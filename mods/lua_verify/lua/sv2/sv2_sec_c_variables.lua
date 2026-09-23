-- sv2_sec_c_variables.lua -- country.variables 节点 savefull 直出 (csec 首发)
-- 形态 (定案 + savefull 实证)
-- variables.random = "s2 s1" 种子对 (写序反: +12 在前 +8 在后), 恒首行
-- variables.<name> = 标量 (fixed5)
-- variables.<name>^<idx> = 数组元 (键含 ^)
-- variables.#N = 匿名行 "name^num=V" (数组长度声明; ^num 非数字后缀
-- 不匹配提取器键正则 → #N 哨兵, 序 = 文档序)
-- 容器 = §4.13.2 CVariables @cc+536 (挂载行见 §4.3.11 表),
-- 写序 = std::map 字符串键序 (^num 紧跟 ^idx 族),
-- 故发射端按键字节序排序 (reader rh_iter 的桶序与写序无关, 键控行不敏感,
-- 仅 #N 计数依赖顺序)。
-- 勘误: 原走 objects_v2.country_variables, 其 rh_iter maxn=4096
-- (散写字面量) — mod 议会机制实测 ~3k 条变量 → mask≥4095, +extra 尾桶 →
-- nbuckets>4096 → rh_iter 返 nil → 整表蒸发 (mem 侧仅剩 random)。
-- 段内直读, maxn 用具名界 lim.PTR_HUGE(65536, RH 扫描类;
-- lim.PTR_SANE=4096 正是故障界, 不可用); writer 无门 = 全量发, 防御界
-- 只需罩住最大真实表。桶解码忠实复制 objects_v2 §33.6 (dist 低字节三重
-- 过滤 0/0xFE/0xFF + SSO 名@+8 + i64 有符号 /100000 定点值@+0x28)。
SV2.csec[#SV2.csec + 1] = { name = "country.variables", emit = function(ctx)
    local emit, tag, c = ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local SL = SV2.lib
    local LAY = GAME.layout
    local rp, ru32 = hoi4.read_u64, hoi4.read_u32
    local vo = rp(c.addr + 536)
    if vo and vo > 0x10000 then
        emit(tag, "variables.random", string.format("%d %d",
            ru32(vo + 12) or 0, ru32(vo + 8) or 0))
    end
    local list = {}
    if vo and vo > 0x10000 then
        -- CVariables 表头内嵌 (勘误): data@vo+0x18, count@vo+0x20
        -- (0x18+8, 平行推定, 仅 mask 读失败的兜底路径用), mask@vo+0x24,
        -- 桶 0x30 {hash@0, dist u8@+4, 名 MSVC@+8, value i64@+0x28}
        local buckets = LAY.rh_iter(vo, { data = 0x18, mask = 0x24,
            count = 0x20, stride = 0x30,
            -- 实测最大国 ~3.1 万变量 → RH 桶数到 131072 档; PTR_HUGE(65536)
            -- 不够使 rh_iter 返 nil 整表蒸发 (同族故障, 界再抬一档)
            maxn = 262144 })
        for _, b in ipairs(buckets or {}) do
            local dist = ru32(b + 4)
            if dist and (dist & 0xFF) ~= 0 and (dist & 0xFF) ~= 0xFE
                and (dist & 0xFF) ~= 0xFF then
                local nm = SL.sso(b + 8)
                local v = rp(b + 0x28)
                if v then v = GAME.layout.as_i64(v) end
                local val = v and v / 100000 or nil
                if nm and val then
                    list[#list + 1] = nm .. "|" .. string.format("%.5f", val)
                end
            end
        end
    end
    table.sort(list) -- "name|val" 串按 name 字节序 (name 不含 |)
    local seq = 0
    local function numfmt(vs)
        local v = tonumber(vs)
        if v and v == math.floor(v) and math.abs(v) < 2 ^ 53 then
            return string.format("%d", v)
        end
        -- writer 定点打印去尾零 (PER project_monetary_cost^-1: save 19.5696)
        return (vs:gsub("0+$", ""):gsub("%.$", ""))
    end
    -- ^ 后缀非纯数字 (num / -1 / …) 的键, 提取器 HEAD 正则
    -- ([A-Za-z0-9_.]+(?:\^\d+)?) 不收 → 整行走多 token 行 →
    -- variables.#N = "名=值" 序号叶 (序 = 全键字节序, 与 ^num 同一计数器)
    for _, kv in ipairs(list) do
        local nm, val = kv:match("^(.-)|(.*)$")
        if nm then
            local suf = nm:match("%^([^%^]*)$")
            if suf and not suf:match("^%d+$") then
                seq = seq + 1
                emit(tag, "variables.#" .. seq, nm .. "=" .. numfmt(val))
            else
                emit(tag, "variables." .. nm, numfmt(val))
            end
        end
    end
end }
