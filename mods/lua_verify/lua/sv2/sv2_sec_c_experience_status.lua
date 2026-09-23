-- sv2_sec_c_experience_status.lua -- country.experience_status 节点

SV2.csec[#SV2.csec + 1] = { name = "country.experience_status",
    emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
    -- §4.3.17 CCountryExperienceStatus (cc+5512, vt 0x29A80C0)
    local es = rp(ctx.cc + 5512)
    if not SL.kptr(es) then return end
    local BASE = ctx.BASE
    if rp(es) ~= BASE + GAME.layout.vt.CExperienceStatus then return end
    local function q15(off)               -- 带符号 Q15 → 浮点 (§3.7 数值换算)
        local v = rp(es + off)
        if not v then return 0 end
        v = GAME.layout.as_i64(v)
        return v / 32768
    end
    local SCAL = {                        -- {path, offset}
        { "army_experience", 16 }, { "navy_experience", 40 },
        { "air_experience", 64 }, { "army_experience_daily", 24 },
        { "army_experience_daily_training", 32 },
        { "navy_experience_daily", 48 }, { "air_experience_daily", 72 },
    }
    for _, s in ipairs(SCAL) do
        local v = q15(s[2])
        if v ~= 0 then
            emit(tag, "experience_status." .. s[1], SL.num(v)) end
    end
    emit(tag, "experience_status.num_armies_for_training",
        SL.num((ru32(es + 80) or 0) / 32768))

    local ok, ad = pcall(function() return c:activity_data() end)
    if not ok or not ad then return end
    -- §4.3.17 三族容器全槽编号 (#N = 容器序含空槽, 与容器 writer 一致);
    -- 叶门按元素 writer: combat/training ≠0, id 对仅 ref 任一≠0
    local n1 = 0
    for _, e in ipairs(ad.xp_by_template or {}) do
        n1 = n1 + 1
        local b = "experience_status.xp_by_template.#" .. n1
        if (e.combat or 0) ~= 0 then
            emit(tag, b .. ".combat", SL.num(e.combat)) end
        if (e.training or 0) ~= 0 then
            emit(tag, b .. ".training", SL.num(e.training)) end
        -- ref 门同 taskforce: 任一≠0 且 id 对解析成功
        -- (division 家族同一 writer 门)
        if (e.ref_type or 0) ~= 0 or (e.ref_id or 0) ~= 0 then
            if (hoi4.call_u64(BASE + 0x221F310, e.addr + 0x10) or 0) ~= 0 then
                emit(tag, b .. ".division", SL.idpair(e.ref_id, e.ref_type))
            end
        end
    end
    -- taskforce: mission 门 byte@+0x1C reader 未给 → 容器内联直读
    -- (ad.addr = es; on_mission 符号 >0)
    local n2 = 0
    do
        local es = ad.addr
        local td, tc = rp(es + 112), ru32(es + 124)
        if SL.kptr(td) and tc and tc > 0 and tc < GAME.layout.lim.PTR_HUGE then
            for i = 0, tc - 1 do
                local e = td + 40 * i
                if rp(e) == BASE + GAME.layout.vt.CExperienceElem then
                    n2 = n2 + 1
                    local b = "experience_status.xp_by_taskforce.#" .. n2
                    local cb, tr = ru32(e + 8) or 0, ru32(e + 12) or 0
                    if cb ~= 0 then
                        emit(tag, b .. ".combat", SL.num(cb)) end
                    if tr ~= 0 then
                        emit(tag, b .. ".training", SL.num(tr)) end
                    -- ref 门 (writer 0X141961BB0): 任一≠0 **且 id 对解析成功**
                    -- (sub_14221F310(e+16) ≠ 0; 返 0 = 目标已不存在 → 不写)
                    local rt, ri = ru32(e + 0x10) or 0, ru32(e + 0x14) or 0
                    if (rt ~= 0 or ri ~= 0)
                        and (hoi4.call_u64(BASE + 0x221F310, e + 0x10) or 0) ~= 0 then
                        emit(tag, b .. ".task_force", SL.idpair(ri, rt)) end
                    local om = ru32(e + 0x20) or 0
                    om = GAME.layout.as_i32(om)
                    if om > 0 then
                        emit(tag, b .. ".on_mission", SL.num(om)) end
                    if (ru8(e + 0x1C) or 0) ~= 0 then
                        emit(tag, b .. ".mission",
                            SL.num(ru32(e + 0x18) or 0)) end
                end
            end
        end
    end
    local n3 = 0
    for _, e in ipairs(ad.xp_by_airwing or {}) do
        n3 = n3 + 1
        local b = "experience_status.xp_by_airwing.#" .. n3
        if (e.combat or 0) ~= 0 then
            emit(tag, b .. ".combat", SL.num(e.combat)) end
        if (e.training or 0) ~= 0 then
            emit(tag, b .. ".training", SL.num(e.training)) end
        -- ref 门同上: 解析成功才写
        if ((e.ref_type or 0) ~= 0 or (e.ref_id or 0) ~= 0)
            and (hoi4.call_u64(BASE + 0x221F310, e.addr + 0x10) or 0) ~= 0 then
            emit(tag, b .. ".air_wing", SL.idpair(e.ref_id, e.ref_type))
        end
    end
end }
