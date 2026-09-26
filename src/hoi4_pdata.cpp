// hoi4_pdata.cpp — hoi4.exe .pdata function-boundary table (see hoi4_pdata.h).
#include "hoi4_common.h"
#include "hoi4_pdata.h"

typedef struct { uint32_t begin, end; } PdataFn;

static PdataFn *g_fn;
static int      g_fnN;
static uint64_t g_lo, g_hi;
static volatile LONG g_state;        // 0=uninit 1=building 2=done

int pdata_build(void) {
    if (g_state == 2) return g_fn != NULL;
    if (InterlockedCompareExchange(&g_state, 1, 0) == 0) {
        int ok = 0;
        __try {
            if (g_base) {
                uint8_t *b = (uint8_t *)g_base;
                if (*(uint16_t *)b == 0x5A4D) {
                    uint32_t e = *(uint32_t *)(b + 0x3C);
                    PIMAGE_NT_HEADERS nt = (PIMAGE_NT_HEADERS)(b + e);
                    if (nt->Signature == IMAGE_NT_SIGNATURE) {
                        g_lo = (uint64_t)(uintptr_t)b;
                        g_hi = g_lo + nt->OptionalHeader.SizeOfImage;
                        const IMAGE_DATA_DIRECTORY *dd =
                            nt->OptionalHeader.DataDirectory +
                            IMAGE_DIRECTORY_ENTRY_EXCEPTION;
                        int n = (int)(dd->Size /
                                      sizeof(IMAGE_RUNTIME_FUNCTION_ENTRY));
                        if (n > 0 && dd->VirtualAddress) {
                            PdataFn *arr =
                                (PdataFn *)malloc((size_t)n * sizeof(PdataFn));
                            if (arr) {
                                const uint8_t *p = b + dd->VirtualAddress;
                                for (int i = 0; i < n; i++) {
                                    const IMAGE_RUNTIME_FUNCTION_ENTRY *rf =
                                        (const IMAGE_RUNTIME_FUNCTION_ENTRY *)
                                        (p + (size_t)i * 12);
                                    arr[i].begin = rf->BeginAddress;
                                    arr[i].end   = rf->EndAddress;
                                }
                                g_fn = arr; g_fnN = n; ok = 1;
                                L("[pdata] %d function boundaries, image "
                                  "%llx..%llx", n,
                                  (unsigned long long)g_lo,
                                  (unsigned long long)g_hi);
                            }
                        }
                    }
                }
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) { ok = 0; }
        InterlockedExchange(&g_state, 2);
        return ok;
    }
    while (g_state != 2) Sleep(1);
    return g_fn != NULL;
}

int      pdata_count(void)   { return g_fnN; }
uint64_t pdata_img_lo(void)  { return g_lo; }
uint64_t pdata_img_hi(void)  { return g_hi; }

// index of the greatest entry with begin <= rva; -1 when none
static int pdata_index(uint32_t rva) {
    int lo = 0, hi = g_fnN - 1, ans = -1;
    while (lo <= hi) {
        int mid = (lo + hi) >> 1;
        if (g_fn[mid].begin <= rva) { ans = mid; lo = mid + 1; }
        else hi = mid - 1;
    }
    return ans;
}

uint32_t pdata_func(uint32_t rva) {
    if (!g_fn || g_fnN <= 0) return 0;
    int i = pdata_index(rva);
    return i >= 0 ? g_fn[i].begin : 0;
}

uint32_t pdata_end(uint32_t rva) {
    if (!g_fn || g_fnN <= 0) return 0;
    int i = pdata_index(rva);
    return i >= 0 ? g_fn[i].end : 0;
}

int pdata_is_start(uint32_t rva) {
    return rva != 0 && pdata_func(rva) == rva;
}
