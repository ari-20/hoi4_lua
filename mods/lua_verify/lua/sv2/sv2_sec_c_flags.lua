-- sv2_sec_c_flags.lua -- country.flags 节点 savefull 直出

SV2.csec[#SV2.csec + 1] = { name = "country.flags", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32 = SL.rp, SL.ru32
    -- mod 旗 token 在 lexer 扩展段 (§4.3.1 表 cc+560 行注),
    -- 界 = 运行时 lexer max
    local lexmax = hoi4.read_u32(hoi4.base() + GAME.layout.rva.lexer_token_max) or 100000
    -- §4.13.3 CFlagManager / CScriptFlag 条目 48B
    -- (国家侧挂载 cc+560, §4.3.1 表; 条目 {token@+8, setdate@+24,
    -- value|expiry 打包@+0x28})
    local store = rp(c.addr + 0x230)
    if not SL.kptr(store) then return end
    local d, cnt = rp(store + 8), ru32(store + 0x14)
    if not SL.kptr(d) or not cnt or cnt <= 0 or cnt > 100000 then return end
    for i = 0, cnt - 1 do
        local e = d + 0x30 * i
        local key = ru32(e + 8)
        local nm = key and key <= lexmax and SL.tok(key)
        if nm and nm ~= "" then
            local kp = "flags." .. tostring(nm) .. "."
            local pack = ru32(e + 0x28) or 0
            local v = pack & 0xFFFF
            v = GAME.layout.as_i16(v)
            emit(tag, kp .. "value", tostring(v))
            local dh = ru32(e + 0x18)
            if dh and dh > 0 then
                local ds = SL.date(dh) -- 绝对小时直用 (同 states 段)
                if ds then emit(tag, kp .. "date", '"' .. ds .. '"') end
            end
            local ex = (pack >> 16) & 0x7FFF
            if ex > 0 then emit(tag, kp .. "days", tostring(ex)) end
        end
    end
end }
