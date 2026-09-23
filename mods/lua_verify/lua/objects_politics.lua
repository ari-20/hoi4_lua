-- objects_politics.lua -- 学说 / 政治外交 / 生产 (对象层域文件)
-- 加载序无关: 本文件自行 dofile objects_shared (幂等); 入口 objects_v2 汇总
-- 共享符号经 objects_shared (SH = GAME.objects_shared) 取用。
-- 结构语义详见书 hoi4_runtime_classes.md: 学说 §4.6 / 政治外交 §4.10 /
-- 生产 §4.8; vtable RVA 引 GAME.layout.vt。
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
local date_from_hours_raw = SH.date_from_hours_raw

-- §4.6 学说 CDoctrineSystem (gs+0x400 = gs+1024; writer 0x1413BA360)
-- ============================================================
local VT_DOC = { cs = GAME.layout.vt.CDoctrineCs, folder = GAME.layout.vt.CDoctrineFolder,
  track = GAME.layout.vt.CDoctrineTrack }
local function tokname_of(p)           -- *(p) 对象的 token@+8 → 名
  local o = rp(p)
  if not O.kptr(o) then return nil end
  return LAYOUT.token_name(ru32(o + 8)) or tostring(ru32(o + 8))
end

function Runtime.doctrine(self, idx)
  local g = self.gs()
  local doc = g and rp(g + 0x400)
  if not O.kptr(doc) then return nil end
  local data, n = rp(doc + 8), ru32(doc + 20)
  if not O.kptr(data) or not n or idx >= n then return nil end
  local elem = data + idx * 0xA0
  if rp(elem) ~= BASE + VT_DOC.cs then return nil end
  local out = { index = idx, addr = elem, folders = {} }
  for _, fo in O.vec(elem, 16, 28, 80, false) do
    if rp(fo) == BASE + VT_DOC.folder then
      local tracks = {}
      for _, tr in O.vec(fo, 24, 36, 96, false) do
        if rp(tr) == BASE + VT_DOC.track then
          -- §4.6 CTrackStatus leaders_daily_mastery (track writer 0x14146A9F0
          -- {d@+48, c@+60} 24B 条 {vt@0, leader idpair {type@+8,id@+12},
          -- mastery fixed5@+16}, 块门 count>0)
          local ldm = {}
          local ld, lc = rp(tr + 48), ru32(tr + 60)
          if O.kptr(ld) and lc and lc > 0 and lc < 4096 then
            for li = 0, lc - 1 do
              -- 条目内联 24B (探针: ld 即数组基, 非指针数组)
              -- {vt@0, leader idpair u64@+8 {type@+8, id@+12},
              -- mastery fixed5 i64@+16}
              local le = ld + 24 * li
              local ltype, lid = ru32(le + 8) or 0, ru32(le + 12) or 0
              -- 合理性门 (防脏桶; 存档 leader idpair {type 4713, id <100000})
              if ltype > 0 and ltype < 100000 and lid < 100000 then
                ldm[#ldm + 1] = {
                  ltype = ltype, lid = lid,
                  mastery = U.fix5(le + 16),
                }
              end
            end
          end
          tracks[#tracks + 1] = {
            sub_doctrine = tokname_of(tr + 8),
            rewards = ru32(tr + 16),
            mastery = U.fix5(tr + 24),
            mastery_bank = U.fix5(tr + 32),
            daily_mastery = U.fix5(tr + 40),
            leaders_daily_mastery = ldm,
          }
        end
      end
      out.folders[#out.folders + 1] = {
        folder = tokname_of(fo + 8),
        grand_doctrine = tokname_of(fo + 16),
        tracks = tracks,
      }
    end
  end
  out.cost_reduction = {}
  for _, cr in O.vec(elem, 64, 76, 64, false) do
    out.cost_reduction[#out.cost_reduction + 1] = {
      uses = ru32(cr + 8), name = U.sso(cr + 16),
      cost_factor = U.fix5(cr + 48), folder = tokname_of(cr + 56),
    }
  end
  out.enable_tactic = {}
  local etd, etc = rp(elem + 40), ru32(elem + 52)
  if O.kptr(etd) and etc and etc > 0 and etc < 64 then
    for k = 0, etc - 1 do
      local ro = rp(etd + 8 * k)
      local tk = O.kptr(ro) and ru32(ro + 152) or nil
      if tk then out.enable_tactic[#out.enable_tactic + 1] = tk end
    end
  end
  out.daily_mastery = {}
  for _, dm in O.vec(elem, 88, 100, 112, false) do
    local rt = {}
    for _, ro in O.vec(dm, 40, 52, 8, true) do
      rt[#rt + 1] = { addr = ro }
    end
    out.daily_mastery[#out.daily_mastery + 1] = {
      name = U.sso(dm + 8), relevant_tracks = rt,
      daily_mastery = U.fix5(dm + 88), bonus = U.fix5(dm + 96),
      days = ru32(dm + 104),
    }
  end
  -- §4.6 CCountryDoctrineStatus equipment_bonus (writer 0x1413CF470 块尾第五段; 容器 @+112
  -- {data@112, count@124}, 条目 24B SDoctrineEquipmentBonusHandle
  -- {vt 0x2965210@0, id lexer token u32@+8, index u32@+12,
  -- equipment_bonus u32@+16}; 块门 count≠0, 条目恒写含 0 值)
  out.equipment_bonus = { count = ru32(elem + 124) or 0, list = {} }
  local ebd, ebc = rp(elem + 112), ru32(elem + 124)
  if O.kptr(ebd) and ebc and ebc > 0 and ebc < 4096 then
    for ei = 0, ebc - 1 do
      local ee = ebd + 24 * ei
      if O.kptr(rp(ee)) then
        out.equipment_bonus.list[#out.equipment_bonus.list + 1] = {
          id_tok = ru32(ee + 8) or 0,
          index = ru32(ee + 12) or 0,
          bonus = ru32(ee + 16) or 0,
        }
      end
    end
  end
  return out
end


-- ============================================================
-- §4.10 政治与外交 (cc+3984 CPolitics / cc+3976 CDiplomacyStatus)
-- ============================================================
local VT_POL = GAME.layout.vt.CPolitics           -- §4.10.10 CPolitics
local function tok(p) return LAYOUT.token_name(p) end

-- §4.10.10 CPolitics 政治 (vt 0x294fda8; writer 0x141411040 族)
function Country.politics(self)
  local ps = rp(self.addr + 3984)
  if not O.kptr(ps) or rp(ps) ~= BASE + VT_POL then return nil end
  local out = { addr = ps,
    political_power = U.fix5(ps + 224),
    election_frequency = ru32(ps + 232),
    elections_allowed = (ru32(ps + 236) & 0xFF) == 1,
    last_election_hours = ru32(ps + 160),   -- §4.10.10 last_election i32@+160 (重定案)
    parties = {} }
  -- §4.10.11 CPoliticalParty parties: {d@32, c@44}
  for _, p in O.vec(ps, 32, 44, 8, true) do
    local prec = {
      ideology = tok(ru32(p + 8)),
      name = U.sso(p + 40),
      long_name = U.sso(p + 72),
      popularity = U.fix5(p + 136),
      default_flag = (ru32(p + 104) & 0xFF) == 1,
      leader_count = ru32(p + 124) or 0,
      country_leaders = {},
    }
    -- §4.10.11 country_leaders 数组 {d@112, c@124}; 元素: subideology 串@*(e+320)+16,
    -- char id 对 = *(*(e+8)+8) {type lo, id hi}
    for _, e in O.vec(p, 112, 124, 8, true) do
      local rec = {}
      local sub = rp(e + 320)
      if O.kptr(sub) then
        rec.ideology = U.sso(sub + 16) or U.cstr(sub + 16)
      end
      local ref = rp(e + 8)
      local pk = ref and rp(ref + 8)
      if pk then
        rec.char_type = pk % 0x100000000
        rec.char_id = math.floor(pk / 0x100000000) % 0x100000000
      end
      prec.country_leaders[#prec.country_leaders + 1] = rec
    end
    out.parties[#out.parties + 1] = prec
  end
  -- §4.10.10 ruling_party: 指针指向 parties 元素之一
  local rpp = rp(ps + 208)
  if O.kptr(rpp) then
    out.ruling_party = tok(ru32(rpp + 8))
    out.ruling_popularity = U.fix5(rpp + 136)
  end
  -- §4.10.10 ideas: {d@80, c@92} CIdea* → 名 = token@idea+8
  out.ideas = { count = ru32(ps + 92) or 0, list = {} }
  for _, idea in O.vec(ps, 80, 92, 8, true) do
    out.ideas.list[#out.ideas.list + 1] =
        O.kptr(idea) and (tok(ru32(idea + 8)) or "?") or "?"
  end
  -- §4.10.10 timed_ideas (CTimedIdea): 内嵌 24B 元素 {idea ptr@+8, days@+16}
  out.timed_ideas = {}
  for _, e in O.vec(ps, 104, 116, 24, false) do
    local idea = rp(e + 8)
    out.timed_ideas[#out.timed_ideas + 1] = {
      idea = O.kptr(idea) and tok(ru32(idea + 8)) or nil,
      days = ru32(e + 16),
    }
  end
  return out
end

-- §4.10.9 CCurrentAutonomyStatus 自治 (dip+848; writer 0x14066DEF0)
function Country.autonomy(self)
  local dip = rp(self.addr + 3976)
  local au = dip and rp(dip + 848)
  if not O.kptr(au) then return nil end
  local function dname(p)
    return O.kptr(p) and tostring(U.sso(p + 8)) or nil
  end
  local out = { progress = ru32(au + 8), lm_hours = ru32(au + 96),
    current_state = dname(rp(au + 40)), prev_state = dname(rp(au + 48)),
    next_state = dname(rp(au + 64)), path = {}, effects = {} }
  for _, e in O.vec(au, 16, 28, 8, true) do
    out.path[#out.path + 1] = dname(e)
  end
  for _, ev in O.vec(au, 112, 124, 8, true) do
    -- value = raw i64 (legacy Objects.autonomy 同型: lo+hi*2^32 有符号化)。
    -- U.fix5 ×1e-5 浮点 → 导出端 format("%d") 在 Lua 5.4 抛 "number has
    -- no integer representation" (secA:706 崩溃根因)
    local lo, hi = ru32(ev), ru32(ev + 4)
    local v = hi * 4294967296 + lo
    if v >= 9223372036854775808 then v = v - 18446744073709551616 end
    out.effects[#out.effects + 1] = { value = v,
      desc = tostring(U.sso(ev + 8)), hours = ru32(ev + 56) }
  end
  return out
end

-- §4.10.8 待处理外交行动 proposed (dip+768 {40B 条: index@0, date hours@16, action@32})
-- (writer 0x140D32BD0 0x3562 块; action token 10546 系)
function Country.proposed_diplo(self)
  local dip = rp(self.addr + 3976)
  if not O.kptr(dip) then return nil end
  local out = { list = {} }
  for _, e in O.vec(dip, 768, 780, 40, false) do
    out.list[#out.list + 1] = { index = ru32(e),
      hours = ru32(e + 16),
      action = LAYOUT.token_name and LAYOUT.token_name(ru32(e + 32)) or nil }
  end
  return out
end

-- §4.10.1 CDiplomacyStatus 外交 (cc+3976; dip 布局 = 书 §4.10.1,
-- CRelationStatus/rule_overrides = 书 §4.10.2)
function Country.diplomacy(self)
  local dip = rp(self.addr + 3976)
  if not O.kptr(dip) then return nil end
  local g = self.R:gs()
  local arr = g and rp(g + 0x310)   -- §1.2 gs+784 国家指针数组
  local out = { addr = dip, relations = {},
    exile_army_leaders = ru32(dip + 440) }
  -- §4.10.1 cached_allies_and_guarantees {d@880, c@892} u32 idx 数组 → tag 名
  -- ⚠ 勘误 (legacy L7947-7961): 元素 = u32 国家 idx, deref 后查 cc+8;
  -- 原 O.vec(deref=false) 迭代的是元素地址 → 全落 "i<addr>" 假行;
  -- cc2 无效时 legacy 跳过 (不补 i 行); cac_dbg = "count|data_ptr"
  local cad, cac = rp(dip + 880), ru32(dip + 892)
  out.cached_allies = {}
  local tt2 = g and rp(g + 0x358)   -- §1.2 gs+856 tag 串表
  if O.kptr(cad) and cac and cac > 0 and cac < 512 then
    for i = 0, cac - 1 do
      local idx = ru32(cad + 4 * i)
      -- 元素 = tag id, 直查 tag 表 (国家槽为空时
      -- cc 解引用路线必败 — 引擎即按 tag id 写名)
      local t336 = idx and tt2 and hoi4.read_str(tt2 + 32 * idx)
      out.cached_allies[#out.cached_allies + 1] =
          (t336 and t336 ~= "" and t336 ~= "---") and t336
          or ("i" .. tostring(idx))
    end
  end
  out.cac_dbg = string.format("%s|%s", tostring(cac), tostring(cad))
  -- §4.10.1 faction_join_date hours@720 (哨兵不导) / taken_lead_to_wars {d@856, c@868}
  -- 12B 条 {reason u32@0, tag tid@4, days@8} (tag/reason 顺序以此为准)
  out.faction_join_hours = ru32(dip + 720)
  out.taken_lead = {}
  for _, e in O.vec(dip, 856, 868, 12, false) do
    local tid = ru32(e + 4)
    out.taken_lead[#out.taken_lead + 1] = {
      tag = (tid and tid > 0 and self.R:tag(tid)) or "?",
      reason = ru32(e) or 0, days = ru32(e + 8) or 0 }
  end
  -- §4.10.14 incoming_diplomatic_action: 容器 = *(cc+4088) {d@+8, c@+20} 8B 指针数组
  -- entry {type@+8, id@+12, action ptr@+24}; action 字段布局 = 书 §4.10.13/§4.10.14
  out.incoming_diplomatic = { count = 0, list = {} }
  do
    local incobj = rp(self.addr + 4088)
    local idd, idc
    if O.kptr(incobj) then idd, idc = rp(incobj + 8), ru32(incobj + 20) end
    out.incoming_diplomatic.count = idc or 0
    if O.kptr(idd) and idc and idc > 0 and idc < 256 then
      for i = 0, idc - 1 do
        local ent = rp(idd + 8 * i)
        local act = ent and rp(ent + 24) or nil
        if O.kptr(act) then
          local function tagidx_str(off)
            local tidx = ru32(act + off)
            return (tidx and tidx > 0 and self.R:tag(tidx)) or nil
          end
          local env = ru32(act + 108) or 0
          if env >= 2147483648 then env = env - 4294967296 end
          local oap = rp(act + 88)
          local oa = (O.kptr(oap) and (ru32(oap + 24) & 0xFF) ~= 0)
              and tok(ru32(oap + 8)) or nil
          -- ⚠ versus u32 数组须 deref (legacy L8036-8043: vc<64)
          local versus = {}
          do
            local vd, vc = rp(act + 120), ru32(act + 132)
            if O.kptr(vd) and vc and vc > 0 and vc < 64 then
              for v = 0, vc - 1 do
                local vti = ru32(vd + 4 * v)
                local vt2 = vti and self.R:tag(vti)
                versus[#versus + 1] = vt2 or tostring(vti or 0)
              end
            end
          end
          out.incoming_diplomatic.list[#out.incoming_diplomatic.list + 1] = {
            id = ru32(ent + 12) or 0, idtype = ru32(ent + 8) or 0,
            tok = tok(ru32(act + 8)) or tostring(ru32(act + 8) or 0),
            im = ru8(act + 16) or 0,
            act = tagidx_str(20), oact = tagidx_str(24),
            rec = tagidx_str(28), orec = tagidx_str(32),
            date_h = ru32(act + 48) or 0, lcd_h = ru32(act + 72) or 0,
            typ = ru32(act + 104) or 0, envoy = env,
            val = ru8(act + 113) or 0, oa = oa,
            versus = (#versus > 0) and table.concat(versus, " ") or "",
            hum = ru8(act + 112) or 0 }
        end
      end
    end
  end
  -- §4.10.2 active_relations: 逐对方国家 CRelationStatus
  local rd, rc = rp(dip + 8), ru32(dip + 20)
  if O.kptr(rd) and rc and rc > 0 and rc <= 1024 then
    for i = 0, rc - 1 do
      local rs = rp(rd + 8 * i)
      if O.kptr(rs) then
        local rec = { idx = i, tag = self.R:tag(i) }
        local cs = ru32(rs + 768)
        if cs and cs >= 2147483648 then cs = cs - 4294967296 end
        rec.cached_sum = cs
        -- §4.10.2 日期三连: CGameDate 前 8 定律 (槽位 @104/@128/@152, hours@槽-8)
        rec.last_send_diplomat = U.date(ru32(rs + 104 - 8))
        rec.trade = U.date(ru32(rs + 128 - 8))
        rec.trade_equipment = U.date(ru32(rs + 152 - 8))
        local att = rp(rs + 792)
        if O.kptr(att) then rec.attitude = U.cstr(att + 16) end
        rec.border_friction = U.fix5(rs + 776)
        -- §4.10.2 opinions 求和 + 逐条 (value@+48, def 链 rp(m+40)+8, 门 b@56/57)
        local od, oc = rp(rs + 256), ru32(rs + 268)
        if O.kptr(od) and oc and oc > 0 and oc < 64 then
          local sum, mods = 0, {}
          for j = 0, oc - 1 do
            local mo = rp(od + 8 * j)
            if O.kptr(mo) then
              sum = sum + (U.fix5(mo + 48) or 0)
              local defp = rp(mo + 40)
              local defid = O.kptr(defp) and ru32(defp + 8) or nil
              mods[#mods + 1] = { value = U.fix5(mo + 48), def_id = defid,
                name = defid and tok(defid) or nil,
                dnx = (ru32(mo + 57) & 0xFF) ~= 0,
                decay = (ru32(mo + 56) & 0xFF) ~= 0,
                date = U.date(ru32(mo + 24)) }
            end
          end
          rec.opinion_sum = sum
          rec.opinion_modifiers = mods
        end
        -- §4.10.3 关系对象基类 relations 子对象 (start_date hours@rel+32, 哨兵不导)
        rec.relations = {}
        for _, rel in O.vec(rs, 232, 244, 8, true) do
          local r = { token = ru32(rel + 8), addr = rel,
            first_idx = ru32(rel + 16), second_idx = ru32(rel + 20) }
          local sh = ru32(rel + 32)
          if sh and sh ~= 0 and sh ~= 43808760 then
            r.start_date = U.date(sh)
          end
          r.first_tag = self.R:tag(r.first_idx or -1)
          r.second_tag = self.R:tag(r.second_idx or -1)
          rec.relations[#rec.relations + 1] = r
        end
        -- §4.10.2 modifiers (名串@e+424)
        rec.modifiers = {}
        for _, e in O.vec(rs, 280, 292, 8, true) do
          rec.modifiers[#rec.modifiers + 1] = U.cstr(e + 424)
        end
        rec.truce_until = U.date(ru32(rs + 168))
        -- §4.10.2 rule_overrides (28 槽 flags/desc/vec)
        do
          local _roc, _nz = 0, 0
          for k = 0, 27 do
            _roc = _roc + (ru32(rs + 1836 + 24 * k) or 0)
          end
          for o = 816, 924, 4 do
            if (ru32(rs + o) or 0) ~= 0 then _nz = _nz + 1 end
          end
          if _roc + _nz > 0 then
            local rules_base = rp(BASE + 0x33304C0)
            rec.rule_overrides = {}
            for k = 0, 27 do
              local key = O.kptr(rules_base)
                  and tok(ru32(rules_base + 56 * k + 40)) or nil
              local flag = ru32(rs + 816 + 4 * k)
              if flag and flag ~= 0 then
                rec.rule_overrides[#rec.rule_overrides + 1] =
                    { key = key, val = (flag == 1),
                      desc = U.cstr(rs + 928 + 32 * k) }
              end
              local dd = rp(rs + 1824 + 24 * k)
              local cnt = ru32(rs + 1836 + 24 * k)
              if cnt and cnt > 0 and cnt < 64 and O.kptr(dd) then
                for j = 0, cnt - 1 do
                  local e = dd + 48 * j
                  local p = rp(e + 8)
                  rec.rule_overrides[#rec.rule_overrides + 1] =
                      { key = key, val = (ru32(e) or 0) == 1,
                        desc = U.cstr(e + 16),
                        trig = O.kptr(p) and U.cstr(p + 96) or nil }
                end
              end
            end
          end
        end
        out.relations[#out.relations + 1] = rec
      end
    end
  end
  -- embargo_against / guaranteed_by
  -- ⚠ u32 idx 数组须 deref (legacy L8290-8297: ec<128, ix=ru32)
  out.embargo_against = { count = ru32(dip + 212) or 0, list = {} }
  do
    local ed, ec = rp(dip + 200), ru32(dip + 212)
    if O.kptr(ed) and ec and ec > 0 and ec < 128 then
      for i = 0, ec - 1 do
        local ix = ru32(ed + 4 * i)
        local c = arr and rp(arr + 8 * ix) or nil
        out.embargo_against.list[#out.embargo_against.list + 1] =
            { idx = ix, tag = c and self.R:tag(ru32(c + 8)) or nil }
      end
    end
  end
  out.guaranteed_by = { count = ru32(dip + 236) or 0 }
  return out
end


-- ============================================================
-- §4.8 CProductionStatus 生产 (cc+3944; writer 0x1414A36A0/0x1419260B0 族)
-- ============================================================
-- §4.8 CProductionStatus 生产标量 + 装备池 + 租借 + 能源
function Country.production_scalars(self)
  local ps = rp(self.addr + 3944)
  if not O.kptr(ps) then return nil end
  local out = { addr = ps }
  out.dirty = (ru32(ps + 1192) & 0xFF) == 1 and "yes" or "no"
  out.max_factories_for_repair = ru32(ps + 1200)
  local lneb = ru32(ps + 1352)
  if lneb and lneb >= 2147483648 then lneb = lneb - 4294967296 end
  out.last_named_equipment_bonus = lneb
  out.cic_bank_value = U.fix5(ps + 672)
  local az = (ru32(ps + 568) & 0xFF) == 1
  out.equip_allow_zero = az and "yes" or "no"
  -- §4.8 equipments 池 (12122) @+512: {d@+32, c@+44} 16B {variant*, amount ×1e-5}
  -- 写门 = amount≠0 或 allow_zero(池+56); id 对 = {type@var+8, id@var+12}
  out.equip_pool = {}
  local epd, epc = rp(ps + 512 + 32), ru32(ps + 512 + 44)
  if O.kptr(epd) and epc and epc > 0 and epc < 4096 then
    for ei = 0, epc - 1 do
      local ev = rp(epd + 16 * ei)
      local eamt = rp(epd + 16 * ei + 8) or 0
      if O.kptr(ev) and (eamt ~= 0 or az) then
        out.equip_pool[#out.equip_pool + 1] = {
          type = ru32(ev + 8) or 0, id = ru32(ev + 12) or 0,
          amount = eamt / 100000 }
      end
    end
  end
  -- §4.8 foreign_lease_equipments (13049): {d@232, c@244} variant 指针, 无条件写
  out.foreign_lease = {}
  for _, fv in O.vec(ps, 232, 244, 8, true) do
    out.foreign_lease[#out.foreign_lease + 1] = {
      type = ru32(fv + 8) or 0, id = ru32(fv + 12) or 0 }
  end
  -- §4.8 energy_production_cost @+1256: amount@+16 / need@+24 (×1e-5),
  -- resource = token@(*(ps+1264)+8)
  local eo = ps + 1256
  out.energy_amount = U.fix5(eo + 16)
  out.energy_need = U.fix5(eo + 24)
  local r2 = rp(eo + 8)
  if O.kptr(r2) then
    out.energy_resource = LAYOUT.token_name(ru32(r2 + 8) or 0)
  end
  return out
end

-- §4.8.1 生产线元素 (lines {d@88, c@100}; generals {d@112, c@124};
-- 线元素字段布局 = 书 §4.8.1)
-- 特化: naval(57) deployment §4.8.2 / railway_gun(75)+refit(71) names·refit 附加 §4.8.3/§4.8.4
function Country.production_lines(self)
  local ps = rp(self.addr + 3944)
  if not O.kptr(ps) then return nil end
  local out = { addr = ps, lines = {}, general_count = ru32(ps + 124) or 0 }
  -- fe 元素 = 原始 i64 Q15; 必须整体读 (rp 返 Lua integer 精确 64 位)。
  -- ⚠ 曾用 lo + hi*2^32 浮点重组: hi=0xFFFFFFFF 时乘积超 double 53 位
  -- 精度, -373786 被舍成 -374784 (Red_Dusk y2006 假 DIFF 根因) —
  -- 高位掩码形态一律禁浮点重组。
  local function q15(addr) return rp(addr) or 0 end
  local function line_rec(e)
    local amt = ru32(e + 72)
    if amt and amt >= 2147483648 then amt = amt - 4294967296 end
    local rec = {
      line_type = ru32(e + 8) or 0, line_id = ru32(e + 12) or 0,
      active_factories = ru32(e + 24), cost = U.fix5(e + 40),
      speed = U.fix5(e + 48), produced = U.fix5(e + 56),
      priority = ru32(e + 68), amount = amt,
      requested_factories = ru32(e + 232),
    }
    local qf = ru32(e + 64) or 0           -- writer =0 不写
    if qf ~= 0 then rec.queued_factories = qf end
    local dfm = ru32(e + 28) or 0
    if dfm ~= 0 then rec.damaged_factories = dfm end
    -- resources (×1e-5 定点; "none" 占位不写)
    rec.resources = {}
    for _, re_ in O.vec(e, 88, 100, 32, false) do
      local def = rp(re_ + 8)
      local rname = nil
      if O.kptr(def) then rname = LAYOUT.token_name(ru32(def + 8) or 0) end
      if rname and rname ~= "none" then
        rec.resources[#rec.resources + 1] = {
          resource = rname,
          amount = (rp(re_ + 16) or 0) / 100000,
          need = (rp(re_ + 24) or 0) / 100000 }
      end
    end
    local var = rp(e + 136)
    if O.kptr(var) then
      rec.variant_type = ru32(var + 8) or 0
      rec.variant_id = ru32(var + 12) or 0
    end
    local mfr_t, mfr_i = ru32(e + 144) or 0, ru32(e + 148) or 0
    if mfr_t ~= 0 or mfr_i ~= 0 then rec.mfr_type, rec.mfr_id = mfr_t, mfr_i end
    -- factory_efficiencies: i64 Q15 数组
    local fed, fec = rp(e + 192), ru32(e + 204)
    if O.kptr(fed) and fec and fec > 0 and fec < 4096 then
      rec.fe_count = fec
      rec.fe_first = (rp(fed) or 0) / 32768
      rec.fe_raw = {}
      for fi = 0, fec - 1 do
        rec.fe_raw[#rec.fe_raw + 1] = q15(fed + 8 * fi)
      end
    end
    return rec
  end
  for _, e in O.vec(ps, 88, 100, 8, true) do
    local rec = line_rec(e)
    rec.addr = e
    if rec.line_type == 57 or rec.line_type == 75 then
      -- §4.8.3 naval(57)/railway_gun(75) names 容器 (176B CNameGroupMember
      -- 元素; 布局 = 书 §4.8.3); deployment 仅海军线 (书 §4.8.2)
      if rec.line_type == 57 then
        local dep = rp(e + 272)
        if O.kptr(dep) then
          local d = {}
          local tt2, ti2 = ru32(dep + 12) or 0, ru32(dep + 16) or 0
          if (tt2 ~= 0 or ti2 ~= 0) and ti2 ~= 16 then
            d.tf_type, d.tf_id = tt2, ti2
          else
            d.base = ru32(dep + 28) or 0
          end
          -- §4.8.2 initial_carrier_air_wing_deployment 内嵌@dep+48
          local icc = ru32(dep + 68) or 0
          if icc > 0 and icc < 64 then
            local icd = rp(dep + 56)
            if O.kptr(icd) then
              d.icaw = {}
              for oi = 0, icc - 1 do
                local ie = icd + 16 * oi
                local ipd = rp(ie)
                d.icaw[#d.icaw + 1] = {
                  name = O.kptr(ipd)
                      and LAYOUT.token_name(ru32(ipd + 8) or 0) or nil,
                  value = (rp(ie + 8) or 0) / 100000 }
              end
            end
          end
          rec.deployment = d
        end
      end
      -- §4.8.3 names 容器 176B 元素; override 串@+136 (门 size@+152 ≠ 0)
      for _, ne in O.vec(e, 248, 260, 176, false) do
        rec.names = rec.names or {}
        local nr = { type = ru32(ne + 8) or 0,
          name_order = ru32(ne + 128) or 0,
          is_name_ordered = ru32(ne + 168) & 0xFF,
          override_set_prog = ru32(ne + 169) & 0xFF }
        if (rp(ne + 152) or 0) ~= 0 then
          nr.override = U.sso(ne + 136)
        end
        local ep = rp(ne + 80)
        if O.kptr(ep) then
          nr.eq_type = ru32(ep + 8) or 0
          nr.eq_id = ru32(ep + 12) or 0
        end
        rec.names[#rec.names + 1] = nr
      end
    elseif rec.line_type == 71 then      -- §4.8.4 refit 线
      local d = {}
      local tt2, ti2 = ru32(e + 260) or 0, ru32(e + 264) or 0
      if (tt2 ~= 0 or ti2 ~= 0) and ti2 ~= 16 then
        d.tf_type, d.tf_id = tt2, ti2
      end
      local st2, si2 = ru32(e + 280) or 0, ru32(e + 284) or 0
      if st2 ~= 0 or si2 ~= 0 then d.ship_type, d.ship_id = st2, si2 end
      if d.tf_type == nil then -- §4.8.4 无 tf 才写 base
        d.base = ru32(e + 276) or 0
      end
      rec.deployment = d
      local oec = rp(e + 336)
      if oec then rec.original_eq_cost = oec / 100000 end
    end
    out.lines[#out.lines + 1] = rec
  end
  -- §4.8.5/§4.8.6/§4.8.7 general_lines 特化 (building 59 / rail_way 4713 / railway_gun 76)
  out.generals = {}
  for _, e in O.vec(ps, 112, 124, 8, true) do
    local amt = ru32(e + 72)
    if amt and amt >= 2147483648 then amt = amt - 4294967296 end
    local gr = {
      line_type = ru32(e + 8) or 0, line_id = ru32(e + 12) or 0,
      produced = U.fix5(e + 56), active_factories = ru32(e + 24),
      priority = ru32(e + 68), amount = amt,
      speed = U.fix5(e + 48), cost = U.fix5(e + 40),
      created_date_hours = ru32(e + 88) or 0 }
    do -- damaged u32@+28 ≠0 (同 line_rec; §4.8.5 general building)
      local dfm = ru32(e + 28) or 0
      if dfm ~= 0 then gr.damaged_factories = dfm end
    end
    if gr.line_type == 59 then
      gr.to_repair = ru32(e + 120) or 0
      gr.conversion = ru32(e + 140) & 0xFF
      local rt, ri = ru32(e + 144) or 0, ru32(e + 148) or 0
      if rt ~= 0 or ri ~= 0 then gr.rel_type, gr.rel_id = rt, ri end
      gr.title = ru32(e + 152) & 0xFF
      gr.allied_build = ru32(e + 153) & 0xFF
      local bld = rp(e + 112)
      if O.kptr(bld) then
        local tmpl = rp(bld + 0x1E0)
        if O.kptr(tmpl) then
          gr.building_template =
              LAYOUT.token_name(ru32(tmpl + 8) or 0)
        end
        local loc = rp(bld + 0x1D8)
        if O.kptr(loc) then gr.building_location = ru32(loc + 108) or 0 end
      end
    elseif gr.line_type == 4713 then
      gr.rw_base = ru32(e + 112) or 0
      gr.rw_target = ru32(e + 116) or 0
      local cpv = ru32(e + 152) or 0
      if cpv >= 2147483648 then cpv = cpv - 4294967296 end
      gr.rw_current_province = cpv
      gr.rw_remaining_hours = (rp(e + 160) or 0) / 100000
      gr.rw_path = nil
      do -- ⚠ 元素 = u32 省 id, 必须 deref (原 deref=false 发地址)
        local rd54, rc54 = rp(e + 128), ru32(e + 140)
        if O.kptr(rd54) and rc54 and rc54 > 0 and rc54 < 256 then
          gr.rw_path = {}
          for ri = 0, rc54 - 1 do
            gr.rw_path[#gr.rw_path + 1] = ru32(rd54 + 4 * ri) or 0
          end
        end
      end
    elseif gr.line_type == 76 then
      -- §4.8.7 railway_gun 生产线: idpair {type@e+112,
      -- id@e+116} — 与 rail_way base/target 同槽异义 (GER el[49]
      -- 74/2 → save "railway_gun id=2 type=74")
      gr.rg_type = ru32(e + 112) or 0
      gr.rg_id = ru32(e + 116) or 0
    end
    out.generals[#out.generals + 1] = gr
  end
  out.cic_bank = U.fix5(ps + 672)
  return out
end


-- ============================================================
