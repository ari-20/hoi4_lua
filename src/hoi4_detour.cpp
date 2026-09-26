// hoi4_detour.cpp — Tier 2 function-body detour engine + DLL entry.
//
// Two roles live here:
//   1. the CODE-PATCHING engine — steal the target's prologue into an RX
//      trampoline and redirect the entry. Used for NON-virtual targets (the
//      framework's own FindCommandByName / EffectRouter / TriggerRouter, and
//      mod-installed hoi4.detour targets). Tier 1 (virtual methods) is the
//      separate vt[slot] facility in hoi4_hook.cpp: that one swaps ONE data
//      qword and leaves every code byte intact. The names are one letter apart
//      by history — hook = data swap, detour = code patch.
//   2. DllMain + install_hooks — the DLL startup path, which installs those
//      three detours and the frame vtable hook.
//
// The primitives are exposed through hoi4_detour.h; the design that justifies
// each gate is DETOUR_DESIGN.md.
#include "hoi4_common.h"
#include "hoi4_detour.h"
#include "hoi4_pdata.h"
#include <tlhelp32.h>   // thread enumeration for the suspend-and-verify window

// forward decls for cross-module hook targets (see hoi4_common.h)
void lua_init_thread(void *unused);

// ---- game binary signature check ----
// All image addresses AND the expected PE signature live in the compiled-in
// kOffValues table (hoi4_offsets.h / hoi4_offsets.cpp). Loading fails closed:
// signature mismatch or a zero table entry -> DllMain returns FALSE and the
// game keeps running untouched.

#include "hoi4_lde.h"   // pure decoder extracted for unit tests (tests/test_lde.cpp)

// ---------------------------------------------------------------- steal

int detour_steal_len(const uint8_t *target, int minBytes, int maxBytes,
                     const char **why) {
    int total = 0;
    uint8_t window[32];
    if (why) *why = NULL;
    __try {
        memcpy(window, target, sizeof(window));
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        if (why) *why = "target memory unreadable";
        return 0;
    }
    while (total < minBytes) {
        int rel = 0, rip = 0;
        int n = lde_len(window + total, (uint32_t)(sizeof(window) - total),
                        &rel, &rip);
        if (n <= 0) {
            L("[hook] lde: unrecognized%s opcode %02X at target+%d",
              rel ? " relative-cf" : "", window[total], total);
            if (why) *why = rel
                ? "prologue contains relative control flow (not relocatable)"
                : "prologue contains an unrecognized opcode";
            return 0;
        }
        if (rip) {
            // The stolen bytes are copied VERBATIM into a trampoline elsewhere;
            // a RIP-relative operand would then resolve against the trampoline's
            // address instead of the target's. No relocation is implemented, so
            // this is a hard refusal — see hoi4_lde.h. (The length above is
            // still correct; only the operand's meaning breaks.)
            L("[hook] lde: RIP-relative operand at target+%d (opcode %02X) — "
              "not relocatable, refusing hook", total, window[total]);
            if (why) *why = "prologue uses a RIP-relative operand "
                            "(needs relocation, not implemented)";
            return 0;
        }
        total += n;
    }
    if (total > maxBytes) {
        if (why) *why = "prologue needs more bytes than the limit allows";
        return 0;
    }
    return total;
}

// ---------------------------------------------------------------- trampoline

void *detour_make_trampoline(uint8_t *target, int stolen) {
    uint8_t *stub = (uint8_t *)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE,
                                            PAGE_EXECUTE_READWRITE);
    if (!stub) return NULL;
    memcpy(stub, target, (size_t)stolen);
    // Register-free jump back:
    //     FF 25 00 00 00 00   jmp qword ptr [rip+0]
    //     <8-byte absolute target>
    // WHY NOT `movabs rax,imm64; jmp rax` (what this used to be): the stolen
    // instructions have ALREADY RUN when the jump-back executes, so their
    // register outputs are live in the resumed body. The old abs-jmp clobbered
    // rax, which is exactly the dump-proven failure that killed the first idler
    // hook (FUN_140DBF240: `mov rax,rsp` ... `lea rbp,[rax-68h]` + two movaps
    // stores through rax — see hoi4_frame.cpp). The indirect-through-memory
    // form touches NO register and, unlike `E9 rel32`, has no ±2GB range limit
    // (the trampoline is a fresh VirtualAlloc and may land far from the image).
    stub[stolen + 0] = 0xFF;
    stub[stolen + 1] = 0x25;
    *(uint32_t *)(stub + stolen + 2) = 0;                        // [rip+0]
    *(uint64_t *)(stub + stolen + 6) = (uint64_t)(uintptr_t)(target + stolen);
    // W^X: written once, never modified again (a detour has no uninstall).
    DWORD op = 0;
    if (!VirtualProtect(stub, 64, PAGE_EXECUTE_READ, &op)) {
        VirtualFree(stub, 0, MEM_RELEASE);
        return NULL;
    }
    return stub;
}

// ---------------------------------------------------------------- windows

// Byte windows this process has already patched. The framework's three detours
// register here at DllMain time; every Tier 2 detour registers when committed.
// A new detour must not overlap any of them (DETOUR_DESIGN.md G5/G6) — two
// detours over the same bytes would each replay the other's patch as "stolen
// instructions" and jump into nonsense.
#define DT_MAX_WINDOWS 32
static struct { uint64_t lo, hi; } g_win[DT_MAX_WINDOWS];
static volatile LONG g_winCount;

static void dt_note_window(uint64_t target, int len) {
    long i = InterlockedIncrement(&g_winCount) - 1;
    if (i < DT_MAX_WINDOWS) {
        g_win[i].lo = target;
        g_win[i].hi = target + (uint64_t)len;
    } else {
        InterlockedDecrement(&g_winCount);
        L("[hook] WARNING: patch-window table full — overlap checks degraded");
    }
}

int detour_windows(uint64_t *lo, uint64_t *hi, int cap) {
    int n = (int)g_winCount;
    if (n > DT_MAX_WINDOWS) n = DT_MAX_WINDOWS;
    int m = (n < cap) ? n : cap;
    for (int i = 0; i < m; i++) {
        if (lo) lo[i] = g_win[i].lo;
        if (hi) hi[i] = g_win[i].hi;
    }
    return n;
}

// ---------------------------------------------------------------- patch

// Suspend-and-verify entry patch (DETOUR_DESIGN.md §3.1.2).
//
// ⚠ Nothing between the first SuspendThread and the last ResumeThread may
// allocate or take a user-mode lock. Every allocation and every OpenThread
// happens BEFORE the first suspend, and the only calls inside the window are
// SuspendThread / GetThreadContext / VirtualProtect / memcpy / ResumeThread —
// all kernel paths. That is what keeps the window deadlock-free when a
// suspended thread holds the loader lock (the main thread often does, since we
// run on the init worker) or the heap lock.
int detour_patch_entry(uint8_t *target, int stolen, void *entry,
                       int *outThreads, unsigned long *outHitTid) {
#define DT_MAX_THREADS 512
    HANDLE  th[DT_MAX_THREADS];
    DWORD   tid[DT_MAX_THREADS];
    int     n = 0, suspended = 0, rc = 0, tooMany = 0;

    if (outThreads) *outThreads = 0;
    if (outHitTid)  *outHitTid = 0;
    if (stolen < DT_ENTRY_PATCH_BYTES) return 0;

    DWORD self = GetCurrentThreadId();
    DWORD pid  = GetCurrentProcessId();

    // ---- phase 1: enumerate + open (nothing is suspended yet) ----
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    THREADENTRY32 te;
    memset(&te, 0, sizeof(te));
    te.dwSize = sizeof(te);
    if (Thread32First(snap, &te)) {
        do {
            if (te.dwSize < FIELD_OFFSET(THREADENTRY32, th32OwnerProcessID) +
                            sizeof(DWORD))
                continue;
            if (te.th32OwnerProcessID != pid) continue;
            if (te.th32ThreadID == self) continue;   // our own RIP is in the bridge
            if (n >= DT_MAX_THREADS) { tooMany = 1; break; }
            HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                                  THREAD_QUERY_INFORMATION, FALSE,
                                  te.th32ThreadID);
            if (!h) continue;      // already exited: cannot be inside the target
            th[n] = h;
            tid[n] = te.th32ThreadID;
            n++;
        } while (Thread32Next(snap, &te));
    }
    CloseHandle(snap);

    if (tooMany) {                 // fail closed: cannot verify every thread
        for (int i = 0; i < n; i++) CloseHandle(th[i]);
        return 0;
    }

    // ---- phase 2: suspend all ----
    for (int i = 0; i < n; i++) {
        if (SuspendThread(th[i]) == (DWORD)-1) break;
        suspended++;
    }
    if (suspended != n) goto done;   // could not stop them all: refuse

    // ---- phase 3: verify none is inside the window ----
    for (int i = 0; i < n; i++) {
        CONTEXT c;
        memset(&c, 0, sizeof(c));
        c.ContextFlags = CONTEXT_CONTROL;
        if (!GetThreadContext(th[i], &c)) goto done;   // cannot inspect: refuse
        if ((uint64_t)c.Rip >= (uint64_t)(uintptr_t)target &&
            (uint64_t)c.Rip <  (uint64_t)(uintptr_t)(target + stolen)) {
            if (outHitTid) *outHitTid = tid[i];
            goto done;                                   // inside: refuse
        }
    }
    if (outThreads) *outThreads = n;

    // ---- phase 4: commit (no allocation, no user-mode lock) ----
    {
        DWORD op = 0;
        if (VirtualProtect(target, (SIZE_T)stolen, PAGE_EXECUTE_READWRITE, &op)) {
            target[0] = 0x48; target[1] = 0xB8;
            *(uint64_t *)(target + 2) = (uint64_t)(uintptr_t)entry;
            target[10] = 0xFF; target[11] = 0xE0;
            for (int i = DT_ENTRY_PATCH_BYTES; i < stolen; i++) target[i] = 0x90;
            DWORD tmp = 0;
            VirtualProtect(target, (SIZE_T)stolen, op, &tmp);
            FlushInstructionCache(GetCurrentProcess(), target, (SIZE_T)stolen);
            dt_note_window((uint64_t)(uintptr_t)target, stolen);
            rc = 1;
        }
    }

done:
    for (int i = 0; i < suspended; i++) ResumeThread(th[i]);
    for (int i = 0; i < n; i++) CloseHandle(th[i]);
    return rc;
#undef DT_MAX_THREADS
}

// ---------------------------------------------------------------- framework install

// Steal + trampoline + patch, for the framework's OWN detours. These run from
// DllMain, i.e. under the loader lock, so they must NOT call
// CreateToolhelp32Snapshot (which can take the loader lock and would deadlock
// against the very thread calling us). The game is still starting here and the
// three targets are unreachable until it is up, so the plain patch is safe for
// exactly these three — a mod-facing detour never takes this path.
static int install_abs_jmp(uint8_t *target, void *dst, uint8_t *saved,
                           void **trampOut) {
    const char *why = NULL;
    int stolen = detour_steal_len(target, DT_ENTRY_PATCH_BYTES, 24, &why);
    if (!stolen) {
        L("[hook] REFUSED @ %p: prologue not cleanly stealable (%s)", target,
          why ? why : "?");
        return 0;
    }
    memcpy(saved, target, (size_t)stolen);
    void *stub = detour_make_trampoline(target, stolen);
    if (!stub) return 0;
    *trampOut = stub;
    DWORD op;
    VirtualProtect(target, (SIZE_T)stolen, PAGE_EXECUTE_READWRITE, &op);
    target[0] = 0x48; target[1] = 0xB8;
    *(uint64_t *)(target + 2) = (uint64_t)(uintptr_t)dst;
    target[10] = 0xFF; target[11] = 0xE0;
    for (int i = DT_ENTRY_PATCH_BYTES; i < stolen; i++) target[i] = 0x90;
    VirtualProtect(target, (SIZE_T)stolen, op, &op);
    FlushInstructionCache(GetCurrentProcess(), target, (SIZE_T)stolen);
    dt_note_window((uint64_t)(uintptr_t)target, stolen);
    L("[hook] installed @ %p -> %p (stolen=%d, stub=%p, jmpback=FF25[rip])",
      target, dst, stolen, stub);
    return 1;
}

static int install_hooks(void) {
    g_base = (uint8_t *)GetModuleHandleW(NULL);
    if (!offsets_load()) {
        L("[fatal] offsets load/verify failed — refusing to patch.");
        return 0;
    }
    // The detour targets are function starts, and the LDE window must stay
    // inside them (a 12-byte steal from a short function would eat the next
    // one). Build the table up front so the same gate the mod path uses also
    // guards the framework's own three.
    if (!pdata_build())
        L("[hook] WARNING: .pdata unavailable — function-start gate degraded");
    if (!install_abs_jmp(g_base + RVA_FIND_CMD_BY_NAME, HK_FindCommandByName,
                    (uint8_t *)VirtualAlloc(NULL, 24, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE),
                    (void **)&g_origFind)) return 0;
    L("[hook] FindCommandByName @ %p", g_base + RVA_FIND_CMD_BY_NAME);
    if (!install_abs_jmp(g_base + RVA_EFFECT_ROUTER, HK_EffectRouter,
                    (uint8_t *)VirtualAlloc(NULL, 24, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE),
                    (void **)&g_origRouter)) return 0;
    L("[hook] EffectRouter @ %p (orig %p)", g_base + RVA_EFFECT_ROUTER, g_origRouter);
    g_engNew = (EngineNew_t)(g_base + RVA_ENGINE_NEW);
    g_factorySetGlobal = (void *(*)(void))(g_base + RVA_SET_GLOBAL_FACTORY);
    g_engPush = (void (*)(uint8_t *, void **))(g_base + RVA_VEC_PUSH_BACK);
    // name bridge fn
    g_nameToKey = (void (*)(int *, void *))(g_base + RVA_NAME_TO_KEY);
    L("[init] machinery: new=%p factory=%p push=%p", g_engNew, g_factorySetGlobal, g_engPush);
    L("[bridge] bridge: nameToKey=%p", g_nameToKey);
    // trigger machinery
    g_factoryGFT = (void *(*)(void))(g_base + RVA_GFT_FACTORY);
    build_my_tvt();
    if (!install_abs_jmp(g_base + RVA_TRIGGER_ROUTER, HK_TriggerRouter,
                    (uint8_t *)VirtualAlloc(NULL, 24, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE),
                    (void **)&g_origTRouter)) return 0;
    L("[trigger] TriggerRouter @ %p (orig %p) factory=%p",
      g_base + RVA_TRIGGER_ROUTER, g_origTRouter, g_factoryGFT);
    build_my_vtable();
    // per-frame heartbeat via VTABLE SLOT swap (the inline body patch
    // was dump-proven fatal - the abs-jmp trampoline clobbers rax which the
    // stolen prologue feeds into rbp/movaps later in FUN_140DBF240).
    install_v4_vtable_hook();
    return 1;
}

BOOL APIENTRY DllMain(HMODULE hMod, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hMod);
        // No file IO here (loader lock): early log entries go to the memory
        // ring; lua_init_thread opens the real file under <user>/logs/ once
        // paths are resolved (log_open_in_logs_dir).
        L("=== hoi4_bridge loaded (pid %lu) ===", GetCurrentProcessId());
        int ok = 0;
        __try { ok = install_hooks(); }
        __except (EXCEPTION_EXECUTE_HANDLER) {
            L("[fatal] hook install crashed");
            return FALSE;
        }
        if (!ok) {
            L("[fatal] hook install refused/failed — DLL not activating");
            return FALSE;
        }
        // Lua init on a worker thread: DllMain (loader lock) must stay light
        CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)lua_init_thread, NULL, 0, NULL);
        // heartbeat: no extra thread needed anymore - the frame hook
        // installed above (CInGameIdler::v4) dispatches on the engine's
        // pinned main thread, in-game only. The old WM_TIMER worker was
        // removed with the route-B redesign.
    }
    return TRUE;
}
