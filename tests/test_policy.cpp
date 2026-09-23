// test_policy.cpp — table-driven unit tests for the mod-Lua path sandbox
// (hoi4_pol.h). Every rule here decides whether an untrusted mod may touch a
// path, so a regression is a sandbox escape, not a cosmetic bug. The
// handle-based canonicalisation step stays in hoi4_lua_policy.cpp (it needs the
// real filesystem); what is testable without a game process is the pure string
// logic, which is where the rules actually live.
//
// The tests are written as pairs: what must be ALLOWED, and the near-miss that
// must be DENIED. A one-sided test would pass just as happily against a policy
// that denies everything.
//
// Build & run (no framework, plain asserts):
//   cl /nologo /O2 /W4 tests\test_policy.cpp /Fe:test_policy.exe && test_policy.exe
#include <cstdio>
#include <cstring>
#include <cwchar>
#include "../src/hoi4_pol.h"

static int g_fail = 0, g_run = 0;

static void check(const char *name, int got, int want) {
    g_run++;
    if (got != want) {
        g_fail++;
        printf("FAIL %-52s got %d, want %d\n", name, got, want);
    }
}

// ---- pol_under: root-prefix containment ------------------------------------
static void under(const char *name, const wchar_t *full, const wchar_t *root,
                  int want) {
    check(name, pol_under(full, root), want);
}

static void test_under(void) {
    // exact and nested hits
    under("exact root",        L"D:\\mods\\lua",      L"D:\\mods\\lua",      1);
    under("child of root",     L"D:\\mods\\lua\\a.lua",L"D:\\mods\\lua",     1);

    // the boundary bug this function exists for: lua_evil is NOT under lua
    under("sibling prefix lua_evil", L"D:\\mods\\lua_evil", L"D:\\mods\\lua", 0);
    under("sibling prefix lua2",     L"D:\\mods\\lua2\\a",  L"D:\\mods\\lua", 0);

    // case-insensitive (Windows paths)
    under("case-insensitive root", L"D:\\Mods\\Lua\\a", L"d:\\mods\\lua", 1);

    // separator-insensitive: the loader hands roots over as "D:/x/lua" while a
    // mod's own dofile(dir .. "/resource.lua") mixes styles onto the same path.
    // Getting this wrong denies a mod its OWN files (it broke on first run).
    under("fwd root, back full",   L"D:\\mods\\lua\\a.lua", L"D:/mods/lua",  1);
    under("back root, fwd full",   L"D:/mods/lua/a.lua",    L"D:\\mods\\lua", 1);
    under("mixed inside full",     L"D:/mods/lua\\a.lua",   L"D:/mods/lua",  1);

    // a shorter full than root must not read past the terminator
    under("full shorter than root", L"D:\\mods", L"D:\\mods\\lua", 0);
    under("empty full",             L"",         L"D:\\mods",      0);

    // an empty root would match everything — must be refused outright
    under("empty root", L"D:\\anything", L"", 0);
}

// ---- pol_leaf_reject: the filename rule ------------------------------------
static void leaf(const char *name, const wchar_t *l, int wantReject) {
    g_run++;
    const char *why = pol_leaf_reject(l);
    int got = (why != NULL);
    if (got != wantReject) {
        g_fail++;
        printf("FAIL %-52s got %s, want %s\n", name,
               why ? why : "accept", wantReject ? "reject" : "accept");
    }
}

static void test_leaf(void) {
    // plain names are fine
    leaf("plain",              L"resource.lua", 0);
    leaf("dots inside",        L"a.b.c.txt",    0);
    leaf("mixed case",         L"Objects_V2.lua", 0);
    leaf("hyphen/underscore",  L"sv2_sec_c-intel.lua", 0);

    // length boundary: exactly 255 is accepted, 256 is not. Built rather than
    // typed so the count cannot drift.
    {
        static wchar_t ok[256], too[257];
        for (int i = 0; i < 255; i++) ok[i] = L'a';
        ok[255] = 0;
        for (int i = 0; i < 256; i++) too[i] = L'a';
        too[256] = 0;
        leaf("255 chars", ok,  0);
        leaf("256 chars", too, 1);
    }

    // empty
    leaf("empty",              L"", 1);

    // Windows silently strips trailing dots/spaces, so these ALIAS a real file
    leaf("trailing dot",       L"f.txt.", 1);
    leaf("trailing space",     L"f.txt ", 1);

    // NTFS alternate data streams ("f.txt:evil") hide a payload in the stream
    leaf("ADS",                L"f.txt:evil", 1);
    leaf("bare colon",         L":",          1);

    // reserved device names: opening CON/NUL talks to a device, not a file
    leaf("CON",                L"CON",   1);
    leaf("nul lower",          L"nul",   1);
    leaf("COM1",               L"COM1",  1);
    leaf("LPT1",               L"LPT1",  1);
    leaf("CON.txt",            L"CON.txt", 1);
    leaf("NUL:stream",         L"NUL:evil", 1);   // ADS check fires first
    // ...but a name merely STARTING with a device name is an ordinary file
    leaf("CONSOLE (not CON)",  L"CONSOLE.txt", 0);
    leaf("COM10 (not COM1)",   L"COM10",       0);
    leaf("NULLIFY (not NUL)",  L"NULLIFY.txt", 0);
}

// ---- pol_last_sep: split at the LAST separator of either kind --------------
static void sep(const char *name, const wchar_t *in, int want) {
    check(name, pol_last_sep(in), want);
}

static void test_last_sep(void) {
    // The mixed-path case is the regression: a backslash-only scan finds the
    // one inside "lua_verify\lua" and splits there, yielding the directory
    // "D:/x/mods/lua_verify" — which is not a root, so the mod is denied its own
    // file. The last separator of EITHER kind is the only correct split.
    {
        //               0123456789...
        const wchar_t *p = L"D:/x/mods/lua_verify\\lua/resource.lua";
        sep("mixed path: last sep is the '/'", p, 24);
        int i = pol_last_sep(p);
        g_run++;
        if (i < 0 || p[i] != L'/') {          // the '/' before the leaf, not the '\'
            g_fail++;
            printf("FAIL %-52s wrong separator chosen\n", "mixed path split");
        }
        g_run++;
        if (i < 0 || wcscmp(p + i + 1, L"resource.lua") != 0) {
            g_fail++;
            printf("FAIL %-52s leaf != resource.lua\n", "mixed path leaf");
        }
    }
    sep("plain backslash", L"D:\\a\\b.lua", 4);   // D : \ a \ b . l u a
    sep("plain forward",   L"D:/a/b.lua",   4);
    sep("no separator",    L"b.lua",       -1);
    sep("empty",           L"",            -1);
}

// ---- pol_op_from_mode_str: mode string -> operation class ------------------
static void mode(const char *name, const char *m, int want) {
    check(name, (int)pol_op_from_mode_str(m), want);
}

static void test_mode(void) {
    // only "r*" reads; everything else can write or truncate, so it must be
    // classified as WRITE — misclassifying a "w" as a read would let a mod
    // overwrite an allowed file under the read audit class
    mode("r",   "r",   POL_OP_READ);
    mode("rb",  "rb",  POL_OP_READ);
    mode("r+",  "r+",  POL_OP_READ);    // r+ reads first (matches lua's own rule)
    mode("w",   "w",   POL_OP_WRITE);
    mode("wb",  "wb",  POL_OP_WRITE);
    mode("a",   "a",   POL_OP_WRITE);
    mode("a+",  "a+",  POL_OP_WRITE);
    mode("r+b", "r+b", POL_OP_READ);
    mode("w+",  "w+",  POL_OP_WRITE);
    // absent / empty mode defaults to read (lua's io.open default is "r")
    mode("empty", "",   POL_OP_READ);
    mode("NULL",  NULL, POL_OP_READ);
    // a mode that merely CONTAINS an r is not a read mode
    mode("aw",  "aw",  POL_OP_WRITE);
}

// ---- pol_strip_prefix / pol_trim_sep: canonical-path normalisation ---------
// These run on the OUTPUT of GetFinalPathNameByHandleW, which always yields the
// \\?\ form; if the prefix survives, the stored root never matches a plain
// "D:\..." and every path is denied (fail-closed, but a total outage).
static void test_normalise(void) {
    {
        wchar_t b[64]; wcscpy_s(b, L"\\\\?\\D:\\mods\\lua");
        pol_strip_prefix(b);
        check("strip \\\\?\\ prefix", wcscmp(b, L"D:\\mods\\lua") == 0, 1);
    }
    {
        // \\?\UNC\srv\share -> \\srv\share
        wchar_t b[64]; wcscpy_s(b, L"\\\\?\\UNC\\srv\\share");
        pol_strip_prefix(b);
        check("strip UNC prefix", wcscmp(b, L"\\\\srv\\share") == 0, 1);
    }
    {
        wchar_t b[64]; wcscpy_s(b, L"D:\\mods\\lua\\");
        pol_trim_sep(b);
        check("trim trailing backslash", wcscmp(b, L"D:\\mods\\lua") == 0, 1);
    }
    {
        wchar_t b[64]; wcscpy_s(b, L"D:\\mods\\lua/");
        pol_trim_sep(b);
        check("trim trailing forward slash", wcscmp(b, L"D:\\mods\\lua") == 0, 1);
    }
    {
        // the n > 3 guard: a drive root must keep its separator, or "D:\"
        // degrades to "D:" which resolves to the drive's CWD, not its root
        wchar_t b[64]; wcscpy_s(b, L"D:\\");
        pol_trim_sep(b);
        check("drive root keeps separator", wcscmp(b, L"D:\\") == 0, 1);
    }
    {
        wchar_t b[64]; wcscpy_s(b, L"D:\\\\\\");
        pol_trim_sep(b);
        check("drive root, repeated seps", wcscmp(b, L"D:\\") == 0, 1);
    }
}

int main(void) {
    test_under();
    test_leaf();
    test_last_sep();
    test_mode();
    test_normalise();

    if (g_fail) { printf("TESTS FAILED: %d of %d\n", g_fail, g_run); return 1; }
    printf("TESTS OK (%d checks)\n", g_run);
    return 0;
}
