-- sv2_sec_raids.lua -- raids 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Runtime.raid_targets /
--  Runtime.raid_country_entries, objects_global §31.3/§31.4 §4.27.1)

SV2.gsec[#SV2.gsec + 1] = { name = "raids", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local DIM = "raids"
    local function E(path, val)
        if val ~= nil then emit(DIM, path, val) end
    end
    local function s32(v)               -- u32 哨兵 0xFFFFFFFF → -1
        if v == nil then return nil end
        if v == 0xFFFFFFFF then return -1 end
        return v
    end
    -- ===== targets (§31.3) — §4.27.1 目标管理器 (@CRaidSystem+8) =====
    local rt = O:raid_targets()
    if rt then
        E("targets.next_state", tostring(s32(rt.next_state)))
        E("targets.existing_target_num", tostring(s32(rt.existing_target_num)))
        E("targets.detectable_target_num",
            tostring(s32(rt.detectable_target_num)))
        E("targets.next_target", tostring(s32(rt.next_target)))
        for ti, t in ipairs(rt.targets or {}) do
            local key = ti == 1 and "targets.target"
                or ("targets.target[" .. ti .. "]")
            E(key .. ".existing_target_num", tostring(s32(t.existing)))
            E(key .. ".detectable_target_num", tostring(s32(t.detectable)))
            E(key .. ".valid", SL.yn(t.valid))
            E(key .. ".dynamic", SL.yn(t.dynamic))
            -- leader / leader_province (§4.27.1 SRaidTarget)
            if t.leader then
                E(key .. ".target.leader",
                    SL.idpair(t.leader.id, t.leader.type))
            end
            if t.leader_province then
                E(key .. ".target.leader_province",
                    tostring(t.leader_province))
            end
            if t.state and t.state >= 0 then
                E(key .. ".target.state", tostring(t.state)) end
            if t.province and t.province >= 0 then
                E(key .. ".target.province", tostring(t.province)) end
            if t.bld_template then
                E(key .. ".target.building.template", tostring(t.bld_template))
            end
            if t.bld_location then
                E(key .. ".target.building.location", tostring(t.bld_location))
            end
            if t.detected and #t.detected > 0 then
                local parts = {}
                for _, b in ipairs(t.detected) do
                    parts[#parts + 1] = tostring(b) end
                E(key .. ".detected", table.concat(parts, " "))
            end
        end
    end

    -- ===== countries (§31.4) — §4.27.1 CCountryRaidStatus =====
    local rc = O:raid_country_entries()
    if rc then
        for _, rec in ipairs(rc) do
            local P = "countries.#" .. (rec.index + 1)
            if rec.tag then E(P .. ".tag", SL.Q(rec.tag)) end
            E(P .. ".priority", tostring(rec.priority or 0))
            if rec.dummy_id then
                E(P .. ".dummy.id", SL.idpair(rec.dummy_id, rec.dummy_type))
            end
            for ki, ir in ipairs(rec.instances or {}) do
                local IP = P .. ".raid_instance.#" .. ki
                E(IP .. ".id", SL.idpair(ir.id, ir.type_id))
                if ir.prep_time and ir.prep_time ~= 0 then
                    E(IP .. ".prep_time", tostring(ir.prep_time)) end
                if ir.nr_days and ir.nr_days ~= 0 then
                    E(IP .. ".nr_days_launchable", tostring(ir.nr_days)) end
                if ir.distance and ir.distance ~= 0 then
                    E(IP .. ".distance", SL.num(ir.distance)) end
                if ir.phase and ir.phase ~= "NONE" and ir.phase ~= "?" then
                    E(IP .. ".phase", SL.Q(ir.phase)) end
                if ir.outcome and ir.outcome ~= "NONE" and ir.outcome ~= "?" then
                    E(IP .. ".outcome", SL.Q(ir.outcome)) end
                if ir.type_name then E(IP .. ".type", SL.Q(ir.type_name)) end
                -- unit.air_wing (§4.27.1 CRaidInstance +200 双 id 对)
                if ir.air_wing then
                    E(IP .. ".unit.air_wing",
                        SL.idpair(ir.air_wing.id, ir.air_wing.type))
                end
                -- target.leader / leader_province (§4.27.1 SRaidTarget)
                if ir.leader then
                    E(IP .. ".target.leader",
                        SL.idpair(ir.leader.id, ir.leader.type))
                end
                if ir.leader_province then
                    E(IP .. ".target.leader_province",
                        tostring(ir.leader_province))
                end
                if ir.src_province then
                    E(IP .. ".raid_source.province",
                        tostring(ir.src_province))
                end
                -- raid_source.ship (§4.27.1 raid_source 块+16 内联 id 对)
                if ir.src_ship then
                    E(IP .. ".raid_source.ship", ir.src_ship)
                end
                local tb = ir.target_building
                if tb then
                    if tb.template then
                        E(IP .. ".target.building.template",
                            tostring(tb.template)) end
                    if tb.location then
                        E(IP .. ".target.building.location",
                            tostring(tb.location)) end
                end
                if ir.target_province then
                    E(IP .. ".target.province", tostring(ir.target_province))
                end
                if ir.target_state then
                    E(IP .. ".target.state", tostring(ir.target_state))
                end
                if ir.unit_army_id then
                    E(IP .. ".unit.army",
                        SL.idpair(ir.unit_army_id, ir.unit_army_type)) end
                if ir.src_type then
                    E(IP .. ".raid_source.type", tostring(ir.src_type)) end
                if ir.src_tag then
                    E(IP .. ".raid_source.tag", SL.Q(ir.src_tag)) end
                -- raid_source.building 有效性门 (reader 判)
                local sb = ir.src_building_valid and ir.src_building or nil
                if sb then
                    if sb.template then
                        E(IP .. ".raid_source.building.template",
                            tostring(sb.template)) end
                    if sb.location then
                        E(IP .. ".raid_source.building.location",
                            tostring(sb.location)) end
                end
                -- show_for 标签列 (提取器半匿名续行怪癖: 首标签在
                -- show_for={ 行, #2+ 走 @.#(j-1))
                if ir.show_for and #ir.show_for > 0 then
                    E(IP .. ".show_for",
                        "show_for={ \"" .. ir.show_for[1] .. "\"")
                    for j = 2, #ir.show_for do
                        E(IP .. ".@.#" .. (j - 1), '"' .. ir.show_for[j] .. '"')
                    end
                end
                if ir.detected and ir.detected ~= 0 then
                    E(IP .. ".detected", "yes") end
                -- end_date (§4.27.1 CRaidInstance: 门 bool@+432,
                -- 内嵌 CGameDate hours@+416)
                if ir.end_gate and ir.end_gate ~= 0 and ir.end_hours then
                    local d = SL.date(ir.end_hours)
                    if d then
                        E(IP .. ".end_date", '"' .. d .. '"') end
                end
                if ir.victim then
                    E(IP .. ".victim_country", SL.Q(ir.victim)) end
            end
            -- target_cooldowns (§4.27.1 CCountryRaidStatus +72)
            for j, cd in ipairs(rec.target_cooldowns or {}) do
                local TP = P .. ".target_cooldowns.#" .. j
                if cd.bld_template then
                    E(TP .. ".target.building.template",
                        tostring(cd.bld_template)) end
                if cd.bld_location then
                    E(TP .. ".target.building.location",
                        tostring(cd.bld_location)) end
                if cd.province then
                    E(TP .. ".target.province", tostring(cd.province)) end
                if cd.state then
                    E(TP .. ".target.state", tostring(cd.state)) end
                if cd.type_name then
                    E(TP .. ".type", '"' .. tostring(cd.type_name) .. '"') end
                E(TP .. ".cooldown", tostring(cd.cooldown or 0))
            end
        end
    end
end }
