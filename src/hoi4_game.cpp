// hoi4_game.cpp — game control APIs (batch H)
//
// Research basis: research_20260911/GAP_PAUSE_SPEED.md (2026-09-11) +
// live probe 2026-09-12:
//   gs+0x4BC = speed index (0..4, UI shows index+1); clamp in engine setter
//   sub_1401EDAD0(gs, n). PAUSED is a SEPARATE flag — probe: game loaded
//   paused read speed=4, hour frozen; writing the field
//   changed the setting but never unpaused. Pause/unpause therefore goes
//   through the command path: CPauseGame::apply -> mgr->vt[+656](u8, reason).
//   mgr = *(base + APP_MGR_PTR) (same application manager as the save/load
//   session research); the object is CInGameIdler (vtable RVA 0x2968FF0).
//   vtable slot read at runtime — no class-name need.

#include "hoi4_common.h"

// hoi4.game_speed() -> speed index 0..4 (nil if no gamestate)
int hoi4_game_speed(lua_State *Ls) {
    uint64_t gs = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
    if (!gs) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, h4_rd32(gs + GS_SPEED, 0));
    return 1;
}

// hoi4.game_set_speed(n) — engine's own setter (clamps 0..4 AND pushes the
// UI update events a raw write lacks). Main thread only (engine asserts).
typedef void (__fastcall *SetSpeed_t)(uint64_t gs, int speed);
int hoi4_game_set_speed(lua_State *Ls) {
    int n = (int)luaL_checkinteger(Ls, 1);
    uint64_t gs = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
    if (!gs) { lua_pushnil(Ls); return 1; }
    SetSpeed_t fn = (SetSpeed_t)(g_base + RVA_SET_SPEED);
    __try { fn(gs, n); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); return 1; }
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.game_pause(state) — set-state semantics ("ensure paused/running"),
// NOT a blind toggle: callers can call it repeatedly without tracking state.
//
// Engine facts (1.19.3, live-verified):
//  - mgr+1729 is the authoritative pause flag (1 with hour frozen, 0 running).
//    The object is CInGameIdler (vtable RVA 0x2968FF0); APP_MGR_PTR holds it.
//  - mgr->vt[+656] (slot 82, RVA 0x140DDAD30) IS the pause toggle: its body
//    writes +1729 = 0/1 and +1731 = 0/1 and carries the "Game paused by
//    <reason>" branch (which READS +1729 as its predicate — the read does not
//    make the function read-only). Reason is a stack SSO std::string
//    (<=15 chars -> fully inline, zero allocator involvement).
//  - ⚠ DO NOT confuse it with slot 91 (vt+728, RVA 0x140DC6530), which is the
//    AUTOSAVE flag setter: its whole body is `*(a1+1680)=a2; if(!a2)
//    *(a1+1681)=0;` — it touches +1680/+1681 and NEVER +1729, so it cannot
//    pause anything. Reading its +1680 write as "the pause setter" is the
//    documented way to get this pair backwards.
//  - after engine-internal loads the toggle can SHORT-CIRCUIT while the
//    companion pending bit (mgr+1731) is armed: repeated calls flip nothing.
//    In that state the flag byte is still polled every frame, so writing it
//    directly (and clearing the pending bit) takes effect immediately.
typedef void (__fastcall *MgrPause_t)(uint64_t mgr, uint32_t state,
                                      const void *reasonStr);

// plain-C invokable (shared by the Lua API below and the HTTP module).
// Returns 1 on success, 0 on failure (no manager/vtable).
int game_pause_invoke_raw(int state) {
    uint64_t mgr = h4_rd64((uint64_t)(uintptr_t)g_base + APP_MGR_PTR, 0);
    if (!mgr) return 0;
    uint8_t want = state ? 1 : 0;
    if (h4_rd8(mgr + MGR_PAUSE_FLAG, 0) == want) {
        *(volatile uint8_t *)(mgr + MGR_PAUSE_PENDING) = 0;   // clear stale pending
        return 1;
    }
    uint64_t vt = h4_rd64(mgr, 0);
    MgrPause_t fn = vt ? (MgrPause_t)h4_rd64(vt + 656, 0) : NULL;
    // memory-derived target: exec-domain gate (memgate). On refuse the
    // direct flag write below takes over — same documented semantics.
    if (fn && !memgate_exec_ok((uint64_t)(uintptr_t)fn)) {
        L("[pause] mgr->vt[+656] target outside engine exec sections — "
          "falling back to direct flag write");
        fn = NULL;
    }
    if (fn) {
        uint8_t reason[0x20];
        memset(reason, 0, sizeof(reason));
        memcpy(reason, "lua", 3);
        *(uint64_t *)(reason + 0x10) = 3;      // len
        *(uint64_t *)(reason + 0x18) = 15;     // SSO cap
        __try { fn(mgr, (uint32_t)state, reason); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    }
    if (h4_rd8(mgr + MGR_PAUSE_FLAG, 0) != want) {
        *(volatile uint8_t *)(mgr + MGR_PAUSE_FLAG) = want;
        *(volatile uint8_t *)(mgr + MGR_PAUSE_PENDING) = 0;
    }
    return 1;
}

// F: extern for C++ (common.h declares game_pause_invoke / game_speed_read)
int game_pause_invoke(int state) { return game_pause_invoke_raw(state); }
int  game_speed_read(void) {
    uint64_t gs = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
    if (!gs) return -1;
    return (int)h4_rd32(gs + GS_SPEED, 0);
}

// O(1) paused read (H tail item, closed 2026-09-12): the pause toggle
// sub_140DDAD30 (mgr->vt[+656], slot 82) flips EXACTLY the byte at mgr+1729
// (0x6C1) in every branch (mgr+1731 is the pending-press companion bit).
// Live verified: 1 with hour frozen, 0 while running. -1 if no manager.
// (The pre-1.19.3 note in this file cited RVA 0x140DC6520 for this slot; that
// address is stale — the live slot-82 target is 0x140DDAD30. Do not read the
// slot-91 autosave setter at 0x140DC6530 as this function.)
int game_paused_read(void) {
    uint64_t mgr = h4_rd64((uint64_t)(uintptr_t)g_base + APP_MGR_PTR, 0);
    if (!mgr) return -1;
    return (int)h4_rd8(mgr + MGR_PAUSE_FLAG, 0);
}

int hoi4_game_pause(lua_State *Ls) {
    int state = (int)luaL_checkinteger(Ls, 1);
    if (!game_pause_invoke_raw(state)) { lua_pushnil(Ls); return 1; }
    lua_pushboolean(Ls, 1);
    return 1;
}
