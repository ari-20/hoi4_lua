-- sv2_sec_c_variables.lua -- country.variables 节点 savefull 直出 (csec)
-- (发射规则段; 布局/走查唯一实现 = Country.country_variables
--  objects_global §33.6 §4.13.2 CVariables, maxn=262144 根治版)
-- 形态 (定案 + savefull 实证)
-- variables.random = "s2 s1" 种子对 (写序反: +12 在前 +8 在后), 恒首行
-- variables.<name> = 标量 (fixed5)
-- variables.<name>^<idx> = 数组元 (键含 ^)
-- variables.#N = 匿名行 "name^num=V" (数组长度声明; ^num 非数字后缀
-- 不匹配提取器键正则 → #N 哨兵, 序 = 文档序)
-- 写序 = std::map 字符串键序 (^num 紧跟 ^idx 族),
-- 故发射端按键字节序排序 (reader rh_iter 的桶序与写序无关, 键控行不敏感,
-- 仅 #N 计数依赖顺序)。writer 无门 = 全量发。
SV2.csec[#SV2.csec + 1] = { name = "country.variables", emit = function(ctx)
    local emit, tag, c = ctx.emit, ctx.tag, ctx.country
    if not c then return end
    local SL = SV2.lib
    local ok, vo = pcall(function() return c:country_variables() end)
    vo = ok and vo or nil
    if vo and vo.random then
        emit(tag, "variables.random", string.format("%d %d",
            vo.random[1] or 0, vo.random[2] or 0))
    end
    local list = {}
    for _, v in ipairs(vo and vo.vars or {}) do
        list[#list + 1] = v.name .. "|" .. string.format("%.5f", v.value)
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
