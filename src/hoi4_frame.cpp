#include "hoi4_common.h"
#include "hoi4_hook.h"

// -+ frame tick
// (covers heartbeat, async and IPC dispatch)
// Lua dispatch shared by the route-B frame hook below: called once per
// RENDERED FRAME while IN GAME, on the engine main thread, with g_luaLock
// held. Order: session -> reload -> timers -> async -> hook-observe -> HTTP.
//
// Locking: same discipline as the effect-callback path — SRWLock with owner
// tid+depth bookkeeping, TryAcquire so we never stall the frame thread; a
// lost frame is harmless. The hook site (vtable slot 4 parent layer) cannot
// overlap an effect callback on the same thread anyway; the guards protect
// against hypothetical worker-side holders.
static volatile long g_frames;         // v4 entries since install
static DWORD         g_tickOwnerTid;   // re-entrancy: tid inside dispatch
static unsigned      g_tickDropped;    // diagnostics

static void tick_dispatch_lua(unsigned long long now)
{
    // g_initialized is set only after lua_init_thread has finished openlibs,
    // API registration, metatables and the first script load — g_L != NULL
    // alone would let us enter a half-initialized VM (published mid-init).
    if (!g_L || !g_initialized) return;
    // belt-and-braces phase guard: the hook site already implies an in-game
    // idler, but quit-to-menu transitions tear state down on the same thread.
    uint64_t gs = *(volatile uint64_t *)(g_base + RVA_GAMESTATE_PTR);
    if (!gs) { g_tickDropped++; return; }

    DWORD tid = GetCurrentThreadId();
    if (g_tickOwnerTid == tid)             // re-entry paranoia
        { g_tickDropped++; return; }
    if (g_luaOwner && g_luaOwner != tid)   // someone else holds the VM
        { g_tickDropped++; return; }
    int taken = TryAcquireSRWLockExclusive(&g_luaLock);
    if (!taken) { g_tickDropped++; return; }
    g_luaOwner = tid; g_luaDepth = 1;
    g_tickOwnerTid = tid;
    session_note_frame();                  // "in game now" heartbeat (health)

    // Hot reload executes HERE (top of frame, shallow stack). A1/F9: mtime
    // DETECTION is throttled to 1 Hz (was: every frame + every effect/trigger
    // callback entry — the callback path is removed as redundant; frame-top
    // alone costs ~1/60th of before and worst-case latency is ~1s).
    static unsigned long long s_lastReloadCheck;
    // B: session events are consumed first — a session switch forces a full
    // reload itself (session_dispatch_locked), so ordering matters.
    session_dispatch_locked(g_L, 1);   // in-game frame (gate re-arm allowed)
    if (now - s_lastReloadCheck >= 1000) {
        s_lastReloadCheck = now;
        maybe_reload_locked();
    }
    reload_execute_locked();
    // timers are dispatched by the C core now.
    // The temporary pure-Lua "on_frame" global contract is retired.
    timer_dispatch_locked(now);
    // deliver finished async jobs to their Lua callbacks.
    async_dispatch_locked(g_L);
    // deliver queued vtable-hook observe events (hoi4_hook.cpp). They are
    // enqueued from arbitrary threads and can only be handed to Lua here.
    hook_dispatch_observe(g_L);
    // F: queued /console /lua /game/pause. Bounded per frame; leftovers
    // wait for the next one.
    http_poll_main(4);

    g_tickOwnerTid = 0;
    g_luaOwner = 0; g_luaDepth = 0;
    ReleaseSRWLockExclusive(&g_luaLock);
}

// -+ frame heartbeat (engine vtable slot4 hook)
// VTABLE-SLOT hook on CInGameIdler slot 4 (FUN_140DBF240, RVA 0xDBF240).
// The engine calls it every frame while IN
// GAME, on the pinned main thread, as the PARENT of effect dispatch ->
// structurally outside any effect callback. Main menu / loading screens
// never reach it: the phase guard is free.
//
// Replaces the REMOVED tick-1 WM_TIMER design (RegisterClassW bug +
// worker-thread dispatch). Also replaces the FIRST route-B attempt (inline
// abs-jmp on the function body): CRASHED ON FIRST FRAME — dump-proven root
// cause (crashdumps analysis 2026-08-25): the stolen prologue contains
// mov rax,rsp, and FUN_140DBF240+0x1D re-derives rbp from rax
// (lea rbp,[rax-68h]) plus two movaps stores through rax. Our trampoline's
// return-jump overwrote rax with the jumpback address, so the resumed body
// computed rbp = (.text addr) - 0x68 and movaps faulted writing through it.
// Lesson: abs-jmp trampolines clobber rax; only safe when the stolen bytes'
// outputs are dead on resume. A vtable-slot swap touches ONE data qword,
// leaves the function body byte-identical, and cannot have this failure
// mode at all.
//
#define TICK_LOG_EVERY          512    // ~8s of frames between progress lines

typedef void (*InGameIdlerV4_t)(void *self, uint8_t flags);
static InGameIdlerV4_t g_origIdlerV4;

static void HK_InGameIdlerV4(void *self, uint8_t flags)
{
    session_note_idler_ingame();          // idler edge: FE -> game => START
    unsigned long long now = GetTickCount64();
    long f = InterlockedIncrement(&g_frames);
    // First entry = the engine's pinned main thread. Record it once; the hook
    // facility needs it to tell "safe to run Lua inline" from "must fail open"
    // (a worker-thread callback cannot touch the VM). Captured here rather than
    // in DllMain because this site is provably the main thread.
    if (f == 1) hook_note_main_thread(GetCurrentThreadId());
    // progress lines are debug-mode-only (dll_debug_mode is a cached atomic
    // read); the install-path [frame] diagnostics below stay always-on.
    if (f == 1 && dll_debug_mode())
        L("[frame] CInGameIdler::v4 FIRST FRAME self=%p base=%p",
          self, (void *)g_base);
    else if (f % TICK_LOG_EVERY == 0 && dll_debug_mode())
        L("[frame] frame #%ld t=%llu dropped=%u", f, now, g_tickDropped);
    tick_dispatch_lua(now);
    g_origIdlerV4(self, flags);
}

void install_v4_vtable_hook(void)
{
    void **slot = (void **)(g_base + RVA_INGAME_IDLER_VTBL_SLOT4);
    __try {
        void *cur = *slot;
        if (cur != (void *)(g_base + RVA_INGAME_IDLER_V4)) {
            // refuse on version drift / wrong qword: patching blind would
            // redirect an unknown function.
            L("[frame] slot4 mismatch: got %p expect %p - NOT hooking",
              cur, (void *)(g_base + RVA_INGAME_IDLER_V4));
            return;
        }
        DWORD op;
        if (!VirtualProtect(slot, sizeof(void *), PAGE_READWRITE, &op)) {
            L("[frame] VirtualProtect failed %lu", GetLastError());
            return;
        }
        g_origIdlerV4 = (InGameIdlerV4_t)cur;
        *slot = (void *)HK_InGameIdlerV4;
        VirtualProtect(slot, sizeof(void *), op, &op);
        L("[frame] vtable slot4 hooked @ %p (%p -> %p)",
          (void *)slot, cur, (void *)&HK_InGameIdlerV4);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        L("[frame] vtable hook install faulted");
    }
}

// -+ front-end frame hook (main menu / loading screens)
// Same vtable-slot4 shape as the in-game hook above, on CFrontEndIdler
// (vt 0x2949D50, slot4 = sub_140B3CA20 Idle = frontend.cpp:177 frame loop;
// f05 findings). Purpose: give the session machinery a frame-top consumer
// while the engine idles on the FRONT END — previously dispatch only
// existed on the in-game idler, so quit-to-menu round trips raised no event
// and mod Lua state survived into the next world (crash 2026-09-26; see
// the idler-edge note in hoi4_session.cpp).
// Scope is deliberately MINIMAL: idler-edge detection + session_dispatch
// ONLY. No session_note_frame (session_active/health must stay in-game
// only), no timers / async / observe / HTTP dispatch (the front-end
// gamestate is not a live game world — mod callbacks reading game memory
// there would fault), no mtime reload watch.
typedef void (*FeIdlerV4_t)(void *self, uint8_t flags);
static FeIdlerV4_t g_origFeIdlerV4;

static void HK_FrontEndIdlerV4(void *self, uint8_t flags)
{
    session_note_idler_frontend();        // idler edge: game -> FE => END+START
    if (g_L && g_initialized) {
        // same lock discipline as tick_dispatch_lua (TryAcquire: a lost
        // frame is harmless — the flags stay raised for the next one)
        DWORD tid = GetCurrentThreadId();
        if (g_tickOwnerTid != tid && (!g_luaOwner || g_luaOwner == tid)) {
            if (TryAcquireSRWLockExclusive(&g_luaLock)) {
                g_luaOwner = tid; g_luaDepth = 1;
                g_tickOwnerTid = tid;
                session_dispatch_locked(g_L, 0);  // menu frame: NO gate re-arm
                g_tickOwnerTid = 0;
                g_luaOwner = 0; g_luaDepth = 0;
                ReleaseSRWLockExclusive(&g_luaLock);
            }
        }
    }
    g_origFeIdlerV4(self, flags);
}

void install_fe_v4_vtable_hook(void)
{
    void **slot = (void **)(g_base + RVA_FRONTEND_IDLER_VTBL_SLOT4);
    __try {
        void *cur = *slot;
        if (cur != (void *)(g_base + RVA_FRONTEND_IDLER_V4)) {
            L("[frame] FE slot4 mismatch: got %p expect %p - NOT hooking",
              cur, (void *)(g_base + RVA_FRONTEND_IDLER_V4));
            return;
        }
        DWORD op;
        if (!VirtualProtect(slot, sizeof(void *), PAGE_READWRITE, &op)) {
            L("[frame] FE VirtualProtect failed %lu", GetLastError());
            return;
        }
        g_origFeIdlerV4 = (FeIdlerV4_t)cur;
        *slot = (void *)HK_FrontEndIdlerV4;
        VirtualProtect(slot, sizeof(void *), op, &op);
        L("[frame] FE vtable slot4 hooked @ %p (%p -> %p)",
          (void *)slot, cur, (void *)&HK_FrontEndIdlerV4);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        L("[frame] FE vtable hook install faulted");
    }
}

