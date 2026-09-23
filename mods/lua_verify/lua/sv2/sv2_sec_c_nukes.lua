-- sv2_sec_c_nukes.lua -- country.nukes 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.nukes", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    -- §4.3.10 CNuke (容器 cc+4880; 元素 72B — amount fix5@+24 /
    -- nukes_ready u32@+60, reader c:nukes())
    local ok, r = pcall(function() return c:nukes() end)
    if not ok or not r then return end
    for ni, ne in ipairs(r.list or {}) do
        local kp = "nukes.#" .. ni .. "."
        emit(tag, kp .. "amount", SL.num(ne.amount or 0))
        emit(tag, kp .. "nukes_ready", tostring(ne.nukes_ready or 0))
    end
end }
