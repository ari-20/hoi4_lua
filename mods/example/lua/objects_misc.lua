-- objects_misc.lua -- 国家快照 / 国家报告 / 杂项状态 / 部署定义库 (对象层域文件)
-- 结构语义详见书: 顶元 §4.1.2–§4.1.16 / 杂项状态 §4.3.2 起 / 国家报告 §4.3.20 /
-- 阵营 §4.5 / 部署 §4.18 / 外交关系 §4.10。
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
local sid_map2 = SH.sid_map2

-- §24 国家字段快照 / 阵营列表 / 单边关系
-- ============================================================
-- 24.1 州指针→state_id 映射 (缓存; §1.2 gs+712 州表)
local sid_cache2 = { map = nil }
local function sid_map2(g)
  if sid_cache2.map then return sid_cache2.map end
  local stbl = g and rp(g + 0x2C8)
  local m = {}
  if O.kptr(stbl) then
    for sid = 1, 4096 do
      local p = rp(stbl + 8 * sid)
      if not O.kptr(p) then break end
      m[p] = sid
    end
  end
  sid_cache2.map = m
  return m
end

-- 24.2 国家字段快照 (capital/cores/claims/delayed_events + 标量族)
-- §4.3.1 CCountry 字段布局 / §4.3.11 country_fields 标量字段族
function Country.country_fields(self)
  local g = self.R:gs()
  local cc = self.addr
  local m = sid_map2(g)
  local cores, claims, del = {}, {}, {}
  for _, p in O.vec(cc, 1192, 1204, 8, true) do
    cores[#cores + 1] = m[p]
  end
  for _, p in O.vec(cc, 1216, 1228, 8, true) do
    claims[#claims + 1] = m[p]
  end
  for _, e in O.vec(cc, 4752, 4764, 8, true) do
    local h = ru32(e + 196) or 0
    local ev = rp(e + 8)
    del[#del + 1] = { delay_hours = h, hours = h % 24,
      days = math.floor(h % 720 / 24), months = math.floor(h / 720),
      originator = ru32(e + 192),
      event = O.kptr(ev) and U.sso(ev + 32) or nil }
  end
  -- CGameDate 序列化基 (hours@基-8; §3.7a; 1.1.1.1 默认态照发)
  -- ⚠ U.date 对默认哨兵 43808760 返 nil → pride_of_the_fleet_date_lost
  -- country_reports.date 全缺; legacy _gd (L3421) 照发 "1.1.1.1"
  local function gd(a)
    return date_from_hours_raw(ru32(a - 8))
  end
  local function fxo(off) return U.fix5(cc + off) end
  local ct = {
    stability = fxo(4304), war_support = fxo(4312),
    command_power = fxo(496), accidents_score = fxo(5352),
    refresh = ru32(cc + 4320), research_slot = ru32(cc + 4936),
    scripted_gui_random = (function()      -- i32 符号 ()
      local v = ru32(cc + 544)
      if v then v = LAYOUT.as_i32(v) end
      return v
    end)(),
    cosmetic_tag = U.sso(cc + 5256) or "",
    use_legacy_ai_pp_spend = ru32(cc + 5214) & 0xFF,
    pride_of_the_fleet_date_lost = gd(cc + 616),
  }
  local ftp = rp(cc + 4976)
  if O.kptr(ftp) then ct.focus_tree = U.sso(ftp + 8) end
  local cfp = rp(cc + 4984)
  if O.kptr(cfp) then ct.continuous_focus_palette = U.sso(cfp + 8) end
  -- §4.3.20 CCountryReportsManager (cc+4064) — 内嵌报告日期
  local crp = rp(cc + 4064)
  if O.kptr(crp) then ct.country_reports_date = gd(crp + 0x40) end
  local res = {
    capital = ru32(cc + 4120),
    original_capital = ru32(cc + 4124),
    instances_counter = ru32(cc + 432),
    -- manpower.ratio: uint32@cc+824; **0 不导** (writer val>0 才写)
    manpower_ratio = (function()
      local v = ru32(cc + 824)
      return (v and v ~= 0) and v or nil
    end)(),
    preferred_tactic = (function()         -- u32@*(cc+5584)+152
      local o = rp(cc + 5584)
      if O.kptr(o) then return ru32(o + 152) end
      return nil
    end)(),
    -- variables.random: 写序反 "<+12> <+8>" (CHRX 同款)
    variables_random = (function()
      local vo = rp(cc + 536)
      if not O.kptr(vo) then return nil end
      return string.format("%d %d", ru32(vo + 12) or 0, ru32(vo + 8) or 0)
    end)(),
    cores = cores, claims = claims, delayed_events = del,
    coastal_protection_ratio = fxo(5632),
    invasion_reports = ru32(cc + 4108) or 0,
  }
  for k, v in pairs(ct) do
    if res[k] == nil then res[k] = v end
  end
  return res
end

-- 24.3 阵营列表 (容器 {data@fac_sys+32, count@+44}; CFaction 0xA80)
-- §4.5 CFactionSystem (gs+1016) / §4.5.2 CFaction
function Runtime.factions(self)
  local g = self.gs()
  local cont = g and rp(g + 0x3F8)
  if not O.kptr(cont) then return nil end
  local data, cnt = rp(cont + 32), ru32(cont + 44)
  local list = {}
  if O.kptr(data) and cnt and cnt > 0 and cnt < 256 then
    for i = 0, cnt - 1 do
      local fr = rp(data + 8 * i)
      if O.kptr(fr) then
        local mem = {}
        for _, cc in O.vec(fr, 88, 100, 8, true) do
          if O.kptr(cc) then
            mem[#mem + 1] = { country_idx = ru32(cc + 8), addr = cc }
          end
        end
        list[#list + 1] = {
          addr = fr, id = ru32(fr + 12), type = ru32(fr + 8),
          members = mem,
          is_color_overridden = ru32(fr + 2496) & 0xFF,
          color = { rp(fr + 2512), rp(fr + 2520) },
          power_projection_from_effects = rp(fr + 2088),
          leader_change_date_raw = rp(fr + 128),
          rule_status = O.kptr(rp(fr + 1392)) and (fr + 1392) or nil,
          goal_status = O.kptr(rp(fr + 1568)) and (fr + 1568) or nil,
          faction_programs = O.kptr(rp(fr + 1992)) and (fr + 1992) or nil,
          variables = O.kptr(rp(fr + 2624)) and (fr + 2624) or nil }
      end
    end
  end
  return { addr = cont, count = cnt, list = list }
end

-- 24.4 单边关系摘要 (relation: active_relations[target_idx])
-- §4.10.1 CDiplomacyStatus (cc+3976) / §4.10.2 CRelationStatus
function Country.relation(self, target_idx)
  local dip = rp(self.addr + 3976)
  if not O.kptr(dip) then return nil end
  local rd = rp(dip + 8)
  if not O.kptr(rd) then return nil end
  local rs = rp(rd + 8 * (target_idx or 0))
  if not O.kptr(rs) then return nil end
  local cs = ru32(rs + 768)
  if cs and cs >= 2147483648 then cs = cs - 4294967296 end
  local out = { addr = rs, target_idx = target_idx, cached_sum = cs,
    last_send_diplomat = U.date(ru32(rs + 104 - 8)),
    trade = U.date(ru32(rs + 128 - 8)),
    trade_equipment = U.date(ru32(rs + 152 - 8)) }
  local att = rp(rs + 792)
  if O.kptr(att) then out.attitude = U.cstr(att + 16) end
  out.border_friction = U.fix5(rs + 776)
  local od, oc = rp(rs + 256), ru32(rs + 268)
  if O.kptr(od) and oc and oc > 0 and oc < 64 then
    local sum = 0
    for j = 0, oc - 1 do
      local mo = rp(od + 8 * j)
      if O.kptr(mo) then sum = sum + (U.fix5(mo + 48) or 0) end
    end
    out.opinion_sum = sum
  end
  return out
end



-- ============================================================
-- §4.3.20 CCountryReportsManager (crm @cc+4064, vt 0x1429D10A8)
-- ============================================================
-- 27.1 country_reports (§4.3.20; index/days/log 存档编码/construction
-- 19 键/equipment_production 38 键 stride16 mask u64 = 书)
function Country.country_reports(self)
  local crm = rp(self.addr + 4064)
  if not O.kptr(crm) then return nil end
  local out = { addr = crm, index = ru32(crm + 44) or 0,
    days = ru32(crm + 40) or 0 }
  local ctr = rp(crm + 72)
  if O.kptr(ctr) then
    local arr, cnt = rp(ctr + 8), ru32(ctr + 20)
    if O.kptr(arr) and cnt == 19 then
      out.construction = {}
      for i = 0, 18 do
        out.construction[i + 1] = ru32(arr + 4 * i) or 0
      end
    end
  end
  local etr = rp(crm + 80)
  if O.kptr(etr) then
    local edata, ecnt = rp(etr), ru32(etr + 12)
    if O.kptr(edata) and ecnt > 0 and ecnt < 64 then
      out.equipment_production = {}
      for i = 0, ecnt - 1 do
        out.equipment_production[i + 1] = {
          mask = rp(edata + 16 * i) or 0,
          value = U.fix5(edata + 16 * i + 8) }
      end
    end
  end
  return out
end


-- ============================================================

-- ============================================================
-- §28 杂项状态族 (legacy Objects.misc_status 拆解)
-- ============================================================
-- 28.1 占领状态 CCountryOccupationStatus @cc+4048
-- (§4.3.2 布局 / §4.3.6 occupation 写门族; occ/DP/SGD/GRR 布局与
-- 写门 = 书)
-- 读侧启发: SGD 桶数组直挂 dp+0xD8 无独立头 — 扫到连续 64 空桶止
-- (上限 512)
function Country.occupation(self)
  local occ = rp(self.addr + 4048)
  if not O.kptr(occ) then return nil end
  local o = { addr = occ, priority = ru32(occ + 8) or 0 }
  local tp78 = rp(occ + 0x78)
  if O.kptr(tp78) then
    o.division_template = { type = ru32(tp78 + 8) or 0,
      id = ru32(tp78 + 12) or 0 }
  end
  -- resistance_attack_log (§4.3.2; 容器/条目布局与写门 = 书)
  do
    local rld, rln = rp(occ + 256), ru32(occ + 268)
    if O.kptr(rld) and rln and rln > 0 and rln < 4096 then
      local rals = {}
      for k = 0, rln - 1 do
        local en = rp(rld + 8 * k)
        if O.kptr(en) then
          local ctid = ru32(en + 8) or 0
          local e = { country_tid = ctid,
            country = ctid > 0
              and (self.R and self.R:tag(ctid) or ("i" .. ctid)) or nil }
          local stp = rp(en + 16)
          if O.kptr(stp) then e.state_id = ru32(stp + 88) or 0 end
          e.date_h = ru32(en + 32) or 0
          e.garrison = (U.a8(en + 48) or 0) ~= 0
          local mp, mn = rp(en + 64), ru32(en + 76)
          if O.kptr(mp) and mn and mn > 0 and mn < 64 then
            e.manpower = {}
            for j = 0, mn - 1 do
              local mt = ru32(mp + 8 * j) or 0
              local mv = ru32(mp + 8 * j + 4) or 0
              if mv > 0 then
                e.manpower[#e.manpower + 1] = { tag = mt > 0
                  and (self.R and self.R:tag(mt) or ("i" .. mt)) or nil,
                  value = mv }
              end
            end
          end
          -- resistance_activity (ptr@en+152 → std::string@ptr+8)
          local ra2 = rp(en + 152)
          if O.kptr(ra2) then e.resistance_activity = U.sso(ra2 + 8) end
          local eqd, eqn = rp(en + 120), ru32(en + 132)
          e.eq_allow_zero = (U.a8(en + 144) or 0) ~= 0
          e.equipment = {}
          if O.kptr(eqd) and eqn and eqn > 0 and eqn < 4096 then
            for j = 0, eqn - 1 do
              local base = eqd + 16 * j
              local vp = rp(base)
              local amt = rp(base + 8) or 0
              if (amt ~= 0 or e.eq_allow_zero) and O.kptr(vp) then
                e.equipment[#e.equipment + 1] = {
                  type = ru32(vp + 8) or 0, id = ru32(vp + 12) or 0,
                  amount = amt,
                }
              end
            end
          end
          rals[#rals + 1] = e
        end
      end
      o.resistance_attack_log = rals
    end
  end
  local dtp = rp(occ + 0x60)
  if O.kptr(dtp) then o.occupied_countries_ptr = dtp end
  local lp = rp(occ + 0x118)
  if O.kptr(lp) then o.default_law = U.cstr(lp + 0x10) end
  local data_ptr, mask = rp(occ + 0x48), ru32(occ + 0x54)
  if O.kptr(data_ptr) and mask and mask > 0 and mask < 0x10000 then
    local nbuckets = mask + 1 + (U.a8(occ + 0x58) or 0)
    local occs = {}
    for i = 0, nbuckets - 1 do
      local b = data_ptr + 24 * i
      local dist, tagv, dp = U.a8(b + 4), ru32(b + 8), rp(b + 16)
      -- 500 硬编码被大 mod (798 tag) 击穿 (USF/BLA/VPA
      -- ≥500 整 dp 76 叶蒸发) — 上界改国家计数 (§4.3.6)
      if dist and dist > 0 and dist ~= 0xFF and dist ~= 0xFE
          and O.kptr(dp) and tagv and tagv > 0
          and tagv < (GAME.layout.country_count() or 100000) then
        local cd = { addr = dp, tag = self.R:tag(tagv) or ("i" .. tagv),
          compliance = U.fix5(dp + 0x40),
          resistance = U.fix5(dp + 0x38),
          garrison_required = U.fix5(dp + 0x48),
          strength_ratio = U.fix5(dp + 0x50) }
        local sd, sn = rp(dp + 0x20), ru32(dp + 0x2C)
        if O.kptr(sd) and sn and sn > 0 and sn < 4096 then
          local sts = {}
          for k = 0, sn - 1 do
            local sp = rp(sd + 8 * k)
            sts[#sts + 1] = O.kptr(sp) and (ru32(sp + 88) or 0) or 0
          end
          table.sort(sts)
          cd.states = table.concat(sts, " ")
        end
        local olp = rp(dp + 0xA0)
        if O.kptr(olp) then cd.occupation_law = U.cstr(olp + 0x10) end
        -- resistance_modifiers {d@dp+88, c@dp+100} (dp writer
        -- 0x140FEA660 F7BA70(15743, +88))
        local rmd, rmn = rp(dp + 88), ru32(dp + 100)
        if O.kptr(rmd) and rmn and rmn > 0 and rmn < 64 then
          local rms = {}
          for k2 = 0, rmn - 1 do
            local mp2 = rp(rmd + 8 * k2)
            rms[#rms + 1] = O.kptr(mp2) and U.sso(mp2 + 0x10) or "?"
          end
          cd.resistance_modifiers = table.concat(rms, ",")
        end
        local cmd, cmn = rp(dp + 0x70), ru32(dp + 0x7C)
        if O.kptr(cmd) and cmn and cmn > 0 and cmn < 64 then
          local cms = {}
          for k = 0, cmn - 1 do
            local mp = rp(cmd + 8 * k)
            -- U.cstr→U.sso (名 = std::string@+0x10, 长名堆形态
            -- cstr 会把指针字节当字符 — subagent 定案建议)
            cms[#cms + 1] = O.kptr(mp) and U.sso(mp + 0x10) or "?"
          end
          cd.compliance_modifiers = table.concat(cms, ",")
        end
        local ll_d = rp(dp + 0xB0 + 8)
        local ll_mask = ru32(dp + 0xB0 + 0x10)
        if O.kptr(ll_d) and ll_mask and ll_mask > 0 and ll_mask < 0x1000 then
          local lls = {}
          for k = 0, ll_mask do
            local b2 = ll_d + 24 * k
            local sid2, lp2 = ru32(b2 + 8), rp(b2 + 16)
            if sid2 and sid2 > 0 and O.kptr(lp2) then
              lls[#lls + 1] = sid2 .. "=" .. (U.cstr(lp2 + 0x10) or "?")
            end
          end
          cd.law_list = table.concat(lls, ",")
        end
        -- §4.3.6 state_garrison_data 写门族 (SGD = CScriptedGuiData;
        -- 桶数组直挂 dp+0xD8, 写门 = sid ∈ states 列表)
        local gd_d = rp(dp + 0xD8)
        if O.kptr(gd_d) then
          local gds, gdxs, empty_run = {}, {}, 0
          for k = 0, 511 do
            local b3 = gd_d + 24 * k
            local dist3, sid3, gp = U.a8(b3 + 4), ru32(b3 + 8), rp(b3 + 16)
            if dist3 and dist3 > 0 and dist3 < 32 and dist3 ~= 0xFE
                and sid3 and sid3 > 0 and sid3 < 100000 and O.kptr(gp)
                and O.vt(gp, GAME.layout.vt.CScriptedGuiData) then
              empty_run = 0
              local sr, gr = rp(gp + 0xF0) or 0, rp(gp + 0xF8) or 0
              local amn = ru32(gp + 0x88) or 0
              gds[#gds + 1] = sid3 .. "|" .. (sr / 100000) .. "|"
                .. (gr / 100000) .. "|" .. amn
              local azb = U.a8(gp + 200) or 0
              local eqt, ent = {}, {}
              local eqa, eqc = rp(gp + 176), ru32(gp + 188) or 0
              if O.kptr(eqa) and eqc > 0 and eqc < 64 then
                for j = 0, eqc - 1 do
                  local en2 = eqa + 16 * j
                  local df = rp(en2)
                  if O.kptr(df) then
                    eqt[#eqt + 1] = ru32(df + 8) .. ":" .. ru32(df + 12)
                      .. ":" .. tostring(rp(en2 + 8) or 0)
                  end
                end
              end
              local ena, enc = rp(gp + 216), ru32(gp + 228) or 0
              if O.kptr(ena) and enc > 0 and enc < 64 then
                for j = 0, enc - 1 do
                  local en2 = ena + 16 * j
                  local df = rp(en2)
                  if O.kptr(df) then
                    ent[#ent + 1] = LAYOUT.token_name(ru32(df + 8)) .. ":"
                      .. tostring(rp(en2 + 8) or 0)
                  end
                end
              end
              local grrs = {}
              local grd, grc = rp(gp + 48), ru32(gp + 60) or 0
              if O.kptr(grd) and grc > 0 and grc < 16 then
                for j = 0, grc - 1 do
                  local itm = rp(grd + 8 * j)
                  if O.kptr(itm) then
                    local ppt, ptn = {}, {}
                    -- az = u8@池基+24 (SGD equipment 池同规则: 池 gp+176 →
                    -- az gp+200; 本池基 itm+88 → az itm+112), 推定
                    local gaz = U.a8(itm + 112) or 0
                    local pdd, pdc = rp(itm + 88), ru32(itm + 100) or 0
                    if O.kptr(pdd) and pdc > 0 and pdc < 64 then
                      for k2 = 0, pdc - 1 do
                        local en2 = pdd + 16 * k2
                        local df = rp(en2)
                        -- 条目门 = amount≠0 或 allow_zero_entries (writer
                        -- 与师/驻军装备池同规则; 缺门则零额条目混入 →
                        -- 编号错位; §4.3.6 garrison_reinforcement_requests)
                        if O.kptr(df)
                            and ((rp(en2 + 8) or 0) ~= 0 or gaz ~= 0) then
                          ppt[#ppt + 1] = ru32(df + 8) .. ":" .. ru32(df + 12)
                            .. ":" .. tostring(rp(en2 + 8) or 0)
                        end
                      end
                    end
                    local ndd, ndc = rp(itm + 128), ru32(itm + 140) or 0
                    if O.kptr(ndd) and ndc > 0 and ndc < 64 then
                      for k2 = 0, ndc - 1 do
                        local en2 = ndd + 16 * k2
                        local df = rp(en2)
                        if O.kptr(df) then
                          ptn[#ptn + 1] = LAYOUT.token_name(ru32(df + 8))
                            .. ":" .. tostring(rp(en2 + 8) or 0)
                        end
                      end
                    end
                    grrs[#grrs + 1] = (ru32(itm + 32) or 0) .. "^"
                      .. (rp(itm + 40) or 0) .. "^" .. (rp(itm + 48) or 0)
                      .. "^" .. (ru32(itm + 160) or 0) .. "^"
                      .. table.concat(ppt, ",") .. "^"
                      .. table.concat(ptn, ",") .. "^" .. gaz
                  end
                end
              end
              local mpv = ""
              do
                local pool = gp + 104
                local pd2, pc2 = rp(pool + 8), ru32(pool + 20) or 0
                if O.kptr(pd2) and pc2 > 0 and pc2 < 64 then
                  local parts = {}
                  for k2 = 0, pc2 - 1 do
                    local en2 = pd2 + 8 * k2
                    local tg2, vl2 = ru32(en2) or 0, ru32(en2 + 4) or 0
                    if vl2 > 0 then
                      parts[#parts + 1] = tostring(tg2) .. ":" .. vl2
                    end
                  end
                  mpv = table.concat(parts, ",")
                end
              end
              gdxs[#gdxs + 1] = sid3 .. ";" .. azb .. ";" .. amn .. ";"
                .. table.concat(eqt, ",") .. ";"
                .. table.concat(ent, ",") .. ";"
                .. table.concat(grrs, "~") .. ";" .. mpv .. ";"
                .. (U.a8(gp + 0x60) or 0) -- suppression byte (writer
                -- 0x140FEB450 AE850(0x2EB7, a1+96) ≠0 门)
            else
              empty_run = empty_run + 1
              if empty_run >= 64 then break end
            end
          end
          cd.garrison_data = table.concat(gds, ",")
          cd.garrison_x = table.concat(gdxs, "!")
        end
        occs[#occs + 1] = cd
      end
    end
    o.occupied = occs
  end
  return o
end

-- ------------------------------------------------------------
-- 28.2 后勤 (§4.3.13 CLoopHistory / 队列族; CLogisticsStatus
-- @cc+3992, 19 槽, 三队列 — 布局 = 书)
-- 读侧: 队列 is_full 是字节 (旧 ru32 读 4 字节, 高位非零曾出
-- 19 行假差异)
-- 28.3 country_reports log 记录流 (§4.3.20; 每记录 32B 8×u32;
-- 存档编码 = 书: 逐记录 [前缀=最高非零槽+1, 前 k 个值],
-- 全零记录只写 "0")
function Country.logistics(self)
  local logi = rp(self.addr + 3992)
  if not O.kptr(logi) then return nil end
  local ld = rp(logi + 8)
  local n = 0
  if O.kptr(ld) then
    for i = 0, 18 do
      if O.kptr(rp(ld + 8 * i)) then n = n + 1 end
    end
  end
  local out = { slots_total = 19, nonempty = n }
  local lq = {}
  if O.kptr(ld) then
    for i = 0, 18 do
      local tr = rp(ld + 8 * i)
      if O.kptr(tr) then
        for qi, qoff in ipairs({ 0x10, 0x18, 0x20 }) do
          local qc = rp(tr + qoff)
          if O.kptr(qc) then
            lq[#lq + 1] = { slot = i, q = qi - 1,
              max = ru32(qc + 0x10) or 0,
              offset = ru32(qc + 0x24) or 0,
              full = U.a8(qc + 0x28) or 0 }
          end
        end
      end
    end
  end
  out.queues = lq
  local crp = rp(self.addr + 4064)
  if O.kptr(crp) then
    local cl_d, cl_cap, cl_c = rp(crp + 0x10), ru32(crp + 0x18),
      ru32(crp + 0x1C)
    if O.kptr(cl_d) and cl_c and cl_c > 0 and cl_c < 4096
        and cl_cap and cl_cap >= cl_c then
      local t = {}
      for i = 0, cl_c - 1 do
        local b = cl_d + 32 * i
        local k, vv = 0, { 0, 0, 0, 0, 0, 0, 0, 0 }
        for j = 0, 7 do
          local x = ru32(b + 4 * j) or 0
          vv[j + 1] = x
          if x ~= 0 then k = j + 1 end
        end
        if k == 0 then
          t[#t + 1] = "0"
        else
          t[#t + 1] = tostring(k)
          for j = 1, k do
            t[#t + 1] = tostring(vv[j])
          end
        end
      end
      out.report_log = table.concat(t, " ")
    end
  end
  return out
end

-- ------------------------------------------------------------
-- 28.4 族 (外交/流亡/入侵状态快照): dirty_controlled/removed_prov/
-- air volunteer 收发/流亡投降族 (dip = *(cc+3976))/heroes_dying/
-- exile manpower/invasion_report/recently_invaded_areas
-- (§4.3.1 杂项标量/容器族 + §4.10.18 投降/流亡/志愿航空队族 +
-- §4.3.19 recently_invaded_areas; 布局与写门 = 书)
function Country.misc_status_snapshot(self)
  local snap = {}
  snap.dirty = (U.a8(self.addr + 4749) or 0) ~= 0
  snap.removed_prov = (U.a8(self.addr + 5618) or 0) ~= 0
  do
    local rv = {}
    local rd2, rc2 = rp(self.addr + 5160), ru32(self.addr + 5172)
    local cd2 = rp(self.addr + 5184)
    if O.kptr(rd2) and rc2 and rc2 > 0 and rc2 < 128 then
      for i = 0, rc2 - 1 do
        rv[#rv + 1] = string.format("%s=%d",
          self.R:tag(ru32(rd2 + 4 * i)) or "?",
          O.kptr(cd2) and (ru32(cd2 + 4 * i) or 0) or 0)
      end
    end
    if #rv > 0 then snap.recv_vol = rv end
  end
  do
    local gv = {}
    local gd2, gc3 = rp(self.addr + 5136), ru32(self.addr + 5148)
    if O.kptr(gd2) and gc3 and gc3 > 0 and gc3 < 128 then
      for i = 0, gc3 - 1 do
        gv[#gv + 1] = self.R:tag(ru32(gd2 + 4 * i))
      end
    end
    if #gv > 0 then snap.given_vol = gv end
  end
  local dip = rp(self.addr + 3976)
  if O.kptr(dip) then
    snap.capitulated = (U.a8(dip + 736) or 0) ~= 0
    snap.cap_date_h = ru32(dip + 752)
    snap.last_surr_h = ru32(dip + 696)
    local htid = ru32(dip + 424)
    if htid and htid > 0 then snap.hosting = self.R:tag(htid) end
    local lg = rp(dip + 432)
    if lg and lg ~= 0 then snap.legitimacy = lg / 100000 end
    local ed, ec = rp(dip + 400), ru32(dip + 412)
    if O.kptr(ed) and ec and ec > 0 and ec < 128 then
      local ehosts = {}
      for i = 0, ec - 1 do
        ehosts[#ehosts + 1] = self.R:tag(ru32(ed + 4 * i))
      end
      if #ehosts > 0 then snap.we_host = ehosts end
    end
  end
  local hq = rp(self.addr + 5328)
  if hq and hq ~= 0 then snap.heroes = hq / 32768 end
  local exv, exm = ru32(self.addr + 808 + 24), ru32(self.addr + 808 + 28)
  if exv and exv > 0 then
    snap.exile_mp = exv
    snap.max_exile_mp = exm or 0
  end
  do
    local iv = {}
    local idd, idc = rp(self.addr + 4096), ru32(self.addr + 4108)
    if O.kptr(idd) and idc and idc > 0 and idc < 128 then
      for i = 0, idc - 1 do
        local e = rp(idd + 8 * i)
        if O.kptr(e) then
          local pp = rp(e + 16)
          iv[#iv + 1] = { tag = self.R:tag(ru32(e + 8)),
            enemy = self.R:tag(ru32(e + 12)),
            province = O.kptr(pp) and ru32(pp + 164) or nil,
            date_h = ru32(e + 40) }
        end
      end
    end
    if #iv > 0 then snap.invasion_reports = iv end
  end
  do
    local ivd = {}
    local host5 = rp(self.addr + 552)
    local csa = O.kptr(host5) and rp(host5 + 2800) or nil
    if O.kptr(csa) then csa = csa + 2800 end
    local vdd, vdc
    if csa then
      vdd, vdc = rp(csa + 5544), ru32(csa + 5556)
    end
    if O.kptr(vdd) and vdc and vdc > 0 and vdc < 128 then
      for i = 0, vdc - 1 do
        local e = vdd + 64 * i
        local pp = rp(e + 8)
        local od, oc = rp(e + 16), ru32(e + 28)
        local ids = "0"
        if O.kptr(od) and oc and oc > 0 and oc < 64 then
          local tl = {}
          for j = 0, oc - 1 do
            tl[#tl + 1] = tostring(ru32(od + 4 * j) or 0)
          end
          ids = table.concat(tl, " ")
        end
        ivd[#ivd + 1] = { province = O.kptr(pp) and (ru32(pp + 164) or 0) or 0,
          ids = ids, date_h = ru32(e + 48) or 0 }
      end
    end
    if #ivd > 0 then snap.recently_invaded = ivd end
  end
  return snap
end

-- ------------------------------------------------------------
-- 28.5 王牌飞行员 (CAirAce; 容器 {d@cc+4824, c@cc+4836};
-- 元素字段/写门 = 书 §4.3 country.ace 元素表)
function Country.air_aces(self)
  local ac = {}
  local ad, acn = rp(self.addr + 4824), ru32(self.addr + 4836)
  if O.kptr(ad) and acn and acn > 0 and acn < 64 then
    for i = 0, acn - 1 do
      local e = rp(ad + 8 * i)
      if O.kptr(e) then
        local rec = {}
        local mp = rp(e + 368)
        if O.kptr(mp) then rec.modifier = U.sso(mp + 8) end
        rec.name = U.sso(e + 240)
        rec.surname = U.sso(e + 272)
        rec.callsign = U.sso(e + 304)
        rec.portrait = ru32(e + 340) or 0
        rec.alive = (U.a8(e + 344) or 0) ~= 0 and 1 or 0
        rec.kt = ru32(e + 348) or 0
        rec.kn = ru32(e + 352) or 0
        rec.kc = ru32(e + 360) or 0
        ac[#ac + 1] = rec
      end
    end
  end
  return ac
end

-- ------------------------------------------------------------
-- 28.6 国家级建筑 CBuildingStatus @rp(cc+4944) (§4.3 +4944 行;
-- vt 同州级; CBuilding 元素布局/写门 = 书)
function Country.country_buildings(self)
  local bo = rp(self.addr + 4944)
  if not O.vt(bo, GAME.layout.vt.CBuildingStatus) then return nil end
  local bd, bcn = rp(bo + 56), ru32(bo + 68)
  local bl = {}
  if O.kptr(bd) and bcn and bcn > 0 and bcn < 64 then
    for i = 0, bcn - 1 do
      local e = rp(bd + 8 * i)
      if O.kptr(e) then
        local tok = ru32(e + 8)
        local lv = ru32(e + 64) or 0
        bl[#bl + 1] = {
          name = (tok and (LAYOUT.token_name(tok)))
            or ("token_" .. tostring(tok)),
          level = lv % 65536,
          healthy = math.floor(lv / 65536),
          partial = (ru32(e + 72) or 0) / 100000 }
      end
    end
  end
  return { count = #bl, list = bl }
end

-- ------------------------------------------------------------
-- 28.7 misc_status 组合器 (legacy Objects.misc_status 同构输出)
function Country.misc_status(self)
  local out = {}
  out.occupation = self:occupation()
  -- §4.3.1 CCountryCollaborationStatus (cc+4056)
  local coll = rp(self.addr + 4056)
  if O.kptr(coll) then
    out.collaboration = { count = ru32(coll + 0x34) or 0 }
  end
  local lg = self:logistics()
  if lg then
    out.logistics = { slots_total = lg.slots_total, nonempty = lg.nonempty }
    out.logistics_queues = lg.queues
    out.country_report_log = lg.report_log
  end
  -- §4.10.14 incoming_diplomatic_action (cc+4088)
  local inc = rp(self.addr + 4088)
  if O.kptr(inc) then
    out.incoming_diplomatic = { count = ru32(inc + 20) or 0 }
  end
  out.exile_invasion = self:misc_status_snapshot()
  local ac = self:air_aces()
  if #ac > 0 then out.aces = ac end
  local bl = self:country_buildings()
  if bl then out.buildings = bl end
  -- §4.3.1 CArmyUpgradesStatus (cc+3968)
  local upg = rp(self.addr + 3968)
  if O.kptr(upg) then out.upgrades = { addr = upg } end
  return out
end

-- ============================================================
-- §30 部署/定义/顶元族 (legacy deployment_conveyors / deployment_hq /
-- definitions / top_meta / deployment_unit_modifiers 正式迁移)
-- ============================================================
-- 30.1 (legacy STATIC 静态槽位表已删): 原表持 1.19.2 六库/扩展库地址,
-- 仅 Runtime.definitions 消费; 二者一并移除 (见 30.4 注)。

-- §4.18 CDeploymentStatus / §4.18.12 CMilitaryDeploymentConveyor 命令族
-- 30.2 deployment_conveyors: 存档 deployment.military_deployment_
-- conveyor 族全链, dep = rp(cc+3952), conveyor 容器 @dep+72
-- (conveyor/line/md 三层布局与写门 = 书 §4.18.12)
function Country.deployment_conveyors(self)
  local dep = rp(self.addr + 3952)
  if not O.kptr(dep) then return nil end
  local out = { list = {} }
  local cd, ccnt = rp(dep + 72), ru32(dep + 84)
  if O.kptr(cd) and ccnt and ccnt > 0 and ccnt < 128 then
    for j = 0, ccnt - 1 do
      local e = rp(cd + 8 * j)
      if O.kptr(e) then
        local rec = {
          addr = e,
          id_type = ru32(e + 8) or 0,
          id = ru32(e + 12) or 0,
          name = U.sso(e + 40),
          amount = ru32(e + 72) or 0,
          location = ru32(e + 76) or 0,
          priority = ru32(e + 80) or 0,
          role = ru32(e + 144) or 0,
          closed = (U.a8(e + 148) == 1) and "yes" or "no",
          giex_tid = ru32(e + 152) or 0,  -- government_in_exile_tag
          lines = {},
        }
        -- division_template_id: 指针@e+32 → id 对@+8
        local tp = rp(e + 32)
        if O.kptr(tp) then
          rec.template_type = ru32(tp + 8) or 0
          rec.template_id = ru32(tp + 12) or 0
        end
        -- order_index (gate: 探针 GER +84=0 无行)
        rec.order_index = ru32(e + 84) or 0
        -- lines {d@e+120, c@e+132}
        local ld, lc = rp(e + 120), ru32(e + 132)
        if O.kptr(ld) and lc and lc > 0 and lc < 128 then
          for k = 0, lc - 1 do
            local L = rp(ld + 8 * k)
            if O.kptr(L) then
              local lrec = {
                id_type = ru32(L + 8) or 0,
                id = ru32(L + 12) or 0,
                amount = ru32(L + 40) or 0,
              }
              -- division_name 对象@L+32
              local dn = rp(L + 32)
              if O.kptr(dn) then
                lrec.dn_type = ru32(dn + 8) or 0
                lrec.dn_order = ru32(dn + 128) or 0
              end
              -- md = *(L+48)+24
              local mp = rp(L + 48)
              if O.kptr(mp) then
                local M = mp + 24
                lrec.training = (rp(M + 72) or 0) / 100000
                lrec.max_training = (rp(M + 80) or 0) / 100000
                lrec.max_manpower = ru32(M + 152) or 0
                -- halting_reason u32@M+168, 门 byte@M+172 ≠0 (writer
                -- 0x1414246F0 0x382E)
                if (U.a8(M + 172) or 0) ~= 0 then
                  lrec.halting_reason = ru32(M + 168) or 0
                end
                -- manpower value/need (writer 0x140C5B610): 容器
                -- {d@obj+8, cnt@obj+20} 条目内联 8B {tag idx, value 整数}
                local function mp_read(obj, pfx)
                  if not (obj and obj > 0x10000) then return end
                  local md8, mc20 = rp(obj + 8), ru32(obj + 20)
                  if O.kptr(md8) and mc20 and mc20 > 0 and mc20 < 16 then
                    for q2 = 0, mc20 - 1 do
                      local mtag = ru32(md8 + 8 * q2) or 0
                      local mval = ru32(md8 + 8 * q2 + 4) or 0
                      if mval > 0 then
                        lrec[pfx .. "_tag"] =
                          self.R:tag(mtag) or tostring(mtag)
                        lrec[pfx .. "_value"] = mval
                      end
                    end
                  end
                end
                -- 对象是内嵌非指针 (writer 直传 a1+88/a1+120, vt 在 M+88/M+120)
                mp_read(M + 88, "mpv")
                mp_read(M + 120, "mpn")
                -- equipment 池内嵌@M+8 (0x1414246F0 ADEC0(0x2F4E, a1+8)
                -- 直传; vt@M+8, {d@M+40, cnt@M+52} — GER l1 5 条 ✓)
                local ep = M + 8
                if rp(ep) and rp(ep) > 0x10000 then
                  local ed, ec = rp(ep + 32), ru32(ep + 44)
                  lrec.equipment = {}
                  if O.kptr(ed) and ec and ec > 0 and ec < 256 then
                    for q = 0, ec - 1 do
                      local ee = ed + 16 * q
                      local var = rp(ee)
                      if O.kptr(var) then
                        lrec.equipment[#lrec.equipment + 1] = {
                          id = ru32(var + 12) or 0,
                          type = ru32(var + 8) or 0,
                          amount = (rp(ee + 8) or 0) / 100000,
                        }
                      end
                    end
                  end
                  lrec.allow_zero = (U.a8(ep + 56) == 1) and "yes" or "no"
                end
              end
              rec.lines[#rec.lines + 1] = lrec
            end
          end
        end
        out.list[#out.list + 1] = rec
      end
    end
  end
  return out
end

-- 30.3 deployment_hq: §4.18 CDeploymentStatus (default_hq_template/
-- hq_next_deploy_order 写门 = 书); strategic_navy dockyards/
-- naval_accident (§4.16.5; M = gs+0x698 国家数组)
function Country.deployment_hq(self)
  local dep = rp(self.addr + 3952)
  if not O.kptr(dep) then return nil end
  local out = {}
  local ht, hi = ru32(dep + 172) or 0, ru32(dep + 176) or 0
  if ht ~= 0 or hi ~= 0 then
    out.default_hq_type, out.default_hq_id = ht, hi
  end
  local no = ru32(dep + 168) or 0
  if no > 0 then out.hq_next_deploy_order = no end
  -- strategic_navy dockyards + naval_accident
  do
    local g = self.R.gs()
    local M = g and rp(g + 0x698)
    if O.kptr(M) then
      local arr = rp(M + 8)
      local n2 = ru32(M + 20) or 0
      if O.kptr(arr) and self.idx < n2 then
        local S = rp(arr + 8 * self.idx)
        if O.kptr(S) then
          out.max_allowed_dockyards = ru32(S + 440) or 0
          out.num_used_dockyards = ru32(S + 444) or 0
          local ad, ac = rp(S + 224), ru32(S + 236)
          if O.kptr(ad) and ac and ac > 0 and ac < 8 then
            out.accident_count = ac
          end
        end
      end
    end
  end
  return out
end

-- 30.4 definitions: 已移除 (旧址失效 + 无调用方)
-- 原实现读 legacy STATIC 表 (1.19.2 地址): 实测 sv2_export 路径 0 次
-- 调用, 且旧址失效返回垃圾计数。权威静态资源访问 = resource.lua 的
-- idb 族 (书 §4.26); 布局知识留档于 git 历史。

-- 30.5 top_meta: 存档头部顶格叶 (§4.1.2 区界表 + §4.1.6–§4.1.16; 布局与写门 = 书):
-- 全局计数 rva 直读; gs 内存叶 gmem 偏移; id_counter 表@gs+0x7A8
-- 条目 0x10 {vt@+0, type@+8, id@+12} 连续同 vt; date/start_date 裸
-- hours; player = gs+1312 → 国家数组 → tag; ideology = 玩家国
-- cc+3984(political) → +208 → +8 token
function Runtime.top_meta(self)
  local g = self.gs()
  if not g then return nil end
  local counters = {}
  -- 计数器 RVA 统一引自 hoi4_layout.rva.counters (唯一权威; 原与
  -- sv2_sec_session_meta 各持一份拷贝)。两个 random_* 为 i32 语义。
  for nm, rva in pairs(LAYOUT.rva.counters) do
    local v = ru32(BASE + rva) or 0
    if nm == "multiplayer_random_seed"
        or nm == "multiplayer_random_count" then
      v = LAYOUT.as_i32(v)
    end
    counters[nm] = v
  end
  local function gmem(off, name) counters[name] = ru32(g + off) or 0 end
  gmem(1864, 'land_combat_id')
  gmem(1868, 'navy_id')
  gmem(1168, 'session')
  gmem(1212, 'speed')
  gmem(1824, 'game_unique_seed')
  gmem(2492, 'cached_active_trade_route_count')
  gmem(2496, 'next_trade_route_update_country_idx')
  local avg = ru32(g + 2168)
  local out = { counters = counters }
  if avg then out.average_major_ic = avg / 1e5 end
  local cid = ru32(g + 1320)
  if cid and cid > 0 then
    out.tension_scaling_base_country = self:tag(cid)
  end
  local glen = rp(g + 1832 + 0x10)
  if glen and glen > 0 and glen < 64 then
    local buf = rp(g + 1832)
    if O.kptr(buf) then out.game_unique_id = hoi4.read_cstr(buf) end
  end
  local sto = rp(g + 0x7A8)
  local ic = {}
  if O.kptr(sto) then
    local p0 = rp(sto)
    for i5 = 0, 255 do
      local e5 = sto + 0x10 * i5
      if rp(e5) ~= p0 then break end
      local t5 = ru32(e5 + 8)
      local v5 = ru32(e5 + 12)
      if not t5 or t5 == 0 or not v5 then break end
      ic[#ic + 1] = { type = t5, id = v5 }
    end
  end
  out.id_counter = ic
  local function _h2d(h)
    -- 唯一实现 = hoi4_layout.date_opt (门 = 丢 h<=纪元; 无回绕, 0x29C3388 不滤)
    return LAYOUT.date_opt(h, { drop_le = 43800000 })
  end
  out.date = _h2d(ru32(g + 0x468))      -- gs+1128 当前日期 CGameDate hours
  out.start_date = _h2d(ru32(g + 0x4A8))  -- gs+4A8 裸 hours (探针 60759371)
  local DIFF_NAMES = { "very_easy", "easy", "normal", "hard", "very_hard" }
  local denv = ru32(g + 1584) or 2
  out.difficulty = DIFF_NAMES[denv + 1] or ("diff_" .. denv)
  local v192 = ru32(g + 192) or 0
  out.tutorial = ((v192 & 8) ~= 0) and "yes" or "no"
  out.statistics_collection_enabled =
    ((ru32(g + 2232) or 0) & 0xFF) ~= 0 and "yes" or "no"
  out.save_version = ru32(BASE + LAYOUT.rva.save_version)
  out.minor_save_version = ru32(BASE + LAYOUT.rva.minor_save_version)
  local carr2 = rp(g + 0x310)
  local pidx = ru32(g + 1312) or 0
  local pcc = carr2 and pidx > 0 and rp(carr2 + 8 * pidx) or nil
  if O.kptr(pcc) then
    local ptag = ru32(pcc + 8) or 0
    if ptag > 0 then
      out.player = self:tag(ptag)
    end
    local pol = rp(pcc + 3984)
    if O.kptr(pol) then
      local itok = rp(pol + 208)
      if O.kptr(itok) then
        local tid = ru32(itok + 8) or 0
        out.ideology = LAYOUT.token_name(tid)
      end
    end
  end
  return out
end

-- 30.6 deployment_unit_modifiers (DUM 修饰值族; §4.18.11
-- CSubunitBonusPersistent: dep = rp(cc+3952) 容器 {d@+8, c@+20}
-- 112B 元素, 两层列表 + stats 对象 obj+64 — 布局/写门 = 书 §4.18.11)
-- stat_idx → token (writer 0x1413D34D0 switch, 78 项)
local STAT2TOK = {
  [0] = 11950,
  [1] = 10836,
  [2] = 11956,
  [3] = 13733,
  [4] = 11960,
  [5] = 11961,
  [6] = 12196,
  [7] = 13551,
  [8] = 13573,
  [9] = 12744,
  [10] = 12597,
  [11] = 11887,
  [12] = 11959,
  [13] = 13838,
  [14] = 13375,
  [15] = 14415,
  [16] = 15138,
  [17] = 10106,
  [18] = 10121,
  [19] = 11965,
  [20] = 11967,
  [21] = 12287,
  [22] = 12288,
  [23] = 10219,
  [24] = 10221,
  [25] = 15351,
  [26] = 15350,
  [27] = 15354,
  [28] = 15353,
  [29] = 12310,
  [30] = 11972,
  [31] = 12442,
  [32] = 12965,
  [33] = 12332,
  [34] = 13362,
  [35] = 14656,
  [36] = 14657,
  [37] = 12011,
  [38] = 12101,
  [39] = 15191,
  [40] = 12077,
  [41] = 12089,
  [42] = 16333,
  [43] = 12975,
  [44] = 12976,
  [45] = 12977,
  [46] = 12236,
  [47] = 11958,
  [48] = 11962,
  [49] = 12238,
  [50] = 12336,
  [51] = 12335,
  [52] = 12440,
  [53] = 12441,
  [54] = 13166,
  [55] = 13269,
  [56] = 15422,
  [57] = 19874,
  [58] = 16415,
  [59] = 16419,
  [60] = 12330,
  [61] = 11948,
  [62] = 11954,
  [63] = 12099,
  [64] = 12100,
  [65] = 12668,
  [66] = 13572,
  [67] = 593,
  [68] = 10811,
  [69] = 11955,
  [70] = 15713,
  [71] = 11901,
  [72] = 11964,
  [73] = 17093,
  [74] = 14532,
  [75] = 14531,
  [76] = 12153,
  [77] = 11951,
}

-- §4.18/§4.18.11 CDeployment/CSubunitBonusPersistent: dep = cc+3952, 容器
-- {d@dep+8, c@dep+20} 112B 元素; scan_stats 读元素统计块 (+24 combat_width,
-- 78 槽 STAT2TOK 映射, stats 对象 obj+64 — 与书 §4.18.11 表同源)
function Country.deployment_unit_modifiers(self)
  local dep = rp(self.addr + 3952)
  if not O.kptr(dep) then return nil end
  local d, c = rp(dep + 8), ru32(dep + 20)
  local out = { list = {} }
  if not (O.kptr(d) and c and c > 0 and c < 4096) then return out end
  local rec_mods
  local function scan_stats(base, cat)
    local cw = rp(base + 24) or 0
    if cw ~= 0 then
      cw = LAYOUT.as_i64(cw)
      rec_mods[#rec_mods + 1] = {
        target = cat, name = "combat_width", value = cw * 1e-5 }
    end
    for i = 0, 77 do
      local raw = rp(base + 96 + 8 * i) or 0
      if raw ~= 0 then
        raw = LAYOUT.as_i64(raw)
        local tok = STAT2TOK[i]
        local nm = tok and LAYOUT.token_name(tok)
        if nm then
          rec_mods[#rec_mods + 1] = {
            target = cat, name = nm, value = raw * 1e-5 }
        end
      end
    end
  end
  for k = 0, c - 1 do
    local e = d + 112 * k
    local rec = { mods = {} }
    rec_mods = rec.mods
    local p1d, p1c = rp(e + 16), ru32(e + 28)
    if O.kptr(p1d) and p1c and p1c > 0 and p1c < 64 then
      for i = 0, p1c - 1 do
        local p = rp(p1d + 8 * i)
        if O.kptr(p) then
          local cat = LAYOUT.token_name(ru32(p + 8) or 0)
          scan_stats(p + 64, cat)
        end
      end
    end
    local p2d, p2c = rp(e + 40), ru32(e + 52)
    if O.kptr(p2d) and p2c and p2c > 0 and p2c < 64 then
      for i = 0, p2c - 1 do
        local db = rp(p2d + 16 * i)
        local obj = rp(p2d + 16 * i + 8)
        if O.kptr(db) and O.kptr(obj) then
          local cat = LAYOUT.token_name(ru32(db + 84) or 0)
          scan_stats(obj + 64, cat)
        end
      end
    end
    if rp(e + 96) then
      -- ⚠ U.sso size==0 → ""(真值) 会多发 lk 行; legacy
      -- read_msvc_str 返 nil → 空串归一为 nil
      local lk = U.sso(e + 80)
      if lk and #lk > 0 then rec.localization_key = lk end
    end
    out.list[#out.list + 1] = rec
  end
  return out
end

-- ============================================================
