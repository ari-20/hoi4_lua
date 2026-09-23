-- sv2_sec_c_intel.lua -- country.intel 节点 savefull 直出
-- (§4.11.7 CCountryIntel cc+4072 六矩阵)

SV2.csec[#SV2.csec + 1] = { name = "country.intel", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local n = ctx.n or 0
    local QUAD = { "civilian", "army", "navy", "airforce" }
    -- "c|a|n|f" (reader %.5f 打包串) -> {4×number}; fixed5 分辨率 1e-5,
    -- %.5f→tonumber 往返无损
    local function parse_quad(qs)
        local t = {}
        for s in tostring(qs or ""):gmatch("[^|]+") do
            t[#t + 1] = tonumber(s) or 0
        end
        return t
    end
    -- 每象限 ≠0 才写 (writer if(v) 规则, 全零行/条目双侧无叶)
    local function emit_quad(prefix, qv)
        for q = 1, 4 do
            local v = qv[q] or 0
            if v ~= 0 then emit(tag, prefix .. "." .. QUAD[q], SL.num(v)) end
        end
    end

    local ok, r = pcall(function() return c:intel() end)
    if ok and r then
        -- 1) 主矩阵 §4.11.7 CCountryIntel 六矩阵: intel.intel.#N.<quad> (n 门)
        for _, row in ipairs(r.intel and r.intel.rows or {}) do
            if (row.idx or 0) < n then
                emit_quad("intel.intel.#" .. ((row.idx or 0) + 1),
                    { row.civilian, row.army, row.navy, row.airforce })
            end
        end
        -- 2) intel_from_allies.#N.<quad> (裸 quad 行, 键=行号即国家 idx+1)
        for ri, qs in ipairs(r.from_allies_rows or {}) do
            emit_quad("intel.intel_from_allies.#" .. ri, parse_quad(qs))
        end
        -- 2b) intel_from_encryption_decryption.#N.<quad> (补 — writer
        -- 0x140CF2AE0 六矩阵全发, 19492 走 CEC1C0 同 from_allies 形;
        -- 旧段漏发, 实测矩阵全空故未暴露)
        for ri, qs in ipairs(r.from_encryption_decryption_rows or {}) do
            emit_quad("intel.intel_from_encryption_decryption.#" .. ri,
                parse_quad(qs))
        end
        -- 3) static_intel_pools 两层 + 嵌套条目 (§4.11.7 +160 / dynamic +184)
        for pi, pr in ipairs(r.static_pool_rows or {}) do
            emit(tag, "intel.static_intel_pools.#" .. pi .. ".id", SL.num(pr.id))
            for si, src in ipairs(pr.sources or {}) do
                local pfx = "intel.static_intel_pools.#" .. pi .. ".intel.#" .. si
                emit(tag, pfx .. ".id", SL.num(src.id))
                emit(tag, pfx .. ".remove", SL.yn(src.remove))
                for _, en in ipairs(src.entries or {}) do
                    emit_quad(pfx .. ".intel." .. (en.idx or 0), parse_quad(en.quad))
                end
            end
        end
        -- 4) dynamic_intel_pools accumulator/values (@.@ 丢键形)
        for pi, pr in ipairs(r.dynamic_pool_rows or {}) do
            for _, kv in ipairs({ { "accumulator", pr.accum },
                                  { "values", pr.values } }) do
                for _, en in ipairs(kv[2] or {}) do
                    emit_quad("intel.dynamic_intel_pools.#" .. pi .. "."
                        .. kv[1] .. ".@.@", parse_quad(en.quad))
                end
            end
        end
        -- 5) intel_from_(static|dynamic)_pools(_prev_day) 行容器 (@.@ 丢键形)
        for _, fam in ipairs({
            { "intel.intel_from_static_pools", r.from_static_rows },
            { "intel.intel_from_dynamic_pools", r.from_dynamic_rows },
            { "intel.intel_from_dynamic_pools_prev_day", r.from_dynamic_prev_rows },
        }) do
            for pi, s in ipairs(fam[2] or {}) do
                if s ~= "" then
                    for item in s:gmatch("[^;]+") do
                        local qs = item:match("^%d+=(.*)$")
                        if qs then
                            emit_quad(fam[1] .. ".#" .. pi .. ".@.@", parse_quad(qs))
                        end
                    end
                end
            end
        end
        -- 6) cheat / discriminant 恒写行 (id@it+232, disc@it+236,
        -- discriminant@it+208; 值 0 也写)
        local ch = r.cheat or {}
        emit(tag, "intel.cheat.id", SL.num(ch.id))
        emit(tag, "intel.cheat.discriminant", SL.num(ch.discriminant))
        emit(tag, "intel.discriminant", SL.num(r.discriminant))
    end

    -- 7) intel_source 三挂载 (§4.11.5 CStaticIntelSourceReference,
    -- 元素 vt 0x295f138, 开键 idx>0 且 pool≠0
    -- 已在 reader 内门控; country 仅 idx>0 写 / pool 仅 ≠0 写 — 门后
    -- 四字段全写)
    local ok2, isx = pcall(function() return c:intel_sources() end)
    if ok2 and isx then
        -- radar/tokens 两挂载由专段 sv2_sec_c_radar/tokens 负责,
        -- 本段只发 cryptology (与他段重复发射已去重)
        for _, m in ipairs({
            { "intelligence_agency.cryptology.intel_source", isx.cryptology },
        }) do
            local v = m[2]
            if v then
                local cs = SL.Q(v.country)
                if cs then emit(tag, m[1] .. ".country", cs) end
                emit(tag, m[1] .. ".pool", SL.num(v.pool))
                emit(tag, m[1] .. ".id", SL.num(v.id))
                emit(tag, m[1] .. ".discriminant", SL.num(v.discriminant))
            end
        end
    end
end }
