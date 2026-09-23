#include "hoi4_common.h"

// ---- engine machinery globals + name bridge + path APIs ----
typedef void *(*EngineNew_t)(size_t size);
EngineNew_t g_engNew;
void *(*g_factorySetGlobal)(void);
void (*g_engPush)(uint8_t *, void **);

// name bridge engine fn
void (*g_nameToKey)(int *, void *);        // (key_out, std::string*)

// ---------------------------------------------------------------- Lua side
// init runs on a background thread: DllMain holds the loader lock (APC inject),
// so heavy work (heap, file IO) must not happen there.
// 2026-08-27: LUA_SCRIPT removed — ALL Lua loads from mod dirs
// 2026-08-30 (F1-F3): flag API deleted — read side lives in hoi4_layout.lua
//   M.flags() / M.get_flag(name) (lexer token table based); write side goes
//   through console commands via hoi4.console("set_flag ...").
//   g_nameToKey stays for the hoi4.name_to_token bridge.
//   (g_L / g_luaLock live in hoi4_main.cpp; declared extern in hoi4_common.h.)

int hoi4_log(lua_State *Ls) {
    const char *s = luaL_checkstring(Ls, 1);
    L("[lua] %s", s);
    return 0;
}

// (F1-F3, 2026-08-30) hoi4_get_flag / hoi4_set_flag / hoi4_list_flags deleted,
// 2026-09-19 hoi4.flag_write deleted with its g_flagWrite engine hook:
// read side = hoi4_layout.lua M.flags()/M.get_flag(name); write side =
// console commands ("set_flag <tag> <name>"). g_nameToKey stays for
// hoi4.name_to_token (strview ABI: {char* data@0, u64 len@8} —
// FUN_1424a65a0 reads param_2 as data ptr and param_2[1] as length, NOT an
// MSVC std::string; that misread once caused key=0 / SEH faults).

