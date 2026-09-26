-- sv2_sec_c_fuel_status.lua -- country.fuel_status 节点 savefull 直出 (csec)
-- (发射规则段; 布局/走查/写门唯一实现 = Country.fuel
--  objects_economy §4.3.16 CCountryFuelStatus cc+5504)
SV2.csec[#SV2.csec + 1] = { name = "country.fuel_status", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ok, fs = pcall(function() return c:fuel() end)
    if not ok or not fs then return end
    -- 顶层标量 (恒写; 写序 = writer sub_1410E39B0 调序 = 存档文档序)
    emit(tag, "fuel_status.fuel", string.format("%.5f", fs.fuel))
    emit(tag, "fuel_status.max_fuel", string.format("%.5f", fs.max_fuel))
    emit(tag, "fuel_status.fuel_gain", SL.num(fs.fuel_gain))
    emit(tag, "fuel_status.fuel_cost", SL.num(fs.fuel_cost))
    emit(tag, "fuel_status.fuel_gain_per_oil", SL.num(fs.fuel_gain_per_oil))
    emit(tag, "fuel_status.fuel_gain_from_states", SL.num(fs.fuel_gain_from_states))
    emit(tag, "fuel_status.fuel_gain_from_lend_lease",
        string.format("%.5f", fs.fuel_gain_from_lend_lease))
    emit(tag, "fuel_status.fuel_consumption_from_lend_lease",
        string.format("%.5f", fs.fuel_consumption_from_lend_lease))
    -- fuel_consumer_data 逐条 (vector 序 = writer 循环序; index = 容器序)
    local seq = SL.seqc()
    for j, u in ipairs(fs.consumers and fs.consumers.list or {}) do
        local p = seq("fuel_status.fuel_consumer_data")
        emit(tag, p .. ".index", string.format("%d", j - 1))
        emit(tag, p .. ".priority", string.format("%d", u.priority or 0))
        emit(tag, p .. ".received", SL.num(u.received))
        emit(tag, p .. ".requested", SL.num(u.requested))
    end
    emit(tag, "fuel_status.history_index",
        string.format("%d", fs.history_index or 0))
    emit(tag, "fuel_status.remaining_hours",
        string.format("%d", fs.remaining_hours or 0))
    -- history 环形缓冲: 哨兵 (index=-1) 先写, 后 24 槽 (reader 已排)
    for _, h in ipairs(fs.history or {}) do
        local p = seq("fuel_status.history")
        emit(tag, p .. ".index", string.format("%d", h.index))
        emit(tag, p .. ".fuel", string.format("%.5f", h.fuel))
        emit(tag, p .. ".consumed", string.format("%.5f", h.consumed))
        emit(tag, p .. ".fuel_gain", SL.num(h.fuel_gain))
        emit(tag, p .. ".other", string.format("%.5f", h.other))
        emit(tag, p .. ".requested.#1", string.format("%s %s %s",
            SL.num(h.requested[1]), SL.num(h.requested[2]),
            SL.num(h.requested[3])))
        emit(tag, p .. ".received.#1", string.format("%s %s %s",
            SL.num(h.received[1]), SL.num(h.received[2]),
            SL.num(h.received[3])))
    end
end }
