-- sv2_sec_c_volunteers.lua -- country.volunteers_transfer / exile_divisions_transfer /
-- expeditionaries_sent 三节点 savefull 直出 (csec, 同族同文件)
-- =====================================================================
-- [1] §4.10.19 CVolunteerForceTransfer volunteers_transfer
--     (容器 {data@cc+5040, count i32@cc+5052} → 0xA0 元素; 布局/写门/键序 = 书 §4.10.19)
-- [2] §4.10.19 CExileDivisionsTransfer exile_divisions_transfer
--     (容器 {data@cc+5064, count i32@cc+5076} → 0x38 元素; 布局同上书 §4.10.19;
--      流亡国自身 divisions 空 → 师包装走 reader O.unit_division)
-- [3] §4.3.1 expeditionaries_sent (容器 {data@cc+760, count u32@cc+772};
--     每元素一行 #N 恒编号, 值 "id=N type=T")
-- =====================================================================
-- 共用 id 对解析 = resource.lua M.rva.idreg (§4.26.3; 已上提 reader)。
-- ⚠ 师库存指针 = this 调整指针, 师 raw = res-16 (第二基类 vt1 → vt0;
--   §4.18.5 CArmy; writer 以 res 调 vt1+8 → id 写两次)。
-- officer 多块 (+1384 vector) = 书 §4.18.1 army_history 子表。

-- ============ 共享助手工厂 (绑定 ctx; volunteers/exile 两族复用) ============
-- 师包装上提 reader — O.unit_division(ty,id) (idreg 解析 +
-- vt 双校验 + res-16 调整 + mk_div) / O.division_at(addr); 旧 DivMT
-- 元表跨国借用 (g_divmt 缓存) 退役 (流亡国 114 叶事故的根治)。
local function mk_h(ctx)
    local SL, emit, tag, O, i = SV2.lib, ctx.emit, ctx.tag, ctx.O, ctx.i
    local rp, ru32, ru8, kptr = SL.rp, SL.ru32, SL.ru8, SL.kptr
    local cc, gs, BASE = ctx.cc, ctx.gs, ctx.BASE
    local c = ctx.country
    local H = { SL = SL, emit = emit, tag = tag, O = O, i = i,
        rp = rp, ru32 = ru32, ru8 = ru8, kptr = kptr,
        cc = cc, gs = gs, BASE = BASE }

    function H.QE(s)
        if s and s ~= "" and s ~= "nil" then
            return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
        end
        return nil
    end
    function H.NF(v)
        local n = tonumber(v)
        if n then return SL.num(n) end
        return nil
    end
    function H.words(s)
        local out = {}
        if s then for w in tostring(s):gmatch("%S+") do out[#out + 1] = w end end
        return out
    end
    -- CGameDate 总小时 -> "Y.M.D.H" (B 族)
    H.date_raw = SL.date_raw
    -- IEEE754 位型 -> ×255 取整 (同 objects_v2 §7 fleet_color / theatres 截断)
    function H.fcol(bits)
        if not bits or bits == 0 then return 0 end
        local e = math.floor(bits / 2 ^ 23) % 256
        local m = bits % 2 ^ 23
        local v
        if e == 0 then v = m / 2 ^ 23 * 2 ^ -126
        else v = (1 + m / 2 ^ 23) * 2 ^ (e - 127) end
        return math.floor(v * 255)
    end
    -- CUnitHistoryEntry +104 medal 定义叶 (§4.18; 同 units)
    function H.medal_name_of(e)
        local mdp = rp(e + 104)
        if kptr(mdp) and (ru8(mdp + 16) or 0) ~= 0 then
            local mdn = SL.sso(mdp + 24)
            if mdn and #mdn > 0 then return mdn end
        end
        return nil
    end
    -- tag id → 名串 (§1.2 gs+856 tag 串表, 32B/项; 同 units medal 内联读法)
    local ttags = rp(gs + 0x358)
    function H.tagstr(tid)
        if tid and tid > 0 and tid < GAME.layout.lim.PTR_HUGE and kptr(ttags) then
            local s = hoi4.read_str(ttags + 32 * tid)
            if s and #s > 0 then return s end
        end
        return nil
    end

    -- 师 history_queue 公共发射 (复制自 sv2_sec_c_units, 字段同构)
    function H.emit_div_history(dpfx, ah, opts)
        local hseq = SL.seqc()
        for hi, hr in ipairs(ah.list or {}) do
            if hi > 64 then break end
            local hk = dpfx .. hseq("history_queue")
            local v = H.QE(hr.army_names)
            if v then emit(tag, hk .. ".army_names", v)
            elseif opts and opts.empty_fallback then
                emit(tag, hk .. ".army_names", '""') end
            v = H.QE(hr.target_country)
            if v then emit(tag, hk .. ".target_country", v)
            elseif opts and opts.empty_fallback then
                emit(tag, hk .. ".target_country", '"---"') end
            local ln = 0
            local ea = opts and opts.entries and opts.entries[hi]
            if ea then
                local ld, lc = rp(ea + 0x120), ru32(ea + 0x128)
                if kptr(ld) and lc and lc > 0 and lc < GAME.layout.lim.PTR_SANE then
                    for j = 0, lc - 1 do
                        local lp = rp(ld + 8 * j)
                        local lid = kptr(lp) and ru32(lp + 164) or nil
                        if lid then
                            ln = ln + 1
                            emit(tag, hk .. ".location.#" .. ln, H.NF(lid)) end
                    end
                end
            else
                for _, lid in ipairs(H.words(hr.location)) do
                    ln = ln + 1
                    emit(tag, hk .. ".location.#" .. ln, lid)
                end
            end
            if ea then
                local mdn = H.medal_name_of(ea)
                if mdn then emit(tag, hk .. ".unit_medals", H.QE(mdn)) end
            end
            v = H.QE(hr.date) if v then emit(tag, hk .. ".date", v) end
            if hr.unique ~= nil then emit(tag, hk .. ".unique", H.NF(hr.unique)) end
            if hr.medal_count then emit(tag, hk .. ".medal_count", hr.medal_count) end
            if hr.inherit then emit(tag, hk .. ".inherit", hr.inherit) end
            if hr.multiplier then emit(tag, hk .. ".multiplier", H.NF(hr.multiplier)) end
            if hr.orders then emit(tag, hk .. ".orders", H.NF(hr.orders)) end
            local su = hr.sunk
            if su then
                local sp = hk .. ".sunk_ship"
                v = H.QE(su.name) if v then emit(tag, sp .. ".name", v) end
                v = H.QE(su.killer_name) if v then emit(tag, sp .. ".killer_name", v) end
                v = H.QE(su.country) if v then emit(tag, sp .. ".country", v) end
                v = H.QE(su.killer_country) if v then emit(tag, sp .. ".killer_country", v) end
                if su.level then emit(tag, sp .. ".level", H.NF(su.level)) end
                if su.definition then emit(tag, sp .. ".definition", su.definition) end
                if su.killer_definition then
                    emit(tag, sp .. ".killer_definition", su.killer_definition) end
                if su.location then emit(tag, sp .. ".location", H.NF(su.location)) end
                v = H.QE(su.date) if v then emit(tag, sp .. ".date", v) end
                if su.assist then emit(tag, sp .. ".assist", "yes") end
                if su.eq_variant then emit(tag, sp .. ".equipment_variant", su.eq_variant) end
                if su.air_wing and su.air_wing ~= "id=0 type=0" then
                    emit(tag, sp .. ".air_wing", su.air_wing) end
                if su.battle then emit(tag, sp .. ".battle", su.battle) end
                if su.convoy then emit(tag, sp .. ".convoy", su.convoy) end
            end
        end
    end

    -- §4.18.3 requests 全族 (q = *(div+1144)): 复制自 sv2_sec_c_units;
    -- 定案, reader DivMT.requests — 经 objects_v2 mk_div 构造
    function H.emit_requests(dpfx, dv)
        local okr, rq = pcall(function() return dv.requests end)
        if not (okr and rq) then return end
        local pfx = dpfx .. "requests."
        if rq.date then emit(tag, pfx .. "date", H.QE(rq.date)) end
        local mpseq = SL.seqc()
        local function rows(arr, grp)
            for _, kv in ipairs(arr or {}) do
                local k, v = kv[1], kv[2]
                if v ~= nil then
                    if k:match("^manpower_pool%.%d+$") then
                        emit(tag, pfx .. grp .. mpseq("manpower_pool"), v)
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
                                v = H.QE(v)
                            elseif rest:find("allow_zero_entries") then
                            elseif rest:sub(-3) == ".id"
                                or rest:find("equipment_variant_index") then
                            elseif rest == "status" then
                            else v = H.NF(v) end
                            if v then emit(tag, pfx .. grp .. p2 .. rest, v) end
                        end
                    end
                end
            end
        end
        rows(rq.reinforcement, "reinforcement.")
        rows(rq.upgrades, "upgrades.")
    end

    -- id 对 → 对象解析: 收敛到 hoi4_layout.idreg_unit_resolve
    function H.unit_resolve(ty, id)
        return GAME.layout.idreg_unit_resolve(ty, id)
    end

    -- 师解析/包装 = reader O.unit_division (idreg + res-16 + vt 校验 +
    -- mk_div, objects_v2 §6.2a); H.ARMY_VT* 兼容保留 (现役无段内使用)
    H.ARMY_VT0, H.ARMY_VT1 = BASE + GAME.layout.vt.CArmy_vt0, BASE + GAME.layout.vt.CArmy_vt1

    -- ============ §4.18.1 CArmy 师块发射 (与 sv2_sec_c_units division 体同构 + officer[N]) ====
    function H.emit_division(dpfx, dv)
        local NF, QE = H.NF, H.QE
        local function D(path, val)
            if val ~= nil then emit(tag, dpfx .. path, val) end
        end
        local v
        D("id", SL.idpair(dv.id, dv.type))      -- §4.18.5 CUnit 层 id (第 1 次)
        v = H.QE(dv.last_combat_date) D("last_combat_date", v)
        D("movement_progress", NF(dv.movement_progress))
        local mpr = dv.move_priority_raw        -- 写门: raw@a+584 ~= 1
        if mpr and mpr ~= 1 then D("move_priority", dv.move_priority) end
        D("location", NF(dv.location))
        D("logical_country", QE(dv.logical_country))
        D("seed", NF(dv.seed))
        D("id", SL.idpair(dv.id, dv.type))      -- CDivision 层 id (第 2 次)
        D("motorization_level", NF(dv.motorization_level))
        -- officer 全记录链 (CHeldOfficer @a+1272, 与 units 同构): 块序
        -- inline@+1296 先/追加向量 {data@+1384, count@+1396} 元素后,
        -- 键序 seed/name/portraits/male
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
        local dn = dv.division_name             -- 内嵌@a+832 (writer 0x1409BCC70)
        if dn then
            D("division_name.type", NF(dn.type))
            D("division_name.name_order", NF(dn.name_order))
            D("division_name.override", QE(dn.override))
            if dn.override_set_programmatically then
                D("division_name.override_set_programmatically", "yes") end
        end
        D("max_supply", NF(dv.max_supply))
        D("organisation", NF(dv.organisation))
        D("strength", NF(dv.strength))
        -- 装备池 内嵌@a+840; 条目写门 amount~=0 或 az; idpair type 恒 70
        local az = dv.equip_allow_zero == true
        local eseq = SL.seqc()
        for ei, eq in ipairs(dv.equipment or {}) do
            if ei > 40 then break end
            if eq.variant_id and ((eq.amount or 0) ~= 0 or az) then
                local ek = eseq("equipment.equipment")
                D(ek .. ".id", SL.idpair(eq.variant_id, 70))
                D(ek .. ".amount", NF(eq.amount))
            end
        end
        D("equipment.allow_zero_entries", SL.yn(az))
        D("script_id", NF(dv.script_id))
        -- army_manpower 双容器; 重复 value 键不编号 (BEL 实证)
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
        local ac = dv.acclimatization           -- 内嵌@a+1208 (writer 0x140609C70)
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
            for kk, vv in pairs(ac) do
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
        D("supply_gain", NF(dv.supply_gain))
        D("bonus", NF(dv.bonus))
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
        -- 列表单行形态 (对拍定案): 全元素空格拼接进单条 .#1 行
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
        H.emit_requests(dpfx, dv)
        local ah = dv.army_history              -- 内嵌@a+1592 (writer 0x14143AC00)
        if ah and ah.list and #ah.list > 0 then
            local earrs
            local a2 = dv.addr
            if a2 then
                local hd, hc = rp(a2 + 1632), ru32(a2 + 1644)
                if kptr(hd) and hc and hc > 0 and hc < GAME.layout.lim.PTR_SANE then
                    earrs = {}
                    for q = 0, hc - 1 do
                        local e = rp(hd + 8 * q)
                        if kptr(e) then earrs[#earrs + 1] = e end
                    end
                end
            end
            H.emit_div_history(dpfx .. "army_history.army_history.", ah,
                earrs and { entries = earrs } or nil)
        end
        -- army_history.unit_medals (本族 census 0 行, 同 units)
        do
            local a2 = dv.addr
            local st = a2 and rp(a2 + 1624)
            if st and kptr(st) and rp(st) == BASE + GAME.layout.vt.CUnitHistoryEntry then
                local hd2, hc2 = rp(st + 8), ru32(st + 20)
                if kptr(hd2) and hc2 and hc2 > 0 and hc2 < GAME.layout.lim.PTR_SANE then
                    local recs, earrs2 = {}, {}
                    for q = 0, hc2 - 1 do
                        local e = rp(hd2 + 8 * q)
                        if kptr(e) then
                            local rec = {}
                            local an = SL.sso(e + 8)
                            if an and #an > 0 then rec.army_names = an end
                            local tg2 = H.tagstr(ru32(e + 76))
                            if tg2 then rec.target_country = tg2 end
                            rec.date = H.date_raw(ru32(e + 88))
                            rec.unique = ru32(e + 72)
                            rec.medal_count = (ru8(e + 112) == 1)
                                and "yes" or "no"
                            rec.inherit = (ru8(e + 113) == 1)
                                and "yes" or "no"
                            local mult = rp(e + 312)
                            if mult and mult ~= 100000 then
                                rec.multiplier = mult * 1e-5 end
                            local om = ru32(e + 320)
                            if om and om ~= 0 then rec.orders = om end
                            recs[#recs + 1] = rec
                            earrs2[#earrs2 + 1] = e
                        end
                    end
                    if #recs > 0 then
                        H.emit_div_history(
                            dpfx .. "army_history.unit_medals.history.",
                            { list = recs }, { entries = earrs2 })
                    end
                end
                local amt = ru32(st + 608)
                if amt and amt > 0 then
                    D("army_history.unit_medals.amount", NF(amt)) end
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
        -- previous (§4.18.5 CUnit 公共段 +504 / 键 0x29A3, kptr 门): 与 units 段同款
        -- writer 通道; volunteers 侧雇师被调走时置位 (锚件 9 例实证)
        D("previous", NF(dv.previous))
        D("transfer_offset_1", NF(dv.transfer_offset_1))
        D("transfer_offset_2", NF(dv.transfer_offset_2))
        v = QE(dv.start_date) D("start_date", v) -- 写入门 h-43800000>=17520
        v = QE(dv.end_date) D("end_date", v)
        D("expeditionary_owner", QE(dv.expeditionary_owner)) -- 门 tid@a+476>0
    end

    -- ============ transfer 族公共体 (volunteers/exile 仅差头部字段) ============
    -- mode = "volunteers" (容器 5040/5052 + group 子块 + force)
    -- | "exile" (容器 5064/5076 + is_to_host)
    function H.emit_transfers(mode)
        -- 容器走查/T 元素字段/门 = Country.volunteers_transfers (§4.10.19)
        local okv, tl = pcall(function() return c:volunteers_transfers(mode) end)
        tl = okv and tl or {}
        local key = (mode == "exile") and "exile_divisions_transfer"
            or "volunteers_transfer"
        local tseq = SL.seqc()
        for _, T in ipairs(tl) do
            local tpfx = tseq(key) .. "."
            local function TR(path, val)
                if val ~= nil then emit(tag, tpfx .. path, val) end
            end
            TR("to", H.QE(H.tagstr(T.to_tid)))       -- 恒写 (0x2990)
            TR("from", H.QE(H.tagstr(T.from_tid)))   -- 恒写 (0x298F)
            TR("days", H.NF(T.days))                 -- 恒写 (0x296D)
            if mode == "exile" then
                TR("is_to_host", SL.yn(T.is_to_host))     -- 恒写 (0x3AC2)
            else
                TR("sender", SL.yn(T.sender))             -- 恒写 yes/no (0x240)
            end
            TR("target_provinces", H.NF(T.target_provinces)) -- 恒写 (0x2D15)
            if T.group_flag then
                TR("group", "yes")
                if T.leader then
                    TR("leader", SL.idpair(T.leader.id, T.leader.type)) end
                if T.leader_unit then
                    TR("leader_unit",
                        SL.idpair(T.leader_unit.id, T.leader_unit.type)) end
                TR("group_color", string.format("%d %d %d",
                    T.group_color[1], T.group_color[2], T.group_color[3]))
                if T.group_name then
                    TR("group_name", H.QE(T.group_name)) end
            end
            local dseq = SL.seqc()
            for _, dd in ipairs(T.divisions or {}) do
                -- reader 直解: idreg + res-16 + vt 双校验 + mk_div
                local dv = O.unit_division(O, dd.type, dd.id)
                if dv then
                    H.emit_division(tpfx .. dseq("division") .. ".", dv)
                end
            end
            if T.force then TR("force", "yes") end
        end
    end

    return H
end

-- ============ 段注册 ============
SV2.csec[#SV2.csec + 1] = { name = "country.volunteers_transfer",
    emit = function(ctx)
        if not ctx.country then return end
        mk_h(ctx).emit_transfers("volunteers")
    end }

SV2.csec[#SV2.csec + 1] = { name = "country.exile_divisions_transfer",
    emit = function(ctx)
        if not ctx.country then return end
        mk_h(ctx).emit_transfers("exile")
    end }

SV2.csec[#SV2.csec + 1] = { name = "country.expeditionaries_sent",
    emit = function(ctx)
        if not ctx.country then return end
        local SL, emit, tag = SV2.lib, ctx.emit, ctx.tag
        local rp, ru32, kptr = SL.rp, SL.ru32, SL.kptr
        -- §4.3.1 expeditionaries_sent {data@cc+760, count u32@cc+772}
        -- 8B 内联对 {type@+0, id@+4},
        -- #N 1 基恒编号 (writer sub_1406BBE20)
        local oke, el = pcall(function() return ctx.country:expeditionaries() end)
        el = oke and el or {}
        for q, dd in ipairs(el) do
            emit(tag, "expeditionaries_sent.#" .. q,
                SL.idpair(dd.id, dd.type))
        end
    end }
