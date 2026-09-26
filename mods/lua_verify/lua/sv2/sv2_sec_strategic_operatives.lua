-- sv2_sec_strategic_operatives.lua -- strategic_operatives 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Runtime.operatives
--  objects_characters §4.11 / §4.11.1 / §4.11.3 / §4.11.4)

SV2.gsec[#SV2.gsec + 1] = { name = "strategic_operatives", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local DIM = "strategic_operatives"
    local function E(path, val)
        if val ~= nil then emit(DIM, path, val) end
    end
    -- q15s (legacy L2247; §4.11.1 Q17.15): → 截断 5 位小数带尾零 ("0.00704")
    local function q15s(v)
        if not v then return nil end
        return string.format("%.5f", math.floor(v * 100000 + 1e-9) / 100000)
    end
    local function join(vals, fmt)
        local t = {}
        for _, v in ipairs(vals) do t[#t + 1] = fmt and fmt(v) or tostring(v) end
        return table.concat(t, " ")
    end
    -- i32 有符号 (定案: depth/sub_network_id 的 -1 = 无子网哨兵;
    -- ru32 零扩展直出会变 4294967295)
    local si32 = GAME.layout.as_i32
    local function si32s(v) return tostring(si32(v)) end
    local PID_FIELDS = { "previous_error", "integral", "last_output", "value",
        "proportional_factor", "integral_factor", "derivative_factor" }

    local ws = O:operatives()
    if not (ws and ws.countries) then return end
    for i = 0, ws.countries - 1 do
        local ok, rop = pcall(function() return O:operatives(i) end)
        if ok and rop then
            local P = "strategic_operative." .. i
            -- intel_network[N] (§4.11 网容器; 多网 seqc, 本档每国至多 1 网)
            local seq = SL.seqc()
            for _, net in ipairs(rop.intel_networks or {}) do
                local NP = P .. "." .. seq("intel_network")
                E(NP .. ".target", SL.Q(net.target))
                -- 图 = §4.11.3 CLocalIntelNetwork (net+16 内联 80B)
                local gr = net.graph
                if gr and gr.vertices then
                    local G = NP .. ".intel_network"
                    E(G .. ".vertices", tostring(gr.vertices))
                    if gr.edges and #gr.edges > 0 then
                        E(G .. ".edges.#1", join(gr.edges)) end
                    if gr.state_id and #gr.state_id > 0 then
                        E(G .. ".state_id.#1", join(gr.state_id)) end
                    if gr.gain and #gr.gain > 0 then
                        E(G .. ".gain.#1", join(gr.gain, SL.num)) end
                    for gi, gb in ipairs(gr.gb or {}) do
                        E(G .. ".gain_breakdown.#" .. gi .. ".operatives",
                            SL.num(gb.operatives))
                        E(G .. ".gain_breakdown.#" .. gi .. ".adjacencies",
                            SL.num(gb.adjacencies))
                    end
                    if gr.strength and #gr.strength > 0 then
                        E(G .. ".strength.#1", join(gr.strength, SL.num)) end
                    if gr.depth and #gr.depth > 0 then
                        E(G .. ".depth.#1", join(gr.depth, si32s)) end
                    if gr.sub_network_id and #gr.sub_network_id > 0 then
                        E(G .. ".sub_network_id.#1",
                            join(gr.sub_network_id, si32s)) end
                    E(G .. ".sub_network_count", tostring(gr.sub_network_count or 0))
                    if gr.quiet and #gr.quiet > 0 then
                        E(G .. ".sub_network_is_quiet", join(gr.quiet)) end
                    E(G .. ".prev_max_depth", tostring(gr.prev_max_depth or 0))
                    -- prev_gain_sources: 存档侧内联块 → 单行 #1 join
                    if gr.prev_gain_sources and #gr.prev_gain_sources > 0 then
                        E(G .. ".prev_gain_sources.#1",
                            join(gr.prev_gain_sources, si32s)) end
                end
                -- operatives.@.#K = state (§4.11 顶点容器; 提取器只吃
                -- 裸标量, id 对块被丢弃)
                local ops = net.operatives
                if ops and ops.list and #ops.list > 0 then
                    for k, ov in ipairs(ops.list) do
                        E(NP .. ".operatives.@.#" .. k, tostring(ov.state_id or 0))
                    end
                end
                -- sub_intel_networks (§4.11.4 CSubIntelNetwork 216B; 容器序)
                for k, sn in ipairs(net.sub_intel_networks and
                        net.sub_intel_networks.list or {}) do
                    local SP = NP .. ".sub_intel_networks.#" .. k
                    local m = sn.modifiers or {}
                    E(SP .. ".modifiers.intel_network_gain_factor", SL.num(m.intel_network_gain_factor))
                    E(SP .. ".modifiers.own_operative_detection_chance",
                        SL.num(m.own_operative_detection_chance))
                    E(SP .. ".modifiers.own_operative_detection_chance_factor",
                        SL.num(m.own_operative_detection_chance_factor))
                    E(SP .. ".strength", SL.num(sn.strength))
                    E(SP .. ".strength_sum", SL.num(sn.strength_sum))
                    E(SP .. ".strength_sum_over_cores", SL.num(sn.strength_sum_over_cores))
                    E(SP .. ".national_coverage", SL.num(sn.national_coverage))
                    E(SP .. ".sub_network_strength_target",
                        SL.num(sn.strength_target))
                    E(SP .. ".sub_network_strength_target_from_operatives",
                        SL.num(sn.strength_target_from_operatives))
                    E(SP .. ".sub_network_strength_target_from_counterintelligence",
                        SL.num(sn.strength_target_from_counterintel))
                    E(SP .. ".sub_network_is_quiet", SL.yn(sn.is_quiet))
                    local cov = sn.coverage or {}
                    E(SP .. ".coverage_stats.core_states",
                        tostring(cov.core_states or 0))
                    E(SP .. ".coverage_stats.controlled_states",
                        tostring(cov.controlled_states or 0))
                    E(SP .. ".coverage_stats.owned_worth",
                        tostring(cov.owned_worth or 0))
                    local tc = sn.total_coverable or {}
                    E(SP .. ".total_coverable.core_states",
                        tostring(tc.core_states or 0))
                    E(SP .. ".total_coverable.controlled_states",
                        tostring(tc.controlled_states or 0))
                    E(SP .. ".total_coverable.owned_worth",
                        tostring(tc.owned_worth or 0))
                    -- coverage_per_occupied (§4.11.4 +120; tag 出叶首条
                    -- .#1 余裸键; tid 门 = tid>0 才发 tag 叶, 字段块恒发)
                    for j, cv in ipairs(sn.coverage_per_occupied or {}) do
                        local cp = SP .. ".coverage_per_occupied"
                        if (cv.tid or 0) > 0 then
                            E(j == 1 and (cp .. ".#1") or cp,
                                SL.Q(O:tag(cv.tid)))
                        end
                        local F1 = cp .. ".#" .. j .. ".#1"
                        E(F1 .. ".owned_worth", tostring(cv.owned_worth or 0))
                        E(F1 .. ".states", tostring(cv.states or 0))
                    end
                    -- operatives 打包 id 对 (§4.11.4 +192)
                    for j, op in ipairs(sn.op_pairs or {}) do
                        E(SP .. ".operatives.#" .. j,
                            SL.idpair(op.id, op.type))
                    end
                    -- states {d@s+144} 16B {州指针, strength}; writer 按
                    -- 州 id 升序 (TLS 排序段实证 — 排序 = 发射规则)
                    do
                        local rows = {}
                        for _, sr in ipairs(sn.states_precise or {}) do
                            rows[#rows + 1] = sr
                        end
                        table.sort(rows, function(a, b) return a.sid < b.sid end)
                        for j, rr in ipairs(rows) do
                            E(SP .. ".states.#" .. j,
                                rr.sid .. " " .. SL.num(rr.str))
                        end
                    end
                    -- core_states {d@s+168} 8B CState* (count≠0 才写; 升序单行)
                    do
                        local ids = {}
                        for _, sid in ipairs(sn.core_states or {}) do
                            ids[#ids + 1] = sid end
                        table.sort(ids)
                        if #ids > 0 then
                            E(SP .. ".core_states.#1", join(ids)) end
                    end
                end
                -- max_coverage_by_occupied_tag (§4.11 +144; 裸 tag 行 #J
                -- 伪影 + 内层匿名块 #J.#1.<字段>)
                for j, mv in ipairs(net.max_coverage_by_occupied_tag or {}) do
                    local MB = NP .. ".max_coverage_by_occupied_tag"
                    local MP = (j == 1) and (MB .. ".#1") or MB
                    if (mv.tid or 0) > 0 then
                        E(MP, SL.Q(O:tag(mv.tid))) end
                    -- 字段前缀恒 .#K.#1 (K=1 基容器序, 与 tag 叶伪影无关)
                    local M1 = MB .. ".#" .. j .. ".#1"
                    E(M1 .. ".owned_worth", tostring(mv.owned_worth or 0))
                    E(M1 .. ".states", tostring(mv.states or 0))
                    E(M1 .. ".intel_network_gain_factor",
                        SL.num(mv.gain_factor))
                    E(M1 .. ".enemy_operative_detection_chance",
                        SL.num(mv.detection_chance))
                    E(M1 .. ".enemy_operative_detection_chance_factor",
                        SL.num(mv.detection_chance_factor))
                end
                local isn = net.intel_source
                if isn then
                    E(NP .. ".intel_source.country", SL.Q(isn.country))
                    E(NP .. ".intel_source.pool", tostring(isn.pool or 0))
                    E(NP .. ".intel_source.id", tostring(isn.id or 0))
                    E(NP .. ".intel_source.discriminant",
                        tostring(isn.discriminant or 0))
                end
                local cov = net.coverage or {}
                E(NP .. ".coverage.core_states", tostring(cov.core_states or 0))
                E(NP .. ".coverage.controlled_states",
                    tostring(cov.controlled_states or 0))
                E(NP .. ".coverage.owned_worth", tostring(cov.owned_worth or 0))
                E(NP .. ".strength_sum", SL.num(net.strength_sum))
                E(NP .. ".strength_sum_over_cores",
                    SL.num(net.strength_sum_over_cores))
                -- state_strength_max (§4.11 +224 恒写)
                E(NP .. ".state_strength_max", SL.num(net.state_strength_max))
            end
            -- recent_propaganda_effort 环 (§4.11.1 +184 环形缓冲
            -- §3.4; head→tail; Q17.15 截断)
            for k, re in ipairs(rop.propaganda_ring_entries or {}) do
                E(P .. ".recent_propaganda_effort.#" .. k .. ".war_support",
                    q15s(re.ws))
                E(P .. ".recent_propaganda_effort.#" .. k .. ".stability",
                    q15s(re.st))
            end
            -- propaganda_weekly_drift (§4.11.1 +304/+312):
            -- raw ≠ 0 才写 (writer v13 = fix(0) = 0)
            local pd = rop.drift
            if pd and ((pd.war_support or 0) ~= 0 or (pd.stability or 0) ~= 0) then
                E(P .. ".propaganda_weekly_drift.war_support",
                    q15s(pd.war_support))
                E(P .. ".propaganda_weekly_drift.stability", q15s(pd.stability))
            end
            -- PID 双块恒写 (§4.11.1 +344/+400; 含 idx0 哨兵全零)
            for _, blk in ipairs({ { "subversive_activity_level",
                    rop.subversive_activity_level },
                { "danger_level", rop.danger_level } }) do
                local t = blk[2]
                if t then
                    for _, fn in ipairs(PID_FIELDS) do
                        E(P .. "." .. blk[1] .. "." .. fn, SL.num(t[fn]))
                    end
                end
            end
        end
    end
end }
