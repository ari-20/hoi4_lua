> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.9 CDeployment (部署)

**获取**: `dep = *(cc + 3952)` — 类身份 = CDeploymentStatus (vt 0x14295FC38; ctor sub_140D0D020 / writer sub_140D14650 / dtor sub_140D0D4C0 三源互证)。

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +8 | 匿名结构 (112B) | unit_modifiers 容器数据指针 | {data, count}, 元素内联 112B, count<64 | §4.9.1 |
| +9..+19 | — | = unit_modifiers 容器 {data@8, **cap@16**, count@20, alloc@24} 内部 (pdx 24B; ctor sub_140D0D020) |  |  |
| +20 | u32 | unit_modifiers 容器计数 |  | §4.9.1 |
| +21..+71 | — | = unit_modifiers count@20 尾 + **alloc@24** + **运行时容器#2 {data@32, cap@40, count@44, alloc@48}** (未序列化) + **std::map unlocked_subunits {head@56 (malloc 0x28 三自指哨兵), size@64}** (writer 块 token 16572 = unlocked_subunits; 节点 {key token@+28, u8@+32})  |  |  |
| +72 | CVolleyDivTransport* | conveyors 容器数据指针 | {data, count<128} 8B 指针元; 元素布局与 GUI 消费见 §4.9.2 | §4.9.2 |
| +73..+83 | — | = conveyors 容器 {data@72, **cap@80**, count@84, alloc@88} 内部  |  |  |
| +84 | u32 | conveyors 容器计数 |  |  |
| +85..+239 | — | = conveyors count@84 尾 + **alloc@88** + **运行时容器#4 {d@96, cap@104, c@108, alloc@112}** + **#5 {d@120, cap@128, c@132, alloc@136}** (**定案 = 部署中单位列表**, CCountryDeploymentView 数据链: 玩家 tag → cc+3952 本对象) + **#6 {d@144, cap@152, c@156, alloc@160}** (均未序列化, dtor 逐个清) + **+168 = hq_next_deploy_order u32** (writer 键 16910, >0 门) + **+172/+176 = default_hq_template id 对** {type@172, id@176} (qword_14333D528 初值; writer B320 键 10667) + +180 qword 0 + +188 u32 0 + +192..239 零区  |  |  |
| +240 | CEquipmentArcheTypePool* 向量 | initial_carrier_air_wing_deployment | **CEquipmentArcheTypePool 32B (ctor sub_14100C630)** {vt@240, 容器@248 {d@248, cap@256, c@260, alloc@264}} (writer 键 13691); +272 = lambda scoped ptr (8B), 消费 sub_141980140 = 同模板已排产行数 (add_limit 上限, >9 显 MORE_THAN_NINE) | |

其余区域 = 未序列化运行时容器群 (上列 #2/#4/#5/#6 与 +56 map 之外无其他容器; 对拍工具链不消费)。

#### 4.9.1 CSubunitBonusPersistent (unit_modifiers 元素, 112B; vt 0x14295FAA8; writer 0X14197FA10)

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +0 | — | vtable 槽 | 序列化分发 (writer 首行虚调用) | |
| +8 | 静态类描述符* | 类描述符 | 指向静态描述对象 | |
| +16 | 匿名结构 (8B 形状) | stats 容器数据指针 — 列表 1 | {data, count<64}; 元素 8B 指针 → 类别对象 |  |
| +17..+27 | — | = CSubUnitStatBonus (内嵌@+8) 容器1 {data@16, **cap@24**, count@28, alloc@32} 内部 (pdx 24B; ctor sub_140641990) |  |  |
| +28 | u32 | stats 容器计数 |  |  |
| +29..+39 | — | = 容器1 count@28 尾 + **alloc@32**  |  |  |
| +40 | 匿名结构 (16B) | stats 容器数据指针 — 列表 2 | {data, count<64}; 元素 16B {静态 DB 条目指针, 对象} |  |
| +41..+51 | — | = 容器2 {data@40, **cap@48**, count@52, alloc@56} 内部  |  |  |
| +52 | u32 | stats 容器计数 |  |  |
| +53..+63 | — | = 容器2 count@52 尾 + **alloc@56**; @+64 起 type/id/number/localization_key 区  |  |  |
| +64 | uint32 | type | 枚举: 值→token 映射见下表 | |
| +68 | token | id | ≠357 才写 | |
| +72 | uint32 | number | | |
| +80 | string | localization_key | SSO; 门 = 指针@+96 ≠ 0 | |

**type 枚举** (值→token):

| 值 | token |
|---|---|
| 1 | 10022 |
| 2 | 89 |
| 3 | 16775 |
| 4 | 16778 |
| 5 | 16770 |
| 6 | 16771 |
| 默认 | 357 |

**类别对象** (列表 1 元素解引用): 类别 token uint32@+8; 内嵌 stats 子对象 @+64 (vtable@+64)。

**stats 子对象布局** (头部 24B + 主数组): 类名 = **USSubUnitStats** (RTTI `.?AUSSubUnitStats`, 主 vt 0x142789D70, 本 writer = 该虚表槽 [2]; ctor 经 sub_141018080 内嵌构造 = CSubUnitDefinition+64)

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | vtable | |
| +16 | fixed×1e-5 | factor 头 | 恒 100000 (factor 类, writer 不写) |
| +24 | fixed×1e-5 | combat_width | 主数组外独立字段 |
| +72 | 容器 | battalion_mult (48B 条) | category/add/display/stats 逐叶门 |
| +96..+719 | fixed×1e-5[78] | 主数组 | 78 槽 int64×1e-5 |
| +720 | CEquipmentArcheTypePool | **need_equipment** (tok 15244) | 池 {vt@+0, data@+8, cap@+16, count@+20, alloc@+24}; 元素 16B = {CEquipmentArchetype* @+0, 数量 i64 fixed×1e-5 @+8}; 键名 = token_name(原型+8) 装备原型名 (support_equipment / motorized_equipment); 写门 = count>0 ∧ 任一数量 ≠0 (sub_141010B70); ⚠ 池自身地址在 +720, 数据指针在 +728 (少一层解引用 = 读到池虚表) |
| +752..+912 | 地形静态块 ×5 | 地形修正 (attack/defence/movement) | 块门 = attack/defence/movement 任一非零 |
| +952 | 容器 | 动态地形容器 (40B 条) | |

78 槽 → 修饰名映射 = reader 层 STAT2TOK token id 数组。列表 2 元素的 obj: 类别 token@db+84, stats 对象 obj+64。

#### 4.9.2 CVolleyDivTransport 与 conveyor 命令族

**类名绑定 (1.19.3 实证)**: conveyor 元素 = **CMilitaryDeploymentConveyor** (vt 0x14295E100, ~160B, writer 0x140CEBC10 / reader 0x140CEAE70, ctor 0x140CE7070); 行包裹件 W = **CMilitaryDeploymentLine** (64B, vt 0x14295E0A8, writer 0x140CEBD60); 训练行 L = **CMilitaryDeployment** (200B, MI: CEquipmentDistributable@0 (priority@+8, ≠1 写) + CPersistent@24, vt 0x14295E020 / pers 0x14295E058, writer 0x140CEBB30 / reader 0x140CEACB0, ctor 0x140CE6DE0)。

line 包裹件 division_name: dn = *(line+32) (lines 容器 {d@cv+120}); type 恒写 / name_order@dn+128 (≠0 才写) / override SSO@dn+136 (size@dn+152 ≠0, 引号) / override_set_prog b@dn+169 (≠0 写 yes)。

conveyors 元素布局与 GUI 三视图消费 (九字段 GUI 坐实; cv = 元素基):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | idpair | id 对 | {type@+8, id@+12} |
| +32 | 匿名结构 (NNB 形状) | template | 模板侧偏移见下表 |
| +40 | string | name | SSO; GUI 消费 |
| +72 | — | amount | 0 → INFINITY 无限系列 |
| +76 | — | location | 非零 → gs+8 vt[1] → *(obj+192) → sub_1409D91D0 地名串 |
| +80 | — | priority | 0/1/2 → 三钮态 (2,1,1)(1,1,4)(1,3,1) |
| +84 | — | order_index | GUI 消费; 与 +88 orders group 配对 |
| +88 | idpair | orders group | sub_140CE9E00 → RTDynamicCast COrdersGroup 铁证 → sub_140BEAA30(group, order_index) → *(entry+56)+272 = CColor 军团色 |
| +120 | 容器 12B | lines | {d@+120, c@+132}; GUI 消费 |
| +144 | token | role |  |
| +148 | uint8 | closed | GUI 消费 |
| +152 | tag_id | government_in_exile_tag | >0 才写 (实证: ENG cv[0] tid=5=FRA); 训练 ETA 因子双 define dword_143335D10/143319D00 |

**行包裹件 W** (cv+120 / dep+120 容器元素):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | idpair | id 对 |  |
| +32 | 匿名结构 (NNB 形状) | 模板 ptr |  |
| +40 | uint32 | 当前 series 序号 |  |
| +48 | 匿名结构 (NNB 形状) | 训练行 L | 布局见下表 |
| +56 | CVolleyDivTransport* | conveyor 回指 |  |

**训练行 L** (训练行对象):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +32 | CString 32B | equipment (tok 12110) 训练装备引用 | writer/reader 双证 (多态值 I/O); 原表未载 |
| +96 | fixed×1e-5 | 训练进度 (tok 12218) | 定点; >0 写 |
| +104 | fixed×1e-5 | 目标 max_training (tok 13078) | 100000 |
| +112 | — | 装备人力池 army_manpower_value (tok 14075) | sub_140C69830 求和; writer 0x140C6AD50 |
| +144 | — | 需求侧池 army_manpower_need (tok 14076) | reader 0x140C6A330 同容器对 |
| +176 | u32 | max_manpower (tok 10608) | >0 写 |
| +184 | 行包裹件 W* | W 回指 |  |
| +192..+195 | u32 | 停滞理由 id |  |
| +196 | uint8 | 停滞字节 | 置位 → TRAINING_HALTED; 否则人力比不足 → CONVEYOR_CAN_NOT_MANPOWER_TRAIN; 其它 → CONVEYOR_CAN_NOT_TRAIN |

需人 = 模板需人 × (cc+1464 modifier 键 222 + 100000) / 100000。

**模板侧偏移** (除名模板类 tpl):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | — | 图标/所有者上下文 |
| +400 | — | 目标人力 |
| +420 | — | 优先级图标枚举 |
| +492 | tag_id | owner tag |
| +566 | uint8 | 过时警告字节 |

两地图模式类: CMapModeMilitaryDeployment (模式 20) / CMapModeMilitaryDeploymentToOrder (模式 21), 0x558B scoped_ref 内嵌 ConveyorView+6800/+6816 (子对象+1360 = conveyor; [4]Refresh 0X141D87950 激活时退出选址/指派)。

**conveyor 命令族** (11 枚, 全 RTTI 定案):

| 类 | 载荷/语义 |
|---|---|
| CCollapseConveyor |  |
| CChangeConveyorPosition | +48: 1/2 down, 3/4 up, shift 变体 |
| CSetConveyorName |  |
| CSetConveyorSeries |  |
| CSetConveyorPriority |  |
| CAddConveyorLine |  |
| CDeployConveyor |  |
| CRemoveConveyor | >20% 弹确认 |
| CDeployConveyorLine |  |
| CRemoveConveyorLine | L+96>20000 弹确认 CONVEYOR_LINE_CANCEL_ACCEPT_* |
| CSetMarketRequestAutomationOptions | +40 请求 id = (target)+8, +44/+46 三旗 |

⚠ sub_1406CF0F0 = cc+656 CArmy 师列表容器直返 (非「特种部队」专表)。

**CSupplyTruckReinforcementItem (卡车增援行, GUI)**: 宿主 = CCountryDeploymentView (rdata 反查定案); **CDeployBaseItem 七纯虚槽 [19]-[25] 全实现** (SUPPLY_TRUCKS/_DESC/_EMPTY 三 loc 直证); 命令出口 = **CSetSupplyReinforcementPriorityCommand {+40 玩家 tag, +44 优先级}**。

**CCarrierAirWingCompositionWindow / Entry (海军生产线舰载机编成弹窗, GUI)**: 窗 (vt 0x142A750D8, 2816B, CPopUpWindow 族): target = **线 CRef@+2804 (是生产线非 CShip!)**; 线+136 变体 / 线+272→**dep+48 编成映射 ✓ §4.8/§4.8.2 全互证**; 经 CProductionLineNavalItem 开启; confirm 投 **CSetNavalProductionLineAirWingCompositionCommand {+40 = line 键 / +48 = initial_carrier_air_wing_deployment 映射}** (Execute 0X14115C750 写回 dep+48, 双 token 定案) — **与 §4.31.30 舰版编成编辑器同构定案**。Entry (vt 0x142a75250, 2824B): 零覆写 Item 族; 行 = equipment_icon/name + number_box + ±按钮三回调 (**+32 装备项 / +40 机数 / +44 上限 / +48 指回 win+2800**), 内容由宿主窗 rebuild 直写。
