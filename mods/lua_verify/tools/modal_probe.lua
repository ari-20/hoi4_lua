-- modal_probe.lua — 停滞现场模态判别 (卡住时 POST 一次即知类型)
-- 输出: pending_events 队列 / active_peace 计数 / 玩家国投降挂起旗 / 速度
local B = hoi4.base()
local gs = hoi4.read_u64(B + 0x332F260)
local out = {}
if not gs or gs < 0x10000 then return "no gamestate" end

-- (1) 事件弹窗: pending_events 队列 (gs+1376 容器, 56B 元素)
do
    local d, n = hoi4.read_u64(gs + 1376), hoi4.read_u32(gs + 1388) or 0
    out[#out + 1] = string.format("pending_events=%d", n)
    for i = 0, math.min(n, 8) - 1 do
        local e = d + 56 * i
        local pid = hoi4.read_u32(e) or 0
        local sc = hoi4.read_u64(e + 16) or 0
        local actor = 0
        if sc > 0x10000 then actor = hoi4.read_u32(sc + 8) or 0 end
        out[#out + 1] = string.format("  ev%d pending_id=%d scope=%X actor_tid=%d",
            i, pid, sc, actor)
    end
end

-- (2) 和会: gs+1248 CPeaceConferenceManager 内嵌, active_peace {d@+8, c@+20}
do
    local pcm = gs + 1248
    local vt = hoi4.read_u64(pcm) or 0
    local ap, apc = hoi4.read_u64(pcm + 8), hoi4.read_u32(pcm + 20) or 0
    out[#out + 1] = string.format("peace_mgr vt_ok=%s active_peace=%d data=%X",
        tostring(vt == B + 0x2720E48), apc, ap)
end

-- (3) 玩家国投降挂起旗 (cc+5208: 和会期间抑制投降)
do
    local cdata = hoi4.read_u64(gs + 0x310)
    local ptid = hoi4.read_u32(gs + 1312) or 0
    local cc = (cdata > 0x10000) and (hoi4.read_u64(cdata + 8 * ptid) or 0) or 0
    if cc > 0x10000 then
        out[#out + 1] = string.format("player tid=%d cc=%X surrender_hold(5208)=%d",
            ptid, cc, hoi4.read_u8(cc + 5208) or -1)
    end
end

-- (4) human_ai 旗 + 速度 (排除"未开 human_ai 导致事件无人应答")
out[#out + 1] = string.format("human_ai=%d ai_master=%d speed=%d",
    hoi4.read_u8(B + 0x332F639) or -1,
    hoi4.read_u8(B + 0x332F63C) or -1,
    hoi4.read_u32(gs + 1212) or -1)

return table.concat(out, "\n")
