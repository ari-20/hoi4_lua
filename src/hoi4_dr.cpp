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
static void     *g_gpVeh;                 // guard-page VEH (旧版从未注册 = gp_veh 死代码, 守卫页异常全链无人认领 → UEF 杀进程)
static volatile LONG64 g_drWatch = 0;     // absolute watch address (0 = idle)
static DrHit     g_drRing[DR_MAX_HITS];
static int       g_drCount;
static unsigned  g_drArmed;               // threads successfully armed

// ---- vectored exception handler: the actual probe --------------------------
static volatile LONG64 g_selfDr0, g_selfDr6, g_selfDr7;   // dr_selfdr 采样结果
int hoi4_dr_selfdr(lua_State *Ls);

static LONG CALLBACK dr_veh(PEXCEPTION_POINTERS ep) {
    if (ep && ep->ExceptionRecord && ep->ExceptionRecord->ExceptionCode == 0xE0000042) {
        PCONTEXT c = ep->ContextRecord;                    // 内核捕获的 CPU 真值
        if (c) {
            g_selfDr0 = (LONG64)c->Dr0;
            g_selfDr6 = (LONG64)c->Dr6;
            g_selfDr7 = (LONG64)c->Dr7;
        }
        return EXCEPTION_CONTINUE_EXECUTION;               // 吞掉, 游戏无感
    }
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

// ThreadHideFromDebugger = 0x11 (ntdll NtSetInformationThread class).
// 破解加载器 (Juij version.dll/winmm.dll) 会把游戏线程标记为 hidden: 内核随后
// 静默丢弃 DR 装载 (SetThreadContext 报成功但 CPU 不加载) 且线程从外部
// toolhelp 消失。arm 前逐线程清掉该标志再装 DR。
typedef NTSTATUS (NTAPI *ZwSetInfoThread_t)(HANDLE, ULONG, PVOID, ULONG);
static ZwSetInfoThread_t get_zw_sit(void) {
    static ZwSetInfoThread_t fn = NULL;
    if (!fn) {
        HMODULE nt = GetModuleHandleA("ntdll.dll");
        if (nt) fn = (ZwSetInfoThread_t)(void *)GetProcAddress(nt, "ZwSetInformationThread");
    }
    return fn;
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
                    ZwSetInfoThread_t zw = get_zw_sit();
                    if (zw) zw(h, 0x11, NULL, 0);   // 清 ThreadHideFromDebugger
                    CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                    if (GetThreadContext(h, &c)) {
                        c.Dr0 = addr;
                        c.Dr1 = c.Dr2 = c.Dr3 = 0;
                        // 直接赋值: 只启用 L0 (残留的 L2/L4 位会干扰装载)
                        c.Dr7 = 0x1ULL          // L0 local enable
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

// hoi4.dr_state() -> {threads, l0_set, l0_clear, other, tid0, dr0_0, dr7_0}
// 诊断: 抽查全线程 DR 寄存器现值, 判定 dr_watch 装载是否被清除。
// running 线程的 GetThreadContext 是不稳定快照, 但 DR 字段只在显式
// SetThreadContext 时改变 — 对「L0 位还在不在」的判读足够。
int hoi4_dr_state(lua_State *Ls) {
    lua_newtable(Ls);
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) {
        lua_pushinteger(Ls, -1); lua_setfield(Ls, -2, "threads");
        return 1;
    }
    THREADENTRY32 te; te.dwSize = sizeof(te);
    BOOL ok = Thread32First(snap, &te);
    DWORD pid = GetCurrentProcessId();
    int total = 0, l0 = 0, clear = 0, other = 0, fail = 0, dr6nz = 0;
    ULONG64 d0 = 0, d7 = 0, d6 = 0; DWORD t0 = 0;
    while (ok) {
        if (te.th32OwnerProcessID == pid) {
            total++;
            HANDLE h = OpenThread(THREAD_GET_CONTEXT, FALSE, te.th32ThreadID);
            if (h) {
                CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                if (GetThreadContext(h, &c)) {
                    if (c.Dr6 != 0ULL) {
                        dr6nz++;
                        if (d6 == 0ULL) d6 = c.Dr6;
                    }
                    if (c.Dr7 & 1ULL) {
                        l0++;
                        if (t0 == 0) { t0 = te.th32ThreadID; d0 = c.Dr0; d7 = c.Dr7; }
                    } else if (c.Dr0 == 0 && (c.Dr7 & 0xFFFFULL) == 0) {
                        clear++;
                    } else {
                        other++;
                    }
                } else {
                    fail++;
                }
                CloseHandle(h);
            } else {
                fail++;
            }
        }
        ok = Thread32Next(snap, &te);
    }
    CloseHandle(snap);
    L("[dr] state: threads=%d l0_set=%d l0_clear=%d other=%d fail=%d tid0=%lu dr0=%llx dr7=%llx",
      total, l0, clear, other, fail, (unsigned long)t0,
      (unsigned long long)d0, (unsigned long long)d7);
    L("[dr] state2: dr6_nonzero=%d dr6_first=%llx", dr6nz, (unsigned long long)d6);
    lua_pushinteger(Ls, total);           lua_setfield(Ls, -2, "threads");
    lua_pushinteger(Ls, l0);              lua_setfield(Ls, -2, "l0_set");
    lua_pushinteger(Ls, clear);           lua_setfield(Ls, -2, "l0_clear");
    lua_pushinteger(Ls, other);           lua_setfield(Ls, -2, "other");
    lua_pushinteger(Ls, fail);            lua_setfield(Ls, -2, "fail");
    lua_pushinteger(Ls, (lua_Integer)t0); lua_setfield(Ls, -2, "tid0");
    lua_pushinteger(Ls, (lua_Integer)d0); lua_setfield(Ls, -2, "dr0_0");
    lua_pushinteger(Ls, (lua_Integer)d7); lua_setfield(Ls, -2, "dr7_0");
    lua_pushinteger(Ls, dr6nz);           lua_setfield(Ls, -2, "dr6_nonzero");
    lua_pushinteger(Ls, (lua_Integer)d6); lua_setfield(Ls, -2, "dr6_first");
    return 1;
}

// hoi4.dr_selfdr() -> {dr0, dr6, dr7} — 对本线程 RaiseException(0xE0000042),
// 由 dr_veh 采样内核捕获的 CPU 真实调试寄存器 (非 KTHREAD 缓存)。
typedef void (WINAPI *RaiseException_t)(DWORD, DWORD, DWORD, const ULONG64 *);
int hoi4_dr_selfdr(lua_State *Ls) {
    HMODULE k32 = GetModuleHandleA("kernel32.dll");
    RaiseException_t raise_ex =
        (RaiseException_t)(void *)GetProcAddress(k32, "RaiseException");
    if (!raise_ex) { lua_pushnil(Ls); return 1; }
    g_selfDr0 = g_selfDr6 = g_selfDr7 = -1;
    raise_ex(0xE0000042, 0, 0, nullptr);
    lua_newtable(Ls);
    lua_pushinteger(Ls, (lua_Integer)g_selfDr0); lua_setfield(Ls, -2, "dr0");
    lua_pushinteger(Ls, (lua_Integer)g_selfDr6); lua_setfield(Ls, -2, "dr6");
    lua_pushinteger(Ls, (lua_Integer)g_selfDr7); lua_setfield(Ls, -2, "dr7");
    return 1;
}

// hoi4.dr_threadtest() -> {armed, hits, var, tid}
// 二分实验: 桥自建全新线程 (CREATE_SUSPENDED) 复刻裸进程成功路径
// (arm DR0=桥全局变量 -> resume -> 线程写)。命中 = 进程级无抑制, 问题
// 在游戏线程个体; 不命中 = 进程级 DR 抑制。
static volatile LONG64 g_ttVar;
static DWORD WINAPI tt_worker(LPVOID) {
    InterlockedExchange64(&g_ttVar, 0x1234);   // 触发 DR0 写断点
    return 0;
}
int hoi4_dr_threadtest(lua_State *Ls) {
    InterlockedExchange64(&g_drWatch, (LONG64)&g_ttVar);
    AcquireSRWLockExclusive(&g_drLock); g_drCount = 0; ReleaseSRWLockExclusive(&g_drLock);
    InterlockedExchange64(&g_ttVar, 0);
    if (!g_drVeh) g_drVeh = AddVectoredExceptionHandler(1, dr_veh);
    DWORD tid = 0;
    HANDLE th = CreateThread(NULL, 0, tt_worker, NULL, CREATE_SUSPENDED, &tid);
    int armed = 0;
    if (th) {
        CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
        if (GetThreadContext(th, &c)) {
            c.Dr0 = (ULONG64)&g_ttVar;
            c.Dr1 = c.Dr2 = c.Dr3 = 0;
            c.Dr7 = 0x1ULL | (0x1ULL << 16) | (0x3ULL << 18);
            c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
            if (SetThreadContext(th, &c)) armed = 1;
        }
        ResumeThread(th);
        WaitForSingleObject(th, 3000);
        CloseHandle(th);
    }
    int hits;
    AcquireSRWLockShared(&g_drLock); hits = g_drCount; ReleaseSRWLockShared(&g_drLock);
    lua_newtable(Ls);
    lua_pushinteger(Ls, armed); lua_setfield(Ls, -2, "armed");
    lua_pushinteger(Ls, hits);    lua_setfield(Ls, -2, "hits");
    lua_pushinteger(Ls, (lua_Integer)g_ttVar); lua_setfield(Ls, -2, "var");
    lua_pushinteger(Ls, (lua_Integer)tid); lua_setfield(Ls, -2, "tid");
    InterlockedExchange64(&g_drWatch, 0);
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
static ULONG64    g_gpDeadPage = 0;   // 熔断/解除后的曾监控页 (在途违例吞掉)
#define GP_MAX 4096

static LONG CALLBACK gp_veh(PEXCEPTION_POINTERS ep) {
    // TF 单步舞步认领: 内核分发时清 EFlags.TF → 不能按位判; g_gpTF 作计数
    // (违例 +1 / 单步 -1): >0 即认领, 多线程并发违例各自的单步都能被接住
    // (旧版单例位图在并发时丢第二线程的单步 → unhandled 80000004 杀进程)
    if (ep && ep->ExceptionRecord &&
        ep->ExceptionRecord->ExceptionCode == 0x80000004 && g_gpTF > 0) {
        PCONTEXT ct = ep->ContextRecord;
        if (ct) ct->EFlags &= ~0x100ULL;
        InterlockedDecrement(&g_gpTF);
        DWORD oldp = 0;
        if (g_gpPage)
            VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE | PAGE_GUARD, &oldp);
        return EXCEPTION_CONTINUE_EXECUTION;
    }
    if (!ep || !ep->ExceptionRecord || ep->ExceptionRecord->ExceptionCode != 0x80000001)
        return EXCEPTION_CONTINUE_SEARCH;   // STATUS_GUARD_PAGE_VIOLATION
    ULONG64 fault = (ULONG64)ep->ExceptionRecord->ExceptionInformation[1];
    ULONG64 page = fault & ~0xFFFULL;
    if (page == g_gpDeadPage && !g_gpPage)
        return EXCEPTION_CONTINUE_EXECUTION; // 熔断/解除后在途违例 (撤 guard 前
                                             // 其他核已 raise 的) — 吞掉免 UEF 死
    if (page != g_gpPage || !g_gpPage)
        return EXCEPTION_CONTINUE_SEARCH;   // 别人的 guard 页

    // 我们的页: 无论命中哪个地址, 必须重挂 guard 并 CONTINUE_EXECUTION,
    // 否则未处理守卫页异常直接杀死进程。精确地址命中才记 hit。
    if (g_gpCount >= GP_MAX) {          // 熔断: 总量到顶, 永久解除本页 guard
        DWORD oldp = 0;
        VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE, &oldp);
        g_gpDeadPage = g_gpPage;
        g_gpPage = 0;
        return EXCEPTION_CONTINUE_EXECUTION;
    }
    // 无锁记录: Interlocked 分配槽位 (VEH 内零锁零分配)
    InterlockedIncrement(&g_gpCount);          // 熔断计数 (旧版从不递增 = 死代码)
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
    InterlockedIncrement(&g_gpTF);           // 计数: 本线程单步即将到来
    return EXCEPTION_CONTINUE_EXECUTION;
}

// hoi4.dr_gwatch(addr, chain_max) -> 1 (guard armed on addr's page)
int hoi4_dr_gwatch(lua_State *Ls) {
    long long a = (long long)luaL_checkinteger(Ls, 1);
    long long cmax = (long long)luaL_checkinteger(Ls, 2);
    if (a == 0) { lua_pushnil(Ls); return 1; }
    if (!g_gpVeh)
        g_gpVeh = AddVectoredExceptionHandler(1, gp_veh);   // 修: 守卫页异常认领者
    ULONG64 page = (ULONG64)a & ~0xFFFULL;
    g_gpPage = page;                       // 必须先于 VirtualProtect: 首个违例
    g_gpSize = 0x1000;                     // 到达时 VEH 要靠它认领自己的页
    g_gpAddr = a;
    g_gpCount = 0;
    g_gpSeq = 0;
    g_gpDeadPage = 0;
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
    if (g_gpPage) {
        VirtualProtect((void *)g_gpPage, g_gpSize, PAGE_READWRITE, &old);
        g_gpDeadPage = g_gpPage;
    }
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
    // (旧版此处有一个无配对的 ReleaseSRWLockShared — 释放未持有锁,
    //  RtlRaiseStatus 直接杀进程; g_drRing 快照读本就无需锁)
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
