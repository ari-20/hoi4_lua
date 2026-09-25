-- sv2_sec_states.lua -- states 节点 savefull 直出 (主写)

SV2.gsec[#SV2.gsec + 1] = { name = "states", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32 = SL.rp, SL.ru32
    local gs, BASE = ctx.gs, ctx.BASE
    -- §4.13 CState — 州库条目数 = u32@gs+0x2D4 (states writer 循环
    -- i∈[1,0x2D4)); gs+0x2BC = 省数 (16885) 非州数 — 旧 vt 反扫在大
    -- mod 会越界读到邻接数组内存误判 sid_max
    local sid_max = 0
    local smax = gs and ru32(gs + 0x2D4) or 0
    if smax > 1 and smax < 100000 then sid_max = smax - 1 end
    if sid_max == 0 then return end
    local function numf(v) return SL.num(v) end
    for sid = 1, sid_max do
        local ok2, st = pcall(function() return O:state(sid) end)
        local oks, sf = pcall(function() return O:state_fields(sid) end)
        if ok2 and st then
            local p = sid .. "."
            local function E(path, val) emit("states", p .. path, val) end
            local function Q(s) return SL.Q(s) end
            -- buildings (state_buildings: level/healthy_levels u16 拆,
            -- partial ×1e-5) — §4.14.2 CBuilding (州侧容器同构)
            local okb, bld = pcall(function() return O:state_buildings(sid) end)
            if okb and bld and bld.list then
                for _, b in ipairs(bld.list) do
                    local bp = "buildings." .. tostring(b.type) .. "."
                    E(bp .. "level", tostring(b.level or 0))
                    E(bp .. "partial_health", numf((b.partial_health or 0) / 1e5))
                    E(bp .. "healthy_levels", tostring(b.healthy_levels or 0))
                    -- repair_speed_factor : 州=省同 writer
                    -- 0x1410DCCA0, i64 fixed5 @元素+80, 门 raw≠100000
                    -- (发射形态镜像 provinces 侧)
                    if b.repair_speed_factor and b.repair_speed_factor ~= 1 then
                        E(bp .. "repair_speed_factor",
                            SL.num(b.repair_speed_factor))
                    end
                end
            end
            -- owner/controller/manpower — §4.13 CState
            local s = Q(st.owner) if s then E("owner", s) end
            if st.controller and st.controller ~= "" and st.controller ~= st.owner then
                E("controller", '"' .. st.controller .. '"')
            end
            -- 全零池引擎整块不写, 三叶恒全 — §4.13 CState (CStateManpower)
            if (st.manpower_available or 0) ~= 0 or (st.manpower_locked or 0) ~= 0
                or (st.manpower_total or 0) ~= 0 then
                E("manpower_pool.available", tostring(st.manpower_available or 0))
                E("manpower_pool.locked", tostring(st.manpower_locked or 0))
                E("manpower_pool.total", tostring(st.manpower_total or 0))
            end
            -- resources (raw 读) — §4.13.6 CStrategicResourcePool
            -- (布局/两级落盘门 = 书); 计数须用 +460 count — cap@+456
            -- 尾部有脏槽; 资源名过滤复用 reader 惰性集 O._res_ok。
            local okx, ex = pcall(function() return O:state_extras(sid) end)
            if okx and ex then
                local sa2 = st.addr
                local rd2 = sa2 and rp(sa2 + 448)
                local rc2 = sa2 and ru32(sa2 + 460)
                if rd2 and SL.kptr(rd2) and rc2 and rc2 > 0 and rc2 < GAME.layout.lim.PTR_SANE then
                    local RESOK = O._res_ok
                    -- 条目门 (两遍扫描): **块级** = 至少一个正值条目才整块写
                    -- (writer 0x1409D4040 skip-scan); **条目级** = 块写后
                    -- signed ≠0 全发, 含负 food。i64 负数须有符号还原。
                    local ent, haspos = {}, false
                    for i = 0, rc2 - 1 do
                        local raw = rp(rd2 + 16 * i)
                        local sv = raw
                        sv = GAME.layout.as_i64(raw)
                        ent[i] = { v = sv, k = ru32(rd2 + 16 * i + 8) }
                        if sv and sv > 0 then haspos = true end
                    end
                    if haspos then
                        for i = 0, rc2 - 1 do
                            local e = ent[i]
                            if e.v and e.v ~= 0 and e.k then
                                local nm = GAME.layout.token_name(e.k)
                                if nm and RESOK and RESOK[nm] then
                                    E("resources." .. nm, numf(e.v / 1e5))
                                end
                            end
                        end
                    end
                end
            end
            -- flags — §4.13.3 CFlagManager (value 恒写; date = +0x18 绝对小时)
            local st_addr = st.addr
            -- name (§4.13 CState: MSVC 串 @+56, size@+72 ≠0 才写)
            if sf and sf.name then E("name", '"' .. sf.name .. '"') end
            -- contested_owners/previous_owner (槽序稀疏表保洞; 门 <440)
            if sf and sf.contested then
                for ci = 1, sf.contested_n do
                    local t = sf.contested[ci]
                    if t then
                        E("contested_owners.#" .. ci, '"' .. t .. '"') end
                end
            end
            if sf and sf.previous then
                for pi = 1, sf.previous_n do
                    local t = sf.previous[pi]
                    if t then
                        E("previous_owner.#" .. pi, '"' .. t .. '"') end
                end
            end
            -- state modifier 块 (§4.13 +1736 内嵌 CModifier; reader
            -- sf.modifier = base pairs + added children)
            do
                local mo = sf and sf.modifier
                if mo then
                    local function emit_pairs(pre, lst)
                        for _, pv in ipairs(lst or {}) do
                            E(pre .. pv.name, numf(pv.value)) end
                    end
                    emit_pairs("modifier.", mo.base)
                    local cseq = 0  -- 重复块第 2 起编 [N] (提取器契约)
                    for _, a in ipairs(mo.added or {}) do
                        cseq = cseq + 1
                        local abase = "modifier.added_modifier"
                            .. (cseq > 1 and ("[" .. cseq .. "]") or "")
                            .. "."
                        if a.data then E(abase .. "data", tostring(a.data)) end
                        if a.name then
                            E(abase .. "name", '"' .. a.name .. '"') end
                        emit_pairs(abase, a.pairs)
                    end
                end
            end
            -- flags (reader sf.flags; date = 绝对小时; days = 高半 >0)
            for _, fg in ipairs((sf and sf.flags) or {}) do
                E("flags." .. fg.name .. ".value", tostring(fg.value))
                if fg.date_h then
                    local ds = SL.date(fg.date_h)
                    if ds then
                        E("flags." .. fg.name .. ".date", '"' .. ds .. '"') end
                end
                if fg.days then
                    E("flags." .. fg.name .. ".days", tostring(fg.days)) end
            end
            -- 恒写三键 + 类别 + 槽 — §4.13 CState
            E("demilitarized", SL.yn(st.demilitarized))
            E("is_border_conflict", SL.yn(st.is_border_conflict))
            if st.state_category then E("state_category", tostring(st.state_category)) end
            if (st.extra_shared_slots or 0) > 0 then
                E("extra_shared_slots", tostring(st.extra_shared_slots))
            end
            -- variables — §4.13.2 CVariables (random 写序反 + 字母序键)
            do
                if sf and sf.vars_random then
                    E("variables.random", string.format("%d %d",
                        sf.vars_random[1], sf.vars_random[2])) end
                local vlist = {}
                for _, kv in ipairs(st.variables or {}) do
                    vlist[#vlist + 1] = kv
                end
                table.sort(vlist)
                local vseq = 0
                for _, kv in ipairs(vlist) do
                    local nm, val = kv:match("^(.-)|(.+)$")
                    if nm then
                        if nm:find("%^num$") then
                            vseq = vseq + 1
                            E("variables.#" .. vseq, nm .. "=" .. numf(tonumber(val)))
                        else
                            E("variables." .. nm, numf(tonumber(val)))
                        end
                    end
                end
            end
            -- resistance 块 (占领州) — §4.13.1 CResistance (内嵌 st+616)
            do
                local has_r = st.occupied_country_tag ~= nil
                local rf = { "resistance", "resistance_speed", "resistance_target",
                    "base_resistance_target", "compliance", "compliance_speed" }
                if not has_r then
                    for _, k in ipairs(rf) do
                        if (st[k] or 0) ~= 0 then has_r = true break end
                    end
                end
                if has_r then
                    for _, k in ipairs(rf) do
                        if (st[k] or 0) ~= 0 then
                            E("resistance." .. k, numf(st[k]))
                        end
                    end
                    s = Q(st.occupied_country_tag)
                    if s then E("resistance.occupied_country_tag", s) end
                    if st.operational_status == 1 then -- bool_true_only (207/207 yes)
                        E("resistance.operational_status", "yes")
                    end
                    local rseq = 0
                    for _, nm in ipairs(st.resistance_modifiers or {}) do
                        if nm and nm ~= "" then
                            rseq = rseq + 1
                            E("resistance.resistance_modifiers.#" .. rseq,
                                '"' .. nm .. '"')
                        end
                    end
                    -- compliance_modifiers.#N (§4.13.1 CResistance+112
                    -- {d,c@+124} 同 resistance_modifiers 走法)
                    local cseq = 0
                    for _, nm in ipairs(st.compliance_modifiers or {}) do
                        if nm and nm ~= "" then
                            cseq = cseq + 1
                            E("resistance.compliance_modifiers.#" .. cseq,
                                '"' .. nm .. '"')
                        end
                    end
                end
                -- added_resistance_targets (§4.13.1 CResistance @st+616;
                -- 布局/条目子表/写门 = 书) — 门 = 容器非空, 与占领数值
                -- 无关, 故本 do 块移出 has_r
                do
                    local art = sf and sf.added_rt
                    for ai, at in ipairs(art or {}) do
                        local ap = "resistance.added_resistance_targets.#"
                            .. ai .. "."
                        if at.id then E(ap .. "id", tostring(at.id)) end
                        E(ap .. "amount", numf(at.amount))
                        if at.days then E(ap .. "days", tostring(at.days)) end
                        if at.controller then
                            E(ap .. "controller", '"' .. at.controller .. '"') end
                        if at.occupied then
                            E(ap .. "occupied", '"' .. at.occupied .. '"') end
                        if at.tooltip then
                            E(ap .. "tooltip", '"' .. at.tooltip .. '"') end
                    end
                end
                -- force_disable_resistance.<keytag> (§4.13.1; 元素/门/
                -- tid0 渲染 = 书) — 契约对齐: 原生档裸键 "---=DEI" 被提取
                -- 器自然解析为 键=keytag 值=valtag (旧 #N 合并形态已失效)
                local function tg3(t)
                    if not t or t == 0 then return "---" end
                    return tostring(O:tag(t) or t)
                end
                for _, fv in ipairs(st.force_disable or {}) do
                    E("resistance.force_disable_resistance." .. tg3(fv[1]),
                        tg3(fv[2]))
                end
                -- force_enable_resistance.<keytag> = <valtag>: {d@rz+624,
                -- c@rz+636} 同构 8B 对 (writer 0x140F87B70 0x4AA2=19106
                -- 块, 键 tag 命名块)。
                -- tid=0 条目合法, 去 fv[1]>0 门
                for _, fv in ipairs(st.force_enable or {}) do
                    E("resistance.force_enable_resistance." .. tg3(fv[1]),
                        tg3(fv[2]))
                end
            end
            -- dynamic_modifier (容器序 [N]) — §4.13.4 SDynamicModifierEntry
            do
                local seq = SL.seqc()
                for _, dm in ipairs(st.dynamic_modifiers or {}) do
                    local nm, en, tg, days, vals, mst = dm:match(
                        "^(.-)|(.-)|(.-)|(.-)|(.-)|(.*)$")
                    if nm and nm ~= "" and nm ~= "nil" then
                        local kp = "dynamic_modifier." .. seq("modifier") .. "."
                        E(kp .. "modifier", '"' .. nm .. '"')
                        -- .state = 条目自带州 id u32@entry+12, >0 才写
                        -- (writer sub_140605C80 ADFE0 0x1B7; §4.13.4)
                        local mstn = tonumber(mst)
                        if mstn and mstn > 0 then
                            E(kp .. "state", tostring(mstn))
                        end
                        E(kp .. "enabled", SL.yn(tonumber(en)))
                        s = Q(tg) if s then E(kp .. "tag", s) end
                        local dnum = tonumber(days)
                        if dnum and dnum >= 0 and dnum < 0xFFFFFFFF then
                            E(kp .. "days", tostring(dnum))
                        end
                        if vals and vals ~= "" then
                            local toks = {}
                            for tk in vals:gmatch("[^,]+") do
                                toks[#toks + 1] = SL.num(tonumber(tk) or 0)
                            end
                            E(kp .. "value.#1", table.concat(toks, " "))
                        end
                    end
                end
            end
            -- active_targeted_modifier — §4.13.5 (RH 表 st+2280);
            -- atm: pairs; added: pairs 值, name/data 记 B
            if okx and ex then
                for _, at in ipairs(ex.atm or {}) do
                    local tg = at.tag and O:tag(at.tag)
                    if tg then
                        -- bare pairs (reader at.xpairs; modifier_token 直解)
                        for _, pv in ipairs(at.xpairs or {}) do
                            E("active_targeted_modifier."
                                .. tg .. "." .. pv.name, numf(pv.value)) end
                        -- added_modifier (reader at.xadded; data/name/pairs)
                        local aseq = SL.seqc()
                        for _, a in ipairs(at.xadded or {}) do
                            local kp = "active_targeted_modifier." .. tg
                                .. "." .. aseq("added_modifier") .. "."
                            if a.data then E(kp .. "data", tostring(a.data)) end
                            if a.name then
                                E(kp .. "name", '"' .. a.name .. '"') end
                            for _, pv in ipairs(a.pairs or {}) do
                                E(kp .. pv.name, numf(pv.value)) end
                        end
                    end
                end
            end
            -- strategic_region_data (#N "token value")
            do
                local sseq = 0
                for _, sr in ipairs(st.strategic_region_data or {}) do
                    local nm, val = sr:match("^(.-)|(.+)$")
                    if nm and nm ~= "nil" then
                        sseq = sseq + 1
                        E("strategic_region_data.#" .. sseq,
                            nm .. " " .. tostring(val))
                    end
                end
            end
            -- last_strategic_bombing — §4.13 CState (+2184 CGameDate 内嵌)
            if okx and ex and ex.last_bombing_hours then
                local ds = SL.date(ex.last_bombing_hours)
                if ds then E("last_strategic_bombing", '"' .. ds .. '"') end
            end
        end
    end
end }
