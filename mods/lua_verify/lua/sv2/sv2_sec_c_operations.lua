-- sv2_sec_c_operations.lua -- country.operations 节点 savefull 直出
-- (csec; §4.11.15 country.operations, ops = *(cc+5544))
-- 结构/走查唯一实现 = reader (Country:operations, objects_global §33.1);
-- 本段只持 writer 发射规则 (写序/块门/编号/值格式)。

SV2.csec[#SV2.csec + 1] = { name = "country.operations", emit = function(ctx)
    local SL, emit, tag = SV2.lib, ctx.emit, ctx.tag
    local c = ctx.country
    if not c then return end
    local ok, ops = pcall(function() return c:operations() end)
    if not ok or not ops then return end

    local function tagof(tid)   -- tag_id → 三字串 (writer 门: >0 且 <4096)
        if not (tid and tid > 0 and tid < 4096) then return nil end
        local s = ctx.O:tag(tid)
        if s and s ~= "" then return s end
        return nil
    end
    local function tokname(id)
        local nm = id and GAME.layout.token_name(id) or nil
        if nm and nm ~= "" then return nm end
        return nil
    end

    if ops.priority then
        emit(tag, "operations.priority", SL.num(ops.priority))
    end

    -- ===== finished (pairs 已按 t 升序 = 写序, reader 侧排好) =====
    for _, fin in ipairs(ops.finished or {}) do
        local parts, ok2 = {}, true
        for _, pr in ipairs(fin.pairs or {}) do
            local tn = tagof(pr.t)
            if not tn then ok2 = false break end
            parts[#parts + 1] = tn .. " " .. pr.n
        end
        if ok2 and #parts > 0 then
            emit(tag, "operations.finished." .. fin.name,
                table.concat(parts, " "))
        end
    end

    -- ===== running =====
    for _, op in ipairs(ops.running or {}) do
        local B = "operations.running." .. op.name .. "."
        emit(tag, B .. "id", SL.idpair(op.id_id, op.id_type))
        if op.duration and op.duration ~= 0 then
            local ds = SL.date(op.date_h)
            if ds then emit(tag, B .. "date", '"' .. ds .. '"') end
            emit(tag, B .. "duration", tostring(op.duration))
        end
        -- 代价标量 (writer 0x1413EF710 L11-17: 0x4BDD=civilian_factories /
        -- 0x2A12=total, 均 ×1e-5 ≠0 才写)
        if op.civilian_factories and op.civilian_factories ~= 0 then
            emit(tag, B .. "civilian_factories",
                SL.num(op.civilian_factories * 1e-5))
        end
        if op.total and op.total ~= 0 then
            emit(tag, B .. "total", SL.num(op.total * 1e-5))
        end
        -- resources 块 (§4.11.12/§4.11.16; flag 分支 = reader 已解)
        for _, re in ipairs(op.resources or {}) do
            local amt = re.amount
            if re.flag ~= 0 then
                local a9 = amt >= 0
                    and math.floor(amt / 100000)
                    or -math.floor(-amt / 100000)
                emit(tag, B .. "resources.civilian_factories.amount",
                    SL.num(a9))
                emit(tag, B .. "resources.civilian_factories.days",
                    tostring(re.days or 0))
            else
                if re.def_name and amt then
                    emit(tag, B .. "resources." .. re.def_name,
                        SL.num(amt / 100000))
                end
            end
        end
        -- return_on_complete (§4.11.12; 容器/存档半行匿名形态/提取器 @.#N)
        -- ⚠ roc_n = 原容器计数 (元素可 nil, 编号仍按原下标)
        for oi = 1, op.roc_n or 0 do
            local v = op.return_on_complete[oi]
            if v then
                emit(tag, B .. "return_on_complete.@.#" .. oi,
                    SL.num(v / 100000))
            end
        end
        -- equipment 块恒写 (§4.11.15; ADEC0 0x2F4E 无门) — 池发射 = 共享件
        SL.pool_emit(ctx.O, emit, tag, B .. "equipment.", op.addr + 272,
                     { max = GAME.layout.lim.PTR_SANE })
        local tg = tagof(op.target_tid)
        if tg then emit(tag, B .. "target", '"' .. tg .. '"') end
        if op.target_provinces then
            emit(tag, B .. "target_provinces", tostring(op.target_provinces))
        end
        -- operative_slots (§4.11.15; #N 匿名块)
        for j, s2 in ipairs(op.operative_slots or {}) do
            local SK = B .. "operative_slots.#" .. j .. "."
            if (s2.op_type or 0) ~= 0 or (s2.op_id or 0) ~= 0 then
                emit(tag, SK .. "operative", SL.idpair(s2.op_id, s2.op_type))
            end
            if (s2.resume or 0) ~= 0 then
                emit(tag, SK .. "resume_mission", "yes")
            end
            if (s2.mission_flag or 0) ~= 0 then
                local mnm = tokname(s2.mission_tok)
                if mnm then emit(tag, SK .. "mission.mission", mnm) end
                local mc = tagof(s2.mission_target_tid)
                if mc then
                    emit(tag, SK .. "mission.target_country", '"' .. mc .. '"')
                end
                if s2.mission_state then
                    emit(tag, SK .. "mission.target_state",
                        tostring(s2.mission_state))
                end
            end
        end
        -- phases (引号空格单行; 任一名字解析失败整块不写 = 原门)
        -- ⚠ phases_n = 原容器计数 (名可 nil)
        if (op.phases_n or 0) > 0 then
            local parts, ok2 = {}, true
            for j = 1, op.phases_n do
                local pn = op.phases[j]
                if not pn then ok2 = false break end
                parts[#parts + 1] = '"' .. pn .. '"'
            end
            if ok2 then emit(tag, B .. "phases", table.concat(parts, " ")) end
        end
        -- prepared (hours ≠ 1.1.1.1 哨兵)
        if op.prepared_h and op.prepared_h ~= 43808760 then
            local ds = SL.date(op.prepared_h)
            if ds then emit(tag, B .. "prepared", '"' .. ds .. '"') end
        end
    end
end }
