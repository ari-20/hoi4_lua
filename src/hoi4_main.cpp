// hoi4_main.cpp — DLL entry: Lua runtime bootstrap and shared module state
// Build: build_m4b.cmd (vcvars64 + lua54_static.lib)
//
// Chain: mod text "m4_debug_hello = yes" -> router hook -> name snapshot hit ->
//   engine factory instance -> engine parse (original vtable path) -> bind to
//   Lua fn -> push into effect list. Execution: engine calls a vtable slot on
//   the instance; our patched slot thunk sees the bind and calls Lua.
//
// REJECTED experiments (do not retry):
//   - vtable POINTER swap on the instance: crashes even with identical
//     contents + RTTI COL preserved (engine binds to vtable identity).
//   - Lua init inside DllMain (APC/loader lock): crashes. Init on worker.
//
// Engine facts (1.19.3 c01a3d50, image base 0x140000000): every image
// address lives in the compiled-in kOffValues table (hoi4_offsets.h — the
// single source of truth, fully relocated for 1.19.3). The functions it
// names: effect/trigger routers (hooked), SGF/GFT factories, engine
// allocator, vec push_back, FindCommandByName (hooked, command register).

#define WIN32_LEAN_AND_MEAN
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0600
#endif
#include <winsock2.h>          // MUST precede windows.h (IPC uses winsock; winsock1
#include <ws2tcpip.h>          //  shadowing would hide sockaddr_in/inet_pton)
#include <windows.h>
#include <shlobj.h>
#include <objbase.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")

#include "third-party/lua54/lua-5.4.7/src/lua.hpp"

// ============================================================
// Refactored 2026-08-26: module implementations moved to src/*.c
// (paths/bridge/primitives/registry/vtable/console/hooks/timer/async/frame).
// This file keeps: shared global definitions, the registry name snapshot,
// hot-reload core, lua_init_thread, and DllMain wiring.
//
// 2026-08-27 LUA_SCRIPT is GONE: ALL Lua loads from the mod directory
// via load_mod_lua_scripts()  No path is hardcoded
// anywhere. Hot reload = mtime of every mod lua/ file (watch entries
// are registered by the loader itself, see hoi4_paths.cpp).
// ============================================================
#include "hoi4_common.h"
#include "hoi4_hook.h"

// ---- shared global definitions (declared in hoi4_common.h) ----
HANDLE g_log = INVALID_HANDLE_VALUE;
uint8_t *g_base;
struct lua_State *g_L;
void *g_mgr;
SRWLOCK g_luaLock = SRWLOCK_INIT;
DWORD g_luaOwner;
unsigned g_luaDepth;
volatile LONG g_initialized;        // P5: set once lua_init_thread finished

// ---- logging with deferred file open ----
// DllMain must not touch the user-documents path chain (SHGetKnownFolderPath
// etc. load shell DLLs = loader-lock hazard), so early entries go to a
// memory buffer. lua_init_thread calls log_open_in_logs_dir() right after
// resolve_game_data_path(); it opens <user_data>/logs/hoi4_bridge.log and
// flushes the buffer into it. Until then L() keeps buffering.
#define LOG_RING_BYTES   (256 * 1024)
#define LOG_RING_MAX     512
static char  g_logRing[LOG_RING_MAX][256];
static int   g_logRingLen[LOG_RING_MAX];
static int   g_logRingCount;
static CRITICAL_SECTION g_logRingLock;
static INIT_ONCE g_logRingOnce = INIT_ONCE_STATIC_INIT;

static BOOL CALLBACK log_ring_lock_init(PINIT_ONCE io, PVOID arg, PVOID *ctx) {
    (void)io; (void)arg; (void)ctx;
    InitializeCriticalSection(&g_logRingLock);
    return TRUE;
}

static void log_ring_push(const char *line, int len) {
    InitOnceExecuteOnce(&g_logRingOnce, log_ring_lock_init, NULL, NULL);
    EnterCriticalSection(&g_logRingLock);
    if (g_logRingCount < LOG_RING_MAX) {
        int n = len < 255 ? len : 255;
        memcpy(g_logRing[g_logRingCount], line, (size_t)n);
        g_logRing[g_logRingCount][n] = 0;
        g_logRingLen[g_logRingCount] = n;
        g_logRingCount++;
    }
    LeaveCriticalSection(&g_logRingLock);
}

// flush buffered (DllMain-era) entries into an opened handle, then adopt it
// as g_log. Called by log_open_in_logs_dir (hoi4_paths.cpp) on the init thread.
void log_ring_flush_and_adopt(HANDLE h) {
    if (!h || h == INVALID_HANDLE_VALUE) return;
    if (InterlockedCompareExchangePointer((PVOID volatile *)&g_log,
                                          (PVOID)h, (PVOID)INVALID_HANDLE_VALUE)
        != (PVOID)INVALID_HANDLE_VALUE) {
        CloseHandle(h);            // someone already opened it
        return;
    }
    InitOnceExecuteOnce(&g_logRingOnce, log_ring_lock_init, NULL, NULL);
    EnterCriticalSection(&g_logRingLock);
    for (int i = 0; i < g_logRingCount; i++) {
        DWORD w;
        WriteFile(h, g_logRing[i], (DWORD)g_logRingLen[i], &w, NULL);
        WriteFile(h, "\n", 1, &w, NULL);
    }
    g_logRingCount = 0;
    LeaveCriticalSection(&g_logRingLock);
}

// open the real log under <user_data>/logs/ and flush buffered entries.
// Defined in hoi4_paths.cpp (owns wpath_join/g_logsDir); declared in common.h.
void log_open_in_logs_dir(void);

// L()'s private serialization lock (file scope so the INIT_ONCE callback can
// reach it; C has no nested functions).
static CRITICAL_SECTION g_logBufLock;
static INIT_ONCE g_logBufOnce = INIT_ONCE_STATIC_INIT;
static BOOL CALLBACK log_buf_lock_init(PINIT_ONCE io, PVOID arg, PVOID *ctx) {
    (void)io; (void)arg; (void)ctx;
    InitializeCriticalSection(&g_logBufLock);
    return TRUE;
}

// ---------------------------------------------------------------- log policy
// Line shape: [MM-DD HH:MM:SS.mmm] [src.cpp:LINE] message — same month/day +
// source-location shape as the audit log (2026-09-27: one format across both
// files, year omitted). L(...) is a macro over L_at(__FILE__, __LINE__, ...)
// so every line carries its emitting C location.
//
// Flush policy: the old shape wrote AND FlushFileBuffers'd every single line;
// a trigger-eval log storm measured 49% of main-thread samples inside that
// ntdll path (2026-09-27 profile). Lines now append to a buffer that is
// drained when full and flushed on an interval: g_logFlushMs — default 2000,
// 0 = write + flush per line (the old behavior, for crash forensics).
// Override at startup with env HOI4_LOG_FLUSH_MS, at runtime with
// hoi4.log_flush(ms). In interval mode a hard kill loses at most one interval.
static char g_logBuf[8192];
static size_t g_logBufLen;
static ULONGLONG g_logLastFlushMs;
static volatile LONG g_logFlushMs = -1;   // -1 unresolved, else 0..60000 ms

static void log_drain_locked(void) {
    if (g_logBufLen) {
        DWORD w;
        WriteFile(g_log, g_logBuf, (DWORD)g_logBufLen, &w, NULL);
        g_logBufLen = 0;
    }
}

static void log_flush_locked(void) {
    if (g_log == INVALID_HANDLE_VALUE) return;
    log_drain_locked();
    FlushFileBuffers(g_log);
    g_logLastFlushMs = GetTickCount64();
}

static int log_flush_ms(void) {
    LONG v = g_logFlushMs;
    if (v >= 0) return (int)v;
    LONG nv = 2000;
    char e[16];
    DWORD n = GetEnvironmentVariableA("HOI4_LOG_FLUSH_MS", e, sizeof(e));
    if (n > 0 && n < sizeof(e)) {
        long ms = strtol(e, NULL, 10);
        if (ms < 0) ms = 0;
        if (ms > 60000) ms = 60000;
        nv = (LONG)ms;
    }
    InterlockedCompareExchange(&g_logFlushMs, nv, -1);
    return (int)g_logFlushMs;
}

// teardown flush (DllMain DLL_PROCESS_DETACH): interval mode can hold up to
// one interval worth of lines in the buffer.
void log_flush_now(void) {
    InitOnceExecuteOnce(&g_logBufOnce, log_buf_lock_init, NULL, NULL);
    EnterCriticalSection(&g_logBufLock);
    log_flush_locked();
    LeaveCriticalSection(&g_logBufLock);
}

// Non-blocking twin for the loader-lock / process-exit path: a thread that
// died holding the log lock must not hang teardown, so a busy lock means
// "skip" (the buffer is lost, the process was killed mid-write anyway).
int log_flush_try(void) {
    InitOnceExecuteOnce(&g_logBufOnce, log_buf_lock_init, NULL, NULL);
    if (!TryEnterCriticalSection(&g_logBufLock)) return 0;
    log_flush_locked();
    LeaveCriticalSection(&g_logBufLock);
    return 1;
}

// Frame-boundary tick: interval mode flushes from the frame hooks (in-game and
// front-end idlers) because L() can only check the clock when a line arrives —
// without this, a quiet tail could sit in the buffer indefinitely instead of
// the promised <=1 interval (found live 2026-09-27: a denial burst's line was
// still buffered seconds later).
void log_flush_tick(void) {
    if (!g_logBufLen) return;                  // unlocked peek: nothing buffered
    int ms = log_flush_ms();
    if (ms <= 0) return;
    if (GetTickCount64() - g_logLastFlushMs < (ULONGLONG)ms) return;
    log_flush_now();
}

// hoi4.log_flush([ms]) -> current interval ms; 0 = write + flush every line.
// Setting also drains immediately so a crash right after loses nothing.
int hoi4_log_flush(lua_State *Ls) {
    if (lua_gettop(Ls) >= 1) {
        lua_Integer ms = luaL_checkinteger(Ls, 1);
        if (ms < 0) ms = 0;
        if (ms > 60000) ms = 60000;
        InterlockedExchange(&g_logFlushMs, (LONG)ms);
        log_flush_now();
    }
    lua_pushinteger(Ls, log_flush_ms());
    return 1;
}

void L_at(const char *file, int line, const char *fmt, ...) {
    // STACK-SAFETY (2026-08-27 fastfail forensics): this function can run at
    // the bottom of a deep recursion (IPC frame -> console -> event -> effect
    // -> Lua -> effect depth 2 -> L) where the 1KB stack Buffer + CRT frames
    // tipped the 1MB stack over (FAST_FAIL_STACK_COOKIE inside vsnprintf->
    // strstr). The buffer is now static, serialized by the ring's critical
    // section (worst case: log lines interleave across threads; never crash).
    static char buf[1024];
    InitOnceExecuteOnce(&g_logBufOnce, log_buf_lock_init, NULL, NULL);
    EnterCriticalSection(&g_logBufLock);
    const char *base = file ? file : "?";
    if (file) {
        const char *s1 = strrchr(file, '\\');
        const char *s2 = strrchr(file, '/');
        const char *s = (s1 > s2) ? s1 : s2;      // NULL-safe: both NULL -> NULL
        if (s) base = s + 1;
    }
    SYSTEMTIME st; GetLocalTime(&st);
    int pre = snprintf(buf, sizeof(buf)-1, "[%02d-%02d %02d:%02d:%02d.%03d] [%s:%d] ",
                       st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond,
                       st.wMilliseconds, base, line);
    if (pre < 0) pre = 0;
    if (pre > (int)sizeof(buf) - 2) pre = (int)sizeof(buf) - 2;
    va_list ap; va_start(ap, fmt);
    int n = vsnprintf(buf + pre, sizeof(buf)-1-pre, fmt, ap);
    va_end(ap);
    // vsnprintf returns the WOULD-BE length on truncation — clamp to what
    // actually fits or buf[pre+n]/WriteFile(pre+n+1) walk out of bounds.
    if (n > 0) {
        size_t avail = sizeof(buf) - 1 - (size_t)pre;
        size_t len = (size_t)n < avail ? (size_t)n : avail;
        if (g_log == INVALID_HANDLE_VALUE) {
            log_ring_push(buf, pre + (int)len);
        } else {
            buf[pre + len] = '\n';
            size_t total = (size_t)pre + len + 1;
            int ms = log_flush_ms();
            if (ms == 0) {
                DWORD w;
                WriteFile(g_log, buf, (DWORD)total, &w, NULL);
                FlushFileBuffers(g_log);
                g_logLastFlushMs = GetTickCount64();
            } else {
                if (total > sizeof(g_logBuf) - g_logBufLen) log_drain_locked();
                memcpy(g_logBuf + g_logBufLen, buf, total);
                g_logBufLen += total;
                if (GetTickCount64() - g_logLastFlushMs >= (ULONGLONG)ms)
                    log_flush_locked();
            }
        }
    }
    LeaveCriticalSection(&g_logBufLock);
}

// ---------------------------------------------------------------- log throttle
// log_throttle(key, interval_ms, *suppressed): 1 = emit now, 0 = suppress.
// Gate denials can fire at frame rate when a script targets a refused address
// (2026-09-27: 159k log lines + 225k audit rows from one bad out-param write);
// the audit keeps the full record, the text log keeps a rate-limited trace.
// `key` is a stable pointer (call-site string literal); slots never recycle.
#define LOG_THROTTLE_SLOTS 24
static struct {
    const void *key;
    ULONGLONG last;
    unsigned long suppressed;
} g_thr[LOG_THROTTLE_SLOTS];
static int g_thrCount;
static CRITICAL_SECTION g_thrLock;
static INIT_ONCE g_thrOnce = INIT_ONCE_STATIC_INIT;
static BOOL CALLBACK log_thr_lock_init(PINIT_ONCE io, PVOID arg, PVOID *ctx) {
    (void)io; (void)arg; (void)ctx;
    InitializeCriticalSection(&g_thrLock);
    return TRUE;
}

int log_throttle(const void *key, unsigned interval_ms, unsigned long *suppressed) {
    if (suppressed) *suppressed = 0;
    InitOnceExecuteOnce(&g_thrOnce, log_thr_lock_init, NULL, NULL);
    EnterCriticalSection(&g_thrLock);
    ULONGLONG now = GetTickCount64();
    int slot = -1;
    for (int i = 0; i < g_thrCount; i++) {
        if (g_thr[i].key == key) { slot = i; break; }
    }
    if (slot < 0 && g_thrCount < LOG_THROTTLE_SLOTS) {
        slot = g_thrCount++;
        g_thr[slot].key = key;
        g_thr[slot].last = 0;
        g_thr[slot].suppressed = 0;
    }
    int emit = 1;
    if (slot >= 0) {
        if (g_thr[slot].last && now - g_thr[slot].last < interval_ms) {
            g_thr[slot].suppressed++;
            emit = 0;
        } else {
            if (suppressed) *suppressed = g_thr[slot].suppressed;
            g_thr[slot].suppressed = 0;
            g_thr[slot].last = now;
        }
    }
    LeaveCriticalSection(&g_thrLock);
    return emit;
}

// ---------------------------------------------------------------- log gates
// Two opt-in gates, each resolved once on first query and then cached; a
// running session keeps the flags it started with.
//
//   debug   (-debug token / HOI4_DLL_DEBUG=1): per-call vtable traces
//           ([effect] slotN on bound — they fire on every desc/validity
//           repaint, not just real executions: hundreds of lines per day on
//           tooltip-heavy effects).
//   verbose (-verbose token / HOI4_DLL_VERBOSE=1): the per-repaint traces that
//           fire far past debug rates — [trigger] eval runs at frame rate
//           (measured 209-310 lines/s, 241k lines in one 2026-09-27 session).
//           Strictly separate: -debug alone does NOT enable these.
//
// cmdline token channels: the launcher passes single-dash args through to
// hoi4.exe; env channels are inherited from the launcher.
static volatile LONG g_debugMode = -1;   // -1 unresolved, 0 off, 1 on
static volatile LONG g_verboseMode = -1;

// case-insensitive `-<tok>` / `/<tok>` scan: left edge = string start or
// blank, right edge = end / blank / '=' (so -debug_xyz does not match).
static int cmdline_has_token(const wchar_t *tok) {
    const wchar_t *c = GetCommandLineW();
    if (!c) return 0;
    size_t tl = wcslen(tok);
    for (const wchar_t *p = c; *p; p++) {
        if (*p != L'-' && *p != L'/') continue;
        if (p != c && p[-1] != L' ' && p[-1] != L'\t') continue;  // need left edge
        size_t i = 0;
        for (; i < tl; i++) {
            wchar_t a = p[1 + i], b = tok[i];
            if (a >= L'A' && a <= L'Z') a = (wchar_t)(a + 32);
            if (b >= L'A' && b <= L'Z') b = (wchar_t)(b + 32);
            if (a != b) break;
        }
        if (i != tl) continue;
        wchar_t nx = p[1 + tl];
        if (nx == 0 || nx == L' ' || nx == L'\t' || nx == L'=') return 1;
    }
    return 0;
}

static int env_flag_enabled(const char *name) {
    char v[8];
    DWORD n = GetEnvironmentVariableA(name, v, sizeof(v));
    return n > 0 && (v[0] == '1' || v[0] == 'y' || v[0] == 'Y');
}

int dll_debug_mode(void) {
    LONG v = g_debugMode;
    if (v >= 0) return (int)v;
    LONG nv = (cmdline_has_token(L"debug") || env_flag_enabled("HOI4_DLL_DEBUG")) ? 1 : 0;
    InterlockedCompareExchange(&g_debugMode, nv, -1);
    v = g_debugMode;
    if (v == 1) L("[init] debug mode on: verbose effect/vtable logs enabled");
    return (int)v;
}

int dll_verbose_mode(void) {
    LONG v = g_verboseMode;
    if (v >= 0) return (int)v;
    LONG nv = (cmdline_has_token(L"verbose") || env_flag_enabled("HOI4_DLL_VERBOSE")) ? 1 : 0;
    InterlockedCompareExchange(&g_verboseMode, nv, -1);
    v = g_verboseMode;
    if (v == 1) L("[init] verbose mode on: per-repaint traces (trigger eval) enabled");
    return (int)v;
}

// hoi4.debug() / hoi4.verbose() -> bool. Both live under the hoi4 table, so
// they coexist with Lua's global `debug` library.
int hoi4_debug(lua_State *Ls) {
    lua_pushboolean(Ls, dll_debug_mode());
    return 1;
}

int hoi4_verbose(lua_State *Ls) {
    lua_pushboolean(Ls, dll_verbose_mode());
    return 1;
}

// -+ dual-table name snapshot
// Replaces the old "every global function is routable" scan. Names come from
// the explicit registry tables filled by hoi4.effect/hoi4.trigger at script
// load time; effect and trigger routers each search only their own table.
#define MAX_NAMES 512
static char g_fx[MAX_NAMES][64];   // routable as EFFECT
static volatile long g_fxCount;
static char g_tr[MAX_NAMES][64];   // routable as TRIGGER
static volatile long g_trCount;
static volatile long g_reloadCount;

static int cmp_names(const void *a, const void *b) {
    return strcmp((const char *)a, (const char *)b);
}

// snapshot one registry kind into dst (sorted); returns the count. Must hold
// g_luaLock — reads live Lua tables.
static int snapshot_kind_locked(lua_State *Ls, const char *kind, char (*dst)[64]) {
    int n = 0;
    lua_getfield(Ls, LUA_REGISTRYINDEX, "m4_registry");
    if (lua_istable(Ls, -1)) {
        lua_getfield(Ls, -1, kind);
        if (lua_istable(Ls, -1)) {
            lua_pushnil(Ls);
            while (lua_next(Ls, -2) != 0) {
                // key must be a string; value was validated at registration
                const char *k = lua_tostring(Ls, -2);
                if (k && *k && n < MAX_NAMES) {
                    strncpy(dst[n], k, 63);
                    dst[n][63] = 0;
                    n++;
                }
                lua_pop(Ls, 1);          // pop value, keep key for lua_next
            }
        }
        lua_pop(Ls, 1);                  // kind table
    }
    lua_pop(Ls, 1);                      // m4_registry
    qsort(dst, (size_t)n, 64, cmp_names);
    if (n >= MAX_NAMES)
        L("[registry] name snapshot hit the %d cap: %s entries beyond it are NOT routable",
          MAX_NAMES, kind);
    return n;
}

void snapshot_names_locked(void) {
    int fx = snapshot_kind_locked(g_L, REG_TABLE_EFFECT, g_fx);
    int tr = snapshot_kind_locked(g_L, REG_TABLE_TRIGGER, g_tr);
    InterlockedExchange(&g_fxCount, fx);
    InterlockedExchange(&g_trCount, tr);
}

// C-side registry reset: runs before every dofile so hot reload rebuilds the
// registry from scratch (stale registrations from the previous generation die
// here; a script that fails to reload leaves NO routable names behind).
void registry_clear(lua_State *Ls) {
    lua_pushnil(Ls);
    lua_setfield(Ls, LUA_REGISTRYINDEX, "m4_registry");
    // Hook callbacks are resolved BY ID from their own table on every call
    // (exactly like the bind table), so clearing it here means a reloaded
    // script's NEW closure is what the still-patched slot reaches. The patch
    // itself is untouched: hooks are process-level and survive a reload.
    hooks_registry_clear(Ls);
}

// runtime-registered watch list. Scripts call hoi4.watch(path) at load
// time (during dofile) to add dependencies; maybe_reload_locked then treats a
// change in ANY watched file as a script change. The list is rebuilt on every
// dofile: watch() is cleared first, and the script re-registers what it
// dofile()s. All accesses happen under g_luaLock, so no extra sync needed.
static int get_file_mtime(const char *path, FILETIME *ft);
static int watch_add_locked(const char *path);
#define MAX_WATCH 256   // 2026-08-27: 32 -> 256. Multi-mod setups register EVERY
                        // lua file they load; two 20-file mods already
                        // overflowed the old cap silently.
typedef struct { char path[MAX_PATH]; FILETIME mtime; int valid; } WatchEntry;
static WatchEntry g_watch[MAX_WATCH];
static int g_watchCount;

// C-side entry (no Lua stack): the lua loader watch-registers each file
// it dofiles. Declared in hoi4_common.h as watch_add_file().
int watch_add_file(const char *path) { return watch_add_locked(path); }

static void watch_clear_locked(void) { g_watchCount = 0; }

static void watch_rescan_locked(void) {
    for (int i = 0; i < g_watchCount; i++)
        g_watch[i].valid = get_file_mtime(g_watch[i].path, &g_watch[i].mtime);
}

static int watch_add_locked(const char *path) {
    if (g_watchCount >= MAX_WATCH) return 0;
    WatchEntry *w = &g_watch[g_watchCount];
    strncpy(w->path, path, MAX_PATH - 1);
    w->path[MAX_PATH - 1] = 0;
    w->valid = get_file_mtime(w->path, &w->mtime);
    g_watchCount++;
    return 1;
}

// has any watched file changed since it was registered?
// A4/F2: existence is part of the watched state — a file DELETED since
// register time is a change (triggers reload), and a watched-but-missing
// file that APPEARED is a change too. Previously deletions never triggered.
static int watch_changed_locked(void) {
    for (int i = 0; i < g_watchCount; i++) {
        FILETIME now;
        if (!g_watch[i].valid) {
            // was missing at register time: did it appear since?
            if (get_file_mtime(g_watch[i].path, &now)) {
                g_watch[i].mtime = now;
                g_watch[i].valid = 1;
                return 1;
            }
            continue;
        }
        if (!get_file_mtime(g_watch[i].path, &now))
            return 1;                         // deleted since register
        if (now.dwLowDateTime != g_watch[i].mtime.dwLowDateTime ||
            now.dwHighDateTime != g_watch[i].mtime.dwHighDateTime)
            return 1;
    }
    return 0;
}

// hoi4.watch(path) — register a hot-reload dependency (call at script load time).
// Also called internally (non-Lua) by the lua loader so every mod lua file it
// dofiles becomes a reload trigger.
int hoi4_watch(lua_State *Ls) {
    const char *path = luaL_checkstring(Ls, 1);
    int ok = watch_add_locked(path);
    if (ok) L("[reload] watching %s", path);
    else L("[reload] watch list full, ignoring %s", path);
    lua_pushboolean(Ls, ok);
    return 1;
}

// snapshot_names_locked moved above the watch section — it now reads the
// explicit hoi4.effect/hoi4.trigger registry tables instead of scanning _G.

static int get_file_mtime(const char *path, FILETIME *ft) {
    WIN32_FILE_ATTRIBUTE_DATA fad;
    if (!GetFileAttributesExA(path, GetFileExInfoStandard, &fad)) return 0;
    *ft = fad.ftLastWriteTime;
    return 1;
}

// Hot-reload execution is DEFERRED to the frame heartbeat (2026-08-27).
// Depth-sensitive call sites (lua_call_effect / lua_call_trigger, which can
// sit at the bottom of IPC->console->event->effect->Lua->effect recursion)
// only run the cheap mtime check and set the pending flag. The heavy work
// (registry clear + full re-dofile, ~all of load_mod_lua_scripts) runs in
// frame_dispatch at the TOP of the frame, on a shallow stack — this
// removes the last big stack consumer from nested callback paths.
static volatile LONG g_reloadPending;
// Set for the duration of reload execution so load-time script code
// that touches watched files (or fires effects) cannot queue a second
// immediate reload of the generation currently being built.
static volatile LONG g_reloading;

// ---- script-load phase flags (Tier 2 detour install window) ----
// load_mod_lua_scripts runs in TWO situations: the process's first load
// (lua_init_thread, before the engine's render loop exists) and every later
// reload (frame-top hot reload, and session switches). Only the FIRST one is
// quiet enough to rewrite engine code bytes safely — the others run with the
// game live, AI ticking and workers busy. hoi4.detour therefore accepts a
// target only while in_first_script_load() is true; see DETOUR_DESIGN.md §4.1.
static volatile LONG g_scriptLoadDepth;   // >0 while a load is executing
static volatile LONG g_scriptLoadDone;    // completed load rounds

int in_first_script_load(void) {
    return g_scriptLoadDepth > 0 && g_scriptLoadDone == 0;
}

static int run_script_load(lua_State *Ls) {
    InterlockedIncrement(&g_scriptLoadDepth);
    int n = load_mod_lua_scripts(Ls);
    InterlockedDecrement(&g_scriptLoadDepth);
    InterlockedIncrement(&g_scriptLoadDone);
    return n;
}

void maybe_reload_locked(void) {
    // detection only — called from deep callback stacks
    if (g_reloading) return;             // A5: reload already in progress
    if (g_reloadPending) return;
    if (watch_changed_locked())
        InterlockedExchange(&g_reloadPending, 1);
}

// B: force a full reload cycle regardless of pending detection. Used by the
// session-switch path (old script state must not survive a session change).
// Caller must hold g_luaLock (frame-top context).
void force_reload_locked(void) {
    InterlockedExchange(&g_reloadPending, 1);
    reload_execute_locked();
}

// execute a pending reload. Called from the frame heartbeat (shallow stack,
// g_luaLock held). Also safe to call directly at init.
// Static-capacity occupancy: every fixed table silently drops on overflow
// (by design, with one log line at the drop site). This periodic line makes
// the headroom VISIBLE from the log alone — a long AI-hosted campaign should
// show these numbers well below the caps, and a march toward a cap is the
// early signal of a leak (dead binds / stale watches) before it bites.
void capacity_log_locked(void) {
    L("[capacity] names fx=%d/512 tr=%d/512 watch=%d/256 binds=%d/512 "
      "hooks=%d/64 hslots=%d/32 detours=%d/16",
      (int)g_fxCount, (int)g_trCount, g_watchCount, bind_count(),
      hook_count(), hook_slot_count(), hook_detour_count());
}

void reload_execute_locked(void) {
    if (!InterlockedExchange(&g_reloadPending, 0)) return;
    InterlockedIncrement(&g_reloadCount);
    L("[reload] mod lua changed, reloading (%ld)", g_reloadCount);
    g_reloading = 1;                    // A5: suppress nested detection
    watch_clear_locked();               // the re-dofile rebuilds the watch list
    registry_clear(g_L);                // stale registrations die here
    timers_clear_locked();          // timers follow the same reset semantics
    {
        int n = run_script_load(g_L);
        L("[lua] mod lua scripts reloaded: %d", n);
    }
    snapshot_names_locked();
    g_reloading = 0;
    L("[reload] reload done, fx=%d tr=%d names, watching %d deps",
      (int)g_fxCount, (int)g_trCount, g_watchCount);
    capacity_log_locked();
}
// (footer fix: count printed as int, g_watchCount is int)

// ---- hoi4_lib assembly table (aggregates all modules' Lua exports) ----
static const luaL_Reg hoi4_lib[] = {
    {"log", hoi4_log},
    {"debug", hoi4_debug},
    {"verbose", hoi4_verbose},
    {"log_flush", hoi4_log_flush},
    {"base", hoi4_base},
    {"to_number", hoi4_to_number},
    {"read_u64", hoi4_read_u64},
    {"read_u32", hoi4_read_u32},
    {"read_u16", hoi4_read_u16},
    {"read_u8", hoi4_read_u8},
    {"read_f32", hoi4_read_f32},
    {"read_f64", hoi4_read_f64},
    {"read_cstr", hoi4_read_cstr},
    {"read_str", hoi4_read_str},
    {"read_bytes", hoi4_read_bytes},
    {"write_u8", hoi4_write_u8},
    {"write_u16", hoi4_write_u16},
    {"write_u32", hoi4_write_u32},
    {"write_u64", hoi4_write_u64},
    {"write_f32", hoi4_write_f32},
    {"write_f64", hoi4_write_f64},
    {"write_str", hoi4_write_str},
    {"game_dir", hoi4_game_dir},
    {"user_data_dir", hoi4_user_data_dir},
    {"logs_dir", hoi4_logs_dir},
    {"save_dir", hoi4_save_dir},
    {"read_dir", hoi4_read_dir},
    {"http_request", hoi4_http_request},
    {"mods_json", hoi4_mods_json},
    {"read_mod_descriptor", hoi4_read_mod_descriptor},
    {"watch", hoi4_watch},
    {"console", hoi4_console},
    {"console_argv", hoi4_console_argv},
    {"effect", hoi4_effect_reg},
    {"trigger", hoi4_trigger_reg},
    {"get_effect", hoi4_get_effect},
    {"get_trigger", hoi4_get_trigger},
    {"every", hoi4_every},
    {"after", hoi4_after},
    {"every_cancel", hoi4_every_cancel},
    {"timers_count", hoi4_timers_count},
    {"async_exec", hoi4_async_exec},
    {"async_cancel", hoi4_async_cancel},
    {"async_poll", hoi4_async_poll},
    {"async_status", hoi4_async_status},
    {"scope_country", hoi4_scope_country},       // D1: scope ctx accessors
    {"scope_state_id", hoi4_scope_state_id},
    {"eval_value", hoi4_eval_value},
    {"game_speed", hoi4_game_speed},             // H: game control
    {"game_set_speed", hoi4_game_set_speed},
    {"game_pause", hoi4_game_pause},
    {"session_pending", hoi4_session_pending},   // switch event raised, dispatch pending
    {"call_u64", hoi4_call_u64},                 // G: guarded engine call
    {"call_void", hoi4_call_void},
    {"engine_alloc", hoi4_engine_alloc},
    {"engine_free", hoi4_engine_free},
    {"name_to_token", hoi4_name_to_token},
    {"load_save", hoi4_load_save},
    {"define_lookup", hoi4_lua_define_lookup},   // defines via image scan
    {"define_targets", hoi4_lua_define_targets},
    {"defines_build", hoi4_lua_defines_build},
    {"defines_count", hoi4_lua_defines_count},
    {"dr_watch", hoi4_dr_watch},                 // DR0 write watch (in-process)
    {"dr_off", hoi4_dr_off},                     // disarm DR watch
    {"dr_hits", hoi4_dr_hits},                   // collected hit ring
    {"dr_state", hoi4_dr_state},                 // diag: read back thread DR regs
    {"dr_selfdr", hoi4_dr_selfdr},               // diag: CPU-real DR of calling thread
    {"dr_threadtest", hoi4_dr_threadtest},         // diag: fresh-thread DR end-to-end test
    {"dr_gwatch", hoi4_dr_gwatch},               // guard-page watch
    {"dr_goff", hoi4_dr_goff},                   // guard disarm
    {"dr_ghits", hoi4_dr_ghits},                 // guard hit aggregation
    {"dr_ring_addr", hoi4_dr_ring_addr},         // ring base for external polling
    {"profile_start", hoi4_profile_start},       // sampling profiler
    {"profile_stop", hoi4_profile_stop},
    {"profile_top", hoi4_profile_top},
    {"profile_folded", hoi4_profile_folded},
    {"profile_threads", hoi4_profile_threads},
    {"profile_status", hoi4_profile_status},
    // vtable-slot hook facility (hoi4_hook.cpp / hoi4_hook.h): intercept an
    // existing engine virtual method by replacing ONE data qword (vt[slot]).
    // Replaces/wraps/observes; never patches code bytes.
    {"hook_vt", hoi4_hook_vt},
    {"unhook_vt", hoi4_unhook_vt},
    {"hook_list", hoi4_hook_list},
    {"hook_status", hoi4_hook_status},
    // Tier 2 function-body detour (hoi4_hook.cpp / hoi4_detour.cpp). Permanent
    // by design: there is deliberately no unhook — writing engine code bytes
    // back races every other thread exactly like installing does. Install is
    // restricted to the process's FIRST script load; re-registering the same id
    // (to change the callback) works at any time with no restart.
    {"detour", hoi4_detour},
    {"detour_list", hoi4_detour_list},
    {"detour_status", hoi4_detour_status},
    {"detour_probe", hoi4_detour_probe},
    {NULL, NULL},
};

void lua_init_thread(void *unused) {
    (void)unused;
    if (!get_game_dir())
        L("[paths] failed to resolve game directory from module path");
    else if (!resolve_game_data_path())
        L("[paths] failed to resolve HOI4 user data directory");
    g_L = luaL_newstate();
    if (!g_L) { L("[lua] luaL_newstate failed"); return; }
    luaL_openlibs(g_L);
    // Security layers BEFORE any mod script runs (order is load-bearing: a mod
    // that executes first could capture an unwrapped reference to what these
    // replace). Reduction first, then the path policy that wraps dofile/io.
    lua_harden_libs(g_L);
    lua_policy_register_save_dir();
    lua_policy_install(g_L);
    audit_init_config();
    audit_open(logs_dir_utf8());
    audit_session_start(offsets_version(), "0.4");
    // register the hoi4 bridge BEFORE any script so load-time code can
    // call hoi4.log(...) etc.
    lua_newtable(g_L);
    luaL_setfuncs(g_L, hoi4_lib, 0);
    lua_setglobal(g_L, "hoi4");
    // 2026-08-27: the ONLY Lua entry point is the mod directory — every
    // enabled mod's lua/*.lua  The loader also watch-registers each
    // file it dofiles, so hot reload needs no separate main-script mtime.
    {
        int n = run_script_load(g_L);
        L("[lua] mod lua scripts loaded: %d", n);
    }
    snapshot_names_locked();
    L("[registry] registered: %d effects, %d triggers",
      (int)g_fxCount, (int)g_trCount);
    // B: session lifecycle watcher LAST — transitions are only meaningful
    // once every subsystem it cleans up (timers/async/binds/reload) is live.
    session_hooks_install();
    // F: local HTTP service (opt-in via -http[=port]); polls from frame top.
    http_maybe_autostart();
    // P5: everything up; late external entry points (http_enable APC, probes)
    // may now safely touch the VM.
    InterlockedExchange(&g_initialized, 1);
    L("[init] lua runtime ready");
}

// per-kind lookup over the sorted read-only snapshots. The effect router
// consults ONLY effect_known(); the trigger router ONLY trigger_known(). A
// name in the wrong table is invisible at that router -> falls through to
// native handling (vanilla "unknown effect/trigger" error = clean signal).
static int kind_known(const char (*tab)[64], const volatile long *cnt, const char *n) {
    int hi = (int)*cnt - 1;
    int lo = 0;
    while (lo <= hi) {
        int mid = (lo + hi) >> 1;
        int c = strcmp(tab[mid], n);
        if (c == 0) return 1;
        if (c < 0) lo = mid + 1; else hi = mid - 1;
    }
    return 0;
}
int effect_known(const char *n)  { return kind_known(g_fx, &g_fxCount, n); }
int trigger_known(const char *n) { return kind_known(g_tr, &g_trCount, n); }

// call Lua fn(name, self, ctx) — serialized. ctx = slot12's param_2 (the
// effect-context/scope object the engine hands to Execute).

// recursion-aware locking. A Lua effect can invoke native console
// commands (hoi4.console("event ...")) which synchronously fire an event whose
// triggers route BACK into Lua on the SAME thread while the outer call still
// holds g_luaLock. Acquiring an SRWLOCK exclusively twice on one thread is
// undefined behavior (observed: process dies inside the native handler with
// no fault record). Same-thread re-entry therefore bypasses the lock — the
// Lua state is single-threaded anyway; the lock only serializes threads.

void lua_lock(void) {
    DWORD tid = GetCurrentThreadId();
    if (g_luaOwner == tid && g_luaDepth > 0) {
        g_luaDepth++;
        L("[lua] recursive entry, depth=%u", g_luaDepth);
        return;
    }
    AcquireSRWLockExclusive(&g_luaLock);
    g_luaOwner = tid;
    g_luaDepth = 1;
}

void lua_unlock(void) {
    DWORD tid = GetCurrentThreadId();
    if (g_luaOwner != tid || g_luaDepth == 0) return;  // defensive
    if (--g_luaDepth > 0) return;
    g_luaOwner = 0;
    ReleaseSRWLockExclusive(&g_luaLock);
}

void lua_call_effect(const char *fn, void *self, uint64_t ctx) {
    if (!g_L) return;
    lua_lock();
    // (A1/F9) reload detection removed here: the frame heartbeat is the
    // structural parent of effect dispatch, so frame-top detection always
    // covers any point where an effect could run. The per-callback check
    // was a stat() storm on effect-heavy frames for zero coverage gain.
    reg_table(g_L, REG_TABLE_EFFECT);        // fn lives in the registry
    lua_pushstring(g_L, fn);
    lua_rawget(g_L, -2);
    lua_remove(g_L, -2);
    if (lua_isfunction(g_L, -1)) {
        lua_pushstring(g_L, fn);
        lua_pushlightuserdata(g_L, self);
        lua_pushlightuserdata(g_L, (void *)(uintptr_t)ctx);
        if (lua_pcall(g_L, 3, 0, 0) != LUA_OK) {
            L("[lua] runtime error in %s: %s", fn, lua_tostring(g_L, -1));
            lua_pop(g_L, 1);
        }
    } else {
        lua_pop(g_L, 1);
    }
    lua_unlock();
}

