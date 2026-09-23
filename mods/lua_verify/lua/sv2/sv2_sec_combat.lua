-- sv2_sec_combat.lua -- combat 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "combat", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local gs, BASE = ctx.gs, ctx.BASE
    if not (gs and BASE) then return end
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local kptr = SL.kptr
    -- §4.22.1 CCombatManager (gs+608 内嵌, vt 存于槽自身)
    if rp(gs + 0x260) ~= BASE + GAME.layout.vt.CCombatManager then return end
    local DFLT_DATE = ru32(BASE + 0x3086B20) -- §3.7a 门哨兵 dword_143086B20

    local i64 = GAME.layout.i64
    local function fix5(a)
        local r = i64(a)
        return r and (r / 100000) or nil
    end
    local tt = rp(gs + 0x358) -- §1.2 gs+856 tag 串表 (槽 0 = "---")
    local function tagraw(tid)
        if not (kptr(tt) and tid) then return nil end
        return hoi4.read_str(tt + 32 * tid)
    end
    local function qtag(tid) -- tid → 引号串 (恒写字段用; 坏 tid 返 nil)
        local s = tagraw(tid)
        return s and ('"' .. s .. '"') or nil
    end
    local function qdate(h) -- hours → 引号日期
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end
    -- 无哨兵过滤版 (§3.7b date_quoted 变体): naval air last_external_wave_date
    -- 恒写, hours=0x29C3388(43791240) 是合法值 "-1.1.1.1" (A 族 date 会当哨兵
    -- 滤掉; 活体实证 hours@ae+112, vt@ae+120)
    local qdate_raw = SL.date_quoted
    -- fixed/整数数组单行 (size/org_loss/str_loss/modifier_hours)
    local function arrline_fixed(d, n)
        local t = {}
        for i = 0, n - 1 do t[#t + 1] = SL.num(((i64(d + 8 * i)) or 0) / 100000) end
        return table.concat(t, " ")
    end
    local function arrline_u32(d, n)
        local t = {}
        for i = 0, n - 1 do t[#t + 1] = tostring(ru32(d + 4 * i) or 0) end
        return table.concat(t, " ")
    end
    -- §4.22.4 SEquipmentPool: P = 池包装基址, pfx = 叶路径前缀; gated = true 时
    -- 整块空判 (combat_side_data/combat_data 用), false = 恒写 (combat_log
    -- 装备子条目用)。空判 = 0x140FFB8F0 (容器A elem+16 全零)。
    local function emit_pool(P, pfx, gated)
        if not kptr(P) then return end
        if gated then
            local na = ru32(P + 20) or 0
            local empty = na <= 0
            if not empty then
                local da = rp(P + 8)
                empty = true
                if kptr(da) then
                    for i = 0, math.min(na, 4096) - 1 do
                        if (rp(da + 24 * i + 16) or 0) ~= 0 then
                            empty = false break
                        end
                    end
                end
            end
            if empty then return end
        end
        local az = ru8(P + 56) == 1
        local d, n = rp(P + 32), ru32(P + 44) or 0
        local seq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 4096) - 1 do
                local vp, amt = rp(d + 16 * i), i64(d + 16 * i + 8)
                if kptr(vp) and ((amt or 0) ~= 0 or az) then
                    local k = seq("equipment")
                    emit("combat", pfx .. "." .. k .. ".id",
                        SL.idpair(ru32(vp + 12), ru32(vp + 8)))
                    emit("combat", pfx .. "." .. k .. ".amount",
                        SL.num((amt or 0) / 100000))
                end
            end
        end
        emit("combat", pfx .. ".allow_zero_entries", SL.yn(az))
    end
    -- §4.22.4 SCombatSideData 侧数据 (combat_side_data / combat_data
    -- 双侧共用; writer 0x140CD15D0)
    local function emit_side(S, pfx)
        local v = ru32(S + 8)
        if v and v > 0 then emit("combat", pfx .. ".manpower_lost", tostring(v)) end
        local f = fix5(S + 16)
        if f and f > 0 then
            emit("combat", pfx .. ".manpower_lost_air_factor", SL.num(f))
        end
        emit_pool(S + 24, pfx .. ".equipment_lost", true)
        emit_pool(S + 344, pfx .. ".equipment_captured_by_enemy", true)
        emit_pool(S + 408, pfx .. ".equipment_recovered", true)
        local lt, li = ru32(S + 520) or 0, ru32(S + 524) or 0
        if lt ~= 0 or li ~= 0 then
            emit("combat", pfx .. ".leader", SL.idpair(li, lt))
        end
        -- tags: u32 tid 数组 → 逐条 #i 引号串
        local d, n = rp(S + 496), ru32(S + 508) or 0
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 64) - 1 do
                local s = qtag(ru32(d + 4 * i))
                if s then emit("combat", pfx .. ".tags.#" .. (i + 1), s) end
            end
        end
    end
    -- §4.22.4 CActivityInGroup 条目 (log.group; writer 0x140CD0980)
    local function emit_group(ge, pfx)
        emit("combat", pfx .. ".group",
            SL.idpair(ru32(ge + 12), ru32(ge + 8)))
        local d, n = rp(ge + 16), ru32(ge + 28) or 0 -- division_template 内联对
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                emit("combat", pfx .. ".division_template.#" .. (i + 1),
                    SL.idpair(ru32(d + 8 * i + 4), ru32(d + 8 * i)))
            end
        end
        d, n = rp(ge + 40), ru32(ge + 52) or 0 -- enemy_dmg 16B {对, fixed}
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                local e = d + 16 * i
                emit("combat", pfx .. ".enemy_dmg_units.#" .. (i + 1),
                    SL.idpair(ru32(e + 4), ru32(e)))
                emit("combat", pfx .. ".enemy_dmg_str.#" .. (i + 1),
                    SL.num(((i64(e + 8)) or 0) / 100000))
            end
        end
        emit_pool(ge + 64, pfx .. ".damaged_equipment", true)
        -- damage_dealer/damage_taker: writer 0x140BA6770 门 = tid > 0
        local tid = ru32(ge + 128) or 0
        if tid > 0 then
            local s = qtag(tid)
            if s then emit("combat", pfx .. ".damage_dealer", s) end
        end
        tid = ru32(ge + 132) or 0
        if tid > 0 then
            local s = qtag(tid)
            if s then emit("combat", pfx .. ".damage_taker", s) end
        end
    end
    -- §4.22.4 NCombatLog::CStatsObserver log 对象 (内嵌@cb+432, writer 0x140CD1240)
    local function emit_log(lb, pfx)
        local d, n = rp(lb + 8), ru32(lb + 20) or 0 -- group 指针数组
        local gseq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                local ge = rp(d + 8 * i)
                if kptr(ge) then emit_group(ge, pfx .. "." .. gseq("group")) end
            end
        end
        emit_side(lb + 88, pfx .. ".combat_side_data")
        d, n = rp(lb + 32), ru32(lb + 44) or 0 -- leader_hours 12B 条
        local lseq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                local e = d + 12 * i
                local k = lseq("leader_hours")
                emit("combat", pfx .. "." .. k .. ".leader",
                    SL.idpair(ru32(e + 4), ru32(e)))
                emit("combat", pfx .. "." .. k .. ".time",
                    tostring(ru32(e + 8) or 0))
            end
        end
        d, n = rp(lb + 56), ru32(lb + 68) or 0 -- damage 32B 条
        local dseq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                local e = d + 32 * i
                local k = dseq("damage")
                local s = qtag(ru32(e + 8))
                if s then emit("combat", pfx .. "." .. k .. ".from", s) end
                s = qtag(ru32(e + 12))
                if s then emit("combat", pfx .. "." .. k .. ".receiver", s) end
                s = qtag(ru32(e + 16))
                if s then emit("combat", pfx .. "." .. k .. ".to", s) end
                emit("combat", pfx .. "." .. k .. ".value",
                    SL.num(((i64(e + 24)) or 0) / 100000))
            end
        end
        local f = fix5(lb + 80)
        if f and f > 0 then emit("combat", pfx .. ".total_damage", SL.num(f)) end
        emit("combat", pfx .. ".modifier_hours.#1", arrline_u32(lb + 624, 30))
        local bits = ru8(lb + 744) or 0
        if (bits & 1) ~= 0 then emit("combat", pfx .. ".snow", "yes") end
        if (bits & 2) ~= 0 then emit("combat", pfx .. ".win", "yes") end
        f = fix5(lb + 616)
        if f and f > 0 then emit("combat", pfx .. ".progress", SL.num(f)) end
    end
    -- §4.22.4 CCombatant/CLandCombatant 参战方 (writer 0x1413CEED0 + 0x1412A8760)
    local function emit_combatant(cb, pfx)
        if not kptr(cb) then return end
        -- id 对列表 (unit/front/reserves/retreat): 8B 指针, 对内联@elem+24
        -- 重复块 = 裸名重复 (multiset), 不编 [N] (原始存档实证)
        local function reflist(off_d, off_c, key)
            local d, n = rp(cb + off_d), ru32(cb + off_c) or 0
            if kptr(d) and n > 0 then
                for i = 0, math.min(n, 256) - 1 do
                    local u = rp(d + 8 * i)
                    if kptr(u) then
                        emit("combat", pfx .. "." .. key,
                            SL.idpair(ru32(u + 28), ru32(u + 24)))
                    end
                end
            end
        end
        reflist(32, 44, "unit")
        emit("combat", pfx .. ".losses", SL.num(fix5(cb + 184) or 0))
        local d, n = rp(cb + 160), ru32(cb + 172) or 0 -- size
        if kptr(d) and n > 0 then
            emit("combat", pfx .. ".size.#1",
                arrline_fixed(d, math.min(n, 512)))
        end
        if (ru8(cb + 219) or 0) ~= 0 then
            emit("combat", pfx .. ".has_flanked_opponent", "yes")
        end
        local s = qtag(ru32(cb + 224)) -- last_hit (tid>0 门在 qtag 外)
        if (ru32(cb + 224) or 0) > 0 and s then
            emit("combat", pfx .. ".last_hit", s)
        end
        local f = fix5(cb + 16)
        if f and f > 0 then
            emit("combat", pfx .. ".shore_bombardment_collateral_damage_factor",
                SL.num(f))
        end
        local v = ru32(cb + 352)
        if v and v > 0 and v < 0x80000000 then
            emit("combat", pfx .. ".air_kills", tostring(v))
        end
        local function posfix(off, key)
            local x = fix5(cb + off)
            if x and x > 0 then emit("combat", pfx .. "." .. key, SL.num(x)) end
        end
        posfix(360, "air_damage_str") posfix(368, "air_damage_org")
        posfix(376, "ground_damage_str") posfix(384, "ground_damage_org")
        posfix(392, "prevented_damage_str") posfix(400, "prevented_damage_org")
        posfix(344, "anti_air_attack")
        reflist(232, 244, "front")
        reflist(256, 268, "reserves")
        reflist(280, 292, "retreat")
        d, n = rp(cb + 320), ru32(cb + 332) or 0 -- §4.22.4 CAirInLandCombat 8B 指针
        local aseq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                local A = rp(d + 8 * i)
                if kptr(A) then
                    local k = aseq("air_plane")
                    local h = ru32(A + 40)
                    if h and h ~= DFLT_DATE then
                        local ds = qdate(h)
                        if ds then
                            emit("combat", pfx .. "." .. k .. ".date", ds)
                        end
                    end
                    emit("combat", pfx .. "." .. k .. ".amount",
                        tostring(ru32(A + 20) or 0))
                    emit("combat", pfx .. "." .. k .. ".air_wing",
                        SL.idpair(ru32(A + 12), ru32(A + 8)))
                    emit("combat", pfx .. "." .. k .. ".air_count",
                        tostring(ru32(A + 16) or 0))
                    emit("combat", pfx .. "." .. k .. ".damage_factor",
                        SL.num(((i64(A + 24)) or 0) / 100000))
                end
            end
        end
        local tac = rp(cb + 304) -- §4.22.7 CCombatTactic ref (writer 另有 vmethod80 门)
        if kptr(tac) then
            emit("combat", pfx .. ".tactic", tostring(ru32(tac + 152) or 0))
        end
        d, n = rp(cb + 408), ru32(cb + 420) or 0 -- org_loss_summary
        if kptr(d) and n > 0 then
            emit("combat", pfx .. ".org_loss_summary.#1",
                arrline_fixed(d, math.min(n, 512)))
        end
        d, n = rp(cb + 432), ru32(cb + 444) or 0 -- str_loss_summary
        if kptr(d) and n > 0 then
            emit("combat", pfx .. ".str_loss_summary.#1",
                arrline_fixed(d, math.min(n, 512)))
        end
        emit("combat", pfx .. ".org_loss_summary_index",
            tostring(ru32(cb + 456) or 0))
        emit("combat", pfx .. ".num_org_losses",
            tostring(ru32(cb + 460) or 0))
        -- §4.22.4 weighted_participants RH 表 @cb+128: data@+136, 计数@+144
        -- (写门非零), 掩码 u32@+148, extra u8@+152; 桶 24B: 距离
        -- byte@+4 ≠0 占用, tag id u32@+8, weight i64 fix5@+16; writer
        -- sub_1413E41F0 → sub_1411DCF90)
        do
            local wd = rp(cb + 136)
            local wcnt = ru32(cb + 144) or 0
            local wmask = ru32(cb + 148) or 0
            local wextra = ru8(cb + 152) or 0
            if kptr(wd) and wcnt > 0 and wcnt < 4096 then
                local nb = wmask + 1 + wextra
                for bi = 0, math.min(nb, 65536) - 1 do
                    local b = wd + 24 * bi
                    if (ru8(b + 4) or 0) ~= 0 then
                        local tgs = qtag(ru32(b + 8) or 0)
                        if tgs then
                            emit("combat", pfx .. ".weighted_participants",
                                tgs .. " " .. tostring(SL.num(fix5(b + 16) or 0)))
                        end
                    end
                end
            end
        end
        emit_log(cb + 464, pfx .. ".log")
    end
    -- 容器包装 → 参战基址 (§4.22.3 CLandCombat 侧容器解引用;
    -- objects_v2 §14.2 combatant 同款)
    local function combatant(c, side_off)
        local cont = rp(c + side_off)
        if not kptr(cont) then return nil end
        local d = rp(cont)
        local n = ru32(cont + 12)
        -- ⚠ cont[0] 在本构建 = **vtable** (落在映像区间), 不是数据指针 —
        -- 实测 33 场陆战 66 个侧容器 66/66 皆然。当数据指针去解包 = 把
        -- 代码字节读成堆指针 → cb 成垃圾 → 该侧字段整批丢失。攻击侧
        -- 侥幸无恙 (n 读到垃圾巨值, 被 count<64 门挡回兜底 cont); 防守侧
        -- n 恰 =1 而误入解包路径 → 整侧 MISS。判据 = cont[0] 属映像区间
        -- 即判 vtable ⇒ 直接用 cont。objects_v2 §14.2 combatant 同款。
        if d and d >= BASE and d < BASE + 0x37EC000 then return cont end
        if kptr(d) and n and n > 0 and n < 64 then
            local el = rp(d)
            if kptr(el) then return rp(el + 16) or el end
        end
        return cont
    end
    -- §4.22.2 CLandBorderWarCombatant 边界战参战方扩展 (1.19.3 writer
    -- 0x1413F0100 = CLandCombatant 基座后追加; 偏移/门见 §4.22.2 —
    -- 全表比 1.19.2 +32)
    local function emit_bw_side(cb, pfx)
        if not kptr(cb) then return end
        local function W(path, val)
            emit("combat", pfx .. "." .. path, val)
        end
        local tid = ru32(cb + 1216) or 0
        local s = qtag(tid)
        if not s and tid == 0 then s = '"---"' end
        if s then W("tag", s) end
        local sp = rp(cb + 1224)
        if kptr(sp) then W("state", tostring(ru32(sp + 88) or 0)) end
        local d, n = rp(cb + 1232), ru32(cb + 1244) or 0
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 64) - 1 do
                local pe = rp(d + 8 * i)
                if kptr(pe) then
                    W("province", tostring(ru32(pe + 164) or 0))
                end
            end
        end
        W("orders_group", SL.idpair(ru32(cb + 1260) or 0,
            ru32(cb + 1256) or 0))
        W("max_units", tostring(ru32(cb + 1264) or 0))
        -- 0x1424C34F0 (i64 写) = fixed×1e-5 (raw 100000 → save 1 实证)
        W("modifier", SL.num((i64(cb + 1272) or 0) / 100000))
        W("dig_in_factor", SL.num((i64(cb + 1376) or 0) / 100000))
        W("terrain_factor", SL.num((i64(cb + 1384) or 0) / 100000))
        s = SL.sso(cb + 1280)
        if s and s ~= "" then W("on_win", '"' .. s .. '"') end
        s = SL.sso(cb + 1312)
        if s and s ~= "" then W("on_lose", '"' .. s .. '"') end
        s = SL.sso(cb + 1344)
        if s and s ~= "" then W("on_cancel", '"' .. s .. '"') end
        d, n = rp(cb + 1392), ru32(cb + 1404) or 0 -- removed_unit 12B 条
        local rseq = SL.seqc()
        if kptr(d) and n > 0 then
            for i = 0, math.min(n, 256) - 1 do
                local en = d + 12 * i
                local k = rseq("removed_unit")
                W(k .. ".unit", SL.idpair(ru32(en + 4), ru32(en)))
                W(k .. ".hours", tostring(ru32(en + 8) or 0))
            end
        end
    end

    -- ================= 海战族 =================
    -- §4.2.2 三注册表源 (sub_14221F310 三档 id 库): ty>0x1268 / >=100 / <100
    local DB_BIG, DB_MID, DB_ARR = BASE + 0x3451DB0, BASE + 0x3451DB8,
        BASE + 0x3451DC0
    local function ref_resolve(ty, id)
        if not (ty and id) then return nil end
        local db
        if ty > 0x1268 then db = rp(DB_BIG)
        elseif ty >= 100 then db = rp(DB_MID)
        else db = rp(DB_ARR + 8 * ty) end
        if not kptr(db) then return nil end
        local d, mask, maxp = rp(db + 8), ru32(db + 20), ru8(db + 24)
        if not (kptr(d) and mask and mask > 0 and mask < 0x4000000) then
            return nil end
        for bi = 0, mask + (maxp or 0) do
            local b = d + 24 * bi
            if (ru8(b + 4) or 0) ~= 0
                and ru32(b + 8) == ty and ru32(b + 12) == id then
                local o = rp(b + 16)
                if kptr(o) then return o end
                return nil
            end
        end
        return nil
    end
    -- §4.22.5 SNavalHit 条目 (writer 0x1415B57D0, 全恒写)
    local function emit_naval_hit(h, pfx)
        emit("combat", pfx .. ".target", tostring(ru32(h + 8) or 0))
        local s = SL.sso(h + 16)
        if s then emit("combat", pfx .. ".name", '"' .. s .. '"') end
        emit("combat", pfx .. ".convoy", SL.yn(ru8(h + 48)))
        emit("combat", pfx .. ".damage", SL.num(fix5(h + 56) or 0))
        emit("combat", pfx .. ".strength", SL.num(fix5(h + 64) or 0))
        emit("combat", pfx .. ".last_hit", SL.yn(ru8(h + 72)))
    end
    -- §4.22.5 SAirHit 条目 (writer 0x1415B5760)
    local function emit_air_hit(ah, pfx)
        local s = qtag(ru32(ah + 20))
        if s then emit("combat", pfx .. ".tag", s) end
        local v7 = rp(ah + 8)
        if kptr(v7) then
            emit("combat", pfx .. ".equipment_variant_index",
                SL.idpair(ru32(v7 + 12), ru32(v7 + 8)))
        end
        emit("combat", pfx .. ".count", tostring(ru32(ah + 16) or 0))
    end
    -- §4.22.5 CFEXMember member 条目 (writer 0x1419760B0, 旧 0x141962A00)
    local EQ_SENT_LO = ru32(BASE + 0x333D528)      -- qword_143324598 哨兵
    local EQ_SENT_HI = ru32(BASE + 0x333D528 + 4)
    local function emit_naval_member(m, pfx)
        if not kptr(m) then return end
        emit("combat", pfx .. ".unique_id", tostring(ru32(m + 288) or 0))
        local t, i = ru32(m + 8) or 0, ru32(m + 12) or 0
        if t ~= 0 or i ~= 0 then
            emit("combat", pfx .. ".ship", SL.idpair(i, t))
        end
        t, i = ru32(m + 16) or 0, ru32(m + 20) or 0
        if t ~= 0 or i ~= 0 then
            emit("combat", pfx .. ".convoy", SL.idpair(i, t))
        end
        emit("combat", pfx .. ".state", tostring(ru32(m + 224) or 0))
        emit("combat", pfx .. ".hours_to_arrive",
            tostring(ru32(m + 228) or 0))
        emit("combat", pfx .. ".cooldown.#1", arrline_fixed(m + 240, 3))
        -- §4.22.5 member.cached_info (SCachedInfo) 内嵌 @m+24 (writer 0x141962D80)
        local ci = m + 24
        local function cemit(leaf, val)
            if val then emit("combat", pfx .. ".cached_info." .. leaf, val) end
        end
        local s = SL.sso(ci + 112)
        if s then cemit("sprite", '"' .. s .. '"') end
        cemit("index", tostring(ru32(ci + 12) or 0))
        cemit("type", tostring(ru32(ci + 16) or 0))
        cemit("tag", qtag(ru32(ci + 8)))
        local f = fix5(ci + 32)
        if f and f ~= 0 then cemit("strength", SL.num(f)) end
        if (ru32(ci + 160) or 0) ~= 0 then
            s = SL.sso(ci + 144)
            if s and s ~= "" then cemit("sunk_by", '"' .. s .. '"') end
        end
        if (ru8(ci + 41) or 0) ~= 0 then cemit("convoy", "yes") end
        f = fix5(ci + 24)
        if f and f ~= 0 then cemit("build_cost_ic", SL.num(f)) end
        if (ru32(ci + 96) or 0) ~= 0 then
            s = SL.sso(ci + 80)
            if s and s ~= "" then
                cemit("equipment_variant", '"' .. s .. '"')
            end
        end
        t, i = ru32(ci + 176) or 0, ru32(ci + 180) or 0
        if t ~= (EQ_SENT_LO or -1) or i ~= (EQ_SENT_HI or -1) then
            cemit("highest_eq_variant", SL.idpair(i, t))
        end
        if (ru32(ci + 64) or 0) ~= 0 then
            s = SL.sso(ci + 48)
            if s and s ~= "" then cemit("ship", '"' .. s .. '"') end
        end
        if (ru8(ci + 40) or 0) ~= 0 then
            cemit("pride_of_the_fleet", "yes")
        end
        t, i = ru32(ci + 184) or 0, ru32(ci + 188) or 0
        if t ~= 0 or i ~= 0 then
            cemit("convoy_id", SL.idpair(i, t))
        end
        local v = ru32(ci + 192) or 0xFFFFFFFF
        if v < 0x80000000 then cemit("convoy_index", tostring(v)) end
        -- 余部
        v = ru32(m + 292) or 0
        if v > 0 then
            emit("combat", pfx .. ".critical_hits_received", tostring(v))
        end
        local d, n = rp(m + 384), ru32(m + 396) or 0 -- naval_hit 指针数组
        local hseq = SL.seqc()
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 256) - 1 do
                local h = rp(d + 8 * q)
                if kptr(h) then
                    emit_naval_hit(h, pfx .. "." .. hseq("naval_hit"))
                end
            end
        end
        d, n = rp(m + 336), ru32(m + 348) or 0 -- air_hit 指针数组
        local aseq = SL.seqc()
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 256) - 1 do
                local ah = rp(d + 8 * q)
                if kptr(ah) then
                    emit_air_hit(ah, pfx .. "." .. aseq("air_hit"))
                end
            end
        end
        v = ru32(m + 296) or 0
        if v ~= 0 then emit("combat", pfx .. ".evacuated", tostring(v)) end
        v = ru32(m + 300) or 0xFFFFFFFF
        if v ~= 0xFFFFFFFF then
            emit("combat", pfx .. ".hidden", tostring(v))
        end
        f = fix5(m + 304)
        if f and f ~= 0 then
            emit("combat", pfx .. ".escape_progress", SL.num(f))
        end
        emit("combat", pfx .. ".damage_received_by_gun_types.#1",
            arrline_fixed(m + 408, 6))
        d, n = rp(m + 264), ru32(m + 276) or 0 -- damage_received 内联 32B
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 64) - 1 do
                local e = d + 32 * q
                local dp = pfx .. ".damage_received.#" .. (q + 1)
                emit("combat", dp .. ".ship",
                    SL.idpair(ru32(e + 12), ru32(e + 8)))
                s = qtag(ru32(e + 16))
                if s then emit("combat", dp .. ".tag", s) end
                emit("combat", dp .. ".damage", SL.num(fix5(e + 24) or 0))
            end
        end
        if (ru8(m + 328) or 0) ~= 0 then -- last_target (lt=m+312)
            emit("combat", pfx .. ".last_target.convoy",
                SL.yn(ru8(m + 312 + 8)))
            emit("combat", pfx .. ".last_target.size",
                tostring(ru32(m + 312 + 12) or 0))
        end
    end
    -- §4.22.5 CFEXAir group air 条目 (writer 0x14197D990, 旧 0x14196A2E0)
    local function emit_naval_air(ae, pfx)
        local s = qtag(ru32(ae + 100))
        if s then emit("combat", pfx .. ".tag", s) end
        local t, i = ru32(ae + 28) or 0, ru32(ae + 32) or 0
        if t ~= 0 or i ~= 0 then
            emit("combat", pfx .. ".air_base", SL.idpair(i, t))
        end
        local d, n = rp(ae + 64), ru32(ae + 76) or 0 -- air_wing 内联对
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 256) - 1 do
                emit("combat", pfx .. ".air_wing",
                    SL.idpair(ru32(d + 8 * q + 4), ru32(d + 8 * q)))
            end
        end
        d, n = rp(ae + 40), ru32(ae + 52) or 0 -- naval_strike 内联对
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 256) - 1 do
                emit("combat", pfx .. ".naval_strike",
                    SL.idpair(ru32(d + 8 * q + 4), ru32(d + 8 * q)))
            end
        end
        n = ru32(ae + 180) or 0 -- names 32B 串数组
        d = rp(ae + 168)
        if kptr(d) and n > 0 then
            local tt2 = {}
            for q = 0, math.min(n, 64) - 1 do
                local nm = SL.sso(d + 32 * q)
                if nm then tt2[#tt2 + 1] = '"' .. nm .. '"' end
            end
            if #tt2 > 0 then
                emit("combat", pfx .. ".names.#1", table.concat(tt2, " "))
            end
        end
        emit("combat", pfx .. ".max", tostring(ru32(ae + 88) or 0))
        emit("combat", pfx .. ".alive", tostring(ru32(ae + 92) or 0))
        emit("combat", pfx .. ".casualties", tostring(ru32(ae + 96) or 0))
        local ds = qdate_raw(ru32(ae + 112)) -- CGameDate 族A: ptr=ae+120
        if ds then emit("combat", pfx .. ".last_external_wave_date", ds) end
        emit("combat", pfx .. ".external_wave_complete",
            SL.yn(ru8(ae + 128)))
        emit("combat", pfx .. ".time_duration",
            tostring(ru32(ae + 248) or 0))
        emit("combat", pfx .. ".external", SL.yn(ru8(ae + 129)))
        s = SL.sso(ae + 136)
        if s then emit("combat", pfx .. ".name", '"' .. s .. '"') end
        emit("combat", pfx .. ".damage_mult", SL.num(fix5(ae + 192) or 0))
        local d2, n2 = rp(ae + 256), ru32(ae + 268) or 0
        local hseq = SL.seqc()
        if kptr(d2) and n2 > 0 then
            for q = 0, math.min(n2, 256) - 1 do
                local h = rp(d2 + 8 * q)
                if kptr(h) then
                    emit_naval_hit(h, pfx .. "." .. hseq("naval_hit"))
                end
            end
        end
        d2, n2 = rp(ae + 280), ru32(ae + 292) or 0
        local aseq = SL.seqc()
        if kptr(d2) and n2 > 0 then
            for q = 0, math.min(n2, 256) - 1 do
                local ah = rp(d2 + 8 * q)
                if kptr(ah) then
                    emit_air_hit(ah, pfx .. "." .. aseq("air_hit"))
                end
            end
        end
        local v = ru32(ae + 24) or 0xFFFFFFFF
        if v ~= 0xFFFFFFFF then
            emit("combat", pfx .. ".carrier", tostring(v))
        end
    end
    -- §4.22.5 CFEXGroup group 条目 (writer 0x141C58360)
    local function emit_naval_group(g, pfx)
        local d, n = rp(g + 8), ru32(g + 20) or 0 -- member 指针数组
        local mseq = SL.seqc()
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 1024) - 1 do
                local m = rp(d + 8 * q)
                if kptr(m) then
                    emit_naval_member(m, pfx .. "." .. mseq("member"))
                end
            end
        end
        d, n = rp(g + 88), ru32(g + 100) or 0 -- air 指针数组
        local aseq = SL.seqc()
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 256) - 1 do
                local ae = rp(d + 8 * q)
                if kptr(ae) then
                    emit_naval_air(ae, pfx .. "." .. aseq("air"))
                end
            end
        end
        -- opponent_group: oppg 在其母 combatant group 数组中的下标
        -- (1.19.3: host combatant 数组 {d@+232,c@+244} — 新 writer 0x141C6D0D0)
        local oppg = rp(g + 32)
        if kptr(oppg) then
            local oc = rp(oppg + 56)
            local od = oc and rp(oc + 232)
            local on = oc and (ru32(oc + 244) or 0)
            if kptr(od) and on and on > 0 and on < 64 then  -- 判别界勿放宽 (同 combatant)
                for q = 0, on - 1 do
                    if rp(od + 8 * q) == oppg then
                        emit("combat", pfx .. ".opponent_group", tostring(q))
                        break
                    end
                end
            end
        end
        emit("combat", pfx .. ".forces_compare", SL.num(fix5(g + 48) or 0))
        emit("combat", pfx .. ".disengage_counter",
            tostring(ru32(g + 64) or 0))
        emit("combat", pfx .. ".chasing_counter",
            tostring(ru32(g + 68) or 0))
    end
    -- §4.22.5 CNavalCombatant 海战参战方 (writer 0x14160FF40)
    local function emit_naval_side(cb, pfx)
        if not kptr(cb) then return end
        local d, n = rp(cb + 32), ru32(cb + 44) or 0 -- unit (裸名重复)
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 256) - 1 do
                local u = rp(d + 8 * q)
                if kptr(u) then
                    emit("combat", pfx .. ".unit",
                        SL.idpair(ru32(u + 28), ru32(u + 24)))
                end
            end
        end
        d, n = rp(cb + 232), ru32(cb + 244) or 0 -- group[N] (1.19.3 +32)
        local gseq = SL.seqc()
        if kptr(d) and n > 0 then
            for q = 0, math.min(n, 64) - 1 do
                local g = rp(d + 8 * q)
                if kptr(g) then
                    emit_naval_group(g, pfx .. "." .. gseq("group"))
                end
            end
        end
        local ll = rp(cb + 312) -- last_leader → 对@ptr+8 (1.19.3 +32)
        if kptr(ll) then
            emit("combat", pfx .. ".last_leader",
                SL.idpair(ru32(ll + 12), ru32(ll + 8)))
        end
        if (ru8(cb + 320) or 0) ~= 0 then -- disengage (+32)
            emit("combat", pfx .. ".disengage", "yes")
        end
        emit("combat", pfx .. ".anti_air", SL.num(fix5(cb + 368) or 0))
        emit("combat", pfx .. ".positioning", SL.num(fix5(cb + 344) or 0))
        local f = fix5(cb + 352)
        if f and f ~= 0 then
            emit("combat", pfx .. ".new_ships_positioning_penalty", SL.num(f))
        end
        emit("combat", pfx .. ".total_damage_dealt",
            SL.num(fix5(cb + 384) or 0))
        emit("combat", pfx .. ".total_initial_strength",
            SL.num(fix5(cb + 376) or 0))
        emit("combat", pfx .. ".positioning_dominance_bonus",
            SL.num(fix5(cb + 360) or 0))
        emit("combat", pfx .. ".damage_dealt_by_gun_types.#1",
            arrline_fixed(cb + 392, 36)) -- 1.19.3 +32 (writer 拷贝环首 a1+392)
        -- damage_dealt_by_ship_types: 侵入链表 (头=哨兵, next@0) (+32)
        if (ru32(cb + 696) or 0) ~= 0 then
            local head = rp(cb + 688)
            local node = head and rp(head)
            local guard = 0
            while kptr(node) and node ~= head
                and guard < GAME.layout.lim.PTR_SANE do
                local tk = ru32(node + 16)
                local nm = tk and SL.tok(tk)
                if nm then
                    emit("combat", pfx .. ".damage_dealt_by_ship_types."
                        .. nm, SL.num(fix5(node + 24) or 0))
                end
                node = rp(node)
                guard = guard + 1
            end
        end
    end
    -- §4.22.5 convoy 条目 无独立 RTTI 类 (writer 0x141AD8690, 旧 0x141AC3C50)
    local function emit_convoy_entry(cv, pfx)
        emit("combat", pfx .. ".id",
            SL.idpair(ru32(cv + 12), ru32(cv + 8)))
        local v4 = rp(cv + 24)
        if kptr(v4) then
            emit("combat", pfx .. ".equipment_variant_index",
                SL.idpair(ru32(v4 + 12), ru32(v4 + 8)))
        end
        emit("combat", pfx .. ".strength", SL.num(fix5(cv + 32) or 0))
        emit("combat", pfx .. ".organisation", SL.num(fix5(cv + 40) or 0))
        -- tag 三段链 (client 对 → obj+24 | transfer 对 → obj+88 | 兜底+64)
        local tid
        local t1, i1 = ru32(cv + 48) or 0, ru32(cv + 52) or 0
        if t1 ~= 0 or i1 ~= 0 then
            local o = ref_resolve(t1, i1)
            if o then tid = ru32(o + 24) end
        end
        if not tid then
            local t2, i2 = ru32(cv + 56) or 0, ru32(cv + 60) or 0
            if t2 ~= 0 or i2 ~= 0 then
                local o = ref_resolve(t2, i2)
                if o then tid = ru32(o + 88) end
            end
        end
        if not tid then tid = ru32(cv + 64) end
        if tid and tid > 0 then
            local s = qtag(tid)
            if s then emit("combat", pfx .. ".tag", s) end
        end
        local t2, i2 = ru32(cv + 56) or 0, ru32(cv + 60) or 0
        if (t2 ~= 0 or i2 ~= 0) and ref_resolve(t2, i2) then
            emit("combat", pfx .. ".transfer_navy", SL.idpair(i2, t2))
        end
        if (t1 ~= 0 or i1 ~= 0) and ref_resolve(t1, i1) then
            emit("combat", pfx .. ".client", SL.idpair(i1, t1))
        end
        emit("combat", pfx .. ".convoy_index",
            tostring(ru32(cv + 68) or 0))
    end

    -- §4.22.1 CCombatManager 场循环 (gs+0x268 {d, c@+0x274}); 三类分流 (L)
    -- 边界战 = 主 vtable *e == §4.22.2 CLandBorderWarCombat 0x29bc5f0
    -- (RTTI+探针实拍; day 正数, 必须先于海战判定); 海战 = day 有符号 (实证);
    -- 其余 = §4.22.3 陆战 CLandCombat。
    local cd, cn = rp(gs + 0x268), ru32(gs + 0x274) or 0
    local seqL, seqN, seqB = SL.seqc(), SL.seqc(), SL.seqc()
    local VT_BWC = BASE + GAME.layout.vt.CLandBorderWarCombat
    if kptr(cd) and cn > 0 then
        -- 64 容器 guard 截断 (大档千级容器同族风险) — 收敛 PTR_SANE
        for k = 0, math.min(cn, 4096) - 1 do
            local e = rp(cd + 8 * k)
            if kptr(e) then
                local c = e + 16
                local day = ru32(c + 48) or 0
                local border = rp(e) == VT_BWC
                local naval = (not border) and day > 0x7FFFFFFF
                local key = border and seqB("border_war_combat")
                    or naval and seqN("naval_combat")
                    or seqL("land_combat")
                local function E(path, val) emit("combat", key .. "." .. path, val) end
                E("id", SL.idpair(ru32(c + 12), ru32(c + 8)))
                local loc = rp(c + 40)
                if kptr(loc) then E("location", tostring(ru32(loc + 164) or 0)) end
                local sday = day >= 0x80000000 and day - 0x100000000 or day
                E("day", tostring(sday)) -- ADFE0 按 int32 打印 (-1=海战)
                E("duration", tostring(ru32(c + 52) or 0))
                if naval then
                    -- §4.22.5 CNavalCombat (writer 0x1415C5BC0, 旧 0x1415B36C0):
                    -- 参战直指, 无陆战包装
                    emit_naval_side(rp(c + 24), key .. ".attacker")
                    emit_naval_side(rp(c + 32), key .. ".defender")
                    -- client / naval_transport 内联对 (裸名重复)
                    local d, n = rp(c + 200), ru32(c + 212) or 0
                    if kptr(d) and n > 0 then
                        for q = 0, math.min(n, 64) - 1 do
                            E("client", SL.idpair(ru32(d + 8 * q + 4),
                                ru32(d + 8 * q)))
                        end
                    end
                    local nd, nn = rp(c + 224), ru32(c + 236) or 0
                    if kptr(nd) and nn > 0 then
                        for q = 0, math.min(nn, 64) - 1 do
                            E("naval_transport", SL.idpair(
                                ru32(nd + 8 * q + 4), ru32(nd + 8 * q)))
                        end
                    end
                    -- convoy[N]: 门 = 自有计数>0 且 (client 或 ntt 非空)
                    local cn2 = ru32(c + 188) or 0
                    if cn2 > 0 and ((n or 0) > 0 or (nn or 0) > 0) then
                        local vd = rp(c + 176)
                        local vseq = SL.seqc()
                        if kptr(vd) then
                            for q = 0, math.min(cn2, 256) - 1 do
                                local cv = rp(vd + 8 * q)
                                if kptr(cv) then
                                    emit_convoy_entry(cv,
                                        key .. "." .. vseq("convoy"))
                                end
                            end
                        end
                    end
                    E("unique_id", tostring(ru32(c + 248) or 0))
                    if (ru8(c + 252) or 0) ~= 0 then E("port_strike", "yes") end
                    if (ru8(c + 253) or 0) ~= 0 then E("naval_strike", "yes") end
                    local sc = ru32(c + 256) or 0
                    if sc > 0 then E("sunk_convoys", tostring(sc)) end
                    if (ru8(c + 260) or 0) ~= 0 then E("hide", "yes") end
                    if (ru8(c + 261) or 0) ~= 0 then
                        E("convoy_combat", "yes")
                    end
                    E("progress", SL.num(fix5(c + 264) or 0))
                else
                    emit_combatant(combatant(c, 24), key .. ".attacker")
                    emit_combatant(combatant(c, 32), key .. ".defender")
                    if border then
                        -- §4.22.2 CLandBorderWarCombat 块扩展 (writer 0x1413F0070; 恒写)
                        emit_bw_side(combatant(c, 24), key .. ".attacker")
                        emit_bw_side(combatant(c, 32), key .. ".defender")
                        E("combat_width", SL.num((i64(c + 200) or 0) / 100000))
                        E("combat_state", tostring(ru32(c + 208) or 0))
                        E("minimum_duration_in_days",
                            tostring(ru32(c + 212) or 0))
                        do  -- start i32 有符号 (-2 被直打 4294967294 实证)
                            local sv = ru32(c + 216) or 0
                            sv = GAME.layout.as_i32(sv)
                            E("start", tostring(sv))
                        end
                        E("change_state_after_war", SL.yn(ru8(c + 224) == 1))
                    end
                end
                local tobj = rp(c + 56)
                if kptr(tobj) and ((ru32(tobj + 16) or 0) & 0xFF) ~= 0 then
                    local s = hoi4.read_str(tobj + 24)
                    if s and s ~= "" then E("terrain", '"' .. s .. '"') end
                end
            end
        end
    end

    -- §4.22.4 CCombatHistory 战斗历史 (链表头@gs+0x288+8, 存档序 = 链表序);
    -- guard = PTR_SANE — 旧 128 在大战 136 条档截尾 8 条 (实证)
    local e = rp(gs + 0x288 + 8)
    local hi, guard = 0, 0
    local HGUARD = (GAME.layout.lim and GAME.layout.lim.PTR_SANE) or 4096
    while kptr(e) and guard < HGUARD do
        hi = hi + 1
        local pfx = "history.history.#" .. hi
        emit("combat", pfx .. ".location", tostring(ru32(e + 44) or 0))
        local s = qtag(ru32(e + 36))
        if s then emit("combat", pfx .. ".attacker", s) end
        s = qtag(ru32(e + 40))
        if s then emit("combat", pfx .. ".defender", s) end
        local ds = qdate(ru32(e + 16)) -- §3.7a 族B CGameDate@e+8: vt@+0, hours@+8
        if ds then emit("combat", pfx .. ".end_date", ds) end
        emit("combat", pfx .. ".type", tostring(ru32(e + 32) or 0))
        e = rp(e + 56)
        guard = guard + 1
    end
end }
