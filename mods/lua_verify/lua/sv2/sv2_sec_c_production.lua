-- sv2_sec_c_production.lua -- country.production 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.production", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
    local tok, kptr = SL.tok, SL.kptr

    -- §4.8 CProductionStatus
    local psr = c:production_scalars()
    local plr = c:production_lines()
    local ps = (psr and psr.addr) or (plr and plr.addr)
    if not ps then return end
    local pm = c:production_misc()

    -- 提取器 HEAD 键字符集 = [A-Za-z0-9_./:@-] (扩, savefull3.py
    -- HEAD) — 旧定案"连字符键落 '@' 哨兵"已废: 提取器现发真名
    -- (AST_vickers-ruwolt_organization), mem 侧须同构发真名。
    -- '@' 仅作 HEAD 外脏键回退 (提取器吞行分支同形)。
    local function ekey(s)
        if s and s:match("^[A-Za-z0-9_./:@-]+$") then return s end
        return "@"
    end

    -- fe Q15 打印 = double(raw/32768) 的 5 位**截断** (非 %.5f 四舍五入;
    -- 截断边界实例: raw=1462754 → save "44.63961" vs %.5f "44.63962")。
    -- raw*3125/1024 为二进制定点精确值, floor 无浮点边界误差。
    local function q15str(raw)
        local v = raw / 32768
        local neg = v < 0
        local q = math.floor(math.abs(v) * 100000)
        local ip, f5 = q // 100000, q % 100000
        return (neg and "-" or "") .. string.format("%d.%05d", ip, f5)
    end

    -- MSVC SSO 串 (§3.5; 同 objects_v2 U.sso 语义, 段内本地副本)
    local function sso(obj)
        if not obj then return nil end
        local size = ru32(obj + 16)
        if not size or size > 4096 then return nil end
        if size == 0 then return "" end
        -- 内联判据 = cap 而非 size (§3.5 MSVC SSO; 实例 size=15/cap=31 = 堆串)
        local cap = ru32(obj + 0x18)
        local buf = (cap and cap > 15) and rp(obj) or obj
        if not kptr(buf) then return nil end
        local t = {}
        for i = 0, size - 1 do
            t[#t + 1] = string.char((ru32(buf + i) or 0) & 0xFF)
        end
        return table.concat(t)
    end
    local function fix5(a) local v = rp(a); return v and v / 100000 or nil end

    -- ===== named_equipment_bonuses (#N 1 基 = 容器序) =====
    for bi, nb in ipairs(pm and pm.named_bonuses or {}) do
        local b = "production.named_equipment_bonuses.#" .. bi
        local nm = SL.Q(nb.name)
        if nm then emit(tag, b .. ".name", nm) end
        local pq = SL.Q(nb.prefix)
        if pq then emit(tag, b .. ".prefix", pq) end
        local tgt = nb.target
        if tgt and tgt ~= "" and tgt ~= "nil" then
            emit(tag, b .. "." .. tgt .. ".instant",
                nb.instant == "yes" and "yes" or "no")
            for _, mv in ipairs(nb.mods or {}) do
                emit(tag, b .. "." .. tgt .. "." .. tostring(mv.name),
                    SL.num(mv.value))
            end
        end
        emit(tag, b .. ".id", SL.num(nb.id or 0))
    end

    -- ===== available_equipments (id 对行, 多重集) =====
    -- §4.8 CProductionStatus
    do
        local aed, aec = rp(ps + 160), ru32(ps + 172)
        if kptr(aed) and aec and aec > 0 and aec < GAME.layout.lim.PTR_HUGE then
            for k = 0, aec - 1 do
                local v = rp(aed + 8 * k)
                if kptr(v) then
                    emit(tag, "production.available_equipments.equipment",
                        SL.idpair(ru32(v + 12), ru32(v + 8)))
                end
            end
        end
    end

    -- ===== 顶层标量 =====
    emit(tag, "production.dirty", psr and psr.dirty or "no")

    -- ===== foreign_lease_equipments =====
    for _, fv in ipairs(psr and psr.foreign_lease or {}) do
        emit(tag, "production.foreign_lease_equipments.equipment",
            SL.idpair(fv.id, fv.type))
    end

    -- ===== production_licenses (avail 先行, owned [N] 序 = 容器序) =====
    -- §4.8.10 CEquipmentProductionLicense
    do
        local oseq = SL.seqc()
        for _, lz in ipairs(pm and pm.licenses or {}) do
            if lz.avail_id ~= nil then
                emit(tag, "production.production_licenses.available",
                    SL.idpair(lz.avail_id, lz.avail_type))
            elseif lz.lended ~= nil then
                local b = "production.production_licenses."
                    .. oseq("owned_license")
                emit(tag, b .. ".lended_cic", SL.num(lz.lended))
                emit(tag, b .. ".required_cic", SL.num(lz.required))
                local ow, gv = SL.Q(lz.owner), SL.Q(lz.giver)
                if ow then emit(tag, b .. ".owner", ow) end
                if gv then emit(tag, b .. ".giver", gv) end
                local sd2 = SL.date(lz.start_h)
                if sd2 then emit(tag, b .. ".start_date", '"' .. sd2 .. '"') end
                if lz.parent and lz.parent ~= "nil" then
                    emit(tag, b .. ".parent", lz.parent)
                end
                for _, eqs in ipairs(lz.equipment or {}) do
                    emit(tag, b .. ".equipment", eqs)
                end
            end
        end
    end

    emit(tag, "production.cic_bank.value",
        SL.num(psr and psr.cic_bank_value or 0))

    -- ===== 生产线三族 (共容器, [N] 按族独立计数, 序 = 容器序) =====
    -- §4.8.1 生产线元素多态族
    local FAM = { [56] = "military_lines", [57] = "naval_lines",
        [71] = "ship_refit_lines", [75] = "railway_gun_lines" }
    local lseq = SL.seqc()
    for _, lr in ipairs(plr and plr.lines or {}) do
        local fam = FAM[lr.line_type]
        local e = lr.addr
        if fam and e then
            local p = "production." .. lseq(fam)
            emit(tag, p .. ".id", SL.idpair(lr.line_id, lr.line_type))
            if (rp(e + 56) or 0) ~= 0 then
                emit(tag, p .. ".produced", SL.num(lr.produced))
            end
            if (ru32(e + 24) or 0) ~= 0 then
                emit(tag, p .. ".active_factories",
                    SL.num(lr.active_factories))
            end
            if lr.damaged_factories then
                emit(tag, p .. ".damaged_factories",
                    SL.num(lr.damaged_factories))
            end
            emit(tag, p .. ".priority", SL.num(lr.priority))
            emit(tag, p .. ".amount", SL.num(lr.amount))
            if (rp(e + 48) or 0) ~= 0 then
                emit(tag, p .. ".speed", SL.num(lr.speed))
            end
            emit(tag, p .. ".cost", SL.num(lr.cost))
            if lr.queued_factories then
                emit(tag, p .. ".queued_factories",
                    SL.num(lr.queued_factories))
            end
            emit(tag, p .. ".requested_factories",
                SL.num(lr.requested_factories))
            if lr.variant_id then
                emit(tag, p .. ".equipment_variant_index",
                    SL.idpair(lr.variant_id, lr.variant_type))
            end
            -- factory_efficiencies: 单行 5 位截断空格串 (q15str, 保留尾零)
            if lr.fe_raw then
                local ft = {}
                for _, fv2 in ipairs(lr.fe_raw) do
                    ft[#ft + 1] = q15str(fv2)
                end
                emit(tag, p .. ".factory_efficiencies.#1",
                    table.concat(ft, " "))
            end
            for ri, rv in ipairs(lr.resources or {}) do
                local rb = p .. ".resources.#" .. ri
                emit(tag, rb .. ".resource", tostring(rv.resource))
                emit(tag, rb .. ".amount", SL.num(rv.amount))
                emit(tag, rb .. ".need", SL.num(rv.need))
            end
            -- 转换/界面族 (writer 0x1419260B0 尾; 本存档零行)
            if (ru8(e + 236) or 0) ~= 0 then
                emit(tag, p .. ".is_converting", "yes")
                emit(tag, p .. ".non_conversion_speed",
                    SL.num(fix5(e + 224)))
            end
            if (ru8(e + 237) or 0) ~= 0 then
                emit(tag, p .. ".collapsed_interface", "yes")
            end
            local ifs = ru32(e + 240) or 1
            if ifs ~= 1 then
                emit(tag, p .. ".interface_factory_scale", SL.num(ifs))
            end
            if lr.mfr_id then
                emit(tag, p .. ".industrial_manufacturer",
                    SL.idpair(lr.mfr_id, lr.mfr_type))
            end
            local d = lr.deployment
            if d then
                if d.tf_id then
                    emit(tag, p .. ".deployment.task_force",
                        SL.idpair(d.tf_id, d.tf_type))
                end
                if d.ship_id then
                    emit(tag, p .. ".deployment.ship",
                        SL.idpair(d.ship_id, d.ship_type))
                end
                if d.base ~= nil then
                    emit(tag, p .. ".deployment.base", SL.num(d.base))
                end
                for _, ov in ipairs(d.icaw or {}) do
                    if ov.name then
                        emit(tag, p .. ".deployment."
                            .. "initial_carrier_air_wing_deployment."
                            .. tostring(ov.name), SL.num(ov.value))
                    end
                end
            end
            for ni, nr in ipairs(lr.names or {}) do
                local nb = p .. ".names.#" .. ni
                emit(tag, nb .. ".type", SL.num(nr.type))
                if (nr.name_order or 0) ~= 0 then
                    emit(tag, nb .. ".name_order", SL.num(nr.name_order))
                end
                if nr.is_name_ordered == 0 then
                    emit(tag, nb .. ".is_name_ordered", "no")
                end
                local ovq = SL.Q(nr.override)
                if ovq then emit(tag, nb .. ".override", ovq) end
                if nr.override_set_prog == 1 then
                    emit(tag, nb .. ".override_set_programmatically", "yes")
                end
                if nr.eq_id then
                    emit(tag, nb .. ".equipment",
                        SL.idpair(nr.eq_id, nr.eq_type))
                end
            end
            if lr.original_eq_cost then
                emit(tag, p .. ".original_eq_cost",
                    SL.num(lr.original_eq_cost))
            end
        end
    end

    -- ===== general_lines (building / rail_way; [N] 按子族计数) =====
    -- §4.8.1 生产线元素多态族 (general 特化)
    local gseq = SL.seqc()
    for _, gr in ipairs(plr and plr.generals or {}) do
        local gf = gr.line_type == 59 and "building"
            or gr.line_type == 4713 and "rail_way"
            or gr.line_type == 76 and "railway_gun" or nil
        if gf then
            local p = "production.general_lines." .. gseq(gf)
            emit(tag, p .. ".id", SL.idpair(gr.line_id, gr.line_type))
            if gr.produced and gr.produced ~= 0 then
                emit(tag, p .. ".produced", SL.num(gr.produced))
            end
            -- damaged u32@+28 ≠0 (writer 0x1414A36A0 同款)
            if gr.damaged_factories and gr.damaged_factories ~= 0 then
                emit(tag, p .. ".damaged_factories",
                    SL.num(gr.damaged_factories))
            end
            if gr.active_factories and gr.active_factories ~= 0 then
                emit(tag, p .. ".active_factories",
                    SL.num(gr.active_factories))
            end
            emit(tag, p .. ".priority", SL.num(gr.priority))
            emit(tag, p .. ".amount", SL.num(gr.amount))
            if gr.speed and gr.speed ~= 0 then
                emit(tag, p .. ".speed", SL.num(gr.speed))
            end
            emit(tag, p .. ".cost", SL.num(gr.cost))
            if (gr.created_date_hours or 0) ~= 0 then
                local cd = SL.date(gr.created_date_hours)
                if cd then
                    emit(tag, p .. ".created_date", '"' .. cd .. '"')
                end
            end
            -- §4.8.5 CBuildingProductionLine
            if gf == "building" then
                if gr.building_template then
                    emit(tag, p .. ".building.template",
                        gr.building_template)
                end
                if gr.building_location then
                    emit(tag, p .. ".building.location",
                        SL.num(gr.building_location))
                end
                if gr.to_repair and gr.to_repair > 0 then
                    emit(tag, p .. ".to_repair", SL.num(gr.to_repair))
                end
                if gr.conversion == 1 then
                    emit(tag, p .. ".conversion", "yes")
                end
                if gr.rel_id then
                    emit(tag, p .. ".relative",
                        SL.idpair(gr.rel_id, gr.rel_type))
                end
                if gr.title == 1 then
                    emit(tag, p .. ".title", "yes")
                end
                emit(tag, p .. ".allied_build",
                    gr.allied_build == 1 and "yes" or "no")
            -- §4.8.6 CRailwayProductionLine
            elseif gf == "rail_way" then
                emit(tag, p .. ".base", SL.num(gr.rw_base))
                emit(tag, p .. ".target", SL.num(gr.rw_target))
                emit(tag, p .. ".current_province",
                    SL.num(gr.rw_current_province))
                emit(tag, p .. ".remaining_hours",
                    SL.num(gr.rw_remaining_hours))
                if gr.rw_path then
                    emit(tag, p .. ".rail_way.#1",
                        table.concat(gr.rw_path, " "))
                end
            -- §4.8.7 CRailwayGunRepairLine
            elseif gf == "railway_gun" then
                -- 产出的铁路炮 idpair {type@e+112, id@e+116} (任≠0 才写)
                if (gr.rg_type or 0) ~= 0 or (gr.rg_id or 0) ~= 0 then
                    emit(tag, p .. ".railway_gun",
                        SL.idpair(gr.rg_id, gr.rg_type))
                end
            end
        end
    end

    -- ===== equipments 池 + allow_zero_entries =====
    -- §4.8 CProductionStatus / §4.23.3 CEquipmentVariantPool
    if psr then
        emit(tag, "production.equipments.allow_zero_entries",
            psr.equip_allow_zero or "no")
        local eseq = SL.seqc()
        for _, ev in ipairs(psr.equip_pool or {}) do
            local b = "production.equipments." .. eseq("equipment")
            emit(tag, b .. ".id", SL.idpair(ev.id, ev.type))
            emit(tag, b .. ".amount", SL.num(ev.amount))
        end
    end

    -- ===== enable_equipment_modules (#N 裸 token) =====
    for mi2, mn in ipairs(pm and pm.enable_modules or {}) do
        emit(tag, "production.enable_equipment_modules.#" .. mi2, mn)
    end

    -- ===== industrial_organisations (键 = token@org+56; 匿名 @) =====
    -- '@' 父键不编号 (提取器深度哨兵无 [N]); 但其【内层块键】按同父出现
    -- 序编号: 第二个 @ org 的 allowed_policies/history/unlocked → [2]
    -- (标量叶不编号, 多重集)。blk 按 (父, 块名) 计数, 普通 org 父唯一
    -- 恒一现不受影响。
    local mseq = SL.seqc()
    local blkcnt = {}
    local function blk(parent, name)
        local k = parent .. "" .. name
        local n = (blkcnt[k] or 0) + 1
        blkcnt[k] = n
        return n == 1 and name or (name .. "[" .. n .. "]")
    end
    -- ⚠ 迁移临时内联 (objects_v2 修 CC_VT2 后可回收此块换回 c:mio):
    -- 1.19.3 国家 vt 搬家致共享层 c:mio 恒 nil → 全部国家
    -- industrial_organisations 整树 MISS, 此处绕开国家 vt 门直走 pm
    -- 容器, 字段解析 = MIOrgMT 同构 (offsets/门逐项照抄)。
    -- §4.8.12 NIndustrialOrganisation::COrganisation
    local miovt = ctx.BASE + GAME.layout.vt.COrganisation
    local tnm = GAME.layout and GAME.layout.token_name
    local function mfix5(p) local q = rp(p); return q and q * 1e-5 or nil end
    local function mio_list(cc)
        if not cc then return nil end
        local pmc = rp(cc + 0xF68)
        if not kptr(pmc) then return nil end
        local d, n = rp(pmc + 0x130), ru32(pmc + 0x13C)
        if not kptr(d) or not n or n <= 0 or n >= 65536 then return nil end
        local out = {}
        for i = 0, n - 1 do
            local a = rp(d + 8 * i)
            if kptr(a) and rp(a) == miovt then
                local rec = { addr = a,
                    org_type = ru32(a + 0x08), org_id = ru32(a + 0x0C),
                    name = sso(a + 0x60), icon = sso(a + 0x80),
                    research_bonus = mfix5(a + 0xA0),
                    task_capacity = ru32(a + 0xA8),
                    funds = mfix5(a + 0x128),
                    size = ru32(a + 0x130), points = ru32(a + 0x134),
                    upgrades = (ru8(a + 0x138) or 0) == 1 and 1 or 0,
                    research_assign_cost = mfix5(a + 176),
                    production_assign_cost = mfix5(a + 184),
                    design_team_change_cost = ru32(a + 192),
                    add_mio_funds_gain_factor = mfix5(a + 200) }
                -- allowed_policies {d@+368, c@+380} u32 token (c<=256 门)
                do
                    local ap = {}
                    local apd, apc = rp(a + 368), ru32(a + 380)
                    if kptr(apd) and apc and apc > 0 and apc <= 256 then
                        for k = 0, apc - 1 do
                            local tk = ru32(apd + 4 * k)
                            ap[#ap + 1] = (tk and tnm and tnm(tk))
                                or (tk and "?" .. tostring(tk)) or nil
                        end
                    end
                    rec.allowed_policies = ap
                end
                -- unlocked traits (RB 中序 @+320, trait token@node+40)
                do
                    local ut = {}
                    local head = rp(a + 320)
                    local node = head and rp(head)
                    local guard = 0
                    while node and (ru8(node + 25) or 0) == 0
                        and guard < 512 do
                        guard = guard + 1
                        local tk = ru32(node + 40)
                        ut[#ut + 1] = tk and tnm and tnm(tk) or nil
                        local r = rp(node + 16)
                        if r and (ru8(r + 25) or 0) == 0 then
                            node = r
                            while node do
                                local l = rp(node)
                                if l and (ru8(l + 25) or 0) == 0 then
                                    node = l
                                else
                                    break
                                end
                            end
                        else
                            while true do
                                local p = rp(node + 8)
                                if not p or (ru8(p + 25) or 0) ~= 0 then
                                    node = nil
                                    break
                                end
                                -- ⚠ 先比较旧 node (来自左子才继续上溯),
                                -- 再上移 (MIOrgMT 原语义)
                                local pr = rp(p + 16)
                                local from_left = (pr == node)
                                node = p
                                if not from_left then break end
                            end
                        end
                    end
                    rec.unlocked_traits = ut
                end
                -- history (RH 表 @+248 桶 64B; date 门 flag b@+0x30 +
                -- 43800000..300000000 纪元窗)
                do
                    local his = {}
                    local hbase = a + 248
                    local ent = rp(hbase)
                    local mask = ru32(hbase + 12) or 0
                    local extra = ru8(hbase + 16) or 0
                    if kptr(ent) then
                        local nb = mask + 1 + extra
                        if nb > 1024 then nb = 1024 end
                        for idx2 = 0, nb - 1 do
                            local b = ent + 64 * idx2
                            local d4 = ru8(b + 4) or 0
                            if d4 ~= 0 and d4 ~= 0xFE then
                                local dflag = ru8(b + 0x30) or 0
                                local dh = 0
                                if dflag ~= 0 then
                                    dh = ru32(b + 0x20) or 0
                                    if dh < 43800000 or dh > 300000000 then
                                        dh = 0
                                    end
                                end
                                his[#his + 1] = {
                                    eq_type = ru32(b + 8) or 0,
                                    eq_id = ru32(b + 12) or 0,
                                    date_h = dh,
                                    units = ru32(b + 0x38) or 0 }
                            end
                        end
                    end
                    rec.history = his
                end
                out[#out + 1] = rec
            end
        end
        return out
    end
    for _, mo in ipairs(mio_list(ctx.cc) or {}) do
        local a = mo.addr
        if a then
            local key0 = ekey(tok(ru32(a + 56)))
            local b = "production.industrial_organisations."
                .. (key0 == "@" and "@" or mseq(key0))
            emit(tag, b .. ".id", SL.idpair(mo.org_id, mo.org_type))
            emit(tag, b .. ".name", '"' .. (mo.name or "") .. '"')
            emit(tag, b .. ".icon", '"' .. (mo.icon or "") .. '"')
            emit(tag, b .. ".research_bonus", SL.num(mo.research_bonus))
            emit(tag, b .. ".task_capacity", SL.num(mo.task_capacity))
            emit(tag, b .. ".funds", SL.num(mo.funds))
            emit(tag, b .. ".size", SL.num(mo.size))
            emit(tag, b .. ".points", SL.num(mo.points))
            emit(tag, b .. ".upgrades", mo.upgrades == 1 and "yes" or "no")
            local apkey = blk(b, "allowed_policies")
            for pi, pol in ipairs(mo.allowed_policies or {}) do
                emit(tag, b .. "." .. apkey .. ".#" .. pi, pol)
            end
            emit(tag, b .. ".research_assign_cost",
                SL.num(mo.research_assign_cost))
            emit(tag, b .. ".production_assign_cost",
                SL.num(mo.production_assign_cost))
            emit(tag, b .. ".design_team_change_cost",
                SL.num(mo.design_team_change_cost))
            emit(tag, b .. ".add_mio_funds_gain_factor",
                SL.num(mo.add_mio_funds_gain_factor))
            -- policy (u32@+392 ≠ 19479 undefined 才写, 裸 token)
            local pol2 = ru32(a + 392)
            if pol2 and pol2 ~= 19479 then
                local pnm = tok(pol2)
                if pnm then emit(tag, b .. ".policy", pnm) end
            end
            -- §4.8.11 COrganisation 附属块 (cooldown/history/variables/flags;
            -- 门/偏移 = 书) — 提取器对 cooldown={ "date" } 行内块收裸叶,
            -- 值含引号
            do
                local cb = a and ru8(a + 424) or 0
                if cb and cb ~= 0 then
                    local ch = ru32(a + 408)
                    local cds = ch and SL.date(ch)
                    if cds then
                        emit(tag, b .. ".cooldown", '"' .. cds .. '"') end
                end
            end
            -- unlocked traits (RB 中序 = 写序; 引号)
            for _, tn in ipairs(mo.unlocked_traits or {}) do
                emit(tag, b .. "." .. blk(b, "unlocked") .. ".trait",
                    '"' .. tostring(tn) .. '"')
            end
            -- history (RH 桶序 = 写序)
            for _, hr in ipairs(mo.history or {}) do
                local hb = b .. "." .. blk(b, "history")
                emit(tag, hb .. ".equipment",
                    SL.idpair(hr.eq_id, hr.eq_type))
                if (hr.date_h or 0) ~= 0 then
                    local hd = SL.date(hr.date_h)
                    if hd then
                        emit(tag, hb .. ".data.date", '"' .. hd .. '"')
                    end
                end
                do  -- units i32 有符号
                    local uv = hr.units or 0
                    uv = GAME.layout.as_i32(uv)
                    emit(tag, hb .. ".data.units", SL.num(uv))
                end
            end
            -- variables@org+448 / flags@org+504 — §4.25.1 CVariables /
            -- §4.8.11 CFlagStore (附属块; 布局/门 = 书)
            do
                local vo = a + 448
                local vr8 = ru32(vo + 8)
                if vr8 and vr8 ~= 1 then
                    emit(tag, b .. ".variables.random", string.format(
                        "%d %d", ru32(vo + 12) or 0, vr8))
                end
                local vlist = {}
                -- ⚠ mask=0 (空表) 必须跳桶走查: rh_iter 的 count 兜底分支会
                -- 误读 +0x10 → 扫静态哨兵桶出垃圾名
                local vmask = ru32(vo + 0x24)
                local vb = nil
                if vmask and vmask > 0 and vmask <= GAME.layout.lim.PTR_HUGE then
                    vb = GAME.layout.rh_iter(vo, { data = 0x18,
                        mask = 0x24, stride = 0x30,
                        maxn = GAME.layout.lim.PTR_HUGE })
                end
                for _, bk in ipairs(vb or {}) do
                    local vdist = ru32(bk + 4)
                    if vdist and (vdist & 0xFF) ~= 0
                        and (vdist & 0xFF) ~= 0xFE
                        and (vdist & 0xFF) ~= 0xFF then
                        local vnm = sso(bk + 8)
                        local vraw = SL.rp_i64(bk + 0x28)
                        if vnm and vraw then
                            vlist[#vlist + 1] = vnm .. "|"
                                .. SL.num(vraw * 1e-5)
                        end
                    end
                end
                table.sort(vlist) -- 键字节序 (writer 先收集排序)
                local vseq = 0
                for _, kv in ipairs(vlist) do
                    local vnm2, vval = kv:match("^(.-)|(.*)$")
                    if vnm2 then
                        if vnm2:find("%^num$") then
                            vseq = vseq + 1
                            emit(tag, b .. ".variables.#" .. vseq,
                                vnm2 .. "=" .. vval)
                        else
                            emit(tag, b .. ".variables." .. vnm2, vval)
                        end
                    end
                end
                local fd, fc = rp(a + 504 + 8), ru32(a + 504 + 0x14)
                if kptr(fd) and fc and fc > 0 and fc < GAME.layout.lim.PTR_HUGE then
                    for fi = 0, fc - 1 do
                        local fe = fd + 0x30 * fi
                        local fk = ru32(fe + 8)
                        local fnm = fk and fk <= (hoi4.read_u32(hoi4.base() + GAME.layout.rva.lexer_token_max) or 100000) and tok(fk)
                        if fnm and fnm ~= "" then
                            local fkp = b .. ".flags."
                                .. tostring(fnm) .. "."
                            local fpack = ru32(fe + 0x28) or 0
                            local fv = fpack & 0xFFFF
                            fv = GAME.layout.as_i16(fv)
                            emit(tag, fkp .. "value", tostring(fv))
                            local fdh = ru32(fe + 0x18)
                            if fdh and fdh > 0 then
                                local fds = SL.date(fdh)
                                if fds then
                                    emit(tag, fkp .. "date",
                                        '"' .. fds .. '"')
                                end
                            end
                            local fex = (fpack >> 16) & 0x7FFF
                            if fex > 0 then
                                emit(tag, fkp .. "days", tostring(fex))
                            end
                        end
                    end
                end
            end
        end
    end

    -- ===== policies (cost/cooldown 恒写; 内联 — writer sub_140A3D110
    -- cost u32@el+72 / cooldown u32@el+76, 键 token@el+8; reader
    -- objects_v2 Country.policies 的 cost@+48 偏移有误, 勿用) =====
    -- §4.8 CProductionStatus
    do
        local pcd, pcc = rp(ps + 328), ru32(ps + 340)
        if kptr(pcd) and pcc and pcc > 0 and pcc < 4096 then
            for k = 0, pcc - 1 do
                local el = rp(pcd + 8 * k)
                if kptr(el) then
                    local pnm = tok(ru32(el + 8))
                    if pnm then
                        local b = "production.policies." .. pnm
                        emit(tag, b .. ".cost", SL.num(ru32(el + 72)))
                        emit(tag, b .. ".cooldown", SL.num(ru32(el + 76)))
                    end
                end
            end
        end
    end

    -- ===== scheduled_equipment_variants (内联; writer 0x1414517C0) =====
    -- §4.8 CProductionStatus (CCreateEquipmentVariantScheduler 容器)
    do
        -- count = int@sch+20 = ps+620 (池 writer 0x1419ED330 /
        -- clear sub_1401C10D0 / 空门 sub_140CCDC10 三重证据);
        -- 旧 ps+616 = capacity → 残留槽幻影 (, 见段头)
        local sdd, sdc = rp(ps + 608), ru32(ps + 620)
        if kptr(sdd) and sdc and sdc > 0 and sdc < GAME.layout.lim.PTR_SANE then
            local vseq = SL.seqc()
            for k = 0, sdc - 1 do
                local e = sdd + 16 * k
                local arch, var = rp(e), rp(e + 8)
                if kptr(arch) and kptr(var) then
                    -- §4.23.1 CEquipmentVariant (var+ 字段族)
                    local key0 = ekey(tok(ru32(arch + 8)))
                    if key0 then
                        local b = "production.scheduled_equipment_variants."
                            .. vseq(key0)
                        if (rp(var + 32) or 0) ~= 0 then
                            local nm = sso(var + 16)
                            if nm and nm ~= "" then
                                emit(tag, b .. ".name", '"' .. nm .. '"')
                            end
                        end
                        if (rp(var + 64) or 0) ~= 0 then
                            local ng = sso(var + 48)
                            if ng and ng ~= "" then
                                emit(tag, b .. ".name_group",
                                    '"' .. ng .. '"')
                            end
                        end
                        if (ru8(var + 85) or 0) == 0 then
                            emit(tag, b .. ".show_position", "no")
                        end
                        local pv = ru32(var + 80) or 0
                        if pv ~= 0 then
                            emit(tag, b .. ".parent_version", SL.num(pv))
                        end
                        if (ru8(var + 84) or 0) ~= 0 then
                            emit(tag, b .. ".obsolete", "yes")
                        end
                        if (ru8(var + 86) or 0) ~= 0 then
                            emit(tag, b .. ".mark_older_equipment_obsolete",
                                "yes")
                        end
                        if (rp(var + 160) or 0) ~= 0 then
                            local md2 = sso(var + 144)
                            if md2 and md2 ~= "" then
                                emit(tag, b .. ".model", '"' .. md2 .. '"')
                            end
                        end
                        if (ru8(var + 176) or 0) ~= 0
                            and (ru32(var + 180) or 9) <= 1 then
                            local ic = sso(var + 184)
                            if ic and ic ~= "" then
                                emit(tag, b .. ".icon", '"' .. ic .. '"')
                            end
                        end
                        local rii = ru32(var + 88) or 0
                        if rii ~= (ru32(var + 8) or 0) then
                            emit(tag, b .. ".role_icon_index", SL.num(rii))
                        end
                        -- upgrades {d@96,c@108} 16B {def@0, lvl u8@8}
                        local ud, un = rp(var + 96), ru32(var + 108)
                        if kptr(ud) and un and un > 0 and un < GAME.layout.lim.PTR_SANE then
                            for i = 0, un - 1 do
                                local ue = ud + 16 * i
                                local def = rp(ue)
                                if kptr(def) and (ru8(def + 16) or 0) ~= 0
                                then
                                    local unm = tok(ru32(def + 8))
                                    if unm then
                                        emit(tag, b .. ".upgrades." .. unm,
                                            SL.num(ru8(ue + 8) or 0))
                                    end
                                end
                            end
                        end
                        -- modules {d@120,c@132} 16B {slot tok@0, moddef@8}
                        local md3, mn3 = rp(var + 120), ru32(var + 132)
                        if kptr(md3) and mn3 and mn3 > 0 and mn3 < GAME.layout.lim.PTR_SANE then
                            for i = 0, mn3 - 1 do
                                local me = md3 + 16 * i
                                local mo2 = rp(me + 8)
                                if kptr(mo2) then
                                    local slot = tok(ru32(me))
                                    local val
                                    if (ru8(mo2 + 16) or 0) ~= 0 then
                                        val = tok(ru32(mo2 + 8))
                                    else
                                        val = "empty"
                                    end
                                    if slot and val then
                                        emit(tag, b .. ".modules." .. slot,
                                            val)
                                    end
                                end
                            end
                        end
                        local io_t, io_i = ru32(var + 248) or 0,
                            ru32(var + 252) or 0
                        if io_t ~= 0 or io_i ~= 0 then
                            emit(tag, b .. ".industrial_organisation",
                                SL.idpair(io_i, io_t))
                        end
                    end
                end
            end
        end
    end

    -- ===== max_factories_for_repair (恒写) =====
    emit(tag, "production.max_factories_for_repair",
        SL.num(psr and psr.max_factories_for_repair or 0))

    -- ===== discount (#N 1 基; types #M 裸 token) =====
    for di2, dc2 in ipairs(pm and pm.discounts or {}) do
        local b = "production.discount.#" .. di2
        emit(tag, b .. ".uses", SL.num(dc2.uses))
        emit(tag, b .. ".discount", SL.num(dc2.discount))
        for ti2, tn2 in ipairs(dc2.types or {}) do
            emit(tag, b .. ".types.#" .. ti2, tn2)
        end
    end

    -- ===== energy_production_cost (块门 b@*(*(ps+1264))+16) =====
    -- §4.8 CProductionStatus
    do
        local ep = rp(ps + 1264)
        if kptr(ep) and (ru8(ep + 16) or 0) ~= 0 and psr then
            if psr.energy_resource then
                emit(tag, "production.energy_production_cost.resource",
                    psr.energy_resource)
            end
            emit(tag, "production.energy_production_cost.amount",
                SL.num(psr.energy_amount))
            emit(tag, "production.energy_production_cost.need",
                SL.num(psr.energy_need))
        end
    end

    -- ===== last_named_equipment_bonus (i32 恒写, 可 -1) =====
    emit(tag, "production.last_named_equipment_bonus",
        SL.num(psr and psr.last_named_equipment_bonus or 0))
end }
