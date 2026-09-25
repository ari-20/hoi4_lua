-- sv2_sec_c_history.lua -- country.history 节点 savefull 直出
-- 结构/走查唯一实现 = reader (Country:history_queues, objects_global §33.1b);
-- 本段只持 writer 发射规则 (恒写三叶 + data.#1 单行折叠)。

SV2.csec[#SV2.csec + 1] = { name = "country.history", emit = function(ctx)
    local SL, emit, tag, c = SV2.lib, ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local ok, hq = pcall(function() return c:history_queues() end)
    if not ok or not hq then return end
    for _, q in ipairs(hq.queues or {}) do
        -- ⚠ index 原下标 (无效队列留路径空洞, 原样保留)
        local b = "history.history_queue." .. q.index
        emit(tag, b .. ".max_elements", SL.num(q.max_elements or 0))
        emit(tag, b .. ".offset", SL.num(q.offset or 0))
        emit(tag, b .. ".is_full", SL.yn(q.is_full or 0))
        if q.cells then
            local vals = {}
            for i, v in ipairs(q.cells) do
                vals[i] = SL.num(v / 100000)
            end
            emit(tag, b .. ".data.#1", table.concat(vals, " "))
        end
    end
end }
