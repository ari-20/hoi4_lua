-- sv2_sec_unit_leader.lua -- unit_leader 顶层块 savefull 直出 (钻研定案)

SV2.gsec[#SV2.gsec + 1] = { name = "unit_leader", emit = function(ctx)
    local SL, emit = SV2.lib, ctx.emit
    local rp, ru32 = SL.rp, SL.ru32
    local gs = ctx.gs
    -- §1.2 全局 unit-leader CID 注册表 gs+1040 (count@gs+1052; 类 =
    -- §4.4.2 CUnitLeader): 条目 8B {type u32, id u32}, idx0 = null 哨兵
    local d, cnt = rp(gs + 0x410), ru32(gs + 0x41C)
    if not (SL.kptr(d) and cnt and cnt > 1 and cnt < 100000) then return end
    local seq = 0
    for i = 1, cnt - 1 do
        local ty = ru32(d + 8 * i)
        local id = ru32(d + 8 * i + 4)
        if ty and ty ~= 0 then
            seq = seq + 1
            emit("unit_leader", "#" .. seq, SL.idpair(id, ty))
        end
    end
end }
