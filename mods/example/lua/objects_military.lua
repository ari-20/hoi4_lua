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

-- holder 全记录链 (inline 记录 holder+24 先, 追加向量元素后 — writer 块序)
-- = SH.officer_records (本文件顶部已导入)。此处原有一份逐字重复的本地
-- 定义, 遮蔽了导入, 已删 (唯一实现住 objects_shared)。

local DivMT = {}
local function mk_div(a) return setmetatable({ addr = a }, DivMT) end

-- §4.18.1 CUnitHistoryEntry 公共记录链唯一实现 (师 army_history / 师·船
-- unit_medals store / 船 history 同构; kptr 过滤 = 列表对齐契约)。
-- writer 门逐项: army_names sso@+8 空不收 / target_country tag@+76 上界
-- PTR_HUGE / medal 定义@+104 (门 ptr≠0 且 ru8(def+16)≠0, 名 sso@def+24) /
-- multiplier i64@+312 门≠100000 (×1e-5) / orders u32@+320 门≠0 /
-- custom_lockey MSVC@+40 门 unique(@+72)==16 / location 容器@+0x120
-- (门 PTR_SANE = 段层实证, 旧 reader <64 系误抄防御界) / sunk 原始名串
-- @+128/+160。with_sunk = 真 (船史) 才另建 §4.16.13 CSunkShipInfo 全记录
-- (@+120; 师侧区域非零残差会造假叶, 故按需)。
local function uhist_recs(hd, hc, with_sunk)
  local out = {}
  if not O.kptr(hd) or not hc or hc <= 0 or hc >= LAYOUT.lim.PTR_SANE then
    return out
  end
  for q = 0, hc - 1 do
    local e = rp(hd + 8 * q)
    if O.kptr(e) then
      local rec = { addr = e }
      local an = U.sso(e + 8)
      if an and #an > 0 then rec.army_names = an end
      local tid = ru32(e + 76)
      if tid and tid > 0 and tid < LAYOUT.lim.PTR_HUGE then
        rec.target_country = Runtime:tag(tid) end
      rec.date = date_from_hours_raw(ru32(e + 88))
      rec.unique = ru32(e + 72)
      rec.medal_count = (ru8(e + 112) == 1) and "yes" or "no"
      rec.inherit = (ru8(e + 113) == 1) and "yes" or "no"
      local mdp = rp(e + 104)
      if O.kptr(mdp) and (ru8(mdp + 16) or 0) ~= 0 then
        local mdn = U.sso(mdp + 24)
        if mdn and #mdn > 0 then rec.medal = mdn end
      end
      local mu = rp(e + 312)
      if mu and mu ~= 100000 then rec.multiplier = mu * 1e-5 end
      local od = ru32(e + 320)
      if od and od ~= 0 then rec.orders = od end
      if ru32(e + 72) == 16 then
        local csz = ru32(e + 56)
        if csz and csz > 0 and csz < 4096 then
          local cbuf = (csz > 15) and rp(e + 40) or (e + 40)
          if O.kptr(cbuf) then rec.custom_lockey = hoi4.read_cstr(cbuf) end
        end
      end
      local lcd, lcc = rp(e + 0x120), ru32(e + 0x128)
      if O.kptr(lcd) and lcc and lcc > 0 and lcc < LAYOUT.lim.PTR_SANE then
        local locs = {}
        for k2 = 0, lcc - 1 do
          local lp2 = rp(lcd + 8 * k2)
          local lid = O.kptr(lp2) and ru32(lp2 + 164) or nil
          if lid then locs[#locs + 1] = lid end
        end
        rec.locations = locs
      end
      rec.sunk_name_raw = U.sso(e + 128)
      rec.sunk_killer_raw = U.sso(e + 160)
      if with_sunk then
        -- §4.16.13 CSunkShipInfo 内嵌@+120 (船史; 块门 = 名非空或 level>0)
        local b0 = 120
        local su = {}
        local nm2 = U.sso(e + b0 + 8)
        if nm2 and #nm2 > 0 then su.name = nm2 end
        local kn2 = U.sso(e + b0 + 40)
        if kn2 and #kn2 > 0 then su.killer_name = kn2 end
        local ct2 = ru32(e + b0 + 72)
        if ct2 and ct2 > 0 then su.country = Runtime:tag(ct2) end
        local kc2 = ru32(e + b0 + 76)
        if kc2 and kc2 > 0 then su.killer_country = Runtime:tag(kc2) end
        su.level = ru32(e + b0 + 120) or 0
        local dfd = rp(e + b0 + 104)
        if O.kptr(dfd) then
          su.definition = LAYOUT.token_name(ru32(dfd + 8) or 0) end
        local kdd = rp(e + b0 + 112)
        if O.kptr(kdd) then
          su.killer_definition = LAYOUT.token_name(ru32(kdd + 8) or 0) end
        local lcd3 = rp(e + b0 + 144)
        if O.kptr(lcd3) then su.location = ru32(lcd3 + 164) or 0 end
        su.date = date_from_hours_raw(ru32(e + b0 + 88))
        if (ru32(e + b0 + 161) & 0xFF) == 1 then su.assist = "yes" end
        local evt, evi = ru32(e + b0 + 124), ru32(e + b0 + 128)
        if (evt and evt ~= 0) or (evi and evi ~= 0) then
          su.eq_variant = string.format("id=%d type=%d",
              evi or 0, evt or 0) end
        su.air_wing = string.format("id=%d type=%d",
            ru32(e + b0 + 136) or 0, ru32(e + b0 + 132) or 0)
        local btt, bti = ru32(e + b0 + 152), ru32(e + b0 + 156)
        if (btt and btt ~= 0) or (bti and bti ~= 0) then
          su.battle = string.format("id=%d type=%d", bti or 0, btt or 0) end
        su.convoy = (ru32(e + b0 + 160) & 0xFF) == 1 and "yes" or "no"
        if (su.name and #su.name > 0) or (su.level or 0) > 0 then
          rec.sunk = su
        end
      end
      out[#out + 1] = rec
    end
  end
  return out
end

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
-- produced (12204) @P: 池 64B (§4.23.3 CEquipmentVariantPool, 序列化源 = pool2);
-- allow_zero_entries bool@P+56 (writer 0x140FFDB00); amount≠0 或 az 才写条目;
-- 有条目或 force 时补 produced.allow_zero_entries 键。
-- ⚠ 池读取唯一实现 = U.pool_read (布局引 LAYOUT.off.variant_pool);
-- 上界 64 = 历史判据 (writer 明文有界)。
local function req_produced(P, out, pfx, force)
  local pr = U.pool_read(P, { max = LAYOUT.lim.FIXED_SMALL })
  local n = 0
  for _, e in ipairs(pr and pr.list or {}) do
    n = n + 1
    out[#out + 1] = { pfx .. "produced.equipment." .. n .. ".id",
        string.format("id=%d type=%d", e.id, e.type) }
    out[#out + 1] = { pfx .. "produced.equipment." .. n .. ".amount",
        req_fx(e.amount) }
  end
  if n > 0 or force then
    out[#out + 1] = { pfx .. "produced.allow_zero_entries",
        (pr and pr.allow_zero or 0) ~= 0 and "yes" or "no" }
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
    -- is_name_ordered (14562): 反值门仅假写 no (段层 writer 实证 @+168==0)
    r.is_name_ordered_no = (ru8(n + 168) or 0) == 0
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
      lst = uhist_recs(d, cnt)
    end
    return { list = lst, count = #lst }
  end
  if k == "medal_store" then            -- §4.18.1 army_history.unit_medals
    local st = rp(a + 1624)             --   (scoped ptr → CUnitMedalStore;
    if not (st and O.kptr(st)           --   布局同 CArmyHistory 队列 + amount@+608)
        and rp(st) == BASE + GAME.layout.vt.CUnitHistoryEntry) then
      return nil
    end
    local amt = ru32(st + 608)
    return { list = uhist_recs(rp(st + 8), ru32(st + 20)),
      amount = (amt and amt > 0) and amt or nil }
  end
  if k == "commandlist_actions" then    -- §4.18.5 writer 分派 (token@p+8;
    local out = {}                      --   13898 存档未见未实现, 原样)
    for _, p in O.vec(a, 704, 716, 8, true) do
      if O.kptr(p) then
        local tk = ru32(p + 8)
        if tk == 13896 then             -- §4.33.15 CUnitMoveAction (96B)
          local act = { kind = 13896,
            unit_type = ru32(p + 16) or 0, unit_id = ru32(p + 20) or 0 }
          local d1, c1 = rp(p + 24), ru32(p + 36)
          if O.kptr(d1) and c1 and c1 > 0 and c1 < 4096 then
            act.provinces = {}
            for j = 0, c1 - 1 do
              act.provinces[#act.provinces + 1] = ru32(d1 + 4 * j) or 0 end
          end
          local d2, c2 = rp(p + 48), ru32(p + 60)
          if O.kptr(d2) and c2 and c2 > 0 and c2 < 4096 then
            act.path = {}
            for j = 0, c2 - 1 do
              act.path[#act.path + 1] = ru32(d2 + 4 * j) or 0 end
          end
          act.clear = (ru8(p + 80) or 0) ~= 0
          act.safe = (ru8(p + 81) or 0) ~= 0
          act.safe_fallback = (ru8(p + 83) or 0) ~= 0
          act.safe_end = (ru8(p + 82) or 0) ~= 0
          act.avoid = (ru8(p + 85) or 0) ~= 0
          act.move_priority_raw = ru32(p + 88)
          act.sticky = (ru8(p + 92) or 0) ~= 0
          out[#out + 1] = act
        elseif tk == 13897 then         -- §4.33.15 CUnitNavalMoveAction (40B)
          out[#out + 1] = { kind = 13897,
            unit_type = ru32(p + 16) or 0, unit_id = ru32(p + 20) or 0,
            location = ru32(p + 28), province = ru32(p + 24),
            amphibious = (ru8(p + 32) or 0) ~= 0 }
        end
      end
    end
    return out
  end
  if k == "disrupted_supply_raw" then   -- i64@+176 原值 (段层门 ~=0, ×1e-5)
    return rp(a + 176)
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
      -- name: MSVC SSO @fl+224 {buf@0, size@+16, cap@+24} (writer 形;
      -- 旧 cstr-first 链对裸堆串误读, 已废)
      frec.name = U.sso(fl + 224)
      -- hours_without_patrol_missions_pairs (RH 表 @fl+40: data@+8,
      -- mask@+20, extra@+24; 24B 桶 {dist@+4, region ptr@+8, value@+16};
      -- 空桶 dist==0 与墓碑 0xFE 过滤; 写序 = region id 升序 — differ 实证)
      do
        local hd = rp(fl + 48)
        local hmask = ru32(fl + 60) or 0
        local hmaxp = ru8(fl + 64) or 0
        if O.kptr(hd) and hmask > 0 and hmask < LAYOUT.lim.PTR_SANE then
          local endp = hd + 24 * (hmask + hmaxp + 1)
          local he, guard = hd, 0
          local hw = {}
          while he < endp and guard < 4096 do
            guard = guard + 1
            local dist = ru8(he + 4) or 0
            if dist ~= 0 and dist ~= 0xFE then
              local op = rp(he + 8)
              local reg = O.kptr(op) and ru32(op + 88) or nil
              if reg then hw[#hw + 1] = { reg, ru32(he + 16) or 0 } end
            end
            he = he + 24
          end
          table.sort(hw, function(a, b) return a[1] < b[1] end)
          frec.patrol_pairs = hw
        end
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
          -- spotting 族 (§4.16.12 A6 表; writer 0x140FA9900 尾段; ms=tf+864)
          if (ru8(ms + 104) or 0) ~= 0 then mrec.already_spotted = true end
          local ssp = rp(ms + 120)
          if ssp and ssp ~= 0 then mrec.spotting_speed = ssp end
          local spr = rp(ms + 128)
          if spr and spr ~= 0 then mrec.spotting_process = spr end
          mrec.spot_targets = {}
          for _, ip in ipairs({ { 136, "spotting_target" },
              { 144, "spotting_convoy_client" },
              { 152, "spotting_unit_transfer" },
              { 160, "strike_force_target" } }) do
            local t0, i0 = ru32(ms + ip[1]), ru32(ms + ip[1] + 4)
            if (t0 and t0 ~= 0) or (i0 and i0 ~= 0) then
              mrec.spot_targets[#mrec.spot_targets + 1] = {
                name = ip[2], type = t0 or 0, id = i0 or 0 }
            end
          end
          do                    -- mission.bombardment_region: region ptr@ms+96
            local mbp = rp(ms + 96)
            if O.kptr(mbp) then
              mrec.bombardment_region = ru32(mbp + 88) or 0 end
          end
          -- tf 级内联簇 (§4.16.2; writer 0x140D66770 尾段)
          do                    -- country_intel {d@+0x278, c@+0x284} 24B 元
            local cid, cic = rp(tf + 0x278), ru32(tf + 0x284) or 0
            if O.kptr(cid) and cic > 0 and cic < LAYOUT.lim.PTR_SANE then
              local ci = {}
              for k = 0, cic - 1 do
                local e = cid + 24 * k
                ci[#ci + 1] = ru32(e) or 0
                ci[#ci + 1] = ru32(e + 8) or 0
                ci[#ci + 1] = ru8(e + 16) or 0
              end
              trec.country_intel = ci
            end
          end
          do                    -- strike_forces_on_ship {d@+1576, c@+1588}
            local sfd, sfc = rp(tf + 1576), ru32(tf + 1588)
            if O.kptr(sfd) and sfc and sfc > 0
                and sfc < LAYOUT.lim.PTR_SANE then
              trec.strike_forces = {}
              for j = 0, sfc - 1 do
                local e = sfd + 8 * j
                trec.strike_forces[#trec.strike_forces + 1] = {
                  type = ru32(e) or 0, id = ru32(e + 4) or 0 }
              end
            end
          end
          do                    -- spotters {d@+1552, c@+1564} (8B 内联 idpair)
            local spd, spc = rp(tf + 1552), ru32(tf + 1564)
            if O.kptr(spd) and spc and spc > 0
                and spc < LAYOUT.lim.PTR_SANE then
              trec.spotters = {}
              for j = 0, spc - 1 do
                local e = spd + 8 * j
                trec.spotters[#trec.spotters + 1] = {
                  type = ru32(e) or 0, id = ru32(e + 4) or 0 }
              end
            end
          end
          do                    -- enemy_mines_factor i64@+1616 门 signed>0
            local emf = rp(tf + 1616)
            if emf and emf > 0 then trec.enemy_mines = emf end
          end
          do                    -- repair_last_mission u32@+1264 门≠0
            local rlm = ru32(tf + 1264)
            if rlm and rlm ~= 0 then trec.repair_last_mission = rlm end
          end
          do                    -- path_to_parent (运行时 tf+1816/1820)
            local nap = ru32(tf + 1816)
            if nap and nap ~= 0 then trec.next_pp = nap end
            local ldp = ru32(tf + 1820)
            if ldp and ldp ~= 1 then trec.last_delay_pp = ldp end
          end
          do                    -- target_ship_types {d@+1856, c@+1868}
            -- 32B SSO 元; 空/不可读槽占号不发射 (槽序稀疏表保洞)
            local tsd, tsc = rp(tf + 1856), ru32(tf + 1868)
            if O.kptr(tsd) and tsc and tsc > 0
                and tsc < LAYOUT.lim.PTR_SANE then
              local sts = {}
              for j = 0, tsc - 1 do
                local s = U.sso(tsd + 32 * j)
                if s and s ~= "" then sts[j + 1] = s end
              end
              trec.target_ship_types = sts
              trec.target_ship_types_n = tsc
            end
          end
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
              do                    -- critical_damage {d@+2328, c@+2340} 16B 元
                local cdd, cdc = rp(sh + 2328), ru32(sh + 2340)
                if O.kptr(cdd) and cdc and cdc > 0
                    and cdc < LAYOUT.lim.PTR_SANE then
                  local ckey, cparts
                  for cj = 0, cdc - 1 do
                    local ce = cdd + 16 * cj
                    local dfn = rp(ce)
                    local q24 = dfn and O.kptr(dfn) and rp(dfn + 24)
                    -- writer 门 = *(qword*)(def+24) 非空 (D21 实证 13/7 =
                    -- 小整数, 非 kptr); 键 = 部件定义名串 sso@def+8
                    if dfn and O.kptr(dfn) and q24 and q24 ~= 0 then
                      local cnm = U.sso(dfn + 8)
                      if cnm and cnm ~= "" then
                        local cv = tostring(ru32(ce + 8) or 0)
                        if not ckey then
                          ckey = cnm
                          cparts = { cv }     -- 首对: 键进路径, 值裸
                        else
                          cparts[#cparts + 1] = cnm .. "=" .. cv
                        end
                      end
                    end
                  end
                  if ckey then
                    srec.critical_damage = { first = ckey, parts = cparts }
                  end
                end
              end
              do                    -- history (容器@sh+2304/2316; 记录链
                local hd, hc = rp(sh + 2304), ru32(sh + 2316)  -- 含 sunk)
                if O.kptr(hd) and hc and hc > 0 and hc < 4096 then
                  srec.history = uhist_recs(hd, hc, true)
                end
              end
              do                    -- unit_medals store @sh+2296 (同 CArmyHistory 形)
                local st = rp(sh + 2296)
                if O.kptr(st)
                    and rp(st) == BASE + GAME.layout.vt.CUnitHistoryEntry then
                  local amt = ru32(st + 608)
                  srec.medal_store = {
                    list = uhist_recs(rp(st + 8), ru32(st + 20)),
                    amount = (amt and amt > 0) and amt or nil }
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
-- (cont_elems 本地副本已删 — 与 SH.cont_elems 逐字重复且遮蔽了本文件顶部
--  的导入; 唯一实现住 objects_shared。)


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

-- 13.6 导出全量 reader (§4.15; sv2_sec_strategic_air 只持写序/块键/格式)。
-- ⚠ 与 §13.1-13.4 代理族语义有分歧 (name=SSO@+2440 非 cstr; base 旗@+124
--   非 +128; 各写门在此定案) — 发射路径以本函数 + 书 §4.15 为准。
-- ⚫ carrier_air_wing_kills 键解析 = 引擎表 call BASE+0xF8A750 (tok 位集);
--   transferring_to = idreg_unit_resolve 后取 obj+104→+88 (§4.26.3)。
local SA_EXEC = { [0x1]=12335, [0x2]=12224, [0x4]=11058, [0x8]=12229,
  [0x10]=12225, [0x20]=11059, [0x40]=13123, [0x80]=11258,
  [0x100]=12971, [0x200]=11388, [0x400]=11851, [0x800]=12218,
  [0x1000]=11856, [0x2000]=11858, [0x4000]=12196,
  [0x8000]=12159, [0x10000]=10088, [0x20000]=10100 }

local function sa_fx(a)                 -- fixed5 @addr → 数值 (段层格式化)
  return (GAME.layout.i64(a) or 0) / 1e5
end

local function sa_i64(a) return GAME.layout.i64(a) or 0 end

local function sa_resolve_tto(t56, i60)
  if not t56 or t56 <= 0 or t56 >= 100 then return nil end
  local obj = GAME.layout.idreg_unit_resolve(t56, i60)
  if not obj then return nil end
  local o104 = rp(obj + 104)
  if O.kptr(o104) then return ru32(o104 + 88) end
  return nil
end

-- 16B 元内联装备池 (wing@+0x1E8 / ch 条目@+88 内嵌 — 非共享 64B
-- CEquipmentVariantPool): {d@+0,c@+12}, 16B 元 {vp, amt i64@+8}, az 单独传
local function sa_eq_list(d, c, az)
  if not O.kptr(d) or not c or c <= 0 or c > 100 then return nil end
  local out = {}
  for i = 0, c - 1 do
    local e = d + 16 * i
    local vp = rp(e)
    local amt = sa_i64(e + 8)
    if amt ~= 0 or az ~= 0 then
      out[#out + 1] = { type = O.kptr(vp) and (ru32(vp + 8) or 0) or nil,
        id = O.kptr(vp) and (ru32(vp + 0xC) or 0) or nil,
        amount = amt / 1e5 }
    end
  end
  return out
end

local function sa_wing(w)
  if not O.kptr(w) or ru32(w + 8) ~= 69 then return nil end
  local t56, i60 = ru32(w + 56) or 0, ru32(w + 60) or 0
  local b105 = ru8(w + 105) or 0
  local tto, transferring = nil, false
  if t56 ~= 0 or i60 ~= 0 then
    tto = sa_resolve_tto(t56, i60)
    transferring = tto ~= nil
  end
  local dep84, dt80 = ru32(w + 84) or 0, ru32(w + 80) or 0
  local td = rp(w + 2576)
  -- §4.15.5 CAirMission 内嵌@+0x80
  local m = w + 0x80
  local m48 = rp(m + 48)
  local ef = ru32(m + 20) or 0
  local exec_name
  if ef ~= 0 and SA_EXEC[ef] then
    exec_name = GAME.layout.token_name(SA_EXEC[ef]) or SA_EXEC[ef]
  end
  local epc = ru32(m + 224)
  local agg = ru32(m + 28)
  -- priority 串列表 ({d@m+128,c@m+140}, 元 deref, SSO@+624, 非空)
  local prio
  do
    local prd, prc = rp(m + 128), ru32(m + 140)
    if O.kptr(prd) and prc and prc > 0 and prc < LAYOUT.lim.PTR_SANE then
      prio = {}
      for pi = 0, prc - 1 do
        local pp = rp(prd + 8 * pi)
        local ps = O.kptr(pp) and U.sso(pp + 624) or nil
        if ps and ps ~= "" then prio[#prio + 1] = ps end
      end
    end
  end
  -- other_combats (c>0 才写; 8B 元 {type@0, id@4} 内联)
  local ocb
  local ocn = ru32(w + 444)
  if ocn and ocn > 0 and ocn < LAYOUT.lim.PTR_SANE then
    local ocd = rp(w + 432)
    if O.kptr(ocd) then
      ocb = {}
      for i = 0, ocn - 1 do
        ocb[#ocb + 1] = { id = ru32(ocd + 4 + 8 * i) or 0,
          type = ru32(ocd + 8 * i) or 0 }
      end
    end
  end
  -- 装备池 + az (az b@+0x200 单读; allow_zero 叶恒写)
  local eq_az = ru8(w + 0x200) or 0
  local eq = sa_eq_list(rp(w + 0x1E8), ru32(w + 0x1F4), eq_az)
  -- carrier_air_wing_kills (tok 19901): 16B 数组 {key u64 位集, value u32};
  -- 键经引擎表 → token, 无名 token 落数值键 (SL.tok 兜底同形)
  local cak
  do
    local kcnt = ru32(w + 2548) or 0
    local kd = rp(w + 2536)
    if O.kptr(kd) and kcnt > 0 and kcnt <= 64 then
      local buf = hoi4.engine_alloc(8)
      if buf then
        cak = {}
        for ki = 0, kcnt - 1 do
          local e = kd + 16 * ki
          local key = rp(e) or 0
          hoi4.write_u32(buf, 0)
          hoi4.call_u64(BASE + 0xF8A750, buf, key)
          local tk = ru32(buf) or 0
          if tk > 0 then
            cak[#cak + 1] = { name = GAME.layout.token_name(tk) or tk,
              value = ru32(e + 8) or 0 }
          end
        end
        hoi4.engine_free(buf)
      end
    end
  end
  local at728, ai732 = ru32(w + 728) or 0, ru32(w + 732) or 0
  local ag48, ag52 = ru32(w + 48) or 0, ru32(w + 52) or 0
  local rt2588, ri2592 = ru32(w + 2588) or 0, ru32(w + 2592) or 0
  local gix = ru32(w + 2488)
  local ttag = ru32(w + 0x9B4)
  local rta, mta = ru32(w + 96), ru32(w + 100)
  return {
    addr = w,
    id_type = ru32(w + 8) or 0, id_id = ru32(w + 0xC) or 0,
    count = ru32(w + 108) or 0,
    experience = sa_fx(w + 520),
    reinforcement_setting = ru8(w + 2492) or 0,
    timed_disabling = O.kptr(td) and
      { remaining = ru32(td + 4) or 0, sst = (ru32(td + 8) or 0) & 0xFF }
      or nil,
    transfer_pair = (t56 ~= 0 or i60 ~= 0),
    transferring = transferring, transferring_to = tto,
    to_warehouse = b105,
    transfer_progress = sa_fx(w + 64),
    transfer_cancelled = ru8(w + 104) or 0,
    deployment_pair = (b105 ~= 0 or dep84 < dt80 or transferring),
    deployment = dep84, deployment_time = dt80,
    manpower = ru32(w + 112) or 0,
    mission = {
      type = ru32(m + 16) or 0,
      period = (function()
        local b = ru32(m + 24) & 0xFF
        if b >= 128 then b = b - 256 end
        return b end)(),
      active = ru8(m + 32) or 0,
      executing = exec_name,
      effectiveness = (sa_i64(m + 216) ~= 0) and sa_fx(m + 216) or nil,
      effective_planes_count = (epc and epc ~= 0) and epc or nil,
      effective_air_superiority = (sa_i64(m + 232) ~= 0)
        and sa_fx(m + 232) or nil,
      strategic_region = O.kptr(m48) and (ru32(m48 + 88) or 0) or nil,
      region_change_penalty = sa_fx(m + 192),
      missions_done = ru32(m + 116) or 0,
      aggressiveness = (agg and agg ~= 0) and agg or nil,
      priorities = prio,
      stop_training = (ru8(m + 124) or 0) ~= 0 },
    other_combats = ocb,
    air_accidents = (function() local v = ru32(w + 116)
      return (v and v > 0) and v or nil end)(),
    ace_pair = (at728 ~= 0 or ai732 ~= 0),
    ace_id = ai732, ace_type = at728,
    suspended_missions = (function() local v = ru32(w + 424)
      return (v and v ~= 0) and v or nil end)(),
    tag = (ttag and ttag ~= 0) and Runtime:tag(ttag) or nil,
    equipment = eq, equipment_az = eq_az,
    name = U.sso(w + 2440),
    priority = ru32(w + 24) or 0,
    allow_mission_type = ru32(w + 28) or 0,
    region_to_assign = (rta and rta ~= 0) and rta or nil,
    mission_to_assign = (mta and mta ~= 0) and mta or nil,
    gix_tag = (gix and gix > 0) and Runtime:tag(gix) or nil,
    air_untrained = (ru8(w + 2568) or 0) ~= 0,
    air_untrained_factor = sa_fx(w + 2560),
    air_group_pair = (ag48 ~= 0 or ag52 ~= 0),
    air_group_id = ag52, air_group_type = ag48,
    role_icon_index = (function() local v = ru32(w + 2584)
      return (v and v > 0) and v or nil end)(),
    raid_pair = (rt2588 ~= 0 or ri2592 ~= 0),
    raid_id = ri2592, raid_type = rt2588,
    carrier_kills = cak }
end

-- §4.15.7 SAirWingCombatData 单侧条目 (152B; equipment 内嵌池@+88)
local function sa_ch_side(e)
  if not O.kptr(e) then return nil end
  local az = ru8(e + 88 + 56) or 0
  local tag80 = ru32(e + 80)
  local function sr(doff, coff)
    local n = ru32(e + coff)
    if not n or n <= 0 or n >= 4096 then return nil end
    local d = rp(e + doff)
    if not O.kptr(d) then return nil end
    local out = {}
    for i = 0, n - 1 do
      local q = d + 24 * i
      out[#out + 1] = { type = ru32(q + 8) or 0, value = sa_fx(q + 16) }
    end
    return out
  end
  return {
    id = ru32(e + 8) or 0,
    equipment = sa_eq_list(rp(e + 88 + 0x20), ru32(e + 88 + 0x2C), az),
    az = az,
    time = ru32(e + 12) or 0,
    mission = ru32(e + 20) or 0, count = ru32(e + 16) or 0,
    tag = (tag80 and tag80 > 0) and Runtime:tag(tag80) or nil,
    ground_attack = (ru8(e + 25) or 0) ~= 0,
    receiver = sr(56, 68), sender = sr(32, 44),
    destination = (ru8(e + 24) or 0) ~= 0 }
end

-- Runtime.strategic_air_full -> {air_theatre_index_id, air_group_index_id,
--   bases(四阵列合并序), countries(按国条序; tag 门)}
function Runtime.strategic_air_full(self)
  local g = self.gs()
  local mgr = g and rp(g + 0x690)
  if not (mgr and O.kptr(mgr)
      and rp(mgr) == BASE + GAME.layout.vt.CStrategicAirMgr) then
    return nil
  end
  local out = { addr = mgr,
    air_theatre_index_id = ru32(mgr + 0x18) or 0,
    air_group_index_id = ru32(mgr + 0x28) or 0,
    bases = {}, countries = {} }
  -- §4.15.8 基地四阵列 (writer 0x140C57520 序: air_base/舰载/火箭/巨炮;
  -- 1/3 阵列 vt 门, 2/4 无)
  for _, arr in ipairs({ { 0x90, true }, { 0xD8, false },
                         { 0xA8, true }, { 0xC0, false } }) do
    local d, c = rp(mgr + arr[1]), ru32(mgr + arr[1] + 12)
    if O.kptr(d) and c and c > 0 and c < LAYOUT.lim.PTR_HUGE then
      for i = 0, c - 1 do
        local p = rp(d + 8 * i)
        if O.kptr(p)
            and (not arr[2] or rp(p) == BASE + GAME.layout.vt.CAirBase) then
          local sp = rp(p + 104)
          local cd, cn = rp(p + 72), ru32(p + 84)
          local cts
          if O.kptr(cd) and cn and cn > 0 and cn < 4096 then
            cts = {}
            for k = 0, cn - 1 do
              local cp = rp(cd + 8 * k)
              if O.kptr(cp) then
                local tid = ru32(cp + 176)
                cts[#cts + 1] = {
                  id_type = ru32(cp + 8) or 0, id_id = ru32(cp + 12) or 0,
                  disrupted_supply = (sa_i64(cp + 160) > 0)
                    and sa_fx(cp + 160) or nil,
                  motorization = ru8(cp + 29) or 0,
                  tag = (tid and tid ~= 0) and Runtime:tag(tid) or nil,
                  operational_status = (sa_i64(cp + 208) ~= 100000)
                    and sa_fx(cp + 208) or nil,
                  capacity_penalty = (sa_i64(cp + 216) ~= 0)
                    and sa_fx(cp + 216) or nil,
                  fuel_consumption = (sa_i64(cp + 224) ~= 0)
                    and sa_fx(cp + 224) or nil,
                  received = (sa_i64(cp + 240) ~= 0)
                    and sa_fx(cp + 240) or nil,
                  base_fuel_consumption = (sa_i64(cp + 232) ~= 0)
                    and sa_fx(cp + 232) or nil }
              end
            end
          end
          out.bases[#out.bases + 1] = {
            addr = p, base_flag = ru32(p + 124) or 0,
            id_type = ru32(p + 8) or 0, id_id = ru32(p + 12) or 0,
            state = O.kptr(sp) and (ru32(sp + 88) or 0) or nil,
            carrier_type = ru32(p + 96) or 0, carrier_id = ru32(p + 100) or 0,
            capacity = ru32(p + 120) or 0,
            has_manpower = ru8(p + 128) or 0,
            level = ru32(p + 132) or 0,
            allow_equipment_type = rp(p + 136) or 0,
            countries = cts }
        end
      end
    end
  end
  -- 国条循环 (§4.15.2)
  local d30, n30 = rp(mgr + 0x30), ru32(mgr + 0x3C)
  if not (O.kptr(d30) and n30 and n30 > 0
      and n30 < LAYOUT.lim.PTR_HUGE) then
    return out
  end
  for i = 0, n30 - 1 do
    local sa = rp(d30 + 8 * i)
    if O.kptr(sa) and rp(sa) == BASE + SA2.sa_country then
      local tid = ru32(sa + 0x90)
      local tag = (tid and tid ~= 0) and Runtime:tag(tid) or nil
      if tag then
        local rec = { addr = sa, tag = tag,
          pools = {}, combat_history = {}, history_queues = {} }
        -- §4.15.3 CAirWingPool
        local pd, pn = rp(sa + 0x58), ru32(sa + 0x64)
        if O.kptr(pd) and pn and pn > 0 and pn < 4096 then
          for j = 0, pn - 1 do
            local pa = rp(pd + 8 * j)
            if O.kptr(pa) and rp(pa) == BASE + SA2.pool then
              local pool = { addr = pa,
                id_type = ru32(pa + 8) or 0, id_id = ru32(pa + 0xC) or 0,
                air_base_type = ru32(pa + 0x18) or 0,
                air_base_id = ru32(pa + 0x1C) or 0,
                wings = {} }
              local dp = rp(pa + 0x20)
              if O.kptr(dp) then pool.definition_tok = ru32(dp + 8) end
              local wd, wn = rp(pa + 0x28), ru32(pa + 0x34)
              if O.kptr(wd) and wn and wn > 0
                  and wn < LAYOUT.lim.PTR_SANE then
                for k = 0, wn - 1 do
                  local h = rp(wd + 8 * k)
                  if O.kptr(h) then
                    local w2 = sa_wing(h + 16)
                    if w2 then pool.wings[#pool.wings + 1] = w2 end
                  end
                end
              end
              rec.pools[#rec.pools + 1] = pool
            end
          end
        end
        -- naval_strike_remaining {d@+248,c@+260} (c>0, <10000)
        do
          local nd, nn = rp(sa + 248), ru32(sa + 260)
          if O.kptr(nd) and nn and nn > 0 and nn < 10000 then
            local vals = {}
            for j = 0, nn - 1 do vals[#vals + 1] = ru32(nd + 4 * j) or 0 end
            rec.naval_strike = vals
          end
        end
        -- §4.15.6 CAirRegionCombatData combat_history (索引 = 槽位 0 起;
        -- 侧名互换: save enemy ← +32, friend ← +8)
        do
          local chd, chn = rp(sa + 368), ru32(sa + 380)
          if O.kptr(chd) and chn and chn > 0 and chn < 4096 then
            for j = 0, chn - 1 do
              local p = rp(chd + 8 * j)
              if O.kptr(p) and rp(p) == BASE + GAME.layout.vt.CStrategicAir_vt2 then
                local t56 = ru32(p + 56)
                local hk = { idx = j,
                  tag = (t56 and t56 > 0) and Runtime:tag(t56) or nil,
                  enemy = {}, friend = {} }
                for _, sd in ipairs({ { "enemy", 32 }, { "friend", 8 } }) do
                  local n = ru32(p + sd[2] + 12)
                  if n and n > 0 and n < 4096 then
                    local d2 = rp(p + sd[2])
                    if O.kptr(d2) then
                      local lst = hk[sd[1]]
                      for k2 = 0, n - 1 do
                        local e = sa_ch_side(d2 + 152 * k2)
                        if e then lst[#lst + 1] = e end
                      end
                    end
                  end
                end
                rec.combat_history[#rec.combat_history + 1] = hk
              end
            end
          end
        end
        -- §4.3.13 CLoopHistory 队列族 (+344 history; 3 队列@+0x10/+0x18/+0x20)
        do
          local hd, hn = rp(sa + 344), ru32(sa + 356)
          if O.kptr(hd) and hn and hn > 0 and hn < 4096 then
            for j = 0, hn - 1 do
              local he = rp(hd + 8 * j)
              local hcols = O.kptr(he) and ru32(he + 52) or nil
              if hcols and hcols > 0 and hcols <= 512 then
                local hrec = { idx = j, cols = hcols, queues = {} }
                for qi, qoff in ipairs({ 0x10, 0x18, 0x20 }) do
                  local qc = rp(he + qoff)
                  if O.kptr(qc) then
                    local q = { max_elements = ru32(qc + 0x20) or 0,
                      offset = ru32(qc + 0x24) or 0,
                      is_full = (ru8(qc + 0x28) or 0) ~= 0 }
                    local buf = rp(qc + 8)
                    local rows = ru32(qc + 0x14) or 0
                    if O.kptr(buf) and rows > 0 and rows <= 256
                        and rows * hcols <= 65536 then
                      local cells, any = {}, false
                      for r = 0, rows - 1 do
                        local h1 = rp(buf + 8 * r)
                        local row = O.kptr(h1) and rp(h1) or nil
                        local rv = O.kptr(row)
                        for k2 = 0, hcols - 1 do
                          local v = 0
                          if rv then
                            v = sa_i64(row + 8 * k2) / 1e5
                          end
                          if v ~= 0 then any = true end
                          cells[#cells + 1] = v
                        end
                      end
                      if any then q.cells = cells end
                    end
                    hrec.queues[qi] = q
                  end
                end
                rec.history_queues[#rec.history_queues + 1] = hrec
              end
            end
          end
        end
        out.countries[#out.countries + 1] = rec
      end
    end
  end
  return out
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

-- ============================================================
-- 14.5 combat_log 管理器族 (§4.22.4 NCombatLog::CManager;
-- gs+2176/2188 按国家 id 索引; SCombatData 同体异名 vt 0x295D8D8)
-- 结构唯一实现; 段层 sv2_sec_combat_log 只按写序发射。
-- ⚠ equipment ×4 容器为**合并序** (writer 依次扫 4 容器, 共用一个编号),
--   故 reader 输出带 src 序号, 段层不得重排。
local function combat_log_loss(se)
  -- CLoss 三件套: reason u32@+8 / date@+24 / 内嵌 SEquipmentPool @+40
  -- (恒写无空判; 元素门 amount≠0∨az = 共享 reader)
  if not O.kptr(se) then return nil end
  return { reason = ru32(se + 8) or 0, date_h = ru32(se + 24),
           pool = U.pool_read(se + 40, { clamp = LAYOUT.lim.PTR_SANE }) }
end

function Runtime.combat_log_managers(self)
  local g = self.gs()
  if not g then return nil end
  local arr, cnt = rp(g + 0x880), ru32(g + 0x88C) or 0
  if not O.kptr(arr) or cnt <= 0 then return nil end
  local out = {}
  for i = 0, math.min(cnt, 1024) - 1 do
    local mgr = rp(arr + 8 * i)
    if O.kptr(mgr) and rp(mgr) == BASE + GAME.layout.vt.CCombatLogManager then
      local ln = ru32(mgr + 20) or 0
      local rec = { addr = mgr, tag_tid = ru32(mgr + 32), logs = {},
                    log_count = ln }
      local ld = rp(mgr + 8)
      if O.kptr(ld) and ln > 0 then
        for j = 0, math.min(ln, 256) - 1 do
          local le = rp(ld + 8 * j)
          if O.kptr(le) and rp(le) == BASE + GAME.layout.vt.CCombatLogEntry then
            local e = { group_id = ru32(le + 228),
              group_type = ru32(le + 224),
              equipment = {}, enemy_equipment = {},
              equipment_recovered = {}, manpower = {},
              division_template = {}, combat_data_index = {} }
            -- equipment ×4 容器 (合并序; 8B 指针容器)
            for _, oc in ipairs({ { 56, 68 }, { 80, 92 },
                                  { 104, 116 }, { 128, 140 } }) do
              local d2, n2 = rp(le + oc[1]), ru32(le + oc[2]) or 0
              if O.kptr(d2) and n2 > 0 then
                for q = 0, math.min(n2, LAYOUT.lim.PTR_SANE) - 1 do
                  local r = combat_log_loss(rp(d2 + 8 * q))
                  if r then e.equipment[#e.equipment + 1] = r end
                end
              end
            end
            -- enemy_equipment / equipment_recovered
            for _, spec in ipairs({ { 8, 20, "enemy_equipment" },
                                    { 32, 44, "equipment_recovered" } }) do
              local d2, n2 = rp(le + spec[1]), ru32(le + spec[2]) or 0
              if O.kptr(d2) and n2 > 0 then
                for q = 0, math.min(n2, LAYOUT.lim.PTR_SANE) - 1 do
                  local r = combat_log_loss(rp(d2 + 8 * q))
                  if r then e[spec[3]][#e[spec[3]] + 1] = r end
                end
              end
            end
            -- manpower 子条目 (reason@+8 / date@+24 / mp_losses 3×u32@+40)
            local d2, n2 = rp(le + 152), ru32(le + 164) or 0
            if O.kptr(d2) and n2 > 0 then
              for q = 0, math.min(n2, LAYOUT.lim.PTR_SANE) - 1 do
                local se = rp(d2 + 8 * q)
                if O.kptr(se) then
                  e.manpower[#e.manpower + 1] = {
                    reason = ru32(se + 8) or 0, date_h = ru32(se + 24),
                    losses = { ru32(se + 40) or 0, ru32(se + 44) or 0,
                               ru32(se + 48) or 0 } }
                end
              end
            end
            -- CPerTemplateStats division_template (id 对@+8/+12 / win@+24 /
            -- total@+28 / date@+40)
            d2, n2 = rp(le + 176), ru32(le + 188) or 0
            if O.kptr(d2) and n2 > 0 then
              for q = 0, math.min(n2, LAYOUT.lim.PTR_SANE) - 1 do
                local se = rp(d2 + 8 * q)
                if O.kptr(se) then
                  e.division_template[#e.division_template + 1] = {
                    id_type = ru32(se + 8), id_id = ru32(se + 12),
                    win = ru32(se + 24) or 0, total = ru32(se + 28) or 0,
                    date_h = ru32(se + 40) }
                end
              end
            end
            -- combat_data_index 内联 8B {id i32, attacker u8}
            d2, n2 = rp(le + 200), ru32(le + 212) or 0
            if O.kptr(d2) and n2 > 0 then
              for q = 0, math.min(n2, LAYOUT.lim.PTR_SANE) - 1 do
                local v = d2 + 8 * q
                local id = ru32(v) or 0
                e.combat_data_index[#e.combat_data_index + 1] = {
                  id = LAYOUT.as_i32(id), attacker = ru8(v + 4) or 0 }
              end
            end
            rec.logs[#rec.logs + 1] = e
          end
        end
      end
      out[#out + 1] = rec
    end
  end
  return out
end

-- ============================================================
-- 14.6 naval_combat_result (§4.22.6 CNavalCombatResults;
-- gs+1472 {d}, count@gs+1484; 侧对象 112B 内嵌 @e+24/@e+136)
-- 结构唯一实现; 段层 sv2_sec_naval_combat_result 只按写序发射。
-- ⚠ shown_to_countries 编号 = 原始槽序 (tag 解析失败的槽占号不发射, 有洞;
--   reader 以 shown_to_n + 稀疏表保序); countries 则过滤后重编号。
-- ⚫ 空 id 对哨兵 qword_14333D528 (highest_eq_variant 门; 读值非读址)
local NCR_NULLREF = BASE + 0x333D528

-- SNavalHit (六字段全恒写; name/damage/strength 读写失败 = 段层 E 跳 nil)
local function ncr_naval_hits(d, c)
  if not O.kptr(d) or not c or c <= 0 then return nil end
  local out = {}
  for k = 0, math.min(c, LAYOUT.lim.PTR_SANE) - 1 do
    local en = rp(d + 8 * k)
    if O.kptr(en) then
      out[#out + 1] = {
        target = ru32(en + 8) or 0,
        name = U.sso(en + 16),
        convoy = ru8(en + 48) or 0,   -- 原字节 (两段 yn 语义不同, 段层换算)
        damage = U.fix5(en + 56),
        strength = U.fix5(en + 64),
        last_hit = ru8(en + 72) or 0 }
    end
  end
  return out
end

-- SAirHit (tag 门 >0 且可解析; 装备变体门 = 指针有效)
local function ncr_air_hits(d, c)
  if not O.kptr(d) or not c or c <= 0 then return nil end
  local out = {}
  for k = 0, math.min(c, LAYOUT.lim.PTR_SANE) - 1 do
    local en = rp(d + 8 * k)
    if O.kptr(en) then
      local tg, ev = ru32(en + 0x14), rp(en + 8)
      out[#out + 1] = {
        tag = (tg and tg > 0) and Runtime:tag(tg) or nil,
        var_type = O.kptr(ev) and (ru32(ev + 8) or 0) or nil,
        var_id = O.kptr(ev) and (ru32(ev + 12) or 0) or nil,
        count = ru32(en + 0x10) or 0 }
    end
  end
  return out
end

-- CNavalCombatAirEntry (killed/tag 门 >0; 双 hits 容器门 count>0)
local function ncr_air_wings(d, c)
  if not O.kptr(d) or not c or c <= 0 then return nil end
  local out = {}
  for k = 0, math.min(c, LAYOUT.lim.PTR_SANE) - 1 do
    local aw = rp(d + 8 * k)
    if O.kptr(aw) then
      local ev, kl, tg = rp(aw + 8), ru32(aw + 24), ru32(aw + 28)
      out[#out + 1] = {
        var_type = O.kptr(ev) and (ru32(ev + 8) or 0) or nil,
        var_id = O.kptr(ev) and (ru32(ev + 12) or 0) or nil,
        max = ru32(aw + 16) or 0,
        alive = ru32(aw + 20) or 0,
        killed = (kl and kl > 0) and kl or nil,
        tag = (tg and tg > 0) and Runtime:tag(tg) or nil,
        air_base = U.sso(aw + 32),
        naval_hits = ncr_naval_hits(rp(aw + 64), ru32(aw + 76) or 0),
        air_hits = ncr_air_hits(rp(aw + 88), ru32(aw + 100) or 0) }
    end
  end
  return out
end

-- SCachedInfo (结构同 §4.22.5 member.cached_info; 门 = 书逐项; 发射序 = 段层)
local function ncr_cached(ci, nullref)
  local sb, shn = U.sso(ci + 0x90), U.sso(ci + 0x30)
  local hev = rp(ci + 0xB0)
  local cvt, cvi = ru32(ci + 0xB8), ru32(ci + 0xBC)
  local stv, bci = U.fix5(ci + 0x20), U.fix5(ci + 0x18)
  local cidx, tg = ru32(ci + 0xC0) or 0, ru32(ci + 8)
  return {
    sprite = U.sso(ci + 0x70),
    index = ru32(ci + 0x0C) or 0,
    type = ru32(ci + 0x10) or 0,
    tag = (tg and tg > 0) and Runtime:tag(tg) or nil,
    strength = (stv and stv ~= 0) and stv or nil,
    sunk_by = (sb and sb ~= "") and sb or nil,
    convoy = (ru8(ci + 0x29) or 0) ~= 0,
    build_cost_ic = (bci and bci ~= 0) and bci or nil,
    equipment_variant = U.sso(ci + 0x50),
    hev_type = (hev and hev ~= nullref) and (ru32(ci + 0xB0) or 0) or nil,
    hev_id = (hev and hev ~= nullref) and (ru32(ci + 0xB4) or 0) or nil,
    ship = (shn and shn ~= "") and shn or nil,
    potf = (ru8(ci + 0x28) or 0) ~= 0,
    convoy_id_type = ((cvt and cvt ~= 0) or (cvi and cvi ~= 0))
      and (cvt or 0) or nil,
    convoy_id_id = ((cvt and cvt ~= 0) or (cvi and cvi ~= 0))
      and (cvi or 0) or nil,
    convoy_index = (cidx < 0x80000000) and cidx or nil }
end

-- CNavalCombatShipEntry (unique_id 恒写)
local function ncr_ships(d, c, nullref)
  if not O.kptr(d) or not c or c <= 0 then return nil end
  local out = {}
  for k = 0, math.min(c, LAYOUT.lim.PTR_SANE) - 1 do
    local sh = rp(d + 8 * k)
    if O.kptr(sh) then
      out[#out + 1] = {
        id_type = ru32(sh + 8) or 0, id_id = ru32(sh + 12) or 0,
        cached = ncr_cached(sh + 16, nullref),
        naval_hits = ncr_naval_hits(rp(sh + 0xD8), ru32(sh + 0xE4) or 0),
        air_hits = ncr_air_hits(rp(sh + 0xF0), ru32(sh + 0xFC) or 0) }
    end
  end
  return out
end

-- CNavalCombatResultSide (countries 过滤重编号; last_leader 门 = §4.1.7
-- 三注册表解析成功)
local function ncr_side(s, nullref)
  if not O.kptr(s) then return nil end
  local cd2, cc2 = rp(s + 56), ru32(s + 68)
  local countries
  if O.kptr(cd2) and cc2 and cc2 ~= 0 then
    countries = {}
    for k = 0, math.min(cc2, LAYOUT.lim.PTR_SANE) - 1 do
      local cid = ru32(cd2 + 4 * k)
      local t = (cid and cid > 0) and Runtime:tag(cid) or nil
      if t then countries[#countries + 1] = t end
    end
  end
  local lty, lid = ru32(s + 80), ru32(s + 84)
  return {
    air_wings = ncr_air_wings(rp(s + 8), ru32(s + 20) or 0),
    ships = ncr_ships(rp(s + 32), ru32(s + 44) or 0, nullref),
    countries = countries,
    last_leader = (lty == 4713 and lid ~= 0
      and GAME.layout.idreg_unit_resolve(lty, lid))
      and { id = lid, type = lty } or nil }
end

-- Runtime.naval_combat_results -> 有序 list (writer break 语义 = 首无效截断)
function Runtime.naval_combat_results(self)
  local g = self.gs()
  if not g then return nil end
  local d, c = rp(g + 0x5C0), ru32(g + 0x5CC)
  if not (d and c and c > 0 and c < LAYOUT.lim.PTR_SANE) then return nil end
  local nullref = rp(NCR_NULLREF)
  local out = {}
  for i = 0, c - 1 do
    local e = rp(d + 8 * i)
    if not O.kptr(e) then break end
    local scd, scc = rp(e + 0x150), ru32(e + 0x15C)
    local shown, shown_n
    if O.kptr(scd) and scc and scc > 0 and scc < LAYOUT.lim.PTR_SANE then
      shown, shown_n = {}, scc
      for j = 0, scc - 1 do
        local cid = ru32(scd + 4 * j)
        shown[j + 1] = (cid and cid > 0) and Runtime:tag(cid) or nil
      end
    end
    out[#out + 1] = {
      addr = e,
      id_type = ru32(e + 8) or 0, id_id = ru32(e + 12) or 0,
      location = ru32(e + 0x108) or 0,
      date_h = ru32(e + 0x118),
      attacker = ncr_side(e + 0x18, nullref),
      defender = ncr_side(e + 0x88, nullref),
      port_strike = (ru8(e + 0x128) or 0) ~= 0,
      naval_strike = (ru8(e + 0x129) or 0) ~= 0,
      importance = ru32(e + 0x148) or 0,
      to_discard_h = ru32(e + 0x138),
      shown_to = shown, shown_to_n = shown_n }
  end
  return out
end

-- ============================================================
-- 6.9 railway_gun (§4.18.2 CRailwayGun 挂 cc+680/692; 尾接 CUnit 公共段
-- §4.18.5) — 结构唯一实现; 段层 sv2_sec_c_units 只按写序发射。
-- ⚠ army id 对 = 虚函数返 *(p-16) qword {id=高32, type=低32} (0x140BE02B0);
--   tag 上界收敛 = Runtime:tagUpperBound() (段内旧本地逻辑并入)。
function Country.railway_guns(self)
  local cca = self.addr
  if not cca then return nil end
  local rgd, rgc = rp(cca + 680), ru32(cca + 692)
  if not O.kptr(rgd) or not rgc or rgc <= 0
      or rgc >= LAYOUT.lim.PTR_SANE then return nil end
  local tagub = Runtime:tagUpperBound()
  local out = {}
  for i = 0, rgc - 1 do
    local o = rp(rgd + 8 * i)
    if O.kptr(o) and rp(o) == BASE + GAME.layout.vt.CRailwayGun then
      -- definition: scoped ptr @+312 → token u32 @p+8
      local dpp = rp(o + 312)
      local geq = rp(o + 912)
      -- combat: {d@1056, c@1068} 8B 内联 idpair {type@0, id@4}
      local combat
      do
        local cbt = ru32(o + 1068)
        if cbt and cbt > 0 and cbt < LAYOUT.lim.PTR_SANE then
          local cdd = rp(o + 1056)
          if O.kptr(cdd) then
            combat = {}
            for cj = 0, cbt - 1 do
              local ce = cdd + 8 * cj
              combat[#combat + 1] = { type = ru32(ce) or 0,
                id = ru32(ce + 4) or 0 }
            end
          end
        end
      end
      -- army: ptr @+1088 → 虚函数返 *(p-16) qword
      local army
      do
        local ap2 = rp(o + 1088)
        if O.kptr(ap2) then
          local q = rp(ap2 - 16)
          if q and q ~= 0 then
            army = { id = q >> 32, type = q % 2 ^ 32 } end
        end
      end
      -- path / full_path: {d@512/544, c@524/556} u32 密集元
      -- (full_path 外门 = c@556 ≠0, 双门原样)
      local path
      do
        local pd2, pc2 = rp(o + 512), ru32(o + 524)
        if O.kptr(pd2) and pc2 and pc2 > 0 and pc2 < 4096 then
          path = {}
          for pj = 0, pc2 - 1 do
            path[#path + 1] = ru32(pd2 + 4 * pj) or 0 end
        end
      end
      local full_path
      if (ru32(o + 556) or 0) ~= 0 then
        local fd2, fc2 = rp(o + 544), ru32(o + 556)
        if O.kptr(fd2) and fc2 and fc2 > 0 and fc2 < 4096 then
          full_path = {}
          for pj = 0, fc2 - 1 do
            full_path[#full_path + 1] = ru32(fd2 + 4 * pj) or 0 end
        end
      end
      -- expeditionary_owner / logical_country: tid 门 >0 且 <tagub,
      -- 串非空 (tag 串 = Runtime:tag 同源 read_str)
      local eo, lg = ru32(o + 476), ru32(o + 480)
      -- country_intel: {d@632, c@644} 24B 元 {u32@0, u32@8, u8@16}
      local intel
      do
        local cid, cic = rp(o + 632), ru32(o + 644)
        if O.kptr(cid) and cic and cic > 0
            and cic < LAYOUT.lim.PTR_SANE then
          intel = {}
          for k = 0, cic - 1 do
            local e = cid + 24 * k
            intel[#intel + 1] = { ru32(e) or 0, ru32(e + 8) or 0,
              ru8(e + 16) or 0 }
          end
        end
      end
      out[#out + 1] = {
        addr = o,
        definition_tok = O.kptr(dpp) and (ru32(dpp + 8) or 0) or nil,
        eq_type = ru32(o + 824) or 0, eq_id = ru32(o + 828) or 0,
        name_type = ru32(o + 840),
        name_order = (function() local v = ru32(o + 960)
          return (v and v ~= 0) and v or nil end)(),
        name_ordered_no = (ru8(o + 1000) or 0) == 0,
        override_gate = O.kptr(rp(o + 984)),
        override = U.sso(o + 968),
        osp = (ru8(o + 1001) or 0) ~= 0,
        name_eq = O.kptr(geq)
          and { type = ru32(geq + 8) or 0, id = ru32(geq + 12) or 0 }
          or nil,
        strength = (rp(o + 1008) or 0) / 100000,
        manpower = ru32(o + 1016),
        max_supply = (rp(o + 1024) or 0) / 100000,
        supply_ratio = (rp(o + 1040) or 0) / 100000,
        supply_gain = (rp(o + 1032) or 0) / 100000,
        repair_line = ((ru32(o + 1048) or 0) ~= 0
            or (ru32(o + 1052) or 0) ~= 0)
          and { type = ru32(o + 1048) or 0, id = ru32(o + 1052) or 0 }
          or nil,
        combat = combat, army = army,
        id_type = ru32(o + 24) or 0, id_id = ru32(o + 28) or 0,
        name = U.sso(o + 600),
        previous = O.kptr(rp(o + 504))
          and (ru32(rp(o + 504) + 164) or 0) or nil,
        experience = O.kptr(rp(o + 488))
          and (ru32(rp(o + 488) + 164) or 0) or nil,
        last_combat_h = (function() local v = ru32(o + 456)
          return (v and v ~= 0) and v or nil end)(),
        movement_progress = (function() local v = rp(o + 576)
          return (v and v ~= 0) and v / 100000 or nil end)(),
        move_priority_raw = ru32(o + 584),
        path = path, full_path = full_path,
        location = O.kptr(rp(o + 496))
          and (ru32(rp(o + 496) + 164) or 0) or nil,
        retreat = (ru8(o + 588) or 0) ~= 0,
        withdraw = (ru8(o + 589) or 0) ~= 0,
        start_h = (function() local v = ru32(o + 328)
          if not v then return nil end
          v = LAYOUT.as_i32(v)
          return (v - 43800000 >= 17520) and v or nil end)(),
        end_h = (function() local v = ru32(o + 352)
          if not v then return nil end
          v = LAYOUT.as_i32(v)
          return (v - 43800000 >= 17520) and v or nil end)(),
        is_buildable = (function() local v = ru32(o + 304)
          return (v and v > 0) and v or nil end)(),
        unused_token = (function() local v = ru32(o + 304)
          return (v and v > 0) and (ru32(o + 308) or 0) or nil end)(),
        expeditionary_owner = (eo and eo > 0 and eo < tagub)
          and Runtime:tag(eo) or nil,
        logical_country = (lg and lg > 0 and lg < tagub)
          and Runtime:tag(lg) or nil,
        alliance = (function() local v = ru32(o + 696)
          return (v and v ~= 0) and v or nil end)(),
        clear_queued = (function() local v = ru32(o + 700)
          return (v and v ~= 0) and v or nil end)(),
        exile = (ru8(o + 686) or 0) ~= 0,
        move_capital = (ru8(o + 688) or 0) ~= 0,
        seed = (function() local v = ru32(o + 808)
          return (v and v ~= 0) and v or nil end)(),
        raid = ((ru32(o + 812) or 0) ~= 0 or (ru32(o + 816) or 0) ~= 0)
          and { type = ru32(o + 812) or 0, id = ru32(o + 816) or 0 }
          or nil,
        intel = intel }
    end
  end
  return out
end

-- ============================================================
-- 14.7 combat 导出全量 reader (§4.22; sv2_sec_combat 只持写序/块键/编号/
-- 值格式化)。writer 忠实; 与 §14.1-14.4 旧探针形访问器并存。
-- 复用: SNavalHit 布局 §4.22.5 ≡ §4.22.6 (ncr_naval_hits); SAirHit 的
-- tag 门两段不同 (combat qtag 无 0 门 — tid=0 读槽 0 = "---" 照发射)
-- 故 cbt_air_hits 单列; cached_info 门亦有差 → cbt_cached。
-- 哨兵: dword_143086B20 (air date) / qword_14333D528 (空 id 对)。
local function cbt_fix5(a)
  local r = GAME.layout.i64(a)
  return r and (r / 100000) or nil
end

local function cbt_tagraw(tid)          -- §1.2 tag 串表 (combat qtag 语义:
  if not tid then return nil end        --   无 0 门, 槽 0 = "---")
  local tt = rp(Runtime.gs() + 0x358)
  if not O.kptr(tt) then return nil end
  return hoi4.read_str(tt + 32 * tid)
end

-- §4.22.4 SCombatSideData 侧数据 (combat_side_data / combat_data 双侧共用;
-- writer 0x140CD15D0)。池以基址交段层 SL.pool_emit_gated (布局住共享件)。
local function cbt_side_data(S)
  if not O.kptr(S) then return nil end
  local rec = {
    equipment_lost = S + 24, equipment_captured = S + 344,
    equipment_recovered = S + 408 }
  local v = ru32(S + 8)
  if v and v > 0 then rec.manpower_lost = v end
  local f = cbt_fix5(S + 16)
  if f and f > 0 then rec.manpower_lost_air_factor = f end
  local lt, li = ru32(S + 520) or 0, ru32(S + 524) or 0
  if lt ~= 0 or li ~= 0 then rec.leader = { type = lt, id = li } end
  -- tags: u32 tid 数组 → 槽序 (qtag 无 0 门; 解析失败槽占号不发射)
  local d, n = rp(S + 496), ru32(S + 508) or 0
  if O.kptr(d) and n > 0 then
    local tags = {}
    for i = 0, math.min(n, 64) - 1 do
      tags[i + 1] = cbt_tagraw(ru32(d + 4 * i))
    end
    rec.tags = tags
  end
  return rec
end

-- §4.22.4 CActivityInGroup 条目 (log.group; writer 0x140CD0980)
local function cbt_group(ge)
  local rec = { group_type = ru32(ge + 8) or 0, group_id = ru32(ge + 12) or 0 }
  local d, n = rp(ge + 16), ru32(ge + 28) or 0
  if O.kptr(d) and n > 0 then
    rec.division_templates = {}
    for i = 0, math.min(n, 256) - 1 do
      rec.division_templates[#rec.division_templates + 1] = {
        type = ru32(d + 8 * i) or 0, id = ru32(d + 8 * i + 4) or 0 }
    end
  end
  d, n = rp(ge + 40), ru32(ge + 52) or 0 -- enemy_dmg 16B {对, fixed}
  if O.kptr(d) and n > 0 then
    rec.enemy_dmg = {}
    for i = 0, math.min(n, 256) - 1 do
      local e = d + 16 * i
      rec.enemy_dmg[#rec.enemy_dmg + 1] = {
        unit_type = ru32(e) or 0, unit_id = ru32(e + 4) or 0,
        value = (GAME.layout.i64(e + 8) or 0) / 100000 }
    end
  end
  rec.damaged_equipment = ge + 64
  local tid = ru32(ge + 128) or 0     -- writer 0x140BA6770 门 = tid > 0
  if tid > 0 then rec.damage_dealer = cbt_tagraw(tid) end
  tid = ru32(ge + 132) or 0
  if tid > 0 then rec.damage_taker = cbt_tagraw(tid) end
  return rec
end

-- §4.22.4 NCombatLog::CStatsObserver log 对象 (内嵌@cb+464, writer 0x140CD1240)
local function cbt_log(lb)
  local rec = {}
  local d, n = rp(lb + 8), ru32(lb + 20) or 0
  if O.kptr(d) and n > 0 then
    rec.groups = {}
    for i = 0, math.min(n, 256) - 1 do
      local ge = rp(d + 8 * i)
      if O.kptr(ge) then rec.groups[#rec.groups + 1] = cbt_group(ge) end
    end
  end
  rec.combat_side_data = cbt_side_data(lb + 88)
  d, n = rp(lb + 32), ru32(lb + 44) or 0 -- leader_hours 12B 条
  if O.kptr(d) and n > 0 then
    rec.leader_hours = {}
    for i = 0, math.min(n, 256) - 1 do
      local e = d + 12 * i
      rec.leader_hours[#rec.leader_hours + 1] = {
        type = ru32(e) or 0, id = ru32(e + 4) or 0,
        time = ru32(e + 8) or 0 }
    end
  end
  d, n = rp(lb + 56), ru32(lb + 68) or 0 -- damage 32B 条
  if O.kptr(d) and n > 0 then
    rec.damages = {}
    for i = 0, math.min(n, 256) - 1 do
      local e = d + 32 * i
      rec.damages[#rec.damages + 1] = {
        from = cbt_tagraw(ru32(e + 8)),
        receiver = cbt_tagraw(ru32(e + 12)),
        to = cbt_tagraw(ru32(e + 16)),
        value = (GAME.layout.i64(e + 24) or 0) / 100000 }
    end
  end
  local f = cbt_fix5(lb + 80)
  if f and f > 0 then rec.total_damage = f end
  do                              -- modifier_hours 恒写 30 元 u32
    local t = {}
    for i = 0, 29 do t[#t + 1] = ru32(lb + 624 + 4 * i) or 0 end
    rec.modifier_hours = t
  end
  local bits = ru8(lb + 744) or 0
  rec.snow = (bits & 1) ~= 0
  rec.win = (bits & 2) ~= 0
  f = cbt_fix5(lb + 616)
  if f and f > 0 then rec.progress = f end
  return rec
end

-- §4.22.5 SAirHit 条目 (writer 0x1415B5760) — tag = combat qtag 语义 (无 0 门)
local function cbt_air_hits(d, c)
  if not O.kptr(d) or not c or c <= 0 then return nil end
  local out = {}
  for k = 0, math.min(c, LAYOUT.lim.PTR_SANE) - 1 do
    local en = rp(d + 8 * k)
    if O.kptr(en) then
      local ev = rp(en + 8)
      out[#out + 1] = {
        tag = cbt_tagraw(ru32(en + 0x14)),
        var_type = O.kptr(ev) and (ru32(ev + 8) or 0) or nil,
        var_id = O.kptr(ev) and (ru32(ev + 12) or 0) or nil,
        count = ru32(en + 0x10) or 0 }
    end
  end
  return out
end

-- §4.22.4 CCombatant/CLandCombatant 参战方 (writer 0x1413CEED0 + 0x1412A8760)
local function cbt_combatant(cb, dflt_date)
  if not O.kptr(cb) then return nil end
  local rec = { addr = cb }
  -- id 对列表 (unit/front/reserves/retreat): 8B 指针, 对内联@elem+24;
  -- 重复块 = 裸名重复 (multiset) 不编号
  local function reflist(off_d, off_c, key)
    local d, n = rp(cb + off_d), ru32(cb + off_c) or 0
    if O.kptr(d) and n > 0 then
      local lst = {}
      for i = 0, math.min(n, 256) - 1 do
        local u = rp(d + 8 * i)
        if O.kptr(u) then
          lst[#lst + 1] = { type = ru32(u + 24) or 0,
            id = ru32(u + 28) or 0 }
        end
      end
      rec[key] = lst
    end
  end
  reflist(32, 44, "units")
  rec.losses = cbt_fix5(cb + 184) or 0 -- 恒写 (SL.num(fix5 or 0))
  local d, n = rp(cb + 160), ru32(cb + 172) or 0 -- size
  if O.kptr(d) and n > 0 then
    local t = {}
    for i = 0, math.min(n, 512) - 1 do
      t[#t + 1] = (GAME.layout.i64(d + 8 * i) or 0) / 100000
    end
    rec.size = t
  end
  rec.has_flanked = (ru8(cb + 219) or 0) ~= 0
  local lh = ru32(cb + 224)
  if lh and lh > 0 then rec.last_hit = cbt_tagraw(lh) end
  local f = cbt_fix5(cb + 16)
  if f and f > 0 then rec.shore_bombardment_factor = f end
  local v = ru32(cb + 352)
  if v and v > 0 and v < 0x80000000 then rec.air_kills = v end
  local function posfix(off)
    local x = cbt_fix5(cb + off)
    return (x and x > 0) and x or nil
  end
  rec.air_damage_str = posfix(360)
  rec.air_damage_org = posfix(368)
  rec.ground_damage_str = posfix(376)
  rec.ground_damage_org = posfix(384)
  rec.prevented_damage_str = posfix(392)
  rec.prevented_damage_org = posfix(400)
  rec.anti_air_attack = posfix(344)
  reflist(232, 244, "fronts")
  reflist(256, 268, "reserves")
  reflist(280, 292, "retreats")
  d, n = rp(cb + 320), ru32(cb + 332) or 0 -- §4.22.4 CAirInLandCombat 8B 指针
  if O.kptr(d) and n > 0 then
    rec.air_planes = {}
    for i = 0, math.min(n, 256) - 1 do
      local A = rp(d + 8 * i)
      if O.kptr(A) then
        local h = ru32(A + 40)
        rec.air_planes[#rec.air_planes + 1] = {
          date_h = (h and h ~= dflt_date) and h or nil,
          amount = ru32(A + 20) or 0,
          wing_type = ru32(A + 8) or 0, wing_id = ru32(A + 12) or 0,
          air_count = ru32(A + 16) or 0,
          damage_factor = (GAME.layout.i64(A + 24) or 0) / 100000 }
      end
    end
  end
  local tac = rp(cb + 304) -- §4.22.7 CCombatTactic ref
  if O.kptr(tac) then rec.tactic = ru32(tac + 152) or 0 end
  d, n = rp(cb + 408), ru32(cb + 420) or 0 -- org_loss_summary
  if O.kptr(d) and n > 0 then
    local t = {}
    for i = 0, math.min(n, 512) - 1 do
      t[#t + 1] = (GAME.layout.i64(d + 8 * i) or 0) / 100000
    end
    rec.org_loss_summary = t
  end
  d, n = rp(cb + 432), ru32(cb + 444) or 0 -- str_loss_summary
  if O.kptr(d) and n > 0 then
    local t = {}
    for i = 0, math.min(n, 512) - 1 do
      t[#t + 1] = (GAME.layout.i64(d + 8 * i) or 0) / 100000
    end
    rec.str_loss_summary = t
  end
  rec.org_loss_summary_index = ru32(cb + 456) or 0
  rec.num_org_losses = ru32(cb + 460) or 0
  -- §4.22.4 weighted_participants RH 表 @cb+128: data@+136, 计数@+144,
  -- 掩码 u32@+148, extra u8@+152; 桶 24B {dist@+4, tag@+8, weight@+16};
  -- 发射序 = 桶序 (writer sub_1413E41F0 → sub_1411DCF90, 无排序)
  do
    local wd = rp(cb + 136)
    local wcnt = ru32(cb + 144) or 0
    local wmask = ru32(cb + 148) or 0
    local wextra = ru8(cb + 152) or 0
    if O.kptr(wd) and wcnt > 0 and wcnt < 4096 then
      local nb = wmask + 1 + wextra
      local wp = {}
      for bi = 0, math.min(nb, 65536) - 1 do
        local b = wd + 24 * bi
        if (ru8(b + 4) or 0) ~= 0 then
          local tgs = cbt_tagraw(ru32(b + 8) or 0)
          if tgs then
            wp[#wp + 1] = { tag = tgs, weight = cbt_fix5(b + 16) or 0 }
          end
        end
      end
      rec.weighted_participants = wp
    end
  end
  rec.log = cbt_log(cb + 464)
  return rec
end

-- §4.22.2 CLandBorderWarCombatant 边界战参战方扩展 (writer 0x1413F0100)
local function cbt_bw_side(cb)
  if not O.kptr(cb) then return nil end
  local rec = {}
  local tid = ru32(cb + 1216) or 0
  rec.tag = (tid == 0) and "---" or cbt_tagraw(tid)
  local sp = rp(cb + 1224)
  if O.kptr(sp) then rec.state = ru32(sp + 88) or 0 end
  local d, n = rp(cb + 1232), ru32(cb + 1244) or 0
  if O.kptr(d) and n > 0 then
    rec.provinces = {}
    for i = 0, math.min(n, 64) - 1 do
      local pe = rp(d + 8 * i)
      if O.kptr(pe) then
        rec.provinces[#rec.provinces + 1] = ru32(pe + 164) or 0 end
    end
  end
  rec.orders_group = { type = ru32(cb + 1256) or 0,
    id = ru32(cb + 1260) or 0 }
  rec.max_units = ru32(cb + 1264) or 0
  rec.modifier = (GAME.layout.i64(cb + 1272) or 0) / 100000
  rec.dig_in_factor = (GAME.layout.i64(cb + 1376) or 0) / 100000
  rec.terrain_factor = (GAME.layout.i64(cb + 1384) or 0) / 100000
  local s = U.sso(cb + 1280)
  if s and s ~= "" then rec.on_win = s end
  s = U.sso(cb + 1312)
  if s and s ~= "" then rec.on_lose = s end
  s = U.sso(cb + 1344)
  if s and s ~= "" then rec.on_cancel = s end
  d, n = rp(cb + 1392), ru32(cb + 1404) or 0 -- removed_unit 12B 条
  if O.kptr(d) and n > 0 then
    rec.removed_units = {}
    for i = 0, math.min(n, 256) - 1 do
      local en = d + 12 * i
      rec.removed_units[#rec.removed_units + 1] = {
        type = ru32(en) or 0, id = ru32(en + 4) or 0,
        hours = ru32(en + 8) or 0 }
    end
  end
  return rec
end

-- §4.22.5 member.cached_info (SCachedInfo 内嵌@m+24, writer 0x141962D80)。
-- ⚠ 门与 §4.22.6 形有差: equipment_variant/sunk_by/ship 有 size u32 前门。
local function cbt_cached(ci, nullref)
  local rec = {
    sprite = U.sso(ci + 112),
    index = ru32(ci + 12) or 0,
    type = ru32(ci + 16) or 0,
    tag = cbt_tagraw(ru32(ci + 8)) }
  local f = cbt_fix5(ci + 32)
  if f and f ~= 0 then rec.strength = f end
  if (ru32(ci + 160) or 0) ~= 0 then
    local s = U.sso(ci + 144)
    if s and s ~= "" then rec.sunk_by = s end
  end
  rec.convoy = (ru8(ci + 41) or 0) ~= 0
  f = cbt_fix5(ci + 24)
  if f and f ~= 0 then rec.build_cost_ic = f end
  if (ru32(ci + 96) or 0) ~= 0 then
    local s = U.sso(ci + 80)
    if s and s ~= "" then rec.equipment_variant = s end
  end
  local t, i = ru32(ci + 176) or 0, ru32(ci + 180) or 0
  local lo = nullref and (nullref % 4294967296) or -1
  local hi = nullref and math.floor(nullref / 4294967296) or -1
  if t ~= lo or i ~= hi then
    rec.hev_type = t
    rec.hev_id = i
  end
  if (ru32(ci + 64) or 0) ~= 0 then
    local s = U.sso(ci + 48)
    if s and s ~= "" then rec.ship = s end
  end
  rec.potf = (ru8(ci + 40) or 0) ~= 0
  t, i = ru32(ci + 184) or 0, ru32(ci + 188) or 0
  if t ~= 0 or i ~= 0 then
    rec.convoy_id_type = t
    rec.convoy_id_id = i
  end
  local v = ru32(ci + 192) or 0xFFFFFFFF
  if v < 0x80000000 then rec.convoy_index = v end
  return rec
end

-- §4.22.5 CFEXMember member 条目 (writer 0x1419760B0)
local function cbt_naval_member(m, nullref)
  if not O.kptr(m) then return nil end
  local rec = { unique_id = ru32(m + 288) or 0 }
  local t, i = ru32(m + 8) or 0, ru32(m + 12) or 0
  if t ~= 0 or i ~= 0 then rec.ship = { type = t, id = i } end
  t, i = ru32(m + 16) or 0, ru32(m + 20) or 0
  if t ~= 0 or i ~= 0 then rec.convoy = { type = t, id = i } end
  rec.state = ru32(m + 224) or 0
  rec.hours_to_arrive = ru32(m + 228) or 0
  do                                    -- cooldown 恒写 3 元 fixed5
    local t2 = {}
    for q = 0, 2 do
      t2[#t2 + 1] = (GAME.layout.i64(m + 240 + 8 * q) or 0) / 100000
    end
    rec.cooldown = t2
  end
  rec.cached_info = cbt_cached(m + 24, nullref)
  local v = ru32(m + 292) or 0
  if v > 0 then rec.critical_hits_received = v end
  rec.naval_hits = ncr_naval_hits(rp(m + 384), ru32(m + 396) or 0)
  rec.air_hits = cbt_air_hits(rp(m + 336), ru32(m + 348) or 0)
  v = ru32(m + 296) or 0
  if v ~= 0 then rec.evacuated = v end
  v = ru32(m + 300) or 0xFFFFFFFF
  if v ~= 0xFFFFFFFF then rec.hidden = v end
  local f = cbt_fix5(m + 304)
  if f and f ~= 0 then rec.escape_progress = f end
  do                                    -- damage_received_by_gun_types 恒写 6 元
    local t2 = {}
    for q = 0, 5 do
      t2[#t2 + 1] = (GAME.layout.i64(m + 408 + 8 * q) or 0) / 100000
    end
    rec.gun_type_damage = t2
  end
  local d, n = rp(m + 264), ru32(m + 276) or 0 -- damage_received 32B
  if O.kptr(d) and n > 0 then
    rec.damage_received = {}
    for q = 0, math.min(n, 64) - 1 do
      local e = d + 32 * q
      rec.damage_received[#rec.damage_received + 1] = {
        ship_type = ru32(e + 8) or 0, ship_id = ru32(e + 12) or 0,
        tag = cbt_tagraw(ru32(e + 16)),
        damage = cbt_fix5(e + 24) or 0 }
    end
  end
  if (ru8(m + 328) or 0) ~= 0 then      -- last_target (lt=m+312)
    rec.last_target = { convoy = (ru8(m + 320) or 0) ~= 0,
      size = ru32(m + 324) or 0 }
  end
  return rec
end

-- §4.22.5 CFEXAir group air 条目 (writer 0x14197D990)
local function cbt_naval_air(ae)
  if not O.kptr(ae) then return nil end
  local rec = { tag = cbt_tagraw(ru32(ae + 100)) }
  local t, i = ru32(ae + 28) or 0, ru32(ae + 32) or 0
  if t ~= 0 or i ~= 0 then rec.air_base = { type = t, id = i } end
  local d, n = rp(ae + 64), ru32(ae + 76) or 0 -- air_wing 内联对
  if O.kptr(d) and n > 0 then
    rec.air_wings = {}
    for q = 0, math.min(n, 256) - 1 do
      rec.air_wings[#rec.air_wings + 1] = { type = ru32(d + 8 * q) or 0,
        id = ru32(d + 8 * q + 4) or 0 }
    end
  end
  d, n = rp(ae + 40), ru32(ae + 52) or 0 -- naval_strike 内联对
  if O.kptr(d) and n > 0 then
    rec.naval_strikes = {}
    for q = 0, math.min(n, 256) - 1 do
      rec.naval_strikes[#rec.naval_strikes + 1] = {
        type = ru32(d + 8 * q) or 0, id = ru32(d + 8 * q + 4) or 0 }
    end
  end
  n = ru32(ae + 180) or 0               -- names 32B 串数组 (空串照收)
  d = rp(ae + 168)
  if O.kptr(d) and n > 0 then
    local tt2 = {}
    for q = 0, math.min(n, 64) - 1 do
      local nm = U.sso(d + 32 * q)
      if nm then tt2[#tt2 + 1] = nm end
    end
    if #tt2 > 0 then rec.names = tt2 end
  end
  rec.max = ru32(ae + 88) or 0
  rec.alive = ru32(ae + 92) or 0
  rec.casualties = ru32(ae + 96) or 0
  rec.last_external_wave_h = ru32(ae + 112) -- C 族 date_quoted 无滤
  rec.external_wave_complete = ru8(ae + 128) or 0  -- 原字节 (段层 yn)
  rec.time_duration = ru32(ae + 248) or 0
  rec.external = ru8(ae + 129) or 0
  rec.name = U.sso(ae + 136)
  rec.damage_mult = cbt_fix5(ae + 192) or 0
  rec.naval_hits = ncr_naval_hits(rp(ae + 256), ru32(ae + 268) or 0)
  rec.air_hits = cbt_air_hits(rp(ae + 280), ru32(ae + 292) or 0)
  local v = ru32(ae + 24) or 0xFFFFFFFF
  if v ~= 0xFFFFFFFF then rec.carrier = v end
  return rec
end

-- §4.22.5 CFEXGroup group 条目 (writer 0x141C58360)
local function cbt_naval_group(g, nullref)
  if not O.kptr(g) then return nil end
  local rec = {}
  local d, n = rp(g + 8), ru32(g + 20) or 0 -- member 指针数组
  if O.kptr(d) and n > 0 then
    rec.members = {}
    for q = 0, math.min(n, 1024) - 1 do
      local m = cbt_naval_member(rp(d + 8 * q), nullref)
      if m then rec.members[#rec.members + 1] = m end
    end
  end
  d, n = rp(g + 88), ru32(g + 100) or 0 -- air 指针数组
  if O.kptr(d) and n > 0 then
    rec.airs = {}
    for q = 0, math.min(n, 256) - 1 do
      local ae = cbt_naval_air(rp(d + 8 * q))
      if ae then rec.airs[#rec.airs + 1] = ae end
    end
  end
  -- opponent_group: oppg 在母 combatant group 数组 {d@+232,c@+244} 的下标
  local oppg = rp(g + 32)
  if O.kptr(oppg) then
    local oc = rp(oppg + 56)
    local od = oc and rp(oc + 232)
    local on = oc and (ru32(oc + 244) or 0)
    if O.kptr(od) and on and on > 0 and on < 64 then
      for q = 0, on - 1 do
        if rp(od + 8 * q) == oppg then
          rec.opponent_group = q
          break
        end
      end
    end
  end
  rec.forces_compare = cbt_fix5(g + 48) or 0
  rec.disengage_counter = ru32(g + 64) or 0
  rec.chasing_counter = ru32(g + 68) or 0
  return rec
end

-- §4.22.5 CNavalCombatant 海战参战方 (writer 0x14160FF40)
local function cbt_naval_side(cb, nullref)
  if not O.kptr(cb) then return nil end
  local rec = {}
  local d, n = rp(cb + 32), ru32(cb + 44) or 0 -- unit (裸名重复)
  if O.kptr(d) and n > 0 then
    rec.units = {}
    for q = 0, math.min(n, 256) - 1 do
      local u = rp(d + 8 * q)
      if O.kptr(u) then
        rec.units[#rec.units + 1] = { type = ru32(u + 24) or 0,
          id = ru32(u + 28) or 0 }
      end
    end
  end
  d, n = rp(cb + 232), ru32(cb + 244) or 0 -- group[N]
  if O.kptr(d) and n > 0 then
    rec.groups = {}
    for q = 0, math.min(n, 64) - 1 do
      local g2 = cbt_naval_group(rp(d + 8 * q), nullref)
      if g2 then rec.groups[#rec.groups + 1] = g2 end
    end
  end
  local ll = rp(cb + 312) -- last_leader → 对@ptr+8
  if O.kptr(ll) then
    rec.last_leader = { type = ru32(ll + 8) or 0, id = ru32(ll + 12) or 0 }
  end
  rec.disengage = (ru8(cb + 320) or 0) ~= 0
  rec.anti_air = cbt_fix5(cb + 368) or 0
  rec.positioning = cbt_fix5(cb + 344) or 0
  local f = cbt_fix5(cb + 352)
  if f and f ~= 0 then rec.new_ships_positioning_penalty = f end
  rec.total_damage_dealt = cbt_fix5(cb + 384) or 0
  rec.total_initial_strength = cbt_fix5(cb + 376) or 0
  rec.positioning_dominance_bonus = cbt_fix5(cb + 360) or 0
  do                                    -- gun types 恒写 36 元 (1.19.3 +32)
    local t2 = {}
    for q = 0, 35 do
      t2[#t2 + 1] = (GAME.layout.i64(cb + 392 + 8 * q) or 0) / 100000
    end
    rec.gun_type_damage = t2
  end
  -- damage_dealt_by_ship_types: 侵入链表 (头=哨兵, next@0), 键 = token
  if (ru32(cb + 696) or 0) ~= 0 then
    local head = rp(cb + 688)
    local node = head and rp(head)
    local guard = 0
    local st = {}
    while O.kptr(node) and node ~= head
        and guard < LAYOUT.lim.PTR_SANE do
      local tk = ru32(node + 16)
      local nm = tk and (GAME.layout.token_name(tk) or tk)
      if nm then
        st[#st + 1] = { name = nm, value = cbt_fix5(node + 24) or 0 }
      end
      node = rp(node)
      guard = guard + 1
    end
    rec.ship_type_damage = st
  end
  return rec
end

-- §4.22.5 convoy 条目 (无独立 RTTI 类; writer 0x141AD8690)
local function cbt_convoy_entry(cv)
  if not O.kptr(cv) then return nil end
  local rec = { id_type = ru32(cv + 8) or 0, id_id = ru32(cv + 12) or 0 }
  local v4 = rp(cv + 24)
  if O.kptr(v4) then
    rec.var_type = ru32(v4 + 8) or 0
    rec.var_id = ru32(v4 + 12) or 0
  end
  rec.strength = cbt_fix5(cv + 32) or 0
  rec.organisation = cbt_fix5(cv + 40) or 0
  local t1, i1 = ru32(cv + 48) or 0, ru32(cv + 52) or 0
  local t2, i2 = ru32(cv + 56) or 0, ru32(cv + 60) or 0
  -- tag 三段链 (client 对 → obj+24 | transfer 对 → obj+88 | 兜底+64)
  local tid
  if t1 ~= 0 or i1 ~= 0 then
    local o = GAME.layout.idreg_unit_resolve(t1, i1)
    if o then tid = ru32(o + 24) end
  end
  if not tid then
    if t2 ~= 0 or i2 ~= 0 then
      local o = GAME.layout.idreg_unit_resolve(t2, i2)
      if o then tid = ru32(o + 88) end
    end
  end
  if not tid then tid = ru32(cv + 64) end
  if tid and tid > 0 then rec.tag = cbt_tagraw(tid) end
  if (t2 ~= 0 or i2 ~= 0)
      and GAME.layout.idreg_unit_resolve(t2, i2) then
    rec.transfer_navy = { type = t2, id = i2 }
  end
  if (t1 ~= 0 or i1 ~= 0)
      and GAME.layout.idreg_unit_resolve(t1, i1) then
    rec.client = { type = t1, id = i1 }
  end
  rec.convoy_index = ru32(cv + 68) or 0
  return rec
end

-- 容器包装 → 参战基址 (§4.22.3 侧容器解引用; cont[0] 属映像区间判 vtable)
local function cbt_combatant_base(c, side_off)
  local cont = rp(c + side_off)
  if not O.kptr(cont) then return nil end
  local d = rp(cont)
  local n = ru32(cont + 12)
  if d and d >= BASE and d < BASE + 0x37EC000 then return cont end
  if O.kptr(d) and n and n > 0 and n < 64 then
    local el = rp(d)
    if O.kptr(el) then return rp(el + 16) or el end
  end
  return cont
end

-- Runtime.combat_full -> {list, history}; kind = border/naval/land
function Runtime.combat_full(self)
  local g = self.gs()
  if not g or rp(g + 0x260) ~= BASE + GAME.layout.vt.CCombatManager then
    return nil
  end
  local dflt_date = ru32(BASE + 0x3086B20) -- §3.7a 门哨兵
  local nullref = rp(BASE + 0x333D528)
  local out = { list = {}, history = {} }
  local cd, cn = rp(g + 0x268), ru32(g + 0x274) or 0
  if O.kptr(cd) and cn > 0 then
    for k = 0, math.min(cn, 4096) - 1 do
      local e = rp(cd + 8 * k)
      if O.kptr(e) then
        local c = e + 16
        local day = ru32(c + 48) or 0
        local border = rp(e) == BASE + GAME.layout.vt.CLandBorderWarCombat
        local naval = (not border) and day > 0x7FFFFFFF
        local rec = { kind = border and "border" or naval and "naval" or "land",
          id_type = ru32(c + 8) or 0, id_id = ru32(c + 12) or 0 }
        local loc = rp(c + 40)
        if O.kptr(loc) then rec.location = ru32(loc + 164) or 0 end
        rec.day = day >= 0x80000000 and day - 0x100000000 or day
        rec.duration = ru32(c + 52) or 0
        if naval then
          -- §4.22.5 CNavalCombat (writer 0x1415C5BC0): 参战直指
          rec.naval = {
            attacker = cbt_naval_side(rp(c + 24), nullref),
            defender = cbt_naval_side(rp(c + 32), nullref) }
          local d2, n2 = rp(c + 200), ru32(c + 212) or 0
          if O.kptr(d2) and n2 > 0 then
            rec.naval.clients = {}
            for q = 0, math.min(n2, 64) - 1 do
              rec.naval.clients[#rec.naval.clients + 1] = {
                type = ru32(d2 + 8 * q) or 0,
                id = ru32(d2 + 8 * q + 4) or 0 }
            end
          end
          local nd, nn = rp(c + 224), ru32(c + 236) or 0
          if O.kptr(nd) and nn > 0 then
            rec.naval.naval_transports = {}
            for q = 0, math.min(nn, 64) - 1 do
              rec.naval.naval_transports[#rec.naval.naval_transports + 1] = {
                type = ru32(nd + 8 * q) or 0,
                id = ru32(nd + 8 * q + 4) or 0 }
            end
          end
          -- convoy[N]: 门 = 自有计数>0 且 (client 或 ntt 非空)
          local cn2 = ru32(c + 188) or 0
          if cn2 > 0 and ((n2 or 0) > 0 or (nn or 0) > 0) then
            local vd = rp(c + 176)
            if O.kptr(vd) then
              rec.naval.convoys = {}
              for q = 0, math.min(cn2, 256) - 1 do
                local cv = cbt_convoy_entry(rp(vd + 8 * q))
                if cv then rec.naval.convoys[#rec.naval.convoys + 1] = cv end
              end
            end
          end
          rec.naval.unique_id = ru32(c + 248) or 0
          rec.naval.port_strike = (ru8(c + 252) or 0) ~= 0
          rec.naval.naval_strike = (ru8(c + 253) or 0) ~= 0
          local sc = ru32(c + 256) or 0
          if sc > 0 then rec.naval.sunk_convoys = sc end
          rec.naval.hide = (ru8(c + 260) or 0) ~= 0
          rec.naval.convoy_combat = (ru8(c + 261) or 0) ~= 0
          rec.naval.progress = cbt_fix5(c + 264) or 0
        else
          local ab = cbt_combatant_base(c, 24)
          local db = cbt_combatant_base(c, 32)
          rec.attacker = cbt_combatant(ab, dflt_date)
          rec.defender = cbt_combatant(db, dflt_date)
          if border then
            -- §4.22.2 CLandBorderWarCombat 块扩展 (writer 0x1413F0070; 恒写)
            rec.bw_attacker = cbt_bw_side(ab)
            rec.bw_defender = cbt_bw_side(db)
            rec.combat_width = (GAME.layout.i64(c + 200) or 0) / 100000
            rec.combat_state = ru32(c + 208) or 0
            rec.minimum_duration_in_days = ru32(c + 212) or 0
            rec.start = GAME.layout.as_i32(ru32(c + 216) or 0)
            rec.change_state_after_war = (ru8(c + 224) or 0) == 1
          end
        end
        local tobj = rp(c + 56)
        if O.kptr(tobj) and ((ru32(tobj + 16) or 0) & 0xFF) ~= 0 then
          local s = hoi4.read_str(tobj + 24)
          if s and s ~= "" then rec.terrain = s end
        end
        out.list[#out.list + 1] = rec
      end
    end
  end
  -- §4.22.4 CCombatHistory (链表头@gs+0x288+8, 存档序 = 链表序;
  -- guard = PTR_SANE — 旧 128 大战截尾实证)
  local e = rp(g + 0x288 + 8)
  local guard = 0
  while O.kptr(e) and guard < LAYOUT.lim.PTR_SANE do
    local rec = { location = ru32(e + 44) or 0 }
    local s = cbt_tagraw(ru32(e + 36))
    if s then rec.attacker = s end
    s = cbt_tagraw(ru32(e + 40))
    if s then rec.defender = s end
    rec.end_h = ru32(e + 16)
    rec.type = ru32(e + 32) or 0
    out.history[#out.history + 1] = rec
    e = rp(e + 56)
    guard = guard + 1
  end
  return out
end

-- ============================================================
-- §4.16.13/§4.16.14 全局沉船历史族导出全量 reader
-- (sv2_sec_global_tails history/sunk_convoys_history 块消费)
local function gh_date3(h)
  if h == 43808760 then return "1.1.1.1" end
  return GAME.layout.date(h)
end
local function gh_idpair_at(el, off)  -- {type@off, id@off+4}; 双零不写
  local ty, id = ru32(el + off), ru32(el + off + 4)
  if (ty and ty ~= 0) or (id and id ~= 0) then
    return { type = ty or 0, id = id or 0 }
  end
  return nil
end

-- §4.16.13 CSunkShipInfo (挂 §1.2 +1424, count@+1436)
function Runtime.global_sunk_ships(self)
  local g = self.gs()
  local c = ru32(g + 1436)
  if not (c and c > 0 and c < LAYOUT.lim.PTR_HUGE) then return nil end
  local d = rp(g + 1424)
  if not O.kptr(d) then return nil end
  local out = {}
  for i = 0, c - 1 do
    local el = rp(d + 8 * i)
    if O.kptr(el) then
      local rec = { name = U.sso(el + 8), killer_name = U.sso(el + 40) }
      rec.country = Runtime:tag(ru32(el + 72) or 0)
      -- killer_country: tag 查表失败 → writer 字面量 "---" 恒写
      rec.killer_country = Runtime:tag(ru32(el + 76) or 0) or "---"
      rec.level = ru32(el + 120) or 0
      local def = rp(el + 104)
      if O.kptr(def) then
        rec.definition = GAME.layout.token_name(ru32(def + 8) or 0)
          or (ru32(def + 8) or 0)
      end
      def = rp(el + 112)
      if O.kptr(def) then
        rec.killer_definition = GAME.layout.token_name(ru32(def + 8) or 0)
          or (ru32(def + 8) or 0)
      end
      local loc = rp(el + 144)
      if O.kptr(loc) then rec.location = ru32(loc + 164) or 0 end
      rec.date_h = ru32(el + 88)   -- date3 无门
      rec.equipment_variant = gh_idpair_at(el, 124)
      rec.air_wing = gh_idpair_at(el, 132)
      rec.battle = { type = ru32(el + 152) or 0, id = ru32(el + 156) or 0 }
      rec.convoy = ru8(el + 160) or 0   -- 原字节 (段层 yn)
      out[#out + 1] = rec
    end
  end
  return out
end

-- §4.16.14 sunk_convoys_history (挂 §1.2 +1448, count@+1460)
function Runtime.global_sunk_convoys(self)
  local g = self.gs()
  local c = ru32(g + 1460)
  if not (c and c > 0 and c < 4096) then return nil end
  local d = rp(g + 1448)
  if not O.kptr(d) then return nil end
  local out = {}
  for i = 0, c - 1 do
    local el = rp(d + 8 * i)
    if O.kptr(el) then
      local t = Runtime:tag(ru32(el + 16) or 0)
      out[#out + 1] = { month = ru32(el + 8) or 0,
        convoys = ru32(el + 12) or 0,
        killer_country = t or "---",    -- 查表失败 = "---" 恒写
        owner = Runtime:tag(ru32(el + 20) or 0) }
    end
  end
  return out
end
