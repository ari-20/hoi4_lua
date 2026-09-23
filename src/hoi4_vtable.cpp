#include "hoi4_common.h"

// ---- bind table / vtable machinery ----
// ---------------------------------------------------------------- bind table
// instance -> lua fn name; append-only, obj field published last (x64 TSO)
// gen stamped from g_bindGen at install (diagnostics only since 2026-09-19).
//
// 2026-09-19 session-switch fix: the old design GC-dropped old-gen binds at
// session-START dispatch. That killed LIVE binds on same-pointer session
// switches (save reload / new campaign — the engine reuses the gs allocation
// AND the script database, and does NOT reliably re-parse the routed effects:
// observed 0 re-installs for the on_daily effects after such a switch). After
// the GC, every routed effect silently forwarded to the original SGF Execute.
// Binds are now KEPT across sessions and re-stamped. Lookup matches obj
// ONLY — the +0x20 token is re-initialized by in-place save loads and is not
// a stable identity; duplicate entries under a recycled address are instead
// collapsed by the regen-time compaction (last entry per obj wins). The Lua
// fn itself is resolved BY NAME in the registry on every call, so a
// surviving bind always reaches the CURRENT session's closure.
typedef struct { void *obj; char fn[64]; int token; long gen; } BindEntry;
static BindEntry g_binds[512];
static volatile long g_bindCount;
static volatile long g_bindGen;

// ⚠ 2026-09-19 live test: an in-place save load re-initializes shell fields,
// so the +0x20 token is NOT stable across loads — lookup must match obj only
// (the pre-2026-09-19 behavior). Address-recycling disambiguation is instead
// handled by the regen-time duplicate compaction (last entry per obj wins).
const char *bind_lookup(void *obj) {
    int n = (int)g_bindCount;
    for (int i = 0; i < n; i++)
        if (g_binds[i].obj == obj) return g_binds[i].fn;
    return NULL;
}

// session watcher: the live session just ended. Gen is bookkeeping only.
void bind_note_session_end(void) {
    InterlockedIncrement(&g_bindGen);
}

// frame-top (session START): KEEP all binds (same-pointer switches reuse the
// script database and its shell instances — the 2026-09-19 GC dropped live
// binds here and killed every routed effect until the next re-parse) and
// re-stamp to the current gen. Compacts exact duplicates when full.
// occupancy for the capacity log (hoi4_main.cpp capacity_log_locked).
// g_bindCount can briefly exceed the cap: bind_add increments before the
// bounds check rejects, regen compaction resets it.
int bind_count(void) { return (int)g_bindCount; }

void bind_table_regen(void) {
    long cur = g_bindGen;
    long n = g_bindCount;
    if (n >= 512) {                       // compact: keep last (obj,token) pair
        long w = 0;
        for (long i = 0; i < n; i++) {
            long j;
            for (j = i + 1; j < n; j++)
                if (g_binds[j].obj == g_binds[i].obj &&
                    g_binds[j].token == g_binds[i].token) break;
            if (j >= n) g_binds[w++] = g_binds[i];   // no later duplicate
        }
        g_bindCount = w;
        n = w;
        L("[bind] table full: compacted to %d unique shell bind(s)", (int)w);
    }
    for (long i = 0; i < g_bindCount; i++) g_binds[i].gen = cur;
    L("[bind] session refresh: %d bind(s) kept (gen=%ld)", (int)g_bindCount, cur);
}

static int bind_add(void *obj, const char *fn, int token) {
    if (g_bindCount >= 512) return 0;
    long i = InterlockedIncrement(&g_bindCount) - 1;
    if (i >= 512) return 0;
    strncpy(g_binds[i].fn, fn, 63);
    g_binds[i].fn[63] = 0;
    g_binds[i].token = token;
    g_binds[i].gen = g_bindGen;
    g_binds[i].obj = obj;                 // publish LAST
    return 1;
}

// ---------------------------------------------------------------- vtable machinery
// TRUE vtable length is 26 slots (verified by static PE scan, m4_vtlen.py:
// slots are consecutive .text pointers until a data qword at [26]; the qword
// BEFORE the vtable is the RTTI COL 0x142bbdb70 matching RTTI records).
// The old 12-slot copy was truncated -> engine called slot 12+ -> garbage.
#define VT_SLOTS 26
static void **g_sgfVt;                    // engine CSetGlobalFlagEffect vtable
static void *g_myVtFull[VT_SLOTS + 1];    // [0]=COL copy, [1..26]=our vtable
static void **g_myVt = &g_myVtFull[1];
static void *g_slotOrig[VT_SLOTS];

// thunks: forward 4-arg/uint64-ret superset (safe on x64 for all observed sigs)
// ⚠ 2026-09-20 hardening: on the EXECUTE slot (LUACALL=1), a bind miss no
// longer forwards to the original SGF Execute — that would run
// set_global_flag(<our effect token>) = silent world pollution on every
// lost-bind daily tick. Fail safe: rate-limited log + skip. Non-execute
// slots keep forwarding (the shell must behave like SGF for dtor/parse/
// tooltips — that is by design).
#define SLOT_THUNK(N, LUACALL) \
static uint64_t __fastcall Slot##N(void *self, void *a, void *b, void *c) { \
    const char *fn = bind_lookup(self); \
    if (fn) { \
        if (dll_debug_mode()) L("[effect] slot" #N " on bound '%s' self=%p a=%p b=%p", fn, self, a, b); \
        if (LUACALL) { lua_call_effect(fn, self, (uint64_t)(uintptr_t)a); return 0; } \
        return ((uint64_t (__fastcall *)(void *, void *, void *, void *))g_slotOrig[N])(self, a, b, c); \
    } \
    if (LUACALL) { \
        static volatile LONG s_miss; \
        long m = InterlockedIncrement(&s_miss); \
        if (m <= 5 || m % 500 == 0) \
            L("[effect] EXECUTE bind miss self=%p (total %ld) — skipped, no SGF fallthrough", self, m); \
        return 0; \
    } \
    return ((uint64_t (__fastcall *)(void *, void *, void *, void *))g_slotOrig[N])(self, a, b, c); \
}
SLOT_THUNK(0, 0)
SLOT_THUNK(1, 0)
SLOT_THUNK(2, 0)
SLOT_THUNK(3, 0)   // parse (we call this ourselves during install)
SLOT_THUNK(4, 0)
SLOT_THUNK(5, 0)
SLOT_THUNK(6, 0)
SLOT_THUNK(7, 0)
SLOT_THUNK(8, 0)
SLOT_THUNK(9, 0)
SLOT_THUNK(10, 0)
SLOT_THUNK(11, 0)
SLOT_THUNK(12, 1)  // EXECUTE entry (gamestate asserts + scope check inside);
                   // success path calls slot13 via vtable — Lua branch returns
                   // early so we never double-execute
SLOT_THUNK(13, 0)  // actual write body (set_global_flag's flag-store path)
SLOT_THUNK(14, 0)
SLOT_THUNK(15, 0)
SLOT_THUNK(16, 0)
SLOT_THUNK(17, 0)
SLOT_THUNK(18, 0)
SLOT_THUNK(19, 0)
SLOT_THUNK(20, 0)
SLOT_THUNK(21, 0)
SLOT_THUNK(22, 0)
SLOT_THUNK(23, 0)
SLOT_THUNK(24, 0)
SLOT_THUNK(25, 0)

void build_my_vtable(void) {
    g_sgfVt = (void **)(g_base + RVA_SGF_VTABLE);
    g_myVtFull[0] = g_sgfVt[-1];       // RTTI Complete Object Locator
    for (int i = 0; i < VT_SLOTS; i++) g_slotOrig[i] = g_sgfVt[i];
    g_myVt[0]  = Slot0;   // dtor: forward (bind cleanup via slot0 log only)
    g_myVt[1]  = Slot1;
    g_myVt[2]  = Slot2;
    g_myVt[3]  = Slot3;   // Lua hook slot
    g_myVt[4]  = Slot4;
    g_myVt[5]  = Slot5;
    g_myVt[6]  = Slot6;
    g_myVt[7]  = Slot7;
    g_myVt[8]  = Slot8;
    g_myVt[9]  = Slot9;
    g_myVt[10] = Slot10;
    g_myVt[11] = Slot11;
    g_myVt[12] = Slot12;
    g_myVt[13] = Slot13;
    g_myVt[14] = Slot14;
    g_myVt[15] = Slot15;
    g_myVt[16] = Slot16;
    g_myVt[17] = Slot17;
    g_myVt[18] = Slot18;
    g_myVt[19] = Slot19;
    g_myVt[20] = Slot20;
    g_myVt[21] = Slot21;
    g_myVt[22] = Slot22;
    g_myVt[23] = Slot23;
    g_myVt[24] = Slot24;
    g_myVt[25] = Slot25;
    L("[effect] full %d-slot vtable ready (engine=%p COL=%p)", VT_SLOTS, g_sgfVt, g_sgfVt[-1]);
}

// -+ triggers
// Same shape as the effect side but for CTrigger:
//   trigger router FUN_1405434f0 hook -> by-name intercept -> synthesize a
//   CGlobalFlagTrigger via its factory -> replicate router success path
//   (token @ +4, scope check vt+0x80, push list, Parse vt+0x28) -> swap full
//   24-slot vtable copy with slot 22 (Evaluate, vt+0xB0) as the Lua thunk.
// Differences vs effects: token stored at obj+4 (u64), scope-check slot +0x80
// (effects: +0xA8), Parse slot +0x28 (effects: +0x18), Evaluate is slot 22
// returning bool in AL (engine calls it via base slot 3's vt+0xB0 dispatch).
#define TVT_SLOTS 24
static void **g_gftVt;                     // engine CGlobalFlagTrigger vtable
static void *g_myTVtFull[TVT_SLOTS + 1];   // [0]=COL copy, [1..24]=our vtable
static void **g_myTVt = &g_myTVtFull[1];
static void *g_slotTOrig[TVT_SLOTS];
void *(*g_factoryGFT)(void);

// call Lua fn(name, self, ctx) -> bool; serialized like the effect path
static int lua_call_trigger(const char *fn, void *self, uint64_t ctx) {
    int ret = 0;
    if (!g_L) return 0;
    lua_lock();                              // recursion-aware (see above)
    // (A1/F9) detection removed here — covered by frame-top throttle
    // (frame hook is the parent of trigger dispatch).
    reg_table(g_L, REG_TABLE_TRIGGER);       // fn lives in the registry
    lua_pushstring(g_L, fn);
    lua_rawget(g_L, -2);
    lua_remove(g_L, -2);
    if (lua_isfunction(g_L, -1)) {
        lua_pushstring(g_L, fn);
        lua_pushlightuserdata(g_L, self);
        lua_pushlightuserdata(g_L, (void *)(uintptr_t)ctx);
        if (lua_pcall(g_L, 3, 1, 0) != LUA_OK) {
            L("[trigger] lua runtime error in trigger %s: %s", fn, lua_tostring(g_L, -1));
            lua_pop(g_L, 1);
        } else {
            ret = lua_toboolean(g_L, -1);
            lua_pop(g_L, 1);
        }
    } else {
        lua_pop(g_L, 1);
    }
    lua_unlock();
    return ret;
}

// Evaluate thunk: preserve register-passed args we must forward (self, ctx).
// Original is FUN_1403d0d90(this, ctx) -> bool; we rebuild via a small asm
// trampoline is overkill — the thunk signature matches: (self, ctx, r8, r9).
// Bind miss (hardening 2026-09-20): return false (conservative), never
// forward — a lost bind must not evaluate the raw CGlobalFlagTrigger.
static uint64_t __fastcall TEval(void *self, void *ctx, void *r8, void *r9) {
    const char *fn = bind_lookup(self);
    if (fn) {
        int b = lua_call_trigger(fn, self, (uint64_t)(uintptr_t)ctx);
        L("[trigger] TRIGGER '%s' eval -> %d", fn, b);
        return (uint64_t)(unsigned char)b;
    }
    L("[trigger] EVAL bind miss — returning false (conservative)");
    return 0;
}

#define TSLOT_THUNK(N) \
static uint64_t __fastcall TSlot##N(void *self, void *a, void *b, void *c) { \
    return ((uint64_t(__fastcall *)(void *, void *, void *, void *))g_slotTOrig[N])(self, a, b, c); \
}
TSLOT_THUNK(0)
TSLOT_THUNK(1)
TSLOT_THUNK(2)
TSLOT_THUNK(3)
TSLOT_THUNK(4)
TSLOT_THUNK(5)
TSLOT_THUNK(6)
TSLOT_THUNK(7)
TSLOT_THUNK(8)
TSLOT_THUNK(9)
TSLOT_THUNK(10)
TSLOT_THUNK(11)
TSLOT_THUNK(12)
TSLOT_THUNK(13)
TSLOT_THUNK(14)
TSLOT_THUNK(15)
TSLOT_THUNK(16)
TSLOT_THUNK(17)
TSLOT_THUNK(18)
TSLOT_THUNK(19)
TSLOT_THUNK(20)
TSLOT_THUNK(21)
TSLOT_THUNK(23)

void build_my_tvt(void) {
    g_gftVt = (void **)(g_base + RVA_GFT_VTABLE);
    g_myTVtFull[0] = g_gftVt[-1];       // RTTI Complete Object Locator
    for (int i = 0; i < TVT_SLOTS; i++) g_slotTOrig[i] = g_gftVt[i];
    g_myTVt[0]  = TSlot0;
    g_myTVt[1]  = TSlot1;
    g_myTVt[2]  = TSlot2;
    g_myTVt[3]  = TSlot3;
    g_myTVt[4]  = TSlot4;
    g_myTVt[5]  = TSlot5;
    g_myTVt[6]  = TSlot6;
    g_myTVt[7]  = TSlot7;
    g_myTVt[8]  = TSlot8;
    g_myTVt[9]  = TSlot9;
    g_myTVt[10] = TSlot10;
    g_myTVt[11] = TSlot11;
    g_myTVt[12] = TSlot12;
    g_myTVt[13] = TSlot13;
    g_myTVt[14] = TSlot14;
    g_myTVt[15] = TSlot15;
    g_myTVt[16] = TSlot16;
    g_myTVt[17] = TSlot17;
    g_myTVt[18] = TSlot18;
    g_myTVt[19] = TSlot19;
    g_myTVt[20] = TSlot20;
    g_myTVt[21] = TSlot21;
    g_myTVt[22] = TEval;    // Evaluate
    g_myTVt[23] = TSlot23;
    L("[trigger] trigger vtable ready (%d slots, engine=%p COL=%p)",
      TVT_SLOTS, g_gftVt, g_gftVt[-1]);
}

// router success path replication for triggers (see FUN_1405434f0 tail):
//   obj = factory()                    ; new 0xb0, base ctor, write vtable
//   line-info slot omitted (only used for tooltips of native triggers)
//   *(u32*)(obj+4) = token             ; NOTE +4, not +0x20 like effects
//   scope check: (vt+0x80)(obj, scope) ; logs warning on mismatch, non-fatal
//   push obj into list @ param1+8
//   Parse: (vt+0x28)(obj, ctx, scope)  ; parse trigger args from script
static void install_trigger_for(const char *name, uint64_t ctx_p,
                                uint64_t param1, uint64_t token, int scope) {
    void *obj = g_factoryGFT();
    if (!obj) { L("[trigger] GFT factory returned null"); return; }
    // router tail replication (FUN_1405434f0 LAB_140543b93..end), in order:
    //   line-info: obj+0x2c <- *FUN_1424aa650(ctx, &buf); obj+0x34 = 1
    //   token:     *(u32*)(obj+0x20) = token   (plVar14+4 with longlong* = +0x20!)
    //   scope chk: (vt+0x80)(obj, scope)       (warning only, non-fatal)
    //   push into list @ param1+8
    //   parse:     (vt+0x28)(obj, ctx, scope)
    __try {
        uint64_t buf[2];
        uint64_t *li = ((uint64_t *(__fastcall *)(uint64_t, void *))(
            g_base + RVA_LINE_INFO))(ctx_p, buf);
        *(uint64_t *)((uint8_t *)obj + 0x2c) = *li;
        *(uint8_t *)((uint8_t *)obj + 0x34) = 1;
    } __except (EXCEPTION_EXECUTE_HANDLER) { L("[trigger] lineinfo faulted"); }
    *(uint32_t *)((uint8_t *)obj + 0x20) = (uint32_t)token;
    void **vt = *(void ***)obj;
    __try {
        ((char(__fastcall *)(void *, int))vt[0x80 / 8])(obj, scope);
    } __except (EXCEPTION_EXECUTE_HANDLER) { L("[trigger] scope check faulted"); }
    // swap in our vtable, bind, push (router pushes before parse; parse then
    // runs through TSlot5 which forwards to the original FUN_1413950f0)
    *(void ***)obj = g_myTVt;
    if (!bind_add(obj, name, (int)token)) L("[trigger] bind table full");
    void *pObj = obj;
    __try { g_engPush((uint8_t *)param1 + 8, &pObj); }
    __except (EXCEPTION_EXECUTE_HANDLER) { L("[trigger] vec push faulted"); }
    __try {
        ((void(__fastcall *)(void *, uint64_t, int))vt[0x28 / 8])(obj, ctx_p, scope);
    } __except (EXCEPTION_EXECUTE_HANDLER) { L("[trigger] parse faulted"); }
    L("[trigger] trigger installed obj=%p token=%llx lua=%s", obj,
      (unsigned long long)token, name);
}

TRouter_t g_origTRouter;

void __fastcall HK_TriggerRouter(uint64_t param1, uint64_t param2,
                                        uint64_t token, int scope) {
    static volatile long g_seen = 0;
    if (InterlockedCompareExchange(&g_seen, 1, 0) == 0)
        L("[trigger] trigger router hooked, first call token=%llx scope=%d",
          (unsigned long long)token, scope);
    const char *name = "";
    __try {
        if (*(int *)(param2 + 0x44) != 0)
            name = *(const char **)(param2 + 0x38);
    } __except (EXCEPTION_EXECUTE_HANDLER) { name = ""; }
    if (name && *name && trigger_known(name)) {
        L("[trigger] ROUTED '%s' token=%llx scope=%d", name,
          (unsigned long long)token, scope);
        install_trigger_for(name, param2, param1, token, scope);
        return;
    }
    g_origTRouter(param1, param2, token, scope);
}

// -+ effect install
static void install_effect_for(const char *name, uint64_t ctx_p, uint64_t param1, int token, int scope) {
    void *obj = g_factorySetGlobal();
    if (!obj) { L("[effect] factory returned null"); return; }
    *(int *)((uint8_t *)obj + 0x20) = token;
    // engine parse with ORIGINAL vtable (proven path), then swap in the
    // FULL 26-slot copy — the old crash was a truncated 12-slot vtable.
    // D2 note (2026-09-12 live test): vt[3] (SGF Parse) is REQUIRED — it
    // consumes the token stream itself and fills the shell's value holders
    // (+128 value / +336 expiry) via its internal slot4 dispatch. Calling
    // vt[6] directly (as typed effects do from their Parse) fails here
    // because the engine prepares ctx+0xC0 only when IT drives the parse —
    // at our router hook point the buffer is not ready (live-tested: all
    // slot6 calls failed). Args are therefore read post-parse via
    // hoi4.eval_value(self+128, ctx) — no install-path change needed.
    void **vt = *(void ***)obj;
    ((void(__fastcall *)(void *, uint64_t, int))vt[3])(obj, ctx_p, scope);
    *(void ***)obj = g_myVt;
    if (!bind_add(obj, name, token)) L("[effect] bind table full");
    void *pObj = obj;
    __try { g_engPush((uint8_t *)param1 + 8, &pObj); }
    __except (EXCEPTION_EXECUTE_HANDLER) { L("[effect] vec push faulted"); }
    L("[effect] effect installed obj=%p token=%d lua=%s", obj, token, name);
}

Router_t g_origRouter;

void __fastcall HK_EffectRouter(uint64_t param1, uint64_t param2, int token, int scope) {
    static volatile long g_seen = 0;
    if (InterlockedCompareExchange(&g_seen, 1, 0) == 0)
        L("[effect] router hooked, first call token=%d scope=%d", token, scope);
    const char *name = "";
    __try {
        if (*(int *)(param2 + 0x44) != 0)
            name = *(const char **)(param2 + 0x38);
    } __except (EXCEPTION_EXECUTE_HANDLER) { name = ""; }
    if (name && *name && effect_known(name)) {
        L("[effect] ROUTED '%s' token=%d scope=%d param1=%llx", name, token, scope, param1);
        install_effect_for(name, param2, param1, token, scope);
        return;
    }
    g_origRouter(param1, param2, token, scope);
}

