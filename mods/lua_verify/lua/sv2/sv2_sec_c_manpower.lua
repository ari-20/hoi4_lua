-- sv2_sec_c_manpower.lua -- country.manpower 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.manpower", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ru32 = hoi4.read_u32
    local cc = ctx.cc
    -- §4.3.12 CCountryManpower (人力块宿主 cc+808 内嵌 40B, 布局
    -- §4.3.1 表 +808 行; 叶行 +820/+824/+832/+836)
    local mp = ru32(cc + 808 + 12)
    if mp and mp ~= 0 then
        emit(tag, "manpower.current", SL.num(mp)) end
    local ratio = ru32(cc + 824)
    if ratio and ratio ~= 0 then
        emit(tag, "manpower.ratio", SL.num(ratio)) end
    local exv = ru32(cc + 808 + 24)
    if exv and exv > 0 then
        emit(tag, "manpower.exile_manpower", SL.num(exv)) end
    local exm = ru32(cc + 808 + 28)
    if exm and exm > 0 then
        emit(tag, "manpower.max_exile_manpower", SL.num(exm)) end
end }
