// hoi4_pdata.h — hoi4.exe .pdata (PE exception directory) function table.
//
// The exception directory is a RUN table: one 12-byte
// IMAGE_RUNTIME_FUNCTION_ENTRY per function that HAS unwind info, holding
// {BeginAddress, EndAddress, UnwindData} as image RVAs, sorted by begin.
// Parsing it in-process yields every function's exact boundaries with no
// symbol file and no per-version data file.
//
// Two consumers:
//   * hoi4_sampler.cpp — attributes a sampled RIP to its function.
//   * hoi4_hook.cpp    — Tier 2 detour target qualification. A detour may only
//     patch a function START, and its stolen-byte window must stay inside that
//     function (DETOUR_DESIGN.md G2/G3). Stealing past the end of a short
//     function would eat the NEXT function's first bytes.
//
// COVERAGE CAVEAT (fail-closed by contract): only functions WITH unwind info
// appear. A leaf function needing no unwind data may be absent, and "absent"
// must be read as "not patchable" — never as "no constraint".
#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int      pdata_build(void);             // idempotent; 1 = table ready
int      pdata_count(void);             // entries (0 before a successful build)
uint64_t pdata_img_lo(void);            // hoi4.exe image base
uint64_t pdata_img_hi(void);            // base + SizeOfImage

// Greatest function start <= rva (0 = rva precedes the first entry, or no
// table). This is the sampler's attribution rule: an RIP in inter-function
// padding still reports the preceding function, which is what the profiler
// has always shown.
uint32_t pdata_func(uint32_t rva);

// End RVA (exclusive) of the function that pdata_func(rva) returns; 0 = none.
uint32_t pdata_end(uint32_t rva);

// 1 when rva is EXACTLY a function start. The detour install gate requires
// this: patching mid-function would rewrite bytes some other branch may target.
int      pdata_is_start(uint32_t rva);

#ifdef __cplusplus
}
#endif
