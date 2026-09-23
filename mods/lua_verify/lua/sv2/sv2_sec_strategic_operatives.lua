-- sv2_sec_strategic_operatives.lua -- strategic_operatives 节点 savefull 直出
-- (§4.11 CCountryIntelNetwork / §4.11.1 CStrategicOperative;
-- operatives mgr = gs+1696, 每国一项 so)

SV2.gsec[#SV2.gsec + 1] = { name = "strategic_operatives", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32 = SL.rp, SL.ru32
    local DIM = "strategic_operatives"
    local function E(path, val)
        if val ~= nil then emit(DIM, path, val) end
    end
    -- i64 ×1e-5 定点 (同 objects_v2 U.fix5)
    local fix5 = GAME.layout.fix5
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
            -- intel_network[N] (§4.11 CCountryIntelNetwork 网容器
            -- {d@so+16, c@so+28}; 多网 seqc, 本档每国至多 1 网)
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
                    -- prev_gain_sources: 存档侧为 `prev_gain_sources={ 360 }`
                    -- 内联块, 提取器出 #N 编号叶 (§4.11.3 +56 容器),
                    -- 与下面 depth/sub_network_id 同型 → 单行 #1 join
                    if gr.prev_gain_sources and #gr.prev_gain_sources > 0 then
                        E(G .. ".prev_gain_sources.#1",
                            join(gr.prev_gain_sources, si32s)) end
                end
                -- operatives.@.#K = state (§4.11 顶点容器 @net+96
                -- stride 12; 提取器只吃裸标量, id 对块被丢弃)
                local ops = net.operatives
                if ops and ops.list and #ops.list > 0 then
                    for k, ov in ipairs(ops.list) do
                        E(NP .. ".operatives.@.#" .. k, tostring(ov.state_id or 0))
                    end
                end
                -- sub_intel_networks (§4.11.4 CSubIntelNetwork 216B;
                -- 容器序; addr 内联推算 = d@net+120 + 216k)
                local subs = net.sub_intel_networks
                local sd = net.addr and rp(net.addr + 120) or nil
                for k, sn in ipairs(subs and subs.list or {}) do
                    local SP = NP .. ".sub_intel_networks.#" .. k
                    -- sub 元素地址 (coverage_per_occupied 内联读用)
                    local s = (sd and SL.kptr(sd)) and (sd + 216 * (k - 1))
                        or nil
                    -- modifiers 直用 reader (§4.11.4 内联三槽
                    -- gain@+8/chance@+24/factor@+16, sub writer
                    -- 0x1411F3430 token 实证; 旧段内内联+回落逻辑回收)
                    local m = sn.modifiers or {}
                    local mgf = m.intel_network_gain_factor
                    local mch = m.own_operative_detection_chance
                    local mcf = m.own_operative_detection_chance_factor
                    E(SP .. ".modifiers.intel_network_gain_factor", SL.num(mgf))
                    E(SP .. ".modifiers.own_operative_detection_chance",
                        SL.num(mch))
                    E(SP .. ".modifiers.own_operative_detection_chance_factor",
                        SL.num(mcf))
                    E(SP .. ".strength", SL.num(sn.strength))
                    E(SP .. ".strength_sum", SL.num(sn.strength_sum))
                    E(SP .. ".strength_sum_over_cores",
                        SL.num(sn.strength_sum_over_cores))
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
                    -- coverage_per_occupied (§4.11.4 +120 容器; 布局/门 =
                    -- 书; tag 出叶首条 .#1 余裸键 = 书同款)
                    if s then
                        local cvd, cvc = rp(s + 120), ru32(s + 132)
                        if SL.kptr(cvd) and cvc and cvc > 0 and cvc < 4096 then
                            for j = 0, cvc - 1 do
                                local el = cvd + 12 * j
                                local tid = ru32(el)
                                if tid and tid > 0 then
                                    local cp = SP .. ".coverage_per_occupied"
                                    E(j == 0 and (cp .. ".#1") or cp,
                                        SL.Q(O:tag(tid)))
                                end
                                local F1 = SP .. ".coverage_per_occupied.#"
                                    .. (j + 1) .. ".#1"
                                E(F1 .. ".owned_worth",
                                    tostring(ru32(el + 4) or 0))
                                E(F1 .. ".states", tostring(ru32(el + 8) or 0))
                            end
                        end
                    end
                    -- 以下三族 reader 未带出原始序/缺字段 → 段内内联
                    if s then
                        -- operatives 打包 id 对 (§4.11.4 +192 容器;
                        -- 布局 = 书)
                        local od, oc = rp(s + 192), ru32(s + 204)
                        if SL.kptr(od) and oc and oc > 0 and oc < 4096 then
                            for j = 0, oc - 1 do
                                local e = od + 8 * j
                                local ty, id = ru32(e), ru32(e + 4)
                                E(SP .. ".operatives.#" .. (j + 1),
                                    SL.idpair(id, ty))
                            end
                        end
                        -- states {d@s+144, c@s+156} stride16 {CState*@0,
                        -- i64 str@8} (§4.11.4 +144 容器); writer 按州 id
                        -- 排序 (TLS 排序段实证)
                        local td, tc2 = rp(s + 144), ru32(s + 156)
                        if SL.kptr(td) and tc2 and tc2 > 0 and tc2 < GAME.layout.lim.PTR_HUGE then
                            local rows = {}
                            for j = 0, tc2 - 1 do
                                local e = td + 16 * j
                                local sp = rp(e)
                                local sid = SL.kptr(sp) and ru32(sp + 88) or nil
                                if sid then
                                    rows[#rows + 1] =
                                        { sid = sid, str = fix5(e + 8) or 0 }
                                end
                            end
                            table.sort(rows, function(a, b) return a.sid < b.sid end)
                            for j, r in ipairs(rows) do
                                E(SP .. ".states.#" .. j,
                                    r.sid .. " " .. SL.num(r.str))
                            end
                        end
                        -- core_states {d@s+168, c@s+180} 8B CState*
                        -- (§4.11.4 +168 容器; count≠0 才写; 升序单行)
                        local cd, cc2 = rp(s + 168), ru32(s + 180)
                        if SL.kptr(cd) and cc2 and cc2 > 0 and cc2 < GAME.layout.lim.PTR_HUGE then
                            local ids = {}
                            for j = 0, cc2 - 1 do
                                local sp = rp(cd + 8 * j)
                                local sid = SL.kptr(sp) and ru32(sp + 88) or nil
                                if sid then ids[#ids + 1] = sid end
                            end
                            table.sort(ids)
                            if #ids > 0 then
                                E(SP .. ".core_states.#1", join(ids)) end
                        end
                    end
                end
                -- max_coverage_by_occupied_tag (§4.11 +144 容器; 布局/门 =
                -- 书) — 形态 = 裸 tag 行 #J + 内层匿名块 #J.#1.<字段>
                if net.addr then
                    local md, mc = rp(net.addr + 144), ru32(net.addr + 156)
                    if SL.kptr(md) and mc and mc > 0 and mc < 4096 then
                        for j = 0, mc - 1 do
                            local el = md + 40 * j
                            -- 伪影: { "TAG" {…} } 对列表第 1 条
                            -- tag = .#1, 第 2 条起 tag = 裸键 (提取器对
                            -- '\t}'+'}' 双闭括号行的半匿名出叶口径)
                            local MB = NP .. ".max_coverage_by_occupied_tag"
                            local MP = (j == 0) and (MB .. ".#1") or MB
                            local tid = ru32(el)
                            if tid and tid > 0 then
                                E(MP, SL.Q(O:tag(tid))) end
                            -- 字段前缀恒 .#K.#1 (K=1 基容器序, 与 tag 叶
                            -- 伪影无关)
                            local M1 = MB .. ".#" .. (j + 1) .. ".#1"
                            E(M1 .. ".owned_worth",
                                tostring(ru32(el + 8) or 0))
                            E(M1 .. ".states", tostring(ru32(el + 12) or 0))
                            E(M1 .. ".intel_network_gain_factor",
                                SL.num(fix5(el + 16)))
                            E(M1 .. ".enemy_operative_detection_chance",
                                SL.num(fix5(el + 32)))
                            E(M1 .. ".enemy_operative_detection_chance_factor",
                                SL.num(fix5(el + 24)))
                        end
                    end
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
                -- state_strength_max (§4.11 +224 恒写): reader 未接 →
                -- 段内内联 i64@net+224
                -- (writer 0x1411C1BE0 尾: sub_1424AE590(0x4C6A, *(a1+224)))
                if net.addr then
                    E(NP .. ".state_strength_max", SL.num(fix5(net.addr + 224)))
                end
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
