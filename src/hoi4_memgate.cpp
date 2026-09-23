// hoi4_memgate.cpp — memory-domain gates for the Lua-facing primitives.
//
// Policy (user ruling, 2026-09-23): the Lua layer may WRITE only engine-owned
// genuinely-writable memory and may CALL only engine code. Concretely:
//
//   write  [addr, addr+len) must lie in committed, non-executable, explicitly
//          writable pages (PAGE_READWRITE / PAGE_WRITECOPY) that do NOT belong
//          to any module except hoi4.exe, and must not touch the current
//          thread's TEB region or stack. Effects:
//            - game .text/.rdata/IAT: read-only -> denied (SEH backstop in the
//              primitives still races); with the call gate below there is no
//              reachable VirtualProtect any more, so read-only pages are
//              permanently read-only
//            - hoi4_bridge.dll's own writable .data: denied (module check) —
//              forging g_nameToKey & co. would otherwise be a call-gate bypass
//            - other modules' writable data (kernel32 et al): denied
//            - executable pages of ANY kind: denied — no legitimate write
//              target lives in executable memory
//            - game heap / engine allocations / engine .data (e.g. the
//              human_ai flag): allowed — the write side's bread and butter
//
//   call   the target must lie inside an EXECUTABLE SECTION of the hoi4.exe
//          image. kernel32!VirtualAlloc/VirtualProtect/LoadLibraryA, freshly
//          allocated RWX pages and bridge-internal addresses are all
//          unreachable from call_u64/call_void. Every in-corpus caller (sv2
//          segments, example mod, tools) calls BASE+<RVA> engine addresses,
//          which pass unchanged.
//
// The C wrappers that call MEMORY-DERIVED function pointers (load_save's
// app->vt[+880], game_pause's mgr->vt[+656]) run the resolved target through
// memgate_exec_ok() too — a forged heap vtable can no longer steer an
// uninstrumented bridge call site.
//
// Overhead: memgate_exec_ok is a linear scan of a handful of section ranges.
// memgate_write_ok keeps a per-thread single-region cache — export loops hit
// the same buffers for thousands of consecutive writes, so VirtualQuery runs
// only on region change.

#include "hoi4_common.h"
#include <intrin.h>

// ---------------------------------------------------------------- exec ranges

#define MG_MAX_SECTIONS 64

static volatile LONG mg_state = 0;        // 0=uninit 1=building 2=ready
static HMODULE mg_exeMod = NULL;          // hoi4.exe module handle
static struct { uint64_t lo, hi; } mg_exec[MG_MAX_SECTIONS];
static int mg_execCount = 0;

static void mg_build(void) {
    mg_exeMod = GetModuleHandleW(NULL);
    if (!g_base || !mg_exeMod) return;
    __try {
        IMAGE_DOS_HEADER *dos = (IMAGE_DOS_HEADER *)g_base;
        if (!dos || dos->e_magic != IMAGE_DOS_SIGNATURE) return;
        IMAGE_NT_HEADERS *nt = (IMAGE_NT_HEADERS *)(g_base + dos->e_lfanew);
        if (nt->Signature != IMAGE_NT_SIGNATURE) return;
        WORD n = nt->FileHeader.NumberOfSections;
        if (n > MG_MAX_SECTIONS) n = MG_MAX_SECTIONS;
        IMAGE_SECTION_HEADER *sec = (IMAGE_SECTION_HEADER *)
            ((uint8_t *)&nt->OptionalHeader + nt->FileHeader.SizeOfOptionalHeader);
        for (WORD i = 0; i < n; i++) {
            if (!(sec[i].Characteristics & IMAGE_SCN_MEM_EXECUTE)) continue;
            uint64_t lo = (uint64_t)(uintptr_t)g_base + sec[i].VirtualAddress;
            uint64_t hi = lo + sec[i].Misc.VirtualSize;
            if (hi <= lo) continue;
            if (mg_execCount < MG_MAX_SECTIONS)
                mg_exec[mg_execCount++] = { lo, hi };
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { mg_execCount = 0; }
    L("[memgate] exec sections=%d (policy: calls must target these)", mg_execCount);
}

static void mg_lazy_init(void) {
    if (InterlockedCompareExchange(&mg_state, 2, 2) == 2) return;   // fast: ready
    if (InterlockedCompareExchange(&mg_state, 1, 0) == 0) {
        mg_build();
        InterlockedExchange(&mg_state, 2);
    } else {
        while (InterlockedCompareExchange(&mg_state, 2, 2) != 2) Sleep(1);
    }
}

// 1 = addr is inside an executable section of the hoi4.exe image.
int memgate_exec_ok(uint64_t addr) {
    if (!g_base) return 0;
    mg_lazy_init();
    for (int i = 0; i < mg_execCount; i++)
        if (addr >= mg_exec[i].lo && addr < mg_exec[i].hi) return 1;
    return 0;
}

// ---------------------------------------------------------------- write gate

// Per-thread state: current TEB region (TLS slots etc.), current stack, and
// the single-region write cache. Primitives run on the main thread in
// practice; filling lazily per thread keeps it correct for any caller.
typedef struct {
    int      filled;
    uint64_t tebLo, tebHi;    // region containing the TEB (TLS slots inside)
    uint64_t stkLo, stkHi;    // [StackLimit, StackBase) of the calling thread
    uint64_t rLo, rHi;        // cached write region; rLo==0 = empty
    int      rOk;
} MgThread;
static __declspec(thread) MgThread t_mg;

static void mg_thread_fill(MgThread *t) {
    uint64_t teb = __readgsqword(0x30);       // TEB self pointer (x64)
    t->stkLo = __readgsqword(0x10);           // StackLimit (low address)
    t->stkHi = __readgsqword(0x08);           // StackBase  (high address)
    t->tebLo = t->tebHi = 0;
    MEMORY_BASIC_INFORMATION mbi;
    if (teb && VirtualQuery((LPCVOID)(uintptr_t)teb, &mbi, sizeof(mbi))) {
        t->tebLo = (uint64_t)(uintptr_t)mbi.BaseAddress;
        t->tebHi = t->tebLo + mbi.RegionSize;
    }
    t->filled = 1;
}

// 1 = every page of [addr, addr+len) passes the write-domain policy.
int memgate_write_ok(uint64_t addr, uint64_t len) {
    if (!g_base || len == 0) return 0;
    if (addr > UINT64_MAX - len) return 0;
    mg_lazy_init();
    MgThread *t = &t_mg;
    if (!t->filled) mg_thread_fill(t);

    uint64_t end = addr + len;

    // fast path: cached region verdict
    if (t->rLo && addr >= t->rLo && end <= t->rHi) return t->rOk;
    // TEB / stack are region-stable: cheap overlap tests on every miss
    if (t->tebHi && addr < t->tebHi && end > t->tebLo) return 0;
    if (t->stkHi > t->stkLo && addr < t->stkHi && end > t->stkLo) return 0;

    int ok = 1, first = 1;
    uint64_t q = addr, qLo = 0, qHi = 0;
    while (q < end) {
        MEMORY_BASIC_INFORMATION mbi;
        if (!VirtualQuery((LPCVOID)(uintptr_t)q, &mbi, sizeof(mbi))) { ok = 0; break; }
        uint64_t rlo = (uint64_t)(uintptr_t)mbi.BaseAddress;
        uint64_t rhi = rlo + mbi.RegionSize;
        if (rhi <= rlo) { ok = 0; break; }

        int rok = (mbi.State == MEM_COMMIT) &&
                  (mbi.Protect == PAGE_READWRITE || mbi.Protect == PAGE_WRITECOPY);
        if (rok) {
            // no writes into ANY module other than the game image itself
            // (bridge .data forging, kernel32 data patching, ...)
            HMODULE hm = NULL;
            if (GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                   GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                   (LPCWSTR)(uintptr_t)rlo, &hm) && hm)
                rok = (hm == mg_exeMod);
        }
        if (!rok) { ok = 0; break; }

        if (first) { qLo = rlo; qHi = rhi; first = 0; }
        q = rhi;
    }

    // cache only when the whole range sat inside the first region
    if (!first && addr >= qLo && end <= qHi) {
        t->rLo = qLo; t->rHi = qHi; t->rOk = ok;
    }
    return ok;
}
