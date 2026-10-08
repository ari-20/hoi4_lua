

### 4.23 装备与市场 (装备定义 / 库存 / 全局市场 / 静态定义 / 属性枚举 / 升级模块)

#### 4.23.1 装备定义族 (equipments)

| 项 | 值 | 语义 |
|---|---|---|
| 管理器 | `*(gs+1812)` | |
| 定义表 | `*(gs+1800)` | |
| 元素 vtable | 0X2951608 | |
| 定义名 | token@对象+8 | |
| 字段族 | archetype / id / version / is_frame / creator / origin | 存档 equipments 块 |

**CEquipmentVariant** (元素, sizeof 0x4B8 = 1208; CReferenceObject 头 {vtable@0, type u32@+8 = 70, id u32@+12}; writer 0X140BE3C80; ctor 0X140BD06B0 / dtor 0X140BD1680 / loader 0X140BDE4C0; 方法群 0X140BCD0D0–0x140BD8400, equipmentvariant.cpp):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | uint32 | 原型名 token (存档条目键) |
| +28 | uint32 | creator |
| +32 | uint32 | origin tid (0 = "---") |
| +36 | uint8 | show_position (==0 才写 `show_position no`, writer 0X140BE3C80 第 3 分支 token 398; 26 叶全 no 由此解释) |
| +40 | SSO | name |
| +41..+71 | — | = name SSO 尾 {size@+56, cap@+64 = 15} |
| +72 | SSO | position |
| +73..+103 | — | = position SSO 尾 {size@+88, cap@+96} |
| +104 | 内嵌 | upgrades 实例 (CEquipmentUpgradesInstance 80B, 布局见下表) |
| +105..+183 | — | = upgrades 实例本体 (var+104..+183) |
| +184 | 匿名结构 (16B 形状) 向量 24B | modules 容器 {d@184, cap@192, count@196, alloc@200}; 16B 条 {slot_token, str*} (空槽不写) |
| +185..+207 | — | = modules 容器尾 {cap@+192, count@+196, alloc@+200} |
| +208 | uint32 向量 24B | ideas 容器 {d(ptr)@208, cap@216, count@220, alloc@224} 指针数组 → io+120 → token u32@+8; **键门 = count@220 ≠ 0** (writer 0X140BE3C80 尾): count==0 → 存档无 `ideas=` 键; count≠0 但名全解析空 → 合法空块 `ideas={ }` |
| +209..+231 | — | = ideas 容器尾 {cap@+216, alloc@+224} |
| +232 | uint32 向量 24B | named_equipment_bonuses 容器 {d@232, cap@240, count@244, alloc@248}, u32 数组; 空格单行 #1 |
| +233..+255 | — | = named_equipment_bonuses 容器尾 {cap@+240, alloc@+248} |
| +256 | int64[78] | stats 数组 (+256..+872), 变体生效属性缓存; 下标 = EEquipmentStats 枚举 id (67 = weight@+792, 68 = thrust@+800, loc EQUIPMENT_DESIGNER_WEIGHT_EXCEEDS_THRUST 锚定); 不序列化 |
| +880 | 匿名结构 (40B 形状) 向量 24B | per-mission stats {d@880, cap@888, c@892, alloc@896} — 40B 条 {mission_bits u32@0, pairs_data@16 → 16B {stat_enum u32, value i64}, pairs_count@28}; 不序列化 |
| +904 | 匿名结构 (16B 形状) 向量 24B | stat 修正源缓存 {d@904, cap@912, c@916, alloc@920} — 16B 条 {key qword@0, flags u32@+8}; 形态定案 / 语义推定; 不序列化 |
| +928 | i64 数组 (定长 = CTerrainDatabase 单例 +76 = 地形数) | **per-地形聚合数组**: 每地形 = type+192 基值[m] + ideas (var+208 → idea+88 数组) + named_bonus (var+232 句柄 → ps+376 对象 +96 数组) + Σ upgrade def (def+200 数组) ×level/1e5 (sub_140BE0260 纯数值累加, 无指针写); 业务名推定 per-地形 attrition (与 CEquipmentBonus attrition 通道同构), 引擎消费点未定位待裁; 不序列化 |
| +952 | 匿名结构 (4B 形状) 向量 24B | 未名 {d@952, cap@960, c@964, alloc@968} — **元素 4B (u32 数组)**: dtor sub_14011DF40 / copy-assign memcpy(..., 4*count) (sub_141892C50); 形态定案 / 全 dump 无具名消费者; 元素 4B 复证 (copy `0x140156970` `lea r8,[r14*4]`); 不序列化 |
| +976 | 内嵌块 | variant bonus 块: {value qword@976 ← type+944; **单件资源成本表容器@+984** (16B 条 {单件量 qword@+0, 资源 def 指针@+8}) ← type+64 拷贝}; upgrades/modules 叠加后尾以 named_equipment_bonus #77 百分比缩放 (**+984 语义收实 = 单件资源成本表**: 军线 GetInputResources 0x141938370 普通态直读本容器, 换装态返回来源装备的资源表; 书旧注「修正对容器 (语义推定: 造价/加成块)」升格定案); 形态定案; 不序列化 |
| +1008 | CEquipmentType* | _pType (ctor `*(a1+1008) = a2`; archetype token@+24 = *(*(a1+1008)+8); ~15 函数 "Expected/Invalid equipment type" 断言; _Category 由它算); 不序列化 |
| +1016 | CEquipmentVariant* | parent 变体指针 (parent_id id 对) |
| +1024 | uint64 | 未名 (ctor sub_140BD06B0 清零 / copy 系整 qword 拷贝); 可用性门 = sub_1419A5AF0 `*(v6+32)>0 && !*(v6+1024)` (同函数亦读 +1008 _pType) → **外部只读缓存指针槽** (本类域内仅清零/拷贝, 无写入者); 形态定案 |
| +1032 | u64 | _Category 位掩码 (EEquipmentCategory bitmask; 位段 0x1F0037FC00 = EQUIPMENT_AIR 族; assert `_Category != EQUIPMENT_UNKNOWN`); 不序列化 |
| +1040 | uint32 | missions 位掩码 (机种任务使能; 聚合自各已装模块 +116 的位, 0X140BDF420 重算); 不序列化 |
| +1044 | uint32 | 升级等级总和缓存 (Σ *(u8*)(upgrade+8); design 相等性三键之一 +196/+1044/+1048); 不序列化, 高置信 |
| +1048 | uint32 | Σ(module+112) 缓存 (design 相等性三键之一; module+112 语义推定: id/单价); 不序列化, 高置信 |
| +1052 | uint8 | version (互斥写: ver>0 写 version 否则写 max_version) |
| +1053 | uint8 | max_version (互斥写同门) |
| +1054 | uint8 | is_frame (恒写 yes/no) |
| +1056 | uint32 | manpower (仅正值写) |
| +1060 | uint8 | obsolete (仅真值写) |
| +1061 | uint8 | auto_upgraded (仅真值写) |
| +1062 | uint8 | highlight (仅真值写) |
| +1063..+1065 | uint8×3 | can_upgrade_type / can_upgrade_variant / can_upgrade_modules (仅真值写) |
| +1066 | i16 | legacy parent variant id (−1 = 无; loader case 135 = parent 置 −1, 解析结果写 +1016; `_pParent` 断言); 兼容键, 定案 |
| +1068 | uint32 | role_icon_index (仅正值写) |
| +1072 | SSO | override_model |
| +1073..+1103 | — | = override_model SSO 尾 {size@+1088, cap@+1096} |
| +1104 | uint8 | has_override_sprite 标志 (writer 写门) |
| +1112 | SSO | override_sprite (size@+1128, cap@+1136; 定案) |
| +1113..+1151 | — | = override_sprite 48B 结构体尾段 (结构体 +1104..+1151, sub_14139CBD0 构造 / sub_140153530 析构) |
| +1152 | 匿名结构 (含 SSO) | division_names_group → 串@+8 |
| +1160 | uint32 | design_team id 对.type (0 = 无) |
| +1164 | uint32 | design_team id 对.id (0 = 无) |
| +1165..+1175 | — | = design_team id 对尾 (+1165..+1167) + +1168 = NIndustrialOrganisation::CTraitBonus 对象基 vtable 槽 |
| +1176 | 匿名结构 (16B) | design_team_bonus 数组数据, cap@+1184 / 真计数 u32@+1188 (⚠ 遍历按 +1188 真计数, 勿用 cap — cap 可超 count), 16B 条 {stat_token u32, fixed5 i64@+8}; 受 design_team 门控 (无 dt 的残留数组 writer 不写) |
| +1177..+1199 | — | = CTraitBonus 容器尾 {cap@+1184, count@+1188, alloc@+1192} |
| +1200 | uint32 | number_of_design_team_traits (0 = 不写) |

⚠ stats 数组 (+256) 下标是 EEquipmentStats 枚举 id, 非存档 token — 同 BLD2_NAMES 教训: 两套命名空间勿混。

ideas 容器 writer (0X140BE3C80) 逐元素线性查重只写首现: 容器可含重复 token, 发射端须去重。**writer 侧断言** (0x140BE3C80 内): version(+1052) > 0 分支中 parent(+1016) 为空 → :836「_pParent」断言 (主门 byte_1435E1B52 flags=1, 闩 byte_14333C91F) = 「version>0 蕴含 parent 非空」不变式出口把关; ideas 发射的 token→名转换走 **lexer 双上界** (静态 dword_1435E1ABC / mod 扩容 dword_1435E1AB4) + 慢路夹 **unk_1435E1AD8 (SRWLOCK)** (与 §4.4 性别枚举 token 名缓存同锁对象互证)。

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
| 实例+32 | 8B 元素 向量 | 容器2 (var+136) — 元素 = 8 字节 (0x140185E10 `lea rsi,[rbx*8]` 直证); **= 已挂升级 def 指针数组 (按 def+8 token 升序二分, sub_140F8B310)** |
| 实例+56 | 8B 元素 向量 | 容器3 (var+160) — 元素 = 8 字节 (同上); **= 第二 def 指针数组 (同序; 扁价表路径)** |

**升级成本计算 (sub_140F8DD30, equipment_upgrades_instance.cpp:125, 137 行, 定案)**: 路径A = a4/a5 (起/止等级 u8, 相等返 0) 逐级累加, **类别枚举 = CEquipmentType +224 {0 land / 1 naval / 2 air}** (sub_140C37AC0 单行 getter): 每级成本 = **BASE + RAMP×L**, 总额 `*a2 += 100000 × 每级值` (fixed×1e-5)。六 define 名全定案: dword_143335FA8 = **LAND_EQUIPMENT_BASE_COST** / dword_143336028 = **LAND_EQUIPMENT_RAMP_COST** / dword_1433360C0 = **NAVAL_EQUIPMENT_BASE_COST** / dword_14333613C = **NAVAL_EQUIPMENT_RAMP_COST** / dword_1433361D8 = **AIR_EQUIPMENT_BASE_COST** / dword_143336278 = **AIR_EQUIPMENT_RAMP_COST**。路径B = +56 表二分命中 → 16B 价对 {价1, 价2}, `*a2 = (a6 旗 ? 价2 : 价1) × (a5−a4)` (两字段业务语义与 +56 表适用 def 族未决); 两表皆无 → 0。⚠ 源文件名甄别: 候选池截断名 `rades_instance.cpp` 实为 **[upg]rades_instance.cpp = equipment_upgrades_instance.cpp**。

**CEquipmentVariantReference (栈构引用对象)**; 栈构无独立堆布局 (推定):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +0 | vtable | — | 推定 |
| +4 | uint32 | archetype id | 推定 |
| +8 | uint64 | 未名 qword | 推定 |
| +12 | uint32 | tag #1 | 推定 |
| +16 | uint32 | tag #2 | 推定 |
| +20 | uint8 | 旗 | 推定 |
| +24 | MSVC 串 | 名串 | 推定 |

**archetype 后勤计算** (sub_141372E80, logistics.cpp; 公式定案, PE×14 采样验算):
需求余量 = Σ(需求−损耗)×权重/1e5, 权重 = 过滤表命中 ? 200000−条目+24 : 1e5;
饱和界 ±92233720200000 (溢出哨兵); 国家修正分两类别分支 (其一负值清 0)。

#### 4.23.2 库存 / 装备市场

| 项 | 值 | 语义 |
|---|---|---|
| stockpile | 国家装备库存 (库存池对象基 = **ps+512 CEquipmentVariantPool**, data@+520/count@+532; +536 第二池 = 替换源 data@+544; 另 cc+4024 市场侧) | cc+0 区挂载 (gs+1776 = 编制模板容器单义, 非库存共用) |
| 国家侧 equipment_market | cc+4024 数据源 (market_request_automation / market_stockpile / subsidies) | 与全局块不同对象不同数据 (国家侧 view writer 0X141AA6A30 族, def 在其对象+120) |
| market_stockpile 装备池条目 | 池 writer 0X141012DB0 | **条目门 = amount(raw i64)≠0 或 allow_zero_entries≠0**; `[N]` 编号只对发射条目递增 (门外的编号会整体前移) |
| 附属国库存包装器 +840 | set_equipment_fraction 写点 (包装器层 +840; 推定) | 单批孤证 |
| 国家侧 market automation | 外层对象 +96/+97/+98 三布尔 | market_request_automation 开关族 (cc+4024 双层: 外层 = rp(cc+4024), 内层 = rp(外层)) |
| 国家侧 market_stockpile 池 | 内层 {d@+88, count@+100} | 16B 条 {variant ptr@+0, amount fixed×1e-5@+8} (与全局块 §4.23.3 不同对象) |
| 国家侧 合同信号 | 外层对象 **+136 = 成交挂信号 / +200 = 取消挂信号** (均 boost::signals2 信号, px≠0 断言) | sub_140DEB660 = boost::signals2 槽连接器 (364 行: EnterCriticalSection(信号+24) + signal_template.hpp "_shared_state.unique()" 双断言 + shared_ptr.hpp 六处 "px != 0" + 槽链遍历 + _InterlockedIncrement); 成交时买卖双方 +136 各挂一次 (sub_140DECDD0 尾), 取消时 +200 各挂一次 (sub_140DEC540, §4.23.3a) |
| 国家侧 补贴容器 | 外层对象 +32 = CEquipmentSubsidyContainer {i64 CIC 总额@+0, CPdxArray\<CSubsidy\> {data@+8, cap@+16, count@+20}, 元 48B} | 批量移除 sub_1413B51F0 的宿主; +264 = shared_ptr (sub_1413B7AB0 取走的补贴集, px≠0 断言) |

⚠ 勘误收口 (原「+136 挂链容器 vs +200 待裁」): sub_140DEB660 体直证 = boost::signals2 槽连接器, 故 **+136 与 +200 是同外层对象上的两个信号** (成交 / 取消), 非链表头偏移分歧 — 「容器内部布局未决」的旧读删除, 信号体 +24 = shared_state (临界区) / +16 = 槽链表头。

**subsidies 补贴条** (国家侧 market 对象内; e = 条目基; 读取链 sub_1413B29C0 / 140DDD510, 三档存档实证):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | fixed×1e-5 | cic |
| 元素+8 | 匿名结构 (NNB 形状)* | archetype 宿主, archetype = ru32(rp(e+8)+8) |
| 元素+16 | CPdxArray<CCountryTag> (24) | 国家列表 {data@+16, cap@+24, count@+28} (CSubsidy 定案, 同 contract_draft.subsidies 条表; 「串宿主」旧读与 ctor/容器消费/swap 三证矛盾) |
| 元素+40 | byte | HasCountryListCondition 之非 (0 = 有国家列表; 1 = 无 → 条件求值) |
#### 4.23.3 全局装备市场 (NInternationalMarket)

| 项 | 值 | 语义 |
|---|---|---|
| 挂载 | mkt = rp(gs+1000) | gamestate writer 0X1401F2E40 调用点 0XUNRESOLVED `mov r8,[rsi+1000]`; 空指针整块不写 |
| 类 | NInternationalMarket (RTTI); mkt 对象 = CPurchaseContractsContainer 120B | 分配点 gs 重建 sub_1401EC950: malloc 0x78 → ctor sub_140DEADD0 |
| mkt 布局 | 内嵌 96B {contracts@0, pending-removal 延期删除架@24, by_seller 索引@48, by_buyer 索引@72 (均 333 槽 = 国数)} + requests@96 | 延期删除架 = move-push 进, DailyUpdate 尾 flush 删 |
| 块构成 | 仅 contracts + requests 两字段 | loader 直证: 成员分发 sub_140DF3C60 case 13230 = requests / 15105 = contracts, 其余 skip |
| writer | sub_140DF42C0 | — |

**contracts** (容器 @ mkt+0; 元素 8B 指针 → CPurchaseContract; [N] 序 = 数组序, 创建/插入序, 不按 id 排序):

| 偏移 (mkt) | 类型 | 内容 |
|---|---|---|
| +0 | CPurchaseContract** | data |
| +8 | — | cap |
| +12 | uint32 | count |

**requests** (容器 @ mkt+96; count = 440 国家槽, idx0 哨兵; 槽 i 归属国 i-1):

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

内表元素 = 8B 指针 → CPurchaseRequest (vtable 0x142A28ED0, ctor 0X1419D6020; ~240B: CReferenceObject 头 + def@+24 216B 与合同 def 同构)。

requests 存档形态 (稀疏数组 writer sub_140DF48B0): `requests={ <总槽数=440> index=<国槽 idx> data={ { contract_definition={…} id={…} } } }` (index=524 仅 icount≠0 槽; data=240; 元素 def writer = sub_140DF1EC0 与合同 def 同函数, id = B320(11, req+8))。

> `index` = 槽序号 i (0 基), 非国 id; 槽 i 归属国 i-1 (idx0 哨兵无归属)。
> 全空槽 (无任一 icount≠0) 时 writer 改发裸总数 `requests.#1`, 不出 index/data 块。

**CPurchaseContract** (808B = 0x328; vtable 0x14296B750; writer 0X140DF4540; ctor 0X1419D4370) — 写序 = id → contract_definition → delivery_route_handler → days → contract_delivery_state → contract_meta → variables (表行序 = 偏移升序, 写序以本句为准):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | id 对.type (type@+8=81) | B320: id = a3[1], type = *a3 |
| +12 | uint32 | id.id — id 对之 id |  |
| +13..+23 | — | = CReferenceObject 头尾 {u8 注册标志@+16, pad} (头 24B {vtable@0, idpair@+8/+12, u8@+16}, 基 ctor sub_14221E410 直证) |  |
| +24 | 内嵌 | contract_definition (def, writer 0X140DF1EC0) | 下表 |
| +25..+239 | — | = contract_definition 内嵌 216B 本体 (+24..+239; ctor sub_140302250 逐字段拷) |  |
| +240 | 内嵌 | delivery_route_handler = CEquipmentConvoyClient (vtable 0x14296B6B0, 基 CConvoyClient) | 下表 |
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
| +624 | std::function\<void(CPurchaseContract*)\> 64B | 完成下架回调 {_Space[56], _Impl@+56; 探针 _Impl vtable=0x14296B588} | 不序列化 |
| +688 | std::function\<void(CPurchaseContract*)\> 64B | 周期未竟回调 {_Impl vtable=0x14296B5C0} | 不序列化 |
| +752 | 内嵌 | variables = CVariables 56B (+752..+807 恰满; 全布局 §4.13 — vtable/种子对/桶哨兵/count/mask/extra/load_factor=0.9/尾槽) | 空表三闸门 §4.13 |

完成下架回调 lambda_1 (CEquipmentMarketSystem::SetCallbacks 挂载): 容器移除 + 国家+168 ended 信号 + 全局 off_1430B15B0。

周期未竟回调 lambda_2: 国家+232 changed 信号 + 重启交付周期。取消 = 独立路径 CancelContract (sub_140DEC540, :277 "_ContractsContainer.Contains( Contract )" 断言) → sub_140DEC380(off_1430B15B8) 取消 on-action + 买卖双方外层对象 (rp(cc+4024)) **+200 取消信号**槽各 sub_140DEB660 一次 (槽位归属: sub_140DEC540 经 sub_140BB4390 = gs+784 国数组取 CCountry\*, sub_1406CF600 = `*(cc+4024)` pdx_scopedptr.h:119 断言, 故槽在**外层对象**非 cc 本身; 高置信)。

**全局信号名表** (PE .data 三指针表 @ 0x1430B15A8 直读): `on_contract_started` (0x1430B15A8, 成交 sub_140DECDD0 第七步) / `on_contract_finished` (0x1430B15B0, lambda_1 下架) / `on_contract_cancelled` (0x1430B15B8, CancelContract)。广播器 sub_140DEC380 = 按信号名 + 主体 CReferenceObject 的 CEventScope 派发: sub_140534FE0 建 scope (hash 由 sub_142233FA0(path, line) 算入 scope+16) → sub_14053B1B0 解析主体 ref (ref.h 断言) 存 scope+128 → 经 TGameItemDatabase 单例 (qword_14332EFA0, gameitemdatabase.h:149 `_pInstance` 断言) sub_140A792B0 按名查 → sub_140A79BA0 派发 (**onaction.cpp:243 锚 → 库身份 = on-action 库, 高置信**; payload = 合同对象)。即「全局信号」实为**脚本 on-action**, 三个挂点对应成交/取消/周期未竟; 通道 id = sub_142233FA0("…equipment_market_system.cpp", 28) (random.cpp:181 杂凑族), 184B 载荷记录 = sub_140534FE0(rec, id & 0x7FFFFFFF) 建 + sub_14053B1B0(rec, a2, 1) 填入合同。未决: on-action 库类型名与 §4.19/§4.26 已录库族的关系 / 通道 id 消费端与符号位用途。

contract_definition (def = c+24; 表行序 = 偏移升序, 括注 = 合同绝对偏移; 落盘写序 ≠ 行序, 见下):

| def 偏移 (合同绝对) | 类型 | 名称/语义 |
|---|---|---|
| +0 (+24) | CEquipmentVariantPool | prices (下) |
| +64 (+88) | int32 | contract_draft.seller |
| +68 (+92) | int32 | buyer = tag_id → 串 |
| +72 (+96) | CEquipmentVariantPool | contract_draft.equipments 请求池 |
| +136 (+160) | uint64 | 补贴 CIC 总额 (ctor = 0 从 draft 拷贝; 不序列化; IsComplete ⇔ factory_cic_progress == +208−+200) |
| +144 (+168) | 匿名结构 (48B 形状) 向量 | contract_draft.subsidies {data@144, count@156}, stride 48 (元素布局见下表) |
| +168 (+192) | uint32 | contract_draft.speed |
| +176 (+200) | std::map | price_levels → levels: head@176, size@184; **节点 key = idpair 8B {type@+28, id@+32}** = **CEquipmentVariant 自身 CReferenceObject idpair** (L2 门 = 全局 CIdentifier 注册表可解析 sub_14221F310, 不可解析静默丢弃; 读侧 sub_1419D3FD0 / 写侧 sub_1419D40F0 双证), value 枚举 u32@+36 (**落盘 token 实证 = 0→19365 low / 1→119 normal / 2→19367 high**, writer sub_140DF4390 值发射直证; 档因子映射 sub_1413B8CC0 链: 0→LOW_PRICE_LEVEL_FACTOR 0.75 (qword_143331BA8) / 1→标准 100000 / 2→HIGH_PRICE_LEVEL_FACTOR 1.25 (qword_143331CE8) / ≥3→断言后落标准**); 中序 = 写序 (map 形态定案: 收集 sub_1419D3E00 → 写 sub_140DF4390); **文本装载链 = sub_140DF2C40 (std_map 装载器) → sub_140DF2600 pair** (first = CID 列表跳读 0x14221F970, second = 内联 token 开关 low/normal/high→0/1/2, 断言 international_market_serializer.cpp:378; 已存键覆写 value — §4.00 std_pair_parser 段) |
| +192 (+216) | uint8 | 懒计算完成标志 (ctor = 0) |
| +200 (+224) | int64×1e-5 | 补贴抵扣 = min(+136, 总价×F/(F+1e5)) (F = PURCHASE_CONTRACT_SUBSIDY_BONUS_SPEED_FACTOR; 不序列化) |
| +208 (+232) | int64×1e-5 | 合同总 CIC 价 (Σ variant IC×价格档因子×IC_TO_CIC_FACTOR, market_core.cpp 断言锚; 不序列化) |

def 落盘写序 (writer sub_140DF1EC0, 非表行序): contract_draft (seller → buyer → equipments → speed → subsidies) → price_levels → prices; 每段仅在该段有内容时出块, 空 subsidies / 空 price_levels 不出块。

contract_draft.subsidies 条 = **CSubsidy 48B** (ctor sub_1413B2790, market_equipment_subsidy.cpp:37/:38/:49 三断言直证; 定案; 收尾源卖方列表释放块: a4 = 28B 卖方 tag 容器 {data@+0, count@+8, cap@+12, alloc@+16, 通配字节@+24}, 通配字节 ≠ -1 ∧ == 0 ∧ data 非空 → count@+12 = 0 → alloc vtable+16 释放 + data/count 清零; 通配态 -1 不释放 (推定共享/静态表)):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | i64 (fixed×1e-5) | _CicAmount (ctor 断言 > 0) |
| 元素+8 | 匿名结构 (NNB 形状)* | _TargetArchetype (指涉对象 +1365 = IsArchetype 旗), archetype = ru32(rp(e+8)+8) |
| 元素+16 | CPdxArray<CCountryTag> (24) | 国家列表 {data@+16, cap@+24, count@+28} (ctor 走 sub_1403021E0 容器拷构造; sub_1413B2940 按容器消费; std::swap 特化元素类型名直证) |
| 元素+40 | byte | HasCountryListCondition 之非 (0 = 有国家列表 → targets 交集; 1 = 无 → 条件求值过滤) |
| 元素+41..+47 | — | 填充 (stride 48) |

CEquipmentConvoyClient (cli = c+240; 派生 writer 0X1419D7490 → 基类 0X140CBE140):

| cli 偏移 (合同绝对) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +248 | uint32 | id.type — id 对之 type (对 {type@+248=4713, id@+252}) | has-id 标志 u8@c+256≠0 才写 |
| +252 | uint32 | id.id — id 对之 id | 同上 |
| +253..+263 | — | = CReferenceObject 头尾 {u8 注册标志@+256 = has-id 写门, pad} |  |
| +264 | int32 | country = tag_id (船队归属国) |  |
| +272 | 内嵌 | convoys_subscriber = CConvoySubscriber (vtable 0x14295c0f0, writer 0X141022CB0): convoys u32@c+280 / total u32@c+284 | 块仅在 total≠0 时写 |
| +273..+311 | — | = CConvoySubscriber 内嵌 24B 本体 {convoys@+280, total@+284, u32@+288} + qword×2@+296/+304 (不序列化) |  |
| +312 | fixed×1e-5 | efficiency |  |
| +320 | fixed×1e-5 | efficiency_due_to_lost_convoys |  |
| +321..+359 | — | = vector 24B@+328 (不序列化, 未名) + idpair 哨兵@+352 (=qword_14333D528, 不序列化) |  |
| +360 | uint32 | request |  |
| +368 | CEquipmentVariantPool | equipments 在途池 |  |
| +369..+431 | — | = equipments 在途池 CEquipmentVariantPool 64B 本体 (+368..+431) |  |
| +432 | uint32 | length 航线长度 |  |
| +436 | uint8 | type = 2 |  |
| +437..+447 | — | = +440 = CResourceDeliveryRoute* (卖方 CCountryResources(cc+4600) delivery_routes@rs+1928 按买方国 idx; route vtable=0x14295C320, route+56 convoys_owner = 买方 tag 探针实证; Status 本体在 cc+4024) + pad |  |
| +448 | fixed×1e-5 | drh.efficiency |  |
| +456 | fixed×1e-5 | drh.sunk_convoys | fixed5 缩放 |
| +464 | uint32 | drh.days | 原值 |

**CEquipmentVariantPool** (64B; vtable 0X142748040; ctor 0X14100C710; writer slot2 0X141012DB0; 3 处复用: prices / draft.equipments / cli.equipments; 师 +840/+1472 与 CRaidInstance+272 同 ctor 同 vtable — SEquipmentPool 同体异名, §4.22 互证; pool1 stride 24 / pool2 stride 16 分用定案, 证据: writer 0X141012DB0 循环 `v5 += 16` / ctor 0X14100C710 pool1 增长 `24*n` / push 0X141012230 双池并见):

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

写侧 LUT = 0x1413E8820 (switch id→token), 读侧反查 = 0x1413E81B0 (token→id, 未中 = 78)。CEquipmentStats 元素 = 16B {stat_enum u32@0, value i64@8} (稀疏集, value≠0 才写); 装备统计数组 = variant/archetype 侧 i64[78] 按此序; 78 = EEquipmentStats::NUMBER_OF_EQUIPMENT_STATS (stat_helper.cpp:157), 变体侧逐时合算件 = sub_140BDFA70 (槽 i = (A+B/count)×(M+1e5)/1e5; +832 = 槽 72 特判, 整数断言后下取整 1e5 倍数)。

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

**CEquipmentStats** (32B; vtable 0x142718958; writer 0x140632FB0 / reader 0x1406329D0→0x140632840; clear 槽[9]=0x140631ED0): {d@8, cap@16, count@20, alloc@24}; 元素 16B {stat_enum u32@0, value i64@8}; writer value≠0 才写 (id→token 走 §4.23.5 LUT); reader 已存在同名时**累加** (警告 "Duplicated equipment stat type")。

**CEquipmentStatsGroup** (104B; vtable 0x142937DF8; **writer = CFG 空桩 = 纯脚本解析不落盘**; reader 0x140632A60): +8 CEquipmentStats add_stats (15213) / +40 add_average_stats (15223) / +72 multiply_stats (15214)。

**CEquipmentBonus** (56B; vtable 0x1427189B0; writer 0x140632DE0 / reader 0x140632830→0x1406323B0): 基 CEquipmentStats@8..+28 + **+32 f64 数组 = 按地形 A 族下标的 attrition 值** {d@32, cap@40, count@44}: writer 先写 attrition = { terrain = f64 ×N } (地形名自 CTerrainDatabase 0x332F0A8, 零值不写); reader 键 10531 按地形查 def+136 = A 族下标落 +32+8×idx, 未知地形告警 (equipmentbonus.cpp:274)。

**CSpecificEquipmentBonus** (~120B; vtable 0x142718A08; 基 CPersistentWithToken@0 + THashedKeyValueTrait@16; **自有 wrapper 类 (serfam 盲区)**: Save w 0x140632D90 / writer 0x140633090 / Load w 0x140632130 / reader 0x140632B10): +8 加成类型名 token / +16 名 SSO (+48 ci-FNV) / +56 equipment→CEquipmentBonus hash 图 / +112 instant 旗 (13428) / +116 map 键 hash。名校验 = **script_enum_equipment_bonus_type 注册库 0x332EED0** (§4.26.8)。存档形 = `<加成类型名> = { instant = <bool>; <equipment token> = <bonus 块> ×N }`; = named_equipment_bonuses 容器 (cc+376 块 10206, 200B 元) 本体。

**CTraitEquipmentBonus** (~160B; vtable 0x1427EA5F8; 基 CSpecificEquipmentBonus 同槽全共享; 独有 dtor 0x14071DE80): +128 trait 名 SSO (运行时缓存, 不落盘)。
#### 4.23.7 升级/模块/装备组/候选设计族

**CEquipmentUpgrade** (升级定义, ~352B; vtable 0x1429D4E18; **writer = CFG 空桩**; reader 0x141538B40; 校验 vtable[7]=0x1415380D0): +8 upgrade 名 token / +24 显示名 SSO (CCountrySpecificNamedItem) / +64 CEquipmentStatsGroup / +168 CEquipmentBonus (attrition 仅此可达, 裸 stat 先被 multiply 吃掉) / +224 cost 货币枚 (10323: 0 land/1 naval/2 air) / +232 CEquipmentStats linear_cost (19499) / +268 max_level (11875) / +272 level_requirements 容器 (19549, 96B/条 = {level u8@0 排序键 + CAndTrigger 88B@8}, reader 0x141538320) / +296 resource_cost_thresholds 容器 (19734, 184B/条 = CEquipmentUpgrade::CUpgradeCost = {byte 键@0 + CStrategicResourcePool 176B@8}, reader 0x141538D60) / +320 abbreviation SSO (10557)。

**CEquipmentModuleConversion** (模块改装转换条; vtable 0x1429D4480; writer 桩; reader 0x14152FCD0): +8 = **源模块指针 (后处理 sub_14152E8C0 由 +16 token 解析填充; 失败报 "Invalid source module")** / +16 module (15222) / +20 module_category (15221) / +24 i64 convert_cost_ic (15219) / +32 容器 convert_cost_resources (15220)。

**CEquipmentModuleSlot** (模块槽; vtable 0x14295B788; writer 桩; reader 0x141645F30): +8 slot 名 token / +16 u8 required (12481) / +24 容器 allowed_module_categories (15209) / +48 gfx SSO (12472)。

**CEquipmentGroup** (装备组定义; vtable 0x142719610; writer 桩; reader 0x140A0B160): +8 组名 token / +16 icon SSO (181) / +48 description SSO (15906) / +80 equipment_type 串列 (16217)。**GetIconString 链 (sub_140A092E0, 266 行)**: ① +16 icon SSO 非空 (len@+32, cap@+40, MSVC SSO) → 直接拷用; ② 否则取 +8 组名 token, **token 357 = "none"** (lexer 查表 sub_1424BC260) → 匿名组分支, 需 +92 dword == 1 (推定 = MIO 组类型标记), 以 +80 equipment_type 经 TGameItemDatabase 单例 (qword_14332EED0) sub_14047D7B0 查原型 CEquipmentGroup — 查到 → 递归 sub_140A092E0; 未查到 → `"GFX_military_industrial_organization_" + 串`; ③ 否则 → `"GFX_" + 组名 token 串`; ④ key 不在图标注册表 qword_143453090 (sub_142238DF0 判存在) → 错误日志 `"GFX key %s is missing (cannot represent %s)"` (cpp:70) → 回退 "GFX_idea_unknown"。显示名 getter sub_140A09030: +64 (= +48 SSO 长度字段) 非零 → 用 +48 串, 否则用 +8 token 名。⚠ **勘误 (待裁)**: +48 的 description 与显示名同槽冲突 — 候选为 +48 实为 name/display SSO (description 另在它处), 或错误信息确实打印 description; 需 description 的 writer/reader 以外消费点交叉验证。**CAnonymousEquipmentGroup** (vtable 0x142719668; 基 + CEquipmentGroupDatabaseListener@104 + TListenerTrait@104): +136 u8 已注册旗 ([9] 门路)。**CEquipmentGroupDatabase** (vtable 0x142719790; 非 CPersistent): vec@96/cnt@108 (idb equipment_group 已挂 ✓) + listener@+128; reload 槽组 0x14016CAD0/0x14016A740。**CEquipmentFilter** (**40B** {vtable, 8B 键@+8, values 向量@+16}; 注册表 = CEquipmentDatabase+456; vtable 0x142937F40): +8 name (27) / +16 values (19260)。

**CDuplicateArchetypeDefinition** (duplicate 原型 def, **272B**; 应用链 = 0x1409F7090 克隆原型 (db+272 子类型区间, 新名 = def 名+源名去公共前缀尾段, 0x140C94520 应用覆盖, 写 db+408 载具编成权重表) + 0x1409F6DA0 驱动 (逐 def FindByToken 找原型 :918/:925); vtable 0x142937EF0; writer = 断言 stub 不落盘; reader 0x140C98DD0): only_duplicate_archetype(12431)→+16 u8 / module_slots(15208)→+17 u8 (仅 none=357 合法) / archetype(12103)→+20 / type(225)→+24 子对象 / ai_type(12955)→+32 / default_carrier_composition_weight(13699)→+40 (+48 旗) / variant_name(19748)→+128 串对 map / substitute(12375)→+176 (+180 旗) / sprite(61)→+184 串 / picture(464)→+216 串 / air_map_icon_frame(14310)→+248 (+252 旗) / interface_overview_category_index(13900)→+256 (+260 旗) / forbid_mission_type(12391)→+264 子对象。

**CPotentialDesignCollection** (候选设计集; **sizeof 80B**; vtable 0x142A1B640; ctor sub_14191E8E0(名串, 0); writer 0x141923D30 / reader 0x141922360): +8 集合名 SSO / **+48 u64 category 位掩码** / +56 designs 指针数组 {d@56, count@68}: land = 0x408000003C / naval = 0x80004003C1 / air = 0x1F0037FC00 (与 §4.23.1 CEquipmentVariant+1032 _Category 位段互证); 落盘形 `<名> = { category = land|naval|air; equipment(12110) = <设计块> ×N }`。**宿主 = CPersistedDesignsDb 单例 (BASE+0x333C5E8 解引; 可为 0 需判空), 链 = db+24{d}/+36{c} → 本类\* → +56 designs → 元素 = SPotentialDesign\* (384B 落盘副本, 非 CEquipmentVariant\*)**; 活体 (3 集合: land 1 / naval 1 / air 0 设计)。**db reader 块处理器 sub_141921C30**: malloc 0x50 → ctor → **vt[3] Load wrapper 自载** (category + equipment 子块) → 类别去重 (扫 db+24 表逐元比 elem+48; 同类别重复 → 断言 "Same category exists multiple times in the session file, expect corruption" :418) → `(category_mask & obj+48) != 0` 入表, 否则 vt[0](obj, 1) 销毁。**db Load 分派 (sub_1419214F0)**: 238 → version u32@db+72 / 12933 (tank_designs) / 12934 (ship_designs) / 12935 (plane_designs) → 块处理器 (a4==0) 或 sub_141921730 (a4==1) / 其他跳块; 收尾三族掩码后处理 sub_141920F70 ×3 (§4.23.7 三族掩码一致)。**Load 入口初始化序** (a2 = ctx_out): byte a2+0 = 0 → sub_14191E7E0(a2+8) → sub_14191E6E0(a2+64) → sub_14191E5E0(a2+136) → sub_141497CF0(a2+208) → dword a2+376 = 0; unwind dtor = sub_14177B0F0(a2); 三族掩码调用序 = land (0x408000003C) → air (0x1F0037FC00) → naval (0x80004003C1)。

**图形池族 (idb equipment_graphic 已挂 0x332EEC8; 运行期源 = equipment_graphic_database.cpp, 数据源目录 = gfx/interface/equipmentdesigner/graphic_db)**: CEquipmentGraphicDatabase (vtable 0x142719578; 非 CPersistent): 项数组@+8 + **4 张内联 RH 表 @+48/+80/+112/+144 (四表条件 = 72B/56B/80B/80B**, 迭代步距直证; 伴随 CDatabaseReloader vtable 0x14271BEE0); 装库后立即跑**校验驱动 0x140A05E40 → 0x140A08120 → 0x140A07EF0 三链** (pool 引用三重校验: GFX 名存在性 qword_143453090 / 文件存在性 sub_1424E0B90 / 实体名存在性 qword_143468F00, 三错串 :49/:58/:72; 未知类型 "Unknown equipment type" :106)。CEquipmentGraphicPool (vtable 0x1429389F0; writer 桩; 296B): 键 limit(10762)→+8 子解析 / cultures(11534) / ideologies(12241) / sub_units(12176) / weight(593) / models_weight(16903)→*(a1+96)+16 / icons_weight(16904)→+8 / **icons(19742)→+152 48B 条向量 / models(19903)→+176 串向量**; **icons 48B 条 = {+0 u8, +4 tag (0=GFX/1=文件), +8 串, +40 u64}**, tag 判据 (工厂 0x14139D460, icon_entry.cpp:38) = 串含 `/`或`.` 即文件、否则必须 `GFX_` 前缀。CEquipmentGraphicPoolTypeMap (名录; vtable 0x1427194F8): type→pool 映射薄壳 = {vtable@0, +8 池容器 (元素 **0x128 = 296B**; 原「0x28B」系笔误, 高置信)}, 唯一键 19241 `pool`。CEquipmentOverview (名录; vtable 0x142A55F18): 装备总览 GUI 窗 "equipment_overview_window", CReloadableInterface@0 + CTooltipHandler@40, 内嵌 CArmyManpowerValues@+152。

**装备 attrition 售后小件**: CEquipmentBonus attrition 通道与 terrain def+136/def+8 双通道见 §4.26.7。

#### 4.23.7a CEquipmentModule (装备变体模块 def)

728B (0x2D8); 主 vtable 0x142937E50 (9 槽 CPersistent 契约): [2] writer = guard_nop
(**def 不序列化**); [3] Load = 自定 DLC 锁 wrapper 0x14152EE00 (先盖 +712 锁定对
再走标准驱动 — serfam 指纹失配缺席原因, §4.00.1 盲区家族; [4] 仍真 reader);
[4] reader = sub_14152F4A0 (24 键全表); ctor sub_14152B9E0; Null Object vtable
0x142938090 (库 Array[0])。装载: common/units/equipment 递归, 顶层块
equipment_modules (15210, per-file 分发 sub_1409F1FC0); **CEquipmentDatabase 单例实例槽**
qword_14332EEC0 (malloc 0x1E8; 与 idb 规格表行 equipment 的 key 0x332eec0 对应, free_convoys 取值器 gameitemdatabase.h:142 断言 `_pInstance` 直证 — §4.34.30); 按 token 线性查 sub_1409F8460 (比 +8); 热重载 = 重名告警后
sub_14152E6F0 原位清空重 parse (保位覆盖)。

| 偏移 | 类型 | 语义 | 键 | 置信 |
|---|---|---|---|---|
| +8 | uint32 | 名字 token (ctor 自块名串; 库查找键) | — | 定案 |
| +16 | uint8 | 有效旗 (ctor 1; Null Object 0) | — | 定案 |
| +24..+55 | SSO 32B | 名串 (报错/GUI 缺省名源) | — | 定案 |
| +64 | uint32 | category 模块类别 token | 702 | 定案 |
| +72 | uint32 向量 | gui_category u32 token 列表 (空时后处理回退 push 自身 category) | 15522 | 定案 |
| +96 | int32 | parent 母模块 token (−1 = 无) | 135 | 定案 |
| +104 | CEquipmentModule* | 已解析母模块指针 (非 owning) | 后处理 | 定案 |
| +112 | uint32 | **母链继承深度 (祖先数)**; variant+1048 = Σ 本字段 = 设计相等性指纹 | 后处理逐级 ++ | 定案 |
| +116 | uint32 | **allow_mission_type 任务位掩码** (OR 累加); variant+1040 = type 基值 ∨ Σ 本字段 再过 DLC 门 | 11057 | 定案 |
| +120 | uint32 | add_equipment_type 类别位掩码 | 15249 | 定案 |
| +128 | uint32 | allow_equipment_type 位掩码 | 19735 | 定案 |
| +136 | uint32 | forbid_equipment_type 位掩码 | 19736 | 定案 |
| +144 | uint32 | forbid_equipment_type_exact_match 位掩码 | 10556 | 定案 |
| +152 | 匿名结构 (16B 形状) 向量 | forbid_equipment_type_exact_match_for_category 16B 条 {category token, mask}; 同类别重复报错 | 10586 | 定案 |
| +176 | uint32 向量 | forbid_module_categories u32 token 列表 | 12102 | 定案 |
| +200 | SSO 32B | abbreviation | 10557 | 定案 |
| +232 | SSO 32B | gfx (空 = 回退模块名) | 12472 | 定案 |
| +264 | SSO 32B | sfx | 15571 | 定案 |
| +296 | CEquipmentStatsGroup 96B | stats 块 (reader 兜底键 add_stats/multiply_stats 等全喂此) | — | 组形态定案 |
| +400 | 匿名结构 (112B 形状) 向量 | mission_type_stats 112B 条 {mission 位掩码, CEquipmentStats}; 同掩码重复报错 | 11942 | 定案 |
| +424 | int64 fixed | **build_cost_ic 缓存** (后处理自 stats 表查枚举 77; 消费 = 变体造价差) | — | 定案 |
| +432 | 匿名结构 (16B 形状) 向量 | build_cost_resources 16B 条 {资源 token, fixed64 量} | 15216 | 定案 |
| +456 | fixed×1e-5 | dismantle_cost_ic | 15217 | 定案 |
| +464 | 匿名结构 (NNB 形状) 向量 | dismantle_cost_resources | 15218 | 定案 |
| +488 | int64 | xp_cost 值 (pdx optional 值位; ctor 填 0xAA 调试位) | 19741 | 定案 |
| +496 | uint8 | xp_cost isSet 旗 | 19741 | 定案 |
| +504 | 匿名结构 (NNB 形状) 向量 | allowed_module_categories (槽名 token → 类别 token 列表; **条形 = 8B {槽 token, 类别 token}**) | 15209 | 语义定案 |
| +528 | 匿名结构 (NNB 形状) 向量 | can_convert_from 56B CEquipmentModuleConversion 条 (后处理解析源模块到条 +8) | 14302 | 定案 |
| +552 | 匿名结构 (NNB 形状) 向量 | critical_parts 字符串列表 | 15358 | 定案 |
| +576 | 匿名结构 (NNB 形状) 向量 | critical parts 解析结果 ptr 数组 (FNV 快查; 未知名报错) | — | 机制定案 |
| +600 | 内嵌 CAndTrigger 88B | allowed 可用性触发器 (默认 token 10600 "and"; 求值门 +620) | 12263 | 定案 |
| +688 | 触发器 shared_ptr | **equipment_modules 文件级 `limit` (10762) 触发器** (+688/+696, 块尾统一写同块全部新模块) | 块尾 | |

> 变体侧聚合缓存 (消费链收口): variant+928 填充循环 sub_140BE0260;
> +1040 = type+1040 基值 ∨ Σ模块+116 再过 DLC 门 (sub_140BDF420);
> +1048 = Σ模块+112 (设计相等性指纹, sub_140BDC710 三键);
> +1056 = type 基数 + Σ模块+704 (manpower)。
> 模块 +112 = 母链继承深度 (设计相等性指纹); +116 = allow_mission_type 位掩码。
> sub_140BCD0D0 = **GetStatByTerrainIndex(var, {i64\* cell}, terrain_idx)** — +928 单格聚合器,
> 三通道 ideas/named_bonus/upgrades (upgrades = def+200 per-地形数组 ×level/1e5;
> equipmentvariant.cpp:1779); variant+928 填充循环在 sub_140BE0260;
> 78 槽统计合算内步 = sub_140BDFA70 (§4.23.5 头注)。

**equipmentvariant.cpp 簇方法群清册 (全簇定案)**: RefreshStats 总入口 = **sub_140BE0260**:
空军门 (全局掩码 sub_140F87A10 & +1032 & 0x1F0037FC00) → per-mission stats (+880, 40B/条)
重建分支, 非空军走 78 槽合算 sub_140BDFA70; 共同尾 = +928 地形聚合 + +1044 (Σ升级条+8) +
+1056 (type 基+Σ模块+704) + +1048 (Σ模块+112) + +1040 missions 重算 (return sub_140BDF420)。

| 函数 | 身份 |
|---|---|
| 0x140BCD2F0 / 0x140BCD610 / 0x140BCD930 | GetStat 三兄弟 (token 键 / 逐字节同体双编译 / 对象键变体): ideas → named_bonus → design_team_bonus (+1168) → upgrades multiply_stats×level → modules multiply_stats 五通道累加到出参 |
| 0x140BD2D70 | AddIdea: +208 线性查重 push (dupe 断言 equipmentvariant.h:623) |
| 0x140BD4BC0 | 设计器造价: (XP 分量 0x140BD60C0 + 第二分量 0x140BD5980) × (100000+token 471..474+archetype token)/1e5 (下限 100000) × (1e5−archetype 折扣)/1e5; token 471-474 实名待裁 |
| 0x140BD5440 | IsProducedOrPossessed 五源: creator 国 ps+512 库存池 / 国+56 池 / ps+88 产线 (同 type+version+creator+origin) / gs+1008 表 sub_140E85750 / 海军型逐国师池 +840 |
| 0x140BD70E0 | ChangeEquipmentType 核心: 栈构新型默认 upgrades; 旧 upgrades 新型无效且 !keep → 败; 逐 type+112 槽 (80B, 名@+8) 二分旧模块保留/取默认, 必需槽无解败; 成 → 盖 +1008/+112/+136/+160/+184/+1032 + 重算 |
| 0x140BDD610 | SetModule(slot_token, module): type+112 槽合法性断言 :2462; +184 二分 (升序) 插入/替换/删, 计数 +196 |
| 0x140BDD7F0 | ValidateAirWeightThrust: 总 thrust (stat 68) < weight (67) → "EQUIPMENT_DESIGNER_WEIGHT_EXCEEDS_THRUST"; 逐 +880 per-mission 条 (mission_bits ∧ +1040) 违者累计位集出 "…_FOR_MISSIONS" 文案 |
| 0x140BD7EF0 | CreateLicensedVariant(base, receiver): **creator = 接收方 / origin = base creator / version 原样继承** (与 §4.8 lp 条目互证); 拷 name/sprite/override_model + ideas 迁移 |
| 0x140BD81D0 | CreateUpgradedVariant: **version = 根 (沿 +1016 链按 +32 符号定向) +1053 max_version + 1**; 独占调用方 = **0x1401D2EE0 变体创建分发原语**; 0x1401D2D80 = 许可创建原语 (7EF0 独占) |
| 0x140BDF680 | ReloadIdeasFromCountry: creator/origin 国 ps+352 表过滤 (sub_140631E70) 入 +208 去重 |
| 0x140BDF910 / 0x140BE1960 | RecalculateCategory / SetCategory(显式): +1032 = sub_140BD3A50(类别源, type, +184) 合成; 类别源 = **sub_140C95710 = type+1344 非零 ?: 基原型 (+1240) →+1344** 尾挂 MIO 重建门 = gs 非空 ∧ *(gs+2613)==0 才调 sub_140BE2450 (MIO trait bonus 重建; 装载期跳过推定) |
| 0x140BE1550 | ApplyIdeasAndBonuses: 清 +220/+244, ideas 与句柄分别过滤入 (+2676/:2692/:2697 断言族) |
| 0x140BE2270 | SetAllUpgrades: sub_140F8E250(+104, creator, list); 调用方含 AI 旧版升级路 0x1410BAE50 |
| 0x140BE2980 / 0x140BE2A70 | MarkCanUpgradeType 单/批: newType archetype 数组 (+1168/+1180) 含旧型 ∨ 同基原型 (+1240) ∧ 谓词 → +1063 = 1 同型 (newType == +1008) 短路不置 +1063 (单/批同) |
| 0x140BD6FC0 | 应用设计核心: +1008 != newType → 整委派 sub_140BD70E0 (ChangeEquipmentType, a3 = keep 旗推定); 同型 = SetAllUpgrades 0x140BE2270 (creator = variant+28 直证, 失败日志 :2363) → +196 清零 → 模块向量 {d@+0, c@+12} 16B 元 {u32 槽 token, u64 module} 重放 SetModule → RecalculateCategory → RefreshStats(1)。parent 解析本体 = 0x140BE1A00 (+1066 legacy id ≥0 门; 键 = (type, 创建者串域 +28, id u16) → sub_1401DAA50 写 +1016; 失败断言 _pParent :981 + 抛 "no such parent") |
| 0x140BE2EE0 | ApplyPendingModuleReplacements: creator 国 ps+280 清单找可替换件 → SetModule 换装; 失败拼 "Failed to replace slotted ancestor module" 错误串; 调用方 = builder 域 + 生产域 (设计创建后) |
| 0x140BE0D10 | 装备→变体解析 (add_equipment_production/create_production_license 共用): CLicensedProductionStatus 查 (sub_14143A8B0/14143AA40) → 未命中建 licensed/normal (sub_140E67D10/140E67ED0) → 二次查 foreign_lease (sub_140E68A60/E68C10) |

**CEquipmentType 新字段 (定案)**: **+192 = per-地形基值 qword 数组** (+928 聚合的 type 基值侧);
**+1344 = 类别位掩码** (基原型回退, 见上表)。**CEquipmentVariantBuilder 重解** (equipmentvariantbuilder.cpp
5 函数): **+4976 = 内嵌工作 CEquipmentVariant 本体 (1208B)**, +6184 = 第二工作块 (Reset 双块同构
sub_140BD77D0) — 故 +5984/+5992/+6008 = 工作变体 +1008/+1016/+1032; +8600/+8604/+8712 旗 /
+5004 国 tag; Reset 0x141491500 (子单位 def 查败断言 :83) / 设计 spec 装配 0x1414919B0 /
重算+造价 0x141492AC0 (造价 = 0x140BD4BC0, cost≤0 取父断言 :974) / 造价包装 0x14148F460 /
NeedsTypeChange 0x1414910E0。

#### 4.23.3a 市场撮合与执行链

**核心定案: 撮合不是定时扫描** — 无批处理器; request→contract 转换由外交
action `request_equipment_purchase` 的**响应执行**逐单驱动, 另有 direct-buy
命令路径完全绕过 requests 直接成交。hourly 侧市场调用 = 空转 (HourlyUpdate
域 11 只调 thunk sub_1401C67B0 (gs+1000 解引用断言) 且返回值弃置); 全局市场
唯一周期入口 = daily 序16 **sub_140DEC850**。

| 入口 | 函数 (VA) | 语义 | 置信 |
|---|---|---|---|
| action 响应执行 | sub_141AA53F0 | CRequestEquipmentPurchaseAction::Execute (request_equipment_purchase_action.cpp:174/181 断言): 按 a1+104 响应码三路 — 0 = 建 request 入队 sub_140DEBED0 (回存 idpair @a1+336); 2 = request→contract 立即成交 sub_140DEC0B0; 其他 = 拒绝 sub_140DEC690 + 买方收 refused_market_trade 通知 | 定案 |
| request 入队 | sub_140DEBED0 | malloc(240) + 带参 ctor sub_1419D5FD0 构造 CPurchaseRequest → push 进 mkt+96 买方槽内 vector (**槽按买方 (请求发起国) tag 索引**, 三函数全用 req+92=buyer 解 idx) | 定案 |
| request→contract | sub_140DEC0B0 | "ContainsPendingRequest( PurchaseRequest )" 断言 (equipment_market_system.cpp:195, 闩 byte_14333CFA4) → sub_140DEB170 从 req+24 的 216B def 拷 draft → sub_140DEDA40 从槽内移除 → sub_140DECDD0 成交 | 定案 |
| request 拒绝/撤回 | sub_140DEC690 | 同断言 (:204, 闩 byte_14333CFA5) → 装备退还卖方 (req+88 卖方 tag → sub_1419D6A10(国池, req+96)) + 补贴退还买方 (req+92 买方 tag → sub_1413B7740(国, req+168)) → 移除 | 定案 |
| 成交主体 | sub_140DECDD0 | ExecutePurchaseDraft 八步: ①五断言 (cpp:146-151) ②malloc(808)+ctor sub_1419D4370 ③挂双回调 (lambda_1 完成 sub_1419D5370→c+624 / lambda_2 未竟 sub_1419D53B0→c+688) ④sub_1419D5850 入库 (by_seller mkt+48 / by_buyer mkt+72 / 主容器 mkt+0 三点) ⑤**买方 CProductionStatus+1192 脏旗置 1** (def+68 buyer → cc+3944 → byte+1192=1; 原「卖方」说废 — F4 验算) ⑥通知 13288 ⑦sub_140DEC380 全局信号 ⑧buyer/seller 国家侧 market 外层对象 (rp(cc+4024)) +136 成交信号槽各 sub_140DEB660 一次 (boost::signals2, §4.23.2) + 玩家方 sub_140206EA0 | 定案 |

⚠ 首参精确化 (待裁): request 拒绝 (sub_140DEC690) 与取消 (sub_140DEC540) 的退还/挂信号函数, 首参经 sub_1406CF600(sub_140BB4390(tag)) = **rp(cc+4024) 国家侧市场外层对象** (非 CCountry 本身); rp(cc+4024) 前段与 CMarketStockpile 同构 ({+32 tag / +48 通知宿主 / +56 CEquipmentVariantPool}), 退还/补贴退还/挂信号均作用于该对象。§4.23.2 既有「automation 侧外层 = rp(cc+4024), 内层 = rp(外层)」双层说与本批单层直读的差异留运行时复核 (可能为同对象不同子域的两种访问路径)。
| direct-buy 命令 | sub_1403042D0 | 草稿池构造 → sub_140DEC4F0 三谓词校验 (draft 全量 / 补贴在买方国补贴表 sub_1413B9CF0 / 池+价格档有效 sub_1413B9C90) → 过 = sub_140DEBDF0 包装成交; 不过 = 回显 "Can not make the contract." | 定案 |
| request 拒绝/撤回 | sub_140DEC690 / sub_141AA68F0 | 装备退还卖方 sub_1419D6A10(seller, req+96 def 池) + 补贴退还买方 sub_1413B7740(buyer, req+168) + 移除; 撤回 = 解析 a1+336 ref idpair 同函数 | 定案 |
| 读档 loader | sub_140DF16B0 | 逐 request malloc(240) + 无参 ctor sub_1419D6020 + 成员解析 sub_140DF13B0 → push 槽 (writer sub_140DF48B0 配对; 非撮合路径) | 定案 |

定价链: **sub_1413BA720** (market_core.cpp:307/31 断言) = IC_TO_CIC_FACTOR
(qword_1433319C8) × (variant 价格 (variant+976 或 sub_14100EB00 档覆盖回退) ×
档因子 / 100000) / 100000; 档因子映射 (sub_1419D3FD0 返值: **0 → LOW_PRICE_LEVEL_FACTOR (qword_143331BA8) / 1 → 100000 标准 / 2 → HIGH_PRICE_LEVEL_FACTOR (qword_143331CE8) / ≥3 → :31 断言 "The price level is not defined." 后落 100000**; 三证 = sub_1413BA720 switch 体 + price_levels 表行 + 0x142065F90 UI 标签序, 定案)。def 懒计算 sub_141445CD0
(IsComplete sub_1414453F0 懒触发): def+208 = 合同总 CIC 价 (Σ variant IC×档
因子×IC_TO_CIC_FACTOR); def+200 = 补贴抵扣 = min(def+136 补贴总额,
总价×F/(F+1e5)) (F = PURCHASE_CONTRACT_SUBSIDY_BONUS_SPEED_FACTOR);
IsComplete ⇔ state+8 (factory_cic_progress) == def+208 − def+200 (定案)。

F4 验算边界注 (24 点 21 一致; 定价总式/懒计算/五断言串/平滑分期记账全套证实): ① **CicCostInRange (sub_1413B9250) 语义 = i64 溢出防护非价格带** — 单条乘积与累计两段溢出检查 (负/js 分支), 恒用空池即恒走 variant+976 基价; **五断言全在 debug 门下, 非调试会话 request→contract 路径无数值校验**; ② price_levels map 未命中返缺省 1 = 标准档; ③ 钳位 sub_1419D76A0 = 两端吞噬 (<SNAP_LIMIT → 0 / >1e5−SNAP_LIMIT → 1e5, 区间内原值); ④ **第二完成谓词 sub_1419FF370**: collected (c+496) ≥ def+208−def+200 (≥ 比较), 与 IsComplete (== 比较、factory_cic_progress) 并行使用 — 合同 +608 u32 = **本轮分配工厂数** (唯一写者 = CContractPaymentConsumer::Update sub_1419FEFE0 每合同写 min(可用, c+192); PayContracts sub_1419FF1F0 不读 — 写者直证, 高置信; 旧「产能估算 speed 副本」说法废)。

护运输送三层 (定案):

| 层 | 函数 | 语义 |
|---|---|---|
| 路线层 | DoTradeRoutesUpdate (§4.21.1b) | 每日按 TRADE_ROUTE_RECALCULATE_FREQUENCY_DAYS (dword_1433363A8) 分批重算; route+8 状态机: 1=待重算 / 2=生效 (cli 消费) / 0,3=停摆 (租借 HourlyUpdate 拒跑); route+120 废弃标志 (收集时状态非 1 置 1); 收集 tuple {买方,卖方,route} 24B (MSVC tuple 内存序反) |
| client 层每日 | sub_1419D71F0 | CEquipmentConvoyClient::Update (cli = c+240): ①route+8 变化 → route==2 时 c+192 = route+108 + 按在途池 (c+368) 重算护航需求 ②sub_140CBC770 设置 (申请量 = ceil((100000−安全覆盖)×n/100000); RequestConvoys = sub_141022950, §4.16.7b) ③虚槽 [10] (vtable+80) 调用 ④c+448 += cli+72 (drh.efficiency 累加) ⑤c+456 += cli+80 (drh.sunk 累加) ⑥++c+464 (drh.days); 安全覆盖 = 槽[15] (vtable+120) GetRoute sub_140CA7700: 覆盖率 = 100000×危险海区权重/总权重 × qword_1433334D0 (trade.cpp:534/546 断言) |
| 效率平滑 | sub_1419D7500 (无 route 变化日) / sub_1419D7860 (变化日重置) | 三 lerp (f/32768): c+536 convoys → 100000×allocated (α=CONTRACT_ESTIMATE_AVERAGE_CONVOY_COUNT_ALPHA qword_143332240) / c+528 cic → 每日产能 sub_1413BA8B0 (α=…DAILY_PRODUCTION_ALPHA qword_143332330) / c+544 → cli+320 efficiency_due_to_lost (α=…SUNK_MULTIPLIER_ALPHA qword_1433325E0); 读取钳 [SNAP_LIMIT qword_143332720, 1e5−SNAP_LIMIT] (sub_1419D76A0); c+520 每日硬置 100000×allocated; 每日产能 = 买方 CProductionStatus 容量因子 sub_1415C9B40 × speed (sub_1419FF190) |

到期结算/周期重启 (合同 daily 尾段, sub_140DEC850 快照遍历 → 逐合同
sub_1419D49C0): ①cli::Update ②IsComplete? 未完 days(c+616)++ ③days ≥
PURCHASE_CONTRACT_DELIVERY_TOTAL_DAYS (dword_1433317F0) → **sub_1419D4AA0
到期结算** (CalcDeliveryAt sub_141445450 按 DeliveryDays 分期 (断言
contract_delivery_state.cpp:154/156); 装备交付买方 sub_1413B8640: _Category
bit0 → sub_1410205F0(cc+4608) convoy 池 / else sub_140E60E60 生产装备账
(market_core.cpp:504 断言); CIC 收支原子记账 sub_140CC2B40(seller,+300)/
sub_140CC2740(buyer,+304) _InterlockedAdd) ④完成 lambda_1 (容器移除+国+168
ended) / 未竟 lambda_2 (国+232 changed) → **sub_1419D53F0 周期重启** (按已转移
进度 state+16 算剩余比例池 sub_1413BA070 → sub_1419D7350 重新装船) → days=0;
尾 sub_1419D5910 延期删除架 flush (sub_1401A4F70(mkt+24)) (定案)。

租借输送 = **CLendLeaseExchange::HourlyUpdate sub_14196DC80**
(lendlease.cpp:141/146 断言直证; 驱动 = sub_140CB56B0 遍历 rs+1880 数组):
门 = eff_due_lost(+80)×efficiency(+72)/100000 ≠ 0 ∧ route+8 ∉ {0,3}; 容量 =
route 相关量 (LL+848)/24 + 比例量 (LL+856 外部预算钳); LL+888 += 容量×24×
LEND_LEASE_DELIVERY_TOTAL_DAYS (dword_143337218); 有效量 = 容量×
(eff×eff_lost/100000)/FUEL_EFFICIENCY_RAID_MULTIPLIER (unk_143331EE0);
**LL+864 += 有效量 (累计输送) / LL+880 = 本小时量 / LL+872 += 容量−有效量
(损耗累计)**; 双边关系账 sub_140D2A0E0/sub_140D2A0A0 (war_score 的
lend_lease_sent/received 键 14483/14484, §4.10) (定案)。CLendLeaseExchange
ctor sub_14196A480: CConvoyClient 基 (到 +128, tag@+24, subscriber@+32,
eff@+72, eff_lost@+80) + request@+128 + subscriber2@+136 + 宿主@+176 +
**对端 tag_id@+184 (仅存档形态为字符串)** + route 指针@+192 (= rs+1928[taker idx])
+ **九个 CEquipmentVariantPool 64B 逐池定名**: +216/+280/+344 = 来源池 (action
载荷 +136/+200/+264 拷入, sub_14196AD40) / +408 = 应发总量工作池 (运行期, 不落盘) /
+472 = 交付对账 / +536 = 本日可交付快照 (运行期, 不落盘) / +600 = 剩余未交付 /
+664 = taker 已收 / +728 = 本期累计交付 — 七池落盘 (键 12541/13327/13664/12622/
12623/12629/12624, 落盘序非键号序) + CGameDate×**4** @+792/+808/+816/+832 (原「×3」
漏记 +832) + 六标量账 @+848..+888 (原「route 指针区」订正 — route 在 +192)。 Reader = **sub_14196E160** (键→池映射 12541→+216 / 13327→+280 / 12622→+472 / 12623→+600 / 12629→+664 / 12624→+728 / 12625→+808 / 12626→+832; 键 12473/12480 = route/state 解析 → gs+724 州数钳位 + gs+712 州表反查写 LL+200/+208 — 「+192 挂回点」待裁的部分消解)。第二 ctor/reinit = **sub_14196A860** (vtable 直证): 五池清零 (+632..+776) + 双 CGameDate +792/+816 + gs+2618 门未置时按宿主 tag 解析国家并向 (cc+3944) 挂 +472 池 (sub_140E60E50)。
流向链闭合: action 响应 2 → get-or-create (双挂 rs+1880 与对端 rs+1904{+1916}, 新表)
→ 日更池路由 sub_140CDE7C0 → 护航到位回调 (槽[14] 扣船 → 槽[11] 分批交付) → 到期
整池出清 + XP/装备账/关系账/战争分; 变体旗 variant+1032 bit0 = 需护航运输旗。
池类 CEquipmentVariantPool 64B = 分组层 (archetype+1048 设计指纹为键, 24B 条目含
Σ量) + flat 层 (variant*+量) + 旗位@56; 18 原语全反编译 (SubPool 靠 sub_1424EF6F0
取负直证)。待裁: +280 日常链全无消费者 / +808/+832 两日期语义 / +200/+208 谁是谁 /
+312 计划表写入者 / 载入后 +192 挂回点 / 取消时余量返还 / +472 账目方向 (操作序列
定案、语义推定)。

cli+80 (efficiency_due_to_lost) 写者探针定案 = **sub_140CA87D0 内偏移 893 处** (CConvoyClient 域内; dr_watch 活跃合同 cli+80, 15 游戏日 64 命中 — 重算频率高于每日, 随路线/危险重算批触发; 旧「槽[10] 每日重算」推定修正为「sub_140CA87D0 条件重算」; 静态调用方 = sub_141D6D600/sub_141DBB740 (传 rs); ⚠ 合同到期释放后地址复用会串写他对象 — 长窗 watch 须重新取活跃地址); **第二写者 sub_140CAB520** (交付量重算步④: 复位 +72/+80 = 100000 后经 sub_140CA9C70 重算 — SetAmount 路径, 双写者并存)。

CConvoyClient 基类布局 (ctor 双变体: sub_140CA48C0 = tag>0 时带 subscriber init sub_141021F90(a1+32, 国, kind, priority), trade.cpp:339 / sub_140CA47E0 = 无 subscriber 区留零, :328; 公共序 = vtable 链写 → +8 CID 哨兵 → +24 tag → +72/+80 = 100000 (eff 双槽满-eff) → +88 combat idpair 空构造 → +112 spotter 哨兵 → +120/+124 清零; 派生 =
CEquipmentConvoyClient / CNavalBaseConvoyClient (§4.8.10) / CResourceOrigin /
CResourceExchange / CLendLeaseExchange / NProject::CProgramConsumer):

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +24 | tag_id | 归属国 | 定案 |
| +32 | CConvoySubscriber 内嵌 | (§4.16.7b 互证: vtable@32/allocated@40/requested@44/标签@48/宿主国@56/桶@64) | 定案 |
| +72 | fixed×1e-5 | efficiency (ctor 100000) | 定案 |
| +80 | fixed×1e-5 | efficiency_due_to_lost_convoys (ctor 100000) | 定案 |
| +88 | 匿名结构 (NNB 形状) 向量 24B | 未名 vector | 推定 |
| +112 | idpair 哨兵 | = qword_14333D528 | 定案 |
| +120 | uint32 | 期望护航量 (sub_140CBC770 写) | 定案 |

CPurchaseDraft (与 contract def 同构, 偏移 = def−64): seller@+0 / buyer@+4 /
equipments 池@+8 (= def+72) / subsidies 容器@+72 (= def+144) / speed@+104
(= def+168); CRequestEquipmentPurchaseAction: +104 响应码 (0=send/2=accept/
其他=refuse) / +336 _MarketPurchaseRequestRef idpair (定案)。
CResourceDeliveryRoute (vtable 0x14295C320): +8 状态字节 (=2 活跃态) / +48 第二端
tag (路线两端 tag 对之一, 港口 BFS 配套谓词 sub_140CAA8C0 双端放行; 推定 seller) /
+52 买方 tag (落盘键 tag) / +56 receiver tag (运行期写点, 交付重算 sub_140CA9EF0 写
exchange+136) / +96 海区数组 (元 8B = 战略海区指针; 元素 +224 = 海区权重 fx1e-5 /
+232 = 覆盖谓词键对象, 安全覆盖率 sub_140CA7700 消费) / +108 海区计数 / +120 日期槽
(建/改贸易 sub_140CB5D60 写 \*(gs+1128) 当前日期 hours; 语义待裁 (writer/reader 侧复核), 现按日期写点记录)。

#### 4.23.3b resources.daily 执行链

**resources.daily = sub_140CABB30** (trade.cpp; 挂 CCountry::DailyUpdate 串行段
`*(cc+4600)` CCountryResources, 定案): export/extra/lend-lease/exchange 四族
权利对象虚槽 vtable[+80] 日更 → 结算尾 = 每资源累积表清零 + **逐资源贸易履行结算
sub_140CA6EB0** (权重/可交付量/政治 274+外交 376 修正/库存上限/比例分配; 其被调
**交付量重算 sub_140CA9EF0** = "NEGATIVE RESOURCE EXCHANGE" trade.cpp:4302 断言真宿主 —
交付量公式 = `delivered = clamp(量,0) ×
eff(+72) × eff_lost(+80) / 1e10` 全整型定点) + 租借交换逆序到期收尾。
第二站点 sub_140CB5D60 = 命令驱动的取消后再结算 (非调度链)。rs 侧字段勘正:
rs+1784 = origin / rs+1808 = export 扁平表 / rs+1832 = 按资源桶数组 (writer
循环基地址留运行期对拍裁定, 链级结论不受影响)。

**反垄断贸易因子** (计算步 sub_1406EBBD0, 挂 CCountry::DailyUpdate 链; 公式定案):
份额均值 = 1e5×Σ(本国量/全市场量)/资源数 (量 0 → 哨兵跳过); 判别: 份额均值 >
ANTI_MONOPOLY_TRADE_FACTOR_THRESHOLD (全局 0x3334F98) → 因子 =
ANTI_MONOPOLY_TRADE_FACTOR (全局 0x3335038), 否则 0; mdef274/mdef376 双向修正。

#### 4.23.9b CEquipmentDatabase 全布局 (equipment_database.cpp 装载链)

**CEquipmentDatabase** (488B; vtable 0x142937FC0, 基 TGameItemDatabase; ctor 0x1409EF930; vtable[7]/[8] = Save wrapper/CFG 空桩 — **库不落盘**; §4.23.7a 「modules 库单例」实为本整库, modules 仅 +224 子容器):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +32 | uint8 | 静默覆盖旗 (读者已定位 = 分发器重名覆盖分支**告警门**: ≤0 告警 :379 / >0 静默, 只门告警不门覆盖; 写者仍未定位) |
| +40 | 名→下标链哈希 | 64B 节点 (桶数组@+64, 桶掩码@+88, 计数@+56, 16B 桶 {head, tail}; 节点+56 = type 下标) |
| +104 | 主 type 指针数组 | vector 形 {data@+104, cap@+112, count@+116, 分配器@+120 (vtable+8 alloc/vtable+16 free)}, 增长 1.5x — db+296 依赖序数组的数据源 (快照 = 该数组整块 memcpy) |
| +128 | archetype 数组 | 原型槽表 {data@+128, count@+140} (重名覆盖时腾空写 0x1409F8570 Null 原型单例) |
| +152 | lookup 40B 线性表 | 升级 |
| +200 | lookup 40B 线性表 | 模块 |
| +224 | 匿名结构 (NNB 形状) 向量 | §4.23.7a 所指 |
| +272 | archetype 子类型区间 | duplicate 克隆范围 — 16B/条 {begin, end} 指针对, 计数@+284, 按原型 +1336 下标索引 |
| +296 | 依赖序快照数组 | {data@296, cap@304, count@308, alloc@312}; 生产点 = sub_1409F6DA0 尾 (db+104 数组整块 memcpy 后排序); 排序后 (stable_sort 八件展开: 非 duplicate 在前 + type+1248 父链浅者在前 + 64 步环断言 "Cyclic equipment hierarchy" :1042) |
| +320 | 模块类别注册表 | slot 允许类别 = 脚本 ∪ 模块声明 ∩ 实用类别 (0x1409F4940 两阶段回注: 模块侧收集校验 → type 侧逐槽脚本声明 ∪ 注册表 ∩ 模块类别, 经 sub_140C935D0 回注; 48B/条, id@+40, 计数 db+332; 报错 :706/:767) |
| +408 | 载具编成权重表 | duplicate_archetype 应用写入 — 16B/条 {CEquipmentType* @0, weight i64@8} + {cap@416, count@420, alloc@424}; 值源 = def+40 pdxoptional (isSet@+48); 同型指针已存在覆盖权重, 否则 append |
| +432 | limit 触发器向量 | (见 +688 行); 写者定位 = 分发器 equipment_modules 块级 limit(10762): CAndTrigger(88B) shared_ptr → sub_1401AFF20 推入 |
| +456 | search_filters 注册表 | 平铺分簇哈希 {桶数组@+8, 计数@+16, 掩码@+20, 深度上限@+24, 载荷因子@+28}; 节点 56B = 16B 哈希头 {链字节@+4, key@+8} + 内嵌 CEquipmentFilter 40B 本体 @+16 (书 40B 布局为对象本体相对, 成立) |

装载链 (0x1409F1FC0 per-file 分发器): 五顶层块 equipments(12122)/upgrades(12393)/equipment_modules(15210)/search_filters(19320)/duplicate_archetypes(19503) 逐条建 def、查重覆盖 ("Overriding old")、注册; 重名覆盖处理器 sub_1409F6990 (逐别名 token → 名哈希 → db+40 哈希开链摘除、腾空 archetype 槽 db+128、0x140C93F80 原位 reset; **a3 出参 = {腾出槽下标 u32, 有效旗 u8}** 由 sub_1409F9D80 消费实现腾槽复用); equipments 新建 = malloc(1480)+ctor → push db+104 → 哈希节点 → vtable[3] Load → sub_1409F9D80 → archetype 且 interface category == 357(none) 警告; 尾部三连加载日志 :564/:570/:576 + gameitemdatabasehelper.h Null Object 断言族 (Array == Lookup+1)。**Load (0x1409F9F00) 尾钩**: db+32 > 0 → vtable[2](db) 装载完成通知 (推定; 注意与 PostLoad 同槽复用 = 装载期/后置两语义, 待裁)。db PostLoad (vtable 槽[2] 0x1409F7DF0) = 逐 type 0x140C949D0 + convoy 唯一性 (:597/:605; 检查 = 类别位掩码聚合 getter sub_140C95730 的 **bit0 = convoy 旗**, type+1365 区分 archetype/type 两类) + 逐模块 0x14152E8C0 (模块数组 {data@+224, count@+236}) + +320 回注 0x1409F4940 + **尾部另有 sub_1409F45B0 / sub_1409F5780 两步 (语义未决)**。**CEquipmentType 增补** (sizeof **1480B**; ctor 0x140C924B0 双点复现): +1048 db 下标 / **+112 槽数组 80B/条 {+8 槽 token, +24 脚本类别向量, +36 计数}, +124 槽计数** / +992 interface category token (取值链 sub_140C95830: !=357 或自身 archetype 或无基原型则返回, 否则沿 +1240 递归) / **+1344/+1352 类别位掩码低/高半字** / +1248 派生母指针 (self 哨兵; **+1240 初值 = 0x1409F8570 Null 原型单例**) / +1280 别名向量 / +1312 内嵌开地址表 / +1336 archetype 下标 / **+1360 u32 主类别序号** (ctor 清 0; PostLoad 0x140C949D0 未设时 = sub_140659D70(首类目位) 位→序号转换; getter sub_140C956E0 沿 +1240 走根原型读; 位→序号全表: 0→0 / 0x4→1 / 0x8→2 / 0x10→3 / 0x20→4 / 0x40→5 / 0x80→6 / 0x100→7 / 0x1→8 / 0x400→11 / 0x4000→12 / 0x800→13 / 0x1000→14 / 0x2000→15 / 0x8000→16 / 0x200000→17 / 0x100000→18 / 0x400000→19 / 0x20000→22 / 0x40000→23 / 0x8000000→24 / 0x10000000→25 / 0x20000000→26 / 0x40000000→27 / 0x2000000→28 / 0x80000000→32 / 0x200→33 / 0x80000→34 / 0x100000000→40 / default→0) / **+1365 IsArchetype 旗** / +1366 IsDuplicate / **+964 i32 与 +976 u32** (getter sub_140C96180; 生产装备窗五键排序第 3/4 键消费, 业务语义未决)。**bonus 枚举双向校验报错桩** = sub_1409FB5B0 (:649 枚举有而类型/类别无) / sub_1409FB650 (:656 反向), 触发站未决 (语料零调用点)。

#### 4.23.10 equipmentdesignerview.cpp 簇对账增补 (CEquipmentDesignerView; 13 函数闭环)

视图类实名 **CEquipmentDesignerView** (调用方 lambda MSVC 符号直证), 同符号带出六实名:
EDesignerType (enum, view+14224 u32 存) / EUpdateMask / CInGameIdler /
CInGameInterfaceHandler / CInGameUpdateableInterface / NIndustrialOrganisation::
COrganisation (设计团队经 lambda 传入)。三型同类 (tank/plane/country 共用一类, §4.23.1
GUI 消费表 handler+600/608/616 三实例互证)。**EDesignerType → 窗名映射** (sub_14177FAA0
整读定案): 0 = countryequipmentdesignerview / 1 = tank_designer_view / 2 =
plane_designer_view; **海军设计无独立窗** (ship_designer_model_preview 等元素与 tank/plane
预览同在 Create 挂接, 走 country 窗)。

簇成员全清册 (13 函定案): Create 总装配 sub_141788E70 (2497 行; 窗创建 + 84 个窗元素名全录
+ 子元素句柄缓存 view+58216 起 + observer glue 绑定 ×10 [sub_14172D090, glue 槽 view+62272
步进 8]; 断言 "Window already created" = 幂等门) / 升级·差异列表重建 sub_141786710 (1021;
original parent 对比驱动, 10 型小对象 80B/56B 逐项插列表; 父变体 +32 计数 > 0 → 直发
order_invalid_effect) / 3D 模型选择器 populate sub_141791F50 (551; 默认项 {排序键 −100000,
"USE_DEFAULT_MODEL", GFX_default}; 变体查 SubUnitDefinition 失败断言 :4154) / 历史设计应用
sub_141784A80 (489; historical_design_button 链; a2 = 历史设计行条目 +440 名/+576 图标,
非 CEquipmentVariant; 失败断言 "Auto design failed…" :3115) / parent 逐字段比对置脏 ×2
(sub_14178DC00 / sub_141791920 镜像组) / 当前设计 sub-unit 查找+图标刷新 sub_1417929E0
(:3620) / 角色切换回调 sub_14177BD10 / 模块装卸回调 sub_141775290 / 模块等级步进
sub_141793B30 (拒 → manager vtable+160 查最大允许等级 clamp 重试) / role_icon 回退重导出
sub_141790050 / 编辑模式开关 sub_1417846D0 (`*(WORD*)(view+31849) = 1` 双旗齐写 =
状态机 1 态原子置位) / 编辑母本跳转 sub_1417864B0。

**CEquipmentVariantBuilder 方法族** (断言串 "VariantBuilder refused…" 旁证实名; 实例 =
view 内嵌 +14192 / +14232 / +23032): GetOriginalParent sub_141490A10 / HasOriginalParent
sub_141490F10 / 应用历史设计 sub_1414900E0 / 设角色 sub_141491E10 / 装模块 sub_1414921F0 /
卸模块 sub_14148F6D0 / 设模块等级 sub_1414926E0 / SetTarget sub_141788C50 (双 builder,
书 +1016 行互证) / 载出 sub_1414919B0。全部出口走 builder 方法族 + 按名字符串触发钩,
无 CCommand 族直接构造。

**按名触发统一通道** (定案): manager 侧 vtable+248 = 按名触发 (effect 名与 sfx 名
`sfx_ui_sd_module_default` 同接口 — 一接口两资源型; 其余槽 vtable+96 窗查找/vtable+136 取容器/
vtable+160 取对象计数); 元素侧 vtable+688(名, 参数数组, 0) = 按名效果钩。效果名全录:
EQUIPMENT_DESIGNER_SAVE (带 {XPICON, 2, XP值} / {XPCOST, 9, XP成本} 双参数, XP 值 =
sub_140F8A450(view+20240), 保存门 XP < 10000) / DIVISION_DESIGNER_RENAME /
EQUIPMENT_DESIGNER_UPDATE_COSMETIC (书 +85 行互证) / order_invalid_effect。

**镜像组 ×2 布局** (定案, 设计对比/升级脏查数据基座): 双 builder 各持一套 parent 字段镜像
— view+31872/+31912 division_names_group (↔parent+1152) / +31880/+31920 与
+70600/+70640 override_model (↔+1072) / +31928/+31968 role_icon_index (↔+1068) /
+31933/+31973 auto_upgraded (↔+1061) / +31934/+31974 show_position (↔+36) — 与书
CEquipmentVariant 布局字段级互证。view+20240 = 类别位掩码镜像 (_Category 类); 三组掩码
0x1F0037FC00 (= 书 +1032 EQUIPMENT_AIR 族互证) / 0x408000003C / 0x80004003C1 (陆/海推定,
待裁)。状态分类器 sub_14177E000 (同单元非簇): 3 = 无母本可比 / 1 = 编辑模式 (+31849) /
2 = 同日期母本对照 / 0 默认。

未决: view+20216 深链 +1256→+1240→+8 中间两跳实名; sub_14177E000 状态 2 的
sub_140BB52F0 可比性语义; 10 型列表项逐型实名; EDesignerType 非法值 Create 行为;
两组类别位段命名。断言闩 byte_14338B085-094 地址连续 = 编译单元顺序布局 (与空军剧场批
同型规律)。


**AutoDesign sub_14177D290** (equipmentdesignerview.cpp:2511; §4.23.10 十三函数闭环外第 14 函, 定案): vt[5]（a1+14216→+1288 子对象）取设计框架序号 → sub_14148F310 在 8800B 栈缓冲建设计上下文 → sub_14062E820(AI 管理, view+14232, ctx, 序号, 0) 找设计 → sub_14148F830/sub_14062D0C0 转换回填 → sub_14148FBA0(ctx, 设计, 序号) 应用 → sub_141491000(ctx, view+19208) **IsValid 校验**；命中后若 **!a2**（a2 = 仅校验不应用门）再 sub_14148FBA0(view+14232, 设计, 序号) 应用到 builder，失败 → 断言闩告警 :2511 "Auto design failed after finding a presumably acceptable AI design."；`*(dword*)(view+31968) = *(dword*)(设计+576)` = role_icon 镜像写回（与 §4.23.10 历史设计行条目 +576 图标位同位）；返回 1 = 找到并过校验。

**设计应用器 sub_14148FBA0 函数体布局** (builder = ctx 栈对象或 view+14232; 定案): v5 = builder+4976 设计数据子对象; v6 = sub_140BB4390(builder+5004) → v55 = v6+3944 上下文 / v56 = sub_1406CF0E0(v6)+3024+560。链序 = ① 槽映射同步 (builder+8608 ≠ v5+184 时以 v5+196 计数 / v5+184 源 sub_1401A89E0 开空间 + memcpy 16B/条, 计数镜像 builder+8620) → ② 逐模块 (v5+1008 数组 +112 步距 80, 计数 +124): 现值 sub_140BDA480 / 新值 sub_14148A360, 不同则 16B 键控有序向量 (key i32@+8, value qword@+8) 二分插入/覆写/删除并同步计数 → ③ 统计容器 sub_140BD1D30(builder+8632, …) → ④ 逐槽钳位 (v5+1008+88, 计数 +100): sub_14148A960 返 2 word (低字节值 / 高字节 isSet, pdxoptional.h:173 `_bIsSet` 断言), set → sub_140BDC3F0 写入, 上界 sub_141537940(v40, v5+28, 0), **min(值, 上界)** 不等 → sub_140F8F730 统计 + 置变化旗, 处理完写哨兵 170 (0xAA) → ⑤ 上下文写回 `*(builder+6044) = *(设计+576)` (role_icon 镜像族) → ⑥ 类别/框架门: v47 = sub_140C95730(设计+568) (类别位掩码聚合 getter) == v5+1032 直接过, 否则 sub_140BDE030 + 位掩码包含门 (v49 == (v49 & sub_140BD9140(v5))), 失败返 0 → ⑦ 合法性: sub_141492AC0 真 ∧ `*(设计+728) != 357` (357 = interface category token "none") → v4 = sub_140E5D090(v55) → sub_141B93670(v56, builder, v4); 终局门 `*(builder) ∧ *(builder+5992) ∧ sub_140BDDF60(v5)` → 读旗 builder+6008: `(旗 & 0x408000003C) == 0` 须 `*(builder+2320) >= qword_143336D40`, `(旗 & 0x1F0037FC00) == 0` 须 sub_140BDD7F0(v5, 0) (= §4.23:432 ValidateAirWeightThrust) → 返 sub_140BDCAD0(v5, 0) != 0。+6008 两旗位掩码与 +2320 阈值语义未决。

#### 4.23.14 requests 块装载校验器 (parse 侧)

requests 装载校验 = sub_140307930 (错误文案四条: "Target equipment archetype is not provided." / "CIC amount is not provided." / "Valid seller_tags or a valid seller_trigger should be provided." / "Should either provided seller_tags or seller_trigger and not both." — archetype/CIC 必填, seller_tags 与 seller_trigger 互斥)。

#### 4.23.15 EEquipmentCategory 类别域 (equipment_category.cpp; 8 函闭环 — 位语义总表 / 组合键 / 角色键 / 谓词 / 三表对账)

类别位语义总表 (sub_140F88620 loc 键表 × sub_140F8A750 token 表逐位对名, token 名经 ref token 基准全对上; 缺 bit 1, bit 23 无 token):

| bit | 掩码 | token | token 名 | EQUIPMENT_* loc 键 |
|---|---|---|---|---|
| 0 | 0x1 | 11923 | convoy | EQUIPMENT_CONVOY |
| 1 | 0x2 | — | — (两表皆缺 → unknown) | — |
| 2 | 0x4 | 12165 | armor | EQUIPMENT_ARMOR |
| 3 | 0x8 | 12170 | motorized | EQUIPMENT_MOTORIZED |
| 4 | 0x10 | 12169 | mechanized | EQUIPMENT_MECHANIZED |
| 5 | 0x20 | 10113 | infantry | EQUIPMENT_INFANTRY |
| 6 | 0x40 | 12172 | capital_ship | EQUIPMENT_CAPITAL_SHIP |
| 7 | 0x80 | 12173 | submarine | EQUIPMENT_SUBMARINE |
| 8 | 0x100 | 12314 | screen_ship | EQUIPMENT_SCREEN |
| 9 | 0x200 | 19713 | floating_harbor | EQUIPMENT_FLOATING_HARBOR |
| 10 | 0x400 | 12223 | fighter | EQUIPMENT_SMALL_FIGHTER |
| 11 | 0x800 | 12226 | interceptor | EQUIPMENT_INTERCEPTOR |
| 12 | 0x1000 | 12228 | tactical_bomber | EQUIPMENT_TACTICAL_BOMBER |
| 13 | 0x2000 | 12229 | strategic_bomber | EQUIPMENT_STRATEGIC_BOMBER |
| 14 | 0x4000 | 12224 | cas | EQUIPMENT_CAS |
| 15 | 0x8000 | 12225 | naval_bomber | EQUIPMENT_NAVAL_BOMBER |
| 16 | 0x10000 | 13299 | missile | EQUIPMENT_MISSILE |
| 17 | 0x20000 | 14329 | suicide | EQUIPMENT_SUICIDE |
| 18 | 0x40000 | 19417 | scout_plane | EQUIPMENT_SCOUT_PLANE |
| 19 | 0x80000 | 19732 | railway_gun | EQUIPMENT_RAILWAY_GUN |
| 20 | 0x100000 | 13065 | air_transport | EQUIPMENT_AIR_TRANSPORT |
| 21 | 0x200000 | 12192 | maritime_patrol_plane | EQUIPMENT_MARITIME_PATROL_PLANE |
| 22 | 0x400000 | 12175 | carrier | EQUIPMENT_CARRIER |
| 23 | 0x800000 | (→ token 0) | — (parachute: 有 loc 键无 token) | EQUIPMENT_PARACHUTE |
| 24 | 0x1000000 | 12188 | support | EQUIPMENT_SUPPORT |
| 25 | 0x2000000 | 10312 | flame | EQUIPMENT_FLAME |
| 26 | 0x4000000 | 11945 | amphibious | EQUIPMENT_AMPHIBIOUS |
| 27 | 0x8000000 | 12166 | anti_air | EQUIPMENT_ANTI_AIR |
| 28 | 0x10000000 | 10114 | artillery | EQUIPMENT_ARTILLERY |
| 29 | 0x20000000 | 12167 | anti_tank | EQUIPMENT_ANTI_TANK |
| 30 | 0x40000000 | 12168 | rocket | EQUIPMENT_ROCKET |
| 31 | 0x80000000 | 19704 | train | EQUIPMENT_TRAIN |
| 32 | 0x100000000 | 12954 | heavy_fighter | EQUIPMENT_HEAVY_FIGHTER |
| 33 | 0x200000000 | 10087 | emplacement_gun_ammo | EQUIPMENT_EMPLACEMENT_GUN_AMMO |
| 34 | 0x400000000 | 10093 | ballistic_missile | EQUIPMENT_BALLISTIC_MISSILE |
| 35 | 0x800000000 | 10094 | nuclear_missile | EQUIPMENT_NUCLEAR_MISSILE |
| 36 | 0x1000000000 | 10099 | sam_missile | EQUIPMENT_SAM_MISSILE |
| 37 | 0x2000000000 | 10507 | missile_launcher | EQUIPMENT_MISSILE_LAUNCHER |
| 38 | 0x4000000000 | 10077 | land_cruiser | EQUIPMENT_LAND_CRUISER |
| 39 | 0x8000000000 | 10231 | support_ship | EQUIPMENT_SUPPORT_SHIP |

组合键 (loc 键表独有; token 表对复合掩码一律返 0 — §4.15 勘误行同源):

| 掩码 | loc 键 | 成员 |
|---|---|---|
| 0x201 | EQUIPMENT_NON_TASKFORCE_NAVAL | convoy + floating_harbor |
| 0x20B000 | EQUIPMENT_BOMBER | tactical + strategic + naval_bomber + maritime_patrol |
| 0x1D00000 | EQUIPMENT_SPECIAL | support + amphibious + anti_air + artillery |
| 0x7E000000 | EQUIPMENT_WEAPONS | flame + amphibious + anti_air + artillery + anti_tank + rocket |
| 0x100000400 | EQUIPMENT_FIGHTER | small_fighter + heavy_fighter |
| 0x10036FC00 | EQUIPMENT_PLANE | 空军位去掉 missile/suicide/高位 |
| 0x1C00010000 | EQUIPMENT_MISSILE_CATEGORY | missile + ballistic + nuclear + sam |
| 0x408000003C | EQUIPMENT_LAND | armor/motorized/mechanized/infantry + train + land_cruiser |
| 0x1F0037FC00 | EQUIPMENT_AIR | 空军族全位 (§4.23.1 互证) |
| 0x80004003C1 | EQUIPMENT_NAVAL | convoy + capital + submarine + screen + floating_harbor + emplacement_gun_ammo + support_ship |

三族族掩码 = 0x408000003C (陆) / 0x80004003C1 (海) / 0x1F0037FC00 (空), 与 §4.23.7 CPotentialDesignCollection +48 category 掩码三方一致。

其余六函一行定性:

| 函数 | 锚 | 定性 |
|---|---|---|
| sub_140F8A750 | :52 断言 "std::bitset<32>(Category).count() <= 1 … only returning the token of the first matching one" | 单一位→token 全表; popcount 门 = CPUID 检查 (dword_1430C76A8 ≥ 2 → __popcnt, 否则 SWAR); 复合掩码与 bit 23 → token 0, 0/未列位 → 19530 unknown; 一次性闩 byte_14333D658 |
| sub_140F89890 | :172 断言 "Unhandled equipment category in role key lookup" | 设计器角色键: 纯 armor (0x4) → `"tank_designer_" + token_name(a3)` (**动态后缀, a3 = 附加 token 实参, 仅此分支消费**); armor+车体位 0x2000004..0x40000004 (bit 25..30 六种) → tank_designer_{flame/amphibious/anti_air/artillery/anti_tank/rocket}; 固定机角色 10 种 0x400..0x200000 与 0x100000000 → plane_designer_*; 其余断言 (闩 byte_14333D65B) → "unknown"。调用方 = 设计器视图族 (sub_141780480 / sub_140F89EC0 / sub_14177B420) |
| sub_140F8A450 | :312/:329 断言 "Cannot determine the appropriate experience type icon…" | 经验图标名: a1==0 → 断言 → "army_experience"; 陆掩码非零直接 army; 否则按海 0x80004003C1 → navy_experience / 空 0x1F0037FC00 → air_experience; 都空断言 → army_experience。闩 byte_14333D65C/D |
| sub_140F8A270 | :97 断言 "( Token == _naval_ ‖ Token == _plane_ ‖ Token == _armor_ ) && \"Unknown equipment directory\"" | 目录 loc 键: token naval=11925 / plane=13380 / armor=12165 → 串接 `NAVAL/PLANE/ARMOR` + `_DIRECTORY` 本地化发射; 未命中 → 空串。闩 byte_14333D659 |
| sub_140F88180 | :388 断言 "Equipment.IsValid() && equipment key is neither an equipment category or equipment type/archetype" | 名称列表×类别谓词: a1 = std::string 向量迭代对 {data, count@+12} 40B/元, a2 = 类别掩码; 逐名 token 化 (sub_14022F060, 19479 = undefined 兜底) → 名查 db 312B 条目类别注册表 → 查无则按名取类型/原型 (sub_1409F86F0(qword_14332EEC0, …), qword_14332EEC0 = CEquipmentDatabase 单例槽 (§4.34.30)) → 原型→掩码 (sub_140C95730); 任一 (掩码 & a2) != 0 → 1 |
| sub_140F8B170 / sub_140F8B230 | :357 / :364 错误日志 "… (cf. EQUIPMENT_CATEGORY_META in code)" (CLogStream 一行式无中断) | 装载期双向对账: 脚本枚举 script_enum_equipment_category ↔ 代码 EQUIPMENT_CATEGORY_META 表, 任一侧独有成员即报 — **类别全集有第三份镜像 (脚本枚举), 三表一致性由装载期对账保证** |

未决: 纯 armor 分支动态后缀 a3 取值域 / dword_143086B08 (EndOfTime, §4.00.11) PE 数值 / 谓词 sub_140F88180 的消费场景。

#### 4.23.16 装备市场原语层 (market_core.cpp 9 函 + description_utils 1 函; 补贴计划状态机 / IsTradable 谓词簇 / 定价互证)

簇清册 (体内 cpp 锚 15/15; 断言 16 处 = 15 B52 + 1 B51; latch 连续区 byte_14338A2B5..A2BD):

| 函数 | 行数 | 锚行 | 定性 | 状态 |
|---|---|---|---|---|
| sub_1413B8D70 | 218 | :105 | 补贴移除计划构建器 (56B 计划记录) | 新 |
| sub_1413B9670 | 149 | :173 | 活体补贴向量按 CIC 抽取 (48B 条, 尾向前消费) | 新 |
| sub_1413B87F0 | 146 | :41 | 市场列表 72B 记录构造 | 新 |
| sub_1413BA720 | 75 | :307/:31 | 变体定价链 | 已收 §4.23.3a, 本批逐项互证全等 |
| sub_1413B9970 | 68 | :280 | 合同 CIC 分期交付量 = delivered_at(next) − delivered_at(last) | 新 |
| sub_1413B9590 | 58 | :291 | prices 池拷贝构造 (入池量 = 变体基价非源条量) | 新 |
| sub_1413B8640 | 38 | :504 | 装备交付买方·池批量版 | 已收 §4.23.3a, 互证 |
| sub_1413BB2E0 / sub_1413B8730 | 28+28 | :519/:504 | 国家装备出账/入账单变体对偶 | 新 |
| sub_1413BE5D0 | 653 | :397 (**B51 族实证落点**) | 购买合同补贴总览 tooltip 生成 (双列输出) | 新 |

**入账/出账对偶** (8730/BB2E0; (cc, variant, amount)): 派发门 = variant+1032 bit0 — 1 → 护航池 (cc+4608, sub_1410205F0 / 出账 sub_141022590 无 variant 形参); 0 → 生产装备账 (rp(cc+3944), sub_140E60E60 / sub_140E6EBC0)。8640 池批量版 = 遍历池2 16B 条逐条同派发。**市场库存转移执行器 sub_1419D6A60** (market_stockpile.cpp:54/55 断言, latch byte_14338B4B0..B2; 签名 = (CMarketStockpile\* a1, CEquipmentVariantPool\* a2 = to_reserve, CEquipmentVariantPool\* a3 = to_release)) = release 路径 (遍历 a3 池2 16B 条; 100000 粒度取整 (负值截 0); **上限 = min(请求量, 市场池现货 sub_14100EB00(a1+56, out, variant))** → 8730 入国家 + sub_141012850 出市场池) / reserve 路径 (遍历 a2 池2; :21 逐条断言 sub_1413BB220(variant, tag, 100000 余数) 三参形态; **上限 = min(请求量, 国家持有量 sub_1413BAB80)** → BB2E0 出国家 + sub_14100CCE0 入市场池; 两路均 sub_141375840(*(a1+48)) 通知) → 尾 sub_1419D63D0(a1, &sub_1406CEA90, a1+32) 统一通知; a1 = CMarketStockpile {+32 tag, +48 通知宿主, +56 CEquipmentVariantPool (池2 data@+88/count@+100, §4.23.2 内层互证)}。⚠ sub_14100EB00 同原语在定价链 sub_1413BA720 中作「档覆盖回退价」读取 — 两处同为「池条目量按 archetype 查」, 语义随宿主池变 (现货池 = 库存量 / 价格池 = 覆盖价), 勿按名直推。⚠ 与 §4.23.3a 装备退还卖方 sub_1419D6A10 相邻非同函, 与 0x141B1BF30 (13859 Execute) 的层级待裁 (候选: 141B1BF30 构造规格 → 1419D6A60 执行)。

**补贴计划状态机 (新定案)**: 构建器 sub_1413B8D70 (def+144 补贴向量 48B 条源) 产 56B 计划记录 {cap i64@+0 = min(条目, F × a4 / 100), 余量 i64@+8, 串@+16..+40, 状态 u32@+48}; a5==0 时二次分配: 余量≤0 → 状态 0 / 总余≤0 → 状态 2 / 否则逐条 take 结转 (100000 粒度余数) → 状态 1 — **状态 0/1/2 = DEPLETED/ACTIVE/PENDING** (sub_1413BE5D0 的 UI 键名 PURCHASE_CONTRACT_SUBSIDIES_{DEPLETED,ACTIVE,PENDING}_EXCHANGE 映射直证, 其他值 → :397 断言)。**F = qword_1433318C8 = PURCHASE_CONTRACT_SUBSIDY_BONUS_SPEED_FACTOR** (define 注册点直证; 负值钳 0), 贯穿补贴抵扣 (§4.23.3a)/移除计划/进度折算三函。折算 sub_1413B9E80 = min(def+200, F × 进度/1e5); 分期交付 sub_1413B9970 调用方 = 书已收 CalcDeliveryAt (sub_141445450)。**除法魔数实例: F × a4 / 100 = imul 0x29F16B11C6D1E109 >> 78** (64 位常量乘压 32 位字面量; **PE 验算 = ÷100000 精确 (2^78/magic = 100000.0), 非 ÷100** — 字面式 /100 系伪码量纲残影, 实际语义 = fixed×1e-5 归一; 高置信)。

**合同交付估计域 (新定案; 簇名甄别: "livery_estimates.cpp" 与 "ntract_delivery_state.h/.cpp" 均系 IDA 路径串断行断片 (.cpp 断点恰在 co|ntract 拼接处; contract_delivery_state.cpp 五函数体直证无独立 ntract TU) — 真名 = international_market/contract/delivery_estimates.cpp 与 contract_delivery_state.h, 与海军涂装无关)**: **交付完成估计模拟器 0x141BCE060** (773 行) — SParams 七字段断言画像 (:225-233): {+0 _pState* (非空 IsValid) / +8 _DaysSinceLastDelivery (≥0) / +16 _AvarageEfficiencySinceLastDelivery (i64 fixed ∈[0,1], 引擎拼写 Avarage) / +24 _EstimatedDailyCicProduction (≥0) / +32 _EstimatedAvarageConvoyCount (≥0) / +40 u8 简化旗 (日产取 100000×int(估计)) / +56 _LastDelivery CGameDate (IsDate)}。主流程: state 不可交付 (sub_1414453F0) → 默认结果 (CGameDate 哨兵 43808760); 交付路由 = state+64 → 国家 → cc+4600 → **rs+1928 delivery_routes 按买方 idx** → route+8 ∈ {0,3} 空结果 / ==2 (活跃) 才续; 运力产量折算 = sub_1419D4880 + sub_1413B9950(**route+108 作运力输入** — s4_03 该槽「贸易窗快照」推定的旁证); 日产上限 = min(合同池量, 估计日产 × TOTAL_DAYS); **逐期模拟循环** = 每日交付量 min(池,日产) × 运力比 (<<15 定点, >1 钳 1) + 天数 ceil (余数进位) + sub_141444630 推进一期; **预计交付日 = _LastDelivery + 24 × NMarket.PURCHASE_CONTRACT_DELIVERY_TOTAL_DAYS (dword_1433317F0, defines_game.h:261; 24×D = 天→小时)**。**到第 D 天投影器 0x141BCF7B0** (:385): TOTAL_DAYS 两段加权 (剩余天数权 (D_total−days)<<15), 全 <<15 定点, 尾调书已收 CalcDeliveryAt sub_141445450。SDeliveryEstimate 形状推定 ≥112B ({旗包@0, i64@4, u32@12, u8@16, 容器@24..87, CGameDate@88/@104}); 调用方 = 国际市场 UI 估计窗族 (sub_141BCF110/141BCF310)。中期抽取链 = sub_1419D5080 (purchase_contract.cpp:177 "Should be called only in middle of contract.") → 9670 抽取 → sub_1413B7740 退还买方。

**定价链互证** (sub_1413BA720, §4.23.3a 全等): 基价 variant+976 或覆盖价; 价级查 sub_1419D3FD0 0→LOW 常量 / 1→100000 / 2→HIGH 常量 / ≥3 断言落 100000; 总式 = IC_TO_CIC_FACTOR × (价×档/1e5)/1e5。

**市场列表 72B 记录** (sub_1413B87F0): {+0 variant, +8 cc, +16/+24 原样, +32 可用量, +40 价, +48 价级枚举 u32, +56 原型 category token, +64 净差 (两计数器差, 产/耗差推定)}; 断言 :41 = 非 IsTradable 即断。三个列表构建器 (sub_1413BAC30/BA910/BA360) 为调用方, 均带 bit31 扣预留分支。**NMarketCore::IsTradable 谓词簇本体首次反编译**: sub_1413BB220 = `!sub_140BDE100(variant) && (!sub_140C97B90(原型) || variant+1032 bit0)` (⚠ 断言串两参形态 vs 反编译体仅消费 a1, tag 真伪待汇编核); sub_1413BB260 = 池版逐条谓词。价级 map 写侧 sub_1419D40F0 在 sub_1413BCAC0 (成本串构建) 再证 (读 sub_1419D3FD0/写 sub_1419D40F0 双证补强)。

未决: 记录 +64 净差语义 / 国家侧价级覆盖表挂点 (sub_1406CDBA0(cc+4024)+16 推定) / F×a4/100 量纲 PE 验算 / 中期抽取触发时机 / BB220 形参真伪。

#### 4.23.16a 补贴过滤器与合同交付状态六函 (subsidies_filter.cpp + contract_delivery_state.cpp; 8 函闭环)

**买方视图补贴过滤器** (interfaces/international_market/buyer_view/subsidies_filter.cpp, 断言直证簇名真名): 过滤器对象 {_pArchetype@+0, _Countries = CPdxArray<CCountryTag> (24) {data@+8, cap@+16, count@+20}, _IsInitialized byte@+32}。批量构造 0x142063D70 (330 行) / 单条增量 0x1420632B0 (122 行) 两版同构互证; 语义 = 补贴条目集 → 可作用买方国家集合的**交集折叠**: 有国家列表条 (元素+40==0) → targets 逐条 sorted merge 交集 (首条整拷, tag 比较经恒等表 sub_140BB5490) / 无列表条 (+40==1) → 未初始化先置全国家 (sub_1420634B0 遍历 gs+784 取国+8) 再逐条谓词 (archetype 匹配 ∧ sub_1413B2580 targets 求值) 逐步收窄; 断言 :34/:64 archetype 全条一致 / :59/:86 结果非空 (空 = 数据破损)。swap = sub_140157780 `std::swap(CPdxArray<CCountryTag>)` 特化 (内联缓冲 256 类型名直证)。

contract_delivery_state 六函 (书已收 CalcDeliveryAt/IsComplete/ctor 的同文件邻接函; 均断言行号定位, 函名未取勿杜撰):

| VA | 行数 | 锚行 | 身份/机制 |
|---|---|---|---|
| 0x141444E80 | 96 | :81 | 剩余池构造 = 实拷两池 (def+72 池 {data+80,count+92} + def+96 池 {data+104,count+116}) + byte def+128→out+56 → CEquipmentVariantPool 结果对象 (vtable 直证), 再减付款池; **两条 IsValid() 断言** (contract_delivery_state.cpp:81 闩 byte_14338A4B7 / .h:24 闩 byte_14338A4B4, 均判 *a1 != 0); 两池拷贝为**不同模板实例** (池1 sub_140307560 / 池2 sub_140185F90) (调用方 = §4.23.3a 中期抽取链 sub_1419D5080 与 sub_141AA3F40) |
| 0x141444CE0 | 115 | :102/:106 | HasSunk: Sunk 池 = 付款池 − 转移池 (非负断言), 返 Sunk 非空 (消费方 sub_14204EBA0; 业务精名未决) |
| 0x1414458B0 | 112 | :114-118 | Validate 纯断言: _FactoryCicProgress ∈ [0, def+208−def+200] / _EquipmentTransferProgress ∈ [0, def+208] — **GetTotalFactoryPayment() = def+208−def+200 (总 CIC 价 − 补贴抵扣 = 买方实付) / GetTotalCic() = def+208 直证** |
| 0x141445060 | 92 | :194-200 | operator− 交付装备池差 = ToTransfer(Second) − ToTransfer(First) (两态各自经付款池原语全折算; 同合同断言 :195, 闩 byte_14338A4C2; 结果非负断言 :200; IDA 实参序 = 第二 − 第一, 与 141444920 同向) |
| 0x141444710 | 108 | :208-214 | operator− 转移池差 |
| 0x141444920 | 56 | :221-222 | operator− qword 差 (+40 惰性值 = 合同 +512 剩余 CIC 差; 实算方向 = Second − First, IDA 直证) |

支撑原语: 付款池 0x141444B60 (state+8 进度先经 **sub_1413B9FA0 有效付款进度** — 进度 < def+208−def+200 时 = 进度 + min(def+200, F×进度/1e5) 钳至 def+208, 否则 = def+208; §4.23.16 折算 sub_1413B9E80 的消费点, 书未载) 再 sub_1413BA070 折装备池 / 转移池 0x141444A50 (state+16 直折) / GetDefinition 0x141445270 (AreStatesOfSameContract = def 回指相等) / 惰性 qword 取值器 0x14045AEE0 (state+32 旗假 → sub_141445800 重算并置旗, 值 = *(state+40))。断言锚 (定案): 付款池 :89 (闩 byte_14338A4B8) / 转移池 :96 (闩 byte_14338A4B9) / 各函叠 contract_delivery_state.h:24 IsValid 头内联展开站 (闩 byte_14338A4B4); 付款池尾调 sub_1410129B0 结果规整 (语义未决)。状态 48B 本体字段实名增补 (与 §4.23.3 +472 段记法吻合): +8 = _FactoryCicProgress / +16 = _EquipmentTransferProgress / +32 byte = 两进度惰性重算旗 / +40 qword = 惰性值 (+512 互证)。

#### 4.23.16b 补贴批量移除与市场池入账 (market_equipment_subsidy_container.cpp + market_stockpile.cpp; 2 函定案)

**补贴批量移除 sub_1413B51F0** (170 行; 宿主 = 国家侧 market 外层对象 +32 的 **CEquipmentSubsidyContainer**, 布局 {i64 CIC 累计总额@+0, CPdxArray\<CSubsidy\> {data@+8, cap@+16, count@+20}, 元 48B}; a2 = 待删规格数组 {data@+0, count@+12}, 48B 条)。执行序五步:

1. 容器内线性匹配 sub_1413B2A40(规格, 条目) (archetype@+8 等 + 国家列表 sub_1413B24D0 相容, **不比 cic**) → 下标; 未匹配 = −1。
2. 断言 `Index >= 0 && _Subsidies[Index].GetCicAmount() >= SubsidyToRemove.GetCicAmount()` (cpp:83, latch byte_14338A2AE)。
3. `*总额 -= min(条目 cic, 规格 cic)`; 余额 = 条目 cic − 规格 cic。
4. 紧凑化: sub_1413B28C0 判删条目整体跳过 (尾前移, 逐条拷 +0/+8 与 +16 国家数组 sub_140301D80; ExactEqual = cic + archetype + 国家列表全等) → sub_1413B54D0 截新 count。
5. 余额 > 0 → 建残余条 sub_1413B2BF0 回插 (以待删条的 CicAmount/archetype(+8)/国家列表构造; 国家列表按条目+40 byte: ≠0 无列表条件 → 浅拷 +16..+31 {data, cap}; ==0 → sub_14011DF40 + sub_1401E1640 深建, data = *(规格+16), count = u32@(规格+28))。

国家列表比较 sub_1413B24D0 (相对国家列表基的偏移): +24 byte 三态: −1 = 通配 (恒真) / 非零 = 指针比较 / 0 = count@+12 相等后逐 tag 比较 (tag 相等或经恒等表 sub_140BB52F0)。与 §4.23.2 CSubsidy 表 (data@+16 / cap@+24 / count@+28 / byte@+40) 换算一致。唯一业务方 sub_1413B7AB0(国家侧市场对象, 规格) — 移除补贴后返回 a1+264 的 shared_ptr (px≠0 断言); 被 sub_140DEBED0 (request 入队) / sub_140DEBDF0 (直接成交) 调用。⚠ 未决: sub_1413B28C0 的精确删判条件 (CicAmount 归零 / 匹配同一规格) 与残余条插入位置 (有序/尾插) 未单独反推。

**市场池入账通道 CMarketStockpile::RemovePool (sub_1419D6E60)** (35 行): sub_1410127D0(a1+56, a2) = **池合并原语** (遍历 a2 池2 条, 每条量经 sub_1424EF6F0 取负后 sub_14100CCE0 并入市场池 — 与 §4.23.3a SubPool 取负同原语) → 断言 `!_EquipmentPool.IsAnyNegative()` (cpp:87, latch byte_14338B4B3, 谓词 sub_141010BD0; 市场 latch 区 byte_14338B4B0..B4B3 四枚 = :21/:54/:55/:87) → sub_1419D63D0 通知 (同执行器 sub_1419D6A60 的统一通知口)。业务调用方 = sub_140DEBED0 (request 入队) / sub_140DEBDF0 (直接成交), a1 = 买方国 CMarketStockpile — 两路成交前的装备入池通道, 与 §4.23.16 执行器 sub_1419D6A60 的出池对偶。

**CEquipmentMarketSystem +96 补注**: mkt+96 的 requests 桶表亦 = **待处理请求查询对象** — ContainsPendingRequest(PurchaseRequest) 断言 (cpp:195/204, latch byte_14333CFA4/FA5) 逐桶线性扫描 `*桶基 != a2` 定位; 桶下标 = sub_140BB5490(合同+92) (buyer tag)。与 §4.23.3 「槽 i 归属国 i−1」 dense-index 说的确切关系未决 (sub_140BB5490 是否 = tag→下标恒等映射未定)。

**价格档位 UI 数值语义 (sub_142065F90, 112 行)**: 档位 → 本地化键 + 数值参数:

| 档位枚举 | 本地化键 | 数值参数 |
|---|---|---|
| 0 | INTERNATIONAL_MARKET_PRICE_LEVELS_WIDGET_PRICE_LABEL_LOW | LOW_PRICE_LEVEL_FACTOR − 100000 |
| 1 | INTERNATIONAL_MARKET_PRICE_LEVELS_WIDGET_PRICE_LABEL_NORMAL | 无 |
| 2 | INTERNATIONAL_MARKET_PRICE_LEVELS_WIDGET_PRICE_LABEL_HIGH | HIGH_PRICE_LEVEL_FACTOR − 100000 |
| ≥3 | — | 断言 `Localization is not define for the given Price Level.` (cpp:59, latch byte_14338D033) + 回退串 "NA" |

数值经 0x68B 参数结构封装 (tag=9, 键 "FACTOR", i64 值), 即 **UI 显示 = 档因子 − 1.0 (fixed×1e-5) 的百分比差** (LOW 0.75 → −25%, HIGH 1.25 → +25%)。define 钳位域 (defines_game.h:265/266): NMarket.LOW_PRICE_LEVEL_FACTOR (qword_143331BA8) ∈ [0, 100000], 越界警告 + 回写边界值; NMarket.HIGH_PRICE_LEVEL_FACTOR (qword_143331CE8) ≥ 100000 (<下 → 警告 + 回写 100000, 无上钳); lua 注释 "Should be in range (0,1]" / "Should be more than 1." 与钳位域一致。档位枚举序与 §4.23.3 price_levels 映射 (sub_1419D3FD0) 完全同源, 无冲突。

#### 4.23.17 装备统计注册表胶水 (unit_stats.cpp; 4 函闭环 — 枚举↔token 78 case / 正向旗 / 三表对账)

簇清册 (体内 cpp 锚 4/4; 全新; 与 §4.23.15 脚本枚举对账同族机制 — 统计侧):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_1413E6920 | 342 | :247 断言 "WTF!!!" (B51, 闩 byte_14338A3C0) | 装备统计枚举 → writer token 映射 (78 case, default 断言 + token 357 兜底) |
| sub_1413E7150 | 251 | :284 断言 "Invalid equipment stat token" (B52, 闩 byte_14338A3C1) | 统计 token → 正向旗布尔 (同一 78 token 二分类) |
| sub_1413E8CB0 / sub_1413E8D70 | 36+36 | :305/:312 (CLogStream 4096) | EQUIPMENT_STATS_META ↔ script_enum_equipment_stat 双向一致性错误发射器对 (文案 = §4.23.15 类别侧同款「cf. EQUIPMENT_STATS_META in code」) |

**枚举→token 78 case 全录** (原版基线零未名; 值域 593): 0 default_morale (11950) / 1 defense (10836) / 2 breakthrough (11956) / 3 hardness (13733) / 4 soft_attack (11960) / 5 hard_attack (11961) / 6 recon (12196) / 7 entrenchment (13551) / 8 initiative (13573) / 9 casualty_trickleback (12744) / 10 supply_consumption_factor (12597) / 11 supply_consumption (11887) / 12 suppression (11959) / 13 suppression_factor (13838) / 14 experience_loss_factor (13375) / 15 equipment_capture_factor (14415) / 16 fuel_capacity (15138) / 17 recovery (10106) / 18 additional_collateral_damage (10121) / 19 surface_detection (11965) / 20 sub_detection (11967) / 21 surface_visibility (12287) / 22 sub_visibility (12288) / 23 carrier_sub_detection (10219) / 24 carrier_surface_detection (10221) / 25 lg_attack (15351) / 26 lg_armor_piercing (15350) / 27 hg_attack (15354) / 28 hg_armor_piercing (15353) / 29 torpedo_attack (12310) / 30 sub_attack (11972) / 31 anti_air_attack (12442) / 32 amphibious_defense (12965) / 33 naval_speed (12332) / 34 naval_range (13362) / 35 mines_planting (14656) / 36 mines_sweeping (14657) / 37..41 海军命中率族 (12011/12101/15191/12077/12089) / 42 naval_weather_penalty_factor (16333) / 43..45 协同族 (12975/12976/12977) / 46 air_range (12236) / 47 air_defence (11958) / 48 air_attack (11962) / 49 air_agility (12238) / 50 air_bombing (12336) / 51 air_superiority (12335) / 52 naval_strike_attack (12440) / 53 naval_strike_targetting (12441) / 54..59 空军与铁路炮族 (13166/13269/15422/19874/16415/16419) / 60 max_organisation (12330) / 61 max_strength (11948) / 62 maximum_speed (11954) / 63 armor_value (12099) / 64 ap_attack (12100) / 65 reliability (12668) / 66 reliability_factor (13572) / 67 weight (593) / 68 thrust (10811) / 69 fuel_consumption (11955) / 70 fuel_consumption_factor (15713) / 71 strategic_attack (11901) / 72 carrier_size (11964) / 73 submarine_carrier_size (17093) / 74/75 适应训练族 (14532/14531) / 76 night_penalty (12153) / 77 build_cost_ic (11951)。

**正向旗返 0 全集 14 枚** (负向/成本类, 「越大越好」旗): weight / supply_consumption / build_cost_ic / fuel_consumption / fuel_consumption_factor / night_penalty / surface_visibility / sub_visibility / carrier_sub_detection / carrier_surface_detection / naval_torpedo_enemy_critical_chance_factor / naval_weather_penalty_factor / railway_gun_annex_ratio / railway_gun_hours_between_redistribution — 其余 64 枚全返 1 (与统计名语义逐一吻合); 未知 token 断言返 0。**类别全集第三份镜像机制 (§4.23.15 同款) 在统计侧复现**: 脚本枚举 script_enum_equipment_stat ↔ 代码 EQUIPMENT_STATS_META 装载期双向对账。

#### 4.23.18 装备蓝图窗两级定位 (equipmentblueprintwindow.cpp; 2 函闭环 — 设计器窗/模块槽子窗)

簇清册 (体内 cpp 锚 2/2; 全新; 类名 §4.31 族表已列未展开):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_141DD79C0 | 245 | :50 格式化错误日志 (通道 65540) "Failed to find equipment designer window for equipment…" | 装备设计器窗定位器 |
| sub_141DD7E60 | 271 | :128 格式化错误日志 (65540) "Failed to find equipment designer module window…" | 设计器模块槽子窗定位器 |

**设计器窗定位** (sub_141DD79C0; find_designer_window(guimgr, 装备def, 名来源, 报错旗)): 候选名四连查 (sub_14225C5A0 .gui 名查窗原语; **命中判据 = 窗+8 == 612**, §4.31.92 互证): ① token(def+8) + 名来源修饰段 (sub_140BB4E70) → ② token(*(def+1240)+8) + 同段 → ③ token(def+8) 裸名 → ④ token(*(def+1240)+8) 裸名; 全 miss 且报错旗 → :50 日志列四候选名。

**模块槽子窗定位** (sub_141DD7E60; find_module_window(ctx, 装备def, 槽名, 报错旗)): 前置门 ctx[6] vtable+568 谓词真 → 直接 0; 候选名序列 (每步拷名+修饰+FindChildWindow+可见性谓词): a2 有效 → token(a2+8) / 串 a2+232 / token(a2+64) / 槽名 (ctx[6] vtable+168); a2 空 → **token 10830 (缺省槽, 文本名待运行期定名)**; 末步 a3 裸串再查一次; 全 miss → :128 日志 (带脚本文件名/行号/槽名/全部 tried 名)。

两函构成「装备 → 设计器窗 (612) → 模块槽子窗」两级定位, 供蓝图窗打开/刷新链消费; 窗名模式 = 「<token 名/串><后缀>」与裸名双形。

未决: def+1240 二级 def 身份 / token 10830 文本名。

#### 4.23.19 装备模块需求域 (equipment_module_requirements.cpp; 4 函闭环 — CEquipmentModuleRequirements 模块-槽合法性三道门)

#### 4.23.20 装备模块/类别定义校验汇报器 (equipment.cpp; 1 函 = sub_140C96FB0, 定案/描述符语义推定)

#### 4.23.21 国际市场价级本地化键 getter (international_market_ui_utils.cpp; 1 函 = sub_142066190, 定案)

#### 4.23.22 合约条目 civs tooltip 构建器 (purchase_contract_entry.cpp 匿名 ns; 1 函 = 0x14204E540, 定案/字段语义待裁)

0x14204E540 (ctx, out) — out = 双串 {主 TT @+0, explanation @+32}; market = *(ctx+64)。**SCivAssignment 栈结构** (匿名 ns, vtable 符号直证) = {vt@0, i32 cur@8 ← market+608, i32 req@12 ← market+192, char@16 ← sub_141BCFE70 (推定 disturbed 旗), bool@17 = cur<req} — 与已收 SConvoyAssignment (§4.31 同件) 同域平行不同型。控制流: market+216==0 → 惰性构建 +24 子对象; **cur = *(market+496) (qword) < need = 子对象向量字节差 (+224..232)** → 主分支 (格式化行 sub_142052B10, this = 栈构 SCivAssignment — §4.31:437 「vtable+8」槽语义宿主落实) + 状态键三分支 (`..._REQUIRED_CIVS_DISTURBED` / `..._RECOVERING` / `..._DISTURBED_NOEFFECT`); cur ≥ need → `PURCHASE_CONTRACT_ALL_PAYMENT_COLLECTED_TT`; 尾恒 `PURCHASE_CONTRACT_REQUIRED_CIVS_EXPLANATION_TT` → out+32。⚠ market+496 (qword) 与向量字节差直接比较, 单位一致性待裁。

sub_142066190 (价级枚举 → 本地化键, sub_142245E60 写出参串): 0 → `INTERNATIONAL_MARKET_PRICE_LEVEL_LOW` / 1 → `_NORMAL` / 2 → `_HIGH`; ≥3 → :40「Localization is not define for the given Price Level.」(**原文拼写 define**, B51 告警级, 闩 byte_14338D032) + 落空串 "NA" (SSO size 2 / cap 15)。⚠ 与 §4.23 价级 widget 键族 `INTERNATIONAL_MARKET_PRICE_LEVELS_WIDGET_PRICE_LABEL_*` (复数 LEVELS + widget 段) 为**两套并存键族**, 分属不同 UI 件, 勿混引。

sub_140C96FB0 (装载后校验): a1 = 被校验描述符 (**category i32@+40 / module i32@+44 / 比较运算符 token u32@+48 / title 串@+8 + 指针门@+24**); a2 = std::string 源文件名, a4 = 行号 (四条错误全带 `<文件名>:<行号>` 前缀)。四条: ① category≤−1 ∧ module≤−1 → :65「no category or module defined」; ② token ∉ {**1, 467, 468**} → token>−1 → :83「unexpected comparison operator '%s'」(名经 sub_1424BC260) 否则 :78「no amount defiend」(**原文拼写**); ③ title 指针门非空 ∧ **sub_142244840 谓词失败** → :91「title does not refer to an existing localization key '%s'」。token 三值经离线表 PE 侧验算 = 1「=」/ 467「>」/ 468「<」(比较运算符)。sub_142244840 = 本地化键存在性校验器 (与 §4.7 technology_sharing / §4.26 autonomousstate / §4.27 raid_target 同原语, 本批 equipment.cpp:91 断言串坐实)。

CU = `hoi4\source\equipment\equipment_module_requirements.cpp`; 宿主类 **CEquipmentModuleRequirements** (C++ 符号 `CEquipmentModuleRequirements::InheritLimits` lambda vftable 名直证); 限制条 **SModuleCountLimit** (匿名命名空间) = 12B/条 {槽 token, 比较枚举, 阈值}, 比较枚举 0 = MIN (数量 ≤ 阈值 非法, 合法下限 = 阈值+1) / 1 = MAX (数量 ≥ 阈值 非法, 合法上限 = 阈值−1) / 2 = EXACT (数量 != 阈值 非法), else :471 断言 latch byte_14338A895; 二分查槽 token, 未命中 = 无限制。InheritLimits (0x141534330) 沿依赖图顶点继承复制限制表。

**违规 loc 文案生成器 (sub_141532FE0, 225 行, :555, df305 定案)**: 候选池簇名 `requirements.cpp` 实为本文件 — 限额表 = 引擎自定义容器 (计数@+12), 条目 12B {模块 id (有序, upper_bound 式二分), 枚举 0/1/2, 限额值}; 查空 → 空串 (无违规)。三分支: 枚举 0 → **EQUIPMENT_MODULE_LIMIT_NOT_EQUAL** (REQ_COUNT = 限额原值) / 1 → **EQUIPMENT_MODULE_LIMIT_MAX_EXCEEDED** (显示上限 = **限额−1**) / 2 → **EQUIPMENT_MODULE_LIMIT_MIN_EXCEEDED** (显示下限 = **限额+1**) / 其他 → :555 "Invalid enum value in SModuleCountLimit" 返空串; 各分支附 TITLE 参数 = 模块名 (sub_1415333B0)。⚠ **MAX/MIN 显示值 = 存储值 ∓1 怪癖 (待裁)**: SModuleCountLimit count 字段内部表示比脚本面值偏移 1 (内部 +1 冗余编码推定, 即 max=N 存 N+1) — 复刻/对拍须按引擎存储形态而非脚本字面理解。⚠ 另注意: §4.23.19 上段比较枚举语义 (0=MAX/1=MIN/2=EXACT) 与本段文案枚举 (0=NOT_EQUAL/1=MAX_EXCEEDED/2=MIN_EXCEEDED) 同为 {0,1,2} 但**语义不同源** (前者 = 校验谓词, 后者 = 违规文案分派), 勿混读; 对应关系 = 校验 0 (MIN) ↔ 文案 2 (MIN_EXCEEDED) / 校验 1 (MAX) ↔ 文案 1 (MAX_EXCEEDED) / 校验 2 (EXACT) ↔ 文案 0 (NOT_EQUAL), 与「显示值 = 存储值 ∓1」怪窍同源自洽。

四函身份表:

| VA | 行数 | 身份 |
|---|---|---|
| 0x141533900 | 536 | 缺失需求 tooltip 文本构建器 (直接/间接需求) |
| 0x141534850 | 450 | 模块-槽合法性校验主链 (三道门 + 依赖图遍历) |
| 0x141535F70 | 158 | 依赖图遍历 visitor 层级槽集合回调 |
| 0x141534720 | 60 | SModuleCountLimit 三态比较校验 |

**模块-槽合法性三道门** (0x141534850, 定案): ① 全局依赖图 (CPdxScopedPtr 持有单例; 顶点表 40B/条, +24 = 槽 token) 直查 {槽 token, 类别 token} 声明对, 命中且条目 +0 == +8 (直通形态) → 合法; ② 槽条目 (CEquipmentType+112 槽数组 80B/条, +8 槽 token / +24 容器 / +36 计数 — §4.23 +112/+124 互证) 允许类别向量线性查, 未命中 → 本地化 EQUIPMENT_MODULE_CATEGORY_NOT_ALLOWED {CATEGORY, SLOT}; ③ boost 图形态依赖遍历 (颜色表 = CPdxHybridInlineBufferAllocator<boost::default_color_type,16>; maxDepth 枚举 0 = 无限 0x7FFFFFFF / 1 = 仅直接需求 / 其他 :696 断言 latch byte_14338A897), visitor 层级槽集合 = 逐层继承上一层集合 (memcpy) + 当前槽 token 二分插入, 插入失败 (重复) :210 "Duplicate slot in set" 断言 latch byte_14338A892 — 语义 = 同一槽在一条依赖路径上只允许出现一次。

**缺失需求 tooltip 两段**: ① 间接需求 = 需求上下文逐条在已满足表 (16B/条有序 {token, 模块*}) 二分, 任一不满足 → 单键 EQUIPMENT_MODULE_MISSING_INDIRECT_REQUIREMENT 早退; ② 全满足才报直接需求 = 头 EQUIPMENT_MODULE_MISSING_DIRECT_REQUIREMENT_HEADER {CATEGORY} + 逐行 ..._ENTRY {SLOT, MODULE} 行间 "\n"。断言: 未知槽 :434 latch byte_14338A893 / 未知模块 :441 latch byte_14338A894。

**消费链**: 0x140C97670 = 模块安装校验包装 (先查模块自身类别 → 本地化 EQUIPMENT_MODULE_CATEGORY_NOT_ALLOWED_BY_MODULE {CATEGORY, MODULE} → 再进主链); 消费 6 处, 其中 CEquipmentType 方法形态 = `(*(type+1008), type+184, …)` (+1008 接口槽 / +184 modules 容器互证)。⚠ SModuleCountLimit 与 s4_23 equipment_modules limit(10762) 脚本触发器向量的编译/继承关系待裁 (InheritLimits 只证沿图继承, 来源侧未追)。

#### 4.23.23 装备库存差异消息构造器 (1 函 = 0x14149D8F0, 定案/两份映射真名未决)

`(消息/串累加器 Src, 映射甲 a2, 映射乙 a3)` — 逐 TGameItemDatabase 条目 (单例 qword_14332EEC0, 自身断言 gameitemdatabase.h:142; db+128 条目数组 / db+140 计数) 比对两份「按装备类别的数量映射」, 生成 **DEPLOYMENT_EQUIPMENT_CHANGE** 本地化消息。

比对: 映射形 = {data@+8, count@+20, 16B/条 (类别指针键 + qword 值)}; sub_14100EA10(映射, &out, 条目) 按 `*(条目+1240)` (装备 def 类别指针, 与 §4.23 +1240 基原型链同槽) 查数量, 未命中写 0; 差 d = 甲−乙, q = d/100000 (fixed 1e-5), q ≠ 0 才处理 (不等除时按符号上取整回写 d)。装配: 参数组 1 = {类型 5, q, 键 `STAT_VALUE_DIFF_NEUTRAL`} → sub_142245E60; 参数组 2 = 条目名 (sub_140BC9E70 取 def+24 SSO 串) 键 `NAME` + q 键 `VALUE`; 主串 sub_142245E60(Src, `DEPLOYMENT_EQUIPMENT_CHANGE`, 2 参) 追加 + 换行。调用点 3 处 (sub_1414A0930 内), 语义 = 两份快照比对 (映射真名未决)。
