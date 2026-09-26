-- sv2_sec_character_manager.lua -- character_manager 节点 savefull 直出
-- (gsec) — 结构/走查唯一实现 = Runtime:character_manager_full
-- (objects_characters §4.4.9 尾); portraits/subblocks/extras 走既有 reader。
-- 本段只持 dim/写序 (池序 = reader id 升序)/块键/编号/值格式化。

SV2.gsec[#SV2.gsec + 1] = { name = "character_manager", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local DIM = "character_manager"
    local GENDER = { [0] = "undefined", [1] = "male", [2] = "female" }
    local okr, R = pcall(function() return O:character_manager_full() end)
    if not okr or not R then return end

    local function emit_char(DIM2, P, ch, r)
        local function E(path, val)
            if val ~= nil then emit(DIM2, P .. "." .. path, val) end
        end
        E("id", SL.idpair(r.id_id, r.id_type))
        E("token", SL.Q(r.token))
        if r.template then E("template", SL.Q(r.template)) end
        E("name", SL.Q(r.name))
        if r.country then E("country", '"' .. r.country .. '"') end
        if r.nationality then
            E("nationality", '"' .. r.nationality .. '"') end
        E("gender", GENDER[r.gender])
        -- portraits (§4.4.10 reader; 键按 ptype 编号; path 空串也写 "")
        do
            local okp, rpor = pcall(function()
                return O:char_portraits(ch.id) end)
            if okp and rpor and rpor.count > 0 then
                local pseq = SL.seqc()
                for _, po in ipairs(rpor.list) do
                    local k = pseq(tostring(po.ptype))
                    if po.path ~= nil then
                        E("portraits." .. k .. "." .. tostring(po.size),
                            '"' .. po.path .. '"') end
                end
            end
        end
        -- 将领块 (§4.4.2/5/6)
        local ld = r.leader
        if ld then
            local kind = ld.kind
            local function E2(path, val)
                if val ~= nil then
                    emit(DIM2, P .. "." .. kind .. "." .. path, val) end
            end
            E2("id", SL.idpair(ld.id_id, ld.id_type))
            E2("name", SL.Q(ld.name))
            E2("desc", SL.Q(ld.desc))
            E2("custom_cost_text", SL.Q(ld.custom_cost_text))
            E2("portrait_path", SL.Q(ld.portrait_path))
            E2("picture", SL.Q(ld.picture))
            E2("gfx", SL.Q(ld.gfx))
            if ld.female ~= nil then E2("female", SL.yn(ld.female)) end
            if ld.skill then E2("skill", tostring(ld.skill)) end
            if ld.experience then E2("experience", SL.num(ld.experience)) end
            if ld.script_id then E2("script_id", tostring(ld.script_id)) end
            E2("link", SL.Q(ld.link))
            if ld.max_traits then E2("max_traits", SL.num(ld.max_traits)) end
            local SK = { "attack_skill", "defense_skill" }
            if ld.kind == "navy_leader" then
                SK[3], SK[4] = "maneuvering_skill", "coordination_skill"
            else
                SK[3], SK[4] = "planning_skill", "logistics_skill"
            end
            for _, sk in ipairs(SK) do
                if ld[sk] then E2(sk, tostring(ld[sk])) end
                local td = sk:gsub("_skill$", "_skill_temp_deficit")
                if ld[td] then E2(td, tostring(ld[td])) end
            end
            if ld.preferred_tactic then
                E2("preferred_tactic", tostring(ld.preferred_tactic)) end
            if ld.pending_reassign then
                E2("pending_reassign_target",
                    SL.idpair(ld.pending_reassign.id,
                        ld.pending_reassign.type)) end
            if ld.naval_headquarter then
                E2("naval_headquarter",
                    SL.idpair(ld.naval_headquarter.id,
                        ld.naval_headquarter.type)) end
            if ld.kind == "navy_leader" then
                E2("penalty", SL.num(ld.penalty)) end
            if ld.traits and #ld.traits > 0 then
                E2("traits", table.concat(ld.traits, " ")) end
            for _, pl in ipairs(ld.in_progress or {}) do
                E2("in_progress." .. pl.name, SL.num(pl.value)) end
            for _, pl in ipairs(ld.traits_to_remove or {}) do
                E2("traits_to_remove." .. pl.name, tostring(pl.value)) end
            for _, pl in ipairs(ld.trait_xp_factor or {}) do
                E2("trait_xp_factor." .. pl.name, SL.num(pl.value)) end
            if ld.cooldown_reason then
                E2("cooldown_reason", '"' .. ld.cooldown_reason .. '"') end
            if ld.enable_h then
                local d = SL.date(ld.enable_h)
                if d then
                    E2("leader_modifier_enable_date", '"' .. d .. '"') end end
            if ld.cooldown_start_h then
                local d = SL.date(ld.cooldown_start_h)
                if d then
                    E2("leader_cooldown_start_date", '"' .. d .. '"') end end
            if ld.government_in_exile_tag then
                E2("government_in_exile_tag",
                    '"' .. ld.government_in_exile_tag .. '"') end
            if ld.legacy_id then
                E2("legacy_id", tostring(ld.legacy_id)) end
            if ld.promoted_from_unit then
                E2("promoted_from_unit", "yes") end
            if ld.captured then
                E2("captured", "yes")
                if ld.captured_by then
                    E2("captured_by", '"' .. ld.captured_by .. '"') end
                if ld.captured_location then
                    E2("location", tostring(ld.captured_location)) end end
            if ld.deployed then
                E2("deployed", "yes")
                E2("deployment_cost", SL.num(ld.deployment_cost)) end
            for _, sm in ipairs(ld.sub_unit_modifiers or {}) do
                local m = sm.mod
                for _, pr in ipairs(m.pairs or {}) do
                    E2("sub_unit_modifiers." .. sm.ship .. "." .. pr.name,
                        SL.num(pr.value)) end
                if m.data then
                    E2("sub_unit_modifiers." .. sm.ship .. ".data",
                        tostring(m.data)) end
                if m.name then
                    E2("sub_unit_modifiers." .. sm.ship .. ".name",
                        SL.Q(m.name)) end
            end
        end
        -- operative 对
        if r.operative then
            E("operative", SL.idpair(r.operative.id, r.operative.type)) end
        -- country_leaders + scientist (reader char_subblocks)
        do
            local oks, r59 = pcall(function()
                return O:char_subblocks(ch.id) end)
            if oks and r59 then
                local lseq = SL.seqc()
                for _, ld2 in ipairs(r59.leaders or {}) do
                    local lk = lseq("country_leader")
                    local LP = "country_leaders." .. lk
                    E(LP .. ".desc", SL.Q(ld2.desc))
                    if ld2.ideology and ld2.ideology ~= "nil" then
                        E(LP .. ".ideology", tostring(ld2.ideology)) end
                    if ld2.traits and #ld2.traits > 0 then
                        E(LP .. ".traits", table.concat(ld2.traits, " ")) end
                    if ld2.expire_hours then
                        local d = SL.date(ld2.expire_hours)
                        if d then E(LP .. ".expire", '"' .. d .. '"') end end
                    if ld2.id then E(LP .. ".id", tostring(ld2.id)) end
                end
                local sc = r59.scientist
                if sc then
                    for ti, tn in ipairs(sc.traits or {}) do
                        if tn and tn ~= "" and tn ~= "nil" then
                            E("scientist.traits.#" .. ti,
                                '"' .. tn .. '"') end end
                    for _, sk5 in ipairs(sc.skills or {}) do
                        local spec, lvl, exp =
                            tostring(sk5):match("^([^|]+)|([^|]+)|(.*)$")
                        if spec then
                            lvl, exp = tonumber(lvl), tonumber(exp)
                            if lvl and lvl > 0 then
                                E("scientist.skills." .. spec .. ".level",
                                    tostring(lvl)) end
                            if exp and exp > 0 then
                                E("scientist.skills." .. spec
                                    .. ".experience", SL.num(exp)) end
                        end
                    end
                    if sc.is_assigned == 1 then
                        E("scientist.is_assigned", "yes") end
                    if sc.injured and sc.injured > 0 then
                        E("scientist.injured", tostring(sc.injured)) end
                    E("scientist.desc", SL.Q(sc.desc)) end
            end
        end
        -- advisors (RB 中序 reader)
        for ai, ad in ipairs(r.advisors or {}) do
            local ak = "advisor" .. (ai > 1 and ("[" .. ai .. "]") or "")
            local function EA(path, val)
                if val ~= nil then
                    emit(DIM2, P .. ".advisors." .. ak .. "." .. path, val) end
            end
            EA("slot", SL.Q(ad.slot))
            if ad.template then
                EA("template", '"' .. ad.template .. '"')
            elseif ad.dynamic_template then
                local dt = ad.dynamic_template
                if dt.ledger then EA("dynamic_template.ledger", dt.ledger) end
                EA("dynamic_template.slot", SL.Q(dt.slot))
                EA("dynamic_template.idea_token", SL.Q(dt.idea_token))
                EA("dynamic_template.cost", SL.num(dt.cost))
                EA("dynamic_template.removal_cost", SL.num(dt.removal_cost))
                EA("dynamic_template.can_be_fired",
                    SL.yn(dt.can_be_fired))
                EA("dynamic_template.command_power",
                    SL.num(dt.command_power))
                for j, tn in ipairs(dt.traits or {}) do
                    EA("dynamic_template.traits.#" .. j, '"' .. tn .. '"') end
                if dt.desc then
                    EA("dynamic_template.desc", '"' .. dt.desc .. '"') end
            end
            if ad.ledger then EA("ledger", ad.ledger) end
            EA("idea_token", SL.Q(ad.idea_token))
            if ad.political_power then
                EA("political_power", SL.num(ad.political_power)) end
            if ad.command_power then
                EA("command_power", SL.num(ad.command_power)) end
            for j, tn in ipairs(ad.traits or {}) do
                EA("traits.#" .. j, '"' .. tn .. '"') end
            EA("portrait", SL.Q(ad.portrait))
            if ad.removal_cost then
                EA("removal_cost", SL.num(ad.removal_cost)) end
            if ad.can_be_fired_no then EA("can_be_fired", "no") end
            EA("desc", SL.Q(ad.desc))
            if ad.modifier then
                local m = ad.modifier
                if m.data then EA("modifier.data", tostring(m.data)) end
                if m.name then EA("modifier.name", SL.Q(m.name)) end
                for _, pr in ipairs(m.pairs or {}) do
                    EA("modifier." .. pr.name, SL.num(pr.value)) end
            end
        end
        -- variables.random + flags (char_extras reader)
        do
            local okx, rx = pcall(function()
                return O:char_extras(ch.id) end)
            if okx and rx then
                if rx.random and rx.random ~= "nil" then
                    E("variables.random", rx.random) end
                for _, fv in ipairs(rx.flags or {}) do
                    local fn = tostring(fv.name)
                    if fn ~= "" and fn ~= "nil" then
                        local FP = "flags." .. fn
                        if fv.value ~= nil then
                            E(FP .. ".value", tostring(fv.value)) end
                        if fv.date and fv.date ~= "nil" then
                            E(FP .. ".date", '"' .. fv.date .. '"') end
                        if fv.days and fv.days ~= 0 then
                            E(FP .. ".days", tostring(fv.days)) end end
                end
            end
        end
        -- 变量数组 (排序 = "名|%.5f" 拼串; ^N 后缀匿名; 整值去尾零)
        do
            local vlist = {}
            for _, kv in ipairs(r.variables or {}) do
                vlist[#vlist + 1] = kv.name .. "|"
                    .. string.format("%.5f", kv.value) end
            table.sort(vlist)
            local vseq = 0
            for _, kv in ipairs(vlist) do
                local nm, val = kv:match("^(.-)|(.*)$")
                if nm then
                    local suf = nm:match("%^([^%^]*)$")
                    local fv2 = tonumber(val)
                    local vs = (fv2 and fv2 == math.floor(fv2)
                        and math.abs(fv2) < 2 ^ 53)
                        and string.format("%d", fv2) or val
                    if suf and not suf:match("^%d+$") then
                        vseq = vseq + 1
                        E("variables.#" .. vseq, nm .. "=" .. vs)
                    else
                        E("variables." .. nm, vs) end
                end
            end
        end
    end

    if R.next_character_id then
        emit(DIM, "next_character_id", tostring(R.next_character_id)) end
    for _, pname in ipairs({ "historical", "dynamic" }) do
        local cseq = SL.seqc()
        for _, ch in ipairs(R[pname] or {}) do
            emit_char(DIM, pname .. "." .. cseq("character"), ch, ch)
        end
    end
end }
