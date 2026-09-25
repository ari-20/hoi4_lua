-- sv2_sec_c_theatres.lua -- country.theatres 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Country:theatres_full, objects_economy §4.24
-- 尾); 本段只持写序/块键/[N] 编号/值格式化。

SV2.csec[#SV2.csec + 1] = { name = "country.theatres", emit = function(ctx)
    local emit, tag, O, i = ctx.emit, ctx.tag, ctx.O, ctx.i
    if not ctx.cc then return end
    local SL = SV2.lib
    local okc, cp = pcall(O.country, O, i)
    local ok, ths = pcall(function() return cp and cp:theatres_full() end)
    if not ok or not ths then return end

    -- 值格式化糖 (tag/串 reader 已解析, 此处只加引号)
    local function yn1(v) return (v == 1) and "yes" or "no" end
    local function join_u32(t)
        local out = {}
        for _, v in ipairs(t) do out[#out + 1] = tostring(v) end
        return table.concat(out, " ")
    end
    local function join_num(t)
        local out = {}
        for _, v in ipairs(t) do out[#out + 1] = SL.num(v) end
        return table.concat(out, " ")
    end
    local function E(path, val)
        if val ~= nil then emit(tag, path, val) end
    end

    -- ===== §4.24.5 COrderInstance =====
    local emit_oi
    emit_oi = function(oipath, oi)
        if not oi then return end
        if oi.convoys then -- convoys 块先于 type (CConvoySubscriber@+8)
            E(oipath .. ".convoys.convoys", tostring(oi.convoys.convoys))
            E(oipath .. ".convoys.total", tostring(oi.convoys.total)) end
        E(oipath .. ".type", tostring(oi.otype))
        if oi.path then E(oipath .. ".path", join_u32(oi.path)) end
        if oi.states then E(oipath .. ".states", join_u32(oi.states)) end
        E(oipath .. ".instance_id", tostring(oi.instance_id))
        if oi.virtual_order then E(oipath .. ".virtual_order", "yes") end
        if oi.virtual_creator then
            E(oipath .. ".virtual_creator", tostring(oi.virtual_creator)) end
        if oi.creation_h then
            E(oipath .. ".creation_date", SL.date_quoted(oi.creation_h)) end
        if oi.starting_h then
            E(oipath .. ".starting_date", SL.date_quoted(oi.starting_h)) end
        if oi.virtually_created then
            E(oipath .. ".virtually_created", join_u32(oi.virtually_created))
        end
        local function sso_key(key, s)
            if s then E(oipath .. "." .. key, '"' .. s .. '"') end
        end
        sso_key("operation", oi.operation)
        sso_key("unique", oi.unique)
        sso_key("first", oi.first)
        sso_key("second", oi.second)
        sso_key("prefix", oi.prefix)
        sso_key("postfix", oi.postfix)
        if oi.floating_harbor then
            E(oipath .. ".floating_harbor",
                SL.idpair(oi.floating_harbor.id, oi.floating_harbor.type))
            if oi.floating_harbor_hp then
                E(oipath .. ".floating_harbor_hp",
                    SL.num(oi.floating_harbor_hp * 1e-5)) end
        end
        if oi.sorted_pairs then
            E(oipath .. ".sorted_pairs", join_u32(oi.sorted_pairs))
            E(oipath .. ".sorted_pairs_from",
                tostring(oi.sorted_pairs_from))
            E(oipath .. ".sorted_pairs_to", tostring(oi.sorted_pairs_to)) end
        if oi.enemy_controller_area then
            E(oipath .. ".enemy_controller_area",
                tostring(oi.enemy_controller_area)) end
        if oi.can_execute then
            E(oipath .. ".can_execute", tostring(oi.can_execute)) end
        for _, m in ipairs(oi.scheduled_members or {}) do
            E(oipath .. ".scheduled_member", SL.idpair(m.id, m.type)) end
        for _, m in ipairs(oi.transported_members or {}) do
            E(oipath .. ".transported_member", SL.idpair(m.id, m.type)) end
        if oi.all_transported_members then
            E(oipath .. ".all_transported_members",
                tostring(oi.all_transported_members)) end
        for _, v in ipairs(oi.order_children or {}) do
            E(oipath .. ".order_children", tostring(v)) end
        for _, v in ipairs(oi.order_virtual_children or {}) do
            E(oipath .. ".order_virtual_children", tostring(v)) end
        if oi.invasion_source then
            E(oipath .. ".invasion_source", tostring(oi.invasion_source)) end
        if oi.blitz then
            E(oipath .. ".blitz", "yes")
            if oi.blitz_provinces then
                E(oipath .. ".blitz_provinces",
                    join_u32(oi.blitz_provinces)) end
        end
        if oi.withdraw then
            E(oipath .. ".withdraw", "yes")
            if oi.withdraw_lines then
                for wi = 1, oi.withdraw_lines_n do
                    local t = oi.withdraw_lines[wi]
                    if t then
                        E(oipath .. ".withdraw_lines.#" .. wi,
                            join_u32(t)) end
                end
            end
        end
        if oi.root_front then
            E(oipath .. ".root_front",
                SL.idpair(oi.root_front.id, oi.root_front.type))
            if oi.root_section then
                E(oipath .. ".root_section", tostring(oi.root_section)) end
            if oi.root_from or oi.root_to then
                E(oipath .. ".from", SL.num(oi.root_from))
                E(oipath .. ".to", SL.num(oi.root_to)) end
            if oi.split_from then
                E(oipath .. ".split_from", tostring(oi.split_from)) end
        end
        if oi.midpoints then
            E(oipath .. ".midpoints", join_u32(oi.midpoints)) end
        if oi.fallback then E(oipath .. ".fallback", "yes") end
        if oi.time then E(oipath .. ".time", SL.num(oi.time)) end
        if oi.area_defense_settings then
            E(oipath .. ".area_defense_settings",
                tostring(oi.area_defense_settings)) end
        for _, t in ipairs(oi.area_defense or {}) do
            E(oipath .. ".area_defense_state_assignment", join_u32(t)) end
        if oi.route_is_ok then E(oipath .. ".route_is_ok", "yes") end
        if oi.attach then
            E(oipath .. ".attach",
                SL.idpair(oi.attach.id, oi.attach.type)) end
        E(oipath .. ".manage_child_sections", yn1(oi.manage_child_sections))
        if oi.faction_theaters then
            E(oipath .. ".faction_theaters", join_num(oi.faction_theaters))
        end
    end

    -- ===== §4.24.3 COrdersGroup / §4.24.4 CArmyGroup =====
    local function emit_og(ogpath, og)
        if not og then return end
        if og.sub_orders_groups then -- CArmyGroup 先写子 og 引用 + collapse
            for _, sg in ipairs(og.sub_orders_groups) do
                E(ogpath .. ".orders_group",
                    SL.idpair(sg.id, sg.type)) end
            if og.collapse then E(ogpath .. ".collapse", "yes") end
        end
        E(ogpath .. ".id", SL.idpair(og.id_id, og.id_type))
        if og.name then E(ogpath .. ".name", '"' .. og.name .. '"') end
        local oiseq = SL.seqc()
        for _, oi in ipairs(og.order_instances or {}) do
            emit_oi(ogpath .. "." .. oiseq("order_instance"), oi) end
        local fseq = SL.seqc()
        for _, oi in ipairs(og.fallbacks or {}) do
            emit_oi(ogpath .. "." .. fseq("fallback"), oi) end
        local vseq = SL.seqc()
        for _, oi in ipairs(og.virtual_fallbacks or {}) do
            emit_oi(ogpath .. "." .. vseq("virtual_fallback"), oi) end
        local mseq = SL.seqc()
        for _, m in ipairs(og.members or {}) do
            E(ogpath .. "." .. mseq("member") .. ".unit",
                SL.idpair(m.id, m.type)) end
        if og.leader_unit then
            E(ogpath .. ".leader_unit",
                SL.idpair(og.leader_unit.id, og.leader_unit.type)) end
        if og.leader then
            E(ogpath .. ".leader", SL.idpair(og.leader.id, og.leader.type)) end
        if og.pending_incoming_leader then
            E(ogpath .. ".pending_incoming_leader",
                SL.idpair(og.pending_incoming_leader.id,
                    og.pending_incoming_leader.type)) end
        if og.color then -- color 恒写: (int)(f*255) 截断
            local vals = string.format("%d %d %d", og.color[1], og.color[2],
                og.color[3])
            if og.color_a then
                vals = vals .. string.format(" %d", og.color_a) end
            E(ogpath .. ".color", vals) end
        E(ogpath .. ".icon", tostring(og.icon))
        if og.split_from then
            E(ogpath .. ".split_from",
                SL.idpair(og.split_from.id, og.split_from.type)) end
        if og.deployed then E(ogpath .. ".deployed", "yes") end
        if og.deploy_queued then E(ogpath .. ".deploy_queued", "yes") end
        if og.expeditionaries then E(ogpath .. ".expeditionaries", "yes") end
        if og.hq then
            local hq = og.hq
            local hp = ogpath .. ".hq_deploy_distributable"
            if hq.priority then
                E(hp .. ".priority", tostring(hq.priority)) end
            if hq.country then
                E(hp .. ".country", '"' .. hq.country .. '"') end
            do -- §4.24.10 hq_assembled_equipment
                local ap = hp .. ".hq_assembled_equipment"
                if hq.assembled_equipment then
                    local eseq = SL.seqc()
                    for _, eq in ipairs(hq.assembled_equipment) do
                        local ep = ap .. "." .. eseq("equipment")
                        if eq.id then
                            E(ep .. ".id", SL.idpair(eq.id, eq.type)) end
                        E(ep .. ".amount", SL.num(eq.amount))
                    end
                end
                E(ap .. ".allow_zero_entries", yn1(hq.equipment_az))
            end
            if hq.requested_equipment then
                for _, rq in ipairs(hq.requested_equipment) do
                    E(hp .. ".hq_requested_equipment." .. rq.name,
                        SL.num(rq.amount)) end
            end
            E(hp .. ".hq_assembled_manpower",
                tostring(hq.assembled_manpower))
            E(hp .. ".hq_requested_manpower", tostring(hq.requested_manpower))
            E(hp .. ".hq_deploy_order", tostring(hq.deploy_order))
            E(hp .. ".hq_requisitioned_from_army",
                yn1(hq.requisitioned_from_army))
        end
        if og.target_template then
            E(ogpath .. ".target_template",
                SL.idpair(og.target_template.id, og.target_template.type)) end
        if og.withdrawing then E(ogpath .. ".withdrawing", "yes") end
        if og.unassign_on_withdraw then
            E(ogpath .. ".unassign_on_withdraw", "yes") end
        if og.training then E(ogpath .. ".training", "yes") end
        if og.stop_training_at_max_xp then
            E(ogpath .. ".stop_training_at_max_xp", "yes") end
        E(ogpath .. ".plan_value", SL.num(og.plan_value))
        E(ogpath .. ".our_power", SL.num(og.our_power))
        E(ogpath .. ".enemy_power", SL.num(og.enemy_power))
        if og.members_has_changed then
            E(ogpath .. ".members_has_changed", "yes") end
        E(ogpath .. ".execution_type", tostring(og.execution_type))
        E(ogpath .. ".cohesion_type", tostring(og.cohesion_type))
        E(ogpath .. ".proximity_type", tostring(og.proximity_type))
        E(ogpath .. ".field_marshal_group", yn1(og.field_marshal_group))
        E(ogpath .. ".motorization_level", tostring(og.motorization_level))
        local function i32_ge0(key, v) -- i32>=0 才写
            if v then E(ogpath .. "." .. key, tostring(v)) end end
        i32_ge0("distance", og.distance)
        i32_ge0("hq_nearest_front_province_id",
            og.hq_nearest_front_province_id)
        i32_ge0("hq_distance_to_naval_invasion_source",
            og.hq_distance_to_naval_invasion_source)
        i32_ge0("cached_hq_naval_invasion_source_province_id",
            og.cached_hq_naval_invasion_source_province_id)
        if og.timeout_days then
            E(ogpath .. ".timeout_days", tostring(og.timeout_days)) end
    end

    -- ===== §4.24.7 CFrontSection =====
    local function emit_section(spath, sec)
        if not sec then return end
        E(spath .. ".id", tostring(sec.id))
        if sec.provinces then
            E(spath .. ".provinces.#1", join_u32(sec.provinces)) end
        if sec.sorted_pairs then
            E(spath .. ".sorted_pairs.#1", join_u32(sec.sorted_pairs)) end
        local pseq = SL.seqc()
        for _, pcs in ipairs(sec.per_country_sections or {}) do
            local p = spath .. "." .. pseq("per_country_section")
            E(p .. ".country", '"' .. pcs.country .. '"')
            E(p .. ".index", tostring(pcs.index))
            E(p .. ".count", tostring(pcs.count)) end
    end

    -- ===== §4.24.6 CFront =====
    local function emit_front(fpath, fr)
        if not fr then return end
        E(fpath .. ".id", SL.idpair(fr.id_id, fr.id_type))
        E(fpath .. ".dirty", yn1(fr.dirty))
        if fr.provinces then
            E(fpath .. ".provinces.#1", join_u32(fr.provinces)) end
        if fr.enemies then
            for ei = 1, fr.enemies_n do
                local tstr = fr.enemies[ei]
                if tstr then
                    E(fpath .. ".enemies.#" .. ei, '"' .. tstr .. '"') end
            end
        end
        E(fpath .. ".id_counter", tostring(fr.id_counter))
        local sseq = SL.seqc()
        for _, sec in ipairs(fr.sections or {}) do
            emit_section(fpath .. "." .. sseq("section"), sec) end
        if fr.area then E(fpath .. ".area", tostring(fr.area)) end
    end

    -- ===== §4.24.8 CTheaterGroup =====
    local function emit_tg(tgpath, tg)
        if not tg then return end
        E(tgpath .. ".id", SL.idpair(tg.id_id, tg.id_type))
        E(tgpath .. ".priority", tostring(tg.priority))
        E(tgpath .. ".name", '"' .. (tg.name or "") .. '"')
        for _, og in ipairs(tg.orders_groups or {}) do
            E(tgpath .. ".orders_group", SL.idpair(og.id, og.type)) end
    end

    -- ===== §4.24.2 CTheatre 顶层 =====
    local thseq = SL.seqc()
    for _, th in ipairs(ths) do
        local tp = "theatres." .. thseq("theatre")
        E(tp .. ".id", SL.idpair(th.id_id, th.id_type))
        if th.areas then E(tp .. ".area.#1", join_u32(th.areas)) end
        local ogseq = SL.seqc()
        for _, og in ipairs(th.orders_groups or {}) do
            emit_og(tp .. "." .. ogseq("orders_group"), og) end
        local fseq = SL.seqc()
        for _, ag in ipairs(th.field_marshal_groups or {}) do
            emit_og(tp .. "." .. fseq("field_marshal_group"), ag) end
        local gseq = SL.seqc()
        for _, tg in ipairs(th.theater_groups or {}) do
            emit_tg(tp .. "." .. gseq("theater_group"), tg) end
        for _, u in ipairs(th.units or {}) do
            E(tp .. ".unit", SL.idpair(u.id, u.type)) end
        local frseq = SL.seqc()
        for _, fr in ipairs(th.fronts or {}) do
            emit_front(tp .. "." .. frseq("front"), fr) end
        if th.volunteers_theatre then
            E(tp .. ".volunteers_theatre",
                '"' .. th.volunteers_theatre .. '"') end
    end
end }
