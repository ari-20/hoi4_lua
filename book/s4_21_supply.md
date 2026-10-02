

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
| +24 | uint64 | 基成员 (=0 init; 名未决) | | 高置信形态 |
| +32 | 匿名结构 (48B 形状) 向量 24B | **_IntermediateTransportUsages** {data@32, cap@+40, count@+44, alloc@+48} — **48B 条** {变体 id u32@0 或 @8, count u32@+4, amount i64 fixed@+32, 变体旗 u8@+40} | 断言 "Unknown variant type in _IntermediateTransportUsages" | 不序列化 |
| +56 | 匿名结构 (NNB 形状) 向量 24B | 运行时 {data@56, cap@+64, count@+68, alloc@+72} (语义未决) | | 形态定案 |
| +80 | 匿名结构 (28B 形状) 向量 24B | 运行时 {data@80, cap@+88, count@+92, alloc@+96}; **28B 条** (pass1 第二环 `基址+28×count` 直算; 高置信) — 语义 = 每国流对齐驱动表: 阶段 10 pass1 第二环遍历本表驱动 css+208 (40B 条) 查找/插入对齐 (sub_1412142C0 查找 + sub_14122ED30 定位插入) | | 高置信 |
| +104 | uint8 | 旗 (多个小 accessor 读; 名未决) | | 存在定案 |
| +112 | CSupplySystem* | **系统回指** (ctor 参 a2) | | 不序列化 |
| +120 | CCountry* | 属主国家 (ctor 参 a3 = `*(gs+784)[i]` 国家数组元素) | | |
| +128 | 匿名结构 (800B)* | **系统侧每国 800B 记录指针** (ctor 参 a4 = `*(sys+288) + 800*国idx`; 消费 +384 计数/+360 数组随机选; **记录内部 +208 表槽** = 消费者 `cmp byte [idx + *(rec+208)]` 逐省查 byte 表, 基址由 UpdateSupply 世界构建调用建立 — 构建期被跳过则基址 null, 崩溃反证) | | 不序列化; +208 槽推定 |
| +136 | 匿名结构 (NNB 形状) RH 桶数组 | **disrupted_supply 表头** {tab@+144=空桶 &unk_143086320, count@+152, mask@+156, maxdist u8@+160, load_factor f32 0.9@+164}; 24B 桶 {dist u8@+4, key 对 u32×2@+8, value fixed@+16}; dtor sub_141219770 | writer 键 19698: 按 key 低字升序发 {350{11{key8,key12}, 776 标记}}; ⚠ army_manpower_need (amn) 不在此 — amn +136 属 state_garrison_data (writer 0X141000700 键 14076, SGD+136 u32); loader case 19698 插入本表 | |
| +168 | 匿名结构 (32B 形状) (RH 表 §3.2) | **节点流缓存表** {tab@+176=空桶 &unk_1430B2C10, count@+184, mask@+188, maxdist@+192, lf 0.9@+196} — **104B 桶全字段定案**: {hash u32@+0 (= k1+13×k0 或 k0+k1), dist u8@+4, key 对 u32×2@+8/+12 = calc 232B 网络条 +4/+8, used_this_tick u8@+16 (命中置 1), node_index i32@+20 (ctor −1; 写 = calc 条 +0), 运行时向量 24B@+24 (count@+36), flow_cache 向量 24B@+48 (16B 条 {省 idx int@0, …}, count@+60), 内层 RH 表对象基@+72 (32B 桶, 条目 +16 dword = 流值槽 idx, 经 sub_140EC8A00 现算; tab@+80, count@+88, mask@+92, extra@+96, lf@+100)} | 五写点 sub_141223990/141220690/141220E00/1412231D0/1412220B0 (皆 find-or-insert sub_14120E510); 重建/清 sub_14122BD90 (&2 全清 / &4 按 flow_cache 条省旗选择性清, lam7 链 141230D40 唯一调用); 读者 sub_141658020 命中返 bkt+72 (断言 country_supply.h:386) | 不序列化; 定案 |
| +200 | uint32 | wanted_supply_trucks | writer 键 19715; writer sub_1424C2F40 (u32 写器) 读 `*(DWORD*)(v3+200)`; lua reader 亦作 ru32; loader 弃读 | |
| +208 | 匿名结构 (40B 形状) 向量 24B | 供应流运行时数组 {data@208, cap@+216, count@+220, alloc@+224} — **40B 条** ("ToGive <= RemainingNeed" 流域) | | 不序列化; 形态定案/推定 |
| +232 | CConvoySubscriber 内嵌 | (+232..+287; vt 0x14295c0f0; 重建 sub_141021F90(+232, country, 32, define)) | 每日重建 0X141230D40 | |
| +272 | uint32 | **train 侧计数** (位于 CConvoySubscriber 内嵌区 +40; get_supply_vehicles_temp train 分支直读) | 推定 | |
| +288 | 匿名结构 (24B 形状) 向量 24B | **每变体火车信息** {data@288, cap@+296, count@+300, alloc@+304} — **24B 条 = pair\<CRef\<CEquipmentVariant\>, STrainInfo\>** (RTTI 0x142A4B168 混合内联缓冲) | | |
| +312 | uint32 | **_TotalTruckInfo._Allocated** | 断言 "_PerVariantTruckInfo.IsEmpty && _TotalTruckInfo._Allocated == 0" 查 `+340==0 && +312==0` | |
| +320 | uint64 | _TotalTrainInfo 对应聚合 (=0 init) | | 推定 |
| +328 | 匿名结构 (24B 形状) 向量 24B | trucks = **_PerVariantTruckInfo** {data@328, cap@+336, count@+340, alloc@+344} — 24B 条 {id 对@0, count u32@+8, damage fixed@+16} | writer 键 19688=truck; 上条断言互证 | |
| +352 | CANT_MOVE_SUPPLY_CAPITAL_* 向量 24B | **supply capital 迁移早退州表** {data@352, cap@+360, count@+364, alloc@+368} — u32 州 id (CanMoveSupplyCapital 命中即返 0, loc CANT_MOVE_SUPPLY_CAPITAL_*; 失都时清 count=0) | | 不序列化; 高置信 |
| +376 | uint32 | **capital** (supply 首都州 id; >0 才写, 键 10315; loader 弃读) | 0X141220400 以之查州属主 | |
| +380 | uint32 | last_supply_capital_move = **距开局天数** (`(gs小时−43800000)/24`) | 键 19722 恒写; loader 弃读 | |
| +384 | fixed×1e-5 | buffer (init = 全局 define qword_143336F08; loader 弃读) | | |
| +392 | 匿名结构 (40B 形状) 向量 24B | **settings** {data@392, cap@+400, count@+404, alloc@+408} — **40B 条** {id 对@0, disabled u8@+8, motorization_level 容器 {data@+16, count@+28} 8B {tag u32, level u8}} | writer 键 11101=settings (内 350 node / 11 id / 240 data / 14065 disabled / 19943 motorization_level) | |
| +416 | fixed×1e-5 | **starting_truck_buffer** (init 1.0; >0 才写; loader 弃读) | 键 19699 | |
| +424 | fixed×1e-5 | **starting_train_buffer** (init 1.0; >0 才写; loader 弃读) | 键 19710 | |
| +432 | 匿名结构 (104B 形状) 向量 24B | **temp_nodes** {data@432, cap@+440, count@+444, alloc@+448} — **104B 条 = homebase inner 同构** {supply@0, start@8, penalty@16, add 串@32, duration@64, province@72, hours@80, decay@88, base u8@96} | writer 键 19706; **loader = sub_14122D280** (元素 104B push 助手 sub_141209280) | |
| +456 | 匿名结构 (NNB 形状) 向量 24B | 节点指针收集表 {data@456, cap@+464, count@+468, alloc@+472} — 8B 指针条; 消费者 = **sub_14122BD20 排水** (逐节点 sub_140ECACF0 打下一轮脏标后清零, 阶段 11 尾) | 由 temp_nodes 匹配重建; 「海港/海运相关(推定)」废 — 排水打脏定案 | 不序列化; 定案 |
| +480 | 匿名结构 (112B 形状) 向量 24B | foreign_homebase_nodes {data@480, cap@+488, count@+492, alloc@+496} — 112B 条 = {裸 key u32@+0 (省 id, 提取件不落叶) + inner 104B 对象@+8} | writer 键 17096 | |
| +504 | 匿名结构 (NNB 形状) 向量 24B | 每日重建即清 {data@504, cap@+512, count@+516, alloc@+520} (语义未决) | | 形态定案 |
| +528 | 匿名结构 (40B 形状) 向量 24B | **每国→省分配条目收集表** {data@528, cap@+536, count@+540, alloc@+544} — 40B 条 {键 u32@0, word@+8, 指针收集向量@+16}; 每全量轮被 sys+360 工作数组按键匹配回填, 分发尾 sub_140EB5210 回填 received/asked ("PerCountryIndex >= 0" 增长) | 语义收窄定案 (原「语义未决」); 回填/分发对 | 高置信 |
| +552 | 匿名结构 (24B 形状) (环形缓冲 §3.4) | **lost_railways** {data@0, cap@+8, count u32@+12, alloc@+16} 30 槽 int64 | writer 键 19876; loader 逐环实载 | |
| +576 | 匿名结构 (24B 形状) (环形缓冲 §3.4) | **lost_trains** (同形) | 键 19877 | |
| +600 | 匿名结构 (24B 形状) (环形缓冲 §3.4) | **lost_trucks_attrition** (同形) | 键 19878 | |
| +624 | 匿名结构 (24B 形状) (环形缓冲 §3.4) | **lost_trucks_killed** (同形) | 键 19879 | |
| +648 | uint32 | **last_lost_train_province** | writer 键 19880; loader 弃读 | |
| +652 | uint32 | daily_losses_index | 键 19875; loader 弃读 | |

0x1412318a0 = CCountrySupplySystem 全块序列化器 (外层 sub_140ED0450 经 vt
0X29A2B08 slot+8 虚调; 尾部 4 环 @552/576/600/624 与 0x288/0x28C 吻合);
css 块键发射序 = [基 141 priority] 19688 → 10315 → 19721 → 19715 → 19722 →
11101 → 19699 → 19710 → 19706 → 17096 → 19698 → 19875 → 19880 → 19876 →
19877 → 19878 → 19879; 19721 = 恒发无值标记键 (语义未名); vt[8] =
sub_14122AB10 = _TotalTruckInfo._Allocated 聚合 getter。

**disrupted_supply 桶** (24B; +136 表):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +4 | uint32 | dist | |
| +8 | uint32×2 | key | id 叶 = key 对原样; 发射序 = node id (key 低 u32@+8) 升序 (实证 CHI 1047→4190→9956) |
| +16 | fixed×1e-5 | value | i64 定点 |

系统侧每国 800B 记录 (基址 = *(sys+288), 800×国idx 步进; 条目+128 同指)
完整布局见 §4.21.2 (旧补行 +304/+320 已并入并升定案)。

#### 4.21.1 CSupplySystem 骨架 (sys = *(gs+984); 副 vt 0X2973CC8@+0, 主 vt 0X2973CF0@+8)

⚠ ctor 141218AC0 / Reset 1412202B0 属 **CSupplyCalculationData** (§4.21.2);
本类 ctor = sub_140EC0610。序列化: writer = 主 vt 槽[2] sub_140ED0450 /
reader = 槽[4] sub_140ECA340; 块 token 11593, 块内容仅 tag 键控每国 css 条目
(CCountry+1156 > 0 门), **sys 级字段全部不序列化**。
pdx 向量统一形 = {data qword@+0, cap dword@+8, count dword@+12,
CPdxAllocator vtable off_143085170@+16}; 九容器实名金源 = 校验和件
sub_140EC5A80 (supply_cache_* 族, supply_system.cpp:325-577)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +0 | — | 副 vtable | RVA 0X2973CC8, 4 槽 (guard nop / 140EC4710 / 140ECA010 / 140ECA130) | 探针定案 |
| +8 | — | 主 vtable | RVA 0X2973CF0, 6 实槽 ([2] writer sub_140ED0450 / [4] reader sub_140ECA340 / [5] TrackKey 恒假桩); 序列化指针 = sys+8 | PE 直读+函数体定案 |
| +16 | 匿名结构 (NNB 形状) 向量 | supply_cache_provinces | {data@16, cap@24, count@28}; 32B/省 (条目表见下) | 定案 (sub_140EC8A00 流值变换读的是本表条 +0 supply_factor) |
| +40 | 匿名结构 (NNB 形状) 向量 | supply_cache_states | {data@40, cap@48, count@52}; 40B/州 | 定案 |
| +64 | 匿名结构 (NNB 形状) 向量 | supply_cache_countries | {data@64, cap@72, count@76}; 120B/国 (旗 u8@条+112 的 &2/&4 = 重建分支门, &1/&8 补全) | 收窄定案 (原「每国记录宿主子对象」) |
| +88 | 匿名结构 (NNB 形状) 向量 | supply_cache_dirty | 脏 id 数组 1, {data@88, cap@96, count@100}; 4B/项 | 定案 |
| +112 | 匿名结构 (NNB 形状) 向量 | supply_cache_dirty | 脏 id 数组 2, count@124 | 定案 |
| +136 | 匿名结构 (NNB 形状) 向量 | supply_cache_dirty | 脏 id 数组 3, count@148 | 定案 |
| +160 | 匿名结构 (NNB 形状) 向量 | supply_cache_dirty | 脏国 tag 数组 1, count@172; 4B tag | 定案 |
| +184 | 匿名结构 (NNB 形状) 向量 | supply_cache_dirty | 脏国 tag 数组 2, count@196 | 定案 |
| +208 | 匿名结构 (NNB 形状) 向量 | supply_cache_dirty | 脏国 tag 数组 3, count@220 | 定案 |
| +232 | 匿名结构 (32B 形状) (RH 表 §3.2) | 省键哈希缓存 | {tab@240, count@248, mask@252, extra u8@256, lf f32@260 = 0.9}; 48B 桶 {hash u32@+0, dist u8@+4, key 省 id u32@+8, value 对象指针 qword@+24 (堆上内层 RH 表, 160B 桶), count u32@+32, …}; 全量重算前清空重建 (sub_140ECD400 体内, 以 sys 为基 — 原「gs+232」误记废); 探针 0.56 = 按 float 读 +256..+259 跨字段误读, +260 才是 lf 0.9 | 裁决定案 (原待裁) |
| +264 | 匿名结构 (NNB 形状) 向量 | CPdxArray\<CPdxScopedPtr\<CCountrySupplySystem\>\> | {data@264, cap@272, count@276, allocvt@280}; 元素 656B, ctor 141218530 (vtable 0X29A2B08, 双 vt +0/+8, 内嵌 CConvoySubscriber@+232, +112/+120/+128 = CSupplySystem*/CCountry*/自家 800B 记录); resize sub_140E95790 按国家数 | 探针+语料定案 |
| +288 | 匿名结构 (NNB 形状) 向量 | CPdxArray\<CSupplyCalculationData\> | {data@288, cap@296, count@300, allocvt@304}; 800B/项 = 每国供应计算记录, ctor 141218AC0 / 每轮重置 1412202B0 (lam 2), 新元素 ctor 调用@1022355 | 探针+语料定案 |
| +312 | 匿名结构 (NNB 形状) 向量 | 省聚合行数组 = **USAggregatedProvinceSupplyData** (216B/省) | {data@312, cap@320, count@324}; init sub_140EBBAA0, count←省数; lam 9 清零 / lam 10 归并 / lam 11 排序 / lam 15 聚合 / lam 16 驱动; 读侧 140C00590 / 141635650 / 14167CBD0 | 定案 (升级为容器形) |
| +336 | 匿名结构 (NNB 形状) 向量 | 省自旋锁数组 | {data@336, cap@344, count@348}; 4B/省, 0=空闲 (lam 10) | 定案 (升级为容器形) |
| +360 | 匿名结构 (NNB 形状) 向量 | 省供应分配工作数组 | {data@360, cap@368, count@372}; 40B/省; 每全量轮 sub_140ECA790 重置 → css+528 每国收集表回填 → sub_140EB5210 分发 received/asked (回填/分发对) | 定案 |
| +384 | uint8 | UpdateSupply 重入门 | =1 时 sub_140ECD400 整轮早退; ctor 置 0 | 定案 |

**supply_cache_provinces 条 (32B/省)**: +0 supply_factor fixed (新省 init 1.0; 流值变换 sub_140EC8A00 读此槽) / +8 railway_health qword / +16 controller_index u16 / +18 capital_country_index u16 / +20 supply_node_level u8 / +21 naval_base_level u8 / +22 non_damaged_infra_level u8 / +23 infra_level u8 / +24 旗位 {bit0 has_temp_node, bit1 has_rail, bit2 province_dirty, bit3 province_dirty_railway} (checksum 逐字段直证)。
**supply_cache_countries 条 (120B/国)**: +8/+40/+64 三 dword 数组 + +88 tag 数组 (均 pdx 向量) + +112 旗位 4 位全入校验和。

#### 4.21.1a UpdateSupply 执行链 (12 阶段; tbb lambda 族; 网络条目 232B)

挂点: HourlyUpdate 计时域 4 → sub_1401C6D30 (gs+984 scoped_ptr 解引用) →
sub_140EC8DB0 (强制第二参 = 1)。真名 = tbb 任务符号直读
**CSupplySystem::UpdateSupply(bool)**; 体内 **15 个 tbb parallel_for**
(lambda_1..lambda_22)。第二参 = **小时步进模式旗 (定案)**: 1 = 每小时错峰模式
(调拨按整点过滤、国家每日重算按时隙); 0 = 全量立即模式 (全收、跳过错峰、
哈希清理扩容) — 全 dump 仅 3 处 a2=0 调用 (读档/初始化路径)。

12 阶段 (粗粒度; ss = CSupplySystem 对象 = gs+984 解引用, 布局 §4.21.1):

| 阶段 | 动作 | 并行 |
|---|---|---|
| 0 | 脏检: 每国 120B 记录@ss+64 (+112 旗), 比对 owned_states 变化与补给系数宏缓存 (cc+1464 键 567, fixed×1e-5); 脏国逐个 **sub_140ECC220** 刷新 120B 记录 (+112 bit0 = country+1156>0 / +32 = clamp(系数宏+100000, ≥10000 — **钳位下限待 PE 验算**) / 首都州变则省 32B 行 +18 双向维护 / 尾 sub_140EB3D80 刷 owned_states 列表) | lambda_1 |
| 1 | 打脏: 记录旗 \|= 2, tag 入脏国列表 {ss+160} | 串行 |
| 2 | 三条 id 列表刷新 (ss+88/112/136 → sub_140ECC340/sub_140ECC820) + 逐脏国补给状态重算 | 串行 |
| 3 | 补给节点全局遍历 (token 1812); 取 `小时 = now % 24` 为全程错峰相位 | 串行/并行双路 |
| 4 | CSupplyCalculationData (**800B/国**, ss+288) 更新 | lambda_2 |
| 5 | 国家 id 恒等排列上 8 连 pass: 依赖列表构建 (120B 记录 +88/+100 → calcdata+232)/字节标志压缩剔除 id | lambda_3/4/6/7/8 |
| 6 | 每省 **216B 记录**扩容 (省界 = gs+700) + 4B/省数组 + 省级 pass | lambda_11 |
| 7 | 护航/运输队按整点收集 (232B 元素, +4 时刻 `%24==当前小时`; a2=0 全收 + ss+232 哈希清理扩容) | 串行 |
| 8 | **国家每日重算错峰: `id % 24 == 当前小时` 才执行** (sub_14122E520 清累计 + 30 槽日环 国对象+552..+624 清新槽) — 每日补给重算摊平到 24 小时的削峰机制 | lambda_16 |
| 9 | 分发结算: **省满足率 = 省记录 rec[1]/rec[0]** (clamp ≤100000); 流入写 calcdata+184 区 40B 条目 {来源/快照/数量}; **库存扣减 calcdata+64**; 回填机械 = 脏国逐个遍历 css+528 条目: **sub_140EB3BE0** (sys+360 40B 行 find-or-push, 1.5× rotate 插入) + **sub_140EB5080** (条目内嵌收集向量按键归并 append); 配套扩容/清理 = sub_140ECA830 (sys+312 行数组 1.5×) / sub_140ECAA40 (sys+336 锁数组新尾清零) / sub_140EC8790 (216B 行两内嵌向量扩容前清空) / sub_140EC8710 (内层 160B 桶两内嵌向量元素级清空) | 串行 + lambda_19 |
| 10 | 每国三连 pass (全名 = sub_14122B820 → **sub_14122B300 → sub_14121C700 → sub_14122F110**; 书缩写 C700 实为 sub_14121C700, dump 无 sub_14122C700) + 观察者钩子 = **sub_1415AE8C0** (sys+112/208/160 三脏表并集 → 逐脏 tag 逐 id 从单例 +88→+23776 观察者缓存 RH 24B 桶 backward-shift 删除) — 三 pass 细节见下表 | 混合 |
| 11 | 最终并行结算 + **打下一轮脏标** (sub_140ECACF0: 省 32B 记录旗 \|= 4 入 ss+88, 国记录旗 \|= 4 入 ss+184); 尾部 **sub_140EC8350** 消费后清旗: 省 32B 行 +24 清 bit2/bit3 / 州 40B 行 +36 清 bit0 / 国 120B 记录 +112 清 bit2/bit4/bit8, 六脏列表计数全清零; css+456 排水 = sub_14122BD20 (逐节点 ECACF0 打脏后清零) | lambda_21/22 |

阶段 10 三连 pass (逐 css 串行, 定案):

| pass | 函数 | 语义 |
|---|---|---|
| 前 | sub_14122B820 | calc+320 train 侧运输记录累加 (§4.21.2 +320 行写者) |
| 1 | sub_14122B300 | css+56 订阅者 (16B 条 {对象指针@0, 旗@+8}, count@+68) 旗置位对象: vt[槽9] 刷新 + sub_141021F90 重建 CConvoySubscriber + vt[槽10] 错峰 tick (旗或 对象+12 %24==当前小时); vt[槽15] +108 旗非零 → 对象注册进属主 calc+184 网络条目 (232B×type) **内嵌容器@条+184** (Form P {data@+184, cap@+192, count@+196, alloc@+200}, **48B 条**: 未命中 push {tag@0, 16B 零@+8, {0,100000}@+24, 0@+40}, 条+16 = 订阅者对象指针); 旗零对象 `*(对象+288)=0` 复位; 第二环 = css+80 (28B 条) 驱动 css+208 (40B 条) 对齐 |
| 2 | sub_14121C700 | 卡车分配结算: css+416/+424 起始缓冲 >0 → sub_14122F5F0/sub_14122F2F0 按消费者 asked 总量分摊; css+200 < css+312 缺口 → 遍历 css+328 变体条 (24B) 逐变体取 min(缺口, 条+8) 提 country+3944 装备池 (sub_14100CCE0); 尾段 calc+304 归整到 100000 倍数 (**取整方向待 PE 验算**), 差额逐变体落 **calc+388 累计 += 量 / calc+392[i] = 量** |
| 3 | sub_14122F110 | 读 calc+128 (800B calc) 遍历 calc+536 距离暂存 (24B 条, count@+548): **consumer+30 = 1 到达旗 / consumer+56 = min(距离)** (哨兵 100000, fixed 定点) — CSupplyConsumer 新字段两枚 |

tbb lambda 族 (细粒度)。网络条目 (232B) 字段: +56 = `Node._TotalSupply` / +64 = `Node._RemainingSupply` (country_supply.cpp:1388 族断言串自证字段名)。

| lambda | 链 | 语义 |
|---|---|---|
| lam 1_5 | EB9CD0→EC80C0 | **逐国脏检谓词** (CANT_MOVE_SUPPLY_CAPITAL_* 全部位于 CanMoveSupplyCapital 族, EB9CD0 = 纯 tbb 分裂器无业务串): 四项失配任一 → 返 1 需重算 = has-css 旗 / 系数宏 (cc+1464 键 567) / owned_states / 首都州; 结果写布尔表 (L5917617 实证) |
| lam 2 | EBB3D0→1412202B0 | CSupplyCalculationData 逐项重置 (30+ 字段清零, +352=100000 哨兵) |
| lam 3 | EBA9C0→1412212C0 | 供应消费者记录重建, 注册序 = 逐军(army+16) → 逐舰队逐 TF(**tf+16**, country_supply.cpp:2179) → 铁路炮(gun+16, :2189) → 国家空军容器(容器+0, :2225/:2234) → cc+4008 项目消费者(元素+200); :2268 断言属共享注册函数 sub_14121B650 (先 sub_141230CA0 复位, sys+432 += asked, 插 sys+440 数组 + sys+64 键表); **CNavalBase 无 CSupplyConsumer (负定案)** — 基地是节点非消费者; 消费者类别字节 = ctor 0X140C482A0 a2 (2=空军基地容器 / 4=项目消费者) |
| lam 4 | — | PerCountryIndex 重建 (:3138) |
| lam 7 | EBAE10→141230D40 | 供应节点七步重算 (convoys.cpp:29 + 首都控制权门 :2844) |
| lam 9 | sub_140EB55F0 | sys+312 行清零 (槽 0/+8/+20/+36/+60) + +16 填国 idx (⚠ +16 双语义待裁: calc 侧同型 216B 记录 +16 记「同州链 next」, 需实测区分勿直改) |
| lam 10 | sub_140EB5C00 | 省级数据跨国家归并 (省自旋锁 +336): 逐国把 calc+88 216B 记录归并进 sys+312 全局行 |
| lam 11 排序叶 | sub_140EC3FB0 | 行 216B 内嵌两向量排序 (+24 24B 条 / +48 16B 条; 栈≤32/堆 scratch) |
| lam 12 | sub_140EB57D0 | 脏省逐个 sys+232 find-or-insert 后发布桶值并清内层表 (写者核心 = sub_140EB4B30: 48B 外桶 {hash@0, dist@4, key@8, 值@16..47}, 键命中返回否则 40B 值块整体移入; lf 门 (count+1)/buckets > lf@+28 → rehash **sub_140ECA5A0** (2^1..30 门, pdx_robin_hood_table.h:579); **lf 比较门方向待 PE 验算**) |
| lam 13 | — | hub 条目摩托化贡献累加 (supply_node_settings.h:33) |
| lam 14 | EBD720→ED0F90→14121EA10 | 供应节点非本地链接处理 (:2919) — 采样最热体; 其下两级书未录链 = **sub_141210470** (1,001 行: heap 驱动 + calc+184 网络条 232B/条 +128 门遍历) |
| lam 15 | sub_140EB5A30 | 行+48 列表逐项 sub_14194CDF0 单节点聚合 → 行+8 累加 / 行+20 正值计数 |
| lam 21 | EB9FB0→141225420 | 供应流量分发: 沿 From/To 节点路径扣减推送 (`_TotalSupply(+56) >= _RemainingSupply(+64)`, 防死循环 AvoidInfLoopCounter<100) |
| lam 22 | — | 海口省 SeaProv>0 维护 + mod-24 轮转门 |

⚠ ECD400 体内 15 处 start_for 的**文本线序 ≠ 执行序** (lam 9/10/12/15 走旁路启动包装/直调变体)。

海军可达性 (CNavalAccessibilityManager::Update): 逐国过 `country+1156>0` 门 → 64B/国槽位 (边图描述符 + 双标号数组) → 两次字节并查集泛洪 (1419EE6A0), 边放行 = 邻接规则权限位 &2/&4 (141546CC0/C90 → 141547440 adjacency_check); operator() 无独立实体, 内联于串行叶 140E24BE0。邻接规则进入供应热路径**仅此一条通道**; 141038A50/141966FE0/1419EB1F0 三上游均属部队移动侧, 不在供应段。**槽位唯一重建路径 = hourly 相位 8 的 0xE255E0** (全语料唯一调用点; 调用方临时置管理器 +32=1 → 调用 → 返回后无条件复位, 非派发体内部; +32 置位才尾跳 140E24860 PdxParallelForContainer CPdxSpan\<const CCountry\*\> 派发, 真名 Update 见任务符号) —— 读档/新开局后槽位新鲜度依赖首个小时内 tick, 无独立载入重建路径。**detour 接缝定案**: 0xE255E0 序言 offset 11 = `je rel8` (+32 旗判定分支), stolen-bytes 不可搬移 (hk_probe "prologue contains relative control flow"); 可安装接缝 = **0xE24860** 派发体 (序言纯 mov/push/sub, stolen=18; 全语料唯一调用者 = 0xE255E0, 吞它等价吞整拍重建)。hourlyUpdateUnits (sub_140717BC0) = 全单位 vt[18] 小时 tick 逐国串行驱动 (师/舰队快照/铁路炮三容器, 定案见 §4.2.6 相位 10) — 军队数与 army+840 装备占用条件日志 (country.cpp:13281/13314) 只是调试门 byte_143452529 包裹的附属统计, 非本体职能。

#### 4.21.1a-2 补给网络岛屿分区 (sub_141227400)

1,032 行 (country_supply.cpp:4003/:4040 断言直证): 补给网络**岛屿分区归属 + 海军基地连接**
计算步 (IslandIdsForRegions 族)。

#### 4.21.1a-3 铁路/河流路径回溯步 (sub_141A0CB10)

1,296 行, Dijkstra 变体: `PathTable[省]._RailParentProvince/_RiverParentProvince` 父指针表 +
二叉堆回溯。上游 = UpdateSupply lam 12 (sub_140EB57D0) 经 sub_141A0E240 调入; 与 §4.21.2
空/补 Dijkstra 缓存及 supply_cache_provinces +8 railway_health 互链。

#### 4.21.1b DoTradeRoutesUpdate 工人链 (hourly 资源输送路线)

调度 = CGameState::DoTradeRoutesUpdate (sub_1401D9890); 工人链 = 逐脏路线 lambda_2:
F7470→B8AA0→BBB40→F8390→CBC8C0 (工作体: 端点缓存 + 路径校验 + **`(小时+tag_idx)%168` 周度错峰门** — 路线重算按国家错峰分摊, 非每小时全量; trade.cpp:242 簇); 路线元组收集器 AFDD0 (24B 条; MSVC tuple 内存序与声明序相反); 粒度选择器 DB390 (pdx_parallel_for.h:65, EJobType 0/1/2/3 → count/NumTaskThreads、3×、1、整段)。

CBC8C0 阈值分流 (定案): `v35 = BASE_LAND_TRADE_RANGE² × ln(两国持有州数和+2)` vs 1409D3740 (环绕修正的州锚点距离²) — 通过走快检 CAA7990, 否则全量重算 CA90F0。ln = 定点整数 ln (sub_1424EF9D0: 100000·ln(x/100000), 1/e 缩减循环 + Σzⁿ/n 级数); 国家+1132 = 持有州计数 (+1120 州指针数组)。海路节点对可用性 = trade.cpp 四值枚举 (CAA1B0): 3=完全通过 / 1=条件通过 (边缘准入) / 2=结构性失败 / 0=显式阻断; 消费侧 {1,3}=通 {0,2}=断。

运行语义 (defines 收口): 重算预算 = `NGame.TRADE_ROUTE_RECALCULATE_FREQUENCY_DAYS` (vanilla 45, 0=不周期重算; 每日预算 = max(1, 有效路线数/45)), 轮转游标 = gs+2496 `next_trade_route_update_country_idx` (模 gs+796 国家数置脏), 有效路线计数 = gs+2492 `cached_active_trade_route_count` (token 10102), gs+2488 = 每小时元组收集数 (纯运行时)。护航危险评分 = CStrategicNavy 逐战略海区 0-4 级加权归一 (权重 = defines `NNavy.NAVAL_CONVOY_DANGER_RATIOS` vanilla 0.10/0.10/0.10/0.15/0.15, ×1e5 装载; 孪生件 EB06F0 = 水雷危险版)。

贸易管理器刷新域 (定案): 容器 = +1832/+1844 贸易数组、+1856/+1868 交换条目、+1880/+1892 lend_lease 向量 (键 12618 — CLendLeaseExchange 896B 元, 布局 §4.3.25)、+2000 脏字节; 巡检 sub_140CBBCD0 (失效即终止 + TRADES_MODIFIED 广播) + 重评 sub_140CBA010 + 全国家刷新 sub_140CBA910 (三者宿主 = F07470 资源并行 harness, 全名 ApplyFunctionToCountryResources<...CCountryResources>); 最大可出口量 sub_140CAD5A0 (a1 = CCountryResources@cc+4600; 四理由 TRADE_MAX_EXPORT_DETAILS_*); 路线继续有效性谓词 sub_140D1C700 (+760/+76/+77 旗全零 + +744 对象存活 + 双 tag 在册; 两窗采样最热点 103 样本)。

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
| sub_140C00590(unit, prov, threshold)→bool | 移动域供应阈值判定 (unit.cpp:3150; 唯一调用者 1414D9280 unitcontroller 移动校验); 读 +312 行 +48 列表 (16B/项={节点idx,国idx,权重}) 与网络条目 +56/+64 现算, 另裸读 unit+64 作阈值比较; 拒动落 unit+590=1 / unit+680=3; **门仅对 AI 单位生效** (sub_1406FFDB0 = 人控国判定 sub_1401E2460 ∨ human_ai 旗 byte_14332F639 → 旁路); 门阈值 = qword_143339518[orders group(unit+192)+420, 无组=1] | 断言+调用簇 定案 |
| sub_140F392D0 | 供应地图模式上色 (直读发布器): 逐省取省 +272 陆军单位数组 (+284 计数, 元素为指针, 取单位 +64) 均值 (100000 满值, 空数组视满分); 均值 ≥ SUPPLY_STATUS_DISPLAY_THRESHOLD (全局 float dword_143334128) → reach 档 = clamp(发布器逐省值 ÷ BEST_FLOW_DISPLAY (全局 float dword_143333FD8) × 28, 0..28), 否则 status 档 29..31; 整段被发布器 +68 (dword_1430B3C54) 就绪门门控 | 直读 高置信 |
| sub_14121F1D0 | 后勤满足度计算, 全 1e5 整数 int64: t = calc+320 (1e5×t ≤ qword_143331FA0 = MIN_TRAIN_REQUIREMENT → t=0), 火车比 = t==0 ? 100000 : clamp(1e10×css+272 ÷ (1e5×t)); 流量比 = css+208 计数==0 或 Σ+44==0 ? 100000 : 1e5×Σ+40÷Σ+44 (+32 子对象); **输出 = calc+312 × 火车比 × 流量比 ÷ 1e10, 经出参 \*a2 传递 (rax 只回传指针)**; 满比时输出即 calc+312 (逐国探针对拍); 零数据语义 = 两比自动满分不折减 → 供给冻结态面值唯一缺口 = calc+312 停 0 (§4.21.2 +312 行)；⚠ 面值填充**不可**走 detour 写 \*a2 — 出参是调用方栈上 BYREF 缓冲, 桥写域门拒写当前线程栈, 该写必然失败 (实测每次调用一条拒绝: 桥日志 15.9 万行 + 审计 22.6 万条, 而面值不变) → 唯一可行通道 = 钉 calc+312 (calc+312 = 1e5 时逐国输出即 1e5, 实机对拍) | 直读+探针 定案 |
| sub_1418A33A0 | **顶栏面值唯一写者** (唯一调用点 = CTopBar @48[7] sub_14189D510 逐帧 tick, 全量重算): 玩家 tag = BB48F0(gs + (gs+1312>0 ? 1312 : 1316), 观察模式走 1316) → css 1406EE6E0 → v23 = sub_14121F1D0 **出参** (唯一来源); 色 = v23==100000 ? 'W' : 'R'; 数字+% = sub_14226E4D0 字面装配 (控制字节 0x11 = §, 数值经寄存器进格式化器 — 反编译器丢参, 与稳定度块同型佐证) → SetText(*(a1+232) supply_value); 比例条 = round(v23/1000) 经 CIcon vt[+752]/[+152] 写 *(a1+240) supply_ratio_bar; topbar.gui 该件 = 静态占位 "999d" 无 loc 绑定, Repopulate/Reload 均不写 +232/+240 → 无第二写者。⚠ 旧「强制 v23=100000 面板不变」实测矛盾裁定 = 强制的是 rax 返回值而值经 \*a2 出参传递 (契约错位, 高置信) — 非「另有写入者」 | 直读+唯一调用点 定案 |
| sub_1414323B0 | **情报账页模糊区间** (非面值管线 — 全语料 E8 仅 2 调用者, 均为情报账页: sub_141EBB920 填 INTEL_LEDGER_SUPPLY_TOOLTIP $RANGE$ = "X - Y"/无情报 "NO_INTEL", sub_141EC19D0 账页行族刷新 → SetText +1476..+1508; 均不触顶栏): v23 = sub_14121F1D0 → sub_14142EB50 = countryintelhelper.cpp 模糊化区间估计器 (输出 (min,max) 两百分数 <<15 定点; 幅度随情报进度衰减至 0, 噪声 = 按 (id, 年偏移, 值, 游戏态种子) 确定性双路哈希; 常数实参 1692 = 噪声哈希种子, 函数内不查任何表); v15 = 观察方对目标国民用情报等级 ÷ NIntel.INTEL_COUNTRY_LEVEL_MAXIMUMS[0] (数据数组 = qword_1433390B8, 4×qword, 断言 countryintel.cpp:302, 缺项填 100000); FoW 总旗 byte_14332F63A 关 → 全部精确; define 定名 (注册调用直证): qword_1433315B0 = NIntel.CIVILIAN_SUPPLY_RANGE_INTEL_MIN (vanilla 0.1, 低于显 ??) / qword_143331668 = NIntel.CIVILIAN_SUPPLY_RANGE_INTEL_MAX (0.5, 不低于显精确值) / qword_143331708 = NIntel.CIVILIAN_SUPPLY_INTEL_RANGE_AT_LOWEST_INTEL (0.5, 最低情报扰动幅度) | 直读 定案 |
| 顶栏视图 | 类 = **CTopBar** (RTTI); 虚表 0x142a11290/b8/d0; vt[15] = sub_14189D510 (调 sub_1418A33A0 刷新 supply 元件); 元件: +232 = supply_value (CInstantTextBox), +240 = supply_ratio_bar (CIcon), +39088 = logistics_button | RTTI+实机扫描 定案 |
| sub_141633810 | 顶栏后勤 tooltip (LOGISTICS_CAPACITY[_DETAILED_DESC] 键): 火车/卡车/运输船行 = 持久通道比值 (css+272/calc+320 等); ⚠ 与面值分属两套来源 — css+208 流量累积为每次重算清空的临时量, 供给系统冻结时面值塌 0 而本 tooltip 行仍满 | 直读 定案 |
| sub_141635650 / sub_141636C20 / sub_14162FB40 | 供应地图 tooltip 族 (SUPPLY_CAP_AVAILABLE / SUPPLYMODE_TOOLTIP_ENEMY_DISRUPTION / CONSUMER_SUPPLY_TOOLTIP; 直读 +312 216B 行与 232B 条目) | 本地化键 定案 |
| sub_14167CBD0 (+ 入口 14167C560) | 逐省供应状态数组构建 → UI 侧缓存 {data@a1+56, cap@+64, count@+68}; 门细节 (定案): 发布器 +80 = stale 旗 (关门置 1 仍走 sub_14167C730 刷旧缓存); 门开且州数 %3==0 时使能 mapmode 3/4 重绘 | 定案 |
| sub_1402B95E0(gs, json) | "province_supplies" JSON 导出: 每省 = clamp(100×max(流值),0,100) | 定案 |
| sub_1403EE990 / sub_14042C7D0 | CNumOfSupplyNodesTrigger::GetValue/GetDesc → `*(u32*)(*(css+128)+428)` | 名表+断言 定案 |
| sub_140EC5A80(sys) | supply_cache_{provinces,states,countries,dirty,node_flows,...} 校验和/dump | 字符串簇 定案 |

消费可见值落点 (定案): **每国 CSupplyCalculationData +184 网络 232B 条目的 +56
`_TotalSupply` / +64 `_RemainingSupply`, 与 sys+312 省聚合行两处**; GUI/单位域查询
时刻按 14194CDF0 现算, 无持久化汇总字段。唯一被读侧消费的每小时引擎缓存 =
CCountrySupplySystem+168 节点流缓存 (写者 = lam 7/lam 8); css+208 供应流数组无
独立外部读者 (写侧内部消费); css+136 disrupted_supply 独立查询函数未定位,
读取推定内联于 141636C20 — 待裁。
UI 渲染链: UpdateSupply 尾调 14167C560 (唯一调用点) → 全局发布器 unk_1430B3C10
{data@+56 = 槽 qword_1430B3C48, cap@+64, count@+68 = 槽 dword_1430B3C54 = 就绪门}
(唯一写者 = UpdateSupply) → map mode 上色 140F392D0 (直读 +56 槽逐省数组,
不直读 +312)。发布器重建带状态门 (全局 qword_14333CFB8 对象首 dword == 5 或
app 管理器 vt[23] 链谓词, 实测静置态双闭 — 非每拍必跑)。单位侧有效补给比收口
= sub_140C87EC0 (见 §4.18)。

#### 4.21.1d 调用面与消费者补给比写侧

**入口面** (全 .text E8/E9 扫描, 无函数指针表间接引用):

| 入口 | a2 | 形态 | 上游 |
|---|---|---|---|
| sub_140EC8DB0 | 1 | 包装体强制 a2=1 后尾跳进入本体 | sub_1401DF400 / sub_141B6E9D0 |
| sub_140ECA270 | 0 | 直调 2 次 (读档重建) | sub_1401DA490 / sub_140DD6A30 |
| sub_140DD9B20 | 0 | 直调 (载入完成) | sub_140DDC350 |
| sub_140ED02C0 | 0 | 虚调门条件包装后尾跳进入本体 | 命令/UI 链 8 处 |

a2 语义 (本体以 `v423 = a2` 捕获): 1 = 每小时增量档, 更新面受
`!v423 || 节点 id%24 == 槽` 门控 (id%24 子集更新); 0 = 全量档。
尾跳与直调落点同为函数首字节。

读档链: sub_1401C8A60 → sub_1401EA1B0 → sub_1401D0E30 → sub_1401EC950
(malloc 392B + ctor sub_140EC0610, 结果写 gs+984 (`a1[123]`) 整体替换 sys)
→ sub_140ECAF00 (按国家数分配并清零 calc+288 / 216B 行+312 / 锁+336)。

**消费者补给比写侧** (CSupplyConsumer+48 = 宿主 +64 或 +48): lam 3 消费者重建
逐消费者清零 (流亡 sub_1412212C0) → lam 7 节点重算链 sub_141230D40 →
sub_14121EF20 → sub_1412229D0 → sub_14121A790 / sub_141215BC0 → 尾段
sub_140EB5210 / sub_14122AA00 / sub_141224480 回填 received/asked → 比值落点
sub_141A0AFB0 / sub_141A0ACF0 (+48 = 100000×_ReceivedSupply/_AskedSupply,
asked=0 → 100000); 复位写点 sub_141230CA0 (写 0, 唯一调用点 sub_14121B650)。
CSupplyConsumer 另两字段 (阶段 10 pass3 sub_14122F110 写, 定案):
**+30 = 到达旗 (1 = 本轮已供应)** / **+56 = 最近供应节点距离** (fixed 定点,
哨兵 100000, 取 min 更新)。

| 宿主 | 消费者基对象 | 补给比落点 |
|---|---|---|
| CArmy / CTaskForce / CRailwayGun | 宿主+16 内嵌 | 宿主+64 |
| CCountryAirContainer / 项目消费者 | 宿主+0 | 宿主+48 |

> ⚠ 读档时 sys 对象整体替换 (旧对象弃用), 外部缓存的 css 指针须重取。

#### 4.21.2 CSupplyCalculationData (每国 800B 供应计算记录, 纯结构无虚表)

ctor 141218AC0 / dtor 140EC1290 / 每轮重置 1412202B0 (lam 2) / move 140EBFEE0 /
扩容 140ECAF00 (按国家数, sys+288 数组); CCountrySupplySystem+128 同指自家记录;
不序列化 (仅 checksum 件 sub_140EC5A80 抽查 +184/+440 两表)。
容器两形: 向量 (带 alloc 变体, §3.1) = {data 指针@+0, cap uint32@+8, count uint32@+12, alloc 指针@+16};
RH 表对象 (§3.2) = 匿名结构 (32B 形状) {占位 uint64@+0 (不初始化), tab@+8, count@+16, mask@+20, extra uint8@+24, lf float@+28 = 0.9}。
重置语义: 清累计/各向量 count、+424 = −1、+416 = 0、+352 = 100000、
两哈希表**惰性清** (扫桶清 dist/flag 并 --count — 旧「条目压实移除」系此误读)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | 匿名结构 (32B 形状) (RH 表 §3.2) | **省→供应值缓存** (空补 Dijkstra 终值 qword@桶+16; 未算标记 100000, 不可达 92233720200000); 桶 24B {hash, dist@+4, key 省 id@+8, value@+16}; 写 sub_140325D20 (空补定稿回填) / 读 sub_14121E1B0 命中直返 | 定案 |
| +28 | float | +8 表装载因子 lf = 0.9 | 定案 |
| +32 | 匿名结构 (32B 形状) (RH 表 §3.2) | **省→距离+1 缓存** (空补 Dijkstra); 桶 12B {flag u8, key 省 id u32@+4, value u32@+8}; 插入器 sub_1401B04A0 (对象基 calc+32) | 定案 |
| +64 | 匿名结构 (120B 形状) | **省/州/区聚合工作集**: 相对 +64: vec@0 = int×省数 (省→216B 记录 idx, init −1); vec@24 = **216B 聚合记录表** (USAggregatedProvinceSupplyData 同型: +0 word 省 id / +8 Σ(asked−received) / +16 同州链 next / +24 每消费者 24B 向量 {16B ref id, dword tag} / +48 16B 列表 {节点idx,国idx,权重} / +152 节点值); vec@48 int 数组; vec@72 (=calc+136) = int×州数 (州→已有节点 idx, 建重复节点门); vec@96 (=calc+160) = int×区数 (init −1); ctor 1414DFE80 / 清 1414E1860 / find-or-create sub_1414E0460 | 升级定案 (原「语义推定」) |
| +184 | 匿名结构 (232B 形状) 向量 | **供应节点表**: +0 dword 节点 idx / +4 word 省 id / +8 dword type (0=州陆地 / 1=空补 / 2=建 (SupplyLevel 门) / 3=跨国非本地链接 / 3·5=海补) / +12 旗 byte / +56 `_TotalSupply` / +64 `_RemainingSupply` / +128 属主 tag / +152 节点值 / **+184 内嵌 Form P (48B 条订阅者挂接列表, count@+196; 阶段 10 pass1 sub_14122B300 写条+16 = 订阅者指针; 未命中 push {tag@0, 16B 零@+8, {0,100000}@+24, 0@+40})** / **+208 内嵌 Form P (40B 使用记录, count@+220)**; 建 type0 sub_1412229D0 / type1 sub_141222570 / type2 sub_141220690·141220E00 / type3 EA10 | 定案 (type 枚举本轮闭合; +184 订阅者列表新补) |
| +192 | uint32 | vec184 cap | 定案 |
| +196 | uint32 | vec184 count = **节点数** (EA10 读作新节点 idx) | 定案 |
| +200 | uint64 | vec184 alloc | 定案 |
| +208 | 向量 24B (元素未名) | **休眠残槽 (负定案)**: 生命周期四件 (ctor 141218AC0 向量初始化 / reset 1412202B0 仅清 count@220 / move 140EBFEE0 / dtor) 之外, 全 supply 域字面量与指针算术两形扫描均无推入/读取点 → 1.19.3 恒空。⚠ 同号异体: css+208 = CNavalBaseConvoyClient 挂接表, 节点条目内嵌 +208 = 每接收方发放台账, 勿混 | 定案 (负向; 语义待裁闭合) |
| +232 | uint32 向量 | 本 tick 涉及的外国 tag 集 (从 sys+64 国家缓存条 +88 复制; 写 sub_14121DEA0 / 读 sub_14122C090 逐 tag→国 idx→该国 calc+440) | 定案 |
| +256 | 匿名结构 (40B 形状) 向量 | **消费者供给发放账单** {CSupplyConsumer*@0, qword@8, qword@16, qword@24, dword 键@32}; 排水 = UpdateSupply 尾段 sub_14122AA00 逐条 CSupplyConsumer::AddReceivedSupply (sub_141A0ACF0; supply_consumer.cpp:167/181 断言); **写者负定案 (休眠)**: 全域无推入点, 排水在而账本恒空 (原「单位指针@0」系首参误记 — 首参 = 消费者对象) | 形定案 / 写者定案 (负向) |
| +280 | 匿名结构 (16B 形状) 向量 | **跨国非本地链接源** {省 id@0, ?@4, 省/参数@8, 值@12}: EA10 逐他国记录读此表 → 本国 +184 插 type3 + +704 登记; **写者负定案 (休眠)**: 节点创建族与全域无推入点 → type3/+704 链路原版不可达 (高置信推论) | 读侧定案 / 写者定案 (负向) |
| +304 | fixed×1e-5 | truck 侧运输记录值 (消费者 = css 摩托化 wanted_trucks 换算三处) | 定案 |
| +312 | uint32 | **顶栏后勤面值唯一基数** (公式 = 本值 × 火车比 × 流量比 ÷ 1e10; 详见 §4.21.1c sub_14121F1D0 行) | 定案维持 |
| +320 | uint32 | train 侧运输记录值 (_IntermediateTransportUsages type0 条累加; 写 sub_14122B820) | 定案维持 |
| +324 | uint32 | **空补节点计数** (首都迁移启发式 <2/<4 门) | 定案 |
| +328 | uint32 向量 | **供应首都迁移候选省 id 列表** (剪枝 css+352 早退表) | 高置信 |
| +340 | uint32 | vec328 count | 定案 |
| +352 | u32 (qword 写) | **火车满足率** = min(100000, 100000×(100000×+384)÷(100000×+320)); 总量 0 或 ≤ MIN_TRAIN_REQUIREMENT → 100000; 唯一写者 sub_14122B820; **面值公式不消费它** (消费者在火车分配侧) | 定案 (原「效率/比例因子」落位) |
| +360 | uint32 向量 | 火车按变体分配结果 int×N (N = css+300 数) | 定案 |
| +384 | uint32 | **火车分配量累计** (consumer+760 因子进入每变体结果) | 定案 |
| +388 | uint32 | **卡车分配量累计** (写 = 阶段 10 pass2 sub_14121C700 尾段) | 定案 |
| +392 | uint32 向量 | 卡车按候选省分配结果 int×N (写 = sub_14121C700 尾段, 按 css+340 变体数扩容) | 定案 |
| +416 | uint64 | **CProvince\* 供应首都省指针** (写 sub_14121EF20; 控制权不符整国跳过) | 定案 |
| +424 | int32 | **供应首都节点 idx** (−1 哨兵; 铁路 tooltip sub_1416583F0 取首都节点 _TotalSupply) | 定案 |
| +428 | uint32 | 供应节点计数 (触发器 num_of_supply_nodes 读) | 定案 |
| +432 | uint64 | **Σ asked_supply 累计** (消费者注册时累加) | 定案 |
| +440 | 匿名结构 (16B 形状) 向量 | **消费者表 supply_cache_consumers** {CReferenceObject id 对@0, CSupplyConsumer\*@8}; 注册者 sub_14121B650 (vec776 排水), checksum 直证 | 定案 |
| +452 | uint32 | vec440 count | 定案 |
| +464 | 匿名结构 (40B 形状) 向量 | **每变体中间运输使用记录** (convoy tag 键, 断言 :1708; +32 qword 量累加; count 每轮重建) | 定案 |
| +476 | uint32 | vec464 count | 定案 |
| +488 | 匿名结构 (16B 形状) 向量 | **省→距离评估输出** {省 id@0, 距离 qword@8} (排序后落盘) | 定案 |
| +500 | uint32 | vec488 count | 定案 |
| +512 | 匿名结构 (24B 形状) 向量 | **每国节点需求清单** {state id@0, ?@4, 省 id@8, 容量基数 qword@16} (lam4 从 sys+40 PerCountryIndex 展开, 断言 :3138) | 定案 |
| +524 | uint32 | vec512 count | 定案 |
| +536 | 匿名结构 (24B 形状) 向量 | **消费者距离暂存** {16B ref id, qword 距离} (+440 × +232 二重循环) | 定案 |
| +548 | uint32 | vec536 count | 定案 |
| +560 | uint16 向量/省 | **省→海区/岛链 id** (ctor 0xFFFF; 海补洪泛赋值) | 定案 |
| +584 | uint16 向量/省 | **省→第二海补分组 id** (每轮重填 −1 再赋值) | 高置信 |
| +608 | uint16 向量 | **岛链并查集 parent 表** (合并 + 路径压缩) | 定案 |
| +632 | uint32 向量 | **海口省 id 列表** (海补轮重建) | 定案 |
| +656 | 匿名结构 (8B 形状) 向量 | **(state, node idx) 有序对表** (FindNodeIndex case0; 每轮 sub_1412229D0 尾排序重建 — 键收窄为 state) | 定案 |
| +680 | 匿名结构 (32B 形状) 向量 | **state→空补节点 idx 列表** {state id@0, 内嵌 24B 向量@8}; 读者 1414E3980 求和的是**节点**条 +64 | 定案 |
| +704 | 匿名结构 (8B 形状) 向量 | **_NonLocalNodes** {(省 id, 节点 idx)}; 断言 country_supply.cpp:2919 | 定案 |
| +728 | 匿名结构 (8B 形状) 向量 | (省 id, 节点 idx) 有序对表 — FindNodeIndex (sub_141229210) case4 目标; 变体读者 sub_141223990 / sub_1414E2AF0; **写者负定案 (恒空, case4 恒 −1)** | 读侧定案 / 写者定案 (负向) |
| +752 | 匿名结构 (8B 形状) 向量 | (省 id, 节点 idx) 有序对表 — FindNodeIndex case5 目标; 变体读者 sub_14120F110/141210470/1412220B0/1414E2AF0; **写者负定案 (恒空, case5 恒 −1)** | 读侧定案 / 写者定案 (负向) |
| +776 | 匿名结构 (16B 形状) 向量 | **消费者注册清单** {tag u32@0, CSupplyConsumer\*@8} (lam3 重建 → 注册阶段排水 = **sub_141229D70**: 逐 16B 条按 tag 定国调 sub_14121B650 注册); sizeof = 800 由本容器闭合 | 定案 |
