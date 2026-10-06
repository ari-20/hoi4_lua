

### 4.30 GUI 描述 ↔ 游戏数值 映射表

> **定位**: 主视图/面板/地图模式本体的 **GUI 类布局与本册主表并列** —— 每行 = **(GUI 面板/元素,
> 取值函数) ↔ (游戏对象+偏移) ↔ (语义字段) ↔ (loc key)**; 面板/窗本体类另立小节 (见尾段 §4.30.40 起)。
> 基类槽语义 = §4.00.2/§4.00.5/§4.00.6。域对象字段仍在各分册 (本册只留视图侧入口链/坐标校准/余量账)。

**GUI 值打包原语** (取值函数与元件之间的公共下发层; 定案):

| 项 | 结论 | 证据 |
|---|---|---|
| 函数 | sub_1402E32B0 = 值打包器: 把 (GUI 变量名, 源值) 打包为栈上值对象并返回其指针; **变量名是值对象标签, 非求值键** — 源值由调用方 (各 populate worker) 直读对象偏移后传入 | sub_14174DD50 内: `v92 = *(a1[176]+56)` (= CProvince+56 victory_points) → `v33 = sub_1402E32B0(&v82, "STATE_VIEW_WICTORY_POINTS", "VALUE", &v92)` → `sub_1422CA920(v21, v33)` |
| 参数 | rcx = out 值对象 / rdx = GUI 变量名字符串 / r8 = "VALUE" 字面量 / r9 = &源值 (int32); 返回 rax = 值对象指针 | 同上调用形态 |
| 消费端 | sub_1422CA920(目标元件, 值对象) 把打包值绑定到元件 | 同上 |
| 1.19.2 对应 | +2E2E60; 全映像 `lea rdx → "STATE_VIEW_WICTORY_POINTS"` 引用唯一 (0x173ACF1, 所在函数体 ≈0x173A800 起, 内部偏移与 1.19.3 同型) | 二进制复核 |

#### 4.30.1 州面板 (CCountryStateView)

**入口链**: SetTarget vtable[11]
0X14174AA40 → **View+1408 = CProvince\* / View+1416 = *(prov+192) = CState\***;
populate worker = sub_14174ECF0 (州) / sub_14174DD50 (省) + 刷新 helper r1-r4 +
阻力填充 sub_14174E8E0; vtable[14]/vtable[15] = 窗口/行池管理 (零目标访问)。
worker 内按名取窗/元件: sub_1412374F0(a1) → vtable[+440]("state_info_window") →
vtable[+136]("victory_points_bg"); 行值经 GUI 值打包原语下发 (§4.30 头表)。

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

已结 (§4.26/§4.3 定案): 建筑 def +704 = shares_slots (13602) / +874 = always_shown (13566) / +1448 = CModifier 块; +1448 (cc+3944 = CProductionStatus 指针槽已定案 §4.8)
(共享槽基数输入); gs+992 每省 map item 族 (+32/+44 max 扫描 /
+472 状态块)、管理器 **CInGameIdler** (qword_14332F698, RTTI 实名) vtable[120] 对象 +1776 省字节表、
sub_140BB52F0 同国谓词的关系语义 — 见 §4.30.21。
已收敛: **sub_1409D8F90 = CState+2256 每国州级 modifier RH 查找 + 行追加** (id 形参;
208B 桶; 原"163/164 键"即此, 已直证 (§4.30.21: 161-164 = MODIFIER_GLOBAL/LOCAL_BUILDING_SLOTS(_FACTOR)) — 定案)。伴生: sub_140BB5490 = gs+832 表 getter
(4971 调用点)、sub_140BB47D0 = gamestate.h:1125/1126 断言门 + gs+784 国家取 (均见 §4.3/§4.1)。

#### 4.30.2 师设计面板 (CDivisionDesignerView)

**入口链**: 目标 = **「编辑会话」对象 ES** (0x908,
divisiontemplatemanager.cpp 断言实名), 存 **View+11096** — 非 CCountry/CArmy/模板本体。
SetTarget 无虚槽 (三通道: sub_14168D4C0 编辑现有 / sub_141762BC0 新建 / sub_14168B520
mode=0); Refresh = @40[9] Repopulate 0X141768250; Reload = @0[2] 0X141763770。
⚠ **基链与 CCountryView 同族不同序** (`CReloadableInterface@0` + iface@40 +
tooltip@64 + **CModelListItemParent@72**; 主vtable仅 6 槽) —— §4.00.2 的 17 槽大表
**不可跨类硬套**, 各 View 逐类解基链。

ES 要点: +0 模式枚举 / +4 国家 tag / **+8 `_pCurrentTemplateData` 草稿 CDivisionTemplateData\*** /
+16 原始快照 (内嵌 0x248) / +2256 模板 wrapper / +2264 活数据 / +600·+2280·+2288 三个统计
预览对象 (统计数组 @+160 起 8B/项按 statId 索引)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key | 置信 |
|---|---|---|---|---|---|
| 面板打开目标 (国家) | sub_141762BC0 ← 根窗 vtable[20] | ES+4 (tag) → CCountry | 设计师固定编辑属主国 (§4.3) | — | 定案 |
| 优先级按钮 0..3 | sub_14168DF80 | CDivisionTemplateData+396 | priority (§4.18), clamp dword_143337338 | TEMPLATE_PRIO_0..2(_DESC) | 定案 |
| 名字输入框 | sub_14168DF50 | D+8 SSO | name (§4.18) | DIVISION_DESIGNER_RENAME | 定案 |
| 模型覆盖名编辑框 | 0X141763F10→sub_140BA6030 | D+504 SSO | override_model (§4.18); 脏旗 view+17705 | division_designer_model | 定案 |
| 三网格摆格 | 摆格四函 2×2 = 0x14168DFA0/0x14168E150 (support +104·管理器持针/快照内联) + **0x14168E3B0**/0x14168E570 (regimental_support +136·管理器/快照) — 分格映射体读定案; 语义 = **摆格 (Set) 非拆格** (a3 = 写入元素指针), 摆后列同型化 (列头 +1444 判型, 异型整格覆写为列头指针); regiments(+72) 族 = BF90/B600/B520 (待证) | D(或快照)+72/+104/+136 | regiments/support/regimental_support (§4.18) | regiments_grid 等 | 定案 |
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

已结三项: D+488 = override_model_equipment_category_filter (tok 16902, §4.18) / cc+3952 = CDeployment* (§4.3) / 预览统计对象 = CSubUnitDefinition vftable 合成形态无独立 RTTI (CArmy+312 ctor, §4.18); 留未决: 师设计器陆军经验显示源偏移 (候选 cc+5512 CCountryExperienceStatus, 探针 = dr_watch cc+5512 对象观察 GUI 读窗); 原: CDivisionTemplateData+488 (16B getter/setter 对); CCountry+3952 (D+180 16B 条
可用性校验表); 预览统计对象类身份 (0x678B, 与 CArmy+312 同类); 陆军经验显示的源偏移。

**窗壳（重锚后零漂移，1.19.3 全址已重定）**：主 vtable **0x1429FAA00** + @40 0x1429FAA38 + @64 0x1429FAA90 + **@72 CModelListItemParent 表（1 槽）0x1429FAAA8**；视图规模 0x5CC0=23744B；注册宿主 = 装配器 0x140B614C0（注册槽 +592）；ctor **0x1417591C0**；槽：@40[7] Update = 0x141762360 / @40[8] IsOpenAndVisible = 0x141761AB0 / [9] Repopulate 0x141768250 / Reload 0x141763770 / 名字提交 0x141763F10 / tooltip 0x14175F4F0 / 新建 ES 0x141762BC0；**两控制器 +17720/+17728**（激活 0x141DD0190/0x141DD2A90，门 0x141DD01B0/0x141DD2AC0，喂食 0x141DD0320，崩溃于 @0[5]，创建于 @0[4]; +17720 控制器实名 = **CCustomIconChangeView** (2616B, ctor 0x141DCF670, 窗名 "div_templ_custom_icon_view", customiconchangeview.cpp 断言直证 — CTemplateDeploymentWindow+4024 同类双实例, §4.31.58)）；+17776/+23640 两 CEmptyEntryListBase 模板实例（ctor vtable 直证）；Conveyor 壳：ctor 0x141D83A10 / Setup 0x141D890C0（18 窗名，vtable 索引 136/104/120）/ 创建宿主 0x14172C530（sizeof 0x1AB0=6832 再证）；scoped_ref 两 helper 0x141D82170/0x141D823C0（模式号 20/21 直读）。ES 表补三行：**+2272 = 多态新建源（ctor 0x140B95230）** / **+2296 = 立即执行旗（Accept 核 0x14168D4E0 消费）** / **+2304 = ctor a3 u8**；命令 ctor 1.19.3：CSetConveyorNameCommand 0x141BA18C0 / CSetConveyorSeriesCommand 0x141BA1A90（+胶水 cb 0x141D88290/0x141D887C0）。

#### 4.30.3 生产面板 (CCountryProductionLineView)

**入口链**: **target = CCountry 本体** (根窗 vtable[20] → tag →
sub_140BB48F0 → **cc+3944 CProductionStatus 直读**, 无存储式 SetTarget/无会话对象);
vtable[11] 在本类语义转义 = 「面板开着点地图省」→ CSetNavalDeploymentTarget/
CSetShipRefitDeploymentTarget 命令 (pProvince 断言直证); 拖拽重排 = @1408
CStandardGridBox::CReorderObserver → 全表 CChangeProductionLinePriorityCommand (线+68)。
⚠ 又一「同族不同序」实例: 基座 +1408 target 锚对本类失效 (被行池占用)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 面板目标国 | vtable[20] (view+1344/+1392) → sub_140BB48F0 | CCountry (+3944 CProductionStatus) | 面板恒显窗口属主国, 无存储式 target (§4.3) | — | 定案 |
| 运营军工厂双读数 | sub_141743200→sub_14173B2D0 | ps+696 (÷1e5) − ps+760 − ps+768 / − ps+728 − ps+752 | 军工厂池 val 与两组分配 dword (§4.8 +688 池) | PRODUCTION_OPERATIONAL_FACTORIES_VALUE | 定案 (读法) / 组语义推定 |
| 造船厂读数 | sub_14173B2D0 | ps+792 (÷1e5) | 造船厂池 val (§4.8 +784 池) | dockyards_output_value | 定案 |
| production_output 值 | sub_1415C9EB0→sub_1415CA210 | cc+1464 token 0xD4/0xA8 × ps+936 | 民用池 factor<1e5 时改写输出公式 | production_output_value | 定案 (链) / 公式语义高置信 |
| dockyard output 值 | sub_1415CA060 | cc+1464 token 0xD6 + 同上 | 造船厂输出 | dockyards_output_value | 定案 (链) |
| 效率上限/增长/损失/工厂轰炸防御 | Repopulate sub_14055E360 | cc+1464 token 0xA9/0xAA/0xA5/0xD9 | country_modifiers 查表 (§4.3 +1464) | efficiency_cap/growth/loss、factory_bombing_defence_value | 定案 (读法) / token 名未定 |
| tab 使能 (tank/infantry/aircraft) | sub_141739E20 (断言实名) | ps+696 > 0 | 有军工厂才亮 | tank/infantry/aircraft_button | 定案 |
| naval tab 使能 | 同上 | ps+792 > 0 | 有造船厂才亮 | naval_button | 定案 |
| 生产线列表 | sub_14173FEA0 | ps+88 {data} / ps+100 {count} | lines 容器逐线建行 (§4.8) | production_lines/item_grid | 定案 |
| 行工厂 +/− | sub_141D5F450 → CAddProductionLineFactoriesCommand | 线+232 (现值), clamp 0..线 vtable[11] (变体._pType+1440 = CEquipmentType+1440 → 父arch+1440 → dword_143335FE0; ⚠ CEquipmentVariant sizeof 1208 < 1440, 「变体+1440」不存在) | 工厂增减, 步长 1/5/10 | increase/decrease 族 | 读法定案 / +232 语义高置信 |
| 行数量 (amount) | 0X141D5FF20 等 → CSetProductionLineAmountToProduceCommand | 线 id 对 @+8/+12; 载荷@cmd+48 | 数量提交; 变体+1208==3 走换装选择流 | — | 定案 (命令) |
| 行优先级 ▲▼ | sub_141D60520/BF70 → CChangeProductionLinePriorityCommand | 线+68 (新值 = +68+1; shift→9999) | priority (§4.8) | increase/decrease_priority | 定案 |
| 拖拽重排行 | @1408[0] 0X14173EDF0 → 同命令 | view+9200 行池 → 各线+68 全表重排; 改读 **view+9224 过滤序数组** 定位 | CReorderObserver = 批量优先级重排 | item_grid | 定案 |
| 行换装/转换 | 行 vtable[18] 0X141D61290 → CSetProductionLineConvertCommand | 门 = 线+236 u8 (= **`is_converting`**, tok 14304; 邻 +237 `collapsed_interface` 14608 / +240 `interface_factory_scale` 14679 / +224 `non_conversion_speed` 14330) + 变体内部 (宿主+1008→+1016/+1366/+1180) | 换装 (转换惩罚走命令) | — | 定案 |
| 类别合计 (6 类) | sub_14173FEA0 switch | (线+24+线+28) 按变体类别 token 分桶 | 每 line active+damaged 合计 | show_equipment 等 6 徽标 | 定案 |
| 显示过滤 6 项 | populate 复选框绑定 | view+9512 token 表 {14700..14704, 15665} | resources/stockpiling/reinforcing/upgrading/outdated/refitting | show_* | 定案 |
| 上段 used 计数 | sub_141743200 | totals[7]/[8]/[9] (naval 行+13208 三档) | used_upgrading/outdated/refitting | factories_used_* | 高置信 |
| 新舰部署母港/舰改编目标 | vtable[11]→sub_141DB3390 | 窗+1408/+1416 选中 id 对 + 省 | CSetNavalDeploymentTarget / CSetShipRefitDeploymentTarget | — (pProvince 断言) | 定案 |
| 工厂格图标悬停 tooltip | 0X141D54820 (CProductionFactoryItem 槽0) | 双分支: 军工厂 (线+32 owner ps 链) / 造船厂 | **PRODUCTION_FACTORY_ASSIGN_DESC / PRODUCTION_DOCKYARD_ASSIGN_DESC** (§4.31.30 互证 — 宿主 = 工厂格图标非行) | FACTORIES/OUTPUT | 定案 |
| 顶部资源条 | sub_141D6DAC0→sub_140CAED60 | cc+4600 (按 CStrategicResource) | 国别资源/租借值 (§4.3 +4600) | resources_grid | 定案 |
| 生产线效率列 | 0X141937ED0 (效率上限计算, 读 vtable+88 基数 + sub_140C97B90 判 1e7 档) / 0X141939760 | 线+192 Q15 数组 (+204 count); 累计/钳制核 sub_140F6E840 (`100000*v4/v2` → /1e5 → 线+236 换装门 → sub_141939950 + sub_141937DD0) | factory_efficiencies (§4.8); **行 UI 绑定 = 行对象 vtable 出口** (无独立窗口柄) | — | 定案 |
| 面板刷新链 | [9]/[10]/@48[5]/@48[7] | view+9536/+9488 脏旗 | 玩家比对脏旗 + 日期门 + 可见门 | — | 定案 (机制) |


**窗壳骨架**（1.19.3 重锚：四 facet 骨座 17/2/10/4 同序同数，槽函数群址族 0x133550；
TD 0x143287B48；主 vtable 0x1429F7430 / @40 0x1429F74C0 / @48 0x1429F74D8 / @1408 0x1429F7530）：

| facet / 槽 | 语义 | 函数 | 备注 |
|---|---|---|---|
| 主 [0] | dtor | 0x141739B00 | — |
| 主 [2] | Reload | 0x141740600 | 清串经 sub_1412374F0(view) → vtable+96 (基类 reload 共享形) |
| 主 [7] | 关窗/收起 | 0x14173DEF0 | 五窗口群 +9504 逐一 hide；尾调 **sub_141C3C390(view+9544)** |
| 主 [9] | Refresh thunk | 0x14173EC50 | jmp rel32 → 0x14173EC60 (体) |
| 主 [10] | 日期门 Refresh | 0x14173EBE0 | 置脏旗 view+9536 |
| 主 [11] | SetTarget (转义) | 0x14173F270 | 面板开着点地图省 → 部署命令 (§4.30.3 入口链) |
| 主 [13] | 同通道第二入口 | 0x14173F120 | — |
| 主 [14] | populate 主 | 0x141740A40 | close_button → view+9344；military_tab → production_lines → item_grid |
| 主 [15] | populate 副 (teardown) | 0x14173A340 | 首调 **sub_141C3B7D0 (view+9544)** |
| @40 [0] | BuildTooltip | 0x14173BD90 | — |
| @48 [5] | 可见才 Repopulate | 0x1417167F0 | 体 = visible 门 → vtable+72 |
| @48 [7] | Update | 0x14173F2D0 | 三脏判 (view+9536 / +9280 / +9296 子窗) → @48[9] Repopulate |
| @48 [9] | Repopulate | 0x1417429F0 | 五窗口群复位 + 行池交叉 |
| @1408 [0] | 拖拽重排 | 0x14173EDF0 | 读过滤序数组定位 |

**基帧规则**: @48 facet 函数体内 `this = view+48`（mdisp=48），体内 `a1+N` 记作 view+N 须
**+48 归一**；主表 @0 facet 不受影响。归一后的真偏移：

| 原稿标签 | 真 view 偏移 | 语义 | 置信 |
|---|---|---|---|
| view+9176 / +9188 | **+9224 / +9236** | 过滤/排序行数组 {data, count}（Update 逐行 vtable+144，拖拽 @1408[0] 定位；写者 **sub_14173AEE0**(view, view+9512 复选框 token 表, view+9224)，按 tok 14700/15665 与线 vtable+200/+216 过滤建序，由 sub_141743200 每轮调用） | 定案 |
| view+9232 / +9248 | **+9280 / +9296** | 两子窗口包装（脏判可见；Repopulate 复位） | 定案 |
| view+9488 | **+9536** | Refresh 脏旗（[10] 置 1 / Update 消费清 0；与「+9536 脏旗 #2」同一字段） | 定案 |
| view+9448 | **+9496** | 0x28 资源条同步对象（内部 {data@0, count@+12}）；`sub_141D6DA80` 逐项 `sub_141D6DAC0` 刷新；ctor sub_141D6C790(view 根+1272) 建 | 定案 |
| view+9456 | **+9504** | 对象（+2804 id 对空/无效经 sub_14221F310 判 → vtable+64 复位）；populate 经 `sub_141DA9530(malloc(0xB00), view+1392)` lazy 自建（`if (!v173)` 门） | 定案 |

**元素柄群与 glue 观察者**（全零漂移；1.19.3 新增实名 glue 内嵌）：

| 柄群 | 偏移 | 语义 | 置信 |
|---|---|---|---|
| 五窗口手柄群 | **+9264 / +9272 / +9280 / +9288 / +9296**（+9288 = CProductionNavalDeploymentWindow；+9504 尾件） | Reload / [7] / Repopulate 三处同集复位 | 定案 |
| 五类别按钮 | **+9304 / +9312 / +9320 / +9328 / +9336** | tank / infantry / aircraft / naval / naval_repair_button | 定案 |
| 四按钮 glow | **+9352 / +9360 / +9368 / +9376** | tank / infantry / aircraft / naval_button_glow | 定案 |
| close_button | **+9344** | populate 装配 (.rdata 串直读) | 定案 |
| 网格两柄 | **+9384** production_lines / **+9392** item_grid | item_grid 由 production_lines vtable+432 取；`sub_1422C6650(item_grid, view+1408 观察者)` 挂 CReorderObserver | 定案 |
| 十二复选框柄 | **+9400..+9488** | show_equipment 族 12 项 | 定案 |
| 按钮 glue ×5 | **view+1416 起、1288B 步长**（+1416/+2704/+3992/+5280/+6568） | 内嵌 CLegacyButtonObserverGlue<> 实例 | 定案 |
| 复选框 glue ×12 | **view+7856 起、112B 步长** | 内嵌 CCheckBoxObserverGlue<> 实例 | 定案 |
| 资源条读数 helper | — | sub_141D6DAC0→sub_140CAED60 | 定案 |
| 工厂步长修饰 | — | sub_141D52A00 | 定案 |
| 线 id 对访问器 (行→线) | — | sub_141D52C40 | 定案 |
| 命令执行器/管理器 | — | sub_142250B00 / 全局 qword_14332F698 = **CInGameIdler**（RTTI 实名，主 vtable 0x142968FF0；取执行器 vtable+136）; **+1720 = CInGameInterfaceHandler** (ctor sub_140DC1B30 内 `*(a1+1720) = sub_140B614C0(...)`), 其 **+1240 = NNotification::CNotificationHandler** (见 §4.17) | 定案 |
| 行基类 ctor | — | CProductionLineItem sub_141D4B340（行+2600/+2608 优先钮、+2624 线 id 对） | 定案 |
| 行 ctor 四档 | — | sub_141D4C540 (0x3DA8) / sub_141D4B780 (0x33A0) / sub_141D4E540 (0x3398) / sub_141D4F5B0 (0x2478)；分派依线 vtable+192/+200/+208/+216 | 定案 |
| 行类基 vtable | 0x142A6CE20 | RTTI 直读 | 定案 |

> 行键 = (线指针, 线+237 u8)；旧行匹配 `sub_141D52C40(old)==线 && *(u8*)(old+8016)==v237`；行池
> view+9200 {data}/+9208 cap/+9212 count；新建行挂 view+9392 网格（grid+416 数组 / +428 count，
> 移除经 grid vtable+632）。行三负荷按钮 **+7936 / +7944 / +7952**（负向取负）经
> CAddProductionLineFactoriesCommand（ctor 0x141143520，0x38B）下令；CChangeProductionLinePriorityCommand
> ctor 0x141143C00。view+9396 = **死槽**（全 dump 0 读点; +9384 production_lines 与 +9392 item_grid 之间的填充槽, ctor 置 0 后永不触）;
> view+9544 = **NIndustrialOrganisation::COrganisationListWindow**（窗名 `industrial_organisation_list_window`, 无独立 RTTI 表项, vftable 串定案; ctor sub_141C3A650; 同族内嵌于装备设计器 sub_141776C00(a1+72) / MIO 详情窗族等）; BuildTooltip 与 populate 余段未逐行。

**定名收口** (writer 键 + 断言串 + lexer, 见 §4.8):

| 项 | 结论 | 证据 |
|---|---|---|
| 线+232 requested_factories (tok 13769) | CAddProductionLineFactoriesCommand 写入字段; setter clamp ≤ GetMaxAllowedFactories (线 vtable[11] → 变体._pType+1440 (CEquipmentType+1440) → 父arch+1440 → 默认 dword_143335FE0 [KR=150]) | 断言 nFactories; Execute 二进制文件 |
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
| 装模块/拆模块 | sub_141775290 → **builder sub_1414921F0 (装) / sub_14148F6D0 (拆)** | draft+184 modules; builder+8776 槽-模块表 | 模块编辑落草稿 (非命令, 会话内直改) | sfx_ui_sd_module_default; MODULE_SLOT_* | 定案 |
| 升级等级选择 | 0X141793B30/0890/0A40 → builder **sub_1414926E0 (设级入口, 含国别上限钳位重试)** / F120/D240 | builder+8632 CEquipmentUpgradesInstance | 三通道 (设/复位/自动); 国别上限 sub_141537940 | AUTO_UPGRADE_BUTTON_DESC | 定案 (通道) / 逐通道语义推定 |
| 角色下拉 | sub_14177BD10 → builder FB00 | builder 草稿 (role 字段经 FB00 内部) | 坦克角色变更; 失败文案读 镜像#1+40 名 | EQUIPMENT_DESIGNER_UPDATE_DESC_NEW_ROLE | 定案 (链) |
| 变体名 | sub_141786550 ← E230 (builder) | draft+40 name SSO (经 E230 拷出) | 按模式 0/1/2 取 草稿/母本/现役 名 | EQUIPMENT_DESIGNER_EMPTY_NAME | 定案 |
| 模型覆盖名 | view+69096 CEquipmentDesignerModelSelector ← sub_141784780 | variant+1072 override_model | SetTarget 镜像; E440 与 ref+1072 比对判改 | EQUIPMENT_DESIGNER_UPDATE_COSMETIC | 定案 |
| 引用变体网格 | 0X141793E10 | view+62392 条目+1376 = CEquipmentVariant*; 选中 view+31840 | 引用/升级候选变体选择; 选中重算预览#3 (sub_141492A10) | — | 定案 |
| 国家过滤 | sub_141784520 | view+62488 tag 数组; 行条目+1384 tag | AddCountryVariantFilterItem: 按创建国过滤 (FOREIGN/OWN_FILTER 语境) | EQUIPMENT_DESIGNER_OWN_FILTER/FOREIGN_FILTER | 定案 |
| 历史设计列表 | sub_141784A80 / sub_141784890 | CCountry+5544 scoped_ptr 每国 AI 设计库 → 条目 +552/+556; view+74064/+74104 | AI 历史设计条目 + 文件夹过滤 (HISTORICAL_PRESET 特例); 条目 = 0x320 = 800B (vtable 0x1429C7198, 脚本 common/ai_equipment; 全布局表见 §4.30.33) | — | 定案 |
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

> **模块操作对公共骨架** (装/拆 0x141775290 / 等级步进 0x141793B30): 操作入口清 `*(view+31854) = 0` (u8, 推定操作进行中/抑制刷新旗); 主操作走 builder = view+14232; 操作尾统一 `if (!*(view+31852)) sub_141786550(view)` 名刷新 (31852 = 跳过名刷新旗) → sub_141790050(view) 角色图标回退 → `*(view+31848) = 1` 编辑脏旗 (编辑镜像区 +31848..+31974 首字节); 预览对象 view+73920 非空 → sub_14177B230() 取对象 → sub_141DD8850(预览, a2, 模块) 更新预览。装模块成功且模块+280 非空 → manager (view+14216) **vtable+248 按名触发并跳过默认 sfx** (IDA 仅渲 1 参, 第二参疑丢, 待裁); 装失败 → 断言 "It should not have been possible to do that" equipmentdesignerview.cpp:3342 + sfx "order_invalid_effect"; 卸失败 → "It should not be possible to do that" :3361 + 同 sfx。等级步进被拒 → max = sub_141537940(a2, manager vt+160 返回值, 0) 国别上限; max < 等级则以 max 重试, 重试仍拒 → "VariantBuilder refused the max allowed level" :3246; max ≥ 等级却拒 → "VariantBuilder refused an allowed level" :3240。

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
| combat width | CArmy vt0[46] 0X140C7D9B0 (双出参) | CArmy 虚槽 (无存储偏移) | 战斗宽度 (现值+上限 推定); 书 vtable 表新行 | COMBAT_WIDTH_DESC / DESIGNER_COMBATWIDTH_TOOLTIP | 定案 (读法) |
| 装备构成 8 类 | BuildTooltip → sub_140B9D860 | **CArmy+904 vector** ⊕ 模板 data+168 容器 | 师×模板类别合并计数 (cavalry/armor/rocket/artillery/motorized/mechanized/infantry/special_forces) | EQUIPMENT_ARMOR 等 7 + cavalry | 定案 (读法; +904 见 §4.18) |
| 损耗 tooltip | sub_140C75500 | CArmy (方法内) | attrition 计算 | ATTRITION_DESC | 定案 (单链) |
| 师名/等级/经验 tooltip | sub_140C86CC0 / sub_140C7E930 | CArmy (方法内) | 师名; unit_level·experience 两窗共用 | LEVEL_NAME / VISUAL_LEVEL | 定案 (单链) |
| 历史页行重建 | sub_1416BEE50 | CArmy+1592 块 / +1644 行数 / +1624 CUnitMedalStore (键@+1064) | 补行 (0x5B0 条) + 按键分组 0x50 行 | — | 定案 |
| history_kill_count | sub_1416BEE50 | **CArmy+1656 killed** | 击杀数 | HISTORY_KILL_COUNT_TEXT | 定案 |
| history_experience_count / 军官经验增益 | sub_1416BEE50 / 0X1416AD770 链 | **CArmy+824 成员→vtable[1]→+136** (+32 = Update 变更侦测); **军官经验增益窗槽 = view+8024** (BuildTooltip 0X1416A2270 分支 `a2==*(a1+8024)` → resolve → 载体 vtable[1]; tooltip helper sub_1413E9CE0; 参数源 qword_143337930 PER_MEDAL/MULT) | 任职军官经验 (载体经虚 getter) | HISTORY_EXPERIENCE_COUNT_TEXT / ARMY_FIELD_OFFICER_EXPERIENCE_GAIN_TOOLTIP | 定案 |
| combat width 窗群 | BuildTooltip 0X1416A2270 | **view+8192 / view+8200 双窗槽** (`a2==*(a1+8192) ‖ a2==*(a1+8200)` → CArmy vtable+368 = vtable[46] 0X140C7D9B0) | 战斗宽度双出参 | COMBAT_WIDTH_DESC / DESIGNER_COMBATWIDTH_TOOLTIP | 定案 |
| 历史页行管理器/行列表/宿主窗槽 | sub_1416BEE50 (行 99..395) | **view+8272 行宿主窗** (vtable+120 find "history_kill_count"/"history_experience_count") / **view+8280 行列表管理器** (vtable[11] (+88) 上限 / vtable[5] (+40) 加行 / vtable[29] (+232) 与 vtable[33] (+264) 刷新对) / **view+8296 历史行列表** (0x50 行对象 ctor sub_141D102A0) | 页模式 view+8376 ==2 历史页; 行访问器 sub_1414468A0; 行条目 0x5B0 (1456B, ctor sub_141D0FD00; 行对象参数 = 工厂 `*(a1+128)+1272`) | — | 定案 |
| Update 脏检 | @64[1] 0X1416B88A0 | view+1672 缓存 vs (+824obj)->vtable[1]+32 | 变化 → sub_1416BDF50 局部刷新 | — | 定案 |
| 页切换 | @64[2] 末段 | view+8376 = 0/1/2 | 编制/统计/历史 三页 | — | 定案 (机制) |
| Badge 目标 (军/集团军) | 工厂 sub_141BCB490 → badge+504 idpair; **写点 = sub_1416B5D40(badge, idx, obj, flag)** (populate sub_1416BC7E0 逐条调用; 写值 = 入参对象 +8 的 refid 快照; ctor 初值 qword_14333D528 哨兵; 断言 ref.h:83) | resolve → COrdersGroup / CArmyGroup (+57 旗判) | 侧栏军级条目; SetTarget 无虚槽 (populates 写入) | — | 定案 |
| Badge 改名 | 文本观察器 sub_1416ACB50 | target+8 idpair → CSetOrderGroupNameCommand (0x50B) | 命令投递 sub_142250B00 (§4.00.6) | — | 定案 |
| Badge 名字聚合 tooltip | 0X14169D860 | CArmyGroup+560/{+572} 逐元+80; 单名 +80 | 集团军→含军名清单; 军→单名 | UNASSIGN_ARMY(_GROUP) | 定案 |
| Badge 将领技能 | 0X14169D860 → sub_140333D10 | 军团→将领; sub_140C15500 攻击技能 | 空 → 无将领文案 | LEADER_SKILL_DESC / UNIT_LEADER_NO_LEADER | 定案 (链) |
| Badge 组织/兵力条 | COrgStrIndicator (+392 内嵌) | (指示器内部未逐行; 属 §4.18 域) | org/str 显示控件 | — | 形态定案 |
| ListView 管辖师集合 | CTemplateChanger[1] 0X14169B400 | view+272 {count@+284} idpair 数组 → CArmy\* (res−16) | 批量师导出 (设计器「选中师改模板」数据源同族) | — | 定案 |
| ListView 部署/撤退 tooltip | BuildTooltip 0X14169F350 | view+260 idpair → 军团 → sub_140333D10 将领; leader+409/+410/+411, vtable[26] 天数, +64 名 | 部署在途/受阻/撤退三态; 军团+432 边境战争禁解散 | LEADER_DEPLOY_* / LEADER_COMING/LEADER_WITHDRAWING / HQ_WITHDRAW_REFUND_* / CAN_NOT_UNASSIGN_BORDER_WAR | 定案 (链; leader+409..411 = COrdersGroup §4.4.8) |
| ListView 部署/撤退列表窗 | BuildTooltip | view+10656 / view+12024 窗柄 | 两列表悬停分派 | DEPLOY_BUTTON_* / SWITCH_STRATEGIC_REDEPLOYMENT_MODE* | 定案 (机制) |
| 撤编全选注记 | BuildTooltip | view+304/+305 旗 bytes | HQ 撤编注记开关 | DISBAND_ALL_UNIT(_NOTE) | 高置信 |
| 设计器名字组行项点击 | sub_1414A38A0 → sub_141763E10 | **行项 +1328 (CDivisionDesignerView\*) / +1336 载荷 / +1344 旗** → ES(+11096) 名字组落账 + designer+17705 脏旗 | **CArmy+1328 簇属主裁定 = CDesignerEquipmentCategoryItem**, 非 CArmy | designer_div_name_group_entry | 定案 |
| 师列表排序比较器 | sub_1416B4D80 (ListView 大 Setup **sub_141693010** 列表槽 **+27168** 注册, 槽族 stride 1376: +16160..+28544; 断言 armiesview.cpp:342 "LeftArmy && RightArmy") | og = CUnit+192 → og+440 父集团军; 同群军序 ag+560{+572} / 无群 theatre+128{+140} / 跨群 theatre+152{+164} / 跨战区 cc+360{+372} (signed <) | 军群树层级排序 (师 og → 父军集团 → 战区 → 国家战区表), 触达六组偏移全数书已收 (GUI 消费侧互证零冲突); 槽族尾槽 +28544 = HqSlotTemplateChanger (RTTI vftable 直写) | — | 定案 |
| 师排序键权重 | sub_14169D210 (包装 sub_1416B5780 注册列表槽 **+23040**; 断言 armiesview.cpp:303 "Unhandled case" 落空 → 0) | 移动态枚举 sub_14169BF10: +524 path count / 省 controller vs +480 logical_country 敌对(sub_140700600) / sub_140C01650 撤退 / sub_140C00000 = d+436 is_army_hq / +1112÷+1120 挖掘比 (挖掘门 = 三 conjunct: dig_in≠0 ∧ cap≠0 ∧ sub_1416B3BF0 可挖掘) | 撤退 300000 < 向敌 400000 < HQ 500000 / 挖掘 100000+100000×dig_in÷cap < 向友 600000 (哨兵 0x10001869F) | — | 定案 |
| 列排序键换算对 | sub_14169C4E0 / sub_1416ADE80 (共享断言 armiesview.cpp:4024 `_SortComparators.GetSize()==1 \|\| ==3`) | 换算 = col+(desc?7:1)+(n==1?0:2); 应用 = *(x+1368) 控件 vtable 下发排序模式 1/3 (调用域 *(x+328) 列表族 8 站点) | 列头点击 → 排序键 id 换算 | — | 定案 |
| 习服图标帧 | sub_14169B310 (断言 armiesview.cpp:5457; 调用者含 CArmyDivisionView 子面板刷新 sub_1416B89C0 ✓) | 类别单例 sub_140614DF0 线性查索引 → frame = 2×索引+1; 习服值 (CUnit+1208 NAcclimatization::CData) ≥100000 (满档 1.0) 再 +1 | 习服图标帧选择 | — | 定案 |
| 多选燃料日耗行 | sub_14169A340 (断言 armiesview.cpp:457 "Invalid range") | Σ 逐单位双燃料 getter ×24 累计 (a4 累计出参); 首格单位名 = sub_140B9F5C0 (模板 data+400 首格缓存) 链 | FUEL_DAILY {AMOUNT} 选中集汇总行 | — | 定案 |

> **师排序键权重增补 (sub_14169D210)**: 挖掘比钳位判据 = `cap≠0 ∧ (u64)(dig_in + 0x7FFFFFFFFFFFFFFE) ≤ 0xFFFFFFFFFFFFFFFC` (无符号化区间检查, 排除 dig_in ∈ {−1,−2} 哨兵与 cap==0 除零) → 命中 100000+100000×dig_in÷cap, 否则哨兵 0x10001869F (4295107231 = 0x100000000 + 0x1869F, 推定 fixed5 「无效」标记); CArmy 取 = sub_14221F310(idpair) res−16 (§4.32 同族); 挖掘比宿主 = sub_1402AA280(army) (对象身份推定 CUnit, 未决); 断言门 B52 闩 byte_14338ABD0。
>
> **习服图标帧增补 (sub_14169B310)**: 类别单例指针经 **PHYSFS_swapULE64 字节序混淆** (sub_140614DF0 返翻转指针, 调用方翻回 — 防静态 grep 的轻度混淆); 习服值取值原语 = sub_140614AE0(unit+1208, &out 16B); 单例容器形态 {d@+0, c@+12}; 断言门 B52 闩 byte_14338ABD5; 两调用点 = 基帧 (a2=0, CArmyDivisionView 子面板刷新 sub_1416B89C0) 与满档帧 (带 unit)。


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
| 应用并关闭 | glue+4016 → sub_1420369F0 | — | 改名提交 + vtable[8] 关窗 | — | 定案 |
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
| CAirWing 双vtable槽表 | 见 §4.15 补记 | — |
| CAcesView | = reorg+4224 | — |
| 书 +2492 | reinforcement_setting (confirm 门比对) | — |

#### 4.30.7 海军视图簇 (ShipStatsView / CompactShipListView / NavalCombatView)

**入口链**: ShipStatsView target = **CShip** (idpair
@view+6632, ctor 快照); CompactShipListView target = **CTaskForce 数组** (RTTI 实名 filler
`UpdateCompactShipList(CShipCategorizer const&, CTaskForce const* const(&)[N], filler)`);
NavalCombatView target = **CNavalCombat** (idpair@view+64, Reload 经 res−16+24 归一化)。
**坐标校准定案**: §4.22.5 海战书表 = res 坐标, 无 ±16 (sub_1413E2B80 双谓词
直证); **−16 胶水规律定案**: `*(X−16+24) = *(X+8) = X 的 refid` (CTaskForce writer 基互证)。
命令族: **CDeleteShipCommand{+40 舰, +48 特混舰队}** / **CDisengageFromNavalCombatCommand
{+40 combat refid tok 0x2916, +48 is_attacker tok 0x28F5}** — §4.00.6 再添两员。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| ShipStats 目标 (舰) | 工厂 glue sub_141AC9DB0 (ctor a3 直拷) | **CShip+8 refid → view+6632**; +56 解析缓存 | 宿主+5320 idpair 进; 析构安全快照 | ship_stats_window | 定案 |
| ShipStats 统计/历史页签 | glue+88/+1376 cb | win+5312 vtable+104/+176 | 双页签互切 | tab_stats / tab_history | 定案 (形态) |
| ShipStats 装备定义行 | glue+2664 sub_141BEF820 | **CShip+64 池 → 池+1008 def** | 装备定义可见门 | — | 定案 |
| ShipStats 资源门列表 | glue+3952 sub_141BECFC0 | **CShip+1832→tf+472** → CCountry+224 ≥ 1e5×define | 属主资源达标列表 | — | 高置信 |
| ShipStats 舰名/删除确认 | glue+7928 sub_141BECA70 | **CShip+2072(+96)**; +1832 宿主 | 确认弹窗 0x1078; 投 CDeleteShipCommand | CONFIRMDELETESHIP / CONFIRMDELETETEXT / DISBAND_PRIDE_OF_THE_FLEET_COST | 定案 |
| ShipStats pride 图标切换 | 逐帧 0X141BED5F0 | **CCountry+592/+596 vs 舰+8/+12**; CShip+1576 旗 | 舰=舰队 pride 时 type_icon 切换 | type_icon | 定案 |
| ShipStats 军官钮刷新 | Update 0X141BEFB60 | **CShip+24 IOfficerHolder** vtable[1]→+32 | 军官变更检测 (缓存 win+10600) | — | 高置信 |
| ShipStats 舰图标串 | sub_140C3A0F0 | **CShip+232 舰体名** + def+968 | GFX_unit_\<hull\>_\<n\>_icon_medium | GFX_navalcombat_ship_icon_unknown (兜底) | 高置信 |
| ShipStats 流亡/可见谓词 | sub_140C33A50 | **CShip+1576 旗 qword; +2052 exile tag; +64 池旗** | define 15 门 | — | 定案 (读法) |
| CompactList 条目灌入 | UpdateCompactShipList (RTTI 实名) | **CTaskForce 数组** → view+56 数组 | 特混舰队编成紧凑列表 | entry | 定案 (形态) |
| CompactList 条目 tooltip | 0X141E11E40 | **entry+1336 DB 索引; +1340 需求数** | 舰型名 + 需求舰数 | COMPACT_SHIP_VIEW_DESC_REQ / TYPE | 定案 |
| CompactList 条目图标 | entry 窗 | entry+8/+16 idpair; "pride"/"required_ships_count" 窗 | pride 图标 + 需求计数 | pride / required_ships_count | 定案 (窗名) |
| NavalCombat 目标 (海战) | Reload 0X1417EA930 再归一化 | **CNavalCombat+8 refid → view+64** | 外部 idpair 规范为海战自身 refid | navalcombatview | 定案 |
| NavalCombat 双侧网格 | sub_1417ED140 | **cb+232/{+244} group 容器** → CCombatBoxGrids+24 8 槽 + CFEXShipIcon | 攻/守组×舰图标网格 | CCombatBoxGrids | 定案 |
| NavalCombat 将领面板 | sub_1417F0320 | **cb+304 current_leader** (无将 → GFX_leader_unknown) | 名/头像/技能(fixed5)/等级 | UNIT_LEADER_NO_LEADER | 定案 |
| NavalCombat 参战国旗 | sub_1417EDD40 | **cb+56 参战 tag 链A** → view+2656/+2664 | 两侧参战国 | — | 定案 |
| NavalCombat 侧统计 | sub_14161E9A0 | 镜像 cb → view+2672/+2680 vtable+776 | 侧统计窗 | — | 定案 (链) |
| NavalCombat 进度条 | 刷新尾段 | combat vtable[25] → view+2704 | 战斗进度 | COMBAT_PROGRESS_DESC | 定案 (挂接) |
| NavalCombat 脱离战斗 | glue+1360 → sub_1417E4330 | **CDisengageFromNavalCombatCommand {+40 海战 refid, +48 is_attacker@+216}** | 玩家侧选取 sub_1417E7B30 (gs+1312/1316 + cb+56) | — | 定案 |
| NavalCombat 中央 tooltip | BuildTooltip 0X1417E88A0 | 进度/天气/夜战/载具堆叠/将领特性 | 悬停统计 | COMBAT_PROGRESS_DESC / WEATHER_MODIFIERS / NIGHT_MODIFIERS / CARRIER_STACK_PENALTY_DESC / LEARNING_TRAITS | 定案 (loc key) |
| 坐标校准 (海战族) | — | **§4.22.5 书偏移 = res 坐标**; −16 胶水 = 「(X−16)+24 = X+8 refid」 | 侧/镜像/group/leader 全 res 直读命中 | — | **定案** |

**坐标关系** (§4.16 已载): writer 0X140D7AFA0 a1 = 元素+16, 运行时特混舰队对象 =
writer this+16; sub_1402A6F30 读 tf+24 = writer+8 顶层 refid (独立再证)。
已结: pride 窗 = 探测门 (sub_1422BE0F0) + 缓存取 (vtable+136 → 条目+1560) 两段式, 非双窗 (定案); lambda = 分类器→逐条目刷新 std::_Binder 绑定 (高置信, 行级展开收益低不再追)。

#### 4.30.8 阵营视图簇 (FactionView / NewFactionWindow / CommanderWindow)

**入口链**: FactionView = 「CCountry 直读」变奏 (无存储 target,
查看国 gs+1312/1316 → cc+3976+656 → CFaction 每次现取); NewFactionWindow = **第 7 种基链
CReloadableWindow 9 槽**, target = 选中 CFactionTemplate\*@win+2920; CommanderWindow =
**CUnitLeaderWindow 首次入册 13 槽**, 无阵营指针 (玩家国现取 + **cc+4080 roster 两张
CUnitLeader\* 候选表 @+112/+136**)。**方法学新路径**: 本族vtable常量在 dump 里以
`&类名::vftable'` 符号出现 (grep 地址必落空) — ctor 定位 = grep 符号 → 符号回映射行号;
**MI 漂移第二形态**: @48 子对象vtable方法 this = win+48 (Update 读 +20192 = win+20240 双向全中)。
命令族: **CCreateFactionCommand (id 12242: +40 tag / +48 名 / +80 icon 串 / +128 CColor 色 / +184 初始成员)** /
**CClearFactionTheater (19760)** / **CFactionSetCommanderCommand (10509: +40 序槽 / +44 leader
idpair / +52 applier)**。CFactionMemberStatus+56/+80 添 UI 消费点定案 (§4.5)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| FactionView 目标 (查看国) | 无 SetTarget ([9]/[11] 不覆写); 刷新时现取 | tag gs+1312/1316 → sub_140BB48F0 → **cc+3976+656 → CFaction\*** | 「CCountry 直读」变奏 (§4.30.3 同款); 零阵营即空态 | countryfactionview | 定案 |
| FactionView 全量构建 | [14] populate sub_141472080 (**DLC50 门**) | 惰性建 §2 全表 | Deeper Factions DLC 门 (与 add_faction_goal 同门) | — | 定案 |
| 阵营名行 | sub_140D8BB80 | **CFaction+24/+56 name** | GetName (§4.5) | — | 定案 |
| manifest 门/名 | sub_140A21BE0 | **goal_status+16 manifest def** (+2664/+2872 = 描述需实例状态门对, §4.5.3) | manifest 显示 | MANIFEST / FOREIGN_MANIFEST_ENTRY | 定案 (读法) |
| 目标 (goals) 列表 | sub_140A27930 | **goal_status+24 {count@+36} 1344B 条目 def@+0** | 目标列表 (§4.5 ✓) | FOREIGN_GOAL_ITEM_ENTRY | 定案 |
| 成员国列表 (色+值) | sub_141474550 | **CFaction+88/{+100}**; **facsys 条目 sub_140BB4AC0(tag)+56/+80**; **cc+848(+880) 色** | 逐成员行: 色/百分值/计数; 首元 = 领袖旗 | faction_countries_window | 定案 (读法) / +56/+80 语义推定 |
| 规则/目标/邀请/人力弹窗 | +1408/+1416/+1432/+1440 四窗 | CChangeRuleWindow / CChangeGoalWindow / CInviteCountriesWindow / "request_faction_manpower" | 交互弹窗群 (change_rule_window 等) | change_rule_window | 定案 (形态) |
| 弹窗池 12 种 | sub_141BFE5B0(popup, mode) | +20240 vector\<unique_ptr\<CFactionPopup\>\> (内联容 13) | 解散/退出/夺权/目标/规则/剧院/学说/踢除/邀请 确认窗 | CDismantleFaction… 全族 RTTI | 定案 |
| 指挥官窗嵌入 | sub_141BF84C0 (populate 惰性建) | **+20216 CFactionCommanderWindow (0x11A8)** | 阵营页内嵌指挥官管理 | — | 定案 |
| 设施/科学家子对象 | sub_141468980 / 0X141C1F110 | +20200 CProjectListFilterWindow\<CResearchFacilityItem\> / +20208 CFactionScientistRoster | NProject 联动 (RTTI 实名) | — | 定案 (形态) |
| New 阵营窗模板网格 | [6] sub_1418282B0 | **CFactionTemplateDatabase qword_14332EF10 {data@+80, count@+92}**; 谓词 sub_140D91D80/sub_140A2F810 | 模板列表 × unavailable_checkbox 过滤 | new_faction_window / faction_template_grid | 定案 |
| 模板选中 | 行 lambda sub_141828720 → sub_141825CF0 | **win+2920 = CFactionTemplate\*** (item+32 进, item+1432 回指) | 可切 0; 门 = allow 谓词 | new_faction_template_item | 定案 |
| 模板 allow 门 | sub_140D91D70 → sub_140A2F810 | **CFactionTemplate+140 门 / +120 子对象 vtable[3] (国 scope), vtable[12] 名生成** | 模板×国家允许 + 阵营命名 | create_faction_button | 定案 (链) / def 字段推定 |
| 创建阵营提交 | create_faction_button lambda sub_141828760 → sub_141584EC0 | **view21+8248 = template** (SetTemplate sub_141825EA0); 开 view#21; 关 view12+31696 | 二段式: 选模板 → 终窗 (名/色) | create_faction_button | 定案 |
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
| cc+4080 宿主类 | **CCountryCharacters** (vtable 0X14298AE18; sizeof 0x138 全布局见 §4.3); 两张 CUnitLeader\* 候选表 +112/+136 实测 GER 27/12 人 | 活体探针 + ASLR 换算 + RTTI 名三证 |
| view#21 三子窗 | +8312 CInviteCountriesWindow / +8320 CFactionIconWindow / +8328 CFactionColorPickerWindow | RTTI 实名 |
| 阵营色链 | 初始色 = CFactionTemplate rgba@+384 (旗@+400) ∥ 玩家国 cc+880 → picker+2992 CColor → CCreateFactionCommand+128 → fac+2512 | 二进制文件 |
| CCreateFactionCommand+80 | icon 串 (非色; 色在 +128 CColor) | 断言+二进制文件 |
| CLegacy 窗 | 无 DLC50 时的备胎窗 | — |
| influence 显示 | 占比 = 值 ÷ fac+2080; 排名 = token 19617 faction_influence_rank | 注册串直证 |
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
| DiplomacyView 目标 (目标国) | SetTarget [11] 0X1415EC140 / [12] 0X1415EC070 | **CProvince+392 controller → win+17664 (dword tag)**; manager+192 同步 | 「tag 存储」变奏 (非指针); 自国 = manager vtable[20] 现取 — 双边形态 | countrydiplomacyview | 定案 |
| 目标播发 | Repopulate @48[9] 0X1415F08E0 (**@48 this 漂移**) | **infoCtrl+5304 / actionCtrl+2552 / actionCtrl+2600 ← win+17664** | 单点写入四处消费 | — | 定案 |
| 目标国 header (旗/名/阵营) | sub_1415F11F0 | **dip+656 CFaction\*** → sub_140D8BB80; 国名 sub_140BB4BB0(&tag) | `diplo_country_flag` / `country_name` / `faction_name` | DIPLOMACY_NO_FACTION | 定案 |
| opinion 双向 (our/their) | sub_1415F49A0 + sub_1406F4490 | **dip+8 active_relations[idx] → rs+768 cached_sum**; 旗 = sub_140B44AC0(mgr, obj, &tag) | `our_opinion_value` / `their_opinion_value` (零关系 → "—") | DIPLOMACY_OPINION_VALUE | 定案 (书表命中) |
| 执政党块 | sub_1415F5960 | **ps+208 ruling_party → sub_1411A3300 leader**; 名 sub_140FCB280; 像 sub_140B47270 | `leader_name` / `leader_portrait`; 无 → GFX_leader_unknown | ERROR: Missing leader | 定案 |
| 政党饼图 | 同上 (C2dPieChartTemplate; def 侧 = C2dPieChartType, 负定案 writer 空桩) | **ps+32/{+44}; party+136 popularity; 色 sub_1411A4780(party)+16** | political_pie_chart 顶点 | — | 定案 (书表命中) |
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
| 动作提交/取消 | vtable[14] 订阅 | **`send_button` / `cancel_button`** → 各控制器 | tooltip handler = 控制器自身 (vtable[2] 绑 vtable[69]) | send_button | 定案 |
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
| P+44 / P+48 | P+44 = 大陆 id (loc: DYPLOMACY_FILTER_CONTINENTS/IDEOLOGIES/FACTIONS 三滤); P+48 = 稠密战略区号 | loc 直证 |
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
| 需求状态行 | w3 | **conf+220 making_demands** 门; sub_140E48090 国 | 提需求中/等待 | PEACE_CURRENTLY_MAKING_DEMANDS / PEACE_WAITING_PLAYERS_MAKE_DEMANDS | 定案 |
| 截止数值行 | w3 | sub_140E401F0(conf) ×1000/1e5 + gs 日期 | 会议时限/累计值 | PEACE_THREAT_GENERATED_TOTAL (SUMMED/VALUE) | 高置信 (语义) |
| 当前分数 | w3 | **winners 条目+64** (sub_140E38720 查 tag) − sub_140E400F0(conf) 总分; 分差 sub_140E3F7D0 (+368 solo_winner 门) | 国别分 vs 玩家总分 | PEACE_CURRENT_SCORE (SCORE) | 定案 |
| 9 个行动图标 | w2 0X1418657D0 | sub_1418626E0/F720(conf, …, token) → **win+20880..+20944**; **DLC41 门** | take_states(12495)/liberate(12496)/puppet(12497)/force_government(12498) + take_navy(12526)/demilitarized_zone(12531)/war_reparation(12532)/resource_rights(12533)/dismantle_industry(12534) | *_action_icon | 定案 |
| 行动说明显隐 | w2 | 九图标 byte165&8 聚合 | 有可用行动才显 | bid_actions_description / stackable_bid_actions_description | 定案 |
| subject/liberated 页签 | w2 | **conf+308 + conf+332 计数和** → +20992 对象 vtable[81]/vtable[82] | liberated/subject 页签出叶 (计数门) | — | 定案 (读法) |
| demands 标签 | w5 0X1418647F0 | **conf+96/{+108} vs +120** per-player map 查玩家; **conf+532** = ACTION | make demands / defeated / thirdparty 三态 | PEACE_MAKE_DEMANDS_LABEL / PEACE_FILTER_DEMANDS_DESCRIPTION / PEACE_DEFEATED_ACTIONS_* / PEACE_THIRDPARTY_ACTIONS_* | 定案 |
| 可用行动列表 | w5 尾 | sub_14185CEC0(…, **conf+528** 选中 token, 默认 19479 undefined) | available_actions 窗 | available_actions | 定案 (读法) |
| 行动窗显隐 | w5 | **win+20758 byte** | actions_window 门 | peaceconference_actions_window | 定案 |
| taker tab (夺州页) | w6 0X141867A20 | **win+20760 模式**; 池 A/B 清理; win+20824 列表 | 夺州分页 (断言 Unknown taker tab) | current_and_history_actions | 定案 (机制) |
| 双 popup 更新 | w7 0X1418660E0 / w8 0X141867D00 | **popup+5248 = conf idpair** (sub_141E584E0 装); popup+56 目标; conf+96/{+108} 匹配 | winner/beneficiary 双侧竞标弹窗 (SetBiddingsIn\* 载体) | — | 定案 (装载+骨架: ctor sub_141E566A0 — +8 winner/beneficiary 变体 dword / +16 CSimpleEmptyEntryList<CBiddingsPopupItem> 行表 / 三组按钮胶水 +80/+1368/+2656 / 事件束 +3944 / conf idpair +5248 (哨兵 qword_14333D528, 装载 sub_141E584E0)) |
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
= 本类 text 族 0x134E0 / item 族 0x14FA0 / 胶水桩族 0x510 / vtable rdata 0x16D60）：

| 项 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 三行对象池 dtor 序 | dtor 实 sub_14185C670 | 逆序 **+20704 → +20680 → +20656** | 逐池 `sub_140BBF080(池)` 销元素 → `alloc vtable[2] (+16)` 回收 data → data 清零 → dword@+8 清 0；三池共用 sub_140BBF080（ICF 折叠） | — | 定案 |
| 池形态（三池同） | — | data@0 / dword@+8 / count@+12 / alloc@+16（元素 8B 指针） | count 槽 = **+20668 / +20692 / +20716**（三处 8B 步长循环 `v2+8**(a1+count)` 直证：sub_14185F080 / w6 sub_141867A20 / sub_14185F7B0） | — | 定案 |
| 池 1 dword@+8 | dtor 清 0 / ctor 清 0 | **+20664** | **池容量 cap**（与 +20668 count / +20672 alloc 构成标准 CVector 三件套; dtor sub_14185C670 逆序销池时清 cap + alloc vtable[2] 回收 data） | — | 定案 |
| 池 1 allocator@+16 | ctor 初值 = off_143085170；dtor 经 vtable[2] 回收 | **+20672** | 池分配器槽 | — | 定案 |
| 池 2 三槽 | 同池 1 机制 | **+20688 / +20692 / +20696** | dword / count / alloc | — | 定案 |
| 池 3 三槽 | 同上 | **+20712 / +20716 / +20720** | +20716 另见 sub_14185F7B0 循环 | — | 定案 |
| 池 1 元素删除 | sub_14185F080 内 | **sub_141E4D510** | 销元素后再调行对象 vtable[25] (+200) 关窗 | — | 定案 |
| 池 2 元素删除 | 同上 | **sub_141E4D4E0** | 同机制 | — | 定案 |
| 池 3 元素删除 | 同上 | **sub_141E479B0** | 同机制 | — | 定案 |
| +20728 owner/界面处理器 | ctor sub_14185AE60 存 a2；Reload 网络侧 | **+20728** | `*(a2+1272)` = 窗工厂 → `sub_14225C5A0(工厂, "peaceconference_full_window", 0)` 查根窗（vtable[12] (+96) 内部形态未逐行）；Reload 网络通知链 = vtable+136 → server+88 → `_RTDynamicCast(CNetworkServer/CProxyServer)` + server+84 门 → 通知全局 qword_14338A140（+80/+88 各 vtable+96） | peaceconference_full_window | 定案 |
| +20736 completed 窗柄 | 主填充 sub_1418646F0 首分支（conf+221 门）→ **sub_140B653D0** | **+20736**；ctor a3 存入 | 体内 +576 子窗经 sub_14185F080 复位 / +1018 清 0；对象类名未名（CGuiObject 谱系） | — | 定案（机制） |
| idpair 哨兵 | ctor 尾块初值 | **+20744 / +20748** = qword_14333D528 | 1.19.3 通用 idpair 哨兵，全镜像复用 | — | 定案 |
| 双 popup 更新门 | w7 sub_1418660E0 / w8 sub_141867D00 | **+20756** 与 **+20757**（置位为 1） | 假分支 → 各自 popup vtable[6] (+48) 调用 | — | 定案 |
| +20764 暂停暂存 | Reload → sub_1401FA5E0() +594 取旧置 → 存本槽置 1 | **+20764** | 全局对象身份未名（同形态沿用） | — | 高置信（语义） |
| +20768 根窗槽 | 可见性谓词 vtable+584 / byte165 bit3；清除 = **sub_141862670**（vtable[2] 逐子 + vtable[25] (+200) 后置 0）；w6 经 `sub_1422BC600(+20768, "reopen_ingame_lobby_label")` 查子窗 | **+20768** | ctor 只把窗名交基 ctor sub_142255FA0，槽实写点在 reload/rebuild 链（合并块未逐行） | reopen_ingame_lobby | 定案（清除点） |
| 双竞标弹窗指针 | Reload（conf idpair 装载段） | **+20776** 与 **+20784** = CPeaceBiddingsPopUpWindow\* ×2 | **sub_141E584E0**(popup, conf) 装 conf idpair → popup+5248（popup vtable 0x142A848A0） | — | 定案 |
| 清窗/复位函数 | dtor 首调 + Reload 双调 | **sub_14185F080** | 清九图标柄 +20880..+20976 + 三池销元素 + 清 +20800/+20808/+20816 | — | 定案（新锚） |
| Reload 变体 | **sub_141864560** | 无可见门 / 无 popup 装载，直接 输赢 → 主填充 → +20764 → +20768 → 地图模式 22; 断言 :539 "_Conference.IsValid()" (latch byte_14338B208; 引用 = a1+20744 id 对 + sub_14221F310 校验); 字段落位 = +20752 主填充 (sub_14185DE40) / +20764 存 mgr+594 旧值并置 1 / +20768 对象 vtable 槽 15 / mgr = qword_14332F6A0+1720 (sub_140B65270) | 触发路径未追（推定 = 结束态/非可见路径） | — | 推定 |
| 主填充分派 | **sub_1418646F0** | completed → sub_140B653D0；否则九连 w4/w2/w3/w5/w6/w7/w8/w9 + 地图模式 22 | 九 worker 地址见上行各行 | — | 定案 |
| 输赢计算 | **sub_14185DE40** | conf+96/+120 map 查玩家 | 漂移 0x134E0 | — | 定案 |
| SetBiddingsIn\* lambda vtable | — | **0x142A0E748**（winner）/ **0x142A0E780**（beneficiary） | mangled 签名零漂移（七参全同）；Winner 宿主 sub_141868380（thunk sub_1418687F0）/ Beneficiary 宿主 sub_141865250（thunk sub_1418687E0） | — | 定案 |

> 主 vtable **0x142A0DB20** 四槽：[0] 0x14185CD80（→ 实 dtor 0x14185C670）/ [1] 0x14011D220
> const-false / [2] Reload 0x141862010 / [3] 0x14012A2C0 guard_nop；主 vtable [-1] COL =
> 0x142D45EA0，表止位 = @40 COL 0x142D45F30。@40 子表（CTooltipHandler）**0x142A0DB48**：
> [0] BuildTooltip 0x141860410（体未逐行）/ [1] dtor 变体 0x14185CD68（thunk `sub_14185CD80(a1-40)`）。
> 基链 = CReloadableInterface@0 + CTooltipHandler@40（双 COL 证实）。ctor **sub_14185AE60**
> 尾段初值块：+20728=a2 / +20736=a3 / +20744=qword_14333D528 / +20758=1，尾至 +21000 全 0；
> 16× CButtonEventDispatcher stride 1288 @+48..+19368（vtable 基）。Reload 0x141862010 流程：
> +20768 vtable+584(73) 可见性 → idpair 自愈（conf+8 回写；peaceconferencewindow.cpp:539 =
> 0x21B 断言）→ 双 popup 装载 → +20752 输赢 → 主填充 → +20764 暂停暂存 → 网络通知 → 尾。

**CPeaceUIHelper 两函 (peaceuihelper.cpp, 书未收)**: ① **GetOnClickAllLabel sub_1419E8B00** = 和会主窗「全选/全撤/全叠」按钮标签 — ui+1296 = CPeaceConference* 槽 / ui+1304 = 模式枚举槽 {0=SELECT, 1=CANCEL, 2/3=STACK|UNSTACK}; STACK 与 UNSTACK 共用 v5∈{2,3} 分支, 真区分靠 conf+528 选中 action token == 19479 (未选 = STACK, §4.30.10 available_actions 同址); 输方 (conf+20752≠0, 本节输赢顶图同字段) 不提供标签; 四 loc 键 PEACE_CONFERENCE_ON_CLICK_{SELECT,CANCEL,STACK,UNSTACK}_ALL_ACTIONS; 落空模式断言 :627 "Unknown type of click all" (门 B52 闩 byte_14338B50A)。② **GetStateMapActionName sub_1419E7470** = §4.30.28 CPeaceMapIcon 表 +152 行的名构建输入 (第三参 = StateMapData, 模板参 = icon+144) — StateMapData 布局: +4 模式源 dword / +8 _pClickAction* / +16 _pAttachedAction* (断言串直证); 名构建链三件 = sub_140E3B830 模式解析 (switch *(mapdata+4)) → sub_1419E7470 分派 (模式 0/3 取 +8, 余取 +16, 双指针皆空且模式 7 断言 :173) → sub_1419E7660 名构建本体 (含 :102 "Negotiator.IsValid()" 断言, 消费 conf+528 选中 token)。


#### 4.30.11 科技+国策视图 (TechnologyView / NationalFocusView / FocusInlayWindowView)

**入口链**: TechnologyView target = **CTechnologyStatus 现取**
(sub_1406CFCB0(cc) = *(cc+3936), §4.7 ✓) — B3「CCountry 直读」第 2 例 (基 ctor mode=6);
NationalFocusView target = **查看国 CCountry\*@win+8440** (§4.30.1 存指针变奏; 显式 setter 0X14138C260
+ [6] SetTargetPlayer; 视图 #13), **第 4 子对象 CEventScopeProvider@+1408 (3 槽新骨架元素)**;
InlayWindowView = **无 RTTI 无vtable** (104B 非多态行视图, 池 win+1448)。**跨视图链定案**: 外交
infoCtrl+5304 → 视图#13 SetTarget (§4.30.9 目标 tag); @48 子表 this=win+48 坐标规则第 4/5 例。
新锚: 科技 template+984 年份/+992 基础成本/+1034 旗 / 解锁元+1000; cc+5620 树版本 / tree+152
inlay 表 / def+1416·+1470 (**见 §4.3.13**: def+1416=mutually_exclusive 定案 /
def+1470=dynamic name 旗 / tree+152=CFocusInlayWindowInstance 56B 内联)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 科技面板目标 | 无 SetTarget 槽; [6] 0X1415F9090 刷 win+1448 | **owner vtable[20] 玩家 tag → 现取 *(cc+3936) CTechnologyStatus** | B3「CCountry 直读」第 2 例 (§4.7 ✓) | countrytechnologyview | 定案 |
| 研究槽行 (research_slots_grid) | Repopulate@48[9] 0X1415FA1A0 → 0X1415FA300 | **ts+160 data/{+172} count → CResearchSlotItem(0x580) 行, item+1336=slot** | 行模型 = §4.7 slots | research_slot_entry / research_slots_grid | 定案 |
| 行可见门 | sub_1415FB5D0 | ts+160 线性查 slot 指针 | 非本人槽不画 | — | 定案 |
| 空槽支路 | 0X141BE4BF0 slot+24==0 | — | title=UNUSED_SLOT + GFX_research_line_bg + empty_research_slot_glow | **UNUSED_SLOT** | 定案 |
| 行标题 (title 窗) | sub_140EDEBB0 → sub_140EC9A60 | slot+24 tech (名 tech+8) | 在研科技名 | — | 定案 |
| 进度条 (research_progressbar) | 0X141BE35C0; 分子 sub_140EDEDB0 / 分母 sub_140EDEA90 | 分子 = tech+408 ∨ slot+32; 分母 = template+992×qword_143332BA0/1e5 ∨ qword_143332A38; 归一 1e7 | 模板+992 = 基础成本 (新锚) | — | 定案 (链) / 分母语义高置信 |
| ETA 文本 (eta 窗) | sub_140EDA1B0 (tech+488 门) | tech+488 use_experience | 剩余天数 → ETA_SHORT_D/DAYS; 门 = 在研且窗可见 | **ETA_SHORT_D / DAYS** | 定案 |
| 年份 (year 窗) | sub_140EDF970 | **template+984 (>0 门)** | 科技可用年 (窗口名直证; +984 见 §4.7) | — | 高置信 |
| 科技图标 (technology 窗) | sub_140B491B0 (模板) / sub_140B45D30 (解锁 def) | **门: !tech+360 ∨ sub_140EE3DD0(template+1034 ∨ tech+116==0)**; def 源 = *(tech+104) 首元 (+1000 旗) | 模板图 vs 首解锁装备图 | — | 定案 (书表命中) |
| 设计商图标 (designer 窗) | sub_14221F310 + sub_140DB8C20 | **tech+492/+496 id 对** | 有设计商 → GFX_research_line_mio_bg + 名 | GFX_research_line_mio_bg | 定案 (书表命中) |
| 页签切换 | SetupDerived lambda ×2 → win+1408; Repopulate 分派 | **win+1408 (0=research/1=facilities)**; 研究槽行件内 tab 镜像 = 行件+1360 (Repopulate 0x1415FA1A0 读, 与 win+1408 同步), Repopulate 父锚 = 行基 −48; +1552/+2920 页容器互斥 | assert "unknown tab" @ countrytechnologyview.cpp:0x116 | research_slots_tab / facilities_tab | 定案 |
| 设施页签本体 | ctor 0X141CAEA90 | **win+4288 = NProject::NUi::CFacilitiesTabView (0xB98, 窗 facilities_view)** | 布局定案 (§4.30.23 五合一表 + §4.7) | facilities_view | 定案 |
| 国策面板目标 | 直写 setter 0X14138C260 / [6] SetTargetPlayer 0X14138B200 | **win+8440 = 查看国 CCountry\***; getter 0X141387390 (0→玩家回退) | §4.30.1 存指针变奏 (非 [11] 槽); 换国广播 sub_14053A610(+8528) | nationalfocusview; 视图 #13 | 定案 |
| 外交→国策跳转 | 0X1415EC3E0 (dip infoCtrl cb3) | **manager vtable[23] 视图#13 ← infoCtrl+5304 (§4.30.9 目标 tag)** | 跨视图 target 直传 | — | 定案 |
| 焦点树重建 | 0X141386BD0 | **cc+4976 树; 门 = win+8424/+8432 缓存 ∧ cc+5620 版本** | 树/版本双门; 题栏 NATIONAL_FOCUS_TITLE | **NATIONAL_FOCUS_TITLE** | 定案 |
| 焦点树插图行 (inlay) | push 0X141378820 / Setup 0X141BC0280 / Update 0X141BC0B80 / 按钮二级查找 0X141BBFD90 / 销毁 0X141BBFB40 | **池 win+1448{+1460} 104B; 源 = tree+152{count@164} 56B 条; 条+24 = CFocusInlayWindow def (名@def+88; 可见门 = 旗 def+208 → 实判 def+120 CAndTrigger Evaluate 槽[3] ∧ 查看国一致 gs+1312/1316 — sub_140A6CC00 直证, 原「可见门 def+208」措辞不精确)** | 每树条目一实例窗 `<名>_instance`; 三元素组刷新; **View 104B 全字段** = {+0 源条目, +8 宿主窗, +16 实例窗 (FB40 销毁置 0; Update 判空惰性 Setup), +32 图标行表 24B 元 {win, 状态表宿主, 上次态} 初值 −2, +56 按钮条目表 1376B 元 {wrapper@+8, SButton*@+1368}, +80 进度条行表 16B 元 {win, SProgressbar*}}; Setup 三错误串 :161/:177/:222/:229; FD90 = (窗口 id View+44, 按钮 id View+48) → cc+4976 树 → tree+152 → def+8 → def+40 192B 条+12 二级查找落空 :107; FB40 销毁断言 DidRemove :244 | focus_inlay_window_view.cpp | 定案 |
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
| 决议变更序列号缓存 | @48[7] 0X1417290A0 | win+1708 缓存 (sub_140DCCEA0 = owner vtable[17]→+1848 + 全局+220) | 序列号比对侦脏 | countrydecisionview | 定案 |
| 普通决议行 (decision_grid) | pass A sub_1417274C0; Setup vtable[25] 0X141D77DC0 | **ds+16 可用表 → def @item+4016**; 池 +1552..+1576 (0xFB8) | 行门 = **def+3296 on_map_mode ∈{1,2}** (1=decision_view_only/2=map_and_decisions_view) ∧ 类别+992==0 ∧ ∉to_re_enable ∧ (taken ∨ visible) | decision_item | 定案 |
| 行状态码 | sub_141723540 / sub_1417235E0 | taken∈ds{64/76}→3/4; visible(sub_1407367D0→"should_show") ∧ available(sub_1407313C0→"is_available") → 1/2 (cost sub_140726C20 分) | 0=隐/1=成本足/2=成本未足/3=采纳/4=采纳+冷却 | — | 定案 (链) / 语义高置信 |
| 行采纳勾选 | item+1312 dword | 状态∈{3,4,10,11}→1 | 已采纳显示 | — | 高置信 |
| 行名/图标 | sub_14072D610 (题) / sub_140B45190 (图标) | def+288 名; def+2444/+2528 分支附目标上下文 | ignored 集查询 cc+5360 (名键) → 状态元 1/2 | — | 定案 (读法) / 集语义推定 |
| 行按钮可用 | sub_14072FB10 / sub_140731E80 | **def+2816 ∧ def+2817** | 可选/可用双 byte 门 | — | 定案 (门) |
| 定向决议行 | pass B: ds+232 门 sub_141723CE0 / ds+256 门 sub_141723DD0; Setup 0X141D78360 | **entry @item+4024**; entry+40 state≠2 ∧(==1 ∨ sub_140736980); 源2 state∉{2,4} | targeted 族枚举 (writer 定案 2/3/4) ✓; 目标域触发 = entry+32 tag / +36 state 建 scope | targeted_decision_item | 定案 |
| 定向行目标国标 | Setup: entry+32>0 → sub_140B44AC0 | **entry+32 target_tag / +36 target_state** | 有目标 → 目标国旗/名; ≤0 隐 | — | 定案 |
| 定向行 ignore 态 | Setup: !*(entry+44) → 状态 2 | **entry+44 ignore** | CIgnereTargetedDecisionCommand 消费侧 | — | 定案 |
| 计时决议行 | pass C sub_141727BA0; Setup 0X141D78590 | **ds+160 → entry @item+2736**; entry+28 state∉{3,4} (timed 枚举) | active_timed 源; 日数 entry+24 | — | 定案 |
| 类别页签/头 | pass F sub_141726490; Setup vtable[19] 0X141D77970 | **类别 @item+72**; 类别源 = 行组键 *(def+368) + ds+304{c@316} 表 | 逐组挂格, Y+=vtable[17](136); 折叠表 win+1680{+1692} | category_header | 定案 |
| 类别描述行/头 | sub_141728AF0 分支 | **类别+480 = scripted_gui 名长字段**: 0 → InfoItem(0x88, win+1456 池) / 非 0 → EventCategoryHeader(win+1512) | `decision_category_desc` | — | 定案 (分支) |
| 类别可见门 | pass E sub_141727EC0 | **类别+568 ∧ sub_140731490 (+72 available/+976 power-balance/+992) ∧ sub_140736910 (+248 should_show/+268)** | power-balance 类别 (+992≠0) 不进普通行列表 | — | 定案 (链) |
| 格容器 | populate 0X141729130 | **win+1408 `decision_grid_container` / +1416 `decision_grid`**; +1512 头 (0x190) | vtable[55](440)/vtable[54](432) 查名 | decision_grid | 定案 |
| 地图决议图标 | (未拆) | CDecisionMapIconItem (19 槽, `decision_mapicon_item`); OnMapLocatorItem `on_map_decision_locator_item` | ctor 0X1418B8DA0 / 0X141D70BC0 | — | 定案 (存在) |
| 事件行 item | sub_141729C70 (decision_grid 顶部: 先挂 EventCategoryHeader(win+1512) 再按 GUImgr+1536 全局事件表逐条建行) | **CDecisionViewEventItem (0x550, 池 win+1520..1544); 窗名 = `event_item` (ctor 常量); 宿主 = CCountryDecisionView 本体** | 与 EventCategoryHeader 配套 | event_item | 定案 |
| amount_to_take 窗簇 | sub_141920540 ← sub_140C2BF60 (宿主 obj+74192) | 窗 decisionview_amount_to_take_items / _timeout_bg / decisionview_button | **非 CCountryDecisionView 成员** (另一宿主); loc DECISIONVIEW_AMOUNT_CAN_TAKE_ITEMS / DECISIONVIEW_AMOUNT_TIMEOUT_ITEMS | DECISIONVIEW_AMOUNT_* | 推定 (归属) |
| 坐标校准 | — | **@48 方法 this = win+48 (第 6 例: Repopulate a1+1344→win+1392, a1+1660→win+1708)** | 主表方法 this = win 无位移 | — | 定案 |

余量定案:

| 项 | 结论 | 证据 |
|---|---|---|
| CDecisionCategory | sizeof 0x3F8; 双 vtable; ctor 0X140723750; 装载器 "Duplicate category" 断言; key 派发器全落名 | 断言+二进制文件 |
| CDecisionCategory+544 | SOnMapLocator vector (304B 元素, key 15048 = on_map_area) | — |
| CDecisionCategory+464 | scripted_gui 名串本体 (MSVC SSO: 缓冲@+464 / **size@+480** / cap@+488; ReadKey case 14961 写 +464; ctor sub_140723750 清零块 +464/+480=0/+488=15) | 二进制文件 |
| player_settings (token 14423) | 内 ignored 决议名集; 写侧 CIgnoreDecisionCommand 0X141157240 + CIgnoreAllAvailableDecisionCommand 0X141156FD0; pinned/新高亮排除 | 二进制文件 |
| on_map_mode 枚举 | 0=map_only / 1=decision_view_only / 2=map_and_decisions_view (默认 2) | — |
| binder→命令映射 | CSelectDecisionCommand 14345 / CIgnoreDecisionCommand 14768 / CSelectTargetedDecisionCommand 14383 / CIgnoreTargetedDecisionCommand 14769; TimedItem 复用 14345; CategoryItem cb = 折叠切换非命令 | RTTI |
| 窗名 | TimedItem = `timed_decision_item`; EventItem = `event_item` | ctor 常量 |

**定案 6 项**: cat+496 = **decisions 容器** {data@496, cap@504, count@508, alloc@512} (写点 sub_140725F50 逐类别 push; 消费 sub_140734EC0 可用决议遍历) / cat+336 = **`visible_when_empty` u8** (键 15243; ReadKey sub_1407332B0) / cat+1008 = **power-balance 类别值 i32** (默认 −1; 类别名副本 = +976 串, **size@+992 / cap@+1000**) / SOnMapLocator = **CDecisionCategory::SOnMapLocator** (vftable 0x1427EB2E8, ctor sub_140724070; 304B 元素: +8 内嵌 CScriptTargets / +264 zoom 键 11793 / +272 loc 名 键 27 默认 ON_MAP_DECISION_NAME_DEFAULT / +288 size / +296 cap) / GUImgr+1536 = **CInGameIdler 全局待显事件表** {data@1536, cap@1544, count@1548, alloc@1552, 游标@1560}, 元素 = **CEvent\*** (id u32@0) / amount_to_take 宿主 = **CTopBar+39144** (窗 `decisionview_amount_to_take_items`, +39152 配 `_bg`; 装于 [2] Reload sub_14189ECF0 体内的 sub_14189EF20)。
**前提证伪 2 项**: 「pass D 排序键」不成立 — sub_141727810 是**地图/隐藏决议收集 pass** (门 sub_1407312F0 + sub_140736AE0(cat+336) + sub_140736910(cat+248/268)), 全 pass 后**无 sort 调用** (worker sub_1417297C0 尾段仅释放临时容器 + grid 刷新), 行序 = 各 pass 调用序 (A 普通 → B 定向 → C 计时 → D 地图 → E 类别 → F); 「def+272 写点」**不存在** (全 dump 0 写点, 推定偏移笔误 — decision def 串区在 +288)。

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
| 机构面板目标 | 无存储 SetTarget; @48[9] 0X140F2F3A0 现取 | **owner vtable[20] tag → cc → ag=\*(cc+4032)** (§4.3/§4.11.14 ✓) | 「自见」变奏 (§4.30.3/§4.30.11 同款); 面板恒显查看国机构 | countryintelligenceagencyview | 定案 |
| 机构名/徽标 | Repopulate 0X140F2F3A0 | **ag+128 name SSO → win+1448; ag+160 icon SSO → win+1672 (vtable+728)** | 书 ✓ 两恒写槽的 UI 出口 | agency_name / name_logo | 定案 |
| 分支升级格 | Repopulate + CBranchUpgradeButtonEntry (sub_141A230F0) | **DB qword_14332EDC0 {count@+124, items@+112}** → 窗 `upgrade_button`; ag 回指 @entry+40 | 分支/升级条目 (def@+48); `agency_branches` 格 | agency_branches | 定案 (读法) / DB 类名未定 |
| 行动列表 (operations) | @48[6] Update 0X140F2F720; [4] 预算 CalcOperations 0X140F29150 | **4×SBufferedOperations 静态 (unk_14333D420/A8/C0/D8)** × tag 过滤 → 0xAC0 行 {+2728 序, +2736 COperation\*, +2744 纪元快照}; 纪元 qword_14333D4C8/14333D528 | 行动页数据流 (tbb 并行预算); 行级 COperation 14 字段定案见 §4.31.14 | — | 定案 (机制) |
| 面板内省点击→密码过滤 | [11] 0X140F2C150 | **prov+192→state+204 controller → CCryptologyView+48** | 省转发变奏 (§4.13 ✓) | — | 定案 |
| 密码头部: 防御等级/解密强度 | sub_141A221C0 | **crypt=\*(ag+288)**; LEVEL = **mdef 528 = crypto_strength** (528/529 是 modifier def 索引非 lexer token) @\*(crypt+8)+1464; STRENGTH = sub_1413F7C60(crypt, level) | §4.3 修正式出口 | CRYPTO_DEFENSE_LEVEL/LEVEL, CRYPTO_DECRYPTION_STRENGTH/STRENGTH | 定案 |
| 密码部门激活旗 | sub_1413F86E0; 触发器 CIsCryptologyDepartmentActive::Evaluate 0X1403DA800 | **mdef 529 = crypto_department_enabled** ≠0 | 显 `crypto_not_active` (==0) vs `active_crypto_items` + 国表刷新分支 (≠0; 极性消解 = 与触发器名同向) | crypto_not_active / active_crypto_items | 定案 |
| 密码国别行 (cryptology_country_entry) | Setup sub_141A223E0 | **tag @entry+32**; 记录 = **CCountryDecryptionState 56B** {tag+8, days+12, 全解密+16, 解密中+18, 进度分子+24} @玩家 crypt 24B 槽 {data+40, count+52} | 玩家侧对目标国的解密账本 (operatives/cryptology.cpp 断言实名) | cryptology_country_entry | 定案 |
| 行进度条 | Setup: 100000×分子/分母 → clamp 1..100 | 分母 = **目标国自身** mdef528 式 `qword_143333030 (=CRYPTO_BASE_CRYPTO_LEVEL) + qword_1433330F0 (=CRYPTO_CRYPTO_LEVEL_PER_CRYPTO_UPGRADE)×level/1e5` (define 注册串定名) | 披露门 = 分子≥同式; 无分母 → -1 | entry+3984 簇 | 定案 |
| 行状态文案 | Setup 分支 | +16 旗 → CRYPTO_FULLY_DECRYPTED/CRYPTO_FULLY_ACTIVATED; +18 旗 → CRYPTO_DECRYPTING/CRYPTO_NOT_DECRYPTING (天数 sub_1413F7960); REVEAL_INTEL(_LEFT) ← dword_1433331A0 ∨ 记录+12 | 解密状态四态 | CRYPTO_DECRYPTING / CRYPTO_NOT_DECRYPTING / CRYPTO_FULLY_DECRYPTED / CRYPTO_FULLY_ACTIVATED / REVEAL_INTEL / REVEAL_INTEL_LEFT | 定案 (读法) |
| 行候选门 | sub_141A228B0 + sub_1413F8640 | 排除 自国/同国(140BA60A0)/tag≤0/**cc+1156 owned_states≤0** (§4.3 ✓)/自国·同阵营 (cc+3976+656 §4.5 ✓) | 只列「有争议州且非友方」的国 | country_list / country_list_container / add_new_container | 定案 |
| 账本面板目标 | **vtable[7] thunk→sub_1419DABD0**; @48[9]→vtable[4] 0X1419DB0B0 | **win+5456 tag 存储**; 缓存脏旗 \*(qword_14333CFB8+48)+83; win+5460 计数; win+5248 mode | 「tag 存储」变奏 (§4.30.9 同族); CReloadableView 9 槽新骨架 | country_intel_ledger_view | 定案 |
| 账本四页签 | populate sub_1419DAC10 | 块 +5256/5304/5352/5400 × 区 +96/1384/2672/3960 (**区 = CLegacyButtonObserverGlue\<CCountryIntelLedgerView\> 1288B**); 窗 econom/army/navy/air_panel(+_tab_frame); 区回调 = 置 win+5248 mode + **切 map mode 30** | economy/army/navy/air 四视图 | econom_panel 等 | 定案 |
| 页签面板刷新 | vtable[4] 分派 → 面板 vtable[1] 0X141EA9930 | 面板+8 = tag; vtable[2] 自填充 (navy 0X141ECCCA0 / air 0X141EAB690 / army 0X141EB85A0) | 换 tag 即全量重算 | — | 定案 |
| 共享头控制器 | sub_1415137C0 直写 | +5448 CIntelLedgerHeaderController {vtable, tag@+8} (0x10) | 四页签共享的目标 tag 副本 | — | 定案 |
| navy 页汇总行 | 面板 vtable[2] 0X141ECCCA0 | **cc+632/{+644} 容器** → sub_140D230E0 逐元聚合 {键, 数} | 目标国海军汇总 (书中未名) | — | 定案 (存在) / 语义推定 |
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
| 建筑资源双列 | sub_14155D120 | **st+368 建筑 × 资源块+480 的 +764/+768 × 等级 i16@+64 ×100000; 再 × (st+2256 RH 行值+100000)/100000** (按占领国折减) | 占领资源产出拆分; **双列 = "industrial_capacity" (+764+768 合计×等级, 零显 "-.-") 与 "resources" (州资源, 与 +764/+768 无关); +764 = 军工产线数 NUM_TOTAL_MIL_FACTORIES / +768 = 民用产线数 NUM_TOTAL_CIV_FACTORIES** | (数字×2) | 定案 (机制+列名) |
| 表头汇总条 | sub_14156F5B0 尾 | **win+11960 = Σ行+48; win+11968 = 均行+56** | 全账本合计/均值 | (数字) | 定案 |
| compliance/resistance 页签 | cb sub_141566A40 | **页管理器 sub_140E139B0 dword@0: 模式 6 = 抵抗视图 / 模式 7 = 顺从视图**; sub_140A66DE0 置页 | 与 §4.30.13 情报管理器同全局 (qword_14333CFB8 族) 的页号槽。⌛ 旧记 6(compliance)/7(resistance) 系按钮回调置页参数序推定, 已被 populate 体直证翻案: 模式 6 消费 cr+528 = resistance_modifiers (writer 键 15743) + 占领状态对 +88 名单, 模式 7 消费 cr+552 = compliance_modifiers (15747) + 占领状态对 +112 (resistancemapicons.cpp sub_14190A2D0 函数体直读; .gui 按钮命名与页内容互换 or 回调参数序误读, 二者取一不影响页语义定案) | compliance_tab_button / resistance_tab_button | 定案 |
| 排序/过滤页签 (5 枚) | cb sub_141565790 | **win+11880 = 按钮携带 id**; 列表 sub_14156B430/sub_14156B8E0 消费 | 二级页签 (排序类别) | — | 定案 (机制) |
| 只显抵抗国开关 | cb sub_141566B70 → 全重算 | 列表 B 生成门 (sub_140FF7780) | 开 = 同时列无抵抗占领国 | OCCUPATION_SHOW_NO_RESISTING_COUNTRIES / show_non_resisting_container_checkbox | 定案 |
| 开「选占领政策」 | cb sub_14156B310 → sub_141566D80 | 清 +11720 持有点 {+8,+16} → 弹策略窗 (过滤槽 +8 tag/+16 state) | 弹窗过滤槽变奏 | select_law_icon | 定案 |
| 开「驻军模板」 | cb sub_14156B3A0 → sub_141566CD0 | 同上开驻军窗; has_target 门 (+11832 vtable+176) | 需先选中目标州/国 | garrison_template_button | 定案 |
| 政策弹窗标题/数据 | [2] 0X14156D6B0 | tag>0: occdata(+160 日期); state: **st+616** (sub_1406F2F20 法 id, sub_140F99DB0 法); 空: occmgr+280 | 三态过滤 (国/州/默认) | DEFAULT_LAW_SELECTION | 定案 |
| 驻军弹窗模板列表 | [2] 0X14156C940 | **玩家cc+440 CDivisionTemplate\* 容器**; 默认法读取 = sub_140FF7BB0 (法 A = occdata+120 / 法 B = occdata+128) | 驻军模板 = 编制模板子集 | OCCUPATION_PRIMARY_GARRISON_TITLE | 定案 (读法) |
| 当前占领法旗标 | sub_140F99C00(cr,0) +24 | **cr+80 → controller occmgr → occdata → 按州查法 COccupationLaw\*** (+24 旗 SSO) | GetOccupationLaw 族 (断言串实名) | (旗标) | 定案 |
| 默认法旗标 (面板头·法 A) | sub_14156FE90 | **occmgr+120** 回退 → 旗标 +24 | 无州上下文的默认法 A | (旗标) | 定案 |
| 默认法旗标 (面板头·法 B) | sub_14156FE90 | **occmgr+128** 回退 → 旗标 +24 | 无州上下文的默认法 B | (旗标) | 定案 |
| 抵抗/合规状态小部件 | **Update sub_14156E190** | **cr+16 / cr+64 → 图标帧+百分比 (clamp 0..100)**; 门 **cr+520** | §4.13 CResistance 数值槽的 UI 直出口 | *_resistance_status_container / *_compliance_status_container | 定案 |
| 小部件修正列表 | Update 后半 | **cr+528 (15743) / cr+552 (15747)** + 状态行 cr+472/cr+496 + 全局触发表 sub_140319DE0 行[size+3] | 修正清单按 size 枚举分族 | occupation_modifier_entry | 定案 |
| 小部件进度条 | Update 尾 | sub_140F959F0(cr) 分子/100 → `min+(x/100000)×(max-min)` (vtable+232 查 max, +56 覆盖源) | 数值进度条标准三段式 | — | 定案 (机制) |
| 州状态行 (detail) | Setup sub_14156EF60 | **CState\*@entry+3904**; 双 StatusView@+3912/+3920; +3928 州名; +3944 GetOccupationLaw 族返回+80; **+3952 = 驻军模板旗标; +3992 = 表2 记录经 sub_140FF5490 计算的 1e5 进度值; 表3 记录+24 = CDivisionTemplate\* 驻军模板** | 州行 = StatusView 分发器 | occupied_territory_state_entry | 定案 |
| 行高/滚动 | 行 vtable[17](136)+4 / 格+128 子件 vtable+56 | 100000 滚动标度 (SetTarget 后定位选中行) | CStandardGridBoxItem 家族复证 | — | 定案 |
| 坐标校准 | — | 主表 this = win; **弹窗 [4] populate this = 弹窗**; **StatusView Update this = view (基子对象全在 view 内, 无漂移)** | 家族规律 | — | 定案 |

余量定案:

| 项 | 结论 | 证据 |
|---|---|---|
| cc+4048 类身份 | **CCountryOccupationStatus** (vtable 0X142982CF0, 书命名正确); 记录的 272B 布局偏移仍有效; 活体 +8=2/+16=0/+24=静态空对象, 与中立未占领态自洽 (§4.3) | GER 探针活体读 vtable |
| cc+4048 对象+8 | occmgr 回指 (非占领国 cc) | ctor 直证 |
| cc+4048 对象+32 | CState\* 向量 (非 SSO) | — |
| 表3 记录+24 / +3952 / +3992 | 表3 记录+24 = CDivisionTemplate\* 驻军模板; +3952 = 驻军模板旗标; +3992 = 表2 进度值; **记录法域定案 (活体+命令驱动)**: {+136 CGameDate (hours u32@+144) / +152 CGameDate (hours@+160 = 法设时间戳, 未设恒 0, CSetOccupationPolicyCommand Execute 直写) / +168/+172 = u32 数值对 (同法重设不变, 疑 compliance/resistance 族缓存) / **+176 = occupation law def 指针 (法身份槽, 各记录互异)**}; 附带: 记录元素 = 8B 指针 (tag@rec+8 实为回指 lo32, 对象层注记待校) | 命令驱动活体对账: martial_law_occupation 重设 FRA, +160 0→非零, +168/+172/+176 不变 |
| 国行 6 glue 钮 | 钉选 / 政策弹窗 / 驻军弹窗 / Release nation = CReleaseCountryDialog / Return territory / +6512 地图定位 | RTTI 实名 |
| WithoutResistance 条目 target | +1320 CState\*; tooltip = ret0 桩 (有意无 tooltip); 创建点 = E3C0 无抵抗分支 (被占领国 owned × 玩家控制 × cr+80≠被占领 tag) | — |

#### 4.30.15 后勤+贸易+市场 (LogisticsView / TradeView / MarketStockpileWindow)

**入口链**: LogisticsView = 17 槽第 13 例, 自见账本
(tag 懒存 view+6784); TradeView = 17 槽第 14 例, 自见 + 行级选择 (资源行+32 = 资源 def /
国家行+1328 = CCountry\*); MarketStockpileWindow = **新骨架 CEmbeddedWindow 四vtable族**,
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
| 特殊行 ×2 域 | sub_14172E380 | **item+988 = CEquipmentType 的 `group_by` 脚本键值 token (: vtable[4] KV 分发 sub_140C99410 case 13022, 默认 357="none"; 邻槽 +992 = interface_category token)** | 225="type" → **CLogisticsOverviewTypeItem** (0x5F8, 按 type 位掩码聚合); 12103="archetype" → **CLogisticsOverviewEquipmentItem** (0x5D8 单行); 默认 → OtherItem 桶 — 三 RTTI 类名直证; 「convoy/train」猜想证伪 (原版用户 = 导弹族) | — | 定案 |
| 「其它」行 | sub_14172E320 | 0x568 行 {桶 data@+1344, 计@+1356} | 域内非特判 archetype 聚合桶 | logistics_overview_*_other_entry | 定案 |
| 行数值 (库存/需求/缺口) | sub_141D9BFE0 → sub_141371450 族 | **\*(cc+3992) CLogisticsStatus** (logi+8 队列聚合; kind 1..6,14); 行 +1392..+1488; **+1440 = k6−Σk1..k5** | 后勤账本行出口; logistics.cpp:0x2E8 断言 | (数字组) | 定案 (偏移) / kind 名未定 |
| 军工厂占用条 | sub_1417327F0 | **ps+696(总量)/728(已分配产线工厂)/752(转出合计≡760+768)/760(上缴宗主)/768(外赠目标国)** (bar = 100−比例转换) | military_factories_usage | military_factories(+_usage) | 定案 |
| 海军工厂占用条 | sub_1417327F0 | **ps+792 (船坞总量)** × sub_140E69130(ps) | naval_factories_usage | naval_factories(+_usage) | 定案 |
| 优先级按钮 (低/中/高 ×3 域) | cb 0X141730780/D3A0/D0B0 → post | **CSetFuelPriorityCommand {tag@+40, category@+44=域号, level@+48}**; Execute → sub_1410F80A0 单写 consumer[域].priority; 分配按 2→1→0 高先得 (§4.3.16) | 后勤分配命令 (§4.00.6 post ✓) | low_prio / medium_prio / high_prio | 定案 |
| 油料子窗 | sub_141D900D0 / sub_141732C30 | **\*(cc+5504) fuel_status**; 窗柄 view+6712; 四条 fulfilled 柱 = 三军域柱 (fuel_consumer_data 逐域 Σrequested/Σreceived, §4.3.16 域表 [0]陆/[1]空/[2]海) + 国比柱 (sub_1410F3570×100); 折线图数据源 = CLogisticsStatus (\*(cc+3992)) 19 元序列数组**元素[17]** (桶 +136, 7 列 = FUEL_DATA_COUNT; 读数器 sub_141D8D190 读 ld+136 + ctor i==17 特判 cols=7 + 活体桶 17 cols=7 三证), 非直读 24 小时环 | fuel 类型分支 (断言 "invalid fuel type") | logistics_fuel_window | 定案 |

**燃料窗对象槽位** (logisticsfuelwindow.cpp 两函直证; 类名本簇无 RTTI/断言实名, 推定 CLogisticsFuelWindow):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +3864 | uint32 | 时间标度模式 (0 = DAYS / 1 = MONTHS / 2 = YEARS; 越界 → :358 B51 断言「Not Supported!」) |
| +3868 | uint32 | 对比模式 (0 = 单国, 非 0 = 6 国对比) |
| +3872 | 对象* | 国家解析器 (vtable+160 → tag) |
| +3880 | GUI 上下文* | CreateWindowByName 宿主 (vtable+104 / vtable+120) |
| +3888 | 图表控件* | 折线图 (清/挂系列两原语) |
| +3896 | 燃料行项窗口* CPdxArray | 国家行项池 {data@+3896, count@+3908}; 元 = "logistics_info_fuel_line_entry" 窗口; **池长度跟选国数, 非 6 国满建** |
| +3920 | 控件* | 模式切换链同触 |
| +3928 | 控件* | 尾部消费 |

行项窗口 (logistics_info_fuel_line_entry, ctor sub_141D8BC80): +1320 uint8 **有数据旗** = 行件入图门 (系列构建与模式切换链一律以 `行项+1320 != 0` 过门)。

轴标签填充器 (sub_141D8D730): 三文本窗名经 qword 常量逐字节解码确认 = "min_x_value" / "max_x_value" / "x_axis_type"; x 轴类型按模式 0/1/2 → loc 键 LINECHART_DETAILS_DAYS (id 22) / MONTHS (24) / YEARS (23)。系列构建 :281 断言门 = FUEL_GRAPH_COLOR 尺寸 dword_143338E14 == FUEL_DATA_COUNT×3 (合法值 21)。

国家选择全局量 (.data): dword_1430B5EA0 / qword_1430B5EA4 / qword_1430B5EAC / dword_1430B5EB4 = 6 国对比槽 (idx 1..6 连续), dword_14338C6E4 = 单国槽 (模式 0); 全部 5 个全局量在 217MB 语料中**零写者** (仅 5 读点), 疑经寄存器计算地址或指针写入, 未决。
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

#### 4.30.15a CEmbeddedWindow 建窗 (embedded_window.cpp; 1 函, 推定)

`sub_141F31A00(a1, a2)` (推定 `CEmbeddedWindow::Create(bool)`):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +8 | std::string | 窗口名（模板名） | 拷出作建窗第二参 |
| +56 | 父宿主对象 (8B) | 传子精灵 GUI 对象 vtable 槽 69（+552） | 挂接步骤实参 |
| +96 | 建窗上下文/父管理器 | 精灵工厂 `sub_1422B8BC0` 首参 | 书载「精灵工厂按名建」交叉验证 |
| +112 | 窗实例指针 | 建窗出参；重复 Create 被 :94 门拦 | `_pWindow == 0 && "Window already created."` (B52 闩 byte_14338CA0E) |

建窗实例名 = 模板名 + `"_Instance"`（`sub_14011DBC0` 追加，SSO/堆分支，长度 <9 时 reserve 9）；
挂接取 `实例+48` 子精灵 GUI 对象调其槽 69；收尾：a2 真 → 自身 vtable 槽 11，返回自身 vtable 槽 6 调用结果（槽语义推定）。
#### 4.30.16 散簇·铁路炮+轨道图标 (CRailwayGunListView / StatsView / CRailwayMapIcon)

> CRailwayGun 单位侧布局与 GUI 消费全表见 §4.18.2。

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
| host 类名 | CRailwayGunListView 宿主 = **CArmiesView** (vtable 0x1429E9C98); CRailwayGunStatsView 宿主/开启者 = **CRailwayGunListView** (vtable[7] sub_141D01840 建/取 stats view 并缓存宿主 +2632) | 建件点 sub_1416AE5D0 双件 (与本节 §4.30.29 CArmiesView @+1416/+1424 一致) |
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
| 舰队底栏条目 | SetTarget 0X141DE6F60 | **CFleet idpair 快照 @item+32**; fl+224 name (§4.16 ✓) | 解散 = CConfirmDisbandFleet; 已结: fl+24 = CSelectable 次表 / +44+56 = hours_without_patrol RH 头 / +184+196 = tf 容器头 (§4.16.4 全表) | navy_leader_window | 定案 (target) |
| 舰队底栏 | 选择集+1100 idpair | resolve → +32 CFleet\* 数组 | 属主 = CInGameIdler vtable[23] 地图模式接口对象的选中 idpair (模式切换 sub_140E17F30 → sub_140B68320) | — | 定案 (形态) |
| 海军总览 | Setup 0X141819200 / UpdateButtons 0X14181D070 | tf ship 容器 (tf+840/852) / repair_parent (tf+1200/1204) / target_ship_types (tf+1856/1868) / refid + gs 玩家 tag | 四子件内嵌 (LeaderWindow/MoveShips/CompositionEditor/CompactShipList); 候选 tf+884 任务类型枚举见 §4.31.5 (定案) | — | 定案 (命中) / 候选推定 |
| 沉船图标 (海战参战) | populate 0X1417EFDB0 | 参战舰组 40B {ptr 数组@0, count@+12}; 记录 W: +32 owner tag/+64 pride u8/+136 舰体名串 | icon 帧 = is_sunk+1 (帧2=沉); pride 金/灰双色 CColor | — | 定案 (形态) / W 推定 |


**窗壳重锚**（1.19.3：海军 GUI 群全结构偏移零漂移，地址整体平移；TD/vtable 全表）：

| 类 | vtable (1.19.3) | 主 vtable | ctor | 备注 |
|---|---|---|---|---|
| CNaviesView | 0x142A06850 + @40 0x142A06878 | [2] Reload 0x141816D20 / tt [0] BuildTooltip 0x141809190 | **0x1418029A0** | 17 胶水块 @+304..+20912 步距 1288B 全清；+120 CCompactShipListView / +22200 detailed_fleet_list / +22216 CTaskForceCompositionEditor / +22240 CNavyLeaderWindow / +22248 CMoveShipsWindow / +22256 舰船视图厂 / +224 哨兵 / +22232 舰船选择子件 (Setup 直证)；胶水块 ctor 0x141801810；行为全案与 9 块胶水语义 = §4.16.23 |
| CFleetsBottomBar | 0x142A001A0 + @40 0x142A001C8 | [2] Reload 0x1417A68F0 | 0x1417A4F10 | tt [0] = const-false 0x14011D220；Setup 0x1417A6930 / **条目重建执行体 0x1417A5CA0** (populate 本体; 旧记 0x1417A5300 系误标 — 该 VA = CNewFleetBottomBarButton ctor, RTTI 直证 §4.30.52) / Reload 前段 0x1417A5B10；**+2800 = btn_scroll_left / +2808 = btn_scroll_right**; +2784 占位项 = **CReserveBottomBarItem 实例** (工厂 0x141DE5F60 malloc 0x548, §4.31.44 CReserveBottomBarItem 同类互证); 运行期详表 §4.30.52 |
| CFleetsBottomBarItem | 0x142A7A0F8 + tt 0x142A7A198 | [0] dtor 0x141DE6140 / tt [0] BuildTooltip 0x141DE6440 | 0x141DE59E0 | SetTarget 0x141DE6F60（项+32 CFleet idpair 快照）；提示注册器 0x140B77E10 (@+2704/+4072) |
| CSunkShipEntry | 0x142A054B0 + tt 0x142A05550 | [0] dtor 0x1417F4210 / tt [0] BuildTooltip 0x1417F6840 | 0x1417F5C50 | populate 0x1417FD790 |
| CSunkShipIcon | tt@0 0x142A046F0 / 主@8 0x142A04708 | tt [0] BuildTooltip 0x1417EA710 / 主 [0] dtor 0x1417E3200 | 0x1417E2460 | populate 0x1417EFDB0（a3 = is_sunk）；网格填充宿主 0x1417ED140 族；池工厂 0x1417F5C50 同族 |
| CNaviesViewSunkShipItem | 0x142A4F008 + @56 0x142A4F078 + @72 0x142A4F140 | @72 [0] BuildTooltip 0x141BEB240（拷 this+8 串 → item+80） | 0x141BF0140 | 三 facet 类 |
| CShipStatsView | 0x142A4F278 + @40 0x142A4F2A0 + @48 0x142A4F2B8 + @64 0x142A4F2F0 | [2] Reload 0x141BED890 / tt [0] BuildTooltip 0x141BEB270 / @48 [1] Update 0x141BEFB60 / @48 [2] populate 0x141BED870 / @64 [7] 逐帧 0x141BED5F0 | **0x141BE8C90** (dtor 体 0x141BE99D0) | 七胶水块 @+88..+7928；+6632 目标 idpair / +9216+9224 军官柄 / +9232 CButtonWrapper / +9248 CButtonObserverGlue / +10552 缓存；sizeof 0x29D0 |
| CCompactShipListView | 0x142A7EA90 | [0] const-false 0x14011D220 / [1] dtor 0x141E11AA0 | 0x141E11730 | +48 CSimpleEmptyEntryList\<CCompactShipEntry\>；sizeof 0x58；**更新主入口 0x141E12B70 = UpdateCompactShipList** (读侧 +8 条目宿主容器 / +16 CShipCategorizer\* 非空 → 条目 +1352/+1416 装 lambda 且 +1344 置 1 / +56..+80 = 内嵌件 data/cap/count/alloc/游标镜像；详见下方段) |
| CCompactShipEntry | 0x142A7E8A0 | [0] BuildTooltip 0x141E11E40 / [1] dtor 0x141E11960 | 0x141E10F30 | sizeof 0x620; +1336 舰型 DB 索引 / +1340 需求舰数 / **+1344 分类器模式旗 / +1352/+1416 两 std::function (CShipCategorizer lambda) / +1480 条目子窗口 / +1488 父容器摘挂点** (详见下方段) |
| CNavalCombatView | 0x142A04868 + tt 0x142A04890 | [2] Reload 0x1417EA930 / tt [0] BuildTooltip 0x1417E88A0 | 0x1417E1FD0 | +2784 side=1 / +3272 side=0 (CCombatBoxGrids 嵌套 ctor 0x1417E1510)；sizeof 0xF30 |
| CNavalLossesOverview | 主 0x142A05AF0 + tt 0x142A05B18 | [0] dtor 0x1417F40B0 / [2] Reload 0x1417F7210 | — | Setup/填格 0x1417F98B0 (另 0x1417FA310)；释放 0x1417F4EE0 |
| CNavyLeaderWindow | 0x142A38158 (另 0x142A381C8 / 0x142A381E0) | [2] Reload 0x141ACD050 | 0x141ABD920 (malloc 0x1B98) | §4.31.2 簇 |
| CMoveShipsWindow | 0x142A4B338 (另 0x142A4B360) | [2] Reload 0x141BBC770 | 0x141BBAEE0 (malloc 0x5D8) | — |
| CTaskForceCompositionEditor | 0x142A800D0 (另 0x142A800E8) | — | 0x141E1FA10 (malloc 0x20B0) | 宿主 CNaviesView+22216 |
| CConfirmDisbandFleet | 0x142A9EF08 (另 0x142A9EFA0) | — | 未复核 | vtable 已锚 |
| CChangeNavyLeaderDialog | 0x142A8ED50 (次 0x142A8EDE8) | — | 未移植 | 基 CDefaultConfirmationPopUpWindow; 海军将领更换确认弹窗 |
| CFexShipIcon / CDeleteShipCommand / CDisengage…Command | 0x142A04638 / 0x1429B2910 / 0x1429B07B8 | — | 命令 ctor 0x14135FEC0 / 0x1413467C0 | 见下行命令族行 |

**CCompactShipListView 更新链与 CCompactShipEntry 布局** (compactshiplistview.cpp; 清单名 `actshiplistview.cpp` = 断行伪影, 真名 compactshiplistview.cpp):

| 偏移 (CCompactShipListView 88B) | 类型 | 语义 |
|---|---|---|
| +8 | 指针 | 条目宿主容器对象; 每条目以名 "entry" 挂接其下 (vt+216) |
| +16 | CShipCategorizer* | 非空 → 条目 +1352/+1416 安装两 lambda 且 +1344 置 1 |
| +56 | CCompactShipEntry** | 列表数据 (= 内嵌件 +8) |
| +64 | int32 | 容量 (= 内嵌件 +16) |
| +68 | int32 | 计数 (= 内嵌件 +20) |
| +72 | 指针 | 分配器 (vt+8 allocate / vt+16 deallocate) |
| +80 | int32 | 游标; 更新前置 0, 遍历中写当前下标 |

> UpdateCompactShipList (0x141E12B70, lambda 描述符直证): 源 = 引擎向量 (data@+0 / count@+12 / 元步距 32B, 元+4 = 舰型 DB 索引, 元+8 由 sub_141E13050 消费); 源计数 ≠ 上次游标 → 逐元 sub_141E12240 释放旧条目再重建 (几何扩容 max(count+1, (int)(cap×1.5))), 否则原地复用; 每元调回调 a3(view, entry) 后 entry+1336 ← 源元+4 + 窗口 vt+48 刷新; 返回 = 各条目窗口 vt+232 计数累加。CCompactShipEntry ctor 0x141E10F30 第二实参 = qword_14332F698+1272 (§4.16 未决项新证据)。

| 偏移 (CCompactShipEntry 1568B) | 类型 | 语义 |
|---|---|---|
| +1336 | uint32 | 舰型 DB 索引 |
| +1340 | uint32 | 需求舰数 |
| +1344 | bool | 分类器模式旗 (源 = view+16 != 0) |
| +1352 | std::function | lambda 1 (取 CShipCategorizer& + 成员函数指针 void(CCompactShipListView::\*)(CCompactShipEntry&)) |
| +1416 | std::function | lambda 2 (同族, 第二参数 const CTaskForce\*) |
| +1480 | CWindow* | 条目子窗口; 空 → 断言 "Use after free!"; 非空而 +1488 空 → 断言 "No parent window to attach to!" |
| +1488 | 指针 | 父容器摘挂点; 旧对象经 vt+224/vt+464 摘链, 新值 = view+8 以名 "entry" 经 vt+216 挂接 |

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
> Reload 辅助 0x14181BB10 / UpdateButtons 0x14181D070（lambda vtable 0x142A07E88/EC0/EF8）/
> ConditionallyShowManufacturerList 0x141806E40（lambda vtable 0x142A07F30）；CShipStatsView
> Reload 释放旧窗 0x141BEA0D0 / 全量重建 0x141BEE020 / 观察列表重注册 0x141BEF3A0 / 军官钮刷新
> 0x141BEFF40（+10552 缓存 + ship+24 vtable[1]→+32）。海战视图: Reload 重建 0x1417E4030 /
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
LandLicenseEntry = 零覆写类 (双 vtable 与 CLicenseProductionEntry 全同), 仅窗口名
"request_license_land_entry" 异。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 战斗进度/宽度虚槽 | combat vtable[25] / vtable[26] | (虚槽, 无存储偏移) | **进度 = vtable[25] / 战斗宽度 = vtable[26]** (6 虚槽语义定案) | COMBAT_PROGRESS 族 | 定案 (读法) |
| 标题+地形 | 0X1415D9A20 | combat obj+40 location / +48 day | 地点+日期标题 | — | ⚠ 定案: obj+40/+48 = 攻/守 cb 侧指针 (cb+56/+72 单位数+首单位 tag 攻守判定) 选标题 BATTLE_ATTACK/DEFENCE/BATTLE/BORDER_CONFLICT (vtable+80==14757 门); 地形 obj+184→def+168 名 + 天气 _winter; 全函数无 location/day 读 |
| BORDER_CONFLICT 判定 | (谓词) | **vtable+80 == 14757 = border_war_combat** | token 表直证 | — | 定案 |
| 参战方/将领面板 | 数据泵 0X1415DAE50 | cb+56 参战链A / cb+304 tactic / cb+232/{+244} front 列表 / cb+344 anti_air_attack / cb+352..400 统计 | §4.22 全中 | UNIT_LEADER_NO_LEADER 等 | 定案 |
| 地图图标位置/点击 | GetPosition 0X1418BC9A0 / OnClick 0X1418C3040 | 战斗省 map_obj+4688 xyz + 攻击出发省边点数组+4568 中点 + atan2 攻击方向角; unit+664 = 移动路径环境因子缓存非空门 (§4.18 定案, malloc 0x88 堆对象; 图标锚 = 侧内首个正在移动的单位) / unit+496 = location 对象指针 (省 id@+164) (新发现) | 攻击方向角定位; 点击直开陆战视图 | — | 定案 / 新发现未决 |
| 候选新偏移 | 数据泵 | combat obj+160 / terrain def+104/+112 / cb+8 / cb+408/460 / leader name@+64 country@+288 / gs+684 | 宽度修正系数 (二进制文件 + 探针活值) / 基宽与每增向宽度 (vtable[26] sub_1412ADE10 一函数三偏移直证 + 活读 forest 60/30 等) / 修饰旗位段 (值已采, 位义未决) / org_loss_summary 互证 (序列化面无书证, runtime-only) / 高置信互证 / **gs+684 更正** = CSettings 单例 qword_14332F408 (968B, 内嵌 CMapRenderingOptions@+376; ctor sub_1401F9A60) : **+684 = byte 设置门** (只读 — 图标帧 SetFrame((byte==1)+1) / EquipmentType.IsAir 帧式 2×(type+960)−(byte!=1) / 两套常量表切换, 84 调用点全读; ctor 后 0, 写点未定位疑 settings 装载通用通道) / **+680 = dword 0/1 toggle** (CMapModesInterface 回调 sub_141577250 翻转, 定案) — 「地图状态序号」推定撤销 | — | 定案 (+680) / 高置信 (+684 byte 门; 活体: read_u8(CSettings+684) + 切地图模式观察 +680) |


**建窗 sub_1415D8FB0**: view+2728 (a1[341]) 为空时经 view+2736 (a1[342] CWindowsManager) +1272 (vtable+96) 创建窗口, **窗口名 = "landcombatview"**; 创建失败 → CLogStream 通道 65540「Failed to create land combat window」(:1264)。window+48 vtable+552 挂 view+40 上下文; 按钮 "close" (vtable+104) 绑 view+56; "tactics_list_button" 绑 view+168。CTacticsListView = malloc(0xB20) + ctor sub_1415CC3B0(inst, 管理器, qword_14332F6A0 vtable+184); 双 traits 网格 = malloc(0x60) + ctor sub_141C73C90(obj, 管理器+1272, 子件经 window vtable+432 取 "attacker_traits_grid" / "defender_traits_grid")。

**标题判定细化** (sub_1415D9A20): 标题串取自 window vtable+120 "window_title"; 玩家 tag = `gs+1316 if gs+1312 > 0` (由 `gs+328 > 0` 选择); 战斗类型 = `combat+80 == 14757` (border_war_combat) → BORDER_CONFLICT, 否则攻/守侧 (cb+72 计数 >0 ∧ cb+56 首 tag == 玩家 tag, 或 sub_140BB52F0) → BATTLE_ATTACK / BATTLE_DEFENCE, 皆否 → BATTLE_BATTLE。**地形**: combat+184 → +168 地形名; 精灵名 = "GFX_terrain_"+名; 若天气源 (gs+1672 偏移族) + 省份 id@terrain+164 的 +64 > 0 → 追加 "_winter"; 精灵 "terrain_picture" 经 window vtable+136 → vtable+728 置串; 缺失 → CLogStream 通道 65543「Missing spriteType "..." for terrain "..." used in combatview.」(:1339)。

#### 4.30.19 散簇·地图模式/图标基族 (CMapIcon / CMapIconManagerImpl / CMapMode / CMapModeWithButton / MMD = CMapModeMilitaryDeployment / MMDToOrder = CMapModeMilitaryDeploymentToOrder / CMapModeOperationSelectTarget / CMapModesInterface / CAllMapModesEntry)

业务侧字段权威 = 本节 §4.30.26 (基族全布局 + 派生散件 A/B); 本节保留视图侧索引

类布局 (类名 / target / 锚点):

CLandCombatView (0xAF8):

| 项 | 定案 |
|---|---|
| target 形态 | view+48 token 对 (SetTarget 0X1415D9A20 从 combat obj+24 holder 对拷入; resolve−16 = CLandCombat obj) |
| populate 链 | slot2 0X1415D7E00 → 0X1415D8FB0 (建窗) / 0X1415DA220 (tactics) / **0X1415DAE50 (数据泵)** / 0X1415D9A20 (标题+地形) |
| 册内偏移复核 | 视图消费与册内布局一致: obj+24 holder / +40 location / +48 day / cb+32 unit 容器 / +56 参战链A / +72 / +232/{+244} front 列表 / +256/+268 / +304 tactic (探针正名) / +320 / +332 / +344 anti_air_attack / +352/+360..+400 统计 |
| 实例 | malloc(0xAF8) = 2808B, 挂宿主+504 (工厂 `sub_140B614C0`; naval 同厂挂 +496); 主表 4 槽 ([2] populate / [3] CFG 空桩) |
| 尾段布局 | +2728 内容窗 / +2736 管理器 / +2744 CTacticsListView 实例 / +2768/+2776 攻守参战侧对象 (见下) / +2784/+2792 attacker·defender_traits_grid 面板 / +2800 战斗序号缓存 (读地图单例+684, 变更置泵旗) / +2804 数据泵已跑旗 |

新发现核验结果:

| 项 | 位置/值 | 状态 |
|---|---|---|
| 战斗宽度修正 | combat obj+160 | 高置信: 活值槽 (单样本 fixed 0.1, 探针); 语义推定宽度/战术修正 |
| 地形宽度 | terrain def+104/+112 | 字段定案 (探针活读: forest 60/30, hills 70/35, mountain 50/25, plains 70/35, 海/湖 0/0); (x, x/2) 对语义推定留文件对账 |
| 修饰旗位段 | cb+8 | **位义定案**: 侧修正图标驱动位段 — 八值枚举 {2,7,10,13,27,8,17,16 → 图标 0-7} 三处互证 (CCombatantSideModifierIconEntry populate: cb+8 位段 ∧ cb vtable+248 ∧ sub_1401F6EA0(cb)+152 三源); **触发器侧双读向**: has_combat_modifier 同读 cb+8 作 BM_* 战斗修正位旗 (名表 sub_141452A20) — 同一位段两层消费 (双读向并存) |
| 强度缓冲 | cb+408/460 | 定案: 与主表 org_loss_summary 行互证 (环形 count24 ≤ num27, idx=3, 探针); 本行冗余可并 |
| leader 名/国 | leader name@+64 / country@+288 | **定案否定** : cb+304 对象 RTTI = **CCombatTactic** (+64 无名串); 下表「+304 current_leader」应正名 tactic |
| 战斗序号 | gs+684 | 定案否定 (探针: 两次读均 ASCII 串缓冲字节, 非战斗序号) |
| 虚槽语义 | vtable[26] / vtable[25] | vtable[26] = 战斗宽度 — 定案 (sub_1412ADE10 一函数三偏移直证); vtable[25] = 战斗进度 — 定案 (sub_1413E1E10: 100000×攻方份额, clamp [0,100000]; 两方皆 0 → 50000) |
| BORDER_CONFLICT 判定 | token 表 vtable+80 == **14757 border_war_combat** | 定案 (直证) |

CLandCombatMapIcon:

| 项 | 定案 |
|---|---|
| target | +1424 ctor 写全局哨兵 `qword_14333D528` (运行时 0), 全语料无字面写者, 5 实例活读恒 0 — 「token 对」系 1.19.2 偏移漂移; **+1432 = CButtonStandard\*** (ctor 0, 运行时建; vtable 0x142B472E8 直证) 才是运行时填充槽 |
| sizeof | 1528 (0x5F8, 工厂 case 11 malloc 直证) |
| GetPosition 0X1418BC9A0 | 战斗省 map_obj+4688 xyz + 攻击出发省边点数组+4568 中点 + atan2 攻击方向角 |
| OnClick 0X1418C3040 | 直开陆战视图 |

map 省对象 位置/边点/可见旗 布局 + unit+664 目标旗 / unit+496 所在省 (新发现)。

CLandLicenseEntry:

| 项 | 定案 |
|---|---|
| 类形态 | 零覆写类 (双 vtable 与 CLicenseProductionEntry 逐槽全同) |
| 唯一区别 | 窗口名 "request_license_land_entry" |
| tooltip | 0X141F2F090 消费 entry+2560 token (装备 HEADER / PRODUCTION_ENTRY_OUTDATED 两支) |

⚠ 排雷: CTacticsListView 族 (0X1415CE480/0X1415CEFB0) 与 view 撞 +2728/+2768 偏移但属异类 (已甄别, 复核见 4.22.8)。

view+2768/+2776 定案: **攻方/守方「参战侧对象」缓存** (= 侧 cb 的 vtable+232 getter
返回物, 可 0; 侧对象 +16 = 领袖名串, +288 = country tag dword, +4168/+4172 token 对)。
写点三态: 清零 = ctor `sub_1415CD790` + 清屏 `sub_1415CE880` (每次 populate 前清);
唯一非零写者 = `sub_1415D8410` (攻 a4≠0 写 +2768 / 守写 +2776, `a1[346]/a1[347]`
qword 步进变更守卫式), 调用链 = vtable[2] populate `sub_1415D7E00` → 数据泵
`sub_1415DAE50` → `sub_1415DBD60` → `sub_1415D8410`; 休眠视图两槽恒 0 (活体复验)。
「双 leader 指针」说否定 — 领袖 UI 系按名 FindChild("attacker_leader" 等) 另找的
widget, 不落两槽。同偏移跨类撞车均已甄别: CNavalCombatView 两槽 = "leader_attacker/
leader_defender" widget 指针 (写者 `sub_1417EB690`, 语义不同); CNavalMissionUnitItem
两槽 = "spotting_bar_fg"/"spotting_bar_bg" widget (ctor `sub_14198CE60` 尾调
`sub_1419913F0` 绑定); 另有 CConfirmResearchTechnology / CDoctrineSharingFolderItem /
CTacticsListView 族 (0x1415C-D 段 +27xx 取字段须先过类归属)。

类布局 (类名 / target / 锚点):

view+11096 = ES (0x908B, divisiontemplatemanager.cpp 断言实名)。

| 偏移 (ES) | 类型 | 名称/语义 |
|---|---|---|
| +0 | 枚举 | 模式 |
| +4 | tag | 国家 tag (vtable[20] 根窗 → CCountry) |
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

三vtable:

| vtable | 槽 | 函数 | 语义 |
|---|---|---|---|
| view+0 主表 0x1429F82E8 | [9] | 0X14174A990 | Refresh |
| view+0 主表 0x1429F82E8 | [11] | 0X14174AA40 | SetTarget |
| view+0 主表 0x1429F82E8 | [14] | 0X14174AF00 | SetupDerived (lambda RTTI 实证) |
| view+0 主表 0x1429F82E8 | [15] | 0X141746070 | Clear |
| view+40 事件子对象 0x1429F8378 | [0] | sub_141747430 | tooltip 巨函本体 (19 分支); 2 槽表, 紧邻 @48 表 COL@0x1429F8388 |
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
| +8 | MSVC SSO 串 | gfx/图标名 (buf@+8/size@+24/cap@+32=15; ctor sub_140556100 空串三连直证; 活体「8B 小整数」= SSO 内联字符自洽) | |
| +24 | u64 | = +8 SSO 的 size 字段 | 过滤门 = 串非空 (语义定案) |
| +40 | string | 名 SSO (cap@+64) | loc 键 = 名 + "_desc" 附录 |
| +248 | 内嵌 CModifier (192B) | 静态基础值段 | 判空 sub_14060CF80@def+264 pairs 容器 |
| +440 | — | 动态槽元数据表 (216B/行) | count@def+452; 行 = mdef idx, 值 = entry.values 平行数组 ×1e-5 |

CDynamicModifierItem / BigItem / SmallItem: target = item+32 内嵌
SDynamicModifierEntry 64B 拷贝 (tag/state/days/def/enabled/values 逐字段命中
§4.13.4 布局 6/6); Big/Small 零自身覆写, 差异 = 窗模板
"spirit_modifier_entry"/"_small" + item+100 旗 (flagtextureatlas.h 直证);
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

**CTemplateEntry (正名纠偏 = CBuildingsNudger 的建筑模板行, 非师模板)**: feed = **建筑库 qword_14332EE28 ✓** (滤 **def+20>0 且 def+84==357**) + null 末条; def 名 = \*(def+8) token (lexer 直证); 副表槽9 = 选中高亮。
(入口链/模式条目/命令出口) + §4.30.38 (CMapModeManager 布局补全);
两部署模式类与 §4.18 互证 (ConveyorView+6800/+6816 scoped_ref
内嵌同族)。视图侧骨架: 激活流 sub_1417CAB50 = [1]CanActivate→mode+40=目标
省→[3]Commit; 取消 glue sub_1417CAB20 = +40 非空→[4]Cancel→清; 命令出口 =
qword_14332F6A0 vtable+136 命令队列。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 图标基类 21 槽 | 槽表全定名 | icon+8 名/+16 子精灵/+48 目标/+56 client/+108 层号/+116 旗 | +1424/+5985/+4688 = 派生区非基类 (复核) | — | 定案 |
| 图标管理器 | factory sub_140B71AF0 | **单例 qword_14333C5A8**; +8/+824 双 34 层数组 / +1840 精灵工厂 | mapiconmanagerimpl.cpp 实名; 调试层过滤 dword_143086368 | "mapicons_container" | 定案 |
| 部署选址模式 20 | [3]Commit 0X141F6BE40 | mode+1344=conveyor; 投 CSetConveyorLocationCommand(conveyor, **prov+164**) | prov+392 controller/+192→CState 州名全按 §4.14 消费 | CONVEYOR_ASSIGN_LOCATION_SELECT_{HOME_}AREA | 定案 |
| 部署指派模式 21 | [3]Commit 0X141DF3D20 | 投 CSetConveyorGroupCommand; order 源=*(qword_14332F6A0 vtable+200 对象+464) | **qword_14338C790 = 当前 hover 选中** ([11]写[10]清) | CONVEYOR_ASSIGN_ORDER_SELECT_AREA | 定案 |
| 行动目标择模式 29 | [1]CanSelect 0X141E339C0 | +1344 候选/+1368 窗/+1376 上下文/+1388 实现选择子 | prov+392→CState+88 州 id; [10]/[11] CState+20 字节旗; mapmodeoperationselecttarget.cpp:103 实名 | SELECT_STATE_ON_CLICK{,_DISABLED} | 定案 |
| 可配置模式条目 | OnClick sub_141575470 | entry+1360=mode id/+1368=父; **宿主+11712 起 11 槽 mode id 数组** | 件型 "ConfigurableMapMode"; custom 旗走 scripted 激活 | — | 高置信 |

**定案 8 项 + 推定 1 项**: icon+40 = **可清惰性缓存槽** (基 ctor 恒 0, 槽[17] sub_14163FB80 可清; 消费者 = 情报账本行件 sub_141682080 的 a1+40 = CCapitalMapIcon 懒建缓存, sub_140B72CA0 建 + icon+24 = 行件回链, sub_1418CE0D0 更新 icon+152 = CState*/+160 首都省 CRef — 非 CMapIcon 对象自身字段) / 槽[3] = **UpdateAndRealize** (层可见性 sub_1418BBB30 LUT + sub_140FA61D0 写 +112 + 定位 sub_14163FAF0 + 派生 populate 三合一) / 槽[9] = **图标类型数哨兵 18** (基类 sub_14163F4E0 返 18; **族内三值 1/10/18** — CVictoryPointMapIcon/CCapitalMapIcon/CAdjacencyRuleIcon 返 10) / 双 34 层表: **+8 = Reload 重建集** (vtable[2] sub_140B73CF0 只遍历 +8) / **+824 = 活性图标表** (vtable[4] Update 扩容易地 + 工厂 sub_140B729B0 push) / CMapIconGroup = {vtable@0, 图标 CVector@+8 {data@8, cap@16, count@20, alloc@24}, +32 当前图标, +40 = CMapIconLayer* 回指; CMapIconLayer+40 的 group 数组四件套 {data@40, cap@48, count@52, alloc@56} 勿与本类混淆} / OpST+1388 = **实现选择子模式枚举** (写点 = 工厂 sub_141828D50; 0 = 内嵌候选表命中门, 1 = 按实现逐条, 其它断言 mapmodeoperationselecttarget.cpp:103) / 调试命令 = **`map_icon_reload_type`** (参数 NUM; 无参 = 清 −1 全层重载; 体 sub_140284980 写层过滤全局 dword_143086368) / MMD[10][11] = **目标图标抑制/恢复对** (CMapModeMilitaryDeployment vtable 0x142A72268: [10] sub_141F6BB30 写 +20=0 / [11] sub_141F6BC80 写 +20=1; MMDToOrder vtable 0x142A722D0: [10] sub_141DF3C30 清 qword_14338C790 / [11] sub_141DF3C60 写 = sub_140CE9E00(*(a1+1344)); 实例 = make_shared 块 0x558 内嵌 (块头 _Ref_count_obj2 16B, 对象起点块+16, 1352B): 对象+8 = 21 (mode id) / +12 = 6 (按钮/层 id, 语义待裁) / +16 u8 = 1; **+1344 = COrdersGroup 引用包装 (CReferenceObject 系, ref.h GetPtr 断言链; ctor a3 直存, 宿主 +6816 实例槽)**) / CForceUpdateMapMode = **slot[13] Execute = sub_1403575C0** (vtable 0x14277AB90; [5]/[14] = CEffect 族默认桩)。
**推定 1 项**: OpST+1376 = **上下文/触发器载体指针** (读 `*(ctx+944)` CAndTrigger vtable+24 求值; **无独立 RTTI — 负定案**)。

#### 4.30.20 散簇·脚本化 UI (CScriptedWindowTemplate / CScriptedWindow / CScriptedWindowManager / CScriptedWindowDatabase / CScriptedMapMode / CScriptedMapModeLayer / CScriptedMapModeDatabase / CScriptedMapIcon / CScriptedGUIDiplomacyPopup + 辅助 CScriptedWindowGUIUpdater)

**文件层**: common/scripted_guis → CScriptedWindowDatabase::LoadFile 0X140AB9950
(顶 key scripted_gui → 每子键 new CScriptedWindowTemplate, ReadKey 0X14159ECB0);
common/map_modes → CScriptedMapModeDatabase::LoadFile 0X140AAF740 (顶 key
scripted_map_modes → db 槽位原位构造 CScriptedMapMode)。**运行期两查 (df305 定案)**:
① 按 name 线性查 (sub_140AB97F0, 67 行) = 库 +40 条目数组 (8B CPdxScopedPtr 槽) / +52 计数,
条目解引用 → scripted GUI 对象 **+8 = name 串**, 长度+memcmp 全表 O(n) 比对; 未命中 →
scriptedwindowdatabase.cpp:83 "Scripted gui not found: %s" 返 0; 空 scoped ptr →
pdx_scopedptr.h:134 "_pPtr" 断言 (闩 byte_14333A0BD)。② 具名 effect 两级哈希解析
(sub_140AB9430, 138 行) — 窗口实例 +64 = effect name 串 (查询键) / **+368 = 命中 effect id 缓存 /
+376 = effect 对象缓存**; 数据库条目: **name→id 表** (桶基 a2+256, 掩码 a2+280, 尾哨兵 a2+240,
桶 16B {next@+8, 键串@+16, len@+32, id 8B@+48}; FNV-1a 32 位 0x811C9DC5/16777619) →
**id→effect 对象表** (哨兵 a2+496, 桶基 a2+512, 掩码 a2+536; 节点 {next@+8, id@+16, 对象@+24};
FNV-1a **64 位** 0xCBF29CE484222325/0x100000001B3 叠 id 8 字节); 命中链 = name 表查 id → 写
+368 → id 表查对象 → 写 +376; 未命中 → :129 "Effect is not found '%s' in '%s'\n"。
**template def 文法
21 key 全落偏移** (ReadKey 逐 case + token 反查; **key 表外: template+8 = scripted_gui
自身名串** {buf@8, size@24, cap@32} — parent_scripted_gui 名扫的匹配目标与三处错误
消息 %s): context_type+40 (8 值白名单:
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
watcher 热重载回调 0X140B87EA0 = std::function 装配, 槽[1]; 孪生直接调用入口
0X140B88ED0 三调用点全经 *(宿主+712)): **slot7 Update 0X140B88DC0** (profiler 域名
"scripted_gui.window"; 门 byte_14332F635; +104 = root revision 快照
sub_140DCCEA0, 变化即逐窗 sub_140B88950, 尾 sub_140B8D980 — 推定 AI 评估半段,
待裁)。布局 (0xB0 = 176B 自洽): +24 root 对象 (UI 前端单例, updater 独立形态 =
qword_14332F6A0; **+1272 CGuiSystem 在 root 对象上** — 按名找窗/顶层建窗/动态条目
注册全经它, 非 manager 偏移) / +32..+48 窗口数组 / +56/+68 每国数组 (24B 元) /
+80/+92 有序模板数组 (context_type 19794/19795 专用, 二分插入) / +104 revision /
+112 _ParentWindows 表 (断言串实名; 记录+24 = 窗口对象槽) / +120/+136/+160 4 字节
FNV 名字查重 map。CScriptedWindow (0xB90 = 2960B):
+48 root scope 恒 player country / +232 template / +248 实例窗 / +264 父
CScriptedWindow / **+272 内嵌 CScriptedWindowGUIUpdater (0xA68 = 2664B)** / +1232 主
scope (=updater+960) / **+2936 父可见缓存 / +2937 计算可见 (= 父可见 ∧ ai 门
sub_140B883C0 ∧ 视图检查 ∧ template+164 门→template+144 trigger vtable+24 @scope a1+1232) /
+2938 强制 dirty** (Update sub_140B88950: +2938 先清, +2936 比对置位或置 1; dirty 比
+2944/+2952)。Reload 父窗三级解析
(token hash → parent_scripted_gui 名扫 → parent_window_name 按名 RTDynamicCast;
scriptedwindowmanager.cpp:429/435/448 实名); 实例化名 = `<window_name>_instance`。
**Reload 全链** (watcher 或直接入口 → 清 → +104 = −1 → 0X140B8A1C0): ①硬编码 token
绑定 (root vtable+184 取子系统 → 按槽号直取/嵌套 vtable+440 按名下钻; 15023←"tree"→
"grid_window"→"focus_tree_scripted_window_container" 三级下钻; 15027←"country_list";
19667..19670←army/navy/economy/air_panel 四面板; 15025 记录复制到 14996/14997 别名槽)
②28 条 ParentWindowPaths 静态表 @0x1430B0A90 (步长 40B: token@+0, name[10]@+8) FNV
去重 → CGuiSystem 按名找窗 → RTDynamicCast CContainerWindow → 绑 +112 表
(cpp:212 全绑断言) ③0X140B88F00 全窗重建: 遍历 CScriptedWindowDatabase 单例
qword_14332F060 逐模板项 (item+40 = context_type: 11839/15410 跳过不建窗 /
19794/19795 入 +80 有序数组), malloc(0xB90) new CScriptedWindow (基 ctor
sub_142255FA0; 双 vtable +0/+40; +224 root/+232 模板/+240 manager; WORD+2936 = 1)
→ B86320 父解析+实例创建 → 压 +32 数组。B86320 AI 白名单门 = template+1052 置位 ∧
有父 gui ∧ context_type ∈ {10130, 14962, 14963, 19373, 19794, 19795} → "ai for
scripted windows that has parent guis with scopes is not enabled" (cpp:429)。
单窗重建 = 0X140B88EB0 (0X140B87D80 DestroyInstance: 实例按名自父容器摘除销毁 +
窗+2938 强制 dirty = 1 副作用 → B86320, 返 1)。
**BuildScope sub_140B8D1E0 = 游戏对象真实消费点**: player_context→gs+1312/
1316; selected_state→选择集 (manager+1336 type==4→+184); diplomacy_target→
ledger 四窗 view+17664 / occupation 视图 +5352→+5456 二级; 种子 = CCountry
+544/+548 FNV 混合写 scope+16(random1) 后 +12(random2) (**写序反, 与 §4.3
§CEventScope 逐位互证**)。decision_category/mapicon 三 token = BuildScope (sub_140B8D1E0) token 分派穷尽落玩家国兜底 (定案); 「父窗继承」实为可见性链。Update 逐窗 scope 变更检测消费 sub_140BB52F0 同原初国谓词 (§4.30.21 谓词新消费点) + 14996/14997 父窗 token 走国家视图态特判 (高置信)。
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
@+4264 并绑 template (行动 vtable+408); slot1 Update 双 country scope (+4064/4068
FROM/TO → v7+24/+32) + 种子哈希; 显隐 = +4072 vtable+648/656; 五 widget 名定案
(bottom_container/accept_button/decline_button/title/scripted_gui_container)。
**辅助 CScriptedWindowGUIUpdater** (0xA68 = 2664B; 无 RTTI 项, vftable 串定案, ctor
0X140B851A0; 三形态调用: 窗内嵌 (window+272, args=[root, window, 0]) / 子 updater
(malloc 0xA68, args=[manager, 容器 widget, 父 updater]) / 独立形态 (args=
[qword_14332F6A0, 0, 0])): +8 root 回链 / +24 父 updater (AI 递归门判据) / +32
template / +960 scope / +972/976 random2/random1 / +984 root (事件 scope) / +992
父 scope / +1136 变量数组 (40B 元, 子 updater 自父全拷) / **+2616 动态列表运行时表**
(176B 槽: +0 所有者 / +8 目标容器 widget / +16 SDynamicListInfo* / +24 用中条目记录
map (16B 元 {条目对象, 子 updater}) / +32 空闲条目侵入链 / +88 条目池 map / +152/+164
缓存名串向量); 子 updater 随机种子分叉 = +972/+976 自父+972 两条独立整数雪崩混合
(条目级随机流与父分流)。窗口+272 内嵌与弹窗+4264 独立两形态经 ±272 换算逐位互证。
应用器 sub_140B8AD20 = properties 应用器, 尾调 **sub_140B8BE40 动态列表刷新引擎**
(1089 行; 遍历 +2616 表: 表达式求值 sub_140544C90 (scope = updater+960), 排序键 =
100000×索引写 def+632/+424 数组; 双路刷新 — 不变 = used 计数复用 + 记录表尾 LIFO 弹出
(cpp:1390 断言) / 变 = 清容器 + 池回灌 + 逐名查 CGuiSystem 缺则 malloc 0x18 建 GUI
条目 (sub_1422C6040) + grid 列/行界回绕定位插入 (容器 +368/+372 界, x≥界→x=0,y+1);
条目变量对 = def+744 名→100000×索引 / def+536 名→条目值; cpp:1376 "window not
found")。余项未决: B8AD20 本体逐行 / B8D980 / root 实名 / token 值对名 (须运行时
lexer) / 28 条表全名单离线 dump / SDynamicListInfo 名串槽对语义。


> **CScriptedWindowTemplate +944** = 指针容器 {data@944, cap@952, count@956, 分配器@960} (8B 元), 元素 = **CScriptedWindowTemplate::SAIEffectInfo\*** (解析键 14977 ai_weights; ≥384B: {+0 vtable, +8 token 块 56B 默认 16382, +64 SSO 效果名, +96 权重主体 208B (sub_140541C10), +304 token 块 B, +360 u8, +368/+376 qword}; 真 ctor sub_140AB91D0 复制型; 字段语义待裁)。同解析器邻键: 15270 array / 15303 entry_container / 15304 country_scope_entry_container。

#### 4.30.21 州面板余量 (CCountryStateView 三vtable / tooltip 巨函 19 分支 / SetupDerived+Clear / gs+992 铁路图 / 163-164 键 / 同原初国谓词)

业务侧: 州面板+modifier 哈希+资源形态见 §4.13; 铁路图 CProvinceRailwayInfo+
prov+200 天气 id 见 §4.14; m_OriginalTag/gs+832 恒等表/每州资源因子缓存见
§4.3。+4216 = template_garrison。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| tooltip 巨函 | = **view+40 事件子对象 vtable[0]** sub_141747430 | 19 分支线性分派; a1[171]=view+1408 prov / a1[172]=view+1416 state | countrystateview.cpp 实名; 新消费点 CState+436/+448/+460/prov+200/cc+808/cc+3944 | STATE_NO_RESOURCES / STATE_CONTROLLER / STATE_POPULATION_DESC 等 | 定案 |
| SetupDerived / Clear | vtable[14] 0X14174AF00 / vtable[15] 0X141746070 | 三行池 def 驱动 (def+700/def+824) + 共享槽池+1448 (dword_143334520) + 容器族 +4176..+4352 | lambda RTTI 实证; Clear = 5 列表清+4 池回收+2 grid | — | 定案 |
| 铁路图 | sub_1414E3210 assert | **gs+992 = {+8: CProvinceRailwayInfo\*[] 按省 id}**; 条目 +24/+32/+44/+56/+68/+104/+472 | supply_system_utils.cpp:0x31C 直证 | — | 定案 |
| 省情报字节纹理 | **CInGameIdler vtable[120]** → CGraphicalMap (= *(app+880)) → +1776 | **+1776 每省情报/可见度字节纹理对象** (64B, 无独立 RTTI 类 — 负定案; {+0 每省字节表, +8 第二表, +16 i32 省数 (按 gs+700 分配), +24/25/26 三旗, +27 = byte_14332F63A 快照, +48 allocator, +56 纹理像素缓冲}; 惰性建 sub_140B55770 → sub_1416181B0) | **0-255 标度档位 100/150/250** (MODIFIER_INTEL_FROM_COMBAT_FACTOR id 587 缩放, 求值 sub_141618DC0); `<150` 消费 = naval_base_map_icon.cpp:295 选省循环 + 建筑图标固定省; `<50` 消费 = 建筑图标位置省 (sub_141676EB0) + 省 tooltip 情报段; 门 = 战争迷雾总开关 byte_14332F63A | — | 定案 |
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
(ctor 0X141E4B890, **vtable 0X142A837F8** — 原 0X142A81928 系 COperationPhasesViewEntry vftable[1] 槽地址张冠李戴, PE COL 反查定案, 0x142DA4920 全 exe 唯一, 0x1560B) / +20680 = CPeaceBeneficiaryBiddingsItem
(0X141E49AD0, **0X142A83998** — 原 0X142A81AC8 同病, COL 0x142DA48A0, 0x5F0B) / +20704 = CPeaceAggregatedAvailableActionItem
(0X141E45970, **0X142A83278** — 原 0X142A813A8 同病, COL 0x142DA3EE8, 0x618B)**; 层级 = winner→agg action→country→
CPeaceBiddingItem/QuickAccess 孙行。**country 行 ctor 实参: +1336 =
行动类型 token 组键** (源自 CPeaceAction+8, sub_1419E6B30 译 GFX 图标名);
**+1340 = 国 tag**; FillActions = sub_141E4D740 (展开时逐动作建
CPeaceBiddingItem 行 + CStatePeaceAction+76..79 四叠加旗分 12531-12534 组
建 QuickAccess 勾选行, lambda 写 country+1320 map 勾选态)。winners 条目
UI 字段: +8 tag→旗/名 / +76 当前分→score 文本。未决 8 项 (明细未录): GetWinner
ICF 别名 / +568/+584 语义 / 五谓词内部等。


> **竞标弹窗聚合行件三件 (与上三行池不同窗域)**: CPeaceBiddingQuickAccess 1352B (竞标聚合窗 sub_141E4B890 内嵌双实例 @+2768/+4120; +8 窗件 "conference_bidding_quick_access_button", +24..+1304 glue 1280B, +1312 弹窗类别 (0=CONTESTED/1=SELECTED, Update 0x141E51BB0 直证; 标题/计数双文本件); 2 槽小表基 CTooltipHandler) / **CPeaceBiddingsAggregatedActionItem 1424B** (行窗 "conference_bidding_aggregated_action"; 主 vtable [0] = 0x1401807B0 `return 1` ICF 共享平凡虚) / **CPeaceBiddingsAggregatedCountryItem 1496B** (行窗 "conference_bidding_aggregated_country") — 后两件住竞标弹窗聚合视图 (CPeaceBiddingsPopUpWindow 系, 本节行 550 双弹窗指针 +20776/+20784), 上三行池住和会主窗行动池, 名字近邻窗域不同; 三件零 gameplay 读点 (ctor 实参全为窗件/宿主/整型) = 纯 UI 负定案。

**竞标行件 tooltip 与数据面增补 (定案)**: **CPeaceWinnerBiddingsItem tooltip 泵 = vftable[0] 0x141E4F900** (7 行件分支 + PEACE_* loc 键 7 条 + 尾 SELECT_TAKER/NEGOTIATOR 分流 — **主窗 +20752 = 竞标侧旗**: 0 → SELECT_TAKER / 否则 SELECT_NEGOTIATOR); winner 行件指针族 +2696..+2744 七件。**CPeaceBeneficiaryBiddingsItem tooltip = 0x141E4EC80** (vftable 0x142A83998): 类型文案 switch + NEGOTIATOR 国名列表 + "flag" 行件名比对; beneficiary 行件 +1464..+1496, **+1424 = CSimpleEmptyEntryList\<CNegotiatorFlagEntry\>**。**SetBeneficiaryData 0x141E50C00 = CConferenceParticipant 三子类 RTTI 直证** (Subject/ForceGovernment/Liberated), 类型 token **12496/12497/12498 = liberate/puppet/force_government**, tag 集源偏移 +88/+88/+72 三态。**竞标计数谓词 = CPeaceAction+60 status ∈ {3,4}** (sub_14151EBE0; NB_BIDS/NB_CONTESTED/NB_BIDS_FOR_BENEFICIARY 三计数器 0x141E4D6E0/620/680 — 与 §4.10.28 status 语义互证)。**winners 条目 +112 = 战争参与度 (i64) / +120 = 战争分重分配 (i64)**, 分布体双文本格式化器 sub_141983F60/141983E80 (loc PEACE_COUNTRY_WAR_PARTICIPATION_RATIO / PEACE_WAR_SCORE_REDISTRIBUTION)。**tag→国名双通道**: sub_140BB4BB0 = country+16 名 (经 gs+784 数组) / sub_140BB4E70 = gs+856+32×tag 直索引名表 (兜底 qword_143330D98) / sub_140BB4C30 = tag→国名逐项。

#### 4.30.23 科技面板设施页签 (CFacilitiesTabView 五合一; 国策 def 侧见 §4.3.15)

业务侧: CFacilitiesTabView 全布局见 §4.7。

类布局 (类名 / target / 锚点):

科技面板设施页签 (win+4288, 0xB98, 三 vtable @+0/+16/+56, 窗 facilities_view) —
定案 = 0xB98 五合一容器:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +128 | CScientistRoster | 科学家名册 | |
| +136 | **NProject::NUi::CProjectHistoryRoster** (0x650) | 历史名册 (1616B, malloc 0x650 直证; 无 CScientistHistoryRoster RTTI 类 — 原类名误配废) | 与 +144 系**两独立分配** (非一槽两用) |
| +144 | **NProject::NUi::CProjectSimpleRoster** (0x658) | 过滤名册 (1624B, malloc 0x658; 绑 .gui 窗 project_simple_roster/projects_list/project_simple_roster_filters) | 同上 |
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
| 接口处理器历史容器 | {data@+1192, cap@+1200, count@+1204, alloc@+1208} | 元素 216B {tag@+0, 类别 u8@+208}; 宿主 = idler vtable+184 会话对象 (eventmanager 批直证 — 原「未名」补全) |
| 合同交付状态对象 | 分子 +472/+512; 分母 +24/+232; 惰性旗 +504/+216 | 国际市场合同交付状态; 宿主待归 (候选并 §4.23.3) |

#### 4.30.25 游戏内屏面三件 (时钟 / 设置屏 / 小地图)

| 类 | vtable / 基链 | 布局与行为 |
|---|---|---|
| CInGameClock (152B; 顶栏真实挂钟, 窗名 "clock_window") | 主表 4 槽 + CInGameUpdateableInterface@40 十槽 ([1..6] updateableinterface.cpp 默认桩, 仅覆写 [7] tick) | tick = localtime64 → "%R" 格式写窗文本; 显隐门 = 设置单例 +909 字节; 激活 = 游戏内 GUI 大工厂 sub_140B614C0 |
| CIngameSettingsScreen (2648B; 游戏内设置屏, reload 名 "menu_settings_ingame") | CReloadableInterface/CReloadDispatcher@0 + CTooltipHandler@40 | ctor 12 段 CLegacyButtonObserverGlue 按钮胶水 (邻串 ApplyButton) |
| CMinimapInterface (5424B; 小地图界面, "mini_map_interface") | 双副表 @40 tooltip / @48 updateable (覆写旗检 + 浮点相机两槽) | 与时钟同厂 (sub_140B614C0) 同宿主挂载 |

三件均非 CPersistent 零存档面 (serfam 全无记录); 定案/高置信。

#### 4.30.26 地图图标/模式基族 (CMapIcon / CMapIconManagerImpl / CMapIconGroup / CMapIconLayer / CMapMode)

CMapIcon 基类: vtable 0x1429E6AB0, 21 槽, 128B; ctor sub_14163F310(名, 层号, client)。

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
| +108 | — | 层号 (**兼作 icon type**: 值 == 工厂 case 号 == 层号; mapicon.h:189 断言 "eType < MAP_ICON_TYPES_COUNT") | | 0-33; 管理器 34 层数组下标 (= 工厂 case id, §4.30.27 映射表); 类型→gfx id 非恒等直写 = 经 LUT 且可加变体偏移 (+0/+1/条件+1/+5, §4.30.57) |
| +112 | uint32 | **层可见性缓存** | | 所有派生 slot3 统一调 sub_1418BBB30 (gfx 层 id byte LUT xmmword_14338A9F0[类型]; 访问器本体 = 单读 + :189 断言) → sub_140FA61D0 直写本字段 |
| +116 | — | 旗 | | bit0 = active, bit3 = SetX |

CMapIcon vtable槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | 矩形测试 |
| [2] | IsVisible | 派生加迷雾谓词 |
| [3] | **帧级 Update/populate 分发** (定案) | 派生覆写同形态: type LUT xmmword_14338A9F0[+108] (+ 变体偏移) → sub_140FA61D0 + 基 + 派生 populate; 12 类实例本体全住 mapicon.h (7 纯转发 + 2 半内联 + 3 大内联), 类特有逻辑在各自 .cpp populate — §4.30.57 |
| [4] | GetPosition | 纯虚 |
| [7] | ClearTarget | 清 +48 目标 |
| [8] | Realize | 经管理器 +1840 工厂按名建子精灵 |
| [13] | — | 宽分发 |
| [14] | — | 高分发 |
| [15] | **命中收集入口** | 框选/点选流图标侧终点 (icon, x, y, type, flag, out); 管理器逐层查询经矩形测试 [1] 命中后调 (mapiconmanagerimpl.cpp 查询体直证) |

注: +1424 token / +5985 迷雾 / +4688 xyz 属派生扩展区/省地图对象, 非基类字段。

CMapIconManagerImpl: vtable 0x14294BE40 (COL 0x142CCB748), 6 槽, 0x7A0; 基链 = 接口+Base+CReloadDispatcher,
模板基 CMapIconManager\<34\> (vtable 0x14294BE08); 单例 qword_14333C5A8 (factory sub_140B71AF0 =
malloc(0x7A0) → ctor sub_140B712C0; 初始化点 = gameapplication.cpp:1660 日志串
"InitGame:: CMapIconManagerImpl takes "; mapiconmanagerimpl.cpp 实名);
调试层过滤全局 dword_143086368 (−1 = 全层)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | CVector[34] | 层表 ① | | **图标对象池 (定案)**: 每层 24B {data, cap, count, 分配器对象}; Reload 经 sub_140B73650 逐层走工厂 sub_140B71B50 预建 (请求数超 cap 先 ×1.5 扩), 新图标 +120 = *(manager+1848) 重建世代戳; ClearAll 尾逐层 deleting dtor 实体销毁 |
| +824 | CVector[34] | 层表 ② | | 活性图标表 (定案); Reload 尾按 池① count > 表② cap 预留容量; 查询/ClearAll 均走此表 |
| +1776 | CMapIcon* 向量 | 全池平铺指针数组 | | {data, cap, count, 分配器}; 容量 = Σ34 层池① count, Reload 尾一次扩足 (mapiconmanagerimpl.cpp Reload 体直证) |
| +1800 | CMapIconLayer (0x48B) 向量 | 层任务对象数组 | | Reload 每次 malloc(0x48) + sub_14163FF40 建一个 (+8 manager, +16 双 CVector, +56 分配器, +64 层号, +68 = 0); ClearAll 逐项 deleting dtor + 缩容 |
| +1832 | — | 容器名串 | | "mapicons_container" |
| +1840 | — | 精灵工厂 | | = sub_1422B8BC0 |
| +1848 | — | 重建世代戳 | | Reload 时写入新图标 +120 |
| +1856 | — | 引用计数旧状态对象 | | Reload 释放 (InterlockedExchangeAdd) |
| +1880 | 24B 子结构 | 清空三件套之一 | | ClearAll 逐个 sub_140B73EB0 清 |
| +1904 | 24B 子结构 | 清空三件套之二 | | 同上 |
| +1928 | 24B 子结构 | 清空三件套之三 | | 同上 |

CMapIconManagerImpl vtable槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [2] | Reload | 全层 Realize |
| [4] | Update | 11165 行 ICF 巨函, 禁逐行 |
| [5] | ClearAll | |

CMapIconGroup (48B): 图标 CVector@+8 {data@8, cap@16, count@20, alloc@24}; +32 = 当前图标; +40 = CMapIconLayer* 回指。Update LOD 0-3 距离三 define =
MAP_ICONS_GROUP_CAM_DISTANCE / MAP_ICONS_STATE_GROUP_CAM_DISTANCE /
MAP_ICONS_STRATEGIC_GROUP_CAM_DISTANCE (均 /100000.0 vs 相机+404)。

CMapIconLayer: 双 CVector; +64 = 层号。

CMapMode 基类: vtable 0x142A02F20, 10 槽 (唯一 `&CMapMode::vftable` 写点 deleting dtor 链 + purecall 四连定案)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | — | mode id | | |
| +40 | CProvince* | 当前目标 | | |

激活流 sub_1417CAB50: [1]CanActivate → +40 = a2 → [3]Commit; 取消 glue
sub_1417CAB20: +40 非空 → [4]Cancel → 清。dtor 自动向管理器注销。

CMapMode vtable槽表:

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

CMapModeWithButton vtable槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [10] | 目标图标恢复 | 对象+20 字节 0/1 |
| [11] | 目标图标抑制 | 对象+20 字节 0/1 |

mode id 增补 (映射表):

| 值 | 名称 | 语义 |
|---|---|---|
| 20 | CMapModeMilitaryDeployment | +1344 = conveyor; Commit 投 CSetConveyorLocationCommand(conveyor, prov+164); GetInfo 读 prov+392 controller / prov+192 → CState 州名; loc CONVEYOR_ASSIGN_LOCATION_SELECT_{HOME_}AREA; 0x558B scoped_ref 内嵌 ConveyorView+6800/+6816 (子对象+1360 = conveyor), [4] Refresh 0X141D87950 激活时退出选址/指派 |
| 21 | …ToOrder | 投 CSetConveyorGroupCommand; order 源 = *(qword_14332F6A0 vtable+200 对象+464); qword_14338C790 = 当前 hover 选中 |
| 29 | CMapModeOperationSelectTarget | +1344 = 候选 CVector / +1368 = 窗 / +1376 = 上下文 / +1384 = 选中目标 token / +1388 = 实现选择子; mapmodeoperationselecttarget.cpp:103 实名; loc SELECT_STATE_ON_CLICK{,_DISABLED}; 槽[10]/[11] 经 prov+192 CState+20 字节旗 |

**CMapModeOperationSelectTarget 目标拾取 (0x141E340A0, 新收)**: token 变更 (宿主 +5856) ∨ 上下文变更 (宿主 +5920 对象的 +1036) 时重选并写 +1368/+1384/+1376; 按目标类型 token 分派 — **10304 (province) → 选择子 0 + a1+8 = 29 / 12014 (strategic_region) → 选择子 1 + a1+8 = 32**; 其它 → 日志 "Invalid target type for operation: %s" (mapmodeoperationselecttarget.cpp:48) 不切; 尾调刷新 sub_1417CA930; 选址提示文案经宿主 vtable[+688] (slot 86) 设置, 无目标时 loc OPERATION_VIEW_SELECT_TARGET。⚠ **本类服务 mode 29 与 32 两个 id** (调用方宿主持 +5904 / +5952 两份实例槽), 与 §4.30.38 实名表「32 = MAPMODE_STRATEGIC_AIR」冲突 — 两说并存待裁 (命名权: 名构造器 sub_140E028C0 vs 本类实例化点)。

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

**图标工厂 sub_140B71B50 case↔类映射 (类型 id == 层号)**: 2 = CVictoryPointMapIcon / 3 = CResourceMapIcon / 8 = CNavalBaseMapIcon / 14 = CCapitalMapIcon / 17 = CRadarMapIcon / 20 = CResistanceComplianceMapIcon / 25 = CScriptedMapIcon / 26 = CSupplyNodeMapIcon / 29 = (mode 29 邻域, 见 §4.30.19) / 31 = CNavalHeadquarterMapIcon / 33 = CStrategicLocationMapIcon。**CTooltipHandler 副vtable = 2 槽**: [0] = GetTooltip 真入口, [1] = 转发 dtor (a1−128)。**州地图对象** (sub_140B552A0): +112/+120 位置 / +124 可见 byte; **省地图对象** (sub_140B53EE0): +5024/+5032 位置 / +5985 迷雾 / +4796/+4808 补给锚对 / +5448 建筑 gfx 句柄表 — 两者均无 RTTI 名。

| 类 (类型 id) | target 形态 | 锚点 |
|---|---|---|
| CCapitalMapIcon (14, 216B) | **+152 CState\* + +160 首都省 CRef** (\*(\*+160)+164 = 省 id ✓); +172 模式旗切换州锚/省锚 | populate 用省+56 VP 名或州名; SetFrame 归属着色 (自=3/友=1/外=5/远焦=2) |
| CVictoryPointMapIcon (2, 192B) | **+152 CProvince\*** | 帧 = 归属 (**省+392 controller ✓**) + VP 档位 (**省+56 victory_points ✓** 对阈值表 **qword_143338A70**, frame = v31 + 5×(档数−档)); 大 VP 远焦仍可见 |
| CRadarMapIcon (17, 152B) | **+136 裸省 id** | 存在谓词 = 省→州→控制国 **CRadarsPool (cc+4344 ✓)** 内有该州雷达; 位置锚在建筑精灵 (CBuildingDatabase ✓ 匹配省地图对象+5448 gfx 句柄表); tooltip = RADAR_ONMAP_TOOLTIP/_DAMAGED (站+88 等级 vs 最大) |
| CResourceMapIcon (3, 224B; **唯一无 CTooltipHandler**) | **+128 CState\***; **+152 复合容器块 (+160 i64 数量数组按资源 def+216−1 索引 ✓§4.13.6)** | 近焦才显 (dword_1433342A0); 遍历 strategic_resource 库 (0x332f088 ✓§4.26) 填 "resources_list" |
| CResourceMapIconItem (88B; **非 CMapIcon** — CStandardlistboxItem 派生, 副 facet @+56) | "desc"(+72) = 资源名 / "flag"(+80) = 数量 | 由宿主 populate 直灌 |
| CStrategicLocationMapIcon (33, 176B) | **+136 = 省 id** (= **st+2048 strategic locations 对第二 u32 ✓§4.13**) | +144 名串拼 "GFX_strategic_location_*" 经 vtable+728 SetGfx 上 "bg_btn"(+168); tooltip = STRATEGIC_LOCATION_MAPICON + 省名 |
| CSupplyNodeMapIcon (26, 6712B 巨图标; 窗名 supply_node_map_icon; ctor sub_14190DF80; 主 vtable 0x142A1A250 / 副 vtable 0x142A1A300 (主表+176)) | **+6576 CProvince\*; +6584 节点变体旗 (ctor 初值 0x10000, 低字节) / +6585 / +6586 byte; 子元素群 +6592..+6701 + +6704=5 / +6708=4** | 5×1288B 事件回调束 (+136/+1424/+2712/+4000/+5288, 束安装器 sub_14190D7A0, 11 回调) 配五按钮; **tooltip 五键全定名: SUPPLY_NODE_MOVE_CAPITAL / UPGRADE_TO_CAPITAL / TOGGLE_ALLIES / MOTORIZATION_PRIORITY / SUPPLY_FLOW_SHOW_RANGE**; **悬停元素四路分派**: +6632→MOVE_CAPITAL / +6680→TOGGLE_ALLIES / +6688→UPGRADE_TO_CAPITAL / +6696→MOTORIZATION_PRIORITY+FLOW_SHOW_RANGE (GetTooltip sub_14190EAB0; 元素 = icon+128); 点击经 qword_14332F6A0 → sub_140A66AE0 控制器三方法 sub_1419B0E90 (prov+164, flag) / sub_1419B10B0 (prov+164, flag) / sub_1419B0B70 (prov+164), 非裸 CCommand; 槽: [2] IsVisible sub_14190EF40 (prov+192→st+88→sub_140B552A0→+124) / [3] 层门+populate sub_141912AB0 (层@+108; populate = sub_1419107D0) / [4] GetPosition sub_14190E7B0 (节点槽查询 sub_1414E2AF0; 控制国→gs+984→+264 槽表 232B 元: 槽+13 flag, 槽+8==3→+4796 否则 +4808; 兜底 defines dword_143333410/414/418) / [7] ClearTarget sub_14190F370 / [8] Realize sub_141912000 / [10] sub_141908CB0 (与 resistance 共享, 推定) |
| CResistanceComplianceMapIcon (20, 208B; resistancemapicons.cpp 实名) | **+136 CState\*** | populate 仅 map mode 6/7; 数据源 = **st+616 CResistance ✓ (cr+528/+552 双修正名单 ✓§4.13.1 + sub_140F99CF0 占领状态对)**; 内嵌 CGenericEmptyEntryList\<ModifierEntry\>@+168 逐修正建行 |

#### 4.30.28 地图图标派生族散件 B (CCryptologyMapIcon / CIntelLedgerMapIcon / CIntelLedgerResourceEntry / CConstructionInfoMapIcon / CStateModifierMapIcon / CAdjacencyRuleIcon / CPeaceMapIcon / CCounterintelligenceMapIconEntry)

**地图对象双查表定案** (管理器 qword_14332F698): **vtable+120 → sub_140B552A0 = 州地图对象** (pos float3@+112/+120, 迷雾字节@+124); **vtable+128 → sub_140B53EE0 = 省地图对象族** (pos float3@+4568 或 float2@+5024, **迷雾旗 @+5985 bit1** — 双证定案)。工厂 case 补: 4 = CConstructionInfoMapIcon / 15 = CPeaceMapIcon / 16 = CAdjacencyRuleIcon / 22 = CIntelLedgerMapIcon / 23 = CIntelLedgerMapRegionIcon / 24 = CCryptologyMapIcon / 28 = CStateModifierMapIcon。

| 类 (类型 id) | target 形态 | 锚点 |
|---|---|---|
| CCryptologyMapIcon (24, 0xAC8B) | **国 tag@+2756** | 四子件 decrytion_bar/state_icon/large_flag/percent @+2712..+2736; 位置 = 目标国首都省 (**cc+4120 ✓**); 槽[6] = **owned_states (cc+1156 ✓)** ≤0 门; 点击投 **CStartStopDecryptionCommand / CActivateActiveDecryptionBonuses**; tooltip 全 8 个 CRYPTO_* loc 定案 |
| CIntelLedgerMapIcon (22, 0x188B; 兄弟 CIntelLedgerMapRegionIcon 23) | **CState\* 向量@+144** (质心定位) | 14 个命名 widget (六计数+六图标+双视图+missions_grid) @+192..+304 + 空海任务行表@+312/+352; 数据源 = CCountryIntelLedgerView 单例 **qword_14338B4C0** revision 门; **无 tooltip** (副 vtable[0]=ret0) |
| CIntelLedgerResourceEntry (0x68B 行件, 基 CStandardGridBoxItem 零覆写) | **+32 = 资源库 def (qword_14332F088 ✓)** | 窗 ledger_resource_entry; 资源图标帧 = **def+220 ✓**; **+88 = C2dPieChartTemplate 饼图** (RTDynamicCast 直证); tooltip = TRADE_PRODUCED/IMPORTED/EXPORTED + NO_INTEL 民用情报门 |
| CConstructionInfoMapIcon (4, 0x640B) | **州 id@+136 + 转换对象@+176** | 12 widget (双计数+双转换钮+disabled 对+双旗+infrastructure_effect); 点击 = **CConvertFactoryCommand** (arms/industry 双向, sub_1409D5740/89F0 门); tooltip = STATE_CONVERT_BUILDING {FACTOR, BUILDING_FROM, TO} |
| CStateModifierMapIcon (28, 0x90B; 单基无 tooltip) | **CState\*@+128 + "modifiers_list" widget@+136** | populate 遍历 **CState+1968/+1980 dynamic_modifier 容器 ✓§4.13** (注意: 非 st+2256 哈希) |
| CAdjacencyRuleIcon (16, 0x5A8B) | **CAdjacencyRule\*@+1432 + 省对象@+1440** (省 id@+164 ✓) | 位置 = 省地图对象+4568 float3 + 规则偏移; 槽[9] = 常数 10; hover 经 sub_140B6C5E0 高亮海峡; tooltip = 规则名 HEADER + 逐国要求文本 |
| CPeaceMapIcon (15, 0x128B; peacemapicon.cpp:65 实名断言) | **州 id@+136** | 和会割让州图标; 内嵌 CResourceEntry + CNegotiatorFlagEntry 双行表; tooltip = sub_1419E5540 和会处置预览 + PEACE_HIDE_MAP_ICON; 无自有点击 |
| CCounterintelligenceMapIconEntry (0x78B 行件, 基 CIntelMapModeMapIconEntry) | **tag@+88** | 槽[19] 实现基纯虚 = 目标国首都省; populate 用 **define COUNTERINTELLIGENCE_ACTIVITY_LEVEL_THRESHOLD_COLORS** 数组给 +112 widget 着色 (+80 计时器翻帧); tooltip = AGENCY_DEFENSE_LEVEL_DESC + COUNTERINTELLIGENCE_ACTIVITY_LEVEL(_DESC) |
| CIntelMapModeMapIconMore (1376B, 基 CIntelMapModeMapIconEntry) | 图标超量聚合行 | 工厂门 = 图标计数 < defines 全局 dword_143332B50 不建 (超量时聚合显示); 属 CIntelMapModeMapIconEntry 子族 |


#### 4.30.28a 海军基地地图图标缓存式取值器 (naval_base_map_icon.cpp; 1 函, 高置信)

`sub_1418EF7C0`: 全局缓存 `qword_1430B41C8`（初值 −1 = 未初始化）→ 未初始化时经 `sub_14225C370(qword_143453230, &串)` 按名 `"naval_base_mapicon"` 查 GUI 对象（qword_143453230 = CGui 单例, §4.30/§4.31 已定案）→ 取其 **vtable 字节偏移 +224（槽 28）** getter（out 参 8B 栈位）缓存结果；查无 → 错误日志 "naval map icon object not found" (:88) + 返 0。未决：槽 28 getter 语义未定名（位置 / 图标对象 / 纹理）。
#### 4.30.29 顶栏/陆军总览/力量平衡窗本体 (CTopBar / CArmiesView / CPowerBalanceView)

本节 = 三张 View 本体的布局与 glue 全表; 行件侧 (CDivisionsSummaryItemView 等行/条目级) 见 §4.31.53。

**CPowerBalanceView (1632B 新锚, "powerbalanceview")**：主 vtable 0x142A58F70（4 槽）+ @40 tooltip（[0] BuildTooltip 0x141C5D950）；ctor 0x141C5CC00；创建点 sub_14157C600；[2] Reload 0x141C5E940 → sub_141C5E950(this, *(this+64))。布局：+56 ctx / +64 会话对象 / +72 主窗 / +80 decision_container / +88 decision_grid / +1384..+1424 六件（power_balance_name/active_range_name/power_balance_value/position_marker/left_power_icon/right_power_icon）/ +1432 当前 CPowerBalance\*（Update 写 FindBalance 结果）/ +1440 range 缓存；**尾部扩展新锚：+1480/+1512/+1544/+1576 四组容器 + +1608/+1620/+1624 行池区 + +1628 f32=0.5f**；Update 真入口 = sub_141C5F5D0（非虚；sub_140E56DF0(gs+1104, gs+1312/1316) FindBalance，变化/强制 → sub_141C60810 populate）；+48 value → 百分比 = 50×(v+100000)/100000（populate 内逐字同）；侧名 = CPowerBalance+24 left / +32 right → +16 名串（sub_140E57080）；平衡名 = template+16（sub_140A8D870）。

**CTopBar (39328B, "topbar")**：主 vtable 0x142A11290（4 槽）+ @40 tooltip 0x142A112B8 + @48 update 0x142A112D0（10 槽）；ctor 0x14188FDC0；[2] Reload 0x14189ECF0；@48[6] 全刷 0x14189D4E0（→sub_1418A1EE0 日期）/[7] 逐帧 0x14189D510（入口门 = *(this+72) 窗非 0 且 *(*(this+72)+165) & 8；日期/稳定度/战争支持/政治点/convoys/supply 逐段重算 = 每帧全量刷新；派发 = CInGameUpdateableInterface 注册制中央 tick，基 ctor 1412362A0 注册键 id）/[9] Repopulate 0x1418A2170（+39008 tag 缓存比对 gs+1312/1316）；glue 注册器 = 每 glue 仅绑 1 handler（sub_14188F7A0；+9280/+26056 两位特化）。

glue 网格 = **26 槽位 +264..+32496 步距 1288**（+23448 新对象插入后后续槽各 +32，原位存在）；逐钮表（绑定函数 sub_14189EF20；widget 名实证）：

| 偏移 | 元素名 | glue@ | handler / 语义 |
|---|---|---|---|
| +39016..+39048 | button_speedstep1..5 ×5 | +26056 | sub_14189EEF0（ctx vtable[37]() 取目标速度 → sub_140DE0160 跳转；帧规则 = i≤*(gs+1212) → (i==4)+2 否则 1，vtable[22] SetFrame；**gs+1212 = 当前游戏速度档 (int, clamp 0..4)** — 写者 sub_1401EDE50 `if (a2>4) a2=4;` 后写 +1212；调用者 = 加减速钮 sub_140F06EF0 (`gs+303+1`) / sub_140F069B0 (`gs+303−1`) / sub_140F07110 读档初始化） |
| +39056 | decisionview_button | +4128 | sub_1418A1870（→sub_140B6DC30(parent, 3, 1) 视图 3） |
| +39064 | intel_agency_button | +5416 | sub_1418A1A50（视图 4） |
| +39072 | technology_button | +7992 | sub_1418A1C60（→sub_1418A1BE0(parent,0) tech 树切换） |
| +39080 | diplomacy_button | +9280 | sub_141896C40 双分支（DLC43: sub_1418A1A90 → sub_141E74F40(view+39176) + sub_1418A1A70 视图 10；无 DLC: sub_1418A1A20 视图 9） |
| +39088 | trade_button | +13144 | sub_1418A1C80（视图 15） |
| +39096 | construction_button | +17008 | sub_1418A1850（视图 17） |
| +39104 | production_button（+39112 glow 件） | +6704 | sub_1418A1BA0（视图 2 + 清 +39312 决策辉光超载旗 + 触 +39112 glow 件 vtable[16]\|=0x10） |
| +39120 | **deployment_button** | +11856 | sub_1418A1A00（→sub_140B6DC30(parent, 14, 1) 视图 14；原稿「疑 trade」证伪——trade 在 +39088） |
| +39128 | logistics_button | +14432 | sub_1418A1AA0（→sub_140B6DB70(parent, 1)） |
| +39136 | officer_corp_button | +15720 | sub_1418A1B30（→sub_140B6DC30(parent, 19, 1) 视图 19） |
| +39144 | decisionview_amount_to_take_items（+39152 配 _bg） | — | 决策可执行数 |
| +39160 | prototype_rewards_aquired（+39168 配 _bg） | — | 特种项目奖励数 |
| +39184 | threat 相关文本件 | +22160 | sub_1418A1CA0（ctx vtable[23]() → sub_140B6DDF0：obj+416 窗 vtable[7]/vtable[8] 显隐切换；"threat_button"/"threat_value_button" 双件共享此 glue） |
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
| +2840 | sub_1418A1730 | dismissed_alerts → sub_140B175B0(*(*(a1+104)+1944)) (全量重建警报 widget; 警报系统 = §4.17.7) |
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
| +27344 | sub_1418A1B50 | ctx vtable[71](ctx,1) → sub_1418A2E30 刷 time_control_window: pause_button_date(+117 bit0x10)/pause_button_date_paused 双件暂停态切换 (定案) |
| +28632 | sub_1418A1B50 | pause_button_date/pause_button_date_paused 双件共享（与 +27344 同 handler） |
| +29920 | sub_14189ED70 | reopen_ingame_lobby（CServer RTDynamicCast 门）→ sub_140B6B970(ctx vtable[23](), 0) |
| +31208 | sub_14189E9D0 | playlist_button：FindWindow "toggle_music_commands_win" 显隐 toggle（推定） |
| +32496 | sub_14189EAF0 | musicplayer → sub_140B6DBD0(*(a1+112)) |

> ⚠ 「CTopBar 全部无 CCommand 出口」对调速两钮不成立：MP 分支构造速度命令投递命令队列（单机路径直接调速，——其 handler 无 dump 可复核，标推定）。
> 数据源锚（view+39008 tag 缓存，逐帧 sub_140BB48F0 取 cc）：DateText = gs+1120（setter sub_1418A1EE0）；pol_power = CPolitics+224；industrial_capacity = sub_140E693C0(cc+3944)（公式 (ps+792+888+696)/1e5 − 六项占用）；industrial_ratio_bar = ps+936 ×100；三军经验 = cc+5512 +16(陆,view+168)/+64(空,view+160)/+40(海,view+176)；command_power = cc+496；**fuel = cc+5504（fs）——元件四件：fuel_value@+200（SetText sub_1410F6390 格式化） / fuel_icon@+208（vtable+176 SetEnabled ← 格式化器出旗） / fuel_ratio_bar@+216 ← 100×sub_1410F3570（(fs+8≪15)/fs+16 → 规整 1e5 → sub_1424ED730 (+50000)/100000 取整, 帧域 0..100） / industrial_ratio_bar@+224 ← ps+936×100；四件写语句在 @48[7] sub_14189D510 函数体内 supply 段之后同段逐帧执行；bar 链 = vtable+752 GetSprite → 精灵 vtable+152 SetFrame（§4.31.86 setter 底座）；名字缓存 = [2] Reload → sub_14189EF20（"fuel_value"→+200 / "fuel_icon"→+208 / "fuel_ratio_bar"→+216 / "industrial_ratio_bar"→+224 / "supply_value"→+240）**；nukes = sub_141097B50(cc)>0；stability/war_support = sub_1406F8750/sub_1406F9E70(cc)；player_flag = sub_140B44AC0(ctx+1272, flag 件, view+39008, 0,1,0)；achievements 使能 = sub_14061E2D0(sub_14061CD20(), gs, 0)≤1；**supply 面值唯一写者链 = @48[7] sub_14189D510 → sub_1418A33A0（玩家 tag → css → sub_14121F1D0 出参；数字/颜色/比例条三件同源，详 §4.21.1c；sub_1414323B0 = 情报账页管线与顶栏无关）**；**convoys 源 = sub_1418A1CC0（cc+4608 系统根 → 枚举）**；**threat_value = define 表达式 TOB_BAR_THREAT 求值 sub_1402E31F0（替代手写聚合器——机制变了）**；BuildTooltip = 0x141897AB0。

**CArmiesView (1640B, "armies_view")**：主 vtable 0x1429E9C98（4 槽）+ @40 tooltip；ctor 0x141692440；[2] Reload 0x1416AD9A0。布局：+1336 ctx / +1344/+1352/+1360 主窗子窗 / +1368 CArmyLeaderWindow\* / +1376/+1388 子窗指针数组（+1392 sentinel）/ +1400/+1408 CArmyDivisionListView ×2 / +1416/+1424 CRailwayGunListView ×2 / +1432 徽标 int（推定）/ +1440 选中槽 = −1 / +1444 u8 = 1 / +1448..+1544 容器四组（sentinel ×2 = qword_14333D528）/ +1488 选中师 refid（count +1500，选择同步 sub_1416C2E10 内 type==0 → vtable[7] 推入）/ +1512 数组（count +1524）/ +1544 选中铁路炮 refid（count +1556，type==13 → vtable[11]）/ +1592 脏旗（glue 回调 sub_1416AC7E0 置 1）/ +1600..+1632 远征窗等。glue @+48 ctor = sub_141690BC0（同构注册器）；建窗 sub_1416AE5D0 / 选择集 helper sub_140BC3180（判空）/ sub_140BC30C0（链表化）；主 populate = sub_1416BC7E0。

#### 4.30.30 国别域六视图本体 (CCountryConstructionsView / CCountryDiplomacyView / CCountryIntelligenceAgencyView / CCountryLogisticsView / CCountryOccupationView / CCountryTechnologyView)

视图本体 (装配器 0x140B614C0 统一 malloc, 挂宿主 +232=情报(14752) / +240=科技(4320) / +272=外交(17680) / +288=占领(11976) / +328=后勤(6904) / +336=建设(5520) — 对类实证); 行件侧 (国旗行/选择行/过滤器行) 见 §4.31.65。

| 类 | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---:|---|---|
| CCountryConstructionsView | countryconstructionsview(id1) | 5520 | 建设面板视图（唯一带第四基 CReorderObserver@1408；+1480 = CGameDate "1.1.1.1" 哨兵新消费点） | 定案 |
| CCountryDiplomacyView | countrydiplomacyview(id4) | 17680 | 外交视图 | 定案 |
| CCountryIntelligenceAgencyView | countryintelligenceagencyview(id6) | 14752 | 情报机构视图（[9] 读宿主 tag 上国名窗题） | 定案 |
| CCountryLogisticsView | countrylogisticsview(id4) | 6904 | 后勤视图（[5] 转发 [9]）；**时机定案 = 可见性切换各恰一次 Repopulate，非逐帧**（@48[7] = updateableinterface.cpp 基桩；活体 detour 计数终证：两游戏月未开零调用且行值指纹冻结、开/关各恰一次且行值重算——行值 = 打开时 sub_141D9BFE0 从 \*(cc+3992) 桶聚合现算现写，行件 +1356..+1488） | 定案 |
| CCountryOccupationView | countryoccupationview(id5) | 11976 | 占领视图 | 定案 |
| CCountryTechnologyView | countrytechnologyview(id6) | 4320 | 科技视图（[9] 选中扫描 byte165&0x10） | 定案 |

**六视图自有域**（基域 +0..+1407，派生自有 +1408 起）：

| 视图 | 自有域（+1408 起） | 业务槽 |
|---|---|---|
| CCountryTechnologyView (4320, id6) | +1408 u32 当前 tab 枚举 (0/1, "unknown tab" 断言 countrytechnologyview.cpp:278 — 原「所选科技 id」废) / +1416 向量 {data@+1416, count@+1428, alloc@+1432}（[5] 遍历调 sub_141BE35C0）/ +1448 u32 国家 tag 副本（父 vtable[20] 取）/ +1456、+1480、+1504、+1528 四 pdx 向量（两对 48B GUI 行件持有双向量, flush 原语 sub_1415818C0, 析构 sub_1415F71C0/sub_1415F7220; +1480 = 行件指针表 {data@1480, count@1492}）/ +1552、+2920 两 CButtonWrapper / +4288 门对象指针（[6] vtable+56 查真→vtable+8 行动）、+4296 tab 窗体对象指针（[9] byte165&0x10 选中旗置/清）、+4312 指针（0x1415FAC20 尾 sub_1422C4970 消费） | [5] 0x1415F8FF0 布线+树清理 / [6] 0x1415F9050 / [9] 0x1415FA1A0（byte165&0x10 选中扫描; 三槽 this = +48 子对象, [6] 读 a1+4240 = complete +4288 互证） |
| CCountryDiplomacyView (17680, id4) | +1408 子对象（sub_1415E3B60，至 7016）/ +7016 子对象（sub_1415E3FE0，至 14952）/ +14952 子对象（sub_1415E2950，至 17664）/ +17664 u32 / +17672 qword | [5] 0x1415EBCD0（+17592 未建门 && +17664>0 → sub_1415F0810 填充）/ [9] 0x1415F08E0（选中传播：+6712 选中 idx、+17552 计数同步、+14864 窗控对象 byte165&0x10 置位、隐藏 +17656 旧窗、+17568←+17576 交换; 两槽 this = +48 子对象（`a1-48` 直证）, 原 +6664/+17504/+17516/+14816 等均为 @48 坐标, 完整对象 = 原值 +48, 定案） |
| CCountryLogisticsView (6904, id4) | +1408 窗件块（sub_14172D170，回调 sub_141730780）/ +2696 窗件块（回调 sub_1417308F0）/ +3984 窗件块（回调 sub_141730600）/ +5272 窗件块（回调 sub_1417305C0） | [5] 0x1413D96A0 = 转发自身 vtable[9]（后勤/占领共用）/ [9] 0x141731FE0（"materiel" 物资行填充） |
| CCountryOccupationView (11976, id5) | +1408 容器参数 qword（ctor a3 直存, 不属胶水块 — 原「+1408、+1416 块」拆开）/ +1416、+2704、+3992、+5280 四个 1288B 按钮胶水块（CLegacyButtonObserverGlue\<CCountryOccupationView\>, 构造器 sub_141557B60, 析构 sub_1402DE2D0; 回调 +1416→sub_141237480 / +2704→sub_141565A00 / +3992→sub_141566BD0 / +5280→sub_141566A40） | [5] 0x1413D96A0（与后勤同址）/ @48[7] 0x141566AF0（占领矩阵刷新：+11720 域 + byte165&8 可见门 + UI 根 +1288 facet）/ @48[9] 0x14156F5A0（Repopulate；槽号见 §4.31.68 注） |
| CCountryIntelligenceAgencyView (14752, id6) | +1408..+1743 头部域 336B（+1432 机构对象指针, dtor sub_1401C1DC0; 字段细分待裁）/ +1744 CButtonWrapper (1368B) / +3112..+14703 九个 1288B 按钮胶水块（CLegacyButtonObserverGlue\<CCountryIntelligenceAgencyView\>, 构造器 sub_140F265F0; 回调 3112→140F2C1C0 / 4400→140F2BE30 / 5688→140F2B750 / 6976→140F2BAB0 / 8264→140F2C110 / 9552→140F2F310 / 10840→140F2F240 / 12128→140F2C370 / 13416→140F2C130）/ +14704 行表 CEmptyEntryListBase\<COperationViewEntry\> (48B, ctor 空表/泛型二选一) | [5] 0x140F2C0A0（机构刷新，+1432 机构对象 → sub_141A20990/221C0）/ [6] 0x140F2C100 / [9] 0x140F2F3A0（读宿主 +1392 vtable[20] tag → 国家对象 → 国名(@国+128) 上窗题）; +1408 起按钮胶水块群 (CLegacyButtonObserverGlue<CCountryIntelligenceAgencyView>, 释放器 sub_140F265F0); sub_140F2C1C0 正名 = 国+2104 表取项的指令投递 handler (高置信) |
| CCountryConstructionsView (5520, id1) | +1408 CClass* CReorderObserver 次表（唯一带第四基视图，4 槽）/ +1416 24B 对象 / +1440、+1448 qword / +1456 24B 向量头（+1480 = CGameDate 43808760 "1.1.1.1" 哨兵、+1488 第二 CGameDate、+1496 u16）/ +1504、+2792、+4144 三窗件块（回调 sub_141716900/CF0/540）/ +4080..+4143 零块、+5432..+5519 窗件区（活体: +5496 = CStandardGridBox* vtable 0x142B46218 / +5504 = CContainerWindow* vtable 0x142B45278, 建筑网格与容器窗; 非零写入者静态不可见, 疑 GUI 框架表驱动绑定 — 未决） | [1] 0x141716EA0 = 置位 / [2] 0x141716820 = 清位 —— 同构体 `(*(vtable+184))(qword_14332F6A0)` 取会话 GUI 根后写 `*(BYTE*)(root+1016) = 1 / 0`，即显示抑制门 set/clear 对（定案）；行集 = ps+112 general_lines / 民池 / cc+3944，populate 0x141719340 |

> CCountryConstructionsView CReorderObserver 表 4 槽为主表（本类主表只覆写 [1]/[2]）。CCountryTechnologyView [9] 选中扫描与 §4.00.6 CStandardGridBoxItem 行互证。
**CCountryLogisticsView 自有尾域**（+6560..+6903，重锚后零漂移，ctor 六容器全量初始化）：**六容器** +6560/+6584/+6608/+6632/+6656/+6680（均 24B；前两只 = 225 特行列表；**+6680 = 第六窗件块**，消费 sub_1419107D0（读 +6680 并 `(*(vtable+128))(+6680)` 挂载）+ 建/拆 sub_141912040（析构走 vtable+552））；三 tab 兜底行 +6728 (land) / +6736 (naval) / +6744 (air)；双子窗 +6712/+6720；清靶 +6752/+6760/+6768；tag +6784；优先级四行组 +6792..+6896；表头 +6704；0x5D8=1496 行槽 +1392..+1480 与 kind 映射；「其它」桶 {data@+1344, count@+1356}。主表槽：[7] 0x141730550（基复位 + 收 +6712/+6720 + 清 +6752/+6760/+6768）/ [14] 0x141730A80 / [15] 0x14172E5C0 / Repopulate 0x141731FE0；ctor sub_14172D950。**⚠ 「+2632 窗件块」在本视图不存在**（旧原稿唯一出处 = CTradeResourceInfoItem 贸易行件文本元素——按域剔除）。
**CCountryMilitaryOverview（军事总览窗）**：+13737 u8 = 抑制旗 / +1408 tab 枚举 / +1448 排序列（−1 复位）/ +1452 计数；主表槽 [4] 0x14170C090 / [6] 0x14170AC80；**@48[9] 排序器 = 0x14170E550**（谓词 sub_141D3A460）：排序三列表主坐标 **+13408/+13480/+13600**、比较子 **+13696/+13712/+13728**、回调向量 +13648、收件 +13192/+13208；[14] 元素新增 **army_sort_group**（与 army_sort_name/army_sort_type 并列；navy/air_sort_name 同族）；⚠ 旧原稿「view+13552/+13680」= @48 坐标系记录，真值同主坐标。**populate = sub_141706F70**（非虚独立函数；主表 [4] 0x14170C090 / [6] 0x14170AC80 先复位 +1448=-1 / [14] 0x14170AF30 直调）。
> CCountryConstructionsView 补遗：[7] = 0x141716300（+1496=+1497）；[4] = 0x141719090；Repopulate = 0x14171A960；**+5496/+5504 类名定案**（RTTI 直证: CStandardGridBox / CContainerWindow; dtor sub_1402E11E0 + facet+128 卸载、[4] sub_1422C31A0(+5504) 刷新、populate sub_1422C6DD0(+5496) 建行、0x141717E30 过滤 churn; **非零写入者静态不可见维持未决** — 视图簇内纯消费, 疑 GUI 框架表驱动绑定）、**+5512 = 表头对象**（Repopulate 尾）；民池 available（ps+888/912/944/920）与 **traded（ps+948+ps+956）公式逐字复证**；**local（ps+964+ps+968）直读存在 = sub_141892C50（industrial_capacity tooltip 链, 入口 0x141897AB0, 实参 cc+3944）**; 建设面板行件链不读 local 桶（两处口径并存; 同 tooltip 函数 available 版本用 888/1e5−912/1e5−952−960 与 traded 侧 948−952, 非同一组）；[7] 的 +1392 vtable[23]+1032 门 1.19.3 = **非零门定案**。装备库单例 **qword_14332EEC0 = TGameItemDatabase\<common/units/equipment\> {items@+128, 计@+140}**。
**CCountryView 六视图共同骨架**（定案）：基 ctor sub_141237180(this, 父gui, 容器, 名串, id) 五段 = CReloadableInterface@0（sub_142255FA0 查 .gui 描述子）→ CTooltipHandler@40 → CInGameUpdateableInterface@48（sub_1412362A0 注册键 id）→ CCountryView 三表齐写 → +72 = 1288B 窗件块（sub_1412369A0，回调 sub_141237480）→ +1360 = 名串副本 32B → +1392 = 宿主面板回指 → +1400 = 0；派生自有字段一律 +1408 起。主表 10 槽中 [1][2][3][4][6][7] = updateableinterface.cpp 桩（"Override this function before using!"），[8] = thunk → (this−48)+40，**[5]/[9] = 派生业务槽**。facet 方法表槽语义：+120 查子件 / +128 挂窗件块 / +136 取窗体 / +152 描述子+48 / +176 SetEnabled / +432 查孙 / +440 查列表 / +552 注册行 tooltip / +592 可见门。

#### 4.30.31 精灵/GUI 模板 Type 族 (CSpriteType 族锚 + 7 派生 Type + 2d 元素族名录)

族共性 (定案): Type 族基链 = `XxxType ← C2dObjectType ← CObjectType ← CPersistentWithToken ← CPersistent`; 全部 **writer = CFG 空桩** (mod .gfx/.gui 模板解析件, 不入存档), reader = 自有实现; 元素族基链 = `Xxx ← (CSprite) ← C2dVisibleObject ← C2dObject ← CGraphicalObject`, 全部非 CPersistent (内存渲染对象)。基 reader 0x142355FD0 公共三键: name(27)@+16 / loadType(293)@+64 (枚举 FRONTEND=1/BACKEND=2/INGAME=3) / norefcount(294)@+68; 元素 +16 = 类型对象回指 (C2dObject 层), 元素 +304 = 构造值对槽 (族共性); 元素尾部分配器槽普遍 = off_143085170 (§4.00.9)。

**CSpriteType** (精灵模板族锚, 496B; vtable 0x142B3DD58 33 槽; writer=CFG; reader 0x142241240 = 族公共 reader, 各派生 reader 全回落到它; ctor 0x14223ED20 / 第二 ctor 0x14223EF60 (带帧数 + 纹理尺寸对参数); 模板键 `spriteType`/`spriteTypes`; 运行期方法群见 §4.30.32a):  (精化: LoadTexture 惰性路径重登记门 = `+416 > -1` (改名重载才重登记, 首载由 LoadTextureIfNeeded 承担); IsTransparentAt 帧格尺寸按 +268 三形 — 0 横条带 cell_h=+168 整高 / 1 纵条带 cell_w=+164 整宽 / 2 网格双除; :567 断言 latch byte_1434530E9 与 :588 侧 byte_1434530EA 不同字)。

| 偏移 | 类型 | 键 (token) | 备注 |
|---|---|---|---|
| +16 | SSO 串 (32B) | name (27) | {buf@+16, size@+32, cap@+40=15}; 基 reader |
| +48 | uint32 | — | ctor 0 (推定 id/序) |
| +64 | u32 枚举 | loadType (293) | 基 reader |
| +68 | uint8 | norefcount (294) | 基 reader |
| +72 | CClass* | 宿主/设备对象 (ctor=a2) | 其 +128 顶点缓冲管理器 / +368 纹理管理器 / +400 4×4 变换矩阵 / +1336 技术管理器; CProgressbarSprite 工厂直取此槽 |
| +80 | SSO 串 | effectFile (90) | ctor 默认 "gfx/FX/buttonstate.lua" |
| +112 | SSO 串 | textureFile (37) | {size@+128, cap@+136=15} |
| +144 | int32 | noOfFrames (28), 默认 1 | 帧网格列数 (GetFrameGridXY 取模) |
| +148 | int32 | — | 帧网格行数, 默认 1 (第二 ctor 参数 a4 写 +144) |
| +156 | float | defaultAnimationTime (66), 默认 1.0 | |
| +160 | float | 动画模式/速率, 默认 0.0 | render 判 0.0 走简化路径, ≠0 走蒙皮路径 sub_14223F4E0 |
| +164 | int32 | 纹理宽 | ResolveTexture/LoadTexture/LoadTextureIfNeeded 三处经 sub_142407010 写入 (定案) |
| +168 | int32 | 纹理高 | 同上 |
| +192 | CColor (32B) | 颜色, 默认白 | ctor 调 CColor ctor 0x14224BEE0; rgba f32×4 @+208..+220 |
| +224 | uint64 | 顶点缓冲句柄 | 运行期: CreateVertexBuffer 建 4 顶点×20B 四边形 VB 经 off_1430BF8C8 写入, render 经 off_1430BF8E8 消费 (定案) |
| +232 | float 序列 | anchor (750) | float 序列块读 helper 0x140ADDCA0 (reader case 750 直证落此, 定案) |
| +240 | float | 当前动画时间, 默认 -1.0 (哨兵) | render 读外部 f32 写入, 变化触发 vtable[30]; CreateVertexBuffer 重置 |
| +244 | float | — | ctor 1.0, 用途未决 |
| +248 | float | — | ctor 1.0, 用途未决 |
| +252 | int32 | 当前帧索引 | render 钳位写入 (上界 = +144×+148) |
| +256 | float | 帧 UV 步进 X | UV.x = 帧列 × +256 |
| +260 | float | 帧 UV 步进 Y | UV.y = 帧行 × +260 |
| +264 | uint8 | 几何/时间脏旗 | CreateVertexBuffer 置 1; render 消费后按 +240 变化重判 |
| +268 | uint32 | framedirectiony (571) | 0=横向条 / 1=纵向条 / 2=行主序网格 (GetFrameGridXY 消费) |
| +273 | uint8 | allwaystransparent (319) ≡ alwaystransparent (470) | 拼写双键同槽 |
| +280 | 向量 {data@+280, cap@+288, count@+292, alloc@+296} | animation (64) 帧动画表 | 元素 SAnimationMapData 144B, 1.5× 增长, 分配器 vtable+8 |
| +304 | uint64 | 特效技术句柄 "ANIMATED" | InitResources 经 sub_1422D2CC0 解析; ctor -1 |
| +312 | uint64 | — | ctor -1 |
| +320 | uint64 | 特效技术句柄 "NUM_ANIMATIONS_\<n\>" | InitResources 解析; SetupEffectAnimation 读 +304+16×n 分派 |
| +328 | uint64 | — | ctor -1 |
| +336 | uint64 | 遮罩技术句柄 1 "MASKING" | InitResources 经 sub_1422D2CC0 解析 |
| +344 | uint64 | — | ctor -1 |
| +352 | uint64 | 遮罩技术句柄 2 "MASKING" | InitResources 经 sub_1422D2E80 解析 |
| +360 | uint64 | — | ctor -1 |
| +368 | CTexture* | 纹理指针 | sub_1424071E0(宿主+368 纹理管理器, id) 返回, 三处写入 (定案) |
| +376 | CTexture* | 遮罩纹理指针 | 由 +384 名装载; InitResources/render/IsTransparentAt 消费 |
| +384 | SSO 串 | masking_texture (577) | {size@+400, cap@+408 (ctor 15)} |
| +416 | int32 | 纹理 id | sub_142406740(纹理管理器, 名, flags, 1) 创建返回; 默认 -1 = 未装载 (定案) |
| +420 | float | alpha 乘数, 默认 1.0 | render: 颜色 alpha(+220) × +420 |
| +424 | SSO 串 | clicksound (284) | {size@+440, cap@+448=15} |
| +456 | float 序列 | dx_offset (735) | ctor 预置 -0.5f/+0.5f; helper 同 +232 |
| +464 | uint8 | transparencecheck (275) | 写后 +465 置「已显式设置」旗; 亦作 DXT 告警已发旗 (ResolveTexture 告警后清零 = 同时关闭像素命中测试, 因 DXT3 无可靠 alpha) |
| +465 | uint8 | 「transparencecheck 已显式设置」旗 | reader |
| +466 | uint8 | can_be_lowres (406) | |
| +467 | uint8 | legacy_lazy_load (655) | ctor 默认取全局 byte_1434530E8 |
| +468 | uint8 | 「动画失效告警已发」一次性旗 | SetupEffectAnimation |
| +469 | uint8 | generate_mip_maps (786) | |
| +472 | 向量 {data@+472, cap@+480, count@+484, alloc@+488} | — | 元素 48B (vtable@元素+8, 多态析构 sub_142240140), 两 ctor 初始化; 全语料无消费点, 用途未决 |

SAnimationMapData (+280 向量元素, 144B):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | SAnimationMapData vtable |
| +8 | SSO 串 (32B) | 动画帧纹理名 1 (InitResources 读 +24 长度 / +8 名装载 → +120) |
| +40 | SSO 串 (32B) | 动画帧纹理名 2 (读 +56 长度 / +40 名装载 → +128) |
| +72 | int32 | reader 初值 0 |
| +76 | uint8 | reader 初值 1 |
| +80 | float | reader 初值 1.0 |
| +88 | float×2 | reader 初值 1.0/1.0 |
| +96 | uint64 | reader 初值 0 |
| +104 | uint64 | reader 初值 0 |
| +112 | int32 | reader 初值 -1 |
| +116 | int32 | reader 初值 0 |
| +120 | CTexture* | 纹理 1 指针 (sub_1424071E0) |
| +128 | CTexture* | 纹理 2 指针 (sub_1424071E0) |
| +136 | int32×2 | 纹理 2 尺寸对 (sub_142407010) |

> reader 十六键 27/37/66/90/284/293/294/319/470/571/577/655/735/750/786/64 落点与键表完全一致; 与 CFrameAnimatedSpriteType 自有段起点 +496 边界吻合 (尺寸 496B 定案)。


派生 Type 7 类 (增量段 = CSpriteType 全表 + 下表自有段; 均 writer=CFG 解析件):

| 类 | vtable | 尺寸 | 自有段 (基链) |
|---|---|---|---|
| CFrameAnimatedSpriteType | 0x142B51C60 | ≥512B | +496 f32 animation_rate_fps (452, 取倒数)/animation_rate_spf (453 直写同槽) / +504 f32 = **`pause_on_loop` (457) 以 f32 落槽** (reader `sub_1424C0930` 数值读 — 非布尔, 引擎按数值语义消费, 非类型错) / +508 u8 looping (454) / +509 u8 play_on_show (455); reader 0x142357650 |
| CMaskedSpriteType | 0x1429E6DC0 | ≥696B | +496 ptr (ctor=a2 推定 宿主库) / +504 textureFile2 (39) / +536 textureFile1 (38) / +592 effectFile (90) / +624..+680 缓存群 / +688 u8 small (12503); reader 0x1416422F0 (vtable 孤立于 0x1429Exxxx 簇) |
| CTileSpriteType | 0x142B52838 | ≥504B | +496 u32×2 size (47) 唯一自有键; reader 0x142361910 |
| CTextSpriteType | 0x142B52680 | ≥360B | 不经 CSpriteType: +104 textureFile (37) / +136 i32 -1 / +140 noOfFrames (28) / +144 ptr / +152 f32 defaultAnimationTime (66) / +156 ptr / +168 effectFile (90) / +200/+232 SSO×2 (键未在自有 reader 出现, 推定 基类/另键) / +304 u16=1 / +312 clicksound (284) / +344/+352 i64 -1 缓存对; reader 0x142361150 |
| CProgressbarSpriteType | 0x142B521B8 | ≥292B | 不经 CSpriteType: +80 effectFile (90) / +112 CColor color (86) / +144 CColor colortwo (268) / +176 textureFile1 (38) / +208 textureFile2 (39) / +240 i64=-1 / +248 steps (488, 默认 100) / +252 u32×2 size (47) / +264 u8 horizontal (153, 默认 1) / +280 u8 alwaystransparent 双键同槽 / +284/+288 f32 1.0 对; reader 0x14235FEA0; 元素工厂 vtable[23] 0x14235FB30 |
| CResizeableSpriteType | 0x142B525B0 | ≥128B | 不经 CSpriteType: +80 textureFile (37) / +104 i32 对 — **键 28 (noOfFrames) 与 66 (defaultAnimationTime) 都落 `sub_1424C0900(a2, a1+104)`**: reader 显式 fall-through, 引擎共用该 8B 槽 (设计, 非文档缺陷) / +116 u32×2 size (47) / +124 i32=-1; reader 0x1423607E0 |
| CCorneredTileSpriteType | 0x142B414A8 | ≥208B | 不经 CSpriteType: +72 纹理指针 / +80 textureFile (37) / +112 noOfFrames (28, 默认 1) / +124 u32×2 borderSize (134) / +132 u32×2 size (47) / +144 effectFile (90) / +176/+184 ptr -1 纹理缓存对 / +200 u8 alwaystransparent 双键同槽 / +201 u8 tilingCenter (369) / +202 u8 looping (454) / +204 f32 animation_rate_fps/spf 同槽; reader 0x142295EE0 |

2d 元素族名录 (均非 CPersistent, 不可序列化; 基 ctor = 0x1422AE140 C2dVisibleObject 链, 基段 ~304B):

| 类 | vtable | 尺寸 | 一句话 |
|---|---|---|---|
| CSprite | 0x142B4BA90 | 456B | 精灵元素族锚: +16/+384 类型 / +368/+372 缩放对 / +432/+440 动画帧游标容器对 / +448 分配器; ctor 0x1422FE170 |
| CFrameAnimatedSprite | 0x142B4D400 | ≥488B | 帧动画精灵 (CSprite 派生): +464 动画控制参数块; ctor 0x142308530 |
| CCorneredTileSprite | 0x142B50E68 | ≥424B | 九宫格角块贴图: +376/+380..+392 类型 getter 缓存对; ctor 0x142353290 |
| CInstantSprite | 0x142B47C98 | ≥472B | 即时贴图: +376/+380 缩放对 / +416 矩形参数 / +440..+456 串+句柄; ctor 0x1422D46D0 |
| CProgressbarSprite | 0x142B52288 | 480B (工厂定案) | 进度条元素: +304 纹理尺寸对 / +376 类型 / +384 纹理指针 / +400/+432 子对象对 / +208/+224 颜色对; 工厂 = Type vtable[23] 0x14235FB30 |
| CResizeableSprite | 0x142B59A50 | ≥392B | 可拉伸贴图: +384/+388 可拉伸区参数缓存; ctor 0x142385BD0 |
| CTextSprite | 0x142B47F60 | ≥664B | 文本贴图, 多基 +CLostDeviceInterface 次表@+368; +552 = 2d/纹理管理器全局 qword_143453090; 尾段 +640/+648 清零 / +656 u8 / +658 u16 / +660 u8=a4 / +661 u8=1; ctor 0x1422D52A0 |
| C2dCircularProgressBar | 0x142B59768 | ≥872B | 环形进度条, 次表 CLostDeviceInterface@+368; +856/+864 宿主参数块; ctor 0x142384E40 |
| CButton | 0x142B44828 (+次 0x142B44BB0) | ≥232B | 按钮 widget, observable 面@+128 (§4.00.6 管线 ✓); 字段 +136/+144/+160/+184/+192/+208/+216 清零 + +152 u32/+156 u8/+168 u8/+176 u32 状态机枚举 (0=正常/2=按下/3=禁用/4=拖拽中/5=拖拽中按下, 值 1 未用)/+224 u32/+228 旗 (初值 0xB8, bit 3 = 鼠标输入处理门)/+200 = off_143085170; ctor 0x1422AEE70 |
| CIcon | 0x142B4AF50 (+次 0x142B4B308) | ≥352B | 图标按钮 (CButton 派生): +256/+260 尺寸 f32 对 / +340 u8 四布尔打包位; ctor 0x1422FACA0 |
| TButton | 0x142B444B8 | — | 按钮抽象基 (8 纯虚槽), 不独立实例化 |

> **CTextureReloader** (vtable 0x142B3D720 4 槽, 基 CReloadDispatcher) = 排除: 文件变更→纹理刷新钩子 ([1] 路径谓词 0x14223CAA0 / [2][3] 经 qword_143453090 桶槽迭代), 纯图形基础设施。
> 读侧 helper 分类 (后续 GUI Type 批可复用): 0x1424C0C00 = bool u8 / 0x1424C0AB0 = SSO 串 / 0x1424C08D0 = i32 / 0x1424C0930 = f32 / 0x1424C0900 = i32 对 / 0x1424C0AA0 = 复合块 (CColor 16B/动画元素) / 0x140A4C640 = u32 对 (size/borderSize) / 0x140ADDCA0 = **float 序列块读** (anchor(750)→+232 / dx_offset(735)→+456, sscanf "%f" 序列; 体无任何串比较分支, 定案); 写侧 0x1424C37B0 = u8 / 0x1424C2F40 = u32。
> idb 评估: 8 个 SpriteType 属「GUI 模板库」形态 (spriteTypes 块由各自 reader 解析注册, 键串簇 0x2ae5550..0x2aea130); §4.26.4 idb 规格表无一 GUI 键 — 若做 GFX 名→纹理映射, 本节 reader↔偏移表即规格表底稿。**GFX/内容库名注册表 qword_143339CB8 值类 = `CGraphicalCultureType*`** (定案; 消费者 sub_140712200/sub_140712260 把查得指针写入 CCountry+4168/+4128 = graphical_culture / graphical_culture_2d 解析结果槽 §4.3; 加载器 sub_140181110 解析 `common/graphicalculturetype.txt` 注册; 空值 CNullGraphicalCultureType 0x14293C058; 表 40B {+0 链节点计数, +4 mask 511, +8 buckets 链头, +16 线性值数组 data, +24 该数组 cap, +28 该数组 count, +32 allocator} — 链式哈希 + 并行线性索引 (插入 sub_140A3C160 / 查 sub_140A3C0B0), 惰性建 sub_140A3BF90 once 守卫 dword_14332ECF0; `_gfx` 后缀回退 = sub_140ADF1F0)。

**注册库三库分流 (定案)**: ① spriteTypes 族 → 纹理管理器单例 qword_143453090 的 **+256 哈希表** (表头 {+4 nbuckets 默认 511, +8 buckets}; get-or-create sub_142237660); ② .gui 控件模板 (CGuiType 群) → **CGui/CGameGui 对象 +192 CTernary\<CGuiType\*\>** {容器@+200, count@+212}, 工厂 = CGui vtable[29] CreateTemplate 0x14225ABB0 (token 尺寸与本节键表互证), 实例挂应用对象 +872; ③ GFX/内容库名注册表 = **qword_143339CB8** 懒建单例 (40B, once 守卫 dword_14332ECF0, 哈希形态同①; "_gfx" 后缀解析与纹理按名取件走此表) — **负定案**: 该表 = 40B 匿名哈希容器 (builder sub_140A3BF90 malloc 0x28 → {+0 dword 0 / +4 mask 511 / +8 buckets(0xFFF8) / +16 count / +24 alloc / +32 alloc(off_143085170)}), **无独立 RTTI 类**; 值类 = `CGraphicalCultureType*`; 同族 40B 形 = 链式哈希 + 并行线性索引数组 ({+0 链节点计数, +4 mask 511, +8 buckets, +16 线性数组 data, +24 数组 cap, +28 数组 count, +32 allocator})。

#### 4.30.32 GUI 控件 Type 族 (CGuiType 壳 + 控件模板 Type 群 + 元素/观察器族)

族壳 (定案): Type 类基链 `XxxType ← CGuiType ← CPersistentWithToken ← CPersistent` (CLineChartType 例外走 C2dObjectType 链; 带 CFactory 次基 md+240 者 = CListboxType / CRadioButtonGroupType / CRadioScrollbarGroupType / CScrollbarType / CWindowType / CDropDownMenuType)。**主vtable 13 槽契约** (CLineChartType 25 槽): [0] dtor / [1] Save wrapper 0x1424BEC50 / [2] writer = **CFG 空桩** (mod .gui 模板解析件永不落盘) / [3] Load wrapper = **CGuiType 覆写版 0x1422DE0B0** (先记 文件名 SSO@+72 + 行号@+224 再回落 0x1424BE690 — 故全族除 CLineChartType 外不入 serfam 指纹 = 格式差异非非持久化) / [4] 逐类 Parse (token switch) / [5..8] 空桩样板 / [9] 0x14061F7D0 = GetName (name SSO@+40) / [10] 元素工厂 / [11] 父串回吐。**CGuiType** (基类抽象, vtable 0x142B48628, [10][11] _purecall; Parse 0x1422DE390 = 全族公共回落; 公共键: name(27)→+40 SSO / tooltip(146)/tooltipText(147)/pdx_tooltip(364)→+144 interned 池化串 (intern = sub_14239E3E0) / delayedTooltipText(148)/pdx_tooltip_delayed(365)→+152 / pdx_disabled_tooltip(787)→+160 / pdx_disabled_tooltip_delayed(788)→+168 / hint_tag(458)→+192 SSO / hide(679)→+187 u8 / context_aware_tooltip(794)/bound_tooltip(796)→+104 绑定串复合块 (0x1424C0AA0, 互斥, 置 +136 旗) / pdx_tooltip_anchor(733) 块→子键 x(32)→+176 / y(33)→+180 / relative(734)→+185 / below(752)→+186, 块起始置 +184; 未命中再落 CPersistentWithToken 基 0x1424BEC40)。

模板键 ↔ Type 类 ↔ 承接点 (全部定案; CContainerWindowType::Parse = 统一承接点, containerwindowtype.cpp):

| 模板键 (token id) | Type 类 | vtable | Parse | 承接 |
|---|---|---|---|---|
| buttontype (625) | CButtonType | 0x142B53CC8 | 0x142370410 | CContainerWindowType case / CDropDownBoxType 642 / CExtendedScrollbarType 138/139/156/638/639 / CGridBoxType 156 |
| curveGraphType (648) | CCurveGraphType | 0x142B4FBC0 | 0x14232BF10 | CContainerWindowType case |
| dropDownBoxType (620) | CDropDownBoxType | 0x142B53E20 | 0x1423714D0 | CContainerWindowType case |
| dropDownMenuType (185) | CDropDownMenuType | 0x142B53F60 | 0x142372910 | 库层 (CFactory 面 md+240; vtable[11] 0x1422F7E60 工厂槽) |
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

**CWindowType** (窗口模板族锚, 对象 ≥1136B; vtable 0x142B4AC60; reader 0x1422F84B0; ctor 0x14230E910 1432B): 键 = parent(135)→+248 / background(156)→+280 / position(76)→+312 u32 对 / show_position(398)→+320 / hide_position(399)→+328 / animation_type(400)→+336 枚举 (linear=3/smoothstep=2/accelerated=0) / animation_time(401)→+340 / size(47)→+344 **计算矩形** (宿主尺寸−margin, 勿套通用 helper) / verticalScrollbar(161)→+352 / horizontalScrollbar(162)→+384 / horizontalBorder(166)→+416 / verticalBorder(167)→+448 / priority(141)→+484 f32 / moveable(157)→+488 / fullScreen(48)→+1040 / click_to_front(380)→+1041 / orientation(194)→+1044 枚举 / upsound(281)→+1072 / downsound(282)→+1104 / **threeDguiType(320)→+280 (与 background(156) 共槽; 仅运行期继承拷贝路径 0x1422F99E0 受理, Parse 0x1422F84B0 无 case 320 — 不对称待裁)**。子件创建契约: 工厂 vtable+16 = CreateTemplate(token) → 子件 vtable[3] Load wrapper 载入 → 插入器 vtable+48 (parent, key, 子件) → 追加主子件链表 +1048 头/+1056 尾/+1064 计数 + 各分类链表 (+640..+1064 区)。宿主引用 +528 (其 +384/+388 = 基面尺寸); +536 类型工厂; +544 子件插入器; +672 = CTernary\<CGuiType*\> 模板库容器。

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
| CButtonType | font(30)/origo(102)/buttonFont(174) 三键同槽→+336 串 / spriteType(54)/quadTextureSprite(132)→+432 / position(76)→+648 u32 对 / size(47)→+704 u32 对 / scale(93)→+724 f32 / rotation(342)→+720 f32 / format(114)→+712 枚举 (left115=0 / right116=1 / centre117 与 center50=2) / upSprite(128)→+272 / downSprite(129)→+304 / overSprite(131)→+368 / dissableSprite(130)→+400 (引擎原拼写) / parent(135)→+464 / text(143)/buttonText(173)→+616 / borderSize(134)→+728 u32 对 / orientation(194)→+656 串 / frame(252)→+736 i32 / upsound(281)→+848 / downsound(282)→+816 / oversound(283)→+744 / clicksound(284)→+776 (值="none" 置 +808=1 并清空) / no_clicksound(585)→+808 / shortcut(289)→+528 **CPdxArray<std::string>** (sub_141264520 追加; 元 32B, 扩容 max(count+1, cap×1.5), **可重复追加一键一元**) / luaClick(335)→+496 / callback_type(649)→+552 / callback_argument(650)→+584 / web_link(651)→+552 写死常量+584 读参数 / vertical_alignment(601)→+716 枚举 (top602=0 / center50 与 centre117=1 / bottom603=2; 非法报错串把 top 误拼为 tip) / centerPosition(578)→+741 / multiline(719)→+740 / alwaystransparent(470)→+880 / enabled(705)→+881 / open_browser(715) 弃用告警 |
| CCurveGraphType | position(76)→+240 / size(47)→+248 / spriteType(54)→+256 |
| CDropDownBoxType (404B 级) | name(27) 显式委派基 / position(76)→+240 复合块 (sub_142303C90) / expandButton(642)→+304 CButtonType\* (malloc 888B, 重复报错) / expandedWindow(643)→+312 CContainerWindowType\* (malloc 1432B) / clipping(631)→+332 / contractOnLeave(644)→+330 / hideHeaderOnExpand(645)→+329 / expandedOnTop(646)→+328 / switch_frame_on_expand(749)→+331 五 u8 / verticalScrollbar(161)/horizontalScrollbar(162) 与动画/滚动条簇 8 键 (398..628) = sub_1424C2060 读弃 / default 委派 +320 容器 vtable[4] |
| CDropDownMenuType (424B 级自段 +240..+520; 多基 CFactory md+240) | parent(135)→+248 / dropDown(183)→+312 串 / heading(184)→+344 串 / position(76)→+376 u32 对 / **size(47)→+384 u32 对** / priority(141)→+392 f32 / **background(156)→+280 串** / orientation(194)→+488 SSO 串 (运行期经 sub_1422F9B20 解析落 **+520** u32) |
| CEditBoxType (384B; vtable[7]=0x142372F70 族内唯一 [7] 覆写 = 载入期校验回调, 判据 = +240 textureFile 串 size 非零 ∧ +372 bit1 → 告警 "textureFile is only supported if instantTextBoxType = no"; 4 参 (this, std::string& 文件名, 行起, 行止), 不落字段) | textureFile(37)→+240 / font(30)→+272 / text(143)→+304 串 / position(76)→+336 **i32 对** / size(47)→+344 **i32 对** (三几何键同 reader **sub_1402C7E70**, 与 CButtonType 的 sub_140A4C640 不同; 负值报错 editboxtype.cpp:71, 记日志不修正) / borderSize(134)→+352 **i32 对** (同 reader) / cursor(397)→+360 u32 对 (坐标对语义沿用 sub_140A4C640) / orientation(194)→+368 枚举 (串→0x1422F9B20) / instantTextBoxType(288)→+372 bit1 / ignore_tab_navigation(587)→+372 bit0 / use_special_chars(687)→+372 bit2 / only_numbers(710)→+372 bit3 / ignore_enter(723)→+372 bit4 (**按 bool 置/清位**, 非仅置位 — 详 §4.30.32b) / is_multiline(745)→+376 |
| CExtendedScrollbarType (自段至 +500; Child CButtonType ctor 宿主参数对 +392/+400) | position(76)→+240 复合块 / size(47)→+288 / tileSize(640)→+340 (sub_142304060) / background(156)→+408 / track(139)→+416 / slider(138)→+424 / increaseButton(638)→+432 / decreaseButton(639)→+440 五 CButtonType\* (各重复报错; 报错串误写 scrollbarType/containerWindowType 名, 引擎原样) / maxValue(150)→+448 / minValue(149)→+456 / stepSize(151)→+464 / startValue(152)→+472 / smooth_scrolling(744)→+480 i32 (sub_1424C0A70) / orientation(194)→+488 / origo(102)→+492 枚举 (0x14230E760) / horizontal(153)→+496 / lockable(285)→+497 / drag(286)→+498 / clickonly(641)→+499 / setTrackFrameOnChange(739)→+500 六 u8 |
| CGridBoxType | position(76)→+240 / size(47)→+288 / slotsize(619)→+340 复合块 / padding(618)→+392 (sub_142303980) / background(156)→+432 CButtonType\* (建时拷 name+72 与行号+224) / max_slots(615)→+440/+444 u32 对 (= max_slots_horizontal(617)→+440 / max_slots_vertical(616)→+444) / format(114)→+448 枚举 (串→0x142375060, 值=7 非法回置 0) / orientation(194)→+452 枚举 (upper_left632=0..center_down637=8; token 15 → 0x1423743D0 表达式) / add_horizontal(614)→+456 |
| CIconType (元素工厂 vtable[13]=0x14236D6C0 → malloc 352B + 元素 ctor 0x1422FACA0) | font(30)/text(143)/buttonText(173)/buttonFont(174) 四键报错 / spriteType(54)/quadTextureSprite(132)/buttonMesh(172) 三键同槽→+256 / position(76)→+288/+292 f32 对 +296=0 +316=1 (2D 路径) / 3dposition(175)→+288 起 (0x140ADDCA0 复合读, +316=0) / scale(93)→+300 f32 / orientation(194)→+304 枚举 / frame(252)→+308 i32 / rotation(342)→+312 f32 / allwaystransparent(319/470)→+317 / centerPosition(578)→+318 / center_on_anchor(751)→+319 u8 |
| CInstantTextBoxType (464B) | textureFile(37) 吞键 / size(47) 弃用告警 ("use maxWidth and maxHeight") / font(30)→+248 / text(143)→+280 / orientation(194)→+384 串 / scrollbarType(140)→+432 串 / maxWidth(145)→+348 / maxHeight(144)→+352 (sub_1424C0900 i32 对) / position(76)→+356 / borderSize(134)→+364 u32 对 / fixedsize(176)→+372 / truncate(197)→+373 / multiline(719)→+374 / text_color_code(660)→+345 单字符校验 / format(114)→+416 枚举 / vertical_alignment(601)→+420 枚举 (同 CButtonType: top602=0 / center50 与 centre117=1 / bottom603=2; 报错串同误拼 tip) / allwaystransparent(319/470)→+424 / ignore_special_chars(716)→+425 / context_aware_text(795)/bound_text(797)→+312 绑定串复合块 (互斥判据 = **+332** = 复合块内 +20 已绑定旗; 仅 795 置 +344=1, 与 CGuiType 基类 +104/+124/+136 三元同构) |
| CLayoutType (positionType 库形态) | 唯一键 positionType(178) → malloc 256B 建 **CPositionType** (vtable 0x142B4BA20, ctor 0x1422FD670, 键 position(76)→+240 / scale(93)→+248 f32) → 嵌套 Parse → 按名插 +240 CTernary 容器 (容器 vtable[48] 插入槽); 余键回落基 |
| CListboxType | orientation(194)→+248 / parent(135)→+280 / background(156)→+312 / dropDown(183)→+344 / heading(184)→+376 串 / position(76)→+412 / offset(314)→+420 / size(47)→+428 / borderSize(134)→+436 u32 对 / priority(141)→+444 f32 / step(186)/spacing(272) 双键同槽→+536 i32 / horizontal(153)→+540 / scrollbarType(140)→+544 / membername(273)→+576 串 / scrollbar_side(656)→+408 枚举 (left=0/right=1, 非法值 → 格式化错误日志 listboxtype.cpp:131 "Invalid scrollbar side at \"%s\", expects \"Left\" or \"Right\"") / allwaystransparent(319/470)→+608 / clipping(631)→+609 u8 |
| COverlappingElementsBoxType | parent(135)→+240 串 / position(76)→+272 / size(47)→+280 u32 对 / orientation(194)→+288 枚举 / format(114)→+292 枚举 (center50=0/right116=1/left115=2/up108=3/down798=4, 非法报错串定案) / spacing(272)→+296 i32 / first_on_top(371)→+300 u8 |
| CScrollbarType (672B; 基含 CFactory md+240) | slider(138)→+248 / track(139)→+280 / rightButton(137)→+312 / leftButton(136)→+344 / rangeLimitMinIcon(354)→+376 / rangeLimitMaxIcon(355)→+408 / parent(135)→+440 串 / position(76)→+472 / size(47)→+480 / borderSize(134)→+488 u32 对 / slider_pos_shift(773)→+496 复合块 / maxValue(150)→+504 / minValue(149)→+508 / stepSize(151)→+512 / startValue(152)→+516 / priority(141)→+520 f32 / horizontal(153)→+608 i32 / lockable(285)→+640 / drag(286)→+641 u8 / rangeLimitMin(352)→+648 / rangeLimitMax(353)→+656 fixed×1e-5 / useRangeLimit(356)→+664 u8 / scroll_speed(233)→+668 i32; guiButtonType(127)/buttontype(625) 双键同路建子件 |
| CRadioButtonGroupType | radioButton(159)→+248/+256/+264 链表 (每键 malloc 56B 节点) / parent(135)→+272 串 (slot[11] 回吐空 SSO, reader 直写) / priority(141)→+304 i32 对 / guiButtonType(127) 经 +320 工厂 vtable+16 造子件挂 +328 插入器 |
| CRadioScrollbarGroupType | radioScrollbar(164)→+248/+256/+264 链表 / parent(135)→+272 / priority(141)→+304 / +312/+320 引用对传子件 ctor / scrollbarType(140)→CScrollbarType 子件 (+328 插入器) |
| CTextBoxType (432B) | borderSize(134)→+240 u32 对 / textureFile(37)→+248 / font(30)→+280 / text(143)→+312 串 / maxWidth(145)→+344 / maxHeight(144)→+348 i32 / position(76)→+352 u32 对 / fixedsize(176)→+360 u8 / orientation(194)→+368 串 (存串不映射) / format(114)→+400 枚举按字面量首字符 (s=0/t=1/u=2) / textblock(261)→+408/+416/+424 链表 (每项 malloc 144B CTextBlock, ctor 0x1422D5230) |
| CLineChartType (25 槽, C2dObjectType 链, serfam 命中; 元素工厂 slot[23]=0x1423207D0 → malloc 448B CLineChart ctor 0x142307AC0) | name(27)→+16 / loadType(293)→+64 枚举 / norefcount(294)→+68 (基 reader 0x142355FD0) / size(47)→+80 u32 对 / effectFile(90)→+88 串 / linewidth(361)→+120 f32 (`(int)v/100000.0*0.5`) |

元素族名录 (全非 CPersistent 不可序列化):

| 类 | vtable (主表) | 槽数 | 基链/次表 | 一句话 |
|---|---|---|---|---|
| CCheckBox | 0x142B465D8 (+次 0x142B46868) | 81 | CGuiObject ← TCollisionObserver (+CCheckBoxObservable md+128) | 复选框 widget (checkBoxType 196) |
| CDropDownBox | 0x142B4C7E8 | 79 | CGuiObject | 下拉框 widget |
| CEditBox | 0x142B4A940 (+次 0x142B4ABD0) | 81 | TEditBox ← CGuiObject (+CTextBuffer/CTextBufferObservable md+128, +CTextInputReceiver md+416) | 文本输入框, 文本缓冲/输入接收双多基面 |
| CExtendedScrollbar | 0x142B49DB0 (+次 0x142B4A030 / 0x142B4A0C0) | 79 | CGuiObject (+TScrollbar/CScrollbarObservable md+128, +CDefaultButtonObserver md+176) | 带增减按钮滚动条, 三vtable面 |
| CGridBoxBase | 0x142B487B0 | 79 | CGuiObject | 网格盒抽象基 ([77][78] _purecall, 不独立实例化) |
| CInstantTextBox | 0x142B468C8 | 84 | CGuiObject | 即时文本框 widget; 元素段 +117 bit3 / +118 bit1 = scoped 上下文双门, +120 CScopedLocalizer*, +128 CInstantTextBoxType* 回指 (文本解析 0x1422CB020 见 §4.30.32c) |
| CCurveGraph | 0x142B4FC30 | 79 | CGuiObject (+CLostDeviceInterface 虚基) | 曲线图 widget |
| CButtonDrag | 0x142B4CC50 (+次 0x142B4CFD8) | 112 | CButton ← TButton ← CGuiObject (+CButtonObservable md+128) | 可拖拽按钮变体; 自有段 +232..+337 + 拖拽状态机见 §4.30.32a |
| CCallbackButtonStandard | 0x142B476C0 (+次 0x142B47A70) | 117 | CButtonStandard ← CButton ← TButton | 回调标准按钮 (族内最大槽数) |
| CLineChart | 0x142B4D068 | 88 | C2dVisibleObject ← C2dObject | 折线图 (2d 元素系非 CGuiObject 系); 448B 元素布局 +400 图形数组 data / +412 图形计数 / +440 x 归一化除数 f32; 图形元素 24B {点数组 data@+0, 容量@+8, 计数@+12, 匿名分配器@+16 (vt+8 allocate / vt+16 deallocate)}; 目标点 16B (三 u32 分量 + f32 归一化 x) / 源点 48B (x@+0 i32 或 fixed, 分量@+32/+36/+40); **CLineChartType::N_POINTS = 40 每曲线上限** (SetData 两实例断言直证, §4.30.32c) |
| CScrollbar | 0x142B42520 (次表 0x142B427B0 TScrollbar 17 槽 / 0x142B42840 按钮观察器 12 槽) | 81 | CGuiObject + TScrollbar@128 + CDefaultButtonObserver@176 | 滚动条元素 (三基三vtable) |
| CStandardlistbox | 0x142B43908 模板面 (次表 0x142B43A38 CGuiObject 面 79 槽) | 37 | CFixedMaxSizeListbox ← CSimpleListbox ← CListbox ← TListbox ← TChoice | 定高列表框, 二层vtable |
| CSmoothListbox | 0x142B4C3F8 模板面 (次表 0x142B4C4F0 79 槽) | 30 | 同链 + IButtonEventFilter@288 | 平滑列表框 |
| CTextBox | 0x142B421D8 | 81 | TTextBox ← CGuiObject | 文本框元素 (行为全在基段) |
| TTextBox | 0x142B41F50 | 80 | CGuiObject | 文本框抽象基 (7 纯虚槽, 排除) |
| TEditBox | 0x142B4A6C0 | 79 | CGuiObject | 编辑框抽象基 (同形少一尾槽, 排除) |
| COverlappingElementsBox | 0x142B5A3F0 | 96 | TOverlappingElementsBox\<CStandardlistboxItem\> ← CGuiObject | 重叠元素盒 (元素层虚槽最多者之一) |
| CKeyBoard | 0x142B3C900 (+次 0x142B3C950 md+48) | 9 | CKeyPressedObservable ← CObservable (+CKeyReleasedObservable md+48) | 键盘事件 observable 基座 (排除) |
| CKeyPressedObservable | 0x142B3C888 | 4 | CObservable ← TObservable | 按键事件基 (排除) |

观察器族 (notificationinterface.h 同模板实例, 4 槽 = dtor/AddObserver/RemoveObserver/**GetClassObservable**; 对象内布局 = +8 头/+16 尾/+24 计数/+28 通知旗/+40 计数挂钩旗, 观察器子对象 48B): CWindowObservable (0x142B58628, [3]→qword_143481138) / CMouseButtonPressedObservable (0x142B511E8, →0x1434524A0) / CMouseButtonReleasedObservable (0x142B51260, →0x1434524B0) / CMouseDoubleClickObservable (0x142B512D8, →0x1434524C0) / CMouseMovedObservable (0x142B51350, →0x1434524D0); AddObserver 惰性删/即删双路 (+28 通知旗分流), debug 断言 `_ObserverList.Contains==false` (notificationinterface.h:64)。**CMouse** (游戏层接口, vtable 0x142B513C8 主 33 槽 + 4 次表 @48/96/144/192; 5 观察器子对象各占 48B; [9]=0x140FDCB00 回吐 **+240 u32 = 当前光标档位索引** — setter = CPdxMouse 槽[4] sub_142384DA0 (`if (*(u32*)(a1+240) != a2 || !*(u32*)(a1+240)) { *(u32*)(a1+240) = a2; return sub_142258040(a1 + 8*a2 + 336); }`), sub_142258040 = `SetCursor(*a1)`; **+336 起 = HCURSOR 数组 (39 档, 0x138B)**, 装载器 sub_142384860 = memset + 39 次循环, 源容器 a2 = {+0 std::string 数组基 (32B 步), +12 条目计数 i32}; 条目有效 (v3 < 计数 ∧ 源串非空) → LoadCursorFromFileA, 失败 → LoadCursorA(0, 0x7F00) IDC_ARROW + pdxinput.cpp:387 "Error loading cursor: <名>" (严重度 3); 条目无效 → 直接 IDC_ARROW; 句柄存 +336+8*v3): 平台实现 = CPdxMouse (§4.00.9)。**CTouchDevice** (0x142B3C768, 5 槽根接口 [1..4] 全纯虚) → CPdxTouchDevice (§4.00.9)。

> **[3] GetClassObservable (定案)**: 回吐本 observable 类的**类级单例指针** (双面对象 {CObservable 广播面@0, TObservable 观察者面@48}, RTTI 实名 `VCWindowClassObservable`/`VCMouseButtonPressedClassObservable` 系); @48 观察者面本身登记进各实例观察者链表。通知派发 (Broadcast 0x1422AFA70) 只走实例链表**不消费 [3]**; 锚仅服务 ① 类级订阅点 ② 单例生命周期收尾 (末实例 dtor 按 count==1 注销 @48 面并删单例)。锚族全景 = 16B 记录 {u32 计数; pad; qword 锚}: mouse pressed/released/double click/moved/wheel = dword_143452498/A8/B8/C8/D8 配 qword_1434524A0/B0/C0/D0/E0, window dword_143481134/qword_143481138, scrollbar qword_1434810E0, sessioninfo qword_143453170, textbuffer qword_1434813A8; 类计数 = 存活实例数 + 挂钩旗实例的登记净值 (锚−8)。**锚写入点机制定案 = 类级单例 ctor 一次性写入** (写点 = 各 observable 类 `TObservable<...>::[1]` AddObserver 内联块, 非独立函数, 故按函数名扫必落空; 以 CMouseButtonPressedObservable vtable 0x142B511E8 为例: 其 [1] = sub_142230980, 体内 `if (*(BYTE*)(a1+40)) ++dword_143452498;` 与 `--dword_143452498; if (qword_1434524A0 && v3 == 1) {…注销 @48 面 + 删单例…}`); 全 15 锚引用形态为 `inc/dec/mov eax [rip+…]` 三类, **无一锚存在 `mov [rip+d], imm/reg` 型绝对写** ⇒ 「间接写」成立 (更准确说法 = 类级单例 ctor 经 this 相对写); 未安装时 [3] 回吐 null, 派发与 dtor 判空兼容。

> 1.19.3 解析语义为**全键落槽** (frame/hide/enabled/is_multiline/scrollbar 四值/lockable/drag/clipping 等约 30 键在旧版为读弃键, 现均有真落槽); scale(93)/rotation(342)/priority(141) = f32, CDropDownMenuType orientation(194) = SSO 串 — 以本族键表为准。
> 读侧 helper 增量 (本节新增, 与 §4.30.31 既有表互补): sub_1402C7E70 = i32 对双 dword 直写 / sub_1424C0A70 = 数值→i32 / sub_1424C2060 = 读弃 / sub_142303C90 = position 复合块 setter / sub_142304060 = size 复合块 setter / sub_142303980 = padding 复合块 setter / sub_14230E760 / sub_1422F9B20 / sub_142375060 = 三枚枚举串→u32 (scrollbar 系 / orientation 系 / gridbox format) / sub_14239E3E0 = 串池化 intern (tooltip 系落 8B 指针槽) / sub_141264520 = shortcut 结构转换 / sub_1423743D0 = gridbox orientation 表达式解析。

#### 4.30.32b GUI 控件 Type 族 Parse 机制面 (buttontype / instanttextboxtype / editboxtype; 4 函 751 行)

三族 Parse (CButtonType 0x142370410 260 行 / CInstantTextBoxType 0x1422FA440 312 行 / CEditBoxType 0x142373070 153 行 + vtable[7] 0x142372F70 26 行) 的共性机制 (键→偏移逐项复证与 §4.30.32 键表 30/30 一致, 零冲突):

| 机制 | 事实 |
|---|---|
| 分派形态 | 入口按 token id 三分 (≤ 边界键 / 中层 / 上层), 全为**查表式 switch 无循环**, 单键 O(1); 未命中一律回落 CGuiType::Parse 0x1422DE390 (公共键 name/tooltip/parent 等) |
| 串族 reader | 统一 sub_1424C0AB0(parser, dest, 0) = `parser->vtable[3](parser, dest)`, 写入为 SSO 32B 串; 栈临时按 capacity>0xF 阈值走析构 free |
| 几何族两 reader | sub_140A4C640 (u32 对; CButtonType 三键 + CEditBoxType cursor) vs sub_1402C7E70 (**i32 对**; CEditBoxType position/size/borderSize — size 负值校验坐实符号性) |
| format(114) 枚举 | 两族逐字节同实现: 分派键 = lexer token **首字符 ASCII** (parser+192), 非完整 token 名 — `'s'`(115)=0 / `'t'`(116)=1 / `'u'`(117) 与 `'2'`(50)=2; 非法 → 形态②日志不中断 |
| 位域写入语义 | `flags ^= ((uint8)flags ^ (uint8)(-bool)) & mask` = **按 bool 置/清指定位** (等价 `if(b) flags|=mask; else flags&=~mask;`), 只动低 8 位 (CEditBoxType +372 五键实证) |
| 双键同槽代码形态 | 两个 case 标号落到同一目标 (allwaystransparent 319/470; CButtonType font/origo/buttonFont 30/102/174 三键) |
| 吞键 / 弃用 | textureFile(37) 在 CInstantTextBoxType = 空 case 纯吞 (该类型恒 instant); size(47) 同处 = 唯一形态③ CLogStream 一行式弃用告警 ("use maxWidth and maxHeight", :122); open_browser(715) = malloc+strcpy → sub_1424C1EF0 挂 **parser 告警表** (非 CLogStream), 不落字段 |
| clicksound "none" 特判 | +776 串 capacity(+800)>0xF 或 size(+792)==4 且内容 "none" → 置 +808=1 并**清空串本身** (sub_1424CB690) |
| web_link(651) | sub_140129CA0(a1+552, "web_link", 8) 把常量灌入 callback_type 槽, 再读 callback_argument → +584 |
| 尾调误形两方向 | CButtonType/CEditBoxType 回落调用显 2 参、CInstantTextBoxType 显 4 参 (r9d=0), 基类实为 3 参 (this, parser, token_id); r8d 恒持 token_id, 语义无损 |
| 错误处理统计 | 形态② 格式化错误日志 ×6 (buttontype :249/:260; instanttextboxtype :39/:54/:65; editboxtype :30/:71), 通道旗 4096, **全部记日志不中断**; 断言 0; throw 0; parser 告警 ×3 (绑定串互斥 ×2 共用同一句文案 + open_browser) |
| 绑定串三元同构 | 子类复合块挪位 = 基类模式的平行复制: CGuiType (+104 块 / +124 判据 / +136 context_aware 旗, 键 794/796) ↔ CInstantTextBoxType (+312 / **+332** / +344, 键 795/797) |

未决: +312 绑定串复合块内部结构 (有独立 vtable 的子对象, +20 判据由其自身解析置位) / sub_1402C7E70 与 sub_140A4C640 的数值解析形态 (是否支持表达式/命名常量) / text_color_code 只校验长度不校验字符类别 (串声称 a-z/A-Z, 待裁是否引擎 bug) / 795 与 797 告警文案不区分键 (待裁有意统一)。

#### 4.30.32a GUI 控件运行期方法群 (CButtonDrag 拖拽事件 / CListboxType 父模板继承 / CSpriteType 运行期七件套)

**CButtonDrag 拖拽事件三件套** (buttondrag.cpp; 元素 ctor 0x142305930 / dtor 0x142305CC0 定案自有段):

CButtonDrag 自有段 (基段 CButton 见 §4.30.31 2d 元素族名录):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +232 | CClass* | 宿主 (ctor a3) |
| +240 | uint64 | 类型对象回指 (ctor `*a7`) |
| +248 | uint64 | 类型对象回指副本 (与 +240 同值, 用途未决) |
| +256 | int32 | 坐标缓存 X, 初值 -1000 |
| +260 | int32 | 坐标缓存 Y, 初值 -1000 |
| +264 | uint64 | ctor 0 |
| +272 | uint64 | ctor a8 |
| +280 | CClass* | 外观/状态对象 (ctor 经 sub_142237A10 创建; vtable[19]=SetState(int) / vtable[40]=SetPosition(坐标对)) |
| +288 | uint64 | 拖拽命令句柄 1 (名取宿主 sub_140CA6260, 经 sub_1423B7110 注册进 CGui+576) |
| +296 | uint64 | 拖拽命令句柄 2 (名取 sub_14236EFA0; OnMouseInput 按键 3 注册) |
| +304 | uint64 | 拖拽命令句柄 3 (名取 sub_14072CBE0) |
| +312 | uint64 | 拖拽命令句柄 4 (名取 sub_14236EFF0; OnMouseInput 按键 5 注册) |
| +320 | uint32 | 拖拽句柄 (sub_1423B7F30 返回; +322 高字参与查询) |
| +324 | int32 | 拖拽阈值/重复计数 (取自宿主 +736); <1 时触发外观重置 |
| +328 | int32 | 拖拽参数, 初值 -1 (+332==2 时消费) |
| +332 | int32 | 拖拽模式 (0=鼠标即时 / 1=键盘候选 / 2=键盘定位) |
| +336 | uint8 | 旗 (取自宿主 +880); 置位时 ctor 额外挂四个观察器 |
| +337 | uint8 | 状态通知抑制旗 (置位时 ResetAppearance 仍执行) |

> 末字段 +337 ⇒ CButtonDrag ≥338B (推定 344B, 8 字节对齐)。四个拖拽命令句柄 (+288/+296/+304/+312) 均在 ctor 经 `sub_1423B7110(*(CGui+576), 名, 1)` 注册 — **CGui+576 = 拖拽命令注册表** (新增; CGui 单例 qword_143453230, getter sub_14225A4A0)。

按钮状态机 (HandleButtonState sub_142306B90; 消费基段 +176 枚举; 出参 +32 = 事件结果 / +36 = 事件类型标记, 按下=3 / 松开=4):

| 当前状态 | 按下 (无修饰) | 松开 (有修饰) |
|---|---|---|
| 0 正常 | →2, 出参 +32=0, 返 1 | →0, 出参 +32=0, 返 1 |
| 2 按下 | →2, 出参 +32=0, 返 1 | →0, 出参 +32=0, 返 1 |
| 3 禁用 | 返 0 (拒绝) | 返 0 (拒绝) |
| 4 拖拽中 | →5, 返 1 | →4, 返 1 |
| 5 拖拽中按下 | →5, 返 1 | →4, 返 1 |
| 其他 | 断言 buttondrag.cpp:779, 返 1 | 断言 buttondrag.cpp:807, 返 1 |

三方法 (均虚槽方法, 全语料仅定义处引用):

| VA | 方法 | 职责 |
|---|---|---|
| 0x142307030 | CButtonDrag::OnMouseInput | 主鼠标输入分发: 事件类型 0=按键 / 3=移动; 基段 +228 bit3 门关 → +176=0 直接返回; 5 按键 id 分派 (1=左键拖拽 sub_142306AE0 / 3=句柄注册+置 5 / 4=sub_142306DB0 / 5=使能门 sub_1422ADFB0 过 → 置 2 + 注册 + 拖拽开始/更新; 0/2 无操作); 每 case 收尾经 sub_1422AFA70(this+128) 广播观察者 + HandleButtonState 收口 |
| 0x142306B90 | CButtonDrag::HandleButtonState | 按下/松开状态机转换 (上表); 按下分支取 +288 句柄经 sub_1423B7F30 注册拖拽候选 |
| 0x142305D40 | CButtonDrag::ResetAppearance | +324<1 或 +337 置位时按 +176 状态经 +280 对象 vtable[19] 下发外观参数 (状态 0/2→参数 1 / 3→4 / 4/5→2, 其他 → 断言 buttondrag.cpp:606) = 拖拽未真正开始时把外观退回非拖拽态 |

**CListboxType 父模板继承** (sub_142376740, 虚槽方法, listboxtype.cpp; reader 键表见 §4.30.32):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +296 | uint64 | 继承门 (非空才进入继承流程) |
| +448 | SSO 串 | 模板/继承名 (传 sub_142259710 做按名解析) |
| +456 | uint64 | 模板引用对象指针 (槽 [0]/[2]/[3]/[4] 均参与解析) |
| +512 | u32 数组 {data@+512, count@+524} | 待继承键 token 列表 |

> 流程: ① +448 名经 sub_142259710 从 +456 模板引用对象解析模板链 (槽 [2]/[4]/[3] 逐个参与); ② 谓词 sub_142376550 (推定 = 存在待继承父模板) ∧ +296 门非空 → `owner->vtable[1](owner, this+280)` 按父名解析得父对象; ③ 遍历 +512 数组逐 token 查 sub_142377480 (推定 = 该键本实例未显式设置), 未设置则从父对象同名槽拷入 (qword 直拷 / SSO 串走 sub_140129CA0); ④ 未知 token → 断言 listboxtype.cpp:291 (B51 门, latch byte_1435B9D1F); ⑤ 拷完取 this vtable[9] (GetName) 与父对象 vtable[11] (父串回吐) 比较, 不等则按新名重解析父链 (循环收敛)。
> **九个可继承键**: size(47)→+428 / position(76)→+412 / borderSize(134)→+436 / parent(135)→+280 / priority(141)→+444 / background(156)→+312 / dropDown(183)→+344 / heading(184)→+376 / orientation(194)→+248。**不继承**: offset(314) / horizontal(153) / scrollbarType(140) / membername(273) / scrollbar_side(656) / allwaystransparent / clipping — 布局几何与外观串继承, 行为配置不继承。

**CSpriteType 运行期七件套** (spritetype.cpp; 布局见 §4.30.31):

| VA | 方法 | 职责 |
|---|---|---|
| 0x14223F8D0 | GetFrameGridXY | 线性帧号→(列,行) (out int32[2]); 方向由 +268 与 +144 帧列数决定 (断言 :588) |
| 0x142240080 | CreateVertexBuffer | +240 置 -1.0 哨兵; 旧缓冲 vtable[31] 回收; 建 4 顶点×20B 四边形 VB → +224; +264 置脏旗 |
| 0x14223FA30 | LoadTexture | 拷入 +112 textureFile; legacy_lazy_load(+467) 路径即时装载 → +416 id / +368 指针 / +164/+168 尺寸; 否则回落 vtable[10]/vtable[9] |
| 0x1422401E0 | LoadTextureIfNeeded | 惰性装载: +467 ∧ +416==-1 ∧ +128(名长)>0 时才装载 (同三槽写入序列) |
| 0x1422431C0 | IsTransparentAt | 像素级 alpha 命中: +273 全透明或 +368 无纹理 → 1; +464 未启用 → 0; 主纹理不命中再查 +376 遮罩纹理 |
| 0x142242BD0 | ResolveTexture | id→(指针, 尺寸) 解析 + 双告警通道 (指针空 → :330 初始化失败; 压缩格式禁止 → :340 建议 DXT3, 告警后清零 +464) |
| 0x1422420E0 | SetupEffectAnimation | 遍历 +280 动画向量收集 ≤2 匹配技术 → +304/+320 句柄; 无动画一次性告警 (旗 +468) 并清空动画向量; +467=1 时 :799 告警惰性装载与动画不相容 |
| 0x1422424E0 | Render | 渲染主函数: +240 动画时间/+264 脏旗 → vtable[30]; +252 帧索引钳位; UV = 帧格 × (+256,+260); CColor(+192) 着色 × +420 alpha; +368/+376 双纹理; +224 VB 绘制 |
| 0x142240530 | InitResources | 资源初始化总入口: 默认 effectFile "gfx/FX/buttonstate.lua"; 装载主纹理; 动画技术 "ANIMATED"/"NUM_ANIMATIONS_\<n>" → +304/+320; 逐动画项双纹理 → 元素 +120/+128/+136; 遮罩纹理 → +376 + "MASKING" 对 → +336/+352 |

> **纹理管线** (宿主 +72 持纹理管理器于其 +368): `sub_142406740(管理器, 名, flags, 1) → u32 id` (写 +416) → `sub_1424071E0(管理器, id) → CTexture*` (写 +368) → `sub_142407010(管理器, out, id)` (写 +164/+168)。按名取件 = sub_142407370; 像素命中 = sub_142407530 (坐标先按 a4 缩放、再按帧格+帧索引偏移)。**告警双通道**: 纹理指针空 → :330 "Error initialising texture: \<名> for spritetype \<名>"; 禁止压缩格式 (`(v18-1) & 0xFFFFFFFB == 0`) → :340 "Texture \<名> have forbidden compression, have you tried DXT3?" 并清零 +464 (DXT3 无可靠 alpha ⇒ 同时关闭像素命中测试)。
> **两条装载路径**: 非惰性 (+467=0) — InitResources 即时装载; 惰性 (+467=1) — LoadTextureIfNeeded 仅在 +416==-1 且名非空时装载, render 对「惰性却未装载」额外打 :606 告警 "Should not be lazy loaded. Set lazy_load=no for \<名>"。
> **帧映射**: UV = GetFrameGridXY(frame) × (+256,+260); 帧索引 +252 = max(0, min(a7-1, 列数×行数))。技术对象经 sub_14240ACC0(宿主+1336, 句柄) 取得 (+44 = 动画数, +32 = pass 表); 动画数 <5 → :927 "Effect X does not yet support animations" + sub_14223D1C0 清空 +280 动画向量 (不可恢复, 故一次性旗 +468)。


#### 4.30.32c GUI 控件运行期机制面二 (模板继承链解析 / 属性拷贝器 / 折线图数据 / 即时文本解析 / 锚点权重表)

**模板继承链解析三形** (虚槽方法; CListboxType 形见 §4.30.32a, 另两形本节定案): 清理 std::function 容器 → 模板注册表 vt[1] 取父模板 → 遍历待继承 token 向量逐项过滤 → 命中按 token 拷贝 → 比对本类 vt[9] (GetName) 与父模板 vt[11] (父串回吐), 不等则按父串重取父模板沿链推进。

| 类 | 方法 | 待继承 token 向量 | 取父模板方式 | 尾收 |
|---|---|---|---|---|
| CWindowType | 0x1422F7EA0 | data@+608, count@+620 | `a2->vt[1](a2)` 无键 | fullScreen(+1040) 非零时把宿主 +528 引用对象的 +384 基面尺寸对写入 +344/+348 (size 跟随宿主) |
| CDropDownMenuType | 0x142372360 | data@+464, count@+476 | `a2->vt[1](a2, a1+248)` **以 parent 名为键** | `sub_1422F9B20(a1+488)` 解析 orientation 串 → +520 u32 |

> 属性拷贝 = 二层 switch: 调用者 (继承链解析) 算源地址、被调者算目标地址, 两表偏移完全一致 (同类同槽)。CWindowType::CopyPropertyFromTemplate = 0x1422F99E0 (token 表 = §4.30.32 CWindowType 键表, 含 Parse 不受理的 threeDguiType(320)); 未命中 → "FAIL" 断言 windowtype.cpp:922。CDropDownMenuType 侧未命中 → "Error" 断言 dropdownmenutype.cpp:209。

**CLineChart::SetData 两模板实例** (linechart.cpp; 元素布局见 §4.30.32 名录 CLineChart 行):

| VA | 实例 | x 归一化公式 |
|---|---|---|
| 0x142307FA0 | SetData\<i32\> (x 已是除数单位) | `(float)(int32)(源点+0) / *(float*)(this+440)` |
| 0x142308260 | SetData\<fixed\> (x 为 fixed×2^-15) | `(float)((float)(int32)(源点+0) * 0.000030517578) / *(float*)(this+440)` |

> 常数 0.000030517578 的 f32 位码 = 0x38000000, 与 2^-15 的 f32 编码逐位相同 (PE 侧验算) → 即精确 2^-15, 非近似。两实例共用断言 `Graph.GetSize() <= CLineChartType::N_POINTS`, **N_POINTS = 40** (每曲线点数上限; 条件 count>40 触发, once-only)。容量增长 `newcap = max(needed, (int)(float)(cap*1.5))` (同族 CPdxArray 约定)。

**CLineChartType 折线渲染几何构建器 0x142320960 (linecharttype.cpp; VA 新锚)** = N_POINTS 常量的**第二独立证据点** (linecharttype.cpp:176 断言 "LineData.GetSize() <= N_POINTS", 独立闩 byte_143481450; count > 40 硬钳 min(count, 40) 后 memcpy 16B 点跨距进 640B 栈缓冲 = 40×16)。渲染几何参数: 顶点数 = 2n−2 (n 点折线四边形带, 经全局 mesh 管理器 qword_143481448 的 sub_1422D5110); 归一化因子 = 2.0/width 与 −2.0/height (宽高经 sub_142238DD0(a1, &out) 取, 宽@out+0 / 高@out+4); 颜色 = 全局 *(float*)(qword_143453090 + 206296) 缩放曲线对象 +368/+372 分量 + vtable[336] getter 两分量; x 步进 = a3[92] × 缩放 / max(n−1, 1); count==0 直接返。⚠ 类名归属待裁 (a1 持 +1336 与尺寸 getter, a3 持 vtable+336 getter — 推定 CLineChartType 成员或 C2dObjectType 链入口, 不在 §4.30:1758 已列 25 槽内)。

**CInstantTextBox 文本解析** (0x1422CB020; 被 CInstantTextBox 刷新链 sub_1422C9FE0 调用): `type = *(this+128)` 空则直接返回; `type+344 (context_aware 旗) == 0` 或 `type+332 (绑定判据) == 0` → 普通文本路径 (type+280 text SSO 装缓冲 → sub_1422CA920 落控件); 否则需 `this+118 bit1 ∧ this+117 bit3` 双门满足才用 +120 的 CScopedLocalizer 解析绑定块 (type+312; 出参向量元素跨距 104B); 双门不满足 → 错误日志 `"Scoped text used in instant text box for type %s (%s:%d)"` (instanttextbox.cpp:438, 通道旗 4096), 三实参 = type vt[9] 返回的 name 串 / **type+72 文件名 SSO** / **type+224 行号 u32** — 后两槽为 §4.30.32 载「Load wrapper 0x1422DE0B0 先记文件名+行号」的消费侧首证。

**CEndGameView 得分页签填充** (0x141F87720, hoi4\source\interfaces\endgameview.cpp; CEndGameView 三重直证 = dump 内 `CLegacyButtonObserverGlue<CEndGameView>` vftable 赋值点 + `std::_Binder<...,CEndGameView*,...>` RTTI + vt_rtti.json 0x142A9F320):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +10312 | CCountryEntry* | 国家条目数组 (元素跨距 8B) |
| +10324 | int32 | 国家条目计数 |
| +10368 | CGuiObject* | UI 根 (vt+440 = GetChildByName) |

> 流程: tab (0..7, >7 断言 "Unexpected enum") 分派 8 个排序函数 (0x141F84C20/0x141F84A00/0x141F84F50/0x141F848F0/0x141F84D30/0x141F847E0/0x141F84B10/0x141F84E40, 同模板 8 实例, 均 6 参) → 计数>32 时申请 ceil(n/2) 字节暂存 (仅 >512B 用毕释放) → UI 树三层下钻建表: 根 vt+440 取 "countries_info" → 同槽取 "countries_info_list" → **vt+432** 取 "country_list" → 清表后逐国家入列 (sub_1402DE9B0) + 刷新 (sub_1422C7E50)。

**锚点权重表** (0x1422B3020, guienumhelpers.h `PlaceAtAnchor`): `out.x = point.x*Wx − size.w*Wx'`, `out.y = point.y*Wy − size.h*Wy'`, W/W' ∈ {0, ½, 1}:

| 枚举 | point 权重 (x, y) | size 权重 (x, y) |
|---|---|---|
| 0 | (0, 0) | (0, 0) |
| 1 | (1, 0) | (−1, 0) |
| 2 | (0, 1) | (0, −1) |
| 3 | (1, 1) | (−1, −1) |
| 4 | (½, ½) | (−½, −½) |
| 5 | (0, ½) | (0, −½) |
| 6 | (1, ½) | (−1, −½) |
| 7 | (½, 0) | (−½, 0) |
| 8 | (½, 1) | (−½, −1) |

> ⚠ 本 9 值枚举与 sub_1422F9B20 的 7 值 orientation 枚举**不是同一套** (本枚举 5=(0,½) / 6=(1,½) / 7=(½,0) / 8=(½,1); orientation 5=center_up / 6=center_down 且无 7/8)。语义命名推定: 0=upper_left / 1=upper_right / 2=lower_left / 3=lower_right / 4=center / 5=center_left / 6=center_right / 7=center_up / 8=center_down (待裁)。

**orientation 枚举表全解** (sub_1422F9B20, memcmp 长度逐一复证; 闭合本节原未决):

| 串 | 枚举值 |
|---|---|
| "upper_left" | 0 |
| "upper_right" | 1 |
| "lower_left" | 2 |
| "lower_right" | 3 |
| "center" | 4 |
| "center_up" | 5 |
| "center_down" | 6 |
| 任一未命中 | 0 (缺省回置) |

> 消费点: CDropDownMenuType +488 串 → +520 (上表)、CEditBoxType orientation(194)→+368 (§4.30.32); token 632..637 + 字面量 "center" 与 7 值一致。CGridBoxType 用另一映射 0x142375060。

**button.cpp 两枚未实现桩** (0x1422B0B50 / 0x1422B0BB0, button.cpp:835/:840): 零参零返回, 体仅 once-only 断言 (门 byte_1435E1B52, 通道旗实参 1), dump 内零调用者 → 仅经 vtable 引用; 两 latch (byte_143481130/131) 所属子系统与同 CU 其他断言 (门 byte_1435E1B51) 不同组, 语义归属未决。

#### 4.30.33 装备设计器 / 市场 GUI 对象 (CEquipmentVariantBuilder / CEquipmentType)

定名与锚点总表:

| 对象 | 锚 / 定名 | 语义 |
|---|---|---|
| CEquipmentVariantBuilder | 8800B (equipmentvariantbuilder.cpp 断言实名); 双内嵌 CEquipmentDesignerView +14232 (主编辑) / +23032 (母本对照); SetTarget = 自由函数 sub_141788C50 | 设计器主编辑器; 布局见下表 |

> ⚠ 定案: **CEquipmentDesignerView (0x12220=74272B) 内嵌 CEquipmentVariantBuilder ×2 于 +14232 (主编辑) / +23032 (母本对照)**, 14232+8800=23032 紧邻密接 (8800B builder 容不下 +23032 偏移)。保存链: save_button sub_141786710 (mode≤1 发 CCreateEquipmentVariantCommand, 载荷源 = view+19208 builder 草稿; origin(+32)>0 = 保存硬门; mode 3 逐差发 7 条外观命令); duplicate_button sub_1417846D0 / reset_button sub_1417864B0; Repgregate 实名 = sub_14178DC00 (this=view+40); Setup = sub_141788E70 (EDesignerType→布局名: 0=country/1=tank/2=plane); 历史设计应用 sub_141784A80 (镜像回填 view+74244 源 id); view 编辑镜像区 +31848..+31974 布局表见本节上表。
| CEquipmentType | — | 装备类型 def; 布局见下表 |
| dword_143333C2C | = NAir::MAX_QUICK_WING_SELECTION (定案) | 快速翼选择上限 |
| CAIEquipmentDesignEntry | **0x320 = 800B** (vtable 0x1429C7198; common/ai_equipment; writer CFG 空桩) | 全布局: +72 CAIMTTHChance priority / +344 CAndTrigger enable / +432 visible / +440 name / +472 override_sprite 复合 / +520 override_model / +552 history (10293) / +556 变体来源 u32 / +560 match_value / +568 CEquipmentType* / +576 role_icon_index / +584 upgrades 72B / +608 modules 144B / +632·+656·+704 allowed_modules 三路 / +680 requirements map / +728 design_team / +736·+768 runtime SSO; 消费库 = CCountry+5544 scoped_ptr 每国 AI 设计库 (GUI 历史行件 = 0x1138 = 4408B 另一对象, GetOrCreateHistoricalDesignItem 产) |
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
| +5004 | uint32 | **creator tag**（SetCreator = sub_141491EB0(builder, tag)；玩家 tag 经 qword_14332F260+1312/1316） |
| +5992 | CEquipmentVariant* | **draft.parent = "pRefVariant"**（断言 0x13F；LoadVariant 置为 draftB） |
| +6008 | u64 | draft._Category 位掩码（四比对 = sub_141490F10，parent+1032 对照） |
| +6136 | id 对 | design team 槽（setter sub_1414925D0；与 parent 比对） |
| +6144 | NIndustrialOrganisation::CTraitBonus | design team bonus 内嵌 |
| +6184 | — | 变体镜像 #2 |
| +7392 | — | parent 镜像 |
| +8600 | uint8 | **活动侧选择旗**（E720: 0→+4976, ≠0→+7392；编辑前若置位则 B 拷回 A 并清旗；getter sub_141490A30） |
| +8604 | uint32 | LoadVariant 清理位 (sub_141491500 同序清 +8600/+8712/+8604; 10 处访问全 4B) |
| +8608 | 16B 元向量 | **槽→模块指针有序自动推荐表** (元素 {槽id u32@+0, CEquipmentModule*@+8}, 按槽 id 二分插入; 写入者 sub_1414900E0 — 从镜像#1+184 拷贝后逐槽算推荐 (sub_14148A360) 更新; count@+8620) |
| +8632 | CEquipmentUpgradesInstance | 三通道设/复位/自动 (builder sub_1414926E0/F120/D240; 国别上限 sub_141537940) |
| +8640 | 匿名结构 (元素待裁) 向量 | 未名容器四 (sub_14148F310 = 默认构造 / sub_14148F830 = 拷贝构造 — 二者均非析构; 拷贝构造对 +8640/+8664/+8688 三容器只清理不拷贝, 反证零静态引用预留域负定案; 元素无证据 (零消费), 24B CVector 头槽 (ctor sub_14011DF40 与 +8608/+8776 同款)) |
| +8664 | 匿名结构 (元素待裁) 向量 | ctor/dtor 之外零静态引用 — 预留域 (负定案) |
| +8688 | 匿名结构 (元素待裁) 向量 | ctor/dtor 之外零静态引用 — 预留域 (负定案) |
| +8712 | uint8 | 预览重算门之一（sub_141492970: !+8713 && +8712 → 重算 +1664） |
| +8713 | uint8 | 预览重算门之二 |
| +8720 | uint64 | design team ref 缓存 |
| +8728 | NIndustrialOrganisation::CTraitBonus | 第二 design team bonus 内嵌 (vtable 三方向直证; 其容器@+8736) |
| +8768 | id 对 {type,id} | **参考变体 id 对** (门 = 双非零 ∧ sub_14221F310 解析 ∧ result._pType+1008 == draft._pType+5984 同型; 否则回退 sub_140E67ED0(ps, arch, tag) 按原型找现役; 哨兵 qword_14333D528; 行为合一于 sub_141490980) |
| +8776 | 8B 元向量 | **槽-模块编辑表** — 元素 {槽id u32@+0, 模块id u32@+4} idpair (写入者 sub_1414919B0: 逐槽查当前模块非零 append / 零则移除; LoadVariant sub_141491500 从镜像#1+184 降级重建; {cap@+8784, count@+8788, alloc@+8792}) |

草稿 draft (builder 内草稿对象):

| draft+N | 类型 | 名称/语义 |
|---|---|---|
| draft+40 | SSO | name |
| draft+184 | 16B 元向量 | modules = CEquipmentVariant+184 同构 (§4.23.1; 元素 {slot_token, CEquipmentModule*} — +8 为模块 token, 旧 str* 说更正) |
| draft+580 | — | niche |

CEquipmentType:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | — | 类型名 (blueprint TYPE 参) |
| +112 | 匿名结构 (80B 非多态槽结构, +8 槽 token; 无独立 RTTI) 向量 {data@+112, 计数@+124} | 80B 槽表 (槽 id@+8; 行池按 token "fixed_" 前缀分池; equipment_designer_module_slot_entry) |
| +320 | — | 类别枚举 = **interface_overview_category_index** (airwingreorganizationview.cpp:0xEC 断言实名; 账本机种计数行 TARGET_HAS_CATEGORY_\<n\> 键; 负值时消费端沿 +1240 父链上溯取首个非负, sub_140C95880) |
| +784 | 平坦零化区 | **负定案** — ctor sub_140C926E0 平坦零化 + dtor 零清理 (无堆容器); 类型变体收集真锚 = CEquipmentVariant+1008 类型回指 (sub_1413134B0 收集样板) |
| +960 | — | 图标 |
| +968 | — | GFX 图标串部件 |
| +988 | token | `group_by` 脚本键值 (vtable[4] KV 分发 case 13022, 默认 357 = "none"; 后勤特判行键) |
| +992 | token | interface_category |
| +997 | uint8 | 类型有效旗 (has_design_based_on 变体过滤第二门; 推定) |
| +1000 | uint8 | 舰载机字节 (显隐门) |
| +1240 | — | 父 archetype 链 (reader token 12103 = archetype 挂接; 后勤行域谓词按父链 + 掩码@+1344 分 land/naval/air) |
| +1344 | u64 | **类别位图掩码** (reader token 225 = type 逐类别 token OR 入, mapper sub_140F88330 全解码见下表; 缓存 +312) |
| +1365 | uint8 | 停止字节 (reader/谓词两处门) |

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
| 提交命令 | CSetMarketRequestAutomationOptionsCommand (vtable 0x142A3F8F0, sub_141B1BA00) | cmd+40 = *(*(target)+8) = 请求 id u32 (target = NInternationalMarket::CPurchaseRequest vtable 0x142A28ED0, +8 = request id, reader 键 11); cmd+44/+46 = 旗 |

target 三 bool ↔ 三 checkbox:

| 偏移 (target) | 类型 | 名称/语义 | UI |
|---|---|---|---|
| +32 | bool | 自动接受市场准入 | checkbox auto_accept_market_access |
| +33 | bool | 自动发送市场准入 | checkbox auto_send_market_access |
| +34 | bool | 自动接受购买 | checkbox auto_accept_purchase |

三 lambda 统一投 CSetMarketRequestAutomationOptionsCommand。

target 句柄定案: *(target) = NInternationalMarket::CPurchaseRequest (vtable 0x142A28ED0 RTTI COL 直证; +8 = request id = cmd+40 载荷源); win+1440 = CMarketOverviewPanelController 上下文, ctx+64 = 当前请求 — 推定「请求管理器条目」撤销。

#### 4.30.35 活跃合同控制器 (CActiveContractsUiController)

| 项 | 值 | 语义 |
|---|---|---|
| RTTI | 无自身 RTTI/vtable (仅 lambda 有 TD) | — |
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
| CAddEquipmentToMarketWindow (vtable 0x142AB62B0, CPopUpWindow, 6528B) | **win+1440 CMarketStockpile\* + win+1448 CCountry\* 卖方** (stockpile+104 复证) | 宿主 = CMarketStockpileWindow (lambda 名直证); add_button 恒投 **CMarketStockpileEquipmentTransferCommand {+40/+104 双 64B 池 / +168 卖方 tag, id 13859 ✓}**; 价格档有差时加投 **COverrideMarketEquipmentPriceLevelsCommand {+40 tag / +48 map, id 14010 ✓}** |
| CAddToMarketEquipmentItem (vtable 0x142AB6170, 25 槽, 基 CMarketEquipmentItem) | 基存 **SMarketEquipmentData 72B@+40** + 自建数量组件 0xC08@+1616 / 价格档组件 0x1078@+1624 (两组件尺寸命中 §4.31.15 ✓) | 覆写 [22] IsSelected (推定) / [23] GetAmount / [24] GetPriceLevel |
| CMarketAccessOverviewWindow (vtable 0x142AADE80, 1536B) | 宿主 = CMarketOverviewPanelController (§4.30.34 同宿主 ✓) | [11] 枚举 **gs+784 全国 × 关系过滤** (国+3976, 类型 26 推定 = 市场准入) 生按国行; 内嵌 CCancelMarketAccessPoup@+1480; 确认出口 = **CRequestMarketAccessRightsAction {+120 = 1 撤销旗}** |
| CMarketAccessOverviewItem (vtable 0x142aae070, 零覆写 2792B) | **+2784 对方 tag / +2788 自体 tag** | 行 = 国旗/国名 + cancel_market_access_button (状态门 (state-1)>2 禁撤) + open_diplomacy_button (窗型 9 定位对方国) |
| CTradeOfferWindow (vtable 0X142A60F58, **CReloadableInterface 非弹窗**, 4152B; **交易 CIC 成本取数器 0x141CB53E0 (定案)** = 自体国 this+4080 (tag@cc+8) / 玩家 tag gs+1312 (**无 1316 回退**) → tradeview 取数 sub_1415FCE30(this+4064) → 成本核 sub_140CA7CD0(out, v9, &玩家tag, &自体tag, 1) → 返 cost/1e5, <1e5 钳 1, ≤0 断言 tradeofferwindow.cpp:233 "Trade has 0 factory cost - why does this happen?") | 挂 **CCountryTradeView+7952** | send → **CCreateTradeCommand {+40 对方 tag / +44 自体 tag / +48 = tradeview+7944 资源 id / +56 量}**; 超运力走 default_confirmation_popup 延后派发 |
| CCancelSellingContractPopup (vtable 0x142AAE7E0, CDefaultConfirmationPopUpWindow, 4208B) | **卖方侧下架确认** (对照 §4.31.15 买方侧 CCancelEquipmentPurchaseAction) | 全删 → **CMarketStockpileClearCommand {+40 tag, id 10191 ✓}**; 单条 → 同 CMarketStockpileEquipmentTransferCommand |
| CIncomingLendLeaseEquipmentItem (vtable 0X142A93368, 零覆写 1384B) | **CDiplomacyIncomingLendLeaseActionController+9168 网格的装备行** (与 §4.30.36 按国行 CDiplomacyIncomingLendLeaseItem 划清边界) | setter sub_141F2BE90 填 name/in_pool/producing + 舰载机图标门 (**元素+1000 ✓**); 点击 → 取/建 CDiplomacyRequestIncomingLendLeaseItem 进请求列表 |

#### 4.30.38 CMapModeManager (全地图模式管理器; 情报账本 = mode 30)

单例 qword_14333CFB8 (本类实名, 见 §4.11.10); **对象 288 B** (ctor 调用点 sub_140E13750 malloc 直证); ctor = sub_140DFCD30, 尾调模式切换总派发 sub_140E17F30(mgr, 0, 0, 0) 切到模式 0。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | — | 当前 mode id | −1 初值; 30 = 情报账本 |
| +4 | uint32 | 未决 (ctor 清零, 簇内无写点) | 疑与 +8 成对 |
| +8 | — | **previous 模式 id** (保存模式 sub_140E16B80 `a1[2] = *a1` 直证写入) | 清除 = sub_140DFDBF0 (调用者 sub_1417CAC10) |
| +16 | shared_ptr | 当前 mode 实例 — ptr | 与 +24 成对 {ptr, ctrl}; sub_140DFD540 = 原子增引→调 lambda→释放 |
| +24 | shared_ptr | 当前 mode 实例 — ctrl | 同上 |
| +32 | shared_ptr | **保存的模式实例 — ptr** (E16B80 拷自 +16/+24) | 与 +40 成对; DFDBF0 清 |
| +40 | shared_ptr | 保存的模式实例 — ctrl | 同上 |
| +48 | 指针 | → **GradientBorderManager (GBMan)**, 160 B 堆对象 (ctor 日志 `_pGBMan->LoadDatabase: ` + gradientbordermanager.cpp:354/363 串直证; 布局见下) | NotifyProvinceChanged 经 sub_140F31B50(+48 缓存, prov+164) 标脏 |
| +64 | — | tag 观察者 hub | |
| +72 | — | context = gs | |
| +80 | uint32 | **页号 A** (初值 7; 模式切换按模式写 0-7) | 脏位 = +129 |
| +84 | uint32 | **页号 B** (同上) | 脏位 = +130 |
| +88 | uint8 | formatter 有效旗 (DFDB00 重置 formatter 时清零) | 省 tooltip 消费 |
| +96 | — | formatter 子对象 = **pdx scoped_ptr** (pdx_scopedptr.h:134 断言; vtable[3](buf, prov_id) 追加行) | 非「泛型子对象」 |
| +128 | uint8 | tooltip DEBUG 门 (非 0 → DEBUG 省份转储分支) | 写者未决 (疑 settings/调试通道) |
| +129 | uint8 | 脏位 A (E17F30/E16980/E139C0 置位; ctor 初值 1) | |
| +130 | uint8 | 脏位 B (同上) | |
| +144 | CVector | — | |
| +168 | rh 表 A 头 | **省 id → 控制国下标 倒排表** (头部五字段见子表) | 定案 (四链证据见下注) |
| +200 | rh 表 B 头 | **控制国下标 → 省 id 集合 倒排表** (40 B 条目 {距@4, key@8, 数据@16, 数量@28}) | 同上 |
| +232 | CVector | — | |
| +256 | — | 0 (ctor 清零, 簇内无消费) | 未决 |
| +264 | — | 0 (同上) | 未决 |
| +272 | — | 事件门旗 (省控制权事件 sub_140E16980 入口门) | |
| +276 | uint32 | −1 初值 (簇内零读写) | 未决 (疑事件 pending 槽) |
| +280 | — | **脚本模式实例指针槽** (E17F30 入口清零; mode ≥40 时写入库条目) | |

rh 表头五字段 (A/B 同构; 哈希 = 0x045D9F3B 两轮雪崩, mgr 族 helper 共用):

| 字段 | A 表 | B 表 | 语义 |
|---|---|---|---|
| data | +176 | +208 | 空表哨兵 = &unk_143086250 / &unk_1430B15D0 (全引擎共享判空式) |
| 计数 | +184 | +216 | |
| 掩码 | +188 | +220 | |
| 最大探查距 | +192 | +224 | u8 |
| 最大负载因子 | +196 | +228 | f32 = **0.9f** (exe 双 mov 指令直证; 插入时 `((计+1)/掩码) > 负载` 触发 rehash sub_140E132C0) |

注 (定案, 四链证据): +176..+228 两槽为 rh 表非 tween — ① rh 插入/查找原语 (sub_140DF9AD0/sub_1401B04A0/sub_140DFA4E0) 按头 +8/+16/+20/+24/+28 读字段, E16660 以 mgr+168/+200 为头调用即 +176..+228; ② 0.9 = 经典 rh 最大负载因子, 与比较式吻合, 簇内无该两槽浮点读取; ③ 空表 data 哨兵为全引擎共享判空常量; ④ E16980→E16660 双表行为闭环 (上)。

省控制权倒排索引维护 (sub_140E16980 ← CMapModeDispatcher 转发, 门 +272): 新 owner tag 经 sub_140BB5490 (gs+832) 解析 → A 表按 prov_id 查旧值 (同值早退) → B 表按旧 owner 压缩式移除 prov_id → A 表插 prov_id→新 owner, B 表插新 owner 条目并追加 prov_id (断言 "pProvinces != nullptr" mapmodemanager.cpp:359 = 溢出区空指针防御) + hub 通知 + 双脏位置位。

GBMan (mgr+48, 160 B) 与图层对象 (各 136 B, sub_141596CE0 构造):

| 偏移 | 语义 |
|---|---|
| +24 | 图层指针数组 (23 个独立 malloc(136) 图层对象) |
| +32 | 数组容量 (1.5× 增长, 最少 23) |
| +36 | 数组计数 = 23 (23 个独立 136 B 堆块, 非 23×136 连续块) |
| +48 | LoadDatabase (sub_140F33890) 建的 72 B 库件 |
| +56 | gs 回引 |
| +64 | 子件 (sub_1419DC530 装载) |
| +72..+94 | 23 图层脏字节 (图层对象 +84 = 自身下标; 模式切换经 sub_140F3B090 置位) |
| +95 | 选择槽脏位 A |
| +96 | 选择槽脏位 B |
| +100 | 组选择槽 A = 当前选中图层 id (−1 = 无; 模式切换经 sub_140F31D20 写) |
| +104 | 组选择槽 B (同上) |
| +128 | 容器 |

图层对象 136 B: +76 f32 = GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_* define 落点 / +80 f32 = GRADIENT_BORDERS_OUTLINE_CUTOFF_* 落点 / +84 = 脏字节下标 / +116 = dword 子模式值 / +128 = 刷新 byte。define 存储槽: dword_143332CD0/143331C5C = DIPLOMACY 对, dword_143332D90/143331D18 = DIPLOMACY_ON_INTEL_LEDGER 对 (模式 9/23/30 切换写入图层)。图层重建分派 = sub_140F33D50(db, 图层号); s4_30:678「脏旗 *(mgr+48)+83」= 图层 11 脏字节, 模式 30 选择槽 {1,11} 完全闭合。

mode id 实名表 (sub_140E028C0 = id→"MAPMODE_XXX" 键名构造器, 定案):

| id | 名 | id | 名 |
|---|---|---|---|
| 0、28 | MAPMODE_DEFAULT | 9 | MAPMODE_DIPLOMACY |
| 1、32 | MAPMODE_STRATEGIC_AIR (⚠ 32 另见 §4.30.19 CMapModeOperationSelectTarget 区域侧实例, 待裁) | 10 | MAPMODE_FACTIONS |
| 2 | MAPMODE_STRATEGIC_NAVY | 11 | MAPMODE_PLAYERS |
| 3 | MAPMODE_OPERATIVES | 12 | MAPMODE_INFRASTRUCTURE |
| 4 | MAPMODE_STATES | 13 | MAPMODE_MANPOWER |
| 5 | MAPMODE_SUPPLY_MAP_MODE | 14 | MAPMODE_IDEOLOGY |
| 6 | MAPMODE_RESISTANCE | 15 | MAPMODE_TERRAIN |
| 7 | MAPMODE_COMPLIANCE | 16、38 | MAPMODE_RAIDS |
| 8 | MAPMODE_RESOURCES | ≥40 | "MAPMODE_" + 脚本模式名 (库 {数组@+40, 计@+52}, 条目 8 B/项) |
| 20 | MilitaryDeployment (无本地化键) | 23 | **造宣称目标选择** (MAPMODE_FABRICATE_*) |
| 21 | ToOrder (同上) | 27 | **建筑/铁路建造模式** (CONSTRUCTION_MAPMODE_*; 「模式≠27」拖拽门语义: 建造下不记拖拽锚) |
| 18/19 | **征募部署选区** (DEPLOYMENT_SELECT_AREA) | 29/30 | OperationSelectTarget / 情报账本 |

模式按钮 gfx 键名对: sub_140E02FA0 (selected) / sub_140E026B0 (deselected) — 签名 (out std::string*, int mode_id), 返回 out; mode<40 常量串 `GFX_mapmode_buttons_(de)selected_small` (selected size 34 / deselected size 36, cap 47); **自定义越界 (mode−40) ≥ 库计数 → B51 断言 "invalid_map_mode" (mapmodemanager.cpp:4191 selected, 闩 byte_14333CFC6 / :4211 deselected, 闩 byte_14333CFC7) 但非致命, 落同常量串兜底**; 有效自定义 = 库 getter **sub_14039E240** (返回 §4.35.15 库单例 qword_14332F040 对象) → `*(*(mgr+40) + 8×(mode−40)) + 232` 取名串 → 前缀 `GFX_mapmode_buttons_(de)selected_small_` + 名 append (库 {数组@+40, 计数@+52}, 条目 8B/项, +232 名 — 与 §4.35.15 item+232 名互证)。调用者 = CMapModesInterface 族 (§4.30 +552 件) + 前端 setup 界面 (frontendgamesetupview)。

模式切换总派发 sub_140E17F30(mgr, newMode, force, resetDrawTool) 逐模式配置表 (GBMan 选择槽 {A,B} → sub_140F3B090(组,值) 写图层 +116 并置脏 → 图标重建类型 sub_140E18DF0 (0 全清/1 逐州建筑/2 逐国/3-13 各异) → 双页号):

| mode | {A,B} | F3B090 | 图标类型 | 页 B | 页 A | 备注 |
|---|---|---|---|---|---|---|
| −1 | {−1,−1} | — | 0 | 7 | 7 | |
| 0 DEFAULT | {5,0} | (1,0) | 0 | 0 | 7 | |
| 1/32 STRATEGIC_AIR | {5,−1} | — | 13 | 3 | 3 | 族旗 dword_14338AA14 = 2 |
| 2 STRATEGIC_NAVY | {5,0} | (1,0) | 13 | 3 | 3 | |
| 3 OPERATIVES | {0,10} | (0,0) | 0 | 0 | 2 | |
| 4 STATES | {2,0} | (0,0)(1,0) | 0 | 0 | 2 | 图层脏字节 db+74 |
| 5 SUPPLY | {4,3} | (0,0) | 0 | 0 | 7 | 另两图层重建 sub_140F33D50(db,4/3) |
| 6 RESISTANCE | {0,12} | (0,0)(1,0) | 12 | 0 | 7 | 脏字节 db+84 |
| 7 COMPLIANCE | {0,12} | (0,0)(1,1) | 12 | 0 | 7 | 同上 |
| 8 RESOURCES | {0,−1} | (0,0) | 5 | 0 | 7 | |
| 9 DIPLOMACY | {1,−1} | — | 0 | 0 | 2 | 图层 0 +80/+76 ← DIPLOMACY define 对; db+73 |
| 10 FACTIONS | {0,−1} | (0,1) | 0 | 6 | 6 | |
| 11 PLAYERS | {0,−1} | (0,2) | 0 | 5 | 5 | |
| 12 INFRASTRUCTURE | {7,0} | (1,0) | 0 | 0 | 2 | |
| 13 MANPOWER | {8,0} | (1,0) | 0 | 0 | 2 | 脏字节 db+80 |
| 14 IDEOLOGY | {0,−1} | (0,3) | 0 | 0 | 2 | |
| 15 TERRAIN | {9,0} | (1,0) | 0 | 0 | 2 | |
| 16/38 RAIDS | {0,−1} | (0,0) | 0 | 0 | 0 | |
| 17 | {0,5} | (0,0) | 0 | 3 | 3 | |
| 18 | {0,−1} | (0,0) | 4 | 0 | 2 | 部署选区 |
| 19 | {0,−1} | (0,0) | 3 | 0 | 2 | 同上 |
| 20/21 MMD 族 | {0,−1} | (0,0) | 6 | 0 | 2 | |
| 22 战役计划 | {0,19} | — | 8 | 1 | 2 | 脏字节 db+91; §4.30 主填充→模式 22 落点 |
| 23 造宣称 | {1,−1} | — | 9 | 0 | 2 | 图层 0 define 对同模式 9 |
| 24 | {−1,−1} | — | 10 | 7 | 4 | |
| 25 | {2,−1} | (0,0) | 10 | 2 | 7 | |
| 26 | {5,−1} | — | 10 | 3 | 3 | |
| 27 建造 | {6,−1} | — | 1 | 0 | 2 | 图标 1 = 逐州建筑图标 (sub_140E161C0) |
| 28 DEFAULT | {0,−1} | (0,4) | 0 | 0 | 7 | |
| 29 OpSelectTarget | {0,−1} | (0,0) | 7 | 0 | 2 | |
| 30 情报账本 | {1,11} | — | 0 | 0 | 2 | 图层 11 脏字节 (+83); DIPLOMACY_ON_INTEL_LEDGER define 对 |
| 31 | {0,13} | (0,0)(1,0) | 0 | 0 | 2 | 脏字节 db+85 |
| 33 | {14,−1} | (1,0) | 0 | 0 | 2 | 脏字节 db+86 |
| 34 | {17,−1} | (1,0) | 0 | 0 | 2 | db+89 |
| 35 | {18,−1} | (1,0) | 0 | 0 | 2 | db+90 |
| 36 | {20,−1} | — | 5 | 3 | 3 | db+92 |
| 37 | {21,−1} | — | — | 3 | 3 | db+93 |
| 39 | {22,0} | — | 0 | 3 | 3 | db+94 |
| ≥40 | 脚本自带 | — | 按 +264 映射 {1→0, 2→2, 3→6, 4→5, 默认 7} | — | — | mgr+280 = 库条目, 装载 sub_140AAE2F0 |

default 分支: 40 ≤ mode < 库计数走脚本模式装载; 越界断言 "invalid map mode" (mapmodemanager.cpp:1154)。尾调 sub_140E16D10 = 33 B 逐模式图例/色阶配置拼装 → sub_14163F8D0 发布到全局块 xmmword_14338A9F0/xmmword_14338AA00/word_14338AA10 + dword_14338AA14 族旗 (模式 1/32 → 2, 查表族 → 1/2, 其余 0)。

省悬浮 tooltip 构建器 **sub_140E05340** (3488 行; 上游 sub_140E7CF80; 定案) 三通道互斥: ① mode ≥40 → sub_140AAF060 委派脚本模式自带 tooltip; ② 模式实例 (+16 shared_ptr) 非空 → 实例 vtable[9](buf, prov, 0) 追加 (交互模式 20/21/29 通道); ③ switch(mode) 内建体覆盖 {3 operatives, 5 supply, 6/7 resistance·compliance, 8 resources (ExtraResource 关系单侧缺失断言 mapmodemanager.cpp:3639), 9 diplomacy ((owner)−(subject) + 敌/友/阵营/舆论好坏阈 dword_143334F68/dword_143335018), 12 infrastructure (州 BuildingStatus 条目 +64 等级), 13 manpower (州+2104), 14 ideology, 15 terrain, 18/19 部署选区, 22 battle plan, 23 造宣称五态, 27 建造全套 CONSTRUCTION_MAPMODE_*, 30 intel (sub_140E004E0)}; 0/4/32 走 PROVINCE_CLICK_VIEW 公共块 (PING/点击切换国 tooltip); +128 门或 debugFlag → DEBUG 省份转储块 (Province/Controller Area/State ID/…/Weather 全字段)。

配套单例/门旗: qword_143339E48 = **CMapModeDispatcher** (+8 = CMapModeManager\*; sub_140A66DE0 实名 OnMapModeChange, mapmodedispatcher.cpp:238), 模式设置入口族 sub_140A66{BF0..7750} ×13; byte_1435E1B52 (断言总门) 与 byte_1435E1B51 (E028C0 专用) 两旗勿混; byte_14332EC69 = DEBUG_CLICK_SWITCH_COUNTRY / byte_14332F63D = 外交态度 dump 调试旗。

#### 4.30.39 CPanelController (左右面板控制器; ctor sub_142061510; 176B; 通用控件, 现见空军重组窗)

Reorg 左右面板; 无自有 RTTI; 断言 panel_controller.cpp :103 (LEFT) / :118 (RIGHT);
OnOpen malloc×2 (+4320=side0 / +4328=side1), OnClose sub_142061960 销毁;
填充 = sub_142061E90 (**左面板**, 平铺池迭代 — 池 = win+4024 {data@+32, count@+44}, 类别过滤 = 行原型+4336 == −1 ∥ == sub_140C95880(def+1240)) / sub_142061CA0 (**右面板**, 按机组分组迭代 — 组数组 {data@*a2, count@+12}, 组跨距 80, 组内翼数组 {data@+32, count@+44}; 建行后 sub_14205CB30 组内回写 (语义推定); 尾按 *(win+117)&8 门经 win+128 对象 vtable[7] 刷目标控件)。
两面板共用内层循环: 翼条目 16B {def@+0, 数量@+8}, 有效性门 sub_140C97430(def+1008), 数量门 ≥100000 (1e-5 定点), 部署过滤三元组 (a3+104 非空直放 ∥ tag 解析 + sub_140C95730(def) & 0x100000 == 0 ∥ def+1000 旗), 建行 sub_142061A70。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | 窗回指 | |
| +8 | uint8 | _Side | 0=LEFT, 1=RIGHT |
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
| +8344 | CTextBufferObserverGlue | {vtable, self@+8352}（cb sub_141825320） |
| +8520 | CCheckBoxObserverGlue | {vtable, self@+8528}（cb sub_141824BF0） |
| +8632 | — | （SetupDerived 区） |
| +8640 | — | （SetupDerived 区） |
| +8648 | — | （SetupDerived 区） |
| +8656 | MSVC 串 | cap@+8680=15 |

> 主vtable槽：[0] dtor sub_141822BC0 / [14] SetupDerived sub_141825EF0；rebuild = sub_141825570（SetupDerived 内 `if(a1[1031])`）；create_faction 后续 lambda = sub_141584EC0。sizeof 0x21F0=8688 恰合。
> **兄弟 CNewFactionWindow**（同槽替身，ctor 0x141822830）：+104/+1472 按钮胶水（sub_140B77E10）、+2840/+2848=0、**+2856 CCheckBoxObserverGlue\<CNewFactionWindow\> {vtable, self@+2864, cb@+2872 = sub_141825530}**、+2880..+2935 清零；槽 [4] 绑定 0x141827200 / [5] 复位 0x141823490 / **[6] 模板填充 0x1418282B0** / [7] 清选中 0x141825560。CLegacyCreateFactionWindow ctor = 0x141822010。

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

> **contribution 式（清偿定案）**: 提交门 = `(qword_143333C88 + member+120) ≥ qword_143333BD8 × 请求量`；运行时实测两全局 = 25000000 / 10000（即请求 ≤ 2500 + contribution/10000）。两全局 defines 名：**qword_143333C88 = NFactions::FACTION_CONTRIBUTION_DEBT_LIMIT**（定义件 250，注册点 dump ）/ **qword_143333BD8 = NFactions::FACTION_MANPOWER_RECIEVE_CONTRIBUTION_SCALAR**（定义件 0.1，注册点 Paradox 原拼写 RECIEVE）。

#### 4.30.43 goal/rule 过滤窗口 (CChangeGoalWindow / change_rule_window)

| 窗口 | 偏移 | 语义 |
|---|---|---|
| CChangeGoalWindow | +1664 | 槽 idx (0/1/2 = short/medium/long_term; populate sub_141C08C40 逐槽建 CFilterGoalItem) |
| CChangeGoalWindow | +1668 | 激活 goal 过滤 token (toggle sub_141F13DC0; 重选 357=none 重置; tooltip `<goal名>`_FACTION_GOAL_FILTER) |
| change_rule_window | +2848 | 当前选中规则 token (357=none 门显过滤行) |
| change_rule_window | +2896 | 激活规则过滤 token (populate sub_141C0D680, cpp:83 "show_filter_offset" 断言; GFX 精灵名 `<rule名>`_filter (SetGfx vtable+728 + SetFrame vtable+176 选中帧 2/未选 1)) |

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
| +2704 | 池化条目 数组 | 池化条目 {data@win+2704, top@win+2716} (24B 容器, 非多态元 — 无 vtable 装配) |
| +2728 | 匿名结构 ({tag,count}) 向量 | {tag,count} 请求表 (count@win+2740; 读 sub_141D056D0 / 写 sub_141D06390) |

CRequestExpeditionariesWindowCountryEntry (vtable 0x142A68158, sizeof 0x588B, ctor sub_141D05160): item+40 = CCountry* 裸指针 (非 idpair, 池复用直写)。 (窗主类 RTTI 实名 CDiplomacyRequestExpeditionaryForcesController)

| 字段 | 消费点 | 用途 |
|---|---|---|
| cc+8 / cc+16 | 条目直读 | tag / 国名 |
| cc+552 CCountryAI | 可供谓词 sub_141D05EA0 → ai vtable[128]; accept 意愿 sub_141D05D10 → sub_1402AA9A0 | 可供/意愿判定 |
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

#### 4.30.46 CInGameUpdateableInterface 注册者全景

**七层容器定案**: mgr = **CInGameInterface (idler+1720, malloc 0x4E0)** 持 7 个
vector — 年@+0 / 6月@+24 / 月@+48 / 周@+72 / 日@+96 / 时@+120 / 帧@+144,
每层对应派发函数 (sub_140B68D90/D90→682A0 族)。门语义: **月/周/日三层派发
与 [6] 一样过 vtable[8] IsOpenAndVisible 门**; 年/6月/帧三层无门。**[2] 槽 = 月
==5 (0-based) = 6 月** (月份计算器 sub_140177650 返回 0-based, 平年 365 模
天数表 PE 直读验证)。

注册者全表 (49 类, 定案): 25 个直接注册点 (CTopBar 0x17 帧时日月 /
CInGameClock 帧 / CArmyDivisionStatsView 时 / CAchievementsView 日 等) +
CCountryView 基 ctor 25 个派生调用全定类定掩码。**mgr+200..+376 = 23 国家
视图固定槽** (装配函数 sub_140B614C0 逐槽构造: StateView 槽 0 →
FactionPingView 槽 22; 消费 = 换国主 vtable[6] 全刷 + 帧尾脏标 Repopulate)。
三层空置 (年/6月/周无任何注册者 = 引擎保留档位)。掩码 0 语义: 12 类掩码 0
注册者 (CConfirmSaveGame / CTacticsListView×3 等) 永不进节拍层 (无运行期改
掩码通道)。**STickUpdater = 唯一手写注册** (CEquipmentUpgradeDesignerWindow
ctor 掩码 0 后手动 push 帧层, dtor 手动摘除)。六节拍槽与 §4.2.4 步骤 15
(sub_1401DD370 内联分发) 全链吻合。⚠ CCountryView 主表 [4] 注记「退订
sub_141236280」实为「Repopulate sub_141236980」(sub_141237840 实调后者)。

**mgr+408..+704 直属固定槽全景 (探针枚举定案, 35 槽)**: +408 CStrategicAirView /
+416 CWorldTensionPopUpWindow / +424 CBuildingRosterWindow / +440
CTheatreSelector / +448 CLeaderGroupView / +456 CFleetsBottomBar / +464
COperativeBottomBar / +472 CArmiesView / +480 CNaviesView / +488 COperativeView /
+496 CNavalCombatView / +504 CLandCombatView / +512
NAirSelectionUI::CAirSelectionView / +520 NRaids::NUi::CRaidGuiManager / +536
CInGameMenu / +544 CAchievementsView / +552 CMapModesInterface / +560
CMinimapInterface / +568 CInGameClock / +576 CPeaceConferenceWindow / +592
CDivisionDesignerView / +600/+608/+616 CEquipmentDesignerView ×3 (陆/海/空三
设计器变体) / +624 CWarOverView / +640 CBattlePlansTools / +648
CNavalCombatResultsWindow / +656 CMusicPlayerView / +664 CHotJoinWindow / +672
CCombatLogView / +680 CGarrisonLogView / +688 CArmyLeaderTraitWindow / +696
CNavyLeaderTraitWindow / +704 CInsigniaSelectionWindow; +528 一槽类名未名
(vtable 0x1429FFC68)。

#### 4.30.47 CInGameInterfaceHandler (全 GUI 聚合根; 1248B=0x4E0, CInGameIdler ctor malloc 直证存 +1720; **无主vtable** — ctor/dtor 无 vftable 写入, 纯聚合根 dtor 直调; ctor sub_140B614C0 真实范围 0x1F86B = 全视图装配点; dtor sub_140B63730; 全量 Reload sub_140B6B1A0; **清空复位 = sub_140B64CF0** (InitData/会话重建路调用, 其 10 件直调下游全 GUI 族 — 装备设计器视图清空 sub_14177E0C0 即其一体))

GUI reader 从根定位任意窗的唯一访问路径表 (66 个堆分配子对象全数定类, 70 次 malloc − 4 次窗名串临时分配, 逐槽「malloc 尺寸 ↔ 类名」配对):

| 偏移 | 类型 (视图类) | 尺寸 / ctor / 备注 | 置信 |
|---|---|---|---|
| +200 | CCountryStateView | 0x1108 (4360) ; sub_141744CB0 | 定案 |
| +208 | CCountryNavalRegionView | 0x1B08 (6920) ; sub_141734530 | 定案 |
| +216 | CCountryProductionLineView | 0x5C80 (23680) ; sub_141738090 | 定案 |
| +224 | CCountryDecisionView | 0x6B0 (1712) ; sub_141725E30 | 定案 |
| +232 | CCountryIntelligenceAgencyView | 0x39A0 (14752) ; sub_140F26DD0 | 定案 |
| +240 | CCountryTechnologyView | 0x10E0 (4320) ; sub_1415F6FB0 | 定案 |
| +248 | CCountryTechTreeView（科技树） | 0x1AB0 (6832) ; sub_1413D38F0(…,6,"countrytechtreeview") ; id6 | 定案 |
| +256 | CCountryTechTreeView（学说树复用） | 0x1AB0 (6832) ; sub_1413D38F0(…,7,"countrydoctrineview") ; id7 | 高置信 |
| +264 | NDoctrines::CCountryDoctrineView | 0xAF8 (2808) ; sub_14163AAE0(…,8,"country_doctrine_view") ; id8 | 定案 |
| +272 | CCountryDiplomacyView | 0x4510 (17680) ; sub_1415E27F0 | 定案 |
| +280 | NInternationalMarket::CCountryInternationalMarketView | 0x15D8 (5608) ; sub_1417B8FE0 | 定案 |
| +288 | CCountryOccupationView | 0x2EC8 (11976) ; sub_141559420 | 定案 |
| +296 | CCountryPoliticsView | 0x7BE0 (31680) ; sub_14157C600 | 定案 |
| +304 | CNationalFocusView | 0x22A0 (8864) ; sub_14137FF20 | 定案 |
| +312 | CCountryDeploymentView | 0x6C0 (1728) ; sub_14172A220(ptr, gui, a1, \*(a1+592)) ; 第四参=师设计器回指 | 定案 |
| +320 | CCountryTradeView | 0x1F38 (7992) ; sub_1415FBEC0 | 定案 |
| +328 | CCountryLogisticsView | 0x1AF8 (6904) ; sub_14172D950 | 定案 |
| +336 | CCountryConstructionsView | 0x1590 (5520) ; sub_1417110E0 | 定案 |
| +344 | CCountryMilitaryOverview | 0x35B0 (13744) ; sub_141703F80 | 定案 |
| +352 | CCountryArmyOfficerCorpView | 0x2720 (10016) ; sub_1416F62F0；对象 +9984 = \*(a1+592) ; 内嵌 CDivisionCommanderWindow / CShipCaptainWindow | 定案 |
| +360 | NFactions::NUi::CCountryFactionView | 0x54F0 (21744) ; sub_141468CE0 | 定案 |
| +368 | NFactions::NUi::CFactionSetupWindow | 0x21F0 (8688) ; sub_141821CD0 | 定案 |
| +376 | NFactions::NUi::CFactionPingView | 0x588 (1416) ; sub_141237180(基)+直写 vftable ; "factionpingview" id0；+1408 u8=0 | 定案 |
| +392 | CTopBar | 0x99A0 (39328) ; sub_14188FDC0（内含 CTooltipHandler 基） ; vftable@4906206 | 定案 |
| +400 | CFindView | 0x1048 (4168) ; sub_1417A3650 ; vftable@514180 | 定案 |
| +408 | CStrategicAirView | 0x2F70 (12144) ; sub_14187A6C0 ; vftable@4334686 | 定案 |
| +416 | CWorldTensionPopUpWindow | 0x1A28 (6696) ; sub_1418B23A0 ; vftable@6236143 | 定案 |
| +424 | CBuildingRosterWindow | 0x5C8 (1480) ; sub_1415C1210 ; vftable@3441308 | 定案 |
| +432 | （懒填充槽, 需活体 — 静态写点确证全无, 探针: 面板全开后 read_u64(h+432) 定类或 dr_watch(h+432) 捕懒创建者) | ctor 仅置 0（与 +584/+744/+752 同批零跑），dtor 有释放；全库静态写点未见 ; | 定案 |
| +440 | CTheatreSelector | 0x758 (1880) ; sub_141889D30 ; vftable@7539278 | 定案 |
| +448 | CLeaderGroupView | 0xD0 (208) ; sub_1417BBDA0 ; vftable@7678408 | 定案 |
| +456 | CFleetsBottomBar | 0xB00 (2816) ; sub_1417A4F10 ; vftable@5337144 | 定案 |
| +464 | COperativeBottomBar | 0xB18 (2840) ; sub_141832080 ; vftable@7329441 | 定案 |
| +472 | CArmiesView | 0x668 (1640) ; sub_141692440 ; vftable@347013 | 定案 |
| +480 | CNaviesView | 0x90B8 (37048) ; sub_1418029A0 ; vftable@3930594 | 定案 |
| +488 | COperativeView | 0x68 (104) ; sub_141834770 ; vftable@5667432 | 定案 |
| +496 | CNavalCombatView | 0xF30 (3888) ; sub_1417E1FD0 ; vftable@5287729 | 定案 |
| +504 | CLandCombatView | 0xAF8 (2808) ; sub_1415CD790 ; vftable@2251631 | 定案 |
| +512 | NAirSelectionUI::CAirSelectionView | 0xA8 (168) ; sub_1416881C0 ; vftable@1554248 | 定案 |
| +520 | NRaids::NUi::CRaidGuiManager | 0x1858 (6232) ; sub_1412983A0 ; vftable@414739 | 定案 |
| +528 | NFactions::NUi::CFactionUiManager | 0x90 (144) ; sub_14179F670 ; vftable@7716524 | 定案 |
| +536 | CInGameMenu | 0x32E0 (13024) ; sub_1417B2000 ; "ingamemenu" | 定案 |
| +544 | CAchievementsView | 0x588 (1416) ; sub_141686020 ; vftable@3416651 | 定案 |
| +552 | CMapModesInterface | 0x2EF0 (12016) ; sub_141572A20 ; "Ingame"（内含 CAllMapModesWindow） | 定案 |
| +560 | CMinimapInterface | 0x1530 (5424) ; sub_1417CB5E0 ; vftable@1080663 | 定案 |
| +568 | CInGameClock | 0x98 (152) ; sub_1417B03F0 ; "clock_window" | 定案 |
| +576 | CPeaceConferenceWindow | 0x5210 (21008) ; sub_14185AE60 ; vftable@7005939 | 定案 |
| +584 | CPlayerLobby | 0x26A8 (9896) ; sub_14186BDA0 ; 惰性：Reload 内判 CServer/CProxyServer（RTTI DynamicCast，判定 、写入 ）后才分配 | 定案 |
| +592 | CDivisionDesignerView | 0x5CC0 (23744) ; sub_1417591C0 ; "countrydivisiondesignerview" | 定案 |
| +600 | CEquipmentDesignerView（EDesignerType 0） | 0x12220 (74272) ; sub_141776C00(…,0,0) ; vftable@1818001 | 定案 |
| +608 | CEquipmentDesignerView（EDesignerType 1） | 0x12220 (74272) ; sub_141776C00(…,1,0) ; | 定案 |
| +616 | CEquipmentDesignerView（EDesignerType 2） | 0x12220 (74272) ; sub_141776C00(…,2,0) ; | 定案 |
| +624 | CWarOverView | 0x5C50 (23632) ; sub_1418A82B0 ; "waroverview_window" | 定案 |
| +632 | CErrorLogIndicator | 0x568 (1384) ; 就地构造（sub_142255FA0 + 直写 vftable） ; "error_log_win"；byte_14332EC69 门控 | 定案 |
| +640 | CBattlePlansTools | 0x8598 (34200) ; sub_1416D7390 ; vftable@4904889 | 定案 |
| +648 | CNavalCombatResultsWindow | 0x13E0 (5088) ; sub_1417D63D0 ; vftable@5263681 | 定案 |
| +656 | CMusicPlayerView | 0x1A70 (6768) ; sub_1417D1D10 ; 内含 CMusicPlaybackListener | 定案 |
| +664 | CHotJoinWindow | 0x590 (1424) ; sub_1417ADCD0 ; vftable@441324 | 定案 |
| +672 | CCombatLogView | 0x578 (1400) ; sub_1416E8680 ; vftable@2494260 | 定案 |
| +680 | CGarrisonLogView | 0x15E8 (5672) ; sub_1417A89C0 ; vftable@7229897 | 定案 |
| +688 | CArmyLeaderTraitWindow | 0x1630 (5680) ; sub_1416D1860；构造后调 sub_1416CDB30 ; vftable@5488547 | 定案 |
| +696 | CNavyLeaderTraitWindow | 0x10B0 (4272) ; sub_14181EF80；构造后调 sub_1416CDB30 ; vftable@2642265 | 定案 |
| +704 | CInsigniaSelectionWindow | 0x758 (1880) ; sub_1417B5AD0 ; vftable@3226005 | 定案 |
| +712 | CScriptedWindowManager | 0xB0 (176) ; sub_140B85530 ; vftable@5356567 | 定案 |
| +720 | CNavalMissionExtension | 0x550 (1360) ; sub_1417CEA60 + 直写 vftable ; vftable 直写@ | 定案 |
| +728 | CBoostIdeologyMissionWindow | 0xB48 (2888) ; sub_1416E36C0 ; vftable@299698 | 定案 |
| +736 | CSlowInterfaceIndicator | 0x58 (88) ; 就地构造 ; "slow_interface_win"；同 byte_14332EC69 门控 | 定案 |

> +1008 = 23 = 国别视图槽计数 (ctor 写常量 / dtor 与 Reload 两处硬编码 23 循环同源互证);
> +584 CPlayerLobby (9896B) 惰性分配 — 仅 Reload 检测到 CServer/CProxyServer 时构造,
> 单机恒空; +1128..+1152 = 四个建筑损毁事件 token (building_bombed/sabotaged/
> collateral/repaired), Reload 末尾重取 = mod token 重排安全; +1100 = CRef 槽;
> 24B 动态数组容器 ×13 形 {data, dword, count@+12, allocator@+16}; +432 = 懒填充
> 槽 (ctor 置 0 / dtor 有释放 / 全库静态写点未见)。书内原 11 项既有锚全部吻合。
#### 4.30.47a CTheatreSelector 选择范围取值器 (theatreselector.cpp; 1 函 = 0x14188AFA0 = CTheatreSelector::[3] — 新收)

取某战区单位列表选择范围 [start, end] (含尾; (this, idx, outStart, outEnd)): idx > +1744 (战区计数界) → 读缓存范围 +1748/+1752, 落界回吐该对否则双 −1; idx ≤ +1744 → 按 +1688 战区模式三分流: **1 army** — start = sub_141E6A840(战区指针 = *(this+24)+416+8×idx), 链 sub_140D0D950→sub_1401F6EA0→sub_140CDCC80 取计数表+12, end = 计数+start−1, 空范围双 −1; **2 navy** — start = 0, end = *(u32*)(this+100)−1; **3 air** — start = *(u32*)(战区+56), end = *(u32*)(this+1596); 其他 → 断言 theatreselector.cpp:820 "Theatre mode is neither army, navy nor air"。

CTheatreSelector 布局增量 (1880B, 挂载见 §4.30.47 +440): **+24 → +416 = 战区指针数组 (8B 元)** / +100 = navy 全局范围末 (count−1) / +1596 = air 全局范围末 / +1688 = 战区模式枚举 (1 army / 2 navy / 3 air) / +1744 = 战区计数界 / +1748/+1752 = 缓存选择范围 [start u32, end u32]。


#### 4.30.48 地图下令输入链 (锚 = sub_140DCEFD0; CInGameIdler 输入事件消费, 1034 行)

签名 (idler, u8 鼠标按住旗); 唯一调用点 = Idle 巨函 sub_140DD3A50 (帧内点击善后后、
debug rightclickmenu 门 byte_14332EC69 前)。idler 槽: +1280 输入管理器 (vtable[+192] 光标) /
+1288 键盘态 / +1336 选择集 / +1720 前台窗口栈 / +1764 拖拽锚 / +1772/1773/1734 待决旗 /
+1880 输入事件链 (next@+144, +128 已消费旗; 类型 1=键盘 3/4=鼠标, 载荷+4 动作 1 按下 2 释放)。
三段结构 (定案):

| 段 | 动作 |
|---|---|
| 键盘事件 | 控制台开关键 53 → 懒构造 CConsoleCmdManager (sub_1424B4C40, 224B 三 std::function 谓词门 sub_1424B4BD0, 全局 qword_1435E1A80) 后开面板 (关 = sub_142081040); 键码谓词三件 = sub_142272FA0 键码版 / sub_142272F40 字符版 / sub_142273160 数字版; 面板聚焦件 (全局 qword_14344A590, 160B; +124 激活旗) 激活时 UP/DOWN = 历史 ↑/↓ (sub_142081C30/sub_1420805C0; 键码 1073741906/1073741905) 与 PAGEUP/PAGEDOWN = 值 ∓/+ 步进 (sub_1420811F0/1140, 1e-5 定点; 1073741899/1073741902); 字符键 = 聚焦件开 (sub_1420812A0); 数字键 (sub_142272050 取 0..9) → sub_140DDB280 存控制组 (§4.33 10285); 'h' → sub_140DDCAB0 取消移动 (10415); BACKSPACE/HOME → 镜头聚焦首都 sub_141262730 (双路: 州表 + tag 回退; 相机 z 修正 0.3×(qword_14332F408+576) 待 PE 验算); PAUSE 类键 72 → idler vtable[71](1); **ESC (27) 旁路**: 未消费事件落 LABEL_151 二次分派 — 选择非空清空 (sub_1402A0110 全清 + sub_140B64FE0/FF0 关当前视图 + sub_142275B50 标记消费) / 海军移动预览 → 栈上 CDeleteOrderGroupCommand (ctor sub_141837380, 48B) 入队 / 否则 sub_140B69010 单机取消链 (RTTI 排除 CNetworkServer/CProxyServer) |
| 鼠标释放 (右键下令主路) | ① 拾取 sub_140B56460 = 反投影 sub_140B53890 (三拾取面射线步进取最近点, 平面交兜底) + 省 id 纹理 *(handler+40)+2096 {宽@48, 高@52, u16 数据@24} → gs vtable[+8] 取省对象; ② 海军分流 sub_141816E80 (naviesview.cpp:162 混编断言): handler+480 态 +257 海军旗下把选择集舰队 (type 11 ∪ type 1 父舰队去重) 重指派点中省并**吞右键**; ③ 收集 sub_140B54210 (三拾取面命中单位, 同省叠队环形轮选; graphicalmap.cpp:1036 断言) + 清省选择 sub_1402A0100 + 下令允许门 sub_140F41710 (UI 阻塞/修饰键/铁路炮工具组合); ④ 点中省 +392 有单位且 (选择计数 == 0 或首元素类型 ∉ {≤1, 13, 11, 2}, 判定件 sub_14072B2D0/首元素取件 sub_140BC30D0) → previous 模式保存 sub_140E16B80 + 切模式 9 → **sub_140B6C390 = CInGameInterfaceHandler::SelectProvince** (lambda 符号串直证) 按地图模式分派; ⑤ 三路发射: 空军翼选中 → sub_1415B72C0 (12222) / 铁路炮工具 → sub_140E8B230 (19872) / 默认 **sub_140BC3190** 遍历选择集逐成员 vtable[+32](成员, 省, Ctrl, Shift) 下令 = 真实地面移动令发射点 (下游寻路/命令构造 = §4.14/§4.18 域)。左键按下旁支: 修饰键 (iface+1288 vtable[7]/[6]/[5]) ∧ 攻击 ping 粘锁 (门 sub_1417CDA00 / is_offensive 解析 sub_1417CD970 / 发后清锁 sub_1417CC590; 锁位 = iface+560 件 +5242/+5243) → 反投影 + 高度采样 sub_140A61480 (qword_143339D28+376 表 u8×0.1) → CSendPingCommand (14350); 无 ping 则记拖拽锚 (+1764, +1773/+1772 门 = sub_140E137B0 模式≠27, +1734 = 1) + sub_1402A0100 清选择集中省 |
| 帧尾判定 (按住 ∧ 待决) | 位移 ≥ 1.0 且框宽+高 ≥ 30.0 px → **sub_140DC9860 框选** (8 角反投影 → 6 平面视锥 → 按类型优先级 sub_140B73340 逐类查询 → CanAdd 过滤 → Add); 否则单击: 收集 → Ctrl 切换选 (Remove 反选 / CanAdd 混选门) → type 4 省去重门 (gs+1316 缓存省比对) → Clear → 视图接纳 sub_140B6AC80 (type 6→+528 表 / type 4→+520 表; 模式 1 仅放行 type 0/1/13) → 按类型遍历成员 (0: obj+496→+272/+284 / 1: +248/+260 / 13: +224/+236 滤 13) 逐个 sub_140DDFA60 (属主+组门) → Add |

**输入事件对象槽形** (idler+1880 链节点, 首次定案): +0/+8/+28 = 键码/索引(−1 无效)/屏蔽旗;
+72/+76 = 指针类 (3=左键 4=右键)/相位 (1=press 2=release); +124 = 设备类型 (1=键盘 0=鼠标);
+128 = 已消费旗; +144 = next。访问器族五件 = sub_142275B30/+142275B50/+140D11940/+14139E9B0/
+14139E9A0 (全语料 100-234 处高频)。选择集补: +68 = 延迟摘除旗。地图相机 (idler vtable[37] 取件):
+1664..+1684 当前位/速 / +1688..+1708 双目标三元组 / +1704 固定 10.0f / +1712 飞行中旗
(sub_141261320/141262730 体直证)。CCountry 补: +4120 = 首都州 id / +184→+176 = 首都坐标 {x,z}。

CInGameInterfaceHandler 读数补: +192 当前省 id / +200 起按模式 8B 跨距处理器表 / +480
navies view 态 (+257 海军旗) / +768 选中省 refid 表 {计数@+780} / +1008 当前地图模式。
§4.33 四行 (10285/14350/19872/10415/12222) 的「上游 = sub_140DCEFD0」经锚体逐点核实为真。

选择集操作件 (体直证): 包含查询 = sub_140BC2D50 (沿 +48 链表找 `*node == a2`,
命中即真; 消费 = Shift 点选切换, 命中 → sub_140BC2D80 Remove 反选); 按类型摘除 =
sub_140BC2EB0 (遍历 +48 链, 元素 +8==a2 者: +68 延迟旗置位时 node+24 标记, 否则
即摘 — 双向链摘; 实参 = 省类型); 关界面视图包装对 = sub_140B65430(handler,0,0) /
sub_140B65360 → 65430(handler,1,0) (关视图 0/1, 视图 id 族 = §4.30.29 顶栏视图编号)。

#### 4.30.49 科技树视图运行期 (CCountryTechTreeView 重建/网格盒/连线/页签链; countrytechtreeview.cpp; 8 函数闭环)

簇清册 (8/8 函体内含全路径 assert 锚; §4.30.47 表 +248/+256 视图槽的运行期行为层;
互证 = §4.31.35 项件锚):

| VA | 行数 | 身份 |
|---|---|---|
| 0x1413D6490 | 1034 | 单文件夹科技项重建主函 (事务内建 CTechnologyTreeTechItem 双容器 + 连线 + 40B 记录 + xor 待绑表 flush) |
| 0x1413D9990 | 387 | 全文件夹网格盒/连线重建 (按模式 × folder+204 过滤; 不构造 tech item) |
| 0x1413D8480 | 346 | 文件夹页签 header/tooltip 文本构建 (this = view+40 内层基) |
| 0x1413DBEF0 | 275 | 文件夹页签切换处理 (学说 remap 双全局表; 默认切换路径) |
| 0x1413D5E30 | 160 | 互斥线路径递归绘制 (拐角放 xor 件) |
| 0x1413D61A0 | 138 | 普通依赖线路径绘制 (与上同构、无 xor 角件) |
| 0x1413DE110 | 132 | 初始/允许文件夹选择解析 (四级回退 → 派发页签切换) |
| 0x1413D8140 | 92 | 科技网格盒查找 (**网格盒记录数组** {data@+920, count@+932}, 元素跨距 80B {+40 名 std::string / +72 folder id dword}; 匹配 = folder id (a3+40) + 名 stricmp (a3+8) 双等; 命中经宿主**虚表槽[54]** 取盒对象 + sub_14225D3C0 有效性; 多匹配报错 :746 "Found multiple potential grid boxes for tech %s (%s and %s)"; 科技名取 a2+8 虚表槽[1]) |

**模式与视图偏移面** (定案): view+6820 = 当前模式 id (6 = 科技树 / 7 = 学说树,
学说视图 countrydoctrineview 复用同类), 全簇按 `mode==6 → folder+204 须清` /
`mode==7 → 须置` 过滤 = **idb 文件夹对象 +204 = 学说文件夹旗** (三消费点同语义)。
idb 文件夹对象 (sub_140ACBE80 按库内小整数索引取) 消费形态: +8 名字串 / +40 int id /
+56 启用旗 / +64 tech 指针数组 +76 计数 / +88 qword 数组 (推定 = 每科技摆位坐标,
与 +64 同下标) / +204 学说旗。视图增补偏移:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +1456 | 工厂槽 | 线段单元工厂 (sub_1413D2E80) |
| +2784 | 40B 项容器 | 本文件夹项容器 (populate 第 5 参选择式之一) |
| +4072 | 40B 项容器 | 他文件夹项容器 (按 folder 匹配旗分流, 与 +2784 成对) |
| +6648 | 页数组 | 页索引基 (存 idx−1) |
| +6672 | 页签数组 | 页签文本 (页签切换 remap 查询输入) |
| +6684 | 计数 | 页计数 (选择解析界检) |
| +6696 | 16B 待绑表 {xor件, 盒} | xor 拐角件 GetOrCreate 查重表 (键 = 盒 + 件+32 坐标) |
| +6720 | 列表 | 可弃项列表 (旧项清理倒序 swap-remove) |
| +6732 | 计数 | 可弃项列表计数 |
| +6744..+6756 / +6768..+6780 | 40B 记录向量 ×2 | 元素 {tech, 盒句柄, item, folder+88[i], folder}, 按 sub_140AD1E90 分流 |
| +6792 | 国家上次文件夹存储 | 文件夹选择回退第一级 |
| +6800 | int | 当前页 |
| +6816 | int | tag 覆盖 (>0 时优先于 gs+1312/1316 作当前国) |
| +6820 | int | 当前模式 id (6/7) |

**网格盒体系** (定案): CTechnology 模板 +920 数组 / +932 计数 = **每科技网格盒描述表**
(元素 80B: +40 名字串 / +72 文件夹 id; 重复双盒命中 = :746 断言)。盒句柄 (8B) FNV-1a
全 8 字节 → sub_1413D2510 哈希表查节点; 节点 +16 起内嵌 CPdxRobinHoodTable (+8 数据 /
+16 计数 / +20 mask / +24 extra; 24B 槽 {+4 占用 / +8 key u32 / +16 value qword}),
节点 +28 = float 缩放, +380 = 树层索引。细分深度 = `ceil(log2(max(1.9, 512.0/zoom)+1))`,
`1 << depth > mask+1` 时 sub_1413DA1B0 扩容 — **该 helper = CPdxRobinHoodTable::Rehash**
(pdx_robin_hood_table.h:579 断言直证, 合法域 2..30)。

**连线体系** (定案): 双入口 sub_1413D61A0 (普通, :945) / sub_1413D5E30 (互斥, :1018);
sub_140AD0440 取路径坐标对 → sub_140AC7CD0 二叉查 48B 子条目 (+40 = 子路径 map) 递归,
先横走到转折 x (条目+48) 再竖走到转折 y (条目+52)。四向段填充 helper = sub_1413D5AF0
(x+) / sub_1413D57B0 (x−) / sub_1413D5460 (y+) / sub_1413D7780 (y−) (方向由增减循环位
判定, 高置信)。段单元以 packed 键 `y + (x<<16)` (乘子 73244475) 存盒内嵌 RH 表; 未命中
经 view+1456 工厂建单元 → sub_141BD5E80 配置 → sub_1402DE9B0(盒, 单元, &坐标, 0, 1)
摆位 (统一摆位原语, 项/xor 件共用)。互斥拐角件 GetOrCreate = sub_1413D4DD0 (64B,
构造 sub_141BD0540, 定向 sub_141BD0D80 dir 0..3 — §4.31.35 xor 件锚全链互证)。

**项重建主函 sub_1413D6490** (单文件夹全流程, 定案): ① 事务 begin (sub_1422BDC60 取
科技状态对象列表, 逐个清 +404/+428/+352; 尾 sub_1422C4970 提交 + sub_1422C7E50 收尾);
② 逐 tech 构造 216B CTechnologyTreeTechItem (sub_141BD0070) → populate
(sub_141BD6770, 容器 = view+2784/+4072 按匹配旗分流) → 摆位 sub_1402DE9B0; ③ 40B
记录向量双条 (见视图偏移面); ④ 可见门 = tech+1035 置位时须 sub_140ED8F00 为真;
⑤ 进度实参 = sub_141433B30(tag 指针, 国家, tech, folder, 0) 返回 int。科技状态对象
(sub_140ED5080 由国家科技状态取) = +352 名串 / +404 int / +416 子表数组 +428 计数
(高置信)。

**页签切换与文件夹选择** (定案/高置信): 选择解析 sub_1413DE110 四级回退 = ① view+6792
国家上次文件夹 (+48 上次 idx + +56 旗) → ② 实参携带 idx (国别可达门) → ③ view+6800
现值 +1 → ④ 全量扫描 (启用 + 可达 + 模式学说旗过滤) → ⑤ 全败 = 现值 + :1474 错误
(原文拼写 "techonolgy" 即错)。页签切换 sub_1413DBEF0: 页签文本命中**学说 remap 表 1**
(qword_14338A310 基址 / qword_14338A318 计数) 二次命中**表 2** (off_1430B32E0 /
dword_1430B32EC) → token → qword_14332EEA0 token RH 表 (mask@+68/table@+56/extra@+72)
→ qword_14332F698 窗口管理 vtable+184 取**窗口 8** → 设文件夹 (sub_14163AE60) + 刷新;
未命中 remap = 默认切换 (旧页 +165 |= 0x10 → 清项 sub_1413D9580 → 新页复位 + vtable+176
设页 → view+6800 = max(vtable+440(a3), 0))。页签文本 sub_1413D8480: 窗名 − "_tab" 后缀查
folder, 出参两串 = "HEADER"+{KEY} loc 组合 / 名 + 两枚 2 字节字符 0x5411 / 0x2111
(语义未决)。

**跨域原语**: sub_1413D8350(view) = 取当前国 tag 指针 (view+6816 覆盖优先, gs+1312
int > 0 → &gs+1312, else &gs+1316); 同单元不在本簇的近邻 helper (供后续引用) =
sub_1413D2510 (哈希查表) / sub_1413D2790 (哈希插表) / sub_1413D2E80 (线单元工厂) /
sub_1413D9580 (清项) / sub_1413DA1B0 (RH rehash) / sub_1413DD420 (tech 处理);
sub_1413DA920 / sub_1413DD5A0 同编译单元但归命令簇 (科技替换研究/解锁命令的玩家 UI
通道, s4_33 命令域 CSetResearchCommand 系)。

未决: 文件夹网格上下文 (vtable+432 查询) 与树根 (`*(*(view+1392)+1272)`) 的类归属;
行条目 +48 == 100000 (fixed 1e-5 制 1.0) 旗喂线段配置的语义; 全文件夹重建每文件夹
begin 事务但体内无 commit (调用方承担待裁); 0x5411/0x2111 两字符含义; 双 40B 容器
出参完整布局。

#### 4.30.50 事件窗运行期 (CEventWindow 建窗/tick/遥测; eventwindow.cpp 4 函闭环)

清册 (4/4 函体内含 eventwindow.cpp 路径锚): 建窗体 0x14123B0B0 (920) / ctor 0x1412381A0
(438) / CUpdateable::Update 每帧 tick 0x14123C410 (345, +40 基 vtable[1] PE 直证) / 选项遥测
0x141239DC0 (176, tick 与关窗回调两处调用)。

**CEventWindow 全布局 4752B** (定案): 四 CEventScope 槽 +120..+824 / 三
CButtonEventDispatcher +832/+2120/+3408 / 双 CGameDate +4704/+4720 (+4728 值域复用 float
时钟)。**建窗四分派模板** = 按 ev+1060/1054/1053 选 "EventWindow_News/_leader/_Operative/
EventWindow"; Title/正文 ( 富文本转义族) / agency_insignia / options_grid 逐 option
过滤建格, 空格断言 :270 + 兜底 BUTTON_OK (option=NULL); 尾按 settings popup_news(+601)/
popup_events(+602)/popup_minor_events(+603) 决定带暂停显/仅显并根 vtable+600 开窗通知 (vtable+608
关窗成对)。**超时链** (tick): 无效哨兵门 → country+5208 显隐分支 → 0.3s 选项渐次展开
(vtable+648) → gs+1128 ≥ **+4712** 超时自动选首个过 trigger option 构造 CSelectEventOptionCommand
(vtable[9] IsValid 门 → 遥测 → vtable+136 入队; 无 option 则 :463 不投递)。**遥测五重门** = 人类
玩家 ∨ human_ai、scope tag == 玩家 tag、ev+1052 族旗、非特工/军领/hidden/news; 类别
"event_option" {in_game_date, event_id = ev+24 vtable[1] 名串, option_id = opt+376 名串}。
kind4 收件箱条目载荷精化: +0 fire_id / +8 CEvent* / +16 actor tag / +24 scope / +200
immediate / +208 kind。第二断言门 byte_1435E1B51 (:270, 疑 warn 档); 控制台 event 命令
sub_140257E70 = 第二 ctor 调用方。

未决: country+5208 旗语义 / W+296/+472/+648 三空 scope 槽写者 / 主 vtable[1] 身份 / +64 第 4
基类名 / qword_14332F698+8 时钟对象身份。

#### 4.30.51 地图图标运行期四簇对账 (resistancemapicons / mapiconmanagerimpl / mapiconimpl / insigniagraphicsdatabase; 9 函闭环)

簇清册 (体内 cpp 路径锚 9/9 全含; 已收 VA 级登记无, 全部本批新定性):

| 函数 | 行数 | 归因锚 | 定性 |
|---|---|---|---|
| sub_14190A2D0 | 741 | 断言 "unhandled view mode" @ resistancemapicons.cpp:155 | CResistanceComplianceMapIcon (type 20, 208B) 帧级 populate (槽[3] 形态) |
| sub_140B71B50 | 241 | 断言 "Unknown Icon Type. This will result in a CTD" @126 | 图标工厂 (34 case 全 switch) |
| sub_140B72210 | 418 | 同款断言 @232 | Reload/池重建 (槽[2]) |
| sub_140B738F0 | 141 | 断言 "Progress == PROGRESS_LOCAL_COUNT…" @263 | ClearAll (槽[5]; PROGRESS_LOCAL_COUNT = 36) |
| sub_140B73340 | 123 | 断言 "Unsupported type of selectable" @752 / "Unexpected map mode" @784 | 框选/点选按类型组逐层图标查询 |
| sub_1418C67D0 | 784 | 格式化错误日志 "Mapicon on province %d contains nullptr buildingtemplate" @2143 (无中断) | CConstructionInfoMapIcon (case 4, 1600B, 工厂 RTTI 名 "construction_info_mapicon" 直证) populate |
| sub_1418CF8F0 | 153 | 断言 "pAlertIcon" @2900 | 18 槽警报图标数组刷显 helper |
| sub_140A553A0 | 329 | 四错误位点 @254/263/271/280 (格式化错误日志, 无中断) | CInsigniaGraphicsDatabase 全 8 kind 校验 |
| sub_140A56330 | 29 | 断言 "Equipment role icons not supported for this equipment." @205 | kind 4 装备角色徽章查询入口 |

**CResistanceComplianceMapIcon populate** (sub_14190A2D0; icon: +136 CState* 书 ✓ / +144 头部文本件 / +152 列表框宿主 / +160 dword 滚动参数 / +176..+192 行向量四件 / +200 已用行数):

| 机制 | 内容 |
|---|---|
| 门链 | +136 CState* 非空 → 管理器 qword_14332F698 vtable+184 返真 → 当前地图模式 ∈ {6, 7}; 否则一次性断言 @155 |
| 近焦门 | dword_143334C28 (全局阈值) > 相机+404 (距离) 才收集修正行; 远焦仅刷头部 |
| 模式↔名单 | 模式 6 → 头部 loc 全局 qword_143338E68 + cr+528 (resistance_modifiers, count +540) + 占领状态对 +88 名单 (count +100); 模式 7 → qword_143338E80 + cr+552 (compliance_modifiers, count +564) + 占领状态对 +112 (count +124) — §4.30.26 页签行勘误的直证侧 |
| 头部串 | sub_14226E4D0 = 整数→十进制 + `%` 百分比串; 追加控制字节对 {0x13, 0x20} (机内转义族, 推定) → sub_140F32FB0 渐变取色 (§4.35.33a resistance 梯度插值, 输出颜色分量) → sub_1422CB260 SetText |
| 排序 | 修正指针栈数组 (×1.5 扩容) 排序再建行: ≤32 项 sub_140A70630; >32 项缓冲归并 sub_140A70710 (栈 4KB, 超限 malloc, 步长折半节流) |
| 行件 | 56B, RTTI 名 `CResistanceComplianceMapIconModifierEntry`; ctor sub_141909BE0 (名 "resistance_compliance_map_icon_modifier_entry" 经管理器 +1272 工厂); 行+32 = CState* / 行+40 = 修正 def 指针缓存 (变更才刷) / 行+48 "icon" 子件 vtable+824 槽消费 def+80 修正式文本 |
| 列表挂接 | +152 宿主: +384 旗 / +392 idpair 数组 (8B 元) / +368/+372 可视窗 / +404 当前索引; 加行原语 sub_1402DE9B0 (带 a5 去重门, 扫 +416/+428 查重); 滚动定位 sub_1422DF180/DF220 + sub_1422C7E50 |

**工厂 34 case 对象尺寸/ctor 全表** (case = icon type = 层号; 书 §4.30.27 case↔类映射行全互证):

| case | 尺寸 | ctor | case | 尺寸 | ctor |
|---|---|---|---|---|---|
| 0 | 208 | sub_141912C40 (CUnitsStackMapIcon, 基 ctor 带名 "unit_mapicon") | 17 | 152 | sub_1418B9800 (CRadar) |
| 1 | 208 | sub_141912D30 (CUnitsStackMapIcon 系, 带 Group) | 18 | 1224 | sub_1418B96F0 |
| 2 | 192 | sub_1418BA0D0 | 19 | 264 | sub_1418B8BA0 |
| 3 | 224 | sub_1418B9A40 (Resource) | 20 | 208 | sub_141909AD0 (ResistanceCompliance) |
| 4 | 1600 | sub_1418B8970 (CConstructionInfoMapIcon) | 21 | 272 | sub_1418E71C0 |
| 5 | 1520 | sub_1418B8310 | 22 | 392 | sub_1418DF880 (…,22) (IntelLedger) |
| 6 | 1496 | sub_1418B9CB0 | 23 | 392 | sub_1418DFAC0 (IntelLedgerRegion) |
| 7 | 1448 | sub_1418B9080 | 24 | 2760 | sub_1418DC180 (Cryptology) |
| 8 | 1472 | sub_1418ED6C0 (NavalBase) | 25 | 344 | sub_14190BB40 (Scripted) |
| 9 | 1568 | sub_1418F4410 | 26 | 6712 | sub_14190DF80 (SupplyNode) |
| 10 | 1464 | sub_1418B94B0 | 27 | 1528 | sub_1419080F0 |
| 11 | 1528 | sub_1418B9240 | 28 | 144 | sub_14190C9B0 (StateModifier) |
| 12 | 5656 | sub_1418F9C60 | 29 | 11520 | sub_1418EAC60 |
| 13 | 2472 | sub_1418B8510 | 30 | 1472 | sub_1418B9E80 |
| 14 | 216 | sub_1418B8880 (Capital) | 31 | 1496 | sub_1418E9D00 (NavalHQ) |
| 15 | 296 | sub_141904CC0 (Peace) | 32 | 1536 | sub_1418DE5D0 |
| 16 | 1448 | sub_1418B8150 (Adjacency) | 33 | 176 | sub_1418BA060 (StrategicLocation) |

**Reload 池初值表** (层:预建实例数): 0:3 (带层对象) / 1:1 / 2:10 / 3:12 / 4:16 / 5:192 / 6:128 / 7:128 / 8:192 / 9:32 / 10:64 / 11:128 / 12:64 / 13:192 / 14:192 / 15:128 / 16:64 / 17:64 / 18:128 / 19:128 / 20:96 / 21:128 / 22:128 / 23:32 / 24:128 / 25:1 / 26:128 / 27:128 / 28:64 / 29:128 / 30:128 / 31:64 / 32:128 / 33:64 — 合计约 2900 实例 (池重建 = 工厂唯一批量入口; §4.31.45 未决首项部分 resolve: **图标实例创建点 = Reload 池预建, 非 Update ICF**; target 写入点仍未决, populate 只读 +136)。

**ClearAll (sub_140B738F0)**: 逐层表②: vtable[7] ClearTarget → sub_14163F940(icon,0) (= SetActive: +116 bit0 清) → +24 group = 0 → sub_14163F540 (隐藏子精灵: +16 → +165&8 门 → vtable+128) → count = 0 (容量保留) → 清 +1640..+1776 → +1800 逐项 deleting dtor + 缩容 → 进度 (步 56, 总 36) → 表① 逐项 deleting dtor + count = 0 (池实体销毁) → 三子结构清 → +1840 工厂 vtable+200 清 → 尾断言 (计数 == 36)。

**框选/点选查询 (sub_140B73340)**: a4 selectable 类型门 = ≤2 或 12..13; 静态层优先级表 unk_14294BF98 = (0, 1, 5, 6, 8, 21, 7) (PE .rdata 实读) 逐项 — 0/1/8 无条件; 5/6/7 需当前地图模式 == 1; 21 需模式 == 3; 其他值断言 @784。命中层后遍历表②: 门 = icon+16 GUI 对象 +165 bit3; 矩形测试 = CMapIcon vtable[1]; 命中即调 vtable[15] 命中收集入口。

**CConstructionInfoMapIcon populate** (sub_1418C67D0): +128 CTooltipHandler 副vtable / +136 省 id (gs+712 省表索引) / +176 building template 指针 (空 → @2143 错误日志) / +192/+208 两子元素 / +200/+216/+224 三文本件 / +232/+240 两控制器 / +248/+256 两指示元素 (+117 bit4 隐旗) / +264 建筑实例挂点 (sub_140B44AC0 安装) / +272 归属旗元素 (sub_140B44870 上国别色)。三分支: ① +184≠0 → 两 level 对象 (sub_140319D60 返回 +960/+968) 双串 → SetText +216/+224; ② tmpl+865 ‖ tmpl+880 → controller 路径 (prov+392); ③ 默认 (tmpl+700>0) → prov+344 建筑列表 (count +356) 逐建筑 (+480→+704 旗过滤) 累加 i16@+64 → 等级文本 (≤0 本地化串; >0 `+n/上限` 含机内转义 "\x11Y"=§Y "\x11!"=§! — 控制字节 0x11 + 标签字符, 推定)。归属旗显示门: owner (分支①③ = prov+204 / ② = prov+392) ≤0 ‖ == 观看者 ‖ 同阵营 (sub_140BB52F0) → 隐。

**警报图标 helper (sub_1418CF8F0)**: 18 元素全隐后按警报列表重扫: 条目 {+16 = 18 位警报位图, +100 >1 门}, 位 j 命中 → sub_1419632F0 + sub_141963D10 (警报 tooltip 构建器, 位/类型 24/其余旗) 构数据 → stride 24B 结果数组找 (首 dword==9 && 值>0) 项显该槽。消费方 = sub_1418C5A60 (宿主 18 元素 @+2040; 该巨函未定性)。

**CInsigniaGraphicsDatabase 校验 (sub_140A553A0)**: 8 轮 (kind 0..7), kind 块 64B (**+8 = 名 SSO 串 / +44 = 期望帧数**, army_icons.txt 定义): 基础名查 GFX 库 qword_14333C1D0 (sub_142238DF0) — 找不到 @254 "Missing army icon definition"; 帧数 (def vtable+120 槽 15) ≠ 期望 @263; 名 + "_selected" 重复两查 @271/@280。全走格式化错误日志无中断。

**kind 4 装备角色入口 (sub_140A56330)**: 支持谓词 sub_140C97B90(*(equipDef+1008)) — 递归原型链 (+1240 = 父原型) + 类别掩码 sub_140F8B020(+1344 ‖ +1352) & 0x80004003C1 (六位类别集, 推定海军族, 位 0/6/7/32/35/47 未逐位定名); 支持 → sub_140A56470(db+296, off_1430BDEF0, a3, a4, *(equipDef+1068)): 角色序号 (a5−1) 对 kind 块 +40 数组 (上界 +52) 取项; a4 旗选变体名 (sub_140A55D50) 或块名 (+8) 构 gfx 名查库。不支持 → 一次性断言 @205。

未决: 图标 target 写入点 (Update ICF 或 acquire 路径) / 0x11 与 0x13 转义码表的逐位映射 / B73340 矩形测试第 4 参 0x140000000 (低 32 位 = 2.0f) 真类型 / kind 4 掩码六位类别名 / icon +168 (书面内嵌列表注) 归属 / sub_14226E4D0 百分比值来源 (实参被反编译器截断) / sub_1418C5A60 巨函。

#### 4.30.52 舰队底栏运行期 (fleetsbottombar.cpp; 6 函闭环 — CFleetsBottomBar 布局 14 项 / 条目重建执行体 / CNewFleetBottomBarButton)

簇清册 (体内 cpp 锚/RTTI 6/6):

| 函数 | 行数 | 体内锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_1417A6930 | 254 | 断言 :201 (闩 byte_14338B0F2) + 窗名串 | CFleetsBottomBar::Setup (teardown 后重建七柄) | 已收 VA, 本批细化 |
| sub_1417A5CA0 | 367 | 断言 :195/:207 + pdx_scopedptr.h:124 | 条目重建执行体 (分页 + 池 + 选中追踪 + 宽度合成) | 新 |
| sub_1417A5300 | 121 | RTTI `CNewFleetBottomBarButton::vftable` + :85 断言 | **CNewFleetBottomBarButton ctor** (malloc 1360) | 新 (书旧标 "populate" 系误标, 已改) |
| sub_1417A6730 | 74 | CLogStream :228 "Unable to create fleet from selected task forces" | CNewFleetBottomBarButton::OnClick | 已收互证 (§4.33), 类归属与方法身份新 |
| sub_1417A59B0 | 60 | 断言共享闩 | 可用内容宽度计算器 | 新 |
| sub_1417A66A0 | 25 | 断言共享闩 | 滚动状态转发包装 (窗 vtable+48) | 新 |

**Setup 七柄重建表** (bar sizeof 2816): +2760 主窗引用 (工厂宿主 vtable+96, 键 qword_14338B0B0; 窗 vtable+552 设 owner = bar+40 tooltip handler) / +2768 centering_box (vtable+440 find) / +2776 fleet_box (vtable+432 find, 条目容器) / +2784 CReserveBottomBarItem 实例 (malloc 1352 → sub_141DE5F60, SetTarget sub_141DE7570 剧场) / +2792 CNewFleetBottomBarButton 实例 (malloc 1360 → sub_1417A5300, 父窗 = centering_box; 尾从窗 vtable+152 取 8B 存 bar+152) / +2800 btn_scroll_left / +2808 btn_scroll_right (vtable+104 find button, observer 挂 bar+184/bar+1472 glue)。

**条目重建执行体** (sub_1417A5CA0; (bar, 选择集对象)): 条目池 = bar+64 {data, cap, count, **+88 活跃数**} (池满 malloc 5440 → sub_141DE59E0, 工厂 = *(bar+48)+1272 同源互证); 分页 = 每页容量 max(1, fleet_box 每行容量) / 总数 = 宽度计算器 / 首索引 bar+172 跨度 bar+176; 选中追踪 = bar+168 门 + 选择集末 idpair resolve 后线性定位换算; 双窗状态 = vtable+128 置/vtable+120 清 + +117 的 0x10 旗, vtable+648/+656 按 +172/跨度启停; 布局 = 逐条目 sub_1402DEC80(fleet_box, …) + 总宽累加 → centering_box vtable+240。调用者 = 左滚回调 sub_1417A6870 (--bar+172 → vtable+184 刷新请求) 与增量刷新 sub_1417A7310 (+96 缓存上次选择集逐项比对, 无变化只跑轻刷 sub_1417A62D0)。

**宽度计算器** (sub_1417A59B0): 总宽 − dword_143336234 (全局常量, define 名未取) − 右按钮宽 − 边距 − 左按钮宽; bar+48 = GUI 上下文单例指针 (vtable+136 session sink / vtable+184 刷新请求 / +1264 宽度源 / +1272 条目工厂宿主)。槽位身份: bar+2792 = scopedptr (持有者 +16 = 窗口; 双断言 pdx_scopedptr.h:134 / fleetsbottombar.cpp:207), 边距 = 窗口 vtable+232 输出, 左/右按钮宽 = bar+2800 / bar+2808 各经 vtable+768 返回 int* 解引用 (左宽额外 + 边距)。

**CNewFleetBottomBarButton 布局** (1360B; RTTI 直证): +8 父窗 / +16 内嵌窗 / +24 1280B CLegacyButtonObserverGlue (绑定槽 = OnClick) / **+1312 状态枚举 (ctor = 2; OnClick 门 == 0)** / +1320..+1351 选择集 {data@+1320, n@+1332} (**OnClick 第二门 +1332 ≠ 0**) / +1336..+1359 双容器尾。

**OnClick** (sub_1417A6730): 双门过 → malloc 144 → sub_141346390 ctor (载荷 = this+1320) → sub_14135C4F0 后处理 → IsValid vtable+72 → 成功经 vtable+136(qword_14332F698) session sink 投递; 失败 :228 CLogStream。与 §4.33 CCreateFleetCommand 全互证。

未决: bar+164 语义 (与总宽成 PAIR64 传 vtable+680, 推定滚动范围) / bar+48 单例与 qword_14332F698/14332F6A0 同一性 (三处槽号全同构, 推定同款) / dword_143336234 define 名。

#### 4.30.53 和会竞标弹窗 Reload (peaceconferencepopups.cpp; 1 函 — CPeaceBiddingsPopUpWindow vtable[2] 主刷新)

sub_141E58900 (527 行; 锚 :175/:189/:203 "Don't know this kind of peace bidding popup", B52, 闩 byte_14338C8B4/B5/B6) = **CPeaceBiddingsPopUpWindow vtable[2]** (PE .rdata 直证挂主vtable 0x142A848A0+16; 书内「popup vtable[6]」所指槽与本函不同槽, vtable[6] 经成员链)。签名 `char(win)`: 返 0 = conf idpair 门拒 (+5248/+5252 全零或 resolve 无效)。

| 偏移 | 类型 | 语义 (窗尾布局新增, 书原只记到 +5248) |
|---|---|---|
| +24 | 指针 | 行池 data (条 1440B) |
| +32 | 容量 | 行池 cap |
| +36 | 计数 | 行池 count (ctor sub_141E55DE0, 件名串 "biddings_popup_item" = CBiddingsPopupItem 直证) |
| +48 | int32 | 填充游标 |
| +56 | 指针 | 源条目数组 data |
| +64 | — | 源条目数组 cap |
| +68 | 计数 | 源条目数组 count |
| +5256 | 元素* | 标题文本 (win+8 类型 0 = CONTESTED / 1 = SELECTED, 样式码两档; 其他断言 :175) |
| +5264 | 元素* | 计数副标题 (PEACE_BIDDINGS_POPUP_NB_{CONTESTED,SELECTED}) |
| +5272 | 元素* | 退款文本 (类型 0 退款分支: 两值对 b ≥ a → REFUNDED_SCORE / 否则 _SCORE_DECREASE) |
| +5280 | 管理器* | 选择列表 (+368/+372 边界 / +384 模式旗 / +392 idpair 数组 / +404 选中 idx; 类名未查) |
| +5288 | 观察器宿主* | 收尾通知 |
| +5296 | 控件* | 全选控件 (+117 旗两态; 文本 PEACE_CONTESTED_ALL_RESOLVED / PEACE_SELECTED_ALL_CANCELLED, 断言 :203) |
| +5304 | 元素* | 退款区辅助元素 |
| +5312 | 控件* | 联动使能 (vtable[648]/[656]) |
| +5328 | 宿主* | 按钮文本 (空源分支 PEACE_BIDDINGS_POPUP_SELECT_ALL) |

机制: 行循环 = 源数组逐条 → 行池复用/新建 (回填 +32 宿主窗 / +40 conf 有效性 / +48 源条目) → 选择高亮 (管理器选中 idx 取 idpair → 加行原语) → 计数/全选/使能二态 → 观察器收尾。与 §4.30.50 双弹窗指针 +20776/+20784 行互证。

未决: vtable[6] 与 vtable[2] 成员链 / +5280 管理器类名 / 两静态 CColor RGBA。

#### 4.30.54 自定义地图模式定义库 (custom_map_mode.cpp; 2 函闭环 — CCustomMapMode 176B / 两层库区分)

簇清册 (体内 cpp 锚 2/2):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_140721960 | 603 | :141 日志 (通道 65536) | custom_map_modes 定义库装载器 + CNullCustomMapMode 哨兵创建 |
| sub_140722370 | 60 | :46 "Unknown type in a custom map mode" (65540) | CCustomMapMode reader (两键) |

**CCustomMapMode 176B 布局** (两处构造点互证): +8 名串 (哨兵 = "NO_TITLE") / +40 库内序号 (哨兵 0) / +48 副本串 (sub_142245E60 从 +8 再构造) / **+80 type: 0 = province / 1 = country** (reader token 225 写) / +88 CAndTrigger 内嵌 (sub_140549F40 ctor)。

**两层库区分 (新定案)**: **定义库 qword_143330DC8** (40B; +0 计数 / +4 桶模数固定 511 / +8 桶数组 / +16 条目向量) — 装载期, 本批新定案; qword_14332F040 = CMapModeManager 侧运行时实例库 (§4.35.15 已收, 该节已补两层注)。**CNullCustomMapMode 哨兵** = qword_143330DC0 全局单例 (书原只记 RTTI 未记全局槽, 本批补): 创建 = malloc 176 完整构造 ("NO_TITLE") 后**仅 +0 单槽覆写** — TNullObject 覆写形的单槽简化变体 (§4.26.4 口径已修订); 哨兵与真条目同进桶链且占条目向量[0]; 全语料仅创建点一处引用 (读者待查)。

**装载器**: 清旧条目 → 建哨兵 push → 解析循环 (名串 → malloc 176, +40 = i++ → 桶头插 → push → vtable+24 reader) → 逐条目日志。调用链 = 静态资源装载主链 sub_14018BB20 → **common/custom_map_modes.txt 单文件**存在性门 → ifstream 解析。**reader 两键**: 225 type (10304 province → 0 / 10394 country → 1 / 其他 :46 错误) / 10595 trigger (+88 CAndTrigger Parse 槽[5] 转发); 未知 token 静默丢弃。

未决: 定义库 → 运行时实例库桥接 (id = 40+下标实例化函数) / 哨兵槽读者 / sub_142245E60 尾参语义。

#### 4.30.55 阵营指挥官窗排序与填充 (faction_commander_window.cpp; 3 函闭环 — 排序模式键全表 / 双源归并 / 搜索过滤)

> 簇名勘误记录: dfwk 簇名 on_commander_window.cpp 与体内断言串 faction_commander_window.cpp (diplomacy\factions\ui) 不一致 — 归属以体内锚为准 (台账级, 待裁)。

簇清册 (体内 cpp 锚 3/3):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_141BF8DF0 | 106 | :430 断言 "Invalid Army Leader Sort" (B51, 闩 byte_14338C410; = 书 :0x1AE 互证) | 归并行构造分发器 (陆军/海军双源二路归并) | 已收 VA, 本批精化 |
| sub_141BF9850 | 170 | :320 同文案 (闩 byte_14338C40E) | 陆军将领列表 introsort 分发器 | 新 |
| sub_141BF9D40 | 187 | :377 "Invalid Navy Leader Sort" (闩 byte_14338C40F) | 海军将领列表 introsort 分发器 | 新 |

**窗布局事实** (窗基 = 调用方 −48): +1464 国来源 / +1480 容器宿主 ("leaders" 子件) / +1512 行构造上下文 / **+1704 搜索过滤串** (+1720 size) / **+3024 排序模式键 (0..3, 0xA..0xE)** / +3028 排序方向旗 / +3112 目标 gridbox / +3160 行列表 / +4408/+4432 陆/海将领指针数组 / **+4504 列过滤旗 (bit0 陆军 / bit1 海军)**。

**归并总控**: 过滤旗分流取列表 (sub_1406DACB0 陆 / sub_1406DAD10 海) → 各自 introsort (count > 32 归并族 / 否则插入排) → **过滤谓词 sub_141ACCA40 双侧淘汰** (搜索串空 = 全可见; leader+64 名匹配或 traits {data@+3528, count@+3540} 任一 trait def+16 名匹配 — §4.31 将领条目互证) → 双侧可见才送 8DF0 构行 → gridbox 重排。

**排序模式键全表**: 0 = 仅方向旗 (海军专用 sorter 对) / 1 = 名 (leader+64, MSVC SSO memcmp 字典序) / 2 = 技能 (sub_140C199F0) / 3 = 仅方向旗 (陆海共享) / 0xA/0xB/0xC = sub_1411844D0 三模取值 (mode2/mode0/mode1; UI 语义名待裁) / 0xD/0xE = sub_1411844B0 单参取值 — 陆/海 sorter 家族各自成对 (大/小), 0xA 起共享。8DF0 行构造: 陆军 leader → malloc 5448 + ctor sub_141AB8B30 + 填充 sub_141AD0CD0 (推定 CArmyLeaderItem); 海军 → malloc 4120 + ctor sub_141ABC6E0 + 填充 sub_141AD21D0 (= CNavyLeaderItem 填充器互证)。

未决: 模式键 0xA-0xE 的 UI 语义名 / 窗 +1512 上下文对象身份 / 海陆列表 getter 的国侧偏移归属。

#### 4.30.56 飞机图形域 (gfxairplanes.cpp; 8 函闭环 — 模型选择/空战场景/动画速查)

**类别枚举 → 模型名全表** (0x141241C20 switch, 22 类别 + :449 `Invalid enum` 断言 latch byte_14333DE33): 实体名 = off_1430B2D50[类别] + "_entity" 后缀查实体库 (sub_142293530); 模型候选收进主/副双 CPdxArray (fighter_1..3 变体 0/1/3、bomber(_1..3) 变体 1、rocket 变体 2、defender_1..3 等按类别 0..20 分配, 12/14/18 双表混编)。**224B 模型条目** (两处独立跨距直证; 名 SSO@0 / 变体 int@16 / 尾部挂点旗+速率区; 栈初始化形 232B 差 8 未决): 尾段 = 挂点动画采样 (sub_14228CD30(实体类型def,7,6,0) (首参 = 类型/模型 def 对象, 四例跨域同构收窄) → 挂点名表 off_1430B2DF8 四名逐个 sub_142293790 探测 → 三次时间采样读挂点位置 → 速率 = |Δ|/0.1 写条目尾槽; 挂点缺失 :495 日志)。**装备→实体五级解析链 0x14124B9F0**: 空门 (:813 `No equipment type. wat.` + terminate) → DLC38 门 + TGameItemDatabase 单例 qword_14332EEC8 (键 = {装备 ptr, 意识形态组 ptr — CPolitics+208→+24 链, int}) → cc+5256 国别定制 → 第二国别源 → 裸名/"_entity" → +216 第二名槽/"_entity"。

**空战场景** (定案): 装配器 0x14124D5D0 (4×4 变换矩阵 + 尺寸归一, 逐槽 224 步进; 实例化失败 :569 terminate) + 状态机 tick 0x14124F3E0 (态 1 复位计时 / 态 2 挂点动画 {82,...} 参数包 + 全局速查 + 事件扫描 + 播完停 / 态 3 收尾, 其他 → :1127 `Unexpected enum` byte_14333DE37)。场景对象布局: +8 模板 (+32 主表/+80 副表 data) / +16 实例 / +32 模板库条目 (+184/+188 → 尺寸) / +40 态 / +44 挂点索引 / +48/+60 攻方表 / +72/+84 守方表 / +104 阶段时间戳 / +112/+120 场景尺寸 / +128 最大单机尺寸。**事件扫描 0x14124FD50** = 280B 实体事件条目表 (sub_1422912F0 取全; 名@0 / +254 dword / +262 过滤 id qword): `a_` 前缀攻方组 / `d_` 守方组 / 数字名 atoi = 1-based 索引 / 名 FNV-1a 32 = 事件键; 越界 :998/:1020 `%s is not a valid event id...`。**随机抽机 = xorshift 闭区间均匀采样** `(h^(h>>8)) & 0x7FFFFFFF % (hi−lo+1) + lo` + seed 1587985054 内联变体 (书 §4.32 载 1587985055 半开 randomize — 两形并存分属两域, 非勘误)。**全局动画速度查表 0x14124D130**: define 数组 NAIrGfx::AIRPLANES_ANIMATION_GLOBAL_SPEED_PER_GAMESPEED {data qword_1433387E0, count dword_1433387EC}, 索引 = 暂停? 0 : gs+1212+1 (idler qword_14332F698 vtable+744 暂停读 getter (§4.1 槽[93]) 返真 → 表首槽; 运行中 = 速度 + 1), 越界 :1444 纯日志 (B51) 兜底返 1.0; gs 守卫对 latch = byte_14332ED00/ED01 全文件共享 (触发器批精化第 2 例直证)。动画场景实例构造 0x141241990: 延迟启动 = xorshift × 4.6566129e-10 (2⁻³¹) × (qword_143333078 定点/1e5) + 时间源; 实体缺失 :3263 `Missing entity for animated scenario...` 断言。域 latch 块 = byte_14333DE33..DE3A 连续 8 字节。

#### 4.30.57 地图图标槽[3] 模板壳簇 (mapicon.h; 12 派生类实例 + 2 伴生件 — 帧级 Update/populate 分发逐类定案)

CMapIcon 派生族 12 类的槽[3] (§4.30.26 帧级 Update/populate 分发) 函数本体全部实例化在 mapicon.h 内 (巨型头模板壳形态); 类特有 populate 在各自 .cpp (§4.31.47 peacemapicon.cpp 等消费侧) — **槽[3] 函数 ≠ 类 .cpp 函**。

12 类槽[3] 归属 (vtable PE .rdata 直证):

| vtable | 类 | 槽[3] 函数 | 形态 |
|---|---|---|---|
| 0x142A19728 | CPeaceMapIcon | 0x141906540 (928 行) | 大内联 |
| 0x142A18140 | NRaids::NUi::CRaidMapIcon | 0x1418EBAD0 (161 行) | 大内联 |
| 0x142A17D98 | CNavalHeadquarterMapIcon | 0x1418EA670 (142 行) | 大内联 |
| 0x142A18828 | CNavalCombatMapIcon | 0x1418F8180 (54 行) | 半内联 |
| 0x142A1A6F8 / 0x142A1A7A8 | CUnitsStackMapIcon / CUnitsStackMapIconGroup | 0x141914840 (44 行) | 半内联 |
| 0x142A174C8 | NFactions::NUi::CFactionPingMapIcon | 0x1418DF2E0 (30 行) | 内联 (§4.31 已全解, 复核全符) |
| 0x142A17800 / 0x142A178C8 | CIntelLedgerMapIcon / CIntelLedgerMapRegionIcon | 0x1418E25F0 (29 行) | 纯转发壳 |
| 0x142A17C80 | CIntelMapModeMapIcon | 0x1418E9450 (29 行) | 纯转发壳 |
| 0x142A182B8 | CNavalBaseMapIcon | 0x1418F1460 (29 行) | 纯转发壳 |
| 0x142A19F38 | CScriptedMapIcon | 0x14190C900 (29 行) | 纯转发壳 |
| 0x142A19CE8 | CResistanceComplianceMapIcon | 0x14190B420 (29 行) | 纯转发壳 |
| 0x142A1A078 | CStateModifierMapIcon | 0x14190D6F0 (29 行) | 纯转发壳 |

伴生件:

| 函数 | 身份 |
|---|---|
| 0x141908EB0 (332 行, 非虚) | CRailwayMapIcon 刷新实体 (槽[3] wrapper 0x141909960 的实体) |
| 0x1418BBB30 (27 行) | 层 LUT 访问器本体 (§4.30.19/§4.30.26 已名; `return LUT[type]` 单读 + mapicon.h:189 断言, 定案) |

槽[3] 共同骨架 (14/14 定案): 基可见门 sub_14163F9D0 为真只定位 (仅 CUnitsStackMapIcon) → eType 断言 (mapicon.h:189 `eType < MAP_ICON_TYPES_COUNT`, 门 byte_1435E1B52 + latch byte_14338B2CF 全簇共享) → sub_140FA61D0(icon, xmmword_14338A9F0[type] + 变体偏移) (gfx 层 id 写 +112) → sub_14163FAF0(icon, a2) 定位 → 派生 populate (委派或内联)。

变体偏移四形态 (基准 = `xmmword_14338A9F0[type]` byte LUT, 0..33 → gfx 层 id):

| 变体偏移 | 适用 | 条件 |
|---|---|---|
| +0 | 10 类标准 | 无 |
| +1 | CRailwayMapIcon | 无条件 |
| +1 | CRaidMapIcon | 目标对象 vtable+64 查询返真 |
| +5 | CUnitsStackMapIcon | 选中态 (窗管理器 qword_14332F698+1272→+320 非空 且 子精灵(icon+16)→+48 对象 vtable+344 真) |

**CPeaceMapIcon [3] (0x141906540, 928 行)** — 和会地图建筑/资源图标 populate。实例 296B:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +16 | 对象指针 | tooltip 根件 (vtable+440 按名取子件; +120 取子件 / +232 读 / +240 写对) |
| +108 | int8 | icon type (eType, :189 断言域) |
| +136 | uint32 | 国家下标 (→ gs+712[idx], 上界 gs+724 = gs+89×8/+181×4) |
| +144 | 模板指针 | 和会图标模板: +221 byte 跳出门 (置 1 早退) / +520 uint32 id / +528 类目 token |
| +152 | 参数指针 | 名构建输入 sub_1419E7470(模板, 本字段) |
| +156 | uint32 | 模式 (== 2 走谈判者旗分支) |
| +160 | 对象指针 | 可选引用一 (sub_1419E8FD0(对象, id) 匹配 → tooltip 附加行) |
| +168 | 对象指针 | 可选引用二 (同上) |
| +192 | std::map | RB 树 u32 集合 (值在节点+28) → 收集排序 |
| +212 | uint32 | tooltip 行基号 |
| +216 | 向量 | 输出条目向量 (建筑库迭代写入) |
| +248 | uint32 | 计数清零位 |

建筑特例 switch — `模板+528 token` 三值直接配对 GFX (函数体字符串直证, 定案):

| token 常量 | GFX | 建筑名 |
|---|---|---|
| 12531 (0x30F3) | GFX_building_fort_icon | bunker |
| 12532 (0x30F4) | GFX_non_available_factory_icon | industrial_complex |
| 12534 (0x30F6) | GFX_military_factory_icon | arms_factory |

注: 常量↔GFX↔建筑名配对仅由本函数体直证; 离线 token 表同 id = demilitarized_zone / war_reparation / dismantle_industry — 离线 token 表 ≠ 运行时 lexer (排雷速记通则), id 数值勿跨环境引用。tooltip 五键流 = "flags" (vtable+440) → "info" → "cost" (vtable+120 取子件 + sub_1422CA920 设文本) → "resources_grid" (qword_1429E22B8, PE .rdata 直证) → vtable+240 写 {读值, 基号+行数} 对。谈判者旗分支 (+156==2): +168→+56 的 tag 与玩家 tag (sub_140E47890, 内含 gamestate.h:1125/1126 双守卫) 相等或 sub_140BB52F0 同原初国谓词 (§4.30.21 已名) → 附加换行文本行。建筑库全库迭代 = TGameItemDatabase 单例 qword_14332F088 (+40 data / +52 计数) 逐条 sub_141905480(条目, 国家, 名缓存, +216) (断言 gameitemdatabase.h:142, latch byte_14332F3F3)。集合排序 = 计数 ≤32 直调 sub_141904A60; 否则归并 (scratch ≤1024 元素栈上 / 超出 malloc 失败减半重试 — §3.2a 170 阈同族第二实例)。

**CRaidMapIcon [3] (0x1418EBAD0, 161 行)** — 与 §4.27.8 宿主四数据槽互证:

| 偏移 | 语义 |
|---|---|
| +108 | eType (基类通则) |
| +112 | gfx 层缓存 (基类通则) |
| +136 | 目标对象 (vtable+64 查询旗 → LUT+1; vtable+24 帧更新透传 a2) — 与 §4.27.8 内嵌 Data 族 +136 = 变体指针为两个不同对象, 按类区分 |
| +144 | 变体号 (1..4; 本函处理 ∈ {1, 3}, 2/4 落基类尾) |
| +1488 | 过滤集 std::map (键 = 节点+32 qword) |
| +2968 | 变体 1 读点 = state1 槽 (+152 基) +2816 单位向量 data 指针 (与 §4.27.8 UpdateUnits +2816 同构互证) |
| +8672 | 变体 3 读点 = state3 槽 (+5888 基) +2784 槽, 内嵌 +152 二级门 |

变体 1 逻辑: 遍历 +2968 向量 {data, 计数@+12} 的 u32 元 — 元含旗 0x10000000/0x20000000 时取低 27 位为下标 (⚠ 两旗分属两侧: tooltip/populate 侧只判 0x10000000, 0x20000000 分支在 [3] 本体 — §4.27.9) → `*(gs+1008 → +352) + 56×下标` 56B 条目 → 其 u16 向量逐元判 (旗 0x2000 && 旗 0x4000 && sub_141B29930(筛选对象+4648)) 有任一合格 → 显。变体 3: +8672→+152 非空且 sub_141B29930 直判 → 显。显隐对 = 基类 sub_14163FAD0 (Show) / sub_14163F540 (Hide) — **子精灵 +165 bit3 = 隐藏态镜像** (bit3 未置 → Show, 置位 → Hide; GUI 件 +117 bit4 同款镜像旗)。gameitemdatabase.h:142 第二 latch byte_14333D19A (与 CPeaceMapIcon 的 byte_14332F3F3 分站点)。

**CNavalHeadquarterMapIcon [3] (0x1418EA670, 142 行)**: 目标解析 sub_1418EA2A0 → sub_1410DB630 取 tag; 玩家 tag 读 gs+1312 (计数>0) 否则 gs+1316 (观察者 tag 槽对, 读点定案; 权威写点未决); 相等或同原初国谓词 → 子件 +1432 vtable+648 Show 否则 vtable+656 Hide。帧 = sub_1415C16E0(谓词) && sub_141510EC0(国+4016, icon+1424) → 3 否则 1 (vtable+176 设帧; §4.31.44 帧 3 门 = cc+4016 互证全符; icon+1424 = 站点/hq 标识 id)。

**CNavalCombatMapIcon [3] (0x1418F8180, 54 行)**: populate sub_1418F73F0 后 CID {+136 family, +140 id} 经 sub_14221F310 引用注册表解析 (§3.2b) + 结果 !=16 空外层门 → 子件 +1512 按 sub_1418F5450() 计数显隐 (§4.31.37 海战 refid @icon+136 互证)。

**CRailwayMapIcon 刷新实体 (0x141908EB0, 332 行)**: 门 = +1424/+1432 双 GUI 件指针非空; +1476>0 走轨道升级文本分支: DTO+28/+32 (icon+1468/+1472, §4.30.16 DTO u32 四元互证) 等比 → 数字串拼 ">" 再拼第二数字 (sub_1424CA600 数转串 + sub_14011FFD0/FF60 拼接) → 文本件 +1496 (sub_1422CA920 设文本); +1489/+1490 双旗 → 件 +1504 vtable+176 设帧 1/2/5; 第三件 +1520 按 +1468 ≤/> +1472 显隐; 尾 = :189 断言 + LUT+1。

7 纯转发壳委派表 (同骨架: 断言 + LUT+0 + 定位 + 委派):

| 类 | 委派 populate |
|---|---|
| CIntelLedgerMapIcon / CIntelLedgerMapRegionIcon | sub_1418E1720 |
| CIntelMapModeMapIcon | sub_1418E88B0 |
| CNavalBaseMapIcon | sub_1418F0410 |
| CScriptedMapIcon | sub_14190C200 (单参, 无 a2) |
| CResistanceComplianceMapIcon | sub_14190A2D0 (§4.30 resistancemapicons.cpp 已名) |
| CStateModifierMapIcon | sub_14190CCE0 |
| CNavalCombatMapIcon | sub_1418F73F0 (半内联前段) |


**gui.cpp 控件工厂分发族 (clausewitzlib 层, 四函新析)**: 统一契约 = 工厂嵌入对象 +192 虚槽[1] 取 GUI 类型定义 → 定义+8 = GUI_TYPE 枚举 id 比对 → 匹配则构造器(*(a1+184), a1, a3) 建 widget → 工厂 vtable 槽[20] (+160) 注册钩子挂入; 定义缺失 gui.cpp:931 "Undefined GUI_TYPE: %s - This will most likely crash the game"; 类型不匹配各错误串。**GUI_TYPE 枚举实名 4 项** = 612 containerWindowType (工厂 0x14225B1B0, 构造 sub_14230FE70, 注册件 = w+48, 错误 :409, 哨兵槽 a1+496) / 613 extendedScrollbarType (0x14225B520, :437, a1+528) / 620 dropDownBoxType (0x14225B330, :451, a1+536) / 629 gridBoxType (0x14225BDE0, :423, a1+504); 哨兵槽 = 工厂内每类型兜底 widget 指针 (槽号与类型 id 非线性)。按值移除助手 0x14225C140 (宿主 +585 _CanUpdate 门, 容器 {data@+264, count@+276} 线性查删 memmove, 宿主类未决)。


#### 4.30.58 CGuiObject 基类析构与双向摘除 (guiobject.cpp 1 函)

#### 4.30.59 CProgramView::CreateWindow (program_view.cpp; 1 函 = sub_141B1CAA0 + 收尾链 sub_141B1CBD0, 定案)

sub_141B1CAA0: 前置断言 :55「_pWindow == 0 && "Window already created."」= 重复创建门 (闩 byte_14338C165, 门变量 = a1+48); 建窗 = GUI 窗库 qword_143453230 **vtable+96 按名建窗** (名 "program_window", 栈构 SSO 16B) → 挂 a1+48; 窗装载 = 窗对象 vtable+544 单参调用 (推定 Init/Populate)。收尾链 sub_141B1CBD0: malloc(0x1D58 = 7512B) → sub_141EF06E0(new, *(a1+48), a1+1432, *(a1+1436)) 构造内容视图 → 释放旧视图 *(a1+1448) (sub_141EED800(old+1520) + sub_141EEA5D0(old+16) + free) → 挂 a1+1448 → 旧标题控件 *(a1+56) 经 vtable+552 卸载 → sub_1422BC600(window, &"title", 1, 1) 新建标题控件挂 a1+56。**CProgramView 字段链**: +48 窗指针 (创建门) / +56 标题控件 / +1432 数据源 A / +1436 数据源 B / +1448 内容视图 (7512B)。互证: cc+2896 = CProgramView 弹窗槽 (§4.30:1360); "program_window" 与 §4.31 程序条目 open_program 对上。

#### 4.30.60 和会出价弹窗打开处理器 (peacebiddingswindow.cpp; 1 函 = sub_141E4F7F0, 定案)

sub_141E4F7F0: 类型枚举 *(a1+1312) — 0 → 本地化键 `PEACE_CONFERENCE_ON_CLICK_OPEN_CONFLICT_POPUP` / 1 → `PEACE_CONFERENCE_ON_CLICK_OPEN_SELECTED_POPUP` / 其他 → :55 断言「Don't know this kind of peace bidding popup」(闩 byte_14338C898); 出参 a3 = 32B std::string (sub_14011FE60 移动赋值, 默认 SSO 空串); 恒返 1。与 §4.30:579 CPeaceUIHelper 两函 (和会主窗「全选/全撤/全叠」标签, ui+1296 = CPeaceConference* / ui+1304 模式 {0=SELECT,1=CANCEL,2/3=STACK|UNSTACK}) 为**和会 UI 族第三件**; ⚠ 本件 a1+1312 类型槽与 CPeaceUIHelper ui+1304 模式槽**不是同一枚举** (本件仅 0/1, 键名后缀 ON_CLICK_OPEN_*_POPUP, 语义 = 点击打开何种出价弹窗)。

`CGuiObject::~CGuiObject` = 0x1422ADD90 (guiobject.cpp:10 断言串直证; widget 谱系见本节族表)。基类布局 (dtor 写点 + 断言直证):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | 主 vtable (dtor 首指令回写 CGuiObject::vftable) |
| +16 | std::string (32B) | 串 A (buf@+16 / size@+32 / cap@+40, SSO cap=15; 语义未决) |
| +48 | std::string (32B) | 串 B (buf@+48 / size@+64 / cap@+72; 语义未决) |
| +96 | 容器* | 持本对象的数组容器 A (data@+16 / count@+28, 8B 元; 摘除 = swap-remove) |
| +104 | 宿主* | 持本对象的宿主 B (子数组 data@+288 / count@+300; 回指槽 @+320 / @+328) |
| +117 | uint8 旗 | bit0 = `_bMayDeleteOutOfTurn`; bit2 = sub_14225D4A0 摘除门 |

摘除序: ① `sub_14225D4A0(*(a1+104), a1)` (宿主 B, 门 = 本对象 +117 bit2 未置, 遍历其 +288 数组) → ② 宿主 +320/+328 回指若 == 本对象则清零 → ③ 全局计数 `--dword_1434810FC` → ④ 容器 A (+96) swap-remove (命中则与末元素交换并缩 count@+28) → ⑤ 两 std::string 释放。

摘除前置断言 (guiobject.cpp:10, B52, 闩 byte_143481100): `CGui::Get()->MayDeleteGuiObject() || _bMayDeleteOutOfTurn`, 判据含 sub_14225D490(qword_143453230) (CGui 单例 MayDeleteGuiObject 判定, 推定)。

> 未决: 两 std::string 语义 (推定 name / template 名, 需 ctor 或读写点) / 容器 A 与宿主 B 关系 (推定 A = 父窗子元素表, B = CGui 管理器注册表, 未证) / dword_1434810FC 语义 (推定 = 全局活 CGuiObject 计数, 构造点未核) / sub_14225D4A0 体未全读。
