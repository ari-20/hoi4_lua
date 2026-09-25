-- sv2_lib.lua -- savefull 直出共享库 (所有 sv2_sec_* 段的公共助手)
-- 由 savefull_export.lua 最先 load_sec; 段内用法
-- local SL = SV2.lib
-- SL.Q(s) SL.yn(v) SL.num(v) SL.idpair(id, type) SL.rp SL.ru32 ...
SV2.lib = {
    rp = hoi4.read_u64,
    ru32 = hoi4.read_u32,
    ru8 = hoi4.read_u8,
    -- i64 原始读 = 与 rp 同一原语: C 侧 (lua_Integer)*(uint64_t*) 已是带符号
    -- 重解释 (高位 1 → 负值入栈), 引擎**不存在**独立 read_i64 (旧写法
    -- `hoi4.read_i64 or hoi4.read_u64` 的 or 分支恒空转)。别名保留 = 调用点
    -- 标注该字段符号语义 (fixed×1e-5 / Q15 换算用), 见 §3.7 数值换算。
    rp_i64 = hoi4.read_u64,
}

local SL = SV2.lib

-- 非空串 -> 引号形, 否则 nil (writer 空串不写)
function SL.Q(s)
    if s and s ~= "" and s ~= "nil" then
        -- writer 对串内引号转义 (MD 角色 "Jack" 类名实证)
        return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\\"') .. '"' end
    return nil
end

-- 1/0 -> yes/no
function SL.yn(v) return (v == 1 or v == true) and "yes" or "no" end

-- 数值 -> 整数 %d / 其余 %.5f 去尾零 (§3.7 数值换算; fixed5 writer 格式:
-- "0.598"/"-0.15"; 多 token 串须逐字一致, 单 token 有 differ m_num 容差兜底)
function SL.num(v)
    if v == nil then return "0" end
    if v == math.floor(v) and math.abs(v) < 2 ^ 53 then
        return string.format("%d", math.floor(v))
    end
    local s = string.format("%.5f", v)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s
end

-- id 对: "id=N type=T"
function SL.idpair(id, ty)
    return string.format("id=%d type=%d", id or -1, ty or 0)
end

-- 同名键出现序计数器 (savefull [N] 契约 §4.1.14 提取路径/序号契约:
-- 首现不编号, 第二起 [2] [3]...)
-- 用法: local seq = SL.seqc; local key = seq("division_template")
function SL.seqc()
    local seen = {}
    return function(name)
        local n = (seen[name] or 0) + 1
        seen[name] = n
        return n == 1 and name or (name .. "[" .. n .. "]")
    end
end

-- 日期: CGameDate 总小时 -> "Y.M.D.H" (§3.7b CGameDate 三变体;
-- 与提取器存档形态一致)
-- 唯一实现 = hoi4_layout (A 族: 滤 {0,-1.1.1.1,43808760}, 不设年门)
-- 需要 B 族 (43808760 照发) 用 SL.date_raw; 需要引号形用 SL.date_quoted
function SL.date(h)
    return GAME.layout.date(h)
end

-- B 族: u32 回绕 + 滤 {<=0,-1.1.1.1}; 43808760 照发 "1.1.1.1"
function SL.date_raw(h)
    return GAME.layout.date_raw(h)
end

-- C 族: 不滤 + 引号形 (writer 字面量直接落盘)
function SL.date_quoted(h)
    return GAME.layout.date_quoted(h)
end

-- token -> 名 (§4.26.2 基础访问器; GAME.layout.token_name 兜底原值)
function SL.tok(t)
    if not t then return nil end
    local LAY = GAME.layout
    return (LAY and LAY.token_name(t)) or t
end

-- kptr 判
function SL.kptr(v) return v and v >= 0x10000 and v < 0x7FFF00000000 end

-- §3.5 MSVC SSO 串 {buf@0, size@0x10, cap@0x18}
function SL.sso(obj)
    if not obj or obj < 0x10000 then return nil end
    local size = SL.ru32(obj + 0x10)
    if not size or size > 4096 then return nil end
    if size == 0 then return "" end
    -- 内联判据 = cap (MSVC: cap>15 即堆, 即使 size≤15 — 缩短后堆缓冲
    -- 保留; 对拍实证 size=15/cap=31 堆串)
    local cap = SL.ru32(obj + 0x18)
    local buf = (cap and cap > 15) and SL.rp(obj) or obj
    if not buf or buf < 0x10000 then return nil end
    local t = {}
    for i = 0, size - 1 do
        t[#t + 1] = string.char(SL.ru8(buf + i) or 0)
    end
    return table.concat(t)
end

-- ============================================================
-- 共享 writer 发射件 — contract_definition 216B 本体 + CEquipmentVariantPool
-- (§4.23.3 合同/requests 元素同构; §4.10.25 CRequestEquipmentPurchaseAction
--  内嵌形)。
-- ⚠ 分层: **结构知识 (偏移/元素布局) 住 reader 层** —— 本件只保留 writer
-- 发射规则 (写序/块门/[N] 编号/seq)。数据一律经 R:pool_read /
-- R:contract_def_read (唯一实现 = objects_shared U.pool_read /
-- U.contract_def_read) 取得, 本文件**不再自持任何偏移字面量**。
-- ============================================================

-- CEquipmentVariantPool 发射 (writer slot2 0x141012DB0; 3 处复用)
-- R = Runtime (GAME.objects_v2); pfx 末点已含 (如 "...equipments.")
-- P = 池基址; opts 透传 pool_read ({max=} 拒收大计数 / {clamp=} 钳位)
-- 元素级跳过规则 (amount≠0 ∨ allow_zero≠0) 住 reader, 此处只发
function SL.pool_emit(R, emit, DIM, pfx, P, opts)
    local pr = R:pool_read(P, opts)
    local seq = SL.seqc()
    for _, e in ipairs((pr and pr.list) or {}) do
        local kp = pfx .. seq("equipment") .. "."
        emit(DIM, kp .. "id", SL.idpair(e.id, e.type))
        emit(DIM, kp .. "amount", SL.num(e.amount / 100000))
    end
    -- allow_zero_entries 恒写 (原样传原始 u8: 仅 ==1 判 yes, 与两族旧行为
    -- 一致 — combat 族原传 boolean(==1), emarket 族原传裸 u8, 二者同解)
    local az = (pr and pr.allow_zero) or 0
    emit(DIM, pfx .. "allow_zero_entries", SL.yn(az))
end

-- 带"整块空判"的池发射 (combat_side_data / combat_data 用; 空池整块不出)
-- 空判 (writer 0x140FFB8F0, pool1 全零) 住 reader (R:pool_empty)
function SL.pool_emit_gated(R, emit, DIM, pfx, P, opts)
    if R:pool_empty(P) then return end
    SL.pool_emit(R, emit, DIM, pfx, P, opts)
end

-- contract_definition 216B 本体 (writer sub_140DF1EC0)
-- def = def 本体起点 (合同 c+24 / requests 元素 req+24 / 动作 act+120)
-- DP 末点已含; 写序 = contract_draft (seller→buyer→equipments→speed→
-- subsidies) → price_levels (空表不发叶) → prices
function SL.def_emit(R, emit, DIM, DP, def)
    local d = R:contract_def_read(def)
    if not d then return end
    local DO = GAME.layout.off.contract_def   -- 布局知识唯一源 (禁散写)
    local function E(p, v) if v ~= nil then emit(DIM, p, v) end end
    local function Q(s) return SL.Q(s) end
    local RP = DP .. "contract_draft."
    E(RP .. "seller", Q(d.seller))
    E(RP .. "buyer", Q(d.buyer))
    SL.pool_emit(R, emit, DIM, RP .. "equipments.", def + DO.equipments,
                 { max = GAME.layout.lim.PTR_HUGE })
    E(RP .. "speed", tostring(d.speed or 0))
    -- draft.subsidies (仅 count>0; 空表不出块) — 元素布局住 reader
    for k, s in ipairs(d.subsidies or {}) do
        local kp = RP .. "subsidies.subsidies.#" .. k .. "."
        E(kp .. "cic", SL.num(s.cic))
        if s.archetype then E(kp .. "archetype", tostring(s.archetype)) end
        if s.trigger then E(kp .. "trigger", '"' .. s.trigger .. '"') end
        for j, t in ipairs(s.targets or {}) do
            E(kp .. "targets.#" .. j, Q(t))
        end
    end
    SL.pool_emit(R, emit, DIM, DP .. "prices.", def + DO.prices,
                 { max = GAME.layout.lim.PTR_HUGE })
end
