-- sv2_sec_session_meta.lua -- # 顶格元数据 + all_playthrough_data 节点
-- (§4.2 会话元数据簇)

SV2.gsec[#SV2.gsec + 1] = { name = "session_meta", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8 = SL.rp, SL.ru32, SL.ru8
    local rp_i64 = SL.rp_i64
    local gs = ctx.gs

    -- ============================================================
    -- Part 1: # 顶格叶 (dim = "#"; §4.2.1 顶格 # 叶 writer 族)
    -- ============================================================
    -- §4.2 会话元数据簇 top_meta 计数器访问
    local tm = O:top_meta()
    if tm then
        local c = tm.counters or {}
        -- 计数器槽统一引自 hoi4_layout.rva.counters (top_meta 与本节同源,
        -- 收敛前两份拷贝)。本节**覆写** top_meta 结果: 共享层的 top_meta
        -- 可能落后于 1.19.3 的 .data 位移, 此处以权威表重读一次。
        do
            local B = ctx.BASE
            if B then
                local RC = GAME.layout.rva.counters
                for nm, rva in pairs(RC) do
                    local v = hoi4.read_u32(B + rva) or 0
                    -- 两个 random_* 为 i32 语义 (负值合法;
                    -- §4.28.13 CRandom 计数器随机流)
                    if nm == "multiplayer_random_seed"
                        or nm == "multiplayer_random_count" then
                        v = GAME.layout.as_i32(v)
                    end
                    c[nm] = v
                end
                tm.save_version =
                    hoi4.read_u32(B + GAME.layout.rva.save_version) or 0
                tm.minor_save_version =
                    hoi4.read_u32(B + GAME.layout.rva.minor_save_version) or 0
            end
        end
        local function E(path, val)
            if val ~= nil then emit("#", path, val) end
        end
        local function D(path, v) E(path, string.format("%d", v or 0)) end
        if tm.player then E("player", '"' .. tm.player .. '"') end
        if tm.ideology then E("ideology", tostring(tm.ideology)) end
        if tm.date then E("date", '"' .. tm.date .. '"') end
        if tm.difficulty then E("difficulty", '"' .. tm.difficulty .. '"') end
        -- version 豁免 (写盘时生成)
        E("tutorial", tm.tutorial or "no")
        D("save_version", tm.save_version)
        D("minor_save_version", tm.minor_save_version)
        -- dlcs 豁免 (写盘时生成)
        D("session", c.session)
        D("next_trade_route_update_country_idx",
          c.next_trade_route_update_country_idx)
        D("cached_active_trade_route_count",
          c.cached_active_trade_route_count)
        D("speed", c.speed)
        D("game_unique_seed", c.game_unique_seed)
        if tm.game_unique_id then
            E("game_unique_id", '"' .. tm.game_unique_id .. '"')
        end
        D("multiplayer_random_seed", c.multiplayer_random_seed)
        D("multiplayer_random_count", c.multiplayer_random_count)
        D("debug_current_ref_id", c.debug_current_ref_id)
        D("unit", c.unit)
        D("order_index", c.order_index)
        D("front_index", c.front_index)
        D("theatre_index", c.theatre_index)
        D("theater_group_index", c.theater_group_index)
        D("military_deployment_line_index",
          c.military_deployment_line_index)
        D("military_deployment_conveyor_index",
          c.military_deployment_conveyor_index)
        D("equipment_variant_index", c.equipment_variant_index)
        D("country_leader_index", c.country_leader_index)
        D("navy_id", c.navy_id)
        D("land_combat_id", c.land_combat_id)
        if tm.start_date then
            E("start_date", '"' .. tm.start_date .. '"')
        end
        -- id 叶 (§4.2.2; 三源合并/门/写序 = 书) — reader idreg_maxima
        -- 已上提 (§4.26.5), 段内只做 type 升序排序 + #N 恒编号
        do
            local merged = GAME.layout.idreg_maxima() or {}
            local list = {}
            for ty, idv in pairs(merged) do
                list[#list + 1] = { ty = ty, id = idv }
            end
            table.sort(list, function(a, b2) return a.ty < b2.ty end)
            local seq = SL.seqc()
            for _, e in ipairs(list) do
                E(seq("id"), SL.idpair(e.id, e.ty))
            end
        end
        if tm.average_major_ic then
            E("average_major_ic", SL.num(tm.average_major_ic))
        end
        if tm.tension_scaling_base_country then
            E("tension_scaling_base_country",
              '"' .. tm.tension_scaling_base_country .. '"')
        end
        E("statistics_collection_enabled",
          tm.statistics_collection_enabled or "no")
        -- checksum 豁免 (写盘时生成)
    end

    -- ============================================================
    -- Part 2: all_playthrough_data (dim = "all_playthrough_data";
    -- §4.2.3 all_playthrough_data 宿主 gs+2200)
    -- ============================================================
    local DIM = "all_playthrough_data"
    if not (gs and gs > 0x10000) then return end
    if (ru32(gs + 2216) or 0) == 0 then return end  -- writer gate (RH map 计数门@宿主+16, §4.2.2 RH map 头)

    -- i64 格式化: 整值 %d; 超 2^53 精确 double 用 %.0f (bitset 高位见头注)
    -- C 绑定 lua_pushinteger = 精确 64 位整数, math.type 先判
    -- integer 走 %d — 旧代码大整数落入 %.0f 转 double 丢精度 (差 8/9/11)
    local function i64s(v)
        if not v then return "0" end
        if math.type(v) == "integer" then
            return string.format("%d", v)
        end
        if v == math.floor(v) and math.abs(v) < 2 ^ 53 then
            return string.format("%d", math.floor(v))
        end
        return string.format("%.0f", v)
    end

    -- §4.2.7 SCareerProfileCountryData 164 键 blob 字段表
    -- (writer sub_14069C280 硬编码序, 逐位对拍定案)
    -- {名, 偏移, 类型}; u32 = ru32(S+off), i64 = rp_i64(S+off)
    local BLOB = {
        { "playthroughs", 8, "u32" },
        { "most_factories_built", 12, "u32" },
        { "successful_coups", 16, "u32" },
        { "liberated_nations", 20, "u32" },
        { "sunk_pride_of_the_fleet", 24, "u32" },
        { "shot_aces", 28, "u32" },
        { "successful_operations", 32, "u32" },
        { "recruited_operatives", 36, "u32" },
        { "captured_operatives", 40, "u32" },
        { "designed_ships", 44, "u32" },
        { "sunk_convoys", 48, "u32" },
        { "hosted_governments", 52, "u32" },
        { "admiral_traits_unlocked", 56, "u32" },
        { "puppeted_countries", 60, "u32" },
        { "licensed_foreign_military_tech", 64, "u32" },
        { "fought_civil_wars", 68, "u32" },
        { "general_traits_unlocked", 72, "u32" },
        { "designed_tanks", 76, "u32" },
        { "battles_against_encircled", 80, "u32" },
        { "battles_with_air_support", 84, "u32" },
        { "provinces_gained", 88, "u32" },
        { "provinces_lost", 92, "u32" },
        { "defensive_victories", 96, "u32" },
        { "forts_with_max_defense_defeated", 100, "u32" },
        { "destroyed_encircled_divisions", 104, "u32" },
        { "designed_planes", 108, "u32" },
        { "mussolini_missions", 112, "u32" },
        { "field_officers_promoted", 116, "u32" },
        { "ships_sunk_by_maritime", 120, "u32" },
        { "decrypted_ciphers", 124, "u32" },
        { "civilian_factories_built_1936", 128, "u32" },
        { "civilian_factories_built_1940", 132, "u32" },
        { "civilian_factories_built_1945", 136, "u32" },
        { "military_factories_built_1936", 140, "u32" },
        { "military_factories_built_1940", 144, "u32" },
        { "military_factories_built_1945", 148, "u32" },
        { "dockyards_built_1936", 152, "u32" },
        { "dockyards_built_1940", 156, "u32" },
        { "dockyards_built_1945", 160, "u32" },
        { "rocket_sites_built_1936", 164, "u32" },
        { "rocket_sites_built_1940", 168, "u32" },
        { "rocket_sites_built_1945", 172, "u32" },
        { "embargoed_countries", 176, "u32" },
        { "special_force_doctrines", 180, "u32" },
        { "sp_finished_before_1946", 184, "u32" },
        { "sp_completed", 188, "u32" },
        { "nuclear_raid_before_1944", 192, "u32" },
        { "nuclear_raid_before_1945", 196, "u32" },
        { "nuclear_raid_before_1946", 200, "u32" },
        { "launched_raids", 204, "u32" },
        { "sp_techs_finished", 208, "u32" },
        { "plan_landlocked_naval_projects_finished", 212, "u32" },
        { "scientist_level_ups", 216, "u32" },
        { "faction_goals_completed", 220, "u32" },
        { "naval_headquarters_built", 224, "u32" },
        { "subdoctrines_mastered", 228, "u32" },
        { "faction_long_term_goals_completed", 232, "u32" },
        { "controlled_strategic_locations", 236, "u32" },
        { "special_forces_subdoctrines_mastered", 240, "u32" },
        { "captured_commanders", 244, "u32" },
        { "rescued_commanders", 248, "u32" },
        { "ship_captains_promoted", 252, "u32" },
        { "built_tanks", 256, "u32" },
        { "built_ships", 260, "u32" },
        { "vehicles_received_by_lease", 264, "u32" },
        { "vehicles_sent_by_lease", 268, "u32" },
        { "planes_sent_as_volunteer_force", 272, "u32" },
        { "built_railway_guns", 276, "u32" },
        { "converted_vehicles", 280, "u32" },
        { "captured_equipment", 284, "u32" },
        { "deployed_cavalry_battalions", 288, "u32" },
        { "mio_size_ups", 292, "u32" },
        { "special_forces_deployed", 296, "u32" },
        { "equipment_sold", 300, "u32" },
        { "economic_capacity_exchanged", 304, "u32" },
        { "mobile_warfare_xp", 308, "u32" },
        { "superior_firepower_xp", 312, "u32" },
        { "grand_battleplan_xp", 316, "u32" },
        { "mass_assault_xp", 320, "u32" },
        { "fleet_in_being_xp", 324, "u32" },
        { "trade_interdiction_xp", 328, "u32" },
        { "base_strike_xp", 332, "u32" },
        { "strategic_destruction_xp", 336, "u32" },
        { "battlefield_support_xp", 340, "u32" },
        { "operational_integrity_xp", 344, "u32" },
        { "mastery_gained", 348, "u32" },
        { "captured_generals_levels_counter", 352, "u32" },
        { "longest_battle_duration", 356, "u32" },
        { "largest_manpower_battle", 360, "u32" },
        { "largest_tanks_battle", 364, "u32" },
        { "largest_army", 368, "u32" },
        { "largest_navy", 372, "u32" },
        { "largest_airforce", 376, "u32" },
        { "highest_casualty_war", 380, "u32" },
        { "highest_enemy_casualty_war", 384, "u32" },
        { "paratrooper_divisions", 388, "u32" },
        { "naval_invasions", 392, "u32" },
        { "aircrafts_in_region", 396, "u32" },
        { "aces_in_airbase", 400, "u32" },
        { "defensive_bonus_achieved", 404, "u32" },
        { "planning_bonus_achieved", 408, "u32" },
        { "encircled_divisions", 412, "u32" },
        { "battle_affecting_modifiers", 416, "u32" },
        { "totally_controlled_naval_regions", 420, "u32" },
        { "veteran_units", 424, "u32" },
        { "max_air_supply_to_region", 428, "u32" },
        { "railway_gun_supported_combats", 432, "u32" },
        { "level_up_skills", 436, "u32" },
        { "mined_sea_regions", 440, "u32" },
        { "province_gaining_weeks", 444, "u32" },
        { "decrypting_days_saved", 448, "u32" },
        { "deployed_airplanes_with_air_defense_bronze", 452, "u32" },
        { "deployed_airplanes_with_air_defense_silver", 456, "u32" },
        { "deployed_airplanes_with_air_defense_gold", 460, "u32" },
        { "deployed_high_speed_tanks", 464, "u32" },
        { "deployed_tanks_with_armor_rating_bronze", 468, "u32" },
        { "deployed_tanks_with_armor_rating_silver", 472, "u32" },
        { "deployed_tanks_with_armor_rating_gold", 476, "u32" },
        { "sp_scientist_level_3", 480, "u32" },
        { "sp_scientist_level_4", 484, "u32" },
        { "sp_scientist_level_5", 488, "u32" },
        { "plan_landlocked_light_hulls", 492, "u32" },
        { "plan_landlocked_cruiser", 496, "u32" },
        { "plan_landlocked_battleship", 500, "u32" },
        { "plan_landlocked_carrier", 504, "u32" },
        { "your_officers_leading_faction_theaters", 508, "u32" },
        { "faction_manifesto_fulfillment", 512, "u32" },
        { "ship_captain_skill_level", 516, "u32" },
        { "deployed_division_hq_ic_cost", 520, "u32" },
        { "game_months", 524, "u32" },
        { "seconds_played", 528, "u32" },
        { "offensive_battles", 532, "u32" },
        { "defensive_battles", 536, "u32" },
        { "total_battles", 540, "u32" },
        { "hours_at_war", 544, "u32" },
        { "highest_casualty_civil_war", 548, "u32" },
        { "highest_enemy_casualty_civil_war", 552, "u32" },
        { "own_unknown_casualties", 556, "u32" },
        { "total_own_casualties", 568, "i64" },
        { "own_casualties", 576, "i64" },
        { "enemy_casualties", 584, "i64" },
        { "military_production_equipment", 592, "i64" },
        { "military_production_vehicles", 600, "i64" },
        { "military_production_air", 608, "i64" },
        { "air_production_fighter", 616, "i64" },
        { "air_production_interceptor", 624, "i64" },
        { "air_production_tactical_bomber", 632, "i64" },
        { "air_production_strategic_bomber", 640, "i64" },
        { "air_production_cas", 648, "i64" },
        { "air_production_naval_bomber", 656, "i64" },
        { "air_production_suicide", 664, "i64" },
        { "air_production_scout_plane", 672, "i64" },
        { "air_production_maritime_patrol_plane", 680, "i64" },
        { "tank_production_light", 688, "i64" },
        { "tank_production_medium", 696, "i64" },
        { "tank_production_heavy", 704, "i64" },
        { "tank_production_super_heavy", 712, "i64" },
        { "tank_production_modern", 720, "i64" },
        { "naval_production_submarine", 728, "i64" },
        { "naval_production_screen", 736, "i64" },
        { "naval_production_capital_ship", 744, "i64" },
        { "naval_production_carrier", 752, "i64" },
        { "bombed_trains", 560, "u32" },
        { "conquered_percentage", 564, "u32" },
    }

    -- blob 单叶: "<k=v ...> produced_combat_widths={" (S = 结构体基址)
    local function blob_str(S)
        local parts = {}
        for _, f in ipairs(BLOB) do
            local v
            if f[3] == "i64" then
                v = i64s(rp_i64(S + f[2]))
            else
                v = string.format("%d", ru32(S + f[2]) or 0)
            end
            parts[#parts + 1] = f[1] .. "=" .. v
        end
        parts[#parts + 1] = "produced_combat_widths={"
        return table.concat(parts, " ")
    end

    -- produced_combat_widths 内 52 个 u32 (@.#1): S+776..S+984
    local function widths_str(S)
        local t = {}
        for a = S + 776, S + 980, 4 do
            t[#t + 1] = string.format("%d", ru32(a) or 0)
        end
        return table.concat(t, " ")
    end

    -- §4.2.5 CTimeSeries (interm+off): 写 count 个 *elem
    local function ts_str(base)
        local cnt = ru32(base + 28) or 0
        local data = rp(base + 16)
        if cnt <= 0 or cnt > 4096 or not SL.kptr(data) then
            return nil
        end
        local t = {}
        for k = 0, cnt - 1 do
            local p = rp(data + 8 * k)
            t[#t + 1] = string.format("%d",
                SL.kptr(p) and (ru32(p) or 0) or 0)
        end
        return table.concat(t, " ")
    end

    local RECENTS = {
        { "recent_offensive_battles", 8 },
        { "recent_defensive_battles", 48 },
        { "recent_spawned_divisions", 88 },
        { "recent_dropped_nukes", 128 },
        { "recent_provinces_gained", 168 },
        { "recent_provinces_lost", 208 },
        { "recent_shot_down_airplanes", 248 },
        { "recent_naval_invasion_divisions_transferred", 288 },
        { "last_month_convoys_sunk", 328 },
    }

    -- map 遍历 (§3.2 robin-hood; all_playthrough_data 宿主表 §4.2.3):
    -- dist u8@+4 (0=空), key u32@+8, value ptr@+16
    local buckets = rp(gs + 2208)
    local mask = ru32(gs + 2220) or 0
    local distmax = ru8(gs + 2224) or 0
    local entries = {}
    if SL.kptr(buckets) and mask > 0 and mask < 0x100000 then
        local nb = mask + distmax + 1
        for i = 0, nb - 1 do
            local b = buckets + 24 * i
            local dist = ru8(b + 4) or 0
            -- dist=0xFE 墓碑槽也要跳 (USA 残留桶被误收 →
            -- mem 多发 #2; 全库其它 RH 走查同款双门)
            if dist ~= 0 and dist ~= 0xFE then
                local key = ru32(b + 8) or 0
                local val = rp(b + 16)
                -- writer: key>0 才写 (sub_140BA6730); value 需有效
                if key > 0 and SL.kptr(val) then
                    entries[#entries + 1] = { key = key, val = val }
                end
            end
        end
    end
    -- 写序 = key 升序 (sub_1401B6480)
    table.sort(entries, function(a, b) return a.key < b.key end)

    for K, e in ipairs(entries) do
        local w = e.val
        local tagstr = O:tag(e.key) or tostring(e.key)
        local p = "#" .. K .. ".#1."
        -- 外层 tag 叶恒发 (⚠ 曾见"末条目 tag 叶被吞"伪影, 同刻重存后
        -- 消失 — 系特定字节布局的一次性提取器 half_anon 抖动, 非稳定
        -- 契约, 勿仿真)
        emit(DIM, "#" .. K, '"' .. tagstr .. '"')
        local first, second = w + 16, w + 1024
        -- data.first / data.second (§4.2.4 wrapper SProfileData; 各 4 叶)
        for _, pair in ipairs({ { "first", first }, { "second", second } }) do
            local nm, S = pair[1], pair[2]
            emit(DIM, p .. "data." .. nm .. ".playthroughs", blob_str(S))
            emit(DIM, p .. "data." .. nm .. ".@.#1", widths_str(S))
            emit(DIM, p .. "data." .. nm .. ".average_air_superiority",
                i64s(rp_i64(S + 760)) .. " " .. i64s(rp_i64(S + 768)))
            emit(DIM, p .. "data." .. nm .. ".new_bests.#1",
                i64s(rp_i64(S + 984)) .. " " .. i64s(rp_i64(S + 992))
                .. " " .. i64s(rp_i64(S + 1000)))
        end
        -- data.tag (§3.5 MSVC SSO @w+2032, §4.2.4; writer 空串也写
        -- → 恒引号)
        local ts = SL.sso(w + 2032) or ""
        emit(DIM, p .. "data.tag", '"' .. ts .. '"')
        -- intermediate_statistics (§4.2.5; interm = w+2064)
        local interm = w + 2064
        for _, r in ipairs(RECENTS) do
            local s = ts_str(interm + r[2])
            if s then
                emit(DIM, p .. "intermediate_statistics." .. r[1] .. ".#1", s)
            end
        end
        local cpp = rp(interm + 368)
        local pgp = rp(interm + 376)
        local cp = SL.kptr(cpp) and (ru32(cpp) or 0) or 0
        local pg = SL.kptr(pgp) and (ru32(pgp) or 0) or 0
        -- 提取器怪癖: 行尾带 " }"
        emit(DIM, p .. "intermediate_statistics.controlled_provinces",
            string.format(
                "controlled_provinces=%d province_gaining_weeks_intermediate=%d }",
                cp, pg))
        -- flags : wrapper 内嵌 CFlagManager @w+2448 (§4.2.6; 条目布局 =
        -- §4.13.3) — 行序 = 插入序, 逐条 value→date→days(days 门 >0)
        do
            local fm = w + 2448
            local frows = rp(fm + 8)
            local fcnt = ru32(fm + 20) or 0
            if SL.kptr(frows) and fcnt > 0 and fcnt < GAME.layout.lim.PTR_SANE then
                for fi = 0, fcnt - 1 do
                    local row = frows + 48 * fi
                    local ftn = GAME.layout.token_name(ru32(row + 8) or 0)
                    if ftn and ftn ~= "" and not tostring(ftn):match("^%d") then
                        local fb = p .. "flags." .. tostring(ftn) .. "."
                        local v16 = hoi4.read_u16(row + 40) or 0
                        v16 = GAME.layout.as_i16(v16)
                        emit(DIM, fb .. "value", SL.num(v16))
                        local fd = SL.date(ru32(row + 24))
                        if fd then emit(DIM, fb .. "date", SL.Q(fd)) end
                        local d16 = hoi4.read_u16(row + 42) or 0
                        d16 = GAME.layout.as_i16(d16)
                        if d16 > 0 then
                            emit(DIM, fb .. "days", SL.num(d16)) end
                    end
                end
            end
        end
        -- first_tag (u8@w+2480, §4.2.4; 恒写)
        emit(DIM, p .. "first_tag", SL.yn(ru8(w + 2480)))
    end

    -- ============================================================
    -- Part 3: mod_achievement (dim = "mod_achievement";
    -- §4.28.8 NCareerProfile 生涯档案簇邻域 — 单例 BASE+0x3330460,
    -- 门 = rp(sing+8)≠0)
    -- ============================================================
    do
        local BASE = ctx.BASE
        local sing = BASE and rp(BASE + 0x3330460) or nil
        if SL.kptr(sing) and (rp(sing + 8) or 0) ~= 0 then
            local head = rp(sing)
            if SL.kptr(head) then
                -- RB 中序后继 (§3.3 std::map; MSVC
                -- {_Left@0,_Parent@8,_Right@16,isnil@+25})
                local function succ(n)
                    local r = rp(n + 16)
                    if SL.kptr(r) and ru8(r + 25) == 0 then
                        local j = rp(r)
                        while SL.kptr(j) and ru8(j + 25) == 0 do
                            r = j
                            j = rp(j)
                        end
                        return r
                    end
                    local p = rp(n + 8)
                    while SL.kptr(p) and ru8(p + 25) == 0
                          and n == rp(p + 16) do
                        n = p
                        p = rp(p + 8)
                    end
                    return p
                end
                local names = {}
                local node = rp(head)          -- leftmost
                local guard = 0
                while SL.kptr(node) and ru8(node + 25) == 0
                      and guard < 4096 do
                    guard = guard + 1
                    local vb = rp(node + 64)
                    local vc = ru32(node + 76) or 0
                    if SL.kptr(vb) and vc > 0 and vc < GAME.layout.lim.PTR_HUGE then
                        for i = 0, vc - 1 do
                            local e = rp(vb + 8 * i)
                            if SL.kptr(e) and (ru8(e + 33) or 0) ~= 0 then
                                local nm = SL.sso(e + 40)
                                if nm then names[#names + 1] = nm end
                            end
                        end
                    end
                    node = succ(node)
                end
                if #names > 0 then
                    for k, nm in ipairs(names) do
                        emit("mod_achievement", "#" .. k, '"' .. nm .. '"')
                    end
                end
            end
        end
    end
end }
