-- staticres_verify.lua -- L1 静态资源接口不变量电池
-- 用法: curl -X POST 127.0.0.1:17389/lua --data-binary @staticres_verify.lua
-- 全循环硬上界; 只读; 写 tmp_staticres_l1_report.txt + tmp_staticres_enum.txt (L2 用)
-- 输出目录推导: 源路径自定位优先; 裸 POST (chunk 无路径) 退回 MOD_LUA_DIR
local TOOLS_DIR = (function()
    local src = (debug and debug.getinfo) and debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)[/\\][^/\\]*$") or MOD_LUA_DIR
    return dir .. "/../tools"
end)()
local L = GAME.layout
local rp, ru32, ru8 = hoi4.read_u64, hoi4.read_u32, hoi4.read_u8
local B = hoi4.base()
local out = {}
local enumf = io.open(TOOLS_DIR .. "/tmp_staticres_enum.txt", "w")
local sum = { keys = 0, inv_ok = 0, inv_bad = 0, charset_bad = 0,
              tok_bad = 0, dup = 0, rt_bad = 0, null_bad = 0, n_a = 0 }
-- 名字净度 = 无控制字节/DEL (UTF-8 多字节名合法)
local function name_dirty(s)
    for i = 1, #s do
        local b = s:byte(i)
        if (b < 0x20 and b ~= 9) or b == 0x7F then return true end
    end
    return false
end

local function sreg_invariant(key, db, sp)
    -- §4.26.4 idb 库规格 — 标准族 count 恒等式:
    -- cnt@76 == lookup.size@52 + 1 (ctor assert 运行时版)
    -- 仅对显式标准族生效 (val=number 或 spec 显式 arr=64/cnt=76);
    -- 自带默认值的特形库 (autonomous_state 无 arr/cnt) 不套恒等式
    if not sp.explicit_std then return "N/A" end
    local lsize = ru32(db + 52)
    local cnt = ru32(db + 76) or 0
    if not lsize then return "N/A" end
    if cnt == lsize + 1 then return "OK(cnt=" .. cnt .. "=lookup" .. lsize .. "+1)" end
    return "FAIL(cnt=" .. cnt .. " lookup.size=" .. lsize .. ")"
end

-- §4.26.4 idb 库规格 — 逐库枚举 + 不变量 (电池体系 §4.26.9)
for key, val in pairs(L.rva.idb) do
    if type(key) == "string" then
        sum.keys = sum.keys + 1
        local db = L.idb(key)
        if not db then
            out[#out+1] = key .. "|NO-INSTANCE"
            sum.n_a = sum.n_a + 1
        else
            local spec = (type(val) == "table") and val or {}
            local sp = { rva = spec.rva or (type(val) == "number" and val),
                         arr = spec.arr or 64, cnt = spec.cnt or 76,
                         nm = spec.nm or "tok8", nonull = spec.nonull,
                         -- explicit_std: 仅标准族 (arr@64/cnt@76 且无 shape 标记
                         -- 声明异形) 套 cnt==lookup.size+1 恒等式
                         explicit_std = (type(val) == "number")
                             or (spec.arr == 64 and spec.cnt == 76
                                 and not spec.shape) }
            local cnt = L.idb_count(key)
            local inv = sreg_invariant(key, db, sp)
            if inv:sub(1,2) == "OK" then sum.inv_ok = sum.inv_ok + 1
            elseif inv:sub(1,4) == "FAIL" then sum.inv_bad = sum.inv_bad + 1 end
            -- 枚举 (硬上界 4096/库)
            local cap = cnt
            if cap > 4096 then cap = 4096 end
            local seen, dups = {}, 0
            local cs_bad, tk_bad, rows = 0, 0, 0
            local cs_ex = {}
            local first, second, last
            for i = 0, cap - 1 do
                local nm = L.idb_token(key, i)
                if nm then
                    rows = rows + 1
                    if i == 0 then first = nm elseif i == 1 then second = nm end
                    last = nm
                    local s = tostring(nm)
                    if name_dirty(s) then
                        cs_bad = cs_bad + 1
                        if #cs_ex < 3 then
                            cs_ex[#cs_ex + 1] = s:sub(1, 24)
                        end
                    end
                    if seen[s] then dups = dups + 1 else seen[s] = i end
                    if enumf then enumf:write(key, "\t", i, "\t", s, "\n") end
                    -- §4.26.2 lexer token 表 — token 有效域 (tokN 库)
                    local t = sp.nm:match("^tok(%d+)$")
                    if t and sp.rva then
                        local def = nil
                        local arr = rp(db + sp.arr)
                        if arr then def = rp(arr + 8 * i) end
                        if def then
                            local tok = ru32(def + tonumber(t))
                            local maxt = 0
                            -- lexer max 经 token_name 越界返回 nil 判定
                            if tok and tok > 0 and not L.token_name(tok)
                                and tok > 500000 then tk_bad = tk_bad + 1 end
                        end
                    end
                end
            end
            sum.dup = sum.dup + dups
            sum.charset_bad = sum.charset_bad + cs_bad
            sum.tok_bad = sum.tok_bad + tk_bad
            -- §4.26.2 name→token 反查 / §4.26.5 idb_index_of_token
            -- — roundtrip 采样 (12 点, O(cnt) 每点; 大库限采样)
            local rt_ok, rt_n = 0, 0
            if sp.nm:match("^tok%d+$") and cnt > 0 then
                local step = math.max(1, math.floor(cap / 12))
                local i = 0
                while i < cap do
                    local nm = L.idb_token(key, i)
                    if nm and type(nm) == "string" and not name_dirty(nm) then
                        local tok = L.name_to_token and L.name_to_token(nm)
                        if tok then
                            rt_n = rt_n + 1
                            local idx = L.idb_index_of_token(key, tok)
                            local back = idx and L.idb_token(key, idx)
                            if back == nm then rt_ok = rt_ok + 1 end
                        end
                    end
                    i = i + step
                end
            end
            sum.rt_bad = sum.rt_bad + (rt_n - rt_ok)
            -- §4.26.4 边界语义 — Null 语义: 标准 family idx0 应可读 (arr[0]) 或 nonull nil
            local n0 = L.idb_token(key, 0)
            local nneg = L.idb_token(key, -1)
            local nc = L.idb_token(key, cnt + 1)
            local null_ok = true
            if sp.nonull then
                if nneg ~= nil or nc ~= nil then null_ok = false end
            elseif sp.nm ~= "none" then
                -- [0]=nil 合法 (arr[0] Null Object 名空); cnt>1 时 [1] 必有名
                if cnt > 1 and second == nil then null_ok = false end
            end
            if not null_ok then sum.null_bad = sum.null_bad + 1 end
            local trunc = (cnt > 4096) and ("TRUNC@" .. cap) or ""
            local csx = (#cs_ex > 0) and (" ex=" .. table.concat(cs_ex, "/")) or ""
            out[#out+1] = string.format(
                "%s|cnt=%d|%s|enum=%d|cs_bad=%d%s|tok_bad=%d|dup=%d|rt=%d/%d|null=%s|%s|%s|%s|%s",
                key, cnt, inv, rows, cs_bad, csx, tk_bad, dups, rt_ok, rt_n,
                tostring(null_ok), tostring(first), tostring(second),
                tostring(last), trunc)
        end
    end
end
if enumf then enumf:close() end

-- ================== 二部分: 运行时访问器不变量 (loc_text / define / terrain) ======
-- 只查形态/内部一致性, 不查内容常量 (内容随语言与 mod 变)
local acc = {}
local acc_fail = 0
local function chk(name, ok, detail)
    if not ok then acc_fail = acc_fail + 1 end
    acc[#acc+1] = string.format("%s|%s|%s", name, ok and "OK" or "FAIL",
                                detail == nil and "" or tostring(detail))
end
if L.loc_text then
    local hit = L.loc_text("RECRUIT_OPERATIVE_TITLE")
    chk("loc_text.hit", type(hit) == "string" and #hit > 0, hit)
    chk("loc_text.miss", L.loc_text("A1_L1_BATTERY_NO_SUCH_KEY_ZZZ") == nil, "nil")
    chk("loc_text.edge", L.loc_text("") == nil, "empty-nil")
    -- §4.26.8 本地化运行时管理器 — 索引层不变量: mgr 可达 / 条目数与 blob 用量在有界区间
    local mgr = rp(B + 0x35BA038)
    local texts = mgr and rp(mgr)
    local nidx = texts and ru32(texts + 44)
    local bcap = mgr and ru32(mgr + 40)
    local bused = mgr and ru32(mgr + 44)
    chk("loc_text.idx_cnt", type(nidx) == "number"
        and nidx > 50000 and nidx < 2000000, nidx)
    chk("loc_text.blob_used", type(bused) == "number" and type(bcap) == "number"
        and bused > 1000000 and bused <= bcap and bcap < 200000000,
        (tostring(bused) .. "<=" .. tostring(bcap)))
else
    chk("loc_text.api", false, "M.loc_text 缺失")
end
if L.define then
    -- §4.26.5 define/define_f (离线表 §4.26.7) — 全表形态: 样例全命中 + 未知名 nil; 常量值不作断言
    local dhit, dn = 0, 0
    for _, nm in ipairs({ "OUT_OF_SUPPLY_SPEED", "BASE_FACTORY_MAX_EFFICIENCY_FACTOR",
                          "COMBAT_GOOD_ARMOR", "LAND_UNIT_MOVEMENT_SPEED",
                          "SUPPLY_HUB_FULL_MOTORIZATION_TRUCK_COST" }) do
        dn = dn + 1
        if L.define(nm) ~= nil then dhit = dhit + 1
        else chk("define." .. nm, false, "nil") end
    end
    chk("define.sample", dhit == dn, dhit .. "/" .. dn)
    chk("define.miss", L.define("A1_NO_SUCH_DEFINE_ZZZ") == nil, "nil")
else
    chk("define.api", false, "M.define 缺失")
end
-- §4.26.8 CTerrainDatabase 扩展 — terrain 用例挂 resource.lua 的 terrain_lut (未挂键则跳过)
if L.terrain_lut then
    local lub = L.idb_count("terrain") or 0
    local lc, ln = L.terrain_lut(), 0
    local lut_ok = type(lc) == "number" and lc > 0 and lc <= 65536 and lub > 0
    if lut_ok and type(lc) == "number" then
        for i = 0, lc - 1 do
            local v = L.terrain_lut(i)
            if v == nil then lut_ok = false; ln = i; break end
        end
    end
    chk("terrain.lut", lut_ok, tostring(lc) .. " entries" .. (ln > 0 and (" first_nil@" .. ln) or ""))
    -- §4.14.3 省静态描述符 — 双读一致性: 抽样省 desc 链 terrain def 名 ∈ idb terrain 名集
    if L.province_terrain_name then
        local names = {}
        for i = 0, math.min(lub - 1, 4095) do
            names[tostring(L.idb_token("terrain", i))] = true
        end
        local mp = L.map_ptr()
        local pbound = mp and ru32(mp + 560) or 0
        local step = math.max(97, (pbound or 99000) // 50)
        local ok2, checked = true, 0
        for pid = 1, pbound - 1, step do
            local nm = L.province_terrain_name(pid)
            if nm then
                checked = checked + 1
                if not names[tostring(nm)] then ok2 = false; ln = pid; break end
                if checked >= 60 then break end
            end
        end
        chk("terrain.double_read", ok2 and checked > 0,
            "checked=" .. checked .. (ok2 and "" or (" bad=" .. tostring(ln))))
    end
else
    chk("terrain.lut", true, "SKIP(terrain_lut 未挂载)")
end
-- §4.26.5 idb_find — 指针对拍 (抽样): 哈希/内联取条目 vs 线性扫描取条目, 指针须相等
if L.idb_find and L.idb_token then
    local fok, fn, fbad = 0, 0, nil
    for _, key in ipairs({ "building", "terrain", "sub_unit", "ideology_group",
                           "autonomous_state", "state_category", "wargoal" }) do
        local spec = L.rva.idb[key]
        local db = L.idb(key)
        local cnt = L.idb_count(key) or 0
        if db and cnt > 0 then
            local arroff = (type(spec) == "table" and spec.arr) or 64
            local arr = (type(spec) == "table" and spec.nm == "msvc8")
                and rp(db + 48) or rp(db + arroff)
            if arr then
                local step = math.max(1, math.floor(cnt / 6))
                local i = 0
                while i < cnt and fn < 60 do
                    local nm = L.idb_token(key, i)
                    if nm and type(nm) == "string" then
                        local fp = L.idb_find(key, nm)
                        local lp = nil
                        for j = 0, math.min(cnt - 1, 4096) do
                            if L.idb_token(key, j) == nm then
                                lp = rp(arr + 8 * j); break
                            end
                        end
                        fn = fn + 1
                        if fp and lp and fp == lp then fok = fok + 1
                        elseif not fbad then fbad = key .. ":" .. nm end
                    end
                    i = i + step
                end
            end
        end
    end
    chk("idb_find.ptr", fbad == nil and fok > 0,
        fok .. "/" .. fn .. (fbad and (" bad=" .. fbad) or ""))
end
-- §4.26.5 mods_registry — 形态: 条目数与磁盘 .mod 数一致 (名/路径对拍走离线 L2)
if L.mods_registry then
    local reg = L.mods_registry()
    local n = 0
    local seen = {}
    for _, e in ipairs(reg or {}) do
        n = n + 1
        local nm = e.name or e[1]
        if seen[nm] then seen[nm] = 2 else seen[nm] = 1 end
    end
    chk("mods_registry.shape", n > 0 and n < 5000, n .. " entries")
end
local rpt = io.open(TOOLS_DIR .. "/tmp_staticres_l1_report.txt", "w")
rpt:write("== L1 静态资源接口不变量电池 ==\n")
rpt:write(string.format(
    "SUMMARY keys=%d inv_ok=%d inv_bad=%d charset_bad=%d tok_bad=%d dup=%d rt_bad=%d null_bad=%d n_a=%d acc_fail=%d\n\n",
    sum.keys, sum.inv_ok, sum.inv_bad, sum.charset_bad, sum.tok_bad,
    sum.dup, sum.rt_bad, sum.null_bad, sum.n_a, acc_fail))
for _, ln in ipairs(out) do rpt:write(ln, "\n") end
rpt:write("\n== 访问器不变量 ==\n")
for _, ln in ipairs(acc) do rpt:write(ln, "\n") end
rpt:close()
return string.format(
    "L1 done: keys=%d inv_ok=%d inv_bad=%d cs_bad=%d tok_bad=%d dup=%d rt_bad=%d null_bad=%d acc_fail=%d",
    sum.keys, sum.inv_ok, sum.inv_bad, sum.charset_bad, sum.tok_bad,
    sum.dup, sum.rt_bad, sum.null_bad, acc_fail)
