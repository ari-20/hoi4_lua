-- sv2_sec_c_misc_tails.lua -- country 残族扫尾 savefull 直出 (csec)
-- 覆盖 30 族: cores / claims / dynamic_modifier / logistics /
-- reinforcement / volunteers_sent / navy_theater /
-- cached_navy_strength / num_ships / naval_headquarter_status /
-- delayed_event / original_research_slots / focus_cost_reduction /
-- templates_locked / pride_of_the_fleet / invasion_report /
-- civil_war_target / reserved_dynamic_country / external_rules(.override) /
-- collaboration / major / is_top_ic_country / landlocked_start / buildings /
-- num_armies_in_combat / coastal_protection_ratio /
-- heroes_dying_war_support_penalty / convoys_destroyed / reason /
-- original_tag / operative_codenames_tracker。
-- 各块布局/写门/键序 = 书 §4.3.1/§4.3.8/§4.3.11/§4.3.12/§4.3.13 表行。
-- 分工边界 (不重复发射):
-- navy_theater.theater_group.{id,name,fleet} = sv2_sec_c_strategic_navy.lua
-- (本段仅补 is_important 叶);
-- focus_cost_reduction.* = sv2_sec_c_focus.lua;
-- pride_of_the_fleet_date_lost / capital 等 16 键 + ace = country_scalars 段;
-- division/ship/railway_gun_names_tracker = names_trackers 段 (本段仅
-- operative_codenames mode 3)。

-- 州指针→state_id 映射 → 委派 GAME.layout.state_index_map (唯一实现, 含代际戳)。
-- 原有本地副本 (独立缓存表, 永不失效) 与 objects_v2 §24.1 同构重复, 已删。
local function sid_map(gs)
    return GAME.layout.state_index_map(gs)
end

SV2.csec[#SV2.csec + 1] = { name = "country.misc_tails", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    local cc, O, gs, BASE = ctx.cc, ctx.O, ctx.gs, ctx.BASE
    if not cc then return end
    local rp, ru32, ru8, kptr = SL.rp, SL.ru32, SL.ru8, SL.kptr
    -- i64 ×1e-5 定点 (objects_v2 U.fix5 同构; 必须 /100000 不能 *1e-5)
    local fix5 = GAME.layout.fix5
    -- u32 ≠0 才写标量
    local function u32_nz(key, off)
        local v = ru32(cc + off)
        if v and v ~= 0 then emit(tag, key, SL.num(v)) end
    end
    -- u8 仅真写 yes 标量
    local function flag_yes(key, off)
        if (ru8(cc + off) or 0) ~= 0 then emit(tag, key, "yes") end
    end
    -- tag 串 (tid>0; ""/"---" 不写)
    local function tagstr(tid)
        if not tid or tid <= 0 then return nil end
        local s = O:tag(tid)
        if s and s ~= "" and s ~= "---" then return s end
        return nil
    end

    -- ===== cores (§4.3.11 表 +1192 行; 单行保序) =====
    do
        local vd, vc = rp(cc + 1192), ru32(cc + 1204)
        if kptr(vd) and vc and vc > 0 and vc < 4096 then
            local m = sid_map(gs)
            local ids = {}
            for k = 0, vc - 1 do
                local p = rp(vd + 8 * k)
                ids[#ids + 1] = tostring((p and m[p]) or 0)
            end
            emit(tag, "cores", table.concat(ids, " "))
        end
    end
    -- ===== claims (§4.3.11 表 +1216 行; 单行, 州 id 列表) =====
    -- 集成勘误: 元素 = 8B CState 指针 (非 u32 id!) — count=元素数,
    -- stride 8 读指针经 gs+0x2C8 反查 (与 cores 同构), 保向量序
    do
        local cld, clc = rp(cc + 1216), ru32(cc + 1228)
        if kptr(cld) and clc and clc > 0 and clc < 4096 then
            local m = sid_map(gs)
            local ids = {}
            for k = 0, clc - 1 do
                local p = rp(cld + 8 * k)
                ids[#ids + 1] = tostring((p and m[p]) or 0)
            end
            emit(tag, "claims", table.concat(ids, " "))
        end
    end
    -- ===== dynamic_modifier (§4.3.8 CModifier 动态修正容器, cc+3672) =====
    do
        local vd, vc = rp(cc + 3672 + 40), ru32(cc + 3672 + 52)
        if kptr(vd) and vc and vc > 0 and vc < GAME.layout.lim.PTR_SANE then
            local seq = SL.seqc()
            for i = 0, vc - 1 do
                local e = vd + 64 * i
                local obj = rp(e + 24)
                local nm
                if kptr(obj) then
                    -- ⚠ 裸 char 串指针须 read_cstr 优先, SSO 兜底
                    local p = rp(obj + 40)
                    if kptr(p) then nm = hoi4.read_cstr(p) end
                    if not nm then nm = SL.sso(obj + 40) end
                end
                if nm and nm ~= "" then
                    local kp = "dynamic_modifier." .. seq("modifier") .. "."
                    emit(tag, kp .. "modifier", '"' .. nm .. '"')
                    -- state i32@e+12 >0 才写 (本档 0 行)
                    local st = ru32(e + 12)
                    if st and st > 0 and st < 0x80000000 then
                        emit(tag, kp .. "state", SL.num(st))
                    end
                    -- tag tid i32@e+8 >0 才写 (SWI 锚)
                    local ts = tagstr(ru32(e + 8))
                    if ts then emit(tag, kp .. "tag", '"' .. ts .. '"') end
                    -- value {d@e+40, c@e+52} i64×1e-5 (count>0 才写块)
                    local vd2, vc2 = rp(e + 40), ru32(e + 52)
                    if kptr(vd2) and vc2 and vc2 > 0 and vc2 < GAME.layout.lim.PTR_SANE then
                        local toks = {}
                        for v2 = 0, vc2 - 1 do
                            toks[#toks + 1] =
                                SL.num(fix5(vd2 + 8 * v2) or 0)
                        end
                        emit(tag, kp .. "value.#1",
                            table.concat(toks, " "))
                    end
                    -- enabled u8@e+32 恒写
                    emit(tag, kp .. "enabled",
                        SL.yn((ru8(e + 32) or 0) ~= 0))
                    -- days i32@e+16 >=0 才写 (哨兵 -1; 本档 0 行)
                    local d2 = ru32(e + 16)
                    if d2 and d2 < 0x80000000 then
                        emit(tag, kp .. "days", SL.num(d2))
                    end
                end
            end
        end
    end
    -- ===== logistics.history (§4.3.13 CLoopHistory 队列族 / CLogisticsStatus
    -- cc+3992; 环形簿记) =====
    do
        -- 外层守卫 (writer 0x1413609D0 → 0x1406F3120 → 0x1401E1FE0)
        -- 仅人类控制国落盘 (AI 国整块跳过, 否则全档皆 GER 式数据 → MISS_SAVE)
        -- idx = u32@(*(gs+832))[tid]; is_ai = b@(*(gs+880)+idx)≠0 &&
        -- b@(*(gs+904)+idx)==0; 写 iff not is_ai
        local function human_writes()
            local tid = ru32(cc + 8)
            if not tid or tid == 0 then return false end
            local mapd = rp(gs + 832)
            if not kptr(mapd) then return false end
            local idx = ru32(mapd + 4 * tid)
            local nidx = ru32(gs + 916) or 0
            if not idx or idx >= nidx then return false end
            local valid, hcnt = rp(gs + 880), rp(gs + 904)
            if not (kptr(valid) and kptr(hcnt)) then return false end
            local is_ai = (ru8(valid + idx) or 0) ~= 0
                and (ru8(hcnt + idx) or 0) == 0
            return not is_ai
        end
        local logi = human_writes() and rp(cc + 3992) or nil
        if kptr(logi) then
            local ld = rp(logi + 8)
            if kptr(ld) then
                for i = 0, 18 do
                    local el = rp(ld + 8 * i)
                    -- elem+52 双重身份: 槽守卫 (>0 才落盘) + 记录列数
                    -- (queue writer 0x141505BB0: cols = u32@*(a1+56)+52,
                    -- a1+56 = parent = elem; GER 锚 槽0=81 槽17=7)
                    local cols = kptr(el) and ru32(el + 52) or nil
                    if cols and cols > 0 then
                        for qi, qoff in ipairs({ 0x10, 0x18, 0x20 }) do
                            local qc = rp(el + qoff)
                            if kptr(qc) then
                                local kp = string.format(
                                    "logistics.history.%d.history_queue.%d.",
                                    i, qi - 1)
                                local mx = ru32(qc + 0x10) or 0
                                emit(tag, kp .. "max_elements", SL.num(mx))
                                emit(tag, kp .. "offset",
                                    SL.num(ru32(qc + 0x24) or 0))
                                emit(tag, kp .. "is_full",
                                    SL.yn((ru8(qc + 0x28) or 0) ~= 0))
                                -- data.#1 (布局/写门 = 书 §4.3.13):
                                -- 行主序线性不旋转, 全队列统一 fixed5;
                                -- **全零缓冲整块不写** (v9 门, 空槽即此门
                                -- — 值须二次解引用行对象, 行对象首字段是
                                -- 数据指针非值, 误当值 = MISS_SAVE)
                                local qd = rp(qc + 8)
                                local rows = ru32(qc + 0x14) or 0
                                if kptr(qd) and rows > 0 and rows <= 4096
                                -- ^ 防垃圾指针即可; 行数真值 = qc+0x14 自身
                                -- (旧 rows<=64 是自选防御界误录 M.dim, 降级)
                                    and cols <= 512
                                    and rows * cols <= 65536 then
                                    local toks, any = {}, false
                                    for r = 0, rows - 1 do
                                        local rowobj = rp(qd + 8 * r)
                                        local rowd = kptr(rowobj)
                                            and rp(rowobj) or nil
                                        local ok_row = kptr(rowd)
                                        for k2 = 0, cols - 1 do
                                            local v = 0
                                            if ok_row then
                                                v = fix5(rowd + 8 * k2)
                                                    or 0
                                            end
                                            if v ~= 0 then any = true end
                                            toks[#toks + 1] = SL.num(v)
                                        end
                                    end
                                    if any then
                                        emit(tag, kp .. "data.#1",
                                            table.concat(toks, " "))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- ===== reinforcement.priority (§4.3.1 表 +3960 CReinforcementStatus;
    -- 集成勘误: 默认值 1 不落盘, ≠1 才写) =====
    do
        local robj = rp(cc + 3960)
        if kptr(robj) then
            local v = ru32(robj + 8)
            if v and v ~= 1 then
                emit(tag, "reinforcement.priority", SL.num(v))
            end
        end
    end
    -- ===== volunteers_sent (§4.3.12 表 +784 行; #N 1 基恒编号) =====
    do
        local vd, vc = rp(cc + 784), ru32(cc + 796)
        if kptr(vd) and vc and vc > 0 and vc < GAME.layout.lim.PTR_SANE then
            for q = 0, vc - 1 do
                emit(tag, "volunteers_sent.#" .. (q + 1),
                    SL.idpair(ru32(vd + 8 * q + 4), ru32(vd + 8 * q)))
            end
        end
    end
    -- ===== navy_theater.theater_group.is_important 补叶 (§4.3.12 tg+88 行) =====
    -- ⚠ id/name/fleet 已由 sv2_sec_c_strategic_navy.lua 发射 (同 reader),
    -- 本段仅补 is_important (token 15575, flag u8@tg+88 ≠0 写 yes;
    -- 全 0 常态不发射)
    do
        local ok, nt = pcall(function() return c:navy_theaters() end)
        if ok and nt and nt.list then
            local seq = SL.seqc()
            for _, g in ipairs(nt.list) do
                local kp = "navy_theater." .. seq("theater_group") .. "."
                if (g.flag3cd7 or 0) ~= 0 then
                    emit(tag, kp .. "is_important", "yes")
                end
            end
        end
    end
    -- ===== cached_navy_strength.sub_units (§4.3.12 表 +728 行) =====
    -- ⚠ 块门 (writer: `if (cc+668 || cc+644 || cc+692)`) = 师/舰队/铁路炮
    -- 容器任一非空; 无军队国 (被吞并国 VNC) 整块不写 — 缺门即 mem 多发
    do
        local nd, nc = rp(cc + 736), ru32(cc + 748)
        local n_army = ru32(cc + 668) or 0
        local n_fleet = ru32(cc + 644) or 0
        local n_rgun = ru32(cc + 692) or 0
        if (n_army > 0 or n_fleet > 0 or n_rgun > 0)
            and kptr(nd) and nc and nc > 0 and nc < GAME.layout.lim.PTR_SANE then
            for k = 0, nc - 1 do
                local tok, cnt = ru32(nd + 8 * k), ru32(nd + 8 * k + 4)
                if tok and cnt and cnt ~= 0 then
                    local nm = SL.tok(tok)
                    if nm and nm ~= "" then
                        emit(tag, "cached_navy_strength.sub_units." ..
                            tostring(nm), SL.num(cnt))
                    end
                end
            end
        end
    end
    -- ===== naval_headquarter_status (§4.3.12 表 +4016 行
    -- CCustomizableBuildingCollection; reader §26.2; #N 1 基恒编号) =====
    do
        local ok, nh = pcall(function() return c:naval_hq_status() end)
        if ok and nh and nh.list then
            for bi, b in ipairs(nh.list) do
                local kp = "naval_headquarter_status.buildings.#" .. bi .. "."
                emit(tag, kp .. "id", b.id_pair)
                emit(tag, kp .. "building", b.building)
                if b.province then
                    emit(tag, kp .. "province", SL.num(b.province))
                end
                if (b.char_type or 0) ~= 0 then
                    emit(tag, kp .. "navy_leader_building_module.character",
                        SL.idpair(b.char_id, b.char_type))
                end
                if b.experience and b.experience ~= 0 then
                    emit(tag, kp .. "navy_leader_building_module.experience",
                        SL.num(b.experience))
                end
            end
        end
    end
    -- ===== delayed_event (§4.3.11 元素布局 + CEventScope 递归表; 全字段) =====
    do
        local dd2, dc2 = rp(cc + 4752), ru32(cc + 4764)
        if kptr(dd2) and dc2 and dc2 > 0 and dc2 < 4096 then  -- 4096 界: 256 字面量曾被恰 256 条目击穿
            local seq = SL.seqc()
            local emit_scope -- 前向声明 (递归)
            emit_scope = function(sc, prefix, depth)
                if depth > 8 or not kptr(sc) then return end
                local ts = tagstr(ru32(sc + 8))
                if ts then emit(tag, prefix .. ".country", '"' .. ts .. '"') end
                local sid2 = ru32(sc + 168)
                if sid2 and sid2 ~= 0 then
                    emit(tag, prefix .. ".state", SL.num(sid2))
                end
                -- id 对族 {type@+0, id@+4} (B240)
                local pairspec = {
                    { "character", 80 }, { "operation", 88 }, { "ace", 104 },
                    { "unit", 112 }, { "industrial_organisation", 120 },
                    { "purchase_contract", 128 }, { "raid_instance", 136 },
                    { "project", 144 }, { "faction", 152 } }
                for _, ps in ipairs(pairspec) do
                    local pt2, pi2 = ru32(sc + ps[2]), ru32(sc + ps[2] + 4)
                    if (pt2 and pt2 ~= 0) or (pi2 and pi2 ~= 0) then
                        emit(tag, prefix .. "." .. ps[1],
                            SL.idpair(pi2, pt2))
                    end
                end
                local srp = rp(sc + 72)
                if kptr(srp) then
                    local srv = ru32(srp + 88)
                    if srv then
                        emit(tag, prefix .. ".strategic_region", SL.num(srv))
                    end
                end
                -- random 恒写: 存档序 "<u32@sc+16> <u32@sc+12>" (写序反)
                local r1, r2 = ru32(sc + 16), ru32(sc + 12)
                if r1 and r2 then
                    emit(tag, prefix .. ".random", r1 .. " " .. r2)
                end
                -- root@+24 / from@+32 / prev@+40: ≠自指才递归
                local rt, fr, pv = rp(sc + 24), rp(sc + 32), rp(sc + 40)
                if rt and rt ~= sc then
                    emit_scope(rt, prefix .. ".root", depth + 1) end
                if fr and fr ~= sc then
                    emit_scope(fr, prefix .. ".from", depth + 1) end
                if pv and pv ~= sc then
                    emit_scope(pv, prefix .. ".prev", depth + 1) end
                -- saved_event_target (§4.12.6; 布局/写门 = 书; 提取件
                -- 同名第 2+ 目标编 [N])。⚠ 两路门不同: 本路径
                -- (delayed_event) 的 writer 只在 from==自指层写;
                -- pending_events 走 global_tails 的 emit_scope, 那里
                -- 每层都写。
                if fr == sc then
                    local cp2 = rp(sc + 160)
                    if kptr(cp2) then
                        local td, tc = rp(cp2), ru32(cp2 + 12)
                        if kptr(td) and tc and tc > 0 and tc < GAME.layout.lim.PTR_SANE then
                            for ti = 0, tc - 1 do
                                local te = td + 112 * ti
                                local kp2 = prefix .. ".saved_event_target"
                                if ti > 0 then
                                    kp2 = kp2 .. "[" .. (ti + 1) .. "]"
                                end
                                local st3 = ru32(te + 8)
                                if st3 and st3 ~= 0 then
                                    emit(tag, kp2 .. ".state", SL.num(st3))
                                end
                                local ct3 = ru32(te + 12)
                                if ct3 and ct3 > 0
                                    and ct3 < 0x80000000 then
                                    local cts3 = tagstr(ct3)
                                    if cts3 then
                                        emit(tag, kp2 .. ".country",
                                            '"' .. cts3 .. '"')
                                    end
                                end
                                local ni3 = ru32(te + 104)
                                if ni3 then ni3 = ni3 % 65536 end
                                if ni3 and ni3 ~= 0 then
                                    -- 串表散写回收  → set_name
                                    local nm3 = GAME.layout.set_name(ni3)
                                    if nm3 then
                                        emit(tag, kp2 .. ".name",
                                            '"' .. nm3 .. '"')
                                    end
                                end
                                -- character id 对 @+16 {type@+16, id@+20}
                                -- (实证 refid type=73; 偏移待探针核对, 对拍即验)
                                local ct4, ci4 = ru32(te + 16),
                                    ru32(te + 20)
                                if ct4 and ci4
                                    and (ct4 ~= 0 or ci4 ~= 0) then
                                    emit(tag, kp2 .. ".character",
                                        SL.idpair(ci4, ct4))
                                end
                            end
                        end
                    end
                end
            end
            for di = 0, dc2 - 1 do
                local e = rp(dd2 + 8 * di)
                if kptr(e) then
                    local blk = seq("delayed_event")
                    local ev = rp(e + 8)
                    if kptr(ev) then
                        local nm = SL.sso(ev + 32)
                        if nm and nm ~= "" then
                            emit(tag, blk .. ".event", '"' .. nm .. '"')
                        end
                    end
                    local v = ru32(e + 196) or 0
                    emit(tag, blk .. ".hours", SL.num(v % 24))
                    emit(tag, blk .. ".days",
                        SL.num(math.floor(v % 720 / 24)))
                    emit(tag, blk .. ".months", SL.num(math.floor(v / 720)))
                    emit_scope(e + 16, blk .. ".scope", 1)
                    local ots = tagstr(ru32(e + 192))
                    if ots then
                        emit(tag, blk .. ".originator", '"' .. ots .. '"')
                    end
                end
            end
        end
    end
    -- ===== focus_cost_reduction: 已由 sv2_sec_c_focus.lua 发射, 本段不重复 =====
    -- ===== templates_locked + reason (§4.3.1 表 +436/+464 行; 同字节门 u8@cc+436) =====
    do
        if (ru8(cc + 436) or 0) ~= 0 then
            emit(tag, "templates_locked", "yes")
            local s = SL.sso(cc + 464) or ""
            emit(tag, "reason", '"' .. s .. '"')
        end
    end
    -- ===== pride_of_the_fleet / original_tag (§4.3.1 表 +592/+596 行;
    -- original_tag @cc+4876) =====
    do
        local pt, pi = ru32(cc + 592), ru32(cc + 596)
        if (pt and pt ~= 0) or (pi and pi ~= 0) then
            emit(tag, "pride_of_the_fleet", SL.idpair(pi, pt))
        end
        local ots = tagstr(ru32(cc + 4876))
        if ots then emit(tag, "original_tag", '"' .. ots .. '"') end
    end
    -- ===== invasion_report (§4.3.12 表 +4096 行) =====
    do
        local idd, idc = rp(cc + 4096), ru32(cc + 4108)
        if kptr(idd) and idc and idc > 0 and idc < GAME.layout.lim.PTR_SANE then
            local seq = SL.seqc()
            for i = 0, idc - 1 do
                local e = rp(idd + 8 * i)
                if kptr(e) then
                    local blk = seq("invasion_report")
                    local t1 = tagstr(ru32(e + 8))
                    if t1 then
                        emit(tag, blk .. ".tag", '"' .. t1 .. '"') end
                    local t2 = tagstr(ru32(e + 12))
                    if t2 then
                        emit(tag, blk .. ".enemy", '"' .. t2 .. '"') end
                    local pp = rp(e + 16)
                    if kptr(pp) then
                        local pv = ru32(pp + 164)
                        if pv then
                            emit(tag, blk .. ".province", SL.num(pv)) end
                    end
                    local d = SL.date(ru32(e + 40))
                    if d then emit(tag, blk .. ".date", '"' .. d .. '"') end
                end
            end
        end
    end
    -- ===== civil_war_target (§4.3.12 表 +4848 行) =====
    do
        local cd3, cc3 = rp(cc + 4848), ru32(cc + 4860)
        if kptr(cd3) and cc3 and cc3 > 0 and cc3 < GAME.layout.lim.PTR_SANE then
            for q = 0, cc3 - 1 do
                local s = tagstr(ru32(cd3 + 4 * q))
                if s then emit(tag, "civil_war_target", '"' .. s .. '"') end
            end
        end
    end
    -- ===== external_rules (§4.3.1 CRuleOverrides 宿主 cc+2656 /
    -- §4.26.3 定义表; 28 规则, 门开才写, 值 yes/no 皆写) =====
    do
        -- 键名散写回收 : defs 表直读 → rule_key(i);
        -- 界 = dim.EXTERNAL_RULES
        for i = 0, GAME.layout.dim.EXTERNAL_RULES - 1 do
            if (ru8(cc + 2656 + 92 + i) or 0) ~= 0 then
                local nm = GAME.layout.rule_key(i)
                if nm and nm ~= "" then
                    emit(tag, "external_rules." .. tostring(nm),
                        SL.yn((ru8(cc + 2656 + 64 + i) or 0) ~= 0))
                end
            end
        end
    end
    -- external_rules.override (§4.3.1 表 cc+2656 行; 串槽布局/写门/裸键 = 书)
    do
        for k = 0, GAME.layout.dim.EXTERNAL_RULES - 1 do
            if (rp(cc + 2656 + 136 + 32 * k) or 0) ~= 0 then
                local sv = SL.sso(cc + 2656 + 120 + 32 * k)
                if sv and sv ~= "" then
                    emit(tag, "external_rules.override." .. tostring(k), sv)
                end
            end
        end
    end
    -- ===== collaboration (§4.3.1 表 +4056 行; 布局/写门/occupier 键 = 书) =====
    do
        local co = rp(cc + 4056)
        if kptr(co) then
            local cd, cn = rp(co + 40), ru32(co + 52)
            if kptr(cd) and cn and cn > 0 and cn < 4096 then
                for k = 0, cn - 1 do
                    local ep = rp(cd + 8 * k)
                    if kptr(ep) then
                        local tg = tagstr(ru32(ep + 8))
                        if tg then
                            emit(tag, "collaboration.collaboration." .. tg
                                .. ".value", SL.num(fix5(ep + 16)))
                        end
                    end
                end
            end
        end
    end
    -- ===== buildings (§4.3.12 表 +4944 CBuildingStatus; reader §28.6) =====
    do
        local ok, bd = pcall(function() return c:country_buildings() end)
        if ok and bd and bd.list then
            for _, b in ipairs(bd.list) do
                if b.name then
                    local kp = "buildings." .. b.name .. "."
                    emit(tag, kp .. "level", SL.num(b.level or 0))
                    -- partial_health: 原值 ≠100000 (×1e-5 → ≠1) 才写
                    if b.partial and b.partial ~= 1 then
                        emit(tag, kp .. "partial_health", SL.num(b.partial))
                    end
                    emit(tag, kp .. "healthy_levels",
                        SL.num(b.healthy or 0))
                end
            end
        end
    end
    -- ===== operative_codenames_tracker (§4.3.9 名字组 tracker, mode 3) =====
    do
        local ok, r = pcall(function() return c:name_groups(3) end)
        if ok and r then
            local prefix = "operative_codenames_tracker"
            for li, nm in ipairs(r.unavailable or {}) do
                local q = SL.Q(nm)
                if q then
                    emit(tag, prefix .. ".unavailable_groups.#" .. li, q)
                end
            end
            for li, nm in ipairs(r.available or {}) do
                local q = SL.Q(nm)
                if q then
                    emit(tag, prefix .. ".available_groups.#" .. li, q)
                end
            end
            local seq = SL.seqc()
            for _, pm in ipairs(r.post_mortem and r.post_mortem.list or {}) do
                local blk = seq(prefix .. ".post_mortem")
                emit(tag, blk .. ".type", SL.num(pm.type))
                if pm.name_order then
                    emit(tag, blk .. ".name_order", SL.num(pm.name_order))
                end
                if pm.is_name_ordered then
                    emit(tag, blk .. ".is_name_ordered", pm.is_name_ordered)
                end
                local ov = SL.Q(pm.override)
                if ov then emit(tag, blk .. ".override", ov) end
                if pm.override_set_programmatically then
                    emit(tag, blk .. ".override_set_programmatically",
                        pm.override_set_programmatically)
                end
                if pm.equipment then
                    emit(tag, blk .. ".equipment", pm.equipment)
                end
            end
        end
    end
    -- ===== 散标量 (§4.3.12 杂项标量表; 定案门) =====
    u32_nz("original_research_slots", 4324)
    -- 战斗计数/战支 Q15 五连/last_collaborated 布局上提
    -- reader Country.combat_support_scalars (≠0 门留段层)
    local css = ctx.country and ctx.country:combat_support_scalars() or {}
    if (css.num_ships or 0) ~= 0 then
        emit(tag, "num_ships", tostring(css.num_ships)) end
    if (css.num_armies_in_combat or 0) ~= 0 then
        emit(tag, "num_armies_in_combat", tostring(css.num_armies_in_combat)) end
    if (css.num_ships_in_combat or 0) ~= 0 then
        emit(tag, "num_ships_in_combat", tostring(css.num_ships_in_combat)) end
    if (css.convoys_destroyed or 0) ~= 0 then
        emit(tag, "convoys_destroyed", tostring(css.convoys_destroyed)) end
    flag_yes("major", 5210)
    flag_yes("is_major", 5209) -- JAP/ITA/AUS=1, GER/ENG=0
    flag_yes("is_top_ic_country", 5211)
    flag_yes("landlocked_start", 5619)
    flag_yes("reserved_dynamic_country", 5213)
    do -- coastal_protection_ratio ×1e-5@cc+5632 ≠0 才写
        local v = fix5(cc + 5632)
        if v and v ~= 0 then
            emit(tag, "coastal_protection_ratio", SL.num(v))
        end
    end
    -- 战支惩罚族 Q15 五连 (§4.3.12 表 +5312..+5344; sub_14070C580): ≠0 才写
    for _, kv in ipairs({
        { "propaganda_stability_penalty", css.propaganda_stability_penalty },
        { "being_bombed_support_penalty", css.being_bombed_support_penalty },
        { "heroes_dying_war_support_penalty",
            css.heroes_dying_war_support_penalty },
        { "convoy_raiding_war_support_penalty",
            css.convoy_raiding_war_support_penalty },
        { "propaganda_war_support_penalty",
            css.propaganda_war_support_penalty } }) do
        if kv[2] and kv[2] ~= 0 then
            emit(tag, kv[1], SL.num(kv[2])) end
    end
    do -- last_collaborated_surrender_recipient i32 >0 才写
        -- 值 = 国 idx → 引号 tag (writer 0x14070C580 → sub_140BA5C20)
        local lid = css.last_collaborated
        if lid and lid > 0 and lid < 0x80000000 then
            local s = tagstr(lid)
            if s then
                emit(tag, "last_collaborated_surrender_recipient",
                    '"' .. s .. '"') end
        end
    end
end }
