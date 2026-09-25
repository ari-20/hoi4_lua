-- sv2_sec_emarket_global.lua -- 全局 equipment_market 节点 savefull 直出

SV2.gsec[#SV2.gsec + 1] = { name = "equipment_market", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, ru8, ri64 = SL.rp, SL.ru32, SL.ru8, SL.rp_i64
    local DIM = "equipment_market"
    local gs = ctx.gs
    if not (gs and SL.kptr(gs)) then return end
    -- §4.23.3 NInternationalMarket (gs+1000)
    local mkt = rp(gs + 0x3E8)          -- 0x3E8 = 1000
    if not SL.kptr(mkt) then return end -- 空 → writer 整块不写

    local function fix5(a)              -- i64×1e-5 定点 → savefull 数值串
        return SL.num((ri64(a) or 0) / 100000)
    end
    local function tagq(tid)            -- tag_id → "GER" (无效 → nil 不写)
        local t = tid and O:tag(tid) or nil
        return t and SL.Q(t) or nil
    end
    -- CEquipmentVariantPool 发射 = SL.pool_emit (共享; 布局知识住 reader)
    -- 内嵌 CVariables (合同+752; 空 → 整块不写, 参照档实证)
    -- §4.25.1 CVariables
    local function emit_vars(pfx, vo)
        -- 空表门: data = 静态空桶哨兵 &unk_14306D1A0 或 mask==0 → 跳过
        -- (缺门时 rh_iter count 兜底读 vo+0x10 错偏移 → 扫 .rdata 垃圾,
        -- 集成实测垃圾变量名 "Jun 29 2026..." 事故)
        local d = rp(vo + 0x18)
        if not SL.kptr(d) or d == (ctx.BASE + 0x306D1A0) then return end
        local mask = ru32(vo + 0x24)
        if not mask or mask == 0 or mask > 8192 then return end
        local buckets = GAME.layout.rh_iter(vo, { data = 0x18, mask = 0x24,
            stride = 0x30, maxn = GAME.layout.lim.PTR_HUGE })
        local list = {}
        for _, b in ipairs(buckets or {}) do
            local dist = ru32(b + 4)
            if dist and (dist & 0xFF) ~= 0 and (dist & 0xFF) ~= 0xFE
                and (dist & 0xFF) ~= 0xFF then
                local nm = SL.sso(b + 8)
                local val = ri64(b + 0x28)
                if nm and val then
                    list[#list + 1] = nm .. "|" .. SL.num(val / 100000)
                end
            end
        end
        if #list == 0 then return end
        local r8 = ru32(vo + 8)
        if r8 and r8 ~= 1 then            -- random 哨兵 (writer 0x1424B0BB0)
            emit(DIM, pfx .. "random", string.format("%d %d",
                ru32(vo + 12) or 0, r8))
        end
        table.sort(list)                  -- 写序 = 键字节序
        local seq = 0
        for _, kv in ipairs(list) do
            local nm, val = kv:match("^(.-)|(.*)$")
            if nm then
                if nm:find("%^num$") then
                    seq = seq + 1
                    emit(DIM, pfx .. "#" .. seq, nm .. "=" .. val)
                else
                    emit(DIM, pfx .. nm, val)
                end
            end
        end
    end

    -- ===== contracts (容器 @mkt+0; [N] = 数组线性序 = 创建序) =====
    -- §4.23.3 CPurchaseContract; 容器/def 读取住 reader (O:equipment_market)
    local mk_r = O:equipment_market()
    if mk_r and #mk_r.contracts > 0 then
        local cseq = SL.seqc()
        for _, crec in ipairs(mk_r.contracts) do
            local c = crec.addr
            local P = "contracts." .. cseq("purchase_contract") .. "."
            -- id 对 {type@+8, id@+12} (sub_14220B320(c+8))
            emit(DIM, P .. "id", SL.idpair(crec.id_id, crec.id_type))
            -- contract_definition (def = c+24) — 发射规则住本层
            local DP = P .. "contract_definition."
            local RP = DP .. "contract_draft."
            SL.def_emit(O, emit, DIM, DP, crec.def_addr)
            -- delivery_route_handler (cli = c+240 内嵌 CEquipmentConvoyClient)
            -- §4.23.3 CEquipmentConvoyClient
            local HP = P .. "delivery_route_handler."
            local CP = HP .. "convoy_client."
            emit(DIM, CP .. "length", tostring(ru32(c + 432) or 0))
            emit(DIM, CP .. "type", tostring(ru8(c + 436) or 0))
            -- 在途装备池 (发射规则住本层; 布局住 reader)
            SL.pool_emit(O, emit, DIM, CP .. "equipments.", c + 368,
                         { max = GAME.layout.lim.PTR_HUGE })
            if (ru8(c + 256) or 0) ~= 0 then         -- has-id 标志门
                emit(DIM, CP .. "id",
                    SL.idpair(ru32(c + 252), ru32(c + 248)))
            end
            local cv_total = ru32(c + 284) or 0
            if cv_total ~= 0 then   -- convoys_subscriber 块仅 total≠0 写
                emit(DIM, CP .. "convoys_subscriber.convoys",
                    tostring(ru32(c + 280) or 0))
                emit(DIM, CP .. "convoys_subscriber.total",
                    tostring(cv_total))
            end
            emit(DIM, CP .. "country", tagq(ru32(c + 264)))
            -- spotter (token 勘误 15488=0x3C80; convoy client
            -- 基类 writer 在 {type u32@c+352, id u32@c+356} 上
            -- AF2C0+B240 出块, 门 type≠0 或 id≠0)
            local spty, spid = ru32(c + 352), ru32(c + 356)
            if (spty and spty ~= 0) or (spid and spid ~= 0) then
                emit(DIM, CP .. "spotter", SL.idpair(spid, spty))
            end
            emit(DIM, CP .. "efficiency", fix5(c + 312))
            emit(DIM, CP .. "efficiency_due_to_lost_convoys", fix5(c + 320))
            emit(DIM, CP .. "request", tostring(ru32(c + 360) or 0))
            -- combat (F; 基类 0x2916, a1=cli=c+240: {d@c+328,
            -- c@c+340} 元 8B {type@0, id@+4} c≠0 块门)
            local kbd, kbc = rp(c + 328), ru32(c + 340) or 0
            if SL.kptr(kbd) and kbc > 0
                and kbc <= GAME.layout.lim.FIXED_SMALL then
                for j3 = 0, kbc - 1 do
                    emit(DIM, CP .. "combat.#" .. (j3 + 1),
                        SL.idpair(ru32(kbd + 8 * j3 + 4),
                                  ru32(kbd + 8 * j3)))
                end
            end
            emit(DIM, HP .. "efficiency", fix5(c + 448))
            emit(DIM, HP .. "sunk_convoys", fix5(c + 456)) -- AE590=fixed5
            emit(DIM, HP .. "days", tostring(ru32(c + 464) or 0))
            -- 合同级 days (写在 delivery_route_handler 块之后)
            emit(DIM, P .. "days", tostring(ru32(c + 616) or 0))
            -- contract_delivery_state (c+472 子对象; 三定点恒写)
            local SP = P .. "contract_delivery_state."
            emit(DIM, SP .. "factory_cic_progress", fix5(c + 480))
            emit(DIM, SP .. "equipment_transfer_progress", fix5(c + 488))
            emit(DIM, SP .. "collected", fix5(c + 496))
            -- contract_meta (c+528 起; 存档序 history→completed→convoys→cic→eff)
            local MP = P .. "contract_meta."
            emit(DIM, MP .. "history.factory_cic_progress", fix5(c + 560))
            emit(DIM, MP .. "history.equipment_transfer_progress",
                fix5(c + 568))
            emit(DIM, MP .. "history.collected", fix5(c + 576))
            emit(DIM, MP .. "completed", tostring(ru32(c + 604) or 0))
            emit(DIM, MP .. "convoys", fix5(c + 536)) -- 0x3062 走 AE590=fixed5
            emit(DIM, MP .. "cic", fix5(c + 528))
            emit(DIM, MP .. "efficiency_due_to_lost_convoys", fix5(c + 544))
            -- variables (内嵌 CVariables @c+752; 空 → 不写)
            emit_vars(P .. "variables.", c + 752)
        end
    end

    -- ===== requests (国家槽数组 @mkt+96; 槽 = 国数+1, idx0 哨兵) =====
    -- 结构/走查唯一实现 = reader (O:equipment_market, §4.23.3); 本段只按
    -- 写序发射 + 复刻"有槽块时裸总数被提取器吞掉"的编号规则。
    -- 槽 i ↔ 国 i-1 (idx0 哨兵), index 直写槽序号 i; 仅全空槽时回落
    -- requests.#1 = 总数。
    local mk_r = O:equipment_market()
    if mk_r then
        if #mk_r.requests > 0 then
            for n, slot in ipairs(mk_r.requests) do
                local BP = "requests.#" .. n .. "."
                emit(DIM, BP .. "index", tostring(slot.index))
                for j, req in ipairs(slot.list) do
                    local EP = BP .. "data.#" .. j .. "."
                    SL.def_emit(O, emit, DIM, EP .. "contract_definition.",
                                req.def_addr)
                    emit(DIM, EP .. "id",
                        SL.idpair(req.id_id, req.id_type))
                end
            end
        elseif mk_r.request_slots then
            emit(DIM, "requests.#1", tostring(mk_r.request_slots))
        end
    end
end }
