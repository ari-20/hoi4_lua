-- sv2_sec_global_tails.lua -- 全局小块扫尾 savefull 直出 (gsec)
-- 结构/走查唯一实现 = reader: 阵营族/tech_sharing/power_balance =
-- Runtime:faction_blocks & Runtime:power_balance (objects_politics §4.5);
-- region/threat/game_rules/entity/variables = Runtime.global_* (objects_world
-- §4.25); sunk 两族 = Runtime.global_sunk_* (objects_military §4.16);
-- 元数据族 = Runtime.global_* (objects_global §4.1/§4.12/§4.28)。
-- 本段只持 dim 命名/写序/块键/[N] 编号/值格式化; id_counter/mods 两块
-- 本就直接消费 reader (top_meta / mods_registry)。

local SL = SV2.lib

SV2.gsec[#SV2.gsec + 1] = { name = "global_tails", emit = function(ctx)
    local gs = ctx.gs
    if not gs then return end
    local O = ctx.O
    local raw_emit = ctx.emit
    local function emit(dim, path, val)
        if val ~= nil then raw_emit(dim, path, tostring(val)) end
    end
    local function Q(s) return SL.Q(s) end
    -- §3.7b date 三变体 (哨兵语义 = 书; 43808760 照写 / 43817520 视未设)
    local function date3(h)
        if h == 43808760 then return "1.1.1.1" end
        return SL.date(h) end
    local function date2(h)
        if not h or h == 43817520 then return nil end
        return date3(h) end
    local okM, R = pcall(function() return O:faction_blocks() end)
    if not okM then R = nil end

    -- ===== variables (全局 CVariables) =====
    do
        local okv, vr = pcall(function() return O:global_variables() end)
        if okv and vr then
            if vr.random then
                emit("variables", "random",
                    string.format("%d %d", vr.random[1], vr.random[2])) end
            -- 键字节序: 按 "名|格式化值" 拼串排 (名不含 |; writer 契约)
            local list = {}
            for _, kv in ipairs(vr.entries or {}) do
                list[#list + 1] = kv.name .. "|" .. SL.num(kv.value) end
            table.sort(list)
            local vseq = 0
            for _, kv in ipairs(list) do
                local nm, val = kv:match("^(.-)|(.*)$")
                if nm then
                    if nm:find("%^num$") then
                        vseq = vseq + 1
                        emit("variables", "#" .. vseq, nm .. "=" .. val)
                    else
                        emit("variables", nm, val)
                    end
                end
            end
        end
    end

    -- ===== §4.5.2 faction (dim 第二起 [N]) =====
    local GSTATUS = { [0] = "active", [1] = "completed", [2] = "canceled" }
    local EXEC = { [0] = "careful", [1] = "balanced", [2] = "rush",
        [3] = "rush_weak" }
    local SLOTN = { [0] = "short_term", "medium_term", "long_term" }
    if R and R.factions then
        for i, fr in ipairs(R.factions) do
            local dim = i == 1 and "faction" or ("faction[" .. i .. "]")
            local function E(p, v) emit(dim, p, v) end
            E("id", SL.idpair(fr.id_id, fr.id_type))
            if fr.name then E("name", Q(fr.name)) end
            E("icon", fr.icon and Q(fr.icon) or nil)
            if fr.color then
                local s = string.format("%d %d %d", fr.color[1], fr.color[2],
                    fr.color[3])
                if fr.color_a then
                    s = s .. " " .. tostring(fr.color_a) end
                E("color", s) end
            E("is_color_overridden", SL.yn(fr.is_color_overridden))
            if fr.ideology then E("ideology", fr.ideology) end
            if fr.members then
                for mi = 1, fr.members_n do
                    local t = fr.members[mi]
                    if t then E("members.#" .. mi, Q(t)) end
                end
            end
            local ds = date2(fr.leader_change_h)
            if ds then E("faction_leader_change_date", Q(ds)) end
            if fr.template then
                local tv = type(fr.template) == "string"
                    and Q(fr.template) or tostring(fr.template)
                if tv then E("template", tv) end end
            -- goal_status (§4.5.3)
            local gs2 = fr.goal_status
            if gs2 then
                if gs2.manifest then E("goal_status.manifest", gs2.manifest) end
                for gi, g2 in ipairs(gs2.goals or {}) do
                    local kp = "goal_status.goals.#" .. gi
                    if g2.goal then E(kp .. ".goal", g2.goal) end
                    E(kp .. ".status", GSTATUS[g2.status] or "active")
                    local ds2 = date3(g2.game_data_h)
                    if ds2 then E(kp .. ".game_data", Q(ds2)) end
                end
                local es = gs2.extra_slots or {}
                for si = 0, 2 do
                    local v = es[si]
                    if v and SLOTN[si] then
                        E("goal_status.extra_goal_slots." .. SLOTN[si],
                            tostring(v)) end
                end
                for gi, dh in ipairs(gs2.game_data or {}) do
                    local ds3 = date3(dh)
                    if ds3 then
                        E("goal_status.game_data.#" .. gi, Q(ds3)) end
                end
            end
            if fr.power_projection then
                E("power_projection_from_effects",
                    SL.num(fr.power_projection)) end
            for _, mp in ipairs(fr.manpower_pool2 or {}) do
                E("manpower_pool[2].value",
                    'tag="' .. mp.tag .. '" value=' .. mp.value) end
            for pi, fp in ipairs(fr.faction_programs or {}) do
                E("faction_programs.faction_programs.#" .. pi,
                    "id=" .. fp.id .. " type=" .. fp.type) end
            for gi, pg in ipairs(fr.pings or {}) do
                local kp = "pings.regions.#" .. gi
                if pg.name and pg.name ~= "" then
                    E(kp .. ".name", Q(pg.name)) end
                if pg.tag then E(kp .. ".tag", Q(pg.tag)) end
                if pg.commander then
                    E(kp .. ".commander", "id=" .. pg.commander.id
                        .. " type=" .. pg.commander.type) end
                local ex = EXEC[pg.execution_type]
                if ex then E(kp .. ".execution_type", ex) end
                if pg.template and pg.template ~= "" then
                    E(kp .. ".template", pg.template) end
                if pg.countries then
                    E(kp .. ".countries",
                        "countries={ " .. '"' .. pg.countries[1] .. '"')
                    for j = 2, #pg.countries do
                        E(kp .. ".@.#" .. (j - 1),
                            '"' .. pg.countries[j] .. '"') end
                end
                if pg.ids then
                    local parts = {}
                    for _, v in ipairs(pg.ids) do
                        parts[#parts + 1] = tostring(v) end
                    E(kp .. ".ids", table.concat(parts, " ")) end
                for _, iv in ipairs({ { "selection_order" },
                    { "hidden" } }) do
                    local lst = pg[iv[1]]
                    if lst then
                        local parts = {}
                        for _, v in ipairs(lst) do
                            parts[#parts + 1] = tostring(v) end
                        E(kp .. "." .. iv[1], table.concat(parts, " ")) end
                end
            end
            for _, ex2 in ipairs(fr.extracted or {}) do
                E("extracted." .. ex2.name, SL.num(ex2.value)) end
            local us = fr.upgrade_slots
            if us then
                for ui, s2 in ipairs(us) do
                    local kp = "upgrades.slots.#" .. ui
                    if s2.owner then E(kp .. ".owner", Q(s2.owner)) end
                    if s2.advisor and s2.advisor ~= "" then
                        E(kp .. ".advisor", s2.advisor) end
                    local cd = date2(s2.spymaster_change_h)
                    if cd then
                        E(kp .. ".spymaster_change_date", Q(cd)) end
                    for _, mo in ipairs({ { "modifier", s2.modifier },
                        { "spymaster", s2.spymaster } }) do
                        local m = mo[2]
                        local mp2 = kp .. "." .. mo[1]
                        if m.name and m.name ~= "" then
                            E(mp2 .. ".name", Q(m.name)) end
                        for _, pv in ipairs(m.pairs or {}) do
                            E(mp2 .. "." .. pv.name, SL.num(pv.value)) end
                        if m.data then
                            E(mp2 .. ".data", tostring(m.data)) end
                    end
                end
            end
            local tsg = fr.tech_sharing
            if tsg then
                E("upgrades.tech_sharing_group.upgrade",
                    tostring(tsg.upgrade))
                if tsg.bonuses then
                    local parts = {}
                    for _, v in ipairs(tsg.bonuses) do
                        parts[#parts + 1] = SL.num(v) end
                    E("upgrades.tech_sharing_group.bonuses.#1",
                        table.concat(parts, " ")) end
                if tsg.countries then
                    for ci = 1, tsg.countries_n do
                        local t = tsg.countries[ci]
                        if t then
                            E("upgrades.tech_sharing_group.countries.#"
                                .. ci, Q(t)) end
                    end
                end
            end
            E("research", SL.yn(fr.research))
            E("manpower", SL.yn(fr.manpower_flag))
            local vr = fr.variables
            if vr then
                if vr.random then
                    E("variables.random", string.format("%d %d",
                        vr.random[1], vr.random[2])) end
                local list = {}
                for _, kv in ipairs(vr.entries or {}) do
                    list[#list + 1] = kv.name .. "|" .. SL.num(kv.value) end
                table.sort(list)
                local vseq = 0
                for _, kv in ipairs(list) do
                    local nm, val = kv:match("^(.-)|(.*)$")
                    if nm then
                        if nm:find("%^num$") then
                            vseq = vseq + 1
                            E("variables." .. "#" .. vseq, nm .. "=" .. val)
                        else
                            E("variables." .. nm, val) end
                    end
                end
            end
        end
    end

    -- ===== §4.5.1 faction_system =====
    if R and R.member_status then
        local ms = R.member_status
        local n = 0
        for _, s2 in ipairs(ms.slots or {}) do
            n = n + 1
            local kp = "countries.#" .. n
            emit("faction_system", kp .. ".index", tostring(s2.index))
            local k = 0
            for _, infl in ipairs(s2.influence or {}) do
                k = k + 1
                emit("faction_system",
                    kp .. ".data.influence_status.#" .. k
                    .. ".index", tostring(infl.index))
                emit("faction_system", kp .. ".data.influence_status.#"
                    .. k .. ".data", SL.num(infl.data))
            end
            if k == 0 then
                emit("faction_system", kp .. ".data.influence_status.#1",
                    tostring(s2.influence_size)) end
            if s2.initiative then
                emit("faction_system", kp .. ".data.initiative",
                    SL.num(s2.initiative)) end
            if s2.contribution then
                emit("faction_system", kp .. ".data.contribution",
                    SL.num(s2.contribution)) end
            emit("faction_system", kp .. ".data.contribution_gain.#1",
                SL.num(s2.contribution_gain[1]) .. " "
                .. SL.num(s2.contribution_gain[2]))
            emit("faction_system", kp .. ".data.war_score_breakdown",
                SL.num(s2.war_score_breakdown))
        end
        if n == 0 then
            emit("faction_system", "countries.#1", tostring(ms.size)) end
        for _, ex2 in ipairs(ms.extracted or {}) do
            emit("faction_system", "extracted." .. ex2.name,
                SL.num(ex2.value)) end
    end

    -- ===== §4.1.16 ships_built / §1.2 +928 tech_sharing_group =====
    if R and R.tech_sharing then
        for i, t2 in ipairs(R.tech_sharing) do
            local dim = i == 1 and "tech_sharing_group"
                or ("tech_sharing_group[" .. i .. "]")
            if t2.id then emit(dim, "id", t2.id) end
            if t2.bonuses then
                local parts = {}
                for _, v in ipairs(t2.bonuses) do
                    parts[#parts + 1] = SL.num(v) end
                emit(dim, "bonuses.#1", table.concat(parts, " ")) end
            if t2.countries then
                for ci = 1, t2.countries_n do
                    local t = t2.countries[ci]
                    if t then emit(dim, "countries.#" .. ci, Q(t)) end
                end
            end
        end
    end

    -- ===== §4.25.2 region =====
    do
        local okr, regions = pcall(function() return O:global_regions() end)
        if okr and regions then
            for _, rr in ipairs(regions) do
                local pfx = rr.id .. "."
                if rr.name then
                    emit("region", pfx .. "name", Q(rr.name)) end
                local dd = rr.dominance
                if dd then
                    emit("region", pfx .. "dominance.countries",
                        #dd.countries > 0 and table.concat(dd.countries, " ")
                        or "{}")
                    if dd.values then
                        for ki, en in ipairs(dd.values) do
                            local kp = pfx .. "dominance.values.#" .. ki
                            local tagp = ki == 1 and kp
                                or (pfx .. "dominance.values")
                            if en.tag then
                                emit("region", tagp, Q(en.tag)) end
                            local sp = kp .. ".#1."
                            for _, fld in ipairs({ { "current", en.current },
                                { "target", en.target },
                                { "base_target", en.base_target },
                                { "previous", en.previous },
                                { "decline_from", en.decline_from },
                                { "individual_ratio",
                                    en.individual_ratio } }) do
                                if fld[2] then
                                    emit("region", sp .. fld[1],
                                        SL.num(fld[2])) end
                            end
                        end
                    end
                end
            end
        end
    end

    -- ===== §4.25.3 threat =====
    do
        local okt, threats = pcall(function() return O:global_threats() end)
        if okt and threats then
            local seq = SL.seqc()
            for _, tr in ipairs(threats) do
                local kp = seq("threat") .. "."
                emit("threat", kp .. "threat", SL.num(tr.threat))
                emit("threat", kp .. "final_threat", SL.num(tr.final_threat))
                emit("threat", kp .. "daily", SL.num(tr.daily))
                if tr.tag then emit("threat", kp .. "tag", Q(tr.tag)) end
                if tr.target then
                    emit("threat", kp .. "target", Q(tr.target)) end
                local ds = date3(tr.date_h)
                if ds then emit("threat", kp .. "date", Q(ds)) end
                if tr.label then emit("threat", kp .. "label", Q(tr.label)) end
            end
        end
    end

    -- ===== §4.3.21 power_balance =====
    do
        local okp, pbs = pcall(function() return O:global_power_balance() end)
        if okp and pbs then
            for i, pb in ipairs(pbs) do
                local kp = "power_balances.#" .. i .. "."
                if pb.template then
                    emit("power_balance", kp .. "template", Q(pb.template)) end
                emit("power_balance", kp .. "value", SL.num(pb.value))
                if pb.left_side then
                    emit("power_balance", kp .. "left_side",
                        Q(pb.left_side)) end
                if pb.right_side then
                    emit("power_balance", kp .. "right_side",
                        Q(pb.right_side)) end
                if pb.trending_side then
                    emit("power_balance", kp .. "trending_side",
                        Q(pb.trending_side)) end
                for _, t in ipairs(pb.countries or {}) do
                    emit("power_balance", kp .. "countries.#" .. _, Q(t)) end
                for j, sd in ipairs(pb.sides or {}) do
                    local sp = kp .. "sides.#" .. (j + 1) .. "."
                    emit("power_balance", sp .. "id", Q(sd.id))
                    emit("power_balance", sp .. "gfx", Q(sd.gfx)) end
                for _, nm in ipairs(pb.modifiers or {}) do
                    emit("power_balance", kp .. "modifier", Q(nm)) end
            end
        end
    end

    -- ===== §4.16.13 history (sunk_ship) =====
    do
        local okh, ships = pcall(function() return O:global_sunk_ships() end)
        if okh and ships then
            local seq = SL.seqc()
            for _, el in ipairs(ships) do
                local kp = seq("sunk_ship") .. "."
                if el.name then
                    emit("history", kp .. "name", '"' .. el.name .. '"') end
                if el.killer_name then
                    emit("history", kp .. "killer_name",
                        '"' .. el.killer_name .. '"') end
                if el.country then
                    emit("history", kp .. "country", Q(el.country)) end
                emit("history", kp .. "killer_country",
                    Q(el.killer_country or "---"))
                emit("history", kp .. "level", tostring(el.level))
                if el.definition then
                    emit("history", kp .. "definition", el.definition) end
                if el.killer_definition then
                    emit("history", kp .. "killer_definition",
                        el.killer_definition) end
                if el.location then
                    emit("history", kp .. "location", tostring(el.location)) end
                local ds = date3(el.date_h)
                if ds then emit("history", kp .. "date", Q(ds)) end
                if el.equipment_variant then
                    emit("history", kp .. "equipment_variant",
                        SL.idpair(el.equipment_variant.id,
                            el.equipment_variant.type)) end
                if el.air_wing then
                    emit("history", kp .. "air_wing",
                        SL.idpair(el.air_wing.id, el.air_wing.type)) end
                emit("history", kp .. "battle",
                    SL.idpair(el.battle.id, el.battle.type))
                emit("history", kp .. "convoy", SL.yn(el.convoy))
            end
        end
    end

    -- ===== §4.1.5 global flags =====
    do
        local okf, flags = pcall(function() return O:global_flags() end)
        if okf and flags then
            for _, fg in ipairs(flags) do
                local kp = fg.name .. "."
                emit("flags", kp .. "value", tostring(fg.value))
                if fg.date_h then
                    local ds = SL.date(fg.date_h)
                    if ds then
                        emit("flags", kp .. "date", '"' .. ds .. '"') end
                end
                if fg.days then
                    emit("flags", kp .. "days", tostring(fg.days)) end
            end
        end
    end

    -- ===== §4.16.14 sunk_convoys_history =====
    do
        local oks, cvl = pcall(function() return O:global_sunk_convoys() end)
        if oks and cvl then
            local seq = SL.seqc()
            for _, el in ipairs(cvl) do
                local kp = seq("sunk_convoy") .. "."
                emit("sunk_convoys_history", kp .. "month",
                    tostring(el.month))
                emit("sunk_convoys_history", kp .. "convoys",
                    tostring(el.convoys))
                emit("sunk_convoys_history", kp .. "killer_country",
                    Q(el.killer_country or "---"))
                if el.owner then
                    emit("sunk_convoys_history", kp .. "owner", Q(el.owner)) end
            end
        end
    end

    -- ===== §4.1.16 ships_built =====
    do
        local oksb, sb = pcall(function() return O:global_ships_built() end)
        if oksb and sb then
            for _, e in ipairs(sb) do
                emit("ships_built", e.name, tostring(e.count)) end
        end
    end

    -- ===== §4.12.6 saved_event_target (dim 第二起 [N]) =====
    do
        local oke, set = pcall(function()
            return O:global_saved_event_targets() end)
        if oke and set then
            for i, el in ipairs(set) do
                local dim = i == 1 and "saved_event_target"
                    or ("saved_event_target[" .. i .. "]")
                if el.state then emit(dim, "state", tostring(el.state)) end
                if el.country then emit(dim, "country", Q(el.country)) end
                if el.character then
                    emit(dim, "character", SL.idpair(el.character.id,
                        el.character.type)) end
                if el.strategic_region then
                    emit(dim, "strategic_region",
                        tostring(el.strategic_region)) end
                for _, ps in ipairs({ "ace", "operation", "unit",
                    "industrial_organisation", "purchase_contract",
                    "raid_instance", "project", "faction" }) do
                    local pr = el[ps]
                    if pr then
                        emit(dim, ps, SL.idpair(pr.id, pr.type)) end
                end
                if el.name then emit(dim, "name", Q(el.name)) end
            end
        end
    end

    -- ===== §4.28.6 id_counter_store (top_meta reader 直发) =====
    do
        local oki, r = pcall(function() return O:top_meta() end)
        if oki and r and r.id_counter then
            for i, e in ipairs(r.id_counter) do
                emit("id_counter_store", "id_counter.#" .. i,
                    string.format("type=%d id=%d", e.type or 0, e.id or 0))
            end
        end
    end

    -- ===== §4.28.1 player_countries (cosmetic_tag = 根级 # dim) =====
    do
        local okp, pcs = pcall(function()
            return O:global_player_countries() end)
        if okp and pcs then
            for _, pc in ipairs(pcs) do
                if pc.cosmetic_tag then
                    emit("#", "cosmetic_tag", Q(pc.cosmetic_tag)) end
                local kp = pc.tag .. "."
                if pc.user then emit("player_countries", kp .. "user",
                    Q(pc.user)) end
                emit("player_countries", kp .. "country_leader",
                    SL.yn(pc.country_leader))
                if pc.id then
                    emit("player_countries", kp .. "id", tostring(pc.id)) end
            end
        end
    end

    -- ===== §4.28.2 gameplaysettings =====
    do
        local okg, gset = pcall(function()
            return O:global_gameplaysettings() end)
        if okg and gset then
            emit("gameplaysettings", "difficulty", Q(gset.difficulty))
            emit("gameplaysettings", "ironman", tostring(gset.ironman))
            emit("gameplaysettings", "historical",
                tostring(gset.historical)) end
    end

    -- ===== §4.28.3 mods (hoi4_layout reader 直发; 原样保留) =====
    do
        local LAY = GAME.layout
        local tails = LAY.mods_playset_tails()
        local k = 0
        for _, entry in ipairs(LAY.mods_registry()) do
            local npath = entry.path
            if npath and tails[npath] then
                local nm = entry.name
                if nm and nm ~= "" then
                    k = k + 1
                    emit("mods", "#" .. k, Q(nm)) end
            end
        end
    end

    -- ===== §4.28.4 索引计数器 =====
    do
        local okx, idx = pcall(function() return O:global_indexes() end)
        if okx and idx then
            for _, e in ipairs(idx) do
                emit(e.name, "id", tostring(e.id)) end
        end
    end

    -- ===== §4.12.7 fired_event_names (单行 "id=X" 尾贴 "}") =====
    do
        local okf2, parts = pcall(function()
            return O:global_fired_event_names() end)
        if okf2 and parts then
            local out = {}
            for _, nm in ipairs(parts) do
                out[#out + 1] = "id=" .. nm end
            emit("fired_event_names", "id",
                table.concat(out, " ") .. "}") end
    end

    -- ===== §4.1.1 pending_events (scope 树每层写 saved_event_target) =====
    do
        local okp2, pe = pcall(function() return O:global_pending_events() end)
        if okp2 and pe then
            local eseq = SL.seqc()
            local function emit_scope(pfx, sc)
                if not sc then return end
                if sc.country then
                    emit("pending_events", pfx .. "country",
                        '"' .. sc.country .. '"') end
                if sc.state then
                    emit("pending_events", pfx .. "state",
                        tostring(sc.state)) end
                for _, ps in ipairs({ "character", "ace", "operation",
                    "unit", "industrial_organisation",
                    "purchase_contract", "raid_instance", "project",
                    "faction" }) do
                    local pr = sc[ps]
                    if pr then
                        emit("pending_events", pfx .. ps,
                            string.format("id=%d type=%d", pr.id, pr.type)) end
                end
                if sc.strategic_region then
                    emit("pending_events", pfx .. "strategic_region",
                        tostring(sc.strategic_region)) end
                emit("pending_events", pfx .. "random",
                    string.format("%d %d", sc.random[1], sc.random[2]))
                if sc.saved_event_targets then
                    for ti, st2 in ipairs(sc.saved_event_targets) do
                        local kp = pfx .. "saved_event_target"
                        if ti > 1 then kp = kp .. "[" .. ti .. "]" end
                        if st2.state then
                            emit("pending_events", kp .. ".state",
                                tostring(st2.state)) end
                        if st2.country then
                            emit("pending_events", kp .. ".country",
                                '"' .. st2.country .. '"') end
                        if st2.character then
                            emit("pending_events", kp .. ".character",
                                string.format("id=%d type=%d",
                                    st2.character.id, st2.character.type)) end
                        if st2.name then
                            emit("pending_events", kp .. ".name",
                                '"' .. st2.name .. '"') end
                    end
                end
                if sc.root then emit_scope(pfx .. "root.", sc.root) end
                if sc.from then emit_scope(pfx .. "from.", sc.from) end
                if sc.prev then emit_scope(pfx .. "prev.", sc.prev) end
            end
            for _, ev in ipairs(pe) do
                local ek = eseq("event") .. "."
                if ev.id then emit("pending_events", ek .. "id", ev.id) end
                emit_scope(ek .. "scope.", ev.scope)
                local ds = date3(ev.timeout_h)
                if ds then
                    emit("pending_events", ek .. "timeout", Q(ds)) end
                emit("pending_events", ek .. "pending_id",
                    tostring(ev.pending_id))
            end
        end
    end

    -- ===== §4.1.5 difficulty_settings (difficulty 重复编号 [2]..) =====
    do
        local okd, dss = pcall(function()
            return O:global_difficulty_settings() end)
        if okd and dss then
            local dseq = SL.seqc()
            for _, ds2 in ipairs(dss) do
                local dk = dseq("difficulty")
                if ds2.name then
                    emit("difficulty_settings", dk .. ".difficulty_setting",
                        '"' .. ds2.name .. '"') end
                emit("difficulty_settings", dk .. ".multiplier",
                    SL.num(ds2.multiplier)) end
        end
    end

    -- ===== §4.25.4 game_rules =====
    do
        local okg2, grs = pcall(function() return O:global_game_rules() end)
        if okg2 and grs then
            for _, gr in ipairs(grs) do
                emit("game_rules", gr.k, '"' .. gr.v .. '"') end
        end
    end

    -- ===== §4.1.5 to_be_deleted =====
    do
        local okt2, tbd = pcall(function()
            return O:global_to_be_deleted() end)
        if okt2 and tbd then
            for i, e in ipairs(tbd) do
                emit("to_be_deleted", "#" .. i,
                    string.format("id=%d type=%d", e.id, e.type)) end
        end
    end

    -- ===== §4.28.6 entity (+§4.25.5 子表) =====
    do
        local oke2, ent = pcall(function() return O:global_entity() end)
        if oke2 and ent then
            emit("entity", "id", tostring(ent.id))
            for _, s2 in ipairs(ent.subs or {}) do
                local blk = "entity." .. s2.key .. "."
                if s2.name ~= nil then
                    emit("entity", blk .. "name", '"' .. s2.name .. '"') end
                for _, fv in ipairs({ { "x", s2.x }, { "y", s2.y },
                    { "z", s2.z }, { "scale", s2.scale },
                    { "rotation", s2.rotation },
                    { "min_zoom", s2.min_zoom } }) do
                    emit("entity", blk .. fv[1], SL.num(fv[2])) end
                if s2.animation and s2.animation ~= "" then
                    emit("entity", blk .. "animation",
                        '"' .. s2.animation .. '"') end
                if s2.visible then
                    emit("entity", blk .. "visible",
                        '"' .. s2.visible .. '"') end
            end
        end
    end
end }
