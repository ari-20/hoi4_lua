-- objects_global.lua -- 杂项族 / 国家级杂项族 / 全局元数据族 (对象层域文件)
-- 结构语义详见书: §4.5 阵营 CFactionSystem / §4.27 突袭 CRaidSystem /
-- §4.34 AI CStrategicAI。 (全局代理工厂族 §32 已拆至 objects_manager.lua)
-- 共享层惰性获取 (DLL 字母序下 objects_shared 晚于本文件加载)。
-- 世代判据 (§0.2 对象层文件布局) = GAME.layout 表身份: hoi4_layout 每代
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
local cont_elems = SH.cont_elems
local to_i32, to_i16 = LAYOUT.as_i32, LAYOUT.as_i16

-- §31 杂项族 (faction_members / raids / country_characters / MIO 本体 /
-- strategic_air_deep; legacy Objects 正式迁移)
-- ============================================================
-- 31.1 faction_members: 阵营成员管理器 @gs+0x3F8 (§4.5 CFactionSystem;
-- 条目 §4.5.1 CFactionMemberStatus; 布局/写门 = 书)
-- 读侧启发 (代码判据): 真成员标记 = +0x38/+0x40/+0x48 任一非零
-- (实测 17 国); +0x50 小整数非成员标记 (成员/非成员都有, 语义开放)
function Runtime.faction_members(self, opts)
  opts = opts or {}
  local g = self.gs()
  local fac = g and rp(g + 0x3F8)
  if not O.kptr(fac) then return {} end
  local data, n = rp(fac + 0x8), ru32(fac + 0x14)
  local out = {}
  if not O.kptr(data) or not n or n > 1000 then return out end
  for i = 0, n - 1 do
    local e = data + i * 0xD0
    local v38, v40, v48, v50 =
      rp(e + 0x38), rp(e + 0x40), rp(e + 0x48), rp(e + 0x50)
    local in_faction = (v38 and v38 ~= 0) or (v40 and v40 ~= 0)
      or (v48 and v48 ~= 0)
    if not opts.in_faction or in_faction then
      out[#out + 1] = {
        index = i,
        addr = e,
        in_faction = in_faction,
        initiative = v48 and v48 > 0 and v48 / 100000.0 or 0,
        -- 原始字段 (+0x50 语义开放: 成员与非成员都可能为小整数或静态指针)
        v38 = v38, v40 = v40, v48_raw = v48,
        v50 = v50, v68 = rp(e + 0x68),
      }
    end
  end
  return out
end

-- 31.2 raids: CRaidSystem @gs+0x3F0 (§4.27.1; countries 容器/元素
-- CCountryRaidStatus/targets mgr = 书; VT_RAID_STATUS 未入 M.vt: §0.2)
local VT_RAID_STATUS = 0x29ccd88  -- NRaids::CCountryRaidStatus (未入 M.vt: §0.2)

function Runtime.raid_countries(self)
  local g = self.gs()
  local raids = g and rp(g + 0x3F0)
  if not O.kptr(raids) then return {} end
  local data, n = rp(raids + 0xD8), ru32(raids + 0xE4)
  local out = {}
  if not O.kptr(data) or not n or n > 1000 then return out end
  for i = 0, n - 1 do
    local e = data + i * 0xB0
    if rp(e) == BASE + VT_RAID_STATUS then
      local inst = rp(e + 0x10)
      out[#out + 1] = {
        index = i,
        addr = e,
        instance_count = ru32(e + 0xC),
        instance = O.kptr(inst) and inst or nil,
      }
    end
  end
  return out
end

-- 31.3 raid_targets (§4.27.1 CRaidSystem targets 管理器 @raids+8)
function Runtime.raid_targets(self)
  local g = self.gs()
  local raids = g and rp(g + 0x3F0)
  if not O.kptr(raids) then return nil end
  local mgr = raids + 8
  local out = {
    next_state = ru32(mgr + 144),
    existing_target_num = ru32(mgr + 164),
    detectable_target_num = ru32(mgr + 188),
    next_target = ru32(mgr + 200),
    targets = {},
  }
  local d, c = rp(mgr), ru32(mgr + 12)
  if O.kptr(d) and c and c > 0 and c < 10000 then
    for i = 0, c - 1 do
      local t = rp(d + 8 * i)
      if O.kptr(t) then
        local inner = t + 8
        local rec = {
          existing = ru32(t) or 0,
          detectable = ru32(t + 4) or 0,
          dynamic = U.a8(t + 48) or 0,
          valid = U.a8(t + 49) or 0,
        }
        -- leader / leader_province (SRaidTarget: id 对 {type@t+32,
        -- id@t+36}, 省指针@t+40 → id@+164; 非零才写 = 段侧门)
        local lty, lid = ru32(t + 32), ru32(t + 36)
        if (lty and lty ~= 0) or (lid and lid ~= 0) then
          rec.leader = { type = lty, id = lid } end
        local lp2 = rp(t + 40)
        rec.leader_province = O.kptr(lp2) and (ru32(lp2 + 164) or 0) or nil
        local bld = rp(inner)
        local prov = rp(inner + 8)
        local st = rp(inner + 16)
        rec.state = O.kptr(st) and (ru32(st + 88) or -1) or nil
        rec.province = O.kptr(prov) and (ru32(prov + 164) or -1) or nil
        if O.kptr(bld) then
          -- building ref (1410C6540→141163510→1413AB6C0 族)
          -- template 对象@bld+0x1E0 (token u32@+8)
          -- 州对象@bld+0x1D8 → +108 = 省 idx; 省+164 = location (省 id)
          local tpo = rp(bld + 0x1E0)
          local ttok = O.kptr(tpo) and ru32(tpo + 8) or nil
          rec.bld_template = ttok and
            (LAYOUT.token_name(ttok) or ("tok" .. tostring(ttok))) or nil
          local sto = rp(bld + 0x1D8)
          if O.kptr(sto) then
            rec.bld_location = ru32(sto + 108)
          end
        end
        -- detected 数组
        local dd, dc = rp(t + 56), ru32(t + 68)
        rec.detected = {}
        if O.kptr(dd) and dc and dc > 0 and dc < 256 then
          for j = 0, dc - 1 do
            rec.detected[#rec.detected + 1] = U.a8(dd + j) or 0
          end
        end
        out.targets[#out.targets + 1] = rec
      end
    end
  end
  return out
end

-- 31.4 raid_country_entries : raids 国家条目深层 (§4.27.1
-- CCountryRaidStatus / CRaidInstance / raid_source 布局与写门 = 书)
function Runtime.raid_country_entries(self)
  local g = self.gs()
  if not g then return nil end
  local raids = rp(g + 0x3F0)
  if not O.kptr(raids) then return nil end
  local d, c = rp(raids + 0xD8), ru32(raids + 0xE4)
  local out = {}
  -- 738 国 mod > 旧 440 门 → 放宽 100000
  if not (O.kptr(d) and c and c > 0 and c <= 100000) then return out end
  local PHASE = { "NONE", "ASSEMBLING", "PREPARING", "PREPARED",
    "IN_PROGRESS", "ENDED" }
  local OUTCOME = { "NONE", "FAILURE", "LIMITED_SUCCESS", "SUCCESS",
    "CRITICAL_SUCCESS", "CANCELED" }
  for j = 0, c - 1 do
    local e = d + 0xB0 * j
    local rec = {
      index = j,
      addr = e,  -- 段侧深层读取用 (raid_instance end_date 等)
      priority = ru32(e + 96) or -1,
      instances = {},
    }
    local tid = ru32(e + 8)
    if tid and tid > 0 then
      rec.tag = self:tag(tid)
    end
    local dummy = rp(e + 16)
    if O.kptr(dummy) then
      rec.dummy_id = ru32(dummy + 12) or 0
      rec.dummy_type = ru32(dummy + 8) or 0
    end
    -- target_cooldowns (§4.27.1 CCountryRaidStatus +72; 64B 元:
    -- def ptr@+8 (类型名 token@def+8), building ptr@+16 (template =
    -- tok@*(bld+0x1E0)+8, location = 省 id@*(bld+0x1D8)+108),
    -- province ptr@+24 → +164, state ptr@+32 → +88, cooldown u32@+56)
    rec.target_cooldowns = {}
    do
      local td2, tc2 = rp(e + 72), ru32(e + 84)
      if O.kptr(td2) and tc2 and tc2 > 0 and tc2 < 4096 then
        for k = 0, tc2 - 1 do
          local el = td2 + 64 * k
          local item = { cooldown = ru32(el + 56) or 0 }
          local bld = rp(el + 16)
          if O.kptr(bld) then
            local tpo = rp(bld + 0x1E0)
            local tt = O.kptr(tpo) and ru32(tpo + 8) or nil
            item.bld_template = tt and (LAYOUT.token_name(tt)
                or ("tok" .. tostring(tt))) or nil
            local sto = rp(bld + 0x1D8)
            item.bld_location = O.kptr(sto)
                and (ru32(sto + 108) or 0) or nil
          end
          local pv = rp(el + 24)
          item.province = O.kptr(pv) and (ru32(pv + 164) or 0) or nil
          local st = rp(el + 32)
          item.state = O.kptr(st) and (ru32(st + 88) or 0) or nil
          local def = rp(el + 8)
          item.type_name = O.kptr(def)
              and LAYOUT.token_name(ru32(def + 8)) or nil
          rec.target_cooldowns[#rec.target_cooldowns + 1] = item
        end
      end
    end
    local id2, ic2 = rp(e + 24), ru32(e + 36)
    if O.kptr(id2) and ic2 and ic2 > 0 and ic2 < 256 then
      for k = 0, ic2 - 1 do
        local inst = rp(id2 + 8 * k)
        if O.kptr(inst) then
          local ir = {
            id = ru32(inst + 12) or 0,
            type_id = ru32(inst + 8) or 0,
            prep_time = ru32(inst + 68) or 0,
            nr_days = ru32(inst + 72) or 0,
            distance = U.fix5(inst + 80) or 0,
            phase = PHASE[(ru32(inst + 56) or 0) + 1] or "?",
            outcome = OUTCOME[(ru32(inst + 60) or 0) + 1] or "?",
            detected = ru8(inst + 400) or 0,
            -- 探针实锤 (sv2_raid_probe.txt): 内嵌 CGameDate
            -- {vt@inst+408, hours u32@inst+416}, 门 bool u8@inst+432
            end_gate = ru8(inst + 432) or 0,
            end_hours = ru32(inst + 416),
          }
          -- unit.air_wing (CRaidInstance +200 族: {type@+208, id@+212}
          -- 非零才写; writer 0x141454E80 系)
          local awt, awi = ru32(inst + 208), ru32(inst + 212)
          if (awt and awt ~= 0) or (awi and awi ~= 0) then
            ir.air_wing = { type = awt, id = awi } end
          -- target.leader (SRaidTarget 同构: {type@+184, id@+188},
          -- 省 ptr@+192 → id@+164)
          local lty, lid = ru32(inst + 184), ru32(inst + 188)
          if (lty and lty ~= 0) or (lid and lid ~= 0) then
            ir.leader = { type = lty, id = lid } end
          local lp = rp(inst + 192)
          ir.leader_province = O.kptr(lp) and (ru32(lp + 164) or 0) or nil
          -- raid_source.province (raid_source 块 @inst+216, 省 ptr@
          -- rs+8 → id@+164; writer 0x141581E30)
          local rsp = rp(inst + 224)
          ir.src_province = O.kptr(rsp) and (ru32(rsp + 164) or 0) or nil
          -- show_for (§4.27.1 CRaidInstance +440 {d, c@+452}; 任一
          -- tag 解析失败 = 整块不发 — 提取器半匿名续行怪癖 = 段侧形态)
          do
            local sfc = ru32(inst + 452)
            local sfd = rp(inst + 440)
            if sfc and sfc > 0 and sfc < 440 and O.kptr(sfd) then
              local parts, ok3 = {}, true
              for j2 = 0, sfc - 1 do
                local tg = self:tag(ru32(sfd + 4 * j2) or 0)
                if not tg then ok3 = false break end
                parts[#parts + 1] = tg
              end
              if ok3 then ir.show_for = parts end
            end
          end
          -- type 名 = token_name(u32@*(inst+152)+8)
          local tobj = rp(inst + 152)
          if O.kptr(tobj) then
            ir.type_name = LAYOUT.token_name(ru32(tobj + 8))
          end
          -- victim_country tid@+464 (>0 才写)
          local vtid = ru32(inst + 464)
          if vtid and vtid > 0 then
            ir.victim = self:tag(vtid)
          end
          -- target @inst+160 (writer sub_140FD2A70, this=
          -- inst+160 直读): building 实例 ptr@+160 → template =
          -- token@*(def+480)+8, location = id@*(def+472)+108 (NHQ
          -- 同构), province ptr@+168 → id@+164, state ptr@+176 → +88
          do
            local tdef = rp(inst + 160)
            if O.kptr(tdef) then
              local bt = rp(tdef + 480)
              local bl = rp(tdef + 472)
              ir.target_building = {
                template = (O.kptr(bt)
                  and LAYOUT.token_name(ru32(bt + 8) or 0)) or nil,
                location = (O.kptr(bl) and ru32(bl + 108) or 0),
              }
            end
            local tpv = rp(inst + 168)
            if O.kptr(tpv) then
              ir.target_province = ru32(tpv + 164) or 0
            end
            -- state ptr@+176 → id@+88 (C3: writer 有 target.state 叶;
            -- 旧导出曾 83 叶整族漏发)
            local tst = rp(inst + 176)
            if O.kptr(tst) then
              ir.target_state = ru32(tst + 88) or 0
            end
          end
          -- unit @inst+200: army id 对 {type@+0, id@+4}
          local un = inst + 200
          local ut, ui = ru32(un), ru32(un + 4)
          if (ut and ut ~= 0) or (ui and ui ~= 0) then
            ir.unit_army_id = ui or 0
            ir.unit_army_type = ut or 0
          end
          -- raid_source 内联块 (§4.27.1 raid_source 布局/枚举映射 = 书)
          do
            local src = inst + 216
            if (U.a8(src + 4) or 0) ~= 0 then
              local stv = ru32(src)
              local tmap = { [0] = 12214, [1] = 13303,
                [2] = 12790, [3] = 12175, [4] = 12173, [5] = 10319 }
              local tn2 = LAYOUT.token_name(tmap[stv] or stv)
              ir.src_type = tn2 or tostring(stv)
              local stag = ru32(src + 24)
              if stag and stag > 0 then
                ir.src_tag = self:tag(stag)
              end
              -- 0x28A0(ship) 对@+16 {type@+0,id@+4}, 非零才写
              local st2, si2 = ru32(src + 16), ru32(src + 20)
              if ((st2 or 0) ~= 0) or ((si2 or 0) ~= 0) then
                ir.src_ship = string.format("id=%d type=%d",
                    si2 or 0, st2 or 0)
              end
              ir.src_building = {
                location = ru32(src + 40) or 0,
                template = LAYOUT.token_name(ru32(src + 44) or 0),
              }
              -- 有效性门 (template token ≠19479 哨兵 且 (location
              -- ≠-1 或 i32@+48 > 0))
              local btok = ru32(src + 44) or 19479
              local bloc = ru32(src + 40) or 0xFFFFFFFF
              local b3 = GAME.layout.as_i32(ru32(src + 48) or 0)
              ir.src_building_valid = btok ~= 19479
                  and (bloc ~= 0xFFFFFFFF or b3 > 0)
            end
          end
          rec.instances[#rec.instances + 1] = ir
        end
      end
    end
    out[#out + 1] = rec
  end
  return out
end

-- 31.5 country_characters: CCountry+4080 → CCountryCharacters
-- (§4.4; 宿主/三容器/16B 元素 flags 位分布/科学家表/招募池 = 书 §4.3 chars 内部表)
function Country.country_characters(self)
  local ch = rp(self.addr + 4080)
  if not O.kptr(ch) or rp(ch) ~= BASE + GAME.layout.vt.CCountryCharacters then
    return nil end
  local out = {
    addr = ch,
    status_count = ru32(ch + 28) or 0,
    statuses = {},
    appointed_advisors = ru32(ch + 100) or 0,
  }
  local d, c = rp(ch + 16), ru32(ch + 28)
  if not O.kptr(d) or not c or c > 2048 then return out end
  for j = 0, c - 1 do
    local e = d + 16 * j
    local st = rp(e)
    if O.kptr(st) then
      -- flags 在向量元素 e+8..0xB (writer a3+8..11); id{type,id} 在 ref 壳 st+8/+0xC
      out.statuses[#out.statuses + 1] = {
        addr = st,
        type = ru32(st + 8),
        id = ru32(st + 0xC),
        country_leader = (ru32(e + 8) % 256) == 1,
        advisor = (math.floor((ru32(e + 8) or 0) / 256) % 256) == 1,
        unit_leader = (math.floor((ru32(e + 8) or 0) / 65536) % 256) == 1,
        scientist = (math.floor((ru32(e + 8) or 0) / 16777216) % 256) == 1,
      }
    end
  end
  -- retired_character_status {d@+40, c@+52} (元素 16B 同 status)。
  -- ⚠ 1.19.3 writer 原序直写向量 — 不排序 (旧"id 升序 sort"系误判,
  -- 段层对拍实证原序为真)
  do
    local rd, rc = rp(ch + 40), ru32(ch + 52)
    local rs = {}
    if O.kptr(rd) and rc and rc > 0 and rc < 100000 then
      for j = 0, rc - 1 do
        local e = rd + 16 * j
        local st = rp(e)
        if O.kptr(st) then
          rs[#rs + 1] = {
            type = ru32(st + 8), id = ru32(st + 0xC),
            country_leader = (ru32(e + 8) % 256) == 1,
            advisor = (math.floor((ru32(e + 8) or 0) / 256) % 256) == 1,
            unit_leader = (math.floor((ru32(e + 8) or 0) / 65536) % 256) == 1,
            scientist = (math.floor((ru32(e + 8) or 0) / 16777216) % 256) == 1,
          }
        end
      end
    end
    out.retired = rs
  end
  -- retired_operative_leader 池 {d@+200, c@+212} 8B COperativeLeader*
  -- (§4.11.11; 元素转换 = Runtime.op_leader (objects_characters 公开),
  -- 运行期可用; 未挂载兜底 = 原始地址数组)
  do
    local dd, dc = rp(ch + 200), ru32(ch + 212) or 0
    local dop = {}
    if O.kptr(dd) and dc > 0 and dc < 100000 then
      for q = 0, dc - 1 do
        local e = rp(dd + 8 * q)
        if O.kptr(e) then
          dop[#dop + 1] = Runtime.op_leader
              and Runtime.op_leader(e, self.R) or e
        end
      end
    end
    out.retired_operatives = dop
  end
  -- appointed_advisors 条目 (d@+88 指针数组, 元素→advisor 对象)
  do
    local ad, ac = rp(ch + 88), ru32(ch + 100)
    local av = {}
    if O.kptr(ad) and ac and ac > 0 and ac < 256 then
      for j = 0, ac - 1 do
        local ap = rp(ad + 8 * j)
        if O.kptr(ap) then
          local rec = {
            addr = ap,
            slot = U.sso(ap + 128),
          }
          local hp = rp(ap + 16)
          if O.kptr(hp) then
            local pk = rp(hp + 8)
            if pk then
              rec.char_id = math.floor(pk / 0x100000000) % 0x100000000
              rec.char_type = pk % 0x100000000
            end
          end
          av[#av + 1] = rec
        end
      end
    end
    out.advisors = av
  end
  -- recruit_scientist CScientistRecruitmentPool 内嵌 @ch+224
  do
    local SP = ch + 224
    local sd, sc = rp(SP + 8), ru32(SP + 20)
    local ss = {}
    if O.kptr(sd) and sc and sc > 0 and sc < 4096 then
      for j = 0, sc - 1 do
        local e = rp(sd + 8 * j)
        if O.kptr(e) then
          local ref = rp(e + 8)
          local io = O.kptr(ref) and rp(ref + 8) or nil
          if io then
            ss[#ss + 1] = {
              id = math.floor(io / 0x100000000) % 0x100000000,
              type = io % 0x100000000,
            }
          end
        end
      end
    end
    out.recruit_scientists = ss
  end
  return out
end

-- 31.6 MIO 正式迁移版 (COrganisation / NIndustrialOrganisation,
-- §4.8.12; 附属块 history/unlocked_traits §4.8.11; 布局/落盘序 = 书)
-- 本节为正式迁移版, 覆盖 §17.4 Country.mio / §18.2 Runtime.mio_scan
-- 的过渡桥接 (Lua 后定义覆盖先定义, 预期行为)
-- legacy 死代码第二 history 块 (被首个 history 分支短路) 不迁
local MIO_ORG_VT = GAME.layout.vt.COrganisation  -- §4.8.12 COrganisation
local CC_VT2 = 0x27E7360       -- CCountry (国家数组元素 vt)
local MIOrgMT = {}
local function mk_mio_org(a) return setmetatable({ addr = a }, MIOrgMT) end

MIOrgMT.__index = function(self, k)
  local a = self.addr
  if not O.vt(a, MIO_ORG_VT) then return nil end
  if k == "org_id" then return ru32(a + 0x0C) end
  -- (MIOE): unlocked traits — MSVC RB-tree @org+320 (§4.8.11 MIO 附属块)
  -- (writer 0x140DA84B0: v4 = *(*(org+320)) 起遍历, nil 标志@node+25,
  -- trait 对象@node+32, 名 token@内联对象+8 = node+40; ALB 探针 34013)
  if k == "unlocked_traits" then
    local names = {}
    local head = rp(a + 320)
    local node = head and rp(head)
    local guard = 0
    while node and (ru8(node + 25) or 0) == 0 and guard < 512 do
      guard = guard + 1
      local tk = ru32(node + 40)
      names[#names + 1] = tk and LAYOUT.token_name(tk) or nil
      -- 后继: 右子树最左, 否则上溯
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
          local pr = rp(p + 16)
          if pr == node then
            node = p
          else
            node = p
            break
          end
        end
      end
    end
    return names
  end
  -- (MIOE): history — RH 表 @org+248 (§4.8.11; 桶布局/上界勘误 = 书)。
  -- 读侧门: date 仅当 flag b@桶+0x30 为真才发 (flag=0 条目发 date 曾出
  -- 假差异); 越界纪元/超窗 hours 置 0
  if k == "history" then
    local list = {}
    local base = a + 248
    local ent = rp(base)
    local mask = ru32(base + 12) or 0
    local extra = ru8(base + 16) or 0
    local e2 = ent
    if O.kptr(e2) then
      for idx2 = 0, math.min(mask + 1 + extra, 1024) - 1 do
        local b = e2 + 64 * idx2
        local d4 = ru8(b + 4) or 0
        if d4 ~= 0 and d4 ~= 0xFE then
          local ty, id = ru32(b + 8) or 0, ru32(b + 12) or 0
          local dflag = ru8(b + 0x30) or 0
          local dh = 0
          if dflag ~= 0 then
            dh = ru32(b + 0x20) or 0
            -- 上界放宽 — mod 纪年远超 2000 年窗 ("3090.x" 实际
            -- 小时 ≈70.87M 被 61.32M 上界夹掉; 引擎真基准 ≈60.76M=1936)
            if dh < 43800000 or dh > 300000000 then
              dh = 0
            end
          end
          list[#list + 1] = {
            eq_type = ty, eq_id = id,
            date_h = dh,
            units = ru32(b + 0x38) or 0,  -- i32 符号转换在段侧 (sv2_sec_c_production)
          }
        end
      end
    end
    return list
  end
  if k == "org_type" then return ru32(a + 0x08) end
  if k == "name" then return U.sso(a + 0x60) end
  if k == "icon" then return U.sso(a + 0x80) end
  if k == "research_bonus" then
    local q = rp(a + 0xA0)
    return q and q * 1e-5 or nil        -- 定点 ×1e-5
  end
  if k == "funds" then
    local q = rp(a + 0x128)
    return q and q * 1e-5 or nil        -- 定点 ×1e-5
  end
  if k == "funds_gain" then
    local q = rp(a + 0xC8)
    return q and q * 1e-5 or nil
  end
  if k == "funds_raw" then return rp(a + 0x128) end
  if k == "task_capacity" then return ru32(a + 0xA8) end
  if k == "size" then return ru32(a + 0x130) end
  if k == "points" then return ru32(a + 0x134) end
  if k == "upgrades" then
    -- writer AE850(12393, *(u8*)(a+312)) = yes/no 布尔 (0x138=312)
    return (U.a8(a + 0x138) == 1) and 1 or 0
  end
  -- =====: MIO 四个成本字段 (×1e-5 i64) =====
  -- 探针 GER_1 raw: a+160=5000(0.05 research_bonus 已验) /
  -- a+176=10000(0.1) / a+200=100000(1.0 funds_gain 已验) /
  -- a+208=100000(1.0); 相邻 a+184 / a+192 = 0
  if k == "research_assign_cost" then
    local q = rp(a + 176); return q and q * 1e-5 or nil
  end
  if k == "production_assign_cost" then
    local q = rp(a + 184); return q and q * 1e-5 or nil
  end
  if k == "design_team_change_cost" then
    return ru32(a + 192) or 0
  end
  if k == "add_mio_funds_gain_factor" then
    -- 探针定案: 存档 1.25(3 例)/1.05(1 例) 在 MIO 对象内唯一命中
    -- a+0xC8 = 125000/105000 (4/4 反例全中); 旧 "funds_gain" 键读的
    -- 也是 a+0xC8 — 实为同一字段 (存档无 funds_gain 键)
    local q = rp(a + 200); return q and q * 1e-5 or nil
  end
  if k == "policies" then
    local d, n = rp(a + 0x170), ru32(a + 0x17C)
    if not O.kptr(d) or not n or n > 64 then return nil end
    local t = {}
    for i = 0, n - 1 do t[#t + 1] = ru32(d + 4 * i) end
    return t
  end
  if k == "allowed_policies" then
    -- (writer 0x140DA84B0): u32 token 数组 {d@+368, c@+380},
    -- c>0 才写块; 元素 AAFC0 写 token 名
    local d, n = rp(a + 368), ru32(a + 380)
    if not O.kptr(d) or not n or n > 256 then return nil end
    local t = {}
    for i = 0, n - 1 do
      local tok = ru32(d + 4 * i)
      t[#t + 1] = LAYOUT.token_name(tok) or ("?" .. tostring(tok))
    end
    return t
  end
  return nil
end

-- GAME.objects.mio 同构: 指定国家 MIO 组织列表 (正式迁移版,
-- 覆盖 §17.4 桥接; pm = cc+0xF68 CProductionStatus §4.8,
-- org 容器 {d@+0x130, c@+0x13C})
function Country.mio(self)
  local cc = self.addr
  if not O.vt(cc, CC_VT2) then return nil end
  local pm = rp(cc + 0xF68)
  if not O.kptr(pm) then return nil end
  local d, n = rp(pm + 0x130), ru32(pm + 0x13C)
  local out = {}
  if O.kptr(d) and n and n > 0 and n < 65536 then
    for i = 0, n - 1 do
      local e = rp(d + 8 * i)
      if O.kptr(e) and rp(e) == BASE + MIO_ORG_VT then
        out[#out + 1] = mk_mio_org(e)
      end
    end
  end
  return out
end

-- 全部有 MIO 的国家扫描 {{idx=国家下标, orgs=代理列表}, ...}
-- (正式迁移版, 覆盖 §18.2 桥接; 国家数组 = gs+0x310, §1.2/§4.3)
function Runtime.mio_scan(self)
  local g = self.gs()
  if not g then return {} end
  local cdata, ccount = rp(g + 0x310), ru32(g + 0x31C)
  local out = {}
  if not O.kptr(cdata) or not ccount or ccount > 1000 then return out end
  for i = 0, ccount - 1 do
    local cc = rp(cdata + 8 * i)
    if O.kptr(cc) and rp(cc) == BASE + CC_VT2 then
      local pm = rp(cc + 0xF68)
      if O.kptr(pm) then
        local d, n = rp(pm + 0x130), ru32(pm + 0x13C)
        if O.kptr(d) and n and n > 0 and n < 65536 then
          local orgs = {}
          for k = 0, n - 1 do
            local e = rp(d + 8 * k)
            if O.kptr(e) and rp(e) == BASE + MIO_ORG_VT then
              orgs[#orgs + 1] = mk_mio_org(e)
            end
          end
          if #orgs > 0 then out[#out + 1] = { idx = i, orgs = orgs } end
        end
      end
    end
  end
  return out
end

-- 31.7 strategic_air_deep (依赖 §13 SA2/Base2MT/SAC2MT; 布局 = 书:
-- §4.15.1 管理器 / §4.15.6 CAirRegionCombatData / §4.15.7
-- SAirWingCombatData / §4.15.8 基地两容器)
-- 解析 SEquipmentPool (嵌 SAirWingCombatData+88)
local function awcd_equipment(pool)
  if not O.kptr(pool) then return nil end
  local d, n = rp(pool + 0x20), ru32(pool + 0x2C)
  if not O.kptr(d) or not n or n > 100 then return nil end
  local out = {}
  for i = 0, n - 1 do
    local e = d + 16 * i
    local vp, amt = rp(e), rp(e + 8)
    local vid = O.kptr(vp) and ru32(vp + 0xC) or nil
    out[#out + 1] = { variant_id = vid, amount = (amt or 0) / 1e5 }
  end
  return out
end

-- 单条 SAirWingCombatData → 平面记录 (R = Runtime, tag 查询)
local function awcd_record(e, R)
  local function tag_str(tid)   -- §1.2 tag 串表反查 (经 Runtime.tag)
    if not tid or tid == 0 then return "" end
    return R:tag(tid) or ""
  end
  local rec = {
    wing_id = ru32(e + 8),
    time = ru32(e + 12),
    -- 换槽定案 (writer 0x141951050 token 直证
    -- 11450=mission@+20, 10730=count@+16; 旧注记反)
    mission = ru32(e + 20),
    count = ru32(e + 16),
    destination = U.a8(e + 24),
    ground_attack = U.a8(e + 25),
    tag = tag_str(ru32(e + 80)),
  }
  local pool = e + 88
  -- allow_zero = b@池+56 (writer 0x140FFDB00; 旧 pool+16 误)
  rec.allow_zero = U.a8(pool + 56)
  rec.equipment = awcd_equipment(pool)
  return rec
end

-- 单个 CAirRegionCombatData (§4.15.6) → {tag=..., friend={}, enemy={}}
local function arcdata_record(p, R)
  local tag = ""
  local tid = ru32(p + 56)
  if tid and tid ~= 0 then tag = R:tag(tid) or "" end
  local function collect(base, cnt_off)
    local d, n = rp(p + base), ru32(p + base + cnt_off)
    local out = {}
    -- 防御界仅防垃圾指针 (writer 无门; 旧 <64 在 1940 大会战整侧吞列,
    -- 32k 条事故, 段侧已同修)
    if O.kptr(d) and n and n > 0 and n < 4096 then
      for i = 0, n - 1 do out[#out + 1] = awcd_record(d + 152 * i, R) end
    end
    return out
  end
  return { tag = tag, friend = collect(32, 12), enemy = collect(8, 12) }
end

function Runtime.strategic_air_deep(self)
  local g = self.gs()
  local mgr = g and rp(g + 0x690)
  if not O.vt(mgr, SA2.mgr) then return nil end
  local bases = {}
  for _, p in ipairs(cont_elems(mgr, 0x90, SA2.airbase)) do
    local ab = setmetatable({ addr = p, R = self }, Base2MT)
    bases[#bases + 1] = {
      addr = p,
      id_pair = ab.id_pair,
      state = ab.state,
      capacity = ab.capacity,
      base_flag = ab.base_flag,
      level = ab.level,
      allow_equipment_type = ab.allow_equipment_type,
      countries = ab.country_slots,
    }
  end
  -- 载具基地: mgr+0xD8 容器 (legacy 无 vt 过滤, 与 §13 cont_elems 不同)
  do
    local d, c = rp(mgr + 0xD8), ru32(mgr + 0xE4)
    if O.kptr(d) and c and c > 0 and c < 100000 then
      for i = 0, c - 1 do
        local p = rp(d + 8 * i)
        if O.kptr(p) then
          local ab = setmetatable({ addr = p, R = self }, Base2MT)
          bases[#bases + 1] = {
            addr = p,
            id_pair = ab.id_pair,
            carrier = ab.carrier,
            state = ab.state,
            capacity = ab.capacity,
            base_flag = ab.base_flag,
            level = ab.level,
            allow_equipment_type = ab.allow_equipment_type,
            countries = ab.country_slots,
          }
        end
      end
    end
  end
  -- 每国: naval_strike_remaining + combat_history
  local navies = {}
  local histories = {}
  local d30, n30 = rp(mgr + 0x30), ru32(mgr + 0x3C)
  if O.kptr(d30) and n30 and n30 < 65536 then
    for i = 0, n30 - 1 do
      local sa = rp(d30 + 8 * i)
      if O.kptr(sa) and rp(sa) == BASE + SA2.sa_country then
        local c = setmetatable({ addr = sa }, SAC2MT)
        local tag = ""
        local tid = ru32(sa + 0x90)
        if tid and tid ~= 0 then tag = self:tag(tid) or "" end
        -- naval_strike_remaining: u32 数组 {d@+248, cnt@+260}
        local nd, nn = rp(sa + 248), ru32(sa + 260)
        if O.kptr(nd) and nn and nn > 0 and nn < 10000 then
          local vals = {}
          for j = 0, nn - 1 do vals[#vals + 1] = ru32(nd + 4 * j) or 0 end
          navies[#navies + 1] = { tag = tag, values = vals }
        end
        -- combat_history: CAirRegionCombatData 指针数组 (SAC2MT 保留原下标)
        local chs = c.combat_history or {}
        for _, ch in ipairs(chs) do
          histories[#histories + 1] = { tag = tag,
            hid = ch.idx, data = arcdata_record(ch.ptr, self) }
        end
      end
    end
  end
  return { bases = bases, navies = navies, histories = histories }
end

-- ============================================================
-- §33 国家级杂项族 (legacy Objects.operations_top / char_subblocks /
-- state_buildings / equipment_market_country / intel_sources /
-- country_variables / country_misc / navy_theaters /
-- resources_extra_origins / scheduled_variants / production_misc /
-- navy / ai_strategy / ai_state / dynamic_modifiers 正式迁移)
-- ============================================================

-- neb stat_idx → token (writer 0x1413D34D0 switch, 78 项;
-- 值与 v2 §30.6 STAT2TOK / legacy 6068-6147 同源, 本文件自持一份)
local N33_STAT2TOK = {
  [0] = 11950, [1] = 10836, [2] = 11956, [3] = 13733, [4] = 11960,
  [5] = 11961, [6] = 12196, [7] = 13551, [8] = 13573, [9] = 12744,
  [10] = 12597, [11] = 11887, [12] = 11959, [13] = 13838, [14] = 13375,
  [15] = 14415, [16] = 15138, [17] = 10106, [18] = 10121, [19] = 11965,
  [20] = 11967, [21] = 12287, [22] = 12288, [23] = 10219, [24] = 10221,
  [25] = 15351, [26] = 15350, [27] = 15354, [28] = 15353, [29] = 12310,
  [30] = 11972, [31] = 12442, [32] = 12965, [33] = 12332, [34] = 13362,
  [35] = 14656, [36] = 14657, [37] = 12011, [38] = 12101, [39] = 15191,
  [40] = 12077, [41] = 12089, [42] = 16333, [43] = 12975, [44] = 12976,
  [45] = 12977, [46] = 12236, [47] = 11958, [48] = 11962, [49] = 12238,
  [50] = 12336, [51] = 12335, [52] = 12440, [53] = 12441, [54] = 13166,
  [55] = 13269, [56] = 15422, [57] = 19874, [58] = 16415, [59] = 16419,
  [60] = 12330, [61] = 11948, [62] = 11954, [63] = 12099, [64] = 12100,
  [65] = 12668, [66] = 13572, [67] = 593, [68] = 10811, [69] = 11955,
  [70] = 15713, [71] = 11901, [72] = 11964, [73] = 17093, [74] = 14532,
  [75] = 14531, [76] = 12153, [77] = 11951,
}

-- 海军 vtable RVA (legacy NAVY 表)
local N33_NAVY = { mgr = 0x29732e0, navy = 0x2973260, base = 0x29731c0 }

-- u32 位型 → IEEE754 f32 (legacy u32_as_f32; tuning_factor 用)
local function N33_u32_as_f32(bits)
  if not bits or bits == 0 then return 0 end
  local s = math.floor(bits / 2 ^ 31) % 2
  local e = math.floor(bits / 2 ^ 23) % 256
  local m = bits % 2 ^ 23
  local v
  if e == 0 then v = m / 2 ^ 23 * 2 ^ -126
  else v = (1 + m / 2 ^ 23) * 2 ^ (e - 127) end
  if s == 1 then v = -v end
  return v
end

-- ai_strategy 112 槽取数 (legacy ai_slot): 槽 24B {壳@0, data@+8,
-- count@+16, cap@+20}
local function N33_ai_slot(host, i)
  local h = host + 104 + 24 * i
  local d, c = rp(h + 8), ru32(h + 16)
  if not O.kptr(d) or not c or c <= 0 or c >= 4096 then return nil end
  return d, c
end

-- 33.1 country.operations 全量 (§4.11.15 CCountryOperationManager
-- @cc+5544; 结构知识唯一实现, 段层 sv2_sec_c_operations 只按写序发射)。
-- ⚠ 原 Country.operations_top 仅 priority 一叶且全库无消费者, 已并入。
local OPS_MISSION_TOK = { [0] = 12789, 15642, 19232, 15643, 19233, 19228,
    19229, 19230, 19231 }   -- §4.11.15 mission 槽 token 映射 (9 项)
function Country.operations(self)
  local ops = rp(self.addr + 5544)
  if not O.kptr(ops) then return nil end
  local out = { addr = ops, priority = ru32(ops + 88) }
  -- finished (§4.11.15 CCountryFinishedOperations; 外 48B 桶 RH @ops+40
  -- {data@16, mask@28, extra@32}, dist@bk+4, 名 tok@bk+8; 内 12B 桶
  -- {dist@0, t@+4, n@+8}) → pairs 按 t 升序 = 写序
  out.finished = {}
  do
    local fin = ops + 40
    local data, mask = rp(fin + 16), ru32(fin + 28)
    local extra = ru8(fin + 32) or 0
    if O.kptr(data) and mask and mask > 0 and mask < LAYOUT.lim.PTR_SANE then
      for b = 0, mask + extra do
        local bk = data + 48 * b
        local dist = ru8(bk + 4) or 0
        if dist ~= 0 and dist ~= 0xFE then
          local nm = LAYOUT.token_name(ru32(bk + 8))
          local idata = rp(bk + 24)
          local imask, iextra = ru32(bk + 36) or 0, ru8(bk + 40) or 0
          if nm and O.kptr(idata) and imask > 0
              and imask < LAYOUT.lim.PTR_SANE then
            local prs = {}
            for j = 0, imask + iextra do
              local ib = idata + 12 * j
              local d2 = ru8(ib) or 0
              if d2 ~= 0 and d2 ~= 0xFE then
                prs[#prs + 1] = { t = ru32(ib + 4) or 0,
                                  n = ru32(ib + 8) or 0 }
              end
            end
            table.sort(prs, function(x, y) return x.t < y.t end)
            out.finished[#out.finished + 1] = { name = nm, pairs = prs }
          end
        end
      end
    end
  end
  -- running (§4.11.15/§4.11.12; 8B 指针容器 @ops+16/+28)
  out.running = {}
  local rd, rc = rp(ops + 16), ru32(ops + 28)
  if O.kptr(rd) and rc and rc > 0 and rc < LAYOUT.lim.PTR_SANE then
    for i = 0, rc - 1 do
      local op = rp(rd + 8 * i)
      if O.kptr(op) then
        local def = rp(op + 72)
        local nm = O.kptr(def) and LAYOUT.token_name(ru32(def + 8)) or nil
        if nm then
          local civ = rp(op + 48); civ = civ and LAYOUT.as_i64(civ) or nil
          local tot = rp(op + 56); tot = tot and LAYOUT.as_i64(tot) or nil
          local rec = {
            addr = op, name = nm,
            id_type = ru32(op + 8), id_id = ru32(op + 12),
            date_h = ru32(op + 112), duration = ru32(op + 128),
            civilian_factories = civ, total = tot,
            target_tid = ru32(op + 88), prepared_h = ru32(op + 208),
          }
          local tp = rp(op + 96)
          rec.target_provinces = O.kptr(tp) and ru32(tp + 164) or nil
          -- resources (§4.11.12/§4.11.16; {d@+344, c@+356} 32B 元:
          -- amount@0 / days@+8 / def*@+16 / flag u8@+24)
          rec.resources = {}
          local rsd, rsc = rp(op + 344), ru32(op + 356)
          if O.kptr(rsd) and rsc and rsc > 0 and rsc < LAYOUT.lim.PTR_SANE then
            for ri = 0, rsc - 1 do
              local re = rsd + 32 * ri
              local amt = rp(re); amt = amt and LAYOUT.as_i64(amt) or nil
              local it = { flag = ru8(re + 24) or 0, amount = amt,
                           days = ru32(re + 8) or 0 }
              if it.flag == 0 then
                local dp = rp(re + 16)
                it.def_name = O.kptr(dp)
                    and LAYOUT.token_name(ru32(dp + 8)) or nil
              end
              rec.resources[#rec.resources + 1] = it
            end
          end
          -- return_on_complete ({d@+368, c@+380} 16B 元, 值@+8)
          -- ⚠ roc_n 原样携带: 元素可读失败出 nil 洞, 段层需按原下标编号
          rec.return_on_complete, rec.roc_n = {}, 0
          local rod, roc = rp(op + 368), ru32(op + 380)
          if O.kptr(rod) and roc and roc > 0 and roc < LAYOUT.lim.PTR_SANE then
            rec.roc_n = roc
            for oi = 0, roc - 1 do
              local v = rp(rod + 16 * oi + 8)
              rec.return_on_complete[oi + 1] =
                  v and LAYOUT.as_i64(v) or nil
            end
          end
          -- equipment 池 (CEquipmentVariantPool 内嵌 @op+272) = 共享 reader
          rec.equipment = U.pool_read(op + 272,
                                      { max = LAYOUT.lim.PTR_SANE })
          -- operative_slots ({d@+224, c@+236} 56B 元: 对@0/+4,
          -- resume@+8, mission 旗@+48, mission 块@+16)
          rec.operative_slots = {}
          local sd, sc = rp(op + 224), ru32(op + 236)
          if O.kptr(sd) and sc and sc > 0 and sc < LAYOUT.lim.PTR_SANE then
            for j = 0, sc - 1 do
              local el = sd + 56 * j
              local s2 = { op_type = ru32(el), op_id = ru32(el + 4),
                resume = ru32(el + 8), mission_flag = ru8(el + 48) or 0 }
              if s2.mission_flag ~= 0 then
                local mi = el + 16
                s2.mission_tok = OPS_MISSION_TOK[ru32(mi + 8) or -1]
                s2.mission_target_tid = ru32(mi + 12)
                local mst = rp(mi + 16)
                s2.mission_state = O.kptr(mst) and ru32(mst + 88) or nil
              end
              rec.operative_slots[#rec.operative_slots + 1] = s2
            end
          end
          -- phases ({d@+248, c@+260} 8B 指针, 名@pe+8)
          -- ⚠ phases_n 原样携带: 名解析失败出 nil 洞, 段层门 = 任一失败整块不写
          rec.phases, rec.phases_n = {}, 0
          local pd, pc = rp(op + 248), ru32(op + 260)
          if O.kptr(pd) and pc and pc > 0 and pc < LAYOUT.lim.PTR_SANE then
            rec.phases_n = pc
            for j = 0, pc - 1 do
              local pe = rp(pd + 8 * j)
              rec.phases[j + 1] = O.kptr(pe)
                  and LAYOUT.token_name(ru32(pe + 8)) or nil
            end
          end
          out.running[#out.running + 1] = rec
        end
      end
    end
  end
  return out
end

-- 33.1b country.history (§4.3.13 CLoopHistory @cc+4040; 固定 3 队列对象
-- @+16/+24/+32; 队列 {data@+8, rows@+20, max@+32, offset@+36, is_full@+40};
-- cols = *(qc+56)+52 parent 回读)。
-- ⚠ index 原样携带: 无效队列在存档里留路径空洞 (queue.0/.2 有 .1 无),
-- 段层须按原下标发射; cells 仅在 rows/cols 门过且全行有效且非全零时给。
function Country.history_queues(self)
  local H = rp(self.addr + 4040)
  if not O.kptr(H) then return nil end
  if rp(H) ~= BASE + GAME.layout.vt.CLoopHistory then return nil end
  local out = { queues = {} }
  for qi = 0, 2 do
    local C = rp(H + 16 + 8 * qi)
    if O.kptr(C) and rp(C) == BASE + GAME.layout.vt.CLoopHistoryEntry then
      local q = { index = qi, max_elements = ru32(C + 32) or 0,
                  offset = ru32(C + 36) or 0, is_full = ru8(C + 40) or 0 }
      local rows = ru32(C + 20) or 0
      local desc = rp(C + 56)
      local cols = O.kptr(desc) and (ru32(desc + 52) or 0) or 0
      local buf = rp(C + 8)
      if rows > 0 and rows <= LAYOUT.lim.PTR_SANE and cols > 0 and cols <= 64
          and O.kptr(buf) then
        local cells, bad, any = {}, false, false
        for i = 0, rows - 1 do
          local h1 = rp(buf + 8 * i)          -- 行句柄
          local row = O.kptr(h1) and rp(h1)   -- 行数据基址
          if not O.kptr(row) then bad = true break end
          for j = 0, cols - 1 do
            local v = rp(row + 8 * j) or 0
            v = LAYOUT.as_i64(v)
            if v ~= 0 then any = true end
            cells[#cells + 1] = v
          end
        end
        if not bad and any then q.cells = cells end
      end
      out.queues[#out.queues + 1] = q
    end
  end
  return out
end

-- 33.2 角色子块 (§4.4 CCharacter: country_leaders 容器@+152 /
-- CScientist*@+192; 载荷 §4.4.16 CCountryLeader / §4.4.17 CScientist)
function Runtime.char_subblocks(self, char_id)
  local ch = self:character(char_id)
  if not ch or not O.kptr(ch.addr) then return nil end
  local p = ch.addr
  local out = {}
  -- country_leaders: RB-tree 中序遍历 (_Left 起 FEDD0 后继)
  local leads = {}
  local cont = rp(p + 152)
  if O.kptr(cont) then
    local function tmin(n)
      local g = 0
      while O.kptr(n) and n ~= cont and g < 64 do
        local l = rp(n)
        if not O.kptr(l) or l == cont then return n end
        n = l; g = g + 1
      end
      return n
    end
    local function tsucc(n)
      local r = rp(n + 0x10)
      if O.kptr(r) and r ~= cont then return tmin(r) end
      local g = 0
      while O.kptr(n) and n ~= cont and g < 64 do
        local pa = rp(n + 8)
        if not O.kptr(pa) or pa == cont then return cont end
        if rp(pa + 0x10) ~= n then return pa end
        n = pa; g = g + 1
      end
      return cont
    end
    local node = rp(cont)
    local guard = 0
    while O.kptr(node) and node ~= cont and guard < 64 do
      guard = guard + 1
      local lead = rp(node + 40)
      if O.kptr(lead) then
        local rec = {}
        local dg = rp(lead + 64)
        if dg and dg ~= 0 then rec.desc = U.sso(lead + 48) or "" end
        local ideo = rp(lead + 320)
        if O.kptr(ideo) then
          rec.ideology = LAYOUT.token_name(ru32(ideo + 8) or 0)
        end
        local ts = {}
        local td, tc = rp(lead + 80), ru32(lead + 92)
        if O.kptr(td) and tc and tc > 0 and tc < 32 then
          for i = 0, tc - 1 do
            local t = rp(td + 8 * i)
            if O.kptr(t) then
              ts[#ts + 1] = tostring(LAYOUT.token_name(ru32(t + 8) or 0))
            end
          end
        end
        rec.traits = ts
        local eh = ru32(lead + 304)
        if eh and eh ~= 0 then
          -- 写条件 ≠ dword_14306EB50 (默认哨兵, 运行时读静态)
          local dflt = ru32(BASE + 0x306EB50) or 0
          if eh ~= dflt then rec.expire_hours = eh end
        end
        -- id u32@+328: 门 = ≠ -1 (0xFFFFFFFF); **有符号域** — 存档实证
        -- 出现 -2 (save=-2 而 mem 旧打印 4294967294) → 过门后按 i32 还原
        local lid = ru32(lead + 328)
        if lid and lid ~= 0xFFFFFFFF then
          lid = LAYOUT.as_i32(lid)
          rec.id = lid
        end
        leads[#leads + 1] = rec
      end
      node = tsucc(node)
    end
  end
  out.leaders = leads
  -- scientist
  local sci = rp(p + 192)
  if O.kptr(sci) then
    local s = {}
    local ts = {}
    local td = rp(sci + 48)
    local tc = ru32(sci + 60)
    if O.kptr(td) and tc and tc > 0 and tc < 32 then
      for i = 0, tc - 1 do
        local t = rp(td + 8 * i)
        if O.kptr(t) then
          ts[#ts + 1] = tostring(LAYOUT.token_name(ru32(t + 8) or 0))
        end
      end
    end
    s.traits = ts
    -- skills {d@sci+264+8, cnt@+20} 条目 32B {spec tok@0, 嵌入对象@+8};
    -- 技能对象 (writer 0x14144E480, 键 0x2E9A=experience / 0x286C=level,
    -- >0 才写): experience i64 ×1e-5 (AE590) / level i32@+16
    local sk = {}
    local skd = rp(sci + 264 + 8)
    local skc = ru32(sci + 264 + 20)
    if O.kptr(skd) and skc and skc > 0 and skc < 16 then
      for i = 0, skc - 1 do
        local e = skd + 32 * i
        local tok = ru32(e)
        local obj = e + 8
        if tok then
          local nm = LAYOUT.token_name(tok) or ("t" .. tok)
          local exq = rp(obj + 8) or 0
          local exp2 = exq / 1e5
          local lvl = ru32(obj + 16) or 0
          sk[#sk + 1] = string.format("%s|%d|%.5f", nm, lvl, exp2)
        end
      end
    end
    s.skills = sk
    local dg = rp(sci + 32)
    if dg and dg ~= 0 then s.desc = U.sso(sci + 16) or "" end
    s.is_assigned = U.a8(sci + 304)
    local inj = ru32(sci + 308)
    if inj and inj > 0 then s.injured = inj end
    out.scientist = s
  end
  return out
end

-- 33.3 州级建筑 (§4.13 CState, 州表 = gs+0x2C8; CBuildingStatus
-- 内嵌 @st+288, 布局 = 书)
function Runtime.state_buildings(self, state_id)
  local g = self.gs()
  local sarr = g and rp(g + 0x2C8)
  if not O.kptr(sarr) then return nil end
  local st = rp(sarr + 8 * (state_id or 1))
  if not O.vt(st, GAME.layout.vt.CState) then return nil end
  local bs = st + 288
  if rp(bs) ~= BASE + GAME.layout.vt.CBuildingStatus then return nil end
  local out = { addr = bs, state_addr = st, count = ru32(bs + 68) or 0,
    list = {} }
  local d, c = rp(bs + 56), ru32(bs + 68)
  if not O.kptr(d) or not c or c > 512 then return out end
  for j = 0, c - 1 do
    local e = rp(d + 8 * j)
    if O.kptr(e) then
      local tok = ru32(e + 8)
      local lv = ru32(e + 0x40) or 0
      out.list[#out.list + 1] = {
        addr = e,
        type_token = tok,
        type = (tok and (LAYOUT.token_name(tok)))
          or ("token_" .. tostring(tok)),
        level = lv % 65536,
        healthy_levels = math.floor(lv / 65536),
        partial_health = ru32(e + 0x48),
        repair_speed_factor = (rp(e + 80) or 100000) / 100000,  -- ≠1e5 才写
      }
    end
  end
  return out
end

-- 33.4 国际装备市场 per-country (§4.23.2; market 挂 cc+4024 双层读法,
-- automation 三布尔/内层 stockpile 池 = 书 §4.23.2 表)
-- stockpile 池 = U.pool_read(mk+56) (布局引 LAYOUT.off.variant_pool)。
-- ⚠ 原实现按「kptr(var) 即收」遍历, 漏了 writer 的 amount≠0∨az 跳过规则
-- → 与段层发射不一致; 已收敛到共享 reader (结构知识唯一实现)。
function Country.equipment_market_country(self)
  local outer = rp(self.addr + 4024)
  if not O.kptr(outer) then return nil end
  local mk = rp(outer)
  if not O.kptr(mk) then return nil end
  return {
    addr = mk,
    auto_accept_market_access = (U.a8(outer + 96) == 1) and "yes" or "no",
    auto_send_market_access = (U.a8(outer + 97) == 1) and "yes" or "no",
    auto_accept_purchase = (U.a8(outer + 98) == 1) and "yes" or "no",
    stockpile = U.pool_read(mk + 56),
    subsidies = U.subsidy_list_read(rp(outer + 40), ru32(outer + 52),
                                    self.R),
  }
end

-- 33.5 intel_source 三挂载 (§4.11 情报源: radar cc+4416 /
-- tokens cc+5552 / cryptology ag+288; 元素布局/开键条件 = 书
-- §4.3 +4416 行与 §4.11)
-- 内存观测 (读侧参考): 三挂载 pool 恒 3/1/2, id = 国家数组 idx+1,
-- discriminant 全 0
function Country.intel_sources(self)
  local function isrc(el)
    if not O.kptr(el) then return nil end
    if rp(el) ~= (BASE + GAME.layout.vt.CIntelSource) then return nil end
    local idx, pool = ru32(el + 8), ru32(el + 12)
    -- 14196B990 开键条件: idx>0 且 pool≠0 (第三关 = tag 查表非空,
    -- 由 tag 读结果覆盖)
    if not idx or idx <= 0 or not pool or pool == 0 then return nil end
    return { country = self.R:tag(idx), pool = pool,
      id = ru32(el + 16), discriminant = ru32(el + 20) }
  end
  local out = {}
  local ag = rp(self.addr + 4032)
  out.radar = isrc(self.addr + 4416)
  local tp = rp(self.addr + 5552)
  out.tokens = O.kptr(tp) and isrc(tp + 16) or nil
  out.cryptology = O.kptr(ag) and isrc(rp(ag + 288) + 16) or nil
  return out
end

-- 33.5b operation_assets (§4.11.17 CCountryOperationTokenManager cc+5552;
-- RH 表 = data@+48, mask u32@+60, extra u8@+64, 桶 40B {hash@0,
-- dist u8@+4, tag id u32@+8, 名单 {d@+16, c@+28}})。键 = tag 串表
-- (gs+0x358) SSO 名; 值 = token id 名单, writer 门 = **全部** id 经
-- lexer 解析成功 (任一失败整桶不写); 字典序排序/空格连在段侧。
function Country.operation_assets(self)
  local obj = rp(self.addr + 5552)
  if not O.kptr(obj) then return { assets = {} } end
  local g = Runtime.gs()
  local ttab = g and rp(g + 0x358) or nil
  local assets = {}
  local d = O.kptr(ttab) and rp(obj + 48) or nil
  local mask = O.kptr(obj) and ru32(obj + 60) or 0
  local extra = O.kptr(obj) and (ru8(obj + 64) or 0) or 0
  if O.kptr(d) and mask > 0 and mask < 4096 then
    for b = 0, mask + extra do
      local bk = d + 40 * b
      local dist = ru8(bk + 4) or 0
      if dist ~= 0 and dist ~= 0xFE then
        local tid = ru32(bk + 8)
        local ld, lc = rp(bk + 16), ru32(bk + 28)
        if tid and tid > 0 and tid < 4096 and O.kptr(ld) and lc
            and lc > 0 and lc < LAYOUT.lim.PTR_SANE then
          local tname = U.sso(ttab + 32 * tid)
          if tname and tname ~= "" then
            local names, ok = {}, true
            for j = 0, lc - 1 do
              local nm = LAYOUT.token_name(ru32(ld + 4 * j) or 0)
              if not nm or nm == "" then ok = false break end
              names[#names + 1] = nm
            end
            if ok then assets[#assets + 1] = { tag = tname, names = names } end
          end
        end
      end
    end
  end
  return { addr = obj, assets = assets }
end

-- 33.6 国家 variables (§4.13.2 CVariables; cc+536; 布局/桶/值 ×1e-5 = 书)
-- rh_iter 参数 = 相对 vowner 基 (旧 ht=vowner+0x10 基准曾混绝对/相对)。
-- maxn=262144: 议会机制 mod 实测 ~3.1 万变量 → 桶数到 131072 档;
-- PTR_SANE(4096)/PTR_HUGE(65536) 均不足 → rh_iter 返 nil = 整表蒸发。
-- 值 = i64 有符号 /100000 定点 (桶 @+0x28)。
function Country.country_variables(self)
  local vowner = rp(self.addr + 536)
  if not O.kptr(vowner) then return nil end
  local out = { addr = vowner,
    random = { ru32(vowner + 12) or 0, ru32(vowner + 8) or 0 },
    vars = {} }
  local buckets = LAYOUT.rh_iter(vowner, { data = 0x18, mask = 0x24,
    count = 0x20, stride = 0x30, maxn = 262144 })
  for _, b in ipairs(buckets or {}) do
    local dist = ru32(b + 4)
    if dist and (dist & 0xFF) ~= 0 and (dist & 0xFF) ~= 0xFE
        and (dist & 0xFF) ~= 0xFF then
      local nm = U.sso(b + 8)
      local v = rp(b + 0x28)
      if v then v = LAYOUT.as_i64(v) end
      local val = v and v / 100000 or nil
      if nm and val then
        out.vars[#out.vars + 1] = { name = nm, value = val }
      end
    end
  end
  return out
end

-- 33.7 countries 小标量族 focus 块 + original_research_slots +
-- reinforcement.priority + ai.allowed_strategy_plans +
-- ai.military_access + 扩 12 键 (§4.3 / focus §4.3.14 /
-- reinforcement §4.10 / ai §4.3.19; 布局与写门 = 书)
function Country.country_misc(self)
  local cc = self.addr
  local out = {}
  -- focus 块: 对象指针@cc+4992 CFocusStatus (§4.3.12; ser 基 = 对象指针)
  local fo = rp(cc + 4992)
  if O.kptr(fo) then
    local f = {}
    f.progress = U.fix5(fo + 56) or 0
    local cp = rp(fo + 16)
    if O.kptr(cp) then f.current = U.sso(cp + 24) end
    local pz = U.a8(fo + 176)
    if pz then f.paused = pz end
    local sd, sc = rp(fo + 32), ru32(fo + 44)
    if O.kptr(sd) and sc and sc > 0 and sc < 512 then
      for k = 0, sc - 1 do
        local e = rp(sd + 8 * k)
        if O.kptr(e) then
          local s = U.sso(e + 24)
          if s then f.shine = f.shine or {}
          f.shine[#f.shine + 1] = s end
        end
      end
    end
    local cd, ccn = rp(fo + 64), ru32(fo + 76)
    if O.kptr(cd) and ccn and ccn > 0 and ccn < 65536 then
      for k = 0, ccn - 1 do
        local e = rp(cd + 8 * k)
        if O.kptr(e) then
          local s = U.sso(e + 24)
          if s then f.completed = f.completed or {}
          f.completed[#f.completed + 1] = s end
        end
      end
    end
    out.focus = f
  end
  -- original_research_slots u32@cc+4324 (≠0 才写)
  local ors = ru32(cc + 4324)
  if ors and ors ~= 0 then out.original_research_slots = ors end
  -- reinforcement.priority u32@obj+8 (obj = *(cc+3960), ser 基 obj+24)
  local robj = rp(cc + 3960)
  if O.kptr(robj) then out.reinforcement_priority = ru32(robj + 8) end
  -- ai.allowed_strategy_plans: {d@csa+5520, c@csa+5532} 40B 元素,
  -- 名 = MSVC 串 (SSO/堆双形态)
  -- ai.military_access: {d@csa+5808} 稀疏 u32 数组
  -- csa = host+2800, host = rp(rp(cc+552)+2800) (ai_state 同款双重)
  local host = rp(cc + 552)
  local csa = O.kptr(host) and rp(host + 2800) or nil
  if O.kptr(csa) then
    csa = csa + 2800
    local pd, pc = rp(csa + 5520), ru32(csa + 5532)
    if O.kptr(pd) and pc and pc > 0 and pc < 256 then
      local plans = {}
      for k = 0, pc - 1 do
        local e = pd + 40 * k
        local s = U.sso(e)
        if s then plans[#plans + 1] = s end
      end
      if #plans > 0 then out.allowed_plans = plans end
    end
    local md = rp(csa + 5808)
    if O.kptr(md) then
      local acc = {}
      -- 738 国 mod → 军事通行数组扫描上限 439→100000
      for k = 0, 100000 do
        local v = ru32(md + 4 * k)
        if v and v ~= 0 then
          acc[#acc + 1] = tostring(k) .. ":" .. tostring(v)
        end
      end
      if #acc > 0 then out.military_access = acc end
    end
  end
  -- 扩: CCountry 小标量 12 键 (writer 0x14070C580)
  out.num_ships = ru32(cc + 4912) or 0
  out.num_armies_in_combat = ru32(cc + 4904) or 0
  out.convoys_destroyed = ru32(cc + 4916) or 0
  out.major = U.a8(cc + 5210) or 0
  out.is_top_ic_country = U.a8(cc + 5211) or 0
  out.landlocked_start = U.a8(cc + 5619) or 0
  out.templates_locked = U.a8(cc + 436) or 0
  out.reserved_dynamic_country = U.a8(cc + 5213) or 0
  out.removed_controlled_province = U.a8(cc + 5618) or 0
  local cpr = U.fix5(cc + 5632)
  if cpr then out.coastal_protection_ratio = cpr end
  -- pride_of_the_fleet id 对@cc+592 {type@+0, id@+4}
  local pt, pi = ru32(cc + 592), ru32(cc + 596)
  if pt or pi then
    out.pride_of_the_fleet = string.format("id=%d type=%d", pi or 0, pt or 0)
  end
  -- original_tag tid@cc+4876
  local otid = ru32(cc + 4876)
  if otid and otid > 0 then
    local ts = self.R:tag(otid)
    if ts and ts ~= "" and ts ~= "---" then out.original_tag = ts end
  end
  -- claims: 州 id 列表 (writer 0x3360 块, {d@*(cc+1216), c@cc+1228})
  do
    local cld = rp(cc + 1216)
    local clc = ru32(cc + 1228)
    if O.kptr(cld) and clc and clc > 0 and clc < 4096 then
      local ids = {}
      for k = 0, clc - 1 do
        ids[#ids + 1] = tostring(ru32(cld + 4 * k) or 0)
      end
      out.claims = table.concat(ids, " ")
    end
  end
  -- cached_navy_strength.sub_units: cc+728 内嵌 {d@+8, c@+20} 8B 元素
  -- {舰种 token, 数量} → "submarine=19 destroyer=18 ..."
  local nd, nc = rp(cc + 728 + 8), ru32(cc + 728 + 20)
  if O.kptr(nd) and nc and nc > 0 and nc < 128 then
    local parts = {}
    for k = 0, nc - 1 do
      local e = nd + 8 * k
      local tok = ru32(e)
      local cnt = ru32(e + 4)
      local nm = tok and (LAYOUT.token_name(tok) or ("tok" .. tostring(tok)))
      if nm and cnt and cnt ~= 0 then
        parts[#parts + 1] = nm .. "=" .. cnt
      end
    end
    if #parts > 0 then out.cached_navy = table.concat(parts, " ") end
  end
  return out
end

-- 33.8 navy_theater nt = rp(cc+352) (§4.24.11 CNavyTheater /
-- §4.24.12 CNavyTheaterGroup; 群元素布局/写门 = 书)
function Country.navy_theaters(self)
  local nt = rp(self.addr + 352)
  if not O.kptr(nt) then return nil end
  local d, c = rp(nt + 16), ru32(nt + 28)
  local out = { list = {} }
  if not (O.kptr(d) and c and c > 0 and c < 64) then return out end
  for j = 0, c - 1 do
    -- 元素 = 8B 指针 (writer 0x141506960: ADEC0(0x35D1, *v4) 虚调用)
    local tg = rp(d + 8 * j)
    if O.kptr(tg) then
      local rec = {
        id_pair = string.format("id=%d type=%d",
          ru32(tg + 12) or 0, ru32(tg + 8) or 0),
        name = U.sso(tg + 56) or "",
        fleets = {},
        flag3cd7 = U.a8(tg + 88) or 0,
      }
      local fd, fc = rp(tg + 32), ru32(tg + 44)
      if O.kptr(fd) and fc and fc > 0 and fc < 256 then
        for k = 0, fc - 1 do
          local el = rp(fd + 8 * k)
          if O.kptr(el) then
            local ft, fi2 = ru32(el + 8), ru32(el + 12)
            if (ft and ft ~= 0) or (fi2 and fi2 ~= 0) then
              rec.fleets[#rec.fleets + 1] = string.format(
                "id=%d type=%d", fi2 or 0, ft or 0)
            end
          end
        end
      end
      out.list[#out.list + 1] = rec
    end
  end
  return out
end

-- 33.9 extra_resource_origin (§4.3.1/§4.3.3 资源/租借 rs = cc+4600 /
-- CResourceOrigin; 容器 rs+1976/元素资源向量/grr = 书 §4.3 两处表)
function Country.resources_extra_origins(self)
  local rs = rp(self.addr + 4600)
  if not O.kptr(rs) then return nil end
  local function resvec(objoff, el)
    -- 对象内嵌 @el+objoff: {ptr@+8, cnt@+20} 条目 16B {i64×1e-5, 资源token};
    -- 静态 RES_NAMES 表作废 → token_name 动态, 条目门 8→32
    local p = rp(el + objoff + 8)
    local c = ru32(el + objoff + 20) or 0
    local o = {}
    if O.kptr(p) and c > 0 and c <= 32 then
      for k = 0, c - 1 do
        local v = rp(p + 16 * k) or 0
        local rid = ru32(p + 16 * k + 8) or 0
        local nm = (rid ~= 0 and LAYOUT.token_name(rid)) or ("r" .. k)
        o[nm or ("r" .. k)] = v / 100000
      end
    end
    return o
  end
  local RES_IDX = (function()
    -- 去 '^%w+$' 过滤 (raw_mana 等下划线 mod 资源被滤 → grr 整条
    -- 丢; 与 res_slot_map wide 修复同族)
    local m = {}
    local p2 = rp(rs + 24 + 0x10 + 8)
    local c2 = ru32(rs + 24 + 0x10 + 20) or 0
    if O.kptr(p2) and c2 > 0 and c2 < 64 then
      for k2 = 0, c2 - 1 do
        local rid2 = ru32(p2 + 16 * k2 + 8) or 0
        local nm2 = (rid2 ~= 0) and LAYOUT.token_name(rid2)
        if nm2 then m[k2] = nm2 end
      end
    end
    return m
  end)()
  local d, c = rp(rs + 1976), ru32(rs + 1988)
  local out = { list = {} }
  if not (O.kptr(d) and c and c > 0 and c < 4096) then return out end
  for j = 0, c - 1 do
    local e = d + 16 * j
    local el = rp(e)
    if O.kptr(el) and rp(el) == (BASE + GAME.layout.vt.CResourceOrigin) then
      local t = {
        addr = el,
        id_pair = string.format("id=%d type=%d",
          ru32(el + 12) or 0, ru32(el + 8) or 0),
        country = nil,
        efficiency = U.fix5(el + 72),
        efficiency2 = U.fix5(el + 840),
        efficiency_due_to_lost_convoys = U.fix5(el + 80),
        request = ru32(el + 120),
        state = nil,
        destination = nil,
        resources = resvec(136, el),
        resources_unclapmed = resvec(312, el),
        buildings = resvec(664, el),
      }
      local cp = ru32(el + 24)
      if cp and cp > 0 then t.country = self.R:tag(cp) end
      local sp = rp(el + 128)
      if O.kptr(sp) then t.state = ru32(sp + 88) end
      local dp = rp(el + 976)
      if O.kptr(dp) then t.destination = ru32(dp + 88) end
      -- giver tid@条目+8 (16B 条目 {origin ptr, giver tid})
      local gtid = ru32(e + 8)
      if gtid and gtid > 0 then t.giver = self.R:tag(gtid) end
      -- given_resource_rights (writer 0x140CAF880 0x3CA1 块): 容器
      -- {d@el+992, c@el+1004} 8B {res_key u32@0 (1..7=oil..coal),
      -- tid u32@+4} (探针 ENG 实证: 7 条 key=1..7 tid=2(ENG))
      t.given_resource_rights = {}
      local gd, gc = rp(el + 992), ru32(el + 1004)
      if O.kptr(gd) and gc and gc > 0 and gc < 4096 then  -- 16 旧门未同步
        for k = 0, gc - 1 do
          local ge = gd + 8 * k
          local rk = ru32(ge)
          local rtid = ru32(ge + 4)
          local rn = RES_IDX[rk or -1]
          if rn and rtid and rtid > 0 then
            t.given_resource_rights[rn] = self.R:tag(rtid)
          end
        end
      end
      -- delivery_route 内嵌 @el+848 (CResourceDeliveryRoute,
      -- vt 0x295c320, 布局同 Country.delivery_routes 的 ROUTES 读法)
      local rt = el + 848
      if rp(rt) == BASE + GAME.layout.vt.CResourceDelivery then
        local r2 = {
          type = ru32(rt + 8) % 256,
          sender = ru32(rt + 48), receiver = ru32(rt + 52),
          convoys_owner = ru32(rt + 56),
          -- _c2 2c: blocker_tag tid i32@rt+60 (>0) / blocked_region
          -- ptr@rt+64 → u32@ptr+96
          blocker_tag = (function() local bt = ru32(rt + 60)
              return bt and bt > 0 and self.R:tag(bt) or nil end)(),
          blocked_region = (function() local bp = rp(rt + 64)
              return O.kptr(bp) and ru32(bp + 96) or nil end)(),
          dirty = (ru32(rt + 120) % 256) ~= 0,
          land_path = {}, naval_path = {},
        }
        local fs = rp(rt + 16)
        if O.kptr(fs) then r2.from_state = ru32(fs + 88) end
        local ts2 = rp(rt + 24)
        if O.kptr(ts2) then r2.to_state = ru32(ts2 + 88) end
        local fpp = rp(rt + 32)
        if O.kptr(fpp) then r2.from_port = ru32(fpp + 164) end
        local tpp = rp(rt + 40)
        if O.kptr(tpp) then r2.to_port = ru32(tpp + 164) end
        local ld, lc2 = rp(rt + 72), ru32(rt + 84)
        if O.kptr(ld) and lc2 and lc2 < 512 then
          for k = 0, lc2 - 1 do
            local sp2 = rp(ld + 8 * k)
            r2.land_path[#r2.land_path + 1] =
              O.kptr(sp2) and ru32(sp2 + 88) or nil
          end
        end
        local nd, nc2 = rp(rt + 96), ru32(rt + 108)
        if O.kptr(nd) and nc2 and nc2 < 512 then
          for k = 0, nc2 - 1 do
            local sp2 = rp(nd + 8 * k)
            r2.naval_path[#r2.naval_path + 1] =
              O.kptr(sp2) and ru32(sp2 + 88) or nil
          end
        end
        t.delivery_route = r2
      end
      out.list[#out.list + 1] = t
    end
  end
  return out
end

-- 33.10 scheduled_equipment_variants 池 {d@ps+608, c@ps+616}
-- (ps = rp(cc+0xF68) §4.8; 池/悬挂槽警示/spec 字段 = 书 §4.8 +608 行;
-- 键 = token_name(u32@arch+8) = 存档 archetype 键)
function Country.scheduled_variants(self)
  local ps = rp(self.addr + 0xF68)
  if not O.kptr(ps) then return nil end
  local d, c = rp(ps + 608), ru32(ps + 616)
  local out = { list = {} }
  if not (O.kptr(d) and c and c > 0 and c < 256) then return out end
  for k = 0, c - 1 do
    local e = d + 16 * k
    local arch = rp(e)
    local var = rp(e + 8)
    if O.kptr(arch) and O.kptr(var) then
      local rec = {
        archetype = LAYOUT.token_name(ru32(arch + 8))
          or tostring(ru32(arch + 8)),
      }
      local nm = U.sso(var + 16)
      if nm then rec.name = nm end
      local ng = U.sso(var + 48)
      if ng then rec.name_group = ng end
      local ic = U.sso(var + 0xB8)
      if ic then rec.icon = ic end
      rec.obsolete = (ru8(var + 84) or 0) ~= 0
      local mdl = U.sso(var + 144)
      if mdl then rec.model = mdl end
      local pv = ru32(var + 80)
      if pv and pv ~= 0 then rec.parent_version = pv end
      rec.io_type = ru32(var + 248) or 0
      rec.io_id = ru32(var + 252) or 0
      -- io_dbg: 调试串 rp248/rp252/type/id/u32+80/u32+84
      rec.io_dbg = string.format("%d/%d/%d/%d/%d/%d",
        rp(var + 248) or 0, rp(var + 252) or 0,
        ru32(var + 248) or 0, ru32(var + 252) or 0,
        ru32(var + 80) or 0, ru32(var + 84) or 0)
      local ud, un = rp(var + 96), ru32(var + 108)
      if O.kptr(ud) and un and un > 0 and un < 128 then
        rec.upgrades = {}
        for i = 0, un - 1 do
          local ue = ud + 16 * i
          local def = rp(ue)
          local tok = O.kptr(def) and ru32(def + 8) or nil
          local nm2 = tok and (LAYOUT.token_name(tok)
            or ("tok" .. tostring(tok))) or "?"
          rec.upgrades[#rec.upgrades + 1] = {
            name = nm2,
            level = U.a8(ue + 8) or 0,
          }
        end
      end
      local md, mn = rp(var + 120), ru32(var + 132)
      if O.kptr(md) and mn and mn > 0 and mn < 128 then
        rec.modules = {}
        for i = 0, mn - 1 do
          local me = md + 16 * i
          local slot_tok = ru32(me)
          local mo = rp(me + 8)
          local mtok = (O.kptr(mo) and U.a8(mo + 16) ~= 0)
            and ru32(mo + 8) or nil
          rec.modules[#rec.modules + 1] = {
            slot = LAYOUT.token_name(slot_tok) or tostring(slot_tok),
            module_ = mtok and LAYOUT.token_name(mtok) or nil,
          }
        end
      end
      out.list[#out.list + 1] = rec
    end
  end
  return out
end

-- 33.11 production 五族 external_rules / enable_modules /
-- discounts / named_bonuses / licenses (production_licenses serialize
-- 0x141429400, 容器内嵌 @ps+400; 宿主 §4.8 CProductionStatus)
function Country.production_misc(self)
  local cc = self.addr
  local ps = rp(cc + 0xF68)
  if not O.kptr(ps) then return nil end
  local out = {}
  -- external_rules: 28 规则 (宿主@cc+2656; 写门/defs 寻址 = 书 §4.3
  -- +2656 行; gate_i=7=can_send_volunteers)
  do
    local defs = rp(BASE + 0x33304C0)
    local rules = {}
    if O.kptr(defs) then
      for i = 0, 27 do
        -- 写门 b@+92+i (writer: 门开才 AE850)
        if (U.a8(cc + 2656 + 92 + i) or 0) ~= 0 then
          local tok = ru32(defs + 56 * i + 40)
          local nm = tok and LAYOUT.token_name(tok) or nil
          if nm and nm ~= "" then
            rules[#rules + 1] = {
              name = nm,
              value = ((U.a8(cc + 2656 + 64 + i) or 0) ~= 0)
                and "yes" or "no",
            }
          end
        end
      end
    end
    out.rules = rules
  end
  -- enable_equipment_modules: u32 token 数组 {d@ps+632, c@ps+644}
  do
    local md, mc = rp(ps + 632), ru32(ps + 644)
    if O.kptr(md) and mc and mc > 0 and mc < 512 then
      local mods = {}
      for k = 0, mc - 1 do
        local tok = ru32(md + 4 * k)
        local nm = tok and LAYOUT.token_name(tok)
        if nm then mods[#mods + 1] = nm end
      end
      out.enable_modules = mods
    end
  end
  -- discount: {d@ps+1232, c@ps+1244} 40B 条 {uses u32@0,
  -- discount ×1e-5@+8, types 容器 {d@+16, c@+24} 元素 = u32 token 内联
  -- (FRA 探针: td+0..8 = 20427/20432/20437 = light/medium/heavy
  -- _tank_flame_chassis)}
  do
    local dd, dc = rp(ps + 1232), ru32(ps + 1244)
    if O.kptr(dd) and dc and dc > 0 and dc < 128 then
      local dsc = {}
      for k = 0, dc - 1 do
        local e = dd + 40 * k
        local rec = { uses = ru32(e) or 0,
          discount = U.fix5(e + 8) or 0, types = {} }
        local td, tc = rp(e + 16), ru32(e + 24)
        if O.kptr(td) and tc and tc > 0 and tc < 64 then
          for m = 0, tc - 1 do
            local tok = ru32(td + 4 * m)
            local nm = tok and LAYOUT.token_name(tok) or nil
            if nm then rec.types[#rec.types + 1] = nm end
          end
        end
        dsc[#dsc + 1] = rec
      end
      out.discounts = dsc
    end
  end
  -- named_equipment_bonuses: {d@ps+376, c@ps+388} 200B 条
  -- (§4.23.6 加成族); CEquipmentBonus @e+64 主表 {d@e+72, c@e+84};
  -- 元素 16B {stat_idx u32, 值 i64×1e-5}, stat_idx → token 名经
  -- 0x1413D34D0 switch (78 项, N33_STAT2TOK)
  do
    local nd, nc = rp(ps + 376), ru32(ps + 388)
    if O.kptr(nd) and nc and nc > 0 and nc < 256 then
      local nbs = {}
      for k = 0, nc - 1 do
        local e = nd + 200 * k
        local rec = {
          name = U.sso(e + 0x80),
          prefix = U.sso(e + 0xA0),  -- MD AUS 活体定案: prefix SSO@+0xA0
          id = ru32(e + 0xC0) or 0,
          target = (function()
            local t = ru32(e + 0x10)
            return t and LAYOUT.token_name(t) or nil
          end)(),
          instant = (ru8(e + 0x78) ~= 0) and "yes" or "no",
          mods = {},
        }
        local md, mc = rp(e + 72), ru32(e + 84)
        if O.kptr(md) and mc and mc > 0 and mc < 256 then
          for m = 0, mc - 1 do
            local me = md + 16 * m
            local sidx = ru32(me) or 0
            local tok = N33_STAT2TOK[sidx]
            local nm = tok and LAYOUT.token_name(tok) or nil
            local v = U.fix5(me + 8)
            if nm and v then
              rec.mods[#rec.mods + 1] = { name = nm, value = v }
            end
          end
        end
        nbs[#nbs + 1] = rec
      end
      out.named_bonuses = nbs
    end
  end
  -- production_licenses: 容器内嵌 @ps+400 (CLicensedProductionStatus
  -- {avail@+8, owned@+56} 三列表与 owned_license 对象字段 = 书 §4.8 许可表)
  do
    local lic = ps + 400
    local out_lic = {}
    local ad, ac = rp(lic + 8), ru32(lic + 0x14)
    if O.kptr(ad) and ac and ac > 0 and ac < 4096 then
      for k = 0, ac - 1 do
        local el = rp(ad + 8 * k)
        if O.kptr(el) then
          out_lic[#out_lic + 1] = {
            avail_id = ru32(el + 12) or 0,
            avail_type = ru32(el + 8) or 0,
          }
        end
      end
    end
    local od, oc = rp(lic + 0x38), ru32(lic + 0x44)
    if O.kptr(od) and oc and oc > 0 and oc < 4096 then
      for k = 0, oc - 1 do
        local el = rp(od + 8 * k)
        if O.kptr(el) then
          local rec = {
            lended = ru32(el + 8) or 0,
            required = ru32(el + 0xC) or 0,
          }
          rec.owner = self.R:tag(ru32(el + 0x10))
          rec.giver = self.R:tag(ru32(el + 0x14))
          rec.start_h = ru32(el + 0x20) or 0
          local pp80 = rp(el + 80)
          if O.kptr(pp80) then
            rec.parent = string.format("id=%d type=%d",
              ru32(pp80 + 12) or 0, ru32(pp80 + 8) or 0)
          end
          rec.equipment = {}
          local eqn = ru32(el + 68) or 0
          local eqd = rp(el + 56)
          if O.kptr(eqd) and eqn > 0 and eqn < 64 then
            for m = 0, eqn - 1 do
              local ep = rp(eqd + 8 * m)
              if O.kptr(ep) then
                rec.equipment[#rec.equipment + 1] =
                  string.format("id=%d type=%d",
                    ru32(ep + 12) or 0, ru32(ep + 8) or 0)
              end
            end
          end
          out_lic[#out_lic + 1] = rec
        end
      end
    end
    out.licenses = out_lic
  end
  return out
end

-- 33.12 strategic_navy 全族 (§4.16 海军族: 管理器 §4.16.1 /
-- CStrategicNavy §4.16.5 / SRegionalConvoyData §4.16.6 /
-- CNavalUnitTransfer §4.16.7 / 基地 §4.16.8 / SNA 战史三族
-- §4.16.9-11; 布局/写门 = 书)
function Country.navy(self)
  local g = self.R.gs()
  if not g then return nil end
  local M = rp(g + 0x698)
  if not O.kptr(M) or rp(M) ~= BASE + N33_NAVY.mgr then return nil end
  local out = {
    addr = M,
    world_bases = ru32(M + 48),
    tuning_factor = N33_u32_as_f32(ru32(M + 60)),
  }
  local arr, n = rp(M + 8), ru32(M + 20)
  if not O.kptr(arr) or not n or self.idx >= n then return out end
  local S = rp(arr + 8 * self.idx)
  if not O.kptr(S) or rp(S) ~= BASE + N33_NAVY.navy then return out end
  -- 海军基地列表
  local bases = {}
  local bd, bc = rp(S + 24), ru32(S + 36)
  if O.kptr(bd) and bc and bc > 0 and bc < 4096 then
    for i = 0, bc - 1 do
      local E = rp(bd + 8 * i)
      if O.kptr(E) and rp(E) == BASE + N33_NAVY.base then
        -- ships_in_repair 容器上提 ({d@E+40, c@E+52} 8B
        -- 内联 {type@0, id@+4}, 元素 writer 0x140E9CFF0; c>0 门在段侧)
        local srd, src = rp(E + 40), ru32(E + 52) or 0
        local srlist
        if O.kptr(srd) and src > 0 and src < LAYOUT.lim.PTR_SANE then
          srlist = {}
          for q = 0, src - 1 do
            srlist[#srlist + 1] = { type = ru32(srd + 8 * q) or 0,
              id = ru32(srd + 8 * q + 4) or 0 }
          end
        end
        bases[#bases + 1] = {
          addr = E,
          province = ru32(E + 16),
          level = ru32(E + 20),
          max_level = ru32(E + 24),
          priority = (ru32(E + 32) or 0) % 256,
          ships_in_repair = ru32(E + 52),
          ships_in_repair_list = srlist,
          disabled_for = ru32(E + 76),
        }
      end
    end
  end
  out.bases = { count = #bases, list = bases }
  out.dockyards = { max_allowed = ru32(S + 440), used = ru32(S + 444) }
  out.naval_transport = ru32(S + 316)
  out.naval_accident = ru32(S + 236)
  out.task_force_templates = ru32(S + 340)
  -- per-region (305 战略区域) 计数 + 抽样
  local nreg = ru32(S + 164)
  out.regions = { count = nreg }
  local rd = rp(S + 152)
  if O.kptr(rd) and nreg and nreg > 0 and nreg < 65536 then
    -- regional_convoys: SRegionalConvoyData 数组 (元素 stride 未知,
    -- 只出计数)
    out.regions.convoys_slots = nreg
  end
  local acd = rp(S + 176)
  local acc = 0
  if O.kptr(acd) and nreg then
    for i = 0, nreg - 1 do
      local b = ru32(acd + i) % 256
      if b >= 128 then acc = acc + (b - 256) else acc = acc + b end
    end
    out.regions.access_sum = acc
  end
  local mnd = rp(S + 200)
  local mnz = 0
  if O.kptr(mnd) and nreg then
    for i = 0, nreg - 1 do
      if rp(mnd + 8 * i) ~= 0 then mnz = mnz + 1 end
    end
    out.regions.mines_nonzero = mnz
  end
  -- SNA 三族
  do
    local na = {}
    local nd, nc = rp(S + 224), ru32(S + 236)
    if O.kptr(nd) and nc and nc > 0 and nc < 256 then
      for i = 0, nc - 1 do
        local rec = rp(nd + 8 * i)
        if O.kptr(rec) then
          local regp = rp(rec + 8)
          local eqt, eqi = ru32(rec + 16), ru32(rec + 20)
          local sht, shi = ru32(rec + 36), ru32(rec + 40)
          na[#na + 1] = {
            region = O.kptr(regp) and ru32(regp + 88) or -1,
            eq_type = eqt or 0, eq_id = eqi or 0,
            ship_type = sht or 0, ship_id = shi or 0,
            date_h = ru32(rec + 56) or 0,
          }
        end
      end
    end
    if #na > 0 then out.naval_accidents = na end
    -- per_region_access: "idx=val" 对 (>0 才有)
    do
      local pra = {}
      local pd, pc = rp(S + 176), ru32(S + 188)
      if O.kptr(pd) and pc and pc > 0 and pc < 4096 then
        for i = 0, pc - 1 do
          local b = U.a8(pd + i)
          if b and b > 0 then
            pra[#pra + 1] = string.format("%d=%d", i, b)
          end
        end
      end
      out.per_region_access = pra
    end
    -- convoy_escort_presence_history RH 表 (环形缓冲 head..tail 展开)
    do
      local eph = {}
      local hd = rp(S + 360)
      local mask = ru32(S + 372)
      local mp = U.a8(S + 376)
      if O.kptr(hd) and mask and mask < 0x10000 then
        local cap = mask + 1 + (mp or 0)
        if cap > 0 and cap < 0x100000 then
          for i = 0, cap - 1 do
            local e = hd + 40 * i
            local dist = U.a8(e + 4)
            if dist and dist > 0 and dist < 0xFE then
              local reg = ru32(e + 8)
              local buf = rp(e + 16)
              local bcap = ru32(e + 24) or 0
              local bhd = ru32(e + 28) or 0
              local btl = ru32(e + 32) or 0
              local n2 = btl - bhd
              if n2 < 0 then n2 = n2 + bcap end
              if n2 == 0 and btl ~= bhd then n2 = bcap - 1 end
              if O.kptr(buf) and bcap > 0 and bcap < 4096
                  and n2 > 0 and n2 <= bcap then
                local bits = {}
                for k = 0, n2 - 1 do
                  local v = ru32(buf + 4 * ((bhd + k) % bcap)) or 0
                  if v >= 2147483648 then v = v - 4294967296 end
                  bits[#bits + 1] = tostring(v)
                end
                eph[#eph + 1] = string.format(
                  "%d:%s", reg or 0, table.concat(bits, " "))
              end
            end
          end
        end
      end
      out.escort_history = eph
    end
    -- ==== 上提 (段 sv2_sec_c_strategic_navy S 内联链回收;
    -- 写门/格式/序仍段层) ====
    -- regional_convoys (§4.16.6 SRegionalConvoyData): 壳 {pd@S+152, pc@S+164},
    -- 元 48B SRegionalConvoyData {rc u32@+8, eff i64 fx@+16,
    -- sunk_date hours u32@+32}; 非默认门 (0x140E93BC0 取反) 段层
    do
      local pd, pc = rp(S + 152), ru32(S + 164) or 0
      if O.kptr(pd) and pc > 0 and pc < 2048 then
        local lst = {}
        for k = 0, pc - 1 do
          local el = pd + 48 * k
          lst[#lst + 1] = { index = k,
            required_convoys = ru32(el + 8) or 0,
            efficiency_raw = rp(el + 16) or 0,
            date_h = ru32(el + 32) }  -- 保 nil: 段侧读失败=哨兵语义
        end
        out.regional_convoys = { capacity = pc, list = lst }
      end
    end
    -- per_region_mines (0x3942): {d@S+200, c@S+212} 元 8B i64
    do
      local mnd, mnc = rp(S + 200), ru32(S + 212) or 0
      if O.kptr(mnd) and mnc > 0 and mnc <= LAYOUT.lim.PTR_SANE then
        local t = {}
        for k = 0, mnc - 1 do t[#t + 1] = rp(mnd + 8 * k) or 0 end
        out.per_region_mines = t
      end
    end
    -- per_region_danger (0x3CE4): {d@S+128, c@S+140} 稠密 u32
    do
      local dd, dn = rp(S + 128), ru32(S + 140) or 0
      if O.kptr(dd) and dn > 0 and dn <= LAYOUT.lim.PTR_SANE then
        local t = {}
        for k = 0, dn - 1 do t[#t + 1] = ru32(dd + 4 * k) or 0 end
        out.per_region_danger = t
      end
    end
    -- homebase_observers (0x4E04): {d@S+416, c@S+428} 元 8B
    -- {prov u32@0, count u8@+4}
    do
      local hd, hn = rp(S + 416), ru32(S + 428) or 0
      if O.kptr(hd) and hn > 0 and hn <= LAYOUT.lim.FIXED_SMALL then
        local t = {}
        for k = 0, hn - 1 do
          t[#t + 1] = { province = ru32(hd + 8 * k) or 0,
            count = U.a8(hd + 8 * k + 4) or 0 }
        end
        out.homebase_observers = t
      end
    end
    -- naval_transport (§4.16.7 CNavalUnitTransfer; 字段表/写门 = 书)
    do
      local td, tc = rp(S + 304), ru32(S + 316) or 0
      if O.kptr(td) and tc > 0 and tc < LAYOUT.lim.PTR_SANE then
        local lst = {}
        for k = 0, tc - 1 do
          local T = rp(td + 8 * k)
          if O.kptr(T) then
            local rec = {
              id_type = ru32(T + 8) or 0, id_id = ru32(T + 12) or 0,
              has_id = (U.a8(T + 16) or 0) == 1,
              target_provinces = ru32(T + 80) or 0,
              province = ru32(T + 84) or 0,
              country_tid = ru32(T + 88) or 0,
              invasion_group = (U.a8(T + 92) or 0) ~= 0,
              cooldown = ru32(T + 96) or 0,
              convoys = ru32(T + 144) or 0,
              convoys_total = ru32(T + 148) or 0 }
            -- country tag 串 (gs+0x358 串表 32B/项; tid≠0 才解,
            -- 段侧免带 gs 串表直读)
            if rec.country_tid ~= 0 then
              local g = Runtime.gs()
              local tbl = g and rp(g + 0x358)
              if tbl and O.kptr(tbl) then
                rec.country = U.sso(tbl + 32 * rec.country_tid)
              end
            end
            local pd2, pc2 = rp(T + 104), ru32(T + 116) or 0
            if O.kptr(pd2) and pc2 > 0 and pc2 < LAYOUT.lim.PTR_SANE then
              local pp = {}
              for q2 = 0, pc2 - 1 do
                pp[#pp + 1] = ru32(pd2 + 4 * q2) or 0 end
              rec.path = pp
            end
            local ud, uc = rp(T + 56), ru32(T + 68) or 0
            if O.kptr(ud) and uc > 0 and uc < LAYOUT.lim.PTR_SANE then
              local uu = {}
              for q3 = 0, uc - 1 do
                uu[#uu + 1] = { type = ru32(ud + 8 * q3) or 0,
                  id = ru32(ud + 8 * q3 + 4) or 0 }
              end
              rec.units = uu
            end
            local cbd, cbc = rp(T + 24), ru32(T + 36) or 0
            if O.kptr(cbd) and cbc > 0 and cbc <= LAYOUT.lim.FIXED_SMALL then
              local cb = {}
              for q4 = 0, cbc - 1 do
                cb[#cb + 1] = { type = ru32(cbd + 8 * q4) or 0,
                  id = ru32(cbd + 8 * q4 + 4) or 0 }
              end
              rec.combats = cb
            end
            lst[#lst + 1] = rec
          end
        end
        if #lst > 0 then out.naval_transports = lst end
      end
    end
  end
  return out
end

-- 33.13 ai_strategy / CStrategicAI 双 112 槽数组 (§4.34.11; 挂载链
-- cc+552 → +2800 → csa = host+2800; A ai_strategy @csa+144 / B
-- persistent_strategy @csa+2832, 槽 24B {data@0, count@12}, 元素 12B
-- {value i32@0, target@+4, id@+8})。
-- ⚠ 原实现误读 host+104 槽区且无消费者 (与段层/存档实证不符), 已修正为
-- csa 基址并重排返回形 (ai_strategy / persistent_strategy 两组)。
function Country.ai_strategy(self)
  local p = rp(self.addr + 552)
  if not O.kptr(p) then return nil end
  local host = rp(p + 2800)
  if not O.kptr(host) then return nil end
  local csa = host + 2800
  local function slots(dbase, cbase)
    local g = {}
    for i = 0, 111 do
      local d, c = rp(dbase + 24 * i), ru32(cbase + 24 * i)
      if O.kptr(d) and c and c > 0 and c < LAYOUT.lim.PTR_SANE then
        local list = {}
        for j = 0, c - 1 do
          local e = d + 12 * j
          local v = ru32(e) or 0
          if v >= 2147483648 then v = v - 4294967296 end
          local rec = { value = v, id = ru32(e + 8) or 0,
            id_name = LAYOUT.token_name(ru32(e + 8) or 0) }
          local t = ru32(e + 4) or 0
          if t ~= 0 then rec.target = t end
          list[#list + 1] = rec
        end
        g[#g + 1] = { type = i, count = c, list = list }
      end
    end
    return g
  end
  return { csa = csa,
    ai_strategy = slots(csa + 144, csa + 156),
    persistent_strategy = slots(csa + 2832, csa + 2844) }
end

-- 33.14 CStrategicAI 标量簇 (§4.3.19 定案表; 基址链
-- cc+552 → +2800 → +2800): irrationality / num_wanted_divisions
-- (均 i32 有符号, 存档实证负值) / seed (存档序反) / pp_spend 族 /
-- desire/reserved 簇 13 连 = 书 §4.3.19 表
function Country.ai_state(self)
  local p = rp(self.addr + 552)
  if not O.kptr(p) then return nil end
  local host = rp(p + 2800)
  if not O.kptr(host) then return nil end
  local csa = host + 2800
  local out = { addr = csa }
  out.days_to_need_update = ru32(csa + 5696)
  out.days_until_next_rebuild_access_list = ru32(csa + 5700)
  do
    local ir = ru32(csa + 5960)
    if ir then ir = LAYOUT.as_i32(ir) end
    out.irrationality = ir
  end
  do
    local nw = ru32(csa + 6132)
    if nw then nw = LAYOUT.as_i32(nw) end
    out.num_wanted_divisions = nw
  end
  out.seed = { ru32(csa + 5940), ru32(csa + 5936) }
  out.pp_spend_amount = { U.fix5(csa + 6104), U.fix5(csa + 6112) }
  out.pp_spend_priority = ru32(csa + 6096)
  -- military_access: 稀疏 i32 数组 (idx = 国家; count 界检查交段层,
  -- 段历史行为 = 界坏时整段中止)
  out.military_access = { ptr_valid = false, count = 0, values = {} }
  local ma = rp(csa + 5808)
  if O.kptr(ma) then
    local g = self.R.gs()
    local n = (g and ru32(g + 0x31C)) or 0
    out.military_access.ptr_valid = true
    out.military_access.count = n
    for i = 0, n - 1 do
      out.military_access.values[#out.military_access.values + 1] =
        ru32(ma + 4 * i) or 0
    end
  end
  -- desire 簇 13 连 AE590 定点
  local DN = {
    { 5704, "desire_unlock_land_doctrine" },
    { 5712, "desire_unlock_naval_doctrine" },
    { 5720, "desire_unlock_air_doctrine" },
    { 5728, "desire_update_land_template" },
    { 5736, "desire_upgrade_land_equipment" },
    { 5744, "desire_upgrade_naval_equipment" },
    { 5752, "desire_upgrade_air_equipment" },
    { 5760, "reserved_xp_land_research" },
    { 5768, "reserved_xp_naval_research" },
    { 5776, "reserved_xp_air_research" },
    { 5784, "desire_unlock_army_spirit" },
    { 5792, "desire_unlock_navy_spirit" },
    { 5800, "desire_unlock_air_spirit" },
  }
  for _, d in ipairs(DN) do out[d[2]] = U.fix5(csa + d[1]) end
  -- allowed_strategy_plans ({d@csa+5520, c@+5532} 40B MSVC SSO 串)
  -- ⚠ 原实现把本容器误标 persistent_strategy 且按 {raw0, id@+8} 解串, 已修正
  out.allowed_strategy_plans = {}
  local pd, pc = rp(csa + 5520), ru32(csa + 5532)
  if O.kptr(pd) and pc and pc > 0 and pc < LAYOUT.lim.PTR_SANE then
    for k = 0, pc - 1 do
      out.allowed_strategy_plans[#out.allowed_strategy_plans + 1] =
        U.sso(pd + 40 * k)
    end
  end
  -- force_concentration_target ({d@5624, c@5636} 24B 元:
  -- target@+8 / from@+12 / progress fix5@+16)
  out.force_concentration_target = {}
  local fd, fc = rp(csa + 5624), ru32(csa + 5636)
  if O.kptr(fd) and fc and fc > 0 and fc < LAYOUT.lim.PTR_SANE then
    for k = 0, fc - 1 do
      local e = fd + 24 * k
      out.force_concentration_target[#out.force_concentration_target + 1] =
        { target = ru32(e + 8) or 0, from = ru32(e + 12) or 0,
          progress = U.fix5(e + 16) }
    end
  end
  -- expeditionary_force_data ({d@6160, c@6172} 48B 元: tag tid@+8 /
  -- casualties@+12 / do_not_send@+16 / pull_back@+17 / date@+32)
  out.expeditionary_force_data = {}
  local ed, ec = rp(csa + 6160), ru32(csa + 6172)
  if O.kptr(ed) and ec and ec > 0 and ec < LAYOUT.lim.PTR_SANE then
    for k = 0, ec - 1 do
      local e = ed + 48 * k
      out.expeditionary_force_data[#out.expeditionary_force_data + 1] =
        { tag_tid = ru32(e + 8) or 0, casualties = ru32(e + 12) or 0,
          do_not_send = ru8(e + 16) or 0, pull_back = ru8(e + 17) or 0,
          date_h = ru32(e + 32) }
    end
  end
  -- raids ({d@5592, c@5604} 80B 元; target = SRaidTarget @+16, §4.27:
  -- building*@+0 {template def@+0x1E0, state*@+0x1D8} / province*@+8 /
  -- state*@+16 / leader 对@+24/+28 / leader_province*@+32; end_date@+64)
  out.raids = {}
  local rd, rc = rp(csa + 5592), ru32(csa + 5604)
  if O.kptr(rd) and rc and rc > 0 and rc < LAYOUT.lim.PTR_SANE then
    for k = 0, rc - 1 do
      local e = rd + 80 * k
      local rt = e + 16
      local rec = { type_tok = ru32(e + 8) or 0, end_date_h = ru32(e + 64) }
      local bld = rp(rt)
      if O.kptr(bld) then
        local tpo = rp(bld + 0x1E0)
        rec.bld_template_tok = O.kptr(tpo) and ru32(tpo + 8) or nil
        local sto = rp(bld + 0x1D8)
        rec.bld_state = O.kptr(sto) and ru32(sto + 108) or nil
      end
      local pv = rp(rt + 8)
      rec.province = O.kptr(pv) and ru32(pv + 164) or nil
      local st2 = rp(rt + 16)
      rec.state = O.kptr(st2) and ru32(st2 + 88) or nil
      rec.leader_type, rec.leader_id = ru32(rt + 24), ru32(rt + 28)
      local lp = rp(rt + 32)
      rec.leader_province = O.kptr(lp) and ru32(lp + 164) or nil
      out.raids[#out.raids + 1] = rec
    end
  end
  -- failed_naval_invasions ({d@5568, c@5580} 64B 元: province*@+8 /
  -- order_ids {d@+16, c@+28} 4B u32 / invasion_date@+48)
  out.failed_naval_invasions = {}
  local nd, nc = rp(csa + 5568), ru32(csa + 5580)
  if O.kptr(nd) and nc and nc > 0 and nc < LAYOUT.lim.PTR_SANE then
    for k = 0, nc - 1 do
      local e = nd + 64 * k
      local rec = {}
      local pp = rp(e + 8)
      rec.province = O.kptr(pp) and ru32(pp + 164) or nil
      rec.order_ids = {}
      local od, oc = rp(e + 16), ru32(e + 28)
      -- ⚠ has_orders 原样携带: 段历史门 = kptr(od) 且 oc<PTR_SANE
      -- (无 oc>0 检查, 故 oc==0 也出空 invasion_order_ids 叶)
      if O.kptr(od) and oc and oc < LAYOUT.lim.PTR_SANE then
        rec.has_orders = true
        for j = 0, oc - 1 do
          rec.order_ids[#rec.order_ids + 1] = ru32(od + 4 * j) or 0
        end
      end
      rec.date_h = ru32(e + 48)
      out.failed_naval_invasions[#out.failed_naval_invasions + 1] = rec
    end
  end
  -- recently_invaded_areas ({d@5544, c@5556} 64B 元, 形态同上)
  out.recently_invaded_areas = {}
  local vd, vc = rp(csa + 5544), ru32(csa + 5556)
  if O.kptr(vd) and vc and vc > 0 and vc < LAYOUT.lim.PTR_SANE then
    for k = 0, vc - 1 do
      local e = vd + 64 * k
      local rec = {}
      local pp = rp(e + 8)
      rec.province = O.kptr(pp) and ru32(pp + 164) or nil
      rec.order_ids = {}
      local od, oc = rp(e + 16), ru32(e + 28)
      if O.kptr(od) and oc and oc > 0 and oc < LAYOUT.lim.PTR_SANE then
        for j = 0, oc - 1 do
          rec.order_ids[#rec.order_ids + 1] = ru32(od + 4 * j) or 0
        end
      end
      rec.date_h = ru32(e + 48)
      out.recently_invaded_areas[#out.recently_invaded_areas + 1] = rec
    end
  end
  return out
end

-- 33.15 dynamic_modifiers: 内嵌 @cc+3672 (§4.3.8 动态修正容器;
-- 条目 64B / 任务包 cc+3712 = 书)
-- 读侧双形态: 名 = C 串 *(obj+40), 失败回退 MSVC SSO 内联@obj+40 —
-- 脚本实例化 DM 与静态类 obj+40 形态不同, 以指针判定区分
function Country.dynamic_modifiers(self)
  local dm = self.addr + 3672
  local vd, vc = rp(dm + 40), ru32(dm + 52)
  local out = { count = vc or 0, list = {} }
  if O.kptr(vd) and vc and vc > 0 and vc < 64 then
    for i = 0, vc - 1 do
      local e = vd + 64 * i
      local obj = rp(e + 24)
      local nm
      if O.kptr(obj) then
        local p = rp(obj + 40)
        if O.kptr(p) then nm = hoi4.read_cstr(p) end
        if not nm then nm = U.sso(obj + 40) end
      end
      local enabled = U.a8(e + 32) or 0
      local vals = {}
      local vd2, vc2 = rp(e + 40), ru32(e + 52)
      if O.kptr(vd2) and vc2 and vc2 > 0 and vc2 < 64 then
        for v2 = 0, vc2 - 1 do
          local q = rp(vd2 + 8 * v2)
          vals[#vals + 1] = string.format("%.5f", (q or 0) * 1e-5)
        end
      end
      out.list[#out.list + 1] = { name = nm, enabled = enabled,
        values = table.concat(vals, " ") }
    end
  end
  return out
end

-- ------------------------------------------------------------
-- 29.8 technology_status (单轨补迁; §4.7 CTechnologyStatus;
-- slots/lub/cost_reduction 族)
-- ------------------------------------------------------------
function Country.technology_status(self)
  -- 单轨补迁 (legacy 原体; TECHX/TECH/TECHB/TLB/TSL/TCR/RPM 消费)
  local g = self.R.gs()
  if not g then return nil end
  local ts = rp(self.addr + 3936)
  if not O.vt(ts, GAME.layout.vt.CTechnologyStatus) then return nil end
  local out = { addr = ts }
  out.next_bonus_id = ru32(ts + 316)
  local oit = ru32(ts + 312)
  if oit and oit > 0 then
    out.override_icons_tag = self.R:tag(oit)
  end
  -- technologies (过滤后 = 存档条目)
  out.technologies = { total_in_container = ru32(ts + 148) or 0, list = {} }
  local td, tc = rp(ts + 136), ru32(ts + 148)
  if O.kptr(td) and tc and tc > 0 and tc < 4096 then
      for i = 0, tc - 1 do
          local t = rp(td + 8 * i)
          if O.kptr(t) then
              local lv = ru32(t + 372) or 0
              local rpv = U.fix5(t + 408) or 0
              -- 块门 = writer 0x140ED02A0 四条件或 (, 推翻
              -- bonus≠0 门 — 那是叶门非块门)
              -- ① level>0 ② rp raw i64>0 ④ u32@t+476≠0 (lub 引用计数)
              -- ③ level<max_level(tpl@t+352, max@tpl+988) 且挂研究槽
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
                  local rec =
                      { name = LAYOUT.token_name(ru32(t + 8)), level = lv, research_points = rpv,
                        _addr = t }
                  -- date = hours@t+384 (CGameDate 前置 hours 定律);
                  -- 叶门 u32≠0, 纪元哨兵不滤 — 未完成科技照发
                  -- "1.1.1.1" (ctor 恒初始化纪元, 块写则 date 必写)
                  local th = ru32(t + 384)   -- hours 在 CGameDate(392) 前 8
                  -- 唯一实现 = hoi4_layout.date (门 = 滤 {0,0x29C3388} + 年<1 弃;
                  -- 43808760 不滤 → 未完成科技照发 "1.1.1.1")
                  if th and th ~= 0 and th ~= 0x29C3388 then
                      rec.date = LAYOUT.date_opt(th,
                          { drop = { 0, 0x29C3388 }, min_year = 1 })
                  end
                  -- 字段/写门 = 书 §4.7 (design_team id 对@t+492 任一非零
                  -- 才写; bonus 族 ×1e-5 ≠0 才写)
                  -- locked_design_team (0x4AEE) 来源未定案 — t+500 恒 0xF
                  -- 与存档 org 名不符, 留待 vtable 槽定位
                  local dt1, dt2 = ru32(t + 492), ru32(t + 496)
                  if (dt1 and dt1 ~= 0) or (dt2 and dt2 ~= 0) then
                      rec.design_team = string.format("id=%d type=%d",
                          dt2 or 0, dt1 or 0)
                  end
                  local b416 = rp(t + 416)
                  if b416 and b416 ~= 0 then
                      rec.design_team_bonus = b416 / 100000 end
                  local b424 = rp(t + 424)
                  if b424 and b424 ~= 0 then
                      rec.rp_from_design_team = b424 / 100000 end
                  local b448 = rp(t + 448)
                  if b448 and b448 ~= 0 then
                      rec.ahead_reduction = b448 / 100000 end
                  local b456 = rp(t + 456)
                  if b456 and b456 ~= 0 then
                      rec.bonus = b456 / 100000 end
                  -- (TECHB): limited_use_bonus.uses 裸数组 {d@t+464,
                  -- c@t+476} (writer 0x1407FF170 0x33E3); 原始 uses 值
                  do
                      local ud, uc = rp(t + 464), ru32(t + 476)
                      if O.kptr(ud) and uc and uc > 0 and uc < 64 then
                          rec.lub_uses = {}
                          for u2 = 0, uc - 1 do
                              rec.lub_uses[#rec.lub_uses + 1] = ru32(ud + 4 * u2) or 0
                          end
                      end
                  end
                  -- (RPM): research_points_per_mio = std::map @t+432
                  -- (§4.7; MSVC RB-tree 中序 = 存档顺序, isnil 标志
                  -- b@node+25 — 与 MIO unlocked_traits 同款遍历)
                  do
                      local mhead = rp(t + 432)
                      if O.kptr(mhead) then
                          local node = rp(mhead)
                          local mlist = {}
                          local guard = 0
                          while node and (hoi4.read_u8(node + 25) or 1) == 0
                              and guard < 64 do
                              guard = guard + 1
                              mlist[#mlist + 1] = {
                                  org = LAYOUT.token_name(ru32(node + 0x20)),
                                  points = U.fix5(node + 0x28) or 0,
                              }
                              local r = rp(node + 16)
                              if r and (hoi4.read_u8(r + 25) or 1) == 0 then
                                  node = r
                                  while node do
                                      local l = rp(node)
                                      if l and (hoi4.read_u8(l + 25) or 1) == 0 then
                                          node = l
                                      else
                                          break
                                      end
                                  end
                              else
                                  while true do
                                      local p = rp(node + 8)
                                      if not p or (hoi4.read_u8(p + 25) or 1) ~= 0 then
                                          node = nil
                                          break
                                      end
                                      local pr = rp(p + 16)
                                      if pr == node then
                                          node = p
                                      else
                                          node = p
                                          break
                                      end
                                  end
                              end
                          end
                          if #mlist > 0 then rec.mio_points = mlist end
                      end
                  end
                  out.technologies.list[#out.technologies.list + 1] = rec
              end
          end
      end
  end
  -- slots
  out.slots = {}
  local sd, sc = rp(ts + 160), ru32(ts + 172)
  if O.kptr(sd) and sc and sc > 0 and sc < 64 then
      for i = 0, sc - 1 do
          local s = rp(sd + 8 * i)
          if O.kptr(s) then
              -- used_saved_points = i64×1e-5 @+0x28 (writer
              -- 0x140ECFF80: AE590(0x34BB, a1[5]), ≠0 才写; 探针 AFA)
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
  -- limited_use_bonus
  out.limited_use_bonus = { count = ru32(ts + 244) or 0, list = {} }
  local bd, bc = rp(ts + 232), ru32(ts + 244)
  if O.kptr(bd) and bc and bc > 0 and bc < 4096 then  -- 64 字面量被 GER 档 lub 115 击穿
      for i = 0, bc - 1 do
          local e = rp(bd + 8 * i)
          if O.kptr(e) then
              local rec2 = {
                  bonus = U.fix5(e + 112), uses = ru32(e + 8),
                  id = ru32(e + 48), name = hoi4.read_str(e + 16),
                  -- claim u32@+12 (writer 0x1413BAA70 ADFE0 0x2C2E
                  -- 11310=claim, ≠0 才写)
                  claim = ru32(e + 12),
                  -- ahead_reduction ×1e-5 @+104 (0x33E4, ≠0 才写)
                  ahead_reduction = U.fix5(e + 104),
              }
              -- technology 列表 {d@+56, c@+68} 条目 token@*(it)+60
              -- (writer ADEC0(0x285F=10335, token))
              local td6, tc6 = rp(e + 56), ru32(e + 68)
              local techs = {}
              if O.kptr(td6) and tc6 and tc6 > 0 and tc6 <= LAYOUT.lim.PTR_SANE then
                  for i6 = 0, tc6 - 1 do
                      local it6 = rp(td6 + 8 * i6)
                      if O.kptr(it6) then
                          techs[#techs + 1] = tostring(
                              LAYOUT.token_name(ru32(it6 + 60)))
                      end
                  end
              end
              rec2.technologies = table.concat(techs, ",")
              -- category = {d@+80, c@+92} 条目 {名 SSO@+0,
              -- token u32@+44} (writer ADEC0(702, [item+44]))
              local cd3, cc3 = rp(e + 80), ru32(e + 92)
              local cats = {}
              if O.kptr(cd3) and cc3 and cc3 > 0 and cc3 <= LAYOUT.lim.PTR_SANE then
                  for i3 = 0, cc3 - 1 do
                      local it3 = rp(cd3 + 8 * i3)
                      if O.kptr(it3) then
                          cats[#cats + 1] = tostring(
                              LAYOUT.token_name(ru32(it3 + 44)))
                      end
                  end
              end
              rec2.category = table.concat(cats, ",")
              out.limited_use_bonus.list[#out.limited_use_bonus.list + 1] = rec2
          end
      end
  end
  -- cost_reduction
  out.cost_reduction = { count = ru32(ts + 268) or 0, list = {} }
  local cd2, cc2 = rp(ts + 256), ru32(ts + 268)
  if O.kptr(cd2) and cc2 and cc2 > 0 and cc2 < 32 then
      for i = 0, cc2 - 1 do
          local e = rp(cd2 + 8 * i)
          if O.kptr(e) then
              -- cr category = {d@+88, c@+100} 条目 token@+44
              -- (探针 PRC cat_mountaineers_doctrine 36661 命中)
              local cats7 = {}
              local cd7, cc7 = rp(e + 88), ru32(e + 100)
              if O.kptr(cd7) and cc7 and cc7 > 0 and cc7 < 16 then
                  for i7 = 0, cc7 - 1 do
                      local it7 = rp(cd7 + 8 * i7)
                      if O.kptr(it7) then
                          cats7[#cats7 + 1] = tostring(
                              LAYOUT.token_name(ru32(it7 + 44)))
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
-- state_category 便捷读取器 (§4.13; 定义指针@st+2200 → 类别对象,
-- 名 = 全 SSO 直读 — 8B 内联读会截断, 见书 +2200 行)
-- ------------------------------------------------------------
GAME.state_category_name = function(self)
  -- 旧 8 字节内联读截断 ("large_is"≡"large_island") — 实为完整
  -- SSO@+0x18 (size@+0x28), U.sso 直读
  local sc = self.state_category
  if not sc or sc < 0x10000 then return nil end
  return U.sso(sc + 0x18)
end
GAME.state_category_name_8b = function(self)
  local sc = self.state_category
  if not sc or sc < 0x10000 then return nil end
  local a = hoi4.read_u32(sc + 0x18)
  local b = hoi4.read_u32(sc + 0x1C)
  if not a then return nil end
  local chars = {}
  local function push(v)
    if not v then return false end
    for i = 0, 3 do
      local c = (v >> (8 * i)) & 0xFF
      if c == 0 then return false end
      chars[#chars + 1] = string.char(c)
    end
    return true
  end
  if not push(a) then return table.concat(chars) end
  push(b)
  return table.concat(chars)
end


-- ============================================================
-- §4.1/§4.12/§4.28 全局元数据族导出全量 reader
-- (sv2_sec_global_tails flags/saved_event_target/ships_built/
-- player_countries/gameplaysettings/indexes/fired_event_names/
-- pending_events/difficulty_settings/to_be_deleted 块消费)
local function gm_date3(h)
  if h == 43808760 then return "1.1.1.1" end
  return GAME.layout.date(h)
end
local function gm_idpair_at(el, off)
  local ty, id = ru32(el + off), ru32(el + off + 4)
  if (ty and ty ~= 0) or (id and id ~= 0) then
    return { type = ty or 0, id = id or 0 }
  end
  return nil
end
local function gm_ev_name(np)   -- key 名串/token 双形态
  if not O.kptr(np) then return nil end
  local sz = rp(np + 48)
  if sz and sz ~= 0 then
    if sz <= 4096 then return U.sso(np + 32) end
    if O.kptr(sz) then return hoi4.read_cstr(sz) end
  end
  return (function()
    local t = ru32(np + 12) or 0
    return t and (GAME.layout.token_name(t) or t) or nil
  end)()
end

-- §4.1.5 global flags (*(gs+600) CFlagStore; 与 country.flags 同构)
function Runtime.global_flags(self)
  local g = self.gs()
  local store = rp(g + 600)
  if not O.kptr(store) then return nil end
  local d, cnt = rp(store + 8), ru32(store + 0x14)
  if not (O.kptr(d) and cnt and cnt > 0
      and cnt < LAYOUT.lim.PTR_HUGE) then return nil end
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
      out[#out + 1] = { name = nm, value = v,
        date_h = (dh and dh > 0) and dh or nil,
        days = (ex > 0) and ex or nil }
    end
  end
  return out
end

-- §4.12.6 saved_event_target (挂 §1.2 +1728, count@+1740; 112B 条)
function Runtime.global_saved_event_targets(self)
  local g = self.gs()
  local c = ru32(g + 1740)
  if not (c and c > 0 and c < 4096) then return nil end
  local d = rp(g + 1728)
  if not O.kptr(d) then return nil end
  local out = {}
  for i = 0, c - 1 do
    local el = d + 112 * i
    local rec = {}
    local sv = ru32(el + 8)
    if sv and sv ~= 0 then rec.state = sv end
    local ci = ru32(el + 12)
    if ci and ci > 0 then rec.country = Runtime:tag(ci) end
    rec.character = gm_idpair_at(el, 16)
    local sro = rp(el + 32)
    if O.kptr(sro) then rec.strategic_region = ru32(sro + 88) or 0 end
    rec.ace = gm_idpair_at(el, 48)
    rec.operation = gm_idpair_at(el, 24)
    rec.unit = gm_idpair_at(el, 56)
    rec.industrial_organisation = gm_idpair_at(el, 64)
    rec.purchase_contract = gm_idpair_at(el, 72)
    rec.raid_instance = gm_idpair_at(el, 80)
    rec.project = gm_idpair_at(el, 88)
    rec.faction = gm_idpair_at(el, 96)
    -- name: u16 索引@+104 → set_name (§4.26.3 SET 名串表)
    local nidx = hoi4.read_u16(el + 104) or 0
    if nidx ~= 0 then rec.name = GAME.layout.set_name(nidx) end
    out[#out + 1] = rec
  end
  return out
end

-- §4.1.16 ships_built (挂 §1.2 +2520 std::map; 0 值也写)
function Runtime.global_ships_built(self)
  local g = self.gs()
  if (rp(g + 2528) or 0) == 0 then return nil end
  local head = rp(g + 2520)
  local out = {}
  for _, node in ipairs(GAME.layout.rb_inorder(head)) do
    local t = ru32(node + 28) or 0
    local nm = t and (GAME.layout.token_name(t) or t)
    if nm then
      out[#out + 1] = { name = nm, count = ru32(node + 32) or 0 } end
  end
  return out
end

-- §4.28.1 player_countries (挂 §1.2 +168; 根级 cosmetic_tag 同源 cc+5256)
function Runtime.global_player_countries(self)
  local g = self.gs()
  local d, c = rp(g + 168), ru32(g + 180)
  if not (O.kptr(d) and c and c > 0 and c < LAYOUT.lim.PTR_SANE) then
    return nil end
  local carr2 = rp(g + 0x310)
  local out = {}
  for i = 0, c - 1 do
    local el = d + 160 * i
    local t = Runtime:tag(ru32(el + 112) or 0)
    if t then
      local rec = { tag = t }
      local cc2 = carr2 and rp(carr2 + 8 * (ru32(el + 112) or -1))
      local cos = cc2 and U.sso(cc2 + 5256) or nil
      if cos and cos ~= "" then rec.cosmetic_tag = cos end
      rec.user = U.sso(el + 32)
      rec.country_leader = (ru8(el + 148) or 0) & 1
      local id = ru32(el + 152)
      if id and id ~= 0xFFFFFFFF then rec.id = id end
      out[#out + 1] = rec
    end
  end
  return out
end

-- §4.28.2 gameplaysettings (挂 §1.2 +1576)
function Runtime.global_gameplaysettings(self)
  local g = self.gs()
  local DIFF = { [0] = "very_easy", "easy", "normal", "hard", "very_hard" }
  local dv = ru32(g + 1584) or 2
  return { difficulty = DIFF[dv] or ("diff_" .. dv),
    ironman = ru32(g + 1588) or 0, historical = ru32(g + 1592) or 0 }
end

-- §4.28.4 索引计数器 (5 槽)
function Runtime.global_indexes(self)
  local g = self.gs()
  local T = {
    { 1872, "railway_gun_index" }, { 1888, "industry_organisation_index" },
    { 1904, "special_project_index" }, { 1920, "program" },
    { 1936, "program_supply_consumer" } }
  local out = {}
  for _, e in ipairs(T) do
    out[#out + 1] = { name = e[2], id = ru32(g + e[1] + 8) or 0 }
  end
  return out
end

-- §4.12.7 fired_event_names (挂 §1.2 +1340; 名串/token 双形态)
function Runtime.global_fired_event_names(self)
  local g = self.gs()
  local nb = ru32(g + 1340)
  local buckets = rp(g + 1344)
  if not (nb and nb > 0 and nb < 1048576 and O.kptr(buckets)) then
    return nil end
  local parts = {}
  for b = 0, nb - 1 do
    local node = rp(buckets + 8 * b)
    local guard = 0
    while O.kptr(node) and guard < 100000 do
      guard = guard + 1
      local key = rp(node)
      if O.kptr(key) then
        local nm
        local sz = rp(key + 48)
        if sz and sz ~= 0 then
          if sz <= 4096 then nm = U.sso(key + 32)
          elseif O.kptr(sz) then nm = hoi4.read_cstr(sz) end
        end
        if not nm then
          local t = ru32(key + 12) or 0
          nm = t and (GAME.layout.token_name(t) or t) or nil
        end
        if nm then parts[#parts + 1] = tostring(nm) end
      end
      node = rp(node + 8)
    end
  end
  return (#parts > 0) and parts or nil
end

-- §4.1.5 difficulty_settings (挂 §1.2 +1064; difficulty 重复编号 [2]..)
function Runtime.global_difficulty_settings(self)
  local g = self.gs()
  local dd, dc = rp(g + 1064), ru32(g + 1076)
  if not (O.kptr(dd) and dc and dc > 0
      and dc < LAYOUT.lim.PTR_SANE) then return nil end
  local out = {}
  for i = 0, dc - 1 do
    local e = rp(dd + 8 * i)
    if O.kptr(e) then
      local mul = rp(e + 208)
      if mul and mul > 0 then
        local rec = { multiplier = mul * 1e-5 }
        local def = rp(e + 8)
        local nm = O.kptr(def) and U.sso(def + 56)
        if nm then rec.name = nm end
        out[#out + 1] = rec
      end
    end
  end
  return out
end

-- §4.1.5 to_be_deleted (挂 §1.2 +1224)
function Runtime.global_to_be_deleted(self)
  local g = self.gs()
  local dd, dc = rp(g + 1224), ru32(g + 1236)
  if not (O.kptr(dd) and dc and dc > 0
      and dc < LAYOUT.lim.PTR_SANE) then return nil end
  local out = {}
  for i = 0, dc - 1 do
    local p = dd + 8 * i
    out[#out + 1] = { id = ru32(p + 4) or 0, type = ru32(p) or 0 }
  end
  return out
end

-- §4.1.1 pending_events (vec {gs+1376, gs+1388} 56B 内联; scope 树每层
-- 都写 saved_event_target — 与 delayed_event 路径不同; 嵌套树 = reader)
local function gm_scope(sc, depth)
  if not O.kptr(sc) or depth > 8 then return nil end
  local rec = {}
  local tid = ru32(sc + 8)
  if tid and tid > 0 then rec.country = Runtime:tag(tid) end
  local stv = ru32(sc + 168)
  if stv and stv ~= 0 then rec.state = stv end
  local IDP = { { 80, "character" }, { 104, "ace" }, { 88, "operation" },
    { 112, "unit" }, { 120, "industrial_organisation" },
    { 128, "purchase_contract" }, { 136, "raid_instance" },
    { 144, "project" }, { 152, "faction" } }
  for _, iv in ipairs(IDP) do
    rec[iv[2]] = gm_idpair_at(sc, iv[1])
  end
  local sr = rp(sc + 72)
  if O.kptr(sr) then rec.strategic_region = ru32(sr + 88) or 0 end
  rec.random = { ru32(sc + 16) or 0, ru32(sc + 12) or 0 }
  -- saved_event_target: 每层 scope 都写 (pending_events .from.from 六叶实证)
  do
    local cp = rp(sc + 160)
    if O.kptr(cp) then
      local td, tc = rp(cp), ru32(cp + 12)
      if O.kptr(td) and tc and tc > 0 and tc < LAYOUT.lim.PTR_SANE then
        rec.saved_event_targets = {}
        for ti = 0, tc - 1 do
          local te = td + 112 * ti
          local t2 = {}
          local st = ru32(te + 8)
          if st and st ~= 0 then t2.state = st end
          local ct = ru32(te + 12)
          if ct and ct > 0 and ct < 0x80000000 then
            t2.country = Runtime:tag(ct) end
          t2.character = gm_idpair_at(te, 16)
          local ni = ru32(te + 104)
          if ni then ni = ni % 65536 end
          if ni and ni ~= 0 then t2.name = GAME.layout.set_name(ni) end
          rec.saved_event_targets[#rec.saved_event_targets + 1] = t2
        end
      end
    end
  end
  if depth < 8 then
    local REC = { { 24, "root" }, { 32, "from" }, { 40, "prev" } }
    for _, rv in ipairs(REC) do
      local nx = rp(sc + rv[1])
      if nx and nx ~= sc then
        rec[rv[2]] = gm_scope(nx, depth + 1)
      end
    end
  end
  return rec
end

-- §4.1.1 pending_events 列表
function Runtime.global_pending_events(self)
  local g = self.gs()
  local pd, pc = rp(g + 1376), ru32(g + 1388)
  if not (O.kptr(pd) and pc and pc > 0
      and pc < LAYOUT.lim.PTR_SANE) then return nil end
  local out = {}
  for i = 0, pc - 1 do
    local e = pd + 56 * i
    local rec = { id = gm_ev_name(rp(e + 8)),
      scope = gm_scope(rp(e + 16), 0),
      timeout_h = ru32(e + 40),        -- date3 无门
      pending_id = ru32(e) or 0 }
    out[#out + 1] = rec
  end
  return out
end
