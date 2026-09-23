#include "hoi4_common.h"

// forward decls for cross-module hook targets (see hoi4_common.h)
void lua_init_thread(void *unused);

// ---- game binary signature check ----
// All image addresses AND the expected PE signature live in the compiled-in
// kOffValues table (hoi4_offsets.h / hoi4_offsets.cpp). Loading fails closed:
// signature mismatch or a zero table entry -> DllMain returns FALSE and the
// game keeps running untouched.

#include "hoi4_lde.h"   // pure decoder extracted for unit tests (tests/test_lde.cpp)

// steal >= minBytes of WHOLE instructions at target; returns byte count or 0
static int hook_steal_len(const uint8_t *target, int minBytes, int maxBytes) {
    int total = 0;
    uint8_t window[32];
    __try {
        memcpy(window, target, sizeof(window));
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    while (total < minBytes) {
        int rel = 0;
        int n = lde_len(window + total, (uint32_t)(sizeof(window) - total), &rel);
        if (n <= 0) {
            L("[hook] lde: unrecognized%s opcode %02X at target+%d",
              rel ? " relative-cf" : "", window[total], total);
            return 0;
        }
        total += n;
    }
    if (total > maxBytes) return 0;
    return total;
}

#define HOOK_JUMP_BYTES 12   // movabs rax + jmp rax

static int install_abs_jmp(uint8_t *target, void *dst, uint8_t *saved,
                           void **trampOut) {
    int stolen = hook_steal_len(target, HOOK_JUMP_BYTES, 24);
    if (!stolen) {
        L("[hook] REFUSED @ %p: prologue not cleanly stealable", target);
        return 0;
    }
    memcpy(saved, target, stolen);
    uint8_t *stub = (uint8_t *)VirtualAlloc(NULL, 64, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!stub) return 0;
    memcpy(stub, target, stolen);
    stub[stolen+0] = 0x48; stub[stolen+1] = 0xB8;
    *(uint64_t *)(stub + stolen + 2) = (uint64_t)(target + stolen);
    stub[stolen+10] = 0xFF; stub[stolen+11] = 0xE0;
    *trampOut = stub;
    DWORD op;
    VirtualProtect(target, (SIZE_T)stolen, PAGE_EXECUTE_READWRITE, &op);
    target[0] = 0x48; target[1] = 0xB8;
    *(uint64_t *)(target + 2) = (uint64_t)dst;
    target[10] = 0xFF; target[11] = 0xE0;
    for (int i = HOOK_JUMP_BYTES; i < stolen; i++) target[i] = 0x90; // pad to boundary
    VirtualProtect(target, (SIZE_T)stolen, op, &op);
    FlushInstructionCache(GetCurrentProcess(), target, (SIZE_T)stolen);
    return 1;
}

static int install_hooks(void) {
    g_base = (uint8_t *)GetModuleHandleW(NULL);
    if (!offsets_load()) {
        L("[fatal] offsets load/verify failed — refusing to patch.");
        return 0;
    }
    if (!install_abs_jmp(g_base + RVA_FIND_CMD_BY_NAME, HK_FindCommandByName,
                    (uint8_t *)VirtualAlloc(NULL, 24, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE),
                    (void **)&g_origFind)) return 0;
    L("[hook] FindCommandByName @ %p", g_base + RVA_FIND_CMD_BY_NAME);
    if (!install_abs_jmp(g_base + RVA_EFFECT_ROUTER, HK_EffectRouter,
                    (uint8_t *)VirtualAlloc(NULL, 24, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE),
                    (void **)&g_origRouter)) return 0;
    L("[hook] EffectRouter @ %p (orig %p)", g_base + RVA_EFFECT_ROUTER, g_origRouter);
    g_engNew = (EngineNew_t)(g_base + RVA_ENGINE_NEW);
    g_factorySetGlobal = (void *(*)(void))(g_base + RVA_SET_GLOBAL_FACTORY);
    g_engPush = (void (*)(uint8_t *, void **))(g_base + RVA_VEC_PUSH_BACK);
    // name bridge fn
    g_nameToKey = (void (*)(int *, void *))(g_base + RVA_NAME_TO_KEY);
    L("[init] machinery: new=%p factory=%p push=%p", g_engNew, g_factorySetGlobal, g_engPush);
    L("[bridge] bridge: nameToKey=%p", g_nameToKey);
    // trigger machinery
    g_factoryGFT = (void *(*)(void))(g_base + RVA_GFT_FACTORY);
    build_my_tvt();
    if (!install_abs_jmp(g_base + RVA_TRIGGER_ROUTER, HK_TriggerRouter,
                    (uint8_t *)VirtualAlloc(NULL, 24, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE),
                    (void **)&g_origTRouter)) return 0;
    L("[trigger] TriggerRouter @ %p (orig %p) factory=%p",
      g_base + RVA_TRIGGER_ROUTER, g_origTRouter, g_factoryGFT);
    build_my_vtable();
    // per-frame heartbeat via VTABLE SLOT swap (see
    // frame_block.inc; the inline body patch was dump-proven fatal -
    // the abs-jmp trampoline clobbers rax which the stolen prologue feeds
    // into rbp/movaps later in FUN_140DBF240).
    install_v4_vtable_hook();
    return 1;
}

BOOL APIENTRY DllMain(HMODULE hMod, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hMod);
        // No file IO here (loader lock): early log entries go to the memory
        // ring; lua_init_thread opens the real file under <user>/logs/ once
        // paths are resolved (log_open_in_logs_dir).
        L("=== hoi4_bridge loaded (pid %lu) ===", GetCurrentProcessId());
        int ok = 0;
        __try { ok = install_hooks(); }
        __except (EXCEPTION_EXECUTE_HANDLER) {
            L("[fatal] hook install crashed");
            return FALSE;
        }
        if (!ok) {
            L("[fatal] hook install refused/failed — DLL not activating");
            return FALSE;
        }
        // Lua init on a worker thread: DllMain (loader lock) must stay light
        CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)lua_init_thread, NULL, 0, NULL);
        // heartbeat: no extra thread needed anymore - the frame hook
        // installed above (CInGameIdler::v4) dispatches on the engine's
        // pinned main thread, in-game only. The old WM_TIMER worker was
        // removed with the route-B redesign.
    }
    return TRUE;
}
