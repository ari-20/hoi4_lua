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
      -- §4.6 NDoctrines::STrackFilter (vt 0x27D1130 = 1.19.3 +0x166D0;
      -- 旧门恒假致 relevant_tracks 全灭已勘误): 指针字段@+8..32,
      -- track_index i32@+40 默认 -1
      local rtf = { addr = ro }
      if O.kptr(ro) and rp(ro) == BASE + 0x27D1130 then
        for _, lf in ipairs({ { 8, "track" }, { 16, "folder" },
            { 24, "grand_doctrine" }, { 32, "sub_doctrine" } }) do
          local dp2 = rp(ro + lf[1])
          if O.kptr(dp2) then
            local t2 = ru32(dp2 + 8)
            rtf[lf[2]] = t2 and (LAYOUT.token_name(t2) or t2) or nil
          end
        end
        local tidx = ru32(ro + 40)
        if tidx and tidx ~= 0xFFFFFFFF then rtf.track_index = tidx end
      end
      rt[#rt + 1] = rtf
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
  -- §4.8 available_equipments {d@160, c@172} variant 指针, id 对行
  out.avail_equips = {}
  for _, av in O.vec(ps, 160, 172, 8, true) do
    if O.kptr(av) then
      out.avail_equips[#out.avail_equips + 1] = {
        type = ru32(av + 8) or 0, id = ru32(av + 12) or 0 }
    end
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
      -- 发射门 raw (段侧 writer 门: 值非零才发)
      produced_gate = (rp(e + 56) or 0) ~= 0,
      active_gate = (ru32(e + 24) or 0) ~= 0,
      speed_gate = (rp(e + 48) or 0) ~= 0,
      converting_flag = ru8(e + 236) or 0,
      collapsed_flag = ru8(e + 237) or 0,
      interface_scale = ru32(e + 240) or 1,
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

-- ============================================================
-- §4.5 阵营族 + §4.3.21 power_balance 导出全量 reader
-- (sv2_sec_global_tails faction/faction_system/tech_sharing/
-- power_balance 块消费; writer 忠实; 布局/写门 = 书 §4.5.1-§4.5.4)
-- ⚠ fix5 = i64 ×1e-5 乘式 (本域段实证); f32 = u32 位型 → IEEE754;
--   date3 = 无门字段 (43808760 照写 "1.1.1.1"); date2 = !=43817520 门。
local function gt_f32(a)
  local bits = a and ru32(a) or nil
  if not bits then return nil end
  if bits == 0 then return 0.0 end
  local s = math.floor(bits / 2 ^ 31) % 2
  local e = math.floor(bits / 2 ^ 23) % 256
  local m = bits % 2 ^ 23
  local v
  if e == 0 then v = m / 2 ^ 23 * 2 ^ -126
  else v = (1 + m / 2 ^ 23) * 2 ^ (e - 127) end
  if s == 1 then v = -v end
  return v
end
local function gt_fix5(a)
  local v = a and rp(a) or nil
  return v and (v * 1e-5) or nil
end
local function gt_date3(h)
  if h == 43808760 then return "1.1.1.1" end
  return GAME.layout.date(h)
end
local function gt_date2(h)
  if not h or h == 43817520 then return nil end
  return gt_date3(h)
end
local function gt_idpair_at(el, off)   -- 内存 {type@off, id@off+4}; 双零不写
  local ty, id = ru32(el + off), ru32(el + off + 4)
  if (ty and ty ~= 0) or (id and id ~= 0) then
    return { type = ty or 0, id = id or 0 }
  end
  return nil
end
-- §4.5.8 extracted 资源池 (faction+2320 / facsys+56 同类对象)
local function gt_extracted(obj)
  local d, c = rp(obj + 8), ru32(obj + 20)
  if not (O.kptr(d) and c and c > 0 and c < LAYOUT.lim.PTR_SANE) then
    return nil end
  local t = {}
  for i = 0, c - 1 do
    local raw = rp(d + 16 * i)
    if raw and raw ~= 0 then
      local nid = ru32(d + 16 * i + 8)
      local nm = nid and LAYOUT.token_name(nid) or nid
      if nm then t[#t + 1] = { name = nm, value = raw * 1e-5 } end
    end
  end
  return t
end
-- §4.3.8 CModifier 通用布局 (name/pairs/data)
local function gt_modobj(mo)
  local rec = {}
  local nm = U.sso(mo + 88)
  if nm and nm ~= "" then rec.name = nm end
  local d, c = rp(mo + 16), ru32(mo + 28)
  if O.kptr(d) and c and c > 0 and c < LAYOUT.lim.PTR_SANE then
    rec.pairs = {}
    for i = 0, c - 1 do
      local name = GAME.layout.modifier_token(ru32(d + 16 * i))
      local val = gt_fix5(d + 16 * i + 8)
      if name and val then
        rec.pairs[#rec.pairs + 1] = { name = name, value = val } end
    end
  end
  local dv = ru32(mo + 188)
  if dv and dv ~= 1 then rec.data = dv end
  return rec
end
-- §4.5.4 tech_sharing_group 公共尾 (bonuses/countries) + upgrade 和
local function gt_tsg_tail(tsg)
  local rec = {}
  local bd, bc = rp(tsg + 48), ru32(tsg + 60)
  if O.kptr(bd) and bc and bc > 0 and bc < LAYOUT.lim.PTR_SANE then
    local parts = {}
    for i = 0, bc - 1 do parts[#parts + 1] = gt_fix5(bd + 8 * i) or 0 end
    rec.bonuses = parts
  end
  local cd, cc = rp(tsg + 24), ru32(tsg + 36)
  if O.kptr(cd) and cc and cc > 0 and cc < LAYOUT.lim.PTR_SANE then
    local t = {}
    for i = 0, cc - 1 do
      local tg = Runtime:tag(ru32(cd + 4 * i) or 0)
      if tg then t[i + 1] = tg end
    end
    rec.countries = t
    rec.countries_n = cc
  end
  return rec
end
local function gt_tsg_upgrade(tsg)  -- 逐国共享研究和 (idreg 解析)
  local def = rp(tsg + 72)
  if not O.kptr(def) then return 0 end
  local pd, pc = rp(def + 2000), ru32(def + 2012)
  if not (O.kptr(pd) and pc and pc > 0 and pc < LAYOUT.lim.PTR_SANE) then
    return 0 end
  local sum = 0
  for i = 0, pc - 1 do
    local ty, id = ru32(pd + 8 * i), ru32(pd + 8 * i + 4)
    if (ty or 0) ~= 0 or (id or 0) ~= 0 then
      local obj = GAME.layout.idreg_unit_resolve(ty, id)
      if obj then sum = sum + (ru32(obj + 188) or 0) end
    end
  end
  return sum
end

local function gt_one_faction(fr)
  local rec = { id_type = ru32(fr + 8) or 0, id_id = ru32(fr + 12) or 0 }
  do
    local nsz = ru32(fr + 40)
    if nsz and nsz > 0 then rec.name = U.sso(fr + 24) end
  end
  rec.icon = U.sso(fr + 1352)
  do -- color: (int)(f*255) 截断, alpha 仅 ~=1.0
    local r, g, b, a = gt_f32(fr + 2528), gt_f32(fr + 2532),
      gt_f32(fr + 2536), gt_f32(fr + 2540)
    if r and g and b then
      rec.color = { math.floor(r * 255), math.floor(g * 255),
        math.floor(b * 255) }
      if a and a ~= 1.0 then rec.color_a = math.floor(a * 255) end
    end
  end
  rec.is_color_overridden = (ru8(fr + 2496) or 0) ~= 0
  do -- ideology: def 对象@+136, token idx@def+8 (裸名/数值兜底)
    local def = rp(fr + 136)
    if O.kptr(def) then
      rec.ideology = LAYOUT.token_name(ru32(def + 8) or 0)
        or (ru32(def + 8) or 0)
    end
  end
  do -- members {d@+88, c@+100} 8B 国指针 → tag (槽序保洞)
    local md, mc = rp(fr + 88), ru32(fr + 100)
    if O.kptr(md) and mc and mc > 0 and mc < LAYOUT.lim.PTR_SANE then
      local t = {}
      for i = 0, mc - 1 do
        local cc2 = rp(md + 8 * i)
        local tg = O.kptr(cc2) and Runtime:tag(ru32(cc2 + 8) or 0) or nil
        if tg then t[i + 1] = tg end
      end
      rec.members = t
      rec.members_n = mc
    end
  end
  rec.leader_change_h = ru32(fr + 120) -- !=43817520 门段层 date2
  do -- template: def@+1384 → token
    local def = rp(fr + 1384)
    if O.kptr(def) then
      rec.template = LAYOUT.token_name(ru32(def + 8) or 0)
        or (ru32(def + 8) or 0)
    end
  end
  do -- goal_status 内联对象 @+1568 (§4.5.3)
    local gso = fr + 1568
    local gs2 = {}
    local mdef = rp(gso + 16)
    if O.kptr(mdef) then
      gs2.manifest = LAYOUT.token_name(ru32(mdef + 8) or 0)
        or (ru32(mdef + 8) or 0)
    end
    local gd, gc = rp(gso + 24), ru32(gso + 36)
    if O.kptr(gd) and gc and gc > 0 and gc < LAYOUT.lim.PTR_SANE then
      gs2.goals = {}
      for i = 0, gc - 1 do
        local el = gd + 1344 * i
        local g2 = { status = ru32(el + 8) or 0 }
        local gdef = rp(el)
        if O.kptr(gdef) then
          g2.goal = LAYOUT.token_name(ru32(gdef + 8) or 0)
            or (ru32(gdef + 8) or 0)
        end
        g2.game_data_h = ru32(el + 1328) -- 恒写 (date3)
        gs2.goals[#gs2.goals + 1] = g2
      end
    end
    do -- extra_goal_slots {d@+120, c@+132} u32 i32 化, 仅非零写
      local sd, sc = rp(gso + 120), ru32(gso + 132)
      if O.kptr(sd) and sc and sc > 0 and sc < LAYOUT.lim.PTR_SANE then
        gs2.extra_slots = {}
        for i = 0, sc - 1 do
          local v = ru32(sd + 4 * i)
          if v then v = LAYOUT.as_i32(v) end
          if v and v ~= 0 then gs2.extra_slots[i] = v end
        end
      end
    end
    do -- game_data {d@+320, c@+332} 24B, hours@+8
      local dd, dc = rp(gso + 320), ru32(gso + 332)
      if O.kptr(dd) and dc and dc > 0 and dc < LAYOUT.lim.PTR_SANE then
        gs2.game_data = {}
        for i = 0, dc - 1 do
          gs2.game_data[#gs2.game_data + 1] = ru32(dd + 24 * i + 8)
        end
      end
    end
    rec.goal_status = gs2
  end
  do -- power_projection_from_effects: 非零才写
    local pp = gt_fix5(fr + 2088)
    if pp and pp ~= 0 then rec.power_projection = pp end
  end
  do -- manpower_pool[2] @+2288: {tagidx, value}; value>0 才写行
    local md, mc = rp(fr + 2296), ru32(fr + 2308)
    if O.kptr(md) and mc and mc > 0 and mc < LAYOUT.lim.PTR_SANE then
      local t = {}
      for i = 0, mc - 1 do
        local val = ru32(md + 8 * i + 4)
        if val and val > 0 then
          local tg = Runtime:tag(ru32(md + 8 * i) or 0)
          if tg then t[#t + 1] = { tag = tg, value = val } end
        end
      end
      rec.manpower_pool2 = t
    end
  end
  do -- faction_programs @+2000: 内联 8B idpair {type@0, id@+4}
    local pd, pc = rp(fr + 2000), ru32(fr + 2012)
    if O.kptr(pd) and pc and pc > 0 and pc < LAYOUT.lim.PTR_SANE then
      rec.faction_programs = {}
      for i = 0, pc - 1 do
        local ty, id = ru32(pd + 8 * i), ru32(pd + 8 * i + 4)
        if (ty or 0) ~= 0 or (id or 0) ~= 0 then
          rec.faction_programs[#rec.faction_programs + 1] =
            { type = ty or 0, id = id or 0 }
        end
      end
    end
  end
  do -- pings @+2552 (execution_type 枚举段层)
    local gobj = fr + 2552
    local gc = ru32(gobj + 28)
    if gc and gc > 0 and gc < LAYOUT.lim.PTR_SANE then
      local gd = rp(gobj + 16)
      if O.kptr(gd) then
        rec.pings = {}
        for i = 0, gc - 1 do
          local el = gd + 168 * i
          local p2 = { name = U.sso(el) }
          local tgi = ru32(el + 32)
          if tgi and tgi > 0 then p2.tag = Runtime:tag(tgi) end
          p2.commander = gt_idpair_at(el, 36)
          p2.execution_type = ru32(el + 120) or 0
          local tdef = rp(el + 128)
          if O.kptr(tdef) then
            p2.template = GAME.layout.token_name(ru32(tdef + 8) or 0)
          end
          do -- countries: 全解析才成形 (一失败整列不写 = 原语义)
            local cd2, cc2 = rp(el + 48), ru32(el + 60)
            if O.kptr(cd2) and cc2 and cc2 > 0
                and cc2 < LAYOUT.lim.PTR_SANE then
              local parts = {}
              for j = 0, cc2 - 1 do
                local tg = Runtime:tag(ru32(cd2 + 4 * j) or 0)
                if not tg then parts = nil break end
                parts[#parts + 1] = tg
              end
              p2.countries = parts
            end
          end
          do -- ids / selection_order@96 / hidden@136 整数列
            local dd2, dc2 = rp(el + 72), ru32(el + 84)
            if O.kptr(dd2) and dc2 and dc2 > 0
                and dc2 < LAYOUT.lim.PTR_SANE then
              local t = {}
              for j = 0, dc2 - 1 do t[#t + 1] = ru32(dd2 + 4 * j) or 0 end
              p2.ids = t
            end
            for _, iv in ipairs({ { 96, "selection_order" },
                { 136, "hidden" } }) do
              local dd3, dc3 = rp(el + iv[1]), ru32(el + iv[1] + 12)
              if O.kptr(dd3) and dc3 and dc3 > 0
                  and dc3 < LAYOUT.lim.PTR_SANE then
                local t = {}
                for j = 0, dc3 - 1 do
                  t[#t + 1] = ru32(dd3 + 4 * j) or 0 end
                p2[iv[2]] = t
              end
            end
          end
          rec.pings[#rec.pings + 1] = p2
        end
      end
    end
  end
  rec.extracted = gt_extracted(fr + 2320)
  do -- upgrades 内联对象 @+2104 (§4.5.4)
    local upg = fr + 2104
    local sd, sc = rp(upg + 152), ru32(upg + 164)
    if O.kptr(sd) and sc and sc > 0 and sc < LAYOUT.lim.PTR_SANE then
      rec.upgrade_slots = {}
      for i = 0, sc - 1 do
        local sl = sd + 424 * i
        local s2 = {}
        local oid = ru32(sl + 8)
        if oid and oid > 0 then s2.owner = Runtime:tag(oid) end
        local adef = rp(sl)
        local nobj = O.kptr(adef) and rp(adef + 16)
        if O.kptr(nobj) then
          s2.advisor = GAME.layout.token_name(ru32(nobj + 24) or 0)
        end
        s2.spymaster_change_h = ru32(sl + 24) -- date2 门段层
        s2.modifier = gt_modobj(sl + 232)
        s2.spymaster = gt_modobj(sl + 40)
        rec.upgrade_slots[#rec.upgrade_slots + 1] = s2
      end
    end
    local tsg = upg + 40
    local t2 = gt_tsg_tail(tsg)
    t2.upgrade = gt_tsg_upgrade(tsg)
    rec.tech_sharing = t2
  end
  rec.research = (ru8(fr + 2616) or 0) ~= 0
  rec.manpower_flag = (ru8(fr + 2617) or 0) ~= 0
  do -- variables CVariables @+2624 (写门 = 空谓词: count==0 且 random_hi==1)
    local vo = fr + 2624
    if not ((ru32(vo + 32) or 0) == 0 and (ru32(vo + 8) or 0) == 1) then
      local vv = {}
      local r8 = ru32(vo + 8)
      if r8 and r8 ~= 1 then
        vv.random = { ru32(vo + 12) or 0, r8 } end
      local buckets = GAME.layout.rh_iter(vo, { data = 0x18, mask = 0x24,
        stride = 0x30, maxn = 262144 })  -- 大 mod 数千条击穿档位实证
      local list = {}
      for _, b in ipairs(buckets or {}) do
        local dist = ru32(b + 4)
        if dist and (dist & 0xFF) ~= 0 and (dist & 0xFF) ~= 0xFE
            and (dist & 0xFF) ~= 0xFF then
          local nm = U.sso(b + 8)
          local val = gt_fix5(b + 0x28)
          if nm and val then list[#list + 1] = { name = nm, value = val } end
        end
      end
      vv.entries = list   -- 排序 = 段层 (键字节序, 按 "nm|格式化值" 拼串排)
      rec.variables = vv
    end
  end
  return rec
end

-- Runtime.faction_blocks -> {factions, member_status, tech_sharing}
function Runtime.faction_blocks(self)
  local g = self.gs()
  local fs = rp(g + 0x3F8)
  if not O.kptr(fs) then return nil end
  local out = { factions = {}, member_status = nil, tech_sharing = {} }
  local data, cnt = rp(fs + 32), ru32(fs + 44)
  if O.kptr(data) and cnt and cnt > 0 and cnt < LAYOUT.lim.PTR_SANE then
    for i = 0, cnt - 1 do
      local fr = rp(data + 8 * i)
      if O.kptr(fr) then
        out.factions[#out.factions + 1] = gt_one_faction(fr)
      end
    end
  end
  do -- §4.5.1 faction_system countries 稀疏阵 @fs+8 (元素 208B)
    local d, size = rp(fs + 8), ru32(fs + 20)
    if O.kptr(d) and size and size > 0 and size < LAYOUT.lim.PTR_SANE then
      local carr = rp(g + 0x310)
      local slots = {}
      for i = 0, size - 1 do
        local el = d + 208 * i
        local cidx = ru32(el) or 0
        local occupied = false
        if cidx > 0 and O.kptr(carr) then
          local cc2 = rp(carr + 8 * cidx)
          local dip = O.kptr(cc2) and rp(cc2 + 3976)
          if O.kptr(dip) and (rp(dip + 656) or 0) ~= 0 then
            occupied = true end
        end
        if not occupied and (ru32(el + 196) or 0) ~= 0 then
          occupied = true end
        if occupied then
          local s2 = { index = i }
          local idata, isize = rp(el + 8), ru32(el + 20) or 0
          local infl = {}
          if O.kptr(idata) and isize > 0
              and isize < LAYOUT.lim.PTR_SANE then
            for s3 = 0, isize - 1 do
              local raw = rp(idata + 8 * s3)
              if raw and raw ~= 0 then
                infl[#infl + 1] = { index = s3, data = raw * 1e-5 }
              end
            end
          end
          s2.influence = infl
          s2.influence_size = isize
          local ini = gt_fix5(el + 72)
          if ini and ini ~= 0 then s2.initiative = ini end
          local con = gt_fix5(el + 120)
          if con and con ~= 0 then s2.contribution = con end
          s2.contribution_gain = { gt_fix5(el + 128) or 0,
            gt_fix5(el + 136) or 0 }
          s2.war_score_breakdown = gt_fix5(el + 176) or 0
          slots[#slots + 1] = s2
        end
      end
      out.member_status = { slots = slots, size = size,
        extracted = gt_extracted(fs + 56) }
    end
  end
  do -- §1.2 +928 tech_sharing_group 全局容器
    local c = ru32(g + 940)
    if c and c > 0 and c < LAYOUT.lim.PTR_SANE then
      local d = rp(g + 928)
      if O.kptr(d) then
        out.tech_sharing = {}
        for i = 0, c - 1 do
          local el = rp(d + 8 * i)
          if O.kptr(el) then
            local t2 = gt_tsg_tail(el)
            local def = rp(el + 72)
            if O.kptr(def) then
              t2.id = LAYOUT.token_name(ru32(def + 8) or 0)
                or (ru32(def + 8) or 0)
            end
            out.tech_sharing[#out.tech_sharing + 1] = t2
          end
        end
      end
    end
  end
  return out
end

-- §4.3.21 power_balance (挂 §1.2 +1104)
function Runtime.global_power_balance(self)
  local g = self.gs()
  local sys = rp(g + 0x450)
  if not (O.kptr(sys)
      and rp(sys) == BASE + GAME.layout.vt.CPowerBalanceSystem) then
    return nil
  end
  local data, n = rp(sys + 8), ru32(sys + 20)
  if not (O.kptr(data) and n and n > 0 and n < 4096) then return nil end
  local function sso16(p)
    local o = rp(p)
    return O.kptr(o) and U.sso(o + 16) or nil
  end
  local out = {}
  for i = 0, n - 1 do
    local e = data + 400 * i
    if rp(e) == BASE + GAME.layout.vt.CPowerBalanceEntry then
      local rec = { template = sso16(e + 16),
        value = gt_fix5(e + 48) or 0,
        left_side = sso16(e + 24), right_side = sso16(e + 32),
        trending_side = sso16(e + 40) }
      local cd, cc = rp(e + 56), ru32(e + 68)
      if O.kptr(cd) and cc and cc > 0 and cc < LAYOUT.lim.PTR_SANE then
        local t = {}
        for j = 0, cc - 1 do
          local ci = ru32(cd + 4 * j)
          if ci and ci > 0 then
            local tg = Runtime:tag(ci)
            if tg then t[#t + 1] = tg end
          end
        end
        rec.countries = t
      end
      local sd, sc = rp(e + 376), ru32(e + 388)
      if O.kptr(sd) and sc and sc > 0 and sc < LAYOUT.lim.PTR_SANE then
        rec.sides = {}
        for j = 0, sc - 1 do
          local s2 = sd + 80 * j
          rec.sides[#rec.sides + 1] = { id = U.sso(s2 + 8),
            gfx = U.sso(s2 + 0x30) }
        end
      end
      local md, mc = rp(e + 80), ru32(e + 92)
      if O.kptr(md) and mc and mc > 0 and mc < LAYOUT.lim.PTR_SANE then
        rec.modifiers = {}
        for j = 0, mc - 1 do
          local p = rp(md + 8 * j)
          local nm = O.kptr(p) and U.sso(p + 424)
          if nm then rec.modifiers[#rec.modifiers + 1] = nm end
        end
      end
      out[#out + 1] = rec
    end
  end
  return out
end

-- ============================================================
-- §4.10 diplomacy 导出全量补充 reader (sv2_sec_c_diplomacy 两段消费;
-- 与 Country.diplomacy/autonomy/proposed_diplo/misc_status_snapshot 并存)。
-- ⚠ versus/puppets 的 tag 0 = 槽 0 "---" 照发 (直读串表, 非 Runtime:tag);
--   warrel fix5 = /100000 (与 §4.5 乘式不同域不同实证)。
local function de_tagraw(tt, tid)
  if tt and tid then return hoi4.read_str(tt + 32 * tid) end
  return nil
end

-- 16B 元装备池 (lend_lease 三池; 门 amt≠0∨az 且 vp 有效)
local function de_ll_pool(sub, az)
  local d, c = rp(sub + 32), ru32(sub + 44)
  if not O.kptr(d) or not c or c <= 0 or c >= 4096 then return nil end
  local out = {}
  for k = 0, c - 1 do
    local eb = d + 16 * k
    local vp, amt = rp(eb), rp(eb + 8) or 0
    amt = LAYOUT.as_i64(amt)
    if (amt ~= 0 or az ~= 0) and O.kptr(vp) then
      out[#out + 1] = { type = ru32(vp + 8) or 0, id = ru32(vp + 12) or 0,
        amount = amt / 100000 }
    end
  end
  return out
end

-- §4.10.2 rule_overrides 28 槽 (flags@rs+816, desc@rs+928 32B,
-- vec@rs+1824 步 24B {dd, cnt@+12} 48B 元 {value@0, p@8, desc@16})
local function de_rule_overrides(rs2)
  local ro_rules = rp(BASE + 0x33304C0)
  if not O.kptr(ro_rules) then ro_rules = nil end
  local out = {}
  for k = 0, 27 do
    local kt = ro_rules and ru32(ro_rules + 56 * k + 40) or nil
    local key = kt and (GAME.layout.token_name(kt) or kt) or nil
    local e = { key = key, flag = ru32(rs2 + 816 + 4 * k) or 0,
      desc = hoi4.read_str(rs2 + 928 + 32 * k), vecs = {} }
    local dd = rp(rs2 + 1824 + 24 * k)
    local cnt = ru32(rs2 + 1836 + 24 * k)
    if cnt and cnt > 0 and cnt < 64 and O.kptr(dd) then
      for j = 0, cnt - 1 do
        local el = dd + 48 * j
        local p = rp(el + 8)
        local trig = O.kptr(p) and hoi4.read_str(p + 96) or nil
        e.vecs[#e.vecs + 1] = { value = ru32(el) or 0,
          desc = hoi4.read_str(el + 16),
          trigger = (trig and trig ~= "-") and trig or nil }
      end
    end
    out[#out + 1] = e
  end
  return out
end

-- §4.10.4 CWargoal 元素公共读取 (diplomacy.wargoals / warrel wargoals 同构)
local function de_wargoal(e, tt)
  local wt = ru32(e + 48)
  if not wt then return nil end
  local rec = { type = GAME.layout.token_name(wt) or wt,
    id_type = ru32(e + 8) or 0, id_id = ru32(e + 12) or 0 }
  local atid, rtid = ru32(e + 56), ru32(e + 60)
  if atid and atid > 0 then rec.actor = de_tagraw(tt, atid) end
  if rtid and rtid > 0 then rec.recipient = de_tagraw(tt, rtid) end
  return rec
end

-- incoming_diplomatic_action 载荷 (cc+4088 → +8 → 8*n → +24;
-- 按 act+8 token 自描述预读五族载荷; addr 供 def_emit/request 段层补)
local function de_incoming_acts(cc)
  local incobj2 = rp(cc + 4088)
  if not O.kptr(incobj2) then return nil end
  local idd2 = rp(incobj2 + 8)
  if not O.kptr(idd2) then return nil end
  local g = Runtime.gs()
  local tt = g and rp(g + 0x358) or nil
  local acts = {}
  for n = 0, 4095 do
    local ent2 = rp(idd2 + 8 * n)
    if not O.kptr(ent2) then break end
    local act = rp(ent2 + 24)
    if O.kptr(act) then
      local a = { addr = act, tok_id = ru32(act + 8) or 0 }
      if a.tok_id == 13696 then -- market_access_rights
        a.market_flag = (hoi4.read_u8(act + 120) or 0) ~= 0 end
      if a.tok_id == 13333 then -- send_volunteers
        local dvd, dvc = rp(act + 120), ru32(act + 132)
        if O.kptr(dvd) and dvc and dvc > 0
            and dvc < LAYOUT.lim.PTR_SANE then
          a.divisions = {}
          for di = 0, dvc - 1 do
            local did, dty = ru32(dvd + 8 * di + 4), ru32(dvd + 8 * di)
            if (did or 0) ~= 0 or (dty or 0) ~= 0 then
              a.divisions[#a.divisions + 1] = { type = dty or 0,
                id = did or 0 } end
          end
        end
        a.air_perm = (hoi4.read_u8(act + 176) or 0) ~= 0 end
      if a.tok_id == 13663 or a.tok_id == 12233 then -- join/call allies
        local vvd, vvc = rp(act + 120), ru32(act + 132)
        if O.kptr(vvd) and vvc and vvc > 0 and vvc < 4096 then
          a.versus = {}
          for vi = 0, vvc - 1 do
            local vtid = ru32(vvd + 4 * vi)
            local vtag = de_tagraw(tt, vtid)
            local vq = vtag and vtag ~= "" and vtag or nil
            a.versus[vi + 1] = vq
          end
        end
      end
      if a.tok_id == 12618 then -- lend_lease
        a.ll = {}
        for _, pd in ipairs({ { "equipment", 136 },
            { "production_percentage", 200 }, { "once", 264 } }) do
          local sub = act + pd[2]
          local paz = hoi4.read_u8(sub + 56) or 0
          a.ll[pd[1]] = { list = de_ll_pool(sub, paz), az = paz }
        end
        a.ll.fuel_bits = rp(act + 120)
        a.ll.fuel_pct = LAYOUT.as_i64(rp(act + 128) or 0)
      end
      if a.tok_id == 13289 then -- request_equipment_purchase
        local rty, rid = ru32(act + 336), ru32(act + 340)
        if (rid or 0) ~= 0 or (rty or 0) ~= 0 then
          a.request = { type = rty or 0, id = rid or 0 } end
      end
      acts[n + 1] = a
    end
  end
  return acts
end

-- §4.8.12 NIndustrialOrganisation::COrganisation 池 (§4.8 CProductionStatus;
-- pmc = rp(cc+0xF68), 容器 {d@pmc+0x130, c@pmc+0x13C}, org vt 门;
-- 段 sv2_sec_c_production "迁移临时内联" 回收) 。字段/门/遍历
-- (allowed_policies / unlocked traits RB 中序 / history RH / variables /
-- flags) 全在此; 发射键序 (@ 父键/[N] 编号) = 段侧
function Country.production_mio(self)
  local pmc = rp(self.addr + 0xF68)
  if not O.kptr(pmc) then return nil end
  local d, n = rp(pmc + 0x130), ru32(pmc + 0x13C)
  if not O.kptr(d) or not n or n <= 0 or n >= 65536 then return nil end
  local miovt = BASE + GAME.layout.vt.COrganisation
  local tnm = LAYOUT.token_name
  local function mfix5(p)
    local q = rp(p)
    return q and q * 1e-5 or nil
  end
  local out = {}
  for i = 0, n - 1 do
    local a = rp(d + 8 * i)
    if O.kptr(a) and rp(a) == miovt then
      local rec = { addr = a,
        org_type = ru32(a + 0x08), org_id = ru32(a + 0x0C),
        key_token = ru32(a + 56),
        name = U.sso(a + 0x60), icon = U.sso(a + 0x80),
        research_bonus = mfix5(a + 0xA0),
        task_capacity = ru32(a + 0xA8),
        funds = mfix5(a + 0x128),
        size = ru32(a + 0x130), points = ru32(a + 0x134),
        upgrades = (ru8(a + 0x138) or 0) == 1 and 1 or 0,
        research_assign_cost = mfix5(a + 176),
        production_assign_cost = mfix5(a + 184),
        design_team_change_cost = ru32(a + 192),
        add_mio_funds_gain_factor = mfix5(a + 200) }
      -- allowed_policies {d@+368, c@+380} u32 token (c<=256 门)
      rec.allowed_policies = {}
      do
        local apd, apc = rp(a + 368), ru32(a + 380)
        if O.kptr(apd) and apc and apc > 0 and apc <= 256 then
          for k = 0, apc - 1 do
            local tk = ru32(apd + 4 * k)
            rec.allowed_policies[#rec.allowed_policies + 1] =
                (tk and tnm and tnm(tk)) or (tk and "?" .. tostring(tk)) or nil
          end
        end
      end
      -- unlocked traits (RB 中序 @+320, trait token@node+40)
      rec.unlocked_traits = {}
      do
        local head = rp(a + 320)
        local node = head and rp(head)
        local guard = 0
        while node and (ru8(node + 25) or 0) == 0 and guard < 512 do
          guard = guard + 1
          local tk = ru32(node + 40)
          rec.unlocked_traits[#rec.unlocked_traits + 1] =
              tk and tnm and tnm(tk) or nil
          local r = rp(node + 16)
          if r and (ru8(r + 25) or 0) == 0 then
            node = r
            while node do
              local l = rp(node)
              if l and (ru8(l + 25) or 0) == 0 then
                node = l
              else
                break
              end
            end
          else
            while true do
              local p = rp(node + 8)
              if not p or (ru8(p + 25) or 0) ~= 0 then
                node = nil
                break
              end
              -- ⚠ 先比较旧 node (来自左子才继续上溯), 再上移
              local pr = rp(p + 16)
              local from_left = (pr == node)
              node = p
              if not from_left then break end
            end
          end
        end
      end
      -- history (RH 表 @+248 桶 64B; date 门 flag b@+0x30 +
      -- 43800000..300000000 纪元窗)
      rec.history = {}
      do
        local hbase = a + 248
        local ent = rp(hbase)
        local mask = ru32(hbase + 12) or 0
        local extra = ru8(hbase + 16) or 0
        if O.kptr(ent) then
          local nb = mask + 1 + extra
          if nb > 1024 then nb = 1024 end
          for idx2 = 0, nb - 1 do
            local b = ent + 64 * idx2
            local d4 = ru8(b + 4) or 0
            if d4 ~= 0 and d4 ~= 0xFE then
              local dflag = ru8(b + 0x30) or 0
              local dh = 0
              if dflag ~= 0 then
                dh = ru32(b + 0x20) or 0
                if dh < 43800000 or dh > 300000000 then
                  dh = 0
                end
              end
              rec.history[#rec.history + 1] = {
                eq_type = ru32(b + 8) or 0,
                eq_id = ru32(b + 12) or 0,
                date_h = dh,
                units = ru32(b + 0x38) or 0 }
            end
          end
        end
      end
      -- policy (u32@+392 ≠ 19479 undefined 才写, 裸 token)
      do
        local pol2 = ru32(a + 392)
        if pol2 and pol2 ~= 19479 then
          rec.policy = tnm(pol2)
        end
      end
      -- cooldown (门 u8@+424 ≠0; hours u32@+408)
      do
        local cb = ru8(a + 424) or 0
        if cb ~= 0 then rec.cooldown_hours = ru32(a + 408) or 0 end
      end
      -- variables@org+448 / flags@org+504 — §4.25.1 CVariables /
      -- §4.8.11 CFlagStore (附属块; 布局/门 = 书)
      do
        local vo = a + 448
        local vr8 = ru32(vo + 8)
        rec.var_random = (vr8 and vr8 ~= 1)
            and { ru32(vo + 12) or 0, vr8 } or nil
        rec.variables = {}
        -- ⚠ mask=0 (空表) 必须跳桶走查: rh_iter 的 count 兜底分支会
        -- 误读 +0x10 → 扫静态哨兵桶出垃圾名
        local vmask = ru32(vo + 0x24)
        if vmask and vmask > 0 and vmask <= LAYOUT.lim.PTR_HUGE then
          -- ⚠ 不传 count (兜底分支会误读 +0x10 扫哨兵桶), maxn=PTR_HUGE
          local buckets = LAYOUT.rh_iter(vo, { data = 0x18, mask = 0x24,
            stride = 0x30, maxn = LAYOUT.lim.PTR_HUGE })
          for _, bk in ipairs(buckets or {}) do
            local vdist = ru32(bk + 4)
            if vdist and (vdist & 0xFF) ~= 0
                and (vdist & 0xFF) ~= 0xFE and (vdist & 0xFF) ~= 0xFF then
              local vnm = U.sso(bk + 8)
              local vraw = LAYOUT.as_i64(rp(bk + 0x28) or 0)
              if vnm and vraw then
                rec.variables[#rec.variables + 1] =
                    { name = vnm, raw = vraw }
              end
            end
          end
        end
      end
      do
        rec.flags = {}
        local fd, fc = rp(a + 504 + 8), ru32(a + 504 + 0x14)
        if O.kptr(fd) and fc and fc > 0 and fc < LAYOUT.lim.PTR_HUGE then
          for fi = 0, fc - 1 do
            local fe = fd + 0x30 * fi
            local fk = ru32(fe + 8)
            local fnm = fk
                and fk <= (hoi4.read_u32(hoi4.base()
                    + GAME.layout.rva.lexer_token_max) or 100000)
                and tnm(fk)
            if fnm and fnm ~= "" then
              local fpack = ru32(fe + 0x28) or 0
              rec.flags[#rec.flags + 1] = {
                name = fnm,
                value = LAYOUT.as_i16(fpack & 0xFFFF),
                date_h = ru32(fe + 0x18) or 0,
                days = (fpack >> 16) & 0x7FFF }
            end
          end
        end
      end
      out[#out + 1] = rec
    end
  end
  return out
end

-- §4.10.19 volunteers/exile transfer (CVolunteerForceTransfer 容器
-- {data@cc+5040, count i32@cc+5052} / CExileDivisionsTransfer
-- {data@cc+5064, count i32@cc+5076}, 元素 0xA0; 布局/写门 = 书
-- §4.10.19; leader/leader_unit 门 = 任一非零且 idreg 解析成功;
-- group_name 门 = size u32@T+128 >0; division 容器 8B 内联对)
function Country.volunteers_transfers(self, mode)
  local cc = self.addr
  local doff, coff = 5040, 5052
  if mode == "exile" then doff, coff = 5064, 5076 end
  local vdata, vcnt = rp(cc + doff), ru32(cc + coff)
  local list = {}
  if O.kptr(vdata) and vcnt and vcnt > 0 and vcnt < LAYOUT.lim.PTR_SANE then
    for ti = 0, vcnt - 1 do
      local T = rp(vdata + 8 * ti)
      if O.kptr(T) then
        local rec = {
          to_tid = ru32(T + 8) or 0,
          from_tid = ru32(T + 12) or 0,
          days = ru32(T + 40) or 0,
          sender = (mode == "volunteers") and (ru8(T + 44) or 0) or nil,
          is_to_host = (mode == "exile") and (ru8(T + 44) or 0) or nil,
          target_provinces = ru32(T + 48) or 0,
          divisions = {},
        }
        if mode == "volunteers" then
          rec.group_flag = (ru8(T + 52) or 0) ~= 0
          if rec.group_flag then
            local lty, lid = ru32(T + 56), ru32(T + 60)
            if ((lty or 0) ~= 0 or (lid or 0) ~= 0)
                and GAME.layout.idreg_unit_resolve(lty, lid) then
              rec.leader = { type = lty, id = lid } end
            local uty, uid = ru32(T + 64), ru32(T + 68)
            if ((uty or 0) ~= 0 or (uid or 0) ~= 0)
                and GAME.layout.idreg_unit_resolve(uty, uid) then
              rec.leader_unit = { type = uty, id = uid } end
            -- group_color: CColor 内嵌@T+80 (f32 ×255 取整), 门内恒写
            local function fcol(bits)
              if not bits or bits == 0 then return 0 end
              local e = math.floor(bits / 2 ^ 23) % 256
              local m = bits % 2 ^ 23
              local v
              if e == 0 then v = m / 2 ^ 23 * 2 ^ -126
              else v = (1 + m / 2 ^ 23) * 2 ^ (e - 127) end
              return math.floor(v * 255)
            end
            rec.group_color = { fcol(ru32(T + 96)), fcol(ru32(T + 100)),
              fcol(ru32(T + 104)) }
            local gnsz = ru32(T + 128)
            if gnsz and gnsz > 0 then rec.group_name = U.sso(T + 112) end
          end
        end
        -- division 容器 {count i32@T+28, data@T+16}, 8B 内联对 {type,id}
        local dcnt, ddata = ru32(T + 28), rp(T + 16)
        if O.kptr(ddata) and dcnt and dcnt > 0
            and dcnt < LAYOUT.lim.PTR_SANE then
          for di = 0, dcnt - 1 do
            local dty = ru32(ddata + 8 * di) or 0
            local did = ru32(ddata + 8 * di + 4) or 0
            if dty ~= 0 or did ~= 0 then
              rec.divisions[#rec.divisions + 1] = { type = dty, id = did }
            end
          end
        end
        if mode == "volunteers" then
          rec.force = (ru8(T + 144) or 0) ~= 0
        end
        list[#list + 1] = rec
      end
    end
  end
  return list
end

-- §4.3.1 expeditionaries_sent {data@cc+760, count u32@cc+772} 8B 内联对
-- {type@+0, id@+4} (writer sub_1406BBE20, #N 1 基恒编号 = 段侧)
function Country.expeditionaries(self)
  local vd, vc = rp(self.addr + 760), ru32(self.addr + 772)
  local list = {}
  if O.kptr(vd) and vc and vc > 0 and vc < 4096 then
    for q = 0, vc - 1 do
      list[#list + 1] = { type = ru32(vd + 8 * q),
        id = ru32(vd + 8 * q + 4) }
    end
  end
  return list
end

-- Country.diplo_export -> diplomacy 两段的全部残余结构
function Country.diplo_export(self)
  local cc = self.addr
  if not cc then return nil end
  local g = Runtime.gs()
  local tt = g and rp(g + 0x358) or nil
  local rec = { incoming_acts = de_incoming_acts(cc) }
  -- rs 槽地址表 (rec.idx → rs) + 槽级走查
  local dip = rp(cc + 3976)
  local dip_rd = O.kptr(dip) and rp(dip + 8) or nil
  do
    local rs_map = {}
    if dip_rd then
      for probe = 0, 4095 do
        local rs2 = rp(dip_rd + 8 * probe)
        if not O.kptr(rs2) then break end
        local e = {}
        local rli = ru32(rs2 + 804)
        if rli and rli > 0 then e.leased_ic = rli end
        local lg1, lg2 = rp(rs2 + 576) or 0, rp(rs2 + 584) or 0
        local lg3, lg4 = rp(rs2 + 592) or 0, rp(rs2 + 600) or 0
        if lg1 ~= 0 or lg2 ~= 0 or lg3 ~= 0 or lg4 ~= 0 then
          e.llh = { lg1 / 100000, lg2 / 100000, lg3 / 100000,
            lg4 / 100000 } end
        e.rules = de_rule_overrides(rs2)
        rs_map[probe] = e
      end
    end
    rec.rs_map = rs_map
  end
  do -- §4.10.1 wargoals 容器 + 相邻标量 (dip 侧)
    local wg = {}
    wg.naval_blockade = (hoi4.read_u8(dip + 641) or 0) ~= 0
    local cd2, cc2 = rp(dip + 1000), ru32(dip + 1012)
    if O.kptr(cd2) and cc2 and cc2 > 0 and cc2 < LAYOUT.lim.PTR_SANE then
      wg.captured = {}
      for k = 0, cc2 - 1 do
        wg.captured[#wg.captured + 1] = { type = ru32(cd2 + 8 * k) or 0,
          id = ru32(cd2 + 8 * k + 4) or 0 }
      end
    end
    local awd, awc = rp(dip + 104), ru32(dip + 116)
    if O.kptr(awd) and awc and awc > 0 and awc < LAYOUT.lim.PTR_SANE then
      wg.available = {}
      for q2 = 0, awc - 1 do
        local ae = rp(awd + 8 * q2)
        if O.kptr(ae) then
          wg.available[#wg.available + 1] = { type = ru32(ae + 8) or 0,
            id = ru32(ae + 12) or 0 }
        end
      end
    end
    local wd, wc = rp(dip + 128), ru32(dip + 140)
    if O.kptr(wd) and wc and wc > 0 and wc < LAYOUT.lim.PTR_SANE then
      wg.list = {}
      for q = 0, wc - 1 do
        local e = rp(wd + 8 * q)
        if O.kptr(e) then
          local w = de_wargoal(e, tt)
          if w then
            do -- puppets: 4B tag id; 0/越界槽跳过 (原段 read_str 同门)
              local ppd, ppc = rp(e + 120), ru32(e + 132)
              if O.kptr(ppd) and ppc and ppc > 0
                  and ppc < LAYOUT.lim.PTR_SANE then
                local pts = {}
                for pk = 0, ppc - 1 do
                  local ptid = ru32(ppd + 4 * pk)
                  if tt and ptid and ptid > 0 and ptid < 4096 then
                    local tv = de_tagraw(tt, ptid)
                    if tv then pts[#pts + 1] = tv end
                  end
                end
                if #pts > 0 then w.puppets = pts end
              end
            end
            do -- states: CState vt 门 + id≠0 (悬垂槽防)
              local sd2, sc2 = rp(e + 0x48), ru32(e + 0x50)
              if O.kptr(sd2) and sc2 and sc2 > 0
                  and sc2 < LAYOUT.lim.PTR_SANE then
                local ids = {}
                for k = 0, sc2 - 1 do
                  local sp = rp(sd2 + 8 * k)
                  local svt = sp and rp(sp) or nil
                  if O.kptr(sp) and svt
                      and svt == BASE + GAME.layout.vt.CState then
                    local sid = ru32(sp + 88) or 0
                    if sid > 0 then ids[#ids + 1] = sid end
                  end
                end
                if #ids > 0 then w.states = ids end
              end
            end
            local xh = ru32(e + 0x20)
            if xh and xh ~= 0 and xh ~= 43826280 then w.expire_h = xh end
            wg.list[#wg.list + 1] = w
          end
        end
      end
    end
    rec.wargoals = wg
  end
  -- §4.10.3-7 war_relation 深层 (跨国家去重留段层; 关系全收)
  do
    local out = {}
    local okd, rdip = pcall(function() return self:diplomacy() end)
    if okd and rdip then
      for _, rec2 in ipairs(rdip.relations or {}) do
        for _, rel in ipairs(rec2.relations or {}) do
          local ra = rel.addr
          if rel.token and rel.first_tag and rel.second_tag
              and O.kptr(ra) then
            local w = { token = rel.token, first = rel.first_tag,
              second = rel.second_tag }
            w.cancel = (ru8(ra + 72) or 0) ~= 0
            w.end_sh = ru32(ra + 32)
            w.end_eh = ru32(ra + 56)
            local tn = GAME.layout.token_name(rel.token) or rel.token
            if tn == "war_relation" or tn == "war" then
              local wr = {}
              wr.cas = { rp(ra + 80) or 0, rp(ra + 88) or 0,
                rp(ra + 96) or 0, rp(ra + 104) or 0 }
              wr.ws = {}
              for vi = 1, 2 do
                local ws = ra + (vi == 1 and 112 or 224)
                local w2 = { first = de_tagraw(tt, ru32(ws + 8)),
                  second = de_tagraw(tt, ru32(ws + 12)), fields = {},
                  captured = {} }
                for _, fld in ipairs({ { "equipment_damage", 16 },
                    { "province_capture", 24 }, { "air_damage_str", 32 },
                    { "strategic_air", 40 }, { "sunk_ship", 48 },
                    { "convoy_attack", 56 }, { "casualties", 64 },
                    { "lend_lease_sent", 80 },
                    { "lend_lease_received", 88 } }) do
                  local v = rp(ws + fld[2])
                  w2.fields[#w2.fields + 1] = { name = fld[1],
                    value = v and (v / 100000) or nil }
                end
                for _, node in ipairs(
                    GAME.layout.rb_inorder(rp(ws + 96))) do
                  w2.captured[#w2.captured + 1] = ru32(node + 28) or 0
                end
                wr.ws[vi] = w2
              end
              wr.threat = rp(ra + 336) and (rp(ra + 336) / 100000) or nil
              wr.instig = (ru8(ra + 344) or 0) ~= 0
              wr.fw = {}
              for _, wgp in ipairs({ 360, 384 }) do
                local fwd = rp(ra + wgp)
                local fwc = ru32(ra + wgp + 12)
                if O.kptr(fwd) and fwc and fwc > 0
                    and fwc < LAYOUT.lim.PTR_SANE then
                  local t = {}
                  for k = 0, fwc - 1 do
                    t[#t + 1] = { type = ru32(fwd + 8 * k) or 0,
                      id = ru32(fwd + 8 * k + 4) or 0 }
                  end
                  wr.fw[#wr.fw + 1] = t
                end
              end
              local gd, gc = rp(ra + 408), ru32(ra + 420)
              if O.kptr(gd) and gc and gc > 0
                  and gc < LAYOUT.lim.PTR_SANE then
                wr.wargoals = {}
                for k = 0, gc - 1 do
                  local e = rp(gd + 8 * k)
                  local w2 = (e and O.kptr(e)) and de_wargoal(e, tt) or nil
                  if w2 then wr.wargoals[#wr.wargoals + 1] = w2 end
                end
              end
              wr.h_i = ru32(ra + 352)
              wr.h_d = ru32(ra + 348)
              w.war = wr
            elseif tn == "puppet" then
              local ap = rp(ra + 88)
              if O.kptr(ap) then w.autonomy_state = U.sso(ap + 8) end
              local rawv = rp(ra + 96)
              if rawv and rawv ~= 0 then w.puppet_value = rawv / 100000 end
            end
            out[#out + 1] = w
          end
        end
      end
    end
    rec.warrels = out
  end
  return rec
end
