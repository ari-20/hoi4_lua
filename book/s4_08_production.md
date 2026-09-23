

### 4.8 CProductionStatus (生产)

**获取**: `ps = *(cc + 3944)`。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +88 | 匿名结构 (8B 形状) | lines 容器数据指针 | {data, count}, 元素 8B 指针, count<256 | **GUI: 生产线列表建行** (sub_14173FEA0 → production_lines/item_grid) |
| +89..+99 | — | lines 容器内部 | data 尾 (+89..+95) + **cap@+96**; 四元组 {d@88, cap@96, c@100, alloc@104} 补全  |  |
| +100 | u32 | lines 容器计数 |  |  |
| +101..+111 | — | lines 尾 + general_lines 头 | count@100 尾 + **alloc@104 (哨兵)** + general_lines {d@112} 前 pad  |  |
| +112 | 匿名结构 (NNB 形状) | general_lines 容器数据指针 | {data, count}, count<4096; general_count 亦导出于 +124 |  |
| +113..+123 | — | general_lines 容器内部 | data 尾 (+113..+119) + **cap@+120**; {d@112, cap@120, c@124, alloc@128}  |  |
| +124 | u32 | general_lines 容器计数 |  |  |
| +125..+231 | — | 中段容器群 (全部 24B pdx 四元组) | general_lines alloc@128 + **rocket_lines {d@136..152}** (块 13304) + **available_equipments {d@160..176}** (块 12461) + **运行时容器 A {d@184}** (元素 = CEquipmentVariant*, 不序列化) + **容器 B {d@208}** (AI 生产挑选, 不序列化) + **foreign_lease_equipments {d@232..248}** (块 13049)  |  |
| +232 | CEquipmentVariant* | foreign_lease_equipments 容器数据指针 | 元素 = variant 指针, 无条件写 id 对 |  |
| +233..+243 | — | foreign_lease_equipments 内部 | data 尾 + **cap@+240**  |  |
| +244 | u32 | foreign_lease_equipments 容器计数 |  |  |
| +245..+511 | — | 容器群 + licensed + 池头 | foreign_lease alloc@248 + **运行时容器 C {d@256}** (AI 装备比较, 不序列化) + **容器 D {d@280}** (不序列化) + **industrial_organisations {d@304..320}** (块 19162) + **policies {d@328..344}** + **运行时容器 E {d@352}** + **named_equipment_bonuses {d@376..392}** (块 10206, 200B 元) + **CLicensedProductionStatus@400 (112B)** {avail@408, 运行时容器@432, owned@456, 运行时容器@480, owner 反指@504, 条目+0 qword → 对象 +0 = 目标国 tag (is_licensing_any_to; 推定)} + **CEquipmentVariantPool@512** 头  |  |
| +512 | 匿名结构 (16B 形状) 向量 | equipments 池 (12122) | {data@+32, count@+44} 16B 条 {variant*, amount fixed×1e-5} | 写门: amount≠0 或 allow_zero(uint8@+568)==1; **GUI: 市场库存变体量查** (sub_14100EB00) |
| +513..+567 | — | CEquipmentVariantPool 体 | 预留池 {d@520..536} (24B 元, 不序列化) + **序列化装备池 {d@544, cap@552, c@556, alloc@560}** (16B 元 {variant*, amount}) + **allow_zero_entries u8@568**  |  |
| +568 | uint8 | equip_allow_zero_entries | | |
| +569..+607 | — | destroyed_stockpile + scheduler | **destroyed_stockpile_equipment {d@576..592}** (40B 元, 零行 B) + **CCreateEquipmentVariantScheduler@600 (32B)** {vt@600, 容器@608 {d@608, cap@616, c@620, alloc@624}}  |  |
| +608 | CCreateEquipmentVariantSpec* | scheduled_equipment_variants 容器数据指针 | {data@+608, count@**+620**}; ⚠ +616 = capacity 非 count — pop 后 capacity 内残留悬挂槽 (arch 指针仍活→键像真, var 悬挂→字段垃圾 1069219840 类); scheduler vt 0x1429706b8, 池 writer 0X141A00AF0, 元素 16B {arch@0, var@8}; spec 类 CCreateEquipmentVariantSpec **无 hull/train 派生** (泛型 writer 0X141463A90 全型同门); spec 字段: name@+16 / name_group@+48 / icon@+184 / obsolete b@+84 (b84=1 写 yes 正向; +85 系另一字段反向门) / model@+144 / parent_version@+80 / io id 对@+248 / upgrades {d@+96, c@+108} 16B 条 / modules {d@+120, c@+132} 16B 条 |  |
| +609..+619 | — | scheduler 容器内部 | data 尾 + **cap@+616**  |  |
| +620 | u32 | scheduled_equipment_variants 容器计数 |  |  |
| +621..+671 | — | scheduler 尾 + modules + CicBank 头 | alloc@624 + **enable_equipment_modules {d@632..648}** (块 15212, u32 token 元) + **CCountry 反指@656** + **CCicBank@664** {vt, value i64@672}  |  |
| +672 | fixed×1e-5 | cic_bank | **GUI: 国际市场视图命中** (CCountryInternationalMarketView) |  |
| +673..+1191 | — | 四工厂池 + consumer 群 + 运行时区 | **工厂池×4 (96B 无 vt)**: +688=military / +784=dockyard / +880=civilian / +976=保留 (探针 GER 132/31/168/0; {**+0 u32 = controlled 数 / +4 u32 = owned 数 (num_of_controlled/owned 对偶; 推定)**, **val@+8 = 工厂总量**, **+32 qword = 项目占用扣减 (available_for_projects 参减 ÷1e5; 民用池即 ps+912; 推定)**, **dword@+40 = 已分配产线工厂**, dword@+56 (ps+936) — **活探针: 8 国全 = 100000 (恒 1.0 fixed)** (旧探针 GER 11922 与活值不符, 以活值为准); **作布尔门** `+936!=0 && +928==0` 消费于 sub_140697EA0/sub_1406996B0/sub_14142D240 → 门恒真半边, 真分支条件在 +928; 语义待裁) — 另 **dword@+48 (ps+928) 活探针 = 各国异值的消费品百分比样值** (fixed: 70%/85%/68.75%/4.87%… 经济法则取值域; 全 8 国非零) → 门语义 = 「无消费品负担态」判定, **+64 = 可用工厂公式减项 (军池 = 转出合计 ≡ +72++80; 民用池 = 生活消费品侧, 见 §4.31.30 — ⚠ 四池此槽语义不同, 勿按军池外推)**, **+72 = 上缴宗主 (mic_to_overlord_factor) / +76 = 受赠所得 / +80 = 外赠目标国 (mic_to_target_factor)** — 军池定案, 写入 sub_140E6C810/sub_140E611B0, 即 UI 侧 ps+696/+728/+752/+760/+764/+768/+792}) + **consumer×5 @1072..1191** {vt, enabled u8@+8, u64 双 dword@+12, **值 @对象+16**} (顺序 CConsumerGoods@1072 / CSpecialProjects@1096 / CLicensedProduction@1120 / CTrade@1144 / CContractPayment@1168 — 类序由工具提示 loc key 用法互证, §4.31.30) + dirty@1192 + 运行时@1194/1196/1198 (探针 0x40003/各国异值/≈tag 槽) + **max_factories_for_repair@1200** + **运行时容器 F {d@1208}**  | **GUI: 运营军工厂双读数** (军池 val@696÷1e5 −分配760 −768 / −728 −752; sub_141743200→sub_14173B2D0 → PRODUCTION_OPERATIONAL_FACTORIES_VALUE) **+ 造船厂读数** (船池 val@792 → dockyards_output_value) **+ tab 使能** (军厂钮 ps+696>0 / 船厂钮 ps+792>0; sub_141739E20) **+ 占用条** (military_factories_usage bar=100−比例; naval_factories_usage × sub_140E69130) **+ 民用池全项工具提示** (§4.31.30) |
| +1192 | uint8 | dirty | | |
| +1200 | uint32 | max_factories_for_repair | | |
| +1201..+1255 | — | discount + resource cost | **discount {d@1232..1248}** (块 10202, 40B 元) + **CProductionResourceCost@1256 (32B)** {vt, resource def*@1264 (= null_object 单例 → "none" 占位根因), amount@1272, need@1280} (块 12781) |  |
| +1256 | 匿名结构 (NNB 形状) | energy_production_cost | amount fixed×1e-5@+16, need@+24 (恒 0), resource token@(*(ps+1264)+8) | |
| +1257..+1351 | — | 运行时聚合区 | 聚合 u64@1288 (探针 ENG=550.0) + **工厂池内指表 {1296→880 民用, 1304→688 军用, 1312→784 造船厂}** (探针差值 192/96 实证) + 四经济聚合 i64@1320..1344 (探针 FRA 50.30/462.72/137.00/3.3775) + **last_named_equipment_bonus i32@1352 (ctor 默认 −1 非 0)**; 对象总大小 1360B  |  |
| +1352 | int32 | last_named_equipment_bonus | | |

#### 4.8.1 生产线元素 (多态类族)

生产线元素实为多态类族 (定案), family writer = 0X1414B59B0 与 0X141939760:

| 类型 (line_type) | 尺寸 (B) | writer |
|---|---|---|
| 军线 (military) | 248 | 0X1414B59B0 / 0X141939760 |
| naval (57) | 280 | 0X1414B59B0 / 0X141939760 |
| refit (71) | 344 | 0X1414B59B0 / 0X141939760 |
| railway_gun (75) | 272 | 0X1414B59B0 / 0X141939760 |
| rail_way (4713) | 168 | 0X1414B59B0 / 0X141939760 |
| gun_repair (76) | 120 | 0X1414B59B0 / 0X141939760 |
| building (59) | ≥176 | 0X1414B59B0 / 0X141939760 |

类名绑定 (1.19.3 实证; 抽象基虚表槽[2]/[4] 只挂 id 对原语 0x142220340 / 0x14221FC10, 字段 writer 由叶类链调):

| 类 | line_type | sizeof | vt (主) | 字段 writer / reader |
|---|---|---|---|---|
| CProductionLine (抽象基) | — | 80 | 0x1429CB2F8 | 0x1414B59B0 / 0x1414B58E0 |
| CEquipmentProductionLine (装备基; 次表 @+80 = TListenerTrait 0x142A1C680) | — | 248 | 0x142A1C570 | 0x141939760 / 0x141939330 |
| CMilitaryProductionLine | 56 | 248 | 0x14297BC80 | thunk → 装备基 (零增量) |
| CNavalProductionLine | 57 | 280 | 0x14297BE68 | 0x140F6F590 / 0x140F6F4F0 |
| CBuildingProductionLine | 59 | 176 | 0x14297B958 | 0x140F6E660 / 0x140F6E1C0 (经 CGeneralProductionLine 层 0x141A2F7C0) |
| CRailwayGunProductionLine | 75 | 272 | 0x14297BFC8 | 0x140F70E10 / 0x140F70C60 |
| CRailwayGunRepairLine | 76 | 120 | 0x14297C100 | 0x140F70E60 / 0x140F70C80 |
| CRailwayProductionLine | 4713 | 168 | 0x142A2BE90 | 0x141A046E0 / 0x141A041D0 |
| CGeneralProductionLine | — | — | 无独立 vt (抽象中间层, 负定案) | 字段 writer 0x141A2F7C0 (created_date 键 15102 @+96) |
| CRocketProductionLine | rocket | ~120 | 0x14297C260 | 0x140F71830 / 0x140F71530 (**不经 CProductionLine 支系**, 见 §4.31.33) |

通用布局:

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | line_type | type: 57=naval, 59=building, 71=refit, 4713=rail_way, **75=railway_gun (生产线, 落盘键 railway_gun_lines)**, **76=railway_gun 修理线** (子型键名 building/rail_way/railway_gun 分族计数); ⚠ 编号三套并存勿混: CIdentifier 线引用 type **75 = railway_gun**（名管理器二路 = cc+120 舰名 / cc+128 铁路炮名）, **74 = 产出铁路炮定义引用**, 76 = 修理线行 type |  |
| +12 | uint32 | line_id |  |  |
| +13..+23 | — | CReferenceObject 引用对内部 | {line_type u32@8, line_id u32@12} 尾 + **u8 flag@16** (ctor 0) + pad; 引用对默认 qword_14333D528 = 全局无效 id 对  |  |
| +24 | uint32 | active_factories | **GUI: 类别合计** ((线+24+线+28) 按变体类别 token 分 6 桶 → show_equipment 等徽标; sub_14173FEA0 switch) | |
| +28 | uint32 | damaged_factories | =0 不写 | |
| +29..+39 | — | active/damaged 尾 + owner 头 | {active u32@24, damaged u32@28} 尾 + pad + **owner CProductionStatus* 反指@+32** (ctor a3; 建筑线模板解析 *(owner+656)+8 链实证)  |  |
| +40 | fixed×1e-5 | cost |  |  |
| +48 | fixed×1e-5 | speed |  |  |
| +56 | fixed×1e-5 | produced |  |  |
| +64 | uint32 | queued_factories | =0 不写 | |
| +68 | uint32 | priority | amount 带符号; **GUI: 行优先级 ▲▼ + 拖拽重排** (CChangeProductionLinePriorityCommand: 新值=+68+1, shift→9999; @1408 CReorderObserver 全表重排) |  |
| +72 | int32 | amount | amount 带符号; **GUI: 行数量提交** (CSetProductionLineAmountToProduceCommand; 载荷@cmd+48; 变体+1208==3 走换装选择流) |  |
| +73..+87 | — | amount 尾 + 双族分岔槽 | **amount 默认 −1**@+72 尾 + pad + 军线族 **MIO listener vtable@+80** / 通用线族 **CGameDate created@+80 (hours@88=43808760)** — 两类不同布局同槽 (定案) |  |
| +88 | hours | created_date (**仅 general 线族**) | general 线导出 | 定案: 线对象多态 — 军线族 (56/57/71) +88 = 下行 resources 容器; general 线族 (59) +88 = u32 hours (实测 ≈60.7M); 判别键 = 线所在容器 (军线 ps+88 / general ps+112) (探针) |
| +88 | 匿名结构 (32B) | resources 容器数据指针 (**仅军线族**) | 32B 内联: def 指针@+8 (名 token@def+8), amount int64@+16, need@+24 (均 ×1e-5); 名="none" 的占位元素不写 | 定案 (同上行判别键; 军线 353 线全指针实证, 探针) |
| +89..+99 | — | 军线 resources 容器内部 | data 尾 + **cap@+96**; resources {d@88, cap@96, c@100, alloc@104} 元 **32B = CProductionResourceCost** {vt, def@8, amount@16, need@24}  |  |
| +100 | u32 | resources 容器计数 |  |  |
| +101..+135 | — | 军线 resources 尾 + 运行时区 | alloc@104 + **运行时容器 {d@112, cap@120, c@124, alloc@128}** + variant 宿主@136 前 pad  |  |
| +136 | CEquipmentVariant 引用宿主* | equipment_variant | id 对 {type@+8, id@+12} | |
| +144 | u32 | industrial_manufacturer.type — id 对之 type (id 对) | 任一非零才写 |  |
| +148 | u32 | industrial_manufacturer.id — id 对之 id | 任一非零才写 |  |
| +149..+191 | — | CTraitBonus 尾 + 运行时容器 + fe 头 | **CTraitBonus 内联@+152** (vt@152, dtor 0X1401516C0) 尾 + **运行时容器 {d@160..176}** + **u8=1@184** + fe {d@192} 头  |  |
| +192 | int64 | factory_efficiencies 容器数据指针 | i64 Q15 数组 (8 字节步长!); 元素读法 = **整体 read_u64** (Lua integer 精确 64 位) — 禁 lo + hi×2^32 浮点重组 (hi=0xFFFFFFFF 时超 double 53 位精度致值漂移, Red_Dusk 假 DIFF 实证) | **GUI: 生产线效率列数据侧** (0X141937ED0/0X141939760; 行 UI 绑定未决) |
| +193..+203 | — | fe 容器内部 | data 尾 + **cap@+200**; fe {d@192, cap@200, c@204, alloc@208} 元 8B i64  |  |
| +204 | u32 | factory_efficiencies 容器计数 |  |  |
| +212..+223 | — | 军线尾区 (writer 不触 = 垫/运行时)  |  |  |
| +224 | i64×1e-5 | **non_conversion_speed** (tok 14330; 门 = is_converting@+236 置位才写; 换装惩罚补偿速度) | writer 0X141939760 | 定案 |
| +232 | u32 | **requested_factories** (tok 13769 = 0x35C9; 断言名 nFactories, equipment_production_line.cpp L543) — 线上已分配工厂数; 增减 = CAddProductionLineFactoriesCommand (Execute: 新值=载荷+旧值, setter sub_14193A3D0 clamp ≤ GetMaxAllowedFactories = 线 vt[11] 虚槽 → 变体+1440 → arch+1440 → 默认 dword_143335FE0 [实测 150]) | — | 定案 |
| +236 | u8 | **is_converting** (tok 14304; ≠0 才写, 连带写 +224 non_conversion_speed) — 行换装门 | writer 0x37E0 | 定案 |
| +237 | u8 | **collapsed_interface** (tok 14608; ≠0 才写 — 行 UI 折叠态, 会序列化) | writer 0x3910 | 定案 |
| +240 | u32 | **interface_factory_scale** (tok 14679; ≠1 才写 — 行 UI 工厂格缩放) | writer 0x3957 | 定案 |

#### 4.8.2 naval (57) / refit (71) deployment

deployment 形态分型:

| 类型 | deployment 形态 | 写门 |
|---|---|---|
| naval (57) | 指针@元素+272, writer 0X140D148B0 三分支 (tf/ship/base; 实测走 base 分支) | — |
| refit (71) | 块内联@元素+248 {tf 对@+260/+264, base u32@+276, ship 对@+280/+284} | base 仅在无 tf 对时写 |
| railway_gun (75) | **无 deployment** (272B 类 +248..+271 = names 容器, 无 +272 槽) | — |

deployment 对象布局 (naval: dep = 元素+272 解引用; refit 形态同构内联):

| 偏移 (dep) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +12 | u32 | tf.type — id 对之 type (对) | type==16 为哨兵 |
| +16 | u32 | tf.id — id 对之 id | type==16 为哨兵 |
| +17..+27 | — | **第二 id 对@+20** {type@20, id@24} — ctor qword_14333D528 默认, writer 不发 = 运行时 |  |
| +28 | uint32 | base | 实测走 base 分支 |
| +29..+47 | — | base@+28 尾 + naval: u64=0@+32 / refit: **ship 对 {type@32, id@36}** + naval: null 单例指针@+40 / refit: 0 + naval: **ICAW 块头@+48** (sub_141012160 从 deployment 状态拷入) / refit: null 单例  |  |
| +48 | 内嵌 | initial_carrier_air_wing_deployment: 容器 {data@dep+56, count@dep+68}, 元素 16B {名对象指针@+0 (token@+8), value int64@+8} | |

**类名/基链 (1.19.3 实证)**: 部署对象 = **CNavalDeployment** (80B, vt 0x14295FB48, ctor 0x140D0D2F0, writer 0x140D14860 / reader 0x140D124E0), 基 = **CNavalDeploymentTarget** (vt 0x14295FAF8; 基 writer 0x140D148B0 = 上表三分支); refit 侧派生 = **CShipRefitDeployment** (vt 0x14295FB98, +32 = ship 对)。+32 = 运行时槽 (naval = 0 / refit = ship 对); +40 = 有效位单例指针 (ctor sub_140AC4DD0, ICAW 写门之一); +48 ICAW 池 vt = CEquipmentArcheTypePool (写门 = 非全空 sub_141010B70 ∧ +40 非空)。

#### 4.8.3 names 容器 (176B 元素)

names 容器 (元素内 {data@+248, count@+260}, 176B 元素; writer
0X14145B6F0→0X1409C9AC0; naval(57) 与 railway_gun(75) 产线均持 —
元素 = **CNameGroupMember** (vt 0x142935B18, 75 线活体 RTTI 直证),
铁路炮产线落盘键 = railway_gun_lines (10779), 分派 writer 0X140E5D3B0
按变体类谓词 sub_140C884B0 选键):

| 偏移 | 类型 | 名称/语义 | 写门/备注 |
|---|---|---|---|
| +8 | uint32 | type | |
| +9..+79 | — | type@+8 (默认 **2**) 尾 + **std::string 32B@+16** (名字串, 运行时) + 标量 u32@+48 (默认 −1) + u32@+56 (0) + u64×2@+64/+72 (日期嫌疑) + **equipment 宿主指针@+80** (writer: id 对 *(ne+80)+8/+12) (ctor 0X140C0BA10) |  |
| +80 | 8B | equipment id 对 (指针→{type@+8, id@+12}) | |
| +81..+127 | — | equipment 宿主尾 + **id 对 {type@88, id@92}** (默认无效对) + **第二 std::string 32B@+96..+127** (运行时, 语义未名)  |  |
| +128 | uint32 | name_order | |
| +136 | string | override | **门 = size uint32@+152 ≠ 0** (⚠ 把 size 当指针读会致 SSO 短串漏读) |
| +137..+167 | — | override 串体尾 {size u32@+152 ≠0 门, cap@+160} + pad  |  |
| +168 | uint8 | is_name_ordered | writer sub_1409C9AC0: **==0 才写恒值 no** (≠0 不写; 与 codename 同函数同规则) |
| +169 | uint8 | override_set_prog | |

#### 4.8.4 refit (71) 附加 (偏移相对生产线元素)

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +260 | u32 | tf.type — id 对之 type (对) | 分别条件写, 非三选一 |
| +264 | u32 | tf.id — id 对之 id | 分别条件写, 非三选一 |
| +265..+275 | — | CShipRefitDeployment 内联@+248: tf 对 {260/264} 尾 + **base u32@+276** (仅无 tf 对时写)  |  |
| +276 | uint32 | base | 前两者全空时 |
| +280 | u32 | ship.type — id 对之 type (对) | 分别条件写, 非三选一 |
| +284 | u32 | ship.id — id 对之 id | 分别条件写, 非三选一 |
| +285..+335 | — | refit dep 尾 + 附加区: ship 对 {280/284} 尾 + null 单例指针@+288 + ICAW 头@+296 + u64=0@+304 + **运行时容器 {d@312..328}** + **original_eq_cost i64@336 (≠0 门)** 头  |  |
| +336 | 匿名结构 (NNB 形状) | original_equipment_cost (×1e-5) | |

#### 4.8.5 general 线特化 — building (59)

> **外部驱动入口**: 建筑队列项**只**住在 ps+112 general_lines（type 59），
> 不在 ps+88 lines（那里 type 56/57 = 军/海线）。故"当前在建建筑条数" =
> 遍历 general_lines 数 +8==59 的元素; 按 CBuildingReference 查既有队列线 =
> sub_140E5CF90(cm, ref, 0, 0) 非零即存活。外部排产命令 = CAddConstructionCommand
> (§4.33.18)。类绑定 = **CBuildingProductionLine** (vt 0x14297B958, sizeof 176,
> ctor 0x140F6A540, writer 0x140F6E660 / reader 0x140F6E1C0); 中间层 =
> **CGeneralProductionLine** (无独立 vt): +80 CGameDate (hours@+88=43808760) /
> **+96 CGameDate created_date (tok 15102, hours@+104)**。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | CString 32B | building (tok 10319): 建筑定义名 (写前小写化 sub_1410DB880); GUI 侧经 CBuilding 块取 template = token@(*(bld+480)+8), location = uint32@(*(bld+472)+108) |
| +120 | u32 | to_repair (tok 12570): >0 才写 |
| +121..+139 | u8@128 / u32@132 / u32@136 | relative 对@144 前: **u8@128 (ctor 0) / u32@132 (ctor 0) / u32@136 = sub_140689030(*(owner+656)+8, *(bld+480), 1) 计算值** — 三者未入档 |
| +140 | uint8 | conversion (tok 13609) |
| +144 | id 对 | relative (tok 734): ≠哨兵才写 |
| +152 | uint8 | **is_subject (tok 10835)**: 属国建筑 |
| +153 | uint8 | **allied_build (tok 10187)**: 同盟代建 |

#### 4.8.6 general 线特化 — rail_way (4713)

类绑定 = **CRailwayProductionLine** (vt 0x142A2BE90, sizeof 168, ctor 0x141A01D90, writer 0x141A046E0 / reader 0x141A041D0)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | uint32 | base (tok 11398): 当前铁路等级 |
| +116 | uint32 | target (tok 107): 目标等级 |
| +117..+127 | +112 base/target 对尾 + **u8 cancel (tok 10469, ≠0 写)@+120** + path {d@128} 头 3B  |  |
| +128 | uint32 | path 容器数据指针 — {data, count} uint32 数组 (**rail_way (tok 19649) 沿途省 id 序列**) |
| +129..+139 | path 容器内部: data 尾 + **cap@+136**; path {d@128, cap@136, c@140, alloc@144}  |  |
| +140 | u32 | path 容器计数 |
| +141..+151 | path {c@140 尾, alloc@144} + **current_province i32@152** 头  |  |
| +152 | int32 | current_province (tok 12066) |
| +160 | fixed×1e-5 | remaining_hours (tok 15134) |

#### 4.8.7 general 线特化 — railway_gun (76)

块键 = general_lines.railway_gun 子族, 与 building/rail_way 同 [N] 计数
(探针定案)。类绑定 = **CRailwayGunRepairLine** (120B, vt 0x14297C100,
writer 0x140F70E60 / reader 0x140F70C80; CReferenceObject type = 76);
+112 = railway_gun (tok 19732) 受损炮单位 id 对, 键控块+id 序列。
⚠ 272B 的 **CRailwayGunProductionLine** (vt 0x14297BFC8, writer
0x140F70E10 / reader 0x140F70C60) 不住本容器 — 住 ps+88 生产线容器,
CReferenceObject type = **75** (TGW AUS save 定案 `id=1 type=75`),
落盘键 = railway_gun_lines (10779, feature 35 门), 内容 = 军线尾全量 +
names 容器 (§4.8.3); +96 内部名串 writer 不发。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | u32 | 产出铁路炮.type — id 对之 type (id 对 {type@+112, id@+116} — 与 rail_way base/target 同槽异义 (GER el: 74/2 → `railway_gun id=2 type=74`; 门任≠0)) |
| +116 | u32 | 产出铁路炮.id — id 对之 id |

#### 4.8.8 生产面板 GUI 消费链

cc+1464 生产修正族索引定名 (索引→名离线映射 = 注册器 sub_1405574D0 显式
index 注册点解析, 2669 点 → 712 项); 消费入口 = Repopulate sub_14055E360 与
sub_1415C9EB0/sub_1415CA060:

| 修正索引 (cc+1464) | 名称 | 语义 | GUI 消费 |
|---|---|---|---|
| 0xA5 | line_change_production_efficiency_factor | 效率损失 | efficiency_loss |
| 0xA8 | out_of_power_impact_factor | 停电影响 | — |
| 0xA9 | production_factory_max_efficiency_factor | 效率上限 | efficiency_cap |
| 0xAA | production_factory_efficiency_gain_factor | 效率增长 | efficiency_growth |
| 0xD4 | industrial_capacity_factory | 生产输出 (×ps+936 民用池因子 <1e5 改写输出公式) | production_output_value |
| 0xD6 | industrial_capacity_dockyard | 造船厂输出 | dockyards_output_value |
| 0xD9 | industry_air_damage_factor | 工厂轰炸防御 | factory_bombing_defence_value |

行换装/转换门 = 线+236 is_converting ∧ 变体内部 (宿主+1008→+1016/+1366/+1180);
命令 = 行 vt[18] 0X141D61290 → CSetProductionLineConvertCommand。

#### 4.8.9 民用工厂池字段与工具提示锚点

**获取**: `ps = *(cc + 3944)`; 民用池基址 = `ps + 880` (四池之一, §4.8)。

工具提示函数 **sub_141711C10**(cc, 输出串) 逐项消费下列槽, loc key 即槽语义的
铁证; 探针 (GER 1937, 8 条在建) 与 GUI 工具提示七项逐项一致。

| 池内偏移 | 绝对偏移 | 类型 | 名称/语义 | 工具提示锚 (loc key) |
|---|---|---|---|---|
| +0 | 880 | uint32 | controlled 工厂数 | — |
| +4 | 884 | uint32 | owned 工厂数 (推定) | — |
| +8 | 888 | fixed×1e5 | **工厂总量 (val)** | PRODUCTION_CIVILIAN_FACTORIES_TOTAL (`v5 = *(qword)(888)/1e5`) |
| +16 | 896 | fixed×1e5 | **可分配总量** (工具提示 sub_141711C10: `+896/1e5 − +904 owned` → PRODUCTION_CIVILIAN_FACTORIES_FROM_OCCUPATION; 亦作 …_CURRENTLY 被减数) | 高置信 |
| +24 | 904 | fixed×1e5 | **自己拥有** | PRODUCTION_CIVILIAN_FACTORIES_OWNED (`v8`) |
| +32 | 912 | fixed×1e5 | **可用公式减项 #1** (项目占用) | 未使用公式 `v112` |
| +40 | 920 | uint32 | **建造已分配产线工厂** | 未使用公式 `v7` |
| +48 | 928 | fixed×1e5 | 探针 = +16 同值 | — |
| +56 | 936 | uint32 | **池状态门** (布尔门 `+936!=0 && +928==0`; 探针 11922) — 非 factor: 全 dump 未见于任何算术; 语义待裁 | — |
| +64 | 944 | uint32 | **可用公式减项 #2** (生活消费品侧) | 未使用公式 `v6` |
| +72 | 952 | uint32 | 民用池探针恒 0 (军池 = 上缴宗主, §4.8 主表行) | — |
| +80 | 960 | uint32 | 民用池探针恒 0 (军池 = 外赠目标国) | — |
| +88 | 968 | uint32 | **贸易进口** (FROM_TRADE) | PRODUCTION_CIVILIAN_FACTORIES_FROM_TRADE (`v101`) |

生活消费品与贸易出口**不在池内**, 在 consumer×5 群 (@1072..1191, 值 @对象+16):

| 绝对偏移 | 匿名结构 (NNB 形状) | 工具提示锚 (loc key) |
|---|---|---|
| 1088 | CConsumerGoods | CONSTRUCTION_FACTORIES_CONSUMER_GOODS (`v105`, 显示为负值) |
| 1112 | CSpecialProjects | — |
| 1136 | CLicensedProduction | — |
| 1160 | CTrade | PRODUCTION_CIVILIAN_FACTORIES_SENT_TO_TRADE (`v109`, 显示为负值) |
| 1184 | CContractPayment | — |


**consumer×5 类结构**（1.19.3 COL 全扫反捞——两版 vt→rtti json 均漏收此族；零漂移）：**基类 = CCivilianFactoryConsumer**（无自身 vtable，非多态数据基）；对象 24B {vt@0, enabled u8@+8=1, u32 对@+12}（值 @对象+16 = 对之低位）。五类 2 槽短表（[0] dtor COMDAT 折叠共享 0x140160D50 + [1] 专属 Update）：

| 类 | 主 vt | Update [1] |
|---|---|---|
| CConsumerGoodsConsumer | 0x1429705F0 | 0x1419FE790 |
| CSpecialProjectsConsumer | 0x142970608 | 0x1419FE920 |
| CLicensedProductionConsumer | 0x142970620 | 0x1419FE820 |
| CTradeConsumer | 0x142970638 | 0x1419FE9B0 |
| CContractPaymentConsumer | 0x142970650 | 0x1419FEFE0 |

> 1.19.3 编译期 COMDAT 折叠让五类 dtor 共享同一函数（0x140160D50）。
> 类序 (CConsumerGoods → CSpecialProjects → CLicensedProduction → CTrade →
> CContractPayment) 由工具提示用法互证: 生活消费品读 @1088 = 对象 0+16,
> 贸易出口读 @1160 = 对象 3+16, 与类名逐位对应。

空闲民工 (= 引擎 available_for_projects) 由 getter **sub_140E68350(ps)** 计算:

| 项 | 表达式 |
|---|---|
| 现值 | `(int)*(qword)(ps+888)/100000 − (int)*(qword)(ps+912)/100000 − *(u32)(ps+944)` |
| 钳制 | 负值回 0 (断言 `NumFactoriesAvailable >= 0`, production.cpp:4628) |
| GUI 互证 | 未使用 = 全部 − 生活消费品 − 建造; 探针 GER: 197 − 69 − 128 = 0 = GUI「未使用 0」 |

> sub_140E6A540(ps) 是同式的**可否再开一条产线**谓词: 同式减 `*(u32)(ps+920)`

#### 4.8.10 升级交付/许可/火箭/贸易运输族 (类名绑定)

CUpgradeDelivery (升级交付元素, 96B; vt 0x1429D1ED0; CPersistent@0 + CEquipmentDelivery@8; writer 0x141510680 / reader 0x14150F100; CEquipmentDelivery 无独立 vt = 抽象中间层负定案):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | u32 | status (208) | 交付状态 |
| +16 | fixed×1e-5 | progress (11013) | 仅 status==1 写 |
| +24 | fixed×1e-5 | total_progress (13818) | ≠100000 写 |
| +32 | CString 32B | produced (12204) | 产出装备变体名 |

CUpgradeLevel (升级等级定义, 288B; vt 0x1427DF298; **writer = CFG 空桩 = 只读定义类, 不入档**; reader 0x140625AD0): +8 CModifier 内嵌 (modifier 10597) / +200 效果子对象 (complete_effect 14341); 同级管理器键 level(10348)/ai_will_do(10819)/visible(11562)/frame(252)/sound(441)/picture(464)/modifiers_during_progress(15689)。

CEquipmentProductionLicense (生产许可, 88B; vt 0x1429C0C38; writer 0x14143B6D0 / reader 0x14143AC70; 宿主 = CProductionStatus+400 CLicensedProductionStatus 容器, licensedproduction.cpp 断言):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | u32 | lended_cic (13770) | 租借民厂数 |
| +12 | u32 | required_cic (13459) | 需付民厂数 |
| +16 | u32 | owner (10302) | 持证国 (CCountryRef, tag 名串落盘) |
| +20 | u32 | giver (12500) | 授予国 |
| +24 | CGameDate | — | 未序列化 (语义未决; 非起始日期 — start hours 实@+32) |
| +40 | CGameDate | start_date (10464) | 起始日期 — ADEC0 序列化代理锚; hours 实值 @+32 (代理−8) |
| +56 | 匿名结构 (元素待裁) 向量 | equipment (12110) | 授权装备变体 id 序列 |
| +80 | CEquipmentProductionLicense* | parent (135) | 母许可 id 块 |

CRocketProductionLine (火箭产线, ~120B; vt 0x14297C260; **不经 CProductionLine 支系 — CReferenceObject+CPersistent 直系**; writer 0x140F71830 / reader 0x140F71530; 宿主容器 = ps+136 rocket_lines(13304)):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | u32 | id | 自身 id (与 +12 type 构成 id 对, 联合发射) |
| +12 | u32 | type | id 对 type 半 (联合门, 与 +8 成对) |
| +24 | std::string 32B | — | 名称 (运行时) |
| +56 | CProductionStatus* | — | owner 反指 |
| +64 | CEquipment* | equipment_variant_index (13891) | 火箭装备引用 |
| +72 | 匿名结构 (NNB 形状) | building (10319) | 发射场建筑名 |
| +80 | CRocketDeployment* | deployment (12181) | 部署目标 (32B: vt 0x14295FBE8, +24 = base 11398 >0 写) |
| +104 | fixed×1e-5 | produced (12204) | 已产出 |

CConvoyShip (护航舰, ~72B; vt 0x142A3AC18; writer 0x141AD8690 / reader 0x141AD8240; convoy_ship.cpp:54 断言):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | u32 | id | 自身 id (与 +12 type 构成 id 对, 联合发射) |
| +12 | u32 | type | id 对 type 半 (联合门, 与 +8 成对) |
| +24 | CEquipmentVariant* | equipment_variant_index (13891) | 船型变体 |
| +32 | fixed×1e-5 | strength (10406) | ctor = min(100, *(variant+744)) |
| +40 | fixed×1e-5 | organisation (11979) | ctor = min(100, *(variant+736)) |
| +48 | id 对 | client (202) | 护航队客户 |
| +56 | id 对 | transfer_navy (14443) | 转运舰队 |
| +64 | u32 | tag (10754) | 所属国 (写优先取解析后 client+24) |
| +68 | u32 | convoy_index (15579) | 编队序号 |

CSunkConvoyInfo (沉船记录, ≤32B; vt 0x142973C28; writer 0x140EB39E0 / reader 0x140EB3820): +8 month(123) / +12 convoys(12386) / +16 killer_country(13555) / +20 owner(10302)。

CNavalBaseConvoyClient (海军基地运输客户; vt 0x1429A29C0; writer 0x140CBE140 = CConvoyClient 基字段全量 / reader 0x140CB73D0; 自身增量不序列化; **id 对仅 +16 旗置位才写**): +24 country(10394) / +32 CConvoySubscriber 内嵌 (convoys_subscriber 15717, 门 = +44≠0) / +72 efficiency(13799) / +80 efficiency_due_to_lost_convoys(15592) / +88 combat id 容器 / +112 spotter(15488) / +120 request(12613)。

CResourceExchange (资源贸易单, 240B; vt 0x14295C410; writer 0x140CBEEC0 / reader 0x140CB8E10; trade.cpp:3023 断言):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +128 | CTrade* | — | owner 反指 (注册 *(owner+1832)+24×idx) |
| +136 | u32 | receiver (198) | 接收国 |
| +144 | CResource* | resource (12388) | 资源定义名 (写 = *(def+8) token) |
| +152 | fixed×1e-5 | delivered (12489) | 已交付量 (reader 负值钳 0) |
| +160 | CState* | destination (12480) | 目的州 (写 = *(state+88) id) |
| +168 | CState* | origin (12473) | 来源州 |
| +192 | CGameDate | start_date (10464) | 起始日期 |
| +216 | CGameDate | last_recalc_date (11564) | 末次重算日期 |
| +224 | u32 | required_cic (13459) | 需付民厂 |
| +228 | u32 | lended_cic (13770) | 借出民厂 |

⚠ CResourceExchange 四 CGameDate 值槽交错 (vt@176/192/200/216, 值槽精确配对**待裁**, 键位不受影响)。
> 后逐条累加 `*(line+24) − dword_143336078` (遍历 ps+112 general_lines),
> 累加值 ≤ 0 即返 1。

> ⚠ **民用池 +64 与军池 +64 语义不同**: 军池 ps+752 = 转出合计 (≡ +72++80,
> 探针恒 0 未反证); 民用池 ps+944 在 GER 探针 = 69 而 ps+952/ps+960 恒 0,
> 故 "+64 ≡ +72++80" 对民用池不成立 — 勿按军池外推 (探针 GER/i2/i3 三例)。

> ⚠ **总量已含贸易项**: 探针 GER 总量 197 = 自己拥有 173 (ps+904) + 贸易
> 24 (ps+968, 工具提示 loc key = PRODUCTION_CIVILIAN_FACTORIES_FROM_TRADE;
> 中文界面把该项显示为「贸易出口」); 故可用工厂公式**不再**单独加减 ps+968。

#### 4.8.11 MIO org 附属块 (cooldown / history / variables / flags; writer 0X140DBCCC0)

| 项 | 偏移 (org) | 名称/语义 | 写门 |
|---|---|---|---|
| cooldown | +400..+431 区 (24B date 闭合, vt1@org+400) | ADEC0 族 hours = ptr−8 @{org+408} | 门 byte@org+424 ≠0 (writer `if(b@424) ADEC0(0x391E,+416)`; 未设时该区垃圾) |
| history.data.units | +56 | i32 | ⚠ 引擎按 i32 写 (bi4-8 units=-2 被 u32 直打 4294967294) |
| history.data.date 窗上界 | — | 3 亿小时 | ⚠ 过窄窗会夹掉高时值 (IRIS "3090.x" ≈70.87M) |
| variables | CVariables 内嵌@org+448 | ADEC0 0x2A4A | 无门 (writer 尾部; kr1 探针 vt+16 槽 = 0X140BC9280 CVariables writer 同构) |
| flags | CFlagStore 内嵌@org+504 | ADEC0 0x29C9=10697 | 无门; {entries@+8, count@+20}, 条目 0x30B 同国家侧 (kr1 8/8 对平) |

⚠ mask=0 空 CVariables + rh_iter count 兜底分支 = 误读 +16 扫静态哨兵桶出垃圾名 (kr1 实证) — 桶走查前必须 gate mask>0。

#### 4.8.12 NIndustrialOrganisation::COrganisation (MIO 实例; sizeof 536)

RTTI `NIndustrialOrganisation::COrganisation`; vtable 0x142967A28 (10 槽)。基链 `CReferenceObject@0 ← CPersistent@0` (CPersistent 抽象无实体虚表, §4.00.1) + `TListenableTrait<USOrganisationListener, USEnqueuedOperations>@24` (数据基)。序列化走 CPersistent 槽: writer = 槽 [2] 0X140DBCCC0 / reader = 槽 [4] 0X140DBB350。ctor = 0X140DB3C80(`def = COrganisationTemplate*`, `属主国 tag*`)。创建链 = `CProductionStatus` 遍历 mio_organisation 库 (0x332ef48; def 表 {d@+96, c@+108}) → 逐 def 过 `def+536` 条件块虚槽 [3] → ctor → 入 `PS+304` industrial_organisations 容器 (§4.8)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | 0x142967A28 |
| +8 | idpair | 实例 idpair (哨兵 qword_14333D528); 基类持久化键 `id` |
| +16 | uint8 | 基类附旗 (ctor=0) |
| +24 | 匿名结构 (NNB 形状)* 向量 | 监听者容器 {data@+24, cap@+32, count@+36, alloc@+40}; 变更通知枚举 0X1406C82D0(+24) |
| +48 | 匿名结构 (NNB 形状)* | 第二监听挂接槽 — 单指针 8B, ctor 零填, 无 writer/loader 键 (运行时由列表行 SetTarget 挂接); 不序列化 |
| +56 | token | MIO 名 token (身份, ctor = `*(def+8)`; 初 357 `none`) |
| +64 | MSVC 串 | 显示名缓存 ({data, cap@+88=15}; ctor 取 token 名, `set_mio_name_key` 覆写为本地化名) |
| +96 | MSVC 串 | name_key (cap@+120=15) |
| +128 | MSVC 串 | icon (cap@+152=15) |
| +160 | fixed×1e-5 | research_bonus (qword) |
| +168 | uint32 | task_capacity 原始值; 生效值 = ×`MODIFIER_MIO_TASK_CAPACITY` 经 0X140DB9860, 特性门 define `ENABLE_TASK_CAPACITY` |
| +176 | fixed×1e-5 | research_assign_cost (ctor = define `ASSIGN_DESIGN_TEAM_PP_COST_PER_DAY`) |
| +184 | fixed×1e-5 | production_assign_cost (ctor = `ASSIGN_INDUSTRIAL_MANUFACTURER_PP_COST_PER_DAY`) |
| +192 | int32 | design_team_change_cost (ctor = `DESIGN_TEAM_CHANGE_XP_COST`) |
| +200 | fixed×1e-5 | funds_gain_factor (ctor = 1.0) |
| +208 | fixed×1e-5 | size_up_requirement_factor (ctor = 1.0; 不入档) |
| +216 | 匿名结构 (元素待裁) 向量 | 指派任务容器 {data@+216, cap@+224, count@+228, alloc@+232} (元素 24B; 入档无) |
| +228 | uint32 | num_assigned (上容器 count 本身) |
| +240 | rh 表 | 指派历史 robin-hood {data@+248, count@+256, mask@+260, extra@+264, maxload@+268} (元素 64B, 子表见下) |
| +272 | COrganisationTemplate 子库* | def 特质子库 (= def+136); 特质查找 0X140A53660 / 表 {d@+152, c@+164} / 另表 {d@+184, c@+196, 984B 元} |
| +280 | COrganisationTemplate 子库* | def 条件块 (= def+536); available / visible 门 (0 → 谓词恒真) |
| +288 | tag_id | 属主国 tag (ctor 入参) |
| +296 | fixed×1e-5 | funds (qword) |
| +304 | uint32 | size (规模等级) |
| +308 | uint32 | trait points (字段名 `_TraitPoints`; 解锁特质递减) |
| +312 | uint8 | auto-designs 开关 (ctor=1) |
| +320 | std::set | 已解锁特质集 {sentinel@+320, size@+328} (元 16B, 子表见下) |
| +336 | 匿名结构 (元素待裁) 向量 | queued_trait vector {data@+336, cap@+344, count@+348, alloc@+352} (元 16B, 同下子表) |
| +360 | uint32 | 解锁队列处理游标 |
| +368 | uint32 向量 | allowed_policies vector {data@+368, cap@+376, count@+380, alloc@+384} (元素 u32 政策 id) |
| +392 | token | 当前附着政策 (初 19479 `undefined`) |
| +400 | 匿名结构 (NNB 形状) | policy cooldown 区 (+400..+447; 载荷@+416, 存在旗@+424; 子字段见 §4.31.41) |
| +448 | CVariables 内嵌 | variables (子布局见 §4.31.41) |
| +504 | CFlagManager 内嵌 | flags {vtable@+504, data@+512, count@+524, alloc@+528}; 条目 48B 见 §4.13.3 |

元素子表 — +240 指派历史 rh 表 (64B 元):

| 元内偏移 | 类型 | 名称/语义 |
|---|---|---|
| +4 | uint8 | 占用标 (rh 距离) |
| +8 | idpair | equipment (装备原型) |
| +16 | 匿名结构 (NNB 形状) | data (嵌套落盘于键 240) |

元素子表 — STraitId (16B, 用于 +320 集与 +336 队列):

| 元内偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | `NIndustrialOrganisation::STraitId` 虚表 (嵌套读经其槽 [3]) |
| +8 | token | 特质 id (队列哨兵/未设为 19479 `undefined`) |

**落盘序契约**: 本表行序**非**落盘序; 引擎落盘序 = writer 行序 — `id` → `name` → `icon` → `research_bonus` → `task_capacity` → `funds` → `size` → `points` → `unlocked` (逐元) → `queued_trait` (逐元) → `allowed_policies` (块) → `policy` (≠19479) → `cooldown` (门 b@424) → `variables` → `flags` → `upgrades` → `history` (逐条, 内嵌 `equipment`/`data`) → `research_assign_cost` → `production_assign_cost` → `design_team_change_cost` → `add_mio_funds_gain_factor`。

**不入档字段**: +16 / +24 / +48 / +64 / +208 / +216 / +228 / +272 / +280 / +288 / +360 — 载入后由 def 与 ctor 入参重绑; +216 指派任务容器与 +228 num_assigned 亦不在本类落盘范围 (重建路径未展开 — 待裁)。

**写点要点** (`mio` = COrganisation 真身; 全为行为锚定 + 键对双证):

| 效果/触发器 | 行为 |
|---|---|
| add / set_mio_research_bonus | `sub_140DB4A80` 加 (负钳 0) / 裸写 `*(mio+160)` |
| add / set_mio_task_capacity | `sub_140DB4AC0` 加 (负钳 0) / `sub_140DBBA10` 裸写 `*(mio+168)`; 尾调 0X140DBBEB0 = 容量生效重算 (define 门 + `MODIFIER_MIO_TASK_CAPACITY` 缩放) + 超编任务自 `mio+216` 尾部卸载 (`sub_140DB61F0(task, *(mio+288))`) |
| add_mio_size | `sub_140DBBB60(mio, n)` = size/points 同增 `*(+304)/*(+308)`, 国侧聚合 (`*(mio+288)` 解国 → `_InterlockedAdd(obj+292, n)`), 触发 `on_mio_size_increased` |
| complete_mio_trait | `sub_140DBBB60(mio, 1)` + `sub_140DBC860(mio, trait)` = `STraitId{*(trait+8)}` 插入 `mio+320` 集 + `--*(mio+308)` (断言"已解锁不再解锁"/"需有点数") |
| add / set_mio_funds | `*(mio+296)`; 写经 `sub_140DBBC50` (满额自动升级循环) + 监听者通知 `sub_1406C82D0(mio+24, …)` |
| is_mio_assigned_to_task | `*(mio+228) > 0` |
| has_mio_size / has_mio_number_of_completed_traits | `*(u32)(mio+304)` / `*(u32)(mio+328)` (集 size) |
| has_mio_trait / is_mio_trait_completed | `*(mio+272)` def 查特质 / +320 集成员 |
| has_mio_policy / has_mio_policy_active | `mio+368/+380` 政策表线性查 / `*(mio+392)` 全等 |
| is_mio_available / is_mio_visible | `mio+280 == 0` → 真; 否则取 def 条件块可用条 (cond+88, count@+108) / 可见条 (cond+176, count@+196), 父链回落 `*(cond+856)` / `*(cond+864)`, 求值 0X1413AE4B0 |
| has_mio_flag / set / modify / clr_mio_flag | `mio+504` CFlagManager 条目 (键@+8 / 日期@+24 / i16 值@+40 / days@+42) |
| set_mio_flag / has / is_military_industrial_organization | MIO 身份 token = `mio+56` (= `*(def+8)`) |
| any / all_military_industrial_organization | `include_invisible` 落 **this+328 u8** (parse 键 10177; 消费端 `!*(u8*)(this+328) && !IsVisible(org)` → 跳过) |
| casualties_k / has_mio_number_of_completed_traits | 左端 `100 × Σ(战争关系 rel+80) (= 千人口径 fixed×1e5)` / `*(u32)(mio+328)` |

**MIO 特质 def 布局补行** (COrganisationTemplate+136 特质子库条目; 条件组同族 CLI 条件组形态; 均推定):

| 偏移 (def) | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +528 | 条件组 | 特质条件组 (次组 #1) | 推定 |
| +616 | 条件组 | 特质条件组 (可用组 #1) | 推定 |
| +848 | 条件组 | 特质条件组 (次组 #2; 与 +528 同族) | 推定 |
| +856 | 条件组 | 特质条件组 (可用组 #2; 与 +616 同族) | 推定 |

> **本域 GUI 类布局**: 见 4.31.30 / 4.31.33 / 4.31.41。
