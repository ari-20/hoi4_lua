#include "hoi4_common.h"
#include "third-party/lua54/lua-5.4.7/src/lua.hpp"

// -+ ASYNC interface (v2)
// Lua-task model:
//   an async task IS Lua code, running in a SEPARATE lua_State on a worker
//   thread. Data crosses states ONLY as serialized Lua literals (C-side
//   serializer here; functions travel via lua_dump bytecode embedded as a
//   load("...") literal - upvalues do NOT travel, pass everything in args).
//   Structured returns: the worker serializes its return value the same way;
//   the main state rebuilds it via load("return <literal>").
// Pool: ASYNC_WORKERS worker threads, FIFO start order, per-task state.
// Completion: cb(id,status,value) fires on the MAIN thread at a frame
// boundary (two-phase dispatch: snapshot refs under lock, pcall outside),
// AND/OR polling via async_poll (take) / async_status (peek).
// Cancel: QUEUED tasks are removed outright; RUNNING tasks are not killed
// (never TerminateThread a worker that may hold a bare lua_State).
// Timeout: opts.timeout_ms is ENFORCED (v2, see the IPC_ST_TIMEOUT block
// below) — expiry is swept at frame boundaries: queued tasks retire at once,
// running tasks notify their callback once and discard the late result.
// Worker red lines (red lines): never touch g_L / game memory / engine heap.
// The worker state loads full standard libs incl. io/os - blocking there
// blocks only that worker.

#define ASYNC_TASKS       512     // fixed task table
#define ASYNC_WORKERS     4
#define ASYNC_CHUNK_MAX   8192
#define ASYNC_ARGS_MAX    16384
#define ASYNC_RESULT_MAX  8192
#define ASYNC_SER_DEPTH   16      // nested table depth cap
#define ASYNC_SER_PAIRS   256     // pairs per table cap

#define IPC_ST_ERR_CANCELLED  9       // removed from queue before start
#define IPC_ST_ERR_LUA        10      // task raised a Lua error
#define IPC_ST_ERR_INTERNAL   11      // alloc/infra failure
#define IPC_ST_TIMEOUT        12      // deadline exceeded (opts.timeout_ms)

// TIMEOUT ENFORCEMENT (v2, user request 9-19): opts.timeout_ms is now REAL.
//   QUEUED  -> retired to DONE/TIMEOUT outright (no worker attached yet)
//   RUNNING -> cb is notified ONCE with TIMEOUT and the slot is PINNED (not
//              recycled; the worker thread finishes in the background and
//              discards its own result). Threads are never terminated — a
//              worker may be deep inside a blocking syscall (WinHTTP) or a
//              Lua longjmp-unsafe region. QUEUED expiry also covers queue
//              starvation (4 workers busy elsewhere).
// deadline=0 means no timeout (opts omitted or timeout_ms<=0).

typedef struct {
    int      state;               // AT_*
    int      status;              // IPC_ST_* once DONE
    uint64_t id;
    int      cb_ref;              // luaL_ref in MAIN state; LUA_NOREF = none
    unsigned gen;                 // session generation at submit (B2): results
                                  // whose gen != current are orphaned, never
                                  // delivered into a new session
    DWORD64  deadline;            // GetTickCount64() at which to time out; 0=none
    long     timeout_ms;          // as submitted (for the message)
    int      timed_out;           // already reported; worker must discard result
    int      timeout_taken;       // poll() already returned the TIMEOUT report
    uint32_t chunk_len;
    uint32_t args_len;
    uint32_t res_len;
    char     chunk[ASYNC_CHUNK_MAX];
    char     args[ASYNC_ARGS_MAX];
    char     result[ASYNC_RESULT_MAX];  // serialized literal (OK) or raw msg
} AsyncTask;

#define AT_IDLE    0
#define AT_QUEUED  1
#define AT_RUNNING 2
#define AT_DONE    3

static AsyncTask      g_atasks[ASYNC_TASKS];
static CRITICAL_SECTION  g_alock;
static INIT_ONCE         g_alockOnce = INIT_ONCE_STATIC_INIT;
static HANDLE            g_awake;          // auto-reset: one release per job
static volatile LONG     g_aworkers;       // live worker count
static volatile uint64_t g_aseq;
static volatile unsigned g_sessionGen;     // B2: bumped on session switch

static BOOL CALLBACK async_once_init(PINIT_ONCE io, PVOID arg, PVOID *ctx) {
    (void)io; (void)arg; (void)ctx;
    InitializeCriticalSection(&g_alock);
    g_awake = CreateEventA(NULL, FALSE, FALSE, NULL);  // auto-reset
    for (int i = 0; i < ASYNC_TASKS; i++) {
        g_atasks[i].state  = AT_IDLE;
        g_atasks[i].cb_ref = LUA_NOREF;
    }
    return TRUE;
}

// InitOnce guarantees no thread observes a half-initialized lock/event (the
// old CAS-flag pattern published "done" before the CS was initialized).
static void async_lock_init_once(void)
{
    InitOnceExecuteOnce(&g_alockOnce, async_once_init, NULL, NULL);
}

// -+ async serializer (main <-> worker Lua states)
// Values cross as Lua source literals; functions cross as bytecode wrapped
// in load(): load("\27<escaped bytes>") (binary chunk, string-escaped).
// Unsupported types (userdata/thread/lightuserdata) abort with 0.
// Threading note: serialization happens ONLY on the main thread inside
// hoi4.async_exec while holding g_alock; the dump scratch buffer is static.

static int ser_value(lua_State *Ls, int idx, char *out, size_t cap,
                         size_t *pos, int depth);

struct DumpCtx { char *buf; size_t cap, len; int fail; };

static int dump_writer(lua_State *L, const void *data, size_t sz, void *ud)
{
    (void)L;                                   // lua_Writer signature: 4 args
    struct DumpCtx *c = (struct DumpCtx *)ud;
    if (c->len + sz > c->cap) { c->fail = 1; return 1; }
    if (sz) memcpy(c->buf + c->len, data, sz);
    c->len += sz;
    return 0;
}

static int ser_putc(char *out, size_t cap, size_t *pos, char c)
{
    if (*pos + 1 >= cap) return 0;
    out[(*pos)++] = c;
    return 1;
}

static int ser_puts(char *out, size_t cap, size_t *pos,
                        const char *s, size_t n)
{
    if (*pos + n >= cap) return 0;
    memcpy(out + *pos, s, n);
    *pos += n;
    return 0 == 1 ? 0 : 1;
}

static int ser_string(lua_State *Ls, int idx, char *out, size_t cap,
                          size_t *pos)
{
    size_t l = 0;
    const char *s = lua_tolstring(Ls, idx, &l);
    if (!s) return 0;
    if (!ser_putc(out, cap, pos, '"')) return 0;
    for (size_t i = 0; i < l; i++) {
        unsigned char c = (unsigned char)s[i];
        int ok;
        if (c == '"' || c == '\\') {
            ok = ser_putc(out, cap, pos, '\\') &&
                 ser_putc(out, cap, pos, (char)c);
        } else if (c == '\n') {
            ok = ser_puts(out, cap, pos, "\\n", 2);
        } else if (c == '\r') {
            ok = ser_puts(out, cap, pos, "\\r", 2);
        } else if (c == '\t') {
            ok = ser_puts(out, cap, pos, "\\t", 2);
        } else if (c < 0x20 || c == 0x7f) {
            char tmp[8];
            int n = snprintf(tmp, sizeof(tmp), "\\%03u", (unsigned)c);
            ok = ser_puts(out, cap, pos, tmp, (size_t)n);
        } else {
            ok = ser_putc(out, cap, pos, (char)c);
        }
        if (!ok) return 0;
    }
    return ser_putc(out, cap, pos, '"');
}

static int ser_function_bytes(char *out, size_t cap, size_t *pos,
                              const char *bytes, size_t blen);

// function -> load("<escaped bytecode>") literal
static int ser_function(lua_State *Ls, int idx, char *out, size_t cap,
                            size_t *pos)
{
    static char bytes[ASYNC_CHUNK_MAX];       // main-thread + g_alock only
    struct DumpCtx ctx;
    ctx.buf = bytes; ctx.cap = sizeof(bytes); ctx.len = 0; ctx.fail = 0;
    if (lua_dump(Ls, dump_writer, &ctx, 0) != 0 || ctx.fail || !ctx.len)
        return 0;                                  // unloadable/stripped fn
    return ser_function_bytes(out, cap, pos, bytes, ctx.len);
}

// escape already-dumped bytecode at out+pos (no wrapper; caller supplies one)
static int ser_function_bytes_raw(char *out, size_t cap, size_t *pos,
                                      const char *bytes, size_t blen)
{
    for (size_t i = 0; i < blen; i++) {
        unsigned char c = (unsigned char)bytes[i];
        int ok;
        if (c == '"' || c == '\\') {
            ok = ser_putc(out, cap, pos, '\\') &&
                 ser_putc(out, cap, pos, (char)c);
        } else if (c < 0x20 || c == 0x7f) {
            char tmp[8];
            int n = snprintf(tmp, sizeof(tmp), "\\%03u", (unsigned)c);
            ok = ser_puts(out, cap, pos, tmp, (size_t)n);
        } else {
            ok = ser_putc(out, cap, pos, (char)c);
        }
        if (!ok) return 0;
    }
    return 1;
}

// escape already-dumped bytecode into load("...") at out+pos
static int ser_function_bytes(char *out, size_t cap, size_t *pos,
                                  const char *bytes, size_t blen)
{
    if (!ser_puts(out, cap, pos, "load(\"\\27", 9)) return 0;
    for (size_t i = 0; i < blen; i++) {
        unsigned char c = (unsigned char)bytes[i];
        int ok;
        if (c == '"' || c == '\\') {
            ok = ser_putc(out, cap, pos, '\\') &&
                 ser_putc(out, cap, pos, (char)c);
        } else if (c < 0x20 || c == 0x7f) {
            char tmp[8];
            int n = snprintf(tmp, sizeof(tmp), "\\%03u", (unsigned)c);
            ok = ser_puts(out, cap, pos, tmp, (size_t)n);
        } else {
            ok = ser_putc(out, cap, pos, (char)c);
        }
        if (!ok) return 0;
    }
    return ser_puts(out, cap, pos, "\")", 2);
}

// key=value pair for tables; keys limited to strings and integers.
// String keys MUST use ["key"]= form: {"x"=1} is a Lua SYNTAX error
// (bare name= only accepts identifiers, quoted strings need brackets).
static int ser_keyval(lua_State *Ls, int kidx, int vidx,
                          char *out, size_t cap, size_t *pos, int depth)
{
    int kt = lua_type(Ls, kidx);
    if (kt == LUA_TSTRING) {
        if (!ser_putc(out, cap, pos, '[')) return 0;
        if (!ser_string(Ls, kidx, out, cap, pos)) return 0;
        if (!ser_puts(out, cap, pos, "]=", 2)) return 0;
    } else if (kt == LUA_TNUMBER) {
        // integer-key form [n]=v keeps array ordering unambiguous
        lua_Integer k = lua_tointeger(Ls, kidx);
        char tmp[32];
        int n = snprintf(tmp, sizeof(tmp), "[%lld]=", (long long)k);
        if (!ser_puts(out, cap, pos, tmp, (size_t)n)) return 0;
    } else {
        return 0;                                  // unsupported key type
    }
    return ser_value(Ls, vidx, out, cap, pos, depth);
}

static int ser_value(lua_State *Ls, int idx, char *out, size_t cap,
                         size_t *pos, int depth)
{
    // CRITICAL: resolve to an ABSOLUTE index before the TABLE branch pushes
    // anything. The caller passes -1 (top); lua_pushnil below would make a
    // relative idx point at the pushed nil instead of the table -> lua_next
    // on nil = memory corruption (this was the silent worker-death bug).
    if (idx < 0) idx = lua_gettop(Ls) + 1 + idx;
    switch (lua_type(Ls, idx)) {
    case LUA_TNIL:
        return ser_puts(out, cap, pos, "nil", 3);
    case LUA_TBOOLEAN:
        return lua_toboolean(Ls, idx)
             ? ser_puts(out, cap, pos, "true", 4)
             : ser_puts(out, cap, pos, "false", 5);
    case LUA_TNUMBER: {
        // full precision; integers as plain %lld (same Lua version both
        // sides, so no cross-version literal risk)
        char tmp[64];
        int n;
        if (lua_isinteger(Ls, idx)) {
            long long v = (long long)lua_tointeger(Ls, idx);
            n = snprintf(tmp, sizeof(tmp), "%lld", v);
        } else {
            double d = (double)lua_tonumber(Ls, idx);
            n = snprintf(tmp, sizeof(tmp), "(%.17g)", d);
        }
        return ser_puts(out, cap, pos, tmp, (size_t)n);
    }
    case LUA_TSTRING:
        return ser_string(Ls, idx, out, cap, pos);
    case LUA_TTABLE: {
        if (depth > ASYNC_SER_DEPTH) return 0;
        // recursion below pushes per level; ensure the Lua C stack has room
        if (!lua_checkstack(Ls, 8)) return 0;
        if (!ser_putc(out, cap, pos, '{')) return 0;
        int count = 0;
        lua_pushnil(Ls);
        while (lua_next(Ls, idx) != 0) {
            if (++count > ASYNC_SER_PAIRS) { lua_pop(Ls, 2); return 0; }
            // separator BEFORE every pair except the first
            if (count > 1 && !ser_putc(out, cap, pos, ',')) {
                lua_pop(Ls, 2);
                return 0;
            }
            // stack: key(-2), value(-1); use absolute-ish indices via top
            int k = lua_gettop(Ls) - 1, v = lua_gettop(Ls);
            if (!ser_keyval(Ls, k, v, out, cap, pos, depth + 1)) {
                lua_pop(Ls, 2);
                return 0;
            }
            lua_pop(Ls, 1);                        // pop value, keep key
        }
        return ser_putc(out, cap, pos, '}');
    }
    case LUA_TFUNCTION:
        return ser_function(Ls, idx, out, cap, pos);
    default:
        return 0;                                  // userdata/thread/...
    }
}

// -+ async worker pool + task execution (v2)
// One FIFO pick per wake; ASYNC_WORKERS threads; each task runs in its
// own lua_State with full standard libs. RUNNING tasks are never aborted
// (v1 scope decision): timeout_ms is accepted and ignored, cancel applies
// only to QUEUED tasks. Structured results: the task's return value is
// serialized back to a literal and rebuilt on the main state at poll/cb.

static DWORD WINAPI async_worker_thread(LPVOID arg)
{
    (void)arg;
    for (;;) {
        DWORD w = WaitForSingleObject(g_awake, INFINITE);
        if (w != WAIT_OBJECT_0) continue;

        EnterCriticalSection(&g_alock);
        AsyncTask *t = NULL;
        for (int i = 0; i < ASYNC_TASKS; i++) {
            if (g_atasks[i].state == AT_QUEUED) { t = &g_atasks[i]; break; }
        }
        if (!t) { LeaveCriticalSection(&g_alock); continue; } // spurious wake
        t->state = AT_RUNNING;
        LeaveCriticalSection(&g_alock);

        L("[async] run id=%llu len=%u",
          (unsigned long long)t->id, t->args_len);

        // ---- execute on an isolated state -------------------------------
        L("[async] exec id=%llu step=1 newstate", (unsigned long long)t->id);
        lua_State *W = luaL_newstate();
        if (!W) {
            EnterCriticalSection(&g_alock);
            t->status = IPC_ST_ERR_INTERNAL;
            snprintf(t->result, ASYNC_RESULT_MAX, "state alloc failed");
            t->res_len = (uint32_t)strlen(t->result);
            t->state = AT_DONE;
            LeaveCriticalSection(&g_alock);
        } else {
            luaL_openlibs(W);                  // full libs incl io/os
            // The worker is a SECOND VM with its own base library, so it must
            // be hardened too: leaving this out would hand every mod a
            // bypass (its own dofile/loadfile plus the full stdlib) that the
            // main VM's hardening does not cover.
            lua_harden_libs(W);
            lua_policy_install(W);
            // Outbound network for workers: the async Lua state is a bare
            // lua_State, so hoi4.http_request (WinHTTP) must be registered
            // here explicitly — it is the one hoi4.* function that is safe
            // off the main thread (no game memory, no engine heap).
            hoi4_register_http(W);
            L("[async] exec id=%llu step=2 openlibs done", (unsigned long long)t->id);
            int ok = 1;
            // chunk -> function
            if (luaL_loadbufferx(W, t->chunk, t->chunk_len, "=async_chunk", NULL) != LUA_OK) {
                snprintf(t->result, ASYNC_RESULT_MAX,
                         "chunk error: %s", lua_tostring(W, -1));
                ok = 0;
            }
            // args literal -> value. load() compiles a BLOCK: a bare table
            // constructor is an expression and must be wrapped in "return ".
            if (ok && luaL_loadbufferx(W, t->args, t->args_len, "=async_args", NULL) != LUA_OK) {
                snprintf(t->result, ASYNC_RESULT_MAX,
                         "args error: %s", lua_tostring(W, -1));
                ok = 0;
            }
            if (ok && lua_pcall(W, 0, 1, 0) != LUA_OK) {
                snprintf(t->result, ASYNC_RESULT_MAX,
                         "args error: %s", lua_tostring(W, -1));
                ok = 0;
            }
            if (ok && !lua_istable(W, -1)) {
                snprintf(t->result, ASYNC_RESULT_MAX, "args must be a table");
                ok = 0;
            }
            L("[async] exec id=%llu step=3 args ok=%d", (unsigned long long)t->id, ok);
            // call chunk(args)
            if (ok && lua_pcall(W, 1, 1, 0) != LUA_OK) {
                const char *e = lua_tostring(W, -1);
                snprintf(t->result, ASYNC_RESULT_MAX,
                         "task error: %s", e ? e : "(non-string error)");
                ok = 0;
            }
            if (ok) {
                // serialize return value (top of stack) under g_alock
                // (the serializer's static scratch buffers require it)
                EnterCriticalSection(&g_alock);
                size_t pos = 0;
                int ser_ok = ser_value(W, -1, t->result,
                                           ASYNC_RESULT_MAX, &pos, 0);
                if (ser_ok) {
                    t->result[pos] = 0;
                    t->res_len = (uint32_t)pos;
                    t->status = IPC_ST_OK;
                } else {
                    snprintf(t->result, ASYNC_RESULT_MAX,
                             "return value not serializable");
                    t->res_len = (uint32_t)strlen(t->result);
                    t->status = IPC_ST_ERR_LUA;
                }
                LeaveCriticalSection(&g_alock);
            } else {
                t->status = IPC_ST_ERR_LUA;
                t->res_len = (uint32_t)strlen(t->result);
            }
            lua_close(W);
        }

        EnterCriticalSection(&g_alock);
        int was_timeout = t->timed_out;
        if (t->timed_out) {
            // consumer already got TIMEOUT; this slot was pinned (never
            // recycled mid-flight) so it is still ours to retire — discard
            // the late result outright instead of overwriting the report.
            memset(t, 0, sizeof(*t));
            t->state = AT_IDLE;
            t->cb_ref = LUA_NOREF;
        } else {
            t->state = AT_DONE;
        }
        LeaveCriticalSection(&g_alock);
        L("[async] done id=%llu status=%d len=%u%s",
          (unsigned long long)t->id, t->status, t->res_len,
          was_timeout ? " (timed out, discarded)" : "");

        // release one more pending job, if any (auto-reset event: each
        // SetEvent releases exactly one waiter; re-set while work remains)
        EnterCriticalSection(&g_alock);
        int moreQueued = 0;
        for (int i = 0; i < ASYNC_TASKS; i++)
            if (g_atasks[i].state == AT_QUEUED) { moreQueued = 1; break; }
        LeaveCriticalSection(&g_alock);
        if (moreQueued) SetEvent(g_awake);
    }
    return 0;
}

static void async_ensure_workers(void)
{
    // Reserve the slot BEFORE CreateThread: two concurrent callers used to
    // both pass the < ASYNC_WORKERS check and overshoot the pool size.
    for (;;) {
        LONG live = InterlockedCompareExchange(&g_aworkers, 0, 0);
        if (live >= ASYNC_WORKERS) return;
        LONG reserved = InterlockedIncrement(&g_aworkers);
        if (reserved > ASYNC_WORKERS) {
            InterlockedDecrement(&g_aworkers);   // lost the race: unreserve
            return;
        }
        HANDLE h = CreateThread(NULL, 4 * 1024 * 1024, async_worker_thread, NULL, 0, NULL);
        // 4MB explicit stack: the exe's PE default (inherited when size=0) can
        // be tiny; a fresh Lua state + compiler recursion needs real headroom.
        if (!h) {
            InterlockedDecrement(&g_aworkers);   // spawn failed: unreserve
            return;
        }
        CloseHandle(h);
    }
}

// -+ async Lua API + frame-heartbeat callback dispatch
// hoi4.async_exec(chunk, args, opts) / async_cancel(id)
// hoi4.async_poll(id) -> status,value | nil   (take)
// hoi4.async_status(id) -> status,value       (peek)
// opts: { timeout_ms = n (accepted, ignored in v1), cb = fn }
// cb signature: cb(id, status, value_or_errmsg)

// submit; returns id (integer). Errors via lua_error on bad args/full table.
int hoi4_async_exec(lua_State *Ls)
{
    // init FIRST: args serialization below enters g_alock, and a zero-filled
    // CRITICAL_SECTION passed to EnterCriticalSection is instant UB (this
    // exact ordering bug silently killed the process on first load).
    async_lock_init_once();
    size_t cl = 0;
    const char *chunk = NULL;
    int chunk_owned = 0;

    // chunk: string OR function (string.dump -> load("bytes") literal;
    // upvalues do NOT travel - the task must take everything via args)
    if (lua_type(Ls, 1) == LUA_TFUNCTION) {
        static char bytes[ASYNC_CHUNK_MAX];
        struct DumpCtx ctx;
        ctx.buf = bytes; ctx.cap = sizeof(bytes); ctx.len = 0; ctx.fail = 0;
        // lua_dump reads the value AT STACK TOP (api_checknelems(L,1)) —
        // copy the function to top first, pop after. Dumping whatever else
        // sits on top returns garbage / fails ("function not dumpable").
        lua_pushvalue(Ls, 1);
        int drc = lua_dump(Ls, dump_writer, &ctx, 0);
        lua_pop(Ls, 1);
        if (drc != 0 || ctx.fail || !ctx.len)
            luaL_argerror(Ls, 1, "function not dumpable");
        // worst-case escaping is 4x; reject early if it cannot fit
        if (ctx.len * 4 + 32 >= ASYNC_CHUNK_MAX)
            luaL_argerror(Ls, 1, "function bytecode too large");
        char tmp[ASYNC_CHUNK_MAX];
        size_t pos = 0;
        // Wrap: the worker loads this chunk and CALLS it with args. A bare
        // load("...") expression only evaluates to the restored function and
        // returns it - the task would "finish" without ever running. The
        // wrapper invokes it with args and returns its result:
        //   local args = ... ; return (load("<bc>"))(args)
        const char *pre = "local args = ... ; return (load(\"";
        const char *post = "\"))(args)";
        size_t wpos = 0;
        int okw = ser_puts(tmp, sizeof(tmp), &wpos, pre, strlen(pre)) &&
                  ser_function_bytes_raw(tmp, sizeof(tmp), &wpos, bytes, ctx.len) &&
                  ser_puts(tmp, sizeof(tmp), &wpos, post, strlen(post));
        if (!okw) luaL_argerror(Ls, 1, "function bytecode too large");
        tmp[wpos] = 0;
        {   // debug: persist the generated wrapper for offline luac -p
            // (game-dir relative, no hardcoded path)
            char dbgpath[512];
            const char *gd = game_dir_utf8();
            if (gd && *gd &&
                _snprintf_s(dbgpath, sizeof(dbgpath), _TRUNCATE,
                            "%s\\gen_chunk.lua", gd) > 0) {
                FILE *f = fopen(dbgpath, "wb");
                if (f) { fwrite(tmp, 1, wpos, f); fclose(f); }
            }
        }
        {
            char *owned = (char *)malloc(wpos + 1);
            if (!owned) luaL_argerror(Ls, 1, "out of memory");
            chunk = (const char *)memcpy(owned, tmp, wpos + 1);
        }
        cl = wpos;
        chunk_owned = 1;
        {   // debug: dump head/tail of the generated literal
            char head[81];
            size_t n = pos < 80 ? pos : 80;
            memcpy(head, tmp, n); head[n] = 0;
            L("[async] fn chunk len=%d head=[%s]", (int)pos, head);
        }
    } else {
        chunk = luaL_checklstring(Ls, 1, &cl);
        if (!cl) luaL_argerror(Ls, 1, "empty chunk");
        if (cl >= ASYNC_CHUNK_MAX)
            luaL_argerror(Ls, 1, "chunk too large");
    }

    // serialize args (default: empty table literal "{}")
    char ser[ASYNC_ARGS_MAX];
    size_t pos = 0;
    int haveArgs = 0;
    if (!lua_isnoneornil(Ls, 2)) {
        if (lua_type(Ls, 2) != LUA_TTABLE) {
            if (chunk_owned) free((void *)chunk);
            luaL_argerror(Ls, 2, "table expected");
        }
        EnterCriticalSection(&g_alock);
        int ok = ser_value(Ls, 2, ser, sizeof(ser), &pos, 0);
        LeaveCriticalSection(&g_alock);
        if (!ok) {
            if (chunk_owned) free((void *)chunk);
            luaL_error(Ls,
                "args not serializable (depth>=%d, pairs>%d, or unsupported type)",
                ASYNC_SER_DEPTH, ASYNC_SER_PAIRS);
        }
        ser[pos] = 0;
        // load() compiles a BLOCK: wrap the literal as "return <literal>".
        // The wrapper needs 7 extra bytes BEYOND what the serializer
        // guaranteed fits — check before shifting (was a 7-byte stack overflow
        // for max-size args).
        if (pos + 8 > sizeof(ser)) {
            if (chunk_owned) free((void *)chunk);
            luaL_error(Ls, "args too large after return-prefix wrapping");
        }
        memmove(ser + 7, ser, pos + 1);        // incl NUL
        memcpy(ser, "return ", 7);
        pos += 7;
        haveArgs = 1;
    }

    // opts
    int timeout_ms = 0;
    int cb_ref = LUA_NOREF;
    if (lua_istable(Ls, 3)) {
        lua_getfield(Ls, 3, "timeout_ms");
        if (lua_isnumber(Ls, -1)) timeout_ms = (int)lua_tointeger(Ls, -1);
        lua_pop(Ls, 1);
        lua_getfield(Ls, 3, "cb");
        if (lua_isfunction(Ls, -1)) {
            lua_pushvalue(Ls, -1);                 // ref consumes a copy
            cb_ref = luaL_ref(Ls, LUA_REGISTRYINDEX);
        }
        lua_pop(Ls, 1);
    }

    async_lock_init_once();
    EnterCriticalSection(&g_alock);
    AsyncTask *t = NULL;
    for (int i = 0; i < ASYNC_TASKS; i++)
        if (g_atasks[i].state == AT_IDLE) { t = &g_atasks[i]; break; }
    if (!t) {
        // reclaim the OLDEST done slot that has no pending callback
        for (int i = 0; i < ASYNC_TASKS; i++) {
            AsyncTask *d = &g_atasks[i];
            if (d->state == AT_DONE && d->cb_ref == LUA_NOREF) {
                L("[async] reclaim done slot id=%llu (unpolled)",
                  (unsigned long long)d->id);
                t = d;
                break;
            }
        }
    }
    if (!t) {
        LeaveCriticalSection(&g_alock);
        // release everything this call acquired before longjmp-ing away
        if (cb_ref != LUA_NOREF) luaL_unref(Ls, LUA_REGISTRYINDEX, cb_ref);
        if (chunk_owned) free((void *)chunk);
        return luaL_error(Ls, "async: task table full (%d)", ASYNC_TASKS);
    }

    memset(t, 0, sizeof(*t));
    t->id         = (uint64_t)InterlockedIncrement64((volatile LONG64 *)&g_aseq);
    t->state      = AT_QUEUED;
    t->status     = IPC_ST_PENDING;
    t->cb_ref     = cb_ref;
    t->gen        = g_sessionGen;            // B2: session of record
    t->timeout_ms = timeout_ms;
    if (timeout_ms > 0)
        t->deadline = GetTickCount64() + (DWORD64)timeout_ms;
    memcpy(t->chunk, chunk, cl + 1 > ASYNC_CHUNK_MAX ? ASYNC_CHUNK_MAX : cl + 1);
    t->chunk_len  = (uint32_t)cl;
    if (haveArgs) {
        memcpy(t->args, ser, pos + 1);
        t->args_len = (uint32_t)pos;
    } else {
        memcpy(t->args, "return {}", 10);
        t->args_len = 9;
    }
    SetEvent(g_awake);
    LeaveCriticalSection(&g_alock);

    async_ensure_workers();
    // args 内含 Authorization 等请求头, 只记长度不打内容 (url 由 [httpc] 行覆盖)
    L("[async] queued id=%llu timeout=%d(cb=%d) len=%u",
      (unsigned long long)t->id, timeout_ms, cb_ref != LUA_NOREF, t->args_len);
    lua_pushinteger(Ls, (lua_Integer)t->id);
    if (chunk_owned) free((void *)chunk);
    return 1;
}

// cancel: QUEUED only (v1 scope). RUNNING tasks run to completion.
int hoi4_async_cancel(lua_State *Ls)
{
    uint64_t id = (uint64_t)luaL_checkinteger(Ls, 1);
    async_lock_init_once();
    int ok = 0;
    EnterCriticalSection(&g_alock);
    for (int i = 0; i < ASYNC_TASKS; i++) {
        AsyncTask *t = &g_atasks[i];
        if (t->id != id || t->state != AT_QUEUED) continue;
        t->state = AT_IDLE;
        t->id = 0;
        if (t->cb_ref != LUA_NOREF) {
            luaL_unref(Ls, LUA_REGISTRYINDEX, t->cb_ref);
            t->cb_ref = LUA_NOREF;
        }
        ok = 1;
        break;
    }
    LeaveCriticalSection(&g_alock);
    L("[async] cancel id=%llu queued-remove=%d", (unsigned long long)id, ok);
    lua_pushboolean(Ls, ok);
    return 1;
}

// B2: session switch — orphan ALL in-flight async work so nothing from the
// old session can deliver into the new one.
//   QUEUED  -> cancelled outright (ref released, slot recycled)
//   DONE    -> dropped (ref released, slot recycled)
//   RUNNING -> left alone (v1 scope: workers run to completion); its gen
//              stays stale, so async_dispatch_locked recycles the slot
//              without firing the callback when it completes.
// Called from session_dispatch_locked (frame top, g_luaLock held, g_L valid).
void async_session_reset(void)
{
    async_lock_init_once();
    EnterCriticalSection(&g_alock);
    g_sessionGen++;
    for (int i = 0; i < ASYNC_TASKS; i++) {
        AsyncTask *t = &g_atasks[i];
        if (t->state == AT_QUEUED || t->state == AT_DONE) {
            if (t->cb_ref != LUA_NOREF) {
                luaL_unref(g_L, LUA_REGISTRYINDEX, t->cb_ref);
            }
            memset(t, 0, sizeof(*t));
            t->state  = AT_IDLE;
            t->cb_ref = LUA_NOREF;
        }
        // AT_RUNNING: untouched (worker owns it); stale gen => dropped later
    }
    LeaveCriticalSection(&g_alock);
    L("[async] session reset: gen=%u, queued/done purged", g_sessionGen);
}

// shared take/peek core; mode 0=take 1=peek. Pushes status+value or nil.
// Value is rebuilt structurally (load "return <literal>") when the task
// finished OK; error text comes back as a plain string.
static void async_lookup(lua_State *Ls, uint64_t id, int peek)
{
    async_lock_init_once();
    int found = 0;
    EnterCriticalSection(&g_alock);
    for (int i = 0; i < ASYNC_TASKS; i++) {
        AsyncTask *t = &g_atasks[i];
        if (t->id != id) continue;
        int isDone = (t->state == AT_DONE);
        int isTimeoutRunning = (t->state == AT_RUNNING && t->timed_out);
        if (!isDone && !isTimeoutRunning) continue;
        if (isTimeoutRunning && t->timeout_taken) continue;   // already taken
        if (t->gen != g_sessionGen) continue;  // B2: stale-session result = gone
        lua_pushinteger(Ls, t->status);
        int pushedValue = 0;
        if (t->status == IPC_ST_OK) {
            char expr[ASYNC_RESULT_MAX + 16];
            snprintf(expr, sizeof(expr), "return %s", t->result);
            if (luaL_loadstring(Ls, expr) == LUA_OK &&
                lua_pcall(Ls, 0, 1, 0) == LUA_OK)
                pushedValue = 1;
            else
                lua_pop(Ls, 1);
        }
        if (!pushedValue)
            lua_pushlstring(Ls, t->result, t->res_len);
        found = 1;
        if (isTimeoutRunning) {
            // slot stays pinned for the worker; the report may be consumed
            // once via take. nothing else to recycle here.
            if (!peek) t->timeout_taken = 1;
            break;
        }
        if (!peek) {
            // take: free cb + recycle slot
            if (t->cb_ref != LUA_NOREF) {
                luaL_unref(Ls, LUA_REGISTRYINDEX, t->cb_ref);
                t->cb_ref = LUA_NOREF;
            }
            memset(t, 0, sizeof(*t));
            t->state = AT_IDLE;
            t->cb_ref = LUA_NOREF;
        }
        break;
    }
    LeaveCriticalSection(&g_alock);
    if (!found) { lua_pushnil(Ls); lua_pushnil(Ls); }
}

int hoi4_async_poll(lua_State *Ls)
{
    uint64_t id = (uint64_t)luaL_checkinteger(Ls, 1);
    async_lookup(Ls, id, 0);
    return 2;
}

int hoi4_async_status(lua_State *Ls)
{
    uint64_t id = (uint64_t)luaL_checkinteger(Ls, 1);
    async_lookup(Ls, id, 1);
    return 2;
}

// frame-heartbeat dispatch (main thread, g_luaLock held).
// Two-phase: snapshot DONE-with-cb slots under g_alock, pcall OUTSIDE it -
// the callback may itself call hoi4.async_exec (which takes g_alock).
#define ASYNC_CB_BATCH 8
// static: 8x8KB on the stack risks blowing the engine main thread's tight
// stack (observed silent death right after dispatch started).
static struct { int ref; uint64_t id; int status; char text[ASYNC_RESULT_MAX]; } snap[ASYNC_CB_BATCH];
void async_dispatch_locked(lua_State *Ls)
{
    int n = 0;

    // dispatch runs every frame whether or not any async call happened yet;
    // the lock init is lazy (done at the API entries), so guarantee it here —
    // a zero-filled CRITICAL_SECTION passed to EnterCriticalSection is instant UB
    async_lock_init_once();

    EnterCriticalSection(&g_alock);

    // ---- timeout sweep: retire expired tasks at frame cadence --------------
    // QUEUED  -> no worker attached: mark DONE/TIMEOUT, normal path delivers.
    // RUNNING -> worker owns the slot: notify cb once via the same snapshot,
    //            but keep the slot PINNED (state stays AT_RUNNING) until the
    //            worker thread exits and discards its own late result.
    {
        DWORD64 now = GetTickCount64();
        for (int i = 0; i < ASYNC_TASKS; i++) {
            AsyncTask *t = &g_atasks[i];
            if (!t->deadline || t->timed_out) continue;
            if (t->state != AT_QUEUED && t->state != AT_RUNNING) continue;
            if (now < t->deadline) continue;
            t->timed_out = 1;
            t->status = IPC_ST_TIMEOUT;
            snprintf(t->result, ASYNC_RESULT_MAX,
                     "async timeout after %ld ms", t->timeout_ms);
            t->res_len = (uint32_t)strlen(t->result);
            if (t->state == AT_QUEUED)
                t->state = AT_DONE;      // deliver + recycle below
            else if (t->cb_ref != LUA_NOREF && n < ASYNC_CB_BATCH) {
                // RUNNING with a callback: deliver now, pin the slot.
                // Ref MOVES to the snapshot (delivery loop unrefs it exactly
                // once, same as the AT_DONE path) — never unref here.
                snap[n].ref = t->cb_ref;
                t->cb_ref = LUA_NOREF;
                snap[n].id = t->id;
                snap[n].status = t->status;
                uint32_t take = t->res_len;
                memcpy(snap[n].text, t->result, take);
                snap[n].text[take] = 0;
                n++;
            }
            L("[async] id=%llu timed out (%ld ms, %s)",
              (unsigned long long)t->id, t->timeout_ms,
              t->state == AT_DONE ? "queued retired" : "running, cb notified");
        }
    }

    for (int i = 0; i < ASYNC_TASKS && n < ASYNC_CB_BATCH; i++) {
        AsyncTask *t = &g_atasks[i];
        if (t->state != AT_DONE) continue;
        if (t->gen != g_sessionGen) {
            // B2: orphaned result from a previous session — never deliver.
            // Release the callback and recycle the slot.
            if (t->cb_ref != LUA_NOREF) {
                luaL_unref(Ls, LUA_REGISTRYINDEX, t->cb_ref);
                t->cb_ref = LUA_NOREF;
            }
            memset(t, 0, sizeof(*t));
            t->state = AT_IDLE;
            t->cb_ref = LUA_NOREF;
            continue;
        }
        if (t->cb_ref == LUA_NOREF) continue;
        snap[n].ref = t->cb_ref;
        snap[n].id = t->id;
        snap[n].status = t->status;
        uint32_t take = t->res_len < ASYNC_RESULT_MAX ? t->res_len : ASYNC_RESULT_MAX - 1;
        memcpy(snap[n].text, t->result, take);
        snap[n].text[take] = 0;
        n++;
        // slot consumed by dispatch: recycle now (ref moved to snapshot)
        t->cb_ref = LUA_NOREF;
        memset(t, 0, sizeof(*t));
        t->state = AT_IDLE;
        t->cb_ref = LUA_NOREF;
    }
    LeaveCriticalSection(&g_alock);

    for (int i = 0; i < n; i++) {
        lua_rawgeti(Ls, LUA_REGISTRYINDEX, snap[i].ref);
        luaL_unref(Ls, LUA_REGISTRYINDEX, snap[i].ref);
        // arg1: id
        lua_pushinteger(Ls, (lua_Integer)snap[i].id);
        // arg2: status
        lua_pushinteger(Ls, (lua_Integer)snap[i].status);
        // arg3: value - structured (OK) or raw message (error)
        int pushedValue = 0;
        if (snap[i].status == IPC_ST_OK) {
            char expr[ASYNC_RESULT_MAX + 16];
            snprintf(expr, sizeof(expr), "return %s", snap[i].text);
            if (luaL_loadstring(Ls, expr) == LUA_OK &&
                lua_pcall(Ls, 0, 1, 0) == LUA_OK)
                pushedValue = 1;
            else {
                L("[async] rebuild failed for id=%llu: %s",
                  (unsigned long long)snap[i].id, lua_tostring(Ls, -1));
                lua_pop(Ls, 1);                    // fall back to raw string
            }
        }
        if (!pushedValue)
            lua_pushstring(Ls, snap[i].text);
        // stack: fn, id, status, value
        if (lua_pcall(Ls, 3, 0, 0) != LUA_OK) {
            L("[async] cb error: %s", lua_tostring(Ls, -1));
            lua_pop(Ls, 1);
        }
    }
}
