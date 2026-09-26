-- objects_manager.lua -- 全局管理器代理族 (§32; 自 objects_global 拆分)
-- 结构语义详见书: §4.20 天气 CWeatherManager / §4.21 补给 CSupplySystem /
-- §4.23.1 装备变体 CEquipmentVariant / §4.18.6 编制模板
-- CReferencedDivisionTemplate / §4.14.7 铁路 CRailwayManager /
-- §4.5 阵营 CFactionSystem (faction_pool)。
-- 模式: gs 单例指针槽定位全局管理器 → 指针数组/内联数组扫描 →
-- setmetatable 代理表惰性字段访问 (每次访问重校验 vtable, 悬垂防护)。
-- 共享层惰性获取 (DLL 字母序下 objects_shared 晚于本文件加载)。
-- 世代判据 (§0.2 对象层文件布局) = GAME.layout 表身份: hoi4_layout 每代
-- 重建该表, 故 SH.LAYOUT == GAME.layout ⟺ 本代层已建 → 直接复用;
-- 缺失/过期则自举重建 (hot reload 改 objects_shared 也走这条重建路)。
local SH = GAME.objects_shared
if not SH or not SH.LAYOUT or SH.LAYOUT ~= GAME.layout then
    local _src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local _sep = string.char(92)          -- 反斜杠 (避开转义)
    local _pat = "^@(.-)[/" .. _sep .. "][^/" .. _sep .. "]*$"
    local _dir = _src:match(_pat) or MOD_LUA_DIR
    if _dir then
        pcall(dofile, _dir .. "/objects_shared.lua")
        SH = GAME.objects_shared
    end
end
if not SH then error("objects_shared 不可用 (检查加载路径)") end
local LAYOUT, BASE = SH.LAYOUT, SH.BASE
local U, O = SH.U, SH.O
local Runtime, Country = SH.Runtime, SH.Country
local rp, ru32, ru8 = SH.rp, SH.ru32, SH.ru8

-- ============================================================
-- §32 全局代理工厂族 (legacy Objects.weather / supply2 / equipments /
-- division_templates / rail_way / faction_pool 正式迁移)
-- 模式: gs 单例指针槽定位全局管理器 → 指针数组/内联数组扫描 →
-- setmetatable 代理表惰性字段访问 (每次访问重校验 vtable, 悬垂防护)
-- ============================================================
-- ============================================================
-- §32 全局代理工厂族 (legacy Objects.weather / supply2 / equipments /
-- division_templates / rail_way / faction_pool 正式迁移)
-- 模式: gs 单例指针槽定位全局管理器 → 指针数组/内联数组扫描 →
-- setmetatable 代理表惰性字段访问 (每次访问重校验 vtable, 悬垂防护)
-- ============================================================

-- ------------------------------------------------------------
-- 32.1 weather: CWeatherManager @gs+0x688 (§4.20.1; 省天气 §4.20.2
-- SWeatherPerProvince / 区天气 §4.20.3 SWeatherPerRegion;
-- 容器/内联元素/定点 = 书)
-- ------------------------------------------------------------
local G32_WX = { mgr = BASE + GAME.layout.vt.CWeatherManager,
  prov = BASE + GAME.layout.vt.CWeatherProvince }

local G32_WxProvMT, G32_WxRegionMT
local function G32_mk_wx_prov(a) return setmetatable({ _addr = a }, G32_WxProvMT) end
local function G32_mk_wx_reg(a) return setmetatable({ _addr = a }, G32_WxRegionMT) end

G32_WxProvMT = {
  __index = function(self, k)
    local a = self._addr
    if not O.kptr(a) or rp(a) ~= G32_WX.prov then return nil end
    if k == "province_id" then return ru32(a + 8) end
    if k == "temperature" then return U.fix5(a + 0x118) end
    if k == "temperature_offset" then return U.fix5(a + 0x128) end
    if k == "water" then return U.fix5(a + 0x38) end
    if k == "snow" then return U.fix5(a + 0x40) end
    if k == "mud" then return U.a8(a + 0x130) end
    if k == "custom_modifiers" then
      local d, n = rp(a + 0x148), ru32(a + 0x154)
      if not O.kptr(d) or not n or n > 16 then return nil end
      local t = {}
      for i = 0, n - 1 do
        local name_ptr = rp(d + 16 * i)
        t[#t + 1] = { name = O.kptr(name_ptr) and U.sso(name_ptr + 424) or nil,
          param = ru32(d + 16 * i + 8) }
      end
      return t
    end
    return nil
  end,
}

G32_WxRegionMT = {
  __index = function(self, k)
    local a = self._addr
    if not O.kptr(a) then return nil end
    if k == "region_id" then return ru32(a + 8) end
    if k == "temperature" then return U.fix5(a + 0x138) end
    if k == "rain_light" then return U.a8(a + 0x108) end
    if k == "rain_heavy" then return U.a8(a + 0x110) end
    if k == "snow" then return U.a8(a + 0x118) end
    if k == "blizzard" then return U.a8(a + 0x120) end
    if k == "sandstorm" then return U.a8(a + 0x128) end
    if k == "arctic_water" then return U.a8(a + 0x130) end
    if k == "next_weather_change_addr" then return rp(a + 0x158) end
    -- next_weather_change 恒写: hours u32@+0x150 (writer 0x140F0DDC0;
    -- SL.date 换算在段侧)
    if k == "next_weather_change" then return ru32(a + 0x150) end
    -- active_modifiers: u16 数组 {d@+0x30, cnt@+0x3C} — writer 尾段单匿名
    -- 元循环逐值 + 分隔补写 → 存档形态 = 单行 "v1 v2 ..." (段侧 concat)
    if k == "active_modifiers" then
      local d, n = rp(a + 0x30), ru32(a + 0x3C)
      if not O.kptr(d) or not n or n == 0
          or n >= LAYOUT.lim.PTR_SANE then return nil end
      local t = {}
      for i = 0, n - 1 do t[#t + 1] = hoi4.read_u16(d + 2 * i) or 0 end
      return t
    end
    return nil
  end,
}

-- Runtime.weather -> {addr, provinces={[省id]=proxy}, regions={[区带id]=proxy},
-- current_province, current_region, seed}
function Runtime.weather(self)
  local g = self.gs()
  local mgr = g and rp(g + 0x688)
  if not O.kptr(mgr) or rp(mgr) ~= G32_WX.mgr then return nil end
  local pd, pc = rp(mgr + 0x10), ru32(mgr + 0x1C)
  local rd, rc = rp(mgr + 0x40), ru32(mgr + 0x4C)
  local provs, regs = {}, {}
  if O.kptr(pd) and pc and pc > 0 and pc < 40000 then
    for i = 0, pc - 1 do
      local e = pd + 0x180 * i
      if rp(e) == G32_WX.prov then
        local pid = ru32(e + 8)
        if pid then provs[pid] = G32_mk_wx_prov(e) end
      end
    end
  end
  if O.kptr(rd) and rc and rc > 0 and rc < 65536 then
    for i = 0, rc - 1 do
      local e = rd + 0x160 * i
      local rid = ru32(e + 8)
      if rid then regs[rid] = G32_mk_wx_reg(e) end
    end
  end
  return { addr = mgr, provinces = provs, regions = regs,
    current_province = ru32(mgr + 0x58), current_region = ru32(mgr + 0x5C),
    seed = ru32(mgr + 0x308) }
end

-- ------------------------------------------------------------
-- 32.2 supply2: CSupplySystem @ (gs+0x3D8)+8 (§4.21.1 /
-- CCountrySupplySystem; 字段/lost 环/settings/foreign_homebase_nodes/
-- disrupted_supply 布局与写门 = 书 §4.21)
-- ------------------------------------------------------------
local G32_SUP2 = { sys = BASE + GAME.layout.vt.CSupplySystem,
  ccs = BASE + GAME.layout.vt.CCountrySupplySystem }

local G32_Sup2MT
local function G32_mk_sup2(a) return setmetatable({ _addr = a }, G32_Sup2MT) end

G32_Sup2MT = {
  __index = function(self, k)
    local a = self._addr
    if not O.kptr(a) or rp(a) ~= G32_SUP2.ccs then return nil end
    if k == "tag" then
      -- CCountry+8 = u32 tag_id; 串表基址 = rp(gs+0x358) (§1.2 tag 串表),
      -- 条目 32B std::string
      local cc = rp(a + 120)
      if not O.kptr(cc) then return nil end
      local tid = ru32(cc + 8)
      if not tid or tid == 0 then return nil end
      local g = Runtime.gs()
      local tbl = g and rp(g + 0x358)
      return (tbl and O.kptr(tbl)) and U.sso(tbl + 32 * tid) or nil
    end
    if k == "priority" then return ru32(a + 0x10) end
    if k == "buffer" then return U.fix5(a + 0x180) end
    if k == "wanted_supply_trucks" then return ru32(a + 0xC8) end
    if k == "last_supply_capital_move" then return ru32(a + 0x17C) end
    if k == "daily_losses_index" then return ru32(a + 0x28C) end
    if k == "last_lost_train_province" then return ru32(a + 0x288) end
    if k == "trucks" then
      local d, n = rp(a + 0x148), ru32(a + 0x154)
      if not O.kptr(d) or not n or n > 512 then return nil end
      local t = {}
      for i = 0, n - 1 do
        local e = d + 24 * i
        t[#t + 1] = { type = ru32(e), id = ru32(e + 4), count = ru32(e + 8),
          damage = U.fix5(e + 16) }
      end
      return t
    end
    if k == "lost_railways" or k == "lost_trains"
        or k == "lost_trucks_attrition" or k == "lost_trucks_killed" then
      local off = ({ lost_railways = 0x228, lost_trains = 0x240,
        lost_trucks_attrition = 0x258, lost_trucks_killed = 0x270 })[k]
      local d, n = rp(a + off), ru32(a + off + 0xC)
      if not O.kptr(d) or not n or n > 64 then return nil end
      local t = {}
      for i = 0, n - 1 do t[#t + 1] = rp(d + 8 * i) end
      return t
    end
    if k == "settings" then
      -- 条目数组 → 存档 settings.node[N].{id, data.disabled,
      -- data.motorization_level.<TAG>}
      local d, n = rp(a + 392), ru32(a + 404)
      if not O.kptr(d) or not n or n > 4096 then return nil end
      local g = Runtime.gs()
      local tbl = g and rp(g + 0x358)
      local t = {}
      for i = 0, n - 1 do
        local e = d + 40 * i
        local rec = {
          id = (ru32(e) or 0) .. " " .. (ru32(e + 4) or 0),
          disabled = ((U.a8(e + 8) or 0) ~= 0) and "yes" or "no",
          moto = {},
        }
        local md, mc = rp(e + 16), ru32(e + 28)
        if O.kptr(md) and mc and mc > 0 and mc < 64 then
          for j = 0, mc - 1 do
            local me = md + 8 * j
            local tg = ru32(me) or 0
            local lv = ru32(me + 4) or 0
            if tg > 0 and tbl and O.kptr(tbl) then
              local tn = U.sso(tbl + 32 * tg)
              if tn then rec.moto[tn] = lv % 256 end
            end
          end
        end
        t[#t + 1] = rec
      end
      return t
    end
    -- 上提 (段 sv2_sec_supply_system_2 内联回收; 布局/写门 = 书 §4.21)
    if k == "foreign_homebase_nodes" then
      local d, n = rp(a + 480), ru32(a + 492)
      if not O.kptr(d) or not n or n == 0 or n > LAYOUT.lim.PTR_SANE then
        return nil end
      local t = {}
      for i = 0, n - 1 do
        local nd = d + 112 * i + 8
        t[#t + 1] = {
          supply = U.fix5(nd), start = U.fix5(nd + 8),
          penalty = U.fix5(nd + 16), add_penalty = U.fix5(nd + 24), add = U.sso(nd + 32),
          duration = U.fix5(nd + 64), province = ru32(nd + 72),
          hours = U.fix5(nd + 80), decay = U.fix5(nd + 88),
          base = (U.a8(nd + 96) or 0) ~= 0 }
      end
      return t
    end
    -- disrupted_supply RH {tab@+144, cnt@+152, mask@+156, tail u8@+160},
    -- 桶 24B {dist u8@+4, key 对 u32×2@+8, value i64 fx@+16};
    -- 写序 (node id@+8 升序, 勘误定案) = 段层职责
    if k == "disrupted_supply" then
      local cnt = ru32(a + 152)
      if not cnt or cnt == 0 or cnt > LAYOUT.lim.PTR_SANE then return nil end
      local dt = rp(a + 144)
      if not O.kptr(dt) then return nil end
      local mask, tail = ru32(a + 156) or 0, U.a8(a + 160) or 0
      local t = {}
      for bi = 0, mask + tail do
        local bk = dt + 24 * bi
        local dist = U.a8(bk + 4) or 0
        if dist ~= 0 and dist ~= 0xFE then
          t[#t + 1] = { id_lo = ru32(bk + 12), id_hi = ru32(bk + 8),
            value = U.fix5(bk + 16) }
        end
      end
      return t
    end
    -- alive 门 (段 sv2_sec_supply_system_2 内联回收): ×CCountry@+120
    -- → owned_states 计数 u32@cc+1156 > 0
    if k == "alive" then
      local ccx = rp(a + 120)
      return O.kptr(ccx) and (ru32(ccx + 1156) or 0) > 0 or false
    end
    -- capital (writer 0x14121C6D0 L96-97 token 0x284B(10315)):
    -- u32@+376, 门 ≠0 (门 = 发射规则, 段侧判 nil/0)
    if k == "capital" then return ru32(a + 376) end
    return nil
  end,
}

-- Runtime.supply2 -> {addr, by_tag={[TAG]=proxy}, list=[proxy...]}
function Runtime.supply2(self)
  local g = self.gs()
  local P = g and rp(g + 0x3D8)
  local sys = P and (P + 8) or nil
  if not O.kptr(sys) or rp(sys) ~= G32_SUP2.sys then return nil end
  local d, n = rp(sys + 0x100), ru32(sys + 0x10C)
  local list, by_tag = {}, {}
  -- 738 国 mod > 旧 600 门 → 放宽 100000
  if O.kptr(d) and n and n > 0 and n < 100000 then
    for i = 0, n - 1 do
      local e = rp(d + 8 * i)
      if O.kptr(e) and rp(e) == G32_SUP2.ccs then
        local proxy = G32_mk_sup2(e)
        list[#list + 1] = proxy
        local tg = proxy.tag
        if tg then by_tag[tg] = proxy end
      end
    end
  end
  return { addr = sys, by_tag = by_tag, list = list }
end

-- ------------------------------------------------------------
-- 32.3 equipments: CEquipmentVariant (§4.23.1; 容器 gs+0x708
-- vector<ptr>; 布局/写门 = 书 §4.23)
-- ------------------------------------------------------------
local G32_EQ = { vt = BASE + GAME.layout.vt.CEquipmentVariant }

local G32_EqMT
local function G32_mk_eq(a) return setmetatable({ _addr = a }, G32_EqMT) end

G32_EqMT = {
  __index = function(self, k)
    local a = self._addr
    if not O.kptr(a) then return nil end
    if k == "type" then return ru32(a + 0x8) end
    if k == "id" then return ru32(a + 0xC) end
    if k == "key_token" then return ru32(a + 0x18) end
    if k == "creator" or k == "origin" then
      local g = Runtime.gs()
      local tbl = g and rp(g + 0x358)
      if not O.kptr(tbl) then return nil end
      local tid = ru32(a + (k == "creator" and 0x1C or 0x20))
      if not tid then return nil end
      return U.sso(tbl + 32 * tid)
    end
    if k == "archetype" then
      local kt = ru32(a + 0x18)
      return LAYOUT.token_name(kt) or kt
    end
    if k == "show_position" then return U.a8(a + 0x24) end  -- (writer ==0 才写 no)
    if k == "name" then return U.sso(a + 0x28) end
    if k == "position" then return U.sso(a + 0x48) end
    if k == "version" then return U.a8(a + 0x41C) end
    if k == "max_version" then return U.a8(a + 0x41D) end
    if k == "is_frame" then return U.a8(a + 0x41E) end
    if k == "manpower" then return ru32(a + 0x420) end
    if k == "obsolete" then return U.a8(a + 0x424) end
    if k == "auto_upgraded" then return U.a8(a + 0x425) end
    if k == "highlight" then return U.a8(a + 0x426) end
    if k == "can_upgrade_type" then return U.a8(a + 0x427) end
    if k == "can_upgrade_variant" then return U.a8(a + 0x428) end
    if k == "can_upgrade_modules" then return U.a8(a + 0x429) end
    if k == "role_icon_index" then return ru32(a + 0x42C) end
    if k == "parent_id" then
      local p = rp(a + 0x3F8)
      if not O.kptr(p) then return nil end
      return { id = ru32(p + 0xC), type = ru32(p + 0x8) }
    end
    if k == "parent" then
      local p = rp(a + 0x3F8)
      return O.kptr(p) and G32_mk_eq(p) or nil
    end
    if k == "division_names_group" then
      local p = rp(a + 0x480)
      return O.kptr(p) and U.sso(p + 8) or nil
    end
    if k == "override_sprite" then return U.sso(a + 0x458) end
    if k == "override_model" then return U.sso(a + 0x430) end
    if k == "design_team" then
      local t = ru32(a + 0x488)
      if not t or t == 0 then return nil end
      return { type = t, id = ru32(a + 0x48C) }
    end
    if k == "design_team_bonus" then
      -- count@+0x4A4 (writer 0x140BD4770 尾门; 旧 +0x4A0=cap
      -- 误读, cap>count 时越界读网格对象产垃圾叶, 段内纠偏回收)
      local arr, n = rp(a + 0x498), ru32(a + 0x4A4)
      if not O.kptr(arr) or not n or n == 0 or n > LAYOUT.lim.PTR_SANE then return nil end
      local t = {}
      for i = 0, n - 1 do
        local e = arr + 16 * i
        local tok = ru32(e)
        t[#t + 1] = {
          name = tok and (LAYOUT.token_name(tok) or tostring(tok)) or "?",
          value = U.fix5(e + 8),
        }
      end
      return t
    end
    if k == "number_of_design_team_traits" then
      local v = ru32(a + 0x4B0)
      return (v and v > 0) and v or nil
    end
    if k == "named_equipment_bonuses" then
      local d, n = rp(a + 0xE8), ru32(a + 0xF4)
      if not O.kptr(d) or not n or n == 0 or n > LAYOUT.lim.PTR_SANE then return nil end
      local t = {}
      for i = 0, n - 1 do t[#t + 1] = ru32(d + 4 * i) or 0 end
      return t
    end
    if k == "upgrade_list" then
      -- (writer 0x140F7A6F0 定案): upgrades 实例内嵌@+0x68,
      -- 容器 {d@+0x70, c@+0x7C}, 条目 stride16
      -- {upgrade_def ptr@+0 (名 token = *(def+8)), level u8@+8}
      -- 存档形态 "upgrades={ upgrades={ tank_nsb_engine_upgrade 0 ... } }"
      local d, n = rp(a + 0x70), ru32(a + 0x7C)
      if not O.kptr(d) or not n or n > 128 then return {} end
      local t = {}
      for i = 0, n - 1 do
        local e = d + 16 * i
        local def = rp(e)
        -- def+8 是名 token (u32 直存, writer 1424A7300(*(def+8)))
        local tok = O.kptr(def) and ru32(def + 8) or nil
        t[#t + 1] = {
          name = tok and (LAYOUT.token_name(tok) or ("tok" .. tostring(tok))) or "?",
          level = U.a8(e + 8) or 0,
        }
      end
      return t
    end
    if k == "modules" then
      local d, n = rp(a + 0xB8), ru32(a + 0xC4)
      if not O.kptr(d) or not n or n > 64 then return nil end
      local t = {}
      for i = 0, n - 1 do
        local e = d + 16 * i
        local mo = rp(e + 8)
        local mtok = (O.kptr(mo) and U.a8(mo + 16) ~= 0) and ru32(mo + 8) or nil
        t[#t + 1] = {
          slot = LAYOUT.token_name(ru32(e)) or ru32(e),
          token = mtok,
          module = mtok and LAYOUT.token_name(mtok) or nil,
        }
      end
      return t
    end
    if k == "ideas" then
      local d, n = rp(a + 0xD0), ru32(a + 0xDC)
      if not O.kptr(d) then return nil end
      if not n or n > 64 then return nil end
      -- 键门 (writer 0x140BD4770 尾): count@+0xDC != 0 才写键。count==0
      -- → 存档无 ideas= 键 (返回 nil, 非 {}); count!=0 但名全解析空
      -- → 合法空块 "ideas={ }" (t 为空表, 调用方发 "{}")
      if n == 0 then return nil end
      local t = {}
      for i = 0, n - 1 do
        local e = rp(d + 8 * i)
        local io = e and O.kptr(e) and rp(e + 120)
        if io and O.kptr(io) then t[#t + 1] = ru32(io + 8) end
      end
      return t
    end
    return nil
  end,
}

-- Runtime.equipments -> {addr, count, list=[代理], by_id={[id]=代理},
-- by_token={[key_token]={代理,...}}}
function Runtime.equipments(self)
  local g = self.gs()
  if not g then return nil end
  local data, cnt = rp(g + 0x708), ru32(g + 0x714)
  local list, by_id, by_token = {}, {}, {}
  if O.kptr(data) and cnt and cnt > 0 and cnt < 100000 then
    for i = 0, cnt - 1 do
      local v = rp(data + 8 * i)
      if v and v >= 0x10000 and rp(v) == G32_EQ.vt then
        local px = G32_mk_eq(v)
        list[#list + 1] = px
        local id = ru32(v + 0xC)
        if id then by_id[id] = px end
        local kt = ru32(v + 0x18)
        if kt then
          by_token[kt] = by_token[kt] or {}
          table.insert(by_token[kt], px)
        end
      end
    end
  end
  return { addr = g + 0x708, count = cnt, list = list, by_id = by_id,
    by_token = by_token }
end

-- ------------------------------------------------------------
-- 32.4 division_templates: CReferencedDivisionTemplate (§4.18.6;
-- 内嵌 CDivisionTemplateData §4.18.7; 容器 gs+0x6F0 vector<ptr>,
-- 布局 = 书)
-- ------------------------------------------------------------
local G32_DTP = { vt = BASE + GAME.layout.vt.CDeployment }

local G32_DtplMT
local function G32_mk_dtpl(a) return setmetatable({ _addr = a }, G32_DtplMT) end

G32_DtplMT = {
  __index = function(self, k)
    local a = self._addr
    if not O.kptr(a) then return nil end
    local d = a + 24
    if k == "type" then return ru32(a + 8) end
    if k == "id" then return ru32(a + 12) end
    if k == "name" then return U.sso(d + 8) end
    if k == "localization_key" then return U.sso(d + 40) end
    if k == "country" or k == "original_tag" or k == "foreign_template_tag" then
      local g = Runtime.gs()
      local tbl = g and rp(g + 0x358)
      if not O.kptr(tbl) then return nil end
      local off = (k == "country" and 468) or (k == "original_tag" and 472) or 476
      local tid = ru32(d + off)
      if not tid then return nil end
      return U.sso(tbl + 32 * tid)
    end
    if k == "priority" then return ru32(d + 396) end
    if k == "template_counter" then
      local v = ru32(d + 424)
      if v then v = LAYOUT.as_i32(v) end
      return v
    end
    if k == "ingame_set_template_counter" then return U.a8(d + 428) end
    if k == "allow_new_equipment" then return U.a8(d + 429) end
    if k == "allow_foreign_equipment" then return U.a8(d + 430) end
    if k == "is_army_hq" then return U.a8(d + 436) end
    if k == "is_fake_intel_division" then return U.a8(d + 540) end
    if k == "is_locked" then return U.a8(d + 541) end
    if k == "obsolete" then return U.a8(d + 542) end
    if k == "obsolete_change_date" then
      -- (0x2BA0): 条件 obsolete b@542 且 hours u32@552 ≠ 哨兵
      -- 0x29C77F8 (本字段默认值); 日期算法同共享 date 族
      if (U.a8(d + 542) or 0) == 0 then return nil end
      -- 唯一实现 = hoi4_layout.date_opt (门 = 仅滤哨兵 0x29C77F8;
      -- 0 与 0x29C3388 在本字段**不滤** — 与 U.date 语义不同)
      return LAYOUT.date_opt(ru32(d + 552), { drop = { 0x29C77F8 } })
    end
    if k == "override_model" then
      -- (0x3AF1): MSVC std::string @data+504 (size@+520 ≠0 才写)
      -- ⚠ U.sso 对 size==0 返 ""(真值) → 发射端 tostring 出空串;
      -- legacy read_msvc_str 返 nil → 必须归一
      local m = U.sso(d + 504)
      if m and #m > 0 then return m end
      return nil
    end
    if k == "force_allow_recruiting" then return U.a8(d + 568) end
    if k == "division_cap" then
      if U.a8(d + 576) == 0 then return nil end
      return ru32(d + 572)
    end
    if k == "origin_type" then
      return ({ "master_host", "subject", "exile" })[ru32(d + 480) + 1]
    end
    if k == "division_names_group" then
      local p = rp(d + 440)
      return O.kptr(p) and U.sso(p + 8) or nil
    end
    if k == "role_token" then
      if U.a8(d + 452) == 0 then return nil end
      return ru32(d + 448)
    end
    if k == "regiments" or k == "supports" or k == "regimental_supports" then
      local base = (k == "regiments" and 72) or (k == "supports" and 104) or 136
      local width = (ru32(d + base) >> 16) & 0xFFFF -- 列高=hi u16 (x=slot//hi, y=slot%hi; lo=列数)
      local cd, cn = rp(d + base + 8), ru32(d + base + 20)
      local t = {}
      if O.kptr(cd) and cn and cn > 0 and cn < 5000 and width > 0 then
        for v5 = 0, cn - 1 do
          local e = rp(cd + 8 * v5)
          if O.kptr(e) and U.a8(e + 16) ~= 0 then
            t[#t + 1] = {
              unit_token = ru32(e + 8),
              unit = LAYOUT.token_name(ru32(e + 8)) or ru32(e + 8),
              x = math.floor(v5 / width),
              y = v5 % width,
            }
          end
        end
      end
      return t
    end
    return nil
  end,
}

-- Runtime.division_templates -> {addr, count, list=[代理], by_id={[id]=代理}}
function Runtime.division_templates(self)
  local g = self.gs()
  if not g then return nil end
  local data, cnt = rp(g + 0x6F0), ru32(g + 0x6FC)
  local list, by_id = {}, {}
  if O.kptr(data) and cnt and cnt > 0 and cnt < 100000 then
    for i = 0, cnt - 1 do
      local w = rp(data + 8 * i)
      if w and w >= 0x10000 and rp(w) == G32_DTP.vt then
        local px = G32_mk_dtpl(w)
        list[#list + 1] = px
        local id = ru32(w + 12)
        if id then by_id[id] = px end
      end
    end
  end
  return { addr = g + 0x6F0, count = cnt, list = list, by_id = by_id }
end

-- ------------------------------------------------------------
-- 32.5 rail_way: CRailwayManager @gs+0x3E0 (§4.14.7; 元素
-- §4.14.6 CProvinceRailwayInfo; 容器/levels 邻接表序 = 书)
-- ------------------------------------------------------------
local G32_RW = { mgr = BASE + GAME.layout.vt.CRailwayManager, info = BASE + GAME.layout.vt.CProvinceRailwayInfo }

local G32_RWInfoMT
local function G32_mk_rw_info(a) return setmetatable({ _addr = a }, G32_RWInfoMT) end

G32_RWInfoMT = {
  __index = function(self, k)
    local a = self._addr
    if not O.kptr(a) or rp(a) ~= G32_RW.info then return nil end
    if k == "province_id" then
      local prov = rp(a + 0x08)
      return O.kptr(prov) and ru32(prov + 0xC4) or nil
    end
    if k == "levels" then
      -- 铁轨等级数组, 按邻接表顺序 (1起始, levels[i]=第i个邻省), count==邻省数
      local d, n = rp(a + 0x20), ru32(a + 0x2C)
      if not O.kptr(d) or not n or n > 64 then return nil end
      local t = {}
      for i = 0, n - 1 do t[i + 1] = ru32(d + 4 * i) end
      return t
    end
    if k == "neighbors" then
      -- 排序 {邻省id, level} (仅 level>0 的边)
      local d, n = rp(a + 0x38), ru32(a + 0x44)
      if not O.kptr(d) or not n or n > 64 then return nil end
      local t = {}
      for i = 0, n - 1 do
        t[#t + 1] = { id = ru32(d + 8 * i), level = ru32(d + 8 * i + 4) }
      end
      return t
    end
    if k == "construction" then
      -- 建造中边: {邻省id, 进度定点} 16B pair (n=0 返回空表)
      -- ⚠ progress = i64 fixed×1e-5 (原实现误用 ru32 读低半, 已修)
      local d, n = rp(a + 0x50), ru32(a + 0x5C)
      if not n or n > 256 then return nil end
      local t = {}
      if O.kptr(d) then
        for i = 0, n - 1 do
          local p = rp(d + 16 * i + 8)
          t[#t + 1] = { id = ru32(d + 16 * i),
            progress = p and LAYOUT.as_i64(p) or nil }
        end
      end
      return t
    end
    if k == "cooldown" then return ru32(a + 0x68) end
    return nil
  end,
}

-- Runtime.rail_way -> {addr, slots, list=[代理...], by_province={[省id]=代理},
--                      top_cooldown = {d@mgr+32, c@mgr+44} u32 列表}
function Runtime.rail_way(self)
  local g = self.gs()
  local mgr = g and rp(g + 0x3E0)
  if not O.kptr(mgr) or rp(mgr) ~= G32_RW.mgr then return nil end
  local data, slots = rp(mgr + 0x08), ru32(mgr + 0x14)
  local list, by_id = {}, {}
  if O.kptr(data) and slots and slots > 0 and slots < 100000 then
    for i = 0, slots - 1 do
      local p = rp(data + 8 * i)
      if p and p >= 0x10000 and rp(p) == G32_RW.info then
        local proxy = G32_mk_rw_info(p)
        list[#list + 1] = proxy
        local pid = proxy.province_id
        if pid then by_id[pid] = proxy end
      end
    end
  end
  -- 顶格 cooldown 列表 (§4.14.7; c>0 才写, 段层钳 4096)
  local top_cooldown = {}
  local tcd, tcn = rp(mgr + 32), ru32(mgr + 44)
  if O.kptr(tcd) and tcn and tcn > 0 then
    for i = 0, math.min(tcn, LAYOUT.lim.PTR_SANE) - 1 do
      top_cooldown[#top_cooldown + 1] = ru32(tcd + 4 * i) or 0
    end
  end
  return { addr = mgr, slots = slots, list = list, by_province = by_id,
           top_cooldown = top_cooldown }
end

-- ------------------------------------------------------------
-- 32.6 faction_pool: CFactionSystem @gs+0x3F8 (§4.5; members/
-- extracted 池 = 书)
-- ------------------------------------------------------------
-- Runtime.faction_pool -> {data, count, entries={value, name_id}}
function Runtime.faction_pool(self)
  local g = self.gs()
  local fac = g and rp(g + 0x3F8)
  if not O.kptr(fac) then return nil end
  local data = rp(fac + 0x40)
  local cnt = ru32(fac + 0x48)
  if not O.kptr(data) or not cnt or cnt > 64 then return nil end
  local entries = {}
  for i = 0, cnt - 1 do
    entries[#entries + 1] = {
      value = rp(data + i * 0x10),
      name_id = ru32(data + i * 0x10 + 0x8),
    }
  end
  return { data = data, count = cnt, entries = entries }
end
