-- sv2_sec_c_radar.lua -- country.radar 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.radar", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    -- §4.11.5 intel_source 挂载族 — radar 挂载 @cc+4416 内联
    -- (CStaticIntelSourceReference: country=idx / pool / id / discriminant)
    local ok, r = pcall(function() return c:intel_sources() end)
    local s = ok and r and r.radar or nil
    if not s or not s.country then return end
    emit(tag, "radar.intel_source.country", '"' .. s.country .. '"')
    emit(tag, "radar.intel_source.pool", tostring(s.pool or 0))
    emit(tag, "radar.intel_source.id", tostring(s.id or 0))
    emit(tag, "radar.intel_source.discriminant", tostring(s.discriminant or 0))
end }
