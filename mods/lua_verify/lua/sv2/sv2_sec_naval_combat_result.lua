-- sv2_sec_naval_combat_result.lua -- 顶层 naval_combat_result 匿名重复块

SV2.gsec[#SV2.gsec + 1] = { name = "naval_combat_result", emit = function(ctx)
    local SL, O, emit = SV2.lib, ctx.O, ctx.emit
    local rp, ru32, ru8, rf64 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8,
        hoi4.read_f64
    local gs, BASE = ctx.gs, ctx.BASE
    local kptr = SL.kptr
    local LIM = GAME.layout.lim.PTR_SANE
    local NULLREF = rp(BASE + 0x333D528) -- §4.22.6 空 id 对哨兵 qword_14333D528
    -- §4.22.6 CNavalCombatResults 主数组 (gs+1472 {d}, count@gs+1484)
    local d, c = rp(gs + 0x5C0), ru32(gs + 0x5CC)
    if not (d and c and c > 0 and c < LIM) then return end

    local dim
    local function E(path, val)
        if val ~= nil then emit(dim, path, val) end
    end

    local function idpair(ty, id)
        return "id=" .. tostring(id or 0) .. " type=" .. tostring(ty or 0)
    end

    local function fix5(a)
        local v = rp(a)
        if not v then return nil end
        v = GAME.layout.as_i64(v)
        return v * 1e-5
    end

    -- §4.22.6 SNavalHit 条目 (六字段全恒写)
    local function emit_naval_hits(prefix, dd, dc)
        local seq = SL.seqc()
        for k = 0, dc - 1 do
            local en = rp(dd + 8 * k)
            if kptr(en) then
                local nb = prefix .. seq("naval_hit") .. "."
                E(nb .. "target", tostring(ru32(en + 8) or 0))
                local nmn = SL.sso(en + 16)
                if nmn then E(nb .. "name", '"' .. nmn .. '"') end
                E(nb .. "convoy", (ru8(en + 48) or 0) ~= 0 and "yes" or "no")
                E(nb .. "damage", SL.num(fix5(en + 56)))
                E(nb .. "strength", SL.num(fix5(en + 64)))
                E(nb .. "last_hit", (ru8(en + 72) or 0) ~= 0
                    and "yes" or "no")
            end
        end
    end

    -- §4.22.6 SAirHit 条目
    local function emit_air_hits(prefix, dd, dc)
        local seq = SL.seqc()
        for k = 0, dc - 1 do
            local en = rp(dd + 8 * k)
            if kptr(en) then
                local ab = prefix .. seq("air_hit") .. "."
                local tg = ru32(en + 0x14)
                if tg and tg > 0 then
                    local s = O:tag(tg)
                    if s then E(ab .. "tag", '"' .. s .. '"') end
                end
                local ev = rp(en + 8)
                if kptr(ev) then
                    E(ab .. "equipment_variant_index",
                        idpair(ru32(ev + 8), ru32(ev + 12)))
                end
                E(ab .. "count", tostring(ru32(en + 0x10) or 0))
            end
        end
    end

    -- §4.22.6 CNavalCombatAirEntry 条目
    local function emit_air_wings(prefix, dd, dc)
        local seq = SL.seqc()
        for k = 0, dc - 1 do
            local aw = rp(dd + 8 * k)
            if kptr(aw) then
                local ab = prefix .. seq("air_wing") .. "."
                local ev = rp(aw + 8)
                if kptr(ev) then
                    E(ab .. "equipment_variant_index",
                        idpair(ru32(ev + 8), ru32(ev + 12)))
                end
                E(ab .. "max", tostring(ru32(aw + 16) or 0))
                E(ab .. "alive", tostring(ru32(aw + 20) or 0))
                local kl = ru32(aw + 24)
                if kl and kl > 0 then E(ab .. "killed", tostring(kl)) end
                local tg = ru32(aw + 28)
                if tg and tg > 0 then
                    local s = O:tag(tg)
                    if s then E(ab .. "tag", '"' .. s .. '"') end
                end
                local abn = SL.sso(aw + 32)
                if abn then E(ab .. "air_base", '"' .. abn .. '"') end
                local nhd, nhc = rp(aw + 64), ru32(aw + 76) or 0
                if kptr(nhd) and nhc > 0 then
                    emit_naval_hits(ab, nhd, nhc) end
                local ahd, ahc = rp(aw + 88), ru32(aw + 100) or 0
                if kptr(ahd) and ahc > 0 then
                    emit_air_hits(ab, ahd, ahc) end
            end
        end
    end

    -- §4.22.6 SCachedInfo (结构同 §4.22.5 member.cached_info)
    local function emit_cached_info(base, ci)
        local sp = SL.sso(ci + 0x70)
        if sp then E(base .. "sprite", '"' .. sp .. '"') end
        E(base .. "index", tostring(ru32(ci + 0x0C) or 0))
        E(base .. "type", tostring(ru32(ci + 0x10) or 0))
        local ctg = ru32(ci + 8)
        if ctg and ctg > 0 then
            local s = O:tag(ctg)
            if s then E(base .. "tag", '"' .. s .. '"') end
        end
        local stv = fix5(ci + 0x20)   -- 实证: fixed5 非 f64 (mem=0 教训)
        if stv and stv ~= 0 then E(base .. "strength", SL.num(stv)) end
        local sb = SL.sso(ci + 0x90)
        if sb and sb ~= "" then E(base .. "sunk_by", '"' .. sb .. '"') end
        if (ru8(ci + 0x29) or 0) ~= 0 then E(base .. "convoy", "yes") end
        local bci = fix5(ci + 0x18)
        if bci and bci ~= 0 then E(base .. "build_cost_ic", SL.num(bci)) end
        local evn = SL.sso(ci + 0x50)
        if evn then E(base .. "equipment_variant", '"' .. evn .. '"') end
        local hev = rp(ci + 0xB0)
        if hev and hev ~= NULLREF then
            E(base .. "highest_eq_variant",
                idpair(ru32(ci + 0xB0), ru32(ci + 0xB4)))
        end
        local shn = SL.sso(ci + 0x30)
        if shn and shn ~= "" then E(base .. "ship", '"' .. shn .. '"') end
        if (ru8(ci + 0x28) or 0) ~= 0 then
            E(base .. "pride_of_the_fleet", "yes") end
        local cid, cid2 = ru32(ci + 0xB8), ru32(ci + 0xBC)
        if (cid and cid ~= 0) or (cid2 and cid2 ~= 0) then
            E(base .. "convoy_id", idpair(cid, cid2))
        end
        local cidx = ru32(ci + 0xC0) or 0
        if cidx < 0x80000000 then
            E(base .. "convoy_index", tostring(cidx)) end
    end

    -- §4.22.6 CNavalCombatShipEntry 条目
    local function emit_ships(prefix, dd, dc)
        local seq = SL.seqc()
        for k = 0, dc - 1 do
            local sh = rp(dd + 8 * k)
            if kptr(sh) then
                local sb = prefix .. seq("ship") .. "."
                E(sb .. "unique_id", idpair(ru32(sh + 8), ru32(sh + 12)))
                emit_cached_info(sb .. "cached_info.", sh + 16)
                local nhd, nhc = rp(sh + 0xD8), ru32(sh + 0xE4) or 0
                if kptr(nhd) and nhc > 0 then
                    emit_naval_hits(sb, nhd, nhc) end
                local ahd, ahc = rp(sh + 0xF0), ru32(sh + 0xFC) or 0
                if kptr(ahd) and ahc > 0 then
                    emit_air_hits(sb, ahd, ahc) end
            end
        end
    end

    -- §4.1.7 三注册表源 (sub_14221F310 三档 id 库): ty>0x1268 / >=100 / <100
    -- → 委派统一访问器 GAME.layout.idreg_unit_resolve (resource.lua 唯一实现;
    --   本段原有一份逐字重复的本地副本, 已删)
    local function ref_resolve(ty, id)
        return GAME.layout.idreg_unit_resolve(ty, id)
    end

    -- §4.22.6 CNavalCombatResultSide 侧对象 (内嵌 112B)
    local function emit_side(prefix, s)
        -- seq 名在子函数内加 (prefix 不含块名, 防双拼)
        emit_air_wings(prefix, rp(s + 8), ru32(s + 20) or 0)
        emit_ships(prefix, rp(s + 32), ru32(s + 44) or 0)
        local cd2, cc2 = rp(s + 56), ru32(s + 68)
        if kptr(cd2) and cc2 and cc2 ~= 0 then
            -- 匿名块 #N 恒编号 (seqc("#1") 二次产 "#1[2]",
            -- 存档折 #1/#2 — 手动计数)
            local nj = 0
            for k = 0, cc2 - 1 do
                local cid = ru32(cd2 + 4 * k)
                local s2 = cid and cid > 0 and O:tag(cid) or nil
                if s2 then
                    nj = nj + 1
                    E(prefix .. "countries.#" .. nj, '"' .. s2 .. '"')
                end
            end
        end
        local lty, lid = ru32(s + 80), ru32(s + 84)
        if lty == 4713 and lid ~= 0 and ref_resolve(lty, lid) then
            E(prefix .. "last_leader", idpair(lty, lid))
        end
    end

    -- §4.22.6 CNavalCombatResults 逐条 (发射序 id→location→date→attacker→
    -- defender→port_strike→naval_strike→importance→to_discard_date→
    -- shown_to_countries)
    local seq = SL.seqc()
    for i = 0, c - 1 do
        local e = rp(d + 8 * i)
        if not kptr(e) then break end
        dim = seq("naval_combat_result")
        E("id", idpair(ru32(e + 8), ru32(e + 12)))
        E("location", tostring(ru32(e + 0x108)))
        local dh = ru32(e + 0x118)
        local ds = SL.date(dh)
        if ds then E("date", '"' .. ds .. '"') end
        emit_side("attacker.", e + 0x18)
        emit_side("defender.", e + 0x88)
        E("port_strike", (ru8(e + 0x128) or 0) ~= 0 and "yes" or "no")
        E("naval_strike", (ru8(e + 0x129) or 0) ~= 0 and "yes" or "no")
        E("importance", tostring(ru32(e + 0x148) or 0))
        local tdh = ru32(e + 0x138)
        local tds = SL.date(tdh)
        if tds then E("to_discard_date", '"' .. tds .. '"') end
        local scd, scc = rp(e + 0x150), ru32(e + 0x15C)
        if kptr(scd) and scc and scc > 0 and scc < LIM then
            for j = 0, scc - 1 do
                local cid = ru32(scd + 4 * j)
                local s2 = cid and cid > 0 and O:tag(cid) or nil
                if s2 then
                    E("shown_to_countries.#" .. (j + 1), '"' .. s2 .. '"')
                end
            end
        end
    end
end }
