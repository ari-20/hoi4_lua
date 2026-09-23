-- example_autohunt.lua -- example mod 桥接功能 (DLL 动态发现各启用 mod 的 lua/*.lua)
-- 自动占地猎手: 每 5s (墙钟, hoi4.every 实时基) 扫描玩家国陆军师,
-- 相邻敌方空格子 → 空闲师发 CMoveCommand 占领。决议双档开关:
--   EXAMPLE_AUTOHUNT_ON      标准档: 源格子 ≥2 个己方师 (留 1 占坑) 才发
--   EXAMPLE_AUTOHUNT_BERSERK 激进档: 无视源格子师数, 见敌方空格就发
-- 判定链 (全部书内定案, 1.19.3):
--   玩家国 tag = gs+1312 (0 则 gs+1316 观察国); 国家数组 {gs+0x310, gs+0x31C}
--   敌国集 = dip+152 交战国 tag 缓存 (is_enemy 谓词同源)
--   师容器 = {cc+656, cc+668}; 位置 = *(div+496)+164; 空 = 无路径(path c@524 /
--   full_path c@556) 且无战斗(combats c@436) 且未挂军群令(*(div+192)=0)
--   目标格 = 邻省(desc+112 邻接表, 48B 条 id@+8) ∧ 控制者(prov+392)∈敌集
--            ∧ 无任何在场单位(prov+236) ∧ 无己方师终点在途
--   发令 = CMoveCommand (vt 0x29B1BC8, 136B 薄壳; +40 内嵌 CUnitMoveAction
--          vt 0x29A3A38 — Execute 桩经 cmd+40 action 虚表转发, 必填两张虚表)
local log = function(msg) print("[example] " .. tostring(msg)) end
local rp, ru32 = hoi4.read_u64, hoi4.read_u32
local wu32, wu64 = hoi4.write_u32, hoi4.write_u64

-- 引擎定址 (1.19.3.0 rev c01a3d50) — ⚠ ASLR: 一律 base+RVA!
local B = hoi4.base()
local GS_SLOT      = 0x332F260   -- 全局 gs 槽
local MOVE_VFT     = 0x29B1BC8   -- CMoveCommand vtable
local ACTION_VFT   = 0x29A3A38   -- CUnitMoveAction vtable (+40 内嵌)
local MOVE_ISVALID = 0x1369CB0   -- CMoveCommand vt[9] (转 action vt[10] dry-run)
local MOVE_EXEC    = 0x13669E0   -- CMoveCommand vt[10] (转 action vt[9], this=cmd+40)
local VEC_SENTINEL = 0x3085170   -- off_143085170 引擎空 vector allocator 哨兵
local ARMY_VT0     = 0x295A2B0   -- CArmy vt0 (师容器元素双校验)
local ARMY_VT1     = 0x295A490   -- CArmy vt1

local TICK_MS       = 5000   -- 用户语义: 每 5 秒检查+进攻一轮
local MAX_PER_TICK  = 8      -- 单轮发令上限 (轻 chunk 纪律)
local MAX_GROUPS    = 200    -- 单轮最多考察的源格子数
local MAX_NEIGHBORS = 64     -- 单省邻接考察上限 (断言界 255, 实际 <16)

AUTOHUNT_STATE = { mode = "off", divisions = 0, idle = 0, issued = 0 }

-- ---------------------------------------------------------------- 小工具
local function flag_on(store, tok)
    local d = rp(store + 8)
    local cnt = ru32(store + 0x14) or 0
    if not d or cnt == 0 or cnt > 100000 then return false end
    for i = 0, cnt - 1 do
        local e = d + 48 * i
        if ru32(e + 8) == tok then
            local v = ru32(e + 40) or 0
            return (v % 65536) ~= 0
        end
    end
    return false
end

-- 纯陆军 move 令打不可步行邻接 (跨海峡/海岛) 目标, IsValid 内 mil-access
-- pathing 评估会空指针 (实测 0xc0000005, call_u64 SEH 兜住返回 nil),
-- 双层防御: ① CMap+16 海峡规则表 {from,to,through} 12B 条 → 屏蔽集
-- (CMap 靠 gs 槽扫描启发定位, 不在 gs 前 4KB 时留空集); ② 发令失败
-- (fault=nil / invalid=0) 的 (源省>目标省) 对进黑名单, 会话内不再尝试。
local strait = {}
local bl = {}
local bl_keys = {}
local strait_scanned = false
local function bl_key(a, b) return a * 4194304 + b end  -- 省 id < 2^22
local function scan_cmap()
    local gs = rp(B + GS_SLOT)
    if not gs or gs == 0 then return end
    local pcount = ru32(gs + 0x2BC) or 0
    if pcount == 0 or pcount > 200000 then return end
    for off = 0, 4088, 8 do
        local m = rp(gs + off)
        if m and m > 0x10000 then
            if ru32(m + 560) == pcount and (ru32(m + 564) or 0) <= pcount then
                local d = rp(m + 16)
                local c = ru32(m + 28) or 0
                if d and d ~= 0 and c > 0 and c < 65536 then
                    for i = 0, c - 1 do
                        local e = d + 12 * i
                        local a, b = ru32(e) or 0, ru32(e + 4) or 0
                        strait[bl_key(a, b)] = true; strait[bl_key(b, a)] = true
                    end
                    log("autohunt: strait table " .. c .. " rules (CMap=gs+" .. off .. ")")
                    return
                end
            end
        end
    end
    log("autohunt: CMap not found, strait pre-filter off (blacklist only)")
end

local function player_cc()
    local gs = rp(B + GS_SLOT)
    if not gs or gs == 0 then return nil end
    local ptag = ru32(gs + 1312) or 0          -- 当前国 tag, 0 则观察国
    if ptag == 0 then ptag = ru32(gs + 1316) or 0 end
    if ptag == 0 then return nil end
    local carr = rp(gs + 0x310)
    local cn = ru32(gs + 0x31C) or 0
    if not carr or carr == 0 or cn == 0 or cn > 10000 then return nil end
    for i = 0, cn - 1 do
        local cc = rp(carr + 8 * i)
        if cc and cc ~= 0 and (ru32(cc + 8) or 0) == ptag then return cc, ptag end
    end
    return nil
end

local function enemy_set(cc)
    local dip = rp(cc + 3976)
    if not dip or dip == 0 then return nil end
    local d = rp(dip + 152)
    local cnt = ru32(dip + 164) or 0
    if not d or d == 0 or cnt == 0 or cnt > 512 then return nil end
    local s = {}
    for i = 0, cnt - 1 do s[ru32(d + 4 * i) or 0] = true end
    return s
end

-- 师在途终点 (无 = 站定); path/full_path 尾元素 = 省 id
local function div_final_dest(div)
    local fpc = ru32(div + 556) or 0
    if fpc > 0 and fpc <= 1000 then
        local d = rp(div + 544)
        if d and d ~= 0 then return ru32(d + 4 * (fpc - 1)) end
        return nil
    end
    local pc = ru32(div + 524) or 0
    if pc > 0 and pc <= 1000 then
        local d = rp(div + 512)
        if d and d ~= 0 then return ru32(d + 4 * (pc - 1)) end
    end
    return nil
end

-- 空闲 = 没在移动 (无路径) ∧ 没在战斗 ∧ 非外派远征师。
-- ⚠ 不看 +192 军群回指: 正规军师几乎全挂军群, 挂军群 ≠ 有移动/战斗令。
local function div_idle(div)
    if div_final_dest(div) then return false end
    if (ru32(div + 436) or 0) ~= 0 then return false end        -- combats count
    if (ru32(div + 476) or 0) ~= 0 then return false end        -- expeditionary_owner
    return true
end

-- CMoveCommand 构造 + IsValid 门 + Execute (同步消费, 用后即释)
local function issue_move(div, target_prov)
    local cmd = hoi4.engine_alloc(0x88)
    if not cmd then return false end
    local buf = hoi4.engine_alloc(8)
    if not buf then hoi4.engine_free(cmd) return false end
    for z = 0, 0x80, 8 do wu64(cmd + z, 0) end
    wu64(cmd, B + MOVE_VFT)
    wu32(cmd + 12, 0xFFFFFFFF); wu32(cmd + 20, 0xFFFF0000)
    wu64(cmd + 40, B + ACTION_VFT)          -- Execute 桩经此虚表转发, 必填
    wu32(cmd + 48, 13896)                   -- action token (ctor 值)
    wu32(cmd + 56, ru32(div + 24) or 0)     -- unit idpair.type
    wu32(cmd + 60, ru32(div + 28) or 0)     -- unit idpair.id
    wu32(buf, target_prov)
    wu64(cmd + 64, buf)                     -- 目的省数组 data (u32 元)
    wu64(cmd + 72, 1)                       -- cap (顺带清 count, 先写)
    wu32(cmd + 76, 1)                       -- count = 1
    wu64(cmd + 80, B + VEC_SENTINEL)        -- 目的省 vector alloc 哨兵
    wu64(cmd + 104, B + VEC_SENTINEL)       -- 显式路径 vector alloc 哨兵 (空)
    wu32(cmd + 128, 1)                      -- move_priority = ctor 缺省 1
    local sent = false
    local v = hoi4.call_u64(B + MOVE_ISVALID, cmd)
    if v and (v % 256) ~= 0 then
        hoi4.call_void(B + MOVE_EXEC, cmd)
        sent = true
    end
    hoi4.engine_free(buf)
    hoi4.engine_free(cmd)
    return sent
end

-- ---------------------------------------------------------------- 主循环
-- 空闲师的驻扎省必须是陆省 (海上运输中的师 +496 落海区); 目标省同样;
-- 每轮起点先建一次海峡屏蔽集 (幂等)
local function prov_is_land(pid, parr)
    local pv = rp(parr + 8 * pid)
    local desc = (pv and pv ~= 0) and rp(pv + 184) or nil
    if not desc or desc == 0 then return false end
    return (ru32(desc + 210) or 0) % 2 == 1
end
local function autohunt_body(berserk)
    local cc = player_cc()
    if not cc then AUTOHUNT_STATE.mode = "no-player" return end
    local gs = rp(B + GS_SLOT)
    local parr = rp(gs + 0x2B0)             -- 省指针数组 (id 直下标)
    local pcount = ru32(gs + 0x2BC) or 0    -- 省表界 = max 省 id + 1
    local enemies = enemy_set(cc)
    if not parr or pcount == 0 or pcount > 200000 then
        AUTOHUNT_STATE.mode = "no-map"
        return
    end
    if not enemies then
        AUTOHUNT_STATE.mode = (berserk and "berserk" or "on") .. ":no-war"
        return
    end
    local darr = rp(cc + 656)
    local dcnt = ru32(cc + 668) or 0
    if not darr or dcnt == 0 or dcnt > 2000 then
        AUTOHUNT_STATE.mode = berserk and "berserk" or "on"
        AUTOHUNT_STATE.divisions = 0
        return
    end
    -- 1. 分组: 己方师按所在省聚合; 在途终点登记 (占坑判定)
    local groups, inbound = {}, {}
    local idle_total = 0
    for i = 0, dcnt - 1 do
        local d = rp(darr + 8 * i)
        if d and d ~= 0 and rp(d) == B + ARMY_VT0 and rp(d + 16) == B + ARMY_VT1 then
            local loc = rp(d + 496)
            local pid = (loc and loc ~= 0) and ru32(loc + 164) or nil
            if pid and pid > 0 and pid < pcount then
                local fin = div_final_dest(d)
                if fin then inbound[fin] = true end
                local g = groups[pid]
                if not g then g = { total = 0, idle = {} } groups[pid] = g end
                g.total = g.total + 1
                if not fin and div_idle(d) then
                    g.idle[#g.idle + 1] = d
                    idle_total = idle_total + 1
                end
            end
        end
    end
    AUTOHUNT_STATE.divisions = dcnt
    AUTOHUNT_STATE.idle = idle_total
    AUTOHUNT_STATE.mode = berserk and "berserk" or "on"
    -- 2. 逐源格子找相邻敌方空格发令
    local min_total = berserk and 1 or 2     -- 标准档: >1 个师 (留 1 占坑)
    local issued, scanned = 0, 0
    for pid, g in pairs(groups) do
        if issued >= MAX_PER_TICK or scanned >= MAX_GROUPS then break end
        scanned = scanned + 1
        if g.total >= min_total and #g.idle >= 1 and prov_is_land(pid, parr) then
            local pv = rp(parr + 8 * pid)
            local desc = (pv and pv ~= 0) and rp(pv + 184) or nil
            local adata = (desc and desc ~= 0) and rp(desc + 112) or nil
            local acnt = (desc and desc ~= 0) and (ru32(desc + 124) or 0) or 0
            if adata and adata ~= 0 and acnt > 0 then
                if acnt > MAX_NEIGHBORS then acnt = MAX_NEIGHBORS end
                for k = 0, acnt - 1 do
                    local np = ru32(adata + 48 * k + 8) or 0
                    local sk = (np > 0 and np < pcount) and bl_key(pid, np) or 0
                    if np > 0 and np < pcount and not inbound[np]
                        and not strait[sk] and not bl[sk]
                        and prov_is_land(np, parr) then
                        local npv = rp(parr + 8 * np)
                        if npv and npv ~= 0 then
                            local ctl = ru32(npv + 392) or 0
                            -- 空格 = 陆军 (type==0) 在场数为 0 — 不能数全省
                            -- 单位 (+236): 港口停泊的敌舰队 (CTaskForce,
                            -- t105 实测 12364) 会被误当守军挡住空格
                            local occ = ru32(npv + 284) or 0
                            if ctl > 0 and enemies[ctl] and occ == 0 then
                                local div = g.idle[1]
                                if issue_move(div, np) then
                                    inbound[np] = true   -- 本轮防重复指派
                                    issued = issued + 1
                                    log("autohunt: div#" .. tostring(ru32(div + 28)) ..
                                        " -> prov " .. np ..
                                        " (ctl tag " .. ctl .. ", " ..
                                        (berserk and "berserk" or "normal") .. ")")
                                else
                                    -- fault (nil) 或 invalid (0): 本会话不再试这对
                                    if #bl_keys < 4096 then
                                        bl[sk] = true; bl_keys[#bl_keys + 1] = sk
                                    end
                                end
                                break          -- 每源格子每轮只发一令
                            end
                        end
                    end
                    if issued >= MAX_PER_TICK then break end
                end
            end
        end
    end
    AUTOHUNT_STATE.issued = issued
end

local function autohunt_tick()
    local gs = rp(B + GS_SLOT)
    if not gs or gs == 0 then AUTOHUNT_STATE.mode = "off" return end
    local store = rp(gs + 0x258)
    if not store or store == 0 then return end
    local berserk = flag_on(store, hoi4.name_to_token("EXAMPLE_AUTOHUNT_BERSERK"))
    local on = berserk or flag_on(store, hoi4.name_to_token("EXAMPLE_AUTOHUNT_ON"))
    if not on then AUTOHUNT_STATE.mode = "off" return end
    if not strait_scanned then strait_scanned = true scan_cmap() end
    autohunt_body(berserk)
end

-- 只读探针: 无头/HTTP 验证用 (回模式 + 最近一轮统计; print 在 GUI 进程
-- 无 stdout, 桥日志只见 DLL 侧行, 状态一律走本探针)
hoi4.effect("example_autohunt_status", function(n, self, ctx)
    local s = AUTOHUNT_STATE
    local nbl = 0 for _ in pairs(bl) do nbl = nbl + 1 end
    local nst = 0 for _ in pairs(strait) do nst = nst + 1 end
    return "mode=" .. tostring(s.mode) .. " divisions=" .. tostring(s.divisions) ..
        " idle=" .. tostring(s.idle) .. " last_issued=" .. tostring(s.issued) ..
        " straits=" .. (nst / 2) .. " blacklisted=" .. nbl
end)

-- 5s 实时定时器 (帧顶主线程派发, 菜单/加载不触发; 会话切换 C 侧清表后
-- re-dofile 重挂)。_G 守卫防重复挂: 先取消旧 id 再挂新。
if rawget(_G, "EXAMPLE_AUTOHUNT_TIMER") then
    pcall(hoi4.every_cancel, rawget(_G, "EXAMPLE_AUTOHUNT_TIMER"))
end
local okid, tid = pcall(hoi4.every, TICK_MS, function()
    local ok, err = pcall(autohunt_tick)
    if not ok then log("ERR " .. tostring(err)) end
end, "example_autohunt")
if okid then _G.EXAMPLE_AUTOHUNT_TIMER = tid end
log("example_autohunt: timer armed (" .. (okid and tostring(tid) or "FAIL") ..
    ", " .. TICK_MS .. "ms) + status probe registered")
