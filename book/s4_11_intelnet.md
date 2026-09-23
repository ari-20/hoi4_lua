> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.11 情报域 (谍报网 / 特工 / 情报账本与来源池 / 密码学)

⚠ ci cheat 形态: **两类比定案** — CCountryIntel (vt 0x14295F188) +216 =
内嵌 CStaticIntelSourceReference (键 19457); CCountryIntelNetwork +216 =
strength_sum_over_cores; 全链无 vt 分流读取点, 按对象类各读各的。

**获取**: `so = *(operatives mgr 容器)`, 网容器 = `{data@so+16, count@so+28}`;
**第 i 网 = data[i]** (⚠ 一国多网, 每目标国一个 — 只读第一网会漏)。
**vtable**: 0X29A1A58。

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
| 4 | root_out_resistance | 列表 = agency+216 (§4.3) |
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

| 偏移 (e) | 类型 | 名称 | 备注 |
|---|---|---|---|
| +3944 | uint32* | nationalities 容器数据 — u32 tid 数组 (e = operative 对象) | R:tag 转换 |
| +3956 | uint32 | nationalities 容器计数 |  |

writer 0X140BB5A10 写**内联块单行** `nationalities={ ITA ETH SYR }`
(读法不变)。

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
| tokens | `*(cc+5552)+16` | 定案: 元素 24B 五字段 — idx@+8 = 属主 tag / **pool@+12 = ci.static_intel_pools 池下标 u32** / id@+16 = 池内哈希键 / disc@+20 = ci+208 (探针+二进制全链无指针读法) |
| agency | `*(ag+288)+16` | — |

写门: 开键 14196B990 — 块仅 idx>0 且 pool≠0 且 tag 查表非空落盘。

#### 4.11.6 tokens.operation_assets (排序发射)

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

**CCryptology** = `*(agency+288)` (机构对象 = `*(cc+4032)`, §4.3 +4032 行);
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
