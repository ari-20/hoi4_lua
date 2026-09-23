> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

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

#### 4.16.2 CTaskForce (writer 0X140D7AFA0)

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
| underway_replenishment (16427) | tf+1128 | u8 | 恒写 | |
| convoys (12386) | tf+1136 | 对象 | underway_replenishment≠0 | |
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
| sortie_efficiency (12970) | tf+1260 | u32 | 恒写 | |
| repair_last_mission (13598) | tf+1264 | u32 | ≠0 | |
| hours_waited_for_repairs (15504) | tf+1256 | u32 | ≠0 | |
| repair_split (13596) | tf+1268 | u8 | ≠0 | |
| merge_split (13996) | tf+1269 | u8 | ≠0 | |
| is_sea_locked (13998) | tf+1270 | u8 | ≠0 | |
| auto_reinforcement (15169) | tf+1271 | u8 | ≠0 | |
| fuel (12003) | tf+1272 | i64 fixed5 | ≠0 | |
| requested (15132) | tf+1280 | i64 fixed5 | ≠0 | |
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

#### 4.16.3 CShip (writer 0X140C3E6C0)

| 项 | 值 |
|---|---|
| RTTI 名 | — |
| sizeof | — |
| vtable RVA | 0X2957F28 |
| writer | 0X140C3E6C0 (= vt slot2; a1 = sh 直基; 首调基类 0X142220340) |
| loader | — |
| 挂载点 | CTaskForce ship 容器 (tf+840/tf+852) |

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
| experience (11930) | +1800 | i64 fixed5 | ≠0 | |
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

CShip/CTaskForce GUI 消费表:

| 字段 | 消费点 | 用途 |
|---|---|---|
| CShip+8 refid | ShipStatsView (view+6632 ctor 快照; +56 解析缓存; 宿主+5320 idpair 进; 析构安全) | 面板 target 绑定 |
| CShip+24 IOfficerHolder | vt[1]→+32; Update 0X141BEFB60 (缓存 win+10600) | 军官钮刷新 |
| CShip+232 舰体名 + def+968 | sub_140C3A0F0 (兜底 GFX_navalcombat_ship_icon_unknown) | 舰图标串 GFX_unit_\<hull\>_\<n\>_icon_medium |
| CShip+1576 旗 | sub_140C33A50 (define 15 门) + 逐帧 0X141BED5F0 | 流亡/可见谓词 + pride type_icon 切换 (CCountry+592/+596 vs 舰+8/+12) |
| CShip+1832 → tf+472 → CCountry+224 | sub_141BECFC0 | ≥1e5×define → ShipStats 资源门列表 |
| CTaskForce 数组 | CompactShipListView (UpdateCompactShipList, RTTI 定名) | 条目 entry+8/+16 idpair; **entry+1336 = 舰型 DB 索引, entry+1340 = 需求舰数** (COMPACT_SHIP_VIEW_DESC_REQ/TYPE; pride / required_ships_count 窗) |

#### 4.16.4 CFleet (writer 0x140D5EBC0; ⚠ 旧址 0x1412318A0 = CCountrySupplySystem writer, 清偿批勘误)

| 项 | 值 |
|---|---|
| RTTI 名 | — |
| sizeof | — |
| vtable RVA | — |
| writer | 0x140D5EBC0 |
| loader | — |
| 挂载点 | cc+360 容器 (fleet) |

| 键 (token) | fl 偏移 | 类型/语义 |
|---|---|---|
| name (27) | +224 | 串 |
| icon (181) | +256 | — |
| color (86) | +272 | 对象; f32×3@+288..296 = obj+16..24 |
| leader (10423) | — | — |
| task_force (15157) | *(ptr)+16 | — |
| strategic_region (12014) | — | — |
| assign_to_minimum_order (15603) | — | — |
| bombardment_region | +144/+156 | map 容器 {d@+144, count@+156}, 16B 元 {region ptr@+0 → id@ptr+88, val u32@+8}; 门 count≠0; 写序 = 容器序 (非 id 升序); 提取器: 首对 region 进键名, 余对 " k=v" 拼进值 |
| hours_without_patrol_missions_pairs | +48 | RH 表 (24B 桶 {dist u8@+4, region ptr@+8 → id@+88, hours u32@+16}, mask u32@+12, maxp u8@+16); 多 region 折单行 — 首对 region 进键名, 后续 " region=hours" 追加进值 (逐 region 多行 = 假 MISS) |

候选新偏移 fl+24/+44/+56/+196 (未决)。

CFleet/舰队视图 GUI 消费表:

| 字段 | 消费点 | 用途 |
|---|---|---|
| CFleet idpair (fl+8) | CFleetsBottomBarItem target@item+32 (SetTarget 0X141DE6F60 直拷 fl+8; ref.h:0x53 互证) | 底栏舰队项; fl+224 name 命中 |
| 选择集对象+1100 idpair → resolve → +32 CFleet* 数组 | CFleetsBottomBar (属主未决) | 选择集 target |
| tf ship 容器 (tf+840/+852) / repair_parent (tf+1200/+1204) / target_ship_types (tf+1856/+1868) / refid | CNaviesView (17×1288B 胶水块; 内嵌 CNavyLeaderWindow / CMoveShipsWindow / CTaskForceCompositionEditor / CCompactShipListView 四子件) | 选择集驱动视图 |
| tf+884 | CNaviesView 组行 | 任务类型枚举 (定案: ==8 = reserve, 与组行 reserve 判定同源) |
| tf+832 | MilitaryOverviewItem | leader 指针 |
| tf+496 | MilitaryOverviewItem | 当前 region 指针 |
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

命令族:

| 命令 | 载荷 | 用途 |
|---|---|---|
| CSetFleetLeaderCommand | {+40 leader, +48 fleet} | 舰队指挥官指派 |
| CCreateUnitLeaderCommand | {+44 = 2 navy} | 建 navy leader |
| CChangeNavyLeaderDialog | — | leader 更换对话框 |
| CSetFleetCommand | — | 拖放重编链 (REASSIGN_ALL_TASKFORCES 确认弹窗) |
| CConfirmDisbandFleet | — | 舰队解散确认 (RTTI 定名) |

舰队块 (cc+360 容器, 0x9C0 结构, tf→ship 两级): taskforce 顶层 id 对;
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
| +352 | RH 结构基 | convoy_escort_presence_history RH **结构基 @+352** (loader 插入点 = a1+344 ser; struct+0 8B 未名, data@+360=struct+8, mask@struct+20=+372, extra@struct+24=+376; 条目 40B 见 §4.16.11) |  |  |
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

#### 4.16.8 CNavalBase

CNavalBase (vtable 0X29731C0):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +16 | uint32 | province |
| +20 | uint32 | level |
| +24 | uint32 | max_level |
| +28 | uint32 | **修理容量** (min 钳 + 超容警报双证; GUI = CNavalBaseMapIcon populate 消费) |
| +32 | u32 | priority — writer ADFE0 按 u32 存读 (定案); ≠0 才写 |
| +40 | idpair | ships_in_repair 容器数据 (8B 内联对 {type@0, id@+4}); count@+52; **GUI: 修理队列数据源归属定案** (CNavalRepairWindow 队列 = CStrategicNavy+24 bases 容器 → 本字段, 非 §4.8 refit 生产线; 行类 CNavalRepairQueueNavalBaseEntry 行+3904 = nb / CNavalRepairQueueShipEntry 行+48 = 船 idpair); 发射 = `#N` 恒编号 (1 起容器序, 值 "id=N type=T") |
| +41..+51 | — | = ships_in_repair 容器尾  |
| +52 | u32 | ships_in_repair 容器计数 |
| +53..+63 | — | = ships_in_repair 容器尾 + disabled 前置  |
| +64 | string | **disabled_for_repairs 串列表** 容器数据 (token 0x3C4A = 15434, writer 直证); count@+76 |
| +65..+75 | — | = disabled_for_repairs 容器尾  |
| +76 | u32 | disabled_for_repairs 串列表容器计数 (⚠ CNavalBase+392 = owner tag u32, 与 CStrategicNavy+392 容器跨类同偏移并存, 勿混) |

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
| 任务类型写点 (在航) | sub_140D77E60(mission_obj, new_type) | 在航变体 | 定案 |
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

#### 4.16.14 战史 GUI 消费

**CSunkShipEntry** (宿主 CNavalLossesOverview, populate 0X1417FD790,
target = CSunkShipInfo* 裸指针 @entry+32): 10/10 字段全中
(name/owner/killer/date/definition/killer_definition/eq_variant/location);
killer-type 枚举 helper 0X140C2DFC0 / KILLER_AIR helper 0X140C2DF50。

**CNaviesViewSunkShipItem**: 经 CShip history 元素 +120 内嵌 CSunkShipInfo,
is_sunk 门 @entry+114 — sh+2264/+2316 history 容器双中, 详见 §4.16.3 / §4.31.29。

#### 4.16.15 sunk_convoys_history (gs 侧运输船损失月账)

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
