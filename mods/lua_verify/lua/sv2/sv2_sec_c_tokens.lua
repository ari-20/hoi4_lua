-- sv2_sec_c_tokens.lua -- country.tokens 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.tokens", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    -- §4.11.5 intel_source 挂载族 (tokens 挂载 = *(cc+5552)+16)
    -- / §4.29.7 CCountryOperationTokenManager (cc+5552)
    local ok, r = pcall(function() return c:intel_sources() end)
    local s = ok and r and r.tokens or nil
    if not s or not s.country then return end
    emit(tag, "tokens.intel_source.country", '"' .. s.country .. '"')
    emit(tag, "tokens.intel_source.pool", tostring(s.pool or 0))
    emit(tag, "tokens.intel_source.id", tostring(s.id or 0))
    emit(tag, "tokens.intel_source.discriminant", tostring(s.discriminant or 0))

    -- ===== operation_assets (§4.11.6 排序发射; RH 布局/排序语义 = 书;
    -- 发射 = TAG 键 + 名字串字典序空格连接) =====
    do
        local rp, ru32 = SL.rp, SL.ru32
        local kptr = SL.kptr
        local obj = rp(c.addr + 5552)
        local data = kptr(obj) and rp(obj + 48) or nil
        local mask = kptr(obj) and ru32(obj + 60) or 0
        local extra = kptr(obj) and (SL.ru8(obj + 64) or 0) or 0
        local ttab = ctx.gs and rp(ctx.gs + 0x358) or nil
        if kptr(data) and mask and mask > 0 and mask < 4096
            and kptr(ttab) then
            for b = 0, mask + extra do
                local bk = data + 40 * b
                local dist = SL.ru8(bk + 4) or 0
                if dist ~= 0 and dist ~= 0xFE then
                    local tid = ru32(bk + 8)
                    local ld, lc = rp(bk + 16), ru32(bk + 28)
                    if tid and tid > 0 and tid < 4096
                        and kptr(ld) and lc and lc > 0 and lc < GAME.layout.lim.PTR_SANE then
                        local tname = SL.sso(ttab + 32 * tid)
                        if tname and tname ~= "" then
                            local ids = {}
                            for j = 0, lc - 1 do
                                ids[#ids + 1] = ru32(ld + 4 * j) or 0
                            end
                            local parts = {}
                            local ok2 = true
                            for _, idv in ipairs(ids) do
                                local nm = GAME.layout.token_name(idv)
                                if not nm or nm == "" then
                                    ok2 = false break end
                                parts[#parts + 1] = nm
                            end
                            -- writer 语义 = 名字串字典序 (Lua 默认 `<`),
                            -- 同名异 id 不影响输出文本
                            if ok2 then
                                table.sort(parts)
                                emit(tag, "tokens.operation_assets."
                                    .. tname, table.concat(parts, " "))
                            end
                        end
                    end
                end
            end
        end
    end
end }
