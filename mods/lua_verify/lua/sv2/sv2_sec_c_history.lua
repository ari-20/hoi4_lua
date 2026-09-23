-- sv2_sec_c_history.lua -- country.history 节点 savefull 直出

local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8

SV2.csec[#SV2.csec + 1] = { name = "country.history", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local BASE = ctx.BASE
    -- §4.3.13 CLoopHistory (country.history @cc+4040, 固定 3 队列对象
    -- @+16/+24/+32; 队列 {data@+8, rows@+20, max@+32, offset@+36,
    -- is_full@+40}; cols = *(qc+56)+52 parent 回读)
    local H = rp(ctx.cc + 4040)
    if not SL.kptr(H) then return end
    if rp(H) ~= BASE + GAME.layout.vt.CLoopHistory then return end   -- CLoopHistory vt
    for qi = 0, 2 do
        local C = rp(H + 16 + 8 * qi)
        if SL.kptr(C) and rp(C) == BASE + GAME.layout.vt.CLoopHistoryEntry then
            local b = "history.history_queue." .. qi
            emit(tag, b .. ".max_elements", SL.num(ru32(C + 32) or 0))
            emit(tag, b .. ".offset", SL.num(ru32(C + 36) or 0))
            emit(tag, b .. ".is_full", SL.yn(ru8(C + 40) or 0))
            local rows = ru32(C + 20) or 0
            local desc = rp(C + 56)
            local cols = SL.kptr(desc) and (ru32(desc + 52) or 0) or 0
            local buf = rp(C + 8)
            if rows > 0 and rows <= 4096 and cols > 0 and cols <= 64
                and SL.kptr(buf) then
                local vals, any = {}, false
                local bad = false
                for i = 0, rows - 1 do
                    local h1 = rp(buf + 8 * i)          -- 行句柄
                    local row = SL.kptr(h1) and rp(h1)  -- 行数据基址
                    if not SL.kptr(row) then bad = true break end
                    for j = 0, cols - 1 do
                        local v = rp(row + 8 * j) or 0
                        v = GAME.layout.as_i64(v)
                        if v ~= 0 then any = true end
                        vals[#vals + 1] = SL.num(v / 100000)
                    end
                end
                if not bad and any then
                    emit(tag, b .. ".data.#1", table.concat(vals, " "))
                end
            end
        end
    end
end }
