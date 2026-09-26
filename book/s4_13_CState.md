

### 4.13 CState (州)

获取: `st = 州表[state_id]` — 州表 = `*(gs + 712)` (8 字节/项, state_id 直查); 计数 =
u32@(gs+724) = 州库条目数 (states writer 循环 i∈[1,724); kr2 实拍 1126,
sarr[1125]=CState/[1126]=null 探针互证)。gs+700 = 省表界 (省数, 与 CMap+560 /
省表 null 终止三读互证) — 勿与州计数混用。
vtable RVA 0X2936CC0 (槽[2] = writer); CState writer 0X1409E0E90;
方法群 0XUNRESOLVED-0X1409E2E50 (assert 串 source/geography/state.cpp)。
CProvince+192 = CState* 回指 (§4.14)。⚠ CGameState+260 **负定案**: 全 dump 无 `*(gs+260)` 读写、gs 尾 ctor sub_1401D0E30 亦无该槽初始化 → 非 CGameState 字段 (推定 ctor 前 allocator 头/pad); 附注 sub_140BC0880 = gs+16 子对象 ctor, 非 gs ctor。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +8 | 内嵌 | CSelectable 子对象 (selectable.cpp 断言铁证) | 选择态基件 | 不序列化 |
| +24 | CProvince** | 省数组数据 | qword 元 — BestVP getter/modifier 重建/Reset 三源互证 | |
| +36 | uint32 | 省数组计数 | Reset 置 0 | |
| +48 | CGameState* | 州库定义条目指针 (stateDef) | → CStateDatabase 单例 qword_14332F070 (两 getter rip 目标均此址, 装载串 "history/states" 直证); 条目布局见下 stateDef 子表 | GUI: 国列表 filter1 值源 `*(*(state+48)+320)+44` = 大陆 id (loc 铁证 DYPLOMACY_FILTER_CONTINENTS/IDEOLOGIES/FACTIONS = 三滤) |
| +56 | MSVC 串 | name | 门 = size@+72 ≠0 (writer 0X1409E0E90 L53) | SSO 32B: buf@+56..+71, size@+72, cap@+80; GUI: state_name 文本 (sub_1409D91D0 两级回退: 次选 +232 串) |
| +72 | u32 | name size (写门字段) | | SSO 内部 |
| +80 | u32 | name cap | SSO 内部 (writer 不触) | |
| +81..+87 | — | = name 串 cap 的高 4B (cap 实为 8B size_t; 串 {buf@56, size@72, cap@80}) | | |
| +88 | uint32 | state id | 断言 "Strategic location already exist in state: %d" (sub_1409D18B0); CVariables 以 +88 重注册; SetOwner 通知构造 | |
| +89..+107 | — | = state id@88 尾垫 (+92..+95) + 监听对象数组 {data@96, cap@104, count@108, alloc@112} 头 (owner/controller 变更通知: SetOwner 逐元 vt[+24](elem, st, &tag); 元素类名定案 = **CProductionStatus** (vt RVA 0x2970788 — 活体元素首 qword 直证); 归属未决 — 非任何 cc+3944, +656 反指=0; 消费全定案 (SetOwner sub_1409DE560 逐元 vt[+24](elem, st, &tag) / SetController sub_1409DDA40 整段复制 / Reset 清 count); 注册点未定位 (0x1409D 段内 `sub_1401205A0(...+96)` 0 命中, 推定内联在 province 侧 CProductionStatus 创建路径); **活体分布 = 599/1082 州 count>0**) | | |
| +108 | uint32 | 监听数组计数 | +120 空时 Reset 置 0 (sub_1409D6BF0; 高置信) | |
| +109..+119 | — | = 监听数组 {count@108, alloc@112} + CStateHistory* 外置指针@120 头 (非内嵌; 外置对象 {head, cap, count, alloc}, 条目 32B 见下子表) | | |
| +120 | 内嵌容器 | 州历史条目向量 (CStateHistory 族, 业务名推定) | 32B 条 (见下子表), 独立 allocator; Reset 扩容插入 {2,0,1,0} 迁移 (容器形态定案) — 非「动态修正容器」(旧同名异偏移系误名) | |
| +121..+139 | — | = CStateHistory* 指针尾 (+121..+127) + 占领国状态对象数组 {data@128, cap@136, c@140, alloc@144} 头 (元素 8B 指针: tag@元+56 / 子 CResistance@元+472; swap-remove; 推定 CCountryOccupationStatus) | | |
| +140 | uint32 | **占领国状态对象数组 (+128) 的计数** (swap-remove 维护 `--*(st+140)`: sub_1409DD4F0; 线性查 tag@元素+56 以上界: sub_1409DAB20) | Reset/SetOwner/sub_1409D02B0 三处清零 | |
| +141..+151 | — | = count@140 + alloc@144 尾 + claims {d@152} 头 | | |
| +152 | tag_id 向量 | claims 宣称集合 | tag 键 — CAddStateClaimEffect::Execute sub_14034C350 → sub_1409D1510 插入; 国家侧对应 cc+1216/{+1228} (效果类锚定) | GUI: state_owners 宣称国旗行 (sub_14174ECF0) |
| +153..+175 | — | = claims 容器 {d@152, cap@160, c@164, alloc@168..175} 内部 (dtor 四件套) | | |
| +176 | tag_id 向量 | cores 核心标签数组数据 | u32 tag 元 — CAddStateCoreEffect::Execute sub_14034C380 → sub_1409D1660; 修正重建以 owner/controller ∉ cores 定占领修正 (效果类+三源互证) | GUI: state_owners 核心国旗行 (sub_14174ECF0); 国家侧对应 cc+1192 核心州表 |
| +188 | uint32 | cores 计数 | 步进 +4 遍历界 | |
| +189..+199 | — | = cores 容器 {d@176, cap@184, c@188, alloc@192..199} 内部 | | |
| +200 | uint32 | owner | 占领国 tag_id (0 = 无); SetOwner sub_1409DE560 直写 | GUI: 州头 owner==controller 文案键切换 (sub_14174ECF0 + 谓词 sub_140BB52F0); 省名着色基准 (州+200 vs 省+392) |
| +204 | uint32 | controller | 控制国 tag_id; SetController sub_1409DDA40 (还检 *(st+696)=CResistance+80, 互证) | GUI: 占领州过滤 (x/y 州数 sub_14155D120); 密码候选转发 (AgencyView[11] 0X140F2C150); 外交 SetTarget ([11] 取省+392 同链) |
| +208 | 匿名结构 | contested_owners 容器数据指针 | {data@+208, cap@+216, count@+220, alloc@+224} (标准四元组; writer 0X1409E0E90 块键 10156, 元素 4B tag 流; Reset 清 +220) | GUI: state_owners 争夺国行 (4B tag 流, sub_14174ECF0) |
| +209..+219 | — | = contested 容器 {d@208, cap@216, c@220, alloc@224..231} 内部 | | |
| +220 | u32 | contested_owners 容器计数 | | |
| +221..+263 | — | = contested alloc@224 尾 + 匿名 32B MSVC 串@232..263 {buf@232, size@248, cap@256} (不序列化、Reset 不清; GUI 定案用途 = state_name 回退源 — size@+248≠0 时第二优先, sub_1409D91D0) + previous_owner {d@264} 前 pad | | |
| +264 | tag_id | previous_owner 容器数据指针 | {data, count} 4B tag id (11290; 战速换主才出现) | |
| +265..+275 | — | = previous_owner {d@264, cap@272, c@276, alloc@280..287} 内部 (SetOwner contains+push 维护) | | |
| +276 | u32 | previous_owner 容器计数 | Reset 置 0 | |
| +277..+287 | — | = previous_owner {alloc@280 尾} + 内嵌 CBuildingStatus@288 头 (save 实名 buildings, token 12121) | | |
| +288..+403 | — | = CBuildingStatus (116B) 本体 (save 实名 buildings, token 12121) — 布局见下子表; 销毁器 sub_141174AD0 (操作域 = 相对 +8/{+20 计数} 与 +56/{+68 计数}, 即记录数组与自有槽实例数组两子容器), 与 CProvince+400 成对销毁 | GUI: 州建筑行两列表分流 (def+704 旗 → state_building_entries / state_shared_slot_building_entries; sub_14174ECF0) | |
| +408 | 匿名结构 (8B 形状) 向量 | 占领份额 per-country 数组数据 | 8B 条 {tag, amount}; OCCUPATION_BREAKDOWN tooltip sub_1409D82A0 (share = 1e10*amount/(1e5*total)) (loc 锚定) | GUI: controller_flag(_border) 双旗隐藏门 (owner 份额==100% → 隐; sub_1409D5390 读 +408/{+420,+432}) |
| +420 | uint32 | 占领份额数组计数 | Reset 置 0 | |
| +421..+431 | — | = 占领份额 {d@408, cap@416, c@420, alloc@424..431} 内部 | | |
| +432 | uint32 | 占领份额总量 total | share 分母; Reset 置 0 | |
| +436 | uint8 | 资源消耗/修正可见性旗 A | STATE_RESOURCE_COST 查找门; Reset 以 u16 连 +437 清 | |
| +437 | uint8 | 同族旗 B | 谓词 sub_1409DA7B0 消费 | |
| +438..+615 | — | = 内嵌 CStrategicResourcePool (176B; save 实名 resources, token 11842, `steel=8` 实拍) — 布局见 §4.13.6 | | |
| +616 | 内嵌 CResistance | 抵抗力 | 全字段见 §4.13.1 | GUI: 州面板阻力/合规容器 (sub_14174E8E0, 激活门 sub_140F9B4B0) + 占领法州上下文 (法 id sub_1406F2F20 / 法 sub_140F99DB0) |
| +617..+1343 | — | = CResistance 全长 728B (cr = st+616; §4.13.1); 尾 cr+720 = 100000 标度 | | |
| +1344 | CFlagManager* | 脚本旗标 | SetOwner 时 sub_140CBFA90 清理; 见 §4.13.3 | |
| +1352 | 内嵌块 | 州资源消耗块基 (真 CModifier 192B: vt@1352, pairs@1368, children@1392; 不序列化) | base pairs@+1368 16B 条 {token, value i64}; loc STATE_RESOURCE_COST "State Consumption" 按 token 查 | |
| +1368 | 匿名结构 (16B 键值对) 向量 | (+1352 块) base pairs 数据 | 与 +1736 块 pairs@+1752 同构 (base+16 关系) | 定案: +1352 = 真 CModifier (vt + pairs 双证, 探针), +1368 = 其 base pairs 数据槽; 「内联默认 CModifier」读法否定 |
| +1381..+1543 | — | = 真 CModifier (192B)@1352 内部 — 按 §4.3.8 通用表即闭 | | |
| +1544 | 内嵌块 | 州生效修正块 (运行时合成, 非序列化) | 重建 sub_1409D54A0: 清 +1560 → category 对象+96 修正 + +1736 脚本块 + 非-core owner/controller 占领修正 + 建筑 +88 + 每省 +480 条目 → sub_140557BF0(st+1928, st+1544) 施加; base pairs@+1560, children {d@+1584, c@+1596} | |
| +1596 | uint32 | (+1544 块) children 计数 | sub_1409E02C0 读 | |
| +1597..+1735 | — | = 真 CModifier (192B)@1544 (运行时合成生效修正) 内部 — 192B 恰到 +1736, 三块等距互证 | | |
| +1736 | 内嵌 CModifier | 州 modifier 块 (10597) | 全布局见 §4.3.8 通用表 (+64 回收池 / +88 name / +120 tooltip 串集合 / +152 hidden 集合 / +184 掩码 / +188 深度); base pairs {d@+1752, c@+1764} 16B 元 {mdef idx u32, i64×1e-5}, mdef 表 = *(BASE+53569984) 120B 行 token@+112; children {d@+1776, c@+1788}: added_modifier data=u32@child+188 (≠1 门), name=SSO@child+88, pairs {d@+16, c@+28} (writer 0X140612640; TGWR 脚本州修正) | |
| +1737..+1927 | — | = 州脚本修正 CModifier@1736 (带 vt, ctor a1[217]) 内部 — 192B 恰到 +1928 | | |
| +1928 | 内嵌容器 | dynamic_modifier (15361) | 容器对象 (vt+8 自序列化), {d@+1968, c@+1980} 64B 条目 (§4.13.4); 块门 = sub_14060D020(st+1928) 为假 (非空) 才写 (CState writer 0X1409E0E90) | GUI: dynamic_modifiers_grid 行重建 (r1 sub_14174C8E0 逐条填格) |
| +1929..+1999 | — | = 动态修正容器 (72B) {…, data@1968, count@1980}; 空 = count@+52==0 (sub_14060D020 直读式) | | |
| +2000 | CEvent* 向量 | **州事件作用域待发 CEvent\* 队列** {d@2000, cap@2008, c@2012, alloc@2016} — 元素由事件管理器 sub_140A0D4E0 append; SetOwner 链 sub_1409D73E0 逐元 `sub_141180350(elem, *(st+2024))` 求值命中即 sub_140A0F4F0 投递, 投递后 count 清零 | 遍历点 sub_140443220; **「候选驻军/占领族」方向注销** (与 CStateGarrisonData 无关) | |
| +2012 | uint32 | 上述计数 | Reset 置 0 | |
| +2013..+2023 | — | = 通知表 {d@2000, cap@2008, c@2012, alloc@2016..2023} 内部 | | |
| +2024 | CEventScope* | **CEventScope\*** (0xB0; Reset 释放旧对象后 malloc + ctor sub_140535110 写 `&CEventScope::vftable`, 再 sub_14053B5F0(scope, *(*(st+48)+160), 1) 以 stateDef+160 州 id 设作用域) | 投递时作为事件作用域实参传入 sub_140A0F4F0 | |
| +2025..+2039 | — | = CEventScope*@2024 (176B, 州事件作用域 — ctor 即建, Reset 换新; SetOwner 配合发 on_state_owner_changed) 尾 + u32@2032 = id % dword_143336F50 (**州事件掷骰相位**: 每日州并行 worker 以 `id%N == gs+1156 年积日%N` 判定本州当日是否掷事件候选, N = dword_14332F650 低字节; §4.2.7) | | |
| +2040 | CVariables* | 州脚本变量 | RH 表, 见 §4.13.2 | |
| +2048 | 匿名结构 (8B 形状) 向量 | strategic locations 对数组数据 — 8B 条 {loc_id u32, value u32} | AddStrategicLocation sub_1409D18B0 实读 (重复断言含 +88 id; 1.5x 增长); 默认 value = 首省 +164 | GUI: 州侧 strategic locations 过滤 (条目 v4[1]==prov.id; r2 sub_1417507F0 — 第二 u32 = prov_id, tooltip 双名 getter 再证) |
| +2056 | uint32 | 上述容量 cap (1.5x 增长) | 定案 | |
| +2060 | u32 | strategic locations 容器计数 | BUILDING/AMOUNT 消费者 sub_1409D96D0 互证 | |
| +2061..+2063 | — | = CVariables@2040 (56B) 尾 + VP hybrid 容器@2048 {head@2048, cap@2056=2, c@2060} 头 (victory_points 14786) | | |
| +2064 | vtable | strategic locations allocator 对象 | 释放走 vtable+16 | |
| +2065..+2103 | — | = VP hybrid (CPdxHybridInlineBufferAllocator<pair<token,int>,2>): allocptr@2064→&+2072, 头 vt@2072, 内联 buf 2×8B {token, value}@2080..2095, fallback@2096..2103 | | |
| +2104 | — | manpower 基准锚 | SetOwner/SetController 后 sub_1413EB4D0(st+2104) 重算; Reset sub_1413EAE90 | GUI: 人力文本 (total@+2128 经 sub_14072DEA0 → STATE_POPULATION_VALUE; 占领侧 Σ sub_1413EB130) |
| +2105..+2119 | — | = CStateManpower (32B) {vt@2104, CState* 回指@2112, available@2120, locked@2124} — manpower_pool (13877) 本体; total 初值 = *(gs+340) | | |
| +2120 | uint32 | manpower available | 人力三元组 (写门 = **total ≠0** 整块判定; 三叶恒全 — ⚠ 旧"三值任一非零"经验门被活体证伪: 3103.11 档 76 州 available/locked 非零而 total=0 整块不写) | |
| +2124 | uint32 | locked | 人力三元组 | |
| +2128 | uint32 | total | 人力三元组 (**整块写门字段**) | |
| +2136 | uint32 | extra_shared_slots | >0 才写 (13613); loc UNLOCKED_SLOTS_STATE_EXTRA "Additional Slots in this State" (loc 锚定; resistance 数值在 +616 内嵌块, 非 +2136) | GUI: 共享槽 NUM/MAX (sub_1409D4980 → shared_slot_count + UNLOCKED_SLOTS; category=="wasteland" → 基数归零, +2200 名 SSO 实证) |
| +2140 | int32 | best VP province index | -2=未算 / -1=无 / ≥0=+24 数组下标; 断言 "_BestVPIndex != -2" (sub_1409D8A80, state.cpp) | |
| +2141..+2147 | — | = manpower 区尾 + extra_shared_slots@2136 / bestVP / u32@2144 (**写侧定案 = 州内各省地形修正旗字节 (省 desc+168→+140) 的按位或累积**: sub_1409DF710 先清 0 后逐省 `|=`; sub_1409DED70 同式。**读侧在 1.19.3 全 dump 不存在** (0 读点) → 只写累积位掩码) / demil@2148 区 | | |
| +2148 | uint8 | demilitarized | 非军事化 (13281); +2148 与 +2149 为两个独立 u8 (Reset 以 word 一次双清) | 存档行序在 ibc 前 |
| +2149 | uint8 | is_border_conflict | 边境冲突 (13295); BORDER_WAR tooltip 消费 | |
| +2150 | uint8 | 阻力激活缓存字节 | = sub_140F9B4B0(st+616,1) 镜像, 变化即触发地图刷新; Reset 置 0 | |
| +2151..+2159 | — | = CGameDate 24B@2152 (建筑移除冷却) {vt1@2152, hours@2160, vt2@2168} 头 | | |
| +2160 | uint32 (hours) | 建筑移除冷却锚日 | CGameDate 小时制; loc BUILDING_SLOT_REMOVE_COOLDOWN (DAYS/DATE 双参, sub_1409DAF20); Reset 置 dword_143086B20 (loc 锚定) | |
| +2161..+2183 | — | = 冷却日期 {vt2@2168} 尾 + last_strategic_bombing CGameDate@2176 {vt1@2176, hours@2184, vt2@2192} 头 — writer ADEC0 收 vt2 = 接口子对象地址 (+2192) | | |
| +2184 | hours | last_strategic_bombing | CGameDate 内嵌; ≠ 默认值 (dword_143086B20) 才写 (15508); 写入源 = *(gs+1128) 当前日期 (sub_1409E01A0) | |
| +2185..+2199 | — | = last_strategic_bombing {vt2@2192} 尾 + state_category 定义指针@2200 头 | | |
| +2200 | — | state_category | 指针→定义对象, 名 = 全 SSO@对象+24 (size@+40; 8B 内联读会截断为 "large_is" — 须全 SSO); 默认 = *(gs+360) | |
| +2201..+2207 | — | = state_category 定义指针@2200 尾 (8B) + _SubAreas std::map 哨兵@2208 头 | | |
| +2208 | std::map | _SubAreas 子区域 RB-tree | 断言原文 _SubAreas (sub_1409D71E0, state.cpp); 树遍历 sub_1409E2C80, 插入 sub_1401F6470 (断言锚定) | |
| +2209..+2223 | — | = _SubAreas std::map {哨兵@2208 (malloc 0x28 三自指), size u64@2216} 内部 | | |
| +2224 | CPersistent* 向量 | temporary_resource_list 容器数据指针 (块键 15754) | 元素 **32B 多态 CPersistent 后代** (逐条 sub_1424C24F0 = `(*(elem vt[1]))(elem, writer)` 即元素自身 vt[1] 自序列化, 尾原子 16; 非 dynamic_modifiers/SDynamicModifierEntry — 后者 64B); reader sub_1409CF450; Reset 逐条虚析构后清 count; **元素具体类名待裁 (无 RTTI 直证)** | |
| +2225..+2235 | — | = temporary_resource_list {d@2224, cap@2232, c@2236} (15754; 条目 32B 多态) 内部 | | |
| +2236 | u32 | temporary_resource_list 容器计数 | | |
| +2237..+2247 | — | = temporary_resource_list {alloc@2240..2247} 尾 + 三 RH 表头全形 {qword@0 (ctor 未显式初始化), data@+8 = 空表哨兵 &unk_143090170, mask@+16, count@+20, extra u8@+24, lf f32@+28 = 0.9} (桶 208B); 对象尾 = +2344, 之后无字段 | | |
| +2248 | 匿名结构 (208B 形状) RH 桶数组 | per-tag 值对 RH 表 A | 208B 桶 {used u8@+4, key tag u32@+8, 值对数组 {data@+32, c@+44} 16B 条 {token, i64}}; Reset sub_1409D70F0, tag 查找 sub_1409D8B10 (定案形态) | |
| +2256 | CModifier* RH 桶数组 | 每国州级 modifier 哈希表 | 桶 208B = {hash@0, dist u8@+4, tag@+8, **CModifier 内嵌@+16**}; 掩码@2268 / 空桶回退@2272; 命中谓词 = tag 相等 ‖ sub_140BB52F0 同原初国 | 定案: 桶载 CModifier 内嵌 (vt+357 签名 + pairs 四元组双证, 探针); 旧「值对数组」读法 = CModifier.pairs@+32 误位 |
| +2280 | 匿名结构 (208B 形状) RH 桶数组 | active_targeted_modifier RH 表 (布局互证 {data@+2288, count@+2296, cap@+2300}) | 见 §4.13.5 | |
| +2312 | 匿名结构 (208B 形状) RH 桶数组 | per-tag 值对 RH 表 B (同 +2248 形态) | **定案: B = 表 A (+2248) 的 swap 备份 double buffer** — 重建链 sub_1409D7760 把 data/mask/count/extra 四域成对 A↔B 换位后清 B 重算写回 A; 无独立业务语义, 旧「占领资源转移」语义注销 (探针附证: 占领折减公式实读 A 表, A 表键 = 州属主) | GUI: B14 占领资源折减 ((行值+100000)/100000; sub_14155D120) |

三 RH 表 (+2248 / +2280 / +2312) 表头均按 +2237..+2247 行全形落位, 对象内绝对偏移
= 表基 + 相对: A@2248 → data@2256 / mask@2264 / count@2268 / extra@2272 / lf@2276;
active_targeted_modifier@2280 → data@2288 / mask@2296 / count@2300 / extra@2304 /
lf@2308; B@2312 → data@2320 / mask@2328 / count@2332 / extra@2336 / lf@2340;
对象尾 = +2344。⚠ +2280 行旧互证读法 {count@2296, cap@2300} 与全形推导
(mask@2296 / count@2300) 不合 — 定案: 表头全形成立, **mask@2296 / count@2300** 。

**stateDef (CStateDatabase 条目) 布局** (锚定 = st+48 → 单例 qword_14332F070):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +160 | uint32 | 州 id | |
| +248 | — | 静态资源条 16B 数组 {量@+0, res_id@+8} | 数据@+248 |
| +260 | int | 静态资源条数组**计数** | 定案 : +248 = 数组 data, 元 16B {资源量 i64@0, res_id u32@8}; +256 = cap (推定); 初始化循环 + 零资源早退读者直证 |
| +272 | u32* | 邻接州 id 数组 {data@+272, count@+284} | 高置信 (CEveryNeighborState/CRandomNeighborState 槽[28] 与 num_owned_neighbour_states 双链互证) |
| +320 | 匿名结构 (NNB 形状) | 战略区对象 | 对象+44 = 大陆 id (GUI filter1 值源); 对象+48 = 稠密战略区号 |
| +348 | u8 | **impassable 旗** (stateDef; 直读 sub_1409DB3F0) | §4.32 地形族 |
| +349 | u8 | 海岸旗 (is_coastal) | 推定 |
| +350 | u8 | 单州岛旗 (is_one_state_island) | 推定 |
| +360 | — | 默认 category | 同上 |

**CStateHistory 条目 (32B)** — 外置向量@st+120 (条目形态定案, 业务名推定):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| 元素+0 | uint32 | type | Reset 扩容插入 {2,0,1,0} 迁移 |
| 元素+8 | qword | 未名 | |
| 元素+16 | u8 | 未名 | |
| 元素+24 | u8 | 未名 | |

**CBuildingStatus (116B)** — 内嵌@st+288, save 实名 buildings (token 12121):

| 偏移 (st) | 类型 | 名称 | 备注 |
|---|---|---|---|
| +296 | 匿名结构 (32B 形状) 向量 | 记录数组数据 {d@296, cap@304, c@308, alloc@312} | 32B 元/楼: level / partial_health / healthy_levels |
| +320..+336 | 78×8B 槽序数组 | {u32 槽序, u32 值} (全 (i,−1) 初始; cap=count=78 与 +296 平行) | 形态定案 ; 角色推定 槽→实例映射 |
| +344 | 匿名结构 (NB 形状)* 向量 | 自有槽实例数组数据 {cap@352, c@356, alloc@360} | 8B 元, **元素 stride = 512B** (活体 elem1−elem0 实测); 元素带 +480 块 / +64 i16, 求和场景; 虚析构逐个删 (高置信); **活体分布: 1035/1082 州非空, 总 2158 实例, 单州最大 8** |
| +356 | uint32 | 自有槽实例数组计数 | 高置信 |
| +368 | 匿名结构 (NB 形状)* 向量 | 第二数组数据 {d@368, cap@376, c@380, alloc@384} | 借用/视图; 元素: 等级 i16@+66 (>0 门), 类型 token@+8, 修正 def@+88 (def+528 = 名 SSO), 资源块 ptr@+480; 可见性谓词 sub_1409DA7B0 + 修正重建消费 (高置信形状, 名推定); GUI: 建筑修正图标来源 (r3 sub_14174C6F0) + B14 占领资源双列 (资源块+480 的 +764/+768 ×等级 i16@+64 ×100000, 再按占领国折减; sub_14155D120 — 双列名未定) |
| +380 | uint32 | 第二数组计数 | PEACE_COST 分解 sub_1409D2B20 亦读 |
| +392 | int32 | 类型旗 | ctor 6; 省份 def+210 &8 命中置 2 |
| +396 | uint32 | id | |
| +400 | int32 | 未名标量 | |
| +404..+407 | — | 尾垫 | |

#### 4.13.1 CResistance (内嵌 st+616, writer 0X140F9CCF0)

块门: 全部 ≠0 才写。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +16 | fixed×1e-5 | resistance | | GUI: StatusView 图标帧+百分比 (Update sub_14156E190, clamp 0..100) |
| +24 | fixed×1e-5 | resistance_speed | | |
| +32 | fixed×1e-5 | base_resistance_target | | |
| +40 | fixed×1e-5 | resistance_target | | |
| +41..+63 | — | = cr+8 CState* 回指 区尾 + compliance@+64 头 | | |
| +64 | fixed×1e-5 | compliance | | GUI: StatusView 图标帧+百分比 (Update sub_14156E190) |
| +72 | fixed×1e-5 | compliance_speed | | |
| +80 | tag_id | occupied_country_tag | | GUI: 占领面板数据门 (cr+80>0; 0X141566650 → occmgr 链) |
| +81..+111 | — | = compliance 值区尾 + 「LOCAL_COMPLIANCE」CModifier@cr+88 头 (串 ctor 直写; pairs pdx@cr+104) | | |
| +112 | 匿名结构 | compliance_modifiers 容器数据指针 {data@+112, count@+124} (kr2 定案) | writer 从不读 +112..+127 | ⚠ compliance_modifiers {+112,+124} 系对该 CModifier pairs 错位 8B 误读; save 端 compliance_modifiers 名单 = cr+552 (15747) |
| +113..+123 | — | = pad | | |
| +124 | u32 | compliance_modifiers 容器计数 | | |
| +125..+519 | — | = LOCAL_COMPLIANCE CModifier 体 (cr+88..+279) + 「LOCAL_RESISTANCE」CModifier@cr+280 (st+896) 体至 cr+519 — 均按 §4.3.8 通用表读; 内含名单容器 +472 (10441) / +496 (10442) | | +472/+496 GUI: Update 状态行 (size 枚举分族) |
| +520 | uint8 | operational_status | 仅真值写 | GUI: StatusView Update 显示门 |
| +528 | 8B 指针 向量 | resistance_modifiers 名单 (15743) {data, count@+12} | | 元 8B 指针→名 SSO@+16 (writer 0X140F90BF0); GUI: occupation_modifier_entry 修正行 |
| +552 | 8B 指针 向量 | compliance_modifiers 名单 (15747) | | UI 直消费: Update 修正行源 (定案) |
| +576 | CPersistent* 向量 | active_actions {d@576, cap@592, c@588, alloc@600 推定} — 块键 **15762**, 元素 **40B 多态 CPersistent 后代** (sub_1424C24F0 = 元素自身 vt[1] 自序列化, 尾原子 16; 类名待裁) | reader case 15762 → sub_140F904E0; 失效清理 sub_140F9AD20 (`*(elem+8)==0` → sub_140F9C760 swap-remove); dtor sub_140F91330 | 基线档恒空 (count==0 时 writer 跳过), 故存档中不出叶 |
| +600 | 匿名结构 | added_resistance_targets 容器数据指针 {data@+600, cap@+616, count@+612, alloc@+620} (dtor sub_140F91330 四件套互证) | 容器非空 (count>0), 与占领数值无关 | ⚠ 勿嵌 has_r 数值门 (曾致缺 25 州×4 叶); writer 0X140F9CCF0 块键 19093; 元素 72B (0X140F9D2B0) 见下条目子表 |
| +601..+611 | — | = added_resistance_targets {c@612} 头 + force_enable {d@624} 前 pad | | |
| +612 | u32 | added_resistance_targets 容器计数 | | |
| +613..+623 | — | = added_resistance_targets {c@612 尾, alloc} + force_enable_resistance {d@624} 头 | | |
| +624 | 匿名结构 | force_enable_resistance 容器数据指针 {data@+624, cap@+640, count@+636, alloc@+644} | reader = sub_140F9B830 case 19106 分支 (自定义内联读, 非通用容器 reader) | 块键 19106; tid=0 合法 |
| +625..+635 | — | = force_enable_resistance {cap@632, c@636} | | |
| +636 | u32 | force_enable_resistance 容器计数 | | |
| +637..+647 | — | = force_enable {alloc} + force_disable_resistance {d@648} 头 | | |
| +648 | 匿名结构 (8B 对) | force_disable_resistance 容器数据指针 {data@+648, count@+660} | 容器非空即写 (独立于数值门, 全零阻力州也落) | 元素 8B {key tag_id@0, value tag_id@4}; tid 0 渲染 "---" (writer 块名走变量非字面量; 州 996/459/460 探针定案) |
| +649..+659 | — | = force_disable_resistance {cap@656, c@660} 头 | | |
| +660 | u32 | force_disable_resistance 容器计数 | | |
| +696 | u8 | 脏旗 (add/set_compliance 直写 1) | 不序列化 | 推定 |
| +720 | — | 标度 100000 | | 728B 全长尾 |

added_resistance_targets 条目 (72B, 0X140F9D2B0):

| 偏移 | 类型 | 名称 | 写门 |
|---|---|---|---|
| +8 | uint32 | id | ≠0 |
| +16 | fixed×1e-5 | amount | 恒写 |
| +24 | int32 | days | ≠−1 |
| +28 | tag_id | controller | >0 |
| +32 | tag_id | occupied | >0 |
| +40 | string | tooltip | len@+56 ≠0 |

**(国,州) 占领数据对象 (无独立 RTTI 类 — 负定案)** — sub_140FF3BE0(占领mgr, cr+80) 取得;
set_garrison_strength 链锚定 (§4.32 卡):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +216 | 匿名结构 (24B 槽) 哈希表 | 24B 槽哈希表 {table@+216, mask@+228, spare@+232}; 键 = 州 id (FNV 73244475) | 推定 |
| +228 | u32 | 上表 mask | 推定 |
| +232 | u32 | 上表 spare | 推定 |
| +240 | fixed×1e-5 | garrison override 现值槽 | 推定 |
| +256 | fixed×1e-5 | garrison override 基值槽 (+240/+256 双写同值) | 推定 |

#### 4.13.2 CVariables (脚本变量; 指针 st+2040, writer 0X140BC9280)

| 偏移 (vowner) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +24 | 匿名结构 (桶) RH 桶数组 | RH 桶数组数据指针 (空表 = 静态哨兵 &unk_1430851A0) | 定名: CVariables 全长 56B: vt@0, **random 种子对 +8/+12** (写门 `ru32(+8) != 1`, ctor=1; 写形 `random={ <+12> <+8> }` 反序, writer 0X1424C5B10), count@+32, mask@+36, extra u8@+40, max_load_factor f32@+44=0.9, **尾槽 qword@+48 = 宿主变量域注册表指针** (ctor sub_140BC5BD0 `*(a1+48)=a2`; CCharacter 域 &unk_14333C980 / CState 域 &dword_143339B60 / CCountry 域 &unk_143330CE0 / CGameState 域 &dword_14332F2A0 — 非「恒 0」) |
| +32 | u32 | 数据数组 count (五处互证: 段 / RH 迭代 / 对象层) | |
| +36 | u32 | RH mask | |
| +40 | uint8 | extra (尾部溢出桶数) | 遍历上界 = mask + 1 + extra (缺 extra 即丢尾部条目) |
| +44 | f32 | RH max_load_factor = 0.9 (0x3F666666=1063675494; ctor 常数互证) | |

RH 扫描防御界 = 具名界 `M.lim.PTR_HUGE` (65536, RH 扫描类; 对象层
variables73 maxn = LAYOUT.lim.PTR_HUGE)。

条目布局 (0x30):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | uint32 | hash | |
| +4 | uint8 | dist | 过滤: dist∈{0, 0xFE, 0xFF} 全跳 — 只滤 0xFF 时空桶残留字节会被读成乱码名 (实证 36 叶脏名); 0xFE 墓碑实证见 §4.3 apd RH map |
| +8 | string | key (SSO) | |
| +9..+39 | — | = key MSVC SSO 32B 本体 (+8..+39) | |
| +40 | int64 | value (×1e-5) | |

空表特征 = data@vo+24 = 静态空桶哨兵 &unk_1430851A0 (BASE+50778528),
mask@vo+36 = 0; 无门遍历会把 .rdata 静态区编译时间戳串当变量名 (⚠ 陷阱)。
发射/遍历前任一命中即整块跳过 (与 writer 空表省略对齐):

| 闸门 | 判别 |
|---|---|
| ① | rp(vo+24) 非 kptr |
| ② | data == BASE+50778528 (&unk_1430851A0) |
| ③ | mask == 0 或 mask > 8192 |

内嵌基址用法: vo = 宿主字段本体 (不是 rp(字段))。

#### 4.13.3 CFlagManager (脚本旗标; 指针 st+1344)

vt 0X14295BB98; writer 0X140CBFFC0; 条目类 = **CScriptFlag** 48B (0x30); {data@+8, cap@+16, count@+20, alloc@+24} 标准四元组。
**同族第二宿主**: career profile wrapper+2448 (§4.1.11) / MIO org +504 (§4.8.11) — 布局同本表, 仅宿主与写序差异。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 匿名结构 | entries 容器数据指针 — {data@+8, cap@+16, count@+20, alloc@+24} (标准四元组) | 条目 0x30, 下表; 写点 = 旗标集 sub_1409D1510/sub_1409D1660 家族经 sub_14012B520 插入 |
| +20 | u32 | entries 容器计数 | 条目 0x30, 下表 |

旗标条目布局:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | token id | lexer token (非 FNV); 合法界 <100000 |
| +9..+23 | — | = token@+8 尾 + pad (条目 0x30B {token@8, date@24, value@40, expiry@42}) | |
| +24 | uint32 | setdate (绝对小时) | 探针定案: flags.<name>.date 源; CGameDate 公式直接转 (+42 expiry 读法系误) |
| +25..+39 | — | = setdate@+24 尾 + pad | |
| +40 | int16 | value | |
| +42 | int16 | expiry | |

#### 4.13.4 SDynamicModifierEntry (动态修正条目; 容器内嵌 st+1928, 条目 64B, writer 0X1406127C0)

容器 = st+1928 {data@+1968, count@+1980}; 块门 = 非空 (主表 +1928 行)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | tag_id | tag | |
| +12 | uint32 | state | >0 才写 (GER 条目全 0 无 .state 叶, kr1 2 州有值 — 非「所在州 id 回显」) |
| +16 | int32 | days (键 10605, i32 ≥0 才写) | 定案 (基准词元 + 探针 58/139 同向); 旧「附加」双读行删 |
| +16 | uint32 | days | 探针 s70=58/s71=139 全命中 |
| +24 | — | def 指针 | 名 SSO@def+40 (cap@+64; loc 键 = 名+"_desc"); 键 10597 "modifier" |
| +32 | uint8 | enabled | AE850 恒写 |
| +40 | fixed×1e-5 | value 容器数据指针 — 定点数组 {data, count<64} | |
| +41..+51 | — | = value 容器 {d@40, cap@+48, c@52} 内部 (pdx 四元组) | |
| +52 | u32 | value 容器计数 | |

条目写序 = modifier → state → tag → value → enabled → days。

#### 4.13.5 active_targeted_modifier (RH 表 st+2280)

双形态:
- 形态 A (指针数组 → SDynamicModifierEntry): **否定删除 ** — 主表行正确:
  15754 块元素 = 内联 32B 多态对象 (writer 逐条调元素自身 vt[1] Save, 步长 32B,
  原子 18 填充 + 块尾原子 16); 仅形态 B 成立。
- 形态 B (RH 表 @+2280):

| 偏移 | 类型 | 内容 |
|---|---|---|
| +8 | RH 桶数组* | data |
| +16 | uint32 | mask |
| +20 | uint32 | count |

条目 208B:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +4 | uint8 | dist | ⚠ dist==0 空桶必须跳过 — state 510 崩溃源 |
| +8 | tag_id | tag_id | |
| +9..+31 | — | = tag@+8 尾 + 桶内垫至值对象指针@+32 (桶 {dist@4, tag@8, ptr@32}) | |
| +32 | 匿名结构 (NNB 形状) | 值对象指针 (vtable 0x2A0125D0) | 值对象内两对 {token uint32@+0, value fixed×1e-5@+8} stride 16 (token 27=amphibious_invasion_defence, 254=planning_speed); 尾部 name/data 即存档 added_modifier 块 (writer 双写); vtable 0x2A0125D0 (RTTI 无名) |

added_modifier 定案: 值对象 = entry+16, 即 CAddedModifier (writer 0X140612640, 递归同类) —
**其 192B 全布局 (base pairs@+16 / children@+40 / name@+88 / custom_modifier_tooltip@+120 / hidden_modifier@+152 / data@+188 等) = §4.3.8 (权威, 勿重述)**;
本槽特有: name 由创建时 0X140F3F900 合成缓存 (非写时合成), 写门 size>0。

#### 4.13.6 CStrategicResourcePool (内嵌 st+440; 条目 writer sub_14055F700)

同类亦见 faction+2320 / facsys+56 宿主 (vt 0X29515A0, 元素 writer 0X140BCCAF0); 写序 = 向量序 = 资源定义序 (oil/aluminium/rubber/tungsten/steel/chromium/coal)。

176B (st+440..+615); save 实名 resources (token 11842, `steel=8` 实拍);
条目落盘门两级: **块级** = 至少一个条目 value > 0 才整块写 (writer 0x1409D4040
skip-scan; 只欠不存的州整块无叶实证); **条目级** = 块写后 value ≠ 0 全发,
i64 负欠额照写 (food=-14 与 oil=1 同块实证; KR 州 310 aluminium=-45 系该州
无正条目整块未写, 非「负值不写」)。读侧 i64 负数须有符号还原。

| 偏移 (st) | 类型 | 名称 | 备注 |
|---|---|---|---|
| +448 | 匿名结构 (NNB 形状)* | hybrid head | |
| +456 | u32 | cap | |
| +460 | u32 | count | |
| +464 | 匿名结构 (NNB 形状)* | allocptr | |
| +472 | — | hybrid vt | |
| +480..+607 | — | 内联 buf 8×16B CStrategicResourceAmount {value i64@+0, token@+8} | 量按 资源 def+216 = 州内资源索引 取; 资源 def+240/+244 = per-res modifier id 对 (加值/因子) |
| +608 | 匿名结构 (NNB 形状)* | fallback | |

stateDef+248/+260 = 静态资源条 16B 数组 {量@0, res_id@8} (CState+48 = stateDef 再证)。

#### 4.13.7 州历史条目族 (CStateHistoryEntry 系; 开局装载, 大多不重存)

族基 = **CStateHistoryEntry** (72B, vt 0x1429DB5B8, [13]=10304 province, writer 0x1415A2170 / reader 0x1415A17C0 工厂) ← CHistoryEntry (§4.31.37: [13] 纯虚 GetToken / [17] Apply) ← CPersistent。容器 = **CStateHistory** (vt 0x1429DB900, +64 = CState*; writer 0x141540FF0 与国史容器共用 — 双分支: 条目+48≠0 → 写日期键块, 否则调条目 vt[1])。族契约: +32 子条目侵入链表 / +48 u32 写门 / +64 宿主 (州条目 = CState*, 国条目 = 国 tag id) / 装载执行即弃 (国史侧负定案 §4.3 同族)。工厂 reader 0x1415A17C0 分派: 10302→OwnerChange / 10303→ControllerChange / 12121→SetStateBuildings / 12156→SetStateVictoryPoints / 默认→CHistoryAddEffectState。

| 类 | vt | [13] token | 布局 | Execute (vt[17]) / 重存 |
|---|---|---|---|---|
| COwnerChange | 0x1429DB660 | 10302 owner | 0x58: +72 tag id | sub_1409DE560(州, tag, 0) + sub_1409DDA40 同步 controller + sub_1409DFC20 收尾; 重存 vt[1]=0x1415A2130 (owner = "TAG") |
| CControllerChange | 0x1429DB708 | 10303 controller | 0x58: +72 tag id | sub_1409DDA40(州, tag, 1, 0); 重存 vt[1]=0x1415A20F0 |
| CSetStateBuildings | 0x1429DB7B0 | 12126 set_buildings | 0x70: +72 容器 {d@72,c@84} 136B 元 (**州历史建筑条目 = {省 id, 建筑 token/def 索引, u16 等级}** — 消费链 sub_1415A0D80 → sub_140687B90 → sub_141179050 → sub_141172EB0 → sub_1410DC4E0(cb, *(u16*)(elem+40), flag); **元素无独立 RTTI — 负定案**) + +96 rb-tree 省建筑组表 | 0x1415A0D80 两段循环落州 (statehistory.cpp:270/306/315 错误串); vt[1]=空桩 **不重存** |
| CSetStateVictoryPoints | 0x1429DB858 | 12156 victory_points | 0x50: +72 省 id / +76 VP 数 (工厂 "takes 2 parameters" 直证) | 0x1415A1220 → sub_140E810F0(省, +76); vt[1]=空桩 不重存 |
| CHistoryAddEffectState | 0x1429DB9A8 | 89 effect | 0x150: +72 CEffect 列表 + +160 scope 子对象 (注入 *(state+160) 州 id) | 0x14153FF80 (与国变体共享) 重放效应; vt[1]=空桩 不重存 |

#### 4.13.8 CResistanceActivityLog (驻军/抵抗活动日志条目; vt 0x142984888)

CPersistent 真 writer/reader (0x141000640 / 0x140FFBF80); 宿主容器 = occmgr+256 驻军活动日志 (GUI 消费锚 = §4.31 占领域行件)。

| 偏移 | 类型 | 键 (token) | 备注 |
|---|---|---|---|
| +8 | u32 tag id | country (10394) | 行为国 |
| +16 | CState* | state (439) | 写 = *(state+88) 州 id; 读 = gs 州数组反查 |
| +24 | CGregorianDate 内嵌 | date (10314) | 日期 |
| +48 | u8 | garrison (10536) | 驻军旗 (推定) |
| +56 | 匿名结构 (16B 形状) 向量 | manpower (10300) | {data, count@+76}; 元素 16B {tag, amount} |
| +88 | 匿名结构 (NNB 形状) | equipment (12110) | 装备块 |
| +152 | CResistanceActivity* | resistance_activity (15757) | 读 = 名串查 idb resistance_activity (§4.26.4); 写 = def+8 名串 |

> **本域 GUI 类布局**: 见 4.30.1。
