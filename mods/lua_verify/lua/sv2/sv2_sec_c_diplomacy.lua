-- sv2_sec_c_diplomacy.lua -- country.diplomacy 节点 savefull 直出 (csec)
-- 结构/走查唯一实现 = reader: Country.diplomacy/autonomy/proposed_diplo/
-- misc_status_snapshot (objects_politics §4.10 已有) + Country:diplo_export
-- (act 载荷五族/rs 槽 28 规则/wargoal 容器, 本文件尾追加的 §4.10 补充)。
-- 本段只持写序/块键/编号/值格式化。
-- ⚠ 关系型块通用: dim=first, R=second, mem 挂载侧不定 → 段内跨国去重,
--   恒以 dim=first_tag 发 (rel_seen); war/puppet/nap.end_date 深层由
--   country.diplomacy.warrel 段覆盖。

local rp, ru32 = hoi4.read_u64, hoi4.read_u32

local REL_TYPES = {
    market_access_rights = true, embargo = true, guarantee = true,
    non_aggression_pact = true, puppet = true, war = true,
    war_relation = true,
    military_access = true, lend_lease = true,
    equipment_purchase_contract_relation = true, air_base_access = true,
    offer_air_base_access = true,
    docking_rights = true, improve_relation = true, naval_blockade = true,
    send_attache = true,  -- JAP→FNG 首例 (first/second/start_date)
}

local rel_seen, rel_last_i = {}, nil

SV2.csec[#SV2.csec + 1] = { name = "country.diplomacy", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ci = ctx.i or 0
    if rel_last_i == nil or ci < rel_last_i then rel_seen = {} end
    rel_last_i = ci

    local okd, rdip = pcall(function() return c:diplomacy() end)
    if not okd then rdip = nil end
    local okx, dex = pcall(function() return c:diplo_export() end)
    if not okx then dex = nil end

    -- ============ §4.10.1 CDiplomacyStatus 标量族 ============
    if rdip then
        emit(tag, "diplomacy.exile_army_leaders",
             SL.num(rdip.exile_army_leaders or 0))
        for k, t in ipairs(rdip.cached_allies or {}) do
            local q = SL.Q(t)
            if q then
                emit(tag, "diplomacy.cached_allies_and_gurantees.#" .. k, q)
            end
        end
        local fjd = SL.date(rdip.faction_join_hours)
        if fjd then emit(tag, "diplomacy.faction_join_date", SL.Q(fjd)) end
        for ti, tl in ipairs(rdip.taken_lead or {}) do
            local b = "diplomacy.taken_lead_to_wars.#" .. ti
            local q = SL.Q(tl.tag)
            if q then emit(tag, b .. ".tag", q) end
            emit(tag, b .. ".reason", SL.num(tl.reason))
            emit(tag, b .. ".days", SL.num(tl.days))
        end
        for ii, rr in ipairs((rdip.incoming_diplomatic or {}).list or {}) do
            local b = "incoming_diplomatic_action." .. (ii - 1)
            emit(tag, b .. ".id", SL.idpair(rr.id, rr.idtype))
            local ab = b .. "." .. tostring(rr.tok)
            emit(tag, ab .. ".type", SL.num(rr.typ))
            local q
            q = SL.Q(rr.act);  if q then emit(tag, ab .. ".actor", q) end
            q = SL.Q(rr.oact); if q then emit(tag, ab .. ".original_actor", q) end
            q = SL.Q(rr.rec);  if q then emit(tag, ab .. ".recipient", q) end
            q = SL.Q(rr.orec); if q then emit(tag, ab .. ".original_recipient", q) end
            q = SL.date(rr.date_h)
            if q then emit(tag, ab .. ".date", SL.Q(q)) end
            emit(tag, ab .. ".value", SL.yn(rr.val))
            q = SL.date(rr.lcd_h)
            if q then emit(tag, ab .. ".last_command_date", SL.Q(q)) end
            emit(tag, ab .. ".envoy", SL.num(rr.envoy))
            emit(tag, ab .. ".initiator_matters", SL.yn(rr.im))
            if rr.oa then
                emit(tag, ab .. ".on_action", tostring(rr.oa)) end
            if (rr.hum or 0) ~= 0 then
                emit(tag, ab .. ".human", "yes") end
            -- 五族载荷 = reader dex.incoming_acts[ii] (按 act+8 token 预读)
            local a = dex and dex.incoming_acts and dex.incoming_acts[ii]
            if a then
                if a.market_flag ~= nil then
                    emit(tag, ab .. ".show_show_result_message_to_actor",
                        SL.yn(a.market_flag)) end
                if a.tok_id == 13333 then -- §4.10.14 send_volunteers
                    for _, dv in ipairs(a.divisions or {}) do
                        emit(tag, ab .. ".division",
                            SL.idpair(dv.id, dv.type)) end
                    emit(tag, ab .. ".given_air_volunteer_permission",
                        SL.yn(a.air_perm)) end
                if a.tok_id == 13663 or a.tok_id == 12233 then -- versus
                    if a.versus then
                        for vi = 1, #a.versus do
                            local vq = a.versus[vi]
                            if vq then
                                emit(tag, ab .. ".versus.#" .. vi, SL.Q(vq)) end
                        end
                    end end
                if a.tok_id == 12618 and a.ll then -- §4.10.23 lend_lease
                    for _, pd in ipairs({ { "equipment", "equipment" },
                        { "production_percentage", "production_percentage" },
                        { "once", "once" } }) do
                        local pool = a.ll[pd[1]]
                        if pool then
                            local pseq = SL.seqc()
                            for _, eq in ipairs(pool.list or {}) do
                                local ek2 = ab .. "." .. pd[2] .. "."
                                    .. pseq("equipment") .. "."
                                emit(tag, ek2 .. "id",
                                    SL.idpair(eq.id, eq.type))
                                emit(tag, ek2 .. "amount",
                                    SL.num(eq.amount)) end
                            emit(tag, ab .. "." .. pd[2]
                                .. ".allow_zero_entries", SL.yn(pool.az)) end
                    end
                    if a.ll.fuel_bits then
                        local okd2, fdv = pcall(string.unpack, "<d",
                            string.pack("<I8", a.ll.fuel_bits))
                        if not okd2 then fdv = a.ll.fuel_bits / 100000 end
                        emit(tag, ab .. ".fuel_daily",
                            string.format("%.5f", fdv)) end
                    emit(tag, ab .. ".fuel_percentage",
                        SL.num(a.ll.fuel_pct / 100000)) end
                if a.request then -- §4.10.25 (def_emit = 共享发射件)
                    local DP = ab .. ".contract_definition."
                    SL.def_emit(ctx.O, emit, tag, DP, a.addr + 120)
                    emit(tag, ab .. ".request",
                        SL.idpair(a.request.id, a.request.type)) end
            end
        end
    end

    -- ============ §4.10.2 active_relations 逐对方国 ============
    for _, rec in ipairs((rdip and rdip.relations) or {}) do
        local R = rec.tag
        if R and R ~= "" and R ~= "---" then
            local base = "diplomacy.active_relations." .. R
            local rse = dex and dex.rs_map and dex.rs_map[rec.idx or -1]
            if rse then
                if rse.leased_ic then
                    emit(tag, base .. ".recently_leased_ic",
                        SL.num(rse.leased_ic)) end
                if rse.llh then
                    local lb = base .. ".lend_lease_to_allies_history"
                    emit(tag, lb .. ".ic_given", SL.num(rse.llh[1]))
                    emit(tag, lb .. ".fuel_given", SL.num(rse.llh[2]))
                    emit(tag, lb .. ".ic_received", SL.num(rse.llh[3]))
                    emit(tag, lb .. ".fuel_received", SL.num(rse.llh[4])) end
            end
            if rec.cached_sum and rec.cached_sum ~= 0 then
                emit(tag, base .. ".cached_sum", SL.num(rec.cached_sum)) end
            if rec.attitude and rec.attitude ~= "" and rec.attitude ~= "noattitude" then
                emit(tag, base .. ".attitude", SL.Q(rec.attitude)) end
            if rec.border_friction and rec.border_friction ~= 0 then
                emit(tag, base .. ".border_friction_claim",
                     SL.num(rec.border_friction)) end
            local d = rec.last_send_diplomat
            if d then emit(tag, base .. ".last_send_diplomat", SL.Q(d)) end
            d = rec.trade
            if d then emit(tag, base .. ".trade", SL.Q(d)) end
            d = rec.trade_equipment
            if d then emit(tag, base .. ".trade_equipment", SL.Q(d)) end
            d = rec.truce_until
            if d then emit(tag, base .. ".truce_until", SL.Q(d)) end
            for _, mn in ipairs(rec.modifiers or {}) do
                local q = SL.Q(mn)
                if q then emit(tag, base .. ".modifier", q) end
            end
            for oi, om in ipairs(rec.opinion_modifiers or {}) do
                local ob = base .. ".opinion" ..
                    (oi > 1 and ("[" .. oi .. "]") or "")
                if om.name then
                    emit(tag, ob .. ".modifier", tostring(om.name)) end
                if om.date then
                    emit(tag, ob .. ".date", SL.Q(om.date)) end
                emit(tag, ob .. ".value", SL.num(om.value or 0))
                if om.decay then emit(tag, ob .. ".decay", "yes") end
                if om.dnx then
                    emit(tag, ob .. ".do_not_expire", "yes") end
            end
            -- §4.10.2 rule_overrides 28 槽 (reader rse.rules)
            if rse then
                local rob = base .. ".rule_overrides.override"
                for _, e in ipairs(rse.rules or {}) do
                    local key = e.key and tostring(e.key) or nil
                    if e.flag ~= 0 then
                        if key then
                            emit(tag, rob .. "." .. key,
                                SL.yn(e.flag == 1)) end
                        emit(tag, rob .. ".desc",
                            '"' .. tostring(e.desc or "") .. '"')
                    end
                    for _, v2 in ipairs(e.vecs or {}) do
                        if key then
                            emit(tag, rob .. "." .. key,
                                SL.yn(v2.value == 1)) end
                        emit(tag, rob .. ".desc",
                            '"' .. tostring(v2.desc or "") .. '"')
                        if v2.trigger then
                            local tq = SL.Q(v2.trigger)
                            if tq then emit(tag, rob .. ".trigger", tq) end
                        end
                    end
                end
            end
            -- §4.10.3 关系对象基类 (跨国家去重)
            for _, rel in ipairs(rec.relations or {}) do
                local tn = rel.token and SL.tok(rel.token) or nil
                tn = tn and tostring(tn) or nil
                local f, s = rel.first_tag, rel.second_tag
                if tn and REL_TYPES[tn] and f and s
                    and f ~= "" and s ~= "" then
                    local dk = tn .. "|" .. f .. "|" .. s
                    if not rel_seen[dk] then
                        rel_seen[dk] = true
                        local st = (tn == "war") and "war_relation" or tn
                        local rb = "diplomacy.active_relations." .. s
                            .. "." .. st
                        emit(f, rb .. ".first", SL.Q(f))
                        emit(f, rb .. ".second", SL.Q(s))
                        if rel.start_date then
                            emit(f, rb .. ".start_date",
                                 SL.Q(rel.start_date))
                        end
                    end
                end
            end
        end
    end

    -- ============ §4.10.9 autonomy (reader c:autonomy) ============
    local oka, au = pcall(function() return c:autonomy() end)
    if oka and au then
        local prg = au.progress or 0
        prg = GAME.layout.as_i32(prg)
        emit(tag, "diplomacy.autonomy_state.progress", SL.num(prg * 1e-5))
        local lm = SL.date(au.lm_hours) or "1.1.1.1"
        emit(tag, "diplomacy.autonomy_state.last_modified_autonomy_date",
             '"' .. lm .. '"')
        if au.current_state and au.current_state ~= "" then
            emit(tag, "diplomacy.autonomy_state.current_state",
                 SL.Q(au.current_state)) end
        if au.prev_state and au.prev_state ~= "" then
            emit(tag, "diplomacy.autonomy_state.prev_state",
                 SL.Q(au.prev_state)) end
        if au.next_state and au.next_state ~= "" then
            emit(tag, "diplomacy.autonomy_state.next_state",
                 SL.Q(au.next_state)) end
        for _, pn in ipairs(au.path or {}) do
            local q = SL.Q(pn)
            if q then emit(tag, "diplomacy.autonomy_state.path", q) end
        end
        for ei, ee in ipairs(au.effects or {}) do
            local eb = "diplomacy.autonomy_state.effect" ..
                (ei > 1 and ("[" .. ei .. "]") or "")
            emit(tag, eb .. ".value", SL.num((ee.value or 0) * 1e-5))
            local q = SL.Q(ee.desc)
            if q then emit(tag, eb .. ".desc", q) end
            local ed = SL.date(ee.hours)
            if ed then emit(tag, eb .. ".date", SL.Q(ed)) end
        end
    end

    -- ============ §4.10.8 proposed (reader c:proposed_diplo) ============
    local okp, dp = pcall(function() return c:proposed_diplo() end)
    if okp and dp then
        for di, de in ipairs(dp.list or {}) do
            local pb = "diplomacy.proposed_diplo_action" ..
                (di > 1 and ("[" .. di .. "]") or "")
            if de.action then
                emit(tag, pb .. ".action", tostring(de.action)) end
            emit(tag, pb .. ".index", SL.num(de.index))
            local q = SL.date(de.hours)
            if q then emit(tag, pb .. ".date", SL.Q(q)) end
        end
    end

    -- ============ §4.10.1 wargoals 容器族 (reader dex.wargoals) ============
    local wg = dex and dex.wargoals
    if wg then
        if wg.naval_blockade then emit(tag, "diplomacy.naval_blockade", "yes") end
        for k, cp in ipairs(wg.captured or {}) do
            emit(tag, "diplomacy.captured.#" .. k,
                SL.idpair(cp.id, cp.type)) end
        for _, aw in ipairs(wg.available or {}) do
            emit(tag, "diplomacy.available_wargoals.wargoal",
                SL.idpair(aw.id, aw.type)) end
        local wseq = SL.seqc()
        for _, w in ipairs(wg.list or {}) do
            local wt = tostring(w.type)
            local wb = "diplomacy.wargoals." .. wseq(wt)
            emit(tag, wb .. ".id", SL.idpair(w.id_id, w.id_type))
            if w.actor then
                local qa = SL.Q(w.actor)
                if qa then emit(tag, wb .. ".wargoaldata_actor", qa) end end
            if w.recipient then
                local qr = SL.Q(w.recipient)
                if qr then
                    emit(tag, wb .. ".wargoaldata_recipient", qr) end end
            emit(tag, wb .. ".type", wt)
            if w.puppets then
                emit(tag, wb .. ".puppets", table.concat(w.puppets, " ")) end
            if w.states then
                local ids = {}
                for _, sid in ipairs(w.states) do
                    ids[#ids + 1] = tostring(sid) end
                emit(tag, wb .. ".states", table.concat(ids, " ")) end
            if w.expire_h then
                local xd = SL.date(w.expire_h)
                if xd then emit(tag, wb .. ".expire", SL.Q(xd)) end end
        end
    end

    -- §4.10.18 投降/流亡/志愿航空队族 (reader misc_status_snapshot)
    local okm, snap = pcall(function() return c:misc_status_snapshot() end)
    if okm and snap then
        if snap.dirty then
            emit(tag, "dirty_controlled_states", "yes") end
        if snap.removed_prov then
            emit(tag, "removed_controlled_province", "yes") end
        local rvseq = 0
        for _, pair in ipairs(snap.recv_vol or {}) do
            local t, cnt = tostring(pair):match("^(.-)=(%d+)$")
            if t then
                rvseq = rvseq + 1
                local rvp = "received_air_volunteer_permission"
                    .. (rvseq > 1 and ("[" .. rvseq .. "]") or "")
                emit(tag, rvp .. ".tag", SL.Q(t))
                emit(tag, rvp .. ".count", SL.num(tonumber(cnt))) end
        end
        for _, t in ipairs(snap.given_vol or {}) do
            local q = SL.Q(t)
            if q then emit(tag, "given_air_volunteer_permission", q) end
        end
        if snap.capitulated then
            emit(tag, "diplomacy.capitulated", "yes")
            local cd = SL.date(snap.cap_date_h)
            if cd then
                emit(tag, "diplomacy.capitulated_date", SL.Q(cd)) end end
        local sd = SL.date(snap.last_surr_h)
        if sd then
            emit(tag, "diplomacy.last_surrender_date", SL.Q(sd)) end
        if snap.hosting then
            emit(tag, "diplomacy.hosting_our_government_in_exile",
                 SL.Q(snap.hosting)) end
        if snap.legitimacy then
            emit(tag, "diplomacy.legitimacy", SL.num(snap.legitimacy)) end
        do
            local whl = {}
            for _, t in ipairs(snap.we_host or {}) do
                local q = SL.Q(t)
                if q then whl[#whl + 1] = q end
            end
            if #whl > 0 then
                emit(tag, "diplomacy.governments_in_exile_we_host.#1",
                    table.concat(whl, " ")) end
        end
    end
end }
-- sv2_sec_c_diplomacy.warrel -- war_relation 深层 B 族 (csec)
-- 结构/走查唯一实现 = Country:diplo_export (objects_politics §4.10 补充);
-- 本段只持跨国家去重/写序/块键/枚举映射/值格式化。
-- ⚠ war_score 视角由引擎在子对象内换好 (§4.10.5); hostility_reason
--   instigator@+352 / defender@+348 方向勿反 (§4.10.6)。

local SL = SV2.lib

-- §4.10.6 hostility_reason 枚举 (writer switch 实证): 表外 = 不写
local WARREL_REASON = { [0] = "war", "puppet", "ally", "asked_to_join",
    "guarantee", "not_applicable" }

-- save 侧写的关系型 (与主段同表)
local REL_TYPES = {
    market_access_rights = true, embargo = true, guarantee = true,
    non_aggression_pact = true, puppet = true, war = true,
    war_relation = true,
    military_access = true, lend_lease = true,
    equipment_purchase_contract_relation = true, air_base_access = true,
    offer_air_base_access = true,
    docking_rights = true, improve_relation = true, naval_blockade = true,
    send_attache = true,
}

local warrel_seen, warrel_last_i = {}, nil

SV2.csec[#SV2.csec + 1] = { name = "country.diplomacy.warrel",
    emit = function(ctx)
    local SL, emit, c = SV2.lib, ctx.emit, ctx.country
    if not c then return end
    local ci = ctx.i or 0
    if warrel_last_i == nil or ci < warrel_last_i then warrel_seen = {} end
    warrel_last_i = ci
    local okx, dex = pcall(function() return c:diplo_export() end)
    if not okx or not dex then return end
    local function tagof(s)   -- tag 串 (""/"---" 不发; war_score/13085 用)
        return (s and s ~= "" and s ~= "---") and SL.Q(s) or nil end
    for _, w in ipairs(dex.warrels or {}) do
        local tn = w.token and SL.tok(w.token) or nil
        tn = tn and tostring(tn) or nil
        local f, s = w.first, w.second
        if tn and REL_TYPES[tn] and f and s and f ~= "" and s ~= "" then
            local dk = tn .. "|" .. f .. "|" .. s
            if not warrel_seen[dk] then
                warrel_seen[dk] = true
                local rb = "diplomacy.active_relations." .. s .. "." .. tn
                -- 基类通用 (全 11 型): cancel / end_date
                if w.cancel then emit(f, rb .. ".cancel", "yes") end
                if w.end_eh and w.end_sh and w.end_eh > w.end_sh then
                    local d = SL.date(w.end_eh)
                    if d then emit(f, rb .. ".end_date", SL.Q(d)) end
                end
                if tn == "war_relation" and w.war then
                    local wr = w.war
                    -- casualties 四连 i64 原值, 恒写
                    emit(f, rb .. ".first_casualties",
                        SL.num(wr.cas[1]))
                    emit(f, rb .. ".second_casualties", SL.num(wr.cas[2]))
                    emit(f, rb .. ".first_unknown_casualties",
                        SL.num(wr.cas[3]))
                    emit(f, rb .. ".second_unknown_casualties",
                        SL.num(wr.cas[4]))
                    -- war_score 两视角内嵌子对象 (112B)
                    for vi = 1, 2 do
                        local ws = wr.ws and wr.ws[vi]
                        if ws then
                            local wb = rb .. "." .. (vi == 1
                                and "war_score_first_vs_second"
                                or "war_score_second_vs_first")
                            local q = tagof(ws.first)
                            if q then emit(f, wb .. ".first", q) end
                            q = tagof(ws.second)
                            if q then emit(f, wb .. ".second", q) end
                            for _, fld in ipairs(ws.fields or {}) do
                                emit(f, wb .. "." .. fld.name,
                                    SL.num(fld.value or 0)) end
                            if #ws.captured > 0 then
                                local keys = {}
                                for _, k2 in ipairs(ws.captured) do
                                    keys[#keys + 1] = tostring(k2) end
                                emit(f, wb .. ".captured_provinces.#1",
                                    table.concat(keys, " ")) end
                        end
                    end
                    emit(f, rb .. ".threat", SL.num(wr.threat or 0))
                    emit(f, rb .. ".first_was_instigator",
                        SL.yn(wr.instig))
                    -- first/second_wargoals 8B 紧致对
                    local wgn = { "first_wargoals", "second_wargoals" }
                    for gi, gname in ipairs(wgn) do
                        local lst = wr.fw and wr.fw[gi]
                        for _, wg2 in ipairs(lst or {}) do
                            emit(f, rb .. "." .. gname .. ".wargoal",
                                SL.idpair(wg2.id, wg2.type)) end
                    end
                    -- wargoals (token 13085): CWargoal* 动态块
                    local wseq = SL.seqc()
                    for _, w2 in ipairs(wr.wargoals or {}) do
                        local wt = tostring(w2.type)
                        local gb = rb .. ".wargoals." .. wseq(wt)
                        emit(f, gb .. ".id",
                            SL.idpair(w2.id_id, w2.id_type))
                        local q2 = tagof(w2.actor)
                        if q2 then
                            emit(f, gb .. ".wargoaldata_actor", q2) end
                        q2 = tagof(w2.recipient)
                        if q2 then
                            emit(f, gb .. ".wargoaldata_recipient", q2) end
                        emit(f, gb .. ".type", wt) end
                    -- hostility_reason (方向勿反)
                    if wr.h_i and WARREL_REASON[wr.h_i] then
                        emit(f, rb .. ".hostility_reason_instigator",
                            WARREL_REASON[wr.h_i]) end
                    if wr.h_d and WARREL_REASON[wr.h_d] then
                        emit(f, rb .. ".hostility_reason_defender",
                            WARREL_REASON[wr.h_d]) end
                elseif tn == "puppet" then
                    if w.autonomy_state then
                        local q = SL.Q(w.autonomy_state)
                        if q then emit(f, rb .. ".autonomy_state", q) end end
                    if w.puppet_value then
                        emit(f, rb .. ".value", SL.num(w.puppet_value)) end
                end
            end
        end
    end
end }
