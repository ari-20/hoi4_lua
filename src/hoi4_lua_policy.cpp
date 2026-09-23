// hoi4_lua_policy.cpp - path-scoped file access for mod Lua.
//
// Threat: mod Lua is untrusted (README "Safety"), yet luaL_openlibs hands it
// io.open / dofile / loadfile / os.remove / os.rename with no path restriction.
// Any enabled mod can read %USERPROFILE%\.ssh\id_rsa, or write into another
// mod's lua/ directory before that mod registers its own root.
//
// Policy: a path is permitted only if (a) its DIRECTORY resolves, through a real
// handle, to a canonical path under a registered root, and (b) its leaf is a
// plain filename. Canonicalising on a handle is what defeats `..`, directory
// junctions and symlinks; the leaf rule blocks NTFS alternate data streams
// ("f.txt:evil"), device names (CON/NUL) and the trailing dot/space forms that
// Windows silently strips.
//
// The originals of the wrapped functions live in C statics, NOT in upvalues: a
// mod holding the debug library must not be able to recover the unwrapped
// io.open via debug.getupvalue.

#include "hoi4_common.h"
#include "hoi4_pol.h"       // pure path predicates (unit-tested)

#include <wchar.h>
#include <io.h>
#include <fcntl.h>

#define POL_BUF        32768
#define POL_MAX_ROOTS  64
#define POL_MAX_CHUNK  (16 * 1024 * 1024)   // dofile'd sources are small; the
                                            // 120MB dumps go through io.open

// ---- declared in hoi4_common.h in the real patch (hoi4_paths.cpp) ----
extern "C" const wchar_t *save_dir_w(void);

static wchar_t g_roots[POL_MAX_ROOTS][POL_BUF];
static int     g_rootCount;
static SRWLOCK g_polLock = SRWLOCK_INIT;

static lua_CFunction g_origIoOpen, g_origIoLines, g_origIoInput, g_origIoOutput;
static lua_CFunction g_origOsRemove, g_origOsRename;

// The pure predicates (separator folding, root-prefix test, leaf rule, mode ->
// op) live in hoi4_pol.h so tests/test_policy.cpp can exercise them without a
// lua_State or a filesystem. pol_op / pol_strip_prefix / pol_trim_sep /
// pol_fold / pol_under / pol_leaf_reject / pol_last_sep come from there.

static int pol_dofile(lua_State *Ls);
static int pol_loadfile(lua_State *Ls);
static int pol_io_open(lua_State *Ls);
static int pol_io_lines(lua_State *Ls);
static int pol_io_input(lua_State *Ls);
static int pol_io_output(lua_State *Ls);
static int pol_os_remove(lua_State *Ls);
static int pol_os_rename(lua_State *Ls);

// ------------------------------------------------------------------ helpers

static int pol_utf8_to_wide(const char *src, wchar_t *dst, size_t cap) {
    if (!src || !dst || cap == 0) return 0;
    int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, src, -1, dst,
                                (int)cap);
    if (!n) n = MultiByteToWideChar(CP_ACP, 0, src, -1, dst, (int)cap);
    return n > 0;
}

static int pol_wide_to_utf8(const wchar_t *src, char *dst, size_t cap) {
    if (!src || !dst || cap == 0) return 0;
    return WideCharToMultiByte(CP_UTF8, 0, src, -1, dst, (int)cap, NULL, NULL) > 0;
}

// Canonical path of an EXISTING directory: resolves `..`, 8.3 names, junctions
// and symlinks. Fails closed when the directory cannot be opened.
static int pol_real_dir(const wchar_t *dir, wchar_t *out, size_t cap) {
    HANDLE h = CreateFileW(dir, FILE_READ_ATTRIBUTES,
                           FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                           NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (h == INVALID_HANDLE_VALUE) return 0;
    DWORD n = GetFinalPathNameByHandleW(h, out, (DWORD)cap, FILE_NAME_NORMALIZED);
    CloseHandle(h);
    if (!n || n >= cap) return 0;
    pol_strip_prefix(out);
    pol_trim_sep(out);
    return 1;
}

// Canonical path for a TRUSTED root that may not exist yet (a fresh install has
// no "save games" directory). Never applied to mod-supplied paths.
static int pol_canon_root(const wchar_t *in, wchar_t *out, size_t cap) {
    if (pol_real_dir(in, out, cap)) return 1;
    DWORD n = GetFullPathNameW(in, (DWORD)cap, out, NULL);
    if (!n || n >= cap) return 0;
    pol_strip_prefix(out);
    pol_trim_sep(out);
    // Roots are stored with one separator style. The loader passes
    // "D:/a/b\lua" (forward-slash base, backslash from the path join), and
    // leaving that mixed would make the stored root differ textually from the
    // same directory as reported by GetFinalPathNameByHandle.
    for (wchar_t *q = out; *q; q++) if (*q == L'/') *q = (wchar_t)0x5C;
    return 1;
}

static int pol_dir_allowed(const wchar_t *dir) {
    int hit = 0;
    AcquireSRWLockShared(&g_polLock);
    for (int i = 0; i < g_rootCount; i++) {
        if (pol_under(dir, g_roots[i])) { hit = 1; break; }
    }
    ReleaseSRWLockShared(&g_polLock);
    return hit;
}

void lua_policy_add_root(const char *utf8_dir) {
    if (!utf8_dir || !*utf8_dir) return;
    wchar_t in[POL_BUF], canon[POL_BUF];
    if (!pol_utf8_to_wide(utf8_dir, in, POL_BUF)) return;
    if (!pol_canon_root(in, canon, POL_BUF)) return;
    AcquireSRWLockExclusive(&g_polLock);
    for (int i = 0; i < g_rootCount; i++) {
        if (_wcsicmp(g_roots[i], canon) == 0) {
            ReleaseSRWLockExclusive(&g_polLock);
            return;
        }
    }
    if (g_rootCount < POL_MAX_ROOTS) {
        wcsncpy_s(g_roots[g_rootCount], POL_BUF, canon, _TRUNCATE);
        g_rootCount++;
        L("[policy] root +%s", utf8_dir);
    } else {
        L("[policy] root table full, IGNORING %s", utf8_dir);
    }
    ReleaseSRWLockExclusive(&g_polLock);
}

// The save dir is resolved after this module initialises, so it is registered
// on demand rather than at install time.
void lua_policy_register_save_dir(void) {
    const wchar_t *sd = save_dir_w();
    if (!sd || !*sd) return;
    char utf8[POL_BUF];
    if (pol_wide_to_utf8(sd, utf8, sizeof(utf8))) lua_policy_add_root(utf8);
}

// ------------------------------------------------------- the path decision

// Every denial leaves through here, so the audit log records it. Denials are
// never deduplicated (see hoi4_audit.cpp): a flood of them is itself the signal.
static int pol_deny(lua_State *Ls, const char *path, pol_op op, const char *why) {
    static const char *kOp[] = { "read", "write", "exec", "meta" };
    audit_fs(Ls, kOp[op], path, 1, why);
    return 0;
}

// On success fills `out` with the canonical absolute path and returns 1.
static int pol_check(lua_State *Ls, const char *utf8_path, pol_op op,
                     wchar_t *out, size_t cap) {
    if (!utf8_path || !*utf8_path)
        return pol_deny(Ls, utf8_path ? utf8_path : "", op, "empty path");
    wchar_t in[POL_BUF];
    if (!pol_utf8_to_wide(utf8_path, in, POL_BUF))
        return pol_deny(Ls, utf8_path, op, "not utf8");

    // UNC (\\srv\share) and the device namespace (\\.\C:, \\?\C:) first: UNC
    // also leaks NTLM credentials when the connect fails.
    if (in[0] == L'\\' && in[1] == L'\\')
        return pol_deny(Ls, utf8_path, op, "UNC/device path");

    // Split at the LAST separator of either kind (rule + rationale in
    // hoi4_pol.h: a '\\'-first scan mis-splits mixed paths and denies a mod
    // its own files).
    int sepIdx = pol_last_sep(in);
    if (sepIdx < 0)
        return pol_deny(Ls, utf8_path, op, "no directory component");
    const wchar_t *sep = in + sepIdx;

    size_t nd = (size_t)(sep - in);
    if (nd == 0 || nd >= POL_BUF)
        return pol_deny(Ls, utf8_path, op, "bad directory");
    wchar_t dir[POL_BUF];
    memcpy(dir, in, nd * sizeof(wchar_t));
    dir[nd] = 0;
    const wchar_t *leaf = sep + 1;

    // Leaf: a plain filename and nothing else (rule lives in hoi4_pol.h).
    const char *leafWhy = pol_leaf_reject(leaf);
    if (leafWhy) return pol_deny(Ls, utf8_path, op, leafWhy);

    // Canonicalise the DIRECTORY through a handle, then re-attach the leaf.
    // This is the step that turns "../../../Windows" into a path that fails the
    // root test, and that sees through a junction planted inside a root.
    wchar_t real[POL_BUF];
    if (!pol_real_dir(dir, real, POL_BUF))
        return pol_deny(Ls, utf8_path, op, "directory does not resolve");
    if (!pol_dir_allowed(real))
        return pol_deny(Ls, utf8_path, op, "outside allowed roots");

    if (_snwprintf_s(out, cap, _TRUNCATE, L"%s\\%s", real, leaf) < 0)
        return pol_deny(Ls, utf8_path, op, "path too long");

    // A reparse point planted INSIDE an allowed root would redirect the write
    // back outside it, so refuse existing symlinks even when the directory is
    // legitimate.
    DWORD at = GetFileAttributesW(out);
    if (at != INVALID_FILE_ATTRIBUTES && (at & FILE_ATTRIBUTE_REPARSE_POINT))
        return pol_deny(Ls, utf8_path, op, "symlink/reparse target");

    // Allowed: one line per distinct (op, path), repeats counted not logged.
    static const char *kOp[] = { "read", "write", "exec", "meta" };
    audit_fs(Ls, kOp[op], utf8_path, 0, NULL);
    return 1;
}

// ------------------------------------------------------------- dofile/loadfile

// Reads the already-validated file and pushes the compiled chunk; returns a
// Lua status. Reading the bytes here rather than delegating to the original
// dofile means the validated path is the one actually read - there is no
// check-then-open window.
static int pol_load_chunk(lua_State *Ls, const char *luaPath, const wchar_t *full) {
    HANDLE h = CreateFileW(full, GENERIC_READ,
                           FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        lua_pushfstring(Ls, "cannot open %s", luaPath);
        return LUA_ERRFILE;
    }
    LARGE_INTEGER sz;
    if (!GetFileSizeEx(h, &sz) || sz.QuadPart < 0 ||
        sz.QuadPart > (LONGLONG)POL_MAX_CHUNK) {
        CloseHandle(h);
        lua_pushfstring(Ls, "%s: file too large", luaPath);
        return LUA_ERRFILE;
    }
    DWORD len = (DWORD)sz.QuadPart, got = 0;
    char *buf = (char *)HeapAlloc(GetProcessHeap(), 0, len ? len : 1);
    if (!buf) {
        CloseHandle(h);
        lua_pushstring(Ls, "out of memory");
        return LUA_ERRMEM;
    }
    BOOL ok = ReadFile(h, buf, len, &got, NULL);
    CloseHandle(h);
    if (!ok || got != len) {
        HeapFree(GetProcessHeap(), 0, buf);
        lua_pushfstring(Ls, "cannot read %s", luaPath);
        return LUA_ERRFILE;
    }
    // The chunkname keeps the "@" file convention: debug.getinfo(1,"S").source
    // must stay "@<path>" because the shipped mods derive SELF_DIR from it.
    char chunk[POL_BUF];
    _snprintf_s(chunk, sizeof(chunk), _TRUNCATE, "@%s", luaPath);
    int st = luaL_loadbufferx(Ls, buf, len, chunk, "bt");
    HeapFree(GetProcessHeap(), 0, buf);
    return st;
}

static int pol_dofile(lua_State *Ls) {
    const char *p = luaL_checkstring(Ls, 1);
    wchar_t full[POL_BUF];
    if (!pol_check(Ls, p, POL_OP_EXEC, full, POL_BUF))
        return luaL_error(Ls, "dofile: path not permitted: %s", p);
    audit_code_load(Ls, p, NULL);
    int st = pol_load_chunk(Ls, p, full);
    if (st != LUA_OK) return lua_error(Ls);
    lua_remove(Ls, 1);
    lua_call(Ls, 0, LUA_MULTRET);
    return lua_gettop(Ls);
}

static int pol_loadfile(lua_State *Ls) {
    const char *p = luaL_checkstring(Ls, 1);
    wchar_t full[POL_BUF];
    if (!pol_check(Ls, p, POL_OP_EXEC, full, POL_BUF)) {
        lua_pushnil(Ls);
        lua_pushfstring(Ls, "cannot open %s: path not permitted", p);
        return 2;
    }
    audit_code_load(Ls, p, NULL);
    int st = pol_load_chunk(Ls, p, full);
    if (st != LUA_OK) {          // loadfile contract: nil, message
        lua_pushnil(Ls);
        lua_insert(Ls, -2);
        return 2;
    }
    return 1;
}

// -------------------------------------------------------- delegate wrappers

// Validate argument 1, then call the saved original with the canonical path.
static int pol_delegate(lua_State *Ls, lua_CFunction orig, const char *what,
                        pol_op op) {
    const char *p = luaL_checkstring(Ls, 1);
    wchar_t full[POL_BUF];
    char canon[POL_BUF];
    if (!pol_check(Ls, p, op, full, POL_BUF) ||
        !pol_wide_to_utf8(full, canon, sizeof(canon))) {
        lua_pushnil(Ls);
        lua_pushfstring(Ls, "%s: path not permitted: %s", what, p);
        return 2;
    }
    int n = lua_gettop(Ls);
    lua_pushcfunction(Ls, orig);
    lua_insert(Ls, 1);            // fn, arg1..argn
    lua_pushstring(Ls, canon);
    lua_replace(Ls, 2);           // swap the original path for the canonical one
    lua_call(Ls, n, LUA_MULTRET);
    return lua_gettop(Ls);
}

// io.open/lines/input/output take a mode, so the op is decided from argument 2
// rather than assumed. Only "r*" reads; anything else writes or truncates. The
// decision itself is in hoi4_pol.h (pol_op_from_mode_str); this wrapper only
// unpacks the lua argument.
static pol_op pol_op_from_mode(lua_State *Ls) {
    if (lua_gettop(Ls) < 2 || lua_isnoneornil(Ls, 2)) return POL_OP_READ;
    return pol_op_from_mode_str(lua_tostring(Ls, 2));
}

static int pol_io_open(lua_State *Ls)   { return pol_delegate(Ls, g_origIoOpen,   "io.open",   pol_op_from_mode(Ls)); }
static int pol_io_lines(lua_State *Ls)  { return pol_delegate(Ls, g_origIoLines,  "io.lines",  POL_OP_READ); }
static int pol_io_input(lua_State *Ls)  { return pol_delegate(Ls, g_origIoInput,  "io.input",  POL_OP_READ); }
static int pol_io_output(lua_State *Ls) { return pol_delegate(Ls, g_origIoOutput, "io.output", POL_OP_WRITE); }
static int pol_os_remove(lua_State *Ls) { return pol_delegate(Ls, g_origOsRemove, "os.remove", POL_OP_META); }
static int pol_os_rename(lua_State *Ls) { return pol_delegate(Ls, g_origOsRename, "os.rename", POL_OP_META); }

// -------------------------------------------------------------------- install

static void pol_capture(lua_State *Ls, const char *tbl, const char *name,
                        lua_CFunction wrapper, lua_CFunction *slot) {
    if (*slot && *slot != wrapper) return;   // keep the first real original
    lua_getglobal(Ls, tbl);
    if (!lua_istable(Ls, -1)) { lua_pop(Ls, 1); return; }
    lua_getfield(Ls, -1, name);
    if (lua_iscfunction(Ls, -1)) {
        lua_CFunction cur = lua_tocfunction(Ls, -1);
        if (cur != wrapper) *slot = cur;
    }
    lua_pop(Ls, 2);
}

static void pol_replace(lua_State *Ls, const char *tbl, const char *name,
                        lua_CFunction fn) {
    lua_getglobal(Ls, tbl);
    if (!lua_istable(Ls, -1)) { lua_pop(Ls, 1); return; }
    lua_pushcfunction(Ls, fn);
    lua_setfield(Ls, -2, name);
    lua_pop(Ls, 1);
}

// Idempotent, and safe to call on the async worker states as well as the main
// VM. Must run BEFORE any mod script, so a mod cannot capture an unwrapped
// reference at load time.
void lua_policy_install(lua_State *Ls) {
    if (!Ls) return;

    pol_capture(Ls, "io", "open",   pol_io_open,   &g_origIoOpen);
    pol_capture(Ls, "io", "lines",  pol_io_lines,  &g_origIoLines);
    pol_capture(Ls, "io", "input",  pol_io_input,  &g_origIoInput);
    pol_capture(Ls, "io", "output", pol_io_output, &g_origIoOutput);
    pol_capture(Ls, "os", "remove", pol_os_remove, &g_origOsRemove);
    pol_capture(Ls, "os", "rename", pol_os_rename, &g_origOsRename);

    if (g_origIoOpen)   pol_replace(Ls, "io", "open",   pol_io_open);
    if (g_origIoLines)  pol_replace(Ls, "io", "lines",  pol_io_lines);
    if (g_origIoInput)  pol_replace(Ls, "io", "input",  pol_io_input);
    if (g_origIoOutput) pol_replace(Ls, "io", "output", pol_io_output);
    if (g_origOsRemove) pol_replace(Ls, "os", "remove", pol_os_remove);
    if (g_origOsRename) pol_replace(Ls, "os", "rename", pol_os_rename);

    lua_getglobal(Ls, "dofile");
    lua_CFunction cur = lua_iscfunction(Ls, -1) ? lua_tocfunction(Ls, -1) : NULL;
    lua_pop(Ls, 1);
    if (cur && cur != pol_dofile) {
        lua_pushcfunction(Ls, pol_dofile);
        lua_setglobal(Ls, "dofile");
    }

    lua_getglobal(Ls, "loadfile");
    cur = lua_iscfunction(Ls, -1) ? lua_tocfunction(Ls, -1) : NULL;
    lua_pop(Ls, 1);
    if (cur && cur != pol_loadfile) {
        lua_pushcfunction(Ls, pol_loadfile);
        lua_setglobal(Ls, "loadfile");
    }

    // require reaches the filesystem through package.searchers, and the mod
    // loader in this tree never uses it.
    lua_pushnil(Ls);
    lua_setglobal(Ls, "require");

    L("[policy] file access restricted to %d root(s)", g_rootCount);
}
