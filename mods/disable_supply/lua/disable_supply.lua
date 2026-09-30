-- disable_supply.lua — 供给禁用 + 贸易降频 + 单位补给钉满
--
-- 依赖：桥内置 hoi4.detour（Tier 2 函数体 detour）。四个 detour 在本文件
-- 顶层安装 —— detour 只允许在进程首次脚本加载期安装新目标（G0 门），
-- mod 平铺加载恰在该窗口内；之后同 id 重注册（热重载换回调）不受限。
-- ⚠ hoi4.detour 拒绝时返回 (nil, err) 不抛错 —— 安装一律走 install()
-- 包装逐个查返回值（2026-09-28 实测: E255E0 序言含相对跳转被拒, pcall
-- 静默吞掉, 刀失联无人知晓）。
--
-- 默认全关（对拍安全）：detour 补丁常驻，但回调首行直通 call_orig，
-- 行为与原版一致。开关态三源合流：
--   · 全局旗 DS_TRADE_ON / DS_SUPPLY_ON / DS_PIN_ON / DS_ACCESS_ON =
--     **持久真值**
--     （写在存档里 ⇒ save/load 可恢复；决议栏 visible 一律读
--     has_global_flag ⇒ 零 Lua 求值，不再有 trigger 刷屏）
--   · STATE = 运行期镜像：游戏内会话派发时读旗恢复；菜单帧派发一律复位 OFF
--   · 三条改态路径（决议 / DISABLE_SUPPLY.on() / 控制台直改旗）由每秒一次的
--     对账收敛（旗赢），世界未就绪/构建窗口内对账不动作
--
-- 刀清单 (挂四个开关下)：
--   ds_trade   DoTradeRoutesUpdate(0x1D9890) 每小时 → 每日
--              （门条件复刻引擎内部每日门，与 45 天轮转置脏同拍）
--   ds_supply  CSupplySystem::UpdateSupply(0xECD400) 吞掉
--              （本体级：同时覆盖 hourly 与读档/世界构建路径入口；返回 0
--               已核实无消费者 —— ECA270 result 被虚调用覆盖、hourly/
--               DD9B20 丢弃）
--   pin        每游戏小时遍历活跃国全师写 CUnit+64 = 100000
--              （有效补给比 = clamp(max(+64, 储备比)) —— 满比即全部惩罚
--               消费点归零；+1176 缺补天数由 CArmy[19] 日 tick 自动清零）
--   ds_move    移动供应阈值门 (0x140C00590) 强制"不低于阈值"（解除拒动，随 pin
--              开关；该门直读供应系统数据，+64 钉满也不解除）
--   ds_access  海军可达性重建 每小时 → 每日（目标 0xE24860 并行派发体,
--              真名 Update CNavalAccessibilityManager; 门条件同 ds_trade;
--              启用后首拍直通一次——可达性槽位唯一重建路径 = hourly 相位 8,
--              读档/新开局后不先放行一拍则槽位空置最长 24h, 海军寻路会坏
--              一整天。代价：海峡/邻接权变更后海军寻路最多滞后到下一个 0 点
--              相位。调用方在调用返回后无条件复位管理器 +32 旗, 吞调用不留
--              残旗。⚠ 不 detour 0xE255E0 包装体: 序言含 je rel8 不可搬移）
--   fill       数据面补写（显示面，随 supply 开关）: 发布器逐省值 → 1200000
--              （= BEST_FLOW_DISPLAY 12.0 × 1e5，地图 reach 档满色）+
--              每国 calc 记录 +312 = 100000
--              ⚠ 顶栏后勤满足度读侧 = calc+312 × 火车比 × 流量比（0x121F1D0），
--              钉住 calc+312 即钉住显示面。旧的 ds_topbar detour 已删：它写
--              第二实参 out —— 那是**调用方栈上缓冲**，写域门按防 ROP 策略
--              拒写，22 万条审计/16 万行日志全来自这条无效写（2026-09-27）。
--
-- ⚠ 会话边界纪律（2026-09-26 崩溃定案，archive/t93_crash/）：
--   detour 补丁常驻进程、STATE 表也跨"回主菜单→新开一局"存活（gs 槽不
--   重写、无会话事件），但**新局世界构建期的 UpdateSupply 调用负责建立
--   供给运行时表**（CCountrySupplySystem+128 每国 800B 记录内部表）——
--   刀开着跨局 = 构建调用被吞 = 表未建 = 引擎读空表崩（同日 6 崩实证）。
--   因此：菜单帧会话派发（in_game=false）一律复位 OFF；只有**游戏内派发**
--   （in_game=true，世界已建成）才按旗恢复。桥侧钩子签名
--   __hoi4_on_session_start(in_game)（旧 0 参写法仍兼容）。
local STATE = rawget(_G, "DISABLE_SUPPLY_STATE")
if not STATE then
    STATE = { trade = false, supply = false, pin = false, access = false,
              synced = false, skipped = 0, gated = 0, passed = 0, pinned = 0,
              filled = 0, refilled = 0, move_hits = 0, last_hour = -1,
              fill_hour = -1, access_gated = 0, access_passed = 0,
              access_latch = false }
    rawset(_G, "DISABLE_SUPPLY_STATE", STATE)
end

-- 字段补齐：STATE 表跨代/热重载存活（rawget 复用），新增字段不会自动出现，
-- 缺项按默认值补（否则热重载后首次访问 = nil 算术语义崩溃）。
for k, v in pairs({ filled = 0, refilled = 0, move_hits = 0, fill_hour = -1,
                    synced = false, access = false, access_gated = 0,
                    access_passed = 0, access_latch = false }) do
    if STATE[k] == nil then STATE[k] = v end
end

local FLAGS = { trade = "DS_TRADE_ON", supply = "DS_SUPPLY_ON", pin = "DS_PIN_ON",
                access = "DS_ACCESS_ON" }

local function read_gs()
    local b = hoi4.base()
    if not b or b == 0 then return nil end
    local gs = hoi4.read_u64(b + 0x332F260)
    if not gs or gs == 0 then return nil end
    return gs
end

-- ---------------------------------------------------------------- 全局旗读写
-- CFlagManager = gs+600 (§1.2 / §4.13.3): entries@+8 / count@+0x14，
-- 条目 48B: token@+8 (int) / 值@+40 (i16，非 0 = 置位)。token 走桥
-- hoi4.name_to_token（旗用 lexer token id，非 FNV 哈希）。
-- flag_read -> true / false（条目不存在 = 未置）/ nil（读不到：无 gs、
-- token 未注册、容器未就绪 —— 一律不动刀）。
local function flag_read(name)
    local gs = read_gs()
    if not gs then return nil end
    local tok = hoi4.name_to_token and hoi4.name_to_token(name)
    if not tok or tok == 0 then return nil end
    local store = hoi4.read_u64(gs + 600)
    if not store or store == 0 then return nil end
    local d = hoi4.read_u64(store + 8)
    local cnt = hoi4.read_u32(store + 0x14)
    if not d or d == 0 or not cnt or cnt > 100000 then return nil end
    for i = 0, cnt - 1 do
        local e = d + 48 * i
        if hoi4.read_u32(e + 8) == tok then
            return ((hoi4.read_u32(e + 40) or 0) % 65536) ~= 0
        end
    end
    return false
end

-- 控制台写旗：set_global_flag <名> [值]（缺省 = 1；0 = 置 0，条目不能删）。
-- 返回 true/false（读回校验），nil = 读不回（世界未就绪，不判失败）。
local function flag_write(name, on)
    hoi4.console("set_global_flag " .. name .. (on and "" or " 0"))
    local v = flag_read(name)
    if v == nil then return nil end
    return v == (on and true or false)
end

-- 世界就绪门：gs 有效 + 无待派发会话事件 + HasGameStarted 门 (gs+2617) 已开。
-- 构建窗口内（菜单帧构建新局 / 读档重建）三条件必有其一不满足。
local function world_ready()
    local gs = read_gs()
    if not gs then return false end
    if hoi4.session_pending and hoi4.session_pending() then return false end
    return hoi4.read_u8(gs + 2617) == 1
end

-- 旗 → STATE 对账（旗赢）。只在"本会话已被游戏内派发认领 (synced)
-- 且世界就绪"时动作 —— 构建窗口绝不动刀。
local function sync_from_flags()
    if not STATE.synced or not world_ready() then return false end
    local t, s, p = flag_read(FLAGS.trade), flag_read(FLAGS.supply), flag_read(FLAGS.pin)
    local a = flag_read(FLAGS.access)
    if t == nil or s == nil or p == nil or a == nil then return false end
    if t == STATE.trade and s == STATE.supply and p == STATE.pin and a == STATE.access then
        return false
    end
    STATE.trade, STATE.supply, STATE.pin, STATE.access = t, s, p, a
    if s then STATE.fill_hour = -1 end              -- 立即补写一拍
    if a then STATE.access_latch = false end        -- 换挡后首拍放行重建
    STATE.last_hour = -1
    hoi4.log(string.format(
        "disable_supply: flags -> STATE synced (trade=%s supply=%s pin=%s access=%s)",
        tostring(t), tostring(s), tostring(p), tostring(a)))
    return true
end

local function reset_off(why)
    if STATE.trade or STATE.supply or STATE.pin or STATE.access then
        STATE.trade, STATE.supply, STATE.pin, STATE.access = false, false, false, false
        STATE.last_hour, STATE.fill_hour = -1, -1
        hoi4.log("disable_supply: knives reset to OFF (" .. why .. ")")
    end
end

-- 新会话/装载沿（含"回主菜单→新开一局"）。in_game=true = 世界已建成
-- （读档完成 / 新局构建完），此时才允许按旗恢复刀态；菜单帧派发必须回关。
function __hoi4_on_session_start(in_game)
    STATE.synced = false
    if in_game then
        STATE.synced = true
        local t, s, p = flag_read(FLAGS.trade), flag_read(FLAGS.supply), flag_read(FLAGS.pin)
        local a = flag_read(FLAGS.access)
        STATE.trade, STATE.supply, STATE.pin, STATE.access = t == true, s == true, p == true, a == true
        STATE.access_latch = false                   -- 新世界首拍放行重建
        STATE.last_hour, STATE.fill_hour = -1, -1
        hoi4.log(string.format(
            "disable_supply: in-game session start -> flags restored (trade=%s supply=%s pin=%s access=%s)",
            tostring(STATE.trade), tostring(STATE.supply), tostring(STATE.pin), tostring(STATE.access)))
    else
        reset_off("menu-frame session start; world rebuild must not be swallowed")
    end
end

-- 显示面数据补写（fill，仅 STATE.supply 开时有意义）：
--   · 发布器 (BASE+0x30B3C48 数据槽 / +0x30B3C54 计数槽) 逐省值 = 1200000
--     = BEST_FLOW_DISPLAY(12.0)×1e5 —— 地图 reach 档满色饱和点（实测真值
--     上限 ~15.1）。
--   · 每国 calc 记录 (css+128) +312 = 100000（后勤满足度因子；顶栏读侧
--     0x121F1D0 = 本值 × 火车比 × 流量比）。
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
    -- hoi4.detour 对拒绝 (G0 窗口外/序言不可搬移/表满) 返回 (nil, err) 而
    -- 不抛错 —— pcall 捕获不到, 必须逐个查返回值, 否则刀静默失联。
    local function install(addr, cb, opts)
        local hid, herr = hoi4.detour(addr, cb, opts)
        if not hid then
            hoi4.log("disable_supply: detour " .. tostring(opts and opts.id or addr)
                     .. " REFUSED: " .. tostring(herr))
        end
        return hid
    end
    -- 世界重建放行门：会话切换事件已置但帧顶尚未派发的窗口内（in-place
    -- 读档的重建在 DA04F0 内部同步完成、菜单往返重建在 FE 帧上推进，均早于
    -- 派发），UpdateSupply 的调用是**建表调用**——吞掉 = 供给运行时表为空 =
    -- 引擎读空表崩（2026-09-26 两轮崩溃定案）。桥的 pending 标志 = 纯事件
    -- 语义（DR 断点已证入口），非变量指纹启发式。
    local rebuild_window = function()
        return hoi4.session_pending and hoi4.session_pending() or false
    end

    -- 刀② SUPPLY_OFF：UpdateSupply 本体（hourly wrapper 与读档/世界构建路径全走这里）
    install(0xECD400, function(ctx)
        if not STATE.supply then return ctx.call_orig() end
        if rebuild_window() then return ctx.call_orig() end
        STATE.skipped = STATE.skipped + 1
        return 0
    end, { id = "ds_supply", ret = "u64", args = 2 })

    -- 刀① TRADE_DAILY：DoTradeRoutesUpdate 每小时 → 每日（ret=void，吞即跳过）
    -- ⚠ 门的小时值必须读全局 gs（base+0x332F260 槽）+1128 —— D9890 的第一参
    -- a1 实测不是 gs（a1+1128 处是另一对象的快速变化字段，实测值 ~155 万级、
    -- tick 间非单调），不能用作门源。
    install(0x1D9890, function(ctx)
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

    -- 刀⑤ MOVE_RELEASE：移动供应阈值门强制"不低于阈值"（解除拒动，随 pin 开关）。
    -- 唯一调用者 1414D9280 unitcontroller 移动校验；返回 true = 拒动分支
    -- (落 unit+590=1 / unit+680=3)。门内直读供应系统数据，且裸读 unit+64
    -- 作阈值比较——有效比钉满也不解除，故钉补给的开关一并管这刀。
    install(0xC00590, function(ctx)
        if not STATE.pin then return ctx.call_orig() end
        if rebuild_window() then return ctx.call_orig() end
        STATE.move_hits = STATE.move_hits + 1
        return 0
    end, { id = "ds_move", ret = "bool", args = 3 })

    -- 刀⑥ ACCESS_DAILY：海军可达性重建 每小时 → 每日。
    -- 目标 = 0xE24860 (PdxParallelForContainer 派发体, 真名 Update
    -- CNavalAccessibilityManager 任务符号直证): 它是 0xE255E0 包装体
    -- (+32 旗门) 的唯一实质动作、也是全语料中它的唯一被调方——吞它等价
    -- 于吞掉整拍可达性重建。⚠ 不能直接 detour 0xE255E0: 其序言 offset 11
    -- 处 `74 1C` (je rel8, +32 旗判定分支) 含相对控制流, stolen-bytes
    -- 不可搬移, hk_probe 拒绝 ("prologue contains relative control flow",
    -- 2026-09-28 实测定案); 0xE24860 序言纯 mov/push/sub, 可搬移。
    -- ret=void 吞即跳过本拍并行重建。可达性槽位的唯一重建路径是 hourly
    -- 相位 8 (无独立载入重建), 故带**首拍闩**: knife 生效后 (含读档恢复 /
    -- 对账换挡) 第一次调用先放行整拍重建, 对齐原版"载入后一小时内必有
    -- 新鲜槽位"的行为, 之后才按日门节流。门条件与 ds_trade 同源
    -- (引擎日相位)。+32 旗由调用方在调用返回后无条件复位, 吞调用不留残旗。
    install(0xE24860, function(ctx)
        if not STATE.access then return ctx.call_orig() end
        if rebuild_window() then return ctx.call_orig() end
        if not STATE.access_latch then
            STATE.access_latch = true
            STATE.access_passed = STATE.access_passed + 1
            return ctx.call_orig()
        end
        local gs = read_gs()
        if not gs then return ctx.call_orig() end
        local h = hoi4.read_u32(gs + 1128)
        if ((h - 43800000) % 24) ~= 0 then
            STATE.access_gated = STATE.access_gated + 1
            return
        end
        STATE.access_passed = STATE.access_passed + 1
        return ctx.call_orig()
    end, { id = "ds_access", ret = "void", args = 3 })
end)
if not ok then
    hoi4.log("disable_supply: detour install FAILED: " .. tostring(err))
else
    hoi4.log("disable_supply: detours installed (default OFF, flags = DS_*_ON)")
end

-- 刀③ ARMY_PIN（+ supply 的显示面数据补写）：每游戏小时，活跃国全师
-- CUnit+64 = 100000 + 储备 = 上限；supply 开时同拍补写显示面（发布器/calc，
-- 24 游戏小时节流一次防高倍速反复写）。每秒先做一次旗→STATE 对账。
hoi4.every(1000, function()
    local ok2, err2 = pcall(function()
        sync_from_flags()
        if not (STATE.pin or STATE.supply) then return end
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
    -- on() / on(trade, supply, pin, access)：缺省参数 = true
    --   supply 开关 = 吞重算 + 显示面（发布器与 calc 数据补写）
    --   pin    开关 = 钉全师 +64/储备 + 解除缺补给移动拒动
    --   access 开关 = 海军可达性每小时 → 每日（首拍放行重建）
    -- 先写旗（持久真值）再改 STATE；读回校验失败会在返回值里带 warn。
    on = function(trade, supply, pin, access)
        trade  = (trade  == nil) or (trade  and true or false)
        supply = (supply == nil) or (supply and true or false)
        pin    = (pin    == nil) or (pin    and true or false)
        access = (access == nil) or (access and true or false)
        local v1 = flag_write(FLAGS.trade,  trade)
        local v2 = flag_write(FLAGS.supply, supply)
        local v3 = flag_write(FLAGS.pin,    pin)
        local v4 = flag_write(FLAGS.access, access)
        STATE.trade, STATE.supply, STATE.pin, STATE.access = trade, supply, pin, access
        STATE.synced = true
        if supply then STATE.fill_hour = -1 end            -- 立即补写一拍
        if access then STATE.access_latch = false end      -- 换挡后首拍放行
        STATE.last_hour = -1
        local warn = (v1 == false or v2 == false or v3 == false or v4 == false)
                     and " [WARN flag read-back mismatch]" or ""
        return string.format("trade=%s supply=%s pin=%s access=%s%s",
            tostring(trade), tostring(supply), tostring(pin), tostring(access), warn)
    end,
    off = function()
        flag_write(FLAGS.trade,  false)
        flag_write(FLAGS.supply, false)
        flag_write(FLAGS.pin,    false)
        flag_write(FLAGS.access, false)
        STATE.trade, STATE.supply, STATE.pin, STATE.access = false, false, false, false
        return "all disabled (flags cleared; detours stay installed, callbacks pass through)"
    end,
    status = function()
        local dt = hoi4.detour_status and hoi4.detour_status("ds_trade")
        local ds = hoi4.detour_status and hoi4.detour_status("ds_supply")
        local dm = hoi4.detour_status and hoi4.detour_status("ds_move")
        local da = hoi4.detour_status and hoi4.detour_status("ds_access")
        return { state = STATE, trade = dt, supply = ds, move = dm, access = da,
                 flags = { trade = flag_read(FLAGS.trade),
                           supply = flag_read(FLAGS.supply),
                           pin = flag_read(FLAGS.pin),
                           access = flag_read(FLAGS.access) } }
    end,
    probe = function(addr) return hoi4.detour_probe(addr) end,
}

-- ---------------------------------------------------------------- 决议开关
-- common/decisions/ds_toggles.txt 的双状态决议：visible 读 has_global_flag
-- （引擎侧，零 Lua 求值），complete_effect 先引擎置/清旗、再调这里注册的
-- 同名效果镜像 STATE（旗在前 ⇒ 对账永不看到 flag < STATE 的中间态）。
-- 控制台/Lua 直开走 DISABLE_SUPPLY.on()/off()（内部同款 flag_write）。
hoi4.effect("ds_supply_on",  function() STATE.supply = true  STATE.fill_hour = -1 return "supply=on"  end)
hoi4.effect("ds_supply_off", function() STATE.supply = false return "supply=off" end)
hoi4.effect("ds_trade_on",   function() STATE.trade  = true  return "trade=on"  end)
hoi4.effect("ds_trade_off",  function() STATE.trade  = false return "trade=off" end)
hoi4.effect("ds_pin_on",     function() STATE.pin    = true  return "pin=on"    end)
hoi4.effect("ds_pin_off",    function() STATE.pin    = false return "pin=off"   end)
hoi4.effect("ds_access_on",  function() STATE.access = true  STATE.access_latch = false return "access=on"  end)
hoi4.effect("ds_access_off", function() STATE.access = false return "access=off" end)
hoi4.log("disable_supply: 8 decision effects registered")

-- 首次加载即已在对局内（手动 dofile 重载 / 晚加载）：立刻按旗对齐一次。
-- 世界未就绪（加载期首次 dofile）时留待游戏内会话派发处理。
if world_ready() then
    STATE.synced = true
    sync_from_flags()
    hoi4.log("disable_supply: loaded in-game, STATE synced from flags")
end
