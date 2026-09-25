// hoi4_offsets.h — image address table for hoi4_bridge.dll
// Single source of truth for every version-specific image address, compiled
// into the DLL (no companion file to distribute). A game update = edit this
// file + rebuild; the PE signature check refuses activation on any other
// build, so a stale table fails closed instead of patching wrong addresses.
// Values: hoi4.exe 1.19.3.0 rev c01a3d50 (base 0x140000000).
// Relocation evidence: fdiff v4 byte-hash map, string
// anchors, vtable RTTI, router call-chain intersection, CRT heap/tls xrefs —
// per-key notes below. ENGINE_NEW: never called anywhere in src (dead
// machinery, kept for the enum order); 1.19.2 value already pointed mid-
// function, so it is now pinned to the malloc thunk as a safe placeholder.
#pragma once

#define OFF_VERSION    "1.19.3.0-c01a3d50"
#define OFF_TIMESTAMP  0x6AA123BBu
#define OFF_IMAGE_SIZE 0x37EC000u
#define OFF_CHECKSUM   0x03534BB2u

// index order MUST match OffId in hoi4_common.h
static const uint64_t kOffValues[OFF_COUNT] = {
    /* FIND_CMD_BY_NAME  */ 0x24B54C0,   // fdiff
    /* EFFECT_ROUTER     */ 0x540EE0,   // str-anchor + new-dump body match
    /* ENGINE_NEW        */ 0x21C9AF0,  // unused slot; j_j__malloc_base (safe)
    /* SET_GLOBAL_FACTORY*/ 0x341500,   // SGF vt xref + body (malloc 0x220 + vftable)
    /* VEC_PUSH_BACK     */ 0x1205A0,   // both-router call-chain intersection
    /* SGF_VTABLE        */ 0x276C218,  // RTTI CSetGlobalFlagEffect
    /* GAMESTATE_PTR     */ 0x332F260,  // token-align 122 votes
    /* NAME_TO_KEY       */ 0x24BB460,  // fdiff + str-anchor
    /* LEXER_TOKEN_TABLE */ 0x35E1AE0,  // token-align + adjacency
    /* LEXER_TOKEN_MAX   */ 0x35E1AB4,  // adjacency + 279-occurrence exact match
    /* TRIGGER_ROUTER    */ 0x550030,   // str-anchor + new-dump body match
    /* GFT_FACTORY       */ 0x3E4D00,   // GFT vt xref + body (malloc 0xB0 + vftable)
    /* GFT_VTABLE        */ 0x278A670,  // RTTI CGlobalFlagTrigger
    /* INGAME_IDLER_V4   */ 0xDD3A50,   // CInGameIdler vt slot4 read
    /* INGAME_IDLER_VTBL_SLOT4 */ 0x2969010, // CInGameIdler vt + 0x20
    /* ENGINE_ALLOC      */ 0x21C9AF0,  // j_j__malloc_base (thunk chain traced)
    /* MGR_CTOR          */ 0x24B4C40,  // fdiff
    /* SET_SPEED         */ 0x1EDE50,   // fdiff
    /* EVAL_VALUE        */ 0x544C90,   // str-anchor (scopedvariable.cpp)
    /* LINE_INFO         */ 0x24BF5B0,  // fdiff + router call-chain
    /* CONSOLE_MGR_SLOT  */ 0x35E1A80,  // token-align + adjacency
    /* ENGINE_HEAP_HANDLE*/ 0x35E7D50,  // _malloc_base xref (hHeap)
    /* APP_MGR_PTR       */ 0x332F698,  // token-align 51 votes
    /* ENGINE_TLSINDEX   */ 0x35E6178,  // tls stub xrefs (TlsIndex)
    /* ASSERTS_BYTE      */ 0x35E1B52,  // token-align 119 votes + adjacency
    /* SESSION_CTOR_WRITE*/ 0x1D2D03,   // gs slot write insn (scan: tools/scan_gs_writers_1193.py)
    /* SESSION_DTOR_WRITE*/ 0x1D60AA,   // gs slot null-write insn (same scan)
    /* LOAD_ENTRY        */ 0xDA04F0,   // load-save entry sub_140DA04F0;
                                       //   DR2 事件 + hoi4.load_save 驱动目标)
    /* SAVEDESC_CTOR     */ 0xBC0880,   // 224B saveDesc ctor
    /* SAVEDESC_DTOR     */ 0xBC0960,   // saveDesc dtor
    /* STRING_ASSIGN     */ 0x129CA0,   // std::string::assign(this, char*, len)
    /* SET_GAME_STARTED  */ 0x1EDFF0,   // SetGameStarted(gs,1) — idempotent gate reopen
    /* PURECALL          */ 0x253C3B8,  // _purecall: base-class vtable filler.
                                       //   hook gate: a slot holding this is a
                                       //   BASE-class slot — hooking it would
                                       //   intercept nothing (see hoi4_hook.h)
    /* GUARD_NOP         */ 0x12A2C0,   // _guard_check_icall_nop: CFG no-op stub
                                       //   (1.19.3; old 0x140129DB0 = 1.19.2)
                                       //   hook gate: same "not a real impl"
                                       //   class of filler as _purecall
};
