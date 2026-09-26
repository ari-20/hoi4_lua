#include "hoi4_common.h"
#include <stdlib.h>   // malloc: the 128 KB string scratch is heap, not stack

// -+ generic read/write primitives ----
// -+ generic read primitives
// Version-agnostic raw-memory reads. ALL structure knowledge lives in the Lua
// layout file; the DLL never changes when layouts drift across game versions.
// Convention: addresses are absolute runtime addresses passed as Lua integers.
// Every primitive is SEH-guarded and returns nil on fault (never crashes).

static uint64_t check_addr(lua_State *Ls, int n) {
    return (uint64_t)luaL_checkinteger(Ls, n);
}

// Upper bound for the string readers. The old 255-byte cap silently truncated
// real data (localisation values reach 371 chars, the longest printable run in
// the image is ~12 KB), so a 256-byte ceiling clipped them with no signal.
// 128 KB covers any string the engine stores with a wide margin.
#define STR_READ_MAX (128u * 1024u)

// Caller-supplied size cap for read_bytes: memory is attacker-adjacent here
// (any address can be passed), so an unbounded length would let one call walk
// gigabytes. 64 MB is far past any real structure and still bounded.
#define BYTES_READ_MAX (64u * 1024u * 1024u)

// Scratch buffer for the string readers. At 128 KB this is allocated once on
// first use, NOT per call: a stack buffer of that size would push a 128 KB
// frame on every lookup, and this project has already been bitten by a tight
// stack (see the async worker's explicit 4 MB in hoi4_async.cpp). Lazy so a
// session that never reads a long string pays nothing.
//
// Threading: these readers are only reachable from the MAIN VM. The async
// worker is a second lua_State with just hoi4_register_http attached, so it
// cannot call them -- hence a single static buffer needs no lock. If a read
// primitive is ever registered on a worker, this must become thread-local.
//
// Lifetime: the buffer is reused across calls, so any future primitive that
// hands out a POINTER into it would alias. Today every user copies out with
// lua_pushlstring before returning, which keeps the sharing safe.
static char *str_scratch(void) {
    static char *buf;
    if (!buf) buf = (char *)malloc(STR_READ_MAX + 1);
    return buf;
}

int hoi4_base(lua_State *Ls) {
    lua_pushinteger(Ls, (lua_Integer)g_base);
    return 1;
}

// session-switch event raised but not yet dispatched by the frame-top
// consumer — a world rebuild runs inside that window (see hoi4_session.cpp).
// Mod detour callbacks use this to let build-time engine calls through.
int hoi4_session_pending(lua_State *Ls) {
    lua_pushboolean(Ls, session_pending());
    return 1;
}

// lightuserdata -> integer (Lua cannot do arithmetic on userdata)
int hoi4_to_number(lua_State *Ls) {
    void *p = lua_touserdata(Ls, 1);
    if (!p) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, (lua_Integer)(uintptr_t)p);
    return 1;
}

// u64 is a WIDTH name, NOT a value-range promise. The 64-bit pattern moves
// in/out of a lua_Integer (int64) unchanged: there is no wider Lua type to
// zero-extend into, so a value with bit 63 set ARRIVES AS A NEGATIVE Lua
// integer (0xFFFFFFFFFFFFFFF1 -> -15) and write_u64 sends it back verbatim.
// The round trip is exact; "unsigned" is a display concern (%u / %x).
// There is deliberately no read_i64: it would be byte-identical to this one.
// The narrow readers differ -- u8/u16/u32 zero-extend into the non-negative
// half, so their sign must be restored by hand (GAME.layout.as_iN, book 3.7).
int hoi4_read_u64(lua_State *Ls) {
    __try { lua_pushinteger(Ls, (lua_Integer)*(volatile uint64_t *)check_addr(Ls, 1)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

int hoi4_read_u32(lua_State *Ls) {
    __try { lua_pushinteger(Ls, *(volatile uint32_t *)check_addr(Ls, 1)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

int hoi4_read_u16(lua_State *Ls) {
    __try { lua_pushinteger(Ls, *(volatile uint16_t *)check_addr(Ls, 1)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

int hoi4_read_u8(lua_State *Ls) {
    __try { lua_pushinteger(Ls, *(volatile uint8_t *)check_addr(Ls, 1)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

int hoi4_read_f32(lua_State *Ls) {
    __try { lua_pushnumber(Ls, (double)*(volatile float *)check_addr(Ls, 1)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

int hoi4_read_f64(lua_State *Ls) {
    __try { lua_pushnumber(Ls, *(volatile double *)check_addr(Ls, 1)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

// read a raw NUL-terminated C string, nil on fault.
// No charset filter: bytes pass through verbatim, so UTF-8 round-trips (unlike
// read_str's long-string path, which used to reject it).
int hoi4_read_cstr(lua_State *Ls) {
    char *buf = str_scratch();
    if (!buf) { lua_pushnil(Ls); return 1; }
    __try {
        const char *p = (const char *)check_addr(Ls, 1);
        uint64_t n = 0;
        while (n < STR_READ_MAX && p[n]) n++;
        if (n == 0 && p[0] != 0) { lua_pushnil(Ls); return 1; }
        memcpy(buf, p, (size_t)n);
        lua_pushlstring(Ls, buf, (size_t)n);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

// read an MSVC-layout std::string (compiler ABI, stable across game versions)
// {ptr/inline[16], len@+0x10, cap@+0x18}; len>15 means heap.
// A string longer than STR_READ_MAX is TRUNCATED, not rejected -- callers that
// need to detect that compare the result against the length field themselves
// (the Lua layer already does: M.read_msvc_str checks #s == len).
//
// Content stops at the first NUL in BOTH paths, len only bounds the read. An
// SSO buffer is 16 bytes and a short string leaves its tail zeroed, so sending
// `len` bytes verbatim would hand back "_refit_speed\0\0\0" for a 12-char
// name -- a NUL-padded string that fails any charset check downstream. The
// field says how much is ALLOCATED; the text ends where the NUL does.
int hoi4_read_str(lua_State *Ls) {
    char *buf = str_scratch();
    if (!buf) { lua_pushnil(Ls); return 1; }
    __try {
        uint64_t s = check_addr(Ls, 1);
        uint64_t len = *(volatile uint64_t *)(s + 0x10);
        if (len > STR_READ_MAX) len = STR_READ_MAX;
        // len>15 means the 16-byte inline buffer holds a pointer; otherwise the
        // characters live in the buffer itself. Both are read the same way
        // afterward -- NUL-terminated -- so the branch only picks the base.
        const char *base = (const char *)(uintptr_t)s;
        const char *p = base;
        if (len > 15) p = *(const char *const *)(uintptr_t)s;
        uint64_t n = 0;
        while (n < len && p[n]) n++;
        memcpy(buf, p, (size_t)n);
        lua_pushlstring(Ls, buf, (size_t)n);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

// read_bytes(addr, n) -> string of exactly n bytes, verbatim.
//
// The missing primitive: read_cstr stops at a NUL and read_str needs a
// std::string object, so neither can return a fixed-size buffer, a binary
// blob, or any run containing a zero byte. One lua_pushlstring delivers the
// whole run, so Lua-side find/sub/match then run in C instead of a per-byte
// loop (measured ~29x on the export's name path).
int hoi4_read_bytes(lua_State *Ls) {
    __try {
        uint64_t addr = check_addr(Ls, 1);
        lua_Integer want = luaL_checkinteger(Ls, 2);
        if (want < 0) { lua_pushnil(Ls); return 1; }
        uint64_t n = (uint64_t)want;
        if (n > BYTES_READ_MAX) { lua_pushnil(Ls); return 1; }
        lua_pushlstring(Ls, (const char *)(uintptr_t)addr, (size_t)n);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); }
    return 1;
}

// -+ write primitives
// Same convention as reads: absolute address, SEH-guarded, return true/false.
// DANGEROUS by design — the Lua layout file owns all offset knowledge.
// WRITE-DOMAIN GATE (hoi4_memgate.cpp, policy 2026-09-23): every target is
// checked before the store — committed writable non-executable pages, in no
// module except hoi4.exe, off the current thread's TEB/stack. Read-only pages
// (game .text/.rdata/IAT) and foreign-module data are refused with an audit
// line instead of a bare SEH false; with the call gate there is no reachable
// VirtualProtect, so this cannot be unlocked from Lua.
// write_str is CAPACITY-BOUNDED ONLY: if the new text does not fit the existing
// std::string capacity (SSO 15 or heap cap), it refuses (returns false) rather
// than calling the engine allocator — a reallocation needs its ABI and risks
// dangling pointers elsewhere.

// Denial tail: false is already on the stack; log + audit, keep the shape of
// "refused, never crashed".
static int wr_denied(lua_State *Ls, const char *api, uint64_t a) {
    L("[mem] %s denied @%llx (write domain)", api, (unsigned long long)a);
    audit_mem_deny(Ls, "write", a, "write-domain gate");
    return 1;
}

// Read-back verification tail. A store that silently does NOT stick was the
// invisible failure mode: every hoi4.write_* caller ignores the return value,
// and the success path used to report true unconditionally. Callers re-read the
// same width and compare RAW BYTES (bit patterns), so NaN/denormal round-trips
// verify correctly where float == would not. `false` is already on the stack.
static int wr_no_stick(lua_State *Ls, const char *api, uint64_t a) {
    audit_mem_deny(Ls, "write_verify", a, "read-back mismatch");
    return 1;
}

int hoi4_write_u8(lua_State *Ls) {
    uint64_t a = check_addr(Ls, 1);
    uint8_t v = (uint8_t)luaL_checkinteger(Ls, 2);
    lua_pushboolean(Ls, 0);
    if (!memgate_write_ok(a, 1)) return wr_denied(Ls, "write_u8", a);
    __try {
        *(volatile uint8_t *)a = v;
        uint8_t got = *(volatile uint8_t *)a;
        if (got != v) {
            L("[mem] write_u8 read-back mismatch @%llx (want %02x got %02x)",
              (unsigned long long)a, (unsigned)v, (unsigned)got);
            return wr_no_stick(Ls, "write_u8", a);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

int hoi4_write_u16(lua_State *Ls) {
    uint64_t a = check_addr(Ls, 1);
    uint16_t v = (uint16_t)luaL_checkinteger(Ls, 2);
    lua_pushboolean(Ls, 0);
    if (!memgate_write_ok(a, 2)) return wr_denied(Ls, "write_u16", a);
    __try {
        *(volatile uint16_t *)a = v;
        uint16_t got = *(volatile uint16_t *)a;
        if (got != v) {
            L("[mem] write_u16 read-back mismatch @%llx (want %04x got %04x)",
              (unsigned long long)a, (unsigned)v, (unsigned)got);
            return wr_no_stick(Ls, "write_u16", a);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

int hoi4_write_u32(lua_State *Ls) {
    uint64_t a = check_addr(Ls, 1);
    uint32_t v = (uint32_t)luaL_checkinteger(Ls, 2);
    lua_pushboolean(Ls, 0);
    if (!memgate_write_ok(a, 4)) return wr_denied(Ls, "write_u32", a);
    __try {
        *(volatile uint32_t *)a = v;
        uint32_t got = *(volatile uint32_t *)a;
        if (got != v) {
            L("[mem] write_u32 read-back mismatch @%llx (want %08x got %08x)",
              (unsigned long long)a, v, got);
            return wr_no_stick(Ls, "write_u32", a);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

int hoi4_write_u64(lua_State *Ls) {
    uint64_t a = check_addr(Ls, 1);
    uint64_t v = (uint64_t)luaL_checkinteger(Ls, 2);
    lua_pushboolean(Ls, 0);
    if (!memgate_write_ok(a, 8)) return wr_denied(Ls, "write_u64", a);
    __try {
        *(volatile uint64_t *)a = v;
        uint64_t got = *(volatile uint64_t *)a;
        if (got != v) {
            L("[mem] write_u64 read-back mismatch @%llx (want %016llx got %016llx)",
              (unsigned long long)a, (unsigned long long)v,
              (unsigned long long)got);
            return wr_no_stick(Ls, "write_u64", a);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

// f32/f64 store the exact IEEE bit pattern and verify the same way. Comparing
// floats with == would fail to verify NaN (NaN != NaN) and could mask a
// signaling-bit rewrite, so the integer view is used on both sides.
int hoi4_write_f32(lua_State *Ls) {
    uint64_t a = check_addr(Ls, 1);
    float v = (float)luaL_checknumber(Ls, 2);
    uint32_t bits;
    memcpy(&bits, &v, sizeof(bits));
    lua_pushboolean(Ls, 0);
    if (!memgate_write_ok(a, 4)) return wr_denied(Ls, "write_f32", a);
    __try {
        *(volatile uint32_t *)a = bits;
        uint32_t got = *(volatile uint32_t *)a;
        if (got != bits) {
            L("[mem] write_f32 read-back mismatch @%llx (want %08x got %08x)",
              (unsigned long long)a, bits, got);
            return wr_no_stick(Ls, "write_f32", a);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

int hoi4_write_f64(lua_State *Ls) {
    uint64_t a = check_addr(Ls, 1);
    double v = luaL_checknumber(Ls, 2);
    uint64_t bits;
    memcpy(&bits, &v, sizeof(bits));
    lua_pushboolean(Ls, 0);
    if (!memgate_write_ok(a, 8)) return wr_denied(Ls, "write_f64", a);
    __try {
        *(volatile uint64_t *)a = bits;
        uint64_t got = *(volatile uint64_t *)a;
        if (got != bits) {
            L("[mem] write_f64 read-back mismatch @%llx (want %016llx got %016llx)",
              (unsigned long long)a, (unsigned long long)bits,
              (unsigned long long)got);
            return wr_no_stick(Ls, "write_f64", a);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

// write text into an existing MSVC std::string at addr, capacity-bounded.
// short (<=15) text always fits (SSO); long text needs heap cap >= len.
// Gated on BOTH write targets: the std::string header (SSO buffer + len/cap,
// [s, s+0x20)) and the heap buffer on the long path ([p, p+tlen+1]).
int hoi4_write_str(lua_State *Ls) {
    const char *text = luaL_checkstring(Ls, 2);
    size_t tlen = strlen(text);
    uint64_t s = check_addr(Ls, 1);
    lua_pushboolean(Ls, 0);
    if (tlen > 255) return 1;                    // artificial safety bound
    if (tlen <= 15) {
        if (!memgate_write_ok(s, 0x20)) return wr_denied(Ls, "write_str", s);
    } else {
        if (!memgate_write_ok(s, 0x18)) return wr_denied(Ls, "write_str", s);
    }
    __try {
        uint64_t len = *(volatile uint64_t *)(s + 0x10);
        uint64_t cap = *(volatile uint64_t *)(s + 0x18);
        if (tlen <= 15) {
            // heap->SSO transition would strand the old heap allocation
            // (we must not free engine blocks we can't attribute): refuse
            if (len > 15) return 1;
            // SSO path: clear inline buffer, copy, fix len/cap
            memset((void *)s, 0, 16);
            memcpy((void *)s, text, tlen);
            *(volatile uint64_t *)(s + 0x10) = tlen;
            *(volatile uint64_t *)(s + 0x18) = 15;
            // read-back: the inline bytes, the length AND the capacity field
            if (*(volatile uint64_t *)(s + 0x10) != tlen ||
                *(volatile uint64_t *)(s + 0x18) != 15 ||
                memcmp((const void *)s, text, tlen) != 0) {
                L("[mem] write_str read-back mismatch @%llx (SSO, len=%zu)",
                  (unsigned long long)s, tlen);
                return wr_no_stick(Ls, "write_str", s);
            }
        } else {
            // heap path: keep the existing allocation if it fits
            if (cap < tlen || len <= 15) return 1;   // would need (re)alloc — refuse
            char *p = (char *)(*(volatile char **)(s + 0));
            if (!memgate_write_ok((uint64_t)(uintptr_t)p, tlen + 1))
                return wr_denied(Ls, "write_str", (uint64_t)(uintptr_t)p);
            memcpy(p, text, tlen);
            p[tlen] = 0;
            *(volatile uint64_t *)(s + 0x10) = tlen;
            // read-back: the heap bytes, the NUL terminator AND the length
            if (*(volatile uint64_t *)(s + 0x10) != tlen ||
                memcmp((const void *)p, text, tlen) != 0 ||
                *(volatile char *)(p + tlen) != 0) {
                L("[mem] write_str read-back mismatch @%llx (heap, len=%zu)",
                  (unsigned long long)s, tlen);
                return wr_no_stick(Ls, "write_str", s);
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 1; }
    lua_pop(Ls, 1); lua_pushboolean(Ls, 1);
    return 1;
}

// hot-reload dependency registration (defined after hoi4_lib)
int hoi4_watch(lua_State *Ls);
// console command invocation (see console.cpp)
int hoi4_console(lua_State *Ls);

