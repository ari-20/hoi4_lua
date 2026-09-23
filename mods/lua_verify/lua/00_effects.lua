-- 00_effects.lua — routing canary
-- Verifies the full chain: engine text effect/trigger -> router hook ->
-- registry -> synthesized object -> vtable slot -> Lua callback.
-- 路由链 = §4.00.3 脚本效应基类 (CEffect [13]=Execute / CTrigger [22]=Evaluate;
-- 注册经 hoi4.effect/trigger registry, 同名覆盖即热更新)。
-- Usage (in game console or via /lua hoi4.console)
-- m4_hello -> effect: writes m4b_lua_fired.txt + logs vars count
-- m4_dual -> effect AND trigger (dual-registration check)

-- 自定位 (SELF_DIR 惯用法): debug.getinfo 源路径优先; 裸 POST 执行的
-- chunk 没有源路径时退回 MOD_LUA_DIR (last-mod-wins 共享全局, 仅兜底)
local SELF_DIR = (function()
    local src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)[/\\][^/\\]*$")
    if dir then return dir end
    return MOD_LUA_DIR
end)()
local MY_DIR = SELF_DIR

-- ---------------------------------------------------------------- hello canary
-- One-call end-to-end proof that the routing chain is alive: fires only if
-- engine parse -> HK_EffectRouter -> registry hit -> vtable Execute -> Lua.
local function m4_hello(name, self, ctx)
    local f = io.open(MY_DIR .. "\\m4b_lua_fired.txt", "a")
    if f then f:write(name .. " executed!\n"); f:close() end
    hoi4.log("[canary] m4_hello routed and executed")
end
hoi4.effect("m4_hello", m4_hello)

-- ---------------------------------------------------------------- dual check
-- Same name registered as BOTH effect and trigger (HOI4-style verb/predicate
-- pair): as a trigger it must return true.
local function m4_dual_impl(name, self, ctx)
    hoi4.log("[canary] m4_dual executed (as " .. tostring(name) .. ")")
    return true
end
hoi4.effect("m4_dual", m4_dual_impl)
hoi4.trigger("m4_dual", m4_dual_impl)
