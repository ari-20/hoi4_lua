// hoi4_lde.h — minimal x86-64 instruction length decoder (hook boundary safety)
//
// Pure functions, extracted from hoi4_detour.cpp so they are unit-testable
// (tests/test_lde.cpp): install_abs_jmp used to steal a FIXED 15 bytes; if
// that count landed in the middle of an instruction the trampoline resumed
// garbage. This decoder steals exactly N WHOLE instructions (N >= the
// 12-byte absolute jump). It is deliberately conservative: any opcode it
// cannot classify aborts the hook (fail closed). Covers the MSVC /O2
// prologue repertoire: legacy prefixes, REX, 1-byte opcodes with/without
// ModRM, 0F two-byte opcodes, imm8/16/32/64, disp8/32, and relative
// control-flow (which is REJECTED — relocated rel targets would point into
// nowhere).
//
// Two independent rejection signals, both fail-closed:
//   *rel_cf  = 1 -> relative control flow (call/jmp/jcc rel) — its target
//                    cannot be relocated, so stealing it is always wrong.
//   *rip_rel = 1 -> the instruction carries a RIP-relative memory operand
//                    ([rip+disp32]). The length is decoded correctly, but
//                    the operand only means anything at its ORIGINAL address;
//                    install_abs_jmp copies stolen bytes verbatim into a stub
//                    elsewhere, so such an instruction must be refused.
//                    Deliberately over-conservative: multi-byte NOPs with a
//                    RIP-relative operand are flagged too even though their
//                    operand is never used (MSVC emits [rax+0]/SIB forms for
//                    alignment padding, so this costs nothing in practice).
#pragma once
#include <stdint.h>

// returns 1 if the (0F-prefixed or one-byte) opcode takes a ModRM byte
static int lde_has_modrm(uint8_t op, int is0f) {
    if (is0f) {
        // 0F 10-17/28-2F/38/3A/40-4F/80-8F(no modrm, rel32)/AF/B0-B1/B6-BF/C3
        if (op >= 0x10 && op <= 0x17) return 1;
        if (op >= 0x28 && op <= 0x2F) return 1;
        if (op >= 0x40 && op <= 0x4F) return 1;
        if (op == 0x38 || op == 0x3A) return 1;
        if (op >= 0x50 && op <= 0x7F) return 1;
        if (op >= 0x90 && op <= 0x9F) return 1;
        if (op >= 0xA3 && op <= 0xA5) return 1;
        if (op == 0xAB || op == 0xAD || op == 0xAE) return 1;
        if (op >= 0xAF && op <= 0xB9) return 1;
        if (op >= 0xBA && op <= 0xBF) return 1;
        if (op >= 0xC0 && op <= 0xC7) return 1;
        if (op >= 0xD0 && op <= 0xFF) return 1;
        return 0;                       // 0F 06/0B/1E/1F(/0)? etc: only nop-like
    }
    // one-byte map
    if (op <= 0x03 || (op >= 0x08 && op <= 0x0B) ||
        (op >= 0x10 && op <= 0x13) || (op >= 0x18 && op <= 0x1B) ||
        (op >= 0x20 && op <= 0x23) || (op >= 0x28 && op <= 0x2B) ||
        (op >= 0x30 && op <= 0x33) || (op >= 0x38 && op <= 0x3B)) return 1;
    if (op >= 0x60 && op <= 0x63) return op == 0x63;   // movsxd
    if (op >= 0x80 && op <= 0x8F) return 1;            // grp1/lea/mov/pop
    if (op >= 0xC0 && op <= 0xC7) return (op == 0xC0 || op == 0xC1 ||
                                          op == 0xC6 || op == 0xC7);
    if (op >= 0xD0 && op <= 0xD3) return 1;
    if (op >= 0xF6 && op <= 0xF7) return 1;
    if (op >= 0xFE && op <= 0xFF) return 1;
    return 0;
}

// returns instruction length in [1..15], 0 = unrecognized/unsafe.
// (*rel_cf = 1 marks the relative-control-flow rejection subtype; *rip_rel = 1
// marks a RIP-relative memory operand — see the header note. Both outputs are
// written on every path, so callers may read them without pre-clearing.)
static int lde_len(const uint8_t *p, uint32_t avail, int *rel_cf, int *rip_rel) {
    uint32_t i = 0;
    int rexW = 0, is0f = 0, f3 = 0, os16 = 0;
    *rel_cf = 0;
    *rip_rel = 0;
    // legacy prefixes (repeatable)
    for (;;) {
        if (i >= avail) return 0;
        uint8_t b = p[i];
        if (b == 0x66 || b == 0x67 || b == 0xF0 || b == 0xF2 || b == 0xF3 ||
            b == 0x2E || b == 0x36 || b == 0x3E || b == 0x26 ||
            b == 0x64 || b == 0x65) {
            if (b == 0xF3) f3 = 1;
            if (b == 0x66) os16 = 1;     // operand-size: imm32 -> imm16
            i++;
            continue;
        }
        if (b >= 0x40 && b <= 0x4F) { rexW = (b & 8) != 0; i++; continue; }
        break;
    }
    if (i >= avail) return 0;
    uint8_t op = p[i++];
    if (op == 0x0F) {
        if (i >= avail) return 0;
        op = p[i++];
        is0f = 1;
        // relative control flow: jcc rel32 (0F 80-8F) — reject for stealing
        if (op >= 0x80 && op <= 0x8F) { *rel_cf = 1; return 0; }
        // three-byte forms 0F 38 / 0F 3A: third byte is the real opcode
        if (op == 0x38 || op == 0x3A) {
            int imm8 = (op == 0x3A);
            if (i >= avail) return 0;
            op = p[i++];
            // modrm + optional imm8
            if (i >= avail) return 0;
            uint8_t modrm = p[i++];
            uint8_t mod = modrm >> 6, rm = modrm & 7;
            // mod=0 rm=5 here is RIP-relative (no SIB in the 0F38/0F3A form)
            if (mod == 0 && rm == 5) { i += 4; *rip_rel = 1; }
            else if (mod == 1) i += 1;
            else if (mod == 2) i += 4;
            if (mod != 3 && rm == 4) { // SIB
                if (i >= avail) return 0;
                uint8_t sib = p[i++];
                if (mod == 0 && (sib & 7) == 5) i += 4;
            }
            i += imm8;
            return (i <= avail && i <= 15) ? (int)i : 0;
        }
        // endbr64 = F3 0F 1E FA (modrm encoded as register form)
        if (op == 0x1E) {
            if (i < avail) { i++; }    // modrm byte (0xFA/0xFB)
            return (f3 && i <= avail && i <= 15) ? (int)i : 0;
        }
        if (op == 0x1F) {
            // multi-byte nop: modrm, no immediate
        } else if (!lde_has_modrm(op, 1)) {
            // 0F 05 syscall / 0F 0B ud2 / 0F 31 rdtsc etc: no modrm, no imm
            if (op == 0x05 || op == 0x0B || op == 0x31 || op == 0xA2 ||
                (op >= 0x30 && op <= 0x37))
                return (int)i;
            return 0;
        }
    } else {
        // relative control flow in the one-byte map — reject for stealing
        if (op == 0xE8 || op == 0xE9 || op == 0xEB || op == 0xE3 ||
            (op >= 0x70 && op <= 0x7F) || (op >= 0xE0 && op <= 0xE2)) {
            *rel_cf = 1;
            return 0;
        }
        // immediate-only opcodes (no modrm)
        if (op >= 0x50 && op <= 0x5F) return (int)i;             // push/pop r
        if (op == 0x90 || op == 0xC3 || op == 0xCC || op == 0xC9) return (int)i;
        if (op == 0x6A) return (i + 1 <= avail) ? (int)(i + 1) : 0;   // push imm8
        if (op == 0x68) {                                            // push imm16/32
            int n = os16 ? 2 : 4;
            return (i + (uint32_t)n <= avail) ? (int)(i + n) : 0;
        }
        if (op == 0xC2) return (i + 2 <= avail) ? (int)(i + 2) : 0;   // ret imm16
        if (op >= 0xB0 && op <= 0xB7)                              // mov r8, imm8
            return (i + 1 <= avail) ? (int)(i + 1) : 0;
        if (op >= 0xB8 && op <= 0xBF) {                            // mov r, imm
            int n = rexW ? 8 : (os16 ? 2 : 4);
            return (i + (uint32_t)n <= avail) ? (int)(i + n) : 0;
        }
        if (op == 0x04 || op == 0x0C || op == 0x14 || op == 0x1C ||
            op == 0x24 || op == 0x2C || op == 0x34 || op == 0x3C ||
            op == 0xA8)
            return (i + 1 <= avail) ? (int)(i + 1) : 0;          // AL, imm8
        if (op == 0x05 || op == 0x0D || op == 0x15 || op == 0x1D ||
            op == 0x25 || op == 0x2D || op == 0x35 || op == 0x3D ||
            op == 0xA9) {
            int n = os16 ? 2 : 4;                                // eAX, imm16/32
            return (i + (uint32_t)n <= avail) ? (int)(i + n) : 0;
        }
        if (!lde_has_modrm(op, 0)) return 0;
    }
    // ModRM + optional SIB + displacement
    if (i >= avail) return 0;
    uint8_t modrm = p[i++];
    uint8_t mod = modrm >> 6, rm = modrm & 7;
    int sib_present = (mod != 3 && rm == 4);
    if (sib_present) {
        if (i >= avail) return 0;
        uint8_t sib = p[i++];
        if (mod == 0 && (sib & 7) == 5) i += 4;                  // disp32 via SIB
    }
    // RIP-relative: mod=0 rm=5 WITHOUT SIB (with SIB it is [disp32] absolute,
    // which is position-independent and needs no flag)
    if (mod == 0 && rm == 5 && !sib_present) { i += 4; *rip_rel = 1; }
    else if (mod == 1) i += 1;
    else if (mod == 2) i += 4;
    // immediate by opcode group
    uint8_t eff = op;
    if (!is0f) {
        if (eff == 0x80 || eff == 0x83 || eff == 0xC0 || eff == 0xC1 ||
            eff == 0xC6 || (eff == 0xF6 && ((modrm >> 3) & 7) <= 1))
            i += 1;                                              // imm8
        else if (eff == 0x81 || eff == 0xC7 ||
                 (eff == 0xF7 && ((modrm >> 3) & 7) <= 1))
            i += os16 ? 2 : 4;                                   // imm16/32
    } else {
        // two-byte map: immediate only for a closed set; every other opcode
        // must be on the known-no-immediate whitelist or we fail closed.
        // Getting an imm length WRONG would steal mid-instruction — worse
        // than refusing the hook.
        static const uint8_t imm8_set[] = { 0x70, 0x71, 0x72, 0x73, 0xBA,
                                            0xC2, 0xC4, 0xC5, 0xC6 };
        int has_imm8 = 0;
        for (size_t k = 0; k < sizeof(imm8_set); k++)
            if (op == imm8_set[k]) { has_imm8 = 1; break; }
        if (has_imm8) {
            i += 1;
        } else {
            int known = (op == 0x1F) ||
                (op >= 0x10 && op <= 0x17) || (op >= 0x28 && op <= 0x2F) ||
                (op >= 0x40 && op <= 0x4F) || (op >= 0x50 && op <= 0x6F) ||
                (op >= 0x74 && op <= 0x7F) || (op >= 0x90 && op <= 0x9F) ||
                (op >= 0xA3 && op <= 0xA5) || op == 0xAB || op == 0xAD ||
                (op >= 0xAF && op <= 0xB8) || (op >= 0xBB && op <= 0xBF) ||
                op == 0xC0 || op == 0xC1 || op == 0xC3 || op == 0xC7 ||
                (op >= 0xD0 && op <= 0xFE);
            // 0F B9 (ud1) / 0F FF (ud0) deliberately excluded: reserved
            // opcodes must refuse, never be "decoded".
            if (!known) return 0;    // unrecognized 0F opcode: refuse
        }
    }
    if (i > avail || i > 15) return 0;
    return (int)i;
}
