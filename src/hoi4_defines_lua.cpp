// hoi4_defines_lua.cpp — the `hoi4.*` surface over the defines image scan.
//
// Two entry points, for two different access patterns:
//
//   hoi4.define_lookup(name) -> rva | nil
//       One lookup, O(n) over the cached array. This is what M.define uses:
//       callers ask for a handful of names, and building a 4.4k-entry Lua
//       table to answer one of them would be pure waste.
//
//   hoi4.defines_build() -> table | nil, err
//       The whole map as `name -> rva`, for callers that want to iterate or
//       need the bulk shape (the L2 diff tool and the regression harness).
//       Charges its cost once, on demand.
//
// A failed scan returns nil plus a reason rather than an empty table: an empty
// table is indistinguishable from "the game genuinely has no defines", and
// that would silently turn every define lookup into a nil with no signal.

#include "hoi4_common.h"

// ---- hoi4_defines.cpp ------------------------------------------------------
int hoi4_defines_scan(void);
int hoi4_defines_count(void);
int hoi4_defines_at(int idx, const char **name, uint32_t *rva);
int hoi4_defines_lookup(const char *name, uint32_t *rva);

static const char *scan_reason(int rc) {
    switch (rc) {
    case -1: return "image headers unreadable (PE32+ expected)";
    case -2: return "allocation failed";
    case -3: return "loader diagnostics not found - refusing to guess";
    default: return "scan failed";
    }
}

// hoi4.define_lookup(name) -> rva (integer, ImageBase-relative) | nil
int hoi4_lua_define_lookup(lua_State *Ls) {
    const char *name = luaL_checkstring(Ls, 1);
    if (!name || !*name) { lua_pushnil(Ls); return 1; }

    int rc = hoi4_defines_scan();
    if (rc < 0) { lua_pushnil(Ls); return 1; }

    uint32_t rva = 0;
    if (!hoi4_defines_lookup(name, &rva)) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, (lua_Integer)rva);
    return 1;
}

// hoi4.defines_build() -> {name = rva} | nil, reason
int hoi4_lua_defines_build(lua_State *Ls) {
    int rc = hoi4_defines_scan();
    if (rc < 0) {
        lua_pushnil(Ls);
        lua_pushstring(Ls, scan_reason(rc));
        return 2;
    }
    lua_createtable(Ls, 0, 0);
    const char *name = NULL;
    uint32_t rva = 0;
    int n = hoi4_defines_count();
    for (int i = 0; i < n; i++) {
        if (!hoi4_defines_at(i, &name, &rva)) continue;
        lua_pushinteger(Ls, (lua_Integer)rva);
        lua_setfield(Ls, -2, name);
    }
    return 1;
}

// hoi4.defines_count() -> integer (-1 when the scan could not run)
int hoi4_lua_defines_count(lua_State *Ls) {
    int rc = hoi4_defines_scan();
    lua_pushinteger(Ls, rc < 0 ? -1 : rc);
    return 1;
}

// hoi4.define_targets(name) -> array of rva | nil
//
// A name may be registered into more than one namespace, and each namespace has
// its own storage — the two addresses are BOTH real, holding different values.
// define_lookup()/defines_build() return only the first, which is fine for
// existence checks but wrong for reading a specific namespace's value. Callers
// that need to disambiguate use this and pick by expected value range.
int hoi4_lua_define_targets(lua_State *Ls) {
    const char *name = luaL_checkstring(Ls, 1);
    if (!name || !*name) { lua_pushnil(Ls); return 1; }
    if (hoi4_defines_scan() < 0) { lua_pushnil(Ls); return 1; }

    uint32_t rvas[8];
    int n = hoi4_defines_targets(name, rvas, 8);
    if (n <= 0) { lua_pushnil(Ls); return 1; }
    lua_createtable(Ls, n, 0);
    for (int i = 0; i < n; i++) {
        lua_pushinteger(Ls, (lua_Integer)rvas[i]);
        lua_rawseti(Ls, -2, i + 1);
    }
    return 1;
}
