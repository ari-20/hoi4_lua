

### 4.23 装备与市场 (装备定义 / 库存 / 全局市场 / 静态定义 / 属性枚举 / 升级模块)

#### 4.23.1 装备定义族 (equipments)

| 项 | 值 | 语义 |
|---|---|---|
| 管理器 | `*(gs+1812)` | |
| 定义表 | `*(gs+1800)` | |
| 元素 vtable | 0X2951608 | |
| 定义名 | token@对象+8 | |
| 字段族 | archetype / id / version / is_frame / creator / origin | 存档 equipments 块 |

**CEquipmentVariant** (元素, sizeof 0x4B8 = 1208; CReferenceObject 头 {vt@0, type u32@+8 = 70, id u32@+12}; writer 0X140BE3C80; ctor 0X140BD06B0 / dtor 0X140BD1680 / loader 0X140BDE4C0; 方法群 0X140BCC520–0x140BD5000, equipmentvariant.cpp):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | u32 | 原型名 token (存档条目键) |
| +28 | u32 | creator |
| +32 | u32 | origin tid (0 = "---") |
| +36 | u8 | show_position (==0 才写 `show_position no`, writer 0X140BE3C80 第 3 分支 token 398; 26 叶全 no 由此解释) |
| +40 | SSO | name |
| +41..+71 | — | = name SSO 尾 {size@+56, cap@+64 = 15} |
| +72 | SSO | position |
| +73..+103 | — | = position SSO 尾 {size@+88, cap@+96} |
| +104 | 内嵌 | upgrades 实例 (CEquipmentUpgradesInstance 80B, 布局见下表) |
| +105..+183 | — | = upgrades 实例本体 (var+104..+183) |
| +184 | 容器 24B | modules 容器 {d@184, cap@192, count@196, alloc@200}; 16B 条 {slot_token, str*} (空槽不写) |
| +185..+207 | — | = modules 容器尾 {cap@+192, count@+196, alloc@+200} |
| +208 | 容器 24B | ideas 容器 {d(ptr)@208, cap@216, count@220, alloc@224} 指针数组 → io+120 → token u32@+8; **键门 = count@220 ≠ 0** (writer 0X140BE3C80 尾): count==0 → 存档无 `ideas=` 键; count≠0 但名全解析空 → 合法空块 `ideas={ }` |
| +209..+231 | — | = ideas 容器尾 {cap@+216, alloc@+224} |
| +232 | 容器 24B | named_equipment_bonuses 容器 {d@232, cap@240, count@244, alloc@248}, u32 数组; 空格单行 #1 |
| +233..+255 | — | = named_equipment_bonuses 容器尾 {cap@+240, alloc@+248} |
| +256 | i64[78] | stats 数组 (+256..+872), 变体生效属性缓存; 下标 = EEquipmentStats 枚举 id (67 = weight@+792, 68 = thrust@+800, loc EQUIPMENT_DESIGNER_WEIGHT_EXCEEDS_THRUST 锚定); 不序列化 |
| +880 | 容器 24B | per-mission stats {d@880, cap@888, c@892, alloc@896} — 40B 条 {mission_bits u32@0, pairs_data@16 → 16B {stat_enum u32, value i64}, pairs_count@28}; 不序列化 |
| +904 | 容器 24B | stat 修正源缓存 {d@904, cap@912, c@916, alloc@920} — 16B 条 {key qword@0, flags u32@+8}; 形态定案 / 语义推定; 不序列化 |
| +928 | 容器 24B | 每槽已装模块指针缓存 (8B 条, 索引 = 模块槽号, 值 = 解析后 CEquipmentModule*; type+192 槽 def 数组经 sub_140BCD0D0 解析); 不序列化 |
| +952 | 容器 24B | 未名 {d@952, cap@960, c@964, alloc@968} — **元素 4B (u32 数组)**: dtor sub_14011DF40 / copy-assign memcpy(..., 4*count) (sub_141892C50); 形态定案 / 全 dump 无具名消费者; 元素 4B 复证 (copy `0x140156970` `lea r8,[r14*4]`); 不序列化 |
| +976 | 内嵌块 | variant bonus 块: {value qword@976 ← type+944; 修正对容器@+984 (16B 条) ← type+64 拷贝}; upgrades/modules 叠加后尾以 named_equipment_bonus #77 百分比缩放 (语义推定: 造价/加成块); 形态定案 / 语义推定; 不序列化 |
| +1008 | CEquipmentType* | _pType (ctor `*(a1+1008) = a2`; archetype token@+24 = *(*(a1+1008)+8); ~15 函数 "Expected/Invalid equipment type" 断言; _Category 由它算); 不序列化 |
| +1016 | CEquipmentVariant* | parent 变体指针 (parent_id id 对) |
| +1024 | qword | 未名 (ctor sub_140BD06B0 清零 / copy 系整 qword 拷贝); 可用性门 = sub_1419A5AF0 `*(v6+32)>0 && !*(v6+1024)` (同函数亦读 +1008 _pType) → **外部只读缓存指针槽** (本类域内仅清零/拷贝, 无写入者); 形态定案 |
| +1032 | u64 | _Category 位掩码 (EEquipmentCategory bitmask; 位段 0x1F0037FC00 = EQUIPMENT_AIR 族; assert `_Category != EQUIPMENT_UNKNOWN`); 不序列化 |
| +1040 | u32 | missions 位掩码 (机种任务使能; 聚合自各已装模块 +116 的位, 0X140BDF420 重算); 不序列化 |
| +1044 | u32 | 升级等级总和缓存 (Σ *(u8*)(upgrade+8); design 相等性三键之一 +196/+1044/+1048); 不序列化, 高置信 |
| +1048 | u32 | Σ(module+112) 缓存 (design 相等性三键之一; module+112 语义推定: id/单价); 不序列化, 高置信 |
| +1052 | u8 | version (互斥写: ver>0 写 version 否则写 max_version) |
| +1053 | u8 | max_version (互斥写同门) |
| +1054 | u8 | is_frame (恒写 yes/no) |
| +1056 | u32 | manpower (仅正值写) |
| +1060 | u8 | obsolete (仅真值写) |
| +1061 | u8 | auto_upgraded (仅真值写) |
| +1062 | u8 | highlight (仅真值写) |
| +1063..+1065 | u8×3 | can_upgrade_type / can_upgrade_variant / can_upgrade_modules (仅真值写) |
| +1066 | i16 | legacy parent variant id (−1 = 无; loader case 135 = parent 置 −1, 解析结果写 +1016; `_pParent` 断言); 兼容键, 定案 |
| +1068 | u32 | role_icon_index (仅正值写) |
| +1072 | SSO | override_model |
| +1073..+1103 | — | = override_model SSO 尾 {size@+1088, cap@+1096} |
| +1104 | u8 | has_override_sprite 标志 (writer 写门) |
| +1112 | SSO | override_sprite (size@+1128, cap@+1136; 定案) |
| +1113..+1151 | — | = override_sprite 48B 结构体尾段 (结构体 +1104..+1151, sub_14139CBD0 构造 / sub_140153530 析构) |
| +1152 | 匿名结构 (含 SSO) | division_names_group → 串@+8 |
| +1160 | uint32 | design_team id 对.type (0 = 无) |
| +1164 | uint32 | design_team id 对.id (0 = 无) |
| +1165..+1175 | — | = design_team id 对尾 (+1165..+1167) + +1168 = NIndustrialOrganisation::CTraitBonus 对象基 vt 槽 |
| +1176 | 匿名结构 (16B) | design_team_bonus 数组数据, cap@+1184 / 真计数 u32@+1188 (⚠ 遍历按 +1188 真计数, 勿用 cap — cap 可超 count), 16B 条 {stat_token u32, fixed5 i64@+8}; 受 design_team 门控 (无 dt 的残留数组 writer 不写) |
| +1177..+1199 | — | = CTraitBonus 容器尾 {cap@+1184, count@+1188, alloc@+1192} |
| +1200 | u32 | number_of_design_team_traits (0 = 不写) |

⚠ stats 数组 (+256) 下标是 EEquipmentStats 枚举 id, 非存档 token — 同 BLD2_NAMES 教训: 两套命名空间勿混。

ideas 容器 writer (0X140BE3C80) 逐元素线性查重只写首现: 容器可含重复 token, 发射端须去重。

GUI 消费表 (CEquipmentVariant):

| 字段 | 消费点 | 用途 |
|---|---|---|
| +32 origin | sub_141784780 尾 (0 门控 EE500) | 起源显示 |
| +1008 _pType | sub_140B6C220 谓词 → handler+600/608/616 三视图实例 | 设计器路由键 (tank/plane/(country)equipmentdesignerview) |
| +1016 parent | builder#2 载入 live parent ∥ 自身; SetTarget = sub_141788C50 双 builder @view+14232/+23032 | 母本对照源 |
| +1032 _Category | sub_141790600: 镜像#1+1032 → 预览#2+1448 (VARIABLE_CATEGORY_TOOLTIP 语境); bit0 → cc+4624 池/+4716/+4728/+4736; bit31 → sub_1406EE6E0 扣减链 | 类别掩码聚合; 市场库存分支 (位名推定) |
| +1040 missions | view+58264 vs variant+1040 | mission 过滤 (选中机种任务不含于变体 → 收起该段) |
| +1068 role_icon_index | =0 时按库 sub_14062F120 回退 (sub_141790050) | 角色图标回退 |
| +1072 override_model | view+69096 CEquipmentDesignerModelSelector; E440 与 +1072 比对判改 (EQUIPMENT_DESIGNER_UPDATE_COSMETIC) | 模型覆盖名镜像 |

**CEquipmentUpgradesInstance** (实例基 = var+104; 80B):

| 实例+N | 类型 | 名称/语义 |
|---|---|---|
| 实例+0 | — | vtable |
| 实例+8 | 容器 24B | upgrades {d@实例+8 = var+112, c@实例+20 = var+124}; 16B 条 {def ptr → 名 token@+8, level u8@+8} |
| 实例+32 | 8B 元素 向量 | 容器2 (var+136) — 元素 = 8 字节 (0x140185E10 `lea rsi,[rbx*8]` 直证) |
| 实例+56 | 8B 元素 向量 | 容器3 (var+160) — 元素 = 8 字节 (同上) |

**CEquipmentVariantReference (栈构引用对象)** — b08 批据; 栈构无独立堆布局 (推定):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +0 | vt | — | 推定 |
| +4 | u32 | archetype id | 推定 |
| +8 | qword | 未名 qword | 推定 |
| +12 | u32 | tag #1 | 推定 |
| +16 | u32 | tag #2 | 推定 |
| +20 | u8 | 旗 | 推定 |
| +24 | MSVC 串 | 名串 | 推定 |
#### 4.23.2 库存 / 装备市场

| 项 | 值 | 语义 |
|---|---|---|
| stockpile | 国家装备库存 (库存锚 = ps+520/544 + cc+4024) | cc+0 区挂载 (gs+1776 = 编制模板容器单义, 非库存共用) |
| 国家侧 equipment_market | cc+4024 数据源 (market_request_automation / market_stockpile / subsidies) | 与全局块不同对象不同数据 (国家侧 view writer 0X141AA6A30 族, def 在其对象+120) |
| market_stockpile 装备池条目 | 池 writer 0X141012DB0 | **条目门 = amount(raw i64)≠0 或 allow_zero_entries≠0**; `[N]` 编号只对发射条目递增 (门外的编号会整体前移) |
| 附属国库存包装器 +840 | set_equipment_fraction 写点 (包装器层 +840; 推定) | 单批孤证 |
| 国家侧 market automation | 外层对象 +96/+97/+98 三布尔 | market_request_automation 开关族 (cc+4024 双层: 外层 = rp(cc+4024), 内层 = rp(外层)) |
| 国家侧 market_stockpile 池 | 内层 {d@+88, count@+100} | 16B 条 {variant ptr@+0, amount fixed×1e-5@+8} (与全局块 §4.23.3 不同对象) |

**subsidies 补贴条** (国家侧 market 对象内; e = 条目基; 读取链 sub_1413B29C0 / 140DDD510, 三档存档实证):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | fixed×1e-5 | cic |
| 元素+8 | 匿名结构 (NNB 形状)* | archetype 宿主, archetype = ru32(rp(e+8)+8) |
| 元素+16 | 匿名结构 (NNB 形状)* | 串宿主, trigger 分支 ==1 时 MSVC 串 @*(e+16)+96 |
| 元素+40 | u8 | trigger 分支 (==1 → 串) |
#### 4.23.3 全局装备市场 (NInternationalMarket)

| 项 | 值 | 语义 |
|---|---|---|
| 挂载 | mkt = rp(gs+1000) | gamestate writer 0X1401F2E40 调用点 0XUNRESOLVED `mov r8,[rsi+1000]`; 空指针整块不写 |
| 类 | NInternationalMarket (RTTI); mkt 对象 = CPurchaseContractsContainer 120B | 分配点 gs 重建 sub_1401EC950: malloc 0x78 → ctor sub_140DEADD0 |
| mkt 布局 | 内嵌 96B {contracts@0, pending-removal 延期删除架@24, by_seller 索引@48, by_buyer 索引@72 (均 333 槽 = 国数)} + requests@96 | 延期删除架 = move-push 进, DailyUpdate 尾 flush 删 |
| 块构成 | 仅 contracts + requests 两字段 | loader 铁证: 成员分发 sub_140DF3C60 case 13230 = requests / 15105 = contracts, 其余 skip |
| writer | sub_140DF42C0 | — |

**contracts** (容器 @ mkt+0; 元素 8B 指针 → CPurchaseContract; [N] 序 = 数组序, 创建/插入序, 不按 id 排序):

| 偏移 (mkt) | 类型 | 内容 |
|---|---|---|
| +0 | CPurchaseContract** | data |
| +8 | — | cap |
| +12 | uint32 | count |

**requests** (容器 @ mkt+96; count = 440 国家槽, idx0 哨兵):

| 偏移 (mkt) | 类型 | 内容 |
|---|---|---|
| +96 | 匿名结构 (24B 元)* | data; 元素 = 24B 内嵌 vector |
| +104 | — | cap |
| +108 | uint32 | count |

元素 stride 24B:

| 偏移 (元素) | 类型 | 内容 |
|---|---|---|
| +0 | CPurchaseRequest** | idata |
| +8 | — | icap |
| +12 | uint32 | icount (过滤器 sub_140DF25F0 = elem+12==0 跳过) |

内表元素 = 8B 指针 → CPurchaseRequest (vt 0x142A28ED0, ctor 0X1419D6020; ~240B: CReferenceObject 头 + def@+24 216B 与合同 def 同构)。

requests 存档形态 (稀疏数组 writer sub_140DF48B0): `requests={ <总槽数=440> index=<国槽 idx> data={ { contract_definition={…} id={…} } } }` (index=524 仅 icount≠0 槽; data=240; 元素 def writer = sub_140DF1EC0 与合同 def 同函数, id = B320(11, req+8))。

**CPurchaseContract** (808B = 0x328; vt 0x14296B750; writer 0X140DF4540; ctor 0X1419D4370) — 写序 = id → contract_definition → delivery_route_handler → days → contract_delivery_state → contract_meta → variables (表行序 = 偏移升序, 写序以本句为准):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | u32 | id 对.type (type@+8=81) | B320: id = a3[1], type = *a3 |
| +12 | u32 | id.id — id 对之 id |  |
| +13..+23 | — | = CReferenceObject 头尾 {u8 注册标志@+16, pad} (头 24B {vt@0, idpair@+8/+12, u8@+16}, 基 ctor sub_14221E410 直证) |  |
| +24 | 内嵌 | contract_definition (def, writer 0X140DF1EC0) | 下表 |
| +25..+239 | — | = contract_definition 内嵌 216B 本体 (+24..+239; ctor sub_140302250 逐字段拷) |  |
| +240 | 内嵌 | delivery_route_handler = CEquipmentConvoyClient (vt 0x14296B6B0, 基 CConvoyClient) | 下表 |
| +241..+471 | — | = CEquipmentConvoyClient 内嵌 232B 本体 (+240..+471; 基 CConvoyClient ctor sub_140CA48C0 trade.cpp:339) |  |
| +472 | 内嵌 | contract_delivery_state (ctor 0X1414445A0, +0 = definition 回指) | factory_cic_progress i64@+480 / equipment_transfer_progress@+488 / collected@+496 (fixed5) |
| +473..+527 | — | = contract_delivery_state 48B 本体 {def 回指@+472, factory_cic_progress@+480, equipment_transfer_progress@+488, collected@+496, u8@+504 (不序列化), qword@+512 (不序列化)} + +520 i64 (ctor = 100000×convoys_total, 运行时再算不序列化) |  |
| +528 | fixed×1e-5 | contract_meta.cic |  |
| +536 | fixed×1e-5 | contract_meta.convoys | fixed5 缩放 (AE590), 非原值 |
| +544 | fixed×1e-5 | contract_meta.efficiency_due_to_lost_convoys | ctor 默认 100000 |
| +545..+559 | — | = contract_meta 体内 (efficiency_due_to_lost_convoys 尾 + history 区) |  |
| +560 | fixed×1e-5 | contract_meta.history.factory_cic_progress |  |
| +568 | fixed×1e-5 | contract_meta.history.equipment_transfer_progress |  |
| +576 | fixed×1e-5 | contract_meta.history.collected |  |
| +577..+603 | — | = contract_meta.history 体内 (+600 = −1 哨兵低半) |  |
| +604 | uint32 | contract_meta.completed | 原值 (ADFE0) |
| +605..+615 | — | = completed 尾 + days 前置 |  |
| +616 | uint32 | 合同级 days | 原值 |
| +624 | std::function\<void(CPurchaseContract*)\> 64B | 完成下架回调 {_Space[56], _Impl@+56; 探针 _Impl vt=0x14296B588} | 不序列化 |
| +688 | std::function\<void(CPurchaseContract*)\> 64B | 周期未竟回调 {_Impl vt=0x14296B5C0} | 不序列化 |
| +752 | 内嵌 | variables = CVariables 56B (+752..+807 恰满; 全布局 §4.13 — vt/种子对/桶哨兵/count/mask/extra/load_factor=0.9/尾槽) | 空表三闸门 §4.13 |

完成下架回调 lambda_1 (CEquipmentMarketSystem::SetCallbacks 挂载): 容器移除 + 国家+168 ended 信号 + 全局 off_1430B15B0。

周期未竟回调 lambda_2: 国家+232 changed 信号 + 重启交付周期。取消 = 独立路径 CancelContract (sub_140DEC540) → 国家+200 cancelled 信号 + off_1430B15B8。

contract_definition (def = c+24; 表行序 = 偏移升序, 括注 = 合同绝对偏移):

| def 偏移 (合同绝对) | 类型 | 名称/语义 |
|---|---|---|
| +0 (+24) | CEquipmentVariantPool | prices (下) |
| +64 (+88) | int32 | contract_draft.seller |
| +68 (+92) | int32 | buyer = tag_id → 串 |
| +72 (+96) | CEquipmentVariantPool | contract_draft.equipments 请求池 |
| +136 (+160) | qword | 补贴 CIC 总额 (ctor = 0 从 draft 拷贝; 不序列化; IsComplete ⇔ factory_cic_progress == +208−+200) |
| +144 (+168) | 匿名结构 (48B 形状) 向量 | contract_draft.subsidies {data@144, count@156}, stride 48 (元素布局见下表) |
| +168 (+192) | uint32 | contract_draft.speed |
| +176 (+200) | std::map | price_levels → levels: head@176, size@184; **节点 key = idpair 8B {type@+28, id@+32}** = **CEquipmentVariant 自身 CReferenceObject idpair** (L2 门 = 全局 CIdentifier 注册表可解析 sub_14221F310, 不可解析静默丢弃; 读侧 sub_1419D3FD0 / 写侧 sub_1419D40F0 双证), value 枚举 u32@+36; 中序 = 写序 (map 形态定案: 收集 sub_1419D3E00 → 写 sub_140DF4390) |
| +192 (+216) | u8 | 懒计算完成标志 (ctor = 0) |
| +200 (+224) | i64×1e-5 | 补贴抵扣 = min(+136, 总价×F/(F+1e5)) (F = PURCHASE_CONTRACT_SUBSIDY_BONUS_SPEED_FACTOR; 不序列化) |
| +208 (+232) | i64×1e-5 | 合同总 CIC 价 (Σ variant IC×价格档因子×IC_TO_CIC_FACTOR, market_core.cpp 断言锚; 不序列化) |

contract_draft.subsidies 条 (48B stride; e = 条目基):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | i64 (fixed×1e-5) | cic |
| 元素+8 | 匿名结构 (NNB 形状)* | archetype 宿主, archetype = ru32(rp(e+8)+8) |
| 元素+16 | 匿名结构 (NNB 形状)* | 串宿主 (MSVC 串 @*(e+16)+96) |
| 元素+40 | u8 | 分支 (0 → targets u32 列表; 1 → i64) |

CEquipmentConvoyClient (cli = c+240; 派生 writer 0X1419D7490 → 基类 0X140CBE140):

| cli 偏移 (合同绝对) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +248 | u32 | id.type — id 对之 type (对 {type@+248=4713, id@+252}) | has-id 标志 u8@c+256≠0 才写 |
| +252 | u32 | id.id — id 对之 id | 同上 |
| +253..+263 | — | = CReferenceObject 头尾 {u8 注册标志@+256 = has-id 写门, pad} |  |
| +264 | int32 | country = tag_id (船队归属国) |  |
| +272 | 内嵌 | convoys_subscriber = CConvoySubscriber (vt 0x14295c0f0, writer 0X141022CB0): convoys u32@c+280 / total u32@c+284 | 块仅在 total≠0 时写 |
| +273..+311 | — | = CConvoySubscriber 内嵌 24B 本体 {convoys@+280, total@+284, u32@+288} + qword×2@+296/+304 (不序列化) |  |
| +312 | fixed×1e-5 | efficiency |  |
| +320 | fixed×1e-5 | efficiency_due_to_lost_convoys |  |
| +321..+359 | — | = vector 24B@+328 (不序列化, 未名) + idpair 哨兵@+352 (=qword_14333D528, 不序列化) |  |
| +360 | uint32 | request |  |
| +368 | CEquipmentVariantPool | equipments 在途池 |  |
| +369..+431 | — | = equipments 在途池 CEquipmentVariantPool 64B 本体 (+368..+431) |  |
| +432 | uint32 | length 航线长度 |  |
| +436 | uint8 | type = 2 |  |
| +437..+447 | — | = +440 = CResourceDeliveryRoute* (卖方 CCountryResources(cc+4600) delivery_routes@rs+1928 按买方国 idx; route vt=0x14295C320, route+56 convoys_owner = 买方 tag 探针实证; Status 本体在 cc+4024) + pad |  |
| +448 | fixed×1e-5 | drh.efficiency |  |
| +456 | fixed×1e-5 | drh.sunk_convoys | fixed5 缩放 |
| +464 | uint32 | drh.days | 原值 |

**CEquipmentVariantPool** (64B; vt 0X142748040; ctor 0X14100C710; writer slot2 0X141012DB0; 3 处复用: prices / draft.equipments / cli.equipments; 师 +840/+1472 与 CRaidInstance+272 同 ctor 同 vt — SEquipmentPool 同体异名, §4.22 互证; pool1 stride 24 / pool2 stride 16 分用定案, 证据: writer 0X141012DB0 循环 `v5 += 16` / ctor 0X14100C710 pool1 增长 `24*n` / push 0X141012230 双池并见):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (24B)* | pool1 容器数据 {data@8, count@20} stride 24, 条 {variant*, pool2idx u8@+8, refcount u32@+12, amount@+16} — 不入档 (变体级明细) | 不写 |
| +9..+31 | — | = pool1 容器尾 {cap@+16, count@+20, alloc@+24} (ctor 预分配 defines/10 容量) |  |
| +32 | 匿名结构 (16B)* | pool2 容器数据 {data@32, count@44} stride 16 — 序列化源: {variant ptr@+0, amount i64×1e-5@+8}; variant id 对 = {type@var+8=70, id@var+12} | 元素级跳过规则见下 |
| +33..+55 | — | = pool2 容器尾 {cap@+40, count@+44, alloc@+48} |  |
| +56 | uint8 | allow_zero_entries | 恒写 |

writer 跳过规则: amount==0 && allow_zero_entries==0 的元素不写。

市场 GUI 对象 (锚定与定名, 消费链见各行):

| 对象 | 锚 / 定名 | 语义 |
|---|---|---|
| CLendLeaseExchange | rs+1880{+1892} = CLendLeaseExchange* 数组 | 布局 = CConvoyClient 派生全字段 (export item = refid 快照 @item+32) |
| COverrideMarketEquipmentPriceLevelsCommand | id 14010 | EPriceLevel 枚举实名 |
| SMarketEquipmentData | 72B | 布局见下表 |
| CMarketEquipmentItem | 基族 25 槽 | PurchaseDraftItem / PurchaseEquipmentItem 同基 |
| EditMarketStockpileWindow | 双槽 target = win+1448 CMarketStockpile* + win+1440 卖方 tag | 数据 @win+5624 |

SMarketEquipmentData (72B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +16 | — | amount |
| +24 | — | 生产库存 (断言定名) |
| +40 | — | cic_cost |
| +48 | — | price_level |
| +56 | — | convoy_cost |
#### 4.23.4 静态定义 (definitions)

| 项 | 值 | 语义 |
|---|---|---|
| 锚 | `*(cc+3936)` (CTechnologyStatus 同锚) | def_names 表 + token 全局表 |
| BLD_NAMES | 建筑名表 | |
| STAT2TOK | 78 修饰槽 token 表 | |
| CR_MASK | 装备掩码 u64 | 0x40000 scout_plane / 0x100000 air_transport / 0x200000 maritime_patrol_plane / 0x400000 carrier / 0x2000000 flame / 1<<32 heavy_fighter 等 |
#### 4.23.5 EEquipmentStats 枚举全表 (装备属性 id → token)

写侧 LUT = 0x1413E8820 (switch id→token), 读侧反查 = 0x1413E81B0 (token→id, 未中 = 78)。CEquipmentStats 元素 = 16B {stat_enum u32@0, value i64@8} (稀疏集, value≠0 才写); 装备统计数组 = variant/archetype 侧 i64[78] 按此序。

| id | token | id | token | id | token |
|---|---|---|---|---|---|
| 0 | default_morale | 26 | lg_armor_piercing | 52 | naval_strike_attack |
| 1 | defense | 27 | hg_attack | 53 | naval_strike_targetting |
| 2 | breakthrough | 28 | hg_armor_piercing | 54 | air_ground_attack |
| 3 | hardness | 29 | torpedo_attack | 55 | air_visibility_factor |
| 4 | soft_attack | 30 | sub_attack | 56 | railway_gun_attack |
| 5 | hard_attack | 31 | anti_air_attack | 57 | railway_gun_attack_range_index_in_define |
| 6 | recon | 32 | amphibious_defense | 58 | railway_gun_annex_ratio |
| 7 | entrenchment | 33 | naval_speed | 59 | railway_gun_hours_between_redistribution |
| 8 | initiative | 34 | naval_range | 60 | max_organisation |
| 9 | casualty_trickleback | 35 | mines_planting | 61 | max_strength |
| 10 | supply_consumption_factor | 36 | mines_sweeping | 62 | maximum_speed |
| 11 | supply_consumption | 37 | naval_light_gun_hit_chance_factor | 63 | armor_value |
| 12 | suppression | 38 | naval_heavy_gun_hit_chance_factor | 64 | ap_attack |
| 13 | suppression_factor | 39 | naval_torpedo_hit_chance_factor | 65 | reliability |
| 14 | experience_loss_factor | 40 | naval_torpedo_damage_reduction_factor | 66 | reliability_factor |
| 15 | equipment_capture_factor | 41 | naval_torpedo_enemy_critical_chance_factor | 67 | weight |
| 16 | fuel_capacity | 42 | naval_weather_penalty_factor | 68 | thrust |
| 17 | recovery | 43 | convoy_raiding_coordination | 69 | fuel_consumption |
| 18 | additional_collateral_damage | 44 | patrol_coordination | 70 | fuel_consumption_factor |
| 19 | surface_detection | 45 | search_and_destroy_coordination | 71 | strategic_attack |
| 20 | sub_detection | 46 | air_range | 72 | carrier_size |
| 21 | surface_visibility | 47 | air_defence | 73 | submarine_carrier_size |
| 22 | sub_visibility | 48 | air_attack | 74 | acclimatization_hot_climate_gain_factor |
| 23 | carrier_sub_detection | 49 | air_agility | 75 | acclimatization_cold_climate_gain_factor |
| 24 | carrier_surface_detection | 50 | air_bombing | 76 | night_penalty |
| 25 | lg_attack | 51 | air_superiority | 77 | build_cost_ic |
#### 4.23.6 装备属性/加成族 (CEquipmentStats / StatsGroup / EquipmentBonus / SpecificEquipmentBonus / TraitEquipmentBonus)

**CEquipmentStats** (32B; vt 0x142718958; writer 0x140632FB0 / reader 0x1406329D0→0x140632840; clear 槽[9]=0x140631ED0): {d@8, cap@16, count@20, alloc@24}; 元素 16B {stat_enum u32@0, value i64@8}; writer value≠0 才写 (id→token 走 §4.23.5 LUT); reader 已存在同名时**累加** (警告 "Duplicated equipment stat type")。

**CEquipmentStatsGroup** (104B; vt 0x142937DF8; **writer = CFG 空桩 = 纯脚本解析不落盘**; reader 0x140632A60): +8 CEquipmentStats add_stats (15213) / +40 add_average_stats (15223) / +72 multiply_stats (15214)。

**CEquipmentBonus** (56B; vt 0x1427189B0; writer 0x140632DE0 / reader 0x140632830→0x1406323B0): 基 CEquipmentStats@8..+28 + **+32 f64 数组 = 按地形 A 族下标的 attrition 值** {d@32, cap@40, count@44}: writer 先写 attrition = { terrain = f64 ×N } (地形名自 CTerrainDatabase 0x332F0A8, 零值不写); reader 键 10531 按地形查 def+136 = A 族下标落 +32+8×idx, 未知地形告警 (equipmentbonus.cpp:274)。

**CSpecificEquipmentBonus** (~120B; vt 0x142718A08; 基 CPersistentWithToken@0 + THashedKeyValueTrait@16; **自有 wrapper 类 (serfam 盲区)**: Save w 0x140632D90 / writer 0x140633090 / Load w 0x140632130 / reader 0x140632B10): +8 加成类型名 token / +16 名 SSO (+48 ci-FNV) / +56 equipment→CEquipmentBonus hash 图 / +112 instant 旗 (13428) / +116 map 键 hash。名校验 = **script_enum_equipment_bonus_type 注册库 0x332EED0** (§4.26.8)。存档形 = `<加成类型名> = { instant = <bool>; <equipment token> = <bonus 块> ×N }`; = named_equipment_bonuses 容器 (cc+376 块 10206, 200B 元) 本体。

**CTraitEquipmentBonus** (~160B; vt 0x1427EA5F8; 基 CSpecificEquipmentBonus 同槽全共享; 独有 dtor 0x14071DE80): +128 trait 名 SSO (运行时缓存, 不落盘)。
#### 4.23.7 升级/模块/装备组/候选设计族

**CEquipmentUpgrade** (升级定义, ~352B; vt 0x1429D4E18; **writer = CFG 空桩**; reader 0x141538B40; 校验 vt[7]=0x1415380D0): +8 upgrade 名 token / +24 显示名 SSO (CCountrySpecificNamedItem) / +64 CEquipmentStatsGroup / +168 CEquipmentBonus (attrition 仅此可达, 裸 stat 先被 multiply 吃掉) / +224 cost 货币枚 (10323: 0 land/1 naval/2 air) / +232 CEquipmentStats linear_cost (19499) / +268 max_level (11875) / +272 level_requirements 容器 (19549, 96B/条 = {level u8@0 排序键 + CAndTrigger 88B@8}, reader 0x141538320) / +296 resource_cost_thresholds 容器 (19734, 184B/条 = CEquipmentUpgrade::CUpgradeCost = {byte 键@0 + CStrategicResourcePool 176B@8}, reader 0x141538D60) / +320 abbreviation SSO (10557)。

**CEquipmentModuleConversion** (模块改装转换条; vt 0x1429D4480; writer 桩; reader 0x14152FCD0): +8 u32 未名 (待裁) / +16 module (15222) / +20 module_category (15221) / +24 i64 convert_cost_ic (15219) / +32 容器 convert_cost_resources (15220)。

**CEquipmentModuleSlot** (模块槽; vt 0x14295B788; writer 桩; reader 0x141645F30): +8 slot 名 token / +16 u8 required (12481) / +24 容器 allowed_module_categories (15209) / +48 gfx SSO (12472)。

**CEquipmentGroup** (装备组定义; vt 0x142719610; writer 桩; reader 0x140A0B160): +8 组名 token / +16 icon SSO (181) / +48 description SSO (15906) / +80 equipment_type 串列 (16217)。**CAnonymousEquipmentGroup** (vt 0x142719668; 基 + CEquipmentGroupDatabaseListener@104 + TListenerTrait@104): +136 u8 已注册旗 ([9] 门路)。**CEquipmentGroupDatabase** (vt 0x142719790; 非 CPersistent): vec@96/cnt@108 (idb equipment_group 已挂 ✓) + listener@+128; reload 槽组 0x14016CAD0/0x14016A740。**CEquipmentFilter** (名录; vt 0x142937F40): +8 name (27) / +16 values (19260)。

**CDuplicateArchetypeDefinition** (duplicate 原型 def, ~280B; vt 0x142937EF0; writer = 断言 stub 不落盘; reader 0x140C98DD0): only_duplicate_archetype(12431)→+16 u8 / module_slots(15208)→+17 u8 (仅 none=357 合法) / archetype(12103)→+20 / type(225)→+24 子对象 / ai_type(12955)→+32 / default_carrier_composition_weight(13699)→+40 (+48 旗) / variant_name(19748)→+128 串对 map / substitute(12375)→+176 (+180 旗) / sprite(61)→+184 串 / picture(464)→+216 串 / air_map_icon_frame(14310)→+248 (+252 旗) / interface_overview_category_index(13900)→+256 (+260 旗) / forbid_mission_type(12391)→+264 子对象。

**CPotentialDesignCollection** (候选设计集; vt 0x142A1B640; writer 0x141923D30 / reader 0x141922360): +8 集合名 SSO / **+48 u64 category 位掩码** / +56 designs 指针数组 {d@56, count@68}: land = 0x408000003C / naval = 0x80004003C1 / air = 0x1F0037FC00 (与 §4.23.1 CEquipmentVariant+1032 _Category 位段互证); 落盘形 `<名> = { category = land|naval|air; equipment(12110) = <设计块> ×N }`。

**图形池族 (idb equipment_graphic 已挂 0x332EEC8)**: CEquipmentGraphicDatabase (vt 0x142719578; 非 CPersistent): 项数组@+8 + **4 张内联 RH 表 @+48/+80/+112/+144** (56B/80B/80B 条; 伴随 CDatabaseReloader vt 0x14271BEE0); CEquipmentGraphicPool (vt 0x1429389F0; writer 桩): 键 limit(10762)→+8 子解析 / cultures(11534) / ideologies(12241) / sub_units(12176) / weight(593) / models_weight(16903)→*(a1+96)+16 / icons_weight(16904)→+8; CEquipmentGraphicPoolTypeMap (名录; vt 0x1427194F8): type→pool 映射薄壳 = {vt@0, +8 池容器 (元素 0x28B)}, 唯一键 19241 `pool`。CEquipmentOverview (名录; vt 0x142A55F18): 装备总览 GUI 窗 "equipment_overview_window", CReloadableInterface@0 + CTooltipHandler@40, 内嵌 CArmyManpowerValues@+152。

**装备 attrition 售后小件**: CEquipmentBonus attrition 通道与 terrain def+136/def+8 双通道见 §4.26.7。
