#include "hoi4_common.h"

#include <winsock2.h>
#include <intrin.h>       // _ReturnAddress (HK caller-RVA forensics)
// -+ console command invocation core + crash forensics ----
// -+ console command
FindCmd_t g_origFind;

static int read_std_string(void *addr, char *out, size_t cap);

static void set_str(void *addr, const char *s) {
    memset(addr, 0, 0x20);
    size_t len = strlen(s);
    char *p = (char *)addr;
    if (len > 15) {
        p = (char *)HeapAlloc(GetProcessHeap(), 0, len + 1);
        memcpy(p, s, len + 1);
        *(char **)addr = p;
    } else {
        memcpy(p, s, len + 1);
    }
    *(uint64_t *)((char *)addr + 0x10) = len;
    *(uint64_t *)((char *)addr + 0x18) = len < 16 ? 15 : len;
}

// ---------------------------------------------------------------- E: `lua`
// Pseudo console command executing an arbitrary Lua chunk in the main VM,
// returning the result as the command output text. Runs on the main thread:
// every caller path already holds or cleanly acquires g_luaLock
// (lua_lock is recursion-aware):
//   1. Lua-side hoi4.console("lua ...")  -> already locked, depth++
//   2. IPC executor (frame-top poll)     -> already locked
//   3. native engine FindCommandByName   -> first acquisition here
// Chunk text = whitespace-split tokens rejoined with single spaces
// (console_invoke_core contract: quotes survive, runs of whitespace inside
// string literals collapse). Heavier code should go through IPC where the
// payload is raw. Blocking risk documented: an infinite loop in a chunk
// stalls the main thread, same class as hoi4.console("savegame") usage.
static void lua_result_to_text(lua_State *Ls, char *out, size_t cap) {
    size_t pos = 0;
    out[0] = 0;
    if (!cap) return;
    switch (lua_type(Ls, -1)) {
    case LUA_TNIL:
        return;
    case LUA_TBOOLEAN:
        _snprintf_s(out, cap, _TRUNCATE, "%s",
                    lua_toboolean(Ls, -1) ? "true" : "false");
        return;
    case LUA_TNUMBER:
        if (lua_isinteger(Ls, -1))
            _snprintf_s(out, cap, _TRUNCATE, "%lld",
                        (long long)lua_tointeger(Ls, -1));
        else
            _snprintf_s(out, cap, _TRUNCATE, "%.17g", lua_tonumber(Ls, -1));
        return;
    case LUA_TSTRING: {
        size_t l = 0;
        const char *s = lua_tolstring(Ls, -1, &l);
        if (l >= cap) l = cap - 1;
        memcpy(out, s, l);
        out[l] = 0;
        return;
    }
    case LUA_TTABLE: {
        // top-level summary, first 8 pairs, "k=v" — full structures belong
        // in export files, not console output.
        pos = (size_t)_snprintf_s(out, cap, _TRUNCATE, "{");
        if (pos >= cap) pos = cap - 1;
        lua_pushnil(Ls);
        int pairs = 0;
        // pairs check comes FIRST: with lua_next first, the 9th pair gets
        // pushed and then abandoned on the stack when the loop exits.
        while (pairs < 8 && lua_next(Ls, -2) != 0) {
            const char *ks = NULL;
            char kbuf[64];
            if (lua_type(Ls, -2) == LUA_TSTRING) {
                ks = lua_tostring(Ls, -2);
            } else if (lua_type(Ls, -2) == LUA_TNUMBER) {
                _snprintf_s(kbuf, sizeof(kbuf), _TRUNCATE, "[%lld]",
                            (long long)lua_tointeger(Ls, -2));
                ks = kbuf;
            }
            const char *vs = NULL;
            char vbuf[64];
            int vt = lua_type(Ls, -1);
            if (vt == LUA_TSTRING)  vs = lua_tostring(Ls, -1);
            else if (vt == LUA_TNUMBER) {
                if (lua_isinteger(Ls, -1))
                    _snprintf_s(vbuf, sizeof(vbuf), _TRUNCATE, "%lld",
                                (long long)lua_tointeger(Ls, -1));
                else
                    _snprintf_s(vbuf, sizeof(vbuf), _TRUNCATE, "%.10g",
                                lua_tonumber(Ls, -1));
                vs = vbuf;
            } else if (vt == LUA_TBOOLEAN) {
                vs = lua_toboolean(Ls, -1) ? "true" : "false";
            } else if (vt == LUA_TTABLE)    vs = "{...}";
            else if (vt == LUA_TFUNCTION)   vs = "fn";
            else if (vt == LUA_TNIL)        vs = "nil";
            else                            vs = "?";
            if (ks && vs) {
                int w = _snprintf_s(out + pos, cap - pos, _TRUNCATE,
                                    "%s%s=%s", pairs ? ", " : " ", ks, vs);
                if (w < 0 || (size_t)w >= cap - pos) { lua_pop(Ls, 1); break; }
                pos += (size_t)w;
                pairs++;
            }
            lua_pop(Ls, 1);                  // pop value, keep key
        }
        _snprintf_s(out + pos, cap - pos, _TRUNCATE, "%s", pairs >= 8 ? ", ...}" : " }");
        return;
    }
    default:
        _snprintf_s(out, cap, _TRUNCATE, "<%s>", lua_typename(Ls, lua_type(Ls, -1)));
        return;
    }
}

// shared by the `lua` pseudo command and (future) the HTTP /lua endpoint.
// Returns 1 on clean execution (out = serialized result), 0 on load/runtime
// error (out = "load: ..." / "runtime: ..."). Main thread only.
int lua_exec_chunk(const char *chunk, char *out, size_t cap) {
    if (cap) out[0] = 0;
    if (!g_L || !chunk || !*chunk) { _snprintf_s(out, cap, _TRUNCATE, "no state/empty chunk"); return 0; }
    lua_lock();
    int ok = 0;
    if (luaL_loadstring(g_L, chunk) == LUA_OK) {
        if (lua_pcall(g_L, 0, 1, 0) == LUA_OK) {
            lua_result_to_text(g_L, out, cap);
            lua_pop(g_L, 1);                 // the result value
            ok = 1;
        } else {
            _snprintf_s(out, cap, _TRUNCATE, "runtime: %s",
                        lua_tostring(g_L, -1) ? lua_tostring(g_L, -1) : "?");
            lua_pop(g_L, 1);
        }
    } else {
        _snprintf_s(out, cap, _TRUNCATE, "load: %s",
                    lua_tostring(g_L, -1) ? lua_tostring(g_L, -1) : "?");
        lua_pop(g_L, 1);
    }
    lua_unlock();
    return ok;
}

// pseudo-entry handler: rejoin tokens into the chunk, execute, publish.
static void CmdLuaHandler(void *ret, void *args, void *userdata) {
    (void)userdata;
    static char s_chunk[4096];               // main thread only (console path)
    static char s_out[1024];
    s_chunk[0] = 0;
    int nArgs = args ? *(int *)((uint8_t *)args + 0x0C) : 0;
    uint8_t *elems = args ? *(uint8_t **)args : NULL;
    size_t pos = 0;
    if (nArgs > 31) nArgs = 31;
    for (int i = 0; i < nArgs; i++) {
        char tok[128];
        if (!read_std_string(elems + (size_t)i * 0x20, tok, sizeof(tok))) continue;
        int w = _snprintf_s(s_chunk + pos, sizeof(s_chunk) - pos, _TRUNCATE,
                            "%s%s", pos ? " " : "", tok);
        if (w < 0) break;
        pos += (size_t)w;
        if (pos >= sizeof(s_chunk) - 1) break;
    }
    if (!pos) {
        *(uint8_t *)ret = 1;
        set_str((uint8_t *)ret + 8, "usage: lua <chunk>");
        return;
    }
    L("[console] lua chunk (%zu bytes): %.80s", pos, s_chunk);
    s_out[0] = 0;
    lua_exec_chunk(s_chunk, s_out, sizeof(s_out));
    *(uint8_t *)ret = 1;
    set_str((uint8_t *)ret + 8, s_out);
    // >15-char results live in a HeapAlloc string; console_invoke_core's
    // engine_free_string skips non-engine blocks -> bounded deliberate leak
    // (same contract as the ret slot comment there).
}

// -+ pseudo entries
// OLD approach (REMOVED): HeapAlloc a bigger entry array, memcpy the engine's
// array into it, swap mgr+0x00. FATAL: the engine later grows/frees that array
// through its own allocator -> custom block-header contract violated ->
// UCRT invalid parameter -> __fastfail(5). This was a standing landmine under
// EVERY engine string operation (confirmed via full-dump analysis 2026-08-24).
//
// NEW approach: entries live in our static memory (permanent, never freed,
// never reallocated by anyone). They are surfaced by intercepting the NATIVE
// lookup in HK_FindCommandByName when the engine's own table misses.
static char s_pseudoLuaName[] = "lua";
uint8_t s_pseudoLua[0x1C8];         // E: `lua` pseudo command (batch E)

static void init_pseudo_entries(void) {
    memset(s_pseudoLua, 0, sizeof(s_pseudoLua));
    *(uint8_t *)(s_pseudoLua + 0) = 1;                 // dev-flag bit
    // "lua" is 3 chars <= SSO(15): bytes inline per MSVC string layout
    memcpy(s_pseudoLua + 8, s_pseudoLuaName, 4);
    *(uint64_t *)(s_pseudoLua + 0x10) = 3;             // length
    *(uint64_t *)(s_pseudoLua + 0x18) = 15;            // SSO capacity
    *(void **)(s_pseudoLua + 0x68) = (void *)CmdLuaHandler;
    *(void **)(s_pseudoLua + 0x78) = NULL;
    L("[console] pseudo entry ready: lua <chunk> (batch E)");
}

// Active acquisition (2026-09-12): the engine keeps the console manager in
// the global slot qword_1435C8B20 and lazily constructs it via sub_14249FCE0
// (its own pattern in sub_1423D11A0: if (!slot) { ctor(); } use slot).
// Reading the slot removes the dependency on the engine's FIRST
// FindCommandByName call; the HK capture in the hook stays as a zero-cost
// fallback, and the hook keeps its second job (serving pseudo entries to
// the native debug console). Call only from booted-game contexts (invoke
// paths), never during DllMain — the ctor allocates via the engine heap.
static int console_mgr_acquire(void) {
    if (g_mgr || !g_base) return g_mgr ? 1 : 0;
    uintptr_t slotAddr = (uintptr_t)g_base + CONSOLE_MGR_SLOT;
    uint64_t slot = 0;
    __try { slot = *(volatile uint64_t *)slotAddr; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (!slot) {
        typedef void (__fastcall *MgrCtor_t)(void);
        MgrCtor_t ctor = (MgrCtor_t)(g_base + RVA_MGR_CTOR);
        __try { ctor(); }
        __except (EXCEPTION_EXECUTE_HANDLER) {
            L("[console] mgr lazy-ctor faulted; waiting for HK capture");
            return 0;
        }
        __try { slot = *(volatile uint64_t *)slotAddr; }
        __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    }
    if (!slot) return 0;
    g_mgr = (void *)(uintptr_t)slot;
    L("[console] mgr acquired from qword_1435C8B20 = %p", g_mgr);
    init_pseudo_entries();
    return 1;
}

// does this std::string* hold 'name'? (read-only peek, SSO aware)
static int stdstr_equals(void *nameStr, const char *name) {
    if (!nameStr) return 0;
    uint64_t len = *(uint64_t *)((char *)nameStr + 0x10);
    const char *s = (len > 15) ? *(const char **)nameStr : (const char *)nameStr;
    if (!s) return 0;
    return _stricmp(s, name) == 0;
}

// -+ console()
// hoi4.console("cmd arg1 arg2") -> invoke a native console command by name.
// Command entry layout (INJECTION_PLAN.md, M2 实测):
//   +0x00  name (std::string)  / +0x28  alias count / +0x30  alias table
//   +0x68  handler(ret std::string*, args std::vector<std::string>*, userdata)
//   +0x78  userdata / +0x88  flags / +0x108  permission value
// Table: mgr+0x00 = entry array ptr, mgr+0x0C = entry count (int).
// This is the read/invoke counterpart of register_command() (write path).
#define CMD_STRIDE  0x1C8
#define CMD_NAME_OFF 0
#define CMD_FN_OFF   0x68

typedef void (*CmdInvoke_t)(void *ret, void *args, void *userdata);

// -+ crash forensics forensics
// From inside a running Lua effect, console commands that dispatch game
// scripts (`event`, `eval_effect`) kill the process SILENTLY: no Paradox dump,
// no WER record, our SEH around the handler call never fires. That signature
// points at fail-fast / terminate-class death rather than an ordinary AV.
// These probes run ONLY while a dangerous command executes (armed window), so
// normal gameplay is unaffected.
static volatile long g_forensicArmed;      // 1 while the risky handler runs
static LONG WINAPI forensic_veh(EXCEPTION_POINTERS *ep) {
    if (InterlockedCompareExchange(&g_forensicArmed, 0, 0)) {
        L("[console] VEH: exception code=%08lx addr=%p",
          ep->ExceptionRecord->ExceptionCode,
          ep->ExceptionRecord->ExceptionAddress);
    }
    return EXCEPTION_CONTINUE_SEARCH;
}
static LONG WINAPI forensic_uef(EXCEPTION_POINTERS *ep) {
    L("[console] UEF: last-chance exception code=%08lx addr=%p",
      ep->ExceptionRecord->ExceptionCode,
      ep->ExceptionRecord->ExceptionAddress);
    // 2026-08-27: CONTINUE_SEARCH (was EXECUTE_HANDLER) so WER LocalDumps
    // still captures the crash — swallowing it here left no .dmp for the
    // recurring vars-dump crash. The VEH above already logged what we need.
    return EXCEPTION_CONTINUE_SEARCH;
}

// (build_string_vector removed — replaced by engine-layout static args
// container built inline in hoi4_console; see the layout comment there.)

// find command entry by exact name — delegate to the NATIVE lookup (g_origFind),
// falling back to our static pseudo entries on a native miss.
// E fix (2026-09-12 live validation): the pseudo fallback previously existed
// ONLY in HK_FindCommandByName (the engine's native dispatch path), so our
// OWN bridge — console_invoke_core, used by hoi4.console AND the IPC
// executor — could never reach `lua`
// ("unknown command" forever). Share one pseudo lookup for both paths.
static uint8_t *pseudo_lookup(const char *name) {
    if (!strcmp(name, "lua")) return s_pseudoLua;
    return NULL;
}

static uint8_t *find_command_entry(const char *name) {
    if (!g_mgr || !name || !*name) return NULL;
    if (!g_origFind) return NULL;
    uint8_t nameStr[0x20];
    memset(nameStr, 0, sizeof(nameStr));
    set_str(nameStr, name);   // std::string layout: +0x10 len, SSO <= 15
    void *entry = NULL;
    __try {
        entry = g_origFind(g_mgr, nameStr);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return NULL;
    }
    if (!entry) entry = pseudo_lookup(name);
    return (uint8_t *)entry;
}

// read back a std::string (SSO-aware) into a caller buffer
static int read_std_string(void *addr, char *out, size_t cap) {
    if (!addr || !out || cap == 0) return 0;
    const char *s = (const char *)addr;
    uint64_t len = *(uint64_t *)((char *)addr + 0x10);
    if (len > 15) s = *(const char **)addr;
    if (!s) return 0;
    size_t n = (size_t)len;
    if (n >= cap) n = cap - 1;
    memcpy(out, s, n);
    out[n] = 0;
    return 1;
}

// -+ console()
// Command entry layout
//   +0x00 dev flag byte / +0x08 name std::string / +0x68 handler / +0x78 userdata
// Handler signature : f(ret_str*, args*, userdata)
//
// Args CONTAINER layout (engine custom, NOT std::vector — this was the crash):
//   +0x00  elements ptr (stride 0x20 std::string each)
//   +0x08  ? (ctor zeroes it)
//   +0x0C  int count        <-- consumers read THIS (we used to ship an MSVC
//                                vector{begin,end,cap}; the engine read the
//                                begin-pointer's HIGH DWORD as count -> walked
//                                thousands of garbage "strings" -> allocator
//                                validator __fastfail(5). Full-dump confirmed.)
// Ctor reference: FUN_14011da30 -> {NULL, NULL, &static_sentinel}
//
// rebuild rules (all static memory, ZERO heap on our side):
//   * container + elements: function-local static buffers, permanent
//   * element strings: SSO only — tokens >15 chars are REJECTED (clean nil
//     return) because inline bytes need no allocator contract at all
//   * ret: zeroed static std::string; if a handler moves a heap string into
//     it we DELIBERATELY leak it (bounded, rare) instead of replicating the
//     engine's block-header free/validate dance
#define CMD_MAX_ARGS 31

// engine string release, replicating the native submit cleanup exactly:
//   heap block = [data-8] (back-pointer written by the aligned-alloc ctor),
//   padding check (raw..data <= 0x1F), then HeapFree on the ENGINE's heap.
// Engine heap handle lives in global DAT_1435cedf0 (RVA 0x35CEDF0, verified
// via FUN_1421b4b50 decompile). On ANY doubt we skip the free (leak one
// string) rather than risk a repeat of the c0000409 fastfail.
static void engine_free_string(uint8_t *s) {
    if (!s) return;
    uint64_t len = *(uint64_t *)(s + 0x10);
    if (len <= 15) return;                       // SSO: nothing on the heap
    uint8_t *data = *(uint8_t **)s;              // heap buffer
    if (!data) return;
    uintptr_t rawStored = *(uintptr_t *)(data - 8);
    if (!rawStored || (rawStored & 7)) {         // implausible back-pointer
        L("[console] engine_free_string: suspicious back-pointer %llx, skipping",
          (unsigned long long)rawStored);
        return;
    }
    uintptr_t pad = (uintptr_t)data - rawStored - 8;
    if (pad > 0x1F) {
        L("[console] engine_free_string: padding %llx > 0x1F, skipping",
          (unsigned long long)pad);
        return;
    }
    HANDLE *heapPtr = (HANDLE *)(g_base + ENGINE_HEAP_HANDLE);
    HANDLE hHeap = *heapPtr;
    if (!hHeap) return;
    HeapFree(hHeap, 0, (void *)rawStored);
}

// long-token: build an ENGINE-contract heap string (tokens >15 chars).
// Replicates the native ctor observed in FUN_14249FE00's growth path:
//   raw  = FUN_1421B4B50(cap + 0x28)   engine allocator wrapper (HeapAlloc+retry)
//   data = (raw + 0x27) & ~0x1F        32-byte aligned payload
//   [data - 8] = raw                   back-pointer consumed by free/cleanup
// Fills dst as a standard MSVC string {data, ?, len, cap}. Returns 1 on
// success, 0 on alloc failure (nothing partially built -> caller can refuse
// the command cleanly). Pair EVERY successful call with engine_free_string.
typedef void *(*EngAlloc_t)(size_t);
static int engine_make_string(uint8_t *dst, const char *src) {
    size_t len = strlen(src);
    EngAlloc_t allocFn = (EngAlloc_t)(g_base + RVA_ENGINE_ALLOC);
    if (!len || !allocFn || len + 0x28 < len) return 0;
    uint8_t *raw = (uint8_t *)allocFn(len + 0x28);
    if (!raw) return 0;
    uint8_t *data = (uint8_t *)((uintptr_t)(raw + 0x27) & ~(uintptr_t)0x1F);
    *(uint8_t **)(data - 8) = raw;               // back-pointer (free contract)
    memcpy(data, src, len);
    data[len] = 0;
    *(uint8_t **)dst         = data;
    *(uint64_t *)(dst + 0x08) = 0;               // unused middle field
    *(uint64_t *)(dst + 0x10) = len;
    *(uint64_t *)(dst + 0x18) = len;             // capacity == len (native form)
    return 1;
}

// engine-invocation core shared by the Lua bridge (hoi4_console), the `lua`
// pseudo command, and the HTTP module's /console endpoint.
// Returns 1 and fills out (NUL-terminated ret text, possibly "") on a normal
// handler return; 0 on unknown command / missing handler / alloc failure /
// handler fault. Must run on the game main thread.
int console_invoke_core(const char *cmd, char *out, size_t cap_out)
{
    if (cap_out) out[0] = 0;
    console_mgr_acquire();   // t=0 usable; HK capture stays as fallback
    // split into whitespace-separated tokens; token[0] = command name
    char tokens[32][128];
    int nTokens = 0;
    const char *p = cmd;
    while (*p && nTokens < 32) {
        while (*p == ' ' || *p == '\t') p++;
        if (!*p) break;
        size_t n = 0;
        while (*p && *p != ' ' && *p != '\t' && n + 1 < 128)
            tokens[nTokens][n++] = *p++;
        tokens[nTokens][n] = 0;
        nTokens++;
    }
    if (nTokens == 0) return 0;
    const char *name = tokens[0];

    uint8_t *entry = find_command_entry(name);
    if (!entry) {
        L("[console] console: unknown command '%s'", name);
        return 0;
    }
    CmdInvoke_t fn = *(CmdInvoke_t *)(entry + CMD_FN_OFF);
    if (!fn) {
        L("[console] console: '%s' has no handler (fn=NULL)", name);
        return 0;
    }

    // ---- build args container in ENGINE layout (static, permanent) --------
    // Ret slot contract (help/savegame handler decomp 2026-08-27, RVA
    // 0x261640/0x280280): [u8 status @+0][std::string @+8] = 0x28 bytes.
    // The old 0x20 buffer was 8 bytes short: handlers writing the SSO cap
    // field at +0x28 corrupted adjacent statics -> delayed c0000005 in
    // unrelated modules (help/date/quit crashed, event/eval_effect only
    // survived because their SSO writes stayed inside +8..+0x1F).
    static uint8_t argsElem[(CMD_MAX_ARGS) * 0x20];   // element strings
    static uint8_t argsContainer[24];
    static uint8_t retStr[0x28];                      // status + string
    static int     heapIdx[CMD_MAX_ARGS];             // elements needing free
    int nHeap = 0;
    int nArgs = nTokens - 1;

    memset(argsElem, 0, sizeof(argsElem));
    memset(argsContainer, 0, sizeof(argsContainer));
    memset(retStr, 0, sizeof(retStr));                // status=0, empty SSO string
    for (int i = 0; i < nArgs; i++) {
        if (strlen(tokens[i + 1]) <= 15) {
            set_str(argsElem + (size_t)i * 0x20, tokens[i + 1]);   // SSO inline
        } else if (engine_make_string(argsElem + (size_t)i * 0x20,
                                      tokens[i + 1])) {
            heapIdx[nHeap++] = i;                      // engine-contract heap str
        } else {
            L("[console] console '%s': alloc failed for token %d, aborting", cmd, i);
            for (int k = 0; k < nHeap; k++)
                engine_free_string(argsElem + (size_t)heapIdx[k] * 0x20);
            return 0;
        }
    }
    *(void **)(argsContainer + 0x00) = argsElem;      // elements ptr
    *(int   *)(argsContainer + 0x0C) = nArgs;         // ENGINE reads count HERE

    // userdata = entry's own +0x78 field ('event' handler dereferences it)
    void *userdata = *(void **)(entry + 0x78);

    // flag parity with the native MAIN path (submit clears mgr+0xd9)
    if (g_mgr) *(uint8_t *)((uintptr_t)g_mgr + 0xd9) = 0;

    // ---- invoke -----------------------------------------------------------
    L("[console] invoking '%s' handler=%p nArgs=%d (engine-layout static args)",
      name, (void *)fn, nArgs);
    // VEH removal requires the REGISTRATION HANDLE from Add, not the function
    // pointer (the old code leaked one VEH per console call). UEF is a
    // process-global chain: save and restore the previous filter on all exits.
    PVOID veh = AddVectoredExceptionHandler(1, forensic_veh);
    LPTOP_LEVEL_EXCEPTION_FILTER oldUef = SetUnhandledExceptionFilter(forensic_uef);
    InterlockedExchange(&g_forensicArmed, 1);
    __try {
        fn(retStr, argsContainer, userdata);
        L("[console] '%s' handler RETURNED normally", name);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        L("[console] console: '%s' handler faulted (SEH code=%08x)", name,
          GetExceptionCode());
        InterlockedExchange(&g_forensicArmed, 0);
        if (veh) RemoveVectoredExceptionHandler(veh);
        SetUnhandledExceptionFilter(oldUef);
        // fault path: release OUR heap-string args before bailing (was leaked)
        for (int k = 0; k < nHeap; k++)
            engine_free_string(argsElem + (size_t)heapIdx[k] * 0x20);
        return 0;
    }
    InterlockedExchange(&g_forensicArmed, 0);
    if (veh) RemoveVectoredExceptionHandler(veh);
    SetUnhandledExceptionFilter(oldUef);
    // read BEFORE release; empty on read failure (still a normal invoke).
    // The string lives at retStr+8 (status byte occupies +0).
    read_std_string(retStr + 8, out, cap_out);
    // release whatever the handler left in the string slot using the ENGINE's
    // own contract; engine_free_string skips (leaks one bounded string) on doubt.
    engine_free_string(retStr + 8);
    memset(retStr, 0, sizeof(retStr));                // reset status+SSO
    // free OUR heap-string elements (SSO elements need nothing)
    for (int k = 0; k < nHeap; k++)
        engine_free_string(argsElem + (size_t)heapIdx[k] * 0x20);
    L("[console] console '%s' nArgs=%d -> %s", name, nArgs,
      *out ? out : "(empty)");
    return 1;
}

int hoi4_console(lua_State *Ls) {
    const char *cmd = luaL_checkstring(Ls, 1);
    if (!cmd || !*cmd) { lua_pushnil(Ls); return 1; }
    char out[512];
    if (!console_invoke_core(cmd, out, sizeof(out))) {
        lua_pushnil(Ls);
        return 1;
    }
    lua_pushstring(Ls, out);
    return 1;
}


void *__fastcall HK_FindCommandByName(void *mgr, void *nameStr) {
    if (!g_mgr) {
        g_mgr = mgr;
        L("[capture] console mgr = %p", mgr);
        init_pseudo_entries();
    }
    // capture the NATIVE dispatch chain (caller RVA logging, one-shot per
    // distinct caller). Kept from the crash investigation.
    {
        void *ret = _ReturnAddress();
        static void *lastLogged;
        if (ret != lastLogged) {
            lastLogged = ret;
            L("[console] FindCmdByName caller=%p base=%p rva=0x%llx",
              ret, (void *)g_base,
              (unsigned long long)((uintptr_t)ret - (uintptr_t)g_base));
        }
    }
    void *found = g_origFind(mgr, nameStr);
    if (!found && nameStr) {
        // engine table missed: surface our STATIC pseudo entries. The returned
        // pointer must stay valid forever — hence no heap involvement at all.
        if (stdstr_equals(nameStr, "lua")) {
            L("[console] pseudo entry served: lua");
            return s_pseudoLua;
        }
    }
    return found;
}

