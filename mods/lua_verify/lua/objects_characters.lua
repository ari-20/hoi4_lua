-- objects_characters.lua -- 角色 / 情报三节 / 角色深层族 (对象层域文件)
-- 结构语义详见书: 角色 §4.4 / 情报 §4.11 / 特工与情报机构 §4.11 /
-- 国策进度 §4.3.14 CFocusStatus。
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

-- §9 角色族 (§4.4.9 CCharacterManager gs+0x6A8; §4.4.11 CCharacter vt 0x297ea60)
-- ============================================================
local VT_CHAR = GAME.layout.vt.CCharacter
local Char2MT = {}
Char2MT.__index = function(self, k)
  local a = self.addr
  if not O.vt(a, VT_CHAR) then return nil end   -- 悬垂/复用 → nil
  -- §4.4.11 CCharacter: id 对 +8/+12 / name@+72 / operative 对 +200/+204 /
  -- flags 计数@+292 / leader@+168
  if k == "char_id" then return ru32(a + 0xC) end
  if k == "type_id" then return ru32(a + 8) end
  if k == "name" then return U.sso(a + 0x48) end
  if k == "operative_a" then return ru32(a + 0xC8) end
  if k == "operative_b" then return ru32(a + 0xCC) end
  if k == "flags_count" then return ru32(a + 0x124) end
  if k == "has_leader" then return O.kptr(rp(a + 0xA8)) end
  if k == "leader" then
    -- §4.4.11 CCharacter+168 → §4.4.2 CUnitLeader: skill 对象@+3680
    -- (等级 u32@+440) / xp@+3688 / leader_type@+3708 / traits {+3528,+3540}
    local l = rp(a + 0xA8)
    if not O.kptr(l) then return nil end
    local s = rp(l + 0xE60)
    local ld = { addr = l,
      level = O.kptr(s) and ru32(s + 0x1B8) or nil,
      xp = rp(l + 0xE68),
      leader_type = ru32(l + 0xE7C),       -- 0/1 陆军系, 2 海军
      traits = {}, skill_ptr = s }
    for _, e in O.vec(l, 0xDC8, 0xDD4, 8, true) do
      ld.traits[#ld.traits + 1] = e and ru32(e + 8) or nil
    end
    return ld
  end
  return nil
end
local function mk_char2(a, R)
  return setmetatable({ addr = a, R = R }, Char2MT)
end

-- 代际签名 (容器数据/计数变化 → 重建 id 缓存)
-- §4.4.9 CCharacterManager: 两容器 {d@+16, c@+28} historical / {d@+40, c@+52} dynamic
local char_cache = { gen = nil, by_id = nil }
local function char_gen(g)
  local mgr = g and rp(g + 0x6A8)
  if not O.kptr(mgr) then return nil end
  local h, d = ru32(mgr + 0x1C), ru32(mgr + 0x34)
  return table.concat({ rp(mgr + 0x10) or 0, h or 0, d or 0 }, ":")
end
local function chars_collect(g, filter)
  local mgr = g and rp(g + 0x6A8)
  if not O.kptr(mgr) then return {} end
  local out = {}
  local containers = { { rp(mgr + 0x10), ru32(mgr + 0x1C) },
                        { rp(mgr + 0x28), ru32(mgr + 0x34) } }
  for _, c in ipairs(containers) do
    local data, n = c[1], c[2]
    if O.kptr(data) and n and n > 0 and n < 200000 then
      for i = 0, n - 1 do
        local p = rp(data + 8 * i)
        if p and rp(p) == BASE + VT_CHAR then
          if not filter or filter(p, ru32(p + 0xC)) then
            out[#out + 1] = mk_char2(p, g)
          end
        end
      end
    end
  end
  return out
end

function Runtime.characters(self)
  return chars_collect(self.gs(), nil)
end
-- §4.4.9 CCharacterManager 容器查角色 (两容器 historical/dynamic; 元素 = §4.4.11 CCharacter)
function Runtime.character(self, id)
  local g = self.gs()
  local gen = char_gen(g)
  if char_cache.gen ~= gen then
    local map = {}
    local mgr = g and rp(g + 0x6A8)
    if O.kptr(mgr) then
      local containers = { { rp(mgr + 0x10), ru32(mgr + 0x1C) },
                            { rp(mgr + 0x28), ru32(mgr + 0x34) } }
      for _, c in ipairs(containers) do
        local data, n = c[1], c[2]
        if O.kptr(data) and n and n > 0 and n < 200000 then
          for i = 0, n - 1 do
            local p = rp(data + 8 * i)
            if p and rp(p) == BASE + VT_CHAR then
              local cid = ru32(p + 0xC)
              if cid then map[cid] = p end
            end
          end
        end
      end
    end
    char_cache.gen, char_cache.by_id = gen, map
  end
  local a = char_cache.by_id[id]
  return a and mk_char2(a, self) or nil
end
function Runtime.leaders(self, filter_fn)
  -- §4.4.11 CCharacter+168 → §4.4.2 CUnitLeader+3708 leader_type
  return chars_collect(self.gs(), function(p, id)
    local l = rp(p + 0xA8)
    return O.kptr(l) and (not filter_fn or filter_fn(rp(l + 0xE7C)))
  end)
end



-- ============================================================
-- §10 情报机构 (§4.11.14 CIntelligenceAgency @cc+4032; vt 键名 CCountryIntelAgency)
-- ============================================================
-- recruitable/training 元素 = §4.11.11 COperativeLeader (基区 = §4.4.2
-- CUnitLeader, nationalities 容器 = §4.11.11 特有区 +3944/+3956)
local MISSION_NAMES = { [1] = "build_intel_network", [2] = "quiet_network",
  [3] = "counter_intelligence", [4] = "root_out_resistance",
  [5] = "boost_ideology", [6] = "control_trade", [7] = "diplomatic_pressure",
  [8] = "propaganda" }

local function operative_leader(e, R)
  local traits = {}
  for _, te in O.vec(e, 3528, 3540, 8, true) do
    -- legacy 同门: te 指针无效 → 跳过 (不补 "?")
    if O.kptr(te) then
      traits[#traits + 1] = tok(ru32(te + 8) or 0) or "?"
    end
  end
  local nat = {}
  for _, na in O.vec(e, 3944, 3956, 4, false) do
    -- stride 4 u32 数组: O.vec(deref=false) 迭代出元素地址, 须 ru32 解引
    -- (原把地址当 tid → nationalities 输出指针值)
    local ntid = ru32(na)
    nat[#nat + 1] = (ntid and ntid > 0 and R:tag(ntid))
        or tostring(ntid or 0)
  end
  local prog, prog_pairs = {}, {}
  for _, pe in O.vec(e, 3576, 3588, 16, false) do
    local tobj = rp(pe)
    local vq = rp(pe + 8)
    if O.kptr(tobj) then
      local tn = tok(ru32(tobj + 8) or 0)
      local val = GAME.layout.as_i64(vq or 0) / 100000
      -- 串版 (旧口径 "?" 兜底) 与结构化对版分离:
      -- 发射段 writer 门 = token 名非 nil 才发 → prog_pairs 只收有效名
      prog[#prog + 1] = string.format("%s=%.5f", tn or "?", val)
      if tn then
        prog_pairs[#prog_pairs + 1] = { tok = tn, val = val }
      end
    end
  end
  local skillp = rp(e + 3680)
  -- §4.11.11 mission {mdata*@+4248, type u32@+4256}: target tid =
  -- ru32(mdata+16), state = ru32(rp(mdata+24)+88) (通用口径, 无型别
  -- 白名单 — 白名单门 = 发射规则留段侧)
  local mtype = ru32(e + 4256) or 0
  local m_target_tid, m_state = 0, 0
  if mtype ~= 0 then
    local mdata = rp(e + 4248)
    if O.kptr(mdata) then
      local mtid = ru32(mdata + 16) or 0
      if mtid > 0 then m_target_tid = mtid end
      local ms2 = rp(mdata + 24)
      if O.kptr(ms2) then m_state = ru32(ms2 + 88) or 0 end
    end
  end
  return {
    type = ru32(e + 8) or 0, id = ru32(e + 12) or 0,
    -- legacy 同型: read_msvc_str size=0 → nil → 导出端 "gfx" 行不发 /
    -- g[N] 显 "?" (U.sso 返回空串致 TRO 多发空 gfx 行 / ROP g[N] 空)
    name = LAYOUT.read_msvc_str(e + 32),
    gfx = LAYOUT.read_msvc_str(e + 256),
    female = ru32(e + 3712) & 0xFF,
    traits = table.concat(traits, " "),
    skill = O.kptr(skillp) and ru32(skillp + 440) or 0,
    script_id = ru32(e + 3924) or 0,
    -- §4.4.2 legacy_id u32@+3800: 门 = ≠-1 (writer 0x14142D240 族: v24 != -1 才写);
    -- **有符号域** — PB:LOM 实证 save=-2/-3412 (mem 旧印 4294967294/…);
    -- 本行在 to_i32 定义之前, 故内联 (文件级 local 先宣后用)
    legacy_id = ((ru32(e + 3800) or 0) % 0x100000000 + 0x80000000)
        % 0x100000000 - 0x80000000,
    legacy_u32 = ru32(e + 3800) or 0xFFFFFFFF,
    state = ru32(e + 4224) or 0,
    nationalities = table.concat(nat, " "),
    codename_type = ru32(e + 4056) or 0,
    in_progress = table.concat(prog, ";"),
    in_progress_pairs = prog_pairs,
    -- ===== 扩展字段 (§4.11.11 writer 0x140C18FF0/0x140C1CE70 全门收编;
    -- 现役/退役/招募三消费者共用, 发射键集差异留段侧) =====
    desc = LAYOUT.read_msvc_str(e + 128),
    custom_cost_text = LAYOUT.read_msvc_str(e + 160),
    picture = LAYOUT.read_msvc_str(e + 224),
    portrait_path = LAYOUT.read_msvc_str(e + 192),
    -- female 门 = 字段@+3713 ≠0 才写 (ru8)
    female_gate = (ru8(e + 3713) or 0) ~= 0,
    experience = GAME.layout.as_i64(rp(e + 3688) or 0) / 100000,
    captured_tag = ru32(e + 4016) or 0,
    capture_date_hours = ru32(e + 4032) or 0,
    operation_type = ru32(e + 3968) or 0,
    operation_id = ru32(e + 3972) or 0,
    -- cooldown 三件套 (§4.4.2 基类同构): 总门 reason 码 ≠0;
    -- 枚举反表/日期串在段侧 (0=no_cooldown 族)
    cooldown_reason_code = ru32(e + 3716) or 0,
    cooldown_enable_hours = ru32(e + 3752) or 0,
    cooldown_start_hours = ru32(e + 3728) or 0,
    codename_name_order = ru32(e + 4176) or 0,
    codename_is_name_ordered_zero = (ru8(e + 4216) or 0) == 0,
    mission_type_code = mtype,
    mission_target_tid = m_target_tid,
    mission_state_raw = m_state,
  }
end
-- 公开 (objects_global Country.country_characters 的 retired_operatives
-- 池跨域复用同一转换; 发射键集差异留段侧)
Runtime.op_leader = operative_leader

function Country.intelligence_agency(self)
  local ag = rp(self.addr + 4032)
  if not O.kptr(ag) or rp(ag) ~= BASE + GAME.layout.vt.CCountryIntelAgency then return nil end
  local out = { addr = ag,
    name = U.sso(ag + 128), icon = U.sso(ag + 160),
    is_created = (ru32(ag + 192) % 256) == 1,
    -- legacy 同型: read_u8(ag+193) ~= 0 (原 %256==1 对 b>1 误判 false)
    in_creation = (ru8(ag + 193) or 0) ~= 0,
    max_operative_count = ru32(ag + 240),
    usable_operative_slots = ru32(ag + 244),
    elapsed_days_for_next_slot = ru32(ag + 248),
    building = ru32(ag + 256),
    defense = U.fix5(ag + 296) }        -- writer 0x140FCA0F0 (0x2A54)
  -- §4.11.14 recruitment 三容器: generated {d@24,c@36} / recruitable
  -- {d@48,c@60} / recruitable_not_to_spy_master {d@72,c@84} (8B 指针元,
  -- 容器序 = writer 序; n 编号仅计有效元素)
  local function rec_pool(doff, coff)
    local pool = { count = ru32(ag + coff) or 0, list = {} }
    for _, e in O.vec(ag, doff, coff, 8, true) do
      if O.kptr(e) then
        pool.list[#pool.list + 1] = operative_leader(e, self.R)
      end
    end
    return pool
  end
  out.generated_operatives = rec_pool(24, 36)
  out.recruitable = rec_pool(48, 60)
  out.recruitable_not_to_spy_master = rec_pool(72, 84)
  local lv = rp(ag + 200)
  out.upgrade_progress = lv and lv / 100000 or nil
  -- §4.11.14 upgrades {d@96, c@108} 16B {def*, level u32@+8};
  -- def* 有效且 token 名非空才收 (writer 门)
  out.upgrades = { count = ru32(ag + 108) or 0, list = {} }
  do
    local ud, uc = rp(ag + 96), ru32(ag + 108) or 0
    if O.kptr(ud) and uc > 0 and uc < LAYOUT.lim.PTR_SANE then
      for q4 = 0, uc - 1 do
        local e2 = ud + 16 * q4
        local p2 = rp(e2)
        if O.kptr(p2) then
          local un = tok(ru32(p2 + 8) or 0)
          if un then
            out.upgrades.list[#out.upgrades.list + 1] =
                { name = tostring(un), level = ru32(e2 + 8) or 0 }
          end
        end
      end
    end
  end
  -- upgrade 裸键 (writer 0x140FCA0F0 L69: def*@ag+208 指针门,
  -- token@def+8 裸名)
  do
    local udef = rp(ag + 208)
    if O.kptr(udef) then
      local un = LAYOUT.token_name(ru32(udef + 8) or 0)
      if un and un ~= "" then out.upgrade = un end
    end
  end
  -- own_operative_death (writer L45: u32@ag+252 ≠0 才写, 段门)
  out.own_operative_death = ru32(ag + 252) or 0
  -- §4.11.14 operative 池 {d@216, c@228} + §4.11.11 尾段字段
  out.training_operatives = { count = ru32(ag + 228) or 0, list = {} }
  for _, e in O.vec(ag, 216, 228, 8, true) do
    if O.kptr(e) then
      local r = operative_leader(e, self.R)
      r.xp = (rp(e + 3688) or 0) / 100000
      local capc = ru32(e + 4016)
      if capc and capc > 0 then
        r.captured_by = capc
        r.capture_date_h = ru32(e + 4032) or 0
      end
      local cno2 = ru32(e + 4176) or 0
      if cno2 ~= 0 then r.codename_no = cno2 end
      if (ru32(e + 4216) & 0xFF) == 0 then r.codename_ino = "no" end
      local mtype = ru32(e + 4256) or 0
      if mtype and mtype ~= 0 then
        r.mission_type = MISSION_NAMES[mtype] or tostring(mtype)
        local mdata = rp(e + 4248)
        if O.kptr(mdata) then
          local mtid = ru32(mdata + 16)
          if mtid and mtid > 0 then r.mission_target = mtid end
          local ms2 = rp(mdata + 24)
          if O.kptr(ms2) then r.mission_state = ru32(ms2 + 88) or 0 end
        end
      end
      out.training_operatives.list[#out.training_operatives.list + 1] = r
    end
  end
  -- §4.11.14 captured {d@264, c@276} stride 56: 元 = CCapturedOperativeReference
  -- {country idx u32@+8, op type@+12, op id@+16, intel 四象限 i64×1e-5
  --  @+24/+32/+40/+48}; 门 = count<PTR_SANE (旧 64 上限会被大 mod 击穿)
  out.captured = { count = ru32(ag + 276) or 0, list = {} }
  do
    local cd, cc2 = rp(ag + 264), ru32(ag + 276) or 0
    if O.kptr(cd) and cc2 > 0 and cc2 < LAYOUT.lim.PTR_SANE then
      for q2 = 0, cc2 - 1 do
        local e3 = cd + 56 * q2
        out.captured.list[#out.captured.list + 1] = {
          addr = e3,
          country_idx = ru32(e3 + 8) or 0,
          op_type = ru32(e3 + 12) or 0,
          op_id = ru32(e3 + 16) or 0,
          intel_civilian = U.fix5(e3 + 24),
          intel_army = U.fix5(e3 + 32),
          intel_navy = U.fix5(e3 + 40),
          intel_airforce = U.fix5(e3 + 48) }
      end
    end
  end
  -- §4.11.9 cryptology (crypto = *(ag+288)): targets {d@+40, c@+52}
  -- 56B 元 {tag tid u32@+8, days u32@+12 (门 ≠-1), active/hide/decryption
  -- b@+16/+17/+18, amount ×1e-5@+24 (门 ≠0), date u32@+40 (门 ≠43808760
  -- ctor 哨兵)}
  do
    local crypto = rp(ag + 288)
    out.cryptology = { targets = {} }
    if O.kptr(crypto) then
      local td2, tc2 = rp(crypto + 40), ru32(crypto + 52) or 0
      if O.kptr(td2) and tc2 > 0 and tc2 < LAYOUT.lim.PTR_SANE then
        for q6 = 0, tc2 - 1 do
          local e4 = td2 + 56 * q6
          out.cryptology.targets[#out.cryptology.targets + 1] = {
            tag_tid = ru32(e4 + 8) or 0,
            days_raw = ru32(e4 + 12) or 0xFFFFFFFF,
            active = (ru8(e4 + 16) or 0) ~= 0,
            hide = (ru8(e4 + 17) or 0) ~= 0,
            decryption = (ru8(e4 + 18) or 0) ~= 0,
            amount = GAME.layout.as_i64(rp(e4 + 24) or 0) / 100000,
            date_hours = ru32(e4 + 40) or 0 }
        end
      end
    end
  end
  return out
end


-- ============================================================
-- §11 情报四象限矩阵 (§4.11.7 CCountryIntel @cc+4072; vt 0x295f188; writer 0x140CF2AE0)
-- ============================================================
local INTEL2_MATS = {
  { 16, "intel" }, { 40, "from_allies" }, { 64, "from_static_pools" },
  { 88, "from_dynamic_pools" }, { 112, "from_dynamic_pools_prev_day" },
  { 136, "from_encryption_decryption" } }
local INTEL2_QUAD = { "civilian", "army", "navy", "airforce" }

function Country.intel(self)
  local it = rp(self.addr + 4072)
  if not O.kptr(it) or rp(it) ~= BASE + GAME.layout.vt.CCountryIntel then return nil end
  local out = { addr = it }
  local function quad_str(qd)
    local s = {}
    for qi = 1, 4 do
      s[#s + 1] = string.format("%.5f", U.fix5(qd + 8 * (qi - 1)) or 0)
    end
    return table.concat(s, "|")
  end
  local function pool_entries(d, c, cap)   -- {idx@+0, quad i64×4@+8} stride40
    local t = {}
    if O.kptr(d) and c and c > 0 and c <= cap then
      for j = 0, c - 1 do
        local e = d + 40 * j
        t[#t + 1] = { idx = ru32(e), quad = quad_str(e + 8) }
      end
    end
    return t
  end
  local function rows24(d, c, cap)         -- §4.11.7 CEC260 行容器 (行内嵌 {d,c}@+0/+12)
    local t = {}
    if O.kptr(d) and c and c > 0 and c <= cap then
      for j = 0, c - 1 do
        local row = d + 24 * j
        local id, ic = rp(row), ru32(row + 12)
        local items = {}
        if O.kptr(id) and ic and ic > 0 and ic <= 4096 then  -- 64 字面量被 ENG intel 行 77 条击穿
          for k = 0, ic - 1 do
            local e = id + 40 * k
            items[#items + 1] = string.format("%d=%s",
                ru32(e) or 0, quad_str(e + 8))
          end
        end
        t[#t + 1] = table.concat(items, ";")
      end
    end
    return t
  end
  for _, m in ipairs(INTEL2_MATS) do
    local d, c = rp(it + m[1]), ru32(it + m[1] + 8)
    local mat = { count = c or 0, rows = {} }
    if O.kptr(d) and c and c > 0 and c < 65536 then
      for j = 0, c - 1 do
        local e = d + 32 * j
        local row = { idx = j }
        for q = 1, 4 do row[INTEL2_QUAD[q]] = U.fix5(e + 8 * (q - 1)) end
        mat.rows[#mat.rows + 1] = row
      end
    end
    out[m[2]] = mat
  end
  out.static_intel_pools = { count = ru32(it + 172) or 0 }
  out.dynamic_intel_pools = { count = ru32(it + 196) or 0 }
  out.discriminant = ru32(it + 208)
  -- static 池 (两层, §4.11.8): 外层 {d@160, c@172} 72B CStaticIntelSourcePool,
  -- 内层 CIntelSource {d@+8, c@+20, id@+32, remove u8@+36} stride40
  out.static_pool_rows = {}
  for _, p in O.vec(it, 160, 172, 72, false) do
    local rec = { id = ru32(p + 64) or 0, sources = {} }
    for _, src in O.vec(p, 40, 52, 40, false) do
      rec.sources[#rec.sources + 1] = {
        id = ru32(src + 32) or 0,
        remove = ru32(src + 36) & 0xFF,
        entries = pool_entries(rp(src + 8), ru32(src + 20), 1024) }
    end
    out.static_pool_rows[#out.static_pool_rows + 1] = rec
  end
  -- §4.11.8 dynamic 池: {d@184, c@196} 56B CDynamicIntelSourcePool (accumulator@+8, values@+32)
  out.dynamic_pool_rows = {}
  for _, p in O.vec(it, 184, 196, 56, false) do
    local rec = {}
    rec.accum = pool_entries(rp(p + 8), ru32(p + 20), 64)
    rec.values = pool_entries(rp(p + 32), ru32(p + 44), 64)
    out.dynamic_pool_rows[#out.dynamic_pool_rows + 1] = rec
  end
  -- from_allies 裸 quad 行
  out.from_allies_rows = {}
  for _, e in O.vec(it, 40, 52, 32, false) do
    out.from_allies_rows[#out.from_allies_rows + 1] = quad_str(e)
  end
  -- from_encryption_decryption 裸 quad 行 (补: writer 19492
  -- CEC1C0 同 from_allies 族; ctor 定名 intel_from_encryption_decryption)
  out.from_encryption_decryption_rows = {}
  for _, e in O.vec(it, 136, 148, 32, false) do
    out.from_encryption_decryption_rows[#out.from_encryption_decryption_rows + 1] = quad_str(e)
  end
  -- from_static/dynamic/prev_day 行容器 (count 在块基+12)
  out.from_static_rows = rows24(rp(it + 64), ru32(it + 76), 1024)
  out.from_dynamic_rows = rows24(rp(it + 88), ru32(it + 100), 1024)
  out.from_dynamic_prev_rows = rows24(rp(it + 112), ru32(it + 124), 1024)
  -- §4.11.7 cheat (内嵌@216; CStaticIntelSourceReference: id@+16, discriminant@+20)
  out.cheat = { id = ru32(it + 232) or -1,
    discriminant = ru32(it + 236) or -1 }
  return out
end



-- ============================================================
-- §12 谍报机构 (mgr gs+0x6A0 §1.2; so/net/sub vt = §4.11.1 CStrategicOperative /
-- §4.11 CCountryIntelNetwork / §4.11.4 CSubIntelNetwork)
-- ============================================================
local OPS2 = { mgr_vt = GAME.layout.vt.CStrategicOperativesMgr,
  so_vt = GAME.layout.vt.CStrategicOperative,
  net_vt = GAME.layout.vt.COperativesNet, sub_vt = GAME.layout.vt.COperativesSubNet }
local function fq15(a)                   -- Q17.15 定点
  local v = rp(a)
  if not v then return nil end
  return v / 32768
end

-- 战支/战斗计数散标量 (上提, 段 sv2_sec_c_misc_tails 内联
-- 回收; §4.3 CCountry): 计数 u32@cc+4904/4908/4912/4916;
-- Q15 i64 五连 @cc+5312..5344 (writer sub_14070C580 同 helper);
-- last_collaborated i32@cc+12 (国 idx); ≠0 门全在段层
function Country.combat_support_scalars(self)
  local cc = self.addr
  -- Q15 带符号 (fq15 无符号修正, 惩罚族可负 — 勿复用)
  local function q15s(off)
    local v = LAYOUT.i64(cc + off)
    if not v then return nil end
    return v / 32768
  end
  return {
    num_armies_in_combat = ru32(cc + 4904),
    num_ships_in_combat = ru32(cc + 4908),
    num_ships = ru32(cc + 4912),
    convoys_destroyed = ru32(cc + 4916),
    propaganda_stability_penalty = q15s(5312),
    being_bombed_support_penalty = q15s(5320),
    heroes_dying_war_support_penalty = q15s(5328),
    convoy_raiding_war_support_penalty = q15s(5336),
    propaganda_war_support_penalty = q15s(5344),
    last_collaborated = ru32(cc + 12),
  }
end

-- CAirAce 族 (挂载 = §4.3 cc+4824 行, 元素表 §4.3.12; 布局/写门 = 书
-- country.ace 表)
function Country.aces(self)
  local cc = self.addr
  local d, n = rp(cc + 4824), ru32(cc + 4836)
  if not O.kptr(d) or not n or n == 0 or n > LAYOUT.lim.PTR_SANE then
    return nil end
  local out = {}
  for j = 0, n - 1 do
    local e = rp(d + 8 * j)
    if O.kptr(e) then
      local rec = {
        id_type = ru32(e + 8) or 0, id_id = ru32(e + 12) or 0,
        name = U.sso(e + 240), surname = U.sso(e + 272),
        callsign = U.sso(e + 304),
        is_female = (ru32(e + 336) or 0) & 0xFF,
        alive = (ru32(e + 344) or 0) & 0xFF,
        kill_type = ru32(e + 348) or 0,
        killer_name_type = ru32(e + 352) or 0,
        killer_name_id = ru32(e + 356) or 0,
        killer_country_tid = ru32(e + 360) or 0,
        handled = (ru32(e + 364) or 0) & 0xFF }
      local pt = ru32(e + 340)
      if pt then rec.portrait = pt end
      local mp = rp(e + 368)
      if O.kptr(mp) then rec.modifier = U.sso(mp + 8) end
      out[#out + 1] = rec
    end
  end
  return out
end
-- PID 7 槽解码 (§4.11.7 CCountryIntel +344/+400 同构; 7×i64×1e-5 @+0..+48)
local function pid7(base)
  return { previous_error = U.fix5(base), integral = U.fix5(base + 8),
    last_output = U.fix5(base + 16), value = U.fix5(base + 24),
    proportional_factor = U.fix5(base + 32), integral_factor = U.fix5(base + 40),
    derivative_factor = U.fix5(base + 48) }
end

function Runtime.operatives(self, country_idx)
  local g = self.gs()
  local mgr = g and rp(g + 0x6A0)
  if not O.kptr(mgr) or rp(mgr) ~= BASE + OPS2.mgr_vt then return nil end
  -- §4.11.1 挂载行: mgr 容器 {d@mgr+8, c@mgr+20} 8B 指针元
  local data, count = rp(mgr + 8), ru32(mgr + 20)
  if not O.kptr(data) or not count then return nil end
  if not country_idx then                -- 世界摘要
    local out = { countries = count, networks = 0, operative_slots = 0 }
    for i = 0, count - 1 do
      local so = rp(data + 8 * i)
      if O.kptr(so) and rp(so) == BASE + OPS2.so_vt then
        -- §4.11.1 CStrategicOperative+16 网数组 {d@+16, c@+28}
        local nd, nc = rp(so + 16), ru32(so + 28)
        if O.kptr(nd) and nc and nc > 0 then
          out.networks = out.networks + nc
          -- ⚠ legacy (L3626-3630) 只计每国**第一网**的 slots
          -- (net = rp(nd) 首元素); v2 原全网累加 → 37 vs legacy 24
          local net = rp(nd)
          if O.kptr(net) then
            out.operative_slots = out.operative_slots + (ru32(net + 108) or 0)
          end
        end
      end
    end
    return out
  end
  if country_idx < 0 or country_idx >= count then return nil end
  local so = rp(data + 8 * country_idx)
  if not O.kptr(so) or rp(so) ~= BASE + OPS2.so_vt then return nil end
  -- §4.11.1 CStrategicOperative: diplo_pressure 计数 +256/+288 /
  -- propaganda_weekly_drift Q17.15 +304/+312
  local out = { addr = so, country_idx = country_idx,
    drift = { war_support = fq15(so + 304), stability = fq15(so + 312) },
    diplo_pressure = { from_factions = ru32(so + 256),
      from_countries = ru32(so + 288) } }
  -- ⚠ 补: 发射端读 rop.propaganda_drift (legacy L3667, Q17.15);
  -- v2 原只有 drift 键 → ops.pdrift.ws/st 全缺 (每国 2 行)
  out.propaganda_drift = {
    war_support = fq15(so + 304), stability = fq15(so + 312) }
  -- §4.11.1 recent_propaganda_effort 宣传环 {data@184, cap@192, head@196, tail@200} 40B 元素
  -- {war_support Q17.15@0, stability Q17.15@8}; 写序 head→tail
  out.propaganda_ring_entries = (function()
    local d, cap = rp(so + 184), ru32(so + 192)
    local head, tail = ru32(so + 196), ru32(so + 200)
    local r = {}
    if not (O.kptr(d) and cap and cap > 0 and cap < 4096) then return r end
    local i2, n = head, 0
    while i2 ~= tail and n < cap do
      local e = d + 40 * i2
      r[#r + 1] = { ws = fq15(e), st = fq15(e + 8) }
      i2 = (i2 + 1) % cap
      n = n + 1
    end
    return r
  end)()
  -- §4.11.1 PID 7 槽: subversive_activity_level@+344 / danger_level@+400
  out.subversive_activity_level = pid7(so + 344)
  out.danger_level = pid7(so + 400)
  -- **多网循环** (核心修复: 每目标国一个 CCountryIntelNetwork)
  out.intel_networks = {}
  local nd, nc = rp(so + 16), ru32(so + 28)
  if O.kptr(nd) and nc and nc > 0 and nc < 256 then
    for ni = 0, nc - 1 do
      local net = rp(nd + 8 * ni)
      if O.kptr(net) and rp(net) == BASE + OPS2.net_vt then
        -- §4.11 CCountryIntelNetwork: target@+8 / operatives {+96,+108} /
        -- subnets {+120,+132} / coverage {+192..+200} / strength_sum {+208,+216}
        local tg = ru32(net + 8)
        local n = { addr = net, net_index = ni + 1,
          target_tag = tg, target = self:tag(tg) }
        -- operatives 顶点 {d@96, c@108} stride 12
        n.operatives = { count = ru32(net + 108) or 0, list = {} }
        for _, v in O.vec(net, 96, 108, 12, false) do
          n.operatives.list[#n.operatives.list + 1] = {
            type = ru32(v), id = ru32(v + 4), state_id = ru32(v + 8) }
        end
        -- sub_intel_networks {d@120, c@132} 元素 216B
        n.sub_intel_networks = { count = ru32(net + 132) or 0, list = {} }
        for _, s in O.vec(net, 120, 132, 216, false) do
          -- §4.11.4 CSubIntelNetwork (216B): strength 族 +32..+80 /
          -- is_quiet b@+88 / coverage {+92..+100} / total_coverable {+104..+112}
          local sub = {
            strength = U.fix5(s + 0x20),
            strength_sum = U.fix5(s + 0x28),
            strength_sum_over_cores = U.fix5(s + 0x30),
            national_coverage = U.fix5(s + 0x38),
            strength_target = U.fix5(s + 0x40),
            strength_target_from_operatives = U.fix5(s + 0x48),
            strength_target_from_counterintel = U.fix5(s + 0x50),
            is_quiet = (ru32(s + 88) & 0xFF) ~= 0,   -- 勘误: b@+88
            modifiers = {
              intel_network_gain_factor = U.fix5(s + 8),
              -- 换槽定案 (sub writer 0x1411F3430 token 实证
              -- 0x4B57@+24=chance, 0x3D50@+16=factor; 旧 +16/+24 记反)
              own_operative_detection_chance = U.fix5(s + 24),
              own_operative_detection_chance_factor = U.fix5(s + 16) },
            coverage = { core_states = ru32(s + 0x5C),
              controlled_states = ru32(s + 0x60),
              owned_worth = ru32(s + 0x64) },
            total_coverable = { core_states = ru32(s + 0x68),
              controlled_states = ru32(s + 0x6C),
              owned_worth = ru32(s + 0x70) },
            states = {}, states_precise = {} }
          -- §4.11.4 states {d@s+144, c@s+156} 16B {州指针, strength ×1e-5};
          -- 州 id = uint32@州对象+88 (无过滤全量写); states_precise =
          -- 结构化 {sid, str} 精确值 (writer 按 sid 升序排序 — 排序 =
          -- 发射规则留段侧; 旧 states "id|%.2f" 串保留兼容)
          for _, se in O.vec(s, 144, 156, 16, false) do
            local sp2 = rp(se)
            local sid2 = O.kptr(sp2) and ru32(sp2 + 88) or nil
            if sid2 then
              sub.states[#sub.states + 1] =
                  string.format("%d|%.2f", sid2, U.fix5(se + 8) or 0)
              sub.states_precise[#sub.states_precise + 1] =
                  { sid = sid2, str = U.fix5(se + 8) or 0 }
            end
          end
          -- §4.11.4 core_states = 独立容器 {d@s+168, c@s+180} (writer
          -- 0x1411F3430 token 0x3189: 8B CState*, 无过滤, count≠0 才写);
          -- states 全集是其超集
          sub.core_states = {}
          for _, sp2 in O.vec(s, 168, 180, 8, true) do
            local sid2 = O.kptr(sp2) and ru32(sp2 + 88) or nil
            if sid2 then
              sub.core_states[#sub.core_states + 1] = sid2
            end
          end
          -- §4.11.4 coverage_per_occupied {d@s+120, c@s+132} 12B 元
          -- {tag tid u32@0, owned_worth u32@+4, states u32@+8}
          -- (收全部元素 — tid 门与首条 .#1 发射伪影 = 段侧规则)
          sub.coverage_per_occupied = {}
          do
            local cvd, cvc = rp(s + 120), ru32(s + 132)
            if O.kptr(cvd) and cvc and cvc > 0 and cvc < 4096 then
              for j = 0, cvc - 1 do
                local el = cvd + 12 * j
                sub.coverage_per_occupied[#sub.coverage_per_occupied + 1] = {
                  tid = ru32(el) or 0,
                  owned_worth = ru32(el + 4) or 0,
                  states = ru32(el + 8) or 0 }
              end
            end
          end
          -- §4.11.4 operatives 打包 id 对 {d@s+192, c@s+204} 8B 元
          -- {type u32@0, id u32@+4}
          sub.op_pairs = {}
          do
            local od2, oc2 = rp(s + 192), ru32(s + 204)
            if O.kptr(od2) and oc2 and oc2 > 0 and oc2 < 4096 then
              for j = 0, oc2 - 1 do
                local e = od2 + 8 * j
                sub.op_pairs[#sub.op_pairs + 1] = {
                  type = ru32(e), id = ru32(e + 4) }
              end
            end
          end
          n.sub_intel_networks.list[#n.sub_intel_networks.list + 1] = sub
        end
        n.strength_sum = U.fix5(net + 208)
        n.strength_sum_over_cores = U.fix5(net + 216)
        -- §4.11.3 CLocalIntelNetwork 图 (writer 0x1411B1270, g = net+16)
        do
          local gg = net + 16
          local wrap = rp(gg + 8)
          if O.kptr(wrap) then
            local beg, fin = rp(wrap + 16), rp(wrap + 24)
            if O.kptr(beg) and fin and fin > beg and (fin - beg) % 80 == 0 then
              local vn = (fin - beg) / 80
              if vn > 0 and vn < 4096 then
                local gr2 = { vertices = vn, edges = {}, state_id = {},
                  gain = {}, gb = {}, strength = {}, depth = {},
                  sub_network_id = {}, quiet = {} }
                -- ⚠ 标签勘误: g+16 = sub_network_count,
                -- g+48 = prev_max_depth (第一网恒 (1,1) 曾掩盖互换)
                gr2.sub_network_count = ru32(gg + 16) or 0
                gr2.prev_max_depth = ru32(gg + 48) or 0
                for v2 = 0, vn - 1 do
                  local vx = beg + 80 * v2
                  gr2.sub_network_id[#gr2.sub_network_id + 1] =
                      ru32(vx + 24) or 0
                  gr2.depth[#gr2.depth + 1] = ru32(vx + 32) or 0
                  gr2.strength[#gr2.strength + 1] =
                      (rp(vx + 40) or 0) * 1e-5
                  gr2.gb[#gr2.gb + 1] = {
                    operatives = (rp(vx + 48) or 0) * 1e-5,
                    adjacencies = (rp(vx + 56) or 0) * 1e-5 }
                  gr2.gain[#gr2.gain + 1] = (rp(vx + 64) or 0) * 1e-5
                  gr2.state_id[#gr2.state_id + 1] = ru32(vx + 72) or 0
                end
                local sentinel = rp(wrap)
                if O.kptr(sentinel) then
                  local el = rp(sentinel)
                  local guard = 0
                  while el and el ~= sentinel and guard < 8192 do
                    guard = guard + 1
                    gr2.edges[#gr2.edges + 1] = ru32(el + 16) or 0
                    gr2.edges[#gr2.edges + 1] = ru32(el + 24) or 0
                    el = rp(el)
                  end
                end
                -- ⚠ 勘误: quiet/prev_gain_sources 原用 O.vec(deref=false)
                -- 拿到的是元素地址 — bool 数组须逐字节 read_u8 (legacy L3829),
                -- u32 数组须 ru32 解引用 (legacy L3838)
                do
                  local qd, qc = rp(gg + 24), ru32(gg + 36)
                  if O.kptr(qd) and qc and qc > 0 and qc < 4096 then
                    for q2 = 0, qc - 1 do
                      gr2.quiet[#gr2.quiet + 1] =
                          (ru8(qd + q2) or 0) ~= 0 and "yes" or "no"
                    end
                  end
                end
                gr2.prev_gain_sources = {}
                do
                  local gd, gc = rp(gg + 56), ru32(gg + 68)
                  if O.kptr(gd) and gc and gc > 0 and gc < 4096 then
                    for g2 = 0, gc - 1 do
                      gr2.prev_gain_sources[#gr2.prev_gain_sources + 1] =
                          ru32(gd + 4 * g2) or 0
                    end
                  end
                end
                if #gr2.prev_gain_sources == 0 then
                  gr2.prev_gain_sources = nil end
                n.graph = gr2
              end
            end
          end
        end
        -- §4.11.5 intel_source 内联@net+168 (vt 0x295f138; idx>0 且 pool≠0 才写)
        local els = net + 168
        if rp(els) == (BASE + GAME.layout.vt.CIntelSource) then
          local eidx, epool = ru32(els + 8), ru32(els + 12)
          if eidx and eidx > 0 and epool and epool ~= 0 then
            n.intel_source = { country = self:tag(eidx), pool = epool,
              id = ru32(els + 16), discriminant = ru32(els + 20) }
          end
        end
        n.coverage = { core_states = ru32(net + 192),
          controlled_states = ru32(net + 196),
          owned_worth = ru32(net + 200) }
        -- §4.11 max_coverage_by_occupied_tag {d@net+144, c@net+156} 40B 元
        -- {tag tid u32@0, owned_worth u32@+8, states u32@+12,
        --  gain_factor ×1e-5@+16, det_factor ×1e-5@+24, det ×1e-5@+32}
        -- (收全部元素 — tid 门与首条 .#1 发射伪影 = 段侧规则)
        n.max_coverage_by_occupied_tag = {}
        do
          local md, mc = rp(net + 144), ru32(net + 156)
          if O.kptr(md) and mc and mc > 0 and mc < 4096 then
            for j = 0, mc - 1 do
              local el = md + 40 * j
              n.max_coverage_by_occupied_tag[#n.max_coverage_by_occupied_tag + 1] = {
                tid = ru32(el) or 0,
                owned_worth = ru32(el + 8) or 0,
                states = ru32(el + 12) or 0,
                gain_factor = GAME.layout.as_i64(rp(el + 16) or 0) / 100000,
                detection_chance_factor =
                  GAME.layout.as_i64(rp(el + 24) or 0) / 100000,
                detection_chance =
                  GAME.layout.as_i64(rp(el + 32) or 0) / 100000 }
            end
          end
        end
        -- §4.11 +224 恒写 (writer 0x1411C1BE0 尾: sub_1424AE590(0x4C6A,
        -- *(a1+224)) — i64 ×1e-5)
        n.state_strength_max = U.fix5(net + 224)
        out.intel_networks[#out.intel_networks + 1] = n
        if ni == 0 then out.intel_network = n end   -- 兼容旧引用
      end
    end
  end
  return out
end



-- ============================================================
-- §29 国策进度 + 角色深层族
-- ============================================================
-- 29.1 focus (§4.3.14 CFocusStatus = CNationalFocusProgress RTTI 正名,
-- cc+0x1380; 布局/写门 = 书 §4.3.14; completed 必须按 count 取 —
-- kptr 扫描会把容量内脏槽当条目)
function Country.focus(self)
  local fp = rp(self.addr + 0x1380)
  if not O.kptr(fp) then return nil end
  local out = { addr = fp, progress = U.fix5(fp + 0x38) }
  local cur = rp(fp + 0x10)
  if O.kptr(cur) then out.current = U.cstr(cur + 24) end
  -- current_continuous (curc ptr@fp+0x18, 名 C 串@+24,
  -- 与 current 同构; 段侧内联回收)
  local curc = rp(fp + 0x18)
  if O.kptr(curc) then out.current_continuous = U.cstr(curc + 24) end
  out.paused = (U.a8(fp + 0xB0) or 0) == 1
  out.paused_raw = U.a8(fp + 0xB0)   -- 原 byte (发射门 ==0 → "no")
  out.completed = {}
  out.completed_count = ru32(fp + 0x4C) or 0
  -- §4.3.14 shine 列表 (fp+32 {d,c@+44}; 名 C 串@+24 非空才收)
  out.shine = {}
  do
    local sd, sc = rp(fp + 32), ru32(fp + 44) or 0
    if O.kptr(sd) and sc > 0 and sc < LAYOUT.lim.PTR_SANE then
      for k = 0, sc - 1 do
        local e = rp(sd + 8 * k)
        if O.kptr(e) then
          local nm = U.cstr(e + 24)
          if nm and nm ~= "" then
            out.shine[#out.shine + 1] = nm end
        end
      end
    end
  end
  -- §4.3.14 completed 双形态记录 (联合判定 + originator RH + 失效图;
  -- 渲染规则: joint → "TAG 名" (tid 0 渲 "---"), plain → '"名"')。
  -- 基桩 vt 判定 1.19.3 = BASE+0x11D220 (rp(vt+112) 相等 = plain)。
  out.completed_records = {}
  do
    local R = self.R
    local cd, cc2 = rp(fp + 0x40), ru32(fp + 0x4C) or 0
    if O.kptr(cd) and cc2 > 0 and cc2 <= 1024 then
      -- originator 表 (fp+152 RH, 24B 桶 {hash@0, dist@+4, key@+8, tid@+16})
      local ob, omask = rp(fp + 152), ru32(fp + 164)
      local oextra = ru8(fp + 168) or 0
      local ovalid = O.kptr(ob) and omask and omask < 0x10000
      -- fp+88 失效图 (16B 桶 {hash@0, dist@+4, key@+8}; 值 vp+4==0xFF
      -- = 失效 → tid 0)
      local ib, imask = rp(fp + 96), ru32(fp + 108)
      local iextra = ru8(fp + 112) or 0
      local ivalid = O.kptr(ib) and imask and imask < 0x10000
      -- FNV-1a 32bit over 8 ptr bytes (键散布)
      local function fnv1a_ptr(p)
        local h = 0x811C9DC5
        for i = 0, 7 do
          local b = (p >> (8 * i)) & 0xFF
          h = ((h ~ b) * 16777619) & 0xFFFFFFFF
        end
        return h
      end
      local function originator(e)
        if ivalid then
          local h = fnv1a_ptr(e)
          local bk = ib + 16 * (h & imask)
          local n = 1
          while true do
            local dist = ru8(bk + 4)
            if not dist or dist == 0 or n > dist then break end
            if rp(bk + 8) == e then
              local vp = rp(bk)
              if O.kptr(vp) and ru8(vp + 4) == 0xFF then
                return 0          -- 失效 → tid 0
              end
              break
            end
            bk = bk + 16
            n = n + 1
            if n > imask + iextra + 2 then break end
          end
        end
        if ovalid then
          local h = fnv1a_ptr(e)
          local bk = ob + 24 * (h & omask)
          local n = 1
          while true do
            local dist = ru8(bk + 4)
            if not dist or dist == 0 or n > dist then break end
            if rp(bk + 8) == e then
              return ru32(bk + 16) or 0
            end
            bk = bk + 24
            n = n + 1
            if n > omask + oextra + 2 then break end
          end
        end
        return 0
      end
      for k = 0, cc2 - 1 do
        local e = rp(cd + 8 * k)
        if O.kptr(e) then
          local nm = U.cstr(e + 24)
          if nm and nm ~= "" then
            local vt = rp(e)
            -- ⚠ vt 判定勿用 O.kptr: 其上界 0x7FF000000000 切在
            -- 本机映像基址 (0x7FF7_9x…) 之下, 虚表指针恒 false →
            -- 全体误判 plain; 这里只需要下界哨兵
            local joint = vt and vt >= 0x10000
                and rp(vt + 112) ~= BASE + 0x11D220
            local rec = { name = nm, joint = joint and true or false }
            if rec.joint then
              local tid = originator(e)
              rec.originator_tid = tid
              rec.originator = (tid > 0 and R) and R:tag(tid) or nil
            end
            out.completed_records[#out.completed_records + 1] = rec
          end
        end
      end
    end
  end
  local cd = rp(fp + 0x40)
  if O.kptr(cd) and out.completed_count > 0 and out.completed_count <= 128 then
    for i = 0, out.completed_count - 1 do
      local e = rp(cd + 8 * i)
      if not O.kptr(e) then break end
      out.completed[#out.completed + 1] = U.cstr(e + 24)
    end
  end
  return out
end

-- 29.2 角色顾问 (§4.4.11 CCharacter+176 advisors 链, 载荷 CAdvisor* @node+72;
-- §4.4.15 CAdvisor 全字段/ledger 枚举 = 书 §4.4.15)
function Runtime.char_advisors(self, char_id)
  local ch = self:character(char_id)
  if not ch then return nil end
  local head = rp(ch.addr + 176)
  if not O.kptr(head) then return { count = 0, list = {} } end
  local out = { count = 0, list = {} }
  local node, n = rp(head), 0
  while O.kptr(node) and node ~= head and n < 64 do
    n = n + 1
    local adv = rp(node + 72)
    if O.kptr(adv) then
      local rec = { addr = adv, slot = U.sso(adv + 0x80),
        idea_token = U.sso(adv + 0x30), ledger = ru32(adv + 0x28),
        political_power = (rp(adv + 0xA8) or 0) * 1e-5, traits = {} }
      local td, tc = rp(adv + 0xC8), ru32(adv + 0xD4)
      if O.kptr(td) and tc and tc > 0 and tc < 32 then
        for j = 0, tc - 1 do
          local tr = rp(td + 8 * j)
          if O.kptr(tr) then
            rec.traits[#rec.traits + 1] = U.sso(tr + 0x18)
          end
        end
      end
      out.list[#out.list + 1] = rec
    end
    node = rp(node)
  end
  out.count = #out.list
  return out
end

-- 29.3 角色肖像 (§4.4.10 CCharacterPortraits 内嵌 @CCharacter+120,
-- vt 0x14274F3D8): 容器 {data@+8, count@+20} 元素 56B
-- {type u32@+0, size u32@+4, MSVC string@+0x10} (探针实证)
-- type: 0=civilian 1=army 2=navy 3=air 4=operative 5=scientist
function Runtime.char_portraits(self, char_id)
  local ch = self:character(char_id)
  if not ch then return nil end
  local pp = ch.addr + 120
  local d, c = rp(pp + 8), ru32(pp + 20)
  local out = { count = c or 0, list = {} }
  if not O.kptr(d) or not c or c > 64 then return out end
  local TYPE_NAMES = { "civilian", "army", "navy", "air", "operative",
    "scientist" }
  for j = 0, c - 1 do
    local e = d + 56 * j
    local t, sz = ru32(e), ru32(e + 4)
    out.list[#out.list + 1] = {
      ptype = TYPE_NAMES[(t or 0) + 1] or ("t" .. tostring(t)),
      size = (sz == 1 and "large") or "small",
      path = U.sso(e + 0x10) }
  end
  return out
end

-- 29.4 leader 四技能 (统一挂 §4.4.11 CCharacter+0xA8 CUnitLeader; 双布局按
-- leader_type 分派 = §4.4.5 CArmyLeader / §4.4.6 CNavyLeader, 偏移/键/技能直存 = 书两表)
function Runtime.leader_extras(self, char_id)
  local ch = self:character(char_id)
  if not ch then return nil end
  local l = rp(ch.addr + 0xA8)
  if not O.kptr(l) then return nil end
  local lt = ru32(l + 0xE7C)
  if lt == 2 then
    return { addr = l, leader_type = lt,
      attack = ru32(l + 3944), defense = ru32(l + 3960),
      maneuvering = ru32(l + 3976), coordination = ru32(l + 3992) }
  end
  return { addr = l, leader_type = lt,
    attack = ru32(l + 3928), defense = ru32(l + 3944),
    planning = ru32(l + 3960), logistics = ru32(l + 3976) }
end

-- 29.5 char_extras (§4.4.11 CCharacter; template/gender/operative 对/variables/
-- random 对反序/flags 字段与写门 = 书 §4.4.11+§4.13.2, variables 空判 = §4.4.10 BB9830 同构)
function Runtime.char_extras(self, char_id)
  local ch = self:character(char_id)
  if not ch then return nil end
  local p = ch.addr
  local r = { _addr = p }
  local function _tk(v)
    if not v or v == 0 then return nil end
    return LAYOUT.token_name(v) or ("k" .. tostring(v))
  end
  local tp = rp(p + 32)
  r.template = _tk(O.kptr(tp) and ru32(tp + 8) or nil)
  local g = ru32(p + 112) or 0
  r.gender = (g == 1 and "male") or (g == 2 and "female") or "undefined"
  local ot, oi = ru32(p + 200) or 0, ru32(p + 204) or 0
  if ot ~= 0 or oi ~= 0 then r.operative_type, r.operative_id = ot, oi end
  local vv = p + 216
  local r1, r2 = ru32(vv + 8) or 0, ru32(vv + 12) or 0
  local vempty = (r1 == 1 and (ru32(vv + 32) or 0) == 0)
  if not vempty then
    r.random = string.format("%d %d", r2, r1)
  end
  r._vcount = ru32(vv + 32) or 0
  local fs = p + 272
  local fe, fc = rp(fs + 8), ru32(fs + 20) or 0
  local fl = {}
  if O.kptr(fe) and fc > 0 and fc < 100000 then
    for i = 0, fc - 1 do
      local e = fe + 0x30 * i
      local key = ru32(e + 8) or 0
      if key ~= 0 and key < 100000 then
        local raw = ru32(e + 0x28) or 0
        local v = raw & 0xFFFF
        v = LAYOUT.as_i16(v)
        fl[#fl + 1] = { name = _tk(key) or ("k" .. tostring(key)),
          value = v, days = (raw >> 16) & 0x7FFF,
          date = U.date(ru32(e + 0x18)) }
      end
    end
  end
  r.flags = fl
  return r
end

-- 29.6 commander_deep: §4.4.2 CUnitLeader 深层族 (+4272 preferred_tactic =
-- §4.4.5 CArmyLeader 尾段; 字段/写门/gfx 堆串/legacy_id = 书 §4.4.2 表)
function Runtime.commander_deep(self, char_id)
  local ch = self:character(char_id)
  if not ch then return nil end
  local l = rp(ch.addr + 0xA8)
  if not O.kptr(l) then return nil end
  local lt = ru32(l + 0xE7C)
  local function _tok(ptr)
    if not O.kptr(ptr) then return nil end
    local t = ru32(ptr + 8)
    return t and (LAYOUT.token_name(t) or ("tok" .. tostring(t))) or nil
  end
  local function _pair_list(doff, coff)
    local d, c = rp(l + doff), ru32(l + coff)
    local t = {}
    if O.kptr(d) and c and c > 0 and c <= 128 then
      for i = 0, c - 1 do
        local e = d + 16 * i
        local name = _tok(rp(e))
        if name then
          t[#t + 1] = name .. "=" .. string.format("%.5f", U.fix5(e + 8) or 0)
        end
      end
    end
    return table.concat(t, ";")
  end
  local function _trait_names()
    local d, c = rp(l + 3528), ru32(l + 3540)
    local t = {}
    if O.kptr(d) and c and c > 0 and c <= 128 then
      for i = 0, c - 1 do
        local name = _tok(rp(d + 8 * i))
        if name then t[#t + 1] = name end
      end
    end
    return table.concat(t, " ")
  end
  local skillo, tacp = rp(l + 3680), rp(l + 4272)
  local gfx = ""
  local gp = rp(l + 256)
  if O.kptr(gp) then
    local chars = {}
    for i = 0, 63 do
      local c8 = U.a8(gp + i)
      if not c8 or c8 == 0 then break end
      chars[#chars + 1] = string.char(c8)
    end
    if #chars >= 3 then gfx = table.concat(chars) end
  end
  return { addr = l, leader_type = lt,
    id_seq = ru32(l + 12) or -1, type_id = ru32(l + 8) or -1,
    name = U.sso(l + 32), gfx = gfx,
    female = U.a8(l + 3712) or 0,
    skill = (O.kptr(skillo) and ru32(skillo + 440)) or -1,
    experience = U.fix5(l + 3688),
    script_id = ru32(l + 3924) or 0,
    preferred_tactic = (O.kptr(tacp) and ru32(tacp + 152)) or 0,
    -- §4.4.2 legacy_id u32@+3800: 门 ≠-1; 有符号域 (PB:LOM 实证, 同 country_leader.id)
    legacy_id = to_i32(ru32(l + 3800) or -1),
    traits = _trait_names(),
    in_progress = _pair_list(3576, 3588),
    trait_xp_factor = _pair_list(3600, 3612) }
end

-- 29.7 navy_leader_extras: §4.4.6 CNavyLeader 0x10B8 (vt 0x2955dc0)
-- 特有 9 键: 四技能 navy 布局 + temp_deficit u32@+4016..+4028 +
-- penalty ×1e-5@+4032 (默认 1.0; 锚 Habib Allah Nuristani 1/2/2/2)
function Runtime.navy_leader_extras(self, char_id)
  local ch = self:character(char_id)
  if not ch then return nil end
  local l = rp(ch.addr + 0xA8)
  if not O.kptr(l) then return nil end
  return { addr = l,
    attack = ru32(l + 3944), defense = ru32(l + 3960),
    maneuvering = ru32(l + 3976), coordination = ru32(l + 3992),
    penalty = U.fix5(l + 4032),
    temp_deficit = { ru32(l + 4016), ru32(l + 4020), ru32(l + 4024),
      ru32(l + 4028) } }
end

-- ============================================================

-- ============================================================
-- §4.4.9 character_manager 导出全量 reader (sv2_sec_character_manager 消费;
-- writer 忠实; 存档 character[N] 写序 = 池内 id 升序 = reader 排序契约)。
-- ⚠ leader fix5 = ×1e-5 (本域实证); sso/tokenname 缺表拒收 "=" 占位。
local CM_VT_CHAR = GAME.layout.vt.CCharacter

local function cm_sso(obj)
  if not obj or obj < 0x10000 then return nil end
  local size = ru32(obj + 0x10)
  if not size or size > 4096 then return nil end
  if size == 0 then return "" end
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
local function cm_tokname(t)
  if not t or t == 0 then return nil end
  local n = GAME.layout.token_name(t)
  if type(n) == "string" and n ~= "" and n ~= "=" then return n end
  return nil
end
local function cm_tagstr(tid)
  local g = Runtime.gs()
  local ttab = g and rp(g + 0x358)
  if not tid or tid <= 0 or tid >= 100000 or not ttab then return nil end
  return hoi4.read_str(ttab + 32 * tid)
end
local function cm_fix5(a) return (rp(a) or 0) * 1e-5 end

-- §4.3.8 CModifier 本体 (name/data/pairs 三分; added_modifier 数组B 0 叶)
local function cm_modifier(mod)
  local rec = {}
  if not O.kptr(mod) then return rec end
  local dv = ru32(mod + 188)
  if dv and dv ~= 1 then rec.data = dv end
  local nm = cm_sso(mod + 88)
  if nm and nm ~= "" then rec.name = nm end
  local mnd = GAME.layout.modifier_count() or 0
  if mnd > 0 then
    local d, c = rp(mod + 16), ru32(mod + 28)
    if O.kptr(d) and c and c > 0 and c <= LAYOUT.lim.PTR_SANE then
      rec.pairs = {}
      for j = 0, c - 1 do
        local e = d + 16 * j
        local mn = GAME.layout.modifier_token(ru32(e))
        if mn then
          rec.pairs[#rec.pairs + 1] = { name = mn, value = cm_fix5(e + 8) }
        end
      end
    end
  end
  return rec
end

-- §4.4.2 CUnitLeader 16B {trait_ptr@0, val@+8} 对列表
local function cm_pair_list(l, doff, coff, is_int)
  local d, c = rp(l + doff), ru32(l + coff)
  local out = {}
  if O.kptr(d) and c and c > 0 and c <= 128 then
    for i = 0, c - 1 do
      local e = d + 16 * i
      local tp = rp(e)
      local nm = O.kptr(tp) and cm_tokname(ru32(tp + 8)) or nil
      if nm then
        if is_int then
          out[#out + 1] = { name = nm, value = LAYOUT.as_i32(ru32(e + 8)) or 0 }
        else
          out[#out + 1] = { name = nm, value = cm_fix5(e + 8) }
        end
      end
    end
  end
  return out
end

local CM_REASON = { [1] = "reassigned", [2] = "harmed",
  [3] = "forced_into_hiding", [4] = "deployed", [5] = "withdrawing" }
local CM_LEDGER = { [4] = "army", [8] = "navy", [16] = "air",
  [28] = "military", [0xFFFFFFFF] = "invalid", [1] = "hidden",
  [30] = "all", [2] = "civilian" }
local CM_KIND = { [0] = "field_marshal", [1] = "corps_commander",
  [2] = "navy_leader" }

-- 将领块 (§4.4.2 CUnitLeader / §4.4.5 CArmyLeader / §4.4.6 CNavyLeader)
local function cm_leader(p)
  local l = rp(p + 0xA8)
  if not O.kptr(l) then return nil end
  local lt = ru32(l + 0xE7C)
  local kind = CM_KIND[lt]
  if not kind then return nil end
  local rec = { kind = kind }
  rec.id_type = ru32(l + 8) or 0
  rec.id_id = ru32(l + 12) or 0
  rec.name = cm_sso(l + 32)
  rec.desc = cm_sso(l + 128)
  rec.custom_cost_text = cm_sso(l + 160)
  rec.portrait_path = cm_sso(l + 192)
  rec.picture = cm_sso(l + 224)
  rec.gfx = cm_sso(l + 256)
  if (ru8(l + 3713) or 0) ~= 0 then
    rec.female = (ru8(l + 3712) or 0) ~= 0 end
  local sko = rp(l + 3680)
  if O.kptr(sko) then
    local sk = ru32(sko + 440)
    if sk then rec.skill = sk end end
  if (rp(l + 3688) or 0) ~= 0 then rec.experience = cm_fix5(l + 3688) end
  local sid = ru32(l + 3924)
  if sid and sid ~= 0 then rec.script_id = sid end
  rec.link = cm_sso(l + 3648)
  if (rp(l + 3776) or 0) ~= 0 then rec.max_traits = cm_fix5(l + 3776) end
  -- 四技能 (≠0 才写): army 3928.. / navy 3944..; temp_deficit 有符号
  local SK = { "attack_skill", "defense_skill" }
  if lt == 2 then
    SK[3], SK[4] = "maneuvering_skill", "coordination_skill"
  else
    SK[3], SK[4] = "planning_skill", "logistics_skill"
  end
  local soff = lt == 2 and { 3944, 3960, 3976, 3992 }
    or { 3928, 3944, 3960, 3976 }
  for i = 1, 4 do
    local v = ru32(l + soff[i])
    if v and v ~= 0 then rec[SK[i]] = v end
  end
  local toff = lt == 2 and { 4016, 4020, 4024, 4028 }
    or { 3992, 3996, 4000, 4004 }
  for i = 1, 4 do
    local v = LAYOUT.as_i32(ru32(l + toff[i]))
    if v and v ~= 0 then
      rec[SK[i]:gsub("_skill$", "_skill_temp_deficit")] = v end
  end
  if lt ~= 2 then
    local tp = rp(l + 4272)
    if O.kptr(tp) then rec.preferred_tactic = ru32(tp + 152) or 0 end
    local pt0, pt1 = ru32(l + 4176), ru32(l + 4180)
    if (pt0 and pt0 ~= 0) or (pt1 and pt1 ~= 0) then
      -- writer 尾段有 idreg 注册表校验 (sub_14220A3D0): 悬垂引用不写
      if GAME.layout.idreg_unit_resolve(pt0, pt1) then
        rec.pending_reassign = { type = pt0 or 0, id = pt1 or 0 } end
    end
  end
  if lt == 2 then
    local hqid = ru32(l + 4012)
    if hqid and hqid ~= 0 then
      rec.naval_headquarter = { type = ru32(l + 4008) or 0, id = hqid } end
    rec.penalty = cm_fix5(l + 4032)
  end
  do -- traits (空不写)
    local d, c = rp(l + 3528), ru32(l + 3540)
    if O.kptr(d) and c and c > 0 and c <= 128 then
      local ts = {}
      for i = 0, c - 1 do
        local tp = rp(d + 8 * i)
        local nm = O.kptr(tp) and cm_tokname(ru32(tp + 8))
        if nm then ts[#ts + 1] = nm end
      end
      if #ts > 0 then rec.traits = ts end
    end
  end
  rec.in_progress = cm_pair_list(l, 3576, 3588, false)
  rec.traits_to_remove = cm_pair_list(l, 3552, 3564, true)
  rec.trait_xp_factor = cm_pair_list(l, 3600, 3612, false)
  local cd = ru32(l + 3716)
  if cd and cd ~= 0 then
    rec.cooldown_reason = CM_REASON[cd]
    rec.enable_h = ru32(l + 3752)
    rec.cooldown_start_h = ru32(l + 3728)
  end
  local gx = ru32(l + 3796)
  if gx and gx > 0 then rec.government_in_exile_tag = cm_tagstr(gx) end
  local leg = ru32(l + 3800)
  if leg and leg ~= 0xFFFFFFFF then
    rec.legacy_id = LAYOUT.as_i32(leg) end
  rec.promoted_from_unit = (ru8(l + 3804) or 0) ~= 0
  if lt ~= 2 and (ru8(l + 4185) or 0) ~= 0 then
    rec.captured = true
    local cb = LAYOUT.as_i32(ru32(l + 4188)) or 0
    if cb > 0 then rec.captured_by = cm_tagstr(cb) end
    local lp = rp(l + 4192)
    if O.kptr(lp) then rec.captured_location = ru32(lp + 164) or 0 end
  end
  if lt ~= 2 and (ru8(l + 4200) or 0) ~= 0 then
    rec.deployed = true
    rec.deployment_cost = cm_fix5(l + 4208) end
  do -- sub_unit_modifiers (A/B key 升序归并; units 叶未解仅出修正)
    local dA, dB = rp(l + 304), rp(l + 328)
    local cA = (O.kptr(dA) and ru32(l + 316)) or 0
    local cB = (O.kptr(dB) and ru32(l + 340)) or 0
    if cA > LAYOUT.lim.PTR_SANE then cA = 0 end
    if cB > LAYOUT.lim.PTR_SANE then cB = 0 end
    if cA + cB > 0 then
      rec.sub_unit_modifiers = {}
      local function shipname(idx)
        if not idx then return nil end
        if idx == 0 then return "null" end
        return LAYOUT.idb_token("sub_unit", idx)
      end
      local function emit_B(j)
        local e = dB + 208 * j
        local nm = shipname(ru32(e + 8))
        local mod = e + 16
        if nm and rp(mod) == BASE + 0x27185F0 then
          rec.sub_unit_modifiers[#rec.sub_unit_modifiers + 1] =
            { ship = nm, mod = cm_modifier(mod) }
        end
      end
      local i, j = 0, 0
      while i < cA or j < cB do
        local kA = (i < cA and ru32(dA + 56 * i + 8)) or 0xFFFFFFFF
        local kB = (j < cB and ru32(dB + 208 * j + 8)) or 0xFFFFFFFF
        if kA <= kB then
          if kA == kB and j < cB then emit_B(j); j = j + 1 end
          i = i + 1
        else
          emit_B(j); j = j + 1
        end
      end
    end
  end
  return rec
end

-- 顾问块 (§4.4.11 map 中序; §4.4.15 CAdvisor)
local function cm_isnil(n)
  return not O.kptr(n) or (ru8(n + 25) or 1) ~= 0
end
local function cm_advisors(p)
  local head = rp(p + 0xB0)
  if not O.kptr(head) then return nil end
  local out = {}
  local nodes = GAME.layout.rb_inorder(head)
  local guard = 0
  for _, node in ipairs(nodes or {}) do
    guard = guard + 1
    if guard > 64 then break end
    local adv = rp(node + 72)
    if O.kptr(adv) then
      local a = { slot = cm_sso(adv + 0x80) }
      -- template ref@+0x18 → get=*(ref+0x10); 兜底 dynamic_template@+0x20
      local ref = rp(adv + 0x18)
      local tname
      if O.kptr(ref) then
        local obj = rp(ref + 0x10)
        if O.kptr(obj) then
          tname = cm_tokname(ru32(obj + 8))
          if not tname then
            local s2 = cm_sso(obj + 0x18)
            if s2 and s2 ~= "" then tname = s2 end
          end
        end
      end
      if tname then
        a.template = tname
      else
        local dtp = rp(adv + 0x20)
        if O.kptr(dtp)
            and rp(dtp) == BASE + GAME.layout.vt.CAdvisorTemplate then
          local dt = {}
          local lv = ru32(dtp + 0x18) or 0
          if lv == 0xFFFF then lv = 0xFFFFFFFF end
          dt.ledger = CM_LEDGER[lv]
          dt.slot = cm_sso(dtp + 0x70)
          dt.idea_token = cm_sso(dtp + 0x20)
          dt.cost = cm_fix5(dtp + 0xB8)
          dt.removal_cost = cm_fix5(dtp + 0xC8)
          dt.can_be_fired = (ru8(dtp + 0xD0)) ~= 0
          dt.command_power = cm_fix5(dtp + 0xD8)
          do
            local d, c = rp(dtp + 0xE0), ru32(dtp + 0xEC)
            if O.kptr(d) and c and c > 0
                and c < LAYOUT.lim.PTR_SANE then
              dt.traits = {}
              for j = 0, c - 1 do
                local tnm = cm_sso(d + 40 * j)
                if tnm and tnm ~= "" then
                  dt.traits[#dt.traits + 1] = tnm end
              end
            end
          end
          dt.desc = cm_sso(dtp + 0x418)
          a.dynamic_template = dt
        end
      end
      do
        local lv = ru32(adv + 0x28) or 0
        if lv == 0xFFFF then lv = 0xFFFFFFFF end
        a.ledger = CM_LEDGER[lv]
      end
      a.idea_token = cm_sso(adv + 0x30)
      if (rp(adv + 0xA8) or 0) ~= 0 then
        a.political_power = cm_fix5(adv + 0xA8) end
      if (rp(adv + 0xC0) or 0) ~= 0 then
        a.command_power = cm_fix5(adv + 0xC0) end
      do
        local d, c = rp(adv + 0xC8), ru32(adv + 0xD4)
        if O.kptr(d) and c and c > 0 and c < LAYOUT.lim.PTR_SANE then
          a.traits = {}
          for j = 0, c - 1 do
            local tr = rp(d + 8 * j)
            if O.kptr(tr) then
              local nm = cm_sso(tr + 0x18)
              if nm and nm ~= "" then
                a.traits[#a.traits + 1] = nm end end
          end
        end
      end
      a.portrait = cm_sso(adv + 0x280)
      if (rp(adv + 0xB0) or 0) ~= 0 then
        a.removal_cost = cm_fix5(adv + 0xB0) end
      a.can_be_fired_no = (ru8(adv + 0xB8) or 1) == 0
      a.desc = cm_sso(adv + 0x2D8)
      do -- modifier 内嵌@+0xE0 (块门三选一 = 书)
        local mod = adv + 0xE0
        local gate = (LAYOUT.as_i32(ru32(mod + 136)) or 0) > 0
            or (ru32(mod + 52) or 0) ~= 0
        if not gate then
          local mnd = GAME.layout.modifier_count() or 0
          if mnd > 0 then
            local d, c = rp(mod + 16), ru32(mod + 28)
            if O.kptr(d) and c and c > 0 and c <= LAYOUT.lim.PTR_SANE then
              local cmask = GAME.layout.modifier_category_mask() or 0
              for j = 0, c - 1 do
                local cat = GAME.layout.modifier_category(
                    ru32(d + 16 * j))
                if cat and (cat == 0 or (cmask & cat) ~= 0) then
                  gate = true
                  break
                end
              end
            end
          end
        end
        if gate then a.modifier = cm_modifier(mod) end
      end
      out[#out + 1] = a
    end
  end
  return out
end

-- Runtime.character_manager_full -> {next_character_id, historical, dynamic}
function Runtime.character_manager_full(self)
  local g = self.gs()
  local mgr = g and rp(g + 0x6A8)
  if not O.kptr(mgr) then return nil end
  local out = {}
  local ncid = ru32(mgr + 8)
  if ncid then out.next_character_id = ncid end
  local function pool(doff, coff)
    local data, n = rp(mgr + doff), ru32(mgr + coff)
    local t = {}
    if O.kptr(data) and n and n > 0 and n < 200000 then
      for i = 0, n - 1 do
        local p = rp(data + 8 * i)
        if p and rp(p) == BASE + CM_VT_CHAR then
          t[#t + 1] = { addr = p, id = ru32(p + 0xC) or 0 }
        end
      end
    end
    table.sort(t, function(a, b) return a.id < b.id end)
    return t
  end
  local function char_rec(ch)
    local p = ch.addr
    local rec = { id = ch.id, addr = p,
      id_type = ru32(p + 8) or 0, id_id = ru32(p + 0xC) or 0 }
    rec.token = cm_tokname(ru32(p + 0x18))
    local tp = rp(p + 0x20)
    if O.kptr(tp) then rec.template = cm_tokname(ru32(tp + 8)) end
    rec.name = cm_sso(p + 0x48)
    local tid = ru32(p + 0x68)
    if tid and tid > 0 then rec.country = cm_tagstr(tid) end
    local nid = ru32(p + 0x6C)
    if nid and nid > 0 then rec.nationality = cm_tagstr(nid) end
    rec.gender = ru32(p + 0x70) or 0
    rec.leader = cm_leader(p)
    local ot, oi = ru32(p + 0xC8) or 0, ru32(p + 0xCC) or 0
    if ot ~= 0 or oi ~= 0 then
      rec.operative = { type = ot, id = oi } end
    rec.advisors = cm_advisors(p)
    do -- variables CVariables 内嵌 @p+216 (BB9830 判空门 = count@+32)
      local vo = p + 216
      local vcnt = ru32(vo + 32) or 0
      if vcnt > 0 and vcnt < LAYOUT.lim.PTR_HUGE then
        local buckets = GAME.layout.rh_iter(vo, { data = 0x18,
          mask = 0x24, count = 0x20, stride = 0x30,
          maxn = LAYOUT.lim.PTR_HUGE })
        local vlist = {}
        for _, b in ipairs(buckets or {}) do
          local dist = ru32(b + 4)
          if dist and (dist & 0xFF) ~= 0 and (dist & 0xFF) ~= 0xFE
              and (dist & 0xFF) ~= 0xFF then
            local nm = cm_sso(b + 8)
            local v = rp(b + 0x28)
            if v then v = LAYOUT.as_i64(v) end
            if nm and v then
              vlist[#vlist + 1] = { name = nm, value = v / 100000 } end
          end
        end
        rec.variables = vlist   -- 排序/^N 判定 = 段层 (拼串排 + %.5f)
      end
    end
    return rec
  end
  out.historical = {}
  for _, ch in ipairs(pool(0x10, 0x1C)) do
    out.historical[#out.historical + 1] = char_rec(ch) end
  out.dynamic = {}
  for _, ch in ipairs(pool(0x28, 0x34)) do
    out.dynamic[#out.dynamic + 1] = char_rec(ch) end
  return out
end


-- §1.2 unit-leader CID 注册表导出 reader (gs+1040, count@+1052; idx0 哨兵)
function Runtime.unit_leader_registry(self)
  local g = self.gs()
  local d, cnt = rp(g + 0x410), ru32(g + 0x41C)
  if not (O.kptr(d) and cnt and cnt > 1 and cnt < 100000) then return nil end
  local out = {}
  for i = 1, cnt - 1 do
    local ty = ru32(d + 8 * i)
    local id = ru32(d + 8 * i + 4)
    if ty and ty ~= 0 then out[#out + 1] = { type = ty, id = id } end
  end
  return out
end
