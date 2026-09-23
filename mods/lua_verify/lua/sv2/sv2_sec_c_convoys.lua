-- sv2_sec_c_convoys.lua -- country.convoys 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.convoys", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    -- §4.3.18 CConvoys (cc+4608 内嵌; equipment 池头 cvp = cc+4624)
    local cvp = c.addr + 4608 + 16
    local az = ru8(cvp + 56) or 0
    local d, cnt = rp(cvp + 32), ru32(cvp + 44)
    local seq = SL.seqc()
    if SL.kptr(d) and cnt and cnt > 0 and cnt < 4096 then
        for k = 0, cnt - 1 do
            local ev = rp(d + 16 * k)
            local amt = rp(d + 16 * k + 8) or 0
            -- 门同 writer: amount(raw)≠0 或 az≠0 (variant 非空仍必要 — id 对解引用)
            if SL.kptr(ev) and (amt ~= 0 or az ~= 0) then
                local kp = "convoys.equipment." .. seq("equipment") .. "."
                emit(tag, kp .. "id", SL.idpair(ru32(ev + 12), ru32(ev + 8)))
                emit(tag, kp .. "amount", SL.num(amt / 100000))
            end
        end
    end
    emit(tag, "convoys.equipment.allow_zero_entries", SL.yn(az))
end }
