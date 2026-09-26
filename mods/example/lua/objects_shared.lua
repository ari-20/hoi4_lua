-- objects_shared.lua -- 对象层共享基座 (拆自 objects_v2.lua §0-§2 + 跨域助手)
-- 加载序: hoi4_layout -> resource -> objects_shared -> objects_<域> -> objects_v2(入口)
-- (objects_v2.lua 为汇总入口, 末尾挂 GAME.objects* 契约位)
--
-- 本文件持**跨域共享**符号: 读原语/卫语句/Runtime 全局根/Country 代理 + 少数
-- 被多个域文件引用的助手 (officer_records / cont_elems / tok / tokname_of /
-- date_from_hours_raw / sid_map2)。域私有助手留在各域文件内。
-- ⚠ 偏移与 vtable RVA 权威来源 = hoi4_layout (M.vt/M.off/M.const/M.lim),
-- 本文件不自持布局知识; 结构语义详见书 hoi4_runtime_classes.md 对应 §。
-- ⚠ 为何单列: Lua local 有词法作用域, 跨文件引用必须经此共享层
-- (拆前单文件内 884 处引 O / 370 处引 U, 直接切文件会全部失效)。
--
-- 世代守卫 (对象层重挂载; 书 §0.2 对象层文件布局):
-- 世代判据 = GAME.layout 表身份 — hoi4_layout 每代重建该表 (GAME.layout = M),
-- 故 prev.LAYOUT == GAME.layout ⟺ prev 属本代 → 复用返回, 不重建。
-- 无守卫的代价: DLL 扫描 + 域文件自举 + objects_v2 兜底使本文件每代被执行
-- 2~3 次, 只有最后一份能接上全部域方法, 其余整表成垃圾; 且域文件先于本次
-- 建层时挂的方法会挂在上一代表上 (静默丢失)。
-- ⚠ 改本文件后 touch 任一被 watch 的 lua 触发整代重载; 单文件 dofile 不构成
-- 完整重挂载 (契约位 GAME.objects* 由 objects_v2 挂)。

GAME = GAME or {}

local _prev = GAME.objects_shared
if _prev and _prev.LAYOUT and _prev.LAYOUT == GAME.layout then
    return _prev
end

local LAYOUT = GAME.layout
local BASE = hoi4.base()
-- rp 命名沿历史惯例 (书 §3.7): 读 64 位原值, 指针/整数/fixed 共用; 引擎侧
-- 已带符号重解释 (高位 1 → 负值), 故 i64 族无需补符号。窄读 ru32/ru8 为零扩展。
local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8

-- §0 原语
-- ============================================================
local U = {}
function U.a64(a) return a and a >= 0x10000 and a < 0x7FF000000000 and rp(a) or nil end
function U.a32(a) return a and a ~= 0 and ru32(a) or nil end
function U.a8(a) return a and a ~= 0 and ru8(a) or nil end
function U.i8(a)                       -- 带符号字节 (唯一实现 = hoi4_layout.i8)
  return LAYOUT.i8(a)
end
function U.i16(a) return LAYOUT.i16(a) end
function U.i32(a) return LAYOUT.i32(a) end
function U.fix5(a)                     -- §3.7 fixed×1e-5 定点 → 浮点
  local v = LAYOUT.i64(a)
  if not v then return nil end
  -- ⚠ 必须 /100000 (legacy fp5 L3600), 不能 *1e-5 —
  -- 1ulp 差会破 _n0 的整值判定 (ai.pp_spend_amount 25 → "25.00000" 实证)
  return v / 100000
end
function U.sso(obj)                    -- §3.5 MSVC SSO 串 {buf@0, size@0x10, cap@0x18}
  if not obj or obj < 0x10000 then return nil end
  local size = ru32(obj + 0x10)
  if not size or size > 4096 then return nil end
  if size == 0 then return "" end
  -- 内联判据 = cap (MSVC: cap>15 即堆模式, 即使 size≤15 — 串缩短后
  -- 堆缓冲保留; §3.5)
  local cap = ru32(obj + 0x18)
  local buf = (cap and cap > 15) and rp(obj) or obj
  if not buf or buf < 0x10000 then return nil end
  local chars = {}
  for i = 0, size - 1 do
    local c = ru32(buf + i)
    if not c then return nil end
    chars[#chars + 1] = string.char(c & 0xFF)
  end
  return table.concat(chars)
end
function U.cstr(p)                     -- C 串 (读到 \0)
  if not p or p < 0x10000 then return nil end
  return hoi4.read_str(p)
end
function U.date(h)                     -- §3.7b CGameDate 总小时 → "Y.M.D.H"
  -- 唯一实现 = hoi4_layout (A 族: 滤 {0,-1.1.1.1,43808760} + 年<1 弃)
  return LAYOUT.date(h, 1)
end

-- legacy 建筑名硬编码表已废 : 建筑名 = lexer token_name 直解
-- (CBuildingDatabase 0x3316A58, staticres §2) + token_name 兜底

local O = {}
function O.kptr(v) return v and v >= 0x10000 and v < 0x7FF000000000 end
function O.vt(addr, rva)
  return O.kptr(addr) and rp(addr) == (BASE + rva)
end

-- 容器遍历: 统一入口 → 委派 LAYOUT.vec (唯一实现)
-- vc(base, doff, coff) → 迭代器 (i, elem_addr 或 elem 基址)
-- 上界保持历史值 65536 (原判据 c > 65536 拒, 即 c <= 65536 收 → max 同值)。
function O.vec(base, doff, coff, stride, deref)
  return LAYOUT.vec(base, doff, stride,
                     { count = coff, deref = deref, max = LAYOUT.lim.PTR_HUGE })
end

-- ============================================================
-- §1 全局根
-- ============================================================
local Runtime = {}
Runtime.gs = function()                -- §1.1 CGameState 单例 @BASE+0x332F260
  local g = rp(BASE + 0x332F260)
  return O.kptr(g) and g or nil
end
Runtime.tagTable = function(self)      -- §1.1 CGameState +856 (0x358) tag 串表
  local g = self.gs()
  return g and rp(g + 0x358) or nil
end
-- tag 表条目数 = 合法 tag id 的上界 (count@gs+868; 书 §4.1/§4.18)。
-- ⚠ 勿用 countryCount 当界: tag 表按动态槽分配, count 可 > 国家数 → 尾部 tag 静默判非法。
function Runtime.tagCount(self)
  local g = self.gs()
  return g and ru32(g + 0x364) or nil
end
-- tag id 合法性上界 (防越界读; 取 tag 表 count, 退回 countryCount)
function Runtime.tagUpperBound(self)
  local n = self:tagCount()
  if not n or n <= 32 or n >= 4096 then n = self.R:countryCount() end
  if not n or n <= 32 or n >= 4096 then n = 1024 end
  return n
end
Runtime.tag = function(self, tid)      -- §1.1 CGameState tag 串 (串表+32*tid C 串)
  local tt = self:tagTable()
  if not tt or not tid or tid == 0 then return nil end
  return U.cstr(tt + 32 * tid)
end
Runtime.tagId = function(self, tag)    -- §1.1 CGameState tag 串表反查 (三字串 → tag id)
  local tt = self:tagTable()
  if not tt or not tag then return nil end
  for i = 0, 1000 do
    if U.cstr(tt + 32 * i) == tag then return i end
  end
  return nil
end
Runtime.countryCount = function(self)  -- §1.1 CGameState +796 (0x31C) 国家数
  local g = self.gs()
  return g and ru32(g + 0x31C) or 0
end

Runtime.provinces = function(self)     -- §1.2 CGameState +688 (0x2B0) 省指针数组
  local g = self.gs()
  if not g then return nil, 0 end
  -- count@gs+0x2BC = 省表界 (=CMap+560=省表 null 终止)
  return rp(g + 0x2B0), ru32(g + 0x2BC) or 0
end
Runtime.states = function(self)        -- §1.2 CGameState +712 (0x2C8) 州表
  local g = self.gs()
  if not g then return nil, 0 end
  -- count@gs+0x2D4 = 州库条目数 (states writer 循环界; 旧 0x2BC 系省数
  -- 误用, 勘误 — 虚大量级仅作防御上界未爆雷)
  return rp(g + 0x2C8), ru32(g + 0x2D4) or 0
end

-- ============================================================
-- §2 Country (国家代理; 偏移表见 hoi4_runtime_classes.md §4.3 CCountry)
-- ============================================================
local Country, DeploymentMT = {}, {}
Country.__index = function(self, k)
  -- 延迟解析子系统 (方法表), 保持对象轻量
  local v = Country[k]
  if v then
    if type(v) == "function" then return v end
    return v
  end
  return nil
end
Runtime.country = function(self, idx)  -- §1.1 CGameState +784 (0x310) 国家指针数组 → §4.3 CCountry
  local g = self.gs()
  if not g then return nil end
  local arr = rp(g + 0x310)
  local cc = arr and rp(arr + 8 * (idx or 0))
  if not O.kptr(cc) then return nil end
  return setmetatable({ addr = cc, idx = idx or 0, R = self }, Country)
end
Runtime.countryByTag = function(self, tag)
  local tid = self:tagId(tag)
  return tid and self:country(tid) or nil
end
Country.tag = function(self)
  return self.R:tag(self.idx)
end



-- 国家子系统偏移表 (全部已验证; 语义详见书 §4.3.1 CCountry 字段布局)
Country.SUBSYS = {
  technology   = 3936,   -- §4.7 CTechnologyStatus
  deployment   = 3952,   -- §4.18 CDeployment
  variables    = 536,    -- §4.13.2 CVariables (scripted_gui_random @+0x220)
  tech_arr     = 3936,
}

-- ------------------------------------------------------------
-- 2.1 科技 §4.7 CTechnologyStatus (cc+3936; writer 0x140ECFFF0 族)
-- ------------------------------------------------------------
Country.technology = function(self)
  local ts = rp(self.addr + 3936)
  if not O.vt(ts, GAME.layout.vt.CTechnologyStatus) then return nil end
  local out = { addr = ts,
    next_bonus_id = ru32(ts + 316),
    override_icons_tag = nil }
  local oit = ru32(ts + 312)
  if oit and oit > 0 then out.override_icons_tag = self.R:tag(oit) end
  -- technologies 全量容器; 导出过滤门 (四条件或) = 书 §4.7
  out.technologies = {}
  local td, tc = rp(ts + 136), ru32(ts + 148)
  if O.kptr(td) and tc and tc > 0 and tc < 4096 then
    for i = 0, tc - 1 do
      local t = rp(td + 8 * i)
      if O.kptr(t) then
        local lv = ru32(t + 372) or 0
        local rpv = U.fix5(t + 408) or 0
        local bnv = rp(t + 456) or 0
        local wr = lv > 0 or (rp(t + 408) or 0) > 0
            or (ru32(t + 476) or 0) ~= 0
        if not wr then
          local tpl = rp(t + 352)
          local mx = O.kptr(tpl) and ru32(tpl + 988) or 0
          if mx and lv < mx then
            local sd, sc = rp(ts + 160), ru32(ts + 172)
            if O.kptr(sd) and sc and sc > 0 and sc < 64 then
              for si = 0, sc - 1 do
                local sp = rp(sd + 8 * si)
                if O.kptr(sp) and rp(sp + 24) == t then
                  wr = true break end
              end
            end
          end
        end
        if wr then
          local rec = {
            name = LAYOUT.token_name(ru32(t + 8)),
            level = lv, research_points = rpv,
          }
          -- date hours @+384 (§3.7b CGameDate@+392 前置)
          rec.date = U.date(ru32(t + 384))
          -- §3.6 id 对 design_team @+492 {type lo, id hi}
          local dt1, dt2 = ru32(t + 492), ru32(t + 496)
          if (dt1 and dt1 ~= 0) or (dt2 and dt2 ~= 0) then
            rec.design_team = string.format("id=%d type=%d", dt2 or 0, dt1 or 0)
          end
          local d1 = rp(t + 416); if d1 and d1 ~= 0 then
            rec.design_team_bonus = d1 / 100000 end
          local d2 = rp(t + 424); if d2 and d2 ~= 0 then
            rec.rp_from_design_team = d2 / 100000 end
          local d3 = rp(t + 448); if d3 and d3 ~= 0 then
            rec.ahead_reduction = d3 / 100000 end
          rec.bonus = (bnv ~= 0) and bnv / 100000 or nil
          -- tech 级 limited_use_bonus.uses 裸数组 {d@464, c@476}
          local ud, uc = rp(t + 464), ru32(t + 476)
          if O.kptr(ud) and uc and uc > 0 and uc < 64 then
            rec.lub_uses = {}
            for u2 = 0, uc - 1 do
              rec.lub_uses[#rec.lub_uses + 1] = ru32(ud + 4 * u2) or 0
            end
          end
          out.technologies[#out.technologies + 1] = rec
        end
      end
    end
  end
  return out
end

-- ------------------------------------------------------------
-- 2.1b technology_status (§4.7 CTechnologyStatus) — legacy 全形态移植, 补齐
-- Country.technology 缺的 technologies.list/slots/limited_use_bonus.list/cost_reduction.list 键 (缺则发射端对应段零发射)
-- ------------------------------------------------------------
Country.technology_status = function(self)
  local ts = rp(self.addr + 3936)
  if not O.vt(ts, GAME.layout.vt.CTechnologyStatus) then return nil end
  local out = { addr = ts }
  out.next_bonus_id = ru32(ts + 316)
  local oit = ru32(ts + 312)
  if oit and oit > 0 then out.override_icons_tag = self.R:tag(oit) end
  -- technologies (过滤后 = 存档条目): {total_in_container, list}
  out.technologies = { total_in_container = ru32(ts + 148) or 0, list = {} }
  local td, tc = rp(ts + 136), ru32(ts + 148)
  if O.kptr(td) and tc and tc > 0 and tc < 4096 then
    for i = 0, tc - 1 do
      local t = rp(td + 8 * i)
      if O.kptr(t) then
        local lv = ru32(t + 372) or 0
        local rpv = U.fix5(t + 408) or 0
        local bnv = rp(t + 456) or 0
        if lv > 0 or rpv ~= 0 or bnv ~= 0 then
          local rec = {
            name = LAYOUT.token_name(ru32(t + 8)),
            level = lv, research_points = rpv, _addr = t,
          }
          rec.date = U.date(ru32(t + 384))
          local dt1, dt2 = ru32(t + 492), ru32(t + 496)
          if (dt1 and dt1 ~= 0) or (dt2 and dt2 ~= 0) then
            rec.design_team = string.format("id=%d type=%d", dt2 or 0, dt1 or 0)
          end
          local b416 = rp(t + 416)
          if b416 and b416 ~= 0 then rec.design_team_bonus = b416 / 100000 end
          local b424 = rp(t + 424)
          if b424 and b424 ~= 0 then rec.rp_from_design_team = b424 / 100000 end
          local b448 = rp(t + 448)
          if b448 and b448 ~= 0 then rec.ahead_reduction = b448 / 100000 end
          local b456 = rp(t + 456)
          if b456 and b456 ~= 0 then rec.bonus = b456 / 100000 end
          -- tech 级 lub.uses 裸数组 {d@t+464, c@t+476}
          local ud, uc = rp(t + 464), ru32(t + 476)
          if O.kptr(ud) and uc and uc > 0 and uc < 64 then
            rec.lub_uses = {}
            for u2 = 0, uc - 1 do
              rec.lub_uses[#rec.lub_uses + 1] = ru32(ud + 4 * u2) or 0
            end
          end
          -- (RPM): research_points_per_mio std::map @t+432 (§3.3 红黑树)
          -- (head=rp(t+432), isnil b@node+25, key token@+0x20,
          -- value ×1e-5@+0x28; 中序 = 存档序; legacy L8467-L8509)
          local mhead = rp(t + 432)
          if O.kptr(mhead) then
            local node = rp(mhead)
            local mlist = {}
            local guard = 0
            local isnilb = function(p)
              return not p or ((ru32(p + 25) & 0xFF) ~= 0)
            end
            while node and not isnilb(node) and guard < 64 do
              guard = guard + 1
              mlist[#mlist + 1] = {
                org = LAYOUT.token_name(ru32(node + 0x20)),
                points = U.fix5(node + 0x28) or 0,
              }
              local r = rp(node + 16)
              if r and not isnilb(r) then
                node = r
                while true do
                  local l = rp(node)
                  if l and not isnilb(l) then node = l else break end
                end
              else
                while true do
                  local p = rp(node + 8)
                  if not p or isnilb(p) then node = nil break end
                  local pr = rp(p + 16)
                  local from_right = (pr == node)
                  node = p
                  if not from_right then break end
                end
              end
            end
            if #mlist > 0 then rec.mio_points = mlist end
          end
          out.technologies.list[#out.technologies.list + 1] = rec
        end
      end
    end
  end
  -- slots {d@160, c@172} (§4.7.2 CResearchSlot; legacy L8523-L8538)
  out.slots = {}
  local sd, sc = rp(ts + 160), ru32(ts + 172)
  if O.kptr(sd) and sc and sc > 0 and sc < 64 then
    for i = 0, sc - 1 do
      local s = rp(sd + 8 * i)
      if O.kptr(s) then
        local usp = U.fix5(s + 0x28)
        out.slots[#out.slots + 1] = {
          name = LAYOUT.token_name(ru32(s + 8)),
          points_factor = U.fix5(s + 56),
          used_saved_points = (usp and usp ~= 0) and usp or nil,
          researching = O.kptr(rp(s + 24)),
        }
      end
    end
  end
  -- limited_use_bonus {d@232, c@244} (§4.7.3 CLimitedUseTechBonus; legacy L8540-L8587)
  out.limited_use_bonus = { count = ru32(ts + 244) or 0, list = {} }
  local bd, bc = rp(ts + 232), ru32(ts + 244)
  if O.kptr(bd) and bc and bc > 0 and bc < 4096 then  -- 上界 4096: 实测条目可 >64, 勿收紧 (§4.7.3)
    for i = 0, bc - 1 do
      local e = rp(bd + 8 * i)
      if O.kptr(e) then
        local rec2 = {
          bonus = U.fix5(e + 112), uses = ru32(e + 8),
          id = ru32(e + 48), name = hoi4.read_str(e + 16),
          claim = ru32(e + 12),
          ahead_reduction = U.fix5(e + 104),
        }
        local td6, tc6 = rp(e + 56), ru32(e + 68)
        local techs = {}
        if O.kptr(td6) and tc6 and tc6 > 0 and tc6 <= LAYOUT.lim.PTR_SANE then
          for i6 = 0, tc6 - 1 do
            local it6 = rp(td6 + 8 * i6)
            if O.kptr(it6) then
              techs[#techs + 1] = tostring(LAYOUT.token_name(ru32(it6 + 60)))
            end
          end
        end
        rec2.technologies = table.concat(techs, ",")
        local cd3, cc3 = rp(e + 80), ru32(e + 92)
        local cats = {}
        if O.kptr(cd3) and cc3 and cc3 > 0 and cc3 <= LAYOUT.lim.PTR_SANE then
          for i3 = 0, cc3 - 1 do
            local it3 = rp(cd3 + 8 * i3)
            if O.kptr(it3) then
              cats[#cats + 1] = tostring(LAYOUT.token_name(ru32(it3 + 44)))
            end
          end
        end
        rec2.category = table.concat(cats, ",")
        out.limited_use_bonus.list[#out.limited_use_bonus.list + 1] = rec2
      end
    end
  end
  -- cost_reduction {d@256, c@268} (§4.7.4 CLimitedUseTechCostReduction; legacy L8589-L8610)
  out.cost_reduction = { count = ru32(ts + 268) or 0, list = {} }
  local cd2, cc2 = rp(ts + 256), ru32(ts + 268)
  if O.kptr(cd2) and cc2 and cc2 > 0 and cc2 < 32 then
    for i = 0, cc2 - 1 do
      local e = rp(cd2 + 8 * i)
      if O.kptr(e) then
        local cats7 = {}
        local cd7, cc7 = rp(e + 88), ru32(e + 100)
        if O.kptr(cd7) and cc7 and cc7 > 0 and cc7 < 16 then
          for i7 = 0, cc7 - 1 do
            local it7 = rp(cd7 + 8 * i7)
            if O.kptr(it7) then
              cats7[#cats7 + 1] = tostring(LAYOUT.token_name(ru32(it7 + 44)))
            end
          end
        end
        out.cost_reduction.list[#out.cost_reduction.list + 1] = {
          cost_reduction = U.fix5(e + 8), uses = ru32(e + 40),
          name = hoi4.read_str(e + 48), id = ru32(e + 80),
          category = table.concat(cats7, ","),
        }
      end
    end
  end
  return out
end

-- ------------------------------------------------------------
-- 2.2 部署 §4.18 CDeployment (cc+3952)
-- ------------------------------------------------------------
Country.deployment = function(self)
  local dep = rp(self.addr + 3952)
  if not O.kptr(dep) then return nil end
  return setmetatable({ addr = dep, R = self.R }, DeploymentMT)
end


-- ============================================================

-- ============================================================
-- 导出 (供 objects_v2 入口与各域文件取用)
-- ============================================================
local M = {}
M.LAYOUT, M.BASE = LAYOUT, BASE
M.rp, M.ru32, M.ru8 = rp, ru32, ru8
M.U, M.O = U, O
M.Runtime, M.Country = Runtime, Country
M.vt, M.const, M.lim, M.dim = LAYOUT.vt, LAYOUT.const, LAYOUT.lim, LAYOUT.dim
M.off = LAYOUT.off

-- 跨域助手: token 名
local function tok(p) return LAYOUT.token_name(p) end
M.tok = tok

-- ============================================================
-- §3 装备市场结构读取 (唯一实现; 布局知识引 LAYOUT.off, 段层只消费)
-- 书 §4.23.3 NInternationalMarket / CPurchaseContract / CEquipmentVariantPool
-- ============================================================

-- CEquipmentVariantPool 序列化源 (pool2) 读取 — §4.23.3
-- P = 池基址 → { allow_zero = u8 原值, list = { {type, id, amount} } }
-- 元素级跳过规则复刻 writer: amount(raw i64)≠0 或 allow_zero≠0 才收。
-- opts.max   = 计数上界 (n >= max 即整体弃, 默认不设 → 无上界)
-- opts.clamp = 循环钳位 (池1 空判族用, 与 max 的"拒绝"语义不同)
function U.pool_read(P, opts)
    if not O.kptr(P) then return nil end
    opts = opts or {}
    local o = LAYOUT.off.variant_pool
    local az = ru8(P + o.allow_zero) or 0
    local out = { allow_zero = az, list = {} }
    local d, n = rp(P + o.data), ru32(P + o.count)
    if not (O.kptr(d) and n and n > 0) then return out end
    if opts.max and n >= opts.max then return out end
    local cnt = n
    if opts.clamp then cnt = math.min(cnt, opts.clamp) end
    for i = 0, cnt - 1 do
        local e = d + o.stride * i
        local amt = LAYOUT.i64(e + o.amount) or 0
        if amt ~= 0 or az ~= 0 then
            local var = rp(e)
            if O.kptr(var) then
                out.list[#out.list + 1] = {
                    type = ru32(var + 8), id = ru32(var + 12),
                    amount = amt,
                }
            end
        end
    end
    return out
end

-- 池"整块空判" (§4.23.3 writer 0x140FFB8F0): pool1 全零 ⇒ 空
-- combat 族 (combat_side_data / combat_data) 用此门决定是否出整块
function U.pool_empty(P)
    if not O.kptr(P) then return true end
    local o = LAYOUT.off.variant_pool
    local n = ru32(P + o.pool1_count) or 0
    if n <= 0 then return true end
    local d = rp(P + o.pool1_data)
    if not O.kptr(d) then return true end
    for i = 0, math.min(n, LAYOUT.lim.PTR_SANE) - 1 do
        if (rp(d + o.pool1_stride * i + o.pool1_amount) or 0) ~= 0 then
            return false
        end
    end
    return true
end

-- contract_draft.subsidies / 国级市场 subsidies 条读取 (48B, 唯一实现)
-- §4.23.3 (writer sub_140DDD510); data/count 由调用方给 (两处容器偏移不同)
-- → { {cic, archetype?, targets?} } (branch 0 → targets tag 串列表)
function U.subsidy_list_read(data, count, R)
    local out = {}
    if not (O.kptr(data) and count and count > 0
            and count < LAYOUT.lim.PTR_SANE) then
        return out
    end
    local se = LAYOUT.off.subsidy_entry
    local function tagq(tid)
        if not (tid and tid > 0) then return nil end
        local s = R and R:tag(tid) or nil
        if not s or s == "" or s == "---" then return nil end
        return s
    end
    for k = 0, count - 1 do
        local e = data + se.stride * k
        local rec = { cic = (LAYOUT.i64(e) or 0) / 100000 }
        local ap = rp(e + se.archetype)
        if O.kptr(ap) then rec.archetype = LAYOUT.token_name(ru32(ap + 8)) end
        local br = ru8(e + se.branch) or 0
        if br == 0 then
            local td = rp(e + se.targets)
            local tc = ru32(e + se.targets + 12)
            if O.kptr(td) and tc and tc > 0 and tc < LAYOUT.lim.PTR_SANE then
                rec.targets = {}
                for j = 0, tc - 1 do
                    local t = tagq(ru32(td + 4 * j))
                    if t then rec.targets[#rec.targets + 1] = t end
                end
            end
        elseif br == 1 then
            -- trigger 脚本分支: v16 = *(e+16) (sub_14139D960
            -- HasTriggerCondition 断言), MSVC 串 @v16+96
            local tp = rp(e + se.targets)
            if O.kptr(tp) then
                local ts = U.sso(tp + 96)
                if ts and ts ~= "" then rec.trigger = ts end
            end
        end
        out[#out + 1] = rec
    end
    return out
end

-- contract_definition 216B 读取 — §4.23.3 (writer sub_140DF1EC0)
-- def = def 本体起点 (合同 c+24 / requests 元素 req+24 / 动作 act+120)
-- R = Runtime (tag_id → 三字串); 返回 nil 当 def 非指针
-- 写序 (段层按此发射): contract_draft (seller→buyer→equipments→speed→
-- subsidies) → price_levels → prices
function U.contract_def_read(def, R)
    if not O.kptr(def) then return nil end
    local o = LAYOUT.off.contract_def
    local function tagq(tid)
        if not (tid and tid > 0) then return nil end
        local s = R and R:tag(tid) or nil
        if not s or s == "" or s == "---" then return nil end
        return s
    end
    return {
        seller     = tagq(ru32(def + o.seller)),
        buyer      = tagq(ru32(def + o.buyer)),
        equipments = U.pool_read(def + o.equipments,
                                 { max = LAYOUT.lim.PTR_HUGE }),
        speed      = ru32(def + o.speed) or 0,
        subsidies  = U.subsidy_list_read(rp(def + o.subsidies),
                                         ru32(def + o.subsidies + 12), R),
        prices     = U.pool_read(def + o.prices,
                                 { max = LAYOUT.lim.PTR_HUGE }),
    }
end

-- CPurchaseRequest 读取 (~240B: CReferenceObject 头 + def@+24) — §4.23.3
-- 返回 def_addr (段层发射需原址) + def (解析结果)
function U.purchase_request_read(req, R)
    if not O.kptr(req) then return nil end
    local o = LAYOUT.off.purchase_request
    local da = req + o.def
    return {
        addr = req, def_addr = da,
        id_type = ru32(req + o.id_type), id_id = ru32(req + o.id_id),
        def = U.contract_def_read(da, R),
    }
end

-- CPurchaseContract 读取 (808B; id 对@+8/+12 + def@+24) — §4.23.3
function U.purchase_contract_read(c, R)
    if not O.kptr(c) then return nil end
    local o = LAYOUT.off.purchase_request
    local da = c + o.def
    return {
        addr = c, def_addr = da,
        id_type = ru32(c + o.id_type), id_id = ru32(c + o.id_id),
        def = U.contract_def_read(da, R),
    }
end

-- §4.23.3 NInternationalMarket (gs+1000) 读取 — 全局装备市场
-- → { addr, contracts = { {addr,id_type,id_id,def} },
--      request_slots = 槽数, requests = { {index, list={req 记录}} } }
-- requests 槽 i 归属国 i-1 (idx0 哨兵); 仅 icount≠0 槽入 requests
function Runtime.equipment_market(self)
    local g = self.gs()
    if not g then return nil end
    local mkt = rp(g + 1000)
    if not O.kptr(mkt) then return nil end
    local o = LAYOUT.off.market
    local out = { addr = mkt, contracts = {}, requests = {} }
    local cd = rp(mkt + o.contracts)
    local cc = ru32(mkt + o.contracts + 12)
    if O.kptr(cd) and cc and cc > 0 and cc < LAYOUT.lim.PTR_SANE then
        for i = 0, cc - 1 do
            local rec = U.purchase_contract_read(rp(cd + 8 * i), self)
            if rec then out.contracts[#out.contracts + 1] = rec end
        end
    end
    local rd = rp(mkt + o.requests)
    local rc = ru32(mkt + o.requests_count)
    if O.kptr(rd) and rc and rc > 0 and rc < LAYOUT.lim.PTR_HUGE then
        out.request_slots = rc
        for i = 0, rc - 1 do
            local s = rd + o.req_slot_stride * i
            local idata = rp(s + o.req_slot_data)
            local icount = ru32(s + o.req_slot_count)
            if O.kptr(idata) and icount and icount > 0
                and icount < LAYOUT.lim.PTR_SANE then
                local slot = { index = i, list = {} }
                for j = 0, icount - 1 do
                    local rec = U.purchase_request_read(
                        rp(idata + 8 * j), self)
                    if rec then slot.list[#slot.list + 1] = rec end
                end
                out.requests[#out.requests + 1] = slot
            end
        end
    end
    return out
end

-- 段层/域层消费入口 (R 自动传入; 段文件经 ctx.O 取用)
function Runtime.pool_read(self, P, opts) return U.pool_read(P, opts) end
function Runtime.pool_empty(self, P) return U.pool_empty(P) end
function Runtime.contract_def_read(self, def)
    return U.contract_def_read(def, self)
end
function Runtime.purchase_request_read(self, r)
    return U.purchase_request_read(r, self)
end
function Runtime.purchase_contract_read(self, c)
    return U.purchase_contract_read(c, self)
end

local function date_from_hours_raw(h) return LAYOUT.date_raw(h) end
M.date_from_hours_raw = date_from_hours_raw

-- 跨域助手: 容器元素收集 (§3.1 vector, count@+0xC; 校验元素虚表;
-- 空军族 §13 / 战略空军深层 §31) → 委派 LAYOUT (唯一实现)
-- 上界保持历史判据 c < 65536 (即 max = 65535; 与 O.vec 的 <= 65536 差一,
-- 系历史写法不一致, 此处照原样钉住)。
local function cont_elems(base, off, vtrva)
  return LAYOUT.gather(LAYOUT.vec(base, off, 8,
                                  { count = off + 12, vt = vtrva, deref = true,
                                    max = LAYOUT.lim.PTR_HUGE - 1 }))
end
M.cont_elems = cont_elems

-- 跨域助手: 州指针 -> state_id 映射 → 委派 LAYOUT.state_index_map (唯一实现,
-- 含强制代际戳; 原本地实现**永不失效**, 换档后州表搬家即得悬垂错映射)。
local function sid_map2(g)
  return LAYOUT.state_index_map(g)
end
M.sid_map2 = sid_map2

-- 跨域助手: 对象 token (+8) -> 名 (token_name lexer, 书 §4.26.2)
local function tokname_of(p)
  local o = rp(p)
  if not O.kptr(o) then return nil end
  return LAYOUT.token_name(ru32(o + 8)) or tostring(ru32(o + 8))
end
M.tokname_of = tokname_of

-- 跨域助手: 军官记录族 (陆军 §6 / 舰队 §7; 书 §4.18 officer 88B 记录
-- + CCharacterPortraits; ship 侧同构 §4.16)
local OFFICER_PORTRAIT_BRANCH = { [0] = "civilian", "army", "navy", "air",
    "operative", "scientist" }
local OFFICER_PORTRAIT_SIZE = { [0] = "small", "large" }
local function officer_record_read(e)
    local r = { seed = ru32(e + 8) }
    r.male = (((ru32(e + 80) or 0) & 0xFF) == 1) and "yes" or "no"
    local nm = U.sso(e + 16)
    if nm and #nm > 0 then r.name = nm end
    local pd, pc = rp(e + 56), ru32(e + 68)
    if O.kptr(pd) and pc and pc > 0 and pc <= 16 then
        local lst = {}
        for i = 0, pc - 1 do
            local pe = pd + 56 * i
            local gate, psz = ru32(pe + 12), ru32(pe + 32)
            if gate and gate <= 1 and psz and psz > 0 and psz < 4096 then
                local pp = (psz > 15) and rp(pe + 16) or (pe + 16)
                local pth = O.kptr(pp) and hoi4.read_cstr(pp) or nil
                if pth and #pth > 0 then
                    lst[#lst + 1] = {
                        branch = OFFICER_PORTRAIT_BRANCH[ru32(pe)] or "army",
                        size = OFFICER_PORTRAIT_SIZE[ru32(pe + 4)] or "small",
                        path = pth }
                end
            end
        end
        if #lst > 0 then r.portraits = lst end
    end
    return r
end
local function officer_records(inline, vd, vc)
    local out = { officer_record_read(inline) }
    if O.kptr(vd) and vc and vc > 0 and vc <= LAYOUT.lim.PTR_SANE then
        for i = 0, vc - 1 do
            out[#out + 1] = officer_record_read(vd + 88 * i)
        end
    end
    return out
end
M.officer_record_read = officer_record_read
M.officer_records = officer_records
M.OFFICER_PORTRAIT_BRANCH = OFFICER_PORTRAIT_BRANCH
M.OFFICER_PORTRAIT_SIZE = OFFICER_PORTRAIT_SIZE

-- 自注册 (域文件与入口按 GAME.objects_shared 取用; 世代守卫见文件头注)
GAME.objects_shared = M

-- §4.13.3 country flags 导出全量 reader (cc+0x230 CFlagStore; 48B 条;
-- 与 global flags 同构; 键 = SL.tok 同形 token 失效落数值)
function Country.flags_list(self)
  local cc = self.addr
  if not cc then return nil end
  local store = rp(cc + 0x230)
  if not O.kptr(store) then return nil end
  local d, cnt = rp(store + 8), ru32(store + 0x14)
  if not O.kptr(d) or not cnt or cnt <= 0 or cnt > 100000 then return nil end
  local maxtok = hoi4.read_u32(hoi4.base()
      + GAME.layout.rva.lexer_token_max) or 100000
  local out = {}
  for i = 0, cnt - 1 do
    local e = d + 0x30 * i
    local key = ru32(e + 8)
    local nm = key and key <= maxtok
        and (GAME.layout.token_name(key) or key)
    if nm and nm ~= "" then
      local pack = ru32(e + 0x28) or 0
      local v = pack & 0xFFFF
      v = LAYOUT.as_i16(v)
      local dh = ru32(e + 0x18)
      local ex = (pack >> 16) & 0x7FFF
      out[#out + 1] = { name = tostring(nm), value = v,
        date_h = (dh and dh > 0) and dh or nil,
        days = (ex > 0) and ex or nil }
    end
  end
  return out
end

return M
