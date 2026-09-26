-- sv2_sec_c_characters.lua -- country.characters 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Country.country_characters
--  objects_global §33 + Runtime.op_leader 元素转换 (§4.11.11))

SV2.csec[#SV2.csec + 1] = { name = "country.characters", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local r = c:country_characters()
    if not r then return end

    -- §4.3 CCountryCharacters (cc+4080) 五键状态族公共发射
    -- (character 行首, 四 flag 行序 = 存档文档序)
    local function emit_status(base, st)
        emit(tag, base .. ".character", SL.idpair(st.id, st.type))
        emit(tag, base .. ".country_leader", SL.yn(st.country_leader))
        emit(tag, base .. ".advisor", SL.yn(st.advisor))
        emit(tag, base .. ".unit_leader", SL.yn(st.unit_leader))
        emit(tag, base .. ".scientist", SL.yn(st.scientist))
    end

    -- character_status : 1.19.3 writer 原序直写向量, 段内禁
    -- sort — r.statuses 保持 reader 遍历序 (向量原序), 直接发射
    local seq = SL.seqc()
    for _, st in ipairs(r.statuses or {}) do
        emit_status("characters." .. seq("character_status"), st)
    end

    -- retired_character_status : writer 原序直写 (reader retired 已原序)
    local rseq = SL.seqc()
    for _, st in ipairs(r.retired or {}) do
        emit_status("characters."
            .. rseq("retired_character_status"), st)
    end

    -- appointed_advisors 匿名块 #N (1 起 = 容器序; 块内 slot 先 character 后)
    for ai, av in ipairs(r.advisors or {}) do
        local base = "characters.appointed_advisors.#" .. ai
        local sl = SL.Q(av.slot)
        if sl then emit(tag, base .. ".slot", sl) end
        if av.char_id then
            emit(tag, base .. ".character",
                 SL.idpair(av.char_id, av.char_type))
        end
    end

    -- recruit_scientist (叶级重复键不编号; 仅池非空 — 空池 writer 不写块)
    for _, sc in ipairs(r.recruit_scientists or {}) do
        emit(tag, "characters.recruit_scientist.scientist",
             SL.idpair(sc.id, sc.type))
    end

    -- retired_operative_leader: 池 {d@ch+200, c@ch+212} → reader
    -- retired_operatives (Runtime.op_leader 转换); 叶规则 =
    -- sv2_sec_c_intelligence_agency op_emit 同型 (writer 链相同),
    -- 重复块键 [N] 编号。⚠ 本族发射键集 = agency 版子集 (无 desc/
    -- custom_cost_text/picture/portrait_path/cooldown) 且 mission
    -- state 无型别白名单 (通用口径)
    do
        local R = c.R
        local OP_STATE = { [0] = "on_capture", [1] = "on_cooldown",
            [2] = "on_disband", [3] = "on_mission", [4] = "on_operation",
            [5] = "killed" }
        local MISSION_NAMES = { [1] = "build_intel_network",
            [2] = "quiet_network", [3] = "counter_intelligence",
            [4] = "root_out_resistance", [5] = "boost_ideology",
            [6] = "control_trade", [7] = "diplomatic_pressure",
            [8] = "propaganda" }
        local function tagof(tid)
            if tid and tid > 0 and R then return R:tag(tid) end
            return nil
        end
        local oseq = SL.seqc()
        for _, o in ipairs(r.retired_operatives or {}) do
            local base = "characters."
                .. oseq("retired_operative_leader")
            emit(tag, base .. ".id", SL.idpair(o.id, o.type))
            local qn = SL.Q(o.name)
            if qn then emit(tag, base .. ".name", qn) end
            -- gfx: COperativeLeader MSVC@+256 (非空才写) — 本处曾漏发
            -- (退役干员有 gfx 而候选池无 → 单侧 MISS)
            local qg = SL.Q(o.gfx)
            if qg then emit(tag, base .. ".gfx", qg) end
            if o.female_gate then
                emit(tag, base .. ".female", SL.yn(o.female or 0)) end
            emit(tag, base .. ".skill", SL.num(o.skill or 0))
            local xp = o.experience
            if xp and xp ~= 0 then
                emit(tag, base .. ".experience", SL.num(xp)) end
            local sid = o.script_id or 0
            if sid ~= 0 then
                emit(tag, base .. ".script_id", SL.num(sid)) end
            if o.traits and o.traits ~= "" then
                emit(tag, base .. ".traits", o.traits) end
            -- in_progress 16B {tok*, i64×1e-5} 全条目含 0
            for _, pp in ipairs(o.in_progress_pairs or {}) do
                emit(tag, base .. ".in_progress." .. tostring(pp.tok),
                    SL.num(pp.val))
            end
            local lid = o.legacy_u32 or 0xFFFFFFFF
            if lid ~= 0xFFFFFFFF then
                emit(tag, base .. ".legacy_id", SL.num(lid)) end
            -- nationalities u32 tid 数组 → 单行 #1 空格 joined 裸 tag
            if o.nationalities and o.nationalities ~= "" then
                emit(tag, base .. ".nationalities.#1", o.nationalities) end
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
            emit(tag, base .. ".codename.type",
                SL.num(o.codename_type or 0))
            local cno = o.codename_name_order or 0
            if cno ~= 0 then
                emit(tag, base .. ".codename.name_order", SL.num(cno)) end
            if o.codename_is_name_ordered_zero then
                emit(tag, base .. ".codename.is_name_ordered", "no") end
            local mtype = o.mission_type_code or 0
            if mtype ~= 0 then
                local mn = MISSION_NAMES[mtype] or tostring(mtype)
                local mb = base .. ".mission." .. mn
                local mt = tagof(o.mission_target_tid or 0)
                if mt then emit(tag, mb .. ".target", SL.Q(mt)) end
                -- ⚠ 退役族通用口径: 不带 build_intel_network(1)/
                -- root_out_resistance(4) 白名单 (agency 版有)
                local msv = o.mission_state_raw or 0
                if msv ~= 0 then
                    emit(tag, mb .. ".state", SL.num(msv)) end
            end
            -- operation (0x2F1B): id 对门 type/id 任一≠0, 叶序在
            -- codename 后 state 前 (retired 与现役同一 writer
            -- 0x140C18FF0, 镜像 op_emit)
            local opty, opid = o.operation_type or 0, o.operation_id or 0
            if opty ~= 0 or opid ~= 0 then
                emit(tag, base .. ".operation", SL.idpair(opid, opty)) end
            local stn = OP_STATE[o.state or 0]
            if stn then
                emit(tag, base .. ".state",
                    "state=" .. stn .. " }") end
        end
    end
end }
