-- 容器原语纯 Lua 单测: 假内存模型 (不碰游戏)
local MEM = {}            -- addr -> byte value
local function rd(a, n)
  local v = 0
  for i = n-1, 0, -1 do v = v * 256 + (MEM[a+i] or 0) end
  return v
end
local function wr(a, n, v)
  for i = 0, n-1 do MEM[a+i] = v % 256; v = (v - v % 256) // 256 end
end
local NEXT = 0x100000
local function alloc(sz) local a = NEXT; NEXT = NEXT + sz + 16; return a end

hoi4 = {
  base = function() return 0x140000000 end,
  read_u8  = function(a) return MEM[a] or 0 end,
  read_u16 = function(a) return rd(a,2) end,
  read_u32 = function(a) return rd(a,4) end,
  read_u64 = function(a) return rd(a,8) end,
}
GAME = {}
-- 定位被测文件 (不依赖脚本自身路径: 依次试几个已知位置)
local L
for _, p in ipairs({
    "mods/lua_verify/lua/hoi4_layout.lua",
    "../mods/lua_verify/lua/hoi4_layout.lua",
    "D:/documents/workspace/hoi4_lua/mods/lua_verify/lua/hoi4_layout.lua",
}) do
    local f = io.open(p, "r")
    if f then f:close(); L = dofile(p); break end
end
assert(L, "cannot locate hoi4_layout.lua")

local pass, fail = 0, 0
local function ok(cond, msg)
  if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: "..msg) end
end

-- ---------- 1. vector 基本 ----------
local v = alloc(64)
local arr = alloc(64)
wr(v+8, 8, arr); wr(v+20, 4, 3)          -- data@+8, count@+20 (delta 12)
local seen = {}
for i, e in L.vec(v, 8, 8) do seen[#seen+1] = e end
ok(#seen == 3, "vec 收 3 元素, 实得 "..#seen)
ok(seen[1] == arr and seen[3] == arr + 16, "vec 元素地址 = data + stride*i")

-- ---------- 2. vector + vtable 过滤 ----------
local VT = 0x2999050
local p1, p2 = alloc(32), alloc(32)
wr(arr+0, 8, 0x140000000 + VT)           -- 元素0 命中
wr(arr+8, 8, 0x140000000 + 0x1234)       -- 元素1 不命中
wr(arr+16, 8, 0x140000000 + VT)          -- 元素2 命中
local hit = {}
for _, e in L.vec(v, 8, 8, { deref = true, vt = VT }) do hit[#hit+1] = e end
ok(#hit == 2, "vt 过滤后 2 命中, 实得 "..#hit)

-- ---------- 3. 计数上界 ----------
wr(v+20, 4, 999999)
local cnt = select(2, L.vec(v, 8, 8))
ok(cnt == 0, "超上界 → 空迭代器 (count 回 0), 实得 "..tostring(cnt))
wr(v+20, 4, 3)

-- ---------- 4. 空迭代器可安全 for-in ----------
wr(v+8, 8, 0)                            -- data 置空
local n = 0
for _ in L.vec(v, 8, 8) do n = n + 1 end
ok(n == 0, "空迭代器 for-in 不抛错且零元素")

-- ---------- 5. vec_alt (delta-8 变体) ----------
local v2 = alloc(64); local arr2 = alloc(32)
wr(v2+8, 8, arr2); wr(v2+16, 4, 2)       -- count 在 doff(8)+delta(8) = +16
local c2 = select(2, L.vec(v2, 8, 8, { shape = "vec_alt" }))
ok(c2 == 2, "vec_alt 计数取自 +8, 实得 "..tostring(c2))

-- ---------- 6. robin-hood ----------
local ht = alloc(64); local bk = alloc(24*8)
wr(ht+8, 8, bk); wr(ht+20, 4, 7)         -- data@+8, mask=7 → 8 桶
wr(ht+24, 1, 1)                          -- extra=1 → 9 桶
wr(bk+0*24+4, 4, 0)                      -- 空槽
wr(bk+3*24+4, 4, 2)                      -- 占位
wr(bk+7*24+4, 4, 1)                      -- 占位
wr(bk+8*24+4, 4, 1)                      -- extra 尾部占位 (mask 之外)
local rh = {}
for _, e in L.rh(ht, 24) do rh[#rh+1] = e end
ok(#rh == 3, "rh 收 3 占位桶 (含 extra 尾部), 实得 "..#rh)

-- ---------- 7. 红黑树中序 ----------
-- 哨兵节点
local NIL = alloc(32); wr(NIL+25, 1, 1)
-- 节点: key@+0x20
local n10, n20, n30 = alloc(64), alloc(64), alloc(64)
local function mknode(n, key, left, right, parent)
  wr(n+0x20, 4, key); wr(n, 8, left); wr(n+16, 8, right); wr(n+8, 8, parent)
  wr(n+25, 1, 0)
end
mknode(n20, 20, n10, n30, NIL)
mknode(n10, 10, NIL, NIL, n20)
mknode(n30, 30, NIL, NIL, n20)
local head = alloc(16); wr(head, 8, n20)
local order = {}
for _, nd in L.rb(head) do order[#order+1] = rd(nd+0x20, 4) end
ok(#order == 3 and order[1]==10 and order[2]==20 and order[3]==30,
   "rb 中序 = 10,20,30 实得 "..table.concat(order, ","))

-- ---------- 8. 链表 ----------
local l1, l2, l3 = alloc(32), alloc(32), alloc(32)
wr(l1, 8, l2); wr(l2, 8, l3); wr(l3, 8, 0)
local ln = 0
for _, nd in L.list(l1) do ln = ln + 1 end
ok(ln == 3, "list 收 3 节点, 实得 "..ln)

-- ---------- 9. gather 空迭代器 ----------
ok(#L.gather((L.vec(0, 8, 8))) == 0, "gather(空) = 空表")

-- ---------- 10. rev_index 缓存与失效 ----------
local builds = 0
local stamp = "A"
local rev = L.rev_index(function() return stamp end,
                        function() builds = builds + 1; return {x=builds} end)
rev(); rev(); rev()
ok(builds == 1, "同戳只建一次, 实得 "..builds)
stamp = "B"
rev()
ok(builds == 2, "换戳重建, 实得 "..builds)

-- ---------- 11. state_index_map (唯一实现) ----------
local g = alloc(0x1000)
local stbl = alloc(8*8)
wr(g+0x2C8, 8, stbl); wr(g+0x2D4, 4, 3)
local s1, s2, s3 = alloc(16), alloc(16), alloc(16)
wr(stbl+8*1, 8, s1); wr(stbl+8*2, 8, s2); wr(stbl+8*3, 8, s3)
wr(stbl+8*4, 8, 0)                       -- 哨兵终止
local m = L.state_index_map(g)
ok(m[s1]==1 and m[s2]==2 and m[s3]==3, "state_index_map 映射正确")
ok(L.state_index_map(g) == m, "同代际复用同表 (缓存命中)")

print(string.format("\n%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
