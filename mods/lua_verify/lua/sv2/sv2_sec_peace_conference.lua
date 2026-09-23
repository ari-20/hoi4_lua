-- sv2_sec_peace_conference.lua -- peace_conference 节点 savefull 直出

local function read_peace(ctx)
    local SL = SV2.lib
    local rp, ru32 = SL.rp, SL.ru32
    local O, gs, BASE = ctx.O, ctx.gs, ctx.BASE
    -- i64×1e-5 定点带符号 (§3.7 数值换算; peace_threat 负值先例, 同段内 fix5)
    local function fx(a)
        local v = rp(a) or 0
        v = GAME.layout.as_i64(v)
        return v / 100000
    end
    -- §4.10.26 CPeaceConferenceManager (gs+1248 内嵌, vt 0x2720E48)
    local mgr = gs and (gs + 0x4E0)
    if not SL.kptr(mgr) or rp(mgr) ~= BASE + 0x2720E48 then
        return { addr = mgr, active = false, count = 0, conferences = {} }
    end
    local out = { addr = mgr, active = false,
        count = ru32(mgr + 20) or 0, conferences = {} }
    if out.count == 0 then return out end
    local data = rp(mgr + 8)
    if not SL.kptr(data) then return out end
    out.active = true
    for i = 0, out.count - 1 do
        local p = rp(data + 8 * i)
        if SL.kptr(p) and rp(p) == BASE + GAME.layout.vt.CPeaceConference then
            -- §4.10.27 CPeaceConference (active_peace 元素)
            local c = { addr = p,
                actor = O:tag(ru32(p + 52)),
                recipient = O:tag(ru32(p + 56)) }
            c.winners = { count = ru32(p + 260) or 0, list = {} }
            do
                local wd, wc = rp(p + 248), ru32(p + 260) or 0
                if SL.kptr(wd) and wc > 0 and wc < 4096 then
                    for k = 0, wc - 1 do
                        local e = rp(wd + 8 * k)
                        if SL.kptr(e) then
                            -- §4.10.27 CConferenceWinnerParticipant (winners 条目)
                            local w = { addr = e,
                                country = O:tag(ru32(e + 8)),
                                original_score = ru32(e + 72),
                                score = ru32(e + 76),
                                ratio = fx(e + 112) }
                            w.score_distribution = {}
                            local dd2, dc2 = rp(e + 88), ru32(e + 100)
                            if SL.kptr(dd2) and dc2 and dc2 > 0
                                and dc2 < 64 then
                                for j = 0, dc2 - 1 do
                                    w.score_distribution[#w.score_distribution + 1] =
                                        ru32(dd2 + 4 * j)
                                end
                            end
                            -- §4.10.27 CWarScoreBreakdown (war_score 壳内嵌)
                            local bk = e + 0x88
                            if rp(bk) == BASE + GAME.layout.vt.CWarScoreBreakdown then
                                w.war_score_breakdown = {
                                    equipment_damage =
                                        fx(bk + 0x10),
                                    province_capture =
                                        fx(bk + 0x18),
                                    air_damage_str =
                                        fx(bk + 0x20),
                                    strategic_air =
                                        fx(bk + 0x28),
                                    sunk_ship =
                                        fx(bk + 0x30),
                                    convoy_attack =
                                        fx(bk + 0x38),
                                    casualties =
                                        fx(bk + 0x40),
                                    lend_lease_sent =
                                        fx(bk + 0x50),
                                    lend_lease_received =
                                        fx(bk + 0x58),
                                    total_score_before = ru32(e + 0x110) }
                            end
                            c.winners.list[#c.winners.list + 1] = w
                        end
                    end
                end
            end
            c.losers = { count = ru32(p + 284) or 0, list = {} }
            do
                local ld, lc = rp(p + 272), ru32(p + 284) or 0
                if SL.kptr(ld) and lc > 0 and lc < 4096 then
                    for k = 0, lc - 1 do
                        local le = rp(ld + 8 * k)
                        if SL.kptr(le) then
                            c.losers.list[#c.losers.list + 1] = {
                                addr = le,
                                country = O:tag(ru32(le + 16)),
                                screening_ic = ru32(le + 48) }
                        end
                    end
                end
            end
            out.conferences[#out.conferences + 1] = c
        end
    end
    return out
end

SV2.gsec[#SV2.gsec + 1] = { name = "peace_conference", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8

    -- i64 ×1e-5 定点 (§3.7 数值换算; 100000 勿 *1e-5; 符号双形态兼容,
    -- peace_threat 可为负 — 锚件 -1.71287)
    local function fix5(a)
        local v = rp(a) or 0
        v = GAME.layout.as_i64(v)
        return v / 100000
    end
    -- §3.3 std::map (红黑树) 中序 walker (照 objects_v2 L330-360 RPM 模式, key u32@
    -- node+0x1C 无 value; 中序 = key 升序 = 存档序)。返回 key 数组。
    local function map_keys(base)
        local keys = {}
        local mhead = rp(base)
        if not SL.kptr(mhead) then return keys end
        local function isnilb(p)
            return (not p) or p < 0x10000 or ((ru32(p + 25) & 0xFF) ~= 0)
        end
        local node = rp(mhead)      -- head._Left = 最小节点
        local guard = 0
        while node and not isnilb(node) and guard < 4096 do
            guard = guard + 1
            keys[#keys + 1] = ru32(node + 28) or 0
            local r = rp(node + 16)
            if r and not isnilb(r) then
                node = r
                while true do
                    local l = rp(node)
                    if l and not isnilb(l) then node = l else break end
                end
            else
                while true do
                    local par = rp(node + 8)
                    if not par or isnilb(par) then node = nil break end
                    local from_right = (rp(par + 16) == node)
                    node = par
                    if not from_right then break end
                end
            end
        end
        return keys
    end
    -- tag idx → 引号串 (§1.1 CGameState tag 串表; 门 idx>0, 同 sub_140BA6770)
    local function qtag(tid)
        if tid and tid > 0 then return SL.Q(O:tag(tid)) end
        return nil
    end

    local okp, pc = pcall(function() return read_peace(ctx) end)
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
            E("id", SL.idpair(ru32(p + 12), ru32(p + 8)))
            -- actor/recipient (ADF40 恒写引号串, tag idx@p+52/+56)
            local s = SL.Q(c.actor) if s then E("actor", s) end
            s = SL.Q(c.recipient) if s then E("recipient", s) end
            -- occupied_winners (15094): u32 idx 数组 {d@p+144,c@p+156}, c>0
            do
                local d, n = rp(p + 144), ru32(p + 156)
                if SL.kptr(d) and n and n > 0 and n < GAME.layout.lim.PTR_SANE then
                    local t = {}
                    for j = 0, n - 1 do
                        t[#t + 1] = O:tag(ru32(d + 4 * j)) or "?"
                    end
                    E("occupied_winners.#1", table.concat(t, " "))
                end
            end
            -- peace_conference_name_state_id u32@p+24 恒写
            E("peace_conference_name_state_id", tostring(ru32(p + 24) or 0))
            -- peace_threat 恒写 (0x4B89=fix5@p+536; reader 已定案)
            E("peace_threat", SL.num(c.peace_threat or fix5(p + 536)))
            -- completed (12583) 仅真写 yes, u8@p+221
            if (ru8(p + 221) or 0) ~= 0 then E("completed", "yes") end
            -- factor 恒写 (0x296B=fix5@p+40)
            E("factor", SL.num(c.factor or fix5(p + 40)))
            -- message (221): SSO 串@p+64 (§3.5), 门 size@p+80≠0
            if (rp(p + 80) or 0) ~= 0 then
                s = SL.Q(SL.sso(p + 64)) if s then E("message", s) end
            end
            -- winner_scope/loser_scope u32@p+28/+32 恒写
            E("winner_scope", tostring(ru32(p + 28) or 0))
            E("loser_scope", tostring(ru32(p + 32) or 0))

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
                local rv = w.ratio
                if rv == nil and e then rv = fix5(e + 112) end
                WE("ratio", SL.num(rv))
                -- §4.10.27 CWarScoreBreakdown (壳/内层布局 = 书) —
                -- 9 分量 + total_score_before 走 reader (已上提定案);
                -- first/second/captured_provinces reader 未暴露 → 内联
                if e then
                    local bk = e + 0x88
                    local ib = wb .. ".war_score_breakdown"
                        .. ".war_score_breakdown"
                    local bkd = w.war_score_breakdown
                    if bkd then
                        -- first/second tag idx@bk+8/+12, 门 idx>0
                        s = qtag(ru32(bk + 8))  if s then E(ib .. ".first", s) end
                        s = qtag(ru32(bk + 12)) if s then E(ib .. ".second", s) end
                        -- 9 个 fixed5 恒写 (writer 序; sent@+80 received@+88,
                        -- +72 不写 = 缓存和)
                        for _, f in ipairs({
                            "equipment_damage", "province_capture",
                            "air_damage_str", "strategic_air",
                            "sunk_ship", "convoy_attack",
                            "casualties", "lend_lease_sent",
                            "lend_lease_received" }) do
                            E(ib .. "." .. f, SL.num(bkd[f]))
                        end
                        -- captured_provinces: map {head@bk+96,size@bk+104},
                        -- size≠0 → #1 空格连升序
                        if (rp(bk + 104) or 0) ~= 0 then
                            local keys = map_keys(bk + 96)
                            if #keys > 0 then
                                E(ib .. ".captured_provinces.#1",
                                    table.concat(keys, " "))
                            end
                        end
                    end
                    -- total_score_before u32@W+144=e+0x110 恒写 (壳字段)
                    E(wb .. ".war_score_breakdown.total_score_before",
                        tostring(ru32(e + 0x110) or 0))
                    -- non_refunded_score u32@e+80 (b+16) 恒写
                    WE("non_refunded_score", tostring(ru32(e + 80) or 0))
                end
            end

            -- solo_winner (12552): ptr@p+368 → tag idx@obj+8, 门 ptr≠0+idx>0
            do
                local sp = rp(p + 368)
                if SL.kptr(sp) then
                    s = qtag(ru32(sp + 8)) if s then E("solo_winner", s) end
                end
            end

            -- losers 块: 指针数组 {d@p+272,c@p+284} 恒写; 块键 = tag(le+16),
            -- 块对象 = 元素本身 (writer sub_1414477E0)
            for _, l in ipairs((c.losers and c.losers.list) or {}) do
                local le = l.addr
                local lb = "losers." .. tostring(l.country)
                -- screening_ic u32@le+48 恒写 (0x3395)
                E(lb .. ".screening_ic", tostring(l.screening_ic or 0))
                if le then
                    -- civil_war_target (12619) 仅真写 yes, u8@le+176
                    if (ru8(le + 176) or 0) ~= 0 then
                        E(lb .. ".civil_war_target", "yes")
                    end
                    -- civil_war_enemy (14217) tag, 门 i32@le+180>0
                    s = qtag(ru32(le + 180))
                    if s then E(lb .. ".civil_war_enemy", s) end
                end
            end

            -- liberated (12581): 指针数组 {d@p+296,c@p+308}, c>0; 块对象
            -- elem+64 与 winner 同型 (同 sub_1424AD860 调用形态) — 块内容
            -- 布局同 winner, 锚件 0 例, 仅枚举键占位不如不发: 门控跳过。
            -- subject(13024)/history(10293) 同因布局未全定案不发射 (见头注)。

            -- civil_war_losers (12134): u32 idx 数组 {d@p+192,c@p+204}, c>0
            do
                local d, n = rp(p + 192), ru32(p + 204)
                if SL.kptr(d) and n and n > 0 and n < GAME.layout.lim.PTR_SANE then
                    local t = {}
                    for j = 0, n - 1 do
                        t[#t + 1] = O:tag(ru32(d + 4 * j)) or "?"
                    end
                    E("civil_war_losers.#1", table.concat(t, " "))
                end
            end
            -- done (12813): map {head@p+472,size@p+480} key=国家idx@node+28,
            -- size≠0 → #1 空格连 tag (中序 = idx 升序)
            if (rp(p + 480) or 0) ~= 0 then
                local t = {}
                for _, k in ipairs(map_keys(p + 472)) do
                    t[#t + 1] = O:tag(k) or tostring(k)
                end
                if #t > 0 then E("done.#1", table.concat(t, " ")) end
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
                local base624 = ru32(p + 624) or 0
                local t616 = rp(p + 616) or 0
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
