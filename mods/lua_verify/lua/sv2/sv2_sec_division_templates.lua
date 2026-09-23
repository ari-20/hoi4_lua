-- sv2_sec_division_templates.lua -- division_templates 节点 savefull 直出
-- §4.18.4 CDivisionTemplate 字段族 / §4.18.6 CReferencedDivisionTemplate
-- 全局容器 (gs+1776, §1.2 管理器总表)

SV2.gsec[#SV2.gsec + 1] = { name = "division_templates", emit = function(ctx)
    local O, emit = ctx.O, ctx.emit
    local LAY = GAME.layout
    local r = O:division_templates()
    if not (r and r.list) then return end
    local list = r.list
    table.sort(list, function(a, b) return (a.id or 0) < (b.id or 0) end)
    local function Q(s)
        if s and s ~= "" and s ~= "nil" then return '"' .. s .. '"' end
        return nil
    end
    local function yn(v) return (v == 1) and "yes" or "no" end
    local seq = 0
    for _, dt in ipairs(list) do
        seq = seq + 1
        local n = dt.id or 0
        local key = seq == 1 and "division_template"
            or ("division_template[" .. seq .. "]")
        local function E(path, val)
            emit("division_templates", key .. "." .. path, val)
        end
        E("id", string.format("id=%d type=%d", n, dt.type or 0))
        local s = Q(dt.name) if s then E("name", s) end
        if dt.obsolete == 1 then E("obsolete", "yes") end
        s = Q(dt.obsolete_change_date)
        if s then E("obsolete_change_date", s) end
        if dt.is_locked == 1 then E("is_locked", "yes") end
        if dt.force_allow_recruiting == 1 then
            E("force_allow_recruiting", "yes")
        end
        if dt.division_cap then
            E("division_cap", tostring(dt.division_cap))
        end
        s = Q(dt.country) if s then E("country", s) end
        s = Q(dt.original_tag) if s then E("original_tag", s) end
        s = Q(dt.foreign_template_tag) if s then E("foreign_template_tag", s) end
        s = Q(dt.override_model) if s then E("override_model", s) end
        -- §4.18.4 CDivisionTemplate priority (writer 按有符号 i32 写,
        -- 0xFFFFFFFF → -1 TUN 师 636 实证; reader ru32 原样 → 段内转符号)
        local pr = dt.priority or 0
        pr = GAME.layout.as_i32(pr)
        E("priority", tostring(pr))
        E("allow_new_equipment", yn(dt.allow_new_equipment))
        E("allow_foreign_equipment", yn(dt.allow_foreign_equipment))
        for _, c in ipairs(dt.regiments or {}) do
            E("regiments." .. tostring(c.unit),
                string.format("x=%d y=%d", c.x, c.y))
        end
        for _, c in ipairs(dt.supports or {}) do
            E("support." .. tostring(c.unit),
                string.format("x=%d y=%d", c.x, c.y))
        end
        for _, c in ipairs(dt.regimental_supports or {}) do
            E("regimental_support." .. tostring(c.unit),
                string.format("x=%d y=%d", c.x, c.y))
        end
        E("template_counter", tostring(dt.template_counter or 0))
        E("ingame_set_template_counter", yn(dt.ingame_set_template_counter))
        if dt.origin_type then E("origin_type", tostring(dt.origin_type)) end
        s = Q(dt.localization_key) if s then E("localization_key", s) end
        s = Q(dt.division_names_group)
        if s then E("division_names_group", s) end
        local rt = dt.role_token
        if rt then
            E("role", '"' .. tostring(LAY and LAY.token_name(rt) or rt) .. '"')
        end
        if dt.is_army_hq == 1 then E("is_army_hq", "yes") end
    end
end }
