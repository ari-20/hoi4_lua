// hoi4_sampler.cpp - in-process sampling profiler for the game main thread.
//
// Answers "which function is hot" at function granularity — the engine's own
// zone profiler (book §4.9) only goes down to subsystem level. Two modes:
//
//   leaf mode (default)  - RIP histogram, cheapest suspension window.
//   stack mode           - full call-stack capture per sample, folded-stack
//                          histogram for flame graphs (sampler_annotate.py).
//   scope "all"          - additionally sweep EVERY process thread each tick
//                          (leaf RIP only; the main thread keeps its full
//                          capture incl. optional stacks) plus per-thread CPU
//                          deltas via GetThreadTimes. Answers "what are the
//                          tbb workers actually running". Access:
//                          hoi4.profile_threads() / GET /profile/threads.
//   scope "main" (default) - only the calling thread (the game main thread).
//
//   Sweep economics: ~90 threads x (suspend+ctx+resume) costs ~1-3 ms per
//   sweep, so "all" scope refuses intervals below 10 ms (clamped). The
//   sampler thread itself is excluded from its own sweep.
//
// Design invariants:
//
//   - Capture window (target suspended): kernel calls + memory reads ONLY.
//     No bridge locks, no CRT, no allocations — the suspended main thread may
//     be holding the process heap lock, and taking anything it holds would
//     wedge the sampler while it keeps the main thread frozen.
//   - Stack unwinding uses ntdll RtlLookupFunctionEntry + RtlVirtualUnwind
//     (resolved via GetProcAddress): allocation-free, lock-free, driven purely
//     by the target module's .pdata unwind metadata. Same technique as the
//     Firefox/Chrome in-process profilers.
//   - RIP -> function attribution needs no symbol files: hoi4.exe's own
//     exception directory (.pdata RUN table) is a sorted list of function
//     starts; parsed once, binary-searched per sample. Offline annotation
//     (rva -> sub_NAME) happens in the Python tool against the corpus.
//   - Commit window (target resumed): histogram/folded inserts under smp.cs.
//     Readers take the same CS; they only ever wait on a RUNNING main thread.
//   - Target thread = whoever called profile_start. /lua and console `lua`
//     run at frame top on the main thread, so the target is right by
//     construction. Async workers never see the hoi4 table.
//   - Auto-stop after SAMP_FAIL_LIMIT consecutive failed captures (target
//     gone = process shutdown); profile_stop cleans up after auto-stop too.
//
// Lua surface:
//   hoi4.profile_start([interval_ms[, stacks[, all]]])  -> "ok ..." (error if running)
//   hoi4.profile_stop()                                 -> summary string, keeps data
//   hoi4.profile_top([n])                               -> lines "count rva|rip <hex>"
//   hoi4.profile_folded([path])                         -> writes folded stacks file
//   hoi4.profile_threads()                              -> per-tid hits/cpu table
//   hoi4.profile_status()                               -> counters string
#include "hoi4_common.h"
#include <tlhelp32.h>
#include <string>
#include <vector>
#include <unordered_map>
#include <algorithm>

#define SAMP_TABLE_BITS      16
#define SAMP_TABLE_SIZE      (1u << SAMP_TABLE_BITS)     // 64K slots = 1 MB
#define SAMP_INTERVAL_MIN_MS 1
#define SAMP_INTERVAL_MAX_MS 1000
#define SAMP_ALL_MIN_MS      10                           // sweep ~90 threads per tick is not free
#define SAMP_TOP_MAX         200                          // fits the 8 KB /lua result
#define SAMP_FAIL_LIMIT      64                           // consecutive capture failures -> auto stop
#define SAMP_MAX_FRAMES      64
#define SAMP_TID_MAX         256
#define SAMP_TID_REFRESH     2000                         // ms between thread-table rebuilds
#define SAMP_TID_DEADRUNS    16                           // sweeps failing before tid is dropped

typedef struct {
    uint64_t key;    // 0 = empty slot; bit0 set = raw RIP (unresolved); else func-start RVA
    uint64_t count;
} SampSlot;

static struct {
    CRITICAL_SECTION   cs;
    HANDLE             hStop;        // signalled by profile_stop
    HANDLE             hTimer;       // high-resolution periodic timer (may be NULL)
    HANDLE             hThread;      // target (game main thread)
    HANDLE             hWorker;
    DWORD              targetTid;
    DWORD              intervalMs;
    int                stacks;       // 1 = full stack capture per sample
    SampSlot          *tab;          // preallocated at start (main thread)
    unsigned long long total;        // samples taken
    unsigned long long ext;          // samples outside hoi4.exe .pdata (raw RIP kept)
    unsigned long long suspendFail;
    unsigned long long ctxFail;
    unsigned long long dropped;      // table pressure rejections
    volatile LONG      running;      // 0 idle, 1 sampling
} g_smp;
static int g_diagLogged;             // one-shot first-failure diagnostic

// ---- scope "all": process-wide thread table (worker-owned, no CS needed:
// only samp_worker reads/mutates it; samp_api_threads copies under CS) ----
typedef struct {
    DWORD              tid;
    HANDLE             h;              // SUSPEND_RESUME|GET_CONTEXT|QUERY_INFORMATION
    unsigned long long hits;           // samples attributed to this tid
    unsigned long long cpuPrev;        // kernel+user, 100ns units, last refresh
    unsigned long long cpuDelta;       // last refresh window's cpu delta (100ns)
    DWORD              deadRuns;       // consecutive failed SuspendThread calls
} SampTid;
static struct {
    int    all;                        // scope flag
    SampTid tids[SAMP_TID_MAX];
    int    count;
    DWORD  selfTid;                    // sampler worker's own tid (excluded)
    DWORD  mainTid;                    // target tid (excluded from the sweep:
                                       // it gets the full capture path)
    unsigned long long lastRefreshMs;
} g_scope;

// folded-stack histogram (stack mode; key = "ripA;ripB;ripC" root->leaf)
static std::unordered_map<std::string, uint64_t> g_folded;
static unsigned long long g_foldedTotal;

// ---- .pdata function table (parsed once, main thread, on first start) ----
static uint32_t *g_pdata;        // sorted function-start RVAs
static int       g_pdataN;
static uint64_t  g_imgLo, g_imgHi;

// ---- ntdll unwind exports (resolved lazily; no import-lib change) ----
typedef struct _SampRunFn { DWORD BeginAddress, EndAddress, UnwindData; } SampRunFn;
typedef SampRunFn *(__stdcall *RtlLookupFunctionEntry_t)(DWORD64, PDWORD64, PVOID);
typedef DWORD64 (__stdcall *RtlVirtualUnwind_t)(DWORD, DWORD64, DWORD64, SampRunFn *,
                                                PCONTEXT, PVOID *, PDWORD64, PVOID);
static RtlLookupFunctionEntry_t pRtlLookupFunctionEntry;
static RtlVirtualUnwind_t       pRtlVirtualUnwind;

static void sampler_resolve_unwind(void)
{
    if (pRtlLookupFunctionEntry) return;
    HMODULE nt = GetModuleHandleW(L"ntdll.dll");
    if (!nt) return;
    pRtlLookupFunctionEntry =
        (RtlLookupFunctionEntry_t)GetProcAddress(nt, "RtlLookupFunctionEntry");
    pRtlVirtualUnwind =
        (RtlVirtualUnwind_t)GetProcAddress(nt, "RtlVirtualUnwind");
}

static int pdata_build(void)
{
    if (g_pdata) return 1;
    if (!g_base) return 0;
    sampler_resolve_unwind();
    uint8_t *b = (uint8_t *)g_base;
    __try {
        if (*(uint16_t *)b != 0x5A4D) return 0;
        uint32_t eLfanew = *(uint32_t *)(b + 0x3C);
        PIMAGE_NT_HEADERS nt = (PIMAGE_NT_HEADERS)(b + eLfanew);
        if (nt->Signature != IMAGE_NT_SIGNATURE) return 0;
        g_imgLo = (uint64_t)(uintptr_t)b;
        g_imgHi = g_imgLo + nt->OptionalHeader.SizeOfImage;
        const IMAGE_DATA_DIRECTORY *dd =
            nt->OptionalHeader.DataDirectory + IMAGE_DIRECTORY_ENTRY_EXCEPTION;
        int n = (int)(dd->Size / sizeof(IMAGE_RUNTIME_FUNCTION_ENTRY));
        if (n <= 0 || dd->VirtualAddress == 0) return 0;
        uint32_t *arr = (uint32_t *)malloc((size_t)n * 4);
        if (!arr) return 0;
        const uint8_t *p = b + dd->VirtualAddress;
        for (int i = 0; i < n; i++)
            arr[i] = *(const uint32_t *)(p + (size_t)i * 12);   // BeginAddress
        g_pdata = arr;
        g_pdataN = n;
        L("[sampler] .pdata: %d function starts, image %llx..%llx",
          n, (unsigned long long)g_imgLo, (unsigned long long)g_imgHi);
        return 1;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

// greatest function start <= rva; 0 when rva precedes the first function
static uint32_t pdata_func(uint32_t rva)
{
    int lo = 0, hi = g_pdataN - 1, ans = -1;
    while (lo <= hi) {
        int mid = (lo + hi) >> 1;
        if (g_pdata[mid] <= rva) { ans = mid; lo = mid + 1; }
        else hi = mid - 1;
    }
    return ans >= 0 ? g_pdata[ans] : 0;
}

// ---- scope "all" thread table ----
static void samp_add_locked(uint64_t rip);       // defined with the commit helpers below

// Close handles only — rows/stats survive stop (readers need them post-stop,
// same contract as the leaf histogram; next start's refresh rebuilds handles).
static void tids_close_handles(void)
{
    for (int i = 0; i < g_scope.count; i++)
        if (g_scope.tids[i].h) { CloseHandle(g_scope.tids[i].h); g_scope.tids[i].h = nullptr; }
}

static void tids_close_all(void)
{
    tids_close_handles();
    g_scope.count = 0;
}

// Rebuild the table from a Toolhelp snapshot. Surviving tids keep their
// hits/cpuPrev; new tids join; gone tids' handles close. Runs on the worker
// thread between sweeps — no lock needed.
static void tids_refresh(void)
{
    unsigned long long prevCpu[SAMP_TID_MAX];
    DWORD prevTid[SAMP_TID_MAX];
    unsigned long long prevHits[SAMP_TID_MAX], prevDelta[SAMP_TID_MAX];
    int keep = 0;
    for (int i = 0; i < g_scope.count && keep < SAMP_TID_MAX; i++) {
        prevTid[keep]   = g_scope.tids[i].tid;
        prevCpu[keep]   = g_scope.tids[i].cpuPrev;
        prevHits[keep]  = g_scope.tids[i].hits;
        prevDelta[keep] = g_scope.tids[i].cpuDelta;
        keep++;
    }
    tids_close_handles();                                   // refresh rebuilds itself

    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return;
    THREADENTRY32 te;
    te.dwSize = sizeof(te);
    DWORD pid = GetCurrentProcessId();
    DWORD selfTid = GetCurrentThreadId();
    int n = 0;
    if (Thread32First(snap, &te)) do {
        if (te.th32OwnerProcessID != pid) continue;
        if (te.th32ThreadID == selfTid) continue;          // never sample ourselves
        if (n >= SAMP_TID_MAX) break;
        HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                              THREAD_QUERY_INFORMATION, FALSE, te.th32ThreadID);
        if (!h) continue;
        SampTid *t = &g_scope.tids[n];
        memset(t, 0, sizeof(*t));
        t->tid = te.th32ThreadID;
        t->h   = h;
        for (int k = 0; k < keep; k++)                     // tiny: carry stats over
            if (prevTid[k] == t->tid) {
                t->hits     = prevHits[k];
                t->cpuPrev  = prevCpu[k];
                t->cpuDelta = prevDelta[k];
                break;
            }
        n++;
    } while (Thread32Next(snap, &te));
    CloseHandle(snap);
    g_scope.count = n;
    g_scope.lastRefreshMs = GetTickCount64();
}

// CPU-time deltas per thread (GetThreadTimes kernel+user), refreshed alongside
// the table rebuild cadence. Cheap, no suspension.
static void tids_cpu_refresh(void)
{
    for (int i = 0; i < g_scope.count; i++) {
        SampTid *t = &g_scope.tids[i];
        FILETIME cr, ex, kr, us;
        if (!GetThreadTimes(t->h, &cr, &ex, &kr, &us)) continue;
        unsigned long long now =
            (((unsigned long long)kr.dwHighDateTime << 32) | kr.dwLowDateTime) +
            (((unsigned long long)us.dwHighDateTime << 32) | us.dwLowDateTime);
        if (t->cpuPrev)
            t->cpuDelta = now - t->cpuPrev;
        t->cpuPrev = now;
    }
}

        // One leaf sample per live thread. Runs in the worker, target threads only
// briefly suspended. The sampler's own tid and the main tid are skipped (the
// main tid is captured by the primary path with optional stacks). hits/total
// move under CS so samp_api_threads never races the counters.
static void samp_sweep_all(void)
{
    CONTEXT ctx;
    for (int i = 0; i < g_scope.count; i++) {
        SampTid *t = &g_scope.tids[i];
        if (t->tid == g_scope.mainTid) continue;
        DWORD prev = SuspendThread(t->h);
        if (prev == (DWORD)-1) { if (++t->deadRuns > SAMP_TID_DEADRUNS) t->tid = 0; continue; }
        memset(&ctx, 0, sizeof(ctx));
        ctx.ContextFlags = CONTEXT_CONTROL;
        int got = GetThreadContext(t->h, &ctx);
        ResumeThread(t->h);
        if (!got) continue;
        EnterCriticalSection(&g_smp.cs);
        samp_add_locked(ctx.Rip);
        t->hits++;
        g_smp.total++;
        LeaveCriticalSection(&g_smp.cs);
    }
    // compaction of dropped tids + periodic table/cpu refresh
    int w = 0;
    for (int i = 0; i < g_scope.count; i++)
        if (g_scope.tids[i].tid) g_scope.tids[w++] = g_scope.tids[i];
    g_scope.count = w;
    unsigned long long now = GetTickCount64();
    if (now - g_scope.lastRefreshMs >= SAMP_TID_REFRESH) {
        tids_refresh();
        tids_cpu_refresh();
    }
}


// ---- capture window primitives (target suspended; no locks/allocs) ----

// Walk the suspended target's stack into out[] (leaf first). Bounds are
// defensive: non-canonical RIP, missing unwind info, and non-monotonic RSP
// all terminate the walk. RtlLookupFunctionEntry gets a NULL history table:
// it is only a lookup-cache optimization, and its 12-slot layout is easy to
// size wrong — a mis-sized table is a stack overflow the OS can't see. The
// whole walk is SEH-wrapped: bad unwind metadata anywhere must cost one
// sample, never the process (a worker crash kills hoi4.exe).
static int samp_walk_stack_core(PCONTEXT ctx, uint64_t *out, int maxf)
{
    int n = 0;
    CONTEXT c = *ctx;
    uint64_t prevRsp = 0, prevRip = 0;
    while (n < maxf) {
        uint64_t rip = c.Rip;
        if (!rip || (rip >> 47)) break;                    // non-canonical / kernel
        out[n++] = rip;
        if (!pRtlLookupFunctionEntry || !pRtlVirtualUnwind) break;
        uint64_t ibase = 0;
        SampRunFn *rf = nullptr;
        // HandlerData / EstablisherFrame must be REAL out-pointers: frames
        // with handler-info (common in ntdll wait stubs) make RtlVirtualUnwind
        // write through them unconditionally — NULL = access violation.
        PVOID handlerData = nullptr;
        uint64_t estabFrame = 0;
        __try {
            rf = pRtlLookupFunctionEntry(rip, &ibase, nullptr);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { break; }
        if (!rf) break;
        __try {
            pRtlVirtualUnwind(0, ibase, rip, rf, &c,
                              &handlerData, &estabFrame, nullptr);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { break; }      // partial stack kept
        if (c.Rsp <= prevRsp || !c.Rip || c.Rip == prevRip) break;
        prevRsp = c.Rsp;
        prevRip = c.Rip;
    }
    return n;
}

static int samp_walk_stack(PCONTEXT ctx, uint64_t *out, int maxf)
{
    __try { return samp_walk_stack_core(ctx, out, maxf); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

// ---- commit window helpers (target running; cs held) ----
static void samp_add_locked(uint64_t rip)
{
    uint64_t key = 0;
    if (rip >= g_imgLo && rip < g_imgHi) {
        uint32_t fr = pdata_func((uint32_t)(rip - g_imgLo));
        if (fr) key = fr;                    // func-start RVA (16-aligned, bit0 clear)
    }
    if (!key) { key = rip | 1; g_smp.ext++; }
    uint32_t i = (uint32_t)((key * 0x9E3779B97F4A7C15ull) >> 48)
               & (SAMP_TABLE_SIZE - 1);
    for (int probe = 0; probe < 64; probe++) {
        SampSlot *s = &g_smp.tab[i];
        if (s->key == 0) { s->key = key; s->count = 1; return; }
        if (s->key == key) { s->count++; return; }
        i = (i + 1) & (SAMP_TABLE_SIZE - 1);
    }
    g_smp.dropped++;                          // 64-slot probe bound: never hit in practice
}

// frames[] is leaf-first; folded format wants root first ("a;b;c" + count)
static void samp_fold_locked(const uint64_t *frames, int n)
{
    std::string key;
    key.reserve((size_t)n * 13);
    char tmp[24];
    for (int i = n - 1; i >= 0; i--) {
        _snprintf_s(tmp, sizeof(tmp), _TRUNCATE, "%llx%c",
                    (unsigned long long)frames[i], i ? ';' : '\0');
        key += tmp;
    }
    g_folded[key]++;
    g_foldedTotal++;
}

static int samp_slot_cmp_count(const void *a, const void *b)
{
    uint64_t ca = ((const SampSlot *)a)->count, cb = ((const SampSlot *)b)->count;
    return ca < cb ? 1 : ca > cb ? -1 : 0;
}

// ---- worker ----
static DWORD WINAPI samp_worker(LPVOID arg)
{
    (void)arg;
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
    HANDLE waitOn[2] = { g_smp.hStop, g_smp.hTimer };
    uint64_t walk[SAMP_MAX_FRAMES];
    int failRun = 0;
    for (;;) {
        DWORD w = g_smp.hTimer
            ? WaitForMultipleObjects(2, waitOn, FALSE, INFINITE)
            : WaitForSingleObject(g_smp.hStop, (DWORD)g_smp.intervalMs);
        if (w == WAIT_OBJECT_0) break;                       // stop signalled
        if (g_smp.hTimer && w != WAIT_OBJECT_0 + 1) {
            L("[sampler] wait unexpected: w=%lu err=%lu", w, GetLastError());
            break;                                           // never silent again
        }
        // (no-timer fallback: WAIT_TIMEOUT falls through to a sample)
        CONTEXT ctx;
        memset(&ctx, 0, sizeof(ctx));
        ctx.ContextFlags = g_smp.stacks ? CONTEXT_FULL : CONTEXT_CONTROL;
        // capture window — see file header for the no-locks/no-allocs rule.
        DWORD prev = SuspendThread(g_smp.hThread);
        int nframes = 0, ok = 0, suspended = (prev != (DWORD)-1);
        if (suspended) {
            DWORD gtcErr = 0;
            if (GetThreadContext(g_smp.hThread, &ctx)) {
                nframes = g_smp.stacks
                    ? samp_walk_stack(&ctx, walk, SAMP_MAX_FRAMES)
                    : (walk[0] = ctx.Rip, 1);
                ok = (nframes > 0);              // empty walk = failed sample
            } else {
                gtcErr = GetLastError();
            }
            ResumeThread(g_smp.hThread);
            if (!ok && !g_diagLogged) {
                g_diagLogged = 1;
                L("[sampler] first-fail diag: gtc=%lu rip=%llx rsp=%llx flags=%llx frames=%d",
                  gtcErr, (unsigned long long)ctx.Rip, (unsigned long long)ctx.Rsp,
                  (unsigned long long)ctx.ContextFlags, nframes);
            }
        }
        // commit window — main thread is running again.
        EnterCriticalSection(&g_smp.cs);
        if (!ok) {
            if (!suspended) g_smp.suspendFail++; else g_smp.ctxFail++;
            failRun++;
        } else {
            if (g_smp.stacks) samp_fold_locked(walk, nframes);
            samp_add_locked(walk[0]);          // leaf histogram kept in both modes
            g_smp.total++;
            failRun = 0;
        }
        LeaveCriticalSection(&g_smp.cs);
        if (g_scope.all) samp_sweep_all();       // scope "all": one leaf per live thread
        if (failRun > SAMP_FAIL_LIMIT) break;
    }
    InterlockedExchange(&g_smp.running, 0);
    L("[sampler] worker exit: total=%llu ext=%llu stacks=%llu sfail=%llu ctxfail=%llu dropped=%llu",
      g_smp.total, g_smp.ext, g_foldedTotal,
      g_smp.suspendFail, g_smp.ctxFail, g_smp.dropped);
    return 0;
}

// ---- shared helpers ----
static void samp_counters_str(char *out, size_t cap, const char *head)
{
    _snprintf_s(out, cap, _TRUNCATE,
        "%s samples=%llu stacks=%llu external=%llu suspend_fail=%llu ctx_fail=%llu dropped=%llu",
        head, g_smp.total, g_foldedTotal, g_smp.ext,
        g_smp.suspendFail, g_smp.ctxFail, g_smp.dropped);
}

static void samp_reset_data(void)
{
    if (g_smp.tab) memset(g_smp.tab, 0, (size_t)SAMP_TABLE_SIZE * sizeof(SampSlot));
    g_folded.clear();
    g_foldedTotal = 0;
    g_smp.total = g_smp.ext = g_smp.suspendFail = g_smp.ctxFail = g_smp.dropped = 0;
}

// join + close per-run handles; safe to call twice / after an auto-stop
static void samp_teardown(void)
{
    SetEvent(g_smp.hStop);
    if (g_smp.hWorker) {
        WaitForSingleObject(g_smp.hWorker, 10000);
        CloseHandle(g_smp.hWorker);
        g_smp.hWorker = nullptr;
    }
    if (g_smp.hThread) { CloseHandle(g_smp.hThread); g_smp.hThread = nullptr; }
    if (g_smp.hTimer) CancelWaitableTimer(g_smp.hTimer);   // timer itself is reused
    tids_close_handles();                                   // rows/stats survive stop
}

// ---- C core (shared by the Lua wrappers and the HTTP endpoints) ----
// All samp_api_* are main-thread-only (buffers/CS conventions) — the HTTP
// endpoints reach them through the same frame-top queue as /lua.

// Returns NULL on success (out = info line), else a static error string.
const char *samp_api_start(unsigned interval_ms, int stacks, DWORD target_tid,
                           int all, char *out, size_t cap)
{
    if (InterlockedCompareExchange(&g_smp.running, 1, 0) != 0)
        return "profile already running (profile_stop first)";
    if (all && interval_ms < SAMP_ALL_MIN_MS)
        interval_ms = SAMP_ALL_MIN_MS;         // sweeping ~90 threads per tick is not free
    if (interval_ms < SAMP_INTERVAL_MIN_MS || interval_ms > SAMP_INTERVAL_MAX_MS)
        return "interval_ms out of range (1..1000)";
    if (!pdata_build()) { InterlockedExchange(&g_smp.running, 0);
                          return "pdata parse failed"; }
    if (stacks && (!pRtlLookupFunctionEntry || !pRtlVirtualUnwind)) {
        InterlockedExchange(&g_smp.running, 0);
        return "ntdll unwind exports unresolved";
    }
    HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                          THREAD_QUERY_INFORMATION, FALSE, target_tid);
    if (!h) { InterlockedExchange(&g_smp.running, 0);
              return "OpenThread(self) failed"; }

    if (!g_smp.tab) {
        g_smp.tab = (SampSlot *)calloc(SAMP_TABLE_SIZE, sizeof(SampSlot));
        if (!g_smp.tab) { CloseHandle(h); InterlockedExchange(&g_smp.running, 0);
                          return "histogram alloc failed"; }
        InitializeCriticalSection(&g_smp.cs);
        g_smp.hStop = CreateEventA(nullptr, TRUE, FALSE, nullptr);
        // High-resolution waitable timer: no timeBeginPeriod global side
        // effect. Signature is (attrs, name, flags, access) — the flag goes
        // in slot 3; a timer handle needs sync+modify-state access. Fall
        // back to a plain timer, then to Sleep pacing in the worker.
        g_smp.hTimer = CreateWaitableTimerExW(nullptr, nullptr,
                                              CREATE_WAITABLE_TIMER_HIGH_RESOLUTION,
                                              TIMER_ALL_ACCESS);
        if (!g_smp.hTimer) g_smp.hTimer = CreateWaitableTimerW(nullptr, 0, nullptr);
    }
    samp_reset_data();
    g_smp.targetTid  = target_tid;
    g_smp.intervalMs = interval_ms;
    g_smp.stacks     = stacks;
    g_smp.hThread    = h;
    g_scope.all      = all;
    g_scope.mainTid  = target_tid;
    g_scope.lastRefreshMs = 0;                    // worker builds the table on its first sweep
    ResetEvent(g_smp.hStop);
    if (g_smp.hTimer) {
        LARGE_INTEGER due;
        due.QuadPart = -1;                       // first fire in 100 ns
        if (!SetWaitableTimer(g_smp.hTimer, &due, g_smp.intervalMs,
                              nullptr, nullptr, FALSE)) {
            DWORD e = GetLastError();
            L("[sampler] SetWaitableTimer failed (%lu); Sleep pacing", e);
            CloseHandle(g_smp.hTimer);
            g_smp.hTimer = nullptr;
        }
    }
    g_smp.hWorker = CreateThread(nullptr, 0, samp_worker, nullptr, 0, nullptr);
    if (!g_smp.hWorker || !g_smp.hStop) {
        samp_teardown();
        InterlockedExchange(&g_smp.running, 0);
        return "sampler thread create failed";
    }
    _snprintf_s(out, cap, _TRUNCATE, "ok tid=%lu interval_ms=%lu stacks=%d all=%d pdata=%d",
                (unsigned long)target_tid, (unsigned long)interval_ms,
                stacks, all, g_pdataN);
    L("[sampler] start tid=%lu interval=%lums stacks=%d all=%d pdata=%d",
      (unsigned long)target_tid, (unsigned long)interval_ms, stacks, all, g_pdataN);
    return nullptr;
}

// 1 = stopped something, 0 = nothing was running
int samp_api_stop(char *out, size_t cap)
{
    int was = InterlockedExchange(&g_smp.running, 0);
    if (!was && !g_smp.hWorker && !g_smp.hThread)
        return 0;
    samp_teardown();
    samp_counters_str(out, cap, "stopped:");
    L("[sampler] %s", out);
    return 1;
}

int samp_api_top(int n, char *out, size_t cap)
{
    if (n < 1) n = 1;
    if (n > SAMP_TOP_MAX) n = SAMP_TOP_MAX;
    if (!g_smp.tab) return 0;

    static SampSlot snap[SAMP_TABLE_SIZE];       // static: main-thread only
    int used = 0;
    unsigned long long total = 0;
    EnterCriticalSection(&g_smp.cs);
    for (uint32_t i = 0; i < SAMP_TABLE_SIZE; i++) {
        if (!g_smp.tab[i].key) continue;
        snap[used++] = g_smp.tab[i];
        total += g_smp.tab[i].count;
    }
    LeaveCriticalSection(&g_smp.cs);

    qsort(snap, (size_t)used, sizeof(SampSlot), samp_slot_cmp_count);
    if (n > used) n = used;

    size_t pos = (size_t)_snprintf_s(out, cap, _TRUNCATE,
        "total=%llu functions=%lld", total, (long long)used);
    for (int i = 0; i < n && pos < cap - 40; i++) {
        uint64_t key = snap[i].key;
        int w = (key & 1)
            ? _snprintf_s(out + pos, cap - pos, _TRUNCATE,
                          "\n%llu rip %llx", snap[i].count,
                          (unsigned long long)(key & ~(uint64_t)1))
            : _snprintf_s(out + pos, cap - pos, _TRUNCATE,
                          "\n%llu rva %llx", snap[i].count,
                          (unsigned long long)key);
        if (w < 0) break;
        pos += (size_t)w;
    }
    return 1;
}

// Folded-stack dump ("root;...;leaf count" per line, count-descending).
// Transport is a file because a real capture is megabytes.
int samp_api_folded(const char *argPath, char *out, size_t cap)
{
    char path[1024];
    if (argPath && *argPath) {
        _snprintf_s(path, sizeof(path), _TRUNCATE, "%s", argPath);
    } else {
        // user dir root, NOT logs/ — the engine wipes logs/ on every launch
        // and a folded capture must survive the next restart for offline work.
        const char *user = user_data_dir_utf8();
        if (!user || !*user) return 0;
        _snprintf_s(path, sizeof(path), _TRUNCATE, "%s\\profile_folded.txt", user);
    }

    std::vector<std::pair<std::string, uint64_t>> rows;
    EnterCriticalSection(&g_smp.cs);
    rows.assign(g_folded.begin(), g_folded.end());
    unsigned long long total = g_smp.total, stacks = g_foldedTotal;
    LeaveCriticalSection(&g_smp.cs);
    if (rows.empty()) return 0;
    std::sort(rows.begin(), rows.end(),
              [](const auto &a, const auto &b) { return a.second > b.second; });

    wchar_t wpath[1024];
    if (MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, 1024) <= 0)
        return 0;
    FILE *f = nullptr;
    if (_wfopen_s(&f, wpath, L"wb") != 0 || !f)
        return 0;
    fprintf(f, "# samples=%llu stacks=%llu stacks_unique=%llu base=%llx\n",
            total, stacks, (unsigned long long)rows.size(),
            (unsigned long long)g_imgLo);
    for (const auto &r : rows)
        fprintf(f, "%s %llu\n", r.first.c_str(), (unsigned long long)r.second);
    fclose(f);
    L("[sampler] folded written: %s (%llu stacks, %llu unique)",
      path, stacks, (unsigned long long)rows.size());
    _snprintf_s(out, cap, _TRUNCATE, "written %s stacks=%llu unique=%llu",
                path, stacks, (unsigned long long)rows.size());
    return 1;
}

void samp_api_status(char *out, size_t cap)
{
    samp_counters_str(out, cap,
                      InterlockedCompareExchange(&g_smp.running, 0, 0)
                          ? "running:" : "idle:");
    size_t l = strlen(out);
    _snprintf_s(out + l, cap - l, _TRUNCATE, " scope=%s tids=%d",
                g_scope.all ? "all" : "main", g_scope.count);
}

// Per-thread table (scope "all"): lines "tid hits hits% cpu_ms(last window)".
// Reader path: snapshot under CS (worker bumps tid counters under the same CS),
// then fresh GetThreadTimes for a live cpu column when sampling is stopped.
int samp_api_threads(char *out, size_t cap)
{
    SampTid snap[SAMP_TID_MAX];
    int n = 0;
    EnterCriticalSection(&g_smp.cs);
    n = g_scope.count < SAMP_TID_MAX ? g_scope.count : SAMP_TID_MAX;
    memcpy(snap, g_scope.tids, (size_t)n * sizeof(SampTid));
    unsigned long long total = g_smp.total;
    int all = g_scope.all;
    LeaveCriticalSection(&g_smp.cs);

    // hottest threads first: cpu-delta more diagnostic than hits (in a full
    // sweep every live tid accumulates exactly one hit per sweep — hits only
    // says "alive", cpu says "working")
    std::sort(snap, snap + n,
              [](const SampTid &a, const SampTid &b) {
                  return a.cpuDelta != b.cpuDelta ? a.cpuDelta > b.cpuDelta
                                                  : a.hits > b.hits;
              });

    size_t pos = (size_t)_snprintf_s(out, cap, _TRUNCATE,
        "scope=%s threads=%d total_samples=%llu\n%6s %8s %6s %10s",
        all ? "all" : "main", n, total, "tid", "hits", "hits%", "cpu_ms~");
    for (int i = 0; i < n && pos < cap - 48; i++) {
        SampTid *t = &snap[i];
        if (!t->hits && !t->cpuDelta) continue;            // silence is data too
        int w = _snprintf_s(out + pos, cap - pos, _TRUNCATE, "\n%6lu %8llu %6.2f %10.1f",
            (unsigned long)t->tid, t->hits,
            total ? 100.0 * (double)t->hits / (double)total : 0.0,
            (double)t->cpuDelta / 10000.0);
        if (w < 0) break;
        pos += (size_t)w;
    }
    return 1;
}

// ---- Lua surface ----
int hoi4_profile_start(lua_State *Ls)
{
    lua_Number ms = luaL_optnumber(Ls, 1, 1.0);
    if (ms < (lua_Number)SAMP_INTERVAL_MIN_MS || ms > (lua_Number)SAMP_INTERVAL_MAX_MS)
        luaL_argerror(Ls, 1, "interval_ms out of range (1..1000)");
    int stacks = lua_toboolean(Ls, 2);
    int all    = lua_toboolean(Ls, 3);
    // Target = whoever called us. /lua and console `lua` both run at frame
    // top on the game's main thread; async workers never see the hoi4 table.
    char out[112];
    const char *err = samp_api_start((unsigned)ms, stacks, GetCurrentThreadId(),
                                     all, out, sizeof(out));
    if (err) return luaL_error(Ls, "%s", err);
    lua_pushstring(Ls, out);
    return 1;
}

int hoi4_profile_stop(lua_State *Ls)
{
    char out[200];
    if (!samp_api_stop(out, sizeof(out)))
        return luaL_error(Ls, "profile not running");
    lua_pushstring(Ls, out);
    return 1;
}

// Lines: "<count> <kind> <hex>" — kind "rva" keys a hoi4.exe function start
// (annotate offline), "rip" is a raw sample address outside .pdata coverage.
int hoi4_profile_top(lua_State *Ls)
{
    lua_Integer n = luaL_optinteger(Ls, 1, 30);
    static char out[SAMP_TOP_MAX * 32 + 128];
    if (!samp_api_top((int)n, out, sizeof(out)))
        return luaL_error(Ls, "profile never started");
    lua_pushstring(Ls, out);
    return 1;
}

int hoi4_profile_folded(lua_State *Ls)
{
    const char *argPath = luaL_optstring(Ls, 1, nullptr);
    char out[1200];
    if (!samp_api_folded(argPath, out, sizeof(out)))
        return luaL_error(Ls, "no stack data (start with stacks=true) or write failed");
    lua_pushstring(Ls, out);
    return 1;
}

int hoi4_profile_status(lua_State *Ls)
{
    char out[200];
    samp_api_status(out, sizeof(out));
    lua_pushstring(Ls, out);
    return 1;
}

int hoi4_profile_threads(lua_State *Ls)
{
    static char out[64 * 1024];                // main-thread readers only
    samp_api_threads(out, sizeof(out));
    lua_pushstring(Ls, out);
    return 1;
}
