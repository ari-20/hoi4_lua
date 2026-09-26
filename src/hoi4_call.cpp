// hoi4_call.cpp — guarded engine call primitive + write-side wrappers
//
// Threading model (live-probed): Lua callbacks always run on the main thread,
// in contexts the engine itself mutates state — the TLS forbid gate is the
// engine itself mutates state — the TLS forbid gate is the engine's own rule).
//
// Hard guards on EVERY call:
//   1. current thread == the Lua-callback thread holding g_luaLock
//   2. gamestate singleton live
//   3. engine's own forbid gate: *(u32*)(TLSSlot[TlsIndex] + 16) == 0
//      TlsIndex @ RVA 0x35CD218 (extracted from sub_141D13B10: the same
//      instruction neighbourhood loads 0x860=2144 and 0x10=16, the two
//      guard offsets). Unresolvable/invalid -> API disabled (fails closed).
//
// call_u64 is a DEBUG/tooling primitive: production setters should go
// through the verified wrappers below. SEH catches AVs; silent state
// corruption from wrong ABIs is NOT catchable — whitelist discipline
// applies (GAP6 §4A.3).

#include "hoi4_common.h"
#include "hoi4_hook.h"
#include <intrin.h>        // __readgsqword: TEB+0x58 = ThreadLocalStoragePointer
                          // (winternl.h's _TEB in SDK 10.0.26100 lacks the field)

static int call_guard_ok(void) {
    // 1. only from inside a Lua callback (thread holds the lock)
    if (GetCurrentThreadId() != g_luaOwner || g_luaDepth == 0) {
        L("[call] refused: not on Lua callback thread");
        return 0;
    }
    // 2. gamestate live
    if (!h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0)) {
        L("[call] refused: no gamestate");
        return 0;
    }
    // 3. engine forbid gate — gated on the SAME flag the engine uses.
    // byte_1435C8BF2==0 in the retail build disables the whole assert family
    // (incl. ThreadForbidCount) — then the guard is vacuous BY ENGINE DESIGN,
    // regardless of what dwTlsIndex happens to hold (observed: -1 and 0 in
    // different runs). Only when asserts are on AND the index is valid do we
    // replicate the engine's own check.
    static volatile long s_tlsChecked = 0;
    static int s_guard3Active = 0;
    static DWORD s_tlsIndex = 0;
    if (!s_tlsChecked) {
        uint8_t assertsOn = *(volatile uint8_t *)(g_base + RVA_ASSERTS_BYTE);
        DWORD ti = *(volatile DWORD *)(g_base + RVA_ENGINE_TLSINDEX);
        s_tlsIndex = ti;
        s_guard3Active = (assertsOn && ti < 1088) ? 1 : 0;
        L("[call] asserts(RVA_ASSERTS_BYTE)=%u TlsIndex=%ld -> guard3 %s",
          assertsOn, (long)ti, s_guard3Active ? "active" : "vacuous");
        InterlockedExchange(&s_tlsChecked, 1);
    }
    if (s_guard3Active) {
        uintptr_t *tls = (uintptr_t *)__readgsqword(0x58);   // TEB->TlsSlots
        uint32_t forbid = 0;
        __try { forbid = *(volatile uint32_t *)(tls[s_tlsIndex] + 16); }
        __except (EXCEPTION_EXECUTE_HANDLER) { forbid = 1; }
        if (forbid != 0) {
            L("[call] refused: ThreadForbidCount=%u", forbid);
            return 0;
        }
    }
    return 1;
}

static uint64_t ca_addr(lua_State *Ls, int n) {
    if (lua_type(Ls, n) == LUA_TLIGHTUSERDATA)
        return (uint64_t)(uintptr_t)lua_touserdata(Ls, n);
    return (uint64_t)luaL_optinteger(Ls, n, 0);
}

// hoi4.call_u64(addr, a1?, a2?, a3?, a4?) -> u64 or nil
// CALL-DOMAIN GATE (hoi4_memgate.cpp, policy 2026-09-23): the target must lie
// in an executable section of the hoi4.exe image. kernel32 exports
// (VirtualAlloc/VirtualProtect/LoadLibraryA), fresh RWX pages and
// bridge-internal addresses are unreachable from Lua. All in-corpus callers
// use BASE+<RVA> engine addresses, which pass unchanged.
static int call_domain_refused(lua_State *Ls, const char *api, uint64_t addr) {
    L("[call] %s refused: %llx outside engine exec sections", api,
      (unsigned long long)addr);
    audit_mem_deny(Ls, "call", addr, "outside engine exec sections");
    return 0;
}

int hoi4_call_u64(lua_State *Ls) {
    uint64_t addr = ca_addr(Ls, 1);
    uint64_t a1 = ca_addr(Ls, 2), a2 = ca_addr(Ls, 3);
    uint64_t a3 = ca_addr(Ls, 4), a4 = ca_addr(Ls, 5);
    if (!addr || !call_guard_ok()) { lua_pushnil(Ls); return 1; }
    if (!memgate_exec_ok(addr)) { call_domain_refused(Ls, "call_u64", addr); lua_pushnil(Ls); return 1; }
    int nargs = lua_gettop(Ls) - 1;
    uint64_t ret = 0;
    __try {
        switch (nargs <= 0 ? 0 : (nargs > 4 ? 4 : nargs)) {
        case 0: ret = ((uint64_t(__fastcall *)(void))addr)(); break;
        case 1: ret = ((uint64_t(__fastcall *)(uint64_t))addr)(a1); break;
        case 2: ret = ((uint64_t(__fastcall *)(uint64_t, uint64_t))addr)(a1, a2); break;
        case 3: ret = ((uint64_t(__fastcall *)(uint64_t, uint64_t, uint64_t))addr)(a1, a2, a3); break;
        default: ret = ((uint64_t(__fastcall *)(uint64_t, uint64_t, uint64_t, uint64_t))addr)(a1, a2, a3, a4); break;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        L("[call] call_u64(%llx) faulted 0x%lx", (unsigned long long)addr,
          GetExceptionCode());
        lua_pushnil(Ls);
        return 1;
    }
    lua_pushinteger(Ls, (lua_Integer)ret);
    return 1;
}

// hoi4.call_void(addr, a1?, ..., a4?) -> true or nil
int hoi4_call_void(lua_State *Ls) {
    uint64_t addr = ca_addr(Ls, 1);
    uint64_t a1 = ca_addr(Ls, 2), a2 = ca_addr(Ls, 3);
    uint64_t a3 = ca_addr(Ls, 4), a4 = ca_addr(Ls, 5);
    if (!addr || !call_guard_ok()) { lua_pushnil(Ls); return 1; }
    if (!memgate_exec_ok(addr)) { call_domain_refused(Ls, "call_void", addr); lua_pushnil(Ls); return 1; }
    int nargs = lua_gettop(Ls) - 1;
    __try {
        switch (nargs <= 0 ? 0 : (nargs > 4 ? 4 : nargs)) {
        case 0: ((void(__fastcall *)(void))addr)(); break;
        case 1: ((void(__fastcall *)(uint64_t))addr)(a1); break;
        case 2: ((void(__fastcall *)(uint64_t, uint64_t))addr)(a1, a2); break;
        case 3: ((void(__fastcall *)(uint64_t, uint64_t, uint64_t))addr)(a1, a2, a3); break;
        default: ((void(__fastcall *)(uint64_t, uint64_t, uint64_t, uint64_t))addr)(a1, a2, a3, a4); break;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        L("[call] call_void(%llx) faulted 0x%lx", (unsigned long long)addr,
          GetExceptionCode());
        lua_pushnil(Ls);
        return 1;
    }
    lua_pushboolean(Ls, 1);
    return 1;
}

// ---------------------------------------------------------------- wrappers
// hoi4.engine_alloc(n) -> ptr or nil (engine allocator FUN_1421B4B50;
// engine_make_string's proven contract). Free with hoi4.engine_free.
typedef void *(*EngAlloc_t)(size_t);
int hoi4_engine_alloc(lua_State *Ls) {
    size_t n = (size_t)luaL_checkinteger(Ls, 1);
    if (!call_guard_ok()) { lua_pushnil(Ls); return 1; }
    EngAlloc_t fn = (EngAlloc_t)(g_base + RVA_ENGINE_ALLOC);
    void *p = NULL;
    __try { p = fn(n); }
    __except (EXCEPTION_EXECUTE_HANDLER) { p = NULL; }
    if (!p) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, (lua_Integer)(uintptr_t)p);
    return 1;
}

// hoi4.engine_free(p) -> bool. p = a RAW block from engine_alloc
// (the engine heap lives @ base+0x35CEDF0, per console.cpp's
// engine_free_string forensics).
int hoi4_engine_free(lua_State *Ls) {
    uint64_t p = ca_addr(Ls, 1);
    if (!p || !call_guard_ok()) { lua_pushnil(Ls); return 1; }
    HANDLE hHeap = *(HANDLE *)(g_base + ENGINE_HEAP_HANDLE);
    if (!hHeap) { lua_pushnil(Ls); return 1; }
    __try { HeapFree(hHeap, 0, (void *)(uintptr_t)p); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); return 1; }
    lua_pushboolean(Ls, 1);
    return 1;
}

// hoi4.name_to_token(name) -> token id or nil
// g_nameToKey = FUN_1424A6500, strview ABI {const char* data@0, u64 len@8}
// (NOT MSVC std::string — bridge.cpp documents the misread that once caused
// key=0 / SEH faults). Creates the token for new names (dynamic region).
int hoi4_name_to_token(lua_State *Ls) {
    size_t len = 0;
    const char *s = luaL_checklstring(Ls, 1, &len);
    if (!g_nameToKey || !call_guard_ok()) { lua_pushnil(Ls); return 1; }
    struct { const char *data; uint64_t len; } sv;
    sv.data = s;
    sv.len = (uint64_t)len;
    int key = 0;
    __try { g_nameToKey(&key, &sv); }
    __except (EXCEPTION_EXECUTE_HANDLER) { lua_pushnil(Ls); return 1; }
    if (key == 0) { lua_pushnil(Ls); return 1; }
    lua_pushinteger(Ls, key);
    return 1;
}

// hoi4.vec_push was removed 2026-09-21: no mod, sv2 segment, tool or doc ever
// called it. It was a raw engine-vector push_back taking a caller-supplied
// vector pointer with no validation, so a forged pointer meant a controlled
// out-of-bounds write - an unguarded primitive with zero users, which is pure
// future risk. g_engPush itself STAYS: the effect/trigger bind path in
// hoi4_vtable.cpp (the two call sites there) depends on it, and the engine
// pointer is still published in hoi4_detour.cpp.

// hoi4.load_save(name) -> bool
// Drives the ENGINE's own load-save entry sub_140DA04F0 — the same
// function the front-end Load Game button and console savecheck use. World
// rebuild completes synchronously inside the call; the session DR2 event at
// entry raises END+START, consumed at the next frame (cleanup + script reload).
// 主线程专用（call_guard_ok），name = 裸文件名（缺 .hoi4 自动补）。配方与
// savecheck handler 完全同型：mgr = app->vt[+880]()；desc 224B 栈对象 ctor
// → string::assign(desc+32, name, len) → entry(mgr, desc, gs+1312/1316) → dtor。
#define SAVEDESC_SIZE   224
#define SAVE_MGR_VT_OFF 880
int hoi4_load_save(lua_State *Ls) {
    size_t nl = 0;
    const char *name = luaL_checklstring(Ls, 1, &nl);
    if (!name || !*name || nl > 200) { lua_pushboolean(Ls, 0); return 1; }
    if (!call_guard_ok()) { lua_pushboolean(Ls, 0); return 1; }

    // name with .hoi4 suffix (engine joins the save games dir itself)
    char nameHoi4[256];
    snprintf(nameHoi4, sizeof(nameHoi4), "%s%s", name,
             (nl > 5 && strcmp(name + nl - 5, ".hoi4") == 0) ? "" : ".hoi4");

    uint64_t app = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_APP_MGR_PTR, 0);
    uint64_t gs  = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
    if (!app || !gs) { lua_pushboolean(Ls, 0); return 1; }

    uint8_t ok = 0;
    __try {
        // mgr = app->vt[+880]() — save manager getter (no side effects).
        // Memory-derived target: same exec-domain gate as call_u64 — a forged
        // heap vtable must not steer an uninstrumented bridge call site.
        // A hooked slot holds a hook-facility thunk; resolve it back to the
        // ORIGINAL getter instead of running a mod hook — bridge infrastructure
        // must not be vetoable by the mod layer (a vetoed load would abort the
        // verification workflow). A Tier 2 detour resolves to its trampoline,
        // which is why the gate below also accepts the bridge's own trampolines.
        void **appVt = *(void ***)app;
        uint64_t getter = (uint64_t)(uintptr_t)appVt[SAVE_MGR_VT_OFF / 8];
        {
            uint64_t orig = 0;
            if (hook_orig_for_thunk(getter, &orig)) getter = orig;
        }
        if (!memgate_exec_ok(getter) && !hook_is_our_trampoline(getter)) {
            L("[load_save] mgr getter %llx outside engine exec sections",
              (unsigned long long)getter);
            audit_mem_deny(Ls, "call", getter, "outside engine exec sections");
            __leave;
        }
        void *mgr = ((void *(__fastcall *)(void *))getter)((void *)(uintptr_t)app);
        if (!mgr) { lua_pushboolean(Ls, 0); return 1; }

        uint8_t desc[SAVEDESC_SIZE];
        memset(desc, 0, sizeof(desc));
        ((void(__fastcall *)(void *))(
            (uintptr_t)g_base + RVA_SAVEDESC_CTOR))(desc);
        ((int(__fastcall *)(void *, const char *, size_t))(
            (uintptr_t)g_base + RVA_STRING_ASSIGN))(
            desc + 32, nameHoi4, strlen(nameHoi4));
        int *mods = (int *)(gs + ((*(volatile int *)(gs + 1312) > 0) ? 1312 : 1316));
        ok = ((uint8_t(__fastcall *)(void *, void *, int *))(
            (uintptr_t)g_base + RVA_LOAD_ENTRY))(mgr, desc, mods);
        ((void(__fastcall *)(void *))(
            (uintptr_t)g_base + RVA_SAVEDESC_DTOR))(desc);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        L("[load_save] SEH in engine load path");
        lua_pushboolean(Ls, 0);
        return 1;
    }
    L("[load_save] %s -> %s", nameHoi4, ok ? "ok" : "failed");
    lua_pushboolean(Ls, ok ? 1 : 0);
    return 1;
}
