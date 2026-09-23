// hoi4_launcher.cpp — deterministic early injection:
// CreateProcess(CREATE_SUSPENDED) -> QueueUserAPC(LoadLibraryW) -> ResumeThread.
// The DLL is loaded and hooks installed BEFORE any game/mod file parsing runs,
// independent of machine speed. This replaces the timing-based 8s sleep hack.
//
// Usage: hoi4_launcher.exe [--launcher-flags] [game args...]
//   Game args are passed through to hoi4.exe verbatim (single-dash style):
//     hoi4_launcher.exe -start_save=test1 -http=17389
//     hoi4_launcher.exe -debug -http=17389              (debug console)
//   Launcher flags are double-dash, consumed here, never reach the game:
//     --exe=<path>   override the hoi4.exe location (else Steam auto-detect)
//     --probe        resolve + print all paths, exit without launching
//
// Path resolution (no hardcoded machine paths except a last-resort default):
//   DLL : same directory as this launcher (hoi4_bridge.dll)
//   EXE : --exe= -> Steam library auto-detect (appid 394360:
//         HKCU\Software\Valve\Steam\SteamPath + steamapps/libraryfolders.vdf
//         + appmanifest installdir); no match = hard error.
//         DIR (cwd of the game process) is derived from EXE.
//   LOG : same 3-level chain as the DLL (hoi4_paths.cpp):
//         <game>/launcher-settings.json gameDataPath -> <game>/userdir.txt ->
//         SHGetKnownFolderPath(Documents)/Paradox Interactive/Hearts of Iron IV
//         then logs\hoi4_bridge.log under it.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlobj.h>
#include <stdio.h>
#include <string.h>
#include <wchar.h>

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "advapi32.lib")

#define PATH_BUF 32768
#define HOI4_STEAM_APPID L"394360"

// ------------------------------------------------------------ small helpers
static int file_exists_w(const wchar_t *p) {
    DWORD a = GetFileAttributesW(p);
    return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
}

static int wcopy(wchar_t *dst, size_t cap, const wchar_t *src) {
    if (!dst || !src || cap == 0) return 0;
    size_t n = wcslen(src);
    if (n >= cap) return 0;
    memcpy(dst, src, (n + 1) * sizeof(wchar_t));
    return 1;
}

static int wjoin(wchar_t *dst, size_t cap, const wchar_t *a, const wchar_t *b) {
    if (!dst || !a || !b || cap == 0) return 0;
    // alias-safe: dst may be the same buffer as a (append-in-place idiom)
    wchar_t tmp[PATH_BUF];
    size_t na = wcslen(a);
    while (na > 0 && (a[na - 1] == L'\\' || a[na - 1] == L'/')) na--;
    while (*b == L'\\' || *b == L'/') b++;
    int n = _snwprintf_s(tmp, PATH_BUF, _TRUNCATE, L"%.*s\\%s", (int)na, a, b);
    if (n < 0) return 0;
    return wcopy(dst, cap, tmp);
}

// strip the last path component in place (...\hoi4.exe -> ...)
static void dir_of(wchar_t *path) {
    wchar_t *s1 = wcsrchr(path, L'\\');
    wchar_t *s2 = wcsrchr(path, L'/');
    wchar_t *s = (s2 && (!s1 || s2 > s1)) ? s2 : s1;
    if (s) *s = 0;
}

static void wtrim(wchar_t *s) {
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
    if (!n) n = MultiByteToWideChar(CP_ACP, 0, src, -1, dst, (int)cap);
    return n > 0;
}

// ------------------------------------------------------------ DLL: next to this launcher
static int resolve_dll(wchar_t *out, size_t cap) {
    DWORD n = GetModuleFileNameW(NULL, out, (DWORD)cap);
    if (!n || n >= cap) return 0;
    dir_of(out);
    if (!wjoin(out, cap, out, L"hoi4_bridge.dll")) return 0;
    return file_exists_w(out);
}

// ------------------------------------------------------------ Steam auto-detect
// Steam root from HKCU\Software\Valve\Steam\SteamPath.
static int steam_root(wchar_t *out, size_t cap) {
    HKEY hk;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\Valve\\Steam", 0,
                      KEY_READ, &hk) != ERROR_SUCCESS)
        return 0;
    wchar_t buf[1024];
    DWORD type = 0, len = sizeof(buf);
    LONG rc = RegQueryValueExW(hk, L"SteamPath", NULL, &type,
                               (LPBYTE)buf, &len);
    RegCloseKey(hk);
    if (rc != ERROR_SUCCESS || (type != REG_SZ && type != REG_EXPAND_SZ))
        return 0;
    int ok = wcopy(out, cap, buf);
    if (ok) wtrim(out);
    return ok && out[0];
}

// extract the value of the next "key" occurrence in a Valve KeyValues text
// file: "key"  "value". Values may contain escaped backslashes (\\).
static int vdf_value(const char *text, const char *key, wchar_t *out, size_t cap) {
    if (!text || !key || !out || cap == 0) return 0;
    char needle[64];
    int nn = _snprintf_s(needle, sizeof(needle), _TRUNCATE, "\"%s\"", key);
    if (nn < 0) return 0;
    const char *p = strstr(text, needle);
    if (!p) return 0;
    p += nn;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;
    if (*p != '"') return 0;
    p++;
    char raw[1024];
    size_t n = 0;
    while (*p && *p != '"' && n + 1 < sizeof(raw)) {
        if (*p == '\\' && p[1] == '\\') { raw[n++] = '\\'; p += 2; }
        else raw[n++] = *p++;
    }
    raw[n] = 0;
    if (*p != '"') return 0;
    return utf8_to_wide(raw, out, cap);
}

// does library <lib> contain HOI4? Prefer the appmanifest's installdir
// (exact), fall back to the well-known folder name.
static int steam_lib_find_hoi4(const wchar_t *lib, wchar_t *outExe, size_t cap) {
    wchar_t manifest[PATH_BUF];
    wchar_t installdir[512] = L"";
    if (wjoin(manifest, PATH_BUF, lib,
              L"steamapps\\appmanifest_" HOI4_STEAM_APPID L".acf")) {
        char *buf = NULL; DWORD len = 0;
        if (read_file_bytes_w(manifest, &buf, &len)) {
            vdf_value(buf, "installdir", installdir, 512);
            HeapFree(GetProcessHeap(), 0, buf);
        }
    }
    const wchar_t *cands[2] = { installdir, L"Hearts of Iron IV" };
    for (int i = 0; i < 2; i++) {
        if (!cands[i][0]) continue;
        wchar_t dir[PATH_BUF], exe[PATH_BUF];
        if (!wjoin(dir, PATH_BUF, lib, L"steamapps\\common")) continue;
        if (!wjoin(dir, PATH_BUF, dir, cands[i])) continue;
        if (!wjoin(exe, PATH_BUF, dir, L"hoi4.exe")) continue;
        if (file_exists_w(exe)) return wcopy(outExe, cap, exe);
    }
    return 0;
}

// scan the Steam root + every extra library in libraryfolders.vdf
static int steam_find_hoi4(wchar_t *outExe, size_t cap,
                           wchar_t *srcLib, size_t libCap) {
    wchar_t root[1024];
    if (!steam_root(root, 1024)) return 0;
    // candidate libraries: root itself first, then vdf entries
    if (steam_lib_find_hoi4(root, outExe, cap)) {
        if (srcLib) wcopy(srcLib, libCap, root);
        return 1;
    }
    wchar_t vdfPath[PATH_BUF];
    if (!wjoin(vdfPath, PATH_BUF, root,
               L"steamapps\\libraryfolders.vdf")) return 0;
    char *buf = NULL; DWORD len = 0;
    if (!read_file_bytes_w(vdfPath, &buf, &len)) return 0;
    // every "path" entry names one library folder
    const char *p = buf;
    int found = 0;
    while ((p = strstr(p, "\"path\"")) != NULL) {
        wchar_t lib[PATH_BUF];
        if (vdf_value(p, "path", lib, PATH_BUF)) {
            if (steam_lib_find_hoi4(lib, outExe, cap)) {
                if (srcLib) wcopy(srcLib, libCap, lib);
                found = 1;
                break;
            }
        }
        p += 6;
    }
    HeapFree(GetProcessHeap(), 0, buf);
    return found;
}

// ------------------------------------------------------------ EXE resolution
// 1) --exe=  2) Steam auto-detect (no default fallback: hard error instead)
static int resolve_exe(wchar_t *outExe, size_t cap, const wchar_t **outSrc,
                       const wchar_t *cliExe) {
    if (cliExe && cliExe[0]) {
        if (!file_exists_w(cliExe)) {
            wprintf(L"[error] --exe path not found: %s\n", cliExe);
            return 0;
        }
        *outSrc = L"--exe";
        return wcopy(outExe, cap, cliExe);
    }
    wchar_t lib[PATH_BUF] = L"";
    if (steam_find_hoi4(outExe, cap, lib, PATH_BUF)) {
        static wchar_t src[PATH_BUF + 32];
        _snwprintf_s(src, PATH_BUF + 32, _TRUNCATE, L"steam library %s", lib);
        *outSrc = src;
        return 1;
    }
    return 0;
}

// ------------------------------------------------------------ LOG path (port of hoi4_paths.cpp)
static int get_documents_dir(wchar_t *dst, size_t cap) {
    PWSTR p = NULL;
    // C++ build: FOLDERID_Documents binds by reference — no & (see hoi4_paths.cpp)
    HRESULT hr = SHGetKnownFolderPath(FOLDERID_Documents, KF_FLAG_DEFAULT,
                                      NULL, &p);
    if (FAILED(hr) || !p) return 0;
    int ok = wcopy(dst, cap, p);
    CoTaskMemFree(p);
    return ok;
}

// expand a gameDataPath/userdir value into an absolute path.
// Mirrors resolve_game_data_path() in hoi4_paths.cpp.
static void expand_userdir(wchar_t *wvalue, const wchar_t *gameDir,
                           const wchar_t *docs) {
    wtrim(wvalue);
    const wchar_t token[] = L"%USER_DOCUMENTS%";
    wchar_t *at = wcsstr(wvalue, token);
    if (at && docs && docs[0]) {
        wchar_t expanded[PATH_BUF];
        size_t prefix = (size_t)(at - wvalue);
        at += wcslen(token);
        _snwprintf_s(expanded, PATH_BUF, _TRUNCATE, L"%.*s%s%s",
                     (int)prefix, wvalue, docs, at);
        wcopy(wvalue, PATH_BUF, expanded);
    } else {
        wchar_t expanded[PATH_BUF];
        DWORD en = ExpandEnvironmentStringsW(wvalue, expanded, PATH_BUF);
        if (en > 0 && en < PATH_BUF) wcopy(wvalue, PATH_BUF, expanded);
    }
    wtrim(wvalue);
    if ((wvalue[0] == L'\\' || wvalue[0] == L'/') &&
        wvalue[1] != L'\\' && wvalue[1] != L'/') {
        // root-relative: resolve against the game drive
        wchar_t root[4] = { gameDir[0], L':', L'\\', 0 };
        wchar_t combined[PATH_BUF];
        _snwprintf_s(combined, PATH_BUF, _TRUNCATE, L"%s%s", root, wvalue);
        wcopy(wvalue, PATH_BUF, combined);
    } else if (!(wvalue[0] && wvalue[1] == L':') &&
               !(wvalue[0] == L'\\' && wvalue[1] == L'\\')) {
        wchar_t combined[PATH_BUF];
        wjoin(combined, PATH_BUF, gameDir, wvalue);
        wcopy(wvalue, PATH_BUF, combined);
    }
}

// Resolve the HOI4 user data directory. Returns the source name via outSrc
// for diagnostics. gameDir = directory of hoi4.exe.
static int resolve_userdir(wchar_t *out, size_t cap, const wchar_t *gameDir,
                           const wchar_t **outSrc) {
    wchar_t docs[PATH_BUF];
    if (!get_documents_dir(docs, PATH_BUF)) docs[0] = 0;
    wchar_t userDir[PATH_BUF] = L"";

    // 1) launcher-settings.json gameDataPath
    wchar_t cfgPath[PATH_BUF];
    char *json = NULL; DWORD jsonLen = 0;
    if (wjoin(cfgPath, PATH_BUF, gameDir, L"launcher-settings.json") &&
        read_file_bytes_w(cfgPath, &json, &jsonLen)) {
        wchar_t wvalue[PATH_BUF];
        if (vdf_value(json, "gameDataPath", wvalue, PATH_BUF)) {
            expand_userdir(wvalue, gameDir, docs);
            if (wvalue[0]) {
                wcopy(userDir, PATH_BUF, wvalue);
                *outSrc = L"launcher-settings.json";
            }
        }
        HeapFree(GetProcessHeap(), 0, json);
    }

    // 2) userdir.txt
    if (!userDir[0]) {
        wchar_t oldPath[PATH_BUF];
        char *old = NULL; DWORD oldLen = 0;
        if (wjoin(oldPath, PATH_BUF, gameDir, L"userdir.txt") &&
            read_file_bytes_w(oldPath, &old, &oldLen)) {
            wchar_t wold[PATH_BUF];
            if (utf8_to_wide(old, wold, PATH_BUF)) {
                expand_userdir(wold, gameDir, docs);
                if (wold[0]) {
                    wcopy(userDir, PATH_BUF, wold);
                    *outSrc = L"userdir.txt";
                }
            }
            HeapFree(GetProcessHeap(), 0, old);
        }
    }

    // 3) Documents default
    if (!userDir[0] && docs[0]) {
        wjoin(userDir, PATH_BUF, docs,
              L"Paradox Interactive\\Hearts of Iron IV");
        *outSrc = L"known-folder-documents";
    }
    if (!userDir[0]) return 0;
    return wcopy(out, cap, userDir);
}

static int resolve_log(wchar_t *outLog, size_t cap, const wchar_t *gameDir,
                       const wchar_t **outSrc) {
    wchar_t userDir[PATH_BUF];
    if (!resolve_userdir(userDir, PATH_BUF, gameDir, outSrc)) return 0;
    wchar_t logs[PATH_BUF];
    if (!wjoin(logs, PATH_BUF, userDir, L"logs")) return 0;
    return wjoin(outLog, cap, logs, L"hoi4_bridge.log");
}

// ------------------------------------------------------------ mod list sync
// -start_save mode: the save header lists the mods the save was played with
// (mods={ "A" "B" ... }). Resolve each name against <userDir>/mod/*.mod
// descriptors (name="..." line) and rewrite dlc_load.json, so every
// -start_save launch self-corrects the playable mod set — the launcher
// playset sync and hand edits can no longer desync it. A save without a
// mods block leaves dlc_load.json untouched; a block whose names resolve
// to nothing also leaves it untouched (never downgrade to vanilla).
static int read_file_head_w(const wchar_t *path, char *buf, DWORD cap,
                            DWORD *got) {
    HANDLE h = CreateFileW(path, GENERIC_READ,
                           FILE_SHARE_READ | FILE_SHARE_WRITE,
                           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return 0;
    DWORD n = 0;
    int ok = ReadFile(h, buf, cap - 1, &n, NULL);
    CloseHandle(h);
    if (!ok) return 0;
    buf[n] = 0;
    *got = n;
    return 1;
}

static int find_mod_by_name(const wchar_t *modDir, const char *nameA,
                            wchar_t *out, size_t cap) {
    wchar_t pattern[PATH_BUF];
    if (!wjoin(pattern, PATH_BUF, modDir, L"*.mod")) return 0;
    WIN32_FIND_DATAW fd;
    HANDLE h = FindFirstFileW(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) return 0;
    int found = 0;
    size_t nlen = strlen(nameA);
    while (!found) {
        if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
            wchar_t path[PATH_BUF];
            if (wjoin(path, PATH_BUF, modDir, fd.cFileName)) {
                char *buf = NULL; DWORD len = 0;
                if (read_file_bytes_w(path, &buf, &len)) {
                    const char *q = strstr(buf, "name=\"");
                    if (q) {
                        q += 6;
                        const char *e = strchr(q, '"');
                        if (e && (size_t)(e - q) == nlen &&
                            memcmp(q, nameA, nlen) == 0) {
                            // dlc_load.json needs forward slashes ("mod\x"
                            // would put an invalid \u escape in the JSON)
                            found = wjoin(out, cap, L"mod", fd.cFileName);
                            if (found)
                                for (wchar_t *s = out; *s; s++)
                                    if (*s == L'\\') *s = L'/';
                        }
                    }
                    HeapFree(GetProcessHeap(), 0, buf);
                }
            }
        }
        if (!FindNextFileW(h, &fd)) break;
    }
    FindClose(h);
    return found;
}

static void sync_dlc_load(const wchar_t *userDir, const wchar_t *saveName) {
    if (!saveName || !*saveName) return;
    wchar_t savesDir[PATH_BUF], savePath[PATH_BUF];
    if (!wjoin(savesDir, PATH_BUF, userDir, L"save games")) return;
    if (!wjoin(savePath, PATH_BUF, savesDir, saveName)) return;
    if (!file_exists_w(savePath) && !wcschr(saveName, L'.')) {
        wchar_t withExt[PATH_BUF];
        if (wjoin(withExt, PATH_BUF, savesDir, saveName)) {
            _snwprintf_s(withExt, PATH_BUF, _TRUNCATE, L"%s.hoi4", withExt);
            if (file_exists_w(withExt)) wcopy(savePath, PATH_BUF, withExt);
        }
    }
    if (!file_exists_w(savePath)) {
        wprintf(L"[mods] save not found, dlc_load untouched: %s\n", savePath);
        return;
    }
    static char head[65536];
    DWORD got = 0;
    if (!read_file_head_w(savePath, head, sizeof(head), &got)) return;
    const char *m = strstr(head, "mods={");
    if (!m) {
        printf("[mods] save has no mods block, dlc_load untouched\n");
        return;
    }
    m += 6;
    wchar_t modDir[PATH_BUF];
    if (!wjoin(modDir, PATH_BUF, userDir, L"mod")) return;
    static char json[16384];
    size_t jn = 0;
    int count = 0, listed = 0;
    jn += (size_t)_snprintf_s(json + jn, sizeof(json) - jn, _TRUNCATE,
                              "{\n\t\"enabled_mods\": [\n");
    while (*m && *m != '}' && jn < sizeof(json) - 1024) {
        if (*m == '"') {
            char nameA[512];
            size_t k = 0;
            m++;
            while (*m && *m != '"' && k + 1 < sizeof(nameA)) nameA[k++] = *m++;
            nameA[k] = 0;
            wchar_t modPath[PATH_BUF];
            if (k && find_mod_by_name(modDir, nameA, modPath, PATH_BUF)) {
                char p8[PATH_BUF];
                WideCharToMultiByte(CP_UTF8, 0, modPath, -1, p8,
                                    sizeof(p8), NULL, NULL);
                jn += (size_t)_snprintf_s(json + jn, sizeof(json) - jn,
                                          _TRUNCATE, "%s\t\t\"%s\"",
                                          count ? ",\n" : "", p8);
                count++;
            } else {
                wprintf(L"[mods] save mod not matched: %.*s\n",
                        (int)k, nameA);
            }
            listed++;
        }
        m++;
    }
    if (count == 0) {
        printf("[mods] no save mod resolved, dlc_load untouched\n");
        return;
    }
    jn += (size_t)_snprintf_s(json + jn, sizeof(json) - jn, _TRUNCATE,
                              "\n\t],\n\t\"disabled_dlcs\": []\n}\n");
    // dlc_load.json lives at the USER DIR ROOT (same path a1_modenv.py
    // maintains) — NOT under mod\.
    wchar_t outPath[PATH_BUF];
    if (!wcopy(outPath, PATH_BUF, userDir)) return;
    if (!wjoin(outPath, PATH_BUF, outPath, L"dlc_load.json")) return;
    HANDLE h = CreateFileW(outPath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        printf("[mods] dlc_load.json write failed\n");
        return;
    }
    DWORD w = 0;
    WriteFile(h, json, (DWORD)jn, &w, NULL);
    CloseHandle(h);
    wprintf(L"[mods] dlc_load.json <- %d mod(s) from save '%s' (%d listed)\n",
            count, saveName, listed);
}

// ------------------------------------------------------------ main
int wmain(int argc, wchar_t **argv) {
    // launcher flags are double-dash and CONSUMED here; everything else is
    // passed to the game verbatim (the game itself only uses single-dash).
    const wchar_t *cliExe = NULL;
    int probe = 0;
    const wchar_t *saveName = NULL;
    wchar_t extra[2048] = L"";
    for (int i = 1; i < argc; i++) {
        if (wcsncmp(argv[i], L"--exe=", 6) == 0) {
            cliExe = argv[i] + 6;
            continue;
        }
        if (wcscmp(argv[i], L"--probe") == 0) { probe = 1; continue; }
        if (wcsncmp(argv[i], L"-start_save=", 12) == 0)
            saveName = argv[i] + 12;
        if (wcslen(extra) + wcslen(argv[i]) + 2 >=
            sizeof(extra) / sizeof(wchar_t)) {
            printf("too many args\n");
            return 1;
        }
        wcscat(extra, L" ");
        wcscat(extra, argv[i]);
    }

    wchar_t dll[PATH_BUF], exe[PATH_BUF], logPath[PATH_BUF];
    const wchar_t *exeSrc = L"?", *logSrc = L"?";

    if (!resolve_dll(dll, PATH_BUF)) {
        printf("hoi4_bridge.dll not found next to the launcher\n");
        return 1;
    }
    if (!resolve_exe(exe, PATH_BUF, &exeSrc, cliExe)) {
        if (!cliExe)
            printf("hoi4.exe not found. Pass --exe=<path>, install via Steam, "
                   "or restore the default backup install.\n");
        return 1;
    }
    wchar_t gameDir[PATH_BUF];
    wcopy(gameDir, PATH_BUF, exe);
    dir_of(gameDir);
    if (!resolve_log(logPath, PATH_BUF, gameDir, &logSrc)) {
        printf("could not resolve the HOI4 user data directory\n");
        return 1;
    }

    wprintf(L"[dll] %s (launcher dir)\n", dll);
    wprintf(L"[exe] %s (%s)\n", exe, exeSrc);
    wprintf(L"[log] %s (%s)\n", logPath, logSrc);

    if (probe) {
        wprintf(L"[probe] --probe given, not launching\n");
        return 0;
    }

    wchar_t userDir[PATH_BUF];
    const wchar_t *udSrc = L"?";
    if (resolve_userdir(userDir, PATH_BUF, gameDir, &udSrc))
        sync_dlc_load(userDir, saveName);
    else
        printf("[mods] user dir unresolved, dlc_load untouched\n");

    wchar_t cmdline[PATH_BUF];
    _snwprintf_s(cmdline, PATH_BUF, _TRUNCATE, L"\"%s\"%s", exe, extra);
    wprintf(L"game args:%s\n", extra);

    STARTUPINFOW si; ZeroMemory(&si, sizeof(si)); si.cb = sizeof(si);
    PROCESS_INFORMATION pi; ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcessW(exe, cmdline, NULL, NULL, FALSE,
                        CREATE_SUSPENDED, NULL, gameDir, &si, &pi)) {
        printf("CreateProcess failed: %lu\n", GetLastError());
        return 1;
    }
    printf("pid=%lu suspended\n", pi.dwProcessId);

    // Unified failure cleanup: any failure after CreateProcess kills the
    // suspended game (never leaves a zombie), frees the remote allocation and
    // closes both handles. Failures BEFORE the remote alloc pass remote=NULL.
    void *remote = NULL;
    SIZE_T n = (wcslen(dll) + 1) * sizeof(wchar_t);
    remote = VirtualAllocEx(pi.hProcess, NULL, n,
                            MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!remote) { printf("VirtualAllocEx failed: %lu\n", GetLastError()); goto fail; }

    {
        SIZE_T w = 0;
        if (!WriteProcessMemory(pi.hProcess, remote, dll, n, &w) || w != n) {
            printf("WriteProcessMemory failed: %lu\n", GetLastError());
            goto fail;
        }

        HMODULE k32 = GetModuleHandleA("kernel32.dll");
        PAPCFUNC ll = k32 ? (PAPCFUNC)(uintptr_t)GetProcAddress(k32, "LoadLibraryW")
                          : NULL;
        if (!ll) { printf("LoadLibraryW address not found\n"); goto fail; }
        if (!QueueUserAPC(ll, pi.hThread, (ULONG_PTR)(uintptr_t)remote)) {
            printf("QueueUserAPC failed: %lu\n", GetLastError());
            goto fail;
        }
        printf("APC queued (LoadLibraryW @ %p)\n", (void *)ll);
    }

    DeleteFileW(logPath);   // stale log from previous run
    if (ResumeThread(pi.hThread) == (DWORD)-1) {
        printf("ResumeThread failed: %lu\n", GetLastError());
        goto fail;
    }
    printf("resumed; DLL will load before game entry point\n");

    // wait up to 60s for the DLL log to appear (game boots meanwhile)
    for (int i = 0; i < 60; i++) {
        Sleep(1000);
        DWORD attr = GetFileAttributesW(logPath);
        if (attr != INVALID_FILE_ATTRIBUTES) {
            printf("=== DLL LOG (after ~%ds) ===\n", i + 1);
            FILE *f = _wfopen(logPath, L"rb");
            if (f) { char buf[2048]; size_t r;
                while ((r = fread(buf, 1, sizeof(buf), f)) > 0) fwrite(buf, 1, r, stdout);
                fclose(f); }
            CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
            return 0;
        }
    }
    printf("no DLL log after 60s (injection may have failed)\n");
    CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
    return 1;

fail:
    // never leave a suspended zombie game or leak handles/remote memory
    if (remote) VirtualFreeEx(pi.hProcess, remote, 0, MEM_RELEASE);
    TerminateProcess(pi.hProcess, 1);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 1;
}
