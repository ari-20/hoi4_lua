

### 4.15 战略空军族 (CStrategicAirManager → CStrategicAir → CAirWingPool → CAirWing)

> 坐标注: 本册表内偏移一律 = 裸对象坐标; 仅 0x2958918 vtable方法 this = R+8 (调整桩 sub_140C4AD58 `a1−8` 直证; ⚠ 0x140C5B7C0 回调体内亦见 `sub_140C4BB60(a1−8, …)`, 「仅」字待裁 — 需 .rdata 槽位证), 其余族 writer (CStrategicAir sub_140C66970 / CAirWing sub_140F68B30 / CAirWingPool sub_140F68FF0) this 与书表 1:1。
> 换算仅在此注, 正文只用书基坐标。

mgr = *(gs+1680); 两级结构 pool → wing (定案)。

#### 4.15.1 CStrategicAirManager (mgr = *(gs+1680); vtable 0X142958918)

| 偏移 (mgr) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | CNonstaticIdGenerator\<77\> 内联 16B | air_theatre_index 生成器 {vtable@+16, id@+24} (ctor 目击+探针互证) | id 恒写 (0 也写) |
| +32 | CNonstaticIdGenerator\<78\> 内联 16B | air_group_index 生成器 {vtable@+32, id@+40} (同证) | id 恒写 |
| +48 | 匿名结构 (NNB 形状) 向量 24B | 国条容器 {data@+48, cap@+56, count@+60, alloc@+64} | 非空元素 = CStrategicAir* (每国一个, vtable 0X29587D8; writer 以 elem+144 tag 分键) |
| +72 | 匿名结构 (24B 形状) 向量 24B | per-state 映射 **X = air_base** {data@+72, cap@+80, count@+84, alloc@+88} (按 state_count 扩容; per-state 24B 条 {省 id 数组@+0, 计数@+12}; 定位函数 sub_140C53910: base+124==1→Y / ==2→Z / else→X, state+88 = state id; MAP_ERROR 断言族) | 不序列化 |
| +96 | 匿名结构 (NNB 形状) 向量 24B | per-state 映射 **Y = rocket_site** {data@+96, cap@+104, count@+108, alloc@+112} (同 X 条形; 构建链 sub_140C59E30 地图初始化: 州建筑三字段 +784/+883/+867, 省 +5976/+5977/+5978 标志, MAP_ERROR 校验; gs 入口 sub_1401E13E0) | 不序列化 |
| +120 | 匿名结构 (NNB 形状) 向量 24B | per-state 映射 **Z = gun_emplacement** {data@+120, cap@+128, count@+132, alloc@+136} (同上) | 不序列化 |
| +144 | CAirBase* | 州基地容器 容器数据指针 — {data, count} | 指针元, vtable 0X2958780 过滤; **GUI: 空军基地地图图标解析尾** (CAirBaseMapIcon: sub_140C4AF30 = 本容器[state+88], 与 +192 炮位/+168 火箭同形 per-state 稀疏索引第三址) |
| +145..+155 | — | = 州基地容器尾 {cap@+152} | |
| +156 | uint32 | 州基地容器 容器计数 | |
| +157..+167 | — | = 州基地容器尾 {alloc@+160} | |
| +168 | 匿名结构 (火箭基地) | 火箭基地并列阵列 容器数据指针 — {data, count} (定案) | 指针元, 同 CAirBase 类 (vtable 0X2958780), 与 +144 州基地 948 槽平行; 元素 base u32@+124 == 1 → 块键 rocket_site (13303), 否则 air_base (12214) — manager writer 0X140C66C60 尾段分支 (GER id=575 state=62 cap=100 lvl=1 实证); 同 per-state 稀疏索引 (CRocketSiteMapIcon resolve 尾调用 sub_140C4B040; tooltip 落 site+120 等级 / site+104 州 + ROCKET_SITE_LEVEL/CAPACITY) |
| +169..+179 | — | = 火箭基地容器尾 {cap@+176, count@+180, alloc@+184} | |
| +180 | uint32 | 火箭基地并列阵列 容器计数 | |
| +192 | CAirBase* 向量 24B | gun_emplacement {data@+192, cap@+200, count@+204, alloc@+208} (指针元; writer token 10086=gun_emplacement 逐元写; loader "Invalid gun emplacement" 断言) | per-state 稀疏索引 (CGunEmplacementMapIcon 消费; emplacement+48/+72/+104 容器形态) |
| +216 | CAirBase* | 载具 (carrier) 基地容器 容器数据指针 — {data, count} | 指针元, 无 vtable 过滤 (定案) |
| +217..+227 | — | = 载具容器尾 {cap@+224, count@+228, alloc@+232} | |
| +228 | uint32 | 载具 容器计数 | |
| +240 | 匿名结构 (NNB 形状) 向量 24B | 遗留未用容器 {data@+240, cap@+248, count@+252, alloc@+256} (无任何写入 — 定案) | 不序列化 |

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
| +88 | CAirWingPool* 向量 24B | air_wing_pool {data@88, cap@96, count@100, alloc@104} | 元素 = CAirWingPool* (vtable 0X297AE38); [N] = 池序 |
| +112 | 匿名结构 (NNB 形状) 向量 24B | **待除名翼队列** {data@+112, cap@+120, count@+124} | 翼 hourly 尾段推入 (无有效位置且无机 / 转移仓库 / 未部署完成 / 转移中); 管理器 hourly 首段清空 (sub_140F62AF0 逐翼处理三件套: 装备退还 sub_141011250 100% + ace 回收 sub_14061BC70 + 删翼 sub_140F66A40; 空池 pool+52==0 → vtable[0] 销毁) |
| +136 | CStrategicAirManager* | manager 回指 | ctor 实参 a3 |
| +144 | uint32 | country_num_id | 国家 id; 翼燃料系数合成器 sub_140F5F880 的 GetCountry 兜底路径 (翼无 tag 时经 pool+64 → sa+144) |
| +152 | 匿名结构 (24B 形状) 向量 24B | _ActiveMissions {data@152, cap@160, count@164} — 按 region id 索引稀疏数组, 24B 条 = 内嵌任务指针向量 {data@0, count@+12} | 断言 `_ActiveMissions[RegionID].Contains(pMission)` |
| +176 | 匿名结构 (NNB 形状) 向量 24B | _AllActiveMissions {data@176, cap@184, count@188} — 任务指针数组 | 断言 `_AllActiveMissions.Contains(pMission)` |
| +200 | uint32 向量 24B | _ActiveMissionRegions {data@200, cap@208, count@212} — u32 region id 数组 | 断言 `_ActiveMissionRegions.Contains(RegionID)` |
| +224 | 匿名结构 (160B 形状) 向量 24B | 按战略区 160B 条态势缓存 {data@224, cap@232, count@236, alloc@240} — 双方机数/比率/按国 RB-tree 明细/活动旗标 (制空惩罚公式 0x140C54230 全解; 聚合式所引 **0x140C456A30 系手误地址** — _fnoff.tsv 无此函数起点, 真身应在 0x140C44xxx lambda 簇内待裁) | 不序列化 |
| +248 | uint32 | naval_strike_remaining 容器数据指针 | u32 数组 {data, count}, c>0 |
| +249..+259 | — | = naval_strike_remaining 容器尾 {cap@+256, alloc@+264} (断言「Consumed more port strike limit than available」互证 port strike 限额语义) | |
| +260 | uint32 | naval_strike_remaining 容器计数 | |
| +272 | 匿名结构 (NNB 形状) 向量 24B | 友方 (自+盟友) CStrategicAir* 列表 {data@272, cap@280, count@284} (0x140C4557A0 重建链) | 不序列化; disruption 总量为 0X140C4C570 现算, 非此表 |
| +296 | 匿名结构 (NNB 形状) 向量 24B | 敌方 CStrategicAir* 列表 (同重建链) | 不序列化 |
| +320 | 匿名结构 (24B 形状) 向量 24B | per-region 24B 条稀疏数组 M {data@320, cap@328, count@332} | 条 = 任务指针向量 {data@0, count@+12}; 与 _ActiveMissions 平行维护; 形态高置信/语义推定 |
| +344 | CLoopHistoryContainer* | history 容器数据指针 | 指针元 → CLoopHistoryContainer (§4.3.11 同构); N = 原槽位 0 起 (含空槽递增 — writer 计数器 0 起递实证; idx=i+1 读法系误) |
| +345..+355 | — | = history 容器尾 {cap@+352, alloc@+360} | |
| +356 | uint32 | history 容器计数 | |
| +357..+367 | — | = history/combat_history 容器尾 | |
| +368 | SAirWingCombatData* | combat_history 容器数据指针 | CAirRegionCombatData 数组 (vtable 0X2958968); 元非空才写; N = 原槽位 0 起 |
| +369..+379 | — | = combat_history 容器尾 {cap@+376, alloc@+384} | |
| +380 | uint32 | combat_history 容器计数 | |
| +392 | uint32 | 增援人力账合计 | 自国+附庸; 0x140C44C960 刷新 / 0x140C440120 扣减 |
| +400 | float + map | 按流亡政府 tag 的增援人力池 (unordered_map) | 形态: lf f32@+400=1.0 + RB-tree {sentinel@+408, size@+416} + hash 容器@+424 |
| +464 | 匿名结构 (8B 形状) | quick_wing_deploy_selection | AAFD0 门; ctor 恒建 0xF8B 对象 `sub_141964F90(tag, *(country+3952), *(country+3944))`; loader token 73=diffuse → sub_140A21680 |

#### 4.15.3 CAirWingPool (vtable 0X297AE38; writer 0X140F68FF0)

| 偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +8 | uint32 | id.type — id 对之 type (对 {type, id}) | |
| +12 | uint32 | id.id — id 对之 id | |
| +13..+23 | — | = id 对尾 + air_base 前置 | |
| +24 | uint32 | air_base ref.type — id 对之 type (loader token 12214=air_base 直写; 断言 `_AirBase.IsValid`) | |
| +28 | uint32 | air_base ref.id — id 对之 id | |
| +32 | CAirWing | definition | token@def+8; 内部布局: def+32 = variant 条目数组数据, def+44 = 计数 (16B 条; wing ctor 取 *(variant+1040) 任务掩码; loader 12259 → sub_140AC4FA0 直证) |
| +40 | CAirWing* | wings 容器数据指针 | {data, count}; 元素 = holder 指针, wing 对象 = 容器元素即真基址 (原「holder+16」系帧误差补偿描述, 已废) |
| +41..+51 | — | = wings 容器尾 {cap@+48} | |
| +52 | uint32 | wings 容器计数 | |
| +56 | uint8 | allow_zero_entries | 装备池写门 |
| +64 | CStrategicAir* | 属主国条回指 | ctor sub_140F5A410 a2 形参; loader 0X140C61640 传入 |
| +65..+71 | — | 无字段 — 池 sizeof = 72B (0x48; 两处 malloc 0x48; ctor sub_140F5A410 只写 +0..+64; writer 0X140F68FF0 / loader 0X140F65C70 / postload 0X140F62DD0 均不触 +88/+104) | 不序列化; combat_stats 国修门读链 = resolve(_pPool → air_base idpair@+24/+28) +104 → CAirBase+104 state (门语义见 §4.15.8) — 定案 |

#### 4.15.4 CAirWing (writer 0X140F68B30; 0xA38=2616B; 本表偏移 = 真基址帧 real)

主vtable 0X14297ADA8 (CSelectable 6 槽, real+0) / **副vtable 0X14297ADE0 = real+16** (CReferenceObject 子对象 —
对象层 wing 校验并查副表)。**帧机制定案**: writer/loader/PostLoad 经副表派发, C++ 传入 this = 真基址+16,
体内偏移 = real−16; 本表原版当初以 writer 为锚建表即整体 −16 — 现全表 36 行已按 ctor 0X140F59760
(真基址帧) + writer 0X140F68B30 + loader 0X140F651B0 三方互证逐行修正为 real 帧, **无一行例外**;
总尺寸 0xA38=2616B 不变 (malloc 直证, 无 +16 前置头; 末字段 raid id 对止于 +2611, 尾 pad 满额)。
校验法「uint32==69」判据随移至 **real+24**。证据列: `c`=ctor 行 / `w`=writer 行 / `l`=loader 行 / `x`=旁证。

约定:证据列 `c`=ctor 行,`w`=writer 行,`l`=loader 行,`x`=旁证函数行。类型/语义沿用书表,仅偏移与个别备注修正。

| real 偏移 | 书表值 | 类型 | 名称 | 语义 | 备注 | 证据 |
|---|---|---|---|---|---|---|
| +0 | (未列) | vtable* | 主vtable | CAirWing 主表 0X14297ADA8(CSelectable,6 槽) | 补列 | c7344503 |
| +8 | (未列) | uint32 | CSelectable 基字段 | ctor 实参 = 2(语义待裁) | 不序列化;补列 | c7344495,3814875 |
| +12 | (未列) | uint8 | CSelectable 标志 | 默认 0 | 不序列化;补列 | 3814878 |
| +16 | (未列) | vtable* | 副vtable | CReferenceObject 子对象 0X14297ADE0 = **书表帧原点** | 对象层 wing 校验可并查副表(原注保留);补列 | c7344500/7344504 |
| +24 | +8 | uint32 | id.type | = 69 | 「校验法 uint32==69」判据随移至此 | c7344621,472061,2340097 |
| +28 | +12 | uint32 | id.id | 引擎翼计数器 dword_14333D590 递增 | | 2340098 |
| +32 | +16 | uint8 | CReferenceObject id 注册旗 | ctor 清 0,sub_14221E700 尾置 1(**ctor 返回后恒 1,非默认 0**) | 不序列化;语义升级 | c7344502,472108 |
| +40 | +24 | uint32 | priority | 默认 = dword_143337624(NAir define) | 键 141 恒写 | c7344505;w1183990 |
| +44 | +28 | uint32 | allow_mission_type | 位掩码;默认 = *(首 variant+1040);断言 `_EquipmentMissionTypes` | 键 11057 恒写 | c7344532;w1183991;x727852(拷贝源) |
| +48 | +32 | uint32 | equipment_mission_types | 位掩码(装备可做任务;与 allow_mission_type 区分) | 不序列化;重建器 sub_140F667B0 real 帧直写:+44 基线 + 国旗 0x80(def+1448&0x100000400)+ 规则 19 位 0x1000/0x2000 − **有有效基地(sub_140F61600≠0 基地控制者 tag;非机数判定) 0x800** − 低机 0x400(阈值 = MIN_PLANE_COUNT_AIR_SUPPLY dword_143332D68) | c7344533;x727848-727877;6450788(读 +48&0x400) |
| +56 | +40 | CAirWingPool* | _pPool 回指 | 断言 "Calling hourly update on an airwing with no pool." | 不序列化 | c7344534;x727848,7737778 |
| +64 | +48 | uint32 | air_group.type | id 对 {+64,+68} | 非零且可解析才写(12227) | c7344535;w1184025-1184033 |
| +68 | +52 | uint32 | air_group.id | | | 同上 |
| +72 | +56 | uint32 | transferring_to.type | id 对 {+72,+76};解析链:RH 表→{d@tb+8, mask@tb+20} 24B 桶→obj@+16→*(obj+104)→u32@+88 = region id(0X14221F310) | 写门 = id 对非零且解析非空 | c7344536;x7737757(qword 写);w1183911 |
| +76 | +60 | uint32 | transferring_to.id | | | 同上 |
| +80 | +64 | fixed×1e-5 | transfer_progress | 门 = 转移中或 u8@+121≠0(else 分支直落,非互斥) | 不序列化(转移态载入重算) | c7344537 |
| +88 | +72 | fixed×1e-5 | 转移路程阈值 | StartTransfer 写 sub_140F5B8B0 计算值;sub_140F5D2D0 清 0;sub_140F64B70 比较到站 | 非转移恒 0;载入重算 | c7344538;x7737772(`*(qword)(a1+88)=*v10`) |
| +96 | +80 | uint32 | deployment_time | 门 = u8@+121≠0 ‖ deployment(+100) < deployment_time(+96) ‖ 转移中(同门同出) | 键 19180 | c7344539(qword 清 96..103);w1183941/1183945 |
| +100 | +84 | uint32 | deployment | | 键 12181(先于 deployment_time 发射) | 同上;w1183944 |
| +104 | +88 | fixed5 | 经验增益量/速率 | 每 tick 清 0;训练任务下加入 experience@+536 并以 qword_143331300 封顶;ctor 默认 100000 | 不序列化 | c7344540 |
| +112 | +96 | uint32 | region_to_assign | ≠0 才写(14652) | | c7344541(qword 清 112..119);x7737755;w1183992 |
| +116 | +100 | uint32 | mission_to_assign | ≠0 才写(14653) | | 同上;x7737756;w1183995 |
| +120 | +104 | uint8 | transfer_cancelled → yes/no | 门同 transfer_progress | 键 12252 | c7344542(WORD@120 清 120..121);w1183938 |
| +121 | +105 | uint8 | transfer_to_warehouse | 非转移且 ≠0 才写 yes(13206) | | 同上;w1183931 |
| +124 | +108 | uint32 | count | **序列化**(10730 恒写;loader 落此) | ctor/维护路径尾 = 池总量/1e5 | c7344543(qword 清 124..131),7344673(dword31=/1e5);w1183905;l981534 |
| +128 | +112 | uint32 | manpower | | GUI: 联队人力数字窗(sub_140F622A0 → current_manpower / MANPOWER_AIRWING) | c7344543(qword 清含);w1183947(10300 ← 帧+112) |
| +132 | +116 | uint32 | air_accidents | >0 才写(12857);+= 空难数(sub_140F5DD80) | | c7344544(qword 清 132..139);w1183974 |
| +133..+135 | +117..+119 | — | mission 前置 pad | | ctor 只显式清 132..139 | c7344544 |
| +136 | +120 | uint32 | 累计接收机数 | 加机原语 sub_140F64190 `+=` | 不序列化(加机两型 sub_140F5ADD0/sub_140F64190 之一) | 140F64190 |
| +140..+143 | +124..+127 | — | pad 尾 | | ctor 未显式清 | c7344544 |
| +144 | +128 | CAirMission(内联) | mission | 296B(+144..+439 全封闭);见 §4.15.5 | ⚠ §4.15.5 锚「wing+128」应改「wing+144」,该节内部(mission 基帧)不动 | c7344545(sub_140F75380(翼+18));w1183948(11450 ← 帧+128);l981582 |
| +440 | +424 | uint32 | suspended_missions | 位掩码(2048 与存档 suspended 集一致);≠0 才写(13780) | | c7344548(dword110);w1183982;l981167 |
| +448 | +432 | SAirWingCombatData* | other_combats 容器数据指针 | 24B 容器 {data@+448, cap@+456, count@+460, alloc@+464};data 为 id 对数组本体内联 8B 条 {type@+0, id@+4}(探针定案保留) | | c7344549(sub_14011DF40(翼+56));w1183949-1183952(count 帧+444/data 帧+432) |
| +456 | +440 | — | other_combats 容器 cap | | | 容器形状(24B) |
| +460 | +444 | uint32 | other_combats 容器计数 | | | w1183949 |
| +464 | +448 | — | other_combats 容器 alloc | | | 容器形状 |
| +472 | +456 | CEquipmentVariantPool(内联 64B) | equipment 池 | {data@+504, cap@+520, count@+516, allow_zero u8@+528};16B 条 {variant*, amount×1e-5};ctor 尾填池并置 allow_zero=1,count 处维护同款 | GUI: 装备构成列表(原引「SetupDerived 直读 +488/+500」= 书表帧引述,real = +504/+516);writer 键 12110;allow_zero 写门同生产池(writer 0X141012DB0) | c7344552(sub_14100C710(翼+59)),7344671-7344682(填充/data@504/count@516/allow_zero=1);w1183987;l981452 |
| +536 | +520 | fixed×1e-5 | experience | | | c7344555 (sub_140F65F20 读写) |
| +544 | +528 | uint8 | 经验增长脏标志 | xp 低于 cap 且增加时置 1;ctor 默认 1;HourlyUpdate 门读;xp 步尾清 0 | 不序列化 | c7344556;6450838 |
| +552 | +536 | CModifier 内嵌 192B | wing 动态修正块 | (+552..+743;ctor sub_140555FB0 内核@+568,vtable@+552) | 不序列化 | c7344558/7344569;dtor c7344722(翼+69) |
| +744 | +728 | uint32 | ace.type | id 对 {+744,+748};非零且可解析才写(12770) | GUI: Ace 名/头像(sub_140F5AAB0 → CAce;名 sub_14061A5D0;无 ace → 隐藏+禁用) | c7344570(a1[93]);w1183977 |
| +748 | +732 | uint32 | ace.id | | | 同上 |
| +752 | +736 | CSubUnitDefinition 内嵌副本 ~1656B | 定义副本 | (+752..+2407;尾界 +2407 为末字节,+2408 起下一子对象;ctor copy 自 null object 拷默认) — **负定案:无运行时覆写层**(维持) | 不序列化 | c7344572(sub_1403C77D0(翼+94));dtor c7344717 |
| +2408 | +2392 | i64 向量 | _StatsPerMission | {data@+2408, cap@+2416, count@+2420, alloc@+2424, remap int8[18]@+2432..+2449} — 条目 624B = 78×i64;remap[任务位号]→条目号(0xFF=无);MISSIONS_COUNT=18 | 断言 `MissionIndex < _StatsPerMission.GetSize` | c7344575(sub_140F5A500(翼+301));dtor c7344712 |
| +2456 | +2440 | cstr | name | **恒写(空串照写 "")** — 门 sub_1424BFF30 是 checksum-file 判定(RTDynamicCast CChecksumFile),与 SSO 非空无关 | MSVC SSO 32B:{buf@+2456, size@+2472, cap@+2480=15};GUI: sub_140F60A70 → CSetAirWingNameCommand id 14312 | c7344576-7344578(OWORD 清/size/cap=15);w1183989(27 ← 帧+2440);l981537/981538 |
| +2488 | +2472 | 匿名结构(NNB 形状) | army 对象指针 | token 10397;writer 经 sub_142220260(a2, 10397, army+8) 写 idpair | ptr≠0 才发射本组 | c7344580(a1[311]);w1183998 |
| +2496 | +2480 | uint8 | coverage | 默认 1,仅 0 时写 `coverage=no`(12469=0) | ⚠ 发射嵌套于 army≠0 块内(army==0 时 coverage 不发射;新增备注) | c7344581;w1184002 |
| +2500 | +2484 | tag_id | tag(wtag) | 0 不写(10754 经 sub_140BB4E70) | GUI: combat_stats 属主修正链(tag → cc+1464 查键 {201/202/203}=navy_carrier_air_*;门见 §4.15.8 CAirBase +104 行) | c7344582(dword625=*a2);w1183985;x727855,7737770 |
| +2504 | +2488 | uint32 | government_in_exile_tag | >0 才写(15034;tag 反查) | | c7344583(dword626=*a3);w1184005 |
| +2508 | +2492 | uint8 | reinforcement_setting | 默认 1;19415 恒写 u8 | | c7344584;w1183907 |
| +2512 | +2496 | 容器 24B | 空投运输单位列表 | {data@+2512, cap@+2520, count@+2524, alloc@+2528} — 8B CUnit* 元(unit+800 = `_pAirTransport` 回指互证) | 不序列化;任务位 0x40 = paradrop(断言直证) | c7344585(sub_14011DF40(翼+314));dtor c7344702;6450796(count@2524 门) |
| +2536 | +2520 | uint32 | 空投目标省 | 0x40 任务门:`count@+2524==0 && 省@+2536 > 0`;清零 qword 覆盖 +2536..+2543 | 不序列化;原行「qword 空投目标省」的 qword 形态 = 清零/判零读法,本体 u32 | c7344619(a1[317]);6450796(`*(int*)(a1+2536)>0`),6450807 |
| +2540 | +2524 | uint32 | 任务类型快照 | 传 sub_140F856B0(翼+144, …) | 不序列化 | c7344619(qword 清含);6450801 |
| +2544 | +2528 | uint64 | region 快照(idpair 形态) | 传 sub_140F859D0(翼+144, …) | 不序列化;原表「u32 region 快照」按实读改 qword | c7344620(a1[318]);6450802 |
| +2552 | +2536 | uint32 | carrier_air_wing_kills 容器数据指针 | 24B 容器 {data@+2552, cap@+2560, count@+2564, alloc@+2568};**扁平 16B 元 {key u64 装备类别 bitmask@+0, value u32@+8}**(非 RH map);键经 equipment_category 表 sub_140F8A750 转 token(0x400→fighter / 0x8000→naval_bomber …;**多位键返 token 0** — :52 断言只拦低 32 位内多位 (bitset\<32\>), 高位组合直落复合键分支; 0/未列位 → 19530 unknown) | c>0 才写(19901) | c7344586(sub_14011DF40(翼+319));dtor c7344697;w1184010-1184018(data 帧+2536/count 帧+2548/元读法) |
| +2564 | +2548 | uint32 | kills 容器计数 | c>0 | | w1184010 |
| +2576 | +2560 | fixed×1e-5 | air_untrained_pilots_penalty_factor | xp 步 sub_140F65F20 写「修正值 + 12500」;**本体不序列化** —— writer 仅在门旗置位时发 19863 **无值旗键**(原 writer 链「+2560 值」列不成立) | ctor 低字节 0xAA(其余 7B 未显式清;ctor 尾即调 xp 步算出,语义待裁);块 dtor sub_14014D1D0 挂 +2576 | c7344597;dtor c7344692(翼+322);w1184023 |
| +2584 | +2568 | uint8 | penalty 已算门旗 | sub_140F65F20 置 1;writer 19863 发射门 | ctor = 0 | c7344598;w1184023 |
| +2592 | +2576 | STimedDisabling* | timed_disabling | malloc 12B 对象{remaining_hours uint32@+4, should_start_on_transfer uint8@+8}(ssot 运行时恒 1,存档读回 no — 演化字段);writer 0X141A2F740(块键 15799);td 空按默认 0/no;HourlyUpdate 尾 sub_141A2F6C0 解引用 tick | | c7344600-7344615(a1[324],malloc(0xC)+sub_141A2F690);dtor c7344687(翼+324);w1183908(ptr ← 帧+2576);6450843 |
| +2600 | +2584 | uint32 | role_icon_index | >0 才写(15526) | GUI: 联队角色图标(sub_140F5F670) | c7344616(dword650);w1184034 |
| +2604 | +2588 | uint32 | raid_instance.type | id 对 {+2604,+2608};任一非零且可解析才写(19183;sub_142220180 先 id 后 type) | | c7344617(qword@2604);w1184037-1184045 |
| +2608 | +2592 | uint32 | raid_instance.id | | | 同上 |
| +2612..+2615 | — | — | 尾 pad | 总尺寸 **0xA38=2616B 不变**(malloc 直证;末字段止于 +2611) | | 2340090 |

双vtable槽表(主表 6 槽/副表 10 槽)为函数地址表,不涉偏移,**原样保留**,无需改动。

**−16 错位根因 (定案)**: CAirWing = 多继承双vtable对象 — CSelectable 主基 @W+0 (主vtable 0X14297ADA8; W+12 = **IsSelected 旗**, dtor 断言 356 "AR-17034" 直证) + CReferenceObject←CPersistent 副基 @W+16 (副vtable 0X14297ADE0; **序列化槽 [1]Save/[2]writer/[3]Load/[4]loader/[8]PostLoad 全挂此基**)。书表原按 reader/writer 的 this (= W+16) 建表 → 书偏移 = 规范偏移 − 16; 本表已改双坐标 (规范 W | 旧书帧)。三路直证: ① 翼 loader sub_140F651B0 (vtable[4]) this = W+16 全程 a1+书偏移落字段; ② 池 loader sub_140F65C70 尾直调翼 vtable[3] 传 v13+2 (= W+16) 且先 `v13[7]=池` (_pPool 在内容加载前就位); ③ ctor/HourlyUpdate/KillAirplanes/转移推进/dtor 30+ 字段全按规范偏移零反例。

**holder 术语废除 (定案)**: CAirWingPool wings 容器 (P+40, 计数 P+52) 元素 = **CAirWing 规范对象指针 W 本体**, 无 holder 间接层 (池 loader push 的 v15 = ctor 返回值 W + RemoveWing sub_140F66A40 精确指针比对双直证)。旧「wing = holder+16」即 W+16 = CPersistent 子对象 = −16 错位的另一表述, 全书统一「规范基址 W」。§4.15.3 池为单vtable对象无错位 (本批池 loader 逐 token 复核)。

**运行时机制增补** (实现层定案, 摘要):

| 机制 | 定案 |
|---|---|
| XP 混合公式族 | 全簇唯一经验写点 = sub_140F63E00; KillAirplanes 吃 AIR_WING_XP_LOSS_WHEN_KILLED × 友方领土减免 (AIR_WING_XP_LOSS_REDUCTION_OVER_FRIENDLY_TERRITORY_FACTOR × 区域参与国友方份额 ×(1+国修正键6)); 训练钳 AIR_WING_XP_TRAINING_MAX; MoveAirplanes 双翼 XP 混合+溢出入国 |
| 燃料 | 两口径公式 sub_140F5BFC0 (精确式, a1 = CAirWingPool 池级 Σ, +40 wings 数据/+52 计数) / sub_140F5FB90 (任务位现算); ace 414/国 414/W+1464 (每机基础燃料系数, def 副本 +712) 三源; MISSION_FUEL_COSTS 18 档 |
| 转移推进 | sub_140F64B70 三分支: 仓库=100% 退库+删翼 / 到基=搬池+任务恢复 / 失效=改道或取消; 转移翼**预挂目的地池** (loader 12249 AddWing); 步长 = AIR_WING_FLIGHT_SPEED_MULT × 速度合成/1e5; transferring_to 运行时形态 = 目的地 CAirWingPool ref (8B), 序列化 = 目的地基地 id(12249)/载具 id(12436) |
| 超容回库 | sub_140F68220 (HourlyUpdate 步②): 超额装备完好退国家库存, 与 cat4 损失 roll 分立 |
| 部署四件套 | 0x140F5CC60 (布尔门) / 0x140F61FE0 (码版 0/1/2/3) / 0x140F63FA0 (执行, gix 起始 XP = GIE_EXILE_AIR_START_EXPERIENCE) / 加机原语两型; role_icon 门 W+2600 == variant+1068 |
| PostLoad | sub_140F62BC0: id 重注册 + 高水位 `dword_14333D590 = max(旧, 本翼 id)` + 缺省翼名 = 国+定义名 (sub_140BC9F70) + ace 补链 |
| DailyUpdate | sub_140F643A0: W+440 = 任务掩码暂存 (暂停/恢复) + StratAirEnableMissionCommand 载具重指派 |
| 状态枚举 | sub_140F5BB90 五值 (0/2=载具 tf+884 移动/3=训练/4=raid/5=无基) |
| 池 loader | sub_140F65C70: 12110 块载入侧消费跳过 (定义改由 12259 数据库重取); 12213 坏档整跳门 (断言 4200) |
| 换装门 | sub_140F632C0 reinforcement_setting 0-3 四档: 0 = 无 switch 直走默认严格链 (wtag/sa+144 同源检查 + 装备池内队列位置比较, 变体类型+964 升降序两向) / 1 = 恒真 (默认值, 翼+2508 行) / 2 = 反向队列比较, 拒 variant+1060 真变体 / 3 = 变体+1032 位掩码 0x1C00010000 + 池内精确匹配 + sub_14100EB00 库存量 >0; ≥4 断言 "unhandled reinforcement setting" (:3089) |



**writer 发射链全序** (键序 = dump 实际发射序; 原 18 行仅覆盖尾段, 此为全序 31 键):


书表原链表 18 行仅覆盖 12449 起的尾段;此处给全序(键序 = dump 1183904-1184045 实际发射序),供整表替换。

| 序 | 块键 | real 偏移 | 写门 |
|---|---|---|---|
| 1 | 10730 | +124(count) | 恒写 |
| 2 | 11930 | — | 无值键(段标) |
| 3 | 19415 | +2508(reinforcement_setting) | 恒写 u8 |
| 4 | 15799 | +2592(timed_disabling → sub_141A2F740) | — |
| 5 | 12249 / 12436 | 转移解析目标(12249 ← *(解析+104)→+88;12436 ← 二级 id 对) | +72/+76 非零且解析非空 |
| 6 | 12251 | — | 无值键(随转移组) |
| 7 | 12252 | +120(transfer_cancelled) | 转移组尾恒发 |
| 8 | 13206 | +121(transfer_to_warehouse) | 非转移且 ≠0 |
| 9 | 12181 | +100(deployment) | +121≠0 ‖ +100<+96 ‖ 转移中 |
| 10 | 19180 | +96(deployment_time) | 同上 |
| 11 | 10300 | +128(manpower) | 恒写 |
| 12 | 11450 | +144(CAirMission 内嵌块) | — |
| 13 | 12449(数组) | +448 data / +460 count | count≠0;元素 8B id 对 |
| 14 | 12857 | +132(air_accidents) | >0 |
| 15 | 12770 | +744/+748(ace id 对) | 非零且可解析 |
| 16 | 13780 | +440(suspended_missions) | ≠0 |
| 17 | 10754(tag 串) | +2500(经 sub_140BB4E70) | — |
| 18 | 12110(equipment) | +472(池) | — |
| 19 | 27(name) | +2456 | 恒写(门 AAFD0 = checksum-file 判定) |
| 20 | 141 | +40(priority) | 恒写 |
| 21 | 11057 | +44(allow_mission_type) | 恒写 |
| 22 | 14652 | +112(region_to_assign) | ≠0 |
| 23 | 14653 | +116(mission_to_assign) | ≠0 |
| 24 | 10397 | +2488(army,写 army+8 idpair) | ptr≠0 |
| 25 | 12469 | +2496(coverage=no) | 仅 ==0 时发,且嵌套于 24 行 army≠0 块内 |
| 26 | 15034(gix) | +2504 | >0 |
| 27 | 19901(数组) | +2552 data / +2564 count | count≠0;16B 元 |
| 28 | 19863 | 门旗 +2584 | 门旗≠0;**无值发射**(penalty 本体不落盘) |
| 29 | 12227 | +64/+68(air_group) | 非零且可解析 |
| 30 | 15526 | +2600(role_icon_index) | >0 |
| 31 | 19183(raid_instance) | +2604/+2608(id 对) | 任一非零且可解析(14220B240:先 id 后 type) |

注:翼自身 id 对(real+24/+28)不经本 writer 发射,由 air_base 侧块结构承载(本 writer 无 id 键)。


#### 4.15.5 CAirMission (内联 wing+144; 296B; vtable 0X297C8D0; writer 0X140F87820; ctor 0X140F75380)

m = CAirMission 本体 (wing+128 起); 下一 wing 字段 +424 = m+296, 全封闭。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +16 | uint32 | type | token 225; **读法 = 任务位掩码 (1<<任务位 idx; 18 位)** — 位 6 (0x40) = 空投 / 位 11 (0x800) = 训练 MISSION_TRAINING (三链定案: 空难公式 TRAINING 项 / 该位下才结算训练 XP sub_140F5F1B0 / XP 满封自动清位); 任务位 tick 维护 = sub_140F5D5D0 (训练 XP 结算 +536/+544, qword_143331300 封顶 + 无效空投位清位断言 "Airwing with no unit transport has paradrop mission set." :3559) — 空军 AI 容器存翼本体 W (§4.15.4); 容器元素+160 ≡ m+16 (§4.34.12) | 高置信 |
| +20 | uint32 | executing_mission | u32 位旗@m+20; ≠0 时经 sub_141014010 查表裸写 token 名; 唯一运行时写者 = lambda_1 sub_140C49E80 (roll sub_140F7A420/7ACC0/796E0; SetMission 与不可达时清 0) | 写序在 active 之后 (定案) |
| +24 | int8 | period | **昼夜选择枚举: 0=仅夜 1=仅昼 2=昼夜皆飞** (非周期小时); writer 低 8 位截断无损 (枚举值 <128); 燃料折算 = period≠2 时按当日太阳覆盖 > DAY_NIGHT_COVERAGE_FACTOR 的小时数 ×(小时/24) (sub_140F5B4C0); 训练昼夜门 sub_140F80A40 (昼任务夜间覆盖不足 → 不计消耗) | |
| +28 | uint32 | aggressiveness | ≠0 才写 | |
| +32 | uint8 | active | token 11390; 重算门 = SetMission 尾 (无基/不可访问/训练 → 0) | |
| +40 | CAirWing* | _pAirWing 回指 (ctor `*(m+40)=a2`) | 不序列化 | |
| +48 | CStrategicRegion* | region 对象 | region ptr = m+48 (定案); strategic_region = uint32@(*(m+48)+88) | ptr≠0 |
| +56 | 匿名结构 (16B 形状) 向量 | 16B 条目标省表 | {data@+56, cap@+64, count@+68, alloc@+72}; 填充者 sub_141012F80 (AA 强度 + 航程过滤, 经 sub_1410132D0) | 不序列化 |
| +64 | uint64 | 未名 (combat 路径同读) | 不序列化 | |
| +80 | fixed×1e-5 | 目标省覆盖比 | clamp(1e5×需求省数/区域省数(region+36), ≤1e5) | 不序列化 |
| +88 | 匿名结构 (元素待裁) 向量 | 未名 (c2@+88, dtor 分组) | 不序列化 | 未决 |
| +112 | uint32 | 当前目标省 id | sub_140F85240 随机选取, 0=无; ProcessGroundMission case 0x8000 同写 | 不序列化 |
| +116 | uint32 | missions_done | token 12777; writer 恒写; **无运行时写者 — 负定案 (仅存档往返)** | |
| +120 | uint32 | 机数缓存 | sub_140F87480: 出战加权机力/1e5; 变化时清 +68 重选目标 | 不序列化 |

| +124 | 位集 | stop_training (512) | 门 = u8@m+124 (writer `*(_BYTE*)`), 仅真写 yes; u32 判在 b@+125 置位时失真 | |
| +128 | 匿名结构 (NNB 形状) | priority 容器数据指针 — 串循环 {data@m+128, count u32@m+140} 指针数组, 键 141 (priority), 元素 deref+624 引号串, 重复裸键标量叶不编号 (writer 全字段定案; GER pool[3] 7 叶 naval_base/… 实证) | | |
| +129..+139 | — | = priority 容器尾 {cap@+136} | | |
| +140 | uint32 | priority 容器计数 | | |
| +144 | — | = priority 容器尾 {alloc@+144} | | |
| +152 | uint32 | **小时累计被击坠数** (累加 + 出动余量扣减 + sub_140F63580 收割三处独立证实; KillAirplanes 步9 参数) | 不序列化 | |
| +156 | idpair | **击杀方王牌 id 对** (受害任务侧记录, 默认 qword 哨兵) | 不序列化 | |
| +164 | uint32 | **击杀方 tag** | 不序列化 | |
| +168 | uint64 ×3 | 扰断三件套 (+168 有效 / +176 taken / +184 reduction) | 不序列化 | |
| +192 | fixed×1e-5 | region_change_penalty | writer 在 strategic_region 门内无条件写, 0 值也出叶 — 对象层 raw≠0 才返回会丢叶, 段内须 inline | |
| +200 | uint32 | 未名 (F6CF90/F6DB20 地面任务目标选择读 m+200/208 族) | 不序列化 | 未决 |
| +208 | uint64 | 地面任务选定目标 | 不序列化 | |
| +216 | fixed×1e-5 | effectiveness (真值); **序列化 token 14144** (bool 形落盘); 运行时写者 sub_140F79A00 (表 A 执行门) | |
| +224 | uint32 | effective_planes_count; **序列化 token 14145** (u32 保真); 运行时写者 sub_140F79A00 / 紧急出击门 sub_140F79C10 | |
| +232 | fixed×1e-5 | effective_air_superiority; **序列化 token 14149** (bool 形); 写者 sub_140F775D0 | |
| +240 | CCommandPowerAllocator 内嵌 | 指挥点数分配器对象 (vtable 直读; m+248/+256 = 其成员) | 不序列化 | |
| +264 | MSVC 串 | CP tooltip 描述串 {buf@264..279, size@280, cap@288=15} (0X140F79E40 生成, loc 键 COMMAND_POWER_TOOLTIP_AIR_MISSION; 定名) | 不序列化 | |

#### 4.15.6 CAirRegionCombatData (combat_history 元素; writer 0X141964630)

| 偏移 | 类型 | 名称 |
|---|---|---|
| +8 | 友方条目数组* | friend 容器 {data@+8, count@+20} 152B 条 (元素发射: strength 10754 / org 10983 / name 10864 — 恒写无门) |
| +9..+31 | — | = friend 容器尾 {cap@+16, count@+20, alloc@+24} |
| +32 | 匿名结构 (152B 形状) 向量 | enemy 容器 {data@+32, count@+44} 152B 条 |
| +33..+55 | — | = enemy 容器尾 {cap@+40, count@+44, alloc@+48} |
| +56 | tag_id | tag (sub_140BB4E70 串) |

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

vtable槽表: [0] dtor 0x140C4AD70 / [2] writer 0x140C667B0 / [4] loader 0x140C60DF0 / [8] postload 0x140C59380 / [9] id 生成 / **[24] (+192) = 0x140C5B7C0 建筑等级变化回调 (capacity/level 唯一运行时写者)** / [25] (+200) = 0x140C5B720 部署入口。

生命周期: 运行时创建走三个惰性函数 sub_140C4B110/4BEE0/4BBE0 (air/rocket/gun 各一, mgr 稀疏索引 miss 才建, 统一 id = {65, ++dword_14333CA00}); 销毁: rocket 建筑归零走拆除链 (逐翼解散+稀疏槽销毁); 载具 = RemoveCarrierBase sub_140C51080 (byte_14333CA04 门 + vtable[0] delete), dtor 断言"池必须已空" (strategicair.cpp:737)。载具回挂三写点 = 创建 sub_140C4B5A0 / loader 尾 / dtor 清 0; 舰沉级联 = 舰船 dtor sub_140C30380 → RemoveCarrierBase (mgr+216 二分 + sub_140C63100 按 +124 分派逐国除名); 另两路 = 装备丧失 sub_140C33BA0 / 转籍 sub_140D67800→sub_140C4EB40 (删旧建新)。

容量链 (sub_140C65490, 唯一写者): 陆基 = AIRBASE_CAPACITY_MULT×Σ建筑等级 / rocket = ROCKETSITE_CAPACITY_MULT×Σ / gun 恒 1 / 载具 = 舰统计 (+864/+872)/1e5×CARRIER/SUBMARINE_CARRIER_SIZE_STAT_INCREMENT / 导弹舰 = MISSILE_LAUNCHER_CAPACITY (钳 ≥10)。翼容量四档 = CSubUnitDefinition+1536/1540/1544/1548 (air_wing_size 四档: AirbaseType 枚举 0..3 ↔ land/carrier/mega/submarine, 逐档字段名见 §4.18.19; "Missing case for AirbaseType" 断言直证; def+1448 带 0x200000000 位则直接用 base+120; 类别→四档取值收口 sub_140F5F000 — 本函实为**容量 getter**: 返回容量值非类别, 类别合成仅内部步骤 (用法三证: 部署门 容量≤0‖≤count / 部署钳 min(请求, 容−现) / 增援权重缺额项))。

访问权链 (纯派生, 无直接 effect 写门 — 负定案): HasAccess = sub_140C57400 (base+48 槽非空); 授予重算 sub_140C65B80 逐国挂/除 (陆基 = 基地省控制 sub_140C4FB60>0 / 载具 = 对属主军事访问 sub_140D45270)。AddWing = sub_140C4BD80 (装备类别断言) / RemoveWing = sub_140C636F0 (id 对换位删除)。**空图标记更新器 0x141E7DB00 (airmapiconsimpl.cpp; 定案)** = HasAccess(airbase, 玩家国 1312/1316 规范形) 门 (失败断言 :891 "HasAccess", 闩 byte_14338C91C) → sub_140C536B0(base, 玩家国) 取访问数据 (relation+184 翼池数组 {data@+0, count@+12}) → 逐池 {data@+40, count@+52} 翼条目 → 逐翼 sub_141E7D8C0 (翼级回调 = 空图标记实际更新点, 未收); 返回 = 最后一次回调返回, 无访问权返 0。


| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | id.type — id 对之 type (对 {type, id}) — GUI: Reorg 窗 target (idpair → win+4128 快照; SetTarget sub_14202DCD0) | 恒写 |
| +12 | uint32 | id 对.id — B400 壳 | 恒写 |
| +16 | uint8 | 标志字节 (默认 0; dtor 读 `!*(a1+16)` 门 id 重注册) | 不序列化 |
| +24 | 匿名结构 (NNB 形状) 向量 24B | 驻扎 wing 列表 {data@+24, cap@+32, count@+36, alloc@+40} (AddWing 按 id 对去重) | 不序列化 |
| +48 | 匿名结构 (NNB 形状) 向量 24B | **按国索引 CCountryAirContainer* 槽表** {data@+48, cap@+56, count@+60, alloc@+64} (ctor sub_140C47B00 以国家数建容; 容器工厂 sub_140C4B9F0 双注册直证 — 写槽 + 挂 +72 密集容器; HasAccess(Tag) 断言即查此槽非空) | 不序列化 |
| +72 | CCountryAirContainer* | countries 容器数据指针 — {data, count} 指针元 → CCountryAirContainer (§4.15.9) | c>0 |
| +73..+83 | — | = countries 容器尾 {cap@+80} | |
| +84 | uint32 | countries 容器计数 | c>0 |
| +85..+95 | — | = countries 容器尾 {alloc@+88} | |
| +96 | uint32 | carrier.type — id 对之 type (id 对 {type, id}) | else 分支恒写 (无 state 即写, 载具基地) |
| +100 | uint32 | carrier.id — id 对之 id | |
| +104 | CState* | state 对象 → state = *(*(a+104)+88) | 状态指针非空; combat_stats 国修门真身: resolve(_pPool → air_base idpair@+24/+28)+104 == 0 (海上/载具/未指派, 基地无 state) → 翼 combat_stats 吃属主国修正 {201=navy_carrier_air_attack_factor / 202=targetting / 203=agility} (各 +100000 基数, 经 wing+2484 tag → cc+1464 查键); ≠0 → 基数 1.0 (定案) |
| +112 | uint64 | 位置缓存预留槽 — **运行期无写者** (ctor 清 0 后恒 0, 负定案); 位置 getter sub_140C53790 每次现算 | 不序列化 (定案) |
| +120 | uint32 | capacity | 恒写 |
| +124 | uint32 | base 类别枚举 **{0=air_base, 1=rocket_site, 2=gun_emplacement}** (manager loader 断言直证); ctor = sub_140C3AD00(ship) (导弹舰旗 = ship+1032 & **0x200000000** (位 33; 两处建翼判定一致 — 原 0x2000000000 疑笔误, 全写者定案待裁)); 真值 = u32@+124 (byte@+128 = 下行 has_manpower 的门/值, 勿混) | 恒写 |
| +128 | uint8 | has_manpower_for_recruit_change_to | ≠0 才写 |
| +132 | uint32 | level (默认 1); **唯一运行时写者 = sub_140C5B7C0** (CAirBase vtable[24] 建筑等级变化回调, air 分支 = 建筑 i16@+64 当前等级) | 恒写 |
| +136 | uint64 | allow_equipment_type | 位掩码 (>32bit), 恒写; 初值三来源: 陆基惰性创建 0x10036FC00 / rocket 0x1C00010000 / 载具 = 舰 unit 装备位并集 & 0x1F0037FC00 (+124==0 再或 0x10036FC00); GUI: Reorg 可部署装备池过滤 (× cc+3944(+512) 库存 → win+4024 池; sub_14100CFC0) |

#### 4.15.9 CCountryAirContainer (CAirBase countries 元素 0xF8; **CSupplyConsumer 派生, 基类宿主 +0**)

身份: 基类 ctor 0X140C482A0 (类别字节 a2 存 +28: **2 = 空军基地容器**, 4 = 项目消费者); 容器 ctor 0X140C4B9F0 (malloc 0xF8, 换主vtable 0x142958710, 双注册 = base+48[tag] 槽 + base+72 密集容器)。vtable 槽: [2] writer 0X140C668B0 (先调基 writer 0X140ED0400) / [4] loader 0X140C61360 (default → 基 loader 0X140ECA2E0) / [8] postload·重挂 0X140C59380 / [9] id 生成 0X14221E990 ({type=4713, id=全局自增}) / [10] GetNeededSupply 0X140C4D770 / [11] GetSupplyLocation 0X140C4D490 / [12] SetMotorization 0X140C047D0。

CSupplyConsumer 基类域 (cp+0..+160; 不序列化段):

| 偏移 | 类型 | 名称/语义 | 初值 |
|---|---|---|---|
| +24 | uint32 | 保留 | 0 |
| +28 | uint8 | 消费者类别 (2=空军基地容器 / 4=项目消费者) | ctor a2 |
| +29 | uint8 | motorization_level (恒写 token 19943; vtable[12] setter) | 0 |
| +30 | uint8 | 未名 (ctor `WORD@29=256` 高半) | 1 |
| +32 | fixed×1e-5 | 总需求侧缓存标量 | 100000 |
| +40 | fixed×1e-5 | _AskedSupply (供网回填; 断言 supply_consumer) | 100000 |
| +48 | fixed×1e-5 | **补给比** = 1e5×_ReceivedSupply/_AskedSupply (asked=0 → 1e5; sub_141A0AFB0) | 100000 |
| +56 | fixed×1e-5 | defines 下限运算派生值 (sub_1424EF6F0(1e5)) | 派生 |
| +64 | fixed×1e-5 | _ReceivedSupply (累加, clamp 到 +40) | 100000 |
| +72..+88 | qword 零群 | — | 0 |
| +96 | 匿名结构 (NNB 形状) 向量 24B | pdx 容器 {data@+96, cap@+104, count@+112} | — |
| +120..+152 | 标量区 | **+128 = 在基地机数 / +136 = 需求权重和** = GetNeededSupply 副作用写点 (needed = BASE_AIR_SUPPLY_MULT_FOR_TRUCK_BUFFER × Σ逐池逐翼 sub_140F625B0) | 0 |

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +160 | fixed×1e-5 | disrupted_supply (基 writer) | >0 才写 |
| +168 | idpair | 所属 air_base 引用 (+168/+172; postload vtable[8] 逐容器回写; GetSupplyLocation vtable[11] 解析: 陆基 → 省 id, 载具 → ship+1832 → taskforce vtable[11]; 断言 `Country air container without airbase when calculating supply location`) | |
| +176 | tag_id | country (loader 串 10394 → tag 反查; 失败报 "Air base country container refers to invalid tag: ") | 恒写 |
| +184 | CAirWingPool* 向量 | 该基地该国**翼池**指针数组 {data@+184, cap@+188, count@+196} — 元素 = CAirWingPool* 非裸翼 (§4.15.3) | |
| +208 | fixed×1e-5 | operational_status = **可运转州占比 (战争控制面, 与燃料无关)**: 写者链 sub_140C65D40 (100000 × sub_140C4FB60 逐州 sub_140D45270 控制/交战判定 / 基地省列表省数) → sub_140C63FA0 (≤0 且旧值 >0 时逐翼取消任务/换序后落值); 载具/海上基地恒 100000; 读者 = 消耗结算门 / sub_140C4CA10 (>0 门) / sub_140C4C150 (daily, ≤0 断言并除名基地) | ≠100000 (≠1.0) 才写 |
| +216 | fixed×1e-5 | capacity_penalty = clamp(1e5 − 超容比×CAPACITY_PENALTY, 0, 1e5) (sub_140C579F0 计算; 超容比 >0.9 直接 0; 载具基地再乘国家修正 268; 未超容恒 100000 — 输入纯基地超容, 与燃料无关); 基地不可运营 (cp+208 ≤0) 或州沦陷谓词真时整段清零 (sub_140C57B70) | ≠0 才写 |
| +224 | fixed×1e-5 | fuel_consumption = 每小时清 0 后**逐池累加** sub_140F5BA20 (任务/训练消耗现算; executing 分支机数 = m+224 无门直过) — sub_140C57B70 (ProcessAirBasesHourly 并行段: sub_140C5EFC0 → tbb 分裂 sub_140C45D50/叶 sub_140C67630 → sub_140C579F0 capacity_penalty 后逐容器调用) | ≠0 才写 |
| +232 | fixed×1e-5 | base_fuel_consumption = 同循环逐池累加 sub_140F5B720 (基础 = 翼系数×机数, 无论任务; executing 无门直过) | ≠0 才写 |
| +240 | fixed×1e-5 | received = 该国在该基地实获燃料: 每小时结算扇出清 0 (sub_140C4F920, 唯一调用者 sub_1410F71B0; 只扫 sa+16 与 sa+40, 火箭表不在) → 分配直写 = grant (sub_140C4BB10, 唯一调用者 sub_1410F3080, 按需求优先级 2/1/0 三轮); 上游 = sub_1407164E0 (cc+5504 燃料结构) ← sub_1401D85A0 hourlyUpdateUnits ← DoCountryHourlyUpdates; 基地燃料满足比 getter sub_140C543E0 = clamp(1e5×received/consumption, 0, 1e5) (consumption=0 → 1e5) | ≠0 才写 |

loader 0X140C61360: 12434→+208 / 12435→+216 / 15130→+240 / 15289→+232 / 11955→+224 — **五字段全落字段**; 不序列化 = 基类供网侧 (+32/+40/+48/+64) 与 +128/+136 (载入后首个供网 tick 重建); 零态即满态 (满足比 1e5 无封锁门, 翼照常出动)。

**翼级燃料 = 无持久字段, 逐时现算** (参与门 = 执行中 或 (训练位 ∧ 装备允许 ∧ 非转移仓库 wing+105 ∧ 已部署 wing+84≥wing+80 ∧ 非转移中) 且过昼夜门 sub_140F80A40 与拥挤门 sub_140F80930 (1e5×机数/容量 ≥ AGGRESSION_THRESHOLD[激进度 m+28] 才计入)):

| 变体 | 函数 | 语义/公式 |
|---|---|---|
| 上限估算 (UI) | sub_140F5B4C0 | MISSION_FUEL_COSTS[任务位] × 机数 (m+224 或训练 wing+108) × FUEL_COST_MULT × 翼系数合成器 sub_140F5F880 /1e5; period≠2 按昼夜小时折算 (含天气折算) |
| 当前实际 (累加用) | sub_140F5BA20 | 同上 (m+224; 训练位 11 × wing+108), 无天气折算 |
| 基础 (在基地) | sub_140F5B720 | 1e5 × wing+1448 × wing+108 /1e5 (无任务门) |
| 最大理论 (UI) | sub_140F5BFC0 | max(表基址 qword_143339770 [0..17], 越界断言 :3996) × 国家修正414合成 × 机数, 逐翼累加 |

翼燃料系数合成器 sub_140F5F880 = wing+1448 (每机基础燃料系数, fix5, 定义副本区随装备定义拷贝带入) + 国家修正414 + (100000 或 王牌修正414+1e5) + 战区修正414(按任务) + 天气修正414; 修正键 414 经 wing+2484 tag → cc+1464 查 CModifier。MISSION_FUEL_COSTS = 18 元 define 表 (索引 = 任务位 = log2(任务 token), 位 11 = 训练); 另有副表 qword_1433397B8 = **海军任务燃料消耗表** (三读者全在海军域: 任务燃料查表) — 「AI 评估用」系误记。

**低燃料行为**: 不取消任务 — 任务效率乘 f(ratio) = ratio×(1e5−MISSION_EFFICIENCY_MULT_AT_LACK_OF_FUEL)/1e5 + MEMLALF; 任务取消门是 operational_status (控制面) ≤0。

任务效率 sub_140F78500 = **四惩罚项积** (覆盖比反项 × capacity_penalty 反项 sub_140C53FD0 读 cp+216 × 补给比反项 sub_140C54ED0 读 cp+48, a4 旗可跳过 × MEMLALF 燃料插值) × (1 + 修正键 17 AIR_MISSION_EFFICIENCY 三源和) — 燃料是**唯一乘点**, 零燃料 = 效率 25% (与陆军的独立惩罚比 getter、海军的战斗数值加法式**均不同构**)。

XP 两链同乘满足比: field-XP sub_140F5DFA0 (×修正键 437 AIR_MISSION_XP_FACTOR) / 训练 XP sub_140F5F1B0 (×修正键 99 AIR_TRAINING_XP_FACTOR) — **翼无 org 字段 (负定案), XP 增长即等价物**。

出动数与燃料无关 (零燃料不停飞, 在执行门层再证): 出动数 sub_140F78360 三档 — rocket = 导弹槽系数 (无州 = MISSILE_LAUNCHER_SLOTS, 有州 = 州建筑表扫描) / gun = 1 / air = RNG roll × 姿态表 tf+1260; 任务执行门 sub_140F79A00 (七门: active/region/机数/昼夜/拥挤/载具区域/出击数>0) 与紧急出击门 sub_140F79C10 逐小时 roll。损失记账处满足比 <1e5 反而按比**缩减** (= 减免非惩罚)。

**空军无海军式 OUT_OF_FUEL 战斗修正 (负定案)**: 海军 FEX 空侧解算 sub_141978E30 体内无燃料三字段引用 (该函数定性见 §4.15.12 — 非对空战通用解析器)。

翼装备增援链 (与 CSupplyConsumer 无关 — 负定案: CSupplyConsumer 只管基地补给/燃料): 库存分配 = sub_140C54850 桶 / Σ需求 sub_140C4E8A0 / sub_140F5C370 权重 = 执行中?500 + 缺额 + 1000×priority (资格门含任务掩码 variant+1040; 细化: 执行中 = 任务掩码 wing+160 非零, 缺额源 = 容量 getter sub_140F5F000, 库存 sub_14100EA10(def+784) ≤0 亦权重 0); 损失链入口 (**§4.15.9 五入口 taxonomy**: 区域空战 sub_140F862A0 / 对地-AA 与陆战 AA sub_140F86A40·sub_1412AADD0 / 空难 sub_140F5DD80 / 部署超容 / 轰炸还击; 旧「三入口」行已重排) → sub_140C5C5C0 双方记账 → sub_140F63580 "KillAirplanes" 装备/人力扣减 + sub_140F64770 统计/租借原产国/事件; **装备损失不回库存, 唯一回库通道 = 翼除名 100% 退还** (sa+112 消费 sub_140F62AF0 三件套: 退还 sub_141011250 + ace 回收 sub_14061BC70 + 删翼 sub_140F66A40; 空池 pool+52==0 → vtable[0] 销毁)。

**换装/加机函数族 (体读定案)**: 加机原语 = sub_140F5ADD0 (AddAirplanes, trace "AddAirplanes - nAdd: %i total after: %i" :468); 翼+472 装备池三收口铁律 = 加机 sub_14100CCE0(池, variant, 1e5×n) / 整批重填 sub_14100CAE0(池, 变型集) / 计数重算 *(wing+124) = sub_141012920(池)/1e5。三型加机执行: 部署侧 0x140F63FA0 (容量钳 + 资源折减 sub_140C4F860 明细落 wing+2504 域, 待裁 + GIE 起始 XP qword_143335B40, 门 wing+2504 >0) / 增援侧 0x140F64190 (min(请求, 现有+124) 钳 + 经验沿 +536 继承 + +136 累计接收机数) / 换装侧 0x140F5AC50 (变型集重填 + 机数重算 + sub_140F63E00 全簇唯一经验写点)。换装候选 = 0x140F5BE30 (旧变体存量 Σ, sub_140BD7DC0 NEW/OLD 五键比较器) / 0x140F5D0A0 (布尔版, 四门 + 池扫 amount>0); 库存池 = def+784 (库族变体库存池, 计数查询 sub_14100EA10, 与市场查询 sub_14100EB00 同族异址)。

#### 4.15.10 地勤 (ground crew) — 花人力买一次性任务效率加成

与燃料链**无交集** (负定案): 不是每小时消耗物, 而是**国家级决议**购入的修正键 17
(AIR_MISSION_EFFICIENCY) 一次性加成。

| 项 | 值 |
|---|---|
| defines | BOOST = `qword_143337CC0` / COST = `qword_143337C08` (AIR_MORE_GROUND_CREWS_COST) |
| 命令 | `sub_141945190` (Execute) / `sub_141948200` (IsValid) |
| 登记原语 | `sub_1407024F0(country, region)` = 台账旗读取 |
| **消费原语** | `sub_1406E92B0(country, region)` = find-or-create 0x100B 条 + flag@+56 清 0 + 施加修正键 17 (BOOST) — **台账消费点 = CStrategicAir::RemoveMission 尾段** (区域任务清空时按区域消费, §4.15.14) |
| 台账 | cc+1240 (键 = **任务区域指针**, 元素 +16 已付 / +56 一次性旗) |
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
（sub_140C5B380）/ 物流打击 cat5（sub_140F75A00）/ 海军 FEX（旧
sub_141978E30）。

**空难概率公式 (定案, define 键 tooltip 六键直证)**: 入口 = 0x140F61D70 (空难概率 getter, 掩码空/机数 0 → 0; 任务型全零断言 "Expected mission type to be set." :3386) → 公式本体 sub_140C4DAF0 (622 行, 主体 ~8 处定点乘除, 余为 tooltip 构造): 结果 = (BASE qword_143336460 [ACCIDENT_CHANCE_BASE 3336460] + cc+1464 修100) × (RELI_MULT qword_143336630 [ACCIDENT_CHANCE_RELIABILITY_MULT 3336630] × (1e5 − min(可靠值 sub_140F60970(wing,&,65), 1e5))/1e5)/1e5 × (1e5 + 天气修100 [基地州天气对象 +1464, 仅 >0 并入] + CARRIER qword_143336500 [仅载具基地加] + TRAINING qword_143331428 [仅任务位 11 加] + 翼+568 修101 [tooltip 标 AIR_WING_EXPERIENCE_VALUE_MODIFIER] + cc修101)/1e5; CARRIER/TRAINING 两 define 地址 defines_map 无名 (待裁)。

| 段 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 接战判定 | sub_140C591C0 | 区域活跃 byte 网格 + 敌 SA 交战判定 → 收集己方 air_superiority\|interception 任务（m+20 & 5）与敌执行中任务, 按 air_defence×air_agility 排序（sub_140C43580/C43B80 归并）— **没有纯空优 vs 空优自由空战, 只打正在执行对地/对海任务的敌任务** | 定案 |
| 狗斗解析 | sub_140F81A20（拦截份额掷骰+空战XP）→ sub_140F7BE70（逐敌任务对）→ **sub_140F862A0** | 速度加成 = 0.65×base×(min(攻速/守速, 3.5)−1); 敏捷减伤 = 0.45×base×(min(守敏/攻敏, 4.0)−1) 仅守优生效, 归一除数 800/100; **顶速伤害加成项 (TSDBF 0.025) 原版恒 0** — 内层 trunc((spd/100)×2500/1e5) 在 spd<4000 截断为零 (双重定标瑕疵); 击坠 = AIR_COMBAT_DAMAGE_SCALE(载具档, vanilla 1/5)×总攻值×0.01÷守方 air_defence, base = 0.2×分配机数, 随机取整; 损失钳 ≥100 量纲 = **0.001 架** (100 fixed5, 非 1 架), 多机钳分配双钳 ≥100 同值实参; 防守条目 count 消耗 = −round(分配/3); cat1 归因 + m+152/164 损失账（m+152 = 小时累计被击坠数, 非已飞里程; m+156/160 = 击杀方王牌 id 对 / m+164 = 击杀方 tag; m+208 = 拦截因子缓存）, 步9 sub_140F87550 统一 KillAirplanes | 定案 |
| 拦截/扰断 | 步6 sub_140F7BE70 → 步7 sub_140F77360 → 步8 sub_140C4C570 | 三段全小时活管道: 写敌任务 m+176 taken（DISRUPTION_* defines）→ 写己方空优 m+184（ESCORT_*, 修正键 12; **ESCORT 侦查因子复用 DISRUPTION_DETECTION_FACTOR 槽, 无独立 define**）→ 折 m+168 → 对地结算 sub_140F78160 出拦截因子（存 m+208; **= clamp(1−sqrt(taken/防御骰)/3.162, 0.001, 1), PE 除数 316200 = 手写 sqrt(10) 精确**; 防御骰 = 出动×(1+速)×(1+0.5攻)×(1+0.5防)）, 损失 = 出动数×(1−因子), 归因 m+200 扰断方 tag | 定案 |
| 对地 | **sub_140F82110 ProcessGroundMission** → sub_140F82CA0 | 任务位→目标收集器全表; 多态目标分发（建筑/CAS 入陆战 sub_140BB8380/港击/物流打击 sub_140F75A00/师直伤 sub_140C01B70/陆战 vtable[240]）+ 州-AA+SAM 掷骰 sub_140F86A40（÷air_defence）; paradrop/布雷扫雷分叉 | 定案 |
| 空优聚合 | sa+224 160B 行 | pass25-29 产出 + sub_140C66170 友敌聚合 (+0/+8/+16/+24); 消费 = sub_140C54230 制空惩罚公式与国家级均值 sub_140C655F0 | 定案 |

defines 新钉 30+（DISRUPTION_*/ESCORT_*/COMBAT_DAMAGE_SCALE/ACE_*/SAM_MISSION_
SUPERIORITY/ANTI_AIR_*、修正键 1/12/19/118/356/394/395）; AIR_COMBAT_FINAL_
DAMAGE_{SCALE,PLANES,PLANES_FACTOR} **三件套全零读者（负定案）**。m+88 = 8B
{region, dist} 对（定案）。

#### 4.15.13b 空军任务实现层增补 (airmission.cpp 定案摘要)

**任务位 → token 18 位全表** (sub_141014010 直证; 18 = MISSIONS_COUNT; 允许掩码语义判定集):

| 位 | 值 | token | 名 | 位 | 值 | token | 名 |
|---|---|---|---|---|---|---|---|
| 0 | 0x1 | 12335 | air_superiority | 9 | 0x200 | 11388 | attack_logistics |
| 1 | 0x2 | 12224 | cas | 10 | 0x400 | 11851 | air_supply |
| 2 | 0x4 | 11058 | interception | 11 | 0x800 | 12218 | training |
| 3 | 0x8 | 12229 | strategic_bomber | 12 | 0x1000 | 11856 | naval_mines_planting |
| 4 | 0x10 | 12225 | naval_bomber | 13 | 0x2000 | 11858 | naval_mines_sweeping |
| 5 | 0x20 | 11059 | drop_nuke | 14 | 0x4000 | 12196 | recon |
| 6 | 0x40 | 13123 | paradrop | 15 | 0x8000 | 12159 | naval_patrol |
| 7 | 0x80 | 11258 | naval_kamikaze | 16 | 0x10000 | 10088 | barrage_mission |
| 8 | 0x100 | 12971 | port_strike | 17 | 0x20000 | 10100 | sam_mission |

打击任务掩码 0x1F7FA = 位 {1, 3..10, 12..16} (拦截链「正在执行对地/对海任务」判定集)。

实现层定案 (摘要): SetMission (训练特例/独占组合并/active 十门重算); ProcessGroundMission 主调度 (任务位→收集器全表 + 加权随机); 逐目标结算中枢 (州 AA 门槛 + KillAirplanes 收尾); **attack_logistics 四件套** (列车铁路主结算 + 伤害落地 inline-PRNG 选列车 + 铁路炮 type13 + 卡车节点打击; cat5 sub_140F75A00 = 物流打击, 非战略轰炸还击); 协同打击顶层 (港击/战略轰炸派发); 侦察四路情报分摊 (ProcessAirRecon, lambda 符号实名; 公式 = RECON_PLANE_INTEL_BASE + LAND/SEA_DISTRIBUTION 四象限分摊, 份额 = (100000−占比)×强度/1e5, CConvoyClient 过滤); 布雷/扫雷 (DLC 门); 狗斗/拦截/扰断公式 §4.15.12 对账全过 (速度 0.65/3.5 / 敏捷 0.45/4.0 / 击坠 = ACS×攻值×0.01÷air_defence); **防守方加权聚合 sub_140F80540** (cas×2 / port_strike×100 / strat_bomber×修正键4); **王牌 on_action 全局族 qword_14333D5F8..628** (PostLoad 扇出填充, §4.12.9b; 获得/创建派发 = on_ace_promoted); 空袭伤害 (命中数→AA 防减→暴击→入账类型 3); 王牌死亡/获得/收割与 on_action 派发七名全局表。region 侧锚 (recon 消费): region+24 省指针数组 / +104/+116/+128 = 基地/计数/权重三平行表 / **+160 = 侦察覆盖比 fixed5** / +152 = 区内地面存在量 (推定); state+392 = 州 owner tag; CProvince+164 = 省 id。sub_1424ED730 = fixed5 round(x/1e5) (书内多处「round」语义的 PE 实体)。

**航路省线栅格化 = 0x140F7A760 (定案, 本节机制文的函数本体)**: 签名/`m+88` 容器描述符含 alloc@16 / 地图单例 +2096 块 {+24 省→region 表, +48 宽, +52 高} / x 环形环绕 / gs vt[1] 取 id 链 (疑丢参, 待裁) / dummy 计数器 / gamestate.h 断言对 — df19 粗对齐仅 x 轴, 本批复核补 7 项细节。

#### 4.15.14 战略空军实现层 (strategicair 三单元 61 函数; 非序列化)

三单元 = strategicair.cpp (48 函数, 状态+调度+统计层) / strategicaircommands.cpp (命令层, Execute/IsValid
家族住 0x141944C00..0x14194A400 窗口, RTTI 23 类) / strategicairview.cpp (GUI 统计层 4 函数)。
**负定案**: 战略轰炸/核打击 (drop_nuke 位 5) 调度/结算全在 airmission.cpp ProcessGroundMission 链
(§4.15.13b), 本三单元全簇零 NUKE 引用; 港击限额消费 sub_140C4F960 是簇内唯一对地结算触点 (账本, 非结算)。

新定类 (1.19 空军战区系统首笔):

| 项 | 定案 |
|---|---|
| CAirTheatre | RTTI vtable 0x1427E73C0; CReferenceObject 单继承; ctor sub_1414EB6A0 (+8 空 idpair 常量, +16 u8 旗, +24 u32, **+32 MSVC 串默认 "NEW_THEATER_GROUP"**, +64/+72 容器群); idpair = **{77, ++\*(mgr+24)}**; 存储 = **cc+384 容器** (形态待裁) |
| CAirGroup | RTTI vtable 0x1429CCF30; ctor sub_1414EB410 (malloc 0x90 = 144B; `&CAirGroup::vftable'` 符号直证; 布局 = +8 idpair / +16 注册旗 / +32 icon 默认 1 / +48 CColor vptr / **+80 MSVC 串默认 "NEW_THEATER_GROUP" (ctor 直证, 与 CAirTheatre+32 同默认串 — 两类各有名串)** / +112 theatre 句柄 / +120 翼表); idpair = **{78, ++\*(mgr+40)}**; 全布局见 §4.31.61 运行期所有权操作层 |
| mgr+24 / mgr+40 | **air_theatre / air_group id 计数器** (书 §4.15.1 generator 字段 {77,78} 的现场写者 = CMoveAirWingAndAirGroupToAirTheatreCommand::Execute) |
| 命令 RTTI 族 | CMoveAirWingAndAirGroupToAirTheatreCommand 0x142A1E510 / CMoveAirGroupAndAirTheatreToFreeCommand 0x142A1E5D8 / CMoveAirWingToAirGroupCommand 0x142A1E6A0 / CReorderAirTheatersCommand 0x142A1E768 / CRenameAirTheatreCommand 0x142A1E830 / CRenameAirGroupCommand 0x142A1E8F8 / CChangeAirGroupInsigniaCommand 0x142A1E9C0; token 14863-14868 |

**CStrategicAir::AddMission sub_140C5DAA0 / RemoveMission sub_140C5DCB0 (定案)**: Add = 非成员断言
(:4467) → 插 _ActiveMissions[region+88] (SA+152 稀疏数组) → 插 _AllActiveMissions (SA+176) →
region id **排序插入** _ActiveMissionRegions (SA+200, 二分定位); Remove = 成员断言 (:4478/:4479/:4486)
→ 逐表摘除, 区域任务清空时 region id 前移删除; **尾段 = 地勤加成按区域消费** (cc+1240 条 +56 旗 →
sub_1406E92B0 施加修正键 17, §4.15.10)。

**导弹舰自动建翼链 (定案)**: 两处独立实现同逻辑 (建筑等级回调 sub_140C5B7C0 vtable[24] / 基地激活
sub_140C5E4E0) — gun_emplacement 就绪州 → 扫国舰表判 `ship+1032 & 0x200000000` → sub_140C508F0 建舰载翼
→ sub_140F852A0(翼+144, **0x10000 = 任务位 16 barrage_mission**, 1, 0, 170) (第 5 参语义未决; 另三处清位调用 0x40/0x800/训练位同传 &int16{170} — 推定任务变更通知 token); 失败断言
:6756。**CAirBase 生命周期四件补全**: dtor 本体 sub_140C48740 (vtable[0] 壳 0x140C4AD70 → 断言 "carrier
deleted not in delete function" 门 byte_14333CA04 + 解链 ship+1840) / token 工厂 sub_140C61B60 (12214
air_base → malloc 0x90 + ctor sub_140C47B00; state-or-carrier 校验败即销毁) / 转籍重建 sub_140C64400
(按 base+124 分派 + 逐翼用 sub_140C505F0 按新主重建) / OOB air_wings 历史装载器 sub_140C61F80 (713 行,
Ace 顺序断言族, 调用者 = 历史 OOB 装载器 sub_140705CE0)。

**战损统计记录族 (定案)**: 按因记录入口 sub_140C5C8C0 (类别 4/5) / sub_140C5CF30 (7) / sub_140C5D590 与
sub_140C5D8E0 (6 两型) → sub_141962C40 (airregionstatistics.cpp:203, §4.15.7) 写入, 4/5 落 enemy 侧
(+56) / 6/7 落 friend 侧 (+32); **战损原因枚举→loc 键全表 sub_140C54A70**: 0=REASON_NONE_TOTAL(/_DETAILED)
/ 1=AIR_COMBAT / 2=LAND_COMBAT / 3=ACCIDENT / 4=BOMBED / 5=ARMORED_TRAINS / 6=SUICIDE (default 断言
:6728); AIR_VIEW 伤害统计表构建 sub_14187F9D0 (18 键 BY_US/BY_ENEMY 对) 为 view 侧消费者。

**HourlyUpdate 骨架增补**: 入口断言 :6547 全文 = "!ActiveCountryIndices.IsEmpty() && Expected some
active countries."; gs+2536 以 byte 指针入帧, 步 6 经 **sub_140BB3800 = 区域情报兵力树登记器 (定案)**: **0x88 (136B) 节点 13 字段布局** / +80 = 情报对数组 / 「本方兵力 × 因子 ÷ 100000」情报缩放公式; 新记 **SA+224 = 160B 每区域记录数组** (gs+736 区域指针数组 / gs+748 计数遍历); 训练翼随机换基 sub_140C60290
(inline PRNG 10% 概率, 唯一调用者 = ProcessAirBasesHourly sub_140C5EFC0); 无断言函数 (HourlyUpdate
并行解算 sub_140C58660 / lambda 簇 / 制空惩罚 sub_140C54230 / 容量访问链 sub_140C65490 族) 属本 cpp
逻辑但体无断言串, 入书时按行注/调用者锚勿按 cpp 归属找。

#### 4.15.15 aces.cpp 王牌域增补 (创建工厂与死亡 on_action 七槽; 8 函闭环)

清册 (8/8 函体内含 aces.cpp 路径锚): 创建主工厂 0x140618860 (1091) / CAce::Load reader
0x14061AFB0 (177, 11 键全表) / CAcesDatabase 根 Parse 0x140618080 (154, 根作用域只认
modifiers(12774), `@` 前缀引用旁路) / AddItem 0x140618600 (103, §4.32 add_ace 互证全过) /
HandleOnKilled 0x14061AA90 (69, 三断言 + 一次性 on_action 派发) / Kill 0x14061BBA0 (35,
+344=0/+348 kill_type/+352..+359 killer token 对 8B/+360 i32 出参) / EnsureId 0x14061AD90 (14,
§4.28.17 注) / EnsurePortrait 0x14061AF70 (10, +340 惰性全局流掷点)。

**创建工厂五阶段** (定案): 私流双哈希 RNG → def 加权预选 (翼侧机型掩码门) → 名三重组优先
(triple 自带 modifier 名可覆盖 def) → 池装配兜底 (性别比掷点 + 国规则门 + 同名占用衰减
avail 99999/used 0) → malloc 0x178 建 CAce 入国容器+挂翼; 两消费点 (airmission.cpp
:2111/:2898) 均尾随 on_ace_promoted。

**CAce 布局 9 增补行** (定案): +16/+32 CModifier / +40 / +224 owner 国 / +240/+272/+304
三名串 / +348 kill_type / +352..+359 killer token 对 8B / +360 i32 出参 / +364 handled。CNameDatabase 条目形状 = 男女
三池 ×3 + 三重组表 +328 镜像。

**王牌死亡 on_action 七槽全实名 + 触发分支表** (定案; 补全 §4.12.9b on_action 族王牌分支):
on_aces_killed_each_other / on_ace_killed_by_ace / on_ace_killed_other_ace / on_ace_killed /
on_ace_killed_on_accident / on_non_ace_killed_other_ace / on_ace_promoted; 派发链 = 三路 Kill
记账 → sub_140C57D30 逐日清扫 (alive==0 && !handled) → HandleOnKilled。

未决: def+64→ace+4B 语义 / 翼侧掩码链中间对象 (+56→+32→+1448) / kill_type 全枚举
(观测 0/1/2) / 名组 lookup 键 a3 语义。

#### 4.15.16 空军 UI 工具域 (airutil.cpp; 8 函闭环 — 区域右键/堆叠图标 tooltip/装备库存分配/SelectionList 校验)

#### 4.15.17 空军任务类型位号取值 (air_mission_util.cpp; 1 函 = sub_141013EE0, 定案)

#### 4.15.18 CAirMission 目标省表扫描器与 STacticalTarget (airmission.cpp; 1 函 = 0x140F7E600 + 追加原语 sub_140F77200, 高置信)

0x140F7E600 (a1 = CAirMission, a2 = vector<STacticalTarget>* 可空 = 纯计数, a3 = 采样参数, a4 = 采样键重生成种子, a5 = 抽查模式旗, a6 = 找到首个即返) → 命中数。入口门 = region+152 QWORD 非零 (region = a1+48 CStrategicRegion*; +152 书未收); **目标省表 = a1+56 16B 条 {data@56, cap@64, count@68}** (§4.15.5 已收, 填充者 sub_141012F80), 本函 = 消费侧。a4 ≠ 0 → 重算 64bit 采样键 {低默认 1, 高默认 1587985054} (常数链 2126043716/282605150/1831007003 与 542824007/−1259093227/947560250 multiply-xorshift 展开 = **引擎自研采样哈希, 非 FNV-1a**); a5 → 采样阈值 = 1000 × qword_1433339E8 (全局随机因子, 写者未决) × a3 / 100000。**路① (a5=0 全扫)**: 逐省 (16B 条 u32 省 id + u64 时间戳, `now−时间戳` 夹 [0,now] = 权重基数) → 省对象 → **省+368 {data@368, count@380} 列表** (元素类待裁) 逐元过三重门 (vtable+88(元,省)==1 / sub_1413E27F0 敌性匹配 / 翼省 sub_140F5E7F0 落元+40/+48 两集合 → 命中构造 STacticalTarget)。**路② (a5=1 抽查)**: 对当前省 **+272 {data@272, count@284} 列表** (与 CStrategicAirManager+272 同偏移异宿主) 逐元过哈希采样门 (`hash(键 + 序号×1255572915 线性递推) & 0x7FFFFFFF % 100000 < 阈值`) + sub_140C00000 有效性哨兵。**STacticalTarget = 40B** {+0 vtable (RTTI `CAirMission::STacticalTarget::vftable'` 直证) / +8 i64 权重 / +16 i32 (源对象 +164) / +24 目标对象指针 (路①) / +32 第二目标指针 (路②)}; 追加原语 = sub_140F77200。

sub_141013EE0 (MissionType 位枚举 → 位号作数组下标): 双 B52 断言 — :30「Mission type must not be 0.」(闩 byte_14333D815) / :32「Expected no more than one bit set in mission type.」(单比特判 = `__popcnt(a1) == 1`; 闩 byte_14333D816; IDA 将 popcnt 展开为 `16843009×SWAR(…)>>24` 软件路, 由 dword_1430C76A8 ≥ 2 分派硬件/软件, 非业务系数); 计算 = 移位循环整数 log2。

CU = `hoi4\source\airutil.cpp`。八函身份表:

| VA | 行数 | 身份 |
|---|---|---|
| 0x1415B5320 | 474 | 空军区域右键 tooltip 文本构建 (类别枚举: 0 → "ROCKET_" 前缀 / 1 → "GUN_EMPLACEMENT_" / 其他 :1113 断言 latch byte_14338A96E) |
| 0x1415B33B0 | 343 | 机群堆叠 tooltip 按装备类型分桶构建 |
| 0x1415B3A70 | 246 | 空军装备库存分配器 |
| 0x1415B61D0 | 89 | 单向量堆叠图标行构建 (33B0 单桶变体) |
| 0x1415B7560 | 60 | 选中列表全量校验 (选中链表头 = 管理器单例 qword_14332F6A0 **+1336**; 节点 next@+16, 节点+0 = selectable 指针, selectable+8 类型 **2 = 航空**; 逐向量元查链表命中, 断言 "Invalid selectable in SelectionList" airutil.cpp:168 latch byte_14338A96D) |
| 0x1415B7480 | 45 | 选中列表单元素校验 |
| 0x1415B4E50 | 29 | 机群堆叠地图图标帧 getter |
| 0x1415B7230 | 25 | 子单位定义 +792 键取值 (`return *(def+792)`) |

**区域右键键族三态**: AIR_REGION_RIGHT_CLICK (全选) / _NOT_ALL (部分选中) / _NONE (无选中); 输出 = 本地化 + "\n" + 计数串 (sub_1415B6390 逐单位区域匹配收集) + "\n"。

**空军类别位掩码 = 0x1F0037FC00 (定案)**: CSubUnitDefinition+1448 category 位域 (s4_34_ai 已名) 的空军子集; 三处断言直证 (`(*(u64)(def+1448) & 0x1F0037FC00) == 0` → SubUnitDef.IsAir() 断言 :1032/:1316/:1340 — :1032 = 四档容量 getter sub_14101B080 前置门 (latch byte_14333D971, 兜底返 +1536; AirbaseType 越界断言 :1045 "Missing case for AirbaseType" latch byte_14333D972)) + 消费方字面量直证 (0x14169D860 堆叠图标 tooltip 传参)。

**堆叠图标 tooltip 分桶**: 桶键 = wing+472 → sub_14100FF30 查 CEquipmentType; 帧公式 **ICONFRAME = 2×(原型+960) − (X+684 != 1 ? 1 : 0)** (参数名 "ICONFRAME"; 原型沿 CEquipmentType+1008 接口槽 → +1240 派生母链解析, :1199 EquipmentType.IsAir() 断言 latch byte_14338A96F); 键 AIRWING_STACK_INFO_MAP_ICON。

**空军装备库存分配器**: 需求量 = 100000 × AirbaseType 四档 getter sub_14101B080 (枚举 0..3 ↔ CSubUnitDefinition+1536/+1540/+1544/+1548; else 断言 subunitdefinition.cpp:1045 "Missing case for AirbaseType" 兜底返 +1536 — 与 §4.18.19 air_wing_size 四档互证并补枚举映射); 候选 = sub_14100FC70(宿主+512, *(def+792)) → 16B/条 {装备对象*, 数量} 向量; 排序 = ≤32 元素插入 / >32 归并 (scratch 栈缓冲 ≤256 元素, malloc 失败减半重试 — §3.2a 归并族 scratch 第三档实例); 分配 = 候选 +1040 (CEquipmentType db 下标) 匹配者 min(剩余需求, 候选数量) 累进。

**SelectionList 校验对** (定案): 选中列表 = 全局 qword_14332F6A0 (interface 管理器) **+1336 = SelectionList** — 链节点 {+0 对象指针, +8 u32 类型 (==2 单位条目), +16 next}; 两校验器断言 :143/:168 `Selectable.IsValid() && "Invalid selectable in SelectionList"` (latch byte_14338A96C/96D); 空列表语义: 全量校验返 1 / 单元素校验返 0。⚠ 指针槽差: 本批全局 = qword_14332F6A0, s4_18 书记 qword_14332F698 (相邻槽) — 同 iface 对象两入口或两对象未核, 双注保留。


**strategicair.cpp 50-99 行簇增补**: **CAirBase 新字段** — +8/+12 = 自身 idpair (0x140C57B70 断言 "_pAirBase == pBase" :635 互证) / +96/+100 = 属主国 idpair (控制国 getter 0x140C54030 ②路; 州沦陷时走 sub_140C53790(state)+392 控制国 tag ①路; 双缺断言 "Air base with no controller, what???" :2308, 轻量门 B51) / **+136 = 允许装备类别掩码** (AddWing 0x140C4BD80 断言: sub_1410112E0 = CPlanePool::OnlyHasOfAnyType(翼+472 机池, +136 掩码), 串 "AirWing is not supported by this airbase" :1858)。**GetNeededSupply 0x140C4D770 (vtable[10])**: base+48[tag] 槽空 → 供需 0 早退; MULT (qword_143337100 = BASE_AIR_SUPPLY_MULT_FOR_TRUCK_BUFFER) 乘法**只进出参 a3**, +136 落盘未乘 Σ 原值; 在基地机数 getter = sub_140C4D910。属主 idpair = a1+168 (sub_14221F310, 断言 "pAirBase" :578), 国家下标 = sub_140BB5490(a1+176); 翼遍历 = 每国容器内 {翼数组@+184, 计数@+196}; 每翼机池 {data@wing+40, count@wing+52}, 逐装备条 sub_140F625B0 取机数累加 Σ; `*a3 = qword_143337100 × Σ / 100000`; `a1+128 = sub_140C4D910(基地)`; `a1+136 = Σ`。**港击限额消费 0x140C4F960**: 四联断言 — a3 ≤ 0 "PlaneCount >= 0 && \"Invalid limit used\"" :2935 / a2 == 0 "Null region" :2940 / 越界 "Unexpected region index" :2947 / 下溢 "Consumed more port strike limit than available" :2954; 限额数组 = `*(a1+248)` (i32 元), 区域计数上界 = a1+260; 区域下标 = *(区域+96); 递减过账**钳 0** (:2954)。小时结算叶 0x140C57B70: 入口断言 "_pAirBase == pBase" :635 (a1+168/+172 与 a2+8/+12 idpair 双对); 入口清 a1+224 = a1+232 = 0; 不可运营 (`*(基地+208) ≤ 0` ∨ a2+104 州 ∧ sub_1409DB3E0 沦陷) → a1+216 = 0 早退; 正常 → a1+216 = a3 (penalty; capacity_penalty 定界断言 :636 0..1e5) + 遍历 {a1+184, a1+196} 翼: `a1+224 += sub_140F5BA20(翼)` (燃料) / `a1+232 += sub_140F5B720(翼)` (第二累加器, 语义推定机数, 未决)。AddWing 0x140C4BD80 另补去重: 线性扫 {a1+24, 计数 a1+36} 现有翼, 匹配 idpair (翼+24 == a2+24 ∧ 翼+28 == a2+28) → 返回既有翼 id, 不重复加入; 未命中 → sub_1401205A0 追加。变体→子单位定义取数 0x140C542D0 (IsAir 断言 :3458; **宿主 = 属主国** — a1+144 tag 经 sub_140BB48F0 解析 → `*(国+3952)` = **CDeployment\*** (§4.3 +3952) 传入 sub_140C51B10(变体, deployment) 查表; `*(变体+1008)` 域对象 → sub_140C97430 IsAir 门; 空定义断言 "SubUnitDef" :3462; 返 sub_14101B080(定义, a3))。


**airmission.cpp 50-99 行簇增补**: **CAirMission 槽位补** = +152 命中计数 / +156 目标 idpair (复位 = 哨兵 qword_14333D528) / +164 事件参数 / +216 出动选择 / +68 naval_patrol 目标门 (= §4.15.5 目标省表 count@+68 非零, 表非空即门; 翼侧 +160 = 18 位任务掩码 (**训练位 0x800 豁免 region/active 门**)。**任务可行性聚合门 = 0x140F7B280 (新定性)**: 18 位 OR 短路表 — paradrop/logistics/air_supply 无条件真; strat 与 barrage 共用 sub_140F7E290; naval_bomber 与 kamikaze 共用 sub_140F7D590; naval_patrol 需 +68 ∧ region+160 双目标; (mission & 0x1F7FA)==0 = 无打击位放行; 断言 "Airwings are expected to always have an airbase." :1508。**任务执行门 0x140F79A00 逐门复核过 + 增补**: 训练位活化断言 :1595 / 空基断言 :1629; **昼夜临界全局 qword_143335B60** (执行门小时比较与训练门覆盖值比较共用, define 名待裁); 敌占区门细化 = (mission&5)!=0 (空优|CAS) ∧ region == 控制国+496→+200。**训练昼夜门 0x140F80A40 复核过**: 空基走异路 getter sub_140F5F830, 断言 "Training air mission has no airbase." :2978 后仍返真 (断言非门)。命中结算收尾 0x140F87550: 王牌链 sub_140F5AAB0 (ace+344 门) + 阈值 = qword_143336788 + 10000×(qword_143336828×计数/1e5)/1e5 (define 槽名待裁) + RNG roll (定位锚 :2640) 发事件 sub_14061BBA0; 收尾三清 (+152/+164 归零, +156 复位哨兵)。

#### 4.15.19 省地图图标可用性批量评估 (1 函 = 0x14128D060, 公式定案/整体身份推定)

0x14128D060 (a1 = 省 map_obj 宿主 [+5976/+5977/+5978 旗 / +5984 战略位置旗], a2 = CProvince 取数源 [+56 VP/+164 省 id/+192 CState*/+392 controller], a3 = 定义对象 [byte 选项旗 +5..+40 / float +16 截止阈值 / tag +44 / int* +56 情报表基址], a4 char) → bool = a1+4499。写入 **a1+4480..+4506 可用旗块 (27 字节, 全表)**: +4489 主使能 = a3+14 ∧ a4; +4480 位组 / +4481 / +4484 dword (0/2/7) / +4490 / +4501..+4506 / +4488 (情报分支) / +4495..+4498 / +4500 — 各位 = a3 选项旗组合门 (详见 findings §1.3); +4492/93/94 = a1+5976/5977/5978 ∧ 空军基地/火箭/第三容器解析器 (sub_140C4AF30/B040/C546A0(airmgr, 州); airmgr = sub_1406F9600(cc)); +4496/4497 = sub_140E7A1A0 (语义待裁) / sub_140E7C420 (省→CNavalBase)。**情报门**: v11 = `byte[省id + *(a3+56)]`, ≥50 两处消费, byte_14332F63A (情报总旗) 新读者点。**+4491 VP 点截止公式 (定案)**: `(VICTORY_POINT_MAP_ICON_DOT_CUTOFF_MAX > f) && ((VP ÷ VICTORY_POINT_MAP_ICON_MAX_VICTORY_POINTS_FOR_PERCENT) × (MAX − VICTORY_POINT_MAP_ICON_DOT_CUTOFF_MIN) + MIN) > f` (三 define PE 验算 ✓; 与 E1.4 区间映射同构); 豁免 = 州 +204 tag == sub_1406ECE80(cc) ∧ a2 == sub_1406EC950(cc) → 恒 0 (推定州属主首都豁免)。

#### 4.15.20 集团按剧场分组核 (strategicaircommands.cpp; 1 函 = 0x1419478B0, 定案)

0x1419478B0 (集群数组 a1 {data, count@+12}, out 剧场表 a2 {data, cap@+8, count@+12, alloc}, out 散集团表 a3): air 迁移三段 helper 第 2 段 (sub_1419473D0 联队×集团划分 → **本函** 集团×剧场分组 → sub_14193F1B0 集团摘场); 调用方 = CMoveAirWingAndAirGroupToAirTheatreCommand 14863 / CMoveAirGroupAndAirTheatreToFreeCommand 14864 / CMoveAirWingToAirGroupCommand 14865 / CDeleteAirWingCommand 13651 四 Execute。执行序: 局部 std::map (0x40B 节点: rb 链 +0/+8/+16, nil 旗@+25, key 8B@+32, 值向量 {data@+40, cap@+48, count@+52, 分配器@+56}; 溢出 → std::length_error 抛出桩) → 逐集群 (16B idpair, **{0,0} 哨兵跳过**) resolve 后以**集团+112 = 剧场 idpair** 为 key 入 map, 集团 id 追加值向量 (×1.5 增长) → 逐 map 节点: 断言 :101 `AirTheatre.IsValid() && "AirTheatre has to be valid on an AirGroup"` (闩 byte_14338B3A6) + :104 `"The AirGroup has to be connected to the same AirTheatre"` (集团+112 == 节点 key; 闩 byte_14338B3AF), 均在主门 byte_1435E1B52 内; a2 去重 = **O(n²) 线性扫** (idpair 双 DWORD 逐对比较); **整剧场判据 = 剧场+76 集团数 == 节点收集数** → 剧场 idpair 入 a2, 否则该批集团 idpair 经 sub_1402BE050 追加进 a3 (散集团)。尾: rb 树后序清理 (逐节点释放值向量 + free 节点 + free 头哨兵)。

#### 4.15.21 空军域函数补遗（14 函）

| VA | 语义/证据 |
|---|---|
| 0x140C61640 | CStrategicAir::Reader "Not a valid strategic air type." + 调用 CDiplomaticAction::GetFirstCountryRef |
| 0x140F80F60 | （未命名）airmission.cpp:2898 站点 airmission.cpp:2898 站点；调用日期/任务工具子链 |
| 0x140F7CAC0 | （未命名）gamestate.h:1116 + vtable `CAirMission::SAirSupplyTarget` / `CAirMission::STargetPriority` gamestate.h:1116 + vtable `CAirMission::SAirSupplyTarget` / `… |
| 0x140F814A0 | （未命名）airmission.cpp:4086 站点 airmission.cpp:4086 站点；调用空中任务相关子链 |
| 0x140F83AA0 | （未命名）airmission.cpp:4119 airmission.cpp:4119；NGameDLC::HasFeature(NAVAL_MINES) 门 + ThreadIsMainThread 断言，水雷任务 |
| 0x141AF5DF0 | （未命名）"Province %d" / "Superiority: %s%%" / "Radar efficiency" / "No air vs air combat" "Province %d" / "Superiority: %s%%" / "Radar efficiency" / "No air vs … |
| 0x141FCF4E0 | sub_141FCF4E0 VALUE / AIRWING_STR / AMOUNT / AIRWING_STR_MISSING（舰载机联队强度 UI） |
| 0x14202F720 | sub_14202F720 空军联队人力（MANPOWER_AIR_WING_CREATION_VALUE/VALUE） |
| 0x1404695F0 | CLastStrategicBombingOnStateStrigger::GetValue CLastStrategicBombingOnStateStrigger::GetValue；串「_pInstance && "gamestate unitilialized"」 |
| 0x140AF1610 | CUnitNamesDatabase::GenerateNameForAirGroup CUnitNamesDatabase::GenerateNameForAirGroup，串 "AIR_GROUP_NAME_PATTERN" |
| 0x141CF31D0 | （未命名）GUI 串 "air_groups_view"/"air_group_view_ GUI 串 "air_groups_view"/"air_group_view_entries"（空军编组视图） |
| 0x14202F550 | （未命名）GUI 串 "plane_filters"/"plane_type_grid" GUI 串 "plane_filters"/"plane_type_grid"（飞机筛选/机型网格） |
| 0x141013C50 | sub_141013C50 空军联队/飞机窗口与任务类型（AIRWING_MISSION_TYPE） |
| 0x141D3F8C0 | （未命名）GUI/loc 串 AIR_EQUIPMENT_TOTAL/_DESC GUI/loc 串 AIR_EQUIPMENT_TOTAL/_DESC（空军装备总量条目） |

#### 4.15.22 空军域函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140BB0860 | （无名）air_update_tracer.cpp:130 + GetAirWing/GetSize 方法调用 air_update_tracer.cpp:130 + GetAirWing/GetSize 方法调用 |
| 0x140F674E0 | （无名，按上游/loc 定性） ref.h:83 断言 |
| 0x141AF7C30 | （无名，按上游/loc 定性） 串 "nav. patrol\ recon\ logi. strike\ air supply\ mine pla*" |
| 0x14202C320 | sub_14202C320 特征串:AIRWING_CREATE_EMPTY ; AIRWING_CREATE_NO_MANPOWER |
| 0x142230C80 | CMouse::[1] CMouse::[1] + 域关键词匹配; 串 "_ObserverList.Contains( Observer ) == fals"; 源码路径 clausewitz |

#### 4.15.23 空军域函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x1418828D0 | 空军任务类型显示 空军任务类型显示；loc \"AIRWING_MISSION_TYPE_AIR_SUPERIORITY\"/\"AIRWING_MISSION_TYPE_INTERCEPTION\"/\"AIR_VIEW_GROUND_MISSION\"+\"KEY\"/\"HEADER\"，被调 locali… |
| 0x140BB2750 | "air mission missing from AIR_MISSION_SP "air mission missing from AIR_MISSION_SPOTTING_FACTORS" + ai §4.15 空战 |
| 0x141E07FD0 | "number/plane" 空军数据 "number/plane" 空军数据 §4.15 空战 |
| 0x140C648B0 | sub_140C648B0（无名） strategicair.cpp:3891 站点 "pShip && Carrier without ship when transferring wings to base."，航母联队转场至基地 |
| 0x140C5D240 | sub_140C5D240（无名） pdx_scoped_buffer "_Position + NeededSize <= _BufferSize" 写断言 + gamestate.h:1125，夹于 CStrategicAir::[3]/CStrategicAirManager::[2]，战略空军序列化写入 |
| 0x141887650 | "PLANE_COUNTS_IN_REGION/PLANE_COUNTS_PAS "PLANE_COUNTS_IN_REGION/PLANE_COUNTS_PASSING_THROUGH_REGION" §4.15 空战 |
| 0x140FEA9E0 | sub_140FEA9E0（无名） RAID_INST_PHASE_ASSEMBLING/PREPARING/PREPARED/IN_PROGRESS/ENDED/NONE + PHASE/PROGRESS/raid_inst_progress_desc GUI 键，紧邻 NRaids::CRaidInstanc… |

#### 4.15.24 空军域函数补遗（11 函）

| VA | 语义/证据 |
|---|---|
| 0x140F59760 | （无名，按证据定性） airwing.cpp:260 断言 'Expected non-empty variant pool.' + IsAllMatchingMissionTypes + CAirWing/CModifier vtable（舰载机联队任务类型匹配） |
| 0x140C4B1C0 | 航空联队任务状态 AIRWING_MISSION_WING_STATUS_MISSION + MIS |
| 0x1406E5110 | 国家空军基地访问校验 "Country thinks it has access to an airbase that it should not have access to." country.cpp:11830 + AIR_SUP/SCORE_CALC_AIR |
| 0x140C5E820 | OOB 航母航空基地装载校验 "has no carrier air base with name ... Is the OOB file containing the carrier loaded after this file?" |
| 0x142039340 | 航空联队快速部署 QUICK_DEPLOY_WING_ENABLE_DESC / DISABLE_NO_MAN_DESC / DISABLE_NO_EQUIP_DESC + PLANE_TYPE |
| 0x140C66FB0 | H::CStrategicAir::USIntermediateAirBaseStatuses::QEBAXAEAV?$CPd鈥�::[1] func_names 名 H::CStrategicAir::USIntermediateAirBaseStatuses::QEBAXAEAV?$CPd鈥�::[1] |
| 0x140F64340 | CAirWing::[2] vtable 槽 CAirWing::[2]（func_names RTTI 名） |
| 0x140C4AE90 | CStrategicAir::[0] vtable 槽 CStrategicAir::[0]（func_names RTTI 名） |
| 0x140F5A9A0 | CAirWing::[0] vtable 槽 CAirWing::[0]（func_names RTTI 名） |
| 0x140F5A988 | CAirWing::[0] vtable 槽 CAirWing::[0]（func_names RTTI 名） |
| 0x140C4AD4C | CStrategicAir::[2] vtable 槽 CStrategicAir::[2]（func_names RTTI 名） |

#### 4.15.25 空军域函数补遗（11 函）

| VA | 语义/证据 |
|---|---|

#### 4.15.26 空军域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x140C47E80 | （无名） 体设 CStrategicAir::vftable（RTTI 名） |
| 0x140C48FF0 | （无名） 体设 CStrategicAir::vftable（RTTI 名） |
| 0x140F5A5B0 | （无名） 体设 CAirWing::vftable（RTTI 名） |

#### 4.15.27 空军域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|

#### 4.15.28 空军域函数补遗（26 函）

| VA | 语义/证据 |
|---|---|
| 0x1412C93F0 | （无名） 调用图传播: 10 锚点投 §4.15（80%） |
| 0x140FAA260 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140F796E0 | （无名） 调用图传播: 3 锚点投 §4.15（100%） |
| 0x141E7DE50 | （无名） 调用图传播: 8 锚点投 §4.15（50%） |
| 0x140641AE0 | （无名） 调用图传播: 4 锚点投 §4.15（50%） |
| 0x140BE8B70 | （无名） 调用图传播: 4 锚点投 §4.15（100%） |
| 0x14100D7A0 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140F66DD0 | （无名） 调用图传播: 3 锚点投 §4.15（67%） |
| 0x14100D670 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140BE7D10 | （无名） 调用图传播: 6 锚点投 §4.15（100%） |
| 0x141039000 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |
| 0x140C4D3D0 | （无名） 调用图传播: 3 锚点投 §4.15（67%） |
| 0x140EDECD0 | （无名） 调用图传播: 4 锚点投 §4.15（50%） |
| 0x140F5E400 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x1419625D0 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |
| 0x140C5D750 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x141039120 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |
| 0x141FD1EE0 | （无名） 调用图传播: 4 锚点投 §4.15（75%） |
| 0x14100D550 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140E689C0 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140CDA2C0 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140F66890 | （无名） 调用图传播: 3 锚点投 §4.15（67%） |
| 0x140F877B0 | （无名） 调用图传播: 3 锚点投 §4.15（100%） |
| 0x140F784B0 | （无名） 调用图传播: 3 锚点投 §4.15（67%） |
| 0x140F776D0 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |
| 0x140F80B10 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |

#### 4.15.29 空军域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141668E10 | 空军任务方向 串 "air_mission_direction"（pdx_scoped_buffer 仅断言站点）→ 空军任务方向 |
| 0x140B05320 | 战略空军进驻权 strategicair.h + 断言 "HasAccess( Tag )" → 战略空军进驻权 |
| 0x141886DD0 | 空中详情频道 UI 串 "AIRVIEW_DETAILS_CHANNEL_" → 空中详情频道 UI |
| 0x141013340 | 联队任务 tooltip 串 "AIRWING_MISSION_TYPE_*_DESC"/"AIRWING_MISSION_NIGHT_BOMBING_DESC" → 联队任务 tooltip |

#### 4.15.30 空军域函数补遗（21 函）

| VA | 语义/证据 |
|---|---|
| 0x141DFF5E0 | sub_141DFF5E0 空军联队/飞机窗口与任务类型（lost_air_grid） |
| 0x140F5C500 | 无名领域函数 sub_140F5C500 断言站点 \hoi4\\source\\airwing.cpp（空军联队） |
| 0x141A81DB0 | sub_141A81DB0 王牌飞行员（ace）数据/文本函数（the ace） |
| 0x140C44250 | 无名领域函数 sub_140C44250 被调用者定名: CStrategicAirManager::UpdatePortStrikeLimitPerRegion? 等命中 §4.15（占 56%，共 2 callee） |
| 0x141A81200 | sub_141A81200 王牌飞行员（ace）数据/文本函数（the ace） |
| 0x141A82730 | sub_141A82730 王牌飞行员（ace）数据/文本函数（the ace） |
| 0x140C4BFA0 | sub_140C4BFA0 串:CPdxIteratorRange( pPool->GetAirWings() ) .AllOf( SHasAllowe |
| 0x1402B31C0 | 域关键词匹配 sub_1402B31C0 + 域关键词匹配 |
| 0x141D3E870 | 域关键词匹配 sub_141D3E870 + 域关键词匹配; 源码路径 hoi4; 被 CPlanesOverview::[0] 等 1 命名函数调用 |
| 0x1421B23B0 | 调用图上游传播(占 100%, 1 票) sub_1421B23B0 + 调用图上游传播(占 100%, 1 票) |
| 0x141D3E330 | sub_141D3E330 空军联队/飞机窗口与任务类型（planeswindow） |
| 0x1415DF090 | 调用图上游传播(占 100%, 1 票) sub_1415DF090 + 调用图上游传播(占 100%, 1 票) |
| 0x14205FAB0 | 域关键词匹配 sub_14205FAB0 + 域关键词匹配; 源码路径 hoi4; 被调源码 clausewitz |
| 0x14247FD20 | 域关键词匹配 sub_14247FD20 + 域关键词匹配 |
| 0x141CBFAF0 | 同区段近邻 NCareerProfile::CFrontendCareerProfileView::[4](距 0xC250)属 4.15 族 sub_141CBFAF0 + 同区段近邻 NCareerProfile::CFrontendCareerProfileView::[4](距 0xC250)属 4.15 族 |
| 0x14247E4C0 | 域关键词匹配 sub_14247E4C0 + 域关键词匹配 |
| 0x14203D630 | 域关键词匹配 sub_14203D630 + 域关键词匹配; 源码路径 hoi4; 被 NInternationalMarket::CSubsidyOverview::CListController::[2] 等 1 命名函数调用 |
| 0x14255FEF8 | 域关键词匹配 sub_14255FEF8 + 域关键词匹配 |
| 0x1421C9230 | 调用图上游传播(占 100%, 1 票) sub_1421C9230 + 调用图上游传播(占 100%, 1 票) |
| 0x140616AC0 | 同区段近邻 CAce::[0](距 0x1280)属 4.15 族 sub_140616AC0 + 同区段近邻 CAce::[0](距 0x1280)属 4.15 族 |
| 0x140E34EC0 | 调用图上游传播(占 67%, 2 票) sub_140E34EC0 + 调用图上游传播(占 67%, 2 票) |

#### 4.15.31 空军域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x141D3ECC0 | SERVICE_MANPOWER_HEADER（例程） loc 键 SERVICE_MANPOWER_HEADER/AIR_SERVICE_MANPOWER_DESC |
| 0x140C4CE30 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |
| 0x1421AE640 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |

#### 4.15.32 空军域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141964A20 | NAir::NQuickWingDeployment（vtable 槽/管理器） VT NAir::NQuickWingDeployment + SOnSelectionChanged 监听入队（快速机翼部署选择） |

#### 4.15.33 空军域函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x140C53C80 | （无名） 调用图传播: 2 锚点投 §4.15（50%） |
| 0x140F5D240 | （无名） 调用图传播: 2 锚点投 §4.15（100%） |

#### 4.15.34 空军域函数补遗（29 函）

| VA | 语义/证据 |
|---|---|
| 0x140BB1070 | 无名 sub_（断言站点/串定位） 断言站点 air_update_tracer.cpp:130 |
| 0x141E5A3F0 | 无名 sub_（断言站点/串定位） 串字面量 "AIR_SUPERIORITY_AA_REDUCTION_ENEMY" |
| 0x1415B4730 | 无名 sub_（断言站点/串定位） 串字面量 "AIR_BASE_RIGHT_CLICK" |
| 0x140C52150 | 无名 sub_（断言站点/串定位） 断言站点 strategicair.cpp:116 |
| 0x14170CD00 | 无名 sub_（断言站点/串定位） 串字面量 "ARMY_AIR_WINGS_ACTIVE" |
| 0x141688630 | 无名 sub_（断言站点/串定位） 串字面量 "air_selection_view" |
| 0x1415DB9A0 | 无名 sub_（断言站点/串定位） 串字面量 "defender_air_icon" |
| 0x1415B8F20 | 无名 sub_（断言站点/串定位） 串字面量 "order_airwing_effect" |
| 0x1415C6610 | 无名 sub_（断言站点/串定位） 串字面量 "NAVAL_COMBAT_DEFENSE_AIRWING_TOOLTIP_SHOT_DOWN" |
| 0x141F6FBC0 | 无名 sub_（断言站点/串定位） 串字面量 "DESIGNER_AIR_SAVE" |
| 0x140F63AF0 | 无名 sub_（断言站点/串定位） 断言站点 airwing.cpp:644 |
| 0x142508460 | 无名（证据推断） 类名/模板：ESide::RIGHT |
| 0x141D3EA70 | 无名 sub_（断言站点/串定位） 串字面量 "AIR_EQUIPMENT_IN_USE" |
| 0x141FD3690 | 无名 sub_（断言站点/串定位） 串字面量 "AIRWING_MISSION_TRAINING" |
| 0x14007B1F0 | 无名 sub_（断言站点/串定位） 串字面量 "state_repair_speed_" |
| 0x141F96470 | 无名 sub_（断言站点/串定位） 串字面量 "NAVY_REPAIR_NOW_CANCEL" |
| 0x141FD7420 | 无名 sub_（断言站点/串定位） 串字面量 "START_SAM_WINGS" |
| 0x140FCE030 | 无名 sub_（断言站点/串定位） 串字面量 "airforce" |
| 0x140C4E9C0 | 无名 sub_（断言站点/串定位） 断言站点 strategicair.cpp:1975 |
| 0x142061120 | 无名 sub_（断言站点/串定位） 串字面量 "AIRWING_MANPOWER_TEXT" |
| 0x141D3FD00 | 无名 sub_（断言站点/串定位） 串字面量 "planeswindow" |
| 0x140F70A00 | 无名 sub_（断言站点/串定位） 串字面量 "REPAIR_SPEED_RAILWAY_GUN" |
| 0x141965170 | 无名 sub_（断言站点/串定位） 断言站点 wing_deploy_controller.cpp:179 |
| 0x1419650C0 | 无名 sub_（断言站点/串定位） 断言站点 wing_deploy_controller.cpp:154 |
| 0x141F5FAC0 | 无名 sub_（断言站点/串定位） 串字面量 "AIRWING_NEW_BASE" |
| 0x140C57740 | 无名 sub_（断言站点/串定位） 断言站点 strategicair.cpp:3480 |
| 0x1419472E0 | 无名 sub_（断言站点/串定位） 串字面量 "AIR_DELETE_WING" |
| 0x1415BF910 | 无名 sub_（断言站点/串定位） 串字面量 "NAVY_REPAIR_CANCEL_DESC_REUNITE" |
| 0x14002A080 | 无名 sub_（断言站点/串定位） 串字面量 "Check if carrier has airplanes that are part of th" |

#### 4.15.35 空军域函数补遗（17 函）

| VA | 语义/证据 |
|---|---|
| 0x142546174 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x141753230 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140AF0870 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x141012410 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x141A089D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140C4D050 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x141534260 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140E61B80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140FD6F80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140E61F30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140F5C700 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140C67B40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x141883250 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140C5B160 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x140CDB040 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x141A06B30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
| 0x1418862B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.15 |
