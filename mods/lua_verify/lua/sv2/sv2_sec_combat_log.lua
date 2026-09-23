-- sv2_sec_combat_log.lua -- combat_log 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "combat_log", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local gs, BASE = ctx.gs, ctx.BASE
    if not (gs and BASE) then return end
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local kptr = SL.kptr
    -- §4.22.4 NCombatLog::CManager 指针数组 (gs+2176/2188; 按国家 id 索引)
    local arr = rp(gs + 0x880)
    local cnt = ru32(gs + 0x88C) or 0
    if not (kptr(arr) and cnt > 0) then return end

    local i64 = GAME.layout.i64
    local tt = rp(gs + 0x358) -- §1.2 gs+856 tag 串表
    local function qtag(tid)
        if not (kptr(tt) and tid and tid > 0) then return nil end
        local s = hoi4.read_str(tt + 32 * tid)
        return s and ('"' .. s .. '"') or nil
    end
    local function qdate(h)
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end

    -- §4.22.4 装备子条目 (CLoss 三件套; equipment/enemy_equipment/
    -- equipment_recovered 同构)
    -- 嵌套契约 (形状直方图定案): 子条目内 writer 先写池块 "equipment"
    -- (裸), 其下编号条目 equipment[K] → id/amount; allow_zero_entries 是
    -- 池块子叶。即 <pfx>.equipment.equipment[K].id, 不是
    -- <pfx>.equipment[K].equipment.id。
    local function emit_equip_entry(dim, se, pfx)
        local P = se + 40 -- §4.22.4 SEquipmentPool 内嵌 (恒写, 无空判)
        local az = ru8(P + 56) == 1
        local d, n = rp(P + 32), ru32(P + 44) or 0
        local pp = pfx .. ".equipment" -- 池块前缀 (裸)
        local seq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 4096) - 1 do
                local vp, amt = rp(d + 16 * i), i64(d + 16 * i + 8)
                if kptr(vp) and ((amt or 0) ~= 0 or az) then
                    local k = seq("equipment")
                    emit(dim, pp .. "." .. k .. ".id",
                        SL.idpair(ru32(vp + 12), ru32(vp + 8)))
                    emit(dim, pp .. "." .. k .. ".amount",
                        SL.num((amt or 0) / 100000))
                end
            end
        end
        emit(dim, pp .. ".allow_zero_entries", SL.yn(az))
        emit(dim, pfx .. ".reason", tostring(ru32(se + 8) or 0))
        local ds = qdate(ru32(se + 24))
        if ds then emit(dim, pfx .. ".date", ds) end
    end

    local dimseq = SL.seqc()
    for i = 0, math.min(cnt, 1024) - 1 do
        local mgr = rp(arr + 8 * i)
        -- §4.22.4 NCombatLog::CManager (SCombatData 同体异名, vt 0X295D8D8)
        if kptr(mgr) and rp(mgr) == BASE + GAME.layout.vt.CCombatLogManager then
            local ln = ru32(mgr + 20) or 0
            if ln > 0 then -- 块写门: 空日志不写整块
                local dim = dimseq("combat_log")
                local s = qtag(ru32(mgr + 32))
                if s then emit(dim, "tag", s) end
                local ld = rp(mgr + 8)
                local logseq = SL.seqc()
                if kptr(ld) then
                    for j = 0, math.min(ln, 256) - 1 do
                        local le = rp(ld + 8 * j)
                        -- §4.22.4 COrdersGroupLogs 条目 (vt = CCombatLogEntry)
                        if kptr(le) and rp(le) == BASE + GAME.layout.vt.CCombatLogEntry then
                            local pfx = logseq("log")
                            emit(dim, pfx .. ".group",
                                SL.idpair(ru32(le + 228), ru32(le + 224)))
                            -- §4.22.4 equipment ×4 容器 (四容器合并序)
                            local eqseq = SL.seqc()
                            for _, oc in ipairs({
                                { 56, 68 }, { 80, 92 }, { 104, 116 },
                                { 128, 140 } }) do
                                local d2, n2 = rp(le + oc[1]),
                                    ru32(le + oc[2]) or 0
                                if kptr(d2) and n2 > 0 then
                                    for q = 0, math.min(n2, 4096) - 1 do
                                        local se = rp(d2 + 8 * q)
                                        if kptr(se) then
                                            emit_equip_entry(dim, se,
                                                pfx .. "." .. eqseq("equipment"))
                                        end
                                    end
                                end
                            end
                            -- enemy_equipment / equipment_recovered
                            for _, spec in ipairs({
                                { 8, 20, "enemy_equipment" },
                                { 32, 44, "equipment_recovered" } }) do
                                local d2, n2 = rp(le + spec[1]),
                                    ru32(le + spec[2]) or 0
                                local sseq = SL.seqc()
                                if kptr(d2) and n2 > 0 then
                                    for q = 0, math.min(n2, 4096) - 1 do
                                        local se = rp(d2 + 8 * q)
                                        if kptr(se) then
                                            emit_equip_entry(dim, se,
                                                pfx .. "." .. sseq(spec[3]))
                                        end
                                    end
                                end
                            end
                            -- §4.22.4 manpower 子条目
                            local d2, n2 = rp(le + 152), ru32(le + 164) or 0
                            local mseq = SL.seqc()
                            if kptr(d2) and n2 > 0 then
                                for q = 0, math.min(n2, 4096) - 1 do
                                    local se = rp(d2 + 8 * q)
                                    if kptr(se) then
                                        local k = mseq("manpower")
                                        emit(dim, pfx .. "." .. k .. ".reason",
                                            tostring(ru32(se + 8) or 0))
                                        local ds = qdate(ru32(se + 24))
                                        if ds then
                                            emit(dim, pfx .. "." .. k .. ".date", ds)
                                        end
                                        emit(dim,
                                            pfx .. "." .. k .. ".mp_losses.#1",
                                            string.format("%d %d %d",
                                                ru32(se + 40) or 0,
                                                ru32(se + 44) or 0,
                                                ru32(se + 48) or 0))
                                    end
                                end
                            end
                            -- §4.22.4 CPerTemplateStats division_template 子条目
                            d2, n2 = rp(le + 176), ru32(le + 188) or 0
                            local tseq = SL.seqc()
                            if kptr(d2) and n2 > 0 then
                                for q = 0, math.min(n2, 4096) - 1 do
                                    local se = rp(d2 + 8 * q)
                                    if kptr(se) then
                                        local k = tseq("division_template")
                                        emit(dim, pfx .. "." .. k .. ".division",
                                            SL.idpair(ru32(se + 12),
                                                ru32(se + 8)))
                                        local ds = qdate(ru32(se + 40))
                                        if ds then
                                            emit(dim, pfx .. "." .. k .. ".date", ds)
                                        end
                                        emit(dim, pfx .. "." .. k .. ".win",
                                            tostring(ru32(se + 24) or 0))
                                        emit(dim, pfx .. "." .. k .. ".total",
                                            tostring(ru32(se + 28) or 0))
                                    end
                                end
                            end
                            -- §4.22.4 combat_data_index 内联 8B {id i32, attacker u8}
                            d2, n2 = rp(le + 200), ru32(le + 212) or 0
                            local iseq = SL.seqc()
                            if kptr(d2) and n2 > 0 then
                                for q = 0, math.min(n2, 4096) - 1 do
                                    local v = d2 + 8 * q
                                    local k = iseq("combat_data_index")
                                    local id = ru32(v) or 0
                                    id = GAME.layout.as_i32(id)
                                    emit(dim, pfx .. "." .. k .. ".id",
                                        tostring(id))
                                    emit(dim, pfx .. "." .. k .. ".attacker",
                                        SL.yn(ru8(v + 4)))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end }
