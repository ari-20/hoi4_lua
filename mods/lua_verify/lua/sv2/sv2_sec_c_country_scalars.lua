-- sv2_sec_c_country_scalars.lua -- country 顶层散标量族 savefull 直出 (csec)

SV2.csec[#SV2.csec + 1] = { name = "country.scalars", emit = function(ctx)
    local SL, emit, tag = SV2.lib, ctx.emit, ctx.tag
    local cc = ctx.cc
    if not cc then return end
    local rp, ru32 = SL.rp, SL.ru32
    local kptr = SL.kptr
    -- MSVC SSO 串 {buf@0, size@0x10, cap@0x18} (§3.5; objects_v2 U.sso 同构内联)
    local function sso(obj)
        if not obj or obj < 0x10000 then return nil end
        local size = ru32(obj + 0x10)
        if not size or size > 4096 then return nil end
        if size == 0 then return "" end
        -- 内联判据 = cap (MSVC; 实证 size=15/cap=31 堆串)
        local cap = ru32(obj + 0x18)
        local buf = (cap and cap > 15) and rp(obj) or obj
        if not buf or buf < 0x10000 then return nil end
        local chars = {}
        for j = 0, size - 1 do
            local ch = ru32(buf + j)
            if not ch then return nil end
            chars[#chars + 1] = string.char(ch & 0xFF)
        end
        return table.concat(chars)
    end
    -- i64 ×1e-5 定点 (objects_v2 U.fix5 同构; 必须 /100000 不能 *1e-5)
    local fix5 = GAME.layout.fix5
    -- CGameDate 总小时 raw (B 族: 43808760 → "1.1.1.1" 照发)
    local date_raw = SL.date_raw
    local function u(key, a) -- u32 恒写
        local v = ru32(a)
        if v then emit(tag, key, SL.num(v)) end
    end
    local function fx(key, a) -- fixed5 恒写
        local v = fix5(a)
        if v then emit(tag, key, SL.num(v)) end
    end
    -- §4.3.11 CCountry 标量族 (散标量行另见 §4.3.12 杂项表)
    u("capital", cc + 4120)
    u("original_capital", cc + 4124)
    fx("stability", cc + 4304)
    fx("war_support", cc + 4312)
    u("refresh", cc + 4320)
    fx("command_power", cc + 496)
    do -- scripted_gui_random i32 符号 ()
        local v = ru32(cc + 544)
        if v then
            v = GAME.layout.as_i32(v)
            emit(tag, "scripted_gui_random", SL.num(v))
        end
    end
    u("research_slot", cc + 4936)
    fx("accidents_score", cc + 5352)
    do -- cosmetic_tag SSO@5256, 空串照写 ""
        local s = sso(cc + 5256)
        if s then emit(tag, "cosmetic_tag", '"' .. s .. '"') end
    end
    do -- focus_tree SSO@*(4976)+8 (指针门)
        local p = rp(cc + 4976)
        if kptr(p) then
            local s = sso(p + 8)
            if s then emit(tag, "focus_tree", '"' .. s .. '"') end
        end
    end
    do -- continuous_focus_palette SSO@*(4984)+8 (指针门)
        local p = rp(cc + 4984)
        if kptr(p) then
            local s = sso(p + 8)
            if s then emit(tag, "continuous_focus_palette", '"' .. s .. '"') end
        end
    end
    do -- pride_of_the_fleet_date_lost (hours@608, 默认态照发)
        local d = date_raw(ru32(cc + 608))
        if d then emit(tag, "pride_of_the_fleet_date_lost", '"' .. d .. '"') end
    end
    do -- use_legacy_ai_pp_spend bool@5214 恒写
        local v = ru32(cc + 5214)
        if v then emit(tag, "use_legacy_ai_pp_spend", SL.yn((v & 0xFF) == 1)) end
    end
    u("instances_counter", cc + 432)
    do -- preferred_tactic u32@*(5584)+152 (指针门)
        local o = rp(cc + 5584)
        if kptr(o) then
            local v = ru32(o + 152)
            if v then emit(tag, "preferred_tactic", SL.num(v)) end
        end
    end
    do -- dynamic_revolution_tag (§4.3.12 表 +5112 行; writer ccountry L812-828):
        -- 容器 {d@cc+5112, c@cc+5124} 16B 元 {子对象 ptr@+0,
        -- tag_id u32@+8}; 块 13668 开: tag = 引号 tag 串
        -- (BA5C20 = tt+32*tid, tt=rp(gs+0x358));
        -- ideology = 裸 token (u32@*(elem+0)+20 → ADCE0 11838)
        local drd, drc = rp(cc + 5112), ru32(cc + 5124)
        if kptr(drd) and drc and drc > 0 and drc < GAME.layout.lim.PTR_SANE then
            local ttab = ctx.gs and rp(ctx.gs + 0x358) or nil
            for i = 0, drc - 1 do
                local tid = ru32(drd + 16 * i + 8)
                if tid and tid > 0 and kptr(ttab) and tid < 4096 then
                    local ts = SL.sso(ttab + 32 * tid)
                    local qt = ts and ts ~= "" and ts ~= "---" and SL.Q(ts)
                    if qt then
                        emit(tag, "dynamic_revolution_tag.tag", qt)
                    end
                end
                local op = rp(drd + 16 * i)
                if kptr(op) then
                    local it = ru32(op + 20)
                    if it and it > 0 then
                        local inm = SL.tok(it)
                        if inm then
                            emit(tag, "dynamic_revolution_tag.ideology",
                                tostring(inm))
                        end
                    end
                end
            end
        end
    end
    -- ===== ace 族 (§4.3.12 country.ace 表 — CAce 元素; serialize
    -- 0x14060F1F0; 布局上提
    -- reader Country.aces — 段侧只留写门/格式) =====
    do
        local aces = ctx.country and ctx.country:aces()
        if aces then
            local seq = SL.seqc()
            for _, e in ipairs(aces) do
                local blk = seq("ace")
                emit(tag, blk .. ".id", SL.idpair(e.id_id, e.id_type))
                if e.modifier then
                    emit(tag, blk .. ".modifier", '"' .. e.modifier .. '"')
                end
                if e.name then emit(tag, blk .. ".name", '"' .. e.name .. '"') end
                if e.surname then
                    emit(tag, blk .. ".surname", '"' .. e.surname .. '"') end
                if e.callsign and e.callsign ~= "" then
                    emit(tag, blk .. ".callsign", '"' .. e.callsign .. '"') end
                if e.portrait then
                    emit(tag, blk .. ".portrait", SL.num(e.portrait)) end
                if e.is_female ~= 0 then
                    emit(tag, blk .. ".is_female", "yes") end
                if e.alive == 0 then emit(tag, blk .. ".alive", "no") end
                if e.handled ~= 0 then emit(tag, blk .. ".handled", "yes") end
                if e.kill_type ~= 0 then
                    emit(tag, blk .. ".kill_type", SL.num(e.kill_type)) end
                if e.killer_name_type ~= 0 or e.killer_name_id ~= 0 then
                    emit(tag, blk .. ".killer_name",
                        SL.idpair(e.killer_name_id, e.killer_name_type))
                end
                -- killer_country i32 带符号 >0 才写 (引号 tag)
                local kc = e.killer_country_tid
                if kc > 0 and kc < 0x80000000 then
                    local ks = ctx.O:tag(kc)
                    if ks and ks ~= "" then
                        emit(tag, blk .. ".killer_country",
                            '"' .. ks .. '"') end
                end
            end
        end
    end
end }
