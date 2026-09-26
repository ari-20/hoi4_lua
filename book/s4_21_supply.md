

### 4.21 补给系统 2 (CSupplySystem)

**获取**: `sys = *(gs + 984)` (单解引用; gs+984 = CPdxScopedPtr::_pPtr 裸槽,
operator→ = sub_1401C6D30, 断言 "_pPtr" pdx_scopedptr.h:124)。
对象 +0 = 副 vtable RVA 0X2973CC8 (4 槽: _guard_check_icall_nop / sub_140EC4710 /
sub_140ECA010 / sub_140ECA130); **+8 = 主 vtable RVA 0X2973CF0** (CPersistent 链)。
序列化口径: gs writer `ADEC0(a2, 19687 supply_system_2, sys+8)` = 落盘主基
子对象指针 (探针实证: `*(gs+984)` 对象 [P+0]=…CC8 / [P+8]=…CF0;
本册 §4.21.1 骨架偏移一律以 P = sys = `*(gs+984)` 为基准)。
每国条目数组: `sys+264` CPdxArray {data@264, cap@272, count@276} (探针
现役局 738/738), 元素 = CCountrySupplySystem (656B, ctor 141218530,
vtable 0X29A2B08, 逐国 scoped-ptr, 扩容 140ECAF00); tag 反查: `*(el+120)`
= CCountry*, tag 串在 CCountry+8; 国家入口原语 = sub_1406EE6E0
(`*(sys+264)[BB5490(country+8)]`, 全读侧共用, 80 调用者)。

**CCountrySupplySystem 字段** (656B; writer 0x1412318a0 / loader
0X14122D890 / ctor 0X141218530 三源互证):

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +8 | CEquipmentDistributable 内嵌基 | 基类 {vt@+8, priority u32@+16, +24 qword=0} | 基 ctor 0X1415A7410 (RTTI 0x1429DC100); 基 writer 键 141=priority (!=1 才写), loader 弃读 | |
| +16 | uint32 | priority | ==1 默认 (writer 默认不写 → SUP2-SETTINGS 145 家族门; loader 弃读) | |
| +24 | qword | 基成员 (=0 init; 名未决) | | 高置信形态 |
| +32 | 容器 24B | **_IntermediateTransportUsages** {data@32, cap@+40, count@+44, alloc@+48} — **48B 条** {变体 id u32@0 或 @8, count u32@+4, amount i64 fixed@+32, 变体旗 u8@+40} | 断言 "Unknown variant type in _IntermediateTransportUsages" | 不序列化 |
| +56 | 容器 24B | 运行时 {data@56, cap@+64, count@+68, alloc@+72} (语义未决) | | 形态定案 |
| +80 | 容器 24B | 运行时 {data@80, cap@+88, count@+92, alloc@+96} (语义未决) | | 形态定案 |
| +104 | u8 | 旗 (多个小 accessor 读; 名未决) | | 存在定案 |
| +112 | CSupplySystem* | **系统回指** (ctor 参 a2) | | 不序列化 |
| +120 | CCountry* | 属主国家 (ctor 参 a3 = `*(gs+784)[i]` 国家数组元素) | | |
| +128 | 匿名结构 (800B)* | **系统侧每国 800B 记录指针** (ctor 参 a4 = `*(sys+288) + 800*国idx`; 消费 +384 计数/+360 数组随机选) | | 不序列化 |
| +136 | 匿名结构 (NNB 形状) RH 桶数组 | **disrupted_supply 表头** {tab@+144=空桶 &unk_143086320, count@+152, mask@+156, maxdist u8@+160, load_factor f32 0.9@+164} | ⚠ army_manpower_need (amn) 不在此 — amn +136 属 state_garrison_data (writer 0X141000700 键 14076, SGD+136 u32); loader case 19698 插入本表 | |
| +168 | 匿名结构 (元素待裁) RH 桶数组 | **运行时供应节点状态表** {tab@+176=空桶 &unk_1430B2C10, count@+184, mask@+188, maxdist@+192, lf 0.9@+196} — **104B 桶** {…, +36 dword, +60 dword, 内层 32B 容器@+80/+88} | 重建 0X14122BD90 (按系统侧 120B 国别记录旗 &2/&4 分支遍历清桶) | 不序列化; 形态定案/语义推定 |
| +200 | u32 | wanted_supply_trucks | writer sub_1424C2F40 (u32 写器) 读 `*(DWORD*)(v3+200)`; lua reader 亦作 ru32; loader 弃读 | |
| +208 | 容器 24B | 供应流运行时数组 {data@208, cap@+216, count@+220, alloc@+224} — **40B 条** ("ToGive <= RemainingNeed" 流域) | | 不序列化; 形态定案/推定 |
| +232 | CConvoySubscriber 内嵌 | (+232..+287; vt 0x14295c0f0; 重建 sub_141021F90(+232, country, 32, define)) | 每日重建 0X141230D40 | |
| +272 | u32 | **train 侧计数** (位于 CConvoySubscriber 内嵌区 +40; get_supply_vehicles_temp train 分支直读) | 推定 | |
| +288 | 容器 24B | **每变体火车信息** {data@288, cap@+296, count@+300, alloc@+304} — **24B 条 = pair\<CRef\<CEquipmentVariant\>, STrainInfo\>** (RTTI 0x142A4B168 混合内联缓冲) | | |
| +312 | u32 | **_TotalTruckInfo._Allocated** | 断言 "_PerVariantTruckInfo.IsEmpty && _TotalTruckInfo._Allocated == 0" 查 `+340==0 && +312==0` | |
| +320 | qword | _TotalTrainInfo 对应聚合 (=0 init) | | 推定 |
| +328 | 容器 24B | trucks = **_PerVariantTruckInfo** {data@328, cap@+336, count@+340, alloc@+344} — 24B 条 {id 对@0, count u32@+8, damage fixed@+16} | writer 键 19688=truck; 上条断言互证 | |
| +352 | 容器 24B | **supply capital 迁移早退州表** {data@352, cap@+360, count@+364, alloc@+368} — u32 州 id (CanMoveSupplyCapital 命中即返 0, loc CANT_MOVE_SUPPLY_CAPITAL_*; 失都时清 count=0) | | 不序列化; 高置信 |
| +376 | u32 | **capital** (supply 首都州 id; >0 才写, loader 弃读) | 0X141220400 以之查州属主 | |
| +380 | u32 | last_supply_capital_move = **距开局天数** (`(gs小时−43800000)/24`) | loader 弃读 | |
| +384 | fixed×1e-5 | buffer (init = 全局 define qword_143336F08; loader 弃读) | | |
| +392 | 容器 24B | **settings** {data@392, cap@+400, count@+404, alloc@+408} — **40B 条** {id 对@0, disabled u8@+8, motorization_level 容器 {data@+16, count@+28} 8B {tag u32, level u8}} | writer 键 11101=settings (内 350 node / 11 id / 240 data / 14065 disabled / 19943 motorization_level) | |
| +416 | fixed×1e-5 | **starting_truck_buffer** (init 1.0; >0 才写; loader 弃读) | 键 19699 | |
| +424 | fixed×1e-5 | **starting_train_buffer** (init 1.0; >0 才写; loader 弃读) | 键 19710 | |
| +432 | 容器 24B | **temp_nodes** {data@432, cap@+440, count@+444, alloc@+448} — **104B 条 = homebase inner 同构** {supply@0, start@8, penalty@16, add 串@32, duration@64, province@72, hours@80, decay@88, base u8@96} | writer 键 19706 | |
| +456 | 容器 24B | 节点指针收集表 {data@456, cap@+464, count@+468, alloc@+472} — 8B 指针条 | 由 temp_nodes 匹配重建; 海港/海运相关 (推定; 邻近断言 "SeaProv > 0") | 不序列化; 形态定案 |
| +480 | 容器 24B | foreign_homebase_nodes {data@480, cap@+488, count@+492, alloc@+496} — 112B 条 = {裸 key u32@+0 (省 id, 提取件不落叶) + inner 104B 对象@+8} | writer 键 17096 | |
| +504 | 容器 24B | 每日重建即清 {data@504, cap@+512, count@+516, alloc@+520} (语义未决) | | 形态定案 |
| +528 | 容器 24B | 每日 sub_140ECA790 重置 {data@528, cap@+536, count@+540, alloc@+544} ("PerCountryIndex >= 0" 增长; 语义未决) | | 形态定案 |
| +552 | 环形 24B | **lost_railways** {data@0, cap@+8, count u32@+12, alloc@+16} 30 槽 int64 | writer 键 19876; loader 逐环实载 | |
| +576 | 环形 24B | **lost_trains** (同形) | 键 19877 | |
| +600 | 环形 24B | **lost_trucks_attrition** (同形) | 键 19878 | |
| +624 | 环形 24B | **lost_trucks_killed** (同形) | 键 19879 | |
| +648 | u32 | **last_lost_train_province** | writer 键 19880; loader 弃读 | |
| +652 | u32 | daily_losses_index | 键 19875; loader 弃读 | |

0x1412318a0 = CCountrySupplySystem 全块序列化器 (外层 sub_140ED0450 经 vt
0X29A2B08 slot+8 虚调; 尾部 4 环 @552/576/600/624 与 0x288/0x28C 吻合)。

**disrupted_supply 桶** (24B; +136 表):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +4 | uint32 | dist | |
| +8 | u32×2 | key | id 叶 = key 对原样; 发射序 = node id (key 低 u32@+8) 升序 (实证 CHI 1047→4190→9956) |
| +16 | fixed×1e-5 | value | i64 定点 |

系统侧每国 800B 记录 (基址 = *(sys+288), 800×国idx 步进; 条目+128 同指)
完整布局见 §4.21.2 (旧补行 +304/+320 已并入并升定案)。

#### 4.21.1 CSupplySystem 骨架 (sys = *(gs+984); 副 vt 0X2973CC8@+0, 主 vt 0X2973CF0@+8)

⚠ ctor 141218AC0 / Reset 1412202B0 属 **CSupplyCalculationData** (§4.21.2),
非本类 (本类无 ctor/Reset 定案)。结构由探针 + 读侧调用簇双证: P+8 = 主
vtable; P+272/276/296/300 = 738 = 国家数; P+352/P+424 无哨兵。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +0 | — | 副 vtable | RVA 0X2973CC8, 4 槽 (guard nop / 140EC4710 / 140ECA010 / 140ECA130) | 探针定案 |
| +8 | — | 主 vtable | RVA 0X2973CF0 (CPersistent 链); 序列化指针 = sys+8 | 探针定案 |
| +16 | qword* | 流值乘数表数据指针 | sub_140EC8A00 流值变换按槽 idx 索引 | 推定 |
| +64 | 匿名结构* | 每国记录宿主子对象 | 内含每国 120B 记录数组 — entry+112 回指后经 +64 访问, 旗 u8@条+112 的 &2/&4 分支; +88/+112/+136 容器群被校验和件 140EC5A80 覆盖 | 探针非空指针; 语义高置信 |
| +232 | — | 待裁 | 探针 = float 1.0; 供应重算前省键哈希缓存清条目 (lam 12) 的表头归属待裁 (语料正文作 gs+232) | 待裁 |
| +256 | — | 待裁 | 探针 = float 对 (0.9 / 0.56); 旧 "countries 容器 {cap@264,count@268}" 行翻案 — countries 由 +264 数组承担 | 待裁 |
| +264 | 容器 | CPdxArray\<CPdxScopedPtr\<CCountrySupplySystem\>\> | {data@264, cap@272, count@276}; 元素 656B, ctor 141218530 (vtable 0X29A2B08, 双 vt +0/+8, 内嵌 CConvoySubscriber@+232, +112/+120/+128 = CSupplySystem*/CCountry*/自家 800B 记录); lam 4 PerCountryIndex 宿主 | 探针+语料定案 |
| +288 | 容器 | CPdxArray\<CSupplyCalculationData\> | {data@288, cap@296, count@300}; 800B/项 = 每国供应计算记录, 扩容 140ECAF00 按国家数, ctor 141218AC0 / 每轮重置 1412202B0 (lam 2) | 探针+语料定案 |
| +312 | 匿名结构 (216B)* | 每省供应聚合表 = **USAggregatedProvinceSupplyData** | lam 9 清零 / lam 10 归并 / lam 11 排序 / lam 15 聚合 / lam 16 驱动; 读侧 140C00590 / 141635650 / 14167CBD0 | 定案 |
| +336 | u32* | 省自旋锁数组 | 每省 1 锁, 0=空闲 (lam 10 `_InterlockedCompareExchange` + `_mm_pause`) | 定案 |

#### 4.21.1a UpdateSupply 并行任务族 (tbb lambda 语义; 网络条目 232B)

网络条目 (232B) 字段: +56 = `Node._TotalSupply` / +64 = `Node._RemainingSupply` (country_supply.cpp:1388 族断言串自证字段名)。

| lambda | 链 | 语义 |
|---|---|---|
| lam 1_5 | EB9CD0→EC80C0 | 供应首都/枢纽合法性校验 (CANT_MOVE_SUPPLY_CAPITAL_NOT_CONTROLLED 门, 结果写布尔表) |
| lam 2 | EBB3D0→1412202B0 | CSupplyCalculationData 逐项重置 (30+ 字段清零, +352=100000 哨兵) |
| lam 3 | EBA9C0→1412212C0 | 供应消费者记录重建 (陆军/铁路炮/国家空军/空军基地; country_supply.cpp:2160-2268 断言族) |
| lam 4 | — | PerCountryIndex 重建 (:3138) |
| lam 7 | EBAE10→141230D40 | 供应节点七步重算 (convoys.cpp:29 + 首都控制权门 :2844) |
| lam 10 | — | 省级数据跨国家归并 (省自旋锁 +336) |
| lam 13 | — | hub 条目摩托化贡献累加 (supply_node_settings.h:33) |
| lam 14 | EBD720→ED0F90→14121EA10 | 供应节点非本地链接处理 (:2919) — 采样最热体 |
| lam 21 | EB9FB0→141225420 | 供应流量分发: 沿 From/To 节点路径扣减推送 (`_TotalSupply(+56) >= _RemainingSupply(+64)`, 防死循环 AvoidInfLoopCounter<100) |
| lam 22 | — | 海口省 SeaProv>0 维护 + mod-24 轮转门 |

⚠ ECD400 体内 15 处 start_for 的**文本线序 ≠ 执行序** (lam 9/10/12/15 走旁路启动包装/直调变体)。

海军可达性 (CNavalAccessibilityManager::Update): 逐国过 `country+1156>0` 门 → 64B/国槽位 (边图描述符 + 双标号数组) → 两次字节并查集泛洪 (1419EE6A0), 边放行 = 邻接规则权限位 &2/&4 (141546CC0/C90 → 141547440 adjacency_check); operator() 无独立实体, 内联于串行叶 140E24BE0。邻接规则进入供应热路径**仅此一条通道**; 141038A50/141966FE0/1419EB1F0 三上游均属部队移动侧, 不在供应段。hourlyUpdateUnits (sub_140717BC0) = 纯统计上报 (army+840 装备占用求和 → country.cpp:13281/13314 条件日志, 调试门 byte_143452529 关闭时不执行)。

#### 4.21.1b DoTradeRoutesUpdate 工人链 (hourly 资源输送路线)

调度 = CGameState::DoTradeRoutesUpdate (sub_1401D9890); 工人链 = 逐脏路线 lambda_2:
F7470→B8AA0→BBB40→F8390→CBC8C0 (工作体: 端点缓存 + 路径校验 + **`(小时+tag_idx)%168` 周度错峰门** — 路线重算按国家错峰分摊, 非每小时全量; trade.cpp:242 簇); 路线元组收集器 AFDD0 (24B 条; MSVC tuple 内存序与声明序相反); 粒度选择器 DB390 (pdx_parallel_for.h:65, EJobType 0/1/2/3 → count/NumTaskThreads、3×、1、整段)。

CBC8C0 阈值分流 (定案): `v35 = BASE_LAND_TRADE_RANGE² × ln(两国持有州数和+2)` vs 1409D3740 (环绕修正的州锚点距离²) — 通过走快检 CAA7990, 否则全量重算 CA90F0。ln = 定点整数 ln (sub_1424EF9D0: 100000·ln(x/100000), 1/e 缩减循环 + Σzⁿ/n 级数); 国家+1132 = 持有州计数 (+1120 州指针数组)。海路节点对可用性 = trade.cpp 四值枚举 (CAA1B0): 3=完全通过 / 1=条件通过 (边缘准入) / 2=结构性失败 / 0=显式阻断; 消费侧 {1,3}=通 {0,2}=断。

运行语义 (defines 收口): 重算预算 = `NGame.TRADE_ROUTE_RECALCULATE_FREQUENCY_DAYS` (vanilla 45, 0=不周期重算; 每日预算 = max(1, 有效路线数/45)), 轮转游标 = gs+2496 `next_trade_route_update_country_idx` (模 gs+796 国家数置脏), 有效路线计数 = gs+2492 `cached_active_trade_route_count` (token 10102), gs+2488 = 每小时元组收集数 (纯运行时)。护航危险评分 = CStrategicNavy 逐战略海区 0-4 级加权归一 (权重 = defines `NNavy.NAVAL_CONVOY_DANGER_RATIOS` vanilla 0.10/0.10/0.10/0.15/0.15, ×1e5 装载; 孪生件 EB06F0 = 水雷危险版)。

#### 4.21.1c 读侧与消费面 (UpdateSupply 之外的全部读者)

**无单一 (国家,省)→补给量 总门查询**; 读侧 = 解析原语 → 每国 CSupplyCalculationData
节点表二分 → 单节点聚合 14194CDF0 按需现算 → 调用域自行合成的分层链。

| 原语/查询 | 语义 |
|---|---|
| sub_1406EE6E0(CCountry*) | tag → CCountrySupplySystem* (`*(sys+264)[BB5490(country+8)]`); 全读侧国家入口 (80 调用者: 脚本 6 / AI 18 / UI 11 / 海军护航 10 / 供应核心 13) |
| sub_141229210(calc, type:id) | FindNodeIndex: 节点 idx 二分 (case0 省→+656 表; 2/3→+704 `_NonLocalNodes`; 4→+728; 5→+752; case1 air 断言 country_supply.cpp:3029) |
| sub_1414E3980(out, state_id, calc) | 州内全部节点 entry+64 求和 (calc+680 表 32B/项, state 键二分) |
| sub_141658020(css, {prov,x}) | css+168 节点流缓存探测 (104B 桶, 断言 country_supply.h:386) |
| sub_140EC8A00(sys, out, entry, 槽) | 流值变换: `*(sys+16)[idx]×(量+100000)/100000−100000` 负钳 0 |
| sub_14194CDF0(entry, OUT, sys, weight) | 单节点聚合供应 (lam 15 同款核; 写侧 5 + 读侧 3 调用者) |

| 域级消费函数 | 语义 | 证据 |
|---|---|---|
| sub_140C00590(unit, prov, threshold)→bool | 移动域供应阈值判定 (unit.cpp:3150; 唯一调用者 1414D9280 unitcontroller 移动校验); 读 +312 行 +48 列表 (16B/项={节点idx,国idx,权重}) 与网络条目 +56/+64 现算 | 断言+调用簇 定案 |
| sub_141635650 / sub_141636C20 / sub_14162FB40 | 供应地图 tooltip 族 (SUPPLY_CAP_AVAILABLE / SUPPLYMODE_TOOLTIP_ENEMY_DISRUPTION / CONSUMER_SUPPLY_TOOLTIP; 直读 +312 216B 行与 232B 条目) | 本地化键 定案 |
| sub_14167CBD0 (+ 入口 14167C560) | 逐省供应状态数组构建 → UI 侧缓存 {data@a1+56, cap@+64, count@+68} | 定案 |
| sub_1402B95E0(gs, json) | "province_supplies" JSON 导出: 每省 = clamp(100×max(流值),0,100) | 定案 |
| sub_1403EE990 / sub_14042C7D0 | CNumOfSupplyNodesTrigger::GetValue/GetDesc → `*(u32*)(*(css+128)+428)` | 名表+断言 定案 |
| sub_140EC5A80(sys) | supply_cache_{provinces,states,countries,dirty,node_flows,...} 校验和/dump | 字符串簇 定案 |

消费可见值落点 (定案): **每国 CSupplyCalculationData +184 网络 232B 条目的 +56
`_TotalSupply` / +64 `_RemainingSupply`, 与 sys+312 省聚合行两处**; GUI/单位域查询
时刻按 14194CDF0 现算, 无持久化汇总字段。唯一被读侧消费的每小时引擎缓存 =
CCountrySupplySystem+168 节点流缓存 (写者 = lam 7/lam 8); css+208 供应流数组无
独立外部读者 (写侧内部消费); css+136 disrupted_supply 独立查询函数未定位,
读取推定内联于 141636C20 — 待裁。
UI 渲染链: UpdateSupply 尾调 14167C560 → 全局发布器 unk_1430B3C10
{data@+56, cap@+64, count@+68=就绪门} → map mode 上色 140F392D0 (读发布器副本,
不直读 +312)。单位侧有效补给比收口 = sub_140C87EC0 (见 §4.18)。

#### 4.21.2 CSupplyCalculationData (每国 800B 供应计算记录, 纯结构无虚表)

ctor 141218AC0 (首写 +8, 无 vtable store) / 每轮重置 1412202B0 (lam 2) /
扩容 140ECAF00 (按国家数, sys+288 数组); CCountrySupplySystem+128 同指自家记录;
不序列化。重置语义: 清累计、tag 回哨兵 −1、因子回 1.0。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 容器 {data@8, count@16} | 条目表, 24B/项压实 (entry+4 旗为真者移除) | 推定=已处理/失效条目 |
| +28 | float | 0.9 系数 (不重置) | 推定=衰减/保持率 |
| +40 | 容器 {data@40, count@48} | 条目表, 12B/项压实 (entry+0 旗) | |
| +64 | 子结构 120B | 供计算子对象 (ctor 1414DFE80 / 清 1414E1860) | 形态定案/语义推定 |
| +184 | 连接表 {data@184, 计数@192} | **232B/条**: entry+4 word 目的 id, +8 dword 计数 (>1 门), +56 qword `_TotalSupply`, +64 qword `_RemainingSupply`, +152 qword 值; sub_14121EA10 以 (省,值) 插类型 3 链接 | 断言串自证字段名; 消费可见值落点, 定案 |
| +196 | dword | (省,值) 对值部 (EA10 读) | 推定=节点本地供应值 |
| +200 | hybrid 容器 | 计算暂存 | 推定 |
| +224 | hybrid 容器 | 计算暂存 | 推定 |
| +248 | hybrid 容器 | 计算暂存 | 推定 |
| +272 | hybrid 容器 | 计算暂存 | 推定 |
| +280 | 容器 | 跨国非本地链接源 (EA10 读他国记录此表的 16B 条目) | 推定 |
| +304 | fixed×1e-5 | truck 侧运输记录值 (get_supply_vehicles_temp: 1e5×ceil_fixed) | 定案 |
| +320 | u32 | train 侧运输记录值 (仅 100000×值 > qword_143331FA0 = **NSupply.MIN_TRAIN_REQUIREMENT** 才写) | 定案 (define 定名闭环) |
| +352 | fixed×1e-5 | 效率/比例因子 (构造=重置=100000) | 值定案/语义推定 |
| +424 | i32 | 来源/属主 tag 哨兵 (构造=重置=−1; EA10 以 ≠−1 为处理门) | 哨兵定案/语义推定 |
| +428 | u32 | 供应节点计数 (141220690 ++; 触发器 num_of_supply_nodes 读) | 定案 |
| +452 | dword | 计数 (重置清 0) | |
| +476 | dword | 计数 (重置清 0) | |
| +500 | dword | 计数 (重置清 0) | |
| +524 | dword | 计数 (重置清 0) | |
| +548 | dword | 计数 (重置清 0) | |
| +560 | hybrid 容器 | 计算用容器 | |
| +584 | hybrid 容器 | 计算用容器 | |
| +608 | hybrid 容器 | 计算用容器 | |
| +632 | hybrid 容器 | 计算用容器 | |
| +656 | 有序表 {data@656, count@668} | 节点 id → 节点 idx 映射 (141229210 case0 二分目标) | 定案 |
| +680 | 有序表 {data@680, count@692} | 32B/项, entry[0]=state id; 州→节点集合 (1414E3980 二分目标) | 定案 |
| +704 | 有序表 {data@704, count@716} | **_NonLocalNodes**: 8B 条 = (省 id, 值), 二分插入 sub_140E905D0; 断言 "!_NonLocalNodes.Contains( NodeProvince )" country_supply.cpp:2919 | |
| +728 | 有序表 {data@728, count@740} | FindNodeIndex case4 目标 | |
| +752 | 有序表 {data@752, count@764} | FindNodeIndex case5 目标 | |
| +776 | qword | — | |
| +784 | qword | — | |
