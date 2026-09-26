-- disable_supply.lua — 供给禁用 + 贸易降频 + 单位补给钉满
--
-- 依赖：桥内置 hoi4.detour（Tier 2 函数体 detour）。三个 detour 在本文件
-- 顶层安装 —— detour 只允许在进程首次脚本加载期安装新目标（G0 门），
-- mod 平铺加载恰在该窗口内；之后同 id 重注册（热重载换回调）不受限。
--
-- 默认全关（对拍安全）：detour 补丁常驻，但回调首行直通 call_orig，
-- 行为与原版一致。运行时开关 = DISABLE_SUPPLY.on()/off()。
--
-- 三刀：
--   ds_trade   DoTradeRoutesUpdate(0x1D9890) 每小时 → 每日
--              （门条件复刻引擎内部每日门，与 45 天轮转置脏同拍）
--   ds_supply  CSupplySystem::UpdateSupply(0xECD400) 吞掉
--              （本体级：同时覆盖 hourly 与读档路径入口；返回 0 已核实
--               无消费者 —— ECA270 result 被虚调用覆盖、hourly/DD9B20 丢弃）
--   pin        每游戏小时遍历活跃国全师写 CUnit+64 = 100000
--              （有效补给比 = clamp(max(+64, 储备比)) —— 满比即全部惩罚
--               消费点归零；+1176 缺补天数由 CArmy[19] 日 tick 自动清零）

local STATE = rawget(_G, "DISABLE_SUPPLY_STATE")
if not STATE then
    STATE = { trade = false, supply = false, pin = false,
              skipped = 0, gated = 0, passed = 0, pinned = 0, last_hour = -1 }
    rawset(_G, "DISABLE_SUPPLY_STATE", STATE)
end

local function read_gs()
    local b = hoi4.base()
    if not b or b == 0 then return nil end
    local gs = hoi4.read_u64(b + 0x332F260)
    if not gs or gs == 0 then return nil end
    return gs
end

local ok, err = pcall(function()
    -- 刀② SUPPLY_OFF：UpdateSupply 本体（hourly wrapper 与读档路径全走这里）
    hoi4.detour(0xECD400, function(ctx)
        if not STATE.supply then return ctx.call_orig() end
        STATE.skipped = STATE.skipped + 1
        return 0
    end, { id = "ds_supply", ret = "u64", args = 2 })

    -- 刀① TRADE_DAILY：DoTradeRoutesUpdate 每小时 → 每日（ret=void，吞即跳过）
    -- ⚠ 门的小时值必须读全局 gs（base+0x332F260 槽）+1128 —— D9890 的第一参
    -- a1 实测不是 gs（a1+1128 处是另一对象的快速变化字段，实测值 ~155 万级、
    -- tick 间非单调），不能用作门源。
    hoi4.detour(0x1D9890, function(ctx)
        if not STATE.trade then return ctx.call_orig() end
        local gs = read_gs()
        if not gs then return ctx.call_orig() end
        local h = hoi4.read_u32(gs + 1128)
        if ((h - 43800000) % 24) ~= 0 then
            STATE.gated = STATE.gated + 1
            return
        end
        STATE.passed = STATE.passed + 1
        return ctx.call_orig()
    end, { id = "ds_trade", ret = "void", args = 2 })
end)
if not ok then
    hoi4.log("disable_supply: detour install FAILED: " .. tostring(err))
else
    hoi4.log("disable_supply: detours installed (default OFF)")
end

-- 刀③ ARMY_PIN：每游戏小时，活跃国全师 CUnit+64 = 100000
hoi4.every(1000, function()
    if not STATE.pin then return end
    local ok2, err2 = pcall(function()
        local gs = read_gs()
        if not gs then return end
        local h = hoi4.read_u32(gs + 1128)
        if h == STATE.last_hour then return end          -- 每游戏小时一次
        STATE.last_hour = h
        local arr = hoi4.read_u64(gs + 784)
        if not arr or arr == 0 then return end
        local n = hoi4.read_u32(gs + 796)
        for i = 1, n - 1 do                               -- 0 号无效国
            local cc = hoi4.read_u64(arr + 8 * i)
            if cc and cc ~= 0 and hoi4.read_u32(cc + 1156) > 0 then
                local data = hoi4.read_u64(cc + 656)      -- 师容器 {data, count@+12}
                local cnt = hoi4.read_u32(cc + 668)
                if data and data ~= 0 and cnt > 0 then
                    for j = 0, cnt - 1 do
                        local army = hoi4.read_u64(data + 8 * j)
                        if army and army ~= 0 then
                            if hoi4.read_u32(army + 64) ~= 100000 then
                                hoi4.write_u32(army + 64, 100000)
                                STATE.pinned = STATE.pinned + 1
                            end
                        end
                    end
                end
            end
        end
    end)
    if not ok2 then hoi4.log("disable_supply pin loop: " .. tostring(err2)) end
end)

DISABLE_SUPPLY = {
    -- on() / on(trade, supply, pin)：缺省参数 = true
    on = function(trade, supply, pin)
        STATE.trade  = (trade  == nil) or (trade  and true or false)
        STATE.supply = (supply == nil) or (supply and true or false)
        STATE.pin    = (pin    == nil) or (pin    and true or false)
        return string.format("trade=%s supply=%s pin=%s",
            tostring(STATE.trade), tostring(STATE.supply), tostring(STATE.pin))
    end,
    off = function()
        STATE.trade, STATE.supply, STATE.pin = false, false, false
        return "all disabled (detours stay installed, callbacks pass through)"
    end,
    status = function()
        local dt = hoi4.detour_status and hoi4.detour_status("ds_trade")
        local ds = hoi4.detour_status and hoi4.detour_status("ds_supply")
        return { state = STATE, trade = dt, supply = ds }
    end,
    probe = function(addr) return hoi4.detour_probe(addr) end,
}

-- ---------------------------------------------------------------- 决议开关
-- common/decisions/ds_toggles.txt 的双状态决议对置/清全局旗 (DS_*_ON, 仅 UI
-- 态) 并调用这里注册的同名效果立即生效。STATE 不落盘——读档后回到默认全
-- 关，决议栏旗若残留 ON，点一次 off 再 on 对齐即可（实验 mod 不做持久化）。
hoi4.effect("ds_supply_on",  function() STATE.supply = true  return "supply=on"  end)
hoi4.effect("ds_supply_off", function() STATE.supply = false return "supply=off" end)
hoi4.effect("ds_trade_on",   function() STATE.trade  = true  return "trade=on"  end)
hoi4.effect("ds_trade_off",  function() STATE.trade  = false return "trade=off" end)
hoi4.effect("ds_pin_on",     function() STATE.pin    = true  return "pin=on"    end)
hoi4.effect("ds_pin_off",    function() STATE.pin    = false return "pin=off"   end)
hoi4.log("disable_supply: 6 decision effects registered")
