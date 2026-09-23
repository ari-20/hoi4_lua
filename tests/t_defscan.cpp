// t_defscan.cpp — host harness for the defines scanner.
//
// hoi4_defines.cpp is written against the *mapped* image (g_base + RVAs), so it
// cannot run outside the game process. This harness re-implements nothing: it
// loads hoi4.exe, maps it the same way (file offset == RVA for .text on this
// build), points the scanner's g_base at the mapping, and calls the real scan.
//
// It exists to answer one question before shipping: does the C++ sweep find the
// same name->address set as the offline prototype and the committed table?
#define _CRT_SECURE_NO_WARNINGS
#define HOI4_DEFINES_HOST_TEST   // scanner drops hoi4_common.h; we supply g_base/L
#include <winsock2.h>            // before windows.h: ws2def vs winsock ordering
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>

// The scanner's only external dependencies. Declared in the same shape as
// hoi4_common.h so the same source compiles both in-game and here.
uint8_t *g_base = 0;
void L(const char *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    vprintf(fmt, ap);
    printf("\n");
    va_end(ap);
}

#include "../src/hoi4_defines.cpp"

static uint8_t *g_img;
static size_t   g_imgSize;

// Map hoi4.exe so that image_rva(base, rva) == file_offset(rva). The scanner
// walks sections by VA/RVA, so a flat mapping at the preferred base is enough.
// Replicates what the OS loader does to hoi4.exe: headers at the image base,
// every section copied from its raw pointer to its RVA, gaps zeroed. The
// scanner reads both the headers and section contents through g_base, so a
// flat file mapping or a section-only copy would each send it off the end of
// a different structure.
static int map_image(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) { printf("cannot open %s\n", path); return 0; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    g_img = (uint8_t *)VirtualAlloc(NULL, (size_t)n, MEM_COMMIT | MEM_RESERVE,
                                    PAGE_READWRITE);
    if (!g_img) { fclose(f); return 0; }
    if (fread(g_img, 1, (size_t)n, f) != (size_t)n) { fclose(f); return 0; }
    fclose(f);
    g_imgSize = (size_t)n;

    uint32_t e = *(uint32_t *)(g_img + 0x3C);
    uint8_t *nt = g_img + e;
    uint16_t nsec = *(uint16_t *)(nt + 6);
    uint16_t optSize = *(uint16_t *)(nt + 20);
    uint8_t *sec = nt + 24 + optSize;
    uint32_t sizeOfImage = *(uint32_t *)(nt + 24 + 56);
    size_t hdrEnd = (size_t)((sec - g_img) + 40 * (size_t)nsec);

    uint8_t *mapped = (uint8_t *)VirtualAlloc(NULL, sizeOfImage,
                                              MEM_COMMIT | MEM_RESERVE,
                                              PAGE_READWRITE);
    if (!mapped) return 0;
    if (hdrEnd > g_imgSize) hdrEnd = g_imgSize;
    if (hdrEnd > sizeOfImage) hdrEnd = sizeOfImage;
    memcpy(mapped, g_img, hdrEnd);

    for (int i = 0; i < nsec; i++) {
        uint8_t *s = sec + 40 * i;
        uint32_t vsz = *(uint32_t *)(s + 8);
        uint32_t va  = *(uint32_t *)(s + 12);
        uint32_t rsz = *(uint32_t *)(s + 16);
        uint32_t ra  = *(uint32_t *)(s + 20);
        if (va >= sizeOfImage) continue;
        // The loader maps max(vsize, rawsize) bytes; a section whose raw size
        // exceeds its virtual size (padding) still lands at its own RVA. Both
        // are clipped so a malformed table cannot run off either buffer.
        size_t cpy = rsz > vsz ? rsz : vsz;
        if (cpy > sizeOfImage - va) cpy = sizeOfImage - va;
        if (ra + cpy > g_imgSize) cpy = g_imgSize - ra;
        memcpy(mapped + va, g_img + ra, cpy);
    }
    VirtualFree(g_img, 0, MEM_RELEASE);
    g_img = mapped;
    g_imgSize = sizeOfImage;
    g_base = mapped;
    return 1;
}

int main(int argc, char **argv) {
    const char *exe = argc > 1 ? argv[1] : "D:/game/hoi4_backup_1_19_3/hoi4.exe";
    if (!map_image(exe)) { printf("map failed\n"); return 1; }

    DWORD t0 = GetTickCount();
    int n = hoi4_defines_scan();
    DWORD dt = GetTickCount() - t0;
    printf("scan rc=%d count=%d in %lu ms\n", n, hoi4_defines_count(), dt);
    if (n < 0) return 1;

    // dump for comparison
    if (argc > 2) {
        FILE *o = fopen(argv[2], "w");
        const char *nm; uint32_t rva;
        for (int i = 0; i < hoi4_defines_count(); i++)
            if (hoi4_defines_at(i, &nm, &rva)) fprintf(o, "%s\t%X\n", nm, rva);
        fclose(o);
        printf("wrote %s\n", argv[2]);
    }

    // spot checks against known values
    const char *probe[] = {"GAME_SPEED_SECONDS", "OUT_OF_SUPPLY_SPEED",
                           "MAX_CIV_FACTORIES_PER_LINE", "END_DATE", NULL};
    for (int i = 0; probe[i]; i++) {
        uint32_t rva = 0;
        if (hoi4_defines_lookup(probe[i], &rva)) printf("  %-32s %X\n", probe[i], rva);
        else printf("  %-32s MISS\n", probe[i]);
    }
    return 0;
}
