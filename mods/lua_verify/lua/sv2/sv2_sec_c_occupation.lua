-- sv2_sec_c_occupation.lua -- country.occupation_status 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.occupation_status", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32 = hoi4.read_u64, hoi4.read_u32
    local ru8 = hoi4.read_u8 -- 前置: Lua 词法作用域不向后覆盖 (L94 先用后宣事故)
    local occ = c:occupation()
    if not occ then return end
    -- §4.3.2 CCountryOccupationStatus (occ 基 = rp(cc+4048))
    local P = "occupation_status."

    local function splitcsv(s)
        local out = {}
        if s and s ~= "" and s ~= "nil" then
            for part in tostring(s):gmatch("[^,]+") do out[#out + 1] = part end
        end
        return out
    end

    -- ===== 顶级三叶 =====
    local prio = occ.priority or 1
    if prio ~= 1 then emit(tag, P .. "priority", SL.num(prio)) end
    if occ.division_template then
        emit(tag, P .. "division_template_id", SL.idpair(
            occ.division_template.id, occ.division_template.type))
    end
    local dl = SL.Q(occ.default_law)
    if dl then emit(tag, P .. "default_law", dl) end

    -- ===== §4.3.6 state_compliance_cache (reader 已解, 值 raw i64
    -- 段侧 ×1e-5 渲染 — 值 AE9A0 无零门) =====
    for _, scc in ipairs(occ.state_compliance_cache or {}) do
        emit(tag, P .. "state_compliance_cache." .. scc.sid,
            SL.num(scc.raw * 1e-5))
    end

    -- ===== §4.3.2 占领记录 dp / §4.3.6 写门族: occupation.<R> 每被占国 =====
    for _, od in ipairs(occ.occupied or {}) do
        local B = P .. "occupation." .. tostring(od.tag) .. "."
        -- §4.3.6 states.#1 (reader states_raw = 向量原序 — writer 原序
        -- 直写, sort 版弃用); 同时建 states 集 = SGD 写门 (头注定案)
        local stset = {}
        if od.states_raw then
            local ids = {}
            for _, sidv in ipairs(od.states_raw) do
                ids[#ids + 1] = tostring(sidv)
                stset[sidv] = true
            end
            emit(tag, B .. "states.#1", table.concat(ids, " "))
        end
        local stgate = next(stset) ~= nil
        -- resistance_modifiers.#N (dp+88/100, 向量序, 引号)
        for j, nm in ipairs(splitcsv(od.resistance_modifiers)) do
            emit(tag, B .. "resistance_modifiers.#" .. j,
                '"' .. nm .. '"')
        end
        -- compliance_modifiers.#N (向量序, 引号)
        for j, nm in ipairs(splitcsv(od.compliance_modifiers)) do
            emit(tag, B .. "compliance_modifiers.#" .. j,
                '"' .. nm .. '"')
        end
        -- 四定点: resistance/compliance 恒写 (writer 0x140FEA660 L153-154
        -- 无门); strength_ratio/garrison_required **≠0 门** (writer
        -- L381-386 if(*(v3+80)) / if(*(v3+72)) 实证; CRC/SUR 零值案)
        emit(tag, B .. "resistance", SL.num(od.resistance))
        emit(tag, B .. "compliance", SL.num(od.compliance))
        if (od.strength_ratio or 0) ~= 0 then
            emit(tag, B .. "strength_ratio", SL.num(od.strength_ratio))
        end
        if (od.garrison_required or 0) ~= 0 then
            emit(tag, B .. "garrison_required", SL.num(od.garrison_required))
        end
        -- occupation_law 条件写
        local ol = SL.Q(od.occupation_law)
        if ol then emit(tag, B .. "occupation_law", ol) end
        -- §4.3.2 occupation_law_list (dp+0xB0 RH; reader law_list_map
        -- 已按 writer 门解出 — 镜像写一切 dist≠0 桶)
        for sid2, nm2 in pairs(od.law_list_map or {}) do
            emit(tag, B .. "occupation_law_list." .. sid2, nm2)
        end
        -- §4.3.6 state_garrison_data: garrison_data "sid|sr|gr|amn,..." 主键序 +
        -- garrison_x "sid;az;amn;eq;en;grr;mpv ! 分隔" 按 sid 配对
        local gdx = {}
        for _, gx in ipairs((function(s)
                local out = {}
                if s and s ~= "" then
                    for part in tostring(s):gmatch("[^!]+") do
                        out[#out + 1] = part
                    end
                end
                return out
            end)(od.garrison_x)) do
            local sid3, az3, amn3, eq3, en3, grr3, mpv3, sup3 = gx:match(
                "^(%d+);(%d+);([^;]*);([^;]*);([^;]*);([^;]*);(.*);(%d+)$")
            if sid3 then
                gdx[sid3] = { az = az3, eq = eq3, en = en3,
                    grr = grr3, mpv = mpv3, sup = sup3 }
            end
        end
        for _, gd in ipairs(splitcsv(od.garrison_data)) do
            local sid, sr, gr, amn =
                gd:match("^(%d+)|([^|]+)|([^|]+)|([^|]+)$")
            -- SGD 写门: sid ∈ states 集 (reader 越界桶在此滤除, 头注);
            -- states 向量读取失败时门退化放行 (限损 = 回到旧过发行为)
            if sid and (not stgate or stset[tonumber(sid)]) then
                local S = B .. "state_garrison_data." .. sid .. "."
                -- SGD 三值 **≠0 门** (writer 0x140FEB450: strength_ratio
                -- if(*(a1+240)) / garrison_required if(*(a1+248)) /
                -- army_manpower_need u32 if(*(a1+136)) 实证;
                -- CRC.695/SUR.309 零值案)
                local srv, grv, amnv = tonumber(sr), tonumber(gr),
                    tonumber(amn)
                if srv and srv ~= 0 then
                    emit(tag, S .. "strength_ratio", SL.num(srv))
                end
                if grv and grv ~= 0 then
                    emit(tag, S .. "garrison_required", SL.num(grv))
                end
                local x = gdx[sid]
                -- manpower_pool.value ("tagidx:val,..." → tag 反查)
                for _, pv in ipairs(splitcsv(x and x.mpv)) do
                    local tidx, pval = pv:match("^(%d+):(%d+)$")
                    if tidx then
                        local tn = (c.R and c.R:tag(tonumber(tidx))) or tidx
                        emit(tag, S .. "manpower_pool.value",
                            string.format('tag="%s" value=%s',
                                tostring(tn), pval))
                    end
                end
                if amnv and amnv ~= 0 then
                    emit(tag, S .. "army_manpower_need", SL.num(amnv))
                end
                -- suppression byte@SGD+0x60 ≠0 才写 yes (writer 0x140FEB450
                -- AE850(0x2EB7); INS PNG.669 实证)
                local sup = tonumber(x and x.sup) or 0
                if sup ~= 0 then
                    emit(tag, S .. "suppression", "yes")
                end
                -- equipment.equipment[N] (向量序; "type:id:amt,...")
                local eseq = SL.seqc()
                for _, ep in ipairs(splitcsv(x and x.eq)) do
                    local ety, eid, eamt =
                        ep:match("^(%d+):(%d+):(-?%d+)$")
                    -- 条目门 (池 writer 0x140FFDB00): amount(raw i64)≠0 或
                    -- allow_zero_entries≠0 才发射; eseq 在门内 (编号只对
                    -- 发射条目递增, 门外的编号会整体前移)
                    if eid and (tonumber(eamt) ~= 0
                            or (x and x.az == "1")) then
                        local EK = S .. "equipment."
                            .. eseq("equipment") .. "."
                        emit(tag, EK .. "id", SL.idpair(
                            tonumber(eid), tonumber(ety)))
                        emit(tag, EK .. "amount",
                            SL.num(tonumber(eamt) / 100000))
                    end
                end
                -- allow_zero_entries 恒写 (az "0"/"1")
                if x then
                    emit(tag, S .. "equipment.allow_zero_entries",
                        x.az == "1" and "yes" or "no")
                end
                -- equipment_need.<tok> ("name:amt,...")
                for _, en in ipairs(splitcsv(x and x.en)) do
                    local nnm, namt = en:match("^([^:]+):(-?%d+)$")
                    -- 写门 amt≠0 (writer 不写零需求, FRA 殖民地 32 叶实证)
                    if nnm and tonumber(namt) ~= 0 then
                        emit(tag, S .. "equipment_need." .. nnm,
                            SL.num(tonumber(namt) / 100000))
                    end
                end
                -- garrison_reinforcement_requests.request[N]
                -- ("st^prog^tp^dh^prod^need" ~ 分隔)
                local rseq = SL.seqc()
                local grrs = {}
                if x and x.grr and x.grr ~= "" then
                    for part in tostring(x.grr):gmatch("[^~]+") do
                        grrs[#grrs + 1] = part
                    end
                end
                for _, re in ipairs(grrs) do
                    local st, prog, tp, dh, prod, need, gaz = re:match(
                        "^([^%^]*)%^([^%^]*)%^([^%^]*)%^([^%^]*)"
                        .. "%^([^%^]*)%^([^%^]*)%^(.*)$")
                    if st then
                        local RK = S .. "garrison_reinforcement_requests."
                            .. rseq("request") .. "."
                        if st ~= "0" then
                            emit(tag, RK .. "status", SL.num(tonumber(st)))
                        end
                        if st == "1" then
                            emit(tag, RK .. "progress",
                                SL.num(tonumber(prog) / 100000))
                        end
                        -- total_progress: ≠1 门 (raw≠100000, 头注)
                        if tp ~= "100000" and tp ~= "" then
                            emit(tag, RK .. "total_progress",
                                SL.num(tonumber(tp) / 100000))
                        end
                        if prod and prod ~= "" then
                            local pseq = SL.seqc()
                            for _, pp in ipairs(splitcsv(prod)) do
                                local pty, pid, pamt =
                                    pp:match("^(%d+):(%d+):(-?%d+)$")
                                if pid then
                                    local PK = RK .. "produced."
                                        .. pseq("equipment") .. "."
                                    emit(tag, PK .. "id", SL.idpair(
                                        tonumber(pid), tonumber(pty)))
                                    emit(tag, PK .. "amount",
                                        SL.num(tonumber(pamt) / 100000))
                                end
                            end
                            -- az = 池基+24 (u8; 与 SGD 装备池同规则)
                            emit(tag, RK .. "produced.allow_zero_entries",
                                (gaz == "1") and "yes" or "no")
                        end
                        for _, nd in ipairs(splitcsv(need)) do
                            local nnm2, namt2 =
                                nd:match("^([^:]+):(-?%d+)$")
                            if nnm2 then
                                emit(tag, RK .. "need." .. nnm2,
                                    SL.num(tonumber(namt2) / 100000))
                            end
                        end
                        emit(tag, RK .. "date", '"'
                            .. (SL.date(tonumber(dh)) or "1.1.1.1")
                            .. '"')
                    end
                end
            end
        end
    end

        -- §4.3.2 resistance_attack_log (occ+256 向量; reader occ.resistance_attack_log):
        -- 发射契约: state ptr 门 / manpower 元 value>0 / country·date·
        -- garrison·allow_zero 恒写 / equipment 元 门 amount≠0 或 az;
        -- [N] 第 2 起; 段头勿再加前缀 — seqc 返回完整键名)
        do
            local rseq = SL.seqc()
            for _, e in ipairs(occ.resistance_attack_log or {}) do
                local RK = "occupation_status."
                    .. rseq("resistance_attack_log") .. "."
                if e.state_id then
                    emit(tag, RK .. "state", tostring(e.state_id))
                end
                local mseq = SL.seqc()
                for _, mp in ipairs(e.manpower or {}) do
                    if mp.tag then
                        emit(tag, RK .. "manpower." .. mseq("value"),
                            'tag="' .. mp.tag .. '" value='
                            .. tostring(mp.value))
                    end
                end
                if e.country then
                    emit(tag, RK .. "country", '"' .. e.country .. '"')
                end
                emit(tag, RK .. "date", '"'
                    .. (SL.date(e.date_h) or "1.1.1.1") .. '"')
                emit(tag, RK .. "garrison", e.garrison and "yes" or "no")
                -- resistance_activity (ptr@en+152 → SSO@+8; 有值才写)
                if e.resistance_activity then
                    emit(tag, RK .. "resistance_activity",
                        '"' .. e.resistance_activity .. '"')
                end
                local eseq = SL.seqc()
                for _, ep in ipairs(e.equipment or {}) do
                    local EK = RK .. "equipment."
                        .. eseq("equipment") .. "."
                    emit(tag, EK .. "id", SL.idpair(ep.id, ep.type))
                    emit(tag, EK .. "amount",
                        SL.num(ep.amount / 100000))
                end
                emit(tag, RK .. "equipment.allow_zero_entries",
                    e.eq_allow_zero and "yes" or "no")
            end
        end
end }
