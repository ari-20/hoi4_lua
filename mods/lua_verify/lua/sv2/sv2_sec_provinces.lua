-- sv2_sec_provinces.lua -- provinces 节点 savefull 直出 (主写)

SV2.gsec[#SV2.gsec + 1] = { name = "provinces", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32 = SL.rp, SL.ru32
    local gs = ctx.gs
    -- §4.14 CProvince — 省表 = *(gs+0x2B0), 省数 = u32@gs+0x2BC
    local parr, pcnt = rp(gs + 0x2B0), ru32(gs + 0x2BC)
    if not (SL.kptr(parr) and pcnt and pcnt > 0 and pcnt < GAME.layout.lim.PTR_HUGE) then
        return
    end
    for pid = 0, pcnt - 1 do
        local p = pid .. "."
        local function E(path, val) emit("provinces", p .. path, val) end
        -- §4.14.1 CBuildingStatus / §4.14.2 CBuilding (省建筑)
        local okb, bld = pcall(function() return O:province_buildings(pid) end)
        if okb and bld and bld.list then
            for _, b in ipairs(bld.list) do
                local bp = "buildings." .. tostring(b.type) .. "."
                E(bp .. "level", tostring(b.level or 0))
                E(bp .. "partial_health", SL.num((b.partial_health or 0) / 1e5))
                E(bp .. "healthy_levels", tostring(b.healthy_levels or 0))
                -- repair_speed_factor 原值 ≠1e5 (≠1.0) 才写 — §4.14.2 CBuilding
                if b.repair_speed_factor and b.repair_speed_factor ~= 1 then
                    E(bp .. "repair_speed_factor",
                        SL.num(b.repair_speed_factor))
                end
            end
        end
        -- §4.14 CProvince — victory_points(+56) / controller(+392) /
        -- 动态名(+64) / strategic_province_location(+320)
        local okx, ex = pcall(function() return O:province_extras(pid) end)
        if okx and ex then
            if (ex.victory_points or 0) > 0 then
                E("victory_points", tostring(ex.victory_points))
            end
            if ex.controller then
                E("controller", '"' .. ex.controller .. '"')
            end
            if ex.name and ex.name ~= "" then
                E("name", '"' .. ex.name .. '"') end
            local sseq = 0
            for _, nm in ipairs(ex.spl or {}) do
                if nm and nm ~= "" then
                    sseq = sseq + 1
                    E("strategic_province_location.#" .. sseq, tostring(nm))
                end
            end
        end
    end
end }
