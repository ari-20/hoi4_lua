-- sv2_sec_c_country_reports.lua -- country.country_reports 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Country.country_reports
--  objects_misc §27.1 §4.3.20 CCountryReportsManager cc+4064)

SV2.csec[#SV2.csec + 1] = { name = "country.country_reports", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end

    local r = c:country_reports()   -- objects_misc §27.1
    if not r then return end        -- crm 指针无效: 整国缺 (不应发生)

    -- index / days: 恒写整数
    emit(tag, "country_reports.index", string.format("%d", r.index or 0))
    emit(tag, "country_reports.days", string.format("%d", r.days or 0))

    -- date: 恒写引号形; 哨兵 43808760 照发 "1.1.1.1"
    -- (C 族 = 无哨兵剔除 + 引号输出)
    emit(tag, "country_reports.date", SL.date_quoted(r.date_hours or 0))

    -- construction: 19 键恒写 (writer 0x141C1DFE0 无条件循环; 文档序 =
    -- CR_CONSTR; 缺数据默认 0 = writer 查不到时的行为)
    local CR_CONSTR = { "civilian_factory", "military_factory", "dockyard",
        "port", "infrastructure", "air_base", "rocket_site", "gun_emplacement",
        "radar", "anti_air", "refinery", "fuel_silo", "supply_node",
        "nuclear_reactor", "land_fort", "naval_fort", "naval_headquarter",
        "naval_supply_hub", "other" }
    local cons = r.construction
    for i, nm in ipairs(CR_CONSTR) do
        emit(tag, "country_reports.construction." .. nm,
            string.format("%d", (cons and cons[i]) or 0))
    end

    -- equipment_production: 38 键恒写, 存档文档序 = writer (mask,token)
    -- 对序 (writer 0x141C1F500; 已标定 23 位全部吻合)
    local CR_EQ = {
        { "convoy", 0x1 }, { "train", 0x80000000 },
        { "floating_harbor", 0x200 }, { "railway_gun", 0x80000 },
        { "armor", 0x4 }, { "land_cruiser", 0x4000000000 },
        { "motorized", 0x8 }, { "mechanized", 0x10 },
        { "infantry", 0x20 }, { "capital_ship", 0x40 },
        { "submarine", 0x80 }, { "screen_ship", 0x100 },
        { "support_ship", 0x8000000000 }, { "fighter", 0x400 },
        { "heavy_fighter", 0x100000000 }, { "interceptor", 0x800 },
        { "tactical_bomber", 0x1000 }, { "strategic_bomber", 0x2000 },
        { "cas", 0x4000 }, { "naval_bomber", 0x8000 },
        { "missile", 0x10000 }, { "emplacement_gun_ammo", 0x200000000 },
        { "ballistic_missile", 0x400000000 }, { "nuclear_missile", 0x800000000 },
        { "sam_missile", 0x1000000000 }, { "suicide", 0x20000 },
        { "scout_plane", 0x40000 }, { "maritime_patrol_plane", 0x200000 },
        { "air_transport", 0x100000 }, { "carrier", 0x400000 },
        { "missile_launcher", 0x2000000000 }, { "support", 0x1000000 },
        { "amphibious", 0x4000000 }, { "anti_air", 0x8000000 },
        { "artillery", 0x10000000 }, { "anti_tank", 0x20000000 },
        { "rocket", 0x40000000 }, { "flame", 0x2000000 },
    }
    local vals = {}
    for _, e in ipairs(r.equipment_production or {}) do
        vals[e.mask] = e.value   -- mask < 2^40, lua number 精确; int/float 键等价
    end
    for _, kv in ipairs(CR_EQ) do
        emit(tag, "country_reports.equipment_production." .. kv[1],
            SL.num(vals[kv[2]] or 0))
    end

    -- log.#1: 记录流 (reader 已解出 8×u32 编码记录)
    if r.log and #r.log > 0 then
        local t = {}
        for _, rec in ipairs(r.log) do
            for _, x in ipairs(rec) do t[#t + 1] = tostring(x) end
        end
        emit(tag, "country_reports.log.#1", table.concat(t, " "))
    end
    -- 注: lc==0 (空 log) 形态存档无样本 (439 国全有 log.#1, 休眠国 =
    -- 单条全零记录 "0"), 暂不发射 (不确定点)。
end }
