> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.11 情报—间谍系统 (谍报网 / 特工与特务专项 / 情报机构 / 情报账本与来源池 / 密码学)

> **本册范围**: 一个情报—间谍系统的全链 —— 谍报网侧 (§4.11.1–§4.11.10, 挂 `gs+1696`
> 谍报机构管理 + `cc+4072` intel 六矩阵) 与特务机构侧 (§4.11.11–§4.11.17, 挂
> `cc+4032` 机构 / `cc+5544` operations / `cc+5552` tokens + CCharacter 特工池);
> 两侧经同一对象链互指 (net+168 挂 `*(cc+5552)+16` 与 `*(ag+288)+16`;
> CCryptology = `*(agency+288)`)。

⚠ ci cheat 形态: **两类比定案** — CCountryIntel (vt 0x14295F188) +216 =
内嵌 CStaticIntelSourceReference (键 19457); CCountryIntelNetwork +216 =
strength_sum_over_cores; 全链无 vt 分流读取点, 按对象类各读各的。

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
| +28 | u32 | 网数组 容器计数 |  |
| +29..+95 | — | = **CLocalIntelNetwork 内联 80B 本体 (net+16..+95)** — net ctor `sub_1411BC870(a1+16)` 首行 `&CLocalIntelNetwork::vftable` (RTTI 0x1429a0408 实名) + writer ADEC0(0x3D1D, a1+16) + loader 同址三证; 图布局见下  |  |
| +96 | 匿名结构 (12B) | operatives 容器数据指针 — 顶点 | stride 12 {type@0, id@4, state@8} |
| +97..+107 | — | = operatives 容器尾 {cap@+104}  |  |
| +108 | u32 | operatives 容器计数 |  |
| +109..+119 | — | = operatives 容器尾 + subnets 前置  |  |
| +120 | CSubIntelNetwork* | sub_intel_networks 容器数据指针 | 元素 216B CSubIntelNetwork |
| +121..+131 | — | = sub_intel_networks 容器尾 {cap@+128}  |  |
| +132 | u32 | sub_intel_networks 容器计数 |  |
| +133..+143 | — | = subnets 容器尾 + max_coverage 前置  |  |
| +144 | 匿名结构 (40B) | **max_coverage_by_occupied_tag** 容器数据指针 — (0x4C00=19456), 元素 40B **{tag u32@0, pad@4, owned_worth u32@+8, states u32@+12, intel_network_gain_factor i64@+16, enemy_operative_detection_chance_factor i64@+24, enemy_operative_detection_chance i64@+32}** | c>0 |
| +145..+155 | — | = max_coverage 容器尾 {cap@+152}  |  |
| +156 | u32 | max_coverage_by_occupied_tag 容器计数 | c>0 |
| +157..+167 | — | = max_coverage 容器尾 + intel_source vt 前置  |  |
| +168 | CStaticIntelSourceReference 内联 | **intel_source** {vt@+168, idx@+176, pool@+180, id@+184, discriminant@+188} — 真图 = net+16 内联 (§4.11.3); +176..+191 = intel_source 四字段; writer ADEC0(0x4B34, a1+168), loader 19252 同址 | |
| +177..+191 | — | = intel_source 四字段本体 (idx/pool/id/discriminant) |  |
| +192 | uint32 | coverage.core_states — **GUI: 全国覆盖 tooltip** (sub_1411D2400/BD440; NATIONAL_COVERAGE 权重 define 三元组) | |
| +196 | uint32 | coverage.controlled_states — **GUI: 同上** | |
| +200 | uint32 | coverage.owned_worth — **GUI: 同上** | |
| +204 | u32 | **未初始化死槽 (堆残留)** — ctor 0X1411CF7C0 **不置零本槽** (只置 +192/+200/+208); 唯一写点 = 容器清场路径 sub_1411CFBE0 `*(a1+204)=0`; **全 dump 零读者**。探针「约半数网非零」= 分配器残留字节 (ctor 未初始化的直接推论), 非覆盖率分母 | |
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
| +16 | 容器 24B | 网数组 {data@16, cap@+24, count@+28, alloc@+32} — 8B CCountryIntelNetwork* 元 | 逐网 ADEC0 |
| +40 | 24B 槽 | **counter_intel effort 槽 (mission 3)** {ptr/旗@+0, u32@+8, count u32@+12, 多态对象*@+16} | — |
| +64 | 24B 槽 | **build_intel_network effort 槽 (mission 1)** | — |
| +88 | 24B 槽 | **boost_ideology effort 槽 (mission 5)** (assert "BoostIdeology array" 实名) | — |
| +112 | 24B 槽 | **propaganda effort 槽 (mission 8)** | — |
| +136 | 24B 槽 | **control_trade effort 槽 (mission 6)** | — |
| +160 | 24B 槽 | **diplomatic_pressure effort 槽 (mission 7)** | — |
| +184 | 环形缓冲 data | recent_propaganda_effort — 元素 40B {ws Q17.15@0, st Q17.15@8}, 写序 head→tail 模 cap | head≠tail |
| +192 | 环形缓冲 cap | recent_propaganda_effort | head≠tail |
| +196 | 环形缓冲 head | recent_propaganda_effort | head≠tail |
| +200 | 环形缓冲 tail | recent_propaganda_effort | head≠tail |
| +208 | 匿名结构 (24B 形状) RH 桶数组 | **trade_influence_modifier_of_buyers** (0x4B4A = 19274) {头@+208, buckets@+216, count@+224, mask@+228, extra u8@+232} — 桶 24B {dist@+4, tag@+8, value fixed i64@+16} | c>0 |
| +209..+223 | — | = RH 表内部位 (buckets@+216; 共享空桶 &unk_1430B2A10) |  |
| +224 | u32 | trade_influence_modifier_of_buyers count | c>0 |
| +225..+239 | — | = RH 表内部位 {mask@+228, extra@+232}  |  |
| +240 | 容器 data | diplo_pressure.from_factions (0x4B4E) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +241..+255 | — | = from_factions RH 表内部位 {buckets@+248, count@+256} (空桶 &unk_1430B2A40) |  |
| +256 | 容器 count | diplo_pressure.from_factions (0x4B4E) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +257..+271 | — | = from_factions RH 表内部位 + from_countries 前置  |  |
| +272 | 容器 data | from_countries (0x491D) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +273..+287 | — | = from_countries RH 表内部位 {buckets@+280, count@+288} (空桶 &unk_1430B2A90) |  |
| +288 | 容器 count | from_countries (0x491D) | c>0 且桶数组非空 (探针空态定案: count=0 ⇔ 桶=静态哨兵; 非空分支未证 — 未决) |
| +289..+303 | — | = from_countries RH 表内部位 + drift 前置  |  |
| +304 | Q17.15 | propaganda_weekly_drift.war_support | raw≠0 才写 (默认 0) |
| +312 | Q17.15 | propaganda_weekly_drift.stability | raw≠0 才写 (默认 0) |
| +320 | qword ×3 | **独立 qword 清零族** (+320/+328/+336; 非容器 — dtor 不释放、ctor 非容器构造、+344 PID 界放不下 alloc; 探针全零, 未名) | 不序列化 |
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
| +8 | 图顶点向量 wrapper* | 顶点向量 wrapper = *(g+8), {beg@+16, end@+24} | 顶点 80B 内联 (下表); 边 = 环形链表 sentinel@*(wrapper), 元素 {next@0, from@+16, to@+24} |
| +16 | uint32 | **sub_network_count** (token 0x3D26 图 writer 直发 — **互换警告解除**) |  |
| +24 | 匿名结构 | quiet 容器数据指针 — {d, c} |  |
| +25..+35 | — | = quiet 容器尾 {cap@+32}  |  |
| +36 | u32 | quiet 容器计数 |  |
| +37..+47 | — | = quiet 容器尾 + allocator@+40 (ctor 实锤) |  |
| +48 | uint32 | **prev_max_depth** (token 0x3D27 图 writer 直发) |  |
| +56 | uint32 | prev_gain_sources 容器数据指针 — {d, c} uint32 数组 |  |
| +57..+67 | — | = prev_gain_sources 容器尾 {cap@+64}  |  |
| +68 | u32 | prev_gain_sources 容器计数 |  |

顶点 80B 内联:

| 偏移 | 类型 | 名称 |
|---|---|---|
| +24 | uint32 | snid |
| +32 | uint32 | depth |
| +40 | int64 | strength |
| +48 | fixed×1e-5 | gb.op = **gain_breakdown.operatives** (loc INTEL_NETWORK_STRENGTH_GROWTH_FROM_OPERATIVE "From own Operatives" 坐实) |
| +56 | fixed×1e-5 | gb.adj = **gain_breakdown.adjacencies** (loc …_FROM_ADJACENCY "From adjacent states" 坐实) |
| +64 | int64 | gain |
| +72 | uint32 | state_id |

#### 4.11.4 CSubIntelNetwork (216B)

| 项 | 值 |
|---|---|
| sizeof | 216B |
| vtable RVA | 0X29A1AA8 |
| writer | 0X141208490 (modifiers 块 token 0x31E6 后直读 a1+8/+16/+24) |
| loader | 0X1412073E0 (case 12774 → sub_140DEF040(a2, a1+8) 同基) |
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
| +32 | i64 fixed | strength (0x28A6; **loader 读档丢弃**) | |
| +40 | i64 fixed | strength_sum (0x4C03; loader case 19459 实写) | |
| +48 | i64 fixed | strength_sum_over_cores (0x4C04; loader case 19460 实写) | |
| +56 | i64 fixed | national_coverage (0x4BFA; loader 实写) | |
| +64 | i64 fixed | sub_network_strength_target (0x4B6A; loader 实写) | |
| +72 | i64 fixed | sub_network_strength_target_from_operatives (0x4C0C; loader 实写) | |
| +80 | i64 fixed | sub_network_strength_target_from_counterintelligence (0x4C0D; loader 读弃) | |
| +88 | uint8 | is_quiet (0x4B23; **loader 读档丢弃**) | |
| +92 | uint32 | coverage.core | |
| +96 | uint32 | coverage.controlled | |
| +100 | uint32 | coverage.owned | |
| +104 | uint32 | total_coverable.core | |
| +108 | uint32 | total_coverable.controlled | |
| +112 | uint32 | total_coverable.owned | |
| +120 | 容器 24B | **coverage_per_occupied** {data@120, cap@+128, count@+132} — 12B 元 {tag 关联, u32@+4, u32@+8} (0x4BFD) | loader 19453 |
| +144 | 匿名结构 (16B, 内含 CState*) | states 容器数据指针 — {data, count}; 16B 条 {州指针, strength int64×1e-5} | 州 id = uint32@州对象+88; 无过滤全量写 |
| +145..+155 | — | = states 容器尾 {cap@+152}  |  |
| +156 | u32 | states 容器计数 |  |
| +168 | 容器 24B | **core_states** {data@168, cap@+176, count@+180} — **8B CState\* 元** (0x3189) | writer 遍历取 `*(st+88)` 发州 id; loader 12681 同法重建 |
| +192 | idpair | operatives 容器数据指针 — id 对列表 | 8B 紧致对 {type@0, id@4}; 定案 |
| +193..+203 | — | = operatives 容器尾 {cap@+200} (; 尾 pad +205..+215, 对象 216B 止) |  |
| +204 | u32 | operatives 容器计数 |  |

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

写门: 开键 14196B990 — 块仅 idx>0 且 pool≠0 且 tag 查表非空落盘。

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
| +208 | u32 | discriminant = **write-only 存档兼容判别** | ctor=1; 条件写: AAFD0 假才发 0x4B28 (仅二进制档写); loader AB970 读弃 |
| +216 | CStaticIntelSourceReference 内嵌 | **cheat** (0x4C01 ADEC0) — 内嵌静态 intel 源引用 {idx@+224, pool@+228, id@+232, discriminant@+236} | ctor 写 vt 0X14295D5C8 (探针 vt_rva=0X295F138 实证); load-key 19457 → sub_1424C0AA0(a2, a1+216) |

#### 4.11.8 情报源三件套 (CIntelSource / CStaticIntelSourcePool / CDynamicIntelSourcePool)

**CIntelSource** (池内单源四象限矩阵, 40B; vt 0x14295F098; writer 0x1411AEE90 / reader 0x1411ADE90; 入档): +8 intel 矩阵容器 {d@8, c@20} (12524) — 40B 元 {key u32 国家 idx@0, 四象限 4×i64×1e-5@+8 序 = civilian(19238)/army(10397)/navy(10398)/airforce(19239)} / +32 u32 id (11, 恒写) / +36 u8 remove 旗 (14530, 恒写)。发射序 = intel 块 → id → remove; 四象限写入帮手 = 共享族 sub_14109AEA0 (brace 包非零页)。

**CStaticIntelSourcePool** (静态源池, 72B; vt 0x14295F0E8; writer 0x1411AEFF0 / reader 0x1411AE930; 入档): +8 RH 名索引 {buckets@8, count@24, mask@28, extra@32, mlf 0.9@36}, 12B 桶 {dist@0, key@4 源 id, val@8} / +40 CIntelSource 值容器 {d@40, c@52} (元素内嵌 CIntelSource 本体) / **+64 u32 next id** (11; slot[8] = 0x1411AD8D0 id 溢出回滚 >0x3B9AC9FF→0)。挂链 = ci+160 static_intel_pools (**6 元**; 存档不写名, 按位置序对应 6 静态源定义)。

**CDynamicIntelSourcePool** (动态源池, 56B; vt 0x14295F048; writer 0x14197EC30 / reader 0x14197EBF0; 入档): +8 **accumulator** (19259) 40B 元 {国家 idx, 四象限} {d@8, c@20} / +32 **values** (19260) 同形 {d@32, c@44}; slot[8] = 0x14197E9B0 日总结算 = 两容器逐元四象限负值钳 0。语义 = 每池每国 intel 量日账 (accumulator = 当日累计, values = 已结算截面)。挂链 = ci+184 dynamic_intel_pools (**7 元**)。

#### 4.11.9 CCryptology / CCountryDecryptionState

**CCryptology** = `*(agency+288)` (机构对象 = `*(cc+4032)` = CIntelligenceAgency, §4.11.14; 挂载行 §4.3 +4032);
ctor sub_1413F61D0; 24B 槽 {data@+40, count@+52}。其内 **CCountryDecryptionState
56B** — 对每个已解密/解密中国家一条:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | tag | 目标国 |
| +12 | — | days — 激活加成剩余天数 | 激活时 = dword_1433331A0 = CRYPTO_CRYPTO_ACTIVE_BONUS_DURATION; −1 才不写 |
| +16 | uint8 | 全解密旗 | |
| +17 | uint8 | hide 旗 | |
| +18 | uint8 | 解密中旗 | |
| +24 | — | 进度分子 | 行进度条分子 |
| +40 | — | 解密完成日 | sub_1413F6820 进度到阈才写当前日期 |
| +48 | uint32 | date | 与 +52 联合为存档 `date` 键 (记录 writer sub_1413F9060 逐键定案) |
| +52 | uint32 | date | 同上 (联合门) |

CCryptology 哈希索引层 (RH; 适用「暂停态 RH 表仍会重建」纪律):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +72 | RH 桶数据 | 哈希索引层 {data@+72, mask@+84, extra@+88}; 12B 槽 {占位旗@+0, tag@+4, 值@+8} | 推定 |

行进度条 = 100000×分子/分母 clamp 1..100 (天数 sub_1413F7960); 分母 (攻防分离) =
define 组合 qword_143333030 = **CRYPTO_BASE_CRYPTO_LEVEL** +
qword_1433330F0 = **CRYPTO_CRYPTO_LEVEL_PER_CRYPTO_UPGRADE**×level/1e5
(双 define 注册串直证), 再按目标国自身 mdef528 修正取值 (cc+1464 修正在表键)。

mdef 索引: 528/529 是 **modifier def 表索引** (非 lexer token id — lexer 528/529 =
addressu/addressv, 离线 token_table_1193 同; GAME.layout.modifier_token 活体直证):

| 值 | 名称 | 语义 |
|---|---|---|
| 528 | moddef crypto_strength | 修正索引 (UI loc CRYPTO_DEFENSE_LEVEL); 进度分母按目标国自身该修正取值 |
| 529 | moddef crypto_department_enabled | 密码学部门态旗 (CIsCryptologyDepartmentActive::Evaluate 同址直证) — 值≠0 = 部门激活 → active_crypto_items + 国表刷新; ==0 → crypto_not_active (与触发器名 is_cryptology_department_active 同向) |

情报账本刷新机 (流程): SetTarget 写 win+5456 → 脏旗 → vt[4] 按 mode 推 tag 给
economy/army/navy/air 四面板。

#### 4.11.10 情报账本 GUI 消费点

| 对象+偏移 | 语义 | GUI 消费者 | loc key |
|---|---|---|---|
| ci 四象限矩阵 (§4.11 六矩阵) | 账本四页签数据源 | 面板数字**不读缓存管理器** — 四象限行 = 页签钮 `intel` 文本经 sub_1419DB1F0 直读玩家 ci+16 矩阵 (sub_140D045C0 = 四象限读取器定案); tooltip sub_141E9CAF0 把六矩阵全族 (+16/+40/+64/+88/+112/+136) 逐段映射 TOTAL_INTEL_*/INTEL_STATIC/DYNAMIC_SOURCE_* (静源名表含 IntelNetwork); qword_14333CFB8 = CMapModeManager 实名 (mapmodemanager.cpp:430 直证) — 其链路 = SetTarget 置缓存槽 11 脏 → sub_140F33D50 分派 → sub_140F353D0 读账本单例 tag+mode 做**地图着色** (非面板数值) | economy/army/navy/air_panel |
| CCountryDecryptionState 56B (crypt 24B 槽 {data+40, count+52}; §4.11.9) | 玩家侧对目标国解密账本 | cryptology_country_entry Setup sub_141A223E0 (tag@entry+32) | cryptology_country_entry |
| CCountryDecryptionState 记录字段 (§4.11.9) | 行四态文案与行进度条 | Setup 分支 | CRYPTO_DECRYPTING / CRYPTO_NOT_DECRYPTING / CRYPTO_FULLY_DECRYPTED / CRYPTO_FULLY_ACTIVATED / REVEAL_INTEL(_LEFT) |
| cc+1156 owned_states / cc+3976+656 阵营 | 候选门 (只列有争议州且非友方) | sub_141A228B0 + sub_1413F8640 | country_list(_container) / add_new_container |
| cc+632/{+644} 容器 | navy 页汇总行 — **= `CTaskForce**` 舰队容器** (§4.16 实名); 用途 = **按舰型聚合玩家已获情报的舰船数/价值**。汇总链: 舰队容器 → 逐 tf → `sub_140D230E0(tf)` (**全文仅 `return a1 + 184;` 一行访问器, 非「逐元聚合」**) → 逐 ship `sub_140BFDF30(ship,tag)>0` 情报门 → `*(ship+496)` 设计 → `*(design+184)` 舰级 → `+112` 表 {count@+124, 48B 条} → `sub_140D6EEB0(ship)` → 计数; 价值化 0X1406F06F0 (`dword_143335208 * 计数 * 100000`) | **面板 = `CIntelLedgerNavyPanelController`** (RTTI 实名, vt 0x142A8DEE8); 行类 = CLedgerShipTypeEntry / CLedgerShipEntry / CLedgerShipHeaderEntry (窗名 `ledger_ship_type_entry` / `ledger_ship_entry` / `ledger_ship_header_entry`) | 定案 |
| 账本页签区 (win+5248 mode 四区, 1288B/区) | 区 = CLegacyButtonObserverGlue\<CCountryIntelLedgerView\> (1288B), 每区仅绑一个 on_click — sub_1419DA880/6F50/7260/6DE0 ↔ economy/army/navy/air; 回调 = 置 win+5248 mode + 三态切换 + **切 map mode 30** | populate sub_1419D8F10 | econom/army/navy/air_panel(+_tab_frame) |
| economy 面板 | **CIntelLedgerCivilianPanelController 实名** (vt[2]=0X141EC2250 五 filler 分派; +2816..+2912 元素名经绑定器 sub_141EBEC00+rdata 串逐个定名) | 面板 vt[2] | — |
| army 面板 | vt[2]=0X141EB85A0 thunk→**sub_141EB7200**: 师数/特战师数/部署人力三行 (ARMY_*_INTEL_MIN/MAX/AT_LOWEST define 三元组定名; **模糊化引擎 = sub_14142EB50**) | 面板 vt[2] | — |
| AgencyView 子视图 A/B/C (win+1408/+1416/+1424) | A(+1408) = **CAgencyLogoSelectionWindow** (三证: malloc(0xB50)→vt 0x142a2c638 + agencylogoselectionwindow.cpp:0x88 断言 + 窗名 name_logo_agency_selection_window; 另见 §4.31.88) / B(+1416) = **COperationOverviewWindow** (idpair 存储@win+5940 + spec 缓存块 win+5856..5935; setter 0X14182CCD0 / opener 0X14182C990) / C(+1424) = **CAgencyUpgradesWindow** (三证: malloc(0x578)→vt 0x142a2caa0 + agencyupgradeswindow.cpp:0x1BE + 窗名 intelligence_agency_upgrades_window; COperationViewEntry 只是内嵌行列表条目型, +14704 容器直证; 另见 §4.31.88) | 刷新器 sub_141A11EB0/sub_14182EEF0/sub_141A166F0 | — |
| SBufferedOperations ×4 静态 (unk_14333D420/438/450/468, stride 0x18) | 行动页数据流 (tbb 并行预算; 0xAC0 行 {+2728 序, +2736 COperation\*, +2744 纪元快照}; 纪元 qword_14333D4C8/14333D528) | @48[6] Update 0X140F2F720 (经转发器 sub_140F2C100 = `sub_140F2F720(a1−48)`); [4] CalcOperations 0X140F29150 | — |
| 行动页纪元域 | **win+14744 纪元缓存** (⊥ qword_14333D4C8 命中 → 仅刷可见行 [0, +14736); 未命中 → 存纪元 + 清 +1704 格 (sub_1402E11E0, 伴生 +1712) + +14736=0) / **行池 {data@+14712, cap@+14720, count@+14724, glue@+14728}**; +14736 = 纪元等分支循环界 / 重建分支追加游标 (追加后 = +14724) | @48[6] Update; @48[9] Repopulate sub_140F2F3A0; 行 ctor sub_141A19CC0 / Setup sub_141A1B450 (+2728=*a3 / +2736=COperation\* / +2744=snapshot) / 行自刷新 sub_141A1C650; 行解引 sub_14221F310 + 门 sub_141401870 (obj+128==0) + 行刷 sub_141A1D110; 格几何 (列+368 / 上限+372 / 纵旗+384 / 游标+404) 未变 | — |
| 行动页纪元全局 | **纪元计数器 qword_14333D4C8** (写者: [4] OnOpen sub_140F2F050 内联自增 / sub_140F2D910 自增 / sub_1400737B0 置 0 / sub_140F29AF0 = `v1[21]` 存档恢复) / **快照与 idpair 哨兵 qword_14333D528** / tag 过滤表 qword_14333D4B0 + 计数 qword_14333D4BC / 16B 元双表 qword_14333D480 + dword_14333D48C 与 qword_14333D498 + dword_14333D4A4 (两段并行循环) | Update / CalcOperations | — |

> **§4.29 并入说明**: 特务专项 (COperativeLeader / mission 分发 / operation 块 /
> CIntelligenceAgency / 行动令牌) 原为独立分册, 与本节同属**一个情报—间谍系统**
> (同一对象链: gs+1696 谍报网 ←→ cc+4032 机构 ←→ CCharacter 特工池), 故合并于本节
> §4.11.11 起。原节号 §4.29 不再启用, 交叉引用已全数改指本节。

#### 4.11.11 COperativeLeader 特有区全字段表

身份表:

| 项 | 值 |
|---|---|
| RTTI 名 | COperativeLeader |
| sizeof | 0x10A8 (4264) — 两处独立 malloc_base(0x10A8) + ctor 旁证 |
| vtable RVA | vt0 0X142954730 / vt1 0X142954848 (+3928 CSelectable 子对象视口) |
| writer (vt slot2) | 0X140C28550 = 基链 0X140C1CE70 (前缀 [0,3928), 基类全表见 §4.4 CUnitLeader) + 特有区 |
| loader | — |
| 挂载点 | retired 池 {d@ch+200, c@ch+212} (CCharacter) 与现役 CIntelligenceAgency recruitment/agency 池 (§4.11.14), 同经 ADEC0 |
| ctor | 0X140C0BE20 (经 0X140C0C200 基类链) |
| dtor | 0X140C0D1B0 (触 +3928/+4232/+3944) |

ADEC0 备查: 写键 token 后调内嵌对象 vt 槽1 trampoline 自序列化, 传参 = &vt = 对象基址+8 (§3.7a 族 A, payload 在 ptr−8)。

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
| +4016 | tag_id (u32) | captured 俘虏国 tag — 与 +4024 capture_date 各自独立 (capture_date = 24B, 见 +4024 行) | 门 (i32)>0; writer 0X140BB59C0 → 提取形 `captured="TAG"`; tok 15636 (0x3D14) |
| +4017..+4023 | — | pad (capture_date vt1@+4024 前置对齐) |  |
| +4024 | CGameDate 24B {vt1@+4024, hours@+4032, vt2@+4040} | capture_date (ctor = 43808760 "1.1.1.1" 哨兵; 24B 占 +4024..+4047, 布局闭合) | 门 = captured>0 (**同一 if 块配对** — 无 captured 则 date 也不写); ADEC0 (ptr=vt2=+4040, hours=ptr−8=+4032); 提取形 `capture_date="Y.M.D.H"`; tok 19297 (0x4B61) |
| +4048 | CNameGroupMember 内嵌 (184B, 4048..4231; vt 0x142935b18) | codename | **恒写** (ADEC0 委托 → writer 0X1409C9AC0); tok 15639 (0x3D17); 子表见下 |
| +4049..+4223 | — | = CNameGroupMember 内嵌本体 (+4048..+4231; 内部布局见 §4.3 名字组表) |  |
| +4224 | uint32 枚举 | state — 枚举表见下 | 块键 439 (0x1B7), 0X1401F4F00 写枚举原子; 非法值 → assert("Invalid enum value", unitleader.cpp) 后仍写 14668 |
| +4232 | COperativeMission 内嵌 (32B, 4232..4263 = sizeof 闭合) | mission | 门 0X140FC4080 = (type@+4256 ≠ 0) (⚠ 0X141FC3D70 非函数, 勿用); ADEC0 委托 (writer 0X140FC6240); 子表见下 |

**state 枚举表** (0X1401F4F00 写枚举原子):

| 值 | 名称 | 语义 (存档原子 token) |
|---|---|---|
| 0 | on_capture | 19025 |
| 1 | on_cooldown | 19026; **GUI 显示态 = enroute** (COperativeMapIconEntry [19] 分支 1→leader+3976 optional, 显示 leader_enroute) |
| 2 | on_disband | 19027 |
| 3 | on_mission | 14668 (ctor 默认 3); GUI 分支 3→mission impl vt+72 (§4.11.13 互证) |
| 4 | on_operation | 19024; GUI 显示态 = on_operation (PortraitView 四态双处互证) |

GUI 显示态分组: 0/2/5 = idle, 1 = enroute, 3 = on_mission, 4 = on_operation (§4.31.43 视图族互证)。
| 5 | killed | 13164 |

**mission 句柄 (COperativeMission@+4232) 子表** (偏移 = leader 绝对, 括号内 = 对象内):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +4232 (+0) | vt | vtable | 不序列化 |
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

注: sizeof(CNameGroupMember) = 0xB8 (4048+184 = 4232 = mission 起点, 布局闭合)。

**mission (COperativeMission@+4232) 分发表** (writer 0X140FC6240: assert
impl 非空 → switch(type) 取 mission 名 token → ADEC0(token, impl) 委托
impl 自己的序列化器):

| type | 存档名 | 名 token | impl 类 (vt) | impl writer (vt slot2) |
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
| resources | 容器 {d@op+344, c@op+356}, 元素子表见下 | 门 count≠0 |
| return_on_complete (tok 19426/0x4BE2) | 容器 {d@op+368, c@op+380}, 元素子表见下 | 门 count≠0; writer 0X141404B00; 存档形态 = 半行匿名对象 `{ {id=X type=Y}` ␍ `amount}` → 提取器折 `return_on_complete.@.#N` = amount/1e5 (id 对被提取器丢弃; USA 锚 0x1AEAA→1.1025) |

ops 容器 (sub_14022FFF0 实例表) 形态补记: {data@+16, count@+28}, 8B 指针元 (推定)。

**resources 元素子表** (32B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | i64 | amount | flag≠0 → 块值 = C 截断 raw/1e5 + days |
| +8 | uint32 | days | |
| +16 | 匿名结构 (NNB 形状)* | def | |
| +24 | uint8 | flag | 分支门见下注 |

注 (resources 分支): flag≠0 → 发 `civilian_factories` 块 (tok 0x4BDD/19421); flag=0 → 键名 = token@*(e+16)+8, 单叶 fixed5。

**return_on_complete 元素子表** (16B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | uint32 | type | id 对被提取器丢弃 |
| +4 | uint32 | id | 同上 |
| +8 | i64×1e-5 | amount | 提取值 = amount/1e5 |

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

谱系 (RTTI 全扫 12 类全齐): NOperativeMissions::IOperativeMission 纯接口 (无自身 typeinfo) → CNoMission 8B / CStateBased 32B → {CNetworkBased 32B (零新增字段) → CBuildIntelNetwork 64B / CQuietIntelNetwork 32B / CBoostIdeology 72B / CPropaganda 64B; CRootOutResistance 32B 直承 CStateBased} / CCountryBased 24B → CControlTrade / CCounterIntelligence / CDiplomaticPressure 各 56B。COperativeMissionData 32B = 任务快照非任务对象 (见下); COperativeMission 句柄 32B = leader+4232 内嵌。清偿补注: **mission+88 = 州对象缓存**（州+204 = 控制国比对, 书定案）、**mission+96 = 意识形态指针**（kind5 "#~ No ideology" 门）——CSetOperativeMission 旧推定废。命名空间多出的 2 条 RTTI = CQuietIntelNetwork::GetProvincesInRangeOfState lambda 载体 (vt 0x142A20148 / 0x142A20180)。

**中间基类表** (RTTI 定案):

| 类 | sizeof | vtable | 共用 writer (vt slot2) | 派生 |
|---|---|---|---|---|
| CStateBased | 32 | 0x142A1F538 | — | CNetworkBased / CRootOutResistance |
| CNetworkBased | 32 | 0x142a1f538 | 0X141A31840 | CBuildIntelNetwork / CQuietIntelNetwork / CBoostIdeology / CPropaganda (零新增字段, 仅覆 vtable) |
| CCountryBased | 24 | 0x142a1fa50 | 0X141A328B0 (只发 target) | CControlTrade / CCounterIntelligence / CDiplomaticPressure |

**全族虚表槽表** (12 类):

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
| +0 | vt | vtable | 不序列化 |
| +8 | COperativeMission* | owner — 所属 mission 句柄 | 不序列化 |
| +16 | tag_id | target country — 0X140BB59C0 引号串 | 门 >0 |
| +20 | — | pad | 不序列化 |
| +24 | CState* | pState; 快照 fill 0X141A313D0 (assert "pState not set", operative_mission_state_based.cpp:0x50) | writer ADFE0 — tok 439, 发 *(pState+88) |

**CCountryBased (24B) 字段表** (ctor 0X141A32670 / 0X141A32690):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vt | vtable | 不序列化 |
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
> CControlTrade / sub_141956F60 = CCounterIntelligence / sub_1419585D0 = CDiplomaticPressure /
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

**COperativeMissionData (32B) 快照字段表** (vt 0x142955b40; writer 0X14194E520; ctor 0X14194D810 5参 / 0X14194D880 4参 / 0X14194D850 3参):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vt | vtable | 不序列化 |
| +8 | uint32 | mission type — ADCE0 tok 11450; 值域 = 0X140FC4150 type→名 switch (与分发表同表) |  |
| +12 | tag_id | target_country — tok 14964 | 门 >0 |
| +16 | CState* | pState — tok 14965 → 发 *(pState+88) | 门 非空 |
| +24 | 匿名结构 (NNB 形状)* | ideology 定义 ptr — tok 11838, deref+24 = MSVC 串 (ADF40) | ADF40 |

注: optional 包装 move-assign 0X140C0D820, present u8@+32 (对象尾后)。消费 = operationinstance.cpp:385 (0X141400170): leader+4224==3 (active) 时经 0X140FC1130 (handle+16 → impl slot17) 取 op 实例 56B 元素内快照。

**op 实例 56B 快照元素** (operationinstance.cpp:385 消费形态):

| 元素+N | 内容 |
|---|---|
| +0 | vt |
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
- COperativeMissionData **从不落盘** (负定案): writer sub_14194E520 全 dump 引用数 = 1 (仅定义行), 其 vt 0x142955B40 不被任何 Save wrapper 入口调用 ⇒ 纯运行时快照。

#### 4.11.14 CIntelligenceAgency (ag = rp(cc+4032), vt 0X2981F68, writer 0X140FDF3A0)

| 字段 | 偏移 (ag) | 布局/写门 |
|---|---|---|
| recruitment 内嵌 (vt 0X29D8FF0, writer 0X14157BE20) | +8 | 三容器族 (下表) |
| upgrades {d, c@+108} 16B {tok*, u32} | +96 | count>0; **GUI: 分支升级格** (CBranchUpgradeButtonEntry sub_141A230F0; DB qword_14332EDC0 {count@+124, items@+112} → upgrade_button; `agency_branches` 格) |
| name SSO | +128 | 恒写; **GUI: 机构名** (Repopulate 0X140F2F3A0 → win+1448; agency_name) |
| icon SSO | +160 | 恒写 (icon 空串写 ""); **GUI: 机构徽标** (→ win+1672 (vt+728); name_logo) |
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
| cryptology | +288 | = *(ag+288) → intel_source 内嵌@+16 (vt 0X295F138): country idx@+8 / pool@+12 / id@+16 / discriminant@+20; 开键 idx>0 且 pool≠0 (0X14197F040), 4 叶恒写 — 归 sv2_sec_c_intel 段管辖; **GUI: CCryptology 入口** (密码头部 LEVEL = mdef 528 crypto_strength @*(crypt+8)+1464 / STRENGTH sub_1413F7C60 + cryptology_country_entry 国别行; 全链 §4.11) |
| defense i64×1e-5 | +296 | 恒写含 0 |

recruitment 三容器 (容器 writer 0X141579010 count>0 才开块; 8B 指针元):

| 字段 | 偏移 (recruitment) | 键 | 备注 |
|---|---|---|---|
| generated_operatives | {d@+16, c@+28} | 0x4B44=19268 |  |
| recruitable_operatives | {d@+40, c@+52} | 0x4B45 |  |
| recruitable_operatives_not_to_spy_master | {d@+64, c@+76} | 0x4B54 | ctor 0x141579120 双子容器 |

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
| finished (ops+40 子对象, vt 0X27E7528) | 0X1411A19A0 | 外 RH {data@+16, mask@+28, extra@+32} 48B 桶 {dist@+4, op token id@+8, 内表 ptr@+24, 内 mask@+36, 内 extra@+40}; 内表 12B 桶 {dist@0, tagidx@+4, count@+8}; 发射 = 外桶逐有效键一块 (op token 名), 内 tag 按 tagidx 升序 "TAG count" 空格连接 |
| running (gate count@ops+28≠0; {data@ops+16}) | 0X141404B00 (块名 = token@*(op+72)+8 op def) | id 对 {type@op+8, id@op+12}; duration u32@op+128 ≠0 才写 date+duration (date hours@op+112, CGameDate 代理 vt@+120 hours 在 vt−8 — raids 同构); equipment 块恒写 (ADEC0(0x2F4E, op+272), allow_zero_entries@op+272+56); target = 国 idx@op+88 → 引号 tag 恒写; target_provinces = ptr@op+96 → u32@ptr+164 (指针门); operative_slots 门 count@op+236≠0: {data@op+224} 56B 元 (0X141BE6A40): operative id 对 {type@0, id@+4} 非零门 / resume_mission u32@+8 ≠0 写 yes / mission 块门 b@+48≠0 对象@el+16 (0X14194E520): mission 枚举@+8 → sub_140FC4150 switch 0..8 裸名 / target_country 国 idx@+12 >0 / target_state ptr@+16 → u32@ptr+88; phases 门 count@op+260≠0: {data@op+248} 8B 指针 → token 名 u32@*(el)+8 引号空格单行; prepared: hours@op+208 ≠ 43808760 才写 (vt 代理@+216) |

#### 4.11.16 情报机构事务族 (资源/令牌/阶段/升级/历史机构/转移动作)

**COperationResources** (行动资源清单容器; vt 0x14271AB70; writer 0x140A7B070 / reader 0x140A7AB40; 入档): 容器 {d@8, c@20} 32B 元 = {i64 amount@0 (civilian 元 = raw/1e5 整写, 装备元 = fixed), u32 days@8, def 指针@16 (civilian → civilian_factories(19421) 块 / 装备 → def+8 token 名), u8 civilian 旗@24}; 挂载 = op+344 resources 块。

**COperationToken** (行动奖励令牌定义, ~184B; vt 0x14271ADF0; writer=CFG; reader 0x140A7FC30; idb operation_tokens 已挂): +16 desc (10644) / +48 icon (181) / +80 name (27) / +112 text_icon (19424) / +144 i64 intel_gain (19022) / +152 {dword intel 来源种类, u8 旗@156} (19252) / +160 targeted_modifier 容器 (14623, 8B 修饰 def 指针, 去重报错)。

**COperationPhaseSelection** (phases 选择列表容器, 32B; vt 0x14293F288; writer=CFG; reader 0x140A7B420): op def 的 phases(19005) 块挂 **op+1936** {d@1936, c@1948} 本类实例, 内容 = 8B 指针元 → COperationPhaseSelectionMember; 无效 phase 名剔除并日志 (operationphase.cpp:68)。**COperationPhaseSelectionMember** (288B; vt 0x14293F148; writer=CFG; reader 0x140A7B6F0 = 直通 +16 槽[4]): +8 u32 phase 名 token / +16 CAIMTTHChance 内嵌 272B (该 phase 的 AI 选中权重)。

**CAgencyUpgradeBranch** (机构升级分支定义; vt 0x1427DF190; writer=CFG; reader 0x140625780): +40/+64/+88/+112 四容器 (+64 = 分支内升级清单 {d@64, c@76}, 元 = CAgencyUpgrade 624B {SSO 名@+24, FNV@+56}, 重复报错 agencyupgrade.cpp:262); +40/+88/+112 三容器语义未决 (reader sub_140625780 只显式用 +64 做同名合并, 其余三容器无键分派分支; writer = CFG 空桩 ⇒ 无 token 锚)。idb agency_upgrade 已挂 (0x332EDC0)。

**CHistoricalAgency** (历史机构名簿; vt 0x1427DF060; writer=CFG; reader 0x140621F70): **+16 names 串列表容器** (12767, SSO 32B 元) / +40 picture (464) / +72 available (12264) 子对象 / +160 default (11405) 子对象 — random_historical_agency 取名的数据底 (与 §4.33.10 CSetIntelligenceAgencyRandomHistoricalNameCommand 互证)。

**CCapturedOperativeReference** (被捕干员引用, 56B; vt 0x142981FB8; writer 0x141A34FF0 / reader 0x141A34F40; 入档): +8 country tag (10394) / +12 operative idpair (15635) / +24 intel 四象限 (12524) — ag+264 captured 列表元素。

**CTransferSpyMasterAction / CTransferHeadOfCounterIntelAction / CTransferHeadOfCryptologyAction / CTransferHeadOfOperationsAction** (情报机构首长转移四动作; CDiplomaticAction 120B 零新增薄派生, writer/reader 同址直挂基类真体 0x141141470/0x14113E7A0):

| 类 | vt | [23] 名产出 | [24] Clone |
|---|---|---|---|
| CTransferSpyMasterAction | 0x14298F3E8 | 0x14112E7E0 → DIPLOMACY_SPYMASTER | 0x141102550 |
| CTransferHeadOfCounterIntelAction | 0x14298F610 | 0x14112E690 → DIPLOMACY_HEAD_OF_COUNTERINTEL | 0x141102460 |
| CTransferHeadOfCryptologyAction | 0x14298F838 | 0x14112E700 → DIPLOMACY_HEAD_OF_CRYPTOLOGY | 0x1411024B0 |
| CTransferHeadOfOperationsAction | 0x14298FA60 | 0x14112E770 → DIPLOMACY_HEAD_OF_OPERATIONS | 0x141102500 |

> +104 type = 首长槽别 (枚举值待裁); 落点 = fac+2104 间谍首脑槽表 (§4.33.10)。

**AI 四驱动 (CAIModule 基, 名录; 无存档字段; 共性 +64 = owner 上下文; 门控读 CStrategicAI+8765 (csa+5965) 战略首轮就绪旗, §4.34.11)**: COperationsAI (vt 0x1429AC6B0; [14] 周期启动门 → post CLaunchOperationCommand; [15] 周优先级) / COperativesAi (0x14298A2E8; [14] 干员招募+任务分派; 无周更) / CIntelligenceAgencyAI (0x1429AB938; **[15] 建局主逻辑**, DLC 门 25; [14] 仅 metrics 日志) / CCryptologyAI (0x1429AB130; +72 = cryptology 对象指针 (宿主 = agency+288 推定); [14] 日补位 + [15] 周重评估; **密码部门激活门 = 日/周共用前置门**)。四家 AI 行为全链见 §4.34.14。

#### 4.11.17 行动令牌管理器与情报 defines 全局映射

**CCountryOperationTokenManager** (国别行动令牌管理器, 72B; cc+5552 tokens scopedptr 本体; ctor 0x141405CF0(cc); **入 savegame 国家块**): writer 0x141407F90 / reader 0x141406F20; 落键 = intel_source (19252, +16 内嵌子对象) + operation_assets (16245, RH 表 40B 条目 {+48/+56/+60/+64}, 排序后落盘), reader 兼容旧键 tokens (19016); 与相邻 cc+5544 CCountryOperationManager (内含 CCountryFinishedOperations@+40) 配对 — 干员令牌 def 见 §4.11.16 COperationToken, 本类持运行态令牌清单。

| 全局地址 | define 全名 | 定义件值 | 注册点 | 消费者 |
|---|---|---|---|---|
| dword_143335730 | NOperatives::AGENCY_CREATION_FACTORIES | 5 | dump L5566522 | CIA 建局门槛 IsValid 0x141A298E0 (可用民工厂 ≥ N) |
| dword_143335C90 | NOperatives::BECOME_SPYMASTER_PP_COST | 50 | L2489973 | CBecomeSpyMaster Execute 0x141A27370 (非 DLC 通道政治力) |
| dword_143335D14 | NOperatives::BECOME_SPYMASTER_MIN_UPGRADES | 3 | L1473366 | IsValid 0x140FD8F60 (所需情报局升级数) |
| dword_1433357C8 | NFactions::FACTION_INTELLIGENCE_UNLOCK_COST | 1 | L4524049 | CBecomeSpyMaster DLC 通道 (100000×值 扣 ms+72; 同 §4.31.21/§4.31.2 解锁费) |

> 名证 = 注册调用点与全名串返回函数双证 (映射表六地址均唯一), 值级与 common/defines/00_defines.lua 对拍一致。

> **本域 GUI 类布局**: 见 4.31.43。
