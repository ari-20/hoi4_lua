// hoi4_hook.cpp — vtable-slot hook facility (Tier 1). See hoi4_hook.h for the
// design rationale (why slot-swap and not body patching).
//
// Shape of the thing:
//   vt[slot] (engine .rdata qword)  ->  hk_thunk_N  ->  hk_dispatch(N, ...)
//                                                         |
//                                          chain_run(0, self, a1, a2, a3)
//                                                         |
//                       per-hook Lua callback, then (unless replaced)
//                       the next hook in the chain, then the REAL original
//
// The chain is walked only as far as Lua asks: a callback that never calls
// h.call_orig() ends the walk and its return value becomes the caller's result
// (REPLACE). A callback that calls h.call_orig() drives the rest of the chain
// itself, which is what makes "wrap and modify the result" possible.
#include "hoi4_common.h"
#include "hoi4_hook.h"
#include "hoi4_detour.h"
#include "hoi4_pdata.h"

// ---------------------------------------------------------------- state

// What an entry redirects. Both kinds share the chain engine, the Lua bridge,
// the audit trail and the id registry; they differ only in HOW the entry is
// taken over and WHAT the "original" is.
#define HK_KIND_VT  0   // vt[slot] data swap; original = the engine function
#define HK_KIND_FN  1   // function-body detour; original = the RX trampoline

typedef struct {
    int      kind;              // HK_KIND_*
    void    *slotAddr;          // VT: &vt[slot]     FN: the patched target
    void    *origFn;            // VT: engine fn     FN: trampoline (stolen + jump back)
    uint64_t vt;                // resolved absolute vtable address (VT only)
    int      slot;              // VT only; -1 for FN
    // ---- FN only ----
    uint32_t rva;               // target RVA (logs, audit, overlap checks)
    int      stolenLen;         // bytes lifted into the trampoline
    uint8_t  stolen[24];        // the original bytes (crash forensics; see §7)
    int      active;
    long     gen;
    int      inUse;             // 0 = entry available for reuse
    // Chain membership: indices into g_hooks, in registration order.
    // MUST be explicit. An earlier version derived the chain implicitly as
    // "g_hooks entries whose slotIdx == si, in ascending index order" while
    // hk_chain_run() indexed g_hooks with a counter starting at 0 — the two
    // disagree as soon as any OTHER slot's hook sits at a lower g_hooks index,
    // so the thunk dispatched to the WRONG slot's callback (symptom: install
    // slot A then slot B -> B never fires, A's callback runs instead).
    int      chain[HK_MAX_CHAIN];
    // per-slot stats (rolled up from the entries for hook_status)
    volatile long calls;
} HkSlot;

// ⚠ A slot descriptor must NEVER move once created. The thunk index is baked
// into the thunk function itself (hk_thunk_N -> hk_dispatch(N, ...)) and that
// thunk is written into the engine's vtable, so "descriptor index N" and
// "installed thunk N" are the same binding for the lifetime of the process.
// An earlier version compacted the array on removal (g_slots[si] =
// g_slots[last]); that silently re-pointed thunk_last at a stale descriptor.
// Freed entries are therefore REUSED IN PLACE via inUse, never shifted.
//
// origFn is deliberately NOT cleared when a slot is freed: a stale thunk that
// is still reachable (a call in flight across an unhook, or a forged vtable
// aimed at one of our thunks) then forwards to the ORIGINAL engine function —
// which is exactly what "unhooked" means — instead of calling a null pointer.

typedef struct {
    int      slotIdx;           // index into g_slots, -1 = free
    char     id[HK_ID_LEN];     // registry key the Lua fn is resolved from
    int      args;              // extra integer args (0..3); see the gate
    int      ret;               // HK_RET_*
    int      mode;              // HK_MODE_*
    long     gen;
    volatile long calls, luaCalls, forwarded, swallowed, errors;
    volatile long droppedOffThread;
    volatile long depthCapped;  // Tier 2 re-entry ceiling hit (see HK_MAX_DEPTH)
} HkEntry;

static HkSlot  g_slots[HK_MAX_SLOTS];
static HkEntry g_hooks[HK_MAX_HOOKS];
static volatile long g_hookCount;
static volatile long g_hookGen;
static volatile long g_detourCount;      // HK_KIND_FN entries (capacity log)

// Per-thread re-entry depth, one counter per slot. Tier 2 only: a detour
// target can recurse (or be re-entered through call_orig), and the thunk must
// not run Lua forever. Past HK_MAX_DEPTH the thunk forwards without Lua.
static __declspec(thread) unsigned char t_slotDepth[HK_MAX_SLOTS];

static DWORD g_mainTid;                  // engine main thread (see hook_note_main_thread)
static volatile LONG g_mainTidSet;

// ---------------------------------------------------------------- observe queue
// SPSC ring: producers (thunks, ANY thread) advance g_obsWrite; the single
// consumer (frame top, main thread) advances g_obsRead. The producer publishes
// by writing the slot BEFORE the counter increment is visible — the consumer
// only ever touches slots with index < g_obsWrite, and a slot is not reused
// until the consumer has advanced past it, so a torn read cannot happen.
//
// Each event carries its own hook id: between enqueue and drain the hook may
// have been unhooked and its table slot recycled, so the index alone is not a
// stable identity.
typedef struct {
    char     id[HK_ID_LEN];
    void    *self;
    uint64_t a1, a2, a3, ret;
} HkEvent;
static HkEvent g_obsQ[HK_OBSERVE_QUEUE];
static volatile long g_obsWrite;         // monotonic; producer side
static volatile long g_obsRead;          // monotonic; consumer side
static volatile long g_obsDropped;

// producer side — callable from any thread, never blocks
static void hk_obs_enqueue(const HkEntry *e, void *self,
                           uint64_t a1, uint64_t a2, uint64_t a3, uint64_t ret) {
    long t = InterlockedIncrement(&g_obsWrite) - 1;
    if (t - g_obsRead >= HK_OBSERVE_QUEUE) {   // consumer too far behind
        InterlockedIncrement(&g_obsDropped);
        return;
    }
    HkEvent *ev = &g_obsQ[t % HK_OBSERVE_QUEUE];
    strncpy(ev->id, e->id, HK_ID_LEN - 1);
    ev->id[HK_ID_LEN - 1] = 0;
    ev->self = self; ev->a1 = a1; ev->a2 = a2; ev->a3 = a3; ev->ret = ret;
}

// ---------------------------------------------------------------- helpers

// RVA vs absolute: image RVAs are < 0x10000000 for hoi4.exe (SizeOfImage
// 0x37EC000). Anything at/above that is treated as an absolute address.
#define HK_RVA_CEILING 0x10000000ull

static uint64_t hk_resolve(uint64_t v) {
    if (v < HK_RVA_CEILING) return (uint64_t)(uintptr_t)g_base + v;
    return v;
}

// is [addr] inside the hoi4.exe image (any section)?
static int hk_in_exe(uint64_t addr) {
    HMODULE hm = NULL;
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                            GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            (LPCWSTR)(uintptr_t)addr, &hm) || !hm)
        return 0;
    return hm == GetModuleHandleW(NULL);
}

static int hk_slot_index(void *slotAddr) {
    for (int i = 0; i < HK_MAX_SLOTS; i++)
        if (g_slots[i].inUse && g_slots[i].slotAddr == slotAddr) return i;
    return -1;
}

// first descriptor entry not in use, or -1 (entries are never moved — see HkSlot)
static int hk_slot_alloc(void) {
    for (int i = 0; i < HK_MAX_SLOTS; i++)
        if (!g_slots[i].inUse) return i;
    return -1;
}

// Is [addr] one of OUR thunks? Used to recognise "this slot is already hooked
// by this facility" so a second hook can be APPENDED to the chain. Without
// this, the "slot must hold engine code" gate would reject the append, because
// the current occupant is a bridge-DLL thunk rather than hoi4.exe code.
// (Defined after the thunk table — see hk_is_our_thunk below.)
static int hk_is_our_thunk(uint64_t addr);

static HkEntry *hk_find(const char *id) {
    int n = (int)g_hookCount;
    for (int i = 0; i < n; i++)
        if (g_hooks[i].slotIdx >= 0 && strcmp(g_hooks[i].id, id) == 0)
            return &g_hooks[i];
    return NULL;
}

// ---------------------------------------------------------------- registry
// Hook callbacks live in their own registry table so a reload that clears the
// effect/trigger tables cannot leave a stale closure reachable here (and vice
// versa). For TIER 1 the resolution is by id on every call, exactly like the
// bind table, so a reloaded script's new closure is what the still-patched slot
// reaches.
//
// This applies to BOTH tiers, including a Tier 2 detour: its callback is bound
// by id too, so a reloaded script's new closure is what the still-patched
// function body reaches. Verified live by tagging each load and watching the
// tag advance across reloads.
static void hk_reg_table(lua_State *Ls) {
    lua_getfield(Ls, LUA_REGISTRYINDEX, "m4_hooks");
    if (!lua_istable(Ls, -1)) {
        lua_pop(Ls, 1);
        lua_newtable(Ls);
        lua_pushvalue(Ls, -1);
        lua_setfield(Ls, LUA_REGISTRYINDEX, "m4_hooks");
    }
}
void hooks_registry_clear(lua_State *Ls) {
    lua_pushnil(Ls);
    lua_setfield(Ls, LUA_REGISTRYINDEX, "m4_hooks");
}

// ---------------------------------------------------------------- Lua VM entry
// A thunk may run on the main thread inside engine code that is NOT under our
// VM lock. Acquire with TryAcquire (never block the frame thread) and treat
// failure as "cannot run Lua" -> fail open. Re-entry (Lua -> engine -> hook on
// the same thread) is detected through g_luaOwner/g_luaDepth exactly as
// lua_lock does, so we never self-deadlock on an SRWLOCK.
static int hk_lua_enter(void) {
    DWORD tid = GetCurrentThreadId();
    if (g_luaOwner == tid && g_luaDepth > 0) { g_luaDepth++; return 1; }
    if (!TryAcquireSRWLockExclusive(&g_luaLock)) return 0;
    g_luaOwner = tid; g_luaDepth = 1;
    return 1;
}
static void hk_lua_leave(void) {
    DWORD tid = GetCurrentThreadId();
    if (g_luaOwner != tid || g_luaDepth == 0) return;
    if (--g_luaDepth > 0) return;
    g_luaOwner = 0;
    ReleaseSRWLockExclusive(&g_luaLock);
}

static int hk_may_run_lua(void) {
    if (!g_L || !g_initialized) return 0;
    if (!g_mainTidSet || GetCurrentThreadId() != g_mainTid) return 0;
    return 1;
}

// ---------------------------------------------------------------- chain

typedef struct {
    int      slotIdx;
    int      nextIdx;
    void    *self;
    uint64_t a1, a2, a3;
    uint64_t ret;
    int      calledCont;      // latch: the continuation already ran exactly once
} HkCtx;

static uint64_t hk_chain_run(int slotIdx, int idx, void *self,
                             uint64_t a1, uint64_t a2, uint64_t a3);
static uint64_t hk_chain_run_inner(int slotIdx, int idx, void *self,
                                   uint64_t a1, uint64_t a2, uint64_t a3);

// h.call_orig([a1[, a2[, a3]]]) — runs the REST of the chain (later hooks +
// the real original) synchronously and returns its result to Lua. Optional
// arguments override the values forwarded onward (the "modify arguments"
// ability); `this` is deliberately NOT overridable.
static int hk_lua_call_orig(lua_State *Ls) {
    HkCtx *ctx = (HkCtx *)lua_touserdata(Ls, lua_upvalueindex(1));
    if (!ctx) return luaL_error(Ls, "call_orig: no context");
    if (ctx->calledCont)
        return luaL_error(Ls, "call_orig: already called in this hook invocation "
                              "(calling it twice would run the original twice)");
    uint64_t a1 = ctx->a1, a2 = ctx->a2, a3 = ctx->a3;
    if (lua_gettop(Ls) >= 1 && !lua_isnil(Ls, 1)) a1 = (uint64_t)luaL_checkinteger(Ls, 1);
    if (lua_gettop(Ls) >= 2 && !lua_isnil(Ls, 2)) a2 = (uint64_t)luaL_checkinteger(Ls, 2);
    if (lua_gettop(Ls) >= 3 && !lua_isnil(Ls, 3)) a3 = (uint64_t)luaL_checkinteger(Ls, 3);
    ctx->calledCont = 1;
    ctx->ret = hk_chain_run(ctx->slotIdx, ctx->nextIdx, ctx->self, a1, a2, a3);
    lua_pushinteger(Ls, (lua_Integer)ctx->ret);
    return 1;
}

// build the `h` table handed to a hook callback
static void hk_push_ctx_table(lua_State *Ls, HkEntry *e, HkCtx *ctx, int allowOrig) {
    lua_createtable(Ls, 0, 10);
    lua_pushstring(Ls, e->id);          lua_setfield(Ls, -2, "id");
    lua_pushinteger(Ls, (lua_Integer)g_slots[ctx->slotIdx].vt);
    lua_setfield(Ls, -2, "vt");
    lua_pushinteger(Ls, ctx->slotIdx >= 0 ? g_slots[ctx->slotIdx].slot : -1);
    lua_setfield(Ls, -2, "slot");
    // `this` is a NUMBER, not lightuserdata: every other address this framework
    // hands to Lua is a number (objects_v2, scope_country, read_*), and
    // lightuserdata cannot be used in arithmetic — a documented pitfall that
    // would make `ctx.this + 88` fail with "attempt to perform arithmetic on a
    // userdata value".
    lua_pushinteger(Ls, (lua_Integer)(uintptr_t)ctx->self);
    lua_setfield(Ls, -2, "this");
    lua_pushinteger(Ls, (lua_Integer)ctx->a1); lua_setfield(Ls, -2, "a1");
    lua_pushinteger(Ls, (lua_Integer)ctx->a2); lua_setfield(Ls, -2, "a2");
    lua_pushinteger(Ls, (lua_Integer)ctx->a3); lua_setfield(Ls, -2, "a3");
    lua_pushstring(Ls, e->mode == HK_MODE_OBSERVE ? "observe" : "sync");
    lua_setfield(Ls, -2, "mode");
    if (allowOrig) {
        lua_pushlightuserdata(Ls, ctx);
        lua_pushcclosure(Ls, hk_lua_call_orig, 1);
        lua_setfield(Ls, -2, "call_orig");
    }
}

// resolve the callback by id; leaves it on the stack (or nil)
static int hk_push_callback(lua_State *Ls, const char *id) {
    hk_reg_table(Ls);
    lua_getfield(Ls, -1, id);
    lua_remove(Ls, -2);
    return lua_isfunction(Ls, -1);
}

// Run one hook's Lua callback. Returns HK_ACT_*, and on HK_ACT_REPLACE sets
// *outRet. ctx->calledCont tells the caller whether the continuation already ran.
static int hk_run_one(lua_State *Ls, HkEntry *e, HkCtx *ctx, uint64_t *outRet) {
    if (!hk_push_callback(Ls, e->id)) {
        lua_pop(Ls, 1);
        // The script that owned this hook is gone (deleted / renamed / not yet
        // re-registered after a reload). FAIL OPEN — forward to the original.
        // NOTE: this is deliberately the OPPOSITE of the effect execute slot,
        // where a bind miss SKIPS the original (forwarding there would run
        // set_global_flag(<our token>) and pollute the world). A hook is an
        // INTERCEPT, not a replacement: with the mod gone the engine must
        // behave as if the hook were never installed.
        e->errors++;
        static volatile long s_lastMissLog;
        long now = (long)(GetTickCount64() / 1000);
        if (now != s_lastMissLog) {
            s_lastMissLog = now;
            L("[hook] callback '%s' missing (script not registered?) — forwarding original", e->id);
        }
        return HK_ACT_FORWARD;
    }
    hk_push_ctx_table(Ls, e, ctx, 1);
    e->luaCalls++;
    if (lua_pcall(Ls, 1, 1, 0) != LUA_OK) {
        const char *err = lua_tostring(Ls, -1);
        L("[hook] error in '%s': %s", e->id, err ? err : "(non-string error)");
        lua_pop(Ls, 1);
        e->errors++;
        return HK_ACT_ERROR;
    }
    int isnum = lua_isnumber(Ls, -1);
    *outRet = isnum ? (uint64_t)lua_tointeger(Ls, -1) : 0;
    lua_pop(Ls, 1);
    if (ctx->calledCont) {
        // The continuation already ran. A numeric return is the value the
        // caller sees (wrap-and-modify); a nil return means "pass the
        // original's result through unchanged".
        if (isnum) { e->swallowed++; return HK_ACT_REPLACE; }
        *outRet = ctx->ret;
        e->swallowed++;
        return HK_ACT_REPLACE;
    }
    e->swallowed++;
    return HK_ACT_REPLACE;          // no call_orig -> pure replacement
}

static uint64_t hk_chain_run_inner(int slotIdx, int idx, void *self,
                                   uint64_t a1, uint64_t a2, uint64_t a3) {
    HkSlot *s = &g_slots[slotIdx];
    // Fail SAFE, not open. A thunk can be reached while its slot is FREE (a
    // call in flight across an unhook, or a forged vtable aimed at one of our
    // thunks — see hook_orig_for_thunk). Forwarding to the original is the
    // right answer there: "unhooked" MEANS "behaves like the original". origFn
    // survives slot release precisely so this path never dereferences a null
    // target; only a never-initialised descriptor (origFn == NULL) returns 0.
    if (!s->origFn) return 0;
    if (idx >= s->active) {        // chain exhausted: the real original
        typedef uint64_t (__fastcall *Fn_t)(void *, uint64_t, uint64_t, uint64_t);
        return ((Fn_t)s->origFn)(self, a1, a2, a3);
    }

    // s->chain[] maps chain position -> g_hooks index (they differ whenever
    // another slot's hook occupies a lower g_hooks index — see HkSlot).
    HkEntry *e = &g_hooks[s->chain[idx]];
    InterlockedIncrement(&e->calls);
    InterlockedIncrement(&s->calls);

    if (e->mode == HK_MODE_OBSERVE) {
        // Observe hooks never run inline and never influence the result: the
        // original runs NOW and the event (with its return value) is queued for
        // frame top. This is why observe is safe on any thread.
        typedef uint64_t (__fastcall *Fn_t)(void *, uint64_t, uint64_t, uint64_t);
        uint64_t r = hk_chain_run(slotIdx, idx + 1, self, a1, a2, a3);
        hk_obs_enqueue(e, self, a1, a2, a3, r);
        return r;
    }

    if (!hk_may_run_lua()) {
        // SYNC hook invoked off the main thread (or the VM is not up). The
        // honest answer is "cannot run Lua here" -> fail open, and make it
        // VISIBLE: this is the one silent-degradation path in the facility.
        InterlockedIncrement(&e->droppedOffThread);
        static volatile long s_lastOffLog;
        long now = (long)(GetTickCount64() / 1000);
        if (now != s_lastOffLog) {
            s_lastOffLog = now;
            L("[hook] '%s' sync hook hit on non-main thread (tid=%lu, main=%lu) — "
              "forwarding without running Lua", e->id,
              GetCurrentThreadId(), (unsigned long)g_mainTid);
        }
        return hk_chain_run(slotIdx, idx + 1, self, a1, a2, a3);
    }

    lua_State *Ls = g_L;
    if (!hk_lua_enter()) {
        InterlockedIncrement(&e->droppedOffThread);
        return hk_chain_run(slotIdx, idx + 1, self, a1, a2, a3);
    }

    HkCtx ctx;
    ctx.slotIdx = slotIdx; ctx.nextIdx = idx + 1; ctx.self = self;
    ctx.a1 = a1; ctx.a2 = a2; ctx.a3 = a3; ctx.ret = 0; ctx.calledCont = 0;

    int before = lua_gettop(Ls);
    uint64_t ret = 0;
    int act = hk_run_one(Ls, e, &ctx, &ret);
    lua_settop(Ls, before);        // balance no matter what the callback did

    if (act == HK_ACT_ERROR) {
        // A Lua error must not swallow the engine call. If the callback had
        // already driven the continuation we cannot run it again — use its
        // result; otherwise forward.
        ret = ctx.calledCont ? ctx.ret : hk_chain_run(slotIdx, idx + 1, self, a1, a2, a3);
        if (!ctx.calledCont) InterlockedIncrement(&e->forwarded);
    } else if (ctx.calledCont) {
        // continuation ran inside call_orig
    } else {
        // pure replacement — nothing more to run
    }

    hk_lua_leave();
    return ret;
}

// Chain entry point. Tier 2 needs one thing the inner walker cannot do on its
// own: bound its own re-entry. A detour target can recurse (a tree walk, or the
// mod driving the original through call_orig and the original calling itself),
// and every level re-enters the thunk. Past HK_MAX_DEPTH we stop running Lua
// and just forward, so a runaway chain degrades to the original's behaviour
// instead of exhausting the stack. VT slots are exempt: recursion through a
// vtable is the engine's own business and carries no equivalent semantics.
static uint64_t hk_chain_run(int slotIdx, int idx, void *self,
                             uint64_t a1, uint64_t a2, uint64_t a3) {
    HkSlot *s = &g_slots[slotIdx];
    if (s->kind != HK_KIND_FN || idx != 0)
        return hk_chain_run_inner(slotIdx, idx, self, a1, a2, a3);
    if (t_slotDepth[slotIdx] >= HK_MAX_DEPTH) {
        HkEntry *e = &g_hooks[s->chain[idx]];
        InterlockedIncrement(&e->depthCapped);
        return hk_chain_run_inner(slotIdx, idx + 1, self, a1, a2, a3);
    }
    t_slotDepth[slotIdx]++;
    uint64_t r = hk_chain_run_inner(slotIdx, idx, self, a1, a2, a3);
    t_slotDepth[slotIdx]--;
    return r;
}

// ---------------------------------------------------------------- thunks
// Uniform shape: (this, a1, a2, a3) -> u64. On x64 this is safe for any target
// taking <= 4 integer args (MSVC fastcall register slots rcx/rdx/r8/r9); extra
// registers we pass are simply ignored by a callee that declares fewer.
// Targets needing MORE than 4 integer args, a floating-point return (xmm0), or
// a by-value struct return (hidden sret pointer) are REFUSED at install time —
// see the gate in hoi4_hook_vt. A uniform C thunk cannot forward those, and a
// thunk that silently drops stack arguments would corrupt the call.
static uint64_t hk_dispatch(int slotIdx, void *self,
                            uint64_t a1, uint64_t a2, uint64_t a3) {
    return hk_chain_run(slotIdx, 0, self, a1, a2, a3);
}

#define HK_THUNK(N)                                                            \
    static uint64_t __fastcall hk_thunk_##N(void *self, uint64_t a1,           \
                                            uint64_t a2, uint64_t a3) {        \
        return hk_dispatch(N, self, a1, a2, a3);                               \
    }
HK_THUNK(0)  HK_THUNK(1)  HK_THUNK(2)  HK_THUNK(3)  HK_THUNK(4)  HK_THUNK(5)
HK_THUNK(6)  HK_THUNK(7)  HK_THUNK(8)  HK_THUNK(9)  HK_THUNK(10) HK_THUNK(11)
HK_THUNK(12) HK_THUNK(13) HK_THUNK(14) HK_THUNK(15) HK_THUNK(16) HK_THUNK(17)
HK_THUNK(18) HK_THUNK(19) HK_THUNK(20) HK_THUNK(21) HK_THUNK(22) HK_THUNK(23)
HK_THUNK(24) HK_THUNK(25) HK_THUNK(26) HK_THUNK(27) HK_THUNK(28) HK_THUNK(29)
HK_THUNK(30) HK_THUNK(31)

static void *const g_thunks[HK_MAX_SLOTS] = {
    (void *)hk_thunk_0,  (void *)hk_thunk_1,  (void *)hk_thunk_2,  (void *)hk_thunk_3,
    (void *)hk_thunk_4,  (void *)hk_thunk_5,  (void *)hk_thunk_6,  (void *)hk_thunk_7,
    (void *)hk_thunk_8,  (void *)hk_thunk_9,  (void *)hk_thunk_10, (void *)hk_thunk_11,
    (void *)hk_thunk_12, (void *)hk_thunk_13, (void *)hk_thunk_14, (void *)hk_thunk_15,
    (void *)hk_thunk_16, (void *)hk_thunk_17, (void *)hk_thunk_18, (void *)hk_thunk_19,
    (void *)hk_thunk_20, (void *)hk_thunk_21, (void *)hk_thunk_22, (void *)hk_thunk_23,
    (void *)hk_thunk_24, (void *)hk_thunk_25, (void *)hk_thunk_26, (void *)hk_thunk_27,
    (void *)hk_thunk_28, (void *)hk_thunk_29, (void *)hk_thunk_30, (void *)hk_thunk_31,
};

// see the forward declaration above
static int hk_is_our_thunk(uint64_t addr) {
    for (int i = 0; i < HK_MAX_SLOTS; i++)
        if ((uint64_t)(uintptr_t)g_thunks[i] == addr) return 1;
    return 0;
}

// ---------------------------------------------------------------- patch/unpatch

static int hk_write_slot(void *slotAddr, void *value) {
    DWORD op = 0;
    if (!VirtualProtect(slotAddr, sizeof(void *), PAGE_READWRITE, &op)) {
        L("[hook] VirtualProtect(%p) failed: %lu", slotAddr, GetLastError());
        return 0;
    }
    *(void **)slotAddr = value;
    DWORD tmp = 0;
    VirtualProtect(slotAddr, sizeof(void *), op, &tmp);
    FlushInstructionCache(GetCurrentProcess(), slotAddr, sizeof(void *));
    return 1;
}

// ---------------------------------------------------------------- install

// Validate + patch. On success the slot index is returned (>=0) and *outErr is
// NULL; on refusal -1 is returned and *outErr points at a static reason string.
// Every outcome — install, refusal, re-install — writes one audit line, so a
// code redirect is never silent.
static int hk_install(lua_State *Ls, uint64_t vt, int slot, const char *id,
                      int args, int ret, int mode, const char **outErr) {
#define HK_REFUSE(msg) do { *outErr = (msg); audit_hook(Ls, "deny", id, vt, slot, (msg)); \
                            return -1; } while (0)
    if (!g_base) HK_REFUSE("no game base (offsets not loaded)");
    if (slot < 0 || slot >= HK_MAX_SLOT_INDEX)
        HK_REFUSE("slot index out of range (0..511)");
    if (args < 0 || args > 3)
        HK_REFUSE("args must be 0..3 — a uniform C thunk cannot forward a 5th "
                  "integer argument (it lives on the stack); see hoi4_hook.h");
    if (ret != HK_RET_U64 && ret != HK_RET_VOID && ret != HK_RET_BOOL)
        HK_REFUSE("ret must be u64/void/bool (float returns live in xmm0 and a "
                  "by-value struct return uses a hidden sret pointer — neither "
                  "is supported by this thunk shape)");
    if (mode != HK_MODE_SYNC && mode != HK_MODE_OBSERVE)
        HK_REFUSE("mode must be sync/observe");

    uint64_t vta = hk_resolve(vt);
    if (!hk_in_exe(vta)) HK_REFUSE("vtable address is not inside hoi4.exe");

    // Snapshot the slot BEFORE any early return, so the mandatory audit line
    // below always has a target to report.
    void *slotAddr = (void *)(uintptr_t)(vta + (uint64_t)slot * 8);
    if (!hk_in_exe((uint64_t)(uintptr_t)slotAddr))
        HK_REFUSE("vt+slot*8 falls outside the game image");

    // the slot must be DATA (a .rdata qword). If it is already executable we
    // were handed a function address, not a vtable.
    if (memgate_exec_ok((uint64_t)(uintptr_t)slotAddr))
        HK_REFUSE("target is executable code, not a vtable slot");

    // the bridge's own frame hook owns this slot
    if (slotAddr == (void *)(g_base + RVA_INGAME_IDLER_VTBL_SLOT4))
        HK_REFUSE("slot is reserved by the bridge (idler frame hook)");

    // IDEMPOTENT re-install — checked BEFORE inspecting the slot contents,
    // because on a re-install the slot already holds OUR thunk (which lives in
    // the bridge DLL, not hoi4.exe, so the "must hold engine code" gate below
    // would wrongly reject it). This is the normal hot-reload path: the script
    // re-runs, calls hoi4.hook_vt with the same id, and only the callback
    // changes (the caller re-registers it before calling here). The patch
    // itself stays exactly as it was — re-patching would open a pointless
    // window of "callback missing".
    {
        HkEntry *ex = hk_find(id);
        if (ex) {
            HkSlot *es = &g_slots[ex->slotIdx];
            if (es->vt != vta || es->slot != slot)
                HK_REFUSE("id already registered on a DIFFERENT slot "
                          "(unhook it first)");
            ex->args = args; ex->ret = ret; ex->mode = mode; ex->gen = g_hookGen;
            L("[hook] id='%s' re-registered (idempotent, patch untouched)", id);
            audit_hook(Ls, "reinstall", id, vt, slot, "idempotent re-register");
            *outErr = NULL;
            return ex->slotIdx;
        }
    }

    void *cur = NULL;
    __try { cur = *(void **)slotAddr; }
    __except (EXCEPTION_EXECUTE_HANDLER) { HK_REFUSE("unreadable slot"); }
    if (!cur) HK_REFUSE("slot is null (no implementation to wrap)");

    uint64_t curAbs = (uint64_t)(uintptr_t)cur;
    // A slot that already holds OUR thunk means this facility owns it: the
    // engine target was validated when the FIRST hook went in, and `origFn` is
    // recorded on the slot. This is the append-to-chain path (two mods hooking
    // the same method), so skip the engine-code checks below.
    if (!hk_is_our_thunk(curAbs)) {
        if (!memgate_exec_ok(curAbs))
            HK_REFUSE("slot does not hold engine code (foreign or already patched)");

        // Base-class filler: hooking it intercepts NOTHING and reports no error
        // at runtime, which is the single most confusing way this facility
        // could fail.
        if (curAbs == (uint64_t)(uintptr_t)(g_base + RVA_PURECALL))
            HK_REFUSE("slot holds _purecall — this is a BASE-class vtable; hook "
                      "the DERIVED class's vtable (see hoi4_hook.h on granularity)");
        if (curAbs == (uint64_t)(uintptr_t)(g_base + RVA_GUARD_NOP))
            HK_REFUSE("slot holds _guard_check_icall_nop (CFG no-op stub) — not "
                      "a real implementation");
    }

    if ((int)g_hookCount >= HK_MAX_HOOKS) HK_REFUSE("hook table full");

    int si = hk_slot_index(slotAddr);
    int fresh = 0;
    if (si < 0) {
        // Reuse a freed descriptor IN PLACE (never compact — the thunk index is
        // baked into the installed thunk, see HkSlot).
        si = hk_slot_alloc();
        if (si < 0) HK_REFUSE("slot table full (too many distinct hooked slots)");
        g_slots[si].kind = HK_KIND_VT;
        g_slots[si].slotAddr = slotAddr;
        g_slots[si].origFn = cur;
        g_slots[si].vt = vta;
        g_slots[si].slot = slot;
        g_slots[si].rva = 0;
        g_slots[si].stolenLen = 0;
        g_slots[si].active = 0;
        g_slots[si].gen = g_hookGen;
        g_slots[si].calls = 0;
        g_slots[si].inUse = 1;
        fresh = 1;
    }
    if (g_slots[si].active >= HK_MAX_CHAIN) HK_REFUSE("chain full (max 4 hooks)");

    // Append to the chain BEFORE patching, so the thunk can never observe a
    // chain that does not yet contain its own entry.
    long hi = InterlockedIncrement(&g_hookCount) - 1;
    if (hi >= HK_MAX_HOOKS) { InterlockedDecrement(&g_hookCount); HK_REFUSE("hook table full"); }
    HkEntry *e = &g_hooks[hi];
    memset(e, 0, sizeof(*e));
    e->slotIdx = si;
    strncpy(e->id, id, HK_ID_LEN - 1);
    e->args = args; e->ret = ret; e->mode = mode; e->gen = g_hookGen;
    g_slots[si].chain[g_slots[si].active] = (int)hi;   // record membership FIRST
    g_slots[si].active++;

    if (fresh) {
        if (!hk_write_slot(slotAddr, g_thunks[si])) {
            g_slots[si].active = 0;            // also drops the chain entry
            g_slots[si].inUse = 0;
            g_slots[si].inUse = 0;
            g_slots[si].slotAddr = NULL;
            e->slotIdx = -1;
            InterlockedDecrement(&g_hookCount);
            HK_REFUSE("VirtualProtect/write of the vtable slot failed");
        }
        L("[hook] slot %d @ vt+%d (0x%llx): orig=%p -> thunk_%d "
          "(vt now patched, engine calls redirect)",
          slot, slot * 8, (unsigned long long)vta, cur, si);
    }
    L("[hook] installed id='%s' mode=%s args=%d ret=%d (chain depth %d on slot %d)",
      id, mode == HK_MODE_OBSERVE ? "observe" : "sync", args, ret,
      g_slots[si].active, si);
    {
        char d[96];
        snprintf(d, sizeof(d), "mode=%s args=%d ret=%d depth=%d",
                 mode == HK_MODE_OBSERVE ? "observe" : "sync", args, ret,
                 g_slots[si].active);
        audit_hook(Ls, "install", id, vt, slot, d);
    }
    *outErr = NULL;
    return si;
#undef HK_REFUSE
}

static int hk_uninstall(lua_State *Ls, const char *id, const char **outErr) {
    HkEntry *e = hk_find(id);
    if (!e) {
        *outErr = "unknown hook id";
        audit_hook(Ls, "deny", id, 0, 0, "unhook: unknown id");
        return 0;
    }
    // Tier 2 has no uninstall, and the reason is structural rather than a
    // missing feature: writing the original bytes back races every other
    // thread exactly like installing does (a thread parked mid-patch would
    // resume into the middle of an instruction). See DETOUR_DESIGN.md §3.3.
    if (g_slots[e->slotIdx].kind == HK_KIND_FN) {
        *outErr = "detour targets cannot be unhooked — the entry patch is "
                  "permanent by design; re-register the same id to change the "
                  "callback, or restart the game to change the target";
        audit_hook(Ls, "deny", id, 0, -1, "unhook refused: Tier 2 is permanent");
        return 0;
    }
    int si = e->slotIdx;
    HkSlot *s = &g_slots[si];
    int slotNo = s->slot;
    uint64_t vtv = s->vt;

    // Remove this hook from g_hooks and repair every slot's chain indices.
    // g_hooks is compacted, so all indices above `removed` shift down by one;
    // and the removed entry must be spliced out of ITS slot's chain. Doing this
    // by index (not by pointer) is what keeps the chains valid — see HkSlot.
    int removed = (int)(e - g_hooks);
    {
        HkEntry tmp[HK_MAX_HOOKS];
        int n = 0;
        for (int i = 0; i < (int)g_hookCount; i++) {
            if (i == removed) continue;
            if (g_hooks[i].slotIdx < 0) continue;
            tmp[n++] = g_hooks[i];
        }
        memcpy(g_hooks, tmp, sizeof(HkEntry) * (size_t)n);
        g_hookCount = n;
    }
    for (int i = 0; i < HK_MAX_SLOTS; i++) {
        if (!g_slots[i].inUse) continue;
        int w = 0;
        for (int k = 0; k < g_slots[i].active; k++) {
            int c = g_slots[i].chain[k];
            if (c == removed) continue;              // this hook is gone
            g_slots[i].chain[w++] = (c > removed) ? c - 1 : c;
        }
        g_slots[i].active = w;
    }

    int restored = 0;
    if (s->active == 0) {
        // restore the engine qword and free the descriptor IN PLACE
        // (origFn is kept — a stale thunk must still forward safely)
        if (!hk_write_slot(s->slotAddr, s->origFn))
            L("[hook] WARNING: failed to restore original at %p", s->slotAddr);
        else
            L("[hook] slot %d restored: orig %p back in place", slotNo, s->origFn);
        restored = 1;
        s->inUse = 0;
        s->slotAddr = NULL;
        s->active = 0;
    }
    L("[hook] uninstalled id='%s' (slot %d, depth now %d)", id, slotNo,
      restored ? 0 : s->active);
    // The detail must reflect what ACTUALLY happened: removing one hook from a
    // chain leaves the slot patched (the remaining hooks still run), so
    // claiming "restored" there would be a false record.
    if (restored)
        audit_hook(Ls, "uninstall", id, vtv, slotNo, "slot restored to original");
    else {
        char d[64];
        snprintf(d, sizeof(d), "chain depth now %d (slot still patched)",
                 s->active);
        audit_hook(Ls, "uninstall", id, vtv, slotNo, d);
    }
    *outErr = NULL;
    return 1;
}

// ---------------------------------------------------------------- Tier 2 (detour)

// Everything the probe reports, and everything the install gates decide on.
typedef struct {
    int         ok;              // installable (G1..G4 and no window overlap)
    uint32_t    rva;
    uint32_t    funcStart, funcEnd;
    int         isFuncStart;
    int         inWindow;        // overlaps an existing patch window (G5/G6)
    int         stolenLen;       // 0 = not stealable
    uint8_t     stolen[24];
    const char *reason;          // first failing gate, or NULL when ok
} HkProbe;

// Gates G1, G2, G4, G3 and the window-overlap check, in that order.
// READ-ONLY: not one byte is written, which is why hoi4.detour_probe is
// allowed at any time while hoi4.detour is restricted to the first load.
static void hk_probe_fill(uint64_t target, HkProbe *p) {
    memset(p, 0, sizeof(*p));
    if (!g_base) { p->reason = "no game base (offsets not loaded)"; return; }
    uint64_t lo = pdata_img_lo(), hi = pdata_img_hi();
    if (!target || target < lo || target >= hi) {
        p->reason = "address is outside the hoi4.exe image";
        return;
    }
    p->rva = (uint32_t)(target - lo);
    if (!memgate_exec_ok(target)) {
        p->reason = "address is not in an executable section of hoi4.exe";
        return;
    }
    if (!pdata_build() || pdata_count() == 0) {
        p->reason = ".pdata unavailable — function boundaries cannot be verified";
        return;
    }
    p->funcStart = pdata_func(p->rva);
    p->funcEnd   = pdata_end(p->rva);
    p->isFuncStart = (p->funcStart == p->rva);
    if (!p->isFuncStart) {
        p->reason = "not a function start (.pdata) — a detour must patch the "
                    "function entry, never the middle of an instruction stream";
        return;
    }
    {
        const char *why = NULL;
        int n = detour_steal_len((const uint8_t *)(uintptr_t)target,
                                 DT_ENTRY_PATCH_BYTES, 24, &why);
        if (!n) { p->reason = why ? why : "prologue not cleanly stealable"; return; }
        // A 12-byte steal from a short function would eat the NEXT function's
        // first bytes — the trampoline would then replay another function's
        // prologue.
        if (p->funcEnd && p->rva + (uint32_t)n > p->funcEnd) {
            p->reason = "the stolen prologue would run past the end of this "
                        "function into the next one";
            return;
        }
        __try { memcpy(p->stolen, (const void *)(uintptr_t)target, (size_t)n); }
        __except (EXCEPTION_EXECUTE_HANDLER) {
            p->reason = "target memory unreadable";
            return;
        }
        p->stolenLen = n;
    }
    {
        uint64_t wl[DT_MAX_WINDOWS_REPORT], wh[DT_MAX_WINDOWS_REPORT];
        int n = detour_windows(wl, wh, DT_MAX_WINDOWS_REPORT);
        for (int i = 0; i < n && i < DT_MAX_WINDOWS_REPORT; i++)
            if (target < wh[i] && target + (uint64_t)p->stolenLen > wl[i]) {
                p->inWindow = 1;
                p->reason = "overlaps a byte window this process has already "
                            "patched (a framework detour, or another detour)";
                return;
            }
    }
    p->ok = 1;
}

// An existing Tier 2 slot that already patches this target. A second detour on
// the same target must APPEND to that slot's chain rather than patch again:
// the second patch would steal our own entry patch (`48 B8 .. FF E0`) and
// build a trampoline that jumps into nonsense.
static int hk_fn_slot_for(uint64_t target) {
    for (int i = 0; i < HK_MAX_SLOTS; i++)
        if (g_slots[i].inUse && g_slots[i].kind == HK_KIND_FN &&
            (uint64_t)(uintptr_t)g_slots[i].slotAddr == target)
            return i;
    return -1;
}

static void hk_hex(const uint8_t *b, int n, char *out, size_t cap) {
    size_t k = 0;
    for (int i = 0; i < n && k + 3 < cap; i++)
        k += (size_t)snprintf(out + k, cap - k, "%02X", b[i]);
    out[k < cap ? k : cap - 1] = 0;
}

static int hk_install_fn(lua_State *Ls, uint64_t target, const char *id,
                         int args, int ret, int mode, const char **outErr) {
#define HK_FN_REFUSE(msg) do { *outErr = (msg); \
        audit_hook(Ls, "deny", id, target, -1, (msg)); return -1; } while (0)
    if (args < 0 || args > 3)
        HK_FN_REFUSE("args must be 0..3 — a uniform C thunk cannot forward a "
                     "5th integer argument (it lives on the stack)");
    if (ret != HK_RET_U64 && ret != HK_RET_VOID && ret != HK_RET_BOOL)
        HK_FN_REFUSE("ret must be u64/void/bool (a float return lives in xmm0 "
                     "and a by-value struct return uses a hidden sret pointer — "
                     "neither survives this thunk shape)");
    if (mode != HK_MODE_SYNC && mode != HK_MODE_OBSERVE)
        HK_FN_REFUSE("mode must be sync/observe");

    // ---- re-register on the same target: idempotent ----
    // The patch stays exactly as it is (re-patching would open a pointless
    // window of "callback missing"); only the declared shape is refreshed. The
    // callback itself is resolved by id on every call, so a reloaded script's
    // NEW closure is what the still-patched entry reaches — verified live by
    // tagging each load and watching the tag advance across reloads.
    {
        HkEntry *ex = hk_find(id);
        if (ex) {
            HkSlot *es = &g_slots[ex->slotIdx];
            if (es->kind != HK_KIND_FN ||
                (uint64_t)(uintptr_t)es->slotAddr != target)
                HK_FN_REFUSE("id already registered on a DIFFERENT target "
                             "(detour targets are permanent — pick a new id, or "
                             "restart the game)");
            ex->args = args; ex->ret = ret; ex->mode = mode; ex->gen = g_hookGen;
            L("[detour] id='%s' re-registered (idempotent, patch untouched)", id);
            audit_hook(Ls, "reinstall", id, target, -1, "idempotent re-register");
            *outErr = NULL;
            return ex->slotIdx;
        }
    }

    // ---- G0: only during the process's FIRST script load ----
    // Later loads (frame-top hot reload, session switch) run with the game
    // live: AI ticking, workers busy. That is not a window to rewrite code.
    if (!in_first_script_load())
        HK_FN_REFUSE("hoi4.detour only works during the game's first script "
                     "load — a NEW detour target needs a game restart (you can "
                     "still re-register the same id to change the callback)");

    // ---- G1..G6: eligibility (read-only) ----
    HkProbe pr;
    hk_probe_fill(target, &pr);
    if (!pr.ok) HK_FN_REFUSE(pr.reason ? pr.reason : "target not eligible");

    int si = hk_fn_slot_for(target);
    int fresh = (si < 0);
    if (fresh) {
        if ((int)g_detourCount >= HK_MAX_DETOURS)
            HK_FN_REFUSE("detour table full (HK_MAX_DETOURS)");
        si = hk_slot_alloc();
        if (si < 0) HK_FN_REFUSE("slot table full (too many distinct targets)");
    } else if (g_slots[si].active >= HK_MAX_CHAIN) {
        HK_FN_REFUSE("chain full (max 4 hooks on this target)");
    }
    if ((int)g_hookCount >= HK_MAX_HOOKS) HK_FN_REFUSE("hook table full");

    // ---- reserve the chain entry BEFORE patching, so a thunk that goes live
    // can never observe a chain that lacks its own entry ----
    long hi = InterlockedIncrement(&g_hookCount) - 1;
    if (hi >= HK_MAX_HOOKS) {
        InterlockedDecrement(&g_hookCount);
        HK_FN_REFUSE("hook table full");
    }

    void *tramp = NULL;
    if (fresh) {
        tramp = detour_make_trampoline((uint8_t *)(uintptr_t)target,
                                       pr.stolenLen);
        if (!tramp) {
            InterlockedDecrement(&g_hookCount);
            HK_FN_REFUSE("trampoline allocation failed");
        }
        // Publish the descriptor BEFORE the patch. A thunk that becomes
        // reachable the instant the entry is rewritten must already find a
        // valid origFn (the trampoline) — with active==0 it simply forwards to
        // the original, which is exactly the pre-hook behaviour.
        g_slots[si].kind = HK_KIND_FN;
        g_slots[si].slotAddr = (void *)(uintptr_t)target;
        g_slots[si].origFn = tramp;
        g_slots[si].vt = 0;
        g_slots[si].slot = -1;
        g_slots[si].rva = pr.rva;
        g_slots[si].stolenLen = pr.stolenLen;
        memcpy(g_slots[si].stolen, pr.stolen, (size_t)pr.stolenLen);
        g_slots[si].active = 0;
        g_slots[si].gen = g_hookGen;
        g_slots[si].calls = 0;
        g_slots[si].inUse = 1;

        // ---- G10: the suspend-and-verify commit ----
        int nthreads = 0;
        unsigned long hit = 0;
        if (!detour_patch_entry((uint8_t *)(uintptr_t)target, pr.stolenLen,
                                g_thunks[si], &nthreads, &hit)) {
            g_slots[si].inUse = 0;
            g_slots[si].origFn = NULL;
            g_slots[si].slotAddr = NULL;
            VirtualFree(tramp, 0, MEM_RELEASE);
            InterlockedDecrement(&g_hookCount);
            if (hit)
                HK_FN_REFUSE("a thread is executing inside the target right now "
                             "— refused, nothing written (restart the game and "
                             "retry)");
            HK_FN_REFUSE("could not suspend and verify every thread — refused, "
                         "nothing written");
        }
        InterlockedIncrement(&g_detourCount);
        {
            char hex[3 * 24 + 1];
            hk_hex(pr.stolen, pr.stolenLen, hex, sizeof(hex));
            // The stolen bytes are logged because a bad detour surfaces as a
            // wild jump whose only evidence is the crash RIP. Target address
            // plus these bytes let a dump be traced back to THIS install — and
            // unlike Tier 1 there is no uninstall to undo it.
            L("[detour] PATCHED rva=%X -> thunk_%d stolen=%d [%s] trampoline=%p "
              "threads_verified=%d", pr.rva, si, pr.stolenLen, hex, tramp,
              nthreads);
        }
    }

    HkEntry *e = &g_hooks[hi];
    memset(e, 0, sizeof(*e));
    e->slotIdx = si;
    strncpy(e->id, id, HK_ID_LEN - 1);
    e->args = args; e->ret = ret; e->mode = mode; e->gen = g_hookGen;
    g_slots[si].chain[g_slots[si].active] = (int)hi;
    g_slots[si].active++;

    L("[detour] installed id='%s' mode=%s args=%d ret=%d rva=%X (chain depth %d)",
      id, mode == HK_MODE_OBSERVE ? "observe" : "sync", args, ret, pr.rva,
      g_slots[si].active);
    {
        char d[128];
        snprintf(d, sizeof(d), "mode=%s args=%d ret=%d depth=%d rva=%X stolen=%d",
                 mode == HK_MODE_OBSERVE ? "observe" : "sync", args, ret,
                 g_slots[si].active, pr.rva, fresh ? pr.stolenLen : 0);
        audit_hook(Ls, "detour_install", id, target, -1, d);
    }
    *outErr = NULL;
    return si;
#undef HK_FN_REFUSE
}

// ---------------------------------------------------------------- Lua API

static int hk_opt_int(lua_State *Ls, int idx, const char *field, int dflt) {
    int t = lua_gettop(Ls);
    if (t < idx || !lua_istable(Ls, idx)) return dflt;
    lua_getfield(Ls, idx, field);
    int v = lua_isnumber(Ls, -1) ? (int)lua_tointeger(Ls, -1) : dflt;
    lua_pop(Ls, 1);
    return v;
}
static const char *hk_opt_str(lua_State *Ls, int idx, const char *field) {
    int t = lua_gettop(Ls);
    if (t < idx || !lua_istable(Ls, idx)) return NULL;
    lua_getfield(Ls, idx, field);
    const char *v = lua_isstring(Ls, -1) ? lua_tostring(Ls, -1) : NULL;
    lua_pop(Ls, 1);
    return v;
}

// hoi4.hook_vt(vt, slot, fn, opts) -> handle | nil, err
int hoi4_hook_vt(lua_State *Ls) {
    uint64_t vt = (uint64_t)luaL_checkinteger(Ls, 1);
    int slot = (int)luaL_checkinteger(Ls, 2);
    luaL_checktype(Ls, 3, LUA_TFUNCTION);

    const char *id = hk_opt_str(Ls, 4, "id");
    char idbuf[HK_ID_LEN];
    if (!id || !*id) {
        // default id: derived from the target so two scripts hooking the same
        // slot without naming themselves still get distinct ids
        snprintf(idbuf, sizeof(idbuf), "hook_%llx_%d",
                 (unsigned long long)vt, slot);
        id = idbuf;
    }
    int mode = HK_MODE_SYNC;
    const char *ms = hk_opt_str(Ls, 4, "mode");
    if (ms && strcmp(ms, "observe") == 0) mode = HK_MODE_OBSERVE;
    else if (ms && strcmp(ms, "sync") != 0)
        { lua_pushnil(Ls); lua_pushfstring(Ls, "mode must be 'sync' or 'observe'"); return 2; }

    int ret = HK_RET_U64;
    const char *rs = hk_opt_str(Ls, 4, "ret");
    if (rs) {
        if (strcmp(rs, "void") == 0) ret = HK_RET_VOID;
        else if (strcmp(rs, "bool") == 0) ret = HK_RET_BOOL;
        else if (strcmp(rs, "u64") != 0)
            { lua_pushnil(Ls); lua_pushfstring(Ls, "ret must be 'u64', 'void' or 'bool'"); return 2; }
    }
    int args = hk_opt_int(Ls, 4, "args", 1);

    // register the callback FIRST: the patch must never be live without a
    // resolvable callback (a thunk with a missing callback still fails open,
    // but registering first avoids even that transient).
    hk_reg_table(Ls);
    lua_pushvalue(Ls, 3);
    lua_setfield(Ls, -2, id);
    lua_pop(Ls, 1);

    const char *err = NULL;
    int si = hk_install(Ls, vt, slot, id, args, ret, mode, &err);
    if (si < 0) {
        lua_pushnil(Ls);
        lua_pushstring(Ls, err ? err : "install refused");
        return 2;
    }

    lua_createtable(Ls, 0, 4);
    lua_pushstring(Ls, id);                 lua_setfield(Ls, -2, "id");
    lua_pushinteger(Ls, (lua_Integer)hk_resolve(vt)); lua_setfield(Ls, -2, "vt");
    lua_pushinteger(Ls, slot);              lua_setfield(Ls, -2, "slot");
    lua_pushstring(Ls, mode == HK_MODE_OBSERVE ? "observe" : "sync");
    lua_setfield(Ls, -2, "mode");
    return 1;
}

// hoi4.unhook_vt(id) -> true | nil, err
int hoi4_unhook_vt(lua_State *Ls) {
    const char *id = luaL_checkstring(Ls, 1);
    const char *err = NULL;
    if (!hk_uninstall(Ls, id, &err)) {
        lua_pushnil(Ls);
        lua_pushstring(Ls, err ? err : "unhook failed");
        return 2;
    }
    // drop the callback registration too
    hk_reg_table(Ls);
    lua_pushnil(Ls);
    lua_setfield(Ls, -2, id);
    lua_pop(Ls, 1);
    lua_pushboolean(Ls, 1);
    return 1;
}

static void hk_push_status(lua_State *Ls, HkEntry *e) {
    HkSlot *s = &g_slots[e->slotIdx];
    lua_createtable(Ls, 0, 14);
    lua_pushstring(Ls, e->id);                 lua_setfield(Ls, -2, "id");
    lua_pushinteger(Ls, (lua_Integer)s->vt);   lua_setfield(Ls, -2, "vt");
    lua_pushinteger(Ls, s->slot);              lua_setfield(Ls, -2, "slot");
    lua_pushstring(Ls, e->mode == HK_MODE_OBSERVE ? "observe" : "sync");
    lua_setfield(Ls, -2, "mode");
    lua_pushinteger(Ls, e->args);              lua_setfield(Ls, -2, "args");
    lua_pushinteger(Ls, e->ret);               lua_setfield(Ls, -2, "ret");
    lua_pushinteger(Ls, (lua_Integer)e->calls);            lua_setfield(Ls, -2, "calls");
    lua_pushinteger(Ls, (lua_Integer)e->luaCalls);         lua_setfield(Ls, -2, "lua_calls");
    lua_pushinteger(Ls, (lua_Integer)e->swallowed);        lua_setfield(Ls, -2, "replaced");
    lua_pushinteger(Ls, (lua_Integer)e->forwarded);        lua_setfield(Ls, -2, "forwarded");
    lua_pushinteger(Ls, (lua_Integer)e->errors);           lua_setfield(Ls, -2, "errors");
    lua_pushinteger(Ls, (lua_Integer)e->droppedOffThread); lua_setfield(Ls, -2, "dropped_off_thread");
    lua_pushinteger(Ls, (lua_Integer)e->depthCapped);      lua_setfield(Ls, -2, "depth_capped");
    lua_pushinteger(Ls, s->active);            lua_setfield(Ls, -2, "chain_depth");
    lua_pushstring(Ls, s->kind == HK_KIND_FN ? "detour" : "vt");
    lua_setfield(Ls, -2, "kind");
    lua_pushinteger(Ls, (lua_Integer)(uintptr_t)s->origFn);
    lua_setfield(Ls, -2, "orig");
    if (s->kind == HK_KIND_FN) {
        lua_pushinteger(Ls, (lua_Integer)s->rva);   lua_setfield(Ls, -2, "rva");
        lua_pushinteger(Ls, s->stolenLen);          lua_setfield(Ls, -2, "stolen_len");
    } else {
        lua_pushinteger(Ls, (lua_Integer)s->slot);  lua_setfield(Ls, -2, "slot");
        lua_pushinteger(Ls, (lua_Integer)s->vt);    lua_setfield(Ls, -2, "vt");
    }
}

// hoi4.hook_list() -> array of status tables
int hoi4_hook_list(lua_State *Ls) {
    lua_newtable(Ls);
    int n = 0;
    for (int i = 0; i < (int)g_hookCount; i++) {
        if (g_hooks[i].slotIdx < 0) continue;
        hk_push_status(Ls, &g_hooks[i]);
        lua_rawseti(Ls, -2, ++n);
    }
    return 1;
}

// hoi4.hook_status(id) -> table | nil
int hoi4_hook_status(lua_State *Ls) {
    const char *id = luaL_checkstring(Ls, 1);
    HkEntry *e = hk_find(id);
    if (!e) { lua_pushnil(Ls); return 1; }
    hk_push_status(Ls, e);
    return 1;
}

// hoi4.detour(addr, fn, opts) -> handle | nil, err
// Tier 2. Same callback contract as hoi4.hook_vt, but the target is a FUNCTION
// ADDRESS rather than a vtable slot, and the install is permanent. See the
// header of hk_install_fn for the gate order.
int hoi4_detour(lua_State *Ls) {
    uint64_t addr = (uint64_t)luaL_checkinteger(Ls, 1);
    luaL_checktype(Ls, 2, LUA_TFUNCTION);

    // Accept both absolute addresses and BASE-relative RVAs, the way every
    // other address-taking API in this framework does (hk_resolve).
    uint64_t target = hk_resolve(addr);

    const char *id = hk_opt_str(Ls, 3, "id");
    char idbuf[HK_ID_LEN];
    if (!id || !*id) {
        snprintf(idbuf, sizeof(idbuf), "detour_%llx", (unsigned long long)addr);
        id = idbuf;
    }
    int mode = HK_MODE_SYNC;
    const char *ms = hk_opt_str(Ls, 3, "mode");
    if (ms && strcmp(ms, "observe") == 0) mode = HK_MODE_OBSERVE;
    else if (ms && strcmp(ms, "sync") != 0)
        { lua_pushnil(Ls); lua_pushstring(Ls, "mode must be 'sync' or 'observe'"); return 2; }

    int ret = HK_RET_U64;
    const char *rs = hk_opt_str(Ls, 3, "ret");
    if (rs) {
        if (strcmp(rs, "void") == 0) ret = HK_RET_VOID;
        else if (strcmp(rs, "bool") == 0) ret = HK_RET_BOOL;
        else if (strcmp(rs, "u64") != 0)
            { lua_pushnil(Ls); lua_pushstring(Ls, "ret must be 'u64', 'void' or 'bool'"); return 2; }
    }
    // `this` defaults to false: a non-virtual function is the common case for
    // a detour, and guessing "member function" would hand Lua a bogus self.
    int isThis = 0;
    {
        int t = lua_gettop(Ls);
        if (t >= 3 && lua_istable(Ls, 3)) {
            lua_getfield(Ls, 3, "this");
            isThis = lua_toboolean(Ls, -1) ? 1 : 0;
            lua_pop(Ls, 1);
        }
    }
    // args = integer parameters. With this=true the first register slot is the
    // object, so the Lua-visible a1..a3 still cap at 3 either way.
    int args = hk_opt_int(Ls, 3, "args", isThis ? 0 : 1);
    if (args < 0 || args > 3)
        { lua_pushnil(Ls); lua_pushstring(Ls, "args must be 0..3"); return 2; }

    hk_reg_table(Ls);
    lua_pushvalue(Ls, 2);
    lua_setfield(Ls, -2, id);
    lua_pop(Ls, 1);

    const char *err = NULL;
    int si = hk_install_fn(Ls, target, id, args, ret, mode, &err);
    if (si < 0) {
        lua_pushnil(Ls);
        lua_pushstring(Ls, err ? err : "detour refused");
        return 2;
    }
    lua_pushstring(Ls, id);
    return 1;
}

// hoi4.detour_list() -> array of status tables (Tier 2 entries only)
int hoi4_detour_list(lua_State *Ls) {
    lua_newtable(Ls);
    int n = 0;
    for (int i = 0; i < (int)g_hookCount; i++) {
        if (g_hooks[i].slotIdx < 0) continue;
        if (g_slots[g_hooks[i].slotIdx].kind != HK_KIND_FN) continue;
        hk_push_status(Ls, &g_hooks[i]);
        lua_rawseti(Ls, -2, ++n);
    }
    return 1;
}

// hoi4.detour_status(id) -> table | nil
int hoi4_detour_status(lua_State *Ls) {
    const char *id = luaL_checkstring(Ls, 1);
    HkEntry *e = hk_find(id);
    if (!e || g_slots[e->slotIdx].kind != HK_KIND_FN) { lua_pushnil(Ls); return 1; }
    hk_push_status(Ls, e);
    return 1;
}

// hoi4.detour_probe(addr) -> report table
// Read-only and always available (no first-load restriction): it is the way to
// find out whether a target CAN be detoured without touching anything.
int hoi4_detour_probe(lua_State *Ls) {
    uint64_t addr = (uint64_t)luaL_checkinteger(Ls, 1);
    uint64_t target = hk_resolve(addr);
    HkProbe p;
    hk_probe_fill(target, &p);

    lua_newtable(Ls);
    lua_pushboolean(Ls, p.ok);            lua_setfield(Ls, -2, "ok");
    lua_pushinteger(Ls, (lua_Integer)target); lua_setfield(Ls, -2, "target");
    lua_pushinteger(Ls, (lua_Integer)p.rva);        lua_setfield(Ls, -2, "rva");
    lua_pushinteger(Ls, (lua_Integer)p.funcStart);  lua_setfield(Ls, -2, "func_start");
    lua_pushinteger(Ls, (lua_Integer)p.funcEnd);    lua_setfield(Ls, -2, "func_end");
    lua_pushboolean(Ls, p.isFuncStart);   lua_setfield(Ls, -2, "is_func_start");
    lua_pushboolean(Ls, p.stolenLen > 0); lua_setfield(Ls, -2, "stealable");
    lua_pushinteger(Ls, p.stolenLen);     lua_setfield(Ls, -2, "stolen_len");
    if (p.stolenLen > 0) {
        char hex[3 * 24 + 1];
        hk_hex(p.stolen, p.stolenLen, hex, sizeof(hex));
        lua_pushstring(Ls, hex);          lua_setfield(Ls, -2, "stolen_hex");
    }
    if (p.reason) { lua_pushstring(Ls, p.reason); lua_setfield(Ls, -2, "reason"); }
    return 1;
}

// ---------------------------------------------------------------- lifecycle

void hook_note_main_thread(DWORD tid) {
    if (InterlockedCompareExchange(&g_mainTidSet, 1, 0) == 0) {
        g_mainTid = tid;
        L("[hook] main thread recorded: tid=%lu", tid);
    }
}
DWORD hook_main_tid(void) { return g_mainTid; }

void hook_session_regen(void) {
    // Hooks are PROCESS-level: the patch lives in engine .rdata and is entirely
    // independent of gamestate lifetime, so nothing is torn down here (the
    // 2026-09-19 bind-table lesson — never GC live state on a session switch).
    // Only bookkeeping is refreshed. The callback is resolved by id on every
    // call, so a surviving hook reaches the CURRENT session's closure.
    long cur = InterlockedIncrement(&g_hookGen) - 1;
    for (int i = 0; i < HK_MAX_SLOTS; i++)
        if (g_slots[i].inUse) g_slots[i].gen = cur;
    for (int i = 0; i < (int)g_hookCount; i++) g_hooks[i].gen = cur;
    g_obsWrite = 0; g_obsRead = 0;      // stale observe events are meaningless
    L("[hook] session regen: %d hook(s) / %d slot(s) kept (gen=%ld)",
      (int)g_hookCount, hook_slot_count(), cur);
}

// frame top, main thread, g_luaLock held: deliver queued observe events
void hook_dispatch_observe(lua_State *Ls) {
    long dropped = g_obsDropped;
    if (dropped) { g_obsDropped = 0; L("[hook] observe queue dropped %ld event(s)", dropped); }

    int guard = 0;
    while (g_obsRead < g_obsWrite && guard++ < HK_OBSERVE_QUEUE) {
        HkEvent *ev = &g_obsQ[g_obsRead % HK_OBSERVE_QUEUE];
        HkEntry *e = hk_find(ev->id);          // by ID: the table slot may have
                                               // been recycled since enqueue
        if (e && e->mode == HK_MODE_OBSERVE) {
            int before = lua_gettop(Ls);
            if (hk_push_callback(Ls, e->id)) {
                HkCtx ctx;
                ctx.slotIdx = e->slotIdx; ctx.nextIdx = 0; ctx.self = ev->self;
                ctx.a1 = ev->a1; ctx.a2 = ev->a2; ctx.a3 = ev->a3;
                ctx.ret = ev->ret; ctx.calledCont = 1;   // the original already ran
                // call_orig is NOT offered: the engine call has already
                // returned, so there is nothing left to drive.
                hk_push_ctx_table(Ls, e, &ctx, 0);
                lua_pushinteger(Ls, (lua_Integer)ev->ret);
                lua_setfield(Ls, -2, "ret");
                e->luaCalls++;
                if (lua_pcall(Ls, 1, 0, 0) != LUA_OK) {
                    L("[hook] observe error in '%s': %s", e->id,
                      lua_tostring(Ls, -1) ? lua_tostring(Ls, -1) : "?");
                    lua_pop(Ls, 1);
                    e->errors++;
                }
            } else {
                lua_pop(Ls, 1);
            }
            lua_settop(Ls, before);
        }
        g_obsRead++;
    }
}

int hook_count(void)      { return (int)g_hookCount; }
int hook_detour_count(void) { return (int)g_detourCount; }
int hook_slot_count(void) {
    int n = 0;
    for (int i = 0; i < HK_MAX_SLOTS; i++) if (g_slots[i].inUse) n++;
    return n;
}

// exported for the bridge's own memory-derived call sites — see hoi4_hook.h
int hook_orig_for_thunk(uint64_t addr, uint64_t *out_orig) {
    for (int i = 0; i < HK_MAX_SLOTS; i++) {
        if ((uint64_t)(uintptr_t)g_thunks[i] != addr) continue;
        // origFn is kept even after a slot is released, so this resolves for a
        // stale thunk too (forwarding to the original = "unhooked" semantics).
        if (!g_slots[i].origFn) return 0;
        if (out_orig) *out_orig = (uint64_t)(uintptr_t)g_slots[i].origFn;
        return 1;
    }
    // Tier 2: a detour leaves the vtable slot alone and patches the FUNCTION
    // BODY, so a bridge call site reading mgr->vt[+656] still gets the engine
    // address — and the call then lands in our thunk. Resolve that case too,
    // or a mod detour would be able to veto the bridge's own pause/load (the
    // exact thing the Tier 1 ruling forbids; see hoi4_hook.h).
    for (int i = 0; i < HK_MAX_SLOTS; i++) {
        if (!g_slots[i].inUse || g_slots[i].kind != HK_KIND_FN) continue;
        if ((uint64_t)(uintptr_t)g_slots[i].slotAddr != addr) continue;
        if (!g_slots[i].origFn) return 0;
        if (out_orig) *out_orig = (uint64_t)(uintptr_t)g_slots[i].origFn;
        return 1;
    }
    return 0;
}

// Is [addr] a trampoline this facility allocated? A trampoline is NOT engine
// code (it lives in a VirtualAlloc block), so memgate_exec_ok rejects it — by
// design. The bridge's own call sites accept it as a second, narrower case:
// they are calling infrastructure they allocated themselves, not a target a
// Lua caller nominated. memgate itself is untouched.
int hook_is_our_trampoline(uint64_t addr) {
    if (!addr) return 0;
    for (int i = 0; i < HK_MAX_SLOTS; i++)
        if (g_slots[i].kind == HK_KIND_FN && g_slots[i].origFn &&
            (uint64_t)(uintptr_t)g_slots[i].origFn == addr)
            return 1;
    return 0;
}
