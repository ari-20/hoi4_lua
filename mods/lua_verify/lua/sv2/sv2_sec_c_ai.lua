-- sv2_sec_c_ai.lua -- country.ai 节点 savefull 直出 (csec)
-- 结构/走查唯一实现 = reader (Country:ai_strategy / Country:ai_state,
-- objects_global §33.13/33.14); 本段只持 writer 发射规则
-- (写序/块门/编号/值格式, 含 ai_strategy 槽 9/16/21 的 token 名放行门)。

SV2.csec[#SV2.csec + 1] = { name = "country.ai", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local oka, strat = pcall(function() return c:ai_strategy() end)
    local oks, st = pcall(function() return c:ai_state() end)
    if not oka or not oks then return end

    local function tagof(tid)   -- tag_id → 三字串 (>0 才写)
        if not (tid and tid > 0) then return nil end
        local s = ctx.O:tag(tid)
        if s and s ~= "" then return s end
        return nil
    end
    -- ===== §4.34.11 双 112 槽数组 =====
    -- 槽 9/16/21 (0x210200 bits) 的 id 走 token 名 (放宽收 CamelCase),
    -- 其余槽 id 原样数字 = writer 门; value 已由 reader 转带符号
    local TOK_SLOT = { [9] = true, [16] = true, [21] = true }
    local function emit_group(groups, path, use_tok)
        for _, g in ipairs(groups or {}) do
            for _, e in ipairs(g.list) do
                local ids
                if use_tok and TOK_SLOT[g.type] then
                    local nm = e.id_name
                    if type(nm) == "string"
                        and nm:match("^[%a_][%w_]*$") then
                        ids = nm
                    else
                        ids = tostring(e.id)
                    end
                else
                    ids = tostring(e.id)
                end
                local line = "type=" .. g.type .. " id=" .. ids
                if (e.target or 0) ~= 0 then
                    line = line .. " target=" .. e.target
                end
                line = line .. " value=" .. e.value
                emit(tag, path, line)
            end
        end
    end
    emit_group(strat.ai_strategy, "ai.ai_strategy", true)          -- A: 0x3100
    emit_group(strat.persistent_strategy, "ai.persistent_strategy", false) -- B: 0x3A32

    -- ===== §4.3.19 military_access (ptr 有效才写, 全零也写) =====
    -- ⚠ 段历史行为: 国家数界坏时**整段中止** (后续标量全不发), 原样保留
    local ma = st.military_access or {}
    if ma.ptr_valid then
        local n = ma.count or 0
        if n <= 0 or n > 65536 then return end
        local t = {}
        for i = 1, n do t[i] = tostring(ma.values[i] or 0) end
        emit(tag, "ai.military_access.#1", table.concat(t, " "))
    end

    -- ===== §4.3.19 CStrategicAI 标量簇 (恒写) =====
    emit(tag, "ai.days_until_next_rebuild_access_list",
        tostring(st.days_until_next_rebuild_access_list or 0))
    emit(tag, "ai.days_to_need_update", tostring(st.days_to_need_update or 0))
    emit(tag, "ai.seed", string.format("%d %d",
        st.seed[1] or 0, st.seed[2] or 0))
    emit(tag, "ai.irrationality", tostring(st.irrationality))
    emit(tag, "ai.pp_spend_priority", tostring(st.pp_spend_priority or 0))
    emit(tag, "ai.pp_spend_amount.#1", string.format("%s %s",
        SL.num(st.pp_spend_amount[1]), SL.num(st.pp_spend_amount[2])))
    emit(tag, "ai.num_wanted_divisions", tostring(st.num_wanted_divisions))
    for _, key in ipairs{
        "desire_unlock_land_doctrine", "desire_unlock_naval_doctrine",
        "desire_unlock_air_doctrine", "desire_update_land_template",
        "desire_upgrade_land_equipment", "desire_upgrade_naval_equipment",
        "desire_upgrade_air_equipment", "desire_unlock_army_spirit",
        "desire_unlock_navy_spirit", "desire_unlock_air_spirit",
        "reserved_xp_land_research", "reserved_xp_naval_research",
        "reserved_xp_air_research" } do
        emit(tag, "ai." .. key, SL.num(st[key]))
    end

    -- ===== §4.34.11 allowed_strategy_plans (count>0 且有非空串才写) =====
    do
        local plans = {}
        for _, s in ipairs(st.allowed_strategy_plans or {}) do
            if s and s ~= "" then plans[#plans + 1] = s end
        end
        if #plans > 0 then
            emit(tag, "ai.allowed_strategy_plans.#1",
                table.concat(plans, " "))
        end
    end

    -- ===== §4.3.19 force_concentration_target =====
    local fseq = SL.seqc()
    for _, e in ipairs(st.force_concentration_target or {}) do
        local fb = "ai." .. fseq("force_concentration_target") .. "."
        emit(tag, fb .. "target", tostring(e.target or 0))
        emit(tag, fb .. "from", tostring(e.from or 0))
        emit(tag, fb .. "progress", SL.num(e.progress))
    end

    -- ===== §4.3.19 expeditionary_force_data =====
    local eseq = SL.seqc()
    for _, e in ipairs(st.expeditionary_force_data or {}) do
        local eb = "ai." .. eseq("expeditionary_force_data") .. "."
        local t = tagof(e.tag_tid)
        if t then emit(tag, eb .. "tag", '"' .. t .. '"') end
        emit(tag, eb .. "casualties", tostring(e.casualties or 0))
        emit(tag, eb .. "do_not_send_forces", SL.yn(e.do_not_send or 0))
        emit(tag, eb .. "pull_forces_back", SL.yn(e.pull_back or 0))
        if e.date_h and e.date_h ~= 43808760 then
            local ds = SL.date(e.date_h)
            if ds then emit(tag, eb .. "date", '"' .. ds .. '"') end
        end
    end

    -- ===== §4.3.19 ai.raids (target 内层 SRaidTarget = §4.27) =====
    local rseq = SL.seqc()
    for _, e in ipairs(st.raids or {}) do
        local rb = "ai." .. rseq("raids") .. "."
        local tnm = GAME.layout.token_name(e.type_tok or 0)
        if tnm and tnm ~= "" then emit(tag, rb .. "type", tnm) end
        if e.bld_template_tok then
            local tn2 = GAME.layout.token_name(e.bld_template_tok)
            if tn2 and tn2 ~= "" then
                emit(tag, rb .. "target.building.template", tn2)
            end
        end
        if e.bld_state then
            emit(tag, rb .. "target.building.location",
                tostring(e.bld_state))
        end
        if e.province then
            emit(tag, rb .. "target.province", tostring(e.province))
        end
        if e.state then
            emit(tag, rb .. "target.state", tostring(e.state))
        end
        if (e.leader_type or 0) ~= 0 or (e.leader_id or 0) ~= 0 then
            emit(tag, rb .. "target.leader",
                SL.idpair(e.leader_id, e.leader_type))
        end
        if e.leader_province then
            emit(tag, rb .. "target.leader_province",
                tostring(e.leader_province))
        end
        local ds = SL.date(e.end_date_h)
        if ds then emit(tag, rb .. "end_date", '"' .. ds .. '"') end
    end

    -- ===== §4.3.19 failed_naval_invasions =====
    local nseq = SL.seqc()
    for _, e in ipairs(st.failed_naval_invasions or {}) do
        local nb = "ai." .. nseq("failed_naval_invasions") .. "."
        if e.province then
            emit(tag, nb .. "province", tostring(e.province))
        end
        if e.has_orders then
            local tl = {}
            for j, v in ipairs(e.order_ids) do tl[j] = tostring(v) end
            emit(tag, nb .. "invasion_order_ids.#1", table.concat(tl, " "))
        end
        local ds = SL.date(e.date_h)
        if ds then emit(tag, nb .. "invasion_date", '"' .. ds .. '"') end
    end

    -- ===== §4.3.19 recently_invaded_areas (count>0 才写; [N] 首现不编) =====
    local seq = SL.seqc()
    for _, e in ipairs(st.recently_invaded_areas or {}) do
        local blk = seq("recently_invaded_areas")
        emit(tag, "ai." .. blk .. ".province",
            tostring(e.province or 0))
        if #e.order_ids > 0 then
            local tl = {}
            for j, v in ipairs(e.order_ids) do tl[j] = tostring(v) end
            emit(tag, "ai." .. blk .. ".invasion_order_ids.#1",
                table.concat(tl, " "))
        end
        local ds = SL.date(e.date_h)
        if ds then
            emit(tag, "ai." .. blk .. ".invasion_date", '"' .. ds .. '"')
        end
    end
end }
