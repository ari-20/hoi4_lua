// hoi4_scope.cpp — scope-context accessors (batch D1)
//
// Research basis: research_20260911/GAP4_5_CTX_SCOPE.md (2026-09-11).
// The scope ctx pointer ALREADY reaches Lua as the 3rd arg of effect/trigger
// callbacks (lua_call_effect/lua_call_trigger push it as lightuserdata);
// these accessors decode it. Layout is decomp-finalized with three-way
// evidence (scope check 0x140533BE0 / CAddPP::Execute 0x14034AF40 /
// value evaluator 0x1405382B0):
//
//   ctx+0x08 (dword) = scope country id -> dword table @ *(gs+0x340)[id]
//                      -> country array index into gs+0x310 (0 = no country)
//   ctx+0xA8 (dword) = scope state id (index into gs+0x2C8; 0 = no state)
//
// eval_value wraps the engine scripted-value evaluator
// sub_1405382B0(holder, &out, ctx, 0, 0) -> i64 fixed-point (x1e-5).
// The engine itself calls this from effect Execute bodies in the exact same
// context our callbacks run in (main thread, effect dispatch).

#include "hoi4_common.h"

// accept lightuserdata (raw callback arg) or integer address
static uint64_t sc_addr(lua_State *Ls, int n) {
    if (lua_type(Ls, n) == LUA_TLIGHTUSERDATA)
        return (uint64_t)(uintptr_t)lua_touserdata(Ls, n);
    return (uint64_t)luaL_checkinteger(Ls, n);
}

// hoi4.scope_country(ctx) -> country array index (>0) or nil (no country scope)
int hoi4_scope_country(lua_State *Ls) {
    uint64_t ctx = sc_addr(Ls, 1);
    uint64_t gs = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
    if (!ctx || !gs) { lua_pushnil(Ls); return 1; }
    uint32_t cid = h4_rd32(ctx + 0x08, 0);
    if (!cid) { lua_pushnil(Ls); return 1; }        // sentinel: no country scope
    uint64_t tab = h4_rd64(gs + 0x340, 0);             // id -> array idx dword table
    if (!tab) { lua_pushnil(Ls); return 1; }
    int32_t idx = (int32_t)h4_rd32(tab + 4ull * cid, 0);
    if (idx <= 0) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, idx);
    return 1;
}

// hoi4.scope_state_id(ctx) -> state id (0 = no state scope)
int hoi4_scope_state_id(lua_State *Ls) {
    uint64_t ctx = sc_addr(Ls, 1);
    if (!ctx) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, h4_rd32(ctx + 0xA8, 0));
    return 1;
}

typedef __int64 (__fastcall *EvalValue_t)(uint64_t holder, __int64 *out,
                                          uint64_t ctx, __int64 a4,
                                          unsigned __int8 a5);

// hoi4.eval_value(holder, ctx) -> i64 fixed-point raw (x1e-5) or nil on fault
int hoi4_eval_value(lua_State *Ls) {
    uint64_t holder = sc_addr(Ls, 1);
    uint64_t ctx    = sc_addr(Ls, 2);
    uint64_t gs = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
    if (!holder || !ctx || !gs) { lua_pushnil(Ls); return 1; }
    EvalValue_t fn = (EvalValue_t)(g_base + RVA_EVAL_VALUE);
    __int64 out = 0;
    __try {
        fn(holder, &out, ctx, 0, 0);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        lua_pushnil(Ls);
        return 1;
    }
    lua_pushinteger(Ls, out);
    return 1;
}
