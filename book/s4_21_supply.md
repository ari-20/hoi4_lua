

### 4.21 补给系统 2 (CSupplySystem)

**获取**: `sys = *(*(gs + 984) + 8)`; **主 vtable RVA 0X2973CF0**;
gs writer `ADEC0(a2, 0x4CE7=19687 supply_system_2, *(gs+984)+8)`。
国家条目容器: {data@+256, cap@+264, count@+268, alloc@+272}, 元素 =
CCountrySupplySystem (vtable 0X29A2B08, 440 全体); tag 反查: `*(el+120)`
= CCountry*, tag 串在 CCountry+8。

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

系统侧每国 800B 记录 (基址 = *(sys+288), 800×国idx 步进; 条目+128 同指) 布局补行 (推定):

| 偏移 (记录) | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +304 | fixed×1e-5 | truck 侧运输记录值 (get_supply_vehicles_temp: 1e5×ceil_fixed(此值)) | 推定 |
| +320 | u32 | train 侧运输记录值 (get_supply_vehicles_temp: 1e5×此值, 仅当 > qword_143331FA0 才写) | 推定 |

#### 4.21.1 CSupplySystem 骨架 (sys = obj+8, vt 0X2973CF0@sys+0)

ctor 0X141218AC0 + Reset 0X1412202B0。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +8 | 匿名结构 (元素待裁) RH 桶数组 | RH 表 #1 | 运行时 | |
| +40 | 匿名结构 (元素待裁) RH 桶数组 | RH 表 #2 | 运行时 | |
| +64 | 匿名结构 | 每国记录宿主子对象 | 内含每国 120B 记录数组 — entry+112 回指后经 +64 访问, 旗 u8@条+112 的 &2/&4 分支 | |
| +232 | 哈希缓存 | 省键哈希缓存 (gs 键→条目; lam 12 供应重算前清条目) | A 包 lam 12 | |
| +256 | 容器 24B | countries | {cap@+264, count@+268, alloc@+272} | |
| +264 | CPdxScopedPtr\<CCountrySupplySystem\>* | 每国供应系统对象数组 (lam 4 重建 PerCountryIndex 的宿主) | A 包 lam 4 | |
| +288 | 匿名结构 (800B)* | 每国 800B 供应记录数组基址 | entry+128 = 此数组 + 800×国idx | |
| +312 | 匿名结构 (216B)* | 每省供应聚合表 = **USAggregatedProvinceSupplyData** (lam 15 聚合计算 / lam 16 逐省重算驱动) | A 包 lam 15/16 | |
| +336 | 自旋锁 (每省) | 省级数据跨国家归并锁 (lam 10: `_InterlockedCompareExchange` + 双列表 append) | A 包 lam 10 | |
| +352 | fixed×1e-5 | 全局供应缩放 | init 100000 (lam 2 重置回写哨兵) | |
| +416 | — | 供应首都相关全局态 | | |
| +424 | — | 供应首都相关全局态 | init −1 | |
| +428 | — | 供应首都相关全局态 | | |

另: +184..+776 区间为容器群 (Reset 互证形态)。

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

#### 4.21.1b DoTradeRoutesUpdate 工人链 (hourly 资源输送路线)

调度 = CGameState::DoTradeRoutesUpdate (sub_1401D9890); 工人链 = 逐脏路线 lambda_2:
F7470→B8AA0→BBB40→F8390→CBC8C0 (工作体: 端点缓存 + 路径校验 + **`(小时+tag_idx)%168` 周度错峰门** — 路线重算按国家错峰分摊, 非每小时全量; 成本阈值分流快检/重算; trade.cpp:242 簇); 路线元组收集器 AFDD0 (24B 条; MSVC tuple 内存序与声明序相反); 粒度选择器 DB390 (pdx_parallel_for.h:65, EJobType 0/1/2/3 → count/NumTaskThreads、3×、1、整段)。
