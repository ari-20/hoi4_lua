-- sv2_sec_c_tokens.lua -- country.tokens 节点 savefull 直出
-- (发射规则段; 布局/走查/写门唯一实现 = Country.intel_sources /
--  Country.operation_assets, objects_global §33.5/§33.5b §4.11.5/§4.11.17)

SV2.csec[#SV2.csec + 1] = { name = "country.tokens", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    -- §4.11.5 intel_source 挂载族 (tokens 挂载 = *(cc+5552)+16)
    local ok, r = pcall(function() return c:intel_sources() end)
    local s = ok and r and r.tokens or nil
    if not s or not s.country then return end
    emit(tag, "tokens.intel_source.country", '"' .. s.country .. '"')
    emit(tag, "tokens.intel_source.pool", tostring(s.pool or 0))
    emit(tag, "tokens.intel_source.id", tostring(s.id or 0))
    emit(tag, "tokens.intel_source.discriminant", tostring(s.discriminant or 0))

    -- ===== operation_assets (§4.11.17; RH 扫描序 = reader assets 序;
    -- 发射 = TAG 键 + 名字串字典序空格连接) =====
    local oka, oa = pcall(function() return c:operation_assets() end)
    for _, a in ipairs(oka and oa and oa.assets or {}) do
        -- writer 语义 = 名字串字典序 (Lua 默认 `<`),
        -- 同名异 id 不影响输出文本
        local parts = {}
        for _, nm in ipairs(a.names) do parts[#parts + 1] = nm end
        table.sort(parts)
        emit(tag, "tokens.operation_assets." .. a.tag,
            table.concat(parts, " "))
    end
end }
