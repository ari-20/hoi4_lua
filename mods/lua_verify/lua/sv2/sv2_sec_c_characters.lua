-- sv2_sec_c_characters.lua -- country.characters 节点 savefull 直出
-- (csec; §4.3 CCountryCharacters cc+4080)

SV2.csec[#SV2.csec + 1] = { name = "country.characters", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local r = c:country_characters()
    if not r then return end

    -- §4.3 CCountryCharacters (cc+4080) 五键状态族公共发射
    -- (character 行首, 四 flag 行序 = 存档文档序)
    local function emit_status(base, st)
        emit(tag, base .. ".character", SL.idpair(st.id, st.type))
        emit(tag, base .. ".country_leader", SL.yn(st.country_leader))
        emit(tag, base .. ".advisor", SL.yn(st.advisor))
        emit(tag, base .. ".unit_leader", SL.yn(st.unit_leader))
        emit(tag, base .. ".scientist", SL.yn(st.scientist))
    end

    -- character_status : 1.19.3 writer 原序直写向量, 段内禁
    -- sort — r.statuses 保持 reader 遍历序 (向量原序), 直接发射
    local seq = SL.seqc()
    for _, st in ipairs(r.statuses or {}) do
        emit_status("characters." .. seq("character_status"), st)
    end

    -- retired_character_status : writer 原序直写 {d@ch+40,
    -- c@ch+52} — 段内重走原始向量, 不消费 objects_v2 的 id 升序 sort
    -- 副本 (仅族非空)
    do
        local rp, ru32 = hoi4.read_u64, hoi4.read_u32
        local rseq = SL.seqc()
        local ch = r.addr
        local rd, rc = rp(ch + 40), ru32(ch + 52) or 0
        if SL.kptr(rd) and rc > 0 and rc < GAME.layout.lim.PTR_SANE then
            for j = 0, rc - 1 do
                local e = rd + 16 * j
                local st = rp(e)
                if SL.kptr(st) then
                    local fl = ru32(e + 8) or 0
                    emit_status("characters."
                        .. rseq("retired_character_status"), {
                        id = ru32(st + 0xC),
                        type = ru32(st + 8),
                        country_leader = (fl % 256) == 1,
                        advisor = (math.floor(fl / 256) % 256) == 1,
                        unit_leader = (math.floor(fl / 65536) % 256) == 1,
                        scientist = (math.floor(fl / 16777216) % 256) == 1,
                    })
                end
            end
        end
    end

    -- appointed_advisors 匿名块 #N (1 起 = 容器序; 块内 slot 先 character 后)
    for ai, av in ipairs(r.advisors or {}) do
        local base = "characters.appointed_advisors.#" .. ai
        local sl = SL.Q(av.slot)
        if sl then emit(tag, base .. ".slot", sl) end
        if av.char_id then
            emit(tag, base .. ".character",
                 SL.idpair(av.char_id, av.char_type))
        end
    end

    -- recruit_scientist (叶级重复键不编号; 仅池非空 — 空池 writer 不写块)
    for _, sc in ipairs(r.recruit_scientists or {}) do
        emit(tag, "characters.recruit_scientist.scientist",
             SL.idpair(sc.id, sc.type))
    end

    -- retired_operative_leader: 池 {d@ch+200, c@ch+212} 8B 指针 →
    -- §4.29.1 COperativeLeader (§4.3 chars+200 行); 叶规则 =
    -- sv2_sec_c_intelligence_agency op_emit 同型 (writer 链相同),
    -- 重复块键 [N] 编号
    do
        local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
        local LAY, R = GAME.layout, c.R
        local OP_STATE = { [0] = "on_capture", [1] = "on_cooldown",
            [2] = "on_disband", [3] = "on_mission", [4] = "on_operation",
            [5] = "killed" }
        local MISSION_NAMES = { [1] = "build_intel_network",
            [2] = "quiet_network", [3] = "counter_intelligence",
            [4] = "root_out_resistance", [5] = "boost_ideology",
            [6] = "control_trade", [7] = "diplomatic_pressure",
            [8] = "propaganda" }
        local function tagof(tid)
            if tid and tid > 0 and R then return R:tag(tid) end
            return nil
        end
        local function fix5(a)   -- i64 ×1e-5 定点 (§3.7; /100000 勿 *1e-5)
            local v = rp(a)
            if not v then return 0 end
            v = GAME.layout.as_i64(v)
            return v / 100000
        end
        local ch = r.addr
        local dd, dc = rp(ch + 200), ru32(ch + 212) or 0
        if SL.kptr(dd) and dc > 0 and dc < GAME.layout.lim.PTR_SANE then
            local oseq = SL.seqc()
            for q = 0, dc - 1 do
                local e = rp(dd + 8 * q)
                if SL.kptr(e) then
                    local base = "characters."
                        .. oseq("retired_operative_leader")
                    emit(tag, base .. ".id",
                        SL.idpair(ru32(e + 12), ru32(e + 8)))
                    local qn = SL.Q(LAY.read_msvc_str(e + 32))
                    if qn then emit(tag, base .. ".name", qn) end
                    -- gfx: COperativeLeader MSVC@e+256 (非空才写) — 与
                    -- intelligence_agency.op_emit 同源同址; 本处曾漏发
                    -- (退役干员有 gfx 而候选池无 → 单侧 MISS)
                    local qg = SL.Q(LAY.read_msvc_str(e + 256))
                    if qg then emit(tag, base .. ".gfx", qg) end
                    if (ru8(e + 3713) or 0) ~= 0 then
                        emit(tag, base .. ".female",
                            SL.yn(ru8(e + 3712) or 0)) end
                    local sk = rp(e + 3680)
                    emit(tag, base .. ".skill",
                        SL.num(SL.kptr(sk) and ru32(sk + 440) or 0))
                    local xp = rp(e + 3688) or 0
                    xp = GAME.layout.as_i64(xp)
                    if xp ~= 0 then
                        emit(tag, base .. ".experience",
                            SL.num(xp / 100000)) end
                    local sid = ru32(e + 3924) or 0
                    if sid ~= 0 then
                        emit(tag, base .. ".script_id", SL.num(sid)) end
                    local td, tc = rp(e + 3528), ru32(e + 3540) or 0
                    if SL.kptr(td) and tc > 0 and tc < GAME.layout.lim.PTR_SANE then
                        local t = {}
                        for k = 0, tc - 1 do
                            local te = rp(td + 8 * k)
                            if SL.kptr(te) then
                                t[#t + 1] = tostring(
                                    SL.tok(ru32(te + 8)) or "?")
                            end
                        end
                        if #t > 0 then
                            emit(tag, base .. ".traits",
                                table.concat(t, " ")) end
                    end
                    -- in_progress 16B {tok*, i64×1e-5} 全条目含 0
                    local pd, pc = rp(e + 3576), ru32(e + 3588) or 0
                    if SL.kptr(pd) and pc > 0 and pc < GAME.layout.lim.PTR_SANE then
                        for k = 0, pc - 1 do
                            local pe = pd + 16 * k
                            local tobj = rp(pe)
                            if SL.kptr(tobj) then
                                local tn = SL.tok(ru32(tobj + 8))
                                if tn then
                                    emit(tag, base .. ".in_progress."
                                        .. tostring(tn),
                                        SL.num(fix5(pe + 8)))
                                end
                            end
                        end
                    end
                    local lid = ru32(e + 3800) or 0xFFFFFFFF
                    if lid ~= 0xFFFFFFFF then
                        emit(tag, base .. ".legacy_id", SL.num(lid)) end
                    -- nationalities u32 tid 数组 → 单行 #1 空格 joined 裸 tag
                    local nd, nc = rp(e + 3944), ru32(e + 3956) or 0
                    if SL.kptr(nd) and nc > 0 and nc < GAME.layout.lim.PTR_SANE then
                        local t = {}
                        for k = 0, nc - 1 do
                            local ntid = ru32(nd + 4 * k) or 0
                            t[#t + 1] = tagof(ntid) or tostring(ntid)
                        end
                        if #t > 0 then
                            emit(tag, base .. ".nationalities.#1",
                                table.concat(t, " ")) end
                    end
                    local capt = ru32(e + 4016) or 0
                    if capt > 0 then
                        local ct = tagof(capt)
                        if ct then
                            emit(tag, base .. ".captured", SL.Q(ct))
                            local cd = SL.date(ru32(e + 4032))
                            if cd then
                                emit(tag, base .. ".capture_date",
                                    SL.Q(cd)) end
                        end
                    end
                    emit(tag, base .. ".codename.type",
                        SL.num(ru32(e + 4056) or 0))
                    local cno = ru32(e + 4176) or 0
                    if cno ~= 0 then
                        emit(tag, base .. ".codename.name_order",
                            SL.num(cno)) end
                    if (ru8(e + 4216) or 0) == 0 then
                        emit(tag, base .. ".codename.is_name_ordered",
                            "no") end
                    local mtype = ru32(e + 4256) or 0
                    if mtype ~= 0 then
                        local mn = MISSION_NAMES[mtype] or tostring(mtype)
                        local mb = base .. ".mission." .. mn
                        local mdata = rp(e + 4248)
                        if SL.kptr(mdata) then
                            local mt = tagof(ru32(mdata + 16) or 0)
                            if mt then
                                emit(tag, mb .. ".target", SL.Q(mt)) end
                            local ms2 = rp(mdata + 24)
                            if SL.kptr(ms2) then
                                local msv = ru32(ms2 + 88) or 0
                                if msv ~= 0 then
                                    emit(tag, mb .. ".state", SL.num(msv))
                                end
                            end
                        end
                    end
                    -- operation (0x2F1B): idpair 门 type@e+3968≠0
                    -- or id@e+3972≠0, 叶序在 codename 后 state 前 (retired
                    -- 与现役同一 writer 0x140C18FF0, 镜像 op_emit)
                    local opty, opid = ru32(e + 3968) or 0, ru32(e + 3972) or 0
                    if opty ~= 0 or opid ~= 0 then
                        emit(tag, base .. ".operation",
                            SL.idpair(opid, opty)) end
                    local stn = OP_STATE[ru32(e + 4224) or 0]
                    if stn then
                        emit(tag, base .. ".state",
                            "state=" .. stn .. " }") end
                end
            end
        end
    end
end }
