

### 4.15 战略空军族 (CStrategicAirManager → CStrategicAir → CAirWingPool → CAirWing)

> 坐标注: 本册表内偏移一律 = 书基坐标; 运行时方法 this = 书基−16 (raw)。
> 换算仅在此注, 正文只用书基坐标。

mgr = *(gs+1680); 两级结构 pool → wing (定案)。

#### 4.15.1 CStrategicAirManager (mgr = *(gs+1680); vtable 0X29588F8)

| 偏移 (mgr) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | CNonstaticIdGenerator\<77\> 内联 16B | air_theatre_index 生成器 {vt@+16, id@+24} (ctor 目击+探针互证) | id 恒写 (0 也写) |
| +32 | CNonstaticIdGenerator\<78\> 内联 16B | air_group_index 生成器 {vt@+32, id@+40} (同证) | id 恒写 |
| +48 | 容器 24B | 国条容器 {data@+48, cap@+56, count@+60, alloc@+64} | 非空元素 = CStrategicAir* (每国一个, vt 0X29587D8; writer 以 elem+144 tag 分键) |
| +72 | 容器 24B | per-state 映射 X {data@+72, cap@+80, count@+84, alloc@+88} (按 state_count 扩容; 与 +96/+120 成组 = 州→air_base/rocket/gun 映射, 组定案/次序推定; MAP_ERROR 断言族) | 不序列化 |
| +96 | 容器 24B | per-state 映射 Y {data@+96, cap@+104, count@+108, alloc@+112} | 不序列化 |
| +120 | 容器 24B | per-state 映射 Z {data@+120, cap@+128, count@+132, alloc@+136} | 不序列化 |
| +144 | CAirBase* | 州基地容器 容器数据指针 — {data, count} | 指针元, vt 0X2958780 过滤; **GUI: 空军基地地图图标解析尾** (CAirBaseMapIcon: sub_140C4AF30 = 本容器[state+88], 与 +192 炮位/+168 火箭同形 per-state 稀疏索引第三址) |
| +145..+155 | — | = 州基地容器尾 {cap@+152} | |
| +156 | u32 | 州基地容器 容器计数 | |
| +157..+167 | — | = 州基地容器尾 {alloc@+160} | |
| +168 | 匿名结构 (火箭基地) | 火箭基地并列阵列 容器数据指针 — {data, count} (定案) | 指针元, 同 CAirBase 类 (vt 0X2958780), 与 +144 州基地 948 槽平行; 元素 base u32@+124 == 1 → 块键 rocket_site (13303), 否则 air_base (12214) — manager writer 0X140C66C60 尾段分支 (GER id=575 state=62 cap=100 lvl=1 实证); 同 per-state 稀疏索引 (CRocketSiteMapIcon resolve 尾调用 sub_140C4B040; tooltip 落 site+120 等级 / site+104 州 + ROCKET_SITE_LEVEL/CAPACITY) |
| +169..+179 | — | = 火箭基地容器尾 {cap@+176, count@+180, alloc@+184} | |
| +180 | u32 | 火箭基地并列阵列 容器计数 | |
| +192 | CAirBase* 容器 24B | gun_emplacement {data@+192, cap@+200, count@+204, alloc@+208} (指针元; writer token 10086=gun_emplacement 逐元写; loader "Invalid gun emplacement" 断言) | per-state 稀疏索引 (CGunEmplacementMapIcon 消费; emplacement+48/+72/+104 容器形态) |
| +216 | CAirBase* | 载具 (carrier) 基地容器 容器数据指针 — {data, count} | 指针元, 无 vt 过滤 (定案) |
| +217..+227 | — | = 载具容器尾 {cap@+224, count@+228, alloc@+232} | |
| +228 | u32 | 载具 容器计数 | |
| +240 | 容器 24B | 遗留未用容器 {data@+240, cap@+248, count@+252, alloc@+256} (无任何写入 — 定案) | 不序列化 |

air_base[N] 序 = 州基地容器序 + 载具基地容器序 (实证: 338 州基地 + 14 载具 →
air_base[339..352].carrier)。manager writer 0X140C66C60 尾段发射序:

| 步骤 | 源容器 | 块键 | 说明 |
|---|---|---|---|
| 1 | 州基地 (+144) | air_base (12214) | air_base[N] 前段 = 州基地容器序 |
| 2 | 载具基地 (+216) | air_base (12214) | 循环内 *(elem+124) base==1 → 改写 rocket_site (13303) |
| 3 | 火箭基地 (+168) | rocket_site (13303) | 独立循环恒写 |
| 4 | gun_emplacement (+192) | gun_emplacement (10086) | 独立循环恒写, 逐元 |
| 5 | 国条 (+48) | — | CStrategicAir 逐国 |

#### 4.15.2 CStrategicAir (vtable 0X29587D8; 国条 writer 0X140C66970)

| 偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +16 | CAirBase* | 平行基地列表 A 数据 | 三平行 CAirBase* 列表之一 (+16/+40/+64); 条目布局未展开 |
| +40 | CAirBase* | 平行基地列表 B 数据 | 同上 |
| +64 | CAirBase* | 平行基地列表 C 数据 | 同上 |
| +88 | CAirWingPool* 容器 24B | air_wing_pool {data@88, cap@96, count@100, alloc@104} | 元素 = CAirWingPool* (vtable 0X297AE38); [N] = 池序 |
| +112 | 容器 24B | 未名向量 E | 形态定案/语义未决 — 全 dump 无业务读写, 疑遗留 |
| +136 | CStrategicAirManager* | manager 回指 | ctor 实参 a3 |
| +144 | uint32 | country_num_id | 国家 id |
| +152 | 容器 24B | _ActiveMissions {data@152, cap@160, count@164} — 按 region id 索引稀疏数组, 24B 条 = 内嵌任务指针向量 {data@0, count@+12} | 断言 `_ActiveMissions[RegionID].Contains(pMission)` |
| +176 | 容器 24B | _AllActiveMissions {data@176, cap@184, count@188} — 任务指针数组 | 断言 `_AllActiveMissions.Contains(pMission)` |
| +200 | 容器 24B | _ActiveMissionRegions {data@200, cap@208, count@212} — u32 region id 数组 | 断言 `_ActiveMissionRegions.Contains(RegionID)` |
| +224 | 容器 24B | 按战略区 160B 条态势缓存 {data@224, cap@232, count@236, alloc@240} — 双方机数/比率/按国 RB-tree 明细/活动旗标 (聚合式与制空惩罚公式 0x140C456A30/0X140C54230 全解) | 不序列化 |
| +248 | uint32 | naval_strike_remaining 容器数据指针 | u32 数组 {data, count}, c>0 |
| +249..+259 | — | = naval_strike_remaining 容器尾 {cap@+256, alloc@+264} (断言「Consumed more port strike limit than available」互证 port strike 限额语义) | |
| +260 | u32 | naval_strike_remaining 容器计数 | |
| +272 | 容器 24B | 友方 (自+盟友) CStrategicAir* 列表 {data@272, cap@280, count@284} (0x140C4557A0 重建链) | 不序列化; disruption 总量为 0X140C4C570 现算, 非此表 |
| +296 | 容器 24B | 敌方 CStrategicAir* 列表 (同重建链) | 不序列化 |
| +320 | 容器 24B | per-region 24B 条稀疏数组 M {data@320, cap@328, count@332} | 条 = 任务指针向量 {data@0, count@+12}; 与 _ActiveMissions 平行维护; 形态高置信/语义推定 |
| +344 | CLoopHistoryContainer* | history 容器数据指针 | 指针元 → CLoopHistoryContainer (§4.3.11 同构); N = 原槽位 0 起 (含空槽递增 — writer 计数器 0 起递实证; idx=i+1 读法系误) |
| +345..+355 | — | = history 容器尾 {cap@+352, alloc@+360} | |
| +356 | u32 | history 容器计数 | |
| +357..+367 | — | = history/combat_history 容器尾 | |
| +368 | SAirWingCombatData* | combat_history 容器数据指针 | CAirRegionCombatData 数组 (vt 0X2958968); 元非空才写; N = 原槽位 0 起 |
| +369..+379 | — | = combat_history 容器尾 {cap@+376, alloc@+384} | |
| +380 | u32 | combat_history 容器计数 | |
| +392 | u32 | 增援人力账合计 | 自国+附庸; 0x140C44C960 刷新 / 0x140C440120 扣减 |
| +400 | f32 + map | 按流亡政府 tag 的增援人力池 (unordered_map) | 形态: lf f32@+400=1.0 + RB-tree {sentinel@+408, size@+416} + hash 容器@+424 |
| +464 | 匿名结构 (8B 形状) | quick_wing_deploy_selection | AAFD0 门; ctor 恒建 0xF8B 对象 `sub_141964F90(tag, *(country+3952), *(country+3944))`; loader token 73=diffuse → sub_140A21680 |

#### 4.15.3 CAirWingPool (vtable 0X297AE38; writer 0X140F68FF0)

| 偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +8 | u32 | id.type — id 对之 type (对 {type, id}) | |
| +12 | u32 | id.id — id 对之 id | |
| +13..+23 | — | = id 对尾 + air_base 前置 | |
| +24 | uint32 | air_base ref.type — id 对之 type (loader token 12214=air_base 直写; 断言 `_AirBase.IsValid`) | |
| +28 | uint32 | air_base ref.id — id 对之 id | |
| +32 | CAirWing | definition | token@def+8; 内部布局: def+32 = variant 条目数组数据, def+44 = 计数 (16B 条; wing ctor 取 *(variant+1040) 任务掩码; loader 12259 → sub_140AC4FA0 直证) |
| +40 | CAirWing* | wings 容器数据指针 | {data, count}; 元素 = holder 指针, wing 对象 = holder+16 |
| +41..+51 | — | = wings 容器尾 {cap@+48} | |
| +52 | u32 | wings 容器计数 | |
| +56 | uint8 | allow_zero_entries | 装备池写门 |
| +65..+71 | — | 无字段 — 池 sizeof = 72B (0x48; 两处 malloc 0x48; ctor sub_140F5A410 只写 +0..+64; writer 0X140F68FF0 / loader 0X140F65C70 / postload 0X140F62DD0 均不触 +88/+104) | 不序列化; combat_stats 国修门读链 = resolve(_pPool → air_base idpair@+24/+28) +104 → CAirBase+104 state (门语义见 §4.15.8) — 定案 |

#### 4.15.4 CAirWing (writer 0X140F68B30; 0xA38=2616B)

主虚表 0X14297ADA8 / 副虚表 0X14297ADE0 (RTTI COL 直证; CReferenceObject 子对象 — 对象层
wing 校验可并查副表); ctor 0X140F59760; 校验法 = uint32@+8 == 69。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +8 | u32 | id.type — id 对之 type (对 {type=69, id}) | | |
| +12 | u32 | id.id — id 对之 id | | |
| +16 | u8 | 标志字节 (默认 0, 语义未附) | 不序列化 | |
| +24 | uint32 | priority (默认 = dword_143337624, NAir define) | | |
| +28 | uint32 | allow_mission_type | 位掩码 (默认 = *(首 variant+1040) 装备允许任务掩码; 断言 `_EquipmentMissionTypes`) | |
| +32 | u32 | equipment_mission_types 位掩码 (装备可做任务; 与 allow_mission_type 区分; 断言 `IsAllMatchingMissionTypes(Equipment, _EquipmentMissionTypes)`) | 不序列化 | |
| +40 | CAirWingPool* | _pPool 回指 (断言 `_pPool && "Calling hourly update on an airwing with no pool."`) | 不序列化 | |
| +48 | u32 | air_group.type — id 对之 type (id 对 {type@+48, id@+52}) | 非零且可解析才写 | |
| +52 | u32 | air_group.id — id 对之 id | 非零且可解析才写 | |
| +56 | u32 | transferring_to.type — id 对之 type (id 对 {type@+56, id@+60}) | 解析链: RH 表 `base+54759008+8*type` → {d@tb+8, mask@tb+20} 24B 桶 → obj@+16 → *(obj+104) → u32@+88 = region id; 写门 = id 对非零且解析非空 (0X14221F310 返回值检查) | |
| +60 | u32 | transferring_to.id — id 对之 id | | |
| +64 | fixed×1e-5 | transfer_progress | 门 = 转移中或 u8@+105≠0 (else 分支直落, 非互斥) | |
| +72 | idpair (qword) | air_base 当前基地引用 (load 时由 transferring_to/transferring_to_carrier 解析回填; 载具路径经 *(ship+1840)) | 不序列化 | |
| +80 | uint32 | deployment_time | 门 = b105≠0 或 deployment(+84) < deployment_time(+80) 或 转移中 (同门同出) | |
| +84 | uint32 | deployment | | |
| +88 | fixed5 | 经验增益量/速率 (每 tick 清 0; 训练任务下 = 计算增益加进 experience@+520 并以 qword_143331300 封顶; ctor 默认 100000) | 不序列化 | |
| +96 | uint32 | region_to_assign | ≠0 才写 | |
| +100 | uint32 | mission_to_assign | ≠0 才写 | |
| +104 | uint8 | transfer_cancelled → yes/no | 门同 transfer_progress | |
| +105 | uint8 | transfer_to_warehouse | 非转移且 ≠0 才写 yes | |
| +108 | uint32 | count | 机数 | |
| +112 | uint32 | manpower | | GUI: 联队人力数字窗 (sub_140F622A0 → current_manpower / MANPOWER_AIRWING) |
| +116 | uint32 | air_accidents | >0 才写 | |
| +117..+127 | — | = mission 前置 pad | | |
| +128 | CAirMission (内联) | mission | 见 §4.15.5 | |
| +129..+423 | — | = CAirMission 内嵌 296B 整体 (+128..+423, §4.15.5) | | |
| +424 | uint32 | suspended_missions | 位掩码 (2048 与存档 suspended 集一致); ≠0 才写 | |
| +432 | SAirWingCombatData* | other_combats 容器数据指针 | {data, count}; data 为 id 对数组本体内联 8B 条 {type@+0, id@+4} (探针定案) | |
| +433..+443 | — | = other_combats 容器尾 {cap@+440} | | |
| +444 | u32 | other_combats 容器计数 | | |
| +445..+455 | — | = other_combats 容器尾 {alloc@+448} | | |
| +456 | 匿名结构 (元素待裁) 向量 | equipment 池 | {data@+488, count@+500} 16B {variant*, amount ×1e-5}; allow_zero = uint8@+512 (writer 0X141012DB0 同生产池) | GUI: 装备构成列表 (SetupDerived 直读 +488/+500: 0x560 行对象 × {variant*, amount/1e5 机数}) |
| +457..+519 | — | = equipment 池本体 64B (CEquipmentVariantPool 同型, ctor 0X14100C710; 条目 data@+488, cap@+504, count@+500, allow_zero u8@+512) | | |
| +520 | fixed×1e-5 | experience | | |
| +528 | u8 | 经验增长脏标志 (xp 低于 cap 且增加时置 1; ctor 默认 1) | 不序列化 | |
| +536 | CModifier 内嵌 192B | wing 动态修正块 (+536..+727; ctor sub_140555FB0 直证) | 不序列化 | |
| +728 | u32 | ace.type — id 对之 type (id 对 {type@+728, id@+732}) | 非零且可解析才写 | GUI: Ace 名/头像 (sub_140F5AAB0 → CAce; 名 sub_14061A5D0; 无 ace → 隐藏+禁用) |
| +732 | u32 | ace.id — id 对之 id | 非零且可解析才写 | |
| +736 | CSubUnitDefinition 内嵌副本 ~1656B | 定义副本 (+736..+2391; **尾界 +2407 为末字节**, +2408 起下一子对象, ctor sub_140F5A500; copy ctor 0X1403C77D0 从 null object 拷默认) — **负定案: 无运行时覆写层** (三 ctor 仅 null def 拷, 拷贝 ctor 其余调用全为临时对象, 全 dump 零子域写入); 旧「统计 getter fallback」无读者支持已降档 | 不序列化 | |
| +2392 | i64 向量 | _StatsPerMission {data@+2392, cap@+2400, count@+2404, alloc@+2408, remap int8[18]@+2416..+2433} — 条目 624B = 78×i64 统计值数组; remap[任务位号]→条目号 (0xFF=无); MISSIONS_COUNT=18 | 断言 `MissionIndex < _StatsPerMission.GetSize` | |
| +2440 | cstr | name | **恒写 (空串照写 "")** — 门 sub_1424BFF30 是 **checksum-file 判定** (RTDynamicCast CChecksumFile), 与 SSO 串非空无关 | GUI: 联队名文本/改名 (sub_140F60A70 → air_wing_name; 变更 → CSetAirWingNameCommand id 14312) |
| +2441..+2471 | — | = name MSVC SSO 32B 内件 {size@+2456, cap@+2464=15} | | |
| +2472 | 匿名结构 (NNB 形状) | army 对象指针 (token 10397) | ptr≠0 | writer 经 sub_142220260(a2, 10397, ptr+8) 写 idpair |
| +2480 | u8 | coverage | 默认 1, 仅当 0 时写 `coverage=no` | |
| +2484 | tag_id | tag (wtag) | 0 不写 | GUI: combat_stats 属主修正链 (+2484 tag → cc+1464 查键 {201/202/203}=navy_carrier_air_*; 门见 §4.15.8 CAirBase +104 行) |
| +2488 | uint32 | government_in_exile_tag | >0 才写 (tag 反查) | |
| +2492 | uint8 | reinforcement_setting (默认 1) | | |
| +2496 | 容器 24B | 空投运输单位列表 {data@+2496, cap@+2504, count@+2508, alloc@+2512} — 8B CUnit* 元 (unit+800 = `_pAirTransport` 回指互证) | 不序列化 | 任务位 0x40 = paradrop (断言直证) |
| +2520 | qword | 空投目标省 (0x40 任务门检 `count==0 && +2520==0`) | 不序列化 | |
| +2524 | u32 ×2 | 任务类型与 region 快照 (+2524/+2528) | 不序列化 | |
| +2536 | uint32 | carrier_air_wing_kills 容器数据指针 — **扁平 16B 元 {key u64 装备类别 bitmask@+0, value u32@+8}** (非 RH map); 键经 equipment_category 表 sub_140F8A750 转 token (0x400→fighter / 0x8000→naval_bomber …; 多位键取首位置, equipment_category.cpp:52 断言) | c>0 | |
| +2537..+2547 | — | = kills 容器尾 {cap@+2544} | | |
| +2548 | u32 | carrier_air_wing_kills 容器计数 | c>0 | |
| +2549..+2559 | — | = kills 容器尾 {alloc@+2552} | | |
| +2560 | fixed×1e-5 | air_untrained_pilots_penalty_factor | 门 = u8@+2568≠0 | |
| +2561..+2575 | — | = penalty factor 尾 + 门 u8@+2568 + pad | | |
| +2576 | STimedDisabling* | timed_disabling | writer 0X141A2F740: remaining_hours uint32@+4, should_start_on_transfer uint8@+8 (ssot 运行时恒 1, 存档读回 no — 演化字段); td 空按默认 0/no | |
| +2584 | uint32 | role_icon_index | >0 才写 | GUI: 联队角色图标 (sub_140F5F670) |
| +2588 | u32 | raid_instance.type — id 对之 type (id 对 {type@2588, id@2592}) | 任一非零才写 (14220B240: 先 id 后 type) | |
| +2592 | u32 | raid_instance.id — id 对之 id | | |

CAirWing 双虚表槽表 — 主表 0X14297ADA8 (CSelectable, 6 槽):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | _purecall | 空桩 |
| [2] | OnSelect | 选中翼的所属基地 |
| [3] | _purecall | 空桩 |
| [4] | _purecall | 空桩 |
| [5] | — | 恒真 |

副表 0X142979150 (@16, CReferenceObject←CPersistent, 10 槽):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | (§4.00 CPersistent 指纹同址) | Save wrapper |
| [2] | 0X140F68B30 | writer |
| [3] | (§4.00 CPersistent 指纹同址) | Load wrapper |
| [4] | 0X140F651B0 | loader |
| [8] | — | PostLoad 补链 (含 ace 重解析与翼名惰性初始化) |

CAirWing writer 0X140F68B30 尾段发射链 (实证 12449/19183 块均在其内):

| 序 | 块键 | 偏移 (wing) | 写门 |
|---|---|---|---|
| 1 | 12449 (other_combats) | +432 | 数组 |
| 2 | 12857 | +116 (missions_done) | — |
| 3 | 12770 | +728 (ace id 对) | 非零且可解析 |
| 4 | 13780 | +424 (suspended_missions) | ≠0 |
| 5 | 10754 (tag 串) | +2484 (经 sub_140BB4E70) | — |
| 6 | 12110 (equipment) | +456 | — |
| 7 | 27 | +2440 (name) | 恒写 (空串照写, 门 AAFD0 = checksum-file 判定) |
| 8 | 141 | +24 (priority) | — |
| 9 | 11057 | +28 (allow_mission_type) | — |
| 10 | 14652 | +96 (region_to_assign) | ≠0 |
| 11 | 14653 | +100 (mission_to_assign) | ≠0 |
| 12 | 12469 | +2480 (coverage) | 仅 0 时写 no |
| 13 | 15034 (gix) | +2488 | >0 |
| 14 | 19901 (数组) | +2536 (count@+2548) | c>0 |
| 15 | 19863 | +2560 | u8@+2568 ≠0 |
| 16 | 12227 | +48 (air_group) | 非零且可解析 |
| 17 | 15526 | +2584 (role_icon_index) | >0 |
| 18 | 19183 (raid_instance) | +2588 (id 对) | +2588‖+2592 任一非零 (14220B240: 先 id 后 type) |

#### 4.15.5 CAirMission (内联 wing+128; 296B; vtable 0X297C8D0; writer 0X140F87820; ctor 0X140F75380)

m = CAirMission 本体 (wing+128 起); 下一 wing 字段 +424 = m+296, 全封闭。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +16 | uint32 | type | token 225; **AI 侧读法 = 任务位掩码 (1<<任务位 idx; 位 11 = 训练 MISSION_TRAINING)** — holder 形态判定: 空军 AI 容器存的是 holder (CAirWingPool 72B 元素), holder+160 ≡ m+16 (§4.34.12) | 高置信 |
| +20 | uint32 | executing_mission (u32 位旗@m+20; ≠0 时经 sub_141014010 查表裸写 token 名) | 写序在 active 之后 (定案) | |
| +24 | int8 | period | 任务周期 (小时); writer 只写低 8 位带符号 (mem 258=0x102 ↔ save 2 铁证) | |
| +28 | uint32 | aggressiveness | ≠0 才写 | |
| +32 | uint8 | active | token 11390 | |
| +40 | CAirWing* | _pAirWing 回指 (ctor `*(m+40)=a2`) | 不序列化 | |
| +48 | CStrategicRegion* | region 对象 | region ptr = m+48 (定案); strategic_region = uint32@(*(m+48)+88) | ptr≠0 |
| +56 | 匿名结构 (16B 形状) 向量 | 16B 条目标省表 | c1@+56 (dtor 分组); combat 路径 F67D70/F66100 读 m+56/64/68 | 不序列化 |
| +64 | qword | 未名 (combat 路径同读) | 不序列化 | |
| +80 | fixed×1e-5 | effectiveness 缓存槽 | 真值@+216 (缓存值==m+216 实证); 容器分组 c1@+56 / c2@+88 (dtor 分组) | |
| +88 | 匿名结构 (元素待裁) 向量 | 未名 (c2@+88, dtor 分组) | 不序列化 | 未决 |
| +104 | 匿名结构 (元素待裁) 向量 | {alloc@+104, data@+112, 计数@+116} — 高置信: +116 单值双名 (容器计数 ≡ missions_done 恒等, 探针); alloc@+104 = 引擎分配器单例 (84/84) | | |
| +116 | uint32 | missions_done | (同上; 残留验证点: u116>0 时 data@112 展开终验, 本档无翼执行任务) | |
| +124 | 位集 | stop_training (512) | 门 = u8@m+124 (writer `*(_BYTE*)`), 仅真写 yes; u32 判在 b@+125 置位时失真 | |
| +128 | 匿名结构 (NNB 形状) | priority 容器数据指针 — 串循环 {data@m+128, count u32@m+140} 指针数组, 键 141 (priority), 元素 deref+624 引号串, 重复裸键标量叶不编号 (writer 全字段定案; GER pool[3] 7 叶 naval_base/… 实证) | | |
| +129..+139 | — | = priority 容器尾 {cap@+136} | | |
| +140 | u32 | priority 容器计数 | | |
| +144 | — | = priority 容器尾 {alloc@+144} | | |
| +152 | u32 | 已飞里程 (F71120 速度计算读 m+152/156/160/164 族) | 不序列化 | |
| +156 | idpair | ace id 对 (默认 qword 哨兵) | 不序列化 | |
| +164 | u32 | 所属 tag 缓存 | 不序列化 | |
| +168 | qword ×3 | 扰断三件套 (+168 有效 / +176 taken / +184 reduction) | 不序列化 | |
| +192 | fixed×1e-5 | region_change_penalty | writer 在 strategic_region 门内无条件写, 0 值也出叶 — 对象层 raw≠0 才返回会丢叶, 段内须 inline | |
| +200 | u32 | 未名 (F6CF90/F6DB20 地面任务目标选择读 m+200/208 族) | 不序列化 | 未决 |
| +208 | qword | 地面任务选定目标 | 不序列化 | |
| +216 | fixed×1e-5 | effectiveness (真值) | | |
| +224 | uint32 | effective_planes_count | | |
| +232 | fixed×1e-5 | effective_air_superiority | | |
| +240 | CCommandPowerAllocator 内嵌 | 指挥点数分配器对象 (vt 直读; m+248/+256 = 其成员) | 不序列化 | |
| +264 | MSVC 串 | CP tooltip 描述串 {buf@264..279, size@280, cap@288=15} (0X140F79E40 生成, loc 键 COMMAND_POWER_TOOLTIP_AIR_MISSION; 定名) | 不序列化 | |

#### 4.15.6 CAirRegionCombatData (combat_history 元素; writer 0X141964630)

| 偏移 | 类型 | 名称 |
|---|---|---|
| +8 | 友方条目数组* | friend 容器 {data@+8, count@+20} 152B 条 |
| +9..+31 | — | = friend 容器尾 {cap@+16, count@+20, alloc@+24} |
| +32 | 匿名结构 (152B 形状) 向量 | enemy 容器 {data@+32, count@+44} 152B 条 |
| +33..+55 | — | = enemy 容器尾 {cap@+40, count@+44, alloc@+48} |
| +56 | tag_id | tag (140BA5C20 串) |

#### 4.15.7 SAirWingCombatData (152B 条; writer 0X141964700)

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | wing_id |
| +12 | uint32 | time |
| +16 | uint32 | count (token 直证 10730=count@+16) |
| +20 | uint32 | mission (token 11450) |
| +24 | uint8 | destination |
| +25 | uint8 | ground_attack |
| +32 | 匿名结构 (24B 形状) 向量 | friend_damage {d@+32, c@+44} 24B 条 (SDamageEntry: uint32@+8 (token 225), fixed×1e-5@+16 (token 776)) |
| +33..+55 | — | = friend_damage 容器尾 {cap@+40, alloc@+48} |
| +56 | 匿名结构 (24B 形状) 向量 | enemy_damage {d@+56, c@+68} 24B 条 |
| +57..+79 | — | = enemy_damage 容器尾 {cap@+64, alloc@+72} |
| +80 | MSVC 串 | tag |
| +88 | SEquipmentPool 内嵌 | equipment 块 (12110; allow_zero = b@池+56, writer 0X141012DB0) |

#### 4.15.8 CAirBase (vtable 0X2958780; 144B; writer 0X140C667B0)

ctor 0X140C47B00; 载具构造 0X140C4B5A0 (载具 id={65, ++dword_14333CA00} 全局序;
*(ship+1840)=base 回挂)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | u32 | id.type — id 对之 type (对 {type, id}) — GUI: Reorg 窗 target (idpair → win+4128 快照; SetTarget sub_14202DCD0) | 恒写 |
| +12 | u32 | id 对.id — B400 壳 | 恒写 |
| +16 | u8 | 标志字节 (默认 0; dtor 读 `!*(a1+16)` 门 id 重注册) | 不序列化 |
| +24 | 容器 24B | 驻扎 wing 列表 {data@+24, cap@+32, count@+36, alloc@+40} (AddWing 按 id 对去重) | 不序列化 |
| +48 | 容器 24B | per-country access 关系数组 {data@+48, cap@+56, count@+60, alloc@+64} — 8B 指针元 → CAirBaseAccessRelation (RTTI 0x142A21738; 按国家序号索引, elem+184 = 访问数据; 断言 `HasAccess(Tag)` / `Removing country access to air base with dangling airpools`) | 不序列化 |
| +72 | CCountryAirContainer* | countries 容器数据指针 — {data, count} 指针元 → CCountryAirContainer (§4.15.9) | c>0 |
| +73..+83 | — | = countries 容器尾 {cap@+80} | |
| +84 | u32 | countries 容器计数 | c>0 |
| +85..+95 | — | = countries 容器尾 {alloc@+88} | |
| +96 | u32 | carrier.type — id 对之 type (id 对 {type, id}) | else 分支恒写 (无 state 即写, 载具基地) |
| +100 | u32 | carrier.id — id 对之 id | |
| +104 | CState* | state 对象 → state = *(*(a+104)+88) | 状态指针非空; combat_stats 国修门真身: resolve(_pPool → air_base idpair@+24/+28)+104 == 0 (海上/载具/未指派, 基地无 state) → 翼 combat_stats 吃属主国修正 {201=navy_carrier_air_attack_factor / 202=targetting / 203=agility} (各 +100000 基数, 经 wing+2484 tag → cc+1464 查键); ≠0 → 基数 1.0 (定案) |
| +112 | qword | 基地 province id 惰性缓存 (daily 重算) | 不序列化 (定案) |
| +120 | uint32 | capacity | 恒写 |
| +124 | uint32 | base | 恒写; 真值 = u32@+124 (byte@+128 = 下行 has_manpower 的门/值, 勿混); ctor = sub_140C3AD00(ship) 0/1 |
| +128 | uint8 | has_manpower_for_recruit_change_to | ≠0 才写 |
| +132 | uint32 | level (默认 1) | 恒写 |
| +136 | uint64 | allow_equipment_type | 位掩码 (>32bit), 恒写; GUI: Reorg 可部署装备池过滤 (× cc+3944(+512) 库存 → win+4024 池; sub_14100CFC0) |

#### 4.15.9 CCountryAirContainer (CAirBase countries 元素; 基 writer 0X140ED0400 → 主 0X140C668B0)

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | u32 | id.type — id 对之 type (对 {type=4713, id}) | 恒写 |
| +12 | u32 | id 对.id — B400 壳 | 恒写 |
| +13..+28 | — | = CReferenceObject 簿记@+16 (ctor 清 0) + 所属 supply-region CSupplyConsumer id 对/指针 @+17..+23 + u32@+24 = 0 (基 ctor 置零, 未入档; 元素对象 0xF8) + pad (ctor sub_140C482A0) | |
| +29 | uint8 | motorization_level | 恒写 |
| +30..+159 | — | = motorization_level@+29 (ctor `WORD@29=256` 高半=1) + 三个 100000 (1.0) 定点标量 {+32/+40/+48} (基 ctor) + +56 = sub_1424EF6F0(100000) 派生值 (defines 下限运算) + +64=100000 + qword 零群 {+72/+80/+88} + pdx 容器 {data@+96, cap@+104, count@+112} + 标量区 {+120/+128/+136/+144/+152} (全零, ctor 置 0) — 全段 writer 仅发射 +29 (motorization) 与 +160 (disrupted_supply), 余为运行时 (基 ctor 直读) | |
| +160 | fixed×1e-5 | disrupted_supply | >0 才写 |
| +168 | idpair | 所属 air_base 引用 (+168/+172; base daily 逐国回写; 断言 `Country air container without airbase when calculating supply location`) | |
| +176 | tag_id | country (反查 tag 串) | 恒写 |
| +184 | 匿名结构 (元素待裁) 向量 | 该基地该国 wing 指针数组 {data@+184, cap@+188, count@+196} — 8B 元 (逐翼燃料值累加进 cp+224/+232) | |
| +208 | fixed×1e-5 | operational_status | ≠100000 (≠1.0) 才写 |
| +216 | fixed×1e-5 | capacity_penalty | ≠0 才写 (真源 +216) |
| +224 | fixed×1e-5 | fuel_consumption | ≠0 才写 |
| +232 | fixed×1e-5 | base_fuel_consumption | ≠0 才写 |
| +240 | fixed×1e-5 | received | ≠0 才写 |

#### 4.15.10 CAirWingsSelectionList (ctor sub_141F5D940)

RTTI 实名 @ByBase 条目+112; 布局 14 格全清 (含三套行回收池 +40/+104/+136);
populate 链 sub_141F5E740 → sub_141F5E9E0 按基地 +124 base 类型建四类行。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +40 | — | 行回收池 | CAirWingSelectionItem 池 (原稿正确) |
| +72 | — | 行回收池 | **CRocketWingsSelectionItem 池** (data@+72, cap@+80, count@+84, alloc@+88, live@+64; 复用器 sub_141F5DE90 双证) |
| +104 | — | 行回收池 | **CGunEmplacementWingsSelectionItem 池** (data@+104, cap@+112, count@+116, live@+96; builder case 2 双版同偏移, 定案 — 旧「bottom_window 窗柄」注系误并; bottom_window = ByBaseView+104 另域) |
| +136 | — | 行回收池 | CAirBaseSelectionItem 池 (原稿正确) |
| +336 | — | air_group 对空过滤器 (定案) | flag=0 收 air_group 为空的未分配翼; flag=1 收 air_group==a4 的所选组翼 (air_group 对 = 翼 +48) |

> **本域 GUI 类布局**: 见 4.30.45 / 4.31.11 / 4.31.38 / 4.31.40 / 4.31.61 / 4.31.90。
