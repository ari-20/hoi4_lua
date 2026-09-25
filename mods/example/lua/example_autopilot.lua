-- example_autopilot.lua -- example mod 桥接功能 (DLL 动态发现各启用 mod 的 lua/*.lua)
-- 三功能独立决策开关 (全局旗) + on_daily 门控, 效果本体在 Lua 侧
-- example_autosave_tick : autosave.hoi4 → autosave_<本地时间>.hoi4, 滚动保留 12
-- example_research_tick : 空科研槽 → 随机可用科技 (IsValid = 可用性神谕)
-- example_focus_tick : 空国策槽 → 引擎候选表 (fp+120) 随机启动
local log = function(msg) print("[example] " .. tostring(msg)) end
local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
local wu32, wu64, wu8, wu16 = hoi4.write_u32, hoi4.write_u64, hoi4.write_u8, hoi4.write_u16
-- 日志美化助手可选依赖布局层 (example 本体只用 DLL 原语, 无框架也能跑);
-- 惰性解析: 本 mod 拷贝的层文件 (hoi4_layout 等) 字母序晚于本文件加载,
-- 顶层捕获会拿 nil — 一律调用时再取 GAME.layout
local function LV() return (type(GAME) == "table") and GAME.layout or nil end
-- 命令发射库 (example_cmd.lua 挂 _G.EXAMPLE_CMD): 字母序晚于本文件加载,
-- 一律运行期惰性取用, 顶层不得捕获 (同 GAME.layout 纪律)
local function CMD() return rawget(_G, "EXAMPLE_CMD") end
local function tok_name(tok)
    local l = LV() return l and l.token_name and l.token_name(tok) or nil
end
local function rd_str(o)
    local l = LV() return l and l.read_msvc_str and l.read_msvc_str(o) or nil
end

-- 引擎定址 (1.19.3.0 rev c01a3d50, dump 定案) — ⚠ ASLR: 一律 base+RVA!
-- 四令 VFT/IsValid/Execute/size 配方集中在 EXAMPLE_CMD.R (对书 §4.33.18
-- 外部构造配方详卡), 本文件只留非命令类引擎地址。
local B = hoi4.base()

local test_cc = nil
local function player_cc(ctx)
    if test_cc then return test_cc end
    local ok, idx = pcall(hoi4.scope_country, ctx)
    if not ok or not idx or idx <= 0 then return nil end
    -- scope_country 返回的是国家数组下标 (小整数), 业务 body 要的是指针地址
    local gs = rp(hoi4.base() + 0x332F260)
    local carr = gs and rp(gs + 0x310)
    return (carr and carr ~= 0) and rp(carr + 8 * idx) or nil
end

-- ---------------------------------------------------------------- 1. autosave
local KEEP = 12
-- 枚举用 DLL 的 hoi4.read_dir (进程内 FindFirstFileW, 无窗口);
-- 旧版 io.popen('dir /b') 在 GUI 进程里派生 cmd.exe = 每次存档闪黑窗 (6.4 节)。
local function list_autosaves(dir)
    local ok, t = pcall(hoi4.read_dir, "autosave_*.hoi4")
    if not ok or type(t) ~= "table" then return nil end
    local out = {}
    for _, n in ipairs(t) do out[#out+1] = n end
    table.sort(out)
    return out
end
local function autosave_body()
    local okd, dir = pcall(hoi4.save_dir)
    if not okd or not dir or dir == "" then return end
    local src = dir .. "/autosave.hoi4"
    local fh = io.open(src, "rb")
    if not fh then return end
    fh:close()
    local dst = dir .. "/autosave_" .. os.date("%Y%m%d_%H%M%S") .. ".hoi4"
    local ok, err = os.rename(src, dst)
    if not ok then log("rename fail: " .. tostring(err)) return end
    log("autosave -> " .. dst)
    local list = list_autosaves(dir)
    if not list then return end
    for i = 1, #list - KEEP do
        local ok2, e2 = os.remove(dir .. "/" .. list[i])
        log(ok2 and ("pruned " .. list[i]) or ("prune fail " .. tostring(e2)))
    end
end

-- ---------------------------------------------------------------- 2. research
-- ts = *(cc+3936); 槽 {d@160, 容量@172} (每槽一 CResearchSlot 对象, 空闲 = +24 无科技);
-- ⚠ 可用槽数 = cc+4936 (ideas 加成后动态值, BICE: 容量恒 6 而动态 0~6, dyn=0 国禁研);
-- ts+136 列表 = CTechnology 实例 {+8 名token, +352 模板, +360 联动, +372 等级};
-- 命令 payload {+40 tid(>0), +48 模板指针(模板+56=1based实例索引), +56 槽号, +60 flag};
-- IsValid = 界检 + sub_140ED8F00 可用性神谕, flag=0 短路放行 (§4.33.9/§4.33.18)
local function country_index(cc)
    local gs = rp(hoi4.base() + 0x332F260)
    local carr = rp(gs + 0x310)
    local cn = ru32(gs + 0x31C) or 0
    for i = 0, cn - 1 do
        if rp(carr + 8 * i) == cc then return i end
    end
    return nil
end
local function arr_has(arr, cnt, ptr)                     -- 指针数组直存扫描
    for i = 0, cnt - 1 do
        if rp(arr + 8 * i) == ptr then return true end
    end
    return false
end
local function research_bound(sdata, total, tech)         -- 科研槽对象 +24 反查
    for i = 0, total - 1 do
        local s = rp(sdata + 8 * i)
        if s and rp(s + 24) == tech then return true end
    end
    return false
end
local function research_body(cc)
    local C = CMD()
    if not C then log("research: cmd 库未加载") return end
    local ts = rp(cc + 3936)
    if not ts then return end
    local sdata = rp(ts + 160)
    local total = ru32(ts + 172) or 0
    local dyn = ru32(cc + 4936) or 0
    if dyn == 0 then return end                          -- 无可用科研槽
    local usable = (dyn < total) and dyn or total
    local cidx = country_index(cc)
    if not cidx then log("research: 国家数组下标未找到") return end
    if not sdata or usable == 0 then return end
    local free_idx
    for i = 0, usable - 1 do
        local s = rp(sdata + 8 * i)
        if s and rp(s + 24) == 0 then free_idx = i; break end
    end
    if not free_idx then return end                      -- 无空槽
    local tdata = rp(ts + 136)
    local tcnt = ru32(ts + 148) or 0
    local rdata = rp(ts + 64)
    local rcnt = ru32(ts + 76) or 0
    if not tdata or tcnt == 0 then return end
    local R = C.R.research
    local picked
    for _ = 1, 64 do                                     -- 随机试, IsValid = 可用性神谕
        local k = math.random(0, tcnt - 1)
        local tech = rp(tdata + 8 * k)                   -- CTechnology 实例
        local tmpl = (tech and tech ~= 0) and rp(tech + 352) or nil   -- +48 要模板 (实例+352)
        if tmpl and tmpl ~= 0
            and not arr_has(rdata, rcnt, tech)           -- 未研完
            and not research_bound(sdata, total, tech) then -- 未在研
            -- 单发糖: 构造→填载荷→IsValid 门→Execute→释放 (用后即释)
            local r = C.fire(R.size, R.vft, R.isvalid, R.exec, function(cmd)
                wu32(cmd + 40, cidx)          -- +40 = 国家数组下标 (IsValid: *(gs数组+8*id))
                wu64(cmd + 48, tmpl); wu32(cmd + 56, free_idx); wu8(cmd + 60, 0)
            end)
            if r == "valid" then picked = tech; break end
        end
    end
    if picked then
        local tok = ru32(picked + 8)
        log("research started: slot=" .. free_idx .. " tech=" ..
            tostring(tok_name and tok_name(tok) or tok))
    else
        log("research: 64 次随机未命中可用科技")
    end
end

-- ---------------------------------------------------------------- 3. focus
-- fp = *(cc+4992) CFocusStatus; 候选 {d@120, c@132} (引擎维护, 前置满足才入);
-- 当前国策 fp+16 (非 0 = 占用); 启动 = sub_140711660(cc, CFocus*)
local function focus_body(cc)
    local C = CMD()
    if not C then return "focus: cmd 库未加载" end
    local fp = rp(cc + 4992)
    if not fp or fp == 0 then return "no fp" end
    local cur = rp(fp + 16)
    if cur and cur ~= 0 then return "occupied cur=" .. string.format("%x", cur) end
    local d = rp(fp + 120)
    local c = ru32(fp + 132) or 0
    if c == 0 or not d then return "候选表空 c=" .. tostring(c) end
    -- 候选表只保证前置满足, 不含 available 触发器 (如 GER_enigma 的
    -- "没有: 恩尼格玛密码被破解了!") → 用命令 IsValid (def 虚槽[9] CanSelect)
    -- 逐条过筛, 只从通过者里随机; 启动走命令 Execute 而非绕检的内层函数
    local cidx = country_index(cc)
    if not cidx then return "build: 无国家下标" end
    local R = C.R.focus
    local cmd = C.new(R.size, R.vft)
    if not cmd then return "focus: alloc 失败" end
    wu32(cmd + 40, cidx)
    local valid = {}                                     -- 两段式: 先筛后发 (一条 cmd 反复过筛)
    for i = 0, c - 1 do
        local fdef = rp(d + 8 * i)
        if fdef and fdef ~= 0 then
            wu64(cmd + 48, fdef)
            if C.valid(cmd, R.isvalid) == true then valid[#valid+1] = fdef end
        end
    end
    if #valid == 0 then
        C.free(cmd)
        return "可选 0/" .. c .. " (available 全不满足)"
    end
    local focus = valid[math.random(1, #valid)]
    wu64(cmd + 48, focus)
    C.exec(cmd, R.exec)
    local nm = rd_str and rd_str(focus + 24) or "?"
    C.free(cmd)
    return "started [" .. tostring(nm) .. "] 可选 " .. #valid .. "/" .. c ..
        " fp16=" .. string.format("%x", rp(fp + 16) or 0)
end

-- ---------------------------------------------------------------- 注册
hoi4.effect("example_autosave_tick", function(n, self, ctx)
    log("autosave tick fired")
    local ok, err = pcall(autosave_body); if not ok then log("ERR " .. tostring(err)) end
end)
hoi4.effect("example_research_tick", function(n, self, ctx)
    local cc = player_cc(ctx)
    if not cc then log("research: 无国家 scope") return end
    local ok, err = pcall(research_body, cc); if not ok then log("ERR " .. tostring(err)) end
end)
hoi4.effect("example_focus_tick", function(n, self, ctx)
    local cc = player_cc(ctx)
    if not cc then return "focus: 无国家 scope" end
    local ok, err = pcall(focus_body, cc)
    if not ok then log("ERR " .. tostring(err)) return "ERR " .. tostring(err) end
    return err
end)
-- 测试钩子: headless 直接指定国家 (正式玩法走 scope)
hoi4.effect("example_test_setcc", function(n, self, ctx)
    test_cc = (ctx and ctx ~= 0) and ctx or nil
    log("test_cc = " .. tostring(test_cc))
end)
log("example_autopilot: 3 effects + test hook registered")

-- ---------------------------------------------------------------- 4. rng reseed
-- 全局 RNG 状态对 = 静态槽 (savefull 同名导出锚定): seed@0x3452524 / count@0x3452520
-- 首选 = 控制台 `random_seed <int>` (官方 SetSeed: 单 int 哈希派生 seed+count,
-- 无 debug 门, 模块侧零偏移依赖); 失败才回落纯写 (counter 型流: 新 seed + count
-- 归零 = 全新流)。种子取 int31 正数以适配控制台文本解析。
local RNG_SEED_RVA = 0x3452524
local RNG_CNT_RVA  = 0x3452520
local function reseed_body()
    local B = hoi4.base()
    local gs = rp(B + 0x332F260)
    local gh = (gs and ru32(gs + 1128)) or 0
    local t = os.time() % 1000000
    local seed = math.floor((t * 1103515245 + 12345 + gh * 2654435761) % 2147483647)
    local old = ru32(B + RNG_SEED_RVA) or 0
    local via = "write"
    local r = hoi4.console("random_seed " .. seed)
    local new = ru32(B + RNG_SEED_RVA)
    if r == nil or new == nil or new == old then
        wu32(B + RNG_SEED_RVA, seed)
        wu32(B + RNG_CNT_RVA, 0)
        new = ru32(B + RNG_SEED_RVA)
        via = "fallback" .. (r and "(noop)" or "(nil)")
    else
        via = "console"
    end
    log("rng reseeded (" .. via .. "): " .. old .. " -> " .. tostring(new) ..
        " seed=" .. seed)
end
hoi4.effect("example_reseed_rng", function(n, self, ctx)
    local ok, err = pcall(reseed_body); if not ok then log("ERR " .. tostring(err)) end
end)

-- ---------------------------------------------------------------- 5. auto build
-- CAddConstructionCommand {+40 tag id, +48 内嵌 CBuildingReference{+56 州id,
-- +60 建筑token, +64 未名0}, +72 数量, +76 插入枚举<3}; IsValid=界检+可建神谕
-- (§4.33.9/§4.33.18); 配方 = EXAMPLE_CMD.R.build, 本地只留业务常量
local BUILD_NAMES   = { "industrial_complex", "arms_factory", "fuel_refinery" }
local function flag_on(store, tok)
    local d = rp(store + 8)
    local cnt = ru32(store + 0x14) or 0
    if not d or cnt == 0 or cnt > 100000 then return false end
    for i = 0, cnt - 1 do
        local e = d + 48 * i
        if ru32(e + 8) == tok then
            local v = ru32(e + 40) or 0
            return (v % 65536) ~= 0
        end
    end
    return false
end
-- 建造队列语义 (用户裁定): 读真实空闲 → 排一条 → 再读, 循环至空闲归零。
-- 真实队列 = ps+112 general_lines (查线函数 sub_140E5CF90 走它 + RTTI
-- 转型 CBuildingProductionLine); 元素 +8 = line_type (59 = 建筑)。
-- 空闲民工 = 引擎 available_for_projects 同式 (getter sub_140E68350, 断言
-- "NumFactoriesAvailable >= 0" production.cpp:4628)
-- ps+888 val ÷1e5 − ps+912 ÷1e5 − ps+944 − ps+920
-- 后三项即 GUI 工具提示 未使用 = 全部 − 生活消费品 − 建造 (− 项目占用);
-- 同一式亦见触发器 num_of_available_civilian_factories (书 §4.32)。
-- ⚠ ps+888 恒为 fixed×1e5 (factor@+56), 一律 ÷1e5 —— 不可写 ">100000 才除"
-- 恰好 1.0 个工厂 (100000) 会漏除 → 目标暴涨 (已修)。
-- ⚠ ps+968 = 贸易进口 (FROM_TRADE), 已含在总量内 —— 不可再减;
-- 出口 (SENT_TO_TRADE) 是 ps+1160, 本式不含。
local function civ_idle(ps)
    local total = math.floor((rp(ps + 888) or 0) / 100000)
    local proj = math.floor((rp(ps + 912) or 0) / 100000)
    local cg = ru32(ps + 944) or 0
    local asg = ru32(ps + 920) or 0
    local idle = total - proj - cg - asg
    return (idle > 0) and idle or 0
end
local function civ_cap()
    local L = LV()
    local cap = (L and L.define) and L.define("MAX_CIV_FACTORIES_PER_LINE") or 15
    if cap and cap > 0 then cap = cap % 4294967296 end  -- M.define 是 u64 读, defines 本体 u32
    if not cap or cap < 1 or cap > 100 then cap = 15 end
    return cap
end
local function count_building_lines(ps)
    local gd = rp(ps + 112)
    local gc = ru32(ps + 124) or 0
    if not gd or gd == 0 or gc == 0 or gc > 10000 then return 0 end
    local nb = 0
    for i = 0, gc - 1 do
        local e = rp(gd + 8 * i)
        if e and e ~= 0 and ru32(e + 8) == 59 then nb = nb + 1 end
    end
    return nb
end
local function build_body(cc)
    local gs = rp(hoi4.base() + 0x332F260)
    local store = rp(gs + 0x258)
    local choice = 0
    if flag_on(store, hoi4.name_to_token("EXAMPLE_BUILD_CIV")) then choice = 1
    elseif flag_on(store, hoi4.name_to_token("EXAMPLE_BUILD_MIL")) then choice = 2
    elseif flag_on(store, hoi4.name_to_token("EXAMPLE_BUILD_REF")) then choice = 3 end
    if choice == 0 then return "build: 未选择建筑" end
    local ps = rp(cc + 3944)
    if not ps or ps == 0 then return "build: 无生产状态" end
    local btok = hoi4.name_to_token(BUILD_NAMES[choice])
    if not btok or btok == 0 then return "build: token 未找到" end
    local cap = civ_cap()
    local n = count_building_lines(ps)                   -- 引擎真实队列数
    local idle = civ_idle(ps)                            -- 引擎真实空闲数
    if idle == 0 then
        return "无空闲民工(" .. n .. "条在建, cap" .. cap .. ")"
    end
    -- 每条新线最多吃 cap 个工厂; +2 余量, 50 条绝对上限
    local budget = math.ceil(idle / cap) + 2
    if budget > 50 then budget = 50 end
    local sarr = rp(gs + 0x2C8)
    local scnt = ru32(gs + 0x2D4) or 0
    local cidx = country_index(cc)
    if not cidx or not sarr or scnt == 0 or scnt > 100000 then return "build: 州表不可读" end
    local owned = {}
    for i = 0, scnt - 1 do
        local st = rp(sarr + 8 * i)
        if st and st ~= 0 and ru32(st + 200) == cidx then owned[#owned+1] = st end
    end
    if #owned == 0 then return "build: 无拥有州" end
    local C = CMD()
    if not C then return "build: cmd 库未加载" end
    local R = C.R.build
    local cmd = C.new(R.size, R.vft)
    if not cmd then return "build: alloc 失败" end
    wu32(cmd + 40, cidx)
    wu64(cmd + 48, B + R.ref_vft)                          -- ref.内嵌 CBuildingReference vt
    wu32(cmd + 60, btok)                                   -- ref.建筑token (+12)
    wu32(cmd + 72, 1)                                      -- 数量
    wu8(cmd + 76, 0)                                       -- 插入枚举
    local added = 0
    while idle > 0 and added < budget do
        local before = idle
        local placed = false
        local tried = {}
        while #tried < math.min(#owned, 16) do
            local k = math.random(0, #owned - 1)
            if not tried[k + 1] then
                tried[k + 1] = true
                local st = owned[k + 1]
                wu32(cmd + 56, ru32(st + 88))              -- ref.州id (+8)
                if C.valid(cmd, R.isvalid) == true then    -- 一条 cmd 复用: 改州id→验→发
                    C.exec(cmd, R.exec)
                    placed = true
                    break
                end
            end
        end
        if not placed then break end
        added = added + 1
        n = count_building_lines(ps)                       -- 再读, 用户语义
        idle = civ_idle(ps)
        if idle >= before then break end                   -- 引擎不再吃进 = 到头
    end
    C.free(cmd)
    if idle == 0 then
        return "已铺满(+" .. added .. "条, 共" .. n .. "条在建, cap" .. cap .. ")"
    end
    return "部分 +" .. added .. "条(" .. n .. "条在建, 余空闲" .. idle ..
           " — 州槽位不足, 明日再试)"
end
hoi4.effect("example_build_tick", function(n, self, ctx)
    local cc = player_cc(ctx)
    if not cc then return "build: 无国家 scope" end
    local ok, err = pcall(build_body, cc)
    if not ok then log("ERR " .. tostring(err)) return "ERR " .. tostring(err) end
    return err
end)

-- ---------------------------------------------------------------- 6. save review
-- 出站通路 (重写): 不再依赖系统 curl —— 根因 = 系统 PATH 无 curl,
-- io.popen(start /b curl) 静默失败, 回复文件永不出现。DLL 提供
-- hoi4.http_request (WinHTTP, 系统自带库原生 https, worker 安全)。流程 =
-- async_exec 工作线程发请求 → 主线程 cb (帧边界派发) 收回复 → 写 loc yml
-- → reload loc → eval_effect 触发骨架事件。零临时文件, 无窗口闪现。
-- 双超时: http_request 全请求硬 deadline 150s + async opts.timeout_ms=180s
-- (超期 cb 收 status=12 的 TIMEOUT 报告) — 绝不无限等待。
local _src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
local MY_DIR = _src:match("^@(.*)[/\\][^/\\]*$") or (type(MOD_LUA_DIR) == "string" and MOD_LUA_DIR) or ""
local MOD_DIR = MY_DIR:gsub("\\", "/"):gsub("/+$", "") .. "/../"
local function read_cfg()
    local fh = io.open(MOD_DIR .. "review_config.txt", "r")
    if not fh then return nil end
    local cfg = {}
    for ln in fh:lines() do
        local k, v = ln:match("^([%w_]+)=(.*)%s*$")
        if k and v and v ~= "" then cfg[k] = v end
    end
    fh:close()
    if cfg.url and cfg.key and cfg.model and cfg.key ~= "PUT_YOUR_KEY_HERE" then return cfg end
    return nil
end
local function sanitize(s, cap)
    s = tostring(s):gsub("[\r\n]+", " "):gsub("[%c\\]", " "):gsub('"', "'")
    cap = cap or 700
    if #s > cap then s = s:sub(1, cap) end
    return s
end
-- 摘要 = example_saveinfo.lua 富字段版 (日期/稳定度/PP/党派/人力/师/工厂/
-- 科研/国策/法案/精神/经验/盟友); 该层自包含, 但保留 DLL 原语最小兜底
local function save_summary(cc)
    if type(EXAMPLE_SAVEINFO) == "table" and EXAMPLE_SAVEINFO.summary then
        local ok, s = pcall(EXAMPLE_SAVEINFO.summary, cc)
        if ok and type(s) == "string" and #s > 0 then return s end
        log("summary: 富摘要失败 " .. tostring(s) .. ", 走兜底")
    end
    local gs = rp(hoi4.base() + 0x332F260)
    local parts = {}
    parts[#parts+1] = "国家编号:" .. tostring(country_index(cc))
    local sarr = rp(gs + 0x2C8)
    local scnt = ru32(gs + 0x2D4) or 0
    local owned, cidx = 0, country_index(cc)
    if sarr and cidx and scnt > 0 and scnt < 100000 then
        for i = 0, scnt - 1 do
            local st = rp(sarr + 8 * i)
            if st and st ~= 0 and ru32(st + 200) == cidx then owned = owned + 1 end
        end
    end
    parts[#parts+1] = "拥有州数:" .. owned
    local ps = rp(cc + 3944)
    if ps and ps ~= 0 then
        for _, p in ipairs({ { "民用", 880 }, { "军用", 688 }, { "造船", 784 } }) do
            local v = ru32(ps + p[2] + 8) or 0
            if v > 100000 then v = math.floor(v / 100000) end
            parts[#parts+1] = p[1] .. "工厂:" .. v
        end
    end
    local ts = rp(cc + 3936)
    if ts and ts ~= 0 then
        parts[#parts+1] = "已研科技:" .. (ru32(ts + 76) or 0)
        local sdata = rp(ts + 160)
        local dyn = ru32(cc + 4936) or 0
        local filled = 0
        for i = 0, dyn - 1 do
            local s = sdata and rp(sdata + 8 * i) or 0
            local t = s and rp(s + 24) or 0
            if t and t ~= 0 then filled = filled + 1 end
        end
        parts[#parts+1] = "科研槽:" .. filled .. "/" .. dyn
    end
    local fp = rp(cc + 4992)
    if fp and fp ~= 0 then
        local f = rp(fp + 16)
        if f and f ~= 0 then
            parts[#parts+1] = "当前国策:" .. tostring(rd_str and rd_str(f + 24) or "?")
        end
    end
    if ps and ps ~= 0 then parts[#parts+1] = "建造队列:" .. count_building_lines(ps) end
    return table.concat(parts, "；")
end
-- 锐评 loc: 生成物 (.yml) 不进仓库, 模板 (.tmpl) 才是真源。原因 = 每次锐评
-- 都整文件覆写, 若 .yml 入库则每跑一次就脏一个 tracked 文件, 而提交进去的
-- 又只是上一次的运行时文本。HOI4 只加载 localisation/ 下的 *.yml, 所以
-- .tmpl 不会被引擎读到; 首次加载时若 .yml 缺失就从模板补一份 (新克隆可用)。
local REVIEW_LANGS = { "english", "simp_chinese" }
local function review_loc_path(lang)
    return MOD_DIR .. "localisation/" .. lang .. "/example_review_l_" .. lang .. ".yml"
end
local function read_file(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local s = fh:read("*a")
    fh:close()
    return s
end
-- 模板 → 生成物 (仅在生成物缺失时; 不覆盖已有锐评)
local function ensure_review_loc()
    for _, lang in ipairs(REVIEW_LANGS) do
        local yml = review_loc_path(lang)
        if not read_file(yml) then
            local tmpl = read_file(yml .. ".tmpl")
            if tmpl then
                local fh = io.open(yml, "wb")
                if fh then fh:write(tmpl) fh:close() end
            end
        end
    end
end
local function write_review_loc(text)
    for _, lang in ipairs(REVIEW_LANGS) do
        local fh = io.open(review_loc_path(lang), "wb")
        if not fh then return false end
        fh:write("\239\187\191")
        if lang == "english" then fh:write("l_english:\n") else fh:write("l_simp_chinese:\n") end
        fh:write(' example_review_event.1.d:0 "' .. text .. '"\n')
        fh:close()
    end
    return true
end
-- 工作线程任务体: worker 是裸 lua_State, 只能用标准库 + hoi4.http_request
local REVIEW_WORKER = [=[
local args = ...
local code, body = hoi4.http_request("POST", args.url, args.headers, args.payload, 150000)
if not code then
    return "ERR:连接失败 " .. tostring(body)
end
if code ~= 200 then
    return "ERR:HTTP " .. tostring(code) .. " " .. tostring(body or ""):sub(1, 120)
end
local i = body:find('"content"', 1, true)
if not i then return "ERR:响应无 content 字段" end
local j = body:find(":", i + 9, true)
if not j then return "ERR:content 形态异常" end
j = j + 1
while body:sub(j, j) == " " do j = j + 1 end
if body:sub(j, j) ~= '"' then return "ERR:content 非字符串" end
j = j + 1
local out = {}
while j <= #body do
    local ch = body:sub(j, j)
    if ch == "\\" then
        local nx = body:sub(j + 1, j + 1)
        if nx == "n" then out[#out+1] = " "
        elseif nx == '"' or nx == "\\" or nx == "/" then out[#out+1] = nx
        elseif nx == "u" then j = j + 4 end
        j = j + 2
    elseif ch == '"' then break
    else out[#out+1] = ch; j = j + 1 end
end
return table.concat(out)
]=]
-- 锐评在途标记 = 引擎全局旗 EXAMPLE_REVIEW_PENDING (决议栏工具提示读它)
-- 写通道 = hoi4.console("set_global_flag ... 0/1") (flag_write 已删, 控制台
-- set_global_flag 带 0/1 参数即置 0/置 1; 旗条目只能置 0 不能删除)。
-- 旗随存档持久化: 会话起点自愈清 0 (见文件尾), 防上一会话在途残留锁死。
-- 主线程 cb (帧边界派发): 先清 PENDING (无论成败, 允许重试), 再应用回复
local function review_reply_apply(id, status, value)
    hoi4.console("set_global_flag EXAMPLE_REVIEW_PENDING 0")
    local ok, err = pcall(function()
        if status ~= 1 then
            log("review: 任务失败 status=" .. tostring(status) .. " " .. tostring(value))
            return
        end
        if type(value) ~= "string" then log("review: 回复形态异常") return end
        if value:sub(1, 4) == "ERR:" then log("review: " .. value) return end
        if not write_review_loc(sanitize(value, 1200)) then log("review: loc 写入失败") return end
        hoi4.console("reload loc")
        hoi4.console("eval_effect country_event = { id = example_review_event.1 }")
        log("review: 事件已触发")
    end)
    if not ok then log("ERR " .. tostring(err)) end
end
local function review_request_body(cc)
    local cfg = read_cfg()
    if not cfg then log("review: review_config.txt 未配置") return "review_config.txt 未配置" end
    local gs = rp(hoi4.base() + 0x332F260)
    local store = rp(gs + 0x258)
    local ptok = hoi4.name_to_token("EXAMPLE_REVIEW_PENDING")
    if flag_on(store, ptok) then return "已有锐评请求进行中" end
    local prompt = "玩家存档实况数据(以'；'分隔, 标识符为HOI4原名): " ..
        save_summary(cc) .. "。请锐评这个局势。"
    local sys = "你是钢铁雄心4(HOI4)社区的存档锐评大师, 文风对标B站《存档锐评》系列:"
        .. "毒舌但内行, 善用反讽和夸张比喻, 直接引用具体数字戳槽点(工厂配比/科研空置/"
        .. "人力池/政治点囤积/军民工失衡都是好素材); 评的是局势和操作, 不攻击玩家本人;"
        .. "结论要有数据依据, 不说放之四海皆准的空话。"
        .. "输出要求: ①正文不超过300个汉字(标点计入); ②至少引用6个数据里的具体数字开涮;"
        .. "③第一句是一句话标题式总评(可以标题党); ④中间挑最疼的3-4处戳;"
        .. "⑤结尾点出2-3件最该马上做的事; ⑥中文, 只输出锐评本身, 不要任何前后缀、不要解释。"
    local payload = '{"model":"' .. cfg.model .. '","messages":['
        .. '{"role":"system","content":"' .. sanitize(sys, 1200) .. '"},'
        .. '{"role":"user","content":"' .. sanitize(prompt, 2400) .. '"}]}'
    local headers = "Authorization: Bearer " .. cfg.key .. string.char(13, 10)
        .. "Content-Type: application/json"
    local ok, id = pcall(hoi4.async_exec, REVIEW_WORKER,
        { url = cfg.url, headers = headers, payload = payload },
        { timeout_ms = 180000, cb = review_reply_apply })
    if not ok then log("review: async 提交失败 " .. tostring(id)) return "async 提交失败" end
    hoi4.console("set_global_flag EXAMPLE_REVIEW_PENDING")
    log("review: 请求已发出 (task " .. tostring(id) .. ")")
    return "锐评请求已发出"
end
hoi4.effect("example_review_request", function(n, self, ctx)
    local cc = player_cc(ctx)
    if not cc then return "review: 无国家 scope" end
    local ok, err = pcall(review_request_body, cc)
    if not ok then log("ERR " .. tostring(err)) return "ERR " .. tostring(err) end
    return err
end)
-- 只读探针: 回显送模型的摘要原文 (引擎路由调用时落桥日志, 便于无头验证)
hoi4.effect("example_summary_probe", function(n, self, ctx)
    local cc = player_cc(ctx)
    if not cc then return "summary: 无国家 scope" end
    local ok, s = pcall(save_summary, cc)
    if not ok then return "ERR " .. tostring(s) end
    log("summary: " .. tostring(s))
    return s
end)
-- 会话起点自愈: 旗随存档持久化, 上一会话在途残留 (存档时恰在请求中) 会
-- 锁死新会话的锐评 —— dofile 每次会话启动都跑, 统一清 0。
pcall(function() hoi4.console("set_global_flag EXAMPLE_REVIEW_PENDING 0") end)
-- 生成物自愈: 新克隆/清过工作区时从模板补出 .yml (缺文件 = 事件 desc 空)
pcall(ensure_review_loc)
log("example_autopilot: 8 effects registered (autopilot + reseed + build + review)")
