

### 4.16 海军族 (CStrategicNavyManager → CStrategicNavy → 基地/特混舰队/舰船 + 战史与战果记录)

书内「CNavy」定名 **CStrategicNavy** (vtable 0X2973260, RTTI 双证); 管理器定名
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
| +20 | uint32 | per 容器计数 |  |
| +21..+31 | — | = per 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (24B 形状) RH 桶数组 | **naval supply hub 全局 RH 表** {结构基@+32, entries@+40 (24B 元 {hash@0, dist@+4, payload, ptr@+16}), count@+48, mask@+52, extra u8@+56, maxload f32@+60=0.9; 清理/扩桶 sub_140EA21B0/sub_140EAE2C0}  |  |
| +48 | uint32 | world_bases — **定名: = supply hub RH 表 count** (586 叶互证) |  |
| +49..+59 | — | = RH 表尾 {mask@+52, extra@+56}  |  |
| +60 | float (uint32 位型) | tuning_factor — **定名: = RH max_load_factor = 0.9** (0x3F666666 位型, 与主文件 §3.2 RH 通用尾同构) | IEEE754 位型读 |

#### 4.16.2 CTaskForce (writer 0X140D7AFA0 / loader 0X140D75470)

writer 0X140D7AFA0 的 a1 = **元素+16 视角**; 运行时偏移 = writer 偏移 + 16
(tf = ser + 16)。⚠ 直接按 writer 偏移读运行时内存会错位读进垃圾。
⚠ **双表检索纪律**: 本表用 ser 视角、全键表用 tf 视角, 同一数字两表指不同字段
(ser+1188 = repair_parent id, tf+1188 = repair_child 计数; 1188..1280 窗口 14 对全撞)
—— 按偏移字面 grep 全书必须带视角读, 词边界过滤救不了同号碰撞。

writer↔tf 偏移对照 (writer 体直读 43 偏移全覆盖; 行序 = ser 升序):

| 键 (token) | writer 偏移 (ser) | 运行时偏移 (tf) | 类型 | 写门 | 备注 |
|---|---|---|---|---|---|
| ship (10400) | +824 | tf+840 | CShip* 容器数据 (8B 指针) | c>0 | 元素 ADEC0 多态 |
| ship (10400) | +836 | tf+852 | uint32 | c>0 | ship 容器计数 |
| mission (11450) | +848 | tf+864 | CNavalMission 内嵌 | 恒写 | 存档块名 units; 布局 §4.16.12a |
| repair_mode (13593) | +1108 | tf+1124 | uint32 | 恒写 | |
| underway_replenishment (16427) | +1112 | tf+1128 | uint8 | 恒写 | 开关语义见全键表行 |
| convoys (12386) | +1120 | tf+1136 | CConvoySubscriber 内嵌 | underway_replenishment≠0 | |
| repair_child (13594) | +1160 | tf+1176 | idpair 容器数据 (8B/元) | c 循环 | |
| repair_child (13594) | +1172 | tf+1188 | uint32 | c 循环 | 容器计数; loader push 重建 |
| repair_parent (13595) | +1184 | tf+1200 | 行内 idpair — type | 任一≠0 且有效 | |
| repair_parent (13595) | +1188 | tf+1204 | 行内 idpair — id | 任一≠0 且有效 | |
| detached_activity (15225) | +1192 | tf+1208 | uint32 枚举 1..4 | ∈1..4 (0 不写) | |
| repair_target (13597) | +1200 | tf+1216 | 引用对象指针 (类未名) | ptr≠0 | 发射 u32@obj+164 |
| refit_equipment_variant (14663) | +1208 | tf+1224 | 引用对象指针 (类未名) | ptr≠0 | 发射 idpair@obj+8 |
| refit_to_variant_after_repair (14664) | +1216 | tf+1232 | 引用对象指针 (类未名) | ptr≠0 | 发射 idpair@obj+8 |
| industrial_manufacturer (19160) | +1224 | tf+1240 | 行内 idpair — type | 任一≠0 且有效 | |
| industrial_manufacturer (19160) | +1228 | tf+1244 | 行内 idpair — id | 任一≠0 且有效 | |
| merge_with_after_repair (14665) | +1232 | tf+1248 | 行内 idpair — type | 任一≠0 | |
| merge_with_after_repair (14665) | +1236 | tf+1252 | 行内 idpair — id | 任一≠0 | |
| hours_waited_for_repairs (15504) | +1240 | tf+1256 | uint32 | >0 | |
| sortie_efficiency (12970) | +1244 | tf+1260 | uint32 | 恒写 | 载机姿态索引 |
| repair_last_mission (13598) | +1248 | tf+1264 | uint32 | ≠0 | |
| repair_split (13596) | +1252 | tf+1268 | uint8 | ≠0 | |
| merge_split (13996) | +1253 | tf+1269 | uint8 | ≠0 | |
| is_sea_locked (13998) | +1254 | tf+1270 | uint8 | ≠0 | |
| auto_reinforcement (15169) | +1255 | tf+1271 | uint8 | ≠0 | |
| fuel (12003) | +1256 | tf+1272 | i64 fixed5 | ≠0 | per-hour scratch |
| requested (15132) | +1264 | tf+1280 | i64 fixed5 | ≠0 | |
| icon (181) | +1272 | tf+1288 | uint32 | 恒写 | |
| use_fleet_color (15195) | +1276 | tf+1292 | uint8 | 恒写 | 兼任 color (86) 发射门 |
| color (86) | +1280 | tf+1296 | CColor 内嵌 | !use_fleet_color | |
| ai_taskforce_composition (17899) | +1312 | tf+1328 | CTaskForceCompositionRequirements 内嵌 224B | 恒写 | 布局见全键表行 |
| spotters (15275) | +1536 | tf+1552 | idpair 容器数据 (8B/元) | c 循环 | |
| spotters (15275) | +1548 | tf+1564 | uint32 | c 循环 | 容器计数 |
| strike_forces_on_ship (15282) | +1560 | tf+1576 | idpair 容器数据 (8B/元) | c 循环 | |
| strike_forces_on_ship (15282) | +1572 | tf+1588 | uint32 | c 循环 | 容器计数 |
| enemy_mines_factor (19887) | +1600 | tf+1616 | i64 fixed5 | signed>0 | |
| next_attempt_to_path_to_parent (15620) | +1800 | tf+1816 | uint32 | ≠0 | |
| last_delay_to_path_to_parent (15621) | +1804 | tf+1820 | uint32 | ≠1 | |
| hours_to_wait_for_repair_check (15580) | +1808 | tf+1824 | uint32 | >0 | |
| naval_headquarter (10193) | +1816 | tf+1832 | 引用对象指针 (容器元, 类未名) | c>0 | 元素发射 idpair@obj+8 |
| naval_headquarter (10193) | +1828 | tf+1844 | uint32 | c>0 | 容器计数 |
| target_ship_types (10256) | +1840 | tf+1856 | 32B MSVC 串 — 容器数据 | c>0 | |
| target_ship_types (10256) | +1852 | tf+1868 | uint32 | c>0 | 容器计数 |

容器形状 (定案): 类内 PDX 容器一律 24B {data@0, cap u32@+8, count u32@+12, 存根@+16}
—— push 助手 sub_1401CBF60 读 count@+12 / cap@+8, 扩容 ×1.5 经存根对象, 容器构造
sub_14011DF40; 上表 6 个容器计数槽 (ser+836/+1172/+1548/+1572/+1828/+1852) = 各容器
data 基 +12, 全部吻合。

CTaskForce 全键表 (writer 0X140D7AFA0, a1 = 元素+16, 首调
CUnit::Serialize 0X140C06540; 运行时偏移 tf = writer+16; **行序 = writer
发射序落盘契约, 非偏移升序**):

| 键 (token) | tf 偏移 | 类型 | 门 | 备注 |
|---|---|---|---|---|
| ship (10400) | tf+840 | 8B 指针 → CShip (ADEC0 多态) — 容器数据 | c>0 | **GUI: MilitaryOverviewItem 命中** (target = tf raw+40 idpair; sub_1402A6F30=*(tf+24) 灌入) |
| ship (10400) | tf+852 | ship 容器计数 | c>0 | |
| mission (11450) | tf+864 | 代理对象 | 恒写 | |
| repair_mode (13593) | tf+1124 | u32 | 恒写 | ctor 默认 3; tooltip 档位域 = **0..3 四档** (≥4 显示按 0; 运行期值 5 不入档位 UI 环 — §4.16 小时处理 ∉{0,5} 合并门不矛盾, 5 = 特殊态); 枚举语义未定 |
| underway_replenishment (16427) | tf+1128 | u8 | 恒写  开关 setter (tf 基): 关 → 退订 sub_141022A70(tf+1136); 开 → Init(tf+1136, country, 128, UNDERWAY_REPLENISHMENT_PRIORITY); 小时维持 sub_140D69090: tf+1128 ∧ ¬sub_1406DFDA0(country+1731 旗) → 自动关; 需求 = ceil(24×IN_COMBAT_FUEL_COST(2.0)×(FUEL_COST_MULT×tf 小时燃料消耗/1e5)/1e5×UNDERWAY_REPLENISHMENT_CONVOY_COST_PER_FUEL(0.28)×(1+modifier(637))) — 按日燃料消耗折算; **收益仅射程** (sub_140D66F90: 射程比 × (0.4×(1+modifier(636)))), 不补燃料/组织度||
| convoys (12386) | tf+1136 | CConvoySubscriber 内嵌 | underway_replenishment≠0 | |
| — (15171 = set_task_force_composition_requirements 命令名, 非存档键) | tf+1336 | **CTaskForceComposition 内嵌 104B** (RTTI 实名; vtable 0x142973300; 布局见后表) | 非独立键 — 由 tf+1328 对象 writer 0x14198C060 经子键 15166 requirements 发出 | 定案 |
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
| merge_split (13996) | tf+1269 | u8 | ≠0 | 运行时置位点 dump 无静态写点 (待裁) |
| is_sea_locked (13998) | tf+1270 | u8 | ≠0 | |
| auto_reinforcement (15169) | tf+1271 | u8 | ≠0 | |
| fuel (12003) | tf+1272 | i64 fixed5 | ≠0 | **本小时实收** (per-hour scratch): 每小时 tick sub_140D68B90 先清 0, 再由优先级分发 sub_140D64740 (tf+1272 += grant) 灌入; 载入值存活至首整点即被覆盖; loader ser+1256 **落字段** |
| requested (15132) | tf+1280 | i64 fixed5 | ≠0 | 每小时 sub_140C35280 重算: MISSION_COST×(FUEL_COST_MULT×Σ舰用量缓存/1e5)/1e5 (分派表见下); 上游钳制 = tf+64 补给比 × MAX_FUEL_FLOW_MULT (无补给 ⇒ 少要燃料); 读取器 sub_140D6EAC0; loader ser+1264 **落字段** |
| icon (181) | tf+1288 | u32 | 恒写 | ctor 默认 dword_1433366B4; 亦为 GetInsigniaIndexForRole 角色表查表兜底默认 (§4.16.2a) |
| use_fleet_color (15195) | tf+1292 | u8 | 恒写 | ctor 默认 1 (解释 color 键常态缺省) |
| color (86) | tf+1296 | 对象 (CColor 族) | !use_fleet_color | |
| ai_taskforce_composition (17899) | tf+1328 | **CTaskForceCompositionRequirements 内嵌 224B** (RTTI 实名; vtable 0x142A223C8; CPersistent 族; writer 0x14198C060 / reader 0x14198BF60): +8 = requirements 编成 (CTaskForceComposition@tf+1336, 键 15166) / +112 = fulfillment 编成 (@tf+1440, 键 15167) / +216 = ai_taskforce_composition token (@tf+1544, 19479=undefined 不写) | 恒写 (整个对象写在 17899 键下) | 定案 |
| spotters (15275) | tf+1552 | 8B idpair {type@0, id@+4} — 容器数据 | c 循环 | |
| spotters (15275) | tf+1564 | spotters 容器计数 | c 循环 | |
| strike_forces_on_ship (15282) | tf+1576 | 8B idpair {type@0, id@+4} — 容器数据 | c 循环 | |
| strike_forces_on_ship (15282) | tf+1588 | strike_forces_on_ship 容器计数 | c 循环 | |
| enemy_mines_factor (19887) | tf+1616 | i64 fixed5 | signed>0 | 全二进制唯一发射点, 在 spotters 之后 task_force 块尾 (探针 NOR 9025→0.09025 / ENG 539→0.00539) |
| next_attempt_to_path_to_parent (15620) | tf+1816 | u32 | ≠0 | reinforcing 回队寻路重试倒计时 (小时; 失败重置 = 步长, >1 每小时 −1) |
| last_delay_to_path_to_parent (15621) | tf+1820 | u32 | ≠1 | ctor 默认 1; 运行时 = 退避步长 min(2×旧, 24) 封顶 (sub_140D7A180) |
| hours_to_wait_for_repair_check (15580) | tf+1824 | u32 | signed>0 | ctor 默认 0 |
| **naval_headquarter (10193)** | tf+1832 | 8B 指针 → idpair@obj+8 — 容器数据 | c>0 | |
| **naval_headquarter (10193)** | tf+1844 | naval_headquarter 容器计数 | c>0 | |
| target_ship_types (10256) | tf+1856 | 32B MSVC 串 — 容器数据 | c>0 | 元素 = 32B MSVC 串非 idpair (三档探针定案) |
| target_ship_types (10256) | tf+1868 | target_ship_types 容器计数 | c>0 | |

CTaskForce 运行时字段 (不序列化; 燃料结算链定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +312 | CSubUnitDefinition* | 合成统计对象 (0x678B; ctor 0x141018D00); **+712 = statId 69 STAT_COMMON_FUEL_CONSUMPTION = Σ舰每小时燃料用量缓存**; vtable[57] (0x140BFBFB0) 读取; 聚合核 sub_140B9AD70 (与师统计同框架, 入口 sub_140C86CC0 传 tf+840 ships 容器) |
| +512 | u32 数组 | 移动路径省份 {data@+512, count@+524}; +524 > 0 = 在航未达 (HOLD/reserve 在航成本门) |
| +933 | uint8 | stop_training_at_max_xp (见 mission 补录表) |

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
detached_activity 状态设置器 = sub_140D731A0 (taskforce.cpp:6079 断言): 联写 tf+1208/1216/1224/1240; 迁移写点 = 1 repairing = 分舰链 sub_140D72580(activity=1) (调用者 sub_140D77FF0 沉船总入口/sub_140D77900; sub_140DA0E40 属铁路炮域非 TF) / 2 moving_to_refit sub_140D72F10 / 3 refitting sub_140D78F10 (分裂) + sub_140D705F0 在港完成块 (上改装线 sub_140C3D720, repair_parent 有效则 sub_140D76B00 转回队 (FinishRepair: SetDetachedActivity(4) + 即跑状态机 sub_140D79900)) / 4 reinforcing sub_140FB6C70 + taskforce 侧写点 sub_140D76B00 直写 / sub_140D79DE0 经分舰链 (…,4,…) 拆队 / sub_140D72000 链内挂父 / 0 完结多处。**状态迁移无燃料门** (唯一交集 = 修理/改装期在港自然落 ON_BASE_FUEL_COST 0.0)。

**detached_activity 的 GUI 消费 (CNavyTheaterFleetRowItem, navytheaterfleetrowitem.cpp 0x141E15E20)**: 分舰队汇总入容器 = 逐 CTaskForce 按 `tf+1200 || tf+1204` (repair_parent 非空) ∧ resolve 有效 → 以修理父 tf 为值、父自 idpair 为键二分有序插入 **320B 行容器** (行 = 父 CTaskForce\*@+0 + 三个 104B 槽 @+8/+112/+216); 子 tf 按其 detached_activity 落列承载 tf+1440 fulfillment 编成 (CTaskForceComposition 拷贝, sub_14198A9E0): **1 repairing → +8 / 2 moving_to_refit 与 3 refitting → +112 / 4 reinforcing → +216 / 0 → 不落槽并触发断言 "A task force is reporting status NotDetached while having a RepairParent"**; 汇总船数 += tf+852 容器计数 (sub_140D6EEB0 = tf+840 一行直证)。

**CTaskForceComposition** (RTTI 实名; vtable 0x142973300; sizeof 104B; CPersistent 族; writer 0x14198B970 / reader 0x14198B630; ctor 0x14198A7A0):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | vtable | — | 槽 0..8; [6]/[7] CFG 空桩 |
| +8 | 匿名结构 (NNB 形状) 向量 24B | **A 紧凑映射 = 唯一序列化源** | 元素 16B (见下表); 按 {sub_unit, role} 二分有序, 同键插入 amount 累加 |
| +32 | 匿名结构 (NNB 形状) 向量 24B | B amounts 读入暂存 | 键 amount (417) |
| +56 | 匿名结构 (NNB 形状) 向量 24B | C sub_units 读入暂存 | 键 sub_units (12176), 兼容旧名 archetype (12103) |
| +80 | 匿名结构 (NNB 形状) 向量 24B | D roles 读入暂存 | 键 roles (14278) |

A 容器元素 (16B; 有序键 = {sub_unit, role}):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | u32 | sub_unit 舰型定义 token (writer 以 token 名发射) |
| 元素+4 | u32 | role 角色 token (0 = any 通配) |
| 元素+8 | u32 | role2 严格角色匹配旗 (默认 0xFFFFFFFF; 不序列化): 需求形 {role=X, role2=-1} = 宽松 (design role==X 或泛型舰 role==0 均满足) / {role=0, role2=X} = 严格 (恰配 design role_icon_index==X, 泛型不计); fulfillment 侧恒 -1 无人读 |
| 元素+12 | u32 | amount 需求舰数 (同键插入时累加) |

> 收尾钩子 = 虚槽 [8] 0x14198B1A0 (load wrapper 读完后调): 三组长度不齐时按 taskforcecomposition.cpp:56 断言截到三者最小值, 逐 B[i] 取 {C[i] sub_unit, D[i] role} 在 A 二分查/插后**释放 B/C/D** — 故运行态常态 A 有值、B/C/D 已空, 读档读键期间三组才并存。
> 命令链: CSetTaskForceCompositionRequirementsCommand (vtable 0x1429AFF20; Execute 0x1413569C0) 载荷 {task_force idpair@+40, requirements 编成@+48} — Execute 只把该编成四容器整体拷进 tf+1336 (sub_140D642E0), 不触 +112/+216。
> 满足度缺口 = requirements − fulfillment 逐元扣减 (**0x14198AD20**, 纯扣减循环无断言): 需求元 role2==-1 时 fulfillment 的 role==0 泛型舰计入 (宽松), role2!=-1 时须恰等 (严格); fulfillment 元 role2 全程无人读。需求侧双 builder: 需求表条目带旗 → {role=0, role2=X} (0x14198B790), 无旗 → {role=X, role2=-1} (0x14198B750); 条目源 = 编成编辑器需求模型 robin-hood 表 (24B 条 {amount@+8, role@+12, role2@+16 带旗}, 命令路径 0x141354720)。
> **缺口×可用交集 = 0x14198BC80** (taskforcecompositionrequirements.cpp; 断言 :102 "AvailableIter->first == DeficitIter->first" 实属本函, 旧挂 0x14198AD20 修正): 先 0x14198AD20 算缺口表 (tf+1328 对象 +8 需求 / +112 满足), 再与可用编成**有序键并归** (键序 = {sub_unit, role}, 匹配另校 role2) → 结果 = min(可用.amount, 缺口.amount) 逐键入 a2; **可用侧 role==0 (any 通配) 条目不入匹配, 改入通配池** 在可用不足/同 sub_unit 缺口上回补 (回补量 = min(池余, 缺口.amount))。两调用点: GUI 侧 0x141E67BF0 簇 (sub_140FB3380 从舰船构造可用编成, 逐选中 TF 调本函) / navalmission 侧逐 TF 以首 TF fulfillment 为可用, 门 = tf+884 != 8 (非 reserve)。

mission 块 (units; 存档块名, 非 RTTI 类名) 补录:

| 键 (token) | 偏移 | 类型 | 写门 | writer |
|---|---|---|---|---|
| already_spotted (0x3BB3) | ms+104 (tf+968) | u8 | ≠0 写 yes | 0X140FBEA80 |
| stop_training_at_max_xp (19076) | ms+69 (tf+933) | u8 | ≠0 写 | sub_140FB9B30; 仅 type==7 TRAINING 时 sub_140FBA460 从命令载荷写; 作用 = 训练任务燃料成本混合门 (0.15/0.6 经验加权) |

#### 4.16.2a 海军特遣舰队徽记索引查表 (taskforcebuilder.cpp; 1 函 = sub_141233850, 定案)

role < 0 → :277 断言 "!\"Unexpected role index less than zero\"" (B52/闩 byte_14333DE16) → 默认; 0 ≤ role < dword_1433398FC → *(u32*)(qword_1433398F0 + 4×role) (新全局 = 角色→徽记索引 u32 数组 / 表长); role ≥ 表长 → CLog 65540 "Role index %u has no insignia index defined\n" (:282) → 默认; 默认 = dword_1433366B4 (与 tf+1288 icon ctor 默认同源)。角色索引的脚本填充源未查。

#### 4.16.3 CShip (writer 0X140C3E6C0 = vtable[2]; reader 0x140C3C5A0 = vtable[4])

| 项 | 值 |
|---|---|
| RTTI 名 | CShip |
| sizeof | **2360 (0x938)** (CTaskForce loader case 10400 malloc(0x938) 直证 — 原「≥2360」封口, +2360..尾空白不存在) |
| vtable RVA | 0X2957F28 (主表); 第二表 0x2957F90 = +24 IOfficerHolder 子对象 |
| writer | 0X140C3E6C0 (= vtable slot2; a1 = sh 直基; 首调基类 0X142220340) |
| reader | 0x140C3C5A0 (= vtable slot4; serfam 行 840 + loader 对新舰调 slot3 wrapper 双证) |
| ctor / dtor | 0x140C2FEA0 / 0x140C30380 |
| 挂载点 | CTaskForce ship 容器 (tf+840/tf+852) |

**+128..+1783 = 内嵌 CSubUnitDefinition 克隆 1656B** (copy ctor 自 null def; reader 键 12259 经 sub_140B961B0 重克隆) — 原空白 +236..+839 与 +864..+1575 全部是克隆体内部, **按 §4.18.19 布局 −128 映射即全解** (活体 1524 艘 vtable 全中: sprite "heavy_cruiser"@sh+232 (def+104+128)、主统计数组 **statId=(off−288)/8** (ship 基址; def 克隆体映射 = off−288−128; 统计重算真身 0x140C3D090 惩罚直写 sh+288+8×statId + 内部自洽 (org/strength 钳位读 sh+768/+776 = statId 60/61 MAX_ORG/MAX_STRENGTH 仅 288 基址自洽, 416 基址映 44/45 语义不通))、reliability = statId65 = 0.8、critical_parts cap4、map_icon=3(ship)@sh+1544 (def+1416)、DB 母本索引=72@sh+1548 (def+1420)); 克隆体后 +1784 = strength。
⚠ 原「舰统计重算 sub_140C21570」误挂 — 该函数触 +4168, 2360B 对象物理不可能, 系他类函数; **真身 = 0x140C3D090** (281 行, ship.cpp; 全机制见 §4.16.21); 原「+856 CModifier 树」活体全零且 getter 不读 (待裁); GUI「+1576 旗」定名 = 克隆 type 位域 capital_ship 0x40 位。

loader 兼容读入键 (writer 均不发射, 8 个新增): air_wings (12213) → +1840 航母机库注册 (strategicair.cpp:5946 断言) / start_experience_factor (13548) → +1824 / pride_of_the_fleet (15002) → +2068 / ordered_name (15501) → +2112 / unordered_name (15502) → +2116 / name (27) → +2080 旧名缓冲 / division_name (14596) 旧 ship_name 键 / refitting (15228) 容忍跳过。held_officer 键名 = 10660 定案; 另有 case 19176 → sub_1413EAA60(a1+2120) (officer 对象操作, 不落值域)。

CShip 键表 (writer 0X140C3E6C0 直证清单; **行序 = writer 发射序落盘契约,
非偏移升序**):

| 键 (token) | sh 偏移 | 类型 | 门 | 备注 |
|---|---|---|---|---|
| definition (12259) | +136 | u32 (ADCE0 枚举式) | 恒写 | |
| organisation (11979) | +1792 | i64 fixed5 | 恒写 | |
| strength (10406) | +1784 | i64 fixed5 | 恒写 | |
| experience (11930) | +1800 | i64 fixed5 | ≠0 | 本级进度 (sub_140C31840 得经验, 钳 ≤ +1808 下级所需); +2048 = 经验脏旗  |
| sunk_convoys (12418) | +60 | u32 | ≠0 | |
| equipment (12110) | +64 | 代理 (idpair 族) | 恒写 | **GUI: ShipStats 装备定义行** (+64 池 → 池+1008 def 可见门; sub_141BEF820) |
| ship_name (15500) | ptr@+2072 | 对象 (名称块; vtable+8 分发在 officer 之前) | 恒写 | **GUI: 舰名/删除确认文案** (glue+7928 sub_141BECA70 → CONFIRMDELETESHIP / DISBAND_PRIDE_OF_FLEET_COST; 投 CDeleteShipCommand {+40 舰, +48 特混舰队}) |
| government_in_exile_tag (15034) | +2052 | tag (sub_140BB4E70→串) | >0 | **GUI: 流亡/可见谓词** (+1576 旗 + +64 池旗 + define 15 门; sub_140C33A50) |
| refit_production_line (15234) | +1848 | 行内 idpair — type | 任一≠0 且有效 | 在改判定谓词 = sub_140C3B130; 上线写 = sub_140E60830 (遍历国家+3944 改装生产线容器) |
| refit_production_line (15234) | +1852 | 行内 idpair — id | 任一≠0 且有效 | |
| max_manpower (10608) | +2060 | u32 | 恒写 | |
| manpower (10300) | +2056 | u32 | 恒写 | |
| last_sunk_ship_info_read (15624) | +56 | u32 | ≠0 | |
| (officer 内联对象, 无键名) | +2120 | 对象 (vtable+8 自序列化; ≈144B 跨 +2120..+2263; seed@+2120+32, 追加军官向量 {d@+2232, c@+2244} = obj+112/+124) | 恒写; **对象定名 = CHeldOfficer 内联** (CShip ctor vtable写入 + IOfficerHolder vtable[1]=0X140C30D10 返 ship+2120 双证) — **舰长数据源定案**: 舰长 = 本对象, 非 +2232 追加向量/非独立 id 对; 军官角色 CRef 走 CUnit+24 指挥官链 (舰→tf+24); **记录族布局与师侧同构** (§4.18.1 officer 子表: 内嵌记录 = 块1 @ship+2144 (seed@+8, name@+16, portraits@+48, male@+80), 追加记录 → officer[2+], 键序 seed/name/portraits/male, held_officer.experience i64 fix5@+2256 >0 写) | |
| history (10293) | +2264 | 容器对象 (ADEC0 多态; 门 = 内部 count @+2264+52 = sh+2316) | count≠0 | 元素布局定案: {+114 = is_sunk 门, +120 = 内嵌 168B CSunkShipInfo (§4.31.29 同型)}; **容器类名定案 = CUnitHistory {+24 type=1 舰, +40 元素向量 c@+52}; owner 槽按 ctor 变体分注 — 舰侧 sub_141445E00 落 +16, 军侧 sub_141445E90 落 +8 (同 vtable 0x1429C1868)**; **GUI: CNaviesViewSunkShipItem** (target = 元素+120 内嵌; assist@+161 / level@+120 / def@+104 全中); **GUI: CShipHistoryEntryItem = 舰长授勋行** (槽[13] 返本容器 ✓; 条目+112 = awardable 旗/+80 日期/+104 icon; 槽[14] 建 CMedalTemplateItem, 点击 = CGiveMedalCommand; **+114/+120 本行不消费** — 沉船归因归 §4.31.30) |
| critical_damage (15357) | +2328 | 16B 元容器数据 {名称串 ptr@0 (*(ptr)+24 = 长度校验), u32@+8}; assert「Invalid damaged part name on ship」ship.cpp:1159 | c>0 | |
| critical_damage (15357) | +2340 | critical_damage 容器计数 | c>0 | |
| raid_instance (19183) | +2352 | 行内 idpair — type | 任一≠0 | |
| raid_instance (19183) | +2356 | 行内 idpair — id | 任一≠0 | |

CShip 运行时燃料行: **+840 = i64 fix5 每小时燃料用量** (不序列化; getter sub_140C36F60; 谓词 sub_140C3AF90 < SHIP_FUEL_EFFICIENCY_WARNING_THRESHOLD → TASK_FORCE_HAS_FUEL_INEFFICIENT_SHIP_FOR_MISSION tooltip); 与 +856 构成 {标量, CModifier 树@+16} 修改值对 (舰统计重算 = 0x140C3D090 — 基值 = 舰体/装备定义); 逐舰 UI 现算 sub_140C39BF0 = 用量×(1+MODIFIER_NAVY_FUEL_CONSUMPTION_FACTOR id413)×FUEL_COST_MULT×MISSION_COST (TF 级 sub_140C35280 不带该修正项, 走 statId 69 缓存)。

CShip/CTaskForce GUI 消费表:

| 字段 | 消费点 | 用途 |
|---|---|---|
| CShip+8 refid | ShipStatsView (view+6632 ctor 快照; +56 解析缓存; 宿主+5320 idpair 进; 析构安全) | 面板 target 绑定 |
| CShip+24 IOfficerHolder | vtable[1]→+32; Update 0X141BEFB60 (缓存 win+10600) | 军官钮刷新 |
| CShip+232 舰体名 + def+968 | sub_140C3A0F0 (兜底 GFX_navalcombat_ship_icon_unknown) | 舰图标串 GFX_unit_\<hull\>_\<n\>_icon_medium |
| CShip+1576 旗 | sub_140C33A50 (define 15 门) + 逐帧 0X141BED5F0 | 流亡/可见谓词 + pride type_icon 切换 (CCountry+592/+596 vs 舰+8/+12) |
| CShip+1832 → tf+472 → CCountry+224 | sub_141BECFC0 | ≥1e5×define → ShipStats 资源门列表 |
| CTaskForce 数组 | CompactShipListView (UpdateCompactShipList, RTTI 定名) | 条目 entry+8/+16 idpair; **entry+1336 = 舰型 DB 索引, entry+1340 = 需求舰数** (COMPACT_SHIP_VIEW_DESC_REQ/TYPE; pride / required_ships_count 窗) |

#### 4.16.4 CFleet (writer 0x140D5EBC0 = vtable[2]; ⚠ 0x1412318A0 = CCountrySupplySystem writer)

> 特混舰队任务分桶件 = **sub_140D51B80** (按 tf+884 任务类型分桶 + tf+864 CNavalMission 分发; 8 调用方全 CFleet 族)。

**sizeof = 304 (0x130)** (malloc 0x130 双站点 + ctor 覆盖 +0..+303 + 活体 +300 alpha 恰填满四重证); RTTI 名 = CFleet (活体 COL 直读 .?AVCFleet@@ + vt_rtti.json 双证); 主vtable RVA 0x2962A18 / CSelectable 次表 0x2962A70; reader = vtable[4] 0x140D582B0; ctor 0x140D503D0 / dtor 0x140D50840 (fleet.cpp:162/163 断言) / 工厂 CreateFleet 0x140D545A0; 基类 = CReferenceObject + CSelectable (ctor sub_140BC2AA0(a1+24, 11))。派生: **CTaskForce sizeof = 1888 (0x760)** (loader 15157 分支 malloc 直证)。挂载点 = cc+632 {d} / cc+644 {c}, 元素 CFleet*。

⚠ GUI 锚「CFleet+1584/+2696 idpair」**物理不可能** (sizeof=304) — 系 GUI 项类自身偏移误挂 CFleet 名下, 待重勘; 「fl+24 = 类型标签 11」实为 CSelectable 第二基类vtable (type id 11 落 +32, selected 旗落 +36); 「fl+44 = 容器 cap」实为 hours RH 结构基死槽 (count@+56/mask@+60/lf 0.9@+68)。

完整成员布局 (+0..+303 全覆盖, 无成片空白):

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vtable | CFleet 主vtable 0x2962A18 | [2] writer / [4] reader |
| +8 | idpair 8B | CReferenceObject::ref {type@+8, id@+12} (基类 writer 发键 225/11) | 舰队数字 id 直印 AddTaskForce 日志 |
| +16 | uint8 | **CReferenceObject::IsCreated() 旗** (fleet.cpp:50/382 双断言内联直读 — 语义定案; 写点 = id 分配链 sub_1401E44C0→sub_14221E700 内, 高置信) | 读点定案 |
| +24 | vtable | **CSelectable 子对象vtable** 0x2962A70 | |
| +32 | uint32 | CSelectable type id = **11** | |
| +36 | uint8 | selected 旗 (dtor 断言 false, fleet.cpp:163) | |
| +40 | RH 结构基 | hours_without_patrol_missions_pairs RH 表 (死槽@+40; 桶数组@+48, **count@+56, mask@+60, extra@+64, lf 0.9@+68**; 24B 桶 {dist u8@+4, region ptr@+8 → id@+88, hours u32@+16}) | 键 15599 成对发射 |
| +72 | 匿名结构 (NNB 形状) 向量 | **strategic_region** {d@72, cap@80, count@84, alloc@88} — 元 8B CRegion* (id@ptr+88) | 键 12014: 先收 u32 数组再发射, 门 count>0; 维护件 = **AddRegion sub_140D50F10** (去重线性查 + 追加 sub_1401205A0; a3 → RebuildRegionRanges sub_140D530E0 + sub_140D5E970; a4 → 自动母港重选 sub_140D59410; 重复断言 fleet.cpp:2649 latch byte_14333CE44) |
| +96 | CFleet* 向量 | **区域范围表** {d@96, cap@104, count@108, alloc@112} — 元 16B {CFleet*, start u32, end u32}, 对排序后区域数组切段 (fleet.cpp:1788 断言) | 重建 sub_140D530E0 |
| +120 | 16B 节点 | 自引用范围节点 {self@120, start@128=0, end@132=区域数镜像} (无区域时挂进每个 TF mission) | 构建者 = **创建收尾件 sub_140D57A60** (空 idpair → sub_1401E44C0 分配 + sub_14221E700 注册; leader idpair resolve 失败 → 写空哨兵 qword_14333D528 清引用; +300 alpha==0 → sub_140D51A60; 尾 RebuildRegionRanges + "IsCreated()" 断言 fleet.cpp:382 读 +16; 身份高置信 — 不排除 PostLoad/OnIdAssigned 变体) |
| +136 | uint32 | **tick_to_check_naval_invasion_support** (键 15583, 门 >0; 书原表无此键) | |
| +144 | 匿名结构 (16B 形状) 向量 | **bombardment_region** {d@144, cap@152, count@156, alloc@160} — 16B 元 {region ptr@+0 → id@ptr+88, val u32@+8}; 门 count≠0; 写序 = 容器序 | 提取器: 首对 region 进键名, 余对 " k=v" 拼进值 |
| +168 | CCountry* | **owner 国家指针** (ctor sub_140BB4390) | |
| +176 | idpair 8B | **leader** {type@176, id@180} (键 10423; 门 ≠ qword_14333D528 空哨兵) | |
| +184 | 匿名结构 (NNB 形状) 向量 | **task_force** {d@184, cap@192, count@196, alloc@200} — 元 8B CTaskForce* (writer 逐元写 键 15157 + 元+16 视角) | |
| +208 | CNavyTheaterGroup* | **所属编组** (getter 0x140D50F00 / setter 0x140D5A620; 挂组 sub_1415B9550: fleet+208 = group 且 group+32 成员向量 += fleet; 组 vtable 0x29DCCE0 RTTI 直证) | |
| +216 | CProvince* | **home_base = 家港省指针** (键 10241, 发射 *(u32*)(prov+164) = 省 id — §4.14 定案; loader 解析失败报 "Invalid province ID for fleet home base"; G 批活体 vtable 0x2971B18 RTTI 直证 — 88B 的 CNavalBase 无 +164 槽) | |
| +224 | MSVC 串 32B | name (键 27; ctor 默认 "FLEET_NAME_NOT_SET") | |
| +256 | uint32 | icon (键 181) | |
| +260 | uint8 | **automated_homebase** (键 10395, bool 恒写) | |
| +261 | uint8 | **_TaskForcesLock** (AddTaskForce 断言, fleet.cpp:608) | |
| +272 | CColor 32B | color (键 86; {vtable@272, R f32@288, G@292, B@296, **A f32@300**}) | writer 校验和流门跳过 name/color/icon |

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
| tf+832 | MilitaryOverviewItem | **父舰队 CFleet\* (定案 — CTaskForce::GetFleet = sub_140D64500 一行直返 + fleet.cpp:548 断言 "Task force in the wrong fleet" 消费双证); 配对 setter SetFleet = sub_140D77B90 (旧队移除/新队挂/mission 重置/use_fleet_color 时颜色继承)** |
| tf+496 | MilitaryOverviewItem | 当前省份 CProvince* (prov+200 → 战略区; prov+184 → 静态描述符, desc+210 bit0 = is_land 在港判定) |
| tf+436 | MilitaryOverviewItem | 战斗中谓词 |
| tf+472 (tag_id u32) | MilitaryOverviewItem | owner — **u32 tag_id 非 CCountry\*** (与 CCountry+8 同源, 直读数值比; 定案) |
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
| writer | 0X140EB2250 (a1 = S+8; = vtable slot8 — **CStrategicNavy::Serialize 专用**) |
| loader | sub_140EACAF0 (slot10, if 链) |
| 挂载点 | gs+1688 → M+8 数组元素 (arr = rp(M+8), n@M+20 → S = rp(arr+8×idx)) |
| 序列化基 | S+8 (lua 偏移 = raw+16); dtor sub_140E9E0C0 (容器谱来源) |

全块序列化 (定案; token 全序与存档原文逐位吻合): 挂载链 `M = rp(gs+1688)`
(vtable 0X29732E0) → `arr = rp(M+8)`, `n@M+20` → `S = rp(arr+8*idx)`
(vtable 0X2973260) → 块 writer 0X140EB2250 (a1 = S+8)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +24 | CNavalBase* | 海军基地 容器数据指针 | 元素 = CNavalBase* (vtable 0X29731C0), count<4096; **+40 = 省 id→CNavalBase RH 表** (解析器 sub_140E7C420 定案, GUI 基地图标/修理窗共用) |  |
| +25..+35 | — | = bases 容器尾 {cap@+32}  |  |  |
| +36 | uint32 | 海军基地 容器计数 |  |  |
| +37..+47 | — | = bases 容器尾 {alloc@+40}  |  |  |
| +48 | CNavalBase* 向量 24B | 基地引用数组 {d@48, cap@56, c@60, alloc@64} (运行时-only; 基地被移除时对应槽置空 — sub_140EAAFE0 跨国转移) | 不序列化 | 形态定案/语义推定 |
| +72 | uint32 向量 24B | **naval access/interest 国缓存** {d@72, cap@80, c@84, alloc@88} — u32 国 idx 数组 (四源: 派系成员 + diplo+392 单 tag + wargoal 目标国 RH + military_access/docking_rights 关系国; 填充者 sub_140EADF80; 探针 GER/JAP 实证) | 不序列化  |  |
| +104 | 匿名结构 (NNB 形状) 向量 24B | **per-region CNavalMission\* 桶** {d@104, cap@112, c@116, alloc@120} — 276 桶×24B vector (区域数维; GER 桶 138/147/173 探针实证) | 不序列化; **GUI: 任务扩展行数据源** (CNavalMissionExtensionEntry: region+88 = 桶下标; **mission+8 = CTaskForce\* 新锚 / mission+20 = 任务类型 u32**; pride 判定 = ship+1832 == tf 回指; tooltip SPECIFIC_NAVY_CONTAINS_PRIDE_OF_FLEET) |  |
| +128 | u32 数组 | per_region_danger 容器数据 {d@128, c@140} | 稠密 u32 区域数组, 见 token 全序表; 块门 c≠0 但全 0 值时提取器无叶 → 全 0 不发射 |  |
| +140 | uint32 | per_region_danger 容器计数 |  |  |
| +141..+151 | — | = danger/regional_convoys 容器尾 (cap/alloc) |  |  |
| +152 | SRegionalConvoyData* | regional_convoys 容器数据指针 — 稀疏数组 {data@S+152, count@S+164} | 305 战略区域, **stride 48 = SRegionalConvoyData** (下表) | 定案; reader Country.navy.regional_convoys; 提取器: 有条目时块前缀被吞 → 有条目不发容量行 / 无条目发 regional_convoys.#1=容量 |
| +153..+163 | — | = regional_convoys 容器尾  |  |  |
| +164 | uint32 | regional_convoys 容器计数 |  |  |
| +165..+175 | — | = regional_convoys/access 容器尾  |  |  |
| +176 | int8 | per_region_access 容器数据指针 | int8 数组; **>0 才写 idx=val 对**; 值枚举 {0=allowed, 1=avoid, 2=blocked} (定案, sub_140EA62F0 本地化键生成器直证, §4.16.5a) |  |
| +177..+187 | — | = access 容器尾  |  |  |
| +188 | uint32 | per_region_access 容器计数 |  |  |
| +189..+199 | — | = access/mines 容器尾  |  |  |
| +200 | int64 | mines 容器数据指针 | 8B 数组 |  |
| +201..+211 | — | = mines 容器尾  |  |  |
| +212 | uint32 | mines 容器计数 | 8B 数组 |  |
| +213..+223 | — | = mines/accident 容器尾  |  |  |
| +224 | 匿名结构 (NNB 形状) 向量 | naval_accidents 容器数据指针 | 元素 8B 指针 → CNavalAccidentReport (vtable 0X295DDC8; **元素 writer 0X140CE6590 = vtable slot2**; 0X140EB2250 = CStrategicNavy::Serialize 专用, 勿混) | 定案; loader 门 rec+8 (region 指针) 非空 |
| +225..+235 | — | = accident 容器尾  |  |  |
| +236 | uint32 | naval_accidents 容器计数 |  |  |
| +248 | CNavalMineReport* 向量 24B | **mine_report** {d@248, cap@256, c@260, alloc@264} | loader malloc 0x50 + CNavalMineReport::vftable | loader-only; ⚠ 现版 writer 不发射 (token 15321 仅 loader 识) |
| +272 | 匿名结构 (NNB 形状) 向量 24B | **active CNavalMission\* 平表** {d@272, cap@280, c@284, alloc@288} (元素 vtable 0X297F038 = CNavalMission RTTI 直查) | 不序列化  |  |
| +296 | uint8 | **舰队刷新脏旗** (推定名; 小时更新读清, 置位触发属主国逐元素 sub_140D59BE0 + sub_140A66B70 舰队刷新链) | 不序列化  | 高置信 |
| +297 | uint8 | **bases dirty flag** (基地增删后置 1; sub_140EAAFE0/sub_140EAACF0/sub_140EAA7F0 三处写) | 不序列化  |  |
| +298 | uint8 | **naval access/interest 缓存脏旗** (小时更新读清 → sub_140EADF80 重建 +72 国缓存) | 不序列化  |  |
| +304 | CNavalUnitTransfer* 向量 | naval_transport 容器数据指针 | 元素 = 8B 指针 → CNavalUnitTransfer (vtable 0X296D8A8, 176B=0xB0; 字段表按指针解引用读取, 见 §4.16.7) | reader Country.navy.naval_transports |
| +316 | uint32 | naval_transport 容器计数 |  |  |
| +328 | MSVC 串 向量 24B | **task_force_templates** {d@328, cap@336, c@340, alloc@344} — **136B 内联元** {name MSVC 串@+0 (token 27), composition_requirements 多态对象@+32 (token 15168)} | 块 token 15175 task_force_template | loader: name 空或 composition 无效不入容器 |
| +340 | uint32 | task_force_templates **容器计数** | | |
| +341..+351 | — | = templates 容器尾 {alloc@+344}  |  |  |
| +352 | RH 结构基 | convoy_escort_presence_history RH **结构基 @+352** (loader 插入点 = a1+344 ser; struct+0 = 四面无读者死槽 (负定案), data@+360=struct+8, count@struct+16=+368 (写入门字段), mask@struct+20=+372, extra@struct+24=+376, lf@struct+28=+380; 条目 40B 见 §4.16.11) |  |  |
| +361..+371 | — | = RH 结构体内  |  |  |
| +372 | uint32 | convoy_escort_presence_history RH mask | | |
| +376 | uint8 | convoy_escort_presence_history RH extra | | |
| +384 | 匿名结构 (200B 形状) | **per-navy 邻接规则 (海峡/运河通行) 缓存** — 200B 无 vtable {owner 回指 + 3×64B block (kind 2/1/0, region→u16 组映射 + 376B 元规则 RH)}; 谓词链落 adjacencyrule.cpp (EAdjacencyRuleSubject); **消费入口 = sub_140EA9120/9510 → sub_1419ED790** (ENavalPathing 判定, §4.16.5a) | 不序列化  |  |
| +392 | uint32 向量 24B | **naval_supply_hub 省份缓存** {d@392, cap@400, c@404, alloc@408} — u32 省 id (填充者 sub_140EB1840 遍历 controlled_provinces → prov+480 建筑实例数组 → 建筑类型共享状态 F+886 旗 = naval_supply_hub 类型旗 tok 10194, 定案; ⚠ **CNavalBase+392 = owner tag u32 跨类同偏移并存, 勿混**) | 不序列化  |  |
| +416 | 匿名结构 (8B 形状) 向量 | homebase_observers {d@416, c@428} 8B 元 {prov u32@0, count u8@+4} | 逐元匿名块 "prov count" |  |
| +428 | uint32 | homebase_observers 容器计数 |  |  |
| +440 | uint32 | dockyards max_allowed |  |  |
| +444 | uint32 | used |  |  |

token 全序表:

| token | S 偏移 | 语义 |
|---|---|---|
| 13066 | +304/+316 | naval_transport 容器 (门 c>0) |
| 14923 | +152 | regional_convoys (稀疏数组壳) |
| 14654 | +176/+188 | per_region_access 容器 (i8; >0 才写 idx=val 对) |
| 14658 | +200/+212 | per_region_mines 容器 (i64; 定案, 探针 AUS 168→1.357) |
| 15175 | +328/+340 | task_force_template 块 (136B 元 {name 27, composition 15168}) |
| 15305 | +224/+236 | naval_accidents 容器 (门 c>0) |
| 12790 | +24/+36 | naval_base 块 (逐基地块, 宿主 §4.16.8) — ⚠ 同键在 §4.16.4 CFleet 侧为 reader 兼容旧跳过键, 两域同名勿串 |
| 15336 | +440 | dockyards max_allowed (恒写) |
| 15338 | +444 | dockyards used (恒写) |
| 15588 | +128/+140 | per_region_danger 容器 — 稠密 u32 区域数组, writer 写 "idx val" 对仅 val>0 → savefull 折叠单叶 .#1 |
| 15631 | +352 | convoy_escort_presence_history RH (§4.16.11; 双重门 = RH count>0 ∧ gs+748 > 1 — 极早期档不发射该块; loader: region id 门 0 < id < \*(gs+748), 条目值钳 ≥721 int, 32 位终化哈希常数 73244475 两轮) |
| 19972 | +416/+428 | homebase_observers 容器 — 元 {prov u32@0, count u8@+4}, 逐元匿名块 "prov count" |

#### 4.16.5a CStrategicNavy 运行时操作层 (strategicnavy.cpp 定案)

簇定性 = **CStrategicNavy/CNavalBase/CNavalUnitTransfer 的运行时操作面** (存档 loader + 修理队列 + 海运下单/拆分 + 寻路判定); **非 AI 战略海军评估层** (负定案: 全簇无一函数被 AI 主循环调用, 任务分配逻辑在 CNavalMission/ai 域, 本簇只供判定原语)。this 三型: loader/下单/拆分/寻路族 a1 = S (CStrategicNavy\*); 修理队列族 a1 = CNavalBase\* (NB+16 省 id / NB+40 队列)。入口四路: 读档 (vtable slot10) / 每小时 tick phase 9 (sub_1401DF400 → sub_140EA79F0 → sub_140EA76B0 → 逐基地 sub_140EA1280; TF 侧 sub_140D731A0 → sub_140E9F4E0, §4.16.8) / 玩家·AI 命令 (§4.16.15 四入口) / 修理 UI (§4.16.8 移舰对)。

运行时判定与工具函数 (12 函数簇内书先前未收的 7 个):

| 函数 | 身份 | 定案要点 |
|---|---|---|
| sub_140EA62F0 | 海域访问级别本地化键生成器 | f(out 串, access_level): 三值枚举 → "NAVAL_REGION_ACCESS_{ALLOWED,AVOID,BLOCKED}\n…_DESC" 双键拼接 (本地化变量 LVL=1); 其它值断言 :3384 后返空串; 调用者 = GUI tooltip 族 3 处 |
| sub_140EA9120 | CheckNavalPath (省对版) | a2 = ENavalPathing {0..4}; 两省各经 prov+184 描述符 (+210 bit0 is_land → GetProvince(+200 配对海省)) → 海省+200 战略区 → 区+88 数字 id → sub_1419ED790(S+384 缓存, …); 映射 0→(1,2) / 1→(2,2) / {2,3}→(0,2) / 4→(3,1) (二元组业务名推定; {2,3}→(0,2) = 双源逐行直证 — v11 在两函数入口均显式初始化为 0, 非 未初始化噪音); 未识别枚举断言 :2646 (闩 byte_14333D1EB, 两版共用); 调用者 5 处全为海军任务/移动判定族 |
| sub_140EA9510 | CheckNavalPath (区对象直连版) | a3 直接持区 +88 字段 (免省→区换算); 同款断言与映射; 调用者 2 处; 与 EA9120 = 同一判定两接口层 |
| sub_140EA6F20 | 权重随机选取 | 输入 24B/元 {权重 u64@0, 值 qword@+8, u32 tag@+16 (+20..+23 填充, 仅 +16..+19 被消费)} 排序态前缀和游走 (count==1 快路; 随机 ≥ 总权重取末元素); 出参 *a3 = qword {tag@0, 国家数组下标@4} (下标经 sub_140BB5490(elem+16), §4.27.1 tag→国家下标 helper); 容器 +24 = i64 总权重; 随机 = random_fixed 全局计数器哈希流 (§4.28.13) 源行 4172 播种 (确定性重放, OOS 安全); **空表/零权缺省 = 100000 (fixed 1.0, 不写 *a3)**; 唯一消费者 = 船体统计 sub_140C309D0 |
| sub_140E9F4E0 | CNavalBase::AddTaskForceShipsToRepairQueue | 见 §4.16.8 修理链表 |
| sub_140EAE9C0 / sub_140EAEB30 | 修理队列移舰对 | 见 §4.16.8 修理链表 |
| sub_140EAA8C0 | CNavalBase::DetachProvinceTaskForceShips | 见 §4.16.8 修理链表 |

确定性 RNG 定案: 本簇 2 处随机 (源行 280 洗牌 / 4172 权重抽取) 均走 random_fixed 全局计数器哈希流 (§4.28.13, 非 O'Neill PCG) 带 (文件, 源行) 标签 — 重放确定。

#### 4.16.6 SRegionalConvoyData (48B)

SRegionalConvoyData (48B; 元 vtable 0x142973210; 定案) — 稀疏写出:
SSparseArrayWriter (vtable 0X2973490 slot1 = 0X140EB2070) 先写裸容量 (u32@壳+12
= 305) 再逐**非默认**元 `{ index=i, data={…} }`; **默认谓词 0X140EA8D50** =
三字段全默认才不写 (⚠ 条目门 = 非默认谓词, 不是 rc≠0); data writer
0X140EB2AF0 三字段各自条件写:

| 偏移 | 类型 | 名称/语义 | 默认 | 写门 |
|---|---|---|---|---|
| +0 | vtable | 0x142973210 | — | — |
| +8 | uint32 | required_convoys (0x30CA) | 0 | ≠0 |
| +16 | fixed×1e-5 | efficiency (0x35E7) | 100000 (=1.0) | ≠100000 |
| +24 | vtable | CGameDate 内嵌 vtable | — | — |
| +32 | hours | last_sunk_convoy_date (0x3A4A) | **43817520** (dword_143086B38) | **≠哨兵才写** (SL.date 哨兵表不含 43817520, 段内须显式门) |
| +40 | vtable | 第二 CGameDate 内嵌 vtable | — | 未写盘字段 |

#### 4.16.7 CNavalUnitTransfer (176B, naval_transport 元素)

CNavalUnitTransfer (176B = 0xB0; vtable 0X296D8A8; 元素 writer 0X140E28F40;
定案) — 容器元素 = 8B 指针, 下表偏移按指针解引用后读取:

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +16 | uint8 | id 块门 (refid 经 B400) | ≠0 |
| +24 | idpair | combat 容器数据指针 — id 对数组 {d, c} | c>0 |
| +25..+35 | — | = combat 容器 {data@24, **cap@32**, count@36, alloc@40} 内部 (pdx 24B) |  |
| +36 | uint32 | combat 容器计数 | c>0 |
| +37..+47 | — | = combat count 尾 + **alloc@40**  |  |
| +48 | uint32 | spotter.type — id 对之 type (refid 对) | 任一≠0 |
| +52 | uint32 | spotter.id — id 对之 id | 任一≠0 |
| +56 | idpair | unit 容器数据指针 — refid 数组 {d, c} | 元素有效且 A3D0−16≠0 |
| +57..+67 | — | = unit 容器 {data@56, **cap@64**, count@68, alloc@72} 内部  |  |
| +68 | uint32 | unit 容器计数 |  |
| +69..+79 | — | = unit count 尾 + **alloc@72**  |  |
| +80 | uint32 | target_provinces | 无条件 |
| +84 | uint32 | province | 无条件 |
| +88 | tag_id | country (sub_140BB4E70→串) | 无条件 |
| +92 | uint8 | **invasion_group (0x316A)** | **≠0 仅真写 yes** (ctor 第 4 参创建即写 = sub_140700570 敌对判定旗, 运行时来源定案) |
| +93 | uint8 | is_returning (0x3938) | ≠0 |
| +94 | uint8 | force_revalidate_route (0x393F) | ≠0 |
| +96 | uint32 | cooldown (0x391E) | >0 |
| +104 | uint32 | path 容器数据指针 — u32 数组 {d, c} | c>0 |
| +105..+115 | — | = path 容器 {data@104, **cap@112**, count@116, alloc@120} 内部 (u32 省 id 数组) |  |
| +116 | uint32 | path 容器计数 | c>0 |
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
| +0 | uint32 | level |
| +8 | int64 fixed5 | amount (⚠ 内存 300000 ↔ save 3) |

resources 叶名 `<building>.<level>`。

#### 4.16.7b CConvoySubscriber 与运输船管理器 (country+4608)

**CConvoySubscriber** (40B, vtable 0x14295c0f0) 内嵌三处: css+232 / tf+1136 / CNavalUnitTransfer+136; 另有轻客户端 (CEquipmentConvoyClient 族) 内嵌 +8/+32/+136 小宿主。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | allocated (已分得运输船数) |
| +12 | uint32 | requested (申请数; RequestConvoys sub_141022950 写) |
| +16 | uint32 | 静态标签 (Init 第 3 参: 2/4/32/128; 分配面不读) |
| +24 | CCountry* | 订阅宿主国 |
| +32 | 桶指针 | 所属优先级桶 (订阅时回填) |

订阅链: Init sub_141021F90 (convoys.cpp:29 断言; 旧国非空先退订, requested/allocated **保值重订阅**) → 订阅 sub_1410207D0 (按**优先级键**二分定位/建桶, 桶 40B {键, Σallocated, Σrequested, 订阅者数组, cap, count, allocator} 按键升序插入, 订阅者尾插 1.5× 扩容, 三面聚合同步); 退订 sub_1410227F0 (聚合反减; 桶仅剩 1 人整桶释放, 否则桶内 swap-remove; sub+8/+12 清零; 尾调 sub_1410215C0 全量再平衡)。优先级键 = define 值: NAVAL_INVASION/NAVAL_TRANSFER(1) / SUPPLY(2) / RESOURCE_LENDLEASE(3) / RESOURCE_EXPORT(4) / RESOURCE_ORIGIN(5) / RESOURCE_PURCHASE(6) / UNDERWAY_REPLENISHMENT(7) — **值大 = 优先级低** (桶升序, 缺口回剥从数组尾开始)。分配 = RequestConvoys 即时分派, 缺口时从最低优先级桶整段剥除后顺位重填; **沉船反应** = sub_1410225E0 扣池后按阈值触发同一回剥 (convoys.cpp:437/612/53 断言族)。

管理器 (country+4608): {+16 池对容器头 {data@+48, cap@+56, count@+60, alloc@+64} 16B 元 {CResource*, amount i64 fixed5}, +80 桶指针数组 data / +92 count, +104 Σrequested, +108 Σallocated, +112 运输船变体资源缓存 (sub_141021920, 从 country+3944 资源数组取首个 flag&1 项), +120 池缓存有效旗, +128 池缓存 fixed5}。池读 = sub_14100DCB0 (Σ flag(resource+1032)&1 的 amount); 可用 = sub_1402BC910 (池/1e5); 空闲 = sub_1402BC8A0 (池/1e5 − Σallocated); 指定优先级以下已占 = sub_141021C20。**桶按掩码计数 = sub_141021E50(mgr, mask, flag)** (高置信): 遍历 +80 桶数组 → 桶+16 子数组 (count@池元素+28) → `(mask & 子条目+16) == 子条目+16` 时累加 子条目+12; 子条目布局 {count@+12, mask@+16}; 月度日志 convoy 段用 mask 1/2/32/92 × flag 0/1 (§4.2.10)。css 日重建 = sub_141230D40; 贸易路线申请点 = lambda_2 sub_141225420。**增减总入口 CConvoys::AddConvoys = sub_141020680** (a1 = mgr, a2 = i32 amount): 正数 → 1e5 缩放入 CEquipmentVariantPool@+16 (sub_14100CCE0) + 池缓存有效旗 (+120) 清 0 + sub_1410215C0 重算; 负数 → 取负 (sub_1424EF6F0 单指令 helper) → sub_1410225E0 移除; amount==0 空操作; 取负溢出 (INT_MIN) → :612 防御日志。

#### 4.16.8 CNavalBase

CNavalBase (vtable 0X29731C0; **sizeof = 88 (0x58)** malloc 三重证; writer = vtable[2] 0x140EB2180 / reader = vtable[4] 0x140EAC9A0; ctor 无独立函数 — 内联于建基地工厂 sub_140E9F210; dtor sub_140E9DAB0; 序列化只发 3 键: 15334 ships_in_repair (count≠0) / 141 priority (门 = **≠1**, ctor 默认 1 — 原「≠0」订正) / 15434 disabled 逐元; province/level/max_level 不序列化, 读档由 init sub_140EB1DF0 从 prov+400 建筑实例派生 (inst+66→level、inst+64→max_level); 存档叶形 = strategic_navy.naval_base.<省id>.priority — 元素头串 = 省 id 十进制串; **省→基地 RH 表在管理器 M+40** (全局 547 条, 活体与各国 bases 容器同对象群)):
⚠ 原跨类同偏移警告订正: 「CNavalBase+392 = owner tag」不存在 (88B 对象) — 该偏移实为 **CProvince+392 controller** 之误标。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CStrategicNavy* | owner 回指 (其 +96 = 管理器 M) |
| +16 | uint32 | province |
| +20 | uint32 | level |
| +24 | uint32 | max_level |
| +28 | uint32 | **修理容量** (min 钳 + 超容警报双证; GUI = CNavalBaseMapIcon populate 消费) |
| +32 | uint32 | priority — writer ADFE0 按 u32 存读 (定案); **门 = ≠1** (ctor 默认 1; 原「≠0 才写」订正) |
| +40 | idpair | ships_in_repair 容器数据 (8B 内联对 {type@0, id@+4}); count@+52; **GUI: 修理队列数据源归属定案** (CNavalRepairWindow 队列 = CStrategicNavy+24 bases 容器 → 本字段, 非 §4.8 refit 生产线; 行类 CNavalRepairQueueNavalBaseEntry 行+3904 = nb / CNavalRepairQueueShipEntry 行+48 = 船 idpair); 发射 = `#N` 恒编号 (1 起容器序, 值 "id=N type=T") |
| +41..+51 | — | = ships_in_repair 容器尾  |
| +52 | uint32 | ships_in_repair 容器计数 |
| +53..+63 | — | = ships_in_repair 容器尾 + disabled 前置  |
| +64 | string | **disabled_for_repairs 串列表** 容器数据 (token 0x3C4A = 15434, writer 直证); count@+76 |
| +65..+75 | — | = disabled_for_repairs 容器尾  |
| +76 | uint32 | disabled_for_repairs 串列表容器计数 |
| +80 | ptr | 第二容器分配器指针 (共享静态 off_143085170) + 尾填充至 88 — 对象到 88 为止, 原「+80..尾 空白」闭合 |
| ⚠ | — | 原「CNavalBase+392 = owner tag u32」跨类警告**废** — 88B 对象无 +392 槽, 该偏移实为 CProvince+392 controller 误标 (§4.14) |
修理链: 入队 sub_140EAB160 (本国优先 + repair_mode 降序) + 插入位规则 sub_140EA4EE0; 队列小时处理 sub_140EA1280 + 交战门 sub_140EA10E0; 速率 = sub_140D655B0 (NAVALBASE_REPAIR_MULT × modifier 475 × 基地系数, **补给门**用 calc+184 _RemainingSupply)。

修理链全环 (queue 小时处理两相 + 批量入队 + 移舰 + 拆船, 定案):

| 环节 | 函数 | 语义 |
|---|---|---|
| 小时处理 相 1 | sub_140EA1280 | 同省特混舰队合并候选: repair_parent (tf+1200) 空 ∧ detached_activity (tf+1208) ≠1 ∧ repair_mode (tf+1124) ∉ {0,5} ∧ 无任务 (tf+864 内嵌 CNavalMission) ∧ 无子 ∧ 属主 = 省控制国 (prov+392) → sub_140D64C30 **就地开修 StartRepairHere** (SetDetachedActivity(1, 当前省), 并入基地修理队列 — 非舰队合并); 入队前断言 TF+496 所在省 = 基地省 (:707) |
| 小时处理 相 2 | sub_140EA1280 | 队列重建: 船+1784 日期过期 ∨ 船+2340 旗 → 出队 (compact); 其所在 TF (船+1832 回指) 排序 (≤32 插入 sub_140E9B900 / 归并 sub_140E9BFB0); 交战门 sub_140EA10E0 过且 repair_mode ≠0 → sub_140EAB160 重入队; 不过 → sub_140D67780 |
| TF 批量入队 | sub_140E9F4E0 | CTaskForce 小时链 sub_140D731A0 调; 收集过期/旗位船经 NB+40 线性查重后**确定性洗牌** (random_fixed 源行 280 播种, OOS 安全), 按插入位规则 sub_140EA4EE0 定点插入 |
| 移舰 (绝对下标) | sub_140EAE9C0 | 查全部重复项删除 (幂等) → min(目标下标, 队长) 重插; UI 拖拽左右分支之一 (修理窗 sub_141356A80 / sub_141353990) |
| 移舰 (同属主组内) | sub_140EAEB30 | 过滤与目标船同属主 (sub_140C30D00 属主 + sub_140BB52F0 同国判定) 的队列成员, 截断到组内目标位原位回写 |
| 基地移除拆船 | sub_140EAA8C0 | 基地移除族 sub_140EAA7F0 (S+297 三写点之一) 唯一调用; 遍历省海军单位容器 (prov+248/+260) 拆散全部成员船 (sub_140D77FF0); 时间预算门 = random_fixed 源行 547 抽值 vs qword_143337038 阈值 (超预算停止收集) |


#### 4.16.9 CNavalAccidentReport (72B)

CNavalAccidentReport (72B = 0x48; vtable 0X295DDC8; Serialize = 0X140CE6590 =
vtable slot2, 定案; 0X140EB2250 = CStrategicNavy::Serialize 专用, 勿混);
a1=rec:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 (间接) | uint32 | region = uint32@(*(rec+8)+88) (键 10827 恒写) |
| +16 | uint32 | equipment.type — id 对之 type (id 对 {type, id}) |
| +20 | uint32 | equipment.id — id 对之 id |
| +24 | uint64 | 累加器 (添加器 sub_140EAAE10 `*(rec+24) += a3`; 不序列化) |
| +32 | uint8 | **is_sunk** (token 14661; ≠0 才写) |
| +36 | uint32 | ship.type — id 对之 type (id 对 {type, id}) |
| +40 | uint32 | ship.id — id 对之 id |
| +44 | tag uint32 | **country** (token 10394, sub_140BB4E70→串; 恒写) |
| +56 | hours | **to_discard_date** (token 15510) — 24B {vtable1@+48, hours@+56, vtable2@+64}, ADEC0 代理 = vtable2@+64; 恒写 |

#### 4.16.10 CNavalMineReport (80B)

CNavalMineReport (80B = 0x50; vtable 0X295DE18; Serialize 0X140CE6D20 = vtable
slot2; 定案) — 与事故记录同头; **date = 单个 CGameDate 24B {vtable1@+48,
hours@+56 = 43808760 哨兵, vtable2@+64}** (loader 内联 ctor 定案 — 不存在第二
未发射日期), 序列化只发 to_discard_date (代理 = vtable2@+64)。容器 {d@S+248,
c@S+260} writer 不发射 (token 15321 仅 loader 识)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 (间接) | uint32 | region = uint32@(*(rec+8)+88) (键 10827 恒写) | — |
| +16 | idpair | equipment {type@+16, id@+20} | — |
| +24 | uint64 | 累加器 (添加器 sub_140EAAF00 同式; 不序列化) | — |
| +32 | uint8 | is_sunk | ≠0 |
| +36 | idpair | ship {type@+36, id@+40} | — |
| +44 | tag uint32 | country (token 10394, sub_140BB4E70→串) | — |
| +48..+71 | CGameDate 24B | date {vtable1@+48, hours@+56 = 43808760 哨兵, vtable2@+64} | 只发 to_discard_date (代理 = vtable2@+64) |
| +72 | tag uint32 | country 尾部多发 (token 10394; 同键双发 = 重复标量叶不编号形态; 推定 = 布雷国+被炸国二元组) | — |

has_mined 深扫链 (复合链, 推定; 单批孤证, cc 侧首跳管理器指针未钉偏移):
cc → 水雷管理器 → 元 {+176/+188} → 子 {+184} → 表 {data@+112, count@+124, 48B 条 {id@+8}} → 对象旗 {+184 u8, +200, +210 u8}。

#### 4.16.11 convoy_escort_presence_history 条目 (40B)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +4 | uint8 | dist | 有效值 1..0xFE |
| +8 | uint32 | region | |
| +16 | 匿名结构 (NNB 形状) (环形缓冲 §3.4) | value 内嵌 {buf@+16, capacity@+24, head@+28, tail@+32} | 元素 i32 三态 {−1 无数据哨兵, 0 无护航, N 活跃护航 TF 计数} (生产端 sub_140EB0970 Σ+−1 push / 消费端 sub_140EA58B0 按 ≥0 分母 >0 分子, 720 窗口); 每条目发射门 = 环非空 (tail != head); 落盘 = head..tail 环形展开 (count = tail<head ? capacity+tail−head : tail−head; 满载 capacity−1; 运行时新建条目即 cap=721 (malloc 0xB44); ⚠ 线性读法读出槽外垃圾) |

**运行时清扫器 = sub_140EA1B20** (215 行; = CStrategicNavyManager::DailyUpdate 体 sub_140EA2FD0 六步之尾, §4.2 计时域 9 navymanager.daily): 遍历 RH 表 (桶跨距 40, 跳 dist@+4 == 0), 每桶走环 — **任一元素 `*(i32*)(buf+4×idx) >= 0` 即保留**; **全 < 0 (−1 哨兵) 或空环 (head == tail) → 收集 region u32@+8**。对每个待删键重算哈希定位 (u32 键双轮雪崩, P = 73244475 = 0x045D9F3B, `idx = mask & h`) → 线性探测比对键@+8 → **40B 桶 RH backward-shift 擦除** (先 j_free 当前桶 buf, 整搬下桶六字段含 dist−1, 被搬空桶重置 {buf=0, capacity=1, head=0, tail=0}, 终桶 j_free + dist=0 + 宿主 count@+368 −−)。遍历前断言 `_pBuffer != nullptr` (pdx_circular_buffer.h:124, latch byte_14333D1F1) + 桶推进断言 (pdx_robin_hood_table.h:58, latch byte_14333D1F2)。

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
==2 (strike) 且 repair_mode≠5 → 维修度 vtable[34] ≥ 阈值, 或全舰修满
sub_140C38740 → 归队; 在修理目标省且任务=8 也跑一次状态机) / 2=moving_to_refit
(sub_140D78BA0) / 3=refitting (sub_140D79DE0) / 4=reinforcing (sub_140D7A180)
— 3/4 在 §4.16.2 在册。

10 类任务分派 (sub_140FBCB90 switch):

| type | 名 | handler | 状态机核心 |
|---|---|---|---|
| 0 | HOLD | 内联 | 门: `+49==0 ∧ AGGRESSION_SETTINGS_VALUES[+52] > 0`; 扫本省 (tf+496 → prov+260/prov+248) 他舰 TF: 非 HOLD 关系 + 目标舰型过滤 (tf+1868 计数≠0 时逐舰 sh+136 def 匹配 tf+1856 清单) + 战斗序列 ≥3 (交战国) → **sub_140BB99D0 开战**; 无果 +68=0 |
| 1 | PATROL | sub_140FBB0A0 | 侦查引擎 (下); 目标失效清 +112/+108/+136; +108 在区递增; 完全侦出 (+128 ≥ 1e7) → +104 锁存 + 三级 notify (sub_140C01B70: 1=部分/2=发现/3=可攻击; 阈值 SPOTTING_MISSION_DETECTION_THRESHOLD_LOW/MEDIUM) |
| 2 | STRIKE_FORCE | sub_140FB3C90 | strike 目标 (+160) 有效且就绪 (sub_140FBE950) → 追击目标省; 无目标 → 舰队目标省 (fleet+216) 待命; 同省相遇 → sub_140BB99D0 开战 + sub_140D766E0 注销目标 |
| 3 | CONVOY_RAIDING | sub_140FBC730 | 目标态: +144 护航客户 / +152 海运运输 (**+92 invasion_group 区分** — +92 实义见 §4.16.7 表 invasion_group 行); sub_140FBB810 接敌现运 (省 +272/+284 陆军 type0 单位数组与 +296/+308 铁路炮 type13 数组 → unit+760 运输: a2 目标优先级码门 (下) + 冷却 +96≤0 + spotter +48 全零 + 无战斗 +36 + allocated +144>0 + 敌我门, 完整式见下「接敌现运检测门」) 失败 → sub_140FBADC0 搜护航客户 (CONVOY_DETECTION_CHANCE_BASE 门); 检测进度都是 +128 |
| 4 | CONVOY_ESCORT | sub_140FBBF00 | 扫区域→省→省 +368/+380 客户在场表: 客户 × tf+1856 目标舰型 × mission+16 国别匹配, 敌我强度比择优 → **sub_140BB85D0 接敌** |
| 5 | MINES_PLANTING | 内联 | 有海权国 ∧ +212 区域数>0: 布雷量 = NAVAL_MINES_PLANTING_SPEED_MULT × sub_140D6F120(tf); 确定性 RNG (种子=小时) 遍历 +200 区域, sub_141003F50 海权优势方==我 → × (NAVAL_DOMINANCE_MINES_PLANTING_BONUS+1e5)/1e5; 查现存上限 NAVAL_MINES_IN_REGION_MAX → sub_140E9F1D0 布雷 |
| 6 | MINES_SWEEPING | sub_140FB8840 | 对称: NAVAL_MINES_SWEEPING_SPEED_MULT × sub_140D6F1F0(tf); 海权加成 NAVAL_DOMINANCE_MINES_SWEEPING_BONUS; sub_140E9F1D0 负量扫除 |
| 7 | TRAINING | sub_140FB97C0 | 门: 训练区存在 ∧ (+69==0 ∨ sub_140D700A0); **sub_140D700A0 = 训练余量谓词 (定案)**: 逐 tf+840 舰, 存在 sub_140C36400(ship) < UNIT_EXP_LEVELS[TRAINING_MAX_LEVEL−1] (= 30000 fixed5, 取值 sub_140C37E50) 即返 1; 空舰队/全舰不达标返 0; **sub_140C36400 = 舰本级进度%** = 100000 × clamp≥0(ship+1800) / (ship+1808), 除数 0 → 0xFFFFFFFF 哨兵 (已满级, 永不达标); 在区 → +56 递增 (≥24 归零+日报); 逐舰训练推进 = TRAINING_EXPERIENCE_FACTOR × 燃料比缩放, XP/组织度/强度恢复 (0.15/0.6 经验加权) |
| 8 | reserve | 内联 | 未战斗 ∧ 无路径 (tf+524≤0) ∧ 有海权区域 → sub_140FB8FF0; 否则 sub_140D69BB0(tf,0) 母港省 → **+24 = 省 id** + sub_140FB95F0 回港令 |
| 9 | NAVAL_INVASION_SUPPORT | 内联 | +96 轰炸区在 +200 内 → 校验 (navalmission.cpp:4051 断言); 不在 → 清 +96; 无 +96: 订单引用 (+72) 有效 → sub_140FBDD60 从登陆订单战斗列表 (order+528/+540) 的省选轰炸区; 否则跟随舰队目标省 → +24 = 省 id |

接敌现运检测门 (sub_140FBB810, navalmission.cpp, 定案): 五参 (mission, a2 目标优先级码, a3/a4 开战上下文透传 sub_140FBAB00, a5 破交效率 fixed5 = sub_140FAE5D0)。**a2 = caller 现算 0..3**: mission+152 idpair 非空 → sub_14221F310 解引用读 +92 → 3 (登陆舰队) / 2 (普通运输); 否则 = (mission+144 idpair 非空) (1 仅护航客户 / 0 无目标)。**入口五门 (全返 0)**: a2 ≥ 3 (已锁登陆舰队目标) / mission+49 旗 (与 HOLD 同门) / AGGRESSION_SETTINGS_VALUES[mission+52] ≤ 0 / 100×random > UNIT_TRANSFER_DETECTION_CHANCE_BASE (qword_143335468) / a5 < 100000 且 random > a5 (效率越高越易放行)。**候选门** (双层扫 mission+200 区域 → region+24 省 → 海省门 desc+210 & 3 == 0 → 省 +272/+284 陆军与 +296/+308 铁路炮两支同构循环 → unit+760 运输): 敌我门 = dip+8 槽表 [sub_140BB5490(unit+472)] → +744 关系对象 +73 == 0 (非友军); 优先级规则 = a2 < 2 收任何运输 / a2 == 2 仅收 invasion_group (+92) 运输 (升级); 冷却 +96 ≤ 0; spotter +48 idpair 全零 ∧ 战斗计数 +36 == 0; allocated +144 > 0 (§4.16.7b 内嵌订阅者 +8)。**逐候选掷检定** (sub_140FACD70 海侦基础概率 v45 × sub_140FB2840 面侦速度因子 v46 [按 allocated 缩放]): 命中 ⟺ `100 × random(navalmission.cpp:3735) ≤ v40 + v41 / 100000`, 其中 invasion_group 支 {v40 = SPOTTING_SPEED_EFFECT_FOR_INITIAL_NAVAL_INVASION_SPOTTING (qword_1433356B8) × v46 / 100000, v41 = BASE_SPOTTING_EFFECT_FOR_INITIAL_NAVAL_INVASION_SPOTTING (qword_143335620) × v45}, 普通运输支 {SPOTTING_SPEED_EFFECT_FOR_INITIAL_UNIT_TRANSFER_SPOTTING (qword_143335590) / BASE_SPOTTING_EFFECT_FOR_INITIAL_UNIT_TRANSFER_SPOTTING (qword_1433354F8) 同构}; 首中 → sub_140FBAB00 锁定 (设 mission+152 spotting_unit_transfer, writer 键 15490) 返 1; 全部未中返 0 (caller 续搜护航客户)。⚠ 铁路炮支 IDA 伪码 v32 复用失真: 报错式实为 spotter 全零 ∧ 无战斗, 与陆军支同构。

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

ApplySpottingModifiers sub_140FAA680 (navalmission.cpp:4871/4888, df365 复核 df102/df11 全吻合 + 补锚): (死参, a2 侦查值 in/out fixed5 [门 >0], a3 tf [+472 owner/+496 现省], a4 tooltip 可空)。① 值 ×(1 + 修正85 SPOTTING_CHANCE sub_140D6CEA0 + 修正453 SPOTTING_CHANCE_AGAINST_A_COUNTRY)/1e5 — 修正453 = 省+392 控制国关系槽 **rel+304 修正区** (sub_140D23780 恒等) +16 {id u32, value q64} 16B 有序表 sub_14055E360 二分 (全局修正定义表 = qword_14332ED90, 120B/项); v14≠1e5 → tooltip MODIFIER_SPOTTING_CHANCE_MODIFIER 行。② 夜门 = CWeatherManager 每省 DayNight (sub_140F19660) **> 0.8 (80000)** → ×(1 + 修正264 NIGHT_SPOTTING_CHANCE)/1e5。⚠ tooltip 夜行 MODIFIER_NIGHT_SPOTTING_CHANCE_MODIFIER 追加门误用年间乘子 v14≠1e5 判定 (与夜间修正 264 自身中性无关, 年间中性而夜间非中性时夜行不显示 = 引擎 UI 缺陷, df365 新钉)。


枚举表 (名→id 映射 = sub_140660F20 的 **naval mission 支** — 该函数实为类型字符九域分派的多域目标参数解析器, 海军支仅其一):

| id | 名 | id | 名 |
|---:|---|---:|---|
| 0 | MISSION_HOLD | 5 | MISSION_MINES_PLANTING |
| 1 | MISSION_PATROL | 6 | MISSION_MINES_SWEEPING |
| 2 | MISSION_STRIKE_FORCE | 7 | MISSION_TRAINING |
| 3 | MISSION_CONVOY_RAIDING | 8 | **RESERVE_FLEET** (id→名表 sub_140FB65C0 实有此键, navalmission 簇直证; GUI 侧「预备旗」表述限 GUI 语境) |
| 4 | MISSION_CONVOY_ESCORT | 9 | MISSION_NAVAL_INVASION_SUPPORT |

A6 活体读锚 (-human_ai 现场可直接读):

| 锚 | 地址式 | 读法 | 证据档 |
|---|---|---|---|
| 特混舰队枚举容器 | tf_arr = rp(cc+632), tf_n = read_i32(cc+644) | CFleet\* 平表 (per-country; 元素 rp(tf_arr+8\*i)) — 更正: 原「CTaskForce\* 平表」系误认; sub_1406D35A0 = 逐 CFleet\* 平铺其 +184 task_force 容器的收集器 (writer 键 15156=fleet 级/15157=task force 级两级树), 特混任务类型须经 rp(fleet+184) 二级取 CTaskForce\* 后再读 (对 fleet 元素直读 tf+884 越界) | 定案 (§4.31.30 + sub_1406D35A0 双证, 二级展开更正) |
| 特混当前任务类型 | read_u32(tf+884) | EMissionType u32 (0..9) | 定案 (写点直读) |
| 特混内嵌任务对象 | tf+864 | CNavalMission 内嵌 (vtable 0x14297F038); mission+8 = tf 回指 / mission+20 = 任务类型 (= tf+884) | 定案 |
| 任务 spotting 族 | ms = rp(tf+864) | spotting_speed fixed5@+120 / spotting_process i64@+128 (≠0 才写); idpair 门 = 任一 dword≠0: spotting_target@+136 / spotting_convoy_client@+144 / spotting_unit_transfer@+152 / strike_force_target@+160 (后三枚存档未见, writer 支持) | 定案 (savefull 对拍) |
| 在航 naval mission 平表 | M = rp(gs+1688); arr=rp(M+8); n=read_i32(M+20); S=rp(arr+8\*idx) | active CNavalMission\* 容器 (元素 vtable 0x14297F038); ms = rp(S+272), ms_n = read_i32(S+284) | 定案 (§4.16.5) |
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
| 挂载点 | gs+1424 (指针数组), cnt @gs+1436; gs writer 逐元多态键 **11928 (sunk_ship)** |
| ctor | 0X140C2D6B0 |

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CSunkShipInfo | 不序列化 |  |
| +8 | MSVC SSO 32B (size@+24) | name | 空串也写 `""` |  |
| +40 | MSVC SSO 32B (size@+56) | killer_name | 空串也写 `""` | 引号 |
| +72 | uint32 | country | 恒写 |  |
| +76 | uint32 | killer_country | 恒写 | 国 idx → 引号 tag (sub_140BB4E70 直查无 >0 门) |
| +80 | CGameDate (24B 双 vtable) | date | 恒写 (无门 date3) | {vtable1@+80, hours@+88, vtable2@+96}; ctor 哨兵 43808760; writer ADEC0 收 a1+96 = &vtable2; 形态通则见 §3.7a |
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
| RTTI 名 | CSunkConvoyInfo (元素类) |
| sizeof | 24 (元素) |
| vtable RVA | 0x2973C28 (元素) |
| writer | 0X140EB39E0 (块); 元素 writer/reader 与 §4.16.13 CSunkShipInfo 同族 |
| loader | — |
| 挂载点 | gs+1448 (指针数组), cnt @gs+1460 (块键 14369 / 元素键 14370) |

元素主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | month (绝对月序号 = 12×((当前 hours−43800000)/8760)+月) | 恒写 |  |
| +12 | uint32 | convoys | 恒写 |  |
| +16 | tag_id | killer_country | 恒写 | tag 引号 |
| +20 | tag_id | owner | 恒写 | tag 引号 |

> **本域 GUI 类布局**: 见 4.31.29 / 4.31.30 / 4.31.42 / 4.31.44。

> **本域 GUI 类布局**: 见 §4.31.23。

#### 4.16.12a CNavalMission 运行时字段全表 (基 = tf+864; ctor sub_140FA9890 / loader sub_140FB9B30 / writer 0X140FBEA80 三面互证)

| 偏移 | 类型 | 语义 | 写门 | 置信 |
|---|---|---|---|---|
| +8 | CTaskForce* | 宿主回指 | 不序列化 | 定案 |
| +16 | uint32 | 拥有国 handle type 槽 (拷自 tf+472 refid type 段; 解析只读 +16) | 不序列化 | 定案 |
| +20 | uint32 | EMissionType (键 11450 mission) | 恒写 | 定案 |
| +24 | uint32 | 移动目标省 id (回港/入侵跟随/区域漫游; sub_140FB95F0 发 CNavalMissionMoveCommand 后清 0) | 键 333 move ≠0 写 | 定案 |
| +32 | int64 fixed5 | 雷达覆盖合计 (Σ区域雷达贡献, 钳 0..1e5) | 键 12237 radar >0 写 | 定案 |
| +40 | int64 fixed5 | 制空权值 (区域加权平均, sub_140FBD630) | 键 12335 air_superiority >0 写 | 定案 |
| +48 | uint8 | IsInAssignedRegions (sub_140FBE7F0 每小时重算) | 键 12468 is_in_regions ≠0 写 | 定案 |
| +49 | uint8 | 分舰维修旗 (= tf+913; 置位时 HOLD/破交/护航拒接敌; tf 侧写点 = sub_140D77940 OrderToRepair 唯一) | 不序列化 | 定案 |
| +52 | uint32 | **接敌规则索引 navy_engagement_rule** (0=不接敌; ctor 默认 2=medium; 接敌门统一 AGGRESSION_SETTINGS_VALUES[+52] ≤0 拒) | 键 13358 恒写 | 定案 |
| +56 | uint32 | TRAINING 小时计数 (在训练区递增, ≥24 归零+日报; SetType 清 0) | 键 12656 hours >0 写 | 定案 |
| +60 | uint32 | hours_in_mission (非训练型活跃计数, ≥24 归零+日报) | 键 17190 >0 写 | 定案 |
| +64 | i64 (低 32 位) | num_convoys_in_regions (sub_140FBE250 并行重算 Σ; 高 32 位运行时未用) | 键 15540 >0 写 | 定案 |
| +68 | uint8 | 本小时活跃旗 (switch 前置 1; 无敌/无区清 0; 门控 24h 日报) | 不序列化 | 定案 |
| +69 | uint8 | stop_training_at_max_xp (= tf+933) | 键 19076 ≠0 写 | 定案 |
| +72 | SOrderInstanceRef 内嵌 | group_to_escort 订单引用 (空引用判定 sub_1410381D0 — **非活订单时才序列化**, 活订单由订单系统自持; case 9 消费) | 键 15484 | 定案 |
| +96 | CStrategicRegion* | invasion bombardment region (sub_140FBA6B0 设置; case 9 消费/清零) | 键 15483 → region+88 id | 定案 |
| +104 | uint8 | already_spotted (完全侦出锁存, 换目标复位) | 键 15283 ≠0 写 | 定案 |
| +108 | uint32 | hours_in_spotting_region (PATROL 在侦查区递增, 换区/失效清 0) | 键 15290 >0 写 | 定案 |
| +112 | CStrategicRegion* | spotting_region (sub_140FBA7E0 设置连带 +108 清 0) | 键 15285 → region+88 id | 定案 |
| +120 | int64 fixed5 | spotting_speed (本小时侦查速度 sub_140FB0830) | 键 15300 ≠0 写 | 定案 |
| +128 | int64 | spotting_process (检测进度累积, 1e7 封顶 = 完全侦出; 目标/港/型切换清 0) | 键 15280 ≠0 写 | 定案 |
| +136 | refid 8B | spotting_target (敌 TF) | 键 15277 | 定案 |
| +144 | refid 8B | spotting_convoy_client (破交目标护航客户, sub_140FBA990) | 键 15489 | 定案 |
| +152 | refid 8B | spotting_unit_transfer (破交目标海运运输, sub_140FBAB00) | 键 15490 | 定案 |
| +160 | refid 8B | strike_force_target (STRIKE 追击目标) | 键 15281 | 定案 |
| +168 | CStrategicRegion* | accessible_regions_range 锚区 | 键 15292 (⚠ 裸指针 i64 发射/loader 原样回读 — 跨会话陈旧指针, 首小时区域比对自愈) | 定案 |
| +176 | 匿名结构 (NNB 形状) 向量 | accessible_regions_in_fleet per 区域 bool 数组 | 键 15293 | 定案 |
| +200 | 匿名结构 (NNB 形状) 向量 | accessible_regions (舰队区域 ∩ 省区间 ∩ 可达 — 状态机「任务区域」唯一来源) | 键 15299 逐 region id | 定案 |
| +224 | uint32 | hours_to_wait_for_base_check (sub_140FB7630 每小时减 1) | 键 15581 ≠0 写 | 定案 |
| +232 | CStrategicRegion* | convoy_spotting_region (护航客户路线选区 sub_140FBD850 / 运输选区 sub_140FBDAB0) | 键 15491 → region+88 id | 定案 |
| +240 | CFleet* | _pFleet 缓存 (`_RegionRange._pFleet == _pNavy->GetFleet()` 断言族) | 不序列化 | 定案 |
| +248 | uint32 | ppStart (省区间下界) | 不序列化 | 定案 |
| +252 | uint32 | ppEnd (省区间上界, 开区间) | 不序列化 | 定案 |

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
| 装船 | sub_140E286D0 / sub_140E25C60 | 给每师发海路省序移动令 (sub_140BF9A40) + 写 **CUnit+760 回指**; 类型门 = unit+8 ∈ {0,13} (断言 navaltransfer.cpp:659 "Adding unsupported unit to naval transfer.", 闩 byte_14333CFFC), 入侵只收 0 (入侵门 :661, 闩 byte_14333CFFD); 挂接 sub_140E25AB0 的引用合法性门 = ref.h:83 (闩 byte_14332F70C) |
| 取首单位位置 | sub_140E260A0 | 首个有效单位的 **location 对象指针** (CUnit+496, §4.18 location 域; 对象+164 = 省 idx); 无有效单位 → 断言 "no valid units huh?" (navaltransfer.cpp:637, **门 byte_1435E1B51 非 B52**, 闩 byte_14333CFFB) 返 0 |
| 航渡 | phase9 → sub_140EA79F0 → sub_140EA76B0 逐国扫 S+304 | 谓词 sub_140E274C0 (战斗中/目标仍有效/有活单位) → **sub_140E263B0 每小时推进** — 单位沿路径省自走, 失路 sub_140E28950 重寻路, force_revalidate(+94) 每 tick 清 |
| 卸载 | 到达目的地省 | 移出 (unit+760=0 + CancelMovement sub_140BFB4A0 + swap-remove + 退超额船); 师本就在目的省, 无额外落位 |
| 落地 | （普通转移卸载即完成） | 入侵到达段触发**浮动港建造**（落到登岸省控制方名下）+ **on_naval_invasion** 事件 + AI 钩; 冷却 (+96) 由海战火交换设入, 无战斗时每小时递减 |
| 取消 | sub_140E28820 | 单位删除/取消移动/换队三路摘除; 全队空或目标失效 (sub_140700570 目标省控制方敌对, 与 invasion_group 同源) → 下一 tick sub_140E28790 全退护航 + 删除 |

新钉: CStrategicNavy+16 = owner tag u32; CPendingStratNavyTransfer 56B 全布局
(§4.00 待命指令族补全)。is_returning 运行期无置 1 写点 (负发现)。

单位脱离拆分 sub_140EAA5C0 (定案): 断言 transfer ∈ S+304 ∧ NT+88 country == S+16
(:2994) ∧ 单位在 transfer 内 (:3001) → 为该单位造新 transfer (sub_140E25F50 +
sub_140E25AB0 挂接) 并写 **unit+760 = new (唯一写点)**; 新 NT push **归属主国海军
S+304**; 原 NT (NT+68 计数) 归零 → swap-remove 出 S+304 + 虚调析构删除。调用者 =
CUnit 域 sub_1406D2FC0 / sub_1406D2CB0 (单位删除/脱离路径)。

#### 4.16.16 海军侦查/任务效率运行时行为面 (navalmission.cpp 簇; 非序列化)

- **族 A 侦查明细 (9 函数新收)**: 海侦基础概率计算器 sub_140FACD70 (BASE_SPOTTING + FROM_NAVY/AIR/RADAR/DECRYPTION × 天气, SPOTTING_BASE_CHANCE_* 六项 tooltip 分解 — 引擎破交检测与 GUI 同源); 空基贡献 sub_140FAB5F0 (AIR_MISSION_SPOTTING_FACTORS 表 qword_143339848 + **逐小时轮换省采样** `(hours−43800000)%region 省数`); NAVAL_DETECTION_CHANCE_DETAILS 主管 sub_140FAED70 (BASE+雷达+制空 ×1000 ×补给缩放); NAVAL_SPOTTING_* 侦查对决明细行 sub_140FB1860 (追逃速度差选 CATCHING_UP/RUNNING_AWAY 双档); 三入口包装 sub_140FB2840/FB1740/FB15B0 = 运输/入侵、convoy、patrol 三目标类 (37 项 define 全部对名)。
- **族 B 任务效率四件套**: type 3/4/5/6 各一个同骨架特混效率计算器 (舰队内同型计数 ×define ×修正 ÷省区间跨度 → **MISSION_EFFICIENCY_POW_FACTOR 幂曲线**); loc = CONVOY_RAIDING_TASK_FORCE_EFFICIENCY_DESC / CONVOY_ESCORT_EFFICIENCY_FLEET_DESC 等。破交下半段执行体 sub_140FAB010 (接敌现运开战 + 按 AGGRESSION>0/type9 拉敌) 与拦截支路 sub_140FAACD0 (公共低雷区随机选省 + 兵力公式) 补全。
- **CTaskForce 运行时新钉偏移** (十进制): +64 补给度 / +912 任务激活旗 / +916 接敌规则下标 (AGGRESSION_SETTINGS_VALUES qword_143339860 副本) / +1104 任务组舰队回指 / +1108/+1112 任务省区间副本 / +408/+416/+424 对潜/对面/侦查基量; prov 模板 +210 bit0 = IsLand (断言直证)、prov +200 省→海域/区域锚。
- **定点幂原语**: sub_1424EFD10/sub_1424EFB20 = pow(x, exp/1e5) (二参 thunk 第三参 r8 直通); 本簇两类用法 = 饱和曲线 `1e5−1e10/2^t` 与效率幂整形。
- 任务型 id→名表 sub_140FB65C0 实含 RESERVE_FLEET(8) (§4.16.12 任务表 8 行已校正)。

#### 4.16.17 海军视图运行时行为面 (naviesview.cpp 簇 30 函数; 修理/置脏/排序)

- **修船资格过滤器 sub_141807860**: 选区或预建舰清单 → repair_parent (tf+1200) 未设门 → 逐舰回调 ship+8 CIdentifier; 单特混单舰特判路。
- **选区特混批量置脏 sub_141818360**: tf+1881 = 1; 脏位由 sub_1417F8650/sub_140D674D0 消费重算 **tf+1880 修理缓存 bool** (新偏移定案)。
- **选区修理三态分类器 sub_141808040**: 0 无 / 1 需修 / 2 在修 — 唯一消费者 BuildTooltip 的 REPAIR_NOW/_CANCEL/_DISABLED 文案。
- **特混三分区排序器 sub_141806420**: [无活动 | 有活动无修理父 | 修理父已设] (naviesview.cpp:92/93/94 断言即此), 喂 SetType/SetTarget/CancelNavyActivity 三路; 泛型收集 helper sub_1417FF1C0 (OutTaskForces/OutFleets 双出参, 返「是否舰队展开」)。
- **符号实名升级**: 0x141819200 = **CNaviesView::Setup** / 0x14181D070 = **CNaviesView::UpdateButtons** (lambda 符号串直证, 全签名含三组 CPdxArray); 17 胶水块由 ctor sub_1418029A0 接线。
- **新 RTTI 确认弹窗族 3 件**: CConfirmCancelNavyActivityDialog (0x1048) / CConfirmDeleteUnits (0x1048) / CConfirmRemoveAllRegions (0x1008) — 同型族, 布局见 findings。
- 选区表基址 = *(view+48)+1336 (簇内 20+ 处唯一直证形态, *(view+8) 侧未见); CNaviesView+22232 = 舰船选择子件槽 (Setup 直证: sub_141E19760 构造写入, 三函消费)。0x14181BB10 实为选区刷新主链 (快照数组/哨兵/置脏/三连刷新 12 步, §4.16.23)。

#### 4.16.18 CTaskForce 运行时操作面 (taskforce.cpp 簇 33 函数; 非序列化)

簇 = CTaskForce 生命周期 + detached_activity 分离活动操作面 (构造/析构、修理父子枝、合并、送修、
改装、回队、母港选择、spotter/strike 双列表增删、海战句柄); **非 AI 层** (全簇无一函数被 AI 主循环
直调, 任务分派在 CNavalMission/navalmission.cpp 域 — 与 §4.16.5a 同口径负定案)。

新定案函数清册 (书已收 8 件抽验全符, 不复列):

| VA | 行数 | 身份 |
|---|---:|---|
| 0x140D63620 | 367 | **CTaskForce dtor**: naval_headquarter 逐元反注册 (元+48 32B 条目容器双向注销) + 读档门外双列表对清 (strike→sub_140FBA800 / spotter→sub_140FBAC60) + repair_parent 双向摘链 + 逐舰 delete + "_pFleet == nullptr" 断言 (:934) + 容器逐一析构; 尾重写 +824 组 vtable |
| 0x140D72000 | 244 | **ConnectToParent**: 断言自挂/重复挂/父链 12 层环 (:5621..5686); child+1271 清 0 → 逐舰在改线注销 → child+1200/+1204 = 父+24/+28 (自 idpair) → 父 repair_child 查重 push → mode 2/3 并编成需求 → **图标/颜色三槽继承 (+1288/+1292/+1312..+1327)** — tf+1312 颜色继承 = 16B RGBA 全拷 (SetFleet 直证 `*(tf+1312) 16B = *(new_fleet+288) 16B`) → 根父异舰队挂队 → mission (父 reserve 则 8 否则 0) → 尾 TakeOverChildren |
| 0x140D76DD0 | 464 | **按损伤拆舰送修**: 权重 = max−current str (sub_140C38740 − CShip+1784); ≤32 插排/大数组归并 → sub_140D67AA0 取基地路径 → dword_143332608 批量分批走分舰链 (activity=1); 唯一调用者 = sub_140D79900 小时分舰检查 |
| 0x140D67AA0 | 884 | **修理母港打分寻路**: 同盟扩充种子 → 逐国 S+24 基地按战略区分桶 (桶数 = gs+748 区数) → 战略区 BFS → 打分 = sub_141356E90(tf) ± 三 define (见下表, 本方基地减惩罚), 平局按基地省 id 升序; Pathfinder 档位 = 全舰 +1576 bit7 (含空队 → 1) |
| 0x140D695D0 | 249 | 就近可达母港: S+24 基地可用门 → **省对距离表 qword_143339D28 (+672 宽 / +680 数据 / +704 i16 半行索引)** 最小者 → CheckNavalPath 可航门 |
| 0x140D7A180 | 151 | **reinforcing 小时分支**: 无父 → 完结; **父在改装路 (activity 2/3) → 父子换位** (vtable[40] SetName 子承父名, +1264 repair_last_mission 接管, 原父降级为子队); 同区 → 并回 (门 sub_140D79880 + MergeTaskForces); 异区 → 回队寻路 +1816 倒计时 / +1820 退避 min(2×, 24) |
| 0x140D79DE0 | 162 | refitting 小时分支: 补线 (装备 arch≠变体 ∧ ¬在改谓词 ∧ 升级链判定 → 上线) + 二分分裂 (全有线 → FinishRepair 或完结; 有父 → 无线段拆 reinforcing 子队; 无父 → 有线段拆改装子队 + 本体完结) |
| 0x140D6B660 | 603 | 禁动原因文案构造: NO_MOVE_HEADING_HOME_TO_REPAIR / _IS_IN_HOME_REPAIRING / …_REJOIN / _STAY / _RESUME (repair_last_mission==0 分) + NAVY_ACTIVITY_{MOVING_TO_REFIT,REFITTING,REINFORCING}_DESC 按 activity 分派, 逐键追加 \n; repair_target 对象 +192 = CProvince\* / +164 = 省 id |
| 0x140D76260 | 139 | 合成统计重算: tf+312 统计对象复位 → 逐舰累加; **min-speed stat+424 只下探不上探**; 射程基 stat+432 断言 "Navy has no range" (:2720); statId 69 = Σ舰燃料; **全语料无静态调用方 = vtable槽派发** (槽号待裁; 与 army.cpp 框架入口 sub_140C86CC0 两套并存待裁) |
| 0x140D68D90 | 138 | CreateTaskForce: **malloc 0x760 = 1888 B (sizeof 定案)** → ctor → 分配对象 id → vtable[29] (+232) 位置初始化 → 父 reserve 继发 → 挂队 + 注册 |
| 0x140D72C20 | 113 | MergeTaskForces: 逆序摘 src 舰落 dst → 需求合并 → TakeOverChildren 孤儿改挂 → 观察者注册表 qword_14332F698 改挂 → src 摘父链 + 完结 + RefreshAbilities vtable[22] → **sub_1401D7460 延迟删除登记** → dst vtable[29] 位置刷新 |
| 0x140D73920 | 106 | TakeOverChildren: giver 的 repair_child 整枝摘下重挂 root (child==root 断言 :5561); Merge 与 ConnectToParent 共用收尾 |
| 0x140D72A20 | 94 | 分舰去向判定: activity 1 → 修理基地省 / 2,3 → 就近母港 / 0 断言; 唯一调用者 = 分舰链 sub_140D72580 |
| 0x140D744F0 | 147 | MoveToDetachedActivityTarget: activity 1 → 母港省 / 2 → 就近母港 / 其余抛异常; 重发 SetDetachedActivity 后栈构造 **CNavalMoveCommand (12664)** (clear=1, access=2) → IsValid → Execute |
| 0x140D73E30 | 140 | 海区访问级别比对 (小时 tick 消费): fleet+216 舰队目标省区 vs 现处省区, 查 gs+1032 国家link×区 64B 行 (行基+24 数组, 索引 = 区+96), **列 = 全潜艇旗选 +32 (潜艇) 否则 +8** (列值待裁) |
| 0x140D77940 | 86 | OrderToRepair(省): 有海军基地 → SetDetachedActivity(1) + **tf+913 = 1 唯一写点**; 无效警告 (:5043) 回退母港; 调用者 = 海军命令 sub_1413536B0 |
| 0x140D79BA0 | 51 | 编成满足度重算: 沿 repair_parent 走根 (环断言 :3813; idpair 解引 **−16 = 父队基址** — ref 指向父队 +16 处成员) → 自根递归: 父满足度 = 本队舰 + Σ子队 (自算 sub_14198B7D0 + 子合并 sub_14198A9E0) |
| 0x140D64A60 | 91 | OrderRefit: 变体空断言/异常 (:4810/4811) → 国家+3944 生产线逐舰上线 → SetDetachedActivity(3); 调用者 = 小时驱动 + repairing 归队判定 |
| 0x140D64860 / 0x140D645D0 / 0x140D76850 / 0x140D766E0 | 91/91/53/53 | spotter/strike 双列表增删四件: AddSpotter (+1552/+1564) / AddStrikeForceOnShip (+1576/+1588) / Remove×2 swap-remove = **全匹配删除** (命中不提前退出, 同键多条全删, 计数域直接覆写); idpair 键 = 实参 +24/+28 (自 idpair 又证); 断言串两两同文 = 源码复制粘贴 (:4018/4087, :4026/4095) |
| 0x140D6D0C0 / 0x140D64530 | 31/29 | GetNavalBattle 双变体 (const/非 const 两编译产物, 断言门 byte_1435E1B52 :3087 vs byte_1435E1B51 :3107): 首战斗 vtable[11] (+88) == 2 才返 |
| 0x140D765C0 | 44 | 海战侧复位: 战斗 +152/+160 两侧各 sub_141621990 (侧+292 清 0 + 逐元 vtable+72); fleet.cpp 接战两路调用 |

新布局/语义汇总:

| 偏移/对象 | 语义 | 置信 |
|---|---|---|
| tf+24 / +28 | CTaskForce 自 idpair {type, id} | 定案 |
| +824 基站点 (第 4 vtable站) | TListenerTrait\<CCustomizableBuildingItem,1\> 建筑变更监听接口 (ships 容器 tf+840 挂该基站下) | 定案 (vtable 重写直证) / 语义高置信 |
| sizeof(CTaskForce) | 0x760 = 1888 B (CreateTaskForce malloc 直证, 与 writer 全键表上界吻合) | 定案 |
| tf+913 (u8) | 分舰维修旗 (= mission+49, §4.16.12a); 写点 = OrderToRepair 唯一 | 定案 (写点) |
| tf+1600 | std::map 头 (rb-tree, 堆节点 32B +25 = nil 旗), 加/删舰后 sub_140D66390 全量重建 (键链 = 舰装备 arch → def+1312 40B 条目族, 元素门 = CShip+1576 bit39); **+1608 = map size** (0 → 跳过遍历, 新锚); writer 不落盘 | **语义定案 (dg034)**: 值体 = 舰载支援需求条目 {def id@+32, 目标量@+40 (×1e5), 类型@+44, 计数对象@+48 (+16 计数)} — 编成编辑器 tooltip 制海权支逐节点 emit TASKFORCE_SUPPORT_NEED (SUPPORT_TYPE=类型名 / CURRENT=sub_14196A360 算值 / TARGET=+40; 比例条经国+支援加成表 sub_14055E360 查值 → sub_14055AB90 格式化) |
| tf+1640 | 24B 容器 (dtor 析构; writer 不落盘) | 定案 (存在) / 语义未决 |
| tf+1224 目标对象 | +164 = 省 id u32 / +192 = 省 CProvince\*; 推定海军基地建筑 | 推定 |
| CShip+1576 位域 | bit6 capital (已收); **bit7 (0x80) = 全队判定键 → Pathfinder 档位与访问表列选** (推定潜艇类); bit39 = tf+1600 重建元素门 | 位机制定案 / 0x80 名待裁 |
| gs+1032 表 64B 行 | 行基+24 数组, 索引 = 区+96; 双列 +8 (水面) / +32 (潜艇), 列值待探针 | 高置信 (结构) |
| 省对距离表 | qword_143339D28 +672 宽 / +680 数据 / +704 i16 半行索引 | 高置信 |
| vtable[11] (+88) | 战斗类型查询 (返 2 = 海战) | 定案 |
| vtable[29] (+232) | (tf, CProvince\*) 位置/编成初始化钩 | 推定 |
| vtable[40] (+320) | SetName (reinforcing 父子换位用) | 定案 |
| qword_14333D528 | 空 idpair 常量 | 定案 |
| 修理打分三 define | qword_1433326B0 NAVY_REPAIR_BASE_SEARCH_SCORE_PER_SHIP_WAITING_EXTRA_SHIP / qword_143332778 …_SCORE_PER_SLOT / dword_143332824 …_BOOST_FOR_SAME_COUNTRY (ref/defines_map 直证) | 定案 |

未决: 0x140D76260 vtable槽号 (需 vtable 数据落盘) / tf+1600 map 键值业务名 / gs+1032 列值 /
并队门 sub_1406DEDF0 语义 / 0x140D67AA0 逐区边权细节。

#### 4.16.19 fleet.cpp 簇对账增补 (CFleet 运行期行为层; 12 函数闭环)

**提督解析器 sub_140D64510** (定案, 12 行): `*(tf+832)` (tf 父舰队 CFleet*, §4.16.4) → sub_140D50EE0 读 fleet+176 leader idpair → sub_14221F310 → CCharacter*; 两消费点 = AddTaskForce 侦测折减 (提督 stat 86 加成, §4.22.5a) 与 RemoveUnit 参战将领保留判定。

**CFleetRegionRange 实名** (定案, 新源文件锚 fleetregionrange.cpp): 范围表元素 =
`{_pFleet CFleet* @+0, _Range.first u32 @+8, _Range.second u32 @+12}` (断言 :7/:12/:18/:23
直证); 助手 0x141987EA0 = begin() = `GetRegions().data() + 8×_Range.first` (:7/:12 双断言门) /
0x141987F90 = end() = `GetRegions().data() + 8×_Range.second` (:18/:23 双断言门) /
0x141987CA0 = 段内成员判定 (在 [first, second) 下标段内线性扫 region 指针, 命中返 1)。**结构体布局 (本批补)**: 16B {CFleet* @+0; int first @+8; int second @+12}; CFleet::GetRegions() = {data @+72, count @+84}; 四断言 fleetregionrange.cpp:7/:12/:18/:23 = _pFleet ×2 + first/second 上界。
CFleet::GetRegions() 侧证: 数据 @ CFleet+72 (8B 元 = CStrategicRegion\*), 计数 u32 @ CFleet+84 —
与 CFleet 表「+72 strategic_region {d@72, cap@80, count@84, alloc@88}」吻合; 断言边界语义 = first/second 允许 == size (空段在尾合法)。

#### 4.16.19a 海军剧场选择集合法性谓词 (navytheater.cpp 0x141518490)

**调用链**: GUI 谓词 0x141E67BF0 (读 UI 单例 qword_14332F6A0+1336 选择集) → sub_140DC7320(ui_session+1336, &fleets, &taskforces) **按 CSelectable type id 分拣选择集** (type 11 = CFleet, 基址 = 链节点对象指针 −24; type 1 = CTaskForce, 基址 = 节点对象指针) → 0x141518490(fleets, taskforces)。选择集链表形态与 §4.15「SelectionList = qword_14332F6A0+1336, 链节点 {+0 对象指针, +16 next}」互证; **对象侧 type id 落在 selectable+8** (CFleet selectable@+24 → +32 = 11, 与 CFleet 表「+32 CSelectable type id = 11」吻合; CTaskForce selectable@+0 → +8 = 1)。

0x141518490 六判据 (全部定案):

| # | 判据 | 字段锚 |
|---|---|---|
| 1 | 全部选中舰队 owner 同国 (tag_id) | CFleet+168 = CCountry\* → cc+8 = tag_id; 或 CTaskForce+472 = owner tag_id u32 直读 |
| 2 | 全部选中特混 owner tag 匹配 (或 sub_140BB52F0 同国等价, 含流亡) | tf+472 |
| 3 | 选中舰队集恰为某战区组完整成员集 (全队 fleet+208 同组 且 组 count@+44 == 选中数) → 必须同时选中特混, 否则非法 | CFleet+208 → 组+32 容器 count@+44 |
| 4 | 选中特混须同属一父舰队 (tf+832 全等) 且父舰队 tf 计数 == 选中数 (= 父舰队完整特混集) | CTaskForce+832 = 父 CFleet\*; 父舰队 +184 容器 count@+196 |
| 5 | 父舰队须有战区组 (fleet+208) 或为预备舰队 | :95 断言 "( pTheaterGroup \|\| pFleet->IsReserveFleet() ) && A fleet should either belong to a theater group or be a reserve fleet."; IsReserveFleet = sub_140D57C70 (§4.16.20 定名) |
| 6 | 判据 4 成立且父舰队战区组成员数 == 1 → 非法 | 组+44 == 1 |

> **CTaskForce+472 = owner tag_id (u32, 非 CCountry\*)** — 判据 1/2 直接以 u32 比 tag 且空值/同国分支均按数值处理 (定案; 与 CCountry+8 同源)。

**RebuildRegionRanges sub_140D530E0 算法定案**: gs+2618 真 → 抑制直返; 自引用节点复位
(fl+120 = fl / +128 = 0 / +132 = 区域数) → 范围表 count@+108 清 0 → 无区域分支 =
自引用节点逐 TF mission 挂载 (推定转实证) / 有区域分支 = **strategic_region 数组 (+72)
就地重排为组序** (sub_140D539A0 产出 24B 组条目 → 索引排序 → sub_140185E10 重排) → 逐组
切段 push 范围表 → :1788 覆盖完整性断言 → 尾分桶重算。**可达性自检 sub_140D51360**
(新定案): 栈式传播 (邻接 ∈ 舰队区域 + 通行权 bit1 门), 段覆盖 ≠ 跨度返 1 → CFleet::Update
触发重建; 带出 CStrategicRegion+176/+188/+200 邻接块交叉证据 (96B/邻接区, 推定, region 域
待收)。

**SetHomeBase sub_140D59E00**: :2173 断言; 旧基地注销 sub_140EAE740 / 新省注册
sub_1414E4350→sub_140E9F130 对; propagate 逐 TF 门链 (海战门 GetNavalBattle / 距离查询
sub_140EA5F70 / vtable[14] 谓词) → 命令投递 (qword_14332F698 vtable[17] → malloc 72 →
sub_141346DA0 → sub_142250B00 入队); 配套自动母港重选 sub_140D59410 (门 = fl+260
automated_homebase); 簇外邻居 sub_140D58120 = 读档/新建后无 home_base 修复形态。
**AddTaskForce sub_140D51010**: 他队继承 home_base + 旧队移除; 无家港就近选基地; 幂等
push (:608 锁断言); vtable[22] RefreshAbilities; **CFleet+136 运行时写点 = Add/RemoveTaskForce
双点归零** (入侵支援核查倒计时复位, 与 SetType 进出 type 9 清 0 同族)。**SetColor 链**: fl+288 16B RGBA 全拷 + use_fleet_color getter sub_140D74210 =
tf+1292 直证; SetDefaultColor = fleet_id 取模色表 (dword_143338D3C/qword_143338D30)。
**CFleet::Update sub_140D577F0**: leader 更新 → TF 指针快照迭代 (防容器变异) → :548/:550
双断言 (同国判定 sub_140BB52F0 流亡等价) → 逐 TF vtable[18] 派发 (结构定案, 槽 RVA 未决)。
**CTaskForce 虚槽新证据**: vtable[13] = GetName (trace 消费) / vtable[22] 第二消费点 = AddTaskForce
挂队尾 / vtable[14] = 7 参谓词 (待裁)。**qword_14332F698 补证** (定性改「持 vtable 全局管理器:
选中对象注册+注销 [dtor sub_1402A00F0] + 命令工厂投递 [SetHomeBase 通道]」, 具体身份仍
待裁；**CCompactShipEntry ctor 0x141E10F30 第二实参 = qword_14332F698+1272** (该全局持 vtable, vt+128/+184/+200 有调用点, 含 +1264/+1272 子表 — §4.30 落卡)。**分桶网络补全**: sub_140D51B80 全部 8 调用点名单; 10 桶 = 10×24B 栈容器
(0xAu×0x18u 直证), 键 = tf+884 mission type。**gs+2618 = 重建抑制旗** (3 消费门) /
**gs+2617 = 分桶重算门** (推定, 运行时-only)。

**sub_14221F310 空哨兵判读收口 (定案)**: 两处独立调用 (CNavyTheaterFleetRowItem 0x141E15E20 / naval_utility 0x1415C6F30) 同形用法 = `v = sub_14221F310(idpair); base = v − 16; if (v != 16)` → **返回 16 = 空哨兵, 有效对象 = 返回值−16** (另有 v==0 先判分支; 与本表 tf+1024 行「不可解析返 16 哨兵」一致, 原未决项关闭)。

未决: vtable[14]/vtable[18] 槽 RVA; qword_14332F698 身份
三说并存; sub_140D539A0 分组键; desc+210 bit1 位域; CStrategicRegion 邻接块归属 s4_25 域待收。

#### 4.16.20 navalcommands.cpp 簇对账增补 (海军命令执行与预备舰队体系; 11 函闭环)

清册 (11/11 函体内含 navalcommands.cpp 路径锚; 命令行对号见 §4.33.11/12):
A\* 寻路核心 0x14134FCC0 (384) / 舰数组→预备/新建特混 helper 0x14134DD50 (250, 15158
与 15172 Execute 共用) / CAutomateHomebaseForFleetCommand::Execute 0x1413508D0 (28) /
CNavalMissionSetTypeCommand::Execute 0x141351C50 (184) / CNavyDetachShipsAndMerge
Command::Execute 0x141352E90 (212) / CReorganizeShipsCommand::Execute 0x141353AE0 (713) /
CSetFleetCommand::Execute 0x141355060 (525) / CSetFleetHomeBaseCommand::Execute
0x1413559E0 (247) / CSetNavalRegionAccessCommand::Execute 0x1413560B0 (356) / 特混→预备
舰队落位 helper 0x141357840 (127, 15172 专属) / 预备舰队合法性+清任务 helper 0x141359EE0 (48)。

**CFleet::IsReserveFleet 定名** (sub_140D57C70; :1237 断言文点名直证): 判据 = 舰队有特混
(舰队+196 ≠ 0) ∧ 首特混任务类型 tf+884 == 8 — **预备舰队 = 运行时任务态, 非持久标志位**
(15165 :2865 拒绝门 / 0x141359EE0 合法性门 / 15174 预备舰队路由 / 15179 预备簿记
sub_140D54430 四函交叉复用)。伴生谓词 sub_140D5A430 = 预备化一致性 (全队按 repair_parent
解析体归组须同 key; 空队恒真)。

**枚举补值** (定案): CTaskForce::EActivity — Mission = 0 (:1270 断言文) / Reinforcing = 4
(:1253) / 训练活动 = 3 (高置信, 停训门 sub_140D67380 配对) / 5 = 未名待裁 (与 1 同组在
16738 move 门排除); 任务类型 (tf+884) — **7 = MISSION_TRAINING** (:1270) / **8 = 预备任务**
(四函交叉), 与 IsValid 上界 ≤9 相容。

**CTaskForceIdentity (128B) Execute 消费点布局** (定案): +32 CColor 16B 带 vftable (旗@+48)
/ +64 u8 (旗@+65) / +68 u32 (旗@+72) / +76 任务类型 (旗@+80; ==8 走预备舰队) / +84
stop_training (旗@+85) / +88 舰 idpair 向量 {data@+88, cap@+96, count@+100} / +112 目标舰队
CRef {type@+112, id@+116} (空 → throw :3567); +0/+16/+120 Execute 未消费待裁。

**15174 CReorganizeShips 全机制** (定案): 舰按所在特混省索引 (tf+496+164) 稳定排序
(≤32 插入 sub_141345C10 / >32 归并 sub_141345D20) → 按省切组, 每组 CreateTaskForce
(组首舰旧 tf+496 省, related = 并入目标) → optional 逐项施用 (色/旗/+68/+76 任务类型+
stop_training) → 旧 tf 腾空 (tf+840 容器 count@+852) 即删 → 本地玩家 UI+1336 选中
先清后加 (仅首组清)。

**16738 move 旗机制** (定案): 对舰队每个可动特混 (activity ∉ {1,4,5} ∧ 非战 ∧ 不在新省)
**栈构 CNavalMissionMoveCommand → IsValid (sub_14134B970) → 直调 Execute
(sub_141351260)**, 不经 post — 「Execute 无自调 IsValid」横断不破, 反增栈构子命令样板
(与 12664 引擎级联同款)。

**14858 clear 旗语义** (定案): clear=1 = 先生成全海区默认表 (access=0, 1..gs+748−1) 再对
载荷区写值; 元素 = {region_id u32, access u8} 8B; 施用门 = 区域对象+160 > 0; gs+368 = 海区
对象表, **gs+748 = 海区总数** (§4.11.19 未决项闭合)。

**海军 A\* 寻路核心** (0x14134FCC0, 384 行; 两调用点均在 12664 链 sub_141359780 内,
第 4 参 = gs+700 节点总数): 节点描述符 = **省+184 对象** — 边表 {data@+112, count@+124},
48B/边 {邻接节点索引@+8, 边成本@+24}; 节点位置 x@+184/y@+188; 每跳附加成本@+192
(desc+210 陆/湖旗同对象, §4.14 互证)。节点索引 = 省+164; 节点记录 24B {省*, 父记录*,
f@+16, g@+20}; 优先队列 = pdx heappriorityqueue (8B 项 {优先级, 节点索引})。g = ceil1e5
(边成本)/1e5 + 节点+192 附加 + 1; h = 目标与邻省位置的**地图环绕欧氏距离** (环绕半宽 =
qword_143339D28+64); 命中沿父链回溯 (sub_14134B6F0)。边成本量纲未追源, 系数入书需
PE 侧验算 (核心纪律 8)。

**CFleet/CTaskForce 字段消费点增补** (定案): CFleet — +8 舰队自引用 idpair / +72/+84 任务栈
(sub_140D59520 清空) / +168 属国 / +184/+196 特混指针数组 (sub_140D230E0 直返) / +208
战区组 / **+260 自动母港旗** (10417 翻转 + sub_140D59410 重估: 首特混省或任务栈定基准省 →
sub_140EA0000 找基地 → sub_140D59E00 落母港); CTaskForce — +24 自引用 idpair / +248 位置
省 id / +840/+852 舰船容器 (sub_140D6EEB0 直返; 整队判定 = 选中数 == count) / +1176/+1188
停泊子特混表 (换队随迁) / +1208 detached_activity (EActivity)。

**错误机制三组辨析** (本簇实证, 勿混): assert 组 = sub_1424C8080 (latch + debugbreak);
**throw 组 = sub_1424C9240 → sub_1424C9AE0 (buf, file, line, 65540) → sub_1424C8E30
(组消息, 可内插) → sub_1424C89E0 (抛 ios_base 异常), terminate 仅兜底** — 15179 :701 带
舰队 id 内插、15158 路 :134 异省串均此组; 日志组 = sub_1424C8950+8E60 (无中断)。与
CLogStream 行式日志 (§4.12.9b) 共四形态。

未决: CTaskForceIdentity +0/+16/+120 语义 / EActivity=5 / CreateTaskForce 第 3 参精确
语义 / sub_140D51B80 巨函 (~1200 行) 骨架级 / gs+2613 旗 (0 = 才做母港迁移跟随) /
边成本量纲。

#### 4.16.21 ship.cpp 簇对账增补 (舰船运行期; 12 函闭环)

清册 (12/12 函体内含 ship.cpp 全路径锚): CShip reader vtable[4] 0x140C3C5A0 (467) / 海战统计
查询 0x140C34A50 (389) / **统计重算真身 0x140C3D090 (281)** / 关键部件损伤施加
0x140C34500 (267) / 逐舰小时 tick 0x140C3C060 (217) / CShip writer vtable[2] 0x140C3E6C0
(150) / SetPrideOfTheFleet 0x140C34280 (120) / 装载后舰名解析 0x140C3B840 (98) / 调试
join helper 0x140C2F160 (98) / attrition tick 0x140C32EB0 (45) / SetShipName (deprecated)
0x140C3D7E0 (28) / GetSubAttack 包装 0x140C3A890 (26)。

**统计重算真身** (0x140C3D090; 解 §4.16.3「sub_140C21570 待裁」): 装备×(1e10/池值) 累加 +
定义本体 + 损件惩罚直写 **sh+288+8×statId** + 强度重标 + org cap (mod 71/638 +
TRAINING_ORG 门) + 等级槽 +2064。主统计数组基址定案与内部自洽见 §4.16.3。

**海战统计查询** (0x140C34A50; 定案): 签名 (out, sel 0..4, tf, ship, def, combat|0),
sel = 轻炮攻/重炮攻/潜攻/鱼雷/装甲; 型别位 0x80 潜/0x40 主力/0x100 屏卫分支 × 对国修正
(modifier 194..199/456..461/439..440/263/464..465); PotF 参战加成; OUT_OF_FUEL_* 燃料罚;
终式 = base×(1e5+Σmod)/1e5。

**critical_damage 全链** (定案): 施加 0x140C34500 = 候选 (sh+1360 critical_parts + sh+96
树) 按权重 random_fixed(:1935) 加权选件 → {条目*, 次数} 入账 (元素 +8 = 受损次数) → 重算
→ tf vtable[22] 通知; writer :1159 断言 = 发射循环 (「名」计数格式); reader 键 15357 按名经
game item DB 回填。

**逐舰 tick 三件** (定案): ① 训练经验 (UNIT_EXP_LEVELS/TRAINING_MAX_LEVEL 停训门;
+69 stop_training_at_max_xp 仅 type==7 互证) + 训练回补 TRAINING_MIN_STRENGTH; ② 海难/
水雷判定 (mod 425/426, NAVAL_MINES_ACCIDENT_* 四 define, PotF 双减免, random_fixed
:2770/:2786) → 真海难沉没归因链 + 事故报告; ③ **attrition tick: sh+1816 = attrition
累积** (任务中 ×ATTRITION_WHILE_MOVING_FACTOR 衰减, 停泊不衰减) → org 流失 + 概率强度损
(ATTRITION 四 define)。

**杂项定案**: SetPrideOfTheFleet = 舰 refid **type=51** 水位分配 + 资格位 (0x40/0x400000/
0x2000000000 型别或池模块, 业务名待裁) + 流亡排除 (throw) + cc+592 登记; 舰名延迟求名链 =
自定义名(+2080) → 有序(+2112) → 无序(+2116) → 兜底生成, cc+120 注册, 占名 throw
(0x140C3B840; 自定义名非空判 = 读其 32B 串的 size 字段 +2096 = +2080+16; 名管理器经
*(a1+1832)+472 → +120 注册器, 占名 throw 串 "...The division name is occupied: ");

调试 join helper 0x140C2F160 = std::string join ('\n' 分隔): 累加各元素串长 → 分配
→ 尾追加 '\n' (size==cap 走 sub_1424C8E60, 否则直写 `*(WORD*)(buf+size)=10`) →
两半拷出; 空范围 = latch 断言 (ship.cpp:692) + SSO 空串 (size=0 / cap=15)。
SetShipName deprecated assert 仍执行写名 (非删除); reader 补三点 = 键 14596≡15500 共用
分支 (占名 throw)、键 11930 负值钳 0、15357 DB 回填。

**工具防复发**: sub_142233DB0 = clausewitz random_fixed(file, line) (确定性 RNG,
rand()%100000), 非 define 代理 — 形态与 define 读取相似勿混。

未决: sh+96 容器身份 / 候选条目 RTTI 名 (§4.18.19 B 项) / sel=3 wrapper 推定 / PotF
资格位业务名 / sh+288 L1 探针复验 (读 sh+808 期待 reliability 0.8)。


#### 4.16.22 打击舰队 GUI 状态文本与接敌概率模型 (naval_mission_unit_item.cpp; sub_14198DD80 481 行)

**打击舰队 GUI 状态文本构建器** (行件数据源; 被行构建器 sub_14198E690 逐特混舰队调用; :347 断言 `!"This should not happen"`, loc 串 9 枚 NAVAL_STRIKE_FORCE_STATUS_*):

| tf 偏移 | 类型 | 本函数消费 |
|---|---|---|
| +436 | uint32 | > 0 → 直接 STATUS_IN_COMBAT (经 sub_140C00000) |
| +864 | CNavalMission 内嵌 | 传入 sub_140FB4390 / sub_140FB8200 |
| +884 | uint32 | == 2 (STRIKE_FORCE) 才进入状态机, 否则断言 → STATUS_NOT_READY (= mission+20 EMissionType) |
| +916 | uint32 | 接敌规则索引; == 4 → 直接 STATUS_READY; 否则取接敌设置名拼 tooltip (= mission+52 navy_engagement_rule) |
| +1024 | uint32 | strike_force_target idpair — type (= mission+160); 经 sub_14221F310 解析, 不可解析返 16 哨兵 |
| +1028 | uint32 | strike_force_target idpair — id (= mission+164) |
| +1208 | uint32 | detached_activity 枚举; ≠ 0 → STATUS_NOT_READY |
| +1856 | 32B 串容器 | target_ship_types; 经 sub_140FB8200 按目标舰型过滤敌舰, 空容器 → 恒允许接敌 |

> a3 = 敌方上下文 (推定 = 敌 CTaskForce): idpair {type@+24, id@+28} + 舰队容器经 sub_140D6EEB0 解析; a4 = uint8 情报等级 (0..250)。⚠ IDA 伪码失真两处已按汇编校正: ① 形参声明 `_DWORD*` 致 `a2+216` 字面读作 +216, 实为 **+864** (= CNavalMission); ② sub_14198A130/sub_141989B00 内除法魔数与 int64 极值哨兵分支伪码省略。

状态六态判定序:

1. tf+436 > 0 → STATUS_IN_COMBAT
2. tf+1208 ≠ 0 → STATUS_NOT_READY
3. tf+884 ≠ 2 (非打击任务) → 断言 → STATUS_NOT_READY
4. mission+160 目标可解析 (≠ 16 哨兵): 目标 idpair == a3 idpair → STATUS_ENGAGING; 否则 → STATUS_ENGAGING_ANOTHER
5. tf+916 == 4 (最高接敌设置) → STATUS_READY
6. 情报分档: a4 < 100 → STATUS_NOT_ENOUGH_INTEL; a4 ≥ 250 走**精确强度比路径**; 100 ≤ a4 < 250 走**概率路径**

**精确强度比路径** (a4 ≥ 250): ratio = clamp(100000 × 敌估计 / max(我估计, 10000), 0, 1000000) (sub_14198A130; 任一方为 int64 极值哨兵 → ratio = 1000000 = 永不接敌); 接敌阈值 (AGGRESSION_SETTINGS_VALUES[qword_143339860][tf+916], 分舰维修旗 tf+913 置 → 阈值 0) > ratio → STATUS_READY 否则 STATUS_ENEMY_TOO_STRONG。

**概率路径** (100 ≤ a4 < 250, sub_141989B00): 半界 = (a4 ≥ 150) ? INTEL_LEVEL_MEDIUM_STRENGTH_ESTIMATE_HALF_RANGE_PERCENTAGE : INTEL_LEVEL_LOW_STRENGTH_ESTIMATE_HALF_RANGE_PERCENTAGE; (lo, hi) = 敌强度估计区间 (sub_14198D790, 按半界百分比我方估计上下浮动); r_lo = 100000×lo/我, r_hi = 100000×hi/我; 阈值 ≤ r_lo → prob = 0; r_lo < 阈值 ≤ r_hi → prob = clamp(100000×(阈值−r_lo)/(r_hi−r_lo), ≤99000); 阈值 > r_hi → prob = 100000。prob ≥ 100000 → STATUS_READY; ≥ THR_VERY_LIKELY → VERY_LIKELY_TO_ENGAGE; ≥ THR_LIKELY → LIKELY_TO_ENGAGE; 0 < prob < THR_UNLIKELY → VERY_UNLIKELY_TO_ENGAGE; ≤ 0 → STATUS_ENEMY_TOO_STRONG; 其余 → UNLIKELY_TO_ENGAGE。

> 阈值不等式方向按汇编常量定案: THR_VERY_LIKELY > THR_LIKELY > THR_UNLIKELY > (VERY_UNLIKELY / ENEMY_TOO_STRONG); prob ∈ [0, 100000] 且 99000 上钳 (故 STATUS_READY 的 ≥100000 只能由「阈值高于整个估计区间」的确定分支达成)。非 READY 各态均追加换行 + 接敌设置名 tooltip (NAVAL_STRIKE_FORCE_STATUS_ENGAGEMENT_SETTING_DESC + `SETTING` 槽 = 设置名 loc)。

define 落名 (defines_map_1193 直证):

| 全局 | define |
|---|---|
| qword_143336C10 | NAVAL_STRIKE_FORCE_ATTACK_LIKELYHOOD_THR_VERY_LIKELY |
| qword_143336D60 | NAVAL_STRIKE_FORCE_ATTACK_LIKELYHOOD_THR_LIKELY |
| qword_143336E78 | NAVAL_STRIKE_FORCE_ATTACK_LIKELYHOOD_THR_UNLIKELY |
| dword_143336068 | INTEL_LEVEL_LOW_STRENGTH_ESTIMATE_HALF_RANGE_PERCENTAGE |
| dword_143336138 | INTEL_LEVEL_MEDIUM_STRENGTH_ESTIMATE_HALF_RANGE_PERCENTAGE |

未决: a3 敌方上下文类属 (idpair@+24/+28 + 舰队容器消费双证, 无 RTTI 直查) / sub_14198D790 双输出语义 (推定 敌强度估计区间上下限) / 行件宿主类名 (上游 sub_14198E690 未整读)。

#### 4.16.23 CNaviesView 海军总览视图全案 (naviesview.cpp; 30 函 — 选区驱动的按钮回调域)

断言路径串 `source\interfaces\naviesview\naviesview.cpp` 40 处直证零伪影。主类 CNaviesView (37048B, vtable §4.30.17 已载), 符号实名两枚 = Setup 0x141819200 / UpdateButtons 0x14181D070; 三大件 = tt[0] BuildTooltip 0x141809190 (2366 行) + 选区刷新主链 0x14181BB10 (971 行) + UpdateButtons (733 行); 余 22 函几乎全为「收集选区 → 过滤 → 构造命令 → IsValid → 投递」按钮回调骨架 (16 函共享 :162 混编断言 `OutTaskForces.IsEmpty() && "We have a mix of task forces and fleet in the selection!"`, latch byte_14338B16C/_16D/常态三枚同文共享)。

选区收集标准四步骨架 (16 函复用): ① sub_140BC30C0(*(view+48)+1336, &iter) 选区链遍历 → ② 元素+8==1 舰队条目 sub_140D64500 (CTaskForce::GetFleet) 收集去重 / +8==11 特混条目元素-24 直收 CTaskForce* → ③ 两类并存 :162 混编断言 → ④ 舰队展开 sub_140D230E0 (GetTaskForces), 过滤 repair_parent (tf+1200/+1204 双零或 resolve 失败) 并入 tf 清单。

**BuildTooltip (0x141809190) 分发槽表** (按 `a1[槽]==a2` 按钮指针分发; 键流定案, 函数体串直证; ⚠ 与 Setup 绑定槽存在语义错位 — Setup 把 btn_merge 绑到 +36912 而本表 +36912 为 AUTO_REINFORCE 分支, 候选解释 = 绑定 helper sub_14172D090 首参非按钮存储槽或存在平行按钮区, 待活体对拍, 两表暂并列):

| 槽偏移 | tooltip 键 |
|---|---|
| +36640 | NAVAL_BTN_REMOVE_REGIONS (+_NO_REGIONS) |
| +36648 | ALL_TASK_FORCES_REPAIR_NOW / _CANCEL / _DISABLED (三态 = sub_141808040 返 0/1/2) |
| +36848 | SHIP_REFIT_TOOLTIP (+_NO_SHIPS_TOOLTIP / _NO_COMPATIBLE_DESIGNS_TOOLTIP; 经 +22232 子件链取舰/设计计数) |
| +36856 | SELECTED_TASK_FORCES_ARE_ALREADY_RESERVE_FLEET / SET_SHIPS_AS_RESERVE_FLEET / SET_TASK_FORCES_AS_RESERVE_FLEET (分支门 = view+204) |
| +36864 | NAVY_SELECT_HALF / _NEED_MORE_THAN_ONE_SHIP |
| +36872 | NAVAL_GUI_BTN_MERGE (disabled → 选区计数 + 合并预览 sub_1406DEDF0) |
| +36880 | NAVY_SPLIT_TASKFORCE_IN_HALF / _TOO_SMALL |
| +36896 | AUTO_BALANCE_SHIPS_IN_TASK_FORCES (disabled → 详情 sub_1418085F0) |
| +36904 | NAVAL_BTN_SET_TARGET / _NO_TASKFORCE (+_DELAYED_DESCRIPTION) |
| +36912 | ENABLE/DISABLE_TASK_FORCE_AUTO_REINFORCEMENT (+_DISABLED_FOR_DETACHED + _DESC) |
| +36928 | 修理拆分开关 ENABLED/DISABLED + NAVY_REPAIR_POLICY_SPLIT(_MIXED) + _DESC (伴生 +36936) |
| +36944 | NAVY_REPAIR_PRIORITY (+NAVY_REPAIR_POLICY_MIXED / _BLOCK_BECAUSE_DETACHED) |
| +36960 | ENABLE/DISABLE_TASK_FORCE_UNDERWAY_REPLENISHMENT (+_DISABLED_FOR_DETACHED) |
| +36976 | NAVY_AGGRESSIVENESS (SHIP_MIXED/_CURRENT_AGGRESSIVENESS_LEVEL + _N) |
| +36992 | NAVY_CARRIER_DEFENSIVE_STANCE (+_SELECTION_CURRENT/_CONFLICT) |

非按钮分支: 任务按钮循环 0..9 查 `btn_mission<id>` 件 (缺件 → "Missing button for naval mission id <id>"); 匹配过滤 = tf+884 任务类型, 任务数据 sub_140FB3600(tf+864, id, out); 任务 id 5/6 走 define 门特判。任务目标按钮行 (view+36752 容器 48B 元: +8 串 / +40 按钮) → NAVAL_MISSION_TARGET_IS_SELECTED/_DESELECTED。舰队条目尾 = navalmission 文案族 (任务名/效率/描述) + raid_ship_source_move_warning。

**Setup (0x141819200) 全窗构建**: 旧观察器/下拉析构 (+36392/+36408/+36416) → 按名查件 (navy_box_background 绑观察 this+40 / navy_box → +36776 / slider → +36400 内部指针 → this+92) → 任务按钮循环接线 (胶水块+2880) → 按钮绑定 helper **sub_14172D090(槽地址, 父件, 名串, 胶水块, 观察器)** 五参形态:

| 件名 | 写入槽 | 胶水块 |
|---|---|---|
| btn_remove_regions | +36680 | +4168 |
| btn_exclude | +36896 | +9320 |
| btn_select_half | +36904 | +10608 |
| btn_merge | +36912 | +11896 |
| btn_split_in_half | +36920 | +13184 |
| btn_create_new_from_selected | +36928 | +14472 |
| btn_taskforce_o_matic | +36936 | +15760 |
| btn_upgrade | +36888 | +6744 |
| btn_repair_now | +36688 | +19624 |
| btn_reinforce | +36952 (+36960 观察器) | 直连 +8032 |
| btn_toggle_split_for_repair | +36968 (+36976 观察器) | 直连 +18336 |
| btn_underway_replenishment | +37000 (+37008 观察器) | 直连 +17048 |

三下拉: defensive_stance → +36696 (观察器 +37032, 图标 +37040) / aggressiveness → +36704 (+37016, 按钮 +37024) / repair_priority → +36712 (+36984, 图标 +36992); 选项网格 = define 门 54 → dword_1433398E4 项 / 5 项 / 4 项逐项入 button_grid。子件构造: +22248 CMoveShipsWindow / +22240 CNavyLeaderWindow / +22216 CTaskForceCompositionEditor / +22200 detailed_fleet_list / +22208 名件 / **+22232 舰船选择子件 (sub_141E19760 构造)**。任务按钮缓存数组 (+36792 data / +36800 count, 48B 元, 元+4 占用旗) 重建 + FNV-32 (素数 16777619) → +36784 RH 表; 尾 handler 空断言 :1696。

**选区刷新主链 (0x14181BB10, 书旧定性「Reload 辅助」细化为选区刷新主链)** 12 步要点: 空选区早退清理名册态; 标准四步收集; **view+232..+244 = 选区 idpair 数组 {data@232, cap@236, count@244}** (逐条 resolve 失效即移除); view+224/+228 上次选区哨兵变化广播; **view+257 = 海军旗** (多选清 0 / 单选按 fleet+84 区域计数置值, 书「handler+480 态 +257」精确化 = 本类字段); view+256 舰船详情 pending 旗 (置位时修船资格过滤 sub_141807860 → 喂 +22232 件, 用后清 0); **view+36840..+36852 = 选区 TF 快照数组** (新旧 memcmp 变化 → sub_141818360 批量置脏 + 覆写); 三连刷新尾链 sub_14181DE80 → UpdateButtons → sub_14181E480; a2 弹窗树遍历有摘除 → CNavyCancelActivityCommand; 单 tf 任务类型 8 (reserve) 时 navy_box 显示所属编组名/色带 (经 view+36728 scoped ptr); 选择计数文案 = fleet+36 旗 → ALL_TASKFORCES_SELECTED / 单选 ONE_TASKFORCE_SELECTED / 多选 MULTIPLE_TASKFORCES_SELECTED。

**UpdateButtons (0x14181D070) 驱动逻辑要点**: tf 数空断言 :2177; 任务按钮缓存 RH 表遍历 (pdx_robin_hood_table 迭代哨兵断言 latch byte_14338B165); btn_exclude 单选 hide / 首个非 reserve tf → 显; define 门 54 可自动补员过滤 → 防御姿态观察器同步; 合并预览 (多选 sub_1406DEDF0 与 BuildTooltip 同源); btn_reinforce 按 Σ无修理父舰数与谓词二选一; gs 玩家国 (+328 槽) → 补员观察器; strike force (tf+884==2) 存在 → aggressiveness 网格显隐。

**22 回调定性表** (命令 ctor 全部直证新钉):

| VA | 行数 | 定性 | 命令 ctor |
|---|---:|---|---|
| 0x141812770 | 524 | 取消活动回调 (弹窗树联动) | sub_141347BD0 = CNavyCancelActivityCommand (15181) |
| 0x141811950 | 434 | 任务目标设定回调 (materiel_grid 刷新) | sub_1413473D0 = CNavalMissionSetTargetCommand (10261) |
| 0x1418151C0 | 426 | 全选舰移出三路回调 (选区首舰同源判定 = tf+1832 舦→队回指; 合并/拆分/重指派三路) | sub_141349950 (REASSIGN_ALL_TASKFORCES) / sub_141349BD0 (合并族) / sub_141349840 (拆分族) 三 ctor 新钉; 命令 id 对号未决 |
| 0x141807860 | 406 | 修船资格过滤器 (CReferenceObject 校验断言双份; 喂 +22232) | — |
| 0x141810B90 | 390 | 修理模式下拉回调 | sub_141349160 = CNavyRepairModeCommand (13581) |
| 0x141813080 | 378 | 交战规则下拉回调 (读 14198 偏好簇) | sub_1413616D0 = CSetNavyEngagementCommand (13357) |
| 0x14180DB60 | 377 | 改装入口 (胶水 +6744) | — |
| 0x14180D4C0 | 375 | 特混重组回调 (胶水 +15760; sub_141360AE0 族) | §4.33 13092 已载 |
| 0x14180F050 | 372 | 自动补员开关回调 (胶水 +9320) | sub_14134A630 = CSetTaskForceAutoReinforcementCommand (15170) |
| 0x14180E250 | 365 | 多选合并回调 | sub_141360420 = CMergeNaviesCommand (13176) |
| 0x14180F6B0 | 339 | 移除区域回调 (:2129 断言; 确认弹窗带 DAILYCOST/MISSING_PP/PROGRESS 表格键) | — |
| 0x141812160 | 333 | 海上补给开关回调 | sub_141349370 = CNavySetUnderwayReplenishmentCommand (16467) |
| 0x141816E80 | 328 | 地图右键海军分流 (view+257 海军旗; industrial_organisation_list_window 互斥判定) | — |
| 0x141813750 | 314 | 航母防御姿态下拉回调 (舰载机状态文案收集) | sub_141349D70 = CSetCarrierDefensiveStance (10227) |
| 0x14180E970 | 312 | 移动令排序壳 (三分区 :92/93/94 第二份全拷贝 + "All checked range are empty…" 断言) | sub_141347720 = CNavalMissionMoveCommand (13092) |
| 0x141813D80 | 295 | 修理拆分开关回调 (第二 RepairMode 入口) | sub_141348E70 = CNavyRepairModeCommand (13581 变体) |
| 0x141818360 | 282 | 选区特混批量置脏 (逐 tf sub_140D77B60 = `*(tf+1881)=1` 一行写点; 调用方 = 选区刷新主链 + 修理路) | — |
| 0x141808040 | 281 | 修理三态分类器 (0/1/2; 唯一消费者 BuildTooltip REPAIR_NOW 族) | — |
| 0x1417FF1C0 | 218 | 泛型收集 helper (双出参; 尾 :162 断言 = 「返是否舰队展开」注实现侧) | — |
| 0x141807540 | 162 | 拖放移动回调 (:4182 SubUnitID 断言) | sub_1413485C0 = CMoveShipsCommand (13092) |
| 0x141806420 | 128 | 三分区排序器 (:92/93/94 断言本体; 出参 = 分区后数组) | — |
| 0x14180C570 | 62 | 移动令玩家UI 小函 (:4090 断言 + order_fleet_effect/order_invalid_effect 双音效) | sub_141346B30 = CNavalMissionMoveCommand (12284) |

**0x141818920 (615 行) = REASSIGN_ALL_TASKFORCES 确认弹窗入口前置 (新定案, 补 §4.33 13092 调用链)**: UI 单例 qword_14332F6A0 vtable+184 → +480 = CNaviesView → view+244 选区数非空短路直调 0x1418151C0; 主体 = 收集 → 混编断言 (直通非弹窗) → sub_141806930 + sub_141349950 ctor → default_confirmation_popup (TASK_FORCE_IS_RESERVE_FLEET / REASSIGN_ALL_TASKFORCES_TEXT / _HEADER 三键) → 确认回调投递。

**本批新定案字段 (与 §4.30.17 类壳互补)**: +88 布局高度缓存 / +92 slider 内部指针 / +128..+140 选中对象跟踪三件套 (idpair+dword+u8 旗, 复位路径已见宿主语义未决) / +144 合并预览 40B 缓冲 / +204 舰队级选中旗 / +232..+244 选区 idpair 数组 / +256 详情 pending 旗 / +257 海军旗 / +264 弹窗树比对键 / +36720 选择计数件 / +36728 reserve 组 scoped ptr (latch byte_14338B16A) / +36752 任务目标按钮表 48B 元 / +36784..+36810 任务按钮 RH 表区 / +36816/+36828 串数组 {data, count} / +36840..+36852 TF 快照数组 (BuildTooltip idx4605 同址) / Setup 绑定槽区 +36680..+36936 步 8 与观察器对 +36952..+37040。音效 = order_fleet_effect (下令) / order_invalid_effect (无效)。

17 胶水块语义落定 9 块: +4168 移除区域 / +6744 改装 / +9320 自动补员 / +10608 半选 / +11896 btn_merge 接线 / +13184 btn_split_in_half 接线 / +14472 btn_create_new_from_selected 接线 / +15760 特混重组 / +19624 修理模式 / +20912 修理回调 (0x14180FCD0, 523 行: 三态分类 sub_141806380 → 需修路 CNavyRepairNowCommand / 弹窗路分舰送修; 尾驱动 +36688 槽状态)。


**navalmission.cpp 50-99 行簇增补**: 新定性三函 — **单位所在海省谓词入口 0x140FB6E30** (desc+210 bit0 陆地 → GetProvince(desc+200) 换算 → 海省+200 QWORD 非 0 委派 sub_140FB7010 (全身未析); 无省一次性日志 "no province? /dan" :867) / **运输群截击可达判定 0x140FB7C40** (transfer 单位表 {d@+24, c@+36} 首个 desc 旗 &3==0 单位过 sub_140EA8F30 海距门 = 舰队目标省 fleet+216 距 ≤ 上限, a4 置位回退 +392 邻接表; TF 无海通路告警 "TaskForce in province id %i that has no sea access" :2143) / **水面侦测修正施加 0x140FB2E20** (×mod/1e5 基线 1e5; mod = sub_140D6F660 = (省+352×Σ舰值(tf+840 表)/1e5 + 省+312)×ctx+8/1e5 下限 0 — Σ舰值 getter = sub_140C334D0, 场项业务名待裁; 明细行 SURF_DET {type 9, delta=mod−1e5}, 族 A 增员)。helper 定案 = sub_140D6EAD0 (TF 所在省 getter, tf+496, 陆→配对海省换算) / sub_140EA8F30 (海距判定) / sub_140D6F040 (TF 路径进度换算, 溢出返 -1)。已载函微增 = 0x140FBE250 谓词对象 = CConvoyClient (std::function 包装 sub_140FB7700), 元素 40B {权重@+28 × 对象值@+40}; 任务类型名表 0x140FB65C0 越界断言 "Missing localization key for new mission!" :1145 返空串。省对象 +200 QWORD 字段语义未决 (两处消费)。


**naval_fire_exchange_member.cpp 执行侧四函 (FEX 解析器 0x141978E30 近邻, 全新收)**: **命中结算入口 0x141973E20** — 侧累计 QWORD[2]@+240 (+1.0/次, ceil 钳上限, 满 return false) → 选目标 sub_141971CC0 → 内嵌 **CFEXMember::CLastTargetInfo@+312** {vtable@+312, 指针@+320, dword@+324, active@+328} (vtable 名直证) → 主结算 sub_1419740C0 → 暴击判定写 **+300 = dword_143331560** (乘数 qword_143331960, 两 define 槽名待裁); 布局新证 = 环境指针@+232 (+32 目标表/+56 单位集)。**炮槽三路读器 0x141972900** (gun∈{0,1,2} 双源切换 +8 对象 A 优先/+16 对象 B, "invalid gun" :2519; 炮种语义待裁)。**ECombatBox→档位映射 0x1419723B0** (值域 {1,2,4,8,0x10,0x20}; 4/0x10→7 / 0x20→6 / 1/2/8 舰种谓词四件套 sub_140C3AF20/B210/B220/B230 细分 (谓词第五件 sub_140C3AF10 = ship+1576 & 0x40 = capital_ship 位, FEX 五分类普查 0x141C6A370 首件单独判); "invalid ECombatBox" :2479)。**穿透→临界系数查表 0x14196FD60 (定案)**: NAVY_PIERCING_THRESHOLDS (data qword_143339998 / size dword_1433399A4) × CRITICAL_VALUES 同尺寸配对 (:1826 断言直证); 比率 = 1e5×穿透/护甲, **除零 → 10.0**; 档 = 最后一个 ≤ 比率阈值; 低于全部 → values[0]+1.0。

**编成编辑器窗 tooltip 构建器 sub_141E29DE0 (2117 行, dg034 定案)**: CTaskForceCompositionEditor (高置信, ≥12016B) 副 vtable tooltip 槽注册 (零直接调用; CNaviesView BuildTooltip 0x141809190 同型异窗); 契约 = (窗 a1 [+24 = 当前特混 idpair], 悬停元素 a2, 出参 string[2] 标题/描述) → bool (1 = 吞默认); a1+11792..+12008 = 15 个 tooltip 元素槽 (槽号×8) 指针分发 + a1[1486] 荣誉舰兜底。26 loc 键群: NAVY_REPAIR_POLICY_〈n〉 (tf+1124 四档环取 sub_141CF5BC0) / SHIP_ENGAGEMENT_BUTTON_AGGRESSIVENESS_〈n〉 (tf+916 五级环) / TASKFORCE_SUPPORT_NEED (tf+1600 map) / TASK_FORCE_FLEET_INFORMATION_* (tf+840 逐舰 max 匹配: 舰+552 最慢约束 / +560 最短航程约束, 筛选器 sub_141E26270 按 8×a4+288 选字段, 推定) / NAVY_CONTAINS_PRIDE_OF_FLEET / CANNOT_OPEN_..._FOR_DETACHED_TASK_FORCES (元素 vt+520 分离谓词) 等。**CCountry 荣誉舰 CRef 槽 (语义定案 / 偏移待裁)**: 国对象 16B idpair → sub_14221F310 解析 → 舰对象 (其 +1832 = tf 回指, 与 §4.16.23 ship+1832 pride 判定互证; gs 玩家国与 tf 拥有国两路同读); IDA 伪影 `std::end<std::_Win_errtab_t const,74>` 统一渲染 (全语料 31 处同参), dg034 初判 +16 与 cc+16 name 缓存定案冲突不取 — **dg035 独立坐实 cc+16 = 国名 std::string** (访问器 0x140222840 = return a1+16 + MSVC 拷贝 ctor 双证), 荣誉舰槽真实偏移待 PE 侧验证 (伪影字面 74 亦与三串缓存区布局冲突)。字形 token 18449/8465 两枚 UTF-16 图标串再证。未决: a1+24 写侧 / 舰+552/560 单位 / 舰+1840 归属匹配对象 (⚠ CShip 装载键 pride_of_the_fleet→+2068、air_wings→+1840 区与巨函读法交叉, 待裁) / tf+312 统计对象 +432 statId。

**海军地图特混图标集重建 sub_1418F1510 (290 行, NNavyMapIconUtils 族 functor RTTI 三件直证, df366 全案)**: 调用方 = sub_1418F0410 (海军地图 populate) 3 处; 视图 +1456 = scoped_ptr 图标列表 / +1464 过滤旗。流程: 早退门 (288B 管理器单例 qword_14333CFB8 +0 = zoom 级别 / vt+904 谓词; **tf+388 强度比** vs 阈值 dword_143335A10/AB0, 分档 qword_1433355A8/518 ×1e-5, define 名待裁) → 三重过滤 (有船有队 sub_141E8CB10 ∧ 可见度 ≥150 ∨ 控制台 toggle byte_14332F622 (sub_1402939D0 回显 ON/OFF) ∧ **tf+524 ≤ 0 未在航**) → 排序 (级别 0 ∨ 强度低于阈值 → 粗 comparator STaskForceCoarseMapIconSorter / 否则细 STaskForceMapIconSorter; ≤32 插入 / >32 stable_sort) → 强度档 3 时阵营分组 functor STaskForceAlligenceGrouper (引擎拼写) → sub_141E8C530 分组灌列 + sub_1422C7E50 刷新。**可见度计算器 sub_141618DC0 全案**: 门 byte_14332F63A; owner 非玩家且非同原初国才算: 情报分档 (sub_140BFDF30) → 类型 +8==1: 档 3/2/1 → 基值 250/150/100; 类型 0/13: 档 1 → 150 / 档 ≥2 → 250, 与每省 LUT 字节 (idler vt+120 → +1776, §4.30.58 纹理同源) 取大; 终值 = 基值 × (1 + 修正587 MODIFIER_INTEL_FROM_COMBAT_FACTOR /1e5); >255 返 −1。

#### 4.16.24 海空交火车载机投送强度计算 (naval_fire_exchange_air.cpp; 1 函 = sub_14197D770, 高置信)

#### 4.16.25 海军领袖建筑模块四槽取值写门 (navy_leader_building_module.cpp; 1 函 = sub_141623450, 高置信/类型门推定)

sub_141623450: a1+8 = idpair (双 dword 非零 ∧ sub_14221F310 解析 → 本体); 本体经 sub_140F9F9C0 取对象 v7, **门 = v7 非空 ∧ *(v7+3708) == 2** (推定 = 海军类建筑类型); a3 ∈ {0,1,2,3} 四槽分派 (switch 降级为减法链: 0 → sub_140C154F0 / 1 → sub_1406CFCD0 / 2 → sub_1406CF4D0 / 3 → sub_1406CF890, 各返槽持有者); **落点统一 sub_14055AB90(槽+224, a2, 2, 0, 0, −1, 0, 100000, 0, 0, 0)** — 固定值 **100000 (= fixed 1.0)** 写出参 a2; 非法 a3 → :145「Should never get here」纯日志 (闩 byte_14338A9C9); 任一前置失败 → sub_14011E130(a2, &空串) 空出参。

sub_14197D770 (a1 = 交火成员侧对象): a1+8 = 父交火对象 / a1+28 = 载机 token 对 ({lo@+28, hi@+32}) → 非零经 sub_14221F310 解析为对象 v9 → 断言 :68 (v9+104 非零 = IsCarrier, 闩 byte_14338B40D); v6 = *(父+56); v9+96 或 v9+100 非零 → 取次级 token (v9+96) → `v4 = *sub_140C38760(&out, token, 463, *(v6+304), 0, 0)` (常量 463 语义未决); **ceil-1e5 取整** = `v4 != 100000*(v4/100000) → v4 = 100000*(v4/100000 + (v4>0))` (正数向上取整到 1e5 粒度, 非正不变); 结果 `*(dword*)(a1+248) = dword_143335D60 + (int)v4/100000` (全局基值 + 定点缩放; 基值与 463 语义未决); 返回值 = v4 符号位惯用语 (`v4*0x29F16B11C6D1E109>>64>>63` = v4≥0 的 bool, 非业务系数, PE 侧验算)。与 §4.16.23 交火执行侧四函同族 (成员侧字段消费面)。

#### 4.16.26 CNavyMilitaryOverviewItem 海军列表 tooltip 构造 (1 函 = 0x141D34380, 高置信)

0x141D34380 (调用方 sub_141D36240, §4.31 CNavyMilitaryOverviewItem @24[0]): loc 键 `ARMY_NAVIES_TOOLTIP_DELAYED_TEMPLATE` (NAME/TYPE 两参); 舰队列表 = **a2+840 引擎向量 {data@+840, count@+852}** (sub_140D6EEB0 体 = `return a1+840` 纯偏移访问器, 消费端按 a2+840 读); 逐舰队 type token 推定经 sub_140C39160 / 名条目 sub_14100FEE0(navy+64); pdx_scoped_buffer.h:54 断言站实例化闩 = **byte_14333CE83** (门 byte_1435E1B52 flags=1, 站语义书已收闩 VA 补录)。

#### 4.16.27 海军舰船条目面板刷新 (维修/改装队列 UI 簇; 1 函 = 0x141F98820, 高置信)

0x141F98820 (面板 a1, **CShip\* a2**, a2+1832 = CTaskForce\*): 维修/改装进度三态条 + 舰名着色 + 装备角色徽章 + 计时文本。谓词全复用书定案符号: sub_140C00000 在战中 (unit+436) / sub_140C3B130 在改 (§4.16) / sub_140C3B170 维修中 (§4.33:843 同域) / sub_14221F310 idpair 解析 / sub_1401AEB50(n) DLC 特性开关。流程: ① 逐子件显隐归位 (elem+117 & 8; vt+120 Show / vt+128 Hide) 对 +64/+88/+96/+160/+72/+104/+216/+184; ② **tf+1200/+1204 idpair** 解析 (失败 ∨ 类型 ≠16 ∨ tf+1208 维修态码 ≠1 → 隐藏 +200 进度条收尾); ③ `sub_140C3AC60(a2)` ≥ 100000 (fixed 1e5 满进度) 早退; ④ 三态 = 维修 2 / sub_141E2C7F0 3 / 否则 1 → +200 slot22 SetState; ⑤ 进度条: `+1612 = +1608` 进度镜像复位 → slot96 宽扣减 → slot19 位置 = 当前进度 → slot85 新宽 → sub_140D6B480(tf) 分流 slot81/82; ⑥ 舰名着色 = sub_140C3B0E0 二选一 CColor 常量 (xmmword_143338AA0 / xmmword_1430BDF00, 色值待裁) → +64 slot30 SetColor; ⑦ a2+2340 支路 = +216 第二条 Show + sub_140C35480 格式化文本 + 同 ⑤ 宽/位序列; ⑧ **徽章** = DLC 开关 sub_1401AEB50(20) ∧ 装备定义 (+64 容器经 sub_14100FF30 取首, +1068 > 0) → **sub_140A56330(qword_14332EF50 = CInsigniaGraphicsDatabase 单例, 装备定义, a1+184 图标, 0)** (§4.30:2748/2796 kind 4 徽章入口消费点); 否则 +184 Hide。

#### 4.16.28 海军域函数补遗（15 函）

| VA | 语义/证据 |
|---|---|
| 0x141F99D10 | sub_141F99D10 ref.h:83 + NAVY_MERGE_PARENT_STATUS / NAVY_DETACHED_PARENT_STATUS（海军合并/脱离母舰状态 UI） |
| 0x14198F6B0 | sub_14198F6B0 NAVAL_SPOTTING_LEVEL_(NONE/LOW/MEDIUM/DETAILED_UNITS)_DESC + NAVAL_SPOTTING_SEARCHED_BY（海军索敌等级 UI） |
| 0x1415BA930 | （未命名）GUI 串 NAVAL_ACCIDENT_DISPATCH_TITLE/_DES GUI 串 NAVAL_ACCIDENT_DISPATCH_TITLE/_DESC + "default_confirmation_popup"（海损事故弹窗） |
| 0x141E29870 | （未命名）GUI 串 TASK_FORCE_UNDERWAY_REPLENISHMENT_ GUI 串 TASK_FORCE_UNDERWAY_REPLENISHMENT_DESC / FACTOR_BONUS（舰队补给） |
| 0x1410141C0 | （未命名）串 "Unrecognized mission type" 串 "Unrecognized mission type"（任务类型解析） |
| 0x140528BE0 | GetDesc 海军触发器（断言站点 naval_triggers.cpp:30） |
| 0x140FB43C0 | （未命名）loc 串 SHIP_ENGAGEMENT_BUTTON_AGGRESSIVEN loc 串 SHIP_ENGAGEMENT_BUTTON_AGGRESSIVENESS_（舰队交战积极度按钮） |
| 0x1418FA990 | （未命名）loc 串 CURRENT_ALL_ACTIVE_TASK_FORCE_FOR_ loc 串 CURRENT_ALL_ACTIVE_TASK_FORCE_FOR_MISSION / CURRENT_ACTIVE_TASK_FORCE_FOR_MISSION |
| 0x141E0A920 | sub_141E0A920 体内构造/操作 vtable 类 CNavyTheaterNavyItemBase（&CNavyTheaterNavyItemBase::vftable）→ 海军报告/联队项/海军命令 |
| 0x140D77C70 | CTaskForce::[29] CTaskForce::[29]（舰队 vtable 槽方法） |
| 0x141ED65D0 | sub_141ED65D0 海军 task force/海军上将司令部逻辑（ADMIRAL_THRESHOLD_REACHED_NAVAL_HEADQUARTER CHANGE_ADMIRAL_I） |
| 0x140D57CA0 | CFleet::[5] gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x1418FCFF0 | （未命名）loc 串 CURRENT_ACTIVE_TASK_FORCE_FOR_NAVA loc 串 CURRENT_ACTIVE_TASK_FORCE_FOR_NAVAL_INVASION_SUPPORT_WARNING（登陆支援舰队警告） |
| 0x1418FABA0 | sub_1418FABA0 海军 task force/海军上将司令部逻辑（TASK_FORCE） |
| 0x141D436F0 | sub_141D436F0 海军装备总量 GUI（NAVY_EQUIPMENT_TOTAL） |

#### 4.16.29 海军域函数补遗（12 函）

| VA | 语义/证据 |
|---|---|
| 0x1416255A0 | （无名）TOOLTIP_POTENTIAL_TARGET_RAID_HEADER_ALLOWED/NOT_ALLOWED + RAID_RANGE_FACTOR_TOOLTIP + raid_type_rescue_captured_general_captive_line TOOLTIP_POTENTIAL_T… |
| 0x141298D40 | （无名）tooltip_raid_source_map_hover + WHAT/LOCATION 键 tooltip_raid_source_map_hover + WHAT/LOCATION 键 |
| 0x141801F90 | （无名，按上游/loc 定性） loc "aggressiveness_item\ icon\ name\ SHIP_ENGAGEMENT_BUTT*" |
| 0x1418FDEA0 | （无名，按上游/loc 定性） loc "PROGRESS\ NAVAL_SPOTTING_PROGRESS\ SPEED\ NAVAL_SPOTT*" → 海上索敌进度提示 |
| 0x141803FA0 | （无名，按上游/loc 定性） loc "repair_priority_item\ icon\ name\ NAVY_DOCKYARD_REPAI*" |
| 0x14197B380 | （无名，按上游/loc 定性） naval_fire_exchange_air.cpp:637 断言 |
| 0x140A2EEC0 | vtable/RTTI 类 NFactions::CFactionGoal sub_140A2EEC0 + vtable/RTTI 类 NFactions::CFactionGoal; 被 SUniformReader<…>::[1] 等 1 命名函数调用 |
| 0x140A2F020 | vtable/RTTI 类 NFactions::CFactionGoal sub_140A2F020 + vtable/RTTI 类 NFactions::CFactionGoal; 被 SUniformReader<…>::[2] 等 1 命名函数调用 |
| 0x140A2BEE0 | SUniformReader<…>::[1] SUniformReader<…>::[1] + vtable/RTTI 类 NFactions::CFactionUpgrade; vtable/RTTI 含 NFactions::CFactionUpgrade; 被 SUniformReader<…>::[1] … |
| 0x141D435E0 | CShipsOverview::[0] CShipsOverview::[0] + 域关键词匹配; 串 "total_ships_icon"; 被 CShipsOverview::[0] 等 1 命名函数调用 |
| 0x140EEB5D0 | CFrontSection::[0] CFrontSection::[0] + vtable/RTTI 类 CFrontSection; vtable/RTTI 含 CFrontSection; 被 CFrontSection::[0] 等 1 命名函数调用 |
| 0x140A69010 | vtable/RTTI 类 CCountryNames sub_140A69010 + vtable/RTTI 类 CCountryNames |

#### 4.16.30 海军域函数补遗（10 函）

| VA | 语义/证据 |
|---|---|
| 0x141665430 | 舰艇战斗读取器槽 舰艇战斗读取器槽；邻 CShipCombatReader::[0](-14640B)/CShipCombatReader::Reader(-1952B)，被调 pdx_entity.cpp:2523 |
| 0x141BEABA0 | 舰队荣耀加成 舰队荣耀加成；loc \"PRIDE_OF_THE_FLEET_COUNTRY_BONUS\"/\"PRIDE_OF_THE_FLEET_SHIP_BONUS\"/\"PRIDE_OF_THE_FLEET_TEMP_BONUS\"+\"BONUS\"，被调 pdx_robin_hood_table.… |
| 0x141BF2C60 | 海军战史条目 海军战史条目；loc \"NAVAL_HISTORY_ASSISTED_KILL\"/\"NAVAL_HISTORY_KILLED\"+\"NAME\"/\"SHIPCLASS\"+\"assisted_kill_icon\"+\"GFX_navalcombat_ship_icon_unknown\" |
| 0x140C31980 | 舰队任务燃料效率提示 舰队任务燃料效率提示；loc \"FLEET_HAS_FUEL_INEFFICIENT_SHIP_FOR_MISSION\"，被调 localize.cpp:641/text.cpp:491 |
| 0x1418C85C0 | 海军战果图标 海军战果图标；loc \"GFX_naval_combat_result_navalstrikes\"/\"GFX_naval_combat_result\"/\"_convoys\"/\"_portstrikes\"，被调 gamestate.h:1125×2 |
| 0x14197AC80 | 海军空袭火力交换 海军空袭火力交换；断言 \"!\\\"how can both be false? bail! /dan\\\"\"（naval_fire_exchange_air.cpp），被调 naval_utility.cpp:457/naval_fire_exchange_member.cpp:756/… |
| 0x140C3DC50 | sub_140C3DC50（无名） FUEL_DAILY / AMOUNT GUI 键，夹于 CShip::Reader(d=5808) 与 CShip::Writer(d=2672)，舰船燃料 UI |
| 0x1417F94C0 | "sunk_by_training/damage_by_mines/equipm "sunk_by_training/damage_by_mines/equipment_ic" 舰船损失统计 §4.16 海军 |
| 0x1417CEE80 | "naval_mission_ships/naval_missions_grid "naval_mission_ships/naval_missions_grid/select_all" 海军任务 UI §4.16 海军 |
| 0x14118A790 | "CONFIRMCHANGE_NAVY_LEADER_FLEET_TEXT/HE "CONFIRMCHANGE_NAVY_LEADER_FLEET_TEXT/HEADQUARTER/SUPREME_CO §4.16 海军 |

#### 4.16.31 海军域函数补遗（25 函）

| VA | 语义/证据 |
|---|---|
| 0x14197A700 | （无名，按证据定性） naval_fire_exchange_air.cpp:1087 断言站点（海空交战火力交换） |
| 0x141ED7670 | （无名，按证据定性） 键 NAVAL_EXPERIENCE_HQ_GAIN/NAVAL_HEADQUARTER_NO_ADMIRAL（海军司令部经验/无提督） |
| 0x140D6C2B0 | （无名，按证据定性） 键 NAVY_DETACHED_ACTIVITY_STATUS_REFITTING_ONE_SHIP/REPAIRING_MANY_SHIPS 等（分舰队活动状态） |
| 0x1415C2B40 | （无名，按证据定性） 键 NAVAL_PORT_STRIKE_TITLE/NAVAL_BATTLE_TITLE + NAME（海军战斗/港口打击标题文本） |
| 0x140D6A7C0 | 舰队活动描述 TASK_FORCE_ACTIVITY_DESC_MOVING_TO_AREA / STRIKE_FORCE_INTERCEPTING 等 ×11 |
| 0x1419694A0 | 海军转运 NAVAL_TRANSFER_MOVING + VALUE/BASE |
| 0x141D61B90 | 舰船设计器制海权 SHIP_DESIGNER_NAVAL_DOMINANCE_VALUE + dominance_icon/value |
| 0x140D71A70 | CTaskForce::[8] func_names CTaskForce::[8]（特遣舰队方法）+ gamestate.h:1125 断言 |
| 0x1418FD1E0 | 海军巡逻区域 CURRENT_ASSIGNED_TASK_FORCE_FOR_PATROL + REGION_WITH_NO_PATROL |
| 0x140C361F0 | CShip::[11] vtable 槽 CShip::[11]（func_names RTTI 名） |
| 0x140D581C0 | CFleet::[4] vtable 槽 CFleet::[4]（func_names RTTI 名） |
| 0x140C3B070 | CShip::[9] vtable 槽 CShip::[9]（func_names RTTI 名） |
| 0x140EB2AF0 | CStrategicNavy::GetEstimatedEnemyConvoysInRegion? func_names 名 CStrategicNavy::GetEstimatedEnemyConvoysInRegion? |
| 0x140EADE30 | CStrategicNavy::SRegionalConvoyData::[4] vtable 槽 CStrategicNavy::SRegionalConvoyData::[4]（func_names RTTI 名） |
| 0x140C394F0 | CShip::[4] vtable 槽 CShip::[4]（func_names RTTI 名） |
| 0x140D57FC0 | CFleet::[3] vtable 槽 CFleet::[3]（func_names RTTI 名） |
| 0x140D581A0 | CFleet::[2] vtable 槽 CFleet::[2]（func_names RTTI 名） |
| 0x140EB2140 | CStrategicNavy::SRegionalConvoyData::[1] vtable 槽 CStrategicNavy::SRegionalConvoyData::[1]（func_names RTTI 名） |
| 0x140C30CC0 | CShip::[0] vtable 槽 CShip::[0]（func_names RTTI 名） |
| 0x140D50EA0 | CFleet::[0] vtable 槽 CFleet::[0]（func_names RTTI 名） |
| 0x140E9EF60 | CStrategicNavy::[2] vtable 槽 CStrategicNavy::[2]（func_names RTTI 名） |
| 0x140C394D0 | CShip::[3] vtable 槽 CShip::[3]（func_names RTTI 名） |
| 0x140D50E8C | CFleet::[0] vtable 槽 CFleet::[0]（func_names RTTI 名） |
| 0x140E9EF08 | CStrategicNavy::[0] vtable 槽 CStrategicNavy::[0]（func_names RTTI 名） |
| 0x140C30D20 | CShip::[7] vtable 槽 CShip::[7]（func_names RTTI 名） |

#### 4.16.32 海军域函数补遗（25 函）

| VA | 语义/证据 |
|---|---|

#### 4.16.33 海军域函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x140EABE80 | CStrategicNavy::USRegionalConvoyData::U?$SDefaultSetSize::NPdx:鈥�::[3] func_names 名 CStrategicNavy::USRegionalConvoyData::U?$SDefaultSetSize::NPdx:鈥�::[3] |
| 0x140EB2250 | CStrategicNavy::Writer func_names 名 CStrategicNavy::Writer |
| 0x140EA5BD0 | CStrategicNavy::GetEstimatedEnemyConvoysInRegion? func_names 名 CStrategicNavy::GetEstimatedEnemyConvoysInRegion? |
| 0x140C3AD50 | CShip::[8] vtable 槽 CShip::[8]（func_names RTTI 名） |
| 0x140C30C3C | CShip::[0] vtable 槽 CShip::[0]（func_names RTTI 名） |
| 0x140C30D10 | CShip::[1] vtable 槽 CShip::[1]（func_names RTTI 名） |

#### 4.16.34 海军域函数补遗（6 函）

| VA | 语义/证据 |
|---|---|

#### 4.16.35 海军域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x14161CCB0 | 舰队掩护/定位 tooltip 生成（舰种计数与 box 布局） 串 SCREENING_TOOLTIP_* 全族 + NUM_CAPI/CARR/CONV/SCRE/NEED + POSITIONING_VALUE |
| 0x140E03A40 | 海军水雷区域统计 tooltip（按敌/友/中立/己方分类） 键 NAVAL_MINES_IN_REGION_BY_ENEMIES/FRIENDS/NEUTRAL/US + COUNT_DAMAGED/COUNT_SUNK |
| 0x14161B960 | CNavalCombatant 定位/修正 tooltip（海军战斗定位罚项） 键 POSITIONING_PENALTY_INFO / CONVOY_ESCORT_POSITIONING_BONUS / SCREENING_VALUE / STAT_NAVY_SUB_VISIBILITY；邻接 CNavalCo… |

#### 4.16.36 海军域函数补遗（40 函）

| VA | 语义/证据 |
|---|---|
| 0x140D5D7E0 | （无名） 调用图传播: 5 锚点投 §4.16（60%） |
| 0x141D2C860 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x140E9CD90 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140D0A2F0 | （无名） 调用图传播: 6 锚点投 §4.16（100%） |
| 0x140FB2980 | （无名） 调用图传播: 8 锚点投 §4.16（50%） |
| 0x140D09770 | （无名） 调用图传播: 4 锚点投 §4.16（100%） |
| 0x140D08620 | （无名） 调用图传播: 4 锚点投 §4.16（100%） |
| 0x140FB01C0 | （无名） 调用图传播: 5 锚点投 §4.16（60%） |
| 0x141E8C910 | （无名） 调用图传播: 8 锚点投 §4.16（50%） |
| 0x141B05E90 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x141971440 | （无名） 调用图传播: 7 锚点投 §4.16（57%） |
| 0x1412326B0 | （无名） 调用图传播: 4 锚点投 §4.16（50%） |
| 0x140D71E70 | （无名） 调用图传播: 4 锚点投 §4.16（50%） |
| 0x14002EC60 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x1416A9810 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x140C37B50 | （无名） 调用图传播: 4 锚点投 §4.16（100%） |
| 0x140C37000 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140D66220 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140FB15B0 | （无名） 调用图传播: 5 锚点投 §4.16（80%） |
| 0x140D59D50 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140FBA740 | （无名） 调用图传播: 4 锚点投 §4.16（100%） |
| 0x141A0E8F0 | （无名） 调用图传播: 4 锚点投 §4.16（50%） |
| 0x140C33570 | （无名） 调用图传播: 3 锚点投 §4.16（100%） |
| 0x140FB1740 | （无名） 调用图传播: 4 锚点投 §4.16（75%） |
| 0x140D59750 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x141B06770 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D6B120 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D69D10 | （无名） 调用图传播: 5 锚点投 §4.16（80%） |
| 0x1424EC9A0 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x1415B01F0 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D5A3B0 | （无名） 调用图传播: 3 锚点投 §4.16（100%） |
| 0x140EB2C70 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140C39D60 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140C3A470 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140A59200 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D6E800 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140D76A90 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x140D650F0 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D778B0 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140D76690 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |

#### 4.16.37 海军域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x140E04BA0 | 海军事故 串 "NAVAL_ACCIDENTS_ENEMY"/"NAVAL_ACCIDENTS_MINES"/"NAVAL_ACCIDENTS_TRAINING" → 海军事故 |

#### 4.16.38 海军域函数补遗（31 函）

| VA | 语义/证据 |
|---|---|
| 0x141BA6130 | sub_141BA6130 调 CNavalBaseConvoyClient::[15]；unknown_libname_10 + malloc(0x20) 节点构造（海军基地护航客户端数据结构） |
| 0x141F95D30 | sub_141F95D30 SSpriteFramePair + GFX_ship_activity_(retrofitting/repairing/docked)（舰船活动精灵状态视图） |
| 0x141233980 | sub_141233980 海军任务编队类型（Wolfpack/CarrierTaskForce/SurfaceActionGroup/MineLayers/PatrolTaskForce/ConvoyEscort） |
| 0x1417F5540 | 域关键词匹配 sub_1417F5540 + 域关键词匹配; 源码路径 hoi4; 被 CEmptyEntryListBase<CShipArchetypeItem>::[0] 等 1 命名函数调用 |
| 0x14161F620 | 调用图上游传播(占 100%, 1 票) sub_14161F620 + 调用图上游传播(占 100%, 1 票) |
| 0x141709E40 | sub_141709E40 特征串:destroyed_ships_open |
| 0x140F7EEE0 | 调用图上游传播(占 100%, 1 票) sub_140F7EEE0 + 调用图上游传播(占 100%, 1 票) |
| 0x1414DB520 | 同区段近邻 CPendingStratNavyTransfer::[4](距 0x4F30)属 4.16 族 sub_1414DB520 + 同区段近邻 CPendingStratNavyTransfer::[4](距 0x4F30)属 4.16 族 |
| 0x14158D360 | 调用图上游传播(占 80%, 2 票) sub_14158D360 + 调用图上游传播(占 80%, 2 票) |
| 0x140E97050 | 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[11](距 0x10 sub_140E97050 + 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaid… |
| 0x141232C90 | 域关键词匹配 sub_141232C90 + 域关键词匹配; 被 CRestructureShipsToTaskforceCompositions::Execute 等 2 命名函数调用 |
| 0x141C6C3D0 | 调用图上游传播(占 100%, 1 票) sub_141C6C3D0 + 调用图上游传播(占 100%, 1 票) |
| 0x14170A520 | sub_14170A520 特征串:navy_sort_size |
| 0x141B1F580 | 调用图上游传播(占 100%, 1 票) sub_141B1F580 + 调用图上游传播(占 100%, 1 票) |
| 0x141E22270 | sub_141E22270 海军战斗 GUI 图标（GFX_navalcombat_ship_icon） |
| 0x141975150 | 域关键词匹配 sub_141975150 + 域关键词匹配; 源码路径 hoi4; 被调源码 clausewitz |
| 0x140E87130 | 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[11](距 0x22 sub_140E87130 + 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaid… |
| 0x14129BDC0 | 域关键词匹配 sub_14129BDC0 + 域关键词匹配; 被调源码 clausewitz |
| 0x1410040C0 | 域关键词匹配 sub_1410040C0 + 域关键词匹配; 源码路径 hoi4; 被调源码 clausewitz |
| 0x140C324F0 | 域关键词匹配 sub_140C324F0 + 域关键词匹配 |
| 0x140E7AEA0 | 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[11](距 0xC0 sub_140E7AEA0 + 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaid… |
| 0x140FEA670 | 调用图上游传播(占 100%, 1 票) sub_140FEA670 + 调用图上游传播(占 100%, 1 票) |
| 0x14158DC00 | 域关键词匹配 sub_14158DC00 + 域关键词匹配; 被调源码 clausewitz; 被 NRaids::NUi::CRaidList::[6] 等 1 命名函数调用 |
| 0x140C333E0 | 调用图上游传播(占 55%, 3 票) sub_140C333E0 + 调用图上游传播(占 55%, 3 票) |
| 0x140CE31E0 | 调用图上游传播(占 100%, 1 票) sub_140CE31E0 + 调用图上游传播(占 100%, 1 票) |
| 0x14145B400 | 域关键词匹配 sub_14145B400 + 域关键词匹配; 被 CNavalProductionLine::[30] 等 3 命名函数调用 |
| 0x14158C390 | 调用图上游传播(占 67%, 2 票) sub_14158C390 + 调用图上游传播(占 67%, 2 票) |
| 0x140C27EF0 | 调用图上游传播(占 50%, 2 票) sub_140C27EF0 + 调用图上游传播(占 50%, 2 票) |
| 0x140FEAFF0 | 域关键词匹配 sub_140FEAFF0 + 域关键词匹配 |
| 0x140E9A680 | 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[11](距 0x13 sub_140E9A680 + 同区段近邻 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaid… |
| 0x141E1C720 | 调用图上游传播(占 100%, 1 票) sub_141E1C720 + 调用图上游传播(占 100%, 1 票) |

#### 4.16.39 海军域函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x140E9A930 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x141973170 | 无名 · loc 键 "SHIP_AND_TYPE" loc 键 "SHIP_AND_TYPE" |
| 0x141D43480 | 无名 · "SERVICE_MANPOWER_HEADER" 海军人力键 "SERVICE_MANPOWER_HEADER" 海军人力键 |
| 0x1412D9570 | 无名 · "CONVOY_DOMINANCE_COST_REDUCTION" "CONVOY_DOMINANCE_COST_REDUCTION" 护航统治力键 |
| 0x140D6C130 | 无名 · "NAVY_DETACHED_ACTIVITY_STATUS_" 脱 "NAVY_DETACHED_ACTIVITY_STATUS_" 脱离舰队状态键 |
| 0x141287F00 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x141E1D1E0 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |

#### 4.16.40 海军域函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140270370 | 业务逻辑（见证据锚） "Added … naval mines to the selected region(s)."/"Please select some regions first."（布雷控制台命令） |
| 0x1417DAFF0 | 业务逻辑（键 NAVAL_COMBAT_RESULT_DEFEAT） "NAVAL_COMBAT_RESULT_DEFEAT"/"NAVAL_COMBAT_RESULT_VICTORY"/"outcome"（海战结果） |
| 0x140E281F0 | 业务逻辑（见证据锚） "pUnit &&"/"Unhandled unit type."（海军运输单位类型） |
| 0x141004A70 | 业务逻辑（键 SEAZONE_MINIMUM_DOMINANCE） "SEAZONE_MINIMUM_DOMINANCE"/"NAVAL_DOMINANCE_RATIO[_HEADER]"（海区控制度） |
| 0x1412A9000 | SNavalUnitActivityData 海军单位活动数据 (vtable类名 SNavalUnitActivityData) vtable引用 SNavalUnitActivityData vftable |

#### 4.16.41 海军域函数补遗（12 函）

| VA | 语义/证据 |
|---|---|
| 0x141BB8AA0 | （无名） 调用图传播: 8 锚点投 §4.16（62%） |
| 0x140D790A0 | （无名） 调用图传播: 8 锚点投 §4.16（62%） |
| 0x140D64D40 | （无名） 调用图传播: 3 锚点投 §4.16（67%） |
| 0x140652840 | （无名） 调用图传播: 4 锚点投 §4.16（50%） |
| 0x1400826D0 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x1402B48F0 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x14196FCA0 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x14101B1B0 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D0C540 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x1424E36A0 | （无名） 调用图传播: 2 锚点投 §4.16（50%） |
| 0x140D55E40 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |
| 0x140D547F0 | （无名） 调用图传播: 2 锚点投 §4.16（100%） |

#### 4.16.42 海军域函数补遗（19 函）

| VA | 语义/证据 |
|---|---|
| 0x141E069D0 | 无名 sub_（断言站点/串定位） 串字面量 "NAVAL_COMBAT_RESULT_SURVIVOR_COUNT_UNDAMAGED" |
| 0x140C37180 | 无名 sub_（断言站点/串定位） 串字面量 "STAT_NAVY_HIT_PROFILE" |
| 0x140D56740 | 无名 sub_（断言站点/串定位） 串字面量 "FLEET_NAME" |
| 0x140CE3470 | 无名 sub_（断言站点/串定位） 串字面量 "NAVAL_COMBAT_RESULT_HEADER" |
| 0x141E6E1E0 | 无名 sub_（断言站点/串定位） 串字面量 "naval_access_rule" |
| 0x141BBCF40 | 无名 sub_（断言站点/串定位） 串字面量 "ship_name" |
| 0x1417D89B0 | 无名 sub_（断言站点/串定位） 串字面量 "NAVAL_HEADQUARTERS_COMBAT_TT" |
| 0x141DFF2B0 | 无名 sub_（断言站点/串定位） 串字面量 "NAVAL_COMBAT_RESULT_SURVIVOR_TYPE" |
| 0x141F96170 | 无名 sub_（断言站点/串定位） 串字面量 "SHIP_REFIT_CANCEL_TOOLTIP" |
| 0x140D74220 | 无名 sub_（断言站点/串定位） 串字面量 "NAVAL_BASE" |
| 0x1406E5F90 | 无名 sub_（断言站点/串定位） 串字面量 "SCORE_CALC_NAVY" |
| 0x141F7D010 | 无名 sub_（断言站点/串定位） 串字面量 "CONFIRM_DISBAND_FLEET_TITLE" |
| 0x141F6D2B0 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_navalcombat_ship_icon_" |
| 0x140FB6710 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_mapicon_naval_mission_patrol" |
| 0x14158C6D0 | 无名 sub_（断言站点/串定位） 串字面量 "naval_base" |
| 0x140241720 | 无名 sub_（断言站点/串定位） 串字面量 "Naval invasion order are now ignoring superiority " |
| 0x140C39420 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_navy_icon_" |
| 0x140C317B0 | 无名 sub_（断言站点/串定位） 串字面量 "FUEL_DAILY_REQUIRED_MAX_DESC_NAVY" |
| 0x141BBD4F0 | 无名 sub_（断言站点/串定位） 串字面量 "ALL_SHIPS" |

#### 4.16.43 海军域函数补遗（17 函）

| VA | 语义/证据 |
|---|---|
| 0x140EBE580 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140E9AFA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140D6FFF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x1415B9A50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x1417DAF40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x14161E2C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x141666790 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x14181E220 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x141972B60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140D6F3B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x1412AD090 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x14134B550 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140ED0D10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140D65C60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140D6B490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140D6E870 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x140D701C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |

#### 4.16.44 海军域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x140EBAE10 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.16 |
| 0x140E9AC50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.16 |
| 0x1415C4FD0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.16 |

#### 4.16.45 海军域函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x1421A6ED0 | （无名） 调 sub_1415934A0（raid_source.cpp:410）+ sub_1424C8080 |
| 0x140D6AB60 | （无名） 串 "TASK_FORCE_ACTIVITY_DESC_SPOTTING_ENEMY_TASK_FORCE"/"TASK_FORCE_ACTIVITY_DESC_PERFORMING_MISSION_IN_REGION" |

#### 4.16.46 海军域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141E29780 | 舰队补给描述 特混舰队航行中补给描述：TASK_FORCE_UNDERWAY_REPLENISHMENT_DESC + FACTOR_BONUS + eh vector 构造 |

#### 4.16.47 海军域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x14158DD60 | 未决窗口函数 · 海上突袭类别 串 "raid_category_" 前缀构造 + stringop |
