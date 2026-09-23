// hoi4_defines.cpp — runtime defines name->address recovery from the game image.
//
// WHY THIS EXISTS
// The engine registers every `common/defines/*.txt` entry by calling a loader
// with the name and the destination address as compile-time constants:
//
//     lea r8,  [<target global>]      ; 4c 8d 05 <disp32>
//     lea rdx, [<name string>]        ; 48 8d 15 <disp32>
//     lea rcx, [rsp+<n>]              ; 48 8d 4c 24 <n>
//     call <loader>                   ; e8 <rel32>
//
// So the name->address map is not a runtime lookup table anywhere: it is baked
// into the code bytes, once per define. That makes it recoverable from the
// image in the process, with no companion data file and no per-game-version
// regeneration step — the previous approach (scanner over an offline
// disassembly dump, output consumed by resource.lua) needed a re-run on every
// game update AND shipped a file the mod had to find on disk.
//
// IDENTIFICATION
// The signature above is generic enough to match unrelated registrations, so a
// candidate is only accepted when its NAME also appears in a loader diagnostic
// string: the family emits `Error reading "NAME"` / `no lua object named X`.
// That guard is what separates defines from the other same-shaped registries
// (modifier, gfx, ...). Measured against the committed 1.19.3 table: 0 misses,
// all 4424 addresses identical, plus 18 genuine defines the offline scanner had
// missed (mostly *_COLOR entries).
//
// The scan is a byte sweep over the image, run once per session and cached. It
// is deliberately NOT exposed as a per-lookup Lua call: mod Lua reads memory
// one typed access at a time, so a multi-megabyte sweep from Lua would stall
// the frame and trip the bridge's heartbeat. One C-side sweep, then O(1)
// lookups.

#if defined(HOI4_DEFINES_HOST_TEST)
// Host-test build (tests/t_defscan.cpp): the scanner is compiled without the
// bridge's common header, so the two symbols it uses are supplied by the
// harness. Keeping the scanner free of other dependencies is what makes it
// testable outside the game process at all.
extern uint8_t *g_base;
void L(const char *fmt, ...);
#else
#include "hoi4_common.h"
#endif

#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>


#define DEF_MAX_NAMES   8192      // 4442 seen on 1.19.3; headroom for mods
#define DEF_MAX_TARGETS 4         // same name registered to >1 namespace
#define DEF_NAME_MAX    64

typedef struct {
    char     name[DEF_NAME_MAX];
    uint32_t rva[DEF_MAX_TARGETS];
    int      count;
} DefEntry;

static DefEntry *g_defs;
static int       g_defCount;
static int       g_defTried;      // scan attempted (success or not)
static uint32_t  g_defScannedImageSize;

// ---------------------------------------------------------------- PE helpers

typedef struct {
    uint8_t *base;
    size_t   size;
    uint8_t *hdr;      // section table
    uint16_t nsec;
} ImageView;

// The module is the running hoi4.exe; offsets_load() already pinned g_base.
static int img_init(ImageView *v) {
    uint8_t *b = (uint8_t *)(uintptr_t)g_base;
    if (!b) return 0;
    v->base = b;

    // Read the PE headers defensively: the image is mapped read-only, but a
    // malformed/hostile header must not walk us off the end.
    __try {
        if (b[0] != 'M' || b[1] != 'Z') return 0;
        uint32_t e_lfanew = *(uint32_t *)(b + 0x3C);
        if (e_lfanew < 0x40 || e_lfanew > 0x1000) return 0;
        uint8_t *nt = b + e_lfanew;
        if (nt[0] != 'P' || nt[1] != 'E' || nt[2] != 0 || nt[3] != 0) return 0;
        uint16_t nsec = *(uint16_t *)(nt + 6);
        if (nsec == 0 || nsec > 96) return 0;
        uint16_t optSize = *(uint16_t *)(nt + 20);
        uint8_t *opt = nt + 24;
        uint16_t magic = *(uint16_t *)opt;
        if (magic != 0x20B) return 0;                 // PE32+ only
        uint32_t sizeOfImage = *(uint32_t *)(opt + 56);
        if (sizeOfImage < 0x1000 || sizeOfImage > 0x20000000) return 0;
        v->size = sizeOfImage;
        v->hdr  = opt + optSize;                      // section table
        v->nsec = nsec;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
    return 1;
}

static int img_sec(const ImageView *v, int i, uint8_t **outName8, size_t *outNameLen,
                   uint32_t *outVA, uint32_t *outVSize, uint32_t *outRawSize) {
    uint8_t *sec = v->hdr + 40 * (size_t)i;
    __try {
        *outName8 = sec;
        *outNameLen = 8;
        *outVSize = *(uint32_t *)(sec + 8);
        *outVA    = *(uint32_t *)(sec + 12);
        *outRawSize = *(uint32_t *)(sec + 16);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
    return 1;
}

// The image is mapped, so a section's contents live at base + RVA: there is no
// separate file-offset step (that only exists in the on-disk image). The check
// below therefore validates that an RVA lands inside SOME section and returns
// the RVA unchanged. Subtracting the section VA here (the on-disk instinct)
// reads garbage well before the section start — the bug that made the first
// in-game sweep match nothing.
static int img_rva_ok(const ImageView *v, uint32_t rva) {
    if (rva == 0 || rva >= v->size) return 0;
    for (int i = 0; i < v->nsec; i++) {
        uint8_t *nm; size_t nl; uint32_t va, vs, rs;
        if (!img_sec(v, i, &nm, &nl, &va, &vs, &rs)) return 0;
        uint32_t span = vs > rs ? vs : rs;
        if (rva >= va && rva < va + span) return 1;
    }
    return 0;
}

// ------------------------------------------------------------------ strings

// Bounded printable-ASCII string read, used for both the name and the
// diagnostic tables. Returns length or 0.
static size_t img_str(const ImageView *v, uint32_t off, char *out, size_t cap) {
    if (off == 0 || off >= v->size) return 0;
    size_t n = 0;
    __try {
        while (n + 1 < cap) {
            uint8_t c = v->base[off + n];
            if (c == 0) break;
            if (c < 0x20 || c > 0x7E) return 0;       // not a plain string
            out[n] = (char)c;
            n++;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
    if (n == 0 || n + 1 >= cap) return 0;
    out[n] = 0;
    return n;
}

// -------------------------------------------------- diagnostic-name hash set
// The guard set is ~4.4k names; a linear scan per candidate would be ~20M
// comparisons. A small open-addressed table keyed on FNV-1a keeps the sweep
// linear.

typedef struct { uint64_t hash; uint32_t next; } DiagSlot;
static uint32_t *g_diagBuckets;   // bucket -> head index (0 = empty)
static DiagSlot *g_diagSlots;
static uint32_t  g_diagSlotsUsed, g_diagSlotsCap, g_diagBucketMask;

static uint64_t fnv1a(const char *s) {
    uint64_t h = 1469598103934665603ULL;
    for (; *s; s++) {
        h ^= (uint8_t)*s;
        h *= 1099511628211ULL;
    }
    return h;
}

static int diag_add(uint64_t h) {
    uint32_t b = (uint32_t)(h & g_diagBucketMask);
    for (uint32_t i = g_diagBuckets[b]; i; i = g_diagSlots[i - 1].next)
        if (g_diagSlots[i - 1].hash == h) return 1;   // already present
    if (g_diagSlotsUsed >= g_diagSlotsCap) return 0;
    uint32_t idx = ++g_diagSlotsUsed;
    g_diagSlots[idx - 1].hash = h;
    g_diagSlots[idx - 1].next = g_diagBuckets[b];
    g_diagBuckets[b] = idx;
    return 1;
}

static int diag_has(uint64_t h) {
    uint32_t b = (uint32_t)(h & g_diagBucketMask);
    for (uint32_t i = g_diagBuckets[b]; i; i = g_diagSlots[i - 1].next)
        if (g_diagSlots[i - 1].hash == h) return 1;
    return 0;
}

// ------------------------------------------------------------------- entries

static DefEntry *def_find(const char *name, int create) {
    for (int i = 0; i < g_defCount; i++)
        if (strcmp(g_defs[i].name, name) == 0) return &g_defs[i];
    if (!create || g_defCount >= DEF_MAX_NAMES) return NULL;
    DefEntry *e = &g_defs[g_defCount++];
    memset(e, 0, sizeof(*e));
    strncpy_s(e->name, DEF_NAME_MAX, name, _TRUNCATE);
    return e;
}

static void def_add_target(DefEntry *e, uint32_t rva) {
    for (int i = 0; i < e->count; i++)
        if (e->rva[i] == rva) return;
    if (e->count < DEF_MAX_TARGETS) e->rva[e->count++] = rva;
}

// ----------------------------------------------------------------- the scan

// Collects every `Error reading "NAME"` occurrence into the guard set.
//
// The name is taken from INSIDE the quotes, not from the whole C string. The
// full diagnostic is `Error reading "NAME": no lua object named NAI\n` — the
// trailing text and the newline both fail a plain printable-C-string read, so
// reading past the closing quote yields nothing and the guard set comes out
// empty (which is exactly how the first in-game run failed: rc=-3).
static int scan_diagnostics(const ImageView *v) {
    static const char MARK[] = "Error reading \"";
    const size_t markLen = sizeof(MARK) - 1;
    if (v->size < markLen) return 0;

    // Bucket count is a power of two above 4x the expected name count.
    uint32_t buckets = 16384;
    g_diagBucketMask = buckets - 1;
    g_diagSlotsCap = 16384;
    g_diagBuckets = (uint32_t *)calloc(buckets, sizeof(uint32_t));
    g_diagSlots = (DiagSlot *)calloc(g_diagSlotsCap, sizeof(DiagSlot));
    if (!g_diagBuckets || !g_diagSlots) return 0;

    char name[DEF_NAME_MAX];
    for (size_t i = 0; i + markLen + 2 < v->size; i++) {
        if (v->base[i] != 'E') continue;              // cheap first-byte filter
        if (memcmp(v->base + i, MARK, markLen) != 0) continue;
        // Read only up to the closing quote, and require plain printable ASCII
        // so a false `Error reading "` inside unrelated data cannot inject.
        size_t n = 0;
        __try {
            while (n + 1 < DEF_NAME_MAX) {
                uint8_t c = v->base[i + markLen + n];
                if (c == '"') break;
                if (c < 0x20 || c > 0x7E) { n = 0; break; }
                name[n++] = (char)c;
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            n = 0;
        }
        i += markLen;
        if (n < 4) continue;                 // short names are not defines
        name[n] = 0;
        diag_add(fnv1a(name));
    }
    return g_diagSlotsUsed > 0;
}

#define DISP32(p) (*(const int32_t *)(p))

// Sweeps .text for the 4-instruction registration signature.
static int scan_sites(const ImageView *v) {
    for (int s = 0; s < v->nsec; s++) {
        uint8_t *nm; size_t nl; uint32_t va, vs, rs;
        if (!img_sec(v, s, &nm, &nl, &va, &vs, &rs)) continue;
        if (nl < 5 || memcmp(nm, ".text", 5) != 0) continue;

        size_t end = (size_t)(vs > rs ? rs : vs);
        if (end < 20) continue;
        for (size_t i = 0; i + 20 <= end; i++) {
            const uint8_t *p = v->base + va + i;
            __try {
                // sequential state machine over the four instructions
                if (p[0] != 0x4C || p[1] != 0x8D || p[2] != 0x05) continue;
                if (p[7] != 0x48 || p[8] != 0x8D || p[9] != 0x15) continue;
                if (p[14] != 0x48 || p[15] != 0x8D ||
                    p[16] != 0x4C || p[17] != 0x24) continue;
                if (p[19] != 0xE8) continue;

                uint32_t globRva = (uint32_t)((int64_t)(va + i + 7) + DISP32(p + 3));
                uint32_t nameRva = (uint32_t)((int64_t)(va + i + 14) + DISP32(p + 10));
                if (!img_rva_ok(v, globRva)) continue;

                char name[DEF_NAME_MAX];
                size_t len = img_str(v, nameRva, name, DEF_NAME_MAX);
                if (len < 4) continue;
                if (!diag_has(fnv1a(name))) continue;   // the defines guard

                DefEntry *e = def_find(name, 1);
                if (e) def_add_target(e, globRva);
                i += 19;
            } __except (EXCEPTION_EXECUTE_HANDLER) {
                // A fault here means the header lied about the extent; stop.
                return g_defCount > 0;
            }
        }
    }
    return 1;
}

// ------------------------------------------------------------- public entry

// One sweep per session. Idempotent; safe to call from any Lua entry point.
// Returns the entry count, or a negative value when the scan could not run.
int hoi4_defines_scan(void) {
    if (g_defTried) return g_defCount;
    g_defTried = 1;

    ImageView v;
    memset(&v, 0, sizeof(v));
    if (!img_init(&v)) { L("[defines] img_init failed"); return -1; }
    L("[defines] image ok: size=%u nsec=%d hdr=%p",
      (unsigned)v.size, (int)v.nsec, (void *)v.hdr);

    g_defs = (DefEntry *)calloc(DEF_MAX_NAMES, sizeof(DefEntry));
    if (!g_defs) return -2;

    if (!scan_diagnostics(&v)) {
        L("[defines] diagnostic guard set empty - refusing to guess");
        return -3;
    }
    scan_sites(&v);

    g_defScannedImageSize = (uint32_t)v.size;
    L("[defines] %d names from %u bytes (guard set %u); %d entries",
      g_defCount, (unsigned)g_defScannedImageSize, g_diagSlotsUsed,
      g_defCount);
    return g_defCount;
}

int hoi4_defines_count(void) {
    if (!g_defTried) hoi4_defines_scan();
    return g_defCount;
}

// Index-ordered accessor (Lua tables have no stable cursor; the caller walks
// 1..count). Returns 0 when the index is out of range.
int hoi4_defines_at(int idx, const char **name, uint32_t *rva) {
    if (!g_defTried) hoi4_defines_scan();
    if (idx < 0 || idx >= g_defCount) return 0;
    *name = g_defs[idx].name;
    *rva  = g_defs[idx].rva[0];         // first namespace wins, matching the
    return 1;                           // historical "first hit" semantics
}

// Direct lookup, used by the Lua M.define path so a lookup is O(n) over the
// cached array instead of building the whole table in Lua first.
int hoi4_defines_lookup(const char *name, uint32_t *rva) {
    if (!name || !*name) return 0;
    if (!g_defTried) hoi4_defines_scan();
    for (int i = 0; i < g_defCount; i++) {
        if (g_defs[i].name[0] != name[0]) continue;
        if (strcmp(g_defs[i].name, name) == 0) {
            *rva = g_defs[i].rva[0];
            return 1;
        }
    }
    return 0;
}

// All target RVAs for a name, in scan order. A define registered into several
// namespaces has one storage slot per namespace; the caller must choose by the
// value it expects, because both slots are legitimately populated.
int hoi4_defines_targets(const char *name, uint32_t *out, int cap) {
    if (!name || !*name || !out || cap <= 0) return 0;
    if (!g_defTried) hoi4_defines_scan();
    for (int i = 0; i < g_defCount; i++) {
        if (g_defs[i].name[0] != name[0]) continue;
        if (strcmp(g_defs[i].name, name) != 0) continue;
        int n = g_defs[i].count;
        if (n > cap) n = cap;
        for (int k = 0; k < n; k++) out[k] = g_defs[i].rva[k];
        return n;
    }
    return 0;
}
