-- sv2_sec_c_resources.lua -- country.resources 节点 savefull 直出
-- 结构/走查唯一实现 = reader: Country.resources_extra_origins/vecs/origin/
-- resources_tails (objects_economy §4.3.3 + 尾补充)。本段只持写序/块键/
-- 编号/值格式化 (fuel f64 "%.5f" 折叠契约留段层)。

SV2.csec[#SV2.csec + 1] = { name = "country.resources", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ru8 = SL.ru8
    local BASE = ctx.BASE
    local okt, RT = pcall(function() return c:resources_tails() end)
    if not okt or not RT then return end

    -- 路由叶发射 (双形兼容: delivery_routes 给 tag 串, origin 内嵌给 tid)
    local function tg(v)
        if type(v) == "number" then
            if v <= 0 then return nil end
            return c.R:tag(v) end
        return v
    end
    local function emit_route(base, rt)
        if (rt.type or 0) ~= 0 then
            emit(tag, base .. ".type", tostring(rt.type)) end
        if rt.from_state then
            emit(tag, base .. ".from_state", tostring(rt.from_state)) end
        if rt.to_state then
            emit(tag, base .. ".to_state", tostring(rt.to_state)) end
        if rt.from_port then
            emit(tag, base .. ".from_port", tostring(rt.from_port)) end
        if rt.to_port then
            emit(tag, base .. ".to_port", tostring(rt.to_port)) end
        local tvs = tg(rt.sender)
        if tvs then
            emit(tag, base .. ".sender", '"' .. tvs .. '"') end
        local rvr = tg(rt.receiver) or rt.receiver_tag
        if rvr then
            emit(tag, base .. ".receiver", '"' .. rvr .. '"') end
        local tvc = tg(rt.convoys_owner)
        if tvc then
            emit(tag, base .. ".convoys_owner", '"' .. tvc .. '"') end
        local np = {}
        for _, v in ipairs(rt.naval_path or {}) do
            if v then np[#np + 1] = tostring(v) end end
        if #np > 0 then
            emit(tag, base .. ".naval_path", table.concat(np, " ")) end
        local lp = {}
        for _, v in ipairs(rt.land_path or {}) do
            if v then lp[#lp + 1] = tostring(v) end end
        if #lp > 0 then
            emit(tag, base .. ".land_path", table.concat(lp, " ")) end
        local tvb = tg(rt.blocker_tag)
        if tvb then
            emit(tag, base .. ".blocker_tag", '"' .. tvb .. '"') end
        if rt.blocked_region then
            emit(tag, base .. ".blocked_region",
                tostring(rt.blocked_region)) end
        emit(tag, base .. ".dirty", SL.yn(rt.dirty == true))
    end

    -- origin 块叶发射 (extra_resource_origin.origin 共用)
    local function emit_origin(base, e)
        if e.addr and (ru8(e.addr + 16) or 0) ~= 0 then
            emit(tag, base .. ".id", e.id_pair) end
        if e.convoys_subscriber then
            emit(tag, base .. ".convoys_subscriber.convoys",
                tostring(e.convoys_subscriber.convoys or 0))
            emit(tag, base .. ".convoys_subscriber.total",
                tostring(e.convoys_subscriber.total or 0)) end
        local cq = SL.Q(e.country)
        if cq then emit(tag, base .. ".country", cq) end
        if e.efficiency ~= nil then
            emit(tag, base .. ".efficiency", SL.num(e.efficiency)) end
        if e.efficiency_due_to_lost_convoys ~= nil then
            emit(tag, base .. ".efficiency_due_to_lost_convoys",
                SL.num(e.efficiency_due_to_lost_convoys)) end
        emit(tag, base .. ".request", tostring(e.request or 0))
        if e.state then emit(tag, base .. ".state", tostring(e.state)) end
        for _, vec in ipairs({ { "resources", e.resources },
            { "resources_unclapmed", e.resources_unclapmed },
            { "buildings", e.buildings } }) do
            local map = vec[2] or {}
            local haspos = false
            for rn, rv in pairs(map) do
                if rn ~= "x0" and rv and rv > 0 then haspos = true break end
            end
            if haspos then
                for rn, rv in pairs(map) do
                    if rn ~= "x0" and rv and rv ~= 0 then
                        emit(tag, base .. "." .. vec[1] .. "." .. rn,
                            SL.num(rv)) end
                end
            end
        end
        if e.efficiency2 ~= nil then
            emit(tag, base .. ".efficiency", SL.num(e.efficiency2)) end
        if e.delivery_route then
            emit_route(base .. ".delivery_route", e.delivery_route) end
        for rn, tg in pairs(e.given_resource_rights or {}) do
            emit(tag, base .. ".given_resource_rights",
                rn .. ' "' .. tostring(tg) .. '"') end
        if e.destination then
            emit(tag, base .. ".destination", tostring(e.destination)) end
    end

    -- ===== 1. delivery_routes =====
    for _, rt in ipairs(RT.delivery_routes or {}) do
        emit_route("resources.delivery_routes." .. rt.receiver_tag, rt)
    end

    -- ===== 2. extra_resource_origin =====
    do
        local r = c:resources_extra_origins()
        if r and r.list then
            local seq = SL.seqc()
            for _, e in ipairs(r.list) do
                local base = seq("resources.extra_resource_origin")
                emit_origin(base .. ".origin", e)
                local gq = SL.Q(e.giver)
                if gq then emit(tag, base .. ".giver", gq) end
            end
        end
    end

    -- ===== 3. dirty =====
    emit(tag, "resources.dirty", RT.dirty and "yes" or "no")

    -- ===== 4/5. 六向量 + to_use =====
    do
        local rv = c:resources_vecs()
        if rv then
            for _, vn in ipairs({ "produced", "transfer_overlord_subject",
                "imported", "to_export", "base_export", "exported" }) do
                for rn, raw in pairs(rv[vn] or {}) do
                    local v = raw and (GAME.layout.as_i64(raw) / 100000)
                    if v and v ~= 0 then
                        emit(tag, "resources." .. vn .. "." .. rn,
                            SL.num(v)) end
                end
            end
            local tu = rv.to_use or {}
            local t1, t2, t3 = tu["1"] or {}, tu["2"] or {}, tu["3"] or {}
            local function s64(v)
                if v then v = GAME.layout.as_i64(v) end
                return v
            end
            for rn, raw in pairs(t1) do
                local v = s64(raw)
                local f = v and (v / 100000)
                if f and f ~= 0 then
                    emit(tag, "resources.to_use.#1." .. rn, SL.num(f)) end
            end
            local keys = {}
            for rn in pairs(t1) do keys[rn] = true end
            for rn in pairs(t2) do keys[rn] = true end
            for rn in pairs(keys) do
                local d = (s64(t2[rn]) or 0) - (s64(t1[rn]) or 0)
                if d ~= 0 then
                    emit(tag, "resources.to_use.#2." .. rn,
                        SL.num(d / 100000)) end
            end
            for rn, raw in pairs(t3) do
                local v = s64(raw)
                local f = v and (v / 100000)
                if f and f ~= 0 then
                    emit(tag, "resources.to_use.#3." .. rn, SL.num(f)) end
            end
        end
    end

    -- ===== 6. origin =====
    do
        local r = c:resources_origin()
        if r and r.list then
            local seq = SL.seqc()
            for _, e in ipairs(r.list) do
                emit_origin(seq("resources.origin"), e)
            end
        end
    end

    -- ===== 7. export 槽阵列 =====
    local seqe = SL.seqc()
    for _, e in ipairs(RT.exports or {}) do
        local base = seqe("resources.export")
        if e.id_id or e.id_type then
            emit(tag, base .. ".id", SL.idpair(e.id_id, e.id_type)) end
        if e.convoys_total then
            emit(tag, base .. ".convoys_subscriber.convoys",
                tostring(e.convoys))
            emit(tag, base .. ".convoys_subscriber.total",
                tostring(e.convoys_total)) end
        if e.spotter then
            emit(tag, base .. ".spotter",
                SL.idpair(e.spotter.id, e.spotter.type)) end
        if e.country then
            emit(tag, base .. ".country", '"' .. e.country .. '"') end
        if e.efficiency ~= nil then
            emit(tag, base .. ".efficiency", SL.num(e.efficiency)) end
        if e.efficiency_due ~= nil then
            emit(tag, base .. ".efficiency_due_to_lost_convoys",
                SL.num(e.efficiency_due)) end
        emit(tag, base .. ".request", tostring(e.request))
        for qi, cp in ipairs(e.combat or {}) do
            emit(tag, base .. ".combat.#" .. qi,
                SL.idpair(cp.id, cp.type)) end
        if e.receiver then
            emit(tag, base .. ".receiver", '"' .. e.receiver .. '"') end
        if e.resource then
            emit(tag, base .. ".resource", '"' .. e.resource .. '"') end
        if e.delivered ~= nil then
            emit(tag, base .. ".delivered", SL.num(e.delivered)) end
        if e.destination then
            emit(tag, base .. ".destination", tostring(e.destination)) end
        if e.origin then emit(tag, base .. ".origin", tostring(e.origin)) end
        if e.start_h then
            local sd = SL.date(e.start_h)
            if sd then emit(tag, base .. ".start_date", '"' .. sd .. '"') end end
        if e.last_recalc_h then
            local lr = SL.date(e.last_recalc_h)
            if lr then
                emit(tag, base .. ".last_recalc_date", '"' .. lr .. '"') end end
        emit(tag, base .. ".required_cic", tostring(e.required_cic))
        emit(tag, base .. ".lended_cic", tostring(e.lended_cic))
    end

    -- ===== 8. lend_lease =====
    local seqll = SL.seqc()
    for _, ll in ipairs(RT.lend_leases or {}) do
        local base = seqll("resources.lend_lease")
        if ll.receiver then
            emit(tag, base .. ".receiver", '"' .. ll.receiver .. '"') end
        if ll.destination then
            emit(tag, base .. ".destination", tostring(ll.destination)) end
        if ll.origin then
            emit(tag, base .. ".origin", tostring(ll.origin)) end
        emit(tag, base .. ".sender.convoys", tostring(ll.sender_convoys))
        emit(tag, base .. ".sender.total", tostring(ll.sender_total))
        for _, mname in ipairs({ "equipment_need", "percentage_need",
            "once_need", "equipment_collected", "equipment_prepared",
            "equipment_sunk", "total_delivered" }) do
            local m2 = ll.maps[mname]
            local eqseq = SL.seqc()
            for _, eq in ipairs(m2.list or {}) do
                local eqb = eqseq(base .. "." .. mname .. ".equipment")
                emit(tag, eqb .. ".id", SL.idpair(eq.id, eq.type))
                emit(tag, eqb .. ".amount", SL.num(eq.amount)) end
            emit(tag, base .. "." .. mname .. ".allow_zero_entries",
                SL.yn(m2.az)) end
        if ll.last_delivery_h then
            local q = SL.date(ll.last_delivery_h)
            if q then
                emit(tag, base .. ".last_delivery_date", '"' .. q .. '"') end end
        if ll.active_h then
            local q = SL.date(ll.active_h)
            if q then emit(tag, base .. ".active_since", '"' .. q .. '"') end end
        if ll.fuel_daily then
            emit(tag, base .. ".fuel_daily",
                string.format("%.5f", ll.fuel_daily)) end
        if ll.fuel_pct ~= nil then
            emit(tag, base .. ".fuel_percentage", SL.num(ll.fuel_pct)) end
        if ll.fuel_sent then
            emit(tag, base .. ".fuel_sent",
                string.format("%.5f", ll.fuel_sent)) end
        if ll.fuel_sunk then
            emit(tag, base .. ".fuel_sunk",
                string.format("%.5f", ll.fuel_sunk)) end
        if ll.last_fuel_delivered then
            emit(tag, base .. ".last_fuel_delivered",
                string.format("%.5f", ll.last_fuel_delivered)) end
        if ll.id_id or ll.id_type then
            emit(tag, base .. ".id", SL.idpair(ll.id_id, ll.id_type)) end
        if ll.convoys_total then
            emit(tag, base .. ".convoys_subscriber.convoys",
                tostring(ll.convoys))
            emit(tag, base .. ".convoys_subscriber.total",
                tostring(ll.convoys_total)) end
        if ll.country then
            emit(tag, base .. ".country", '"' .. ll.country .. '"') end
        if ll.efficiency ~= nil then
            emit(tag, base .. ".efficiency", SL.num(ll.efficiency)) end
        if ll.efficiency_due ~= nil then
            emit(tag, base .. ".efficiency_due_to_lost_convoys",
                SL.num(ll.efficiency_due)) end
        emit(tag, base .. ".request", tostring(ll.request))
    end

    -- ===== 9. modify_building_resources (折叠契约 "lvl=amt }") =====
    for _, mb in ipairs(RT.modify_building or {}) do
        emit(tag, "resources.modify_building_resources." .. mb.building
            .. "." .. mb.level,
            mb.level .. "=" .. SL.num(mb.amount) .. " }") end
end }
