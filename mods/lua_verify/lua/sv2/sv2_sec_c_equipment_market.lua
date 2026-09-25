-- sv2_sec_c_equipment_market.lua -- country.equipment_market 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.equipment_market", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    -- §4.23.2 国家侧 equipment_market (cc+4024) — 结构/走查唯一实现 =
    -- reader (Country:equipment_market_country; 布局引 LAYOUT.off.variant_pool
    -- / subsidy_entry)。本段只保留 writer 发射规则 (写序/恒写键/编号)。
    local ok, m = pcall(function() return c:equipment_market_country() end)
    if not ok or not m then return end
    local P = "equipment_market."
    -- market_stockpile.equipments 条目 (池 @mk+56; 元素级跳过规则住 reader:
    -- amount(raw i64)≠0 或 allow_zero_entries≠0; 编号只对发射条目递增)
    local sp = m.stockpile or { list = {} }
    local seq = SL.seqc()
    for _, e in ipairs(sp.list) do
        local kp = P .. "market_stockpile.equipments."
            .. seq("equipment") .. "."
        emit(tag, kp .. "id", SL.idpair(e.id, e.type))
        emit(tag, kp .. "amount", SL.num(e.amount / 100000))
    end
    -- allow_zero_entries 恒写 (原样传原始 u8: 仅 ==1 判 yes, 与旧行为一致)
    emit(tag, P .. "market_stockpile.equipments.allow_zero_entries",
        SL.yn(sp.allow_zero or 0))
    -- subsidies (仅 count>0; 条目 48B, writer sub_140DDD510)
    -- §4.23.2 subsidies 条目 (branch 0 → targets; branch 1 → trigger 串,
    -- 两分支判据住 reader)
    for k, s in ipairs(m.subsidies or {}) do
        local kp = P .. "subsidies.subsidies.#" .. k .. "."
        emit(tag, kp .. "cic", SL.num(s.cic))
        if s.archetype then emit(tag, kp .. "archetype", tostring(s.archetype)) end
        if s.trigger then emit(tag, kp .. "trigger", '"' .. s.trigger .. '"') end
        for j, t in ipairs(s.targets or {}) do
            emit(tag, kp .. "targets.#" .. j, '"' .. t .. '"')
        end
    end
    -- market_request_automation.option (恒写三键)
    emit(tag, P .. "market_request_automation.option.auto_accept_market_access",
        m.auto_accept_market_access)
    emit(tag, P .. "market_request_automation.option.auto_send_market_access",
        m.auto_send_market_access)
    emit(tag, P .. "market_request_automation.option.auto_accept_purchase",
        m.auto_accept_purchase)
end }
