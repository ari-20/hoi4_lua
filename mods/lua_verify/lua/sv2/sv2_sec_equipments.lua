-- sv2_sec_equipments.lua -- equipments 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "equipments", emit = function(ctx)
    local O, emit = ctx.O, ctx.emit
    local SL = SV2.lib
    local LAY = GAME.layout
    -- §4.23.1 CEquipmentVariant (gs+1800 容器)
    local r2 = O:equipments()
    if not (r2 and r2.list) then return end
    local list = r2.list
    table.sort(list, function(a, b)
        return (a.id or 0) < (b.id or 0)
    end)
    local seen = {}
    for _, ev in ipairs(list) do
        local arch = tostring(ev.archetype)
        local cnt = (seen[arch] or 0) + 1
        seen[arch] = cnt
        local key = cnt == 1 and arch or (arch .. "[" .. cnt .. "]")
        local function E(path, val)
            emit("equipments", key .. "." .. path, val)
        end
        local function Q(s) -- 非空串 -> 引号形, 否则 nil (不写)
            if s and s ~= "" and s ~= "nil" then
                return '"' .. s .. '"'
            end
            return nil
        end
        E("id", string.format("id=%d type=%d", ev.id or -1, ev.type or 0))
        local ver = ev.version or 0
        if ver > 0 then
            E("version", tostring(ver))
        else
            E("max_version", tostring(ev.max_version or 0))
        end
        if ev.obsolete == 1 then E("obsolete", "yes") end
        E("is_frame", ev.is_frame == 1 and "yes" or "no")
        local s = Q(ev.creator) if s then E("creator", s) end
        s = Q(ev.origin) if s then E("origin", s) end
        if ev.can_upgrade_type == 1 then E("can_upgrade_type", "yes") end
        if ev.can_upgrade_variant == 1 then E("can_upgrade_variant", "yes") end
        if ev.can_upgrade_modules == 1 then E("can_upgrade_modules", "yes") end
        if ev.highlight == 1 then E("highlight", "yes") end
        -- show_position ==0 才写 no (writer 0x140BD4770 定案; EqMT)
        if (ev.show_position or 1) == 0 then E("show_position", "no") end
        if (ev.manpower or 0) > 0 then E("manpower", tostring(ev.manpower)) end
        if (ev.role_icon_index or 0) > 0 then
            E("role_icon_index", tostring(ev.role_icon_index))
        end
        s = Q(ev.name) if s then E("name", s) end
        s = Q(ev.position) if s then E("position", s) end
        local pid = ev.parent_id
        if pid then
            E("parent_id", string.format("id=%d type=%d",
                pid.id or -1, pid.type or 0))
        end
        s = Q(ev.division_names_group) if s then E("division_names_group", s) end
        s = Q(ev.override_sprite) if s then E("override_sprite", s) end
        s = Q(ev.override_model) if s then E("override_model", s) end
        local dt = ev.design_team
        if dt then
            E("design_team", string.format("id=%d type=%d",
                dt.id or -1, dt.type or 0))
        end
        if dt then -- bonus 受 design_team 门控 (无 dt 的残留数组 writer 不写)
            -- 段内纠偏上提 reader (count@+0x4A4 定案入
            -- objects_v2 equip_variant MT) — 直用 reader 结果,
            -- 值格式 %g → SL.num (fixed5 writer 格式, %.5f 去尾零)
            for _, b in ipairs(ev.design_team_bonus or {}) do
                E("design_team_bonus." .. tostring(b.name), SL.num(b.value))
            end
        end
        local ndt = ev.number_of_design_team_traits
        if ndt then E("number_of_design_team_traits", tostring(ndt)) end
        local neb = ev.named_equipment_bonuses
        if neb and #neb > 0 then
            local vs = {}
            for _, x in ipairs(neb) do vs[#vs + 1] = tostring(x) end
            E("named_equipment_bonuses.#1", table.concat(vs, " "))
        end
        local idl = ev.ideas
        if idl then
            if #idl == 0 then
                E("ideas", "{}") -- 容器在但空: writer 写空块
            else
                -- R: writer (0x140BD4770 ideas 块) 逐元素线性查重,
                -- 同 idea token 只写首现一次; mem 容器可含重复
                -- → 段内同序去重
                local names, seen = {}, {}
                for _, tok in ipairs(idl) do
                    local nm = tostring(LAY and LAY.token_name(tok) or tok)
                    if not seen[nm] then
                        seen[nm] = true
                        names[#names + 1] = nm
                    end
                end
                E("ideas", table.concat(names, " ")) -- 多条空格单行
            end
        end
        for _, mo in ipairs(ev.modules or {}) do
            if mo.module then
                E("modules." .. tostring(mo.slot), tostring(mo.module))
            end
        end
        for i, up in ipairs(ev.upgrade_list or {}) do
            E("upgrades.upgrades.#" .. i,
                tostring(up.name) .. " " .. tostring(up.level or 0))
        end
    end
end }
