-- sv2_sec_c_deployment.lua -- country.deployment 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Country.unlocked_subunits /
--  deployment_hq / deployment_unit_modifiers(含 nested+icaw) /
--  deployment_conveyors, objects_misc §30 §4.18/§4.18.11/§4.18.12)
SV2.csec[#SV2.csec + 1] = { name = "country.deployment", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local P = "deployment."

    -- ===== §4.18 CDeployment unlocked_subunits.#N (std::set 中序 = 写序) =====
    local ok1, usu = pcall(function() return c:unlocked_subunits() end)
    if ok1 then
        for ui, uu in ipairs(usu and usu.list or {}) do
            if uu.name then
                emit(tag, P .. "unlocked_subunits.#" .. ui,
                    uu.name .. (uu.unlocked and " yes" or " no"))
            end
        end
    end

    -- ===== §4.18 CDeployment default_hq_template / hq_next_deploy_order =====
    local ok2, hq = pcall(function() return c:deployment_hq() end)
    if ok2 and hq then
        if hq.default_hq_id then
            emit(tag, P .. "default_hq_template", SL.idpair(
                hq.default_hq_id, hq.default_hq_type))
        end
        if hq.hq_next_deploy_order then
            emit(tag, P .. "hq_next_deploy_order",
                SL.num(hq.hq_next_deploy_order))
        end
    end

    -- ===== unit_modifiers.#N (§4.18.11 CSubunitBonusPersistent;
    -- 头三叶/修饰值/嵌套类别块/ICAW 全部 reader 供数) =====
    local ok3, dum = pcall(function() return c:deployment_unit_modifiers() end)
    if ok3 and dum then
        for k, rec in ipairs(dum.list or {}) do
            local B = P .. "unit_modifiers.#" .. k .. "."
            emit(tag, B .. "type", tostring(rec.type_name))
            emit(tag, B .. "number", SL.num(rec.number or 0))
            if rec.id_name then
                emit(tag, B .. "id", tostring(rec.id_name))
            end
            for _, mv in ipairs(rec.mods or {}) do
                emit(tag,
                    B .. tostring(mv.target) .. "."
                    .. tostring(mv.name),
                    SL.num(mv.value))
            end
            -- 嵌套块 (battalion_mult / 地形 / 动态地形 / need_equipment)
            for _, nd in ipairs(rec.nested or {}) do
                local CB2 = B .. tostring(nd.cat) .. "."
                local bmseq = SL.seqc()
                for _, bm in ipairs(nd.battalion_mult or {}) do
                    local BK = CB2 .. bmseq("battalion_mult") .. "."
                    if bm.category then
                        emit(tag, BK .. "category", bm.category) end
                    emit(tag, BK .. "add", SL.yn(bm.add or 0))
                    emit(tag, BK .. "display_as_percentage",
                        SL.yn(bm.display_as_percentage or 0))
                    for _, st in ipairs(bm.stats or {}) do
                        emit(tag, BK .. st.name, SL.num(st.value))
                    end
                end
                for _, tn in ipairs(nd.terrains or {}) do
                    local TK = CB2 .. tostring(tn.name) .. "."
                    if (tn.attack or 0) ~= 0 then
                        emit(tag, TK .. "attack", SL.num(tn.attack)) end
                    if (tn.defence or 0) ~= 0 then
                        emit(tag, TK .. "defence", SL.num(tn.defence)) end
                    if (tn.movement or 0) ~= 0 then
                        emit(tag, TK .. "movement", SL.num(tn.movement)) end
                end
                for _, ne in ipairs(nd.need_equipment or {}) do
                    emit(tag, CB2 .. "need_equipment."
                        .. tostring(ne.name), SL.num(ne.value))
                end
            end
        end
        -- ===== §4.18 CDeployment ICAW (内嵌 @dep+240, 空壳门 reader 判) =====
        for _, iw in ipairs(dum.icaw or {}) do
            emit(tag,
                P .. "initial_carrier_air_wing_deployment."
                .. tostring(iw.name),
                SL.num(iw.value))
        end
    end

    -- ===== §4.18.12 conveyor/line 全链 military_deployment_conveyor[N] =====
    local ok4, dcx = pcall(function() return c:deployment_conveyors() end)
    if not (ok4 and dcx) then return end
    local cseq = SL.seqc()
    for _, cv in ipairs(dcx and dcx.list or {}) do
        local CK = P .. cseq("military_deployment_conveyor") .. "."
        emit(tag, CK .. "id", SL.idpair(cv.id, cv.id_type))
        if cv.template_id then
            emit(tag, CK .. "division_template_id",
                SL.idpair(cv.template_id, cv.template_type))
        end
        local nm = SL.Q(cv.name)
        if nm then emit(tag, CK .. "name", nm) end
        emit(tag, CK .. "amount", SL.num(cv.amount or 0))
        emit(tag, CK .. "location", SL.num(cv.location or 0))
        emit(tag, CK .. "priority", SL.num(cv.priority or 0))
        if cv.order_index and cv.order_index ~= 0 then
            emit(tag, CK .. "order_index", SL.num(cv.order_index))
        end
        if cv.role and cv.role ~= 0 then
            emit(tag, CK .. "role", tostring(SL.tok(cv.role)))
        end
        emit(tag, CK .. "closed", cv.closed or "no")
        -- government_in_exile_tag (tid>0 门; tag 串 reader 解)
        if cv.giex_tag and cv.giex_tag ~= "" then
            emit(tag, CK .. "government_in_exile_tag",
                SL.Q(cv.giex_tag)) end
        local lseq = SL.seqc()
        for lvi, lv in ipairs(cv.lines or {}) do
            local LK = CK .. lseq("military_deployment_line") .. "."
            emit(tag, LK .. "id", SL.idpair(lv.id, lv.id_type))
            emit(tag, LK .. "division_name.type",
                SL.num(lv.dn_type or 0))
            -- division_name (布局/写门 = 书 §4.18.12)
            if (lv.dn_order or 0) ~= 0 then
                emit(tag, LK .. "division_name.name_order",
                    SL.num(lv.dn_order))
            end
            if lv.dn_is_name_ordered_zero then
                emit(tag, LK .. "division_name.is_name_ordered", "no")
            end
            if lv.dn_override then
                emit(tag, LK .. "division_name.override",
                    '"' .. lv.dn_override .. '"')
            end
            if lv.dn_override_set then
                emit(tag, LK ..
                    "division_name.override_set_programmatically", "yes")
            end
            emit(tag, LK .. "amount", SL.num(lv.amount or 0))
            local MK = LK .. "military_deployment."
            if lv.training and lv.training ~= 0 then
                emit(tag, MK .. "training", SL.num(lv.training))
            end
            if lv.max_training and lv.max_training ~= 0 then
                emit(tag, MK .. "max_training", SL.num(lv.max_training))
            end
            if lv.mpv_value then
                emit(tag, MK .. "army_manpower_value.value",
                    string.format('tag="%s" value=%d',
                        tostring(lv.mpv_tag), lv.mpv_value))
            end
            if lv.mpn_value then
                emit(tag, MK .. "army_manpower_need.value",
                    string.format('tag="%s" value=%d',
                        tostring(lv.mpn_tag), lv.mpn_value))
            end
            -- equipment 块门 = 池非空 (writer 0x140FFB8F0); 元素门
            -- (池 writer 0x140FFDB00): amount≠0 或 allow_zero≠0;
            -- eseq 必须在门内 (编号只对发射条目递增)
            if lv.equipment and #lv.equipment > 0 then
                local eseq = SL.seqc()
                for _, ev in ipairs(lv.equipment) do
                    if (ev.amount or 0) ~= 0 or lv.allow_zero == "yes" then
                        local EK = MK .. "equipment."
                            .. eseq("equipment") .. "."
                        emit(tag, EK .. "id", SL.idpair(ev.id, ev.type))
                        emit(tag, EK .. "amount", SL.num(ev.amount))
                    end
                end
                emit(tag, MK .. "equipment.allow_zero_entries",
                    lv.allow_zero or "no")
            end
            emit(tag, MK .. "max_manpower",
                SL.num(lv.max_manpower or 0))
            -- halting_reason (门 byte@M+172 ≠0; reader 已门)
            if lv.halting_reason then
                emit(tag, MK .. "halting_reason",
                    SL.num(lv.halting_reason))
            end
        end
    end
end }
