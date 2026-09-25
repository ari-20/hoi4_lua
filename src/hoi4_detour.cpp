// hoi4_detour.cpp — Tier 2 function-body detour engine + DLL entry.
//
// Two roles live here:
//   1. install_abs_jmp / hook_steal_len — the CODE-PATCHING engine, used
//      for NON-virtual targets (FindCommandByName, EffectRouter,
//      TriggerRouter). Tier 1 (virtual methods) is the separate vt[slot]
//      facility in hoi4_hook.cpp: that one swaps ONE data qword and leaves
//      every code byte intact. The names are one letter apart by history —
//      hook = data swap, detour = code patch.
//   2. DllMain + install_hooks — the DLL startup path, which installs those
//      three detours and the frame vtable hook.
//
#include "hoi4_common.h"

// forward decls for cross-module hook targets (see hoi4_common.h)
void lua_init_thread(void *unused);

// ---- game binary signature check ----
// All image addresses AND the expected PE signature live in the compiled-in
// kOffValues table (hoi4_offsets.h / hoi4_offsets.cpp). Loading fails closed:
// signature mismatch or a zero table entry -> DllMain returns FALSE and the
// game keeps running untouched.

#include "hoi4_lde.h"   // pure decoder extracted for unit tests (tests/test_lde.cpp)

// steal >= minBytes of WHOLE instructions at target; returns byte count or 0
static int hook_steal_len(const uint8_t *target, int minBytes, int maxBytes) {
    int total = 0;
    uint8_t window[32];
    __try {
        memcpy(window, target, sizeof(window));
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    while (total < minBytes) {
        int rel = 0, rip = 0;
        int n = lde_len(window + total, (uint32_t)(sizeof(window) - total), &rel, &rip);
        if (n <= 0) {
            L("[hook] lde: unrecognized%s opcode %02X at target+%d",
              rel ? " relative-cf" : "", window[total], total);
            return 0;
        }
        if (rip) {
            // install_abs_jmp copies the stolen bytes VERBATIM into a stub
            // elsewhere; a RIP-relative operand would then resolve against the
            // stub's address instead of the target's. No relocation is
            // implemented, so this is a hard refusal — see hoi4_lde.h. (The
            // length above is still correct; only the operand's meaning breaks.)
            L("[hook] lde: RIP-relative operand at target+%d (opcode %02X) — "
              "not relocatable, refusing hook", total, window[total]);
            return 0;
        }
        total += n;
    }
    if (total > maxBytes) return 0;
    return total;
}

#define HOOK_JUMP_BYTES 12   // movabs rax + jmp rax (outbound patch only)

// Jump-back encoding used at the end of the trampoline (14 bytes):
//     FF 25 00 00 00 00   jmp qword ptr [rip+0]
//     <8-byte absolute target>
// WHY NOT `movabs rax,imm64; jmp rax` (what this used to be): the stolen
// instructions have ALREADY RUN when the jump-back executes, so their register
// outputs are live in the resumed body. The old abs-jmp clobbered rax, which
// is exactly the dump-proven failure that killed the first idler hook
// (FUN_140DBF240: `mov rax,rsp` ... `lea rbp,[rax-68h]` + two movaps stores
// through rax — see hoi4_frame.cpp). The indirect-through-memory form touches
// NO register and, unlike `E9 rel32`, has no ±2GB range limit (the stub is a
// fresh VirtualAlloc and may land far from the image).
//
// The OUTBOUND patch (target -> thunk) keeps the abs-jmp on purpose: it runs
// at function entry, before any stolen instruction, where rax is caller-
// volatile scratch that no callee may rely on — clobbering it there is
// provably harmless. Keeping it also holds the stolen-byte requirement at 12
// (a register-free outbound form would need 14 and change which instructions
// get stolen for the existing targets).

static int install_abs_jmp(uint8_t *target, void *dst, uint8_t *saved,
                           void **trampOut) {
    int stolen = hook_steal_len(target, HOOK_JUMP_BYTES, 24);
    if (!stolen) {
        L("[hook] REFUSED @ %p: prologue not cleanly stealable", target);
        return 0;
    }
    memcpy(saved, target, stolen);
    uint8_t *stub = (uint8_t *)VirtualAlloc(NULL, 64, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return 0;
    memcpy(stub, target, stolen);
    // register-free jump back to target+stolen
    stub[stolen+0] = 0xFF; stub[stolen+1] = 0x25;
    *(uint32_t *)(stub + stolen + 2) = 0;                    // [rip+0]
    *(uint64_t *)(stub + stolen + 6) = (uint64_t)(target + stolen);
    *trampOut = stub;
    DWORD op;
    VirtualProtect(target, (SIZE_T)stolen, PAGE_EXECUTE_READWRITE, &op);
    target[0] = 0x48; target[1] = 0xB8;
    *(uint64_t *)(target + 2) = (uint64_t)dst;
    target[10] = 0xFF; target[11] = 0xE0;
    for (int i = HOOK_JUMP_BYTES; i < stolen; i++) target[i] = 0x90; // pad to boundary
    VirtualProtect(target, (SIZE_T)stolen, op, &op);
    FlushInstructionCache(GetCurrentProcess(), target, (SIZE_T)stolen);
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
    // was dump-proven fatal -
    // the abs-jmp trampoline clobbers rax which the stolen prologue feeds
    // into rbp/movaps later in FUN_140DBF240).
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
