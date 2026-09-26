-- sv2_sec_c_country_scalars.lua -- country 顶层散标量族 savefull 直出 (csec)
-- (发射规则段; 布局/走查/写门唯一实现 = Country.scalars
--  objects_misc §27.0 §4.3.11/§4.3.12)

SV2.csec[#SV2.csec + 1] = { name = "country.scalars", emit = function(ctx)
    local SL, emit, tag = SV2.lib, ctx.emit, ctx.tag
    local c = ctx.country
    if not c then return end
    local ok, s = pcall(function() return c:scalars() end)
    if not ok or not s then return end
    -- §4.3.11 CCountry 标量族 (散标量行另见 §4.3.12 杂项表; 恒写序)
    emit(tag, "capital", SL.num(s.capital or 0))
    emit(tag, "original_capital", SL.num(s.original_capital or 0))
    emit(tag, "stability", SL.num(s.stability))
    emit(tag, "war_support", SL.num(s.war_support))
    emit(tag, "refresh", SL.num(s.refresh or 0))
    emit(tag, "command_power", SL.num(s.command_power))
    emit(tag, "scripted_gui_random", SL.num(s.scripted_gui_random or 0))
    emit(tag, "research_slot", SL.num(s.research_slot or 0))
    emit(tag, "accidents_score", SL.num(s.accidents_score))
    -- cosmetic_tag SSO, 空串照写 ""
    if s.cosmetic_tag ~= nil then
        emit(tag, "cosmetic_tag", '"' .. s.cosmetic_tag .. '"') end
    if s.focus_tree ~= nil then
        emit(tag, "focus_tree", '"' .. s.focus_tree .. '"') end
    if s.continuous_focus_palette ~= nil then
        emit(tag, "continuous_focus_palette",
            '"' .. s.continuous_focus_palette .. '"') end
    -- pride_of_the_fleet_date_lost (默认态照发, B 族哨兵 43808760 照发)
    do
        local d = SL.date_raw(s.pride_of_the_fleet_date_lost)
        if d then emit(tag, "pride_of_the_fleet_date_lost", '"' .. d .. '"') end
    end
    -- use_legacy_ai_pp_spend bool 恒写
    if s.use_legacy_ai_pp_spend ~= nil then
        emit(tag, "use_legacy_ai_pp_spend",
            SL.yn(s.use_legacy_ai_pp_spend)) end
    emit(tag, "instances_counter", SL.num(s.instances_counter or 0))
    if s.preferred_tactic ~= nil then
        emit(tag, "preferred_tactic", SL.num(s.preferred_tactic)) end
    -- dynamic_revolution_tag: tag = 引号 tag 串 (空/"---" 不发);
    -- ideology = 裸 token (>0 且解析成功才发)
    for _, dr in ipairs(s.dynamic_revolution_tag or {}) do
        local tid = dr.tag_tid or 0
        if tid > 0 and tid < 4096 then
            local ts = ctx.O:tag(tid)
            local qt = ts and ts ~= "" and ts ~= "---" and SL.Q(ts)
            if qt then
                emit(tag, "dynamic_revolution_tag.tag", qt)
            end
        end
        if dr.ideology then
            emit(tag, "dynamic_revolution_tag.ideology",
                tostring(dr.ideology))
        end
    end
    -- ===== ace 族 (§4.3.12 country.ace 表; reader Country.aces —
    -- 段侧只留写门/格式) =====
    do
        local oka, aces = pcall(function() return c:aces() end)
        if oka and aces then
            local seq = SL.seqc()
            for _, e in ipairs(aces) do
                local blk = seq("ace")
                emit(tag, blk .. ".id", SL.idpair(e.id_id, e.id_type))
                if e.modifier then
                    emit(tag, blk .. ".modifier", '"' .. e.modifier .. '"')
                end
                if e.name then emit(tag, blk .. ".name", '"' .. e.name .. '"') end
                if e.surname then
                    emit(tag, blk .. ".surname", '"' .. e.surname .. '"') end
                if e.callsign and e.callsign ~= "" then
                    emit(tag, blk .. ".callsign", '"' .. e.callsign .. '"') end
                if e.portrait then
                    emit(tag, blk .. ".portrait", SL.num(e.portrait)) end
                if e.is_female ~= 0 then
                    emit(tag, blk .. ".is_female", "yes") end
                if e.alive == 0 then emit(tag, blk .. ".alive", "no") end
                if e.handled ~= 0 then emit(tag, blk .. ".handled", "yes") end
                if e.kill_type ~= 0 then
                    emit(tag, blk .. ".kill_type", SL.num(e.kill_type)) end
                if e.killer_name_type ~= 0 or e.killer_name_id ~= 0 then
                    emit(tag, blk .. ".killer_name",
                        SL.idpair(e.killer_name_id, e.killer_name_type))
                end
                -- killer_country i32 带符号 >0 才写 (引号 tag)
                local kc = e.killer_country_tid
                if kc > 0 and kc < 0x80000000 then
                    local ks = ctx.O:tag(kc)
                    if ks and ks ~= "" then
                        emit(tag, blk .. ".killer_country",
                            '"' .. ks .. '"') end
                end
            end
        end
    end
end }
