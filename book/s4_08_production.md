

### 4.8 CProductionStatus (生产)

**获取**: `ps = *(cc + 3944)`。

基类子对象 (rtti_hierarchy bases ⚠ 该 ref 件系 1.19.2 谱系快照, vt 列勿直引 — 以 ctor 写点序为准 + ctor 0x140E5BFA0 写点序: 先构子对象后覆写
本类 vftable): CPersistent@+0 / CBuildingListener@+8 (`TListenerTrait<VCBuildingListenable>`
+ CListenerWithMove) / **CStateListener@+16** (vt 0x142A2BD80; 4 槽 [2]/[3] 纯虚;
sizeof 8; 州 owner/controller 变更监听接口基, CState SetOwner 逐元 vt[+24] 消费即此接口)。
三子对象对应三虚表 0x142970708 / 0x142970758 / 0x142970788 (vt_rtti 三条同名记录)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +88 | 匿名结构 (8B 形状) | lines 容器数据指针 | {data, count}, 元素 8B 指针, count<256 | **GUI: 生产线列表建行** (sub_14173FEA0 → production_lines/item_grid) |
| +89..+99 | — | lines 容器内部 | data 尾 (+89..+95) + **cap@+96**; 四元组 {d@88, cap@96, c@100, alloc@104} 补全  |  |
| +100 | uint32 | lines 容器计数 |  |  |
| +101..+111 | — | lines 尾 + general_lines 头 | count@100 尾 + **alloc@104 (哨兵)** + general_lines {d@112} 前 pad  |  |
| +112 | 匿名结构 (NNB 形状) | general_lines 容器数据指针 | {data, count}, count<4096; general_count 亦导出于 +124 |  |
| +113..+123 | — | general_lines 容器内部 | data 尾 (+113..+119) + **cap@+120**; {d@112, cap@120, c@124, alloc@128}  |  |
| +124 | uint32 | general_lines 容器计数 |  |  |
| +125..+231 | — | 中段容器群 (全部 24B pdx 四元组) | general_lines alloc@128 + **rocket_lines {d@136..152}** (块 13304; 元素键 12211) + **available_equipments {d@160..176}** (块 12461) + **运行时容器 A {d@184}** (元素 = CEquipmentVariant*, 不序列化) + **容器 B {d@208}** = **_BestProducibleVariantPerArchetype** (索引 = 原型+1336, count@+220; getter 0x140E684F0 / 更新器 0x140E70D10; 不序列化) + **foreign_lease_equipments {d@232..248}** (块 13049)  |  |
| +232 | CEquipmentVariant* | foreign_lease_equipments 容器数据指针 | 元素 = variant 指针, 无条件写 id 对 |  |
| +233..+243 | — | foreign_lease_equipments 内部 | data 尾 + **cap@+240**  |  |
| +244 | uint32 | foreign_lease_equipments 容器计数 |  |  |
| +245..+511 | — | 容器群 + licensed + 池头 | foreign_lease alloc@248 + **运行时容器 C {d@256}** (AI 装备比较, 不序列化) + **容器 D {d@280}** (不序列化) + **industrial_organisations {d@304..320}** (块 19162) + **policies {d@328..344}** + **运行时容器 E {d@352}** + **named_equipment_bonuses {d@376..392}** (块 10206, 200B 元) + **CLicensedProductionStatus@400 (112B; vt 0x1429C0C88; writer 0x14143B7C0 / reader 0x14143AF10; ctor sub_141436D40; = 4 个同构 24B 容器 + 反指)** {lp+8 = **available (键 12264)** 受让许可表 — 元 = CEquipmentVariant 克隆 1208B {idpair@+8, 接收 tag@+28, 授予 tag@+32, 原型@+1008, 原变体@+1016, license 回指@+1024} / lp+32 = 容器 (语义待裁) / **lp+56 = owned_license (键 14259) = 我持有的许可表 (付费方)** / **lp+80 = 授出许可表 = CEquipmentProductionLicense\* 活跃指针表** (writer 不发但读档由受让国块回填 — 原「运行时容器」误导; **纯运行时容器是 lp+32**) / lp+104 = CProductionStatus\* 反指; +8/+56 引擎存档键自名} + **CEquipmentVariantPool@512** 头  |  |
| +512 | 匿名结构 (16B 形状) 向量 | equipments 池 (12122) | {data@+32, count@+44} 16B 条 {variant*, amount fixed×1e-5} | 写门: amount≠0 或 allow_zero(uint8@+568)==1; **GUI: 市场库存变体量查** (sub_14100EB00) |
| +513..+567 | — | CEquipmentVariantPool 体 | 预留池 {d@520..536} (24B 元, 不序列化) + **序列化装备池 {d@544, cap@552, c@556, alloc@560}** (16B 元 {variant*, amount}) + **allow_zero_entries u8@568**  |  |
| +568 | uint8 | equip_allow_zero_entries | | |
| +569..+607 | — | destroyed_stockpile + scheduler | **destroyed_stockpile_equipment {d@576..592}** (元素 {variant*@0, i64 amount@8 (键 417), CGameDate 到期@16 (键 10314); writer 逐元素一块) + **CCreateEquipmentVariantScheduler@600 (32B)** {vt@600, 容器@608 {d@608, cap@616, c@620, alloc@624}}  |  |
| +608 | CCreateEquipmentVariantSpec* | scheduled_equipment_variants 容器数据指针 | {data@+608, count@**+620**}; ⚠ +616 = capacity 非 count — pop 后 capacity 内残留悬挂槽 (arch 指针仍活→键像真, var 悬挂→字段垃圾 1069219840 类); scheduler vt 0x1429706b8, 池 writer 0X141A00AF0, 元素 16B {arch@0, var@8}; spec 类 CCreateEquipmentVariantSpec **无 hull/train 派生** (泛型 writer 0X141463A90 全型同门); spec 字段: name@+16 / name_group@+48 / icon@+184 / obsolete b@+84 (b84=1 写 yes 正向, 键 12396) / show_position b@+85 (键 398, **反向门**: 值 0 才写, 默认 true 不落盘) / mark_older_equipment_obsolete b@+86 (键 11175, 正向门 ≠0 写 yes; 把同 archetype 更旧版本标记过时) / model@+144 / parent_version@+80 / io id 对@+248 / upgrades {d@+96, c@+108} 16B 条 / modules {d@+120, c@+132} 16B 条 |  |
| +609..+619 | — | scheduler 容器内部 | data 尾 + **cap@+616**  |  |
| +620 | uint32 | scheduled_equipment_variants 容器计数 |  |  |
| +632 | uint32 向量 24B | **enable_equipment_modules token 列表** {d@632, cap@640, c@648} (键 15212; writer sub_140DBD190) | 运行时消费者未收 (MIO/UI 域) | |
| +664 | CCicBank 内联 24B | CIC 银行 | {vt 0x1429705A0 九槽, **value i64@+8 (键 776 value, 有序列化 writer/reader — 原记缺失)**, **reserved i64@+16 = 当期预定账** (提取 sub_14145AAF0 按 max(0, value−reserved) 划扣, 民用分配每轮清零)}; 增压系数 = (1+mod625)×(mod624+CIC_BANK_SPEED_BOOST_FACTOR)/1e5; 清零 sub_14145AAE0; 活体 440 国同 vt |  |
| +672 | fixed×1e-5 | cic_bank | **GUI: 国际市场视图命中** (CCountryInternationalMarketView) |  |
| +673..+1191 | — | 四工厂池 + consumer 群 + 运行时区 | **工厂池×4 (96B 无 vt)**: +688=military / +784=dockyard / +880=civilian / +976=保留 (探针 GER 132/31/168/0; {**+0 u32 = controlled 数 / +4 u32 = owned 数 (num_of_controlled/owned 对偶; 推定)**, **val@+8 = 工厂总量**, **+32 qword = 受损工厂 Σ(1+州修正)×(level−healthy) (tooltip loc key PRODUCTION_CIVILIAN_FACTORIES_DAMAGED 铁证 + SetLevel +66=healthy; )**, **dword@+40 = 已分配产线工厂**, dword@+56 (ps+936) — **定案 = 电力覆盖率 min(1, 能源产量/能源需求)** (重置默认 1.0 sub_140E66060; 真值写者 sub_140E6AE80: 煤预留→产量 ps+1288→min(1e5, 1e5×产量/需求) 写三池; 控制台 Energy Ratio 命令全局覆盖槽 qword_14332F688 (钳 0..1e5, ≥0 时替换三池真值); 能源资源 = coal, ps+1264 def tok 20005, amount=已预留煤/need=缺口); 活探针 14 国次恒 1.0 = 煤覆盖足够时的钳制上限 (GER 产量 2755 ≥ 需求 2749.24), 非常量; 消费 = 单厂速度 lerp (sub_1415C9B40) + 缺电惩罚 (sub_1415CA210); 总需求链: +928 求和 → ps+1336 ×单厂能耗成本 = ps+1328 (单厂成本 = min(ENERGY_COST_CAP 6.6, BASE_ENERGY_COST 0.25 + SCALING_COST_BY_FACTORY_COUNT×(Σ池val−出口折减)/1e5), 出口折减 = ENERGY_SCALE_PER_TRADE_FACTORY_EXPORT×(1+mod399); GER 416.55×6.60=2749.24 精确闭合) — 另 **dword@+48 (ps+928) = 工厂能耗需求权重 (定案)**: 写点 sub_140E64510 `+48 += v20×v18×level/1e5` (v18 = 1e5+州修正 LOCAL_FACTORIES(65); v20 = 1e5+国修正 FACTORY_ENERGY_CONSUMPTION(398)+州 LOCAL_FACTORY_ENERGY_CONSUMPTION(397)+每级基建能耗(657)×基建); sub_140E64B90 经 ps+1296/1304/1312 三池指针表求和 → ps+1336; 曾记「消费品百分比样值」「恒 = +16 同值」两说均废; 六国活值 1.0~2.0 量级与此公式吻合), **+64 = 可用工厂公式减项 (军池 = 转出合计 ≡ +72++80; 民用池 = 生活消费品侧 (tooltip 可用 = 总量−受损912−建造920−消费侧944; 材料在 §4.8.9 本节) — ⚠ 四池此槽语义不同, 勿按军池外推)**, **+72 = 上缴宗主 (mic_to_overlord_factor) / +76 = 受赠所得 / +80 = 外赠目标国 (mic_to_target_factor)** — 军池定案, 写入 sub_140E6C810/sub_140E611B0, 即 UI 侧 ps+696/+728/+752/+760/+764/+768/+792}) + **consumer×5 @1072..1191** {vt, enabled u8@+8, u64 双 dword@+12, **值 @对象+16**} (顺序 CConsumerGoods@1072 / CSpecialProjects@1096 / CLicensedProduction@1120 / CTrade@1144 / CContractPayment@1168 — 类序由工具提示 loc key 用法互证) + dirty@1192 + 运行时快照 6B @1194 u32 + 1198 u16 (资源存量变更检测缓存) + **max_factories_for_repair@1200** + **运行时容器 F {d@1208}**  | **GUI: 运营军工厂双读数** (军池 val@696÷1e5 −分配760 −768 / −728 −752; sub_141743200→sub_14173B2D0 → PRODUCTION_OPERATIONAL_FACTORIES_VALUE) **+ 造船厂读数** (船池 val@792 → dockyards_output_value) **+ tab 使能** (军厂钮 ps+696>0 / 船厂钮 ps+792>0; sub_141739E20) **+ 占用条** (military_factories_usage bar=100−比例; naval_factories_usage × sub_140E69130) **+ 民用池全项工具提示** (§4.8.9 表; 原 §4.31.30 引用断链说废 — 该节是工厂格行件) |
| +1192 | uint8 | dirty (键 13444) | | |
| +1200 | uint32 | max_factories_for_repair | **唯一写者 = sub_140E711A0 (hourly, 自 sub_140E696E0)**: `min(旧值, ceil_1e5(INITIAL_ALLOWED_FACTORY_RATIO_FOR_REPAIRS × ((ps+888)/1e5 − ps+944))/1e5)`, 单调不升; Reset sub_140E65BB0 置 0 → 战时自由民厂 0 即恒 0 (探针 440 国全 0); define 装载器钳 [0,1e5] (defines_game.h:258) | |
| +1201..+1255 | — | discount + resource cost | **discount {d@1232..1248}** (块 10202, 40B 元 {uses u32@0 (13285), i64 值@8 (10202), types token 列表@16 (12300)}) + **CProductionResourceCost@1256 (32B)** {vt, resource def*@1264 (= null_object 单例 → "none" 占位根因), amount@1272, need@1280} (块 12781) |  |
| +1256 | 匿名结构 (NNB 形状) | energy_production_cost | amount fixed×1e-5@+16, need@+24 (恒 0), resource token@(*(ps+1264)+8) | |
| +1257..+1351 | — | 运行时聚合区 | 聚合 u64@1288 (探针 ENG=550.0) + **工厂池内指表 {1296→880 民用, 1304→688 军用, 1312→784 造船厂}** (探针差值 192/96 实证) + 四经济聚合 i64@1320..1344 (探针 FRA 50.30/462.72/137.00/3.3775) + **last_named_equipment_bonus i32@1352 (ctor 默认 −1 非 0)**; 对象总大小 1360B  |  |
| +1352 | int32 | last_named_equipment_bonus (ctor 默认 −1; 键 16749) | | |

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

运行行为槽契约 (daily 推进链消费, 定案):

| 槽 | 军线族 (CEquipmentProductionLine) | general 线族 (CGeneralProductionLine) |
|---|---|---|
| [10] | sub_14193A460 日重算 (fe 扩容/钳制 → 成本重算 → 资源再预留 → 速度) | — |
| [11] | GetMaxAllowedFactories | 同 (建筑线请求钳界) |
| [14] | GetProductionRate (out 参) | — |
| [17] | SetAmount | — |
| [19] | — (building: OnUnitCompleted — 单位建成回调) | — |
| [24] | — | 日推进: building=sub_140F6A710 / railway=sub_141A02660 / repair=sub_140F70100 |
| [25] | — | 删除谓词: building=sub_140F6E160 (无 relative ∧ 完建) / railway=sub_141A03A60 / repair=sub_140F70BE0 |
| [26] | — | IsRepair (民用分配修复线优先门) |
| [28] | GetInputResources (16B 元 {量 qword, 资源 token u32@+8}) | — |
| [30] | 产出推进: military=sub_140F6E840 / naval=sub_140F6F050 / railway_gun=sub_140F6FAC0 (基类 _purecall) | — |
| [32] | GetBaseCost 0x1419382B0 | — |

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
| +100 | uint32 | resources 容器计数 |  |  |
| +101..+135 | — | 军线 resources 尾 + 运行时区 | alloc@104 + **运行时容器 {d@112, cap@120, c@124, alloc@128}** + variant 宿主@136 前 pad  |  |
| +136 | CEquipmentVariant 引用宿主* | equipment_variant | id 对 {type@+8, id@+12} | |
| +144 | uint32 | industrial_manufacturer.type — id 对之 type (id 对) | 任一非零才写 |  |
| +148 | uint32 | industrial_manufacturer.id — id 对之 id | 任一非零才写 |  |
| +149..+191 | — | CTraitBonus 尾 + 运行时容器 + fe 头 | **CTraitBonus 内联@+152** (vt@152, dtor 0X1401516C0) 尾 + **运行时容器 {d@160..176}** + **MIO 特质加成集脏旗 u8@184** (≠0 时 sub_1419382D0 经 sub_140DB7A30(MIO, 原型) 重建加成集) + fe {d@192} 头  |  |
| +192 | int64 | factory_efficiencies 容器数据指针 | i64 Q15 数组 (8 字节步长!); 元素读法 = **整体 read_u64** (Lua integer 精确 64 位) — 禁 lo + hi×2^32 浮点重组 (hi=0xFFFFFFFF 时超 double 53 位精度致值漂移, Red_Dusk 假 DIFF 实证) | **GUI: 生产线效率列数据侧** (0X141937ED0/0X141939760; 行 UI 绑定未决) |
| +193..+203 | — | fe 容器内部 | data 尾 + **cap@+200**; fe {d@192, cap@200, c@204, alloc@208} 元 8B i64  |  |
| +204 | uint32 | factory_efficiencies 容器计数 |  |  |
| +212..+215, +220..+223 | — | 军线尾区垫 | writer 不触 |  |
| +216 | fixed×1e-5 (≤0) | 资源短缺惩罚 | 效率增长减项 (sub_141936210 写 / sub_141935590 读; mod 172 production_lack_of_resource_penalty_factor + PRODUCTION_RESOURCE_LACK_PENALTY qword_143337848 折算) | 定案 |
| +224 | int64×1e-5 | **non_conversion_speed** (tok 14330; 门 = is_converting@+236 置位才写; 换装惩罚补偿速度) | writer 0X141939760 | 定案 |
| +232 | uint32 | **requested_factories** (tok 13769 = 0x35C9; 断言名 nFactories, equipment_production_line.cpp L543) — 线上已分配工厂数; 增减 = CAddProductionLineFactoriesCommand (Execute: 新值=载荷+旧值, setter sub_14193A3D0 clamp ≤ GetMaxAllowedFactories = 线 vt[11] 虚槽 → 变体._pType+1440 (CEquipmentType+1440) → 父arch+1440 → 默认 dword_143335FE0 [实测 150]) | — | 定案 |
| +236 | uint8 | **is_converting** (tok 14304; ≠0 才写, 连带写 +224 non_conversion_speed) — 行换装门 | writer 0x37E0 | 定案 |
| +237 | uint8 | **collapsed_interface** (tok 14608; ≠0 才写 — 行 UI 折叠态, 会序列化) | writer 0x3910 | 定案 |
| +240 | uint32 | **interface_factory_scale** (tok 14679; ≠1 才写 — 行 UI 工厂格缩放) | writer 0x3957 | 定案 |

#### 4.8.2 naval (57) / refit (71) deployment

deployment 形态分型:

| 类型 | deployment 形态 | 写门 |
|---|---|---|
| naval (57) | 指针@元素+272, writer 0X140D148B0 三分支 (tf 对 / theatre 对@+20 / base; 实测走 base 分支) | — |
| refit (71) | 块内联@元素+248 {tf 对@+260/+264, base u32@+276, ship 对@+280/+284} | base 仅在无 tf 对时写 |
| railway_gun (75) | **无 deployment** (272B 类 +248..+271 = names 容器, 无 +272 槽) | — |

deployment 对象布局 (naval: dep = 元素+272 解引用; refit 形态同构内联):

| 偏移 (dep) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +12 | uint32 | tf.type — id 对之 type (对) | type==16 为哨兵 |
| +16 | uint32 | tf.id — id 对之 id | type==16 为哨兵 |
| +17..+27 | — | **第二 id 对@+20** {type@20, id@24} = theatre 对 — ctor qword_14333D528 默认, writer 第二分支实发 (键 12058) |  |
| +28 | uint32 | base | 实测走 base 分支 |
| +29..+47 | — | base@+28 尾 + naval: u64=0@+32 / refit: **ship 对 {type@32, id@36}** (CShipRefitDeployment 派生增量, 键 10400, sub_140D14990) + naval: null 单例指针@+40 / refit: 0 + naval: **ICAW 块头@+48** (sub_141012160 从 deployment 状态拷入) / refit: null 单例  |  |
| +48 | 内嵌 | initial_carrier_air_wing_deployment: 容器 {data@dep+56, count@dep+68}, 元素 16B {名对象指针@+0 (token@+8), value int64@+8} | |

**类名/基链 (1.19.3 实证)**: 部署对象 = **CNavalDeployment** (80B, vt 0x14295FB48, ctor 0x140D0D2F0, writer 0x140D14860 / reader 0x140D124E0), 基 = **CNavalDeploymentTarget** (vt 0x14295FAF8; 基 writer 0x140D148B0 = tf 对 / theatre 对@+20 / base 三分支); refit 侧派生 = **CShipRefitDeployment** (vt 0x14295FB98, +32 = ship 对, 键 10400 增量)。+40 = 有效位单例指针 (ctor sub_140AC4DD0, ICAW 写门之一); +48 ICAW 池 vt = CEquipmentArcheTypePool (写门 = 非全空 sub_141010B70 ∧ +40 非空)。

#### 4.8.3 names 容器 (176B 元素)

names 容器 (元素内 {data@+248, count@+260}, 176B 元素; writer
0X14145B6F0→0X1409C9AC0; naval(57) 与 railway_gun(75) 产线均持 —
元素 = **CNameGroupMember** (vt 0x142935B18, 75 线活体 RTTI 直证),
铁路炮产线落盘键 = railway_gun_lines (10779), 分派 writer 0X140E5D3B0
按变体类谓词 sub_140C97B90 海军 / sub_140C97C00 铁路炮原型 + 线虚槽 +216 refit 判定选键; 分派逻辑整段内联进 CProductionStatus writer sub_140E71CB0):

| 偏移 | 类型 | 名称/语义 | 写门/备注 |
|---|---|---|---|
| +8 | uint32 | type | |
| +9..+79 | — | type@+8 (默认 **2**) 尾 + **std::string 32B@+16** (名字串, 运行时) + 标量 u32@+48 (默认 −1) + u32@+56 (0) + u64×2@+64/+72 (推定日期) + **equipment 宿主指针@+80** (writer: id 对 *(ne+80)+8/+12) (ctor 0X140C0BA10) |  |
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
| +260 | uint32 | tf.type — id 对之 type (对) | 分别条件写, 非三选一 |
| +264 | uint32 | tf.id — id 对之 id | 分别条件写, 非三选一 |
| +265..+275 | — | CShipRefitDeployment 内联@+248: tf 对 {260/264} 尾 + **base u32@+276** (仅无 tf 对时写)  |  |
| +276 | uint32 | base | 前两者全空时 |
| +280 | uint32 | ship.type — id 对之 type (对) | 分别条件写, 非三选一 |
| +284 | uint32 | ship.id — id 对之 id | 分别条件写, 非三选一 |
| +285..+335 | — | refit dep 尾 + 附加区: ship 对 {280/284} 尾 + null 单例指针@+288 + ICAW 头@+296 + u64=0@+304 + **运行时容器 {d@312..328}** + **original_eq_cost i64@336 (≠0 门)** 头  |  |
| +336 | 匿名结构 (NNB 形状) | original_equipment_cost (×1e-5) | |

#### 4.8.5 general 线特化 — building (59)

> **外部驱动入口**: 建筑队列项**只**住在 ps+112 general_lines（type 59），
> 不在 ps+88 lines（那里 type 56/57 = 军/海线）。故"当前在建建筑条数" =
> 遍历 general_lines 数 +8==59 的元素; 按 CBuildingReference 查既有队列线 =
> sub_140E5CF90(cm, ref, 0, 0) 非零即存活。外部排产命令 = CAddConstructionCommand
> (§4.33.18)。类绑定 = **CBuildingProductionLine** (vt 0x14297B958, sizeof 176,
> ctor 0x140F6A540 / 排产 ctor 0x140F69C90, writer 0x140F6E660 / reader 0x140F6E1C0);
> 中间层 = **CGeneralProductionLine** (无独立 vt): **created_date (tok 15102) hours
> 实值 @+88** (ctor 哨兵 43808760; §4.8.1 通用布局 general 线族行同源), 序列化锚
> = **+96** (代理, 锚−8 = hours; 与 §4.8.10 license start_date 锚/hours 同构);
> **+104 = CIC 增压抽取量运行时槽** (ctor 清 0, sub_141A2F7F0 写, 不落档 — 与
> created_date 无关, 定案)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | CString 32B | building (tok 10319): 建筑定义名 (写前小写化 sub_1410DB880); GUI 侧经 CBuilding 块取 template = token@(*(bld+480)+8), location = uint32@(*(bld+472)+108)。⚠ general_lines 装载器兼容双键: case 10319 (building) 与 12211 (building 全键循环同体) |
| +120 | uint32 | to_repair (tok 12570): >0 才写 |
| +121..+139 | uint8@128 / uint32@132 / uint32@136 | relative 对@144 前: **u8@128 (ctor 0) / u32@132 (ctor 0) / u32@136 = sub_140689030(*(owner+656)+8, *(bld+480), 1) 计算值** — 三者未入档 |
| +140 | uint8 | conversion (tok 13609) |
| +144 | id 对 | relative (tok 734): ≠哨兵才写 |
| +152 | uint8 | **is_subject (tok 10835)**: 属国建筑 |
| +153 | uint8 | **allied_build (tok 10187)**: 同盟代建 |
| +160 | CBuilding* | **转换源建筑扣级队列·指针半** (仅 conversion 路径置位; daily_serial 收尾统一 SetLevel(level−1)×count 后清零; ctor 0; 不入档) |
| +168 | uint32 | **转换源建筑扣级队列·计数半** (= 本次转换级数; 不入档) |

#### 4.8.5a 建筑施工执行链

**分工**: hourly 不推进进度 — hourly (相位 5 pass④ sub_1406FDE80 → sub_140E696E0)
只做 ① 民用工厂向建筑线**分配** (sub_140E6D010 → sub_140E6AD10 → sub_140E61320
写线 +24) ② 分配后**速度缓存刷新** (vt[10] sub_140F6E3E0 写 +48) ③ **失效线清扫**
(所在地不可建 → sub_140E6EFA0 拆线, 剩余修理量 >0 转交当地控制国 ps 的
AddConstruction(…, repair=1))。**进度推进 = 每游戏日一次** (daily serial vt[24],
§4.8.13)。

排产入口 **sub_140E5F8C0 AddConstruction(ref, num, repair, conversion)**
(production.cpp:1256-1259 断言): instant 作弊门 byte_14332F628 ∧ 玩家国 → 直接
SetLevel(level+1) + sub_140E6A690 返回 (production.cpp:1272 "Instant cheat enabled")
→ sub_140E5CF90 查既有线 → 无则 malloc(176) + ctor sub_140F69C90 → vt[9] 注册
id {type=59, id=全局计数器+1} → 加入 ps+112 (定案)。简版 sub_140E5D100 无
conversion 参 (CAddConstructionCommand 走此族, §4.33.18)。

daily 线日更 **sub_140F6A710** (vt[24], building_production_line.cpp:529 "_pBuilding"
断言) 八步: ① +136 重算可建上限; ② cost 重算 (+40 = 1e5 × cost, 公式见下);
③ relative 线校验 (有效∧非 is_subject → 早退进度由对方线推进; is_subject →
进度同步写相对线 +56 + 贡献记账 mod291 MASTER_BUILD_AUTONOMY_FACTOR);
④ speed = vt[14] (读 +48 缓存); instant 门 → speed=max(speed,cost);
⑤ produced(+56) += speed; ⑥ 修理分支 (+120>0): sub_140F6A400 修理速度 →
sub_1410DAFD0 恢复 (partial_health@+72 累积钳 1e7, 满 → healthy+1 +
**+80 repair_speed_factor 复位 1e5** + 通知 kind=4); to_repair = level−healthy、
produced=0; ⑦ 建造分支: levels = floor(produced/cost), produced −= cost×levels,
逐级 vt[19] ReduceAmountBy(1) + **SetLevel(building, level+1, 1)** + 相对线同步
扣量/拆线 + sub_140E6A690; ⑧ 转换分支 (+140): 查州内对型建筑 (**BDB+960 = arms_factory 军工 / BDB+968 =
industrial_complex 民用 — 探针 token_name 定案**, def+736 类别互换) → 源建筑等级 ≥ levels 时线 +160={源建筑, levels}
入队 + 目标建筑逐级 SetLevel(+1) (定案)。

| 公式 | 内容 | 置信 |
|---|---|---|
| cost (sub_140F69E60) | max(1, floor[(1+mod(国, def+912 成本修正 id)) × (动态项 + def+744 基础 + def+756×当前等级)]) — "Building cost is non-positive" building_production_line.cpp:805; 动态项 = sub_140F69FD0 (def+752 块, 缓存 +124/门+128/级标+132, 失效时扫全国同 def 队列线重算) | 定案 |
| 转换成本 (sub_140F6C770) | def+748 × (1+mod), mod = 159 MIL_TO_CIV / 160 CIV_TO_MIL (按线 def 类别选 BDB+968/+960 侧), min 1 | 定案 |
| 速度核 (sub_140F6D3A0) | loc_factor × 单厂速度×工数 × (mod166 + 缺电调整 + Σmods + 1e5)/1e5 (内层归一后外层再 /1e5 归一 loc_factor 定点); **括号首项 = mod166 PRODUCTION_SPEED_BUILDINGS + 缺电调整 sub_1415C9A40 (= mod166 + sub_1415CA210: 覆盖率≥1e5 → +mod167 POWERED; <1e5 → −mod166×(1e5−max(0,覆盖率×(1+mod168)))/1e5)** — 原「MIO +」项系军线公式串味幻影, 说废 (函数全程无 MIO 输入); 尾钳负值 0; mods = mod(国, def+896) + mod(州RH桶, def+904) + mod(州RH桶, 548 STATE_PRODUCTION_SPEED_BUILDINGS_FACTOR); def+676 设施旗再加 mod(国,630)+mod(州RH,629); 州RH桶 = sub_1409D8B10(state, tag; state+2256 RH 表 208B 条目, 未命中回落 state+1352); loc_factor = sub_1414B7FA0(def): def+1192 ? def+1088 州条件因子表 : 1.0 | 定案 (F2 验算) |
| 单厂速度 (sub_1415C9B40) | lerp(BASE_FACTORY_SPEED qword_1433363C0, POWERED_FACTORY_SPEED qword_1433365B0, max(0, ps+936 × (1+mod168 OUT_OF_POWER_FACTOR))) | 定案 |
| CIC 增压 (sub_141A2F7F0) | 线当日不会完成 (剩余>speed>0) 时从 ps+664 CCicBank 抽取增速, 日上限三因子 = (1+mod625)×(mod624 + CIC_BANK_SPEED_BOOST_FACTOR 0.25)×speed, 钳 ≤ 剩余−speed (country+1448 容器值即 mod 域); **line+104 = 抽取量** (运行时缓存, 不落档; 与 created_date 无关 — created_date hours 实值 @+88, +96 为序列化代理锚, §3.7a); **CCicBank 台账** (vt 0x1429705A0, writer 0x14145ABA0 / reader 0x14145AAB0 键 776 `value`): cap@ps+672 = add_cic 脚本资源 (effect sub_140490030 充值, 持久), used@ps+680 = 当轮已抽 (hourly 清 0), 日结算 cap −= 消耗 (建筑与铁路两族) | 定案 |
| 基建完好度加速 (sub_1414B97F0) | def+876 infrastructure_construction_effect 门: 速度核之外再乘 (1 + INFRA_MAX_CONSTRUCTION_COST_EFFECT(1.0) × 州基建 healthy/上限), 满基建最多 ×2 | 定案 |
| 修理速度 (sub_140F6A400) | (BASE_FACTORY_REPAIR qword_143334340 + 100×speed/cost) × (sub_140F6CD40 因子+1e5)/1e5 × def+848 × building+80 repair_speed_factor, 钳 ≤1e7 | 定案 |

分配阻断门 (sub_140E61320 内, 定案): ① 省建筑 ∧ sub_140E7DDF0(prov,1) 省内有
进行中战斗 (prov+368 数组, CCombat vt[11]==1) → 该线 0 工厂; ② 铁路线
(vt[22]==2) 与 **def 为 rail_way/supply_node (def+880 补给点) 的建筑线** (省
ptr 非空) ∧ 州∈控制者 cc+5592 焦土名单 (scorched_states) → 阻断; 日推进修理
分支对 rail_way/supply_node def 有同款速度归零抑制。分配核: 可用池 = line+24 +
line+28 + (ps+888)/1e5 − ps+944 − ps+920 (line+24 = 完好 / line+28 = 受损
拆分; 溢出 = max(0, 分配量 + 民池受损÷1e5 − 可用池), 军线 setter
sub_140E611B0 同款); 请求上限 = requested − 相对线贡献 (sub_140F6D300,
is_subject 门下取相对线 +24); requested = vt[11] = MAX_CIV_FACTORIES_PER_LINE
(15) 常量桩 (building/railway/railway-gun-repair 三族同值)。

建成交付 = **CBuilding::SetLevel sub_1410DC4E0** 中央通知器
(building.cpp:138 负值/145 超上限/151 陆锁港三断言): 写 +64 level, healthy 调整
(升 +Δ; 降 min(healthy,new), 相等清 +72 partial_health) → sub_1410DC1C0 重建
建筑双 CModifier (pairs +104/+296 ← def+288/def+96 × healthy) → sub_14195F510
(gs 槽[126] 数组+8 监听) → sub_141178A10 (status 通知) → flag=1 再加 def+868 →
sub_1410A8A40(cc+4344 建成图标, 按州建条目, 仅州控制者==本国) →
**sub_1407042D0(国, building, 旧级)** (cc+4600 统计 + 决策通知 cc+4008 +
cc+4952 逐建筑型等级计数 += Δ + cc+4320 |= 2 修正重算脏位) → 州侧
sub_1409DB480 (门 = 建筑类别旗 sub_14060CF80(building+104) 假 →
**sub_1409D54A0 州生效修正重建** (st+1544 块) + sub_1409E02C0)。交付后钩子
sub_140E6A690: ps+56 监听通知 + AI 补给重算族 (def+760/764/768/780 >0 →
sub_140CD2A30 等; def+885 → sub_140CD2DF0) (定案)。

省/州联动本质: 建筑对象住 CBuildingStatus (省 prov+400 / 州 st+288, def+700
省级等级上限分派); SetLevel 的省侧通知经 prov+192 (省→州回指) 落到州, 州侧
再重建生效修正 — **「省施工、州生效」由通知链完成, 无两份进度** (定案)。
访问器: sub_1410DB850 building→省 / sub_1410DB860 building→州 (省类返 0) /
sub_1410DB630 building→所在地控制者 tag (定案)。

**负定案**: 建筑建成不派发任何脚本 on_action (全 on_action 名枚举无
building/construction 项), 通知全部引擎内部。施工中的表达 = ps+112 存在对应
队列线 (sub_140E5CF90 查询); §4.14 主表 +80 施工容器属铁路 (CProvinceRailwayInfo+80),
与建筑线不同链。铁路线 (type 4713) 对照: 同由 daily serial vt[24]
(sub_141A02660, railway_production_line.cpp:238) 驱动, 推进 current_province(+152)/
path(+128), 速度经 sub_141A02190 (复用 sub_140F6D3A0, def = BDB+936 铁路 def);
铁路施工进度本体存 CProvinceRailwayInfo+80 (§4.14.6) — 两套载体 (定案)。

building 线虚槽契约 (定案): [9]=RegisterId 0x140F6A6E0 / [10]=GetSpeed+刷 cost
sub_140F6E3E0 (写 +40/+48) / [11]=GetRequestedFactories 0x141A2F790
(MAX_CIV_FACTORIES_PER_LINE 常量桩) / [14]=GetSpeed(out&) sub_140F6E060 (读 +48 缓存;
relative 有效∧非 is_subject → 读相对线 +48) / [17]=SetAmount 0x140F6E300
(thunk `jmp 0x1414B5A70`) /
[19]=ReduceAmountBy 0x140F6E3D0 (thunk `jmp 0x1414B5AD0`) / [21]=GetNumToRepair sub_140F6ADC0 (返 +120) /
[22]=常量桩 0x14029C820 `return 1` (分配门; 铁路线同槽返 2 → 焦土阻断;
CRailwayProductionLine/CRailwayGunRepairLine 基座 = CGeneralProductionLine,
RTTI cast 对二者返 0 走 vt[22]==2 分支) / [23]=位置 getter 0x140F6C860 =
sub_1410DB850(线+112) (省; 州建筑返 0) / [26]=修理谓词 0x140F6E190 =
vt[21](线)>0 (= to_repair>0) /
[24]=DailyUpdate sub_140F6A710 / [25]=完成判定 sub_140F6E160 (amount==0 ∧
to_repair==0)。

#### 4.8.6 general 线特化 — rail_way (4713)

类绑定 = **CRailwayProductionLine** (vt 0x142A2BE90, sizeof 168, ctor 0x141A01D90, writer 0x141A046E0 / reader 0x141A041D0)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | uint32 | base (tok 11398): 当前铁路等级 |
| +116 | uint32 | target (tok 107): 目标等级 |
| +117..+127 | +112 base/target 对尾 + **u8 cancel (tok 10469, ≠0 写)@+120** + path {d@128} 头 3B  |  |
| +128 | uint32 | path 容器数据指针 — {data, count} uint32 数组 (**rail_way (tok 19649) 沿途省 id 序列**) |
| +129..+139 | 匿名结构 (NNB 形状) 向量 | path 容器内部: data 尾 + cap@+136; 头 {d@128, cap@136, c@140, alloc@144} |
| +140 | uint32 | path 容器计数 |
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
| +112 | uint32 | 产出铁路炮.type — id 对之 type (id 对 {type@+112, id@+116} — 与 rail_way base/target 同槽异义 (GER el: 74/2 → `railway_gun id=2 type=74`; writer/reader 双侧无门恒写)) |
| +116 | uint32 | 产出铁路炮.id — id 对之 id |

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
| +32 | 912 | fixed×1e5 | **受损工厂** Σ(1+州修正)×(level−healthy) (tooltip PRODUCTION_CIVILIAN_FACTORIES_DAMAGED 铁证; SetLevel +66=healthy; ) | 定案 |
| +40 | 920 | uint32 | **建造已分配产线工厂** | 未使用公式 `v7` |
| +48 | 928 | fixed×1e5 | **工厂能耗需求权重** (sub_140E64510: +48 += v20×v18×level/1e5; v18 = 1e5+州 LOCAL_FACTORIES(65); v20 = 1e5+国 FACTORY_ENERGY_CONSUMPTION(398)+州(397)+基建能耗(657)×基建) | 定案 |
| +56 | 936 | fixed×1e-5 | **电力覆盖率 = min(1, 能源产量 ps+1288 / 需求 ps+1328)**; 重置默认 1.0 (sub_140E66060), 真值写者 sub_140E6AE80 (煤预留→min 钳制); 探针恒 1.0 = 煤足够时的上限值非常量; 消费 = 单厂速度 lerp + 缺电惩罚 | 定案 |
| +64 | 944 | uint32 | **可用公式减项 #2** (生活消费品侧) | 未使用公式 `v6` |
| +68 | 948 | uint32 | **附属贡赋** (FROM_SUBJECTS) | PRODUCTION_CIVILIAN_FACTORIES_FROM_SUBJECTS |
| +72 | 952 | uint32 | 民用池探针恒 0 (军池 = 上缴宗主, §4.8 主表行) | — |
| +80 | 960 | uint32 | 民用池探针恒 0 (军池 = 外赠目标国) | — |
| +84 | 964 | uint32 | **license 受入** (FROM_LICENSES) | tooltip 双桶分开锚定 (与 968 分列) |
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
| +8 | uint32 | status (208) | 交付状态 (**≠0 才写** — loader 默认 0 互锁, 存档常无此键) |
| +16 | fixed×1e-5 | progress (11013) | 仅 status==1 写 |
| +24 | fixed×1e-5 | total_progress (13818) | ≠100000 写 |
| +32 | CString 32B | produced (12204) | 产出装备变体名 |

CUpgradeLevel (升级等级定义, 288B; vt 0x1427DF298; **writer = CFG 空桩 = 只读定义类, 不入档**; reader 0x140625AD0): +8 CModifier 内嵌 (modifier 10597) / +200 效果子对象 (complete_effect 14341); 同级管理器键 level(10348)/ai_will_do(10819)/visible(11562)/frame(252)/sound(441)/picture(464)/modifiers_during_progress(15689)。

CEquipmentProductionLicense (生产许可, 88B; vt 0x1429C0C38; writer 0x14143B6D0 / reader 0x14143AC70; 宿主 = CProductionStatus+400 CLicensedProductionStatus 容器, licensedproduction.cpp 断言):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | uint32 | lended_cic (13770) | 租借民厂数 |
| +12 | uint32 | required_cic (13459) | 需付民厂数 |
| +16 | uint32 | owner (10302) | 持证国 (CCountryRef, tag 名串落盘) |
| +20 | uint32 | giver (12500) | 授予国 |
| +24 | CGameDate | — | 未序列化 (语义未决; 非起始日期 — start hours 实@+32) |
| +40 | CGameDate | start_date (10464) | 起始日期 — ADEC0 序列化代理锚; hours 实值 @+32 (代理−8) |
| +48 | fixed×1e-5 | — | **民厂合同基额** (每日 required_cic 重算公式基数; 量纲反证非日期; 高置信) |
| +56 | 匿名结构 (元素待裁) 向量 | equipment (12110) | 授权装备变体 id 序列 |
| +80 | CEquipmentProductionLicense* | parent (135) | 母许可 id 块 |

许可生产三段运行链 (定案): ① **需求重算** (daily serial 步 1,
sub_14143B640 → sub_1414373F0): required_cic = ceil((基额@+48 + Σ修正) ×
(BASE_LICENSE_IC_COST qword_143337AD8 + LICENSE_IC_COST_YEAR_INCREASE
qword_143337B80 × max(0, 原型年份@arch+984 − 当前年)) / 1e5); Σ修正含 mod 296
(受让国/关系双取) + mod 288 (宗主-附庸双侧, sub_140D25830/D25880) + 装备类别旗
(sub_140C95730 → mod 297/298/299/300 air/infantry/armor/naval) + 原型 token
15399..15402 → mod 313/311/312/314 特化; tooltip 键 LICENSED_PURCHASE_CIC_COST。
② **借出** (池重算消费者 sub_1419FE820 + setter sub_14070CEA0): 授予方民池逐
owned 许可 lended_cic(+8) = min(required_cic, 余量)。③ **受入** (池重算步 4):
avail 侧 lended → 受让国 ps+888 += 1e5×n 且 ps+964 (FROM_LICENSES 桶; 原「ps+968 FROM_TRADE」订正) += n。
方向注 (E 批反编译反转): **lp+56/ps+456 owned_license = 我持有 (受让方, 付费方)** /
**lp+80/ps+480 = 我授出 (授予方, 收款方)** / lp+8/ps+408 available = 市场克隆表
(create_production_license sub_141437120 向受让国 ps+408 push 克隆 + 把 license 注册
进受让国 +456 与授予国 +480) — 原「owned = 本国授予 / avail = 他国授予我方」方向全反, 废。
has_any_license 触发器读 **lp+56 count@ps+468** (accessor 0x14143AB80 = a1+56);
is_licensing_any_to 的 tag 匹配在 license+16 非「解引用+0」。

CRocketProductionLine (火箭产线, ~120B; vt 0x14297C260; **不经 CProductionLine 支系 — CReferenceObject+CPersistent 直系**; writer 0x140F71830 / reader 0x140F71530; 宿主容器 = ps+136 rocket_lines(13304)):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | uint32 | id | 自身 id (与 +12 type 构成 id 对, 联合发射) |
| +12 | uint32 | type | id 对 type 半 (联合门, 与 +8 成对) |
| +24 | std::string 32B | — | 名称 (运行时) |
| +56 | CProductionStatus* | — | owner 反指 |
| +64 | CEquipment* | equipment_variant_index (13891) | 火箭装备引用 |
| +72 | 匿名结构 (NNB 形状) | building (10319) | 发射场建筑名 |
| +80 | CRocketDeployment* | deployment (12181) | 部署目标 (32B 全定案: {vt 0x14295FBE8, tag u32@+8 目标国 (运行时), CEquipmentVariant* @+16 (运行时缓存), base u32@+24 = 键 11398 >0 门, ctor 取建筑定义+88}; writer 0x140D14970 / reader 0x140D12610; 消费链: 火箭线日推进 sub_140F712D0 → sub_140D0DC80 经 CStrategicAirManager(gs+1680) per-country 条目按 base 序号定位基地, 产成枚数灌进 CAirWing) |
| +104 | fixed×1e-5 | produced (12204) | 已产出 |

CConvoyShip (护航舰, ~72B; vt 0x142A3AC18; writer 0x141AD8690 / reader 0x141AD8240; convoy_ship.cpp:54 断言):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | uint32 | id | 自身 id (与 +12 type 构成 id 对, 联合发射) |
| +12 | uint32 | type | id 对 type 半 (联合门, 与 +8 成对) |
| +24 | CEquipmentVariant* | equipment_variant_index (13891) | 船型变体 |
| +32 | fixed×1e-5 | strength (10406) | ctor = max(100, *(variant+744)) (下限 100 raw; `cmovg` 三方向直证) |
| +40 | fixed×1e-5 | organisation (11979) | ctor = max(100, *(variant+736)) |
| +48 | id 对 | client (202) | 护航队客户 |
| +56 | id 对 | transfer_navy (14443) | 转运舰队 |
| +64 | uint32 | tag (10754) | 所属国 (写优先取解析后 client+24) |
| +68 | uint32 | convoy_index (15579) | 编队序号 |

CSunkConvoyInfo (沉船记录, ≤32B; vt 0x142973C28; writer 0x140EB39E0 / reader 0x140EB3820): +8 month(123) / +12 convoys(12386) / +16 killer_country(13555) / +20 owner(10302)。

CNavalBaseConvoyClient (海军基地运输客户; vt 0x1429A29C0; writer 0x140CBE140 = CConvoyClient 基字段全量 / reader 0x140CB73D0; 自身增量不序列化; **id 对仅 +16 旗置位才写**): +24 country(10394) / +32 CConvoySubscriber 内嵌 (convoys_subscriber 15717, 门 = +44≠0) / +72 efficiency(13799) / +80 efficiency_due_to_lost_convoys(15592) / +88 combat id 容器 (块键 10518) / +112 spotter(15488) / +120 request(12613)。

CResourceExchange (资源贸易单, 240B; vt 0x14295C410; writer 0x140CBEEC0 / reader 0x140CB8E10; trade.cpp:3023 断言):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +128 | CTrade* | — | owner 反指 (注册 *(owner+1832)+24×idx) |
| +136 | uint32 | receiver (198) | 接收国 |
| +144 | CResource* | resource (12388) | 资源定义名 (写 = *(def+8) token) |
| +152 | fixed×1e-5 | delivered (12489) | 已交付量 (reader 负值钳 0) |
| +160 | CState* | destination (12480) | 目的州 (写 = *(state+88) id) |
| +168 | CState* | origin (12473) | 来源州 |
| +192 | CGameDate | start_date (10464) | 起始日期 |
| +216 | CGameDate | last_recalc_date (11564) | 末次重算日期 |
| +224 | uint32 | required_cic (13459) | 需付民厂 |
| +228 | uint32 | lended_cic (13770) | 借出民厂 |

CResourceExchange 两 CGameDate: 24B 日期甲 {基+176, hours@+184, 序列化锚@+192} / 24B 日期乙 {基+200, hours@+208, 锚@+216} (双 ctor 直证, 键位不受影响)。
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
虚表 10 槽全表 (reader 侧定案): [8] = **PostLoad 0x140DBABE0** (idpair 重注册 + 已解锁特质 token 桶表校验 :337); 实现层: 特质解锁队列日更 #1 (0x140DBC4F0) 解锁成功后门 mio+312 (auto-designs) → sub_140DB53A0 收集受影响装备变体 → **sub_140DBC9C0 auto-design 变体重设计 pass**; 日更游标前推 sub_140DB7C60 (:1065) / wrapper sub_140DBC7D0 (:1018) / GetTraitName sub_140DB9960 (:1049); **库对象第二索引 trait token RH 桶表 {d@+168, mask@+180, extra@+184}**; **variant+1160 = 挂接 MIO 指针** (sub_1413AF930 :246 断言 + 0x140DBC9C0 门双证)。org_template 家族 7 函数: 0x140A51D60 总校验编排 + 五子校验 (parent/互斥 reciprocity/token 唯一/树位置唯一/remove_trait-vs-include) + 0x140A54AA0 模板级继承门; 模板新偏移 +20 (include isSet 旗) / +36 (+24 列表 count) / +476 / +500 / +556 / **+1384 = include 源模板条件块头指针**。槽契约族内定案: CTrigger [13] = 载荷引用校验槽 / CEffect [23] = 常量负值校验槽 / CTrigger [23] = 比较 trigger 现值 getter。UI 桥: list_window 0x141C3C7F0 / 0x141C3C6B0; ui_context mode 枚举 (1 研究槽/2 生产线/3 舰船改装/4 变体); tooltip_helper token 615..623 stat 族。

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
| +160 | fixed×1e-5 | research_bonus (uint64) |
| +168 | uint32 | task_capacity 原始值; 生效值 = ×`MODIFIER_MIO_TASK_CAPACITY` 经 0X140DB9860, 特性门 define `ENABLE_TASK_CAPACITY` |
| +176 | fixed×1e-5 | research_assign_cost (ctor = define `ASSIGN_DESIGN_TEAM_PP_COST_PER_DAY`) |
| +184 | fixed×1e-5 | production_assign_cost (ctor = `ASSIGN_INDUSTRIAL_MANUFACTURER_PP_COST_PER_DAY`) |
| +192 | int32 | design_team_change_cost (ctor = `DESIGN_TEAM_CHANGE_XP_COST`) |
| +200 | fixed×1e-5 | funds_gain_factor (ctor = 1.0) |
| +208 | fixed×1e-5 | size_up_requirement_factor (ctor = 1.0; 不入档) |
| +216 | NIndustrialOrganisation::CTask 向量 | 指派任务容器 {data@+216, cap@+224, count@+228, alloc@+232} (元素 24B = CTask, 全布局 §4.8.12a; 入档无 — PostLoad 双侧重建) |
| +228 | uint32 | num_assigned (上容器 count 本身) |
| +240 | rh 表 | 指派历史 robin-hood {data@+248, count@+256, mask@+260, extra@+264, maxload@+268} (元素 64B, 子表见下) |
| +272 | COrganisationTemplate 子库* | def 特质子库 (= def+136); 特质查找 sub_140A53660 读 a1+48/+60 = **def+184/def+196** = 模板 trait 数组 24B 容器头, 按元素+8 token 线性扫 (原 {d@+152, c@+164} 注系误记, 说废) |
| +280 | COrganisationTemplate 子库* | def 条件块 (= def+536); available / visible 门 (0 → 谓词恒真) |
| +288 | tag_id | 属主国 tag (ctor 入参) |
| +296 | fixed×1e-5 | funds (uint64) |
| +304 | uint32 | size (规模等级) |
| +308 | uint32 | trait points (字段名 `_TraitPoints`; 解锁特质递减) |
| +312 | uint8 | auto-designs 开关 (ctor=1) |
| +320 | std::set | 已解锁特质集 {sentinel@+320, size@+328} (元 16B, 子表见下) |
| +336 | 匿名结构 (元素待裁) 向量 | queued_trait vector {data@+336, cap@+344, count@+348, alloc@+352} (元 16B, 同下子表) |
| +360 | uint32 | 解锁队列处理游标 |
| +368 | uint32 向量 | allowed_policies vector {data@+368, cap@+376, count@+380, alloc@+384} (元素 u32 政策 id) |
| +392 | token | 当前附着政策 (初 19479 `undefined`) |
| +400 | 匿名结构 (NNB 形状) | policy cooldown 区 (+400..+447; 载荷@+416, 存在旗@+424; 子字段见 §4.31.41) — **无日倒计时 (负定案)**: 冷却 = set_mio_policy_cooldown 政策 def 侧解析回调 (sub_1402FADA0 表注册) 写的基天数 (policy+76, 负值拒) → 附着时换算实例绝对日期门, 改政策时比较日期而非每日递减 (比较点未定位 — F2 未能复核项) |
| +448 | CVariables 内嵌 | variables (子布局见 §4.31.41) |
| +504 | CFlagManager 内嵌 | flags {vtable@+504, data@+512, count@+524, alloc@+528}; 条目 48B 见 §4.13.3 |

MIO 日更四连 (daily serial 对 ps+304 逐 org, 定案):

| 序 | 函数 | 语义 |
|---|---|---|
| 1 | sub_140DBC4F0 | 特质解锁队列日推进: while(+308 点数>0): 自 +360 游标扫 +336 队列 → sub_140A53660 查 def → sub_1413AF360 可解锁判定 → sub_140DBC860 解锁 (插 +320 集 + --点数) → auto-design 重算 (sub_140DB53A0/sub_140DBC9C0, 门 +312); "cannot find trait put in queue for unlock" industrial_organisation.cpp:658 |
| 2 | sub_140DBC140 | 指派任务校验 (纯校验无推进 — 负定案): 逐 +216 任务 (24B 元) available(mio+280 条件块) ∧ visible ∧ 装备匹配 (sub_140DB6F40) 任一失败 → 游戏中 sub_140DB61F0 卸载 / 历史装载期报错 "in history files, MIO … incorrectly attached to a production line … reason=[Not Visible]/[Not Available]/[Equipment no match]" industrial_organisation.cpp:549 |
| 3 | sub_140DBBEB0 | 容量超编卸载 (ENABLE_TASK_CAPACITY 门 + sub_140DB9860 生效容量 → 自 +216 尾部卸载; 即上表 set_mio_task_capacity 尾调同函数) |
| 4 | sub_140CBFA90 | MIO 旗日倒数 (org+504 CFlagManager — 与国家级 flag_manager.daily 同函数, §4.2.7) |

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

**不入档字段**: +16 / +24 / +48 / +56 (MIO 名 token) / +64 / +208 / +216 / +228 / +272 / +280 / +288 / +360 — 载入后由 def 与 ctor 入参重绑; +216 指派任务容器亦不在本类落盘范围 — **重建路径 (定案)** = CCountry::PostLoad 级联内 sub_14070C290: ①清空全部 mio +216 并通知监听; ②线侧回填 — 遍历 ps+88 生产线, 逐线 line+144 idpair 经 id 库解析出 mio → push CTask{0, line}; ③研究槽侧回填 — 遍历 cc+3936 CTechnologyStatus 研究槽数组 (slots{d@+160, c@+172}, §4.7), 逐槽 slot+24 = CTechnology 的 +492 MIO idpair 解析出 mio → push CTask{CTechnology*, 0}。

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

#### 4.8.12a NIndustrialOrganisation::CTask (指派任务挂接记录, 24B)

MIO「任务」= 组织 (设计局) 当前被指派到一条生产线 / 一份装备采购合同的**运行时挂接记录** (非国家任务/非加成任务; 断言 "HasEnoughTaskCapacity()" industrial_organisation.h:220 出现于全部入队点; 卸载报错串 "...incorrectly attached to a production line..." industrial_organisation.cpp:549 锚死语义)。持于 §4.8.12 +216 容器, 元素按值存储; **零键零序列化** (writer = CFG 空桩; reader = "Unexpected token" 报错桩 — §4.00.1 盲区家族 [4] 退化形态), 载入后由 PostLoad 双侧重建 (§4.8.12 不入档字段段)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | 0x1427E74D8 (9 槽; 主虚表 [0..8]) |
| +8 | CPurchaseContract* / CTechnology* | 任务源载荷 (无 = 0): 合同路 = CPurchaseContract*; 研究槽路 = CTechnology* (科技 +492 MIO idpair 挂接, sub_140ED22D0(mio, tech) 断言 HasEnoughTaskCapacity industrial_organisation.h:220; 运行期同构链 L7496507 双证) |
| +16 | CProductionLine* | 生产线任务载荷 (无 = 0; 高置信) |

双载荷互斥单态 (每 CTask 恰一者非零; 无单体 ctor — 三处 push 均内联三连写):

| 入队路 | 链 | 载荷 |
|---|---|---|
| 生产线挂接 | sub_141939EE0: 倒扫 +216 删同线旧任务 (同线替换) → sub_141932470 push; 另把线侧挂接节点 line+80 push 进 mio+48 (第二监听挂接槽的写入路径) | {0, line} |
| 合同付清 | sub_140EE3680 (合同付款/交割链尾) → sub_140ED22D0 push | {contract, 0} |
| 研究槽挂接 | 设计局指派链: `*(tech+492) = idpair` → 遍历 ts slots (cc+3936) → sub_140ED22D0(mio, tech) | {CTechnology*, 0} |
| PostLoad 重建 | sub_14070C290 (§4.8.12 不入档字段段): 线侧 {0, line} / 研究槽侧 {CTechnology*, 0} | 双侧回填 |

daily 校验 = §4.8.12 日更四连 #2 sub_140DBC140 (available ∧ visible ∧ 装备匹配, 经 line+136 取线装备)。

#### 4.8.12b NIndustrialOrganisation::CTraitTemplate (特质 def, 984B) 与 COrganisationTemplate (模板 def)

**CTraitTemplate** (vt 0x14271A4F0, 9 槽; writer = CFG 空桩 = def 不序列化; **[3] Load = 自定 wrapper** — 先记源位置对入 +968 (sub_140A4FFB0) + 盖已载旗 +976 再走标准驱动 — serfam 指纹失配 = §4.00.1 盲区家族; [7] PostLoad2 覆写 = 遍历 +880 父条目校验 num_parents_needed ≤ traits 列表计数 (+12), industrial_org_trait.cpp:283)。**= COrganisationTemplate 的嵌套子结构 (特质条目), 非独立库 def** (模板 reader 键 11918 trait / 11883 add_trait → 模板+184 数组按值追加; 16518 override_trait → 模板+488 第二数组; 16358 initial_trait → 模板+176 单体槽; 运行时查找 sub_140A53660 按 +8 token 线性扫)。装载 = common/military_industrial_organization/ (COrganisationDatabase::InitFromDirectory; 库单例 0x332EF48)。

| 偏移 | 类型 | 名称/语义 | 键 |
|---|---|---|---|
| +8 | uint32 | 特质 def token (库查找键; STraitId 的 token 源) | 19015 token |
| +16 | COrganisationTemplate* | 属主模板反指 (入表时写) | — |
| +24 | SSO 32B | name | 27 name |
| +56 | SSO 32B | icon | 181 icon |
| +88 | uint8 | special_trait_background 旗 (ctor 0; **reader case 16379 = sub_1424C0C00 死吞** — 第二实参不触, 解析层无写回; 无 writer 发射) → 恒 0 死门 (mod 侧 `special_trait_background = yes` 解析层不生效) | 16379 |
| +96 | CAnonymousEquipmentGroup 208B | 装备组 (名串 → 构造 → 三连后处理; 内部子布局推定) | 11538 limit_to_equipment_type |
| +304 | NIndustrialOrganisation::CTraitBonus 32B 头 | **加成表** {d@+312, cap@+320, c@+324} 16B/条 {u32 stat_token@0, i64 值@8}; equipment_bonus / production_bonus 双键共写 — 临时 CTraitBonus 白名单校验 (12647→equipment 词表 industrial_org_trait.cpp:245 / 16218→production 词表 :260) → sub_14063F3C0 合并同 token 累加; **块内无类目字段, 区分全在解析期键侧白名单** (两个不相交 token 词表; 合并门 sub_140640D20: 1=equipment / 2=production / 3=全收) | 12647 / 16218 |
| +336 | CModifier 192B | 修正块 (§4.3.8 同款) | 16233 organization_modifier |
| +528 | CAndTrigger 88B | available 触发器 | 12264 |
| +616 | CAndTrigger 88B | visible 触发器 | 11562 |
| +704 | CEffect 88B | on_complete 效果 | 10074 |
| +792 | CMeanTimeToHappen 56B | ai_will_do 权重 (ctor 基值 100000) | 10819 |
| +848..+879 | 4 uint64 | 未名块 (ctor 清零, 无 reader 写者) | — |
| +880 | 父条目数组 (32B 元) | {data@+880, cap@+888, count@+892}; 条目 = {+0 token 列表 16B {d@0, cap@8, c@12} (键 12278 traits), +24 num_parents_needed (键 14517; 默认 1; all_parents 分支写 = traits 计数)} | 135 parent / 16704 any_parent / 16705 all_parents |
| +904 | token 列表 16B | 互斥特质 token 表 {d@+904, cap@+912, c@+916} | 13242 mutually_exclusive |
| +928 | int32 | position.x (ctor = −1; 树位置解析 sub_140A4E2C0) | 76 |
| +932 | int32 | position.y (勘误: 原单行 int32 系双字段 {x@+928, y@+932}; "position [x, y]" 错串双证) | — |
| +936 | uint32 | relative_position_id token (+940 isSet 旗) | 14029 |
| +944 | token 列表 16B | **delete_included_values** = include 继承排除表 (元素 = 参数键 token): 普通参数命中 → 不从被 include 侧继承 (留默认); 与自身覆写同设 → 警告 industrial_org_trait.cpp:100, 自身值赢; 对 +304 加成块 = 类目级保留过滤 (含 12647 → 继承值仅留 equipment 类 / 含 16218 → 仅留 production 类; 双类目均无声明且 dst 无该类条目 → 全量继承; 消费 = sub_140A507B0) | 16370 |
| +968 | uint64 | **源位置对 {u32 文件索引, u32 行号}** (解析期落点; 自定 [3] wrapper sub_140A4FFB0 前置写入) | [3] 写 |
| +976 | uint8 | 已载旗 ([3] 盖 1) | [3] 写 |

19 键 reader = sub_140A50000 (上表键列全表; 未命中报错桩)。辅助: sub_1403B7500/sub_1403B78B0 = u32 token 列表 reader 两变体 — 骨架完全同构, 唯一差异 = token id 取法 (7500 按名现查表 sub_1424BB460 / 78B0 lexer 记录 +0 直读; 语义等价); 13242/16704/16705 走 7500, 16370 走 78B0。早前「特质条件组」四组推定注 (+528/+616/+848/+856) 已由本表取代: available=+528 / visible=+616 与该推定互异 (推定说废); +848 区实为未名块。

**COrganisationTemplate** (ctor 0x140A51750; **sizeof 1464** (malloc 0x5B8 直证); reader 19+24 键): +8 name token / +16 include (10236) / +24 token 列表 (16370; delete_included_values, 模板级与 CTrait +944 同语义) / +48 SSO name / +80 SSO icon / +112 fixed research_bonus (12641) / +120 u32 task_capacity (16220) / +136 SSO background (156) / +168 xp_research_type (15373: 10397 army→1 / 10398 navy→2 / 11926 air→3) / **+176 initial_trait 单体槽 (984B)** / **+184 trait 数组 (984B 元; +196 count)** / +208 equipment_type 装备组 (16217, 208B) / +416 SSO research_categories (19164) / +440 STreeFlavorText 数组 (48B 元; 16361 tree_header_text) / +464 token 列表 remove_trait (11884) / **+488 override_trait 数组 (984B 元)** / +536 条件块头 (§4.8.12 +280 所指; available cond+88=+624 / visible cond+176=+712 与本表吻合) / +624 available CAndTrigger (12263 allowed 打条件块 / 12264 打本槽) / +712 visible CAndTrigger (11562) / +800..+1320 六 CEffect on_* (10141 on_design_team_assigned_to_tech / 10142 …_to_variant / 10143 on_industrial_manufacturer_assigned / 10196 on_tech_research_cancelled / 10197 on_tech_research_completed / 10198 on_industrial_manufacturer_unassigned) / +1328 CMeanTimeToHappen ai_will_do (10819)。

> **本域 GUI 类布局**: 见 4.31.33 / 4.31.41 (原 4.31.30 引用断链, 民用池 tooltip 在 §4.8.9)。

#### 4.8.13 生产线 daily 推进执行链

主入口 = **sub_140E670A0 (CProductionStatus::DailyUpdate, zone "production.daily_serial")**,
唯一调用点 = CCountry::DailyUpdate 串行段 (§4.2.7, exile 清理后、"resources.daily"
sub_140CABB30 前)。daily 并行侧 (sub_1406E8C70 → sub_140E67040) 只做 AI 快照
memcpy, 无模拟逻辑。

内部序列 (函数体顺序):

| 序 | 函数/槽 | 语义 | 置信 |
|---|---|---|---|
| 1 | sub_14143B640(ps+400) | license 民厂需求重算 (公式见 §4.8.10) | 高置信 |
| 2 | sub_141937BB0 | 军线资源释放遍: 逐线资源成本条目向上取整整单位 → sub_140BCB580(CCountryResources+920) 释放 (trade.h:554) → sub_141A00C60 清 {amount,need} → 尾 SetSpeed(0) (production_line.h:224) | 定案 |
| 3 | 军线 vt[10] sub_14193A460 | 军线日重算 (fe 扩容+钳制 → 成本 → 资源再预留 sub_140E5AAB0 → 速度; 细分见 §4.8.13a) | 定案 |
| 4 | 军线 vt[30] | 产出推进: produced(+56) += 日速率 → 整单位交付 (装备入池 sub_140E60E30 / naval 先 sub_140D0EB00(*(line+272)) 部署推进) → amount(+72) 递减 → cc 计数 → sub_1419341A0 MIO 产出记账 → sub_141937ED0 效率增长 (§4.8.14) → sub_141937FE0 收尾 | 军线定案; naval/铁炮高置信 |
| 5 | sub_140E6ED60 | 零产量军线删除: line+72==0 → "Deleting non productive line %d in %s" (production.cpp:925) swap-remove + priority 顺位重排 | 定案 |
| 6 | general 线 vt[24] | 日推进: building=§4.8.13b / railway=sub_141A02660 (path(+128) 逐省, 失效走 vt[27]) / repair=sub_140F70100 | building 定案; railway/repair 推定 |
| 7 | serial 内联 | 关联建筑等级转移收集: 读 building 线 {对象@+160, 完成数@+168} → 逐条目按 count 次对源建筑 u16@(对象+64) −1 并 sub_1410DC4E0 (民转军一类等级转移的源侧扣除; 关联对象解析 = sub_141175A30(州+288, def+736)) | 机制定案 |
| 8 | general 线 vt[25] | 删除谓词 → "General line %d in %s" (production.cpp:963) swap-remove | 定案 |
| 9 | sub_140F712D0 | 火箭线日推进 (ps+136): produced(+104) += 速率 → 整单位 → sub_140D0DC80 部署 + sub_141374140 统计 | 定案 |
| 10 | sub_140E6D010 / sub_140E6D4B0 | 删线触发的民用/军船厂工厂再分配 (常规入口 = 池重算尾, §4.8.15) | 定案 |
| 11 | serial 内联 | destroyed_stockpile 到期清扫 (ps+576, 40B 元): 元素+24 ≤ gs+1128 当前总小时 → swap-remove | 定案 |
| 12 | MIO 遍历 (ps+304) | 日更四连 (§4.8.12 表) | 定案 |
| 13 | sub_1419FF1F0 | 合同付款日结 (ps+1168): 遍历市场合同, 余款>0 → v11=min(余量单位, 合同+192) → 产值=民厂单产×v11 → sub_1419D4800 支付; 付清 → ps+1192 脏旗 (contract_payment_consumer.cpp:74 "math fuckup" 断言) | 定案 |
| 14 | sub_140224C30 | 删线 UI 通知 (general=17 / 军线=2; 玩家国才发) | 高置信 |

#### 4.8.13a 军线日重算 sub_14193A460 细分

| 子步 | 语义 | 置信 |
|---|---|---|
| fe 维护 | vt[11]=GetMaxAllowedFactories > line+204 → sub_141939A70 扩容 + 新槽零填 (当日钳制抬到 START 下限起步) | 定案 |
| 入口钳制 | 全量 fe[i] = clamp(fe[i], 效率下限, 线上限) | 定案 |
| 效率下限 | 100000 × BASE_FACTORY_START_EFFICIENCY_FACTOR (dword_143336790) + 100 × mod[171]; 无效率装备族 (sub_140C97B90 原型旗递归, mask 0x80004003C1) → 恒 100.0 | 定案 |
| 线效率上限 | 100000 × BASE_FACTORY_MAX_EFFICIENCY_FACTOR (dword_143336830) + 100 × mod[169] + 100 × 线内 MIO 加成槽 2 (sub_1419360B0) | 定案 |
| 换装门 | is_converting(+236) 且变体旗组合有效; 运行时容器(+112/+124) 空 → 取消换装 (清 +236 与 produced+56) | 定案 |
| 成本重算 | line+40 = (线内加成槽0 + 100000) × vt[32] / 100000; 明细链 sub_141935230 (equipment_production_line.cpp:324 MIO 断言, tooltip 键 PRODUCTION_COST_MODIFIER_ITEM) | 定案 |
| 资源再预留 | vt[28] 取单位输入资源表 → 逐资源需求 = 单位量 × active_factories(+24) × (1+线内槽4) → sub_140E5AAB0 扣留 → 条目 amount(+16)=实得 / need(+24)=缺口 | 定案 |
| 短缺计算 | sub_141936210 累加同容器先序线同资源预留按可用量分配 → line+216 短缺惩罚 (§4.8.1) | 定案 |
| 速度计算 | sub_1419364B0 = 基速 × (MIO 加成 + 100000)/1e5 × sub_141935810(修正乘子); 负值断言 "Negative production speed." → 0; SetSpeed(line+48); 换装态再算 → +224 non_conversion_speed | 定案 |
| 加成集 | line+152 CTraitBonus; +184 脏旗时经 sub_140DB7A30(MIO, 原型) 重建; 槽契约 PRODUCTION_BONUS_COUNT=7 (production_bonus.h:53; 0=成本/2=效率帽/3=效率增长/4=资源/5=短缺), 匹配 token 表 dword_14338A560[10×槽] | 定案 |

#### 4.8.13b building 线日推进 sub_140F6A710

线+136 重算 / cost (conversion 旗+140 选择 v4/v5) → produced += 速率 → 每完成
单位 vt[19](line,1) + **sub_1410DC4E0(建筑, u16@(建筑+64)+1) 等级+1** (交付链与
省/州联动详见 §4.14 施工链节); 属国共建时进度镜像对方线+56 且宗主分摊:
delta = MASTER_BUILD_AUTONOMY_FACTOR (**−0.7**) × (speed × 相对线+24 ÷
(相对线+24 + 线+24)) ÷ 100 × (1+mod291), 记线宿主国自治对象; 关联建筑条件满足时
暂存 {对象@+160, 完成数@+168} 由 serial 步 7 收集 (定案)。

#### 4.8.14 效率日增长

**sub_141937ED0** (军线 vt[30] 尾): 对 min(GetMaxAllowedFactories, active_factories)
以内每位 fe[i] += 增量后 clamp(下限, 线上限) — **仅活跃工厂位增长** (定案)。

增量公式 (**sub_141935590**, 定案): gain = (BASE_FACTORY_EFFICIENCY_GAIN
(unk_1433368B0) + mod[170] production_factory_efficiency_gain_factor + line+216
短缺惩罚 + 线内槽3) × 线上限² ÷ (BASE_FACTORY_EFFICIENCY_BALANCE_FACTOR
(unk_143336940) × 当前效率 × 10⁴) — Q15 定点两段换算; 增长随当前效率升高而
减速; 当前==0 或 balance≤0 → 0。

无效率装备族 (sub_140C97B90 旗) 下限=上限=100% (族不用效率斜坡)。调试旗:
byte_14332F628 (toggle) = 产出速率 max 模式; byte_14332F62B = naval/铁炮 vt[30]
附加分支门。

#### 4.8.15 消费者与工厂分配拓扑 (事件驱动)

池重算增补 (定案): 步 3 = sub_140E649A0 附属上缴吸收 (276/277 受入) + 递归池重算; 步 8 = 遍 B 外赠 (+960/+944、+768/+752); **军用 +68 (ps+756) = FROM_SUBJECTS 军侧桶** (书未记)。SetLineFactories sub_140E611B0 完好/受损拆分公式定案 (军源 ps+720 / 船源 ps+816; line+24 = 完好 / line+28 = 受损)。AddProductionLine sub_140E603B0 (初始 produced = cost×pct/1e5; refit amount 顶格 1e7; naval 上限 sub_140BD9EA0); AddRefitLine sub_140E60830; 新建筑线默认置顶 sub_140E710F0 (flag 0→顶 / 2→首个非修理线下方)。变体生命周期: 注册链五件套 (sub_140E5D570 → ps+160/184/208/市场 0x140E714F0/upgrades 0x140E5E410) + 过时标记 sub_140E5E510 (清扫域 = ps+184; 装载期 gs+2613 跳过; 尾联 license 重算); MIO/policy 装载器 0x140E59400/0x140E59720 (模板库 rh 56B 条 + FNV 73244475 查找; policy 实例 104B ctor 0x140A493E0; "MIO %s is in save but not in DB" :115 跳块不终止); available/foreign_lease 共用 reader 0x140E6B0A0 (按变体名==本国 tag 路由)。军线族虚槽: [28]=GetInputResources 0x141938370 / **[29]=SetEquipmentVariant 0x141939C20**; CMilitaryProductionLine 覆写 [30]=0x140F6E840/[32]=0x140F6EA30; building [18]=0x140F69E50 (行量 += num); priority+68 = 容器数组下标不变量 (六函数互证)。

**池重算 sub_140E6C810** (production.cpp:2263) — 消费品比例与工厂分配不在
daily serial 本体, 由事件驱动 (ps+1192 脏旗 / calc_modifier 传播 / hourly 脏分支):

| 步 | 语义 | 置信 |
|---|---|---|
| 1 | ps+1192 脏清零 → 四池基础重填 (sub_140E64510, ps+688/784/880/976) | 定案 |
| 2 | 工厂捐献 mod 292/293/294 加池总量 | 定案 |
| 3 | 附属贡赋: 附属侧 mod 374/375 (cic/mic_to_target_factor) → 宗主 +956/+764 受赠; 宗主侧 mod 276/277 (cic/mic_to_overlord_factor) → +952/+760 上缴 (方向定案: 276/277 上缴门 = 本国有宗主) | 定案 |
| 4 | license 受入 (ps+408 available 克隆侧 lended → ps+888 与 ps+964 FROM_LICENSES 桶; 池重算 sub_140E6C810 经 sub_1406F2F20 扫 **ps+480 授出表** → ps+888/ps+964 — 原「ps+408」订正) | 定案 |
| 5 | 贸易民厂 (CResourceExchange 槽容器@CCountryResources+1832; 交换条目+228 lended_cic → ps+888/968) | 定案 |
| 6 | **消费者×5 调度** (数组序: CConsumerGoods@ps+1072, CContractPayment@+1168, CSpecialProjects@+1096, CLicensedProduction@+1120, CTrade@+1144): 逐个 vt[1](consumer, cc, ps+880 民用池) → **ps+944 += consumer+16** | 定案 |
| 7 | 军/船厂分配 sub_140E6D4B0 (**两遍制**: 预扣遍可负池 → 分配遍 max(0,·) 截断 = 先到先得) → 民用分配 sub_140E6D010 → sub_140E71350 | 定案 |

消费者共式 (五件 Update, CConsumerGoodsConsumer vt 0x1429705F0, [1] =
sub_1419FE790): available = max(0, 民池+8 − 民池+32(ps+912) − ps+944
− ps+920); 份额 = ConsumerGoods min(经济法则需求 (mod 102/103 + define
MINIMUM_NUMBER_OF_FACTORIES_TAKEN_BY_CONSUMER_GOODS_PERCENT qword_143331498 +
军/民池量), available) / SpecialProjects min(sub_140E63E40, available) /
LicensedProduction 逐许可 min(required_cic, 余量) → license+8 lended_cic /
CTrade 逐交换条目 min(required(+224), 余量) (定案)。

军/船厂分配 **sub_140E6D4B0** (production.cpp:2599): 可用 = 池 val(+696/+792)÷1e5
− 池+64 − 豁免 (sub_1406F9760/sub_140EA60A0); 逐线请求 = +232 钳 ≤ — **勘误定案: 豁免项 (sub_140EA60A0) 只减船厂侧; 军侧可用 = val÷1e5 − +64 无豁免项** (sub_140E6D4B0/sub_140E69130 双证)
active+damaged; **sub_140C97B90(原型) 真 (海军族) 吃船厂池、假吃军池**;
增量 min(请求−现有, 可用) → sub_140E611B0 设线工厂数; 尾部重跑释放+重预留 (定案)。

民用分配 **sub_140E6D010** (production.cpp:2542): ps+920 清零 + general 线
line+24 清零 + CCicBank 清零 (sub_14145AAE0(ps+664), 非计息); 修复线优先
(vt[26] 谓词, 预算 = ps+1200 max_factories_for_repair — 预算写者 = hourly
sub_140E711A0, 式见 §4.8 主表 +1200 行); 全部建筑线按 vt[11]
请求; sub_140E6AD10 分配并收集受影响国递归再分配; UI 通知 17 (定案)。

hourly 维护 sub_140E696E0 补 (§4.2.6 pass④ 增补): 非脏分支也跑
sub_140E6D010(ps,1) 每小时兜底; sub_140E71350 = 经济聚合变更检测
(ps+1320..1344 vs sub_140E64B90 现算) + 资源字变更 (ps+1194/1196/1198 快照
vs CCountryResources+1096..1100) → 变更则能量记账 (sub_140E5A100) + 军线
释放+重预留重跑 (定案)。

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| ps+944 | u32 累加 | 民用池消费侧合计 (消费者×5 各加 consumer+16) | 定案 |
| ps+956/+960 | u32 | 民用池受赠所得 / 外赠目标 (军池对偶 +764/+768) | 定案 |
| ps+1194 + ps+1198 | u32 + u16 (6B 快照) | 资源存量快照 (CCountryResources+1096.. 变更检测缓存; 原 u32×3 说废) | 定案 (F2 验算) |
| ps+1200 | u32 | max_factories_for_repair (修复线预算) | 定案 |

#### 4.8.16 CBuildingDatabase::CIntermediateBuildingTemplateData (建筑 def 解析期中间格, 48B; def 侧只读件不入存档)

vt 0x1427E4130 单链继承 (CIBTD←CDatabaseObject←CPersistentWithToken←CPersistent, 全 mdisp=0; 主虚表恰 11 槽 [0..10]; .rdata 后续 5 槽组属 CBuildingDatabase、9 槽组属 USLevelMax@CBuildingTemplate 各独立 COL 勿混): [2] writer = CFG 空桩; **[3] 自定义单值 Load wrapper 0x1424BE620** (读当前标量入 +16, 置旗 +24 — §4.00.1 wrapper 自定类盲区又一实例); [4] reader 0x140688670; **[7] 提交槽 0x140687B60** (旗 +24 置位时把 +16 抄给 +40 回指父对象的 +16, 再虚调父 vt[+56] 续解析); 邻组 9 槽表的 reader 0x1414BC5A0 = CBuildingTemplate::SLevelMax::Reader (非本类)。持有者 = CBuildingDatabase 解析路径 sub_140683BC0 的 this+160 矢量。语义 = 建筑定义解析期「中间模板格子」(缓存 spawn_point 名哈希/延迟值, 提交槽回填父模板), def 装载期临时体, 随 db 重建废弃。

| 偏移 | 类型 | 初值 | reader 键 | 语义 |
|---|---|---|---|---|
| +8 | uint32 | — | — | CDatabaseObject 基类 id |
| +16 | int64 | 0 | (自定义 Load wrapper 单值) | 延迟值格 |
| +24 | uint8 | 0 | — | 已装载旗 (wrapper 置 1, 提交槽消费) |
| +32 | uint32 | 357 none | 10432 spawn_point | 读名字串 → FNV 哈希 (sub_1424BB460) 存入; 非零才覆盖 |
| +40 | 指针 | — | 其它键 → 委派父 vt[+32] | 提交目标 (父模板回指) |
