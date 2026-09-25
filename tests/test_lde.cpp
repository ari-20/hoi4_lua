// test_lde.cpp — table-driven unit tests for the hook instruction-length
// decoder (hoi4_lde.h). A wrong length means install_abs_jmp steals
// mid-instruction bytes and the trampoline resumes into garbage — this is
// the cheapest place to catch that class of bug, before it reaches a live
// game process. The RIP-relative flag is tested just as strictly: a missed
// flag means the trampoline relocates an operand that only made sense at the
// original address (hoi4_lde.h / HOOK_DESIGN.md §5.3).
//
// Build & run (no framework, plain asserts):
//   cl /nologo /O2 /W4 tests\test_lde.cpp /Fe:test_lde.exe && test_lde.exe
#include <cstdio>
#include <cstring>
#include <cstdint>
#include "../src/hoi4_lde.h"

static int g_fail = 0, g_run = 0;

// contract: wantLen>0 -> exact length. wantLen==0: refusal; wantRel==1
// additionally requires the relative-control-flow reject marker; wantRel==-1
// accepts any refusal subtype (the decoder only promises *rel_cf on the
// rel-cf path; other refusals may leave it untouched).
//
// wantRip is asserted on EVERY case: 0 = must not be flagged RIP-relative,
// 1 = must be flagged. T() expects 0, TR() expects 1 — so a change that
// starts (or stops) flagging an instruction cannot pass silently.
static void chk(const char *name, const uint8_t *code, int n,
                int wantLen, int wantRel, int wantRip) {
    int rel = -2, rip = -2;
    int got = lde_len(code, (uint32_t)n, &rel, &rip);
    g_run++;
    int ok = (got == wantLen);
    if (ok && wantLen == 0 && wantRel == 1) ok = (rel == 1);
    if (ok) ok = (rip == wantRip);
    if (!ok) {
        g_fail++;
        printf("FAIL %-34s got len=%d rel=%d rip=%d, want len=%d rel=%d rip=%d\n",
               name, got, rel, rip, wantLen, wantRel, wantRip);
    }
}
#define T(name, arr, len, rel)  chk(name, arr, sizeof(arr), len, rel, 0)
#define TR(name, arr, len, rel) chk(name, arr, sizeof(arr), len, rel, 1)

int main(void) {
    // ---- 1-byte opcodes, no ModRM ----
    { uint8_t c[] = {0x50};            T("push rax", c, 1, -1); }
    { uint8_t c[] = {0x5F};            T("pop rdi", c, 1, -1); }
    { uint8_t c[] = {0x90};            T("nop", c, 1, -1); }
    { uint8_t c[] = {0xC3};            T("ret", c, 1, -1); }
    { uint8_t c[] = {0xC9};            T("leave", c, 1, -1); }
    { uint8_t c[] = {0xCC};            T("int3", c, 1, -1); }
    { uint8_t c[] = {0x6A, 0x20};      T("push imm8", c, 2, -1); }
    { uint8_t c[] = {0x68, 1,2,3,4};   T("push imm32", c, 5, -1); }
    { uint8_t c[] = {0xC2, 1,0};       T("ret imm16", c, 3, -1); }

    // ---- ModRM forms ----
    { uint8_t c[] = {0x8B, 0xC1};      T("mov eax,ecx (reg,reg)", c, 2, -1); }
    { uint8_t c[] = {0x89, 0x08};      T("mov [rax],ecx (mod0)", c, 2, -1); }
    { uint8_t c[] = {0x8B, 0x48, 0x10};T("mov ecx,[rax+0x10] (mod1)", c, 3, -1); }
    { uint8_t c[] = {0x8B, 0x88, 1,2,3,4}; T("mov ecx,[rax+d32] (mod2)", c, 6, -1); }
    // mod0 rm4 + SIB base=5 -> [disp32] ABSOLUTE, position-independent: must
    // NOT be flagged RIP-relative (the decoder distinguishes these two).
    { uint8_t c[] = {0x8B, 0x04, 0x25, 1,2,3,4}; T("mov eax,[d32] (SIB abs, not RIP)", c, 7, -1); }
    { uint8_t c[] = {0x8B, 0x05, 1,2,3,4}; TR("mov eax,RIP-rel (mod0 rm5)", c, 6, -1); }
    { uint8_t c[] = {0x8B, 0x44, 0x24, 0x08}; T("mov eax,[rsp+8] (SIB mod1)", c, 4, -1); }

    // ---- RIP-relative operand detection (must set rip=1; the trampoline
    //      copies stolen bytes verbatim and cannot relocate these) ----
    { uint8_t c[] = {0x48, 0x8B, 0x05, 1,2,3,4}; TR("mov rax,[rip+d32] (REX.W)", c, 7, -1); }
    { uint8_t c[] = {0x48, 0x8D, 0x0D, 1,2,3,4}; TR("lea rcx,[rip+d32]", c, 7, -1); }
    { uint8_t c[] = {0xF3, 0x0F, 0x10, 0x05, 1,2,3,4}; TR("movss xmm0,[rip+d32]", c, 8, -1); }
    { uint8_t c[] = {0x48, 0x89, 0x05, 1,2,3,4}; TR("mov [rip+d32],rax", c, 7, -1); }
    // over-conservative on purpose: a NOP's operand is never used, but the
    // decoder flags by addressing form alone (documented in hoi4_lde.h)
    { uint8_t c[] = {0x0F, 0x1F, 0x05, 1,2,3,4}; TR("nop dword [rip+d32] (flagged)", c, 7, -1); }
    // 0F38 / 0F3A three-byte forms carry their own RIP-relative case
    { uint8_t c[] = {0x0F, 0x38, 0x00, 0x05, 1,2,3,4}; TR("0F38 pshufb [rip+d32]", c, 8, -1); }
    { uint8_t c[] = {0x66, 0x0F, 0x3A, 0x0C, 0x05, 1,2,3,4, 0x02}; TR("0F3A imm8 [rip+d32]", c, 10, -1); }
    // the trampoline's own jump-back encoding is a valid RIP-relative insn:
    //   FF 25 00 00 00 00 = jmp qword ptr [rip+0]  (register-free by design)
    { uint8_t c[] = {0xFF, 0x25, 0,0,0,0}; TR("jmp [rip+0] (stub jump-back form)", c, 6, -1); }
    // negatives: mod1/mod2 displacements are rsp/reg-relative, never RIP
    { uint8_t c[] = {0x48, 0x8B, 0x45, 0x10}; T("mov rax,[rbp+0x10] (mod1, not RIP)", c, 4, -1); }
    { uint8_t c[] = {0x48, 0x8B, 0x85, 1,2,3,4}; T("mov rax,[rbp+d32] (mod2, not RIP)", c, 7, -1); }

    // ---- REX ----
    { uint8_t c[] = {0x48, 0x89, 0xC1}; T("mov rcx,rax (REX.W)", c, 3, -1); }
    { uint8_t c[] = {0x48, 0x8B, 0x44, 0x24, 0x28}; T("mov rax,[rsp+0x28]", c, 5, -1); }
    { uint8_t c[] = {0x48, 0x83, 0xEC, 0x28}; T("sub rsp,0x28 (imm8)", c, 4, -1); }
    { uint8_t c[] = {0x48, 0x81, 0xEC, 8,0,0,0}; T("sub rsp,imm32", c, 7, -1); }
    { uint8_t c[] = {0x48, 0xB8, 1,2,3,4,5,6,7,8}; T("movabs rax,imm64", c, 10, -1); }
    { uint8_t c[] = {0x4C, 0x8B, 0xC1}; T("mov r8,r9 (REX.WR)", c, 3, -1); }
    { uint8_t c[] = {0x49, 0x8B, 0x00}; T("mov rax,[r8] (REX.B)", c, 3, -1); }
    { uint8_t c[] = {0x48, 0x63, 0xC1}; T("movsxd rax,ecx", c, 3, -1); }

    // ---- legacy prefixes ----
    { uint8_t c[] = {0xF3, 0x0F, 0x1E, 0xFA}; T("endbr64", c, 4, -1); }
    { uint8_t c[] = {0x66, 0x68, 1,0}; T("push imm16 (0x66)", c, 4, -1); }
    { uint8_t c[] = {0xF2, 0x0F, 0x10, 0xC1}; T("movsd xmm0,xmm1", c, 4, -1); }
    { uint8_t c[] = {0xF3, 0x0F, 0x7E, 0xC1}; T("movq xmm0,xmm1", c, 4, -1); }

    // ---- 0F two-byte ----
    { uint8_t c[] = {0x0F, 0x28, 0xC1}; T("movaps xmm0,xmm1", c, 3, -1); }
    { uint8_t c[] = {0x0F, 0x29, 0x44, 0x24, 0x10}; T("movaps [rsp+0x10],xmm0", c, 5, -1); }
    { uint8_t c[] = {0x0F, 0x1F, 0x40, 0x00}; T("nop dword [rax+0x0]", c, 4, -1); }
    { uint8_t c[] = {0x0F, 0x1F, 0x84, 0x00, 0,0,0,0}; T("nop dword [rax+rax*1+0] (SIB+disp32)", c, 8, -1); }
    { uint8_t c[] = {0x0F, 0x05};      T("syscall (known, len given)", c, 2, -1); }
    { uint8_t c[] = {0x0F, 0x0B};      T("ud2 (known, len given)", c, 2, -1); }
    { uint8_t c[] = {0x0F, 0xB9, 0xC1}; T("ud1 (reserved, refused)", c, 0, -1); }
    { uint8_t c[] = {0x0F, 0xFF, 0xC1}; T("ud0 (reserved, refused)", c, 0, -1); }
    { uint8_t c[] = {0x0F, 0xC6, 0xC1, 0x02}; T("shufpd imm8", c, 4, -1); }
    { uint8_t c[] = {0x66, 0x0F, 0xC6, 0xC1, 0x02}; T("shufpd 66 imm8", c, 5, -1); }
    { uint8_t c[] = {0x0F, 0x38, 0x00, 0xC1}; T("0F38 3-byte (pshufb)", c, 4, -1); }
    { uint8_t c[] = {0x66, 0x0F, 0x3A, 0x0C, 0xC1, 0x02}; T("0F3A 3-byte imm8", c, 6, -1); }

    // ---- relative control flow: MUST be rejected (relcf=1) ----
    { uint8_t c[] = {0xE8, 1,2,3,4};   T("call rel32", c, 0, 1); }
    { uint8_t c[] = {0xE9, 1,2,3,4};   T("jmp rel32", c, 0, 1); }
    { uint8_t c[] = {0xEB, 0x10};      T("jmp rel8", c, 0, 1); }
    { uint8_t c[] = {0x74, 0x0A};      T("jz rel8", c, 0, 1); }
    { uint8_t c[] = {0x0F, 0x84, 1,2,3,4}; T("jz rel32 (0F 84)", c, 0, 1); }
    { uint8_t c[] = {0xE3, 0x05};      T("jrcxz rel8", c, 0, 1); }

    // ---- refused: unrecognized opcodes ----
    { uint8_t c[] = {0xD4, 0x30};      T("aam (unsupported)", c, 0, -1); }
    { uint8_t c[] = {0xEA, 1,2,3,4,5,6}; T("far jmp (unsupported)", c, 0, -1); }
    { uint8_t c[] = {0x62, 0xE4};      T("EVEX-braced (misdecode guard)", c, 0, -1); }

    // ---- real MSVC /O2 prologue sequences (the actual hook targets) ----
    { uint8_t c[] = {0x48, 0x89, 0x5C, 0x24, 0x08}; T("pro: mov [rsp+8],rbx", c, 5, -1); }
    { uint8_t c[] = {0x48, 0x89, 0x74, 0x24, 0x10}; T("pro: mov [rsp+0x10],rsi", c, 5, -1); }
    { uint8_t c[] = {0x57};            T("pro: push rdi", c, 1, -1); }
    { uint8_t c[] = {0x48, 0x83, 0xEC, 0x20}; T("pro: sub rsp,0x20", c, 4, -1); }
    { uint8_t c[] = {0x49, 0x8B, 0xC8}; T("pro: mov rcx,r8 (arg shuffle)", c, 3, -1); }

    // ---- the three live 1.19.3 detour targets, byte-exact ----
    // Regression guard for the RIP-relative refusal: if any of these ever
    // starts being flagged, install_abs_jmp would refuse at load time and the
    // DLL would fail to activate. Extracted from hoi4.exe 1.19.3.0
    // (RVAs 0x24B54C0 / 0x540EE0 / 0x550030 — see src/hoi4_offsets.h).
    {
        static const uint8_t findCmd[] = {
            0x48,0x89,0x5C,0x24,0x08, 0x48,0x89,0x6C,0x24,0x10,
            0x48,0x89,0x74,0x24,0x18, 0x48,0x89,0x7C,0x24,0x20,
            0x41,0x54, 0x41,0x56, 0x41,0x57, 0x48,0x83,0xEC,0x20 };
        static const uint8_t effRouter[] = {
            0x48,0x89,0x5C,0x24,0x08, 0x44,0x89,0x4C,0x24,0x20,
            0x55, 0x56, 0x57, 0x41,0x54, 0x41,0x55, 0x41,0x56,
            0x41,0x57, 0x48,0x8D,0xAC,0x24,0x10,0xFD,0xFF,0xFF };
        static const uint8_t trgRouter[] = {
            0x48,0x89,0x5C,0x24,0x10, 0x48,0x89,0x4C,0x24,0x08,
            0x55, 0x56, 0x57, 0x41,0x54, 0x41,0x55, 0x41,0x56,
            0x41,0x57, 0x48,0x8D,0xAC,0x24,0x10,0xFD,0xFF,0xFF };

        // per-instruction: each must decode cleanly and NOT be RIP-relative.
        // Note 0x48 0x8D 0xAC 0x24 ... is lea rbp,[rsp+d32] — SIB form, which
        // is the trap the decoder must not misclassify as RIP-relative.
        const uint8_t *all[] = { findCmd, effRouter, trgRouter };
        const int lens[] = { (int)sizeof(findCmd), (int)sizeof(effRouter), (int)sizeof(trgRouter) };
        const char *names[] = { "FindCommandByName", "EffectRouter", "TriggerRouter" };
        for (int t = 0; t < 3; t++) {
            const uint8_t *code = all[t];
            int off = 0, total = 0, bad = 0, flagged = 0;
            while (off < lens[t]) {
                int rel = 0, rip = 0;
                int n = lde_len(code + off, (uint32_t)(lens[t] - off), &rel, &rip);
                if (n <= 0) { bad = 1; break; }
                if (rip) flagged = 1;
                total += n; off += n;
            }
            g_run++;
            if (bad || flagged || total < 12) {
                g_fail++;
                printf("FAIL %-34s prologue walk: bad=%d rip=%d total=%d (need >=12)\n",
                       names[t], bad, flagged, total);
            }
        }
    }

    // ---- truncated input: must refuse, never guess ----
    { uint8_t c[] = {0x48, 0x8B};      T("truncated modrm", c, 0, -1); }
    { uint8_t c[] = {0x68, 1};         T("truncated imm32", c, 0, -1); }
    { uint8_t c[] = {0x48, 0xB8, 1,2}; T("truncated imm64", c, 0, -1); }
    { uint8_t c[] = {0x0F};            T("lonely 0F", c, 0, -1); }

    // ---- 15-byte ceiling ----
    { uint8_t c[] = {0x66,0x66,0x66,0x66,0x66,0x66,0x66,0x66,0x66,0x66,
                     0x66,0x66,0x0F,0x1F,0xC0}; T("15B prefixed nop (ok)", c, 15, -1); }

    printf("%d/%d passed, %d failed\n", g_run - g_fail, g_run, g_fail);
    return g_fail ? 1 : 0;
}
