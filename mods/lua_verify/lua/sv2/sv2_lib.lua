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
