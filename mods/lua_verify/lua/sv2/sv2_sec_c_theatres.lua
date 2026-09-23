-- sv2_sec_c_theatres.lua -- country.theatres 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.theatres", emit = function(ctx)
    local emit, tag, cc, gs = ctx.emit, ctx.tag, ctx.cc, ctx.gs
    if not cc then return end
    local SL = SV2.lib
    local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
    local ri64 = SL.rp_i64   -- 与 rp 同原语 (read_u64 已带符号; 书 §3.7)
    local rf32 = hoi4.read_f32
    local kptr = SL.kptr
    local ttab = gs and rp(gs + 0x358) or nil -- §1.2 tag 串表 gs+856 (tid→tag)
    local function tagstr(tid)
        if not tid or tid <= 0 or tid >= 100000 or not kptr(ttab) then
            return nil end
        return hoi4.read_str(ttab + 32 * tid)
    end
    -- §4.24.3 COrdersGroup / §4.24.5 COrderInstance ref 对哨兵
    -- (qword_14333D528, 运行时读一次; 读不到退 0。
    -- 1.19.3 定案: 旧静态 0x143324598 已被数据搬家占用(ASCII 垃圾),
    -- 新静态活体值 = 0, 即无效槽 qword 直存 0; 守卫语义仍镜像 writer
    -- `*(og+292) != qword_14333D528` / `*(oi+600) != qword_14333D528`)
    local SENT = rp(ctx.BASE + 0x333D528) or 0
    -- §3.7b CGameDate hours -> "Y.M.D.H" (C 族, 引号形, 无哨兵抑制
    -- writer 守卫仅 hours!=0; 43808760 → "1.1.1.1" 照常写)
    local datef = SL.date_quoted
    local function fix5(a) return (ri64(a) or 0) * 1e-5 end
    local function yn1(v) return (v == 1) and "yes" or "no" end
    -- sub_140C91860 族: u32 数组 {data@c+0, count@c+12} → 单行叶 (count>0)
    local function emit_u32list(path, c)
        local d, n = rp(c), ru32(c + 12)
        if kptr(d) and n and n > 0 and n < 1000000 then
            local t = {}
            for i = 0, n - 1 do t[#t + 1] = tostring(ru32(d + 4 * i) or 0) end
            emit(tag, path, table.concat(t, " "))
        end
    end
    -- ptr 数组 {data@c+0, count@c+12}, 值 = ru32(elem+off) → 单行 #1 叶
    local function emit_ptrlist1(path, c, off)
        local d, n = rp(c), ru32(c + 12)
        if kptr(d) and n and n > 0 and n < 1000000 then
            local t = {}
            for i = 0, n - 1 do
                local e = rp(d + 8 * i)
                if kptr(e) then
                    t[#t + 1] = tostring(ru32(e + off) or 0)
                end
            end
            if #t > 0 then emit(tag, path .. ".#1", table.concat(t, " ")) end
        end
    end
    -- 16B 指针对数组 {data@c+0, count@c+12}, 平铺 ru32(ptr+164) → 单行叶
    -- (join=true: oi sorted_pairs 单行无 #1; 否则 #1)
    local function emit_pairlist(path, c, anon)
        local d, n = rp(c), ru32(c + 12)
        if kptr(d) and n and n > 0 and n < 1000000 then
            local t = {}
            for i = 0, n - 1 do
                local pa, pb = rp(d + 16 * i), rp(d + 16 * i + 8)
                if kptr(pa) then t[#t + 1] = tostring(ru32(pa + 164) or 0) end
                if kptr(pb) then t[#t + 1] = tostring(ru32(pb + 164) or 0) end
            end
            if #t > 0 then
                emit(tag, anon and (path .. ".#1") or path,
                    table.concat(t, " "))
            end
        end
    end
    -- §4.24.9 member 族: 元素 = unit+184, ref 对在 unit+24 {type@24, id@28}
    local function unit_ref(e)
        if not kptr(e) or e < 0x10000 + 184 then return nil end
        local b = e - 184
        local ty, id = ru32(b + 24), ru32(b + 28)
        if ty and id and ty > 0 and ty < GAME.layout.lim.PTR_HUGE and id < 0xFFFFFFF then
            return id, ty
        end
        return nil
    end
    local function emit_member_list(path, c) -- 单行叶重复不编号
        local d, n = rp(c), ru32(c + 12)
        if kptr(d) and n and n > 0 and n < GAME.layout.lim.PTR_HUGE then
            for i = 0, n - 1 do
                local id, ty = unit_ref(rp(d + 8 * i))
                if id then emit(tag, path, SL.idpair(id, ty)) end
            end
        end
    end

    -- ===== §4.24.7 CFrontSection =====
    local function emit_section(spath, sec)
        emit(tag, spath .. ".id", tostring(ru32(sec + 8) or 0))
        emit_ptrlist1(spath .. ".provinces", sec + 48, 164)
        emit_pairlist(spath .. ".sorted_pairs", sec + 72, true)
        local pd, pn = rp(sec + 24), ru32(sec + 36)
        if kptr(pd) and pn and pn > 0 and pn < GAME.layout.lim.PTR_SANE then
            local pseq = SL.seqc()
            for i = 0, pn - 1 do
                local e = pd + 24 * i
                local p = spath .. "." .. pseq("per_country_section")
                local tstr = tagstr(ru32(e + 8))
                emit(tag, p .. ".country", tstr and ('"' .. tstr .. '"')
                    or '"---"')
                emit(tag, p .. ".index", tostring(ru32(e + 12) or 0))
                emit(tag, p .. ".count", tostring(ru32(e + 16) or 0))
            end
        end
    end

    -- ===== §4.24.6 CFront =====
    local function emit_front(fpath, fr)
        emit(tag, fpath .. ".id",
            SL.idpair(ru32(fr + 12) or 0, ru32(fr + 8) or 0))
        emit(tag, fpath .. ".dirty", yn1(ru8(fr + 125)))
        emit_ptrlist1(fpath .. ".provinces", fr + 32, 164)
        local ed, en = rp(fr + 56), ru32(fr + 68)
        if kptr(ed) and en and en > 0 and en < 4096 then
            for i = 0, en - 1 do
                local tstr = tagstr(ru32(ed + 4 * i))
                if tstr then
                    emit(tag, fpath .. ".enemies.#" .. (i + 1),
                        '"' .. tstr .. '"')
                end
            end
        end
        emit(tag, fpath .. ".id_counter", tostring(ru32(fr + 80) or 0))
        local sd, sn = rp(fr + 88), ru32(fr + 100)
        if kptr(sd) and sn and sn > 0 and sn < 4096 then
            local sseq = SL.seqc()
            for i = 0, sn - 1 do
                local sec = rp(sd + 8 * i)
                if kptr(sec) then
                    emit_section(fpath .. "." .. sseq("section"), sec)
                end
            end
        end
        local ap = rp(fr + 112)
        local aq = kptr(ap) and rp(ap + 40) or nil
        if kptr(aq) then
            emit(tag, fpath .. ".area", tostring(ru32(aq + 164) or 0))
        end
    end

    -- ===== §4.24.5 COrderInstance (order_instance/fallback/virtual_fallback 同类) ==
    local emit_oi
    emit_oi = function(oipath, oi)
        local otype = ru32(oi + 48) or 0
        if otype == 3 then -- convoys 块先于 type (CConvoySubscriber@+8)
            emit(tag, oipath .. ".convoys.convoys",
                tostring(ru32(oi + 16) or 0))
            emit(tag, oipath .. ".convoys.total",
                tostring(ru32(oi + 20) or 0))
        end
        emit(tag, oipath .. ".type", tostring(otype))
        emit_u32list(oipath .. ".path", oi + 112)
        emit_u32list(oipath .. ".states", oi + 224)
        emit(tag, oipath .. ".instance_id", tostring(ru32(oi + 580) or 0))
        if (ru8(oi + 665) or 0) ~= 0 then
            emit(tag, oipath .. ".virtual_order", "yes") end
        local vc = ru32(oi + 668)
        if vc and vc ~= 0 then
            emit(tag, oipath .. ".virtual_creator", tostring(vc)) end
        local ch = ru32(oi + 72)
        if ch and ch ~= 0 then
            emit(tag, oipath .. ".creation_date", datef(ch)) end
        local sh = ru32(oi + 96)
        if sh and sh ~= 0 then
            emit(tag, oipath .. ".starting_date", datef(sh)) end
        emit_u32list(oipath .. ".virtually_created", oi + 672)
        local function sso_key(key, base, guard)
            if (rp(base + 16) or 0) ~= 0 then
                local s = SL.sso(base)
                if s and s ~= "" then emit(tag, oipath .. "." .. key,
                    '"' .. s .. '"') end
            end
        end
        sso_key("operation", oi + 288)
        sso_key("unique", oi + 384)
        sso_key("first", oi + 320)
        sso_key("second", oi + 352)
        sso_key("prefix", oi + 416)
        sso_key("postfix", oi + 448)
        do -- floating_harbor (id 对 {type@+920, id@+924}, 非零才写) +
           -- floating_harbor_hp (fix5 i64@+928 ≠0 才写) — 仅 type=3
           -- (两栖入侵) 实例实证
            local fht, fhi = ru32(oi + 920), ru32(oi + 924)
            if (fht or 0) ~= 0 or (fhi or 0) ~= 0 then
                emit(tag, oipath .. ".floating_harbor", SL.idpair(fhi, fht))
                local fhp = ri64(oi + 928) or 0
                if fhp ~= 0 then
                    emit(tag, oipath .. ".floating_harbor_hp",
                        SL.num(fhp * 1e-5))
                end
            end
        end
        if (ru32(oi + 148) or 0) > 0 then
            emit_pairlist(oipath .. ".sorted_pairs", oi + 136, false)
            emit(tag, oipath .. ".sorted_pairs_from",
                tostring(ru32(oi + 160) or 0))
            emit(tag, oipath .. ".sorted_pairs_to",
                tostring(ru32(oi + 164) or 0))
        end
        do -- enemy_controller_area 缓存链
            local ca = rp(oi + 168)
            if kptr(ca) and (ru32(ca + 60) or 0) > 0 then
                local a2p = rp(ca + 40)
                local lp = kptr(a2p) and rp(a2p + 184) or nil
                if kptr(lp) and ((ru8(lp + 210) or 0) & 1) == 1 then
                    emit(tag, oipath .. ".enemy_controller_area",
                        tostring(ru32(a2p + 164) or 0))
                end
            end
        end
        local cex = ru8(oi + 584)
        if cex and cex ~= 0 then
            emit(tag, oipath .. ".can_execute", tostring(cex)) end
        emit_member_list(oipath .. ".scheduled_member", oi + 528)
        emit_member_list(oipath .. ".transported_member", oi + 552)
        local atm = ru32(oi + 576)
        if atm and atm ~= 0 then
            emit(tag, oipath .. ".all_transported_members", tostring(atm)) end
        do -- order_children / order_virtual_children: 值=ru32(elem+580)
            local cd, cn = rp(oi + 504), ru32(oi + 516)
            if kptr(cd) and cn and cn > 0 and cn < 4096 then
                for i = 0, cn - 1 do
                    local e = rp(cd + 8 * i)
                    if kptr(e) then
                        emit(tag, oipath .. ".order_children",
                            tostring(ru32(e + 580) or 0))
                    end
                end
            end
            local vd, vn = rp(oi + 720), ru32(oi + 732)
            if kptr(vd) and vn and vn > 0 and vn < 4096 then
                for i = 0, vn - 1 do
                    local e = rp(vd + 8 * i)
                    if kptr(e) then
                        emit(tag, oipath .. ".order_virtual_children",
                            tostring(ru32(e + 580) or 0))
                    end
                end
            end
        end
        local inv = ru32(oi + 184)
        if inv and inv ~= 0 then
            emit(tag, oipath .. ".invasion_source", tostring(inv)) end
        if (ru8(oi + 280) or 0) ~= 0 then
            emit(tag, oipath .. ".blitz", "yes")
            emit_u32list(oipath .. ".blitz_provinces", oi + 800)
        end
        if (ru8(oi + 281) or 0) ~= 0 then
            emit(tag, oipath .. ".withdraw", "yes")
            local wd, wn = rp(oi + 856), ru32(oi + 868)
            if kptr(wd) and wn and wn > 0 and wn < 4096 then
                for i = 0, wn - 1 do
                    local e = wd + 24 * i
                    local d2, n2 = rp(e), ru32(e + 12)
                    if kptr(d2) and n2 and n2 > 0 and n2 < GAME.layout.lim.PTR_HUGE then
                        local t = {}
                        for j = 0, n2 - 1 do
                            t[#t + 1] = tostring(ru32(d2 + 4 * j) or 0) end
                        emit(tag, oipath .. ".withdraw_lines.#" .. (i + 1),
                            table.concat(t, " "))
                    end
                end
            end
        end
        if (rp(oi + 600) or 0) ~= SENT then -- root_front 守卫 (哨兵=无效)
            emit(tag, oipath .. ".root_front",
                SL.idpair(ru32(oi + 604) or 0, ru32(oi + 600) or 0))
            local rs = ru32(oi + 608)
            if rs and rs ~= 0 then
                emit(tag, oipath .. ".root_section", tostring(rs)) end
            if (ri64(oi + 616) or 0) ~= 0 or (ri64(oi + 624) or 0) ~= 100000
                then
                emit(tag, oipath .. ".from", SL.num(fix5(oi + 616)))
                emit(tag, oipath .. ".to", SL.num(fix5(oi + 624)))
            end
            local sf = ru32(oi + 632)
            if sf and sf ~= 0 then
                emit(tag, oipath .. ".split_from", tostring(sf)) end
        end
        emit_u32list(oipath .. ".midpoints", oi + 640)
        if (ru8(oi + 664) or 0) ~= 0 then
            emit(tag, oipath .. ".fallback", "yes") end
        if (ri64(oi + 216) or 0) ~= 0 then
            emit(tag, oipath .. ".time", SL.num(fix5(oi + 216))) end
        local ads = ru32(oi + 248)
        if ads and ads ~= 0 then
            emit(tag, oipath .. ".area_defense_settings", tostring(ads)) end
        do -- area_defense_state_assignment: stride32, 每元一单行叶
            local d, n = rp(oi + 256), ru32(oi + 268)
            if kptr(d) and n and n > 0 and n < GAME.layout.lim.PTR_HUGE then
                for i = 0, n - 1 do
                    local e = d + 32 * i
                    local t = { tostring(ru32(e) or 0) }
                    local d2, n2 = rp(e + 8), ru32(e + 20)
                    if kptr(d2) and n2 and n2 > 0 and n2 < 4096 then
                        for j = 0, n2 - 1 do
                            t[#t + 1] = tostring(ru32(d2 + 8 * j) or 0)
                            t[#t + 1] = tostring(ru32(d2 + 8 * j + 4) or 0)
                        end
                    end
                    emit(tag, oipath .. ".area_defense_state_assignment",
                        table.concat(t, " "))
                end
            end
        end
        if (ru8(oi + 282) or 0) ~= 0 then
            emit(tag, oipath .. ".route_is_ok", "yes") end
        local att = rp(oi + 888)
        if kptr(att) then
            emit(tag, oipath .. ".attach",
                SL.idpair(ru32(att + 12) or 0, ru32(att + 8) or 0))
        end
        emit(tag, oipath .. ".manage_child_sections", yn1(ru8(oi + 880)))
        do -- faction_theaters: i64 fix5 数组单行叶
            local fd, fn = rp(oi + 936), ru32(oi + 948)
            if kptr(fd) and fn and fn > 0 and fn < 4096 then
                local t = {}
                for i = 0, fn - 1 do
                    t[#t + 1] = SL.num((ri64(fd + 8 * i) or 0) * 1e-5) end
                emit(tag, oipath .. ".faction_theaters",
                    table.concat(t, " "))
            end
        end
    end

    -- ===== §4.24.3 COrdersGroup / §4.24.4 CArmyGroup =====
    local function emit_og(ogpath, og, is_fmg)
        if is_fmg then -- CArmyGroup 先写子 orders_group 引用 + collapse
            local d, n = rp(og + 560), ru32(og + 572)
            if kptr(d) and n and n > 0 and n < 4096 then
                for i = 0, n - 1 do
                    local e = rp(d + 8 * i)
                    if kptr(e) then
                        emit(tag, ogpath .. ".orders_group",
                            SL.idpair(ru32(e + 12) or 0, ru32(e + 8) or 0))
                    end
                end
            end
            if (ru8(og + 584) or 0) ~= 0 then
                emit(tag, ogpath .. ".collapse", "yes") end
        end
        emit(tag, ogpath .. ".id",
            SL.idpair(ru32(og + 12) or 0, ru32(og + 8) or 0))
        if (rp(og + 368) or 0) ~= 0 then
            local nm = SL.sso(og + 352)
            if nm and nm ~= "" then
                emit(tag, ogpath .. ".name", '"' .. nm .. '"') end
        end
        do -- §4.24.9 order_instance 家族树展开 (根 vec +152/+164; 收集器先序去重)
            local list, seen = {}, {}
            local function collect(o, offd, offc)
                local d, n = rp(o + offd), ru32(o + offc)
                if kptr(d) and n and n > 0 and n < 4096 then
                    for i = 0, n - 1 do
                        local ch = rp(d + 8 * i)
                        if kptr(ch) then
                            if not seen[ch] then
                                seen[ch] = true
                                list[#list + 1] = ch
                            end
                            collect(ch, offd, offc)
                        end
                    end
                end
            end
            local rd, rn = rp(og + 152), ru32(og + 164)
            if kptr(rd) and rn and rn > 0 and rn < 4096 then
                for i = 0, rn - 1 do
                    local root = rp(rd + 8 * i)
                    if kptr(root) then
                        if not seen[root] then
                            seen[root] = true
                            list[#list + 1] = root
                        end
                        collect(root, 504, 516)  -- order_children
                        collect(root, 720, 732)  -- order_virtual_children
                    end
                end
            end
            local oiseq = SL.seqc()
            for _, oi in ipairs(list) do
                emit_oi(ogpath .. "." .. oiseq("order_instance"), oi)
            end
        end
        do -- fallback / virtual_fallback (同为 COrderInstance)
            local fd, fn = rp(og + 176), ru32(og + 188)
            if kptr(fd) and fn and fn > 0 and fn < GAME.layout.lim.PTR_SANE then
                local fseq = SL.seqc()
                for i = 0, fn - 1 do
                    local o = rp(fd + 8 * i)
                    if kptr(o) then
                        emit_oi(ogpath .. "." .. fseq("fallback"), o) end
                end
            end
            local vd, vn = rp(og + 200), ru32(og + 212)
            if kptr(vd) and vn and vn > 0 and vn < GAME.layout.lim.PTR_SANE then
                local vseq = SL.seqc()
                for i = 0, vn - 1 do
                    local o = rp(vd + 8 * i)
                    if kptr(o) then
                        emit_oi(ogpath .. "." .. vseq("virtual_fallback"), o)
                    end
                end
            end
        end
        do -- member 块 (编号) { unit = id对 }
            local md, mn = rp(og + 80), ru32(og + 92)
            if kptr(md) and mn and mn > 0 and mn < GAME.layout.lim.PTR_HUGE then
                local mseq = SL.seqc()
                for i = 0, mn - 1 do
                    local id, ty = unit_ref(rp(md + 8 * i))
                    if id then
                        emit(tag, ogpath .. "." .. mseq("member") .. ".unit",
                            SL.idpair(id, ty))
                    end
                end
            end
        end
        local lu = rp(og + 104) -- leader_unit (unit+184 视角)
        if kptr(lu) then
            local id, ty = unit_ref(lu)
            if id then
                emit(tag, ogpath .. ".leader_unit", SL.idpair(id, ty)) end
        end
        local ld = rp(og + 136) -- §4.4.5 CArmyLeader leader (type@+8 id@+12)
        if kptr(ld) then
            emit(tag, ogpath .. ".leader",
                SL.idpair(ru32(ld + 12) or 0, ru32(ld + 8) or 0))
        end
        do -- pending_incoming_leader ref 对 (+144/+148, 非零才写)
            local t0, i0 = ru32(og + 144), ru32(og + 148)
            if (t0 and t0 ~= 0) or (i0 and i0 ~= 0) then
                emit(tag, ogpath .. ".pending_incoming_leader",
                    SL.idpair(i0 or 0, t0 or 0))
            end
        end
        if rf32 then -- color 恒写 (!readonly): (int)(f*255) 截断
            local r, g, b = rf32(og + 272), rf32(og + 276), rf32(og + 280)
            if r and g and b then
                local vals = string.format("%d %d %d",
                    math.floor(r * 255), math.floor(g * 255),
                    math.floor(b * 255))
                local a = rf32(og + 284)
                if a and a ~= 1.0 then
                    vals = vals .. string.format(" %d", math.floor(a * 255))
                end
                emit(tag, ogpath .. ".color", vals)
            end
        end
        emit(tag, ogpath .. ".icon", tostring(ru32(og + 288) or 0))
        if (rp(og + 292) or 0) ~= SENT then -- split_from ref 对
            emit(tag, ogpath .. ".split_from",
                SL.idpair(ru32(og + 296) or 0, ru32(og + 292) or 0))
        end
        if (ru8(og + 409) or 0) ~= 0 then
            emit(tag, ogpath .. ".deployed", "yes") end
        if (ru8(og + 410) or 0) ~= 0 then
            emit(tag, ogpath .. ".deploy_queued", "yes") end
        if (ru8(og + 408) or 0) ~= 0 then
            emit(tag, ogpath .. ".expeditionaries", "yes") end
        local hq = rp(og + 392) -- §4.24.10 hq_deploy_distributable (对象+24 视角)
        if kptr(hq) then
            local hp = ogpath .. ".hq_deploy_distributable"
            local prio = ru32(hq + 8)
            if prio and prio ~= 1 then
                emit(tag, hp .. ".priority", tostring(prio)) end
            local hct = tagstr(ru32(hq + 32))
            if hct then emit(tag, hp .. ".country", '"' .. hct .. '"') end
            do -- §4.24.10 hq_assembled_equipment (CEquipmentVariantPool@hq+40)
                local ap = hp .. ".hq_assembled_equipment"
                local d, n = rp(hq + 72), ru32(hq + 84)
                local az = ru8(hq + 96) or 0
                if kptr(d) and n and n > 0 and n < 4096 then
                    local eseq = SL.seqc()
                    for i = 0, n - 1 do
                        local e = d + 16 * i
                        local amt = ri64(e + 8) or 0
                        if amt ~= 0 or az ~= 0 then
                            local v = rp(e)
                            local ep = ap .. "." .. eseq("equipment")
                            if kptr(v) then
                                emit(tag, ep .. ".id", SL.idpair(
                                    ru32(v + 12) or 0, ru32(v + 8) or 0))
                            end
                            emit(tag, ep .. ".amount",
                                SL.num(amt * 1e-5))
                        end
                    end
                end
                emit(tag, ap .. ".allow_zero_entries", yn1(az))
            end
            do -- §4.24.10 hq_requested_equipment (CEquipmentArcheTypePool@hq+104)
                local rpth = hp .. ".hq_requested_equipment"
                local d, n = rp(hq + 112), ru32(hq + 124)
                if kptr(d) and n and n > 0 and n < 4096 then
                    for i = 0, n - 1 do
                        local e = d + 16 * i
                        local amt = ri64(e + 8) or 0
                        if amt ~= 0 then
                            local ar = rp(e)
                            local tk = kptr(ar) and ru32(ar + 8) or nil
                            local LAY = GAME.layout
                            local nm = tk and LAY and LAY.token_name(tk)
                                or nil
                            if type(nm) == "string" then
                                emit(tag, rpth .. "." .. nm,
                                    SL.num(amt * 1e-5))
                            end
                        end
                    end
                end
            end
            emit(tag, hp .. ".hq_assembled_manpower",
                tostring(ru32(hq + 136) or 0))
            emit(tag, hp .. ".hq_requested_manpower",
                tostring(ru32(hq + 140) or 0))
            emit(tag, hp .. ".hq_deploy_order", tostring(ru32(hq + 144) or 0))
            emit(tag, hp .. ".hq_requisitioned_from_army",
                yn1(ru8(hq + 148)))
        end
        do -- target_template ref 对 (+400/+404)
            local t0, i0 = ru32(og + 400), ru32(og + 404)
            if (t0 and t0 ~= 0) or (i0 and i0 ~= 0) then
                emit(tag, ogpath .. ".target_template",
                    SL.idpair(i0 or 0, t0 or 0))
            end
        end
        if (ru8(og + 411) or 0) ~= 0 then
            emit(tag, ogpath .. ".withdrawing", "yes") end
        if (ru8(og + 412) or 0) ~= 0 then
            emit(tag, ogpath .. ".unassign_on_withdraw", "yes") end
        if (ru8(og + 413) or 0) ~= 0 then
            emit(tag, ogpath .. ".training", "yes") end
        if (ru8(og + 416) or 0) ~= 0 then
            emit(tag, ogpath .. ".stop_training_at_max_xp", "yes") end
        emit(tag, ogpath .. ".plan_value", SL.num(fix5(og + 304)))
        emit(tag, ogpath .. ".our_power", SL.num(fix5(og + 312)))
        emit(tag, ogpath .. ".enemy_power", SL.num(fix5(og + 320)))
        if (ru8(og + 414) or 0) ~= 0 then
            emit(tag, ogpath .. ".members_has_changed", "yes") end
        emit(tag, ogpath .. ".execution_type",
            tostring(ru32(og + 420) or 0))
        emit(tag, ogpath .. ".cohesion_type", tostring(ru32(og + 424) or 0))
        emit(tag, ogpath .. ".proximity_type",
            tostring(ru32(og + 428) or 0))
        emit(tag, ogpath .. ".field_marshal_group", yn1(ru8(og + 57)))
        emit(tag, ogpath .. ".motorization_level",
            tostring(ru8(og + 56) or 0))
        local function i32_ge0(key, off) -- i32>=0 才写
            local v = ru32(off)
            if v and v < 0x80000000 then
                emit(tag, ogpath .. "." .. key, tostring(v)) end
        end
        i32_ge0("distance", og + 452)
        i32_ge0("hq_nearest_front_province_id", og + 456)
        i32_ge0("hq_distance_to_naval_invasion_source", og + 460)
        i32_ge0("cached_hq_naval_invasion_source_province_id", og + 464)
        local td = ru32(og + 468) -- timeout_days >0 才写
        if td and td ~= 0 and td < 0x80000000 then
            emit(tag, ogpath .. ".timeout_days", tostring(td)) end
    end

    -- ===== §4.24.8 CTheaterGroup =====
    local function emit_tg(tgpath, tg)
        emit(tag, tgpath .. ".id",
            SL.idpair(ru32(tg + 12) or 0, ru32(tg + 8) or 0))
        emit(tag, tgpath .. ".priority", tostring(ru32(tg + 32) or 0))
        local nm = SL.sso(tg + 40) -- name 恒写 (!readonly, 无守卫)
        emit(tag, tgpath .. ".name", '"' .. (nm or "") .. '"')
        local d, n = rp(tg + 72), ru32(tg + 84)
        if kptr(d) and n and n > 0 and n < 4096 then
            for i = 0, n - 1 do
                local e = rp(d + 8 * i)
                if kptr(e) then
                    emit(tag, tgpath .. ".orders_group",
                        SL.idpair(ru32(e + 12) or 0, ru32(e + 8) or 0))
                end
            end
        end
    end

    -- ===== §4.24.2 CTheatre 顶层: theatres 容器 {data@cc+360, count@cc+372} =====
    local td, tn = rp(cc + 360), ru32(cc + 372)
    if not (kptr(td) and tn and tn > 0 and tn <= 64) then return end
    local thseq = SL.seqc()
    for i = 0, tn - 1 do
        local th = rp(td + 8 * i)
        if kptr(th) then
            local tp = "theatres." .. thseq("theatre")
            emit(tag, tp .. ".id",
                SL.idpair(ru32(th + 12) or 0, ru32(th + 8) or 0))
            -- area: 元素对象两跳 ru32(rp(rp(elem)+40)+164) → area.#1
            local ad, an = rp(th + 24), ru32(th + 36)
            if kptr(ad) and an and an > 0 and an < GAME.layout.lim.PTR_HUGE then
                local t = {}
                for j = 0, an - 1 do
                    local e = rp(ad + 8 * j)
                    local q = kptr(e) and rp(e + 40) or nil
                    if kptr(q) then
                        t[#t + 1] = tostring(ru32(q + 164) or 0) end
                end
                if #t > 0 then
                    emit(tag, tp .. ".area.#1", table.concat(t, " ")) end
            end
            local ogd, ogn = rp(th + 128), ru32(th + 140)
            if kptr(ogd) and ogn and ogn > 0 and ogn < 4096 then
                local ogseq = SL.seqc()
                for j = 0, ogn - 1 do
                    local og = rp(ogd + 8 * j)
                    if kptr(og) then
                        emit_og(tp .. "." .. ogseq("orders_group"), og,
                            false)
                    end
                end
            end
            local fd, fn = rp(th + 152), ru32(th + 164)
            if kptr(fd) and fn and fn > 0 and fn < 4096 then
                local fseq = SL.seqc()
                for j = 0, fn - 1 do
                    local ag = rp(fd + 8 * j)
                    if kptr(ag) then
                        emit_og(tp .. "." .. fseq("field_marshal_group"),
                            ag, true)
                    end
                end
            end
            local gd, gn = rp(th + 200), ru32(th + 212)
            if kptr(gd) and gn and gn > 0 and gn < GAME.layout.lim.PTR_SANE then
                local gseq = SL.seqc()
                for j = 0, gn - 1 do
                    local tg = rp(gd + 8 * j)
                    if kptr(tg) then
                        emit_tg(tp .. "." .. gseq("theater_group"), tg) end
                end
            end
            local ud, un = rp(th + 104), ru32(th + 116)
            if kptr(ud) and un and un > 0 and un < GAME.layout.lim.PTR_HUGE then
                for j = 0, un - 1 do
                    local e = rp(ud + 8 * j)
                    if kptr(e) then
                        emit(tag, tp .. ".unit", SL.idpair(
                            ru32(e + 28) or 0, ru32(e + 24) or 0))
                    end
                end
            end
            local frd, frn = rp(th + 80), ru32(th + 92)
            if kptr(frd) and frn and frn > 0 and frn < 4096 then
                local frseq = SL.seqc()
                for j = 0, frn - 1 do
                    local fr = rp(frd + 8 * j)
                    if kptr(fr) then
                        emit_front(tp .. "." .. frseq("front"), fr) end
                end
            end
            local vt = ru32(th + 272) -- volunteers_theatre (tag_id>0)
            if vt and vt > 0 then
                local tstr = tagstr(vt)
                if tstr then
                    emit(tag, tp .. ".volunteers_theatre",
                        '"' .. tstr .. '"')
                end
            end
        end
    end
end }
