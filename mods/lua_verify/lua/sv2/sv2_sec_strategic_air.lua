-- sv2_sec_strategic_air.lua -- strategic_air 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "strategic_air", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local BASE, gs = ctx.BASE, ctx.gs
    -- §4.15.1 CStrategicAirManager (gs+1680; vt 0X29588F8)
    local mgr = gs and rp(gs + 0x690)
    if not (mgr and SL.kptr(mgr) and rp(mgr) == BASE + GAME.layout.vt.CStrategicAirMgr) then
        return
    end
    local VT_SAC, VT_POOL, VT_BASE, VT_ARC =
        0x29587d8, 0x297ae38, 0x2958780, 0x2958968
    local function E(path, val)
        if val ~= nil then emit("strategic_air", path, val) end
    end
    local function i64s(a)
        return GAME.layout.i64(a) or 0
    end
    local function fx(a) return SL.num(i64s(a) / 1e5) end -- fixed5 叶
    local function tagstr(tid)
        if not tid or tid == 0 then return nil end
        return O:tag(tid)
    end

    -- ===== §4.15.1 CNonstaticIdGenerator: air_theatre_index / air_group_index (SAIDX) =====
    E("air_theatre_index.id", SL.num(ru32(mgr + 0x18) or 0))
    E("air_group_index.id", SL.num(ru32(mgr + 0x28) or 0))

    -- ===== §4.15.8 CAirBase 族 (州/载具/火箭/炮位基地; 容器挂 §4.15.1) =====
    local bases = {}
    do
        local d, c = rp(mgr + 0x90), ru32(mgr + 0x9C)
        if SL.kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_HUGE then
            for i = 0, c - 1 do
                local p = rp(d + 8 * i)
                if SL.kptr(p) and rp(p) == BASE + VT_BASE then
                    bases[#bases + 1] = p
                end
            end
        end
        local d2, c2 = rp(mgr + 0xD8), ru32(mgr + 0xE4)
        if SL.kptr(d2) and c2 and c2 > 0 and c2 < GAME.layout.lim.PTR_HUGE then
            for i = 0, c2 - 1 do
                local p = rp(d2 + 8 * i)
                if SL.kptr(p) then bases[#bases + 1] = p end
            end
        end
        -- §4.15.1 火箭基地并列阵列 (writer 0x140C57520 a1+160/
        -- +172 → mgr+0xA8/+0xB4, 同 CAirBase 类, base@124==1 →
        -- rocket_site 块键)
        local d3, c3 = rp(mgr + 0xA8), ru32(mgr + 0xB4)
        if SL.kptr(d3) and c3 and c3 > 0 and c3 < GAME.layout.lim.PTR_HUGE then
            for i = 0, c3 - 1 do
                local p = rp(d3 + 8 * i)
                if SL.kptr(p) and rp(p) == BASE + VT_BASE then
                    bases[#bases + 1] = p
                end
            end
        end
        -- §4.15.1 巨型炮阵地 (mega_gun_emplacement, 建筑 gun_emplacement=yes)
        -- writer 同 0x140C57520 a1+184/+196 → mgr+0xC0/+0xCC,
        -- base@124==2 → gun_emplacement 块键 (1.19.3 原版活体定案)
        local d4, c4 = rp(mgr + 0xC0), ru32(mgr + 0xCC)
        if SL.kptr(d4) and c4 and c4 > 0 and c4 < GAME.layout.lim.PTR_HUGE then
            for i = 0, c4 - 1 do
                local p = rp(d4 + 8 * i)
                if SL.kptr(p) then bases[#bases + 1] = p end
            end
        end
    end
    local seq_ab = SL.seqc()
    local seq_rs = SL.seqc()
    local seq_ge = SL.seqc()
    for _, ba in ipairs(bases) do
        -- §4.15.8 CAirBase base@ba+124: ==1 → 块键 rocket_site (0x33F7=
        -- 13303), ==2 → gun_emplacement (0x2766=10086), 否则 air_base
        -- (0x2FB6=12214) — 同列表同对象布局, manager writer 0x140C57520
        -- 尾段分支
        local b124 = ru32(ba + 124) or 0
        local bk = (b124 == 2) and seq_ge("gun_emplacement")
            or (b124 == 1) and seq_rs("rocket_site") or seq_ab("air_base")
        local function B(path, val) E(bk .. "." .. path, val) end
        B("id", SL.idpair(ru32(ba + 12), ru32(ba + 8)))
        local sp = rp(ba + 104)
        if SL.kptr(sp) then
            B("state", SL.num(ru32(sp + 88)))
        else
            B("carrier", SL.idpair(ru32(ba + 100), ru32(ba + 96)))
        end
        B("capacity", SL.num(ru32(ba + 120)))
        -- §4.15.9 CCountryAirContainer countries 指针元
        local cd, cn = rp(ba + 72), ru32(ba + 84)
        if SL.kptr(cd) and cn and cn > 0 and cn < 4096 then
            local seq_c = SL.seqc()
            for i = 0, cn - 1 do
                local cp = rp(cd + 8 * i)
                if SL.kptr(cp) then
                    local ck = seq_c(bk .. ".countries")
                    local function C(path, val) E(ck .. "." .. path, val) end
                    C("id", SL.idpair(ru32(cp + 12), ru32(cp + 8)))
                    if i64s(cp + 160) > 0 then
                        C("disrupted_supply", fx(cp + 160))
                    end
                    C("motorization_level", SL.num(ru8(cp + 29) or 0))
                    C("country", SL.Q(tagstr(ru32(cp + 176))))
                    if i64s(cp + 208) ~= 100000 then
                        C("operational_status", fx(cp + 208))
                    end
                    if i64s(cp + 216) ~= 0 then
                        C("capacity_penalty", fx(cp + 216))
                    end
                    if i64s(cp + 224) ~= 0 then
                        C("fuel_consumption", fx(cp + 224))
                    end
                    if i64s(cp + 240) ~= 0 then C("received", fx(cp + 240)) end
                    if i64s(cp + 232) ~= 0 then
                        C("base_fuel_consumption", fx(cp + 232))
                    end
                end
            end
        end
        B("base", SL.num(ru32(ba + 124) or 0))
        local hm = ru8(ba + 128)
        if hm and hm ~= 0 then
            B("has_manpower_for_recruit_change_to", SL.num(hm))
        end
        B("level", SL.num(ru32(ba + 132)))
        B("allow_equipment_type", tostring(rp(ba + 136) or 0))
    end

    -- §4.15.4 CAirWing transferring_to id 对解析 (§4.1.7 三注册表源
    -- RH 槽表 base+0x3451DC0, 24B 桶;
    -- 1.19.3 定案: 旧 0x3438E60 整组 +0x18F60, 旧址现落字符串区,
    -- rp 读到垃圾 → resolve 恒 nil → transfer/deployment 五叶全 MISS)
    local function resolve_tto(t56, i60)
        if not t56 or t56 <= 0 or t56 >= 100 then return nil end
        local tb = rp(BASE + 0x3451DC0 + 8 * t56)
        if not SL.kptr(tb) then return nil end
        local dd, mm = rp(tb + 8), ru32(tb + 20)
        if not (SL.kptr(dd) and mm) then return nil end
        for bi = 0, mm + 2 do
            local e = dd + 24 * bi
            if (ru8(e + 4) or 0) ~= 0 and ru32(e + 8) == t56
                    and ru32(e + 12) == i60 then
                local obj = rp(e + 16)
                if SL.kptr(obj) then
                    local o104 = rp(obj + 104)
                    if SL.kptr(o104) then return ru32(o104 + 88) end
                end
                return nil
            end
        end
        return nil
    end

    -- ===== §4.15.4 CAirWing 翼字段 (w = CAirWing 地址, pk = pool 键) =====
    local function emit_wing(wk, w)
        local function Wf(path, val) E(wk .. "." .. path, val) end
        Wf("id", SL.idpair(ru32(w + 0xC), ru32(w + 8)))
        Wf("count", SL.num(ru32(w + 108)))
        Wf("experience", fx(w + 520))
        Wf("reinforcement_setting", SL.num(ru8(w + 2492) or 0))
        -- timed_disabling 恒写块
        local td = rp(w + 2576)
        local tdk = wk .. ".timed_disabling"
        if SL.kptr(td) then
            E(tdk .. ".remaining_hours", SL.num(ru32(td + 4) or 0))
            E(tdk .. ".should_start_on_transfer",
                SL.yn((ru32(td + 8) or 0) & 0xFF))
        else
            E(tdk .. ".remaining_hours", "0")
            E(tdk .. ".should_start_on_transfer", "no")
        end
        -- transfer 族
        local t56, i60 = ru32(w + 56) or 0, ru32(w + 60) or 0
        local b105 = ru8(w + 105) or 0
        local transferring = (t56 ~= 0 or i60 ~= 0)
            and resolve_tto(t56, i60) ~= nil
        if t56 ~= 0 or i60 ~= 0 then
            local tto = resolve_tto(t56, i60)
            if tto then Wf("transferring_to", SL.num(tto)) end
        end
        if transferring or b105 ~= 0 then
            if not transferring and b105 ~= 0 then
                Wf("transfer_to_warehouse", "yes")
            end
            Wf("transfer_progress", fx(w + 64))
            Wf("transfer_cancelled", SL.yn(ru8(w + 104) or 0))
        end
        -- deployment 族
        local dep84, dt80 = ru32(w + 84) or 0, ru32(w + 80) or 0
        if b105 ~= 0 or dep84 < dt80 or transferring then
            Wf("deployment", SL.num(dep84))
            Wf("deployment_time", SL.num(dt80))
        end
        Wf("manpower", SL.num(ru32(w + 112)))
        -- §4.15.5 CAirMission 块 (m = w+0x80)
        local m = w + 0x80
        local mk = wk .. ".mission"
        E(mk .. ".type", SL.num(ru32(m + 16)))
        do
            local b = ru32(m + 24) & 0xFF
            if b >= 128 then b = b - 256 end
            E(mk .. ".period", SL.num(b))
        end
        E(mk .. ".active", SL.yn(ru8(m + 32) or 0))
        -- executing_mission
        do
            local ef = ru32(m + 20) or 0
            local EXEC = {
                [0x1]=12335, [0x2]=12224, [0x4]=11058, [0x8]=12229,
                [0x10]=12225, [0x20]=11059, [0x40]=13123, [0x80]=11258,
                [0x100]=12971, [0x200]=11388, [0x400]=11851, [0x800]=12218,
                [0x1000]=11856, [0x2000]=11858, [0x4000]=12196,
                [0x8000]=12159, [0x10000]=10088, [0x20000]=10100,
            }
            if ef ~= 0 and EXEC[ef] then
                E(mk .. ".executing_mission", tostring(SL.tok(EXEC[ef])))
            end
        end
        if i64s(m + 216) ~= 0 then E(mk .. ".effectiveness", fx(m + 216)) end
        local epc = ru32(m + 224)
        if epc and epc ~= 0 then
            E(mk .. ".effective_planes_count", SL.num(epc))
        end
        if i64s(m + 232) ~= 0 then
            E(mk .. ".effective_air_superiority", fx(m + 232))
        end
        local r48 = rp(m + 48)
        if SL.kptr(r48) then
            E(mk .. ".strategic_region", SL.num(ru32(r48 + 88)))
            E(mk .. ".region_change_penalty", fx(m + 192))
        end
        E(mk .. ".missions_done", SL.num(ru32(m + 116)))
        local agg = ru32(m + 28)
        if agg and agg ~= 0 then E(mk .. ".aggressiveness", SL.num(agg)) end
        -- priority 串循环 (§4.15.5 CAirMission writer 全字段定案):
        -- {d@m+128, c u32@m+140} 指针数组, 元素 deref+624 引号串,
        -- 键 0x8D=141; 重复裸键标量叶 (提取器重复标量叶不编号)
        do
            local prd, prc = rp(m + 128), ru32(m + 140)
            if SL.kptr(prd) and prc and prc > 0 and prc < GAME.layout.lim.PTR_SANE then
                for pi = 0, prc - 1 do
                    local pp = rp(prd + 8 * pi)
                    local ps = SL.kptr(pp) and SL.sso(pp + 624) or nil
                    if ps and ps ~= "" then
                        E(mk .. ".priority", SL.Q(ps)) end
                end
            end
        end
        if (ru8(m + 124) or 0) ~= 0 then
            E(mk .. ".stop_training_at_max_xp", "yes")
        end
        -- §4.15.4 CAirWing other_combats (c>0 才写; 匿名列表逐项 .#N
        -- 1 起全编号, 首条也带 #1, 非 seqc 首现不编号)
        local ocn = ru32(w + 444)
        if ocn and ocn > 0 and ocn < GAME.layout.lim.PTR_SANE then
            local ocd = rp(w + 432)
            if SL.kptr(ocd) then
                for i = 0, ocn - 1 do
                    E(wk .. ".other_combats.#" .. (i + 1),
                        SL.idpair(ru32(ocd + 4 + 8 * i), ru32(ocd + 8 * i)))
                end
            end
        end
        local acc = ru32(w + 116)
        if acc and acc > 0 then Wf("air_accidents", SL.num(acc)) end
        -- ace id 对
        local at728, ai732 = ru32(w + 728) or 0, ru32(w + 732) or 0
        if at728 ~= 0 or ai732 ~= 0 then
            Wf("ace", SL.idpair(ai732, at728))
        end
        local susp = ru32(w + 424)
        if susp and susp ~= 0 then
            Wf("suspended_missions", SL.num(susp))
        end
        Wf("tag", SL.Q(tagstr(ru32(w + 0x9B4))))
        -- equipment 池 @w+456: {d@+0x1E8, c@+0x1F4} 16B 元; az b@+0x200
        local az = ru8(w + 0x200) or 0
        local eqd, eqn = rp(w + 0x1E8), ru32(w + 0x1F4)
        if SL.kptr(eqd) and eqn and eqn > 0 and eqn <= 100 then
            local seq_eq = SL.seqc()
            for i = 0, eqn - 1 do
                local e = eqd + 16 * i
                local vp, amt = rp(e), i64s(e + 8)
                if amt ~= 0 or az ~= 0 then
                    local ek = seq_eq(wk .. ".equipment.equipment")
                    if SL.kptr(vp) then
                        E(ek .. ".id",
                            SL.idpair(ru32(vp + 0xC), ru32(vp + 8)))
                    end
                    E(ek .. ".amount", SL.num(amt / 1e5))
                end
            end
        end
        Wf("equipment.allow_zero_entries", SL.yn(az))
        -- name SSO@+2440 **恒写 (空串照写 "")** — writer 0x140F539B0 的
        -- 门 sub_1424AAFD0 是 **checksum-file 判定** (RTDynamicCast 到
        -- CChecksumFile), 与串是否为空无关; 旧注"空不写"是错的 (锚件
        -- JAP.air_wing_pool[15/16].air_wings[*].name = "" 六例实证)。
        Wf("name", '"' .. (SL.sso(w + 2440) or "") .. '"')
        Wf("priority", SL.num(ru32(w + 24)))
        Wf("allow_mission_type", SL.num(ru32(w + 28)))
        local rta = ru32(w + 96)
        if rta and rta ~= 0 then
            Wf("region_to_assign", SL.num(rta))
        end
        local mta = ru32(w + 100)
        if mta and mta ~= 0 then
            Wf("mission_to_assign", SL.num(mta))
        end
        local gix = ru32(w + 2488)
        if gix and gix > 0 then
            Wf("government_in_exile_tag", SL.Q(tagstr(gix)))
        end
        if (ru8(w + 2568) or 0) ~= 0 then
            Wf("air_untrained_pilots_penalty_factor", fx(w + 2560))
        end
        local ag48, ag52 = ru32(w + 48) or 0, ru32(w + 52) or 0
        if ag48 ~= 0 or ag52 ~= 0 then
            Wf("air_group", SL.idpair(ag52, ag48))
        end
        local rii = ru32(w + 2584)
        if rii and rii > 0 then
            Wf("role_icon_index", SL.num(rii))
        end
        local rt2588, ri2592 = ru32(w + 2588) or 0, ru32(w + 2592) or 0
        if rt2588 ~= 0 or ri2592 ~= 0 then
            Wf("raid_instance", SL.idpair(ri2592, rt2588))
        end
        -- carrier_air_wing_kills (tok 19901): 扁平 16B 数组 {key u64 装备类别
        -- bitmask@+0, value u32@+8}, data@w+2536, count@w+2548 (≠0 写块);
        -- 键 = equipment_category 位集, 经引擎表 sub_140F8A750 → token
        -- (0x400→fighter / 0x8000→naval_bomber …); 值 u32 原值恒写
        do
            local kcnt = ru32(w + 2548) or 0
            local kd = rp(w + 2536)
            if SL.kptr(kd) and kcnt > 0 and kcnt <= 64 then
                local out = hoi4.engine_alloc(8)
                if out then
                    for ki = 0, kcnt - 1 do
                        local e = kd + 16 * ki
                        local key = rp(e) or 0
                        hoi4.write_u32(out, 0)
                        hoi4.call_u64(BASE + 0xF8A750, out, key)
                        local tk = ru32(out) or 0
                        if tk > 0 then
                            local nm = SL.tok(tk)
                            if nm then
                                Wf("carrier_air_wing_kills." .. nm,
                                    SL.num(ru32(e + 8) or 0))
                            end
                        end
                    end
                    hoi4.engine_free(out)
                end
            end
        end
    end

    -- ===== §4.15.7 SAirWingCombatData combat_history 单侧条目 (e) =====
    local function emit_ch_side(ek, e)
        local function Cf(path, val) E(ek .. "." .. path, val) end
        Cf("id", SL.num(ru32(e + 8)))
        -- equipment 池 @e+88: {d@+0x20, c@+0x2C}; az b@e+144
        local ep = e + 88
        local az = ru8(ep + 56) or 0
        local eqd, eqn = rp(ep + 0x20), ru32(ep + 0x2C)
        if SL.kptr(eqd) and eqn and eqn > 0 and eqn <= 100 then
            local seq_eq = SL.seqc()
            for i = 0, eqn - 1 do
                local q = eqd + 16 * i
                local vp, amt = rp(q), i64s(q + 8)
                if amt ~= 0 or az ~= 0 then
                    local qk = seq_eq(ek .. ".equipment.equipment")
                    if SL.kptr(vp) then
                        E(qk .. ".id",
                            SL.idpair(ru32(vp + 0xC), ru32(vp + 8)))
                    end
                    E(qk .. ".amount", SL.num(amt / 1e5))
                end
            end
        end
        Cf("equipment.allow_zero_entries", SL.yn(az))
        Cf("time", SL.num(ru32(e + 12)))
        -- 定案 (writer 0x141951050 token 序列直证):
        -- 0x2CBA=11450=mission ← @+20; 0x29EA=10730=count ← @+16
        -- (注 count@+20/mission@+16 互反, 568 DIFF = 284 条目×2 全错位)
        Cf("mission", SL.num(ru32(e + 20)))
        Cf("count", SL.num(ru32(e + 16)))
        Cf("tag", SL.Q(tagstr(ru32(e + 80))))
        Cf("ground_attack", SL.yn(ru8(e + 25) or 0))
        -- receiver {d@e+56, c@e+68} / sender {d@e+32, c@e+44}, 24B 元
        local function sr(name, doff, coff)
            local n = ru32(e + coff)
            if n and n > 0 and n < 4096 then -- 同侧列表: 防垃圾指针即可
                local d = rp(e + doff)
                if SL.kptr(d) then
                    local seq = SL.seqc()
                    for i = 0, n - 1 do
                        local q = d + 24 * i
                        local qk = seq(ek .. "." .. name)
                        E(qk .. ".type", SL.num(ru32(q + 8)))
                        E(qk .. ".value", fx(q + 16))
                    end
                end
            end
        end
        sr("receiver", 56, 68)
        sr("sender", 32, 44)
        Cf("destination", SL.yn(ru8(e + 24) or 0))
    end

    -- ===== §4.15.2 CStrategicAir 国条循环: air_wing_pool /
    -- naval_strike_remaining / combat_history =====
    local d30, n30 = rp(mgr + 0x30), ru32(mgr + 0x3C)
    if not (SL.kptr(d30) and n30 and n30 > 0 and n30 < GAME.layout.lim.PTR_HUGE) then return end
    for i = 0, n30 - 1 do
        local sa = rp(d30 + 8 * i)
        if SL.kptr(sa) and rp(sa) == BASE + VT_SAC then
            local tag = tagstr(ru32(sa + 0x90))
            if tag then
                -- §4.15.3 CAirWingPool {d@+88, c@+100} vt 0x297ae38
                local pd, pn = rp(sa + 0x58), ru32(sa + 0x64)
                if SL.kptr(pd) and pn and pn > 0 and pn < 4096 then
                    local seq_pool = SL.seqc()
                    for j = 0, pn - 1 do
                        local pa = rp(pd + 8 * j)
                        if SL.kptr(pa) and rp(pa) == BASE + VT_POOL then
                            local pk = seq_pool(tag .. ".air_wing_pool")
                            local function P(path, val)
                                E(pk .. "." .. path, val)
                            end
                            P("id", SL.idpair(ru32(pa + 0xC), ru32(pa + 8)))
                            local dp = rp(pa + 0x20)
                            if SL.kptr(dp) then
                                P("definition",
                                    tostring(SL.tok(ru32(dp + 8))))
                            end
                            P("air_base",
                                SL.idpair(ru32(pa + 0x1C), ru32(pa + 0x18)))
                            -- wings {d@+0x28, c@+0x34}
                            local wd, wn = rp(pa + 0x28), ru32(pa + 0x34)
                            if SL.kptr(wd) and wn and wn > 0 and wn < GAME.layout.lim.PTR_SANE then
                                local seq_w = SL.seqc()
                                for k = 0, wn - 1 do
                                    local h = rp(wd + 8 * k)
                                    if SL.kptr(h) then
                                        local w = h + 16
                                        if ru32(w + 8) == 69 then
                                            emit_wing(
                                                seq_w(pk .. ".air_wings"), w)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                -- §4.15.2 CStrategicAir naval_strike_remaining {d@+248, c@+260} (c>0)
                local nd, nn = rp(sa + 248), ru32(sa + 260)
                if SL.kptr(nd) and nn and nn > 0 and nn < 10000 then
                    local vals = {}
                    for j = 0, nn - 1 do
                        vals[#vals + 1] = tostring(ru32(nd + 4 * j) or 0)
                    end
                    E(tag .. ".naval_strike_remaining.#1",
                        table.concat(vals, " "))
                end
                -- §4.15.6 CAirRegionCombatData combat_history {d@+368, c@+380};
                -- 索引 = 槽位 0 起 (writer 0x140C57230 计数器 0 起;
                -- 对拍实证 save.210=mem 槽210)
                local chd, chn = rp(sa + 368), ru32(sa + 380)
                if SL.kptr(chd) and chn and chn > 0 and chn < 4096 then
                    for j = 0, chn - 1 do
                        local p = rp(chd + 8 * j)
                        if SL.kptr(p) and rp(p) == BASE + VT_ARC then
                            local hk = tag .. ".combat_history." .. j
                            E(hk .. ".tag", SL.Q(tagstr(ru32(p + 56))))
                            -- 侧名互换: save enemy ← mem+32; save friend ←
                            -- mem+8 (定案)
                            local function side(sname, doff)
                                -- 上限仅防垃圾指针; <64 是误抄的防御界,
                                -- 1940 大会战单侧 >63 队被整侧吞掉
                                -- (writer 无此门)
                                local n = ru32(p + doff + 12)
                                if n and n > 0 and n < 4096 then
                                    local d = rp(p + doff)
                                    if SL.kptr(d) then
                                        local seq_s = SL.seqc()
                                        for k2 = 0, n - 1 do
                                            emit_ch_side(
                                                seq_s(hk .. "." .. sname),
                                                d + 152 * k2)
                                        end
                                    end
                                end
                            end
                            side("enemy", 32)
                            side("friend", 8)
                        end
                    end
                end
                
                -- §4.3.13 CLoopHistory 队列族 (§4.15.2 CStrategicAir +344 history)
                local hd, hn = rp(sa + 344), ru32(sa + 356)
                if SL.kptr(hd) and hn and hn > 0 and hn < 4096 then
                    for j = 0, hn - 1 do
                        local he = rp(hd + 8 * j)
                        local hcols = SL.kptr(he) and ru32(he + 52) or nil
                        if hcols and hcols > 0 and hcols <= 512 then
                            for qi, qoff in ipairs({ 0x10, 0x18, 0x20 }) do
                                local qc = rp(he + qoff)
                                if SL.kptr(qc) then
                                    local kp = string.format(
                                        "%s.history.%d.history_queue.%d.",
                                        tag, j, qi - 1)
                                    E(kp .. "max_elements",
                                        SL.num(ru32(qc + 0x20) or 0))
                                    E(kp .. "offset",
                                        SL.num(ru32(qc + 0x24) or 0))
                                    E(kp .. "is_full",
                                        SL.yn((ru8(qc + 0x28) or 0) ~= 0))
                                    local buf = rp(qc + 8)
                                    local rows = ru32(qc + 0x14) or 0
                                    if SL.kptr(buf) and rows > 0
                                        and rows <= 256
                                        and rows * hcols <= 65536 then
                                        local toks, any = {}, false
                                        for r = 0, rows - 1 do
                                            local h1 = rp(buf + 8 * r)
                                            local row = SL.kptr(h1)
                                                and rp(h1) or nil
                                            local rv = SL.kptr(row)
                                            for k2 = 0, hcols - 1 do
                                                local v = 0
                                                if rv then
                                                    v = i64s(row + 8 * k2)
                                                        / 1e5
                                                end
                                                if v ~= 0 then any = true end
                                                toks[#toks + 1] = SL.num(v)
                                            end
                                        end
                                        if any then
                                            E(kp .. "data.#1",
                                                table.concat(toks, " "))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end }
