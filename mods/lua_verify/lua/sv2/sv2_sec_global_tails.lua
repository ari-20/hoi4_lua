-- sv2_sec_global_tails.lua -- 全局小块扫尾 savefull 直出 (gsec)

local SL = SV2.lib
local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
local ri64 = SL.rp_i64
local kptr = SL.kptr

-- §3.7 数值换算: i64×1e-5 定点读
local function fix5(a)
    local v = a and ri64(a) or nil
    return v and (v * 1e-5) or nil
end

-- u32 位型 → IEEE754 f32 (§3.7 数值换算; objects_v2 N33_u32_as_f32 同构)
local function f32(a)
    local bits = a and ru32(a) or nil
    if not bits then return nil end
    if bits == 0 then return 0.0 end
    local s = math.floor(bits / 2 ^ 31) % 2
    local e = math.floor(bits / 2 ^ 23) % 256
    local m = bits % 2 ^ 23
    local v
    if e == 0 then v = m / 2 ^ 23 * 2 ^ -126
    else v = (1 + m / 2 ^ 23) * 2 ^ (e - 127) end
    if s == 1 then v = -v end
    return v
end

-- §3.7b CGameDate 三变体 (哨兵值/门语义 = 书 §3.7b):
-- date3 = 无门字段用 (哨兵值也照写; SL.date 对 43808760 恒 nil 故单列);
-- date2 = 带 != 门字段用 (默认构造值视同未设, 不写)。
local function date3(h)
    if h == 43808760 then return "1.1.1.1" end
    return SL.date(h)
end
local function date2(h)
    if not h or h == 43817520 then return nil end
    return date3(h)
end

local function Q(s) return SL.Q(s) end

-- §3.3 std::map RB-tree 中序遍历 (节点: left@0 parent@8 right@16
-- 哨兵 byte@+25; head->left = leftmost; 写序 = 中序;
-- 后继逻辑逐字对齐 writer (dominance 0x140FF11E0 / mods 0x142063840))
-- 收敛: RB 中序 walker 公共化 (hoi4_layout.M.rb_inorder; 审查去重)
local rb_inorder = GAME.layout.rb_inorder

-- §4.25.1 CVariables 发射 (布局/写门/键序 = 书 §4.25.1; 写序 = 键字节序;
-- ^num 行 = #N 匿名, 同 sv2_sec_c_variables)
local function emit_cvariables(emit, dim, prefix, vo)
    local r8 = ru32(vo + 8)
    if r8 and r8 ~= 1 then
        emit(dim, prefix .. "random", string.format("%d %d",
            ru32(vo + 12) or 0, r8))
    end
    local buckets = GAME.layout.rh_iter(vo, { data = 0x18, mask = 0x24,
        stride = 0x30, maxn = 262144 })  -- 8192 被超大型 mod 数千条击穿;
        -- TFR USA 3.1 万变量再到 131072 桶档, PTR_HUGE(65536) 亦蒸发 → 262144
    local list = {}
    for _, b in ipairs(buckets or {}) do
        local dist = ru32(b + 4)
        if dist and (dist & 0xFF) ~= 0 and (dist & 0xFF) ~= 0xFE
            and (dist & 0xFF) ~= 0xFF then
            local nm = SL.sso(b + 8)
            local val = fix5(b + 0x28)
            if nm and val then list[#list + 1] = nm .. "|" .. SL.num(val) end
        end
    end
    table.sort(list) -- 键字节序 (名不含 |)
    local seq = 0
    for _, kv in ipairs(list) do
        local nm, val = kv:match("^(.-)|(.*)$")
        if nm then
            if nm:find("%^num$") then
                seq = seq + 1
                emit(dim, prefix .. "#" .. seq, nm .. "=" .. val)
            else
                emit(dim, prefix .. nm, val)
            end
        end
    end
end

-- §4.5.8 CStrategicResourcePool extracted 资源池 (faction+2320 /
-- facsys+56 同类对象; 布局/写门/键序 = 书 §4.5.8)
local function emit_extracted(emit, dim, obj)
    local d, c = rp(obj + 8), ru32(obj + 20)
    if not (kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_SANE) then return end
    for i = 0, c - 1 do
        local raw = ri64(d + 16 * i)
        if raw and raw ~= 0 then
            local nid = ru32(d + 16 * i + 8)
            local nm = nid and SL.tok(nid)
            if nm then emit(dim, "extracted." .. nm, SL.num(raw * 1e-5)) end
        end
    end
end

-- §4.3.8 CModifier 通用布局 (faction upgrades 槽 modifier/spymaster
-- 对象, 与 sv2_sec_character_manager.lua modifier_pairs 同构;
-- 布局/写门 = 书 §4.3.8; 修饰定义表访问 = GAME.layout.modifier_token)
local function emit_modobj(emit, base, mo, BASE)
    local nm = SL.sso(mo + 88)
    if nm and nm ~= "" then emit(base .. ".name", Q(nm)) end
    local d, c = rp(mo + 16), ru32(mo + 28)
    if kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_SANE then
        for i = 0, c - 1 do
            -- 定义表散写回收 : defidx → modifier_token
            local name = GAME.layout.modifier_token(ru32(d + 16 * i))
            local val = fix5(d + 16 * i + 8)
            if name and val then emit(base .. "." .. name, SL.num(val)) end
        end
    end
    local dv = ru32(mo + 188)
    if dv and dv ~= 1 then emit(base .. ".data", tostring(dv)) end
end

-- §4.5.4 tech_sharing_group 公共尾 (writer 0x140D6F910):
-- bonuses {d@+48,c@+60}
-- i64×1e-5 数组整行空格连 (#1 单键); countries {d@+24,c@+36} u32 国 idx
-- 引号逐条。base 为空时无前缀 (全局 tsg), 否则 "base." 前缀 (faction)
local function emit_tsg_tail(emit, base, tsg, O)
    local pfx = base ~= "" and (base .. ".") or ""
    local bd, bc = rp(tsg + 48), ru32(tsg + 60)
    if kptr(bd) and bc and bc > 0 and bc < GAME.layout.lim.PTR_SANE then
        local parts = {}
        for i = 0, bc - 1 do
            parts[#parts + 1] = SL.num(fix5(bd + 8 * i) or 0)
        end
        emit(pfx .. "bonuses.#1", table.concat(parts, " "))
    end
    local cd, cc = rp(tsg + 24), ru32(tsg + 36)
    if kptr(cd) and cc and cc > 0 and cc < GAME.layout.lim.PTR_SANE then
        for i = 0, cc - 1 do
            local t = O:tag(ru32(cd + 4 * i) or 0)
            if t then emit(pfx .. "countries.#" .. (i + 1), Q(t)) end
        end
    end
end

-- §3.6 id 对 idpair (内存 {type u32@off, id u32@off+4}; 写 "id=N type=T";
-- 双零 = 空不写; 证据 sub_14220B240: a2[1]=id 先写, a2[0]=type)
local function idpair_at(el, off)
    local ty, id = ru32(el + off), ru32(el + off + 4)
    if (ty and ty ~= 0) or (id and id ~= 0) then
        return SL.idpair(id or 0, ty or 0)
    end
    return nil
end

-- idref 解析 = 统一访问器 GAME.layout.idreg_unit_resolve(ty, id)
-- (§4.26.5 补全访问器; resource.lua; sub_14220A3D0 + 0x1422083E0
-- 三源分域 RH, 段内散写回收; 桶 24B {dist@+4,type@+8,id@+12,obj*@+16},
-- 键 hash = 1231231557*(type<<32|id) mod 2^64)

-- §4.5.4 faction tech_sharing_group.upgrade = 逐国共享研究和 (writer
-- 0x141BD1A90 → sub_141BD13D0): def = *(tsg+72), 国家对 {d@def+2000,
-- c@def+2012} 8B idref {type, id}, 和 = Σ *(国对象+188) (study 数)
local function tsg_upgrade(tsg, BASE)
    local def = rp(tsg + 72)
    if not kptr(def) then return 0 end
    local pd, pc = rp(def + 2000), ru32(def + 2012)
    if not (kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_SANE) then return 0 end
    local sum = 0
    for i = 0, pc - 1 do
        local ty, id = ru32(pd + 8 * i), ru32(pd + 8 * i + 4)
        if (ty or 0) ~= 0 or (id or 0) ~= 0 then
            local obj = GAME.layout.idreg_unit_resolve(ty, id)
            if obj then sum = sum + (ru32(obj + 188) or 0) end
        end
    end
    return sum
end

-- ============================================================
-- §4.5.2 CFaction faction (挂 facsys 容器 = §1.2 +1016 CFactionSystem;
-- 布局/写序 = 书 §4.5.2; dim 第二起 [N])
-- ============================================================
local function emit_one_faction(ctx, dim, fr)
    local emit, O, BASE = ctx.emit, ctx.O, ctx.BASE
    local function E(p, v) emit(dim, p, v) end
    E("id", SL.idpair(ru32(fr + 12), ru32(fr + 8)))
    do
        local nsz = ru32(fr + 40)
        if nsz and nsz > 0 then E("name", Q(SL.sso(fr + 24))) end
    end
    E("icon", Q(SL.sso(fr + 1352)))
    -- color {vt@+2512, r/g/b/a f32@+2528..}: int(f*255) 截断, alpha 仅 !=1.0
    -- (CColor writer 0x142237AD0 = (int)(float)(f*255.0), 无 +0.5;
    -- 实测锚件 15/15 分量截断命中, round-half 在 fraction>0.5 处分歧)
    do
        local r, g, b, a = f32(fr + 2528), f32(fr + 2532), f32(fr + 2536),
            f32(fr + 2540)
        if r and g and b then
            local s = string.format("%d %d %d",
                math.floor(r * 255), math.floor(g * 255),
                math.floor(b * 255))
            if a and a ~= 1.0 then
                s = s .. " " .. tostring(math.floor(a * 255))
            end
            E("color", s)
        end
    end
    E("is_color_overridden", SL.yn(ru8(fr + 2496) or 0))
    do -- ideology: def 对象@+136, token idx@def+8, 裸名
        local def = rp(fr + 136)
        if kptr(def) then E("ideology", SL.tok(ru32(def + 8) or 0)) end
    end
    do -- members {d@+88, c@+100} 8B 国指针 → tag (引号), 容器序
        local md, mc = rp(fr + 88), ru32(fr + 100)
        if kptr(md) and mc and mc > 0 and mc < GAME.layout.lim.PTR_SANE then
            for i = 0, mc - 1 do
                local cc = rp(md + 8 * i)
                local t = kptr(cc) and O:tag(ru32(cc + 8) or 0)
                if t then E("members.#" .. (i + 1), Q(t)) end
            end
        end
    end
    do -- faction_leader_change_date: hours@+120, != 哨兵 (0x29C3388) 才写
        local ds = date2(ru32(fr + 120))
        if ds then E("faction_leader_change_date", Q(ds)) end
    end
    do -- template: def@+1384 → token 名, 引号 (sub_1424A96A0 = token 查表)
        local def = rp(fr + 1384)
        if kptr(def) then
            local nm = SL.tok(ru32(def + 8) or 0)
            if nm then E("template", Q(nm)) end
        end
    end
    -- rule_status @+1392: 内容为裸名表行, 提取器不落 → 不发射
    do -- goal_status 内联对象 @+1568 (§4.5.3 CFactionGoalStatus; writer 0x140A1AA00)
        local gso = fr + 1568
        local mdef = rp(gso + 16)
        if kptr(mdef) then
            E("goal_status.manifest", SL.tok(ru32(mdef + 8) or 0))
        end
        local GSTATUS = { [0] = "active", [1] = "completed", [2] = "canceled" }
        local gd, gc = rp(gso + 24), ru32(gso + 36)
        if kptr(gd) and gc and gc > 0 and gc < GAME.layout.lim.PTR_SANE then
            for i = 0, gc - 1 do
                local el = gd + 1344 * i -- 336 dword 步长
                local kp = "goal_status.goals.#" .. (i + 1)
                local gdef = rp(el)
                if kptr(gdef) then
                    E(kp .. ".goal", SL.tok(ru32(gdef + 8) or 0))
                end
                E(kp .. ".status", GSTATUS[ru32(el + 8) or 0] or "active")
                -- game_data: CGameDate vt@el+1336, hours@+1328; 恒写
                local ds = date3(ru32(el + 1328))
                if ds then E(kp .. ".game_data", Q(ds)) end
            end
        end
        -- completed_goals/canceled_goals: 裸名表行 → 不发射
        do -- extra_goal_slots {d@+120, c@+132} u32, 仅非零写, 名按槽位
            local SLOTN = { [0] = "short_term", "medium_term", "long_term" }
            local sd, sc = rp(gso + 120), ru32(gso + 132)
            if kptr(sd) and sc and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
                for i = 0, sc - 1 do
                    local v = ru32(sd + 4 * i)
                    if v then v = GAME.layout.as_i32(v) end
                    if v and v ~= 0 and SLOTN[i] then
                        E("goal_status.extra_goal_slots." .. SLOTN[i],
                            tostring(v))
                    end
                end
            end
        end
        do -- game_data {d@+320, c@+332} 24B, hours@+8 (AD590(el+16))
            local dd, dc = rp(gso + 320), ru32(gso + 332)
            if kptr(dd) and dc and dc > 0 and dc < GAME.layout.lim.PTR_SANE then
                for i = 0, dc - 1 do
                    local ds = date3(ru32(dd + 24 * i + 8))
                    if ds then
                        E("goal_status.game_data.#" .. (i + 1), Q(ds))
                    end
                end
            end
        end
    end
    -- power_projection_from_effects: i64 定点 @+2088, 非零才写 (存档恒 0)
    do
        local pp = fix5(fr + 2088)
        if pp and pp ~= 0 then
            E("power_projection_from_effects", SL.num(pp))
        end
    end
    -- manpower_pool ×2 @+2288 (writer 0x140C5B610): {data@+8, count@+20}
    -- 8B 指针元素 → 行 {tagidx u32@0, value u32@4}; value>0 才写行;
    -- 叶 = 重复键 manpower_pool[2].value, 值 "tag=\"X\" value=N"
    -- (对拍定案)。#1 池 @+2288 本档恒空。
    do
        local md, mc = rp(fr + 2288 + 8), ru32(fr + 2288 + 20)
        if kptr(md) and mc and mc > 0 and mc < GAME.layout.lim.PTR_SANE then
            for i = 0, mc - 1 do
                local val = ru32(md + 8 * i + 4)
                if val and val > 0 then
                    local t = O:tag(ru32(md + 8 * i) or 0)
                    if t then
                        E("manpower_pool[2].value",
                            'tag="' .. t .. '" value=' .. val)
                    end
                end
            end
        end
    end
    -- faction_programs @+1992 (writer 0x1419802B0): {data@+8, count@+20}
    -- 内联 8B idpair {type@0, id@+4}; count>0 才写块;
    -- 叶 = faction_programs.faction_programs.#K = "id=N type=T"
    do
        local pd, pc = rp(fr + 1992 + 8), ru32(fr + 1992 + 20)
        if kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_SANE then
            for i = 0, pc - 1 do
                local ty, id = ru32(pd + 8 * i), ru32(pd + 8 * i + 4)
                if (ty or 0) ~= 0 or (id or 0) ~= 0 then
                    E("faction_programs.faction_programs.#" .. (i + 1),
                        "id=" .. (id or 0) .. " type=" .. (ty or 0))
                end
            end
        end
    end
    -- pings @+2552 (§4.5.2; 布局/写门/键序/execution_type 枚举 = 书 §4.5.2 子表)。
    do
        local gobj = fr + 2552
        local gc = ru32(gobj + 28)
        if gc and gc > 0 and gc < GAME.layout.lim.PTR_SANE then
            local gd = rp(gobj + 16)
            if kptr(gd) then
                local EXEC = { [0] = "careful", [1] = "balanced",
                    [2] = "rush", [3] = "rush_weak" }
                for i = 0, gc - 1 do
                    local el = gd + 168 * i
                    local kp = "pings.regions.#" .. (i + 1)
                    local nm = SL.sso(el)
                    if nm and nm ~= "" then E(kp .. ".name", Q(nm)) end
                    local tgi = ru32(el + 32)
                    if tgi and tgi > 0 then
                        local t = O:tag(tgi)
                        if t then E(kp .. ".tag", Q(t)) end
                    end
                    local cid, cty = ru32(el + 40), ru32(el + 36)
                    if (cty or 0) ~= 0 or (cid or 0) ~= 0 then
                        E(kp .. ".commander",
                            "id=" .. (cid or 0) .. " type=" .. (cty or 0))
                    end
                    local ex = EXEC[ru32(el + 120) or 0]
                    if ex then E(kp .. ".execution_type", ex) end
                    local tdef = rp(el + 128)
                    if kptr(tdef) then
                        local tn = GAME.layout.token_name(ru32(tdef + 8) or 0)
                        if tn and tn ~= "" then E(kp .. ".template", tn) end
                    end
                    -- countries 标签列: 首个与首行同行, #2+ 走 @.#(j-1)
                    -- (提取器半匿名对象续行怪癖, 对拍定案)
                    do
                        local cd2, cc2 = rp(el + 48), ru32(el + 60)
                        if kptr(cd2) and cc2 and cc2 > 0 and cc2 < GAME.layout.lim.PTR_SANE then
                            local parts = {}
                            for j = 0, cc2 - 1 do
                                local t = O:tag(ru32(cd2 + 4 * j) or 0)
                                if not t then parts = nil break end
                                parts[#parts + 1] = '"' .. t .. '"'
                            end
                            if parts then
                                E(kp .. ".countries",
                                    "countries={ " .. parts[1])
                                for j = 2, #parts do
                                    E(kp .. ".@.#" .. (j - 1), parts[j])
                                end
                            end
                        end
                    end
                    -- ids 整数列 (空格连接)
                    do
                        local dd2, dc2 = rp(el + 72), ru32(el + 84)
                        if kptr(dd2) and dc2 and dc2 > 0 and dc2 < GAME.layout.lim.PTR_SANE then
                            local parts = {}
                            for j = 0, dc2 - 1 do
                                parts[#parts + 1] =
                                    tostring(ru32(dd2 + 4 * j) or 0)
                            end
                            E(kp .. ".ids", table.concat(parts, " "))
                        end
                    end
                    -- selection_order / hidden 同形整数列 (空跳过)
                    for _, iv in ipairs({ { 96, "selection_order" },
                        { 136, "hidden" } }) do
                        local dd3, dc3 = rp(el + iv[1]), ru32(el + iv[1] + 12)
                        if kptr(dd3) and dc3 and dc3 > 0 and dc3 < GAME.layout.lim.PTR_SANE then
                            local parts = {}
                            for j = 0, dc3 - 1 do
                                parts[#parts + 1] =
                                    tostring(ru32(dd3 + 4 * j) or 0)
                            end
                            E(kp .. "." .. iv[2], table.concat(parts, " "))
                        end
                    end
                end
            end
        end
    end
    emit_extracted(emit, dim, fr + 2320)
    do -- upgrades 内联对象 @+2104 (§4.5.4 CFactionUpgradeStatus; writer 0x1413E6F60)
        local upg = fr + 2104
        -- member_upgrades RH @+16: 裸名表行 → 不发射
        local sd, sc = rp(upg + 152), ru32(upg + 164) -- slots, 424B
        if kptr(sd) and sc and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
            for i = 0, sc - 1 do
                local sl = sd + 424 * i
                local kp = "upgrades.slots.#" .. (i + 1)
                local oid = ru32(sl + 8) -- owner: i32>0 才写 (本存档无)
                if oid and oid > 0 then
                    local t = O:tag(oid)
                    if t then E(kp .. ".owner", Q(t)) end
                end
                -- advisor (§4.5.4 slots; writer 0x1413E6F60:
                -- ADCE0(10454, *(*(getter(*(slot))+16)+24); getter 实 =
                -- 槽 def@+0 → 名对象@def+16 → 角色名 token@+24; 探针实证
                -- rp(rp(sl+0)+16)+24 = GER_wilhelm_canaris 命中)
                local adef = rp(sl)
                local nobj = kptr(adef) and rp(adef + 16)
                if kptr(nobj) then
                    local nm = GAME.layout.token_name(ru32(nobj + 24) or 0)
                    if nm and nm ~= "" then E(kp .. ".advisor", nm) end
                end
                local cd = date2(ru32(sl + 24)) -- spymaster_change_date (无)
                if cd then E(kp .. ".spymaster_change_date", Q(cd)) end
                emit_modobj(E, kp .. ".modifier", sl + 232, BASE)
                emit_modobj(E, kp .. ".spymaster", sl + 40, BASE)
            end
        end
        do -- upgrades.tech_sharing_group @upg+40 (writer 0x141BD1A90)
            local tsg = upg + 40
            -- upgrade = 逐国共享研究和 (§4.5.4; sub_141BD13D0 →
            -- idreg_unit_resolve, 段头注释)
            E("upgrades.tech_sharing_group.upgrade",
                tostring(tsg_upgrade(tsg, BASE)))
            emit_tsg_tail(E, "upgrades.tech_sharing_group", tsg, O)
        end
        -- upgrades.doctrine @+120: 空块 → 不发射
    end
    E("research", SL.yn(ru8(fr + 2616) or 0))
    E("manpower", SL.yn(ru8(fr + 2617) or 0))
    -- variables: CVariables 内联 @+2624 (§4.25.1) — 写门 = CFaction writer
    -- 0x140D7B4D0 尾部 → sub_140BB9830 空谓词: count u32@vo+32==0 且
    -- random_hi u32@vo+8==1 → 整块不写 (count=0 但桶区脏时 rh_iter
    -- 误发; 按谓词整块跳过 = 与 writer 对齐)
    do
        local vo = fr + 2624
        if not ((ru32(vo + 32) or 0) == 0 and (ru32(vo + 8) or 0) == 1) then
            emit_cvariables(emit, dim, "variables.", vo)
        end
    end
end

local function sec_factions(ctx)
    local cont = rp(ctx.gs + 0x3F8)
    if not kptr(cont) then return end
    local data, cnt = rp(cont + 32), ru32(cont + 44)
    if not (kptr(data) and cnt and cnt > 0 and cnt < GAME.layout.lim.PTR_SANE) then return end
    for i = 0, cnt - 1 do
        local fr = rp(data + 8 * i)
        if kptr(fr) then
            local dim = i == 0 and "faction" or ("faction[" .. (i + 1) .. "]")
            emit_one_faction(ctx, dim, fr)
        end
    end
end

-- ============================================================
-- §4.5.1 CFactionMemberStatus faction_system (布局/写门 = 书 §4.5.1)
-- ============================================================
local function sec_faction_system(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local fs = rp(gs + 0x3F8)
    if not kptr(fs) then return end
    local dim = "faction_system"
    -- countries 稀疏阵 @fs+8: {data@+8, size@+20}, 元素 208B (0xD0);
    -- 槽占用 = 国有效 (sub_141179250: idx>0 且 *(*(国+3976)+656)≠0)
    -- 或 completed_faction_goals 计数@+196 ≠0; 写: index=槽号 + data
    local data, size = rp(fs + 8), ru32(fs + 20)
    if kptr(data) and size and size > 0 and size < GAME.layout.lim.PTR_SANE then
        local carr = rp(gs + 0x310)
        local n = 0
        for i = 0, size - 1 do
            local el = data + 208 * i
            local cidx = ru32(el) or 0
            local occupied = false
            if cidx > 0 and kptr(carr) then
                local cc = rp(carr + 8 * cidx)
                local dip = kptr(cc) and rp(cc + 3976)
                if kptr(dip) and (rp(dip + 656) or 0) ~= 0 then
                    occupied = true
                end
            end
            if not occupied and (ru32(el + 196) or 0) ~= 0 then
                occupied = true
            end
            if occupied then
                n = n + 1
                local kp = "countries.#" .. n
                -- (槽位叶见下)
                emit(dim, kp .. ".index", tostring(i))
                -- influence_status 稀疏阵 @el+8 {data@+8, size@+20},
                -- 8B i64 定点; 占用 = 值非零 (λ 0x14117A830 实证);
                -- 全空 → 提取器把裸 size 记为 #1 标量
                local idata, isize = rp(el + 8), ru32(el + 20) or 0
                local k = 0
                if kptr(idata) and isize > 0 and isize < GAME.layout.lim.PTR_SANE then
                    for s = 0, isize - 1 do
                        local raw = ri64(idata + 8 * s)
                        if raw and raw ~= 0 then
                            k = k + 1
                            emit(dim, kp .. ".data.influence_status.#" .. k
                                .. ".index", tostring(s))
                            emit(dim, kp .. ".data.influence_status.#" .. k
                                .. ".data", SL.num(raw * 1e-5))
                        end
                    end
                end
                if k == 0 then
                    emit(dim, kp .. ".data.influence_status.#1",
                        tostring(isize))
                end
                -- initiative i64×1e-5@+72, 非零才写
                local ini = fix5(el + 72)
                if ini and ini ~= 0 then
                    emit(dim, kp .. ".data.initiative", SL.num(ini))
                end
                -- contribution i64×1e-5@+120, 非零才写 (本存档恒 0)
                local con = fix5(el + 120)
                if con and con ~= 0 then
                    emit(dim, kp .. ".data.contribution", SL.num(con))
                end
                -- contribution_gain: 恒写两定点 @+128/+136 空格连
                emit(dim, kp .. ".data.contribution_gain.#1",
                    SL.num(fix5(el + 128) or 0) .. " "
                    .. SL.num(fix5(el + 136) or 0))
                -- member_upgrades/completed_faction_goals: 裸名表行 → 不发射
                emit(dim, kp .. ".data.war_score_breakdown",
                    SL.num(fix5(el + 176) or 0))
            end
        end
    end
    -- 无占槽时容量独占一行 → 提取器记裸标量 countries.#1 (实证
    -- countries={ 579 } 形); 有槽时容量与首槽 { 同行被 BARE 吞
    -- (对拍 countries={ 233 { 实证) → 只在零槽时补发
    if n == 0 then
        emit(dim, "countries.#1", tostring(size))
    end
    emit_extracted(emit, dim, fs + 56)
end

-- ============================================================
-- §4.25.2 region 制海族 (挂 §1.2 +736 数组, id 1..count-1;
-- 布局/写序 = 书 §4.25.2)
-- ============================================================
local function sec_region(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local rarr, rcnt = rp(gs + 736), ru32(gs + 748)
    if not (kptr(rarr) and rcnt and rcnt > 1 and rcnt < 4096) then return end
    local dim = "region"
    for id = 1, rcnt - 1 do
        local robj = rp(rarr + 8 * id)
        if kptr(robj) then
            local pfx = id .. "."
            if (ru32(robj + 72) or 0) ~= 0 then -- name (本存档无)
                local nm = SL.sso(robj + 56)
                if nm and nm ~= "" then emit(dim, pfx .. "name", Q(nm)) end
            end
            local dom = rp(robj + 232)
            if kptr(dom) then
                -- countries: RB tree @dom+16, key 国 idx@node+28,
                -- 裸 tag 空格连; 空树 → "{}"
                local tags = {}
                for _, node in ipairs(rb_inorder(rp(dom + 16))) do
                    local t = O:tag(ru32(node + 28) or 0)
                    if t then tags[#tags + 1] = t end
                end
                emit(dim, pfx .. "dominance.countries",
                    #tags > 0 and table.concat(tags, " ") or "{}")
                -- values: RH @dom+32 (桶/值布局与 key 升序写序 = 书 §4.25.2)
                if (ru32(dom + 48) or 0) > 0 then
                    local bd = rp(dom + 40)
                    local cap = (ru32(dom + 52) or 0) + 1
                        + (ru8(dom + 56) or 0)
                    local ents = {}
                    if kptr(bd) and cap > 0 and cap < 4096 then
                        for b = 0, cap - 1 do
                            local bk = bd + 88 * b
                            local dist = ru8(bk + 4) or 0
                            if dist ~= 0 and dist ~= 0xFE and dist ~= 0xFF then
                                ents[#ents + 1] = {
                                    key = ru32(bk + 8) or 0, b = bk }
                            end
                        end
                    end
                    table.sort(ents, function(x, y) return x.key < y.key end)
                    for ki, en in ipairs(ents) do
                        local t = O:tag(en.key)
                        local bk = en.b + 16
                        local kp = pfx .. "dominance.values.#" .. ki
                        -- tag 行编号 = 提取器半行匿名收尾机制 (savefull3.py
                        -- 实证): 元素 #1 的内层匿名块同名 '#1', 收尾提前在
                        -- 内层闭括号触发 → tag 带 '.#1'; 元素 #2+ 收尾在
                        -- 元素层 pop 后 → tag 落裸 'values' (region.76
                        -- 双国实证); 块字段恒 values.#N.#1.*
                        local tagp = ki == 1 and kp
                            or (pfx .. "dominance.values")
                        if t then emit(dim, tagp, Q(t)) end
                        local sp = kp .. ".#1."
                        local function F(off, fld)
                            local v = fix5(bk + off)
                            if v then emit(dim, sp .. fld, SL.num(v)) end
                        end
                        F(24, "current")
                        F(40, "target")
                        F(32, "base_target")
                        F(56, "previous")
                        F(64, "decline_from")
                        F(48, "individual_ratio")
                    end
                end
            end
        end
    end
end

-- ============================================================
-- §4.25.3 CWorldThreat threat (挂 §1.2 +1712; 布局/写门 = 书 §4.25.3)
-- ============================================================
local function sec_threat(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local holder = rp(gs + 1712)
    if not kptr(holder) then return end
    local d, c = rp(holder + 16), ru32(holder + 28)
    if not (kptr(d) and c and c > 0 and c < 4096) then return end
    local seq = SL.seqc()
    for i = 0, c - 1 do
        local el = rp(d + 8 * i)
        if kptr(el) then
            local kp = seq("threat") .. "."
            local dim = "threat"
            emit(dim, kp .. "threat", SL.num(fix5(el + 16) or 0))
            emit(dim, kp .. "final_threat", SL.num(fix5(el + 24) or 0))
            emit(dim, kp .. "daily", SL.num(fix5(el + 32) or 0))
            local ti = ru32(el + 8) -- tag: >0 才写
            if ti and ti > 0 then
                local t = O:tag(ti)
                if t then emit(dim, kp .. "tag", Q(t)) end
            end
            local tg = ru32(el + 12) -- target: >0 才写 (本存档无)
            if tg and tg > 0 then
                local t = O:tag(tg)
                if t then emit(dim, kp .. "target", Q(t)) end
            end
            local ds = date3(ru32(el + 48)) -- CGameDate vt@+56, hours@+48
            if ds then emit(dim, kp .. "date", Q(ds)) end
            local lb = SL.sso(el + 64) -- label: 非二进制档恒写
            if lb then emit(dim, kp .. "label", Q(lb)) end
        end
    end
end

-- ============================================================
-- §4.3.21 CPowerBalanceSystem power_balance (挂 §1.2 +1104;
-- 布局/写门 = 书 §4.3.21)
-- ============================================================
local function sec_power_balance(ctx)
    local emit, O, gs, BASE = ctx.emit, ctx.O, ctx.gs, ctx.BASE
    local sys = rp(gs + 0x450)
    if not (kptr(sys) and rp(sys) == BASE + GAME.layout.vt.CPowerBalanceSystem) then return end
    local data, n = rp(sys + 8), ru32(sys + 20)
    if not (kptr(data) and n and n > 0 and n < 4096) then return end
    local dim = "power_balance"
    local function sso16(p) -- *(p)+16 处 MSVC 串 (template/sides 定义对象)
        local o = rp(p)
        return kptr(o) and SL.sso(o + 16) or nil
    end
    for i = 0, n - 1 do
        local e = data + 400 * i
        if rp(e) == BASE + GAME.layout.vt.CPowerBalanceEntry then
            local kp = "power_balances.#" .. (i + 1) .. "."
            emit(dim, kp .. "template", Q(sso16(e + 16)))
            emit(dim, kp .. "value", SL.num(fix5(e + 48) or 0))
            emit(dim, kp .. "left_side", Q(sso16(e + 24)))
            emit(dim, kp .. "right_side", Q(sso16(e + 32)))
            emit(dim, kp .. "trending_side", Q(sso16(e + 40)))
            local cd, cc = rp(e + 56), ru32(e + 68) -- countries u32 idx>0
            if kptr(cd) and cc and cc > 0 and cc < GAME.layout.lim.PTR_SANE then
                local k = 0
                for j = 0, cc - 1 do
                    local ci = ru32(cd + 4 * j)
                    if ci and ci > 0 then
                        local t = O:tag(ci)
                        if t then
                            k = k + 1
                            emit(dim, kp .. "countries.#" .. k, Q(t))
                        end
                    end
                end
            end
            local sd, sc = rp(e + 376), ru32(e + 388) -- sides 80B
            if kptr(sd) and sc and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
                for j = 0, sc - 1 do
                    local s = sd + 80 * j
                    local sp = kp .. "sides.#" .. (j + 1) .. "."
                    emit(dim, sp .. "id", Q(SL.sso(s + 8)))
                    emit(dim, sp .. "gfx", Q(SL.sso(s + 0x30)))
                end
            end
            local md, mc = rp(e + 80), ru32(e + 92) -- modifier 8B 指针
            if kptr(md) and mc and mc > 0 and mc < GAME.layout.lim.PTR_SANE then
                for j = 0, mc - 1 do
                    local p = rp(md + 8 * j)
                    local nm = kptr(p) and SL.sso(p + 424)
                    if nm then emit(dim, kp .. "modifier", Q(nm)) end
                end
            end
        end
    end
end

-- ============================================================
-- §4.16.13 CSunkShipInfo history (挂 §1.2 +1424 sunk_ship 历史容器;
-- 布局/写门 = 书 §4.16.13)
-- ============================================================
local function sec_history(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local c = ru32(gs + 1436)
    if not (c and c > 0 and c < GAME.layout.lim.PTR_HUGE) then return end
    local d = rp(gs + 1424)
    if not kptr(d) then return end
    local seq = SL.seqc()
    for i = 0, c - 1 do
        local el = rp(d + 8 * i)
        if kptr(el) then
            local kp = seq("sunk_ship") .. "."
            local dim = "history"
            -- name/killer_name: 非二进制档恒写 (空串也写 "")
            local nm = SL.sso(el + 8)
            if nm then emit(dim, kp .. "name", '"' .. nm .. '"') end
            local kn = SL.sso(el + 40)
            if kn then emit(dim, kp .. "killer_name", '"' .. kn .. '"') end
            local t = O:tag(ru32(el + 72) or 0)
            if t then emit(dim, kp .. "country", Q(t)) end
            -- killer_country: tag 查表失败 → writer 字面量 "---" 恒写
            -- (对拍 sunk_ship 实证; country/owner 无此形)
            t = O:tag(ru32(el + 76) or 0)
            emit(dim, kp .. "killer_country", Q(t or "---"))
            emit(dim, kp .. "level", tostring(ru32(el + 120) or 0))
            local def = rp(el + 104) -- definition: token idx@def+8 裸名
            if kptr(def) then
                emit(dim, kp .. "definition", SL.tok(ru32(def + 8) or 0))
            end
            def = rp(el + 112) -- killer_definition (无杀手 = none def)
            if kptr(def) then
                emit(dim, kp .. "killer_definition",
                    SL.tok(ru32(def + 8) or 0))
            end
            local loc = rp(el + 144) -- location: *(prov obj)+164
            if kptr(loc) then
                emit(dim, kp .. "location", tostring(ru32(loc + 164) or 0))
            end
            local ds = date3(ru32(el + 88)) -- CGameDate vt@+96, hours@+88
            if ds then emit(dim, kp .. "date", Q(ds)) end
            -- 13552 (byte@+161 仅真写, 本存档无) — 未识别键, 不发射
            local v = idpair_at(el, 124) -- equipment_variant (条件)
            if v then emit(dim, kp .. "equipment_variant", v) end
            v = idpair_at(el, 132) -- air_wing (条件)
            if v then emit(dim, kp .. "air_wing", v) end
            -- battle: 恒写 (id=0 type=0 也写)
            emit(dim, kp .. "battle",
                SL.idpair(ru32(el + 156) or 0, ru32(el + 152) or 0))
            emit(dim, kp .. "convoy", SL.yn(ru8(el + 160) or 0))
        end
    end
end

-- ============================================================
-- §4.1.5 全局顶层块 flags (global CFlagStore *(gs+600) = §1.2 +600;
-- 条目布局 = 书 §4.1.5 + CScriptFlag §4.13.3 — 与 country.flags
-- 同构同规则, 见 sv2_sec_c_flags.lua)
-- ============================================================
local function sec_flags(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local store = rp(gs + 600)
    if not kptr(store) then return end
    local d, cnt = rp(store + 8), ru32(store + 0x14)
    if not (kptr(d) and cnt and cnt > 0 and cnt < GAME.layout.lim.PTR_HUGE) then return end
    for i = 0, cnt - 1 do
        local e = d + 0x30 * i
        local key = ru32(e + 8)
        local nm = key and key <= (hoi4.read_u32(hoi4.base() + GAME.layout.rva.lexer_token_max) or 100000) and SL.tok(key)
        if nm and nm ~= "" then
            local kp = nm .. "."
            local pack = ru32(e + 0x28) or 0
            local v = pack & 0xFFFF
            v = GAME.layout.as_i16(v)
            emit("flags", kp .. "value", tostring(v))
            local dh = ru32(e + 0x18)
            if dh and dh > 0 then
                local ds = SL.date(dh)
                if ds then emit("flags", kp .. "date", '"' .. ds .. '"') end
            end
            local ex = (pack >> 16) & 0x7FFF
            if ex > 0 then emit("flags", kp .. "days", tostring(ex)) end
        end
    end
end

-- ============================================================
-- §4.16.14 sunk_convoys_history (挂 §1.2 +1448 sunk_convoy;
-- 布局/写门 = 书 §4.16.14)
-- ============================================================
local function sec_sunk_convoys(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local c = ru32(gs + 1460)
    if not (c and c > 0 and c < 4096) then return end
    local d = rp(gs + 1448)
    if not kptr(d) then return end
    local seq = SL.seqc()
    for i = 0, c - 1 do
        local el = rp(d + 8 * i)
        if kptr(el) then
            local kp = seq("sunk_convoy") .. "."
            local dim = "sunk_convoys_history"
            emit(dim, kp .. "month", tostring(ru32(el + 8) or 0))
            emit(dim, kp .. "convoys", tostring(ru32(el + 12) or 0))
            local t = O:tag(ru32(el + 16) or 0)
            -- killer_country 查表失败 = "---" (对拍 sunk_convoy 实证)
            emit(dim, kp .. "killer_country", Q(t or "---"))
            t = O:tag(ru32(el + 20) or 0)
            if t then emit(dim, kp .. "owner", Q(t)) end
        end
    end
end

-- ============================================================
-- §4.1.16 ships_built (挂 §1.2 +2520 std::map; 布局/写门/0 值也写 = 书 §4.1.16)
-- ============================================================
local function sec_ships_built(ctx)
    local emit, gs = ctx.emit, ctx.gs
    if (rp(gs + 2528) or 0) == 0 then return end
    local head = rp(gs + 2520)
    for _, node in ipairs(rb_inorder(head)) do
        local nm = SL.tok(ru32(node + 28) or 0)
        if nm then
            emit("ships_built", nm, tostring(ru32(node + 32) or 0))
        end
    end
end

-- ============================================================
-- §1.2 +928 tech_sharing_group (挂 §1.2 +928 CTechnologySharingGroup*;
-- 布局/写门 = 书 §1.2 + §4.5.4; dim 第二起 [N])
-- ============================================================
local function sec_tech_sharing(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local c = ru32(gs + 940)
    if not (c and c > 0 and c < GAME.layout.lim.PTR_SANE) then return end
    local d = rp(gs + 928)
    if not kptr(d) then return end
    for i = 0, c - 1 do
        local el = rp(d + 8 * i)
        if kptr(el) then
            local dim = i == 0 and "tech_sharing_group"
                or ("tech_sharing_group[" .. (i + 1) .. "]")
            local def = rp(el + 72)
            if kptr(def) then
                emit(dim, "id", SL.tok(ru32(def + 8) or 0))
            end
            emit_tsg_tail(function(p, v) emit(dim, p, v) end, "", el, O)
        end
    end
end

-- ============================================================
-- §4.12.6 CSavedEventTarget saved_event_target (挂 §1.2 +1728;
-- 布局/写门 = 书 §4.12.6; dim 第二起 [N])
-- ============================================================
local function sec_saved_event_target(ctx)
    local emit, O, gs, BASE = ctx.emit, ctx.O, ctx.gs, ctx.BASE
    local c = ru32(gs + 1740)
    if not (c and c > 0 and c < 4096) then return end
    local d = rp(gs + 1728)
    if not kptr(d) then return end
    for i = 0, c - 1 do
        local el = d + 112 * i
        local dim = i == 0 and "saved_event_target"
            or ("saved_event_target[" .. (i + 1) .. "]")
        local sv = ru32(el + 8) -- state: !=0 才写
        if sv and sv ~= 0 then emit(dim, "state", tostring(sv)) end
        local ci = ru32(el + 12) -- country: >0 才写
        if ci and ci > 0 then
            local t = O:tag(ci)
            if t then emit(dim, "country", Q(t)) end
        end
        local v = idpair_at(el, 16) -- character
        if v then emit(dim, "character", v) end
        local sro = rp(el + 32) -- strategic_region: *(obj)+88, 非空才写
        if kptr(sro) then
            emit(dim, "strategic_region", tostring(ru32(sro + 88) or 0))
        end
        v = idpair_at(el, 48) -- ace
        if v then emit(dim, "ace", v) end
        v = idpair_at(el, 24) -- operation
        if v then emit(dim, "operation", v) end
        v = idpair_at(el, 56) -- unit
        if v then emit(dim, "unit", v) end
        v = idpair_at(el, 64) -- industrial_organisation
        if v then emit(dim, "industrial_organisation", v) end
        v = idpair_at(el, 72) -- purchase_contract
        if v then emit(dim, "purchase_contract", v) end
        v = idpair_at(el, 80) -- raid_instance
        if v then emit(dim, "raid_instance", v) end
        v = idpair_at(el, 88) -- project
        if v then emit(dim, "project", v) end
        v = idpair_at(el, 96) -- faction
        if v then emit(dim, "faction", v) end
        -- name: u16 索引@+104 → set_name (回收; §4.26.3 SET 名串表:
        -- *(BASE+0x33245A0) 条目 32B MSVC)
        local nidx = hoi4.read_u16(el + 104) or 0
        if nidx ~= 0 then
            -- 串表散写回收 : set_name 带实时 set_count 界
            local nm = GAME.layout.set_name(nidx)
            if nm then emit(dim, "name", Q(nm)) end
        end
    end
end

-- §4.28.5 id_counter_store (对象 @gs+1952 = §1.2 +1952 CIdCounterStore
-- {vt@0, 表@+8=gs+0x7A8};
-- 条目 0x10 {vt@0, type@8, id@12} 同 vt 终止 — top_meta 定案;
-- 写序 = 表序; 值形 "type=T id=N")
local function sec_id_counter(ctx)
    local emit = ctx.emit
    local ok, r = pcall(function() return ctx.O:top_meta() end)
    if not (ok and r and r.id_counter) then return end
    for i, e in ipairs(r.id_counter) do
        emit("id_counter_store", "id_counter.#" .. i,
            string.format("type=%d id=%d", e.type or 0, e.id or 0))
    end
end

-- ============================================================
-- §4.28.1 CHuman player_countries (布局/写门 = 书 §4.28.1)
-- ============================================================
local function sec_player_countries(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local d, c = rp(gs + 168), ru32(gs + 180)
    if not (kptr(d) and c and c > 0 and c < GAME.layout.lim.PTR_SANE) then return end
    for i = 0, c - 1 do
        local el = d + 160 * i
        local t = O:tag(ru32(el + 112) or 0)
        if t then
            -- 根级 cosmetic_tag (save 头 cosmetic_tag=玩家国
            -- cosmetic, 空不写 — GER 无此行实证; cc+5256 与国家侧
            -- cosmetic_tag 叶同源)
            local carr2 = rp(gs + 0x310)
            local cc2 = carr2 and rp(carr2 + 8 * (ru32(el + 112) or -1))
            local cos = cc2 and SL.sso(cc2 + 5256) or nil
            if cos and cos ~= "" then
                emit("#", "cosmetic_tag", Q(cos))
            end
            local kp = t .. "."
            local u = SL.sso(el + 32)
            if u then emit("player_countries", kp .. "user", Q(u)) end
            emit("player_countries", kp .. "country_leader",
                SL.yn((ru8(el + 148) or 0) & 1))
            local id = ru32(el + 152)
            if id and id ~= 0xFFFFFFFF then
                emit("player_countries", kp .. "id", tostring(id))
            end
            -- pinned_strategic_regions (cnt@el+20, 本存档无) — 不发射
        end
    end
end

-- ============================================================
-- §4.28.2 gameplaysettings (挂 §1.2 +1576; 布局 = 书 §4.28.2;
-- gs+1584 与 top_meta difficulty 同址互证)
-- ============================================================
local function sec_gameplaysettings(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local DIFF = { [0] = "very_easy", "easy", "normal", "hard", "very_hard" }
    local dv = ru32(gs + 1584) or 2
    emit("gameplaysettings", "difficulty", Q(DIFF[dv] or ("diff_" .. dv)))
    emit("gameplaysettings", "ironman", tostring(ru32(gs + 1588) or 0))
    emit("gameplaysettings", "historical", tostring(ru32(gs + 1592) or 0))
end

-- ============================================================
-- §4.28.3 mods (布局/播放集末两段匹配/写序 = 书 §4.28.3; 访问器 =
-- hoi4_layout.mods_registry / mods_playset_tails)
-- ============================================================
local function sec_mods(ctx)
    local emit = ctx.emit
    -- 收敛到 hoi4_layout: mods_registry (RB 中序 {name,path}) +
    -- mods_playset_tails (播放集末两段匹配集); rva 见 M.rva.mods
    local LAY = GAME.layout
    local tails = LAY.mods_playset_tails()
    local k = 0
    for _, entry in ipairs(LAY.mods_registry()) do
        local npath = entry.path
        if npath and tails[npath] then
            local nm = entry.name
            if nm and nm ~= "" then
                k = k + 1
                emit("mods", "#" .. k, Q(nm))
            end
        end
    end
end

-- ============================================================
-- §4.28.4 索引计数器 (布局/与 entity·id_counter_store 同构 = 书 §4.28.4)
-- ============================================================
local function sec_indexes(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local T = {
        { 1872, "railway_gun_index" },
        { 1888, "industry_organisation_index" },
        { 1904, "special_project_index" },
        { 1920, "program" },
        { 1936, "program_supply_consumer" },
    }
    for _, e in ipairs(T) do
        emit(e[2], "id", tostring(ru32(gs + e[1] + 8) or 0))
    end
end

-- ============================================================
-- §4.12.7 fired_event_names (挂 §1.2 +1340; key 名串/token 双形态、
-- 单行 "id=X" 尾贴 "}" 写形 = 书 §4.12.7)
-- ============================================================
local function sec_fired_event_names(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local nb = ru32(gs + 1340)
    local buckets = rp(gs + 1344)
    if not (nb and nb > 0 and nb < 1048576 and kptr(buckets)) then return end
    local parts = {}
    for b = 0, nb - 1 do
        local node = rp(buckets + 8 * b)
        local guard = 0
        while kptr(node) and guard < 100000 do
            guard = guard + 1
            local key = rp(node)
            if kptr(key) then
                local nm
                local sz = rp(key + 48)
                if sz and sz ~= 0 then
                    if sz <= 4096 then
                        -- MSVC 串对象 @key+32 (size@+48, cap@+56)
                        nm = SL.sso(key + 32)
                    elseif kptr(sz) then
                        -- 裸 C 串指针 @key+48
                        nm = hoi4.read_cstr(sz)
                    end
                end
                if not nm then nm = SL.tok(ru32(key + 12) or 0) end
                if nm then parts[#parts + 1] = "id=" .. nm end
            end
            node = rp(node + 8)
        end
    end
    if #parts > 0 then
        emit("fired_event_names", "id", table.concat(parts, " ") .. "}")
    end
end

-- ============================================================
-- §4.28.6 entity (挂 §1.2 +1096; 布局 = 书 §4.28.6;
-- 嵌套 entity 子表 = §4.25.5)
-- ============================================================
local function sec_entity(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local obj = rp(gs + 1096)
    if not kptr(obj) then return end
    emit("entity", "id", tostring(ru32(obj + 8) or 0))
    -- §4.25.5 CScriptedMapEntityManager 子表 (布局/写门 = 书 §4.25.5;
    -- 唯一使用方 = create_entity effect, TFR hollywood 地标牌为现役样本)
    local d, n = rp(obj + 16), ru32(obj + 28) or 0
    if not kptr(d) or n <= 0 or n > GAME.layout.lim.PTR_SANE then return end
    for i = 0, n - 1 do
        local key = ru32(d + 16 * i) or 0
        local ep = rp(d + 16 * i + 8)
        if kptr(ep) then
            local blk = "entity." .. key .. "."
            local nm = SL.sso(ep + 16)
            if nm ~= nil then
                emit("entity", blk .. "name", '"' .. nm .. '"')
            end
            for _, fv in ipairs({ { 48, "x" }, { 56, "y" }, { 64, "z" },
                { 88, "scale" }, { 96, "rotation" },
                { 72, "min_zoom" } }) do
                emit("entity", blk .. fv[2],
                    SL.num((SL.rp_i64(ep + fv[1]) or 0) * 1e-5))
            end
            local ani = SL.sso(ep + 104)
            if ani and ani ~= "" then
                emit("entity", blk .. "animation", '"' .. ani .. '"')
            end
            local trg = rp(ep + 136)
            if kptr(trg) then
                local vn = SL.sso(trg + 96)
                if vn then
                    emit("entity", blk .. "visible", '"' .. vn .. '"')
                end
            end
        end
    end
end

-- ============================================================
-- ============================================================
-- §4.1.5 difficulty_settings (挂 §1.2 +1064; 布局/写门 = 书 §4.1.5;
-- 键 difficulty 重复编号 [2]..)
-- ============================================================
local function sec_difficulty_settings(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local dd, dc = rp(gs + 1064), ru32(gs + 1076)
    if not (SL.kptr(dd) and dc and dc > 0 and dc < GAME.layout.lim.PTR_SANE) then return end
    local dseq = SL.seqc()
    for i = 0, dc - 1 do
        local e = rp(dd + 8 * i)
        if SL.kptr(e) then
            local mul = SL.rp_i64(e + 208)
            if mul and mul > 0 then
                local dk = dseq("difficulty")
                local def = rp(e + 8)
                local nm = SL.kptr(def) and SL.sso(def + 56)
                if nm then
                    emit("difficulty_settings", dk .. ".difficulty_setting",
                        '"' .. nm .. '"')
                end
                emit("difficulty_settings", dk .. ".multiplier",
                    SL.num(mul * 1e-5))
            end
        end
    end
end

-- ============================================================
-- §4.25.4 游戏规则定义族 game_rules (挂 §1.2 +1088 CGameRulesInstance;
-- 布局/写序 = 书 §4.25.4; 垃圾槽靠 token_name 上界过滤)
-- ============================================================
local function sec_game_rules(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local gr = rp(gs + 1088)
    if not SL.kptr(gr) then return end
    local vd, vc = rp(gr + 8), ru32(gr + 16)
    if not (SL.kptr(vd) and vc and vc > 0 and vc < GAME.layout.lim.PTR_SANE) then return end
    for p = 0, 2 * vc - 1 do
        local k = ru32(vd + 8 * p) or 0
        local v = ru32(vd + 8 * p + 4) or 0
        local kn = k > 0 and GAME.layout.token_name(k) or nil
        local vn = v > 0 and GAME.layout.token_name(v) or nil
        if kn and vn then emit("game_rules", kn, '"' .. vn .. '"') end
    end
end

-- ============================================================
-- §4.1.5 to_be_deleted (挂 §1.2 +1224; 元素布局/键序/条目类型 61 =
-- 书 §4.1.5; 同槽 gs+2608 tutorial_chapter 门恒关无标本, 暂不发)
-- ============================================================
local function sec_to_be_deleted(ctx)
    local emit, gs = ctx.emit, ctx.gs
    local dd, dc = rp(gs + 1224), ru32(gs + 1236)
    if not (SL.kptr(dd) and dc and dc > 0 and dc < GAME.layout.lim.PTR_SANE) then return end
    for i = 0, dc - 1 do
        local p = dd + 8 * i
        emit("to_be_deleted", "#" .. (i + 1),
            string.format("id=%d type=%d", ru32(p + 4) or 0, ru32(p) or 0))
    end
end

local function ev_name(np)
    if not SL.kptr(np) then return nil end
    local sz = rp(np + 48)
    if sz and sz ~= 0 then
        if sz <= 4096 then return SL.sso(np + 32) end
        if SL.kptr(sz) then return hoi4.read_cstr(sz) end
    end
    return SL.tok(ru32(np + 12) or 0)
end

local function emit_scope(W, O, pfx, sc, depth)
    if not SL.kptr(sc) or depth > 8 then return end
    local IDP = {
        { 80, "character" }, { 104, "ace" }, { 88, "operation" },
        { 112, "unit" }, { 120, "industrial_organisation" },
        { 128, "purchase_contract" }, { 136, "raid_instance" },
        { 144, "project" }, { 152, "faction" },
    }
    local tid = ru32(sc + 8)
    if tid and tid > 0 then
        local t = O:tag(tid)
        if t then W(pfx .. "country", '"' .. t .. '"') end
    end
    local stv = ru32(sc + 168)
    if stv and stv ~= 0 then W(pfx .. "state", tostring(stv)) end
    for _, iv in ipairs(IDP) do
        local v = idpair_at(sc, iv[1])
        if v then W(pfx .. iv[2], v) end
    end
    local sr = rp(sc + 72)
    if SL.kptr(sr) then
        W(pfx .. "strategic_region", tostring(ru32(sr + 88) or 0))
    end
    W(pfx .. "random", string.format("%d %d",
        ru32(sc + 16) or 0, ru32(sc + 12) or 0))
    -- saved_event_target (§4.12.6; 布局/写门 = 书 §4.12.6; 每层 scope
    -- 都写, 非仅自指层 — pending_events .from.from 六叶实证)
    do
        local cp = rp(sc + 160)
        if SL.kptr(cp) then
            local td, tc = rp(cp), ru32(cp + 12)
            if SL.kptr(td) and tc and tc > 0
                and tc < GAME.layout.lim.PTR_SANE then
                for ti = 0, tc - 1 do
                    local te = td + 112 * ti
                    local kp = pfx .. "saved_event_target"
                    if ti > 0 then kp = kp .. "[" .. (ti + 1) .. "]" end
                    local st = ru32(te + 8)
                    if st and st ~= 0 then W(kp .. ".state", tostring(st)) end
                    local ct = ru32(te + 12)
                    if ct and ct > 0 and ct < 0x80000000 then
                        local cts = O:tag(ct)
                        if cts then W(kp .. ".country", '"' .. cts .. '"') end
                    end
                    local c4, i4 = ru32(te + 16), ru32(te + 20)
                    if (c4 and c4 ~= 0) or (i4 and i4 ~= 0) then
                        W(kp .. ".character", string.format("id=%d type=%d",
                            i4 or 0, c4 or 0))
                    end
                    local ni = ru32(te + 104)
                    if ni then ni = ni % 65536 end
                    if ni and ni ~= 0 then
                        local nm3 = GAME.layout.set_name(ni)
                        if nm3 then W(kp .. ".name", '"' .. nm3 .. '"') end
                    end
                end
            end
        end
    end
    if depth < 8 then
        local REC = { { 24, "root" }, { 32, "from" }, { 40, "prev" } }
        for _, rv in ipairs(REC) do
            local nx = rp(sc + rv[1])
            if nx and nx ~= sc then
                emit_scope(W, O, pfx .. rv[2] .. ".", nx, depth + 1)
            end
        end
    end
end

-- §4.1.1 pending_events (vec {d@gs+1376, c@gs+1388} = §1.2 +1376,
-- 56B 内联元素; scope 链逐层递归, 见 emit_scope)
local function sec_pending_events(ctx)
    local emit, O, gs = ctx.emit, ctx.O, ctx.gs
    local pd, pc = rp(gs + 1376), ru32(gs + 1388)
    if not (SL.kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_SANE) then return end
    local eseq = SL.seqc()
    for i = 0, pc - 1 do
        local e = pd + 56 * i
        local ek = eseq("event") .. "."
        local nm = ev_name(rp(e + 8))
        if nm then emit("pending_events", ek .. "id", nm) end
        emit_scope(function(p, v) emit("pending_events", p, v) end,
            O, ek .. "scope.", rp(e + 16), 0)
        local ds = date3(ru32(e + 40)) -- CGameDate vt@+48, hours@+40
        if ds then emit("pending_events", ek .. "timeout", '"' .. ds .. '"') end
        emit("pending_events", ek .. "pending_id",
            tostring(ru32(e) or 0))
    end
end

SV2.gsec[#SV2.gsec + 1] = { name = "global_tails", emit = function(ctx)
    local gs = ctx.gs
    if not gs then return end
    -- nil 值保护 (引擎 f:write 遇 nil 会抛错)
    local raw_emit = ctx.emit
    local function emit(dim, path, val)
        if val ~= nil then raw_emit(dim, path, tostring(val)) end
    end
    local ctx2 = { emit = emit, O = ctx.O, gs = gs, n = ctx.n,
        BASE = ctx.BASE }
    -- 每块独立 pcall: 单块失败不拖垮全段
    local BLOCKS = {
        function() -- variables: 全局 CVariables *(gs+2432) (§4.25.1;
            -- §1.2 +2432)
            local vo = rp(gs + 2432)
            if kptr(vo) then
                emit_cvariables(emit, "variables", "", vo)
            end
        end,
        function() sec_factions(ctx2) end,
        function() sec_faction_system(ctx2) end,
        function() sec_region(ctx2) end,
        function() sec_threat(ctx2) end,
        function() sec_power_balance(ctx2) end,
        function() sec_history(ctx2) end,
        function() sec_flags(ctx2) end,
        function() sec_sunk_convoys(ctx2) end,
        function() sec_ships_built(ctx2) end,
        function() sec_tech_sharing(ctx2) end,
        function() sec_saved_event_target(ctx2) end,
        function() sec_id_counter(ctx2) end,
        function() sec_player_countries(ctx2) end,
        function() sec_gameplaysettings(ctx2) end,
        function() sec_mods(ctx2) end,
        function() sec_indexes(ctx2) end,
        function() sec_fired_event_names(ctx2) end,
        function() sec_pending_events(ctx2) end,
        function() sec_difficulty_settings(ctx2) end,
        function() sec_game_rules(ctx2) end,
        function() sec_to_be_deleted(ctx2) end,
        function() sec_entity(ctx2) end,
    }
    for _, blk in ipairs(BLOCKS) do pcall(blk) end
end }
