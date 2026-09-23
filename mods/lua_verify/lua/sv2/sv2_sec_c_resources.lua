-- sv2_sec_c_resources.lua -- country.resources 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.resources", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local BASE = ctx.BASE
    local kptr = SL.kptr
    -- §4.3.1 CCountryResources (cc+4600)
    local rs = rp(c.addr + 4600)
    if not (rs and kptr(rs) and rp(rs) == BASE + GAME.layout.vt.CCountryResources) then return end

    -- i64 无符号 raw → 有符号
    local function s64(v)
        if v then v = GAME.layout.as_i64(v) end
        return v
    end
    -- fixed5 原语 (同 U.fix5 语义, /100000 不 *1e-5)
    local function fix5raw(v)
        v = s64(v)
        return v and (v / 100000) or nil
    end
    local function fix5at(a) return fix5raw(rp(a)) end
    local function f64at(a)
        local v = hoi4.read_f64 and hoi4.read_f64(a) or nil
        if v == 0 then v = 0 end -- -0.0 归一
        return v
    end
    local function tagof(tid)
        if tid and tid > 0 then return c.R:tag(tid) end
        return nil
    end
    local function qd(h) -- hours → 引号日期 (nil 门)
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end

    -- 路由叶发射 (顶层 delivery_routes.<TAG> 与 origin 内嵌共用;
    -- rt 表 = objects_v2 读法字段 {type,from_state,...,sender tid 原值})
    local function emit_route(base, rt)
        if (rt.type or 0) ~= 0 then
            emit(tag, base .. ".type", tostring(rt.type))
        end
        if rt.from_state then
            emit(tag, base .. ".from_state", tostring(rt.from_state))
        end
        if rt.to_state then
            emit(tag, base .. ".to_state", tostring(rt.to_state))
        end
        if rt.from_port then
            emit(tag, base .. ".from_port", tostring(rt.from_port))
        end
        if rt.to_port then
            emit(tag, base .. ".to_port", tostring(rt.to_port))
        end
        local st = tagof(rt.sender)
        if st then emit(tag, base .. ".sender", '"' .. st .. '"') end
        local rt2 = tagof(rt.receiver)
        if rt2 then emit(tag, base .. ".receiver", '"' .. rt2 .. '"') end
        local co = tagof(rt.convoys_owner)
        if co then emit(tag, base .. ".convoys_owner", '"' .. co .. '"') end
        -- writer 先 naval 后 land (序不敏感)
        local np = {}
        for _, v in ipairs(rt.naval_path or {}) do
            if v then np[#np + 1] = tostring(v) end
        end
        if #np > 0 then
            emit(tag, base .. ".naval_path", table.concat(np, " "))
        end
        local lp = {}
        for _, v in ipairs(rt.land_path or {}) do
            if v then lp[#lp + 1] = tostring(v) end
        end
        if #lp > 0 then
            emit(tag, base .. ".land_path", table.concat(lp, " "))
        end
        -- blocker_tag/blocked_region (tid@+60 / ptr@+64→+96)
        if rt.blocker_tag then
            emit(tag, base .. ".blocker_tag", '"' .. rt.blocker_tag .. '"')
        end
        if rt.blocked_region then
            emit(tag, base .. ".blocked_region",
                tostring(rt.blocked_region))
        end
        emit(tag, base .. ".dirty", SL.yn(rt.dirty == true))
    end

    -- origin 块叶发射 (origin 与 extra_resource_origin.origin 共用;
    -- e = objects_v2 resources_origin/extra_origins 条目)
    -- §4.3.3 CCountryResources (origin 条目)
    local function emit_origin(base, e)
        if e.addr and (ru8(e.addr + 16) or 0) ~= 0 then -- id b@+16 门
            emit(tag, base .. ".id", e.id_pair)
        end
        if e.convoys_subscriber then -- total@+44≠0 门 (reader 已判)
            emit(tag, base .. ".convoys_subscriber.convoys",
                tostring(e.convoys_subscriber.convoys or 0))
            emit(tag, base .. ".convoys_subscriber.total",
                tostring(e.convoys_subscriber.total or 0))
        end
        local cq = SL.Q(e.country) -- country 恒写 (tid@+24)
        if cq then emit(tag, base .. ".country", cq) end
        if e.efficiency ~= nil then -- 第一效率 fixed5@+72
            emit(tag, base .. ".efficiency", SL.num(e.efficiency))
        end
        if e.efficiency_due_to_lost_convoys ~= nil then
            emit(tag, base .. ".efficiency_due_to_lost_convoys",
                SL.num(e.efficiency_due_to_lost_convoys))
        end
        emit(tag, base .. ".request", tostring(e.request or 0))
        if e.state then emit(tag, base .. ".state", tostring(e.state)) end
        for _, vec in ipairs({ { "resources", e.resources },
            { "resources_unclapmed", e.resources_unclapmed },
            { "buildings", e.buildings } }) do
            local map = vec[2] or {}
            -- 两级门 (同 CStrategicResourcePool 族 writer skip-scan)
            -- 块级 = 至少一个正值条目才整块写; 条目级 = 块写后 ≠0 全发。
            local haspos = false
            for rn, rv in pairs(map) do
                if rn ~= "x0" and rv and rv > 0 then haspos = true break end
            end
            if haspos then
                for rn, rv in pairs(map) do
                    if rn ~= "x0" and rv and rv ~= 0 then
                        emit(tag, base .. "." .. vec[1] .. "." .. rn,
                            SL.num(rv))
                    end
                end
            end
        end
        if e.efficiency2 ~= nil then -- 第二效率 fixed5@+840 (同键双写)
            emit(tag, base .. ".efficiency", SL.num(e.efficiency2))
        end
        if e.delivery_route then -- 内嵌 @+848 恒写
            emit_route(base .. ".delivery_route", e.delivery_route)
        end
        for rn, tg in pairs(e.given_resource_rights or {}) do
            emit(tag, base .. ".given_resource_rights",
                rn .. ' "' .. tostring(tg) .. '"')
        end
        if e.destination then
            emit(tag, base .. ".destination", tostring(e.destination))
        end
    end

    -- ===== 1. delivery_routes (rs+1928/1940, writer 跳 idx0 哨兵) =====
    -- §4.3.3 CCountryResources
    do
        local rd, rc = rp(rs + 1928), ru32(rs + 1940) or 0
        if kptr(rd) and rc > 1 and rc < 100000 then
            for i = 1, rc - 1 do
                local r = rp(rd + 8 * i)
                if r and kptr(r) and rp(r) == BASE + GAME.layout.vt.CResourceDelivery then
                    local rtag = tagof(ru32(r + 52) or 0)
                    if rtag then -- 块名 = receiver tag
                        local t = { addr = r,
                            type = (ru32(r + 8) or 0) % 256,
                            sender = ru32(r + 48), receiver = ru32(r + 52),
                            convoys_owner = ru32(r + 56),
                            -- blocker_tag tid i32@r+60 (>0) /
                            -- blocked_region ptr@r+64 → u32@ptr+96
                            blocker_tag = (function()
                                local bt = ru32(r + 60)
                                return bt and bt > 0 and tagof(bt) or nil
                            end)(),
                            blocked_region = (function()
                                local bp = rp(r + 64)
                                return kptr(bp) and ru32(bp + 96) or nil
                            end)(),
                            dirty = ((ru32(r + 120) or 0) % 256) ~= 0,
                            land_path = {}, naval_path = {} }
                        local fp = rp(r + 16)
                        if kptr(fp) then t.from_state = ru32(fp + 88) end
                        local tp = rp(r + 24)
                        if kptr(tp) then t.to_state = ru32(tp + 88) end
                        local fpp = rp(r + 32)
                        if kptr(fpp) then t.from_port = ru32(fpp + 164) end
                        local tpp = rp(r + 40)
                        if kptr(tpp) then t.to_port = ru32(tpp + 164) end
                        local ld, lc = rp(r + 72), ru32(r + 84) or 0
                        if kptr(ld) and lc > 0 and lc < GAME.layout.lim.PTR_SANE then
                            for k = 0, lc - 1 do
                                local sp = rp(ld + 8 * k)
                                t.land_path[#t.land_path + 1] =
                                    kptr(sp) and ru32(sp + 88) or nil
                            end
                        end
                        local nd, nc = rp(r + 96), ru32(r + 108) or 0
                        if kptr(nd) and nc > 0 and nc < GAME.layout.lim.PTR_SANE then
                            for k = 0, nc - 1 do
                                local sp = rp(nd + 8 * k)
                                t.naval_path[#t.naval_path + 1] =
                                    kptr(sp) and ru32(sp + 88) or nil
                            end
                        end
                        emit_route("resources.delivery_routes." .. rtag, t)
                    end
                end
            end
        end
    end

    -- ===== 2. extra_resource_origin (rs+1976, 16B {ptr, giver tid}) =====
    -- §4.3.3 CCountryResources
    do
        local r = c:resources_extra_origins()
        if r and r.list then
            local seq = SL.seqc()
            for _, e in ipairs(r.list) do
                local base = seq("resources.extra_resource_origin")
                emit_origin(base .. ".origin", e)
                local gq = SL.Q(e.giver)
                if gq then emit(tag, base .. ".giver", gq) end
            end
        end
    end

    -- ===== 3. dirty (u8@rs+2000 恒写) =====
    emit(tag, "resources.dirty", ((ru32(rs + 2000) or 0) % 256) ~= 0
        and "yes" or "no")

    -- ===== 4/5. 六向量 + to_use (reader resources_vecs, raw i64) =====
    -- §4.3.1 CCountryResources
    do
        local rv = c:resources_vecs()
        if rv then
            for _, vn in ipairs({ "produced", "transfer_overlord_subject",
                "imported", "to_export", "base_export", "exported" }) do
                for rn, raw in pairs(rv[vn] or {}) do
                    local v = fix5raw(raw)
                    if v and v ~= 0 then -- 0 槽 writer 省略
                        emit(tag, "resources." .. vn .. "." .. rn, SL.num(v))
                    end
                end
            end
            local tu = rv.to_use or {}
            local t1, t2, t3 = tu["1"] or {}, tu["2"] or {}, tu["3"] or {}
            for rn, raw in pairs(t1) do
                local v = fix5raw(raw)
                if v and v ~= 0 then
                    emit(tag, "resources.to_use.#1." .. rn, SL.num(v))
                end
            end
            -- #2 = 槽1−槽0 增量 (本档恒 0)
            local keys = {}
            for rn in pairs(t1) do keys[rn] = true end
            for rn in pairs(t2) do keys[rn] = true end
            for rn in pairs(keys) do
                local d = (s64(t2[rn]) or 0) - (s64(t1[rn]) or 0)
                if d ~= 0 then
                    emit(tag, "resources.to_use.#2." .. rn, SL.num(d / 100000))
                end
            end
            for rn, raw in pairs(t3) do
                local v = fix5raw(raw)
                if v and v ~= 0 then
                    emit(tag, "resources.to_use.#3." .. rn, SL.num(v))
                end
            end
        end
    end

    -- ===== 6. origin (rs+1808/1820) =====
    -- §4.3.3 CCountryResources
    do
        local r = c:resources_origin()
        if r and r.list then
            local seq = SL.seqc()
            for _, e in ipairs(r.list) do
                emit_origin(seq("resources.origin"), e)
            end
        end
    end

    -- ===== 7. export (rs+1832 槽阵列, writer 槽 0 起 — 内联重写) =====
    do
        local d = rp(rs + 1832)
        local nslot = ru32(rs + 1844) or 0
        if kptr(d) and nslot > 0 and nslot < GAME.layout.lim.PTR_SANE then
            local seq = SL.seqc()
            for slot = 0, nslot - 1 do
                local arr = rp(d + 24 * slot)
                local cn = ru32(d + 24 * slot + 12) or 0
                if kptr(arr) and cn > 0 and cn < 4096 then
                    for j = 0, cn - 1 do
                        local el = rp(arr + 8 * j)
                        if kptr(el) then
                            local base = seq("resources.export")
                            if (ru8(el + 16) or 0) ~= 0 then -- id b@+16 门
                                emit(tag, base .. ".id", SL.idpair(
                                    ru32(el + 12), ru32(el + 8)))
                            end
                            local cst = ru32(el + 44) or 0
                            if cst ~= 0 then -- convoys_subscriber 门
                                emit(tag, base .. ".convoys_subscriber.convoys",
                                    tostring(ru32(el + 40) or 0))
                                emit(tag, base .. ".convoys_subscriber.total",
                                    tostring(cst))
                            end
                            -- spotter 内联 idpair
                            -- {type@el+112, id@el+116} 任≠0 才写
                            local spt, spi = ru32(el + 112) or 0,
                                ru32(el + 116) or 0
                            if spt ~= 0 or spi ~= 0 then
                                emit(tag, base .. ".spotter",
                                    SL.idpair(spi, spt))
                            end
                            local cq = SL.Q(tagof(ru32(el + 24)))
                            if cq then emit(tag, base .. ".country", cq) end
                            local eff = fix5at(el + 72)
                            if eff ~= nil then
                                emit(tag, base .. ".efficiency", SL.num(eff))
                            end
                            local due = fix5at(el + 80)
                            if due ~= nil then
                                emit(tag, base ..
                                    ".efficiency_due_to_lost_convoys",
                                    SL.num(due))
                            end
                            emit(tag, base .. ".request",
                                tostring(ru32(el + 120) or 0))
                            -- combat (0x2916: {d@el+88, c@el+100}
                            -- 元 8B {type@0, id@+4} c≠0 块门)
                            local ebd, ebc = rp(el + 88), ru32(el + 100) or 0
                            if kptr(ebd) and ebc > 0
                                and ebc <= GAME.layout.lim.FIXED_SMALL then
                                for q5 = 0, ebc - 1 do
                                    emit(tag, base .. ".combat.#" .. (q5 + 1),
                                        SL.idpair(ru32(ebd + 8 * q5 + 4),
                                                  ru32(ebd + 8 * q5)))
                                end
                            end
                            local rq = SL.Q(tagof(ru32(el + 136)))
                            if rq then emit(tag, base .. ".receiver", rq) end
                            local rp144 = rp(el + 144) -- resource ptr 门
                            if kptr(rp144) then
                                local nm = SL.tok(ru32(rp144 + 8))
                                if nm then
                                    emit(tag, base .. ".resource",
                                        '"' .. tostring(nm) .. '"')
                                end
                            end
                            local dv = fix5at(el + 152) -- delivered 恒
                            if dv ~= nil then
                                emit(tag, base .. ".delivered", SL.num(dv))
                            end
                            local dp = rp(el + 160) -- destination ptr 门
                            if kptr(dp) then
                                emit(tag, base .. ".destination",
                                    tostring(ru32(dp + 88) or 0))
                            end
                            local op = rp(el + 168) -- origin ptr 门
                            if kptr(op) then
                                emit(tag, base .. ".origin",
                                    tostring(ru32(op + 88) or 0))
                            end
                            local sd = qd(ru32(el + 184)) -- start_date 恒
                            if sd then emit(tag, base .. ".start_date", sd) end
                            local lr = qd(ru32(el + 208)) -- last_recalc 恒
                            if lr then
                                emit(tag, base .. ".last_recalc_date", lr)
                            end
                            emit(tag, base .. ".required_cic",
                                tostring(ru32(el + 224) or 0))
                            emit(tag, base .. ".lended_cic",
                                tostring(ru32(el + 228) or 0))
                        end
                    end
                end
            end
        end
    end

    -- ===== 8. lend_lease (rs+1880/1892; 内联, writer 0x14195B480) =====
    -- §4.23.3 CLendLeaseExchange
    do
        local ld, lc = rp(rs + 1880), ru32(rs + 1892) or 0
        if kptr(ld) and lc > 0 and lc < GAME.layout.lim.PTR_SANE then
            local seq = SL.seqc()
            local MAPS = { { 216, "equipment_need" },
                { 280, "percentage_need" }, { 344, "once_need" },
                { 472, "equipment_collected" }, { 600, "equipment_prepared" },
                { 664, "equipment_sunk" }, { 728, "total_delivered" } }
            for j = 0, lc - 1 do
                local ll = rp(ld + 8 * j)
                if kptr(ll) then
                    local base = seq("resources.lend_lease")
                    local rq = SL.Q(tagof(ru32(ll + 184))) -- receiver 恒
                    if rq then emit(tag, base .. ".receiver", rq) end
                    local dp = rp(ll + 200) -- destination ptr 门
                    if kptr(dp) then
                        emit(tag, base .. ".destination",
                            tostring(ru32(dp + 88) or 0))
                    end
                    local op = rp(ll + 208) -- origin ptr 门
                    if kptr(op) then
                        emit(tag, base .. ".origin",
                            tostring(ru32(op + 88) or 0))
                    end
                    emit(tag, base .. ".sender.convoys",
                        tostring(ru32(ll + 144) or 0))
                    emit(tag, base .. ".sender.total",
                        tostring(ru32(ll + 148) or 0))
                    for _, mi in ipairs(MAPS) do
                        local slot, mname = mi[1], mi[2]
                        local allow = ru8(ll + slot + 56) or 0
                        local md = rp(ll + slot + 32)
                        local mc = ru32(ll + slot + 44) or 0
                        local eqseq = SL.seqc()
                        if kptr(md) and mc > 0 and mc < 4096 then
                            for k = 0, mc - 1 do
                                local amt = s64(rp(md + 16 * k + 8))
                                if (amt and amt ~= 0) or allow ~= 0 then
                                    local vp = rp(md + 16 * k)
                                    if kptr(vp) then
                                        local eqb = eqseq(base .. "." ..
                                            mname .. ".equipment")
                                        emit(tag, eqb .. ".id", SL.idpair(
                                            ru32(vp + 12), ru32(vp + 8)))
                                        emit(tag, eqb .. ".amount",
                                            SL.num((amt or 0) / 100000))
                                    end
                                end
                            end
                        end
                        emit(tag, base .. "." .. mname ..
                            ".allow_zero_entries", SL.yn(allow))
                    end
                    local ldq = qd(ru32(ll + 800)) -- last_delivery_date 恒
                    if ldq then
                        emit(tag, base .. ".last_delivery_date", ldq)
                    end
                    local asq = qd(ru32(ll + 824)) -- active_since 恒
                    if asq then emit(tag, base .. ".active_since", asq) end
                    local fd = f64at(ll + 848) -- fuel_daily f64
                    if fd then
                        emit(tag, base .. ".fuel_daily",
                            string.format("%.5f", fd))
                    end
                    local fpct = fix5at(ll + 856) -- fuel_percentage fixed5!
                    if fpct ~= nil then
                        emit(tag, base .. ".fuel_percentage", SL.num(fpct))
                    end
                    local fs = f64at(ll + 864) -- fuel_sent f64
                    if fs then
                        emit(tag, base .. ".fuel_sent",
                            string.format("%.5f", fs))
                    end
                    local fk = f64at(ll + 872) -- fuel_sunk f64
                    if fk then
                        emit(tag, base .. ".fuel_sunk",
                            string.format("%.5f", fk))
                    end
                    local lf = f64at(ll + 880) -- last_fuel_delivered f64
                    if lf then
                        emit(tag, base .. ".last_fuel_delivered",
                            string.format("%.5f", lf))
                    end
                    -- base 0x140CAE9F0 (writer 尾部)
                    if (ru8(ll + 16) or 0) ~= 0 then -- id b@+16 门
                        emit(tag, base .. ".id",
                            SL.idpair(ru32(ll + 12), ru32(ll + 8)))
                    end
                    local cst = ru32(ll + 44) or 0
                    if cst ~= 0 then -- convoys_subscriber 门
                        emit(tag, base .. ".convoys_subscriber.convoys",
                            tostring(ru32(ll + 40) or 0))
                        emit(tag, base .. ".convoys_subscriber.total",
                            tostring(cst))
                    end
                    local cq = SL.Q(tagof(ru32(ll + 24))) -- country 恒
                    if cq then emit(tag, base .. ".country", cq) end
                    local eff = fix5at(ll + 72)
                    if eff ~= nil then
                        emit(tag, base .. ".efficiency", SL.num(eff))
                    end
                    local due = fix5at(ll + 80)
                    if due ~= nil then
                        emit(tag, base .. ".efficiency_due_to_lost_convoys",
                            SL.num(due))
                    end
                    emit(tag, base .. ".request",
                        tostring(ru32(ll + 120) or 0))
                end
            end
        end
    end

    -- ===== 9. modify_building_resources (rs+1952/1964 — §4.3.3 建筑→
    -- 资源产出表; 字段细目书标「推定」) — savefull 未知块折叠契约:
    -- 叶 <building>.<level> 值 = "level=amt }" (save 原文 "3=3 }")
    do
        local mdd, mdc = rp(rs + 1952), ru32(rs + 1964) or 0
        if kptr(mdd) and mdc > 0 and mdc <= GAME.layout.lim.PTR_SANE then
            for k = 0, mdc - 1 do
                local e = mdd + 32 * k
                local bname = SL.tok(ru32(e) or 0)
                local idn = rp(e + 8)
                local icn = ru32(e + 20) or 0
                if bname and kptr(idn) and icn > 0
                    and icn <= GAME.layout.lim.FIXED_SMALL then
                    for q6 = 0, icn - 1 do
                        local lvl = ru32(idn + 16 * q6) or 0
                        local amt = s64(rp(idn + 16 * q6 + 8)) or 0
                        emit(tag, "resources.modify_building_resources."
                            .. bname .. "." .. lvl,
                            lvl .. "=" .. SL.num(amt / 100000) .. " }")
                    end
                end
            end
        end
    end
end }
