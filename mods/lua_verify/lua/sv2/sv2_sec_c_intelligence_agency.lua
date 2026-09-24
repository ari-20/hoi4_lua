-- sv2_sec_c_intelligence_agency.lua -- country.intelligence_agency 节点
-- (§4.11.14 CIntelligenceAgency ag = rp(cc+4032))

local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8

local OP_STATE = { [0] = "on_capture", [1] = "on_cooldown",
    [2] = "on_disband", [3] = "on_mission", [4] = "on_operation",
    [5] = "killed" }
local MISSION_NAMES = { [1] = "build_intel_network", [2] = "quiet_network",
    [3] = "counter_intelligence", [4] = "root_out_resistance",
    [5] = "boost_ideology", [6] = "control_trade",
    [7] = "diplomatic_pressure", [8] = "propaganda" }

SV2.csec[#SV2.csec + 1] = { name = "country.intelligence_agency",
    emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local R = c.R
    local LAY = GAME.layout
    local function fix5(a)
        local v = rp(a)
        if not v then return 0 end
        v = GAME.layout.as_i64(v)
        return v / 100000
    end
    local function tagof(tid)           -- tid → 三字 tag (nil 安全)
        if tid and tid > 0 and R then return R:tag(tid) end
        return nil
    end
    -- §4.11.11 COperativeLeader 元素全字段直发 (基链 §4.4.2 CUnitLeader;
    -- base = 叶路径前缀)
    local function op_emit(base, e)
        emit(tag, base .. ".id", SL.idpair(ru32(e + 12), ru32(e + 8)))
        local nm = LAY.read_msvc_str(e + 32)
        local q = SL.Q(nm)
        if q then emit(tag, base .. ".name", q) end
        -- 字符串块六门 (writer 0x140C1CE70 头段序: name → desc →
        -- custom_cost_text → gfx → picture → portrait_path;
        -- 1.19.3 起 e+192 portrait_path 实装)
        do
            local sq = SL.Q(LAY.read_msvc_str(e + 128))
            if sq then emit(tag, base .. ".desc", sq) end
            sq = SL.Q(LAY.read_msvc_str(e + 160))
            if sq then emit(tag, base .. ".custom_cost_text", sq) end
            sq = SL.Q(LAY.read_msvc_str(e + 256))
            if sq then emit(tag, base .. ".gfx", sq) end
            sq = SL.Q(LAY.read_msvc_str(e + 224))
            if sq then emit(tag, base .. ".picture", sq) end
            sq = SL.Q(LAY.read_msvc_str(e + 192))
            if sq then emit(tag, base .. ".portrait_path", sq) end
        end
        if (ru8(e + 3713) or 0) ~= 0 then
            emit(tag, base .. ".female", SL.yn(ru8(e + 3712) or 0)) end
        local sk = rp(e + 3680)
        emit(tag, base .. ".skill",
            SL.num(SL.kptr(sk) and ru32(sk + 440) or 0))
        local xp = rp(e + 3688) or 0
        xp = GAME.layout.as_i64(xp)
        if xp ~= 0 then
            emit(tag, base .. ".experience", SL.num(xp / 100000)) end
        local sid = ru32(e + 3924) or 0
        if sid ~= 0 then
            emit(tag, base .. ".script_id", SL.num(sid)) end
        -- traits (空格 joined 裸 token 名, 仅 count>0)
        local td, tc = rp(e + 3528), ru32(e + 3540) or 0
        if SL.kptr(td) and tc > 0 and tc < GAME.layout.lim.PTR_SANE then
            local t = {}
            for k = 0, tc - 1 do
                local te = rp(td + 8 * k)
                if SL.kptr(te) then
                    t[#t + 1] = tostring(SL.tok(ru32(te + 8)) or "?")
                end
            end
            if #t > 0 then
                emit(tag, base .. ".traits", table.concat(t, " ")) end
        end
        -- in_progress (16B {tok*, i64×1e-5}; 全条目含 0)
        local pd, pc = rp(e + 3576), ru32(e + 3588) or 0
        if SL.kptr(pd) and pc > 0 and pc < GAME.layout.lim.PTR_SANE then
            for k = 0, pc - 1 do
                local pe = pd + 16 * k
                local tobj = rp(pe)
                if SL.kptr(tobj) then
                    local tn = SL.tok(ru32(tobj + 8))
                    if tn then
                        emit(tag, base .. ".in_progress." .. tostring(tn),
                            SL.num(fix5(pe + 8)))
                    end
                end
            end
        end
        local lid = ru32(e + 3800) or 0xFFFFFFFF
        if lid ~= 0xFFFFFFFF then
            emit(tag, base .. ".legacy_id", SL.num(lid)) end
        -- nationalities {d@e+3944, c@e+3956} u32 tid 数组 → 单行 #1
        -- 空格 joined 裸 tag (定案: writer 写 `nationalities={
        -- ITA ETH SYR }` 内联块 → 提取器整行归一; 逐 tid 分行是错的)
        local nd, nc = rp(e + 3944), ru32(e + 3956) or 0
        if SL.kptr(nd) and nc > 0 and nc < GAME.layout.lim.PTR_SANE then
            local t = {}
            for k = 0, nc - 1 do
                local ntid = ru32(nd + 4 * k) or 0
                t[#t + 1] = tagof(ntid) or tostring(ntid)
            end
            if #t > 0 then
                emit(tag, base .. ".nationalities.#1",
                    table.concat(t, " "))
            end
        end
        -- captured + capture_date
        local capt = ru32(e + 4016) or 0
        if capt > 0 then
            local ct = tagof(capt)
            if ct then
                emit(tag, base .. ".captured", SL.Q(ct))
                local cd = SL.date(ru32(e + 4032))
                if cd then
                    emit(tag, base .. ".capture_date", SL.Q(cd)) end
            end
        end
        -- operation id 对 (§4.11.11 +3968; ext writer 0x140C18FF0
        -- {type@e+3968, id@e+3972} 任一非零 → 块 0x2F1B)
        local opty, opid = ru32(e + 3968) or 0, ru32(e + 3972) or 0
        if opty ~= 0 or opid ~= 0 then
            emit(tag, base .. ".operation", SL.idpair(opid, opty))
        end
        -- cooldown 三件套 (§4.4.2 基类同构; 总门/枚举串/日期对 =
        -- 书 §4.4.2 + §4.4.4)
        local cdr = ru32(e + 3716) or 0
        if cdr ~= 0 then
            local CDR = { [0] = "no_cooldown", "reassigned", "harmed",
                "forced_into_hiding", "deployed", "withdrawing" }
            local rn = CDR[cdr]
            if rn then
                emit(tag, base .. ".cooldown_reason", '"' .. rn .. '"')
            end
            local d1 = SL.date(ru32(e + 3752))
            if d1 then
                emit(tag, base .. ".leader_modifier_enable_date",
                    '"' .. d1 .. '"')
            end
            local d2 = SL.date(ru32(e + 3728))
            if d2 then
                emit(tag, base .. ".leader_cooldown_start_date",
                    '"' .. d2 .. '"')
            end
        end
        -- codename (type 恒写 / name_order ≠0 / is_name_ordered 仅 "no")
        emit(tag, base .. ".codename.type", SL.num(ru32(e + 4056) or 0))
        local cno = ru32(e + 4176) or 0
        if cno ~= 0 then
            emit(tag, base .. ".codename.name_order", SL.num(cno)) end
        if (ru8(e + 4216) or 0) == 0 then
            emit(tag, base .. ".codename.is_name_ordered", "no") end
        -- mission (仅 u32@e+4256 ≠0)
        local mtype = ru32(e + 4256) or 0
        if mtype ~= 0 then
            local mn = MISSION_NAMES[mtype] or tostring(mtype)
            local mb = base .. ".mission." .. mn
            local mdata = rp(e + 4248)
            if SL.kptr(mdata) then
                local mtid = ru32(mdata + 16) or 0
                local mt = tagof(mtid)
                if mt then emit(tag, mb .. ".target", SL.Q(mt)) end
                local ms2 = rp(mdata + 24)
                -- state 仅 build_intel_network(1) / root_out_resistance(4) 写
                -- 锚件全档实证 (26+2 例), counter_intelligence(3) 恒无
                -- (7 例仅 target) — 该型 mdata+24 的布局不同, 按通用
                -- +88 读会取到定点值 (RUS 误发 state=150000)
                -- ⚠ 类型 5-8 本档无实例, 口径未决 (沿用 1/4 白名单)
                if SL.kptr(ms2) and (mtype == 1 or mtype == 4) then
                    local msv = ru32(ms2 + 88) or 0
                    if msv ~= 0 then
                        emit(tag, mb .. ".state", SL.num(msv))
                    end
                end
            end
        end
        -- state 恒写 (枚举反表; 未知码跳过)
        local st = OP_STATE[ru32(e + 4224) or 0]
        if st then
            emit(tag, base .. ".state", "state=" .. st .. " }") end
    end

    local ok, r = pcall(function() return c:intelligence_agency() end)
    if not ok or not r then return end
    local ag = r.addr
    if not ag then return end

    -- 头标量族 (§4.11.14; writer 0x140FCA0F0 序)
    emit(tag, "intelligence_agency.name", SL.Q(r.name) or '""')
    emit(tag, "intelligence_agency.icon", '"' .. (r.icon or "") .. '"')
    if r.is_created then
        emit(tag, "intelligence_agency.is_created", "yes") end
    if r.in_creation then
        emit(tag, "intelligence_agency.in_creation", "yes") end
    if r.upgrade_progress and r.upgrade_progress ~= 0 then
        emit(tag, "intelligence_agency.upgrade_progress",
            SL.num(r.upgrade_progress)) end
    -- captured.#N (§4.11.16 CCapturedOperativeReference 56B 元:
    -- country idx@+8 / op type@+12 / op id@+16 /
    -- intel 四象限 i64×1e-5@+24/+32/+40/+48)
    do
        local cd, cc2 = rp(ag + 264), ru32(ag + 276) or 0
        if SL.kptr(cd) and cc2 > 0 and cc2 < GAME.layout.lim.PTR_SANE then
            for q2 = 0, cc2 - 1 do
                local e3 = cd + 56 * q2
                local b = "intelligence_agency.captured.#" .. (q2 + 1)
                local ct = tagof(ru32(e3 + 8))
                if ct then emit(tag, b .. ".country", SL.Q(ct)) end
                emit(tag, b .. ".operative",
                    SL.idpair(ru32(e3 + 16), ru32(e3 + 12)))
                emit(tag, b .. ".intel.civilian", SL.num(fix5(e3 + 24)))
                emit(tag, b .. ".intel.army", SL.num(fix5(e3 + 32)))
                emit(tag, b .. ".intel.navy", SL.num(fix5(e3 + 40)))
                emit(tag, b .. ".intel.airforce", SL.num(fix5(e3 + 48)))
            end
        end
    end
    -- operative[N] (§4.11.14 operative {d@ag+216, c@ag+228})
    do
        -- reader 未给元素地址 → 容器直迭代 (序 = 存档序)
        local seqo = SL.seqc()
        local od, oc = rp(ag + 216), ru32(ag + 228) or 0
        if SL.kptr(od) and oc > 0 and oc < GAME.layout.lim.PTR_SANE then
            for q3 = 0, oc - 1 do
                local e = rp(od + 8 * q3)
                if SL.kptr(e) then
                    op_emit("intelligence_agency." .. seqo("operative"), e)
                end
            end
        end
    end
    -- upgrades.<name> (仅 count>0)
    do
        local ud, uc = rp(ag + 96), ru32(ag + 108) or 0
        if SL.kptr(ud) and uc > 0 and uc < 4096 then  -- 32 字面量上限会被大 mod 击穿
            for q4 = 0, uc - 1 do
                local e2 = ud + 16 * q4
                local p2 = rp(e2)
                if SL.kptr(p2) then
                    local un = SL.tok(ru32(p2 + 8))
                    if un then
                        emit(tag, "intelligence_agency.upgrades."
                            .. tostring(un), SL.num(ru32(e2 + 8) or 0))
                    end
                end
            end
        end
    end
    -- upgrade 裸键 (§4.11.14; writer 0x140FCA0F0 L69: def*@ag+208
    -- 指针门, ADCE0(15356, token@def+8) 裸名)
    do
        local udef = rp(ag + 208)
        if SL.kptr(udef) then
            local un = LAY.token_name(ru32(udef + 8) or 0)
            if un and un ~= "" then
                emit(tag, "intelligence_agency.upgrade", un)
            end
        end
    end
    -- own_operative_death (writer L45: u32@ag+252 ≠0 才写, 0x4B60)
    local ood = ru32(ag + 252) or 0
    if ood ~= 0 then
        emit(tag, "intelligence_agency.own_operative_death",
            SL.num(ood))
    end
    -- cryptology.targets (§4.11.9 CCryptology/CCountryDecryptionState;
    -- crypto = *(ag+288), 容器/元素布局/门 = 书)
    do
        local crypto = rp(ag + 288)
        local td2 = SL.kptr(crypto) and rp(crypto + 40) or nil
        local tc2 = SL.kptr(crypto) and (ru32(crypto + 52) or 0) or 0
        if SL.kptr(td2) and tc2 > 0 and tc2 < GAME.layout.lim.PTR_SANE then
            for q6 = 0, tc2 - 1 do
                local e4 = td2 + 56 * q6
                local b6 = "intelligence_agency.cryptology.targets.#"
                    .. (q6 + 1) .. "."
                local t6 = tagof(ru32(e4 + 8))
                if t6 then
                    emit(tag, b6 .. "target", SL.Q(t6)) end
                local dy = ru32(e4 + 12) or 0xFFFFFFFF
                if dy ~= 0xFFFFFFFF then
                    emit(tag, b6 .. "days", SL.num(dy)) end
                if (ru8(e4 + 16) or 0) ~= 0 then
                    emit(tag, b6 .. "active", "yes") end
                if (ru8(e4 + 17) or 0) ~= 0 then
                    emit(tag, b6 .. "hide", "yes") end
                if (ru8(e4 + 18) or 0) ~= 0 then
                    emit(tag, b6 .. "decryption", "yes") end
                local am = fix5(e4 + 24)
                if am ~= 0 then
                    emit(tag, b6 .. "amount", SL.num(am)) end
                local dh = ru32(e4 + 40)
                if dh and dh ~= 43808760 then
                    local ds = SL.date(dh)
                    if ds then
                        emit(tag, b6 .. "date", '"' .. ds .. '"') end
                end
            end
        end
    end
    -- cryptology.intel_source.* 归 sv2_sec_c_intel.lua 管辖
    do
        -- §4.11.14 recruitment 三容器 (generated/recruitable/
        -- recruitable_not_to_spy_master)
        local function rec_list(doff, coff, base)
            local dd, dc = rp(ag + doff), ru32(ag + coff) or 0
            if SL.kptr(dd) and dc > 0 and dc < GAME.layout.lim.PTR_SANE then
                local n5 = 0
                for q5 = 0, dc - 1 do
                    local e = rp(dd + 8 * q5)
                    if SL.kptr(e) then
                        n5 = n5 + 1
                        op_emit(base .. ".#" .. n5, e)
                    end
                end
            end
        end
        rec_list(24, 36,
            "intelligence_agency.recruitment.generated_operatives")
        rec_list(48, 60,
            "intelligence_agency.recruitment.recruitable_operatives")
        rec_list(72, 84,
            "intelligence_agency.recruitment.recruitable_operatives"
            .. "_not_to_spy_master")
    end
    -- 尾标量五件 (§4.11.14; 恒写含 0)
    emit(tag, "intelligence_agency.defense", SL.num(r.defense or 0))
    emit(tag, "intelligence_agency.max_operative_count",
        SL.num(r.max_operative_count or 0))
    emit(tag, "intelligence_agency.usable_operative_slots",
        SL.num(r.usable_operative_slots or 0))
    emit(tag, "intelligence_agency.elapsed_days_for_next_slot",
        SL.num(r.elapsed_days_for_next_slot or 0))
    emit(tag, "intelligence_agency.building", SL.num(r.building or 0))
end }
