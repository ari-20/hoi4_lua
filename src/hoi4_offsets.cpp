// hoi4_offsets.cpp — image address table publish + signature verification.
//
// The table itself lives in hoi4_offsets.h (compiled in — the DLL ships as a
// single file). This module copies it into the runtime g_rva[] backing the
// RVA_* macros, and verifies the RUNNING game image against the table's PE
// signature before any patching happens (fail closed on version drift).
#include "hoi4_common.h"
#include "hoi4_offsets.h"

uint64_t g_rva[OFF_COUNT];

const char *offsets_version(void) { return OFF_VERSION; }

static int verify_image(void) {
    IMAGE_DOS_HEADER *dos = (IMAGE_DOS_HEADER *)g_base;
    IMAGE_NT_HEADERS *nt;
    __try {
        if (!dos || dos->e_magic != IMAGE_DOS_SIGNATURE) return 0;
        nt = (IMAGE_NT_HEADERS *)(g_base + dos->e_lfanew);
        if (nt->Signature != IMAGE_NT_SIGNATURE) return 0;
        DWORD its  = nt->FileHeader.TimeDateStamp;
        DWORD isz  = nt->OptionalHeader.SizeOfImage;
        DWORD isum = nt->OptionalHeader.CheckSum;
        L("[ver] image TimeDateStamp=%08X SizeOfImage=%X CheckSum=%08X "
          "(table expects %08X/%X/%08X)", its, isz, isum,
          OFF_TIMESTAMP, OFF_IMAGE_SIZE, OFF_CHECKSUM);
        return its == OFF_TIMESTAMP && isz == OFF_IMAGE_SIZE &&
               isum == OFF_CHECKSUM;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

int offsets_load(void) {
    if (!verify_image()) {
        L("[off] game image signature mismatch — refusing to patch "
          "(table is for %s)", OFF_VERSION);
        return 0;
    }
    memcpy(g_rva, kOffValues, sizeof(g_rva));
    L("[off] offsets loaded: %d entries, version %s", OFF_COUNT, OFF_VERSION);
    return 1;
}
