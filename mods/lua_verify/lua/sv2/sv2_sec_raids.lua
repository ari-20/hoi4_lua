-- sv2_sec_raids.lua -- raids 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "raids", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local DIM = "raids"
    local function E(path, val)
        if val ~= nil then emit(DIM, path, val) end
    end
    local function s32(v)               -- u32 哨兵 0xFFFFFFFF → -1
        if v == nil then return nil end
        if v == 0xFFFFFFFF then return -1 end
        return v
    end
    -- raids_sys 内联链 (targets/countries 两段共用; 必须先声明)
    -- §4.27 CRaidSystem — raids_sys = *(gs+0x3F0) (= gs+1008)
    local gs = ctx.gs
    local raids_sys = (gs and SL.kptr(gs)) and rp(gs + 0x3F0) or nil
    -- ===== targets (reader §31.3) — §4.27.1 目标管理器 (@CRaidSystem+8) =====
    -- mgr 内联链 = 段内重推 (reader 不给元素地址); 布局 = 书
    local rt = O:raid_targets()
    if rt then
        E("targets.next_state", tostring(s32(rt.next_state)))
        E("targets.existing_target_num", tostring(s32(rt.existing_target_num)))
        E("targets.detectable_target_num",
            tostring(s32(rt.detectable_target_num)))
        E("targets.next_target", tostring(s32(rt.next_target)))
        for ti, t in ipairs(rt.targets or {}) do
            local key = ti == 1 and "targets.target"
                or ("targets.target[" .. ti .. "]")
            E(key .. ".existing_target_num", tostring(s32(t.existing)))
            E(key .. ".detectable_target_num", tostring(s32(t.detectable)))
            E(key .. ".valid", SL.yn(t.valid))
            E(key .. ".dynamic", SL.yn(t.dynamic))
            -- leader / leader_province (§4.27.1 SRaidTarget; 内联 mgr 链:
            -- mgr = raids_sys+8 内联子对象 — 非指针解引用)
            local mgr2 = (raids_sys and SL.kptr(raids_sys))
                and (raids_sys + 8) or nil
            local tarr2 = (mgr2 and SL.kptr(mgr2)) and rp(mgr2) or nil
            local tcnt2 = mgr2 and ru32(mgr2 + 12) or 0
            local taddr = (tarr2 and SL.kptr(tarr2) and ti <= (tcnt2 or 0))
                and rp(tarr2 + 8 * (ti - 1)) or nil
            if SL.kptr(taddr) then
                local lty, lid = ru32(taddr + 8 + 24), ru32(taddr + 8 + 28)
                if (lty or 0) ~= 0 or (lid or 0) ~= 0 then
                    E(key .. ".target.leader", SL.idpair(lid, lty))
                end
                local lp2 = rp(taddr + 8 + 32)
                if SL.kptr(lp2) then
                    E(key .. ".target.leader_province",
                        tostring(ru32(lp2 + 164) or 0))
                end
            end
            if t.state and t.state >= 0 then
                E(key .. ".target.state", tostring(t.state)) end
            if t.province and t.province >= 0 then
                E(key .. ".target.province", tostring(t.province)) end
            if t.bld_template then
                E(key .. ".target.building.template", tostring(t.bld_template))
            end
            if t.bld_location then
                E(key .. ".target.building.location", tostring(t.bld_location))
            end
            if t.detected and #t.detected > 0 then
                local parts = {}
                for _, b in ipairs(t.detected) do
                    parts[#parts + 1] = tostring(b) end
                E(key .. ".detected", table.concat(parts, " "))
            end
        end
    end

    -- ===== countries (reader §31.4) — §4.27.1 CCountryRaidStatus =====
    -- 国家条目地址内联推算链 (end_date 用): ⚠ reader raid_country_entries 的
    -- rec 无 addr 字段 (31.2 raid_countries 才有) — 残尾根因;
    -- 条目 = *(*(gs+0x3F0)+0xD8) + 0xB0*rec.index
    local cd = (raids_sys and SL.kptr(raids_sys)) and rp(raids_sys + 0xD8)
        or nil
    local rc = O:raid_country_entries()
    if rc then
        for _, rec in ipairs(rc) do
            local P = "countries.#" .. (rec.index + 1)
            if rec.tag then E(P .. ".tag", SL.Q(rec.tag)) end
            E(P .. ".priority", tostring(rec.priority or 0))
            if rec.dummy_id then
                E(P .. ".dummy.id", SL.idpair(rec.dummy_id, rec.dummy_type))
            end
            -- 实例指针数组内联 (end_date 需 inst 地址; reader 未暴露)
            local ce = (cd and SL.kptr(cd)) and (cd + 0xB0 * rec.index)
                or nil
            local id2 = ce and rp(ce + 24) or nil
            for ki, ir in ipairs(rec.instances or {}) do
                local IP = P .. ".raid_instance.#" .. ki
                E(IP .. ".id", SL.idpair(ir.id, ir.type_id))
                if ir.prep_time and ir.prep_time ~= 0 then
                    E(IP .. ".prep_time", tostring(ir.prep_time)) end
                if ir.nr_days and ir.nr_days ~= 0 then
                    E(IP .. ".nr_days_launchable", tostring(ir.nr_days)) end
                if ir.distance and ir.distance ~= 0 then
                    E(IP .. ".distance", SL.num(ir.distance)) end
                if ir.phase and ir.phase ~= "NONE" and ir.phase ~= "?" then
                    E(IP .. ".phase", SL.Q(ir.phase)) end
                if ir.outcome and ir.outcome ~= "NONE" and ir.outcome ~= "?" then
                    E(IP .. ".outcome", SL.Q(ir.outcome)) end
                if ir.type_name then E(IP .. ".type", SL.Q(ir.type_name)) end
                -- 实例裸址 (id2 链; §4.27.1 CCountryRaidStatus +24
                -- 实例指针数组)
                local inst = SL.kptr(id2) and rp(id2 + 8 * (ki - 1)) or nil
                if SL.kptr(inst) then
                    -- unit.air_wing (§4.27.1 CRaidInstance +200 双
                    -- id 对; writer 0x141454E80 系: {type@+208,
                    -- id@+212}, 非零才写)
                    local awt, awi = ru32(inst + 208), ru32(inst + 212)
                    if (awt or 0) ~= 0 or (awi or 0) ~= 0 then
                        E(IP .. ".unit.air_wing", SL.idpair(awi, awt))
                    end
                    -- target.leader / leader_province (§4.27.1 SRaidTarget:
                    -- 0x140FD2A70: idpair
                    -- {type@+184, id@+188}, 省 ptr@+192 → id@+164)
                    local lty, lid = ru32(inst + 184), ru32(inst + 188)
                    if (lty or 0) ~= 0 or (lid or 0) ~= 0 then
                        E(IP .. ".target.leader", SL.idpair(lid, lty))
                    end
                    local lp = rp(inst + 192)
                    if SL.kptr(lp) then
                        E(IP .. ".target.leader_province",
                            tostring(ru32(lp + 164) or 0))
                    end
                    -- raid_source.province (§4.27.1 raid_source @inst+216;
                    -- 省 ptr@rs+8 → id@+164; writer 0x141581E30)
                    local rsp = rp(inst + 224)
                    if SL.kptr(rsp) then
                        E(IP .. ".raid_source.province",
                            tostring(ru32(rsp + 164) or 0))
                    end
                    -- raid_source.ship (§4.27.1 raid_source 块+16
                    -- 内联 id 对, 非零才写)
                    if ir.src_ship then
                        E(IP .. ".raid_source.ship", ir.src_ship)
                    end
                end
                local tb = ir.target_building
                if tb then
                    if tb.template then
                        E(IP .. ".target.building.template",
                            tostring(tb.template)) end
                    if tb.location then
                        E(IP .. ".target.building.location",
                            tostring(tb.location)) end
                end
                if ir.target_province then
                    E(IP .. ".target.province", tostring(ir.target_province))
                end
                if ir.target_state then  -- target.state (§4.27.1 SRaidTarget: state ptr@+176→+88)
                    E(IP .. ".target.state", tostring(ir.target_state))
                end
                if ir.unit_army_id then
                    E(IP .. ".unit.army",
                        SL.idpair(ir.unit_army_id, ir.unit_army_type)) end
                if ir.src_type then
                    E(IP .. ".raid_source.type", tostring(ir.src_type)) end
                if ir.src_tag then
                    E(IP .. ".raid_source.tag", SL.Q(ir.src_tag)) end
                -- raid_source.building 有效性门 (§4.27.1 raid_source
                -- 块+32 building {location@+40, template@+44})
                local bvalid = true
                if SL.kptr(inst) then
                    local btok = ru32(inst + 216 + 44) or 19479
                    local bloc = ru32(inst + 216 + 40) or 0xFFFFFFFF
                    local b3 = ru32(inst + 216 + 48) or 0
                    b3 = GAME.layout.as_i32(b3)
                    bvalid = btok ~= 19479
                        and (bloc ~= 0xFFFFFFFF or b3 > 0)
                end
                local sb = bvalid and ir.src_building or nil
                if sb then
                    if sb.template then
                        E(IP .. ".raid_source.building.template",
                            tostring(sb.template)) end
                    if sb.location then
                        E(IP .. ".raid_source.building.location",
                            tostring(sb.location)) end
                end
                -- show_for 标签列 (§4.27.1 CRaidInstance +440; 布局/门 =
                -- 书) — 提取器半匿名续行怪癖: 首标签在 show_for={ 行,
                -- #2+ 走 @.#(j-1)
                if SL.kptr(inst) then
                    local sfc = ru32(inst + 452)
                    local sfd = rp(inst + 440)
                    if sfc and sfc > 0 and sfc < 440 and SL.kptr(sfd) then
                        local parts = {}
                        for j = 0, sfc - 1 do
                            local t = O:tag(ru32(sfd + 4 * j) or 0)
                            if not t then parts = nil break end
                            parts[#parts + 1] = '"' .. t .. '"'
                        end
                        if parts then
                            E(IP .. ".show_for",
                                "show_for={ " .. parts[1])
                            for j = 2, #parts do
                                E(IP .. ".@.#" .. (j - 1), parts[j])
                            end
                        end
                    end
                end
                if ir.detected and ir.detected ~= 0 then
                    E(IP .. ".detected", "yes") end
                -- end_date 段内内联 (§4.27.1 CRaidInstance):
                -- writer 0x140FDA710 — if (b@inst+432) write date
                -- @inst+424 (vt2 = ADEC0 代理基)。
                if SL.kptr(id2) then
                    local inst = rp(id2 + 8 * (ki - 1))
                    if SL.kptr(inst) and (ru8(inst + 432) or 0) ~= 0 then
                        -- 内嵌 CGameDate {vt@+408, hours u32@+416},
                        -- 门 bool u8@+432 (§4.27.1 CRaidInstance)
                        local d = SL.date(ru32(inst + 416))
                        if d then
                            E(IP .. ".end_date", '"' .. d .. '"') end
                    end
                end
                if ir.victim then
                    E(IP .. ".victim_country", SL.Q(ir.victim)) end
            end
            -- target_cooldowns (§4.27.1 CCountryRaidStatus +72; 容器/元素
            -- 布局/门 = 书)
            if SL.kptr(ce) then
                local td2, tc2 = rp(ce + 72), ru32(ce + 84)
                if SL.kptr(td2) and tc2 and tc2 > 0 and tc2 < 4096 then
                    for j = 0, tc2 - 1 do
                        local el = td2 + 64 * j
                        local TP = P .. ".target_cooldowns.#" .. (j + 1)
                        local bld = rp(el + 16)
                        if SL.kptr(bld) then
                            local tpo = rp(bld + 0x1E0)
                            local tt = SL.kptr(tpo) and ru32(tpo + 8) or nil
                            if tt then
                                E(TP .. ".target.building.template",
                                    tostring(SL.tok(tt))) end
                            local sto = rp(bld + 0x1D8)
                            if SL.kptr(sto) then
                                E(TP .. ".target.building.location",
                                    tostring(ru32(sto + 108) or 0)) end
                        end
                        local pv = rp(el + 24)
                        if SL.kptr(pv) then
                            E(TP .. ".target.province",
                                tostring(ru32(pv + 164) or 0)) end
                        local st = rp(el + 32)
                        if SL.kptr(st) then
                            E(TP .. ".target.state",
                                tostring(ru32(st + 88) or 0)) end
                        local def = rp(el + 8)
                        if SL.kptr(def) then
                            local nm = SL.tok(ru32(def + 8))
                            if nm then
                                E(TP .. ".type",
                                    '"' .. tostring(nm) .. '"') end
                        end
                        E(TP .. ".cooldown", tostring(ru32(el + 56) or 0))
                    end
                end
            end
        end
    end
end }
