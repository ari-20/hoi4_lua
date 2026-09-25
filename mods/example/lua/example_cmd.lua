-- example_cmd.lua -- example mod 私有命令发射库 (DLL 动态发现各启用 mod 的 lua/*.lua)
-- 引擎命令的统一外部驱动配方: 构造(alloc+清零+虚表+基座基线) → 填载荷 →
-- IsValid 门 (vt[9]) → Execute (vt[10]) → engine_free。配方与定案出处 =
-- 书 §4.33.18「外部驱动重点命令详卡」外部构造配方段; 基座布局 = §4.00.7;
-- 各命令逐类判读 = §4.33.9 / §4.33.14 / §4.33.15 对应行。
-- 挂 _G.EXAMPLE_CMD: 本文件字母序晚于 example_autohunt/autopilot 加载,
-- 使用侧一律运行期 rawget 惰性取用 (同 GAME.layout 纪律), 顶层不得捕获。
-- ⚠ ASLR: R 表一律裸 RVA, 库内统一 B+ 化; 使用侧 payload 内引用引擎地址
-- (内嵌虚表/vector 哨兵) 同样裸 RVA + 自侧 B+。
local B = hoi4.base()
local wu32, wu64 = hoi4.write_u32, hoi4.write_u64

-- 命令配方表 (裸 RVA; size = 外部构造分配字节数, 取书详卡实测配方)
-- research: CSetResearchCommand (§4.33.9) — 空科研槽挂科技
--   isvalid = 界检 + sub_140ED8F00 可用性神谕; +60 XP 旗 0 = 短路放行
-- focus: CSetNationalFocusCommand (§4.33.14) — 启动国策
--   isvalid = focus def 虚槽[9] CanSelect (含 available 触发器)
-- build: CAddConstructionCommand (§4.33.9) — 营建入队
--   +48 内嵌 CBuildingReference {vt@+48, +56 州 id, +60 建筑 token, +64 国 tag}
-- move: CMoveCommand (§4.33.15) — 陆军移动薄壳转发
--   136B 薄壳, +40 内嵌 CUnitMoveAction (Execute/IsValid 桩经 cmd+40 虚表
--   转发, 构造必填两张虚表); vec_sentinel = off_143085170 空 vector allocator
local R = {
    research = { size = 0x48, vft = 0x2994F40, isvalid = 0x1166BC0, exec = 0x115D2E0 },
    focus    = { size = 0x48, vft = 0x2996458, isvalid = 0x1166830, exec = 0x115C670 },
    build    = { size = 0x50, vft = 0x2994770, isvalid = 0x11616F0, exec = 0x1150FB0,
                 ref_vft = 0x2971F30 },
    move     = { size = 0x88, vft = 0x29B1BC8, isvalid = 0x1369CB0, exec = 0x13669E0,
                 action_vft = 0x29A3A38, vec_sentinel = 0x3085170 },
}

local M = { R = R }

-- 构造: engine_alloc + 整块清零 (engine_alloc 不清零, tag_ref 带脏字节必炸)
-- + CCommand 虚表 + 基座基线 (§4.00.7): +12 发送方 player id = −1 (ctor 态,
-- 本地直调不经 post); +20 u16 暂存清零且 +22 tick 戳 = 0xFFFF (未投递标记)
function M.new(size, vft_rva)
    local cmd = hoi4.engine_alloc(size)
    if not cmd then return nil end
    for z = 0, size - 8, 8 do wu64(cmd + z, 0) end
    wu64(cmd, B + vft_rva)
    wu32(cmd + 12, 0xFFFFFFFF)
    wu32(cmd + 20, 0xFFFF0000)
    return cmd
end

-- IsValid 门 (vt[9]): 返回 bool 只置 AL (真 = mov al,1 / 假 = xor al,al,
-- RAX 高位是残渣) → 按引擎 test al,al 语义判低字节 (§4.33.18 配方)。
-- 返回 true / false / nil (nil = pathing 类深评估空指针, call_u64 SEH 兜住)
function M.valid(cmd, isvalid_rva)
    local v = hoi4.call_u64(B + isvalid_rva, cmd)
    if not v then return nil end
    return (v % 256) ~= 0
end

-- Execute (vt[10]): 本地直调, 同步消费 (Execute 返回后 cmd 即可复用/释放)
function M.exec(cmd, exec_rva)
    hoi4.call_void(B + exec_rva, cmd)
end

function M.free(cmd)
    if cmd then hoi4.engine_free(cmd) end
end

-- 单发糖: 构造 → fill(cmd) 填载荷 → IsValid 门 → 通过则 Execute → 释放。
-- 返回 "valid" (已执行) / "invalid" / "fault" (IsValid 空指针) / nil (alloc 失败)。
-- 多次发射 (一条 cmd 反复试 IsValid / 复发) 或两段式 (先筛后发) 不走此糖,
-- 用 new/valid/exec/free 自行编排。
function M.fire(size, vft, isvalid, exec, fill)
    local cmd = M.new(size, vft)
    if not cmd then return nil end
    if fill then fill(cmd) end
    local v = M.valid(cmd, isvalid)
    if v == nil then M.free(cmd) return "fault" end
    if v then M.exec(cmd, exec) end
    M.free(cmd)
    return v and "valid" or "invalid"
end

_G.EXAMPLE_CMD = M
return M
