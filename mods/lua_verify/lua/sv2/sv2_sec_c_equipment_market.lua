-- sv2_sec_c_equipment_market.lua -- country.equipment_market 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.equipment_market", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    -- §4.23.2 国家侧 equipment_market (cc+4024)
    local outer = rp(c.addr + 4024)
    if not SL.kptr(outer) then return end
    local mk = rp(outer)
    if not SL.kptr(mk) then return end
    local P = "equipment_market."
    -- market_stockpile.equipments 条目 (池 @mk+56; 空 variant 槽跳过不编号)
    -- §4.23.3 CEquipmentVariantPool
    local pd, pc = rp(mk + 88), ru32(mk + 100)
    local seq = SL.seqc()
    local az = ru8(mk + 112)
    if SL.kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_HUGE then
        for k = 0, pc - 1 do
            local e = pd + 16 * k
            local var = rp(e)
            -- 条目门 (池 writer 0x140FFDB00): amount(raw i64)≠0 或
            -- allow_zero_entries≠0; seq 在门内 (编号只对发射条目递增)
            if SL.kptr(var) and ((rp(e + 8) or 0) ~= 0 or az ~= 0) then
                local kp = P .. "market_stockpile.equipments."
                    .. seq("equipment") .. "."
                emit(tag, kp .. "id", SL.idpair(ru32(var + 12), ru32(var + 8)))
                emit(tag, kp .. "amount", SL.num((rp(e + 8) or 0) / 100000))
            end
        end
    end
    -- allow_zero_entries 恒写
    emit(tag, P .. "market_stockpile.equipments.allow_zero_entries",
        SL.yn(ru8(mk + 112)))
    -- subsidies (仅 count>0; 条目 48B, writer sub_140DDD510)
    -- §4.23.2 subsidies 条目
    local sd, sc = rp(outer + 40), ru32(outer + 52)
    if SL.kptr(sd) and sc and sc > 0 and sc < 4096 then
        for k = 0, sc - 1 do
            local e = sd + 48 * k
            local kp = P .. "subsidies.subsidies.#" .. (k + 1) .. "."
            -- cic = i64×1e-5 定点 (对拍: mem 2000000 ↔ save 20)
            emit(tag, kp .. "cic", SL.num((rp(e) or 0) / 100000))
            local ap = rp(e + 8)
            if SL.kptr(ap) then
                local nm = SL.tok(ru32(ap + 8))
                if nm then emit(tag, kp .. "archetype", tostring(nm)) end
            end
            if (ru8(e + 40) or 0) == 0 then
                local td, tc = rp(e + 16), ru32(e + 28)
                if SL.kptr(td) and tc and tc > 0 and tc < 4096 then
                    for j = 0, tc - 1 do
                        local tg = ctx.O:tag(ru32(td + 4 * j))
                        if tg then
                            emit(tag, kp .. "targets.#" .. (j + 1),
                                '"' .. tg .. '"')
                        end
                    end
                end
            elseif (ru8(e + 40) or 0) == 1 then
                -- trigger 脚本分支 (writer 定案 sub_140DDD510: u8@+40==1
                -- → v16 = *(e+16) (sub_14139D960 HasTriggerCondition 断言),
                -- ADF40(tok 10595=trigger, v16+96) → MSVC 串@v16+96
                -- {buf@0, size@0x10, cap@0x18}; 存档带引号)
                local tp = rp(e + 16)
                if SL.kptr(tp) then
                    local ts = SL.sso(tp + 96)
                    if ts and ts ~= "" then
                        emit(tag, kp .. "trigger", '"' .. ts .. '"')
                    end
                end
            end
        end
    end
    -- market_request_automation.option (恒写三键)
    emit(tag, P .. "market_request_automation.option.auto_accept_market_access",
        SL.yn(ru8(outer + 96)))
    emit(tag, P .. "market_request_automation.option.auto_send_market_access",
        SL.yn(ru8(outer + 97)))
    emit(tag, P .. "market_request_automation.option.auto_accept_purchase",
        SL.yn(ru8(outer + 98)))
end }
