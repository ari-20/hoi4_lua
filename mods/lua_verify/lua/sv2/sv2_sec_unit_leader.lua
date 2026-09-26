-- sv2_sec_unit_leader.lua -- unit_leader 顶层块 savefull 直出
-- 结构唯一实现 = Runtime:unit_leader_registry (objects_characters §1.2 补充)。

SV2.gsec[#SV2.gsec + 1] = { name = "unit_leader", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local ok, r = pcall(function() return O:unit_leader_registry() end)
    if not ok or not r then return end
    for i, e in ipairs(r) do
        emit("unit_leader", "#" .. i, SL.idpair(e.id, e.type)) end
end }
