-- probe_lib.lua — 探针通用辅助 (POST /lua 用; 幂等, 可重复加载)
-- 用法: local P = dofile("<任意路径>/probe_lib.lua")  P.tag(cc) / P.countries() / P.relations(cc) ...
-- ⚠ 关键口径: dip = *(cc+3976) / ps = *(cc+3984) — 相邻 8B 两对象, 勿混
local M = {}
-- objects_v2 加载路径自定位 (SELF_DIR 惯用法: 本文件住 <mod>/tools/,
-- 层住 <mod>/lua/; 裸 chunk 兜底 MOD_LUA_DIR = <mod>/lua, 仅兜底)
local OV_PATH = (function()
    local src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)[/\\][^/\\]*$")
    if dir then return dir .. "/../lua/objects_v2.lua" end
    return MOD_LUA_DIR .. "/objects_v2.lua"
end)()
local OV = dofile(OV_PATH)
M.ov = OV

function M.base() return hoi4.base() end
function M.gs() return hoi4.read_u64(hoi4.base() + 0x332F260) end
function M.u8(a) return hoi4.read_u8(a) end
function M.u16(a) return hoi4.read_u16(a) end
function M.u32(a) return hoi4.read_u32(a) end
function M.u64(a) return hoi4.read_u64(a) end
function M.rva(p) local b = hoi4.base(); if not p or p <= b then return 0 end return p - b end

-- tag 三字串 (经 objects_v2.Runtime 正规法; tag 是方法需传 self)
function M.tag(cc) return OV.tag(OV, hoi4.read_u32(cc+8) or 0) end
function M.tagOfTid(tid) return OV.tag(OV, tid) end

-- 国家索引 (1-based, 与 objects_v2 同)
function M.countries()
  local gs = M.gs()
  local arr, n = hoi4.read_u64(gs+784), hoi4.read_u32(gs+796)
  local out = {}
  for i = 1, math.min(n or 0, 500) do
    local cc = hoi4.read_u64(arr + 8*i)
    if cc and cc > 0x10000 then out[#out+1] = {i = i, cc = cc, tag = M.tag(cc)} end
  end
  return out
end

function M.ccByTag(tag)
  local want = tostring(tag)
  for _, c in ipairs(M.countries()) do
    if tostring(c.tag) == want then return c.cc end
  end
  return nil
end

-- 外交对象 (dip = cc+3976 CDiplomacyStatus / ps = cc+3984 CPolitics)
function M.dip(cc) return hoi4.read_u64(cc+3976) end
function M.ps(cc)  return hoi4.read_u64(cc+3984) end

-- rs (CRelationStatus) 表: dip+8 {data, count@20}, sizeof 0x9C0
function M.relations(cc)
  local d, n = M.dip(cc)
  if not (d and d > 0x10000) then return {} end
  local rd, rc = hoi4.read_u64(d+8), hoi4.read_u32(d+20)
  local out = {}
  if rd and rd > 0x10000 then
    for j = 0, math.min(rc or 0, 500) - 1 do
      local rs = hoi4.read_u64(rd + 8*j)
      if rs and rs > 0x10000 then
        out[#out+1] = { idx = j, rs = rs, u72 = M.u8(rs+72), u73 = M.u8(rs+73), u784 = M.u8(rs+784) }
      end
    end
  end
  return out
end

-- 州表 (gs+712 {data, count@724}), owner@st+200 / controller@st+204
function M.states()
  local gs = M.gs()
  local std, stn = hoi4.read_u64(gs+712), hoi4.read_u32(gs+724)
  local out = {}
  for i = 1, math.min(stn or 0, 2000) do
    local st = hoi4.read_u64(std + 8*i)
    if st and st > 0x10000 then out[#out+1] = {i = i, st = st} end
  end
  return out
end

function M.vt(p, off) return M.rva(hoi4.read_u64(p + (off or 0))) end
function M.hexdump(addr, n)
  local t = {}
  for i = 0, (n or 32) - 1 do t[#t+1] = string.format("%02X", hoi4.read_u8(addr+i) or 0) end
  return table.concat(t, " ")
end
function M.slot(va) return hoi4.read_u64(hoi4.base() + va) end
return M
