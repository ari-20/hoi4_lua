

### 4.16 海军族 (CStrategicNavyManager → CStrategicNavy → 基地/特混舰队/舰船 + 战史与战果记录)

书内「CNavy」定名 **CStrategicNavy** (vt 0X2973260, RTTI 双证); 管理器定名
**CStrategicNavyManager**。CRailwayGun 属 CUnit 基类域, 见 §4.18 (容器
cc+680, 紧挨师列表 cc+656)。

#### 4.16.1 CStrategicNavyManager

| 项 | 值 |
|---|---|
| RTTI 名 | CStrategicNavyManager (TBB 装饰名 UpdateNavalSupplyHubCache 直出) |
| sizeof | — |
| vtable RVA | 0X29732E0 |
| writer | — |
| loader | — |
| 挂载点 | gs+1688 (`M = *(gs + 1688)`) |

| 管理器偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +8 | CNavy* | per 容器数据指针 — country navy 数组 | {data, count}; 元素 = CNavy* (vtable 0X2973260) |
| +9..+19 | — | = per 容器尾 {cap@+16}  |  |
| +20 | u32 | per 容器计数 |  |
| +21..+31 | — | = per 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (24B 形状) RH 桶数组 | **naval supply hub 全局 RH 表** {结构基@+32, entries@+40 (24B 元 {hash@0, dist@+4, payload, ptr@+16}), count@+48, mask@+52, extra u8@+56, maxload f32@+60=0.9; 清理/扩桶 sub_140EA21B0/sub_140EAE2C0}  |  |
| +48 | uint32 | world_bases — **定名: = supply hub RH 表 count** (586 叶互证) |  |
| +49..+59 | — | = RH 表尾 {mask@+52, extra@+56}  |  |
| +60 | float (uint32 位型) | tuning_factor — **定名: = RH max_load_factor = 0.9** (0x3F666666 位型, 与主文件 §3.2 RH 通用尾同构) | IEEE754 位型读 |

#### 4.16.2 CTaskForce (writer 0X140D7AFA0 / loader 0X140D75470)

writer 0X140D7AFA0 的 a1 = **元素+16 视角**; 运行时偏移 = writer 偏移 + 16
(tf = ser + 16)。⚠ 直接按 writer 偏移读运行时内存会错位读进垃圾。

writer 偏移对照:

| 键 (token) | writer 偏移 (ser) | 运行时偏移 (tf) | 写门 | 备注 |
|---|---|---|---|---|
| repair_last_mission | +1248 | tf+1264 | — | 旁证 |
| spotters | +1536 | tf+1552 | — | 旁证 |
| strike_forces_on_ship | +1560 | tf+1576 | — | 旁证 |
| enemy_mines_factor (0x4DAF) | a1+1600 | **tf+1616** (i64 fixed5) | **signed>0** | 定案; 全二进制唯一发射点, 在 spotters 之后 task_force 块尾 (探针 NOR 9025→0.09025 / ENG 539→0.00539) |
| next_attempt_to_path_to_parent (0x3D04) | +1800 | **tf+1816** | ≠0 | |
| last_delay_to_path_to_parent (0x3D05) | +1804 | **tf+1820** | ≠1 | |
| hours_to_wait_for_repair_check (0x3CDC) | +1808 | tf+1824 (u32) | >0 | writer 实发射 (定案) |
| target_ship_types (0x2810) | 数据 +1840; 计数 +1852 | **tf+1856; tf+1868** | — | 定案: 元素 = 32B MSVC 串非 idpair (三档探针) |

CTaskForce 全键表 (writer 0X140D7AFA0, a1 = 元素+16, 首调
CUnit::Serialize 0X140C06540; 运行时偏移 tf = writer+16; **行序 = writer
发射序落盘契约, 非偏移升序**):

| 键 (token) | tf 偏移 | 类型 | 门 | 备注 |
|---|---|---|---|---|
| ship (10400) | tf+840 | 8B 指针 → CShip (ADEC0 多态) — 容器数据 | c>0 | **GUI: MilitaryOverviewItem 命中** (target = tf raw+40 idpair; sub_1402A6F30=*(tf+24) 灌入) |
| ship (10400) | tf+852 | ship 容器计数 | c>0 | |
| mission (11450) | tf+864 | 代理对象 | 恒写 | |
| repair_mode (13593) | tf+1124 | u32 | 恒写 | |
| underway_replenishment (16427) | tf+1128 | u8 | 恒写  开关 setter (tf 基): 关 → 退订 sub_141022A70(tf+1136); 开 → Init(tf+1136, country, 128, UNDERWAY_REPLENISHMENT_PRIORITY); 小时维持 sub_140D69090: tf+1128 ∧ ¬sub_1406DFDA0(country+1731 旗) → 自动关; 需求 = ceil(24×IN_COMBAT_FUEL_COST(2.0)×(FUEL_COST_MULT×tf 小时燃料消耗/1e5)/1e5×UNDERWAY_REPLENISHMENT_CONVOY_COST_PER_FUEL(0.28)×(1+modifier(637))) — 按日燃料消耗折算; **收益仅射程** (sub_140D66F90: 射程比 × (0.4×(1+modifier(636)))), 不补燃料/组织度||
| convoys (12386) | tf+1136 | CConvoySubscriber 内嵌 | underway_replenishment≠0 | |
| — (15171 = set_task_force_composition_requirements 命令名, 非存档键) | tf+1336 | **CTaskForceComposition 内嵌 104B** (RTTI 实名; vt 0x142973300; 布局见后表) | 非独立键 — 由 tf+1328 对象 writer 0x14198C060 经子键 15166 requirements 发出 | 定案 |
| repair_child (13594) | tf+1176 | 8B 行内 idpair 数组 — 容器数据 | c 循环 | |
| repair_child (13594) | tf+1188 | repair_child 容器计数 | c 循环 | |
| repair_parent (13595) | tf+1200 | 行内 idpair — type | 任一≠0 且 A3D0 有效 | **GUI: split_off 徽标 = 分桶分离舰数** (NAVY_THEATER_DETACHED 族; CNavyTheaterFleetRowItem) |
| repair_parent (13595) | tf+1204 | 行内 idpair — id | 任一≠0 且 A3D0 有效 | |
| detached_activity (15225) | tf+1208 | **枚举 u32: 1=repairing 2=moving_to_refit 3=refitting 4=reinforcing** | ∈1..4 (0 不写) | |
| repair_target (13597) | tf+1216 | 对象指针 → u32@obj+164 | ptr≠0 | |
| refit_equipment_variant (14663) | tf+1224 | 对象指针 → idpair@obj+8 | ptr≠0 | |
| refit_to_variant_after_repair (14664) | tf+1232 | 对象指针 → idpair@obj+8 | ptr≠0 | |
| industrial_manufacturer (19160) | tf+1240 | 行内 idpair — type | 任一≠0 且有效 | |
| industrial_manufacturer (19160) | tf+1244 | 行内 idpair — id | 任一≠0 且有效 | |
| merge_with_after_repair (14665) | tf+1248 | 行内 idpair — type | 任一≠0 | |
| merge_with_after_repair (14665) | tf+1252 | 行内 idpair — id | 任一≠0 | |
| sortie_efficiency (12970) | tf+1260 | u32 | 恒写 | **载机姿态索引** (非燃料): 出击比 = CARRIER_OFFENSIVE_STANCE_SORTIE_RATIO 数组按本值查表 |
| repair_last_mission (13598) | tf+1264 | u32 | ≠0 | |
| hours_waited_for_repairs (15504) | tf+1256 | u32 | ≠0 | |
| repair_split (13596) | tf+1268 | u8 | ≠0 | |
| merge_split (13996) | tf+1269 | u8 | ≠0 | |
| is_sea_locked (13998) | tf+1270 | u8 | ≠0 | |
| auto_reinforcement (15169) | tf+1271 | u8 | ≠0 | |
| fuel (12003) | tf+1272 | i64 fixed5 | ≠0 | **本小时实收** (per-hour scratch): 每小时 tick sub_140D68B90 先清 0, 再由优先级分发 sub_140D64740 (tf+1272 += grant) 灌入; 载入值存活至首整点即被覆盖; loader ser+1256 **落字段** |
| requested (15132) | tf+1280 | i64 fixed5 | ≠0 | 每小时 sub_140C35280 重算: MISSION_COST×(FUEL_COST_MULT×Σ舰用量缓存/1e5)/1e5 (分派表见下); 上游钳制 = tf+64 补给比 × MAX_FUEL_FLOW_MULT (无补给 ⇒ 少要燃料); 读取器 sub_140D6EAC0; loader ser+1264 **落字段** |
| icon (181) | tf+1288 | u32 | 恒写 | |
| use_fleet_color (15195) | tf+1292 | u8 | 恒写 | |
| color (86) | tf+1296 | 对象 (CColor 族) | !use_fleet_color | |
| ai_taskforce_composition (17899) | tf+1328 | **CTaskForceCompositionRequirements 内嵌 224B** (RTTI 实名; vt 0x142A223C8; CPersistent 族; writer 0x14198C060 / reader 0x14198BF60): +8 = requirements 编成 (CTaskForceComposition@tf+1336, 键 15166) / +112 = fulfillment 编成 (@tf+1440, 键 15167) / +216 = ai_taskforce_composition token (@tf+1544, 19479=undefined 不写) | 恒写 (整个对象写在 17899 键下) | 定案 |
| spotters (15275) | tf+1552 | 8B idpair {type@0, id@+4} — 容器数据 | c 循环 | |
| spotters (15275) | tf+1564 | spotters 容器计数 | c 循环 | |
| strike_forces_on_ship (15282) | tf+1576 | 8B idpair {type@0, id@+4} — 容器数据 | c 循环 | |
| strike_forces_on_ship (15282) | tf+1588 | strike_forces_on_ship 容器计数 | c 循环 | |
| enemy_mines_factor (19887) | tf+1616 | i64 fixed5 | signed>0 | |
| next_attempt_to_path_to_parent (15620) | tf+1816 | u32 | ≠0 | |
| last_delay_to_path_to_parent (15621) | tf+1820 | u32 | ≠1 | |
| hours_to_wait_for_repair_check (15580) | tf+1824 | u32 | signed>0 | |
| **naval_headquarter (10193)** | tf+1832 | 8B 指针 → idpair@obj+8 — 容器数据 | c>0 | |
| **naval_headquarter (10193)** | tf+1844 | naval_headquarter 容器计数 | c>0 | |
| target_ship_types (10256) | tf+1856 | 32B MSVC 串 — 容器数据 | c>0 | |
| target_ship_types (10256) | tf+1868 | target_ship_types 容器计数 | c>0 | |

CTaskForce 运行时字段 (不序列化; 燃料结算链定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +312 | CSubUnitDefinition* | 合成统计对象 (0x678B; ctor 0x141018D00); **+712 = statId 69 STAT_COMMON_FUEL_CONSUMPTION = Σ舰每小时燃料用量缓存**; vt[57] (0x140BFBFB0) 读取; 聚合核 sub_140B9AD70 (与师统计同框架, 入口 sub_140C86CC0 传 tf+840 ships 容器) |
| +512 | u32 数组 | 移动路径省份 {data@+512, count@+524}; +524 > 0 = 在航未达 (HOLD/reserve 在航成本门) |
| +933 | u8 | stop_training_at_max_xp (见 mission 补录表) |

海军修正 STAT 桥 (定案): 海军族 modifier id (NAVY_*/NAVAL_*/SUBMARINE_*/CARRIER_* 等 61 个) **不按名直量消费**, 经 subunit stat 定义桥 sub_140BAAA20 — stat+1536 (加值 id) / stat+1544 (因子 id) 查 cc+1464 国家聚合表, 结果并入舰统计总线 (与 statId 体系同宿主)。

**燃料结算链 (每游戏小时)**: 调度 = DoCountryHourlyUpdates 阶段 4 → sub_1407164E0 → sub_1410F71B0 (fs) 内舰队→TF tick sub_140D68B90: tf+1280 = sub_140C35280 (公式与任务态成本分派表如下), tf+1272 清 0; 三优先级分发后 sub_140D64740 补入。燃料比 getter sub_140D6C6F0 = clamp(100000×tf+1272/tf+1280, 0, 100000), requested≤0 → 100000 (载入零态 ⇒ 满比, 任务不挂起)。

| 任务态 | 条件 | define (vanilla) |
|---|---|---|
| 战斗 | tf+436 ≠ 0 | IN_COMBAT_FUEL_COST (2.0) |
| 在港 (当前省 is_land) | desc+210 bit0 | ON_BASE_FUEL_COST (0.0); strike 任务在港 = STRIKE_FORCE_ON_BASE_FUEL_COST_FACTOR (0.25) |
| 任务态 | 任务 ∉ {0 HOLD, 8 reserve} 或 tf+524 ≤ 0 | MISSION_FUEL_COSTS[type] (0.0/1.0×6/0.6 TRAINING/…; 训练且 tf+933 时 0.15/0.6 经验加权混合) |
| HOLD/reserve 在航 | 任务 ∈ {0,8} 且 tf+524 > 0 | HOLD_MISSION_MOVEMENT_COST (1.0) |

requested 公式 = MISSION_COST × (FUEL_COST_MULT(0.10) × Σ舰用量缓存/1e5)/1e5; 上游钳制 = tf+64 补给比 × MAX_FUEL_FLOW_MULT(2.0)。

**低燃料行为**: 比值 ratio = tf+1272/tf+1280; 无任务中止/强制回港 — sub_140D705F0 移动更新全函数无燃料门:

| 面 | 函数 | 公式 |
|---|---|---|
| 任务侦查/效能 | sub_140FAEB20 | strength ×= ratio (线性无下限; 空军侧的 0.25 效率下限海军不用) |
| 训练 XP | sub_140FB97C0 | XP ×= ratio; 逐舰 strength < TRAINING_MIN_STRENGTH 无 XP |
| 舰速统计 | sub_140C3A740 / TF 级 sub_140C37CD0 | (1 + OUT_OF_FUEL_SPEED_FACTOR(−0.75)×(1−ratio)), 下限 10% |
| 射程统计 | sub_140C3A610 | 同式 OUT_OF_FUEL_RANGE_FACTOR (0 = 默认无惩罚) |
| 攻击/雷击 | sub_140C34A50 | stat≠4: + OUT_OF_FUEL_{ATTACK(−0.5),TORPEDO(−0.8)}_FACTOR×(1−ratio); stat==3 雷击项 |
| AI 节约模式 | sub_1406690D0 | 三 define 门 (比 ≤ FUEL_RATIO_TO_EXIST_FUEL_SAVING_MODE 等); 状态存 a1+8928; 和平期预算帽 sub_141A69920 |

is_sea_locked (tf+1270) 与燃料**无关联**: 唯一写点 = sub_140D705F0 海锁恢复块 `tf+1270 = (tf+524 ≤ 0)`, 纯海路可达性; auto_reinforcement (tf+1271) 同无燃料联动。
detached_activity 状态设置器 = sub_140D731A0 (taskforce.cpp:6079 断言): 联写 tf+1208/1216/1224/1240; 迁移写点 = 1 repairing = 分舰链 sub_140D72580(activity=1) (调用者 sub_140D77FF0 沉船总入口/sub_140D77900; sub_140DA0E40 属铁路炮域非 TF, 勘误) / 2 moving_to_refit sub_140D72F10 / 3 refitting sub_140D78F10 (分裂) + sub_140D705F0 在港完成块 (上改装线 sub_140C3D720, repair_parent 有效则 sub_140D76B00 合并) / 4 reinforcing sub_140FB6C70 / 0 完结多处。**状态迁移无燃料门** (唯一交集 = 修理/改装期在港自然落 ON_BASE_FUEL_COST 0.0)。

**CTaskForceComposition** (RTTI 实名; vt 0x142973300; sizeof 104B; CPersistent 族; writer 0x14198B970 / reader 0x14198B630; ctor 0x14198A7A0):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | vtable | — | 槽 0..8; [6]/[7] CFG 空桩 |
| +8 | 容器 24B {data, cap, count@+20, alloc} | **A 紧凑映射 = 唯一序列化源** | 元素 16B (见下表); 按 {sub_unit, role} 二分有序, 同键插入 amount 累加 |
| +32 | 容器 24B | B amounts 读入暂存 | 键 amount (417) |
| +56 | 容器 24B | C sub_units 读入暂存 | 键 sub_units (12176), 兼容旧名 archetype (12103) |
| +80 | 容器 24B | D roles 读入暂存 | 键 roles (14278) |

A 容器元素 (16B; 有序键 = {sub_unit, role}):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | u32 | sub_unit 舰型定义 token (writer 以 token 名发射) |
| 元素+4 | u32 | role 角色 token (0 = any 通配) |
| 元素+8 | u32 | role2 严格角色匹配旗 (默认 0xFFFFFFFF; 不序列化): 需求形 {role=X, role2=-1} = 宽松 (design role==X 或泛型舰 role==0 均满足) / {role=0, role2=X} = 严格 (恰配 design role_icon_index==X, 泛型不计); fulfillment 侧恒 -1 无人读 |
| 元素+12 | u32 | amount 需求舰数 (同键插入时累加) |

> 收尾钩子 = 虚槽 [8] 0x14198B1A0 (load wrapper 读完后调): 三组长度不齐时按 taskforcecomposition.cpp:56 断言截到三者最小值, 逐 B[i] 取 {C[i] sub_unit, D[i] role} 在 A 二分查/插后**释放 B/C/D** — 故运行态常态 A 有值、B/C/D 已空, 读档读键期间三组才并存。
> 命令链: CSetTaskForceCompositionRequirementsCommand (vt 0x1429AFF20; Execute 0x1413569C0) 载荷 {task_force idpair@+40, requirements 编成@+48} — Execute 只把该编成四容器整体拷进 tf+1336 (sub_140D642E0), 不触 +112/+216。
> 满足度缺口 = requirements − fulfillment 逐元扣减 (0x14198AD20; 断言 taskforcecompositionrequirements.cpp:102): 需求元 role2==-1 时 fulfillment 的 role==0 泛型舰计入 (宽松), role2!=-1 时须恰等 (严格); fulfillment 元 role2 全程无人读。需求侧双 builder: 需求表条目带旗 → {role=0, role2=X} (0x14198B790), 无旗 → {role=X, role2=-1} (0x14198B750); 条目源 = 编成编辑器需求模型 robin-hood 表 (24B 条 {amount@+8, role@+12, role2@+16 带旗}, 命令路径 0x141354720)。

mission 块 (units; 存档块名, 非 RTTI 类名) 补录:

| 键 (token) | 偏移 | 类型 | 写门 | writer |
|---|---|---|---|---|
| already_spotted (0x3BB3) | ms+104 (tf+968) | u8 | ≠0 写 yes | 0X140FBEA80 |
| stop_training_at_max_xp (19076) | ms+69 (tf+933) | u8 | ≠0 写 | sub_140FB9B30; 仅 type==7 TRAINING 时 sub_140FBA460 从命令载荷写; 作用 = 训练任务燃料成本混合门 (0.15/0.6 经验加权) |

#### 4.16.3 CShip (writer 0X140C3E6C0 = vt[2]; reader 0x140C3C5A0 = vt[4])

| 项 | 值 |
|---|---|
| RTTI 名 | CShip |
| sizeof | **2360 (0x938)** (CTaskForce loader case 10400 malloc(0x938) 直证 — 原「≥2360」封口, +2360..尾空白不存在) |
| vtable RVA | 0X2957F28 (主表); 第二表 0x2957F90 = +24 IOfficerHolder 子对象 |
| writer | 0X140C3E6C0 (= vt slot2; a1 = sh 直基; 首调基类 0X142220340) |
| reader | 0x140C3C5A0 (= vt slot4; serfam 行 840 + loader 对新舰调 slot3 wrapper 双证) |
| ctor / dtor | 0x140C2FEA0 / 0x140C30380 |
| 挂载点 | CTaskForce ship 容器 (tf+840/tf+852) |

**+128..+1783 = 内嵌 CSubUnitDefinition 克隆 1656B** (copy ctor 自 null def; reader 键 12259 经 sub_140B961B0 重克隆) — 原空白 +236..+839 与 +864..+1575 全部是克隆体内部, **按 §4.18.19 布局 −128 映射即全解** (活体 1524 艘 vt 全中: sprite "heavy_cruiser"@sh+232 (def+104+128)、主统计数组 statId=(off−288−128)/8? 否 — statId=(off−416)/8 式即 def 偏移 −128、reliability = statId65 = 0.8、critical_parts cap4、map_icon=3(ship)@sh+1544 (def+1416)、DB 母本索引=72@sh+1548 (def+1420)); 克隆体后 +1784 = strength。
⚠ 原「舰统计重算 sub_140C21570」误挂 — 该函数触 +4168, 2360B 对象物理不可能, 系他类函数; 原「+856 CModifier 树」活体全零且 getter 不读 (待裁); GUI「+1576 旗」定名 = 克隆 type 位域 capital_ship 0x40 位。

loader 兼容读入键 (writer 均不发射, 8 个新增): air_wings (12213) → +1840 航母机库注册 (strategicair.cpp:5946 断言) / start_experience_factor (13548) → +1824 / pride_of_the_fleet (15002) → +2068 / ordered_name (15501) → +2112 / unordered_name (15502) → +2116 / name (27) → +2080 旧名缓冲 / division_name (14596) 旧 ship_name 键 / refitting (15228) 容忍跳过。held_officer 键名 = 10660 定案。

CShip 键表 (writer 0X140C3E6C0 直证清单; **行序 = writer 发射序落盘契约,
非偏移升序**):

| 键 (token) | sh 偏移 | 类型 | 门 | 备注 |
|---|---|---|---|---|
| definition (12259) | +136 | u32 (ADCE0 枚举式) | 恒写 | |
| last_sunk_ship_info_read (15624) | +56 | u32 | ≠0 | |
| sunk_convoys (12418) | +60 | u32 | ≠0 | |
| equipment (12110) | +64 | 代理 (idpair 族) | 恒写 | **GUI: ShipStats 装备定义行** (+64 池 → 池+1008 def 可见门; sub_141BEF820) |
| strength (10406) | +1784 | i64 fixed5 | 恒写 | |
| organisation (11979) | +1792 | i64 fixed5 | 恒写 | |
| experience (11930) | +1800 | i64 fixed5 | ≠0 | 本级进度 (sub_140C31840 得经验, 钳 ≤ +1808 下级所需); +2048 = 经验脏旗  |
| refit_production_line (15234) | +1848 | 行内 idpair — type | 任一≠0 且有效 | |
| refit_production_line (15234) | +1852 | 行内 idpair — id | 任一≠0 且有效 | |
| government_in_exile_tag (15034) | +2052 | tag (BA5C20→串) | >0 | **GUI: 流亡/可见谓词** (+1576 旗 + +64 池旗 + define 15 门; sub_140C33A50) |
| manpower (10300) | +2056 | u32 | 恒写 | |
| max_manpower (10608) | +2060 | u32 | 恒写 | |
| ship_name (15500) | ptr@+2072 | 对象 (名称块; vt+8 分发在 officer 之前) | 恒写 | **GUI: 舰名/删除确认文案** (glue+7928 sub_141BECA70 → CONFIRMDELETESHIP / DISBAND_PRIDE_OF_THE_FLEET_COST; 投 CDeleteShipCommand {+40 舰, +48 特混舰队}) |
| (officer 内联对象, 无键名) | +2120 | 对象 (vt+8 自序列化; ≈144B 跨 +2120..+2263; seed@+2120+32, 追加军官向量 {d@+2232, c@+2244} = obj+112/+124) | 恒写; **对象定名 = CHeldOfficer 内联** (CShip ctor 虚表写入 + IOfficerHolder vt[1]=0X140C30D10 返 ship+2120 双证) — **舰长数据源定案**: 舰长 = 本对象, 非 +2232 追加向量/非独立 id 对; 军官角色 CRef 走 CUnit+24 指挥官链 (舰→tf+24); **记录族布局与师侧同构** (§4.18.1 officer 子表: 内嵌记录 = 块1 @ship+2144 (seed@+8, name@+16, portraits@+48, male@+80), 追加记录 → officer[2+], 键序 seed/name/portraits/male, held_officer.experience i64 fix5@+2256 >0 写) | |
| history (10293) | +2264 | 容器对象 (ADEC0 多态; 门 = 内部 count @+2264+52 = sh+2316) | count≠0 | 元素布局定案: {+114 = is_sunk 门, +120 = 内嵌 168B CSunkShipInfo (§4.31.29 同型)}; **容器类名定案 = CUnitHistory {+24 type=1 舰, +40 元素向量 c@+52}; owner 槽按 ctor 变体分注 — 舰侧 sub_141445E00 落 +16, 军侧 sub_141445E90 落 +8 (同 vtable 0x1429C1868)**; **GUI: CNaviesViewSunkShipItem** (target = 元素+120 内嵌; assist@+161 / level@+120 / def@+104 全中); **GUI: CShipHistoryEntryItem = 舰长授勋行** (槽[13] 返本容器 ✓; 条目+112 = awardable 旗/+80 日期/+104 icon; 槽[14] 建 CMedalTemplateItem, 点击 = CGiveMedalCommand; **+114/+120 本行不消费** — 沉船归因归 §4.31.30) |
| critical_damage (15357) | +2328 | 16B 元容器数据 {名称串 ptr@0 (*(ptr)+24 = 长度校验), u32@+8}; assert「Invalid damaged part name on ship」ship.cpp:1159 | c>0 | |
| critical_damage (15357) | +2340 | critical_damage 容器计数 | c>0 | |
| raid_instance (19183) | +2352 | 行内 idpair — type | 任一≠0 | |
| raid_instance (19183) | +2356 | 行内 idpair — id | 任一≠0 | |

CShip 运行时燃料行: **+840 = i64 fix5 每小时燃料用量** (不序列化; getter sub_140C36F60; 谓词 sub_140C3AF90 < SHIP_FUEL_EFFICIENCY_WARNING_THRESHOLD → TASK_FORCE_HAS_FUEL_INEFFICIENT_SHIP_FOR_MISSION tooltip); 与 +856 构成 {标量, CModifier 树@+16} 修改值对 (舰统计重算 sub_140C21570 聚合, 基值 = 舰体/装备定义); 逐舰 UI 现算 sub_140C39BF0 = 用量×(1+MODIFIER_NAVY_FUEL_CONSUMPTION_FACTOR id413)×FUEL_COST_MULT×MISSION_COST (TF 级 sub_140C35280 不带该修正项, 走 statId 69 缓存)。

CShip/CTaskForce GUI 消费表:

| 字段 | 消费点 | 用途 |
|---|---|---|
| CShip+8 refid | ShipStatsView (view+6632 ctor 快照; +56 解析缓存; 宿主+5320 idpair 进; 析构安全) | 面板 target 绑定 |
| CShip+24 IOfficerHolder | vt[1]→+32; Update 0X141BEFB60 (缓存 win+10600) | 军官钮刷新 |
| CShip+232 舰体名 + def+968 | sub_140C3A0F0 (兜底 GFX_navalcombat_ship_icon_unknown) | 舰图标串 GFX_unit_\<hull\>_\<n\>_icon_medium |
| CShip+1576 旗 | sub_140C33A50 (define 15 门) + 逐帧 0X141BED5F0 | 流亡/可见谓词 + pride type_icon 切换 (CCountry+592/+596 vs 舰+8/+12) |
| CShip+1832 → tf+472 → CCountry+224 | sub_141BECFC0 | ≥1e5×define → ShipStats 资源门列表 |
| CTaskForce 数组 | CompactShipListView (UpdateCompactShipList, RTTI 定名) | 条目 entry+8/+16 idpair; **entry+1336 = 舰型 DB 索引, entry+1340 = 需求舰数** (COMPACT_SHIP_VIEW_DESC_REQ/TYPE; pride / required_ships_count 窗) |

#### 4.16.4 CFleet (writer 0x140D5EBC0 = vt[2]; ⚠ 旧址 0x1412318A0 = CCountrySupplySystem writer, 清偿批勘误)

> 特混舰队任务分桶件 = **sub_140D51B80** (暗区快裁定案: 按 tf+884 任务类型分桶 + tf+864 CNavalMission 分发; 8 调用方全 CFleet 族)。细节细作留专批。

**sizeof = 304 (0x130)** (malloc 0x130 双站点 + ctor 覆盖 +0..+303 + 活体 +300 alpha 恰填满四重证); RTTI 名 = CFleet (活体 COL 直读 .?AVCFleet@@ + vt_rtti.json 双证); 主虚表 RVA 0x2962A18 / CSelectable 次表 0x2962A70; reader = vt[4] 0x140D582B0; ctor 0x140D503D0 / dtor 0x140D50840 (fleet.cpp:162/163 断言) / 工厂 CreateFleet 0x140D545A0; 基类 = CReferenceObject + CSelectable (ctor sub_140BC2AA0(a1+24, 11))。派生: **CTaskForce sizeof = 1888 (0x760)** (loader 15157 分支 malloc 直证)。挂载点 = cc+632 {d} / cc+644 {c}, 元素 CFleet*。

⚠ GUI 锚「CFleet+1584/+2696 idpair」**物理不可能** (sizeof=304) — 系 GUI 项类自身偏移误挂 CFleet 名下, 待重勘; 「fl+24 = 类型标签 11」实为 CSelectable 第二基类虚表 (type id 11 落 +32, selected 旗落 +36); 「fl+44 = 容器 cap」实为 hours RH 结构基死槽 (count@+56/mask@+60/lf 0.9@+68)。

完整成员布局 (+0..+303 全覆盖, 无成片空白):

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vt | CFleet 主虚表 0x2962A18 | [2] writer / [4] reader |
| +8 | idpair 8B | CReferenceObject::ref {type@+8, id@+12} (基类 writer 发键 225/11) | 舰队数字 id 直印 AddTaskForce 日志 |
| +16 | u8 | 基类尾旗 (ctor 0; 活体 1, 写点未定位) | 语义待裁 |
| +24 | vt | **CSelectable 子对象虚表** 0x2962A70 | |
| +32 | u32 | CSelectable type id = **11** | |
| +36 | u8 | selected 旗 (dtor 断言 false, fleet.cpp:163) | |
| +40 | RH 结构基 | hours_without_patrol_missions_pairs RH 表 (死槽@+40; 桶数组@+48, **count@+56, mask@+60, extra@+64, lf 0.9@+68**; 24B 桶 {dist u8@+4, region ptr@+8 → id@+88, hours u32@+16}) | 键 15599 成对发射 |
| +72 | 容器 | **strategic_region** {d@72, cap@80, count@84, alloc@88} — 元 8B CRegion* (id@ptr+88) | 键 12014: 先收 u32 数组再发射, 门 count>0 |
| +96 | 容器 | **区域范围表** {d@96, cap@104, count@108, alloc@112} — 元 16B {CFleet*, start u32, end u32}, 对排序后区域数组切段 (fleet.cpp:1788 断言) | 重建 sub_140D530E0 |
| +120 | 16B 节点 | 自引用范围节点 {self@120, start@128=0, end@132=区域数镜像} (无区域时挂进每个 TF mission) | |
| +136 | u32 | **tick_to_check_naval_invasion_support** (键 15583, 门 >0; 书原表无此键) | |
| +144 | map 容器 | **bombardment_region** {d@144, cap@152, count@156, alloc@160} — 16B 元 {region ptr@+0 → id@ptr+88, val u32@+8}; 门 count≠0; 写序 = 容器序 | 提取器: 首对 region 进键名, 余对 " k=v" 拼进值 |
| +168 | CCountry* | **owner 国家指针** (ctor sub_140BB4390) | |
| +176 | idpair 8B | **leader** {type@176, id@180} (键 10423; 门 ≠ qword_14333D528 空哨兵) | |
| +184 | 容器 | **task_force** {d@184, cap@192, count@196, alloc@200} — 元 8B CTaskForce* (writer 逐元写 键 15157 + 元+16 视角) | |
| +208 | CNavyTheaterGroup* | **所属编组** (getter 0x140D50F00 / setter 0x140D5A620; 挂组 sub_1415B9550: fleet+208 = group 且 group+32 成员向量 += fleet; 组 vtable 0x29DCCE0 RTTI 直证) | |
| +216 | CProvince* | **home_base = 家港省指针** (键 10241, 发射 *(u32*)(prov+164) = 省 id — §4.14 定案; loader 解析失败报 "Invalid province ID for fleet home base"; G 批活体 vt 0x2971B18 RTTI 直证 — D13 原记「CNavalBase*」订正, 88B 的 CNavalBase 无 +164 槽) | |
| +224 | MSVC 串 32B | name (键 27; ctor 默认 "FLEET_NAME_NOT_SET") | |
| +256 | u32 | icon (键 181) | |
| +260 | u8 | **automated_homebase** (键 10395, bool 恒写) | |
| +261 | u8 | **_TaskForcesLock** (AddTaskForce 断言, fleet.cpp:608) | |
| +272 | CColor 32B | color (键 86; {vt@272, R f32@288, G@292, B@296, **A f32@300**}; 原记 f32×3 吻合, 补 A) | writer 校验和流门跳过 name/color/icon |

writer 全键序 (发射契约): [基类块 键 11 {11 id, 225 type}] → leader (10423) → name (27) → color (86) → icon (181) → task_force (15157 逐元) → strategic_region (12014) → hours_without_patrol_missions_pairs (15599, 8B 对收集→sort→成对) → bombardment_region (15483) → tick_to_check_naval_invasion_support (15583) → home_base (10241) → automated_homebase (10395)。

⚠ **assign_to_minimum_order (15603) 不属于 CFleet**: writer/loader 全链无此键; 唯一发射者 sub_141856A30 (键 63 group / 10403 unit / 12342 order_index / 15603 ← bool+76; 无静态调用者 = 仅 vtable 可达, 宿主类待裁, 形状 ≈80B) — 原挂 CFleet 名下属误挂, 移出本表。

reader 兼容旧键: naval_base (12790) / hours_without_patrol_missions (15291) 跳过。

CFleet/舰队视图 GUI 消费表:

| 字段 | 消费点 | 用途 |
|---|---|---|
| CFleet idpair (fl+8) | CFleetsBottomBarItem target@item+32 (SetTarget 0X141DE6F60 直拷 fl+8; ref.h:0x53 互证) | 底栏舰队项; fl+224 name 命中 |
| 选择集对象+1100 idpair → resolve → +32 CFleet* 数组 | CFleetsBottomBar (属主未决) | 选择集 target |
| tf ship 容器 (tf+840/+852) / repair_parent (tf+1200/+1204) / target_ship_types (tf+1856/+1868) / refid | CNaviesView (17×1288B 胶水块; 内嵌 CNavyLeaderWindow / CMoveShipsWindow / CTaskForceCompositionEditor / CCompactShipListView 四子件) | 选择集驱动视图 |
| tf+884 | CNaviesView 组行 | 任务类型枚举 (定案: ==8 = reserve, 与组行 reserve 判定同源) |
| tf+832 | MilitaryOverviewItem | leader 指针 |
| tf+496 | MilitaryOverviewItem | 当前省份 CProvince* (prov+200 → 战略区; prov+184 → 静态描述符, desc+210 bit0 = is_land 在港判定) |
| tf+436 | MilitaryOverviewItem | 战斗中谓词 |
| tf+472 | MilitaryOverviewItem | owner |
| CFleet+1584 idpair | CNavyTheaterFleetItem target | 剧场视图舰队项 |
| CFleet+2696 idpair (+2704 内嵌 FleetItem, +40 TaskForceItem 列表, RTTI 定名) | CNavyTheaterFleetRowItem target | 舰队行项 |
| fl+184 tf 容器 / fl+224 name / fl+256 icon / fl+272 color / fl+84 region 计数 | CNavyTheaterFleetRowItem (FleetRowItem) | 行填充 |
| fleet+36 | — | selected byte (推定) |
| host 链 `*(country+352)` → CNavyTheater+16/+28 | 剧场视图 | 逐组建 GroupItem (定案) |
| fl+176 leader idpair | CNavyLeaderWindow / CNavyLeaderItem | leader 关联 (定案) |
| CFleet idpair @win+7048 | CNavyLeaderWindow target (可空 = 名册态; 双宿主 = 舰队视图+22240 指派态 / CCountryOfficerCorpView **+8592** 名册态) | leader 窗 target |
| leader 裸指针 @item+3944 | CNavyLeaderItem (ctor a4 直存, 无 SetTarget 槽; 填充器 sub_141AD21D0) | leader 项; 命中 leader+64 名/+288/+3528/+3680/+3708/+3912/四技能 (详见 §4.4) |

命令族: 载荷全表见 §4.33 (CSetFleetLeaderCommand 12370 / CCreateUnitLeaderCommand
13107 / CSetFleetCommand 15165); 确认弹窗 CChangeNavyLeaderDialog /
CConfirmDisbandFleet = GUI 类, 见 §4.31.57。

舰队块 (cc+632 容器, 0x9C0 结构, tf→ship 两级): taskforce 顶层 id 对;
ship officer {seed@sh+2120+32, male 位, name; officer[2+] = 追加军官向量
{d@sh+2232, count@+2244} 88B/元, 详见 §4.18 officer 行}; ship_name override
串; refit_line 字段级定案见 §4.8 (生产线元素表: refit 变体 / names 容器 /
general 线特化)。

#### 4.16.5 CStrategicNavy (vtable 0X2973260)

| 项 | 值 |
|---|---|
| RTTI 名 | CStrategicNavy (书内别名 CNavy; RTTI 双证) |
| sizeof | — |
| vtable RVA | 0X2973260 |
| writer | 0X140EB2250 (a1 = S+8; = vt slot8 — **CStrategicNavy::Serialize 专用**) |
| loader | sub_140EACAF0 (slot10, if 链) |
| 挂载点 | gs+1688 → M+8 数组元素 (arr = rp(M+8), n@M+20 → S = rp(arr+8×idx)) |
| 序列化基 | S+8 (lua 偏移 = raw+16); dtor sub_140E9E0C0 (容器谱来源) |

全块序列化 (定案; token 全序与存档原文逐位吻合): 挂载链 `M = rp(gs+1688)`
(vt 0X29732E0) → `arr = rp(M+8)`, `n@M+20` → `S = rp(arr+8*idx)`
(vt 0X2973260) → 块 writer 0X140EB2250 (a1 = S+8)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +24 | CNavalBase* | 海军基地 容器数据指针 | 元素 = CNavalBase* (vtable 0X29731C0), count<4096; **+40 = 省 id→CNavalBase RH 表** (解析器 sub_140E7C420 定案, GUI 基地图标/修理窗共用) |  |
| +25..+35 | — | = bases 容器尾 {cap@+32}  |  |  |
| +36 | u32 | 海军基地 容器计数 |  |  |
| +37..+47 | — | = bases 容器尾 {alloc@+40}  |  |  |
| +48 | CNavalBase* 容器 24B | 基地引用数组 {d@48, cap@56, c@60, alloc@64} (运行时-only; 基地被移除时对应槽置空 — sub_140EAAFE0 跨国转移) | 不序列化 | 形态定案/语义推定 |
| +72 | 容器 24B | **naval access/interest 国缓存** {d@72, cap@80, c@84, alloc@88} — u32 国 idx 数组 (四源: 派系成员 + diplo+392 单 tag + wargoal 目标国 RH + military_access/docking_rights 关系国; 填充者 sub_140EADF80; 探针 GER/JAP 实证) | 不序列化  |  |
| +104 | 容器 24B | **per-region CNavalMission\* 桶** {d@104, cap@112, c@116, alloc@120} — 276 桶×24B vector (区域数维; GER 桶 138/147/173 探针实证) | 不序列化; **GUI: 任务扩展行数据源** (CNavalMissionExtensionEntry: region+88 = 桶下标; **mission+8 = CTaskForce\* 新锚 / mission+20 = 任务类型 u32**; pride 判定 = ship+1832 == tf 回指; tooltip SPECIFIC_NAVY_CONTAINS_PRIDE_OF_FLEET) |  |
| +128 | u32 数组 | per_region_danger 容器数据 {d@128, c@140} | 稠密 u32 区域数组, 见 token 全序表; 块门 c≠0 但全 0 值时提取器无叶 → 全 0 不发射 |  |
| +140 | u32 | per_region_danger 容器计数 |  |  |
| +141..+151 | — | = danger/regional_convoys 容器尾 (cap/alloc) |  |  |
| +152 | SRegionalConvoyData* | regional_convoys 容器数据指针 — 稀疏数组 {data@S+152, count@S+164} | 305 战略区域, **stride 48 = SRegionalConvoyData** (下表) | 定案; reader Country.navy.regional_convoys; 提取器: 有条目时块前缀被吞 → 有条目不发容量行 / 无条目发 regional_convoys.#1=容量 |
| +153..+163 | — | = regional_convoys 容器尾  |  |  |
| +164 | u32 | regional_convoys 容器计数 |  |  |
| +165..+175 | — | = regional_convoys/access 容器尾  |  |  |
| +176 | int8 | per_region_access 容器数据指针 | int8 数组; **>0 才写 idx=val 对** |  |
| +177..+187 | — | = access 容器尾  |  |  |
| +188 | u32 | per_region_access 容器计数 |  |  |
| +189..+199 | — | = access/mines 容器尾  |  |  |
| +200 | int64 | mines 容器数据指针 | 8B 数组 |  |
| +201..+211 | — | = mines 容器尾  |  |  |
| +212 | u32 | mines 容器计数 | 8B 数组 |  |
| +213..+223 | — | = mines/accident 容器尾  |  |  |
| +224 | CNavalAccidentReport* 容器 | naval_accidents 容器数据指针 | 元素 8B 指针 → CNavalAccidentReport (vt 0X295DDC8; **元素 writer 0X140CE6590 = vt slot2**; 0X140EB2250 = CStrategicNavy::Serialize 专用, 勿混) | 定案; loader 门 rec+8 (region 指针) 非空 |
| +225..+235 | — | = accident 容器尾  |  |  |
| +236 | u32 | naval_accidents 容器计数 |  |  |
| +248 | CNavalMineReport* 容器 24B | **mine_report** {d@248, cap@256, c@260, alloc@264} | loader malloc 0x50 + CNavalMineReport::vftable | loader-only; ⚠ 现版 writer 不发射 (token 15321 仅 loader 识) |
| +272 | 容器 24B | **active CNavalMission\* 平表** {d@272, cap@280, c@284, alloc@288} (元素 vt 0X297F038 = CNavalMission RTTI 直查) | 不序列化  |  |
| +297 | u8 | **bases dirty flag** (基地增删后置 1; sub_140EAAFE0/sub_140EAACF0/sub_140EAA7F0 三处写) | 不序列化  |  |
| +304 | CNavalUnitTransfer* 向量 | naval_transport 容器数据指针 | 元素 = 8B 指针 → CNavalUnitTransfer (vt 0X296D8A8, 176B=0xB0; 字段表按指针解引用读取, 见 §4.16.7) | reader Country.navy.naval_transports |
| +316 | uint32 | naval_transport 容器计数 |  |  |
| +328 | 容器 24B | **task_force_templates** {d@328, cap@336, c@340, alloc@344} — **136B 内联元** {name MSVC 串@+0 (token 27), composition_requirements 多态对象@+32 (token 15168)} | 块 token 15175 task_force_template | loader: name 空或 composition 无效不入容器 |
| +340 | u32 | task_force_templates **容器计数** | | |
| +341..+351 | — | = templates 容器尾 {alloc@+344}  |  |  |
| +352 | RH 结构基 | convoy_escort_presence_history RH **结构基 @+352** (loader 插入点 = a1+344 ser; struct+0 = 四面无读者死槽 (负定案), data@+360=struct+8, mask@struct+20=+372, extra@struct+24=+376; 条目 40B 见 §4.16.11) |  |  |
| +361..+371 | — | = RH 结构体内  |  |  |
| +372 | u32 | convoy_escort_presence_history RH mask | | |
| +376 | u8 | convoy_escort_presence_history RH extra | | |
| +384 | 匿名结构 (200B 形状) | **per-navy 邻接规则 (海峡/运河通行) 缓存** — 200B 无 vtable {owner 回指 + 3×64B block (kind 2/1/0, region→u16 组映射 + 376B 元规则 RH)}; 谓词链落 adjacencyrule.cpp (EAdjacencyRuleSubject) | 不序列化  |  |
| +392 | 容器 24B | **naval_supply_hub 省份缓存** {d@392, cap@400, c@404, alloc@408} — u32 省 id (填充者 sub_140EB1840 遍历 controlled_provinces → prov+480 建筑实例数组 → 建筑类型共享状态 F+886 旗 = naval_supply_hub 类型旗 tok 10194, 定案; ⚠ **CNavalBase+392 = owner tag u32 跨类同偏移并存, 勿混**) | 不序列化  |  |
| +416 | 匿名结构 (8B 形状) 向量 | homebase_observers {d@416, c@428} 8B 元 {prov u32@0, count u8@+4} | 逐元匿名块 "prov count" |  |
| +428 | u32 | homebase_observers 容器计数 |  |  |
| +440 | uint32 | dockyards max_allowed |  |  |
| +444 | uint32 | used |  |  |

token 全序表:

| token | S 偏移 | 语义 |
|---|---|---|
| 13066 | +304 | naval_transport 容器数据 |
| 13066 | +316 | naval_transport 容器计数 |
| 14923 | +152 | regional_convoys |
| 14654 | +176 | per_region_access 容器数据 (i8) |
| 14654 | +188 | per_region_access 容器计数 |
| 14658 | +200 | per_region_mines 容器数据 (i64; 定案, 探针 AUS 168→1.357) |
| 14658 | +212 | per_region_mines 容器计数 |
| 15588 | +128 | per_region_danger 容器数据 — 稠密 u32 区域数组, writer 写 "idx val" 对仅 val>0 → savefull 折叠单叶 .#1 |
| 15588 | +140 | per_region_danger 容器计数 |
| 19972 | +416 | homebase_observers 容器数据 — 元 {prov u32@0, count u8@+4}, 逐元匿名块 "prov count" |
| 19972 | +428 | homebase_observers 容器计数 |
| 15305 | +224 | naval_accident |
| 15336 (0x3BE8) | +440 | dockyards (双 token 双槽) |
| 15338 (0x3BEA) | +444 | dockyards (双 token 双槽) |

#### 4.16.6 SRegionalConvoyData (48B)

SRegionalConvoyData (48B; 元 vt 0x142973210; 定案) — 稀疏写出:
SSparseArrayWriter (vt 0X2973490 slot1 = 0X140EB2070) 先写裸容量 (u32@壳+12
= 305) 再逐**非默认**元 `{ index=i, data={…} }`; **默认谓词 0X140EA8D50** =
三字段全默认才不写 (⚠ 条目门 = 非默认谓词, 不是 rc≠0); data writer
0X140EB2AF0 三字段各自条件写:

| 偏移 | 类型 | 名称/语义 | 默认 | 写门 |
|---|---|---|---|---|
| +0 | vt | 0x142973210 | — | — |
| +8 | uint32 | required_convoys (0x30CA) | 0 | ≠0 |
| +16 | fixed×1e-5 | efficiency (0x35E7) | 100000 (=1.0) | ≠100000 |
| +24 | vt | CGameDate 内嵌 vt | — | — |
| +32 | hours | last_sunk_convoy_date (0x3A4A) | **43817520** (dword_143086B38) | **≠哨兵才写** (SL.date 哨兵表不含 43817520, 段内须显式门) |
| +40 | vt | 第二 CGameDate 内嵌 vt | — | 未写盘字段 |

#### 4.16.7 CNavalUnitTransfer (176B, naval_transport 元素)

CNavalUnitTransfer (176B = 0xB0; vt 0X296D8A8; 元素 writer 0X140E28F40;
定案) — 容器元素 = 8B 指针, 下表偏移按指针解引用后读取:

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +16 | uint8 | id 块门 (refid 经 B400) | ≠0 |
| +24 | idpair | combat 容器数据指针 — id 对数组 {d, c} | c>0 |
| +25..+35 | — | = combat 容器 {data@24, **cap@32**, count@36, alloc@40} 内部 (pdx 24B) |  |
| +36 | u32 | combat 容器计数 | c>0 |
| +37..+47 | — | = combat count 尾 + **alloc@40**  |  |
| +48 | u32 | spotter.type — id 对之 type (refid 对) | 任一≠0 |
| +52 | u32 | spotter.id — id 对之 id | 任一≠0 |
| +56 | idpair | unit 容器数据指针 — refid 数组 {d, c} | 元素有效且 A3D0−16≠0 |
| +57..+67 | — | = unit 容器 {data@56, **cap@64**, count@68, alloc@72} 内部  |  |
| +68 | u32 | unit 容器计数 |  |
| +69..+79 | — | = unit count 尾 + **alloc@72**  |  |
| +80 | uint32 | target_provinces | 无条件 |
| +84 | uint32 | province | 无条件 |
| +88 | tag_id | country (BA5C20→串) | 无条件 |
| +92 | uint8 | **invasion_group (0x316A)** | **≠0 仅真写 yes** (定案) |
| +93 | uint8 | is_returning (0x3938) | ≠0 |
| +94 | uint8 | force_revalidate_route (0x393F) | ≠0 |
| +96 | uint32 | cooldown (0x391E) | >0 |
| +104 | uint32 | path 容器数据指针 — u32 数组 {d, c} | c>0 |
| +105..+115 | — | = path 容器 {data@104, **cap@112**, count@116, alloc@120} 内部 (u32 省 id 数组) |  |
| +116 | u32 | path 容器计数 | c>0 |
| +117..+135 | — | = path count 尾 + **alloc@120..127** + **convoys 块对象@+136** 前 pad  |  |
| +136 | 内嵌 | convoys 块对象 | 无条件 |

海军运输相关容器对照 (定案):

| 宿主/元素 | token | 数据偏移 | 计数偏移 | 元素 |
|---|---|---|---|---|
| CNavalUnitTransfer (NT) | 0x2916 | T+24 | T+36 | idpair 8B {type@0, id@+4} |
| origin/export 元基类 (0X140CBE140; cli = c+240) | — | +88 | +100 | combat |
| resources (rs) | 0x38D3 | rs+1952 | rs+1964 | modify_building_resources 条 32B {building token@+0, 内层 {data@+8, count@+20}}; 主 writer 0X140CBE2D0 (a1 = rs+24) |
| CEquipmentConvoyClient | — | c+328 | c+340 | combat |

modify_building_resources 内层元 (16B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | u32 | level |
| +8 | i64 fixed5 | amount (⚠ 内存 300000 ↔ save 3) |

resources 叶名 `<building>.<level>`。

#### 4.16.7b CConvoySubscriber 与运输船管理器 (country+4608)

**CConvoySubscriber** (40B, vt 0x14295c0f0) 内嵌三处: css+232 / tf+1136 / CNavalUnitTransfer+136; 另有轻客户端 (CEquipmentConvoyClient 族) 内嵌 +8/+32/+136 小宿主。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | u32 | allocated (已分得运输船数) |
| +12 | u32 | requested (申请数; RequestConvoys sub_141022950 写) |
| +16 | u32 | 静态标签 (Init 第 3 参: 2/4/32/128; 分配面不读) |
| +24 | CCountry* | 订阅宿主国 |
| +32 | 桶指针 | 所属优先级桶 (订阅时回填) |

订阅链: Init sub_141021F90 (convoys.cpp:29 断言; 旧国非空先退订, requested/allocated **保值重订阅**) → 订阅 sub_1410207D0 (按**优先级键**二分定位/建桶, 桶 40B {键, Σallocated, Σrequested, 订阅者数组, cap, count, allocator} 按键升序插入, 订阅者尾插 1.5× 扩容, 三面聚合同步); 退订 sub_1410227F0 (聚合反减; 桶仅剩 1 人整桶释放, 否则桶内 swap-remove; sub+8/+12 清零; 尾调 sub_1410215C0 全量再平衡)。优先级键 = define 值: NAVAL_INVASION/NAVAL_TRANSFER(1) / SUPPLY(2) / RESOURCE_LENDLEASE(3) / RESOURCE_EXPORT(4) / RESOURCE_ORIGIN(5) / RESOURCE_PURCHASE(6) / UNDERWAY_REPLENISHMENT(7) — **值大 = 优先级低** (桶升序, 缺口回剥从数组尾开始)。分配 = RequestConvoys 即时分派, 缺口时从最低优先级桶整段剥除后顺位重填; **沉船反应** = sub_1410225E0 扣池后按阈值触发同一回剥 (convoys.cpp:437/612/53 断言族)。

管理器 (country+4608): {+16 池对容器头 {data@+48, cap@+56, count@+60, alloc@+64} 16B 元 {CResource*, amount i64 fixed5}, +80 桶指针数组 data / +92 count, +104 Σrequested, +108 Σallocated, +112 运输船变体资源缓存 (sub_141021920, 从 country+3944 资源数组取首个 flag&1 项), +120 池缓存有效旗, +128 池缓存 fixed5}。池读 = sub_14100DCB0 (Σ flag(resource+1032)&1 的 amount); 可用 = sub_1402BC910 (池/1e5); 空闲 = sub_1402BC8A0 (池/1e5 − Σallocated); 指定优先级以下已占 = sub_141021C20。css 日重建 = sub_141230D40; 贸易路线申请点 = lambda_2 sub_141225420。

#### 4.16.8 CNavalBase

CNavalBase (vtable 0X29731C0; **sizeof = 88 (0x58)** malloc 三重证; writer = vt[2] 0x140EB2180 / reader = vt[4] 0x140EAC9A0; ctor 无独立函数 — 内联于建基地工厂 sub_140E9F210; dtor sub_140E9DAB0; 序列化只发 3 键: 15334 ships_in_repair (count≠0) / 141 priority (门 = **≠1**, ctor 默认 1 — 原「≠0」订正) / 15434 disabled 逐元; province/level/max_level 不序列化, 读档由 init sub_140EB1DF0 从 prov+400 建筑实例派生 (inst+66→level、inst+64→max_level); 存档叶形 = strategic_navy.naval_base.<省id>.priority — 元素头串 = 省 id 十进制串; **省→基地 RH 表在管理器 M+40** (全局 547 条, 活体与各国 bases 容器同对象群)):
⚠ 原跨类同偏移警告订正: 「CNavalBase+392 = owner tag」不存在 (88B 对象) — 该偏移实为 **CProvince+392 controller** 之误标。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CStrategicNavy* | owner 回指 (其 +96 = 管理器 M) |
| +16 | uint32 | province |
| +20 | uint32 | level |
| +24 | uint32 | max_level |
| +28 | uint32 | **修理容量** (min 钳 + 超容警报双证; GUI = CNavalBaseMapIcon populate 消费) |
| +32 | u32 | priority — writer ADFE0 按 u32 存读 (定案); **门 = ≠1** (ctor 默认 1; 原「≠0 才写」订正) |
| +40 | idpair | ships_in_repair 容器数据 (8B 内联对 {type@0, id@+4}); count@+52; **GUI: 修理队列数据源归属定案** (CNavalRepairWindow 队列 = CStrategicNavy+24 bases 容器 → 本字段, 非 §4.8 refit 生产线; 行类 CNavalRepairQueueNavalBaseEntry 行+3904 = nb / CNavalRepairQueueShipEntry 行+48 = 船 idpair); 发射 = `#N` 恒编号 (1 起容器序, 值 "id=N type=T") |
| +41..+51 | — | = ships_in_repair 容器尾  |
| +52 | u32 | ships_in_repair 容器计数 |
| +53..+63 | — | = ships_in_repair 容器尾 + disabled 前置  |
| +64 | string | **disabled_for_repairs 串列表** 容器数据 (token 0x3C4A = 15434, writer 直证); count@+76 |
| +65..+75 | — | = disabled_for_repairs 容器尾  |
| +76 | u32 | disabled_for_repairs 串列表容器计数 |
| +80 | ptr | 第二容器分配器指针 (共享静态 off_143085170) + 尾填充至 88 — 对象到 88 为止, 原「+80..尾 空白」闭合 |
| ⚠ | — | 原「CNavalBase+392 = owner tag u32」跨类警告**废** — 88B 对象无 +392 槽, 该偏移实为 CProvince+392 controller 误标 (§4.14) |
修理链: 入队 sub_140EAB160 (本国优先 + repair_mode 降序) + 插入位规则 sub_140EA4EE0; 队列小时处理 sub_140EA1280 + 交战门 sub_140EA10E0; 速率 = sub_140D655B0 (NAVALBASE_REPAIR_MULT × modifier 475 × 基地系数, **补给门**用 calc+184 _RemainingSupply)。


#### 4.16.9 CNavalAccidentReport (72B)

CNavalAccidentReport (72B = 0x48; vt 0X295DDC8; Serialize = 0X140CE6590 =
vt slot2, 定案; 0X140EB2250 = CStrategicNavy::Serialize 专用, 勿混);
a1=rec:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 (间接) | uint32 | region = uint32@(*(rec+8)+88) |
| +16 | u32 | equipment.type — id 对之 type (id 对 {type, id}) |
| +20 | u32 | equipment.id — id 对之 id |
| +32 | u8 | **is_sunk** (token 14661; ≠0 才写) |
| +36 | u32 | ship.type — id 对之 type (id 对 {type, id}) |
| +40 | u32 | ship.id — id 对之 id |
| +44 | tag u32 | **country** (token 10394, BA5C20→串; 恒写) |
| +56 | hours | **to_discard_date** (token 15510) — 24B {vt1@+48, hours@+56, vt2@+64}, ADEC0 代理 = vt2@+64; 恒写 |

#### 4.16.10 CNavalMineReport (80B)

CNavalMineReport (80B = 0x50; vt 0X295DE18; Serialize 0X140CE6D20 = vt
slot2; 定案) — 与事故记录同头; **date = 单个 CGameDate 24B {vt1@+48,
hours@+56 = 43808760 哨兵, vt2@+64}** (loader 内联 ctor 定案 — 不存在第二
未发射日期), 序列化只发 to_discard_date (代理 = vt2@+64)。容器 {d@S+248,
c@S+260} writer 不发射 (token 15321 仅 loader 识)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 (间接) | uint32 | region = uint32@(*(rec+8)+88) | — |
| +16 | idpair | equipment {type@+16, id@+20} | — |
| +32 | u8 | is_sunk | ≠0 |
| +36 | idpair | ship {type@+36, id@+40} | — |
| +44 | tag u32 | country (token 10394, BA5C20→串) | — |
| +48..+71 | CGameDate 24B | date {vt1@+48, hours@+56 = 43808760 哨兵, vt2@+64} | 只发 to_discard_date (代理 = vt2@+64) |
| +72 | tag u32 | country 尾部多发 (token 10394; 同键双发 = 重复标量叶不编号形态; 推定 = 布雷国+被炸国二元组) | — |

has_mined 深扫链 (复合链, 推定; 单批孤证, cc 侧首跳管理器指针未钉偏移):
cc → 水雷管理器 → 元 {+176/+188} → 子 {+184} → 表 {data@+112, count@+124, 48B 条 {id@+8}} → 对象旗 {+184 u8, +200, +210 u8}。

#### 4.16.11 convoy_escort_presence_history 条目 (40B)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +4 | uint8 | dist | 有效值 1..0xFE |
| +8 | uint32 | region | |
| +16 | 环形缓冲 | value 内嵌 {buf@+16, capacity@+24, head@+28, tail@+32} | 元素 uint32 (0/1); 落盘 = head..tail 环形展开 (count = tail<head ? capacity+tail−head : tail−head; 满载 capacity−1; ⚠ 线性读法读出槽外垃圾) |

#### 4.16.12 NNavalMission::EMissionType 枚举与 AI 侧任务写点 (A6 锚)

**任务调度与状态机** (定案): 调度 = master update 阶段 9 → sub_140EA79F0
(串行逐 navy sub_140EA76B0 + 收集 S+272 活任务平表 + tbb parallel_for 逐任务
sub_140FBE250 域量重算 = mission+64 低 32 位 Σ计数×规模); TF 侧 **sub_140D705F0
(移动更新) 尾部 → sub_140FB7630 (+224 倒计时) + sub_140D79900 (TF 小时总驱动:
detached_activity 1..4 状态机 + 修理分舰检查) → sub_140FBCB90 (mission 状态机,
navalmission.cpp:1323/1437/1452)**; sub_140D7A460 = repairing 分支的归队判定
(MIN_REPAIR_FOR_JOINING_COMBATS[min(tf+1124,4)] 门 + 全舰修满门), 非主路径。

detached_activity 状态机 (tf+1208): 1=repairing (可用且到修理目标省 →
sub_140D78BA0 开修 / 否则取消命令; **sub_140D7A460 归队**: repair_last_mission
==2 (strike) 且 repair_mode≠5 → 维修度 vt[34] ≥ 阈值, 或全舰修满
sub_140C38740 → 归队; 在修理目标省且任务=8 也跑一次状态机) / 2=moving_to_refit
(sub_140D78BA0) / 3=refitting (sub_140D79DE0) / 4=reinforcing (sub_140D7A180)
— 3/4 在 §4.16.2 在册。

10 类任务分派 (sub_140FBCB90 switch):

| type | 名 | handler | 状态机核心 |
|---|---|---|---|
| 0 | HOLD | 内联 | 门: `+49==0 ∧ AGGRESSION_SETTINGS_VALUES[+52] > 0`; 扫本省 (tf+496 → prov+260/prov+248) 他舰 TF: 非 HOLD 关系 + 目标舰型过滤 (tf+1868 计数≠0 时逐舰 sh+136 def 匹配 tf+1856 清单) + 战斗序列 ≥3 (交战国) → **sub_140BB99D0 开战**; 无果 +68=0 |
| 1 | PATROL | sub_140FBB0A0 | 侦查引擎 (下); 目标失效清 +112/+108/+136; +108 在区递增; 完全侦出 (+128 ≥ 1e7) → +104 锁存 + 三级 notify (sub_140C01B70: 1=部分/2=发现/3=可攻击; 阈值 SPOTTING_MISSION_DETECTION_THRESHOLD_LOW/MEDIUM) |
| 2 | STRIKE_FORCE | sub_140FB3C90 | strike 目标 (+160) 有效且就绪 (sub_140FBE950) → 追击目标省; 无目标 → 舰队目标省 (fleet+216) 待命; 同省相遇 → sub_140BB99D0 开战 + sub_140D766E0 注销目标 |
| 3 | CONVOY_RAIDING | sub_140FBC730 | 目标态: +144 护航客户 / +152 海运运输 (+92 is_returning 区分); sub_140FBB810 接敌现运 (省 +272/+284 与 +296/+308 TF 在场表 → tf+760 运输: 返航∨态<2 + 冷却 +96≤0 + 无 spotter + invasion_group>0; 检测过 UNIT_TRANSFER_DETECTION_CHANCE_BASE 门) 失败 → sub_140FBADC0 搜护航客户 (CONVOY_DETECTION_CHANCE_BASE 门); 检测进度都是 +128 |
| 4 | CONVOY_ESCORT | sub_140FBBF00 | 扫区域→省→省 +368/+380 客户在场表: 客户 × tf+1856 目标舰型 × mission+16 国别匹配, 敌我强度比择优 → **sub_140BB85D0 接敌** |
| 5 | MINES_PLANTING | 内联 | 有海权国 ∧ +212 区域数>0: 布雷量 = NAVAL_MINES_PLANTING_SPEED_MULT × sub_140D6F120(tf); 确定性 RNG (种子=小时) 遍历 +200 区域, sub_141003F50 海权优势方==我 → × (NAVAL_DOMINANCE_MINES_PLANTING_BONUS+1e5)/1e5; 查现存上限 NAVAL_MINES_IN_REGION_MAX → sub_140E9F1D0 布雷 |
| 6 | MINES_SWEEPING | sub_140FB8840 | 对称: NAVAL_MINES_SWEEPING_SPEED_MULT × sub_140D6F1F0(tf); 海权加成 NAVAL_DOMINANCE_MINES_SWEEPING_BONUS; sub_140E9F1D0 负量扫除 |
| 7 | TRAINING | sub_140FB97C0 | 门: 训练区存在 ∧ (+69==0 ∨ sub_140D700A0); 在区 → +56 递增 (≥24 归零+日报); 逐舰训练推进 = TRAINING_EXPERIENCE_FACTOR × 燃料比缩放, XP/组织度/强度恢复 (0.15/0.6 经验加权) |
| 8 | reserve | 内联 | 未战斗 ∧ 无路径 (tf+524≤0) ∧ 有海权区域 → sub_140FB8FF0; 否则 sub_140D69BB0(tf,0) 母港省 → **+24 = 省 id** + sub_140FB95F0 回港令 |
| 9 | NAVAL_INVASION_SUPPORT | 内联 | +96 轰炸区在 +200 内 → 校验 (navalmission.cpp:4051 断言); 不在 → 清 +96; 无 +96: 订单引用 (+72) 有效 → sub_140FBDD60 从登陆订单战斗列表 (order+528/+540) 的省选轰炸区; 否则跟随舰队目标省 → +24 = 省 id |

侦查引擎 (PATROL, sub_140FBB0A0): ① 现目标失效/敌区不在我区 → sub_140FBA800
(mission,0) 清 (连带 +104/+128/+120 归零 + spotters 摘除); ② 无目标 → +112
侦查区扫省: 国别 + 接敌 + 可见 + 移动舰强度门 (SUB_DETECTION_CHANCE_BASE 族)
→ 检测值 (sub_140FB0830: 侦查速 = 1.0×(面侦−0.8×敌面侦)×0.001 + 1.0×(潜侦−0.8×敌潜侦)×0.001 + 速度差×(0.2/0.5 两档), ×(1+协同), 下限 0.01; 候选门 = (2.0×侦查速 + 0.5×侦测^1.5)/100, 潜艇另过 5% 门) + 隐蔽值 (sub_140FABB80) 加权择优 → 设目标;
③ 有目标同区: **+120 = 本小时侦查速度 → +128 += +120 (进度, 1e7 封顶;
再走 max(进度, 目标侧侦测值) 兜底步)**;
≥1e7 完全侦出 → +104 锁存 + notify 3 级 (全侦出掷 = rand×100 ≤ 侦查速, 速度
竞赛式); 过 LOW(1e6)/MEDIUM(7e6) 阈值 → notify 1/2 级;
首侦出可触发 pride-of-fleet 通报 (sub_140C1F9E0)。

状态机公共段: 前奏 = 区域变化 → **sub_140FBE3C0 区域范围重建** (舰队区域 ∩
省区间 [ppStart,ppEnd) ∩ 海权可达 → +200 数组 + S+104 桶/S+272 活表双注册
sub_140EAAD80) / IsInAssignedRegions(+48) 重算 sub_140FBE7F0 / +40 制空权重算
sub_140FBD630 / +32 雷达合计 (Σ区域国 cc+4344 贡献) / 在区清侦查目标 / 沉船
处置 (tf+840 逐舰强度≤0 且无改装线 → sub_140D77FF0); 尾步 = tf+1271
auto_reinforcement → sub_140FB8E00 补舰请求 + +60/+56 双计数器 24h 日报
(SNavalUnitActivityData)。CNavalMissionSetTypeCommand::Execute sub_141351C50:
锚定舰 sub_140FBA460 + 在航舰 sub_140D77E60 → **写 tf+1264 repair_last_mission
(在航任务类型暂存)**。


枚举表 (名→id 映射表 sub_140660F20 定案):

| id | 名 | id | 名 |
|---:|---|---:|---|
| 0 | MISSION_HOLD | 5 | MISSION_MINES_PLANTING |
| 1 | MISSION_PATROL | 6 | MISSION_MINES_SWEEPING |
| 2 | MISSION_STRIKE_FORCE | 7 | MISSION_TRAINING |
| 3 | MISSION_CONVOY_RAIDING | 8 | reserve (名表无此键, 舰队预备旗, §4.16 GUI 双证) |
| 4 | MISSION_CONVOY_ESCORT | 9 | MISSION_NAVAL_INVASION_SUPPORT |

A6 活体读锚 (-human_ai 现场可直接读):

| 锚 | 地址式 | 读法 | 证据档 |
|---|---|---|---|
| 特混舰队枚举容器 | tf_arr = rp(cc+632), tf_n = read_i32(cc+644) | CTaskForce\* 平表 (per-country; 元素 rp(tf_arr+8\*i)) | 定案 (§4.31.30 + sub_1406D35A0 双证) |
| 特混当前任务类型 | read_u32(tf+884) | EMissionType u32 (0..9) | 定案 (写点直读) |
| 特混内嵌任务对象 | tf+864 | CNavalMission 内嵌 (vt 0x14297F038); mission+8 = tf 回指 / mission+20 = 任务类型 (= tf+884) | 定案 |
| 任务 spotting 族 | ms = rp(tf+864) | spotting_speed fixed5@+120 / spotting_process i64@+128 (≠0 才写); idpair 门 = 任一 dword≠0: spotting_target@+136 / spotting_convoy_client@+144 / spotting_unit_transfer@+152 / strike_force_target@+160 (后三枚存档未见, writer 支持) | 定案 (savefull 对拍) |
| 在航 naval mission 平表 | M = rp(gs+1688); arr=rp(M+8); n=read_i32(M+20); S=rp(arr+8\*idx) | active CNavalMission\* 容器 (元素 vt 0x14297F038); ms = rp(S+272), ms_n = read_i32(S+284) | 定案 (§4.16.5) |
| per-region mission 桶 | S+104 {data, cap@112, c@116, alloc@120} | 276 桶×24B vector (区域维) | 定案 (§4.16.5) |
| 任务类型写点 (锚定) | sub_140FBA460(mission_obj=tf+864, new_type) | 写 \*(mission+20)=new_type; 门 = 新旧不等; type==2(strike) 另置旗 | 定案 |
| 任务类型写点 (在航) | sub_140D77E60(tf, new_type) | 在航变体: **写 tf+1264 repair_last_mission** (在航任务类型暂存) | 定案 |
| 命令级写门 | CNavalMissionSetTypeCommand IsValid: type ≤ 9 | 命令校验上界 (§4.33.11) | 定案 |

- AI 不置 8=reserve; 空闲特混回退 MISSION_TRAINING(7) (§4.34.13)。
- nationmission AI 侧任务派发链 (cGoal→优先级→逐特混命令投递) 见 §4.34.13。

#### 4.16.13 CSunkShipInfo — history (sunk_ship 族; gs 侧沉船总账)

> 本族 = **舰队战果记录**: gs 侧全量沉船总账 (§4.31.29) + 舰对象内嵌逐舰战史 (§4.16.3 `CShip.history` +2264 元素 +120) +
> 沉船战报条目 (§4.31.30 战史 GUI 消费)。三处同型共用 168B 结构。

| 项 | 值 |
|---|---|
| RTTI 名 | CSunkShipInfo |
| sizeof | 168B |
| vtable RVA | 0x142957DE8 |
| writer | 0X140C2E7D0 |
| loader | — |
| 挂载点 | gs+1424 (指针数组), cnt @gs+1436 |
| ctor | 0X140C2D6B0 |

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CSunkShipInfo | 不序列化 |  |
| +8 | MSVC SSO 32B (size@+24) | name | 空串也写 `""` |  |
| +40 | MSVC SSO 32B (size@+56) | killer_name | 空串也写 `""` | 引号 |
| +72 | uint32 | country | 恒写 |  |
| +76 | uint32 | killer_country | 恒写 | 国 idx → 引号 tag (BA5C20 直查无 >0 门) |
| +80 | CGameDate (24B 双 vtable) | date | 恒写 (无门 date3) | {vt1@+80, hours@+88, vt2@+96}; ctor 哨兵 43808760; writer ADEC0 收 a1+96 = &vt2; 形态通则见 §3.7a |
| +104 | CSubUnitDefinition* | definition | 恒写 | def 对象 |
| +112 | CSubUnitDefinition* | killer_definition | 恒写 | def 对象 → token idx@def+8 裸名 |
| +120 | uint32 | level | 恒写 |  |
| +124 | uint32 | equipment_variant.type | 双非零才写 (对) | id 对 {type, id} |
| +128 | uint32 | equipment_variant.id | 双非零才写 (对) | id 对 |
| +132 | uint32 | air_wing.type | 双非零才写 (对) | id 对 {type, id} |
| +136 | uint32 | air_wing.id | 双非零才写 (对) | id 对 |
| +144 | CProvince* | location | ptr≠0 (实恒写) | → u32@prov+164 |
| +152 | uint32 | battle.type | 恒写 (0/0 也写) | id 对 {type, id} |
| +156 | uint32 | battle.id |  | id 对之 id (联合门同 +152) |
| +160 | uint8 | convoy | 恒写 | 写 yes/no |
| +161 | uint8 | assist | 仅真写 yes | 定名 token 13552 = assist; writer `if(*(a1+161)) AE850(0x34F0, 1)`; 提取器不收 |

#### 4.16.14 sunk_convoys_history (gs 侧运输船损失月账)

| 项 | 值 |
|---|---|
| RTTI 名 | — |
| sizeof | — |
| vtable RVA | — |
| writer | 0X140EB39E0 |
| loader | — |
| 挂载点 | gs+1448 (指针数组), cnt @gs+1460 |

元素主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | month | 恒写 |  |
| +12 | uint32 | convoys | 恒写 |  |
| +16 | tag_id | killer_country | 恒写 | tag 引号 |
| +20 | tag_id | owner | 恒写 | tag 引号 |

> **本域 GUI 类布局**: 见 4.31.29 / 4.31.30 / 4.31.42 / 4.31.44。

> **本域 GUI 类布局**: 见 §4.31.23。

#### 4.16.12a CNavalMission 运行时字段全表 (基 = tf+864; ctor sub_140FA9890 / loader sub_140FB9B30 / writer 0X140FBEA80 三面互证)

| 偏移 | 类型 | 语义 | 写门 | 置信 |
|---|---|---|---|---|
| +8 | CTaskForce* | 宿主回指 | 不序列化 | 定案 |
| +16 | u32 | 拥有国 handle type 槽 (拷自 tf+472 refid type 段; 解析只读 +16) | 不序列化 | 定案 |
| +20 | u32 | EMissionType (键 11450 mission) | 恒写 | 定案 |
| +24 | u32 | 移动目标省 id (回港/入侵跟随/区域漫游; sub_140FB95F0 发 CNavalMissionMoveCommand 后清 0) | 键 333 move ≠0 写 | 定案 |
| +32 | i64 fixed5 | 雷达覆盖合计 (Σ区域雷达贡献, 钳 0..1e5) | 键 12237 radar >0 写 | 定案 |
| +40 | i64 fixed5 | 制空权值 (区域加权平均, sub_140FBD630) | 键 12335 air_superiority >0 写 | 定案 |
| +48 | u8 | IsInAssignedRegions (sub_140FBE7F0 每小时重算) | 键 12468 is_in_regions ≠0 写 | 定案 |
| +49 | u8 | 分舰维修旗 (= tf+913; 置位时 HOLD/破交/护航拒接敌) | 不序列化 | 定案 |
| +52 | u32 | **接敌规则索引 navy_engagement_rule** (0=不接敌; ctor 默认 2=medium; 接敌门统一 AGGRESSION_SETTINGS_VALUES[+52] ≤0 拒) | 键 13358 恒写 | 定案 |
| +56 | u32 | TRAINING 小时计数 (在训练区递增, ≥24 归零+日报; SetType 清 0) | 键 12656 hours >0 写 | 定案 |
| +60 | u32 | hours_in_mission (非训练型活跃计数, ≥24 归零+日报) | 键 17190 >0 写 | 定案 |
| +64 | i64 (低 32 位) | num_convoys_in_regions (sub_140FBE250 并行重算 Σ; 高 32 位运行时未用) | 键 15540 >0 写 | 定案 |
| +68 | u8 | 本小时活跃旗 (switch 前置 1; 无敌/无区清 0; 门控 24h 日报) | 不序列化 | 定案 |
| +69 | u8 | stop_training_at_max_xp (= tf+933) | 键 19076 ≠0 写 | 定案 |
| +72 | SOrderInstanceRef 内嵌 | group_to_escort 订单引用 (空引用判定 sub_1410381D0 — **非活订单时才序列化**, 活订单由订单系统自持; case 9 消费) | 键 15484 | 定案 |
| +96 | CStrategicRegion* | invasion bombardment region (sub_140FBA6B0 设置; case 9 消费/清零) | 键 15483 → region+88 id | 定案 |
| +104 | u8 | already_spotted (完全侦出锁存, 换目标复位) | 键 15283 ≠0 写 | 定案 |
| +108 | u32 | hours_in_spotting_region (PATROL 在侦查区递增, 换区/失效清 0) | 键 15290 >0 写 | 定案 |
| +112 | CStrategicRegion* | spotting_region (sub_140FBA7E0 设置连带 +108 清 0) | 键 15285 → region+88 id | 定案 |
| +120 | i64 fixed5 | spotting_speed (本小时侦查速度 sub_140FB0830) | 键 15300 ≠0 写 | 定案 |
| +128 | i64 | spotting_process (检测进度累积, 1e7 封顶 = 完全侦出; 目标/港/型切换清 0) | 键 15280 ≠0 写 | 定案 |
| +136 | refid 8B | spotting_target (敌 TF) | 键 15277 | 定案 |
| +144 | refid 8B | spotting_convoy_client (破交目标护航客户, sub_140FBA990) | 键 15489 | 定案 |
| +152 | refid 8B | spotting_unit_transfer (破交目标海运运输, sub_140FBAB00) | 键 15490 | 定案 |
| +160 | refid 8B | strike_force_target (STRIKE 追击目标) | 键 15281 | 定案 |
| +168 | CStrategicRegion* | accessible_regions_range 锚区 | 键 15292 (⚠ 裸指针 i64 发射/loader 原样回读 — 跨会话陈旧指针, 首小时区域比对自愈) | 定案 |
| +176 | 容器 {d, cap@+184, c@+188} | accessible_regions_in_fleet per 区域 bool 数组 | 键 15293 | 定案 |
| +200 | 容器 {d, cap@+208, c@+212} | accessible_regions (舰队区域 ∩ 省区间 ∩ 可达 — 状态机「任务区域」唯一来源) | 键 15299 逐 region id | 定案 |
| +224 | u32 | hours_to_wait_for_base_check (sub_140FB7630 每小时减 1) | 键 15581 ≠0 写 | 定案 |
| +232 | CStrategicRegion* | convoy_spotting_region (护航客户路线选区 sub_140FBD850 / 运输选区 sub_140FBDAB0) | 键 15491 → region+88 id | 定案 |
| +240 | CFleet* | _pFleet 缓存 (`_RegionRange._pFleet == _pNavy->GetFleet()` 断言族) | 不序列化 | 定案 |
| +248 | u32 | ppStart (省区间下界) | 不序列化 | 定案 |
| +252 | u32 | ppEnd (省区间上界, 开区间) | 不序列化 | 定案 |

邻近结构 (F6 重钉, 定案): province+272 {data, count@+284} 与 province+296
{data, count@+308} = **省在场单位双表（陆军/type13; 「TF 表」判读废）**
(破交扫描消费, 经元素 +760 转 transfer); **CUnit+760** = CNavalUnitTransfer*
在途运输回指 (transfer 侧读 +92 is_returning/+96 cooldown/+144
CConvoySubscriber.allocated); fleet+216 = 舰队命令目标省 CProvince*; fleet+136 = 入侵
支援相关计数 (SetType 进出 type 9 清 0) (定案)。

#### 4.16.15 海运跨海输送生命周期 (CNavalUnitTransfer)

**下令四入口全收敛下单核 sub_140EA9720** (定案): ① CTransportUnitCommand →
内嵌 CUnitNavalMoveAction::Execute sub_1412351F0; ② 入侵订单 → og 索引器
(§4.24.14 type3) → CPendingStratNavyTransfer 工厂 sub_1414D5A70 → Execute 壳
sub_1414C7C80 → sub_140EA9660; ③ 卡死兜底 sub_140DF7A40; ④ 军位置联动。
下单核先验护航充足 (空闲+订单已分得 ≥ 单位数, 不足不建) → malloc 0xB0 建
transfer。

七段生命周期 (定案):

| 段 | 函数 | 语义 |
|---|---|---|
| 配属 | ctor sub_140E256E0 | 即以 CConvoySubscriber 订阅 (优先级 define: 入侵 dword_143334024 / 转移 1433340B4, 静态标签 2/1), 需求恒 = 单位数 (sub_141022950, §4.16.7b 通道) |
| 装船 | sub_140E286D0 / sub_140E25C60 | 给每师发海路省序移动令 (sub_140BF9A40) + 写 **CUnit+760 回指**; 类型门 = unit+8 ∈ {0,13}, 入侵只收 0 |
| 航渡 | phase9 → sub_140EA79F0 → sub_140EA76B0 逐国扫 S+304 | 谓词 sub_140E274C0 (战斗中/目标仍有效/有活单位) → **sub_140E263B0 每小时推进** — 单位沿路径省自走, 失路 sub_140E28950 重寻路, force_revalidate(+94) 每 tick 清 |
| 卸载 | 到达目的地省 | 移出 (unit+760=0 + CancelMovement sub_140BFB4A0 + swap-remove + 退超额船); 师本就在目的省, 无额外落位 |
| 落地 | （普通转移卸载即完成） | 入侵到达段触发**浮动港建造**（落到登岸省控制方名下）+ **on_naval_invasion** 事件 + AI 钩; 冷却 (+96) 由海战火交换设入, 无战斗时每小时递减 |
| 取消 | sub_140E28820 | 单位删除/取消移动/换队三路摘除; 全队空或目标失效 (sub_140700570 目标省控制方敌对, 与 invasion_group 同源) → 下一 tick sub_140E28790 全退护航 + 删除 |

新钉: CStrategicNavy+16 = owner tag u32; CPendingStratNavyTransfer 56B 全布局
(§4.00 待命指令族补全)。is_returning 运行期无置 1 写点 (负发现)。
