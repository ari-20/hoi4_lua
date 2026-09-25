-- hoi4_layout.lua — version-specific data structure knowledge (plan A)
-- Every offset/RVA lives HERE, not in the DLL. To support a new game version,
-- only this table changes. Addresses are RVAs; runtime addr = base + rva.

local M = {}

-- 导出到 GAME.layout (objects.lua 等引用; 本文件先于 objects 加载)
GAME = GAME or {}
GAME.layout = M

M.version = "1.19.3"

-- RVAs of data anchors (globals whose *values* we chase; these drift between
-- versions and are the ONLY version-specific knowledge)
M.rva = {
    gamestate_ptr = 0x332F260,   -- -> CGameState* (§1.1 游戏状态单例)
    lexer_token_table = 0x35E1AE0, -- -> std::string* (stride 0x20; §4.26.2 lexer token 表)
    lexer_token_max   = 0x35E1AB4, -- int, max valid dynamic token id (§4.26.2)
}

-- 全局 id 计数器槽 (u32; 多数为 i32 语义)。top_meta 与 session_meta 同源,
-- 收敛于此 (原两份拷贝)。键 = 存档叶名。§4.1.6 顶格 # 叶 writer 族 (会话元数据簇)。
M.rva.counters = {
    theater_group_index                 = 0x3087258,
    military_deployment_line_index      = 0x30B1358,
    military_deployment_conveyor_index  = 0x30B135C,
    unit                                = 0x308725C,
    order_index                         = 0x3087260,
    front_index                         = 0x3087264,
    theatre_index                       = 0x3087268,
    country_leader_index                = 0x30B12D0,
    equipment_variant_index             = 0x30B1328,
    debug_current_ref_id                = 0x34520E0,
    multiplayer_random_seed             = 0x3452524,  -- i32 语义
    multiplayer_random_count            = 0x3452520,  -- i32 语义
}

-- 全局版本槽 (save_version / minor_save_version; §4.1.6 顶格 # 叶)
M.rva.save_version       = 0x3335FEC
M.rva.minor_save_version = 0x3336080

-- structure offsets (stable *within* a family of versions)
M.off = {
    global_state = {
        flag_store = 600,        -- §1.2 CGameState +600 -> flag store (匿名结构 32B)
        var_owner  = 0x980,      -- §1.2 CGameState +2432 -> CVariables* (全局; §4.25.1)
    },
    flag_store = {
        entries = 8,             -- §4.13.3 CFlagManager +8 -> entry array
        count   = 0x14,          -- §4.13.3 CFlagManager +20 int count
    },
    token_string = {
        stride = 0x20,           -- MSVC std::string (§4.26.2 lexer token 表)
    },
    -- global variables: Robin Hood hashtable, FNV-1a(string) keys (§4.13.2)
    var_owner = {
        ht = 0x10,               -- §4.25.1 CVariables +16 -> 内嵌 hashtable struct
    },
    -- §4.3 CCountry 国家子系统挂载
    country = {
        flag_store  = 0x230,     -- §4.3 CCountry +560 -> CFlagManager* (布局 §4.13.3)
        stockpile   = 0xF68,     -- §4.3 CCountry +3944 -> CProductionStatus* (§4.8)
    },
    -- §4.13.3 CScriptFlag 条目 (48B)
    flag_entry = {
        stride = 0x30,
        key    = 8,              -- int token id
        value  = 0x28,           -- i16
        expiry = 0x2A,           -- i16 expiry days (valid only when > 0)
        setdate = 0x18,          -- game-hour when set (epoch 43800000)
    },
    var_ht = {
        entries = 0x08,          -- §4.13.2 CVariables RH 头 -> entry array (stride 0x30)
        count   = 0x10,          -- §4.13.2 int
        mask    = 0x14,          -- §4.13.2 uint, buckets-1 (power of 2)
        -- maxdist@0x18 (u8), maxload@0x1c (float)
    },
    var_entry = {                -- §4.13.2 RH 桶 (0x30)
        stride = 0x30,
        hash  = 0x00,            -- u32 FNV-1a of name
        dist  = 0x04,            -- u8 probe distance (0 = empty slot)
        key   = 0x08,            -- MSVC std::string
        value = 0x28,            -- s64 fixed point (x1000)
    },
    -- §4.23.3 NInternationalMarket (CPurchaseContractsContainer, gs+1000)
    market = {
        contracts        = 0,    -- 容器 @mkt+0 {data@0, count@12} 元素 8B 指针
        requests         = 96,   -- 槽数组 @mkt+96 (槽 = 国数+1, idx0 哨兵)
        requests_count   = 108,  -- @mkt+108 槽数
        req_slot_stride  = 24,   -- 槽跨距 (内嵌 vector)
        req_slot_data    = 0,    -- 槽内 idata (CPurchaseRequest**)
        req_slot_count   = 12,   -- 槽内 icount (过滤器: ==0 跳过)
    },
    -- §4.23.3 CPurchaseRequest / 合同 id 对 (CReferenceObject 头)
    purchase_request = {
        id_type = 8,             -- id 对 type
        id_id   = 12,            -- id 对 id
        def     = 24,            -- 内嵌 contract_definition 216B 起点
    },
    -- §4.23.3 contract_definition (216B; def 本体相对偏移 = 合同绝对偏移 - 24)
    contract_def = {
        stride         = 216,
        prices         = 0,      -- CEquipmentVariantPool (价格池)
        seller         = 64,     -- int32 tag_id
        buyer          = 68,     -- int32 tag_id
        equipments     = 72,     -- CEquipmentVariantPool (请求装备池)
        subsidy_total  = 136,    -- qword 补贴 CIC 总额 (不序列化)
        subsidies      = 144,    -- {data@144, count@156} 48B 元向量
        speed          = 168,    -- uint32
        price_levels   = 176,    -- std::map 头 (中序 = 写序)
        lazy_done      = 192,    -- u8 懒计算完成标志 (不序列化)
        subsidy_offset = 200,    -- i64 补贴抵扣 (不序列化)
        total_cic      = 208,    -- i64 合同总 CIC 价 (不序列化)
    },
    -- §4.23.3 CEquipmentVariantPool (64B; 3 处复用)
    -- pool1 (stride 24) 不入档, 仅作"整块空判"; pool2 (stride 16) = 序列化源
    variant_pool = {
        pool1_data  = 8,  pool1_count = 20, pool1_stride = 24, pool1_amount = 16,
        data        = 32, count       = 44, stride       = 16, amount       = 8,
        allow_zero  = 56, -- u8 恒写
    },
    -- §4.23.3 contract_draft.subsidies 条 (48B)
    subsidy_entry = {
        stride    = 48,
        cic       = 0,           -- i64 fixed×1e-5
        archetype = 8,           -- 匿名结构* → archetype = ru32(rp(e+8)+8)
        targets   = 16,          -- {data@16, count@28} u32 tag_id 列表
        branch    = 40,          -- u8 分支 (0 → targets; 1 → trigger 串)
    },
}

-- helper: chase pointers with nil-safe reads
-- ⚠ 名中 p/u 皆非契约: 本原语读 64 位**原值**, 指针 / 整数 / fixed 共用同一入口,
-- 且引擎侧已是带符号重解释 (高位 1 → 负值), 非无符号 (书 §3.7)。
local function rp(addr)
    if not addr or addr == 0 then return nil end
    return hoi4.read_u64(addr)
end
M.rp = rp

-- helper: u8 读 / 指针有效性 (与 sv2_lib SL.kptr 同判据; 静态资源访问器用)
local function ru8(addr)
    if not addr or addr == 0 then return nil end
    return hoi4.read_u8(addr)
end
local function kptr(v)
    return v ~= nil and v >= 0x10000 and v < 0x7FFF00000000 or false
end
M.ru8 = ru8
M.kptr = kptr


-- ---------------------------------------------------------------- CGameDate 共享转换 (唯一实现)
-- CGameDate 总小时 -> "Y.M.D.H"。此族函数**只此一份实现** (全库唯一);
-- objects_v2 U.date / sv2_lib SL.date / example_saveinfo 均委托到此。
--
-- 历法常量 (勿散写): 纪元 = 43800000 (=0.1.1.1 常态); day0 = (h-纪元)/24;
-- 年 = day0/365 (HOI4 无闰年), 一年 365 天。
-- 哨兵 (u32 空间): 0 未初始化
-- 0x29C3388 -1.1.1.1 (合法负日期; 部分字段记为哨兵)
-- 0x29C77F8 obsolete_change_date 默认哨兵
-- 43808760 默认构造 "1.1.1.1" (CGameDate 双哨兵之一)
--
-- 语义变体 (经全库审计, 差异仅在 门 + 输出形)。命名包装器 + 通用 opts 核心
-- M.date(h[, min_year]) A族 滤 {0, -1.1.1.1, 43808760}; min_year 给"年<1 弃"门
-- M.date_raw(h) B族 u32 符号回绕 -> 滤 {<=0, -1.1.1.1}; 43808760 照发
-- M.date_quoted(h) C族 不滤 (调用方自门); 输出引号形
-- 特殊门以 opts 表调用核心 M.date_opt(h, opts)
-- { drop = {v,...} 精确值黑名单 (与 <= 独立)
-- drop_le = n 丢弃 h <= n (回绕后比较)
-- drop_zero = true 丢弃回绕后 h <= 0 (B族; 未设时不判零/负)
-- wrap = true u32 -> i32 符号回绕
-- min_year = n 年 < n 则弃
-- quote = true 输出带引号 }
-- 用法: _h2d -> {drop_le=43800000}
-- obsolete -> {drop={0x29C77F8}} (注意: 不滤 0x29C3388, 0 照发)
-- techdate -> {drop={0,0x29C3388}, min_year=1}
local CAL_MONTHS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
M.CAL_MONTHS = CAL_MONTHS

-- 核心: 已假定 h 为该 opts 下的合法值; 只做历法换算
local function cal_ymdh(h)
    local day0 = (h - 43800000) // 24
    local yr, doy = day0 // 365, day0 % 365
    local mo, dd = 0, doy
    for mi, ml in ipairs(CAL_MONTHS) do
        if dd < ml then mo = mi break end
        dd = dd - ml
    end
    if mo == 0 then mo, dd = 12, 0 end
    return yr, mo, dd + 1, h % 24 + 1
end

-- 通用门 + 换算 + 输出 (全部变体的唯一实现)
function M.date_opt(h, opts)
    if not h then return nil end
    if opts.wrap and h >= 0x80000000 then h = h - 0x100000000 end
    if opts.drop_zero and h <= 0 then return nil end
    if opts.drop_le and h <= opts.drop_le then return nil end
    if opts.drop then
        for _, v in ipairs(opts.drop) do if h == v then return nil end end
    end
    local yr, mo, dd, hh = cal_ymdh(h)
    if opts.min_year and yr < opts.min_year then return nil end
    local fmt = opts.quote and '"%d.%d.%d.%d"' or "%d.%d.%d.%d"
    return string.format(fmt, yr, mo, dd, hh)
end

-- A族: 滤 0 / -1.1.1.1 / 43808760; min_year (可选) 加 "年<1 弃" 门
function M.date(h, min_year)
    return M.date_opt(h, {
        drop = { 0, 0x29C3388, 43808760 }, min_year = min_year,
    })
end

-- B族: 先做 u32->i32 符号回绕, 再滤 {<=0, -1.1.1.1}; 43808760 照发 "1.1.1.1"
function M.date_raw(h)
    return M.date_opt(h, { wrap = true, drop_zero = true,
                           drop = { 0x29C3388 } })
end

-- C族: 不滤 (nil 外一律换算, 含 h=0 → 负年份); 输出引号形 (writer 字面量落盘)
function M.date_quoted(h)
    return M.date_opt(h, { quote = true })
end


-- ---------------------------------------------------------------- 带符号读原语 (唯一实现)
-- DLL 只提供 read_u8/u16/u32/u64 (无符号); 需要带符号时全库一律走此处,
-- **禁止在段/对象文件里手写 `v >= 0x80000000 and v - 0x100000000 or v`**
-- (收敛前有 340+ 处手写转换, 易漏符号判/写错位宽; 书 §3.7 数值换算)。
-- 返回 nil 传播读失败 (地址 0 / 越界), 与 hoi4.read_u* 一致。
local R = hoi4

function M.i8(a)                      -- 带符号字节 (i8)
    if not a or a == 0 then return nil end
    local v = R.read_u8(a)
    if not v then return nil end
    if v >= 0x80 then v = v - 0x100 end
    return v
end

function M.i16(a)                     -- 带符号半字 (i16)
    if not a or a == 0 then return nil end
    local v = R.read_u16(a)
    if not v then return nil end
    if v >= 0x8000 then v = v - 0x10000 end
    return v
end

function M.i32(a)                     -- 带符号双字 (i32)
    if not a or a == 0 then return nil end
    local v = R.read_u32(a)
    if not v then return nil end
    if v >= 0x80000000 then v = v - 0x100000000 end
    return v
end

-- ⚠ i64 无需补符号: 引擎读原语 C 侧 `(lua_Integer)*(volatile uint64_t*)` 已是
-- **带符号重解释** (2^63 及以上以负值入栈), 故 i64 = read_u64 原值 —— 旧式
-- `v >= 0x8000000000000000 and v - 0x10000000000000000` 是恒真空操作
-- (0x10000000000000000 字面量回绕为 0), 已删。i8/i16/i32 是窄读零扩展,
-- 补符号仍必需 (书 §3.7)。
function M.i64(a)                     -- 带符号四字 (i64)
    if not a or a == 0 then return nil end
    return R.read_u64(a)
end

-- 就地符号化 (已有无符号值 -> 带符号; 供无法二次读内存的场合, 如数组元素)
function M.as_i8(v)  if not v then return nil end if v >= 0x80 then v = v - 0x100 end return v end
function M.as_i16(v) if not v then return nil end if v >= 0x8000 then v = v - 0x10000 end return v end
function M.as_i32(v) if not v then return nil end if v >= 0x80000000 then v = v - 0x100000000 end return v end
-- as_i64 = 恒等 (值本就带符号; 保留 = 调用点标注符号语义 + 与窄族统一入口)
function M.as_i64(v) if not v then return nil end return v end

-- 定点读 (唯一实现; 书 §3.7 数值换算)。i64 原始值带符号后按比例还原。
-- ⚠ fix5 必须 **除** 100000, 不能 *1e-5 —— 1ulp 差会破整值判定
-- (ai.pp_spend_amount 25 → "25.00000" 实证, 书 §4.34)。
function M.fix5(a)                    -- fixed×1e-5 -> 浮点
    local v = M.i64(a)
    if not v then return nil end
    return v / 100000
end
function M.fix5_raw(v)                -- 同上, 作用在已读出的原始 u64
    if not v then return nil end
    return M.as_i64(v) / 100000
end
function M.q15(a)                     -- Q15 (÷32768); 带符号
    local v = M.i64(a)
    if not v then return nil end
    return v / 32768
end


-- ---------------------------------------------------------------- 静态资源访问层
-- 已整体拆至 resource.lua : token 名/modifier/idb 81 库/
-- idreg/mods/cde/rules/SET/defines。此处经 MOD_LUA_DIR dofile 挂载;
-- M.rva.lexer_* / M.off.token_string.stride / M.read_msvc_str / M.lim /
-- M.dim 仍由本文件提供 (resource 层经 M 闭包引用, 调用时惰性求值)。
do
    -- SELF_DIR 自定位优先 (debug 源路径); MOD_LUA_DIR 仅兜底
    local src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)[/\\]") or MOD_LUA_DIR
    local okr, attach = false, nil
    if dir then
        okr, attach = pcall(dofile, dir .. "/resource.lua")
    end
    if not (okr and type(attach) == "function") then
        error("hoi4_layout: resource.lua 加载失败: " .. tostring(attach))
    end
    attach(M)
end

-- 共享访问器: MSVC std::string 读取 (buf@+0/堆指针, len@+0x10, cap@+0x18)
-- 供 objects.lua 等引用; 校验 len 与实际串长一致, 失败返回 nil
-- 长度上界与 DLL 侧 STR_READ_MAX 同值: 两侧必须一致 (旧 256 上限把长串
-- 静默变 nil, 实测本地化值最长 371 字符已被误杀)。
-- 注意: hoi4.read_str 接受的是串对象地址; 堆缓冲区须用 read_cstr
function M.read_msvc_str(o)
    if not o or o == 0 then return nil end
    local len = rp(o + 0x10)
    if not len or len > M.lim.STR_READ_MAX or len == 0 then return nil end
    local buf = o
    local heap = len > 15
    if heap then
        buf = rp(o)
        if not buf or buf < 0x10000 then return nil end
    end
    local s = heap and hoi4.read_cstr(buf) or hoi4.read_str(buf)
    -- len 与实取长度必须相等: 只差在 SSO 尾部填充/垃圾槽, 宁可判 nil
    if s and #s == len then return s end
    return nil
end

-- ---------------------------------------------------------------- 具名防御界 + 运行时结构计数 (裁定)
-- 硬编码 440 国家数在 mod 加国后即错 (大 mod 加国前科) — 结构计数
-- 一律运行时读; 防御界用具名常量 (防御界 ≠ writer 门)。
M.lim = {
    PTR_SANE = 4096,   -- 通用内容列表防垃圾指针界 (writer 无门的容器)
    PTR_HUGE = 65536,  -- 大型数组 (RH 扫描/装备池)
    FIXED_SMALL = 64,  -- 仅 writer 明文有界或固定槽容器 (slots/rules/队列)
    STR_READ_MAX = 131072,  -- 串读取上界, 与 DLL 侧 STR_READ_MAX 同值 (须同步改)
    -- 容器元素指针上界。⚠ 比 M.const.PTR_HI 紧一个量级边界 (0x7FF vs 0x7FFF):
    -- 本值 = 旧 objects_shared O.kptr 判据, 容器元素校验一律用它 (收窄上界 =
    -- 更早剔除垃圾), 通用指针判定才用 M.const.PTR_HI。两者并存是历史遗留。
    PTR_ELEM = 0x7FF000000000,
}
-- 固定槽/明文有界结构维度 (本质也是 magic num — 具名化;
-- 每项注明证据与出处类别, 段侧一律引用此处, 禁止散写字面量。
-- 类别: [二进制]=writer/ctor 原文定案; [惯例]=历史 reader 结论待复核)
M.dim = {
    EXTERNAL_RULES = 28,   -- [二进制] external_rules 槽 (§4.26.3 external_rules 定义)
    RULE_OVERRIDES = 28,   -- [二进制] rule_overrides 槽 (writer sub_140D19300 字面
                           -- 枚举 28 flag + 28 容器, 定长 [808,2496) 无 count;
                           -- 同 external_rules 28 规则宇宙, §4.26.3)
    LOGISTICS_SLOTS = 19,  -- [二进制] logistics 槽 {d@logi+8} (writer 0x1413609D0)
    HISTORY_QUEUES = 3,    -- [二进制] 每 CLoopHistory 队列数 (qc 偏移 0x10/0x18/0x20; §4.3.13)
    AI_STRATEGY_SLOTS = 112, -- [二进制] AI ai_strategy/persistent_strategy 双数组槽数 (§4.34)
    MODIFIER_HOURS = 30,   -- [二进制] combat log modifier_hours 槽 (30×u32@lb+624; §4.22)
}

-- ---------------------------------------------------------------- vtable RVA 表 (唯一实现)
-- 虚表 RVA (运行时地址 = base + 值)。悬垂防护 = `O.vt(addr, M.vt.X)` 校验
-- (读对象首 qword 与 base+RVA 比对)。**段/对象文件一律引用此处, 禁止散写**
-- 0x29xxxxx 字面量**。
-- ⚠ 收录纪律: **只收代码中真实出现过 vtable 校验的类** (值可 grep 复核)。
-- 无 vtable 校验、仅靠 kptr+偏移访问的类**不入表** (宁缺勿造 —
-- 凭空填值 = 引入错误常量, 比散写字面量更危险)。
-- 类名以 RTTI 为准 (书 §4.00 各节表格); 次虚表以 _vt2/_vt3 区分。
M.vt = {
    -- 国家子系统
    CPolitics            = 0x294fda8,   -- cc+3984 (§4.10 CPolitics)
    CTechnologyStatus    = 0x2974fa0,   -- cc+3936 (§4.7)
    CCountryIntel        = 0x295f188,   -- cc+4072 (§4.11.7)
    CCountryIntelAgency  = 0x2981f68,   -- cc+4032
    CCountryReportsMgr   = 0x29D10A8,   -- cc+4064 (§4.3.20 CCountryReportsManager; RTTI 定案, 旧 0x29BA4B8 系 1.19.2)
    CDeployment          = 0x294f5b0,   -- cc+3952 部署模板 (§4.18 CDeployment)
    CSubUnitStatBonus    = 0x295faa8,   -- §4.18.11 CSubunitBonusPersistent
    CBuildingStatus      = 0x2999050,   -- 州级/国家级建筑池共用 (§4.13/§4.3)
    -- 国家经济/生产
    COrganisation        = 0x2967a28,   -- §4.8.12 NIndustrialOrganisation::COrganisation
    CProductionStatus    = 0x2970788,   -- 州监听元素 (§4.13, 非 cc+3944)
    -- 陆军/海军/空军
    CArmy_vt0            = 0x295a2b0,   -- §4.18 CArmy
    CArmy_vt1            = 0x295a490,   -- §4.18 CArmy (次虚表)
    CNavyLeader          = 0x2955dc0,   -- §4.4.6 CNavyLeader
    CNavalBase           = 0x29732e0,   -- §4.16 (书 §1.3: NAVY.mgr_vt; 别名 CNavyManager)
    CNavalBase_vt2       = 0x2973260,   -- §4.16 (书 §1.3: navy_vt CStrategicNavy)
    CNavalBase_vt3       = 0x29731c0,   -- §4.16 (书 §1.3: base_vt)
    CUnitHistoryEntry    = 0x29c1818,   -- §4.18 部队 history 容器条目
    -- 战略空军 (§4.15)
    CStrategicAirMgr     = 0x29588f8,   -- gs+0x690
    CStrategicAirCountry = 0x29587d8,
    CAirWingPool         = 0x297ae38,
    CAirBase             = 0x2958780,
    CStrategicAir_vt2    = 0x2958968,
    -- 州/省/世界
    CState               = 0x2936cc0,   -- §4.13 CState
    CProvince            = 0x2971b18,   -- §4.14 CProvince
    CRailwayManager      = 0x2972cd0,   -- §4.14.7 CRailwayManager
    CProvinceRailwayInfo = 0x2972c80,   -- §4.14.6 CProvinceRailwayInfo
    CWeatherManager      = 0x2977810,   -- gs+0x688 (§4.20 CWeatherManager)
    CSupplySystem        = 0x2973cf0,   -- gs+0x3D8 (§4.21 CSupplySystem)
    -- 角色
    CCharacter           = 0x297ea60,   -- gs+0x6A8 (§4.4 CCharacter)
    CAdvisorTemplate     = 0x29bba98,   -- §4.4.13 CAdvisorTemplate
    -- 情报/谍报
    CStrategicOperativesMgr = 0x2973b80, -- gs+0x6A0 (§4.11 CStrategicOperativeManager)
    CStrategicOperative  = 0x29a2358,   -- §4.11 CStrategicOperative
    COperativesNet       = 0x29a1a58,   -- §4.11 谍报网
    COperativesSubNet    = 0x29a1aa8,   -- §4.11 子网
    -- 战斗
    CCombatManager       = 0x2950688,   -- gs+0x260 (§4.22 CCombatManager)
    CCombatLogManager    = 0x295d8d8,   -- gs+0x268 (§4.22)
    CCombatLogEntry      = 0x295d888,   -- §4.22 log 条目元素
    CLandBorderWarCombat = 0x29bc5f0,   -- §4.22 CLandBorderWarCombat
    -- 特殊项目/装备/经验
    CSpecialProjectStatus= 0x2971838,   -- cc+4008 (§4.7.9)
    CSpecialProjectPool  = 0x29c6e28,   -- §4.3.12 NProject::CProjectPool
    CSpecialProject      = 0x29717e0,
    CBreakthroughProgress= 0x2a2c040,
    CEquipmentVariant    = 0x2951608,   -- §4.23.1 CEquipmentVariant
    CExperienceStatus    = 0x29a80c0,   -- cc+5512 (§4.3.17 CCountryExperienceStatus)
    CExperienceElem      = 0x2958040,   -- §4.3.17 经验元素
    -- 力量平衡/和会
    CPowerBalanceSystem  = 0x296fca0,   -- gs+0x450 (§4.3.21 CPowerBalanceSystem)
    CPowerBalanceEntry   = 0x296fc50,   -- §4.3.21 CPowerBalance
    CPeaceConferenceMgr  = 0x270AE28,   -- gs+0x4E0 (§4.10.27 CPeaceConferenceManager)
    CPeaceConference     = 0x2950e58,   -- §4.10.27 CPeaceConference
    CWarScoreBreakdown   = 0x2960128,   -- §4.10.27 CWarScoreBreakdown
    -- 学说/历史
    CDoctrineCs           = 0x29653f8,  -- §4.6 学说
    CDoctrineFolder       = 0x29653a8,  -- §4.6
    CDoctrineTrack        = 0x2965358,  -- §4.6
    CLoopHistory          = 0x29d2a48,  -- §4.3.13 CLoopHistory
    CLoopHistoryEntry     = 0x29d29a8,  -- §4.3.13
    -- 燃料/资源
    CFuelStatus          = 0x298b3a8,   -- cc+5504 (§4.3.16 CFuelStatus)
    CCountryResources    = 0x295c4b0,   -- cc+4600 (§4.3.1/§4.3.3)
    CResourceDelivery    = 0x295c320,   -- rs+1928 交付路由元素 (§4.23 CResourceDeliveryRoute)
    CResourceOrigin      = 0x295c370,   -- 资源起源元素
    -- 元素级虚表 (容器内嵌对象)
    CIntelSource         = 0x295f138,   -- 谍报网内联 @net+168 (§4.11)
    CActivityElem        = 0x295a5b0,   -- 活动数据 xp_by_template 元素 (§4.3)
    CActivityElemAir     = 0x2965260,   -- 活动数据 xp_by_airwing 元素 (§4.3)
    CCountryCharacters   = 0x298ae18,   -- cc+4080 country_characters (§4.3)
    CWeatherProvince     = 0x2977770,   -- 天气省级元素 (@mgr+0x10, stride 0x180; §4.20)
    CCountrySupplySystem = 0x29a2b08,   -- 补给国级元素 (§4.21)
    CScriptedGuiData     = 0x29848d8,   -- §4.30 CScriptedGuiData
}

-- ---------------------------------------------------------------- 虚表槽契约
-- 各族虚方法槽号 (书 §4.00.1 序列化槽 / §4.00.3 行为槽)。用法: 取某类 vtable
-- 后按槽号读/钩该虚方法 —— 配合 hoi4.hook_vt(vt, M.vtslot.CEffect.execute, fn)。
--
-- ⚠ 两套编号体系, 勿混 (书 §4.00.1 与 §4.00.3 是分族的, 不是冲突):
--   · CPersistent 族 (CCountry/CState/CProvince/CCharacter/CPoliticalStatus/
--     CCountryPlayerSettings/CCommand): [1]Save [2]writer [3]Load [4]reader。
--   · CEffect / CTrigger **不是** CPersistent 族 (基链含 CProfiledScopeObject/
--     CPdxArray), 各有独立槽表, 故上面 1-4 编号对其不适用。
--   · CCommand 两者兼具: 1-4 槽承 CPersistent, 另有自己的行为槽。
M.vtslot = {
    -- 书 §4.00.1 (七类同构; [1]/[3]/[5] 全类同址不覆写, [2]/[4] 纯虚逐类变)
    CPersistent = { save = 1, writer = 2, load = 3, reader = 4, const_false = 5 },

    -- 书 §4.00.3 CCommand (基表 0x1427214C8; 1-4 承 CPersistent)
    -- ⚠ [2]/[4] 全家族共享不覆写 —— 读载荷勿按基类槽取, 用 [22]/[23]
    CCommand = {
        save = 1, writer = 2, load = 3, reader = 4,
        isvalid = 9, execute = 10, gettypeid = 11, clone = 13,
        payload_writer = 22, payload_reader = 23,
    },

    -- 书 §4.00.3 CEffect (25 槽 0..24; 基链非 CPersistent)
    -- 拦截执行 → execute (13); [12] 是作用域校验外壳 (先校验再转 [13])
    CEffect = {
        getname = 1, parse_block = 3, parse_keys = 4, parse_target_token = 6,
        getdesc = 7, execute_checked = 12, execute = 13,
        scope_mask = 19, target_mask = 20, is_valid_scope = 21,
        validate_targets = 22, resolve_refs = 23,
    },

    -- 书 §4.00.3 CTrigger (23 槽 0..22; 另有可选 [23] 仅 241/546 虚表含)
    -- 拦截求值 → evaluate (22); [3] 是作用域校验外壳 (合法才转 [22])
    CTrigger = {
        getname = 1, is_assign = 2, evaluate_checked = 3, parse_value_keys = 4,
        parse_block = 5, parse_token = 6, validate = 7,
        scope_mask = 14, target_mask = 15, getdesc = 21, evaluate = 22,
    },
}

-- ---------------------------------------------------------------- 全局哨兵/纪元常量
-- 数值哨兵与历法纪元 (书 §3.7 哨兵全表 + §4.1.1)。散写数字一律改引此处。
M.const = {
    DATE_EPOCH    = 43800000,   -- 纪元 = 0.1.1.1 常态 (day0 原点)
    DATE_UNSET    = 43808760,   -- CGameDate 默认构造 "1.1.1.1" (双哨兵之一)
    DATE_DEFAULT2 = 43817520,   -- CGameDate 默认构造 "2.1.1.1" (带门字段跳过)
    DATE_NEG1     = 0x29C3388,  -- 43791240 = "-1.1.1.1" 合法值 (部分字段当哨兵滤)
    DATE_OBSOLETE = 0x29C77F8,  -- 43791352 = obsolete_change_date 字段专属默认
    PTR_LO        = 0x10000,    -- 指针下界 (小于此 = 非指针)
    PTR_HI        = 0x7FFF00000000, -- 指针上界 (kptr 判据)
}
-- ⚠ 以下三者曾是 M.dim 误录 (§4.26.6 核验)
-- 历史队列行数 → 读 queue 对象自身 max_elements/rows 字段, 勿用字面量;
-- PORTRAITS: 动态 count 容器, 插入按 (branch,size) 键去重覆盖 →
-- 结构上限 = 6 分支 × 2 尺寸 = 12 (推导值, 代码无字面量); 16 纯防御;
-- NTT_UNITS: writer 0x140E14640 循环上界 = 容器 count@T+68, 无明文
-- 常量 — 真值运行时读, 防御用 M.lim.FIXED_SMALL。
local function gs()
    return rp(hoi4.base() + M.rva.gamestate_ptr)   -- §1.1 CGameState 单例
end
M.gamestate = gs
-- 国家数组计数 (§1.2 CGameState +784 国家指针数组, 含 idx0 哨兵; mod 加国后随动)
function M.country_count()
    local g = gs()
    return g and hoi4.read_u32(g + 0x31C) or nil   -- §1.2 CGameState +796 国家数
end
-- 州计数 (§1.2 CGameState +712 州表 / count@+724 — states writer 循环界;
-- ⚠ +712 州表与省表分立: gs+0x2BC 为省表界 (=max 省 id+1), 勿当州数用)
function M.state_count()
    local g = gs()
    return g and hoi4.read_u32(g + 0x2D4) or nil   -- §1.2 CGameState +724 州表 count
end
-- 省计数 — ⚠ 命名勘误: gs+736/748 = 区域表 (§1.2 CGameState; loader case 10827
-- region), 非省数; 真省表 = *(gs+0x2B0) (§1.2 +688 省指针数组), 其 count 偏移
-- 待探针定案。保留旧名兼容 + 区域名别名。
function M.province_count()
    local g = gs()
    return g and hoi4.read_u32(g + 0x748) or nil   -- §1.2 CGameState +748 区域表 count
end
M.region_count = M.province_count
-- 真省数组指针 (省表 = *(gs+0x2B0); 计数待定案, 用 id 上界防御)
function M.province_array()
    local g = gs()
    return g and rp(g + 0x2B0) or nil              -- §1.2 CGameState +688 省指针数组
end

-- ================================================================ 通用容器枚举 (唯一实现)
-- 全库容器遍历的唯一实现。族: vector / robin-hood / 红黑树(std::map) / 侵入式链表。
-- 设计纪律:
--   ① 容器偏移一律引 M.cont (禁散写), 与 M.dim / M.lim / M.vt 同惯例;
--   ② 每族返回同形 (迭代器, 计数), 迭代器 yield (序号, 元素地址);
--   ③ 容器不可用时返回**空迭代器而非 nil** —— `for ... in` 直接消费不抛错;
--   ④ 容器布局属 structure knowledge, 故住 Lua 层 (DLL 侧只提供裸读原语,
--      游戏更新容器布局变动只改本文件, 不进 C)。
M.cont = {
    -- std::vector 族 (§3.1): **delta = count 相对 data 偏移的位移**
    -- (⚠ 不是绝对偏移: data 占 8 字节, 绝对 +8/+12 会重叠)
    -- delta-12 为主流 (452 处), delta-8 为少数真实变体 (13 处), 不可合并。
    vec     = { delta = 12 },
    vec_alt = { delta = 8  },
    -- robin-hood 哈希表 (§3.2; 第三方库非 STL): 以下均为**结构内绝对偏移**
    -- 数据指针 / mask(=桶数-1) / 尾部 extra 溢出桶字节 / count / 桶内 dist
    rh      = { data = 8, mask = 20, extra = 24, count = 16, dist = 4 },
    -- std::map 红黑树 (§3.3): 节点内绝对偏移; 中序 = 存档序
    rb      = { root = 0, left = 0, right = 16, parent = 8, isnil = 25 },
    -- 侵入式单链表: next 指针
    list    = { next = 0 },
}

local BASE = hoi4.base()

-- 空迭代器: 容器不可用时的统一返回 (for-in 可直接消费, 不抛错)
local function noop_iter() return nil end

-- 容器元素指针有效性 (用 M.lim.PTR_ELEM, 比通用 kptr 上界紧)
local function elem_ptr(v)
    return v ~= nil and v >= 0x10000 and v < M.lim.PTR_ELEM
end
M.elem_ptr = elem_ptr

-- ---- vector ----
-- base = 容器基址; doff = 元素数组指针偏移 (必填); stride = 元素跨距
-- opts = { count  = 计数偏移**绝对值** (省略则按 shape 的 delta 推: doff+delta)
--          shape  = "vec"(delta 12, 默认) / "vec_alt"(delta 8)
--          deref  = true 元素为指针数组则解引用 (默认 false, yield 元素地址)
--          vt     = vtable RVA, 仅收首 qword == BASE+RVA 的元素
--          max    = 计数上界 (默认 M.lim.PTR_HUGE) }
-- 返回 (迭代器, 计数); 迭代器 yield (i, 元素地址 或 解引用值)
function M.vec(base, doff, stride, opts)
    opts = opts or {}
    if not base or base == 0 or not doff or not stride or stride <= 0 then
        return noop_iter, 0
    end
    local maxn = opts.max or M.lim.PTR_HUGE
    local coff = opts.count
    if not coff then
        local sh = M.cont[opts.shape or "vec"] or M.cont.vec
        coff = doff + (sh.delta or 12)
    end
    local d = rp(base + doff)
    local c = hoi4.read_u32(base + coff)
    if not elem_ptr(d) or not c or c <= 0 or c > maxn then
        return noop_iter, 0
    end
    local vt = opts.vt and (BASE + opts.vt) or nil
    local deref = opts.deref
    local i = -1
    local function iter()
        while true do
            i = i + 1
            if i >= c then return nil end
            local a = d + stride * i
            if not vt or rp(a) == vt then
                return i, deref and rp(a) or a
            end
        end
    end
    return iter, c
end

-- ---- robin-hood ----
-- 桶数推导 (唯一实现): mask+1+extra 优先 (writer 循环上界含尾部溢出桶,
-- state/country variables 实证丢尾), mask 缺失时退化为 count 兜底。
local function rh_layout(ht, sh, maxn)
    if not ht or ht == 0 then return nil end
    local data = rp(ht + sh.data)
    if not elem_ptr(data) then return nil end
    local nbuckets
    local mask = hoi4.read_u32(ht + sh.mask)
    if mask and mask > 0 and mask <= maxn then
        local extra = hoi4.read_u8(ht + sh.extra) or 0
        nbuckets = mask + 1 + extra
    else
        local cnt = hoi4.read_u32(ht + sh.count)
        if not cnt or cnt <= 0 or cnt > maxn then return nil end
        nbuckets = cnt
    end
    if nbuckets > maxn then return nil end
    return data, nbuckets
end

-- ht = 哈希表头地址; stride = 桶跨距
-- opts = { shape = M.cont 名或显式表 (默认 "rh"); max = 安全上限 (默认 1000000) }
-- 返回 (迭代器, 桶数); 迭代器 yield (i, 占位桶地址) —— 调用方按自己的桶布局解字段
function M.rh(ht, stride, opts)
    opts = opts or {}
    local sh = M.cont[opts.shape or "rh"] or M.cont.rh
    local maxn = opts.max or 1000000
    if not stride or stride <= 0 then return noop_iter, 0 end
    local data, nb = rh_layout(ht, sh, maxn)
    if not data then return noop_iter, 0 end
    local dist_off = sh.dist or 4
    local i = -1
    local function iter()
        while true do
            i = i + 1
            if i >= nb then return nil end
            local e = data + stride * i
            local dv = hoi4.read_u32(e + dist_off)
            if dv and (dv & 0xFF) ~= 0 then return i, e end
        end
    end
    return iter, nb
end

-- ---- 红黑树 (std::map) ----
-- head = 树对象地址 (根指针在 head + shape.root); 中序遍历 (== 存档序)
-- opts = { shape = M.cont 名或显式表 (默认 "rb"); max = 节点数上界 }
-- 返回 (迭代器, nil); 迭代器 yield (序号, 节点地址)
function M.rb(head, opts)
    opts = opts or {}
    local sh = M.cont[opts.shape or "rb"] or M.cont.rb
    local maxn = opts.max or M.lim.PTR_HUGE
    if not elem_ptr(head) then return noop_iter, 0 end
    local function isnil(p)
        return not p or ((hoi4.read_u32(p + sh.isnil) or 0) & 0xFF) ~= 0
    end
    local node = rp(head + sh.root)
    if isnil(node) then return noop_iter, 0 end
    -- 中序起点 = 最左节点
    while true do
        local l = rp(node + sh.left)
        if isnil(l) then break end
        node = l
    end
    local n = 0
    local function iter()
        if not node or n >= maxn then return nil end
        local cur = node
        -- 中序后继: 有右子树则钻其最左; 否则沿父链上溯直到"从左侧上来"
        local r = rp(cur + sh.right)
        if not isnil(r) then
            node = r
            while true do
                local l = rp(node + sh.left)
                if isnil(l) then break end
                node = l
            end
        else
            local up = cur
            local p = rp(up + sh.parent)
            while not isnil(p) and rp(p + sh.right) == up do
                up = p
                p = rp(p + sh.parent)
            end
            -- ⚠ 不可写 `isnil(p) and nil or p`: p 恒为真值时该习语返回 p 而非
            -- nil (Lua and/or 陷阱), 会把哨兵当节点继续走。
            if isnil(p) then node = nil else node = p end
        end
        n = n + 1
        return n, cur
    end
    return iter, nil
end

-- ---- 侵入式单链表 ----
-- head = 首节点地址 (非头对象)
-- opts = { shape = M.cont 名或显式表 (默认 "list"); max = 节点数上界 }
-- 返回 (迭代器, nil); 迭代器 yield (序号, 节点地址)
function M.list(head, opts)
    opts = opts or {}
    local sh = M.cont[opts.shape or "list"] or M.cont.list
    local maxn = opts.max or M.lim.PTR_HUGE
    if not elem_ptr(head) then return noop_iter, 0 end
    local node = head
    local n = 0
    local function iter()
        if not elem_ptr(node) or n >= maxn then return nil end
        local cur = node
        n = n + 1
        node = rp(cur + sh.next)
        return n, cur
    end
    return iter, nil
end

-- 收集式消费糖: 把迭代器全部元素收成数组 (空迭代器 -> 空表)
function M.gather(iter)
    local out = {}
    if not iter then return out end
    for _, e in iter do out[#out + 1] = e end
    return out
end

-- 指针 → 索引/任意键 反查索引 (唯一实现; 强制代际戳)。
-- 返回一个访问器闭包: 调用即得 map, 仅在代际戳变化时重建。
-- ⚠ gen_fn 必须同时含容器 **data 指针与计数** —— 只盯计数上界会在
-- "容器搬家但计数未变" 时留悬垂 (token 表实测过一次真实搬家: 旧缓冲已释放)。
-- 用法:
--   local sid_of = M.rev_index(
--       function() local st = rp(g+0x2C8); return tostring(st)..":"..tostring(ru32(g+0x2D4)) end,
--       function() ...建表... return m end)
--   local m = sid_of()
function M.rev_index(gen_fn, build_fn)
    local stamp, map
    return function()
        local g = gen_fn()
        if map == nil or stamp ~= g then
            map = build_fn()
            stamp = g
        end
        return map
    end
end

-- ---------------------------------------------------------------- 州表指针 → state_id 反查 (唯一实现)
-- §1.2 CGameState +712 (0x2C8) 州表; 哨兵终止: 首遇非指针即止。
-- 消费者: objects_shared.sid_map2 (读层) / sv2 段 sid_map (导出层) —— 均委派到此。
-- ⚠ 代际戳含**州表数据指针 + 计数**两者: 只盯计数会在"表搬家但计数未变"时
-- 留下悬垂旧指针的错映射 (token 表实测过一次真实搬家, 旧缓冲已释放)。
-- 实例住文件级 (放函数内 = 每次调用重建闭包 = 缓存永不命中)。
local sid_g
local sid_rev = M.rev_index(
    function()
        local g = sid_g
        return tostring(g and rp(g + 0x2C8) or 0) .. ":"
            .. tostring(g and hoi4.read_u32(g + 0x2D4) or 0)
    end,
    function()
        local m = {}
        local stbl = sid_g and rp(sid_g + 0x2C8)
        if stbl and stbl >= 0x10000 and stbl < M.lim.PTR_ELEM then
            for sid = 1, 4096 do
                local p = rp(stbl + 8 * sid)
                if not (p and p >= 0x10000 and p < M.lim.PTR_ELEM) then break end
                m[p] = sid
            end
        end
        return m
    end)
-- g = gamestate 地址; 返回 { [州指针] = state_id }
function M.state_index_map(g)
    sid_g = g
    return sid_rev()
end

-- ---------------------------------------------------------------- robin_hood 旧接口
-- PDX 引擎的 robin_hood 哈希表 (§3.2)。M.rh_iter 为**兼容保留**的收集式接口
-- (返回占位桶地址列表); 新代码请直接用 M.rh (同形迭代器) 或 M.gather(M.rh(...))。
-- 参数: ht_addr = 哈希表头地址; opts = {data=数据指针偏移(默认8),
-- mask=mask偏移(默认0x14), stride=桶大小, maxn=安全上限}
-- 结构不可用时返回 nil (与 M.rh 返回空迭代器的差异为兼容旧调用点)。
function M.rh_iter(ht_addr, opts)
    opts = opts or {}
    local moff = opts.mask or 0x14
    local sh = { data = opts.data or 8, mask = moff, extra = moff + 4,
                 count = opts.count or 0x10, dist = 4 }
    local data, nb = rh_layout(ht_addr, sh, opts.maxn or 1000000)
    if not data then return nil end
    local stride = opts.stride or 0x30
    local out = {}
    for i = 0, nb - 1 do
        local e = data + i * stride
        local dv = hoi4.read_u32(e + 4)
        if dv and (dv & 0xFF) ~= 0 then out[#out + 1] = e end
    end
    return out
end

-- flag store address (nil if gamestate not up yet)
function M.flag_store()
    local gs = rp(hoi4.base() + M.rva.gamestate_ptr)
    if not gs then return nil end
    return rp(gs + M.off.global_state.flag_store)
end

-- all global flags as a Lua table {name = value}; nil if unavailable
function M.flags()
    local store = M.flag_store()
    if not store then return nil end
    local entries = rp(store + M.off.flag_store.entries)
    local count = hoi4.read_u32(store + M.off.flag_store.count)
    if not entries or not count then return nil end
    if count < 0 or count > 100000 then return nil end
    local tokTable = rp(hoi4.base() + M.rva.lexer_token_table)
    local maxTok = hoi4.read_u32(hoi4.base() + M.rva.lexer_token_max)
    local out = {}
    for i = 0, count - 1 do
        local e = entries + i * M.off.flag_entry.stride
        local key = hoi4.read_u32(e + M.off.flag_entry.key)
        local val = hoi4.read_u16(e + M.off.flag_entry.value)
        local name
        if tokTable and maxTok and key and key >= 0 and key <= maxTok then
            name = hoi4.read_str(tokTable + key * M.off.token_string.stride)
        end
        if not name or name == "" then name = string.format("<key %d>", key or -1) end
        out[name] = val
    end
    return out
end

-- single global flag by name -> value or nil (重建 C 侧已删的 hoi4.get_flag;
-- name -> token id via reverse index over the lexer token
-- table, then linear scan of the store — flags use lexer token ids, NOT the
-- FNV-1a hash used by the variables table; §4.26.2)
-- 索引带版本戳: 上界变化即重建 (全表 O(max) ≈ 20ms @96k, 仅探针/反查
-- 路径使用, 非导出热路径) token 表单进程内单调增长
-- (动态列表仅 atexit 释放), 上界比较足以捕获; 真出现回落也会重建
-- (判等而非判增, 两个方向都安全, 成本同一次 u32 读)。
-- 旧版"每进程一次"在表增长后新名一律反查不到 (大后期档实测)。
-- 版本戳 = (表指针, 上界) 两读; 任一变化即重建。
-- ⚠ 指针必须入戳 — 已实测: token 表是自研 vector
-- {data@+0(u64), cap@+8(u32), count@+0xC(u32), alloc@+0x10(u64)},
-- Rebuild (sub_1424A8D20) 在 count+4000 > cap 时经 sub_1401268D0
-- 按 1.5x 扩容 → sub_1401285C0 搬元素 + **释放旧缓冲 + 装新指针**
-- (5791869: *a1 = a2)。本机实测一次真实搬家
-- 走前 p=1810b13b040 cap=121488 → 走后 p=18101302040 cap=182232
-- (同会话内, 旧缓冲已释放)。只盯上界会在"搬家但 max 未变"时留悬垂。
-- 成本 2 次 h4 读 (实测 0.03us), 相对 20ms 重建可忽略。
local tok_index = nil       -- {max=, tbl=, idx={name -> id}}
local function build_token_index()
    local B = hoi4.base()
    local tbl = rp(B + M.rva.lexer_token_table)
    local mx  = hoi4.read_u32(B + M.rva.lexer_token_max)
    if not tbl or not mx or mx <= 0 or mx > 200000 then return nil end
    local idx = {}
    for id = 1, mx do
        local s = hoi4.read_str(tbl + id * M.off.token_string.stride)
        if s and s ~= "" then idx[s] = id end
    end
    return { max = mx, tbl = tbl, idx = idx }
end

local function token_index()
    local B = hoi4.base()
    local cur_mx  = hoi4.read_u32(B + M.rva.lexer_token_max)
    local cur_tbl = rp(B + M.rva.lexer_token_table)
    if not tok_index or tok_index.max ~= cur_mx or tok_index.tbl ~= cur_tbl then
        tok_index = build_token_index()
    end
    return tok_index
end

-- name → token id 公共反查 (导出为公共访问器; 反查不到返回 nil)
-- — 与 get_flag 共用同一索引
function M.name_to_token(name)
    if type(name) ~= "string" then return nil end
    local ti = token_index()
    return ti and ti.idx[name] or nil
end

function M.get_flag(name)
    if type(name) ~= "string" then return nil end
    local ti = token_index()
    if not ti then return nil end
    local name_to_tok = ti.idx
    if not name_to_tok then return nil end
    local key = name_to_tok[name]
    if not key then return nil end
    local store = M.flag_store()
    if not store then return nil end
    local entries = rp(store + M.off.flag_store.entries)
    local count = hoi4.read_u32(store + M.off.flag_store.count)
    if not entries or not count then return nil end
    for i = 0, count - 1 do
        local e = entries + i * M.off.flag_entry.stride
        if hoi4.read_u32(e + M.off.flag_entry.key) == key then
            return hoi4.read_u16(e + M.off.flag_entry.value)
        end
    end
    return nil
end

-- country flag store: §4.3 CCountry +560 -> CFlagManager (布局 §4.13.3)
-- returns {tag=..., store=addr} list of all countries with non-empty stores
function M.country_stores()
    local gs = rp(hoi4.base() + M.rva.gamestate_ptr)
    if not gs then return nil end
    local arr = rp(gs + 0x310)          -- §1.2 CGameState +784 国家指针数组
    local cnt = hoi4.read_u32(gs + 0x31C) -- §1.2 CGameState +796 国家数
    if not arr or not cnt or cnt <= 0 or cnt > 10000 then return nil end
    local out = {}
    for i = 0, cnt - 1 do
        local c = rp(arr + i * 8)
        if c and c ~= 0 then
            local store = rp(c + M.off.country.flag_store)
            if store and store ~= 0 then
                table.insert(out, { country = c, store = store, index = i })
            end
        end
    end
    return out
end

-- all flags of one country as a Lua table {name = {value, expiry, setdate}}
function M.country_flags(country)
    local store = rp(country + M.off.country.flag_store)
    if not store then return nil end
    local entries = rp(store + M.off.flag_store.entries)
    local count = hoi4.read_u32(store + M.off.flag_store.count)
    if not entries or not count then return nil end
    if count < 0 or count > 100000 then return nil end
    local tokTable = rp(hoi4.base() + M.rva.lexer_token_table)
    local maxTok = hoi4.read_u32(hoi4.base() + M.rva.lexer_token_max)
    local out = {}
    for i = 0, count - 1 do
        local e = entries + i * M.off.flag_entry.stride
        local key = hoi4.read_u32(e + M.off.flag_entry.key)
        local val = hoi4.read_u32(e + M.off.flag_entry.value)   -- i16 value + i16 expiry
        if key then
            local name
            if tokTable and maxTok and key >= 0 and key <= maxTok then
                name = hoi4.read_str(tokTable + key * M.off.token_string.stride)
            end
            if not name or name == "" then name = string.format("<key %d>", key) end
            local v = (val & 0xFFFF)
            if v >= 0x8000 then v = v - 0x10000 end          -- signed i16
            local expiry = (val >> 16) & 0x7FFF              -- i16 expiry days
            local setd = hoi4.read_u32(e + M.off.flag_entry.setdate)
            out[name] = { value = v, expiry = expiry, setdate = setd }
        end
    end
    return out
end

-- ---------------------------------------------------------------- global variables
-- Robin Hood hashtable with FNV-1a keys. Linear scan is simplest and safe
-- iterate all buckets, skip empty slots (dist==0).

local function var_ht()
    local gs = rp(hoi4.base() + M.rva.gamestate_ptr)
    if not gs then return nil end
    local owner = rp(gs + M.off.global_state.var_owner)  -- §4.25.1 CVariables*
    if not owner then return nil end
    -- hashtable struct is INLINE at owner+0x10 (FUN_140bb66f0 passes
    -- container+0x10 directly to FUN_140bb49f0), not a pointer; §4.13.2
    return owner + M.off.var_owner.ht
end

local function fnv1a(s)
    local h = 0x811c9dc5
    for i = 1, #s do
        h = ((string.byte(s, i) ~ h) * 0x1000193) % 0x100000000
    end
    return h
end
M.fnv1a = fnv1a

-- all global variables {name = value}; nil if unavailable
-- (rh_iter 抽象的首个消费者 — 原 24 行手写桶遍历收敛为解字段循环)
function M.vars()
    local ht = var_ht()
    if not ht then return nil end
    local buckets = M.rh_iter(ht, {
        data = M.off.var_ht.entries,
        mask = M.off.var_ht.mask,
        stride = M.off.var_entry.stride,
    })
    if not buckets then return nil end
    local out = {}
    for _, e in ipairs(buckets) do
        local name = hoi4.read_str(e + M.off.var_entry.key)
        local val = hoi4.read_u64(e + M.off.var_entry.value)  -- s64 (读原语即带符号; 无需补符号)
        if name and name ~= "" then out[name] = val / 1000.0 end
    end
    return out
end

-- raw pointer chain diagnosis (exposed for the test script)
function M.var_chain_diag()
    local gs = rp(hoi4.base() + M.rva.gamestate_ptr)
    local owner = gs and rp(gs + M.off.global_state.var_owner) or nil
    local ht = owner and (owner + M.off.var_owner.ht) or nil
    local entries = ht and rp(ht + M.off.var_ht.entries) or nil
    local mask = ht and hoi4.read_u32(ht + M.off.var_ht.mask) or nil
    local count = ht and hoi4.read_u32(ht + M.off.var_ht.count) or nil
    return {
        gs = gs, owner = owner, ht = ht,
        entries = entries, mask = mask, count = count,
    }
end

-- find the raw entry address of a global variable by name (nil if absent)
function M.var_entry(name)
    local ht = var_ht()
    if not ht then return nil end
    local entries = rp(ht + M.off.var_ht.entries)
    local mask = hoi4.read_u32(ht + M.off.var_ht.mask)
    if not entries or not mask then return nil end
    local h = fnv1a(name)
    local i = h & mask
    for step = 1, 64 do  -- bounded probe
        local e = entries + i * M.off.var_entry.stride
        local d = hoi4.read_u32(e + M.off.var_entry.dist)
        if not d then return nil end
        if (d & 0xFF) == 0 then return nil end      -- hit empty slot: absent
        if hoi4.read_u32(e + M.off.var_entry.hash) == h then
            if hoi4.read_str(e + M.off.var_entry.key) == name then return e end
        end
        if (d & 0xFF) < step then return nil end     -- Robin Hood invariant
        i = (i + 1) & mask
    end
    return nil
end

function M.get_var(name)
    local e = M.var_entry(name)
    if not e then return nil end
    local v = hoi4.read_u64(e + M.off.var_entry.value)
    if not v then return nil end
    return v / 1000.0
end

-- write an existing variable's value in place (fixed-point x1000);
-- creating NEW variables is NOT supported here — that needs the engine insert
-- (FUN_140bb49f0) which reallocates; use set_variable via effects instead.
function M.set_var(name, value)
    local e = M.var_entry(name)
    if not e then return false, "no such variable" end
    local fp = math.floor(value * 1000 + 0.5)
    -- 下界检查罩 float 溢出输入 (math.floor 对 |v|>2^53 仍返 float);
    -- 无需再"归一化"负数 — write_u64 收位模式, 负值原样落盘
    if fp > 0x7FFFFFFFFFFFFFFF or fp < -0x8000000000000000 then
        return false, "out of range"
    end
    return hoi4.write_u64(e + M.off.var_entry.value, fp)
end

return M
