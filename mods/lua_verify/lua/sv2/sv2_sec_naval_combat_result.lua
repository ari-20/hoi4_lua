-- sv2_sec_naval_combat_result.lua -- 顶层 naval_combat_result 匿名重复块
-- 结构/走查唯一实现 = reader (Runtime:naval_combat_results,
-- objects_military §14.6); 本段只持写序/块键/[N] 编号/值格式化。

SV2.gsec[#SV2.gsec + 1] = { name = "naval_combat_result", emit = function(ctx)
    local SL, emit = SV2.lib, ctx.emit
    local ok, list = pcall(function() return ctx.O:naval_combat_results() end)
    if not ok or not list then return end

    local dim
    local function E(path, val)
        if val ~= nil then emit(dim, path, val) end
    end

    -- §4.22.6 SNavalHit (六字段全恒写; SL.num(nil)="0" = writer 同形)
    local function emit_naval_hits(prefix, hits)
        local seq = SL.seqc()
        for _, nh in ipairs(hits) do
            local nb = prefix .. seq("naval_hit") .. "."
            E(nb .. "target", tostring(nh.target))
            if nh.name then E(nb .. "name", '"' .. nh.name .. '"') end
            E(nb .. "convoy", nh.convoy and "yes" or "no")
            E(nb .. "damage", SL.num(nh.damage))
            E(nb .. "strength", SL.num(nh.strength))
            E(nb .. "last_hit", nh.last_hit and "yes" or "no")
        end
    end

    -- §4.22.6 SAirHit
    local function emit_air_hits(prefix, hits)
        local seq = SL.seqc()
        for _, ah in ipairs(hits) do
            local ab = prefix .. seq("air_hit") .. "."
            if ah.tag then E(ab .. "tag", '"' .. ah.tag .. '"') end
            if ah.var_id then
                E(ab .. "equipment_variant_index",
                    SL.idpair(ah.var_id, ah.var_type))
            end
            E(ab .. "count", tostring(ah.count))
        end
    end

    -- §4.22.6 CNavalCombatAirEntry
    local function emit_air_wings(prefix, wings)
        local seq = SL.seqc()
        for _, aw in ipairs(wings) do
            local ab = prefix .. seq("air_wing") .. "."
            if aw.var_id then
                E(ab .. "equipment_variant_index",
                    SL.idpair(aw.var_id, aw.var_type))
            end
            E(ab .. "max", tostring(aw.max))
            E(ab .. "alive", tostring(aw.alive))
            E(ab .. "killed", aw.killed and tostring(aw.killed) or nil)
            if aw.tag then E(ab .. "tag", '"' .. aw.tag .. '"') end
            if aw.air_base then
                E(ab .. "air_base", '"' .. aw.air_base .. '"') end
            if aw.naval_hits then emit_naval_hits(ab, aw.naval_hits) end
            if aw.air_hits then emit_air_hits(ab, aw.air_hits) end
        end
    end

    -- §4.22.6 SCachedInfo (发射序 = writer 恒定)
    local function emit_cached_info(base, ci)
        if ci.sprite then E(base .. "sprite", '"' .. ci.sprite .. '"') end
        E(base .. "index", tostring(ci.index))
        E(base .. "type", tostring(ci.type))
        if ci.tag then E(base .. "tag", '"' .. ci.tag .. '"') end
        if ci.strength then
            E(base .. "strength", SL.num(ci.strength)) end
        if ci.sunk_by then E(base .. "sunk_by", '"' .. ci.sunk_by .. '"') end
        if ci.convoy then E(base .. "convoy", "yes") end
        if ci.build_cost_ic then
            E(base .. "build_cost_ic", SL.num(ci.build_cost_ic)) end
        if ci.equipment_variant then
            E(base .. "equipment_variant",
                '"' .. ci.equipment_variant .. '"') end
        if ci.hev_id then
            E(base .. "highest_eq_variant",
                SL.idpair(ci.hev_id, ci.hev_type)) end
        if ci.ship then E(base .. "ship", '"' .. ci.ship .. '"') end
        if ci.potf then E(base .. "pride_of_the_fleet", "yes") end
        if ci.convoy_id_type or ci.convoy_id_id then
            E(base .. "convoy_id",
                SL.idpair(ci.convoy_id_id, ci.convoy_id_type)) end
        if ci.convoy_index then
            E(base .. "convoy_index", tostring(ci.convoy_index)) end
    end

    -- §4.22.6 CNavalCombatShipEntry
    local function emit_ships(prefix, ships)
        local seq = SL.seqc()
        for _, sh in ipairs(ships) do
            local sb = prefix .. seq("ship") .. "."
            E(sb .. "unique_id", SL.idpair(sh.id_id, sh.id_type))
            emit_cached_info(sb .. "cached_info.", sh.cached)
            if sh.naval_hits then emit_naval_hits(sb, sh.naval_hits) end
            if sh.air_hits then emit_air_hits(sb, sh.air_hits) end
        end
    end

    -- §4.22.6 CNavalCombatResultSide (内嵌 112B)
    local function emit_side(prefix, s)
        if not s then return end
        if s.air_wings then emit_air_wings(prefix, s.air_wings) end
        if s.ships then emit_ships(prefix, s.ships) end
        if s.countries then
            for n, t2 in ipairs(s.countries) do
                E(prefix .. "countries.#" .. n, '"' .. t2 .. '"')
            end
        end
        if s.last_leader then
            E(prefix .. "last_leader",
                SL.idpair(s.last_leader.id, s.last_leader.type))
        end
    end

    -- 逐条 (发射序 id→location→date→attacker→defender→port_strike→
    -- naval_strike→importance→to_discard_date→shown_to_countries;
    -- shown_to 编号 = 原始槽序, 洞由 reader 稀疏表保序)
    local seq = SL.seqc()
    for _, r in ipairs(list) do
        dim = seq("naval_combat_result")
        E("id", SL.idpair(r.id_id, r.id_type))
        E("location", tostring(r.location))
        local ds = SL.date(r.date_h)
        if ds then E("date", '"' .. ds .. '"') end
        emit_side("attacker.", r.attacker)
        emit_side("defender.", r.defender)
        E("port_strike", r.port_strike and "yes" or "no")
        E("naval_strike", r.naval_strike and "yes" or "no")
        E("importance", tostring(r.importance))
        local tds = SL.date(r.to_discard_h)
        if tds then E("to_discard_date", '"' .. tds .. '"') end
        if r.shown_to then
            for j = 1, r.shown_to_n do
                local s2 = r.shown_to[j]
                if s2 then
                    E("shown_to_countries.#" .. j, '"' .. s2 .. '"')
                end
            end
        end
    end
end }
