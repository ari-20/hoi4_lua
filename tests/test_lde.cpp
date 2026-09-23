// test_lde.cpp — table-driven unit tests for the hook instruction-length
// decoder (hoi4_lde.h). A wrong length means install_abs_jmp steals
// mid-instruction bytes and the trampoline resumes into garbage — this is
// the cheapest place to catch that class of bug, before it reaches a live
// game process.
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
static void chk(const char *name, const uint8_t *code, int n,
                int wantLen, int wantRel) {
    int rel = -2;
    int got = lde_len(code, (uint32_t)n, &rel);
    g_run++;
    int ok = (got == wantLen);
    if (ok && wantLen == 0 && wantRel == 1) ok = (rel == 1);
    if (!ok) {
        g_fail++;
        printf("FAIL %-28s got len=%d rel=%d, want len=%d rel=%d\n",
               name, got, rel, wantLen, wantRel);
    }
}
#define T(name, arr, len, rel) chk(name, arr, sizeof(arr), len, rel)

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
    { uint8_t c[] = {0x8B, 0x04, 0x25, 1,2,3,4}; T("mov eax,[d32] (SIB abs)", c, 7, -1); }
    { uint8_t c[] = {0x8B, 0x05, 1,2,3,4}; T("mov eax,RIP-rel (mod0 rm5)", c, 6, -1); }
    { uint8_t c[] = {0x8B, 0x44, 0x24, 0x08}; T("mov eax,[rsp+8] (SIB mod1)", c, 4, -1); }

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
