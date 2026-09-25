-- sv2_sec_c_units.lua -- country.units 节点 savefull 直出 (csec)

SV2.csec[#SV2.csec + 1] = { name = "country.units", emit = function(ctx)
    local SL, emit, tag, O, i = SV2.lib, ctx.emit, ctx.tag, ctx.O, ctx.i
    if not ctx.country then return end
    local rp, ru32, ru8, kptr = SL.rp, SL.ru32, SL.ru8, SL.kptr
    local BASE = ctx.BASE

    -- 引号串 (转义 \ 与 "; 空串不写)
    local function QE(s)
        if s and s ~= "" and s ~= "nil" then
            return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
        end
        return nil
    end
    -- 数值/数值串 -> writer 形 (整值去尾零; "%.5f" 串先 tonumber)
    local function NF(v)
        local n = tonumber(v)
        if n then return SL.num(n) end
        return nil
    end
    -- 空格串 -> 逐元素列表
    local function words(s)
        local out = {}
        if s then for w in tostring(s):gmatch("%S+") do out[#out + 1] = w end end
        return out
    end
    -- CGameDate 总小时 -> "Y.M.D.H" (B 族: 43808760 照发 "1.1.1.1")
    local date_raw = SL.date_raw
    -- §4.18.1 CUnitHistoryEntry +104 = medal 定义对象指针: 写门
    -- ptr≠0 且 ru8(def+16)≠0; 名串 MSVC @def+24 (size@+40); 师普通队列 /
    -- medal store 条目 / ship history 条目 (同类) 通用
    local function medal_name_of(e)
        local mdp = rp(e + 104)
        if kptr(mdp) and (ru8(mdp + 16) or 0) ~= 0 then
            local mdn = SL.sso(mdp + 24)
            if mdn and #mdn > 0 then return mdn end
        end
        return nil
    end

    -- §4.18.1 CUnitHistoryEntry / §4.16.13 CSunkShipInfo
    -- 师/船 history_queue 公共发射 (字段同构; dpfx 已含外层块路径)
    -- opts.entries = 条目地址数组 (船 history location 内联读用, 对齐
    -- reader kptr 过滤序); opts.empty_fallback = 船 history 实证规则
    -- army_names 空写 ""/target_country 无写 "---" (JAP fleet[7] 7+7 行)
    local function emit_div_history(dpfx, ah, opts)
        local hseq = SL.seqc()
        for hi, hr in ipairs(ah.list or {}) do
            if hi > 4096 then break end
            local hk = dpfx .. hseq("history_queue")
            local v = QE(hr.army_names)
            if v then emit(tag, hk .. ".army_names", v)
            elseif opts and opts.empty_fallback then
                emit(tag, hk .. ".army_names", '""') end
            v = QE(hr.target_country)
            if v then emit(tag, hk .. ".target_country", v)
            elseif opts and opts.empty_fallback then
                emit(tag, hk .. ".target_country", '"---"') end
            -- location: save 恒单行拼接 .location.#1
            -- ('location.#1 = 6598 11548'; 逐元素 #N 系单省巧合)
            local ea = opts and opts.entries and opts.entries[hi]
            local locs = {}
            if ea then                    -- 内联读 (容器 @ea+0x120/0x128,
                local ld, lc = rp(ea + 0x120), ru32(ea + 0x128) -- 省 id@ptr+164)
                if kptr(ld) and lc and lc > 0 and lc < GAME.layout.lim.PTR_SANE then
                    for j = 0, lc - 1 do
                        local lp = rp(ld + 8 * j)
                        local lid = kptr(lp) and ru32(lp + 164) or nil
                        if lid then locs[#locs + 1] = NF(lid) end
                    end
                end
            elseif hr.locations then      -- reader 记录链已带 (uhist_recs)
                for _, lid in ipairs(hr.locations) do
                    locs[#locs + 1] = NF(lid) end
            else
                for _, lid in ipairs(words(hr.location)) do
                    locs[#locs + 1] = lid end
            end
            if #locs > 0 then
                emit(tag, hk .. ".location.#1", table.concat(locs, " ")) end
            if ea then                    -- 条目内联叶族 (ship 路径, 5c 迁移):
                local mdn = medal_name_of(ea)   -- +104 medal 定义指针
                if mdn then emit(tag, hk .. ".unit_medals", QE(mdn)) end
                -- multiplier i64@+312 ≠100000(=1.0) 才写; orders u32@+320 ≠0
                local mu = rp(ea + 312)
                if mu and mu ~= 100000 then
                    emit(tag, hk .. ".multiplier", NF(mu * 1e-5)) end
                local od = ru32(ea + 320)
                if od and od ~= 0 then emit(tag, hk .. ".orders", NF(od)) end
                -- custom_lockey MSVC @+40 (size@+56), 门 unique(@+72)==16
                -- (SWE 全师 unique=16 → "SWE_winter_drill_entry")
                if ru32(ea + 72) == 16 then
                    local csz = ru32(ea + 56)
                    if csz and csz > 0 and csz < 4096 then
                        local cbuf = (csz > 15) and rp(ea + 40) or (ea + 40)
                        if kptr(cbuf) then
                            emit(tag, hk .. ".custom_lockey",
                                QE(hoi4.read_cstr(cbuf)))
                        end
                    end
                end
            else                          -- rec 兜底 (uhist_recs 全字段, 序同内联)
                if hr.medal then
                    emit(tag, hk .. ".unit_medals", QE(hr.medal)) end
                if hr.multiplier then
                    emit(tag, hk .. ".multiplier", NF(hr.multiplier)) end
                if hr.orders then emit(tag, hk .. ".orders", NF(hr.orders)) end
                if hr.custom_lockey then
                    emit(tag, hk .. ".custom_lockey", QE(hr.custom_lockey)) end
            end
            v = QE(hr.date) if v then emit(tag, hk .. ".date", v) end
            if hr.unique ~= nil then emit(tag, hk .. ".unique", NF(hr.unique)) end
            if hr.medal_count then emit(tag, hk .. ".medal_count", hr.medal_count) end
            if hr.inherit then emit(tag, hk .. ".inherit", hr.inherit) end
            local su = hr.sunk           -- §4.16.13 CSunkShipInfo 内嵌@entry+120
            if su then
                local sp = hk .. ".sunk_ship"
                -- name 空串也写 (与 killer_name 同 writer 门; 块内恒有,
                -- ENG fleet[4] tf[5] ship[3] hq[13] 空名实证); 条目地址
                -- 可用时内联读 raw MSVC @entry+128 (=CSunkShipInfo+8)
                local nm3 = ea and SL.sso(ea + 128) or nil
                if nm3 == nil then nm3 = su.name end
                if nm3 ~= nil then
                    emit(tag, sp .. ".name", QE(nm3) or '""') end
                -- killer_name 空串也写 (save 98/98 sunk_ship 块全带
                -- killer_name, SDL 空串 17 叶 MISS; reader 滤空 → 条目地址
                -- 可用时内联读 raw MSVC @entry+160, 否则 rec 非空兜底)
                local kn = ea and SL.sso(ea + 160) or nil
                if kn == nil then kn = su.killer_name end
                if kn ~= nil then
                    emit(tag, sp .. ".killer_name", QE(kn) or '""') end
                v = QE(su.country) if v then emit(tag, sp .. ".country", v) end
                v = QE(su.killer_country) if v then emit(tag, sp .. ".killer_country", v) end
                if su.level then emit(tag, sp .. ".level", NF(su.level)) end
                if su.definition then emit(tag, sp .. ".definition", su.definition) end
                if su.killer_definition then
                    emit(tag, sp .. ".killer_definition", su.killer_definition) end
                if su.location then emit(tag, sp .. ".location", NF(su.location)) end
                v = QE(su.date) if v then emit(tag, sp .. ".date", v) end
                if su.assist then emit(tag, sp .. ".assist", "yes") end
                if su.eq_variant then emit(tag, sp .. ".equipment_variant", su.eq_variant) end
                -- air_wing "id=0 type=0" = save 缺行 (定案) → 抑制
                if su.air_wing and su.air_wing ~= "id=0 type=0" then
                    emit(tag, sp .. ".air_wing", su.air_wing) end
                if su.battle then emit(tag, sp .. ".battle", su.battle) end
                if su.convoy then emit(tag, sp .. ".convoy", su.convoy) end
            end
        end
    end

    -- §4.18.3 requests 全族 (reader DivMT.requests 返回 {date, reinforcement={k,v}...,
    -- upgrades={k,v}...}; 键 "manpower_pool.N" / "request.N.*" / "delivery.N.*",
    -- 存档 [N] 编号 = 数组序 首现不编号)
    local function emit_requests(dpfx, dv)
        local okr, rq = pcall(function() return dv.requests end)
        if not (okr and rq) then return end
        local pfx = dpfx .. "requests."
        if rq.date then emit(tag, pfx .. "date", QE(rq.date)) end
        local mpseq = SL.seqc()
        local function rows(arr, grp)
            for _, kv in ipairs(arr or {}) do
                local k, v = kv[1], kv[2]
                if v ~= nil then
                    if k:match("^manpower_pool%.%d+$") then
                        -- 值已成型 '"TAG" N'; 同键重复叶 = 多重集不编号
                        -- (双存档 "AUS"/"HUN" 两条均裸键)
                        emit(tag, pfx .. grp .. "manpower_pool", v)
                    else
                        local rn, rest = k:match("^request%.(%d+)%.(.+)$")
                        local dn, drest = k:match("^delivery%.(%d+)%.(.+)$")
                        local p2
                        if rn then
                            p2 = (rn == "1") and "request." or ("request[" .. rn .. "].")
                        elseif dn then
                            p2 = (dn == "1") and "delivery." or ("delivery[" .. dn .. "].")
                            rest = drest
                        end
                        if p2 then
                            rest = rest:gsub("^produced%.equipment%.(%d+)%.",
                                function(e)
                                    return (e == "1") and "produced.equipment."
                                        or ("produced.equipment[" .. e .. "].")
                                end)
                            if rest == "date" or rest:sub(-5) == ".date" then
                                v = QE(v)
                            elseif rest:find("allow_zero_entries") then -- yes/no 原样
                            elseif rest:sub(-3) == ".id"
                                or rest:find("equipment_variant_index") then -- idpair 原样
                            elseif rest == "status" then -- 整数串原样
                            else v = NF(v) end
                            if v then emit(tag, pfx .. grp .. p2 .. rest, v) end
                        end
                    end
                end
            end
        end
        rows(rq.reinforcement, "reinforcement.")
        rows(rq.upgrades, "upgrades.")
    end

    -- ================= division =================
    -- §4.18.1 CArmy (师对象; 含 country_intel/commandlist 内联 = §4.18.5
    -- CUnit 公共段)
    local okd, rd = pcall(O.divisions, O, i)
    if okd and rd and rd.list then
        local dseq = SL.seqc()
        for di, dv in ipairs(rd.list) do
            if di > 2000 then break end
            local dpfx = "units." .. dseq("division") .. "."
            local function D(path, val)
                if val ~= nil then emit(tag, dpfx .. path, val) end
            end
            local v
            D("id", SL.idpair(dv.id, dv.type))      -- CUnit 层 id (第 1 次)
            v = QE(dv.last_combat_date) D("last_combat_date", v)
            D("movement_progress", NF(dv.movement_progress))
            local mpr = dv.move_priority_raw        -- 写门: raw@a+584 ~= 1
            if mpr and mpr ~= 1 then D("move_priority", dv.move_priority) end
            D("location", NF(dv.location))
            D("logical_country", QE(dv.logical_country))
            -- §4.18.5 CUnit 公共段 country_intel (12009): 单行 .#1 全元素
            -- 拼接 (reader dv.country_intel 平铺 3 值/元)
            do
                local ci = dv.country_intel
                if ci and #ci >= 3 then
                    local parts = {}
                    for k = 1, #ci, 3 do
                        parts[#parts + 1] = string.format("%d %d %d",
                            ci[k], ci[k + 1], ci[k + 2])
                    end
                    D("country_intel.#1", table.concat(parts, " "))
                end
            end
            D("seed", NF(dv.seed))
            D("id", SL.idpair(dv.id, dv.type))      -- CDivision 层 id (第 2 次)
            D("motorization_level", NF(dv.motorization_level))
            -- §4.18.1 CArmy officer 全记录链 (CHeldOfficer @raw+1272; 布局/写门见
            -- objects_v2 officer_records 注): writer 块序 inline 记录先/
            -- 追加向量元素后, 键序 seed/name/portraits/male; seed=0 空
            -- 记录与 male 照写, name 非空才写, portraits 容器非空才写
            do
                local oseq = SL.seqc()
                for _, of in ipairs(dv.officer_list or {}) do
                    local ok = oseq("officer")
                    D(ok .. ".seed", NF(of.seed))
                    D(ok .. ".name", QE(of.name))
                    local pseq2 = SL.seqc()
                    for _, po in ipairs(of.portraits or {}) do
                        D(ok .. ".portraits." .. pseq2(po.branch)
                            .. "." .. po.size, QE(po.path))
                    end
                    D(ok .. ".male", of.male)
                end
            end
            local tid = dv.template_id              -- idpair type 恒 52 (实证)
            if tid then D("division_template_id", SL.idpair(tid, 52)) end
            local otid = dv.old_template_id
            if otid then D("old_division_template_id", SL.idpair(otid, 52)) end
            local ftid = dv.fake_intel_template_id
            if ftid then D("fake_intel_template_id", SL.idpair(ftid, 52)) end
            local dn = dv.division_name             -- §4.18.1 CArmy 名持有对象
            if dn then                              -- 内嵌@a+832 (writer 0x1409BCC70)
                D("division_name.type", NF(dn.type))
                D("division_name.name_order", NF(dn.name_order))
                -- is_name_ordered: 反值门仅假写 no (reader 已带 @+168==0)
                if dn.is_name_ordered_no then
                    D("division_name.is_name_ordered", "no") end
                D("division_name.override", QE(dn.override))
                if dn.override_set_programmatically then
                    D("division_name.override_set_programmatically", "yes") end
            end
            D("max_supply", NF(dv.max_supply))
            D("organisation", NF(dv.organisation))
            D("strength", NF(dv.strength))
            -- §4.18.1 CArmy 装备池 内嵌@a+840 (产池同布局); 条目写门 amount~=0 或 az;
            -- idpair type 恒 70 (全量实证)
            local az = dv.equip_allow_zero == true
            local eseq = SL.seqc()
            for ei, eq in ipairs(dv.equipment or {}) do
                if ei > 4096 then break end  -- 40 截断被单师 111 条击穿
                if eq.variant_id and ((eq.amount or 0) ~= 0 or az) then
                    local ek = eseq("equipment.equipment")
                    D(ek .. ".id", SL.idpair(eq.variant_id, 70))
                    D(ek .. ".amount", NF(eq.amount))
                end
            end
            D("equipment.allow_zero_entries", SL.yn(az))
            D("script_id", NF(dv.script_id))
            -- §4.18.1 CArmy army_manpower 双容器 @a+984/a+1016; 值 tag="X" value=N;
            -- 重复 value 键**不编号** (BEL div[14]/[15] 实证: 存档双行
            -- army_manpower_value.value 无 [2], seqc 编号 = MISS 双侧)
            for _, mm in ipairs(dv.manpower_value or {}) do
                local tg, vl = mm:match("^(.-)|(.+)$")
                if tg then
                    D("army_manpower.army_manpower_value.value",
                        string.format('tag="%s" value=%s', tg, vl)) end
            end
            for _, mm in ipairs(dv.manpower_need or {}) do
                local tg, vl = mm:match("^(.-)|(.+)$")
                if tg then
                    D("army_manpower.army_manpower_need.value",
                        string.format('tag="%s" value=%s', tg, vl)) end
            end
            D("experience", NF(dv.experience))
            D("dig_in", NF(dv.dig_in))
            D("dig_in_cap", NF(dv.dig_in_cap))
            local ac = dv.acclimatization           -- §4.18.1 CArmy 内嵌@a+1208 (writer 0x140609C70)
            if ac then
                local ack = { "cold_climate", "hot_climate", "actively_gaining",
                    "actively_gaining_speed", "other_loss", "max_acclimatization" }
                local seen = {}
                for _, kk in ipairs(ack) do
                    seen[kk] = true
                    local vv = ac[kk]
                    if vv ~= nil then
                        if type(vv) == "number" then
                            D("acclimatization." .. kk, NF(vv))
                        else
                            D("acclimatization." .. kk, QE(vv))
                        end
                    end
                end
                for kk, vv in pairs(ac) do          -- 其他气候 token 兜底
                    if not seen[kk] and vv ~= nil then
                        if type(vv) == "number" then
                            D("acclimatization." .. kk, NF(vv))
                        else
                            D("acclimatization." .. kk, QE(tostring(vv)))
                        end
                    end
                end
            end
            D("army_current_supply_ratio", NF(dv.current_supply_ratio))
            -- §4.18.5 CUnit 公共段 commandlist (布局/写门 = 书 §4.18.5;
            -- reader dv.commandlist_actions 已按 token 分派)
            do
                local acts = dv.commandlist_actions
                if acts and #acts > 0 then
                    local clseq = SL.seqc()
                    for _, act in ipairs(acts) do
                        if act.kind == 13896 then
                            -- §4.33.15 CUnitMoveAction (96B, writer
                            -- 0x141220FC0): unit 恒写; province/path 列表
                            -- 单行拼接 (>0 才写); 5 bool 仅真写 yes;
                            -- move_priority 枚举 raw ~= 1 才写
                            local bp = clseq("commandlist.unit_move_action")
                                .. "."
                            D(bp .. "unit",
                                SL.idpair(act.unit_id, act.unit_type))
                            if act.provinces then
                                local pp1 = {}
                                for _, pv in ipairs(act.provinces) do
                                    pp1[#pp1 + 1] = tostring(pv) end
                                D(bp .. "province.#1",
                                    table.concat(pp1, " "))
                            end
                            if act.path then
                                local pp2 = {}
                                for _, pv in ipairs(act.path) do
                                    pp2[#pp2 + 1] = tostring(pv) end
                                D(bp .. "path.#1", table.concat(pp2, " "))
                            end
                            if act.clear then D(bp .. "clear", "yes") end
                            if act.safe then D(bp .. "safe", "yes") end
                            if act.safe_fallback then
                                D(bp .. "safe_with_nonsafe_fallback", "yes") end
                            if act.safe_end then
                                D(bp .. "safe_until_very_end", "yes") end
                            if act.avoid then D(bp .. "avoid", "yes") end
                            local mpa = act.move_priority_raw
                            if mpa and mpa ~= 1 then
                                D(bp .. "move_priority",
                                    ({ [0] = "front_order",
                                        [2] = "player_order",
                                        [3] = "ai_player_order" })[mpa]
                                    or "normal")
                            end
                            if act.sticky then D(bp .. "sticky", "yes") end
                        elseif act.kind == 13897 then
                            -- §4.33.15 CUnitNavalMoveAction (40B, writer
                            -- 0x1412210D0): unit/location/province 恒写;
                            -- is_amphibious_invasion 仅真写 yes
                            local bp = clseq(
                                "commandlist.unit_naval_move_action") .. "."
                            D(bp .. "unit",
                                SL.idpair(act.unit_id, act.unit_type))
                            D(bp .. "location", NF(act.location))
                            D(bp .. "province", NF(act.province))
                            if act.amphibious then
                                D(bp .. "is_amphibious_invasion", "yes") end
                        end
                    end
                end
            end
            D("supply_gain", NF(dv.supply_gain))
            D("bonus", NF(dv.bonus))
            -- disrupted_supply: i64@raw+176 ×1e-5, 门 ≠0 (reader 出原值)
            do
                local ds = dv.disrupted_supply_raw
                if ds and ds ~= 0 then D("disrupted_supply", NF(ds * 1e-5)) end
            end
            D("str_damage", NF(dv.str_damage))
            D("org_damage", NF(dv.org_damage))
            D("str_damage_from_air", NF(dv.str_damage_from_air))
            -- killed/killer_definition 同门 (killed@a+1656 >0)
            if dv.killed then
                D("killed", NF(dv.killed))
                D("killer_definition", dv.killer_definition)
            end
            D("fuel", NF(dv.fuel))
            D("fuel_requested", NF(dv.fuel_requested))
            D("held_officer.experience", NF(dv.held_officer_xp))
            if dv.leader then D("leader", "yes") end
            -- 列表单行形态 (对拍定案): path/full_path 全元素空格拼接进
            -- 单条 .#1 行 (save 'path.#1 = 9835 6837 ...'; 逐元素 #N =
            -- 971+ MISS_SAVE 幻影 + 166 条 #1 DIFF)
            local pl = dv.path
            if pl and #pl > 0 then
                local parts = {}
                for _, pv in ipairs(pl) do parts[#parts + 1] = NF(pv) end
                D("path.#1", table.concat(parts, " "))
            end
            pl = dv.full_path
            if pl and #pl > 0 then
                local parts = {}
                for _, pv in ipairs(pl) do parts[#parts + 1] = NF(pv) end
                D("full_path.#1", table.concat(parts, " "))
            end
            emit_requests(dpfx, dv)
            local ah = dv.army_history              -- §4.18.1 CArmy 内嵌@a+1592
            if ah and ah.list and #ah.list > 0 then
                -- 师史同船史: army_names 空串照写 "" (ITA/APG 等 10 叶实证);
                -- 记录链 reader 已带全字段 (uhist_recs), 无需条目地址
                emit_div_history(dpfx .. "army_history.army_history.", ah,
                    { empty_fallback = true })
            end
            -- §4.18.1 army_history.unit_medals: reader dv.medal_store
            -- (scoped ptr → CUnitMedalStore; 布局/写门/三枚 CModifier
            -- 不落盘 = 书 §4.18.1)。
            do
                local ms = dv.medal_store
                if ms then
                    if #ms.list > 0 then
                        emit_div_history(
                            dpfx .. "army_history.unit_medals.history.",
                            { list = ms.list }, { empty_fallback = true })
                    end
                    if ms.amount then
                        D("army_history.unit_medals.amount", NF(ms.amount)) end
                end
            end
            local ri = dv.raid_instance
            if ri then D("raid_instance", SL.idpair(ri.id, ri.type)) end
            D("retreat", dv.retreat)                -- 以下标志族仅真写 yes
            D("withdraw", dv.withdraw)
            D("exile", dv.exile)
            D("move_capital", dv.move_capital)
            D("strategic_redeployment", dv.strategic_redeployment)
            D("disengage", NF(dv.disengage))        -- >0 门 (legacy 定案)
            D("possible_retreat", NF(dv.possible_retreat))
            D("was_paradropped", NF(dv.was_paradropped))
            D("execute_order", NF(dv.execute_order))
            D("unit_controller_pause", NF(dv.unit_controller_pause))
            D("out_of_supply_days", NF(dv.out_of_supply_days))
            D("support_attack", NF(dv.support_attack))
            -- §4.18.5 CUnit 公共段 previous (+504 / 键 0x29A3, kptr 门): 旧注"writer
            -- 不写"是错的 — writer 0x140BF7010 有 [rdi+1E8h]→ADEC0(0x29A3)
            -- 通道, 存档实证 previous=659
            D("previous", NF(dv.previous))
            D("transfer_offset_1", NF(dv.transfer_offset_1))
            D("transfer_offset_2", NF(dv.transfer_offset_2))
            v = QE(dv.start_date) D("start_date", v) -- 写入门 h-43800000>=17520
            v = QE(dv.end_date) D("end_date", v)
            D("expeditionary_owner", QE(dv.expeditionary_owner)) -- 门 tid@a+476>0
        end
    end

    -- ================= railway_gun =================
    -- §4.18.2 CRailwayGun — 结构唯一实现 = Country:railway_guns
    -- (objects_military §6.9); 本段只按写序/块键/编号/格式发射。
    do
        local okc, cr = pcall(O.country, O, i)
        local okr, rgs = pcall(function()
            return cr and cr:railway_guns() end)
        if okr and rgs then
            local rgseq = SL.seqc()
            for _, rg in ipairs(rgs) do
                local gpfx = "units." .. rgseq("railway_gun") .. "."
                local function G(path, val)
                    if val ~= nil then emit(tag, gpfx .. path, val) end
                end
                -- 0x2FE3 definition: scoped ptr → token (SL.tok 无名落数值)
                if rg.definition_tok ~= nil then
                    G("definition", SL.tok(rg.definition_tok)) end
                -- 0x2F4E equipment: B240 idpair {type@+824, id@+828}
                G("equipment", SL.idpair(rg.eq_id, rg.eq_type))
                -- 0x341D railway_gun_name 内嵌对象 (serialize 0x1409BCC70)
                G("railway_gun_name.type", NF(rg.name_type))
                if rg.name_order then
                    G("railway_gun_name.name_order", NF(rg.name_order)) end
                if rg.name_ordered_no then
                    G("railway_gun_name.is_name_ordered", "no") end
                if rg.override_gate then
                    local ov = QE(rg.override)
                    if ov then G("railway_gun_name.override", ov) end
                end
                if rg.osp then
                    G("railway_gun_name.override_set_programmatically",
                        "yes") end
                if rg.name_eq then
                    G("railway_gun_name.equipment",
                        SL.idpair(rg.name_eq.id, rg.name_eq.type)) end
                -- 0x28A6/0x283C/0x3A43/0x4CED/0x4CEC (全无条件; fixed5/u32)
                G("strength", NF(rg.strength))
                G("manpower", NF(rg.manpower))
                G("max_supply", NF(rg.max_supply))
                G("army_current_supply_ratio", NF(rg.supply_ratio))
                G("supply_gain", NF(rg.supply_gain))
                -- 0x4C5C repair_line idpair 双 dword 门
                if rg.repair_line then
                    G("repair_line", SL.idpair(rg.repair_line.id,
                        rg.repair_line.type)) end
                -- 0x2916 combat: 命名块逐元素 .#N (1 起恒编号)
                if rg.combat then
                    for cj, ce in ipairs(rg.combat) do
                        G("combat.#" .. cj, SL.idpair(ce.id, ce.type))
                    end
                end
                -- 0x289D army: qword {id=高32, type=低32}
                if rg.army then
                    G("army", SL.idpair(rg.army.id, rg.army.type)) end
                -- ===== §4.18.5 CUnit 公共段 (writer 0x140BF7010) =====
                G("id", SL.idpair(rg.id_id, rg.id_type))
                G("name", QE(rg.name))
                G("previous", NF(rg.previous))
                G("experience", NF(rg.experience))
                -- 0x2FDF: 门 ≠0 (哨兵 0x29C3388 也写 "1.1.1.1")
                if rg.last_combat_h then
                    G("last_combat_date", QE(rg.last_combat_h == 0x29C3388
                        and "1.1.1.1" or SL.date_raw(rg.last_combat_h))) end
                -- 0x28A4 movement_progress (token 勘误): i64 门 ≠0
                if rg.movement_progress then
                    G("movement_progress", NF(rg.movement_progress)) end
                local mpr = rg.move_priority_raw      -- 14268, ~=1 才写
                if mpr and mpr ~= 1 then
                    G("move_priority", ({ [0] = "front_order",
                        [2] = "player_order",
                        [3] = "ai_player_order" })[mpr] or "normal") end
                -- path/full_path 单行 .#1 拼接 (u32 密集元)
                if rg.path and #rg.path > 0 then
                    local parts = {}
                    for _, pv in ipairs(rg.path) do
                        parts[#parts + 1] = NF(pv) end
                    G("path.#1", table.concat(parts, " ")) end
                if rg.full_path and #rg.full_path > 0 then
                    local parts = {}
                    for _, pv in ipairs(rg.full_path) do
                        parts[#parts + 1] = NF(pv) end
                    G("full_path.#1", table.concat(parts, " ")) end
                G("location", NF(rg.location))
                if rg.retreat then G("retreat", "yes") end
                if rg.withdraw then G("withdraw", "yes") end
                -- 0x28E0/0x28E1: 门 h-43800000>=17520 (reader 已门)
                if rg.start_h then
                    G("start_date", QE(SL.date_raw(rg.start_h))) end
                if rg.end_h then
                    G("end_date", QE(SL.date_raw(rg.end_h))) end
                -- 0x2EE2/0x2EE5 is_buildable 族: 门 u32@304 >0 (双发)
                if rg.is_buildable then
                    G("is_buildable", NF(rg.is_buildable))
                    G("unused_token_11941", NF(rg.unused_token)) end
                G("expeditionary_owner", QE(rg.expeditionary_owner))
                G("logical_country", QE(rg.logical_country))
                G("alliance_strength_ratio", NF(rg.alliance))
                G("clear_queued_actions", NF(rg.clear_queued))
                if rg.exile then G("exile", "yes") end
                if rg.move_capital then G("move_capital", "yes") end
                G("seed", NF(rg.seed))
                if rg.raid then
                    G("raid_instance", SL.idpair(rg.raid.id, rg.raid.type)) end
                if rg.intel then
                    local parts = {}
                    for _, it in ipairs(rg.intel) do
                        parts[#parts + 1] = string.format("%d %d %d",
                            it[1], it[2], it[3])
                    end
                    G("country_intel.#1", table.concat(parts, " "))
                end
            end
        end
    end

    -- ================= fleet (三层) =================
    -- §4.16.4 CFleet / §4.16.2 CTaskForce / §4.16.3 CShip
    local okf, rf = pcall(O.fleet, O, i)
    if okf and rf and rf.fleets then
        local fseq = SL.seqc()
        for _, fl in ipairs(rf.fleets) do
            local fpfx = "units." .. fseq("fleet") .. "."
            local function F(path, val)
                if val ~= nil then emit(tag, fpfx .. path, val) end
            end
            local v
            F("id", SL.idpair(fl.fleet_id, fl.fleet_type)) -- CFleet id 对@+8
            -- §4.16.4 CFleet name (§3.5 MSVC 串, cap>15 → 堆 buf;
            -- 布局 = 书 §4.16.4)。⚠ reader U.cstr 对裸堆缓冲误读
            -- ('Kriegsmarine' → 垃圾) → 段内按 size 逐字节原样读
            do
                local fa = fl._addr
                local nsz = fa and ru32(fa + 240)
                if nsz and nsz > 0 and nsz < 4096 then
                    local ncap = rp(fa + 248)
                    local nbuf = (ncap and ncap > 15) and rp(fa + 224)
                        or (fa + 224)
                    if kptr(nbuf) then
                        -- 定长缓冲按长度整取 (read_bytes): 逐字节 ru8 + string.char
                        -- + table.concat 三步在本导出实测 ~29x 慢, 且内嵌 NUL 会
                        -- 被 read_cstr 提前截断。
                        F("name", QE(hoi4.read_bytes(nbuf, nsz) or ""))
                    end
                end
            end
            F("color", fl.color)                    -- "R G B" 预成型
            F("icon", NF(fl.fleet_icon))
            F("leader", fl.leader)                  -- idpair 预成型
            -- strategic_region 单行拼接 (同 path; save 'strategic_region.#1 =
            -- 94 95')
            local srl = fl.strategic_regions
            if srl and #srl > 0 then
                F("strategic_region.#1", table.concat(srl, " ")) end
            F("tick_to_check_naval_invasion_support", NF(fl.tick_nis))
            -- bombardment_region = 书 §4.16.4 (容器序发射, 非 id 升序 — 勿排序)
            do
                local bl = fl.bombardment or {}
                if #bl > 0 then
                    local b0, vs = nil, {}
                    for _, br in ipairs(bl) do
                        if br.region and br.region ~= -1 then
                            if not b0 then
                                b0 = tostring(br.region)
                                vs[#vs + 1] = NF(br.value)
                            else
                                vs[#vs + 1] = tostring(br.region)
                                    .. "=" .. NF(br.value)
                            end
                        end
                    end
                    if b0 then
                        F("bombardment_region." .. b0,
                            table.concat(vs, " "))
                    end
                end
            end
            -- hours_without_patrol_missions_pairs = 书 §4.16.4 (RH 表, 段内
            -- 内联; 多 region 折单行 = 提取器契约)
            do
                local fa = fl._addr
                if fa then
                    local hd = rp(fa + 48)
                    local hmask = ru32(fa + 60) or 0
                    local hmaxp = ru8(fa + 64) or 0
                    if kptr(hd) and hmask > 0 and hmask < GAME.layout.lim.PTR_SANE then
                        local endp = hd + 24 * (hmask + hmaxp + 1)
                        local he, guard = hd, 0
                        local hw = {}
                        while he < endp and guard < 4096 do
                            guard = guard + 1
                            local dist = ru8(he + 4) or 0
                            if dist ~= 0 and dist ~= 0xFE then -- 空桶+墓碑过滤
                                local op = rp(he + 8)
                                local reg = kptr(op) and ru32(op + 88) or nil
                                if reg then
                                    hw[#hw + 1] = { reg, ru32(he + 16) or 0 } end
                            end
                            he = he + 24
                        end
                        -- differ 实证: 写序 = region id 升序 (JAP fleet[9]
                        -- save .76 键 vs RH 桶序 .90 键)
                        table.sort(hw, function(a, b) return a[1] < b[1] end)
                        if #hw > 0 then
                            local vs = tostring(hw[1][2])
                            for k2 = 2, #hw do
                                vs = vs .. " " .. hw[k2][1] .. "=" .. hw[k2][2]
                            end
                            F("hours_without_patrol_missions_pairs."
                                .. hw[1][1], vs)
                        end
                    end
                end
            end
            local tfseq = SL.seqc()
            for _, tf in ipairs(fl.task_forces or {}) do
                local tpfx = fpfx .. tfseq("task_force") .. "."
                local function T(path, val)
                    if val ~= nil then emit(tag, tpfx .. path, val) end
                end
                T("id", SL.idpair(tf.id, tf.type))  -- CTaskForce id 对 (+28/+24)
                T("name", QE(tf.name))
                T("last_combat_date", QE(tf.last_combat_date))
                T("movement_progress", NF(tf.movement_progress))
                T("move_priority", tf.move_priority) -- reader 已含 raw~=1 门
                T("location", NF(tf.location))
                T("logical_country", QE(tf.logical_country))
                T("fuel", NF(tf.fuel))
                T("requested", NF(tf.requested))
                -- previous (CUnit 公共 writer 0x140BF7010 / 键 0x29A3, kptr 门)
                T("previous", NF(tf.previous))
                T("path.#1", tf.path)               -- reader 已拼接单行
                -- §4.16.2 CTaskForce mission (CNavalMission 内嵌@tf+864; writer 0x140FA9900)
                local ms = tf.mission
                if ms then
                    T("mission.mission", NF(ms.mission))
                    T("mission.move", NF(ms.move))
                    if ms.is_in_regions then T("mission.is_in_regions", "yes") end
                    T("mission.radar", NF(ms.radar))
                    T("mission.air_superiority", NF(ms.air_superiority))
                    T("mission.hours", NF(ms.hours))
                    T("mission.hours_in_mission", NF(ms.hours_in_mission))
                    T("mission.num_convoys_in_regions", NF(ms.num_convoys_in_regions))
                    T("mission.navy_engagement_rule", NF(ms.navy_engagement_rule))
                    T("mission.spotting_region", NF(ms.spotting_region))
                    T("mission.convoy_spotting_region",
                        NF(ms.convoy_spotting_region))
                    T("mission.hours_in_spotting_region",
                        NF(ms.hours_in_spotting_region))
                    if ms.stop_training_at_max_xp then
                        T("mission.stop_training_at_max_xp", "yes") end
                    T("mission.accessible_regions_range",
                        NF(ms.accessible_regions_range))
                    -- 单行拼接 (save 'accessible_regions.#1 = 94 95')
                    if ms.accessible_regions then
                        T("mission.accessible_regions.#1",
                            ms.accessible_regions) end
                    if ms.accessible_regions_in_fleet then
                        T("mission.accessible_regions_in_fleet.#1",
                            ms.accessible_regions_in_fleet) end
                    if ms.gte_orders_group then
                        T("mission.group_to_escort.orders_group",
                            ms.gte_orders_group) end
                    T("mission.group_to_escort.instance_id", NF(ms.gte_instance_id))
                    -- spotting 族 = 书 §4.16.12 A6 表 (ms = tf+864 内嵌)
                    local msa = tf._addr
                    if msa then
                        local m0 = msa + 864
                        -- already_spotted (writer 0x140FA9900
                        -- AE850(0x3BB3, u8@+104) 非零才写 yes; 表
                        -- token 15283; ENG fl5 tf6 +968=1 实证)
                        if (ru8(m0 + 104) or 0) ~= 0 then
                            T("mission.already_spotted", "yes") end
                        local ssp = rp(m0 + 120) or 0
                        if ssp ~= 0 then
                            T("mission.spotting_speed", NF(ssp * 1e-5)) end
                        local spr = rp(m0 + 128) or 0
                        if spr ~= 0 then
                            T("mission.spotting_process", NF(spr * 1e-5)) end
                        for _, ip in ipairs({
                            { 136, "spotting_target" },
                            { 144, "spotting_convoy_client" },
                            { 152, "spotting_unit_transfer" },
                            { 160, "strike_force_target" } }) do
                            local t0, i0 = ru32(m0 + ip[1]), ru32(m0 + ip[1] + 4)
                            if (t0 and t0 ~= 0) or (i0 and i0 ~= 0) then
                                T("mission." .. ip[2], SL.idpair(i0, t0)) end
                        end
                        -- §4.16.2 mission.bombardment_region: writer
                        -- 0x140FA9900 尾段 key 0x3C7B, region ptr
                        -- @mission+96 → id@ptr+88, 门 ptr≠0 (USA
                        -- fleet[6] tf[6] = 75 ↔ save=75 实证)
                        local mbp = rp(m0 + 96)
                        if kptr(mbp) then
                            T("mission.bombardment_region",
                                NF(ru32(mbp + 88) or 0)) end
                    end
                end
                T("repair_mode", NF(tf.repair_mode))
                T("sortie_efficiency", NF(tf.sortie_efficiency))
                if tf.underway_replenishment ~= nil then
                    T("underway_replenishment", SL.yn(tf.underway_replenishment)) end
                if tf.auto_reinforcement == 1 then     -- 仅真写 (137/185 实证)
                    T("auto_reinforcement", "yes") end
                if tf.use_fleet_color then T("use_fleet_color", tf.use_fleet_color) end
                T("icon", NF(tf.icon))
                -- TF country_intel {d@+0x278, c@+0x284} 24B 元素
                -- {u32@0, u32@8, u8@16}; 多元素单行全 token (objects_v2 未收,
                -- 段内内联; 证据 ev2_secA L1266-L1284 = legacy)
                do
                    local tfa = tf._addr
                    if tfa then
                        local cib = rp(tfa + 0x278)
                        local cic = ru32(tfa + 0x284) or 0
                        if kptr(cib) and cic > 0 and cic < GAME.layout.lim.PTR_SANE then
                            local parts = {}
                            for k = 0, cic - 1 do
                                local e = cib + 24 * k
                                parts[#parts + 1] = string.format("%d %d %d",
                                    ru32(e) or 0, ru32(e + 8) or 0,
                                    ru8(e + 16) or 0)
                            end
                            T("country_intel.#1", table.concat(parts, " "))
                        end
                    end
                end
                -- ai_taskforce_composition 内嵌@tf+1328 (单 #1 行拼接)
                local aic = tf.ai_comp
                if aic then
                    for _, grp in ipairs({ "requirements", "fulfillment" }) do
                        for _, fld in ipairs({ "sub_units", "roles", "amount" }) do
                            local av = aic[grp .. "." .. fld]
                            if av then
                                T("ai_taskforce_composition." .. grp .. "."
                                    .. fld .. ".#1", av) end
                        end
                    end
                    if aic.name then
                        T("ai_taskforce_composition.ai_taskforce_composition",
                            aic.name) end
                end
                local nn = 0
                for _, nh in ipairs(tf.naval_hqs or {}) do
                    nn = nn + 1 T("naval_headquarter.#" .. nn, nh) end
                T("repair_parent", tf.repair_parent)
                -- repair_child: 重复裸键不编号 (SOV 实证 save 双行
                -- 'repair_child = id=...'; seqc [2] = ±1 MISS 对)
                for _, rc in ipairs(tf.repair_children or {}) do
                    T("repair_child", rc) end
                if tf.repair_split then T("repair_split", "yes") end
                -- §4.16.2 strike_forces_on_ship: writer key 15282,
                -- ser {+1560/+1572} → tf+1576/1588, 8B 内联 idpair
                -- {type@+0, id@+4}, 重复裸键不编号 (ITA fleet[3] 双行实证)
                do
                    local a2 = tf._addr
                    local sfd = a2 and rp(a2 + 1576)
                    local sfc = a2 and ru32(a2 + 1588)
                    if sfd and kptr(sfd) and sfc and sfc > 0 and sfc < GAME.layout.lim.PTR_SANE then
                        for j = 0, sfc - 1 do
                            local e = sfd + 8 * j
                            T("strike_forces_on_ship",
                                SL.idpair(ru32(e + 4), ru32(e)))
                        end
                    end
                end
                -- 坐标 {data@+1536, count@+1548} → tf+1552/1564; 8B 内联
                -- idpair {type@+0, id@+4} 逐元素裸键重复; 探针实证 CHI tf420
                -- spotters id=618 type=61)
                do
                    local a2 = tf._addr
                    local spd = a2 and rp(a2 + 1552)
                    local spc = a2 and ru32(a2 + 1564)
                    if spd and kptr(spd) and spc and spc > 0 and spc < GAME.layout.lim.PTR_SANE then
                        for j = 0, spc - 1 do
                            local e = spd + 8 * j
                            -- 重复裸键不编号 (同 repair_child 定案)
                            T("spotters", SL.idpair(ru32(e + 4), ru32(e)))
                        end
                    end
                end
                -- §4.16.2 enemy_mines_factor: writer 0x140D66770 尾段
                -- 0x4DAF, i64 fixed5 @tf+1616, 门 signed>0 (NOR 9025
                -- → 0.09025 / ENG 539 → 0.00539)
                do
                    local ta = tf._addr
                    local emf = ta and rp(ta + 1616)
                    if emf and emf > 0 then
                        T("enemy_mines_factor", NF(emf * 1e-5)) end
                end
                T("repair_target", NF(tf.repair_target))
                -- §4.16.2 repair_last_mission: writer 0x140D66770
                -- key 13598, u32 @ser+1248 → tf+1264, ≠0 才写 (HOL
                -- f3 t1 v1264=7 ↔ save=7 实证)
                do
                    local ta = tf._addr
                    local rlm = ta and ru32(ta + 1264)
                    if rlm and rlm ~= 0 then
                        T("repair_last_mission", NF(rlm)) end
                end
                -- path_to_parent 族 (布局/写门/ser=tf+16 视角换算 = 书
                -- §4.16.2) → 运行时 tf+1816 / tf+1820 (vanilla 恒 0,
                -- 存档未见)
                do
                    local ta = tf._addr
                    if ta then
                        local nap = ru32(ta + 1816)
                        if nap and nap ~= 0 then
                            T("next_attempt_to_path_to_parent", NF(nap)) end
                        local ldp = ru32(ta + 1820)
                        if ldp and ldp ~= 1 then
                            T("last_delay_to_path_to_parent", NF(ldp)) end
                    end
                end
                T("detached_activity", tf.detached_activity)
                T("refit_equipment_variant", tf.refit_variant)
                T("refit_to_variant_after_repair", tf.refit_after_repair)
                if tf.is_sea_locked then T("is_sea_locked", "yes") end
                -- §4.16.2 target_ship_types (布局/写门/ser = tf+16 视角
                -- 换算 = 书 §4.16.2) → 运行时 tf+1856/1868; 叶 #N 逐元编号
                do
                    local ta3 = tf._addr
                    local tsd = ta3 and rp(ta3 + 1856)
                    local tsc = ta3 and ru32(ta3 + 1868)
                    if tsd and kptr(tsd) and tsc and tsc > 0 and tsc < GAME.layout.lim.PTR_SANE then
                        for j = 0, tsc - 1 do
                            local tss = SL.sso(tsd + 32 * j)
                            if tss and tss ~= "" then
                                T("target_ship_types.#" .. (j + 1), QE(tss))
                            end
                        end
                    end
                end
                -- ship 基址数组 (序 = reader §7: ships {d@tf+840, c@tf+852}
                -- 指针元素 + kptr 过滤) — history location 内联读对齐用
                local ship_addrs = {}
                do
                    local tfa2 = tf._addr
                    if tfa2 then
                        local sd, sc = rp(tfa2 + 840), ru32(tfa2 + 852) or 0
                        if kptr(sd) and sc > 0 and sc < 4096 then
                            for q = 0, sc - 1 do
                                local sa = rp(sd + 8 * q)
                                if kptr(sa) then
                                    ship_addrs[#ship_addrs + 1] = sa end
                            end
                        end
                    end
                end
                local sseq = SL.seqc()
                for sni, sh in ipairs(tf.ships or {}) do
                    local spfx = tpfx .. sseq("ship") .. "."
                    local function S(path, val)
                        if val ~= nil then emit(tag, spfx .. path, val) end
                    end
                    S("id", SL.idpair(sh.id, sh.type)) -- CShip id 对 (+12/+8)
                    S("definition", sh.definition)
                    S("organisation", NF(sh.organisation))
                    S("strength", NF(sh.strength))
                    S("experience", NF(sh.experience))
                    local saz = sh.equip_az == true
                    local sheq = SL.seqc()
                    for _, e in ipairs(sh.equipment or {}) do
                        if e.id and ((e.amount or 0) ~= 0 or saz) then
                            local ek = sheq("equipment.equipment")
                            S(ek .. ".id", SL.idpair(e.id, e.tp or 70))
                            S(ek .. ".amount", NF(e.amount))
                        end
                    end
                    S("equipment.allow_zero_entries", SL.yn(saz))
                    S("ship_name.type", NF(sh.ship_name_type))
                    S("ship_name.name_order", NF(sh.ship_name_order))
                    if sh.ship_name_ino then               -- 仅假写 no
                        S("ship_name.is_name_ordered", sh.ship_name_ino) end
                    S("ship_name.override", QE(sh.ship_name_override))
                    if sh.ship_name_osp then
                        S("ship_name.override_set_programmatically", "yes") end
                    S("ship_name.equipment", sh.ship_name_equipment)
                    S("max_manpower", NF(sh.max_manpower))
                    S("manpower", NF(sh.manpower))
                    -- §4.16.3 CShip officer 全记录链 (CHeldOfficer @sh+2120, 与 division 同构)
                    -- 块序 inline@+2144 先/追加向量 {data@+2232, count@+2244}
                    -- 元素后, 键序 seed/name/portraits/male
                    do
                        local oseq = SL.seqc()
                        for _, of in ipairs(sh.officer_list or {}) do
                            local ok = oseq("officer")
                            S(ok .. ".seed", NF(of.seed))
                            S(ok .. ".name", QE(of.name))
                            local pseq = SL.seqc()
                            for _, po in ipairs(of.portraits or {}) do
                                S(ok .. ".portraits." .. pseq(po.branch)
                                    .. "." .. po.size, QE(po.path))
                            end
                            S(ok .. ".male", of.male)
                        end
                    end
                    S("refit_production_line", sh.refit_line)
                    S("sunk_convoys", NF(sh.sunk_convoys))
                    S("held_officer.experience", NF(sh.officer_xp))
                    -- §4.16.3 CShip critical_damage (布局/写门 = 书
                    -- §4.16.3; 键 = 部件定义名串); 单行多对 → 提取器收成
                    -- critical_damage.<首键> = "v0 k1=v1 …" 单叶
                    do
                        local sha2 = ship_addrs[sni]
                        local cdd, cdc = sha2 and rp(sha2 + 2328),
                            sha2 and ru32(sha2 + 2340) or nil
                        if SL.kptr(cdd) and cdc and cdc > 0 and cdc < GAME.layout.lim.PTR_SANE then
                            local ckey, cparts = nil, {}
                            for cj = 0, cdc - 1 do
                                local ce = cdd + 16 * cj
                                local dfn = rp(ce)
                                local q24 = dfn and SL.kptr(dfn)
                                    and rp(dfn + 24)
                                -- writer 门 = *(qword*)(def+24) 非空 (D21
                                -- 实证值 13/7 = 小整数, 非 kptr)
                                if SL.kptr(dfn) and q24 and q24 ~= 0 then
                                    local cnm = SL.sso(dfn + 8)
                                    if cnm and cnm ~= "" then
                                        local cv = tostring(ru32(ce + 8) or 0)
                                        if not ckey then
                                            -- 首对: 键进路径, 值裸 (提取器
                                            -- HEAD 吃掉 k=, 余行作值)
                                            ckey = cnm
                                            cparts[#cparts + 1] = cv
                                        else
                                            cparts[#cparts + 1] = cnm .. "="
                                                .. cv
                                        end
                                    end
                                end
                            end
                            if ckey then
                                S("critical_damage." .. ckey,
                                    table.concat(cparts, " "))
                            end
                        end
                    end
                    if sh.history and #sh.history > 0 then
                        -- history 条目地址 (容器@sha+2304/2316 指针元素, kptr
                        -- 过滤同 reader → earrs[hi] 对齐 sh.history[hi])
                        local earrs = {}
                        local sha = ship_addrs[sni]
                        if sha then
                            local hd2 = rp(sha + 2304)
                            local hc2 = ru32(sha + 2316) or 0
                            if kptr(hd2) and hc2 > 0 and hc2 < GAME.layout.lim.PTR_SANE then
                                for q = 0, hc2 - 1 do
                                    local e2 = rp(hd2 + 8 * q)
                                    if kptr(e2) then
                                        earrs[#earrs + 1] = e2 end
                                end
                            end
                        end
                        emit_div_history(spfx .. "history.army_history.",
                            { list = sh.history },
                            { entries = earrs, empty_fallback = true })
                        -- §4.16.3 CShip unit_medals store (布局/写门 = 书
                        -- §4.16.3, 同 CArmyHistory 布局; history vec +
                        -- amount >0 才写)
                        if sha then
                            local st = rp(sha + 2296)
                            if kptr(st) and rp(st) == BASE + GAME.layout.vt.CUnitHistoryEntry then
                                local hd3, hc3 = rp(st + 8), ru32(st + 20)
                                if kptr(hd3) and hc3 and hc3 > 0 and hc3 < GAME.layout.lim.PTR_SANE then
                                    local recs, earrs3 = {}, {}
                                    local tt3 = rp(ctx.gs + 0x358)
                                    for q3 = 0, hc3 - 1 do
                                        local e3 = rp(hd3 + 8 * q3)
                                        if kptr(e3) then
                                            local rec = {}
                                            local an = SL.sso(e3 + 8)
                                            if an and #an > 0 then
                                                rec.army_names = an end
                                            local tid3 = ru32(e3 + 76)
                                            if tid3 and tid3 > 0
                                                and tid3 < 100000 and tt3 then
                                                local tg3 = hoi4.read_str(
                                                    tt3 + 32 * tid3)
                                                if tg3 and #tg3 > 0 then
                                                    rec.target_country = tg3 end
                                            end
                                            rec.date = date_raw(ru32(e3 + 88))
                                            rec.unique = ru32(e3 + 72)
                                            rec.medal_count =
                                                (ru8(e3 + 112) == 1)
                                                and "yes" or "no"
                                            rec.inherit =
                                                (ru8(e3 + 113) == 1)
                                                and "yes" or "no"
                                            recs[#recs + 1] = rec
                                            earrs3[#earrs3 + 1] = e3
                                        end
                                    end
                                    if #recs > 0 then
                                        emit_div_history(
                                            spfx .. "history.unit_medals.history.",
                                            { list = recs },
                                            { entries = earrs3,
                                                empty_fallback = true })
                                    end
                                end
                                local amt = ru32(st + 608)
                                if amt and amt > 0 then
                                    S("history.unit_medals.amount", NF(amt))
                                end
                            end
                        end
                    end
                end
            end
            F("home_base", NF(fl.home_base))
            if fl.automated then F("automated_homebase", fl.automated) end
        end
    end
end }
