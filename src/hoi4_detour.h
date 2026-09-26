// hoi4_detour.h — internal contract of the Tier 2 detour engine.
//
// NOT mod-facing. The mod-facing hook API is hoi4.hook_vt / hoi4.detour, whose
// contract lives in hoi4_hook.h. This header only exposes the code-patching
// primitives so hoi4_hook.cpp can install a function-body detour without
// duplicating the LDE / trampoline / patch logic that hoi4_detour.cpp owns.
//
// Three primitives, in install order:
//   detour_steal_len        — how many WHOLE instructions must be stolen (G4)
//   detour_make_trampoline  — the RX replay block (stolen bytes + jump back)
//   detour_patch_entry      — the suspend-and-verify entry patch (G10)
//
// The framework's own three detours (FindCommandByName / EffectRouter /
// TriggerRouter) are installed by install_abs_jmp at DllMain time and register
// their byte windows here, so a mod detour can refuse to overlap them (G5/G6).
#pragma once
#include <stdint.h>
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

// Outbound entry patch: movabs rax,imm64 ; jmp rax  (12 bytes), NOP-padded out
// to the stolen instruction boundary.
#define DT_ENTRY_PATCH_BYTES 12

// Steal >= minBytes of WHOLE instructions at [target]. Returns the byte count,
// or 0 with *why set to a static reason (unrecognized opcode / relative
// control flow / RIP-relative operand / past maxBytes). `why` may be NULL.
int detour_steal_len(const uint8_t *target, int minBytes, int maxBytes,
                     const char **why);

// Build a trampoline replaying `stolen` bytes then jumping to target+stolen.
// Returns an RX (W^X) executable block, or NULL. Never freed: a detour is
// permanent by design (DETOUR_DESIGN.md §3.3 — there is no uninstall).
void *detour_make_trampoline(uint8_t *target, int stolen);

// Apply the entry patch with a suspend-and-verify window (DETOUR_DESIGN.md
// §3.1.2). Every other thread in the process is suspended, each one's RIP is
// checked against [target, target+stolen), and the patch is applied only if
// none is inside. All threads are resumed before returning.
//
// Thread handles and any allocation are acquired BEFORE the first suspend, and
// nothing between suspend and resume takes a user-mode lock — that is what
// makes the window deadlock-free even if a suspended thread holds the loader
// lock or the heap lock. Callers must not log from inside either.
//
// Returns 1 on success. On 0:
//   *outHitTid != 0  -> that thread's RIP was inside the window (refused)
//   *outHitTid == 0  -> could not suspend/inspect every thread (refused)
// Either way NOT ONE BYTE was written.
int detour_patch_entry(uint8_t *target, int stolen, void *entry,
                       int *outThreads, unsigned long *outHitTid);

// Byte windows already patched by this process (the framework's own detours,
// plus every Tier 2 detour committed through detour_patch_entry). Writes up to
// `cap` {lo,hi} pairs and returns how many exist in total.
#define DT_MAX_WINDOWS_REPORT 32
int detour_windows(uint64_t *lo, uint64_t *hi, int cap);

#ifdef __cplusplus
}
#endif
