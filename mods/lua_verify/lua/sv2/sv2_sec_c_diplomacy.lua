-- sv2_sec_c_diplomacy.lua -- country.diplomacy 节点 savefull 直出 (csec)
-- + war_relation 深层 B 族增挂 country.diplomacy.warrel。
-- reader: objects_v2.lua §4 Country.diplomacy / autonomy / proposed_diplo
-- + misc_status_snapshot; 布局/写门/键序 = 书 §4.10.1-§4.10.18 各段。
-- ⚠ 关系型块通用: dim=first, R=second, mem 挂载侧不定 → 段内跨国家
-- 去重, 恒以 dim=first_tag 发 (rel_seen / warrel_seen); 深层 war/
-- puppet/nap.end_date 族由下方增挂的 country.diplomacy.warrel 覆盖。

local rp, ru32 = hoi4.read_u64, hoi4.read_u32

-- C 串 (U.cstr 同构; rule_overrides 段内内联用)
local function ro_cstr(p)
    if p and p >= 0x10000 then return hoi4.read_str(p) end
    return nil
end

-- save 侧写的关系型 (mem token 名)
-- ⚠ 勘误: war 关系对象 token@+8 = 14346 "war_relation" (与 save 同名),
-- 非 10637 "war" (旧键为死键, 留档不删); 补 3 型单侧挂载,
-- first/second/start_date 同 11 型通用模式。
local REL_TYPES = {
    market_access_rights = true, embargo = true, guarantee = true,
    non_aggression_pact = true, puppet = true, war = true,
    war_relation = true,
    military_access = true, lend_lease = true,
    equipment_purchase_contract_relation = true, air_base_access = true,
    offer_air_base_access = true,
    docking_rights = true, improve_relation = true, naval_blockade = true,
    send_attache = true,  -- JAP→FNG 首例 (first/second/start_date)
}

-- 关系块跨国家去重 (dim=first 恒发; mem 可能双侧挂载同一对象)。
-- rel_last_i 单调检测新一轮导出 (csec 国家循环 i 递增, 重跑归零附近)。
local rel_seen, rel_last_i = {}, nil

SV2.csec[#SV2.csec + 1] = { name = "country.diplomacy", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ci = ctx.i or 0
    if rel_last_i == nil or ci < rel_last_i then rel_seen = {} end
    rel_last_i = ci

    local okd, rdip = pcall(function() return c:diplomacy() end)
    if not okd then rdip = nil end

    -- ============ §4.10.1 CDiplomacyStatus 标量族 (dip = *(cc+3976)) ============
    if rdip then
        -- exile_army_leaders u32@dip+440; 恒写含 0
        emit(tag, "diplomacy.exile_army_leaders",
             SL.num(rdip.exile_army_leaders or 0))
        -- cached_allies_and_gurantees {d@880, c@892} u32 idx → tag
        for k, t in ipairs(rdip.cached_allies or {}) do
            local q = SL.Q(t)
            if q then
                emit(tag, "diplomacy.cached_allies_and_gurantees.#" .. k, q)
            end
        end
        -- faction_join_date hours@720; 哨兵不写
        local fjd = SL.date(rdip.faction_join_hours)
        if fjd then emit(tag, "diplomacy.faction_join_date", SL.Q(fjd)) end
        -- taken_lead {d@856, c@868} 12B {reason@0, tid@4, days@8}
        for ti, tl in ipairs(rdip.taken_lead or {}) do
            local b = "diplomacy.taken_lead_to_wars.#" .. ti
            local q = SL.Q(tl.tag)
            if q then emit(tag, b .. ".tag", q) end
            emit(tag, b .. ".reason", SL.num(tl.reason))
            emit(tag, b .. ".days", SL.num(tl.days))
        end
        for ii, rr in ipairs((rdip.incoming_diplomatic or {}).list or {}) do
            local b = "incoming_diplomatic_action." .. (ii - 1)
            emit(tag, b .. ".id", SL.idpair(rr.id, rr.idtype))
            local ab = b .. "." .. tostring(rr.tok)
            emit(tag, ab .. ".type", SL.num(rr.typ))
            local q
            q = SL.Q(rr.act);  if q then emit(tag, ab .. ".actor", q) end
            q = SL.Q(rr.oact); if q then emit(tag, ab .. ".original_actor", q) end
            q = SL.Q(rr.rec);  if q then emit(tag, ab .. ".recipient", q) end
            q = SL.Q(rr.orec); if q then emit(tag, ab .. ".original_recipient", q) end
            q = SL.date(rr.date_h)
            if q then emit(tag, ab .. ".date", SL.Q(q)) end
            emit(tag, ab .. ".value", SL.yn(rr.val))
            q = SL.date(rr.lcd_h)
            if q then emit(tag, ab .. ".last_command_date", SL.Q(q)) end
            emit(tag, ab .. ".envoy", SL.num(rr.envoy))
            emit(tag, ab .. ".initiator_matters", SL.yn(rr.im))
            if rr.oa then
                emit(tag, ab .. ".on_action", tostring(rr.oa)) end
            if (rr.hum or 0) ~= 0 then
                emit(tag, ab .. ".human", "yes") end
            -- act 地址 reader 未暴露 → 段内内联回取 (objects_v2 §4.4
            -- 同链; N=ii-1 容器序)。R 勘误: versus 发射已删 — reader
            -- versus@act+120 实为该类 division hybrid buffer
            -- (§4.10.14), 旧代码把 division 元素 u32 当 tag idx 发。
            -- market_access_rights 载荷: b@act+120 恒写 yes/no
            local act
            if rr.tok == "market_access_rights"
                or rr.tok == "send_volunteers"
                or rr.tok == "join_allies"
                or rr.tok == "call_allies"
                or rr.tok == "lend_lease"
                or rr.tok == "request_equipment_purchase" then
                local incobj2 = rp(ctx.cc + 4088)
                if SL.kptr(incobj2) then
                    local idd2 = rp(incobj2 + 8)
                    if SL.kptr(idd2) then
                        local ent2 = rp(idd2 + 8 * (ii - 1))
                        if SL.kptr(ent2) then act = rp(ent2 + 24) end
                    end
                end
            end
            -- token 校验 (13696=market_access_rights) 防 reader 跳条错位
            -- ⚠ 本块在文件级 local ru8 声明点 (warrel 段) 之前, 不可用
            -- ru8 上值 (nil 全局坑, 实证) → 直调 hoi4
            if rr.tok == "market_access_rights" then
                if SL.kptr(act) and ru32(act + 8) == 13696 then
                    emit(tag, ab .. ".show_show_result_message_to_actor",
                        SL.yn((hoi4.read_u8(act + 120) or 0) ~= 0))
                end
            end
            -- §4.10.14 send_volunteers 载荷 (布局/写门/B240 写序 = 书
            -- §4.10.14; given_air_volunteer_permission 同 value
            -- 无条件路径)
            if rr.tok == "send_volunteers" then
                if SL.kptr(act) and ru32(act + 8) == 13333 then
                    local dvd, dvc = rp(act + 120), ru32(act + 132)
                    if SL.kptr(dvd) and dvc and dvc > 0 and dvc < GAME.layout.lim.PTR_SANE then
                        for di = 0, dvc - 1 do
                            -- B240 写序 (ace killer_name 同款): id=元+4,
                            -- type=元+0 (id/type 颠倒实证)
                            local did = ru32(dvd + 8 * di + 4)
                            local dty = ru32(dvd + 8 * di)
                            if (did or 0) ~= 0 or (dty or 0) ~= 0 then
                                emit(tag, ab .. ".division",
                                    SL.idpair(did, dty))
                            end
                        end
                    end
                    emit(tag, ab .. ".given_air_volunteer_permission",
                        SL.yn((hoi4.read_u8(act + 176) or 0) ~= 0))
                end
            end
            -- §4.10.14 versus 载荷 (CJoinAllyAction/CCallAllyAction;
            -- 布局/写门 = 书 §4.10.14)。⚠ 偏移与 send_volunteers
            -- division buffer 按类复用 → 仅 join_allies/call_allies 发
            -- versus (call_allies 同为 C8A0 类写者); call_allies 尾部
            -- hidden b@act+144 书已收编, 待实例再接。
            if rr.tok == "join_allies" or rr.tok == "call_allies" then
                if SL.kptr(act) and (ru32(act + 8) == 13663
                    or ru32(act + 8) == 12233) then
                    local vvd, vvc = rp(act + 120), ru32(act + 132)
                    if SL.kptr(vvd) and vvc and vvc > 0 and vvc < 4096 then
                        local vtt = rp(ctx.gs + 0x358)
                        for vi = 0, vvc - 1 do
                            local vtid = ru32(vvd + 4 * vi)
                            local vtag = vtid and vtt
                                and hoi4.read_str(vtt + 32 * vtid) or nil
                            local vq = SL.Q(vtag and tostring(vtag) or nil)
                            if vq then
                                emit(tag, ab .. ".versus.#" .. (vi + 1), vq)
                            end
                        end
                    end
                end
            end
            -- §4.10.23 CLendLeaseBaseAction 载荷 (lend_lease)
            if rr.tok == "lend_lease" then
                if SL.kptr(act) and ru32(act + 8) == 12618 then
                    for _, pd in ipairs{
                        { "equipment", 136 },
                        { "production_percentage", 200 },
                        { "once", 264 } } do
                        local sub = act + pd[2]
                        local pdta, pcnt = rp(sub + 32), ru32(sub + 44)
                        local paz = (hoi4.read_u8(sub + 56) or 0)
                        if SL.kptr(pdta) and pcnt and pcnt > 0
                            and pcnt < 4096 then
                            local pseq = SL.seqc()
                            for pk = 0, pcnt - 1 do
                                local eb = pdta + 16 * pk
                                local vp, amt = rp(eb), rp(eb + 8) or 0
                                amt = GAME.layout.as_i64(amt)
                                if (amt ~= 0 or paz ~= 0)
                                    and SL.kptr(vp) then
                                    local ek2 = ab .. "." .. pd[1] .. "."
                                        .. pseq("equipment") .. "."
                                    emit(tag, ek2 .. "id",
                                        SL.idpair(ru32(vp + 12),
                                            ru32(vp + 8)))
                                    emit(tag, ek2 .. "amount",
                                        SL.num(amt / 100000))
                                end
                            end
                        end
                        emit(tag, ab .. "." .. pd[1]
                            .. ".allow_zero_entries", SL.yn(paz))
                    end
                    local fdbits = rp(act + 120) or 0
                    local okd2, fdv = pcall(string.unpack, "<d",
                        string.pack("<I8", fdbits))
                    if not okd2 then fdv = fdbits / 100000 end
                    emit(tag, ab .. ".fuel_daily",
                        string.format("%.5f", fdv))
                    local fpp = rp(act + 128) or 0
                    fpp = GAME.layout.as_i64(fpp)
                    emit(tag, ab .. ".fuel_percentage",
                        SL.num(fpp / 100000))
                end
            end
            -- §4.10.25 CRequestEquipmentPurchaseAction 载荷
            -- (request_equipment_purchase; def 216B 内嵌 @act+120, 与合同/
            -- requests 同 writer sub_140DF1EC0; request = CIdentifier
            -- @act+336, 键 12613)。载荷读取住 reader (R:contract_def_read),
            -- 本段只发射。def 本体起点 = act + 120 → 基址 act + 96。
            if rr.tok == "request_equipment_purchase" then
                if SL.kptr(act) and ru32(act + 8) == 13289 then
                    local DP = ab .. ".contract_definition."
                    SL.def_emit(ctx.O, emit, tag, DP, act + 120)
                    local rty, rid = ru32(act + 336), ru32(act + 340)
                    if (rid or 0) ~= 0 or (rty or 0) ~= 0 then
                        emit(tag, ab .. ".request", SL.idpair(rid, rty))
                    end
                end
            end
        end
    end

    -- ============ §4.10.2 CRelationStatus active_relations 逐对方国 ============
    -- rs 内联回取链 (reader 未暴露 rs 地址; rec.idx = 对方槽位;
    -- dip=*(cc+3976), rd=*(dip+8), rs=*(rd+8*idx)) — rli/llth 族用
    local dip2 = rp(ctx.cc + 3976)
    local dip2_rd = SL.kptr(dip2) and rp(dip2 + 8) or nil
    -- ⚠ 迁移: rules_base 静态搬家 0x33180F0 → 0x33304C0 (旧 dump
    -- qword_1433180F0 四函数经旧→新函数映射对新 dump 一致引用
    -- qword_1433304C0; 活体 28 槽键名全解析实证)。objects_v2 reader
    -- 已同址读 (rec.rule_overrides 可用); 本段仍直走 rs 槽。
    local ro_rules = rp(ctx.BASE + 0x33304C0)
    if not SL.kptr(ro_rules) then ro_rules = nil end
    local ro_tok = SL.tok
    for _, rec in ipairs((rdip and rdip.relations) or {}) do
        local R = rec.tag
        if R and R ~= "" and R ~= "---" then
            local base = "diplomacy.active_relations." .. R
            -- recently_leased_ic + lend_lease_to_allies_history
            -- (§4.10.2; 布局/写门 = 书 §4.10.2)
            local rs2 = dip2_rd and rp(dip2_rd + 8 * (rec.idx or -1)) or nil
            if SL.kptr(rs2) then
                local rli = ru32(rs2 + 804)
                if rli and rli > 0 then
                    emit(tag, base .. ".recently_leased_ic", SL.num(rli)) end
                local lg1, lg2 = rp(rs2 + 576) or 0, rp(rs2 + 584) or 0
                local lg3, lg4 = rp(rs2 + 592) or 0, rp(rs2 + 600) or 0
                if lg1 ~= 0 or lg2 ~= 0 or lg3 ~= 0 or lg4 ~= 0 then
                    local lb = base .. ".lend_lease_to_allies_history"
                    emit(tag, lb .. ".ic_given", SL.num(lg1 / 100000))
                    emit(tag, lb .. ".fuel_given", SL.num(lg2 / 100000))
                    emit(tag, lb .. ".ic_received", SL.num(lg3 / 100000))
                    emit(tag, lb .. ".fuel_received", SL.num(lg4 / 100000))
                end
            end
            if rec.cached_sum and rec.cached_sum ~= 0 then
                emit(tag, base .. ".cached_sum", SL.num(rec.cached_sum)) end
            -- attitude: 默认 "noattitude" 不写 (differ: 182,922 MISS_SAVE
            -- 全 = 默认态度指针恒在, writer 仅非默认写)
            if rec.attitude and rec.attitude ~= "" and rec.attitude ~= "noattitude" then
                emit(tag, base .. ".attitude", SL.Q(rec.attitude)) end
            if rec.border_friction and rec.border_friction ~= 0 then
                emit(tag, base .. ".border_friction_claim",
                     SL.num(rec.border_friction)) end
            local d = rec.last_send_diplomat
            if d then emit(tag, base .. ".last_send_diplomat", SL.Q(d)) end
            d = rec.trade
            if d then emit(tag, base .. ".trade", SL.Q(d)) end
            d = rec.trade_equipment
            if d then emit(tag, base .. ".trade_equipment", SL.Q(d)) end
            d = rec.truce_until
            if d then emit(tag, base .. ".truce_until", SL.Q(d)) end
            -- modifiers 名串集合 (名@e+424; 0x2965 {d@rs+280, c@rs+292})
            for _, mn in ipairs(rec.modifiers or {}) do
                local q = SL.Q(mn)
                if q then emit(tag, base .. ".modifier", q) end
            end
            -- §4.10.2 opinions (CTimedOpinionModifier, rs+256):
            -- opinion[N] N=mem 容器序 1 基, 无号=1
            for oi, om in ipairs(rec.opinion_modifiers or {}) do
                local ob = base .. ".opinion" ..
                    (oi > 1 and ("[" .. oi .. "]") or "")
                if om.name then
                    emit(tag, ob .. ".modifier", tostring(om.name)) end
                if om.date then
                    emit(tag, ob .. ".date", SL.Q(om.date)) end
                emit(tag, ob .. ".value", SL.num(om.value or 0))
                -- decay 仅真写 yes (b@mo+56, writer sub_140A73BA0; 3 例)
                if om.decay then
                    emit(tag, ob .. ".decay", "yes") end
                if om.dnx then
                    emit(tag, ob .. ".do_not_expire", "yes") end
            end
            -- §4.10.2 rule_overrides (CRuleOverrides@rs+808; 布局/写门 =
            -- 书 §4.10.2)。⚠ 迁移临时内联: 段内按 reader 同构直走 rs 槽,
            -- reader 同源 (rec.rule_overrides) 已可用 → 本块可回收 (未做)。
            if SL.kptr(rs2) then
                local rob = base .. ".rule_overrides.override"
                for k = 0, 27 do
                    local key = ro_rules
                        and ro_tok(ru32(ro_rules + 56 * k + 40)) or nil
                    -- 槽 flag 位: ≠0 开, 值 1 = yes
                    local flag = ru32(rs2 + 816 + 4 * k)
                    if flag and flag ~= 0 then
                        if key then
                            emit(tag, rob .. "." .. tostring(key),
                                SL.yn(flag == 1))
                        end
                        emit(tag, rob .. ".desc", '"' ..
                            tostring(ro_cstr(rs2 + 928 + 32 * k) or "")
                            .. '"')
                    end
                    -- 槽 vec (条件覆盖, 48B 元)
                    local dd = rp(rs2 + 1824 + 24 * k)
                    local cnt = ru32(rs2 + 1836 + 24 * k)
                    if cnt and cnt > 0 and cnt < 64 and SL.kptr(dd) then
                        for j = 0, cnt - 1 do
                            local e = dd + 48 * j
                            local p = rp(e + 8)
                            if key then
                                emit(tag, rob .. "." .. tostring(key),
                                    SL.yn((ru32(e) or 0) == 1))
                            end
                            emit(tag, rob .. ".desc", '"' ..
                                tostring(ro_cstr(e + 16) or "") .. '"')
                            local trig = SL.kptr(p)
                                and ro_cstr(p + 96) or nil
                            if trig and trig ~= "-" then
                                local q = SL.Q(trig)
                                if q then emit(tag, rob .. ".trigger", q) end
                            end
                        end
                    end
                end
            end
            -- §4.10.3 关系对象基类: 关系型块 dim=first, R=second 恒发 + 跨国去重
            for _, rel in ipairs(rec.relations or {}) do
                local tn = rel.token and SL.tok(rel.token) or nil
                tn = tn and tostring(tn) or nil
                local f, s = rel.first_tag, rel.second_tag
                if tn and REL_TYPES[tn] and f and s
                    and f ~= "" and s ~= "" then
                    local dk = tn .. "|" .. f .. "|" .. s
                    if not rel_seen[dk] then
                        rel_seen[dk] = true
                        local st = (tn == "war") and "war_relation" or tn
                        local rb = "diplomacy.active_relations." .. s
                            .. "." .. st
                        emit(f, rb .. ".first", SL.Q(f))
                        emit(f, rb .. ".second", SL.Q(s))
                        if rel.start_date then
                            emit(f, rb .. ".start_date",
                                 SL.Q(rel.start_date))
                        end
                    end
                end
            end
        end
    end

    -- ============ §4.10.9 CCurrentAutonomyStatus (autonomy_state, @dip+848) ====
    local oka, au = pcall(function() return c:autonomy() end)
    if oka and au then
        -- progress i32@au+8 ×1e-5 (mem 定点; 存档 4200 ↔ mem 420000000)
        -- 引擎按有符号打印 (-67.66813 ↔ u32 4288200483)
        local prg = au.progress or 0
        prg = GAME.layout.as_i32(prg)
        emit(tag, "diplomacy.autonomy_state.progress",
             SL.num(prg * 1e-5))
        -- lm hours@+96: 恒写, 哨兵 43808760 → "1.1.1.1" (19/20 例)
        local lm = SL.date(au.lm_hours) or "1.1.1.1"
        emit(tag, "diplomacy.autonomy_state.last_modified_autonomy_date",
             '"' .. lm .. '"')
        if au.current_state and au.current_state ~= "" then
            emit(tag, "diplomacy.autonomy_state.current_state",
                 SL.Q(au.current_state)) end
        if au.prev_state and au.prev_state ~= "" then
            emit(tag, "diplomacy.autonomy_state.prev_state",
                 SL.Q(au.prev_state)) end
        if au.next_state and au.next_state ~= "" then
            emit(tag, "diplomacy.autonomy_state.next_state",
                 SL.Q(au.next_state)) end
        for _, pn in ipairs(au.path or {}) do
            local q = SL.Q(pn)
            if q then emit(tag, "diplomacy.autonomy_state.path", q) end
        end
        -- effect[N]: value=i64 定点×1e-5 / desc 引号 / date hours→串;
        -- N=mem 容器序 (验证序一致; classdiff 注内存序≠存档序
        -- 为他存档情形, 见不确定点)
        for ei, ee in ipairs(au.effects or {}) do
            local eb = "diplomacy.autonomy_state.effect" ..
                (ei > 1 and ("[" .. ei .. "]") or "")
            emit(tag, eb .. ".value", SL.num((ee.value or 0) * 1e-5))
            local q = SL.Q(ee.desc)
            if q then emit(tag, eb .. ".desc", q) end
            local ed = SL.date(ee.hours)
            if ed then emit(tag, eb .. ".date", SL.Q(ed)) end
        end
    end

    -- ============ §4.10.8 proposed 外交行动条目 (proposed_diplo_action
    -- {d@dip+768, c@dip+780},
    -- 40B 条 {index u32@0, date hours@16, action tok@32}) ============
    local okp, dp = pcall(function() return c:proposed_diplo() end)
    if okp and dp then
        for di, de in ipairs(dp.list or {}) do
            local pb = "diplomacy.proposed_diplo_action" ..
                (di > 1 and ("[" .. di .. "]") or "")
            if de.action then
                emit(tag, pb .. ".action", tostring(de.action)) end
            emit(tag, pb .. ".index", SL.num(de.index))
            local q = SL.date(de.hours)
            if q then emit(tag, pb .. ".date", SL.Q(q)) end
        end
    end

    -- ============ §4.10.1 wargoals 容器 + §4.10.4 CWargoal 元素 (段内内联,
    -- dip = *(cc+3976)) ============
    do
        local dip = rp(ctx.cc + 3976)
        if SL.kptr(dip) then
            -- diplomacy.naval_blockade 仅真写 yes (b u8@dip+641; writer
            -- sub_140D32BD0 L249-251, 门 v41≠0; GER/USA 实证)
            -- ⚠ 本段在文件级 local ru8 声明点之前 → 直调 hoi4.read_u8
            if (hoi4.read_u8(dip + 641) or 0) ~= 0 then
                emit(tag, "diplomacy.naval_blockade", "yes") end
            -- diplomacy.captured {d@dip+1000, c u32@dip+1012}, 元素 8B 紧致
            -- 对 {type@0, id@4} (writer sub_140D32BD0 尾部, 门 c>0);
            -- #N 1 基容器序, "id=N type=T" (GER {731,733} 全中)
            local cd2, cc2 = rp(dip + 1000), ru32(dip + 1012)
            if SL.kptr(cd2) and cc2 and cc2 > 0 and cc2 < GAME.layout.lim.PTR_SANE then
                for k = 0, cc2 - 1 do
                    emit(tag, "diplomacy.captured.#" .. (k + 1),
                        SL.idpair(ru32(cd2 + 8 * k + 4), ru32(cd2 + 8 * k)))
                end
            end
            local wd, wc = rp(dip + 128), ru32(dip + 140)
            local tt = rp(ctx.gs + 0x358)
            -- available_wargoals {d@dip+104, c@dip+116}: 元 = ref 指针,
            -- id 对@ref+8 (+8 type / +12 id) (writer sub_140D32BD0
            -- 0x337C 块 → 元素块 0x2CE2 提取件折叠叶名 "wargoal";
            -- ERI/FIR/ALO/SON 4 例)
            do
                local awd, awc = rp(dip + 104), ru32(dip + 116)
                if SL.kptr(awd) and awc and awc > 0 and awc < GAME.layout.lim.PTR_SANE then
                    for q2 = 0, awc - 1 do
                        local ae = rp(awd + 8 * q2)
                        if SL.kptr(ae) then
                            emit(tag, "diplomacy.available_wargoals.wargoal",
                                SL.idpair(ru32(ae + 12), ru32(ae + 8)))
                        end
                    end
                end
            end
            local tt = rp(ctx.gs + 0x358)
            if SL.kptr(wd) and wc and wc > 0 and wc < GAME.layout.lim.PTR_SANE then
                local wseq = SL.seqc()
                for q = 0, wc - 1 do
                    local e = rp(wd + 8 * q)
                    if SL.kptr(e) then
                        local wt = SL.tok(ru32(e + 48))
                        if wt then
                            wt = tostring(wt)
                            local wb = "diplomacy.wargoals." .. wseq(wt)
                            -- id 对: id@+12, type@+8
                            emit(tag, wb .. ".id",
                                 SL.idpair(ru32(e + 12), ru32(e + 8)))
                            local atid, rtid = ru32(e + 56), ru32(e + 60)
                            if SL.kptr(tt) and atid and atid > 0 then
                                local a = hoi4.read_str(tt + 32 * atid)
                                local qa = SL.Q(a)
                                if qa then
                                    emit(tag, wb .. ".wargoaldata_actor", qa)
                                end
                            end
                            if SL.kptr(tt) and rtid and rtid > 0 then
                                local r = hoi4.read_str(tt + 32 * rtid)
                                local qr = SL.Q(r)
                                if qr then
                                    emit(tag, wb .. ".wargoaldata_recipient",
                                         qr)
                                end
                            end
                            emit(tag, wb .. ".type", wt)
                            -- puppets ({d@e+120, c u32@e+132}
                            -- 4B tag id, c≠0 才写; 存档 puppets={ BEL }
                            -- 行内块 → 提取器裸叶, 多元空格连; GER→BEL
                            -- tid=4 实证)
                            do
                                local ppd, ppc = rp(e + 120), ru32(e + 132)
                                if SL.kptr(ppd) and ppc and ppc > 0
                                    and ppc < GAME.layout.lim.PTR_SANE then
                                    local pts = {}
                                    for pk = 0, ppc - 1 do
                                        local ptid = ru32(ppd + 4 * pk)
                                        if SL.kptr(tt) and ptid
                                            and ptid > 0 and ptid < 4096 then
                                            pts[#pts + 1] =
                                                hoi4.read_str(
                                                    tt + 32 * ptid)
                                        end
                                    end
                                    if #pts > 0 then
                                        emit(tag, wb .. ".puppets",
                                            table.concat(pts, " "))
                                    end
                                end
                            end
                            -- states (take_state/_focus 等; §4.10.4
                            -- 布局/写门 = 书; flat 空格连接 = 块内
                            -- 列表形态)
                            local sd2, sc2 = rp(e + 0x48), ru32(e + 0x50)
                            if SL.kptr(sd2) and sc2 and sc2 > 0 and sc2 < GAME.layout.lim.PTR_SANE then
                                local ids = {}
                                for k = 0, sc2 - 1 do
                                    local sp = rp(sd2 + 8 * k)
                                    -- id≠0 门 + CState vtable 门 (SOV
                                    -- 尾槽 = 悬垂指针, 垃圾 vt 出偶然
                                    -- id=2, 引擎不写)
                                    local svt = sp and rp(sp) or nil
                                    -- 精确 vt 匹配 (勘误: 模块
                                    -- 范围门不够 — 悬垂槽首 qword 可恰落
                                    -- 模块区间出垃圾 id; CState vt 直证)
                                    if SL.kptr(sp) and svt
                                        and svt == ctx.BASE + GAME.layout.vt.CState then
                                        local sid = ru32(sp + 88) or 0
                                        if sid > 0 then
                                            ids[#ids + 1] = tostring(sid)
                                        end
                                    end
                                end
                                if #ids > 0 then
                                    emit(tag, wb .. ".states",
                                        table.concat(ids, " "))
                                end
                            end
                            -- expire hours u32@e+0x20 (CGameDate 槽@+0x28)
                            -- 门 = unset 43826280 不写 (GER focus×5 实证)
                            -- + SL.date 哨兵; GER/SOV/HUN take_state 3 例
                            -- 对档全中
                            local xh = ru32(e + 0x20)
                            if xh and xh ~= 0 and xh ~= 43826280 then
                                local xd = SL.date(xh)
                                if xd then
                                    emit(tag, wb .. ".expire", SL.Q(xd)) end
                            end
                        end
                    end
                end
            end
        end
    end

    -- §4.10.18 投降/流亡/志愿航空队族 (dip 侧; reader misc_status_snapshot)
    local okm, snap = pcall(function() return c:misc_status_snapshot() end)
    if okm and snap then
        if snap.dirty then
            emit(tag, "dirty_controlled_states", "yes") end
        if snap.removed_prov then
            emit(tag, "removed_controlled_province", "yes") end
        local rvseq = 0  -- 重复块第 2 起编 [N] (提取器契约)
        for _, pair in ipairs(snap.recv_vol or {}) do
            local t, cnt = tostring(pair):match("^(.-)=(%d+)$")
            if t then
                rvseq = rvseq + 1
                local rvp = "received_air_volunteer_permission"
                    .. (rvseq > 1 and ("[" .. rvseq .. "]") or "")
                emit(tag, rvp .. ".tag", SL.Q(t))
                emit(tag, rvp .. ".count", SL.num(tonumber(cnt)))
            end
        end
        for _, t in ipairs(snap.given_vol or {}) do
            local q = SL.Q(t)
            if q then emit(tag, "given_air_volunteer_permission", q) end
        end
        if snap.capitulated then
            emit(tag, "diplomacy.capitulated", "yes")
            local cd = SL.date(snap.cap_date_h)
            if cd then
                emit(tag, "diplomacy.capitulated_date", SL.Q(cd)) end
        end
        local sd = SL.date(snap.last_surr_h)
        if sd then
            emit(tag, "diplomacy.last_surrender_date", SL.Q(sd)) end
        if snap.hosting then
            emit(tag, "diplomacy.hosting_our_government_in_exile",
                 SL.Q(snap.hosting)) end
        if snap.legitimacy then
            emit(tag, "diplomacy.legitimacy", SL.num(snap.legitimacy)) end
        -- we_host: writer sub_140D32BD0 单块列表 (AF2C0+循环+AEAC0) →
        -- 提取件单行 #1 全部引号 tag 空格连接 (ENG 6 tag 实证);
        -- 旧 #N-per-tag 形态只在单元素时巧合成立
        do
            local whl = {}
            for _, t in ipairs(snap.we_host or {}) do
                local q = SL.Q(t)
                if q then whl[#whl + 1] = q end
            end
            if #whl > 0 then
                emit(tag, "diplomacy.governments_in_exile_we_host.#1",
                    table.concat(whl, " "))
            end
        end
    end
end }

-- ======================================================================
-- war_relation 深层 B 族 (增挂独立 csec; 只增不改, 与上段并存)
-- 布局与写门 = 书 §4.10.3 关系对象基类 / §4.10.4 war / §4.10.5 war_score /
-- §4.10.6 hostility_reason / §4.10.7 puppet。
-- 链 = rs+232 关系向量 (勘误: 对象 token@+8 = 14346 "war_relation",
-- 非 10637); reader (objects_v2 §4.4) 已上提 rec.relations[j].addr,
-- 本段走 reader 不内联枚举 (分层纪律)。
-- ⚠ war_score 视角由引擎在子对象内换好, 读取侧零交换 (§4.10.5);
-- hostility_reason instigator@+352 / defender@+348 方向勿反 (§4.10.6)。
-- ======================================================================

local ru8 = hoi4.read_u8
local SL = SV2.lib   -- 供文件级 helper 用 (emit 内另有同名 local, 同物)

-- §4.10.6 hostility_reason 枚举 (writer switch 实证): 6 (或表外) = 不写
local WARREL_REASON = { [0] = "war", "puppet", "ally", "asked_to_join",
    "guarantee", "not_applicable" }

-- fixed5 i64 → 浮点; /100000 不用 *1e-5 (1ulp 整值判定坑, 同 objects_v2 U.fix5)
local function warrel_fix5(a)
    local v = rp(a)
    if not v then return nil end
    return v / 100000
end

-- captured_provinces 中序 walker (照 objects_v2 L330-360 RPM 模式,
-- key 改 node+0x1C, 无 value; 中序 = key 升序 = 存档序)
local function warrel_map_keys(base)
    local keys = {}
    local mhead = rp(base)
    if not SL.kptr(mhead) then return keys end
    local isnilb = function(p)
        return (not p) or p < 0x10000 or ((ru32(p + 25) & 0xFF) ~= 0)
    end
    local node = rp(mhead)   -- head._Left = 最小节点
    local guard = 0
    while node and not isnilb(node) and guard < 4096 do
        guard = guard + 1
        keys[#keys + 1] = tostring(ru32(node + 28) or 0)
        local r = rp(node + 16)
        if r and not isnilb(r) then
            node = r
            while true do
                local l = rp(node)
                if l and not isnilb(l) then node = l else break end
            end
        else
            while true do
                local p = rp(node + 8)
                if not p or isnilb(p) then node = nil break end
                local from_right = (rp(p + 16) == node)
                node = p
                if not from_right then break end
            end
        end
    end
    return keys
end

-- 关系深层族跨国家去重 (war 单侧挂载; dim=first_tag 恒发, 同 rel_seen 模式)
-- 段体 = §4.10.3 关系对象/war 基类 (cancel/end_date 通用) +
-- §4.10.5 war_score 子对象 (ws 112B: first/second tag; casualties 四连 @wr+80..104)
local warrel_seen, warrel_last_i = {}, nil

SV2.csec[#SV2.csec + 1] = { name = "country.diplomacy.warrel",
    emit = function(ctx)
    local SL, emit, c = SV2.lib, ctx.emit, ctx.country
    if not c then return end
    local ci = ctx.i or 0
    if warrel_last_i == nil or ci < warrel_last_i then warrel_seen = {} end
    warrel_last_i = ci
    local okd, rdip = pcall(function() return c:diplomacy() end)
    if not okd or not rdip then return end
    local tt = ctx.gs and rp(ctx.gs + 0x358) or nil
    local function tagof(tid)   -- tag id → 三字串 (§1.2 tag 串表; war_score 子对象/13085 用)
        if not (tid and tid > 0 and SL.kptr(tt)) then return nil end
        local t = hoi4.read_str(tt + 32 * tid)
        if t and t ~= "" and t ~= "---" then return t end
        return nil
    end
    for _, rec in ipairs(rdip.relations or {}) do
        for _, rel in ipairs(rec.relations or {}) do
            local tn = rel.token and SL.tok(rel.token) or nil
            tn = tn and tostring(tn) or nil
            local f, s, ra = rel.first_tag, rel.second_tag, rel.addr
            if tn and REL_TYPES[tn] and f and s and f ~= "" and s ~= ""
                and SL.kptr(ra) then
                local dk = tn .. "|" .. f .. "|" .. s
                if not warrel_seen[dk] then
                    warrel_seen[dk] = true
                    -- mem token 与 save 同名 (war_relation=14346 直发)
                    local rb = "diplomacy.active_relations." .. s .. "." .. tn
                    -- 基类通用 (全 11 型): cancel / end_date
                    if (ru8(ra + 72) or 0) ~= 0 then
                        emit(f, rb .. ".cancel", "yes") end
                    local sh, eh = ru32(ra + 32), ru32(ra + 56)
                    if eh and sh and eh > sh then
                        local d = SL.date(eh)
                        if d then
                            emit(f, rb .. ".end_date", SL.Q(d))
                        end
                    end
                    if tn == "war_relation" then
                        local wr = ra
                                        -- casualties 四连 i64 原值, 恒写
                                        emit(f, rb .. ".first_casualties",
                                            SL.num(rp(wr + 80) or 0))
                                        emit(f, rb .. ".second_casualties",
                                            SL.num(rp(wr + 88) or 0))
                                        emit(f, rb .. ".first_unknown_casualties",
                                            SL.num(rp(wr + 96) or 0))
                                        emit(f, rb .. ".second_unknown_casualties",
                                            SL.num(rp(wr + 104) or 0))
                                        -- war_score 两视角内嵌子对象 (112B)
                                        for vi = 1, 2 do
                                            local ws = wr + (vi == 1 and 112 or 224)
                                            local wb = rb .. "." .. (vi == 1
                                                and "war_score_first_vs_second"
                                                or "war_score_second_vs_first")
                                            local q = tagof(ru32(ws + 8))
                                            if q then
                                                emit(f, wb .. ".first", SL.Q(q)) end
                                            q = tagof(ru32(ws + 12))
                                            if q then
                                                emit(f, wb .. ".second", SL.Q(q)) end
                                            for _, fld in ipairs{
                                                { "equipment_damage", 16 },
                                                { "province_capture", 24 },
                                                { "air_damage_str", 32 },
                                                { "strategic_air", 40 },
                                                { "sunk_ship", 48 },
                                                { "convoy_attack", 56 },
                                                { "casualties", 64 },
                                                { "lend_lease_sent", 80 },
                                                { "lend_lease_received", 88 } } do
                                                emit(f, wb .. "." .. fld[1],
                                                    SL.num(warrel_fix5(
                                                        ws + fld[2]) or 0))
                                            end
                                            -- captured_provinces std::map 中序
                                            local keys =
                                                warrel_map_keys(ws + 96)
                                            if #keys > 0 then
                                                emit(f, wb ..
                                                    ".captured_provinces.#1",
                                                    table.concat(keys, " "))
                                            end
                                        end
                                        emit(f, rb .. ".threat",
                                            SL.num(warrel_fix5(wr + 336) or 0))
                                        emit(f, rb .. ".first_was_instigator",
                                            SL.yn((ru8(wr + 344) or 0) ~= 0))
                                        -- first/second_wargoals 8B 紧致对
                                        for _, wg in ipairs{
                                            { "first_wargoals", 360, 372 },
                                            { "second_wargoals", 384, 396 } } do
                                            local fwd = rp(wr + wg[2])
                                            local fwc = ru32(wr + wg[3])
                                            if SL.kptr(fwd) and fwc
                                                and fwc > 0 and fwc < GAME.layout.lim.PTR_SANE then
                                                for k = 0, fwc - 1 do
                                                    emit(f, rb .. "." .. wg[1]
                                                        .. ".wargoal",
                                                        SL.idpair(
                                                            ru32(fwd + 8 * k + 4),
                                                            ru32(fwd + 8 * k)))
                                                end
                                            end
                                        end
                                        -- wargoals (token 13085): CWargoal*
                                        -- 指针动态块; 全空, 形态照
                                        -- diplomacy.wargoals 推测 (未实证)
                                        local gd, gc = rp(wr + 408),
                                            ru32(wr + 420)
                                        if SL.kptr(gd) and gc
                                            and gc > 0 and gc < GAME.layout.lim.PTR_SANE then
                                            local wseq = SL.seqc()
                                            for k = 0, gc - 1 do
                                                local e = rp(gd + 8 * k)
                                                if SL.kptr(e) then
                                                    local wt = SL.tok(
                                                        ru32(e + 48))
                                                    if wt then
                                                        wt = tostring(wt)
                                                        local gb = rb
                                                            .. ".wargoals."
                                                            .. wseq(wt)
                                                        emit(f, gb .. ".id",
                                                            SL.idpair(
                                                                ru32(e + 12),
                                                                ru32(e + 8)))
                                                        local q2 = tagof(
                                                            ru32(e + 56))
                                                        if q2 then
                                                            emit(f, gb ..
                                                                ".wargoaldata_actor",
                                                                SL.Q(q2)) end
                                                        q2 = tagof(ru32(e + 60))
                                                        if q2 then
                                                            emit(f, gb ..
                                                                ".wargoaldata_recipient",
                                                                SL.Q(q2)) end
                                                        emit(f, gb .. ".type", wt)
                                                    end
                                                end
                                            end
                                        end
                                        -- hostility_reason: ⚠ instigator 在
                                        -- +352, defender 在 +348 (方向勿反)
                                        local hi, hd = ru32(wr + 352),
                                            ru32(wr + 348)
                                        if hi and WARREL_REASON[hi] then
                                            emit(f, rb ..
                                                ".hostility_reason_instigator",
                                                WARREL_REASON[hi]) end
                                        if hd and WARREL_REASON[hd] then
                                            emit(f, rb ..
                                                ".hostility_reason_defender",
                                                WARREL_REASON[hd]) end
                    elseif tn == "puppet" then
                        -- autonomy_state ptr@+88 → SSO 串@obj+8
                        local ap = rp(ra + 88)
                        if SL.kptr(ap) then
                            local nm = SL.sso(ap + 8)
                            local q = SL.Q(nm)
                            if q then
                                emit(f, rb .. ".autonomy_state", q) end
                        end
                        -- value fixed5@+96, 门 raw≠0
                        local rawv = rp(ra + 96)
                        if rawv and rawv ~= 0 then
                            emit(f, rb .. ".value",
                                SL.num(warrel_fix5(ra + 96) or 0)) end
                    end
                end
            end
        end
    end
end }

