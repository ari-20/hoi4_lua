-- sv2_sec_c_politics.lua -- country.politics 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.politics", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local r = c:politics()
    if not r then return end
    -- §4.10.10 CPolitics (ps = *(cc+3984))

    -- §4.10.11 CPoliticalParty 党派族 (键含党名, 跨党序不敏感; 党内 country_leader #N 序=容器序)
    -- Q0 = 允许空串的 SL.Q (TFR 政党 long_name="" 落盘实证; writer 对
    -- 存在字段照写, 串内引号仍转义)
    local function Q0(s)
        if s == nil then return nil end
        return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    end
    for _, pt in ipairs(r.parties or {}) do
        local ideol = tostring(pt.ideology)
        local base = "politics.parties." .. ideol
        emit(tag, base .. ".default", SL.yn(pt.default_flag))
        if pt.default_flag == false then -- writer: 仅 default=no 写名对
            local nm, ln = Q0(pt.name), Q0(pt.long_name)
            if nm then emit(tag, base .. ".name", nm) end
            if ln then emit(tag, base .. ".long_name", ln) end
        end
        emit(tag, base .. ".popularity", SL.num(pt.popularity))
        for li, cl in ipairs(pt.country_leaders or {}) do
            local clb = base .. ".country_leader.#" .. li
            local sub = SL.Q(cl.ideology)
            if sub then emit(tag, clb .. ".ideology", sub) end
            if cl.char_id then
                emit(tag, clb .. ".character",
                     SL.idpair(cl.char_id, cl.char_type))
            end
        end
    end

    -- §4.10.10 ideas 容器 (ps+80): 单匿名块 (整行值, token 序 = 容器序)
    if r.ideas and #(r.ideas.list or {}) > 0 then
        emit(tag, "politics.ideas.#1", table.concat(r.ideas.list, " "))
    end

    -- §4.10.10 timed_ideas (CTimedIdea 24B 条, ps+104): 重复键 [N] (首现不编号)
    local seq = SL.seqc()
    for _, tiv in ipairs(r.timed_ideas or {}) do
        local k = seq("politics.timed_idea")
        local nm = SL.Q(tiv.idea)
        if nm then emit(tag, k .. ".idea", nm) end
        emit(tag, k .. ".days", SL.num(tiv.days))
    end

    -- §4.10.10 标量族 (ruling_party@+208 / last_election@+152 / election_frequency@+232 /
    -- elections_allowed@+236 / political_power@+224; 全恒写)
    if r.ruling_party then
        emit(tag, "politics.ruling_party", tostring(r.ruling_party))
    end
    -- "-1.1.1.1" 哨兵 (80 国): hours 为 0/负/哨兵时 writer 原样写字面量
    local le = SL.date(r.last_election_hours) or "-1.1.1.1"
    emit(tag, "politics.last_election", '"' .. le .. '"')
    emit(tag, "politics.election_frequency", SL.num(r.election_frequency))
    emit(tag, "politics.elections_allowed", SL.yn(r.elections_allowed))
    emit(tag, "politics.political_power", SL.num(r.political_power))
end }
