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
--  内嵌形)。base 恒取「使 base+24 = def 本体起点」的宿主基址:
--  合同 c → base=c; requests 元素 req → base=req; 动作 → base=act+96。
-- ============================================================

-- CEquipmentVariantPool 64B 序列化 (writer slot2 0x141012DB0; 3 处复用)
-- pfx 末点已含 (如 "...equipments."); 元素级跳过规则复刻 writer
function SL.pool_emit(emit, DIM, pfx, base)
    local d, n = SL.rp(base + 32), SL.ru32(base + 44)
    local az = SL.ru8(base + 56) or 0
    if SL.kptr(d) and n and n > 0 and n < GAME.layout.lim.PTR_HUGE then
        local seq = SL.seqc()
        for j = 0, n - 1 do
            local e = d + 16 * j
            local amt = SL.rp_i64(e + 8) or 0
            if amt ~= 0 or az ~= 0 then
                local var = SL.rp(e)
                if SL.kptr(var) then
                    local kp = pfx .. seq("equipment") .. "."
                    emit(DIM, kp .. "id",
                        SL.idpair(SL.ru32(var + 12), SL.ru32(var + 8)))
                    emit(DIM, kp .. "amount", SL.num(amt / 100000))
                end
            end
        end
    end
    emit(DIM, pfx .. "allow_zero_entries", SL.yn(az))
end

-- contract_definition 216B 本体 (writer sub_140DF1EC0)
-- gs = CGameState (tag 串表 gs+0x358); DP 末点已含
-- 写序 = contract_draft (seller→buyer→equipments→speed→subsidies)
--        → price_levels (空表不发叶) → prices
function SL.def_emit(emit, DIM, DP, base, gs)
    local function E(p, v) if v ~= nil then emit(DIM, p, v) end end
    local tt = gs and SL.rp(gs + 0x358) or nil
    local function tagq(tid)
        if not (tid and tid > 0 and SL.kptr(tt)) then return nil end
        local s = hoi4.read_str(tt + 32 * tid)
        if not s or s == "" or s == "---" then return nil end
        return SL.Q(s)
    end
    local RP = DP .. "contract_draft."
    E(RP .. "seller", tagq(SL.ru32(base + 88)))
    E(RP .. "buyer", tagq(SL.ru32(base + 92)))
    SL.pool_emit(emit, DIM, RP .. "equipments.", base + 96)
    E(RP .. "speed", tostring(SL.ru32(base + 192) or 0))
    -- draft.subsidies (48B 元, writer 0x140DDD510) 仅 count>0
    local sd, sc = SL.rp(base + 168), SL.ru32(base + 180)
    if SL.kptr(sd) and sc and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
        for k = 0, sc - 1 do
            local e = sd + 48 * k
            local kp = RP .. "subsidies.subsidies.#" .. (k + 1) .. "."
            E(kp .. "cic", SL.num((SL.rp_i64(e) or 0) / 100000))
            local ap = SL.rp(e + 8)
            if SL.kptr(ap) then
                local nm = SL.tok(SL.ru32(ap + 8))
                if nm then E(kp .. "archetype", tostring(nm)) end
            end
            if (SL.ru8(e + 40) or 0) == 0 then
                local td, tc = SL.rp(e + 16), SL.ru32(e + 28)
                if SL.kptr(td) and tc and tc > 0
                    and tc < GAME.layout.lim.PTR_SANE then
                    for j = 0, tc - 1 do
                        local tg = tagq(SL.ru32(td + 4 * j))
                        if tg then E(kp .. "targets.#" .. (j + 1), tg) end
                    end
                end
            end
        end
    end
    SL.pool_emit(emit, DIM, DP .. "prices.", base + 24)
end
