-- sv2_sec_session_meta.lua -- # 顶格元数据 + all_playthrough_data 节点
-- (发射规则段; 布局/走查/写门唯一实现 = Runtime.top_meta / Runtime.session_meta
--  / idreg_maxima, objects_misc §30.5/§30.5b §4.1.6-§4.1.16)

SV2.gsec[#SV2.gsec + 1] = { name = "session_meta", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local gs = ctx.gs

    -- ============================================================
    -- Part 1: # 顶格叶 (dim = "#"; §4.1.6 顶格 # 叶 writer 族)
    -- ============================================================
    local ok0, sm = pcall(function() return O:session_meta() end)
    local tm = O:top_meta()
    if tm then
        local c = tm.counters or {}
        -- 计数器槽 = 权威 rva.counters 重读 (reader 覆写表; top_meta
        -- 共享层可能落后于 1.19.3 的 .data 位移)
        if sm and sm.counters then
            for nm, v in pairs(sm.counters) do c[nm] = v end
            tm.save_version = sm.save_version
            tm.minor_save_version = sm.minor_save_version
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
        -- id 叶 (§4.1.7; 三源合并/门/写序 = 书) — reader idreg_maxima
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
    -- §4.1.8 宿主 gs+2200; 走查/写门/key 升序全在 reader)
    -- ============================================================
    if not (sm and sm.apd_enabled) then return end
    local DIM = "all_playthrough_data"

    -- i64 格式化: 整值 %d; 超 2^53 精确 double 用 %.0f
    -- C 绑定 lua_pushinteger = 精确 64 位整数, math.type 先判
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
    local function field_s(f)
        if f.t == "i64" then return i64s(f.v) end
        return string.format("%d", f.v or 0)
    end
    local function profile_block(p, nm, prof)
        -- blob 单叶: "<k=v ...> produced_combat_widths={"
        local parts = {}
        for _, f in ipairs(prof.fields or {}) do
            parts[#parts + 1] = f.name .. "=" .. field_s(f)
        end
        parts[#parts + 1] = "produced_combat_widths={"
        emit(DIM, p .. "data." .. nm .. ".playthroughs",
            table.concat(parts, " "))
        local wt = {}
        for _, wv in ipairs(prof.widths or {}) do
            wt[#wt + 1] = string.format("%d", wv)
        end
        emit(DIM, p .. "data." .. nm .. ".@.#1", table.concat(wt, " "))
        emit(DIM, p .. "data." .. nm .. ".average_air_superiority",
            i64s(prof.air_a) .. " " .. i64s(prof.air_b))
        emit(DIM, p .. "data." .. nm .. ".new_bests.#1",
            i64s(prof.bests[1]) .. " " .. i64s(prof.bests[2])
            .. " " .. i64s(prof.bests[3]))
    end

    for K, e in ipairs(sm.entries or {}) do
        local p = "#" .. K .. ".#1."
        -- 外层 tag 叶恒发 (⚠ 曾见"末条目 tag 叶被吞"伪影, 同刻重存后
        -- 消失 — 系特定字节布局的一次性提取器 half_anon 抖动, 非稳定
        -- 契约, 勿仿真)
        emit(DIM, "#" .. K, '"' .. e.tag .. '"')
        profile_block(p, "first", e.first or {})
        profile_block(p, "second", e.second or {})
        emit(DIM, p .. "data.tag", '"' .. (e.data_tag or "") .. '"')
        -- intermediate_statistics (§4.1.10; 写 count 个 *elem)
        for _, r in ipairs(e.recents or {}) do
            if r.vals then
                local t = {}
                for _, v in ipairs(r.vals) do
                    t[#t + 1] = string.format("%d", v)
                end
                emit(DIM, p .. "intermediate_statistics." .. r.name
                    .. ".#1", table.concat(t, " "))
            end
        end
        -- 提取器怪癖: 行尾带 " }"
        emit(DIM, p .. "intermediate_statistics.controlled_provinces",
            string.format(
                "controlled_provinces=%d province_gaining_weeks_intermediate=%d }",
                e.controlled or 0, e.pgw or 0))
        -- flags : 行序 = 插入序, 逐条 value→date→days(days 门 >0)
        for _, fr in ipairs(e.flags or {}) do
            local fb = p .. "flags." .. tostring(fr.name) .. "."
            emit(DIM, fb .. "value", SL.num(fr.value))
            local fd = SL.date(fr.date_h)
            if fd then emit(DIM, fb .. "date", SL.Q(fd)) end
            if fr.days then
                emit(DIM, fb .. "days", SL.num(fr.days)) end
        end
        -- first_tag (u8@w+2480, §4.1.9; 恒写)
        emit(DIM, p .. "first_tag", SL.yn(e.first_tag))
    end

    -- ============================================================
    -- Part 3: mod_achievement (dim = "mod_achievement";
    -- §4.28.8 单例/RB 中序/有效位门全在 reader)
    -- ============================================================
    if sm and sm.achievements and #sm.achievements > 0 then
        for k, nm in ipairs(sm.achievements) do
            emit("mod_achievement", "#" .. k, '"' .. nm .. '"')
        end
    end
end }
