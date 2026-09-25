// hoi4_hook.h — mod-facing vtable-slot hook facility (Tier 1).
//
// WHAT THIS IS: replace / wrap / observe the execution of an EXISTING engine
// function that is reached through a vtable slot. The engine already calls
// through vtables for every virtual method, so swapping ONE data qword
// (vt[slot]) redirects every indirect call to that method — no code bytes are
// touched.
//
// WHY NOT function-body patching (Tier 2/3): the framework already paid for
// that lesson. hoi4_frame.cpp records it: the first idler hook patched the
// function body inline and crashed on the FIRST FRAME, dump-proven cause being
// that the stolen prologue contained `mov rax,rsp` while the body later
// re-derived rbp from rax — the trampoline's jump-back clobbered rax. The
// vtable-slot form has no such failure mode at all: the body stays
// byte-identical, the ABI is the compiler's problem (our thunk is an ordinary
// C function declared to match), and `origFn` is a CLEAN pointer that needs no
// trampoline. Uninstall is just writing the original qword back.
// Tier 2 (function-body detour) additionally needs an LDE that refuses
// RIP-relative operands and relative control flow — see hoi4_lde.h.
//
// GRANULARITY (the trap this design exists to make visible): a vtable slot hook
// is PER-CLASS. CEffect has 604 derived classes, each overriding [13] in its
// OWN vtable, and the BASE class vtable holds `_purecall` in those slots — so
// hooking a base vtable intercepts nothing and reports no error. The install
// gate below rejects _purecall/_guard_check_icall_nop targets for exactly this
// reason. To intercept a whole family, hook the SHARED DISPATCHER instead
// (effect/trigger routers are already hooked; see HK_EffectRouter).
//
// THREADING: Lua runs on the main thread only. A thunk executes on whatever
// thread the engine calls from. `sync` mode runs Lua inline when it is the main
// thread and the VM lock is obtainable; otherwise it FAILS OPEN (forwards the
// original, counts `dropped_off_thread`, does NOT run Lua) — a silent
// degradation to observe, which is why the counter is exposed and the first
// drop is logged. `observe` mode always snapshots args and defers to frame top;
// it can never influence the return value.
#pragma once
#include <stdint.h>
#include <windows.h>
#include "third-party/lua54/lua-5.4.7/src/lua.h"
#include "third-party/lua54/lua-5.4.7/src/lauxlib.h"

#ifdef __cplusplus
extern "C" {
#endif

// ---- limits (raise after measuring) ----
#define HK_MAX_HOOKS      64   // total registered hooks
#define HK_MAX_SLOTS      32   // distinct (vt,slot) CHAINS (not a slot number!)
#define HK_MAX_CHAIN       4   // hooks per chain (cross-mod coexistence)
#define HK_OBSERVE_QUEUE  64   // deferred observe events per frame
#define HK_ID_LEN         64

// Highest vtable slot index that may be hooked. This is NOT HK_MAX_SLOTS:
// engine vtables are large (CInGameIdler reaches slot[95], and slot numbers
// are just byte offsets /8), while the number of CHAINS we track is small.
// Conflating the two capped hookable slots at 31 and made the whole
// CInGameIdler pause/autosave slot family unreachable.
#define HK_MAX_SLOT_INDEX 512

// reserved engine slots the bridge itself owns — never hookable
// (currently only the idler frame hook; see install_v4_vtable_hook)
#define HK_RESERVED_SLOTS 1

// ---- mode / return-shape declarations ----
#define HK_MODE_SYNC     0    // inline on main thread; may change the result
#define HK_MODE_OBSERVE  1    // deferred to frame top; cannot change the result

#define HK_RET_U64       0    // return in rax (default)
#define HK_RET_VOID      1    // callee returns nothing; rax is garbage, ignored
#define HK_RET_BOOL      2    // low byte of rax meaningful

// dispatch outcome for one hook invocation (internal)
#define HK_ACT_REPLACE   0
#define HK_ACT_FORWARD   1
#define HK_ACT_ERROR     2

// ---- Lua-facing API (hoi4_hook.cpp) ----
int hoi4_hook_vt(lua_State *Ls);       // hoi4.hook_vt(vt, slot, fn, opts) -> handle|nil,err
int hoi4_unhook_vt(lua_State *Ls);     // hoi4.unhook_vt(id) -> true|nil,err
int hoi4_hook_list(lua_State *Ls);     // hoi4.hook_list() -> array of status tables
int hoi4_hook_status(lua_State *Ls);   // hoi4.hook_status(id) -> table|nil

// Drop the callback registry. Called from registry_clear on hot reload so a
// reloaded script's NEW closures are picked up (hooks themselves stay patched;
// resolution is by id on every call, exactly like the bind table).
void hooks_registry_clear(lua_State *Ls);

// ---- lifecycle hooks the rest of the bridge calls ----
// main-thread identity: captured on the first frame-hook entry (guaranteed to
// be the engine main thread). Without this, sync mode could not tell "inline is
// safe" from "must fail open".
void hook_note_main_thread(DWORD tid);
DWORD hook_main_tid(void);

// session switch: hooks are PROCESS-level (unaffected by gs lifetime) so they
// are KEPT, exactly like the bind table (2026-09-19 fix). Only the generation
// stamp and the pending observe queue are refreshed.
void hook_session_regen(void);

// frame-top consumer for MODE_OBSERVE events (main thread, g_luaLock held).
void hook_dispatch_observe(lua_State *Ls);

// diagnostics for the capacity log
int hook_count(void);
int hook_slot_count(void);

// Resolve a HOOK-FACILITY thunk back to the engine function it replaced.
//
// Used by the bridge's OWN memory-derived call sites (game_pause reads
// mgr->vt[+656], load_save reads app->vt[+880]). Those sites read a vtable slot
// to get a polymorphic implementation, then gate the result through
// memgate_exec_ok — which accepts only hoi4.exe executable sections. A slot we
// have hooked holds a bridge-DLL thunk, so it would be refused there.
//
// The answer is to BYPASS, not to widen: framework infrastructure must not be
// vetoable by the mod layer it hosts. Concretely, if a mod hook vetoed the
// pause issued by the export workflow, an export would run unpaused and break
// the "same-instant anchor" invariant that the whole save-comparison chain
// depends on. So these sites call the ORIGINAL
// implementation, exactly as they would have before the hook existed.
//
// Returns 1 and writes the original target to *out_orig when [addr] is one of
// our thunks; returns 0 (leaving *out_orig untouched) otherwise. memgate_exec_ok
// is deliberately NOT relaxed: the resolved original is engine code and passes
// it unchanged.
int hook_orig_for_thunk(uint64_t addr, uint64_t *out_orig);

#ifdef __cplusplus
}
#endif
