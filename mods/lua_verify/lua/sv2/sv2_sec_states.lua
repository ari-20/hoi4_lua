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
            -- name (§4.13 CState: writer 0x140xxx L53: MSVC 串 @+56,
            -- size u32@+72 ≠0 才写, 引号)
            if st_addr and (ru32(st_addr + 72) or 0) ~= 0 then
                local snm = SL.sso(st_addr + 56)
                if snm and snm ~= "" then E("name", '"' .. snm .. '"') end
            end
            -- contested_owners (§4.13 CState: writer L187-198: gate count
            -- u32@+220 ≠0; data@+208, 4B 国 idx → 引号 tag;
            -- 叶 contested_owners.#K)
            do
                local cod, coc = st_addr and rp(st_addr + 208),
                    st_addr and ru32(st_addr + 220) or nil
                if SL.kptr(cod) and coc and coc > 0 and coc < 440 then
                    for ci = 0, coc - 1 do
                        local t = O:tag(ru32(cod + 4 * ci) or 0)
                        if t then
                            E("contested_owners.#" .. (ci + 1),
                                '"' .. t .. '"')
                        end
                    end
                end
            end
            -- previous_owner (§4.13 CState: writer 0x1409D4040 L239-263,
            -- gate count@+276 ≠0; {d@+264} 4B tag → 引号;
            -- 叶 previous_owner.#K)
            do
                local pod, poc = st_addr and rp(st_addr + 264),
                    st_addr and ru32(st_addr + 276) or nil
                if SL.kptr(pod) and poc and poc > 0 and poc < 440 then
                    for pi = 0, poc - 1 do
                        local t = O:tag(ru32(pod + 4 * pi) or 0)
                        if t then
                            E("previous_owner.#" .. (pi + 1),
                                '"' .. t .. '"')
                        end
                    end
                end
            end
            -- state modifier 块 (§4.13 CState +1736 内嵌 CModifier, writer
            -- 0x140605B00; base pairs 直发 + children → added_modifier)
            do
                local mo = st_addr
                local function emit_pairs(pre, pd, pc)
                    if not (SL.kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_SANE) then
                        return 0 end
                    local n = 0
                    for qi = 0, pc - 1 do
                        local di = ru32(pd + 16 * qi)
                        if not di or di == 0 then break end
                        local raw = SL.rp_i64(pd + 16 * qi + 8)
                        local mn = GAME.layout.modifier_token(di)
                        if mn and raw then
                            local v = raw
                            v = GAME.layout.as_i64(v)
                            E(pre .. mn, numf(v * 1e-5))
                            n = n + 1
                        end
                    end
                    return n
                end
                if SL.kptr(mo) then
                    local md = rp(mo + 1752)
                    local mc = ru32(mo + 1764)
                    local cd, cc = rp(mo + 1776), ru32(mo + 1788)
                    if (mc and mc > 0) or (cc and cc > 0) then
                        emit_pairs("modifier.", md, mc)
                        -- writer 无计数门 (见文件头), 防御界统一 PTR_SANE
                        -- — 旧 cc<16 防御界过紧 (children 计数可 >16)
                        if SL.kptr(cd) and cc and cc > 0
                            and cc < GAME.layout.lim.PTR_SANE then
                            local cseq = 0  -- 重复块第 2 起编 [N] (提取器契约)
                            for cj = 0, cc - 1 do
                                local aobj = rp(cd + 8 * cj)
                                if SL.kptr(aobj) then
                                    cseq = cseq + 1
                                    local abase = "modifier.added_modifier"
                                        .. (cseq > 1
                                            and ("[" .. cseq .. "]") or "")
                                        .. "."
                                    local dv = ru32(aobj + 188)
                                    if dv and dv ~= 1 then
                                        E(abase .. "data", tostring(dv))
                                    end
                                    local snm = SL.sso(aobj + 88)
                                    if snm and snm ~= "" then
                                        E(abase .. "name", '"' .. snm .. '"')
                                    end
                                    emit_pairs(abase,
                                        rp(aobj + 16), ru32(aobj + 28))
                                end
                            end
                        end
                    end
                end
            end
            local fm = st_addr and rp(st_addr + 0x540)
            if SL.kptr(fm) then
                local d, c = rp(fm + 8), ru32(fm + 20)
                if SL.kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_SANE then
                    for i = 0, c - 1 do
                        local e = d + 0x30 * i
                        local key = ru32(e + 8)
                        local nm = key and key <= (hoi4.read_u32(hoi4.base() + GAME.layout.rva.lexer_token_max) or 100000) and SL.tok(key)
                        if nm then
                            local v = ru32(e + 0x28) or 0
                            v = v & 0xFFFF
                            v = GAME.layout.as_i16(v)
                            E("flags." .. nm .. ".value", tostring(v))
                            local dh = ru32(e + 0x18)
                            if dh and dh > 0 then
                                local ds = SL.date(dh) -- 绝对小时直用
                                if ds then E("flags." .. nm .. ".date", '"' .. ds .. '"') end
                            end
                            -- days = expiry i16 高半
                            -- (与 country.flags 同族同门: >0 才写)
                            local ex = (ru32(e + 0x28) >> 16) & 0x7FFF
                            if ex > 0 then
                                E("flags." .. nm .. ".days", tostring(ex))
                            end
                        end
                    end
                end
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
                local vo = st_addr and rp(st_addr + 2040)
                if SL.kptr(vo) then
                    E("variables.random", string.format("%d %d",
                        ru32(vo + 12) or 0, ru32(vo + 8) or 0))
                end
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
                    local ra = st.addr
                    local atd = ra and rp(ra + 0x268 + 600)
                    local atc = ra and ru32(ra + 0x268 + 612) or 0
                    if SL.kptr(atd) and atc > 0 and atc < GAME.layout.lim.PTR_SANE then
                        for ai = 0, atc - 1 do
                            local ae = atd + 72 * ai
                            local ap = "resistance.added_resistance_targets.#"
                                .. (ai + 1) .. "."
                            local aid = ru32(ae + 8)
                            if aid and aid ~= 0 then
                                E(ap .. "id", tostring(aid))
                            end
                            E(ap .. "amount", numf(rp(ae + 16) / 1e5))
                            local ady = ru32(ae + 24)
                            if ady and ady ~= 0xFFFFFFFF then
                                E(ap .. "days", tostring(ady))
                            end
                            local act = ru32(ae + 28)
                            if act and act > 0 then
                                local t = O:tag(act)
                                if t then E(ap .. "controller", '"' .. t .. '"') end
                            end
                            local aot = ru32(ae + 32)
                            if aot and aot > 0 then
                                local t = O:tag(aot)
                                if t then E(ap .. "occupied", '"' .. t .. '"') end
                            end
                            if (rp(ae + 56) or 0) ~= 0 then
                                local tt = SL.sso(ae + 40)
                                if tt and tt ~= "" then
                                    E(ap .. "tooltip", '"' .. tt .. '"')
                                end
                            end
                        end
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
                        -- 1.19.3: bare pairs 的 defs 全局已搬家
                        -- (0x33169C0 → 0x332ED90, 共享层禁改) → 段内自
                        -- _addr 内联重读, 读取语义与 objects_v2 同构
                        do
                            local e0 = at._addr
                            local obj = e0 and rp(e0 + 0x20)
                            if SL.kptr(obj) then
                                local pcnt = math.min(ru32(e0 + 40) or 0,
                                    ru32(e0 + 44) or 0, 8)
                                for q = 0, pcnt - 1 do
                                    local midx = ru32(obj + 16 * q)
                                    if not midx or midx == 0 then break end
                                    local raw = SL.rp_i64(obj + 16 * q + 8)
                                        or 0
                                    local mn =
                                        GAME.layout.modifier_token(midx)
                                    if mn then
                                        E("active_targeted_modifier."
                                            .. tg .. "." .. mn,
                                            numf(raw / 1e5))
                                    end
                                end
                            end
                        end
                        -- added_modifier: data/name/modkey 全接通 (钻研定案)
                        -- data = u32@aobj+0xBC (≠1 才写); name = SSO@aobj+0x58
                        -- (size>0 才写, 创建时缓存非合成); modkey 值 = added_pairs
                        local aarr = at._addr and rp(at._addr + 0x38)
                        local acnt = at._addr and ru32(at._addr + 0x44) or 0
                        if SL.kptr(aarr) and acnt and acnt > 0 and acnt < GAME.layout.lim.PTR_SANE then
                            local aseq = SL.seqc()
                            for aj = 0, acnt - 1 do
                                local aobj = rp(aarr + 8 * aj)
                                if SL.kptr(aobj) then
                                    local kp = "active_targeted_modifier." .. tg
                                        .. "." .. aseq("added_modifier") .. "."
                                    local dv = ru32(aobj + 0xBC)
                                    if dv and dv ~= 1 then
                                        E(kp .. "data", tostring(dv))
                                    end
                                    local nm = SL.sso(aobj + 0x58)
                                    if nm and nm ~= "" then
                                        E(kp .. "name", '"' .. nm .. '"')
                                    end
                                    -- pairs 段内内联 (CModifier 同构;
                                    -- 布局 = §4.3.8, defs 表 = §4.26)
                                    local pd2 = rp(aobj + 16)
                                    local pc2 = ru32(aobj + 28)
                                    if SL.kptr(pd2)
                                        and pc2 and pc2 > 0 and pc2 < GAME.layout.lim.PTR_SANE then
                                        for pj = 0, pc2 - 1 do
                                            local di = ru32(pd2 + 16 * pj)
                                            local raw = SL.rp_i64(
                                                pd2 + 16 * pj + 8)
                                            if di and raw then
                                                -- 散写回收
                                                local mn =
                                                    GAME.layout.modifier_token(di)
                                                if mn then
                                                    E(kp .. mn,
                                                        numf(raw * 1e-5))
                                                end
                                            end
                                        end
                                    end
                                end
                            end
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
