-- sv2_sec_rail_way.lua -- rail_way 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Runtime:rail_way + G32_RWInfoMT 代理,
-- objects_global §32.5); 本段只持 writer 发射规则 (块门/编号/钳位)。

SV2.gsec[#SV2.gsec + 1] = { name = "rail_way", emit = function(ctx)
    local SL, emit = SV2.lib, ctx.emit
    if not (ctx.gs and ctx.BASE) then return end
    local ok, rw = pcall(function() return ctx.O:rail_way() end)
    if not ok or not rw then return end
    for _, info in ipairs(rw.list or {}) do
        local pid = info.province_id
        if pid then
            local base = "rail_way." .. pid
            -- rail_way 等级数组 — §4.14.6 (+32, c>0 → 单行; 钳 64)
            local levels = info.levels
            if levels and #levels > 0 then
                local t = {}
                for j = 1, math.min(#levels, 64) do
                    t[#t + 1] = tostring(levels[j] or 0)
                end
                emit("rail_way", base .. ".rail_way.#1",
                    table.concat(t, " "))
            end
            -- rail_way_construction — §4.14.6 (+80; 16B 条
            -- {邻省 u32@0, 进度 fixed×1e-5 i64@8}; 钳 256)
            local cons = info.construction
            if cons and #cons > 0 then
                for j = 1, math.min(#cons, 256) do
                    local cv = cons[j]
                    emit("rail_way",
                        base .. ".rail_way_construction.#" .. j,
                        tostring(cv.id or 0) .. " "
                        .. SL.num((cv.progress or 0) / 100000))
                end
            end
            -- cooldown — §4.14.6 CProvinceRailwayInfo (+104, >0)
            local cd = info.cooldown or 0
            if cd > 0 then
                emit("rail_way", base .. ".cooldown", tostring(cd))
            end
        end
    end
    -- 顶格 cooldown 列表 — §4.14.7 CRailwayManager (c>0 才写)
    if #(rw.top_cooldown or {}) > 0 then
        local t = {}
        for i, v in ipairs(rw.top_cooldown) do t[i] = tostring(v) end
        emit("rail_way", "cooldown.#1", table.concat(t, " "))
    end
end }
