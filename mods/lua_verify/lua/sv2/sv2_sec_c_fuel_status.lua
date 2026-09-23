-- sv2_sec_c_fuel_status.lua -- country.fuel_status 节点 savefull 直出 (csec)
SV2.csec[#SV2.csec + 1] = { name = "country.fuel_status", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32 = SL.rp, SL.ru32
    -- §4.3.16 CCountryFuelStatus (cc+5504, vt 0x298B3A8)
    local fs = rp(c.addr + 5504)
    if not SL.kptr(fs) then return end
    if rp(fs) ~= ctx.BASE + GAME.layout.vt.CFuelStatus then return end
    -- i64 定点直读 (§3.7 数值换算; U.fix5 同构: u64 二补数修正; 定案必须
    -- /100000, *1e-5 有 1ulp 差); Q15 同理 /32768 (2^15 精确)
    local function fix5(a)
        local v = rp(a) or 0
        v = GAME.layout.as_i64(v)
        return v / 100000
    end
    local function q15(a)
        local v = rp(a) or 0
        v = GAME.layout.as_i64(v)
        return v / 32768
    end
    -- 顶层标量 (恒写; 写序 = writer sub_1410E39B0 调序 = 存档文档序)
    emit(tag, "fuel_status.fuel", string.format("%.5f", q15(fs + 0x08)))
    emit(tag, "fuel_status.max_fuel", string.format("%.5f", q15(fs + 0x10)))
    emit(tag, "fuel_status.fuel_gain", SL.num(fix5(fs + 0x18)))
    emit(tag, "fuel_status.fuel_cost", SL.num(fix5(fs + 0x38)))
    emit(tag, "fuel_status.fuel_gain_per_oil", SL.num(fix5(fs + 0x40)))
    emit(tag, "fuel_status.fuel_gain_from_states", SL.num(fix5(fs + 0x20)))
    emit(tag, "fuel_status.fuel_gain_from_lend_lease",
        string.format("%.5f", q15(fs + 0x28)))
    emit(tag, "fuel_status.fuel_consumption_from_lend_lease",
        string.format("%.5f", q15(fs + 0x30)))
    -- fuel_consumer_data 逐条 (§4.3.16; vector 序 = writer 循环序)
    local ccnt = ru32(fs + 0x54) or 0
    local cdata = rp(fs + 0x48)
    if ccnt > 0 and SL.kptr(cdata) then
        local seq = SL.seqc()
        for j = 0, ccnt - 1 do
            local u = cdata + 24 * j
            local p = seq("fuel_status.fuel_consumer_data")
            emit(tag, p .. ".index", string.format("%d", j))
            emit(tag, p .. ".priority", string.format("%d", ru32(u) or 0))
            emit(tag, p .. ".received", SL.num(fix5(u + 16)))
            emit(tag, p .. ".requested", SL.num(fix5(u + 8)))
        end
    end
    emit(tag, "fuel_status.history_index",
        string.format("%d", ru32(fs + 0xC8) or 0))
    emit(tag, "fuel_status.remaining_hours",
        string.format("%d", ru32(fs + 0xCC) or 0))
    -- history 环形缓冲 (§4.3.16): 哨兵 (fs+0x60, index=-1) 先写,
    -- 后 24 槽 (rp(fs+0xB0), stride 80)
    local seq = SL.seqc()
    local function hist_entry(e, idx)
        local p = seq("fuel_status.history")
        emit(tag, p .. ".index", string.format("%d", idx))
        emit(tag, p .. ".fuel", string.format("%.5f", q15(e + 0x00)))
        emit(tag, p .. ".consumed", string.format("%.5f", q15(e + 0x10)))
        emit(tag, p .. ".fuel_gain", SL.num(fix5(e + 0x08)))
        emit(tag, p .. ".other", string.format("%.5f", q15(e + 0x30)))
        emit(tag, p .. ".requested.#1", string.format("%s %s %s",
            SL.num(fix5(e + 0x18)), SL.num(fix5(e + 0x20)),
            SL.num(fix5(e + 0x28))))
        emit(tag, p .. ".received.#1", string.format("%s %s %s",
            SL.num(fix5(e + 0x38)), SL.num(fix5(e + 0x40)),
            SL.num(fix5(e + 0x48))))
    end
    hist_entry(fs + 0x60, -1)
    local hbase = rp(fs + 0xB0)
    if SL.kptr(hbase) then
        for j = 0, 23 do
            hist_entry(hbase + 80 * j, j)
        end
    end
end }
