-- sv2_sec_c_flags.lua -- country.flags 节点 savefull 直出
-- 结构唯一实现 = Country:flags_list (objects_shared §4.13.3 补充)。

SV2.csec[#SV2.csec + 1] = { name = "country.flags", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ok, flags = pcall(function() return c:flags_list() end)
    if not ok or not flags then return end
    for _, fg in ipairs(flags) do
        local kp = "flags." .. fg.name .. "."
        emit(tag, kp .. "value", tostring(fg.value))
        if fg.date_h then
            local ds = SL.date(fg.date_h)
            if ds then emit(tag, kp .. "date", '"' .. ds .. '"') end end
        if fg.days then emit(tag, kp .. "days", tostring(fg.days)) end
    end
end }
