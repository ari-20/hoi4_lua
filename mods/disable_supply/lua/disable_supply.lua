-- disable_supply.lua — 供给禁用 + 贸易降频 + 单位补给钉满
--
-- 依赖：桥内置 hoi4.detour（Tier 2 函数体 detour）。三个 detour 在本文件
-- 顶层安装 —— detour 只允许在进程首次脚本加载期安装新目标（G0 门），
-- mod 平铺加载恰在该窗口内；之后同 id 重注册（热重载换回调）不受限。
--
-- 默认全关（对拍安全）：detour 补丁常驻，但回调首行直通 call_orig，
-- 行为与原版一致。运行时开关 = DISABLE_SUPPLY.on()/off()。
--
-- 刀清单 (挂三个开关下)：
--   ds_trade   DoTradeRoutesUpdate(0x1D9890) 每小时 → 每日
--              （门条件复刻引擎内部每日门，与 45 天轮转置脏同拍）
--   ds_supply  CSupplySystem::UpdateSupply(0xECD400) 吞掉
--              （本体级：同时覆盖 hourly 与读档/世界构建路径入口；返回 0
--               已核实无消费者 —— ECA270 result 被虚调用覆盖、hourly/
--               DD9B20 丢弃）
--   pin        每游戏小时遍历活跃国全师写 CUnit+64 = 100000
--              （有效补给比 = clamp(max(+64, 储备比)) —— 满比即全部惩罚
--               消费点归零；+1176 缺补天数由 CArmy[19] 日 tick 自动清零）
--   ds_topbar  顶栏后勤满足度 (0x121F1D0) 输出钉 100000（显示面，随 supply 开关）
--   ds_move    移动供应阈值门 (0x140C00590) 强制"不低于阈值"（解除拒动，随 pin
--              开关；该门直读供应系统数据，+64 钉满也不解除）
--   fill       数据面补写（显示面，随 supply 开关）: 发布器逐省值 → 1200000
--              （= BEST_FLOW_DISPLAY 12.0 × 1e5，地图 reach 档满色）+
--              每国 calc 记录 +312 = 100000
--
-- ⚠ 会话边界纪律（2026-09-26 崩溃定案，archive/t93_crash/）：
--   detour 补丁常驻进程、STATE 表也跨"回主菜单→新开一局"存活（gs 槽不
--   重写、无会话事件），但**新局世界构建期的 UpdateSupply 调用负责建立
--   供给运行时表**（CCountrySupplySystem+128 每国 800B 记录内部表）——
--   刀开着跨局 = 构建调用被吞 = 表未建 = 引擎读空表崩（同日 6 崩实证）。
--   因此三刀必须在新世界开始时回默认关：注册 __hoi4_on_session_start
--   钩子重置（桥的 idler 沿检测保证菜单往返也派发该事件）。
local STATE = rawget(_G, "DISABLE_SUPPLY_STATE")
if not STATE then
    STATE = { trade = false, supply = false, pin = false,
              skipped = 0, gated = 0, passed = 0, pinned = 0, filled = 0,
              refilled = 0, move_hits = 0, last_hour = -1, fill_hour = -1 }
    rawset(_G, "DISABLE_SUPPLY_STATE", STATE)
end

-- 字段补齐：STATE 表跨代/热重载存活（rawget 复用），新增字段不会自动出现，
-- 缺项按默认值补（否则热重载后首次访问 = nil 算术语义崩溃）。
for k, v in pairs({ filled = 0, refilled = 0, move_hits = 0, fill_hour = -1 }) do
    if STATE[k] == nil then STATE[k] = v end
end

-- 新会话（含"回主菜单→新开一局"沿）：全部刀回默认关。
-- 防重注册：钩子是全局函数名，重 dofile 直接覆盖旧闭包即可。
function __hoi4_on_session_start()
    if STATE.trade or STATE.supply or STATE.pin then
        STATE.trade, STATE.supply, STATE.pin = false, false, false
        STATE.last_hour, STATE.fill_hour = -1, -1
        hoi4.log("disable_supply: session start -> knives reset to OFF "
            .. "(world rebuild must not be swallowed)")
    end
end

local function read_gs()
    local b = hoi4.base()
    if not b or b == 0 then return nil end
    local gs = hoi4.read_u64(b + 0x332F260)
    if not gs or gs == 0 then return nil end
    return gs
end

-- 显示面数据补写（fill，仅 STATE.supply 开时有意义）：
--   · 发布器 (BASE+0x30B3C48 数据槽 / +0x30B3C54 计数槽) 逐省值 = 1200000
--     = BEST_FLOW_DISPLAY(12.0)×1e5 —— 地图 reach 档满色饱和点（实测真值
--     上限 ~15.1）。
--   · 每国 calc 记录 (css+128) +312 = 100000（后勤满足度因子）。
-- 计数上界 sanity 100000；返回本次实际写入数。
local function fill_display(gs)
    local b = hoi4.base()
    if not b or b == 0 then return 0 end
    local sys = hoi4.read_u64(gs + 984)
    if not sys or sys == 0 then return 0 end
    local n = 0
    local carr = hoi4.read_u64(sys + 264)
    local ccnt = hoi4.read_u32(sys + 276)
    if carr and carr ~= 0 and ccnt > 0 and ccnt < 100000 then
        for i = 0, ccnt - 1 do
            local el = hoi4.read_u64(carr + 8 * i)
            if el and el ~= 0 then
                local calc = hoi4.read_u64(el + 128)
                if calc and calc ~= 0 and hoi4.read_u64(calc + 312) ~= 100000 then
                    hoi4.write_u64(calc + 312, 100000)
                    n = n + 1
                end
            end
        end
    end
    local pd = hoi4.read_u64(b + 0x30B3C48)
    local pc = hoi4.read_u32(b + 0x30B3C54)
    if pd and pd ~= 0 and pc > 0 and pc < 100000 then
        for i = 0, pc - 1 do
            if hoi4.read_u64(pd + 8 * i) ~= 1200000 then
                hoi4.write_u64(pd + 8 * i, 1200000)
                n = n + 1
            end
        end
    end
    return n
end

local ok, err = pcall(function()
    -- 世界重建放行门：会话切换事件已置但帧顶尚未派发的窗口内（in-place
    -- 读档的重建在 DA04F0 内部同步完成、菜单往返重建在 FE 帧上推进，均早于
    -- 派发），UpdateSupply 的调用是**建表调用**——吞掉 = 供给运行时表为空 =
    -- 引擎读空表崩（2026-09-26 两轮崩溃定案）。桥的 pending 标志 = 纯事件
    -- 语义（DR 断点已证入口），非变量指纹启发式。
    local rebuild_window = function()
        return hoi4.session_pending and hoi4.session_pending() or false
    end

    -- 刀② SUPPLY_OFF：UpdateSupply 本体（hourly wrapper 与读档/世界构建路径全走这里）
    hoi4.detour(0xECD400, function(ctx)
        if not STATE.supply then return ctx.call_orig() end
        if rebuild_window() then return ctx.call_orig() end
        STATE.skipped = STATE.skipped + 1
        return 0
    end, { id = "ds_supply", ret = "u64", args = 2 })

    -- 刀① TRADE_DAILY：DoTradeRoutesUpdate 每小时 → 每日（ret=void，吞即跳过）
    -- ⚠ 门的小时值必须读全局 gs（base+0x332F260 槽）+1128 —— D9890 的第一参
    -- a1 实测不是 gs（a1+1128 处是另一对象的快速变化字段，实测值 ~155 万级、
    -- tick 间非单调），不能用作门源。
    hoi4.detour(0x1D9890, function(ctx)
        if not STATE.trade then return ctx.call_orig() end
        if hoi4.session_pending and hoi4.session_pending() then
            return ctx.call_orig()          -- 世界重建窗口: 建表调用不吞 (同上)
        end
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

    -- 刀④ TOPBAR_FULL：顶栏后勤满足度强制满分（显示面，随 supply 开关）。
    -- ⚠ 常数形参映射：普通函数 thunk = (RCX, RDX, R8, R9)，即 ctx.this = 第一
    -- 实参 (css)、ctx.a1 = 第二实参 (out 指针)。写前形态自检（css+128 =
    -- calc 记录堆指针），不符直通原函数——防映射误判写坏对象头。
    hoi4.detour(0x121F1D0, function(ctx)
        if not STATE.supply then return ctx.call_orig() end
        local css, out = ctx.this, ctx.a1
        if css and css ~= 0 and out and out ~= 0 then
            local calc = hoi4.read_u64(css + 128)
            if calc and calc >= 0x10000 and calc < 0x7FF000000000
               and out >= 0x10000 and out < 0x7FF000000000 then
                hoi4.write_u64(out, 100000)
                return out
            end
        end
        return ctx.call_orig()
    end, { id = "ds_topbar", ret = "u64", args = 2 })

    -- 刀⑤ MOVE_RELEASE：移动供应阈值门强制"不低于阈值"（解除拒动，随 pin 开关）。
    -- 唯一调用者 1414D9280 unitcontroller 移动校验；返回 true = 拒动分支
    -- (落 unit+590=1 / unit+680=3)。门内直读供应系统数据，且裸读 unit+64
    -- 作阈值比较——有效比钉满也不解除，故钉补给的开关一并管这刀。
    hoi4.detour(0xC00590, function(ctx)
        if not STATE.pin then return ctx.call_orig() end
        if rebuild_window() then return ctx.call_orig() end
        STATE.move_hits = STATE.move_hits + 1
        return 0
    end, { id = "ds_move", ret = "bool", args = 3 })
end)
if not ok then
    hoi4.log("disable_supply: detour install FAILED: " .. tostring(err))
else
    hoi4.log("disable_supply: detours installed (default OFF)")
end

-- 刀③ ARMY_PIN（+ supply 的显示面数据补写）：每游戏小时，活跃国全师
-- CUnit+64 = 100000 + 储备 = 上限；supply 开时同拍补写显示面（发布器/calc，
-- 24 游戏小时节流一次防高倍速反复写）。
hoi4.every(1000, function()
    if not (STATE.pin or STATE.supply) then return end
    local ok2, err2 = pcall(function()
        local gs = read_gs()
        if not gs then return end
        local h = hoi4.read_u32(gs + 1128)
        if h == STATE.last_hour then return end          -- 每游戏小时一次
        STATE.last_hour = h
        if STATE.pin then
            local arr = hoi4.read_u64(gs + 784)
            if arr and arr ~= 0 then
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
                                    -- 储备 = 上限：清 tooltip "储备 %"（vt[48]
                                    -- 储备比）及只读储备的下游；+64 钉满使每小时
                                    -- 储备链走增益支（分支门 +64>=100000），写满
                                    -- 后自维持不衰减。
                                    local mx = hoi4.read_u64(army + 1536)
                                    if mx and mx > 0 and hoi4.read_u64(army + 1552) < mx then
                                        hoi4.write_u64(army + 1552, mx)
                                        STATE.refilled = STATE.refilled + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if STATE.supply then
            if STATE.fill_hour < 0 or (h - STATE.fill_hour) >= 24 then
                STATE.filled = STATE.filled + fill_display(gs)
                STATE.fill_hour = h
            end
        end
    end)
    if not ok2 then hoi4.log("disable_supply pin/fill loop: " .. tostring(err2)) end
end)

DISABLE_SUPPLY = {
    -- on() / on(trade, supply, pin)：缺省参数 = true
    --   supply 开关 = 吞重算 + 显示面（顶栏 detour / 发布器与 calc 数据补写）
    --   pin    开关 = 钉全师 +64/储备 + 解除缺补给移动拒动
    on = function(trade, supply, pin)
        STATE.trade  = (trade  == nil) or (trade  and true or false)
        STATE.supply = (supply == nil) or (supply and true or false)
        STATE.pin    = (pin    == nil) or (pin    and true or false)
        if STATE.supply then STATE.fill_hour = -1 end      -- 立即补写一拍
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
        local db = hoi4.detour_status and hoi4.detour_status("ds_topbar")
        local dm = hoi4.detour_status and hoi4.detour_status("ds_move")
        return { state = STATE, trade = dt, supply = ds, topbar = db, move = dm }
    end,
    probe = function(addr) return hoi4.detour_probe(addr) end,
}

-- ---------------------------------------------------------------- 决议开关
-- common/decisions/ds_toggles.txt 的双状态决议对置/清全局旗 (DS_*_ON, 仅 UI
-- 态) 并调用这里注册的同名效果立即生效。STATE 不落盘也不跨局——新会话
-- 由 __hoi4_on_session_start 重置回默认全关，决议栏旗若残留 ON，点一次
-- off 再 on 对齐即可（实验 mod 不做持久化）。
hoi4.effect("ds_supply_on",  function() STATE.supply = true  return "supply=on"  end)
hoi4.effect("ds_supply_off", function() STATE.supply = false return "supply=off" end)
hoi4.effect("ds_trade_on",   function() STATE.trade  = true  return "trade=on"  end)
hoi4.effect("ds_trade_off",  function() STATE.trade  = false return "trade=off" end)
hoi4.effect("ds_pin_on",     function() STATE.pin    = true  return "pin=on"    end)
hoi4.effect("ds_pin_off",    function() STATE.pin    = false return "pin=off"   end)
hoi4.log("disable_supply: 6 decision effects registered")

-- ---------------------------------------------------------------- 决议可见性
-- 决议栏 visible 一律以 Lua trigger 读 STATE 真值 —— 全局旗方案会漂移：
-- 旗随存档/持久化、STATE 每会话复位（见文件头会话边界纪律），且经控制台
-- hot 开关时旗不同步，决议栏会显示与实际相反的一侧。trigger 与 STATE 同源
-- 则永不漂移；回调返回值必须为真布尔（桥按 lua_toboolean 判定）。
hoi4.trigger("ds_trade_active",  function() return STATE.trade  == true end)
hoi4.trigger("ds_supply_active", function() return STATE.supply == true end)
hoi4.trigger("ds_pin_active",    function() return STATE.pin    == true end)
hoi4.log("disable_supply: 3 decision-visibility triggers registered")
