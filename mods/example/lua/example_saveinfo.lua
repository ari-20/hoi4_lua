-- example_saveinfo.lua -- example mod 存档摘要发射段 (sv2_sec_* 同型
-- 只调访问层把内存落成文字, 不自持布局知识; 顶层只定义, 零执行)
-- 依赖: 本 mod 拷贝的访问层三件套 (hoi4_layout.lua + resource.lua +
-- objects_v2.lua, 同名整文件同步自 mods/lua_verify/lua/ —— 同名 = 可
-- 整文件覆盖同步; 两 mod 不保证同时启用, 故 example 自带一份)。
-- 运行时经 GAME.objects (Runtime/Country 方法表) 取数, 加载序在访问层
-- 之前无碍 (摘要只在 effect 调用时执行)。
-- 无现成方法的字段, 偏移/格式引现成段知识
-- sv2_sec_c_country_scalars stability i64×1e-5 率@cc+4304 /
-- war_support@cc+4312 (率值 1.0=100%, 存档文本 stability=0.95 同形态;
-- ×100 转百分数 —— popularity 族才是值即百分数, 勿混)
-- sv2_sec_c_manpower 人力 = manpower.ratio u32@cc+824 (原始
-- 人数; current@cc+820 绝大多数国为 0)
-- sv2_sec_c_politics party.popularity fixed5 值即百分数;
-- ideas 平铺列表混装法案与精神
-- sv2_sec_c_focus 已点国策数/当前国策名 (Country.focus)
-- sv2_sec_c_production 工厂池 val@+8 (民用 888/军用 696/造船 792,
-- fixed×1e5 qword); 闲置民工 = 888/1e5 −
-- 912/1e5 − 944 − 920 (书 §4.8.12);
-- 产线 line_type 59 = 建筑, 其余 = 军工
-- (active_factories@元素+24)
-- sv2_sec_c_technology 已研科技 = ts+76 列表数; 动态槽数 = cc+4936
-- objects_v2 state_buildings 州建筑池 st+288 (vt 0x2999050), 元素
-- token@e+8 / level e+0x40 低 16 位;
-- 州 owner cidx@st+200 (build_body 同源)
-- 陆军明细 (army_details) 师人力双容器 @a+984/a+1016 (mp_list 同源);
-- 装备完好率 = 请求块 produced/need
-- (q=*(a+1144), 三门 +68/+172/+196);
-- 编制 = 模板表 {d@cc+440,c@cc+452} +
-- R:division_templates 名册 (sv2_sec_c_units /
-- sv2_sec_division_templates 同源)
-- 海军/空军 舰船 Σ舰队→特混→船 (cc+632/644, fl+184/196,
-- tf+840/852); R:air_wings 翼 count@+0x6C
-- Country.stockpile 库存 by_archetype (cc+0xF68 原型聚合)
-- Country.autonomy 自治状态/进度 (wtt 保护国族可见)
-- gs+1128 当前日期 (总小时, 例建 reseed 同源)
local rp, ru32 = hoi4.read_u64, hoi4.read_u32

-- CGameDate 总小时 → "Y.M.D" (纯函数; A 族门 + 年<1 弃, 再去掉尾部小时位)
-- 唯一实现 = hoi4_layout.date(h, 1); 此处只裁 "Y.M.D.H" → "Y.M.D"
-- (惰性取 GAME.layout: 层文件字母序晚于本文件加载)
local function date(h)
    local s = GAME.layout and GAME.layout.date(h, 1)
    return s and s:match("^(%d+%.%d+%.%d+)")
end
-- i64 ×1e-5 定点 → 浮点: 委托唯一实现 (GAME.layout.fix5; 惰性取因层文件
-- 字母序晚于本文件加载)。散写副本已收敛 — 旧副本含空操作补符号
-- (`v - 0x10000000000000000` 回绕为减 0), 且违反唯一实现原则 (书 §3.7)。
local function fix5(a)
    local L = GAME.layout
    if not L then return nil end
    return L.fix5(a)
end
local function pct(v)                     -- fixed5 百分数 → 整数
    return v and math.floor(v + 0.5) or nil
end

-- 法案/意识形态术语表 (其余标识符保持 HOI4 原名, 模型自识)
local GLOSS = {
    democratic = "民主", communism = "共产", fascism = "法西斯", neutrality = "中立",
    civilian_economy = "民用经济", partial_economic_mobilisation = "战备经济",
    war_economy = "战时经济", tot_economic_mobilisation = "总动员经济",
    free_trade = "自由贸易", export_focus = "出口专注", limited_exports = "限量出口",
    closed_economy = "封闭经济",
    volunteer_only = "志愿兵役", limited_conscription = "有限征兵",
    extensive_conscription = "广泛征兵", service_by_requirement = "按需服役",
    all_adults_serve = "全员服役", scraping_the_barrel = "刮桶兵役",
}
local GLOSS_EQ = {                        -- 装备原型术语表 (stockpile 用)
    infantry_equipment = "步枪", artillery_equipment = "火炮",
    support_equipment = "支援装备", anti_tank_equipment = "反坦克炮",
    anti_air_equipment = "防空炮", motorized_equipment = "摩托化装备",
    mechanized_equipment = "机械化装备", light_tank_chassis = "轻型坦克",
    medium_tank_chassis = "中型坦克", heavy_tank_chassis = "重型坦克",
    light_airframe = "轻型机架", medium_airframe = "中型机架",
    large_airframe = "大型机架", naval_bomber_airframe = "海轰机架",
    jet_airframe = "喷气机架", convoy_1 = "运输船",
}
local function term_eq(name)
    local g = GLOSS_EQ[name]
    return g and (name .. "(" .. g .. ")") or name
end
local GLOSS_BN = {                       -- 营兵种术语表 (编制用)
    infantry = "步", cavalry = "骑", artillery = "炮", anti_tank = "反坦克",
    anti_air = "防空", motorized = "摩托化", mechanized = "机械化",
    light_armor = "轻坦克", medium_armor = "中坦克", heavy_armor = "重坦克",
    paratrooper = "伞兵", marine = "海陆", mountaineers = "山地",
}
local function term_bn(name)
    return GLOSS_BN[name] or name
end
local LAWS = {
    civilian_economy = true, partial_economic_mobilisation = true,
    war_economy = true, tot_economic_mobilisation = true,
    free_trade = true, export_focus = true, limited_exports = true,
    closed_economy = true,
    volunteer_only = true, limited_conscription = true,
    extensive_conscription = true, service_by_requirement = true,
    all_adults_serve = true, scraping_the_barrel = true,
}
local function term(name)
    if not name then return nil end
    local g = GLOSS[name]
    return g and (name .. "(" .. g .. ")") or name
end

-- 在建产线数 (ps+112 general_lines, 元素+8 = line_type, 59 = 建筑;
-- example_autopilot build_body 同源)
local function count_building_lines(ps)
    local gd = rp(ps + 112)
    local gc = ru32(ps + 124) or 0
    if not gd or gd < 0x10000 or gc == 0 or gc > 10000 then return 0 end
    local nb = 0
    for i = 0, gc - 1 do
        local e = rp(gd + 8 * i)
        if e and e ~= 0 and ru32(e + 8) == 59 then nb = nb + 1 end
    end
    return nb
end
-- 闲置民工 (书 §4.8.12 未使用公式)
local function civ_idle(ps)
    local total = math.floor((rp(ps + 888) or 0) / 100000)
    local proj = math.floor((rp(ps + 912) or 0) / 100000)
    local cg = ru32(ps + 944) or 0
    local asg = ru32(ps + 920) or 0
    local idle = total - proj - cg - asg
    return (idle > 0) and idle or 0
end
-- 军工产线条数 + 活跃厂 (line_type ~= 59; active_factories@元素+24)
local function mil_lines(ps)
    local gd = rp(ps + 112)
    local gc = ru32(ps + 124) or 0
    if not gd or gd < 0x10000 or gc == 0 or gc > 10000 then return 0, 0 end
    local nl, nf = 0, 0
    for i = 0, gc - 1 do
        local e = rp(gd + 8 * i)
        if e and e ~= 0 and ru32(e + 8) ~= 59 then
            nl = nl + 1
            nf = nf + (ru32(e + 24) or 0)
        end
    end
    return nl, nf
end

-- 世界工厂聚合 (一次扫全州, 一次性能耗 ~百 ms 级, 仅手动锐评时调用);
-- 建筑 token 预解析成 id 后逐元素比对, 不做逐州 token_name
local WORLD_BS_VT = 0x2999050             -- 州建筑池 vtable (state_buildings 同源)
local function world_factories(R, LAYOUT)
    local t_civ = LAYOUT.name_to_token and LAYOUT.name_to_token("industrial_complex")
    local t_mil = LAYOUT.name_to_token and LAYOUT.name_to_token("arms_factory")
    local t_dk = LAYOUT.name_to_token and LAYOUT.name_to_token("dockyard")
    if not (t_civ and t_mil and t_dk) then return nil end
    local g = R:gs()
    local sarr = g and rp(g + 0x2C8)
    local scnt = g and ru32(g + 0x2D4) or 0
    local carr = g and rp(g + 0x310)
    if not sarr or scnt <= 0 or scnt > 100000 or not carr then return nil end
    local bvt = hoi4.base() + WORLD_BS_VT
    local acc = {}                            -- cidx -> {civ, mil, dock}
    for i = 0, scnt - 1 do
        local st = rp(sarr + 8 * i)
        local ow = st and st >= 0x10000 and ru32(st + 200) or 0
        if ow and ow > 0 and st and st >= 0x10000 then
            local bs = rp(st + 288)
            if bs and bs >= 0x10000 and rp(bs) == bvt then
                local d, c = rp(bs + 56), ru32(bs + 68)
                if d and d >= 0x10000 and c > 0 and c < 512 then
                    local rec = acc[ow]
                    for j = 0, c - 1 do
                        local e = rp(d + 8 * j)
                        if e and e >= 0x10000 then
                            local tk = ru32(e + 8)
                            local lv = (ru32(e + 0x40) or 0) % 65536
                            if tk == t_civ then
                                rec = rec or { 0, 0, 0 }; acc[ow] = rec
                                rec[1] = rec[1] + lv
                            elseif tk == t_mil then
                                rec = rec or { 0, 0, 0 }; acc[ow] = rec
                                rec[2] = rec[2] + lv
                            elseif tk == t_dk then
                                rec = rec or { 0, 0, 0 }; acc[ow] = rec
                                rec[3] = rec[3] + lv
                            end
                        end
                    end
                end
            end
        end
    end
    local list = {}
    for cidx, v in pairs(acc) do
        local cc = rp(carr + 8 * cidx)
        local tid = cc and cc >= 0x10000 and ru32(cc + 8) or nil
        local tg = tid and R:tag(tid)
        if tg then list[#list + 1] = { tag = tg, civ = v[1], mil = v[2], dk = v[3],
            total = v[1] + v[2] + v[3] } end
    end
    table.sort(list, function(a, b) return a.total > b.total end)
    return list
end

-- 陆军明细: 满员率/装备完好率/编制 (一次遍历师列表)
-- 师人力双容器 @a+984/a+1016: {d@+8, c@+20} 8B 元素 {tag u32, value u32}
-- (objects_v2 mp_list 同源)
-- 装备完好率 = Σ已交付/Σ需求: 请求块 q=*(a+1144), 三门 q+68/q+172/q+196
-- (全零 = 满编不进分母); 请求元素 {d@q+56, c@q+68} 指针, 元 B=e+0x18
-- produced 对象@B+32 容器头 {d@P+32, c@P+44} / need 对象@B+96 容器头
-- {d@N+8, c@N+20} (书 §4.18.3; produced 对象多 24B 头, 两头勿复用),
-- 各元素 16B {指针, amount i64} (sv2_sec_c_units 产池同布局)
-- 编制: 模板对象表 {d@cc+440, c@cc+452}, id 对 = u64@tpl+8 (id=高32位);
-- 名册 = R:division_templates 的 {id, name, regiments={{unit,...}}}
local function army_details(R, idx, cc)
    local ok, dl = pcall(R.divisions, R, idx)
    if not ok then dl = nil end
    local ok2, dtl = pcall(R.division_templates, R)
    local byid = {}
    if ok2 and dtl and dtl.list then
        for _, t in ipairs(dtl.list) do byid[t.id] = t end
    end
    local mv, mn, eqp, eqn = 0, 0, 0, 0
    local tcount = {}
                local function pool_sum(base, dh, ch)  -- 容器 {d@base+dh, c@base+ch}, 元素 16B 取 amount
                    local pd = rp(base + dh)
                    local pc = ru32(base + ch) or 0
                    local s = 0
                    if pd and pd >= 0x10000 and pc > 0 and pc < 64 then
                        for j = 0, pc - 1 do
                            s = s + (rp(pd + 16 * j + 8) or 0)
                        end
                    end
                    return s
                end
    if dl and dl.list then
        for _, dv in ipairs(dl.list) do
            local a = dv.addr
            if a and a >= 0x10000 then
                local okid, tid = pcall(function() return dv.template_id end)
                if okid and tid then tcount[tid] = (tcount[tid] or 0) + 1 end
                local function man_sum(off)  -- {d@+8, c@+20} 8B 元素取 value
                    local md = rp(a + off + 8)
                    local mc = ru32(a + off + 20) or 0
                    local s = 0
                    if md and md >= 0x10000 and mc > 0 and mc < 64 then
                        for j = 0, mc - 1 do
                            s = s + (ru32(md + 8 * j + 4) or 0)
                        end
                    end
                    return s
                end
                mv = mv + man_sum(984)
                mn = mn + man_sum(1016)
                local q = rp(a + 1144)
                if q and q >= 0x10000 then
                    local g68 = (ru32(q + 68) or 0) ~= 0
                    local g172 = (ru32(q + 172) or 0) ~= 0
                    local g196 = (ru32(q + 196) or 0) ~= 0
                    if g68 or g172 or g196 then
                        local rd = rp(q + 56)
                        local rc = ru32(q + 68) or 0
                        if rd and rd >= 0x10000 and rc > 0 and rc < 64 then
                            for j = 0, rc - 1 do
                                local e = rp(rd + 8 * j)
                                if e and e >= 0x10000 then
                                    local B = e + 0x18
                                    eqn = eqn + pool_sum(B + 96, 8, 20)    -- need: 容器头 N+8/N+20
                                    eqp = eqp + pool_sum(B + 32, 32, 44)   -- produced: 容器头 P+32/P+44
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- 编制行 (按模板: 名(营构成)×师数)
    local comp = {}
    local td = rp(cc + 440)
    local tc = ru32(cc + 452) or 0
    if td and td >= 0x10000 and tc > 0 and tc < 512 then
        for i = 0, tc - 1 do
            local tpl = rp(td + 8 * i)
            if tpl and tpl >= 0x10000 then
                local pair = rp(tpl + 8)
                if pair then
                    local id = math.floor(pair / 4294967296)
                    local t = byid[id]
                    if t and t.name then
                        local agg = {}
                        for _, rg in ipairs(t.regiments or {}) do
                            agg[rg.unit] = (agg[rg.unit] or 0) + 1
                        end
                        local segs = {}
                        for bn, n in pairs(agg) do
                            segs[#segs + 1] = term_bn(bn) .. n
                        end
                        table.sort(segs)
                        local line = t.name .. "(" .. table.concat(segs, "+") .. ")"
                        local n = tcount[id]
                        if n and n > 1 then line = line .. "×" .. n end
                        comp[#comp + 1] = line
                    end
                end
            end
        end
    end
    return {
        men = (mn > 0) and math.floor(mv / mn * 100 + 0.5) or nil,
        eq = (eqn > 0) and math.floor(eqp / eqn * 100 + 0.5) or 100,
        comp = (#comp > 0) and table.concat(comp, "、") or nil,
    }
end

-- 海军: 舰船总数 = Σ 舰队→特混舰队→船
-- (舰队容器 rp(cc+632)/count cc+644; 特混舰队 {d@fl+184, c@fl+196};
-- 船 {d@tf+840, c@tf+852} — sv2_sec_c_strategic_navy 同源)
local function navy_ships(cc)
    local fd = rp(cc + 632)
    local fc = ru32(cc + 644) or 0
    if not fd or fd < 0x10000 or fc <= 0 or fc > 512 then return 0 end
    local total = 0
    for i = 0, fc - 1 do
        local fl = rp(fd + 8 * i)
        if fl and fl >= 0x10000 then
            local td = rp(fl + 184)
            local tc = ru32(fl + 196) or 0
            if td and td >= 0x10000 and tc > 0 and tc < 512 then
                for j = 0, tc - 1 do
                    local tf = rp(td + 8 * j)
                    if tf and tf >= 0x10000 then
                        local sc = ru32(tf + 852) or 0
                        if sc > 0 and sc < 1000 then total = total + sc end
                    end
                end
            end
        end
    end
    return total
end

-- 空军: 联队数 + 飞机总数 (Runtime.air_wings; wing.count@+0x6C)
local function air_summary(R, idx)
    local ok, aw = pcall(R.air_wings, R, idx)
    if not ok or not aw or not aw.wings then return nil end
    local nw, planes = 0, 0
    for _, w in ipairs(aw.wings) do
        local c = w.count or 0
        if c > 0 then
            nw = nw + 1
            planes = planes + c
        end
    end
    if nw == 0 then return nil end
    return { wings = nw, planes = planes }
end

-- 库存装备 top4 (Country.stockpile.by_archetype: 原型名 → 数量)
local function stockpile_line(c)
    local oks, st = pcall(c.stockpile, c)
    if not oks or not st or not st.by_archetype then return nil end
    local arr = {}
    for nm, amt in pairs(st.by_archetype) do
        if amt > 0 then arr[#arr + 1] = { nm, amt } end
    end
    table.sort(arr, function(a, b) return a[2] > b[2] end)
    local segs = {}
    for i = 1, math.min(#arr, 4) do
        local nm, amt = arr[i][1], arr[i][2]
        local v = (amt >= 10000)
            and string.format("%.1f万", amt / 10000) or string.format("%d", amt)
        segs[#segs + 1] = term_eq(nm) .. v
    end
    if #segs == 0 then return nil end
    return "库存装备:" .. table.concat(segs, "/")
end

-- 摘要组装: "名:值"以'；'连接, 字段名自解释 (锐评模型可直接引用数字);
-- 字段序与措辞 = 离线实测 payload
local function summary(cc)
    if not cc or cc < 0x10000 then return "无国家对象" end
    local R = (type(GAME) == "table") and GAME.objects
    if not (R and R.country and R.gs) then return "访问层未就绪" end
    local LAYOUT = (type(GAME) == "table") and GAME.layout
    local g = R:gs()
    if not g then return "游戏状态未就绪" end

    -- 国家定位: tag id@cc+8 → 数组下标 (id→下标映射 *(gs+0x340), scope 同源)
    local tid = ru32(cc + 8)
    local tab = rp(g + 0x340)
    local idx = (tab and tab >= 0x10000 and tid and tid ~= 0)
        and ru32(tab + 4 * tid) or nil
    if not idx or idx <= 0 then return "国家下标未解析" end
    local c = R:country(idx)
    if not c or c.addr ~= cc then return "国家对象失配" end

    local parts = {}
    parts[#parts + 1] = "日期:" .. (date(ru32(g + 1128)) or "?")
    parts[#parts + 1] = "国家:" .. (c:tag() or ("idx" .. idx))

    -- 政治 (Country.politics: PP/执政党声望 fixed5 百分数/ideas 混装)
    local pol = c:politics()
    local laws, spirits = {}, {}
    if pol then
        if pol.ruling_party then
            local line = "执政:" .. term(pol.ruling_party)
                .. "(声望" .. (pct(pol.ruling_popularity) or "?") .. "%)"
            local best, bestp = nil, -1
            for _, p in ipairs(pol.parties or {}) do
                if p.ideology ~= pol.ruling_party and (p.popularity or 0) > bestp then
                    bestp, best = p.popularity or 0, p.ideology
                end
            end
            if best then
                line = line .. ",最大反对党" .. term(best) .. "(" .. pct(bestp) .. "%)"
            end
            parts[#parts + 1] = line
        end
        for _, nm in ipairs(pol.ideas and pol.ideas.list or {}) do
            if LAWS[nm] then laws[#laws + 1] = term(nm)
            else spirits[#spirits + 1] = nm end
        end
    end

    -- 自治 (Country.autonomy; 附庸国可见, 独立国返回 nil)
    local oka, au = pcall(c.autonomy, c)
    if oka and au and au.current_state then
        parts[#parts + 1] = "宗主体系:" .. au.current_state
            .. "(进度" .. math.floor((au.progress or 0) + 0.5) .. ")"
    end

    -- 稳定度 / 战争支持度 (sv2_sec_c_country_scalars; 率值 ×100)
    local stv = fix5(cc + 4304)
    local wsv = fix5(cc + 4312)
    local st = stv and pct(stv * 100)
    local ws = wsv and pct(wsv * 100)
    if st then parts[#parts + 1] = "稳定度:" .. st .. "%" end
    if ws then parts[#parts + 1] = "战争支持度:" .. ws .. "%" end

    local pp = pol and pol.political_power
    if pp then parts[#parts + 1] = "政治点数:" .. math.floor(pp + 0.5) end

    -- 工厂 (池 val 恒 fixed×1e5, qword 读; 不可写">100000 才除")
    local ps = rp(cc + 3944)
    if ps and ps >= 0x10000 then
        local civ = math.floor((rp(ps + 888) or 0) / 100000)
        local mil = math.floor((rp(ps + 696) or 0) / 100000)
        local dk = math.floor((rp(ps + 792) or 0) / 100000)
        parts[#parts + 1] = "工厂:民用" .. civ .. "/军用" .. mil .. "/造船厂" .. dk
            .. "(共" .. (civ + mil + dk) .. ")"
        local nl, nf = mil_lines(ps)
        parts[#parts + 1] = "军工产线:" .. nl .. "条(" .. nf .. "厂)"
        parts[#parts + 1] = "在建产线:" .. count_building_lines(ps)
    end

    -- 人力 (manpower.ratio@cc+824, 原始人数; save 无 max 字段)
    local mp = ru32(cc + 824)
    if mp then
        parts[#parts + 1] = (mp > 0)
            and string.format("人力:%.1f万", mp / 10000) or "人力:0"
    end

    -- 师 (数量+满员率+装备完好率+编制; 详 army_details 注)
    local okA, ad = pcall(army_details, R, idx, cc)
    if okA and ad then
        local line = "师:" .. (ru32(cc + 668) or 0)
        if ad.men or ad.eq then
            line = line .. "(满员率" .. (ad.men or "?") .. "%"
                .. ",装备完好率" .. (ad.eq or "?") .. "%)"
        end
        parts[#parts + 1] = line
        if ad.comp then parts[#parts + 1] = "编制:" .. ad.comp end
    else
        parts[#parts + 1] = "师:" .. (ru32(cc + 668) or 0)
    end

    -- 海军 / 空军 (舰船总数; 联队数+飞机总数)
    local ships = navy_ships(cc)
    if ships > 0 then parts[#parts + 1] = "海军:舰船" .. ships .. "艘" end
    local oka2, air = pcall(air_summary, R, idx)
    if oka2 and air then
        parts[#parts + 1] = "空军:" .. air.wings .. "个联队共" .. air.planes .. "架"
    end

    -- 库存装备 (top4 原型)
    local okS, sline = pcall(stockpile_line, c)
    if okS and sline then parts[#parts + 1] = sline end

    -- 科研 (sv2_sec_c_technology)
    local ts = rp(cc + 3936)
    if ts and ts >= 0x10000 then
        local sdata = rp(ts + 160)
        local dyn = ru32(cc + 4936) or 0
        local filled = 0
        for i = 0, dyn - 1 do
            local s = sdata and rp(sdata + 8 * i) or 0
            if s and s ~= 0 and rp(s + 24) ~= 0 then filled = filled + 1 end
        end
        parts[#parts + 1] = "已研科技:" .. (ru32(ts + 76) or 0)
        parts[#parts + 1] = "科研槽:" .. filled .. "/" .. dyn
    end

    -- 三军经验 (Country.experience, Q15)
    local oke, e = pcall(c.experience, c)
    if oke and e then
        parts[#parts + 1] = string.format("三军经验:陆军%.0f/海军%.0f/空军%.0f",
            e.army or 0, e.navy or 0, e.air or 0)
    end

    -- 燃料 (Country.fuel, Q15)
    local okf2, fu = pcall(c.fuel, c)
    if okf2 and fu and fu.max_fuel and fu.max_fuel > 0 then
        local pctf = math.floor(fu.fuel / fu.max_fuel * 100 + 0.5)
        parts[#parts + 1] = (pctf >= 99) and "燃料:满" or
            string.format("燃料:%d%%", pctf)
    end

    if #laws > 0 then parts[#parts + 1] = "法案:" .. table.concat(laws, "、") end
    if #spirits > 0 then
        local shown = {}
        for i = 1, math.min(#spirits, 12) do shown[#shown + 1] = spirits[i] end
        parts[#parts + 1] = "国家精神:" .. table.concat(shown, "、") ..
            ((#spirits > 12) and "等" or "")
    end

    -- 国策 (Country.focus: 已点数 + 当前名)
    local okf, f = pcall(c.focus, c)
    if okf and f then
        local line = "国策:已完成" .. (f.completed_count or 0) .. "个"
        if f.current then line = line .. ",当前:" .. f.current
        else line = line .. ",当前无进行中" end
        parts[#parts + 1] = line
    end

    -- 世界总厂对比 (top4 + 自己; 一次全州扫描)
    if LAYOUT then
        local okw, wf = pcall(world_factories, R, LAYOUT)
        if okw and wf and #wf > 0 then
            local seg, mine, shown = {}, nil, 0
            for _, r in ipairs(wf) do
                if r.tag == c:tag() then mine = r end
            end
            for _, r in ipairs(wf) do
                if r.tag ~= c:tag() and shown < 4 then
                    shown = shown + 1
                    seg[#seg + 1] = r.tag .. r.total
                end
            end
            if mine then seg[#seg + 1] = "你" .. mine.total end
            if #seg > 1 then parts[#parts + 1] = "世界总厂:" .. table.concat(seg, "/") end
        end
    end

    -- 盟友 (cached_allies {d@dip+880, c@dip+892}, 元素 = tag id)
    local dip = rp(cc + 3976)
    if dip and dip >= 0x10000 then
        local ad = rp(dip + 880)
        local an = ru32(dip + 892) or 0
        local al = {}
        if ad and ad >= 0x10000 and an > 0 and an < 512 then
            for i = 0, an - 1 do
                local t = R:tag(ru32(ad + 4 * i))
                if t then al[#al + 1] = t end
            end
        end
        if #al > 0 then parts[#parts + 1] = "盟友:" .. table.concat(al, ",") end
    end

    return table.concat(parts, "；")
end

EXAMPLE_SAVEINFO = { summary = summary }
return EXAMPLE_SAVEINFO
