-- objects_military.lua -- 陆军 / 舰队 / 战略空军 / 战斗 (对象层域文件)
-- 结构语义详见书: 陆军 §4.18 CArmy / 海军 §4.16 舰队族 / 空军 §4.15 空军族
-- / 战斗 §4.22 CCombatManager。
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
local officer_record_read, officer_records = SH.officer_record_read, SH.officer_records
local OFFICER_PORTRAIT_BRANCH = SH.OFFICER_PORTRAIT_BRANCH
local OFFICER_PORTRAIT_SIZE = SH.OFFICER_PORTRAIT_SIZE
local cont_elems = SH.cont_elems

-- §6 陆军师族 (§4.18 CArmy; vt0 0x295a2b0 / vt1 0x295a490; writer 0x140BF7010 族)
-- ============================================================
local ARMY2 = { vt0 = BASE + GAME.layout.vt.CArmy_vt0, vt1 = BASE + GAME.layout.vt.CArmy_vt1 }
-- ⚠ legacy _date_from_hours_obj 语义 (objects_legacy L2445-L2463) —
-- 与 U.date 的差别: 默认哨兵 43808760 → "1.1.1.1" (legacy last_combat_date
-- 存档形态), 且 yr<1 照发 "0.x.x.x"; U.date 对两者返 nil → DIVX 缺 1220 行
local function date_from_hours_raw(h)
  -- 唯一实现 = hoi4_layout.date_raw (B 族: u32 回绕 + 滤 {<=0,-1.1.1.1},
  -- 43808760 照发 "1.1.1.1"); legacy last_combat_date 存档形态
  return LAYOUT.date_raw(h)
end

-- officer 记录族 (§4.18.1 CHeldOfficer 持有; 记录 88B 无独立 RTTI;
-- 记录/条目布局与写门 = 书 §4.18 officer 子块表)
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

-- holder 全记录链: inline 记录 (holder+24) 先, 追加向量元素后 (writer 块序)
local function officer_records(inline, vd, vc)
    local out = { officer_record_read(inline) }
    if O.kptr(vd) and vc and vc > 0 and vc <= LAYOUT.lim.PTR_SANE then
        for i = 0, vc - 1 do
            out[#out + 1] = officer_record_read(vd + 88 * i)
        end
    end
    return out
end

local DivMT = {}
local function mk_div(a) return setmetatable({ addr = a }, DivMT) end

-- 6.1 requests 全族 (§4.18.3; q = *(div+1144); 布局/键序/门 = 书 §4.18.3)
-- 记录形态对齐 legacy Objects.divisions "requests"
local function req_fx(v)                -- 值基 ×1e-5 → "%.5f" 串
  if not v then return nil end
  return string.format("%.5f", v * 1e-5)
end
local function req_idpair(p)            -- id 对 (14220B320: type@+8 / id@+12)
  if not O.kptr(p) then return nil end
  local ty, id = ru32(p + 8), ru32(p + 12)
  if not ty or not id then return nil end
  return string.format("id=%d type=%d", id, ty)
end
local function req_date(addr)           -- 0 / 未设哨兵 0x29C3388 → nil
  local h = ru32(addr)
  if not h or h == 0 or h == 0x29C3388 then return nil end
  return U.date(h)
end
-- produced (12204) @P: {d@P+32, c@P+44} 16B {variant 指针@+0, amount i64@+8};
-- allow_zero_entries bool@P+56 (writer 0x140FFDB00); amount≠0 或 az 才写
-- 条目; 有条目或 force 时补 produced.allow_zero_entries 键
local function req_produced(P, out, pfx, force)
  local d, c = rp(P + 32), ru32(P + 44)
  local az = (ru8(P + 56) or 0) ~= 0
  local n = 0
  if O.kptr(d) and c and c > 0 and c < 64 then
    for i = 0, c - 1 do
      local e = d + 16 * i
      local vp, amt = rp(e), rp(e + 8)
      if O.kptr(vp) and amt and (amt ~= 0 or az) then
        n = n + 1
        out[#out + 1] = { pfx .. "produced.equipment." .. n .. ".id",
            req_idpair(vp) }
        out[#out + 1] = { pfx .. "produced.equipment." .. n .. ".amount",
            req_fx(amt) }
      end
    end
  end
  if n > 0 or force then
    out[#out + 1] = { pfx .. "produced.allow_zero_entries",
        az and "yes" or "no" }
  end
end
-- need (12111) @N: {d@N+8, c@N+20} 16B {定义指针@+0, amount i64@+8};
-- 键 = token_name(u32@定义+8); amount≠0 才写
local function req_need(N, out, pfx)
  local d, c = rp(N + 8), ru32(N + 20)
  if not O.kptr(d) or not c or c <= 0 or c >= 64 then return end
  for i = 0, c - 1 do
    local e = d + 16 * i
    local dp, amt = rp(e), rp(e + 8)
    if O.kptr(dp) and amt and amt ~= 0 then
      local tok = ru32(dp + 8)
      if tok then
        out[#out + 1] = { pfx .. "need." .. (LAYOUT.token_name(tok)
            or ("?" .. tostring(tok))), req_fx(amt) }
      end
    end
  end
end
-- 请求元素 (writer 0x1414FE2A0, 序列化基 B) —
-- reinforcement.request[K] / upgrades.delivery[K] 同布局
local function req_element(B, out, pfx)
  local st = ru32(B + 8) or 0
  if st ~= 0 then out[#out + 1] = { pfx .. "status", tostring(st) } end
  if st == 1 then
    local pv = rp(B + 16)
    if pv then out[#out + 1] = { pfx .. "progress", req_fx(pv) } end
  end
  local tp = rp(B + 24)
  if tp and tp ~= 100000 then
    out[#out + 1] = { pfx .. "total_progress", req_fx(tp) }
  end
  -- produced 非空判定 (140FFB8F0): c>0 且存在 amount≠0 才写整块
  local P = B + 32
  local pd, pc = rp(P + 32), ru32(P + 44)
  local prod_any = false
  if O.kptr(pd) and pc and pc > 0 and pc < 64 then
    for i = 0, pc - 1 do
      if (rp(pd + 16 * i + 8) or 0) ~= 0 then prod_any = true break end
    end
  end
  if prod_any then req_produced(P, out, pfx) end
  -- need 非空判定 (140FFB8C0)
  local N = B + 96
  local nd, nc = rp(N + 8), ru32(N + 20)
  local need_any = false
  if O.kptr(nd) and nc and nc > 0 and nc < 64 then
    for i = 0, nc - 1 do
      if (rp(nd + 16 * i + 8) or 0) ~= 0 then need_any = true break end
    end
  end
  if need_any then req_need(N, out, pfx) end
  local dt = req_date(B + 136)
  if dt then out[#out + 1] = { pfx .. "date", dt } end
end

local function req_delivery_element(B, out, pfx)
  local st = ru32(B + 8) or 0
  if st ~= 0 then out[#out + 1] = { pfx .. "status", tostring(st) } end
  if st == 1 then
    local pv = rp(B + 16)
    if pv then out[#out + 1] = { pfx .. "progress", req_fx(pv) } end
  end
  local tp = rp(B + 24)
  if tp and tp ~= 100000 then
    out[#out + 1] = { pfx .. "total_progress", req_fx(tp) }
  end
  req_produced(B + 32, out, pfx, true)
end
DivMT.requests = function(self)
  local q = rp(self.addr + 1144)
  if not O.kptr(q) then return nil end
  -- 三层门 (§4.18.3): 整块门 = 三门任一 ≠0, 全 0 ⇒ 存档无 requests 块
  -- (date 写就残留会保留旧值, 不能反推块存在); 子块门 = reinforcement
  -- g68 / upgrades g172∨g196; date 在块内无条件写
  local g_reinf = (ru32(q + 68) or 0) ~= 0
  local g_upg   = (ru32(q + 172) or 0) ~= 0
  if not (g_reinf or g_upg or (ru32(q + 196) or 0) ~= 0) then return nil end
  local r = {}
  if g_reinf then r.has_reinforcement = true end
  if g_upg then r.has_upgrades = true end
  r.date = req_date(q + 0xE0)
  -- reinforcement 容器 @C = q+40 (writer 0x1414FDF80)
  local out = {}
  if g_reinf then                      -- manpower_pool (13877) {d@C+48, c@C+60}
    local md, mc = rp(q + 88), ru32(q + 100)
    -- ⚠ writer 无条件写每元素 (无零过滤); 键序 = 容器位序 i+1
    if O.kptr(md) and mc and mc > 0 and mc < 64 then
      for i = 0, mc - 1 do
        local e = md + 16 * i
        local tg, vl = ru32(e), rp(e + 8)
        if vl then
          local tag = (tg and self.R:tag(tg)) or tostring(tg)
          out[#out + 1] = { "manpower_pool." .. (i + 1),
              string.format('"%s" %d', tostring(tag),
                  math.floor(vl / 100000)) }
        end
      end
    end
  end
  do                                    -- request (12613) {d@C+16, c@C+28} 指针元素
    local d, c = rp(q + 56), ru32(q + 68)
    if O.kptr(d) and c and c > 0 and c < 64 then
      for i = 0, c - 1 do
        local e = rp(d + 8 * i)
        if O.kptr(e) then
          req_element(e + 0x18, out, "request." .. (i + 1) .. ".")
        end
      end
    end
  end
  r.reinforcement = out
  -- upgrades 容器 @U = q+136 (writer 0x1414FE120)
  out = {}
  do                                    -- request (12613) {d@U+24, c@U+36} 24B 内联
    local d, c = rp(q + 160), ru32(q + 172)
    if O.kptr(d) and c and c > 0 and c < 64 then
      for i = 0, c - 1 do
        local e = d + 24 * i
        local pfx = "request." .. (i + 1) .. "."
        out[#out + 1] = { pfx .. "request", req_fx(rp(e + 8)) }
        out[#out + 1] = { pfx .. "total", req_fx(rp(e + 16)) }
        local vp = rp(e)
        if O.kptr(vp) then
          out[#out + 1] = { pfx .. "equipment_variant_index", req_idpair(vp) }
        end
      end
    end
  end
  do                                    -- delivery (13231) {d@U+48, c@U+60} 指针元素
    local dd, dc = rp(q + 184), ru32(q + 196)
    if O.kptr(dd) and dc and dc > 0 and dc <= LAYOUT.lim.PTR_SANE then
      for i = 0, dc - 1 do
        local e = rp(dd + 8 * i)
        if O.kptr(e) then
          req_delivery_element(e, out, "delivery." .. (i + 1) .. ".")
        end
      end
    end
  end
  r.upgrades = out
  return r
end

-- 6.2 师字段访问器 (DivMT; 全部写出条件已复刻; §4.18.1 CArmy / §4.18.5 CUnit 公共段)
DivMT.__index = function(self, k)
  local a = self.addr
  if not O.kptr(a) then return nil end
  local fxv = U.fix5
  if k == "type" then return ru32(a + 24) end
  if k == "id" then return ru32(a + 28) end
  if k == "template_id" then
    local p = rp(a + 952)
    return O.kptr(p) and ru32(p + 12) or nil
  end
  if k == "old_template_id" then
    local p = rp(a + 960)
    return O.kptr(p) and ru32(p + 12) or nil
  end
  if k == "location" then
    local p = rp(a + 496)
    return O.kptr(p) and ru32(p + 164) or nil
  end
  if k == "previous_location" then
    local p = rp(a + 504)
    return O.kptr(p) and ru32(p + 164) or nil
  end
  if k == "movement_progress" then
    local v = rp(a + 576)                 -- 门 *(a+560) ≠ 0
    return (v and v ~= 0) and v * 1e-5 or nil
  end
  -- ⚠ 勘误: fxv = U.fix5 收地址 (内部 rp); 原写法 fxv(rp(a+X)) 双重
  -- 解引用 → v2 导出 organisation/strength 等为垃圾值 (实证 7.9e13) —
  -- 改传地址 (语义 = legacy fx(rp(a+X)))
  if k == "organisation" then return fxv(a + 1064) end
  if k == "strength" then return fxv(a + 1056) end
  if k == "experience" then return fxv(a + 1072) end
  local cond_fx = function(off, gate)
    local v = rp(a + off)
    if not v then return nil end
    if gate == "pos" then return v > 0 and v * 1e-5 or nil end
    return v ~= 0 and v * 1e-5 or nil
  end
  if k == "str_damage_from_air" then return cond_fx(1088, "pos") end
  if k == "str_damage" then return cond_fx(1096, "pos") end
  if k == "org_damage" then return cond_fx(1104, "pos") end
  if k == "dig_in" then return cond_fx(1112, "pos") end
  if k == "dig_in_cap" then return cond_fx(1120, "pos") end
  if k == "bonus" then return cond_fx(1136, "pos") end
  if k == "max_supply" then return fxv(a + 1536) end
  if k == "supply_gain" then return fxv(a + 1544) end
  if k == "current_supply_ratio" then return fxv(a + 1552) end
  if k == "fuel" then return cond_fx(1568, "nz") end
  if k == "fuel_requested" then return cond_fx(1576, "nz") end
  if k == "out_of_supply_days" then
    local v = ru32(a + 1176)
    return (v and v > 0) and v or nil
  end
  if k == "motorization_level" then return ru32(a + 45) & 0xFF end
  if k == "leader" then
    local v = ru32(a + 1584) & 0xFF
    return (v ~= 0) and v or nil
  end
  if k == "script_id" then
    local v = ru32(a + 1664)
    if v then v = LAYOUT.as_i32(v) end
    return v
  end
  if k == "officer_seed" then return ru32(a + 1304) end
  if k == "seed" then
    local v = ru32(a + 808)
    return (v and v ~= 0) and v or nil
  end
  if k == "support_attack" then
    local p = rp(a + 488)
    return O.kptr(p) and ru32(p + 164) or nil
  end
  if k == "previous" then               -- §4.18.5 CUnit +504 键 0x29A3; kptr 门
    local p = rp(a + 504)
    return O.kptr(p) and ru32(p + 164) or nil
  end
  if k == "move_priority" then          -- 枚举 (值级定案)
    local v = ru32(a + 584)
    if v == 0 then return "front_order" end
    if v == 2 then return "player_order" end
    if v == 3 then return "ai_player_order" end
    return "normal"
  end
  if k == "last_combat_date" then return date_from_hours_raw(ru32(a + 456)) end
  if k == "start_date" or k == "end_date" then
    local off = (k == "start_date") and 328 or 352
    local h = ru32(a + off)
    if not h or h == 0 then return nil end
    h = LAYOUT.as_i32(h)
    if h - 43800000 < 17520 then return nil end   -- 写入门
    return U.date(h)
  end
  local cond_u32 = function(off)
    local v = ru32(a + off)
    return (v and v > 0) and v or nil
  end
  if k == "disengage" then return cond_u32(304) end
  if k == "possible_retreat" then return cond_u32(308) end
  if k == "retreat" then
    return (ru32(a + 588) & 0xFF) == 1 and "yes" or nil
  end
  if k == "withdraw" then
    return (ru32(a + 589) & 0xFF) == 1 and "yes" or nil
  end
  if k == "exile" then
    return (ru32(a + 686) & 0xFF) == 1 and "yes" or nil
  end
  if k == "move_capital" then
    -- 勘误 (§4.18.5 CUnit +688): byte@ser+672 (o+688), writer AE850(0x2B5F=11103
    -- move_capital) — 旧名 exile_capital 系误名 (存档无此键)
    return (ru32(a + 688) & 0xFF) == 1 and "yes" or nil
  end
  if k == "strategic_redeployment" then
    return (ru32(a + 687) & 0xFF) == 1 and "yes" or nil
  end
  if k == "was_paradropped" then return cond_u32(1192) end
  if k == "execute_order" then return cond_u32(1180) end
  if k == "held_officer_xp" then return cond_fx(1408, "nz") end
  if k == "killed" then return cond_u32(1656) end
  if k == "killer_definition" then
    local v = ru32(a + 1660) & 0xFF
    if v == nil then return nil end
    return (v == 1) and "yes" or "no"
  end
  if k == "unit_controller_pause" then return cond_u32(1196) end
  if k == "transfer_offset_1" then return cond_u32(696) end
  if k == "transfer_offset_2" then return cond_u32(700) end
  if k == "expeditionary_owner" then
    -- §4.18.5 CUnit +476: writer 0x140BF7010 (CUnit::serialize, ser=raw+16):
    -- *(int*)(ser+460)>0 才写 0x2EDD (11997); 值 = sub_140BA5C20 →
    -- rp(gs+0x358)+32*tid 名串
    local tid = ru32(a + 476)
    -- 上界 = tag 表 count (非 countryCount; 见 tagUpperBound 注)
    local ub = self.R:tagUpperBound()
    if not tid or tid <= 0 or tid >= ub then return nil end
    return self.R:tag(tid)
  end
  if k == "logical_country" then
    -- §4.18.5 CUnit +480: writer 0x140BF7010: 0x3410 (13328) 无条件写 =
    -- i32 tid@ser+464 (raw+480)。读档孪生 0x140BF35B0 case 13328 走全局 db
    -- (qword_1433189C8) 名→tid, 动态 tag 不在 db → 读档后落 0。
    -- 兜底 = army_manpower 容器 ser+984 (raw a+992/a+1004) 首 tg>0
    local tid = ru32(a + 480)
    -- 上界 = tag 表 count (非 countryCount): a+480 是 **tag id** (不由国家
    -- 数组下标分配), 实测 D06 → a+480=338 而 countryCount=333 — 用
    -- countryCount 当界会把尾部 tag id 判非法 → 整个师的 logical_country
    -- 静默 nil (D06 8 行 MISS_MEM)。tagUpperBound 见其定义注。
    local ub = self.R:tagUpperBound()
    if tid and tid > 0 and tid < ub then
      local s0 = self.R:tag(tid)
      if s0 and s0 ~= "" then return s0 end
    end
    local d, c = rp(a + 992), ru32(a + 1004)
    if O.kptr(d) and c and c > 0 and c < 64 then
      for i3 = 0, c - 1 do
        local tg = ru32(d + 8 * i3)
        if tg and tg > 0 and tg < ub then
          local s0 = self.R:tag(tg)
          if s0 and s0 ~= "" then return s0 end
        end
      end
    end
    return nil
  end
  if k == "unk_19700_fx" then return cond_fx(176, "pos") end
  if k == "fake_intel_template_id" then
    local p = rp(a + 968)
    return O.kptr(p) and ru32(p + 12) or nil
  end
  if k == "raid_instance" then
    local i0, t0 = ru32(a + 816), ru32(a + 812)
    if (not i0 or i0 == 0) and (not t0 or t0 == 0) then return nil end
    return { id = i0, type = t0 }
  end
  if k == "country_intel" then          -- stride 24 → 3 值/元素
    local out = {}
    for _, e in O.vec(a, 632, 644, 24, false) do
      out[#out + 1] = ru32(e) or 0
      out[#out + 1] = ru32(e + 8) or 0
      out[#out + 1] = ru32(e + 16) & 0xFF
    end
    return out
  end
  if k == "commandlist" then
    local out = {}
    for _, p in O.vec(a, 704, 716, 8, true) do
      if O.kptr(p) then
        local tk = ru32(p + 8)
        out[#out + 1] = { token = tk and (tok(tk) or tk) or 0,
            value = fxv(p) }
      end
    end
    return out
  end
  if k == "officer" then                -- writer 键序 seed/male/name
    local r = { seed = ru32(a + 1304) }
    local mb = ru32(a + 1376) & 0xFF
    if mb ~= nil then r.male = (mb == 1) and "yes" or "no" end
    local nm = U.sso(a + 1312)
    if nm and #nm > 0 then r.name = nm end
    return r
  end
  if k == "officer_list" then           -- §4.18.1 CHeldOfficer @a+1272 全记录链
    return officer_records(a + 1296, rp(a + 1384), ru32(a + 1396))
  end
  local function mp_list(base)          -- army_manpower 双容器
    local out = {}
    for _, e in O.vec(base, 8, 20, 8, false) do
      local tg, vl = ru32(e), ru32(e + 4)
      if vl and vl > 0 then
        local tag = (tg and self.R:tag(tg)) or tostring(tg)
        out[#out + 1] = tag .. "|" .. vl
      end
    end
    return out
  end
  if k == "manpower_value" then return mp_list(a + 984) end
  if k == "manpower_need" then return mp_list(a + 1016) end
  if k == "path" or k == "full_path" then
    -- ⚠ 勘误: 发射端 (secA=legacy 同源) 读 dv.path / dv.full_path,
    -- v2 原键名 path/full_path → path/full_path 全缺 (204+1 行)。
    -- 布局同 legacy L2972-L2987 (§4.18.5 CUnit +512/+544): 容器 {data@+0, cnt@+12} (writer 0x1401B3870);
    -- path 对象 @a+512, full_path @a+544 (guard *(a+556))
    local base = (k == "path") and (a + 512) or (a + 544)
    if k == "full_path" and not (ru32(a + 556) and ru32(a + 556) ~= 0) then
      return nil
    end
    local d, c = rp(base), ru32(base + 12)
    local out = {}
    if O.kptr(d) and c and c > 0 and c < 4096 then
      for i2 = 0, c - 1 do out[#out + 1] = ru32(d + 4 * i2) or 0 end
    end
    return out
  end
  -- ===== 补齐 (legacy 导出消费字段; 偏移抄 objects_legacy 定案) =====
  if k == "move_priority_raw" then      -- move_priority 枚举 raw @a+584
    return ru32(a + 584)                --   (export 写门: raw ~= 1 才发 move_priority)
  end
  if k == "equip_allow_zero" then       -- DIVAZ (§4.18.1 +840 池): allow_zero_entries
    -- (池内嵌 @a+840, 产池同布局; bool@池+56 = a+896; resave 实证
    -- mem↔save 值保留) ⚠ export 侧 `az and 1 or 0`: 必须 true/false 布尔
    local v = ru8(a + 896)              --   (数字 0 在 Lua 为真值, 会错导成 1)
    if v and v ~= 0 then return true end
    return false
  end
  if k == "equipment" then              -- DIVEQ (§4.18.1): 装备池内嵌 @a+840 (产池同
    local pool = a + 840                --   布局 {d@+32, c@+44} 16B 条目
    local data, cnt = rp(pool + 0x20), ru32(pool + 0x2C)
    local t = {}
    if O.kptr(data) and cnt and cnt > 0 and cnt <= LAYOUT.lim.PTR_SANE then
      for i = 0, cnt - 1 do
        local p, amt = rp(data + 16 * i), rp(data + 16 * i + 8)
        if O.kptr(p) then
          t[#t + 1] = { variant_id = ru32(p + 0xC),
              key_token = ru32(p + 0x18),
              amount = amt and amt * 1e-5 or 0 }
        end
      end
    end
    return t
  end
  if k == "division_name" then          -- 内嵌 @a+832 (§4.18.1; writer 0x1409BCC70):
    local n = rp(a + 832)               --   name 对象 type@+8 / name_order@+128 /
    if not O.kptr(n) then return nil end --  override 串@+136 / osp b@+169
    local r = { type = ru32(n + 8) }
    local no = ru32(n + 128)
    if no and no ~= 0 then r.name_order = no end
    -- is_name_ordered (14562) 另有类切换/门控未解 (legacy) — 不导出
    local ov = U.sso(n + 136)
    if ov and #ov > 0 then r.override = ov end
    local pb = ru8(n + 169)
    if pb and pb ~= 0 then r.override_set_programmatically = "yes" end
    return r
  end
  if k == "acclimatization" then        -- 内嵌 @a+1208 (§4.18.1; writer 0x140609C70;
    local c = a + 1208                  --   量纲 ×1e-5: cold raw 402336000 ↔
    local r = {}                        --   存档 4023.36; max ≠1e7 才写)
    local d, cnt = rp(c + 8), ru32(c + 20)
    local has_pos = false
    if O.kptr(d) and cnt and cnt > 0 and cnt < 16 then
      for i = 0, cnt - 1 do
        local e = d + 16 * i
        local obj, val = rp(e), rp(e + 8)
        if O.kptr(obj) and val and val ~= 0 then
          local tok = ru32(obj + 32)
          r[LAYOUT.token_name(tok) or ("?" .. tostring(tok))] = val * 1e-5
          if val > 0 then has_pos = true end
        end
      end
    end
    -- 块门 sub_140608080(c): 取最大 val 的元素地址, 最大值 <= 0 (或无可
    -- 读元素) 时返回 0 → 整块不写 (§4.18.1 +1208 写门)。
    if not has_pos then return nil end
    -- actively_gaining: 串对象指针 (writer ADF40(0x386E, *(a1+32)))
    local agp = rp(c + 32)
    local ag = O.kptr(agp) and U.sso(agp) or nil
    if ag and #ag > 0 then r.actively_gaining = ag end
    local sp = rp(c + 40)
    if sp and sp ~= 0 then r.actively_gaining_speed = sp * 1e-5 end
    local ol = rp(c + 48)
    if ol and ol ~= 0 then r.other_loss = ol * 1e-5 end
    local mx = rp(c + 56)
    if mx and mx ~= 10000000 then r.max_acclimatization = mx * 1e-5 end
    return r
  end
  if k == "army_history" then           -- 内嵌 @a+1592 (§4.18.1 army_history; writer 0x14143AC00);
    local h0 = a + 1592                 --   队列 {d@+40, c@+52} 指针元素
    local d, cnt = rp(h0 + 40), ru32(h0 + 52)
    local lst = {}
    if O.kptr(d) and cnt and cnt > 0 and cnt < 4096 then
      for i = 0, cnt - 1 do
        local e = rp(d + 8 * i)
        if O.kptr(e) then
          local rec = {}
          local an = U.sso(e + 8)
          if an and #an > 0 then rec.army_names = an end
          -- target_country: e+76 tag 经串表反查
          local tid = ru32(e + 76)
          if tid and tid > 0 and tid < 100000 then
            rec.target_country = self.R:tag(tid)
          end
          -- CGameDate: hours i32 @e+88 (探针 0x39F37A2 → 1936.10.9.11)
          rec.date = date_from_hours_raw(ru32(e + 88))
          rec.unique = ru32(e + 72)
          rec.medal_count = (ru8(e + 112) == 1) and "yes" or "no"
          rec.inherit = (ru8(e + 113) == 1) and "yes" or "no"
          local mult = rp(e + 312)
          if mult and mult ~= 100000 then rec.multiplier = mult * 1e-5 end
          local om = ru32(e + 320)
          if om and om ~= 0 then rec.orders = om end
          -- location 容器 @e+0x120 {data, c@+0x128}, 元素 8B 省指针
          -- (省 id @ptr+164)
          local lcd, lcc = rp(e + 0x120), ru32(e + 0x128)
          if O.kptr(lcd) and lcc and lcc > 0 and lcc < 64 then
            local locs = {}
            for k2 = 0, lcc - 1 do
              local lp2 = rp(lcd + 8 * k2)
              local lid = O.kptr(lp2) and ru32(lp2 + 164) or nil
              if lid then locs[#locs + 1] = lid end
            end
            if #locs > 0 then rec.location = table.concat(locs, " ") end
          end
          lst[#lst + 1] = rec
        end
      end
    end
    return { list = lst, count = #lst }
  end
  if k == "requests" then return DivMT.requests(self) end
  return nil
end

-- 6.2a 师构造器公开 (上提): 段侧任意师地址 → DivMT 包装 (§4.18.1 CArmy),
-- 取代 volunteers/exile 的 DivMT 元表跨国借用 (流亡国 114 叶事故)
function Runtime.division_at(self, a)
  if not O.kptr(a) then return nil end
  local px = mk_div(a)
  px.R = self
  return px
end

-- id 对 → 师对象 (§4.18.1; idreg 解析 + this 调整: 库存指针 = raw+16 vt1,
-- raw = res-16; vt0/vt1 双校验后 mk_div) — volunteers/exile/raids
-- unit.army 共用
function Runtime.unit_division(self, ty, id)
  local res = LAYOUT.idreg_unit_resolve(ty, id)
  if not res then return nil end
  if rp(res) == ARMY2.vt1 and rp(res - 16) == ARMY2.vt0 then
    return Runtime.division_at(self, res - 16)
  end
  return nil
end

-- 6.3 divisions 入口 (§1.2 gs+784/796 国家数组; §4.3.1 cc+656 师容器 /
-- cc+632 舰队 / cc+680 铁路炮)
function Runtime.divisions(self, country_idx)
  local g = self.gs()
  if not g then return nil end
  local cdata, ccount = rp(g + 0x310), ru32(g + 0x31C)
  if not O.kptr(cdata) or not ccount or (country_idx or 0) >= ccount then
    return nil
  end
  local cc = rp(cdata + 8 * (country_idx or 0))
  if not O.kptr(cc) then return nil end
  local data, cnt = rp(cc + 656), ru32(cc + 668)
  local list, by_id = {}, {}
  if O.kptr(data) and cnt and cnt > 0 and cnt < 100000 then
    for i = 0, cnt - 1 do
      local d = rp(data + 8 * i)
      if O.kptr(d) and rp(d) == ARMY2.vt0 and rp(d + 16) == ARMY2.vt1 then
        local px = mk_div(d)
        px.R = self
        list[#list + 1] = px
        local id = ru32(d + 28)
        if id then by_id[id] = px end
      end
    end
  end
  local fl, fln = rp(cc + 632), ru32(cc + 644)
  return { addr = cc + 656, count = cnt, list = list, by_id = by_id,
    fleets = (O.kptr(fl) and fln) and fln or 0,
    railway_guns = (function()
      local rg, rgn = rp(cc + 680), ru32(cc + 692)
      return (O.kptr(rg) and rgn) and rgn or 0
    end)() }
end



-- ============================================================
-- §7 舰队族 (§4.16 CFleet @cc+632 容器 → CTaskForce → CShip)
-- ============================================================
-- 7.1 CFleet (§4.16.4; 字段布局/写门 = 书 §4.16.4)
local function fleet_color(bits)          -- IEEE754 位型 → ×255 取整
  if not bits or bits == 0 then return 0 end
  local e = math.floor(bits / 2 ^ 23) % 256
  local m = bits % 2 ^ 23
  local v
  if e == 0 then v = m / 2 ^ 23 * 2 ^ -126
  else v = (1 + m / 2 ^ 23) * 2 ^ (e - 127) end
  -- 引擎 CColor writer 0x142237AD0 = (int)(float)(v*255.0) 截断, 非四舍五入
  -- (theatres §7 已裁决该分歧; theatres 段已按截断, fleet 是唯一离群点)
  return math.floor(v * 255)
end
local function a3d0(p)                    -- id 对首 u32 (0/16 = 不写门)
  local t0 = ru32(p)
  if t0 and t0 ~= 0 and t0 ~= 16 then return t0 end
  return 16
end
local MP_NAMES = { [0] = "front_order", [2] = "player_order",
  [3] = "ai_player_order" }
local DA_NAMES = { [1] = "repairing", [2] = "moving_to_refit",
  [3] = "refitting", [4] = "reinforcing" }

function Runtime.fleet(self, country_idx)
  local cc = self:country(country_idx)
  if not cc then return { count = 0, fleets = {} } end
  local fd, fc = rp(cc.addr + 632), ru32(cc.addr + 644)
  local out = { count = fc or 0, fleets = {} }
  -- 舰队数无 64 界 (RF 日本 100 单船舰队实证; 原版帽整树清空) — 防御界 PTR_SANE
  if not O.kptr(fd) or not fc or fc <= 0 or fc > LAYOUT.lim.PTR_SANE then return out end
  for i = 0, fc - 1 do
    local fl = rp(fd + 8 * i)
    if O.kptr(fl) then
      local frec = { _addr = fl, task_forces = {} }
      -- name: 自研串 {ptr@+224, size@+240}, 全堆形态 (含 UTF-8 中文);
      -- cstr 优先, MSVC/内联双兜底
      local np = rp(fl + 224)
      if O.kptr(np) then
        local s = U.cstr(np)
        if s and #s > 0 then frec.name = s end
      end
      if not frec.name then
        frec.name = U.sso(fl + 224) or U.cstr(fl + 224)
      end
      frec.icon = ru32(fl + 256)
      frec.fleet_type = ru32(fl + 8)
      frec.fleet_id = ru32(fl + 12)
      frec.fleet_icon = ru32(fl + 256)
      frec.color = string.format("%d %d %d",
          fleet_color(ru32(fl + 288) or 0),
          fleet_color(ru32(fl + 292) or 0),
          fleet_color(ru32(fl + 296) or 0))
      local hbp = rp(fl + 216)
      if O.kptr(hbp) then frec.home_base = ru32(hbp + 164) end
      frec.automated = (ru32(fl + 260) & 0xFF) == 1 and "yes" or "no"
      if ru32(fl + 176) ~= 0 or ru32(fl + 180) ~= 0 then
        frec.leader = string.format("id=%d type=%d",
            ru32(fl + 180) or 0, ru32(fl + 176) or 0)
      end
      local tick = ru32(fl + 136)
      if tick and tick ~= 0 then frec.tick_nis = tick end
      frec.bombardment = {}
      for _, be in O.vec(fl, 144, 156, 16, false) do
        local bp = rp(be)
        frec.bombardment[#frec.bombardment + 1] = {
          region = O.kptr(bp) and ru32(bp + 88) or -1,
          value = ru32(be + 8) or 0 }
      end
      frec.strategic_regions = {}
      for _, sp in O.vec(fl, 72, 84, 8, true) do
        frec.strategic_regions[#frec.strategic_regions + 1] =
            tostring(ru32(sp + 88) or 0)
      end
      -- task forces (§4.16.2 CTaskForce)
      for _, tf in O.vec(fl, 184, 196, 8, true) do
        if O.kptr(tf) then
          local trec = { _addr = tf,
            id = ru32(tf + 28), type = ru32(tf + 24),
            repair_mode = ru32(tf + 1124),
            sortie_efficiency = ru32(tf + 1260),
            underway_replenishment = ru32(tf + 1128) & 0xFF,
            name = U.sso(tf + 600),
            icon = ru32(tf + 1288),
            use_fleet_color = (ru32(tf + 1292) & 0xFF) == 1
                and "yes" or "no",
            ships = {} }
          -- tf 级残余 (§4.16.2; writer 0x140D66770, lua=raw+16)
          trec.naval_hqs = {}
          for _, el in O.vec(tf, 1832, 1844, 8, true) do
            trec.naval_hqs[#trec.naval_hqs + 1] = string.format(
                "id=%d type=%d", ru32(el + 12) or 0, ru32(el + 8) or 0)
          end
          if a3d0(tf + 1200) ~= 16 then
            trec.repair_parent = string.format("id=%d type=%d",
                ru32(tf + 1204) or 0, ru32(tf + 1200) or 0)
          end
          trec.repair_children = {}
          for _, el in O.vec(tf, 1176, 1188, 8, false) do
            trec.repair_children[#trec.repair_children + 1] =
                string.format("id=%d type=%d",
                    ru32(el + 4) or 0, ru32(el) or 0)
          end
          if (ru32(tf + 1268) & 0xFF) ~= 0 then trec.repair_split = true end
          local rtp = rp(tf + 1216)
          if O.kptr(rtp) then trec.repair_target = ru32(rtp + 164) or 0 end
          local dan = DA_NAMES[ru32(tf + 1208)]
          if dan then trec.detached_activity = dan end
          local rvq = rp(tf + 1224)
          if O.kptr(rvq) then
            trec.refit_variant = string.format("id=%d type=%d",
                ru32(rvq + 12) or 0, ru32(rvq + 8) or 0)
          end
          local rv2q = rp(tf + 1232)
          if O.kptr(rv2q) then
            trec.refit_after_repair = string.format("id=%d type=%d",
                ru32(rv2q + 12) or 0, ru32(rv2q + 8) or 0)
          end
          if (ru32(tf + 1270) & 0xFF) == 1 then trec.is_sea_locked = "yes" end
          -- CUnit 基类字段 (§4.18.5; writer 0x140BF7010, lua=raw+16)
          local locp = rp(tf + 496)
          if O.kptr(locp) then trec.location = ru32(locp + 164) or -1 end
          local prvp = rp(tf + 504)
          if O.kptr(prvp) then trec.previous = ru32(prvp + 164) or -1 end
          local lctid = ru32(tf + 480)
          if lctid and lctid ~= 0 and lctid < 100000 then
            local s56 = self:tag(lctid)
            if s56 and s56 ~= "" then trec.logical_country = s56 end
          end
          local mp56 = rp(tf + 576) or 0
          if mp56 ~= 0 then trec.movement_progress = mp56 * 1e-5 end
          local mprio = ru32(tf + 584)
          if mprio and mprio ~= 1 then
            trec.move_priority = MP_NAMES[mprio] or ("mp_" .. tostring(mprio))
          end
          trec.auto_reinforcement = ru32(tf + 1271) & 0xFF
          local fv56 = rp(tf + 1272) or 0
          if fv56 ~= 0 then trec.fuel = fv56 * 1e-5 end
          local rv56 = rp(tf + 1280) or 0
          if rv56 ~= 0 then trec.requested = rv56 * 1e-5 end
          -- path @tf+512 (0x374 键) u32 省序
          do
            local pd, pc = rp(tf + 512), ru32(tf + 524) or 0
            if O.kptr(pd) and pc > 0 and pc < 512 then
              local pp = {}
              for q2 = 0, pc - 1 do
                pp[#pp + 1] = tostring(ru32(pd + 4 * q2) or 0)
              end
              trec.path = table.concat(pp, " ")
            end
          end
          -- CNavalMission (§4.16.12; writer 0x140FA9900; 内嵌@tf+864)
          local ms = tf + 864
          local mrec = { mission = ru32(ms + 20) }
          local mv24 = ru32(ms + 24)
          if mv24 and mv24 ~= 0 then mrec.move = mv24 end
          if (ru32(ms + 48) & 0xFF) == 1 then mrec.is_in_regions = "yes" end
          local mrad = rp(ms + 32) or 0
          if mrad > 0 then mrec.radar = mrad * 1e-5 end
          local mas = rp(ms + 40) or 0
          if mas > 0 then mrec.air_superiority = mas * 1e-5 end
          local mh = ru32(ms + 56)
          if mh and mh > 0 then mrec.hours = mh end
          local mhim = ru32(ms + 60)
          if mhim and mhim > 0 then mrec.hours_in_mission = mhim end
          local mnc = ru32(ms + 64)
          if mnc and mnc > 0 then mrec.num_convoys_in_regions = mnc end
          mrec.navy_engagement_rule = ru32(ms + 52)
          local msr = rp(ms + 112)
          if O.kptr(msr) then mrec.spotting_region = ru32(msr + 88) end
          local mhsr = ru32(ms + 108)
          if mhsr and mhsr > 0 then
            mrec.hours_in_spotting_region = mhsr end
          local mcsr = rp(ms + 232)
          if O.kptr(mcsr) then mrec.convoy_spotting_region = ru32(mcsr + 88) end
          if (ru32(ms + 69) & 0xFF) == 1 then
            mrec.stop_training_at_max_xp = "yes" end
          mrec.accessible_regions_range =
              (rp(ms + 168) or 0) * 1e-5
          do                                    -- accessible_regions_in_fleet
            local afd, afc = rp(ms + 176), ru32(ms + 188) or 0
            if O.kptr(afd) and afc > 0 and afc < 4096 then
              local afl = {}
              for q2 = 0, afc - 1 do
                afl[#afl + 1] = (ru32(afd + q2) & 0xFF) == 1
                    and "yes" or "no"
              end
              mrec.accessible_regions_in_fleet = table.concat(afl, " ")
            end
          end
          do                                    -- accessible_regions 指针数组
            local arl = {}
            for _, e in O.vec(ms, 200, 212, 8, true) do
              arl[#arl + 1] = tostring(ru32(e + 88) or 0)
            end
            if #arl > 0 then
              mrec.accessible_regions = table.concat(arl, " ")
            end
          end
          do                                    -- group_to_escort 内嵌@ms+72
            local gte_id = ru32(ms + 84)
            if gte_id and gte_id ~= 0 then
              mrec.gte_orders_group = string.format("id=%d type=%d",
                  gte_id, ru32(ms + 80) or 0)
              mrec.gte_instance_id = ru32(ms + 88) or 0
            end
          end
          trec.mission = mrec
          -- ai_taskforce_composition (§4.16.2 CTaskForceCompositionRequirements; 内嵌@tf+1328)
          -- ⚠ 拼串须 table.concat (legacy L9827) — 追加 '….. ' 形态
          -- 会在每行尾部多一个空格
          local aic = tf + 1328
          local acrec = {}
          local function aic56(base, name)
            local dd, cc = rp(base + 8), ru32(base + 20) or 0
            if O.kptr(dd) and cc > 0 and cc < 256 then
              local su, ro, am = {}, {}, {}
              for q = 0, cc - 1 do
                local e = dd + 16 * q
                su[#su + 1] = tostring(ru32(e) or 0)
                ro[#ro + 1] = tostring(ru32(e + 4) or 0)
                am[#am + 1] = tostring(ru32(e + 12) or 0)
              end
              acrec[name .. '.sub_units'] = table.concat(su, " ")
              acrec[name .. '.roles'] = table.concat(ro, " ")
              acrec[name .. '.amount'] = table.concat(am, " ")
            end
          end
          aic56(aic + 8, 'requirements')
          aic56(aic + 112, 'fulfillment')
          local aicn = ru32(aic + 216)
          if aicn and aicn ~= 19479 then acrec.name = LAYOUT.token_name(aicn) end
          trec.ai_comp = acrec
          local tfh = ru32(tf + 456)
          if tfh and tfh ~= 0 then
            if tfh == 43808760 then
              trec.last_combat_date = "1.1.1.1"
            else
              trec.last_combat_date = U.date(tfh)
            end
          end
          -- previous (§4.18.5 CUnit +504 / 键 0x29A3, kptr 门): 锚件
          -- units.fleet.task_force.previous 实证, 旧注"tf 不写"是错的
          do
            local pvp = rp(tf + 504)
            if O.kptr(pvp) then trec.previous = ru32(pvp + 164) end
          end
          -- CShip (§4.16.3; writer 0x140C2EF80): ships {d@840, c@852}
          for _, sh in O.vec(tf, 840, 852, 8, true) do
            if O.kptr(sh) then
              local srec = {
                id = ru32(sh + 12), type = ru32(sh + 8),
                strength = U.fix5(sh + 1784),
                organisation = U.fix5(sh + 1792),
                definition = LAYOUT.token_name(ru32(sh + 136)),
                manpower = ru32(sh + 2056), max_manpower = ru32(sh + 2060) }
              local ev = U.fix5(sh + 1800)
              srec.experience = (ev and ev ~= 0) and ev or nil
              srec.officer_seed = ru32(sh + 2152)
              local scc = ru32(sh + 60)
              if scc and scc > 0 then srec.sunk_convoys = scc end
              -- male b@SOD+80 (SOD@sh+2144 → ho+0x68; §4.16.3 CHeldOfficer; writer
              -- 0x1413D5A50 AE850 无条件写); 旧 ho+0x10 是 CHeldOfficer
              -- ctor 恒 1 的标志位 (seed@+0x20 / name@+0x28 不变)
              local ho2 = sh + 2120
              local maleb = ru32(ho2 + 0x68) & 0xFF
              if maleb then
                srec.officer_male = (maleb == 1) and "yes" or "no"
              end
              local nmsz = ru32(ho2 + 0x38)
              if nmsz and nmsz > 0 then
                local nmp = (nmsz > 15) and rp(ho2 + 0x28) or (ho2 + 0x28)
                -- ⚠ 裸 char 缓冲必须 hoi4.read_cstr (legacy L9939);
                -- U.cstr=hoi4.read_str 智能 reader 对裸堆串行为不符
                if O.kptr(nmp) then srec.officer_name = hoi4.read_cstr(nmp) end
              end
              local preg = rp(ho2 + 0x50)
              if O.kptr(preg) then
                local function msvc_at(o)
                  local szz = ru32(preg + o + 0x10)
                  if not szz or szz == 0 then return nil end
                  local pp2 = (szz > 15) and rp(preg + o) or (preg + o)
                  return O.kptr(pp2) and hoi4.read_cstr(pp2) or nil
                end
                local ps1, ps2 = msvc_at(0x10), msvc_at(0x48)
                srec.officer_portraits = {}
                if ps1 then srec.officer_portraits[#srec.officer_portraits + 1] =
                    { ptype = "navy", size = "0", path = ps1 } end
                if ps2 then srec.officer_portraits[#srec.officer_portraits + 1] =
                    { ptype = "navy", size = "1", path = ps2 } end
              end
              -- officer 全记录链 (§4.16.3 CHeldOfficer @sh+2120): inline@+2144 +
              -- 追加向量 {data@+2232, count@+2244}, 记录 88B
              srec.officer_list = officer_records(sh + 2144, rp(sh + 2232),
                  ru32(sh + 2244))
              local rft0 = ru32(sh + 1848)
              if (rft0 ~= 0 and rft0 ~= 16) or ru32(sh + 1852) ~= 0 then
                srec.refit_line = string.format("id=%d type=%d",
                    ru32(sh + 1852) or 0, rft0 or 0)
              end
              local sn = rp(sh + 2072)
              if O.kptr(sn) then
                srec.ship_name_type = ru32(sn + 8)
                local snep = rp(sn + 80)
                if O.kptr(snep) then
                  srec.ship_name_equipment = string.format("id=%d type=%d",
                      ru32(snep + 12) or 0, ru32(snep + 8) or 0)
                end
                local no = ru32(sn + 128)
                if no and no ~= 0 then srec.ship_name_order = no end
                if (ru32(sn + 169) & 0xFF) ~= 0 then
                  srec.ship_name_osp = "yes" end
                local ino_b = ru32(sn + 168) & 0xFF
                if ino_b == 0 then srec.ship_name_ino = "no" end
                local ov = U.sso(sn + 136)
                if ov and #ov > 0 then srec.ship_name_override = ov end
              end
              do                                -- equipment 池 内嵌@sh+64 (§4.16.3)
                local eqp = sh + 64
                local eqd, eqc = rp(eqp + 32), ru32(eqp + 44) or 0
                if O.kptr(eqd) and eqc > 0 and eqc < 65536 then
                  srec.equipment = {}
                  for q2 = 0, eqc - 1 do
                    local evq = rp(eqd + 16 * q2)
                    local amt = rp(eqd + 16 * q2 + 8) or 0
                    local has = O.kptr(evq)
                    if has or (ru32(eqp + 56) & 0xFF) == 1 then
                      srec.equipment[#srec.equipment + 1] = {
                        id = has and ru32(evq + 12) or nil,
                        tp = has and ru32(evq + 8) or nil,
                        amount = math.floor(amt / 10000) / 10 }
                    end
                  end
                  srec.equip_az = (ru32(eqp + 56) & 0xFF) == 1
                end
              end
              local hoxp = rp(sh + 2256) or 0   -- held_officer.experience (§4.16.3)
              if hoxp > 0 then srec.officer_xp = hoxp * 1e-5 end
              do                                -- history (§4.16.3 CShip.history; 容器@sh+2304/2316)
                local hd, hc = rp(sh + 2304), ru32(sh + 2316)
                if O.kptr(hd) and hc and hc > 0 and hc < 4096 then
                  srec.history = {}
                  for hi = 0, hc - 1 do
                    local e = rp(hd + 8 * hi)
                    if O.kptr(e) then
                      local hr = {}
                      local an = U.sso(e + 8)
                      if an and #an > 0 then hr.army_names = an end
                      local tid = ru32(e + 76)
                      if tid and tid > 0 and tid < 100000 then
                        hr.target_country = self:tag(tid)
                      end
                      hr.date = date_from_hours_raw(ru32(e + 88))
                      hr.unique = ru32(e + 72)
                      hr.medal_count = (ru32(e + 112) & 0xFF) == 1
                          and "yes" or "no"
                      hr.inherit = (ru32(e + 113) & 0xFF) == 1
                          and "yes" or "no"
                      do                        -- CSunkShipInfo (§4.16.13) 内嵌@entry+120
                        local b0 = 120
                        local su = {}
                        local nm2 = U.sso(e + b0 + 8)
                        if nm2 and #nm2 > 0 then su.name = nm2 end
                        local kn2 = U.sso(e + b0 + 40)
                        if kn2 and #kn2 > 0 then su.killer_name = kn2 end
                        local ct2 = ru32(e + b0 + 72)
                        if ct2 and ct2 > 0 then su.country = self:tag(ct2) end
                        local kc2 = ru32(e + b0 + 76)
                        if kc2 and kc2 > 0 then
                          su.killer_country = self:tag(kc2) end
                        su.level = ru32(e + b0 + 120) or 0
                        local dfd = rp(e + b0 + 104)
                        if O.kptr(dfd) then
                          su.definition =
                              LAYOUT.token_name(ru32(dfd + 8) or 0) end
                        local kdd = rp(e + b0 + 112)
                        if O.kptr(kdd) then
                          su.killer_definition =
                              LAYOUT.token_name(ru32(kdd + 8) or 0) end
                        local lcd3 = rp(e + b0 + 144)
                        if O.kptr(lcd3) then su.location = ru32(lcd3 + 164) or 0 end
                        su.date = date_from_hours_raw(ru32(e + b0 + 88))
                        if (ru32(e + b0 + 161) & 0xFF) == 1 then
                          su.assist = "yes" end
                        local evt, evi = ru32(e + b0 + 124), ru32(e + b0 + 128)
                        if (evt and evt ~= 0) or (evi and evi ~= 0) then
                          su.eq_variant = string.format("id=%d type=%d",
                              evi or 0, evt or 0) end
                        su.air_wing = string.format("id=%d type=%d",
                            ru32(e + b0 + 136) or 0,
                            ru32(e + b0 + 132) or 0)
                        local btt, bti = ru32(e + b0 + 152),
                            ru32(e + b0 + 156)
                        if (btt and btt ~= 0) or (bti and bti ~= 0) then
                          su.battle = string.format("id=%d type=%d",
                              bti or 0, btt or 0) end
                        su.convoy = (ru32(e + b0 + 160) & 0xFF) == 1
                            and "yes" or "no"
                        if (su.name and #su.name > 0)
                            or (su.level or 0) > 0 then
                          hr.sunk = su
                        end
                      end
                      srec.history[#srec.history + 1] = hr
                    end
                  end
                end
              end
              trec.ships[#trec.ships + 1] = srec
            end
          end
          frec.task_forces[#frec.task_forces + 1] = trec
        end
      end
      out.fleets[#out.fleets + 1] = frec
    end
  end
  return out
end



-- ============================================================
-- §13 战略空军族 (§4.15; mgr gs+0x690 vtable 0x29588f8; 池 0x297ae38;
-- 国条 0x29587d8; 基地 0x2958780; CAirWing 校验 type==69)
-- ============================================================
local SA2 = { mgr = GAME.layout.vt.CStrategicAirMgr,
  sa_country = GAME.layout.vt.CStrategicAirCountry,
  pool = GAME.layout.vt.CAirWingPool, airbase = GAME.layout.vt.CAirBase }
local Wing2MT, Pool2MT, Base2MT, SAC2MT = {}, {}, {}, {}
local function mk_w2(a) return setmetatable({ addr = a, R = Runtime }, Wing2MT) end
local function wing_of_holder2(h)      -- wing = holder + 16
  if not O.kptr(h) then return nil end
  local w = h + 16
  return (ru32(w + 8) == 69) and mk_w2(w) or nil
end
local function cont_elems(base, off, vtrva)
  local out = {}
  local d, c = rp(base + off), ru32(base + off + 12)
  if O.kptr(d) and c and c > 0 and c < 65536 then
    for i = 0, c - 1 do
      local e = rp(d + 8 * i)
      if O.kptr(e) and rp(e) == BASE + vtrva then out[#out + 1] = e end
    end
  end
  return out
end

-- 13.1 CAirWing 字段访问器 (§4.15.4)
Wing2MT.__index = function(self, k)
  local a = self.addr
  if not a or ru32(a + 8) ~= 69 then return nil end
  if k == "addr" then return a end
  if k == "id" then return ru32(a + 0xC) end
  if k == "priority" then return ru32(a + 0x18) end
  if k == "allow_mission_type" then return ru32(a + 0x1C) end
  if k == "transfer_progress" then return (rp(a + 0x40) or 0) / 1e5 end
  if k == "transfer_cancelled" then return ru32(a + 0x68) & 0xFF end
  if k == "count" then return ru32(a + 0x6C) end
  if k == "manpower" then return ru32(a + 0x70) end
  if k == "air_accidents" then return ru32(a + 0x74) end
  if k == "experience" then return (rp(a + 0x208) or 0) / 1e5 end
  if k == "name" then return U.cstr(a + 0x988) end
  if k == "wtag" or k == "tag_id" then
    local tid = ru32(a + 0x9B4)
    if not tid or tid == 0 then return nil end
    if k == "tag_id" then return tid end
    return self.R:tag(tid)
  end
  if k == "weq_az" then return (ru32(a + 0x200) & 0xFF) == 1 and 1 or 0 end
  if k == "reinforcement_setting" then return ru32(a + 0x9BC) & 0xFF end
  if k == "air_untrained_pilots_penalty_factor" then
    return (rp(a + 0xA00) or 0) / 1e5 end
  if k == "suspended_missions" then return ru32(a + 0x1A8) end
  -- other_combats: d=*(+432) 后 id 对**直接内联**在 d (8B: type@0, id@4)
  if k == "other_combats" then
    local d, n = rp(a + 432), ru32(a + 444)
    if not O.kptr(d) or not n or n <= 0 or n > 256 then return {} end
    local t = {}
    for i = 0, n - 1 do
      t[#t + 1] = string.format("id=%d type=%d",
          ru32(d + 4 + 8 * i) or 0, ru32(d + 8 * i) or 0)
    end
    return t
  end
  if k == "government_in_exile_tag" then
    local n = ru32(a + 2488)
    if not n or n <= 0 then return nil end
    return self.R:tag(n) or tostring(n)
  end
  if k == "raid_instance" then          -- id 对: id@+2592, type@+2588
    local i0, t0 = ru32(a + 2592), ru32(a + 2588)
    if (not i0 or i0 == 0) and (not t0 or t0 == 0) then return nil end
    return string.format("id=%d type=%d", i0 or 0, t0 or 0)
  end
  if k == "timed_disabling" then
    local td = rp(a + 0xA10)
    if not O.kptr(td) then return nil end
    return { remaining_hours = ru32(td + 4),
      should_start_on_transfer = ru32(td + 8) & 0xFF }
  end
  if k == "equipment" then              -- {d@+0x1E8, cnt@+0x1F4} 16B
    local d, n = rp(a + 0x1E8), ru32(a + 0x1F4)
    if not O.kptr(d) or not n or n > 100 then return nil end
    local out = {}
    for i = 0, n - 1 do
      local e = d + 16 * i
      local vp, amt = rp(e), rp(e + 8)
      out[#out + 1] = { variant_id = O.kptr(vp) and ru32(vp + 0xC) or nil,
        variant_type = O.kptr(vp) and ru32(vp + 8) or 0,
        amount = (amt or 0) / 1e5 }
    end
    return out
  end
  if k == "mission" then                -- CAirMission (§4.15.5) 内嵌@+0x80
    local m = a + 0x80
    local rp48 = rp(m + 48)
    local r = { addr = m, type = ru32(m + 0x10),
      -- period = int8@+24 (writer 0x140F726A0 截断写)
      period = (function()
        local b = ru32(m + 0x18) & 0xFF
        if b >= 128 then b = b - 256 end
        return b
      end)(),
      active = ru32(m + 0x20),
      missions_done = ru32(m + 0x74),
      effectiveness = (rp(m + 0xD8) or 0) / 1e5,
      effective_planes_count = ru32(m + 0xE0),
      effective_air_superiority = (rp(m + 0xE8) or 0) / 1e5,
      strategic_region = O.kptr(rp48) and ru32(rp48 + 88) or nil }
    local rcp = rp(m + 0xC0)
    if rcp then r.region_change_penalty = rcp / 1e5 end
    -- ⚠ 勘误: legacy 位集判 ~=0 (L668), 非 >=512 — 位值 1..511 也为真
    r.stop_training = (ru32(m + 0x7C) or 0) ~= 0
    return r
  end
  return nil
end

-- 13.2 CAirWingPool (§4.15.3)
Pool2MT.__index = function(self, k)
  local a = self.addr
  if not O.vt(a, SA2.pool) then return nil end
  if k == "id" then return ru32(a + 0xC) end
  if k == "air_base" then
    return { type = ru32(a + 0x18), id = ru32(a + 0x1C) }
  end
  if k == "definition" then
    -- ⚠ legacy 返 {token, name} 表 (L693) — 发射端读
    -- pool.definition.name; v2 原直接返串 → .name=nil → air.pool 第3列 nil
    local p = rp(a + 0x20)
    if not O.kptr(p) then return nil end
    local tok = ru32(p + 8)
    return { token = tok, name = LAYOUT.token_name(tok) }
  end
  if k == "wings" then
    local out = {}
    local d, n = rp(a + 0x28), ru32(a + 0x34)
    if O.kptr(d) and n and n > 0 and n < 200 then
      for i = 0, n - 1 do
        local w = wing_of_holder2(rp(d + 8 * i))
        if w then out[#out + 1] = w end
      end
    end
    return out
  end
  if k == "wing_count" then return ru32(a + 0x34) end
  return nil
end

-- 13.3 CAirBase (§4.15.8)
Base2MT.__index = function(self, k)
  local a = self.addr
  if not O.vt(a, SA2.airbase) then return nil end
  if k == "id_pair" then return { type = ru32(a + 8), id = ru32(a + 12) } end
  if k == "carrier" then
    if ru32(a + 96) == 0 and ru32(a + 100) == 0 then return nil end
    return { type = ru32(a + 96), id = ru32(a + 100) }
  end
  if k == "state" then
    local sp = rp(a + 104)
    return O.kptr(sp) and ru32(sp + 88) or nil
  end
  if k == "capacity" then return ru32(a + 120) end
  if k == "base_flag" then return ru32(a + 128) & 0xFF end
  if k == "level" then return ru32(a + 132) end
  if k == "allow_equipment_type" then return rp(a + 136) or 0 end
  if k == "country_slots" then          -- 元素 = CCountryAirContainer 指针 (§4.15.9)
    local out = {}
    for _, p in O.vec(a, 72, 84, 8, true) do
      local tid = ru32(p + 176)
      out[#out + 1] = { id = ru32(p + 12),
        motorization = ru32(p + 29) & 0xFF,
        tag = (tid and tid ~= 0 and self.R:tag(tid)) or "",
        -- capacity_penalty 真源 = p+0xD8 (旧 +208 恒默认)
        penalty = (rp(p + 0xD8) or 0) / 1e5 }
    end
    return out
  end
  if k == "country_penalties" then
    local data, slots = rp(a + 0x30), ru32(a + 0x3C)
    if not O.kptr(data) or not slots or slots > 1024 then return nil end
    local t = {}
    for i = 0, slots - 1 do t[i] = ru32(data + 4 * i) end
    return t
  end
  return nil
end

-- 13.4 CStrategicAir (国条; §4.15.2)
SAC2MT.__index = function(self, k)
  local a = self.addr
  if not O.vt(a, SA2.sa_country) then return nil end
  if k == "country_num_id" then return ru32(a + 0x90) end
  if k == "pools" then
    local out = {}
    for _, p in ipairs(cont_elems(a, 0x58, SA2.pool)) do
      out[#out + 1] = setmetatable({ addr = p }, Pool2MT)
    end
    return out
  end
  if k == "pool_count" then return ru32(a + 0x64) end
  if k == "wings" then                  -- 跨池拍平
    local out = {}
    for _, p in ipairs(cont_elems(a, 0x58, SA2.pool)) do
      local d, n = rp(p + 0x28), ru32(p + 0x34)
      if O.kptr(d) and n and n > 0 and n < 200 then
        for i = 0, n - 1 do
          local w = wing_of_holder2(rp(d + 8 * i))
          if w then out[#out + 1] = w end
        end
      end
    end
    return out
  end
  if k == "naval_slots" then return ru32(a + 0x104) end
  if k == "naval_remaining" then
    local d, n = rp(a + 0xF8), ru32(a + 0x104)
    if not O.kptr(d) or not n or n > 10000 then return nil end
    local t = {}
    for i = 0, n - 1 do t[i] = ru32(d + 4 * i) end
    return t
  end
  if k == "has_quick_deploy" then return O.kptr(rp(a + 0x1D0)) end
  -- combat_history (§4.15.2 +368 / 元素 §4.15.6): 索引 = 原槽位 0 起
  -- (writer 0x140C57230 计数器 0 起, 对拍实证 save.210=槽210; 旧 i+1 误)
  if k == "combat_history" then
    local d, n = rp(a + 368), ru32(a + 380)
    if not O.kptr(d) or not n or n > 4096 then return {} end
    local out = {}
    for i = 0, n - 1 do
      local p = rp(d + 8 * i)
      if O.kptr(p) and rp(p) == (BASE + GAME.layout.vt.CStrategicAir_vt2) then
        out[#out + 1] = { idx = i, ptr = p }
      end
    end
    return out
  end
  return nil
end

-- 13.5 入口: strategic_air / air_wings (§4.15.1 mgr = *(gs+1680))
function Runtime.strategic_air(self)
  local mgr = self.gs() and rp(self.gs() + 0x690)
  if not O.vt(mgr, SA2.mgr) then return nil end
  local countries, airbases = {}, {}
  for _, p in ipairs(cont_elems(mgr, 0x30, SA2.sa_country)) do
    countries[#countries + 1] = setmetatable({ addr = p }, SAC2MT)
  end
  for _, p in ipairs(cont_elems(mgr, 0x90, SA2.airbase)) do
    airbases[#airbases + 1] = setmetatable({ addr = p }, Base2MT)
  end
  return { addr = mgr, countries = countries, air_bases = airbases,
    theatre_slots = ru32(mgr + 0xE4), theatre_cap = ru32(mgr + 0xE0) }
end
function Runtime.air_wings(self, idx)
  local mgr = self.gs() and rp(self.gs() + 0x690)
  if not O.kptr(mgr) or rp(mgr) ~= BASE + SA2.mgr then return nil end
  local d30, n30 = rp(mgr + 0x30), ru32(mgr + 0x3C)
  if not O.kptr(d30) or not n30 or n30 > 65536 then return nil end
  if idx >= 0 and idx < n30 then
    local sa = rp(d30 + 8 * idx)
    if O.kptr(sa) and rp(sa) == BASE + SA2.sa_country then
      local c = setmetatable({ addr = sa }, SAC2MT)
      return { pools = c.pools, wings = c.wings, pool_count = c.pool_count }
    end
  end
  return nil
end



-- ============================================================
-- §14 战斗族 (§4.22; 主管理 gs+0x260 vtable 0x2950688; 明细 gs+0x268;
-- 日志管理 gs+0x274 vtable 0x295d8d8; 历史 hist 内嵌@mgr+0x28 → gs+0x288)
-- ============================================================
local CBT2 = { mgr = GAME.layout.vt.CCombatManager, logmgr = GAME.layout.vt.CCombatLogManager }

-- 14.1 combat 概览 (§4.22.1 CCombatManager @gs+608 / logmgr @gs+2176)
function Runtime.combat(self)
  local g = self.gs()
  if not g or rp(g + 0x260) ~= BASE + CBT2.mgr then return nil end
  local out = { addr = g + 0x260 }
  local cd, cn = rp(g + 0x268), ru32(g + 0x274)
  out.combats_count = (O.kptr(cd) and cn) or 0
  out.combats_data = cd
  out.history_count = ru32(g + 0x2A0) or 0
  out.history_head = rp(g + 0x290)
  out.combat_logs = {}
  for i, p in O.vec(g, 0x880, 0x88C, 8, true) do
    if O.kptr(p) and rp(p) == BASE + CBT2.logmgr then
      local n = ru32(p + 0x14) or 0
      local tid = ru32(p + 0x20)
      out.combat_logs[#out.combat_logs + 1] = { idx = i,
        tag = (tid and tid > 0 and self:tag(tid)) or nil, log_count = n }
    end
  end
  return out
end

-- 14.2 combat_details: CLandCombat (§4.22.3) 逐场; combatant 基座字段
-- = §4.22.4 (布局/写门 = 书)
function Runtime.combat_details(self, idx)
  local g = self.gs()
  if not g or rp(g + 0x260) ~= BASE + CBT2.mgr then return nil end
  local cd, cn = rp(g + 0x268), ru32(g + 0x274)
  if not O.kptr(cd) or not cn or idx >= cn then return nil end
  local e = rp(cd + 8 * idx)
  if not O.kptr(e) then return nil end
  local c = e + 16                       -- CLandCombat 内嵌@holder+16
  local function combatant(side_off)     -- 容器@c+24/c+32; ADEC0(elem+16)
    local cont = rp(c + side_off)
    if not O.kptr(cont) then return nil end
    local d = rp(cont)
    local n = ru32(cont + 12)
    -- ⚠ cont[0] = vtable (属映像区间) 而非数据指针 ⇒ 直接用 cont。
    -- 见 sv2_sec_combat.lua 同款注记 (66/66 侧容器实测)。
    if d and d >= BASE and d < BASE + 0x37D2000 then return cont end
    if O.kptr(d) and n and n > 0 and n < 64 then
      local el = rp(d)
      if O.kptr(el) then return rp(el + 16) or el end
    end
    return cont
  end
  local function i64s(a)
    return LAYOUT.i64(a)
  end
  local function fp5x(a)
    local r = i64s(a)
    return r and r / 100000 or nil
  end
  local function ref_list(cb, off_d, off_c)
    local out = {}
    for _, u in O.vec(cb, off_d, off_c, 8, true) do
      out[#out + 1] = ru32(u + 28) or -1
    end
    return out
  end
  local function fp5_arr(dbase, off)     -- {data@+0, count@+12} i64×1e-5
    local out = {}
    local hdr = dbase + off
    local d = rp(hdr)
    if not O.kptr(d) then return out end
    local n = math.min(ru32(hdr + 12) or 0, 512)
    for i = 0, n - 1 do out[i + 1] = (i64s(d + 8 * i) or 0) / 100000 end
    return out
  end
  local function air_planes(cb)          -- {d@288, c@300} 0x38 元素
    local out = {}
    for _, a in O.vec(cb, 288, 300, 8, true) do
      out[#out + 1] = { wing_id = ru32(a + 12), wing_type = ru32(a + 8),
        air_count = ru32(a + 16), amount = ru32(a + 20),
        dmg_factor = (i64s(a + 24) or 0) / 100000,
        date_raw = ru32(a + 40) }        -- 哨兵 0x29C3388 = 未设
    end
    return out
  end
  local function cbt_fields(cb)
    if not cb then return nil end
    local tac = rp(cb + 272)
    return {
      units = ref_list(cb, 32, 44),
      losses = fp5x(cb + 152),
      size = fp5_arr(cb, 128),
      has_flanked = ru32(cb + 187) & 0xFF,
      air_kills = ru32(cb + 320),
      air_dmg_str = fp5x(cb + 328), air_dmg_org = fp5x(cb + 336),
      ground_dmg_str = fp5x(cb + 344), ground_dmg_org = fp5x(cb + 352),
      prevented_str = fp5x(cb + 360), prevented_org = fp5x(cb + 368),
      anti_air = fp5x(cb + 312),
      front = ref_list(cb, 200, 212),
      reserves = ref_list(cb, 224, 236),
      tactic = O.kptr(tac) and ru32(tac + 152) or -1,
      air_planes = air_planes(cb),
      org_loss = fp5_arr(cb, 376),
      str_loss = fp5_arr(cb, 400),
      org_loss_idx = ru32(cb + 424), num_org_losses = ru32(cb + 428) }
  end
  local att, def = combatant(24), combatant(32)
  local loc_obj = rp(c + 40)
  local terrain = nil
  local tobj = rp(c + 56)
  if O.kptr(tobj) and (ru32(tobj + 16) & 0xFF) ~= 0 then
    terrain = U.cstr(tobj + 24)
  end
  return { addr = c,
    id = ru32(e + 12), ctype = ru32(e + 8),   -- holder ref 对 (62 = CLandCombat)
    location = O.kptr(loc_obj) and ru32(loc_obj + 164) or nil,
    day = ru32(c + 48), duration = ru32(c + 52),
    terrain = terrain,
    attacker = cbt_fields(att), defender = cbt_fields(def) }
end

-- 14.3 combat_history: hist 内嵌@gs+0x288 (§4.22.1 CCombatHistory); 链表 next@+56
-- CCombatHistoryEntry (§4.22.4; writer 0x140BABCC0): location@+44,
-- attacker tag@+36, defender tag@+40, end_date CGameDate@+8, type@+32
function Runtime.combat_history(self)
  local g = self.gs()
  if not g or rp(g + 0x260) ~= BASE + CBT2.mgr then return nil end
  local hist = g + 0x288
  -- ⚠ legacy tag_str 无 tid==0 门 — tag 表 (§1.2 gs+856) 槽 0 = "---"
  -- (CBAT:H1 defender "---" 实证); Runtime.tag 对 0 返 nil → v2 全变 nil
  local tt = rp(g + 0x358)
  local function tag_str_raw(tid)
    if not tid or not tt then return nil end
    return U.cstr(tt + 32 * tid)
  end
  local out = {}
  local e = rp(hist + 8)
  local guard = 0
  while O.kptr(e) and guard < 128 do
    out[#out + 1] = {
      location = ru32(e + 44),
      attacker = tag_str_raw(ru32(e + 36)),
      defender = tag_str_raw(ru32(e + 40)),
      type = ru32(e + 32),
      date = U.date(ru32(e + 16)) }
    e = rp(e + 56)
    guard = guard + 1
  end
  return out
end



-- ============================================================
