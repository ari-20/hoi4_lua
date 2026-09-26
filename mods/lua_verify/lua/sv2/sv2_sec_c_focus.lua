-- sv2_sec_c_focus.lua -- country.focus 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Country.focus /
--  Country.focus_cost_reduction, objects_characters §29.1 / §4.3.14)
SV2.csec[#SV2.csec + 1] = { name = "country.focus", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end

    -- §4.3.1 CReducedFocusCost: focus_cost_reduction 键 = focus 名, 值 int
    local okf, fcr = pcall(function() return c:focus_cost_reduction() end)
    if okf and fcr then
        for _, e in ipairs(fcr) do
            if e.key then
                emit(tag, "focus_cost_reduction." .. e.key,
                    SL.num(e.value or 0))
            end
        end
    end

    -- §4.3.14 CFocusStatus
    local ok2, f = pcall(function() return c:focus() end)
    if not ok2 or not f then return end
    local has_content = false

    -- shine 列表 (仅非空; 单行 #1 空格 joined)
    if f.shine and #f.shine > 0 then
        has_content = true
        emit(tag, "focus.activate_shine_on_focus.#1",
            table.concat(f.shine, " "))
    end
    -- completed 双形态渲染: joint → "TAG 名" (tid 0 渲 "---",
    -- writer BA5C20 串表 idx0); plain → '"名"'
    for _, rec in ipairs(f.completed_records or {}) do
        if rec.joint then
            local tid = rec.originator_tid or 0
            local tg = (tid > 0 and rec.originator) and rec.originator
                or (tid > 0 and tostring(tid) or "---")
            emit(tag, "focus.completed", tg .. " " .. rec.name)
        else
            emit(tag, "focus.completed", '"' .. rec.name .. '"')
        end
        has_content = true
    end
    -- progress (门 ≠0)
    local prog = f.progress
    if prog and prog ~= 0 then
        has_content = true
        emit(tag, "focus.progress", SL.num(prog)) end
    -- current / current_continuous (空串门 = writer 规则)
    if f.current and f.current ~= "" then
        has_content = true
        emit(tag, "focus.current", '"' .. f.current .. '"') end
    if f.current_continuous and f.current_continuous ~= "" then
        has_content = true
        emit(tag, "focus.current_continuous",
            '"' .. f.current_continuous .. '"') end
    if has_content and (f.paused_raw or 0) == 0 then
        emit(tag, "focus.paused", "no") end
end }
