-- sv2_sec_c_deployment.lua -- country.deployment 节点 savefull 直出
-- reader: c:unlocked_subunits / c:deployment_hq /
-- c:deployment_unit_modifiers / c:deployment_conveyors;
-- unit_modifiers 头三叶与 ICAW 按 legacy ev2_secB L2896-2996 内联。
-- writer 规则 (布局/逐叶门 = 书 §4.9/§4.9.2): unlocked_subunits 序 =
-- std::set RB-tree 中序 (按 token 键序, 非字母序); conveyor/line 容器序
-- = 写序 — 「序可能不同」系未定案注记 (本档 GER id 升序与向量序一致)
-- stat_idx → token 映射 (78 项) = objects_v2 §30.6 同表段内拷贝
-- (共享文件不动纪律 → 段内本地副本 STAT2TOK)
local STAT2TOK = {
  [0] = 11950, 10836, 11956, 13733, 11960, 11961, 12196, 13551, 13573,
  12744, 12597, 11887, 11959, 13838, 13375, 14415, 15138, 10106, 10121,
  11965, 11967, 12287, 12288, 10219, 10221, 15351, 15350, 15354, 15353,
  12310, 11972, 12442, 12965, 12332, 13362, 14656, 14657, 12011, 12101,
  15191, 12077, 12089, 16333, 12975, 12976, 12977, 12236, 11958, 11962,
  12238, 12336, 12335, 12440, 12441, 13166, 13269, 15422, 19874, 16415,
  16419, 12330, 11948, 11954, 12099, 12100, 12668, 13572, 593, 10811,
  11955, 15713, 11901, 11964, 17093, 14532, 14531, 12153, 11951,
}
SV2.csec[#SV2.csec + 1] = { name = "country.deployment", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32 = hoi4.read_u64, hoi4.read_u32
    local ru8, kptr = hoi4.read_u8, SL.kptr
    local P = "deployment."
    local function sfx(a) -- 有符号 i64 → ×1e-5
        local v = rp(a) or 0
        v = GAME.layout.as_i64(v)
        return v / 100000
    end

    -- ===== §4.9 CDeployment unlocked_subunits.#N (std::set @dep+56, 中序 = 写序) =====
    local usu = c:unlocked_subunits()
    for ui, uu in ipairs(usu and usu.list or {}) do
        if uu.name then
            emit(tag, P .. "unlocked_subunits.#" .. ui,
                uu.name .. (uu.unlocked and " yes" or " no"))
        end
    end

    -- ===== §4.9 CDeployment default_hq_template / hq_next_deploy_order =====
    local hq = c:deployment_hq()
    if hq then
        if hq.default_hq_id then
            emit(tag, P .. "default_hq_template", SL.idpair(
                hq.default_hq_id, hq.default_hq_type))
        end
        if hq.hq_next_deploy_order then
            emit(tag, P .. "hq_next_deploy_order",
                SL.num(hq.hq_next_deploy_order))
        end
    end

    local dep = rp(c.addr + 3952)          -- §4.3 CCountry +3952 → §4.9 CDeployment
    if SL.kptr(dep) then
        -- ===== unit_modifiers.#N (§4.9.1 CSubunitBonusPersistent; 头三叶内联 + 修饰值) =====
        -- 容器 {d@dep+8, c@dep+20} 112B 条; type u32@E+64 经 TYPE_TOK 映射,
        -- id tok@E+68 (357=哨兵), number u32@E+72; DUM reader 同容器同序
        -- → 按 k 对齐 mods
        local dum = c:deployment_unit_modifiers()
        local dU, cU = rp(dep + 8), ru32(dep + 20) or 0
        if SL.kptr(dU) and cU > 0 and cU < GAME.layout.lim.PTR_SANE then
            local TYPE_TOK = { [1] = 10022, [2] = 89, [3] = 16775,
                [4] = 16778, [5] = 16770, [6] = 16771 }
            for k = 0, cU - 1 do
                local E = dU + 112 * k
                local B = P .. "unit_modifiers.#" .. (k + 1) .. "."
                local tv = ru32(E + 64) or 0
                emit(tag, B .. "type",
                    tostring(SL.tok(TYPE_TOK[tv] or 357)))
                emit(tag, B .. "number", SL.num(ru32(E + 72) or 0))
                local idt = ru32(E + 68) or 357
                if idt ~= 357 then
                    emit(tag, B .. "id", tostring(SL.tok(idt)))
                end
                local rec = dum and dum.list and dum.list[k + 1]
                for _, mv in ipairs(rec and rec.mods or {}) do
                    emit(tag,
                        B .. tostring(mv.target) .. "."
                        .. tostring(mv.name),
                        SL.num(mv.value))
                end
                -- 嵌套块 (§4.9.1 USSubUnitStats @类别对象+64; battalion_mult/
                -- 地形块/动态地形/need_equipment 池 = 书 §4.9.1 表)
                local function emit_terrain(tb, tnm, CB2)
                    local av, dv, mv2 = sfx(tb + 16), sfx(tb + 24),
                        sfx(tb + 32)
                    if av ~= 0 or dv ~= 0 or mv2 ~= 0 then
                        local TK = CB2 .. tnm .. "."
                        if av ~= 0 then
                            emit(tag, TK .. "attack", SL.num(av)) end
                        if dv ~= 0 then
                            emit(tag, TK .. "defence", SL.num(dv)) end
                        if mv2 ~= 0 then
                            emit(tag, TK .. "movement", SL.num(mv2)) end
                    end
                end
                local function walk_nested(cobj, cat)
                    if not (kptr(cobj) and cat) then return end
                    local sb = cobj + 64
                    local CB2 = B .. cat .. "."
                    local bmd, bmc = rp(sb + 72), ru32(sb + 84)
                    if kptr(bmd) and bmc and bmc > 0 and bmc < GAME.layout.lim.PTR_SANE then
                        local bmseq = SL.seqc()
                        for j = 0, bmc - 1 do
                            local el = bmd + 48 * j
                            local BK = CB2 .. bmseq("battalion_mult") .. "."
                            local cdef = rp(el + 8)
                            if kptr(cdef) then
                                local cn = GAME.layout.token_name(
                                    ru32(cdef + 84) or 0)
                                if cn and cn ~= "" then
                                    emit(tag, BK .. "category", cn) end
                            end
                            emit(tag, BK .. "add",
                                SL.yn(ru8(el + 40) or 0))
                            emit(tag, BK .. "display_as_percentage",
                                SL.yn(ru8(el + 41) or 0))
                            local sd2, sc2 = rp(el + 16), ru32(el + 28)
                            if kptr(sd2) and sc2 and sc2 > 0
                                and sc2 < 96 then
                                for m = 0, sc2 - 1 do
                                    local raw = sfx(sd2 + 16 * m + 8)
                                    if raw ~= 0 then
                                        local stok = STAT2TOK[
                                            ru32(sd2 + 16 * m) or -1]
                                        local snm = stok and
                                            GAME.layout.token_name(stok)
                                        if snm and snm ~= "" then
                                            emit(tag, BK .. snm,
                                                SL.num(raw))
                                        end
                                    end
                                end
                            end
                        end
                    end
                    for _, tb in ipairs({ { 752, "night" },
                        { 792, "fort" }, { 832, "river" },
                        { 872, "amphibious" }, { 912, "snow" } }) do
                        emit_terrain(sb + tb[1], tb[2], CB2)
                    end
                    local td, tc = rp(sb + 952), ru32(sb + 964)
                    if kptr(td) and tc and tc > 0 and tc < GAME.layout.lim.PTR_SANE then
                        for j = 0, tc - 1 do
                            local el = td + 40 * j
                            local tnm = GAME.layout.token_name(
                                ru32(el + 8) or 0)
                            if tnm and tnm ~= "" then
                                emit_terrain(el, tnm, CB2)
                            end
                        end
                    end
                    -- need_equipment (§4.9.1; 池/元素/键名/写门/+720 陷阱 = 书)
                    local ned, nec = rp(sb + 728), ru32(sb + 740)
                    if kptr(ned) and nec and nec > 0
                        and nec < GAME.layout.lim.PTR_SANE then
                        for j = 0, nec - 1 do
                            local el = ned + 16 * j
                            local amt = sfx(el + 8)
                            if amt ~= 0 then
                                local ar = rp(el)
                                if kptr(ar) then
                                    local enm = GAME.layout.token_name(
                                        ru32(ar + 8) or 0)
                                    if enm and enm ~= "" then
                                        emit(tag, CB2 .. "need_equipment."
                                            .. tostring(enm), SL.num(amt))
                                    end
                                end
                            end
                        end
                    end
                end
                -- 列表1 {d@E+16, c@E+28} 8B 指针 (类别 token@p+8)
                local q1d, q1c = rp(E + 16), ru32(E + 28)
                if kptr(q1d) and q1c and q1c > 0 and q1c < GAME.layout.lim.PTR_SANE then
                    for i = 0, q1c - 1 do
                        local p = rp(q1d + 8 * i)
                        if kptr(p) then
                            walk_nested(p, GAME.layout.token_name(
                                ru32(p + 8) or 0))
                        end
                    end
                end
                -- 列表2 {d@E+40, c@E+52} 16B {def*, obj*} (token@def+84)
                local q2d, q2c = rp(E + 40), ru32(E + 52)
                if kptr(q2d) and q2c and q2c > 0 and q2c < GAME.layout.lim.PTR_SANE then
                    for i = 0, q2c - 1 do
                        local def = rp(q2d + 16 * i)
                        local ob = rp(q2d + 16 * i + 8)
                        if kptr(def) and kptr(ob) then
                            walk_nested(ob, GAME.layout.token_name(
                                ru32(def + 84) or 0))
                        end
                    end
                end
            end
        end
        -- ===== §4.9 CDeployment initial_carrier_air_wing_deployment (ICAW) =====
        -- 内嵌 @dep+240 {d@+8, c@+20}, 16B 条 {名对象 ptr, i64×1e-5};
        -- 空壳门 = ru32(o+0)==0 且 ru32(o+8)==0 (legacy 原样)
        local o = dep + 240
        if not (ru32(o) == 0 and ru32(o + 8) == 0) then
            local dI, cI = rp(o + 8), ru32(o + 20) or 0
            if SL.kptr(dI) and cI > 0 and cI < 4096 then
                for k = 0, cI - 1 do
                    local ent = dI + 16 * k
                    local def = rp(ent)
                    if SL.kptr(def) then
                        local nm = SL.tok(ru32(def + 8) or 0)
                        emit(tag,
                            P .. "initial_carrier_air_wing_deployment."
                            .. tostring(nm),
                            SL.num((rp(ent + 8) or 0) / 100000))
                    end
                end
            end
        end
    end

    -- ===== §4.9.2 conveyor/line 全链 military_deployment_conveyor[N] =====
    local dcx = c:deployment_conveyors()
    local cseq = SL.seqc()
    for _, cv in ipairs(dcx and dcx.list or {}) do
        local CK = P .. cseq("military_deployment_conveyor") .. "."
        emit(tag, CK .. "id", SL.idpair(cv.id, cv.id_type))
        if cv.template_id then
            emit(tag, CK .. "division_template_id",
                SL.idpair(cv.template_id, cv.template_type))
        end
        local nm = SL.Q(cv.name)
        if nm then emit(tag, CK .. "name", nm) end
        emit(tag, CK .. "amount", SL.num(cv.amount or 0))
        emit(tag, CK .. "location", SL.num(cv.location or 0))
        emit(tag, CK .. "priority", SL.num(cv.priority or 0))
        if cv.order_index and cv.order_index ~= 0 then
            emit(tag, CK .. "order_index", SL.num(cv.order_index))
        end
        if cv.role and cv.role ~= 0 then
            emit(tag, CK .. "role", tostring(SL.tok(cv.role)))
        end
        emit(tag, CK .. "closed", cv.closed or "no")
        -- government_in_exile_tag tid@e+152 >0 才写 (ENG
        -- cv[0] tid=5=FRA 实证)
        if cv.giex_tid and cv.giex_tid > 0 then
            local ttab = ctx.gs and rp(ctx.gs + 0x358) or nil
            local gt = ttab and kptr(ttab) and cv.giex_tid < 4096
                and SL.sso(ttab + 32 * cv.giex_tid) or nil
            if gt and gt ~= "" then
                emit(tag, CK .. "government_in_exile_tag",
                    SL.Q(gt)) end
        end
        local lseq = SL.seqc()
        for lvi, lv in ipairs(cv.lines or {}) do
            local LK = CK .. lseq("military_deployment_line") .. "."
            emit(tag, LK .. "id", SL.idpair(lv.id, lv.id_type))
            emit(tag, LK .. "division_name.type",
                SL.num(lv.dn_type or 0))
            -- division_name (布局/写门 = 书 §4.9.2); dn = *(line+32)
            if (lv.dn_order or 0) ~= 0 then
                emit(tag, LK .. "division_name.name_order",
                    SL.num(lv.dn_order))
            end
            do
                local ld2 = cv.addr and rp(cv.addr + 120) or nil
                local L2 = kptr(ld2) and rp(ld2 + 8 * (lvi - 1)) or nil
                local dn = kptr(L2) and rp(L2 + 32) or nil
                if kptr(dn) then
                    -- R: is_name_ordered (writer 0x1409BCC70)
                    -- b@dn+168 ==0 才写, 值恒 0 → "no" (≠0 不写)
                    if (ru8(dn + 168) or 0) == 0 then
                        emit(tag, LK .. "division_name.is_name_ordered",
                            "no")
                    end
                    if (rp(dn + 152) or 0) ~= 0 then
                        local ov = SL.sso(dn + 136)
                        if ov and ov ~= "" then
                            emit(tag, LK .. "division_name.override",
                                '"' .. ov .. '"')
                        end
                    end
                    if (ru8(dn + 169) or 0) ~= 0 then
                        emit(tag, LK ..
                            "division_name.override_set_programmatically",
                            "yes")
                    end
                end
            end
            emit(tag, LK .. "amount", SL.num(lv.amount or 0))
            local MK = LK .. "military_deployment."
            if lv.training and lv.training ~= 0 then
                emit(tag, MK .. "training", SL.num(lv.training))
            end
            if lv.max_training and lv.max_training ~= 0 then
                emit(tag, MK .. "max_training", SL.num(lv.max_training))
            end
            if lv.mpv_value then
                emit(tag, MK .. "army_manpower_value.value",
                    string.format('tag="%s" value=%d',
                        tostring(lv.mpv_tag), lv.mpv_value))
            end
            if lv.mpn_value then
                emit(tag, MK .. "army_manpower_need.value",
                    string.format('tag="%s" value=%d',
                        tostring(lv.mpn_tag), lv.mpn_value))
            end
            -- equipment 块门 = 池非空 (writer 0x140FFB8F0)
            if lv.equipment and #lv.equipment > 0 then
                local eseq = SL.seqc()
                for _, ev in ipairs(lv.equipment) do
                    -- 元素门 (池 writer 0x140FFDB00): amount(raw i64)≠0 或
                    -- allow_zero≠0 才发射; eseq 必须在门内 (编号只对发射
                    -- 条目递增, 否则整段编号移位 → id/amount 全错位)
                    if (ev.amount or 0) ~= 0 or lv.allow_zero == "yes" then
                        local EK = MK .. "equipment."
                            .. eseq("equipment") .. "."
                        emit(tag, EK .. "id", SL.idpair(ev.id, ev.type))
                        emit(tag, EK .. "amount", SL.num(ev.amount))
                    end
                end
                emit(tag, MK .. "equipment.allow_zero_entries",
                    lv.allow_zero or "no")
            end
            emit(tag, MK .. "max_manpower",
                SL.num(lv.max_manpower or 0))
            -- halting_reason (门 byte@M+172 ≠0; writer 0x1414246F0 0x382E;
            -- OLE conveyor[2] 1 例实证)
            if lv.halting_reason then
                emit(tag, MK .. "halting_reason",
                    SL.num(lv.halting_reason))
            end
        end
    end
end }
