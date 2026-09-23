#include "hoi4_common.h"

// registry + dual-table snapshot + hot-reload core ----
// -+ registry
// Explicit effect/trigger classification. Lua scripts register via
//   hoi4.effect(name, fn)    -> routable where an effect is legal
//   hoi4.trigger(name, fn)   -> routable where a trigger is legal; must return bool
// Anything not registered is NOT routed (tool functions are invisible to the
// engine even if they sit in _G). The same name may be registered as both
// (HOI4-style verb/predicate pairs share a namespace).

// push the registry table for 'kind' onto the stack (creates on first use)
void reg_table(lua_State *Ls, const char *kind) {
    lua_getfield(Ls, LUA_REGISTRYINDEX, "m4_registry");
    if (!lua_istable(Ls, -1)) {              // first registration ever
        lua_pop(Ls, 1);
        lua_newtable(Ls);                    // { effects={}, triggers={} }
        lua_newtable(Ls); lua_setfield(Ls, -2, REG_TABLE_EFFECT);
        lua_newtable(Ls); lua_setfield(Ls, -2, REG_TABLE_TRIGGER);
        lua_pushvalue(Ls, -1);
        lua_setfield(Ls, LUA_REGISTRYINDEX, "m4_registry");
    }
    lua_getfield(Ls, -1, kind);
    lua_remove(Ls, -2);                      // leave only the kind table
}

// shared impl: (name, fn) -> stores fn under name; warns on re-registration
// with a different function (hot reload overwrites silently by design).
static int reg_impl(lua_State *Ls, const char *kind) {
    const char *name = luaL_checkstring(Ls, 1);
    luaL_checktype(Ls, 2, LUA_TFUNCTION);
    reg_table(Ls, kind);
    lua_pushvalue(Ls, 1);                    // name key
    lua_gettable(Ls, -2);
    if (lua_isfunction(Ls, -1)) {
        // Hot reload never lands here: C clears both tables BEFORE re-dofiling
        // scripts, so a duplicate means two live scripts claim the same name.
        if (lua_compare(Ls, -1, 2, LUA_OPEQ)) {
            L("[registry] %s '%s' re-registered identically", kind, name);
        } else {
            L("[registry] WARNING: %s '%s' re-registered, overwriting previous fn", kind, name);
        }
    }
    lua_pop(Ls, 1);
    lua_pushvalue(Ls, 2);                    // fn
    lua_setfield(Ls, -2, name);              // kind[name] = fn
    lua_pop(Ls, 1);                          // pop kind table
    return 0;
}

int hoi4_effect_reg(lua_State *Ls)   { return reg_impl(Ls, REG_TABLE_EFFECT); }
int hoi4_trigger_reg(lua_State *Ls)  { return reg_impl(Ls, REG_TABLE_TRIGGER); }

// fetch a registered fn by name WITHOUT touching _G (mod fns are local +
// registry-only by M9 design; debug.getregistry() was the only door before
// this). Non-existent / non-function entries -> nil.
//   hoi4.get_effect("name") / hoi4.get_trigger("name") -> fn or nil
static int reg_get_impl(lua_State *Ls, const char *kind) {
    const char *name = luaL_checkstring(Ls, 1);
    reg_table(Ls, kind);
    lua_getfield(Ls, -1, name);              // [kind, value]
    if (!lua_isfunction(Ls, -1)) {
        lua_pop(Ls, 1);
        lua_pushnil(Ls);
    }
    lua_remove(Ls, -2);                      // drop kind table
    return 1;
}
int hoi4_get_effect(lua_State *Ls)   { return reg_get_impl(Ls, REG_TABLE_EFFECT); }
int hoi4_get_trigger(lua_State *Ls)  { return reg_get_impl(Ls, REG_TABLE_TRIGGER); }

// frame dispatch the route-B block calls). Must precede hoi4_lib.


