-- objects_economy.lua -- 燃料/决议/杂项/编制/装备/特殊项目/名字组 (对象层域文件)
-- 结构语义详见书: §4.7.9 特殊项目 / §4.23 装备 / §4.12.3 决议 等。
-- 共享层惰性获取 (DLL 字母序下 objects_shared 晚于本文件加载)。
-- 世代判据 (书 §0.2 对象层文件布局) = GAME.layout 表身份: hoi4_layout 每代
-- 重建该表, 故 SH.LAYOUT == GAME.layout ⟺ 本代层已建 → 直接复用;
-- 缺失/过期则自举重建 (hot reload 改 objects_shared 也走这条重建路)。
-- 本代首个域文件建层, 其余域文件复用同一份。
local SH = GAME.objects_shared
if not SH or not SH.LAYOUT or SH.LAYOUT ~= GAME.layout then
    local _src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    -- 目录 = 源路径去掉末段; 分隔符 / 与反斜杠都接受 (字符类含两个字符)
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
local tok, tokname_of = SH.tok, SH.tokname_of
local to_i32, to_i16 = LAYOUT.as_i32, LAYOUT.as_i16

-- §4.3.16 CCountryFuelStatus 燃料 (fuel cc+5504 vtable 0x298b3a8) /
-- §4.3.3 CCountryResources 资源路由 (delivery cc+4600 vtable 0x295c320 / 0x295c4b0)
-- ============================================================
-- §4.3.16 fuel 燃料 (writer 定案偏移; Q15 与 fixed×1e-5 混合量纲)
function Country.fuel(self)
  local fs = rp(self.addr + 5504)
  if not O.kptr(fs) or rp(fs) ~= BASE + GAME.layout.vt.CFuelStatus then return nil end
  local out = { addr = fs }
  out.fuel = (rp(fs + 8) or 0) / 32768
  out.max_fuel = (rp(fs + 0x10) or 0) / 32768
  out.fuel_gain = U.fix5(fs + 0x18)
  -- writer+探针定案 (旧偏移标注互有错位)
  out.fuel_gain_per_oil = U.fix5(fs + 0x40)
  out.fuel_cost = U.fix5(fs + 0x38)
  out.fuel_gain_from_states = U.fix5(fs + 0x20)
  out.remaining_hours = ru32(fs + 0xCC)
  -- +0x28/+0x30 系 Q15 (非 fix5) — writer ADDD0/%.5f,
  -- parser sub_1424B0350 v×32768+0.5
  out.fuel_gain_from_lend_lease = (rp(fs + 0x28) or 0) / 32768
  out.fuel_consumption_from_lend_lease = (rp(fs + 0x30) or 0) / 32768
  out.consumers = { count = ru32(fs + 0x54) or 0, list = {} }
  for _, u in O.vec(fs, 0x48, 0x54, 24, false) do
    out.consumers.list[#out.consumers.list + 1] = {
      priority = ru32(u), requested = U.fix5(u + 8),
      received = U.fix5(u + 16) }
  end
  return out
end

-- §4.3.3 delivery_routes 交付路由 (⚠ 真路由容器 = rs+1928 (全槽含占位);
-- rs+1904 是读档瞬态重建临时容器 — 旧读法全空是假象)
function Country.delivery_routes(self)
  local rs = rp(self.addr + 4600)
  if not O.kptr(rs) or rp(rs) ~= BASE + GAME.layout.vt.CCountryResources then return nil end
  local out = { addr = rs, count = ru32(rs + 1936) or 0, routes = {} }
  for _, r in O.vec(rs, 1928, 1936, 8, true) do
    if O.kptr(r) and rp(r) == BASE + GAME.layout.vt.CResourceDelivery then
      local t = { addr = r, type = ru32(r + 8) % 256 }
      local fp16 = rp(r + 16)
      t.from_state = O.kptr(fp16) and ru32(fp16 + 88) or nil
      local tp24 = rp(r + 24)
      t.to_state = O.kptr(tp24) and ru32(tp24 + 88) or nil
      local pp32 = rp(r + 32)
      t.from_port = O.kptr(pp32) and ru32(pp32 + 164) or nil
      local pp40 = rp(r + 40)
      t.to_port = O.kptr(pp40) and ru32(pp40 + 164) or nil
      t.sender = ru32(r + 48)
      t.receiver = ru32(r + 52)
      t.convoys_owner = ru32(r + 56)
      t.dirty = (ru32(r + 120) % 256) ~= 0
      t.land_path = {}
      for _, sp in O.vec(r, 72, 84, 8, true) do
        t.land_path[#t.land_path + 1] = O.kptr(sp) and ru32(sp + 88) or nil
      end
      t.naval_path = {}
      for _, sp in O.vec(r, 96, 108, 8, true) do
        t.naval_path[#t.naval_path + 1] = O.kptr(sp) and ru32(sp + 88) or nil
      end
      out.routes[#out.routes + 1] = t
    end
  end
  return out
end



-- ============================================================
-- §4.12.2 CDecisionStatus 决议 (cc+4000) / §4.3.17 CCountryExperienceStatus 经验·活动 (cc+5512)
-- ============================================================
-- §4.12.2 决议 (状态枚举/布局/writer = 书 §4.12.2)
local DEC_STATE = { "available", "completed", "re_enable_cooldown",
  "failed", "aborted" }
local function dec_name(e)               -- 名 = token 内联@e+0x10 ()
  local tk = ru32(e + 0x10)
  return tk and tok(tk) or nil
end
function Country.decisions(self)
  local ds = rp(self.addr + 4000)
  if not O.kptr(ds) then return nil end
  local out = { addr = ds }
  local function cdlist(doff, coff, wrap)
    local list = { count = ru32(ds + coff) or 0, items = {} }
    for _, e in O.vec(ds, doff, coff, 8, true) do
      local ne = e
      if wrap then                        -- 元素 = {CDecision*@+8, days@+16}
        local dec = rp(e + 8)
        ne = O.kptr(dec) and dec or nil
      end
      list.items[#list.items + 1] = {
        name = ne and dec_name(ne) or nil, days = ru32(e + 16) }
    end
    return list
  end
  out.decisions_taken = cdlist(64, 76)
  out.to_re_enable = cdlist(88, 100, true)
  out.to_remove = cdlist(112, 124, true)
  -- active_timed: 名 = cstr@*(e+16)+288; days i32@+24 (可负); state@+28
  out.active_timed = { count = ru32(ds + 172) or 0, items = {} }
  for _, e in O.vec(ds, 160, 172, 8, true) do
    local d = rp(e + 16)
    local dv = ru32(e + 24)
    if dv then dv = LAYOUT.as_i32(dv) end
    out.active_timed.items[#out.active_timed.items + 1] = {
      name = O.kptr(d) and U.cstr(d + 288) or nil,
      days = dv, state = ru32(e + 28) }
  end
  -- active_targeted / att_timed (targeted 同构; ser 基 el+8)
  local function targeted(doff, coff)
    local r = { count = ru32(ds + coff) or 0, items = {} }
    for _, e in O.vec(ds, doff, coff, 8, true) do
      local dptr = rp(e + 16)
      local nm = O.kptr(dptr) and (U.cstr(dptr + 288) or U.sso(dptr + 288))
          or nil
      local dv = ru32(e + 48)
      if dv then dv = LAYOUT.as_i32(dv) end
      local it = { name = nm, days = dv,
        state = DEC_STATE[(ru32(e + 40) or 0) + 1],
        ignore = ((ru32(e + 44) or 0) % 256) ~= 0 }
      local ttag, tstate = ru32(e + 32) or 0, ru32(e + 36) or 0
      -- ⚠ 须 self.R:tag(tid): Country.tag(self) 无参形态返回本国自身 tag,
      -- self:tag(ttag) 实参被忽略 → ATDX target 恒本国 (根因)
      if ttag ~= 0 then it.target = self.R:tag(ttag)
      elseif tstate ~= 0 then it.target = tostring(tstate) end
      r.items[#r.items + 1] = it
    end
    return r
  end
  out.active_targeted = targeted(232, 244)
  out.att_timed = targeted(256, 268)
  -- random_item: 24B 内联 {静态@0, CDecision*@+8, count@+16, target@+20}
  out.random_item = { count = ru32(ds + 340) or 0, items = {} }
  for _, e in O.vec(ds, 328, 340, 24, false) do
    local dptr = rp(e + 8)
    local nm = O.kptr(dptr) and (U.cstr(dptr + 288) or U.sso(dptr + 288)) or nil
    out.random_item.items[#out.random_item.items + 1] =
        { name = nm, count = ru32(e + 16), target = ru32(e + 20) }
  end
  return out
end

-- §4.3.17 experience 经验 (cc+5512; Q15 量纲)
function Country.experience(self)
  local es = rp(self.addr + 5512)
  if not O.kptr(es) then return nil end
  local q15 = function(a)               -- Q15: raw / 32768
    local v = LAYOUT.i64(a)
    if not v then return nil end
    return v / 32768
  end
  return { addr = es,
    army = q15(es + 16), army_daily = q15(es + 24),
    army_daily_training = q15(es + 32),
    navy = q15(es + 40), navy_daily = q15(es + 48),
    air = q15(es + 64), air_daily = q15(es + 72) }
end

-- §4.3.17 activity_data 活动数据 (xp_by_template {88,100} 24B / taskforce {112,124} 40B /
-- airwing {136,148} 24B; naval 特有 mission@+0x18 (门 b@+0x1C≠0) /
-- on_mission@+0x20 (>0))
function Country.activity_data(self)
  local es = rp(self.addr + 5512)
  if not O.kptr(es) or rp(es) ~= BASE + GAME.layout.vt.CExperienceStatus then return nil end
  local function act_elems(ptr_off, cnt_off, stride, vt)
    local out = {}
    local d, n = rp(es + ptr_off), ru32(es + cnt_off)
    if O.kptr(d) and n and n > 0 and n <= 500 then
      for i = 0, n - 1 do
        local e = d + stride * i
        if rp(e) == vt then
          out[#out + 1] = { addr = e, combat = ru32(e + 8),
            training = ru32(e + 12),
            ref_type = ru32(e + 0x10), ref_id = ru32(e + 0x14) }
        end
      end
    end
    return out
  end
  local naval_out = {}
  do
    local d, n = rp(es + 112), ru32(es + 124)
    if O.kptr(d) and n and n > 0 and n < 65536 then
      for i = 0, n - 1 do
        local e = d + 40 * i
        if rp(e) == BASE + GAME.layout.vt.CExperienceElem then
          naval_out[#naval_out + 1] = { combat = ru32(e + 8),
            training = ru32(e + 12), ref_type = ru32(e + 0x10),
            ref_id = ru32(e + 0x14), mission = ru32(e + 0x18),
            on_mission = ru32(e + 0x20) }
        end
      end
    end
  end
  return { addr = es,
    xp_by_template = act_elems(88, 100, 24, BASE + GAME.layout.vt.CActivityElem),
    xp_by_taskforce = naval_out,
    xp_by_airwing = act_elems(136, 148, 24, BASE + GAME.layout.vt.CActivityElemAir),
    counts = { templates = ru32(es + 100) or 0,
      taskforces = ru32(es + 124) or 0, airwings = ru32(es + 148) or 0 } }
end



-- ============================================================
-- §4.3.10 / §4.3.21 / §4.8 国家杂项小函数 (nukes/power_balance/policies/mio)
-- ============================================================
-- §4.3.10 CNuke 核弹 (容器 {data@cc+4880, count@cc+4892}, 元素 72B)
function Country.nukes(self)
  local out = { count = ru32(self.addr + 4892) or 0, list = {} }
  for _, e in O.vec(self.addr, 4880, 4892, 72, false) do
    out.list[#out.list + 1] = { amount = U.fix5(e + 24),
      nukes_ready = ru32(e + 60), strikes = ru32(e + 44) or 0 }
  end
  return out
end

-- §4.3.21 CPowerBalanceSystem 力量平衡 (sys gs+0x450 = gs+1104, vtable 0x296fca0; 条目 400B vtable 0x296fc50)
function Runtime.power_balance(self)
  local g = self.gs()
  local sys = g and rp(g + 0x450)
  if not O.kptr(sys) or rp(sys) ~= BASE + GAME.layout.vt.CPowerBalanceSystem then return nil end
  local out = { addr = sys, total = ru32(sys + 20), list = {} }
  local data = rp(sys + 8)
  local n = out.total
  if not O.kptr(data) or not n or n == 0 or n > 4096 then return out end
  for i = 0, n - 1 do
    local e = data + 400 * i
    if rp(e) ~= BASE + GAME.layout.vt.CPowerBalanceEntry then
      out.list[#out.list + 1] = { i = i, addr = e, bad_vt = true }
    else
      local t = { i = i, addr = e }
      local tp = rp(e + 0x10)
      if O.kptr(tp) then t.template = U.sso(tp + 0x10) end
      local sides = { left = 0x18, right = 0x20, trending = 0x28 }
      for key, off in pairs(sides) do
        local p = rp(e + off)
        t[key] = O.kptr(p) and U.sso(p + 0x10) or nil
      end
      t.value = U.fix5(e + 0x30)
      t.countries = {}
      -- ⚠ u32 数组须 deref (legacy L6857-6861: ru32(cd+4*j))
      do
        local cd2, cc2 = rp(e + 0x38), ru32(e + 0x44)
        if O.kptr(cd2) and cc2 and cc2 < 100000 then
          for j = 0, cc2 - 1 do
            t.countries[#t.countries + 1] = ru32(cd2 + 4 * j)
          end
        end
      end
      t.modifiers = {}
      for _, p in O.vec(e, 0x50, 0x5C, 8, true) do
        t.modifiers[#t.modifiers + 1] = O.kptr(p) and U.sso(p + 424) or nil
      end
      t.sides = { count = ru32(e + 0x184) or 0, list = {} }
      for _, s in O.vec(e, 0x178, 0x184, 80, false) do
        t.sides.list[#t.sides.list + 1] = { id = U.sso(s + 8),
          gfx = U.sso(s + 0x30) }
      end
      out.list[#out.list + 1] = t
    end
  end
  return out
end

-- §4.8 CProductionStatus policies 政策 (ps=cc+3944 {data@328, count@340})
function Country.policies(self)
  local ps = rp(self.addr + 3944)
  if not O.kptr(ps) then return nil end
  local out = { count = ru32(ps + 340) or 0, list = {} }
  for _, e in O.vec(ps, 328, 340, 8, true) do
    if O.kptr(e) then
      out.list[#out.list + 1] = { name = tok(ru32(e + 8)),
        -- (writer sub_140A3D110): cost u32@el+72 (旧 +48 误植),
        -- cooldown u32@el+76
        cost = ru32(e + 72), cooldown = ru32(e + 76) }
    end
  end
  return out
end

-- §4.8.12 COrganisation MIO (pm=cc+0xF68=3944 industrial_organisations 容器 {d@+0x130, c@+0x13C}; org vtable 0x2967a28)
-- (MIOrgMT 细粒度字段见 objects_legacy MIOrgMT 块 / 原料库)
function Country.mio(self)
  -- ⚠ 过渡桥接: 走 legacy MIOrgMT (正式迁移待办, 见 _v2_PROGRESS.md);
  -- legacy objects.lua 在本文件之前加载, GAME.objects 恒可用
  return GAME.objects.mio(self.idx)
end



-- ============================================================
-- §1.2 计数总览 / §4.18.4 编制模板 id / §4.8.12 MIO 扫描
-- ============================================================
-- §4.18.4 CDivisionTemplate 编制模板 id (容器 {data@cc+440, count@cc+452}; 布局/id 对 = 书 §4.18.4)
function Country.division_template_ids(self)
  local out = {}
  for _, tpl in O.vec(self.addr, 440, 452, 8, true) do
    if O.kptr(tpl) then
      local q = rp(tpl + 8) or 0
      out[#out + 1] = { type = q % 4294967296,
        id = math.floor(q / 4294967296) }
    end
  end
  return out
end

-- §4.8.12 MIO 全扫描 (过渡桥接 legacy mio_scan; 正式迁移随 MIOrgMT 待办)
function Runtime.mio_scan(self)
  return GAME.objects.mio_scan()
end

-- §1.2 gs 管理器总表 计数总览 (各管理器规模一屏, 供导出端 counts 段; 偏移→章节 = 书 §1.2)
function Runtime.counts(self)
  local g = self.gs()
  if not g then return {} end
  local out = { countries = ru32(g + 0x31C) }
  local mgr = rp(g + 0x6A8)
  if O.kptr(mgr) then
    out.characters_historical = ru32(mgr + 0x1C)
    out.characters_dynamic = ru32(mgr + 0x34)
    out.next_character_id = ru32(mgr + 8)
  end
  local fac = rp(g + 0x3F8)
  if O.kptr(fac) then out.faction_members = ru32(fac + 0x14) end
  local doc = rp(g + 0x400)
  if O.kptr(doc) then out.doctrine_countries = ru32(doc + 0x14) end
  local raids = rp(g + 0x3F0)
  if O.kptr(raids) then out.raid_countries = ru32(raids + 0xE4) end
  local sam = rp(g + 0x690)
  if O.kptr(sam) and rp(sam) == BASE + SA2.mgr then
    out.strategic_air_countries = #cont_elems(sam, 0x30, SA2.sa_country)
    out.strategic_air_bases = #cont_elems(sam, 0x90, SA2.airbase)
  end
  local rwm = rp(g + 0x3E0)
  if O.kptr(rwm) and rp(rwm) == BASE + GAME.layout.vt.CRailwayManager then
    local d, n = rp(rwm + 8), ru32(rwm + 20)
    local nn = 0
    if O.kptr(d) and n and n < 100000 then
      for i = 0, n - 1 do
        local p = rp(d + 8 * i)
        if p and p >= 0x10000 and rp(p) == BASE + GAME.layout.vt.CProvinceRailwayInfo then nn = nn + 1 end
      end
    end
    out.rail_way_provinces = nn
  end
  out.mio_total = 0
  for _, m in ipairs(self:mio_scan()) do
    out.mio_total = out.mio_total + #m.orgs end
  local wx = rp(g + 0x688)
  if O.kptr(wx) and rp(wx) == BASE + GAME.layout.vt.CWeatherManager then
    out.weather_provinces = ru32(wx + 0x1C)
    out.weather_regions = ru32(wx + 0x4C)
  end
  local sp = rp(g + 0x3D8)
  if O.kptr(sp) and rp(sp + 8) == BASE + GAME.layout.vt.CSupplySystem then
    out.supply2_countries = ru32(sp + 8 + 0x10C)
  end
  out.equipment_variants = ru32(g + 0x714)
  local nm_ = rp(g + 0x698)
  out.naval_bases_world = (O.kptr(nm_) and rp(nm_) == BASE + GAME.layout.vt.CNavalBase)
      and ru32(nm_ + 48) or nil
  local pbs = rp(g + 0x450)
  out.power_balance_total = (O.kptr(pbs) and rp(pbs) == BASE + GAME.layout.vt.CPowerBalanceSystem)
      and ru32(pbs + 20) or nil
  local osys = rp(g + 0x6A0)
  out.operatives_networks_world = (O.kptr(osys) and rp(osys) == BASE + OPS2.mgr_vt)
      and ((self:operatives() or {}).networks) or nil
  local sg = self:selection_groups()
  out.selection_groups_nonempty = sg and sg.non_empty or nil
  local pc = self:peace_conference()
  out.peace_conferences_active = pc and pc.count or nil
  out.programs_total, out.projects_started = 0, 0
  local pcd, pcn = rp(g + 0x310), ru32(g + 0x31C)
  if O.kptr(pcd) and pcn and pcn < 4096 then
    for i = 0, pcn - 1 do
      local c = rp(pcd + 8 * i)
      if O.kptr(c) and rp(c) == BASE + 0x27E7360 then
      local ps = rp(c + 4008)   -- §4.7.9 CSpecialProjectStatus
      if O.kptr(ps) and rp(ps) == BASE + GAME.layout.vt.CSpecialProjectStatus then
        local pn = ru32(ps + 44)
        if pn and pn > 0 and pn < 256 then
          out.programs_total = out.programs_total + pn end
        -- ⚠ 勘误: projects_started 计数 = 项目池扫描 (legacy L6957-
        -- L6968): pool=rp(ps+24) vt 0x29c6e28, {d@pool+16, c@pool+28},
        -- 448B 元素, 门 (E+444)%256==1; 原 ps+8*pi 伪容器读法恒 0
        local pool = rp(ps + 24)
        if O.kptr(pool) and rp(pool) == BASE + GAME.layout.vt.CSpecialProjectPool then
          local pdd, pdc = rp(pool + 16), ru32(pool + 28)
          if O.kptr(pdd) and pdc and pdc < 4096 then
            for k = 0, pdc - 1 do
              local E = pdd + 448 * k
              if (ru32(E + 444) or 0) % 256 == 1 then
                out.projects_started = out.projects_started + 1 end
            end
          end
        end
      end
      end
    end
  end
  return out
end



-- ============================================================
-- §4.23.2 库存 / §4.8 可用装备 / §4.18 解锁兵种
-- ============================================================
-- §4.23.2 stockpile 装备库存 (mgr=cc+3944 CProductionStatus; 池锚/门/原型 map = 书 §4.23.2)
function Country.stockpile(self)
  local mgr = rp(self.addr + 0xF68)
  if not O.kptr(mgr) then return nil end
  local list, by_variant_id = {}, {}
  local ed, en = rp(mgr + 0x220), ru32(mgr + 0x22C)
  if O.kptr(ed) and en and en > 0 and en < 50000 then
    for i = 0, en - 1 do
      local p = rp(ed + 16 * i)
      local amt = rp(ed + 16 * i + 8)
      if O.kptr(p) then
        local rec = { variant_id = ru32(p + 0xC),
          key_token = ru32(p + 0x18),
          amount = amt and amt * 1e-5 or 0 }
        list[#list + 1] = rec
        if rec.variant_id then by_variant_id[rec.variant_id] = rec end
      end
    end
  end
  local by_archetype = {}
  do                                  -- 原型汇总 map 24B @+0x208
    local md, mn = rp(mgr + 0x208), ru32(mgr + 0x214)
    if O.kptr(md) and mn and mn > 0 and mn < 50000 then
      for i = 0, mn - 1 do
        local e = md + 24 * i
        local b = rp(e)
        local amt = rp(e + 16)
        if O.kptr(b) and amt then
          local key = LAYOUT.token_name(ru32(b + 8)) or ru32(b + 8)
          by_archetype[key] = amt * 1e-5
        end
      end
    end
  end
  return { addr = mgr, list = list, by_variant_id = by_variant_id,
    by_archetype = by_archetype }
end

-- §4.8 available_equipments 可用装备 (ps=cc+3944 {d@160, c@172})
function Country.available_equipments(self)
  local ps = rp(self.addr + 3944)
  if not O.kptr(ps) then return nil end
  local out = { count = ru32(ps + 172) or 0, list = {} }
  for _, v in O.vec(ps, 160, 172, 8, true) do
    if O.kptr(v) then out.list[#out.list + 1] = { id = ru32(v + 12) } end
  end
  return out
end

-- §4.18 CDeployment unlocked_subunits 解锁兵种 (MSVC std::set @dep+56, dep=cc+3952; writer 0x140CFFF30; MSVC tree next)
function Country.unlocked_subunits(self)
  local dep = rp(self.addr + 3952)
  if not O.kptr(dep) then return { count = 0, list = {} } end
  local head = rp(dep + 56)
  if not O.kptr(head) then return { count = 0, list = {} } end
  local out = { count = 0, list = {} }
  local m = rp(head)
  local n = 0
  local isnil = function(p) return (ru32(p + 0x19) & 0xFF) ~= 0 end
  while m and isnil(m) == false and n < 200 do
    n = n + 1
    local tkn = ru32(m + 0x1C)
    local flag = ru32(m + 0x20) & 0xFF
    out.list[#out.list + 1] = { token = tkn,
      name = tkn and LAYOUT.token_name(tkn) or nil,
      unlocked = flag == 1 }
    -- legacy L1447-1465 语义: right 为真节点 → 下降到右子树最左;
    -- right 为空/哨兵 → 向上爬 (m 是父的右孩子则继续爬)
    local right = rp(m + 0x10)
    if right and right ~= 0 and isnil(right) == false then
      local v = right
      while v and isnil(v) == false do
        m = v
        v = rp(v)
      end
    else
      local k = rp(m + 8)
      while k and isnil(k) == false do
        if m == rp(k + 0x10) then
          m = k
          k = rp(m + 8)
        else
          break
        end
      end
      m = k
    end
  end
  out.count = n
  return out
end



-- ============================================================
-- §4.7.9 CSpecialProjectStatus 特殊项目 (1.19; S=cc+4008 vtable 0x2971838; 池 vt 0x29c6e28;
-- program vt 见 PROG2.program_vt; breakthrough map vt 0x296BE28)
-- ============================================================
local PROG2 = { status_vt = GAME.layout.vt.CSpecialProjectStatus,
  pool_vt = GAME.layout.vt.CSpecialProjectPool,
  program_vt = GAME.layout.vt.CSpecialProject,
  -- ⚠ 勘误: bt_vt 原写 0x296BE28 → CBreakthroughProgress vtable
  -- 校验恒败 → breakthrough=nil → BTX specialization_* 全缺 (1756 行)。
  -- legacy 定案值 = 0x2a2c040 (objects_legacy L2431-2437)
  bt_vt = 0x2a2c040 }
local to_i32 = LAYOUT.as_i32
local to_i16 = LAYOUT.as_i16

function Country.program_status(self)
  local S = rp(self.addr + 4008)
  if not O.kptr(S) or rp(S) ~= BASE + PROG2.status_vt then return nil end
  local out = { addr = S }
  -- project_pool: 448B 元素 (writer 0x14220B400: id@E+12, type@E+8)
  out.pool = { count = 0, list = {} }
  local P = rp(S + 24)
  if O.kptr(P) and rp(P) == BASE + PROG2.pool_vt then
    for _, E in O.vec(P, 16, 28, 448, false) do
      local p = { id = ru32(E + 12), name_token = ru32(E + 24) }
      local m = rp(E + 40)
      if O.kptr(m) then
        p.current_state = ru32(rp(m + 8) + 120)
        p.project_progress = ru32(m + 160)
        p.iterations = ru32(m + 164)
        local ph = rp(m + 96)
        p.phase_progress = ph and ph * 1e-5 or nil
        local phs = rp(m + 432)               -- stopping_state 内嵌
        p.phase_progress_stopping = phs and phs * 1e-5 or nil
      end
      p.start = (ru32(E + 444) or 0) % 256
      p.completed = (ru32(E + 445) or 0) % 256
      -- fire_only_once: u32 token 数组 (count==0 writer 整块不写)
      do
        local fd, fn = rp(E + 48), ru32(E + 60)
        if O.kptr(fd) and fn and fn > 0 and fn < 65536 then
          p.fire_only_once = {}
          for k2 = 0, fn - 1 do
            p.fire_only_once[#p.fire_only_once + 1] =
                LAYOUT.token_name(ru32(fd + 4 * k2))
                or ("?" .. tostring(ru32(fd + 4 * k2)))
          end
        end
      end
      -- history 88B 元素 (尾插+正序 → 存档 #N 序 = data[N-1])
      do
        local hd, hn = rp(E + 104), ru32(E + 116)
        if O.kptr(hd) and hn and hn > 0 and hn < 256 then
          p.history = {}
          for k2 = 0, hn - 1 do
            local H = hd + 88 * k2
            local C = H + 16
            local he = {
              prototype_reward = LAYOUT.token_name(ru32(H + 8)) or "undefined",
              option = LAYOUT.token_name(ru32(H + 12)) or "undefined",
              hours = to_i32(ru32(H + 72)),
              prov = to_i32(ru32(C + 8)),
              cprog = ru32(C + 12) or 0,
              ctype = to_i32(ru32(C + 16)),
              cid = to_i32(ru32(C + 20)) }
            -- character 双 0xFFFFFFFF (无效态) 与 {0,0} (真零) 均不导
            if he.ctype <= 0 and he.cid <= 0 then
              he.ctype, he.cid = nil, nil
            end
            local ctry_f = ru32(C + 28) & 0xFF
            if ctry_f and ctry_f ~= 0 then he.country = ru32(C + 24) end
            local sci_f = ru32(C + 36) & 0xFF
            if sci_f and sci_f ~= 0 then he.scientist = ru32(C + 32) end
            local st_f = ru32(C + 44) & 0xFF
            if st_f and st_f ~= 0 then he.state = ru32(C + 40) end
            p.history[#p.history + 1] = he
          end
        end
      end
      -- flags 内嵌@E+368 (writer 0x140CB0870; token=0 墓碑跳过)
      do
        local M = E + 368
        for _, F in O.vec(M, 8, 20, 48, false) do
          local ftok = ru32(F + 8)
          if ftok and ftok > 0 then
            p.flags = p.flags or {}
            p.flags[#p.flags + 1] = {
              name = LAYOUT.token_name(ftok) or ("?" .. tostring(ftok)),
              hours = to_i32(ru32(F + 24)),
              value = to_i16(ru32(F + 40)),
              days = to_i16(ru32(F + 42)) }
          end
        end
      end
      out.pool.count = out.pool.count + 1
      out.pool.list[#out.pool.list + 1] = p
    end
  end
  -- §4.7.9 programs (进行中实例)
  out.programs = {}
  for _, Pr in O.vec(S, 32, 44, 8, true) do
    if O.kptr(Pr) and rp(Pr) == BASE + PROG2.program_vt then
      -- MSVC SSO 双形态 (nuclear_facility=16 字符走堆)
      local bs = {}
      local bstr = U.sso(Pr + 32)
      if bstr then bs[1] = bstr end
      local sup = { tag_id = ru32(Pr + 368), province_id = ru32(Pr + 372),
        id = ru32(Pr + 212), id_type = ru32(Pr + 208),
        motorization_level = (ru32(Pr + 229) or 0) % 256,
        disrupted_supply = rp(Pr + 360) }
      local pg = { addr = Pr,
        id = ru32(Pr + 12), id_type = ru32(Pr + 8),
        country_tag_id = ru32(Pr + 24), province = ru32(Pr + 28),
        building = table.concat(bs),
        project_token = (ru32(Pr + 84) or 0) % 256 == 1
            and ru32(Pr + 80) or nil,
        scientist = { type = ru32(Pr + 88), id = ru32(Pr + 92) },
        delayed_unassigned = { target = ru32(Pr + 104),
          current = ru32(Pr + 108) },
        dismantle = { target = ru32(Pr + 144), current = ru32(Pr + 148) },
        supportive_scientists = {},
        supply = sup,
        unread_prototype_rewards = ru32(Pr + 376) }
      for _, e in O.vec(Pr, 176, 188, 48, false) do
        pg.supportive_scientists[#pg.supportive_scientists + 1] = {
          type = ru32(e), id = ru32(e + 4),
          target = ru32(e + 16), current = ru32(e + 20) }
      end
      out.programs[#out.programs + 1] = pg
    end
  end
  -- breakthrough (RB-tree 中序: nuclear/naval/air/land;
  -- ⚠ spec_id 在 node+0x1c, +0x18 是颜色位; value@+0x20)
  local B = S + 80
  if rp(B) == BASE + PROG2.bt_vt then
    local hdr, cnt = rp(B + 8), ru32(B + 16)
    local vals = {}
    if O.kptr(hdr) and cnt and cnt > 0 and cnt < 64 then
      local bt_walk
      bt_walk = function(n, depth)
        if not O.kptr(n) or n == hdr or depth > 16 or #vals > 32 then
          return end
        bt_walk(rp(n), depth + 1)
        vals[#vals + 1] = { value = ru32(n + 0x20), spec_id = ru32(n + 0x1c) }
        bt_walk(rp(n + 0x10), depth + 1)
      end
      bt_walk(rp(hdr + 8), 0)
    end
    out.breakthrough = { count = cnt, list = vals }
  end
  return out
end



-- ============================================================
-- §4.3.9 名字组 / §4.3.1 国策减免 / §4.24 剧场
-- ============================================================
-- §4.3.9 CNameGroupTracker 名字组 (tracker = cc+112 + 8×mode; 布局/mode 表 = 书 §4.3.9)
function Country.name_groups(self, mode)
  local t = rp(self.addr + 112 + 8 * (mode or 0))
  if not O.kptr(t) then return nil end
  local out = { addr = t, unavailable = { count = 0 }, available = { count = 0 } }
  local function grplist(doff, coff, dst)
    for _, g in O.vec(t, doff, coff, 8, true) do
      local nm
      if O.kptr(g) then
        local p = rp(g + 8)
        -- legacy 同链 (Objects.name_groups): read_cstr 裸串优先。U.cstr =
        -- hoi4.read_str 智能 reader 吃 std::string 对象首址, 名为裸 char
        -- 缓冲时误读 size=0 → 空串 (truthy) → NGRX 空值
        if O.kptr(p) then nm = hoi4.read_cstr(p) or hoi4.read_str(p) end
        if not nm then nm = LAYOUT.read_msvc_str(g + 8) end
      end
      dst[#dst + 1] = nm
    end
    dst.count = ru32(t + coff) or 0
  end
  grplist(16, 28, out.unavailable)
  grplist(40, 52, out.available)
  -- §4.3.9 post_mortem 第三容器 (176B CNameGroupMember 元素; 记录布局/写门 = 书 §4.3.9)
  out.post_mortem = { count = ru32(t + 84) or 0, list = {} }
  do
    local pmd, pmc = rp(t + 72), ru32(t + 84)
    if O.kptr(pmd) and pmc and pmc > 0 and pmc < 4096 then  -- 256 字面量被 post_mortem count 761 击穿
      for i = 0, pmc - 1 do
        local e = pmd + 176 * i
        local rec = { type = ru32(e + 8) or 0 }
        local no = ru32(e + 128)
        if no and no ~= 0 then rec.name_order = no end
        local ov = U.sso(e + 136)
        if ov and #ov > 0 then rec.override = ov end
        rec.is_name_ordered = (ru8(e + 168) or 0) == 0 and "no" or nil
        local osp = ru8(e + 169)
        if osp and osp ~= 0 then rec.override_set_programmatically = "yes" end
        local eqp = rp(e + 80)
        if O.kptr(eqp) then
          rec.equipment = string.format("id=%d type=%d",
              ru32(eqp + 12) or 0, ru32(eqp + 8) or 0)
        end
        out.post_mortem.list[#out.post_mortem.list + 1] = rec
      end
    end
  end
  return out
end

-- §4.3.1 CReducedFocusCost 国策花费减免 (RH 表@cc+5016; 上界 = count@5028+1+extra@5032;
-- dist 合法域 1..32 + 键名形态校验防脏桶)
function Country.focus_cost_reduction(self)
  local out = {}
  local ent = rp(self.addr + 5016)
  local cnt2 = ru32(self.addr + 5028) or 0
  if not O.kptr(ent) or cnt2 <= 0 or cnt2 > 4096 then return out end
  local extra = ru32(self.addr + 5032) & 0xFF
    for k = 0, cnt2 + extra do
      local e = ent + 48 * k
      local d4 = ru32(e + 4) & 0xFF
      if d4 >= 1 and d4 <= 32 then
        local kp = rp(e + 8)
        -- ⚠ 裸 char 串指针必须 hoi4.read_cstr (legacy L9039);
        -- U.cstr(read_str 智能 reader) 返 "?" → #name>=4 门全滤 → FCR 0 行
        -- 短键 (≤7 字符) 内联存于 e+8 本身
        -- (kp = ASCII 字节非指针, 越出指针域时按内联 cstr 读)
        local name
        if kp and kp > 0x10000 and kp < 0x7FFFFFFFFFFF then
            name = hoi4.read_cstr(kp)
        else
            name = hoi4.read_cstr(e + 8)
        end
        if name and #name >= 4 and #name <= 80
            and name:match("^[%w_%./-]+$") then  -- 补 '-' (连字符 focus 名曾被滤)
          -- 值有符号 i32 (负减免 -5 ↔ raw 0xFFFFFFFB, AST_a_change_of_authority 实证)
          local fcval = ru32(e + 40) or 0
          fcval = LAYOUT.as_i32(fcval)
          out[#out + 1] = { key = name, value = fcval }
        end
      end
    end
  return out
end

-- §4.24.2 CTheatre 剧场 (容器 {data@cc+360, count@cc+372}; 0x1D0
-- vt 0x2975a48; 全局计数器 0x3087260/70/74)
function Runtime.theatres(self, country_idx)
  local cc = self:country(country_idx)
  if not cc then return nil end
  local out = {
    order_index = ru32(BASE + 0x3087260),
    front_index = ru32(BASE + 0x3087264),
    theatre_index = ru32(BASE + 0x3087268),
    list = {} }
  local td, tc = rp(cc.addr + 360), ru32(cc.addr + 372)
  if not O.kptr(td) or not tc or tc <= 0 or tc > 32 then return out end
  out.count = tc
  for i = 0, tc - 1 do
    local th = rp(td + 8 * i)
    if O.kptr(th) then
      local trec = { addr = th, area_count = ru32(th + 36) or 0,
        orders_groups = {} }
      -- §4.24.3 COrdersGroup orders_groups {d@128, c@140}
      for _, og in O.vec(th, 128, 140, 8, true) do
        if O.kptr(og) then
          local grec = { name = U.cstr(og + 352), icon = ru32(og + 288),
            plan_value = U.fix5(og + 304), our_power = U.fix5(og + 312),
            enemy_power = U.fix5(og + 320), execution_type = ru32(og + 420),
            field_marshal_group = (ru32(og + 57) & 0xFF) == 1,
            motorization_level = ru32(og + 56) & 0xFF,
            order_instances = {} }
          -- §4.24.5 COrderInstance order_instances {d@152, c@164}
          for _, oi in O.vec(og, 152, 164, 8, true) do
            if O.kptr(oi) then
              grec.order_instances[#grec.order_instances + 1] = {
                type = ru32(oi + 48), instance_id = ru32(oi + 580),
                area_defense_settings = ru32(oi + 248),
                states_count = ru32(oi + 236) or 0,
                adsa_count = ru32(oi + 268) or 0,
                route_is_ok = (ru32(oi + 282) & 0xFF) == 1 }
            end
          end
          trec.orders_groups[#trec.orders_groups + 1] = grec
        end
      end
      out.list[#out.list + 1] = trec
    end
  end
  return out
end


-- ============================================================

-- ============================================================
-- §4.24 theatres 导出全量 reader (sv2_sec_c_theatres 只持写序/块键/编号/
-- 值格式化)。writer 忠实; 与 Runtime.theatres 旧探针形并存 (旧 name 走
-- cstr、容器门 ≤32 与段实证 ≤64 有差, 发射以本函数为准)。
-- ⚠ fix5 = i64 ×1e-5 乘式 (本域段实证; 勿改 /100000)。
local function thr_tagstr(tid)          -- §1.2 tag 串表 (门 >0 <100000)
  if not tid or tid <= 0 or tid >= 100000 then return nil end
  return Runtime:tag(tid)
end
local function thr_fix5(a) return (rp(a) or 0) * 1e-5 end

-- sub_140C91860 族: u32 数组 {data@c, count@c+12} (门 >0 <1e6)
local function thr_u32list(c)
  local d, n = rp(c), ru32(c + 12)
  if not O.kptr(d) or not n or n <= 0 or n >= 1000000 then return nil end
  local t = {}
  for i = 0, n - 1 do t[#t + 1] = ru32(d + 4 * i) or 0 end
  return t
end
-- ptr 数组 {data@c, count@c+12}, 值 = ru32(elem+off) (kptr 过滤)
local function thr_ptrlist1(c, off)
  local d, n = rp(c), ru32(c + 12)
  if not O.kptr(d) or not n or n <= 0 or n >= 1000000 then return nil end
  local t = {}
  for i = 0, n - 1 do
    local e = rp(d + 8 * i)
    if O.kptr(e) then t[#t + 1] = ru32(e + off) or 0 end
  end
  return (#t > 0) and t or nil
end
-- 16B 指针对数组平铺 ru32(ptr+164)
local function thr_pairlist(c)
  local d, n = rp(c), ru32(c + 12)
  if not O.kptr(d) or not n or n <= 0 or n >= 1000000 then return nil end
  local t = {}
  for i = 0, n - 1 do
    local pa, pb = rp(d + 16 * i), rp(d + 16 * i + 8)
    if O.kptr(pa) then t[#t + 1] = ru32(pa + 164) or 0 end
    if O.kptr(pb) then t[#t + 1] = ru32(pb + 164) or 0 end
  end
  return (#t > 0) and t or nil
end
-- §4.24.9 member 族: 元素 = unit+184, ref 对在 unit+24 {type@24, id@28}
local function thr_unit_ref(e)
  if not O.kptr(e) or e < 0x10000 + 184 then return nil end
  local b = e - 184
  local ty, id = ru32(b + 24), ru32(b + 28)
  if ty and id and ty > 0 and ty < LAYOUT.lim.PTR_HUGE and id < 0xFFFFFFF then
    return { type = ty, id = id }
  end
  return nil
end
local function thr_member_list(c)
  local d, n = rp(c), ru32(c + 12)
  if not O.kptr(d) or not n or n <= 0 or n >= LAYOUT.lim.PTR_HUGE then
    return nil end
  local t = {}
  for i = 0, n - 1 do
    local r = thr_unit_ref(rp(d + 8 * i))
    if r then t[#t + 1] = r end
  end
  return t
end

-- §4.24.5 COrderInstance (order_instance/fallback/virtual_fallback 同类)
local function thr_oi(oi, sent)
  if not O.kptr(oi) then return nil end
  local rec = {}
  local otype = ru32(oi + 48) or 0
  rec.otype = otype
  if otype == 3 then -- convoys 块先于 type (CConvoySubscriber@+8)
    rec.convoys = { convoys = ru32(oi + 16) or 0, total = ru32(oi + 20) or 0 }
  end
  rec.path = thr_u32list(oi + 112)
  rec.states = thr_u32list(oi + 224)
  rec.instance_id = ru32(oi + 580) or 0
  rec.virtual_order = (ru8(oi + 665) or 0) ~= 0
  local vc = ru32(oi + 668)
  if vc and vc ~= 0 then rec.virtual_creator = vc end
  local ch = ru32(oi + 72)
  if ch and ch ~= 0 then rec.creation_h = ch end
  local sh = ru32(oi + 96)
  if sh and sh ~= 0 then rec.starting_h = sh end
  rec.virtually_created = thr_u32list(oi + 672)
  local function sso_key(key, base)   -- 门 size@base+16≠0 + 串非空
    if (rp(base + 16) or 0) ~= 0 then
      local s = U.sso(base)
      if s and s ~= "" then rec[key] = s end
    end
  end
  sso_key("operation", oi + 288)
  sso_key("unique", oi + 384)
  sso_key("first", oi + 320)
  sso_key("second", oi + 352)
  sso_key("prefix", oi + 416)
  sso_key("postfix", oi + 448)
  do -- floating_harbor (id 对 +920/+924 非零才写) + hp (i64@+928 ≠0)
    local fht, fhi = ru32(oi + 920), ru32(oi + 924)
    if (fht or 0) ~= 0 or (fhi or 0) ~= 0 then
      rec.floating_harbor = { type = fht or 0, id = fhi or 0 }
      local fhp = rp(oi + 928) or 0
      if fhp ~= 0 then rec.floating_harbor_hp = fhp end
    end
  end
  if (ru32(oi + 148) or 0) > 0 then
    rec.sorted_pairs = thr_pairlist(oi + 136)
    rec.sorted_pairs_from = ru32(oi + 160) or 0
    rec.sorted_pairs_to = ru32(oi + 164) or 0
  end
  do -- enemy_controller_area 缓存链
    local ca = rp(oi + 168)
    if O.kptr(ca) and (ru32(ca + 60) or 0) > 0 then
      local a2p = rp(ca + 40)
      local lp = O.kptr(a2p) and rp(a2p + 184) or nil
      if O.kptr(lp) and ((ru8(lp + 210) or 0) & 1) == 1 then
        rec.enemy_controller_area = ru32(a2p + 164) or 0
      end
    end
  end
  local cex = ru8(oi + 584)
  if cex and cex ~= 0 then rec.can_execute = cex end
  rec.scheduled_members = thr_member_list(oi + 528)
  rec.transported_members = thr_member_list(oi + 552)
  local atm = ru32(oi + 576)
  if atm and atm ~= 0 then rec.all_transported_members = atm end
  do -- order_children / virtual: 值 = ru32(elem+580)
    local cd, cn = rp(oi + 504), ru32(oi + 516)
    if O.kptr(cd) and cn and cn > 0 and cn < 4096 then
      rec.order_children = {}
      for i = 0, cn - 1 do
        local e = rp(cd + 8 * i)
        if O.kptr(e) then
          rec.order_children[#rec.order_children + 1] = ru32(e + 580) or 0
        end
      end
    end
    local vd, vn = rp(oi + 720), ru32(oi + 732)
    if O.kptr(vd) and vn and vn > 0 and vn < 4096 then
      rec.order_virtual_children = {}
      for i = 0, vn - 1 do
        local e = rp(vd + 8 * i)
        if O.kptr(e) then
          rec.order_virtual_children[#rec.order_virtual_children + 1] =
            ru32(e + 580) or 0
        end
      end
    end
  end
  local inv = ru32(oi + 184)
  if inv and inv ~= 0 then rec.invasion_source = inv end
  rec.blitz = (ru8(oi + 280) or 0) ~= 0
  if rec.blitz then rec.blitz_provinces = thr_u32list(oi + 800) end
  rec.withdraw = (ru8(oi + 281) or 0) ~= 0
  if rec.withdraw then
    local wd, wn = rp(oi + 856), ru32(oi + 868)
    if O.kptr(wd) and wn and wn > 0 and wn < 4096 then
      local wl = {}
      for i = 0, wn - 1 do
        local e = wd + 24 * i
        local d2, n2 = rp(e), ru32(e + 12)
        if O.kptr(d2) and n2 and n2 > 0 and n2 < LAYOUT.lim.PTR_HUGE then
          local t = {}
          for j = 0, n2 - 1 do t[#t + 1] = ru32(d2 + 4 * j) or 0 end
          wl[i + 1] = t                 -- 槽序 (内门失败槽占号不发射)
        end
      end
      rec.withdraw_lines = wl
      rec.withdraw_lines_n = wn
    end
  end
  if (rp(oi + 600) or 0) ~= sent then -- root_front 守卫 (哨兵=无效)
    rec.root_front = { type = ru32(oi + 600) or 0, id = ru32(oi + 604) or 0 }
    local rs = ru32(oi + 608)
    if rs and rs ~= 0 then rec.root_section = rs end
    if (rp(oi + 616) or 0) ~= 0 or (rp(oi + 624) or 0) ~= 100000 then
      rec.root_from = thr_fix5(oi + 616)
      rec.root_to = thr_fix5(oi + 624)
    end
    local sf = ru32(oi + 632)
    if sf and sf ~= 0 then rec.split_from = sf end
  end
  rec.midpoints = thr_u32list(oi + 640)
  rec.fallback = (ru8(oi + 664) or 0) ~= 0
  if (rp(oi + 216) or 0) ~= 0 then rec.time = thr_fix5(oi + 216) end
  local ads = ru32(oi + 248)
  if ads and ads ~= 0 then rec.area_defense_settings = ads end
  do -- area_defense_state_assignment: stride32, 每元一单行叶 (重复裸键)
    local d, n = rp(oi + 256), ru32(oi + 268)
    if O.kptr(d) and n and n > 0 and n < LAYOUT.lim.PTR_HUGE then
      rec.area_defense = {}
      for i = 0, n - 1 do
        local e = d + 32 * i
        local t = { ru32(e) or 0 }
        local d2, n2 = rp(e + 8), ru32(e + 20)
        if O.kptr(d2) and n2 and n2 > 0 and n2 < 4096 then
          for j = 0, n2 - 1 do
            t[#t + 1] = ru32(d2 + 8 * j) or 0
            t[#t + 1] = ru32(d2 + 8 * j + 4) or 0
          end
        end
        rec.area_defense[#rec.area_defense + 1] = t
      end
    end
  end
  rec.route_is_ok = (ru8(oi + 282) or 0) ~= 0
  local att = rp(oi + 888)
  if O.kptr(att) then
    rec.attach = { type = ru32(att + 8) or 0, id = ru32(att + 12) or 0 }
  end
  rec.manage_child_sections = ru8(oi + 880) or 0 -- 原字节 (yn1 段层)
  do -- faction_theaters: fix5 数组单行叶
    local fd, fn = rp(oi + 936), ru32(oi + 948)
    if O.kptr(fd) and fn and fn > 0 and fn < 4096 then
      local t = {}
      for i = 0, fn - 1 do
        t[#t + 1] = (rp(fd + 8 * i) or 0) * 1e-5 end
      rec.faction_theaters = t
    end
  end
  return rec
end

-- §4.24.3 COrdersGroup / §4.24.4 CArmyGroup
local function thr_og(og, is_fmg, sent)
  if not O.kptr(og) then return nil end
  local rec = {}
  if is_fmg then -- CArmyGroup 先写子 orders_group 引用 + collapse
    local d, n = rp(og + 560), ru32(og + 572)
    if O.kptr(d) and n and n > 0 and n < 4096 then
      rec.sub_orders_groups = {}
      for i = 0, n - 1 do
        local e = rp(d + 8 * i)
        if O.kptr(e) then
          rec.sub_orders_groups[#rec.sub_orders_groups + 1] = {
            type = ru32(e + 8) or 0, id = ru32(e + 12) or 0 }
        end
      end
    end
    rec.collapse = (ru8(og + 584) or 0) ~= 0
  end
  rec.id_type = ru32(og + 8) or 0
  rec.id_id = ru32(og + 12) or 0
  if (rp(og + 368) or 0) ~= 0 then
    local nm = U.sso(og + 352)
    if nm and nm ~= "" then rec.name = nm end
  end
  do -- §4.24.9 order_instance 家族树展开 (根 vec +152/+164; 先序去重)
    local list, seen = {}, {}
    local function collect(o, offd, offc)
      local d, n = rp(o + offd), ru32(o + offc)
      if O.kptr(d) and n and n > 0 and n < 4096 then
        for i = 0, n - 1 do
          local ch = rp(d + 8 * i)
          if O.kptr(ch) then
            if not seen[ch] then
              seen[ch] = true
              list[#list + 1] = ch
            end
            collect(ch, offd, offc)
          end
        end
      end
    end
    local rd, rn = rp(og + 152), ru32(og + 164)
    if O.kptr(rd) and rn and rn > 0 and rn < 4096 then
      for i = 0, rn - 1 do
        local root = rp(rd + 8 * i)
        if O.kptr(root) then
          if not seen[root] then
            seen[root] = true
            list[#list + 1] = root
          end
          collect(root, 504, 516)  -- order_children
          collect(root, 720, 732)  -- order_virtual_children
        end
      end
    end
    rec.order_instances = {}
    for _, oi in ipairs(list) do
      local r = thr_oi(oi, sent)
      if r then rec.order_instances[#rec.order_instances + 1] = r end
    end
  end
  do -- fallback / virtual_fallback (同为 COrderInstance)
    local fd, fn = rp(og + 176), ru32(og + 188)
    if O.kptr(fd) and fn and fn > 0 and fn < LAYOUT.lim.PTR_SANE then
      rec.fallbacks = {}
      for i = 0, fn - 1 do
        local o = thr_oi(rp(fd + 8 * i), sent)
        if o then rec.fallbacks[#rec.fallbacks + 1] = o end
      end
    end
    local vd, vn = rp(og + 200), ru32(og + 212)
    if O.kptr(vd) and vn and vn > 0 and vn < LAYOUT.lim.PTR_SANE then
      rec.virtual_fallbacks = {}
      for i = 0, vn - 1 do
        local o = thr_oi(rp(vd + 8 * i), sent)
        if o then rec.virtual_fallbacks[#rec.virtual_fallbacks + 1] = o end
      end
    end
  end
  do -- member 块 (编号) { unit = id对 }
    local md, mn = rp(og + 80), ru32(og + 92)
    if O.kptr(md) and mn and mn > 0 and mn < LAYOUT.lim.PTR_HUGE then
      rec.members = {}
      for i = 0, mn - 1 do
        local r = thr_unit_ref(rp(md + 8 * i))
        if r then rec.members[#rec.members + 1] = r end
      end
    end
  end
  local lu = rp(og + 104) -- leader_unit (unit+184 视角)
  if O.kptr(lu) then rec.leader_unit = thr_unit_ref(lu) end
  local ld = rp(og + 136) -- §4.4.5 CArmyLeader leader (type@+8 id@+12)
  if O.kptr(ld) then
    rec.leader = { type = ru32(ld + 8) or 0, id = ru32(ld + 12) or 0 }
  end
  do -- pending_incoming_leader ref 对 (+144/+148, 非零才写)
    local t0, i0 = ru32(og + 144), ru32(og + 148)
    if (t0 and t0 ~= 0) or (i0 and i0 ~= 0) then
      rec.pending_incoming_leader = { type = t0 or 0, id = i0 or 0 }
    end
  end
  do -- color 恒写: (int)(f*255) 截断
    local r, g2, b = hoi4.read_f32(og + 272), hoi4.read_f32(og + 276),
      hoi4.read_f32(og + 280)
    if r and g2 and b then
      rec.color = { math.floor(r * 255), math.floor(g2 * 255),
        math.floor(b * 255) }
      local a = hoi4.read_f32(og + 284)
      if a and a ~= 1.0 then rec.color_a = math.floor(a * 255) end
    end
  end
  rec.icon = ru32(og + 288) or 0
  if (rp(og + 292) or 0) ~= sent then -- split_from ref 对
    rec.split_from = { type = ru32(og + 292) or 0, id = ru32(og + 296) or 0 }
  end
  rec.deployed = (ru8(og + 409) or 0) ~= 0
  rec.deploy_queued = (ru8(og + 410) or 0) ~= 0
  rec.expeditionaries = (ru8(og + 408) or 0) ~= 0
  local hq = rp(og + 392) -- §4.24.10 hq_deploy_distributable
  if O.kptr(hq) then
    local h = {}
    local prio = ru32(hq + 8)
    if prio and prio ~= 1 then h.priority = prio end
    h.country = thr_tagstr(ru32(hq + 32))
    do -- §4.24.10 hq_assembled_equipment (16B 元; 门 amt≠0∨az)
      local d, n = rp(hq + 72), ru32(hq + 84)
      local az = ru8(hq + 96) or 0
      h.equipment_az = az
      if O.kptr(d) and n and n > 0 and n < 4096 then
        h.assembled_equipment = {}
        for i = 0, n - 1 do
          local e = d + 16 * i
          local amt = rp(e + 8) or 0
          if amt ~= 0 or az ~= 0 then
            local v = rp(e)
            h.assembled_equipment[#h.assembled_equipment + 1] = {
              type = O.kptr(v) and (ru32(v + 8) or 0) or nil,
              id = O.kptr(v) and (ru32(v + 12) or 0) or nil,
              amount = amt * 1e-5 }
          end
        end
      end
    end
    do -- §4.24.10 hq_requested_equipment (token 名键)
      local d, n = rp(hq + 112), ru32(hq + 124)
      if O.kptr(d) and n and n > 0 and n < 4096 then
        h.requested_equipment = {}
        for i = 0, n - 1 do
          local e = d + 16 * i
          local amt = rp(e + 8) or 0
          if amt ~= 0 then
            local ar = rp(e)
            local tk = O.kptr(ar) and ru32(ar + 8) or nil
            local nm = tk and LAYOUT.token_name(tk) or nil
            if type(nm) == "string" then
              h.requested_equipment[#h.requested_equipment + 1] = {
                name = nm, amount = amt * 1e-5 }
            end
          end
        end
      end
    end
    h.assembled_manpower = ru32(hq + 136) or 0
    h.requested_manpower = ru32(hq + 140) or 0
    h.deploy_order = ru32(hq + 144) or 0
    h.requisitioned_from_army = ru8(hq + 148) or 0 -- 原字节 (yn1 段层)
    rec.hq = h
  end
  do -- target_template ref 对 (+400/+404)
    local t0, i0 = ru32(og + 400), ru32(og + 404)
    if (t0 and t0 ~= 0) or (i0 and i0 ~= 0) then
      rec.target_template = { type = t0 or 0, id = i0 or 0 }
    end
  end
  rec.withdrawing = (ru8(og + 411) or 0) ~= 0
  rec.unassign_on_withdraw = (ru8(og + 412) or 0) ~= 0
  rec.training = (ru8(og + 413) or 0) ~= 0
  rec.stop_training_at_max_xp = (ru8(og + 416) or 0) ~= 0
  rec.plan_value = thr_fix5(og + 304)
  rec.our_power = thr_fix5(og + 312)
  rec.enemy_power = thr_fix5(og + 320)
  rec.members_has_changed = (ru8(og + 414) or 0) ~= 0
  rec.execution_type = ru32(og + 420) or 0
  rec.cohesion_type = ru32(og + 424) or 0
  rec.proximity_type = ru32(og + 428) or 0
  rec.field_marshal_group = ru8(og + 57) or 0  -- 原字节 (yn1 段层)
  rec.motorization_level = ru8(og + 56) or 0
  local function i32_ge0(off)                  -- i32>=0 才写
    local v = ru32(off)
    if v and v < 0x80000000 then return v end
    return nil
  end
  rec.distance = i32_ge0(og + 452)
  rec.hq_nearest_front_province_id = i32_ge0(og + 456)
  rec.hq_distance_to_naval_invasion_source = i32_ge0(og + 460)
  rec.cached_hq_naval_invasion_source_province_id = i32_ge0(og + 464)
  local td = ru32(og + 468)                    -- timeout_days >0 才写
  if td and td ~= 0 and td < 0x80000000 then rec.timeout_days = td end
  return rec
end

-- §4.24.7 CFrontSection
local function thr_section(sec)
  if not O.kptr(sec) then return nil end
  local rec = { id = ru32(sec + 8) or 0 }
  rec.provinces = thr_ptrlist1(sec + 48, 164)
  rec.sorted_pairs = thr_pairlist(sec + 72)
  local pd, pn = rp(sec + 24), ru32(sec + 36)
  if O.kptr(pd) and pn and pn > 0 and pn < LAYOUT.lim.PTR_SANE then
    rec.per_country_sections = {}
    for i = 0, pn - 1 do
      local e = pd + 24 * i
      local tstr = thr_tagstr(ru32(e + 8))
      rec.per_country_sections[#rec.per_country_sections + 1] = {
        country = tstr or "---", index = ru32(e + 12) or 0,
        count = ru32(e + 16) or 0 }
    end
  end
  return rec
end

-- §4.24.6 CFront
local function thr_front(fr)
  if not O.kptr(fr) then return nil end
  local rec = { id_type = ru32(fr + 8) or 0, id_id = ru32(fr + 12) or 0 }
  rec.dirty = ru8(fr + 125) or 0               -- 原字节 (yn1 段层)
  rec.provinces = thr_ptrlist1(fr + 32, 164)
  local ed, en = rp(fr + 56), ru32(fr + 68)
  if O.kptr(ed) and en and en > 0 and en < 4096 then
    local t = {}
    for i = 0, en - 1 do
      local tstr = thr_tagstr(ru32(ed + 4 * i))
      if tstr then t[i + 1] = tstr end         -- 槽序稀疏表保洞
    end
    rec.enemies = t
    rec.enemies_n = en
  end
  rec.id_counter = ru32(fr + 80) or 0
  local sd, sn = rp(fr + 88), ru32(fr + 100)
  if O.kptr(sd) and sn and sn > 0 and sn < 4096 then
    rec.sections = {}
    for i = 0, sn - 1 do
      local sec = thr_section(rp(sd + 8 * i))
      if sec then rec.sections[#rec.sections + 1] = sec end
    end
  end
  local ap = rp(fr + 112)
  local aq = O.kptr(ap) and rp(ap + 40) or nil
  if O.kptr(aq) then rec.area = ru32(aq + 164) or 0 end
  return rec
end

-- §4.24.8 CTheaterGroup
local function thr_tg(tg)
  if not O.kptr(tg) then return nil end
  local rec = { id_type = ru32(tg + 8) or 0, id_id = ru32(tg + 12) or 0,
    priority = ru32(tg + 32) or 0 }
  rec.name = U.sso(tg + 40)                    -- 恒写 (空串照写)
  local d, n = rp(tg + 72), ru32(tg + 84)
  if O.kptr(d) and n and n > 0 and n < 4096 then
    rec.orders_groups = {}
    for i = 0, n - 1 do
      local e = rp(d + 8 * i)
      if O.kptr(e) then
        rec.orders_groups[#rec.orders_groups + 1] = {
          type = ru32(e + 8) or 0, id = ru32(e + 12) or 0 }
      end
    end
  end
  return rec
end

-- Country.theatres_full -> list (§4.24.2 CTheatre; 容器 {cc+360, cc+372},
-- 门 tn ≤64 = 段实证)
function Country.theatres_full(self)
  local cc = self.addr
  if not cc then return nil end
  local sent = rp(BASE + 0x333D528) or 0
  local td, tn = rp(cc + 360), ru32(cc + 372)
  if not (O.kptr(td) and tn and tn > 0 and tn <= 64) then return nil end
  local out = {}
  for i = 0, tn - 1 do
    local th = rp(td + 8 * i)
    if O.kptr(th) then
      local rec = { id_type = ru32(th + 8) or 0, id_id = ru32(th + 12) or 0 }
      local ad, an = rp(th + 24), ru32(th + 36)
      if O.kptr(ad) and an and an > 0 and an < LAYOUT.lim.PTR_HUGE then
        local t = {}
        for j = 0, an - 1 do
          local e = rp(ad + 8 * j)
          local q = O.kptr(e) and rp(e + 40) or nil
          if O.kptr(q) then t[#t + 1] = ru32(q + 164) or 0 end
        end
        if #t > 0 then rec.areas = t end
      end
      local ogd, ogn = rp(th + 128), ru32(th + 140)
      if O.kptr(ogd) and ogn and ogn > 0 and ogn < 4096 then
        rec.orders_groups = {}
        for j = 0, ogn - 1 do
          local og = thr_og(rp(ogd + 8 * j), false, sent)
          if og then rec.orders_groups[#rec.orders_groups + 1] = og end
        end
      end
      local fd, fn = rp(th + 152), ru32(th + 164)
      if O.kptr(fd) and fn and fn > 0 and fn < 4096 then
        rec.field_marshal_groups = {}
        for j = 0, fn - 1 do
          local ag = thr_og(rp(fd + 8 * j), true, sent)
          if ag then
            rec.field_marshal_groups[#rec.field_marshal_groups + 1] = ag
          end
        end
      end
      local gd, gn = rp(th + 200), ru32(th + 212)
      if O.kptr(gd) and gn and gn > 0 and gn < LAYOUT.lim.PTR_SANE then
        rec.theater_groups = {}
        for j = 0, gn - 1 do
          local tg = thr_tg(rp(gd + 8 * j))
          if tg then rec.theater_groups[#rec.theater_groups + 1] = tg end
        end
      end
      local ud, un = rp(th + 104), ru32(th + 116)
      if O.kptr(ud) and un and un > 0 and un < LAYOUT.lim.PTR_HUGE then
        rec.units = {}
        for j = 0, un - 1 do
          local e = rp(ud + 8 * j)
          if O.kptr(e) then
            rec.units[#rec.units + 1] = { type = ru32(e + 24) or 0,
              id = ru32(e + 28) or 0 }
          end
        end
      end
      local frd, frn = rp(th + 80), ru32(th + 92)
      if O.kptr(frd) and frn and frn > 0 and frn < 4096 then
        rec.fronts = {}
        for j = 0, frn - 1 do
          local fr = thr_front(rp(frd + 8 * j))
          if fr then rec.fronts[#rec.fronts + 1] = fr end
        end
      end
      local vt = ru32(th + 272) -- volunteers_theatre (tag_id>0)
      if vt and vt > 0 then rec.volunteers_theatre = thr_tagstr(vt) end
      out[#out + 1] = rec
    end
  end
  return out
end
