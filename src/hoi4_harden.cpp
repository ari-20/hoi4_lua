// hoi4_harden.cpp - standard-library surface reduction for mod Lua.
//
// Threat: mod Lua is untrusted (README "Safety"), yet luaL_openlibs hands every
// mod the full standard library. Two classes of it are strictly worse than the
// game-memory primitives the framework exists to provide:
//
//   os.execute / io.popen   arbitrary command execution as the current user.
//                           hoi4.write_u64 can break the game; this can break
//                           the machine.
//   debug.*                 universal sandbox escape. getregistry reaches the
//                           registry table (C closures, _LOADED); getupvalue /
//                           setupvalue reach into any closure's upvalues, which
//                           is how a wrapper installed by hoi4_lua_policy is
//                           unwrapped.
//
// A handful of members are dangerous without executing anything at all:
// os.setlocale mutates the WHOLE PROCESS's C locale (the engine parses numbers
// and strings through it), so it goes regardless of who wants it.
//
// Reduction is subtractive - luaL_openlibs stays in charge of library
// construction and load order (its internal cross-library dependencies are
// upstream's business), and this module only removes. That is deliberate: a
// hand-rolled whitelist has to re-derive which libraries depend on which, and
// gets it wrong silently.
//
// Declared removed by the shipped mods (verified by grep over mods/):
//   os.execute 0  os.exit 0  os.tmpname 0  os.setlocale 0  os.getenv 0
//   io.popen only in comments ("旧版 io.popen('dir /b') ... 已弃用")
//   io.tmpfile 0  package 0  require 0  coroutine 0
//   debug.* -> getinfo only (18 sites, all the defensive
//             "debug and debug.getinfo" SELF_DIR idiom)
//
// CAUTION - two properties of this file are load-bearing and must not be
// "tidied up" later:
//   1. It must run BEFORE any mod script executes (see lua_harden_state's
//      callers). A mod that runs first can capture an unwrapped reference.
//   2. The main VM *and* the async worker VM must both go through
//      lua_harden_state(). The worker is a bare lua_State with full base libs,
//      so it has its own dofile/loadfile; hardening only the main VM leaves
//      that path open.

#include "hoi4_common.h"

// ---------------------------------------------------------------- primitives

// Removes t[name] entirely.
static void strip_field(lua_State *Ls, const char *tbl, const char *name) {
    lua_getglobal(Ls, tbl);
    if (!lua_istable(Ls, -1)) { lua_pop(Ls, 1); return; }
    lua_pushnil(Ls);
    lua_setfield(Ls, -2, name);
    lua_pop(Ls, 1);
}

// Removes the global table itself (package, require).
static void strip_global(lua_State *Ls, const char *name) {
    lua_pushnil(Ls);
    lua_setglobal(Ls, name);
}

// ------------------------------------------------------------- library strip

// (table, member) pairs. Kept as data so the policy is readable in one place
// and so the test harness can assert against the same list.
static const char *kStrip[][2] = {
    // os: process control, environment leakage, process-global state.
    { "os", "execute"   },   // RCE - the single worst entry in the library
    { "os", "exit"      },   // terminates hoi4.exe; an autosave mid-frame can
                             // leave a truncated save
    { "os", "tmpname"   },   // synthesises writable paths = filesystem probe
    { "os", "setlocale" },   // mutates the WHOLE PROCESS C locale; the engine
                             // parses through it, so this is a correctness bug
                             // even when nothing malicious is intended
    { "os", "getenv"    },   // environment leakage (tokens, API keys)

    // io: process spawning and writes that dodge the path policy.
    { "io", "popen"     },   // RCE, same class as os.execute
    { "io", "tmpfile"   },   // creates a REAL file in %TEMP%, bypassing
                             // hoi4_lua_policy entirely
    { NULL, NULL }
};

// Whole-library removals.
static const char *kStripLibs[] = {
    "package",   // loadlib loads arbitrary DLLs; the mod loader never uses it
    "require",   // reaches the filesystem via package.searchers (and hoi4's
                 // package.path only holds the game dir); unused by the mods
    NULL
};

static void strip_libs(lua_State *Ls) {
    for (int i = 0; kStrip[i][0]; i++) strip_field(Ls, kStrip[i][0], kStrip[i][1]);
    for (int i = 0; kStripLibs[i]; i++) strip_global(Ls, kStripLibs[i]);
}

// --------------------------------------------------------------- debug strip

// Rebuilds `debug` from the ORIGINAL C functions, keeping only the two members
// that cannot touch upvalues, the registry, or stack variables:
//
//   getinfo    read-only frame metadata. 18 mod sites derive SELF_DIR from
//              debug.getinfo(1,"S").source - this member is a hard
//              compatibility requirement, not a nicety.
//   traceback  formats a stack trace; no escape surface.
//
// Everything else goes, including getmetatable/setmetatable (shared metatables
// = whole-library corruption) and getupvalue/setupvalue (unwraps the policy).
// The originals are captured BEFORE the table is replaced, then dropped - a
// rebuilt table holds only the two whitelisted C functions.
static void narrow_debug(lua_State *Ls) {
    lua_getglobal(Ls, "debug");
    if (!lua_istable(Ls, -1)) { lua_pop(Ls, 1); return; }

    lua_getfield(Ls, -1, "getinfo");
    lua_CFunction gi = lua_iscfunction(Ls, -1) ? lua_tocfunction(Ls, -1) : NULL;
    lua_pop(Ls, 1);

    lua_getfield(Ls, -1, "traceback");
    lua_CFunction tb = lua_iscfunction(Ls, -1) ? lua_tocfunction(Ls, -1) : NULL;
    lua_pop(Ls, 1);

    lua_pop(Ls, 1);                  // old debug table - MUST pop, else the new
                                     // table lands on top of it and setglobal
                                     // publishes the wrong value
    lua_newtable(Ls);
    if (gi) { lua_pushcfunction(Ls, gi); lua_setfield(Ls, -2, "getinfo"); }
    if (tb) { lua_pushcfunction(Ls, tb); lua_setfield(Ls, -2, "traceback"); }
    lua_setglobal(Ls, "debug");
}

// -------------------------------------------------------------- public entry

// Installs the reduced library surface on a state.
//
// Order matters: strip first, then narrow debug. The path policy
// (hoi4_lua_policy.cpp) is installed by its own entry point afterwards, so this
// module stays free of that dependency and either can be tested alone.
void lua_harden_libs(lua_State *Ls) {
    if (!Ls) return;
    strip_libs(Ls);
    narrow_debug(Ls);
#if defined(HOI4_HARDEN_VERBOSE)
    L("[harden] stdlib surface reduced (os/io/package/debug)");
#endif
}
