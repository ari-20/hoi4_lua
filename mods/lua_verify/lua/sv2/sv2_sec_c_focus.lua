-- sv2_sec_c_focus.lua -- country.focus 节点 savefull 直出
SV2.csec[#SV2.csec + 1] = { name = "country.focus", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
    local BASE = ctx.BASE

    -- §4.3.1 CReducedFocusCost (内嵌@cc+5000, RH 桶@cc+5016):
    -- focus_cost_reduction 键 = focus 名, 值 int
    local okf, fcr = pcall(function() return c:focus_cost_reduction() end)
    if okf and fcr then
        for _, e in ipairs(fcr) do
            if e.key then
                emit(tag, "focus_cost_reduction." .. e.key,
                    SL.num(e.value or 0))
            end
        end
    end

    -- §4.3.14 CFocusStatus (fp = *(cc+4992))
    local fp = rp(ctx.cc + 4992)
    if not SL.kptr(fp) then return end
    local R = c.R
    local has_content = false
    local function tagof(tid)
        if tid and tid > 0 and R then return R:tag(tid) end
        return nil
    end
    local function fnv1a_ptr(p)          -- FNV-1a 32bit over 8 ptr bytes
        local h = 0x811C9DC5
        for i = 0, 7 do
            local b = (p >> (8 * i)) & 0xFF
            h = ((h ~ b) * 16777619) & 0xFFFFFFFF
        end
        return h
    end
    -- §4.3.14 shine 列表 (fp+32; 仅 count>0; 单行 #1 空格 joined)
    do
        local sd, sc = rp(fp + 32), ru32(fp + 44) or 0
        if SL.kptr(sd) and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
            local t = {}
            for k = 0, sc - 1 do
                local e = rp(sd + 8 * k)
                if SL.kptr(e) then
                    local nm = hoi4.read_str(e + 24)
                    if nm and nm ~= "" then t[#t + 1] = nm end
                end
            end
            if #t > 0 then
                has_content = true
                emit(tag, "focus.activate_shine_on_focus.#1",
                    table.concat(t, " "))
            end
        end
    end
    -- §4.3.14 completed (双形态多重集; 容器@fp+64 + fp+88 失效图
    -- + fp+152 originator 表)
    do
        local cd, cc2 = rp(fp + 64), ru32(fp + 76) or 0
        if SL.kptr(cd) and cc2 > 0 and cc2 <= 1024 then
            -- originator 表 (fp+152 RH, 24B 桶)
            local ob, omask = rp(fp + 152), ru32(fp + 164)
            local oextra = ru8(fp + 168) or 0
            local ovalid = SL.kptr(ob) and omask and omask < 0x10000
            -- fp+88 失效图 (16B 桶)
            local ib, imask = rp(fp + 96), ru32(fp + 108)
            local iextra = ru8(fp + 112) or 0
            local ivalid = SL.kptr(ib) and imask and imask < 0x10000
            local function originator(e)
                if ivalid then
                    local h = fnv1a_ptr(e)
                    local bk = ib + 16 * (h & imask)
                    local n = 1
                    while true do
                        local dist = ru8(bk + 4)
                        if not dist or dist == 0 or n > dist then break end
                        if rp(bk + 8) == e then
                            local vp = rp(bk)
                            if SL.kptr(vp) and ru8(vp + 4) == 0xFF then
                                return 0          -- 失效 → tid 0
                            end
                            break
                        end
                        bk = bk + 16
                        n = n + 1
                        if n > imask + iextra + 2 then break end
                    end
                end
                if ovalid then
                    local h = fnv1a_ptr(e)
                    local bk = ob + 24 * (h & omask)
                    local n = 1
                    while true do
                        local dist = ru8(bk + 4)
                        if not dist or dist == 0 or n > dist then break end
                        if rp(bk + 8) == e then
                            return ru32(bk + 16) or 0
                        end
                        bk = bk + 24
                        n = n + 1
                        if n > omask + oextra + 2 then break end
                    end
                end
                return 0
            end
            for k = 0, cc2 - 1 do
                local e = rp(cd + 8 * k)
                if SL.kptr(e) then
                    local nm = hoi4.read_str(e + 24)
                    if nm and nm ~= "" then
                        local vt = rp(e)
                        -- 1.19.3 基桩 = BASE+0x11D220 (旧 0x11CD10
                        -- 已失效 → 全体误判联合, plain 行染 "--- " 前缀)
                        local joint = SL.kptr(vt)
                            and rp(vt + 112) ~= BASE + 0x11D220
                        if joint then
                            local tid = originator(e)
                            -- tid 0 渲染 "---" (writer BA5C20 串表 idx0;
                            -- BAK 实证, 旧 tostring(0)="0" 错)
                            local tg = (tid and tid > 0 and tagof(tid))
                                or ((not tid or tid == 0) and "---")
                                or tostring(tid)
                            emit(tag, "focus.completed", tg .. " " .. nm)
                        else
                            emit(tag, "focus.completed", '"' .. nm .. '"')
                        end
                        has_content = true
                    end
                end
            end
        end
    end
    -- §4.3.14 progress / current / paused (writer 独立门 + 块级省略)
    local prog = rp(fp + 56) or 0
    prog = GAME.layout.as_i64(prog)
    if prog ~= 0 then
        has_content = true
        emit(tag, "focus.progress", SL.num(prog / 100000)) end
    -- current / current_continuous 上提 reader Country.focus (;
    -- 空串门 = writer 规则留段层)
    local _, foc = pcall(function() return c:focus() end)
    local nm = foc and foc.current
    if nm and nm ~= "" then
        has_content = true
        emit(tag, "focus.current", '"' .. nm .. '"') end
    local nm2 = foc and foc.current_continuous
    if nm2 and nm2 ~= "" then
        has_content = true
        emit(tag, "focus.current_continuous", '"' .. nm2 .. '"') end
    if has_content and (ru8(fp + 176) or 0) == 0 then
        emit(tag, "focus.paused", "no") end
end }
