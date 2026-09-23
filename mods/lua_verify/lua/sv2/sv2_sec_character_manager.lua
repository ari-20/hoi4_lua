-- sv2_sec_character_manager.lua -- character_manager 节点 savefull 直出
-- (gsec) — §4.4.9 CCharacterManager (gs+1704) historical/dynamic 两池,
-- 元素 8B CCharacter* (布局/写门/键序 = 书 §4.4.9-§4.4.17 各段:
-- CCharacter §4.4.11 / 将领 §4.4.2+§4.4.5+§4.4.6 / 国家领袖 §4.4.16 /
-- 科学家 §4.4.17 / 顾问 §4.4.15 / portraits §4.4.10 复用 O.char_portraits)。
-- 存档 character[N] 写序 = id 升序 (池内 sort)。
SV2.gsec[#SV2.gsec + 1] = { name = "character_manager", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local gs, BASE = ctx.gs, ctx.BASE
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local DIM = "character_manager"
    local VT_CHAR = 0x297ea60

    -- §3.5 MSVC SSO 串 {buf@0, size@0x10, cap@0x18} (同 objects_v2 U.sso)
    local function sso(obj)
        if not obj or obj < 0x10000 then return nil end
        local size = ru32(obj + 0x10)
        if not size or size > 4096 then return nil end
        if size == 0 then return "" end
        -- 内联判据 = cap (MSVC; 实测堆串 size=15/cap=31)
        local cap = ru32(obj + 0x18)
        local buf = (cap and cap > 15) and rp(obj) or obj
        if not buf or buf < 0x10000 then return nil end
        local chars = {}
        for i = 0, size - 1 do
            local c = ru32(buf + i)
            if not c then return nil end
            chars[#chars + 1] = string.char(c & 0xFF)
        end
        return table.concat(chars)
    end
    -- token → 名, 仅接受串 (token_name 缺表 → nil, 防数值假叶;
    -- "=" 是引擎未知 token 占位串, 一并拒收 — 2 template 垃圾教训)
    local function tokname(t)
        if not t or t == 0 then return nil end
        local LAY = GAME.layout
        local n = LAY and LAY.token_name(t)
        if type(n) == "string" and n ~= "" and n ~= "=" then return n end
        return nil
    end
    -- tag id → 三字串 (§1.2 gs+856 (0x358) tag 串表, 32B/项)
    local ttab = gs and rp(gs + 0x358)
    local function tagstr(tid)
        if not tid or tid <= 0 or tid >= 100000 or not ttab then return nil end
        return hoi4.read_str(ttab + 32 * tid)
    end
    local function fix5(a) return (rp(a) or 0) * 1e-5 end
    -- §3.7 有符号 i64 ×1e-5 (modifier 值可负; 必须 /100000 保整值精度)
    local function fix5s(a)
        return GAME.layout.fix5(a)
    end
    local si32 = GAME.layout.as_i32
    local function Qd(h) -- 小时 → 引号日期
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end

    -- modifier 定义表 = 统一访问器
    local LAY = GAME.layout
    local mnd = LAY.modifier_count() or 0
    local function mdef_token(idx) return LAY.modifier_token(idx) end
    -- CModifier 本体叶 (布局/写门 = 书 §4.3.8; added_modifier 数组B
    -- 本存档 0 叶, 未实现)
    local function modifier_pairs(mod)
        local out = {}
        if not SL.kptr(mod) then return out end
        local dv = ru32(mod + 188)
        if dv and dv ~= 1 then out[#out + 1] = { "data", tostring(dv) } end
        local nm = sso(mod + 88)
        if nm and nm ~= "" then out[#out + 1] = { "name", SL.Q(nm) } end
        if mnd > 0 then
            local d, c = rp(mod + 16), ru32(mod + 28)
            if SL.kptr(d) and c and c > 0 and c <= LAY.lim.PTR_SANE then
                for j = 0, c - 1 do
                    local e = d + 16 * j
                    local mn = mdef_token(ru32(e))
                    if mn then
                        out[#out + 1] = { mn, SL.num(fix5s(e + 8) or 0) }
                    end
                end
            end
        end
        return out
    end

    -- §4.4.9 CCharacterManager (gs+1704 = 0x6A8)
    local mgr = gs and rp(gs + 0x6A8)
    if not SL.kptr(mgr) then return end
    -- next_character_id (mgr+0x8)
    local ncid = ru32(mgr + 8)
    if ncid then emit(DIM, "next_character_id", tostring(ncid)) end

    -- 池枚举 (§4.4.9 historical/dynamic 两池; id 升序 = 存档写序)
    local function pool(doff, coff)
        local data, n = rp(mgr + doff), ru32(mgr + coff)
        local out = {}
        if SL.kptr(data) and n and n > 0 and n < 200000 then
            for i = 0, n - 1 do
                local p = rp(data + 8 * i)
                if p and rp(p) == BASE + VT_CHAR then
                    out[#out + 1] = { addr = p, id = ru32(p + 0xC) or 0 }
                end
            end
        end
        table.sort(out, function(a, b) return a.id < b.id end)
        return out
    end

    -- §4.4.2 CUnitLeader 16B {trait_ptr@0, val@+8} 对列表
    -- (in_progress/trait_xp_factor/traits_to_remove 共用容器型)
    local function pair_list(l, doff, coff, is_int)
        local d, c = rp(l + doff), ru32(l + coff)
        local out = {}
        if SL.kptr(d) and c and c > 0 and c <= 128 then
            for i = 0, c - 1 do
                local e = d + 16 * i
                local tp = rp(e)
                local nm = SL.kptr(tp) and tokname(ru32(tp + 8)) or nil
                if nm then
                    if is_int then
                        out[#out + 1] = { nm, tostring(si32(ru32(e + 8)) or 0) }
                    else
                        out[#out + 1] = { nm, SL.num((rp(e + 8) or 0) * 1e-5) }
                    end
                end
            end
        end
        return out
    end

    local CD_REASON = { [1] = "reassigned", [2] = "harmed",
        [3] = "forced_into_hiding", [4] = "deployed", [5] = "withdrawing" }
    local LEDGER = { [4] = "army", [8] = "navy", [16] = "air",
        [28] = "military", [0xFFFFFFFF] = "invalid", [1] = "hidden",
        [30] = "all", [2] = "civilian" } -- 2=civilian: 旧注"无行"被
        -- 推翻 (2 例 ledger=civilian 落盘)
    local LEADER_KIND = { [0] = "field_marshal", [1] = "corps_commander",
        [2] = "navy_leader" }
    local GENDER = { [0] = "undefined", [1] = "male", [2] = "female" }

    -- 将领块 (§4.4.2 CUnitLeader / §4.4.5 CArmyLeader / §4.4.6 CNavyLeader;
    -- corps_commander/field_marshal/navy_leader)
    local function emit_leader(P, p)
        local l = rp(p + 0xA8)
        if not SL.kptr(l) then return end
        local lt = ru32(l + 0xE7C)
        local kind = LEADER_KIND[lt]
        if not kind then return end
        local function E(path, val)
            if val ~= nil then emit(DIM, P .. "." .. kind .. "." .. path, val) end
        end
        E("id", SL.idpair(ru32(l + 12), ru32(l + 8)))
        E("name", SL.Q(sso(l + 32)))
        -- SSO 条件叶 (本存档全空; 守卫 = size≠0, sso 空串 → Q nil 自然跳)
        E("desc", SL.Q(sso(l + 128)))
        E("custom_cost_text", SL.Q(sso(l + 160)))
        E("portrait_path", SL.Q(sso(l + 192)))
        E("picture", SL.Q(sso(l + 224)))
        E("gfx", SL.Q(sso(l + 256)))
        if (ru8(l + 3713) or 0) ~= 0 then
            E("female", SL.yn(ru8(l + 3712)))
        end
        local sko = rp(l + 3680)
        if SL.kptr(sko) then
            local sk = ru32(sko + 440)
            if sk then E("skill", tostring(sk)) end
        end
        if (rp(l + 3688) or 0) ~= 0 then
            E("experience", SL.num(fix5(l + 3688)))
        end
        local sid = ru32(l + 3924)
        if sid and sid ~= 0 then E("script_id", tostring(sid)) end
        E("link", SL.Q(sso(l + 3648)))
        if (rp(l + 3776) or 0) ~= 0 then
            E("max_traits", SL.num(fix5(l + 3776)))
        end
        -- 四技能 (≠0 才写): army 3928/3944/3960/3976; navy 3944/3960/3976/3992
        local SK = { "attack_skill", "defense_skill" }
        if lt == 2 then
            SK[3], SK[4] = "maneuvering_skill", "coordination_skill"
        else
            SK[3], SK[4] = "planning_skill", "logistics_skill"
        end
        local soff = lt == 2 and { 3944, 3960, 3976, 3992 }
            or { 3928, 3944, 3960, 3976 }
        for i = 1, 4 do
            local v = ru32(l + soff[i])
            if v and v ~= 0 then E(SK[i], tostring(v)) end
        end
        -- temp_deficit (≠0, 有符号): army @3992..4004 / navy @4016..4028
        local toff = lt == 2 and { 4016, 4020, 4024, 4028 }
            or { 3992, 3996, 4000, 4004 }
        for i = 1, 4 do
            local v = si32(ru32(l + toff[i]))
            if v and v ~= 0 then
                E(SK[i]:gsub("_skill$", "_skill_temp_deficit"), tostring(v))
            end
        end
        -- preferred_tactic: army 系, ptr@+4272 非空即写 (0 也写); navy 不写
        if lt ~= 2 then
            local tp = rp(l + 4272)
            if SL.kptr(tp) then
                E("preferred_tactic", tostring(ru32(tp + 152) or 0))
            end
            -- pending_reassign_target (army writer
            -- 0x140C18CA0 尾段: 门 (u32@+4176 ≠0 或 u32@+4180 ≠0) 且
            -- 注册表校验 sub_14220A3D0; id 对 {type@+4176, id@+4180}
            -- (sub_14220B240: 先写 a2[1]=id 后 a2[0]=type))
            local pt0, pt1 = ru32(l + 4176), ru32(l + 4180)
            if (pt0 and pt0 ~= 0) or (pt1 and pt1 ~= 0) then
                E("pending_reassign_target", SL.idpair(pt1, pt0))
            end
        end
        -- navy 专属: naval_headquarter 对 + penalty 恒写
        if lt == 2 then
            local hqid = ru32(l + 4012)
            if hqid and hqid ~= 0 then
                E("naval_headquarter",
                    SL.idpair(hqid, ru32(l + 4008) or 0))
            end
            E("penalty", SL.num(fix5(l + 4032)))
        end
        -- traits (空不写, bare 空格连)
        do
            local d, c = rp(l + 3528), ru32(l + 3540)
            local ts = {}
            if SL.kptr(d) and c and c > 0 and c <= 128 then
                for i = 0, c - 1 do
                    local tp = rp(d + 8 * i)
                    local nm = SL.kptr(tp) and tokname(ru32(tp + 8))
                    if nm then ts[#ts + 1] = nm end
                end
            end
            if #ts > 0 then E("traits", table.concat(ts, " ")) end
        end
        for _, pl in ipairs(pair_list(l, 3576, 3588, false)) do
            E("in_progress." .. pl[1], pl[2])
        end
        for _, pl in ipairs(pair_list(l, 3552, 3564, true)) do
            E("traits_to_remove." .. pl[1], pl[2])
        end
        for _, pl in ipairs(pair_list(l, 3600, 3612, false)) do
            E("trait_xp_factor." .. pl[1], pl[2])
        end
        -- cooldown 三件套 (守卫 enum@+3716 ≠0); 日期 = 内嵌多态 CGameDate
        -- (§3.7a) {vt@0, hours@+8}: start 对象@+3720 → hours@+3728;
        -- enable 对象@+3744 → hours@+3752 (定案
        -- +3736/+3760 是另一对 vt/空槽, 非日期本体)
        local cd = ru32(l + 3716)
        if cd and cd ~= 0 then
            local rsn = CD_REASON[cd]
            if rsn then E("cooldown_reason", '"' .. rsn .. '"') end
            E("leader_modifier_enable_date", Qd(ru32(l + 3752)))
            E("leader_cooldown_start_date", Qd(ru32(l + 3728)))
        end
        local gx = ru32(l + 3796)
        if gx and gx > 0 then
            local t = tagstr(gx)
            if t then E("government_in_exile_tag", '"' .. t .. '"') end
        end
        -- legacy_id u32@+3800: 门 ≠-1; **有符号域** (存档实证负值,
        -- 与 country_leader.id 同根因: writer 门是 u32 -1 但值域为 i32)
        local leg = ru32(l + 3800)
        if leg and leg ~= 0xFFFFFFFF then
            leg = GAME.layout.as_i32(leg)
            E("legacy_id", tostring(leg))
        end
        if (ru8(l + 3804) or 0) ~= 0 then E("promoted_from_unit", "yes") end
        -- captured 三件套 (布局/写门 = 书 §4.4.5; 仅 army 系, navy
        -- writer 无此块; 写序在 deployed 前)
        if lt ~= 2 and (ru8(l + 4185) or 0) ~= 0 then
            E("captured", "yes")
            local cb = si32(ru32(l + 4188)) or 0
            if cb > 0 then
                local t = tagstr(cb)
                if t then E("captured_by", '"' .. t .. '"') end
            end
            local lp = rp(l + 4192)
            if SL.kptr(lp) then
                E("location", tostring(ru32(lp + 164) or 0))
            end
        end
        -- deployed/deployment_cost (army writer 0x140C18CA0 尾部专属
        -- byte@+4200 ≠0 → deployed=yes + deployment_cost i64x1e-5@+4208;
        -- ⚠ 仅 army 系 — navy writer 无此块)
        if lt ~= 2 and (ru8(l + 4200) or 0) ~= 0 then
            E("deployed", "yes")
            E("deployment_cost", SL.num(fix5(l + 4208)))
        end
        -- sub_unit_modifiers (§4.4.12; 布局/写门/A+B key 升序归并 = 书)。
        -- 容器A units 项叶结构未解 (本存档恒空 0 叶, 仅出修正叶);
        -- 键名 = LAY.idb_token("sub_unit", key), 0 → "null" (writer 定案)
        do
            local dA, dB = rp(l + 304), rp(l + 328)
            local cA = (SL.kptr(dA) and ru32(l + 316)) or 0
            local cB = (SL.kptr(dB) and ru32(l + 340)) or 0
            if cA > GAME.layout.lim.PTR_SANE then cA = 0 end
            if cB > GAME.layout.lim.PTR_SANE then cB = 0 end
            if cA + cB > 0 then
                -- idb 散写回收 : key→名 = idb_token
                -- ("sub_unit") — GetItem 语义 (idx<1/≥cnt 回退 arr[0])
                -- 访问器自带; idx==0 引擎写 "null" (writer 定案保留)
                local function shipname(idx)
                    if not idx then return nil end
                    if idx == 0 then return "null" end
                    return LAY.idb_token("sub_unit", idx)
                end
                local function emit_B(j)
                    local e = dB + 208 * j
                    local nm = shipname(ru32(e + 8))
                    local mod = e + 16
                    if nm and rp(mod) == BASE + 0x27185F0 then
                        for _, pr in ipairs(modifier_pairs(mod)) do
                            E("sub_unit_modifiers." .. nm .. "." .. pr[1],
                                pr[2])
                        end
                    end
                end
                -- 归并 (A/B 各自 key 升序; 同 key 先 units 后修正 — units
                -- 未解故仅出修正叶; 仅 A 无叶)
                local i, j = 0, 0
                while i < cA or j < cB do
                    local kA = (i < cA and ru32(dA + 56 * i + 8)) or 0xFFFFFFFF
                    local kB = (j < cB and ru32(dB + 208 * j + 8)) or 0xFFFFFFFF
                    if kA <= kB then
                        if kA == kB and j < cB then emit_B(j); j = j + 1 end
                        i = i + 1
                    else
                        emit_B(j); j = j + 1
                    end
                end
            end
        end
        -- B 类跳过: dynamic_modifier@+3840 (块级)
    end

    -- 顾问块 (§4.4.11 CCharacter advisors map / §4.4.15 CAdvisor;
    -- std::map RB-tree 中序 (§3.3), begin = head._Left)。⚠ 必须树中序:
    -- 链表走法在 ≥2 顾问角色丢右子树 (advisor[2]/[3] MISS);
    -- 起步入假曾致整族零产出。
    local function isnil(n)
        return not SL.kptr(n) or (ru8(n + 25) or 1) ~= 0
    end
    local function tsucc(n)              -- = sub_1401FEDD0
        local r = rp(n + 16)
        if not isnil(r) then
            local j = rp(r)
            while not isnil(j) do r = j; j = rp(j) end
            return r
        end
        local i = rp(n + 8)
        while not isnil(i) and n == rp(i + 16) do
            n = i; i = rp(i + 8)
        end
        return i
    end
    local function emit_advisors(P, p)
        local head = rp(p + 0xB0)
        if not SL.kptr(head) then return end
        local aseq = SL.seqc()
        local node, guard = rp(head), 0   -- head._Left = begin (最小)
        while not isnil(node) and node ~= head and guard < 64 do
            guard = guard + 1
            local adv = rp(node + 72)
            if SL.kptr(adv) then
            local akey = aseq("advisor")
            local function E(path, val)
                if val ~= nil then
                    emit(DIM, P .. ".advisors." .. akey .. "." .. path, val)
                end
            end
            E("slot", SL.Q(sso(adv + 0x80)))
            -- template ref@+0x18: get = *(ref+0x10) (sub_14012A010 直证)
            -- → CAdvisorTemplate (vt 0x1429A4B88),
            -- 名 = token@obj+8 (writer 路径); 兜底 = 名 SSO@obj+0x18
            -- (traits 元素同布局已验收); 与 dynamic_template@+0x20 互斥
            local ref = rp(adv + 0x18)
            local tname
            if SL.kptr(ref) then
                local obj = rp(ref + 0x10)
                if SL.kptr(obj) then
                    tname = tokname(ru32(obj + 8))
                    if not tname then
                        local s = sso(obj + 0x18)
                        if s and s ~= "" then tname = s end
                    end
                end
            end
            if tname then
                E("template", '"' .. tname .. '"')
            else
                -- dynamic_template = 堆指针 rp(adv+0x20) (§4.4.13 定案:
                -- 非内嵌! 与 template ref 互斥, ref 优先; 布局/写门 = 书;
                -- research_bonus 本存档 count=0 未实现; desc 空串也写 "")。
                local dtp = rp(adv + 0x20)
                if SL.kptr(dtp) and rp(dtp) == BASE + GAME.layout.vt.CAdvisorTemplate then
                    local function D(path, val)
                        if val ~= nil then
                            E("dynamic_template." .. path, val)
                        end
                    end
                    do
                        local lv = ru32(dtp + 0x18) or 0
                        if lv == 0xFFFF then lv = 0xFFFFFFFF end
                        local ldg = LEDGER[lv]
                        if ldg then D("ledger", ldg) end
                    end
                    D("slot", SL.Q(sso(dtp + 0x70)))
                    D("idea_token", SL.Q(sso(dtp + 0x20)))
                    D("cost", SL.num(fix5s(dtp + 0xB8) or 0))
                    D("removal_cost", SL.num(fix5s(dtp + 0xC8) or 0))
                    D("can_be_fired", SL.yn(ru8(dtp + 0xD0)))
                    D("command_power", SL.num(fix5s(dtp + 0xD8) or 0))
                    do
                        local d, c = rp(dtp + 0xE0), ru32(dtp + 0xEC)
                        if SL.kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_SANE then
                            for j = 0, c - 1 do
                                local tnm = sso(d + 40 * j)
                                if tnm and tnm ~= "" then
                                    D("traits.#" .. (j + 1),
                                        '"' .. tnm .. '"')
                                end
                            end
                        end
                    end
                    local dsc = sso(dtp + 0x418)
                    if dsc then D("desc", '"' .. dsc .. '"') end
                end
            end
            do
                local lv = ru32(adv + 0x28) or 0
                -- 注: 存档 invalid 实例内存读得 0xFFFF (非 0xFFFFFFFF)
                if lv == 0xFFFF then lv = 0xFFFFFFFF end
                local ldg = LEDGER[lv]
                if ldg then E("ledger", ldg) end
            end
            E("idea_token", SL.Q(sso(adv + 0x30)))
            if (rp(adv + 0xA8) or 0) ~= 0 then
                E("political_power", SL.num(fix5(adv + 0xA8)))
            end
            if (rp(adv + 0xC0) or 0) ~= 0 then
                E("command_power", SL.num(fix5(adv + 0xC0)))
            end
            do
                local d, c = rp(adv + 0xC8), ru32(adv + 0xD4)
                if SL.kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_SANE then
                    for j = 0, c - 1 do
                        local tr = rp(d + 8 * j)
                        if SL.kptr(tr) then
                            local nm = sso(tr + 0x18)
                            if nm and nm ~= "" then
                                E("traits.#" .. (j + 1), '"' .. nm .. '"')
                            end
                        end
                    end
                end
            end
            E("portrait", SL.Q(sso(adv + 0x280)))
            if (rp(adv + 0xB0) or 0) ~= 0 then
                E("removal_cost", SL.num(fix5(adv + 0xB0)))
            end
            if (ru8(adv + 0xB8) or 1) == 0 then E("can_be_fired", "no") end
            E("desc", SL.Q(sso(adv + 0x2D8)))
            -- modifier = CModifier 内嵌@adv+0xE0 (书 §4.4.14; 块门
            -- 三选一与引擎精确谓词 = 书, 掩码经
            -- LAY.modifier_category_mask / LAY.modifier_category)
            do
                local mod = adv + 0xE0
                local gate = (si32(ru32(mod + 136)) or 0) > 0
                    or (ru32(mod + 52) or 0) ~= 0
                if not gate and mnd > 0 then
                    local d, c = rp(mod + 16), ru32(mod + 28)
                    if SL.kptr(d) and c and c > 0 and c <= LAY.lim.PTR_SANE then
                        local cmask = LAY.modifier_category_mask() or 0
                        for j = 0, c - 1 do
                            local cat = LAY.modifier_category(
                                ru32(d + 16 * j))
                            if cat and (cat == 0 or (cmask & cat) ~= 0) then
                                gate = true
                                break
                            end
                        end
                    end
                end
                if gate then
                    for _, pr in ipairs(modifier_pairs(mod)) do
                        E("modifier." .. pr[1], pr[2])
                    end
                end
            end
            end
            node = tsucc(node)
        end
    end

    for _, pooldef in ipairs({ { "historical", 0x10, 0x1C },
        { "dynamic", 0x28, 0x34 } }) do
        local pname, doff, coff = pooldef[1], pooldef[2], pooldef[3]
        local cseq = SL.seqc()
        -- §4.4.11 CCharacter (vt 0x297ea60) 逐角色发射
        for _, ch in ipairs(pool(doff, coff)) do
            local p = ch.addr
            local ckey = cseq("character")
            local P = pname .. "." .. ckey
            local function E(path, val)
                if val ~= nil then emit(DIM, P .. "." .. path, val) end
            end
            E("id", SL.idpair(ru32(p + 0xC), ru32(p + 8)))
            E("token", SL.Q(tokname(ru32(p + 0x18))))
            do
                local tp = rp(p + 0x20)
                if SL.kptr(tp) then
                    E("template", SL.Q(tokname(ru32(tp + 8))))
                end
            end
            E("name", SL.Q(sso(p + 0x48)))
            do
                local tid = ru32(p + 0x68)
                if tid and tid > 0 then
                    local t = tagstr(tid)
                    if t then E("country", '"' .. t .. '"') end
                end
                local nid = ru32(p + 0x6C)
                if nid and nid > 0 then
                    local t = tagstr(nid)
                    if t then E("nationality", '"' .. t .. '"') end
                end
            end
            E("gender", GENDER[ru32(p + 0x70) or 0])
            -- portraits (§4.4.10; reader 已验收: ptype/size/path; 键按 ptype 编号)
            do
                local okp, rpor = pcall(function()
                    return O:char_portraits(ch.id) end)
                if okp and rpor and rpor.count > 0 then
                    local pseq = SL.seqc()
                    for _, po in ipairs(rpor.list) do
                        local k = pseq(tostring(po.ptype))
                        -- path 空串也写 "" (锚件 1,464 叶 portraits
                        -- .* = "" 实证; SL.Q 会滤空故不走)
                        if po.path ~= nil then
                            E("portraits." .. k .. "." .. tostring(po.size),
                                '"' .. po.path .. '"')
                        end
                    end
                end
            end
            emit_leader(P, p)
            -- operative 对 (§4.4.11 +200/+204; type@+0xC8, id@+0xCC;
            -- 任一非零)
            do
                local ot, oi = ru32(p + 0xC8) or 0, ru32(p + 0xCC) or 0
                if ot ~= 0 or oi ~= 0 then
                    E("operative", SL.idpair(oi, ot))
                end
            end
            -- country_leaders (§4.4.16 CCountryLeader) + scientist
            -- (§4.4.17 CScientist; reader 已验收)
            do
                local oks, r59 = pcall(function()
                    return O:char_subblocks(ch.id) end)
                if oks and r59 then
                    local lseq = SL.seqc()
                    for _, ld in ipairs(r59.leaders or {}) do
                        local lk = lseq("country_leader")
                        local LP = "country_leaders." .. lk
                        E(LP .. ".desc", SL.Q(ld.desc))
                        if ld.ideology and ld.ideology ~= "nil" then
                            E(LP .. ".ideology", tostring(ld.ideology))
                        end
                        if ld.traits and #ld.traits > 0 then
                            E(LP .. ".traits",
                                table.concat(ld.traits, " "))
                        end
                        if ld.expire_hours then
                            E(LP .. ".expire", Qd(ld.expire_hours))
                        end
                        if ld.id then E(LP .. ".id", tostring(ld.id)) end
                    end
                    local sc = r59.scientist
                    if sc then
                        for ti, tn in ipairs(sc.traits or {}) do
                            if tn and tn ~= "" and tn ~= "nil" then
                                E("scientist.traits.#" .. ti,
                                    '"' .. tn .. '"')
                            end
                        end
                        for _, sk5 in ipairs(sc.skills or {}) do
                            local spec, lvl, exp =
                                tostring(sk5):match("^([^|]+)|([^|]+)|(.*)$")
                            if spec then
                                lvl, exp = tonumber(lvl), tonumber(exp)
                                if lvl and lvl > 0 then
                                    E("scientist.skills." .. spec .. ".level",
                                        tostring(lvl))
                                end
                                if exp and exp > 0 then
                                    E("scientist.skills." .. spec
                                        .. ".experience", SL.num(exp))
                                end
                            end
                        end
                        if sc.is_assigned == 1 then
                            E("scientist.is_assigned", "yes")
                        end
                        if sc.injured and sc.injured > 0 then
                            E("scientist.injured", tostring(sc.injured))
                        end
                        E("scientist.desc", SL.Q(sc.desc))
                    end
                end
            end
            emit_advisors(P, p)
            -- variables.random + flags (§4.4.10 variables / §4.4.11
            -- flags +272; reader 已验收)
            do
                local okx, rx = pcall(function()
                    return O:char_extras(ch.id) end)
                if okx and rx then
                    if rx.random and rx.random ~= "nil" then
                        E("variables.random", rx.random)
                    end
                    for _, fv in ipairs(rx.flags or {}) do
                        local fn = tostring(fv.name)
                        if fn ~= "" and fn ~= "nil" then
                            local FP = "flags." .. fn
                            if fv.value ~= nil then
                                E(FP .. ".value", tostring(fv.value))
                            end
                            if fv.date and fv.date ~= "nil" then
                                E(FP .. ".date", '"' .. fv.date .. '"')
                            end
                            if fv.days and fv.days ~= 0 then
                                E(FP .. ".days", tostring(fv.days))
                            end
                        end
                    end
                end
            end
            -- 变量数组 (^N / ^num 键; cultures^0=33 等 36 叶实证)。
            -- CVariables 内嵌 @p+216 (§4.4.10; char_extras 同源;
            -- ⚠ 非 +0xD8 指针 — 首版两错: 挂载错 + 无 BB9830 判空门,
            -- 爆 54 万假叶)
            do
                local vo = p + 216
                local vcnt = ru32(vo + 32) or 0
                if vcnt > 0 and vcnt < GAME.layout.lim.PTR_HUGE then
                    local LAY2 = GAME.layout
                    local buckets = LAY2 and LAY2.rh_iter(vo,
                        { data = 0x18, mask = 0x24, count = 0x20,
                            stride = 0x30,
                            maxn = LAY2.lim and LAY2.lim.PTR_HUGE or 65536 })
                    local vlist = {}
                    for _, b in ipairs(buckets or {}) do
                        local dist = ru32(b + 4)
                        if dist and (dist & 0xFF) ~= 0
                            and (dist & 0xFF) ~= 0xFE
                            and (dist & 0xFF) ~= 0xFF then
                            local nm = SL.sso(b + 8)
                            local v = rp(b + 0x28)
                            if v then v = GAME.layout.as_i64(v) end
                            if nm and v then
                                vlist[#vlist + 1] = nm .. "|"
                                    .. string.format("%.5f", v / 100000)
                            end
                        end
                    end
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
                                E("variables." .. nm, vs)
                            end
                        end
                    end
                end
            end
        end
    end
end }
