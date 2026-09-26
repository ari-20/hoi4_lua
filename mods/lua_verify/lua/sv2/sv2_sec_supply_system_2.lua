-- sv2_sec_supply_system_2.lua -- supply_system_2 节点 savefull 直出 (主写)
-- (发射规则段; 布局/走查/写门唯一实现 = Runtime.supply2 代理
--  objects_global §32.2 §4.21 CSupplySystem / CCountrySupplySystem)

SV2.gsec[#SV2.gsec + 1] = { name = "supply_system_2", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    -- §4.21 CSupplySystem (gs+984); 国家条目 = CCountrySupplySystem
    local r2 = O:supply2()
    if not (r2 and r2.list) then return end
    for _, sp in ipairs(r2.list) do
        local tg = sp.tag
        if tg and tg ~= "" and sp.alive then
            local p = "countries." .. tg .. "."
            local function E(path, val)
                emit("supply_system_2", p .. path, val)
            end
            -- priority 默认门 ≠1 才写
            if (sp.priority or 1) ~= 1 then
                E("priority", tostring(sp.priority))
            end
            -- trucks
            for ti, tr in ipairs(sp.trucks or {}) do
                local tp = "truck.#" .. ti .. "."
                E(tp .. "id", SL.idpair(tr.id, tr.type))
                E(tp .. "count", tostring(tr.count or 0))
                if (tr.damage or 0) ~= 0 then
                    E(tp .. "damage", SL.num(tr.damage))
                end
            end
            E("buffer", SL.num(sp.buffer or 0))
            E("wanted_supply_trucks", tostring(sp.wanted_supply_trucks or 0))
            E("last_supply_capital_move",
                tostring(sp.last_supply_capital_move or 0))
            -- capital (u32@+376, 门 ≠0)
            local sacap = sp.capital
            if sacap and sacap ~= 0 then
                E("capital", tostring(sacap))
            end
            -- settings.node[N]
            local seq = SL.seqc()
            for _, st in ipairs(sp.settings or {}) do
                local np = "settings." .. seq("node") .. "."
                E(np .. "id", tostring(st.id))
                E(np .. "data.disabled", st.disabled or "no")
                for mtag, lv in pairs(st.moto or {}) do
                    E(np .. "data.motorization_level." .. mtag,
                        tostring(lv))
                end
            end
            -- foreign_homebase_nodes (字段序 = writer 序, @.@ 折叠;
            -- 1.19.3 新叶 add_penalty 恒写可为 0)
            for _, nd in ipairs(sp.foreign_homebase_nodes or {}) do
                local fp = "foreign_homebase_nodes.@.@."
                E(fp .. "supply", SL.num(nd.supply))
                E(fp .. "start", SL.num(nd.start))
                E(fp .. "penalty", SL.num(nd.penalty))
                E(fp .. "add_penalty", SL.num(nd.add_penalty))
                E(fp .. "add", '"' .. (nd.add or "") .. '"')
                E(fp .. "duration", SL.num(nd.duration))
                E(fp .. "province", tostring(nd.province or 0))
                E(fp .. "hours", SL.num(nd.hours))
                E(fp .. "base", SL.yn(nd.base))
                E(fp .. "decay", SL.num(nd.decay))
            end
            -- disrupted_supply — 写序 = node id 升序 (CHI 1047→4190→9956
            -- 实证, 非 u64 键全序) + [N] 编号 (第 2 起)
            local rows = sp.disrupted_supply
            if rows then
                table.sort(rows, function(x, y)
                    if x.id_hi ~= y.id_hi then return x.id_hi < y.id_hi end
                    return x.id_lo < y.id_lo
                end)
                local nseq = 0
                for _, r in ipairs(rows) do
                    nseq = nseq + 1
                    local np = "disrupted_supply.node"
                        .. (nseq > 1 and ("[" .. nseq .. "]") or "")
                    E(np .. ".id", r.id_hi .. " " .. r.id_lo)
                    E(np .. ".value", SL.num(r.value))
                end
            end
            -- 末段标量 + 四环形容器
            E("daily_losses_index", tostring(sp.daily_losses_index or 0))
            E("last_lost_train_province",
                tostring(sp.last_lost_train_province or 0))
            for _, lk in ipairs({ "lost_railways", "lost_trains",
                                  "lost_trucks_attrition",
                                  "lost_trucks_killed" }) do
                local arr = sp[lk]
                if arr and #arr > 0 then
                    local vs = {}
                    for _, raw in ipairs(arr) do
                        local v = raw or 0
                        v = GAME.layout.as_i64(v)
                        vs[#vs + 1] = SL.num(v / 1e5)
                    end
                    E(lk .. ".#1", table.concat(vs, " "))
                end
            end
        end
    end
end }
