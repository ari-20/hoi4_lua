-- sv2_sec_peace_conference.lua -- peace_conference 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Runtime:peace_conference, objects_world §19.2);
-- 本段只持写序/块键/[N] 编号/值格式化。
-- ⚠ time_duration 落盘值 = base + 写时墙钟重算 (Xtime_get_ticks − 起点
--   ticks)/1e7 — writer 语义, 留段层 (豁免台账 active_peace.time_duration)。

SV2.gsec[#SV2.gsec + 1] = { name = "peace_conference", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8

    local okp, pc = pcall(function() return O:peace_conference() end)
    if not (okp and pc and pc.active and pc.conferences) then return end
    -- 以下发射 §4.10.27 CPeaceConference 各字段块 (管理器 = §4.10.26)

    local seq = SL.seqc()
    for _, c in ipairs(pc.conferences) do
        local p = c.addr
        if p then
            local ab = seq("active_peace")   -- 多块重复键: 首现不编号
            local function E(path, val)
                emit("peace_conference", ab .. "." .. path, val)
            end
            -- id 对 (§3.6 id 对; sub_14220B400: 恒写; type@p+8 id@p+12)
            E("id", SL.idpair(c.id_id, c.id_type))
            -- actor/recipient (ADF40 恒写引号串, tag idx@p+52/+56)
            local s = SL.Q(c.actor) if s then E("actor", s) end
            s = SL.Q(c.recipient) if s then E("recipient", s) end
            -- occupied_winners (15094): u32 idx 数组, c>0; 解析失败槽 "?" 占位
            if c.occupied_winners then
                local t = {}
                for j = 1, c.occupied_winners_n do
                    t[j] = c.occupied_winners[j] or "?"
                end
                E("occupied_winners.#1", table.concat(t, " "))
            end
            -- peace_conference_name_state_id u32@p+24 恒写
            E("peace_conference_name_state_id",
                tostring(c.name_state_id or 0))
            -- peace_threat 恒写 (0x4B89=fix5@p+536; reader 已定案)
            E("peace_threat", SL.num(c.peace_threat))
            -- completed (12583) 仅真写 yes, u8@p+221
            if c.completed then E("completed", "yes") end
            -- factor 恒写 (0x296B=fix5@p+40)
            E("factor", SL.num(c.factor))
            -- message (221): SSO 串@p+64 (§3.5), 门 size@p+80≠0 (reader 已门)
            s = SL.Q(c.message) if s then E("message", s) end
            -- winner_scope/loser_scope u32@p+28/+32 恒写
            E("winner_scope", tostring(c.winner_scope or 0))
            E("loser_scope", tostring(c.loser_scope or 0))

            -- winners 块: 指针数组 {d@p+248,c@p+260} 恒写; 元素 e,
            -- 块键 = tag(e+8), 块对象 b=e+64 (writer sub_1414478A0)
            for _, w in ipairs((c.winners and c.winners.list) or {}) do
                local e = w.addr
                local wb = "winners." .. tostring(w.country)
                local function WE(path, val) E(wb .. "." .. path, val) end
                -- country: tag idx@e+8 (b-56), 门 idx>0
                s = SL.Q(w.country) if s then WE("country", s) end
                -- original_score u32@e+72 (b+8) / score u32@e+76 (b+12) 恒写
                WE("original_score", tostring(w.original_score or 0))
                WE("score", tostring(w.score or 0))
                -- score_distribution: u32 数组 {d@e+88,c@e+100}, c>0 → #1 空格连
                if w.score_distribution and #w.score_distribution > 0 then
                    WE("score_distribution.#1",
                        table.concat(w.score_distribution, " "))
                end
                -- ratio fixed5@e+112 (b+48) 恒写
                WE("ratio", SL.num(w.ratio))
                -- §4.10.27 CWarScoreBreakdown (壳/内层布局 = 书) —
                -- first/second tag 门 idx>0 (bk+8/+12); 9 个 fixed5 恒写
                -- (writer 序; sent@+80 received@+88, +72 不写 = 缓存和);
                -- captured_provinces map {head@bk+96,size@bk+104}, size≠0
                -- → #1 空格连升序 (中序 = key 升序, reader 已走)
                local bkd = w.war_score_breakdown
                if bkd then
                    local ib = wb .. ".war_score_breakdown"
                        .. ".war_score_breakdown"
                    s = SL.Q(bkd.first) if s then E(ib .. ".first", s) end
                    s = SL.Q(bkd.second) if s then E(ib .. ".second", s) end
                    for _, f in ipairs({
                        "equipment_damage", "province_capture",
                        "air_damage_str", "strategic_air",
                        "sunk_ship", "convoy_attack",
                        "casualties", "lend_lease_sent",
                        "lend_lease_received" }) do
                        E(ib .. "." .. f, SL.num(bkd[f]))
                    end
                    if bkd.captured_provinces
                        and #bkd.captured_provinces > 0 then
                        E(ib .. ".captured_provinces.#1",
                            table.concat(bkd.captured_provinces, " "))
                    end
                end
                -- total_score_before u32@W+144=e+0x110 恒写 (壳字段;
                -- ⚠ 不在内层 vt 门内 — 与 writer 直出同形)
                E(wb .. ".war_score_breakdown.total_score_before",
                    tostring(w.total_score_before or 0))
                -- non_refunded_score u32@e+80 (b+16) 恒写
                WE("non_refunded_score", tostring(w.non_refunded_score or 0))
            end

            -- solo_winner (12552): ptr@p+368 → tag idx@obj+8, 门 ptr≠0+idx>0
            s = SL.Q(c.solo_winner) if s then E("solo_winner", s) end

            -- losers 块: 指针数组 {d@p+272,c@p+284} 恒写; 块键 = tag(le+16),
            -- 块对象 = 元素本身 (writer sub_1414477E0)
            for _, l in ipairs((c.losers and c.losers.list) or {}) do
                local lb = "losers." .. tostring(l.country)
                -- screening_ic u32@le+48 恒写 (0x3395)
                E(lb .. ".screening_ic", tostring(l.screening_ic or 0))
                -- civil_war_target (12619) 仅真写 yes, u8@le+176
                if l.civil_war_target then
                    E(lb .. ".civil_war_target", "yes") end
                -- civil_war_enemy (14217) tag, 门 idx>0
                s = SL.Q(l.civil_war_enemy)
                if s then E(lb .. ".civil_war_enemy", s) end
            end

            -- liberated (12581): 指针数组 {d@p+296,c@p+308}, c>0; 块对象
            -- elem+64 与 winner 同型 (同 sub_1424AD860 调用形态) — 块内容
            -- 布局同 winner, 锚件 0 例, 仅枚举键占位不如不发: 门控跳过。
            -- subject(13024)/history(10293) 同因布局未全定案不发射 (见头注)。

            -- civil_war_losers (12134): u32 idx 数组, c>0; "?" 占位同上
            if c.civil_war_losers then
                local t = {}
                for j = 1, c.civil_war_losers_n do
                    t[j] = c.civil_war_losers[j] or "?"
                end
                E("civil_war_losers.#1", table.concat(t, " "))
            end
            -- done (12813): map 中序 (idx 升序), size≠0 → #1 空格连
            -- tag (解析失败落 tostring(key))
            if c.done_keys and #c.done_keys > 0 then
                local t = {}
                for _, k in ipairs(c.done_keys) do
                    t[#t + 1] = O:tag(k) or tostring(k)
                end
                E("done.#1", table.concat(t, " "))
            end
            -- time_duration (10925) 恒写: u32@p+624 + (Xtime_get_ticks
            -- - i64@p+616)/1e7 — ⚠ 写时墙钟叶 (同 #session/seconds_played
            -- 族): writer 时刻重算 now−start, resave↔导出对拍恒差墙钟
            -- 间隔, 豁免已生效 (用户裁定; ⚠ 多块形
            -- active_peace[2].time_duration 不在豁免键内, 现无实例)。
            -- Xtime = FILETIME 100ns (1601 纪元)。
            -- 纪元自检: 嵌入式 os.time 返回 1601 纪元秒
            -- (已含 1601↔1970 偏移 11644473600), 桌面 lua 是 Unix 秒 —
            -- >C 即已含偏移, 幂等补齐。
            do
                local base624 = c.time_duration_base or 0
                local t616 = c.time_start_ticks or 0
                local dur = base624
                if t616 > 0 then
                    local u = os.time() or 0
                    if u < 11644473600 then u = u + 11644473600 end
                    local el = math.floor((u * 10000000 - t616) / 10000000)
                    if el > 0 then dur = base624 + el end
                end
                E("time_duration", tostring(dur))
            end
        end
    end
end }
