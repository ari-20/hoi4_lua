-- sv2_sec_rail_way.lua -- rail_way 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "rail_way", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local gs, BASE = ctx.gs, ctx.BASE
    if not (gs and BASE) then return end
    local rp, ru32 = SL.rp, SL.ru32
    local kptr = SL.kptr
    -- §4.14.7 CRailwayManager — mgr = *(gs+0x3E0) (= gs+992)
    local mgr = rp(gs + 0x3E0)
    if not (kptr(mgr) and rp(mgr) == BASE + GAME.layout.vt.CRailwayManager) then return end
    local data, slots = rp(mgr + 8), ru32(mgr + 0x14) or 0
    local i64 = GAME.layout.i64
    if kptr(data) and slots > 0 then
        for i = 0, math.min(slots, 100000) - 1 do
            -- §4.14.6 CProvinceRailwayInfo (vt 校验;
            -- 省反查 prov@info+8 → 省 id@prov+0xC4)
            local info = rp(data + 8 * i)
            if kptr(info) and rp(info) == BASE + GAME.layout.vt.CProvinceRailwayInfo then
                local prov = rp(info + 8)
                local pid = kptr(prov) and ru32(prov + 0xC4) or nil
                if pid then
                    local base = "rail_way." .. pid
                    -- rail_way 等级数组 — §4.14.6 CProvinceRailwayInfo
                    -- (+32 {d@+0x20, c@+0x2C}, c>0 → 单行)
                    local d, n = rp(info + 0x20), ru32(info + 0x2C) or 0
                    if kptr(d) and n > 0 then
                        local t = {}
                        for j = 0, math.min(n, 64) - 1 do
                            t[#t + 1] = tostring(ru32(d + 4 * j) or 0)
                        end
                        emit("rail_way", base .. ".rail_way.#1",
                            table.concat(t, " "))
                    end
                    -- rail_way_construction — §4.14.6 (+80;
                    -- 16B 条 {邻省 u32@0, 进度 fixed×1e-5 i64@8})
                    d, n = rp(info + 0x50), ru32(info + 0x5C) or 0
                    if kptr(d) and n > 0 then
                        for j = 0, math.min(n, 256) - 1 do
                            local nb = ru32(d + 16 * j) or 0
                            local prog = (i64(d + 16 * j + 8) or 0) / 100000
                            emit("rail_way",
                                base .. ".rail_way_construction.#" .. (j + 1),
                                nb .. " " .. SL.num(prog))
                        end
                    end
                    -- cooldown — §4.14.6 CProvinceRailwayInfo (+104, >0)
                    local cd = ru32(info + 0x68) or 0
                    if cd > 0 then
                        emit("rail_way", base .. ".cooldown", tostring(cd))
                    end
                end
            end
        end
    end
    -- 顶格 cooldown 列表 — §4.14.7 CRailwayManager (u32 数组
    -- {d@mgr+32, c@mgr+44}, c>0 才写)
    local n = ru32(mgr + 44) or 0
    local d = rp(mgr + 32)
    if kptr(d) and n > 0 then
        local t = {}
        for i = 0, math.min(n, 4096) - 1 do
            t[#t + 1] = tostring(ru32(d + 4 * i) or 0)
        end
        emit("rail_way", "cooldown.#1", table.concat(t, " "))
    end
end }
