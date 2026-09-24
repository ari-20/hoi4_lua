-- sv2_sec_c_operations.lua -- country.operations 节点 savefull 直出
-- (csec; §4.11.15 country.operations, ops = *(cc+5544))

SV2.csec[#SV2.csec + 1] = { name = "country.operations", emit = function(ctx)
    local SL, emit, tag = SV2.lib, ctx.emit, ctx.tag
    local cc = ctx.cc
    if not cc then return end
    local rp, ru32, ru8, kptr = SL.rp, SL.ru32, SL.ru8, SL.kptr
    -- §4.11.15 country.operations (ops = *(cc+5544))
    local ops = SL.rp(cc + 5544)
    if not kptr(ops) then return end
    local v = SL.ru32(ops + 88)
    if v then emit(tag, "operations.priority", SL.num(v)) end

    -- §1.2 gs+856 (0x358) tag 串表, 32B/项
    local ttab = ctx.gs and rp(ctx.gs + 0x358) or nil
    local function tagof(tid)
        if not (ttab and kptr(ttab) and tid and tid > 0 and tid < 4096)
            then return nil end
        local s = SL.sso(ttab + 32 * tid)
        if s and s ~= "" then return s end
        return nil
    end
    local function tokname(id)
        local nm = id and GAME.layout.token_name(id) or nil
        if nm and nm ~= "" then return nm end
        return nil
    end

    -- ===== finished (§4.11.15 CCountryFinishedOperations @ops+40;
    -- 外 48B 桶 RH §3.2 @ops+40; 内 12B 桶) =====
    do
        local fin = ops + 40
        local data, mask, extra = rp(fin + 16), ru32(fin + 28),
            ru8(fin + 32) or 0
        if kptr(data) and mask and mask > 0 and mask < 4096 then
            for b = 0, mask + extra do
                local bk = data + 48 * b
                local dist = ru8(bk + 4) or 0
                if dist ~= 0 and dist ~= 0xFE then
                    local opname = tokname(ru32(bk + 8))
                    local idata = rp(bk + 24)
                    local imask, iextra = ru32(bk + 36) or 0,
                        ru8(bk + 40) or 0
                    if opname and kptr(idata) and imask > 0
                        and imask < 4096 then
                        local pairs_ = {}
                        for j = 0, imask + iextra do
                            local ib = idata + 12 * j
                            local d2 = ru8(ib) or 0
                            if d2 ~= 0 and d2 ~= 0xFE then
                                pairs_[#pairs_ + 1] = {
                                    t = ru32(ib + 4) or 0,
                                    n = ru32(ib + 8) or 0 }
                            end
                        end
                        table.sort(pairs_, function(x, y)
                            return x.t < y.t end)
                        local parts = {}
                        local ok2 = true
                        for _, pr in ipairs(pairs_) do
                            local tn = tagof(pr.t)
                            if not tn then ok2 = false break end
                            parts[#parts + 1] = tn .. " " .. pr.n
                        end
                        if ok2 and #parts > 0 then
                            emit(tag, "operations.finished." .. opname,
                                table.concat(parts, " "))
                        end
                    end
                end
            end
        end
    end

    -- ===== running (§4.11.15/§4.11.12 operation 块; 8B 指针容器 @ops+16/+28) =====
    local MISSION_TOK = { [0] = 12789, 15642, 19232, 15643, 19233, 19228,
        19229, 19230, 19231 }
    local rd, rc = rp(ops + 16), ru32(ops + 28)
    if kptr(rd) and rc and rc > 0 and rc < GAME.layout.lim.PTR_SANE then
        for i = 0, rc - 1 do
            local op = rp(rd + 8 * i)
            if kptr(op) then
                local def = rp(op + 72)
                local opname = kptr(def) and tokname(ru32(def + 8))
                    or nil
                if opname then
                    local B = "operations.running." .. opname .. "."
                    emit(tag, B .. "id", SL.idpair(ru32(op + 12),
                        ru32(op + 8)))
                    local dur = ru32(op + 128)
                    if dur and dur ~= 0 then
                        local ds = SL.date(ru32(op + 112))
                        if ds then
                            emit(tag, B .. "date", '"' .. ds .. '"') end
                        emit(tag, B .. "duration", tostring(dur))
                    end
                    -- 代价标量 (writer 0x1413EF710 L11-17:
                    -- 0x4BDD=civilian_factories i64@+48 /
                    -- 0x2A12=total i64@+56, 均 ×1e-5 ≠0 才写)
                    local cf = rp(op + 48)
                    if cf then cf = GAME.layout.as_i64(cf) end
                    if cf and cf ~= 0 then
                        emit(tag, B .. "civilian_factories",
                            SL.num(cf * 1e-5)) end
                    local tt2 = rp(op + 56)
                    if tt2 then tt2 = GAME.layout.as_i64(tt2) end
                    if tt2 and tt2 ~= 0 then
                        emit(tag, B .. "total", SL.num(tt2 * 1e-5)) end
                    -- resources 块 (§4.11.12/§4.11.16 COperationResources;
                    -- 容器/旗分支 = 书)
                    do
                        local rsd, rsc = rp(op + 344), ru32(op + 356)
                        if kptr(rsd) and rsc and rsc > 0 and rsc < GAME.layout.lim.PTR_SANE then
                            for ri = 0, rsc - 1 do
                                local re = rsd + 32 * ri
                                local amt = rp(re)
                                if amt then amt = GAME.layout.as_i64(amt) end
                                local fl = ru8(re + 24) or 0
                                if fl ~= 0 then
                                    local a9 = amt >= 0
                                        and math.floor(amt / 100000)
                                        or -math.floor(-amt / 100000)
                                    emit(tag, B .. "resources."
                                        .. "civilian_factories.amount",
                                        SL.num(a9))
                                    emit(tag, B .. "resources."
                                        .. "civilian_factories.days",
                                        tostring(ru32(re + 8) or 0))
                                else
                                    local dp = rp(re + 16)
                                    local nm = kptr(dp)
                                        and SL.tok(ru32(dp + 8) or 0) or nil
                                    if nm and amt then
                                        emit(tag, B .. "resources." .. nm,
                                            SL.num(amt / 100000))
                                    end
                                end
                            end
                        end
                    end
                    -- return_on_complete (§4.11.12; 容器/存档半行匿名形态/
                    -- 提取器 @.#N 折叠规则 = 书)
                    do
                        local rod, roc = rp(op + 368), ru32(op + 380)
                        if kptr(rod) and roc and roc > 0 and roc < GAME.layout.lim.PTR_SANE then
                            for oi = 0, roc - 1 do
                                local re = rod + 16 * oi
                                local amt = rp(re + 8)
                                if amt then amt = GAME.layout.as_i64(amt) end
                                if amt then
                                    emit(tag, B
                                        .. "return_on_complete.@.#"
                                        .. (oi + 1), SL.num(amt / 100000))
                                end
                            end
                        end
                    end
                    -- equipment 块恒写 (§4.11.15; ADEC0 0x2F4E 无门);
                    -- 池 {d@op+304, c@op+316} 16B {var ptr, amount i64}
                    -- 门 amount≠0 或 az (定案; id 对 {type@var+8, id@+12})
                    local eqd, eqc = rp(op + 272 + 32), ru32(op + 272 + 44)
                    if kptr(eqd) and eqc and eqc > 0 and eqc < 4096 then
                        local eaz = (ru8(op + 272 + 56) or 0) ~= 0
                        local eseq = SL.seqc()
                        for ek = 0, eqc - 1 do
                            local ebase = eqd + 16 * ek
                            local vp = rp(ebase)
                            local amt = rp(ebase + 8) or 0
                            if (amt ~= 0 or eaz) and kptr(vp) then
                                local EK = B .. "equipment."
                                    .. eseq("equipment") .. "."
                                emit(tag, EK .. "id",
                                    SL.idpair(ru32(vp + 12), ru32(vp + 8)))
                                emit(tag, EK .. "amount",
                                    SL.num(amt / 100000))
                            end
                        end
                    end
                    emit(tag, B .. "equipment.allow_zero_entries",
                        SL.yn(ru8(op + 272 + 56) or 0))
                    local tg = tagof(ru32(op + 88))
                    if tg then emit(tag, B .. "target", '"' .. tg .. '"')
                        end
                    local tp = rp(op + 96)
                    if kptr(tp) then
                        emit(tag, B .. "target_provinces",
                            tostring(ru32(tp + 164) or 0))
                    end
                    -- operative_slots (§4.11.15; #N 匿名块)
                    local sd, sc = rp(op + 224), ru32(op + 236)
                    if kptr(sd) and sc and sc > 0 and sc < GAME.layout.lim.PTR_SANE then
                        for j = 0, sc - 1 do
                            local el = sd + 56 * j
                            local SK = B .. "operative_slots.#"
                                .. (j + 1) .. "."
                            local oty, oid = ru32(el), ru32(el + 4)
                            if (oty or 0) ~= 0 or (oid or 0) ~= 0 then
                                emit(tag, SK .. "operative",
                                    SL.idpair(oid, oty))
                            end
                            if (ru32(el + 8) or 0) ~= 0 then
                                emit(tag, SK .. "resume_mission", "yes")
                            end
                            if (ru8(el + 48) or 0) ~= 0 then
                                local mi = el + 16
                                local mnm = tokname(MISSION_TOK[
                                    ru32(mi + 8) or -1])
                                if mnm then
                                    emit(tag, SK .. "mission.mission",
                                        mnm)
                                end
                                local mc = tagof(ru32(mi + 12))
                                if mc then
                                    emit(tag, SK
                                        .. "mission.target_country",
                                        '"' .. mc .. '"')
                                end
                                local mst = rp(mi + 16)
                                if kptr(mst) then
                                    emit(tag, SK .. "mission.target_state",
                                        tostring(ru32(mst + 88) or 0))
                                end
                            end
                        end
                    end
                    -- phases (引号空格单行)
                    local pd, pc = rp(op + 248), ru32(op + 260)
                    if kptr(pd) and pc and pc > 0 and pc < GAME.layout.lim.PTR_SANE then
                        local parts = {}
                        local ok2 = true
                        for j = 0, pc - 1 do
                            local pe = rp(pd + 8 * j)
                            local pn = kptr(pe) and tokname(ru32(pe + 8))
                                or nil
                            if not pn then ok2 = false break end
                            parts[#parts + 1] = '"' .. pn .. '"'
                        end
                        if ok2 then
                            emit(tag, B .. "phases",
                                table.concat(parts, " "))
                        end
                    end
                    -- prepared (hours@op+208 != 1.1.1.1 哨兵)
                    local ph = ru32(op + 208)
                    if ph and ph ~= 43808760 then
                        local ds = SL.date(ph)
                        if ds then
                            emit(tag, B .. "prepared", '"' .. ds .. '"')
                        end
                    end
                end
            end
        end
    end
end }
