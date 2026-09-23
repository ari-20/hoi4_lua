-- sv2_sec_c_strategic_navy.lua -- country.strategic_navy 节点 savefull 直出
-- (含 navy_theater.theater_group 族 — secmapping 同节点)
-- 规格源: hoi4_secmapping.py 'country.strategic_navy' 6 条
-- reader: objects_v2 §33.8 Country.navy_theaters + §33.12 Country.navy
-- (bases/dockyards/naval_accidents/per_region_access/escort_history);
-- RCG/NTT 等 S 五族 已上提 reader Country.navy (段侧只留写门/格式/序)
-- 公共链 (§4.16.1 CStrategicNavyManager → §4.16.5 CStrategicNavy):
-- M = rp(gs+0x698) → arr = rp(M+8), n = ru32(M+20) → S = rp(arr+8*idx)
-- 布局/写门/键序 = 书 §4.16.5-§4.16.11 (regional_convoys 非默认谓词门、
-- 哨兵 43817520 段内须显式门等书已收)。
-- navy_theater.theater_group[N]: id/name 恒写, fleet 裸键多重集;
-- N = 容器序 (首现不编号)
-- 提取器契约 = 书 §4.16.5/§4.16.8 (regional_convoys 容量行吞键 /
-- ships_in_repair 编号 / per_region_danger 全 0 不发射)
local rp, ru32 = hoi4.read_u64, hoi4.read_u32

SV2.csec[#SV2.csec + 1] = { name = "country.strategic_navy",
    emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local BASE, gs, ci = ctx.BASE, ctx.gs, ctx.i

    -- ============ §4.24.11 CNavyTheater navy_theater.theater_group ============
    local okth, nth = pcall(function() return c:navy_theaters() end)
    if okth and nth then
        local seq = SL.seqc()
        for _, rec in ipairs(nth.list or {}) do
            local b = "navy_theater." .. seq("theater_group")
            emit(tag, b .. ".id", rec.id_pair)
            local q = SL.Q(rec.name)
            if q then emit(tag, b .. ".name", q) end
            for _, fl in ipairs(rec.fleets or {}) do
                emit(tag, b .. ".fleet", fl)
            end
        end
    end

    -- ============ §4.16.5 CStrategicNavy strategic_navy 主族 (reader Country.navy) ============
    local okn, nv = pcall(function() return c:navy() end)
    -- S 对象五族已上提 reader Country.navy
    -- regional_convoys/per_region_mines/per_region_danger/
    -- homebase_observers/naval_transports — 段侧只留写门/格式/序

    local RCG_DATE_SENTINEL = 43817520
    local rcg = okn and nv and nv.regional_convoys or nil
    if rcg then
        local nrc = 0
        for _, el in ipairs(rcg.list) do
            local rc = el.required_convoys
            local eff = el.efficiency_raw
            eff = GAME.layout.as_i64(eff)
            local dh = el.date_h or RCG_DATE_SENTINEL
            if rc ~= 0 or eff ~= 100000 or dh ~= RCG_DATE_SENTINEL then
                nrc = nrc + 1
                local b = "strategic_navy.regional_convoys.#" .. nrc
                emit(tag, b .. ".index", SL.num(el.index))
                local parts = {}
                if rc ~= 0 then
                    parts[#parts + 1] = "required_convoys=" .. rc end
                if eff ~= 100000 then
                    parts[#parts + 1] = "efficiency="
                        .. SL.num(eff / 100000)
                end
                if dh ~= RCG_DATE_SENTINEL then
                    local ds = SL.date(dh)
                    if ds then
                        parts[#parts + 1] = 'last_sunk_convoy_date="'
                            .. ds .. '"'
                    end
                end
                emit(tag, b .. ".data", table.concat(parts, " "))
            end
        end
        if nrc == 0 then
            emit(tag, "strategic_navy.regional_convoys.#1",
                SL.num(rcg.capacity))
        end
    end

    if okn and nv then
        -- §4.16.9 CNavalAccidentReport naval_accident (N 通常仅 1)
        local seqa = SL.seqc()
        for _, na in ipairs(nv.naval_accidents or {}) do
            local b = "strategic_navy." .. seqa("naval_accident")
            emit(tag, b .. ".region", SL.num(na.region))
            emit(tag, b .. ".equipment", SL.idpair(na.eq_id, na.eq_type))
            emit(tag, b .. ".ship", SL.idpair(na.ship_id, na.ship_type))
            emit(tag, b .. ".country", SL.Q(tag))
            local d = SL.date(na.date_h)
            if d then emit(tag, b .. ".to_discard_date", SL.Q(d)) end
        end
        -- §4.16.8 CNavalBase naval_base.<prov>.{priority, ships_in_repair.#N}
        -- (priority=1 默认不写 / ships_in_repair: 元素 writer
        -- 0x140E9CFF0, 容器 {d@E+40, c@E+52} 8B 内联 {type@0, id@+4},
        -- c>0 才开块, B240 匿名块 `{ id=N type=T }` → #N 恒编号)
        for _, bs in ipairs((nv.bases or {}).list or {}) do
            if bs.province and bs.addr then
                local p = bs.priority or 1
                if p ~= 1 then
                    emit(tag, "strategic_navy.naval_base." .. bs.province
                        .. ".priority", SL.num(p))
                end
                -- 容器上提 reader (ships_in_repair_list)
                for k, sr in ipairs(bs.ships_in_repair_list or {}) do
                    emit(tag, "strategic_navy.naval_base."
                        .. bs.province .. ".ships_in_repair.#" .. k,
                        SL.idpair(sr.id, sr.type))
                end
            end
        end
        -- §4.16.5 CStrategicNavy dockyards 恒写 (LUX 0/0 实证)
        if nv.dockyards then
            emit(tag, "strategic_navy.max_allowed_dockyards_to_repair",
                SL.num(nv.dockyards.max_allowed or 0))
            emit(tag, "strategic_navy.num_used_dockyards",
                SL.num(nv.dockyards.used or 0))
        end
        -- §4.16.5 per_region_access.#1 "idx val ..." (reader "idx=val" 转换)
        local pra = nv.per_region_access or {}
        if #pra > 0 then
            local t = {}
            for _, kv in ipairs(pra) do
                local kk, vv = tostring(kv):match("^(%d+)=(%d+)$")
                if kk then t[#t + 1] = kk; t[#t + 1] = vv end
            end
            if #t > 0 then
                emit(tag, "strategic_navy.per_region_access.#1",
                    table.concat(t, " "))
            end
        end
        -- §4.16.11 convoy_escort_presence_history.<region>.#1 位串
        for _, eh in ipairs(nv.escort_history or {}) do
            local reg, bits = tostring(eh):match("^(%d+):(.*)$")
            if reg and bits and bits ~= "" then
                emit(tag, "strategic_navy.convoy_escort_presence_history."
                    .. reg .. ".#1", bits)
            end
        end
    end

    -- ============ §4.16.7 CNavalUnitTransfer naval_transport 等 S 五族
    -- (NTT; 布局上提 reader Country.navy — 段侧只留写门/格式) ============
    if okn and nv then
        -- §4.16.5 per_region_mines (0x3942): 仅 >0 写 "idx val" 对单行
        do
            local t = {}
            for k, v in ipairs(nv.per_region_mines or {}) do
                v = GAME.layout.as_i64(v)
                if v > 0 then
                    t[#t + 1] = tostring(k - 1) .. " " .. SL.num(v * 1e-5)
                end
            end
            if #t > 0 then
                emit(tag, "strategic_navy.per_region_mines.#1",
                    table.concat(t, " "))
            end
        end
        -- §4.16.5 per_region_danger (0x3CE4): 仅 val>0 写 "idx val" 对
        do
            local t = {}
            for k, v in ipairs(nv.per_region_danger or {}) do
                if v > 0 then
                    t[#t + 1] = tostring(k - 1) .. " " .. tostring(v)
                end
            end
            if #t > 0 then
                emit(tag, "strategic_navy.per_region_danger.#1",
                    table.concat(t, " "))
            end
        end
        -- §4.16.5 homebase_observers (0x4E04): 逐元匿名块 → #N "prov count"
        for k, ho in ipairs(nv.homebase_observers or {}) do
            emit(tag, "strategic_navy.homebase_observers.#" .. k,
                tostring(ho.province) .. " " .. tostring(ho.count))
        end
        -- §4.16.7 CNavalUnitTransfer naval_transport (块 token 0x330A 定案;
        -- 0x3371 旧记作废): 写门/序全段层 (writer 0x140E14640 系)
        local tt = rp(gs + 0x358) -- §1.2 gs+856 tag 串表
        local seqt = SL.seqc()
        for _, T in ipairs(nv.naval_transports or {}) do
            local b = "strategic_navy." .. seqt("naval_transport")
            if T.has_id then
                emit(tag, b .. ".id", SL.idpair(T.id_id, T.id_type))
            end
            emit(tag, b .. ".target_provinces", SL.num(T.target_provinces))
            emit(tag, b .. ".province", SL.num(T.province))
            if T.country_tid ~= 0 and SL.kptr(tt) then
                local q = SL.Q(hoi4.read_str(tt + 32 * T.country_tid))
                if q then emit(tag, b .. ".country", q) end
            end
            if T.path then
                local pp = {}
                for _, pv in ipairs(T.path) do
                    pp[#pp + 1] = tostring(pv) end
                emit(tag, b .. ".path.#1", table.concat(pp, " "))
            end
            emit(tag, b .. ".convoys.convoys", SL.num(T.convoys))
            emit(tag, b .. ".convoys.total", SL.num(T.convoys_total))
            -- invasion_group ≠0 → yes (仅真写; writer 0x140E14640 L55-57)
            if T.invasion_group then
                emit(tag, b .. ".invasion_group", "yes")
            end
            for _, u in ipairs(T.units or {}) do
                if u.type ~= 0 or u.id ~= 0 then
                    emit(tag, b .. ".unit", SL.idpair(u.id, u.type))
                end
            end
            -- combat (0x2916): 逐元匿名 id 对块 → #N
            for q4, cb in ipairs(T.combats or {}) do
                emit(tag, b .. ".combat.#" .. q4,
                    SL.idpair(cb.id, cb.type))
            end
            -- cooldown (0x391E): >0 才写
            if T.cooldown > 0 then
                emit(tag, b .. ".cooldown", SL.num(T.cooldown))
            end
        end
    end
end }
