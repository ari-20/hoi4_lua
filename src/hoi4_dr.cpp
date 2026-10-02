// hoi4_dr.cpp — in-process hardware debug-register write watch
//
// WHY NOT A DEBUGGER: attaching an external debugger (DebugActiveProcess) sets
// the process debug port; the game has a watchdog that self-exits when the
// port exists (IsDebuggerPresent/PEB patches do NOT cover it — only a
// port-less probe survives). This module keeps everything in-process:
//   - DR write watch armed via SetThreadContext on every thread (no debug
//     port, invisible to anti-debug checks)
//   - the resulting STATUS_SINGLE_STEP is caught by a FIRST-chance vectored
//     exception handler, which records RIP + the RSP return-address chain and
//     continues execution (the game never sees the probe)
//
// DR 槽仲裁 (2026-10-02): 会话检测 (hoi4_session.cpp) 常驻 Dr0/Dr1/Dr2。本模块
// 装载一律取「第一个空闲槽」(全线程强制同一槽, 保证 VEH 按 Dr6.Bn 归因一致),
// 撤除按 Dr_i==watch 地址精确匹配 — 绝不整写 Dr7 / 绝不清别人的槽。
//
// Live use (PF7/PF8/PC1 class probes):
//   hoi4.dr_watch(addr)  -- arm 4-byte write watch (absolute, 4B aligned);
//                           returns threads armed (0 = no free DR slot)
//   hoi4.dr_hits()       -- ring of {rip_rva, rsp, chain[], tid, slot, watch}
//                           + total (累计命中, 不随环滚动)
//   hoi4.dr_top([n])     -- ring aggregated by RIP (hits desc) + total
//   hoi4.dr_selftest()   -- end-to-end check: alloc -> arm -> real write -> hit
//   hoi4.dr_off()        -- disarm ALL watches of this module (精确撤槽)
//
// Discipline: the VEH runs on EVERY exception of every thread — first check
// is the exception code, bail to CONTINUE_SEARCH immediately. No allocation,
// no logging, no Lua inside the VEH; hits land in a fixed ring under a SRW.
// 生效判据 = 真实写入产生命中 (dr_selftest); dr_selfdr 的软件异常上下文快照
// 不是判据 (RaiseException 不产生 #DB, 实测出现过快照 0 而真实写命中的同一轮)。

#include "hoi4_common.h"
#include <tlhelp32.h>
#include <intrin.h>

#define DR_SINGLE_STEP 0x80000004
#define DR_MAX_HITS 64
#define DR_CHAIN 16
#define DR_MAX_WATCH 4

typedef struct {
    ULONG64 ripRva;
    ULONG64 rsp;
    unsigned nchain;
    ULONG64 chain[DR_CHAIN];
    unsigned tick;
    unsigned tid;                  // 命中线程 (追加字段, 前缀布局兼容外部 RPM 读者)
    unsigned slot;                 // 命中的硬件槽 0-3 (guard 页命中 = 0xF)
    ULONG64  watch;                // 该槽布的监视地址
} DrHit;

static SRWLOCK   g_drLock = SRWLOCK_INIT;
static void     *g_drVeh;                 // VEH handle (never removed once set)
static void     *g_gpVeh;                 // guard-page VEH (旧版从未注册 = gp_veh 死代码, 守卫页异常全链无人认领 → UEF 杀进程)
static volatile LONG64 g_drWatch[DR_MAX_WATCH];  // [硬件槽] = 布点地址 (0 = 非本工具)
static volatile LONG g_drTotal = 0;       // 累计命中 (不随 64 环滚动; dr_off 归零)
static DrHit     g_drRing[DR_MAX_HITS];
static int       g_drCount;
static unsigned  g_drArmed;               // threads successfully armed

// ---- vectored exception handler: the actual probe --------------------------
static volatile LONG64 g_selfDr0, g_selfDr6, g_selfDr7;   // dr_selfdr 采样结果
int hoi4_dr_selfdr(lua_State *Ls);

static LONG CALLBACK dr_veh(PEXCEPTION_POINTERS ep) {
    if (ep && ep->ExceptionRecord && ep->ExceptionRecord->ExceptionCode == 0xE0000042) {
        PCONTEXT c = ep->ContextRecord;              // 该次软件异常的上下文快照
        if (c) {
            g_selfDr0 = (LONG64)c->Dr0;
            g_selfDr6 = (LONG64)c->Dr6;
            g_selfDr7 = (LONG64)c->Dr7;
        }
        return EXCEPTION_CONTINUE_EXECUTION;         // 吞掉, 游戏无感
    }
    if (!ep || !ep->ExceptionRecord || ep->ExceptionRecord->ExceptionCode != DR_SINGLE_STEP)
        return EXCEPTION_CONTINUE_SEARCH;
    PCONTEXT c = ep->ContextRecord;
    if (!c) return EXCEPTION_CONTINUE_SEARCH;
    // 只认领「本工具布的槽」(g_drWatch 按硬件槽索引): 会话检测 Dr0-2 执行断点
    // 的命中由此放行给会话 VEH — 旧版「Dr6&1 + 单地址非零即认领」在 watch 活动
    // 期会把会话事件吞成本工具的假命中。多个本工具槽同时匹配只记一条。
    int wslot = -1;
    for (int n = 0; n < DR_MAX_WATCH; n++)
        if ((c->Dr6 & (1ULL << n)) && g_drWatch[n]) { wslot = n; break; }
    if (wslot < 0) return EXCEPTION_CONTINUE_SEARCH;

    DrHit hit;
    hit.ripRva = c->Rip - (ULONG64)(uintptr_t)g_base;
    hit.rsp    = c->Rsp;
    hit.tick   = (unsigned)(GetTickCount64() & 0x7FFFFFFF);
    hit.tid    = GetCurrentThreadId();
    hit.slot   = (unsigned)wslot;
    hit.watch  = g_drWatch[wslot];
    hit.nchain = 0;
    for (int i = 0; i < DR_CHAIN; i++) {
        ULONG64 v = *(ULONG64 *)(c->Rsp + 8 * i);   // stack is mapped by definition
        if (v > (ULONG64)(uintptr_t)g_base + 0x1000 &&
            v < (ULONG64)(uintptr_t)g_base + 0x3800000)
            hit.chain[hit.nchain++] = v - (ULONG64)(uintptr_t)g_base;
    }
    for (int n = 0; n < DR_MAX_WATCH; n++)
        if (g_drWatch[n]) c->Dr6 &= ~(1ULL << n);    // 清本工具槽状态 = 重新武装

    AcquireSRWLockExclusive(&g_drLock);
    g_drTotal++;
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

// ThreadHideFromDebugger 旧处理已删: 原代码对每线程调 ZwSetInformationThread
// (0x11) 且注释误标「清除隐藏标志」— 该信息类是设置方向, 且本工具不用外部
// 调试器, 该调用无收益只添噪声。

// ---- DR 槽仲裁原语 ----------------------------------------------------------
static ULONG64 *dr_reg(CONTEXT *c, int i) {
    switch (i) {
    case 0:  return &c->Dr0;
    case 1:  return &c->Dr1;
    case 2:  return &c->Dr2;
    default: return &c->Dr3;
    }
}
// 槽 i 空闲 = 本地使能位 Li 为 0。
// ⚠ DR7 布局: L(i)=bit 2i (L0=0, L1=2, L2=4, L3=6), G(i)=bit 2i+1,
// RW(i)=bits 16+4i..17+4i, LEN(i)=bits 18+4i..19+4i — 使能位不按半字节稠密
// 排布 (首版误用 bit i / 16+2i, 在会话已占 L0-L2 的线程上会误写 Dr1 + G0)。
static int dr_free_slot(CONTEXT *c) {
    for (int i = 0; i < 4; i++)
        if (!(c->Dr7 & (1ULL << (2 * i)))) return i;
    return -1;                                 // 4 槽全占: 拒装 (报 0, 不覆盖)
}
// 槽 i 的 4 字节写断点 Dr7 编码: Li | RWi=01 | LENi=11
static ULONG64 dr_slot_en(int i) {
    return (1ULL << (2 * i)) | (1ULL << (16 + 4 * i)) | (3ULL << (18 + 4 * i));
}
static ULONG64 dr_slot_off(int i) {            // 撤除掩码 (Li + RWi + LENi)
    return (1ULL << (2 * i)) | (0xFULL << (16 + 4 * i));
}
static int dr_ctx_arm(CONTEXT *c, ULONG64 addr) {
    int slot = dr_free_slot(c);
    if (slot < 0) return -1;
    *dr_reg(c, slot) = addr;
    c->Dr7 = (c->Dr7 & ~dr_slot_off(slot)) | dr_slot_en(slot);
    return slot;
}
static void dr_ctx_disarm(CONTEXT *c, ULONG64 addr) {
    for (int i = 0; i < 4; i++) {
        if (*dr_reg(c, i) == addr) {
            c->Dr7 &= ~dr_slot_off(i);
            *dr_reg(c, i) = 0;
        }
    }
}

// runs on a helper thread: the CALLING thread (game main, where /lua executes)
// must be SUSPENDED to get a clean SetThreadContext — a thread cannot set its
// own debug registers reliably while running.
// 全线程强制同一硬件槽 (取首个可装载线程的选择): VEH 按 Dr6.Bn → g_drWatch[槽]
// 归因, 各线程槽号不一致会错归因 — 槽被占的线程跳过不装 (不计入 armed)。
static int dr_arm_threads(ULONG64 addr, int *slot_out) {
    *slot_out = -1;
    if (addr & 3) return 0;                    // LEN=11 须 4B 对齐, 错对齐静默不命中
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    THREADENTRY32 te; te.dwSize = sizeof(te);
    BOOL ok = Thread32First(snap, &te);
    DWORD pid = GetCurrentProcessId();
    DWORD self = GetCurrentThreadId();      // helper 不能 Suspend 自己（挂死且 3s 超时报 0）
    int armed = 0, slot = -1;
    while (ok) {
        if (te.th32OwnerProcessID == pid && te.th32ThreadID != self) {
            HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                                  THREAD_SET_CONTEXT, FALSE, te.th32ThreadID);
            if (h) {
                if (SuspendThread(h) != (DWORD)-1) {
                    // SuspendThread 返回不等线程真正冻结 (忙跑线程的挂起在下次
                    // 内核调度才生效) — settle 让挂起落地, 否则 SetThreadContext
                    // 写的是无效位置 (游戏线程满负荷跑 = 必踩; 阻塞线程无此问题)
                    Sleep(20);
                    CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                    if (GetThreadContext(h, &c)) {
                        // 后续线程锁定首线程选的槽; 该槽被占则跳过 (保归因一致)
                        int s = (slot >= 0)
                                    ? ((c.Dr7 & (1ULL << slot)) ? -1 : slot)
                                    : dr_free_slot(&c);
                        if (s >= 0) {
                            *dr_reg(&c, s) = addr;
                            c.Dr7 = (c.Dr7 & ~dr_slot_off(s)) | dr_slot_en(s);
                            c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                            if (SetThreadContext(h, &c)) {
                                armed++;
                                if (slot < 0) slot = s;
                            }
                        }
                    }
                }
                ResumeThread(h);
                CloseHandle(h);
            }
        }
        ok = Thread32Next(snap, &te);
    }
    CloseHandle(snap);
    *slot_out = slot;
    return armed;
}

static void dr_disarm_threads(ULONG64 addr) {
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
                        dr_ctx_disarm(&c, addr);   // 只动 Dr_i==addr 的槽
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
        dr_ctx_disarm(&c, addr);
        c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
        SetThreadContext(GetCurrentThread(), &c);
    }
}

// hoi4.dr_watch(addr) -> threads armed (nil if addr invalid / 0 = no free slot)
int hoi4_dr_watch(lua_State *Ls) {
    // takes the ABSOLUTE watch address (heap or image — callers compute it;
    // dr_hits reports RIP as an image-relative rva)
    long long a = (long long)luaL_checkinteger(Ls, 1);
    if (a == 0) { lua_pushnil(Ls); return 1; }
    if (a & 3) {
        L("[dr] watch refused: 0x%llx not 4-byte aligned (LEN=11 requirement)",
          (unsigned long long)a);
        lua_pushnil(Ls); return 1;
    }
    if (!g_drVeh)
        g_drVeh = AddVectoredExceptionHandler(1, dr_veh);
    if (!g_drVeh) { lua_pushnil(Ls); return 1; }
    for (int i = 0; i < DR_MAX_WATCH; i++)       // 重复布点拒绝 (幂等语义不明, 宁拒)
        if ((ULONG64)(volatile LONG64 &)g_drWatch[i] == (ULONG64)a) {
            L("[dr] watch refused: 0x%llx already watched", (unsigned long long)a);
            lua_pushnil(Ls); return 1;
        }
    // arm on a helper thread: suspending the CALLING (main) thread from itself
    // is impossible, and SetThreadContext on a running thread is unreliable.
    struct Ctx { ULONG64 addr; int n; int slot; HANDLE done; } ctx = { (ULONG64)a, 0, -1, CreateEventA(nullptr, TRUE, FALSE, nullptr) };
    struct Pack { Ctx *c; };
    auto trampoline = [](void *p) -> DWORD {
        Pack *pk = (Pack *)p;
        pk->c->n = dr_arm_threads(pk->c->addr, &pk->c->slot);
        SetEvent(pk->c->done);
        return 0;
    };
    Pack pk = { &ctx };
    HANDLE th = CreateThread(nullptr, 0, trampoline, &pk, 0, nullptr);
    if (th) {
        WaitForSingleObject(th, 3000);
        CloseHandle(th);
    } else {
        ctx.n = dr_arm_threads(ctx.addr, &ctx.slot);   // fallback: no helper
    }
    CloseHandle(ctx.done);
    int n = ctx.n;
    if (n > 0 && ctx.slot >= 0)
        InterlockedExchange64(&g_drWatch[ctx.slot], (LONG64)a);
    else
        L("[dr] watch 0x%llx NOT armed: no free DR slot (session hooks take Dr0-2)",
          (unsigned long long)a);
    L("[dr] watch armed @ 0x%llx slot=%d on %d threads",
      (unsigned long long)a, ctx.slot, n);
    lua_pushinteger(Ls, n);
    return 1;
}

// hoi4.dr_off() -> true — 撤除本工具全部 watch (会话钩子等其他用户的槽不动)
int hoi4_dr_off(lua_State *Ls) {
    int n = 0;
    for (int i = 0; i < DR_MAX_WATCH; i++) {
        ULONG64 w = (ULONG64)(volatile LONG64 &)g_drWatch[i];
        if (!w) continue;
        dr_disarm_threads(w);
        InterlockedExchange64(&g_drWatch[i], 0);
        n++;
    }
    AcquireSRWLockExclusive(&g_drLock);
    g_drCount = 0;
    g_drTotal = 0;
    ReleaseSRWLockExclusive(&g_drLock);
    L("[dr] watch disarmed (%d watch(es))", n);
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.dr_state() -> {threads, l0_set, l0_clear, other, tid0, dr0_0, dr7_0}
// 诊断: 抽查全线程「保存上下文」中的 DR 字段。⚠ 运行线程的 GetThreadContext
// 是非权威快照 (官方语义: 无效), 读到的 L0 位与 CPU live 态无保证关系 —
// 本函数既非「装载被清除」也非「DR 生效」的判据; 生效判据 = dr_selftest()
// / 真实写命中。
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
// 由 dr_veh 采样「该次软件异常」上下文中的 DR 字段。
// ⚠ 不能作 DR 生效判据: RaiseException 不产生 #DB, ContextRecord 的 DR 字段
// 与 CPU live 态无保证关系 (2026-10-02 实测: 快照 0 的同一轮真实写命中)。
// 工具可用性判据 = dr_selftest()。
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
    InterlockedExchange64(&g_drWatch[0], (LONG64)&g_ttVar);   // 私有新线程, Dr0 必空闲
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
    InterlockedExchange64(&g_drWatch[0], 0);
    return 1;
}

// hoi4.dr_selfarm(addr) -> true/nil — 当前线程真句柄不挂起直接装载 watch 槽
// (走槽位仲裁, 与 dr_watch 同规)。⚠ 对运行中线程 SetThreadContext 非受支持
// API 用法, 但本环境实测可生效 — 生效与否一律以 dr_selftest() / 真实写命中
// 为准, 不以返回值为准。
int hoi4_dr_selfarm(lua_State *Ls) {
    long long a = (long long)luaL_checkinteger(Ls, 1);
    if (a == 0) { lua_pushnil(Ls); return 1; }
    if (a & 3) {
        L("[dr] selfarm refused: 0x%llx not 4-byte aligned", (unsigned long long)a);
        lua_pushnil(Ls); return 1;
    }
    if (!g_drVeh) g_drVeh = AddVectoredExceptionHandler(1, dr_veh);
    for (int i = 0; i < DR_MAX_WATCH; i++)
        if ((ULONG64)(volatile LONG64 &)g_drWatch[i] == (ULONG64)a) {
            L("[dr] selfarm refused: 0x%llx already watched", (unsigned long long)a);
            lua_pushnil(Ls); return 1;
        }
    HANDLE h = OpenThread(THREAD_GET_CONTEXT | THREAD_SET_CONTEXT, FALSE, GetCurrentThreadId());
    if (!h) { lua_pushnil(Ls); return 1; }
    CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
    int ok = 0;
    if (GetThreadContext(h, &c)) {
        int slot = dr_ctx_arm(&c, (ULONG64)a);
        if (slot >= 0) {
            c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
            if (SetThreadContext(h, &c)) {
                InterlockedExchange64(&g_drWatch[slot], (LONG64)a);
                ok = 1;
            }
        } else {
            L("[dr] selfarm refused: no free DR slot");
        }
    }
    CloseHandle(h);
    L("[dr] selfarm @ %llx -> %d", (unsigned long long)a, ok);
    lua_pushboolean(Ls, ok);
    return 1;
}

// hoi4.dr_selftest() -> {alloc, armed, slot, wrote, hit, value}
// 端到端自检 = DR 路线唯一「工具是否可用」判据:
// engine_alloc 8B 堆块 → 当前线程 self-arm → 真实写一次 → 查命中 → 撤 → free。
// hit>=1 即通过 (真实 #DB 事件, 软件异常快照无法伪造)。
// 不触碰已有 watch (只占自己的槽); total 差值计数, 不清环。
int hoi4_dr_selftest(lua_State *Ls) {
    lua_newtable(Ls);
    int alloced = 0, armed = 0, slot = -1, wrote = 0, hit = 0;
    ULONG64 p = 0, value = 0;
    do {
        if (!g_base || !RVA_ENGINE_ALLOC) break;
        typedef void *(*EngAlloc_t)(size_t);
        EngAlloc_t fn = (EngAlloc_t)(g_base + RVA_ENGINE_ALLOC);
        __try { p = (ULONG64)(uintptr_t)fn(8); }
        __except (EXCEPTION_EXECUTE_HANDLER) { p = 0; }
        if (!p) break;
        alloced = 1;
        if (!g_drVeh) g_drVeh = AddVectoredExceptionHandler(1, dr_veh);
        *(volatile unsigned int *)(uintptr_t)p = 0;      // arm 前的写不算命中
        ULONG64 totalBefore = (ULONG64)g_drTotal;
        HANDLE h = OpenThread(THREAD_GET_CONTEXT | THREAD_SET_CONTEXT,
                              FALSE, GetCurrentThreadId());
        if (h) {
            CONTEXT c; c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
            if (GetThreadContext(h, &c) && (slot = dr_ctx_arm(&c, p)) >= 0) {
                c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                armed = SetThreadContext(h, &c) ? 1 : 0;
            }
            CloseHandle(h);
        }
        if (armed) {
            InterlockedExchange64(&g_drWatch[slot], (LONG64)p);
            SwitchToThread();                 // 给内核一次装载 DR 的调度机会
            *(volatile unsigned int *)(uintptr_t)p = 0x13579BDF;
            wrote = 1;
            hit = (int)((ULONG64)g_drTotal - totalBefore);
            value = *(volatile unsigned int *)(uintptr_t)p;
        }
        if (slot >= 0) {
            dr_disarm_threads(p);
            InterlockedExchange64(&g_drWatch[slot], 0);
        }
        HANDLE hHeap = *(HANDLE *)(g_base + RVA_ENGINE_HEAP_HANDLE);
        if (hHeap) {
            __try { HeapFree(hHeap, 0, (void *)(uintptr_t)p); }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
    } while (0);
    lua_pushboolean(Ls, alloced);             lua_setfield(Ls, -2, "alloc");
    lua_pushinteger(Ls, armed);               lua_setfield(Ls, -2, "armed");
    lua_pushinteger(Ls, slot);                lua_setfield(Ls, -2, "slot");
    lua_pushinteger(Ls, wrote);               lua_setfield(Ls, -2, "wrote");
    lua_pushinteger(Ls, hit);                 lua_setfield(Ls, -2, "hit");
    lua_pushinteger(Ls, (lua_Integer)value);  lua_setfield(Ls, -2, "value");
    return 1;
}

// ================= ntdll setter tracer (追凶) ============================
// 谁对游戏线程调 NtSetContextThread / NtSetInformationThread?
// 挂 ntdll 系统调用桩 (布局固定: mov r10,rcx; mov eax,imm32; syscall; ret),
// 偷前 8 字节 (两条整指令), 5 字节 E9 重定向到近旁 RX 块 (movabs 中转),
// 回放块还原两条指令后跳回 stub+8 (syscall)。桥自身调用 (dr_arm) 过滤。
typedef NTSTATUS (NTAPI *NtSCT_fn)(HANDLE, PCONTEXT);
typedef NTSTATUS (NTAPI *NtSIT_fn)(HANDLE, ULONG, PVOID, ULONG);

#define NTT_MAX 512
typedef struct {
    ULONG64 tick;
    int      kind;        // 0 = NtSetContextThread, 1 = NtSetInformationThread
    int      cls;         // SIT 信息类
    ULONG64 caller;       // 调用者返回地址 (绝对)
    ULONG64 modbase;      // 调用者模块基址 (0 = 未解析)
    DWORD    tid;         // 目标线程句柄值 (dump 时解析为 id, 解析失败 0)
    ULONG64 ctxFlags;
    ULONG64 dr0, dr1, dr2, dr7;
} NttRec;
static NttRec        g_ntt[NTT_MAX];
static volatile LONG g_nttN = 0, g_nttDrop = 0, g_nttOn = 0;
static NtSCT_fn      g_nttReplaySCT = NULL;   // 近旁块内回放入口
static NtSIT_fn      g_nttReplaySIT = NULL;
static uint8_t      *g_nttStubSCT = NULL, *g_nttStubSIT = NULL;
static uint8_t       g_nttSavedSCT[8], g_nttSavedSIT[8];
static void         *g_nttBlock = NULL;       // 近旁 RX 块 (中转+回放)

static ULONG64 ntt_self_base(void) {
    HMODULE m = NULL;
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                       GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       (LPCSTR)(void *)&ntt_self_base, &m);
    return (ULONG64)(uintptr_t)m;
}

static void ntt_record(int kind, HANDLE h, int cls, PCONTEXT ctx) {
    // VEH 级纪律: thunk 路径零 API 零锁 (旧版在启动期调 GetModuleHandleExA/
    // GetThreadId 与 loader lock 语境互锁致死) — 只存裸值, dump 惰性解析
    if (!g_nttOn) return;
    // 噪声过滤: SIT 常规类 (优先级 2/3 等 <=0xF) 不记, 只留冷门类
    // (0x11 = ThreadHideFromDebugger 等); SCT (NtSetContextThread) 全记
    if (kind == 1 && cls >= 0 && cls <= 0xF) return;
    ULONG64 ret = (ULONG64)(uintptr_t)_ReturnAddress();
    ULONG64 self = ntt_self_base();
    if (self && ret >= self && ret < self + 0x400000) return;  // 桥自身
    LONG i = InterlockedIncrement(&g_nttN) - 1;
    if (i >= NTT_MAX) { InterlockedIncrement(&g_nttDrop); return; }
    NttRec *r = &g_ntt[i];
    r->tick = 0; r->kind = kind; r->cls = cls;
    r->caller = ret; r->modbase = 0;
    r->tid = (DWORD)(ULONG64)(uintptr_t)h;   // 裸句柄值 (dump 时解析)
    r->ctxFlags = 0; r->dr0 = r->dr1 = r->dr2 = r->dr7 = 0;
    if (kind == 0 && ctx) {
        r->ctxFlags = ctx->ContextFlags;
        r->dr0 = ctx->Dr0; r->dr1 = ctx->Dr1;
        r->dr2 = ctx->Dr2; r->dr7 = ctx->Dr7;
    }
}

static NTSTATUS NTAPI ntt_thunk_sct(HANDLE h, PCONTEXT ctx) {
    ntt_record(0, h, 0, ctx);
    return g_nttReplaySCT(h, ctx);
}
static NTSTATUS NTAPI ntt_thunk_sit(HANDLE h, ULONG cls, PVOID buf, ULONG len) {
    ntt_record(1, h, (int)cls, NULL);
    return g_nttReplaySIT(h, cls, buf, len);
}

// 挂起全进程线程 (跳过 self); 返回句柄数 (负数 = 有线程无法检查, 其绝对值为成功挂起数)
static int ntt_suspend_all(HANDLE *out, int cap, DWORD self_tid) {
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    THREADENTRY32 te; te.dwSize = sizeof(te);
    BOOL ok = Thread32First(snap, &te);
    DWORD pid = GetCurrentProcessId();
    int n = 0, nfailed = 0;
    while (ok) {
        if (te.th32OwnerProcessID == pid && te.th32ThreadID != self_tid && n < cap) {
            HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT, FALSE, te.th32ThreadID);
            if (h) {
                if (SuspendThread(h) != (DWORD)-1) out[n++] = h;
                else { CloseHandle(h); nfailed++; }
            } else nfailed++;
        }
        ok = Thread32Next(snap, &te);
    }
    CloseHandle(snap);
    return nfailed ? -n : n;
}

static void ntt_resume_all(HANDLE *arr, int n) {
    for (int i = 0; i < n; i++) { ResumeThread(arr[i]); CloseHandle(arr[i]); }
}

// 中断窗口内是否有线程 RIP 落在 [lo, lo+len)
static int ntt_rip_in_window(HANDLE *arr, int n, uint8_t *lo, int len) {
    for (int i = 0; i < n; i++) {
        CONTEXT c; c.ContextFlags = CONTEXT_CONTROL;
        if (GetThreadContext(arr[i], &c)) {
            ULONG64 rip = c.Rip;
            if (rip >= (ULONG64)(uintptr_t)lo && rip < (ULONG64)(uintptr_t)lo + len)
                return 1;
        }
    }
    return 0;
}

// 在 stub 处写 E9 rel32 + CC 填充 (调用方负责挂起/校验)
static int ntt_write_patch(uint8_t *stub, void *target) {
    LONG64 rel = (LONG64)(uintptr_t)target - (LONG64)(uintptr_t)(stub + 5);
    if (rel > 0x7FFFFFFFLL || rel < -0x7FFFFFFFLL) return 0;
    DWORD old = 0;
    if (!VirtualProtect(stub, 8, PAGE_EXECUTE_READWRITE, &old)) return 0;
    stub[0] = 0xE9;
    *(int32_t *)(stub + 1) = (int32_t)rel;
    stub[5] = stub[6] = stub[7] = 0xCC;
    VirtualProtect(stub, 8, old, &old);
    FlushInstructionCache(GetCurrentProcess(), stub, 8);
    return 1;
}

static int ntt_restore_patch(uint8_t *stub, const uint8_t *saved) {
    DWORD old = 0;
    if (!VirtualProtect(stub, 8, PAGE_EXECUTE_READWRITE, &old)) return 0;
    memcpy(stub, saved, 8);
    VirtualProtect(stub, 8, old, &old);
    FlushInstructionCache(GetCurrentProcess(), stub, 8);
    return 1;
}

// 近旁块布局 (RX, CFG 安全 — 全部用 FF 25 jmp [rip+0] + imm64 尾,
// 不用 jmp reg: CFG 对寄存器间接跳校验目标, thunk 不在 GFID 表 = 快速失败):
// [0]  redirect_sct: FF 25 00 00 00 00 <thunk_sct imm64>   = 14B
// [16] redirect_sit: FF 25 00 00 00 00 <thunk_sit imm64>   = 14B
// [32] replay_sct:   <原 8B> FF 25 00 00 00 00 <stub+8>    = 22B
// [56] replay_sit:   <原 8B> FF 25 00 00 00 00 <stub+8>    = 22B
static void ntt_emit_ff25(uint8_t *at, ULONG64 target) {
    at[0]=0xFF; at[1]=0x25; at[2]=at[3]=at[4]=at[5]=0;   // jmp qword [rip+0]
    memcpy(at+6, &target, 8);                             // 目标紧跟指令后
}
static int ntt_build_block(uint8_t *near_base, uint8_t *stub_sct, uint8_t *stub_sit) {
    uint8_t *b = (uint8_t *)near_base;
    ntt_emit_ff25(b,      (ULONG64)(uintptr_t)&ntt_thunk_sct);
    ntt_emit_ff25(b+16,   (ULONG64)(uintptr_t)&ntt_thunk_sit);
    memcpy(b+32, stub_sct, 8);
    ntt_emit_ff25(b+40,   (ULONG64)(uintptr_t)(stub_sct + 8));
    memcpy(b+56, stub_sit, 8);
    ntt_emit_ff25(b+64,   (ULONG64)(uintptr_t)(stub_sit + 8));
    DWORD old = 0;
    VirtualProtect(b, 96, PAGE_EXECUTE_READWRITE, &old);
    FlushInstructionCache(GetCurrentProcess(), b, 96);
    return 1;
}

// 安装核心 (DllMain 期与 Lua 期共用): 挂 ntdll 双桩, 开记录
static int ntt_install(void) {
    if (g_nttOn) return 1;
    HMODULE nt = GetModuleHandleA("ntdll.dll");
    uint8_t *sct = (uint8_t *)(void *)GetProcAddress(nt, "NtSetContextThread");
    uint8_t *sit = (uint8_t *)(void *)GetProcAddress(nt, "NtSetInformationThread");
    if (!sct || !sit) return 0;
    if (sct[0]!=0x4C||sct[1]!=0x8B||sct[2]!=0xD1||sct[3]!=0xB8) return 0;
    if (sit[0]!=0x4C||sit[1]!=0x8B||sit[2]!=0xD1||sit[3]!=0xB8) return 0;
    uint8_t *blk = (uint8_t *)VirtualAlloc((void *)((ULONG64)(uintptr_t)sct - 0x40000000),
                                           96, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!blk)
        blk = (uint8_t *)VirtualAlloc(nullptr, 96, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!blk) return 0;
    ntt_build_block(blk, sct, sit);
    HANDLE th[512];
    int n = ntt_suspend_all(th, 512, GetCurrentThreadId());
    if (n <= 0) {
        if (n < 0) ntt_resume_all(th, -n);
        VirtualFree(blk, 0, MEM_RELEASE);
        return 0;
    }
    int inwin = ntt_rip_in_window(th, n, sct, 8) || ntt_rip_in_window(th, n, sit, 8);
    int ok = 0;
    if (!inwin) {
        memcpy(g_nttSavedSCT, sct, 8);
        memcpy(g_nttSavedSIT, sit, 8);
        if (ntt_write_patch(sct, blk) && ntt_write_patch(sit, blk + 16)) {
            g_nttStubSCT = sct; g_nttStubSIT = sit;
            g_nttReplaySCT = (NtSCT_fn)(void *)(blk + 32);
            g_nttReplaySIT = (NtSIT_fn)(void *)(blk + 56);
            g_nttBlock = blk;
            g_nttN = 0; g_nttDrop = 0;
            InterlockedExchange(&g_nttOn, 1);
            ok = 1;
        } else {
            ntt_restore_patch(sct, g_nttSavedSCT);
            ntt_restore_patch(sit, g_nttSavedSIT);
            VirtualFree(blk, 0, MEM_RELEASE);
        }
    } else {
        VirtualFree(blk, 0, MEM_RELEASE);
    }
    ntt_resume_all(th, n);
    L("[ntt] trace %s (sct=%llx sit=%llx blk=%llx)", ok ? "started" : "REFUSED",
      (unsigned long long)(uintptr_t)sct, (unsigned long long)(uintptr_t)sit,
      (unsigned long long)(uintptr_t)blk);
    return ok;
}

// hoi4.dr_tracestart() -> true/nil (Lua 壳; 运行期补装/查询)
int hoi4_dr_tracestart(lua_State *Ls) {
    lua_pushboolean(Ls, ntt_install());
    return 1;
}

// DllMain 期早期安装 (install_hooks 尾部调): 抓启动期毒化调用
int dr_trace_early_install(void) { return ntt_install(); }

// hoi4.dr_tracestop() -> true
int hoi4_dr_tracestop(lua_State *Ls) {
    if (!g_nttOn) { lua_pushboolean(Ls, 1); return 1; }
    InterlockedExchange(&g_nttOn, 0);
    HANDLE th[512];
    int n = ntt_suspend_all(th, 512, GetCurrentThreadId());
    if (n > 0) {
        ntt_restore_patch(g_nttStubSCT, g_nttSavedSCT);
        ntt_restore_patch(g_nttStubSIT, g_nttSavedSIT);
        ntt_resume_all(th, n);
    } else if (n < 0) ntt_resume_all(th, -n);
    if (g_nttBlock) { VirtualFree(g_nttBlock, 0, MEM_RELEASE); g_nttBlock = NULL; }
    g_nttStubSCT = g_nttStubSIT = NULL;
    L("[ntt] trace stopped (n=%d drop=%d)", (int)g_nttN, (int)g_nttDrop);
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.dr_tracedump() -> {n, drop, recs={{kind,cls,tid,mod,off,dr0,dr1,dr2,dr7,flags},...}}
int hoi4_dr_tracedump(lua_State *Ls) {
    lua_newtable(Ls);
    LONG n = g_nttN; if (n > NTT_MAX) n = NTT_MAX;
    lua_pushinteger(Ls, n);    lua_setfield(Ls, -2, "n");
    lua_pushinteger(Ls, g_nttDrop); lua_setfield(Ls, -2, "drop");
    lua_newtable(Ls);
    int shown = n < 64 ? (int)n : 64;
    for (int i = 0; i < shown; i++) {
        NttRec *r = &g_ntt[i];
        char mod[96] = "?";
        HMODULE m = NULL;
        if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                               (LPCSTR)(void *)r->caller, &m)) {
            r->modbase = (ULONG64)(uintptr_t)m;
            char path[MAX_PATH] = {0};
            if (GetModuleFileNameA(m, path, MAX_PATH)) {
                const char *base = path + strlen(path);
                while (base > path && base[-1] != '\\') base--;
                strncpy(mod, base, 90);
            }
        }
        // 惰性解析: 句柄 -> tid (句柄可能已关, 解析失败保句柄值)
        DWORD tid = 0;
        if (r->tid) {
            tid = GetThreadId((HANDLE)(uintptr_t)r->tid);
            if (!tid) tid = r->tid;   // 已关句柄: 保留句柄值供人工比对
        }
        lua_newtable(Ls);
        lua_pushinteger(Ls, r->kind);      lua_setfield(Ls, -2, "kind");
        lua_pushinteger(Ls, r->cls);       lua_setfield(Ls, -2, "cls");
        lua_pushinteger(Ls, (lua_Integer)tid); lua_setfield(Ls, -2, "tid");
        lua_pushstring(Ls, mod);           lua_setfield(Ls, -2, "mod");
        lua_pushinteger(Ls, (lua_Integer)(r->caller - r->modbase)); lua_setfield(Ls, -2, "off");
        lua_pushinteger(Ls, (lua_Integer)r->dr0); lua_setfield(Ls, -2, "dr0");
        lua_pushinteger(Ls, (lua_Integer)r->dr1); lua_setfield(Ls, -2, "dr1");
        lua_pushinteger(Ls, (lua_Integer)r->dr2); lua_setfield(Ls, -2, "dr2");
        lua_pushinteger(Ls, (lua_Integer)r->dr7); lua_setfield(Ls, -2, "dr7");
        lua_pushinteger(Ls, (lua_Integer)r->ctxFlags); lua_setfield(Ls, -2, "flags");
        lua_rawseti(Ls, -2, i + 1);
    }
    lua_setfield(Ls, -2, "recs");
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
        lua_pushinteger(Ls, (lua_Integer)g_drRing[i].tid);
        lua_setfield(Ls, -2, "tid");
        lua_pushinteger(Ls, g_drRing[i].slot);
        lua_setfield(Ls, -2, "slot");
        lua_pushinteger(Ls, (lua_Integer)g_drRing[i].watch);
        lua_setfield(Ls, -2, "watch");
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
    lua_pushinteger(Ls, g_drTotal);
    lua_setfield(Ls, -2, "total");
    ReleaseSRWLockShared(&g_drLock);
    return 1;
}

// hoi4.dr_top([n]) -> {total, entries={{rip_rva, hits, watch, slot, chain0}, ...}}
// 环内容按 RIP 聚合, hits 降序 (环 64 深、满后丢旧 — total 才是全量计数)。
int hoi4_dr_top(lua_State *Ls) {
    int want = (int)luaL_optinteger(Ls, 1, 16);
    if (want < 1) want = 1;
    if (want > DR_MAX_HITS) want = DR_MAX_HITS;
    struct Agg { ULONG64 rip; ULONG64 watch; unsigned slot; unsigned n; ULONG64 chain0; };
    Agg agg[DR_MAX_HITS];
    int nagg = 0;
    LONG total = 0;
    AcquireSRWLockShared(&g_drLock);
    total = g_drTotal;
    for (int i = 0; i < g_drCount; i++) {
        DrHit *h = &g_drRing[i];
        int k = 0;
        while (k < nagg && agg[k].rip != h->ripRva) k++;
        if (k < nagg) { agg[k].n++; continue; }
        if (nagg < DR_MAX_HITS) {
            agg[nagg].rip = h->ripRva;
            agg[nagg].watch = h->watch;
            agg[nagg].slot = h->slot;
            agg[nagg].n = 1;
            agg[nagg].chain0 = h->nchain ? h->chain[0] : 0;
            nagg++;
        }
    }
    ReleaseSRWLockShared(&g_drLock);
    for (int i = 0; i < nagg - 1; i++) {          // hits 降序 (选择排序, <=64 项)
        int mx = i;
        for (int j = i + 1; j < nagg; j++)
            if (agg[j].n > agg[mx].n) mx = j;
        if (mx != i) { Agg t = agg[i]; agg[i] = agg[mx]; agg[mx] = t; }
    }
    if (nagg > want) nagg = want;
    lua_newtable(Ls);
    lua_pushinteger(Ls, total);
    lua_setfield(Ls, -2, "total");
    lua_newtable(Ls);
    for (int k = 0; k < nagg; k++) {
        lua_newtable(Ls);
        lua_pushinteger(Ls, (lua_Integer)agg[k].rip);    lua_setfield(Ls, -2, "rip_rva");
        lua_pushinteger(Ls, agg[k].n);                   lua_setfield(Ls, -2, "hits");
        lua_pushinteger(Ls, (lua_Integer)agg[k].watch);  lua_setfield(Ls, -2, "watch");
        lua_pushinteger(Ls, agg[k].slot);                lua_setfield(Ls, -2, "slot");
        lua_pushinteger(Ls, (lua_Integer)agg[k].chain0); lua_setfield(Ls, -2, "chain0");
        lua_rawseti(Ls, -2, k + 1);
    }
    lua_setfield(Ls, -2, "entries");
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
        hit.tid = GetCurrentThreadId();
        hit.slot = 0xF;                        // 哨兵: guard 页命中 (非 DR 槽)
        hit.watch = (ULONG64)(volatile LONG64 &)g_gpAddr;
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
