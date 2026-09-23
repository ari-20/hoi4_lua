-- clear_peace.lua — 和平会议模态自动清理 (分类清模态之一)
--
-- ⚠ 安全纪律: 只调用**已活体验证**的地址 —
--   · CDonePeaceConferenceCommand (13830) 虚表 0x2A84508 / IsValid 槽
--     0x1E53C10 / Execute 槽 0x1E53B70 (sizeof 48, 载荷 +40 谈判国 tag)
--   · 阶段推进 sub_140E50BB0(conf, 0) — 实测 stage 递增且无异常
--   绝不调用未定案签名/参数的地址 (曾盲调 0x141041BB0 致游戏崩溃)。
--
-- 单次动作语义 (一个 POST = 帧顶一次动作; 帧推进交给 bash 循环):
--   ① 对 OutWinners 每个 tag 下发 CDone (completed 置 1);
--   ② 推进一档阶段; ③ 解暂停让引擎自行终局; ④ 报告现态。
-- bash 侧循环 POST + sleep 复查 active_peace, 归零即 cleared。
local B = hoi4.base()
local gs = hoi4.read_u64(B + 0x332F260)
if not gs or gs < 0x10000 then return "no gamestate" end

local VT_CMD, SLOT_ISVALID, SLOT_EXECUTE, SIZEOF = 0x2A84508, 0x1E53C10, 0x1E53B70, 48
local ADVANCE = 0xE50BB0

local tt = hoi4.read_u64(gs + 0x358)
local function tagname(t)
    if not t or t == 0 then return "?" end
    return tostring(hoi4.read_cstr(tt + 32 * t) or ("i" .. t))
end

local pcm = gs + 1248
if (hoi4.read_u64(pcm) or 0) ~= B + 0x2720E48 then
    return "not a peace conference manager (vtable mismatch)"
end
local out = {}

local function send_cdone(tag)
    local p = hoi4.engine_alloc(SIZEOF)
    if not p then return -1 end
    for i = 0, SIZEOF - 1, 8 do hoi4.write_u64(p + i, 0) end
    hoi4.write_u64(p, B + VT_CMD)
    hoi4.write_u32(p + 12, 0xFFFFFFFF)
    hoi4.write_u16(p + 20, 0xFFFF)
    hoi4.write_u16(p + 22, 0xFFFF)
    hoi4.write_u32(p + 40, tag)
    local ok = (hoi4.call_u64(B + SLOT_ISVALID, p) or 0) % 256
    if ok ~= 0 then hoi4.call_void(B + SLOT_EXECUTE, p) end
    hoi4.engine_free(p)
    return ok
end

local ap, n = hoi4.read_u64(pcm + 8), hoi4.read_u32(pcm + 20) or 0
if n == 0 then
    out[#out + 1] = "active_peace=0"
    out[#out + 1] = "verdict: no_conference"
    return table.concat(out, "\n")
end
local conf = hoi4.read_u64(ap)
if not conf or conf < 0x10000 then
    out[#out + 1] = "conf 指针无效"
    out[#out + 1] = "verdict: needs_manual"
    return table.concat(out, "\n")
end
out[#out + 1] = string.format("before: n=%d stage=%d completed=%d negotiator=%d",
    n, hoi4.read_u32(conf + 216) or -1, hoi4.read_u8(conf + 221) or -1,
    hoi4.read_u32(conf + 520) or -1)

local d, c = hoi4.read_u64(conf + 96), hoi4.read_u32(conf + 108) or 0
local tags = {}
if d and d > 0x10000 and c > 0 and c <= 64 then
    for i = 0, c - 1 do
        local tv = hoi4.read_u32(d + 4 * i)
        if tv and tv > 0 then tags[#tags + 1] = tv end
    end
end
if #tags == 0 then
    out[#out + 1] = "OutWinners 空 — 无法定位谈判方"
    out[#out + 1] = "verdict: needs_manual"
    return table.concat(out, "\n")
end
local names = {}
for _, tv in ipairs(tags) do
    names[#names + 1] = string.format("%s:%d", tagname(tv), send_cdone(tv))
end
out[#out + 1] = "CDone: " .. table.concat(names, " ")

hoi4.call_void(B + ADVANCE, conf, 0)
hoi4.game_pause(0)
out[#out + 1] = string.format("after: n=%d stage=%d completed=%d (已解暂停)",
    hoi4.read_u32(pcm + 20) or -1, hoi4.read_u32(conf + 216) or -1,
    hoi4.read_u8(conf + 221) or -1)
out[#out + 1] = "verdict: acted"
return table.concat(out, "\n")
