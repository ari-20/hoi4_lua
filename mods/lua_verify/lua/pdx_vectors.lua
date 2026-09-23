-- pdx_vectors.lua — 通用 inline vector 组 reader (CPdxHybridInlineBuffer)

GAME = GAME or {}

local function to_n(x)
    if type(x) == "userdata" then return hoi4.to_number(x) end
    return x
end

-- 读一个 vector 条目 (entry = 宿主对象地址 + 条目偏移)
-- 返回 {data=begin地址, count=元素数, cap=容量} 或 nil
-- 布局 = §3.1 std::vector 四件套 {alloc@+0, data@+8, count@+16, cap@+20};
-- allocator 指针 = §1.3 HYBRID 行 CPdxHybridInlineBuffer 分配器标记
local function read_entry(entry)
    local alloc = hoi4.read_u64(entry)
    if not alloc then return nil end
    alloc = to_n(alloc)
    -- 识别: allocator 指向模块区 (非堆非零)
    if type(alloc) ~= "number" or alloc < 0x10000000000 then return nil end
    local data = to_n(hoi4.read_u64(entry + 8) or 0)
    local cnt  = to_n(hoi4.read_u32(entry + 0x10) or 0)
    local cap  = to_n(hoi4.read_u32(entry + 0x14) or 0)
    if type(data) ~= "number" or data < 0x10000000000 then return nil end
    if type(cnt) ~= "number" or cnt < 0 or cnt > 5000000 then return nil end
    return { data = data, count = cnt, cap = cap, alloc = alloc }
end

-- 扫描宿主对象 [from, to) 偏移范围的全部 vector 条目
-- 返回 { {off=条目偏移, data, count, cap}, ... }
local function scan(host, from, to_)
    local out = {}
    local off = from
    while off < to_ do
        local e = read_entry(host + off)
        if e then
            e.off = off
            out[#out+1] = e
            off = off + 0x18          -- 命中: 按条目步进
        else
            off = off + 8             -- 未命中: 逐 8 找下一个条目头
        end
    end
    return out
end

-- 读 vector 的第 i 个元素 (0-based), 按给定 stride, 返回 u32 数组
local function elem(vec, i, stride)
    local base = vec.data + i * stride
    local t = {}
    for j = 0, stride - 4, 4 do
        local ok, v = pcall(hoi4.read_u32, base + j)
        t[#t+1] = (ok and to_n(v)) or nil
    end
    return t
end

-- dump 一个 vector 的前 n 个元素 (多 stride 视角)
local function dump(vec, n, strides)
    local lines = {}
    for _, stride in ipairs(strides or {8, 16}) do
        local parts = {}
        for i = 0, math.min(n, vec.count) - 1 do
            local e = elem(vec, i, stride)
            parts[#parts+1] = string.format("[%d]%s", i, table.concat(e, ","))
        end
        lines[#lines+1] = string.format("  stride 0x%X: %s", stride,
            table.concat(parts, " "))
    end
    return table.concat(lines, "\n")
end

GAME.pdxv = {
    read_entry = read_entry,
    scan = scan,
    elem = elem,
    dump = dump,
}

-- count 指纹: 运行时动态校准 (州/国家数 mod 可改, 不能硬编码!)
-- 每次调用从 gs 数组读当前会话真实 count; 省数从 supply 省级 vector
-- 首扫获得后缓存 (首轮自举: 用 §1.2 CGameState +724 州表 count +
-- +796 国家数做种子)
GAME.pdxv._cal = nil
local function calibrate()
    if GAME.pdxv._cal then return GAME.pdxv._cal end
    local gs, base = GAME.gs()
    if not gs then return nil end
    local states  = GAME.u32(gs + 0x2D4) or 0    -- §1.2 CGameState +724 州表 count (+712 数据)
    local ctries  = GAME.u32(gs + 0x31C) or 0    -- §1.2 CGameState +796 国家数 (+784 数组)
    GAME.pdxv._cal = {
        [states] = "state-level",
        [ctries] = "country-level",
    }
    return GAME.pdxv._cal
end
function GAME.pdxv.label(count)
    local cal = calibrate() or {}
    if cal[count] then return cal[count] end
    -- 省级: 州数远小于省数, 省级 vector 的 count 通常 > 州数 x10
    -- (用比例启发, 不依赖固定 13414)
    local gs, base = GAME.gs()
    if gs then
        local states = GAME.u32(gs + 0x2D4) or 0   -- §1.2 CGameState +724 州表 count
        -- 排除 2 的幂 (位图/位集不是省表)
        local isPow2 = (count > 0) and (count & (count - 1)) == 0
        if states > 0 and count > states * 8 and count < 100000
           and not isPow2 then
            return "province-level?"
        end
    end
    return ""
end
-- 热重载时清缓存 (schema 重载会重新 dofile 本文件)
GAME.pdxv._cal = nil
