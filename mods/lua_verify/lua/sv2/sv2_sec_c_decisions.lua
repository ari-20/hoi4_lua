-- sv2_sec_c_decisions.lua -- country.decision_status 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.decision_status", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local r = c:decisions()
    if not r then return end
    -- §4.12.2 CDecisionStatus 决策状态族 (挂 cc+4000, 挂载见 §4.12.3)

    -- re_enable/remove days reader 取 ru32 无符号; 防御性符号扩展
    -- (本存档未见负值, 与 timed/targeted 的 i32 处理对齐)
    local function s32(v)
        if v then v = GAME.layout.as_i32(v) end
        return v
    end

    -- §4.12.2 decisions_taken (+64): 仅非空写, 单行 #1, token 序 = 容器序
    local dt = r.decisions_taken
    if dt and dt.items and #dt.items > 0 then
        local names = {}
        for _, it in ipairs(dt.items) do
            if it.name then names[#names + 1] = it.name end
        end
        if #names > 0 then
            emit(tag, "decision_status.decisions_taken.#1",
                table.concat(names, " "))
        end
    end

    -- §4.12.2 CDecisionCooldown re_enable / remove (+88/+112):
    -- {decision 引号, days int} 恒写
    local function simple_list(items, base)
        local seq = SL.seqc()
        for _, it in ipairs(items or {}) do
            local p = seq(base)
            local nm = SL.Q(it.name)
            if nm then emit(tag, p .. ".decision", nm) end
            emit(tag, p .. ".days", SL.num(s32(it.days)))
        end
    end
    simple_list(r.to_re_enable and r.to_re_enable.items,
        "decision_status.decision_to_re_enable")
    simple_list(r.to_remove and r.to_remove.items,
        "decision_status.decision_to_remove")

    -- §4.12.2 CTimedDecision active_timed (+160): state 裸枚举手映射
    -- (reader 返回原始 u32)
    local TIMED_STATE = { "active", "completed", "failed", "aborted",
        "re_enable_cooldown" }
    do
        local seq = SL.seqc()
        for _, it in ipairs((r.active_timed and r.active_timed.items) or {}) do
            local p = seq("decision_status.active_timed_decision")
            local nm = SL.Q(it.name)
            if nm then emit(tag, p .. ".decision", nm) end
            emit(tag, p .. ".days", SL.num(it.days))
            local st = TIMED_STATE[(it.state or 0) + 1]
            if st then emit(tag, p .. ".state", st) end
        end
    end

    -- §4.12.2 CTargetedDecision targeted / att_timed (+232/+256):
    -- 五字段恒写; state reader 已映射 (枚举);
    -- target 恒写 (TAG 或州 id; 皆无 → 0, writer 恒写 target= 佐证
    -- random_item target=0 亦写)
    local function targeted(items, base)
        local seq = SL.seqc()
        for _, it in ipairs(items or {}) do
            local p = seq(base)
            local nm = SL.Q(it.name)
            if nm then emit(tag, p .. ".decision", nm) end
            emit(tag, p .. ".target", it.target or "0")
            emit(tag, p .. ".target.ignore", SL.yn(it.ignore))
            emit(tag, p .. ".days", SL.num(it.days))
            if it.state then emit(tag, p .. ".state", it.state) end
        end
    end
    targeted(r.active_targeted and r.active_targeted.items,
        "decision_status.active_targeted_decision")
    targeted(r.att_timed and r.att_timed.items,
        "decision_status.active_targeted_timed_decision")

    -- §4.12.2 random_item (+328): {decision 引号, count int, target int}
    -- 恒写 (target=0 写)
    do
        local seq = SL.seqc()
        for _, it in ipairs((r.random_item and r.random_item.items) or {}) do
            local p = seq("decision_status.random_item")
            local nm = SL.Q(it.name)
            if nm then emit(tag, p .. ".decision", nm) end
            emit(tag, p .. ".count", SL.num(it.count))
            emit(tag, p .. ".target", SL.num(it.target))
        end
    end
end }
