-- sv2_sec_strategic_air.lua -- strategic_air 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Runtime:strategic_air_full,
-- objects_military §13.6); 本段只持写序/块键/[N] 编号/值格式化。

SV2.gsec[#SV2.gsec + 1] = { name = "strategic_air", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local ok, R = pcall(function() return O:strategic_air_full() end)
    if not ok or not R then return end
    local function E(path, val)
        if val ~= nil then emit("strategic_air", path, val) end
    end

    -- ===== §4.15.1 CNonstaticIdGenerator (SAIDX) =====
    E("air_theatre_index.id", SL.num(R.air_theatre_index_id))
    E("air_group_index.id", SL.num(R.air_group_index_id))

    -- ===== §4.15.8 CAirBase 族 (块键 = base@124 分支: 1=rocket_site,
    -- 2=gun_emplacement, 否则 air_base; 同列表同对象布局) =====
    local seq_ab, seq_rs, seq_ge = SL.seqc(), SL.seqc(), SL.seqc()
    for _, ba in ipairs(R.bases or {}) do
        local bk = (ba.base_flag == 2) and seq_ge("gun_emplacement")
            or (ba.base_flag == 1) and seq_rs("rocket_site")
            or seq_ab("air_base")
        local function B(path, val) E(bk .. "." .. path, val) end
        B("id", SL.idpair(ba.id_id, ba.id_type))
        if ba.state then
            B("state", SL.num(ba.state))
        else
            B("carrier", SL.idpair(ba.carrier_id, ba.carrier_type))
        end
        B("capacity", SL.num(ba.capacity))
        -- §4.15.9 CCountryAirContainer countries 指针元
        local seq_c = SL.seqc()
        for _, cp in ipairs(ba.countries or {}) do
            local ck = seq_c(bk .. ".countries")
            local function C(path, val) E(ck .. "." .. path, val) end
            C("id", SL.idpair(cp.id_id, cp.id_type))
            if cp.disrupted_supply then
                C("disrupted_supply", SL.num(cp.disrupted_supply)) end
            C("motorization_level", SL.num(cp.motorization))
            C("country", SL.Q(cp.tag))
            if cp.operational_status then
                C("operational_status", SL.num(cp.operational_status)) end
            if cp.capacity_penalty then
                C("capacity_penalty", SL.num(cp.capacity_penalty)) end
            if cp.fuel_consumption then
                C("fuel_consumption", SL.num(cp.fuel_consumption)) end
            if cp.received then C("received", SL.num(cp.received)) end
            if cp.base_fuel_consumption then
                C("base_fuel_consumption",
                    SL.num(cp.base_fuel_consumption)) end
        end
        B("base", SL.num(ba.base_flag))
        if (ba.has_manpower or 0) ~= 0 then
            B("has_manpower_for_recruit_change_to",
                SL.num(ba.has_manpower)) end
        B("level", SL.num(ba.level))
        B("allow_equipment_type", tostring(ba.allow_equipment_type or 0))
    end

    -- ===== §4.15.4 CAirWing 翼字段 (发射序 = writer 恒定) =====
    local function emit_wing(wk, w)
        local function Wf(path, val) E(wk .. "." .. path, val) end
        Wf("id", SL.idpair(w.id_id, w.id_type))
        Wf("count", SL.num(w.count))
        Wf("experience", SL.num(w.experience))
        Wf("reinforcement_setting", SL.num(w.reinforcement_setting))
        -- timed_disabling 恒写块 (ptr 失效落默认 0/no)
        local tdk = wk .. ".timed_disabling"
        if w.timed_disabling then
            E(tdk .. ".remaining_hours", SL.num(w.timed_disabling.remaining))
            E(tdk .. ".should_start_on_transfer",
                SL.yn(w.timed_disabling.sst))
        else
            E(tdk .. ".remaining_hours", "0")
            E(tdk .. ".should_start_on_transfer", "no")
        end
        -- transfer 族
        if w.transfer_pair and w.transferring_to then
            Wf("transferring_to", SL.num(w.transferring_to))
        end
        if w.transferring or (w.to_warehouse or 0) ~= 0 then
            if not w.transferring and (w.to_warehouse or 0) ~= 0 then
                Wf("transfer_to_warehouse", "yes") end
            Wf("transfer_progress", SL.num(w.transfer_progress))
            Wf("transfer_cancelled", SL.yn(w.transfer_cancelled))
        end
        -- deployment 族
        if w.deployment_pair then
            Wf("deployment", SL.num(w.deployment))
            Wf("deployment_time", SL.num(w.deployment_time))
        end
        Wf("manpower", SL.num(w.manpower))
        -- §4.15.5 CAirMission 块
        local m = w.mission
        local mk = wk .. ".mission"
        E(mk .. ".type", SL.num(m.type))
        E(mk .. ".period", SL.num(m.period))
        E(mk .. ".active", SL.yn(m.active))
        if m.executing then
            E(mk .. ".executing_mission", tostring(m.executing)) end
        if m.effectiveness then
            E(mk .. ".effectiveness", SL.num(m.effectiveness)) end
        if m.effective_planes_count then
            E(mk .. ".effective_planes_count",
                SL.num(m.effective_planes_count)) end
        if m.effective_air_superiority then
            E(mk .. ".effective_air_superiority",
                SL.num(m.effective_air_superiority)) end
        if m.strategic_region then
            E(mk .. ".strategic_region", SL.num(m.strategic_region))
            E(mk .. ".region_change_penalty",
                SL.num(m.region_change_penalty))
        end
        E(mk .. ".missions_done", SL.num(m.missions_done))
        if m.aggressiveness then
            E(mk .. ".aggressiveness", SL.num(m.aggressiveness)) end
        -- priority 串循环: 重复裸键标量叶 (提取器重复标量叶不编号)
        if m.priorities then
            for _, ps in ipairs(m.priorities) do
                E(mk .. ".priority", SL.Q(ps))
            end
        end
        if m.stop_training then
            E(mk .. ".stop_training_at_max_xp", "yes") end
        -- §4.15.4 other_combats (匿名列表逐项 .#N 1 起全编号)
        if w.other_combats then
            for i, oc in ipairs(w.other_combats) do
                E(wk .. ".other_combats.#" .. i,
                    SL.idpair(oc.id, oc.type))
            end
        end
        if w.air_accidents then
            Wf("air_accidents", SL.num(w.air_accidents)) end
        if w.ace_pair then
            Wf("ace", SL.idpair(w.ace_id, w.ace_type)) end
        if w.suspended_missions then
            Wf("suspended_missions", SL.num(w.suspended_missions)) end
        Wf("tag", SL.Q(w.tag))
        -- equipment 池 (skip 规则 reader 已施; allow_zero 叶恒写)
        if w.equipment then
            local seq_eq = SL.seqc()
            for _, eq in ipairs(w.equipment) do
                local ek = seq_eq(wk .. ".equipment.equipment")
                if eq.id then
                    E(ek .. ".id", SL.idpair(eq.id, eq.type)) end
                E(ek .. ".amount", SL.num(eq.amount))
            end
        end
        Wf("equipment.allow_zero_entries", SL.yn(w.equipment_az))
        -- name SSO **恒写 (空串照写 "")** — writer 门是 checksum-file 判定
        -- 非空判 (锚件 JAP.air_wing_pool 六例 "" 实证)
        Wf("name", '"' .. (w.name or "") .. '"')
        Wf("priority", SL.num(w.priority))
        Wf("allow_mission_type", SL.num(w.allow_mission_type))
        if w.region_to_assign then
            Wf("region_to_assign", SL.num(w.region_to_assign)) end
        if w.mission_to_assign then
            Wf("mission_to_assign", SL.num(w.mission_to_assign)) end
        if w.gix_tag then
            Wf("government_in_exile_tag", SL.Q(w.gix_tag)) end
        if w.air_untrained then
            Wf("air_untrained_pilots_penalty_factor",
                SL.num(w.air_untrained_factor)) end
        if w.air_group_pair then
            Wf("air_group", SL.idpair(w.air_group_id, w.air_group_type)) end
        if w.role_icon_index then
            Wf("role_icon_index", SL.num(w.role_icon_index)) end
        if w.raid_pair then
            Wf("raid_instance", SL.idpair(w.raid_id, w.raid_type)) end
        -- carrier_air_wing_kills: 键 = 类别位集经引擎表 → token (无名落
        -- 数值键, reader 兜底同 SL.tok)
        if w.carrier_kills then
            for _, ck in ipairs(w.carrier_kills) do
                Wf("carrier_air_wing_kills." .. ck.name, SL.num(ck.value))
            end
        end
    end

    -- ===== §4.15.7 SAirWingCombatData combat_history 单侧条目 =====
    local function emit_ch_side(ek, e)
        local function Cf(path, val) E(ek .. "." .. path, val) end
        Cf("id", SL.num(e.id))
        if e.equipment then
            local seq_eq = SL.seqc()
            for _, eq in ipairs(e.equipment) do
                local qk = seq_eq(ek .. ".equipment.equipment")
                if eq.id then
                    E(qk .. ".id", SL.idpair(eq.id, eq.type)) end
                E(qk .. ".amount", SL.num(eq.amount))
            end
        end
        Cf("equipment.allow_zero_entries", SL.yn(e.az))
        Cf("time", SL.num(e.time))
        -- 定案 (writer 0x141951050 token 序列直证): mission←+20, count←+16
        Cf("mission", SL.num(e.mission))
        Cf("count", SL.num(e.count))
        Cf("tag", SL.Q(e.tag))
        Cf("ground_attack", SL.yn(e.ground_attack))
        -- receiver 先于 sender (writer 序)
        for _, nm in ipairs({ "receiver", "sender" }) do
            local lst = e[nm]
            if lst then
                local seq = SL.seqc()
                for _, q in ipairs(lst) do
                    local qk = seq(ek .. "." .. nm)
                    E(qk .. ".type", SL.num(q.type))
                    E(qk .. ".value", SL.num(q.value))
                end
            end
        end
        Cf("destination", SL.yn(e.destination))
    end

    -- ===== §4.15.2 国条循环: air_wing_pool / naval_strike_remaining /
    -- combat_history / history 队列族 =====
    for _, sa in ipairs(R.countries or {}) do
        local tag = sa.tag
        local seq_pool = SL.seqc()
        for _, pool in ipairs(sa.pools) do
            local pk = seq_pool(tag .. ".air_wing_pool")
            local function P(path, val) E(pk .. "." .. path, val) end
            P("id", SL.idpair(pool.id_id, pool.id_type))
            if pool.definition_tok ~= nil then
                P("definition", tostring(SL.tok(pool.definition_tok))) end
            P("air_base", SL.idpair(pool.air_base_id, pool.air_base_type))
            local seq_w = SL.seqc()
            for _, w in ipairs(pool.wings) do
                emit_wing(seq_w(pk .. ".air_wings"), w)
            end
        end
        if sa.naval_strike then
            local vals = {}
            for _, v in ipairs(sa.naval_strike) do
                vals[#vals + 1] = tostring(v)
            end
            E(tag .. ".naval_strike_remaining.#1", table.concat(vals, " "))
        end
        for _, hk in ipairs(sa.combat_history) do
            local hk0 = tag .. ".combat_history." .. hk.idx
            E(hk0 .. ".tag", SL.Q(hk.tag))
            -- 侧序: enemy 先于 friend (writer 序)
            for _, nm in ipairs({ "enemy", "friend" }) do
                local lst = hk[nm]
                if #lst > 0 then
                    local seq_s = SL.seqc()
                    for _, e in ipairs(lst) do
                        emit_ch_side(seq_s(hk0 .. "." .. nm), e)
                    end
                end
            end
        end
        for _, hq in ipairs(sa.history_queues) do
            for qi = 1, 3 do
                local q = hq.queues[qi]
                if q then
                    local kp = string.format(
                        "%s.history.%d.history_queue.%d.",
                        tag, hq.idx, qi - 1)
                    E(kp .. "max_elements", SL.num(q.max_elements))
                    E(kp .. "offset", SL.num(q.offset))
                    E(kp .. "is_full", SL.yn(q.is_full))
                    if q.cells then
                        local toks = {}
                        for _, v in ipairs(q.cells) do
                            toks[#toks + 1] = SL.num(v)
                        end
                        E(kp .. "data.#1", table.concat(toks, " "))
                    end
                end
            end
        end
    end
end }
