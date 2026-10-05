

### 4.11 情报—间谍系统 (谍报网 / 特工与特务专项 / 情报机构 / 情报账本与来源池 / 密码学)

> **本册范围**: 一个情报—间谍系统的全链 —— 谍报网侧 (§4.11.1–§4.11.10, 挂 `gs+1696`
> 谍报机构管理 + `cc+4072` intel 六矩阵) 与特务机构侧 (§4.11.11–§4.11.17, 挂
> `cc+4032` 机构 / `cc+5544` operations / `cc+5552` tokens + CCharacter 特工池);
> 两侧经同一对象链互指 (net+168 挂 `*(cc+5552)+16` 与 `*(ag+288)+16`;
> CCryptology = `*(agency+288)`)。

⚠ ci cheat 形态: **两类比定案** — CCountryIntel (vtable 0x14295F188) +216 =
内嵌 CStaticIntelSourceReference (键 19457); CCountryIntelNetwork +216 =
strength_sum_over_cores; 全链无 vtable 分流读取点, 按对象类各读各的。

**获取 (网侧)**: `so = *(operatives mgr 容器)`, 网容器 = `{data@so+16, count@so+28}`;
**第 i 网 = data[i]** (⚠ 一国多网, 每目标国一个 — 只读第一网会漏)。
**vtable**: 0X29A1A58。
**获取 (机构侧)**: `ag = *(cc+4032)` (CIntelligenceAgency, §4.11.14);
`ops = *(cc+5544)` (§4.11.15) / `tokens = *(cc+5552)` (§4.11.17)。

| 偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +8 | tag_id | target | 目标国 |
| +16 | CCountryIntelNetwork* | 网数组 容器数据指针 — (⚠ 这是 so 上的) |  |
| +17..+27 | — | = so 网数组容器尾 {cap@+24}  |  |
| +28 | uint32 | 网数组 容器计数 |  |
| +29..+95 | — | = **CLocalIntelNetwork 内联 80B 本体 (net+16..+95)** — net ctor `sub_1411BC870(a1+16)` 首行 `&CLocalIntelNetwork::vftable` (RTTI 0x1429a0408 实名) + writer ADEC0(0x3D1D, a1+16) + loader 同址三证; 图布局见下  |  |
| +96 | 匿名结构 (12B) | operatives 容器数据指针 — 顶点 | stride 12 {type@0, id@4, state@8} |
| +97..+107 | — | = operatives 容器尾 {cap@+104}  |  |
| +108 | uint32 | operatives 容器计数 |  |
| +109..+119 | — | = operatives 容器尾 + subnets 前置  |  |
| +120 | CSubIntelNetwork* | sub_intel_networks 容器数据指针 | 元素 216B CSubIntelNetwork |
| +121..+131 | — | = sub_intel_networks 容器尾 {cap@+128}  |  |
| +132 | uint32 | sub_intel_networks 容器计数 |  |
| +133..+143 | — | = subnets 容器尾 + max_coverage 前置  |  |
| +144 | 匿名结构 (40B) | **max_coverage_by_occupied_tag** 容器数据指针 — (0x4C00=19456), 元素 40B **{tag u32@0, pad@4, owned_worth u32@+8, states u32@+12, intel_network_gain_factor i64@+16, enemy_operative_detection_chance_factor i64@+24, enemy_operative_detection_chance i64@+32}** | c>0 |
| +145..+155 | — | = max_coverage 容器尾 {cap@+152}  |  |
| +156 | uint32 | max_coverage_by_occupied_tag 容器计数 | c>0 |
| +157..+167 | — | = max_coverage 容器尾 + intel_source vtable 前置  |  |
| +168 | CStaticIntelSourceReference 内联 | **intel_source** {vtable@+168, idx@+176, pool@+180, id@+184, discriminant@+188} — 真图 = net+16 内联 (§4.11.3); +176..+191 = intel_source 四字段; writer ADEC0(0x4B34, a1+168), loader 19252 同址 | |
| +177..+191 | — | = intel_source 四字段本体 (idx/pool/id/discriminant) |  |
| +192 | uint32 | coverage.core_states — **GUI: 全国覆盖 tooltip** (sub_1411D2400/BD440; NATIONAL_COVERAGE 权重 define 三元组) | |
| +196 | uint32 | coverage.controlled_states — **GUI: 同上** | |
| +200 | uint32 | coverage.owned_worth — **GUI: 同上** | |
| +204 | uint32 | **未初始化死槽 (堆残留)** — ctor 0X1411CF7C0 **不置零本槽** (只置 +192/+200/+208); 唯一写点 = 容器清场路径 sub_1411CFBE0 `*(a1+204)=0`; **全 dump 零读者**。探针「约半数网非零」= 分配器残留字节 (ctor 未初始化的直接推论), 非覆盖率分母 | |
| +208 | fixed×1e-5 | strength_sum (**loader 读档丢弃**, 运行时重算族) — **GUI: 全国覆盖 tooltip 强度行** (sub_1411D24A0) |  |
| +216 | fixed×1e-5 | strength_sum_over_cores (loader 读档丢弃) — **GUI: 同上** |  |
| +224 | fixed×1e-5 | **state_strength_max (定案)** (loader 读档丢弃) | **恒写; reader 未接, 段内内联**; **GUI: 机构行动行网强度** (sub_1411FB040 按 tag 找网 → sub_1411D47D0 = 逐 subnet+32 strength 取 MAX) |
| +240 | CSubIntelNetwork* RH 桶数组 | **state_id → CSubIntelNetwork\* 反查缓存** {buckets@+240, mask u32@+252, extra u8@+256, max_load_factor f32@+260=0.9} — 桶 24B {dist u8@+4, key state_id@+8, value subnet*@+16} (lookup sub_1411D4890; 调用点语境 "#~ No sub intel network in this state (yet?)"; dtor 对 +240 非 &unk_1430B2990 才 free) | 不序列化  |

#### 4.11.1 CStrategicOperative (so)

| 项 | 值 |
|---|---|
| RTTI 名 | CStrategicOperative |
| vtable RVA | 0X29A2358 |
| writer | 0X1412025B0 |
| dtor | 0X1411F1F20 |
| 挂载 | operatives mgr (gs+1696) 容器 {d@mgr+8, c@mgr+20} 8B 指针数组 |
| 元素 | 8B CID 对 {type@0, id@4} (探针 {4713,26131} 实证) |

定案依据 (注册回调反查法): 每 mission ctor 经 sub_141E8FF70 注册一对 so
成员函数直写对应槽。

mission id 枚举:

| 值 | mission | 槽/通道 |
|---|---|---|
| 1 | build_intel_network | so+64 effort 槽 |
| 2 | quiet_network | 无 so 槽 — 走 subnet 通道 |
| 3 | counter_intel | so+40 effort 槽 |
| 4 | root_out_resistance | 列表 = agency+216 (§4.11.14) |
| 5 | boost_ideology | so+88 effort 槽 |
| 6 | control_trade | so+136 effort 槽 |
| 7 | diplomatic_pressure | so+160 effort 槽 |
| 8 | propaganda | so+112 effort 槽 |

布局 (六连 effort 槽定案):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | tag_id | 本 so 条对应国 tag (BoostIdeology 选 tag 比对基准, 0x1411F81A0 三调用点直证; 与 §4.11.3 net+8 target tag 同构) | 推定 |
| +16 | CCountryIntelNetwork* 向量 24B | 网数组 {data@16, cap@+24, count@+28, alloc@+32} — 8B CCountryIntelNetwork* 元 | 逐网 ADEC0 |
| +40 | 24B 槽 | **counter_intel effort 槽 (mission 3)** {ptr/旗@+0, u32@+8, count u32@+12, 多态对象*@+16} | — |
| +64 | 24B 槽 | **build_intel_network effort 槽 (mission 1)** | — |
| +88 | CPdxArray<CID 对> 24B | **boost_ideology effort 槽 (mission 5)** (assert "BoostIdeology array" 实名) — {data@+0, cap@+8, count@+12, alloc@+16}; 元 8B CID {type@+0, id@+4}, 双零 = 空哨兵 (0x1411F81A0 三调用点同构遍历直证) | — |
| +112 | 24B 槽 | **propaganda effort 槽 (mission 8)** | — |
| +136 | 24B 槽 | **control_trade effort 槽 (mission 6)** | — |
| +160 | 24B 槽 | **diplomatic_pressure effort 槽 (mission 7)** | — |
| +184 | 匿名结构* (环形缓冲 buf §3.4) | recent_propaganda_effort — 元素 40B {ws Q17.15@0, st Q17.15@8}, 写序 head→tail 模 cap | head≠tail |
| +192 | uint32 | recent_propaganda_effort | head≠tail |
| +196 | uint32 | recent_propaganda_effort | head≠tail |
| +200 | uint32 | recent_propaganda_effort | head≠tail |

> 六连 effort 槽 (+40/+64/+88/+112/+136/+160) 同为 24B CPdxArray 容器族: +88 已由 0x1411F81A0 三调用点直证为 CPdxArray<CID 对> {data@+0, cap@+8, count@+12, alloc@+16}; 其余五槽的「{ptr/旗@+0, u32@+8, count@+12, 多态对象*@+16}」形推为同一四元组的误读 (+8 为 cap, +16 为 alloc); 五槽同形为**推定** (六槽尺寸/间距一致且同族 ctor), 待各自遍历点复核。

| +208 | 匿名结构 (24B 形状) RH 桶数组 | **trade_influence_modifier_of_buyers** (0x4B4A = 19274) {头@+208, buckets@+216, count@+224, mask@+228, extra u8@+232} — 桶 24B {dist@+4, tag@+8, value fixed i64@+16} | c>0 |
| +209..+223 | — | = RH 表内部位 (buckets@+216; 共享空桶 &unk_1430B2A10) |  |
| +224 | uint32 | trade_influence_modifier_of_buyers count | c>0 |
| +225..+239 | — | = RH 表内部位 {mask@+228, extra@+232}  |  |
| +240 | 匿名结构* (容器 data) | diplo_pressure.from_factions (0x4B4E) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +241..+255 | — | = from_factions RH 表内部位 {buckets@+248, count@+256} (空桶 &unk_1430B2A40) |  |
| +256 | uint32 | diplo_pressure.from_factions (0x4B4E) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +257..+271 | — | = from_factions RH 表内部位 + from_countries 前置  |  |
| +272 | 匿名结构* (容器 data) | from_countries (0x491D) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +273..+287 | — | = from_countries RH 表内部位 {buckets@+280, count@+288} (空桶 &unk_1430B2A90) |  |
| +288 | uint32 | from_countries (0x491D) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +289..+303 | — | = from_countries RH 表内部位 + drift 前置  |  |
| +304 | Q17.15 | propaganda_weekly_drift.war_support | raw≠0 才写 (默认 0) |
| +312 | Q17.15 | propaganda_weekly_drift.stability | raw≠0 才写 (默认 0) |
| +320 | uint64 ×3 | **独立 qword 清零族** (+320/+328/+336; 非容器 — dtor 不释放、ctor 非容器构造、+344 PID 界放不下 alloc; 探针全零, 未名) | 不序列化 |
| +344 | PID 7 槽 | subversive_activity_level: prev_err/integral/last_out/value/pf/if/df 7×i64×1e-5 @+0..+48 (sub_1411DD300) | **恒写 (全零也写)** |
| +345..+399 | — | = subversive_activity_level PID 7 槽本体 (56B/枚, 边界确认) |  |
| +400 | PID 7 槽 | danger_level 同构 | 恒写 |

Q17.15 格式: **截断** 5 位小数带尾零 (q15s = floor(v*1e5+1e-9)/1e5 后 %.5f)。

#### 4.11.2 operative 对象 nationalities 容器 (无独立 RTTI 类)

operative 对象 (`COperativeLeader`) 的 nationalities 容器 = **+3944** (uint32 tag 数组) /
**+3956** (计数); writer 0X140BB5A10 写**内联块单行** `nationalities={ ITA ETH SYR }`。
逐字段全表 (含写门/tok/提取形/容器内部) 见 §4.11.11 特有区全字段表。

#### 4.11.3 CLocalIntelNetwork (图 g, 80B, net+16 内联)

| 项 | 值 |
|---|---|
| RTTI 名 | CLocalIntelNetwork (RTTI 0x1429a0408 实名) |
| sizeof | 80B — net+16 内联挂载 |
| writer | 0X1411C62D0 (net 侧 ADEC0 0x3D1D, a1+16) |
| loader | case 0x3D1D → ABB40(a2, a1+16) 同址 |
| ctor | 0X1411CF7C0 — `sub_1411BC870(a1+16)` 首行 `&CLocalIntelNetwork::vftable` |

布局:

| 偏移 (g) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 图顶点向量 wrapper* | 顶点向量 wrapper = *(g+8), {beg@+16, end@+24} (writer 整体门 = 顶点数>0; 首发顶点数叶 257 "vertices"); **wrapper+56 = 有序 snid→vertex 表** (16B 元 {snid u32@0, vertex u64@8}; 拓扑总入口 sub_1411C0780 排序后由 sub_1411C03F0 装填; 重算铺底/清场的二分查找都打这张表) | 顶点 80B 内联 (下表); 边 = 环形链表 sentinel@*(wrapper), 元素 {next@0, from@+16, to@+24} |
| +16 | uint32 | **sub_network_count** (token 0x3D26 图 writer 直发 — **互换警告解除**); **运行时写点 = sub_1411C1310 返回值经 sub_1411C5D30 写入** (quiet subnet 转正后计数) |  |
| +24 | 匿名结构 | quiet 容器数据指针 — {d, c} |  |
| +25..+35 | — | = quiet 容器尾 {cap@+32}  |  |
| +36 | uint32 | quiet 容器计数 |  |
| +37..+47 | — | = quiet 容器尾 + allocator@+40 (ctor 直证) |  |
| +48 | uint32 | **prev_max_depth** (token 0x3D27 图 writer 直发) |  |
| +56 | uint32 | prev_gain_sources 容器数据指针 — {d, c} uint32 数组 |  |
| +57..+67 | — | = prev_gain_sources 容器尾 {cap@+64}  |  |
| +68 | uint32 | prev_gain_sources 容器计数 |  |
| +108 | uint32 | operatives 容器 — 全量重算入口 sub_1411D63A0 **首步清 0** |  |

subnet 对连通表 = **pdx_triangular_matrix 三角矩阵** (n(n−1)/2 u32): 拓扑 BFS sub_1411B7D70 写 `2×depth+1`、sub_1411C39D0 清场复用、sub_1411C5C90 setter (禁对角线)、sub_1411C06D0 下标换算。BFS 颜色值域 = 0 white / 1 gray / 4 black (三 BFS 一致)。

顶点 80B 内联:

| 偏移 | 类型 | 名称 |
|---|---|---|
| +0..+15 | 匿名结构 (16B 形状) 向量 | 顶点级邻接 = **数组形态** (16B 元 {to u64@0}, 非环形链表; wrapper 级边链表是另一结构) — 80B 布局由此闭合 |
| +24 | uint32 | snid |
| +32 | uint32 | depth |
| +40 | int64 | strength |
| +48 | fixed×1e-5 | gb.op = **gain_breakdown.operatives** (loc INTEL_NETWORK_STRENGTH_GROWTH_FROM_OPERATIVE "From own Operatives" 坐实); **写点 = operative 源增益波 BFS sub_1411C4210** (大顶堆 + max 松弛; gain = 源 gain × DECAY^depth 逐层复合) |
| +56 | fixed×1e-5 | gb.adj = **gain_breakdown.adjacencies** (loc …_FROM_ADJACENCY "From adjacent states" 坐实); **写点 = 邻接分解 sub_1411C0A80** (取**正差平均**, 官方注释写 "sum" 以引擎为准) |
| +64 | int64 | gain (4210 max 松弛 / C0A80 累加双写点; 清零铺底 = sub_1411C2960, 负流失率 = WRONG_CONTROLLER −10.0 / OUT_OF_RANGE −1.75) |
| +72 | uint32 | state_id |

拓扑重算链分工 (§4.11.18 细化): sub_1411C0780 = **总入口** (源排序 + sub_1411C03F0 装配 + sub_1411C5D30 编排); BFS 主体三件 = sub_1411B7D70 (拓扑) / sub_1411B81B0 (quiet) / sub_1411C4210 (增益波); "CGainPostProcessor" sub_1411C4080 **在重算链内 (步⑥)** (CacheSubNetworksStrength sub_1411D63A0 步⑥经 sub_1411C4080(g, 函子) 调用, operator() = 0x1411D7050 vtable RTTI 直读, §4.11.22)。

#### 4.11.4 CSubIntelNetwork (216B)

| 项 | 值 |
|---|---|
| sizeof | 216B |
| vtable RVA | 0X29A1AA8 |
| writer | 0X141208490 (modifiers 块 token 0x31E6 后直读 a1+8/+16/+24) |
| loader | 0X1412073E0 (case 12774 → sub_141203A60(a2, a1+8) 同基) |
| ctor | 0X1411CFAA0 (三清零) |
| 挂载 | net+120 sub_intel_networks 容器元素 |
| modifiers 基址 | = subnet 基址自身 (内联三槽 +8/+16/+24) |

布局:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | fixed×1e-5 | **modifiers.intel_network_gain_factor** (token 0x3D2B) | |
| +16 | fixed×1e-5 | **modifiers.own_operative_detection_chance_factor** (token 0x3D50) | |
| +24 | fixed×1e-5 | **modifiers.own_operative_detection_chance** (token 0x4B57) | |
| +25..+31 | — | = modifiers 槽尾 | ⚠ det/det_factor 键不存在于 token 表, writer 亦无此发射 |
| +32 | int64 fixed | strength (0x28A6; **loader 直写** — sub_1424C0A70 fixed 落槽; 存档值有效, PostLoad/运行期重算会覆盖) | |
| +40 | int64 fixed | strength_sum (0x4C03; loader case 19459 实写) | |
| +48 | int64 fixed | strength_sum_over_cores (0x4C04; loader case 19460 实写) | |
| +56 | int64 fixed | national_coverage (0x4BFA; loader 实写) | |
| +64 | int64 fixed | sub_network_strength_target (0x4B6A; loader 实写) | |
| +72 | int64 fixed | sub_network_strength_target_from_operatives (0x4C0C; loader 实写) | |
| +80 | int64 fixed | sub_network_strength_target_from_counterintelligence (0x4C0D; loader 读弃) | |
| +88 | uint8 | is_quiet (0x4B23; **loader 直写** — sub_1424C0C00 bool 落槽) | |
| +92 | uint32 | coverage.core | |
| +96 | uint32 | coverage.controlled | |
| +100 | uint32 | coverage.owned | |
| +104 | uint32 | total_coverable.core | |
| +108 | uint32 | total_coverable.controlled | |
| +112 | uint32 | total_coverable.owned (⚠ 命名张力待裁: 写源 = *(cc+4932) — 书 s4_03 占领度量第 4 槽 contested points 位, 与「owned」名不吻合; §4.11.22) | |
| +120 | 匿名结构 (12B 形状) 向量 24B | **coverage_per_occupied** {data@120, cap@+128, count@+132} — 12B 元 {tag 关联, u32@+4, u32@+8} (0x4BFD) | loader 19453 |
| +144 | 匿名结构 (16B, 内含 CState*) | states 容器数据指针 — {data, count}; 16B 条 {州指针, strength int64×1e-5}; **loader = sub_141206C60** (16B {i32,fixed} pair 数组解析 → id→CState* 经 sub_1412063F0 + sub_1411CFCB0 落 map) | 州 id = uint32@州对象+88; 无过滤全量写 |
| +145..+155 | — | = states 容器尾 {cap@+152}  |  |
| +156 | uint32 | states 容器计数 |  |
| +168 | 匿名结构 (NNB 形状) 向量 24B | **core_states** {data@168, cap@+176, count@+180} — **8B CState\* 元** (0x3189); **loader = sub_1403A9110** (i32 id 数组 → gs v10[89] 解引用 → sub_140B00560 落集合) | writer 遍历取 `*(st+88)` 发州 id; loader 12681 同法重建 |
| +192 | idpair | operatives 容器数据指针 — id 对列表; **loader = sub_141207010** (CID 直读无解析) | 8B 紧致对 {type@0, id@4}; 定案 |
| +193..+203 | — | = operatives 容器尾 {cap@+200} (+205..+207 pad; **+208..+215 = 容器分配器指针** — 24B 头 alloc 槽, 对象 216B 止) |  |
| +204 | uint32 | operatives 容器计数 |  |

⚠ 提取器形态 (operatives 块): `{"TAG" {…}}` 对列表双闭括号伪影 —
coverage_per_occupied (0x4BFD, sub+120) 块: 第 1 条 tag=`.#1`, 第 2 条起裸键。

#### 4.11.5 intel_source 挂载族 (net+168 元素 + radar/tokens/agency 三挂载)

元素布局 (三挂载同构; 元素 = `CStaticIntelSourceReference`):

| 元素+N | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | vtable | — | RVA 0X295F138 (= CStaticIntelSourceReference) |
| +8 | uint32 | idx → country = tag(idx) | idx>0 且 ptr@+12 非空才写 |
| +12 | uint32 | pool — (NNB 形状取值 = ptr 值) | 同上门 |
| +16 | uint32 | id | |
| +20 | uint32 | discriminant | |

三挂载同构 (静态 + 探针全链定案):

| 挂载 | 位置 | 备注 |
|---|---|---|
| radar | cc+4416 内联 | 容器 writer 0X1413F9120; ADEC0(0x2FCD, cc+4352) |
| tokens | `*(cc+5552)+16` (§4.11.17) | 定案: 元素 24B 五字段 — idx@+8 = 属主 tag / **pool@+12 = ci.static_intel_pools 池下标 u32** / id@+16 = 池内哈希键 / disc@+20 = ci+208 (探针+二进制全链无指针读法) |
| agency | `*(ag+288)+16` | 机构对象 = CIntelligenceAgency (§4.11.14) |

写门: 开键 sub_14197F040 — 块仅 idx>0 且 pool≠0 且 tag 查表非空落盘。

#### 4.11.6 tokens.operation_assets (排序发射; 宿主类 = §4.11.17)

块 token 0x3F75 = 16245, 门 = key 数 > 0; 元素 writer 0X141405DD0。

| 步 | 操作 |
|---|---|
| 1 | 遍历 RH 桶 (`*(cc+5552)+40` {data@+48, mask@+60, extra@+64}; 40B 桶 {dist@+4, tagid@+8, 值列 {data@+16, count@+28}}) 收集 tag id |
| 2 | 块 writer 按 **tag id 升序**发射 (sub_1401B6990) |
| 3 | 元素 writer 对列内 id 数组**拷贝后**按 **token 名逐字节字典序**排序写出 (memcmp + 前缀短者先 = std::string `<` = Lua 默认 `<`; 比较器 0X1424BBC80) — **非 token id 数值序** (动态 token 空间 id 分配序 ≠ 字典序; GER token_civilian / token_civilian_1 / token_resistance_contacts 实证) |
| 4 | 存储列表本身不动 |

#### 4.11.7 CCountryIntel 六矩阵 (cc+4072)

**获取**: `ci = *(cc + 4072)`; **vtable RVA 0X295F188**; **writer 0X140D07210**;
load-key 0X140D063A0; clear 0X140D062E0。

六矩阵 = 内联 24B 容器槽 `{data@+X, cap u32@+X+8, count u32@+X+12, alloc@+X+16}`
(形态定案: writer 帮手 sub_140D008F0/CEC260 + loader 帮手 sub_140CFFAE0 双证):

| 偏移 | 矩阵名 | token/键 | 元素形态 |
|---|---|---|---|
| +16 | intel | 12524 | CEC1C0 型: 32B = 4×i64 四象限; ⚠ 实体 = **40B {key u32 国家 idx@0 + 32B 四象限值@8}** (writer stride 40 直证; CEC1C0 32B = 值本体) |
| +40 | intel_from_allies | 19242 | CEC1C0 型 (同构) |
| +64 | intel_from_static_pools | 19263 | CEC260 型: 24B 外层 {子表 ptr@0, 子表 count@12}, 子表 40B 元 {key u32@0, 32B 四象限} — per-pool 分组矩阵 |
| +88 | intel_from_dynamic_pools | 19264 | CEC260 型 (同构) |
| +112 | intel_from_dynamic_pools_prev_day | 19356 | CEC260 型 (同构) |
| +136 | intel_from_encryption_decryption | 19492 | CEC1C0 型 (writer 同 from_allies 族; 导出键 intel.intel_from_encryption_decryption.#N; 20 档实测矩阵全空) |

元素 stride 32 = 4 × int64 定点 ×1e-5, 顺序固定四象限:

| 元素+N | 类型 | 名称 |
|---|---|---|
| +0 | fixed×1e-5 | civilian |
| +8 | fixed×1e-5 | army |
| +16 | fixed×1e-5 | navy |
| +24 | fixed×1e-5 | airforce |

主矩阵 count = 474 (含动态国家, **非 440**; 导出门 = idx < 国家数)。
CAddIntelEffect::Execute 0X14034A8D0 读 4 fixed → sub_140D026F0(ci, 1, tag, vec)
互证。loc 对账: INTEL_FROM_DECRYPTION_TECH "From Decryption" ⇒
from_encryption_decryption 消费端。CEC260 型外层 24B 元 = **标准 pdx 容器三元组尾** {子表 data@+0, **cap@+8 (u32)**, **count@+12 (u32)**, **alloc@+16 (指针)**}; 内层元素 = **40B = 10×u32** {key u32 国家 idx@+0, 四象限 32B@+8} (writer 0X140D00990 逐 10-u32 步进; 四象限经共享帮手 sub_14109AEA0 发射)。调用点 0X140D07210 三处 = intel_from_static_pools (+64) / dynamic_pools (+88) / prev_day (+112)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +160 | CStaticIntelSourcePool 向量 | **static_intel_pools** {data, count@+172} — 72B 元 (首槽 vtable, 字符串序列化) | writer 0x4B3D(19261); load-key 同键 → a1+160; clear 对 72B 元虚调用清场 (元素 = **CStaticIntelSourcePool** 72B; 池数 = **6**, ci ctor 172 直证) |
| +184 | CDynamicIntelSourcePool 向量 | **dynamic_intel_pools** {data, count@+196} — 56B 元 同族 | writer 0x4B3E(19262); load-key 同键 → a1+184 (元素 = **CDynamicIntelSourcePool** 56B; 池数 = **7**, ci ctor 196 直证) |
| +208 | uint32 | discriminant = **write-only 存档兼容判别** | ctor=1; 条件写: AAFD0 假才发 0x4B28 (仅二进制档写); loader AB970 读弃 |
| +216 | CStaticIntelSourceReference 内嵌 | **cheat** (0x4C01 ADEC0) — 内嵌静态 intel 源引用 {idx@+224, pool@+228, id@+232, discriminant@+236} | ctor 写 vtable 0X14295D5C8 (探针 vt_rva=0X295F138 实证); load-key 19457 → sub_1424C0AA0(a2, a1+216) |

#### 4.11.8 情报源三件套 (CIntelSource / CStaticIntelSourcePool / CDynamicIntelSourcePool)

**CIntelSource** (池内单源四象限矩阵, 40B; vtable 0x14295F098; writer 0x1411AEE90 / reader 0x1411ADE90; 入档): +8 intel 矩阵容器 {d@8, c@20} (12524) — 40B 元 {key u32 国家 idx@0, 四象限 4×i64×1e-5@+8 序 = civilian(19238)/army(10397)/navy(10398)/airforce(19239)} / +32 u32 id (11, 恒写) / +36 u8 remove 旗 (14530, 恒写)。发射序 = intel 块 → id → remove; 四象限写入帮手 = 共享族 sub_14109AEA0 (brace 包非零页)。

**CStaticIntelSourcePool** (静态源池, 72B; vtable 0x14295F0E8; writer 0x1411AEFF0 / reader 0x1411AE930; 入档): +8 RH 名索引 {buckets@8, count@24, mask@28, extra@32, mlf 0.9@36}, 12B 桶 {dist@0, key@4 源 id, val@8} / +40 CIntelSource 值容器 {d@40, c@52} (元素内嵌 CIntelSource 本体) / **+64 u32 next id** (11; slot[8] = 0x1411AD8D0 id 溢出回滚 >0x3B9AC9FF→0)。挂链 = ci+160 static_intel_pools (**6 元**; 存档不写名, 按位置序对应 6 静态源定义)。

**CDynamicIntelSourcePool** (动态源池, 56B; vtable 0x14295F048; writer 0x14197EC30 / reader 0x14197EBF0; 入档): +8 **accumulator** (19259) 40B 元 {国家 idx, 四象限} {d@8, c@20} / +32 **values** (19260) 同形 {d@32, c@44}; slot[8] = 0x14197E9B0 日总结算 = 两容器逐元四象限负值钳 0。语义 = 每池每国 intel 量日账 (accumulator = 当日累计, values = 已结算截面)。挂链 = ci+184 dynamic_intel_pools (**7 元**)。

#### 4.11.9 CCryptology / CCountryDecryptionState

**CCryptology** = `*(agency+288)` (机构对象 = `*(cc+4032)` = CIntelligenceAgency, §4.11.14; 挂载行 §4.3 +4032);
ctor sub_1413F61D0; 24B 槽 {data@+40, count@+52}。其内 **CCountryDecryptionState
56B** — 对每个已解密/解密中国家一条:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | tag | 目标国 |
| +12 | — | days — 激活加成剩余天数 (ctor 初值 **−1**; GetOrCreateCountryDecryptionState 0x1413F6F70 构造序列直证) | 激活时 = dword_1433331A0 = CRYPTO_CRYPTO_ACTIVE_BONUS_DURATION; −1 才不写 |
| +16 | uint8 | 全解密旗 (ctor 0) | |
| +17 | uint8 | hide 旗 | |
| +18 | uint8 | 解密中旗 (ctor 0) | 天数公式分母: 置位时 TotalToDecrypt 不 +1 (语义推定 = +1 是自身占名额, 未证) |
| +24 | — | 进度分子 (ctor 0) | 行进度条分子 |
| +32 | CGameDate 内嵌一 | {vtable@+32, hours@+40 = **43808760 ctor 哨兵 "1.1.1.1"**} | GetOrCreate 构造序列直证 |
| +40 | uint32 | date hours (CGameDate 域 {vtable1@+32, hours@+40, vtable2@+48}) | 键 10314 |
| +48 | CGameDate 第二vtable指针 (8B) | date 序列化锚 (ADEC0(10314, a1+48) 代理, hours 在 vtable−8) | 恒写 |

CCryptology 哈希索引层 (RH; 适用「暂停态 RH 表仍会重建」纪律):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +64 | RH 结构基 | 哈希索引层表基 (data@+72 = 基+8, count u32@+80, mask@+84, extra u8@+88, lf f32@+92 = 0.9 = 1063675494 ctor 直证; 静态空桶哨兵 &unk_143086250); 12B 槽 {占位旗@+0, tag@+4, 值@+8} | 定案 (insert/ctor 双向) |

记录四旗/分子键名: active (11390) / hide (679) / decryption (13042) / amount (417) / days (10605) / target (107) / date (10314)。GUI 进度条 = fixed 域中间量再 ×100/1e5 取整 clamp 1..100 (数值等价)。**天数公式全常数定案 (sub_1413F7960, 97 行)**: ① v4 = sub_1413F7C60(a1, &out, 0) = 自方日解密产能总量 (书 §4.11 头部 STRENGTH 取数器; ≤0 → 返 −1); ② 目标国密码强度 = mdef 528 @ *(crypto+8)+1464 (经 sub_14055E360); ③ 所需总进度 v9 = qword_143333030 + qword_1433330F0 × 强度/1e5 (两 define 派生全局, 静态镜像非真值 — define 组合见下); ④ 剩余 = max(v9 − entry+24, 0); ⑤ 分母 v17 = sub_1413F6CA0(a1) (+1; entry+18 解密中旗置位则不 +1) — ≤0 → cryptology.cpp:399 "TotalToDecrypt > 0" 断言返 −1; ⑥ 份额 = 1e5×v4/(1e5×v17); **天数 = ceil(1e5×剩余/份额), 下限 1**。哈希索引插入 (GetOrCreateCountryDecryptionState 0x1413F6F70): sub_1401B04A0(crypto+64, &slot, hash, &key, &idx), key = sub_140BB5490(tag) 国下标, **hash = 32 位 avalanche finalizer 常数 73244475 (0x45D9F3B) 两轮 `(h^h>>16)×K` 末 `h^h>>16`** (与 §3.2b 同族直证)。前置断言 "GetCountryDecryptionState( Tag ) == nullptr" (cryptology.cpp:476) = 查无才建。目标国关系取数 (sub_1413F8D80, 43 行): relation 数组基 = *(对象+8), 返 `*(基 + 8×下标)`; 空指针断言 cryptology.cpp:207 "pRelationStatus && \"no relation status for crypto target\""。

define 组合 (天数公式步骤③): qword_143333030 = **CRYPTO_BASE_CRYPTO_LEVEL** +
qword_1433330F0 = **CRYPTO_CRYPTO_LEVEL_PER_CRYPTO_UPGRADE**×level/1e5
(双 define 注册串直证), 再按目标国自身 mdef528 修正取值 (cc+1464 修正在表键)。

mdef 索引: 528/529 是 **modifier def 表索引** (非 lexer token id — lexer 528/529 =
addressu/addressv, 离线 token_table_1193 同; GAME.layout.modifier_token 活体直证):

| 值 | 名称 | 语义 |
|---|---|---|
| 528 | moddef crypto_strength | 修正索引 (UI loc CRYPTO_DEFENSE_LEVEL); 进度分母按目标国自身该修正取值 |
| 529 | moddef crypto_department_enabled | 密码学部门态旗 (CIsCryptologyDepartmentActive::Evaluate 同址直证) — 值≠0 = 部门激活 → active_crypto_items + 国表刷新; ==0 → crypto_not_active (与触发器名 is_cryptology_department_active 同向) |

情报账本刷新机 (流程): SetTarget 写 win+5456 → 脏旗 → vtable[4] 按 mode 推 tag 给
economy/army/navy/air 四面板。

#### 4.11.10 情报账本 GUI 消费点

| 对象+偏移 | 语义 | GUI 消费者 | loc key |
|---|---|---|---|
| ci 四象限矩阵 (§4.11 六矩阵) | 账本四页签数据源 | 面板数字**不读缓存管理器** — 四象限行 = 页签钮 `intel` 文本经 sub_1419DB1F0 直读玩家 ci+16 矩阵 (sub_140D045C0 = 四象限读取器定案); tooltip sub_141E9CAF0 把六矩阵全族 (+16/+40/+64/+88/+112/+136) 逐段映射 TOTAL_INTEL_*/INTEL_STATIC/DYNAMIC_SOURCE_* (静源名表含 IntelNetwork); qword_14333CFB8 = CMapModeManager 实名 (mapmodemanager.cpp:430 直证) — 其链路 = SetTarget 置缓存槽 11 脏 → sub_140F33D50 分派 → sub_140F353D0 读账本单例 tag+mode 做**地图着色** (非面板数值) | economy/army/navy/air_panel |
| CCountryDecryptionState 56B (crypt 24B 槽 {data+40, count+52}; §4.11.9) | 玩家侧对目标国解密账本 | cryptology_country_entry Setup sub_141A223E0 (tag@entry+32) | cryptology_country_entry |
| CCountryDecryptionState 记录字段 (§4.11.9) | 行四态文案与行进度条 | Setup 分支 | CRYPTO_DECRYPTING / CRYPTO_NOT_DECRYPTING / CRYPTO_FULLY_DECRYPTED / CRYPTO_FULLY_ACTIVATED / REVEAL_INTEL(_LEFT) |
| cc+1156 owned_states / cc+3976+656 阵营 | 候选门 (只列有争议州且非友方) | sub_141A228B0 + sub_1413F8640 | country_list(_container) / add_new_container |
| cc+632/{+644} 容器 | navy 页汇总行 — **= `CTaskForce**` 舰队容器** (§4.16 实名); 用途 = **按舰型聚合玩家已获情报的舰船数/价值**。汇总链: 舰队容器 → 逐 tf → `sub_140D230E0(tf)` (**全文仅 `return a1 + 184;` 一行访问器, 非「逐元聚合」**) → 逐 ship `sub_140BFDF30(ship,tag)>0` 情报门 → `*(ship+496)` ⚠ **两说并列待裁**: 本批三处直证 +496 = **所在省 CProvince\*** (intel.cpp 师/tf/志愿军条目一致按省消费 + §4.16「tf+496 = 当前省份」互证) vs 本行「→设计→舰级」链 (当时似有下游消费佐证, 原函未重读) — 若 +496 = 所在省则此链需复核 (疑容器层级或偏移转录错位) → 原「设计→舰级」段暂记待裁, `+112` 表 {count@+124, 48B 条} → `sub_140D6EEB0(ship)` → 计数; 价值化 0X1406F06F0 (`dword_143335208 * 计数 * 100000`) | **面板 = `CIntelLedgerNavyPanelController`** (RTTI 实名, vtable 0x142A8DEE8); 行类 = CLedgerShipTypeEntry / CLedgerShipEntry / CLedgerShipHeaderEntry (窗名 `ledger_ship_type_entry` / `ledger_ship_entry` / `ledger_ship_header_entry`) | 定案 |
| 账本页签区 (win+5248 mode 四区, 1288B/区) | 区 = CLegacyButtonObserverGlue\<CCountryIntelLedgerView\> (1288B), 每区仅绑一个 on_click — sub_1419DA880/6F50/7260/6DE0 ↔ economy/army/navy/air; 回调 = 置 win+5248 mode + 三态切换 + **切 map mode 30** | populate sub_1419D8F10 | econom/army/navy/air_panel(+_tab_frame) |
| economy 面板 | **CIntelLedgerCivilianPanelController 实名** (vtable[2]=0X141EC2250 五 filler 分派; +2816..+2912 元素名经绑定器 sub_141EBEC00+rdata 串逐个定名) | 面板 vtable[2] | — |
| army 面板 | vtable[2]=0X141EB85A0 thunk→**sub_141EB7200**: 师数/特战师数/部署人力三行 (ARMY_*_INTEL_MIN/MAX/AT_LOWEST define 三元组定名; **模糊化引擎 = sub_14142EB50**) | 面板 vtable[2] | — |
| AgencyView 子视图 A/B/C (win+1408/+1416/+1424) | A(+1408) = **CAgencyLogoSelectionWindow** (三证: malloc(0xB50)→vtable 0x142a2c638 + agencylogoselectionwindow.cpp:0x88 断言 + 窗名 name_logo_agency_selection_window; 另见 §4.31.88) / B(+1416) = **COperationOverviewWindow** (idpair 存储@win+5940 + spec 缓存块 win+5856; setter 0X14182CCD0 / opener 0X14182C990) / C(+1424) = **CAgencyUpgradesWindow** (三证: malloc(0x578)→vtable 0x142a2caa0 + agencyupgradeswindow.cpp:0x1BE + 窗名 intelligence_agency_upgrades_window; COperationViewEntry 只是内嵌行列表条目型, +14704 容器直证; 另见 §4.31.88) | 刷新器 sub_141A11EB0/**sub_14182EEF0 = COperationOverviewWindow::Setup (重建式刷新 — :166 "Window already created." 断言 + 26 元素绑定, §4.11.25)**/sub_141A166F0 | — |
| SBufferedOperations ×4 静态 (unk_14333D420/438/450/468, stride 0x18) | 行动页数据流 (tbb 并行预算; 0xAC0 行 {+2728 序, +2736 COperation\*, +2744 纪元快照}; 纪元 qword_14333D4C8/14333D528) | @48[6] Update 0X140F2F720 (经转发器 sub_140F2C100 = `sub_140F2F720(a1−48)`); [4] CalcOperations 0X140F29150 | — |
| 行动页纪元域 | **win+14744 纪元缓存** (⊥ qword_14333D4C8 命中 → 仅刷可见行 [0, +14736); 未命中 → 存纪元 + 清 +1704 格 (sub_1402E11E0, 伴生 +1712) + +14736=0) / **行池 {data@+14712, cap@+14720, count@+14724, glue@+14728}**; +14736 = 纪元等分支循环界 / 重建分支追加游标 (追加后 = +14724) | @48[6] Update; @48[9] Repopulate sub_140F2F3A0; 行 ctor sub_141A19CC0 / Setup sub_141A1B450 (+2728=*a3 / +2736=COperation\* / +2744=snapshot) / 行自刷新 sub_141A1C650; 行解引 sub_14221F310 + 门 sub_141401870 (obj+128==0) + 行刷 sub_141A1D110; 格几何 (列+368 / 上限+372 / 纵旗+384 / 游标+404) 未变 | — |
| 行动页纪元全局 | **纪元计数器 qword_14333D4C8** (写者: [4] OnOpen sub_140F2F050 内联自增 / sub_140F2D910 自增 / sub_1400737B0 置 0 / sub_140F29AF0 = `v1[21]` 存档恢复) / **快照与 idpair 哨兵 qword_14333D528** / tag 过滤表 qword_14333D4B0 + 计数 qword_14333D4BC / 16B 元双表 qword_14333D480 + dword_14333D48C 与 qword_14333D498 + dword_14333D4A4 (两段并行循环) | Update / CalcOperations | — |

> **§4.29 并入说明**: 特务专项 (COperativeLeader / mission 分发 / operation 块 /
> CIntelligenceAgency / 行动令牌) 原为独立分册, 与本节同属**一个情报—间谍系统**
> (同一对象链: gs+1696 谍报网 ←→ cc+4032 机构 ←→ CCharacter 特工池), 故合并于本节
> §4.11.11 起。原节号 §4.29 不再启用, 交叉引用已全数改指本节。

**账本四页面板控制器族 (身份与公共形; PE 直读)**: 装配 = sub_1419DAC10 ("country_intel_ledger_view" 四页签) — Civilian ptr@宿主+5296 / Army @+5344 / Navy @+5392 / Air @+5440 (各页数据源指针 @−16 槽); 页签 id dword 四区 +5256/+5304/+5400/+5352。四类 = **CIntelLedgerArmyPanelController 1720B / NavyPanelController 432B (vtable 0x142A8DEE8) / AirPanelController 368B / CivilianPanelController 3152B**, 共同抽象基 **CIntelLedgerPanelController 8B** (purecall 直证); 公共形: 主表 3 槽 {[1] 共享 setter int→+8→虚调 [2], [2] Refresh} / +8 刷新 mode / +16 宿主窗 / +24 页数据源 (Refresh 尾消费) / **+32 次 CTooltipHandler 子对象 (MI, COL objoff=32) 2 槽** / +40/+48 每页一个 CIdeasTooltipHandler 系 8B 标签。各页条目容器 = CSimpleEmptyEntryList 40B {vtable, qword×2, 容器头@24, u32@32}: Army 页 +1432 模板 / +1496 库存 / +1584 Idea / +1632 Technology / +1680 Doctrine; Navy 页 +104/+168/+208 舰三行 (书已载窗名) + +296/+344/+392; Air 页 +96/+136 机队两行 + +224/+272/+320; Civilian 页 +2664 Technology / +3080 Idea (行类 CIntelLedger{Idea,Technology,Doctrine}Entry 为全局类, 39 处引用簇)。Refresh 槽[2] 覆写读页数据源重建容器, 全族无 CPersistent = 纯视图侧缓存不入存档。

**CIdeasTooltipHandler ×4 同名 = 四个独立嵌套类 (非 ICF、非模板同实例)**: 四份 TD/COL/vtable (0x142A8C6E8 / 0x142A8DC30 / 0x142A8C0C0 / 0x142A8CEB0, 各宿主 PanelController 嵌套); 唯一差异槽 [0] = 逐页 tooltip 构建体 (直读账本视图单例 qword_14338B4C0 +5456 目标 tag — 与上表 win+5456 同坐标 — 及 gs+1312/1316 玩家 tag, 建 "CURRENT_ARMY_INTEL" 等 loc), 槽 [1] 全族共享 CTooltipHandler 基删除析构 0x1402DE980。「GUI handler 每-use 一类」引擎惯用形。

#### 4.11.11 COperativeLeader 特有区全字段表

身份表:

| 项 | 值 |
|---|---|
| RTTI 名 | COperativeLeader |
| sizeof | 0x10A8 (4264) — 两处独立 malloc_base(0x10A8) + ctor 旁证 |
| vtable RVA | vt0 0X142955F00 (主表, §4.4.1 同源) / vtable1 **0X142956018** (+3928 CSelectable 子对象视口) |
| writer (vtable slot2) | 0X140C28550 = 基链 0X140C1CE70 (前缀 [0,3928), 基类全表见 §4.4 CUnitLeader) + 特有区 |
| loader | — |
| 挂载点 | retired 池 {d@ch+200, c@ch+212} (ch = CCountryCharacters cc+4080; 元素 COperativeLeader* 8B, 键 15702, malloc 0x10A8 = sizeof 直证) 与现役 CIntelligenceAgency recruitment/agency 池 (§4.11.14), 同经 ADEC0 |
| ctor | 0X140C0BE20 (经 0X140C0C200 基类链) |
| dtor | 0X140C0D1B0 (触 +3928/+4232/+3944) |

ADEC0 备查: 写键 token 后调内嵌对象 vtable 槽1 trampoline 自序列化, 传参 = &vtable = 对象基址+8 (§3.7a 族 A, payload 在 ptr−8)。

**特有区全字段表** (writer 0X140C28550 调完基链后的发射序: nationalities →
captured + capture_date → codename → mission → state; 发射序 = 表序; 偏移 = leader 绝对):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +3928 | CSelectable | — | 不序列化 |
| +3929..+3943 | — | = CSelectable 子对象本体 (+3928..+3943) |  |
| +3944 | uint32 向量 | nationalities 数组数据 — u32 国家 tag 数组 (writer 0X140BB5A10); 提取器单行 `nationalities.#1` 空格连裸 tag | 门 计数@+3956≠0 开块, 逐元素 tag 名串 (5C20); tok 15634 (0x3D12) |
| +3945..+3955 | — | = nationalities 容器内部 {data 尾 +3945..+3951, cap u32@+3952}  |  |
| +3956 | uint32 | nationalities 容器计数 | |
| +3957..+3967 | — | = nationalities 容器内部 {alloc@+3960, pad}  |  |
| +3968 | uint32 | operation 对.type — 8B idpair; ctor 写哨兵 qword_14333D528 | 门 type≠0 ∨ id≠0; 0X142220180 (**写序先 id 后 type**); tok 12059 (0x2F1B); 叶序 codename 之后 state 之前 |
| +3972 | uint32 | operation 对.id | 同上 |
| +3976 | `std::optional<NOperativeMissions::COperativeMissionData>` | **32B value 存储 @+3976, `_Has_value` u8 @+4008** — MSVC optional 标准形 (拷贝 ctor sub_140C0BC10: poison 0xAA → present=0 → 条件逐字段拷贝 + present=1; 析构 sub_140C0D0D0 = reset; move-assign sub_140C0D820)。填充 = operationinstance.cpp:385 (sub_141400170, leader+4224==3 active 时取 op 实例快照); 清空 = sub_1413FFFB0 (operationinstance.cpp:677) | 不序列化 |
| +3977..+4007 | — | = +3976 匿名 32B 对象本体 (+3976..+4007) |  |
| +4008 | uint8 | (ctor 置 0) | 不序列化 |
| +4016 | tag_id (uint32) | captured 俘虏国 tag — 与 +4024 capture_date 各自独立 (capture_date = 24B, 见 +4024 行) | 门 (i32)>0; writer 0X140BB59C0 → 提取形 `captured="TAG"`; tok 15636 (0x3D14) |
| +4017..+4023 | — | pad (capture_date vtable1@+4024 前置对齐) |  |
| +4024 | CGameDate 24B {vtable1@+4024, hours@+4032, vtable2@+4040} | capture_date (ctor = 43808760 "1.1.1.1" 哨兵; 24B 占 +4024..+4047, 布局闭合) | 门 = captured>0 (**同一 if 块配对** — 无 captured 则 date 也不写); ADEC0 (ptr=vtable2=+4040, hours=ptr−8=+4032); 提取形 `capture_date="Y.M.D.H"`; tok 19297 (0x4B61) |
| +4048 | CNameGroupMember 内嵌 (176B = 0xB0, 4048..4223; vtable 0x142935b18) | codename | **恒写** (ADEC0 委托 → writer 0X1409C9AC0); tok 15639 (0x3D17); 子表见下 |
| +4049..+4223 | — | = CNameGroupMember 内嵌本体 (内部布局见 §4.3 名字组表) |  |
| +4224 | uint32 枚举 | state — 枚举表见下 | 块键 439 (0x1B7), 0X1401F4F00 写枚举原子; 非法值 → assert("Invalid enum value", unitleader.cpp) 后仍写 14668 |
| +4232 | COperativeMission 内嵌 (32B, 4232..4263 = sizeof 闭合) | mission | 门 0X140FC4080 = (type@+4256 ≠ 0) (⚠ 0X141FC3D70 非函数, 勿用); ADEC0 委托 (writer 0X140FC6240); 子表见下 |

**state 枚举表** (0X1401F4F00 写枚举原子):

| 值 | 名称 | 语义 (存档原子 token) |
|---|---|---|
| 0 | on_capture | 19025 |
| 1 | on_cooldown | 19026; **GUI 显示态 = enroute** (COperativeMapIconEntry [19] 分支 1→leader+3976 optional, 显示 leader_enroute) |
| 2 | on_disband | 19027 |
| 3 | on_mission | 14668 (ctor 默认 3); GUI 分支 3→mission impl vtable+72 (§4.11.13 互证) |
| 4 | on_operation | 19024; GUI 显示态 = on_operation (PortraitView 四态双处互证) |

GUI 显示态分组: 0/2/5 = idle, 1 = enroute, 3 = on_mission, 4 = on_operation (§4.31.43 视图族互证)。
| 5 | killed | 13164 |

**mission 句柄 (COperativeMission@+4232) 子表** (偏移 = leader 绝对, 括号内 = 对象内):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +4232 (+0) | vtable | vtable | 不序列化 |
| +4240 (+8) | — | pad | 不序列化 |
| +4248 (+16) | 匿名结构 (NNB 形状)* | impl — mission 槽 ptr 位 (分发表见上) | 不序列化 |
| +4256 (+24) | uint32 | type — mission 槽 id 位; writer 门字段 | 不序列化 |
| +4260..+4263 (+28..+31) | — | pad (sizeof 闭合 4264) | 不序列化 |

注: mission 槽 = {ptr@+16, id@+24}; +4224 状态枚举 ==3 (on_mission) = active 互证; 全部 Set* 置 handle+24 = type (§4.11.13)。

**codename (CNameGroupMember@+4048) 子表** (writer 0X1409C9AC0; 偏移 =
leader 绝对, 括号内 = 对象内):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +4056 (+8) | uint32 | codename.type (ctor 默认 2) | **恒写** (ADFE0); tok 225 (0xE1) |
| +4064 (+16) | MSVC SSO | (ctor 预置; cap@+4088 (+40)) | 不序列化 |
| +4104 (+56) | uint32 | (ctor = −1) | 不序列化 |
| +4128 (+80) | 匿名结构 (idpair 宿主)* | **equipment** (idpair 宿主指针 → {type@+8, id@+12}) | q≠0 → 0X142220260; tok 12110 = `equipment` |
| +4136 (+88) | 匿名结构 (NNB 形状)* | (ctor = qword_14333D528 哨兵) | 不序列化 |
| +4144 (+96) | MSVC SSO | (ctor 预置; cap@+4168 (+112)) | 不序列化 |
| +4176 (+128) | uint32 | codename.name_order | 门 ≠0; tok 14563 (0x38E3) |
| +4184 (+136) | MSVC SSO (size@+4200) | **override** | 门 size@+152≠0 且 !AAFD0; tok 14561 = `override` |
| +4216 (+168) | uint8 | codename.is_name_ordered | **==0 才写恒值 no** (≠0 不写; 与 deployment division_name 同函数同规则 — CNameGroupMember 两处复用); tok 14562 (0x38E2) |
| +4217 (+169) | uint8 | **override_set_programmatically** | 门 ≠0; tok 14646 |

注: sizeof(CNameGroupMember) = 0xB0 (176B; 4048+176 = 4224 = state 起点 — 三重直证 = post_mortem 容器步长 176 / 登记入口栈上 _BYTE[176] / ctor 与拷贝算子最后触点 +169 对齐闭合)。

**mission (COperativeMission@+4232) 分发表** (writer 0X140FC6240: assert
impl 非空 → switch(type) 取 mission 名 token → ADEC0(token, impl) 委托
impl 自己的序列化器):

| type | 存档名 | 名 token | impl 类 (vtable) | impl writer (vtable slot2) |
|---|---|---|---|---|
| 0 | (CNoMission, 门挡住不落盘) | 12789 | CNoMission 0x142980430 | 0X14012A2C0 (空) |
| 1 | build_intel_network | 15642 | CBuildIntelNetwork 0x142a1f878 | 0X141A31840 (state/network 族共用) |
| 2 | quiet_network | 19232 | CQuietIntelNetwork 0x142A1FFC8 | 0X141A31840 |
| 3 | counter_intelligence | 15643 | CCounterIntelligence 0x142A1FCA0 | 0X141A328B0 (country 族共用) |
| 4 | root_out_resistance | 19233 | CRootOutResistance 0x142A201B8 | 0X141A31840 |
| 5 | boost_ideology | 19228 | CBoostIdeology 0x142A1F5E8 | 0X141953D00 |
| 6 | control_trade | 19229 | CControlTrade 0x142a1fb00 | 0X141A328B0 |
| 7 | diplomatic_pressure | 19230 | CDiplomaticPressure 0x142A1FE00 | 0X141A328B0 |
| 8 | propaganda | 19231 | CPropaganda 0x142A295A8 | 0X141A31840 |

注: 中间基类与 impl 全布局见 §4.11.13; default → assert("Token not defined for mission type!", operativemission.cpp)。
存档消费形态: `mission.<名>.target` = tag u32@impl+16 (引号 tag); `mission.<名>.state` = u32@(*(impl+24))+88 (≠0 才写)。

本节不确定点:

- +3976 = `std::optional<COperativeMissionData>` (定案, 见上表)。
- CNameGroupMember 三未名字段定名 (高置信): +136 = override / +169 = override_set_programmatically / +80 = equipment (idpair; 铁路炮 +824 装备对呼应); tok 14561 / 14646 / 12110 对应 above。
- 基链 traits 循环 (块 12278) 每元素发两原子: trait token + 字面原子 18 — 定案: 纯文本层格式原子 (sub_1401F4F00(stream,N) = 写 (N, 词元串) 文本原子; 16 = 空串、18 = 单空格), 提取器丢弃正确。
- 原子 16 的文本形态: nationalities 块尾与 origin_type 块尾各写一个 0X1401F4F00(16) — 同上定案 (空串文本原子)。
- effect Parse token 12112 = `division_template` (离线表 + 运行时表双证; parse 现场 case 12112 → `sub_1424C0AA0(a2, a1+40)` 于 0x141BA0900)。

#### 4.11.12 operation 块 (存档块名, 非 RTTI 类名)

**operation 块子键表** (op 相对):

| 存档键 | 块数据 | 写门/格式 |
|---|---|---|
| civilian_factories / total (代价) | civ i64×1e-5@op+48, total i64×1e-5@op+56 | 门 civ≠0; writer 0X141404B00 |
| resources | COperationResources* 容器 {d@op+344, c@op+356}, 元素子表见下 (§4.11.16; 对象基 = op+336) | 门 count≠0 |
| return_on_complete (tok 19426/0x4BE2) | 容器 {d@op+368, c@op+380}, 元素子表见下 | 门 count≠0; writer 0X141404B00; 存档形态 = 半行匿名对象 `{ {id=X type=Y}` ␍ `amount}` → 提取器折 `return_on_complete.@.#N` = amount/1e5 (id 对被提取器丢弃; USA 锚 0x1AEAA→1.1025) |

ops 容器 (sub_14022FFF0 实例表) 形态补记: {data@+16, count@+28}, 8B 指针元 (推定)。

**resources 元素子表** (32B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | int64 | amount | flag≠0 → 块值 = C 截断 raw/1e5 + days |
| +8 | uint32 | days | |
| +16 | 匿名结构 (NNB 形状)* | def | |
| +24 | uint8 | flag | 分支门见下注 |

注 (resources 分支): flag≠0 → 发 `civilian_factories` 块 (tok 0x4BDD/19421); flag=0 → 键名 = token@*(e+16)+8, 单叶 fixed5。

**return_on_complete 元素子表** (16B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | uint32 | type | id 对被提取器丢弃 |
| +4 | uint32 | id | 同上 |
| +8 | int64×1e-5 | amount | 提取值 = amount/1e5 |

civilian_factories 条适配器 (非 GUI 类, 匿名 ns 函子 parse/serialize 适配器; 三证):

| 项 | 值 |
|---|---|
| writer | 0X140A7B070 |
| parser | 0X140A7AB40 |
| token | 19421 |

**COperationInstance 行级字段** (与本节 op 同族):

| 偏移 | 名称/语义 |
|---|---|
| +8 | self ref |
| +64 | auto_commence |
| +65 | auto_repeat |
| +66 | completed |
| +72 | COperation* def |
| +80 | owner cc |
| +88 | 目标 tag |
| +96 | 目标对象 |
| +112 | 开工 hours |
| +128 | 工期 days |
| +160 | 完成文本 |
| +192 | 双旗 (一) |
| +193 | 双旗 (二) |
| +224 | 特工快照表 (56B 快照, §4.11 同族) |
| +248 | 名 |
| +336 | 资源区 |

**关联消费点表** (COperation def / COperationPhase):

| 类 | 偏移 | 语义 |
|---|---|---|
| COperation (def) | +8 | def 消费点 |
| COperation (def) | +376 | def 消费点 |
| COperation (def) | +472 | def 消费点 |
| COperation (def) | +1168 | def 消费点; **GUI: 底栏小图标 gfx** (COperativeBottomBar 消费; 与 +1200 成双 = 大小图标, 推定待裁) |
| COperation (def) | +1200 | **GUI: 肖像视图大图标 gfx** (COperativePortraitView SetPortrait operation SetGfx 消费) |
| COperationPhase | +144 | 名 |
| COperationPhase | +176 | icon |
| COperationPhase | +240 | 标题 |
| COperationPhase | +368 | icon (两条目类分别消费) |

#### 4.11.13 mission impl 基类与 per-impl 全布局

谱系 (RTTI 全扫 12 类全齐): NOperativeMissions::IOperativeMission 纯接口 (无自身 typeinfo) → CNoMission 8B / CStateBased 32B → {CNetworkBased 32B (零新增字段) → CBuildIntelNetwork 64B / CQuietIntelNetwork 32B / CBoostIdeology 72B / CPropaganda 64B; CRootOutResistance 32B 直承 CStateBased} / CCountryBased 24B → CControlTrade / CCounterIntelligence / CDiplomaticPressure 各 56B。COperativeMissionData 32B = 任务快照非任务对象 (从不落盘负定案维持 — reader **sub_14194DFD0** 4 键 11450 mission/11838 ideology/14964 target_country/14965 target_state 与 writer 全对称, 纯 vtable 槽挂载, 读侧全机制见 §4.11.13a; 描述串构建器 **sub_14194D8B0** = "OPERATIVE_RESUME_MISSION" 两 104B 条目 {MISSION, TARGET}, type→kind 三折叠实测 3=州/1=国/2=州路 与 impl 谱系三分全吻合, 干员 tooltip 两调用点 §4.11.11 槽位互证; 见下); COperativeMission 句柄 32B = leader+4232 内嵌。清偿补注: **mission+88 = 州对象缓存**（州+204 = 控制国比对, 书定案）、**mission+96 = 意识形态指针**（kind5 "#~ No ideology" 门）——CSetOperativeMission 旧推定废。命名空间多出的 2 条 RTTI = CQuietIntelNetwork::GetProvincesInRangeOfState lambda 载体 (vtable 0x142A20148 / 0x142A20180)。

**中间基类表** (RTTI 定案):

| 类 | sizeof | vtable | 共用 writer (vtable slot2) | 派生 |
|---|---|---|---|---|
| CStateBased | 32 | 0x142A1F488 | — | CNetworkBased (0x142A1F538) / CRootOutResistance |
| CNetworkBased | 32 | 0x142a1f538 | 0X141A31840 | CBuildIntelNetwork / CQuietIntelNetwork / CBoostIdeology / CPropaganda (零新增字段, 仅覆 vtable) |
| CCountryBased | 24 | 0x142a1fa50 | 0X141A328B0 (只发 target) | CControlTrade / CCounterIntelligence / CDiplomaticPressure |

**全族vtable槽表** (12 类):

| 槽 | 函数 | 语义 |
|---|---|---|
| slot1 | 各类 dtor | — |
| slot2 | 各类 writer | 见 per-impl 表 |
| slot3 | 0X1424BE690 (共享) | — |
| slot10 | 0X141A314F0 (共享; CNoMission 单用 0X140FC37F0) | 名 token getter |
| slot17 | 各 impl 独立实现 (基类 purecall 0X14253C3B8) | 填 COperativeMissionData 快照 |

**CStateBased (32B) 字段表** (ctor 0X141A31390 默认 / 0X141A313B0 全参):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vtable | vtable | 不序列化 |
| +8 | COperativeMission* | owner — 所属 mission 句柄 | 不序列化 |
| +16 | tag_id | target country — 0X140BB59C0 引号串 | 门 >0 |
| +20 | — | pad | 不序列化 |
| +24 | CState* | pState; 快照 fill 0X141A313D0 (assert "pState not set", operative_mission_state_based.cpp:0x50) | writer ADFE0 — tok 439, 发 *(pState+88) |

**CCountryBased (24B) 字段表** (ctor 0X141A32670 / 0X141A32690):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vtable | vtable | 不序列化 |
| +8 | COperativeMission* | owner — 所属 mission 句柄 | 不序列化 |
| +16 | tag_id | target country | writer 0X141A328B0 (country 族共用) 只发此字段 |
| +20 | — | pad | 不序列化 |

注: CNetworkBased 无新增字段, 仅覆 vtable (ctor 0X141A31890 / 0X141A318C0)。

**COperativeMissionRegistrationHandler (32B) 注册器** (运行时注册器, 不序列化; init 0X141E8FF70 / register 0X141E90170 / teardown 0X141E903B0 + 0X141E8FF90):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | 匿名结构 (NNB 形状)* | owner — 所属 mission 句柄 | 不序列化 |
| +8 | 函数指针 | do | 不序列化 |
| +16 | 函数指针 | undo | 不序列化 |
| +24 | uint32 | 已注册国 id | 不序列化 |

register 流程: 国 id>0 → gs+1696 operatives mgr per-country 项 (sub_140EB2E80 查) → do(项, handle) → 记 id。
⚠ assert "Invalid registartion country"〔原文拼写〕 operative_mission_registration_handler.cpp:0x26。

**do/undo 对表** (6 对):

| mission (type) | do (索引数组基址) | undo |
|---|---|---|
| CBuildIntelNetwork (1) | 0x1411FF040 (a1+64) | 0x141200A80 |
| CBoostIdeology (5) | 0x1411FEF90 (a1+88) | 0x1412009D0 |
| CControlTrade (6) | 0x1411FF0F0 (a1+136) | 0x141200B30 |
| CCounterIntelligence (3) | 0x1411FF1B0 (a1+40) | 0x141200BE0 |
| CDiplomaticPressure (7) | 0x1411FF260 (a1+160) | 0x141200C90 |
| CPropaganda (8) | 0x1411FF320 (a1+112) | 0x141200D40 |

> 六对均由 `sub_141E8FF70(handler, owner, do, undo)` 注册，注册点各自 vftable 实名直证
> (sub_141954150 = CBuildIntelNetwork / sub_141952310 = CBoostIdeology / sub_141955BE0 =
> CControlTrade / sub_141956F60 = CCounterIntelligence / sub_1419585D0 = CDiplomaticPressure (⚠ 双注册点: sub_1419585D0 默认 ctor 与 sub_141958620 全参 ctor 注册同一对 do/undo — Set* 0X140FC58D0 实际调用全参者) /
> sub_1419DEC50 = CPropaganda)。**副作用 = 有序数组的插入/删除 (mission 索引登记)**: do 端
> sub_1411FCFC0 对 8B 元素 {tag u32@0, idx u32@4} 有序数组二分查找，未命中则 sub_1401B1640 插入;
> undo 端 sub_1411DC2B0 同型二分删除。do/undo 体形完全同构 (唯索引数组基址不同): do 以空 ref 哨兵
> qword_14333D528 起步 + 断言 ref.h:83 → sub_1411FCFC0; undo 同前段 → sub_1411DC2B0。

**per-impl 表** (sizeof 双证 = Set* 创建 malloc + clone 工厂 malloc; 全闭合):

| type | impl | sizeof | 基类 | handler | writer | Set* 创建 | clone |
|---|---|---|---|---|---|---|---|
| 0 | CNoMission | 8 | — | 无 | 0X14012A2C0 (空) | 0X140FC5A90 | — |
| 1 | CBuildIntelNetwork | 64 (0x40) | CNetworkBased | @+32 | 0X141A31840 | 0X140FC5390(h,tag*,pState) | 0X141954650 |
| 2 | CQuietIntelNetwork | 32 | CNetworkBased | 无 | 0X141A31840 | 0X140FC5DF0 | 0X141959E10 |
| 3 | CCounterIntelligence | 56 (0x38) | CCountryBased | @+24 | 0X141A328B0 | 0X140FC5710(h,tag*) | 0X141957860 |
| 4 | CRootOutResistance | 32 | CStateBased 直系 | 无 | 0X141A31840 | 0X140FC5FB0 | 0X14195AE90 |
| 5 | CBoostIdeology | 72 (0x48) | CNetworkBased | @+32 | 0X141953D00 (+ideology) | 0X140FC51B0(h,tag*,pState,ideo*) | 0X1419528D0 |
| 6 | CControlTrade | 56 (0x38) | CCountryBased | @+24 | 0X141A328B0 | 0X140FC5550(h,tag*) | 0x141942BD0 |
| 7 | CDiplomaticPressure | 56 (0x38) | CCountryBased | @+24 | 0X141A328B0 | 0X140FC58D0(h,tag*) | 0X141958EB0 |
| 8 | CPropaganda | 64 (0x40) | CNetworkBased | @+32 | 0X141A31840 (**无 ideology**) | 0X140FC5C30 | 0X1419DEFB0 |

注: 全部 Set* 置 handle+24 = type。CBoostIdeology +64 = CIdeology* (ctor a1[8]=a5); writer 0X141953D00 = 0X141A31840 + ADCE0(0x2E3E, *(ideo+20)) → `ideology = <名>`, 门 pState 与 ideology 皆非空。

**COperativeMissionData (32B) 快照字段表** (vtable 0x142955b40; writer 0X14194E520; ctor 0X14194D810 5参 / 0X14194D880 4参 / 0X14194D850 3参):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vtable | vtable | 不序列化 |
| +8 | uint32 | mission type — ADCE0 tok 11450; 值域 = 0X140FC4150 type→名 switch (与分发表同表) |  |
| +12 | tag_id | target_country — tok 14964 | 门 >0 |
| +16 | CState* | pState — tok 14965 → 发 *(pState+88) | 门 非空 |
| +24 | CIdeologyGroup* | ideology **组对象** — tok 11838; reader 经组库 CIdeologyGroupDatabase (qword_14332EF38) 哈希查表 (56B 桶, 键 = 组名哈希), 未命中 → "Invalid ideology group" 错误; deref+24 = 组名 MSVC 串 (ADF40); GetDesc 不读此字段 (详 §4.11.13a) | ADF40 |

注: optional 包装 move-assign 0X140C0D820, present u8@+32 (对象尾后)。消费 = operationinstance.cpp:385 (0X141400170): leader+4224==3 (active) 时经 0X140FC1130 (handle+16 → impl slot17) 取 op 实例 56B 元素内快照。

**op 实例 56B 快照元素** (operationinstance.cpp:385 消费形态):

| 元素+N | 内容 |
|---|---|
| +0 | vtable |
| +24 | type |
| +28 | tag |
| +32 | ptr |
| +40 | ptr |
| +48 | present |

**token 键名表** (lexer 在线直证):

| token | 键名 |
|---|---|
| 107 | target |
| 439 | state |
| 11450 | mission |
| 14964 | target_country |
| 14965 | target_state |
| 11838 | ideology |

注: 9 个 mission 名 token 与 §4.11.11 分发表全一致。

本册未决:

- handler 6 对 do/undo 具体副作用 = **有序数组的插入/删除 (mission 索引登记)** (定案) — 详见表下注 (do/undo 地址与索引数组基址全定)。
- handler+24 读回消费点 = **unregister 路径** (定案): register sub_141E90170 调 do 后记国 id; unregister sub_141E903B0/sub_141E8FF90 用记下的 id 反查 per-country 项 → 调 undo → 清 0。
- CState 侧 mission 反向引用维护者 (**未决维持**): 全 dump 未找到 CState 持有 COperativeMission*/COperativeMissionData 的写点; mission 侧仅单向 pState (COperativeMissionData+16)。
- CPropaganda ideology 不落盘 — 定案 (以 writer 为准): 共享 impl writer 只发 target(107)/state(439), 无 11838 — 读侧接受写侧不落盘的非对称 (mod 注入兼容), 非漏发。
- COperativeMissionData **从不落盘** (负定案): writer sub_14194E520 全 dump 引用数 = 1 (仅定义行), 其 vtable 0x142955B40 不被任何 Save wrapper 入口调用 ⇒ 纯运行时快照。

#### 4.11.13a COperativeMissionData 读侧与组库查表 (operativemissiondata.cpp; reader 0x14194DFD0 263 行 + GetDesc 0x14194D8B0 393 行)

reader 4 键分发表 (CPersistent vtable[4]; 与 writer 全对称):

| 键 (token) | 动作 | 失败处理 |
|---|---|---|
| 11450 mission | `sub_140FC4290(&out, token@(ctx+192), 11450, 0)` → 写 type@+8 | 解析串 "Expected an operative mission toke[n]" |
| 11838 ideology | 组库 qword_14332EF38 哈希查表 (下表) → 命中写 +24 = 桶+16 组对象 | "Invalid ideology group" |
| 14964 target_country | `sub_140BB5560(ctx, this+12)` 串→tag_id 直写 | — |
| 14965 target_state | `sub_1424C4FE0(ctx+192)` 读 id; `0 < id < u32@(gs+724)` → `+16 = *(*(gs+712) + 8·id)` | qword_14332F260 空 → :70 形态②日志 "Failed to read state id: no game state" (通道 4096); 越界 → "Expected state id" |
| 其他 | `sub_1424BEC40(this, ctx)` 基类 Parse 回退 | — |

> reader 站点断言: gameitemdatabase.h:142 库实例门 (闩 byte_14332F169) / gamestate.h:1125 (byte_14332ED00) / gamestate.h:1126 线程禁入门 (byte_14332ED01)。解析器/token 流布局: +192 整数读入口 / +200 当前串 / +212 串有效旗。

CIdeologyGroupDatabase (单例 qword_14332EF38; reader 11838 分支体直证):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +72 | 匿名结构 (NNB 形状)* | 哈希表 data (56B 桶数组) | |
| +84 | uint32 | 桶索引掩码 (哈希后 `& mask`) | |
| +88 | uint8 | extra (链尾哨兵偏移; 探测终止 = `ptr == data + 56·(mask + extra + 1)`) | |

哈希桶 56B:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +4 | uint8 | 槽位链计数 (探测上界: `游标 > 桶+4` 即止; 语义推定) |
| +8 | uint32 | 名哈希键 (匹配目标) |
| +16 | CIdeologyGroup* | 组对象指针 (命中 → 落 missiondata+24) |

> 哈希 = 对串哈希的二次混淆 (常量 73244475 双轮 + 移位), 冲突线性探测步长 56。

GetDesc (0x14194D8B0) 执行流程:

| 步 | 动作 | 门 |
|---|---|---|
| 1 | target tag@+12 无效 (≤0) → out 置空串返回 | tag 门 |
| 2 | `sub_140FC33E0(type@+8)` 折叠为 kind; kind==0 → 空串返回 | kind 门 |
| 3 | kind 1 (国, types 3/6/7): `sub_140BB4C30(+12, &out)` 由 tag 构造 TARGET 串 | — |
| 4 | kind 2/3 (州, types 1/2/4/5/8): pState@+16 空 → :132 断言 (B52, 闩 byte_14338B3B7) 后空串返回; 否则 `sub_1409D91D0(pState)` 州名 + `sub_140BB4E70(+12)` tag 名 + 两单字节分隔符 (WORD 值 0x12 与 0x20) 连成 TARGET 串 | pState 门 |
| 5 | `sub_140FC3240(out, type)` 取 mission 基名 → MISSION 条目 (2×104B 条目数组, 槽 {1, "MISSION"} / {1, "TARGET"}, eh vector constructor 构造) | — |
| 6 | `sub_142245E60(out, "OPERATIVE_RESUME_MISSION", &entries, 2)` 本地化查表写入 | — |

> 未决: 州路径分隔符 0x12 的语义 (分隔符/文本码) 未定, 需 PE 侧或 loc 系统对账; `sub_140BB4C30` (tag → 国名/显示串) 为本批唯一已知调用点, 书 §4.00 无条目, 待裁。

#### 4.11.13b 特工视图管理态与行动列表排序族 (operativeview.cpp 1 函 + countryintelligenceagencyview.cpp 6 函)

**COperativeView 列表管理态** (populate 0x141834E70 137 行; 断言字段名直证):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +40 | CView* | 父视图 (其 +1272 = 元素工厂) |
| +56 | void* | 条目容器持有槽 ("entry_padding" 元素 +240 读入) |
| +64 | CPdxArray 24B | _OperativeEntries {data@+64, cap@+72, count@+76, alloc@+80} |
| +88 | uint32 | _UsedEntries |
| +96 | CWindow* | UI 窗 ("operative_view"; vtable+200 = 销毁槽) |

populate (重建式) 流程:

| 步 | 动作 | 门 |
|---|---|---|
| 1 | +96 旧窗未清 → :140 断言 (B52, 闩 byte_14338B1AF) → 清理: 清 _OperativeEntries / +88=0 / +56=0 / 旧窗 vtable+200 销毁 / +96=0 | 旧窗门 |
| 2 | :145 断言 `_OperativeEntries.IsEmpty()` (count@+76==0, 闩 byte_14338B1B0); :146 断言 `_UsedEntries == 0` (闩 byte_14338B1B1) | 双清门 |
| 3 | `*(*(+40)+1272)` 父视图元素工厂 → 工厂 vtable+96 以名 "operative_view" 建窗 → +96 | — |
| 4 | 窗 vtable+192 取容器 "entry_padding" → `+56 = *(元素+240)`; 返回 +56 | — |

> 上游重建链 (sub_141834C90): 读旧窗 +165 字节 >>3 (旗) → 清理 → 调本 populate → `sub_141835130` 列表重建 (每特工建 COperativeViewEntry → 挂 operative_status_window, §4.11.26) → 旗真 → (+96)+48 子对象 vtable+120。

**行动列表排序族** (countryintelligenceagencyview.cpp; 6 函 = std::stable_sort / std::inplace_merge 模板族实例化, 比较器 lambda 内联; 操作 8B CID 对元素连续数组):

| VA | 行数 | 标准库角色 |
|---|---|---|
| 0x140F25A00 | 108 | 纯插入排序 (≤32 元叶; 前向插入 + 前缀 memcpy 旋转优化) |
| 0x140F25640 | 126 | 插入排序 run 分块: count≤32 → 上一行; 否则逐 32 元 (256B) 块插入排序 |
| 0x140F243F0 | 146 | inplace_merge 核心归并: 双指针比较 + memcpy 段旋转; 左段足够小时递归 0x140F24970 |
| 0x140F23F70 | 151 | inplace_merge 前段: 二分定位旋转点 → 尾调旋转+归并 |
| 0x140F24970 | 99 | 暂存归并分派: 左段足够小 → 临时缓冲归并; 否则按量分发 0x140F23F70 (左) / 0x140F254A0 (右) |
| 0x140F254A0 | 78 | 逆向归并 (merge_right): 自尾向前归并 + memcpy 段旋转 |

比较键链 (6 函共用, 体直证):

| 环节 | 语义 |
|---|---|
| 元素 8B CID {family@+0, id@+4} | 双 u32 全零 = 空哨兵 → resolve 置 0 (null 侧) |
| sub_14221F310(&cid) | CID → 已注册对象指针 (§4.00 原语, 失败返 0) |
| *(obj+72) | COperation 实例 → def 指针 (§4.11.15) |
| *(def+1032) | priority uint32 (排序键, §4.11.16a) |

> 比较 = priority 升序, stable_sort 保持同序原序。比较断言 countryintelligenceagencyview.cpp:479 "pLhs && pRhs" (B52, 闩 byte_14333D4D0)。

CalcOperations (sub_140F29150, §4.11.10 [4]) 分桶:

| 桶 | 宿主偏移 | 选择条件 (op = 行动实例) | 语义 |
|---|---|---|---|
| 0 | +0 | op+66 != 0 | 已完成 (op+66 = completed 旗, §4.11.15) |
| 1 | +24 | op+66==0 && op+128==0 && sub_141401870(op) != 0 | 筹备期 A (sub_141401870 分流门语义待裁) |
| 2 | +48 | op+66==0 && op+128==0 && sub_141401870(op) == 0 | 筹备期 B |
| 3 | +72 | op+128 != 0 | 运行中 (op+128 = duration, §4.11.15) |

> 每桶 = CPdxArray 24B (8B refid 元素, ref.h:83 / pdx_scopedptr.h:134 断言取 obj+8); 4 桶各经 stable_sort (暂存 n/2 元, 回退 512B 栈缓冲) 按 def priority 升序稳定排序, 尾入 §4.11.10 tbb 并行预算路径。桶 1/2 的业务语义 (筹备期两态) 未决。

#### 4.11.14 CIntelligenceAgency (ag = rp(cc+4032), vtable 0X2981F68, writer 0X140FDF3A0)

| 字段 | 偏移 (ag) | 布局/写门 |
|---|---|---|
| recruitment 内嵌 (vtable 0X29D8FF0, writer 0X14157BE20) | +8 | 三容器族 (下表) |
| upgrades {d, c@+108} 16B {tok*, u32} | +96 | count>0; **GUI: 分支升级格** (CBranchUpgradeButtonEntry sub_141A230F0; DB qword_14332EDC0 {count@+124, items@+112} → upgrade_button; `agency_branches` 格) |
| name SSO | +128 | 恒写; **GUI: 机构名** (Repopulate 0X140F2F3A0 → win+1448; agency_name) |
| icon SSO | +160 | 恒写 (icon 空串写 ""); **GUI: 机构徽标** (→ win+1672 (vtable+728); name_logo) |
| is_created (b) | +192 | 仅真写 |
| in_creation (b) | +193 | 仅真写 |
| upgrade_progress i64×1e-5 | +200 | 仅 ≠0; **GUI: 分支升级进度** (CBranchUpgradeButtonEntry 消费, 同 +96 链) |
| operative | +216 | {d@+216, c@+228} 8B operative 指针; = root_out_resistance (mission 4) 列表 (注册回调反查定名) |
| own_operative_death u32 (0x4B60=19296) | +252 | >0 才写 |
| max_operative_count | +240 | 恒写含 0 |
| usable_operative_slots | +244 | 恒写含 0 |
| elapsed_days_for_next_slot | +248 | 恒写含 0 |
| building | +256 | 恒写含 0 |
| captured | +264 | {d@+264, c@+276} 56B 元; count>0 开块 |
| cryptology | +288 | = *(ag+288) → intel_source 内嵌@+16 (vtable 0X295F138): country idx@+8 / pool@+12 / id@+16 / discriminant@+20; 开键 idx>0 且 pool≠0 (0X14197F040), 4 叶恒写 — 归 sv2_sec_c_intel 段管辖; **GUI: CCryptology 入口** (密码头部 LEVEL = mdef 528 crypto_strength @*(crypt+8)+1464 / STRENGTH sub_1413F7C60 + cryptology_country_entry 国别行; 全链 §4.11) |
| defense i64×1e-5 | +296 | 恒写含 0 |

recruitment 三容器 (容器 writer 0X141579010 count>0 才开块; 8B 指针元):

| 字段 | 偏移 (recruitment) | 键 | 备注 |
|---|---|---|---|
| generated_operatives | {d@+16, c@+28} | 0x4B44=19268 |  |
| recruitable_operatives | {d@+40, c@+52} | 0x4B45 |  |
| recruitable_operatives_not_to_spy_master | {d@+64, c@+76} | 0x4B54 | ctor 0x141579120 双子容器 |

> COperativeRecruitment 增补 (reader 0x14157B590): 19270 days_until_next_batch / 19462 days_recruiting 两废键标量吞弃不落字段 (旧版余键); 槽[8] 0x14157A520 = 三矢量清空例程 (此类唯一 [8] 覆写); 容器元素 0 值写 `none`(357) 占位 (writer 0x141579010, count>0 开块)。
COperativeLeader writer 链 (基 0X140C1CE70 + 0X140C28550):

| 字段 | 偏移 (e) | 写门 |
|---|---|---|
| id | {id@+12, type@+8} | 恒写 |
| name | MSVC@+32 | 恒写 |
| gfx | MSVC@+256 | size≠0 (运行时清空 → 不写) |
| female | b@+3712 | 仅 b@+3713≠0 写 |
| skill | u32@(*(e+3680))+440 | 恒写 |
| experience | i64×1e-5@+3688 | ≠0 |
| script_id | u32@+3924 | ≠0 |

#### 4.11.15 country.operations (ops = *(cc+5544))

| 块 | writer | 布局 |
|---|---|---|
| priority | 0X1411A2690 (ADFE0(0x8D), 挂载 ADEC0(0x4A38)) | u32@ops+88 恒写 (默认 1 照写 — 439 叶全量实证; 与 supply priority 默认不落盘规则不同) |
| finished (ops+40 子对象, vtable 0X27E7528) | 0X1411A19A0 | 外 RH {data@+16, mask@+28, extra@+32} 48B 桶 {dist@+4, op token id@+8, 内表 ptr@+24, 内 mask@+36, 内 extra@+40}; 内表 12B 桶 {dist@0, tagidx@+4, count@+8}; 外层 op-token 键先收集再排序 (sub_14119D460, std::sort 形) 后逐键发射; 内 tag 按 tagidx 升序 "TAG count" 空格连接 |
| running (gate count@ops+28≠0; {data@ops+16}) | 0X141404B00 (块名 = token@*(op+72)+8 op def) | id 对 {type@op+8, id@op+12}; duration u32@op+128 ≠0 才写 date+duration (date hours@op+112, CGameDate 代理 vtable@+120 hours 在 vtable−8 — raids 同构); equipment 块恒写 (ADEC0(0x2F4E, op+272; 对象 = CEquipmentVariantPool, vtable 0x142749270), allow_zero_entries 旗@op+328 以键 10208 落盘); target = 国 idx@op+88 → 引号 tag 恒写; target_provinces = ptr@op+96 → u32@ptr+164 (指针门); operative_slots 门 count@op+236≠0: {data@op+224} 56B 元 (0X141BE6A40): operative id 对 {type@0, id@+4} 非零门 / resume_mission u32@+8 ≠0 写 yes / mission 块门 b@+48≠0 对象@el+16 (0X14194E520): mission 枚举@+8 → sub_140FC4150 switch 0..8 裸名 / target_country 国 idx@+12 >0 / target_state ptr@+16 → u32@ptr+88; phases 门 count@op+260≠0: {data@op+248} 8B 指针 → token 名 u32@*(el)+8 引号空格单行; prepared: hours@op+208 ≠ 43808760 才写 (vtable 代理@+216) |

#### 4.11.16 情报机构事务族 (资源/令牌/阶段/升级/历史机构/转移动作)

**COperationResources** (行动资源清单容器; vtable 0x14271AB70; writer 0x140A7B070 / reader 0x140A7AB40; 入档): 容器 {d@8, c@20} 32B 元 = {i64 amount@0 (civilian 元 = raw/1e5 整写, 装备元 = fixed), u32 days@8, def 指针@16 (civilian → civilian_factories(19421) 块 / 装备 → def+8 token 名), u8 civilian 旗@24}; 挂载 = op+336 resources 容器对象基 (§4.11.15 op+344 行系容器 data 指针视角)。

**COperationToken** (行动奖励令牌定义, ~184B; vtable 0x14271ADF0; writer=CFG; reader 0x140A7FC30; idb operation_tokens 已挂): +16 desc (10644) / +48 icon (181) / +80 name (27) / +112 text_icon (19424) / +144 i64 intel_gain (19022) / +152 {dword intel 来源种类, u8 旗@156} (19252) / +160 targeted_modifier 容器 (14623, 8B 修饰 def 指针, 去重报错)。

**COperationPhaseSelection** (phases 选择列表容器, 32B; vtable 0x14293F288; writer=CFG; reader 0x140A7B420): op def 的 phases(19005) 块挂 **op+1936** {d@1936, c@1948} 本类实例, 内容 = 8B 指针元 → COperationPhaseSelectionMember; 无效 phase 名剔除并日志 (operationphase.cpp:68)。**COperationPhaseSelectionMember** (288B; vtable 0x14293F148; writer=CFG; reader 0x140A7B6F0 = 直通 +16 槽[4]): +8 u32 phase 名 token / +16 CAIMTTHChance 内嵌 272B (该 phase 的 AI 选中权重)。

**CAgencyUpgradeBranch** (机构升级分支定义, **88B** malloc 0x58 直证; vtable 0x1427DF190; writer=CFG; reader 0x140625780): +8 u32 FNV (分支名, sub_1424BB460) / +16 u8 = 1 / +24 SSO 名 / +56 u32 token id / **+64 分支内升级清单 {d@64, c@76}** (元 = CAgencyUpgrade 624B; 重复报错 agencyupgrade.cpp:262 — 原书「+40/+64/+88/+112 四容器」系归因误挂: 四容器全属 **CAgencyUpgradeDatabase 库对象** {+40 升级 lookup / +64 升级数组 / +88 分支 lookup / +112 分支数组, Array = Lookup+1 断言 gameitemdatabasehelper.h:35}, §4.11.28)。**CAgencyUpgrade** 624B {SSO 名@+24 ✓, **+56 = u32 token id** (双函同证, 与库 lookup 元+32 配对; 原记 FNV 系分支壳 +8 之误)}。idb agency_upgrade 已挂 (0x332EDC0)。

**CHistoricalAgency** (历史机构名簿; vtable 0x1427DF060; writer=CFG; reader 0x140621F70): **+16 names 串列表容器** (12767, SSO 32B 元) / +40 picture (464) / +72 available (12264) 子对象 / +160 default (11405) 子对象 — random_historical_agency 取名的数据底 (与 §4.33.10 CSetIntelligenceAgencyRandomHistoricalNameCommand 互证)。

**CCapturedOperativeReference** (被捕干员引用, 56B; vtable 0x142981FB8; writer 0x141A34FF0 / reader 0x141A34F40; 入档): +8 country tag (10394) / +12 operative idpair (15635) / +24 intel 四象限 (12524) — ag+264 captured 列表元素。

**CTransferSpyMasterAction / CTransferHeadOfCounterIntelAction / CTransferHeadOfCryptologyAction / CTransferHeadOfOperationsAction** (情报机构首长转移四动作; CDiplomaticAction 120B 零新增薄派生, writer/reader 同址直挂基类真体 0x141141470/0x14113E7A0):

| 类 | vtable | [23] 名产出 | [24] Clone |
|---|---|---|---|
| CTransferSpyMasterAction | 0x14298F3E8 | 0x14112E7E0 → DIPLOMACY_SPYMASTER | 0x141102550 |
| CTransferHeadOfCounterIntelAction | 0x14298F610 | 0x14112E690 → DIPLOMACY_HEAD_OF_COUNTERINTEL | 0x141102460 |
| CTransferHeadOfCryptologyAction | 0x14298F838 | 0x14112E700 → DIPLOMACY_HEAD_OF_CRYPTOLOGY | 0x1411024B0 |
| CTransferHeadOfOperationsAction | 0x14298FA60 | 0x14112E770 → DIPLOMACY_HEAD_OF_OPERATIONS | 0x141102500 |

> +104 type = 首长槽别 (枚举值待裁); 落点 = fac+2104 间谍首脑槽表 (§4.33.10)。

**AI 四驱动 (CAIModule 基, 名录; 无存档字段; 共性 +64 = owner 上下文; 门控读 CStrategicAI+8765 (csa+5965) 战略首轮就绪旗, §4.34.11)**: COperationsAI (vtable 0x1429AC6B0; [14] 周期启动门 → post CLaunchOperationCommand; [15] 周优先级) / COperativesAi (0x14298A2E8; [14] 干员招募+任务分派; 无周更) / CIntelligenceAgencyAI (0x1429AB938; **[15] 建局主逻辑**, DLC 门 25; [14] 仅 metrics 日志) / CCryptologyAI (0x1429AB130; +72 = cryptology 对象指针 (宿主 = agency+288 推定); [14] 日补位 + [15] 周重评估; **密码部门激活门 = 日/周共用前置门**)。四家 AI 行为全链见 §4.34.14。

#### 4.11.16a COperation def (2008B=0x7D8, vtable 0x14293F2D8) 与 COperationPhase def (408B=0x198, vtable 0x14271ABC0)

**COperation**: [2] writer = 空桩 (**def 不入存档**); [3] Load = 自定 wrapper
sub_140A7EDB0 (写 {块名 intern id, parser int} 对至 +1996/+2000 — serfam 盲区家族);
[4] reader = sub_140A7F200 (43 键); [8] PostLoad = sub_140A7D210; ctor sub_140A7BAB0。
库 = COperationsDatabase (128B, **qword_14332EFA8**; 名索引 RH 表 56B 桶; 书所记
EFA0 系邻位 idb 键); 工厂 sub_1401679D0 (命中 = move-assign 原位覆盖 + vtable[3] 重
parse = 热重载保位); 装载 boot 序 = operation_tokens → operation_phases →
common/operations。GUI: 行+2736 = COperation*; is_operation_type 读 op+72。

| 偏移 | 类型 | 语义 (脚本键) | 键 | 置信 |
|---|---|---|---|---|
| +8 | uint32 | 名字 token id (库 intern id; writer 取块名) | — | 定案 |
| +16 | CMeanTimeToHappen 56B | ai_will_do (ctor 默认 mean 4 天) | 10819 | 定案 |
| +72 | CMeanTimeToHappen 56B | target_weight (ctor 默认 mean 66) | 19642 | 定案 |
| +128 | CAndTrigger 88B | allowed — daily 失效删 op 求值点 | 12263 | 定案 |
| +216 | CAndTrigger 88B | available (可否发动) | 12264 | 定案 |
| +304 | 匿名结构 (NNB 形状) 向量 24B | awarded_tokens | 19423 | 定案 |
| +328 | uint32 | days / base_duration (PostLoad 断言非零, operation.cpp:513) | 10605 | 定案 |
| +336 | fixed×1e-5 | danger_level | 19302 | 定案 |
| +344 | SSO 32B | difficulty | 10655 | 定案 |
| +376 | uint32 | network_strength (所需谍报网强度) | 19009 | 定案 |
| +384 | CEffect 88B | on_start (启动期经 sub_140210F70 另发通知 = 名字复用) | 19007 | 定案 |
| +472 | uint32 | operatives / operative_slots (创建链按此扩快照表) | 15646 | 定案 |
| +480 | CEffect 88B | outcome_execute (普通结局; Complete 在 op+192==0 时执行; 效果容器 count = def+500) | 19432 | 定案 |
| +568 | CEffect 88B | **outcome_extra_execute** (奖励结局效果, 无 fail 效果键; Complete 在 op+192!=0 时执行; 容器 count = def+588) | 19433 | 定案 |
| +656 | CEffect 88B | outcome_potential | 14673 | 定案 |
| +744 | CAndTrigger 88B | optional | 19008 | 定案 |
| +832 | 匿名结构 (NNB 形状) 向量 24B | required_tokens | 14675 | 定案 |
| +856 | CAndTrigger 88B | requirements (独立触发器; 原「allowed 触发器」键名纠正) | 15166 | 定案 |
| +944 | CAndTrigger 88B | selection_target_state (Parse 参 2 = state 域) | 19021 | 定案 |
| +1032 | uint32 | priority (总览行排序键) | 141 | 定案 |
| +1036 | uint32 | target_type (ctor 默认 10304 = province) | 19420 | 定案 |
| +1040 | CAndTrigger 88B | visible | 11562 | 定案 |
| +1128..+1131 | uint8 ×4 | will_lead_to_war_with (13828) / prevent_captured_operative_to_die (19154) / is_staged_coup (15921) / is_captured_cipher (16141) | 各键 | 定案 |
| +1136 | SSO 32B | desc | 10644 | 定案 |
| +1168 | SSO 32B | icon (行动总览行小图标, 行填充 SetGfx def+1168) | 181 | 定案 |
| +1200 | SSO 32B | map_icon (肖像视图大图标 COperativePortraitView; 地图图标同源) | 14676 | 定案 |
| +1232 | SSO 32B | **name** (def 名串, getter sub_140A7CFC0 直读 — on_start 通知系名字复用) | 27 | 定案 |
| +1264 | fixed×1e-5 | cost_multiplier (ctor 0xAA = 未设哨兵; 未设用全局默认) | 19001 | 定案 |
| +1272 | uint8 | cost_multiplier 设定旗 (读入即置 1) | — | 定案 |
| +1280 | fixed×1e-5 | time_multiplier (ctor 0xAA 哨兵) | 19002 | 定案 |
| +1288 | uint8 | time_multiplier 设定旗 | — | 定案 |
| +1296 | fixed×1e-5 | outcome_extra_chance (弃用键 19430 读入写 100000−v 并告警, operation.cpp:476) | 19673 | 定案 |
| +1304 | fixed×1e-5 | risk_chance (计算器 sub_140A7C110) | 19427 | 定案 |
| +1312 | fixed×1e-5 | experience (ctor 默认 1.0; Complete 特工经验 = define × 此值/1e5) | 11930 | 定案 |
| +1320 | uint32 | 本 def 在 _cost modifier 类别库的 mdef 索引 (PostLoad 登记) | — | 定案 |
| +1324 | uint32 | 本 def 在 _outcome 类别库的 mdef 索引 | — | 定案 |
| +1328 | uint32 | 本 def 在 _risk 类别库的 mdef 索引 | — | 定案 |
| +1336 | 匿名结构 (NNB 形状) 向量 24B | cost_modifiers | 19429 | 定案 |
| +1360 | 匿名结构 (NNB 形状) 向量 24B | outcome_modifiers | 19431 | 定案 |
| +1384 | 匿名结构 (NNB 形状) 向量 24B | risk_modifiers | 19428 | 定案 |
| +1408 | CPersistentScriptTargets 264B | operation_target | 19018 | 定案 |
| +1672 | CPersistentScriptTargets 264B | selection_target | 19019 | 定案 |
| +1936 | 匿名结构 (NNB 形状) 向量 24B | phases — 元 = COperationPhaseSelection* 8B (每出现一次 phases 键追加一个 32B selection 并入新成员; selection 内才是 member 列表) | 19005 | 定案 |
| +1960 | COperationResources 32B | equipment 基础资源清单 (创建链先拷它) | 12110 | 定案 |
| +1992 | uint8 | return_on_complete (PostLoad 逐资源元打 return 标) | 19426 | 定案 |
| +1993 | uint8 | scale_cost_independent_of_target (置位 = 全目标口径; cost/time/资源三处一致) | 19350 | 定案 |
| +1996 | uint32 | 名字 intern id (自定 Load 入口现算: 块名 FNV → 全局 intern 表) | — | 高置信 |
| +2000 | uint32 | Load 期 parser 读入 int (与 +1996 成对; 语义未决) | — | 推定 |

实例侧订正: op+192/+193 存档键 = `outcome_extra`/`risk_extra` (原「失败旗/检测旗」
应更名); Complete 机会 = outcome_extra_chance(+1296) 基值 + 修正。

**COperationPhase** (ctor sub_140149BF0; [2] writer 空桩; [3] Load = 自定
sub_140A7B2A0 (intern 对至 +400); [4] reader = sub_140A7B2E0 11 键; [8] PostLoad =
map_icon 空回落 icon + return_on_complete 传导 +104); 库 = COperationPhasesDatabase
(common/operation_phases, 按名字入库):

| 偏移 | 类型 | 语义 (脚本键) | 键 | 置信 |
|---|---|---|---|---|
| +8 | uint32 | 名字 token id (phases 库 intern) | — | 定案 |
| +16 | CAndTrigger 88B | requirements (phase 级门槛) | 15166 | 定案 |
| +104 | COperationResources 32B | **equipment** (本 phase 资源需求清单; 创建链 sub_140A7BEA0 = 拷 def+1960 基础清单 → 逐选中 phase 并入 +104 → 重复系数缩放) | 12110 | 定案 |
| +136 | uint8 | return_on_complete (PostLoad 传导到 +104) | 19426 | 定案 |
| +144 | SSO 32B | desc (GUI 阶段条显示文案; 原「+144 名」键名纠正) | 10644 | 定案 |
| +176 | SSO 32B | icon | 181 | 定案 |
| +208 | SSO 32B | map_icon (空 → PostLoad 回落 +176) | 14676 | 定案 |
| +240 | SSO 32B | name (相位显示名, 如 "Dig the tunnels!"; 原「+240 标题」键名纠正) | 27 | 定案 |
| +272 | SSO 32B | outcome (结局文案) | 19011 | 定案 |
| +304 | SSO 32B | outcome_extra (奖励结局文案; 与实例旗 op+192 存档键同名族) | 19434 | 定案 |
| +336 | SSO 32B | risk_extra (冒险结局文案; 实例旗 op+193 同族) | 19435 | 定案 |
| +368 | SSO 32B | picture (事件肖像图; 原「icon」键名纠正) | 464 | 定案 |
| +400 | uint32 | 名字 intern id (自定 Load 写; GUI 经全局表查) | — | 高置信 |
| +404 | uint32 | Load 期 parser 读入 int (与 +400 成对; 语义未决) | — | 推定 |

#### 4.11.17 行动令牌管理器与情报 defines 全局映射

**CCountryOperationTokenManager** (国别行动令牌管理器, 72B; cc+5552 tokens scopedptr 本体; ctor 0x141405CF0(cc); **入 savegame 国家块**): writer 0x141407F90 / reader 0x141406F20; 落键 = intel_source (19252, +16 内嵌子对象) + operation_assets (16245, RH 表 40B 条目 {+48/+56/+60/+64}, 排序后落盘), reader 兼容旧键 tokens (19016); 与相邻 cc+5544 CCountryOperationManager (内含 CCountryFinishedOperations@+40) 配对 — 干员令牌 def 见 §4.11.16 COperationToken, 本类持运行态令牌清单。

| 全局地址 | define 全名 | 定义件值 | 注册点 | 消费者 |
|---|---|---|---|---|
| dword_143335730 | NOperatives::AGENCY_CREATION_FACTORIES | 5 | dump | CIA 建局门槛 IsValid 0x141A298E0 (可用民工厂 ≥ N) |
| dword_143335C90 | NOperatives::BECOME_SPYMASTER_PP_COST | 50 | — | CBecomeSpyMaster Execute 0x141A27370 (非 DLC 通道政治力) |
| dword_143335D14 | NOperatives::BECOME_SPYMASTER_MIN_UPGRADES | 3 | — | IsValid 0x140FD8F60 (所需情报局升级数) |
| dword_1433357C8 | NFactions::FACTION_INTELLIGENCE_UNLOCK_COST | 1 | — | CBecomeSpyMaster DLC 通道 (100000×值 扣 ms+72; 同 §4.31.21/§4.31.2 解锁费) |

> 名证 = 注册调用点与全名串返回函数双证 (映射表六地址均唯一), 值级与 common/defines/00_defines.lua 对拍一致。

> **本域 GUI 类布局**: 见 4.31.43。

#### 4.11.18 operation 运行推进链

**phases 负定案**: op+248 phases = 创建时逐 selection 加权掷骰选定的**静态变体
列表** (sub_14119F780, CAIMTTHChance, 种子 = sub_14119F4F0(ops,def,target) 双
hash), 决定该次 op 的资源/工期/图标 — **运行期无逐段状态机**; 生命周期三态 =
COLLECTING (duration=0) → 运行 (duration>0) → COMPLETED (op+66)。RAID 五段
相位机属突袭系统 (§4.27.3), 与 operation 无关。

创建链: **CreateOperationInstance sub_14119E0F0** (def 查找 → 查重
"Tried to create the same operation twice against the same target"
operationmanager.cpp:385 → 掷骰选 phases → malloc(408) + 全参 ctor
sub_1413FE600: +72 def / +80 cc / +88 target / +112 开工哨兵 43808760 /
+208 prepared 哨兵 / 五容器 (+224 快照表 56B/元 / +248 phases / +272 equipment
/ +336 资源 / +368 return_on_complete); def+472 特工槽数扩 +224; 资源掷骰
sub_141404A30 (sub_140A7BEA0 逐 phase 并入 phase+104 资源 × 系数 (def+1272
旗? def+1264 : 全局) + 变体掷骰 sub_140A7BFD0 → +336) (定案)。

启动 **StartOperation sub_141400170** (判定 sub_141A29BC0 CanStart):
① **op+128 duration = sub_14119EB20** (def+328 基础天数 × 修正;
tooltip OPERATION_VIEW_BASE_DURATION/DURATION_MALUS_REPETITION/
DURATION_MALUS_DEFENSE); ② **op+112 = gs+1128 当前总小时**; ③ 玩家国 →
on_start 通知 (def+1232, sub_140210F70); ④ 特工绑定: +224 逐 56B 元 →
leader+4224==3 (on_mission) 时经 mission 句柄 slot17 取
COperativeMissionData 快照填元素+16..+48, **sub_140C26600(leader, op)
(state→4 on_operation + 绑 op)**; 缺特工 = **格式化错误日志** "Starting an operation with a
missing operative!" (operationinstance.cpp:408, sub_1424C8950 族无中断); ⑤ 资源扣除 (civ → 生产
sub_141374EF0; equipment → sub_14100EA70 入 +272) (定案)。

daily 推进 **sub_14119E390** (CCountry::DailyUpdate operations 步, 逐 running
op): ① duration==0 → 资源重算; ② **civ 累计 op+48 < 总需求 op+56 → 生产扣款**
(op+48 += sub_140E69490(cc+3944) 可用产能; instant 旗 word_14332F623 ∧ 玩家国
→ 一次付全款); ③ **prepared (op+208)**: 资源齐且未启动 → 写当前小时, 否则
重置哨兵; ④ 工厂需求聚合 → ops+80 (变则 sub_1406FF1F0(cc,2) 修正重算 bit);
⑤ **auto_commence (op+64) → 尝试启动** (每 op 每天一次); ⑥ 失效删除
sub_14119DD20: 目标 tag≤0 / 目标国亡 / 敌对判定 / **def+856 allowed 触发器
求值失败** → 释放特工 (sub_141403580) + 删实例 (定案)。

到期结算 hourly **sub_14119FE70** (country hourly pass⑥ cc+5544, 逐 running
op 栈拷贝): ① 目标国亡 → 释放+删 (无条件); ② duration==0 或 completed 跳过;
③ **到期判定 sub_141403780: gs+1128 ≥ op+112 + 24×op+128** (instant 旗+玩家国
跳过); ④ 到期 → finished 表记账 (ops+48 双层 RH, 目标 tag count+1); ⑤ 玩家
可见: 通知 sub_140CD6440 / cryptology op 解密天数扣减 / def "operation_
rescue_general" 特殊处理 (sub_1401ED990 + sub_140CD43A0 救出将军); ⑥
auto_repeat (op+65): 可重启 (sub_141A29180) → 构造重启命令入事件队列; 否则
玩家国弹 OPERATION_VIEW_AUTO_REPEAT_FAIL; ⑦ **sub_1406FFC90(cc) = 到期通知
登记 (恒真, 写 tag 列表 + cc+136=1) → 所有到期 op 一律当场删除**; ⑧ 待删表
swap-remove 收尾 (operationmanager.cpp:360) (定案)。

Complete **sub_141403780** 十步: ① 派发 **on_operation_completed**
on_action (scope = 目标+owner); 特工经验 = qword_1433333B0 × def+1312 / 1e5
(operationinstance.cpp:548); ② 成功判定: 修正聚合 (国家 cc+1448 + 逐特工
leader+648 + 目标国) → def+588 触发器 → 掷骰失败 → **op+192 失败旗**;
③ 效果块 def+480 (成功) / def+568 (失败) 执行 → op+160 完成文本; ④ **op+66
completed**; ⑤ 特工检测掷骰 → 派发 on_operative_detected_during_operation +
**op+193 检测旗** (operationinstance.cpp:615/622); ⑥ 特工释放 (leader+4224==4
∧ 绑定 op → sub_140C249A0 state 4→3 + 清 leader+3968 + 恢复 mission; 快照
resume_mission → sub_140C26330); ⑦ return_on_complete 支付 (civ/装备返还);
⑧ debug 门日志 (定案)。

**56B 快照元素形态** (op+224, 三点对读定案): {idpair type@0/id@4,
resume_mission u32@8, COperativeMissionData 32B@16 {vtable@16, type@24, tag@28,
ptr@32, ptr@40}, present u8@48}。

情报网重算 (七连之一 sub_1412002E0, 每 so 每日, §4.2.7 特工日更通道): ① 收集属主 agency 特工
(ag+216) mission type∈{1,2,5,8} (build_intel_network/quiet_network/
boost_ideology/propaganda) 按 target tag 聚合; ② 逆序遍历 so+16 网数组每网
**sub_1411D63A0 全量重算** (countryintelnetwork.cpp:492 "A country should not
be able to build an intel network on its territory"; TopologyClient BFS
sub_1411C0780(net+16) + CGainPostProcessor sub_1411C4080; INTEL_NETWORK_* 五
define qword_143335F60/FF8/E38/ED8/6540); 失效网 (无特工指向
sub_1411D4EF0) swap-remove; ③ 新目标 → malloc(264) + ctor sub_1411CF7C0 +
重算。loader 读弃的 net+208/216/224、subnet+32 即此族运行时缓存。

**反谍强度 CIR 公式 (sub_1411F3DF0, 定案 — 全函数 617 行全文定案, 旧「ICF
巨函 >1.2 万行」记载与语料不符废)**: CIR = BASE_COUNTER_INTELLIGENCE_RATING
(qword_143335DA8) + 修正 511 MODIFIER_INTELLIGENCE_AGENCY_DEFENSE (读目标国
cc+1448) + 特工项; tooltip 格式串 "#~ Factor * CIR + Offset = %s * %s + %s"
直证命名。特工项 = so+40 counter_intel 槽 (mission type==3) 过滤目标 ==
so+8 → 逐特工 (OPERATIVE_BASE_INTEL_AGENCY_DEFENSE qword_1433313C0 +
COperativeLeader+1032 修正块 ×511) × (1 + FOREIGN_AGENT_FACTOR
qword_143337FE0/1e5)。特工项取值器本体 = sub_140C16690 (断言 "_Result.IsSet() …
tooltip has not been generated" modifier.h:1191): 值 = qword_1433313C0 + Σ
{sub_140C187D0(特工, tag) → nationalities (特工+3944, count+3956) 二分命中条目 +304 修正;
特工+1032}; tooltip 先决 "STAT_BASE_VALUE" 行 + 尾段 FOREIGN_AGENT_FACTOR ≠0 →
"MODIFIER_OPERATING_IN_FOREIGN_COUNTRY" 行并乘 (factor+100000)/100000; 泛化版
sub_140C27CB0 (mdef id 形参) = 三源 {国籍修正, 特工+1032, 母国 (特工+288) cc+1448} —
两者皆 modifier.h:1191 **跟踪统计求值模板**消费 (栈上记录 ABI: 源槽数组 = CModifier 对象
基址逐个, 惰性 get-or-compute sub_140C0D8A0/DA10 → 逐源累加步 sub_1409D1010 (走 §4.3.8
取值原语 sub_14055E360 + 格式化 sub_140559C30) → pdx_optional 缓存); 聚合 = 身份排序去重 → **值升序最强者满额、其余 ×
STACKING (qword_1433380E8)^k 递减**。消费链: ① 网强度目标 = sub_1411F3C80
→ **sub_1411F3A50 = clamp(Offset qword_143336300 + Factor qword_143336238 ×
CIR/1e5, 0, 1e7)** (无 so 兜底 1e7) → sub_1411D1260 逐 subnet 直写
**subnet+64/72/80 = {目标+per_op, per_op, 目标−Offset}** (per_op =
qword_143336088 × 特工数); ② defense (ag+296) = sub_140FDF110 = CIR +
LOG_FACTOR × ln(CIR+1)/1e5 (ln = sub_1424EF9D0 定点自然对数), DIVISOR
qword_143338328 三分支。新字段: subnet+64/72/80 / COperativeLeader+1032 修正
块 / +288 排序键 tag。

机构 hourly (country hourly pass⑥, sub_140FDD500): ① ag+216 特工逐个维护 +
state==3 ∧ type==0 → 归位; ② **defense (ag+296) 重算 sub_140FDF110** = clamp
(网强度 × qword_143338240 + 强度/100000); ③ **特工槽重算 sub_140FDF210**:
ag+240 max 重算 (sub_140FD7E30), **ag+244 usable = min(旧, 新 max)**; usable
== max → ag+248 elapsed 清 0; 超编 → 现役−usable 逆序解雇 (在 op 上先
RemoveOperativeFromOperation sub_1411A1550 → retired 池) (定案)。

机构 daily (sub_140FDBD60): ① in_creation (ag+193) → upgrade_progress ag+200
+= 产能 → 阈 100000×dword_143335600 → 建成 sub_140FDBA00; ② 升级中 (ag+208)
→ 阈 100000×dword_143335680×(mdef555+1) → sub_140FD78D0; ③ max>usable →
ag+248++ ≥ 下一槽天数 (sub_140FDD160) → ag+244++; ④ ag+256 = max(旧,
Σ控制州抵抗镇压值); ⑤ 尾步 → 密码学 (定案)。

**密码学日进度 CCryptology::DailyUpdate sub_1413F71D0** (机构 daily 尾步):
门 = mdef529 crypto_department_enabled ∧ crypt+52 count>0。① 解密中条目 (+18
旗) 停止清理 (目标==owner / 目标亡 / 关系判定); ② 剩余天数 = 100000×目标防御
(sub_1413F7C60) / (100000×我方力度 sub_1413F6CA0); ③ 逐条目 days(+12) −1 →
≤0 → −1 + 停止 + sub_1413F8D80; ④ 玩家国条目分母 = CRYPTO_BASE
(qword_143333030) + PER_UPGRADE (qword_1433330F0) × mdef528 目标等级;
⑤ **sub_1413F6820: +24 进度分子 += 日增量 clamp 阈值; 到阈 → +40 = 完成日,
未到 → +40 = 43808760**; ⑥ 完成判定 sub_1413F8740 (+16 全解密旗 ∨ 分子≥阈)
→ 解密关系 + 解密完成事件 + 玩家国弹窗 **CRYPTO_ENEMY_CRYPTO_IS_BROKEN_
TITLE/_DESC** (定案)。

COperation def (idb qword_14332EFA0, 56B 桶) 新字段: +328 base_duration /
+472 operative_slots / +480 on_success 效果 / +568 on_fail 效果 / +588 成功
判定触发器 / +856 allowed 触发器 (失效删 op) / +1232 on_start 通知 /
+1264/+1272 资源系数/旗 / +1312 特工经验值 (定案)。COperationInstance 运行时
字段: +48 civ 累计 / +56 总需求 / +192 失败旗 / +193 检测旗 / +208 prepared
时刻; sizeof 408B (malloc 直证); **三枚 24B date cell** (+104 开工时刻 tok 10314 / +136 / +200 prepared tok 19363; 每枚 = {CGameDate vtable 0x1427183A8 值@+8 + 序列化次子对象 vtable 0x1427183D8 8B 值域 this−8}; +136 cell② 无键无写者 — 精化: 原「+136..159 第二 CGameDate 域」系 cell 误读)。CCountryOperationManager (ops = *(cc+5544),
sub_14022FFF0; **vtable RVA 0x2A77578 活体直证**): +80 工厂需求聚合 (定案)。
⚠ idb 池 `qword_14332EFA0` (117 条目, arr@+64/cnt@+76 读法) **条目 vtable
0x2BCEAB0/0x2BCEC50 不在 vt_rtti、非 COperation 主表 0x293F2D8**, 条目头
120B 无 COperation\* 槽, +8/+1168/+1200 读串均空 — 池条目身份待裁
(候选 = 副表形态/包装条目), 「COperation def 实例」的取数仍走 GUI 行 +2736
或 instance+72, 勿直取本池条目当 def 本体。word_14332F623 = instant 旗
(行为定案; 写者未定位)。

#### 4.11.23 operationinstance.cpp 簇对账增补 (行动实例运行期; 7 函闭环)

清册 (7/7 函体内含 operationinstance.cpp 路径锚): Complete 0x141403780 (895, 到期判定 = 函数头
返回 bool; 精化 = instant 观测 tag 后备槽 gs+1316 / 音效 operation_complete 经 qword_14332F698 槽31 /
:540 on_action 未定义 = 错误日志) / 主 vtable[4] reader 0x141402770 (526, **19 键分发表全定**; 含 15646
特工快照循环 / 19472 列表解析 / "slot higher than room" 堆串) / StartOperation 0x141400170 (314,
书五步互证; def+384 启动尾多态槽+96) / 全参 ctor 0x1413FE940 (236, def 查表走 qword_14332EFA8;
:152 FATAL ERROR; def+472 槽扩容 1.5×) / AssignOperativeToSlot 0x1414032D0 (147, 「running op
不夺特工」门 = sub_140C0EC00 绑定反查 + 工期≠0 短路) / ClearOperativeSlot 0x1413FFFB0 (40,
哨兵重置 + optional 毒值 move-assign + 资源重算) / TryStart 0x141404880 (27, CanStart →
StartOperation; 失败 "Failed to start an operation: %s" = 书 auto_commence 执行体)。

**三库定性** (TGameItemDatabase 同布局三实例, 定案): **qword_14332EFA0 = 名字键 on_action 注册库**
(本 CU 全部用法 = 名串查 on_action + 发射, on_operation_completed/on_operative_detected_during_operation
— §4.11.18 池条目身份待裁项高置信闭合: 该池条目 = on_action 包装, 非 COperation def 本体, 原「勿直取」
警示维持) / qword_14332EFA8 = **operation def 库** (RH: data@72/mask@84/extra@88, 条目 56B) /
qword_14332EFB0 = **phase def 库**。第二子对象 vtable = 0x1429BE628 (PE RTTI 同名 COperationInstance;
主 vtable 0x1429BE5D0 直证)。def 消费点新增: def+8 (键/名) / def+384 (启动尾多态槽+96) / 效果块槽
+80 出文本/+96 fire。

未决: cell② 语义 / 次子对象确切类名 / qword_14333D528 哨兵运行期填装 (推定 {-1,-1}) / def+384
脚本语义 / instant 旗写者 (维持未定位)。

#### 4.11.19 雷达情报日结 (CRadarsPool::UpdateIntel; radar.cpp 5 函闭环)

清册 (5/5 函体内含 radar.cpp 路径锚; 与 §4.2.9 序 5④ 伴随日结 thunk sub_140716510
对接闭合, §4.11.5 radar 挂载的消费侧本体):

| VA | 行数 | 身份 |
|---|---|---|
| 0x1410A99A0 | 932 | CRadarsPool::UpdateIntel() 日结本体 (:812 日志串直证) |
| 0x1410A5810 | 536 | CConvoyClient::CollectCoveredConvoyRoutes (radar.cpp 内定义; lambda mangled 名直出) |
| 0x14109D110 | 339 | IntelForCountry 双有序源归并累计 (:839 断言名直证) |
| 0x1410A5140 | 333 | 海省情报按目的 tag 分配步 (:202/:218 断言) |
| 0x1410A83F0 | 184 | CRadarsPool::Init (:680 "already initialized", pool+52 计数为门) |

**双通道模型** (定案): 陆份 = 有主省按控制国聚合 — 每条目 factor =
RADAR_LEVEL_INTEL_FACTOR × 等级合计, share = 因子/最大级, cap = 控制省占比 × share,
每覆盖省 per-prov = 1e7×cap/(1e5×覆盖省数), 省内多站以 RADAR_INTEL_STACKING_FACTOR
归并; 国家级 share2 = val2/受控省数, 四象限 = COUNTRY_COVERAGE_PERCENTAGE[i]×share2/1e5
+ COVERED_LAND_PROVINCES[i]×(val1/100)/1e5。海份 = 无主海省 (desc+210 & 3 == 0 门)
按战略区聚合 → CollectCoveredConvoyRoutes 拆到目的 tag: 区权重 = 区+36 × 区+160 (≤0 =
:325 断言「非海区却有护航路」), 组 share × 区覆盖占比 × COVERED_SEA_PROVINCES[i] 累进 +
NAVY_PER_SHIP_TYPE[i] 加权舰船计数归一累进; 自 tag 组 = :218 断言整组跳过。掷骰无 —
纯累进。

**静源登记** (定案): pool+72 = RADAR 静源引用, **池槽号 = 3** (sub_140D03550(…, 3)
三站点直证 — §4.2.9 序 5② 的 4 槽列举系 define 表序非池槽序); 引用 {tag@+8, 槽@+12},
失效经 sub_14197F040 检查惰性重建。归并 sub_14109D110 = 双数组按别名规范化 tag 序
(sub_140BB5490) 归并, 同键四象限求和一次登记; 登记原语 sub_1411AEA40 对已存在键 =
**覆写 32B 值非累加** → 尾部零值扫过 = 清触碰键旧值 (最终确认待运行时对拍)。

CRadarsPool 布局消费点增补 (§4.3 256B 布局互证无冲突): +16 int 数组 (Init resize 到
gs+748) / +40 条目指针 vector (+52 = 计数兼初始化门) / **+64 owner tag** (省+392 别名
比对) / +96/+120 日结输出容器 / +144/+168 陆/海结果数组 (swap 换入)。112B 条目补行:
+24/+48 双 24B 数组 (Init 置空, 填充方未决) / **+80 雷达距离** (RADAR_RANGE_MIN/BASE/MAX
按等级合计插值) / **+88 等级合计** (Σ 建筑 def i16@66) / **+104 本国控制省占比**
(sub_1409D4190; 47F0 门 > 0)。defines 全对名: RADAR_LEVEL_INTEL_FACTOR 0x143336A30 /
RADAR_INTEL_STACKING_FACTOR 0x143336B08 / 四组 BASE_INTEL_VALUES (COVERAGE_PERCENTAGE
0x143336BE8 / COVERED_LAND 0x143336CA0 / COVERED_SEA 0x143336D68 / NAVY_PER_SHIP_TYPE
0x1433390A0, 均 4×i64 数组对象) / RANGE 三槽 0x1433340C8/040/178 / 四槽
STATIC_INTEL_SOURCE_*_MAXIMUMS 0x143339238/250/268/280 ({begin,end} 容器形, 载 0 或
4×i64)。⚠ 文件像里 define 槽呈运行期改写前形态, 数值不可直读。

未决: UpdateIntel 第二形参真身 (rdx, 海路全程依赖) / 区+36×+160 乘积业务名 / 区分组
记录 40B 步进 vs +40 权重读矛盾 / 条目+24/+48 填充方 / 零值扫过最终语义 / 24B/区记录
4×i64 含义 (待 CConvoyClient 域批次) / gs+748 业务名 / pool+96/+120 读者。

#### 4.11.20 敌军规模估计器 (countryintelhelper.cpp; 陆/空/海/库存同族四家)

UI「敌军规模区间」显示的引擎侧同源。`sub_141432940(out i64×2, observer_tag*, target_tag*)` = 陆军规模 {lo, hi}; `sub_14142F500(同形)` = 空军联队 {lo, hi}; 区间计算核 = sub_14142EB50 (断言 countryintelhelper.cpp:118/120 "MinValue <= Value"/"Value <= MaxValue")。

| 步 | 机制 |
|---|---|
| 1 满情报捷径 | tag 相等 ∨ 同 idx ∨ 同源国深查 (sub_140700600/140700670), 或 **!byte_14332F63A → intel 比 = 1** (四估计器陆/空/海/库存同形直证 `if (!byte_14332F63A) v = 1` — 旗 == 0 时满情报; 原记方向相反已改; 旗写者未查, 常态值推定 1) |
| 海军估计器 | **sub_14142FBD0 (第三成员补齐)**: intel = sub_140D045C0 返回 +16 navy 象限 / 上限 = qword_1433390B8 [2] / 抖动种子 = region_id + 1361 (陆 1140 / 空 1280); 区间核同 sub_14142EB50 — §4.31.106 消费 |
| 库存数量估计器 | **sub_141430A30 (第四成员, 本批新定性 — §4.11.20a)**: intel = sub_140D045C0 返回 **+8 陆军象限** / 上限 = qword_1433390B8 [1] / 抖动种子 = +**1174** (陆 1140 / 空 1280 / 海 1361 之外第四值); 区间核同 sub_14142EB50; defines = ARMY_STOCKPILE_COUNT_INTEL_{MIN=qword_143332678, MAX=qword_143332738, RANGE_AT_LOWEST_INTEL=qword_1433327E0}; 出参 known = (比例 ≥ MIN), 低情报时 GUI 显示 "?" — 情报账本 Army 页装备库存行消费 |
| 2 intel 比 | `1e5 × intel 值 / 上限`; 陆军 intel = intel 管理器 (sub_140D045C0) 返回+8 / 空军 +24; 上限 = COUNTRY_LEVEL_INTEL_MAXIMUMS (qword_1433390B8) [1]/[3] |
| 3 区间 | 折减 `t = clamp(1e5×(intel比−MIN)/(MAX−MIN), 0, 1e5)`; 噪声幅 = `base×(1e5−t)/1e5` (base = RANGE_AT_LOWEST_INTEL) |
| 4 确定性抖动 | 种子 = {1140 (陆) / 1280 (空)} + 月计数器 (sub_140177650 读 gs+1120, 0-based) + 12×年 + 实际值 + gs 计数器 (sub_1401DB340); CRandom 常数族 %1e5 → dither ×幅; 出参 = (Q15+0x4000)>>15 取整两 int |

| 域 | defines (MIN/MAX/RANGE_AT_LOWEST_INTEL) |
|---|---|
| 陆军 | ARMY_ARMY_COUNT_RANGE_INTEL_{MIN,MAX,RANGE_AT_LOWEST_INTEL} = qword_143331DF8 / 143331EB8 / 143331F88 |
| 空军 | AIR_AIRWING_COUNT_INTEL_{同三} = qword_143333B98 / 143333C30 / 143333CE8 |

主消费 = AI 相对军力评估 sub_1406E9BF0 (geography\country.h 内联, §4.34): 分母 = Σ 交战国 (dip+152 缓存) 两估计器四累加; 分子陆军 = `1e5×(cc vtable 槽 9 返回国)+668 师数` + Σ 同阵营邻国 (dip+176 战争同盟缓存 × 邻居位图 cc+4208/+4220 门) 同估计器; 分子空军 = 自身空军估计首输出 (同国满情报捷径 = 精确值); `OUT = 陆军 lo 比 + |hi 比 − lo 比|/2`, 空军 max 比 > 1e5 → +10000 (空优 +0.1); 分母 ≤0 → 默认 1e5, 加法溢出护栏 → −1。门 = `OUT ≥ RELATIVE_STRENGTH_TO_INVADE` (qword_1433326C8)。**CCountry vtable 槽 9 (+72) = 国家对象解析器** (返回带 tag@+8/师计数@+668/邻居位图@+4208/diplo@+3976 的 CCountry, 常规国家返 self; 存在意义推定 = 内战/tag 换源时原初国解析, 与 cc+4876 original_tag 概念同族)。未初始化邻居位图断言 geography\country.h:1776 "Asking if %s is a neighbor of %s before the latter country is initialized" + :1778 一次性警告 (byte_14332FC62 门)。同阵营邻国可达谓词 sub_1412EFED0: 存在 X ∈ 己邻居列表#1 (cc+4232/4244) 使 X 阵营 == 己阵营 ∧ 目标 tag ∈ X 的邻居位图 — AI「可援助/驰援国」评估复合件 (与敌国判定/阵营成员判定/AI 策略求值 sub_1406CF0E0 vtable+32 组合)。

#### 4.11.20a 情报账本 Army 页装备库存行 (countryinteledgerview_army.cpp; 填充器 0x141EB6A70 394 行)

库存行填充器 (entry Setup; 无 RTTI/串名锚, 按文件域与消费链定性); 唯两调用点 = 通用列表填充模板 sub_141EAC400 / sub_141EACC60 (std::map 32B 值数组 → 排序 → 逐元 malloc(0x60) 行件 + ctor sub_141EB1170 → 调本函; 与 §4.11.25「GUI 上下文工厂 qword_14332F698+1272 绑行」同款)。断言 countryinteledgerview_army.cpp:527 "pBestVariant" (B52, 闩 byte_14338C94A) + gamestate.h:1125/1126 卫。

行件对象 (96B, sizeof = malloc(0x60) 直证; ctor sub_141EB1170):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | uint32 | 目标国 tag (经 sub_140BB48F0 → gs+784 国表解析) |
| +40 | CEquipmentVariant* | 行变体 (载荷 a3[0]) |
| +48 | CEquipmentType* | 行装备原型实例 (载荷 a3[1]; 须为 archetype) |
| +56 | fixed×1e-5 | 计数分量 A (载荷 a3[2]) |
| +64 | fixed×1e-5 | 计数分量 B (载荷 a3[3]) |
| +72 | MSVC std::string | 行名称串 |
| +80 | MSVC std::string | 行计数文本串 (未知态 = "?") |
| +88 | 图标件指针 | 装备图标件 |

载荷结构 (32B, 上游 std::map 节点值, 节点+40/+56 两段拷贝直证): CEquipmentVariant*@+0 / CEquipmentType*@+8 / fixed×1e-5@+16 / fixed×1e-5@+24。两分量**分别过估计器后求和** (非先和后估); 业务拆分 (推定 = 库存/在产两路) 属上游 map 属主语义。

名称串 (+72) 两路:

| 分支 | 条件 | 构造 |
|---|---|---|
| 原型路 | 载荷+8 (type) ≠ 0 | `"<tag名>_<型名>"` (tag 经 sub_140BB4E70, 型名 = CEquipmentType+24 SSO) |
| 变体路 | type == 0 ∧ variant ≠ 0 | sub_140BDA540(variant, out, 1): 自有名 (variant+40 SSO) 非空 → 直用; 否则按 variant+28/+32 idpair 解 tag 拼同形 (型 = variant+1008 _pType, 名@型+24) |

图标 (+88) 三路:

| 分支 | 条件 | 贴图解析 |
|---|---|---|
| 最佳可产变体 | type ≠ 0 ∧ 查得 pBestVariant | sub_140B46320(工厂, icon, pBestVariant, "_medium") → `GFX_<变体名>` (兜底 "GFX_default"); 失败 → sub_140B45D90 按型回退 |
| 原型兜底 | type ≠ 0 ∧ pBestVariant == 0 | sub_140B45BC0(工厂, icon, type, "_medium"): 贴图名 = `"GFX_" + "_medium"`, 经工厂+184 容器存在性判定 |
| 变体路 | type == 0 | sub_140B46320(工厂, icon, variant, "_medium") 同上变体链 |

> pBestVariant 查找 = sub_140E68E40(ps, type): ps = *(cc+3944) CProductionStatus; 扫 ps+184 运行时容器 (元 = CEquipmentVariant*, 计数@ps+196), 匹配条件 = `*(*(variant+1008) + 1240 基原型) == type`, 多命中经 sub_140BD2430 择优; 空结果 + 断言门开 → :527 后走原型兜底。与 §4.8 所记「最佳变体 getter ×2 (68E40 扫 ps+184 / 68410 扫 ps+160)」一致 — 本批补其第三消费点。

计数文本 (+80) = 库存数量情报估计器链 (§4.11.20 第四成员): 玩家 tag 槽 = `(gs+1312 > 0) ? gs+1312 : gs+1316`; 两计数分量**分别**过 sub_141430A30 (out u32×2, 玩家 tag, 目标 tag, 分量/1e5, 种子, 0, &known) 后求和; known == 0 → "?" ; lo == hi → 单值 ; 否则 "lo–hi" (千分位 + 分隔符)。种子 = type+1336 (原型下标) 或 variant+12 (id)。

#### 4.11.21 intelligenceagency.cpp 簇对账增补 (机构运行期; 15 函闭环)

清册 (15/15 函体内含 intelligenceagency.cpp 路径锚): CaptureOperative 0x140FDAAE0 (392) /
reader 键分派 0x140FDDA00 (346) / AddUpgrade 0x140FD78D0 (251, def+540 上限 + 总级数断言) /
captured 日结 0x140FDEC70 (213) / gfx 编译失败抛异常助手 0x140FDB3E0 (203) / Reset 全清
0x140FDB6E0 (171) / on_operative_death 发射 0x140FDD7E0 (104) / AddOperative 槽位感知版
0x140FD7480 (96, 满 → recruitment 池+析构 / 空 → +216 直挂) / ClearCapturedOperatives
0x140FDE010 (91) / StartCreation 0x140FDE7C0 (89, 双旗互斥断言) / AddOperative 直挂变体
0x140FD76A0 (87, 招募完成通道) / StartUpgrade 0x140FDE9C0 (86) / RemoveOperative
0x140FDE3D0 (75, 任务反注册+被俘同步摘俘方) / ReleaseOperative 0x140FDE270 (65) /
FakeOperativeDeath 0x140FDC700 (64, +252 计数++, 调用者 = turn_operative 效果)。

**序列化面** (PE 直读 vtable 0x142981F68, 9 槽; §4.00.1 槽位通则实测成立): [1] wrapper /
[2] writer / [3] wrapper / **[4] reader = 0x140FDDA00 (书原缺, 本批钉死)** / [5] PostLoad 桩;
紧邻 0x142981FB8 = CCapturedOperativeReference vtable ([2] writer 0x141A34FF0 / [4] reader
0x141A34F40)。**reader 16 键全表**: 27 name→+128 / 181 icon→+160 / 10319 building→+256 /
10836 defense→+296 / 12393 upgrades→+96 {def*, count} 16B 元 (重复计数累加, 未知名错误
日志; 支持 '@' 变量引用形) / 15356 在途升级→+208 (无效旗 def+16 清槽) / **15635 captured
→+264 (reader 0x140FD6CB0, 56B 元)** / 15667 is_created→+192 / 15668 in_creation→+193 /
15669 upgrade_progress→+200 / **19068 cryptology→+288 (CCryptology 整块)** / 19296
own_operative_death→+252 / 19345 max_operative_count→+240 / **19464 recruitment→+8
(COperativeRecruitment 块)** / 19488 usable_operative_slots→+244 / 19489
elapsed_days_for_next_slot→+248。

**捕获链** (定案): 收益 = define CAPTURED_OPERATIVE_INTEL_YIELD (四象限) × MIN/MAX_FACTOR
受控随机因子 (random_fixed, %1e5) + on_operative_captured 事件 (56B 元入列)。被俘日结:
关押剩余天数 = dword_14333347C + (op+4032 − 43800000)/24 − 今日; 每日四象限入情报源池
(入账 sub_140D026F0, 源池 +184, 56B/kind, kind=6); 营救门 = def+66 清 ∧ def+88 目标=属主
∧ *(def+72)+1129 置; 期满摘除。

**调试开关钉名**: byte_14332F62D = **Agency.AutoComplete** (即时完成建局/升级分流) /
byte_14332F62E = **Agency.KeepExcessOperatives** (槽满仍直挂)。命令 Execute 补钉: 建局 =
0x141A27C00 (双旗 word 写 +192=1/+193=0)、升级 = 0x141A27CF0 (§4.33 补行)。

**COperative 运行期锚束** (消费点定案): idpair@+8/+12 / 属主 tag@+36 / 名 SSO@+64 /
tag@+288 / 关押日期@+4032 / 状态枚举@+4224 (5 = Killed)。op+288 与 +36 两 tag 分工待裁 — 0x1411F99B0 以 op+288 作宣传漂移的分组键与应用键 (宣传作用对象为国家); **op+288 = tag_id u32 (0=空) 定案** (0x1411F81A0 `*(int*)(op+288)>0` 门 → GetCountry sub_140BB48F0(tag→CCountry*) 链直证, 对象指针读法排除; 「任务所在国 vs 归属国」语义仍待裁)。

未决: sub_140710B20 是否含入账 / captured reader 元素键表 / dword_14333347C 的 define 名 /
sub_140C185E0 (+4016 统计, token 545/546) 语义。

#### 4.11.22 countryintelnetwork.cpp 簇对账增补 (谍报网运行期缓存链; 8 函闭环)

清册 (8/8 函体内含 countryintelnetwork.cpp 路径锚): PrepareSubNetworkCache 0x1411D1260
(590, λ 名直出) / 单州强度增长 tooltip 构建器 0x1411D2EF0 (590, 唯一消费方 = §4.35 情报
网络巨函 sub_140E10910) / **CacheSubNetworksStrength 0x1411D63A0 (207, §4.11.18「全量
重算」实名; 九步链补全含两条书未载调用边)** / PrepareSubNetworkCache λ 体 0x1411D07A0
(186) / subnet 三修正聚合器 0x1411D3EC0 (158, coverage_per_occupied 占领占比加权
mdef532/535/538) / CGainPostProcessor::operator() 0x1411D7050 (77) / TopologyClient 槽[2]
谓词 0x1411D4F00 (38, 州 controller == 网目标国) / 槽[1] 收省 0x1411D4720 (33)。

**运行期缓存链定案**: net+144 覆盖 map 运行时写者 = PrepareSubNetworkCache (v92 swap);
**+240 反查表装填者** = λ 体内 sub_1411CB620 (表基 net+232); **subnet+8/16/24 = 运行时
重写槽** (聚合器 0x141208260 首次重算即覆盖 loader 值 — 存档 token 名 own_* 与运行时数据源
mdef ENEMY_*_OVER_OCCUPIED_TAG 不同名同槽, 两侧语义关系未决)。CGainPostProcessor 机制 =
增益钳到目标缺口 / 超目标按 DECAY define 回落。**谍报网静源池槽号 = 4** (与雷达 = 3 互证,
§4.11.19); 海军象限独占「目标省在网内」门。拓扑五 define + 交付四 MAX_*_INTEL +
OCCUPIED_TAG 双权重 define 全具名 (findings §2)。

未决: mission 过滤门语义 / SetStrengthInAllStates 外层函数 / subnet+112 业务名活体对拍 /
0x1411D2EF0 出参 136B 逐字段 GUI 复核 / subnet 修正槽读者侧全景。

#### 4.11.24 countryintel.cpp 簇对账增补 (静态源引用链与钳位累加; 10 函闭环 — 4 函互证 + 6 函新定案)

簇清册 (体内 cpp 锚 10/10; 4 函书已收 = §4.2 序 5 备注 + §4.26 调用行, 本批逐函互证吻合):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_140D05260 | 339 | :302 + :98–112 (11 条错误日志, define 名直证) | 静态上限表打包 440B | 已收互证 (机制名词 = 格式化错误日志 sub_1424C8950+8E60, **无中断** — §4.2 勘误行同源) |
| sub_140D04D70 | 229 | :157–162 (6 条错误日志) | 动态绝对上限表打包 336B | 已收互证 (同上) |
| sub_140D02EB0 | 42 | :391 "_Owner.IsValid()" | 资源观测基准 (mdef 549–552) | 已收互证 |
| sub_140D05BE0 | 45 | :302 | INTEL_COUNTRY_LEVEL_MAXIMUMS 归一 4 元 + 静态缓存刷新 (**无参**; 监听器遍历在 dispatch 调用方 — §4.26 调用行已加注) | 已收互证 (本体边界补全) |
| sub_140D04430 | 53 | :302 | 上限快照读取器 (懒归一 + 出参拷贝) | 新 |
| sub_140D04610 | 61 | :772 / :780 / :787 | CStaticIntelSourceReference → 池解析器 | 新 |
| sub_140D066D0 | 61 | :567 / :815 | 引用 → 源 → 四象限入账链 | 新 |
| sub_140D05A00 | 61 | :20 "Invalid country index in intel source" | 钳位四象限累加原语 | 新 |
| sub_140D042A0 | 61 | :640 "_IntelFromAlliesOverOthers.IsEmpty()" | 盟友对他国情报矩阵读取器 | 新 |
| sub_140D03D40 | 156 | :815 (经 04610/自身) | 引用 → 源覆盖国家 idx 列表收集器 | 新 |

**上限表归一与快照** (sub_140D04430 / sub_140D05BE0 共享归一体): 全局 define 数组 {data qword_1433390B8, cap dword_1433390C0, count dword_1433390C4, alloc qword_1433390C8}; count != 4 → :302 错误日志 ("Expected INTEL_COUNTRY_LEVEL_MAXIMUMS to contain 4 values") → 懒扩容 (max(count×1.5, 4), 分配器 vtable[2]/vtable[4]) → 缺位 **memset 0x186A0 = 100000 (缺省定值直证)** → count 钉 4 → 刷新静态缓存 xmmword_14333CC58 / 14333CC68 (4×i64 快照)。04430 另拷快照入出参; 消费方 = sub_141420610 四象限比较器 (compare_intel_with / intel_level_over 的百分比归一基数) + sub_14023CB70 + sub_140FDBD60。

**静态源引用解析器 sub_140D04610(ci, ref, strict) → CStaticIntelSourcePool***, 三重校验:

| 门 | 条件 | 失败 |
|---|---|---|
| :772 "Reference applied to the wrong owner" | ref+8 (tag) == ci+8 (owner tag), 或同 tag 伴随 (sub_140BB52F0) | 返 0; debug 门断言 (闩 byte_14333CC7C) |
| :780 "Reference might have out-lived the country" | ref+20 (世代 id) == *(ci+208) (国家世代戳); strict = 0 时静默返 0 | strict ∧ debug ∧ 未闩 → 断言 (byte_14333CC7D) |
| :787 "Invalid pool referenced" | 0 ≤ ref+12 (池号) < *(ci+172) (池数) | 返 0; debug 门断言 (byte_14333CC7E) |

命中 = *(ci+160) + 72 × 池号 (ci+160 static_intel_pools 72B/元, §4.11.7/4.11.8 互证)。引用布局: {+8 tag, +12 pool idx, +16 source id, +20 世代}。

**引用消费双通道**: ① sub_140D066D0(ci, ref, tag 槽, out): 04610 解析 → sub_1411AD810(池, ref+16) 取源 → 失败断言 :815 "A reference somehow outlived the intel source"; 解析失败 :567 "Invalid intel reference, intel values will be dropped" (**情报值静默丢弃, 仅 debug 门日志**); 命中 → sub_1411AEA40(源, tag 解析 idx 或 0, out) 四象限入账 (tag 槽空 = 无 tag 过滤全收)。消费面 6 函: sub_14109D110 / sub_1411D6830 / sub_1410A99A0 / sub_1414079B0 / sub_14023CB70 / sub_1413F8EF0。② sub_140D03D40(ci, out 向量, ref): 04610(strict=1) → 取源 → 遍历源内 40B/国条目 (步进 40, 首 dword = key 国家 idx) 收集 idx 列表 → sub_140155CD0 移入出参; 任何失败 → 空向量。消费方 = countryintelhelper 估计器域 (sub_1410A99A0 / sub_1414079B0)。

**钳位四象限累加原语 sub_140D05A00(idx, 入 4×i64, 上限 4×i64, 累加器矩阵)**: idx 越界 (<0 或 ≥ 累加器+12 count) → :20 断言 (闩 byte_14333CC50) 丢弃; 否则 32B/国槽 (累加器 data + 32×idx) 逐象限 += min(入, 上限)。唯一调用方 = **sub_140D02C30 逐国计算核** (§4.2 序 5 — 上限钳位就发生在逐源累加处)。

**_IntelFromAlliesOverOthers 读取器 sub_140D042A0(矩阵宿主, 出 32B, tag)** (成员名断言直证): tag → idx (sub_140BB5490), idx 合法且 count (宿主+52) > 0 → 拷 *(宿主+40) + 32×idx 4×i64; 否则全零。越界且非空断言 :640。唯一消费方 = **情报 tooltip sub_141E9CAF0** (§4.2 序 5 tooltip 双消费点之一)。宿主身份未定名 (推定 CCountryIntel 运行时扩展或伴生结构); 写入者不在本簇 (推定 intel daily 管线 sub_14109AEA0 族)。

未决: _IntelFromAlliesOverOthers 宿主类与写入者 / sub_140D04D70 缺省哨兵 92233720200000 复核 / DYNAMIC_ABSOLUTE 六 define 全名序列抄录。

#### 4.11.25 COperationOverviewWindow 运行期 (operationoverview.cpp; 3 函闭环 — Setup 26 元素 / Load / SetOperativeSlot)

簇清册 (体内 cpp 锚 3/3):

| 函数 | 行数 | 体内锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_14182EEF0 | 579 | 断言 :166 "Window already created." (B51, 闩 byte_14338B1A2) + 26 元素名串 | **COperationOverviewWindow::Setup** (窗创建 + 全元素绑定; 重建式刷新) | 已收 VA 称「刷新器」, 本批定性 + 名称直证 |
| sub_14182C990 | 134 | 错误日志 :708 "Fatal error. Called COperationOverviewWindow::Load with invalid operation" + :714 | **COperationOverviewWindow::Load(spec)** — 函数名由体内错误串直证 | 已收 VA ("opener"), 机制全互证 |
| sub_14182EBF0 | 61 | 错误日志 :260 "Invalid SlotId %d for operation instance" | **SetOperativeSlot 形槽位干员指派写入器** (非弹窗 — §4.33 称谓已改) | 新定性 |

**Setup 26 元素绑定** (win = COperationOverviewWindow; 门 win+88 已有窗 → 断言后走 Reload 槽 vtable+16): +88 operation_overview_window 主窗 (*(win+72)+1272 工厂) / +96 btn_close (→ CDeleteOperationCommand) / +5472 duration_progressbar_container / +5480 cb_auto_commence (glue +5248) / +5488 cb_auto_repeat (glue +5360) / +5512 btn_location / +5520 btn_refert (一体绑定 sub_140F237D0, observer +3960) / +5528 btn_target_flag / +5536..+5568 五文本件 / +5576..+5616 七图标与进度条件 / +5624..+5648 四格 (operatives/phases/phase_titles/resources_grid)。win+72 = GUI 上下文单例指针 (与 CFleetsBottomBar bar+48 同款); sub_140F237D0 = 按钮+observer 一体绑定原语 (参序: glue, 父窗, 名串, observer, owner)。

**Load** (sub_14182C990; (win, spec)): spec = {+0 tag, +8 阶段 def 指针数组, +32 内嵌 COperationResources, +64 def ptr, +72 有效旗}; 门 1 = 有效旗 0 → :708 (函数名直证处); 门 2 = gs+1312/+1316 均 ≤0 → :714 (**gs 全局 = qword_14332F260**, gamestate.h:1116/1117 断言对)。写入 = win+5856 tag / +5864..+5876 阶段表 / +5888 资源块 / +5920 def / +5928 有效旗 / +5936 已选择 = 0 / +5940 idpair = 哨兵 qword_14333D528; **12B 元向量池 {d@+5824, n@+5836} 按 *(def+472) (阶段数 u32) 扩容** 逐元清零 — 与书 12B 元 {leader idpair, resume_mission} 全互证; 尾 sub_14182D4D0 触发刷新。

**SetOperativeSlot** (sub_14182EBF0; (win, leader, slot_id, out idpair*, resume_mission)): 门 slot_id < win+5836 槽计数 (越界 :260); 校验 win+5940 非哨兵 → resolve 必须 == leader; 写 12B 元[slot_id] = {idpair, resume_mission} → sub_14182EA50; **基类区写点 = 遍历全元统计 resolve 成功数 → win+80 = n / win+84 = 1 (已指派计数/旗, 读者未查)**。

未决: win+80/+84 读者 / spec 双串语义 (§4.25.8 同名件无关联)。

#### 4.11.26 COperativeViewEntry 特工行视图 (operativeviewentry.cpp; 2 函闭环)

簇清册 (RTTI/锚 2/2):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141E40AB0 | 721 | RTTI `COperativeViewEntry::vftable` 直出 + :400 断言 "Calling AttachAsSubWindow on a null window" (B52, 闩 byte_14338C883) | 特工行视图全件装配构造器 |
| sub_141E41C80 | 34 | :569 断言 "Calling attach to sub window on a non-initialized window" (B52, 闩 byte_14338C884) | AttachAsSubWindow (状态窗重挂接; detach 先行 sub_141E43770) |

**COperativeViewEntry 布局** (ctor 直证): +8 父视图 (+1272 元素工厂, §4.11.25 同款) / +16 idpair 哨兵 qword_14333D528 (§4.11.25 同一哨兵互证) / +24 串 / +56 基子对象 (点击回调 sub_141E441C0) / +1344 CTextBufferObserverGlue (vtable 0x142A82DF0 = ref/vt_rtti.json 互证; +1376/+1384 双 lambda) / **+1440 主子窗 operative_badge_view** (7 元素全在其上按名取) / +1448 agency_insignia / +1456 operative_code_name (+128 绑 glue) / +1464 deselect_button / +1472/+1480/+1488 operative_name/title/skill_level / +1496 CPdxScopedPtr 肖像窗 (2992B, operative_leader_portrait_window_small; 位置 = operative_portrait_pos 元素 +240/+244) / +1504 traits_grid 包装 / +1512 nationalities_grid 包装 (串常量 exe 直读定名) / +1520 CPdxScopedPtr operative_status_window (88B; accessor pdx_scoped_ptr.h:124 断言)。

**AttachAsSubWindow 契约** (sub_141E41C80): 门 +1440 非零 → detach 旧 (+1432: vtable+464/+224 释放) → +1432 = 窗 → 窗 vtable 槽 27 (+216)(名, badge_view+48) → vtable 槽 57 (+456)(badge_view); **挂接目标恒为 +1440 badge_view+48 (子内容锚点)**。上游 = sub_141835130 列表重建 (每特工建 entry → 挂 operative_status_window)。主 vtable 未入 ref/vt_rtti.json (仅 glue 模板在录, 待补录)。

未决: +56 子对象与双 lambda 行为语义 / 主 vtable VA 补录。

#### 4.11.27 谍报网源划分器 (subintelnetworkpartitioner.cpp; 1 函 — §4.11.22 缓存链的上游算法本体)

sub_141B1DDF0 (861 行; 锚 :23 断言 "The number of sources in the matrix does not match the number of sources in the array" B52 + 内联 pdx_triangular_matrix.h:143 "Matrix index out of bound"): `(out 组向量*, CPdxTriangularMatrix<int>*, 每源权数组*)` — 加权图 → 连通组划分。

**算法全定案**: ① 边表构建 = 全对扫三角矩阵 (三角索引: idx = 大 + 基 − (n−小)(n−小−1)/2 − 小 − 1), 权 ≥ 0 记边 (负权 = 无边); ② **stable_sort 升序** (12B 元归并: ≤32 插入排, 栈 4096B 阈值 341 条溢出 malloc); ③ **DSU 合并循环** (初始标签 iota, 组大小初值 = 源权): 阈值初 4, 升序扫边权 > 阈值即断; 异组且 **w ≤ 组权和 + 1** → 合并 (阈值单调抬到 max(阈值, 2×新组权+1), 置重扫旗); 有合并整轮重扫保留表直至无合并 — 断点尾段弃置 = 终态剪枝 (数学完备性未证, 待裁); ④ 组收集 = 标签压缩 → 每组一 int32 向量 (×1.5 扩容, MSVC 线程安全静态样板门)。

唯一调用方 sub_1411C1310 (传**全 1 源权数组**): 划分后逐源得组号 → 遍历 **80B/条 CLocalIntelNetwork 向量** (§4.11.3 互证) 以映射数组取源号回填组号 — **组号 = §4.11.22 缓存链的分组键, 谍报网按源亲和三角矩阵聚成若干子网**。

未决: 阈值剪枝完备性 / 边权业务量纲 (三角矩阵装填者未追)。

#### 4.11.28 机构升级库装载 (agencyupgrade.cpp; 1 函新定案 + reader 语义补充 2 点)

簇清册 (体内 cpp 锚 2/2):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_1406243A0 | 522 | :332/:354 错误日志 (4096) + gameitemdatabasehelper.h:35 断言 (B52, 闩 byte_14333048B) | **CAgencyUpgradeDatabase::Load (目录装载虚槽实现)** | 新 |
| sub_140625780 | 177 | :262 错误日志 (✓书) + gamestate.h:1125/1126 断言对 | 分支内升级注册 (reader) | 已收 §4.11.16, 本批补 2 点 |

**库对象布局** (a1; 库全局 0x14332EDC0 ✓§4.26): +40 升级 lookup (元 40B {SSO 名@+0, token id@+32}) / +64 升级对象数组 (元 8B = CAgencyUpgrade*, [0] = Null Object) / +88 分支 lookup / +112 分支对象数组 — **Array = Lookup+1 断言** (gameitemdatabasehelper.h:35 "(Array.GetSize() == Lookup.GetSize() + 1) … Null Object as Array[0]?") = TGameItemDatabase 族通用装载不变量 (§4.11.16 四容器归因已改挂库对象)。

**Load 流程** (sub_1406243A0): 扫目录 .txt (64B 步长文件列表) → 逐文件 pdx 解析 → 逐 top-level token: ① 分支注册 (线性查 +88 lookup; miss → malloc 88 建分支壳 push +112/+88; hit 且首装告警 :332); ② 调分支 reader (sub_140625780) 装分支内升级清单 → 本函再遍历清单逐元查 +40 升级 lookup (名 = def+24, id = def+56) — miss → push +64/+40; hit 且 v84==1 → :354 告警。**重复告警门 v84 = 装载前升级数组 count: 仅首装时报, 重载静默**。

**reader 补 2 点** (sub_140625780): ① hit 时**原地重跑 ctor sub_140622890 = 热重载语义**; ② gamestate.h:1125/1126 断言对 + gs+2617 战役活跃旗门 — 门过才报 :262 (读档外语境静默跳过)。

未决: 名登记内部 / 两子块读取器 (§4.27.5 同款疑问不适用此处 — 本簇无)。
