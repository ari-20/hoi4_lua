-- sv2_sec_c_program_status.lua -- country.program_status 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Country.program_status
--  objects_economy §4.7.9 CSpecialProjectStatus cc+4008)

SV2.csec[#SV2.csec + 1] = { name = "country.program_status", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local O = ctx.O
    -- §4.7.9 CSpecialProjectStatus (cc+4008)
    local r = c:program_status()
    if not r then return end

    -- 池回填/资源已上提 reader (extra_by_index / resources)。
    -- ⚠ extra 按**容器下标**索引 (非 name_token): 同名 project 可重复
    -- (sp_naval_ice_carrier 每国两条), 按名索引会互相覆盖 → 首条错拿
    -- 次条的 program 对; 两处走池顺序一致 (均为 d + 448*k), 下标可对齐。
    local extra = r.extra_by_index or {}
    -- resources (池内嵌 CStrategicResourcePool)
    for _, rr in ipairs(r.resources or {}) do
        emit(tag,
            "program_status.project_pool.resources." .. rr.name,
            SL.num(rr.value))
    end

    -- project_pool (键控项目名, 跨项目序不敏感; #N 序 = 容器序 = 写序)
    -- 同名 project 允许重复 → 按名 seqc 编号: 首现裸名 / 重复 [N]
    -- (与 save 侧提取器同法)
    -- §4.7.9 CSpecialProject (project_pool 元素)
    local pseq = SL.seqc()
    for pi, pj in ipairs(r.pool and r.pool.list or {}) do
        local nm = SL.tok(pj.name_token)
        if nm then
            local base = "program_status.project_pool.project." .. pseq(nm)
            local ex = extra[pi - 1]
            emit(tag, base .. ".id", SL.idpair(pj.id, ex and ex.idtype or 86))
            emit(tag, base .. ".progress.current_state",
                SL.num(pj.current_state))
            emit(tag, base .. ".progress.prototype_state.project_progress",
                SL.num(pj.project_progress))
            emit(tag, base .. ".progress.prototype_state.iterations",
                SL.num(pj.iterations))
            emit(tag, base .. ".progress.prototype_state.phase_progress",
                SL.num(pj.phase_progress))
            emit(tag, base .. ".progress.stopping_state.phase_progress",
                SL.num(pj.phase_progress_stopping))
            emit(tag, base .. ".start", SL.yn(pj.start))
            emit(tag, base .. ".completed", SL.yn(pj.completed))
            if ex and ex.prog then
                emit(tag, base .. ".program",
                    SL.idpair(ex.prog.id, ex.prog.type))
            end
            for fi, ft in ipairs(pj.fire_only_once or {}) do
                emit(tag, base .. ".fire_only_once.#" .. fi, tostring(ft))
            end
            for hi, he in ipairs(pj.history or {}) do
                local hb = base .. ".history.#" .. hi
                emit(tag, hb .. ".context.province", SL.num(he.prov))
                if he.cid then -- writer: 无效 id 对象不写 character 键
                    emit(tag, hb .. ".context.character",
                        SL.idpair(he.cid, he.ctype))
                end
                emit(tag, hb .. ".context.progress", SL.num(he.cprog))
                if he.country then
                    emit(tag, hb .. ".context.country", SL.num(he.country))
                end
                if he.scientist then
                    emit(tag, hb .. ".context.scientist", SL.num(he.scientist))
                end
                if he.state then
                    emit(tag, hb .. ".context.state", SL.num(he.state))
                end
                emit(tag, hb .. ".option", tostring(he.option))
                emit(tag, hb .. ".prototype_reward",
                    tostring(he.prototype_reward))
                local hd = SL.date(he.hours)
                if hd then emit(tag, hb .. ".date", '"' .. hd .. '"') end
            end
            for _, fe in ipairs(pj.flags or {}) do
                local fb = base .. ".flags." .. tostring(fe.name)
                emit(tag, fb .. ".value", SL.num(fe.value))
                local fd = SL.date(fe.hours)
                if fd then emit(tag, fb .. ".date", '"' .. fd .. '"') end
            end
        end
    end

    -- breakthrough (RB-tree 中序; 键各异性序不敏感)
    for _, be in ipairs(r.breakthrough and r.breakthrough.list or {}) do
        local spec = tostring(SL.tok(be.spec_id))
        while spec:match("^specialization_") do -- 剥 DB 双重前缀
            spec = spec:gsub("^specialization_", "", 1)
        end
        emit(tag, "program_status.breakthrough.specialization_" .. spec,
            SL.num(be.value))
    end

    -- program 进行中实例 (重复键 seqc; 序 = 容器序)
    -- §4.7.9 CSpecialProjectStatus (program 实例)
    local seq = SL.seqc()
    for _, pg in ipairs(r.programs or {}) do
        local k = seq("program_status.program")
        emit(tag, k .. ".id", SL.idpair(pg.id, pg.id_type))
        local ctag = pg.country_tag_id and O:tag(pg.country_tag_id) or nil
        local cq = SL.Q(ctag)
        if cq then emit(tag, k .. ".country", cq) end
        emit(tag, k .. ".province", SL.num(pg.province))
        if pg.project_token then
            emit(tag, k .. ".project", tostring(SL.tok(pg.project_token)))
        end
        local sc = pg.scientist
        if sc and ((sc.type or 0) > 0 or (sc.id or 0) > 0) then
            -- scientist 块整体仅有效科学家时写 (含 delayed_unassigned 子块)
            emit(tag, k .. ".scientist.scientist", SL.idpair(sc.id, sc.type))
            local du = pg.delayed_unassigned or {}
            emit(tag, k .. ".scientist.delayed_unassigned_scientist.target",
                SL.num(du.target))
            emit(tag, k .. ".scientist.delayed_unassigned_scientist.current",
                SL.num(du.current))
            emit(tag, k .. ".scientist.delayed_unassigned_scientist.timed",
                "no") -- timed 恒 no (mem 无对应字段)
        end
        for ssi, ss in ipairs(pg.supportive_scientists or {}) do
            local sb = k .. ".supportive_scientist.#" .. ssi
            emit(tag, sb .. ".scientist", SL.idpair(ss.id, ss.type))
            emit(tag, sb .. ".delayed_unassigned_scientist.target",
                SL.num(ss.target))
            emit(tag, sb .. ".delayed_unassigned_scientist.current",
                SL.num(ss.current))
            emit(tag, sb .. ".delayed_unassigned_scientist.timed", "no")
        end
        local dm = pg.dismantle or {}
        emit(tag, k .. ".delayed_dismantle_facility.target",
            SL.num(dm.target))
        emit(tag, k .. ".delayed_dismantle_facility.current",
            SL.num(dm.current))
        emit(tag, k .. ".delayed_dismantle_facility.timed", "no")
        local sup = pg.supply
        if sup then
            local stag = sup.tag_id and O:tag(sup.tag_id) or nil
            local sq = SL.Q(stag)
            if sq then emit(tag, k .. ".supply.tag", sq) end
            emit(tag, k .. ".supply.province_id", SL.num(sup.province_id))
            emit(tag, k .. ".supply.id", SL.idpair(sup.id, sup.id_type))
            emit(tag, k .. ".supply.motorization_level",
                SL.num(sup.motorization_level))
        end
        local bq = SL.Q(pg.building)
        if bq then emit(tag, k .. ".building", bq) end
        emit(tag, k .. ".unread_prototype_rewards",
            SL.num(pg.unread_prototype_rewards))
    end
end }
