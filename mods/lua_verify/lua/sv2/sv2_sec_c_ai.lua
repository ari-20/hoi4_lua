-- sv2_sec_c_ai.lua -- country.ai 节点 savefull 直出 (csec)

SV2.csec[#SV2.csec + 1] = { name = "country.ai", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32 = SL.rp, SL.ru32
    local kptr = SL.kptr
    -- §4.3.19 CStrategicAI 标量簇: 挂载链 cc+552 → p; host = rp(p+2800);
    -- csa = host+2800 (内嵌; 帧约定 §4.34.5)
    -- §1.1 CGameState tag 串表 (sub_140BA5C20: rp(gs+0x358)+32*tid, 32B/项 SSO)
    local ttab = ctx.gs and rp(ctx.gs + 0x358) or nil
    local function tagof(tid)
        if not (ttab and kptr(ttab) and tid and tid > 0 and tid < 4096)
            then return nil end
        local s = SL.sso(ttab + 32 * tid)
        if s and s ~= "" then return s end
        return nil
    end
    local p = rp(c.addr + 552)
    if not kptr(p) then return end
    local host = rp(p + 2800)
    if not kptr(host) then return end
    local csa = host + 2800

    local i32 = GAME.layout.i32
    local function fix5(a) -- i64 ×1e-5 定点 (§3.7; 100000 勿 *1e-5)
        local v = rp(a) or 0
        v = GAME.layout.as_i64(v)
        return v / 100000
    end

    -- ===== §4.34.11 CStrategicAI 双 112 槽数组 (ai_strategy / persistent_strategy) =====
    local TOK_ID = { [9] = true, [16] = true, [21] = true } -- 0x210200 bits
    local function emit_slots(dbase, cbase, path, use_tok)
        for i = 0, 111 do
            local d, cnt = rp(dbase + 24 * i), ru32(cbase + 24 * i)
            if kptr(d) and cnt and cnt > 0 and cnt < 4096 then
                for j = 0, cnt - 1 do
                    local e = d + 12 * j
                    local id = ru32(e + 8) or 0
                    local ids
                    if use_tok and TOK_ID[i] then
                        local nm = SL.tok(id)
                        if type(nm) == "string" and nm:match("^[%a_][%w_]*$") then  -- 放宽收 CamelCase
                            ids = nm
                        else
                            ids = tostring(id)
                        end
                    else
                        ids = tostring(id)
                    end
                    local line = "type=" .. i .. " id=" .. ids
                    local t = ru32(e + 4) or 0
                    if t ~= 0 then line = line .. " target=" .. t end
                    line = line .. " value=" .. i32(e)
                    emit(tag, path, line)
                end
            end
        end
    end
    emit_slots(csa + 144, csa + 156, "ai.ai_strategy", true)   -- A: 0x3100
    emit_slots(csa + 2832, csa + 2844, "ai.persistent_strategy", false) -- B: 0x3A32

    -- ===== §4.3.19 CStrategicAI military_access (ptr 有效才写, 全零也写) =====
    local ma = rp(csa + 5808)
    if kptr(ma) then
        local g = ctx.gs
        -- 国家数运行时读 (§1.1 CGameState gs+796; 硬编码 440 在 mod 加国后即错)
        local n = (g and ru32(g + 0x31C)) or 0
        if n <= 0 or n > 65536 then return end
        local t = {}
        for i = 0, n - 1 do
            t[#t + 1] = tostring(ru32(ma + 4 * i) or 0)
        end
        emit(tag, "ai.military_access.#1", table.concat(t, " "))
    end

    -- ===== §4.3.19 CStrategicAI 标量簇 (恒写) =====
    emit(tag, "ai.days_until_next_rebuild_access_list",
        tostring(ru32(csa + 5700) or 0))
    emit(tag, "ai.days_to_need_update", tostring(ru32(csa + 5696) or 0))
    emit(tag, "ai.seed", string.format("%d %d",
        ru32(csa + 5940) or 0, ru32(csa + 5936) or 0))
    emit(tag, "ai.irrationality", tostring(i32(csa + 5960)))
    emit(tag, "ai.pp_spend_priority", tostring(ru32(csa + 6096) or 0))
    emit(tag, "ai.pp_spend_amount.#1", string.format("%s %s",
        SL.num(fix5(csa + 6104)), SL.num(fix5(csa + 6112))))
    emit(tag, "ai.num_wanted_divisions", tostring(i32(csa + 6132)))
    local DN = {
        { 5704, "desire_unlock_land_doctrine" },
        { 5712, "desire_unlock_naval_doctrine" },
        { 5720, "desire_unlock_air_doctrine" },
        { 5728, "desire_update_land_template" },
        { 5736, "desire_upgrade_land_equipment" },
        { 5744, "desire_upgrade_naval_equipment" },
        { 5752, "desire_upgrade_air_equipment" },
        { 5784, "desire_unlock_army_spirit" },
        { 5792, "desire_unlock_navy_spirit" },
        { 5800, "desire_unlock_air_spirit" },
        { 5760, "reserved_xp_land_research" },
        { 5768, "reserved_xp_naval_research" },
        { 5776, "reserved_xp_air_research" },
    }
    for _, d in ipairs(DN) do
        emit(tag, "ai." .. d[2], SL.num(fix5(csa + d[1])))
    end

    -- ===== §4.34.11 CStrategicAI allowed_strategy_plans (count>0 才写) =====
    local pd, pc = rp(csa + 5520), ru32(csa + 5532)
    if kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_SANE then
        local plans = {}
        for k = 0, pc - 1 do
            local s = SL.sso(pd + 40 * k)
            if s and s ~= "" then plans[#plans + 1] = s end
        end
        if #plans > 0 then
            emit(tag, "ai.allowed_strategy_plans.#1",
                table.concat(plans, " "))
        end
    end

    -- ===== §4.3.19 CStrategicAI force_concentration_target (容器/块键/元素字段 = 书) =====
    local fd, fc = rp(csa + 5624), ru32(csa + 5636)
    if kptr(fd) and fc and fc > 0 and fc < GAME.layout.lim.PTR_SANE then
        local fseq = SL.seqc()
        for k = 0, fc - 1 do
            local e = fd + 24 * k
            local fb = "ai." .. fseq("force_concentration_target") .. "."
            emit(tag, fb .. "target", tostring(ru32(e + 8) or 0))
            emit(tag, fb .. "from", tostring(ru32(e + 12) or 0))
            emit(tag, fb .. "progress", SL.num(fix5(e + 16)))
        end
    end

    -- ===== §4.3.19 CStrategicAI expeditionary_force_data (容器/块键/元素字段 = 书) =====
    do
        local ed, ec = rp(csa + 6160), ru32(csa + 6172)
        if kptr(ed) and ec and ec > 0 and ec < GAME.layout.lim.PTR_SANE then
            local eseq = SL.seqc()
            for k = 0, ec - 1 do
                local e = ed + 48 * k
                local eb = "ai." .. eseq("expeditionary_force_data") .. "."
                local t = tagof(ru32(e + 8))
                if t then emit(tag, eb .. "tag", '"' .. t .. '"') end
                emit(tag, eb .. "casualties", tostring(ru32(e + 12) or 0))
                emit(tag, eb .. "do_not_send_forces",
                    SL.yn(SL.ru8(e + 16) or 0))
                emit(tag, eb .. "pull_forces_back",
                    SL.yn(SL.ru8(e + 17) or 0))
                local dh = ru32(e + 32)
                if dh and dh ~= 43808760 then
                    local ds = SL.date(dh)
                    if ds then
                        emit(tag, eb .. "date", '"' .. ds .. '"') end
                end
            end
        end
    end

    -- ===== §4.3.19 CStrategicAI ai.raids (容器/块键/元素字段 = 书;
    -- target 内层 SRaidTarget 布局 = §4.27) =====
    do
        local rd, rc = rp(csa + 5592), ru32(csa + 5604)
        if kptr(rd) and rc and rc > 0 and rc < GAME.layout.lim.PTR_SANE then
            local rseq = SL.seqc()
            for k = 0, rc - 1 do
                local e = rd + 80 * k
                local rb = "ai." .. rseq("raids") .. "."
                local tnm = GAME.layout.token_name(ru32(e + 8) or 0)
                if tnm and tnm ~= "" then
                    emit(tag, rb .. "type", tnm) end
                local rt = e + 16
                local bld = rp(rt)
                if kptr(bld) then
                    local tpo = rp(bld + 0x1E0)
                    local tn2 = kptr(tpo) and GAME.layout.token_name(
                        ru32(tpo + 8) or 0) or nil
                    if tn2 and tn2 ~= "" then
                        emit(tag, rb .. "target.building.template", tn2)
                    end
                    local sto = rp(bld + 0x1D8)
                    if kptr(sto) then
                        emit(tag, rb .. "target.building.location",
                            tostring(ru32(sto + 108) or 0))
                    end
                end
                local pv = rp(rt + 8)
                if kptr(pv) then
                    emit(tag, rb .. "target.province",
                        tostring(ru32(pv + 164) or 0))
                end
                local st2 = rp(rt + 16)
                if kptr(st2) then
                    emit(tag, rb .. "target.state",
                        tostring(ru32(st2 + 88) or 0))
                end
                local lty, lid = ru32(rt + 24), ru32(rt + 28)
                if (lty or 0) ~= 0 or (lid or 0) ~= 0 then
                    emit(tag, rb .. "target.leader", SL.idpair(lid, lty))
                end
                local lp = rp(rt + 32)
                if kptr(lp) then
                    emit(tag, rb .. "target.leader_province",
                        tostring(ru32(lp + 164) or 0))
                end
                local ds = SL.date(ru32(e + 64))
                if ds then
                    emit(tag, rb .. "end_date", '"' .. ds .. '"') end
            end
        end
    end

    -- ===== §4.3.19 CStrategicAI failed_naval_invasions (容器/块键/元素字段 = 书) =====
    do
        local nd, nc = rp(csa + 5568), ru32(csa + 5580)
        if kptr(nd) and nc and nc > 0 and nc < GAME.layout.lim.PTR_SANE then
            local nseq = SL.seqc()
            for k = 0, nc - 1 do
                local e = nd + 64 * k
                local nb = "ai." .. nseq("failed_naval_invasions") .. "."
                local pp = rp(e + 8)
                if kptr(pp) then
                    emit(tag, nb .. "province",
                        tostring(ru32(pp + 164) or 0))
                end
                local od, oc = rp(e + 16), ru32(e + 28)
                if kptr(od) and oc and oc < GAME.layout.lim.PTR_SANE then
                    local tl = {}
                    for j = 0, (oc or 0) - 1 do
                        tl[#tl + 1] = tostring(ru32(od + 4 * j) or 0)
                    end
                    emit(tag, nb .. "invasion_order_ids.#1",
                        table.concat(tl, " "))
                end
                local ds = SL.date(ru32(e + 48))
                if ds then
                    emit(tag, nb .. "invasion_date", '"' .. ds .. '"') end
            end
        end
    end

    -- ===== §4.3.19 CStrategicAI recently_invaded_areas (count>0 才写; [N] 编号首现不编) =====
    local vd, vc = rp(csa + 5544), ru32(csa + 5556)
    if kptr(vd) and vc and vc > 0 and vc < GAME.layout.lim.PTR_SANE then
        local seq = SL.seqc()
        for k = 0, vc - 1 do
            local e = vd + 64 * k
            local blk = seq("recently_invaded_areas") -- "ai." 前缀由下行拼接
            local pp = rp(e + 8)
            emit(tag, "ai." .. blk .. ".province",
                tostring(kptr(pp) and (ru32(pp + 164) or 0) or 0))
            local od, oc = rp(e + 16), ru32(e + 28)
            if kptr(od) and oc and oc > 0 and oc < GAME.layout.lim.PTR_SANE then
                local tl = {}
                for j = 0, oc - 1 do
                    tl[#tl + 1] = tostring(ru32(od + 4 * j) or 0)
                end
                emit(tag, "ai." .. blk .. ".invasion_order_ids.#1",
                    table.concat(tl, " "))
            end
            local ds = SL.date(ru32(e + 48))
            if ds then
                emit(tag, "ai." .. blk .. ".invasion_date", '"' .. ds .. '"')
            end
        end
    end
end }
