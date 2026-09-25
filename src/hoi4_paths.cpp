#include "hoi4_common.h"

#include <shlobj.h>
#include <wchar.h>

// ---- runtime paths / mod list / mod lua autoload ----
// ---------------------------------------------------------------- runtime paths
// HOI4 user data is not necessarily under C:\\Users\\<name>\\Documents: Windows
// Documents may be redirected, and the launcher can override the location with
// gameDataPath in launcher-settings.json (or the legacy userdir.txt). Resolve
// this after the hooks are installed, on the worker thread, never in DllMain.
#define PATH_BUF 32768
static wchar_t g_gameDir[PATH_BUF];
static wchar_t g_userDataDir[PATH_BUF];
static wchar_t g_logsDir[PATH_BUF];
static wchar_t g_saveDir[PATH_BUF];
static volatile LONG g_pathsReady;

int wpath_copy(wchar_t *dst, size_t cap, const wchar_t *src) {
    if (!dst || !src || cap == 0) return 0;
    size_t n = wcslen(src);
    if (n >= cap) return 0;
    memcpy(dst, src, (n + 1) * sizeof(wchar_t));
    return 1;
}

static int wpath_join(wchar_t *dst, size_t cap, const wchar_t *a,
                      const wchar_t *b) {
    if (!dst || !a || !b || cap == 0) return 0;
    size_t na = wcslen(a);
    while (na > 0 && (a[na - 1] == L'\\' || a[na - 1] == L'/')) na--;
    while (*b == L'\\' || *b == L'/') b++;
    int n = _snwprintf_s(dst, cap, _TRUNCATE, L"%.*s\\%s", (int)na, a, b);
    return n >= 0;
}

static void wpath_trim(wchar_t *s) {
    if (!s) return;
    size_t n = wcslen(s);
    while (n > 0 && (s[n - 1] == L' ' || s[n - 1] == L'\t' ||
                     s[n - 1] == L'\r' || s[n - 1] == L'\n'))
        s[--n] = 0;
    size_t start = 0;
    while (s[start] == L' ' || s[start] == L'\t' ||
           s[start] == L'\r' || s[start] == L'\n') start++;
    if (start) memmove(s, s + start, (wcslen(s + start) + 1) * sizeof(wchar_t));
    n = wcslen(s);
    if (n >= 2 && s[0] == L'"' && s[n - 1] == L'"') {
        memmove(s, s + 1, (n - 2) * sizeof(wchar_t));
        s[n - 2] = 0;
    }
    for (size_t i = 0; s[i]; i++)
        if (s[i] == L'/') s[i] = L'\\';
}

int get_game_dir(void) {
    wchar_t exe[PATH_BUF];
    DWORD n = GetModuleFileNameW(NULL, exe, PATH_BUF);
    if (!n || n >= PATH_BUF) return 0;
    exe[n] = 0;
    wchar_t *slash = wcsrchr(exe, L'\\');
    wchar_t *slash2 = wcsrchr(exe, L'/');
    if (slash2 && (!slash || slash2 > slash)) slash = slash2;
    if (!slash) return 0;
    *slash = 0;
    return wpath_copy(g_gameDir, PATH_BUF, exe);
}

// UTF-8 view of g_gameDir for C modules that need a narrow path
// (cached; empty string until get_game_dir() has run).
static int wide_to_utf8(const wchar_t *src, char *dst, size_t cap); // fwd
const char *game_dir_utf8(void) {
    static char cache[512];
    static int  resolved = 0;
    if (!resolved) {
        cache[0] = 0;
        if (g_gameDir[0]) wide_to_utf8(g_gameDir, cache, sizeof(cache));
        resolved = 1;
    }
    return cache;
}

static int read_file_bytes_w(const wchar_t *path, char **out, DWORD *outLen) {
    *out = NULL; *outLen = 0;
    HANDLE h = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return 0;
    LARGE_INTEGER size;
    int ok = GetFileSizeEx(h, &size) && size.QuadPart >= 0 && size.QuadPart <= 4 * 1024 * 1024;
    if (!ok) { CloseHandle(h); return 0; }
    DWORD len = (DWORD)size.QuadPart;
    char *buf = (char *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, (size_t)len + 1);
    if (!buf) { CloseHandle(h); return 0; }
    DWORD got = 0;
    ok = ReadFile(h, buf, len, &got, NULL) && got == len;
    CloseHandle(h);
    if (!ok) { HeapFree(GetProcessHeap(), 0, buf); return 0; }
    buf[len] = 0;
    *out = buf; *outLen = len;
    return 1;
}

static int utf8_to_wide(const char *src, wchar_t *dst, size_t cap) {
    if (!src || !dst || cap == 0) return 0;
    int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, src, -1,
                                dst, (int)cap);
    if (!n) {
        // launcher-settings.json is UTF-8 in the normal case. Fall back to
        // the active Windows code page for old/custom files.
        n = MultiByteToWideChar(CP_ACP, 0, src, -1, dst, (int)cap);
    }
    return n > 0;
}

static int wide_to_utf8(const wchar_t *src, char *dst, size_t cap) {
    if (!src || !dst || cap == 0) return 0;
    int n = WideCharToMultiByte(CP_UTF8, 0, src, -1, dst, (int)cap,
                               NULL, NULL);
    return n > 0;
}

static int get_documents_dir(wchar_t *dst, size_t cap) {
    PWSTR p = NULL;
    // C++ build: FOLDERID_Documents binds by reference — no & (the C form
    // took its address; under C++ the parameter is const KNOWNFOLDERID&).
    HRESULT hr = SHGetKnownFolderPath(FOLDERID_Documents, KF_FLAG_DEFAULT,
                                      NULL, &p);
    if (FAILED(hr) || !p) return 0;
    int ok = wpath_copy(dst, cap, p);
    CoTaskMemFree(p);
    return ok;
}

// Decode the small JSON string used by launcher-settings.json. This is not a
// general JSON parser; it only extracts one named string and handles the JSON
// escapes relevant to filesystem paths.
static int json_string_value(const char *json, const char *key,
                             char *out, size_t cap) {
    if (!json || !key || !out || cap == 0) return 0;
    char needle[128];
    int nn = _snprintf_s(needle, sizeof(needle), _TRUNCATE, "\"%s\"", key);
    if (nn < 0) return 0;
    const char *p = strstr(json, needle);
    if (!p) return 0;
    p += nn;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;
    if (*p != ':') return 0;
    p++;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;
    if (*p != '"') return 0;
    p++;
    size_t n = 0;
    while (*p && *p != '"') {
        unsigned char ch = (unsigned char)*p++;
        if (ch == '\\') {
            ch = (unsigned char)*p++;
            if (!ch) return 0;
            switch (ch) {
            case '"': case '\\': case '/': break;
            case 'b': ch = '\b'; break;
            case 'f': ch = '\f'; break;
            case 'n': ch = '\n'; break;
            case 'r': ch = '\r'; break;
            case 't': ch = '\t'; break;
            case 'u':
                // Preserve \u escapes for the UTF-8/code-page conversion
                // fallback; normal HOI4 paths do not use them.
                if (n + 6 >= cap) return 0;
                out[n++] = '\\'; out[n++] = 'u';
                for (int i = 0; i < 4; i++) {
                    if (!p[i]) return 0;
                    out[n++] = p[i];
                }
                p += 4;
                continue;
            default: break;
            }
        }
        if (n + 1 >= cap) return 0;
        out[n++] = (char)ch;
    }
    if (*p != '"' || n >= cap) return 0;
    out[n] = 0;
    return 1;
}

int resolve_game_data_path(void) {
    wchar_t docs[PATH_BUF];
    if (!get_documents_dir(docs, PATH_BUF)) docs[0] = 0;

    // 1) Current launcher configuration overrides the legacy file.
    wchar_t cfgPath[PATH_BUF];
    char *json = NULL; DWORD jsonLen = 0;
    char value[PATH_BUF];
    if (wpath_join(cfgPath, PATH_BUF, g_gameDir, L"launcher-settings.json") &&
        read_file_bytes_w(cfgPath, &json, &jsonLen) &&
        json_string_value(json, "gameDataPath", value, sizeof(value))) {
        wchar_t wvalue[PATH_BUF];
        if (utf8_to_wide(value, wvalue, PATH_BUF)) {
            wpath_trim(wvalue);
            const wchar_t token[] = L"%USER_DOCUMENTS%";
            wchar_t *at = wcsstr(wvalue, token);
            if (at && docs[0]) {
                wchar_t expanded[PATH_BUF];
                size_t prefix = (size_t)(at - wvalue);
                at += wcslen(token);
                _snwprintf_s(expanded, PATH_BUF, _TRUNCATE, L"%.*s%s%s",
                             (int)prefix, wvalue, docs, at);
                wpath_copy(wvalue, PATH_BUF, expanded);
            } else {
                wchar_t expanded[PATH_BUF];
                DWORD en = ExpandEnvironmentStringsW(wvalue, expanded, PATH_BUF);
                if (en > 0 && en < PATH_BUF) wpath_copy(wvalue, PATH_BUF, expanded);
            }
            wpath_trim(wvalue);
            if ((wvalue[0] == L'\\' || wvalue[0] == L'/') &&
                wvalue[1] != L'\\' && wvalue[1] != L'/') {
                // Root-relative paths are resolved against the game drive.
                wchar_t root[4] = { g_gameDir[0], L':', L'\\', 0 };
                wchar_t combined[PATH_BUF];
                _snwprintf_s(combined, PATH_BUF, _TRUNCATE, L"%s%s", root, wvalue);
                wpath_copy(wvalue, PATH_BUF, combined);
            } else if (!(wvalue[0] && wvalue[1] == L':') &&
                       !(wvalue[0] == L'\\' && wvalue[1] == L'\\')) {
                wchar_t combined[PATH_BUF];
                wpath_join(combined, PATH_BUF, g_gameDir, wvalue);
                wpath_copy(wvalue, PATH_BUF, combined);
            }
            wpath_copy(g_userDataDir, PATH_BUF, wvalue);
            L("[paths] source=launcher-settings.json gameDataPath=%s", value);
        }
    }
    if (json) HeapFree(GetProcessHeap(), 0, json);

    // 2) Legacy userdir.txt is only used if launcher-settings did not provide
    // a usable path. The file lives beside hoi4.exe and contains one path.
    if (!g_userDataDir[0]) {
        wchar_t oldPath[PATH_BUF];
        char *old = NULL; DWORD oldLen = 0;
        if (wpath_join(oldPath, PATH_BUF, g_gameDir, L"userdir.txt") &&
            read_file_bytes_w(oldPath, &old, &oldLen)) {
            wchar_t wold[PATH_BUF];
            if (utf8_to_wide(old, wold, PATH_BUF)) {
                wpath_trim(wold);
                if (wold[0] && !(wold[0] && wold[1] == L':') &&
                    !(wold[0] == L'\\' && wold[1] == L'\\')) {
                    wchar_t combined[PATH_BUF];
                    wpath_join(combined, PATH_BUF, g_gameDir, wold);
                    wpath_copy(wold, PATH_BUF, combined);
                }
                wpath_copy(g_userDataDir, PATH_BUF, wold);
                L("[paths] source=userdir.txt");
            }
            HeapFree(GetProcessHeap(), 0, old);
        }
    }

    // 3) Standard launcher default.
    if (!g_userDataDir[0] && docs[0]) {
        wpath_join(g_userDataDir, PATH_BUF, docs,
                   L"Paradox Interactive\\Hearts of Iron IV");
        L("[paths] source=known-folder-documents");
    }
    if (!g_userDataDir[0]) return 0;
    wpath_join(g_logsDir, PATH_BUF, g_userDataDir, L"logs");
    wpath_join(g_saveDir, PATH_BUF, g_userDataDir, L"save games");

    // Adopt the user logs dir for the bridge log (2026-08-27): open
    // <user>/logs/hoi4_bridge.log and flush the DllMain-era ring buffer.
    log_open_in_logs_dir();

    {
        char game[PATH_BUF], user[PATH_BUF], logs[PATH_BUF], saves[PATH_BUF];
        if (wide_to_utf8(g_gameDir, game, sizeof(game)) &&
            wide_to_utf8(g_userDataDir, user, sizeof(user)) &&
            wide_to_utf8(g_logsDir, logs, sizeof(logs)) &&
            wide_to_utf8(g_saveDir, saves, sizeof(saves)))
            L("[paths] game=%s user_data=%s logs=%s saves=%s",
              game, user, logs, saves);
    }
    InterlockedExchange(&g_pathsReady, 1);
    return 1;
}

static int push_path(lua_State *Ls, const wchar_t *path) {
    char utf8[PATH_BUF];
    if (!path || !*path || !wide_to_utf8(path, utf8, sizeof(utf8))) {
        lua_pushnil(Ls);
        return 1;
    }
    lua_pushstring(Ls, utf8);
    return 1;
}

int hoi4_game_dir(lua_State *Ls) { return push_path(Ls, g_gameDir); }
int hoi4_user_data_dir(lua_State *Ls) { return push_path(Ls, g_userDataDir); }
int hoi4_logs_dir(lua_State *Ls) { return push_path(Ls, g_logsDir); }
int hoi4_save_dir(lua_State *Ls) { return push_path(Ls, g_saveDir); }

// Save-dir accessor for the path policy (hoi4_lua_policy.cpp): the policy module
// must not duplicate the four-level userdir resolution above, so the canonical
// save directory is exposed as plain wide text.
const wchar_t *save_dir_w(void) { return g_saveDir; }
// Logs dir for the audit sink (hoi4_audit.cpp). The audit directory is
// deliberately NOT registered as a policy root, so mod Lua cannot open the log.
const char *logs_dir_utf8(void) {
    static char cache[PATH_BUF];
    cache[0] = 0;
    if (g_logsDir[0]) wide_to_utf8(g_logsDir, cache, sizeof(cache));
    return cache;
}

// User dir root — files that must survive restarts anchor HERE: the engine
// wipes logs/ on every launch (the profile_folded default path used to live
// there and lost whole captures to a relaunch).
const char *user_data_dir_utf8(void) {
    static char cache[PATH_BUF];
    cache[0] = 0;
    if (g_userDataDir[0]) wide_to_utf8(g_userDataDir, cache, sizeof(cache));
    return cache;
}

// -+ mod list
// hoi4.mods_json() -> raw text of <user_data>/dlc_load.json (or nil).
// The file lists enabled/disabled mods as written by the Paradox launcher:
//   {"enabled_mods":["mod/lua_verify.mod"],"disabled_dlcs":[]}
int hoi4_mods_json(lua_State *Ls) {
    if (!g_userDataDir[0]) { lua_pushnil(Ls); return 1; }
    wchar_t p[PATH_BUF];
    if (!wpath_join(p, PATH_BUF, g_userDataDir, L"dlc_load.json")) {
        lua_pushnil(Ls); return 1;
    }
    // Self-scoped to the userdir, so pol_check never sees it - audit here.
    audit_fs(Ls, "read", "<userdir>/dlc_load.json", 0, NULL);
    char *buf = NULL; DWORD len = 0;
    if (!read_file_bytes_w(p, &buf, &len)) { lua_pushnil(Ls); return 1; }
    lua_pushlstring(Ls, buf, len);
    HeapFree(GetProcessHeap(), 0, buf);
    return 1;
}

// hoi4.read_mod_descriptor(relpath) -> raw text of the descriptor file.
// relpath is the entry as listed in dlc_load.json, which already carries the
// "mod/" prefix (e.g. "mod/lua_verify.mod" or "mod/ugc_123.mod"). Resolve against
// user_data when prefixed, otherwise prepend <user_data>/mod/ ourselves.
int hoi4_read_mod_descriptor(lua_State *Ls) {
    const char *rel = luaL_checkstring(Ls, 1);
    if (!rel || !*rel || !g_userDataDir[0]) { lua_pushnil(Ls); return 1; }
    wchar_t wrel[PATH_BUF];
    if (!utf8_to_wide(rel, wrel, PATH_BUF)) { lua_pushnil(Ls); return 1; }
    wchar_t p[PATH_BUF];
    int prefixed = (wrel[0] == L'm' && wrel[1] == L'o' && wrel[2] == L'd' &&
                    (wrel[3] == L'/' || wrel[3] == L'\\'));
    if (prefixed) {
        wpath_join(p, PATH_BUF, g_userDataDir, wrel);
    } else {
        wchar_t modDir[PATH_BUF];
        wpath_join(modDir, PATH_BUF, g_userDataDir, L"mod");
        wpath_join(p, PATH_BUF, modDir, wrel);
    }
    // Self-scoped to the userdir, so pol_check never sees it - audit here.
    audit_fs(Ls, "read", rel, 0, NULL);
    char *buf = NULL; DWORD len = 0;
    if (!read_file_bytes_w(p, &buf, &len)) { lua_pushnil(Ls); return 1; }
    lua_pushlstring(Ls, buf, len);
    HeapFree(GetProcessHeap(), 0, buf);
    return 1;
}

// -+ mod lua autoload
// After the main script loads, scan every enabled mod for a lua/ subdirectory
// and dofile all *.lua inside (sorted by mod order, then filename order).
// Mod discovery reuses the same chain as hoi4.mods_json()/read_mod_descriptor:
//   dlc_load.json -> enabled_mods[] -> descriptor path= -> <path>/lua/*.lua

// extract string values of a JSON array field: "key":[ "a", "b" ]
static int json_array_strings(const char *json, const char *key,
                              char out[][512], int maxOut) {
    if (!json || !key || !out || maxOut <= 0) return 0;
    char needle[128];
    int nn = _snprintf_s(needle, sizeof(needle), _TRUNCATE, "\"%s\"", key);
    if (nn < 0) return 0;
    const char *p = strstr(json, needle);
    if (!p) return 0;
    p += nn;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;
    if (*p != ':') return 0;
    p++;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;
    if (*p != '[') return 0;
    p++;
    int n = 0;
    while (*p && *p != ']' && n < maxOut) {
        while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n' || *p == ',') p++;
        if (*p == '"') {
            p++;
            size_t k = 0;
            while (*p && *p != '"' && k + 1 < 512) out[n][k++] = *p++;
            out[n][k] = 0;
            if (*p == '"') p++;
            n++;
        } else if (*p) p++;
    }
    return n;
}

// extract path="..." from a mod descriptor (Paradox script format)
static int desc_path_value(const char *text, char *out, size_t cap) {
    if (!text || !out || cap == 0) return 0;
    const char *p = strstr(text, "path=");
    if (!p) return 0;
    p += 5;
    while (*p == ' ' || *p == '\t') p++;
    if (*p != '"') return 0;
    p++;
    size_t n = 0;
    while (*p && *p != '"' && n + 1 < cap) out[n++] = *p++;
    if (*p != '"') return 0;
    out[n] = 0;
    return n > 0;
}

// dofile every *.lua under <modPath>/lua/ (returns count loaded).
// A3/F1: files are collected and SORTED by name before dofile — the old
// code relied on FindFirstFileA enumeration order (NTFS happens to be
// alphabetical, but nothing guarantees it). The mod-lua "00_" prefix
// convention is now a load-order CONTRACT, not a filesystem coincidence.
// Each file loaded is ALSO registered in the hot-reload watch list
// (watch_add_file): touching any mod lua triggers maybe_reload_locked,
// which re-runs the whole mod lua set. This is the only reload trigger
// since LUA_SCRIPT went away.
#define MAX_LUA_FILES 512
static char g_luaFiles[MAX_LUA_FILES][MAX_PATH];

static int cmp_lua_filenames(const void *a, const void *b) {
    return strcmp((const char *)a, (const char *)b);
}

static int dofile_mod_lua(lua_State *Ls, const char *modPathUtf8) {
    if (!Ls || !modPathUtf8 || !*modPathUtf8) return 0;
    // static: hot-reload path is deep-stacked (see load_mod_lua_scripts note)
    static char dir[PATH_BUF], pat[PATH_BUF];
    if (_snprintf_s(dir, sizeof(dir), _TRUNCATE, "%s\\lua", modPathUtf8) < 0) return 0;
    if (_snprintf_s(pat, sizeof(pat), _TRUNCATE, "%s\\*.lua", dir) < 0) return 0;
    // pass 1: collect names (sorted below, before any dofile)
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pat, &fd);
    if (h == INVALID_HANDLE_VALUE) return 0;   // no lua/ dir or empty
    int nFiles = 0;
    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        if (nFiles < MAX_LUA_FILES) {
            strncpy(g_luaFiles[nFiles], fd.cFileName, MAX_PATH - 1);
            g_luaFiles[nFiles][MAX_PATH - 1] = 0;
            nFiles++;
        } else {
            L("[lua] mod dir overflow: >%d lua files in %s, extra files SKIPPED",
              MAX_LUA_FILES, dir);
        }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    qsort(g_luaFiles, (size_t)nFiles, MAX_PATH, cmp_lua_filenames);
    // expose the dir to scripts: dofile(MOD_LUA_DIR.."\\layout.lua") etc.
    // (last mod wins; multi-mod setups get each dir in load order)
    lua_pushstring(Ls, dir);
    lua_setglobal(Ls, "MOD_LUA_DIR");
    // Path policy: a mod's whole directory becomes an allowed root, NOT just
    // its lua/ subdirectory. The mod root is the correct boundary - descriptor,
    // common/, events/, localisation/ and tools/ all live beside lua/, and
    // lua_verify legitimately reads and writes its own tools/tmp_*.txt
    // generation artifacts through "<mod>/lua/../tools/...". Registering only
    // lua/ made a mod's own sibling directory read as "outside", which is a
    // boundary drawn too tight rather than a real escape.
    //
    // What this still prevents (the boundary that matters): reaching ANOTHER
    // mod's directory, and any path outside the mod tree entirely.
    // modPathUtf8 is the mod root; `dir` above is its lua/ subdirectory.
    lua_policy_add_root(modPathUtf8);
    int n = 0;
    for (int i = 0; i < nFiles; i++) {
        static char full[PATH_BUF];
        if (_snprintf_s(full, sizeof(full), _TRUNCATE, "%s\\%s",
                        dir, g_luaFiles[i]) < 0) continue;
        // A2/F3: an overflowed watch slot means this file changes will
        // NEVER trigger a reload — that used to fail silently.
        if (!watch_add_file(full))
            L("[lua] watch list full, hot-reload NOT tracking %s", full);
        // Audit the load. The sv2/*.lua segments are NOT watched and are
        // re-dofile'd at runtime, so they are covered by the wrapper in
        // hoi4_lua_policy.cpp instead; this covers the flat lua/*.lua set.
        audit_code_load(Ls, full, NULL);
        if (luaL_dofile(Ls, full) != LUA_OK) {
            L("[lua] lua error in %s: %s", full, lua_tostring(Ls, -1));
            lua_pop(Ls, 1);
        } else {
            L("[lua] loaded %s", full);
            n++;
        }
    }
    return n;
}

// load lua/ scripts of every enabled mod; returns total count
// STACK NOTE (2026-08-27 fastfail forensics): this function is called both at
// init AND from maybe_reload_locked on the hot-reload path, which can nest
// inside a Lua effect -> console -> event -> effect chain (depth 2+). The
// original PATH_BUF (32768) stack arrays totaled ~450KB per invocation and
// blew the 1MB default stack (FAST_FAIL_STACK_COOKIE in strstr during the
// m4test.2 recursion). All big buffers below are STATIC — safe because every
// call site holds g_luaLock (single-threaded by construction).
int load_mod_lua_scripts(lua_State *Ls) {
    if (!Ls || !g_userDataDir[0]) return 0;
    static wchar_t p[PATH_BUF];
    if (!wpath_join(p, PATH_BUF, g_userDataDir, L"dlc_load.json")) return 0;
    char *json = NULL; DWORD len = 0;
    if (!read_file_bytes_w(p, &json, &len)) return 0;
    static char rels[64][512];
    int nRel = json_array_strings(json, "enabled_mods", rels, 64);
    HeapFree(GetProcessHeap(), 0, json);
    if (nRel <= 0) return 0;
    int total = 0;
    for (int i = 0; i < nRel; i++) {
        static wchar_t wrel[PATH_BUF];
        if (!utf8_to_wide(rels[i], wrel, PATH_BUF)) continue;
        static wchar_t descPath[PATH_BUF];
        wpath_join(descPath, PATH_BUF, g_userDataDir, wrel);
        char *desc = NULL; DWORD dlen = 0;
        if (!read_file_bytes_w(descPath, &desc, &dlen)) {
            L("[lua] mod %s: descriptor not found", rels[i]);
            continue;
        }
        static char modPath[PATH_BUF];
        int ok = desc_path_value(desc, modPath, sizeof(modPath));
        HeapFree(GetProcessHeap(), 0, desc);
        if (!ok) {
            L("[lua] mod %s: no path= field", rels[i]);
            continue;
        }
        int n = dofile_mod_lua(Ls, modPath);
        if (n > 0) L("[lua] mod %s: %d lua script(s)", rels[i], n);
        total += n;
    }
    return total;
}

// ------------------------------------------------------- log adoption
// Called from resolve_game_data_path() once g_logsDir is final. Opens
// <user>/logs/hoi4_bridge.log via log_ring_flush_and_adopt (hoi4_main.cpp),
// which first flushes every DllMain-era buffered entry in order.
void log_open_in_logs_dir(void) {
    if (!g_logsDir[0]) return;
    wchar_t wpath[PATH_BUF];
    if (!wpath_join(wpath, PATH_BUF, g_logsDir, L"hoi4_bridge.log")) return;
    HANDLE h = CreateFileW(wpath, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        L("[log] cannot open %ls\\hoi4_bridge.log (err %d), staying buffered",
          g_logsDir, GetLastError());
        return;
    }
    log_ring_flush_and_adopt(h);
    L("[log] log file live under user logs dir");
}

// hoi4.read_dir(pattern_utf8) -> table of matching file names (names only,
// UTF-8). In-process FindFirstFileW: unlike io.popen (spawns cmd.exe, which
// allocates a visible console in a GUI-subsystem process), this never flashes
// a window. Pattern is relative to the SAVE directory.
int hoi4_read_dir(lua_State *Ls) {
    const char *pat = luaL_checkstring(Ls, 1);
    lua_newtable(Ls);
    if (!pat || !*pat || !g_saveDir[0]) return 1;
    // This helper scopes itself to the save dir and so never reaches
    // pol_check; audit it directly. It is still an external-boundary read.
    {
        char shown[PATH_BUF];
        _snprintf_s(shown, sizeof(shown), _TRUNCATE, "<save games>/%s", pat);
        audit_fs(Ls, "meta", shown, 0, NULL);
    }
    wchar_t wpat[PATH_BUF];
    if (!utf8_to_wide(pat, wpat, PATH_BUF)) return 1;
    wchar_t full[PATH_BUF];
    if (!wpath_join(full, PATH_BUF, g_saveDir, wpat)) return 1;
    WIN32_FIND_DATAW fd;
    HANDLE h = FindFirstFileW(full, &fd);
    if (h == INVALID_HANDLE_VALUE) return 1;
    int n = 0;
    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        char name[512];
        if (wide_to_utf8(fd.cFileName, name, sizeof(name))) {
            lua_pushinteger(Ls, ++n);
            lua_pushstring(Ls, name);
            lua_settable(Ls, -3);
        }
    } while (FindNextFileW(h, &fd));
    FindClose(h);
    return 1;
}
