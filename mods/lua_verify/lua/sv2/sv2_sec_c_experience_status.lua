-- sv2_sec_c_experience_status.lua -- country.experience_status 节点
-- (发射规则段; 布局/走查/写门唯一实现 = Country.experience /
--  Country.activity_data, objects_economy §4.3.17; #N = 容器序含
--  vt 过滤后元素, 叶门 combat/training ≠0, id 对仅 ref_ok)

SV2.csec[#SV2.csec + 1] = { name = "country.experience_status",
    emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ok, es = pcall(function() return c:experience() end)
    if not ok or not es then return end
    local SCAL = {                        -- {path, 字段} (写序)
        { "army_experience", "army" }, { "navy_experience", "navy" },
        { "air_experience", "air" },
        { "army_experience_daily", "army_daily" },
        { "army_experience_daily_training", "army_daily_training" },
        { "navy_experience_daily", "navy_daily" },
        { "air_experience_daily", "air_daily" },
    }
    for _, s in ipairs(SCAL) do
        local v = es[s[2]]
        if v and v ~= 0 then
            emit(tag, "experience_status." .. s[1], SL.num(v)) end
    end
    emit(tag, "experience_status.num_armies_for_training",
        SL.num(es.num_armies_for_training or 0))

    local ok2, ad = pcall(function() return c:activity_data() end)
    if not ok2 or not ad then return end
    local n1 = 0
    for _, e in ipairs(ad.xp_by_template or {}) do
        n1 = n1 + 1
        local b = "experience_status.xp_by_template.#" .. n1
        if (e.combat or 0) ~= 0 then
            emit(tag, b .. ".combat", SL.num(e.combat)) end
        if (e.training or 0) ~= 0 then
            emit(tag, b .. ".training", SL.num(e.training)) end
        if e.ref_ok then
            emit(tag, b .. ".division", SL.idpair(e.ref_id, e.ref_type))
        end
    end
    local n2 = 0
    for _, e in ipairs(ad.xp_by_taskforce or {}) do
        n2 = n2 + 1
        local b = "experience_status.xp_by_taskforce.#" .. n2
        local cb, tr = e.combat or 0, e.training or 0
        if cb ~= 0 then emit(tag, b .. ".combat", SL.num(cb)) end
        if tr ~= 0 then emit(tag, b .. ".training", SL.num(tr)) end
        if e.ref_ok then
            emit(tag, b .. ".task_force", SL.idpair(e.ref_id, e.ref_type)) end
        if e.on_mission then emit(tag, b .. ".on_mission", SL.num(e.on_mission)) end
        if e.mission then emit(tag, b .. ".mission", SL.num(e.mission)) end
    end
    local n3 = 0
    for _, e in ipairs(ad.xp_by_airwing or {}) do
        n3 = n3 + 1
        local b = "experience_status.xp_by_airwing.#" .. n3
        if (e.combat or 0) ~= 0 then
            emit(tag, b .. ".combat", SL.num(e.combat)) end
        if (e.training or 0) ~= 0 then
            emit(tag, b .. ".training", SL.num(e.training)) end
        if e.ref_ok then
            emit(tag, b .. ".air_wing", SL.idpair(e.ref_id, e.ref_type))
        end
    end
end }
