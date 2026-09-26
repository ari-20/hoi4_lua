-- sv2_sec_c_convoys.lua -- country.convoys 节点 savefull 直出
-- 结构唯一实现 = Country:convoys_equipment (objects_economy §4.3.18 补充)。

SV2.csec[#SV2.csec + 1] = { name = "country.convoys", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ok, ce = pcall(function() return c:convoys_equipment() end)
    if not ok or not ce then return end
    local seq = SL.seqc()
    for _, eq in ipairs(ce.list or {}) do
        local kp = "convoys.equipment." .. seq("equipment") .. "."
        emit(tag, kp .. "id", SL.idpair(eq.id, eq.type))
        emit(tag, kp .. "amount", SL.num(eq.amount)) end
    emit(tag, "convoys.equipment.allow_zero_entries", SL.yn(ce.az))
end }
