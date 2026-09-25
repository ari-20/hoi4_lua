-- sv2_sec_combat_log.lua -- combat_log 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Runtime:combat_log_managers,
-- objects_military §14.5); 本段只持 writer 发射规则 (写序/块门/编号)。
-- ⚠ 嵌套契约 (形状直方图定案): 子条目内 writer 先写池块 "equipment"
-- (裸), 其下编号条目 equipment[K] → id/amount; allow_zero_entries 是
-- 池块子叶。即 <pfx>.equipment.equipment[K].id, 不是
-- <pfx>.equipment[K].equipment.id。

SV2.gsec[#SV2.gsec + 1] = { name = "combat_log", emit = function(ctx)
    local SL, emit = SV2.lib, ctx.emit
    if not (ctx.gs and ctx.BASE) then return end
    local ok, mgrs = pcall(function() return ctx.O:combat_log_managers() end)
    if not ok or not mgrs then return end

    local function qtag(tid)
        if not (tid and tid > 0) then return nil end
        local s = ctx.O:tag(tid)
        return s and ('"' .. s .. '"') or nil
    end
    local function qdate(h)
        local d = SL.date(h)
        return d and ('"' .. d .. '"') or nil
    end

    -- CLoss 子条目发射 (pool 块裸前缀 + reason + date)
    local function emit_loss(dim, pfx, loss)
        local pp = pfx .. ".equipment"
        local seq = SL.seqc()
        for _, ev in ipairs(loss.pool and loss.pool.list or {}) do
            local k = seq("equipment")
            emit(dim, pp .. "." .. k .. ".id", SL.idpair(ev.id, ev.type))
            emit(dim, pp .. "." .. k .. ".amount",
                SL.num(ev.amount / 100000))
        end
        emit(dim, pp .. ".allow_zero_entries",
            SL.yn(loss.pool and loss.pool.allow_zero or 0))
        emit(dim, pfx .. ".reason", tostring(loss.reason or 0))
        local ds = qdate(loss.date_h)
        if ds then emit(dim, pfx .. ".date", ds) end
    end

    local dimseq = SL.seqc()
    for _, mgr in ipairs(mgrs) do
        if (mgr.log_count or 0) > 0 then     -- 块写门: 空日志不写整块
            local dim = dimseq("combat_log")
            local s = qtag(mgr.tag_tid)
            if s then emit(dim, "tag", s) end
            local logseq = SL.seqc()
            for _, le in ipairs(mgr.logs) do
                local pfx = logseq("log")
                emit(dim, pfx .. ".group",
                    SL.idpair(le.group_id, le.group_type))
                -- equipment ×4 容器合并序 (reader 已按序串好)
                local eqseq = SL.seqc()
                for _, loss in ipairs(le.equipment) do
                    emit_loss(dim, pfx .. "." .. eqseq("equipment"), loss)
                end
                -- enemy_equipment / equipment_recovered (各独立编号)
                for _, key in ipairs({ "enemy_equipment",
                                       "equipment_recovered" }) do
                    local sseq = SL.seqc()
                    for _, loss in ipairs(le[key]) do
                        emit_loss(dim, pfx .. "." .. sseq(key), loss)
                    end
                end
                -- manpower 子条目
                local mseq = SL.seqc()
                for _, mp in ipairs(le.manpower) do
                    local k = mseq("manpower")
                    emit(dim, pfx .. "." .. k .. ".reason",
                        tostring(mp.reason or 0))
                    local ds = qdate(mp.date_h)
                    if ds then emit(dim, pfx .. "." .. k .. ".date", ds) end
                    emit(dim, pfx .. "." .. k .. ".mp_losses.#1",
                        string.format("%d %d %d", mp.losses[1],
                            mp.losses[2], mp.losses[3]))
                end
                -- CPerTemplateStats division_template 子条目
                local tseq = SL.seqc()
                for _, dt in ipairs(le.division_template) do
                    local k = tseq("division_template")
                    emit(dim, pfx .. "." .. k .. ".division",
                        SL.idpair(dt.id_id, dt.id_type))
                    local ds = qdate(dt.date_h)
                    if ds then
                        emit(dim, pfx .. "." .. k .. ".date", ds)
                    end
                    emit(dim, pfx .. "." .. k .. ".win", tostring(dt.win))
                    emit(dim, pfx .. "." .. k .. ".total", tostring(dt.total))
                end
                -- combat_data_index (id 已由 reader 转带符号)
                local iseq = SL.seqc()
                for _, ci in ipairs(le.combat_data_index) do
                    local k = iseq("combat_data_index")
                    emit(dim, pfx .. "." .. k .. ".id", tostring(ci.id))
                    emit(dim, pfx .. "." .. k .. ".attacker",
                        SL.yn(ci.attacker))
                end
            end
        end
    end
end }
