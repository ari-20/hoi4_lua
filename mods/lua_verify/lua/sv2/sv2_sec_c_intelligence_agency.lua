-- sv2_sec_c_intelligence_agency.lua -- country.intelligence_agency 节点
-- (发射规则段; 布局/走查/写门唯一实现 = Country.intelligence_agency
--  + Runtime.op_leader 元素转换, objects_characters §4.11.11/§4.11.14;
--  ag = rp(cc+4032))

local OP_STATE = { [0] = "on_capture", [1] = "on_cooldown",
    [2] = "on_disband", [3] = "on_mission", [4] = "on_operation",
    [5] = "killed" }
local MISSION_NAMES = { [1] = "build_intel_network", [2] = "quiet_network",
    [3] = "counter_intelligence", [4] = "root_out_resistance",
    [5] = "boost_ideology", [6] = "control_trade",
    [7] = "diplomatic_pressure", [8] = "propaganda" }

SV2.csec[#SV2.csec + 1] = { name = "country.intelligence_agency",
    emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local R = c.R
    local function tagof(tid)           -- tid → 三字 tag (nil 安全)
        if tid and tid > 0 and R then return R:tag(tid) end
        return nil
    end
    -- §4.11.11 COperativeLeader 元素全字段直发 (基链 §4.4.2 CUnitLeader;
    -- base = 叶路径前缀; 值全部出自 Runtime.op_leader reader)
    local function op_emit(base, o)
        emit(tag, base .. ".id", SL.idpair(o.id, o.type))
        local q = SL.Q(o.name)
        if q then emit(tag, base .. ".name", q) end
        -- 字符串块六门 (writer 0x140C1CE70 头段序: name → desc →
        -- custom_cost_text → gfx → picture → portrait_path;
        -- 1.19.3 起 e+192 portrait_path 实装)
        q = SL.Q(o.desc)
        if q then emit(tag, base .. ".desc", q) end
        q = SL.Q(o.custom_cost_text)
        if q then emit(tag, base .. ".custom_cost_text", q) end
        q = SL.Q(o.gfx)
        if q then emit(tag, base .. ".gfx", q) end
        q = SL.Q(o.picture)
        if q then emit(tag, base .. ".picture", q) end
        q = SL.Q(o.portrait_path)
        if q then emit(tag, base .. ".portrait_path", q) end
        if o.female_gate then
            emit(tag, base .. ".female", SL.yn(o.female or 0)) end
        emit(tag, base .. ".skill", SL.num(o.skill or 0))
        local xp = o.experience
        if xp and xp ~= 0 then
            emit(tag, base .. ".experience", SL.num(xp)) end
        local sid = o.script_id or 0
        if sid ~= 0 then
            emit(tag, base .. ".script_id", SL.num(sid)) end
        -- traits (空格 joined 裸 token 名, 仅 count>0)
        if o.traits and o.traits ~= "" then
            emit(tag, base .. ".traits", o.traits) end
        -- in_progress (16B {tok*, i64×1e-5}; 全条目含 0)
        for _, pp in ipairs(o.in_progress_pairs or {}) do
            emit(tag, base .. ".in_progress." .. tostring(pp.tok),
                SL.num(pp.val))
        end
        local lid = o.legacy_u32 or 0xFFFFFFFF
        if lid ~= 0xFFFFFFFF then
            emit(tag, base .. ".legacy_id", SL.num(lid)) end
        -- nationalities → 单行 #1 空格 joined 裸 tag (定案: writer 写
        -- `nationalities={ ITA ETH SYR }` 内联块 → 提取器整行归一;
        -- 逐 tid 分行是错的)
        if o.nationalities and o.nationalities ~= "" then
            emit(tag, base .. ".nationalities.#1", o.nationalities) end
        -- captured + capture_date
        local capt = o.captured_tag or 0
        if capt > 0 then
            local ct = tagof(capt)
            if ct then
                emit(tag, base .. ".captured", SL.Q(ct))
                local cd = SL.date(o.capture_date_hours or 0)
                if cd then
                    emit(tag, base .. ".capture_date", SL.Q(cd)) end
            end
        end
        -- operation id 对 (§4.11.11 +3968; ext writer 0x140C18FF0
        -- 任一非零 → 块 0x2F1B)
        local opty, opid = o.operation_type or 0, o.operation_id or 0
        if opty ~= 0 or opid ~= 0 then
            emit(tag, base .. ".operation", SL.idpair(opid, opty))
        end
        -- cooldown 三件套 (§4.4.2 基类同构; 总门/枚举串/日期对 =
        -- 书 §4.4.2 + §4.4.4)
        local cdr = o.cooldown_reason_code or 0
        if cdr ~= 0 then
            local CDR = { [0] = "no_cooldown", "reassigned", "harmed",
                "forced_into_hiding", "deployed", "withdrawing" }
            local rn = CDR[cdr]
            if rn then
                emit(tag, base .. ".cooldown_reason", '"' .. rn .. '"')
            end
            local d1 = SL.date(o.cooldown_enable_hours or 0)
            if d1 then
                emit(tag, base .. ".leader_modifier_enable_date",
                    '"' .. d1 .. '"')
            end
            local d2 = SL.date(o.cooldown_start_hours or 0)
            if d2 then
                emit(tag, base .. ".leader_cooldown_start_date",
                    '"' .. d2 .. '"')
            end
        end
        -- codename (type 恒写 / name_order ≠0 / is_name_ordered 仅 "no")
        emit(tag, base .. ".codename.type", SL.num(o.codename_type or 0))
        local cno = o.codename_name_order or 0
        if cno ~= 0 then
            emit(tag, base .. ".codename.name_order", SL.num(cno)) end
        if o.codename_is_name_ordered_zero then
            emit(tag, base .. ".codename.is_name_ordered", "no") end
        -- mission (仅 type ≠0; state 仅 build_intel_network(1) /
        -- root_out_resistance(4) 写 — 锚件全档实证 (26+2 例),
        -- counter_intelligence(3) 恒无 (7 例仅 target) — 该型
        -- mdata+24 的布局不同, 按通用 +88 读会取到定点值 (RUS 误发
        -- state=150000); ⚠ 类型 5-8 本档无实例, 口径未决 (沿用 1/4 白名单))
        local mtype = o.mission_type_code or 0
        if mtype ~= 0 then
            local mn = MISSION_NAMES[mtype] or tostring(mtype)
            local mb = base .. ".mission." .. mn
            local mt = tagof(o.mission_target_tid or 0)
            if mt then emit(tag, mb .. ".target", SL.Q(mt)) end
            if mtype == 1 or mtype == 4 then
                local msv = o.mission_state_raw or 0
                if msv ~= 0 then
                    emit(tag, mb .. ".state", SL.num(msv))
                end
            end
        end
        -- state 恒写 (枚举反表; 未知码跳过)
        local st = OP_STATE[o.state or 0]
        if st then
            emit(tag, base .. ".state", "state=" .. st .. " }") end
    end

    local ok, r = pcall(function() return c:intelligence_agency() end)
    if not ok or not r then return end
    local ag = r.addr
    if not ag then return end

    -- 头标量族 (§4.11.14; writer 0x140FCA0F0 序)
    emit(tag, "intelligence_agency.name", SL.Q(r.name) or '""')
    emit(tag, "intelligence_agency.icon", '"' .. (r.icon or "") .. '"')
    if r.is_created then
        emit(tag, "intelligence_agency.is_created", "yes") end
    if r.in_creation then
        emit(tag, "intelligence_agency.in_creation", "yes") end
    if r.upgrade_progress and r.upgrade_progress ~= 0 then
        emit(tag, "intelligence_agency.upgrade_progress",
            SL.num(r.upgrade_progress)) end
    -- captured.#N (§4.11.16 CCapturedOperativeReference 56B 元)
    for ci2, cv in ipairs(r.captured and r.captured.list or {}) do
        local b = "intelligence_agency.captured.#" .. ci2
        local ct = tagof(cv.country_idx or 0)
        if ct then emit(tag, b .. ".country", SL.Q(ct)) end
        emit(tag, b .. ".operative", SL.idpair(cv.op_id, cv.op_type))
        emit(tag, b .. ".intel.civilian", SL.num(cv.intel_civilian))
        emit(tag, b .. ".intel.army", SL.num(cv.intel_army))
        emit(tag, b .. ".intel.navy", SL.num(cv.intel_navy))
        emit(tag, b .. ".intel.airforce", SL.num(cv.intel_airforce))
    end
    -- operative[N] (§4.11.14 operative 池 {d@ag+216, c@ag+228})
    do
        local seqo = SL.seqc()
        for _, o in ipairs(r.training_operatives and
                r.training_operatives.list or {}) do
            op_emit("intelligence_agency." .. seqo("operative"), o)
        end
    end
    -- upgrades.<name> (仅 count>0)
    for _, uv in ipairs(r.upgrades and r.upgrades.list or {}) do
        emit(tag, "intelligence_agency.upgrades."
            .. tostring(uv.name), SL.num(uv.level or 0))
    end
    -- upgrade 裸键 (writer 0x140FCA0F0 L69: def*@ag+208 指针门)
    if r.upgrade then
        emit(tag, "intelligence_agency.upgrade", r.upgrade)
    end
    -- own_operative_death (writer L45: u32@ag+252 ≠0 才写, 0x4B60)
    local ood = r.own_operative_death or 0
    if ood ~= 0 then
        emit(tag, "intelligence_agency.own_operative_death",
            SL.num(ood))
    end
    -- cryptology.targets (§4.11.9 CCryptology/CCountryDecryptionState;
    -- crypto = *(ag+288))
    for ti, tv in ipairs(r.cryptology and r.cryptology.targets or {}) do
        local b6 = "intelligence_agency.cryptology.targets.#" .. ti .. "."
        local t6 = tagof(tv.tag_tid or 0)
        if t6 then
            emit(tag, b6 .. "target", SL.Q(t6)) end
        local dy = tv.days_raw or 0xFFFFFFFF
        if dy ~= 0xFFFFFFFF then
            emit(tag, b6 .. "days", SL.num(dy)) end
        if tv.active then emit(tag, b6 .. "active", "yes") end
        if tv.hide then emit(tag, b6 .. "hide", "yes") end
        if tv.decryption then emit(tag, b6 .. "decryption", "yes") end
        local am = tv.amount
        if am and am ~= 0 then
            emit(tag, b6 .. "amount", SL.num(am)) end
        local dh = tv.date_hours or 0
        if dh and dh ~= 43808760 then
            local ds = SL.date(dh)
            if ds then
                emit(tag, b6 .. "date", '"' .. ds .. '"') end
        end
    end
    -- cryptology.intel_source.* 归 sv2_sec_c_intel.lua 管辖
    -- §4.11.14 recruitment 三容器 (generated/recruitable/
    -- recruitable_not_to_spy_master; [N] 编号 = reader list 序)
    local function rec_list(pool, base)
        for n5, o in ipairs(pool and pool.list or {}) do
            op_emit(base .. ".#" .. n5, o)
        end
    end
    rec_list(r.generated_operatives,
        "intelligence_agency.recruitment.generated_operatives")
    rec_list(r.recruitable,
        "intelligence_agency.recruitment.recruitable_operatives")
    rec_list(r.recruitable_not_to_spy_master,
        "intelligence_agency.recruitment.recruitable_operatives"
        .. "_not_to_spy_master")
    -- 尾标量五件 (§4.11.14; 恒写含 0)
    emit(tag, "intelligence_agency.defense", SL.num(r.defense or 0))
    emit(tag, "intelligence_agency.max_operative_count",
        SL.num(r.max_operative_count or 0))
    emit(tag, "intelligence_agency.usable_operative_slots",
        SL.num(r.usable_operative_slots or 0))
    emit(tag, "intelligence_agency.elapsed_days_for_next_slot",
        SL.num(r.elapsed_days_for_next_slot or 0))
    emit(tag, "intelligence_agency.building", SL.num(r.building or 0))
end }
