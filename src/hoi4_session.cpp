// hoi4_session.cpp — session lifecycle: precise ctor/dtor write detection.
//
// Engine fact (1.19.3 c01a3d50, write-scan verified — tools/scan_gs_writers.py):
// the gs singleton slot (RVA_GAMESTATE_PTR) has EXACTLY TWO writers:
//   ctor path: mov [slot], rax   (RVA OFF_SESSION_CTOR_WRITE)  -> session START
//   dtor path: mov [slot], 0     (RVA OFF_SESSION_DTOR_WRITE)  -> session END
// Session events = DR hardware execution breakpoints on those two
// instructions (no code patching, no prologue risk, main-thread only).
//
// ⚠ Coverage note (2026-09-19 live test): the writes fire only at the FIRST
// session creation of the process. Menu round trips and in-game save loads
// do NOT rewrite the slot (no dtor/ctor event) and do NOT re-parse routed
// effects — the engine rebuilds the world in place and keeps shells + binds
// alive, so routed effects keep working across them (verified: slot calls
// continue). Per-load cleanup, if ever needed, must hook the engine's own
// load path (OFF_LOAD_ENTRY), not this slot.
//
// This design replaced the 150ms gs/uid polling watcher. The
// polling design needed G1/G2 heuristics to survive game_unique_id churn
// during loads (regenerated several times per load, same gs pointer), which
// cost a 60s blind window right after every session start, spurious menu
// STARTs, and — via the bind-generation GC race it created — silently killed
// every routed effect on same-pointer session switches (the "reload save
// breaks all features" bug). Hardware events need none of that:
//   - pointer reuse is irrelevant (the write itself is the event),
//   - uid churn is irrelevant (no uid is read at all),
//   - all events raised during a load coalesce: they are consumed as ONE
//     end+start dispatch at the next in-game frame.
//
// Threading:
//   the two write instructions execute on the game main thread; dr_veh runs
//   in that thread's exception context and only sets transition flags.
//   consumer: session_dispatch_locked() at frame top (g_luaLock held) —
//   sequence at the first in-game frame of the new session:
//       on_session_end -> cleanup (timers/async/binds/regen) -> forced
//       reload -> on_session_start
//
// Limits: DRs are installed once onto all threads existing at init time
// (the game main thread is one of them and is the only writer). If a future
// engine build moves the writes to a thread created later, re-arm would be
// needed — the transition log going silent on a known switch is the tell.

#include "hoi4_common.h"
#include "hoi4_hook.h"
#include <tlhelp32.h>

static volatile LONG g_evEnd;
static volatile LONG g_evStart;

// in-game load-save entry (OFF_LOAD_ENTRY): an in-game load
// rebuilds the world WITHOUT destroying the gs (no ctor/dtor write fires) —
// from the mod side it is still a full switch (fresh world, stale script
// env), so its event sets END+START to run the same cleanup. RVA 0 = disabled.
static LONG WINAPI dr_veh(EXCEPTION_POINTERS *ep) {
    if (!g_base) return EXCEPTION_CONTINUE_SEARCH;
    uint64_t rip = ep->ContextRecord->Rip;
    uint64_t ctorA = (uint64_t)(uintptr_t)g_base + RVA_SESSION_CTOR_WRITE;
    uint64_t dtorA = (uint64_t)(uintptr_t)g_base + RVA_SESSION_DTOR_WRITE;
    if (rip == ctorA) {
        InterlockedExchange(&g_evStart, 1);
        L("[session] ctor write -> START");
    } else if (rip == dtorA) {
        InterlockedExchange(&g_evEnd, 1);
        L("[session] dtor write -> END");
    } else if (RVA_LOAD_ENTRY != 0 &&
               rip == (uint64_t)(uintptr_t)g_base + RVA_LOAD_ENTRY) {
        // in-place load: same cleanup as a switch (coalesced at first frame)
        InterlockedExchange(&g_evEnd, 1);
        InterlockedExchange(&g_evStart, 1);
        L("[session] load entry -> END+START (in-place load)");
    } else {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    ep->ContextRecord->EFlags |= 0x10000;      // RF: execute insn once on resume
    ep->ContextRecord->Dr6 = 0;
    return EXCEPTION_CONTINUE_EXECUTION;
}

static BOOL set_thread_dr(HANDLE hThread, uint64_t ctor, uint64_t dtor,
                          uint64_t loadA) {
    CONTEXT c;
    memset(&c, 0, sizeof(c));
    c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
    if (!GetThreadContext(hThread, &c)) return FALSE;
    c.Dr0 = ctor;
    c.Dr1 = dtor;
    c.Dr7 = (c.Dr7 & ~0xFF0000ull) | 0x5;      // L0|L1, RW=00 exec, LEN=00 1B
    if (loadA) {
        c.Dr2 = loadA;
        c.Dr7 = (c.Dr7 & ~0x3000000ull) | 0x10; // L2 (+ clear RW2/LEN2)
    }
    return SetThreadContext(hThread, &c) ? TRUE : FALSE;
}

void session_hooks_install(void) {
    if (!g_base) return;
    if (!RVA_SESSION_CTOR_WRITE || !RVA_SESSION_DTOR_WRITE) {
        L("[session] ctor/dtor write addresses zero — session events disabled");
        return;
    }
    if (!AddVectoredExceptionHandler(1, dr_veh)) {
        L("[session] VEH register FAILED — session events disabled");
        return;
    }
    uint64_t ctorA = (uint64_t)(uintptr_t)g_base + RVA_SESSION_CTOR_WRITE;
    uint64_t dtorA = (uint64_t)(uintptr_t)g_base + RVA_SESSION_DTOR_WRITE;
    uint64_t loadA = (RVA_LOAD_ENTRY != 0)
                         ? (uint64_t)(uintptr_t)g_base + RVA_LOAD_ENTRY : 0;

    // arm every existing thread; the game main thread (the only writer) is
    // among them. The current init thread gets the no-suspend path.
    DWORD pid = GetCurrentProcessId();
    DWORD self = GetCurrentThreadId();
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    int n = 0;
    if (snap != INVALID_HANDLE_VALUE) {
        THREADENTRY32 te;
        te.dwSize = sizeof(te);
        if (Thread32First(snap, &te)) {
            do {
                if (te.th32OwnerProcessID != pid) continue;
                if (te.th32ThreadID == self) continue;
                HANDLE h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT |
                                      THREAD_SET_CONTEXT, FALSE, te.th32ThreadID);
                if (!h) continue;
                DWORD sc = SuspendThread(h);
                if (sc != (DWORD)-1) {
                    if (set_thread_dr(h, ctorA, dtorA, loadA)) n++;
                    ResumeThread(h);
                }
                CloseHandle(h);
            } while (Thread32Next(snap, &te));
        }
        CloseHandle(snap);
    }
    set_thread_dr(GetCurrentThread(), ctorA, dtorA, loadA);
    L("[session] DR hooks armed on %d thread(s): ctor=%llx dtor=%llx load=%s",
      n, (unsigned long long)ctorA, (unsigned long long)dtorA, loadA ? "armed" : "off");
}

// -+ idler-edge session events (menu round-trip coverage, 2026-09-26)
// The DR breakpoints above only fire on the process's FIRST session
// creation: "quit to menu -> new game / load save" rebuilds the world IN
// PLACE without rewriting the gs slot (coverage note above), so mod Lua
// state survived across worlds with no event — the disable_supply knife
// swallowed the new world's build-time UpdateSupply and the engine read a
// never-built supply table (crash 2026-09-26 x6, archive/t93_crash/).
//
// The engine DOES switch idlers for that transition: CInGameIdler <->
// CFrontEndIdler via SetIdler sub_14222EA60 (writes graphics+112, then the
// main loop calls the new idler's vtable slot4 every frame — f05/f09
// findings). Both idlers' slot4 are now hooked (hoi4_frame.cpp) and each
// hook records here which idler is alive:
//   edge front-end -> in-game  = entering the game  -> START flag
//   edge in-game -> front-end  = quit to menu       -> END+START flags
// The merged END+START dispatch (cleanup + script reload + session
// callbacks) then runs on the FIRST MENU FRAME — BEFORE the next world is
// built, so mod state resets in time for the build calls to pass through.
static volatile LONG g_idlerState;      // 0=boot, 1=in-game, 2=front-end
void session_note_idler_ingame(void) {
    LONG st = g_idlerState;
    if (st == 2) {
        InterlockedExchange(&g_evStart, 1);
        L("[session] idler edge: front-end -> in-game (entering game)");
    }
    g_idlerState = 1;
}
void session_note_idler_frontend(void) {
    LONG st = g_idlerState;
    if (st == 1) {
        InterlockedExchange(&g_evEnd, 1);
        InterlockedExchange(&g_evStart, 1);
        L("[session] idler edge: in-game -> front-end (quit to menu)");
    }
    g_idlerState = 2;
}

// -+ session-switch PENDING flag (Lua-facing)
// True from the moment a session-switch event is raised (gs slot write /
// load entry / idler edge) until the frame-top dispatch consumes it. A
// world rebuild runs INSIDE that window (the in-place load rebuilds
// synchronously within sub_140DA04F0; a menu round trip rebuilds on
// front-end frames before the next entry). Mod detour callbacks that
// swallow engine functions must let the call through while this is true —
// the build-time invocations are the ones that construct the runtime
// tables (crash 2026-09-26: swallowed UpdateSupply -> null supply table).
// This is event semantics (the DR breakpoints already proved the entry),
// NOT a heuristic fingerprint.
int session_pending(void) {
    return (g_evEnd || g_evStart) ? 1 : 0;
}

// -+ "in game NOW" signal (HTTP /health session_active)
// gs != 0 alone is NOT enough: the MAIN MENU keeps a frontend gamestate
// (hour frozen, valid uid — observed 2026-09-12), so gs != 0 alone is true in
// menu. The in-game frame hook (CInGameIdler slot4) is the only thing that
// never runs in menu/loading, so "frame seen recently" is the ground truth.
// Paused games still tick frames, so this stays true while paused.
static volatile ULONGLONG g_lastFrameTickMs;
void session_note_frame(void) { g_lastFrameTickMs = GetTickCount64(); }
int session_in_game(void) {
    if (!g_base) return 0;
    uint64_t gs = *(volatile uint64_t *)((uint8_t *)g_base + RVA_GAMESTATE_PTR);
    if (!gs) return 0;
    ULONGLONG last = g_lastFrameTickMs;
    return last && (GetTickCount64() - last) < 3000;   // ~180 frames of slack
}

// call a Lua global fn(name) if defined; errors logged, never fatal.
static void session_call_lua(lua_State *Ls, const char *fn) {
    if (!Ls) return;
    lua_getglobal(Ls, fn);
    if (lua_isfunction(Ls, -1)) {
        if (lua_pcall(Ls, 0, 0, 0) != LUA_OK) {
            L("[session] %s error: %s", fn,
              lua_tostring(Ls, -1) ? lua_tostring(Ls, -1) : "?");
            lua_pop(Ls, 1);
        }
    } else {
        lua_pop(Ls, 1);                      // not defined: fine, contract is opt-in
    }
}

// frame-top consumer (g_luaLock held, main thread, shallow stack). Events
// raised during a load coalesce here into ONE end+start dispatch.
// in_game_frame: which idler is dispatching — the FE twin hook (menu /
// loading frames) passes 0, the in-game tick passes 1. The HasGameStarted
// re-arm below must NOT run on menu frames: a quit-to-menu round trip
// dispatches here BEFORE the next world is built, and the gate re-arms
// only after the world exists (first IN-GAME frame, same timing as the
// load_save in-place path).
void session_dispatch_locked(lua_State *Ls, int in_game_frame) {
    if (!g_evEnd && !g_evStart) return;      // fast path: one relaxed read each
    int end = InterlockedExchange(&g_evEnd, 0);
    int start = InterlockedExchange(&g_evStart, 0);

    if (end) {
        // old script environment still live here (reload has not run yet)
        L("[session] dispatch on_session_end");
        http_push_event("session_end", NULL);
        session_call_lua(Ls, "__hoi4_on_session_end");
    }
    if (start) {
        L("[session] dispatch session switch cleanup");
        timers_clear_locked();               // timers follow game-time resets
        async_session_reset();               // gen gate + queued/done purge
        bind_table_regen();                  // keep + re-stamp (2026-09-19 fix:
                                             // dropping binds here killed every
                                             // routed effect on same-pointer
                                             // session switches)
        hook_session_regen();                // same rule for vtable hooks: the
                                             // patch is process-level, so it is
                                             // KEPT; only bookkeeping refreshes
        force_reload_locked();               // full re-dofile = fresh script env
        // in-place 读档（ESC 菜单读档/load_save）会清掉
        // HasGameStarted 门 (gs+2617) 且不重跑会话启动函数 → 每日/每周/每月
        // 派发在 fire 前全部短路。此处幂等重开（对正常启动无害）。
        if (in_game_frame) {
            uint64_t gs = *(volatile uint64_t *)((uint8_t *)g_base + RVA_GAMESTATE_PTR);
            if (gs) {
                ((void(__fastcall *)(void *, int))(
                    (uintptr_t)g_base + RVA_SET_GAME_STARTED))((void *)gs, 1);
                L("[session] SetGameStarted re-armed (gate gs+2617)");
            }
        }
        L("[session] dispatch on_session_start");
        http_push_event("session_start", NULL);
        session_call_lua(Ls, "__hoi4_on_session_start");
    }
}
