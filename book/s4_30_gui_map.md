

### 4.30 GUI 描述 ↔ 游戏数值 映射表

> **定位**: 主视图/面板/地图模式本体的 **GUI 类布局与本册主表并列** —— 每行 = **(GUI 面板/元素,
> 取值函数) ↔ (游戏对象+偏移) ↔ (语义字段) ↔ (loc key)**; 面板/窗本体类另立小节 (见尾段 §4.30.40 起)。
> 基类槽语义 = §4.00.2/§4.00.5/§4.00.6。域对象字段仍在各分册 (本册只留视图侧入口链/坐标校准/余量账)。

#### 4.30.1 州面板 (CCountryStateView)

**入口链**: SetTarget vt[11]
0X14174AA40 → **View+1408 = CProvince\* / View+1416 = *(prov+192) = CState\***;
populate worker = sub_14174ECF0 (州) / sub_14174DD50 (省) + 刷新 helper r1-r4 +
阻力填充 sub_14174E8E0; vt[14]/vt[15] = 窗口/行池管理 (零目标访问)。

| 面板元素/行为 | 取值函数 | 游戏对象+偏移 | 语义 (出处) | loc key | 置信 |
|---|---|---|---|---|---|
| 胜利点文本 (≠0 显隐) | sub_14174DD50 | CProvince+56 | victory_points (§4.14) | STATE_VIEW_WICTORY_POINTS/VALUE | 定案 |
| 省名占领着色 | r1 sub_14174C8E0 | prov+192→州+200 vs prov+392 | owner≠controller → 着色 | STATE_PROVINCE_NAME_OCCUPIED_COLOR | 定案 |
| 省名 "+TAG" 后缀 | r1 | CProvince+392 | controller (§4.14) | STATE_PROVINCE_PLUS_TAG | 定案 |
| 地形图片 (冬季后缀) | r1 | *(prov+184)+168 → def 名@+24 | 地形 def (§4.14 描述符) | terrain_picture + "_winter" | 定案 |
| 冬季图标 | r1 | sub_140F19EE0(gs+1672 表, prov+164) 对象+64>0 | 天气/温度表 | temperature_icons | 定案 |
| 战略位置行 (省侧) | r2 sub_1417507F0 | CProvince+320/{+332 count} | strategic_province_location (§4.14) | strategic_locations_grid | 定案 |
| 战略位置行 (州侧过滤) | r2 | CState+2048/{+2060}, 条目 v4[1]==prov.id | strategic locations (第二 u32 = prov_id 定案, §4.31.7) | 同上 | 定案 |
| 必需规则图标 | r4 sub_14174C500 | *(prov+184)+152 ≠0 | 必需规则对象 (§4.14 描述符) | province_required_rule | 高置信 |
| 州名文本 (两级回退) | sub_1409D91D0 | CState+56 (size@+72) → 回退 +232 (size@+248) | name / 匿名串 = state_name 回退源 (§4.13) | state_name | 定案 |
| state_owners 核心国旗行 | sub_14174ECF0 | CState+176/{+188} | cores (§4.13) | state_owners (+1520 列表) | 定案 |
| state_owners 宣称国旗行 | 同上 | CState+152/{+164} | claims (§4.13) | 同上 | 定案 |
| state_owners 争夺国行 | 同上 | CState+208/{+220} 4B tag 流 | contested_owners (§4.13) | 同上 | 定案 |
| state_owners 头文案键 | 同上 | CState+200/+204 + sub_140BB52F0 同国谓词 | owner==controller 切换 | state_owners_size_when_owner_(not_)is_controller | 定案 |
| controller_flag 双旗隐藏门 | sub_1409D5390 | CState+408/{+420 count, +432 total} share=1e10*amt/(1e5*total) | 占领份额 (§4.13); owner 份额==100% → 隐藏 | controller_flag / controller_flag_border | 定案 |
| 州建筑行 (两列表分流) | sub_14174ECF0 | CState+288 CBuildingStatus (+104 def 行选择 / +32 重映射 / +56 实例数组) | buildings (§4.13); def+704 旗分流共享槽池 | state_building_entries / state_shared_slot_building_entries | 定案 |
| 建筑修正图标可见性 | r3 sub_14174C6F0 | 州+368/{+380} 实例→CBuilding+104 (=+88 CModifier pairs) 或 省+480/{+492} | 建筑修正来源 (§4.14) | building_modifiers_ico | 定案 |
| 人力文本 | sub_14174ECF0 | CState+2104 → +2128 (u32, 经 sub_14072DEA0) | manpower_pool.total (§4.13) | manpower + STATE_POPULATION_VALUE | 定案 |
| 共享槽计数 NUM/MAX | sub_1409D4980 | CState+2136 extra_shared_slots + owner 国(+1448)×类别; category=="wasteland" → 0 | extra_shared_slots (§4.13); +2200 def SSO 首证 | shared_slot_count + UNLOCKED_SLOTS | 定案 |
| 阻力/合规容器 | sub_14174E8E0 | CState+616 CResistance (sub_140F9B4B0 激活门) | CResistance@616 (§4.13 全布局) | state_resistance/compliance_status_container | 定案 |
| dynamic_modifiers_grid 行 | r1 | CState+1968/{+1980} 64B 条 → 行+40 tag/+44 state/+48 days/+56 def/+64 enabled/+72 values | dynamic_modifier (§4.13) | dynamic_modifiers_grid | 定案 |
| 州资源窗 | sub_14174ECF0 | 资源 def 由 DB 迭代, 值经行对象持州回查 (sub_1409D3C70 消费 st+204 部分) | resources (§4.13 +440 块) | state_resources_entries | 高置信 |
| 省建筑行 (def 侧) | sub_14174DD50 | CProvince+400 CBuildingStatus; 可见性门 def+8==19649 (= rail_way) / +802 / +824 / +883·885 DLC | buildings (§4.14) | province_building_entries | 定案 |

**CBuildingStatus 三字段** (定案, 见 §4.14):

| 项 | 结论 | 证据 |
|---|---|---|
| CBuildingStatus+104 | 类别旗掩码: bit0=省类 / bit1=州类 / bit2 第二类 (ctor 5 = bit0\|bit2; 省侧全奇 {1,5} / 州侧全偶 {2,6}) | 经 sub_1406870A0 → 建筑 DB+904 类别行表 24B×5, 探针 |
| CBuildingStatus+108 | 所属 id 副本 (省 id 25/25; 州 id = st+88 12/12) | 探针 |
| CBuildingStatus+112 | 内联控制器 tag 槽 (≤0 = 无, 回落省+392/州+204; 全档 50 样本 0) | 探针 |

**未决** (书中未名): 建筑 def +704 / +874 语义; CCountry+3944 (energy 按州查询) / +1448
(共享槽基数输入); sub_1409D8F90 的 163/164 键、gs+992 每省 map item 族 (+32/+44 max 扫描 /
+472 状态块)、管理器 **CInGameIdler** (qword_14332F698, RTTI 实名) vt[120] 对象 +1776 省字节表、
sub_140BB52F0 同国谓词的关系语义 — 见 §4.30.21。

#### 4.30.2 师设计面板 (CDivisionDesignerView)

**入口链**: 目标 = **「编辑会话」对象 ES** (0x908,
divisiontemplatemanager.cpp 断言实名), 存 **View+11096** — 非 CCountry/CArmy/模板本体。
SetTarget 无虚槽 (三通道: sub_14168D4C0 编辑现有 / sub_141762BC0 新建 / sub_14168B520
mode=0); Refresh = @40[9] Repopulate 0X141768250; Reload = @0[2] 0X141763770。
⚠ **基链与 CCountryView 同族不同序** (`CReloadableInterface@0` + iface@40 +
tooltip@64 + **CModelListItemParent@72**; 主虚表仅 6 槽) —— §4.00.2 的 17 槽大表
**不可跨类硬套**, 各 View 逐类解基链。

ES 要点: +0 模式枚举 / +4 国家 tag / **+8 `_pCurrentTemplateData` 草稿 CDivisionTemplateData\*** /
+16 原始快照 (内嵌 0x248) / +2256 模板 wrapper / +2264 活数据 / +600·+2280·+2288 三个统计
预览对象 (统计数组 @+160 起 8B/项按 statId 索引)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key | 置信 |
|---|---|---|---|---|---|
| 面板打开目标 (国家) | sub_141762BC0 ← 根窗 vt[20] | ES+4 (tag) → CCountry | 设计师固定编辑属主国 (§4.3) | — | 定案 |
| 优先级按钮 0..3 | sub_14168DF80 | CDivisionTemplateData+396 | priority (§4.18), clamp dword_143337338 | TEMPLATE_PRIO_0..2(_DESC) | 定案 |
| 名字输入框 | sub_14168DF50 | D+8 SSO | name (§4.18) | DIVISION_DESIGNER_RENAME | 定案 |
| 模型覆盖名编辑框 | 0X141763F10→sub_140BA6030 | D+504 SSO | override_model (§4.18); 脏旗 view+17705 | division_designer_model | 定案 |
| 三网格摆格/拆格 | sub_14168E150/BF90/B600/B520 + sub_140FBF5F0 | D(或快照)+72/+104/+136 | regiments/support/regimental_support (§4.18) | regiments_grid 等 | 定案 |
| is_army_hq 摆放重排 | sub_14168B430 | D+436 → 格重排 | is_army_hq (§4.18) | hq_view/non_hq_view | 定案 |
| 统计行数值+红绿增量 | sub_1417641A0 | 预览对象+160+8×statId (新=es+2280 或 es+600; 旧=es+2288) | 预览统计数组 | DESIGNER_NO_STAT/STAT_VALUE | 定案 |
| 战斗宽度/人力/训练行 | 0X1417645E0 行槽 +176/+184/+192 | 预览统计派生 | combat width / manpower / training_time | DESIGNER_COMBATWIDTH 等 | 高置信 |
| 装备原型池输入 | sub_14168B9E0→sub_14100E140 | D+264 × 国家+3944 | CEquipmentArcheTypePool × CProductionStatus (§4.18+§4.8) | — | 定案 |
| 生产成本 (IC) | sub_140B99D50/AB00 | D × 国家+3944 | 生产成本 min/max | DIVISION_PRODUCTION_COST_VAL | 高置信 |
| 装备类别过滤 | reset_equipment_categories_filter_button 群 | D+320 forbidden / D+180 校验 (×国家+3952) | forbidden_equipment_types + 可用性 (§4.18) | EQUIPMENT_CATEGORIES_DESC | 定案 |
| niche 图标列表 | sub_14176F490 | D+580 equipment_niche | equipment_niche (§4.18) | niche_icon_* | 定案 |
| 可改性总门 | sub_140BA2440/93230 | D+468→国家+436 templates_locked; D+541 is_locked; D+576 cap | 模板锁三重门 (§4.18/§4.3) | DESIGNER_LOCKED | 定案 |
| 保存/修改模板 | sub_14168D4E0 | 草稿全套 → CCreate/CUpdateDivisionTemplateCommand | **+632 = 三差之和 = 经验差价** (提交走 CCommand 层 §4.00.6) | DESIGNER_ARMY_SAVE 系列 | 定案 (差价=经验 推定) |
| 选中师改模板 | sub_141761CD0 | view+11336/+11928; 簇 1328..1348 **属 CDesignerEquipmentCategoryItem 非 CArmy (见 §4.30.5)** | 现编成铺格 + 构成标签 | DIVISION_MODIFICATION_* | 高置信 |
| HQ 部署 CP 行 | populate 缓存 view+17744 | CCountry+496 command_power | CP 余额 (§4.3) | HQ_DEPLOY_CP_COST | 定案 |
| 悬停 tooltip | 0X14175F4F0 (@64[0]) | 按元素名分派, 读 ES/草稿全套 | BuildTooltip (钩子契约 §4.00.2) | DIV_TEMPL_SYMBOL_TOOLTIP 等 | 定案 (机制) |

**定名收口** (见 §4.18):

| 项 | 结论 | 证据 |
|---|---|---|
| override_model_equipment_category_filter (tok 16902) | 16B = {i64 类别值, 门 u8@+496}; 门字节 = sub_14176EFB0 的 UI 重建门; 写点先清 override_model 再写 | 游戏内 lexer 直名 |
| CDivisionTemplateData+400 | 首格惰性缓存指针: getter 为 0 时取 regiments 网格 (0,0) 现算回填, 空网格 → Null Object 单例 | 二进制文件 |
| rail_way | 省 def 列表恒含铁路 | lexer |
| tok 12112 | division_template (effect Parse 键名) | lexer |
| CCountry+3944 | CProductionStatus | 三证 |

**CArmy+1328..+1348 簇**: 全簇属 **CDesignerEquipmentCategoryItem** (设计器行项, 非 CArmy;
ctor sub_1414991A0 三链定案, 见 §4.30.5); 用法语义 = 选中师铺格 dispatch: +1336 值 /
+1348 网格类别 1\|2 / +1328 关联对象 byte+16 旗; sub_1414A38A0 注册回调: 旗@+1344 门 →
推 {+1336,1} 进设计器。

**未决**: CDivisionTemplateData+488 (16B getter/setter 对); CCountry+3952 (D+180 16B 条
可用性校验表); 预览统计对象类身份 (0x678B, 与 CArmy+312 同类); 陆军经验显示的源偏移。

**窗壳（重锚后零漂移，1.19.3 全址已重定）**：主 vt **0x1429FAA00** + @40 0x1429FAA38 + @64 0x1429FAA90 + **@72 CModelListItemParent 表（1 槽）0x1429FAAA8**；视图规模 0x5CC0=23744B；注册宿主 = 装配器 0x140B614C0（注册槽 +592）；ctor **0x1417591C0**；槽：@40[7] Update = 0x141762360 / @40[8] IsOpenAndVisible = 0x141761AB0 / [9] Repopulate 0x141768250 / Reload 0x141763770 / 名字提交 0x141763F10 / tooltip 0x14175F4F0 / 新建 ES 0x141762BC0；**两控制器 +17720/+17728**（激活 0x141DD0190/0x141DD2A90，门 0x141DD01B0/0x141DD2AC0，喂食 0x141DD0320，崩溃于 @0[5]，创建于 @0[4]）；+17776/+23640 两 CEmptyEntryListBase 模板实例（ctor vtable 直证）；Conveyor 壳：ctor 0x141D83A10 / Setup 0x141D890C0（18 窗名，vt 索引 136/104/120）/ 创建宿主 0x14172C530（sizeof 0x1AB0=6832 再证）；scoped_ref 两 helper 0x141D82170/0x141D823C0（模式号 20/21 直读）。ES 表补三行：**+2272 = 多态新建源（ctor 0x140B95230）** / **+2296 = 立即执行旗（Accept 核 0x14168D4E0 消费）** / **+2304 = ctor a3 u8**；命令 ctor 1.19.3：CSetConveyorNameCommand 0x141BA18C0 / CSetConveyorSeriesCommand 0x141BA1A90（+胶水 cb 0x141D88290/0x141D887C0）。

#### 4.30.3 生产面板 (CCountryProductionLineView)

**入口链**: **target = CCountry 本体** (根窗 vt[20] → tag →
sub_140BB48F0 → **cc+3944 CProductionStatus 直读**, 无存储式 SetTarget/无会话对象);
vt[11] 在本类语义转义 = 「面板开着点地图省」→ CSetNavalDeploymentTarget/
CSetShipRefitDeploymentTarget 命令 (pProvince 断言实锤); 拖拽重排 = @1408
CStandardGridBox::CReorderObserver → 全表 CChangeProductionLinePriorityCommand (线+68)。
⚠ 又一「同族不同序」实例: 基座 +1408 target 锚对本类失效 (被行池占用)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 面板目标国 | vt[20] (view+1344/+1392) → sub_140BB48F0 | CCountry (+3944 CProductionStatus) | 面板恒显窗口属主国, 无存储式 target (§4.3) | — | 定案 |
| 运营军工厂双读数 | sub_141743200→sub_14173B2D0 | ps+696 (÷1e5) − ps+760 − ps+768 / − ps+728 − ps+752 | 军工厂池 val 与两组分配 dword (§4.8 +688 池) | PRODUCTION_OPERATIONAL_FACTORIES_VALUE | 定案 (读法) / 组语义推定 |
| 造船厂读数 | sub_14173B2D0 | ps+792 (÷1e5) | 造船厂池 val (§4.8 +784 池) | dockyards_output_value | 定案 |
| production_output 值 | sub_1415C9EB0→sub_1415CA210 | cc+1464 token 0xD4/0xA8 × ps+936 | 民用池 factor<1e5 时改写输出公式 | production_output_value | 定案 (链) / 公式语义高置信 |
| dockyard output 值 | sub_1415CA060 | cc+1464 token 0xD6 + 同上 | 造船厂输出 | dockyards_output_value | 定案 (链) |
| 效率上限/增长/损失/工厂轰炸防御 | Repopulate sub_14055E360 | cc+1464 token 0xA9/0xAA/0xA5/0xD9 | country_modifiers 查表 (§4.3 +1464) | efficiency_cap/growth/loss、factory_bombing_defence_value | 定案 (读法) / token 名未定 |
| tab 使能 (tank/infantry/aircraft) | sub_141739E20 (断言实名) | ps+696 > 0 | 有军工厂才亮 | tank/infantry/aircraft_button | 定案 |
| naval tab 使能 | 同上 | ps+792 > 0 | 有造船厂才亮 | naval_button | 定案 |
| 生产线列表 | sub_14173FEA0 | ps+88 {data} / ps+100 {count} | lines 容器逐线建行 (§4.8) | production_lines/item_grid | 定案 |
| 行工厂 +/− | sub_141D5F450 → CAddProductionLineFactoriesCommand | 线+232 (现值), clamp 0..线 vt[11] (变体+1440→arch+1440→dword_143335FE0) | 工厂增减, 步长 1/5/10 | increase/decrease 族 | 读法定案 / +232 语义高置信 |
| 行数量 (amount) | 0X141D5FF20 等 → CSetProductionLineAmountToProduceCommand | 线 id 对 @+8/+12; 载荷@cmd+48 | 数量提交; 变体+1208==3 走换装选择流 | — | 定案 (命令) |
| 行优先级 ▲▼ | sub_141D60520/BF70 → CChangeProductionLinePriorityCommand | 线+68 (新值 = +68+1; shift→9999) | priority (§4.8) | increase/decrease_priority | 定案 |
| 拖拽重排行 | @1408[0] 0X14173EDF0 → 同命令 | view+9200 行池 → 各线+68 全表重排; 改读 **view+9224 过滤序数组** 定位 | CReorderObserver = 批量优先级重排 | item_grid | 定案 |
| 行换装/转换 | 行 vt[18] 0X141D61290 → CSetProductionLineConvertCommand | 门 = 线+236 u8 (= **`is_converting`**, tok 14304; 邻 +237 `collapsed_interface` 14608 / +240 `interface_factory_scale` 14679 / +224 `non_conversion_speed` 14330) + 变体内部 (宿主+1008→+1016/+1366/+1180) | 换装 (转换惩罚走命令) | — | 定案 |
| 类别合计 (6 类) | sub_14173FEA0 switch | (线+24+线+28) 按变体类别 token 分桶 | 每 line active+damaged 合计 | show_equipment 等 6 徽标 | 定案 |
| 显示过滤 6 项 | populate 复选框绑定 | view+9512 token 表 {14700..14704, 15665} | resources/stockpiling/reinforcing/upgrading/outdated/refitting | show_* | 定案 |
| 上段 used 计数 | sub_141743200 | totals[7]/[8]/[9] (naval 行+13208 三档) | used_upgrading/outdated/refitting | factories_used_* | 高置信 |
| 新舰部署母港/舰改编目标 | vt[11]→sub_141DB3390 | 窗+1408/+1416 选中 id 对 + 省 | CSetNavalDeploymentTarget / CSetShipRefitDeploymentTarget | — (pProvince 断言) | 定案 |
| 工厂格图标悬停 tooltip | 0X141D54820 (CProductionFactoryItem 槽0) | 双分支: 军工厂 (线+32 owner ps 链) / 造船厂 | **PRODUCTION_FACTORY_ASSIGN_DESC / PRODUCTION_DOCKYARD_ASSIGN_DESC** (§4.31.30 互证 — 宿主 = 工厂格图标非行) | FACTORIES/OUTPUT | 定案 |
| 顶部资源条 | sub_141D6DAC0→sub_140CAED60 | cc+4600 (按 CStrategicResource) | 国别资源/租借值 (§4.3 +4600) | resources_grid | 定案 |
| 生产线效率列 | 0X141937ED0 (效率上限计算, 读 vt+88 基数 + sub_140C97B90 判 1e7 档) / 0X141939760 | 线+192 Q15 数组 (+204 count); 累计/钳制核 sub_140F6E840 (`100000*v4/v2` → /1e5 → 线+236 换装门 → sub_141939950 + sub_141937DD0) | factory_efficiencies (§4.8); **行 UI 绑定 = 行对象 vt 出口** (无独立窗口柄) | — | 定案 |
| 面板刷新链 | [9]/[10]/@48[5]/@48[7] | view+9536/+9488 脏旗 | 玩家比对脏旗 + 日期门 + 可见门 | — | 定案 (机制) |


**窗壳骨架**（1.19.3 重锚：四 facet 骨座 17/2/10/4 同序同数，槽函数群址族 0x133550；
TD 0x143287B48；主 vt 0x1429F7430 / @40 0x1429F74C0 / @48 0x1429F74D8 / @1408 0x1429F7530）：

| facet / 槽 | 语义 | 函数 | 备注 |
|---|---|---|---|
| 主 [0] | dtor | 0x141739B00 | — |
| 主 [2] | Reload | 0x141740600 | 清串经 sub_1412374F0(view) → vt+96 (基类 reload 共享形) |
| 主 [7] | 关窗/收起 | 0x14173DEF0 | 五窗口群 +9504 逐一 hide；尾调 **sub_141C3C390(view+9544)** |
| 主 [9] | Refresh thunk | 0x14173EC50 | jmp rel32 → 0x14173EC60 (体) |
| 主 [10] | 日期门 Refresh | 0x14173EBE0 | 置脏旗 view+9536 |
| 主 [11] | SetTarget (转义) | 0x14173F270 | 面板开着点地图省 → 部署命令 (§4.30.3 入口链) |
| 主 [13] | 同通道第二入口 | 0x14173F120 | — |
| 主 [14] | populate 主 | 0x141740A40 | close_button → view+9344；military_tab → production_lines → item_grid |
| 主 [15] | populate 副 (teardown) | 0x14173A340 | 首调 **sub_141C3B7D0 (view+9544)** |
| @40 [0] | BuildTooltip | 0x14173BD90 | — |
| @48 [5] | 可见才 Repopulate | 0x1417167F0 | 体 = visible 门 → vt+72 |
| @48 [7] | Update | 0x14173F2D0 | 三脏判 (view+9536 / +9280 / +9296 子窗) → @48[9] Repopulate |
| @48 [9] | Repopulate | 0x1417429F0 | 五窗口群复位 + 行池交叉 |
| @1408 [0] | 拖拽重排 | 0x14173EDF0 | 读过滤序数组定位 |

**基帧规则**: @48 facet 函数体内 `this = view+48`（mdisp=48），体内 `a1+N` 记作 view+N 须
**+48 归一**；主表 @0 facet 不受影响。归一后的真偏移：

| 原稿标签 | 真 view 偏移 | 语义 | 置信 |
|---|---|---|---|
| view+9176 / +9188 | **+9224 / +9236** | 过滤/排序行数组 {data, count}（Update 逐行 vt+144，拖拽 @1408[0] 定位；写者 **sub_14173AEE0**(view, view+9512 复选框 token 表, view+9224)，按 tok 14700/15665 与线 vt+200/+216 过滤建序，由 sub_141743200 每轮调用） | 定案 |
| view+9232 / +9248 | **+9280 / +9296** | 两子窗口包装（脏判可见；Repopulate 复位） | 定案 |
| view+9488 | **+9536** | Refresh 脏旗（[10] 置 1 / Update 消费清 0；与「+9536 脏旗 #2」同一字段） | 定案 |
| view+9448 | **+9496** | 0x28 资源条同步对象（内部 {data@0, count@+12}）；`sub_141D6DA80` 逐项 `sub_141D6DAC0` 刷新；ctor sub_141D6C790(view 根+1272) 建 | 定案 |
| view+9456 | **+9504** | 对象（+2804 id 对空/无效经 sub_14221F310 判 → vt+64 复位）；populate 经 `sub_141DA9530(malloc(0xB00), view+1392)` lazy 自建（`if (!v173)` 门） | 定案 |

**元素柄群与 glue 观察者**（全零漂移；1.19.3 新增实名 glue 内嵌）：

| 柄群 | 偏移 | 语义 | 置信 |
|---|---|---|---|
| 五窗口手柄群 | **+9264 / +9272 / +9280 / +9288 / +9296**（+9288 = CProductionNavalDeploymentWindow；+9504 尾件） | Reload / [7] / Repopulate 三处同集复位 | 定案 |
| 五类别按钮 | **+9304 / +9312 / +9320 / +9328 / +9336** | tank / infantry / aircraft / naval / naval_repair_button | 定案 |
| 四按钮 glow | **+9352 / +9360 / +9368 / +9376** | tank / infantry / aircraft / naval_button_glow | 定案 |
| close_button | **+9344** | populate 装配 (.rdata 串直读) | 定案 |
| 网格两柄 | **+9384** production_lines / **+9392** item_grid | item_grid 由 production_lines vt+432 取；`sub_1422C6650(item_grid, view+1408 观察者)` 挂 CReorderObserver | 定案 |
| 十二复选框柄 | **+9400..+9488** | show_equipment 族 12 项 | 定案 |
| 按钮 glue ×5 | **view+1416 起、1288B 步长**（+1416/+2704/+3992/+5280/+6568） | 内嵌 CLegacyButtonObserverGlue<> 实例 | 定案 |
| 复选框 glue ×12 | **view+7856 起、112B 步长** | 内嵌 CCheckBoxObserverGlue<> 实例 | 定案 |
| 资源条读数 helper | — | sub_141D6DAC0→sub_140CAED60 | 定案 |
| 工厂步长修饰 | — | sub_141D52A00 | 定案 |
| 线 id 对访问器 (行→线) | — | sub_141D52C40 | 定案 |
| 命令执行器/管理器 | — | sub_142250B00 / 全局 qword_14332F698 = **CInGameIdler**（RTTI 实名，主 vt 0x142968FF0；取执行器 vt+136）; **+1720 = CInGameInterfaceHandler** (ctor sub_140DC1B30 内 `*(a1+1720) = sub_140B614C0(...)`), 其 **+1240 = NNotification::CNotificationHandler** (见 §4.17) | 定案 |
| 行基类 ctor | — | CProductionLineItem sub_141D4B340（行+2600/+2608 优先钮、+2624 线 id 对） | 定案 |
| 行 ctor 四档 | — | sub_141D4C540 (0x3DA8) / sub_141D4B780 (0x33A0) / sub_141D4E540 (0x3398) / sub_141D4F5B0 (0x2478)；分派依线 vt+192/+200/+208/+216 | 定案 |
| 行类基 vt | 0x142A6CE20 | RTTI 直读 | 定案 |

> 行键 = (线指针, 线+237 u8)；旧行匹配 `sub_141D52C40(old)==线 && *(u8*)(old+8016)==v237`；行池
> view+9200 {data}/+9208 cap/+9212 count；新建行挂 view+9392 网格（grid+416 数组 / +428 count，
> 移除经 grid vt+632）。行三负荷按钮 **+7936 / +7944 / +7952**（负向取负）经
> CAddProductionLineFactoriesCommand（ctor 0x141143520，0x38B）下令；CChangeProductionLinePriorityCommand
> ctor 0x141143C00。view+9396 = **死槽**（全 dump 0 读点; +9384 production_lines 与 +9392 item_grid 之间的填充槽, ctor 置 0 后永不触）;
> view+9544 = **NIndustrialOrganisation::COrganisationListWindow**（窗名 `industrial_organisation_list_window`, 无独立 RTTI 表项, vftable 串定案; ctor sub_141C3A650; 同族内嵌于装备设计器 sub_141776C00(a1+72) / MIO 详情窗族等）; BuildTooltip 与 populate 余段未逐行。

**定名收口** (writer 键 + 断言串 + lexer, 见 §4.8):

| 项 | 结论 | 证据 |
|---|---|---|
| 线+232 requested_factories (tok 13769) | CAddProductionLineFactoriesCommand 写入字段; setter clamp ≤ GetMaxAllowedFactories (线 vt[11] → 变体+1440 → arch+1440 → 默认 dword_143335FE0 [KR=150]) | 断言 nFactories; Execute 二进制文件 |
| is_converting (tok 14304) | 连带 +224 = non_conversion_speed (tok 14330) | lexer |
| collapsed_interface (tok 14608) | — | lexer |
| 线+240 interface_factory_scale (tok 14679) | ≠1 门 | lexer |

**定案**: 池+752 = **已分配产线工厂总量** (写者 sub_140E6C810 双写 `+752 += v` 与 +760/+768 同步 → **≡ +760 + 768 累加镜像**, 非「军池+64 独立字段」); 消费 sub_140E611B0 `(int)*(ps+696)/1e5 − +752 − +728`。变体+1060 = §4.23
CEquipmentVariant+1060 obsolete 定案 (换装遍历 sub_140BE2B90 以它为跳过门);
效率族 4 token (0xA9/0xAA/0xA5/0xD9) 名未定。

#### 4.30.4 装备设计面板 (CEquipmentDesignerView)

**入口链**: target = **CEquipmentVariantBuilder**
(equipmentvariantbuilder.cpp 断言实名, sizeof 8800B), 内嵌 ×2 于 **view+14232 (主编辑) /
+23032 (母本对照)**; SetTarget = 自由函数 sub_141788C50(view, CEquipmentVariant\*) (无虚槽;
handler 0X140B6C220 按变体 _pType 路由到 handler+600/608/616 三个设计器实例); 载入变体 →
builder#1、其 live parent → builder#2。**CEquipmentVariant 消费偏移 16/16 全命中 §4.23.1 (零未名)**。
顺带添证: cc+3952 (未名) 与 ps+256 (§4.8 未名) 各 +1 证; 0x1F0037FC00=AIR 位段再证。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 面板目标 (编辑会话) | sub_141788C50 (无虚槽, handler 0X140B6C220 路由) | view+14232 builder#1 (CEquipmentVariantBuilder); 变体→+4976/+6184 双拷贝, parent→+7392 | target = 编辑会话 builder ×2; 母本 = variant+1016 live parent 或自身 | — | 定案 |
| 打开路由 | sub_140B6C220 | variant+1008 (_pType) 谓词 → handler+600/+608/+616 | 三视图实例按装备类型分派 (ingameinterfacehandler.cpp:0x9F0) | tank/plane/(country)equipmentdesignerview | 定案 |
| 模块槽行 (可编辑/固定) | sub_141787980 | CEquipmentType+112/{+124} 80B 槽表 (id@+8); 行池 view+73872/+73896 | 槽行按 token "fixed_" 前缀分池 | equipment_designer_module_slot_entry | 定案 (读法) |
| 装模块/拆模块 | sub_141775290 → builder FEE0/D3C0 | draft+184 modules; builder+8776 槽-模块表 | 模块编辑落草稿 (非命令, 会话内直改) | sfx_ui_sd_module_default; MODULE_SLOT_* | 定案 |
| 升级等级选择 | 0X141793B30/0890/0A40 → builder 4803D0/F120/D240 | builder+8632 CEquipmentUpgradesInstance | 三通道 (设/复位/自动); 国别上限 sub_141537940 | AUTO_UPGRADE_BUTTON_DESC | 定案 (通道) / 逐通道语义推定 |
| 角色下拉 | sub_14177BD10 → builder FB00 | builder 草稿 (role 字段经 FB00 内部) | 坦克角色变更; 失败文案读 镜像#1+40 名 | EQUIPMENT_DESIGNER_UPDATE_DESC_NEW_ROLE | 定案 (链) |
| 变体名 | sub_141786550 ← E230 (builder) | draft+40 name SSO (经 E230 拷出) | 按模式 0/1/2 取 草稿/母本/现役 名 | EQUIPMENT_DESIGNER_EMPTY_NAME | 定案 |
| 模型覆盖名 | view+69096 CEquipmentDesignerModelSelector ← sub_141784780 | variant+1072 override_model | SetTarget 镜像; E440 与 ref+1072 比对判改 | EQUIPMENT_DESIGNER_UPDATE_COSMETIC | 定案 |
| 引用变体网格 | 0X141793E10 | view+62392 条目+1376 = CEquipmentVariant*; 选中 view+31840 | 引用/升级候选变体选择; 选中重算预览#3 (sub_141492A10) | — | 定案 |
| 国家过滤 | sub_141784520 | view+62488 tag 数组; 行条目+1384 tag | AddCountryVariantFilterItem: 按创建国过滤 (FOREIGN/OWN_FILTER 语境) | EQUIPMENT_DESIGNER_OWN_FILTER/FOREIGN_FILTER | 定案 |
| 历史设计列表 | sub_141784A80 / sub_141784890 | CAIEquipmentDesignEntry+5544/+552/+556; view+74064/+74104 | AI 历史设计条目 + 文件夹过滤 (HISTORICAL_PRESET 特例); 条目 0x1138B | — | 定案 (机制) / 条目内部未决 |
| 保存按钮 | sub_141791920 | XP 余额 sub_1412A8A80(国家,_pType); 成本 sub_14148F460(builder) | 余额/成本+已改判定 → SAVE/UPDATE_DESC 系; 提交走 CCreate/CUpdateEquipmentVariantCommand (§4.33) | EQUIPMENT_DESIGNER_SAVE(_DESC) | 定案 (文案) / 命令提交链未逐条清 |
| XP 余额监视 | @40[7] Update 0X141787730 | view+31832 缓存 (fixed5) | 余额变化→自动 Repopulate | EQUIPMENT_DESIGNER_ARMY/NAVY/AIR_XP_COST | 定案 |
| niche 图标 | view+73808 列表 + Repopulate | draft+580 族 (经 builder) | niche 选择 | CSetEquipmentVariantNicheIconCommand | 列表定案 / 草稿字段消费未逐行清 |
| mission 过滤掩码 | Repopulate | view+58264 vs variant+1040 | 选中机种任务不含于变体→收起该段 | — | 定案 |
| 类别掩码聚合 | sub_141790600 | 镜像#1+1032 (+20240) | 预览#2+1448 / cc+3952 def+1448 并入 +31864 | VARIABLE_CATEGORY_TOOLTIP 语境 | 高置信 |
| 面机角色缺武器 | Repopulate 末段 | *(镜像#1+112) 槽表 + sub_140BDA480 | 槽全空判 → 文案+隐显 | EQUIPMENT_DESIGNER_PLANE_ROLE_REQUIRE_WEAPON | 定案 |
| blueprint 类型名 | sub_141788340 | sub_140BDC6A0(镜像#1) + _pType+24 | "EQUIPMENT_DESIGNER_BLUEPRINT_TYPE_NAME" (TYPE 参) | 同左 | 定案 (单链) |
| is_frame 模式三态 | sub_14177E000 | view+31849/+31850/+19236; E670/E700/EC00/EDD0 | 3=非frame未改 / 1=frame 新设计 / 2=改现役变体 (creator 同国) | EQUIPMENT_DESIGNER_SAVE_DESC(_NO_CHANGE_TO_PARENT) | 定案 (读法) |
| 起源显示 | sub_141784780 尾 | variant+32 origin | "---" (0) 门控 EE500 | — | 定案 (读法) |
| 角色图标回退 | sub_141790050 | view+31968 ← 数据库 (sub_14062F120) | role_icon_index=0 时按库回退 | — | 定案 (单链) |

#### 4.30.5 陆军视图三件套 (StatsView / BadgeView / DivisionListView)

**入口链**: **第五种 target 变奏 = idpair 快照** —
CArmyDivisionStatsView ctor sub_1402EB660(view, handler, CArmy\* raw) 直拷师 idpair
(raw+24)@view+1664 (师析构安全), 消费统一 sub_14221F310(idpair) → res−16; BadgeView target
= badge+504 idpair → **COrdersGroup(军)/CArmyGroup(集团军)** (+57 旗判型); DivisionListView
target = view+272 {count@+284} 师 idpair 数组 + +260 部署军团。**CTemplateChanger 首次入册**
(6 槽抽象: [1]=CollectTargetDivisions / [2]=CollectAvailableTemplates, 遍历 cc+440 模板容器,
滤锁门 sub_140BA2440 + obsolete + is_army_hq 旗)。
⚠ **CArmy+1328 簇归属**: +1328/+1336/+1344 全簇属 **CDesignerEquipmentCategoryItem**
(设计器行项, ctor sub_1414991A0; +1328=CDivisionDesignerView\* / +1336=division_names_group
载荷 / +1344=点击旗), 非 CArmy 域; §4.18 缺口区 +1228..+1415 与此簇无关。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| StatsView 面板目标 (单师) | ctor sub_1402EB660 (无虚 SetTarget) | CArmy+24 idpair → **view+1664 快照**; 消费 res−16 | target = idpair 快照形态 (师析构安全); 师设计器/列表同族第五变奏 | — | 定案 |
| StatsView 改编目标查询 | CTemplateChanger[1]/[2] | view+1584 idpair; CArmy+1584 leader u8 | [1] 导出单师; [2] 模板集按 leader==is_army_hq 匹配 | — | 定案 |
| 可改编模板列表 (两视图共享) | sub_14169D590 | cc+440/{+452}; data+436 is_army_hq / +542 obsolete / 锁门 sub_140BA2440 | 锁+过时+HQ 三滤 | CHANGE_TEMPLATE_UNIT 语境 | 定案 |
| template_change_icon | @64[2] 0X1416AD770 | CArmy+960 old_template ≠0 → 显 | 改编待生效指示 | — | 定案 |
| 撤编按钮文案/门 | sub_1416BE4F0 | CArmy+476 expeditionary_owner (回退 +472 owner); +1584 leader | 远征师换远征按钮组+旗签; HQ 师加撤编注记 | DISBAND_ALL_UNIT / DISBAND_BUTTON_HQ_WITHDRAW_NOTE / SPECIAL_UNIT_CANNOT_BE_DISBANDED | 定案 |
| 硬度 stat 行 (tooltip) | BuildTooltip 0X1416A2270 | **CArmy+312 统计对象+184 (statId 3)**, fixed5 | 装甲度; SOFT_ATTACK_TAKEN = 1e5−值 (0x678B 统计对象族) | STAT_VALUE / SOFT_ATTACK_TAKEN / HARD_ATTACK_TAKEN | 高置信 |
| combat width | CArmy vt0[46] 0X140C7D9B0 (双出参) | CArmy 虚槽 (无存储偏移) | 战斗宽度 (现值+上限 推定); 书 vt 表新行 | COMBAT_WIDTH_DESC / DESIGNER_COMBATWIDTH_TOOLTIP | 定案 (读法) |
| 装备构成 8 类 | BuildTooltip → sub_140B9D860 | **CArmy+904 vector** ⊕ 模板 data+168 容器 | 师×模板类别合并计数 (cavalry/armor/rocket/artillery/motorized/mechanized/infantry/special_forces) | EQUIPMENT_ARMOR 等 7 + cavalry | 定案 (读法) / +904 书中未名 |
| 损耗 tooltip | sub_140C75500 | CArmy (方法内) | attrition 计算 | ATTRITION_DESC | 定案 (单链) |
| 师名/等级/经验 tooltip | sub_140C86CC0 / sub_140C7E930 | CArmy (方法内) | 师名; unit_level·experience 两窗共用 | LEVEL_NAME / VISUAL_LEVEL | 定案 (单链) |
| 历史页行重建 | sub_1416BEE50 | CArmy+1592 块 / +1644 行数 / +1624 CUnitMedalStore (键@+1064) | 补行 (0x5B0 条) + 按键分组 0x50 行 | — | 定案 |
| history_kill_count | sub_1416BEE50 | **CArmy+1656 killed** | 击杀数 | HISTORY_KILL_COUNT_TEXT | 定案 |
| history_experience_count / 军官经验增益 | sub_1416BEE50 / 0X1416AD770 链 | **CArmy+824 成员→vt[1]→+136** (+32 = Update 变更侦测); **军官经验增益窗槽 = view+8024** (BuildTooltip 0X1416A2270 分支 `a2==*(a1+8024)` → resolve → 载体 vt[1]; tooltip helper sub_1413E9CE0; 参数源 qword_143337930 PER_MEDAL/MULT) | 任职军官经验 (载体经虚 getter) | HISTORY_EXPERIENCE_COUNT_TEXT / ARMY_FIELD_OFFICER_EXPERIENCE_GAIN_TOOLTIP | 定案 |
| combat width 窗群 | BuildTooltip 0X1416A2270 | **view+8192 / view+8200 双窗槽** (`a2==*(a1+8192) ‖ a2==*(a1+8200)` → CArmy vt+368 = vt[46] 0X140C7D9B0) | 战斗宽度双出参 | COMBAT_WIDTH_DESC / DESIGNER_COMBATWIDTH_TOOLTIP | 定案 |
| 历史页行管理器/行列表/宿主窗槽 | sub_1416BEE50 (行 99..395) | **view+8272 行宿主窗** (vt+120 find "history_kill_count"/"history_experience_count") / **view+8280 行列表管理器** (vt[11] (+88) 上限 / vt[5] (+40) 加行 / vt[29] (+232) 与 vt[33] (+264) 刷新对) / **view+8296 历史行列表** (0x50 行对象 ctor sub_141D102A0) | 页模式 view+8376 ==2 历史页; 行访问器 sub_1414468A0; 行条目 0x5B0 (1456B, ctor sub_141D0FD00; 行对象参数 = 工厂 `*(a1+128)+1272`) | — | 定案 |
| Update 脏检 | @64[1] 0X1416B88A0 | view+1672 缓存 vs (+824obj)->vt[1]+32 | 变化 → sub_1416BDF50 局部刷新 | — | 定案 |
| 页切换 | @64[2] 末段 | view+8376 = 0/1/2 | 编制/统计/历史 三页 | — | 定案 (机制) |
| Badge 目标 (军/集团军) | 工厂 sub_141BCB490 → badge+504 idpair; **写点 = sub_1416B5D40(badge, idx, obj, flag)** (populate sub_1416BC7E0 逐条调用; 写值 = 入参对象 +8 的 refid 快照; ctor 初值 qword_14333D528 哨兵; 断言 ref.h:83) | resolve → COrdersGroup / CArmyGroup (+57 旗判) | 侧栏军级条目; SetTarget 无虚槽 (populates 写入) | — | 定案 |
| Badge 改名 | 文本观察器 sub_1416ACB50 | target+8 idpair → CSetOrderGroupNameCommand (0x50B) | 命令投递 sub_142250B00 (§4.00.6) | — | 定案 |
| Badge 名字聚合 tooltip | 0X14169D860 | CArmyGroup+560/{+572} 逐元+80; 单名 +80 | 集团军→含军名清单; 军→单名 | UNASSIGN_ARMY(_GROUP) | 定案 |
| Badge 将领技能 | 0X14169D860 → sub_140333D10 | 军团→将领; sub_140C15500 攻击技能 | 空 → 无将领文案 | LEADER_SKILL_DESC / UNIT_LEADER_NO_LEADER | 定案 (链) |
| Badge 组织/兵力条 | COrgStrIndicator (+392 内嵌) | (指示器内部未逐行; 属 §4.18 域) | org/str 显示控件 | — | 形态定案 |
| ListView 管辖师集合 | CTemplateChanger[1] 0X14169B400 | view+272 {count@+284} idpair 数组 → CArmy\* (res−16) | 批量师导出 (设计器「选中师改模板」数据源同族) | — | 定案 |
| ListView 部署/撤退 tooltip | BuildTooltip 0X14169F350 | view+260 idpair → 军团 → sub_140333D10 将领; leader+409/+410/+411, vt[26] 天数, +64 名 | 部署在途/受阻/撤退三态; 军团+432 边境战争禁解散 | LEADER_DEPLOY_* / LEADER_COMING/LEADER_WITHDRAWING / HQ_WITHDRAW_REFUND_* / CAN_NOT_UNASSIGN_BORDER_WAR | 定案 (链) / leader 侧偏移书中未名 |
| ListView 部署/撤退列表窗 | BuildTooltip | view+10656 / view+12024 窗柄 | 两列表悬停分派 | DEPLOY_BUTTON_* / SWITCH_STRATEGIC_REDEPLOYMENT_MODE* | 定案 (机制) |
| 撤编全选注记 | BuildTooltip | view+304/+305 旗 bytes | HQ 撤编注记开关 | DISBAND_ALL_UNIT(_NOTE) | 高置信 |
| 设计器名字组行项点击 | sub_1414A38A0 → sub_141763E10 | **行项 +1328 (CDivisionDesignerView\*) / +1336 载荷 / +1344 旗** → ES(+11096) 名字组落账 + designer+17705 脏旗 | **CArmy+1328 簇属主裁定 = CDesignerEquipmentCategoryItem**, 非 CArmy | designer_div_name_group_entry | 定案 |

#### 4.30.6 空军视图三件套 (ReorganizationWindow / DetailsPopUp / WingsByBaseView)

**入口链**: **第六种基链变奏 = CPopUpWindow 14 槽基表同族同序**
(两弹窗); target: ReorganizationWindow = **CAirBase** (非虚 SetTarget sub_14202DCD0 存 idpair
@+4128), DetailsPopUp = **CAirWing** (工厂 idpair 快照@+5472, 析构安全 — §4.30.5 同款),
WingsByBaseView = **无目标指针**纯列表 (载荷 +112 CAirWingsSelectionList RTTI 实名)。
**横断发现**: §4.15 空军族书表偏移 = res 坐标 (raw+16), 运行时方法 this = raw — popup 六
getter (raw+472/2456/128/744/2500/2600) 对书表 +456/+2440/+112/+728/+2484/+2584 双向全中,
即「运行时 this = 书表基址−16」(§4.15 头注)。命令族: **CDeployAirWingCommand
(id 13091)** / **CSetAirWingNameCommand (id 14312)** — CCommand 层再添两员 (§4.00.6)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| Reorg 窗目标 (新基地) | SetTarget sub_14202DCD0 (非虚, 工厂直调) | **CAirBase+8 idpair → win+4128**; 消费 res 基 | target = 基地 idpair (工厂传 res); 行控制器 +5264 进 | AIRWING_NEW_BASE / BASE / action_name | 定案 |
| Reorg 可部署装备池 | sub_14100CFC0 | **CAirBase+136 allow_equipment_type** × CCountry+3944(+512) 库存 → win+4024 池 | 基地允许机型过滤国家库存 | — | 定案 |
| Reorg 左面板机型列表 | sub_142061E90 (panel_controller.cpp 断言) | win+4024 池条目; def+1008/+1032/+1240; 行原型+4336 类别过滤 | 按装备定义建行; −1=全部类别 | plane_filters / plane_type_grid | 定案 |
| Reorg confirm 按钮 | glue+1448 → sub_14202C760 | win+4088/{count@4100} 80B 行; **CAirBase+48 目标**; CCountry+808 人力门 | 每行投 CDeployAirWingCommand (13091) | confirm_btn | 定案 |
| Reorg 行人力合计 | sub_140C4CBC0 | 行+32 {16B variant\*,amount} × sub_140BDA170 × define 18 | Σ = 人力需求 (SERVICE_MANPOWER) | SERVICE_MANPOWER_HEADER | 定案 (链) |
| Reorg 增援偏好下拉 | OnOpen glue (lambda RTTI 实名 W4EAirReinforcem…) | win+4212 双 byte / "reinforcement_preferences_position" | 增援偏好 UI | reinforcement_preferences | 高置信 (形态) |
| Reorg Update 激活门 | @64…[1] 0X14202ED10 | win+4112/+4120 idpair + +4024 池 + +4100 行数; dword_14338CF68 | 有目标/池/行任一即活 | — | 定案 (机制) |
| Reorg 关闭 | [8] 0X14202D690 / OnClose [12] / Reload @16[2] | win+4224/+4232/+4240 | 基 Close+控制器收尾; Reload=重建+关窗 | — | 定案 |
| Stats 弹窗目标 (联队) | 工厂 sub_141FD2240 (无虚 SetTarget) | **CAirWing+8 idpair (raw+24) → win+5472 快照** | 联队析构安全; 行控制器 +9744 进 | — | 定案 |
| 联队名 (含改名) | SetupDerived / sub_140F60A70 | **CAirWing+2440 name** | "air_wing_name" 文本源; 变更 → CSetAirWingNameCommand (14312) | air_wing_name | 定案 |
| 联队人力 | sub_140F622A0 | **CAirWing+112 manpower** | 数字窗 | current_manpower / MANPOWER_AIRWING | 定案 |
| 装备构成列表 | SetupDerived res+488/+500 直读 | **CAirWing+456 池 {entries@+488, count@+500}** | 0x560 行对象 × {variant\*, amount/1e5 机数}; +5528 列表/+5564 回收 | — | 定案 |
| Ace 名/头像 | sub_140F5AAB0 | **CAirWing+728 ace idpair** → CAce; 名 sub_14061A5D0 | 无 ace → 隐藏+禁用 | — | 定案 |
| combat_stats 值源 (state 门) | SetupDerived (基地无 state 门) | **CAirWing+40 _pPool → resolve(air_base)+104 = CState\* state** (CAirBase+104; 池+104 字段不存在 — 池 sizeof 0x48, ctor/writer/loader/postload 四路不触) | 属主 defines 修参仅基地无 state 时吃 | combat_stats | 定案 |
| combat_stats 属主 defines | SetupDerived 尾段 | +2484 tag → country+1464 defines {201,202,203} | 201=navy_carrier_air_attack_factor / 202=targetting / 203=agility | combat_stats | 定案 |
| 联队角色图标 | sub_140F5F670 | **CAirWing+2584 role_icon_index** | → +5576 对象 | — | 定案 |
| 联队删除 | glue+2728 → sub_142036A10 | win+5472; sub_140F5F630 名 | 确认弹窗 0x1078 | AIR_DELETE_WING / AIR_DELETE_WING_DESC | 定案 |
| 应用并关闭 | glue+4016 → sub_1420369F0 | — | 改名提交 + vt[8] 关窗 | — | 定案 |
| value 悬停 tooltip | BuildTooltip 0X142036600 | 悬停 a2[2] id → sub_1413E5BD0 | 统计行值 tooltip | value | 定案 (链) |
| ByBase 条目 (未分配联队) | ctor sub_141CEC9E0 | **+112 CAirWingsSelectionList**; **+336 = air_group 对空过滤器 (0=收未分配翼 / 1=收所选组翼)**; +104 bottom_window | 纯数据行, 零虚覆写 | unassigned_airwings_view / bottom_window | 定案 |
| ByBase populate/resize | sub_141CECC20 | sub_141F5E740(list, …, **+336**, …); sub_141F5E200 条目数 | 旗透传 + 按条目数 sizing | — | 定案 (机制) |
| 坐标校准 (全族) | — | **§4.15 书偏移 = res = raw+16**; 运行时 this = raw | popup 六 getter + res+488 直读双向命中 | — | **定案** |

余量定案 (§4.15 池表行):

| 项 | 结论 | 证据 |
|---|---|---|
| CAirBase 池+104 字段 | 不存在 (池 sizeof 0x48; ctor/writer/loader/postload 四路不触); combat_stats 真读链 = `resolve(_pPool→air_base)+104` = CAirBase+104 CState\* state | 二进制文件 |
| combat_stats 门语义 | 基地无 state (海上/载具) → 吃属主国 {201=navy_carrier_air_attack_factor / 202=targetting / 203=agility} | 活体 mdef 定名 |
| reorg win+4112/+4120/+4192/+4200 | 死字段 (哨兵复位无活值) | — |
| CPanelController | 布局全清 | — |
| 行控制器实名 | CAirBaseSelectionItem / CAirWingSelectionItem | RTTI |
| CAirWing 双虚表槽表 | 见 §4.15 补记 | — |
| CAcesView | = reorg+4224 | — |
| 书 +2492 | reinforcement_setting (confirm 门比对) | — |

#### 4.30.7 海军视图簇 (ShipStatsView / CompactShipListView / NavalCombatView)

**入口链**: ShipStatsView target = **CShip** (idpair
@view+6632, ctor 快照); CompactShipListView target = **CTaskForce 数组** (RTTI 实名 filler
`UpdateCompactShipList(CShipCategorizer const&, CTaskForce const* const(&)[N], filler)`);
NavalCombatView target = **CNavalCombat** (idpair@view+64, Reload 经 res−16+24 归一化)。
**坐标校准定案**: §4.22.5a 海战书表 = res 坐标, 无 ±16 (sub_1413E2B80 双谓词
铁证); **−16 胶水规律定案**: `*(X−16+24) = *(X+8) = X 的 refid` (CTaskForce writer 基互证)。
命令族: **CDeleteShipCommand{+40 舰, +48 特混舰队}** / **CDisengageFromNavalCombatCommand
{+40 combat refid tok 0x2916, +48 is_attacker tok 0x28F5}** — §4.00.6 再添两员。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| ShipStats 目标 (舰) | 工厂 glue sub_141AC9DB0 (ctor a3 直拷) | **CShip+8 refid → view+6632**; +56 解析缓存 | 宿主+5320 idpair 进; 析构安全快照 | ship_stats_window | 定案 |
| ShipStats 统计/历史页签 | glue+88/+1376 cb | win+5312 vt+104/+176 | 双页签互切 | tab_stats / tab_history | 定案 (形态) |
| ShipStats 装备定义行 | glue+2664 sub_141BEF820 | **CShip+64 池 → 池+1008 def** | 装备定义可见门 | — | 定案 |
| ShipStats 资源门列表 | glue+3952 sub_141BECFC0 | **CShip+1832→tf+472** → CCountry+224 ≥ 1e5×define | 属主资源达标列表 | — | 高置信 |
| ShipStats 舰名/删除确认 | glue+7928 sub_141BECA70 | **CShip+2072(+96)**; +1832 宿主 | 确认弹窗 0x1078; 投 CDeleteShipCommand | CONFIRMDELETESHIP / CONFIRMDELETETEXT / DISBAND_PRIDE_OF_THE_FLEET_COST | 定案 |
| ShipStats pride 图标切换 | 逐帧 0X141BED5F0 | **CCountry+592/+596 vs 舰+8/+12**; CShip+1576 旗 | 舰=舰队 pride 时 type_icon 切换 | type_icon | 定案 |
| ShipStats 军官钮刷新 | Update 0X141BEFB60 | **CShip+24 IOfficerHolder** vt[1]→+32 | 军官变更检测 (缓存 win+10600) | — | 高置信 |
| ShipStats 舰图标串 | sub_140C3A0F0 | **CShip+232 舰体名** + def+968 | GFX_unit_\<hull\>_\<n\>_icon_medium | GFX_navalcombat_ship_icon_unknown (兜底) | 高置信 |
| ShipStats 流亡/可见谓词 | sub_140C33A50 | **CShip+1576 旗 qword; +2052 exile tag; +64 池旗** | define 15 门 | — | 定案 (读法) |
| CompactList 条目灌入 | UpdateCompactShipList (RTTI 实名) | **CTaskForce 数组** → view+56 数组 | 特混舰队编成紧凑列表 | entry | 定案 (形态) |
| CompactList 条目 tooltip | 0X141E11E40 | **entry+1336 DB 索引; +1340 需求数** | 舰型名 + 需求舰数 | COMPACT_SHIP_VIEW_DESC_REQ / TYPE | 定案 |
| CompactList 条目图标 | entry 窗 | entry+8/+16 idpair; "pride"/"required_ships_count" 窗 | pride 图标 + 需求计数 | pride / required_ships_count | 定案 (窗名) |
| NavalCombat 目标 (海战) | Reload 0X1417EA930 再归一化 | **CNavalCombat+8 refid → view+64** | 外部 idpair 规范为海战自身 refid | navalcombatview | 定案 |
| NavalCombat 双侧网格 | sub_1417ED140 | **cb+232/{+244} group 容器** → CCombatBoxGrids+24 8 槽 + CFEXShipIcon | 攻/守组×舰图标网格 | CCombatBoxGrids | 定案 |
| NavalCombat 将领面板 | sub_1417F0320 | **cb+304 current_leader** (无将 → GFX_leader_unknown) | 名/头像/技能(fixed5)/等级 | UNIT_LEADER_NO_LEADER | 定案 |
| NavalCombat 参战国旗 | sub_1417EDD40 | **cb+56 参战 tag 链A** → view+2656/+2664 | 两侧参战国 | — | 定案 |
| NavalCombat 侧统计 | sub_14161E9A0 | 镜像 cb → view+2672/+2680 vt+776 | 侧统计窗 | — | 定案 (链) |
| NavalCombat 进度条 | 刷新尾段 | combat vt[25] → view+2704 | 战斗进度 | COMBAT_PROGRESS_DESC | 定案 (挂接) |
| NavalCombat 脱离战斗 | glue+1360 → sub_1417E4330 | **CDisengageFromNavalCombatCommand {+40 海战 refid, +48 is_attacker@+216}** | 玩家侧选取 sub_1417E7B30 (gs+1312/1316 + cb+56) | — | 定案 |
| NavalCombat 中央 tooltip | BuildTooltip 0X1417E88A0 | 进度/天气/夜战/载具堆叠/将领特性 | 悬停统计 | COMBAT_PROGRESS_DESC / WEATHER_MODIFIERS / NIGHT_MODIFIERS / CARRIER_STACK_PENALTY_DESC / LEARNING_TRAITS | 定案 (loc key) |
| 坐标校准 (海战族) | — | **§4.22.5a 书偏移 = res 坐标**; −16 胶水 = 「(X−16)+24 = X+8 refid」 | 侧/镜像/group/leader 全 res 直读命中 | — | **定案** |

**坐标关系** (§4.16 已载): writer 0X140D7AFA0 a1 = 元素+16, 运行时特混舰队对象 =
writer this+16; sub_1402A6F30 读 tf+24 = writer+8 顶层 refid (独立再证)。
**未决**: CompactList 条目 lambda 内联细节; pride 双窗语义。

#### 4.30.8 阵营视图簇 (FactionView / NewFactionWindow / CommanderWindow)

**入口链**: FactionView = 「CCountry 直读」变奏 (无存储 target,
查看国 gs+1312/1316 → cc+3976+656 → CFaction 每次现取); NewFactionWindow = **第 7 种基链
CReloadableWindow 9 槽**, target = 选中 CFactionTemplate\*@win+2920; CommanderWindow =
**CUnitLeaderWindow 首次入册 13 槽**, 无阵营指针 (玩家国现取 + **cc+4080 roster 两张
CUnitLeader\* 候选表 @+112/+136**)。**方法学新路径**: 本族虚表常量在 dump 里以
`&类名::vftable'` 符号出现 (grep 地址必落空) — ctor 定位 = grep 符号 → 符号回映射行号;
**MI 漂移第二形态**: @48 子对象虚表方法 this = win+48 (Update 读 +20192 = win+20240 双向全中)。
命令族: **CCreateFactionCommand (id 12242: +40 tag / +48 名 / +80 icon 串 / +128 CColor 色 / +184 初始成员)** /
**CClearFactionTheater (19760)** / **CFactionSetCommanderCommand (10509: +40 序槽 / +44 leader
idpair / +52 applier)**。CFactionMemberStatus+56/+80 添 UI 消费点定案 (§4.5)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| FactionView 目标 (查看国) | 无 SetTarget ([9]/[11] 不覆写); 刷新时现取 | tag gs+1312/1316 → sub_140BB48F0 → **cc+3976+656 → CFaction\*** | 「CCountry 直读」变奏 (§4.30.3 同款); 零阵营即空态 | countryfactionview | 定案 |
| FactionView 全量构建 | [14] populate sub_141472080 (**DLC50 门**) | 惰性建 §2 全表 | Deeper Factions DLC 门 (与 add_faction_goal 同门) | — | 定案 |
| 阵营名行 | sub_140D8BB80 | **CFaction+24/+56 name** | GetName (§4.5) | — | 定案 |
| manifest 门/名 | sub_140A21BE0 | **goal_status+16 manifest def** (+2664/+2872 门 书中未名) | manifest 显示 | MANIFEST / FOREIGN_MANIFEST_ENTRY | 定案 (读法) |
| 目标 (goals) 列表 | sub_140A27930 | **goal_status+24 {count@+36} 1344B 条目 def@+0** | 目标列表 (§4.5 ✓) | FOREIGN_GOAL_ITEM_ENTRY | 定案 |
| 成员国列表 (色+值) | sub_141474550 | **CFaction+88/{+100}**; **facsys 条目 sub_140BB4AC0(tag)+56/+80**; **cc+848(+880) 色** | 逐成员行: 色/百分值/计数; 首元 = 领袖旗 | faction_countries_window | 定案 (读法) / +56/+80 语义推定 |
| 规则/目标/邀请/人力弹窗 | +1408/+1416/+1432/+1440 四窗 | CChangeRuleWindow / CChangeGoalWindow / CInviteCountriesWindow / "request_faction_manpower" | 交互弹窗群 (change_rule_window 等) | change_rule_window | 定案 (形态) |
| 弹窗池 12 种 | sub_141BFE5B0(popup, mode) | +20240 vector\<unique_ptr\<CFactionPopup\>\> (内联容 13) | 解散/退出/夺权/目标/规则/剧院/学说/踢除/邀请 确认窗 | CDismantleFaction… 全族 RTTI | 定案 |
| 指挥官窗嵌入 | sub_141BF84C0 (populate 惰性建) | **+20216 CFactionCommanderWindow (0x11A8)** | 阵营页内嵌指挥官管理 | — | 定案 |
| 设施/科学家子对象 | sub_141468980 / 0X141C1F110 | +20200 CProjectListFilterWindow\<CResearchFacilityItem\> / +20208 CFactionScientistRoster | NProject 联动 (RTTI 实名) | — | 定案 (形态) |
| New 阵营窗模板网格 | [6] sub_1418282B0 | **CFactionTemplateDatabase qword_14332EF10 {data@+80, count@+92}**; 谓词 sub_140D91D80/sub_140A2F810 | 模板列表 × unavailable_checkbox 过滤 | new_faction_window / faction_template_grid | 定案 |
| 模板选中 | 行 lambda sub_141828720 → sub_141825CF0 | **win+2920 = CFactionTemplate\*** (item+32 进, item+1432 回指) | 可切 0; 门 = allow 谓词 | new_faction_template_item | 定案 |
| 模板 allow 门 | sub_140D91D70 → sub_140A2F810 | **CFactionTemplate+140 门 / +120 子对象 vt[3] (国 scope), vt[12] 名生成** | 模板×国家允许 + 阵营命名 | create_faction_button | 定案 (链) / def 字段推定 |
| 创建阵营提交 | create_faction_button lambda sub_1415280 → sub_141584EC0 | **view21+8248 = template** (SetTemplate sub_141825EA0); 开 view#21; 关 view12+31696 | 二段式: 选模板 → 终窗 (名/色) | create_faction_button | 定案 |
| view#21 终窗身份 | — | **NFactions::NUi::CFactionSetupWindow** (faction_setup_window, 0x21F0) | 创建阵营终窗 (名/色/picker) | faction_setup_window | 定案 |
| 终窗提交 (实际建阵营) | CCreateFactionCommand (12242) Execute sub_141155F90 | **+40 tag / +48 名 / +80 icon 串 / +128 CColor / +184{196} 初始成员表** → sub_140D91E00 → **fac+2512 阵营色** | 命令层创建 (非 effect) | — | 定案 |
| 指挥官候选列表 | Repopulate sub_141BFA2A0 (**@48 this 漂移**) | **cc+4080 roster: +112/+136 两表 {data,count+12}, 元 = CUnitLeader\***; 谓词 sub_140C1D8B0/C0E100 (掩码 15) | 可任命领袖 × EFilterFactionCommanders 掩码 (win+4504) | factioncommanderwindow | 定案 |
| 指挥官行排序 | sub_141BF8DF0 (断言 faction_commander_window.cpp:0x1AE) | 基+3024 模式; **leader+64 名** / sub_140C199F0 技能 / sub_1411844D0·F750 | 名/技能/攻防排序 (army leader 同族) | — | 定案 (断言) |
| 点击指挥官 | [10] sub_141BF92E0 | leader → sub_1411867E0(leader, win+3152, 0); view#20→#9 开窗 | 开该将领详情窗 | — | 定案 (链) |
| 指挥官任命 | sub_141C03320 → 双命令投递 | **CClearFactionTheater (19760)** + **CFactionSetCommanderCommand (10509) {+40 序槽, +44 leader idpair, +52 applier}** | 先清旧剧院再任命 | — | 定案 |
| 阵营页联动 | glue cb sub_141BF93E0 / sub_1417A0E10 | **槽215 管理器+528 ← win+3152 选中序号** | 视图↔管理器选中同步 | — | 高置信 |
| 坐标校准 (@48 族) | — | **@48 子表方法 this = win+48**; 主表 this = win | Update 读 +20192 = win+20240 双向全中 | — | **定案** |

余量定案:

| 项 | 结论 | 证据 |
|---|---|---|
| cc+4080 宿主类 | **CCountryCharacters** (vt 0X14298AE18; sizeof 0x138 全布局见 §4.3); 两张 CUnitLeader\* 候选表 +112/+136 实测 GER 27/12 人 | 活体探针 + ASLR 换算 + RTTI 名三证 |
| view#21 三子窗 | +8312 CInviteCountriesWindow / +8320 CFactionIconWindow / +8328 CFactionColorPickerWindow | RTTI 实名 |
| 阵营色链 | 初始色 = CFactionTemplate rgba@+384 (旗@+400) ∥ 玩家国 cc+880 → picker+2992 CColor → CCreateFactionCommand+128 → fac+2512 | 二进制文件 |
| CCreateFactionCommand+80 | icon 串 (非色; 色在 +128 CColor) | 断言+二进制文件 |
| CLegacy 窗 | 无 DLC50 时的备胎窗 | — |
| influence 显示 | 占比 = 值 ÷ fac+2080; 排名 = token 19617 faction_influence_rank | 注册串铁证 |
| 人力弹窗类 | **CRequestManpowerWindow** (0xB78; fac+2288 池合计 → CUseFactionMemberManpower {+40/+44}) | RTTI |
| 取色 getter sub_1406ECF80 | 既有 CCountryColors#1 沿宗主链取色, 非新字段 | — |

#### 4.30.9 外交视图簇 (DiplomacyView / ActionItem 族 / CountryList)

**入口链**: DiplomacyView target = **目标国 tag dword
@win+17664** (「tag 存储」新变奏, 非指针; SetTarget [11] 入参 = CProvince\* 取 +392
controller; [12] = tag 直写变体); @48 this 漂移第 3 例。ActionItem 族 target = **action entry
对象 @item+1328** (双侧 tag **+20 actor / +24 original_actor / +28 recipient / +32 original_recipient** (reader 键 0x292E/0x2FCF/0x292F/0x2FD0, 基类全量布局 §4.10.13, 定案), assert diplomaticaction.cpp:0x62D;
entry 源 sub_141123990 ~50 typed getter, 内嵌 CGameDate 时效, 首族 CScriptedDiplomaticAction
def@+120)。**两个 §4.10 级收口**: opinion 唯一 UI 出口 = sub_1406F4490 (dip+8 → rs+768
cached_sum); dip+56/+80 瞬时暂存定案 = 外交 UI 不消费 (§4.10)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| DiplomacyView 目标 (目标国) | SetTarget [11] 0X1415EC140 / [12] 0X1415EC070 | **CProvince+392 controller → win+17664 (dword tag)**; manager+192 同步 | 「tag 存储」变奏 (非指针); 自国 = manager vt[20] 现取 — 双边形态 | countrydiplomacyview | 定案 |
| 目标播发 | Repopulate @48[9] 0X1415F08E0 (**@48 this 漂移**) | **infoCtrl+5304 / actionCtrl+2552 / actionCtrl+2600 ← win+17664** | 单点写入四处消费 | — | 定案 |
| 目标国 header (旗/名/阵营) | sub_1415F11F0 | **dip+656 CFaction\*** → sub_140D8BB80; 国名 sub_140BB4BB0(&tag) | `diplo_country_flag` / `country_name` / `faction_name` | DIPLOMACY_NO_FACTION | 定案 |
| opinion 双向 (our/their) | sub_1415F49A0 + sub_1406F4490 | **dip+8 active_relations[idx] → rs+768 cached_sum**; 旗 = sub_140B44AC0(mgr, obj, &tag) | `our_opinion_value` / `their_opinion_value` (零关系 → "—") | DIPLOMACY_OPINION_VALUE | 定案 (书表命中) |
| 执政党块 | sub_1415F5960 | **ps+208 ruling_party → sub_1411A3300 leader**; 名 sub_140FCB280; 像 sub_140B47270 | `leader_name` / `leader_portrait`; 无 → GFX_leader_unknown | ERROR: Missing leader | 定案 |
| 政党饼图 | 同上 (C2dPieChartTemplate) | **ps+32/{+44}; party+136 popularity; 色 sub_1411A4780(party)+16** | political_pie_chart 顶点 | — | 定案 (书表命中) |
| 意识形态图标/名 | sub_140B48C70 / sub_140B467E0 / sub_140623700 | **party+24 CIdeologyGroup\*** (+8 组 id) | `ideology_ico` / `ideology_name` / `party_name` (sub_1411A45C0) | — | 定案 |
| 稳定度/战争支持度 | sub_1406F8750 / sub_1406F9E70 | cc 直读 (getter 内部) | `stability_value` / `war_support_value` | — | 定案 (单链) |
| 选举行 | sub_1415F5960 尾 | **ps+236 && ps+232>0 门; ps+176 next_election** | `elections` 显隐 + 日期 | POLITICS_NEXT_ELECTION / POLITICS_NOELECTIONS | 定案 (书表命中) |
| 国策进度块 | sub_1415F3B80 | **fs+16 def / fs+56 progress (i64 fixed)**; 门 sub_141433D90 (情报) | `active_national_focus_info`: label + goal_ico(_shine) + progressbar = 1e7×progress/total | NO_NATIONAL_FOCUS / UNKNOWN_INFO | 高置信 |
| info tab 切换 | sub_1415EF610 | **infoCtrl+5400 模式 (0/1/2)**; **DLC28 门** sub_1401AEB50(28) | tab2 = intel_ledger (+5352 ledger, +5344 窗) | INTEL_LEDGER / DIPLOMACY_INFO_TAB | 定案 |
| 国列表 (countries_grid) | sub_1415F0460 (listCtrl) | 行池 +3864{+3876}; 门 **cc+1156 / capital cc+4120 / cc+5210**; 过滤 +3888/+3912/+3936 三表 + byte+3960 | 候选行四门三滤 → 排序 (sub_1415E59D0) 入格 | countries_grid | 定案 (书表命中) |
| 国列表行 | sub_141C82C50 | **行+1328 tag / +1344/+1348 双向 opinion** | `diplolist_country_flag` / `name` (sub_140BB4BB0) | diplomacy_country_list_country_entry | 定案 |
| 行点击 → SetTarget | [12] tag 直写 | 行+1328 → win+17664 | 列表选国与点省同链 | — | 高置信 (链) |
| 动作面板 (22 动作) | actionCtrl ctor sub_1415E2950 | **+2576 池 {win+17528/+17540}; 每动作 = `standard_<token名>` 窗** | 通用 14 token + 8 特化控制器 (§4.10.13 动作 token 全表; 19 控制器 ↔ 动作键 ↔ Action 类对照全量 = §4.10.22) | standard_diplomacy_controller | 定案 |
| 动作可用性门/背景 | CDiplomacyStandardController +32/+40 | token dword / GFX 背景 SSO | 例: GFX_diplo_action_offer_peace_bg (12474) | standard_* | 定案 (读法) |
| 动作提交/取消 | vt[14] 订阅 | **`send_button` / `cancel_button`** → 各控制器 | tooltip handler = 控制器自身 (vt[2] 绑 vt[69]) | send_button | 定案 |
| 宣战 wargoals 网格 | [7] 0X141C99DA0 | **我方 dip+104/{+116} ∧ wg+60==对方 tag ∧ 对方 dip+368/{+380} 含**; 行 = CDiplomacyWarGoalItem (0x548, wg+8 idpair) | wargoals_grid; 双侧 tag = 选中 item+1328{+20/+28} | wargoals / wargoals_grid | 定案 (书表命中) |
| 外交行动收件箱 (action entry 群) | sub_141123990 收集器 (~50 getter) | **entry+20 actor / +24 original_actor / +28 recipient / +32 original_recipient (定案); 设值器 sub_14113F980 写 +20 / 读 +28** | `diplomacy_action_entry` 行 (CDiplomacyActionItem 0x590, item+1328 = entry) | diplomacy_action_entry | 定案 (断言) |
| entry 时效 | 同上 | 内嵌 CGameDate 时效 | 重建 = sub_1415EC620 | diplomacy_action_entry | 定案 |
| 行选中 → 动作面板 | win+17592 = item | item+1328 块 → 各控制器 | 点击行开 `diplomacy_action_info_window` (+17656/+17672); 写点见下表 | diplomacy_action_info_window | 定案 |
| 战争一览 | sub_1418AC180 | sub_140D3C3E0(dip, temp) 48B 条 → 窗+23576 | war overview 取第 index 战争 | — | 高置信 |
| 视图刷新机制 | @48[5] 惰性 + @48[9] Repopulate; 无 Update 覆写 | +17544 门 + tag 门 | 打开/换目标即刷, 无逐帧 | — | 定案 |
| 坐标校准 (@48 族) | — | **@48 方法 this = win+48** (a1+17616 = win+17664) | 第 3 例 (前例见 §4.30.8) | — | **定案** |

余量定案:

| 项 | 结论 | 证据 |
|---|---|---|
| entry 双侧 tag 槽序 | +20/+24 = _Actor 双槽 (同 *a2 双写); +28/+32 = _Recipient 双槽 (同 *a3 双写); 槽序以 assert 为准, 非文案序 | 设值器 sub_14113F980 写 +20/读 +28, assert diplomaticaction.cpp:0x62D, 五证+亲验回归 |
| win+17592 写点 | sub_1415ECB10(actionCtrl, item) `*(a1+2640)=a2` (清/选同函数); 链 A = CLegacyButtonObserverGlue\<CDiplomacyActionItem\>@item+32 thunk sub_141C80E60 → sub_1415ECAE0; 链 B = sub_1415ECA00(infoCtrl, token 19141/10540/10541/10544) 程序选行 | 二进制文件 |
| CState+48 | 州库定义条目 (qword_14332F070), 非 CGameState\*; 过滤真链 = `*(*(state+48)+320)+44` | 二进制文件 |
| P+44 / P+48 | P+44 = 大陆 id (loc: DYPLOMACY_FILTER_CONTINENTS/IDEOLOGIES/FACTIONS 三滤); P+48 = 稠密战略区号 | loc 铁证 |
| leader+320 | CCountryLeader+320 = CIdeology\* (§4.4) | 复核闭合 |
| party+112 / party+124 | party+112 = 领袖引用槽; party+124 = 有效门 (新锚) | — |

#### 4.30.10 和会视图 (PeaceConferenceWindow / BiddingsItem 族)

**入口链**: target = **CPeaceConference idpair
(type@win+20744, id@+20748)** (gs+1248 管理器 active_peace 元素; 每轮 sub_14221F310 解引 + conf+8
refid 回写自愈); 第 8 骨架 CReloadableInterface@0 + CTooltipHandler@40, true entry =
[2] Reload 0X141862010 (断言 _Conference.IsValid)。**writer 0X140E527D0 全解码 → §4.23
匿名区一次命名** (详见 §4.10.26 注); liberated(+296)/subject(+320) 页签出叶
(定案), history(+504) 无, redistributions/score_from_countries 不在 writer。校准: 本族零漂移。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 和会主窗 target (idpair type) | Reload [2] 0X141862010 (无 SetTarget 虚槽) | **win+20744** ← gs+1248 管理器 active_peace 元素 (§4.10.26 ✓) | idpair 存储变奏 (§4.30.9 tag 存储同族); 联合门: 与 +20748 成对读写, sub_14221F310 解引 | peaceconference_full_window | 定案 |
| 和会主窗 target (idpair id) | 同上 (Reload [2] 0X141862010) | **win+20748**; conf+8 = 自身 refid 回写自愈 | 同上 | peaceconference_full_window | 定案 |
| 输赢顶图 | w4 0X141867F10 | **win+20752** ← sub_14185DE40(conf+96/+120 map 查玩家) | 1=输 → GFX_top_art_losing_conference | peace_conference_top_art | 定案 |
| 阶段条 | w3 0X141866C60 | **conf+216** (+1 显示) | 当前竞标阶段 (§4.23 +216) | PEACE_BID_PHASE (bidphase_panel/bidphase_text) | 定案 |
| 需求状态行 | w3 | **conf+220 making_demands** 门; sub_140E47EB0 国 | 提需求中/等待 | PEACE_CURRENTLY_MAKING_DEMANDS / PEACE_WAITING_PLAYERS_MAKE_DEMANDS | 定案 |
| 截止数值行 | w3 | sub_140E401F0(conf) ×1000/1e5 + gs 日期 | 会议时限/累计值 | PEACE_THREAT_GENERATED_TOTAL (SUMMED/VALUE) | 高置信 (语义) |
| 当前分数 | w3 | **winners 条目+64** (sub_140E38720 查 tag) − sub_140E400F0(conf) 总分; 分差 sub_140E3F7D0 (+368 solo_winner 门) | 国别分 vs 玩家总分 | PEACE_CURRENT_SCORE (SCORE) | 定案 |
| 9 个行动图标 | w2 0X1418657D0 | sub_1418626E0/F720(conf, …, token) → **win+20880..+20944**; **DLC41 门** | take_states(12495)/liberate(12496)/puppet(12497)/force_government(12498) + take_navy(12526)/demilitarized_zone(12531)/war_reparation(12532)/resource_rights(12533)/dismantle_industry(12534) | *_action_icon | 定案 |
| 行动说明显隐 | w2 | 九图标 byte165&8 聚合 | 有可用行动才显 | bid_actions_description / stackable_bid_actions_description | 定案 |
| subject/liberated 页签 | w2 | **conf+308 + conf+332 计数和** → +20992 对象 vt[81]/vt[82] | liberated/subject 页签出叶 (计数门) | — | 定案 (读法) |
| demands 标签 | w5 0X1418647F0 | **conf+96/{+108} vs +120** per-player map 查玩家; **conf+532** = ACTION | make demands / defeated / thirdparty 三态 | PEACE_MAKE_DEMANDS_LABEL / PEACE_FILTER_DEMANDS_DESCRIPTION / PEACE_DEFEATED_ACTIONS_* / PEACE_THIRDPARTY_ACTIONS_* | 定案 |
| 可用行动列表 | w5 尾 | sub_14185CEC0(…, **conf+528** 选中 token, 默认 19479 undefined) | available_actions 窗 | available_actions | 定案 (读法) |
| 行动窗显隐 | w5 | **win+20758 byte** | actions_window 门 | peaceconference_actions_window | 定案 |
| taker tab (夺州页) | w6 0X141867A20 | **win+20760 模式**; 池 A/B 清理; win+20824 列表 | 夺州分页 (断言 Unknown taker tab) | current_and_history_actions | 定案 (机制) |
| 双 popup 更新 | w7 0X1418660E0 / w8 0X141867D00 | **popup+5248 = conf idpair** (sub_141E584E0 装); popup+56 目标; conf+96/{+108} 匹配 | winner/beneficiary 双侧竞标弹窗 (SetBiddingsIn\* 载体) | — | 定案 (装载) / popup 体未决 |
| 等待玩家 | w9 0X141868150 | conf+220 ‖ 空表 → 隐 | 等待玩家列表 | PEACE_WAITING_FOR_PLAYERS (PLAYERS) | 定案 |
| 国聚合竞标行 | ctor (合并块) + cb 0X141E50980 | 行+1312 expand; +1320 四叠加 token map; `nb_biddings`/`biddings_grid` | 点击展开 → 全窗重填 | conference_bidding_aggregated_country_header | 定案 (读法) |
| 可用行动聚合行 | ctor + cb 0X141E48870 → sub_14185F3D0 | **行+1316 tag/+1320 action → conf+524/+532**; conf+221 门 | 选国(+行动)过滤 | aggregated_action_header | 定案 (链) |
| 行动类别 (静态) | CPeaceActionCategoryEntry reader 0X140A85310 | **+24 icon (181) / +56 name (27) / default (11405)** | 静态库 peace_action_categories 行 (不落存档) | — | 定案 (reader) |
| 竞标回合记录 (国) | CPeaceBiddingTurn writer 0X1419F51E0 | +8 country | 每回合竞标国 | — | 定案 (writer) |
| 竞标回合记录 (行动) | CPeaceBiddingTurn writer 0X1419F51E0 | +16 actions | 回合行动列表 | — | 定案 (writer) |
| 竞标回合记录 (行动数) | CPeaceBiddingTurn writer 0X1419F51E0 | +28 actions count | 行动列表计数 | — | 定案 (writer) |
| 竞标回合记录 (州) | CPeaceBiddingTurn writer 0X1419F51E0 | +40 states | 回合州列表 | — | 定案 (writer) |
| 竞标回合记录 (州数) | CPeaceBiddingTurn writer 0X1419F51E0 | +52 states count | 州列表计数 | — | 定案 (writer) |
| 会议存档块 | writer 0X140E527D0 (槽[2]) | §3 全表 | 书 §4.10.26 匿名区全命名 | peace_conference 段 | 定案 |
| 坐标校准 (本族) | — | **UI 解引用 this = writer this = ctor this (零漂移); refid@+8** | conf+216/220/221 UI 读=writer 写 同位三证 | — | **定案** |


**尾域 +20656..+21000 全表**（1.19.3 重锚：全偏移零漂移、尺寸 21008B 不变；地址族漂移
= 本类 text 族 0x134E0 / item 族 0x14FA0 / 胶水桩族 0x510 / vt rdata 0x16D60）：

| 项 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 三行对象池 dtor 序 | dtor 实 sub_14185C670 | 逆序 **+20704 → +20680 → +20656** | 逐池 `sub_140BBF080(池)` 销元素 → `alloc vt[2] (+16)` 回收 data → data 清零 → dword@+8 清 0；三池共用 sub_140BBF080（ICF 折叠） | — | 定案 |
| 池形态（三池同） | — | data@0 / dword@+8 / count@+12 / alloc@+16（元素 8B 指针） | count 槽 = **+20668 / +20692 / +20716**（三处 8B 步长循环 `v2+8**(a1+count)` 直证：sub_14185F080 / w6 sub_141867A20 / sub_14185F7B0） | — | 定案 |
| 池 1 dword@+8 | dtor 清 0 / ctor 清 0 | **+20664** | **池容量 cap**（与 +20668 count / +20672 alloc 构成标准 CVector 三件套; dtor sub_14185C670 逆序销池时清 cap + alloc vt[2] 回收 data） | — | 定案 |
| 池 1 allocator@+16 | ctor 初值 = off_143085170；dtor 经 vt[2] 回收 | **+20672** | 池分配器槽 | — | 定案 |
| 池 2 三槽 | 同池 1 机制 | **+20688 / +20692 / +20696** | dword / count / alloc | — | 定案 |
| 池 3 三槽 | 同上 | **+20712 / +20716 / +20720** | +20716 另见 sub_14185F7B0 循环 | — | 定案 |
| 池 1 元素删除 | sub_14185F080 内 | **sub_141E4D510** | 销元素后再调行对象 vt[25] (+200) 关窗 | — | 定案 |
| 池 2 元素删除 | 同上 | **sub_141E4D4E0** | 同机制 | — | 定案 |
| 池 3 元素删除 | 同上 | **sub_141E479B0** | 同机制 | — | 定案 |
| +20728 owner/界面处理器 | ctor sub_14185AE60 存 a2；Reload 网络侧 | **+20728** | `*(a2+1272)` = 窗工厂 → `sub_14225C5A0(工厂, "peaceconference_full_window", 0)` 查根窗（vt[12] (+96) 内部形态未逐行）；Reload 网络通知链 = vt+136 → server+88 → `_RTDynamicCast(CNetworkServer/CProxyServer)` + server+84 门 → 通知全局 qword_14338A140（+80/+88 各 vt+96） | peaceconference_full_window | 定案 |
| +20736 completed 窗柄 | 主填充 sub_1418646F0 首分支（conf+221 门）→ **sub_140B653D0** | **+20736**；ctor a3 存入 | 体内 +576 子窗经 sub_14185F080 复位 / +1018 清 0；对象类名未名（CGuiObject 谱系） | — | 定案（机制） |
| idpair 哨兵 | ctor 尾块初值 | **+20744 / +20748** = qword_14333D528 | 1.19.3 通用 idpair 哨兵，全镜像复用 | — | 定案 |
| 双 popup 更新门 | w7 sub_1418660E0 / w8 sub_141867D00 | **+20756** 与 **+20757**（置位为 1） | 假分支 → 各自 popup vt[6] (+48) 调用 | — | 定案 |
| +20764 暂停暂存 | Reload → sub_1401FA5E0() +594 取旧置 → 存本槽置 1 | **+20764** | 全局对象身份未名（同形态沿用） | — | 高置信（语义） |
| +20768 根窗槽 | 可见性谓词 vt+584 / byte165 bit3；清除 = **sub_141862670**（vt[2] 逐子 + vt[25] (+200) 后置 0）；w6 经 `sub_1422BC600(+20768, "reopen_ingame_lobby_label")` 查子窗 | **+20768** | ctor 只把窗名交基 ctor sub_142255FA0，槽实写点在 reload/rebuild 链（合并块未逐行） | reopen_ingame_lobby | 定案（清除点） |
| 双竞标弹窗指针 | Reload（conf idpair 装载段） | **+20776** 与 **+20784** = CPeaceBiddingsPopUpWindow\* ×2 | **sub_141E584E0**(popup, conf) 装 conf idpair → popup+5248（popup vt 0x142A848A0） | — | 定案 |
| 清窗/复位函数 | dtor 首调 + Reload 双调 | **sub_14185F080** | 清九图标柄 +20880..+20976 + 三池销元素 + 清 +20800/+20808/+20816 | — | 定案（新锚） |
| Reload 变体 | **sub_141864560** | 无可见门 / 无 popup 装载，直接 输赢 → 主填充 → +20764 → +20768 → 地图模式 22 | 触发路径未追（推定 = 结束态/非可见路径） | — | 推定 |
| 主填充分派 | **sub_1418646F0** | completed → sub_140B653D0；否则九连 w4/w2/w3/w5/w6/w7/w8/w9 + 地图模式 22 | 九 worker 地址见上行各行 | — | 定案 |
| 输赢计算 | **sub_14185DE40** | conf+96/+120 map 查玩家 | 漂移 0x134E0 | — | 定案 |
| SetBiddingsIn\* lambda vt | — | **0x142A0E748**（winner）/ **0x142A0E780**（beneficiary） | mangled 签名零漂移（七参全同）；Winner 宿主 sub_141868380（thunk sub_1418687F0）/ Beneficiary 宿主 sub_141865250（thunk sub_1418687E0） | — | 定案 |

> 主 vt **0x142A0DB20** 四槽：[0] 0x14185CD80（→ 实 dtor 0x14185C670）/ [1] 0x14011D220
> const-false / [2] Reload 0x141862010 / [3] 0x14012A2C0 guard_nop；主 vt [-1] COL =
> 0x142D45EA0，表止位 = @40 COL 0x142D45F30。@40 子表（CTooltipHandler）**0x142A0DB48**：
> [0] BuildTooltip 0x141860410（体未逐行）/ [1] dtor 变体 0x14185CD68（thunk `sub_14185CD80(a1-40)`）。
> 基链 = CReloadableInterface@0 + CTooltipHandler@40（双 COL 证实）。ctor **sub_14185AE60**
> 尾段初值块：+20728=a2 / +20736=a3 / +20744=qword_14333D528 / +20758=1，尾至 +21000 全 0；
> 16× CButtonEventDispatcher stride 1288 @+48..+19368（vt 基）。Reload 0x141862010 流程：
> +20768 vt+584(73) 可见性 → idpair 自愈（conf+8 回写；peaceconferencewindow.cpp:539 =
> 0x21B 断言）→ 双 popup 装载 → +20752 输赢 → 主填充 → +20764 暂停暂存 → 网络通知 → 尾。


#### 4.30.11 科技+国策视图 (TechnologyView / NationalFocusView / FocusInlayWindowView)

**入口链**: TechnologyView target = **CTechnologyStatus 现取**
(sub_1406CFCB0(cc) = *(cc+3936), §4.7 ✓) — B3「CCountry 直读」第 2 例 (基 ctor mode=6);
NationalFocusView target = **查看国 CCountry\*@win+8440** (§4.30.1 存指针变奏; 显式 setter 0X14138C260
+ [6] SetTargetPlayer; 视图 #13), **第 4 子对象 CEventScopeProvider@+1408 (3 槽新骨架元素)**;
InlayWindowView = **无 RTTI 无虚表** (104B 非多态行视图, 池 win+1448)。**跨视图链定案**: 外交
infoCtrl+5304 → 视图#13 SetTarget (§4.30.9 目标 tag); @48 子表 this=win+48 坐标规则第 4/5 例。
新锚: 科技 template+984 年份/+992 基础成本/+1034 旗 / 解锁元+1000; cc+5620 树版本 / tree+152
inlay 表 / def+1416·+1470 (**见 §4.3.13**: def+1416=mutually_exclusive 定案 /
def+1470=dynamic name 旗 / tree+152=CFocusInlayWindowInstance 56B 内联)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 科技面板目标 | 无 SetTarget 槽; [6] 0X1415F9090 刷 win+1448 | **owner vt[20] 玩家 tag → 现取 *(cc+3936) CTechnologyStatus** | B3「CCountry 直读」第 2 例 (§4.7 ✓) | countrytechnologyview | 定案 |
| 研究槽行 (research_slots_grid) | Repopulate@48[9] 0X1415FA1A0 → 0X1415FA300 | **ts+160 data/{+172} count → CResearchSlotItem(0x580) 行, item+1336=slot** | 行模型 = §4.7 slots | research_slot_entry / research_slots_grid | 定案 |
| 行可见门 | sub_1415FB5D0 | ts+160 线性查 slot 指针 | 非本人槽不画 | — | 定案 |
| 空槽支路 | 0X141BE4BF0 slot+24==0 | — | title=UNUSED_SLOT + GFX_research_line_bg + empty_research_slot_glow | **UNUSED_SLOT** | 定案 |
| 行标题 (title 窗) | sub_140EDEBB0 → sub_140EC9A60 | slot+24 tech (名 tech+8) | 在研科技名 | — | 定案 |
| 进度条 (research_progressbar) | 0X141BE35C0; 分子 sub_140EDEDB0 / 分母 sub_140EDEA90 | 分子 = tech+408 ∨ slot+32; 分母 = template+992×qword_143332BA0/1e5 ∨ qword_143332A38; 归一 1e7 | 模板+992 = 基础成本 (新锚) | — | 定案 (链) / 分母语义高置信 |
| ETA 文本 (eta 窗) | sub_140EDA1B0 (tech+488 门) | tech+488 use_experience | 剩余天数 → ETA_SHORT_D/DAYS; 门 = 在研且窗可见 | **ETA_SHORT_D / DAYS** | 定案 |
| 年份 (year 窗) | sub_140EDF970 | **template+984 (>0 门)** | 科技可用年 (窗口名直证; 书未名) | — | 高置信 |
| 科技图标 (technology 窗) | sub_140B491B0 (模板) / sub_140B45D30 (解锁 def) | **门: !tech+360 ∨ sub_140EE3DD0(template+1034 ∨ tech+116==0)**; def 源 = *(tech+104) 首元 (+1000 旗) | 模板图 vs 首解锁装备图 | — | 定案 (书表命中) |
| 设计商图标 (designer 窗) | sub_14221F310 + sub_140DB8C20 | **tech+492/+496 id 对** | 有设计商 → GFX_research_line_mio_bg + 名 | GFX_research_line_mio_bg | 定案 (书表命中) |
| 页签切换 | SetupDerived lambda ×2 → win+1408; Repopulate 分派 | **win+1408 (0=research/1=facilities)**; +1552/+2920 页容器互斥 | assert "unknown tab" @ countrytechnologyview.cpp:0x116 | research_slots_tab / facilities_tab | 定案 |
| 设施页签本体 | ctor 0X141CAEA90 | **win+4288 = NProject::NUi::CFacilitiesTabView (0xB98, 窗 facilities_view)** | 布局未拆 — 列未决 | facilities_view | 定案 (存在) |
| 国策面板目标 | 直写 setter 0X14138C260 / [6] SetTargetPlayer 0X14138B200 | **win+8440 = 查看国 CCountry\***; getter 0X141387390 (0→玩家回退) | §4.30.1 存指针变奏 (非 [11] 槽); 换国广播 sub_14053A610(+8528) | nationalfocusview; 视图 #13 | 定案 |
| 外交→国策跳转 | 0X1415EC3E0 (dip infoCtrl cb3) | **manager vt[23] 视图#13 ← infoCtrl+5304 (§4.30.9 目标 tag)** | 跨视图 target 直传 | — | 定案 |
| 焦点树重建 | 0X141386BD0 | **cc+4976 树; 门 = win+8424/+8432 缓存 ∧ cc+5620 版本** | 树/版本双门; 题栏 NATIONAL_FOCUS_TITLE | **NATIONAL_FOCUS_TITLE** | 定案 |
| 焦点树插图行 (inlay) | push 0X141378820 / Setup 0X141BC0280 / Update 0X141BC0B80 | **池 win+1448{+1460} 104B; 源 = tree+152{count@164} 56B 条; 条+24 = CFocusInlayWindow def (名@def+88; 可见门 def+208)** | 每树条目一实例窗 `<名>_instance`; 三元素组刷新 | focus_inlay_window_view.cpp | 定案 |
| 焦点块状态 (池B) | sub_14138E800 | **fp = *(cc+4992); sub_1402D6C40 = fp+88 RH 命中; def+1416{+1428} 前置扫描 → item+48 状态 1/2/3/4** | 状态码驱五状态窗 (+56..+88) | — | 高置信 (状态语义推定) |
| 焦点块池A 刷 | sub_14138EAB0 | **fp 谓词 sub_1402D4460/1402D6820; originator sub_1402D1930 (UN tag)**; shine +1348/+1352 | 焦点格高亮/动画/归属 | viewing_flag | 定案 (书表命中) |
| 焦点名文本 | Repopulate 尾 | **sub_1402D2670(def, buf, tag); 门 def+1470** | UN 国策带 tag 名 (与 writer 双形态同源) | name | 定案 |
| 事件域 (换国广播) | +1408 接口 [1]/[2] | **win+8528 CEventScope**; sub_14053A610(obj, tag, 1) | 3 槽新骨架元素 CEventScopeProvider@+1408 | — | 定案 |
| 连续国策块 | sub_141BC3CF0/141BAE7E0 | **win+1440 = CContinuousFocusView (0x70)** | +8=win/+16=continuous_focus_window | continuous_focus_window | 定案 (形态) |
| 搜索/过滤/快捷格 | populate 0X14138D280 | **to_find_text(+8480, 观察者+2968) / filter_grid*(+1496..1528) / shortcut_grid(+1560..1568); +8728 = 搜索匹配行 / +8824 = 游标** | [16] 收尾还原 filter 态 | type_to_search_text | 定案 (读法) |
| 树缩放 | sub_140F237D0 绑定 | **win+8512 缩放控制器 ← zoom_in/zoom_out** (dispatcher +4416) | — | zoom_in / zoom_out | 定案 (读法) |
| 坐标校准 | — | **@48 方法 this = win+48 (第 4/5 例: 科技 a1+4240→win+4288; 国策 a1+8480→win+8528)** | 主表方法 this = win 无位移 | — | **定案** |

#### 4.30.12 决议视图族 (DecisionView + 三条目类)

**入口链**: DecisionView = **无 target·自见 (第九变奏)**
([11] 不覆写, 恒读玩家自身 gs+1312/1316 → cc → ds = *(cc+4000); 变更序列号缓存 win+1708);
条目类 = **def/entry 直存**: DecisionItem def@+4016 / TargetedDecisionItem entry@+4024 /
TimedDecisionItem entry@+2736 / CategoryItem 类别对象@+72。**视图基链 = CCountryView 17 槽
第 10 例; item 基链 = CStandardGridBoxItem 19 槽第 9 骨架; @48 漂移第 6 例**。决议行状态机
五态码 sub_141723540; **两个 ds 新容器 (ds+16 可用表 / ds+304 类别态表) 见 §4.12.3**;
def 侧新锚: +368 类别 / +376·+396 可用门 / +1600·+1620 成本。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 决议面板目标 | 无 SetTarget ([11] 基桩); @48[7] 0X1417290A0 序列号门 | **gs+1312/1316 → cc → ds=*(cc+4000)** | 「无 target·自见」变奏 (§4.12.3 ✓); 变更即 Repopulate | countrydecisionview | 定案 |
| 决议变更序列号缓存 | @48[7] 0X1417290A0 | win+1708 缓存 (sub_140DCCEA0 = owner vt[17]→+1848 + 全局+220) | 序列号比对侦脏 | countrydecisionview | 定案 |
| 普通决议行 (decision_grid) | pass A sub_1417274C0; Setup vt[25] 0X141D77DC0 | **ds+16 可用表 → def @item+4016**; 池 +1552..+1576 (0xFB8) | 行门 = **def+3296 on_map_mode ∈{1,2}** (1=decision_view_only/2=map_and_decisions_view) ∧ 类别+992==0 ∧ ∉to_re_enable ∧ (taken ∨ visible) | decision_item | 定案 |
| 行状态码 | sub_141723540 / sub_1417235E0 | taken∈ds{64/76}→3/4; visible(sub_1407367D0→"should_show") ∧ available(sub_1407313C0→"is_available") → 1/2 (cost sub_140726C20 分) | 0=隐/1=成本足/2=成本未足/3=采纳/4=采纳+冷却 | — | 定案 (链) / 语义高置信 |
| 行采纳勾选 | item+1312 dword | 状态∈{3,4,10,11}→1 | 已采纳显示 | — | 高置信 |
| 行名/图标 | sub_14072D610 (题) / sub_140B45190 (图标) | def+288 名; def+2444/+2528 分支附目标上下文 | ignored 集查询 cc+5360 (名键) → 状态元 1/2 | — | 定案 (读法) / 集语义推定 |
| 行按钮可用 | sub_14072FB10 / sub_140731E80 | **def+2816 ∧ def+2817** | 可选/可用双 byte 门 | — | 定案 (门) |
| 定向决议行 | pass B: ds+232 门 sub_141723CE0 / ds+256 门 sub_141723DD0; Setup 0X141D78360 | **entry @item+4024**; entry+40 state≠2 ∧(==1 ∨ sub_140736980); 源2 state∉{2,4} | targeted 族枚举 (writer 定案 2/3/4) ✓; 目标域触发 = entry+32 tag / +36 state 建 scope | targeted_decision_item | 定案 |
| 定向行目标国标 | Setup: entry+32>0 → sub_140B44AC0 | **entry+32 target_tag / +36 target_state** | 有目标 → 目标国旗/名; ≤0 隐 | — | 定案 |
| 定向行 ignore 态 | Setup: !*(entry+44) → 状态 2 | **entry+44 ignore** | CIgnereTargetedDecisionCommand 消费侧 | — | 定案 |
| 计时决议行 | pass C sub_141727BA0; Setup 0X141D78590 | **ds+160 → entry @item+2736**; entry+28 state∉{3,4} (timed 枚举) | active_timed 源; 日数 entry+24 | — | 定案 |
| 类别页签/头 | pass F sub_141726490; Setup vt[19] 0X141D77970 | **类别 @item+72**; 类别源 = 行组键 *(def+368) + ds+304{c@316} 表 | 逐组挂格, Y+=vt[17](136); 折叠表 win+1680{+1692} | category_header | 定案 |
| 类别描述行/头 | sub_141728AF0 分支 | **类别+480 = scripted_gui 名长字段**: 0 → InfoItem(0x88, win+1456 池) / 非 0 → EventCategoryHeader(win+1512) | `decision_category_desc` | — | 定案 (分支) |
| 类别可见门 | pass E sub_141727EC0 | **类别+568 ∧ sub_140731490 (+72 available/+976 power-balance/+992) ∧ sub_140736910 (+248 should_show/+268)** | power-balance 类别 (+992≠0) 不进普通行列表 | — | 定案 (链) |
| 格容器 | populate 0X141729130 | **win+1408 `decision_grid_container` / +1416 `decision_grid`**; +1512 头 (0x190) | vt[55](440)/vt[54](432) 查名 | decision_grid | 定案 |
| 地图决议图标 | (未拆) | CDecisionMapIconItem (19 槽, `decision_mapicon_item`); OnMapLocatorItem `on_map_decision_locator_item` | ctor 0X1418B8DA0 / 0X141D70BC0 | — | 定案 (存在) |
| 事件行 item | sub_141729C70 (decision_grid 顶部: 先挂 EventCategoryHeader(win+1512) 再按 GUImgr+1536 全局事件表逐条建行) | **CDecisionViewEventItem (0x550, 池 win+1520..1544); 窗名 = `event_item` (ctor 常量); 宿主 = CCountryDecisionView 本体** | 与 EventCategoryHeader 配套 | event_item | 定案 |
| amount_to_take 窗簇 | sub_141920540 ← sub_140C2BF60 (宿主 obj+74192) | 窗 decisionview_amount_to_take_items / _timeout_bg / decisionview_button | **非 CCountryDecisionView 成员** (另一宿主); loc DECISIONVIEW_AMOUNT_CAN_TAKE_ITEMS / DECISIONVIEW_AMOUNT_TIMEOUT_ITEMS | DECISIONVIEW_AMOUNT_* | 推定 (归属) |
| 坐标校准 | — | **@48 方法 this = win+48 (第 6 例: Repopulate a1+1344→win+1392, a1+1660→win+1708)** | 主表方法 this = win 无位移 | — | 定案 |

余量定案:

| 项 | 结论 | 证据 |
|---|---|---|
| CDecisionCategory | sizeof 0x3F8; 双 vt; ctor 0X140723750; 装载器 "Duplicate category" 断言; key 派发器全落名 | 断言+二进制文件 |
| CDecisionCategory+544 | SOnMapLocator vector (304B 元素, key 15048 = on_map_area) | — |
| CDecisionCategory+464 | scripted_gui 名串本体 (MSVC SSO: 缓冲@+464 / **size@+480** / cap@+488; ReadKey case 14961 写 +464; ctor sub_140723750 清零块 +464/+480=0/+488=15) | 二进制文件 |
| player_settings (token 14423) | 内 ignored 决议名集; 写侧 CIgnoreDecisionCommand 0X141157240 + CIgnoreAllAvailableDecisionCommand 0X141156FD0; pinned/新高亮排除 | 二进制文件 |
| on_map_mode 枚举 | 0=map_only / 1=decision_view_only / 2=map_and_decisions_view (默认 2) | — |
| binder→命令映射 | CSelectDecisionCommand 14345 / CIgnoreDecisionCommand 14768 / CSelectTargetedDecisionCommand 14383 / CIgnoreTargetedDecisionCommand 14769; TimedItem 复用 14345; CategoryItem cb = 折叠切换非命令 | RTTI |
| 窗名 | TimedItem = `timed_decision_item`; EventItem = `event_item` | ctor 常量 |

**定案 6 项**: cat+496 = **decisions 容器** {data@496, cap@504, count@508, alloc@512} (写点 sub_140725F50 逐类别 push; 消费 sub_140734EC0 可用决议遍历) / cat+336 = **`visible_when_empty` u8** (键 15243; ReadKey sub_1407332B0) / cat+1008 = **power-balance 类别值 i32** (默认 −1; 类别名副本 = +976 串, **size@+992 / cap@+1000**) / SOnMapLocator = **CDecisionCategory::SOnMapLocator** (vftable 0x1427EB2E8, ctor sub_140724070; 304B 元素: +8 内嵌 CScriptTargets / +264 zoom 键 11793 / +272 loc 名 键 27 默认 ON_MAP_DECISION_NAME_DEFAULT / +288 size / +296 cap) / GUImgr+1536 = **CInGameIdler 全局待显事件表** {data@1536, cap@1544, count@1548, alloc@1552, 游标@1560}, 元素 = **CEvent\*** (id u32@0) / amount_to_take 宿主 = **CTopBar+39144** (窗 `decisionview_amount_to_take_items`, +39152 配 `_bg`; 装于 [2] Reload sub_14189ECF0 体内的 sub_14189EF20)。
**前提证伪 2 项**: 「pass D 排序键」不成立 — sub_141727810 是**地图/隐藏决议收集 pass** (门 sub_1417312F0 + sub_140736AE0(cat+336) + sub_140736910(cat+248/268)), 全 pass 后**无 sort 调用** (worker sub_1417297C0 尾段仅释放临时容器 + grid 刷新), 行序 = 各 pass 调用序 (A 普通 → B 定向 → C 计时 → D 地图 → E 类别 → F); 「def+272 写点」**不存在** (全 dump 0 写点, 推定偏移笔误 — decision def 串区在 +288)。

#### 4.30.13 情报视图簇 (AgencyView / IntelLedgerView / CryptologyEntry)

**入口链**: AgencyView = 17 槽第 11 例, 「自见」+ 省点击
转发 (SetTarget → 内嵌 CCryptologyView+48), **ag = *(cc+4032)**; LedgerView = **新骨架第 10
(CReloadableView 9 槽 + CTooltipHandler@88)**, target = 「tag 存储」@win+5456 (§4.30.9 同族),
四页签按 mode 推 tag; CryptologyEntry = 19 槽第 10 例, target = tag@item+32, 数据 =
**CCryptology (=*(ag+288)) 的 CCountryDecryptionState 56B** (12 项密码偏移全定)。
**定名**: mdef 528 = crypto_strength (cc+1464); mdef 529 = 密码学部门态旗 crypto_department_enabled
(Evaluate 同址直证; 528/529 是 modifier def 索引, 非 lexer token); 进度分母 = define×目标国
mod528 (攻防分离)。定名见 §4.3/§4.11。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 机构面板目标 | 无存储 SetTarget; @48[9] 0X140F2F3A0 现取 | **owner vt[20] tag → cc → ag=\*(cc+4032)** (§4.3/§4.11.14 ✓) | 「自见」变奏 (§4.30.3/§4.30.11 同款); 面板恒显查看国机构 | countryintelligenceagencyview | 定案 |
| 机构名/徽标 | Repopulate 0X140F2F3A0 | **ag+128 name SSO → win+1448; ag+160 icon SSO → win+1672 (vt+728)** | 书 ✓ 两恒写槽的 UI 出口 | agency_name / name_logo | 定案 |
| 分支升级格 | Repopulate + CBranchUpgradeButtonEntry (sub_141A230F0) | **DB qword_14332EDC0 {count@+124, items@+112}** → 窗 `upgrade_button`; ag 回指 @entry+40 | 分支/升级条目 (def@+48); `agency_branches` 格 | agency_branches | 定案 (读法) / DB 类名未定 |
| 行动列表 (operations) | @48[6] Update 0X140F2F720; [4] 预算 CalcOperations 0X140F29150 | **4×SBufferedOperations 静态 (unk_14333D420/A8/C0/D8)** × tag 过滤 → 0xAC0 行 {+2728 序, +2736 COperation\*, +2744 纪元快照}; 纪元 qword_14333D4C8/14333D528 | 行动页数据流 (tbb 并行预算); 行级 COperation 14 字段定案见 §4.31.14 | — | 定案 (机制) |
| 面板内省点击→密码过滤 | [11] 0X140F2C150 | **prov+192→state+204 controller → CCryptologyView+48** | 省转发变奏 (§4.13 ✓) | — | 定案 |
| 密码头部: 防御等级/解密强度 | sub_141A221C0 | **crypt=\*(ag+288)**; LEVEL = **mdef 528 = crypto_strength** (528/529 是 modifier def 索引非 lexer token) @\*(crypt+8)+1464; STRENGTH = sub_1413F7C60(crypt, level) | §4.3 修正式出口 | CRYPTO_DEFENSE_LEVEL/LEVEL, CRYPTO_DECRYPTION_STRENGTH/STRENGTH | 定案 |
| 密码部门激活旗 | sub_1413F86E0; 触发器 CIsCryptologyDepartmentActive::Evaluate 0X1403DA800 | **mdef 529 = crypto_department_enabled** ≠0 | 显 `crypto_not_active` (==0) vs `active_crypto_items` + 国表刷新分支 (≠0; 极性消解 = 与触发器名同向) | crypto_not_active / active_crypto_items | 定案 |
| 密码国别行 (cryptology_country_entry) | Setup sub_141A223E0 | **tag @entry+32**; 记录 = **CCountryDecryptionState 56B** {tag+8, days+12, 全解密+16, 解密中+18, 进度分子+24} @玩家 crypt 24B 槽 {data+40, count+52} | 玩家侧对目标国的解密账本 (operatives/cryptology.cpp 断言实名) | cryptology_country_entry | 定案 |
| 行进度条 | Setup: 100000×分子/分母 → clamp 1..100 | 分母 = **目标国自身** mdef528 式 `qword_143333030 (=CRYPTO_BASE_CRYPTO_LEVEL) + qword_1433330F0 (=CRYPTO_CRYPTO_LEVEL_PER_CRYPTO_UPGRADE)×level/1e5` (define 注册串定名) | 披露门 = 分子≥同式; 无分母 → -1 | entry+3984 簇 | 定案 |
| 行状态文案 | Setup 分支 | +16 旗 → CRYPTO_FULLY_DECRYPTED/CRYPTO_FULLY_ACTIVATED; +18 旗 → CRYPTO_DECRYPTING/CRYPTO_NOT_DECRYPTING (天数 sub_1413F7960); REVEAL_INTEL(_LEFT) ← dword_1433331A0 ∨ 记录+12 | 解密状态四态 | CRYPTO_DECRYPTING / CRYPTO_NOT_DECRYPTING / CRYPTO_FULLY_DECRYPTED / CRYPTO_FULLY_ACTIVATED / REVEAL_INTEL / REVEAL_INTEL_LEFT | 定案 (读法) |
| 行候选门 | sub_141A228B0 + sub_1413F8640 | 排除 自国/同国(140BA60A0)/tag≤0/**cc+1156 owned_states≤0** (§4.3 ✓)/自国·同阵营 (cc+3976+656 §4.5 ✓) | 只列「有争议州且非友方」的国 | country_list / country_list_container / add_new_container | 定案 |
| 账本面板目标 | **vt[7] thunk→sub_1419DABD0**; @48[9]→vt[4] 0X1419DB0B0 | **win+5456 tag 存储**; 缓存脏旗 \*(qword_14333CFB8+48)+83; win+5460 计数; win+5248 mode | 「tag 存储」变奏 (§4.30.9 同族); CReloadableView 9 槽新骨架 | country_intel_ledger_view | 定案 |
| 账本四页签 | populate sub_1419DAC10 | 块 +5256/5304/5352/5400 × 区 +96/1384/2672/3960 (**区 = CLegacyButtonObserverGlue\<CCountryIntelLedgerView\> 1288B**); 窗 econom/army/navy/air_panel(+_tab_frame); 区回调 = 置 win+5248 mode + **切 map mode 30** | economy/army/navy/air 四视图 | econom_panel 等 | 定案 |
| 页签面板刷新 | vt[4] 分派 → 面板 vt[1] 0X141EA9930 | 面板+8 = tag; vt[2] 自填充 (navy 0X141ECCCA0 / air 0X141EAB690 / army 0X141EB85A0) | 换 tag 即全量重算 | — | 定案 |
| 共享头控制器 | sub_1415137C0 直写 | +5448 CIntelLedgerHeaderController {vt, tag@+8} (0x10) | 四页签共享的目标 tag 副本 | — | 定案 |
| navy 页汇总行 | 面板 vt[2] 0X141ECCCA0 | **cc+632/{+644} 容器** → sub_140D230E0 逐元聚合 {键, 数} | 目标国海军汇总 (书中未名) | — | 定案 (存在) / 语义推定 |
| 账本行悬停 tooltip | @88[0] 0X1419DA3E0 | 四元素簇 +5168/+5216/+5264/+5312; sub_141E9CAF0(gs tag→cc, win+5368, id, out) | 按簇 id 组装 | — | 定案 (机制) |
| 账本理念行 | ctor sub_141E97FB0 | `ledger_idea_entry`; +32 dword / +40 icon 窗 | economy/navy 页理念列表 | ledger_idea_entry | 定案 (形态) |
| 坐标校准 (agency) | — | **@48 方法 this = win+48 (第 7 例: Repopulate a1+1344→win+1392, a1+1648→win+1696)**; 主表 this = win | 家族规律复证 | — | 定案 |
| 坐标校准 (ledger) | — | 主表方法 this = win; **BuildTooltip this = win+88** (CTooltipHandler 挂 +88 非 +40/+24 — 首见位) | 基子对象偏移逐类不同 (§4.00.2 警告 ✓) | — | 定案 |

#### 4.30.14 占领视图簇 (OccupationView / Policy·Setting·Garrison Selection / StatusView / TerritoryEntry)

**入口链**: OccupationView = 17 槽第 12 例, 「自见+省点击转发」
(prov+192→state+204, 门 cr+80>0); 数据源 = **cc+4048 占领管理器** (CCountryOccupationStatus,
RTTI vtable 0X142982CF0; 记录的 272B 布局偏移仍有效: 三张按 state id 的 RH 表,
+72/+80 汇总槽回灌 UI; §4.3)。
**COccupationStatusView**: Update 实为 ~215 行直消费 CResistance (§4.13 命中 7;
6355 系索引 span 误判)。
**cr+552 = compliance_modifiers (定案, UI 消费)**。
骨架: TerritoryCountryEntry 19 槽第 13 例 / TerritoryStateEntry 第 14 例 (内嵌双 StatusView)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 占领面板目标 | [11] 0X141566650 → sub_14156F3D0 | **prov+192→state; state+204 controller 门; cr+80>0 门**; 数据恒取 \*(玩家cc+4048) | 省转发+自见混合变奏 (§4.13/§4.14 ✓); 无跨视图存储 | countryoccupationview | 定案 |
| 被占领国行集 | sub_14156F5B0 | **occmgr {data@96,count@108}** (CCountryOccupationData 列表, 按页签 +11880 过滤) + 列表 B (controlled_states×cores 国 tag 集) | 玩家占领账本双源 (有账本国 + 仅 core 无账本国) | occupation_territories_list | 定案 |
| 行内汇总 (国行) | Setup sub_14156E780 + 详情体 E3C0 | **tag@entry+7800**; entry+48=occdata+72, entry+56=occdata+80 | 每被占领国账本条的三槽汇总回灌 | occupied_territory_country_entry | 定案 |
| 州数 "x/y" 文本 | sub_14155D120 | **cc+1192/{+1204} (被占领国 owned states) × state+204==玩家 过滤计数** | 已占领/总州数 | (数字拼串) | 定案 |
| 州 manpower 文本 | sub_14155D120 | **Σ sub_1413EB130(st+2104)** (锚×系数/1e5; 书 ✓) | 占领州人力可用合计 | (数字) | 定案 (读法) |
| 建筑资源双列 | sub_14155D120 | **st+368 建筑 × 资源块+480 的 +764/+768 × 等级 i16@+64 ×100000; 再 × (st+2256 RH 行值+100000)/100000** (按占领国折减) | 占领资源产出拆分 (双列 = 书中未名) | (数字×2) | 定案 (机制) / 列名未定 |
| 表头汇总条 | sub_14156F5B0 尾 | **win+11960 = Σ行+48; win+11968 = 均行+56** | 全账本合计/均值 | (数字) | 定案 |
| compliance/resistance 页签 | cb sub_141566A40 | **页管理器 sub_140E139B0 dword@0 = 6(compliance)/7(resistance)**; sub_140A66DE0 置页 | 与 §4.30.13 情报管理器同全局 (qword_14333CFB8 族) 的页号槽 | compliance_tab_button / resistance_tab_button | 定案 |
| 排序/过滤页签 (5 枚) | cb sub_141565790 | **win+11880 = 按钮携带 id**; 列表 sub_14156B430/sub_14156B8E0 消费 | 二级页签 (排序类别) | — | 定案 (机制) |
| 只显抵抗国开关 | cb sub_141566B70 → 全重算 | 列表 B 生成门 (sub_140FF7780) | 开 = 同时列无抵抗占领国 | OCCUPATION_SHOW_NO_RESISTING_COUNTRIES / show_non_resisting_container_checkbox | 定案 |
| 开「选占领政策」 | cb sub_14156B310 → sub_141566D80 | 清 +11720 持有点 {+8,+16} → 弹策略窗 (过滤槽 +8 tag/+16 state) | 弹窗过滤槽变奏 | select_law_icon | 定案 |
| 开「驻军模板」 | cb sub_14156B3A0 → sub_141566CD0 | 同上开驻军窗; has_target 门 (+11832 vt+176) | 需先选中目标州/国 | garrison_template_button | 定案 |
| 政策弹窗标题/数据 | [2] 0X14156D6B0 | tag>0: occdata(+160 日期); state: **st+616** (sub_1406F2F20 法 id, sub_140F99DB0 法); 空: occmgr+280 | 三态过滤 (国/州/默认) | DEFAULT_LAW_SELECTION | 定案 |
| 驻军弹窗模板列表 | [2] 0X14156C940 | **玩家cc+440 CDivisionTemplate\* 容器**; 默认法读取 = sub_140FF7BB0 (法 A = occdata+120 / 法 B = occdata+128) | 驻军模板 = 编制模板子集 | OCCUPATION_PRIMARY_GARRISON_TITLE | 定案 (读法) |
| 当前占领法旗标 | sub_140F99C00(cr,0) +24 | **cr+80 → controller occmgr → occdata → 按州查法 COccupationLaw\*** (+24 旗 SSO) | GetOccupationLaw 族 (断言串实名) | (旗标) | 定案 |
| 默认法旗标 (面板头·法 A) | sub_14156FE90 | **occmgr+120** 回退 → 旗标 +24 | 无州上下文的默认法 A | (旗标) | 定案 |
| 默认法旗标 (面板头·法 B) | sub_14156FE90 | **occmgr+128** 回退 → 旗标 +24 | 无州上下文的默认法 B | (旗标) | 定案 |
| 抵抗/合规状态小部件 | **Update sub_14156E190** | **cr+16 / cr+64 → 图标帧+百分比 (clamp 0..100)**; 门 **cr+520** | §4.13 CResistance 数值槽的 UI 直出口 | *_resistance_status_container / *_compliance_status_container | 定案 |
| 小部件修正列表 | Update 后半 | **cr+528 (15743) / cr+552 (15747)** + 状态行 cr+472/cr+496 + 全局触发表 sub_140319DE0 行[size+3] | 修正清单按 size 枚举分族 | occupation_modifier_entry | 定案 |
| 小部件进度条 | Update 尾 | sub_140F959F0(cr) 分子/100 → `min+(x/100000)×(max-min)` (vt+232 查 max, +56 覆盖源) | 数值进度条标准三段式 | — | 定案 (机制) |
| 州状态行 (detail) | Setup sub_14156EF60 | **CState\*@entry+3904**; 双 StatusView@+3912/+3920; +3928 州名; +3944 GetOccupationLaw 族返回+80; **+3952 = 驻军模板旗标; +3992 = 表2 记录经 sub_140FF5490 计算的 1e5 进度值; 表3 记录+24 = CDivisionTemplate\* 驻军模板** | 州行 = StatusView 分发器 | occupied_territory_state_entry | 定案 |
| 行高/滚动 | 行 vt[17](136)+4 / 格+128 子件 vt+56 | 100000 滚动标度 (SetTarget 后定位选中行) | CStandardGridBoxItem 家族复证 | — | 定案 |
| 坐标校准 | — | 主表 this = win; **弹窗 [4] populate this = 弹窗**; **StatusView Update this = view (基子对象全在 view 内, 无漂移)** | 家族规律 | — | 定案 |

余量定案:

| 项 | 结论 | 证据 |
|---|---|---|
| cc+4048 类身份 | **CCountryOccupationStatus** (vtable 0X142982CF0, 书命名正确); 记录的 272B 布局偏移仍有效; 活体 +8=2/+16=0/+24=静态空对象, 与中立未占领态自洽 (§4.3) | GER 探针活体读 vtable |
| cc+4048 对象+8 | occmgr 回指 (非占领国 cc) | ctor 直证 |
| cc+4048 对象+32 | CState\* 向量 (非 SSO) | — |
| 表3 记录+24 / +3952 / +3992 | 表3 记录+24 = CDivisionTemplate\* 驻军模板; +3952 = 驻军模板旗标; +3992 = 表2 进度值; +160 高置信 : 活体 = CGameDate@+136 (hours@+144) + 法槽@+168, 「+160」两说均差位 24, 留 writer 侧对账; 附带: 记录元素 = 8B 指针 (tag@rec+8 实为回指 lo32, 对象层注记待校) | — |
| 国行 6 glue 钮 | 钉选 / 政策弹窗 / 驻军弹窗 / Release nation = CReleaseCountryDialog / Return territory / +6512 地图定位 | RTTI 实名 |
| WithoutResistance 条目 target | +1320 CState\*; tooltip = ret0 桩 (有意无 tooltip); 创建点 = E3C0 无抵抗分支 (被占领国 owned × 玩家控制 × cr+80≠被占领 tag) | — |

#### 4.30.15 后勤+贸易+市场 (LogisticsView / TradeView / MarketStockpileWindow)

**入口链**: LogisticsView = 17 槽第 13 例, 自见账本
(tag 懒存 view+6784); TradeView = 17 槽第 14 例, 自见 + 行级选择 (资源行+32 = 资源 def /
国家行+1328 = CCountry\*); MarketStockpileWindow = **新骨架 CEmbeddedWindow 四虚表族**,
双槽直绑 (win+136 CMarketStockpile / win+144 卖方 CCountry\*)。**单例定名**: 
qword_14332EEC0 = common/units/equipment DB; **qword_14332F088 = common/resources DB**。
命令族三员: **CSetFuelPriorityCommand (15573)** /
**CMarketStockpileClearCommand (10191)** / **EquipmentTransferCommand (13859)** /
**StockpiledEquipmentDeleteCommand (14424)**。补录: ps+696..+792 工厂占用条 /
CEquipmentType+1240 父 archetype 链等 10 条 (§4.8/§4.23)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 后勤面板目标 | [11] 基桩 (无) | **view+6784 tag (懒) → gs+1312/1316 回退 → cc** | 自见变奏; 数据恒现算 | countrylogisticsview | 定案 |
| 装备行集 (三军) | populate 0X141730A80 | **qword_14332EEC0 = common/units/equipment DB {items@+128, 计@+140}**; 域谓词按 archetype 父链 +1240/掩码 +1344 | 全 archetype 遍历分 land/naval/air (0x201 / !=0x200000000 位门) | logistics_overview_*_equipment_entry | 定案 |
| 特殊行 ×2 域 | sub_14172E380 | **item+988 = CEquipmentType 的 `group_by` 脚本键值 token (: vt[4] KV 分发 sub_140C99410 case 13022, 默认 357="none"; 邻槽 +992 = interface_category token)** | 225="type" → **CLogisticsOverviewTypeItem** (0x5F8, 按 type 位掩码聚合); 12103="archetype" → **CLogisticsOverviewEquipmentItem** (0x5D8 单行); 默认 → OtherItem 桶 — 三 RTTI 类名铁证; 「convoy/train」猜想证伪 (原版用户 = 导弹族) | — | 定案 |
| 「其它」行 | sub_14172E320 | 0x568 行 {桶 data@+1344, 计@+1356} | 域内非特判 archetype 聚合桶 | logistics_overview_*_other_entry | 定案 |
| 行数值 (库存/需求/缺口) | sub_141D9BFE0 → sub_141371450 族 | **\*(cc+3992) CLogisticsStatus** (logi+8 队列聚合; kind 1..6,14); 行 +1392..+1488; **+1440 = k6−Σk1..k5** | 后勤账本行出口; logistics.cpp:0x2E8 断言 | (数字组) | 定案 (偏移) / kind 名未定 |
| 军工厂占用条 | sub_1417327F0 | **ps+696(总量)/728(已分配产线工厂)/752(转出合计≡760+768)/760(上缴宗主)/768(外赠目标国)** (bar = 100−比例转换) | military_factories_usage | military_factories(+_usage) | 定案 |
| 海军工厂占用条 | sub_1417327F0 | **ps+792 (船坞总量)** × sub_140E69130(ps) | naval_factories_usage | naval_factories(+_usage) | 定案 |
| 优先级按钮 (低/中/高 ×3 域) | cb 0X141730780/D3A0/D0B0 → post | **CSetFuelPriorityCommand {tag@+40, category@+44, level@+48}**; 域号 = 行+8 | 后勤分配命令 (§4.00.6 post ✓) | low_prio / medium_prio / high_prio | 定案 |
| 油料子窗 | sub_141D900D0 / sub_141732C30 | **\*(cc+5504) fuel_status**; 窗柄 view+6712 | fuel 类型分支 (断言 "invalid fuel type") | logistics_fuel_window | 定案 |
| 信息子窗 / 展开钮 | sub_141D8B8F0 / populate 尾 | 窗柄 view+6720 / expand_button view+6896 | — | logistics_info_window / expand_button | 定案 |
| 核弹区 | sub_141733680 | "nuke" 元素 | nuke 显示 (未逐行) | nuke | 定案 (机制) |
| 贸易面板目标 | [11] 基桩 (无) | 玩家 gs+1312/1316 每帧现取 | 自见变奏; 页号 8 | countrytradeview | 定案 |
| 资源行集 | sub_1415FE3D0 | **qword_14332F088 = common/resources DB** (sub_140AE2E50 按行取); def+16 启用旗 | 全资源双行 (info+filter) | resources_grid / resources_info_entry / resources_filter_entry | 定案 |
| 资源余额行 | sub_141CBE710 | **rs+48/+216(净余)/+224/+400/+1112 × def+216 行号**; 进出口 sub_140C9DAE0(0/1); 因子 = 1e10/def+224 | RESOURCE_BALANCE_VALUE 六元素 | resources_info_entry | 定案 (偏移) / 数组名推定 |
| 国家行集 | sub_1415FDE00 | gs+796 国槽 × gs+784 国数组; 行 **+1328 = CCountry\*** | 全国行 (country_trade_entry) | country_trade_entry | 定案 |
| 行点击 → 详情 | cb sub_141CBD6B0 → sub_141CB64F0 | **subwin+4080 = CCountry\*** | SetCountry; rs+1928 路线快照 → subwin+4144 | — | 定案 |
| 船队需求文案 | sub_141CB6B50 | **玩家 cc+4608 空闲船队 sub_141021C20** + route+40 占用 | convoys_description (需 vs 有) | convoys_description | 定案 |
| CIC 报价文案 | sub_141CB6B50 | sub_140CA8160(资源号, 玩家tag, 目标tag, …) | TRADEOFFER_FACTORIES_DESC_LABEL / "CIC" | factories_description | 定案 |
| 国家行过滤 | sub_1415FEDA0 | **dip=cc+3976: +656 阵营成员白名单 (faction 过滤器) / +368 tag 表 (subject 过滤器 → 附属国 tag 表, 推定)**; **13024/10877 = 过滤器 token 非规则** (CRuleDefinition 注册表 24 条全集无此二 token; 窗体构建 sub_1415FD620 硬编码 CFilterTokenItem 按钮 faction→参数3/subject→参数5/13349=neighbor; view+7920 = 激活过滤器 token 数组) | 战时/阵营/附属贸易过滤 | — | 定案 |
| 市场库存窗 | [1] Update + [11] OnOpen + sub_14200DE50 | **win+136 = CMarketStockpile (EPool@+56 {data@+88, 计@+100})**; **win+144 = 卖方 CCountry\*** | 卖方市场库存行 (0x1EF8 窗) | market_equipment_stockpile_window | 定案 |
| 库存行数值 | sub_1413BAC30 | variant+1032 位分支: bit0 → **cc+4624 池 / +4716 / +4728/+4736 缓存**; else → **ps+512 查量** (sub_14100EB00), bit31 → sub_1406EE6E0 链扣减 | 可投放量现算 (船队类特殊换算) | — | 定案 (链) / 位名推定 |
| 清空市场库存按钮 | CMarketStockpileClearCommand [10] | **\*(cc+4024)** (scopedptr 直证) → sub_1419D6F20 | id 10191; {tag@+40} | — | 定案 |
| 库存转移 | CMarketStockpileEquipmentTransferCommand [10] | market + 双 64B 池载荷 (+40/+104) | id 13859 | — | 定案 (读法) |
| 库存删除 | CStockpiledEquipmentDeleteCommand | 载荷 idpair@+40 | id 14424; Execute 未拆 | — | 定案 (形态) |
| 坐标校准 | — | 主表 this = win; **@48 worker this = view+48 (内文 a1−48)**; 市场窗 [1][11][12] this = win | 家族规律 | — | 定案 |

#### 4.30.16 散簇·铁路炮+轨道图标 (CRailwayGunListView / StatsView / CRailwayMapIcon)

**入口链**: StatsView target = **CRailwayGun refid 对 @view+2672** (ctor
sub_141CFF1C0 写入, +56 raw 缓存); ListView = 非窗口监听器/控制器 (条目
CRailwayGunViewEntry\* 数组 {d@L+128, c@L+140}); MapIcon target = SetRailway
省对 + 48B DTO (⚠ **轨道图标, 非铁路炮图标** — RAILWAY_UPGRADE/CANCEL/
IN_COOLDOWN + 两省中点 + CChangeRailwayConstructionLeveLCommand〔原文拼写 LeveL〕三证)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| StatsView 攻击行 | 统计行填充 | **def+608 × (1+mdef 0x24E MODIFIER_RAILWAY_GUN_BOMBARDMENT_FACTOR)** | 攻击值公式 (def 注册定名) | STAT_RAILWAY_GUN_ATTACK | 定案 |
| StatsView 射程行 | 同上 | **def+616** | RAILWAY_GUN_POSSIBLE_RANGES 索引 (assert railway_gun.cpp:0x464) | STAT_RAILWAY_GUN_ATTACK_RANGE | 定案 |
| StatsView 强度/速度/补给/重整行 | 同上 | gun+1008 strength / def 侧 / CEquipment+1056 manpower / — | 五统计行 | COMMON_MAX_STRENGTH / COMMON_MAXIMUM_SPEED / ARMY_SUPPLY_CONSUMPTION / HOURS_TO_REDISTRIBUTE | 定案 |
| StatsView 装备行/逻辑国 | 同上 | gun+824 装备 id 对 / gun+480 logical_country | §4.16/§4.18.1 命中 | — | 定案 |
| ListView 条目/选择 | CRailwayGunEntryListener 9 槽 | 条目 CRailwayGunViewEntry\*; gun+496 省 / gun+1088 army / gun+12 选中字节 (定案: = CSelectable 选中字节, IsSelectable 断言 railway_gun_view.cpp:0x1A3 + 双 listener 直读; id 对在 +24/+28 重叠虑不成立) | 单击选择/加选/地图居中/脱离指挥组/开统计窗 | — | 定案 |
| ListView 批量操作 | 5 glue 钮 | → 命令链 | 批量脱离/批量取消移动/全选/批量删除确认 | — | 定案 |
| 轨道图标 升级/取消/冷却 | SetTarget sub_141909780 | **省对 @+1424/+1432 + DTO @+1440: +1468 当前等级 / +1472 目标 / +1476 冷却**; dword_1433349D8 = MAX_RAILWAY_LEVEL | 铁路(轨道)升级图标 (**非铁路炮**) | RAILWAY_UPGRADE / RAILWAY_CANCEL / RAILWAY_IN_COOLDOWN | 定案 |

命令族 (RTTI 实名): CUnassignRailwayGunFromOrdersGroup / CCancelMovementCommand /
CConfirmDeleteUnits / CChangeRailwayConstructionLeveLCommand〔原文拼写 LeveL〕 — §4.00.6 添员。
簇定名 (全解):

| 项 | 结论 | 证据 |
|---|---|---|
| 按钮 .gui 名 | **interface/railway_gun.gui** (窗名 railway_gun_list_view / railway_gun_stats_view 同文件); 五 glue 钮 widget 名 = **btn_delete (+72) / btn_select_half (+48) / btn_unassign (+56) / btn_hold (+64) / btn_close (+80)** | CInGameIdler ctor 直读 + CRailwayGunListView glue sub_141D01DE0 逐钮绑回调 |
| host 类名 | CRailwayGunListView 宿主 = **CArmiesView** (vt 0x1429E9C98); CRailwayGunStatsView 宿主/开启者 = **CRailwayGunListView** (vt[7] sub_141D01840 建/取 stats view 并缓存宿主 +2632) | 建件点 sub_1416AE5D0 双件 (与本节 §4.30.29 CArmiesView @+1416/+1424 一致) |
| def 字段名 | **railway_gun_attack (CEquipment+608) / railway_gun_attack_range_index_in_define (+616) / railway_gun_annex_ratio / railway_gun_hours_between_redistribution** | 磁盘实名 common/units/equipment/railway_gun.txt + 统计行 loc 族 (§4.18.2) |
| 省铁路标志结构 | **CProvinceRailwayInfo** (0x70, RTTI 实名; 布局见 §4.14.6); 轨道图标侧 DTO = **CRailwayMapIcon+1440 48B**, 字段 +24/+28/+32/+36 u32 四元 + +40/+41 byte 双旗 + +44 u32 (书 +1468/+1472/+1476 = 实测 +28/+32/+36; **另补 +1464 = \*(a3+24) 谓词与解析入口**) | SetTarget sub_141909780 逐行 memcpy + 逐字段拷 |
| 5 个 define 名 | **MAX_RAILWAY_LEVEL = 0x1433349D8 / RAILWAY_GUN_POSSIBLE_RANGES = 0x1433399E0 (+count 0x1433399EC) / RAILWAY_ICON_SHIFT = 0x143333580 (float3) 三定案**; RAILWAY_ICON_CUTOFF = 0x1433334C8 / RAILWAY_CONVERSION_COOLDOWN = 0x143332070 两推定 | 前三直接消费实证 (tooltip 门 / 注册 + 磁盘注释 / 图标定位偏移); 后二仅注册点与同名语义关联 |
| 附带 | RAILWAY_MAP_ARROW_THIN_LEVEL_THRESHOLD = 0x143333C28 / _MEDIUM_ = 0x143333CE0 / _THICK_ = 0x143333D88 (轨道箭头等级分档) | 注册点 + 消费 sub_14165D050 粗细分档 |

**定案**: 省铁路 +104 = `cooldown` u32 单标量 (tok 14622, writer sub_140E95DD0) — **无位段**; 阻断语义由 +80 块 `rail_way_construction` (16B 条 {邻省 u32@0, 进度 fixed×1e-5 i64@8}) **非空**表达 (施工中 = 阻断)。

#### 4.30.17 散簇·海军总览/舰队底栏/沉船 (CNaviesView / CFleetsBottomBar(+Item) / CSunkShipEntry / CSunkShipIcon / CNaviesViewSunkShipItem)

**入口链**: NaviesView = 选择集驱动无单 target (17×1288B 胶水块 + 四子件);
FleetsBottomBarItem target = **CFleet idpair 快照 @item+32** (SetTarget 0X141DE6F60
直拷 fl+8); SunkShipEntry target = **CSunkShipInfo\* 裸指针 @entry+32** (宿主
CNavalLossesOverview); SunkShipItem target = **CShip history 元素+120 内嵌
CSunkShipInfo** (is_sunk 门 @entry+114)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 沉船条目全字段 | populate 0X1417FD790 | **CSunkShipInfo +8 name/+40 killer_name/+72 country/+76 killer_country/+80 date/+104 definition/+112 killer_definition/+124 variant/+144 location** | **10/10 全中 §4.16.14**; killer-type 枚举 helper 0X140C2DFC0 / KILLER_AIR 0X140C2DF50 | naval_losses 族 | 定案 |
| 沉船行 (舰队沉船页) | is_sunk 门 @entry+114 | **CShip history 元素 {+114 is_sunk, +120 内嵌 168B CSunkShipInfo}** (sh+2264/+2316 容器) | **history 元素布局定案** (§4.16); assist@+161/level@+120/def@+104 全中 | — | 定案 |
| 舰队底栏条目 | SetTarget 0X141DE6F60 | **CFleet idpair 快照 @item+32**; fl+224 name (§4.16 ✓) | 解散 = CConfirmDisbandFleet; 候选 fl+24/+44/+56/+184/+196 未决 | navy_leader_window | 定案 (target) |
| 舰队底栏 | 选择集+1100 idpair | resolve → +32 CFleet\* 数组 | 属主未决 | — | 定案 (形态) |
| 海军总览 | Setup 0X141819200 / UpdateButtons 0X14181D070 | tf ship 容器 (tf+840/852) / repair_parent (tf+1200/1204) / target_ship_types (tf+1856/1868) / refid + gs 玩家 tag | 四子件内嵌 (LeaderWindow/MoveShips/CompositionEditor/CompactShipList); 候选 tf+884 任务类型枚举见 §4.31.5 (定案) | — | 定案 (命中) / 候选推定 |
| 沉船图标 (海战参战) | populate 0X1417EFDB0 | 参战舰组 40B {ptr 数组@0, count@+12}; 记录 W: +32 owner tag/+64 pride u8/+136 舰体名串 | icon 帧 = is_sunk+1 (帧2=沉); pride 金/灰双色 CColor | — | 定案 (形态) / W 推定 |


**窗壳重锚**（1.19.3：海军 GUI 群全结构偏移零漂移，地址整体平移；TD/vt 全表）：

| 类 | vtable (1.19.3) | 主 vt | ctor | 备注 |
|---|---|---|---|---|
| CNaviesView | 0x142A06850 + @40 0x142A06878 | [2] Reload 0x141816D20 / tt [0] BuildTooltip 0x141809190 | **0x1418029A0** | 17 胶水块 @+304..+20912 步距 1288B 全清；+120 CCompactShipListView / +22200 detailed_fleet_list / +22216 CTaskForceCompositionEditor / +22240 CNavyLeaderWindow / +22248 CMoveShipsWindow / +22256 舰船视图厂 / +224 哨兵；胶水块 ctor 0x141801810 |
| CFleetsBottomBar | 0x142A001A0 + @40 0x142A001C8 | [2] Reload 0x1417A68F0 | 0x1417A4F10 | tt [0] = const-false 0x14011D220；Setup 0x1417A6930 / populate 0x1417A5300 / Reload 前段 0x1417A5B10；窗柄 +2800/+2808；占位工厂 0x141DE5F60 (malloc 0x548) |
| CFleetsBottomBarItem | 0x142A7A0F8 + tt 0x142A7A198 | [0] dtor 0x141DE6140 / tt [0] BuildTooltip 0x141DE6440 | 0x141DE59E0 | SetTarget 0x141DE6F60（项+32 CFleet idpair 快照）；提示注册器 0x140B77E10 (@+2704/+4072) |
| CSunkShipEntry | 0x142A054B0 + tt 0x142A05550 | [0] dtor 0x1417F4210 / tt [0] BuildTooltip 0x1417F6840 | 0x1417F5C50 | populate 0x1417FD790 |
| CSunkShipIcon | tt@0 0x142A046F0 / 主@8 0x142A04708 | tt [0] BuildTooltip 0x1417EA710 / 主 [0] dtor 0x1417E3200 | 0x1417E2460 | populate 0x1417EFDB0（a3 = is_sunk）；网格填充宿主 0x1417ED140 族；池工厂 0x1417F5C50 同族 |
| CNaviesViewSunkShipItem | 0x142A4F008 + @56 0x142A4F078 + @72 0x142A4F140 | @72 [0] BuildTooltip 0x141BEB240（拷 this+8 串 → item+80） | 0x141BF0140 | 三 facet 类 |
| CShipStatsView | 0x142A4F278 + @40 0x142A4F2A0 + @48 0x142A4F2B8 + @64 0x142A4F2F0 | [2] Reload 0x141BED890 / tt [0] BuildTooltip 0x141BEB270 / @48 [1] Update 0x141BEFB60 / @48 [2] populate 0x141BED870 / @64 [7] 逐帧 0x141BED5F0 | **0x141BE8C90** (dtor 体 0x141BE99D0) | 七胶水块 @+88..+7928；+6632 目标 idpair / +9216+9224 军官柄 / +9232 CButtonWrapper / +9248 CButtonObserverGlue / +10552 缓存；sizeof 0x29D0 |
| CCompactShipListView | 0x142A7EA90 | [0] const-false 0x14011D220 / [1] dtor 0x141E11AA0 | 0x141E11730 | +48 CSimpleEmptyEntryList\<CCompactShipEntry\>；sizeof 0x58 |
| CCompactShipEntry | 0x142A7E8A0 | [0] BuildTooltip 0x141E11E40 / [1] dtor 0x141E11960 | 0x141E10F30 | — |
| CNavalCombatView | 0x142A04868 + tt 0x142A04890 | [2] Reload 0x1417EA930 / tt [0] BuildTooltip 0x1417E88A0 | 0x1417E1FD0 | +2784 side=1 / +3272 side=0 (CCombatBoxGrids 嵌套 ctor 0x1417E1510)；sizeof 0xF30 |
| CNavalLossesOverview | 主 0x142A05AF0 + tt 0x142A05B18 | [0] dtor 0x1417F40B0 / [2] Reload 0x1417F7210 | — | Setup/填格 0x1417F98B0 (另 0x1417FA310)；释放 0x1417F4EE0 |
| CNavyLeaderWindow | 0x142A38158 (另 0x142A381C8 / 0x142A381E0) | [2] Reload 0x141ACD050 | 0x141ABD920 (malloc 0x1B98) | §4.31.2 簇 |
| CMoveShipsWindow | 0x142A4B338 (另 0x142A4B360) | [2] Reload 0x141BBC770 | 0x141BBAEE0 (malloc 0x5D8) | — |
| CTaskForceCompositionEditor | 0x142A800D0 (另 0x142A800E8) | — | 0x141E1FA10 (malloc 0x20B0) | 宿主 CNaviesView+22216 |
| CConfirmDisbandFleet | 0x142A9EF08 (另 0x142A9EFA0) | — | 未复核 | vt 已锚 |
| CChangeNavyLeaderDialog | 0x142A8ED50 (次 0x142A8EDE8) | — | 未移植 | 基 CDefaultConfirmationPopUpWindow; 海军将领更换确认弹窗 |
| CFexShipIcon / CDeleteShipCommand / CDisengage…Command | 0x142A04638 / 0x1429B2910 / 0x1429B07B8 | — | 命令 ctor 0x14135FEC0 / 0x1413467C0 | 见下行命令族行 |

**CNaviesView 17 胶水块回调**（块基址 = view+304 + k×1288）：

| 块基址 | 回调 | 块基址 | 回调 |
|---|---|---|---|
| +304 | 0x14180E970 | +11896 | 0x141810930 |
| +1592 | 0x141811900 | +13184 | 0x14180E250 |
| +2880 | 0x141811950 | +14472 | 0x141811250 |
| +4168 | 0x14180F6B0 (另 0x14180D2C0) | +15760 | 0x14180D4C0 |
| +5456 | 0x14180FCB0 | +17048 | 0x14180C7A0 |
| +6744 | 0x14180DB60 | +18336 | 0x141812160 |
| +8032 | 0x14180EEC0 | +19624 | 0x141810B90 |
| +9320 | 0x14180F050 | +20912 | 0x14180FCD0 |
| +10608 | 0x14180E240 | | |

**CShipStatsView 七胶水块回调**（块基址 = view+88 + k×1288；胶水块 ctor 0x141BE84B0）：

| 块基址 | 回调 | 语义 |
|---|---|---|
| +88 | 0x141BEF8C0 | 页签 |
| +1376 | 0x141BEF580 | 页签 |
| +2664 | 0x141BEF820 | 装备定义（+64 池 → +1008 def） |
| +3952 | 0x141BECFC0 | 属主资源门（country+224 ≥ 1e5×define；define 槽 dword_143332110） |
| +5344 | 0x141BECA40 | 确认锁 |
| +6640 | 0x14012A2C0 | 占位（guard_check_icall_nop） |
| +7928 | 0x141BECA70 | 删除确认链（0x1078 弹窗 + CDeleteShipCommand） |

> **刷新/内部链（1.19.3）**: CNaviesView Setup 0x141819200 / Reload 前段释放 0x141806650 /
> Reload 辅助 0x14181BB10 / UpdateButtons 0x14181D070（lambda vt 0x142A07E88/EC0/EF8）/
> ConditionallyShowManufacturerList 0x141806E40（lambda vt 0x142A07F30）；CShipStatsView
> Reload 释放旧窗 0x141BEA0D0 / 全量重建 0x141BEE020 / 观察列表重注册 0x141BEF3A0 / 军官钮刷新
> 0x141BEFF40（+10552 缓存 + ship+24 vt[1]→+32）。海战视图: Reload 重建 0x1417E4030 /
> 0x1417EB690 / 刷新主链 0x1417ED7D0 / 侧选取 0x1417E7B30 / 「两侧无玩家」门 0x1413E2B80（读 cb+218）/
> 将领面板 0x1417F0320 / 组×舰网格 0x1417ED140 (另 0x1417ECC10/0x1417EC9F0) / 两侧国 flag 面板
> 0x1417EDD40 / 侧统计窗 0x14161E9A0 / 脱离 cb 0x1417E4330 / 宿主回指访问器 0x14161A9D0。
> **命令族**: CDisengage writer (槽22) 0x14135C900（tok 10518 "combat" idpair + 10485 "attacker"
> yes/no 同值）/ CDeleteShip writer 0x14136D840（写 +40/+48 两 idpair）/ 投递 0x142250B00；
> 载荷偏移 +40/+48 不变；弹窗尺寸 0x1078 不变。**子件工厂**: CTaskForceCompositionEditor /
> CNavyTheaterFleetItem 工厂 0x141E0A810 (malloc 0x638, view+36728) / detailed_fleet_list model
> 0x141E0FD60（malloc 0x38）。**CTaskForce 存活**: +472 owner tag / +476 第二 tag / +864 mission
> 代理 / +884 任务类型枚举（BuildTooltip 内 `*(tf+884) == 点击任务 id`）全中。
> **CShip 存活**: +24 IOfficerHolder / +64 装备池 / +1008 def / +1832 tf 回指 / +2072 ship_name 块全中。


#### 4.30.18 散簇·陆战视图 (CLandCombatView / CLandCombatMapIcon / CLandLicenseEntry)

**入口链**: LandCombatView (0xAF8) target = **view+48 token 对** (SetTarget
0X1415D9A20 从 combat obj+24 holder 对拷入, resolve−16 = CLandCombat obj);
populate 链 slot2 0X1415D7E00 → 0X1415D8FB0 (建窗) / 0X1415DA220 (tactics) /
**0X1415DAE50 (数据泵)** / 0X1415D9A20 (标题+地形)。**命中册内 15 族偏移全与
§4.22 一致** (obj+24/40/48, cb+32/56/72/232/244/256/268/304/320/332/344/352/360-400)。
LandLicenseEntry = 零覆写类 (双 vt 与 CLicenseProductionEntry 全同), 仅窗口名
"request_license_land_entry" 异。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 战斗进度/宽度虚槽 | combat vt[25] / vt[26] | (虚槽, 无存储偏移) | **进度 = vt[25] / 战斗宽度 = vt[26]** (6 虚槽语义定案) | COMBAT_PROGRESS 族 | 定案 (读法) |
| 标题+地形 | 0X1415D9A20 | combat obj+40 location / +48 day | 地点+日期标题 | — | 定案 |
| BORDER_CONFLICT 判定 | (谓词) | **vt+80 == 14757 = border_war_combat** | token 表铁证 | — | 定案 |
| 参战方/将领面板 | 数据泵 0X1415DAE50 | cb+56 参战链A / cb+304 tactic / cb+232/{+244} front 列表 / cb+344 anti_air_attack / cb+352..400 统计 | §4.22 全中 | UNIT_LEADER_NO_LEADER 等 | 定案 |
| 地图图标位置/点击 | GetPosition 0X1418BC9A0 / OnClick 0X1418C3040 | 战斗省 map_obj+4688 xyz + 攻击出发省边点数组+4568 中点 + atan2 攻击方向角; unit+664 目标旗 / unit+496 所在省 (新发现) | 攻击方向角定位; 点击直开陆战视图 | — | 定案 / 新发现未决 |
| 候选新偏移 | 数据泵 | combat obj+160 / terrain def+104/+112 / cb+8 / cb+408/460 / leader name@+64 country@+288 / gs+684 | 宽度修正系数 (二进制文件 + 探针活值) / 基宽与每增向宽度 (vt[26] sub_1412ADE10 一函数三偏移直证 + 活读 forest 60/30 等) / 修饰旗位段 (值已采, 位义未决) / org_loss_summary 互证 (序列化面无书证, runtime-only) / 高置信互证 / **gs+684 更正** = 地图单例 qword_14332F408 (968B)+684 地图状态序号推定 (直读 gs+684 系串缓冲, 书证归属错误已勘) | — | 定案为主 / gs+684 推定 |


#### 4.30.19 散簇·地图模式/图标基族 (CMapIcon / CMapIconManagerImpl / CMapMode / CMapModeWithButton / MMD / MMDToOrder / CMapModeOperationSelectTarget / CMapModesInterface / CAllMapModesEntry)

业务侧字段权威 = 本节 §4.30.26 (基族全布局 + 派生散件 A/B); 本节保留视图侧索引

类布局 (类名 / target / 锚点):

CLandCombatView (0xAF8):

| 项 | 定案 |
|---|---|
| target 形态 | view+48 token 对 (SetTarget 0X1415D9A20 从 combat obj+24 holder 对拷入; resolve−16 = CLandCombat obj) |
| populate 链 | slot2 0X1415D7E00 → 0X1415D8FB0 (建窗) / 0X1415DA220 (tactics) / **0X1415DAE50 (数据泵)** / 0X1415D9A20 (标题+地形) |
| 册内偏移复核 | 视图消费与册内布局一致: obj+24 holder / +40 location / +48 day / cb+32 unit 容器 / +56 参战链A / +72 / +232/{+244} front 列表 / +256/+268 / +304 tactic (探针正名) / +320 / +332 / +344 anti_air_attack / +352/+360..+400 统计 |

新发现核验结果:

| 项 | 位置/值 | 状态 |
|---|---|---|
| 战斗宽度修正 | combat obj+160 | 高置信: 活值槽 (单样本 fixed 0.1, 探针); 语义推定宽度/战术修正 |
| 地形宽度 | terrain def+104/+112 | 字段定案 (探针活读: forest 60/30, hills 70/35, mountain 50/25, plains 70/35, 海/湖 0/0); (x, x/2) 对语义推定留文件对账 |
| 修饰旗位段 | cb+8 | **位义定案**: 侧修正图标驱动位段 — 八值枚举 {2,7,10,13,27,8,17,16 → 图标 0-7} 三处互证 (CCombatantSideModifierIconEntry populate: cb+8 位段 ∧ cb vt+248 ∧ sub_1401F6EA0(cb)+152 三源); **触发器侧双读向**: has_combat_modifier 同读 cb+8 作 BM_* 战斗修正位旗 (名表 sub_141452A20) — 同一位段两层消费 (双读向并存) |
| 强度缓冲 | cb+408/460 | 定案: 与主表 org_loss_summary 行互证 (环形 count24 ≤ num27, idx=3, 探针); 本行冗余可并 |
| leader 名/国 | leader name@+64 / country@+288 | **定案否定** : cb+304 对象 RTTI = **CCombatTactic** (+64 无名串); 下表「+304 current_leader」应正名 tactic |
| 战斗序号 | gs+684 | 定案否定 (探针: 两次读均 ASCII 串缓冲字节, 非战斗序号) |
| 虚槽语义 | vt[26] / vt[25] | vt[26] = 战斗宽度 — 定案 (sub_1412ADE10 一函数三偏移直证); vt[25] = 战斗进度 — 定案 (sub_1413E1E10: 100000×攻方份额, clamp [0,100000]; 两方皆 0 → 50000) |
| BORDER_CONFLICT 判定 | token 表 vt+80 == **14757 border_war_combat** | 定案 (铁证) |

CLandCombatMapIcon:

| 项 | 定案 |
|---|---|
| target | +1424 token 对 (管理器链路写入, 精确写点未决) |
| GetPosition 0X1418BC9A0 | 战斗省 map_obj+4688 xyz + 攻击出发省边点数组+4568 中点 + atan2 攻击方向角 |
| OnClick 0X1418C3040 | 直开陆战视图 |

map 省对象 位置/边点/可见旗 布局 + unit+664 目标旗 / unit+496 所在省 (新发现)。

CLandLicenseEntry:

| 项 | 定案 |
|---|---|
| 类形态 | 零覆写类 (双 vt 与 CLicenseProductionEntry 逐槽全同) |
| 唯一区别 | 窗口名 "request_license_land_entry" |
| tooltip | 0X141F2F090 消费 entry+2560 token (装备 HEADER / PRODUCTION_ENTRY_OUTDATED 两支) |

⚠ 排雷: CTacticsListView 族 (0X1415CE480/0X1415CEFB0) 与 view 撞 +2728/+2768 偏移但属异类 (已甄别, 复核见 4.22.8)。

view+2768/+2776 双 leader 指针写点定案 (消费侧语义已证): 两槽由**视图 ctor** 初始化 — CLandCombatView ctor `sub_1415CD790` / CNavalCombatView ctor `sub_1417E1FD0` 各自把 0..2864 区全清后写两槽; 运行时重填 = `sub_1419913F0(a1)` (由 ctor 尾调, 亦被 `sub_14198CE60` L5259057 复用)。同 0x1419913F0 内两槽成对赋值 (`v78(...)` / `v81(...)` 两 getter 调用), 与「双 leader」成对语义一致。

类布局 (类名 / target / 锚点):

view+11096 = ES (0x908B, divisiontemplatemanager.cpp 断言实名)。

| 偏移 (ES) | 类型 | 名称/语义 |
|---|---|---|
| +0 | 枚举 | 模式 |
| +4 | tag | 国家 tag (vt[20] 根窗 → CCountry) |
| +8 | CDivisionTemplateData* | `_pCurrentTemplateData` = 草稿 |
| +16 | 内嵌 0x248 | 原始快照 |
| +600 | 匿名结构 (NNB 形状) | 统计预览 ×3 之一 (与 +2280/+2288 同类) |
| +2256 | wrapper | 模板 wrapper |
| +2264 | 活数据 | 活数据 |
| +2280 | 匿名结构 (NNB 形状) | 统计预览 ×3 之二 |
| +2288 | 匿名结构 (NNB 形状) | 统计预览 ×3 之三 |

统计预览对象 = 类 0x678B (与 CArmy+312 同类); 统计数组 @对象+160 起 8B/项按 statId 索引; 统计行红绿增量 = 新预览 vs 旧预览 (DESIGNER_NO_STAT/STAT_VALUE)。保存/修改提交走 CCreate/CUpdateDivisionTemplateCommand (§4.00.6)。**「+632 = 经验差价 (三差之和)」宿主归属定案 = 命令载荷侧 cost 字段**: CCreateDivisionTemplateCommand 载荷 +40 模板数据 ("division_template") / +624 country / **+632 cost (raw)** / +640 orders_group; CUpdateDivisionTemplateCommand 载荷 **+624 模板 id ("division_template_id")** / +40 数据 / +632 country / **+640 cost (fixed5)**; Execute 0X141B9EAE0 / 0X141B9FAE0, GetTypeId 12197/12198。

类布局 (类名 / target / 锚点):

view = CCountryStateView (ctor sub_141744CB0; countrystateview.cpp 实名);
populate worker = sub_14174ECF0 (州) / sub_14174DD50 (省)。
view+1408 = CProvince*; view+1416 = *(prov+192) = CState* 回指 (§4.14 +192;
非 CState 本体)。tooltip 本体 = view+40 事件子对象 [0] sub_141747430
(线性「悬停窗口名→分支」链 19 分支); tooltip 内 a1-5 = view 本体:
a1[171] = view+1408 / a1[172] = view+1416。

三虚表:

| 虚表 | 槽 | 函数 | 语义 |
|---|---|---|---|
| view+0 主表 0x1429F82E8 | [9] | 0X14174A990 | Refresh |
| view+0 主表 0x1429F82E8 | [11] | 0X14174AA40 | SetTarget |
| view+0 主表 0x1429F82E8 | [14] | 0X14174AF00 | SetupDerived (lambda RTTI 实证) |
| view+0 主表 0x1429F82E8 | [15] | 0X141746070 | Clear |
| view+40 事件子对象 0X1429F65B8 | [0] | sub_141747430 | tooltip 巨函本体 (19 分支) |
| view+48 第二子对象 0x1429F8390 | [6] | 0X14174AA00 | — |
| view+48 第二子对象 0x1429F8390 | [9] | 0X14174C8C0 | Repopulate |

SetupDerived 四段:

| 段 | 内容 |
|---|---|
| a 行池预分配 (def 驱动) | def+700≤0 → 州行池 view+1424; def+824 图标≠0 → 省自定义图标池 view+1496; else → 省行池 view+1472; view+1448 = 共享槽行池 (容量 = dword_143334520 = UNLOCKED_SLOTS MAX) |
| b state_info_window 族 | view+1520 = state_claims / view+1528 = state_owners |
| c 容器族 | 见下表 |
| d 事件绑定 | view+1536 / view+2824 / view+40 |

容器族:

| 偏移 (view) | 名称 |
|---|---|
| +4176 | resistance_container |
| +4184 | state_resistance_status_container |
| +4192 | state_compliance_status_container |
| +4200 | law_and_template_container |
| +4208 | select_law_icon |
| +4216 | template_garrison |
| +4224 | select_law_button (事件绑 view+1536) |
| +4232 | template_garrison_button (事件绑 view+2824) |
| +4240 | template_need_text |
| +4256 | dynamic_modifiers_grid |
| +4304 | strategic_locations_grid |
| +4352 | scorched_earth_state_button |

tooltip 分支消费:

| 字段 | 消费点 | 用途 |
|---|---|---|
| CState+204 controller | tooltip 分支 | 悬停州控制国 |
| CState+616 CResistance | tooltip 分支 (select_law / template_garrison 两按钮) | 阻力/合规 |
| CState+368/+380 州建筑实例 | tooltip 分支 | 建筑修正 (实例+104 modifier; 修正 def+480 → def+528 = 名 SSO 新锚) |
| CState+24/+36 省循环 | tooltip 分支 | 省遍历 |
| country+808 人口 | tooltip 分支 (sub_140CFAD80) | 人口文本 |
| country+3944 CProductionStatus | tooltip 分支 | 产能 (energy_text 支; PRODUCTION_NO_INTEL_ON_POWER 门) |

CDynamicModifier def 布局 (CDynamicModifierItem tooltip 双发射器消费):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | 图标 gfx 键 — **活体实读 = def 名 token** (token_name 解出 arms_factory=20002 / dockyard=19446 / synthetic_refinery=20036 / air_base=12214 逐项命中) | |
| +24 | — | 过滤门字段 | *(def+24)≠0 参与过滤 (与 +8 图标 gfx 键相邻, 均为定义件字段; 活体实读 8B 形如小整数 + 串字节, 非整数门 — 语义待裁) |
| +40 | string | 名 SSO (cap@+64) | loc 键 = 名 + "_desc" 附录 |
| +248 | 内嵌 CModifier (192B) | 静态基础值段 | 判空 sub_14060CF80@def+264 pairs 容器 |
| +440 | — | 动态槽元数据表 (216B/行) | count@def+452; 行 = mdef idx, 值 = entry.values 平行数组 ×1e-5 |

CDynamicModifierItem / BigItem / SmallItem: target = item+32 内嵌
SDynamicModifierEntry 64B 拷贝 (tag/state/days/def/enabled/values 逐字段命中
§4.13.4 布局 6/6); Big/Small 零自身覆写, 差异 = 窗模板
"spirit_modifier_entry"/"_small" + item+100 旗 (flagtextureatlas.h 铁证);
过滤 = enabled ∧ *(def+24)≠0; tooltip = 双发射器 sub_14055D670 (主描述) +
sub_1405597F0 ("_desc" 附录); 剩余天数 loc WILL_BE_REMOVED; 宿主两 ICF 巨函
sub_140E87390 (政治/理念视图推定) / sub_140A79410 (外交/国家详情推定) 迭代
CCountry+3712 {count@+3724} 64B 步进容器。

modifier id 定名 (高置信 — 注册连号+持有者对型双推):

| 值 | 名称 | 语义 |
|---|---|---|
| 161 | MODIFIER_GLOBAL_BUILDING_SLOTS | 共享槽公式项 (注册点直证: edx=161, 串 0x1427D8908) |
| 162 | MODIFIER_GLOBAL_BUILDING_SLOTS_FACTOR | 同上 (注册点直证) |
| 163 | MODIFIER_LOCAL_BUILDING_SLOTS | 同上 (注册点直证) |
| 164 | MODIFIER_LOCAL_BUILDING_SLOTS_FACTOR | 同上 (注册点直证) |
| 547 | MODIFIER_STATE_RESOURCES_FACTOR | 资源折减 (注册点直证: 串 0x1427D8998) |

共享槽公式 = clamp(st+2136 extra + (161+163)×(162+164+1.0)/1e5, 0,
dword_143334520)。CCountry+1448 = 国 modifier 内联对象 holder (161/162 查询,
定案); CCountry+4600 内 = 每州资源因子缓存 (sub_140CAE3F0 按州查: infra factor
sub_140CAD400 / supply factor sub_140CB48C0;
RESOURCE_INFRA/SUPPLY_FACTOR_TOOLTIP "MULT")。
完整 GUI 数值映射 = §4.30。

**CStateStakeholderItem / CStateStrategicResourceItem (州面板行件, GUI)**: 宿主 = CCountryStateView populate sub_14174ECF0 ✓。CStateStakeholderItem: **kind 枚举定案 — 0 = 核心 (st+176 ✓) / 1 = 宣称 (st+152 ✓) / 2 = 属主 (st+200 ✓) / 3 = 争夺 (st+208 ✓)**; 元素 = 国旗+细/粗边框+惊叹号。CStateStrategicResourceItem: item+32 = CState\* / +40 = 资源 def / +48 = 量; **资源 def+220 = 图标 frame** (第三处消费互证, §4.31.33/§4.31.47 同源); tooltip 走 st+204→cc+4600 每州因子缓存 ✓; loc STATE_FOREIGN_RESOURCE_OWNER。

**CTemplateEntry (正名纠偏 = CBuildingsNudger 的建筑模板行, 非师模板)**: feed = **建筑库 qword_14332EE28 ✓** (滤 **def+20>0 且 def+84==357**) + null 末条; def 名 = \*(def+8) token (lexer 铁证); 副表槽9 = 选中高亮。
(入口链/模式条目/命令出口) + §4.30.38 (CMapModeManager 布局补全);
两部署模式类与 §4.18 互证 (ConveyorView+6800/+6816 scoped_ref
内嵌同族)。视图侧骨架: 激活流 sub_1417CAB50 = [1]CanActivate→mode+40=目标
省→[3]Commit; 取消 glue sub_1417CAB20 = +40 非空→[4]Cancel→清; 命令出口 =
qword_14332F6A0 vt+136 命令队列。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 图标基类 21 槽 | 槽表全定名 | icon+8 名/+16 子精灵/+48 目标/+56 client/+108 层号/+116 旗 | +1424/+5985/+4688 = 派生区非基类 (复核) | — | 定案 |
| 图标管理器 | factory sub_140B71AF0 | **单例 qword_14333C5A8**; +8/+824 双 34 层数组 / +1840 精灵工厂 | mapiconmanagerimpl.cpp 实名; 调试层过滤 dword_143086368 | "mapicons_container" | 定案 |
| 部署选址模式 20 | [3]Commit 0X141F6BE40 | mode+1344=conveyor; 投 CSetConveyorLocationCommand(conveyor, **prov+164**) | prov+392 controller/+192→CState 州名全按 §4.14 消费 | CONVEYOR_ASSIGN_LOCATION_SELECT_{HOME_}AREA | 定案 |
| 部署指派模式 21 | [3]Commit 0X141DF3D20 | 投 CSetConveyorGroupCommand; order 源=*(qword_14332F6A0 vt+200 对象+464) | **qword_14338C790 = 当前 hover 选中** ([11]写[10]清) | CONVEYOR_ASSIGN_ORDER_SELECT_AREA | 定案 |
| 行动目标择模式 29 | [1]CanSelect 0X141E339C0 | +1344 候选/+1368 窗/+1376 上下文/+1388 实现选择子 | prov+392→CState+88 州 id; [10]/[11] CState+20 字节旗; mapmodeoperationselecttarget.cpp:103 实名 | SELECT_STATE_ON_CLICK{,_DISABLED} | 定案 |
| 可配置模式条目 | OnClick sub_141575470 | entry+1360=mode id/+1368=父; **宿主+11712 起 11 槽 mode id 数组** | 件型 "ConfigurableMapMode"; custom 旗走 scripted 激活 | — | 高置信 |

**定案 8 项 + 推定 1 项**: icon+40 = **组槽/延迟解析缓存双态** (CCapitalMapIcon 派生 = CMapIconGroup\* 反查缓存 sub_140B72CA0; CVictoryPointMapIcon/CStrategicLocationMapIcon 派生 = 省对象缓存 sub_1418CE0D0) / 槽[3] = **UpdateAndRealize** (层可见性 sub_1418BBB30 LUT + sub_140FA61D0 写 +112 + 定位 sub_14163FAF0 + 派生 populate 三合一) / 槽[9] = **图标类型数哨兵 18** (基类 sub_14163F4E0 返 18; **族内三值 1/10/18** — CVictoryPointMapIcon/CCapitalMapIcon/CAdjacencyRuleIcon 返 10) / 双 34 层表: **+8 = Reload 重建集** (vt[2] sub_140B73CF0 只遍历 +8) / **+824 = 活性图标表** (vt[4] Update 扩容易地 + 工厂 sub_140B729B0 push) / Group+40 = **CMapIconGroup 图标 CVector** {data@40, cap@48, count@52, alloc@56} / OpST+1388 = **实现选择子模式枚举** (写点 = 工厂 sub_141828D50; 0 = 内嵌候选表命中门, 1 = 按实现逐条, 其它断言 mapmodeoperationselecttarget.cpp:103) / 调试命令 = **`map_icon_reload_type`** (参数 NUM; 无参 = 清 −1 全层重载; 体 sub_140284980 写层过滤全局 dword_143086368) / MMD[10][11] = **目标图标抑制/恢复对** (CMapModeMilitaryDeployment vt 0x142A72268: [10] sub_141F6BB30 写 +20=0 / [11] sub_141F6BC80 写 +20=1; MMDToOrder vt 0x142A722D0: [10] sub_141DF3C30 清 qword_14338C790 / [11] sub_141DF3C60 写 = sub_140CE9E00(*(a1+1344))) / CForceUpdateMapMode = **slot[13] Execute = sub_1403575C0** (vt 0x14277AB90; [5]/[14] = CEffect 族默认桩)。
**推定 1 项**: OpST+1376 = **上下文/触发器载体指针** (读 `*(ctx+944)` CAndTrigger vt+24 求值; **无独立 RTTI — 负定案**)。

#### 4.30.20 散簇·脚本化 UI (CScriptedWindowTemplate / CScriptedWindow / CScriptedWindowManager / CScriptedWindowDatabase / CScriptedMapMode / CScriptedMapModeLayer / CScriptedMapModeDatabase / CScriptedMapIcon / CScriptedGUIDiplomacyPopup + 辅助 CScriptedWindowGUIUpdater)

**文件层**: common/scripted_guis → CScriptedWindowDatabase::LoadFile 0X140AB9950
(顶 key scripted_gui → 每子键 new CScriptedWindowTemplate, ReadKey 0X14159ECB0);
common/map_modes → CScriptedMapModeDatabase::LoadFile 0X140AAF740 (顶 key
scripted_map_modes → db 槽位原位构造 CScriptedMapMode)。**template def 文法
21 key 全落偏移** (ReadKey 逐 case + token 反查): context_type+40 (8 值白名单:
national_focus/player/selected_state/selected_country/decision_category/
diplomacy_target/state_mapicon/country_mapicon) / parent_window_token+44 /
window_name+48 / parent_window_name+80 / parent_scripted_gui+112 /
visible+144 CTrigger / effects+232 map→CEffect / triggers+296 map→CTrigger /
properties+360 map→SPropertyInfo(自有 vftable) / dynamic_lists+424 map→
SDynamicListInfo (0x3C8 条, 构造 malloc+插 sub_14159D2C0; **尾域 +944 数组/+956 count**
由 PostLoad 逐条 sub_140AB9430 解析) / ai 块 +552..+1336 (ai_enabled+1032/ai_check+1120/ai_weights
+1296; +1052 = ai 启用门) / dirty+1328 / **mapicon_targets+1536** (mapicon 两态
时创建 CPersistentScriptTargets 0x108B, state→+256 flag=1/country→=0) /
mapmode+1544 ("MAPMODE_"+值)。**slot8 PostLoad 0X14159DEF0**: 对 _click/_shift/
_alt/_control/_right 尾缀派生查 `<名>_click_enabled`/`_visible` 绑入触发表 —
按钮 effect 自动可见性 trigger 的绑定点。
**运行层**: CScriptedWindowManager (ctor 0X140B85530, "common/scripted_guis"
watcher 热重载回调 0X140B87EA0): **slot7 Update 0X140B88DC0** (revision 侦脏 →
逐窗 sub_140B88950); +32 窗口数组 / +1272 CGuiSystem。CScriptedWindow (0xB90B):
+48 root scope 恒 player country / +232 template / +248 实例窗 / +264 父
CScriptedWindow / **+272 内嵌 CScriptedWindowGUIUpdater (0xA68B)** / +1232 主
scope (=updater+960) / **+2936 父可见缓存 / +2937 计算可见 (= 父可见 ∧ ai 门
sub_140B883C0 ∧ 视图检查 ∧ template+164 门→template+144 trigger vt+24 @scope a1+1232) /
+2938 强制 dirty** (Update sub_140B88950: +2938 先清, +2936 比对置位或置 1; dirty 比
+2944/+2952)。Reload 父窗三级解析
(token hash → parent_scripted_gui 名扫 → parent_window_name 按名 RTDynamicCast;
scriptedwindowmanager.cpp:429/435/448 实名); 实例化名 = `<window_name>_instance`。
**BuildScope sub_140B8D1E0 = 游戏对象真实消费点**: player_context→gs+1312/
1316; selected_state→选择集 (manager+1336 type==4→+184); diplomacy_target→
ledger 四窗 view+17664 / occupation 视图 +5352→+5456 二级; 种子 = CCountry
+544/+548 FNV 混合写 scope+16(random1) 后 +12(random2) (**写序反, 与 §4.3
§CEventScope 逐位互证**)。decision_category/mapicon 两态走父窗继承 (未决)。
**地图模式层**: CScriptedMapMode 内嵌双 layer (+8 top/+120 bottom) +
far/near_text+264/+268 五值枚举 (none/country/state/faction/player);
CScriptedMapModeLayer: color+24 / type+8 **十值枚举全回收** (none/country/
state/state_controller/game_map_mode_country/states/diplomacy/players/
factions/ideology); type∈{state,state_controller,ideology} → 建
CPersistentScriptTargets (+16, flag+256=1)。**CScriptedMapIcon** (图标类型 25,
工厂 sub_140B71B50 case 25, 容器 "scripted_map_icon_container"): slot4 双文本
链 (country 经+164→+5024 串 / state 经目标+88→+112 串, 归属推定); slot2 可见
门 (对象+124 byte); sub_14190BDD0 绑定 → **全局注册表 qword_14338B308**;
+336 过期哨兵 92233720200000。**CScriptedGUIDiplomacyPopup** (窗
diplomacy_scripted_popup_window): slot11 Init 0x141754d60 建独立 updater
@+4264 并绑 template (行动 vt+408); slot1 Update 双 country scope (+4064/4068
FROM/TO → v7+24/+32) + 种子哈希; 显隐 = +4072 vt+648/656; 五 widget 名定案
(bottom_container/accept_button/decline_button/title/scripted_gui_container)。
**辅助 CScriptedWindowGUIUpdater** (无 RTTI 项, vftable 串定案, ctor
0X140B851A0): +32 template / +960 scope / +972/976 random2/random1 / +984 root;
窗口+272 内嵌与弹窗+4264 独立两形态经 ±272 换算逐位互证。应用器
sub_140B8AD20 (26.7KB 巨函未展开, 未决)。未决 7 项。

#### 4.30.21 州面板余量 (CCountryStateView 三虚表 / tooltip 巨函 19 分支 / SetupDerived+Clear / gs+992 铁路图 / 163-164 键 / 同原初国谓词)

业务侧: 州面板+modifier 哈希+资源形态见 §4.13; 铁路图 CProvinceRailwayInfo+
prov+200 天气 id 见 §4.14; m_OriginalTag/gs+832 恒等表/每州资源因子缓存见
§4.3。+4216 = template_garrison。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| tooltip 巨函 | = **view+40 事件子对象 vt[0]** sub_141747430 | 19 分支线性分派; a1[171]=view+1408 prov / a1[172]=view+1416 state | countrystateview.cpp 实名; 新消费点 CState+436/+448/+460/prov+200/cc+808/cc+3944 | STATE_NO_RESOURCES / STATE_CONTROLLER / STATE_POPULATION_DESC 等 | 定案 |
| SetupDerived / Clear | vt[14] 0X14174AF00 / vt[15] 0X141746070 | 三行池 def 驱动 (def+700/def+824) + 共享槽池+1448 (dword_143334520) + 容器族 +4176..+4352 | lambda RTTI 实证; Clear = 5 列表清+4 池回收+2 grid | — | 定案 |
| 铁路图 | sub_1414E3210 assert | **gs+992 = {+8: CProvinceRailwayInfo\*[] 按省 id}**; 条目 +24/+32/+44/+56/+68/+104/+472 | supply_system_utils.cpp:0x31C 铁证 | — | 定案 |
| 省情报字节纹理 | **CInGameIdler vt[120]** → CGraphicalMap (= *(app+880)) → +1776 | **+1776 每省情报/可见度字节纹理对象** (64B, 无独立 RTTI 类 — 负定案; {+0 每省字节表, +8 第二表, +16 i32 省数 (按 gs+700 分配), +24/25/26 三旗, +27 = byte_14332F63A 快照, +48 allocator, +56 纹理像素缓冲}; 惰性建 sub_140B55770 → sub_1416181B0) | 0-100%; 已定位消费点判据 = `<150` 且门 = 战争迷雾总开关 byte_14332F63A (pdxmaptexturegeneration.cpp); 另有一路消费点判据为 `<50` (未定位) | — | 定案 (类/形状) / 待裁 (阈值两说) |
| 163/164 键 | sub_1409D4980 共享槽公式 | **modifier 索引非 lexer**: 161/162=global_building_slots(_factor) / 163/164=local_… | 注册连号+持有者对型双推; CState+2256 每国州级 modifier 哈希 (208B 桶) | — | 高置信 |
| 同原初国谓词 | sub_140BB52F0/140BA6240 | **gs+832 = original-tag 恒等表**; **cc+4876 = m_OriginalTag** | 三证定案; 3146 处调用 | — | 定案 |

**定案 4 项**: +1776 阈值两说**非矛盾** — `<50` 那一路 = **自定义建筑图标隐藏门** (sub_141746E50 内 `state_name` 窗分支, 门 byte_14332EC69 && a1[172] → sub_1409D8C10), `<150` 那一路 = **战争迷雾总开关门** (byte_14332F63A) / 铁路 +104 = **`cooldown` u32 单标量 (tok 14622)** — **无位段** (writer sub_140E95DD0 直证); 阻断语义由 **+80 块 `rail_way_construction` 非空** 表达 (施工中 = 阻断) / modifier 161-164/547 **1.19.3 离线直证**: 161 = MODIFIER_GLOBAL_BUILDING_SLOTS / 162 = …_FACTOR / 163 = MODIFIER_LOCAL_BUILDING_SLOTS / 164 = …_FACTOR / 547 = MODIFIER_STATE_RESOURCES_FACTOR / `sub_141746E50(view,out,flag)` = **共享槽计数 tooltip 组装器** (窗名 `shared_slot_count`; UNLOCKED_SLOTS + 全局兜底 dword_143334520) ; `sub_1409D8C10(state,out)` = **每国州级 modifier 明细串组装器** (state+1368 主值 + 遍历 state+2256 每国 modifier RH 表 (208B 元, +8 tag, +32 CModifier) 逐条追加)。

#### 4.30.22 和会竞标 (SetBiddingsIn 链 / 三行池身份 / country 行 +1336/+1340 / conf 四容器改判 / actor=MainLoser / +520 竞标方 tag)

conf 字段定案 (全布局表见 §4.10.26):

| 项 | 结论 | 证据 |
|---|---|---|
| conf+52 / conf+56 | MainLoser / MainWinner | writer |
| conf+96 / conf+120 | OutWinners / OutLosers u32 tag 数组 | writer |
| conf+416 | CPdxArray\<scoped\<CPeaceAction\>\> | writer |
| conf+440 | 竞价覆盖 map | writer |
| conf+520 | 当前竞标方 tag | writer |
| conf+552 / +568 / +584 | RB-tree×3 | writer |

视图侧: **SetBiddingsIn lambda
体 = 独立函数非合并块** — SetBiddingsInWinnerItem = sub_141868380 /
SetBiddingsInBeneficiaryItem = sub_141865250 (w6 sub_141867A20 逐参与者
调用); 链 = 行取建 → sub_14185F450 收动作/回合 (conf+504 历史树) →
lambda 过滤 (winner 恒真 ICF 折叠; **beneficiary = sub_1418688F0 实谓词:
行动方 tag==行+1320 && action+8 类型==行+1352 && action+56 目标∈行+1328**)
→ sub_141858A30/1418452E0 入行动作表 → 行 Update 字段。**三行池身份定案
(ctor vftable 符号+清理函数结构对拍双证)**: **+20656 = CPeaceWinnerBiddingsItem
(ctor 0X141E4B890, vt 0X142A81928, 0x1560B) / +20680 = CPeaceBeneficiaryBiddingsItem
(0X141E49AD0, 0X142A81AC8, 0x5F0B) / +20704 = CPeaceAggregatedAvailableActionItem
(0X141E45970, 0X142A813A8, 0x618B)**; 层级 = winner→agg action→country→
CPeaceBiddingItem/QuickAccess 孙行。**country 行 ctor 实参: +1336 =
行动类型 token 组键** (源自 CPeaceAction+8, sub_1419E6B30 译 GFX 图标名);
**+1340 = 国 tag**; FillActions = sub_141E4D740 (展开时逐动作建
CPeaceBiddingItem 行 + CStatePeaceAction+76..79 四叠加旗分 12531-12534 组
建 QuickAccess 勾选行, lambda 写 country+1320 map 勾选态)。winners 条目
UI 字段: +8 tag→旗/名 / +76 当前分→score 文本。未决 8 项: GetWinner
ICF 别名 / +568/+584 语义 / 五谓词内部等。

#### 4.30.23 科技面板设施页签 (CFacilitiesTabView 五合一; 国策 def 侧见 §4.3.15)

业务侧: CFacilitiesTabView 全布局见 §4.7。

类布局 (类名 / target / 锚点):

科技面板设施页签 (win+4288, 0xB98, 三 vt @+0/+16/+56, 窗 facilities_view) —
定案 = 0xB98 五合一容器:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +128 | CScientistRoster | 科学家名册 | |
| +136 | CScientistHistoryRoster (0x650B) | 历史名册 | 与 +144 系**两独立分配** (非一槽两用) |
| +144 | CScientistSimpleRoster (0x658B) | 简一名册 | 同上 |
| +152 | CProgramList | 程序列表 | |
| +2896 | CProgramView | 程序弹窗 | |

行取数主链 (流程): cc+4008 program_status → **+32 {c@44} 程序引用表** →
CProgramItem (0x2C78B) 行; roster 行引 P+16 链 (§4.31.6)。
⚠ ResearchFacility 变体实证在 NFactions FactionView 不在本类; cc+4016 在
本页签函数群零引用。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 设施页签五合一 | CProgramList::Populate | **+128 ScientistRoster / +136 HistoryRoster / +144 SimpleRoster / +152 CProgramList / +2896 CProgramView 弹窗** | 行链 = cc+4008→+32{c@44}→CProgramItem 0x2C78; ⚠ +136/144 两独立分配; cc+4016 零引用 | facilities_view / program_window | 定案 |

> **国策 def 侧布局**: 见 §4.3.15 (CNationalFocus def 全字段 / CJointNationalFocus /
> CNationalFocusTree / CFocusInlayWindow def+Instance / 旗簇死门); CFocusStatus
> fp 锚 (fp+88 完成图 / fp+120 候选缓存 / fp+144 originator) 见 §4.3.14。


#### 4.30.24 宿主待归杂项 (推定)

| 项 | 布局 | 备注 |
|---|---|---|
| 地图模式对象 +232 | MSVC 串 | 地图模式名串; 模式库访问器 sub_14039E240() {数组 @+40, 计 @+52} |
| 接口处理器历史容器 | {data@+1192, cap@+1200, count@+1204, alloc@+1208} | 元素 216B {tag@+0, 类别 u8@+208}; 宿主对象未名 |
| 合同交付状态对象 | 分子 +472/+512; 分母 +24/+232; 惰性旗 +504/+216 | 国际市场合同交付状态; 宿主待归 (候选并 §4.23.3) |

#### 4.30.25 游戏内屏面三件 (时钟 / 设置屏 / 小地图)

| 类 | vt / 基链 | 布局与行为 |
|---|---|---|
| CInGameClock (152B; 顶栏真实挂钟, 窗名 "clock_window") | 主表 4 槽 + CInGameUpdateableInterface@40 十槽 ([1..6] updateableinterface.cpp 默认桩, 仅覆写 [7] tick) | tick = localtime64 → "%R" 格式写窗文本; 显隐门 = 设置单例 +909 字节; 激活 = 游戏内 GUI 大工厂 sub_140B614C0 |
| CIngameSettingsScreen (2648B; 游戏内设置屏, reload 名 "menu_settings_ingame") | CReloadableInterface/CReloadDispatcher@0 + CTooltipHandler@40 | ctor 12 段 CLegacyButtonObserverGlue 按钮胶水 (邻串 ApplyButton) |
| CMinimapInterface (5424B; 小地图界面, "mini_map_interface") | 双副表 @40 tooltip / @48 updateable (覆写旗检 + 浮点相机两槽) | 与时钟同厂 (sub_140B614C0) 同宿主挂载 |

三件均非 CPersistent 零存档面 (serfam 全无记录); 定案/高置信。

#### 4.30.26 地图图标/模式基族 (CMapIcon / CMapIconManagerImpl / CMapIconGroup / CMapIconLayer / CMapMode)

CMapIcon 基类: vt 0x1429E6AB0, 21 槽, 128B; ctor sub_14163F310(名, 层号, client)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | — | 精灵名 | | |
| +16 | — | 子精灵 GUI 对象 | | Realize 槽[8] 经管理器 +1840 工厂 sub_1422B8BC0 按名建 |
| +24 | CMapIconGroup* | group | | |
| +36 | float | 创建序 | | 同层排序键 |
| +48 | — | 目标对象 | | 指针, 派生自定; ClearTarget 槽[7] 清 |
| +56 | CMapIconClient* | client | | SetActive 注册/注销 |
| +64 | — | 屏幕坐标 | | 与 +68 成对 |
| +68 | — | 屏幕坐标 | | 与 +64 成对 |
| +72 | float3 | 世界坐标缓存 | | |
| +108 | — | 层号 (**兼作 icon type**: 值 == 工厂 case 号 == 层号; mapicon.h:189 断言 "eType < MAP_ICON_TYPES_COUNT") | | 0-33; 管理器 34 层数组下标 (= 工厂 case id, §4.30.27 映射表) |
| +112 | u32 | **层可见性缓存** | | 所有派生 slot3 统一调 sub_1418BBB30 (层 LUT xmmword_143371A90[类型]) → sub_140FA61D0 直写本字段 |
| +116 | — | 旗 | | bit0 = active, bit3 = SetX |

CMapIcon 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | 矩形测试 |
| [2] | IsVisible | 派生加迷雾谓词 |
| [3] | **帧级 Update/populate 分发** (定案) | 派生覆写同形态: type LUT xmmword_143371A90[+108] → sub_140FA61D0 + 基 + 派生 populate |
| [4] | GetPosition | 纯虚 |
| [7] | ClearTarget | 清 +48 目标 |
| [8] | Realize | 经管理器 +1840 工厂按名建子精灵 |
| [13] | — | 宽分发 |
| [14] | — | 高分发 |

注: +1424 token / +5985 迷雾 / +4688 xyz 属派生扩展区/省地图对象, 非基类字段。

CMapIconManagerImpl: vt 0x14294BE40 (COL 0x142CCB748), 6 槽, 0x7A0; 基链 = 接口+Base+CReloadDispatcher,
模板基 CMapIconManager\<34\> (vt 0x14294BE08); 单例 qword_14333C5A8 (factory sub_140B71AF0 =
malloc(0x7A0) → ctor sub_140B712C0; 初始化点 = gameapplication.cpp:1660 日志串
"InitGame:: CMapIconManagerImpl takes "; mapiconmanagerimpl.cpp 实名);
调试层过滤全局 dword_143086368 (−1 = 全层)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | CVector[34] | 层表 ① | | Reload 验证集 (推定) |
| +824 | CVector[34] | 层表 ② | | 活性图标表 (定案) |
| +1776 | 匿名结构 (元素待裁) 向量 | 并行任务数组 | | |
| +1832 | — | 容器名串 | | "mapicons_container" |
| +1840 | — | 精灵工厂 | | = sub_1422B8BC0 |

CMapIconManagerImpl 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [2] | Reload | 全层 Realize |
| [4] | Update | 11165 行 ICF 巨函, 禁逐行 |
| [5] | ClearAll | |

CMapIconGroup: +32 = 当前图标; +40 = 图标 CVector。Update LOD 0-3 距离三 define =
MAP_ICONS_GROUP_CAM_DISTANCE / MAP_ICONS_STATE_GROUP_CAM_DISTANCE /
MAP_ICONS_STRATEGIC_GROUP_CAM_DISTANCE (均 /100000.0 vs 相机+404)。

CMapIconLayer: 双 CVector; +64 = 层号。

CMapMode 基类: vt 0X142A01160, 10 槽。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | — | mode id | | |
| +40 | CProvince* | 当前目标 | | |

激活流 sub_1417CAB50: [1]CanActivate → +40 = a2 → [3]Commit; 取消 glue
sub_1417CAB20: +40 非空 → [4]Cancel → 清。dtor 自动向管理器注销。

CMapMode 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | CanActivate | 纯虚 |
| [3] | Commit | 纯虚 |
| [4] | Cancel | 纯虚 |
| [5] | Update | 重着色, 纯虚 |
| [9] | GetInfo | 出参 3×std::string |

CMapModeWithButton (12 槽):

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +48 | — | 按钮 glue | | OnClick sub_1417CAA40 = 管理器切 mode |
| +1336 | CGuiObject* | 宿主 | | |

CMapModeWithButton 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [10] | 目标图标恢复 | 对象+20 字节 0/1 |
| [11] | 目标图标抑制 | 对象+20 字节 0/1 |

mode id 增补 (映射表):

| 值 | 名称 | 语义 |
|---|---|---|
| 20 | CMapModeMilitaryDeployment | +1344 = conveyor; Commit 投 CSetConveyorLocationCommand(conveyor, prov+164); GetInfo 读 prov+392 controller / prov+192 → CState 州名; loc CONVEYOR_ASSIGN_LOCATION_SELECT_{HOME_}AREA; 0x558B scoped_ref 内嵌 ConveyorView+6800/+6816 (子对象+1360 = conveyor), [4] Refresh 0X141D87950 激活时退出选址/指派 |
| 21 | …ToOrder | 投 CSetConveyorGroupCommand; order 源 = *(qword_14332F6A0 vt+200 对象+464); qword_14338C790 = 当前 hover 选中 |
| 29 | CMapModeOperationSelectTarget | +1344 = 候选 CVector / +1368 = 窗 / +1376 = 上下文 / +1388 = 实现选择子; mapmodeoperationselecttarget.cpp:103 实名; loc SELECT_STATE_ON_CLICK{,_DISABLED}; 槽[10]/[11] 经 prov+192 CState+20 字节旗 |

上述三省模式 (20/21/29) 的 click/GetInfo 路径把 prov+164/+192/+392 全按 §4.14 语义消费。

CAllMapModesEntry: +1360 = mode id; +1368 = 父 interface。宿主对象 +11712 起
11×dword = 可配置 map mode 槽 id 数组 (槽 idx = 父+64 ≤ 10, 点击去重写槽;
custom 旗 +68 走 scripted 激活 sub_140A66DE0)。

邻近族:

| 类 | 说明 |
|---|---|
| CScriptedMapMode | TGameItemDatabase 项族, 槽[4] = token loader |
| CCustomMapMode | 同上 |
| CNullCustomMapMode | 同上 |
| CForceUpdateMapMode | 派生自 CEffect; force_update_mapmode 效果; factory sub_14033E4A0 (0xD0B) |

#### 4.30.27 地图图标派生族散件 A (CCapitalMapIcon / CVictoryPointMapIcon / CRadarMapIcon / CResourceMapIcon / CResourceMapIconItem / CStrategicLocationMapIcon / CSupplyNodeMapIcon / CResistanceComplianceMapIcon)

**图标工厂 sub_140B71B50 case↔类映射 (类型 id == 层号)**: 2 = CVictoryPointMapIcon / 3 = CResourceMapIcon / 8 = CNavalBaseMapIcon / 14 = CCapitalMapIcon / 17 = CRadarMapIcon / 20 = CResistanceComplianceMapIcon / 25 = CScriptedMapIcon / 26 = CSupplyNodeMapIcon / 29 = (mode 29 邻域, 见 §4.30.19) / 31 = CNavalHeadquarterMapIcon / 33 = CStrategicLocationMapIcon。**CTooltipHandler 副虚表 = 2 槽**: [0] = GetTooltip 真入口, [1] = 转发 dtor (a1−128)。**州地图对象** (sub_140B552A0): +112/+120 位置 / +124 可见 byte; **省地图对象** (sub_140B53EE0): +5024/+5032 位置 / +5985 迷雾 / +4796/+4808 补给锚对 / +5448 建筑 gfx 句柄表 — 两者均无 RTTI 名。

| 类 (类型 id) | target 形态 | 锚点 |
|---|---|---|
| CCapitalMapIcon (14, 216B) | **+152 CState\* + +160 首都省 CRef** (\*(\*+160)+164 = 省 id ✓); +172 模式旗切换州锚/省锚 | populate 用省+56 VP 名或州名; SetFrame 归属着色 (自=3/友=1/外=5/远焦=2) |
| CVictoryPointMapIcon (2, 192B) | **+152 CProvince\*** | 帧 = 归属 (**省+392 controller ✓**) + VP 档位 (**省+56 victory_points ✓** 对阈值表 **qword_143338A70**, frame = v31 + 5×(档数−档)); 大 VP 远焦仍可见 |
| CRadarMapIcon (17, 152B) | **+136 裸省 id** | 存在谓词 = 省→州→控制国 **CRadarsPool (cc+4344 ✓)** 内有该州雷达; 位置锚在建筑精灵 (CBuildingDatabase ✓ 匹配省地图对象+5448 gfx 句柄表); tooltip = RADAR_ONMAP_TOOLTIP/_DAMAGED (站+88 等级 vs 最大) |
| CResourceMapIcon (3, 224B; **唯一无 CTooltipHandler**) | **+128 CState\***; **+152 复合容器块 (+160 i64 数量数组按资源 def+216−1 索引 ✓§4.13.6)** | 近焦才显 (dword_1433342A0); 遍历 strategic_resource 库 (0x332f088 ✓§4.26) 填 "resources_list" |
| CResourceMapIconItem (88B; **非 CMapIcon** — CStandardlistboxItem 派生, 副 facet @+56) | "desc"(+72) = 资源名 / "flag"(+80) = 数量 | 由宿主 populate 直灌 |
| CStrategicLocationMapIcon (33, 176B) | **+136 = 省 id** (= **st+2048 strategic locations 对第二 u32 ✓§4.13**) | +144 名串拼 "GFX_strategic_location_*" 经 vt+728 SetGfx 上 "bg_btn"(+168); tooltip = STRATEGIC_LOCATION_MAPICON + 省名 |
| CSupplyNodeMapIcon (26, 6712B 巨图标; 窗名 supply_node_map_icon; ctor sub_14190DF80; 主 vt 0x142A1A250 / 副 vt 0x142A1A300 (主表+176)) | **+6576 CProvince\*; +6584 节点变体旗 (ctor 初值 0x10000, 低字节) / +6585 / +6586 byte; 子元素群 +6592..+6701 + +6704=5 / +6708=4** | 5×1288B 事件回调束 (+136/+1424/+2712/+4000/+5288, 束安装器 sub_14190D7A0, 11 回调) 配五按钮; **tooltip 五键全定名: SUPPLY_NODE_MOVE_CAPITAL / UPGRADE_TO_CAPITAL / TOGGLE_ALLIES / MOTORIZATION_PRIORITY / SUPPLY_FLOW_SHOW_RANGE**; **悬停元素四路分派**: +6632→MOVE_CAPITAL / +6680→TOGGLE_ALLIES / +6688→UPGRADE_TO_CAPITAL / +6696→MOTORIZATION_PRIORITY+FLOW_SHOW_RANGE (GetTooltip sub_14190EAB0; 元素 = icon+128); 点击经 qword_14332F6A0 → sub_140A66AE0 控制器三方法 sub_1419B0E90 (prov+164, flag) / sub_1419B10B0 (prov+164, flag) / sub_1419B0B70 (prov+164), 非裸 CCommand; 槽: [2] IsVisible sub_14190EF40 (prov+192→st+88→sub_140B552A0→+124) / [3] 层门+populate sub_141912AB0 (层@+108; populate = sub_1419107D0) / [4] GetPosition sub_14190E7B0 (节点槽查询 sub_1414E2AF0; 控制国→gs+984→+264 槽表 232B 元: 槽+13 flag, 槽+8==3→+4796 否则 +4808; 兜底 defines dword_143333410/414/418) / [7] ClearTarget sub_14190F370 / [8] Realize sub_141912000 / [10] sub_141908CB0 (与 resistance 共享, 推定) |
| CResistanceComplianceMapIcon (20, 208B; resistancemapicons.cpp 实名) | **+136 CState\*** | populate 仅 map mode 6/7; 数据源 = **st+616 CResistance ✓ (cr+528/+552 双修正名单 ✓§4.13.1 + sub_140F99CF0 占领状态对)**; 内嵌 CGenericEmptyEntryList\<ModifierEntry\>@+168 逐修正建行 |

#### 4.30.28 地图图标派生族散件 B (CCryptologyMapIcon / CIntelLedgerMapIcon / CIntelLedgerResourceEntry / CConstructionInfoMapIcon / CStateModifierMapIcon / CAdjacencyRuleIcon / CPeaceMapIcon / CCounterintelligenceMapIconEntry)

**地图对象双查表定案** (管理器 qword_14332F698): **vt+120 → sub_140B552A0 = 州地图对象** (pos float3@+112/+120, 迷雾字节@+124); **vt+128 → sub_140B53EE0 = 省地图对象族** (pos float3@+4568 或 float2@+5024, **迷雾旗 @+5985 bit1** — 双证定案)。工厂 case 补: 4 = CConstructionInfoMapIcon / 15 = CPeaceMapIcon / 16 = CAdjacencyRuleIcon / 22 = CIntelLedgerMapIcon / 23 = CIntelLedgerMapRegionIcon / 24 = CCryptologyMapIcon / 28 = CStateModifierMapIcon。

| 类 (类型 id) | target 形态 | 锚点 |
|---|---|---|
| CCryptologyMapIcon (24, 0xAC8B) | **国 tag@+2756** | 四子件 decrytion_bar/state_icon/large_flag/percent @+2712..+2736; 位置 = 目标国首都省 (**cc+4120 ✓**); 槽[6] = **owned_states (cc+1156 ✓)** ≤0 门; 点击投 **CStartStopDecryptionCommand / CActivateActiveDecryptionBonuses**; tooltip 全 8 个 CRYPTO_* loc 定案 |
| CIntelLedgerMapIcon (22, 0x188B; 兄弟 CIntelLedgerMapRegionIcon 23) | **CState\* 向量@+144** (质心定位) | 14 个命名 widget (六计数+六图标+双视图+missions_grid) @+192..+304 + 空海任务行表@+312/+352; 数据源 = CCountryIntelLedgerView 单例 **qword_14338B4C0** revision 门; **无 tooltip** (副 vt[0]=ret0) |
| CIntelLedgerResourceEntry (0x68B 行件, 基 CStandardGridBoxItem 零覆写) | **+32 = 资源库 def (qword_14332F088 ✓)** | 窗 ledger_resource_entry; 资源图标帧 = **def+220 ✓**; **+88 = C2dPieChartTemplate 饼图** (RTDynamicCast 直证); tooltip = TRADE_PRODUCED/IMPORTED/EXPORTED + NO_INTEL 民用情报门 |
| CConstructionInfoMapIcon (4, 0x640B) | **州 id@+136 + 转换对象@+176** | 12 widget (双计数+双转换钮+disabled 对+双旗+infrastructure_effect); 点击 = **CConvertFactoryCommand** (arms/industry 双向, sub_1409D5740/89F0 门); tooltip = STATE_CONVERT_BUILDING {FACTOR, BUILDING_FROM, TO} |
| CStateModifierMapIcon (28, 0x90B; 单基无 tooltip) | **CState\*@+128 + "modifiers_list" widget@+136** | populate 遍历 **CState+1968/+1980 dynamic_modifier 容器 ✓§4.13** (注意: 非 st+2256 哈希) |
| CAdjacencyRuleIcon (16, 0x5A8B) | **CAdjacencyRule\*@+1432 + 省对象@+1440** (省 id@+164 ✓) | 位置 = 省地图对象+4568 float3 + 规则偏移; 槽[9] = 常数 10; hover 经 sub_140B6C5E0 高亮海峡; tooltip = 规则名 HEADER + 逐国要求文本 |
| CPeaceMapIcon (15, 0x128B; peacemapicon.cpp:65 实名断言) | **州 id@+136** | 和会割让州图标; 内嵌 CResourceEntry + CNegotiatorFlagEntry 双行表; tooltip = sub_1419E5540 和会处置预览 + PEACE_HIDE_MAP_ICON; 无自有点击 |
| CCounterintelligenceMapIconEntry (0x78B 行件, 基 CIntelMapModeMapIconEntry) | **tag@+88** | 槽[19] 实现基纯虚 = 目标国首都省; populate 用 **define COUNTERINTELLIGENCE_ACTIVITY_LEVEL_THRESHOLD_COLORS** 数组给 +112 widget 着色 (+80 计时器翻帧); tooltip = AGENCY_DEFENSE_LEVEL_DESC + COUNTERINTELLIGENCE_ACTIVITY_LEVEL(_DESC) |
| CIntelMapModeMapIconMore (1376B, 基 CIntelMapModeMapIconEntry) | 图标超量聚合行 | 工厂门 = 图标计数 < defines 全局 dword_143332B50 不建 (超量时聚合显示); 属 CIntelMapModeMapIconEntry 子族 |

#### 4.30.29 顶栏/陆军总览/力量平衡窗本体 (CTopBar / CArmiesView / CPowerBalanceView)

本节 = 三张 View 本体的布局与 glue 全表; 行件侧 (CDivisionsSummaryItemView 等行/条目级) 见 §4.31.53。

**CPowerBalanceView (1632B 新锚, "powerbalanceview")**：主 vt 0x142A58F70（4 槽）+ @40 tooltip（[0] BuildTooltip 0x141C5D950）；ctor 0x141C5CC00；创建点 sub_14157C600；[2] Reload 0x141C5E940 → sub_141C5E950(this, *(this+64))。布局：+56 ctx / +64 会话对象 / +72 主窗 / +80 decision_container / +88 decision_grid / +1384..+1424 六件（power_balance_name/active_range_name/power_balance_value/position_marker/left_power_icon/right_power_icon）/ +1432 当前 CPowerBalance\*（Update 写 FindBalance 结果）/ +1440 range 缓存；**尾部扩展新锚：+1480/+1512/+1544/+1576 四组容器 + +1608/+1620/+1624 行池区 + +1628 f32=0.5f**；Update 真入口 = sub_141C5F5D0（非虚；sub_140E56DF0(gs+1104, gs+1312/1316) FindBalance，变化/强制 → sub_141C60810 populate）；+48 value → 百分比 = 50×(v+100000)/100000（populate 内逐字同）；侧名 = CPowerBalance+24 left / +32 right → +16 名串（sub_140E57080）；平衡名 = template+16（sub_140A8D870）。

**CTopBar (39328B, "topbar")**：主 vt 0x142A11290（4 槽）+ @40 tooltip 0x142A112B8 + @48 update 0x142A112D0（10 槽）；ctor 0x14188FDC0；[2] Reload 0x14189ECF0；@48[6] 全刷 0x14189D4E0（→sub_1418A1EE0 日期）/[7] 逐帧 0x14189D510/[9] Repopulate 0x1418A2170（+39008 tag 缓存比对 gs+1312/1316）；glue 注册器 = 每 glue 仅绑 1 handler（sub_14188F7A0；+9280/+26056 两位特化）。

glue 网格 = **26 槽位 +264..+32496 步距 1288**（+23448 新对象插入后后续槽各 +32，原位存在）；逐钮表（绑定函数 sub_14189EF20；widget 名实证）：

| 偏移 | 元素名 | glue@ | handler / 语义 |
|---|---|---|---|
| +39016..+39048 | button_speedstep1..5 ×5 | +26056 | sub_14189EEF0（ctx vt[37]() 取目标速度 → sub_140DE0160 跳转；帧规则 = i≤*(gs+1212) → (i==4)+2 否则 1，vt[22] SetFrame；**gs+1212 = 当前游戏速度档 (int, clamp 0..4)** — 写者 sub_1401EDE50 `if (a2>4) a2=4;` 后写 +1212；调用者 = 加减速钮 sub_140F06EF0 (`gs+303+1`) / sub_140F069B0 (`gs+303−1`) / sub_140F07110 读档初始化） |
| +39056 | decisionview_button | +4128 | sub_1418A1870（→sub_140B6DC30(parent, 3, 1) 视图 3） |
| +39064 | intel_agency_button | +5416 | sub_1418A1A50（视图 4） |
| +39072 | technology_button | +7992 | sub_1418A1C60（→sub_1418A1BE0(parent,0) tech 树切换） |
| +39080 | diplomacy_button | +9280 | sub_141896C40 双分支（DLC43: sub_1418A1A90 → sub_141E74F40(view+39176) + sub_1418A1A70 视图 10；无 DLC: sub_1418A1A20 视图 9） |
| +39088 | trade_button | +13144 | sub_1418A1C80（视图 15） |
| +39096 | construction_button | +17008 | sub_1418A1850（视图 17） |
| +39104 | production_button（+39112 glow 件） | +6704 | sub_1418A1BA0（视图 2 + 清 +39312 决策辉光超载旗 + 触 +39112 glow 件 vt[16]\|=0x10） |
| +39120 | **deployment_button** | +11856 | sub_1418A1A00（→sub_140B6DC30(parent, 14, 1) 视图 14；原稿「疑 trade」证伪——trade 在 +39088） |
| +39128 | logistics_button | +14432 | sub_1418A1AA0（→sub_140B6DB70(parent, 1)） |
| +39136 | officer_corp_button | +15720 | sub_1418A1B30（→sub_140B6DC30(parent, 19, 1) 视图 19） |
| +39144 | decisionview_amount_to_take_items（+39152 配 _bg） | — | 决策可执行数 |
| +39160 | prototype_rewards_aquired（+39168 配 _bg） | — | 特种项目奖励数 |
| +39184 | threat 相关文本件 | +22160 | sub_1418A1CA0（ctx vt[23]() → sub_140B6DDF0：obj+416 窗 vt[7]/vt[8] 显隐切换；"threat_button"/"threat_value_button" 双件共享此 glue） |
| +39192 | non_delivering_contract_amount（+39200 配 _bg） | — | loc INTERNATIONAL_MARKET_TOPBAR_BUTTON_CONTRACT_COUNT{VALUE} 仍在 Update 内 |
| +39208 | ongoing_contract_amount（+39216 配 _bg） | — | |
| +39224 | decisionview_amount_timeout_items（+39232 配 _bg） | — | 决策超时数 |
| +39240 | decision_view_alert_glow | — | |
| +39248 | intelview_ops_available_items（+39256 配 _bg） | — | 可用行动数（sub_1418A2A50：*(sub_140F2A500()+108)≤0 门，DLC 25） |
| +39264 | intelview_ops_prepared_or_completed_items（+39272 配 _bg） | — | 就绪/完成数（sub_1418A2C40：+12 + +36 双计数） |
| +39312 | u8 旗 = 1 | — | 决策辉光超载旗（+6704 handler 清 0） |

> 尾块 +33784 = sub_141DF7730（ctor）；music_pause_button / music_next_button 绑 sub_141DF8BE0 / sub_141DF8880。
> +39176 = 96B 对象（绑定函数尾 malloc；6 字段 + 2 隐藏链表；@48[3]/[5] 门判定 = view+39176 非空，转发 sub_141E750B0/sub_141E74C00，语义未展开）。

**glue handler 全表**：

| glue@ | handler | 语义 |
|---|---|---|
| +264 | sub_1418A1740 | achievements → sub_140B6DAA0(*(a1+112)) |
| +1552 | sub_1418A1A40 | menu_button → sub_140B6DAF0(*(a1+112)) |
| +2840 | sub_1418A1730 | dismissed_alerts → sub_140B175B0(*(*(a1+104)+1944)) |
| +4128 | sub_1418A1870 | decisionview_button（视图 3） |
| +5416 | sub_1418A1A50 | intel_agency_button（视图 4） |
| +6704 | sub_1418A1BA0 | production_button（视图 2 + 辉光旗联动） |
| +7992 | sub_1418A1C60 | technology_button（tech 树切换） |
| +9280 | （sub_141896C40 特化） | diplomacy_button（DLC43 门双 handler） |
| +10568 | sub_1418A1B80 | player_flag（视图 12） |
| +11856 | sub_1418A1A00 | deployment_button（视图 14） |
| +13144 | sub_1418A1C80 | trade_button（视图 15） |
| +14432 | sub_1418A1AA0 | logistics_button |
| +15720 | sub_1418A1B30 | officer_corp_button（视图 19） |
| +17008 | sub_1418A1850 | construction_button（视图 17） |
| +18296 | sub_1418A17D0 | army_button（视图 18 + 门 sub_141709FA0 + 尾 sub_14170ADC0） |
| +19584 | sub_1418A1AB0 | navy_button（同构） |
| +20872 | sub_1418A1750 | air_button（同构） |
| +22160 | sub_1418A1CA0 | threat（obj+416 面板切换） |
| +23480 | sub_14189D380 | button_speedup：单机 sub_140203190(+1)；**MP 构造 CIncreaseGameSpeedCommand(40B) 投递 sub_142250B00** |
| +24768 | sub_141892860 | button_speeddown：单机 sub_140203190(−1)；**MP 构造 CDecreaseGameSpeedCommand(72B) 投递** |
| +26056 | sub_14189EEF0 | speedstep 钮 → 目标速度跳转 |
| +27344 | sub_1418A1B50 | ctx vt[71](ctx,1) → sub_1418A2E30 刷新（music 暂停 toggle 形；widget 绑定件待裁） |
| +28632 | sub_1418A1B50 | pause_button_date/pause_button_date_paused 双件共享（与 +27344 同 handler） |
| +29920 | sub_14189ED70 | reopen_ingame_lobby（CServer RTDynamicCast 门）→ sub_140B6B970(ctx vt[23](), 0) |
| +31208 | sub_14189E9D0 | playlist_button：FindWindow "toggle_music_commands_win" 显隐 toggle（推定） |
| +32496 | sub_14189EAF0 | musicplayer → sub_140B6DBD0(*(a1+112)) |

> ⚠ 「CTopBar 全部无 CCommand 出口」对调速两钮不成立：MP 分支构造速度命令投递命令队列（单机路径直接调速，——其 handler 无 dump 可复核，标推定）。
> 数据源锚（view+39008 tag 缓存，逐帧 sub_140BB48F0 取 cc）：DateText = gs+1120（setter sub_1418A1EE0）；pol_power = CPolitics+224；industrial_capacity = sub_140E693C0(cc+3944)（公式 (ps+792+888+696)/1e5 − 六项占用）；industrial_ratio_bar = ps+936 ×100；三军经验 = cc+5512 +16(陆,view+168)/+64(空,view+160)/+40(海,view+176)；command_power = cc+496；fuel = cc+5504（文本 sub_1410F6390 / 比值 sub_1410F3570 ×100）；nukes = sub_141097B50(cc)>0；stability/war_support = sub_1406F8750/sub_1406F9E70(cc)；player_flag = sub_140B44AC0(ctx+1272, flag 件, view+39008, 0,1,0)；achievements 使能 = sub_14061E2D0(sub_14061CD20(), gs, 0)≤1；**supply/convoys 源 = sub_1418A1CC0（cc+4608 系统根 → 枚举）**；**threat_value = define 表达式 TOB_BAR_THREAT 求值 sub_1402E31F0（替代手写聚合器——机制变了）**；BuildTooltip = 0x141897AB0。

**CArmiesView (1640B, "armies_view")**：主 vt 0x1429E9C98（4 槽）+ @40 tooltip；ctor 0x141692440；[2] Reload 0x1416AD9A0。布局：+1336 ctx / +1344/+1352/+1360 主窗子窗 / +1368 CArmyLeaderWindow\* / +1376/+1388 子窗指针数组（+1392 sentinel）/ +1400/+1408 CArmyDivisionListView ×2 / +1416/+1424 CRailwayGunListView ×2 / +1432 徽标 int（推定）/ +1440 选中槽 = −1 / +1444 u8 = 1 / +1448..+1544 容器四组（sentinel ×2 = qword_14333D528）/ +1488 选中师 refid（count +1500，选择同步 sub_1416C2E10 内 type==0 → vt[7] 推入）/ +1512 数组（count +1524）/ +1544 选中铁路炮 refid（count +1556，type==13 → vt[11]）/ +1592 脏旗（glue 回调 sub_1416AC7E0 置 1）/ +1600..+1632 远征窗等。glue @+48 ctor = sub_141690BC0（同构注册器）；建窗 sub_1416AE5D0 / 选择集 helper sub_140BC3180（判空）/ sub_140BC30C0（链表化）；主 populate = sub_1416BC7E0。

#### 4.30.30 国别域六视图本体 (CCountryConstructionsView / CCountryDiplomacyView / CCountryIntelligenceAgencyView / CCountryLogisticsView / CCountryOccupationView / CCountryTechnologyView)

视图本体 (装配器 0x140B614C0 统一 malloc, 挂宿主 +232/+240/+272/+288/+328/+336); 行件侧 (国旗行/选择行/过滤器行) 见 §4.31.65。

| 类 | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---:|---|---|
| CCountryConstructionsView | countryconstructionsview(id1) | 5520 | 建设面板视图（唯一带第四基 CReorderObserver@1408；+1480 = CGameDate "1.1.1.1" 哨兵新消费点） | 定案 |
| CCountryDiplomacyView | countrydiplomacyview(id4) | 17680 | 外交视图 | 定案 |
| CCountryIntelligenceAgencyView | countryintelligenceagencyview(id6) | 14752 | 情报机构视图（[9] 读宿主 tag 上国名窗题） | 定案 |
| CCountryLogisticsView | countrylogisticsview(id4) | 6904 | 后勤视图（[5] 转发 [9]） | 定案 |
| CCountryOccupationView | countryoccupationview(id5) | 11976 | 占领视图 | 定案 |
| CCountryTechnologyView | countrytechnologyview(id6) | 4320 | 科技视图（[9] 选中扫描 byte165&0x10） | 定案 |

**六视图自有域**（基域 +0..+1407，派生自有 +1408 起）：

| 视图 | 自有域（+1408 起） | 业务槽 |
|---|---|---|
| CCountryTechnologyView (4320, id6) | +1408 u32 所选科技 id / +1416 向量 {data@+1416, count@+1428, alloc@+1432}（[5] 遍历调 sub_141BE35C0）/ +1448 u32 国家 tag 副本（父 vt[20] 取）/ +1456、+1480、+1504 三 24B 对象（unwind 对，推定）/ +1552、+2920 两 CButtonWrapper / +4288..+4319 零块（[6] 读 +4288 门 → 面板开合） | [5] 0x1415F8FF0 布线+树清理 / [6] 0x1415F9050 / [9] 0x1415FA1A0（byte165&0x10 选中扫描） |
| CCountryDiplomacyView (17680, id4) | +1408 子对象（sub_1415E3B60，至 7016）/ +7016 子对象（sub_1415E3FE0，至 14952）/ +14952 子对象（sub_1415E2950，至 17664）/ +17664 u32 / +17672 qword | [5] 0x1415EBCD0（+17544 未建门 && +17616>0 → sub_1415F0810 填充）/ [9] 0x1415F08E0（选中传播：+6664 选中 idx、+17504/+17516 计数同步、+14816 窗控 facet+128 开合；偏移为槽 this 相对换算，推定未决） |
| CCountryLogisticsView (6904, id4) | +1408 窗件块（sub_14172D170，回调 sub_141730780）/ +2696 窗件块（回调 sub_1417308F0）/ +3984 窗件块（回调 sub_141730600）/ +5272 窗件块（回调 sub_1417305C0） | [5] 0x1413D96A0 = 转发自身 vt[9]（后勤/占领共用）/ [9] 0x141731FE0（"materiel" 物资行填充） |
| CCountryOccupationView (11976, id5) | +1408、+1416 块（sub_141557B60 初始化域）/ +2704、+3992、+5280 同上三段（语义推定） | [5] 0x1413D96A0（与后勤同址）/ @48[7] 0x141566AF0（占领矩阵刷新：+11720 域 + byte165&8 可见门 + UI 根 +1288 facet）/ @48[9] 0x14156F5A0（Repopulate；槽号勘误见 §4.31.68 注） |
| CCountryIntelligenceAgencyView (14752, id6) | +1408 起连环子域（sub_140F265F0 / sub_140F2C1C0：机构对象、列域，至 14752；细分待裁） | [5] 0x140F2C0A0（机构刷新，+1432 机构对象 → sub_141A20990/221C0）/ [6] 0x140F2C100 / [9] 0x140F2F3A0（读宿主 +1392 vt[20] tag → 国家对象 → 国名(@国+128) 上窗题） |
| CCountryConstructionsView (5520, id1) | +1408 CClass* CReorderObserver 次表（唯一带第四基视图，4 槽）/ +1416 24B 对象 / +1440、+1448 qword / +1456 24B 向量头（+1480 = CGameDate 43808760 "1.1.1.1" 哨兵、+1488 第二 CGameDate、+1496 u16）/ +1504、+2792、+4144 三窗件块（回调 sub_141716900/CF0/540）/ +4080..+4143、+5432..+5519 零块 | [1] 0x141716EA0 = 置位 / [2] 0x141716820 = 清位 —— 同构体 `(*(vt+184))(qword_14332F6A0)` 取会话 GUI 根后写 `*(BYTE*)(root+1016) = 1 / 0`，即显示抑制门 set/clear 对（定案）；行集 = ps+112 general_lines / 民池 / cc+3944，populate 0x141719340 |

> CCountryConstructionsView CReorderObserver 表 4 槽为主表（本类主表只覆写 [1]/[2]）。CCountryTechnologyView [9] 选中扫描与 §4.00.6 CStandardGridBoxItem 行互证。
**CCountryLogisticsView 自有尾域**（+6560..+6903，重锚后零漂移，ctor 六容器全量初始化）：**六容器** +6560/+6584/+6608/+6632/+6656/+6680（均 24B；前两只 = 225 特行列表；**+6680 = 第六窗件块**，消费 sub_1419107D0（读 +6680 并 `(*(vt+128))(+6680)` 挂载）+ 建/拆 sub_141912040（析构走 vt+552））；三 tab 兜底行 +6728 (land) / +6736 (naval) / +6744 (air)；双子窗 +6712/+6720；清靶 +6752/+6760/+6768；tag +6784；优先级四行组 +6792..+6896；表头 +6704；0x5D8=1496 行槽 +1392..+1480 与 kind 映射；「其它」桶 {data@+1344, count@+1356}。主表槽：[7] 0x141730550（基复位 + 收 +6712/+6720 + 清 +6752/+6760/+6768）/ [14] 0x141730A80 / [15] 0x14172E5C0 / Repopulate 0x141731FE0；ctor sub_14172D950。**⚠ 「+2632 窗件块」在本视图不存在**（旧原稿唯一出处 = CTradeResourceInfoItem 贸易行件文本元素——按域剔除）。
**CCountryMilitaryOverview（军事总览窗）**：+13737 u8 = 抑制旗 / +1408 tab 枚举 / +1448 排序列（−1 复位）/ +1452 计数；主表槽 [4] 0x14170C090 / [6] 0x14170AC80；**@48[9] 排序器 = 0x14170E550**（谓词 sub_141D3A460）：排序三列表主坐标 **+13408/+13480/+13600**、比较子 **+13696/+13712/+13728**、回调向量 +13648、收件 +13192/+13208；[14] 元素新增 **army_sort_group**（与 army_sort_name/army_sort_type 并列；navy/air_sort_name 同族）；⚠ 旧原稿「view+13552/+13680」= @48 坐标系记录，真值同主坐标。填充点未定位（未决）。
> CCountryConstructionsView 补遗：[7] = 0x141716300（+1496=+1497）；[4] = 0x141719090；Repopulate = 0x14171A960；**+5496/+5504** 结构定案（ctor 清零、dtor 释放、[4] 刷 +5504、助手行筛选 churn；类名未决）、**+5512 = 表头对象**（Repopulate 尾）；民池 available（ps+888/912/944/920）与 **traded（ps+948+ps+956）公式逐字复证**；local（ps+964/+968）1.19.3 无直读 → 未决；[7] 的 +1392 vt[23]+1032 门 1.19.3 为**非零门**（旧原稿记 ==2）→ 待裁。装备库单例 **qword_14332EEC0 = TGameItemDatabase\<common/units/equipment\> {items@+128, 计@+140}**。
**CCountryView 六视图共同骨架**（定案）：基 ctor sub_141237180(this, 父gui, 容器, 名串, id) 五段 = CReloadableInterface@0（sub_142255FA0 查 .gui 描述子）→ CTooltipHandler@40 → CInGameUpdateableInterface@48（sub_1412362A0 注册键 id）→ CCountryView 三表齐写 → +72 = 1288B 窗件块（sub_1412369A0，回调 sub_141237480）→ +1360 = 名串副本 32B → +1392 = 宿主面板回指 → +1400 = 0；派生自有字段一律 +1408 起。主表 10 槽中 [1][2][3][4][6][7] = updateableinterface.cpp 桩（"Override this function before using!"），[8] = thunk → (this−48)+40，**[5]/[9] = 派生业务槽**。facet 方法表槽语义：+120 查子件 / +128 挂窗件块 / +136 取窗体 / +152 描述子+48 / +176 SetEnabled / +432 查孙 / +440 查列表 / +552 注册行 tooltip / +592 可见门。

#### 4.30.31 精灵/GUI 模板 Type 族 (CSpriteType 族锚 + 7 派生 Type + 2d 元素族名录)

族共性 (定案): Type 族基链 = `XxxType ← C2dObjectType ← CObjectType ← CPersistentWithToken ← CPersistent`; 全部 **writer = CFG 空桩** (mod .gfx/.gui 模板解析件, 不入存档), reader = 自有实现; 元素族基链 = `Xxx ← (CSprite) ← C2dVisibleObject ← C2dObject ← CGraphicalObject`, 全部非 CPersistent (内存渲染对象)。基 reader 0x142355FD0 公共三键: name(27)@+16 / loadType(293)@+64 (枚举 FRONTEND=1/BACKEND=2/INGAME=3) / norefcount(294)@+68; 元素 +16 = 类型对象回指 (C2dObject 层), 元素 +304 = 构造值对槽 (族共性); 元素尾部分配器槽普遍 = off_143085170 (§4.00.9)。

**CSpriteType** (精灵模板族锚, ≥472B; vt 0x142B3DD58 33 槽; writer=CFG; reader 0x142241240 = 族公共 reader, 各派生 reader 全回落到它; ctor 0x14223ED20; 模板键 `spriteType`/`spriteTypes`):

| 偏移 | 类型 | 键 (token) | 备注 |
|---|---|---|---|
| +16 | SSO 串 | name (27) | 基 reader |
| +48 | u32 | — | ctor 0 (推定 id/序) |
| +64 | u32 枚举 | loadType (293) | 基 reader |
| +68 | u8 | norefcount (294) | 基 reader |
| +72 | CClass* | 纹理指针 (ctor=a2) | CProgressbarSprite 工厂直取此槽 |
| +80 | SSO 串 | effectFile (90) | |
| +112 | SSO 串 | textureFile (37) | |
| +144 | i32 | noOfFrames (28), 默认 1 | |
| +148 | i32 | — | ctor 1 (推定 帧网格 y) |
| +156 | f32 | defaultAnimationTime (66), 默认 1.0 | |
| +164 | u32 | — | ctor 参数 (推定 帧尺寸; 与 +168 成对) |
| +168 | u32 | — | ctor 参数 (推定 帧尺寸; 与 +164 成对) |
| +224 | i64 | anchor (750) | 枚举串映射 helper 0x140ADDCA0 |
| +232 | — | = +224 anchor 枚举槽 | 枚举串映射 helper 0x140ADDCA0 |
| +240 | f32 | — | ctor -1.0 (推定) |
| +244 | f32 | — | ctor 1.0 (推定 缩放对; 与 +248 成对) |
| +248 | f32 | — | ctor 1.0 (推定 缩放对; 与 +244 成对) |
| +268 | u32 | framedirectiony (571) | 布尔读存 u32 |
| +273 | u8 | allwaystransparent (319) ≡ alwaystransparent (470) | 拼写双键同槽 |
| +280 | 向量 {data@+280, cap@+288, count@+292, alloc@+296} | animation (64) 帧动画表 | 元素 SAnimationMapData 144B (含 vt, 1.5× 增长) |
| +304..+360 | i64×8 | — | ctor 全 -1 句柄缓存 (推定 textureFile1..8 纹理缓存) |
| +368 | CClass* | — | ctor=a3 (推定 纹理图集/后备纹理) |
| +384 | SSO 串 | masking_texture (577) | |
| +408 | i32 | — | ctor -1 |
| +416 | i32 | — | ctor -1 (推定) |
| +424 | SSO 串 | clicksound (284) | |
| +456 | i64 | dx_offset (735) | 同 anchor 枚举 helper |
| +464 | u8 | transparencecheck (275) | 写后 +465 置「已显式设置」旗 |
| +466 | u8 | can_be_lowres (406) | |
| +467 | u8 | legacy_lazy_load (655) | |
| +469 | u8 | generate_mip_maps (786) | |

派生 Type 7 类 (增量段 = CSpriteType 全表 + 下表自有段; 均 writer=CFG 解析件):

| 类 | vt | 尺寸 | 自有段 (基链) |
|---|---|---|---|
| CFrameAnimatedSpriteType | 0x142B51C60 | ≥512B | +496 f32 animation_rate_fps (452, 取倒数)/animation_rate_spf (453 直写同槽) / +504 f32 = **`pause_on_loop` (457) 以 f32 落槽** (reader `sub_1424C0930` 数值读 — 非布尔, 引擎按数值语义消费, 非类型错) / +508 u8 looping (454) / +509 u8 play_on_show (455); reader 0x142357650 |
| CMaskedSpriteType | 0x1429E6DC0 | ≥696B | +496 ptr (ctor=a2 推定 宿主库) / +504 textureFile2 (39) / +536 textureFile1 (38) / +592 effectFile (90) / +624..+680 缓存群 / +688 u8 small (12503); reader 0x1416422F0 (vt 孤立于 0x1429Exxxx 簇) |
| CTileSpriteType | 0x142B52838 | ≥504B | +496 u32×2 size (47) 唯一自有键; reader 0x142361910 |
| CTextSpriteType | 0x142B52680 | ≥360B | 不经 CSpriteType: +104 textureFile (37) / +136 i32 -1 / +140 noOfFrames (28) / +144 ptr / +152 f32 defaultAnimationTime (66) / +156 ptr / +168 effectFile (90) / +200/+232 SSO×2 (键未在自有 reader 出现, 推定 基类/另键) / +304 u16=1 / +312 clicksound (284) / +344/+352 i64 -1 缓存对; reader 0x142361150 |
| CProgressbarSpriteType | 0x142B521B8 | ≥292B | 不经 CSpriteType: +80 effectFile (90) / +112 CColor color (86) / +144 CColor colortwo (268) / +176 textureFile1 (38) / +208 textureFile2 (39) / +240 i64=-1 / +248 steps (488, 默认 100) / +252 u32×2 size (47) / +264 u8 horizontal (153, 默认 1) / +280 u8 alwaystransparent 双键同槽 / +284/+288 f32 1.0 对; reader 0x14235FEA0; 元素工厂 vt[23] 0x14235FB30 |
| CResizeableSpriteType | 0x142B525B0 | ≥128B | 不经 CSpriteType: +80 textureFile (37) / +104 i32 对 — **键 28 (noOfFrames) 与 66 (defaultAnimationTime) 都落 `sub_1424C0900(a2, a1+104)`**: reader 显式 fall-through, 引擎共用该 8B 槽 (设计, 非文档缺陷) / +116 u32×2 size (47) / +124 i32=-1; reader 0x1423607E0 |
| CCorneredTileSpriteType | 0x142B414A8 | ≥208B | 不经 CSpriteType: +72 纹理指针 / +80 textureFile (37) / +112 noOfFrames (28, 默认 1) / +124 u32×2 borderSize (134) / +132 u32×2 size (47) / +144 effectFile (90) / +176/+184 ptr -1 纹理缓存对 / +200 u8 alwaystransparent 双键同槽 / +201 u8 tilingCenter (369) / +202 u8 looping (454) / +204 f32 animation_rate_fps/spf 同槽; reader 0x142295EE0 |

2d 元素族名录 (均非 CPersistent, 不可序列化; 基 ctor = 0x1422AE140 C2dVisibleObject 链, 基段 ~304B):

| 类 | vt | 尺寸 | 一句话 |
|---|---|---|---|
| CSprite | 0x142B4BA90 | 456B | 精灵元素族锚: +16/+384 类型 / +368/+372 缩放对 / +432/+440 动画帧游标容器对 / +448 分配器; ctor 0x1422FE170 |
| CFrameAnimatedSprite | 0x142B4D400 | ≥488B | 帧动画精灵 (CSprite 派生): +464 动画控制参数块; ctor 0x142308530 |
| CCorneredTileSprite | 0x142B50E68 | ≥424B | 九宫格角块贴图: +376/+380..+392 类型 getter 缓存对; ctor 0x142353290 |
| CInstantSprite | 0x142B47C98 | ≥472B | 即时贴图: +376/+380 缩放对 / +416 矩形参数 / +440..+456 串+句柄; ctor 0x1422D46D0 |
| CProgressbarSprite | 0x142B52288 | 480B (工厂定案) | 进度条元素: +304 纹理尺寸对 / +376 类型 / +384 纹理指针 / +400/+432 子对象对 / +208/+224 颜色对; 工厂 = Type vt[23] 0x14235FB30 |
| CResizeableSprite | 0x142B59A50 | ≥392B | 可拉伸贴图: +384/+388 可拉伸区参数缓存; ctor 0x142385BD0 |
| CTextSprite | 0x142B47F60 | ≥664B | 文本贴图, 多基 +CLostDeviceInterface 次表@+368; +552 = 2d/纹理管理器全局 qword_143453090; 尾段 +640/+648 清零 / +656 u8 / +658 u16 / +660 u8=a4 / +661 u8=1; ctor 0x1422D52A0 |
| C2dCircularProgressBar | 0x142B59768 | ≥872B | 环形进度条, 次表 CLostDeviceInterface@+368; +856/+864 宿主参数块; ctor 0x142384E40 |
| CButton | 0x142B44828 (+次 0x142B44BB0) | ≥232B | 按钮 widget, observable 面@+128 (§4.00.6 管线 ✓); 字段 +136/+144/+160/+184/+192/+208/+216 清零 + +152 u32/+156 u8/+168 u8/+176 u32/+224 u32/+228 旗 (初值 0xB8)/+200 = off_143085170; ctor 0x1422AEE70 |
| CIcon | 0x142B4AF50 (+次 0x142B4B308) | ≥352B | 图标按钮 (CButton 派生): +256/+260 尺寸 f32 对 / +340 u8 四布尔打包位; ctor 0x1422FACA0 |
| TButton | 0x142B444B8 | — | 按钮抽象基 (8 纯虚槽), 不独立实例化 |

> **CTextureReloader** (vt 0x142B3D720 4 槽, 基 CReloadDispatcher) = 排除: 文件变更→纹理刷新钩子 ([1] 路径谓词 0x14223CAA0 / [2][3] 经 qword_143453090 桶槽迭代), 纯图形基础设施。
> 读侧 helper 分类 (后续 GUI Type 批可复用): 0x1424C0C00 = bool u8 / 0x1424C0AB0 = SSO 串 / 0x1424C08D0 = i32 / 0x1424C0930 = f32 / 0x1424C0900 = i32 对 / 0x1424C0AA0 = 复合块 (CColor 16B/动画元素) / 0x140A4C640 = u32 对 (size/borderSize) / 0x140ADDCA0 = 枚举串映射 (anchor/dx_offset); 写侧 0x1424C37B0 = u8 / 0x1424C2F40 = u32。
> idb 评估: 8 个 SpriteType 属「GUI 模板库」形态 (spriteTypes 块由各自 reader 解析注册, 键串簇 0x2ae5550..0x2aea130); §4.26.4 idb 规格表无一 GUI 键 — 若做 GFX 名→纹理映射, 本节 reader↔偏移表即规格表底稿。**GFX/内容库名注册表 qword_143339CB8 值类 = `CGraphicalCultureType*`** (定案; 消费者 sub_140712200/sub_140712260 把查得指针写入 CCountry+4168/+4128 = graphical_culture / graphical_culture_2d 解析结果槽 §4.3; 加载器 sub_140181110 解析 `common/graphicalculturetype.txt` 注册; 空值 CNullGraphicalCultureType 0x14293C058; 表 40B {mask u32@+4 默认 511, buckets@+8, count@+16, 未决@+24, alloc@+32}, 惰性建 sub_140A3BF90 once 守卫 dword_14332ECF0; `_gfx` 后缀回退 = sub_140ADF1F0)。

**注册库三库分流 (定案)**: ① spriteTypes 族 → 纹理管理器单例 qword_143453090 的 **+256 哈希表** (表头 {+4 nbuckets 默认 511, +8 buckets}; get-or-create sub_142237660); ② .gui 控件模板 (CGuiType 群) → **CGui/CGameGui 对象 +192 CTernary\<CGuiType\*\>** {容器@+200, count@+212}, 工厂 = CGui vt[29] CreateTemplate 0x14225ABB0 (token 尺寸与本节键表互证), 实例挂应用对象 +872; ③ GFX/内容库名注册表 = **qword_143339CB8** 懒建单例 (40B, once 守卫 dword_14332ECF0, 哈希形态同①; "_gfx" 后缀解析与纹理按名取件走此表) — **负定案**: 该表 = 40B 匿名哈希容器 (builder sub_140A3BF90 malloc 0x28 → {+0 dword 0 / +4 mask 511 / +8 buckets(0xFFF8) / +16 count / +24 alloc / +32 alloc(off_143085170)}), **无独立 RTTI 类**; 值类 = `CGraphicalCultureType*`。

#### 4.30.32 GUI 控件 Type 族 (CGuiType 壳 + 控件模板 Type 群 + 元素/观察器族)

族壳 (定案): Type 类基链 `XxxType ← CGuiType ← CPersistentWithToken ← CPersistent` (CLineChartType 例外走 C2dObjectType 链; 带 CFactory 次基 md+240 者 = CListboxType / CRadioButtonGroupType / CRadioScrollbarGroupType / CScrollbarType / CWindowType / CDropDownMenuType)。**主虚表 13 槽契约** (CLineChartType 25 槽): [0] dtor / [1] Save wrapper 0x1424BEC50 / [2] writer = **CFG 空桩** (mod .gui 模板解析件永不落盘) / [3] Load wrapper = **CGuiType 覆写版 0x1422DE0B0** (先记 文件名 SSO@+72 + 行号@+224 再回落 0x1424BE690 — 故全族除 CLineChartType 外不入 serfam 指纹 = 格式差异非非持久化) / [4] 逐类 Parse (token switch) / [5..8] 空桩样板 / [9] 0x14061F7D0 = GetName (name SSO@+40) / [10] 元素工厂 / [11] 父串回吐。**CGuiType** (基类抽象, vt 0x142B48628, [10][11] _purecall; Parse 0x1422DE390 = 全族公共回落; 公共键: name(27)→+40 SSO / tooltip(146)/tooltipText(147)/pdx_tooltip(364)→+144 interned 池化串 (intern = sub_14239E3E0) / delayedTooltipText(148)/pdx_tooltip_delayed(365)→+152 / pdx_disabled_tooltip(787)→+160 / pdx_disabled_tooltip_delayed(788)→+168 / hint_tag(458)→+192 SSO / hide(679)→+187 u8 / context_aware_tooltip(794)/bound_tooltip(796)→+104 绑定串复合块 (0x1424C0AA0, 互斥, 置 +136 旗) / pdx_tooltip_anchor(733) 块→子键 x(32)→+176 / y(33)→+180 / relative(734)→+185 / below(752)→+186, 块起始置 +184; 未命中再落 CPersistentWithToken 基 0x1424BEC40)。

模板键 ↔ Type 类 ↔ 承接点 (全部定案; CContainerWindowType::Parse = 统一承接点, containerwindowtype.cpp):

| 模板键 (token id) | Type 类 | vt | Parse | 承接 |
|---|---|---|---|---|
| buttontype (625) | CButtonType | 0x142B53CC8 | 0x142370410 | CContainerWindowType case / CDropDownBoxType 642 / CExtendedScrollbarType 138/139/156/638/639 / CGridBoxType 156 |
| curveGraphType (648) | CCurveGraphType | 0x142B4FBC0 | 0x14232BF10 | CContainerWindowType case |
| dropDownBoxType (620) | CDropDownBoxType | 0x142B53E20 | 0x1423714D0 | CContainerWindowType case |
| dropDownMenuType (185) | CDropDownMenuType | 0x142B53F60 | 0x142372910 | 库层 (CFactory 面 md+240; vt[11] 0x1422F7E60 工厂槽) |
| editBoxType (170) | CEditBoxType | 0x142B54050 | 0x142373070 | CContainerWindowType case |
| extendedScrollbarType (613) | CExtendedScrollbarType | 0x142B541E0 | 0x142373BC0 | CContainerWindowType case |
| gridboxtype (629) | CGridBoxType | 0x142B54390 | 0x142374A40 | CContainerWindowType case |
| iconType (182) | CIconType | 0x142B53B50 | 0x14236D870 | CContainerWindowType case |
| instantTextBoxType (288) | CInstantTextBoxType | 0x142B4AD50 | 0x1422FA440 | CContainerWindowType case |
| positionType (178) | CLayoutType | 0x142B54520 | 0x1423758C0 | CContainerWindowType case (库形态, 见下) |
| listBoxType (169) / smoothListboxType (507) | CListboxType | 0x142B54590 | 0x142376FA0 | CWindowType 子件链 (双键同 ctor) |
| scrollbarType (140) | CScrollbarType | 0x142B57C70 | 0x14237CF00 | CWindowType 子件链 |
| radioButton (159) | CRadioButtonGroupType | 0x142B57B50 | 0x14237A890 | guiButtonType(127) 子件链 |
| radioScrollbar (164) | CRadioScrollbarGroupType | 0x142B57BE0 | 0x14237B370 | scrollbarType(140) 子件链 |
| textBoxType (133) | CTextBoxType | 0x142B57D00 | 0x14237DD00 | CWindowType 子件链 |
| OverlappingElementsBoxType (334) | COverlappingElementsBoxType | 0x142B546B8 | 0x1423779D0 | CWindowType 子件链 |
| windowType (155) | CWindowType | 0x142B4AC60 | 0x1422F84B0 | CContainerWindowType case (族锚, 卡见下) |
| lineChart 系 | CLineChartType | 0x142B4EF40 | 0x142320840 | C2dObjectType 链 (serfam 命中件) |
| checkBoxType (196) | CCheckBoxType | 推定 ButtonType 变体 | — | CWindowType 子件链 (+896 链表, 同 CButtonType ctor 0x14236E040) |

**CWindowType** (窗口模板族锚, 对象 ≥1136B; vt 0x142B4AC60; reader 0x1422F84B0; ctor 0x14230E910 1432B): 键 = parent(135)→+248 / background(156)→+280 / position(76)→+312 u32 对 / show_position(398)→+320 / hide_position(399)→+328 / animation_type(400)→+336 枚举 (linear=3/smoothstep=2/accelerated=0) / animation_time(401)→+340 / size(47)→+344 **计算矩形** (宿主尺寸−margin, 勿套通用 helper) / verticalScrollbar(161)→+352 / horizontalScrollbar(162)→+384 / horizontalBorder(166)→+416 / verticalBorder(167)→+448 / priority(141)→+484 f32 / moveable(157)→+488 / fullScreen(48)→+1040 / click_to_front(380)→+1041 / orientation(194)→+1044 枚举 / upsound(281)→+1072 / downsound(282)→+1104。子件创建契约: 工厂 vtable+16 = CreateTemplate(token) → 子件 vt[3] Load wrapper 载入 → 插入器 vtable+48 (parent, key, 子件) → 追加主子件链表 +1048 头/+1056 尾/+1064 计数 + 各分类链表 (+640..+1064 区)。宿主引用 +528 (其 +384/+388 = 基面尺寸); +536 类型工厂; +544 子件插入器; +672 = CTernary\<CGuiType*\> 模板库容器。

子件键 → 构造 → 分类链表 (CWindowType 内):

| 键 (token) | 子件 ctor (尺寸) | 分类链表头/尾/计数 | 备注 |
|---|---|---|---|
| guiButtonType (127) | 类型工厂 vcall | +640/+648/+656 | 子件名须等于 background (sub_14015B420 判) |
| multiSpriteButtonType (180) | CButtonType 0x14236E040 (888B) | +656/+664/+672 | 同条件挂载 |
| checkboxType (196) | CButtonType 0x14236E040 (888B) | +896/+904/+912 | 复选框走 ButtonType 变体 (推定) |
| textBoxType (133) | CTextBoxType 0x14237D5B0 (432B) | +704/+712/+720 | |
| instantTextBoxType (288) | CInstantTextBoxType 0x1422F9EA0 (464B) | +728/+736/+744 | |
| scrollbarType (140) | CScrollbarType 0x14237B540 (672B) | +752/+760/+768 | 与 CRadioScrollbarGroupType 同 ctor |
| editBoxType (170) | CEditBoxType 0x142372BA0 (384B) | +776/+784/+792 | |
| iconType (182) | 类型工厂 vcall | +800/+808/+816 | |
| browserType (647) | 类型工厂 vcall | +824 单槽 | |
| curveGraphType (648) | 类型工厂 vcall | +848 单槽 | |
| dropDownBoxType (620) | 类型工厂 vcall | +872 单槽 (sub_14012B3F0) | |
| listBoxType (169) | CListboxType 0x142375960 (616B) | +944/+952/+960 | |
| smoothListboxType (507) | CListboxType 同 ctor | +968/+976/+984 | 标志位区分 |
| windowType (155) | CWindowType 0x1422F5A80 (1136B) | +920/+928/+936 | 嵌套窗口 |
| OverlappingElementsBoxType (334) | COverlappingElementsBoxType 0x1423775F0 (304B) | +1016/+1024/+1032 | 兜底分支同 |

其余 Type 键表 (token→偏移; 全部 writer 空桩):

| Type | 键表 |
|---|---|
| CButtonType | font(30)/origo(102)/buttonFont(174) 三键同槽→+336 串 / spriteType(54)/quadTextureSprite(132)→+432 / position(76)→+648 u32 对 / size(47)→+704 u32 对 / scale(93)→+724 f32 / rotation(342)→+720 f32 / format(114)→+712 枚举 (left115=0 / right116=1 / centre117 与 center50=2) / upSprite(128)→+272 / downSprite(129)→+304 / overSprite(131)→+368 / dissableSprite(130)→+400 (引擎原拼写) / parent(135)→+464 / text(143)/buttonText(173)→+616 / borderSize(134)→+728 u32 对 / orientation(194)→+656 串 / frame(252)→+736 i32 / upsound(281)→+848 / downsound(282)→+816 / oversound(283)→+744 / clicksound(284)→+776 (值="none" 置 +808=1 并清空) / no_clicksound(585)→+808 / shortcut(289)→+528 结构 (sub_141264520) / luaClick(335)→+496 / callback_type(649)→+552 / callback_argument(650)→+584 / web_link(651)→+552 写死常量+584 读参数 / vertical_alignment(601)→+716 枚举 / centerPosition(578)→+741 / multiline(719)→+740 / alwaystransparent(470)→+880 / enabled(705)→+881 / open_browser(715) 弃用告警 |
| CCurveGraphType | position(76)→+240 / size(47)→+248 / spriteType(54)→+256 |
| CDropDownBoxType (404B 级) | name(27) 显式委派基 / position(76)→+240 复合块 (sub_142303C90) / expandButton(642)→+304 CButtonType\* (malloc 888B, 重复报错) / expandedWindow(643)→+312 CContainerWindowType\* (malloc 1432B) / clipping(631)→+332 / contractOnLeave(644)→+330 / hideHeaderOnExpand(645)→+329 / expandedOnTop(646)→+328 / switch_frame_on_expand(749)→+331 五 u8 / verticalScrollbar(161)/horizontalScrollbar(162) 与动画/滚动条簇 8 键 (398..628) = sub_1424C2060 读弃 / default 委派 +320 容器 vt[4] |
| CDropDownMenuType (424B 级自段 +240..+488; 多基 CFactory md+240) | parent(135)→+248 / dropDown(183)→+312 / heading(184)→+344 串 / position(76)→+376 u32 对 / priority(141)→+392 f32 / orientation(194)→+488 SSO 串 |
| CEditBoxType (384B; vt[7]=0x142372F70 族内唯一 [7] 覆写) | textureFile(37)→+240 / font(30)→+272 / text(143)→+304 串 / position(76)→+336 / size(47)→+344 (负值报错) / borderSize(134)→+352 u32 对 / cursor(397)→+360 u32 对 / orientation(194)→+368 枚举 (串→0x1422F9B20) / instantTextBoxType(288)→+372 bit1 / ignore_tab_navigation(587)→+372 bit0 / use_special_chars(687)→+372 bit2 / only_numbers(710)→+372 bit3 / ignore_enter(723)→+372 bit4 (bool→位写入) / is_multiline(745)→+376 |
| CExtendedScrollbarType (自段至 +500; Child CButtonType ctor 宿主参数对 +392/+400) | position(76)→+240 复合块 / size(47)→+288 / tileSize(640)→+340 (sub_142304060) / background(156)→+408 / track(139)→+416 / slider(138)→+424 / increaseButton(638)→+432 / decreaseButton(639)→+440 五 CButtonType\* (各重复报错; 报错串误写 scrollbarType/containerWindowType 名, 引擎原样) / maxValue(150)→+448 / minValue(149)→+456 / stepSize(151)→+464 / startValue(152)→+472 / smooth_scrolling(744)→+480 i32 (sub_1424C0A70) / orientation(194)→+488 / origo(102)→+492 枚举 (0x14230E760) / horizontal(153)→+496 / lockable(285)→+497 / drag(286)→+498 / clickonly(641)→+499 / setTrackFrameOnChange(739)→+500 六 u8 |
| CGridBoxType | position(76)→+240 / size(47)→+288 / slotsize(619)→+340 复合块 / padding(618)→+392 (sub_142303980) / background(156)→+432 CButtonType\* (建时拷 name+72 与行号+224) / max_slots(615)→+440/+444 u32 对 (= max_slots_horizontal(617)→+440 / max_slots_vertical(616)→+444) / format(114)→+448 枚举 (串→0x142375060, 值=7 非法回置 0) / orientation(194)→+452 枚举 (upper_left632=0..center_down637=8; token 15 → 0x1423743D0 表达式) / add_horizontal(614)→+456 |
| CIconType (元素工厂 vt[13]=0x14236D6C0 → malloc 352B + 元素 ctor 0x1422FACA0) | font(30)/text(143)/buttonText(173)/buttonFont(174) 四键报错 / spriteType(54)/quadTextureSprite(132)/buttonMesh(172) 三键同槽→+256 / position(76)→+288/+292 f32 对 +296=0 +316=1 (2D 路径) / 3dposition(175)→+288 起 (0x140ADDCA0 复合读, +316=0) / scale(93)→+300 f32 / orientation(194)→+304 枚举 / frame(252)→+308 i32 / rotation(342)→+312 f32 / allwaystransparent(319/470)→+317 / centerPosition(578)→+318 / center_on_anchor(751)→+319 u8 |
| CInstantTextBoxType (464B) | textureFile(37) 吞键 / size(47) 弃用告警 ("use maxWidth and maxHeight") / font(30)→+248 / text(143)→+280 / orientation(194)→+384 串 / scrollbarType(140)→+432 串 / maxWidth(145)→+348 / maxHeight(144)→+352 (sub_1424C0900 i32 对) / position(76)→+356 / borderSize(134)→+364 u32 对 / fixedsize(176)→+372 / truncate(197)→+373 / multiline(719)→+374 / text_color_code(660)→+345 单字符校验 / format(114)→+416 枚举 / vertical_alignment(601)→+420 枚举 / allwaystransparent(319/470)→+424 / ignore_special_chars(716)→+425 / context_aware_text(795)/bound_text(797)→+312 绑定串 (互斥, 置 +344=1) |
| CLayoutType (positionType 库形态) | 唯一键 positionType(178) → malloc 256B 建 **CPositionType** (vt 0x142B4BA20, ctor 0x1422FD670, 键 position(76)→+240 / scale(93)→+248 f32) → 嵌套 Parse → 按名插 +240 CTernary 容器 (容器 vt[48] 插入槽); 余键回落基 |
| CListboxType | orientation(194)→+248 / parent(135)→+280 / background(156)→+312 / dropDown(183)→+344 / heading(184)→+376 串 / position(76)→+412 / offset(314)→+420 / size(47)→+428 / borderSize(134)→+436 u32 对 / priority(141)→+444 f32 / step(186)/spacing(272) 双键同槽→+536 i32 / horizontal(153)→+540 / scrollbarType(140)→+544 / membername(273)→+576 串 / scrollbar_side(656)→+408 枚举 (left=0/right=1) / allwaystransparent(319/470)→+608 / clipping(631)→+609 u8 |
| COverlappingElementsBoxType | parent(135)→+240 串 / position(76)→+272 / size(47)→+280 u32 对 / orientation(194)→+288 枚举 / format(114)→+292 枚举 (center50=0/right116=1/left115=2/up108=3/down798=4, 非法报错串定案) / spacing(272)→+296 i32 / first_on_top(371)→+300 u8 |
| CScrollbarType (672B; 基含 CFactory md+240) | slider(138)→+248 / track(139)→+280 / rightButton(137)→+312 / leftButton(136)→+344 / rangeLimitMinIcon(354)→+376 / rangeLimitMaxIcon(355)→+408 / parent(135)→+440 串 / position(76)→+472 / size(47)→+480 / borderSize(134)→+488 u32 对 / slider_pos_shift(773)→+496 复合块 / maxValue(150)→+504 / minValue(149)→+508 / stepSize(151)→+512 / startValue(152)→+516 / priority(141)→+520 f32 / horizontal(153)→+608 i32 / lockable(285)→+640 / drag(286)→+641 u8 / rangeLimitMin(352)→+648 / rangeLimitMax(353)→+656 fixed×1e-5 / useRangeLimit(356)→+664 u8 / scroll_speed(233)→+668 i32; guiButtonType(127)/buttontype(625) 双键同路建子件 |
| CRadioButtonGroupType | radioButton(159)→+248/+256/+264 链表 (每键 malloc 56B 节点) / parent(135)→+272 串 (slot[11] 回吐空 SSO, reader 直写) / priority(141)→+304 i32 对 / guiButtonType(127) 经 +320 工厂 vtable+16 造子件挂 +328 插入器 |
| CRadioScrollbarGroupType | radioScrollbar(164)→+248/+256/+264 链表 / parent(135)→+272 / priority(141)→+304 / +312/+320 引用对传子件 ctor / scrollbarType(140)→CScrollbarType 子件 (+328 插入器) |
| CTextBoxType (432B) | borderSize(134)→+240 u32 对 / textureFile(37)→+248 / font(30)→+280 / text(143)→+312 串 / maxWidth(145)→+344 / maxHeight(144)→+348 i32 / position(76)→+352 u32 对 / fixedsize(176)→+360 u8 / orientation(194)→+368 串 (存串不映射) / format(114)→+400 枚举按字面量首字符 (s=0/t=1/u=2) / textblock(261)→+408/+416/+424 链表 (每项 malloc 144B CTextBlock, ctor 0x1422D5230) |
| CLineChartType (25 槽, C2dObjectType 链, serfam 命中; 元素工厂 slot[23]=0x1423207D0 → malloc 448B CLineChart ctor 0x142307AC0) | name(27)→+16 / loadType(293)→+64 枚举 / norefcount(294)→+68 (基 reader 0x142355FD0) / size(47)→+80 u32 对 / effectFile(90)→+88 串 / linewidth(361)→+120 f32 (`(int)v/100000.0*0.5`) |

元素族名录 (全非 CPersistent 不可序列化):

| 类 | vt (主表) | 槽数 | 基链/次表 | 一句话 |
|---|---|---|---|---|
| CCheckBox | 0x142B465D8 (+次 0x142B46868) | 81 | CGuiObject ← TCollisionObserver (+CCheckBoxObservable md+128) | 复选框 widget (checkBoxType 196) |
| CDropDownBox | 0x142B4C7E8 | 79 | CGuiObject | 下拉框 widget |
| CEditBox | 0x142B4A940 (+次 0x142B4ABD0) | 81 | TEditBox ← CGuiObject (+CTextBuffer/CTextBufferObservable md+128, +CTextInputReceiver md+416) | 文本输入框, 文本缓冲/输入接收双多基面 |
| CExtendedScrollbar | 0x142B49DB0 (+次 0x142B4A030 / 0x142B4A0C0) | 79 | CGuiObject (+TScrollbar/CScrollbarObservable md+128, +CDefaultButtonObserver md+176) | 带增减按钮滚动条, 三虚表面 |
| CGridBoxBase | 0x142B487B0 | 79 | CGuiObject | 网格盒抽象基 ([77][78] _purecall, 不独立实例化) |
| CInstantTextBox | 0x142B468C8 | 84 | CGuiObject | 即时文本框 widget |
| CCurveGraph | 0x142B4FC30 | 79 | CGuiObject (+CLostDeviceInterface 虚基) | 曲线图 widget |
| CButtonDrag | 0x142B4CC50 (+次 0x142B4CFD8) | 112 | CButton ← TButton ← CGuiObject (+CButtonObservable md+128) | 可拖拽按钮变体 |
| CCallbackButtonStandard | 0x142B476C0 (+次 0x142B47A70) | 117 | CButtonStandard ← CButton ← TButton | 回调标准按钮 (族内最大槽数) |
| CLineChart | 0x142B4D068 | 88 | C2dVisibleObject ← C2dObject | 折线图 (2d 元素系非 CGuiObject 系) |
| CScrollbar | 0x142B42520 (次表 0x142B427B0 TScrollbar 17 槽 / 0x142B42840 按钮观察器 12 槽) | 81 | CGuiObject + TScrollbar@128 + CDefaultButtonObserver@176 | 滚动条元素 (三基三虚表) |
| CStandardlistbox | 0x142B43908 模板面 (次表 0x142B43A38 CGuiObject 面 79 槽) | 37 | CFixedMaxSizeListbox ← CSimpleListbox ← CListbox ← TListbox ← TChoice | 定高列表框, 二层虚表 |
| CSmoothListbox | 0x142B4C3F8 模板面 (次表 0x142B4C4F0 79 槽) | 30 | 同链 + IButtonEventFilter@288 | 平滑列表框 |
| CTextBox | 0x142B421D8 | 81 | TTextBox ← CGuiObject | 文本框元素 (行为全在基段) |
| TTextBox | 0x142B41F50 | 80 | CGuiObject | 文本框抽象基 (7 纯虚槽, 排除) |
| TEditBox | 0x142B4A6C0 | 79 | CGuiObject | 编辑框抽象基 (同形少一尾槽, 排除) |
| COverlappingElementsBox | 0x142B5A3F0 | 96 | TOverlappingElementsBox\<CStandardlistboxItem\> ← CGuiObject | 重叠元素盒 (元素层虚槽最多者之一) |
| CKeyBoard | 0x142B3C900 (+次 0x142B3C950 md+48) | 9 | CKeyPressedObservable ← CObservable (+CKeyReleasedObservable md+48) | 键盘事件 observable 基座 (排除) |
| CKeyPressedObservable | 0x142B3C888 | 4 | CObservable ← TObservable | 按键事件基 (排除) |

观察器族 (notificationinterface.h 同模板实例, 4 槽 = dtor/AddObserver/RemoveObserver/**GetClassObservable**; 对象内布局 = +8 头/+16 尾/+24 计数/+28 通知旗/+40 计数挂钩旗, 观察器子对象 48B): CWindowObservable (0x142B58628, [3]→qword_143481138) / CMouseButtonPressedObservable (0x142B511E8, →0x1434524A0) / CMouseButtonReleasedObservable (0x142B51260, →0x1434524B0) / CMouseDoubleClickObservable (0x142B512D8, →0x1434524C0) / CMouseMovedObservable (0x142B51350, →0x1434524D0); AddObserver 惰性删/即删双路 (+28 通知旗分流), debug 断言 `_ObserverList.Contains==false` (notificationinterface.h:64)。**CMouse** (游戏层接口, vt 0x142B513C8 主 33 槽 + 4 次表 @48/96/144/192; 5 观察器子对象各占 48B; [9]=0x140FDCB00 回吐 **+240 u32 = 当前光标档位索引** — setter = CPdxMouse 槽[4] sub_142384DA0 (`if (*(u32*)(a1+240) != a2 || !*(u32*)(a1+240)) { *(u32*)(a1+240) = a2; return sub_142258040(a1 + 8*a2 + 336); }`), sub_142258040 = `SetCursor(*a1)`; **+336 起 = HCURSOR 数组 (39 档, 0x138B)**, 装载器 sub_142384860 = memset + 循环 LoadCursorFromFileA, 失败回落 LoadCursorA(0, 0x7F00) IDC_ARROW): 平台实现 = CPdxMouse (§4.00.9)。**CTouchDevice** (0x142B3C768, 5 槽根接口 [1..4] 全纯虚) → CPdxTouchDevice (§4.00.9)。

> **[3] GetClassObservable (定案)**: 回吐本 observable 类的**类级单例指针** (双面对象 {CObservable 广播面@0, TObservable 观察者面@48}, RTTI 实名 `VCWindowClassObservable`/`VCMouseButtonPressedClassObservable` 系); @48 观察者面本身登记进各实例观察者链表。通知派发 (Broadcast 0x1422AFA70) 只走实例链表**不消费 [3]**; 锚仅服务 ① 类级订阅点 ② 单例生命周期收尾 (末实例 dtor 按 count==1 注销 @48 面并删单例)。锚族全景 = 16B 记录 {u32 计数; pad; qword 锚}: mouse pressed/released/double click/moved/wheel = dword_143452498/A8/B8/C8/D8 配 qword_1434524A0/B0/C0/D0/E0, window dword_143481134/qword_143481138, scrollbar qword_1434810E0, sessioninfo qword_143453170, textbuffer qword_1434813A8; 类计数 = 存活实例数 + 挂钩旗实例的登记净值 (锚−8)。**锚写入点机制定案 = 类级单例 ctor 一次性写入** (写点 = 各 observable 类 `TObservable<...>::[1]` AddObserver 内联块, 非独立函数, 故按函数名扫必落空; 以 CMouseButtonPressedObservable vt 0x142B511E8 为例: 其 [1] = sub_142230980, 体内 `if (*(BYTE*)(a1+40)) ++dword_143452498;` 与 `--dword_143452498; if (qword_1434524A0 && v3 == 1) {…注销 @48 面 + 删单例…}`); 全 15 锚引用形态为 `inc/dec/mov eax [rip+…]` 三类, **无一锚存在 `mov [rip+d], imm/reg` 型绝对写** ⇒ 「间接写」成立 (更准确说法 = 类级单例 ctor 经 this 相对写); 未安装时 [3] 回吐 null, 派发与 dtor 判空兼容。

> 1.19.3 解析语义为**全键落槽** (frame/hide/enabled/is_multiline/scrollbar 四值/lockable/drag/clipping 等约 30 键在旧版为读弃键, 现均有真落槽); scale(93)/rotation(342)/priority(141) = f32, CDropDownMenuType orientation(194) = SSO 串 — 以本族键表为准。
> 读侧 helper 增量 (本节新增, 与 §4.30.31 既有表互补): sub_1402C7E70 = i32 对双 dword 直写 / sub_1424C0A70 = 数值→i32 / sub_1424C2060 = 读弃 / sub_142303C90 = position 复合块 setter / sub_142304060 = size 复合块 setter / sub_142303980 = padding 复合块 setter / sub_14230E760 / sub_1422F9B20 / sub_142375060 = 三枚枚举串→u32 (scrollbar 系 / orientation 系 / gridbox format) / sub_14239E3E0 = 串池化 intern (tooltip 系落 8B 指针槽) / sub_141264520 = shortcut 结构转换 / sub_1423743D0 = gridbox orientation 表达式解析。

#### 4.30.33 装备设计器 / 市场 GUI 对象 (CEquipmentVariantBuilder / CEquipmentType)

定名与锚点总表:

| 对象 | 锚 / 定名 | 语义 |
|---|---|---|
| CEquipmentVariantBuilder | 8800B (equipmentvariantbuilder.cpp 断言实名); 双内嵌 CEquipmentDesignerView +14232 (主编辑) / +23032 (母本对照); SetTarget = 自由函数 sub_141788C50 | 设计器主编辑器; 布局见下表 |
| CEquipmentType | — | 装备类型 def; 布局见下表 |
| dword_143333C2C | = NAir::MAX_QUICK_WING_SELECTION (定案) | 快速翼选择上限 |
| CAIEquipmentDesignEntry | 0x1138B | 历史设计条目: +552/+5544/+556 消费 (HISTORICAL_PRESET 特例; 文件夹过滤 view+74064/+74104); 条目内部未决 |
| qword_14332EEC0 | = common/units/equipment DB {items@+128, 计@+140} | 后勤装备行集全 archetype 遍历 |
| qword_14332F088 | = common/resources DB | 贸易资源行集: def+16 启用旗 / def+216 = 资源行号 i32 (rs 数组索引) / def+224 = 换算分母 10000000000/x |
| CMarketStockpile | EPool@+56 {data@+88, 计@+100} | 库存行集; 相关命令见下表 |

CEquipmentVariantBuilder (8800B; 重锚后 15/15 布局字段零漂移):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 匿名结构 (1656B 形状) | 三预览之一（未名用途，重算 = sub_14193DFB0(preview, 快照, …)） |
| +1664 | 匿名结构 (NNB 形状) | 三预览之二（getter 0xE6F0） |
| +3320 | 匿名结构 (NNB 形状) | 三预览之三（getter 0xE740） |
| +4976 | — | 变体镜像 #1 (与 +6184 双拷贝) |
| +5004 | u32 | **creator tag**（SetCreator = sub_141491EB0(builder, tag)；玩家 tag 经 qword_14332F260+1312/1316） |
| +5992 | CEquipmentVariant* | **draft.parent = "pRefVariant"**（断言 0x13F；LoadVariant 置为 draftB） |
| +6008 | u64 | draft._Category 位掩码（四比对 = sub_141490F10，parent+1032 对照） |
| +6136 | id 对 | design team 槽（setter sub_1414925D0；与 parent 比对） |
| +6144 | NIndustrialOrganisation::CTraitBonus | design team bonus 内嵌 |
| +6184 | — | 变体镜像 #2 |
| +7392 | — | parent 镜像 |
| +8600 | u8 | **活动侧选择旗**（E720: 0→+4976, ≠0→+7392；编辑前若置位则 B 拷回 A 并清旗；getter sub_141490A30） |
| +8604 | u8 | LoadVariant 清理位（sub_141491500 同序清 +8600/+8712/+8604） |
| +8608 | 匿名结构 (元素待裁) 向量 | 未名三容器之一（16B 记录、count@+8620；dtor 群） |
| +8632 | CEquipmentUpgradesInstance | 三通道设/复位/自动 (builder 4803D0/F120/D240; 国别上限 sub_141537940) |
| +8664 | 匿名结构 (元素待裁) 向量 | 未名三容器之二 |
| +8688 | 匿名结构 (元素待裁) 向量 | 未名三容器之三 |
| +8712 | u8 | 预览重算门之一（sub_141492970: !+8713 && +8712 → 重算 +1664） |
| +8713 | u8 | 预览重算门之二 |
| +8720 | qword | design team ref 缓存 |
| +8736 | NIndustrialOrganisation::CTraitBonus | 第二 design team bonus 内嵌（容器@+8736） |
| +8768 | id 对 {type,id} | **参考变体 id 对**（E700: 双非零才 sub_14220A3D0 解析；E670 失败回退 E535D0(ps, arch, tag) 按原型找现役；哨兵 qword_14333D528） |
| +8776 | 匿名结构 (元素待裁) 向量 | **槽-模块编辑表**（装/拆模块 builder 0xFEE0/0xD3C0 落草稿 draft+184；LoadVariant 全表重建；{cap@+8784, count@+8788, alloc@+8792}） |

草稿 draft (builder 内草稿对象):

| draft+N | 类型 | 名称/语义 |
|---|---|---|
| draft+40 | SSO | name |
| draft+184 | 匿名结构 (元素待裁) 向量 | modules |
| draft+580 | — | niche |

CEquipmentType:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | — | 类型名 (blueprint TYPE 参) |
| +112 | 匿名结构 (元素待裁) 向量 | 80B 槽表 (槽 id@+8; 行池按 token "fixed_" 前缀分池; equipment_designer_module_slot_entry) |
| +320 | — | 类别枚举 = **interface_overview_category_index** (airwingreorganizationview.cpp:0xEC 断言实名; 账本机种计数行 TARGET_HAS_CATEGORY_\<n\> 键; 负值时消费端沿 +1240 父链上溯取首个非负, sub_140C95880) |
| +784 | 匿名结构 (元素待裁) 向量 | 变体容器 |
| +960 | — | 图标 |
| +968 | — | GFX 图标串部件 |
| +988 | token | `group_by` 脚本键值 (vt[4] KV 分发 case 13022, 默认 357 = "none"; 后勤特判行键) |
| +992 | token | interface_category |
| +997 | u8 | 类型有效旗 (has_design_based_on 变体过滤第二门; 推定) |
| +1000 | u8 | 舰载机字节 (显隐门) |
| +1240 | — | 父 archetype 链 (reader token 12103 = archetype 挂接; 后勤行域谓词按父链 + 掩码@+1344 分 land/naval/air) |
| +1344 | u64 | **类别位图掩码** (reader token 225 = type 逐类别 token OR 入, mapper sub_140F88330 全解码见下表; 缓存 +312) |
| +1365 | u8 | 停止字节 (reader/谓词两处门) |

+1344 类别位图 (token → 位; mapper sub_140F88330, 包装 sub_140F8B020/0X140F8B070;
同图源被徽章 niche 分发与联队资格掩码复用 — 0x1F0037FC00 = 空军联队资格超掩码 /
0x80004003C1 = 海军族 / 0x408000003C = 陆军族):

| 位值 | 类别 token | 位值 | 类别 token |
|---|---|---|---|
| 0x1 | convoy | 0x200000 | maritime_patrol_plane |
| 0x4 | armor | 0x400000 | carrier |
| 0x8 | motorized | 0x800000 | (token 0) |
| 0x10 | mechanized | 0x100000 | air_transport |
| 0x20 | infantry | 0x2000000 | flame |
| 0x40 | capital_ship | 0x4000000 | amphibious |
| 0x80 | submarine | 0x8000000 | anti_air |
| 0x100 | screen_ship | 0x10000000 | artillery |
| 0x200 | floating_harbor | 0x20000000 | anti_tank |
| 0x400 | fighter | 0x40000000 | rocket |
| 0x800 | interceptor | 0x80000000 | train |
| 0x1000 | tactical_bomber | 0x100000000 | heavy_fighter |
| 0x2000 | strategic_bomber | 0x200000000 | emplacement_gun_ammo |
| 0x4000 | cas | 0x400000000 | ballistic_missile |
| 0x8000 | naval_bomber | 0x800000000 | nuclear_missile |
| 0x10000 | missile | 0x1000000000 | sam_missile |
| 0x20000 | suicide | 0x2000000000 | missile_launcher |
| 0x40000 | scout_plane | 0x4000000000 | land_cruiser |
| 0x80000 | railway_gun | 0x8000000000 | support_ship |
| 0x1000000 | support | 0 | unknown |

> 市场可交易门 (NMarketCore::IsTradable, market_stockpile.cpp): `IsTradable = !A(variant) ∧ (¬海军族(B) ∨ variant+1032 ∧ 0x1)` — **海军族装备须带 convoy 位才可交易** (即海军侧只有护航船设计可上架); 类别规整器 sub_140F8B020 使 capital_ship 掩码清 {convoy, submarine, screen_ship}、submarine 清 {convoy, screen_ship}、screen_ship 清 {convoy} — convoy 位与具体舰种位互斥, 战舰设计天然不可交易。A = DLC 类目掩码 ∧ type+1366 门 ∧ variant+1054 旗 — **+1054 = is_frame** (writer sub_140BE3C80 发 tok 11165; IsTradable 链 sub_1413BB220→sub_140BDE100), 即「frame 变体不可交易」。

库存行集命令 (目标对象 = CMarketStockpile / *(cc+4024)):

| 命令 | id | 载荷/语义 |
|---|---|---|
| CMarketStockpileClearCommand | 10191 | {tag@+40}; 目标 *(cc+4024) |
| EquipmentTransferCommand | 13859 | 双 64B 池载荷 +40/+104 |
| StockpiledEquipmentDeleteCommand | 14424 | 载荷 idpair@+40; Execute = 按 define `NUM_DAYS_TO_FULLY_DELETE_STOCKPILED_EQUIPMENT` 分批删; equipment+1032 bit0 = 立即删旗 |

#### 4.30.34 市场自动化选项窗 (NInternationalMarket::CRequestAutomationOptionsWindow)

| 项 | 值 | 语义 |
|---|---|---|
| vtable | 0x142AAE4C0 | 尺寸 0x15B8B |
| 窗 | request_automation_options_window | — |
| ctor | sub_1420078B0 | 宿主 = CMarketOverviewPanelController (ctor sub_141F8A970; target = 控制器上下文+64 → win+1440) |
| Refresh | 虚槽 [6] = 0X142007E20 | 初态 = val+1 |
| 提交命令 | CSetMarketRequestAutomationOptionsCommand (vt 0x142A3F8F0, sub_141B1BA00) | cmd+40 = *(*(target)+8) = 请求 id u32; cmd+44/+46 = 旗 |

target 三 bool ↔ 三 checkbox:

| 偏移 (target) | 类型 | 名称/语义 | UI |
|---|---|---|---|
| +32 | bool | 自动接受市场准入 | checkbox auto_accept_market_access |
| +33 | bool | 自动发送市场准入 | checkbox auto_send_market_access |
| +34 | bool | 自动接受购买 | checkbox auto_accept_purchase |

三 lambda 统一投 CSetMarketRequestAutomationOptionsCommand。

target 句柄形: *(target) 指向含 id@+8 的对象; 类定名未决 (推定请求管理器条目)。

#### 4.30.35 活跃合同控制器 (CActiveContractsUiController)

| 项 | 值 | 语义 |
|---|---|---|
| RTTI | 无自身 RTTI/vt (仅 lambda 有 TD) | — |
| 布局 | 32B | — |
| target | 宿主 CMarketOverviewPanelController+8 对象 | +104 国 ref / +112 mkt |
| 数据源 | mkt by_buyer@+72 / by_seller@+48 索引双路 | 合同 +88 seller / +92 buyer / +104 equipments pool1 / +472 delivery_state 四锚互证 |
| 行类 | CPurchaseContractEntry (0x640B), 窗 active_purchase_contract_entry | 类别分组器 sub_140FCC870 |
| 取消链 | 取消确认弹窗链 → CCancelEquipmentPurchaseAction (0x88B) | — |

#### 4.30.36 外交贸易/租借行件 GUI 族 (CDiplomacyTradeItem / CDiplomacyIncomingLendLeaseItem / CDiplomacyRequestIncomingLendLeaseItem)

| 类 | target 形态 | 锚点 |
|---|---|---|
| CDiplomacyTradeItem (diplomacy_trade_entry; 零覆写 Item 族) | +56 = 贸易对象 (**无 RTTI 类: +8 资源 id / +16 注册标志 / +220 图标 frame**) | tooltip = HEADER / TRADE_PRODUCED(+64) / TRADE_IMPORTED / TRADE_EXPORTED(+32 数量记录); 无按钮 |
| CDiplomacyIncomingLendLeaseItem (diplomacy_incoming_lend_lease_entry) | **+1368 = CEquipmentVariant\* (variant+1008 _pType ✓) / +1376 = is_fuel / +40 = 模式枚举** | tooltip = DIPLOMACY_LEND_LEASE_EQUIPMENT_TOOLTIP (PRODUCING/STORAGE); cancel_button 仅翻转选中 (+1377), 真命令在 controller 侧 |
| CDiplomacyRequestIncomingLendLeaseItem (diplomacy_request_incoming_lend_lease_entry; tooltip 槽 = ret0 桩) | **+1360 = deal 对象 (+24 内嵌 def, CPurchaseRequest 形态 ✓)** | equipment_name/deal_state 两元素; cancel → controller 0X141C95400 摘行 |

#### 4.30.37 市场上架/准入/要约/下架 GUI 族 (CAddEquipmentToMarketWindow / CAddToMarketEquipmentItem / CMarketAccessOverviewWindow / CMarketAccessOverviewItem / CTradeOfferWindow / CCancelSellingContractPopup / CIncomingLendLeaseEquipmentItem)

**CMarketStockpileWindow 布局五槽**: +136 CCountry\* / +144 CMarketStockpile\* / +2928 上架窗缓存 / +5120 另一窗缓存 / +7896 弹窗向量。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CAddEquipmentToMarketWindow (vt 0x142AB62B0, CPopUpWindow, 6528B) | **win+1440 CMarketStockpile\* + win+1448 CCountry\* 卖方** (stockpile+104 复证) | 宿主 = CMarketStockpileWindow (lambda 名铁证); add_button 恒投 **CMarketStockpileEquipmentTransferCommand {+40/+104 双 64B 池 / +168 卖方 tag, id 13859 ✓}**; 价格档有差时加投 **COverrideMarketEquipmentPriceLevelsCommand {+40 tag / +48 map, id 14010 ✓}** |
| CAddToMarketEquipmentItem (vt 0x142AB6170, 25 槽, 基 CMarketEquipmentItem) | 基存 **SMarketEquipmentData 72B@+40** + 自建数量组件 0xC08@+1616 / 价格档组件 0x1078@+1624 (两组件尺寸命中 §4.31.15 ✓) | 覆写 [22] IsSelected (推定) / [23] GetAmount / [24] GetPriceLevel |
| CMarketAccessOverviewWindow (vt 0x142AADE80, 1536B) | 宿主 = CMarketOverviewPanelController (§4.30.34 同宿主 ✓) | [11] 枚举 **gs+784 全国 × 关系过滤** (国+3976, 类型 26 推定 = 市场准入) 生按国行; 内嵌 CCancelMarketAccessPoup@+1480; 确认出口 = **CRequestMarketAccessRightsAction {+120 = 1 撤销旗}** |
| CMarketAccessOverviewItem (vt 0x142aae070, 零覆写 2792B) | **+2784 对方 tag / +2788 自体 tag** | 行 = 国旗/国名 + cancel_market_access_button (状态门 (state-1)>2 禁撤) + open_diplomacy_button (窗型 9 定位对方国) |
| CTradeOfferWindow (vt 0X142A60F58, **CReloadableInterface 非弹窗**, 4152B) | 挂 **CCountryTradeView+7952** | send → **CCreateTradeCommand {+40 对方 tag / +44 自体 tag / +48 = tradeview+7944 资源 id / +56 量}**; 超运力走 default_confirmation_popup 延后派发 |
| CCancelSellingContractPopup (vt 0x142AAE7E0, CDefaultConfirmationPopUpWindow, 4208B) | **卖方侧下架确认** (对照 §4.31.15 买方侧 CCancelEquipmentPurchaseAction) | 全删 → **CMarketStockpileClearCommand {+40 tag, id 10191 ✓}**; 单条 → 同 CMarketStockpileEquipmentTransferCommand |
| CIncomingLendLeaseEquipmentItem (vt 0X142A93368, 零覆写 1384B) | **CDiplomacyIncomingLendLeaseActionController+9168 网格的装备行** (与 §4.30.36 按国行 CDiplomacyIncomingLendLeaseItem 划清边界) | setter sub_141F2BE90 填 name/in_pool/producing + 舰载机图标门 (**元素+1000 ✓**); 点击 → 取/建 CDiplomacyRequestIncomingLendLeaseItem 进请求列表 |

#### 4.30.38 CMapModeManager (全地图模式管理器; 情报账本 = mode 30)

ctor sub_140DFCD30 全布局 (qword_14333CFB8 = 本类实名, 见 §4.11.10):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | — | 当前 mode id | −1 初值; 30 = 情报账本 |
| +16 | shared_ptr | 当前 mode 实例 — ptr | 与 +24 成对 {ptr, ctrl}; sub_140DFD540 = 原子增引→调 lambda→释放 |
| +24 | shared_ptr | 当前 mode 实例 — ctrl | 同上 |
| +48 | 匿名结构 (23 槽×0x88) | per-mode 缓存 | NotifyProvinceChanged 经 sub_140F31B50(+48 缓存, prov+164) 标脏 |
| +64 | — | tag 观察者 hub | |
| +72 | — | context | |
| +96 | — | 子对象 sub_140A9A0F0 | |
| +144 | CVector | — | |
| +176 | tween 结构 | 双 tween 结构之一 | 0.7f 初值; mode 切换淡入淡出 (推定) |
| +208 | tween 结构 | 双 tween 结构之一 | 同上 |
| +232 | CVector | — | |
| +272 | — | 事件门旗 | |

NotifyProvinceChanged sub_140E168F0 (流程): 门旗+272 → prov+392 变体 →
sub_140F31B50(+48 缓存, prov+164) 标脏 + hub 通知。

mode id 表:

| 值 | 名称 | 语义 |
|---|---|---|
| 20 | MilitaryDeployment | — |
| 21 | ToOrder | — |
| 29 | OperationSelectTarget | — |
| 30 | 情报账本 | 情报页地图着色 (§4.18 GUI 消费节) |

#### 4.30.39 CPanelController (左右面板控制器; ctor sub_142061510; 176B; 通用控件, 现见空军重组窗)

Reorg 左右面板; 无自有 RTTI; 断言 panel_controller.cpp L0x67/L0x76;
OnOpen malloc×2 (+4320=side0 / +4328=side1), OnClose sub_142061960 销毁;
填充 = sub_142061E90 / sub_142061CA0。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | 窗回指 | |
| +8 | u8 | _Side | 0=LEFT, 1=RIGHT |
| +16 | — | 行原型名 | |
| +48 | — | 行池 | |
| +72 | — | 行池 | |
| +96 | — | list 柄 (list_left·list·list_right 柄区) | 柄 @+96/+104 |
| +104 | — | list 柄 | |
| +112 | — | 滚条观察 glue | |
| +168 | — | 堆回指格 | |
| +4320 | 匿名结构 (NNB 形状)* | side0 面板 | OnOpen malloc; OnClose 销毁 |
| +4328 | 匿名结构 (NNB 形状)* | side1 面板 | 同上 |

#### 4.30.40 NFactions::NUi::CFactionSetupWindow (创建阵营终窗, 0x21F0 = 8688B)

view#21 (faction_setup_window; CCountryView 17 槽族); ⚠
CLegacyCreateFactionWindow = 无 DLC50 时 view#12+31704 的备胎
(CNewFactionWindow@+31696 同槽替身)。

| 项 | 值 |
|---|---|
| vtable | 0x142A08548 / @+48 0x142A085F0 |
| ctor | sub_141821CD0 |

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1408 | — | 按钮胶水 #1（sub_140B77E10 构造） |
| +2776 | — | 按钮胶水 #2 |
| +4144 | — | 按钮胶水 #3 |
| +5512 | — | 按钮胶水 #4 |
| +6880 | — | 按钮胶水 #5 |
| +8248 | — | template (SetTemplate sub_141825EA0) |
| +8312 | — | CInviteCountriesWindow (RTTI 实名; 0xBA0, ctor sub_141ADA950, 工厂 = 管理器+1272) |
| +8320 | — | CFactionIconWindow (RTTI 实名; 0xB70, ctor sub_141E2EF10) |
| +8328 | — | CFactionColorPickerWindow (RTTI 实名; 0xBE0, ctor sub_141E2EC40) |
| +8248..+8336 | — | 十二窗柄清零区 |
| +8344 | CTextBufferObserverGlue | {vt, self@+8352}（cb sub_141825320） |
| +8520 | CCheckBoxObserverGlue | {vt, self@+8528}（cb sub_141824BF0） |
| +8632 | — | （SetupDerived 区） |
| +8640 | — | （SetupDerived 区） |
| +8648 | — | （SetupDerived 区） |
| +8656 | MSVC 串 | cap@+8680=15 |

> 主虚表槽：[0] dtor sub_141822BC0 / [14] SetupDerived sub_141825EF0；rebuild = sub_141825570（SetupDerived 内 `if(a1[1031])`）；create_faction 后续 lambda = sub_141584EC0。sizeof 0x21F0=8688 恰合。
> **兄弟 CNewFactionWindow**（同槽替身，ctor 0x141822830）：+104/+1472 按钮胶水（sub_140B77E10）、+2840/+2848=0、**+2856 CCheckBoxObserverGlue\<CNewFactionWindow\> {vt, self@+2864, cb@+2872 = sub_141825530}**、+2880..+2935 清零；槽 [4] 绑定 0x141827200 / [5] 复位 0x141823490 / **[6] 模板填充 0x1418282B0** / [7] 清选中 0x141825560。CLegacyCreateFactionWindow ctor = 0x141822010。

#### 4.30.41 NFactions::NUi::CFactionColorPickerWindow

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +2840 | — | template |
| +2848 | — | preset 网格宿主 |
| +2992 | CColor | 本窗色选择结果 (btn_ok 写入) |
| +3024 | — | host |

[4] SetupDerived = 0x141E2F440；preset 网格构造 = 0x141DF0210；高亮 preset = 0x141DF00A0；取色 getter（沿宗主链）= sub_1406ECF80(cc)+16 = cc+864（rgba@cc+880）；初始色源：`*(template+400)` has_color 旗 / +368 CColor 块（rgba@+384），无则玩家国 cc+880。

提交链: btn_ok 写 picker+2992 CColor → CCreateFactionCommand **+128 CColor**
(命令 +80 = icon 串, 非色) → sub_140D91E00 → **fac+2512 阵营色 (+2544 槽序)**,
不写 CCountry+848。初始色 = CFactionTemplate rgba@+384 (has_color@+400) ∥
玩家国 sub_1406ECF80(cc) 返回 +16/+32 = cc+880 rgba。

#### 4.30.42 NFactions::NUi::CRequestManpowerWindow (人力窗, 0xB78)

FactionView+1440; vtable 0x1429C4C90。上限计算 sub_14118A620 = fac+2288 池合计
sub_140D8BAD0 → sub_140C69830 + 成员 contribution(+120) + defines 基数
(loc REQUEST_FACTION_MANPOWER_VALUES); 提交
NFactions::CUseFactionMemberManpower {+40 amount / +44 tag}。

> **contribution 式（清偿定案）**: 提交门 = `(qword_143333C88 + member+120) ≥ qword_143333BD8 × 请求量`；运行时实测两全局 = 25000000 / 10000（即请求 ≤ 2500 + contribution/10000）。两全局 defines 名：**qword_143333C88 = NFactions::FACTION_CONTRIBUTION_DEBT_LIMIT**（定义件 250，注册点 dump L4523807）/ **qword_143333BD8 = NFactions::FACTION_MANPOWER_RECIEVE_CONTRIBUTION_SCALAR**（定义件 0.1，注册点 L6579219；Paradox 原拼写 RECIEVE）。

#### 4.30.43 goal/rule 过滤窗口 (CChangeGoalWindow / change_rule_window)

| 窗口 | 偏移 | 语义 |
|---|---|---|
| CChangeGoalWindow | +1664 | 槽 idx (0/1/2 = short/medium/long_term; populate sub_141C08C40 逐槽建 CFilterGoalItem) |
| CChangeGoalWindow | +1668 | 激活 goal 过滤 token (toggle sub_141F13DC0; 重选 357=none 重置; tooltip `<goal名>`_FACTION_GOAL_FILTER) |
| change_rule_window | +2848 | 当前选中规则 token (357=none 门显过滤行) |
| change_rule_window | +2896 | 激活规则过滤 token (populate sub_141C0D680, cpp:83 "show_filter_offset" 断言; tooltip `<rule名>`_filter_tooltip) |

#### 4.30.44 CRequestExpeditionariesWindow 族 (GUI)

CRequestExpeditionariesWindow:

| 项 | 值 |
|---|---|
| 窗 | expeditionary_force_container |
| ctor | sub_141D064F0 |
| populate | sub_141D07180 |
| 数据锚 | 玩家 cc → dip+656 CFaction → members {data@fac+88, count@fac+100}; 逐成员国跳过自己 |

| 偏移 (win) | 类型 | 语义 |
|---|---|---|
| +2656 | 钮 | 发送钮 (总数>0 显, DIPLOMACY_SEND) |
| +2672 | 文本 | 总计 REQUEST_EXPEDITIONARIES_DIVISIONS_COUNT |
| +2704 | 池化条目 数组 | 池化条目 {data@win+2704, top@win+2716} (24B 容器, 非多态元 — 无 vt 装配) |
| +2728 | 匿名结构 ({tag,count}) 向量 | {tag,count} 请求表 (count@win+2740; 读 sub_141D056D0 / 写 sub_141D06390) |

CRequestExpeditionariesWindowCountryEntry (vt 0X142A66348, sizeof 0x588B, ctor sub_141D05160): item+40 = CCountry* 裸指针 (非 idpair, 池复用直写)。

| 字段 | 消费点 | 用途 |
|---|---|---|
| cc+8 / cc+16 | 条目直读 | tag / 国名 |
| cc+552 CCountryAI | 可供谓词 sub_141D05EA0 → ai vt[128]; accept 意愿 sub_141D05D10 → sub_1402AA9A0 | 可供/意愿判定 |
| cc+656 | ±钮 clamp 上限 (sub_1406CF0F0 = cc+656 直返) | 师列表计数 |
| ±1/5/10 钮 | 无/shift/ctrl 修饰 (与建造页同制) | 批量步进 |

#### 4.30.45 空军重组窗消费 (ReorganizationWindow 族)

| 字段 | 消费点 | 用途 |
|---|---|---|
| 重组窗+4112 | 无活值写点 (唯二写点 = ctor sub_14202ADE0 / SetTarget sub_14202DCD0 哨兵复位) | 死字段 — 读点表明本应 = CAirWing idpair (equipment 池空查询 +456 / 增援偏好比对 +2492 reinforcement_setting; confirm 门 sub_14202EDE0 体 `+4212 byte != wing+2508`) |
| 重组窗+4120 | 同上 (ctor/SetTarget 哨兵复位含本槽) | 死字段; 哨兵值 = qword_14333D528 (0x02DF8CA00005EA66) |
| 重组窗+4192 | 零读点 | 死字段 |
| 重组窗+4200 | → 命令+152 链 (resolve(哨兵) 恒无效) | 失效链 |
| 重组窗+4336 | toggle sub_14205DD80 | 激活分类过滤 (-1=无) |
