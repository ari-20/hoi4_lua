-- sv2_sec_combat_data_entry.lua -- combat_data_entry 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "combat_data_entry", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local gs, BASE = ctx.gs, ctx.BASE
    if not BASE then return end
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local kptr = SL.kptr
    -- §4.22.4 combat_data_entry 池 (引擎侧全局静态存储不经 gs; 条目
    -- 无独立 RTTI 类 — 负定案) — 静态表收敛到 hoi4_layout.cde_table
    -- (rva 见 M.rva.cde)
    local cde = GAME.layout.cde_table()
    local data, refs, count = cde.data, cde.refs, cde.count
    if not (kptr(data) and kptr(refs) and count > 0
        and count <= GAME.layout.lim.PTR_SANE) then return end  -- 防御界 (审查: 原无上界, count 垃圾即挂死)

    local i64 = GAME.layout.i64
    local tt = gs and rp(gs + 0x358) -- §1.2 gs+856 tag 串表
    local function qtag(tid)
        if not (kptr(tt) and tid and tid > 0) then return nil end
        local s = hoi4.read_str(tt + 32 * tid)
        return s and ('"' .. s .. '"') or nil
    end
    local function qdate(h)
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end
    -- §4.22.4 SEquipmentPool (gated 空判)
    local function emit_pool(dim, P, pfx)
        if not kptr(P) then return end
        local na = ru32(P + 20) or 0
        local empty = na <= 0
        if not empty then
            local da = rp(P + 8)
            empty = true
            if kptr(da) then
                for i = 0, math.min(na, 4096) - 1 do
                    if (rp(da + 24 * i + 16) or 0) ~= 0 then
                        empty = false break
                    end
                end
            end
        end
        if empty then return end
        local az = ru8(P + 56) == 1
        local d, n = rp(P + 32), ru32(P + 44) or 0
        local seq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 4096) - 1 do
                local vp, amt = rp(d + 16 * i), i64(d + 16 * i + 8)
                if kptr(vp) and ((amt or 0) ~= 0 or az) then
                    local k = seq("equipment")
                    emit(dim, pfx .. "." .. k .. ".id",
                        SL.idpair(ru32(vp + 12), ru32(vp + 8)))
                    emit(dim, pfx .. "." .. k .. ".amount",
                        SL.num((amt or 0) / 100000))
                end
            end
        end
        emit(dim, pfx .. ".allow_zero_entries", SL.yn(az))
    end
    -- §4.22.4 SCombatSideData 侧数据 (writer 0x140CD15D0)
    local function emit_side(dim, S, pfx)
        local v = ru32(S + 8)
        if v and v > 0 then emit(dim, pfx .. ".manpower_lost", tostring(v)) end
        local r = i64(S + 16)
        if r and r > 0 then
            emit(dim, pfx .. ".manpower_lost_air_factor", SL.num(r / 100000))
        end
        emit_pool(dim, S + 24, pfx .. ".equipment_lost")
        emit_pool(dim, S + 344, pfx .. ".equipment_captured_by_enemy")
        emit_pool(dim, S + 408, pfx .. ".equipment_recovered")
        local lt, li = ru32(S + 520) or 0, ru32(S + 524) or 0
        if lt ~= 0 or li ~= 0 then
            emit(dim, pfx .. ".leader", SL.idpair(li, lt))
        end
        local d, n = rp(S + 496), ru32(S + 508) or 0
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 64) - 1 do
                local s = qtag(ru32(d + 4 * i))
                if s then emit(dim, pfx .. ".tags.#" .. (i + 1), s) end
            end
        end
    end

    -- §4.22.4 combat_data_entry 1096B 条目循环 (refs 并行 u16 数组 >0 = 存活)
    local dimseq = SL.seqc()
    local v2, v3 = 0, 0
    while v3 < count and v2 < 4096 do
        local rc = (ru8(refs + 2 * v2) or 0) + 256 * (ru8(refs + 2 * v2 + 1) or 0)
        if rc > 0 then
            local cd = data + 1096 * v2
            local dim = dimseq("combat_data_entry")
            emit(dim, "id", tostring(v2))
            emit(dim, "ref_count", tostring(rc))
            emit_side(dim, cd + 536, "combat_data.defender")
            emit_side(dim, cd + 8, "combat_data.attacker")
            local ds = qdate(ru32(cd + 1072))
            if ds then emit(dim, "combat_data.date", ds) end
            local v = ru32(cd + 1088)
            if v and v ~= 0 then
                emit(dim, "combat_data.province", tostring(v))
            end
            if (ru8(cd + 1092) or 0) ~= 0 then
                emit(dim, "combat_data.defensive_victory", "yes")
            end
            if (ru8(cd + 1093) or 0) ~= 0 then
                emit(dim, "combat_data.snow", "yes")
            end
            if (ru8(cd + 1094) or 0) ~= 0 then
                emit(dim, "combat_data.overrun", "yes")
            end
            emit(dim, "combat_data.player_is_attacker",
                SL.yn(ru8(cd + 1095)))
            v3 = v3 + 1
        end
        v2 = v2 + 1
    end
end }
