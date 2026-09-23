-- objects_world.lua -- 州省 / 和会 / 资源 / 租借 / 海军总部 (对象层域文件)
-- 结构语义详见书: 州省 §4.13-4.14 / 和会 §4.10.26-4.10.27 / 选择组 §4.25.6 /
-- 资源租借 §4.3.1+§4.3.3 (出口条目 §4.8.10 / 租借 §4.23.2) / 海军总部 §4.3.12。
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

-- §8 州与省 (CState vtable 0x2936cc0 / CProvince vtable 0x2971b18)
-- ============================================================
-- 8.1 州 (§4.13 CState; state_id 直查 gs+0x2C8 = §1.2 gs+712 州表;
-- writer 0x1409D4040; owner/controller/manpower 族 = §4.13 主表)
Runtime.state = function(self, state_id)
  local g = self.gs()
  local sarr = g and rp(g + 0x2C8)
  if not O.kptr(sarr) then return nil end
  local st = rp(sarr + 8 * (state_id or 1))
  if not O.vt(st, GAME.layout.vt.CState) then return nil end
  local out = { addr = st, id = state_id }
  out.owner = self:tag(ru32(st + 0xC8))
  out.controller = self:tag(ru32(st + 0xCC))
  out.manpower_available = ru32(st + 0x848)
  out.manpower_locked = ru32(st + 0x84C)
  out.manpower_total = ru32(st + 0x850)
  local sc_ptr = rp(st + 0x898)
  out.state_category = (sc_ptr and sc_ptr >= 0x10000 and GAME.state_category_name)
      and GAME.state_category_name({ state_category = sc_ptr }) or nil
  out.demilitarized = ru32(st + 0x864) & 0xFF
  out.is_border_conflict = ru32(st + 0x865) & 0xFF
  out.extra_shared_slots = ru32(st + 0x858)
  -- §4.13.1 CResistance 内嵌@+0x268=616 (全部 ≠0 才写)
  local rz = st + 0x268
  if O.kptr(rz) then
    out.resistance = (rp(rz + 16) or 0) / 1e5
    out.resistance_speed = (rp(rz + 24) or 0) / 1e5
    out.base_resistance_target = (rp(rz + 32) or 0) / 1e5
    out.resistance_target = (rp(rz + 40) or 0) / 1e5
    out.compliance = (rp(rz + 64) or 0) / 1e5
    out.compliance_speed = (rp(rz + 72) or 0) / 1e5
    local oc = ru32(rz + 80)
    if oc and oc > 0 then out.occupied_country_tag = self:tag(oc) end
    out.operational_status = ru32(rz + 520) & 0xFF
    out.resistance_modifiers = {}
    for _, e in O.vec(rz, 528, 540, 8, true) do
      out.resistance_modifiers[#out.resistance_modifiers + 1] = U.sso(e + 16)
    end
    -- compliance_modifiers {d@rz+552, c@rz+564} 同构 (§4.13.1 +552 名单;
    -- 名 SSO@+16)
    out.compliance_modifiers = {}
    for _, e in O.vec(rz, 552, 564, 8, true) do
      out.compliance_modifiers[#out.compliance_modifiers + 1] = U.sso(e + 16)
    end
    -- force_disable_resistance {d@rz+648, c@rz+660} 元 8B {key tid@0,
    -- value tid@4} (§4.13.1 +648; tid=0 渲染 "---")
    out.force_disable = {}
    local fd, fc = rp(rz + 648), ru32(rz + 660) or 0
    if O.kptr(fd) and fc > 0 and fc < 64 then
      for fe = 0, fc - 1 do
        out.force_disable[#out.force_disable + 1] =
          { ru32(fd + 8 * fe) or 0, ru32(fd + 8 * fe + 4) or 0 }
      end
    end
    -- force_enable_resistance {d@rz+624, c@rz+636} 同构 8B 对
    -- (§4.13.1 +624; writer 0x140F87B70 0x4AA2 块)
    out.force_enable = {}
    local fe_, fec = rp(rz + 624), ru32(rz + 636) or 0
    if O.kptr(fe_) and fec > 0 and fec < 64 then
      for fe2 = 0, fec - 1 do
        out.force_enable[#out.force_enable + 1] =
          { ru32(fe_ + 8 * fe2) or 0, ru32(fe_ + 8 * fe2 + 4) or 0 }
      end
    end
  end
  -- §4.13.2 CVariables 州脚本变量 (指针@+0x7F8=2040; 上界 = count+1+extra;
  -- 过滤 dist==0 与 0xFF; 州 random 种子对 = vo+8/+12, §4.13.2)
  local vowner = rp(st + 0x7F8)
  if O.kptr(vowner) then
    local ebuf = rp(vowner + 0x18)
    local mask = ru32(vowner + 0x24)
    local extra = ru32(vowner + 0x28) & 0xFF
    out.variables = {}
    if O.kptr(ebuf) and mask and mask > 0 and mask < 0x100000 then
      for i = 0, mask + extra do
        local e = ebuf + 0x30 * i
        local dist = ru32(e + 4) & 0xFF
        if dist ~= 0 and dist ~= 0xFF then
          local name = U.sso(e + 8)
          local raw = LAYOUT.i64(e + 0x28)
          if name and name ~= "" and raw then
            out.variables[#out.variables + 1] =
                name .. "|" .. (raw / 100000.0)
          end
        end
      end
    end
    -- 州 random (终解): vo+12/vo+8
    out.random = { (rp(vowner + 8) or 0), (rp(vowner + 12) or 0) }
  end
  -- §4.13.3 CFlagManager flags (指针@+0x540=1344; 条目 0x30:
  -- token@+8, val i16@0x28, exp@0x2A)
  local fm = rp(st + 0x540)
  if O.kptr(fm) then
    out.flags = {}
    for _, e in O.vec(fm, 8, 20, 0x30, false) do
      local key = ru32(e + 8)
      if key and key < 100000 then
        local name = LAYOUT.token_name(key) or ("k" .. key)
        local val = ru32(e + 0x28) or 0
        local v = LAYOUT.as_i16(val & 0xFFFF)
        local expiry = (val >> 16) & 0x7FFF
        out.flags[#out.flags + 1] = name .. "|" .. v .. "|" .. expiry
      end
    end
  end
  -- §4.13.4 SDynamicModifierEntry 动态修正 (容器内嵌@+0x788=1928; 条目 64B)
  out.dynamic_modifiers = {}
  for _, e in O.vec(st, 0x788 + 0x28, 0x788 + 0x34, 64, false) do
    local def = rp(e + 24)
    local name = O.kptr(def) and U.cstr(def + 40) or nil
    local vals = {}
    -- ⚠ 勘误: deref 必须 true (元素 = i64 定点值, 非 8B 指针数组
    -- 省指针形态); false 时 v=元素地址 → sdm 值变 28655978.96576 类指针÷1e5
    for _, v in O.vec(e, 40, 52, 8, true) do
      vals[#vals + 1] = tostring((v or 0) / 1e5)
    end
    local tg = ""
    local tid = ru32(e + 8)
    if tid and tid > 0 then tg = self:tag(tid) or "" end
    -- 第 6 段 = 条目自带州 id u32@+12 (writer sub_140605C80 ADFE0 0x1B7,
    -- >0 才写; GER 烟测定案 — 旧"所在州 id 回显"系误读)
    out.dynamic_modifiers[#out.dynamic_modifiers + 1] = string.format(
        "%s|%d|%s|%d|%s|%d", tostring(name), ru32(e + 32) & 0xFF, tg,
        ru32(e + 16) or 0, table.concat(vals, ","), ru32(e + 12) or 0)
  end
  -- §4.13.5 active_targeted_modifier (RH 表@+0x8E8=2280: data@+8, count@+20,
  -- mask@+0x10; 条目 208B; dist==0 必须跳过 — state 510 崩溃源)
  out.targeted_modifiers = {}
  do
    local ad = rp(st + 0x8E8 + 8)
    local amask = ru32(st + 0x8E8 + 0x10)
    if O.kptr(ad) and amask and amask > 0 and amask < 0x10000 then
      for i = 0, amask do
        local e = ad + 208 * i
        local dist = ru32(e + 4) & 0xFF
        if dist ~= 0 and dist ~= 0xFF then
          local tid = ru32(e + 8)
          if tid then
            local tg = self:tag(tid) or ("i" .. tid)
            out.targeted_modifiers[#out.targeted_modifiers + 1] =
                tg .. "|" .. (ru32(e + 0x20) or 0)
          end
        end
      end
    end
  end
  -- strategic_region_data (§4.13 +2048 strategic locations): data@+2048 =
  -- 平坦 (token,value) u32 对数组, count@+2060 = **序列化对数** (writer 写前
  -- count 对; 40B 粒度只是分配粒度, 越界对为运行时槽 indices/focus_* 不落盘)
  out.strategic_region_data = {}
  local srd_d, srd_n = rp(st + 2048), ru32(st + 2060)
  if O.kptr(srd_d) and srd_n and srd_n > 0 and srd_n <= LAYOUT.lim.PTR_SANE then
    local lexmax = hoi4.read_u32(hoi4.base() + LAYOUT.rva.lexer_token_max)
        or 100000
    for sp = 0, srd_n - 1 do
      local tk = ru32(srd_d + 8 * sp)
      local nm = tk and tk > 0 and tk <= lexmax and LAYOUT.token_name(tk)
          or nil
      if nm then
        out.strategic_region_data[#out.strategic_region_data + 1] =
            nm .. "|" .. (ru32(srd_d + 8 * sp + 4) or 0)
      end
    end
  end
  -- §4.13 CState: +2192 = last_strategic_bombing CGameDate 尾 vt2 槽
  local lb = rp(st + 2192)
  if O.kptr(lb) then
    out.lsb_raw = string.format("%X|%X|%X|%X", ru32(lb) or 0,
        ru32(lb + 4) or 0, ru32(lb + 8) or 0, ru32(lb + 12) or 0)
  end
  return out
end

-- 8.2 省建筑 (省表 gs+0x2B0 = §1.2 gs+688; §4.14.1 CBuildingStatus 内嵌
-- p+400 / §4.14.2 CBuilding 元素; 建筑容器 vtable 0x2999050)
function Runtime.province_buildings(self, province_id)
  local arr = self.gs() and rp(self.gs() + 0x2B0)
  if not O.kptr(arr) then return nil end
  local p = rp(arr + 8 * (province_id or 1))
  if not O.vt(p, GAME.layout.vt.CProvince) then return nil end
  local bs = p + 400
  if rp(bs) ~= BASE + GAME.layout.vt.CBuildingStatus then return nil end
  local out = { addr = bs, province_addr = p, province_id = province_id,
    count = ru32(bs + 68) or 0, list = {} }
  for _, e in O.vec(bs, 56, 68, 8, true) do
    if O.kptr(e) then
      local tkn = ru32(e + 8)
      local lv = ru32(e + 0x40) or 0
      out.list[#out.list + 1] = {
        addr = e, type_token = tkn,
        type = tkn and (LAYOUT.token_name(tkn))
            or ("token_" .. tostring(tkn)),
        level = lv % 65536,
        healthy_levels = math.floor(lv / 65536),
        partial_health = ru32(e + 0x48),
        repair_speed_factor = (rp(e + 80) or 100000) / 100000,  -- ≠1e5 才写
      }
    end
  end
  return out
end

-- 8.3 省附加 (§4.14 CProvince: vp/controller/name/spl; writer 0x140E6CA90)
function Runtime.province_extras(self, province_id)
  local arr = self.gs() and rp(self.gs() + 0x2B0)
  if not O.kptr(arr) then return nil end
  local p = rp(arr + 8 * (province_id or 1))
  if not O.vt(p, GAME.layout.vt.CProvince) then return nil end
  local spl = {}
  -- ⚠ 勘误: 元素 = u32 token (deref=false 发的是地址 → token_<addr>);
  -- legacy L5018: {d@p+320, c@p+332} n<16, ru32 解引用
  -- (§4.14 +320 strategic_province_location)
  do
    local d, n = rp(p + 320), ru32(p + 332)
    if O.kptr(d) and n and n > 0 and n < 16 then
      for i = 0, n - 1 do
        local tok = ru32(d + 4 * i)
        spl[#spl + 1] = (tok and LAYOUT.token_name(tok))
            or ("token_" .. tostring(tok))
      end
    end
  end
  -- controller 写门 (§4.14 +392; writer 0x140E81390): `*(p+392) > 0` 且
  -- `tid != dctl && (!tid || !dctl || !同国(tid,dctl))`; 同国判据 =
  -- sub_140BB52F0 → gs+104 映射表 [tid] == [dctl] (tag 别名对, 傀儡国
  -- 与宗主同槽)。dctl = rp(p+192) 存在时 +200, 否则 sub_140BB3E00 默认槽
  local tid392 = ru32(p + 392) or 0
  local ctl
  if tid392 > 0 then
    local dsrc = rp(p + 192)
    local dctl = 0
    if O.kptr(dsrc) then dctl = ru32(dsrc + 200) or 0 end
    local same = false
    if tid392 == dctl then same = true
    elseif dctl ~= 0 then
      local g = self.gs()
      local mp = g and rp(g + 832)   -- writer: *((_QWORD*)gs + 104) = 字节 832 (§4.14 同国判据)
      if O.kptr(mp) then
        same = (ru32(mp + 4 * tid392) == ru32(mp + 4 * dctl))
      end
    end
    if not same then ctl = self:tag(tid392) end
  end
  -- 省动态名 (§4.14 +64): MSVC 串@+64; 门 = size@+80 ≠ 0
  local pname
  if (ru32(p + 80) or 0) ~= 0 then pname = U.sso(p + 64) end
  return { addr = p, victory_points = ru32(p + 56), controller = ctl,
    spl = spl, name = pname }
end

-- 建筑名表 (token → 名; 与 legacy BLD_NAMES 同步)


-- ============================================================
-- §19 选择组 / 和会 (选择组 = §4.25.6 @gs+0x658 / 和会 = §4.10.26-4.10.27 @gs+0x4E0)
-- ============================================================
-- 19.1 选择组 (§4.25.6; gs+0x658 = §1.2 gs+1624; 槽布局/非空组写门 = 书 §4.25.6)
function Runtime.selection_groups(self)
  local g = self.gs()
  if not g then return nil end
  local out = { addr = g + 0x658, groups = {}, non_empty = 0 }
  local data = rp(g + 0x658)
  if not O.kptr(data) then return out end
  for i = 0, 9 do
    local slot = data + 24 * i
    local cnt = ru32(slot + 12)
    out.groups[i] = { count = cnt or 0, units_data = rp(slot) }
    if cnt and cnt > 0 then out.non_empty = out.non_empty + 1 end
  end
  return out
end

-- 19.2 和会 (§4.10.26 CPeaceConferenceManager 内嵌@gs+0x4E0=1248; 会议/元素
-- 布局 = §4.10.27 CPeaceConference / CConferenceWinnerParticipant / loser 条目;
-- war_score_breakdown = §4.10.5 CWarScoreBreakdown)
function Runtime.peace_conference(self)
  local g = self.gs()
  local mgr = g and (g + 0x4E0)
  if not O.kptr(mgr) or rp(mgr) ~= BASE + 0x2720E48 then
    return { addr = mgr, active = false, count = 0, conferences = {} }
  end
  local out = { addr = mgr, active = false,
    count = ru32(mgr + 20) or 0, conferences = {} }
  if out.count == 0 then return out end
  local data = rp(mgr + 8)
  if not O.kptr(data) then return out end
  out.active = true
  for _, p in O.vec(mgr, 8, 20, 8, true) do
    if O.kptr(p) and rp(p) == BASE + GAME.layout.vt.CPeaceConference then
      local c = { addr = p,
        actor = self:tag(ru32(p + 52)),
        recipient = self:tag(ru32(p + 56)),
        name_state_id = ru32(p + 24),
        winner_scope = ru32(p + 28), loser_scope = ru32(p + 32),
        -- 换槽定案 (writer sub_140E3DED0: 0x4B89=peace_threat@+536,
        -- 0x296B=factor@+40; 旧 reader 写反, 锚件 -1.71287/1 实证)
        peace_threat = U.fix5(p + 536), factor = U.fix5(p + 40),
        time_duration = ru32(p + 624) }
      c.winners = { count = ru32(p + 260) or 0, list = {} }
      for _, e in O.vec(p, 248, 260, 8, true) do
        local w = { addr = e, country = self:tag(ru32(e + 8)),
          original_score = ru32(e + 72), score = ru32(e + 76),
          ratio = U.fix5(e + 112) }
        w.score_distribution = {}
        -- ⚠ u32 数组须 deref (legacy L3953-3957: ru32(dd+4*k))
        do
          local dd2, dc2 = rp(e + 88), ru32(e + 100)
          if O.kptr(dd2) and dc2 and dc2 > 0 and dc2 < 64 then
            for k = 0, dc2 - 1 do
              w.score_distribution[#w.score_distribution + 1] =
                  ru32(dd2 + 4 * k)
            end
          end
        end
        local bk = e + 0x88
        if rp(bk) == BASE + GAME.layout.vt.CWarScoreBreakdown then
          -- (inner writer sub_141166310 与 war_relation 同函数)
          -- lend_lease_sent@+80 / received@+88 (旧 +0x48/+0x50 误);
          -- total_score_before 不在 bk, 在壳 W+144 = e+0x110 (u32)
          w.war_score_breakdown = {
            equipment_damage = U.fix5(bk + 0x10),
            province_capture = U.fix5(bk + 0x18),
            air_damage_str = U.fix5(bk + 0x20),
            strategic_air = U.fix5(bk + 0x28),
            sunk_ship = U.fix5(bk + 0x30),
            convoy_attack = U.fix5(bk + 0x38),
            casualties = U.fix5(bk + 0x40),
            lend_lease_sent = U.fix5(bk + 0x50),
            lend_lease_received = U.fix5(bk + 0x58),
            total_score_before = ru32(e + 0x110) }
        end
        c.winners.list[#c.winners.list + 1] = w
      end
      c.losers = { count = ru32(p + 284) or 0, list = {} }
      for _, e in O.vec(p, 272, 284, 8, true) do
        c.losers.list[#c.losers.list + 1] = {
          addr = e, country = self:tag(ru32(e + 16)),
          screening_ic = ru32(e + 48) }
      end
      out.conferences[#out.conferences + 1] = c
    end
  end
  return out
end



-- ============================================================
-- §20 资源族 (§4.3.1 cc+4600 rs = CCountryResources; 布局补行见 §4.3.3)
-- ============================================================
-- 公共: 本国资源向量 (§4.3.3 rs+48) → 索引→token 名动态映射
-- (mod 新资源自动兼容; 静态 RES_NAMES 表已废 — 悬空引用曾致 4 国整段
-- pcall 吞错)
local function res_slot_map(rs, wide)
  -- wide=true: 不做 ^%w+$ 过滤 (下划线 mod 资源名 raw_mana 等被滤,
  -- grr 解名需要全注册表; export 路径保持原过滤以免扰动已对平叶)
  local m = {}
  local p2 = rp(rs + 24 + 0x10 + 8)
  local c2 = ru32(rs + 24 + 0x10 + 20) or 0
  if O.kptr(p2) and c2 > 0 and c2 < 64 then
    for k2 = 0, c2 - 1 do
      local rid2 = ru32(p2 + 16 * k2 + 8) or 0
      local nm2 = (rid2 ~= 0) and LAYOUT.token_name(rid2)
      if nm2 and (wide or nm2:match('^%w+$')) then m[k2] = nm2 end
    end
  end
  return m
end

-- 20.1 资源出口 (§4.8.10 CResourceExchange 条目; rs+1832 = §4.8.10
-- CTrade 槽表 8 槽 export 阵列 + exported 向量)
function Country.resources_export(self)
  local rs = rp(self.addr + 4600)
  if not O.kptr(rs) or rp(rs) ~= BASE + GAME.layout.vt.CCountryResources then return nil end
  local RES_SLOTS = res_slot_map(rs)
  local NSLOT = 7
  for k2 in pairs(RES_SLOTS) do
    if k2 + 1 > NSLOT then NSLOT = k2 + 1 end
  end
  local out = { count = 0, list = {} }
  local d = rp(rs + 1832)
  -- (writer 槽 0 起, 槽数 u32@rs+1844): 旧 slot=1..NSLOT
  -- 漏槽 0 (oil) 且可读到越界幻槽
  local nslot = ru32(rs + 1844)
  if nslot and nslot > 0 and nslot < 4096 then NSLOT = nslot end
  if O.kptr(d) then
    for slot = 0, NSLOT - 1 do
      local arr = rp(d + 24 * slot)
      local cn = ru32(d + 24 * slot + 12) or 0
      if O.kptr(arr) and cn > 0 and cn < 4096 then
        for j = 0, cn - 1 do
          local el = rp(arr + 8 * j)
          if O.kptr(el) then
            local t = { addr = el, resource = RES_SLOTS[slot],
              id_pair = string.format("id=%d type=%d",
                  ru32(el + 12) or 0, ru32(el + 8) or 0),
              efficiency = U.fix5(el + 72),
              efficiency_due = U.fix5(el + 80),
              request = ru32(el + 120) or 0,
              delivered = U.fix5(el + 152),
              required_cic = ru32(el + 224) or 0,
              lended_cic = ru32(el + 228) or 0 }
            local cp = ru32(el + 24)
            if cp and cp > 0 then t.country = self.R:tag(cp) end
            local rid = ru32(el + 136)
            if rid and rid > 0 and rid < 100000 then
              t.receiver = self.R:tag(rid) end
            local dp = rp(el + 160)
            if O.kptr(dp) then t.destination = ru32(dp + 88) end
            local sp2 = rp(el + 168)
            if O.kptr(sp2) then t.state = ru32(sp2 + 88) end
            -- start/last_recalc: CGameDate 对象@+192/+216, hours 前 8
            t.start_date = U.date(ru32(el + 184))
            t.last_recalc_date = U.date(ru32(el + 208))
            local cst = ru32(el + 44) or 0
            if cst ~= 0 then
              t.convoys_subscriber = { convoys = ru32(el + 40) or 0,
                  total = cst }
            end
            out.list[#out.list + 1] = t
          end
        end
      end
    end
  end
  out.count = #out.list
  -- exported 向量 {d@1464, c@1476} 16B 条 (门 v≠0; token_name 动态名, ≤32)
  out.exported = {}
  for _, e in O.vec(rs, 1464, 1476, 16, false) do
    local v = rp(e) or 0
    if v ~= 0 then
      local rid = ru32(e + 8) or 0
      local nm = (rid ~= 0 and LAYOUT.token_name(rid)) or ("r" .. k)
      out.exported[nm or ("r" .. 0)] = v / 100000
    end
  end
  out.dirty = (ru32(rs + 2000) & 0xFF) == 1 and "yes" or "no"
  return out
end

-- 20.2 资源向量 (§4.3.1 rs; produced/transfer/imported/to_export/base_export/
-- exported 六向量 + to_use keyed 块 0xB0 步长: count≤8 内联@e+0x38, >8 堆 *(e+8))
function Country.resources_vecs(self)
  local rs = rp(self.addr + 4600)
  if not O.kptr(rs) or rp(rs) ~= BASE + GAME.layout.vt.CCountryResources then return nil end
  local base = rs + 24
  local out = {}
  local VECOFFS = { produced = 0x10, transfer_overlord_subject = 0xc0,
    imported = 0x170, to_export = 0x438, base_export = 0x4e8,
    exported = 0x598 }
  for vn, off in pairs(VECOFFS) do
    local p = rp(base + off + 8)
    local c = ru32(base + off + 20) or 0
    if O.kptr(p) and c > 0 and c <= 32 then
      local v = {}
      for k = 0, c - 1 do
        local raw = rp(p + 16 * k) or 0
        local rid = ru32(p + 16 * k + 8) or 0
        local nm = (rid ~= 0) and LAYOUT.token_name(rid) or ("slot" .. k)
        v[nm or ("slot" .. k)] = raw
      end
      out[vn] = v
    end
  end
  local tu = {}
  local ctb = rs + 24 + 0x220
  for j = 0, 2 do
    local e = ctb + 0xB0 * j
    if O.kptr(e) and rp(e) == rp(ctb) then
      local cnt = ru32(e + 0x14) or 0
      local dp = rp(e + 8)
      local heap = dp and O.kptr(dp) and (dp < e or dp >= e + 0xB0)
          and cnt > 8
      local v, any = {}, false
      for k = 0, cnt - 1 do
        local addr = heap and (dp + 16 * k) or (e + 0x28 + 16 * k)
        local rid = ru32(addr + 8) or 0
        if rid ~= 0 then
          local nm = LAYOUT.token_name(rid)
          if nm and nm:match('^[%w_]+$') then
            v[nm] = rp(addr) or 0
            any = true
          end
        end
      end
      if any then tu[tostring(j + 1)] = v end
    end
  end
  if next(tu) then out.to_use = tu end
  return out
end

-- 20.3 资源起源 (§4.3.3 rs+1808 origin 容器 {d@1808, c@1820}, 元素 =
-- §4.3.1 CResourceOrigin, vtable 0x295c370; efficiency 双效率 (72/840);
-- grr 键=资源索引序; delivery_route 内嵌@+848 = CResourceDelivery)
function Country.resources_origin(self)
  local rs = rp(self.addr + 4600)
  if not O.kptr(rs) or rp(rs) ~= BASE + GAME.layout.vt.CCountryResources then return nil end
  local RES_IDX = res_slot_map(rs, true)  -- grr 解名需含下划线 mod 资源
  local function resvec(objoff, el)
    local p = rp(el + objoff + 8)
    local c = ru32(el + objoff + 20) or 0
    local out = {}
    if O.kptr(p) and c > 0 and c <= 4096 then
      for k = 0, c - 1 do
        local v = rp(p + 16 * k) or 0
        local rid = ru32(p + 16 * k + 8) or 0
        local nm = (rid ~= 0 and LAYOUT.token_name(rid)) or ("r" .. k)
        out[nm or ("r" .. k)] = v / 100000
      end
    end
    return out
  end
  local out = { count = ru32(rs + 1820) or 0, list = {} }
  for _, el in O.vec(rs, 1808, 1820, 8, true) do
    if O.kptr(el) and rp(el) == (BASE + GAME.layout.vt.CResourceOrigin) then
      local t = { addr = el,
        id_pair = string.format("id=%d type=%d",
            ru32(el + 12) or 0, ru32(el + 8) or 0),
        efficiency = U.fix5(el + 72),
        efficiency2 = U.fix5(el + 840),
        efficiency_due_to_lost_convoys = U.fix5(el + 80),
        request = ru32(el + 120),
        resources = resvec(136, el),
        resources_unclapmed = resvec(312, el),
        buildings = resvec(664, el) }
      local cp = ru32(el + 24)
      if cp and cp > 0 then t.country = self.R:tag(cp) end
      local sp = rp(el + 128)
      if O.kptr(sp) then t.state = ru32(sp + 88) end
      local dp = rp(el + 976)
      if O.kptr(dp) then t.destination = ru32(dp + 88) end
      t.given_resource_rights = {}
      do
        local gd2, gc2 = rp(el + 992), ru32(el + 1004)
        if O.kptr(gd2) and gc2 and gc2 > 0 and gc2 < 4096 then  -- 上界 4096: 16 字面量曾被 18 资源 mod 的 24 条给权击穿
          for k = 0, gc2 - 1 do
            local ge = gd2 + 8 * k
            local rk, rtid = ru32(ge), ru32(ge + 4)
            local rn = RES_IDX[rk or -1]
            if rn and rtid and rtid > 0 then
              t.given_resource_rights[rn] = self.R:tag(rtid)
            end
          end
        end
      end
      local cst = ru32(el + 44) or 0
      if cst ~= 0 then
        t.convoys_subscriber = { convoys = ru32(el + 40) or 0, total = cst }
      end
      local rt = el + 848                  -- delivery_route 内嵌 (§4.3.1; CResourceDelivery vt 0x295c320)
      if rp(rt) == BASE + GAME.layout.vt.CResourceDelivery then
        local r2 = { type = ru32(rt + 8) % 256,
          sender = ru32(rt + 48), receiver = ru32(rt + 52),
          convoys_owner = ru32(rt + 56),
          -- _c2 2c: blocker_tag tid i32@rt+60 (>0) / blocked_region
          -- ptr@rt+64 → u32@ptr+96
          blocker_tag = (function() local bt = ru32(rt + 60)
              return bt and bt > 0 and self.R:tag(bt) or nil end)(),
          blocked_region = (function() local bp = rp(rt + 64)
              return O.kptr(bp) and ru32(bp + 96) or nil end)(),
          dirty = (ru32(rt + 120) % 256) ~= 0,
          land_path = {}, naval_path = {} }
        local fs = rp(rt + 16)
        if O.kptr(fs) then r2.from_state = ru32(fs + 88) end
        local ts = rp(rt + 24)
        if O.kptr(ts) then r2.to_state = ru32(ts + 88) end
        local fp32 = rp(rt + 32)
        if O.kptr(fp32) then r2.from_port = ru32(fp32 + 164) end
        local tp40 = rp(rt + 40)
        if O.kptr(tp40) then r2.to_port = ru32(tp40 + 164) end
        for _, sp in O.vec(rt, 72, 84, 8, true) do
          r2.land_path[#r2.land_path + 1] =
              O.kptr(sp) and ru32(sp + 88) or nil
        end
        for _, sp in O.vec(rt, 96, 108, 8, true) do
          r2.naval_path[#r2.naval_path + 1] =
              O.kptr(sp) and ru32(sp + 88) or nil
        end
        t.delivery_route = r2
      end
      out.list[#out.list + 1] = t
    end
  end
  return out
end



-- ============================================================
-- §21 租借 (§4.23.2 CLendLeaseExchange; rs+1880{+1892} 容器,
-- 布局 = CConvoyClient 派生全字段; 7 槽装备映射 @216..728)
-- ============================================================
function Country.lend_lease(self)
  local rs = rp(self.addr + 4600)
  if not O.kptr(rs) then return {} end
  local out = {}
  for _, e in O.vec(rs, 1880, 1892, 8, true) do
    local ll = rp(e)
    if not O.kptr(ll) then ll = e end   -- 元素可能是内联 (指针无效时)
    local rec = { id = ru32(ll + 12) or 0, id_type = ru32(ll + 8) or 0 }
    rec.receiver = self.R:tag(ru32(ll + 184)) or "0"
    rec.country = self.R:tag(ru32(ll + 24)) or "0"
    local dp = rp(ll + 200)
    rec.destination = O.kptr(dp) and ru32(dp + 88) or 0
    local op = rp(ll + 208)
    rec.origin = O.kptr(op) and ru32(op + 88) or 0
    rec.sender_convoys = ru32(ll + 144) or 0
    rec.sender_total = ru32(ll + 148) or 0
    rec.request = ru32(ll + 120) or 0
    rec.efficiency = U.fix5(ll + 72) or 0
    rec.efficiency_due = U.fix5(ll + 80) or 0
    rec.last_delivery = ru32(ll + 800) or 0
    rec.active_since = ru32(ll + 824) or 0
    -- fuel: f64 (IEEE754 真浮点, AE9A0) 混 fixed5 —
    -- fuel_percentage@+856 是 fixed5 i64 (非 f64)
    local function f64(a)
      return hoi4.read_f64 and hoi4.read_f64(a) or 0
    end
    rec.fuel_daily = f64(ll + 848)
    rec.fuel_pct = U.fix5(ll + 856)
    rec.fuel_sent = f64(ll + 864)
    rec.fuel_sunk = f64(ll + 872)
    -- 7 槽装备映射 @216/280/344/472/600/664/728
    local SLOTS = { 216, 280, 344, 472, 600, 664, 728 }
    rec.maps = {}
    for si = 1, 7 do
      local entries = {}
      for _, me in O.vec(ll + SLOTS[si], 32, 44, 16, false) do
        local vp = rp(me)
        if O.kptr(vp) then
          entries[#entries + 1] = { id = ru32(vp + 12) or 0,
            type = ru32(vp + 8) or 0, amount = U.fix5(me + 8) or 0 }
        end
      end
      rec.maps[si] = entries
    end
    out[#out + 1] = rec
  end
  return out
end



-- ============================================================
-- §21a 州附加 (§4.13.5 ATM RH 表 / §4.13.6 资源 / §4.13.1 抵抗修正 / 轰炸)
-- ============================================================
function Runtime.state_extras(self, state_id)
  local g = self.gs()
  local sarr = g and rp(g + 0x2C8)
  if not O.kptr(sarr) then return nil end
  local st = rp(sarr + 8 * (state_id or 1))
  if not O.vt(st, GAME.layout.vt.CState) then return nil end
  local out = {}
  -- §4.13.5 ATM (RH 表@+2280; 条目 208B/值对/added_modifier/键名 mdef 表
  -- = 书 §4.13.5 + §4.13 +1736 行)
  do
    local bd = rp(st + 2288)
    local mask = ru32(st + 2304) & 0xFF
    local cnt20 = ru32(st + 2300)
    local atms = {}
    if O.kptr(bd) and mask and cnt20 and mask < 0xFF then
      local total = mask + cnt20 + 1
      if total > 0 and total < 4096 then
        for i = 0, total - 1 do
          local e = bd + 208 * i
          -- 补 0xFE 墓碑过滤 + 名字不可解析跳过 (墓碑槽垃圾
          -- midx → mtok<大数> 假叶)
          local dist = ru32(e + 4) & 0xFF
          if dist ~= 0 and dist ~= 0xFE and dist ~= 0xFF then
            local t = { dist = dist, tag = ru32(e + 8), _addr = e } -- _addr 供 savefull 段内联读 added_modifier
            local obj = rp(e + 0x20)
            if O.kptr(obj) then
              t.pairs, t.added_pairs = {}, {}
              local mdef = rp(BASE + 0x332ED90)
              -- pair 数取 e+40 与 e+44 的 min (e+40 可能带陈旧值
              -- 多读一对垃圾 — GER experience_gain_navy 实证)
              local pcnt = math.min(ru32(e + 40) or 0,
                  ru32(e + 44) or 0, 8)
              for q = 0, pcnt - 1 do
                local midx = ru32(obj + 16 * q)
                if not midx or midx == 0 then break end
                local raw = rp(obj + 16 * q + 8) or 0
                raw = LAYOUT.as_i64(raw)
                local tkn = mdef and ru32(mdef + 120 * midx + 112)
                local nm = tkn and LAYOUT.token_name(tkn)
                if nm then  -- 不可解析 = 墓碑/失效槽, 引擎不写
                  t.pairs[#t.pairs + 1] =
                      nm .. "|" .. string.format("%.5f", raw / 1e5)
                end
              end
              local aarr, acnt = rp(e + 0x38), ru32(e + 0x44) or 0
              if O.kptr(aarr) and acnt > 0 and acnt < 16 then
                for aj = 0, acnt - 1 do
                  local aobj = rp(aarr + 8 * aj)
                  if O.kptr(aobj) then
                    local adata, acnt2 = rp(aobj + 16), ru32(aobj + 28) or 0
                    if O.kptr(adata) and acnt2 > 0 and acnt2 < 16 then
                      for q2 = 0, acnt2 - 1 do
                        local midx = ru32(adata + 16 * q2)
                        if not midx or midx == 0 then break end
                        local raw = rp(adata + 16 * q2 + 8) or 0
                        raw = LAYOUT.as_i64(raw)
                        local tkn = mdef and ru32(mdef + 120 * midx + 112)
                        local nm = tkn and LAYOUT.token_name(tkn)
                        if nm then
                          t.added_pairs[#t.added_pairs + 1] =
                              nm .. "|" .. string.format("%.5f", raw / 1e5)
                        end
                      end
                    end
                  end
                end
              end
            end
            atms[#atms + 1] = t
          end
        end
      end
    end
    out.atm = atms
  end
  -- §4.13.6 CStrategicResourcePool 资源 (运行时全局资源集过滤
  -- mod 残留 token 防护)
  local rd, rc = rp(st + 448), ru32(st + 456)
  local res = {}
  if O.kptr(rd) and rc and rc > 0 and rc < 32 then
    local RESOK = self._res_ok
    if not RESOK then                    -- 惰性构建全局资源名集 (§1.2 gs+784/796
                                          -- 国家数组; §4.3.1 cc+4600 rs)
      RESOK = {}
      local cn2 = ru32(g + 0x31C) or 0
      local carr2 = rp(g + 0x310)
      for ci2 = 1, cn2 do
        local cc2 = carr2 and rp(carr2 + 8 * ci2)
        if O.kptr(cc2) then
          local rs2 = rp(cc2 + 4600)
          if O.kptr(rs2) and rp(rs2) == BASE + GAME.layout.vt.CCountryResources then
            for _, e2 in O.vec(rs2, 24 + 0x10 + 8, 24 + 0x10 + 20, 16, false) do
              local rid2 = ru32(e2 + 8) or 0
              local nm2 = (rid2 ~= 0) and LAYOUT.token_name(rid2) or nil
              -- 补下划线 (raw_mana 等 mod 资源被滤 → 州 resources 缺叶)
              if nm2 and nm2:match('^[%w_]+$') then RESOK[nm2] = true end
            end
          end
        end
      end
      self._res_ok = RESOK
    end
    for i = 0, rc - 1 do
      local val = rp(rd + 16 * i)
      local tkn = ru32(rd + 16 * i + 8)
      if val and val > 0 and tkn then
        local nm = LAYOUT.token_name(tkn)
        if nm and RESOK[nm] then
          res[#res + 1] = nm .. "|" .. (val / 1e5)
        end
      end
    end
  end
  out.resources = res
  -- §4.13.1 resistance_modifiers (CResistance@+616, {d@+528, c@+540} → SSO 名@+16)
  out.resistance_modifiers = {}
  local rz = st + 616
  for _, e in O.vec(rz, 528, 540, 8, true) do
    out.resistance_modifiers[#out.resistance_modifiers + 1] =
        U.cstr(e + 16) or ""
  end
  local lsb = ru32(st + 2184)            -- §4.13 last_strategic_bombing hours@+2184
  if lsb and lsb ~= 0 and lsb ~= 0x29C3388 then out.last_bombing_hours = lsb end
  return out
end



-- ============================================================
-- §26 海军总部
-- ============================================================
-- 26.1 naval_hq (§4.3.12 cc+4016 CBC; 条目布局/模块块 = 书 §4.3.12)
function Country.naval_hq(self)
  local cbc = rp(self.addr + 4016)
  if not O.kptr(cbc) then return nil end
  local out = { addr = cbc, count = ru32(cbc + 52) or 0, buildings = {} }
  for _, e in O.vec(cbc, 40, 52, 80, false) do
    local rec = { type = ru32(e + 8) or 0, id = ru32(e + 12) or 0 }
    local mod = rp(e + 64)
    if O.kptr(mod) then
      local mt = ru32(mod + 8)
      if mt and mt ~= 0 then
        rec.leader_character = { type = mt, id = ru32(mod + 12) or 0 }
        rec.leader_experience = U.fix5(mod + 16)
      end
    end
    out.buildings[#out.buildings + 1] = rec
  end
  return out
end

-- 26.2 naval_hq_status (§4.3.12 同一建筑向量按 status 行展开;
-- province = 建筑实例 *(e+56) → L=*(binst+472) → id u32@L+108
-- (writer 0x1415AECE0: bit0@L+104=province 模式, ADFE0(10304, id)))
function Country.naval_hq_status(self)
  local nhq = rp(self.addr + 4016)
  if not O.kptr(nhq) then return nil end
  local out = { list = {} }
  for _, e in O.vec(nhq, 40, 52, 80, false) do
    local rec = {
      id_pair = "id=" .. tostring(ru32(e + 12) or 0) .. " type=" ..
                tostring(ru32(e + 8) or 0),
      building = "naval_headquarters" }
    local cm = rp(e + 64)
    if O.kptr(cm) then
      rec.char_type = ru32(cm + 8) or 0
      rec.char_id = ru32(cm + 12) or 0
      local ex = rp(cm + 16)
      if ex then rec.experience = ex / 100000 end
    end
    local binst = rp(e + 56)
    if O.kptr(binst) then
      local L = rp(binst + 472)
      if O.kptr(L) then rec.province = ru32(L + 108) or 0 end
    end
    out.list[#out.list + 1] = rec
  end
  return out
end


-- ============================================================
