#include "hoi4_common.h"

// -+ C-side timer core
// Included BEFORE the hoi4_lib table (registers every/after/every_cancel/
// timers_count) and BEFORE the route-B block (whose frame dispatch calls
// timer_dispatch_locked).
//
// Design decisions (user-approved 2026-08-25):
//   - Core lives in C; Lua only registers callbacks. The temporary pure-Lua
//     dispatcher (timer_tick.lua, owned the "on_frame" global) is retired.
//   - Real-time base (GetTickCount64): fires while paused - feature for
//     agent automation; resolution bounded by frame rate (~14ms @70FPS).
//   - Missed beats are DROPPED (rearm = now + interval, never catch-up).
//   - Max 16 fires per frame; leftovers slide to the next frame.
//   - Registered-before-first-frame timers are PENDING and anchored to the
//     first visible frame (same fix the Lua prototype needed).
//   - Hot reload clears the whole table (registry_reset semantics); sources
//     re-register during the reload dofile.
//
// Slot aliasing guard: callbacks may cancel themselves/others and register
// new timers. A per-slot generation counter ensures post-callback bookkeeping
// (rearm/release) only touches the SAME logical timer that was dispatched.
#define TIMER_MAX           64
#define TIMER_MAX_PER_FRAME 16
#define TIMER_TAG_LEN       24

typedef struct {
    unsigned long long due_ms;    // absolute, GetTickCount64 domain
    unsigned long long delay_ms;  // original period/delay (rearm + anchoring)
    int                interval;  // 0 = one-shot
    int                pending;   // waiting for first visible frame
    int                active;
    int                generation;
    int                ref;       // luaL_ref handle; LUA_NOREF when free
    char               tag[TIMER_TAG_LEN];
} GameTimer;

static GameTimer g_m13Timers[TIMER_MAX];
static int      g_m13SeenFrame;   // 0 until the first dispatch call
static unsigned long long g_nowMs; // last-seen frame time (arm() reads it)

static void timer_release_locked(GameTimer *t)
{
    if (t->ref != LUA_NOREF) {
        luaL_unref(g_L, LUA_REGISTRYINDEX, t->ref);
        t->ref = LUA_NOREF;
    }
    t->active = 0;
    t->generation++;                 // kills stale post-callback bookkeeping
}

// Hot-reload hook: drop every timer (refs included). Called with g_luaLock
// held, next to registry_clear().
void timers_clear_locked(void)
{
    int n = 0;
    for (int i = 0; i < TIMER_MAX; i++)
        if (g_m13Timers[i].active) { timer_release_locked(&g_m13Timers[i]); n++; }
    if (n) L("[timer] cleared %d timer(s) for reload", n);
}

static int timer_arm(lua_State *Ls, int repeating)
{
    lua_Number ms = luaL_checknumber(Ls, 1);
    luaL_checktype(Ls, 2, LUA_TFUNCTION);
    const char *tag = luaL_optstring(Ls, 3, "");
    if (!(ms > 0.0)) luaL_argerror(Ls, 1, "ms must be > 0");
    if (ms > 1e12)   luaL_argerror(Ls, 1, "ms unreasonably large");

    GameTimer *t = NULL;
    for (int i = 0; i < TIMER_MAX; i++)
        if (!g_m13Timers[i].active) { t = &g_m13Timers[i]; break; }
    if (!t) return luaL_error(Ls, "timer table full (%d)", TIMER_MAX);

    t->delay_ms = (unsigned long long)ms;
    t->interval = repeating;
    t->pending  = !g_m13SeenFrame;             // no time base yet -> first frame
    t->due_ms   = g_m13SeenFrame ? g_nowMs + t->delay_ms : 0;
    memset(t->tag, 0, sizeof(t->tag));
    strncpy(t->tag, tag, sizeof(t->tag) - 1);

    lua_pushvalue(Ls, 2);                      // the fn
    t->ref = luaL_ref(Ls, LUA_REGISTRYINDEX);  // pops it
    t->active = 1;
    t->generation++;
    lua_pushinteger(Ls, (t - g_m13Timers) + 1); // id = slot index, 1-based
    return 1;
}

int hoi4_every(lua_State *Ls)        { return timer_arm(Ls, 1); }
int hoi4_after(lua_State *Ls)        { return timer_arm(Ls, 0); }

int hoi4_every_cancel(lua_State *Ls)
{
    lua_Integer id = luaL_checkinteger(Ls, 1);
    if (id >= 1 && id <= TIMER_MAX && g_m13Timers[id - 1].active) {
        timer_release_locked(&g_m13Timers[id - 1]);
        lua_pushboolean(Ls, 1);
    } else {
        lua_pushboolean(Ls, 0);
    }
    return 1;
}

int hoi4_timers_count(lua_State *Ls)
{
    int n = 0;
    for (int i = 0; i < TIMER_MAX; i++)
        if (g_m13Timers[i].active) n++;
    lua_pushinteger(Ls, n);
    return 1;
}

// Frame-side dispatch. Caller holds g_luaLock; g_L valid. `now` is the
// current frame's GetTickCount64 value.
void timer_dispatch_locked(unsigned long long now)
{
    g_nowMs = now;
    if (!g_m13SeenFrame) {
        g_m13SeenFrame = 1;
        for (int i = 0; i < TIMER_MAX; i++) {
            GameTimer *t = &g_m13Timers[i];
            if (t->active && t->pending) {
                t->pending = 0;
                t->due_ms  = now + t->delay_ms;
            }
        }
    }
    int fired = 0;
    for (int i = 0; i < TIMER_MAX; i++) {
        if (fired >= TIMER_MAX_PER_FRAME) break;   // rest slide a frame
        GameTimer *t = &g_m13Timers[i];
        if (!t->active || t->pending || now < t->due_ms) continue;
        fired++;
        int         gen      = t->generation;
        int         repeating = t->interval;
        const char *tag      = t->tag;
        lua_rawgeti(g_L, LUA_REGISTRYINDEX, t->ref);
        lua_pushinteger(g_L, (lua_Integer)now);
        if (lua_pcall(g_L, 1, 0, 0) != LUA_OK) {
            L("[timer] '%s' errored: %s (removed)",
              tag, lua_tostring(g_L, -1));
            lua_pop(g_L, 1);
            // same aliasing guard as the success path: the errored callback
            // may have cancelled itself and re-filled this slot with a NEW
            // timer — only release the slot if it still holds THIS one.
            if (t->generation == gen && t->active)
                timer_release_locked(t);
            continue;
        }
        // Bookkeeping ONLY if the slot still holds the same logical timer
        // (callback may have cancelled itself and/or filled the slot anew).
        if (t->generation != gen || !t->active) continue;
        if (repeating)
            t->due_ms = now + t->delay_ms;             // dropped-beats policy
        else
            timer_release_locked(t);
    }
}
