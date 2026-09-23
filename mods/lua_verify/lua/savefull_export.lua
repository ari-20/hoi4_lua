-- savefull_export.lua -- 迁移: savefull 直出引擎
-- 目标架构: export 直出 savefull 形态 (dim\tpath\tval, 与 savefull3.py
-- 提取件同构), diff 退化为 linediff.py 多重集 join。
-- 当前覆盖: equipments 节点 (试点; 逐节点迁移, classdiff 双跑对照)。
-- 输出: MY_DIR/tmp_savefull_mem.txt (mod lua 目录, 无工作区硬编码)
-- 闭环: MY_DIR/tmp_savefull_done.flag (仅成功路径写, 内容 = 时间戳 + 叶数)
--
-- 调用契约 (重写): 本文件**顶层零执行** (只定义), 加载段文件
-- 与导出都由全局入口 `sv2_export([resave_name])` 显式触发
-- /lua 'return sv2_export' -- 纯导出 (mem + done flag)
-- /lua 'return sv2_export("<档名>")' -- 导出 + savegame 同帧同刻
-- 每次调用都会先重新 dofile 全部段文件 (磁盘新码即生效 = 函数更新,
-- 不存在"改了段文件导出还是旧码"的滞后); 顶层只重定义本文件自身。
-- 兼容: resave_name 省略时仍消费 resave_req.flag (一行存档名) 旧通道。
-- 自定位 (SELF_DIR 惯用法): debug.getinfo 源路径优先; 裸 POST 执行的
-- chunk 没有源路径时退回 MOD_LUA_DIR (last-mod-wins 共享全局, 仅兜底)
local SELF_DIR = (function()
    local src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)[/\\][^/\\]*$")
    if dir then return dir end
    return MOD_LUA_DIR
end)()
local MY_DIR = SELF_DIR
local L = hoi4.log

SV2 = { csec = {}, gsec = {} } -- 每代强制重置 (防热重载重复注册)

local function load_sec(name)
    -- 段文件自 起住 lua/sv2/ 子目录: DLL 加载器只平铺扫 lua/
    -- (*.lua 不递归), 段文件脱离加载器与 mtime watch — 唯一加载通道
    -- 就是本函数 (sv2_export 每次调用时重载, 磁盘新码即生效)
    local okf, errf = pcall(dofile, MY_DIR .. "/sv2/" .. name)
    if not okf then
        L("[SV2] load " .. name .. " ERR: " .. tostring(errf))
    end
end

local function load_secs()
    SV2 = { csec = {}, gsec = {} } -- 重载段前重置注册表
    load_sec("sv2_lib.lua")
    load_sec("sv2_sec_equipments.lua")
    load_sec("sv2_sec_division_templates.lua")
    load_sec("sv2_sec_c_variables.lua")
    load_sec("sv2_sec_c_politics.lua")
    load_sec("sv2_sec_c_technology.lua")
    load_sec("sv2_sec_c_characters.lua")
    load_sec("sv2_sec_c_resources.lua")
    load_sec("sv2_sec_c_program_status.lua")
    load_sec("sv2_sec_c_country_reports.lua")
    load_sec("sv2_sec_c_intel.lua")
    load_sec("sv2_sec_c_diplomacy.lua")
    load_sec("sv2_sec_c_units.lua")
    load_sec("sv2_sec_c_decisions.lua")
    load_sec("sv2_sec_c_names_trackers.lua")
    load_sec("sv2_sec_c_country_scalars.lua")
    load_sec("sv2_sec_c_operations.lua")
    load_sec("sv2_sec_c_fuel_status.lua")
    load_sec("sv2_sec_c_ai.lua")
    load_sec("sv2_sec_c_equipment_market.lua")
    load_sec("sv2_sec_c_convoys.lua")
    load_sec("sv2_sec_c_tokens.lua")
    load_sec("sv2_sec_c_radar.lua")
    load_sec("sv2_sec_c_nukes.lua")
    load_sec("sv2_sec_c_division_template_id.lua")
    load_sec("sv2_sec_c_strategic_navy.lua")
    load_sec("sv2_sec_c_experience_status.lua")
    load_sec("sv2_sec_c_intelligence_agency.lua")
    load_sec("sv2_sec_c_focus.lua")
    load_sec("sv2_sec_c_history.lua")
    load_sec("sv2_sec_c_manpower.lua")
    load_sec("sv2_sec_c_flags.lua")
    load_sec("sv2_sec_c_production.lua")
    load_sec("sv2_sec_c_occupation.lua")
    load_sec("sv2_sec_c_deployment.lua")
    load_sec("sv2_sec_states.lua")
    load_sec("sv2_sec_character_manager.lua")
    load_sec("sv2_sec_unit_leader.lua")
    load_sec("sv2_sec_supply_system_2.lua")
    load_sec("sv2_sec_doctrine.lua")
    load_sec("sv2_sec_provinces.lua")
    load_sec("sv2_sec_weather.lua")
    load_sec("sv2_sec_c_misc_tails.lua")
    load_sec("sv2_sec_c_theatres.lua")
    load_sec("sv2_sec_combat.lua")
    load_sec("sv2_sec_combat_log.lua")
    load_sec("sv2_sec_combat_data_entry.lua")
    load_sec("sv2_sec_rail_way.lua")
    load_sec("sv2_sec_strategic_operatives.lua")
    load_sec("sv2_sec_raids.lua")
    load_sec("sv2_sec_strategic_air.lua")
    load_sec("sv2_sec_session_meta.lua")
    load_sec("sv2_sec_emarket_global.lua")
    load_sec("sv2_sec_global_tails.lua")
    load_sec("sv2_sec_peace_conference.lua")
    load_sec("sv2_sec_c_volunteers.lua")
    load_sec("sv2_sec_naval_combat_result.lua")
end

local function run(resave_name)
    local O = GAME.objects_v2
    if not O then
        L("[SV2] objects_v2 未就绪, 跳过 (首代正常)")
        return -1
    end
    -- resave 通道: 显式传参 sv2_export("名") 优先; 省略时兼容旧 flag 通道
    -- (echo <存档名> > resave_req.flag)。savegame 与本次导出同帧同刻
    -- (游戏暂停时即同刻锚; 进档后自动暂停态, /health paused 确认)。
    if not resave_name then
        local rfl = io.open(MY_DIR .. "/resave_req.flag", "r")
        if rfl then
            resave_name = rfl:read("*l") or "sv2_resave"
            rfl:close()
            os.remove(MY_DIR .. "/resave_req.flag")
        end
    end
    if resave_name and resave_name ~= "" then
        hoi4.console("savegame " .. resave_name)
        -- HOI4 无 "pause" 控制台命令 (实测 bridge ok:false, 旧注释
        -- "强制暂停" 一直无效) — 暂停纪律 = 触发前确认 /health paused:true
    end
    local f, ferr = io.open(MY_DIR .. "/tmp_savefull_mem.txt", "w")
    if not f then
        L("[SV2] open out ERR: " .. tostring(ferr))
        return -1
    end
    local rp, ru32 = hoi4.read_u64, hoi4.read_u32
    local n_leaves = 0
    local function emit(dim, path, val)
        f:write(dim, "\t", path, "\t", val, "\n")
        n_leaves = n_leaves + 1
    end
    -- 国家循环 (csec): ctx.emit(path, val) -> dim=tag; 锚行 country.index
    -- §1.1 CGameState: 单例 @BASE+0x332F260; +784 (0x310) 国家指针数组;
    -- +796 (0x31C) 国家数; +856 (0x358) tag 串表; cc+8 tag_id = §4.3 CCountry
    local BASE = hoi4.base()
    local gs = rp(BASE + 0x332F260)
    local n = gs and ru32(gs + 0x31C) or 0
    local carr = gs and rp(gs + 0x310)
    if carr and n and n > 0 then
        for i = 0, n - 1 do
            local cc = rp(carr + 8 * i)
            if cc then
                local tid = ru32(cc + 8)
                local tt = rp(gs + 0x358)
                local tag = tid and tt and hoi4.read_str(tt + 32 * tid) or nil
                if tag and tag ~= "" and tag ~= "---" then
                    local cctx = {
                        f = f, O = O, i = i, tag = tag, cc = cc,
                        gs = gs, n = n, BASE = BASE,
                        emit = emit, country = O:country(i),
                    }
                    for _, sec in ipairs(SV2.csec) do
                        local ok, err = pcall(sec.emit, cctx)
                        if not ok then
                            L("[SV2] csec " .. tostring(sec.name) .. " "
                                .. tag .. " ERR: " .. tostring(err))
                        end
                    end
                end
            end
        end
    end
    -- 全局段 (gsec): ctx.emit(dim, path, val)
    local gctx = {
        f = f, O = O, gs = gs, n = n, BASE = BASE, emit = emit,
    }
    for _, sec in ipairs(SV2.gsec) do
        local ok, err = pcall(sec.emit, gctx)
        if not ok then
            L("[SV2] sec " .. tostring(sec.name) .. " ERR: " .. tostring(err))
        end
    end
    f:close()
    local done = io.open(MY_DIR .. "/tmp_savefull_done.flag", "w")
    if done then
        done:write(os.date("%Y%m%d%H%M%S") .. " n=" .. n_leaves .. "\n")
        done:close()
    end
    L("[SV2] done n=" .. n_leaves)
    return n_leaves
end

-- 外部唯一入口 (全局): HTTP /lua 或 console `lua` 显式调用。
-- 返回叶数 (成功) / 负值 (跳过) / 抛错时返回 nil,err 形态由 pcall 外包。
function sv2_export(resave_name)
    local ok, err = pcall(function()
        load_secs()                    -- 每次调用重载全部段: 磁盘新码即生效
        return run(resave_name)
    end)
    if not ok then
        L("[SV2] ERROR " .. tostring(err))
        return nil, err
    end
    return err                          -- pcall 第一个返回值 = run 的叶数
end
