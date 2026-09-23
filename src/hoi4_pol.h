// hoi4_pol.h — pure path-policy predicates (no lua, no filesystem handles)
//
// Extracted from hoi4_lua_policy.cpp so the sandbox boundary is unit-testable
// (tests/test_policy.cpp). Every rule below decides whether mod Lua may touch a
// path, and a bug in any of them is a sandbox escape — that is the whole reason
// this file exists rather than living inline.
//
// What stays in the .cpp: the handle-based step that canonicalises a directory
// through CreateFileW (that needs the real filesystem, and canonicalising is
// what defeats `..` / junctions). Only the part that is a pure function of the
// input string is here.
//
// Keep this header lua-free and handle-free: the test links it with nothing.
#pragma once

#include <stddef.h>
#include <string.h>
#include <wchar.h>
#include <wctype.h>

// Operation class, carried into the audit log. Only the io/os wrappers know
// the mode (io.open's second argument), so the caller passes it down to
// pol_check - which is also the natural place to audit, because it is the one
// funnel every file entry point shares, denials included.
typedef enum { POL_OP_READ = 0, POL_OP_WRITE, POL_OP_EXEC, POL_OP_META } pol_op;

// GetFinalPathNameByHandleW returns \\?\D:\x (or \\?\UNC\srv\share)
static void pol_strip_prefix(wchar_t *p) {
    if (wcsncmp(p, L"\\\\?\\UNC\\", 8) == 0) {
        memmove(p + 2, p + 8, (wcslen(p + 8) + 1) * sizeof(wchar_t));
        p[0] = L'\\'; p[1] = L'\\';
    } else if (wcsncmp(p, L"\\\\?\\", 4) == 0) {
        memmove(p, p + 4, (wcslen(p + 4) + 1) * sizeof(wchar_t));
    }
}

// Trailing separators off, but never past the drive root: "D:\" and "D:\\"
// both stay "D:\" (the n > 3 guard is what keeps "D:\" from becoming "D:").
static void pol_trim_sep(wchar_t *p) {
    size_t n = wcslen(p);
    while (n > 3 && (p[n - 1] == L'\\' || p[n - 1] == L'/')) p[--n] = 0;
}

static wchar_t pol_fold(wchar_t c) { return c == L'/' ? L'\\' : c; }

// Separator-boundary prefix test: root "D:\m\lua" must not match "D:\m\lua_evil".
//
// Comparison is separator-INSENSITIVE. Callers reach this with both styles in
// play: the loader hands mod roots over as "D:/x/lua" while a mod's own
// dofile(dir .. "/resource.lua") mixes a forward-slash tail onto that same
// path. A literal _wcsnicmp then fails to match a root against itself and the
// mod's own files get denied - which is exactly how this broke on first
// in-game run. Normalising here is cheaper and safer than canonicalising every
// input, because it cannot be forgotten at a new call site.
static int pol_under(const wchar_t *full, const wchar_t *root) {
    size_t nr = wcslen(root);
    if (nr == 0) return 0;
    for (size_t i = 0; i < nr; i++) {
        wchar_t a = pol_fold(full[i]);
        if (a == 0) return 0;                    // full is shorter than root
        if (towlower(a) != towlower(pol_fold(root[i]))) return 0;
    }
    wchar_t c = full[nr];
    return c == 0 || c == L'\\' || c == L'/';
}

// Leaf rule: a plain filename and nothing else. Returns NULL when the leaf is
// acceptable, otherwise the ASCII denial reason (the caller passes it straight
// into the audit log, so the wording is user-visible).
//
// The order of the checks is load-bearing for the reason text, not the verdict:
// "NUL:evil" is reported as an ADS, "CON." as a trailing dot.
static const char *pol_leaf_reject(const wchar_t *leaf) {
    size_t nl = wcslen(leaf);
    if (nl == 0 || nl > 255) return "bad leaf length";
    // Windows silently strips these, so "f.txt." and "f.txt " alias "f.txt".
    if (leaf[nl - 1] == L'.' || leaf[nl - 1] == L' ') return "trailing dot/space";
    if (wcschr(leaf, L':')) return "alternate data stream";
    static const wchar_t *kDev[] = { L"CON", L"PRN", L"AUX", L"NUL",
                                     L"COM1", L"COM2", L"COM3", L"COM4",
                                     L"LPT1", L"LPT2", L"LPT3", NULL };
    for (int i = 0; kDev[i]; i++) {
        size_t dl = wcslen(kDev[i]);
        if (_wcsnicmp(leaf, kDev[i], dl) == 0 &&
            (leaf[dl] == 0 || leaf[dl] == L'.'))
            return "device name";
    }
    return NULL;
}

// Index of the LAST separator of either kind, or -1 when there is none.
//
// Scanning for '\\' first is wrong for mixed paths: for
// "D:/x/mods/lua_verify\lua/resource.lua" the backslash search finds the one
// inside "lua_verify\lua" and yields the directory "D:/x/mods/lua_verify",
// which is not a root - so a mod's own file gets denied. Take whichever
// separator occurs last.
static int pol_last_sep(const wchar_t *in) {
    int last = -1;
    for (int i = 0; in[i]; i++)
        if (in[i] == L'\\' || in[i] == L'/') last = i;
    return last;
}

// io.open/lines/input/output take a mode, so the op is decided from argument 2
// rather than assumed. Only "r"/"rb" read; anything else writes or truncates.
static pol_op pol_op_from_mode_str(const char *m) {
    if (!m || !*m) return POL_OP_READ;
    return (m[0] == 'r') ? POL_OP_READ : POL_OP_WRITE;
}
