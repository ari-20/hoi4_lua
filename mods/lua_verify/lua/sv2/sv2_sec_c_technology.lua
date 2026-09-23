-- sv2_sec_c_technology.lua -- country.technology 节点 savefull 直出
-- 结构 = §4.7 CTechnologyStatus (cc+3936): 主表标量 / §4.7.1 CTechnology (504B)
-- / §4.7.2 CResearchSlot / §4.7.3 CLimitedUseTechBonus / §4.7.4 CLimitedUseTechCostReduction

SV2.csec[#SV2.csec + 1] = { name = "country.technology", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ru32 = hoi4.read_u32
    local tch = c:technology_status()   -- §4.7 CTechnologyStatus (cc+3936)
    if not tch then return end

    -- 逗号串 → 数组 (reader lub/cr 的 category/technologies 拼接形态;
    -- "nil" 是 reader tostring(nil token) 的残留, 滤除)
    local function splitcsv(s)
        local out = {}
        if s and s ~= "" then
            for part in tostring(s):gmatch("[^,]+") do
                if part ~= "" and part ~= "nil" then
                    out[#out + 1] = part
                end
            end
        end
        return out
    end

    -- ===== technology 顶级标量 (§4.7 CTechnologyStatus 主表) =====
    -- override_icons_tag (u32@ts+312 tag_id; 全档 439/439 国写, 引号串)
    local oit = SL.Q(tch.override_icons_tag)
    if oit then emit(tag, "technology.override_icons_tag", oit) end
    -- next_bonus_id (u32@ts+316; 恒写, 全档值 ≥1)
    emit(tag, "technology.next_bonus_id", SL.num(tch.next_bonus_id or 0))

    -- ===== technologies.<tech>.* (§4.7.1 CTechnology, 504B/条) =====
    for _, rec in ipairs(tch.technologies and tch.technologies.list or {}) do
        if rec.name then
            local base = "technology.technologies." .. rec.name
            if rec.level and rec.level > 0 then
                emit(tag, base .. ".level", SL.num(rec.level))
            end
            if rec.research_points and rec.research_points ~= 0 then
                emit(tag, base .. ".research_points",
                    SL.num(rec.research_points))
            end
            -- date: 放行 (reader hours@t+384 可读; §4.7.1 +376 CGameDate);
            -- 哨兵 → "1.1.1.1" 字面量 (U.date 对 0/0x29C3388/43808760 返 nil)
            emit(tag, base .. ".date", '"' .. (rec.date or "1.1.1.1") .. '"')
            if rec.design_team then
                emit(tag, base .. ".design_team", rec.design_team)
            end
            -- locked_design_team: 内联读 t+500 (§4.7.1 +500; ≠"undefined"
            -- token 19479 才写)
            if rec._addr then
                local ldt = ru32(rec._addr + 500)
                if ldt and ldt ~= 19479 then
                    local nm = (GAME.layout and
                        GAME.layout.token_name(ldt)) or ""
                    emit(tag, base .. ".locked_design_team",
                        '"' .. tostring(nm) .. '"')
                end
            end
            if rec.design_team_bonus then
                emit(tag, base .. ".design_team_bonus",
                    SL.num(rec.design_team_bonus))
            end
            if rec.rp_from_design_team then
                emit(tag, base .. ".research_points_from_design_team",
                    SL.num(rec.rp_from_design_team))
            end
            if rec.ahead_reduction then
                emit(tag, base .. ".ahead_reduction",
                    SL.num(rec.ahead_reduction))
            end
            if rec.bonus then
                emit(tag, base .. ".bonus", SL.num(rec.bonus))
            end
            -- use_experience: u8@t+488 ≠0 才写 (§4.7.1 +488 = _BoostedByXP,
            -- 键 15370; writer 0x140ECFFF0 AE850 0x3C0A, 段内内联)
            if rec._addr then
                local ue = hoi4.read_u8(rec._addr + 488)
                if ue and ue ~= 0 then
                    emit(tag, base .. ".use_experience", "yes")
                end
            end
            -- tech 级 limited_use_bonus (uses 数组, §4.7.1 +464): writer
            -- sub_1424C2A10 逐值写同线 + 尾一次换行 = 数组恒单行 → 单叶
            -- 空格连接 (实证 "20 21" 形; 逐值拆 #N 叶 = 假 MISS)
            local uv = rec.lub_uses or {}
            if #uv > 0 then
                local parts = {}
                for _, v2 in ipairs(uv) do
                    parts[#parts + 1] = string.format("%d", v2)
                end
                emit(tag, base .. ".limited_use_bonus.#1",
                    table.concat(parts, " "))
            end
            -- research_points_per_mio: writer 写 map 块 (§4.7.1 +432
            -- std::map, RB-tree 遍历); 提取器逐键分流 — 扩 HEAD 字符集后
            -- ([A-Za-z0-9_./:@-]) 连字符键也发真名 (实证连字符 MIO 键
            -- "AST_vickers-ruwolt_organization", 旧 #N 折叠定案已废);
            -- 仅 HEAD 外脏键走 #N 折叠回退
            for _, mp in ipairs(rec.mio_points or {}) do
                if mp.org then
                    local org = tostring(mp.org)
                    if org:match("^[A-Za-z0-9_./:@-]+$") then
                        emit(tag, base .. ".research_points_per_mio."
                            .. org, SL.num(mp.points))
                    else
                        emit(tag, base .. ".research_points_per_mio.#1",
                            org .. "=" .. SL.num(mp.points))
                    end
                end
            end
        end
    end

    -- ===== slots.<slot>.* (§4.7.2 CResearchSlot; 字段/门 = 书) =====
    -- 内联重读: reader 无 points 字段且空槽名 nil; 无名槽 (token 0)
    -- 存档键 = 字面 "empty" + [N] 重复编号
    do
        local tsb = tch.addr
        local sd, sc = SL.rp(tsb + 160), ru32(tsb + 172)
        if SL.kptr(sd) and sc and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
            local sseq = SL.seqc() -- 重复键 [N]: 空槽名 token 10830 = "empty"
            for i = 0, sc - 1 do
                local s = SL.rp(sd + 8 * i)
                if SL.kptr(s) then
                    local nm = SL.tok(ru32(s + 8))
                    local base = "technology.slots." .. sseq(nm or "empty")
                    local pts = SL.rp_i64(s + 32)
                    if pts and pts ~= 0 then
                        emit(tag, base .. ".points", SL.num(pts * 1e-5))
                    end
                    local usp = SL.rp_i64(s + 40)
                    if usp and usp ~= 0 then
                        emit(tag, base .. ".used_saved_points",
                            SL.num(usp * 1e-5))
                    end
                    local pf = SL.rp_i64(s + 56)
                    if pf and pf ~= 100000 then
                        emit(tag, base .. ".points_factor", SL.num(pf * 1e-5))
                    end
                end
            end
        end
    end

    -- ===== limited_use_bonus[N] 块 (§4.7.3 CLimitedUseTechBonus;
    -- 容器 = 书; 容器序 = 文档序) =====
    -- name 空串也写 (实证 name="" 2 叶案); reader read_str 对空 SSO
    -- 返 nil → 段内内联重读容器对齐索引兜底
    local lub_d = SL.rp(tch.addr + 232)
    local seq_lb = SL.seqc()
    for lbi, lb in ipairs(tch.limited_use_bonus and
        tch.limited_use_bonus.list or {}) do
        local blk = seq_lb("technology.limited_use_bonus")
        if lb.bonus and lb.bonus ~= 0 then
            emit(tag, blk .. ".bonus", SL.num(lb.bonus))
        end
        if lb.uses and lb.uses ~= 0 then
            emit(tag, blk .. ".uses", string.format("%d", lb.uses))
        end
        if lb.claim and lb.claim ~= 0 then
            emit(tag, blk .. ".claim", string.format("%d", lb.claim))
        end
        emit(tag, blk .. ".id", SL.num(lb.id or 0))
        local nmv = lb.name
        if nmv == nil and SL.kptr(lub_d) then
            local le = SL.rp(lub_d + 8 * (lbi - 1))
            if SL.kptr(le) then nmv = SL.sso(le + 16) end
        end
        if nmv ~= nil then
            emit(tag, blk .. ".name", '"' .. tostring(nmv) .. '"')
        end
        for _, cat in ipairs(splitcsv(lb.category)) do
            emit(tag, blk .. ".category", cat)
        end
        for _, tech in ipairs(splitcsv(lb.technologies)) do
            emit(tag, blk .. ".technology", tech)
        end
        if lb.ahead_reduction and lb.ahead_reduction ~= 0 then
            emit(tag, blk .. ".ahead_reduction",
                SL.num(lb.ahead_reduction))
        end
    end

    -- ===== limited_use_cost_reduction_bonus[N] 块 (§4.7.4
    -- CLimitedUseTechCostReduction, 容器 {d@ts+256, c@ts+268}) =====
    local seq_cr = SL.seqc()
    for _, cr in ipairs(tch.cost_reduction and
        tch.cost_reduction.list or {}) do
        local blk = seq_cr("technology.limited_use_cost_reduction_bonus")
        if cr.cost_reduction and cr.cost_reduction ~= 0 then
            emit(tag, blk .. ".cost_reduction",
                SL.num(cr.cost_reduction))
        end
        if cr.uses and cr.uses ~= 0 then
            emit(tag, blk .. ".uses", string.format("%d", cr.uses))
        end
        emit(tag, blk .. ".id", SL.num(cr.id or 0))
        -- name 恒写 (空串也写 "", ROM 实证; SL.Q 会滤空串故不走)
        if cr.name ~= nil then
            emit(tag, blk .. ".name", '"' .. cr.name .. '"') end
        for _, cat in ipairs(splitcsv(cr.category)) do
            emit(tag, blk .. ".category", cat)
        end
    end
end }
