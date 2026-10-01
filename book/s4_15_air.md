

### 4.15 战略空军族 (CStrategicAirManager → CStrategicAir → CAirWingPool → CAirWing)

> 坐标注: 本册表内偏移一律 = 书基坐标; 运行时方法 this = 书基−16 (raw)。
> 换算仅在此注, 正文只用书基坐标。

mgr = *(gs+1680); 两级结构 pool → wing (定案)。

#### 4.15.1 CStrategicAirManager (mgr = *(gs+1680); vtable 0X142958918)

| 偏移 (mgr) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | CNonstaticIdGenerator\<77\> 内联 16B | air_theatre_index 生成器 {vt@+16, id@+24} (ctor 目击+探针互证) | id 恒写 (0 也写) |
| +32 | CNonstaticIdGenerator\<78\> 内联 16B | air_group_index 生成器 {vt@+32, id@+40} (同证) | id 恒写 |
| +48 | 容器 24B | 国条容器 {data@+48, cap@+56, count@+60, alloc@+64} | 非空元素 = CStrategicAir* (每国一个, vt 0X29587D8; writer 以 elem+144 tag 分键) |
| +72 | 容器 24B | per-state 映射 **X = air_base** {data@+72, cap@+80, count@+84, alloc@+88} (按 state_count 扩容; per-state 24B 条 {省 id 数组@+0, 计数@+12}; 定位函数 sub_140C53910: base+124==1→Y / ==2→Z / else→X, state+88 = state id; MAP_ERROR 断言族) | 不序列化 |
| +96 | 容器 24B | per-state 映射 **Y = rocket_site** {data@+96, cap@+104, count@+108, alloc@+112} (同 X 条形; 构建链 sub_140C59E30 地图初始化: 州建筑三字段 +784/+883/+867, 省 +5976/+5977/+5978 标志, MAP_ERROR 校验; gs 入口 sub_1401E13E0) | 不序列化 |
| +120 | 容器 24B | per-state 映射 **Z = gun_emplacement** {data@+120, cap@+128, count@+132, alloc@+136} (同上) | 不序列化 |
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
| +16 | CAirBase* | **陆基基地表** 数据 {data@+16, cap@+24, count@+28} | 三平行表身份定案 (postload sub_140C59380 按 base+124 挂表: 1→+40, 2→+64, else→+16); 国级空军燃料/消耗合计 sub_1410F25D0 只扫 +16 与 +40 (火箭不计) |
| +40 | CAirBase* | **载具基地表** 数据 {data@+40, cap@+48, count@+52} | 同上 |
| +64 | CAirBase* | **火箭基地表** 数据 {data@+64, cap@+72, count@+76} | 同上 |
| +88 | CAirWingPool* 容器 24B | air_wing_pool {data@88, cap@96, count@100, alloc@104} | 元素 = CAirWingPool* (vtable 0X297AE38); [N] = 池序 |
| +112 | 容器 24B | **待除名翼队列** {data@+112, cap@+120, count@+124} | 翼 hourly 尾段推入 (无有效位置且无机 / 转移仓库 / 未部署完成 / 转移中); 管理器 hourly 首段清空 (sub_140F62AF0 逐翼处理三件套: 装备退还 sub_141011250 100% + ace 回收 sub_14061BC70 + 删翼 sub_140F66A40; 空池 pool+52==0 → vt[0] 销毁) |
| +136 | CStrategicAirManager* | manager 回指 | ctor 实参 a3 |
| +144 | uint32 | country_num_id | 国家 id; 翼燃料系数合成器 sub_140F5F880 的 GetCountry 兜底路径 (翼无 tag 时经 pool+64 → sa+144) |
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
| +64 | CStrategicAir* | 属主国条回指 | ctor sub_140F5A410 a2 形参; loader 0X140C61640 传入 |
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
| +32 | u32 | equipment_mission_types 位掩码 (装备可做任务; 与 allow_mission_type 区分; 断言 `IsAllMatchingMissionTypes(Equipment, _EquipmentMissionTypes)`) | 不序列化; 重建器 = sub_140F667B0 (池 loader 逐翼调用; 公式 = +28 拷贝基线 + def+1448&0x100000400 国旗 0x80 + 规则 19 def+440/448 位 0x1000/0x2000 − 有机 0x800 − 低机 0x400) | |
| +40 | CAirWingPool* | _pPool 回指 (断言 `_pPool && "Calling hourly update on an airwing with no pool."`) | 不序列化 | |
| +48 | u32 | air_group.type — id 对之 type (id 对 {type@+48, id@+52}) | 非零且可解析才写 | |
| +52 | u32 | air_group.id — id 对之 id | 非零且可解析才写 | |
| +56 | u32 | transferring_to.type — id 对之 type (id 对 {type@+56, id@+60}) | 解析链: RH 表 `base+54759008+8*type` → {d@tb+8, mask@tb+20} 24B 桶 → obj@+16 → *(obj+104) → u32@+88 = region id; 写门 = id 对非零且解析非空 (0X14221F310 返回值检查) | |
| +60 | u32 | transferring_to.id — id 对之 id | | |
| +64 | fixed×1e-5 | transfer_progress | 门 = 转移中或 u8@+105≠0 (else 分支直落, 非互斥) | |
| +72 | fixed×1e-5 | **转移路程阈值** (StartTransfer sub_140F67AB0 写 sub_140F5B8B0 计算值; sub_140F5D2D0 清 0; sub_140F64B70 比较到站) | 转移态**载入重算** (翼 loader token 12249/12436 经 sub_140F5B8B0); 非转移恒 0 | |
| +80 | uint32 | deployment_time | 门 = b105≠0 或 deployment(+84) < deployment_time(+80) 或 转移中 (同门同出) | |
| +84 | uint32 | deployment | | |
| +88 | fixed5 | 经验增益量/速率 (每 tick 清 0; 训练任务下 = 计算增益加进 experience@+520 并以 qword_143331300 封顶; ctor 默认 100000) | 不序列化 | |
| +96 | uint32 | region_to_assign | ≠0 才写 | |
| +100 | uint32 | mission_to_assign | ≠0 才写 | |
| +104 | uint8 | transfer_cancelled → yes/no | 门同 transfer_progress | |
| +105 | uint8 | transfer_to_warehouse | 非转移且 ≠0 才写 yes | |
| +108 | uint32 | count | **序列化** (writer 首 token 10730 恒写 / loader 落 +108); sub_140F63580 尾 = 池总量/1e5 现算是运行时维护路径 | |
| +112 | uint32 | manpower | | GUI: 联队人力数字窗 (sub_140F622A0 → current_manpower / MANPOWER_AIRWING) |
| +116 | uint32 | air_accidents | >0 才写; += 空难数 (sub_140F5DD80) | |
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
| [0] | dtor | |
| [1] | CFG 空桩 (0x14012A2C0) | 无实现 |
| [2] | OnSelected | 选中翼的所属基地 |
| [3] | CFG 空桩 | 无实现 |
| [4] | CFG 空桩 | 无实现 |
| [5] | 基类默认恒真 (0x1401807B0 继承) | IsSelectable |

副表 0X14297ADE0 (@16, CReferenceObject←CPersistent, 10 槽):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | (§4.00 CPersistent 指纹同址) | Save wrapper |
| [2] | 0X140F68B30 | writer |
| [3] | (§4.00 CPersistent 指纹同址) | Load wrapper |
| [4] | 0X140F651B0 | loader |
| [8] | 0X140F62BC0 | PostLoad (随机流恢复 + 翼名惰性初始化 sub_140F5E110 + ace 补链 sub_14061BC70, 缺 ace 报 "Airwing %s has Ace that does not exist.") |

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
| +20 | uint32 | executing_mission | u32 位旗@m+20; ≠0 时经 sub_141014010 查表裸写 token 名; 唯一运行时写者 = lambda_1 sub_140C49E80 (roll sub_140F7A420/7ACC0/796E0; SetMission 与不可达时清 0) | 写序在 active 之后 (定案) |
| +24 | int8 | period | **昼夜选择枚举: 0=仅夜 1=仅昼 2=昼夜皆飞** (非周期小时); writer 低 8 位截断无损 (枚举值 <128); 燃料折算 = period≠2 时按当日太阳覆盖 > DAY_NIGHT_COVERAGE_FACTOR 的小时数 ×(小时/24) (sub_140F5B4C0); 训练昼夜门 sub_140F80A40 (昼任务夜间覆盖不足 → 不计消耗) | |
| +28 | uint32 | aggressiveness | ≠0 才写 | |
| +32 | uint8 | active | token 11390; 重算门 = SetMission 尾 (无基/不可访问/训练 → 0) | |
| +40 | CAirWing* | _pAirWing 回指 (ctor `*(m+40)=a2`) | 不序列化 | |
| +48 | CStrategicRegion* | region 对象 | region ptr = m+48 (定案); strategic_region = uint32@(*(m+48)+88) | ptr≠0 |
| +56 | 匿名结构 (16B 形状) 向量 | 16B 条目标省表 | {data@+56, cap@+64, count@+68, alloc@+72}; 填充者 sub_141012F80 (AA 强度 + 航程过滤, 经 sub_1410132D0) | 不序列化 |
| +64 | qword | 未名 (combat 路径同读) | 不序列化 | |
| +80 | fixed×1e-5 | 目标省覆盖比 | clamp(1e5×需求省数/区域省数(region+36), ≤1e5) | 不序列化 |
| +88 | 匿名结构 (元素待裁) 向量 | 未名 (c2@+88, dtor 分组) | 不序列化 | 未决 |
| +112 | uint32 | 当前目标省 id | sub_140F85240 随机选取, 0=无; ProcessGroundMission case 0x8000 同写 | 不序列化 |
| +116 | uint32 | missions_done | token 12777; writer 恒写; **无运行时写者 — 负定案 (仅存档往返)** | |
| +120 | uint32 | 机数缓存 | sub_140F87480: 出战加权机力/1e5; 变化时清 +68 重选目标 | 不序列化 |

| +124 | 位集 | stop_training (512) | 门 = u8@m+124 (writer `*(_BYTE*)`), 仅真写 yes; u32 判在 b@+125 置位时失真 | |
| +128 | 匿名结构 (NNB 形状) | priority 容器数据指针 — 串循环 {data@m+128, count u32@m+140} 指针数组, 键 141 (priority), 元素 deref+624 引号串, 重复裸键标量叶不编号 (writer 全字段定案; GER pool[3] 7 叶 naval_base/… 实证) | | |
| +129..+139 | — | = priority 容器尾 {cap@+136} | | |
| +140 | u32 | priority 容器计数 | | |
| +144 | — | = priority 容器尾 {alloc@+144} | | |
| +152 | u32 | **小时累计被击坠数** (累加 + 出动余量扣减 + sub_140F63580 收割三处独立证实; KillAirplanes 步9 参数) | 不序列化 | |
| +156 | idpair | **击杀方王牌 id 对** (受害任务侧记录, 默认 qword 哨兵) | 不序列化 | |
| +164 | u32 | **击杀方 tag** | 不序列化 | |
| +168 | qword ×3 | 扰断三件套 (+168 有效 / +176 taken / +184 reduction) | 不序列化 | |
| +192 | fixed×1e-5 | region_change_penalty | writer 在 strategic_region 门内无条件写, 0 值也出叶 — 对象层 raw≠0 才返回会丢叶, 段内须 inline | |
| +200 | u32 | 未名 (F6CF90/F6DB20 地面任务目标选择读 m+200/208 族) | 不序列化 | 未决 |
| +208 | qword | 地面任务选定目标 | 不序列化 | |
| +216 | fixed×1e-5 | effectiveness (真值); **序列化 token 14144** (bool 形落盘); 运行时写者 sub_140F79A00 (表 A 执行门) | |
| +224 | uint32 | effective_planes_count; **序列化 token 14145** (u32 保真); 运行时写者 sub_140F79A00 / 紧急出击门 sub_140F79C10 | |
| +232 | fixed×1e-5 | effective_air_superiority; **序列化 token 14149** (bool 形); 写者 sub_140F775D0 | |
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
| +16 | uint32 | count (token 10730; = max(旧, 当前机数)) |
| +20 | uint32 | mission (token 11450; 重建时 ‖= m+16 位并) |
| +24 | uint8 | destination |
| +25 | uint8 | ground_attack |
| +32 | 匿名结构 (24B 形状) 向量 | friend_damage {d@+32, c@+44} 24B 条 (SDamageEntry: uint32@+8 (token 225), fixed×1e-5@+16 (token 776)) — **按统计类别分表: 0/1/2/6/7 → +32; 3/4/5/9/10 → +56; 8 无** (类别 3 = 坠机数, 值 clamp ≤1e5×机数; 填充 sub_141962C40 airregionstatistics.cpp:203) |
| +33..+55 | — | = friend_damage 容器尾 {cap@+40, alloc@+48} |
| +56 | 匿名结构 (24B 形状) 向量 | enemy_damage {d@+56, c@+68} 24B 条 (同上分表规则; +88 起 = 内嵌装备池快照 — 记录时当前机数 > 条内机数 → 合并翼池快照) |
| +57..+79 | — | = enemy_damage 容器尾 {cap@+64, alloc@+72} |
| +80 | MSVC 串 | tag |
| +88 | SEquipmentPool 内嵌 | equipment 块 (12110; allow_zero = b@池+56, writer 0X141012DB0) |

#### 4.15.8 CAirBase (vtable 0X2958780; 144B; writer 0X140C667B0)

ctor 0X140C47B00; 载具构造 0X140C4B5A0 (载具 id={65, ++dword_14333CA00} 全局序;
*(ship+1840)=base 回挂)。

虚表槽表: [0] dtor 0x140C4AD70 / [2] writer 0x140C667B0 / [4] loader 0x140C60DF0 / [8] postload 0x140C59380 / [9] id 生成 / **[24] (+192) = 0x140C5B7C0 建筑等级变化回调 (capacity/level 唯一运行时写者)** / [25] (+200) = 0x140C5B720 部署入口。

生命周期: 运行时创建走三个惰性函数 sub_140C4B110/4BEE0/4BBE0 (air/rocket/gun 各一, mgr 稀疏索引 miss 才建, 统一 id = {65, ++dword_14333CA00}); 销毁: rocket 建筑归零走拆除链 (逐翼解散+稀疏槽销毁); 载具 = RemoveCarrierBase sub_140C51080 (byte_14333CA04 门 + vt[0] delete), dtor 断言"池必须已空" (strategicair.cpp:737)。载具回挂三写点 = 创建 sub_140C4B5A0 / loader 尾 / dtor 清 0; 舰沉级联 = 舰船 dtor sub_140C30380 → RemoveCarrierBase (mgr+216 二分 + sub_140C63100 按 +124 分派逐国除名); 另两路 = 装备丧失 sub_140C33BA0 / 转籍 sub_140D67800→sub_140C4EB40 (删旧建新)。

容量链 (sub_140C65490, 唯一写者): 陆基 = AIRBASE_CAPACITY_MULT×Σ建筑等级 / rocket = ROCKETSITE_CAPACITY_MULT×Σ / gun 恒 1 / 载具 = 舰统计 (+864/+872)/1e5×CARRIER/SUBMARINE_CARRIER_SIZE_STAT_INCREMENT / 导弹舰 = MISSILE_LAUNCHER_CAPACITY (钳 ≥10)。翼容量四档 = def+1536/1540/1544/1548 ("Missing case for AirbaseType" 断言直证; def+1448 带 0x200000000 位则直接用 base+120; 类别合成 sub_140F5F000)。

访问权链 (纯派生, 无直接 effect 写门 — 负定案): HasAccess = sub_140C57400 (base+48 槽非空); 授予重算 sub_140C65B80 逐国挂/除 (陆基 = 基地省控制 sub_140C4FB60>0 / 载具 = 对属主军事访问 sub_140D45270)。AddWing = sub_140C4BD80 (装备类别断言) / RemoveWing = sub_140C636F0 (id 对换位删除)。


| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | u32 | id.type — id 对之 type (对 {type, id}) — GUI: Reorg 窗 target (idpair → win+4128 快照; SetTarget sub_14202DCD0) | 恒写 |
| +12 | u32 | id 对.id — B400 壳 | 恒写 |
| +16 | u8 | 标志字节 (默认 0; dtor 读 `!*(a1+16)` 门 id 重注册) | 不序列化 |
| +24 | 容器 24B | 驻扎 wing 列表 {data@+24, cap@+32, count@+36, alloc@+40} (AddWing 按 id 对去重) | 不序列化 |
| +48 | 容器 24B | **按国索引 CCountryAirContainer* 槽表** {data@+48, cap@+56, count@+60, alloc@+64} (ctor sub_140C47B00 以国家数建容; 容器工厂 sub_140C4B9F0 双注册直证 — 写槽 + 挂 +72 密集容器; HasAccess(Tag) 断言即查此槽非空) | 不序列化 |
| +72 | CCountryAirContainer* | countries 容器数据指针 — {data, count} 指针元 → CCountryAirContainer (§4.15.9) | c>0 |
| +73..+83 | — | = countries 容器尾 {cap@+80} | |
| +84 | u32 | countries 容器计数 | c>0 |
| +85..+95 | — | = countries 容器尾 {alloc@+88} | |
| +96 | u32 | carrier.type — id 对之 type (id 对 {type, id}) | else 分支恒写 (无 state 即写, 载具基地) |
| +100 | u32 | carrier.id — id 对之 id | |
| +104 | CState* | state 对象 → state = *(*(a+104)+88) | 状态指针非空; combat_stats 国修门真身: resolve(_pPool → air_base idpair@+24/+28)+104 == 0 (海上/载具/未指派, 基地无 state) → 翼 combat_stats 吃属主国修正 {201=navy_carrier_air_attack_factor / 202=targetting / 203=agility} (各 +100000 基数, 经 wing+2484 tag → cc+1464 查键); ≠0 → 基数 1.0 (定案) |
| +112 | qword | 位置缓存预留槽 — **运行期无写者** (ctor 清 0 后恒 0, 负定案); 位置 getter sub_140C53790 每次现算 | 不序列化 (定案) |
| +120 | uint32 | capacity | 恒写 |
| +124 | uint32 | base 类别枚举 **{0=air_base, 1=rocket_site, 2=gun_emplacement}** (manager loader 断言直证); ctor = sub_140C3AD00(ship) (位 0x2000000000 = 导弹舰); 真值 = u32@+124 (byte@+128 = 下行 has_manpower 的门/值, 勿混) | 恒写 |
| +128 | uint8 | has_manpower_for_recruit_change_to | ≠0 才写 |
| +132 | uint32 | level (默认 1); **唯一运行时写者 = sub_140C5B7C0** (CAirBase vt[24] 建筑等级变化回调, air 分支 = 建筑 i16@+64 当前等级) | 恒写 |
| +136 | uint64 | allow_equipment_type | 位掩码 (>32bit), 恒写; 初值三来源: 陆基惰性创建 0x10036FC00 / rocket 0x1C00010000 / 载具 = 舰 unit 装备位并集 & 0x1F0037FC00 (+124==0 再或 0x10036FC00); GUI: Reorg 可部署装备池过滤 (× cc+3944(+512) 库存 → win+4024 池; sub_14100CFC0) |

#### 4.15.9 CCountryAirContainer (CAirBase countries 元素 0xF8; **CSupplyConsumer 派生, 基类宿主 +0**)

身份: 基类 ctor 0X140C482A0 (类别字节 a2 存 +28: **2 = 空军基地容器**, 4 = 项目消费者); 容器 ctor 0X140C4B9F0 (malloc 0xF8, 换主虚表 0x142958710, 双注册 = base+48[tag] 槽 + base+72 密集容器)。vtable 槽: [2] writer 0X140C668B0 (先调基 writer 0X140ED0400) / [4] loader 0X140C61360 (default → 基 loader 0X140ECA2E0) / [8] postload·重挂 0X140C59380 / [9] id 生成 0X14221E990 ({type=4713, id=全局自增}) / [10] GetNeededSupply 0X140C4D770 / [11] GetSupplyLocation 0X140C4D490 / [12] SetMotorization 0X140C047D0。

CSupplyConsumer 基类域 (cp+0..+160; 不序列化段):

| 偏移 | 类型 | 名称/语义 | 初值 |
|---|---|---|---|
| +24 | u32 | 保留 | 0 |
| +28 | uint8 | 消费者类别 (2=空军基地容器 / 4=项目消费者) | ctor a2 |
| +29 | uint8 | motorization_level (恒写 token 19943; vt[12] setter) | 0 |
| +30 | uint8 | 未名 (ctor `WORD@29=256` 高半) | 1 |
| +32 | fixed×1e-5 | 总需求侧缓存标量 | 100000 |
| +40 | fixed×1e-5 | _AskedSupply (供网回填; 断言 supply_consumer) | 100000 |
| +48 | fixed×1e-5 | **补给比** = 1e5×_ReceivedSupply/_AskedSupply (asked=0 → 1e5; sub_141A0AFB0) | 100000 |
| +56 | fixed×1e-5 | defines 下限运算派生值 (sub_1424EF6F0(1e5)) | 派生 |
| +64 | fixed×1e-5 | _ReceivedSupply (累加, clamp 到 +40) | 100000 |
| +72..+88 | qword 零群 | — | 0 |
| +96 | 容器 24B | pdx 容器 {data@+96, cap@+104, count@+112} | — |
| +120..+152 | 标量区 | **+128 = 在基地机数 / +136 = 需求权重和** = GetNeededSupply 副作用写点 (needed = BASE_AIR_SUPPLY_MULT_FOR_TRUCK_BUFFER × Σ逐池逐翼 sub_140F625B0) | 0 |

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +160 | fixed×1e-5 | disrupted_supply (基 writer) | >0 才写 |
| +168 | idpair | 所属 air_base 引用 (+168/+172; postload vt[8] 逐容器回写; GetSupplyLocation vt[11] 解析: 陆基 → 省 id, 载具 → ship+1832 → taskforce vt[11]; 断言 `Country air container without airbase when calculating supply location`) | |
| +176 | tag_id | country (loader 串 10394 → tag 反查; 失败报 "Air base country container refers to invalid tag: ") | 恒写 |
| +184 | CAirWingPool* 向量 | 该基地该国**翼池**指针数组 {data@+184, cap@+188, count@+196} — 元素 = CAirWingPool* 非裸翼 (§4.15.3) | |
| +208 | fixed×1e-5 | operational_status = **可运转州占比 (战争控制面, 与燃料无关)**: 写者链 sub_140C65D40 (100000 × sub_140C4FB60 逐州 sub_140D45270 控制/交战判定 / 基地省列表省数) → sub_140C63FA0 (≤0 且旧值 >0 时逐翼取消任务/换序后落值); 载具/海上基地恒 100000; 读者 = 消耗结算门 / sub_140C4CA10 (>0 门) / sub_140C4C150 (daily, ≤0 断言并除名基地) | ≠100000 (≠1.0) 才写 |
| +216 | fixed×1e-5 | capacity_penalty = clamp(1e5 − 超容比×CAPACITY_PENALTY, 0, 1e5) (sub_140C579F0 计算; 超容比 >0.9 直接 0; 载具基地再乘国家修正 268; 未超容恒 100000 — 输入纯基地超容, 与燃料无关); 基地不可运营 (cp+208 ≤0) 或州沦陷谓词真时整段清零 (sub_140C57B70) | ≠0 才写 |
| +224 | fixed×1e-5 | fuel_consumption = 每小时清 0 后**逐池累加** sub_140F5BA20 (任务/训练消耗现算; executing 分支机数 = m+224 无门直过) — sub_140C57B70 (ProcessAirBasesHourly 并行段: sub_140C5EFC0 → tbb 分裂 sub_140C45D50/叶 sub_140C67630 → sub_140C579F0 capacity_penalty 后逐容器调用) | ≠0 才写 |
| +232 | fixed×1e-5 | base_fuel_consumption = 同循环逐池累加 sub_140F5B720 (基础 = 翼系数×机数, 无论任务; executing 无门直过) | ≠0 才写 |
| +240 | fixed×1e-5 | received = 该国在该基地实获燃料: 每小时结算扇出清 0 (sub_140C4F920, 唯一调用者 sub_1410F71B0; 只扫 sa+16 与 sa+40, 火箭表不在) → 分配直写 = grant (sub_140C4BB10, 唯一调用者 sub_140F3080, 按需求优先级 2/1/0 三轮); 上游 = sub_1407164E0 (cc+5504 燃料结构) ← sub_1401D85A0 hourlyUpdateUnits ← DoCountryHourlyUpdates; 基地燃料满足比 getter sub_140C543E0 = clamp(1e5×received/consumption, 0, 1e5) (consumption=0 → 1e5) | ≠0 才写 |

loader 0X140C61360: 12434→+208 / 12435→+216 / 15130→+240 / 15289→+232 / 11955→+224 — **五字段全落字段**; 不序列化 = 基类供网侧 (+32/+40/+48/+64) 与 +128/+136 (载入后首个供网 tick 重建); 零态即满态 (满足比 1e5 无封锁门, 翼照常出动)。

**翼级燃料 = 无持久字段, 逐时现算** (参与门 = 执行中 或 (训练位 ∧ 装备允许 ∧ 非转移仓库 wing+105 ∧ 已部署 wing+84≥wing+80 ∧ 非转移中) 且过昼夜门 sub_140F80A40 与拥挤门 sub_140F80930 (1e5×机数/容量 ≥ AGGRESSION_THRESHOLD[激进度 m+28] 才计入)):

| 变体 | 函数 | 语义/公式 |
|---|---|---|
| 上限估算 (UI) | sub_140F5B4C0 | MISSION_FUEL_COSTS[任务位] × 机数 (m+224 或训练 wing+108) × FUEL_COST_MULT × 翼系数合成器 sub_140F5F880 /1e5; period≠2 按昼夜小时折算 (含天气折算) |
| 当前实际 (累加用) | sub_140F5BA20 | 同上 (m+224; 训练位 11 × wing+108), 无天气折算 |
| 基础 (在基地) | sub_140F5B720 | 1e5 × wing+1448 × wing+108 /1e5 (无任务门) |
| 最大理论 (UI) | sub_140F5BFC0 | max(MISSION_FUEL_COSTS[0..17]) × 国家修正414合成 × 机数 |

翼燃料系数合成器 sub_140F5F880 = wing+1448 (每机基础燃料系数, fix5, 定义副本区随装备定义拷贝带入) + 国家修正414 + (100000 或 王牌修正414+1e5) + 战区修正414(按任务) + 天气修正414; 修正键 414 经 wing+2484 tag → cc+1464 查 CModifier。MISSION_FUEL_COSTS = 18 元 define 表 (索引 = 任务位 = log2(任务 token), 位 11 = 训练); 另有副表 qword_1433397B8 = **海军任务燃料消耗表** (三读者全在海军域: 任务燃料查表) — 「AI 评估用」系误记。

**低燃料行为**: 不取消任务 — 任务效率乘 f(ratio) = ratio×(1e5−MISSION_EFFICIENCY_MULT_AT_LACK_OF_FUEL)/1e5 + MEMLALF; 任务取消门是 operational_status (控制面) ≤0。

任务效率 sub_140F78500 = **四惩罚项积** (覆盖比反项 × capacity_penalty 反项 sub_140C53FD0 读 cp+216 × 补给比反项 sub_140C54ED0 读 cp+48, a4 旗可跳过 × MEMLALF 燃料插值) × (1 + 修正键 17 AIR_MISSION_EFFICIENCY 三源和) — 燃料是**唯一乘点**, 零燃料 = 效率 25% (与陆军的独立惩罚比 getter、海军的战斗数值加法式**均不同构**)。

XP 两链同乘满足比: field-XP sub_140F5DFA0 (×修正键 437 AIR_MISSION_XP_FACTOR) / 训练 XP sub_140F5F1B0 (×修正键 99 AIR_TRAINING_XP_FACTOR) — **翼无 org 字段 (负定案), XP 增长即等价物**。

出动数与燃料无关 (零燃料不停飞, 在执行门层再证): 出动数 sub_140F78360 三档 — rocket = 导弹槽系数 (无州 = MISSILE_LAUNCHER_SLOTS, 有州 = 州建筑表扫描) / gun = 1 / air = RNG roll × 姿态表 tf+1260; 任务执行门 sub_140F79A00 (七门: active/region/机数/昼夜/拥挤/载具区域/出击数>0) 与紧急出击门 sub_140F79C10 逐小时 roll。损失记账处满足比 <1e5 反而按比**缩减** (= 减免非惩罚)。

**空军无海军式 OUT_OF_FUEL 战斗修正 (负定案)**: 海军 FEX 空侧解算 sub_141978E30 体内无燃料三字段引用 (该函数定性见 §4.15.12 — 非对空战通用解析器)。

翼装备增援链 (与 CSupplyConsumer 无关 — 负定案: CSupplyConsumer 只管基地补给/燃料): 库存分配 = sub_140C54850 桶 / Σ需求 sub_140C4E8A0 / sub_140F5C370 权重 = 执行中?500 + 缺额 + 1000×priority (资格门含任务掩码 variant+1040); 损失链入口 (**§4.15.9 五入口 taxonomy**: 区域空战 sub_140F862A0 / 对地-AA 与陆战 AA sub_140F86A40·sub_1412AADD0 / 空难 sub_140F5DD80 / 部署超容 / 轰炸还击; 旧「三入口」行已重排) → sub_140C5C5C0 双方记账 → sub_140F63580 "KillAirplanes" 装备/人力扣减 + sub_140F64770 统计/租借原产国/事件; **装备损失不回库存, 唯一回库通道 = 翼除名 100% 退还** (sa+112 消费 sub_140F62AF0 三件套: 退还 sub_141011250 + ace 回收 sub_14061BC70 + 删翼 sub_140F66A40; 空池 pool+52==0 → vt[0] 销毁)。

#### 4.15.10 地勤 (ground crew) — 花人力买一次性任务效率加成

与燃料链**无交集** (负定案): 不是每小时消耗物, 而是**国家级决议**购入的修正键 17
(AIR_MISSION_EFFICIENCY) 一次性加成。

| 项 | 值 |
|---|---|
| defines | BOOST = `qword_143337CC0` / COST = `qword_143337C08` (AIR_MORE_GROUND_CREWS_COST) |
| 命令 | `sub_141945190` (Execute) / `sub_141948200` (IsValid) |
| 购买原语 | `sub_1406E92B0` |
| 台账 | cc+1240 (键 = 指针, 元素 +16 已付 / +56 一次性旗) |
| 消费点 | 任务效率 sub_140F78500 的修正键 17 三源和之一 |
| GUI | 四件套 (基地面板相关按钮族) |

#### 4.15.11 CAirWingsSelectionList (ctor sub_141F5D940)

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

#### 4.15.12 空战解析调度链 (陆 §4.22.9a / 海 §4.22.10 的空军等价链)

**定性定案**: sub_141978E30（「空战解决器」判读废）实为**海军 FEX 空侧解算**
（唯一调用链在 naval_fire_exchange_group, §4.16.12a 邻域），非对空战通用
解析器。区域空战真链如下（定案）。

**调度**: 区域空战挂 CStrategicAirManager::HourlyUpdate (sub_140C57D30, §4.2.17)
步6 逐 SA 串行段 **sub_140C5F4C0**。损失五入口 taxonomy 重排（定案）:
区域空战 cat1（sub_140F862A0 狗斗）/ 对地-AA cat2（sub_140F86A40）/ 陆战 AA
cat2（sub_1412AADD0）/ 空难 cat3（sub_140F5DD80）/ 部署超容 cat4
（sub_140C5B380）/ 战略轰炸还击 cat5（sub_140F75A00）/ 海军 FEX（旧
sub_141978E30）。

| 段 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 接战判定 | sub_140C591C0 | 区域活跃 byte 网格 + 敌 SA 交战判定 → 收集己方 air_superiority\|interception 任务（m+20 & 5）与敌执行中任务, 按 air_defence×air_agility 排序（sub_140C43580/C43B80 归并）— **没有纯空优 vs 空优自由空战, 只打正在执行对地/对海任务的敌任务** | 定案 |
| 狗斗解析 | sub_140F81A20（拦截份额掷骰+空战XP）→ sub_140F7BE70（逐敌任务对）→ **sub_140F862A0** | 速度加成 = 0.65×base×(min(攻速/守速, 3.5)−1); 敏捷减伤 = 0.45×base×(min(守敏/攻敏, 4.0)−1) 仅守优生效, 归一除数 800/100; **顶速伤害加成项 (TSDBF 0.025) 原版恒 0** — 内层 trunc((spd/100)×2500/1e5) 在 spd<4000 截断为零 (双重定标瑕疵); 击坠 = AIR_COMBAT_DAMAGE_SCALE(载具档, vanilla 1/5)×总攻值×0.01÷守方 air_defence, base = 0.2×分配机数, 随机取整; 损失钳 ≥100 量纲 = **0.001 架** (100 fixed5, 非 1 架), 多机钳分配双钳 ≥100 同值实参; 防守条目 count 消耗 = −round(分配/3); cat1 归因 + m+152/164 损失账（**翻案: m+152 = 小时累计被击坠数**, 非已飞里程; m+156/160 = 击杀方王牌 id 对 / m+164 = 击杀方 tag; m+208 = 拦截因子缓存）, 步9 sub_140F87550 统一 KillAirplanes | 定案 |
| 拦截/扰断 | 步6 sub_140F7BE70 → 步7 sub_140F77360 → 步8 sub_140C4C570 | 三段全小时活管道: 写敌任务 m+176 taken（DISRUPTION_* defines）→ 写己方空优 m+184（ESCORT_*, 修正键 12; **ESCORT 侦查因子复用 DISRUPTION_DETECTION_FACTOR 槽, 无独立 define**）→ 折 m+168 → 对地结算 sub_140F78160 出拦截因子（存 m+208; **= clamp(1−sqrt(taken/防御骰)/3.162, 0.001, 1), PE 除数 316200 = 手写 sqrt(10) 精确**; 防御骰 = 出动×(1+速)×(1+0.5攻)×(1+0.5防)）, 损失 = 出动数×(1−因子), 归因 m+200 扰断方 tag | 定案 |
| 对地 | **sub_140F82110 ProcessGroundMission** → sub_140F82CA0 | 任务位→目标收集器全表; 多态目标分发（建筑/CAS 入陆战 sub_140BB8380/港击/战略轰炸 sub_140F75A00/师直伤 sub_140C01B70/陆战 vt[240]）+ 州-AA+SAM 掷骰 sub_140F86A40（÷air_defence）; paradrop/布雷扫雷分叉 | 定案 |
| 空优聚合 | sa+224 160B 行 | pass25-29 产出 + sub_140C66170 友敌聚合 (+0/+8/+16/+24); 消费 = sub_140C54230 制空惩罚公式与国家级均值 sub_140C655F0 | 定案 |

defines 新钉 30+（DISRUPTION_*/ESCORT_*/COMBAT_DAMAGE_SCALE/ACE_*/SAM_MISSION_
SUPERIORITY/ANTI_AIR_*、修正键 1/12/19/118/356/394/395）; AIR_COMBAT_FINAL_
DAMAGE_{SCALE,PLANES,PLANES_FACTOR} **三件套全零读者（负定案）**。m+88 = 8B
{region, dist} 对（定案）。


#### 4.15.13 链内深扫定址补注表 (e4 批 G 快裁 B 档集中落账; 置信 = 快裁级, 细作时升定案)

| 来源 | 函数与身份 / 建议落点 |
|---|---|
| part01 | sub_140BB1070（711 行，#13） / 空军 / 书 `s4_15_air.md:341` 翼级燃料行（昼夜门 sub_140F80A40/拥挤门 sub_140F80930/系数合成器 sub_140F5F880 均已点名）补聚合体函数名与链（HourlyUpdate → sub_140C57D30 → thunk sub_140BB37D0 → 本件，rb-tree 计数登记） |
| part02 | sub_140BB0860（467 行） / 空军任务-联队追踪 / 书 `s4_15_air.md` 新增「air_update_tracer（任务-联队追踪器）」小节：AirWingEntries[TaskIndex] 对账结构 + 两条断言原文 + 每任务联队表维护语义 |
| part02 | sub_140F7CEF0（392 行） / 空军任务路径节点 / 书 `s4_15_air.md` 新行：airmission 路径节点（NodeIndex>=0 不变量） |
| part04 | sub_140C53270 (#4) / 空军计数/效率聚合（AIR_COUNT_ORIGIN/AVG_EFFICIENCY 宿主 + strategicair 链 + 地图箭头共用） / s4_15 空军册（§4.2.17 战略空军链/计数聚合段） |
| part04 | sub_140F7E600 (#10) / 地面任务执行/评估步（ProcessGroundMission 直调 ×2） / s4_15 空军册（s4_02:488 步10-12 补内部；与部分03#2 孪生合并细作） |
| part04 | sub_140F7A760 (#16) / 空军任务省坐标校验/路径步（airmission.cpp 断言实名） / s4_15 空军册（任务路径规划域，宿主 sub_140E0D390 一并定案） |
| part04 | sub_140BB3800 (#17) / 战略空军链联队聚合（strategicair.cpp 宿主 → airwing HourlyUpdate 族） / s4_15 空军册（§4.2.17 步补内部） |
| part05 | sub_140C64EE0 (#6) / 战略空军 §4.2.17 步2 lambda_1 tbb 分裂体体内段（sub_140C46030 书载实名，本件系其内部） / 书 §4.2.17 步2 / s4_15 战略空军册补 lambda 簇内部 |
| part06 | sub_140F852A0（#6） / 空军任务指派 / 书 `s4_15_air.md` §4.2.17 任务链补：StopTrainingAtMax define 训练门 + raid 任务指派串；7 调用方含书载 HourlyUpdate sub_140F62750，一并注 |
| part06 | sub_140F7DDD0（#11） / 空军任务执行共用步 / 书 `s4_15_air.md` §4.2.17（ProcessGroundMission 步12 宿主 + airbase 断言件双证，4 调用方定址） |
| part06 | sub_140E7EE70（#14） / 空降落地处理 / 书 `s4_15_air.md` 空降任务节（PROV_TEXT_* 文本键 + 唯一调用方 sub_140F84680）+ `s4_12_events.md` on_action 表注 on_units_paradropped_in_state 派发点 |
| part06 | sub_140F76470（#29） / 空袭目标消费 / 书 `s4_15_air.md` 空袭节（"Consumer without Supply Location targetted for Air Strike!" + 唯一调用方 sub_140F82CA0） |
| part07 | sub_140F814A0（#3） / 空军侦察执行 / 书 `s4_15_air.md` §4.2.17 任务链补：ProcessAirRecon 子步定址 + (100000−占比)×强度/1e5 四路分摊公式 + CConvoyClient 过滤 |
| part07 | sub_140F76CC0（#8） / 空军战略目标收集 / 书 `s4_15_air.md` 补 SStrategicTarget 收集/评分步（vtable 两态 + 0x1410D 前线族取点 + 定点修正合成） |
| part07 | sub_140C5DCB0（#10） / 空军任务注册校验 / 书 `s4_15_air.md` 任务注册表节补：_ActiveMissionRegions/_ActiveMissions/_AllActiveMissions 三表操作 + 断言门 |
| part07 | sub_140F7CAC0（#16） / 空军补给打击目标 / 书 `s4_15_air.md` 补 SAirSupplyTarget/STargetPriority 收集步（与 #8 成对） |
| part08 | sub_140F856B0（190 行，#11） / 空军/任务(raid) / 书 `s4_15_air.md` 任务指派节（part06 #6 sub_140F852A0 同区）补「联队突袭任务指派」本件（7 宿主含 CAirWing::HourlyUpdate/部署分派/转场恢复三书实名件）；raid 语义（空袭 raid）细作时与 s4_27_raid 对碰 |
| part08 | sub_140C60290（183 行，#28） / 空军/战略空军 / 书 `s4_15_air.md:335` ProcessAirBasesHourly 行（sub_140C5EFC0 已实名）补训练任务许可分支（MISSION_TRAINING 掩码断言） |
| part08 | sub_140F800F0（182 行，#29） / 空军/王牌 / 书 `s4_15_air.md` 补王牌事件链节（aces.cpp 单元 0x14061A-B 全库无册：击杀处理 sub_14061AA90 → 本件 scope 构建派发；王牌域若成册再迁） |
| part08 | sub_140C648B0（181 行，#39） / 空军/战略空军(对舰) / 书 `s4_15_air.md` §4.2.17 strategicair 行补对舰目标校验件（pShip 断言 + 基地准入 + 翼目标选择；触发链含翼转移推进 sub_140F64B70 与舰船击沉链 sub_141975480 双书实名宿主） |
| part09 | sub_14070B680（176 行，#8） / 空军/军事 / 书 `s4_15_air.md` 补行：按国家单位直方图原语（来源国+控制国双计数，+72/+76 控制旗门）；10 个空军任务侧调用方与用途（疑对地打击目标计数）细作时定 |
| part09 | sub_140F85C30（174 行，#12） / 空军/王牌 / 书 `s4_15_air.md` 补王牌 on_action 六名清单与派发件（on_ace_killed/on_ace_promoted 等 ×7 槽 0x14333D5F8..628；触发链 = 空战结算 sub_140A774B0）；与 §4.12 事件域 on_action 机制交叉注 |
| part09 | sub_140F7E290（172 行，#18） / 空军 / 书 `s4_15_air.md` 补行：对地目标权重累积器（距离钳位 + 师数占比 1e10×命中/(1e5×师数) 定点缩放 + 32B 目标条目输出；first-match-only 参数） |
| part09 | sub_140C5D240（171 行，#20） / 空军/空域统计 / 书 `s4_15_air.md`（或 `s4_16_navy.md` 交叉）补行：空域统计登记链（airregionstatistics.cpp 枚举 8 = 统计种类；参战国家对数组产出 sub_140C53270 + 逐国登记 sub_141962C40）；触发 = airmission.cpp 任务处理件 sub_140F82CA0 |
| part09 | sub_140F83AA0（170 行，#23） / 空军/海军水雷 / 书 `s4_15_air.md` 补空侧布雷/扫雷任务处理行（NAVAL_MINES DLC 门 + CAirMission::ProcessNavalMinesPlantingAndSweeping + 布雷 sub_140E9F1D0 与 `s4_16_navy.md:552-553` 海军舰侧镜像互注） |
| part10 | sub_140F84680（#1） / 空军/空投 / 书 `s4_15_air.md:411` ProcessGroundMission 行补：paradrop 分叉地址 = sub_140F84680（被调 sub_140E7EE70 = part06 #14 空降落地，on_units_paradropped_in_state 派发） |
| part11 | sub_140F84A50（#37） / 空军 / 书 `s4_15_air.md` 补行：翼级损失×系数结算（qword_143334C08 门、sub_140F7B540 结算、sub_140C5CD60 gs+840 表落地、通知 sub_140D19260→sub_141179A90）；调用方 sub_140F82CA0；语义细节待细作 |
| part11 | sub_140F66BE0（#9） / 空军 / 书 `s4_15_air.md:139` _StatsPerMission 行注补重建器函数名 **sub_140F66BE0**（18 位任务掩码→remap int8[18] + 624B 条目数对齐；包装 sub_140F661E0） |
| part12 | sub_140F5D8C0（135 行，#26） / 空军 / 书 `s4_15_air.md` 翼级生命周期节补注销/换组路：排序表摘除 + airwing.cpp:84 断言 + air group 摘除对（sub_1414EC080/1414EBC80）+ 销毁 |
| part13 | sub_140C5DAA0（130 行，#8） / 空军/战略空军 / 书 `s4_15_air.md` 战略空军节补行：region 活跃任务表注销去重步（_ActiveMissions/_AllActiveMissions Contains 不变量；链 = airmission 任务收尾 sub_140F859D0） |
| part13 | sub_140F73A40（126 行，#30） / 空军/任务 / 书 `s4_15_air.md` 补行：airmission 递归容器遍历件（part02 #40 路径节点同族链） |
| part13 | sub_140B662E0（126 行，#32） / 空军/联队 / 书 `s4_15_air.md` 补行：联队任务许可/基地访问校验链（airwing IsAnyMissionTypeAllowed → 本件 → strategicair HasAccess(Tag)） |
| part14 | sub_140F859D0（#38） / 空军 / 书 `s4_15_air.md` 任务节补 mission-airmission 绑定步 = sub_140F859D0（翼/基地登记 + 人力比 +80 + 航路联动；airmission.cpp:809/816） |
| part14 | sub_140F68420（#39） / 空军 / 书 `s4_15_air.md`（airwing.cpp 邻域，s4_02:481 CAirWing::HourlyUpdate 行同注）补人力缺口补足步 = sub_140F68420（808 池正负双向 + a1+128 累计） |
| part15 | sub_140F796E0（109 行，#33） / 空军/任务派发 / 书 `s4_15_air.md` 任务派发节补：翼任务位标志逐位派发总控（13+ 位 → 任务码 2..0x8000；与 part04 #10 sub_140F7E600 / part07 #16 sub_140F7CAC0 同簇并案；位表细作时逐位对 CAirMission 任务枚举） |
| part15 | sub_140F65F20（109 行，#34） / 空军/翼级 / 书 `s4_15_air.md` 补 CAirWing::HourlyUpdate（s4_02:481）内步行：全局表插值 + token 115 修正 + 随机 Roll 累加翼+568；**累积量语义细作先裁**（经验/损耗/燃料嫌疑，getter +200/+212 择路待钉） |
