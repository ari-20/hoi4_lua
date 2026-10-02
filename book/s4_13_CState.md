

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
| +72 | uint32 | name size (写门字段) | | SSO 内部 |
| +80 | uint32 | name cap | SSO 内部 (writer 不触) | |
| +81..+87 | — | = name 串 cap 的高 4B (cap 实为 8B size_t; 串 {buf@56, size@72, cap@80}) | | |
| +88 | uint32 | state id | 断言 "Strategic location already exist in state: %d" (sub_1409D18B0); CVariables 以 +88 重注册; SetOwner 通知构造 | |
| +89..+107 | — | = state id@88 尾垫 (+92..+95) + 监听对象数组 {data@96, cap@104, count@108, alloc@112} 头 (owner/controller 变更通知: SetOwner 逐元 vt[+24](elem, st, &tag); 元素类名定案 = **CProductionStatus**; ⚠ 元素指针 = CProductionStatus 的 **CStateListener 基子对象 (+16)** 而非对象首址 — 活体首 qword 0x2970788 = 该子虚表 (三虚表 0x142970708/0x142970758/0x142970788 之三; 基链详见 §4.8 头注); SetOwner 逐元 vt[+24] = 该子虚表槽的派生覆写; 归属未决 — 非任何 cc+3944, +656 反指=0; 消费全定案 (SetOwner sub_1409DE560 逐元 vt[+24](elem, st, &tag) / SetController sub_1409DDA40 整段复制 / Reset 清 count); 注册点未定位 (0x1409D 段内 `sub_1401205A0(...+96)` 0 命中, 推定内联在 province 侧 CProductionStatus 创建路径); **活体分布 = 1081/1082 州 count=1 (每州恰 1 个监听者; 元素 RTTI 直证 CProductionStatus; +656 反指=0 复现)**) | | |
| +108 | uint32 | 监听数组计数 | +120 空时 Reset 置 0 (sub_1409D6BF0; 高置信) | |
| +109..+119 | — | = 监听数组 {count@108, alloc@112} + CStateHistory* 外置指针@120 头 (非内嵌; 外置对象 {head, cap, count, alloc}, 条目 32B 见下子表) | | |
| +120 | 匿名结构 (NNB 形状) 向量 | 州历史条目向量 (CStateHistory 族, 业务名推定) | 32B 条 (见下子表), 独立 allocator; Reset 扩容插入 {2,0,1,0} 迁移 (容器形态定案) — 非「动态修正容器」(旧同名异偏移系误名) | |
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
| +220 | uint32 | contested_owners 容器计数 | | |
| +221..+263 | — | = contested alloc@224 尾 + 匿名 32B MSVC 串@232..263 {buf@232, size@248, cap@256} (不序列化、Reset 不清; GUI 定案用途 = state_name 回退源 — size@+248≠0 时第二优先, sub_1409D91D0) + previous_owner {d@264} 前 pad | | |
| +264 | tag_id | previous_owner 容器数据指针 | {data, count} 4B tag id (11290; 战速换主才出现) | |
| +265..+275 | — | = previous_owner {d@264, cap@272, c@276, alloc@280..287} 内部 (SetOwner contains+push 维护) | | |
| +276 | uint32 | previous_owner 容器计数 | Reset 置 0 | |
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
| +1344 | CFlagManager* | 脚本旗标 | 过期递减 = sub_140CBFA90 flag_manager.daily (调用点 = states.daily, 非 SetOwner); 见 §4.13.3 | |
| +1352 | 内嵌块 | 州资源消耗块基 (真 CModifier 192B: vt@1352, pairs@1368, children@1392; 不序列化) | base pairs@+1368 16B 条 {token, value i64}; loc STATE_RESOURCE_COST "State Consumption" 按 token 查 | |
| +1368 | 匿名结构 (16B 键值对) 向量 | (+1352 块) base pairs 数据 | 与 +1736 块 pairs@+1752 同构 (base+16 关系) | 定案: +1352 = 真 CModifier (vt + pairs 双证, 探针), +1368 = 其 base pairs 数据槽; 「内联默认 CModifier」读法否定 |
| +1381..+1543 | — | = 真 CModifier (192B)@1352 内部 — 按 §4.3.8 通用表即闭 | | |
| +1544 | 内嵌块 | 州生效修正块 (运行时合成, 非序列化) | 重建 sub_1409D54A0 (触发源 = CBuilding::SetLevel 级变 fan-out sub_1409DB480, §4.14.2): 清 +1560 → category 对象+96 修正 + +1736 脚本块 + 非-core owner/controller 占领修正 + 建筑 +88 + 每省 +480 条目 → sub_140557BF0(st+1928, st+1544) 施加; base pairs@+1560, children {d@+1584, c@+1596} | |
| +1596 | uint32 | (+1544 块) children 计数 | sub_1409E02C0 读 | |
| +1597..+1735 | — | = 真 CModifier (192B)@1544 (运行时合成生效修正) 内部 — 192B 恰到 +1736, 三块等距互证 | | |
| +1736 | 内嵌 CModifier | 州 modifier 块 (10597) | 全布局见 §4.3.8 通用表 (+64 回收池 / +88 name / +120 tooltip 串集合 / +152 hidden 集合 / +184 掩码 / +188 深度); base pairs {d@+1752, c@+1764} 16B 元 {mdef idx u32, i64×1e-5}, mdef 表 = *(BASE+53669264) 120B 行 token@+112; children {d@+1776, c@+1788}: added_modifier data=u32@child+188 (≠1 门), name=SSO@child+88, pairs {d@+16, c@+28} (writer 0X140612640; TGWR 脚本州修正) | |
| +1737..+1927 | — | = 州脚本修正 CModifier@1736 (带 vt, ctor a1[217]) 内部 — 192B 恰到 +1928 | | |
| +1928 | 匿名结构 (NNB 形状) 向量 | dynamic_modifier (15361) | 容器对象 (vt+8 自序列化), {d@+1968, c@+1980} 64B 条目 (§4.13.4); 块门 = sub_14060D020(st+1928) 为假 (非空) 才写 (CState writer 0X1409E0E90) | GUI: dynamic_modifiers_grid 行重建 (r1 sub_14174C8E0 逐条填格) |
| +1929..+1999 | — | = 动态修正容器 (72B) {…, data@1968, count@1980}; 空 = count@+52==0 (sub_14060D020 直读式) | | |
| +2000 | CEvent* 向量 | **州事件作用域待发 CEvent\* 队列** {d@2000, cap@2008, c@2012, alloc@2016} — 元素由事件管理器 sub_140A0D4E0 append; SetOwner 链 sub_1409D73E0 逐元 `sub_141180350(elem, *(st+2024))` 求值命中即 sub_140A0F4F0 投递, 投递后 count 清零 | 遍历点 sub_140443220; **「候选驻军/占领族」方向注销** (与 CStateGarrisonData 无关) | |
| +2012 | uint32 | 上述计数 | Reset 置 0 | |
| +2013..+2023 | — | = 通知表 {d@2000, cap@2008, c@2012, alloc@2016..2023} 内部 | | |
| +2024 | CEventScope* | **CEventScope\*** (0xB0; Reset 释放旧对象后 malloc + ctor sub_140535110 写 `&CEventScope::vftable`, 再 sub_14053B5F0(scope, *(*(st+48)+160), 1) 以 stateDef+160 州 id 设作用域) | 投递时作为事件作用域实参传入 sub_140A0F4F0 | |
| +2025..+2039 | — | = CEventScope*@2024 (176B, 州事件作用域 — ctor 即建, Reset 换新; SetOwner 配合发 on_state_owner_changed) 尾 + u32@2032 = id % dword_143336F50 (**州事件掷骰相位**: 每日州并行 worker 以 `id%N == gs+1156 年积日%N` 判定本州当日是否掷事件候选, N = dword_143336F50 低字节; §4.2.7) | | |
| +2040 | CVariables* | 州脚本变量 | RH 表, 见 §4.13.2 | |
| +2048 | 匿名结构 (8B 形状) 向量 | strategic locations 对数组数据 — 8B 条 {loc_id u32, value u32} | AddStrategicLocation sub_1409D18B0 实读 (重复断言含 +88 id; 1.5x 增长); 默认 value = 首省 +164 | GUI: 州侧 strategic locations 过滤 (条目 v4[1]==prov.id; r2 sub_1417507F0 — 第二 u32 = prov_id, tooltip 双名 getter 再证) |
| +2056 | uint32 | 上述容量 cap (1.5x 增长) | 定案 | |
| +2060 | uint32 | strategic locations 容器计数 | BUILDING/AMOUNT 消费者 sub_1409D96D0 互证 | |
| +2061..+2063 | — | = CVariables@2040 (56B) 尾 + hybrid 容器@2048 {head@2048, cap@2056=2, c@2060} 头 (**token 14786 = strategic_region_data** — 勘误: 原「victory_points 14786」错标, victory_points = 12156 且落别槽; 装载链 0x1409DBE00 case 14786 → 0x1409CF090 → 0x1409DB8A0 pair<CString,i32> 解析器 → 区名大小写不敏感 FNV-1a → 全局区名索引 off_1430C6DE0 → push {token, i32} 入 +2048) | | |
| +2064 | vtable | strategic locations allocator 对象 | 释放走 vtable+16 | |
| +2065..+2103 | — | = hybrid (CPdxHybridInlineBufferAllocator<pair<token,int>,2>): allocptr@2064→&+2072, 头 vt@2072, 内联 buf 2×8B {token, value}@2080..2095, fallback@2096..2103 — **宿主 = 州侧 strategic_region_data** (区名→token 对, 非胜利点) | | |
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
| +2200 | — | state_category | 指针→定义对象, 名 = 全 SSO@对象+24 (size@+40; 8B 内联读会截断为 "large_is" — 须全 SSO); 默认 = stateDef+360 | |
| +2201..+2207 | — | = state_category 定义指针@2200 尾 (8B) + _SubAreas std::map 哨兵@2208 头 | | |
| +2208 | std::map | _SubAreas 子区域 RB-tree | 断言原文 _SubAreas (sub_1409D71E0, state.cpp); 树遍历 sub_1409E2C80, 插入 sub_1401F6470 (断言锚定) | |
| +2209..+2223 | — | = _SubAreas std::map {哨兵@2208 (malloc 0x28 三自指), size u64@2216} 内部 | | |
| +2224 | CPersistent* 向量 | temporary_resource_list 容器数据指针 (块键 15754) | 元素 **32B 多态 CPersistent 后代** (逐条 sub_1424C24F0 = `(*(elem vt[1]))(elem, writer)` 即元素自身 vt[1] 自序列化, 尾原子 16; 非 dynamic_modifiers/SDynamicModifierEntry — 后者 64B); reader sub_1409CF450; Reset 逐条虚析构后清 count; **元素具体类名待裁 (无 RTTI 直证)** | |
| +2225..+2235 | — | = temporary_resource_list {d@2224, cap@2232, c@2236} (15754; 条目 32B 多态) 内部 | | |
| +2236 | uint32 | temporary_resource_list 容器计数 | | |
| +2237..+2247 | — | = temporary_resource_list {alloc@2240..2247} 尾 + 三 RH 表头全形 {qword@0 (ctor 未显式初始化), data@+8 = 空表哨兵 &unk_143090170, count@+16, mask@+20, extra u8@+24, lf f32@+28 = 0.9} (桶 208B); 对象尾 = +2344, 之后无字段 | | |
| +2248 | 匿名结构 (208B 形状) RH 桶数组 | per-tag 值对 RH 表 A | 208B 桶 {used u8@+4, key tag u32@+8, CModifier 内嵌@+16 (pairs 容器 {data@+32, c@+44} 16B 条 {token, i64}, 与 +2256 行同构)}; Reset sub_1409D70F0, tag 查找 sub_1409D8B10 (定案形态) | |
| +2256 | CModifier* RH 桶数组 | 每国州级 modifier 哈希表 | 桶 208B = {hash@0, dist u8@+4, tag@+8, **CModifier 内嵌@+16**}; 掩码@2268 / 空桶回退@2272; 命中谓词 = tag 相等 ‖ sub_140BB52F0 同原初国 | 定案: 桶载 CModifier 内嵌 (vt+357 签名 + pairs 四元组双证, 探针); 旧「值对数组」读法 = CModifier.pairs@+32 误位 |
| +2280 | 匿名结构 (208B 形状) RH 桶数组 | active_targeted_modifier RH 表 (布局 = {data@+2288, count@+2296, mask@+2300}, §4.13.5) | 见 §4.13.5 | |
| +2312 | 匿名结构 (208B 形状) RH 桶数组 | **pending_targeted_modifier** (键 19236, 同 +2248 形态) | 装载缓存 swap 对 = A(+2248)↔B(+2312) — 重建链 sub_1409D7760 把 data/count/mask/extra 四域成对换位; 旧「占领资源转移」语义注销 (占领折减公式实读 A 表, A 表键 = 州属主) | GUI: B14 占领资源折减 ((行值+100000)/100000; sub_14155D120) |

三 RH 表 (+2248 / +2280 / +2312) 表头均按 +2237..+2247 行全形落位, 对象内绝对偏移
= 表基 + 相对: A@2248 → data@2256 / count@2264 / mask@2268 / extra@2272 / lf@2276;
active_targeted_modifier@2280 → data@2288 / count@2296 / mask@2300 / extra@2304 /
lf@2308; B@2312 → data@2320 / count@2328 / mask@2332 / extra@2336 / lf@2340;
对象尾 = +2344。⚠ +2280 行旧互证读法 {count@2296, cap@2300} 与全形推导
(mask@2296 / count@2300) 不合 — 定案: 表头全形成立, **mask@2296 / count@2300** 。

**stateDef = CStateTemplate** (原「CStateDatabase 条目」正名; 464B = 0x1D0, Insert malloc(0x1D0) 直证; vt 0x1429434D0; ParseKey sub_140ABE640 12 token case; RTTI COL 0x1429434D0) — 锚定 = st+48 → 单例 qword_14332F070 (库本体 120B: 容器 A 州条目表 @40 按州 id 直接索引 {cap@48, count@52 含 null 槽, 活体 1082} / 容器 B 全局色表 @64 / 容器 C 大陆表 @88 / 有效条目计数@112, 活体 1081; null 对象 = qword_143339BA0):

| 偏移 | 类型 | 名称 | 键/备注 |
|---|---|---|---|
| +8 | u32 向量 24B | 省份 id 列表 (无效省报 "Province not valid" statetemplate.cpp:157) | 10288 provinces |
| +32 | SSO 32B | 本地化州名 (name 值经 localize 查询结果) | 27 |
| +64 | SSO 32B | 脚本原始 name 串 | 27 |
| +96 | 串 32B | 源条目主串 (推定 = 打开用路径) | 高置信 |
| +128 | 串 32B | 源条目次串 (冲突报错打印, 文件名样) | 高置信 |
| +160 | int32 | 州 id (ctor −1; A 表下标) | 11 |
| +168 | uint8 | 有效条目旗 (ctor 1; null 对象 0; CState 创建门/"Missing State ID" 校验) | — |
| +176 | CStateHistory (72B) 内嵌 | history 块 (键 10293 → vt[3]; +240 宿主槽) | 10293 |
| +248 | 向量 24B | 静态资源条数组 {d@248, cap@256, **count@260**, alloc@264}; 元 16B {量 i64@0, res_id u32@8} | 11842 resources |
| +272 | u32 向量 24B | **邻接州 id 数组** {d@272, cap@280, count@284, alloc@288} — PostLoad 并行 sub_140ABCB30 建 (本州各省 prov+112/+124 经 provdb+40 省→州映射聚合去重排自身); 消费端 GetNeighborState sub_1409DB740 / owner 变更连锁 sub_1409DFC20 / §4.32 触发器链 | 非 parse 键 (定案) |
| +296 | 向量 24B | impassable_ignored_links (省 id 列表; 非 impassable 州 PostParse 清零并警告 statetemplate.cpp:253) | 10749 |
| +320 | CContinent* | **大陆条目指针** (ctor = null 对象; PostParse 按首省 province+211 查容器 C 落位; 与 CStrategicRegion 无涉; 大陆 = map/continent.txt continents 块 7 条, 元 80B {名 SSO@8, 旗@40, id@44, 序号@48, 州表 vec@56}) | 非 parse 键 |
| +328 | int32 | 州中心 X (省 bbox prov+136 聚合, 跨日界线归一 sub_140ABCE00) | 非 parse 键 |
| +332 | int32 | 州中心 Y (同上) | 非 parse 键 |
| +336 | int32 | 州外接尺寸 = max(宽, 高) (「州够不够大」门: > 全局阈值 dword_1433356D0) | 非 parse 键 |
| +340 | int32 | manpower (0 报 "has no people living in it" :244; CState ctor 以之播种种群 st+2104) | 10300 |
| +344 | int32 | force_link_ownership_to (非 impassable 州 PostParse 强制清零并警告 :248; 指向国 tag 推定) | 19611 |
| +348 | uint8 | **impassable 旗** (直读 sub_1409DB3F0) | 11267 |
| +349 | uint8 | 海岸旗 (任一省 prov+210 & 8 则置 1, 两处重算) | 非 parse 键 (定案, 原推定升档) |
| +350 | uint8 | 单州岛旗 (全省陆旗且陆上邻省全属本州, sub_140ABD150) | 非 parse 键 (定案, 原推定升档) |
| +352 | fixed×1e-5 | buildings_max_level_factor (ctor 默认 1.0; 消费 = modifier 104 映射 /100000) | 13192 |
| +360 | CStateCategory* | 默认 category (null 对象默认; 名查 category 库 qword_14332F968, 缺失报 :242; CState ctor 抄到 st+2200) | 13848 |
| +368 | fixed×1e-5 | local_supplies (消费 ×全局常数/100000) | 12564 |
| +376 | CEffect (88B) 内嵌 | state_startup_effect (ctor 注册进全局 effect 注册表) | 10213 |

装载链 8 步: continent.txt → state_category → history/states 并行解析 Insert → colors.txt → 省→州映射 → 省份分配 → PostLoad 建链/旗 → 位置重算 → InitGameState malloc(0x928) 造州。
活体验证: 州 1000 与 vanilla 字面量逐项相符 (prov=5 / manpower=715857 / res=1 steel / 邻接 = {419,1001,420,230,229})。

**「CStateHistory 条目 (32B)」负定案 (原子表废)**: st+120 外置向量全 217MB 语料无任何堆指针写点、ctor 清 0 (sub_1409CFB10)、dtor 不管理、**活体 1192/1192 州恒 0**、CState writer 不发射 — 未用残槽。州史条目唯一真实结构 = §4.13.7 的 72B CHistoryEntry 族 (writer 0x141540FF0 双分支逐字吻合); CStateHistory (vt 0x29DB900) 内嵌 stateDef+176, +64 = 宿主回指 (活体 = stateDef 自身); 国史容器 = 72B 类 + tag@+72 + ptr@+80; st+96 监听数组 = 8B 监听器指针向量, 与 32B 无涉。

**CBuildingStatus (116B)** — 内嵌@st+288, save 实名 buildings (token 12121):

| 偏移 (st) | 类型 | 名称 | 备注 |
|---|---|---|---|
| +296 | 匿名结构 (32B 形状) 向量 | 记录数组数据 {d@296, cap@304, c@308, alloc@312} | 32B 元/楼: level / partial_health / healthy_levels |
| +320..+336 | 78×8B 槽序数组 | {u32 槽序, u32 值} (全 (i,−1) 初始; cap=count=78 与 +296 平行) | 形态定案 ; 角色推定 槽→实例映射 |
| +344 | 匿名结构 (NB 形状)* 向量 | 自有槽实例数组数据 {cap@352, c@356, alloc@360} | = **CBuildingStatus+56 视角 (st+288 内嵌)**: 州建筑元素数组 — 元素 = **CBuilding** (496B; +66 healthy_levels / +72 partial_health / +472 status 回指 / +480 def 回指; 定案), 活体 elem1−elem0 实测 512B (分配器取整); 核弹破坏链 sub_1410DC060 逐元素拆级 (def 免损旗门 +868/+883 族) 并尾调 sub_140E5F8C0 = **AddConstruction(repair=1) 修理线** (§4.8.5a); **活体分布: 1035/1082 州非空, 总 2158 实例, 单州最大 8**; 虚析构逐个删 |
| +356 | uint32 | 自有槽实例数组计数 | 高置信 |
| +368 | 匿名结构 (NB 形状)* 向量 | 第二数组数据 {d@368, cap@376, c@380, alloc@384} | 借用/视图; 元素: 等级 i16@+66 (>0 门), 类型 token@+8, 修正 def@+88 (def+528 = 名 SSO), 资源块 ptr@+480; 可见性谓词 sub_1409DA7B0 + 修正重建消费 (高置信形状, 名推定); GUI: 建筑修正图标来源 (r3 sub_14174C6F0) + B14 占领资源双列 (资源块+480 的 +764/+768 ×等级 i16@+64 ×100000, 再按占领国折减; sub_14155D120; **+764 = 军工产线数 NUM_TOTAL_MIL_FACTORIES / +768 = 民用产线数 NUM_TOTAL_CIV_FACTORIES** — tooltip OCCUPIED_COUNTRY_INDUSTRIAL_CAPACITY_TOOLTIP 参数绑定直证) |
| +380 | uint32 | 第二数组计数 | PEACE_COST 分解 sub_1409D2B20 亦读 |
| +392 | int32 | 类型旗 | ctor 6; 省份 def+210 &8 命中置 2 |
| +396 | uint32 | id | |
| +400 | int32 | 未名标量 | |
| +404..+407 | — | 尾垫 | |

#### 4.13.1 CResistance (内嵌 st+616, writer 0X140F9CCF0; 独立 vtable 0x14297e370)

块门: 全部 ≠0 才写。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +16 | fixed×1e-5 | resistance | | 每日 += +24 速度 (sub_140F980D5), 钳 [0,1e7], 无条件 (cr+520 门只管活动链); GUI: StatusView 图标帧+百分比 (Update sub_14156E190, clamp 0..100) |
| +24 | fixed×1e-5 | resistance_speed | 不序列化, 每日 sub_140F9BF90 重算 (速度公式 sub_140F94690) | |
| +32 | fixed×1e-5 | base_resistance_target | 不序列化; 每日 sub_140F9BF40: 先清 cr+48/56, 再 (include_flow=0, clamp=1) 单调 sub_140F959F0 抵抗目标计算体 (14 项加法公式), **同一返回值双写 +32 与 +40** (+40 = 基值重播种, 邻流随后 +=); cr+520 未置则双清 0 | |
| +40 | fixed×1e-5 | resistance_target | 邻州扩散落值 (sub_140F921A0: cr+40 += flow); 日更重播种 = 同上双写 | |
| +48 | CState* | 邻流源州 (扩散写入时记源; 内存形态 = CState* — 断言 "pState", 州 id 系 writer 折算视角; 目标公式 a3 分支同槽) | | |
| +56 | fixed×1e-5 | 邻流流量 (扩散写入值) | | |
| +57..+63 | — | = pad + compliance@+64 头 | | |
| +64 | fixed×1e-5 | compliance | | 每日 += +72 速度 (sub_140F980D5), 钳 [0,1e7], 无条件; GUI: StatusView 图标帧+百分比 (Update sub_14156E190) |
| +72 | fixed×1e-5 | compliance_speed | | |
| +80 | tag_id | occupied_country_tag | | GUI: 占领面板数据门 (cr+80>0; 0X141566650 → occmgr 链) |
| +81..+111 | — | = compliance 值区尾 + 「LOCAL_COMPLIANCE」CModifier@cr+88 头 (串 ctor 直写; pairs pdx@cr+104) | | |
| +112 | 匿名结构 | compliance_modifiers 容器数据指针 {data@+112, count@+124} (kr2 定案) | writer 从不读 +112..+127 | ⚠ compliance_modifiers {+112,+124} 系对该 CModifier pairs 错位 8B 误读; save 端 compliance_modifiers 名单 = cr+552 (15747) |
| +113..+123 | — | = pad | | |
| +124 | uint32 | compliance_modifiers 容器计数 | | |
| +125..+519 | — | = LOCAL_COMPLIANCE CModifier 体 (cr+88..+279) + 「LOCAL_RESISTANCE」CModifier@cr+280 (st+896) 体至 cr+519 — 均按 §4.3.8 通用表读; 内含名单容器 +472 (10441) / +496 (10442) | | +472/+496 GUI: Update 状态行 (size 枚举分族) |
| +520 | uint8 | operational_status | 仅真值写 | GUI: StatusView Update 显示门 ; 修正器重算总门 (sub_140F91850 首行 return) |
| +528 | 8B 指针 向量 | resistance_modifiers 名单 (15743) {data, count@+12} | | 元 8B 指针→名 SSO@+16 (writer 0X140F90BF0); GUI: occupation_modifier_entry 修正行 |
| +552 | 8B 指针 向量 | compliance_modifiers 名单 (15747) | | UI 直消费: Update 修正行源 (定案) |
| +576 | CPersistent* 向量 | active_actions {d@576, cap@592, c@588, alloc@600 推定} — 块键 **15762**, 元素 **40B 多态 CPersistent 后代** (sub_1424C24F0 = 元素自身 vt[1] 自序列化, 尾原子 16; 类名待裁) | reader case 15762 → sub_140F904E0; 失效清理 sub_140F9AD20 (`*(elem+8)==0` → sub_140F9C760 swap-remove); dtor sub_140F91330 | 基线档恒空 (count==0 时 writer 跳过), 故存档中不出叶 |
| +600 | 匿名结构 | added_resistance_targets 容器数据指针 {data@+600, cap@+616, count@+612, alloc@+620} (dtor sub_140F91330 四件套互证) | 容器非空 (count>0), 与占领数值无关 | ⚠ 勿嵌 has_r 数值门 (曾致缺 25 州×4 叶); writer 0X140F9CCF0 块键 19093; 元素 72B (0X140F9D2B0) 见下条目子表 |
| +601..+611 | — | = added_resistance_targets {c@612} 头 + force_enable {d@624} 前 pad | | |
| +612 | uint32 | added_resistance_targets 容器计数 | | |
| +613..+623 | — | = added_resistance_targets {c@612 尾, alloc} + force_enable_resistance {d@624} 头 | | |
| +624 | 匿名结构 | force_enable_resistance 容器数据指针 {data@+624, cap@+640, count@+636, alloc@+644} | reader = sub_140F9B830 case 19106 分支 (自定义内联读, 非通用容器 reader) | 块键 19106; tid=0 合法 |
| +625..+635 | — | = force_enable_resistance {cap@632, c@636} | | |
| +636 | uint32 | force_enable_resistance 容器计数 | | |
| +637..+647 | — | = force_enable {alloc} + force_disable_resistance {d@648} 头 | | |
| +648 | 匿名结构 (8B 对) | force_disable_resistance 容器数据指针 {data@+648, count@+660} | 容器非空即写 (独立于数值门, 全零阻力州也落) | 元素 8B {key tag_id@0, value tag_id@4}; tid 0 渲染 "---" (writer 块名走变量非字面量; 州 996/459/460 探针定案) |
| +649..+659 | — | = force_disable_resistance {cap@656, c@660} 头 | | |
| +660 | uint32 | force_disable_resistance 容器计数 | | |
| +680 | int64 | 法侧 MODIFIER_RESISTANCE_TARGET(478) 求和缓存 (st+1296; 写者 sub_1409E02C0 州修正重算 a3 出参) | 不序列化 | 定案 |
| +688 | int64 | 法侧 MODIFIER_REQUIRED_GARRISON_FACTOR(499) 求和缓存 (st+1304; 同上 a4 出参; sub_140F94100 驻军需求 a4=1 扣除项 = 驻军师自评口径) | 不序列化 | 定案 |
| +696 | uint8 | 脏旗 (add/set_compliance 直写 1; SetOccupiedCountry/历史重置首行直写 1) | 不序列化 | 定案 |
| +704 | int64 | 上次通知快照·抵抗 (变化检测: \|Δ\|≥1e5 或跨 0/满 → 快照更新 + cr+696 脏) | 不序列化 | 定案 |
| +712 | int64 | 上次通知快照·顺从 (同上) | 不序列化 | 定案 |
| +720 | fixed×1e-5 | 驻军强度比例副本 (每日重算 sub_140F91850 先置 100000, SGD+240 命中则覆写; 修正器重算按 cr+720/1e5 混合法侧与兜底法侧, mdef499 不缩放) | 不序列化 | 定案 |

added_resistance_targets 条目 (72B, 0X140F9D2B0):

| 偏移 | 类型 | 名称 | 写门 |
|---|---|---|---|
| +8 | uint32 | id | ≠0 |
| +16 | fixed×1e-5 | amount | 恒写 |
| +24 | int32 | days | ≠−1 |
| +28 | tag_id | controller | >0 |
| +32 | tag_id | occupied | >0 |
| +40 | string | tooltip | len@+56 ≠0 |

**(国,州) 占领数据对象 = CCountryOccupationData (定案, vt 0x142984928; §4.3.2 记录 dp 同一对象)** —
sub_140FF3BE0(占领mgr, cr+80) 取得; 即 §4.3.2 记录 dp (occ+96 列表条目 / occ+72 RH 值), 全布局见 §4.3.2 补行表:

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +216 | RH map | **CStateGarrisonData map** 桶数据 {count@+224, mask@+228, extra@+232}; 键 = 州 id (FNV 73244475); 条目 = SGD 264B (§4.3.2 布局表) | 定案 |
| +228 | uint32 | 上表 mask | 定案 |
| +232 | uint32 | 上表 extra | 定案 |
| SGD+240 / SGD+256 | fixed×1e-5 | garrison override 现值/基值 (set_garrison_strength 效果 sub_140FFE2F0 双写同值; 旧 +240/+256 推定行系 SGD 字段, 基址勘正) | 定案 |

#### 4.13.2 CVariables (脚本变量; 指针 st+2040, writer 0X140BC9280)

| 偏移 (vowner) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +24 | 匿名结构 (桶) RH 桶数组 | RH 桶数组数据指针 (空表 = 静态哨兵 &unk_1430851A0) | 定名: CVariables 全长 56B: vt@0, **random 种子对 +8/+12** (写门 `ru32(+8) != 1`, ctor=1; 写形 `random={ <+12> <+8> }` 反序, writer 0X1424C5B10), count@+32, mask@+36, extra u8@+40, max_load_factor f32@+44=0.9, **尾槽 qword@+48 = 宿主变量域注册表指针** (ctor sub_140BC5BD0 `*(a1+48)=a2`; CCharacter 域 &unk_14333C980 / CState 域 &dword_143339B60 / CCountry 域 &unk_143330CE0 / CGameState 域 &dword_14332F2A0 — 非「恒 0」) |
| +32 | uint32 | 数据数组 count (五处互证: 段 / RH 迭代 / 对象层) | |
| +36 | uint32 | RH mask | |
| +40 | uint8 | extra (尾部溢出桶数) | 遍历上界 = mask + 1 + extra (缺 extra 即丢尾部条目) |
| +44 | float | RH max_load_factor = 0.9 (0x3F666666=1063675494; ctor 常数互证) | |

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

#### 4.13.3 CFlagManager (脚本旗标管理器; 32B; vt 0X14295D3D8; writer 0X140CBFFC0 / reader 0x140CBFB80 / ctor sub_140CBF4A0; TU gameflags.cpp)

脚本旗标容器, 本体 32B {vt, data@+8, cap@+16, count@+20, alloc@+24}; 条目类 =
**CScriptFlag** 48B。序列化槽 [1] writer (开闭块内联, 无独立 Save wrapper) /
[3] reader (解析循环本体) — 与 §4.00.1 CPersistent 标准四槽契约不对称 ([2] = CFG 空桩
0x14012A2C0; [4] = 0x1424BEC40 "Unexpected token" 异常 thunk, 即 reader 默认分支通用件), 派发协议层解释待裁, 不影响布局。reader 键 = 条目名串
(经 sub_1424BB460 转 token) + 776 value / 10314 date / 10605 days。

| 偏移 | 类型 | 名称/语义 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | 0x14295D3D8 | — | vt_rtti + dump vftable 写点 5 处 + 逐槽函数地址核对, 三路互证 |
| +8 | CScriptFlag* | entries 容器数据指针 | count>0 | 标准四元组 {data@+8, cap@+16, count@+20, alloc@+24}; 写点 = 旗标集 sub_1409D1510/sub_1409D1660 家族经 sub_14012B520 插入 |
| +16 | uint32 | entries 容器 cap | — | find-or-insert 增长 max(count+1, cap×1.5) 经分配器虚槽重分配 |
| +20 | int32 | entries 容器 count | 写 (writer 循环界) | 块键 `flags` (10697) 由宿主 writer 写; count=0 = 空块无叶 |
| +24 | 匿名结构 (分配器)* | 条目数组分配器 | — | 空表 = 静态哨兵 off_143085170; 释放走其虚槽[+16] |

旗标条目 CScriptFlag 布局 (48B; 偏移相对条目基址):

| 偏移 | 类型 | 名称/语义 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | 0x142721338 | — | find-or-insert 写点 |
| +8 | uint32 | token id (条目名) | 键名 | lexer token (非 FNV), 合法界 <100000 |
| +16 | CGameDate 内嵌 (24B) | setdate 日期对象 {vt1@+16, hours@+24, vt2@+32} | 键 10314 date (writer 从 +32 基槽写) | ctor 哨兵 43808760 ("1.1.1.1") 直证; `.date` 叶源 = hours@+24 |
| +40 | int16 | value | 键 776 | setter sub_140CBFED0 (u8/days i16≤0→-1) / sub_140CBFEA0 (i16/days 仅 >0 写) |
| +42 | int16 | days (token 10605) | >0 才写 | 语义 = 持续天数, ≤0 → -1 = 永久 |

条目级叶 = `flags.<名>.value / .date / .days`。辅助机制: find-or-insert
sub_140CBF6D0 (线性查 token@条目+8, 满则 1.5× 增长, 新条目就地构造); 删旗
sub_140CBFE60 → swap-remove sub_140CBFF10 (末条目载荷 {token@+8, hours@+24,
value@+40, days@+42} 搬入被删槽, 末条目虚 dtor 后 count--)。

同族宿主 (ctor 写点实证; 布局同本节, 仅宿主与写序差异):

| 宿主 | 形态 | 挂载点 | 书内位置 |
|---|---|---|---|
| CGameState | **堆指针** (对象 malloc 0x20) | gs+600 (gs ctor sub_1401BFD30 `a1[75] = v12`) | §4.1.1 |
| CState | 堆指针 | st+1344 | 本节头行 |
| CCountry | 堆指针 | cc+560 (ctor sub_1406C9CC0 内堆分配) | §4.3.1 |
| CCharacter | 内嵌 32B | ch+272 (ctor sub_140F9EC50 直构) | §4.4 |
| career profile wrapper | 内嵌 32B | wrapper+2448 (ctor sub_1401B1790) | §4.1.9; 块恒写 count=0 空块无叶, 键走 token_name (`career_profile_overrun_*_flag` 16025/16028 实证; ⚠ 勿裸用 SL.tok 数字回退) |
| MIO organisation | 内嵌 32B | org+504 | §4.8.11 |
| NProject::CProject | 内嵌 32B | project+368 (拷贝 ctor sub_140FDFCE0 写 vftable + 主 ctor sub_140FE0070 直构) | §4.19 (项目域) |

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
| +52 | uint32 | value 容器计数 | |

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
| +16 | CAddedModifier (192B) 内嵌 | 值对象 = CModifier 内嵌@+16 (vt 写入 + key2 idpair 第二 u32@+24; writer sub_1424C24F0 收桶+16) | 定案 |
| +32 | 匿名结构 (16B 形状)* | = 内嵌 modifier 的 base pairs 数据槽 (16B {mdef idx u32, i64×1e-5} 对; token 27=amphibious_invasion_defence, 254=planning_speed) | |

added_modifier 定案: 值对象 = entry+16, 即 CAddedModifier (writer 0X140612640, 递归同类) —
**其 192B 全布局 (base pairs@+16 / children@+40 / name@+88 / custom_modifier_tooltip@+120 / hidden_modifier@+152 / data@+188 等) = §4.3.8 (权威, 勿重述)**;
本槽特有: name 由创建时 0X140F3F900 合成缓存 (非写时合成), 写门 size>0。

#### 4.13.6 CStrategicResourcePool (内嵌 st+440; 块级 skip-scan 内联于 CState writer sub_1409E0E90, 元素 writer 0x140BCCAF0)

同类亦见 faction+2320 / facsys+56 宿主 (vt 0X29515A0, 元素 writer 0X140BCCAF0); 写序 = 向量序 = 资源定义序 (oil/aluminium/rubber/tungsten/steel/chromium/coal)。

176B (st+440..+615); save 实名 resources (token 11842, `steel=8` 实拍);
条目落盘门两级: **块级** = 至少一个条目 value > 0 才整块写 (CState writer
sub_1409E0E90 内联 skip-scan; 只欠不存的州整块无叶实证); **条目级** = 块写后 value ≠ 0 全发,
i64 负欠额照写 (food=-14 与 oil=1 同块实证; KR 州 310 aluminium=-45 系该州
无正条目整块未写, 非「负值不写」)。读侧 i64 负数须有符号还原。

| 偏移 (st) | 类型 | 名称 | 备注 |
|---|---|---|---|
| +448 | 匿名结构 (NNB 形状)* | hybrid head | |
| +456 | uint32 | cap | |
| +460 | uint32 | count | |
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
| +8 | uint32 tag id | country (10394) | 行为国 |
| +16 | CState* | state (439) | 写 = *(state+88) 州 id; 读 = gs 州数组反查 |
| +24 | CGregorianDate 内嵌 | — | 不落盘 (另一颗运行期日期; 序列化 CGameDate 在 +40) |
| +40 | CGregorianDate 内嵌 | date (10314) | 日期 (writer/reader/ctor 三证) |
| +48 | uint8 | garrison (10536) | 驻军旗 (推定) |
| +56 | 匿名结构 (NNB 形状) | — | CArmyManpowerValues 域形 {vt@+56, data@+64, cap@+72, count@+76, alloc@+80} |
| +64 | 8B 对 向量数据 | manpower (10300) | 元素 8B {tag u32, amount u32} |
| +88 | 匿名结构 (NNB 形状) | equipment (12110) | 装备块 |
| +152 | CResistanceActivity* | resistance_activity (15757) | 读 = 名串查 idb resistance_activity (§4.26.4); 写 = def+8 名串 |

> **本域 GUI 类布局**: 见 4.30.1。

#### 4.13.1a 抵抗活动执行体 (cr+576 active_actions 定名)

**元素定名 (定案)**: cr+576 active_actions 40B 元素 =
**CResistance::SActiveResistanceAction** (vftable 符号 + RTTI COL 双证, vt
0x14297e2d0) — 无行为槽纯数据条目: {CResistanceActivity*@+8, pdx vector\<int\>
倒计时列表@+16 {cap@24, count@28, alloc@32}}。writer 0x140F9D1E0 / reader
0x140F9BD90, 落盘 = `action(10546)="名" days(10605)={int…}`。

周期消费 (定案): 占领管理器日更 sub_140FF7170 与全局日更 sub_140A74A50 双路
逐州调 **CResistance::DailyUpdate sub_140F98050** — int 逐日自减 / 到期移除 /
列表空则整元素移除+置脏, 随后掷选。**触发链 sub_140F97920 三道门**:
① 发生率门 (rand1 < resistance%×0.312, 严格 <,
RESISTANCE_ACTIVITY_CHANCE_AT_MAX_RESISTANCE) → ② 渗透率门 (rand2 ≤
(1e5−驻军强度)×(1+Σmdef496 三源)/1e5, 含等号, 下限 0.02 =
RESISTANCE_ACTIVITY_MIN_GARRISON_PENETRATE_CHANCE, 钳 [0,1e5]; 门②失败仍走
sub_140F92710(0)) → ③ rand3 加权选中 (候选收集
sub_140F94490: allowed/weight/days/max_instances 四 def 访问器 + 现有实例数
并发检查)。**执行体 sub_140F98340** = 发 "siegeinfo" 通知 (BestVP 省 id) +
def+184 内嵌 CEffect vt[12] 执行效果块 + days>0 入队 (按 def 查重复用);
sub_140F92710/sub_140FF4D30 = 驻军人力/装备损耗结算 + resistance_attack_log。

活动门补充 (定案): 门② 值 ≤0 → 直通 (可达条件 = MIN define ≤0); 门① 基率 ×(1+Σ MODIFIER_RESISTANCE_ACTIVITY_FACTOR(505) 三源)/1e5。活动修正器生效门 = def+408>0 或 def+324≠0 直通, 否则 def+288 修正器 id 列表 (计数@+300) 须有 id 过游戏规则检查 sub_14055F700 (规则表 qword_14332ED90+120×id, `!(e+104) ‖ flags&(e+104)`); 倍率 = ×(elem+28 实例数)。触发链 scope 链 = state→controller→occupied 三 scope FROM 链 (eventscope.h:193 断言 ×3); sub_140534F00(state_scope) 为执行体第三参。SetOccupiedCountry (sub_140F9B050) 起始值 = INITIAL_STATE_* + 协作政府 (COMPLIANCE_PER_COLLABORATION max 项) + Σmdef484(COMPLIANCE_STARTING_VALUE)×100 三源, 尾置 cr+520。

副产: cr+8 = CState* 回指 (定案); added_resistance_targets 72B 条目 =
CResistance::SAddedResistanceTarget (vt 0x14297e320, reader 0x140F9BEB0 键表
全解); CResistanceActivity def 912B 七字段访问器链; gs+2617 = 抵抗系统启用
旗 (与 §4.1「HasGameStarted」同槽); 消费面 = has_active_resistance 触发器
(0x1427b3470, 被占领∧未平定 target<10) + 特工任务前置校验 + GUI 活动列表
(sub_140F9A200, RESISTANCE_ACTIVITY_LIST_* loc)。
