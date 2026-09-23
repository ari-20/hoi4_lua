-- sv2_sec_weather.lua -- weather 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "weather", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8, ru16 =
        hoi4.read_u64, hoi4.read_u32, hoi4.read_u8, hoi4.read_u16
    -- §4.20.1 CWeatherManager (gs+1672)
    local r2 = O:weather()
    if not r2 then return end
    local function E(path, val) emit("weather", path, val) end

    -- ===== 顶格叶 (恒写; 读失败则缺省跳过, 不伪造 0) =====
    if r2.seed then E("seed", tostring(r2.seed)) end
    if r2.current_province then
        E("current_province", tostring(r2.current_province))
    end
    if r2.current_region then E("current_region", tostring(r2.current_region)) end

    -- ===== 省天气族: provinces.<pid>.* (pid 升序 = 存档文档序) —
    -- §4.20.2 SWeatherPerProvince =====
    local pids = {}
    for pid in pairs(r2.provinces or {}) do pids[#pids + 1] = pid end
    table.sort(pids)
    for _, pid in ipairs(pids) do
        local wp = r2.provinces[pid]
        local base = "provinces." .. pid
        E(base .. ".province", tostring(wp.province_id or pid))
        local t = wp.temperature -- 恒写 (含 0)
        if t then E(base .. ".temperature", SL.num(t)) end
        local v = wp.temperature_offset -- 仅非零
        if v and v ~= 0 then E(base .. ".temperature_offset", SL.num(v)) end
        v = wp.water -- 仅非零
        if v and v ~= 0 then E(base .. ".water", SL.num(v)) end
        v = wp.snow -- 仅非零
        if v and v ~= 0 then E(base .. ".snow", SL.num(v)) end
        v = wp.mud -- 仅非零 yes
        if v and v ~= 0 then E(base .. ".mud", "yes") end
        local cm = wp.custom_modifiers -- 块仅 cnt>0; 16B {名*, param u32@+8}
        if cm then
            local seq = SL.seqc()
            for _, m in ipairs(cm) do
                if m.name and m.name ~= "" then
                    local p = m.param or 0
                    p = GAME.layout.as_i32(p) -- i32 有符号
                    E(base .. ".custom_modifiers." .. seq(m.name), tostring(p))
                end
            end
        end
    end

    -- ===== 区域天气族: regions.<rid>.* (rid 升序) —
    -- §4.20.3 SWeatherPerRegion =====
    local rids = {}
    for rid in pairs(r2.regions or {}) do rids[#rids + 1] = rid end
    table.sort(rids)
    -- 仅非零写 yes 的 u8 旗标 (off, save键) — 与 writer 0x140F0DDC0 逐支对齐
    local RFLAG = {
        { 0x108, "rain_light" }, { 0x110, "rain_heavy" }, { 0x118, "snow" },
        { 0x120, "blizzard" }, { 0x128, "sandstorm" }, { 0x130, "arctic_water" },
    }
    for _, rid in ipairs(rids) do
        local wr = r2.regions[rid]
        local base = "regions." .. rid
        E(base .. ".region", tostring(wr.region_id or rid))
        local t = wr.temperature -- 恒写 (含 0)
        if t then E(base .. ".temperature", SL.num(t)) end
        local e = wr._addr
        if e and SL.kptr(e) then
            -- next_weather_change 恒写: CGameDate@+0x158, hours = ru32@+0x150
            local dh = ru32(e + 0x150)
            local ds = dh and SL.date(dh)
            if ds then
                E(base .. ".next_weather_change", '"' .. ds .. '"')
            end
            for _, f in ipairs(RFLAG) do
                local b = ru8(e + f[1])
                if b and b ~= 0 then E(base .. "." .. f[2], "yes") end
            end
            -- active_modifiers: u16 数组 {d@+0x30, cnt@+0x3C} — writer
            -- 0x140F0DDC0 尾段: AEF00 开单匿名元在循环外, 循环内 ADAB0
            -- 逐值写 + 分隔补写 → 存档形态 = 单行 "v1 v2 ..."
            -- (非演化族, 旧逐值 #N 行为对 cnt=1 巧合对齐)
            local nact = ru32(e + 0x3C)
            local ap = rp(e + 0x30)
            if nact and nact > 0 and nact < GAME.layout.lim.PTR_SANE and SL.kptr(ap) then
                local parts = {}
                for ai = 0, nact - 1 do
                    parts[#parts + 1] = tostring(ru16(ap + 2 * ai) or 0)
                end
                E(base .. ".active_modifiers.#1", table.concat(parts, " "))
            end
        end
    end
end }
