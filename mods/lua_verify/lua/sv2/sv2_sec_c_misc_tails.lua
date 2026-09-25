-- sv2_sec_c_misc_tails.lua -- country 残族扫尾 savefull 直出 (csec)
-- 覆盖 30 族; 结构/走查唯一实现 = reader (Country:misc_tails +
-- c:navy_theaters/naval_hq_status/country_buildings/name_groups/
-- combat_support_scalars); 本段只持写序/块键/编号/值格式化。
-- 分工边界 (不重复发射): navy_theater 主块 = c_strategic_navy 段;
-- focus_cost_reduction = c_focus 段; pride_of_the_fleet_date_lost 等 16 键
-- + ace = country_scalars 段; 名字 tracker 主块 = names_trackers 段。

SV2.csec[#SV2.csec + 1] = { name = "country.misc_tails", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    local cc, O = ctx.cc, ctx.O
    if not cc then return end
    local ok, mt = pcall(function() return c:misc_tails() end)
    if not ok or not mt then return end
    local function qt(s) return s and ('"' .. s .. '"') or nil end

    -- ===== cores / claims (单行保序; ptr→state_id 反查在 reader) =====
    if mt.cores then emit(tag, "cores", table.concat(mt.cores, " ")) end
    if mt.claims then emit(tag, "claims", table.concat(mt.claims, " ")) end

    -- ===== dynamic_modifier (§4.3.8; [N] 首现不编号) =====
    local seq = SL.seqc()
    for _, dm in ipairs(mt.dynamic_modifiers or {}) do
        local kp = "dynamic_modifier." .. seq("modifier") .. "."
        emit(tag, kp .. "modifier", '"' .. dm.name .. '"')
        if dm.state then emit(tag, kp .. "state", SL.num(dm.state)) end
        if dm.tag then emit(tag, kp .. "tag", '"' .. dm.tag .. '"') end
        if dm.values then
            local toks = {}
            for _, v in ipairs(dm.values) do
                toks[#toks + 1] = SL.num(v)
            end
            emit(tag, kp .. "value.#1", table.concat(toks, " "))
        end
        emit(tag, kp .. "enabled", SL.yn(dm.enabled))
        if dm.days then emit(tag, kp .. "days", SL.num(dm.days)) end
    end

    -- ===== logistics.history (§4.3.13; human_writes 门在 reader) =====
    for _, el in ipairs(mt.logistics or {}) do
        for qi, q in ipairs(el.queues) do
            local kp = string.format(
                "logistics.history.%d.history_queue.%d.", el.idx, qi - 1)
            emit(tag, kp .. "max_elements", SL.num(q.max_elements))
            emit(tag, kp .. "offset", SL.num(q.offset))
            emit(tag, kp .. "is_full", SL.yn(q.is_full))
            if q.cells then
                local toks = {}
                for _, v in ipairs(q.cells) do
                    toks[#toks + 1] = SL.num(v)
                end
                emit(tag, kp .. "data.#1", table.concat(toks, " "))
            end
        end
    end

    -- ===== reinforcement.priority (默认 1 不落盘) =====
    if mt.reinforcement_priority then
        emit(tag, "reinforcement.priority", SL.num(mt.reinforcement_priority))
    end

    -- ===== volunteers_sent (#N 1 基恒编号) =====
    for q, vs in ipairs(mt.volunteers_sent or {}) do
        emit(tag, "volunteers_sent.#" .. q, SL.idpair(vs.id, vs.type)) end

    -- ===== navy_theater.theater_group.is_important 补叶 =====
    -- ⚠ id/name/fleet 已由 sv2_sec_c_strategic_navy.lua 发射
    do
        local okn, nt = pcall(function() return c:navy_theaters() end)
        if okn and nt and nt.list then
            local seqn = SL.seqc()
            for _, g in ipairs(nt.list) do
                local kp = "navy_theater." .. seqn("theater_group") .. "."
                if (g.flag3cd7 or 0) ~= 0 then
                    emit(tag, kp .. "is_important", "yes") end
            end
        end
    end

    -- ===== cached_navy_strength.sub_units (块门在 reader; 键 = token) =====
    for _, cn in ipairs(mt.cached_navy_strength or {}) do
        emit(tag, "cached_navy_strength.sub_units." .. tostring(cn.name),
            SL.num(cn.count)) end

    -- ===== naval_headquarter_status (#N 1 基恒编号; reader §26.2) =====
    do
        local okh, nh = pcall(function() return c:naval_hq_status() end)
        if okh and nh and nh.list then
            for bi, b in ipairs(nh.list) do
                local kp = "naval_headquarter_status.buildings.#" .. bi .. "."
                emit(tag, kp .. "id", b.id_pair)
                emit(tag, kp .. "building", b.building)
                if b.province then
                    emit(tag, kp .. "province", SL.num(b.province)) end
                if (b.char_type or 0) ~= 0 then
                    emit(tag, kp .. "navy_leader_building_module.character",
                        SL.idpair(b.char_id, b.char_type)) end
                if b.experience and b.experience ~= 0 then
                    emit(tag, kp .. "navy_leader_building_module.experience",
                        SL.num(b.experience)) end
            end
        end
    end

    -- ===== delayed_event (§4.3.11; scope 树 reader 已建, 本段递归发射) =====
    local seqd = SL.seqc()
    local function emit_scope(sc, prefix)
        if not sc then return end
        local s = qt(sc.country)
        if s then emit(tag, prefix .. ".country", s) end
        if sc.state then emit(tag, prefix .. ".state", SL.num(sc.state)) end
        for _, ps in ipairs({ "character", "operation", "ace", "unit",
            "industrial_organisation", "purchase_contract",
            "raid_instance", "project", "faction" }) do
            local pr = sc[ps]
            if pr then
                emit(tag, prefix .. "." .. ps, SL.idpair(pr.id, pr.type)) end
        end
        if sc.strategic_region then
            emit(tag, prefix .. ".strategic_region",
                SL.num(sc.strategic_region)) end
        if sc.random then
            emit(tag, prefix .. ".random",
                sc.random[1] .. " " .. sc.random[2]) end
        if sc.root then emit_scope(sc.root, prefix .. ".root") end
        if sc.from then emit_scope(sc.from, prefix .. ".from") end
        if sc.prev then emit_scope(sc.prev, prefix .. ".prev") end
        -- saved_event_target: 本路径 (delayed_event) writer 只在
        -- from==自指层写 (reader 已按此门收); 提取件第 2+ 目标编 [N]
        if sc.saved_event_targets then
            for ti, st2 in ipairs(sc.saved_event_targets) do
                local kp2 = prefix .. ".saved_event_target"
                if ti > 1 then kp2 = kp2 .. "[" .. ti .. "]" end
                if st2.state then
                    emit(tag, kp2 .. ".state", SL.num(st2.state)) end
                local s2 = qt(st2.country)
                if s2 then emit(tag, kp2 .. ".country", s2) end
                if st2.name then
                    emit(tag, kp2 .. ".name", '"' .. st2.name .. '"') end
                if st2.character then
                    emit(tag, kp2 .. ".character",
                        SL.idpair(st2.character.id, st2.character.type)) end
            end
        end
    end
    for _, de in ipairs(mt.delayed_events or {}) do
        local blk = seqd("delayed_event")
        if de.event then emit(tag, blk .. ".event", '"' .. de.event .. '"') end
        emit(tag, blk .. ".hours", SL.num(de.hours))
        emit(tag, blk .. ".days", SL.num(de.days))
        emit(tag, blk .. ".months", SL.num(de.months))
        emit_scope(de.scope, blk .. ".scope")
        local ots = qt(de.originator)
        if ots then emit(tag, blk .. ".originator", ots) end
    end

    -- ===== templates_locked + reason (同字节门) =====
    if mt.templates_locked then
        emit(tag, "templates_locked", "yes")
        emit(tag, "reason", '"' .. (mt.reason or "") .. '"') end

    -- ===== pride_of_the_fleet / original_tag =====
    if mt.pride_of_the_fleet then
        emit(tag, "pride_of_the_fleet",
            SL.idpair(mt.pride_of_the_fleet.id, mt.pride_of_the_fleet.type)) end
    local ots = qt(mt.original_tag)
    if ots then emit(tag, "original_tag", ots) end

    -- ===== invasion_report =====
    local seqi = SL.seqc()
    for _, ir in ipairs(mt.invasion_reports or {}) do
        local blk = seqi("invasion_report")
        local s = qt(ir.tag)
        if s then emit(tag, blk .. ".tag", s) end
        s = qt(ir.enemy)
        if s then emit(tag, blk .. ".enemy", s) end
        if ir.province then emit(tag, blk .. ".province", SL.num(ir.province)) end
        local d = SL.date(ir.date_h)
        if d then emit(tag, blk .. ".date", '"' .. d .. '"') end
    end

    -- ===== civil_war_target =====
    for _, s2 in ipairs(mt.civil_war_targets or {}) do
        emit(tag, "civil_war_target", '"' .. s2 .. '"') end

    -- ===== external_rules + override =====
    for _, er in ipairs(mt.external_rules or {}) do
        emit(tag, "external_rules." .. er.name, SL.yn(er.value)) end
    for _, eo in ipairs(mt.external_rule_overrides or {}) do
        emit(tag, "external_rules.override." .. tostring(eo.idx), eo.value) end

    -- ===== collaboration =====
    for _, cl in ipairs(mt.collaborations or {}) do
        emit(tag, "collaboration.collaboration." .. cl.tag .. ".value",
            SL.num(cl.value)) end

    -- ===== buildings (reader §28.6) =====
    do
        local okb, bd = pcall(function() return c:country_buildings() end)
        if okb and bd and bd.list then
            for _, b in ipairs(bd.list) do
                if b.name then
                    local kp = "buildings." .. b.name .. "."
                    emit(tag, kp .. "level", SL.num(b.level or 0))
                    if b.partial and b.partial ~= 1 then
                        emit(tag, kp .. "partial_health", SL.num(b.partial)) end
                    emit(tag, kp .. "healthy_levels", SL.num(b.healthy or 0)) end
            end
        end
    end

    -- ===== operative_codenames_tracker (mode 3) =====
    do
        local okr, r = pcall(function() return c:name_groups(3) end)
        if okr and r then
            local prefix = "operative_codenames_tracker"
            for li, nm in ipairs(r.unavailable or {}) do
                local q = SL.Q(nm)
                if q then
                    emit(tag, prefix .. ".unavailable_groups.#" .. li, q) end
            end
            for li, nm in ipairs(r.available or {}) do
                local q = SL.Q(nm)
                if q then
                    emit(tag, prefix .. ".available_groups.#" .. li, q) end
            end
            local seqp = SL.seqc()
            for _, pm in ipairs(r.post_mortem and r.post_mortem.list or {}) do
                local blk = seqp(prefix .. ".post_mortem")
                emit(tag, blk .. ".type", SL.num(pm.type))
                if pm.name_order then
                    emit(tag, blk .. ".name_order", SL.num(pm.name_order)) end
                if pm.is_name_ordered then
                    emit(tag, blk .. ".is_name_ordered", pm.is_name_ordered) end
                local ov = SL.Q(pm.override)
                if ov then emit(tag, blk .. ".override", ov) end
                if pm.override_set_programmatically then
                    emit(tag, blk .. ".override_set_programmatically",
                        pm.override_set_programmatically) end
                if pm.equipment then
                    emit(tag, blk .. ".equipment", pm.equipment) end
            end
        end
    end

    -- ===== 散标量 (combat_support_scalars reader; ≠0 门 = writer 门) =====
    if mt.original_research_slots then
        emit(tag, "original_research_slots",
            SL.num(mt.original_research_slots)) end
    local css = c and c:combat_support_scalars() or {}
    if (css.num_ships or 0) ~= 0 then
        emit(tag, "num_ships", tostring(css.num_ships)) end
    if (css.num_armies_in_combat or 0) ~= 0 then
        emit(tag, "num_armies_in_combat",
            tostring(css.num_armies_in_combat)) end
    if (css.num_ships_in_combat or 0) ~= 0 then
        emit(tag, "num_ships_in_combat",
            tostring(css.num_ships_in_combat)) end
    if (css.convoys_destroyed or 0) ~= 0 then
        emit(tag, "convoys_destroyed", tostring(css.convoys_destroyed)) end
    if mt.major then emit(tag, "major", "yes") end
    if mt.is_major then emit(tag, "is_major", "yes") end
    if mt.is_top_ic_country then emit(tag, "is_top_ic_country", "yes") end
    if mt.landlocked_start then emit(tag, "landlocked_start", "yes") end
    if mt.reserved_dynamic_country then
        emit(tag, "reserved_dynamic_country", "yes") end
    if mt.coastal_protection_ratio then
        emit(tag, "coastal_protection_ratio",
            SL.num(mt.coastal_protection_ratio)) end
    for _, kv in ipairs({
        { "propaganda_stability_penalty", css.propaganda_stability_penalty },
        { "being_bombed_support_penalty", css.being_bombed_support_penalty },
        { "heroes_dying_war_support_penalty",
            css.heroes_dying_war_support_penalty },
        { "convoy_raiding_war_support_penalty",
            css.convoy_raiding_war_support_penalty },
        { "propaganda_war_support_penalty",
            css.propaganda_war_support_penalty } }) do
        if kv[2] and kv[2] ~= 0 then
            emit(tag, kv[1], SL.num(kv[2])) end
    end
    do -- last_collaborated_surrender_recipient i32 >0 → 引号 tag
        local lid = css.last_collaborated
        if lid and lid > 0 and lid < 0x80000000 then
            local s = qt(O:tag(lid))
            if s and s ~= '""' and s ~= '"---"' then
                emit(tag, "last_collaborated_surrender_recipient", s) end
        end
    end
end }
