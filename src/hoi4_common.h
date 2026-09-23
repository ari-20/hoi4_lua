// hoi4_common.h - shared declarations for all hoi4_bridge modules.
// Split from the former single-file hoi4_reloader.cpp (2026-08-26 refactor).
#pragma once
#ifdef __cplusplus
extern "C" {   // F: hoi4_http_server.cpp consumes these with C linkage
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "third-party/lua54/lua-5.4.7/src/lua.h"
#include "third-party/lua54/lua-5.4.7/src/lauxlib.h"

// ---- image-relative addresses: runtime table, published from the compiled
// hoi4_offsets.h table (single source of truth, no companion file). A game
// update = edit that header + rebuild; the PE signature check refuses
// activation on any other build. Macro names are kept so call sites read
// exactly as before. Values: hoi4.exe 1.19.3.0 c01a3d50 (base 0x140000000).
typedef enum {
    OFF_FIND_CMD_BY_NAME = 0,
    OFF_EFFECT_ROUTER,
    OFF_ENGINE_NEW,
    OFF_SET_GLOBAL_FACTORY,
    OFF_VEC_PUSH_BACK,
    OFF_SGF_VTABLE,
    OFF_GAMESTATE_PTR,
    OFF_NAME_TO_KEY,
    OFF_LEXER_TOKEN_TABLE,
    OFF_LEXER_TOKEN_MAX,
    OFF_TRIGGER_ROUTER,
    OFF_GFT_FACTORY,
    OFF_GFT_VTABLE,
    OFF_INGAME_IDLER_V4,
    OFF_INGAME_IDLER_VTBL_SLOT4,
    OFF_ENGINE_ALLOC,          // engine allocator wrapper (alloc+retry)
    OFF_MGR_CTOR,              // console manager lazy ctor
    OFF_SET_SPEED,             // game speed setter (clamps 0..4)
    OFF_EVAL_VALUE,            // scripted-value evaluator
    OFF_LINE_INFO,             // trigger router line-info helper
    OFF_CONSOLE_MGR_SLOT,      // CConsoleCmdManager* global slot
    OFF_ENGINE_HEAP_HANDLE,    // engine allocator heap HANDLE*
    OFF_APP_MGR_PTR,           // application manager (pause path)
    OFF_ENGINE_TLSINDEX,       // ThreadForbidCount TLS slot index
    OFF_ASSERTS_BYTE,          // engine asserts-enable byte
    OFF_SESSION_CTOR_WRITE,    // gs slot = new gs  (write insn VA, session events)
    OFF_SESSION_DTOR_WRITE,    // gs slot = NULL   (write insn VA, session events)
    OFF_LOAD_ENTRY,            // in-game load-save entry (t99 sub_140DA04F0)
    OFF_SAVEDESC_CTOR,         // 224B saveDesc ctor (t99)
    OFF_SAVEDESC_DTOR,         // saveDesc dtor (t99)
    OFF_STRING_ASSIGN,         // std::string::assign(this, char*, len) (t99)
    OFF_SET_GAME_STARTED,      // SetGameStarted(gs,1) — session 门重开 (t100 修复 A)
    OFF_COUNT
} OffId;

extern uint64_t g_rva[OFF_COUNT];   // hoi4_offsets.cpp
int  offsets_load(void);            // publish table + verify image signature
const char *offsets_version(void);  // version string from the table

#define RVA_FIND_CMD_BY_NAME   (g_rva[OFF_FIND_CMD_BY_NAME])
#define RVA_EFFECT_ROUTER      (g_rva[OFF_EFFECT_ROUTER])
#define RVA_ENGINE_NEW         (g_rva[OFF_ENGINE_NEW])
#define RVA_SET_GLOBAL_FACTORY (g_rva[OFF_SET_GLOBAL_FACTORY])
#define RVA_VEC_PUSH_BACK      (g_rva[OFF_VEC_PUSH_BACK])
#define RVA_SGF_VTABLE         (g_rva[OFF_SGF_VTABLE])
#define RVA_GAMESTATE_PTR      (g_rva[OFF_GAMESTATE_PTR])
#define RVA_NAME_TO_KEY        (g_rva[OFF_NAME_TO_KEY])
#define RVA_LEXER_TOKEN_TABLE  (g_rva[OFF_LEXER_TOKEN_TABLE])
#define RVA_LEXER_TOKEN_MAX    (g_rva[OFF_LEXER_TOKEN_MAX])
#define RVA_TRIGGER_ROUTER     (g_rva[OFF_TRIGGER_ROUTER])
#define RVA_GFT_FACTORY        (g_rva[OFF_GFT_FACTORY])
#define RVA_GFT_VTABLE         (g_rva[OFF_GFT_VTABLE])
#define RVA_INGAME_IDLER_V4          (g_rva[OFF_INGAME_IDLER_V4])
#define RVA_INGAME_IDLER_VTBL_SLOT4  (g_rva[OFF_INGAME_IDLER_VTBL_SLOT4])
#define RVA_ENGINE_ALLOC       (g_rva[OFF_ENGINE_ALLOC])
#define RVA_MGR_CTOR           (g_rva[OFF_MGR_CTOR])
#define RVA_SET_SPEED          (g_rva[OFF_SET_SPEED])
#define RVA_EVAL_VALUE         (g_rva[OFF_EVAL_VALUE])
#define RVA_LINE_INFO          (g_rva[OFF_LINE_INFO])
#define RVA_CONSOLE_MGR_SLOT   (g_rva[OFF_CONSOLE_MGR_SLOT])
#define RVA_ENGINE_HEAP_HANDLE (g_rva[OFF_ENGINE_HEAP_HANDLE])
#define RVA_APP_MGR_PTR        (g_rva[OFF_APP_MGR_PTR])
#define RVA_ENGINE_TLSINDEX    (g_rva[OFF_ENGINE_TLSINDEX])
#define RVA_ASSERTS_BYTE       (g_rva[OFF_ASSERTS_BYTE])
#define RVA_SESSION_CTOR_WRITE (g_rva[OFF_SESSION_CTOR_WRITE])
#define RVA_SESSION_DTOR_WRITE (g_rva[OFF_SESSION_DTOR_WRITE])
#define RVA_LOAD_ENTRY         (g_rva[OFF_LOAD_ENTRY])
#define RVA_SAVEDESC_CTOR      (g_rva[OFF_SAVEDESC_CTOR])
#define RVA_SAVEDESC_DTOR      (g_rva[OFF_SAVEDESC_DTOR])
#define RVA_STRING_ASSIGN      (g_rva[OFF_STRING_ASSIGN])
#define RVA_SET_GAME_STARTED   (g_rva[OFF_SET_GAME_STARTED])

// data-global address macros (image RVAs, same table)
#define ENGINE_HEAP_HANDLE RVA_ENGINE_HEAP_HANDLE
#define CONSOLE_MGR_SLOT   RVA_CONSOLE_MGR_SLOT
#define APP_MGR_PTR        RVA_APP_MGR_PTR

// ---- guarded memory reads (shared) ----
// SEH catches page faults; caller checks the sentinel. Prefer these over
// open-coded __try/__except pairs per module.
static __forceinline uint64_t h4_rd64(uint64_t a, uint64_t dflt) {
    __try { return *(volatile uint64_t *)a; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return dflt; }
}
static __forceinline uint32_t h4_rd32(uint64_t a, uint32_t dflt) {
    __try { return *(volatile uint32_t *)a; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return dflt; }
}
static __forceinline uint8_t h4_rd8(uint64_t a, uint8_t dflt) {
    __try { return *(volatile uint8_t *)a; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return dflt; }
}

// ---- struct-member offsets (OBJECT LAYOUT, not image addresses) ----
// These are version-stable across hotfixes and belong to the layout-knowledge
// domain; they stay compile-time. Image addresses live in the table above.
#define GS_COUNTRIES_ARRAY 0x310
#define GS_COUNTRIES_COUNT 0x31C
#define GS_STATES_ARRAY    0x2C8
#define GS_STATES_COUNT    0x2D4
#define GS_PROVINCES_ARRAY 0x2B0
#define GS_PROVINCES_COUNT 0x2BC
#define GS_SPEED           0x4BC
#define GS_GAME_HOUR       0x468
#define GS_GLOBAL_VARS     0x980
#define GS_UNIQUE_ID       0x728
#define MGR_PAUSE_FLAG     1729        // paused byte, object = CInGameIdler
                                       // (APP_MGR_PTR slot holds it; vtable
                                       // RVA 0x2968FF0). Live-verified 1.19.3:
                                       // 1 while paused, 0 while running.
#define MGR_PAUSE_PENDING  1731        // companion pending-press bit; armed
                                       // after engine-internal loads, the
                                       // pause setter short-circuits while set

// ---- logging (defined in hoi4_main.cpp) ----
extern HANDLE g_log;
void L(const char *fmt, ...);

// Verbose per-call logs (effect vtable slot traces) gate, defined in
// hoi4_main.cpp. 1 = print, 0 = suppress. Resolved lazily on first query from
// the host command line (`-debug`) or env HOI4_DLL_DEBUG=1, then cached.
int dll_debug_mode(void);
// hoi4.debug() -> bool (defined in hoi4_main.cpp next to dll_debug_mode)
int hoi4_debug(lua_State *Ls);

// game directory as UTF-8 (defined in hoi4_paths.cpp; "" before path resolution)
const char *game_dir_utf8(void);
// deferred log adoption (paths.cpp/main.cpp): open <user>/logs/hoi4_bridge.log
void log_open_in_logs_dir(void);
void log_ring_flush_and_adopt(HANDLE h);

// ---- shared globals (defined in their owning module, declared here) ----
extern uint8_t *g_base;            // game module base (hoi4.exe)
extern lua_State *g_L;      // main embedded VM
extern void *g_mgr;                // CConsoleCmdManager* (captured on first FindCommandByName)
extern SRWLOCK g_luaLock;         // serializes ALL main-state Lua access
extern DWORD g_luaOwner;          // recursion-aware lock bookkeeping
extern unsigned g_luaDepth;
extern volatile LONG g_initialized;  // set once lua_init_thread finished (P5)

// console_invoke_core (hoi4_console.cpp): engine command invocation shared by
// the Lua bridge and the IPC executor. Main thread only.
int console_invoke_core(const char *cmd, char *out, size_t cap_out);

// E (batch 2026-09-12): execute a Lua chunk in the main VM, main thread,
// recursion-aware lock. Shared by the `lua` pseudo command and future HTTP.
int lua_exec_chunk(const char *chunk, char *out, size_t cap_out);

// D1 (batch 2026-09-12): scope-context accessors (hoi4_scope.cpp)
int hoi4_scope_country(lua_State *Ls);
int hoi4_scope_state_id(lua_State *Ls);
int hoi4_eval_value(lua_State *Ls);

// H (batch 2026-09-12): game control (hoi4_game.cpp)
int hoi4_game_speed(lua_State *Ls);
int hoi4_game_set_speed(lua_State *Ls);
int hoi4_game_pause(lua_State *Ls);

// async_api.inc: frame-heartbeat callback dispatch (main thread, g_luaLock held)
void async_dispatch_locked(lua_State *Ls);

// ---- cross-module exports (refactor 2026-08-26) ----
// paths.cpp
int load_mod_lua_scripts(lua_State *Ls);
int resolve_game_data_path(void);
int get_game_dir(void);
// registry (hoi4_main.cpp keeps the snapshot; clear lives here)
void registry_clear(lua_State *Ls);
void snapshot_names_locked(void);
void maybe_reload_locked(void);          // main file (hot reload core; detect-only)
void reload_execute_locked(void);        // main file (executes a pending reload; frame-boundary only)
void lua_call_effect(const char *fn, void *self, uint64_t ctx);
// bridge.cpp engine machinery pointers
typedef void *(*EngineNew_t)(size_t size);
extern EngineNew_t g_engNew;
extern void *(*g_factorySetGlobal)(void);
extern void (*g_engPush)(uint8_t *, void **);
extern void (*g_nameToKey)(int *, void *);
extern void *(*g_factoryGFT)(void);
// vtable.cpp
const char *bind_lookup(void *obj);
// timer/async dispatch
#include "third-party/lua54/lua-5.4.7/src/lua.h"
#include "third-party/lua54/lua-5.4.7/src/lauxlib.h"

// registry kind names (string literals shared by all modules)
#define REG_TABLE_EFFECT  "effects"
#define REG_TABLE_TRIGGER "triggers"

int watch_add_file(const char *path);       // main.cpp: C-side watch registration (lua loader)

void lua_init_thread(void *unused);        // main file
void async_dispatch_locked(lua_State *Ls);
void timer_dispatch_locked(unsigned long long now);   // timer.cpp: frame dispatch
void timers_clear_locked(void);                        // timer.cpp: hot-reload reset

// async status codes (async.cpp task status)
#define IPC_ST_PENDING          0
#define IPC_ST_OK               1

// ---- Lua bridge exports (defined across modules) ----
int hoi4_after(lua_State *Ls);
int hoi4_async_cancel(lua_State *Ls);
int hoi4_async_exec(lua_State *Ls);
int hoi4_async_poll(lua_State *Ls);
int hoi4_async_status(lua_State *Ls);
int hoi4_base(lua_State *Ls);
int hoi4_console(lua_State *Ls);
int hoi4_effect_reg(lua_State *Ls);
int hoi4_get_effect(lua_State *Ls);
int hoi4_get_trigger(lua_State *Ls);
int hoi4_every(lua_State *Ls);
int hoi4_every_cancel(lua_State *Ls);
int hoi4_game_dir(lua_State *Ls);
int hoi4_log(lua_State *Ls);
int hoi4_logs_dir(lua_State *Ls);
int hoi4_mods_json(lua_State *Ls);
int hoi4_read_cstr(lua_State *Ls);
int hoi4_read_f32(lua_State *Ls);
int hoi4_read_f64(lua_State *Ls);
int hoi4_read_mod_descriptor(lua_State *Ls);
int hoi4_read_dir(lua_State *Ls);
// outbound HTTP(S) via cpp-httplib + mbedTLS (hoi4_http_client.cpp) — one
// HTTP stack for both directions (server = hoi4_http_server.cpp). Callable
// on ANY thread (async workers included: no game memory touched) but BLOCKS
// the caller — from gameplay code always go through async_exec.
// hoi4_register_http() attaches http_request to an arbitrary lua_State
// (worker states are bare).
int hoi4_http_request(lua_State *Ls);
void hoi4_register_http(lua_State *Ls);
int hoi4_read_u64(lua_State *Ls);
int hoi4_read_str(lua_State *Ls);
int hoi4_read_bytes(lua_State *Ls);
int hoi4_read_u16(lua_State *Ls);
int hoi4_read_u8(lua_State *Ls);
int hoi4_read_u32(lua_State *Ls);
int hoi4_save_dir(lua_State *Ls);
int hoi4_timers_count(lua_State *Ls);
int hoi4_to_number(lua_State *Ls);
int hoi4_trigger_reg(lua_State *Ls);
int hoi4_user_data_dir(lua_State *Ls);
int hoi4_watch(lua_State *Ls);
int hoi4_write_f32(lua_State *Ls);
int hoi4_write_f64(lua_State *Ls);
int hoi4_write_str(lua_State *Ls);
int hoi4_write_u8(lua_State *Ls);
int hoi4_write_u16(lua_State *Ls);
int hoi4_write_u32(lua_State *Ls);
int hoi4_write_u64(lua_State *Ls);

// hook thunks (console.cpp / vtable.cpp) — referenced by install_hooks in hooks.cpp
typedef void *(__fastcall *FindCmd_t)(void *, void *);
extern FindCmd_t g_origFind;
typedef void (__fastcall *Router_t)(uint64_t, uint64_t, int, int);          // effect router
typedef void (__fastcall *TRouter_t)(uint64_t, uint64_t, uint64_t, int);    // trigger router
extern Router_t  g_origRouter;
extern TRouter_t g_origTRouter;
void *__fastcall HK_FindCommandByName(void *mgr, void *nameStr);
void __fastcall HK_EffectRouter(uint64_t p1, uint64_t p2, int token, int scope);
void __fastcall HK_TriggerRouter(uint64_t p1, uint64_t p2, uint64_t token, int scope);
void build_my_tvt(void);
void build_my_vtable(void);
void install_v4_vtable_hook(void);   // routeb.cpp

// registry/snapshot + lock helpers (hoi4_main.cpp / hoi4_registry.cpp)
void reg_table(lua_State *Ls, const char *kind);
void lua_lock(void);
void lua_unlock(void);
int trigger_known(const char *n);
int effect_known(const char *n);

// ---- session lifecycle (hoi4_session.cpp / integrated 2026-09-12, batch B) --
void session_hooks_install(void);            // lua_init_thread tail, once (DR hooks)
void session_dispatch_locked(lua_State *Ls); // frame-top consumer; lock held
void force_reload_locked(void);              // main.cpp: unconditioned full reload
int  bind_count(void);                    // vtable.cpp: occupancy for the capacity log
void bind_table_regen(void);                // vtable.cpp: keep + re-stamp binds (2026-09-19 fix)
void bind_note_session_end(void);            // vtable.cpp: bump bind generation
void async_session_reset(void);              // async.cpp: orphan all in-flight work
void session_note_frame(void);               // session.cpp: frame tick heartbeat
int  session_in_game(void);                  // session.cpp: gs != 0 AND frame alive

// G (batch 2026-09-12): guarded engine call + write wrappers (hoi4_call.cpp)
int hoi4_call_u64(lua_State *Ls);
int hoi4_call_void(lua_State *Ls);
int hoi4_engine_alloc(lua_State *Ls);
int hoi4_engine_free(lua_State *Ls);
int hoi4_name_to_token(lua_State *Ls);
int hoi4_load_save(lua_State *Ls);

// ---- defines image scan (hoi4_defines.cpp / hoi4_defines_lua.cpp) ----------
// The engine registers each define as `lea r8,[target]; lea rdx,[name];
// lea rcx,[ctx]; call loader`, so the name->address map is recoverable from
// the image bytes in-process: no data file, no per-version regeneration.
int hoi4_defines_scan(void);
int hoi4_defines_count(void);
int hoi4_defines_at(int idx, const char **name, uint32_t *rva);
int hoi4_defines_lookup(const char *name, uint32_t *rva);
int hoi4_defines_targets(const char *name, uint32_t *out, int cap);
int hoi4_lua_define_lookup(lua_State *Ls);
int hoi4_lua_define_targets(lua_State *Ls);
int hoi4_lua_defines_build(lua_State *Ls);
int hoi4_lua_defines_count(lua_State *Ls);

// ---- hardening: stdlib reduction + path policy + audit (2026-09-21) ----
// hoi4_harden.cpp: subtractive stdlib reduction (os.execute/os.exit/os.tmpname/
// os.setlocale/os.getenv, io.popen/io.tmpfile, package, require) and a `debug`
// table narrowed to getinfo+traceback. MUST run after luaL_openlibs and BEFORE
// any mod script, on BOTH the main VM and each async worker VM (the worker is a
// bare lua_State with full base libs, so an unhardened worker is a bypass).
void lua_harden_libs(lua_State *Ls);
// hoi4_lua_policy.cpp: path-scoped file access. Installed on the same states.
void lua_policy_install(lua_State *Ls);
void lua_policy_add_root(const char *utf8_dir);   // idempotent; one per mod
void lua_policy_register_save_dir(void);
// hoi4_audit.cpp: external-boundary audit log (net / file access / code load),
// per-target deduplicated, with per-mod attribution. Detection layer for the
// game-memory surface that no sandbox can constrain.
void audit_init_config(void);                     // env HOI4_AUDIT / -audit=
void audit_open(const char *dir_utf8);            // append, rotates
void audit_session_start(const char *game_build, const char *bridge_ver);
void audit_session_end(void);
void audit_fs(lua_State *Ls, const char *op, const char *path, int denied,
              const char *reason);
void audit_net(lua_State *Ls, const char *method, const char *host, int port,
               const char *scheme, long long bytes_out, int status,
               long long bytes_in);
void audit_code_load(lua_State *Ls, const char *path, const char *sha256_hex);
void audit_bump(lua_State *Ls, const char *cls);
void audit_read_tick(lua_State *Ls);
void audit_attribute(lua_State *Ls, char *out, size_t cap, int *line);
int  audit_level_get(void);
void audit_level_set(int l);
int  audit_distinct_count(void);

// hoi4_paths.cpp accessors the security modules need (avoid duplicating the
// userdir resolution in three places).
const wchar_t *save_dir_w(void);
const char *logs_dir_utf8(void);

// H helpers (hoi4_game.cpp): plain-C invokables for the HTTP module
int  game_pause_invoke(int state);               // 1 on call, 0 on failure
int  game_speed_read(void);                      // -1 if no gamestate
int  game_paused_read(void);                     // CInGameIdler+MGR_PAUSE_FLAG; -1 if no manager

// F (batch 2026-09-12): local HTTP service (hoi4_http_server.cpp)
void http_maybe_autostart(void);                 // cmdline -http[=port] scan
int  http_poll_main(int max_requests);           // frame-top executor (lock held)
void http_push_event(const char *name, const char *payload);  // SSE fan-out

#ifdef __cplusplus
}
#endif
