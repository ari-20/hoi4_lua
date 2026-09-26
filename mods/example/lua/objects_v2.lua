-- objects_v2.lua — 类层级对象访问层 · 汇总入口
-- 结构 (拆分后): 本文件只做「加载各域 + 挂契约位」; 实现分居 objects_*.lua。
-- hoi4_layout.lua 布局知识 + 访问原语 (唯一权威; 偏移/vtable/sentinel)
-- objects_shared.lua 跨域共享 (§0 原语 / §1 Runtime / §2 Country + 跨域助手)
-- objects_politics 学说 §3 / 政治外交 §4 / 生产 §5
-- objects_military 陆军 §6 / 舰队 §7 / 战略空军 §13 / 战斗 §14
-- objects_world 州省 §8 / 和会选择组 §19 / 资源 §20/§21 / 海军总部 §26
-- objects_characters 角色 §9 / 情报 §10-§12 / 角色深层 §29
-- objects_economy 燃料 §15 / 决议 §16-§17 / 编制 §18 / 装备 §22-§23 / 名字组 §25
-- objects_misc 快照 §24 / 国家报告 §27 / 杂项状态 §28 / 定义库 §30
-- objects_global 杂项族 §31 / 国家级杂项 §33 / 全局元数据族 §4.1/12/28
-- objects_manager 全局管理器代理族 §32 (weather/supply2/equipments/division_templates/rail_way/faction_pool)
--
-- 契约 (对外不可变): GAME.runtime / GAME.objects / GAME.objects_v2 (= Runtime 表)
-- GAME.objects_v2_country (= Country 方法表); 返回值 = Runtime。
-- 各域文件经 GAME.objects_shared 取共享符号并**直接往 Runtime/Country 挂方法**
-- (方法表引用共享, 挂载即累加), 故本文件末尾导出即完整。
-- 结构语义详见书 hoi4_runtime_classes.md (唯一权威)。
--
-- 加载 (DLL 平铺扫 lua/ 按字母序): 00_effects -> hoi4_layout -> objects_characters
-- -> economy -> global -> manager -> misc -> military -> politics -> shared -> v2 -> world
-- ⚠ 字母序下 objects_v2 先于 objects_world 加载 → 本文件用 dofile 显式
-- 按依赖序加载各域 (不依赖 DLL 的字母序); 重复 dofile 无害
-- (objects_shared 有世代守卫, 各域挂载 = 幂等覆盖同函数).

GAME = GAME or {}

-- 域文件目录自定位 (SELF_DIR 惯用法)
local SELF_DIR = (function()
    local src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)[/\\][^/\\]*$")
    return dir or MOD_LUA_DIR
end)()

-- 按依赖序加载 (shared 必须最先; 各域只依赖 shared)
-- ⚠ 各域文件经全局 GAME.objects_shared 取共享符号 → shared 加载后须立即注册
-- (域文件不 dofile shared, 避免重复执行 §0-2 建表)。
local LOAD_ORDER = {
    "objects_shared.lua",
    "objects_politics.lua",
    "objects_military.lua",
    "objects_world.lua",
    "objects_characters.lua",
    "objects_economy.lua",
    "objects_misc.lua",
    "objects_global.lua",
    "objects_manager.lua",
}
for _, name in ipairs(LOAD_ORDER) do
    if SELF_DIR then
        local ok, ret = pcall(dofile, SELF_DIR .. "/" .. name)
        if not ok then
            hoi4.log("[objects_v2] load " .. name .. " ERR: " .. tostring(ret))
        elseif type(ret) == "table" and name == "objects_shared.lua" then
            GAME.objects_shared = ret      -- 共享层注册 (域文件后续取用)
        end
    end
end

local SH = GAME.objects_shared
if not SH then
    hoi4.log("[objects_v2] objects_shared 未就绪 — 对象层不可用")
    return nil
end
local Runtime, Country = SH.Runtime, SH.Country

-- §99 挂载 (契约位; 与拆分前逐字一致)
GAME.runtime = Runtime
GAME.objects = Runtime            -- legacy 契约位 (export 读 GAME.objects)
GAME.objects_v2 = Runtime
GAME.objects_v2_country = Country  -- Country 方法表 (适配层按签名分派)
return Runtime
