-- sv2_sec_c_names_trackers.lua -- country.{division,ship,railway_gun}_names_tracker
-- (§4.3.9 名字组 tracker, cc+112 + 8×mode)

SV2.csec[#SV2.csec + 1] = { name = "country.names_trackers", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    -- §4.3.9 CNameGroupTracker (cc+112 + 8×mode)
    local modes = {
        { "division_names_tracker", 0 },
        { "ship_names_tracker", 1 },
        { "railway_gun_names_tracker", 2 },
    }
    for _, mi in ipairs(modes) do
        local ok, r = pcall(function() return c:name_groups(mi[2]) end)
        if ok and r then
            local prefix = mi[1]
            for li, nm in ipairs(r.unavailable or {}) do
                local q = SL.Q(nm)
                if q then
                    emit(tag, prefix .. ".unavailable_groups.#" .. li, q)
                end
            end
            for li, nm in ipairs(r.available or {}) do
                local q = SL.Q(nm)
                if q then
                    emit(tag, prefix .. ".available_groups.#" .. li, q)
                end
            end
            -- post_mortem 元素 = §4.3.9 CNameGroupMember (176B 内联)
            local seq = SL.seqc()
            for _, pm in ipairs(r.post_mortem and r.post_mortem.list or {}) do
                local blk = seq(prefix .. ".post_mortem")
                emit(tag, blk .. ".type", SL.num(pm.type))
                if pm.name_order then
                    emit(tag, blk .. ".name_order", SL.num(pm.name_order))
                end
                if pm.is_name_ordered then
                    emit(tag, blk .. ".is_name_ordered", pm.is_name_ordered)
                end
                local ov = SL.Q(pm.override)
                if ov then emit(tag, blk .. ".override", ov) end
                if pm.override_set_programmatically then
                    emit(tag, blk .. ".override_set_programmatically",
                        pm.override_set_programmatically)
                end
                if pm.equipment then
                    emit(tag, blk .. ".equipment", pm.equipment)
                end
            end
        end
    end
end }
