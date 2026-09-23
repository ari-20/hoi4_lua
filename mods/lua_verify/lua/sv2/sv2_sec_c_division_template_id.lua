-- sv2_sec_c_division_template_id.lua -- country.division_template_id 节点
-- §4.18.4 CDivisionTemplate 国家挂载容器 {data@cc+440, count@cc+452}

SV2.csec[#SV2.csec + 1] = { name = "country.division_template_id", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ok, r = pcall(function() return c:division_template_ids() end)
    if not ok or not r then return end
    for _, dv in ipairs(r) do
        emit(tag, "division_template_id", SL.idpair(dv.id, dv.type))
    end
end }
