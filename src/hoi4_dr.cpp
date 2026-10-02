// hoi4_dr.cpp — in-process hardware debug-register watch (DR0 write probe)
//
// WHY NOT A DEBUGGER: attaching an external debugger (DebugActiveProcess) sets
// the process debug port; the game has a watchdog that self-exits when the
// port exists (IsDebuggerPresent/PEB patches do NOT cover it — only a
// port-less probe survives). This module keeps everything in-process:
//   - DR0 write watch armed via SetThreadContext on every thread (no debug
//     port, invisible to anti-debug checks)
//   - the resulting STATUS_SINGLE_STEP is caught by a FIRST-chance vectored
//     exception handler, which records RIP + the RSP return-address chain and
//     continues execution (the game never sees the probe)
//
// Live use (PF7/PF8/PC1 class probes):
//   hoi4.dr_watch(addr)  -- arm DR0 4-byte write watch (returns threads armed)
//   hoi4.dr_hits()       -- ring of {rip_rva, rsp, chain[]} (rip/chain = rva)
//   hoi4.dr_off()        -- disarm (clears DR7 everywhere; VEH stays, inert)
//
// Discipline: the VEH runs on EVERY exception of every thread — first check
// is the exception code, bail to CONTINUE_SEARCH immediately. No allocation,
// no logging, no Lua inside the VEH; hits land in a fixed ring under a SRW.

#include "hoi4_common.h"
#include <tlhelp32.h>

#define DR_SINGLE_STEP 0x80000004
#define DR_MAX_HITS 64
#define DR_CHAIN 16

typedef struct {
    ULONG64 ripRva;
    ULONG64 rsp;
    unsigned nchain;
    ULONG64 chain[DR_CHAIN];
    unsigned tick;
} DrHit;

static SRWLOCK   g_drLock = SRWLOCK_INIT;
static void     *g_drVeh;                 // VEH handle (never removed once set)
static volatile LONG64 g_drWatch = 0;     // absolute watch address (0 = idle)
static DrHit     g_drRing[DR_MAX_HITS];
static int       g_drCount;
static unsigned  g_drArmed;               // threads successfully armed

// ---- vectored exception handler: the actual probe --------------------------
static LONG CALLBACK dr_veh(PEXCEPTION_POINTERS ep) {
    if (!ep || !ep->ExceptionRecord || ep->ExceptionRecord->ExceptionCode != DR_SINGLE_STEP)
        return EXCEPTION_CONTINUE_SEARCH;
    PCONTEXT c = ep->ContextRecord;
    if (!c || !(c->Dr6 & 1ULL))                    // bit0 = DR0 matched
        return EXCEPTION_CONTINUE_SEARCH;
    ULONG64 w = (ULONG64)(volatile LONG64 &)g_drWatch;
    if (!w) return EXCEPTION_CONTINUE_SEARCH;

    DrHit hit;
    hit.ripRva = c->Rip - (ULONG64)(uintptr_t)g_base;
    hit.rsp    = c->Rsp;
    hit.tick   = (unsigned)(GetTickCount64() & 0x7FFFFFFF);
    hit.nchain = 0;
    for (int i = 0; i < DR_CHAIN; i++) {
        ULONG64 v = *(ULONG64 *)(c->Rsp + 8 * i);   // stack is mapped by definition
        if (v > (ULONG64)(uintptr_t)g_base + 0x1000 &&
            v < (ULONG64)(uintptr_t)g_base + 0x3800000)
            hit.chain[hit.nchain++] = v - (ULONG64)(uintptr_t)g_base;
    }
    c->Dr6 &= ~1ULL;                               // clear status, re-arms DR0

    AcquireSRWLockExclusive(&g_drLock);
    // ring: shift-oldest (count stays capped)
    if (g_drCount < DR_MAX_HITS) {
        g_drRing[g_drCount++] = hit;
    } else {
        for (int i = 1; i < DR_MAX_HITS; i++) g_drRing[i - 1] = g_drRing[i];
        g_drRing[DR_MAX_HITS - 1] = hit;
    }
    ReleaseSRWLockExclusive(&g_drLock);
    return EXCEPTION_CONTINUE_EXECUTION;
}

// runs on a helper thread: the CALLING thread (game main, where /lua executes)
// must be SUSPENDED to get a clean SetThreadContext — a thread cannot set its
// own debug registers reliably while running.
static int dr_arm_threads(ULONG64 addr) {
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    THREADENTRY32 te; te.dwSize = sizeof(te);
    BOOL ok = Thread32First(snap, &te);
    DWORD pid = GetCurrentProcessId();
    DWORD self = GetCurrentThreadId();      // helper 不能 Suspend 自己（挂死且 3s 超时报 0）
    int armed = 0;
    while (ok) {
        if (te.th32OwnerProcessID == pid && te.th32ThreadID != self) {
            HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                                  THREAD_SET_CONTEXT, FALSE, te.th32ThreadID);
            if (h) {
                if (SuspendThread(h) != (DWORD)-1) {
                    CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                    if (GetThreadContext(h, &c)) {
                        c.Dr0 = addr;
                        c.Dr7 |= 0x1ULL          // L0 local enable
                               | (0x1ULL << 16)  // RW0 = 01 write
                               | (0x3ULL << 18); // LEN0 = 11 four bytes
                        c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                        if (SetThreadContext(h, &c)) armed++;
                    }
                }
                ResumeThread(h);
                CloseHandle(h);
            }
        }
        ok = Thread32Next(snap, &te);
    }
    CloseHandle(snap);
    return armed;
}

static void dr_disarm_threads(void) {
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return;
    THREADENTRY32 te; te.dwSize = sizeof(te);
    BOOL ok = Thread32First(snap, &te);
    DWORD pid = GetCurrentProcessId();
    DWORD self = GetCurrentThreadId();
    while (ok) {
        if (te.th32OwnerProcessID == pid && te.th32ThreadID != self) {
            HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                                  THREAD_SET_CONTEXT, FALSE, te.th32ThreadID);
            if (h) {
                if (SuspendThread(h) != (DWORD)-1) {
                    CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                    if (GetThreadContext(h, &c)) {
                        c.Dr7 &= ~0xD0001ULL;
                        c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                        SetThreadContext(h, &c);
                    }
                }
                ResumeThread(h);
                CloseHandle(h);
            }
        }
        ok = Thread32Next(snap, &te);
    }
    CloseHandle(snap);
    CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
    if (GetThreadContext(GetCurrentThread(), &c)) {
        c.Dr7 &= ~0xD0001ULL;
        c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
        SetThreadContext(GetCurrentThread(), &c);
    }
}

// hoi4.dr_watch(addr) -> threads armed (nil if addr invalid)
int hoi4_dr_watch(lua_State *Ls) {
    // takes the ABSOLUTE watch address (heap or image — callers compute it;
    // dr_hits reports RIP as an image-relative rva)
    long long a = (long long)luaL_checkinteger(Ls, 1);
    if (a == 0) { lua_pushnil(Ls); return 1; }
    if (!g_drVeh)
        g_drVeh = AddVectoredExceptionHandler(1, dr_veh);
    if (!g_drVeh) { lua_pushnil(Ls); return 1; }
    InterlockedExchange64(&g_drWatch, (LONG64)a);
    AcquireSRWLockExclusive(&g_drLock);
    g_drCount = 0;                                 // fresh arm clears the ring
    ReleaseSRWLockExclusive(&g_drLock);
    // arm on a helper thread: suspending the CALLING (main) thread from itself
    // is impossible, and SetThreadContext on a running thread is unreliable.
    struct Ctx { ULONG64 addr; int n; HANDLE done; } ctx = { (ULONG64)a, 0, CreateEventA(nullptr, TRUE, FALSE, nullptr) };
    struct Pack { Ctx *c; };
    auto trampoline = [](void *p) -> DWORD {
        Pack *pk = (Pack *)p;
        pk->c->n = dr_arm_threads(pk->c->addr);
        SetEvent(pk->c->done);
        return 0;
    };
    Pack pk = { &ctx };
    HANDLE th = CreateThread(nullptr, 0, trampoline, &pk, 0, nullptr);
    if (th) {
        WaitForSingleObject(th, 3000);
        CloseHandle(th);
    } else {
        ctx.n = dr_arm_threads(ctx.addr);          // fallback: no helper
    }
    CloseHandle(ctx.done);
    int n = ctx.n;
    L("[dr] watch armed @ 0x%llx on %d threads", (unsigned long long)a, n);
    lua_pushinteger(Ls, n);
    return 1;
}

// hoi4.dr_off() -> true
int hoi4_dr_off(lua_State *Ls) {
    dr_disarm_threads();
    InterlockedExchange64(&g_drWatch, 0);
    L("[dr] watch disarmed");
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.dr_hits() -> { {rip_rva, rsp, chain={rva...}}, ... }
int hoi4_dr_hits(lua_State *Ls) {
    lua_newtable(Ls);
    AcquireSRWLockShared(&g_drLock);
    for (int i = 0; i < g_drCount; i++) {
        lua_newtable(Ls);
        lua_pushinteger(Ls, (lua_Integer)g_drRing[i].ripRva);
        lua_setfield(Ls, -2, "rip_rva");
        lua_pushinteger(Ls, (lua_Integer)g_drRing[i].rsp);
        lua_setfield(Ls, -2, "rsp");
        lua_pushinteger(Ls, (lua_Integer)g_drRing[i].tick);
        lua_setfield(Ls, -2, "tick");
        lua_newtable(Ls);
        for (unsigned k = 0; k < g_drRing[i].nchain; k++) {
            lua_pushinteger(Ls, (lua_Integer)g_drRing[i].chain[k]);
            lua_rawseti(Ls, -2, k + 1);
        }
        lua_setfield(Ls, -2, "chain");
        lua_rawseti(Ls, -2, i + 1);
    }
    lua_pushinteger(Ls, g_drCount);
    lua_setfield(Ls, -2, "n");
    ReleaseSRWLockShared(&g_drLock);
    return 1;
}


// ============ guard-page watch (v2): no DR, no debug port ============
// VirtualProtect(PAGE_GUARD) on the target page; ANY access raises
// STATUS_GUARD_PAGE_VIOLATION (0x80000001) -> VEH records the faulting RIP
// (+ stack chain) and re-arms the guard. Catches writers AND readers of the
// page in one sweep; the caller filters by exact offset.
static volatile LONG64 g_gpAddr = -1;      // watched exact address (or -1)
static ULONG64    g_gpPage = 0;            // page base
static SIZE_T     g_gpSize = 0;
static volatile LONG g_gpCount = 0;
static volatile LONG g_gpTF = 0;           // TF 舞步: 1 = 已设陷阱旗等单步
static volatile LONG g_gpSeq = 0;
#define GP_MAX 4096

static LONG CALLBACK gp_veh(PEXCEPTION_POINTERS ep) {
    if (g_gpTF && ep && ep->ExceptionRecord &&
        ep->ExceptionRecord->ExceptionCode == 0x80000004) {
        PCONTEXT ct = ep->ContextRecord;
        ct->EFlags &= ~0x100ULL;
        g_gpTF = 0;
        DWORD oldp = 0;
        VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE | PAGE_GUARD, &oldp);
        return EXCEPTION_CONTINUE_EXECUTION;
    }
    if (!ep || !ep->ExceptionRecord || ep->ExceptionRecord->ExceptionCode != 0x80000001)
        return EXCEPTION_CONTINUE_SEARCH;   // STATUS_GUARD_PAGE_VIOLATION
    ULONG64 fault = (ULONG64)ep->ExceptionRecord->ExceptionInformation[1];
    ULONG64 page = fault & ~0xFFFULL;
    if (page != g_gpPage || !g_gpPage)
        return EXCEPTION_CONTINUE_SEARCH;   // 别人的 guard 页

    // 我们的页: 无论命中哪个地址, 必须重挂 guard 并 CONTINUE_EXECUTION,
    // 否则未处理守卫页异常直接杀死进程。精确地址命中才记 hit。
    if (g_gpCount >= GP_MAX) {          // 熔断: 总量到顶, 永久解除本页 guard
        DWORD oldp = 0;
        VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE, &oldp);
        g_gpPage = 0;
        return EXCEPTION_CONTINUE_EXECUTION;
    }
    // 无锁记录: Interlocked 分配槽位 (VEH 内零锁零分配)
    LONG slot = InterlockedIncrement(&g_gpSeq);
    if (slot <= GP_MAX) {
        PCONTEXT c = ep->ContextRecord;
        __try {
            DrHit hit;
            hit.ripRva = c->Rip - (ULONG64)(uintptr_t)g_base;
            hit.rsp = c->Rsp;
            hit.tick = (unsigned)(GetTickCount64() & 0x7FFFFFFF);
            hit.nchain = 0;
            for (int i = 0; i < DR_CHAIN; i++) {
                ULONG64 v = *(ULONG64 *)(c->Rsp + 8 * i);
                if (v > (ULONG64)(uintptr_t)g_base + 0x1000 &&
                    v < (ULONG64)(uintptr_t)g_base + 0x3800000)
                    hit.chain[hit.nchain++] = v - (ULONG64)(uintptr_t)g_base;
            }
            g_drRing[slot - 1] = hit;
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
    DWORD old = 0;
    VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE, &old);
    ep->ContextRecord->EFlags |= 0x100ULL;
    g_gpTF = 1;
    return EXCEPTION_CONTINUE_EXECUTION;
}

// hoi4.dr_gwatch(addr, chain_max) -> 1 (guard armed on addr's page)
int hoi4_dr_gwatch(lua_State *Ls) {
    long long a = (long long)luaL_checkinteger(Ls, 1);
    long long cmax = (long long)luaL_checkinteger(Ls, 2);
    if (a == 0) { lua_pushnil(Ls); return 1; }
    if (!g_drVeh)
        g_drVeh = AddVectoredExceptionHandler(1, dr_veh);
    ULONG64 page = (ULONG64)a & ~0xFFFULL;
    g_gpPage = page;                       // 必须先于 VirtualProtect: 首个违例
    g_gpSize = 0x1000;                     // 到达时 VEH 要靠它认领自己的页
    g_gpAddr = a;
    g_gpCount = 0;
    g_gpSeq = 0;
    (void)cmax;
    DWORD old = 0;
    if (!VirtualProtect((void *)page, 0x1000, PAGE_READWRITE | PAGE_GUARD, &old)) {
        L("[gp] VirtualProtect FAILED err=%lu", (unsigned long)GetLastError());
        lua_pushnil(Ls); return 1;
    }
    L("[gp] guard armed @ 0x%llx (page 0x%llx)", (unsigned long long)a, (unsigned long long)page);
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.dr_goff() -> 1 (清 guard)
int hoi4_dr_goff(lua_State *Ls) {
    g_gpTF = 0;
    DWORD old = 0;
    if (g_gpPage)
        VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE, &old);
    g_gpAddr = -1;
    g_gpPage = 0;
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.dr_ghits() -> { n, {rip_rva, rsp, chain} ... } (按 rip 去重计数)
int hoi4_dr_ghits(lua_State *Ls) {
    // 去重统计: rip_rva -> 命中数 (最多 64 个不同 rip)
    struct { ULONG64 rip; unsigned n; ULONG64 firstChain[4]; unsigned nch; } agg[64];
    int nagg = 0;
    LONG total = g_gpSeq; if (total > GP_MAX) total = GP_MAX;
    for (int i = 0; i < total; i++) {
        ULONG64 r = g_drRing[i].ripRva;
        int found = 0;
        for (int k = 0; k < nagg; k++)
            if (agg[k].rip == r) { agg[k].n++; found = 1; break; }
        if (!found && nagg < 64) {
            agg[nagg].rip = r; agg[nagg].n = 1;
            agg[nagg].nch = g_drRing[i].nchain < 4 ? g_drRing[i].nchain : 4;
            for (unsigned k = 0; k < agg[nagg].nch; k++) agg[nagg].firstChain[k] = g_drRing[i].chain[k];
            nagg++;
        }
    }
    ReleaseSRWLockShared(&g_drLock);
    lua_newtable(Ls);
    lua_pushinteger(Ls, g_gpCount);
    lua_setfield(Ls, -2, "n");
    for (int k = 0; k < nagg; k++) {
        lua_newtable(Ls);
        lua_pushinteger(Ls, (lua_Integer)agg[k].rip);
        lua_setfield(Ls, -2, "rip_rva");
        lua_pushinteger(Ls, agg[k].n);
        lua_setfield(Ls, -2, "hits");
        lua_newtable(Ls);
        for (unsigned q = 0; q < agg[k].nch; q++) {
            lua_pushinteger(Ls, (lua_Integer)agg[k].firstChain[q]);
            lua_rawseti(Ls, -2, q + 1);
        }
        lua_setfield(Ls, -2, "chain");
        lua_rawseti(Ls, -2, k + 1);
    }
    return 1;
}

// hoi4.dr_ring_addr() -> 绝对地址 (外部 RPM 轮询用; 崩溃前抢采命中)
int hoi4_dr_ring_addr(lua_State *Ls) {
    lua_pushinteger(Ls, (lua_Integer)(uintptr_t)g_drRing);
    return 1;
}
