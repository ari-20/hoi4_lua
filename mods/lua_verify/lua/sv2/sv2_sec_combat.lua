-- sv2_sec_combat.lua -- combat 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Runtime:combat_full, objects_military §14.7);
-- 本段只持写序/三类分流键/编号/值格式化 (池发射 = SL.pool_emit_gated)。

SV2.gsec[#SV2.gsec + 1] = { name = "combat", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local ok, R = pcall(function() return O:combat_full() end)
    if not ok or not R then return end

    -- 值格式化糖 (tag/日期串 reader 已解析, 此处只加引号)
    local function qt(s) return s and ('"' .. s .. '"') or nil end
    local function qdate(h)
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end
    local qdate_raw = SL.date_quoted -- 无哨兵过滤 (naval air last_external_wave)
    local function arrline_num(t)
        local out = {}
        for _, v in ipairs(t) do out[#out + 1] = SL.num(v) end
        return table.concat(out, " ")
    end
    local function arrline_u32(t)
        local out = {}
        for _, v in ipairs(t) do out[#out + 1] = tostring(v) end
        return table.concat(out, " ")
    end
    -- ⚠ 本族 pool2 循环历史用 clamp(4096) 语义 (非"计数上界拒绝")
    local POOLOPT = { clamp = GAME.layout.lim.PTR_SANE }
    local function epool(pfx, P)
        -- ⚠ pfx 约定: 本族调用点末点**不含** → 此处补 (共享件约定末点已含)
        SL.pool_emit_gated(O, emit, "combat", pfx .. ".", P, POOLOPT)
    end

    -- §4.22.4 SCombatSideData (池基址 reader 已带)
    local function emit_side(cs, pfx)
        if not cs then return end
        if cs.manpower_lost then
            emit("combat", pfx .. ".manpower_lost",
                tostring(cs.manpower_lost)) end
        if cs.manpower_lost_air_factor then
            emit("combat", pfx .. ".manpower_lost_air_factor",
                SL.num(cs.manpower_lost_air_factor)) end
        epool(pfx .. ".equipment_lost", cs.equipment_lost)
        epool(pfx .. ".equipment_captured_by_enemy", cs.equipment_captured)
        epool(pfx .. ".equipment_recovered", cs.equipment_recovered)
        if cs.leader then
            emit("combat", pfx .. ".leader",
                SL.idpair(cs.leader.id, cs.leader.type)) end
        if cs.tags then
            for i = 1, #cs.tags do
                local s = cs.tags[i]
                if s then emit("combat", pfx .. ".tags.#" .. i, qt(s)) end
            end
        end
    end

    -- §4.22.4 CActivityInGroup 条目 (log.group)
    local function emit_group(gr, pfx)
        emit("combat", pfx .. ".group",
            SL.idpair(gr.group_id, gr.group_type))
        if gr.division_templates then
            for i, dt in ipairs(gr.division_templates) do
                emit("combat", pfx .. ".division_template.#" .. i,
                    SL.idpair(dt.id, dt.type))
            end
        end
        if gr.enemy_dmg then
            for i, ed in ipairs(gr.enemy_dmg) do
                emit("combat", pfx .. ".enemy_dmg_units.#" .. i,
                    SL.idpair(ed.unit_id, ed.unit_type))
                emit("combat", pfx .. ".enemy_dmg_str.#" .. i,
                    SL.num(ed.value))
            end
        end
        epool(pfx .. ".damaged_equipment", gr.damaged_equipment)
        -- damage_dealer/damage_taker: writer 0x140BA6770 门 = tid > 0
        if gr.damage_dealer then
            emit("combat", pfx .. ".damage_dealer", qt(gr.damage_dealer)) end
        if gr.damage_taker then
            emit("combat", pfx .. ".damage_taker", qt(gr.damage_taker)) end
    end

    -- §4.22.4 NCombatLog::CStatsObserver log 对象
    local function emit_log(lg, pfx)
        local gseq = SL.seqc()
        for _, gr in ipairs(lg.groups or {}) do
            emit_group(gr, pfx .. "." .. gseq("group")) end
        emit_side(lg.combat_side_data, pfx .. ".combat_side_data")
        local lseq = SL.seqc()
        for _, lh in ipairs(lg.leader_hours or {}) do
            local k = lseq("leader_hours")
            emit("combat", pfx .. "." .. k .. ".leader",
                SL.idpair(lh.id, lh.type))
            emit("combat", pfx .. "." .. k .. ".time", tostring(lh.time))
        end
        local dseq = SL.seqc()
        for _, dm in ipairs(lg.damages or {}) do
            local k = dseq("damage")
            local s = qt(dm.from)
            if s then emit("combat", pfx .. "." .. k .. ".from", s) end
            s = qt(dm.receiver)
            if s then emit("combat", pfx .. "." .. k .. ".receiver", s) end
            s = qt(dm.to)
            if s then emit("combat", pfx .. "." .. k .. ".to", s) end
            emit("combat", pfx .. "." .. k .. ".value", SL.num(dm.value))
        end
        if lg.total_damage then
            emit("combat", pfx .. ".total_damage", SL.num(lg.total_damage)) end
        emit("combat", pfx .. ".modifier_hours.#1",
            arrline_u32(lg.modifier_hours))
        if lg.snow then emit("combat", pfx .. ".snow", "yes") end
        if lg.win then emit("combat", pfx .. ".win", "yes") end
        if lg.progress then
            emit("combat", pfx .. ".progress", SL.num(lg.progress)) end
    end

    -- §4.22.5 SNavalHit / SAirHit
    local function emit_naval_hit(nh, pfx)
        emit("combat", pfx .. ".target", tostring(nh.target))
        if nh.name then
            emit("combat", pfx .. ".name", '"' .. nh.name .. '"') end
        emit("combat", pfx .. ".convoy", SL.yn(nh.convoy))
        emit("combat", pfx .. ".damage", SL.num(nh.damage))
        emit("combat", pfx .. ".strength", SL.num(nh.strength))
        emit("combat", pfx .. ".last_hit", SL.yn(nh.last_hit))
    end
    local function emit_air_hit(ah, pfx)
        if ah.tag then emit("combat", pfx .. ".tag", qt(ah.tag)) end
        if ah.var_id then
            emit("combat", pfx .. ".equipment_variant_index",
                SL.idpair(ah.var_id, ah.var_type)) end
        emit("combat", pfx .. ".count", tostring(ah.count))
    end

    -- §4.22.5 member.cached_info (发射序 = writer 恒定)
    local function emit_cached_info(ci, pfx)
        if not ci then return end
        local function cemit(leaf, val)
            if val then emit("combat", pfx .. ".cached_info." .. leaf, val) end
        end
        if ci.sprite then cemit("sprite", '"' .. ci.sprite .. '"') end
        cemit("index", tostring(ci.index))
        cemit("type", tostring(ci.type))
        cemit("tag", qt(ci.tag))
        if ci.strength then cemit("strength", SL.num(ci.strength)) end
        if ci.sunk_by then cemit("sunk_by", '"' .. ci.sunk_by .. '"') end
        if ci.convoy then cemit("convoy", "yes") end
        if ci.build_cost_ic then
            cemit("build_cost_ic", SL.num(ci.build_cost_ic)) end
        if ci.equipment_variant then
            cemit("equipment_variant", '"' .. ci.equipment_variant .. '"') end
        if ci.hev_id then
            cemit("highest_eq_variant", SL.idpair(ci.hev_id, ci.hev_type)) end
        if ci.ship then cemit("ship", '"' .. ci.ship .. '"') end
        if ci.potf then cemit("pride_of_the_fleet", "yes") end
        if ci.convoy_id_type or ci.convoy_id_id then
            cemit("convoy_id", SL.idpair(ci.convoy_id_id, ci.convoy_id_type))
        end
        if ci.convoy_index then
            cemit("convoy_index", tostring(ci.convoy_index)) end
    end

    -- §4.22.5 CFEXMember member 条目
    local function emit_naval_member(m, pfx)
        if not m then return end
        emit("combat", pfx .. ".unique_id", tostring(m.unique_id))
        if m.ship then
            emit("combat", pfx .. ".ship",
                SL.idpair(m.ship.id, m.ship.type)) end
        if m.convoy then
            emit("combat", pfx .. ".convoy",
                SL.idpair(m.convoy.id, m.convoy.type)) end
        emit("combat", pfx .. ".state", tostring(m.state))
        emit("combat", pfx .. ".hours_to_arrive", tostring(m.hours_to_arrive))
        emit("combat", pfx .. ".cooldown.#1", arrline_num(m.cooldown))
        emit_cached_info(m.cached_info, pfx)
        if m.critical_hits_received then
            emit("combat", pfx .. ".critical_hits_received",
                tostring(m.critical_hits_received)) end
        local hseq = SL.seqc()
        for _, nh in ipairs(m.naval_hits or {}) do
            emit_naval_hit(nh, pfx .. "." .. hseq("naval_hit")) end
        local aseq = SL.seqc()
        for _, ah in ipairs(m.air_hits or {}) do
            emit_air_hit(ah, pfx .. "." .. aseq("air_hit")) end
        if m.evacuated then
            emit("combat", pfx .. ".evacuated", tostring(m.evacuated)) end
        if m.hidden then
            emit("combat", pfx .. ".hidden", tostring(m.hidden)) end
        if m.escape_progress then
            emit("combat", pfx .. ".escape_progress",
                SL.num(m.escape_progress)) end
        emit("combat", pfx .. ".damage_received_by_gun_types.#1",
            arrline_num(m.gun_type_damage))
        for i, dr in ipairs(m.damage_received or {}) do
            local dp = pfx .. ".damage_received.#" .. i
            emit("combat", dp .. ".ship",
                SL.idpair(dr.ship_id, dr.ship_type))
            if dr.tag then emit("combat", dp .. ".tag", qt(dr.tag)) end
            emit("combat", dp .. ".damage", SL.num(dr.damage))
        end
        if m.last_target then
            emit("combat", pfx .. ".last_target.convoy",
                SL.yn(m.last_target.convoy))
            emit("combat", pfx .. ".last_target.size",
                tostring(m.last_target.size))
        end
    end

    -- §4.22.5 CFEXAir group air 条目
    local function emit_naval_air(na, pfx)
        if not na then return end
        if na.tag then emit("combat", pfx .. ".tag", qt(na.tag)) end
        if na.air_base then
            emit("combat", pfx .. ".air_base",
                SL.idpair(na.air_base.id, na.air_base.type)) end
        for _, w in ipairs(na.air_wings or {}) do
            emit("combat", pfx .. ".air_wing", SL.idpair(w.id, w.type)) end
        for _, ns in ipairs(na.naval_strikes or {}) do
            emit("combat", pfx .. ".naval_strike",
                SL.idpair(ns.id, ns.type)) end
        if na.names then
            local tt2 = {}
            for _, nm in ipairs(na.names) do
                tt2[#tt2 + 1] = '"' .. nm .. '"'
            end
            if #tt2 > 0 then
                emit("combat", pfx .. ".names.#1", table.concat(tt2, " ")) end
        end
        emit("combat", pfx .. ".max", tostring(na.max))
        emit("combat", pfx .. ".alive", tostring(na.alive))
        emit("combat", pfx .. ".casualties", tostring(na.casualties))
        if na.last_external_wave_h then
            local ds = qdate_raw(na.last_external_wave_h)
            if ds then
                emit("combat", pfx .. ".last_external_wave_date", ds) end
        end
        emit("combat", pfx .. ".external_wave_complete",
            SL.yn(na.external_wave_complete))
        emit("combat", pfx .. ".time_duration", tostring(na.time_duration))
        emit("combat", pfx .. ".external", SL.yn(na.external))
        if na.name then
            emit("combat", pfx .. ".name", '"' .. na.name .. '"') end
        emit("combat", pfx .. ".damage_mult", SL.num(na.damage_mult))
        local hseq = SL.seqc()
        for _, nh in ipairs(na.naval_hits or {}) do
            emit_naval_hit(nh, pfx .. "." .. hseq("naval_hit")) end
        local aseq = SL.seqc()
        for _, ah in ipairs(na.air_hits or {}) do
            emit_air_hit(ah, pfx .. "." .. aseq("air_hit")) end
        if na.carrier then
            emit("combat", pfx .. ".carrier", tostring(na.carrier)) end
    end

    -- §4.22.5 CFEXGroup group 条目
    local function emit_naval_group(ng, pfx)
        if not ng then return end
        local mseq = SL.seqc()
        for _, m in ipairs(ng.members or {}) do
            emit_naval_member(m, pfx .. "." .. mseq("member")) end
        local aseq = SL.seqc()
        for _, na in ipairs(ng.airs or {}) do
            emit_naval_air(na, pfx .. "." .. aseq("air")) end
        if ng.opponent_group then
            emit("combat", pfx .. ".opponent_group",
                tostring(ng.opponent_group)) end
        emit("combat", pfx .. ".forces_compare", SL.num(ng.forces_compare))
        emit("combat", pfx .. ".disengage_counter",
            tostring(ng.disengage_counter))
        emit("combat", pfx .. ".chasing_counter",
            tostring(ng.chasing_counter))
    end

    -- §4.22.5 CNavalCombatant 海战参战方
    local function emit_naval_side(ns, pfx)
        if not ns then return end
        for _, u in ipairs(ns.units or {}) do
            emit("combat", pfx .. ".unit", SL.idpair(u.id, u.type)) end
        local gseq = SL.seqc()
        for _, g in ipairs(ns.groups or {}) do
            emit_naval_group(g, pfx .. "." .. gseq("group")) end
        if ns.last_leader then
            emit("combat", pfx .. ".last_leader",
                SL.idpair(ns.last_leader.id, ns.last_leader.type)) end
        if ns.disengage then emit("combat", pfx .. ".disengage", "yes") end
        emit("combat", pfx .. ".anti_air", SL.num(ns.anti_air))
        emit("combat", pfx .. ".positioning", SL.num(ns.positioning))
        if ns.new_ships_positioning_penalty then
            emit("combat", pfx .. ".new_ships_positioning_penalty",
                SL.num(ns.new_ships_positioning_penalty)) end
        emit("combat", pfx .. ".total_damage_dealt",
            SL.num(ns.total_damage_dealt))
        emit("combat", pfx .. ".total_initial_strength",
            SL.num(ns.total_initial_strength))
        emit("combat", pfx .. ".positioning_dominance_bonus",
            SL.num(ns.positioning_dominance_bonus))
        emit("combat", pfx .. ".damage_dealt_by_gun_types.#1",
            arrline_num(ns.gun_type_damage))
        for _, sd in ipairs(ns.ship_type_damage or {}) do
            emit("combat", pfx .. ".damage_dealt_by_ship_types." .. sd.name,
                SL.num(sd.value)) end
    end

    -- §4.22.5 convoy 条目
    local function emit_convoy_entry(cv, pfx)
        if not cv then return end
        emit("combat", pfx .. ".id", SL.idpair(cv.id_id, cv.id_type))
        if cv.var_id then
            emit("combat", pfx .. ".equipment_variant_index",
                SL.idpair(cv.var_id, cv.var_type)) end
        emit("combat", pfx .. ".strength", SL.num(cv.strength))
        emit("combat", pfx .. ".organisation", SL.num(cv.organisation))
        if cv.tag then emit("combat", pfx .. ".tag", qt(cv.tag)) end
        if cv.transfer_navy then
            emit("combat", pfx .. ".transfer_navy",
                SL.idpair(cv.transfer_navy.id, cv.transfer_navy.type)) end
        if cv.client then
            emit("combat", pfx .. ".client",
                SL.idpair(cv.client.id, cv.client.type)) end
        emit("combat", pfx .. ".convoy_index", tostring(cv.convoy_index))
    end

    -- §4.22.4 CCombatant/CLandCombatant 参战方
    local function emit_combatant(cb, pfx)
        if not cb then return end
        local function reflist(lst, key)
            for _, u in ipairs(lst or {}) do
                emit("combat", pfx .. "." .. key,
                    SL.idpair(u.id, u.type)) end
        end
        reflist(cb.units, "unit")
        emit("combat", pfx .. ".losses", SL.num(cb.losses))
        if cb.size then
            emit("combat", pfx .. ".size.#1", arrline_num(cb.size)) end
        if cb.has_flanked then
            emit("combat", pfx .. ".has_flanked_opponent", "yes") end
        if cb.last_hit then
            emit("combat", pfx .. ".last_hit", qt(cb.last_hit)) end
        if cb.shore_bombardment_factor then
            emit("combat", pfx ..
                ".shore_bombardment_collateral_damage_factor",
                SL.num(cb.shore_bombardment_factor)) end
        if cb.air_kills then
            emit("combat", pfx .. ".air_kills", tostring(cb.air_kills)) end
        local function pf(v, key)
            if v then emit("combat", pfx .. "." .. key, SL.num(v)) end
        end
        pf(cb.air_damage_str, "air_damage_str")
        pf(cb.air_damage_org, "air_damage_org")
        pf(cb.ground_damage_str, "ground_damage_str")
        pf(cb.ground_damage_org, "ground_damage_org")
        pf(cb.prevented_damage_str, "prevented_damage_str")
        pf(cb.prevented_damage_org, "prevented_damage_org")
        pf(cb.anti_air_attack, "anti_air_attack")
        reflist(cb.fronts, "front")
        reflist(cb.reserves, "reserves")
        reflist(cb.retreats, "retreat")
        local aseq = SL.seqc()
        for _, ap in ipairs(cb.air_planes or {}) do
            local k = aseq("air_plane")
            if ap.date_h then
                local ds = qdate(ap.date_h)
                if ds then emit("combat", pfx .. "." .. k .. ".date", ds) end
            end
            emit("combat", pfx .. "." .. k .. ".amount", tostring(ap.amount))
            emit("combat", pfx .. "." .. k .. ".air_wing",
                SL.idpair(ap.wing_id, ap.wing_type))
            emit("combat", pfx .. "." .. k .. ".air_count",
                tostring(ap.air_count))
            emit("combat", pfx .. "." .. k .. ".damage_factor",
                SL.num(ap.damage_factor))
        end
        if cb.tactic then
            emit("combat", pfx .. ".tactic", tostring(cb.tactic)) end
        if cb.org_loss_summary then
            emit("combat", pfx .. ".org_loss_summary.#1",
                arrline_num(cb.org_loss_summary)) end
        if cb.str_loss_summary then
            emit("combat", pfx .. ".str_loss_summary.#1",
                arrline_num(cb.str_loss_summary)) end
        emit("combat", pfx .. ".org_loss_summary_index",
            tostring(cb.org_loss_summary_index))
        emit("combat", pfx .. ".num_org_losses",
            tostring(cb.num_org_losses))
        for _, wp in ipairs(cb.weighted_participants or {}) do
            emit("combat", pfx .. ".weighted_participants",
                qt(wp.tag) .. " " .. tostring(SL.num(wp.weight)))
        end
        emit_log(cb.log, pfx .. ".log")
    end

    -- §4.22.2 CLandBorderWarCombatant 边界战参战方扩展
    local function emit_bw_side(bw, pfx)
        if not bw then return end
        local function W(path, val)
            emit("combat", pfx .. "." .. path, val) end
        if bw.tag then W("tag", qt(bw.tag)) end
        if bw.state then W("state", tostring(bw.state)) end
        for _, pid in ipairs(bw.provinces or {}) do
            W("province", tostring(pid)) end
        W("orders_group",
            SL.idpair(bw.orders_group.id, bw.orders_group.type))
        W("max_units", tostring(bw.max_units))
        W("modifier", SL.num(bw.modifier))
        W("dig_in_factor", SL.num(bw.dig_in_factor))
        W("terrain_factor", SL.num(bw.terrain_factor))
        if bw.on_win then W("on_win", '"' .. bw.on_win .. '"') end
        if bw.on_lose then W("on_lose", '"' .. bw.on_lose .. '"') end
        if bw.on_cancel then W("on_cancel", '"' .. bw.on_cancel .. '"') end
        local rseq = SL.seqc()
        for _, ru in ipairs(bw.removed_units or {}) do
            local k = rseq("removed_unit")
            W(k .. ".unit", SL.idpair(ru.id, ru.type))
            W(k .. ".hours", tostring(ru.hours))
        end
    end

    -- 场循环 (三类分流键由 reader kind 定; 发射序 = reader list 序 = 容器序)
    local seqL, seqN, seqB = SL.seqc(), SL.seqc(), SL.seqc()
    for _, rc in ipairs(R.list or {}) do
        local key = rc.kind == "border" and seqB("border_war_combat")
            or rc.kind == "naval" and seqN("naval_combat")
            or seqL("land_combat")
        local function E(path, val)
            emit("combat", key .. "." .. path, val) end
        E("id", SL.idpair(rc.id_id, rc.id_type))
        if rc.location then E("location", tostring(rc.location)) end
        E("day", tostring(rc.day)) -- ADFE0 按 int32 打印 (-1=海战)
        E("duration", tostring(rc.duration))
        if rc.naval then
            local nv = rc.naval
            emit_naval_side(nv.attacker, key .. ".attacker")
            emit_naval_side(nv.defender, key .. ".defender")
            for _, cl in ipairs(nv.clients or {}) do
                E("client", SL.idpair(cl.id, cl.type)) end
            for _, nt in ipairs(nv.naval_transports or {}) do
                E("naval_transport", SL.idpair(nt.id, nt.type)) end
            if nv.convoys then
                local vseq = SL.seqc()
                for _, cv in ipairs(nv.convoys) do
                    emit_convoy_entry(cv, key .. "." .. vseq("convoy")) end
            end
            E("unique_id", tostring(nv.unique_id))
            if nv.port_strike then E("port_strike", "yes") end
            if nv.naval_strike then E("naval_strike", "yes") end
            if nv.sunk_convoys then
                E("sunk_convoys", tostring(nv.sunk_convoys)) end
            if nv.hide then E("hide", "yes") end
            if nv.convoy_combat then E("convoy_combat", "yes") end
            E("progress", SL.num(nv.progress))
        else
            emit_combatant(rc.attacker, key .. ".attacker")
            emit_combatant(rc.defender, key .. ".defender")
            if rc.kind == "border" then
                emit_bw_side(rc.bw_attacker, key .. ".attacker")
                emit_bw_side(rc.bw_defender, key .. ".defender")
                E("combat_width", SL.num(rc.combat_width))
                E("combat_state", tostring(rc.combat_state))
                E("minimum_duration_in_days",
                    tostring(rc.minimum_duration_in_days))
                E("start", tostring(rc.start))
                E("change_state_after_war",
                    SL.yn(rc.change_state_after_war))
            end
        end
        if rc.terrain then E("terrain", '"' .. rc.terrain .. '"') end
    end

    -- §4.22.4 CCombatHistory (链表序 = 存档序)
    for hi, hr in ipairs(R.history or {}) do
        local pfx = "history.history.#" .. hi
        emit("combat", pfx .. ".location", tostring(hr.location))
        if hr.attacker then
            emit("combat", pfx .. ".attacker", qt(hr.attacker)) end
        if hr.defender then
            emit("combat", pfx .. ".defender", qt(hr.defender)) end
        if hr.end_h then
            local ds = qdate(hr.end_h)
            if ds then emit("combat", pfx .. ".end_date", ds) end
        end
        emit("combat", pfx .. ".type", tostring(hr.type))
    end
end }
