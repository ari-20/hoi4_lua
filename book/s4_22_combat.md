

### 4.22 战斗族 (CCombat / details / logmgr / history)

#### 4.22.1 战斗管理挂载与三类分流 (CCombatManager @gs+608)

获取路径与 vtable:

| 偏移 (gs) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +608 | CCombatManager (内嵌) | 战斗主管理 | vtable 0X2950688; 0X2950688 存于槽自身 (非指针; 探针定案) |
| +616 | CCombat* | 战斗明细 (details) 容器数据 — {count@+628}; 元素主 vtable 分流 CLandCombat / CNavalCombat / CLandBorderWarCombat |  |
| +617..+627 | — | = details 容器尾 {cap@+624} |  |
| +628 | u32 | details 容器计数 | logmgr 实为 +2176/+2188 容器 (元素 NCombatLog::CManager, vt 0X295D8D8), 非本槽 |
| +629..+647 | — | = details 容器尾 {alloc@+632} + **+640 注册 token id** (ctor sub_140BB3E00 注册; 运行时, 未名) |  |
| +648 | CCombatHistory (内嵌) | 战斗历史 (hist) | vtable 0X2950638 (= mgr+40) |
| +656 | CCombatHistory* | **CCombatHistory 链表头** — Clear sub_140BB7BB0 沿 next@e+56 逐节点 free; 节点带 CGregorianDate vt@e+8 = end_date 族B (§3.7a) |  |
| +664 | 匿名结构 (NNB 形状)* | 历史链表 **tail** | Clear 同清 (高置信) |
| +672 | u32 | 历史条目 **count** | Clear 同清 (高置信) |
| +676 | u8 | 运行时旗 (ctor 0; 未名) | 不序列化 |
| +680 | u8 | **_bInCombatUpdate 战斗更新中旗** | 断言 "Removing combat during combat update!" combatmanager.cpp:0x495; 不序列化 |
| +688..+2175 | — | **非战斗族** (mgr sizeof≈80, ctor 止于 +72; 本段属 gs 其他子系统 — 定案) |  |
| +2176 | NCombatLog::CManager* | combat log manager 指针数组数据 (按国家) | 元素 NCombatLog::CManager vt 0X295D8D8 |
| +2177..+2187 | — | = log manager 数组尾 (cap 候选 +2184 未直读) |  |
| +2188 | u32 | log manager 数组 **界/计数** | gs loader case 14037 `if(id <= *(a1+2188))` 铁证; CManager sizeof 0x28=40 {vt@0, log{d@8,c@20}, tag@32} |

三类分流与字段族:

| 项 | 规则/定案 | 备注 |
|---|---|---|
| 场容器三类分流 | gs+616 场容器混装三类对象, **主 vtable `*e` 分流**: 陆战 0X29A83D8 / 海战 0X29DDB08 / 边界战 0X29BC5F0** | ⚠ 按 day 正负分流会把 CLandBorderWarCombat (day=68 正值) 误入 land_combat, 致 8196 插槽后索引整体漂移 (~770 伪 DIFF) — 必须按主 vtable 分流 |
| 海陆战分流 | combat `day uint32 > 0x7FFFFFFF` 即海战 (NBAT 前缀) | 陆战按 id 升序重编号 |
| 魔数 | 陆战 600/65536 魔数已改通用 |  |
| combat_details 字段族 | 参战双 attacker/defender 各含 units/losses/size/org_damage/str_damage/manpower casualties 等 | writer 0X1414B59B0 族; pfx 参数区分 CBAT/NBAT 前缀 |

#### 4.22.2 边界战族 (CLandBorderWarCombat / CLandBorderWarCombatant)

独立 `border_war_combat` 块, 首块裸名。块 writer 0X1413F0070 (vtC 0X29BC6D0 slot2) = 陆战基座 0x1412bd810 追加:

| 偏移 (c) | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +200 | i64 (fixed×1e-5) | combat_width |  |
| +208 | u32 | combat_state |  |
| +212 | u32 | minimum_duration_in_days |  |
| +216 | i32 | start (bi1 实测 −2) |  |
| +224 | u8 | change_state_after_war (yn) |  |

side 元素 CLandBorderWarCombatant writer 0X1413F0100 = 0X1412BD820 追加:

| 偏移 (cb) | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +1216 | u32 | tag tid | tid=0 → "---" |
| +1224 | 匿名结构 (NNB 形状)* | state = \*(\*(cb+1224)+88) |  |
| +1232 | CProvince* 向量 | province 容器 {d@cb+1232, c@cb+1244} → 元素 +164 裸名 (省 id) |  |
| +1256 | id 对 | orders_group {type@cb+1256, id@cb+1260} | 折叠单叶 |
| +1264 | u32 | max_units |  |
| +1272 | i64 (fixed×1e-5) | modifier (AE590 族) |  |
| +1280 | MSVC 串 | on_win | 门 size@+16≠0 |
| +1312 | MSVC 串 | on_lose | 门 size@+16≠0 |
| +1344 | MSVC 串 | on_cancel | 门 size@+16≠0 |
| +1376 | i64 (fixed×1e-5) | dig_in_factor (AE590 族) |  |
| +1384 | i64 (fixed×1e-5) | terrain_factor (AE590 族) |  |
| +1392 | 匿名结构 (12B 形状) 向量 | removed_unit 容器 {d@cb+1392, c@cb+1404} — 12B 条 {id 对@0, hours u32@8} |  |

注: token 0x39A3 = removed_unit 块键本身 / 0x28A3 = unused / 0x3170 = hours 字段键, 均与 on_* 无关 (探针 token_name 定案); 真键 = **on_win 14747 / on_lose 14748 / on_cancel 14749** (连号, 与 writer 字段序同序)。
证据: `sub_1413F0070` (border_war 块 writer) / `sub_1413F0100` (侧元素 writer) 对基座 `sub_1412BCF70` / `sub_1412BD820` 的追加调用。

CWar (战争对象; 挂载 = 关系对象+744, §4.10) 布局补行 (高置信, 多批互证):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +32 | hours | 开战日期 | 高置信 |
| +73 | u8 | 状态旗 (非 0 = 排除于统计/存活判定) | 高置信 |

#### 4.22.3 CLandCombat 场对象 (writer 0X1413E4150)

> 基差注: 活体对象带 16B 包装前缀 e — 槽包装目标 cb+24 = e, 书表基 c = e+16;
> 故 e+40/48/56/72 = 本表 c+24/32/40/56。

场枚举与 holder:

| 层级 | 地址 | 说明 |
|---|---|---|
| 场容器 | {d@gs+616, c@gs+628} | 元素 8B 指针 e = 槽包装 (前 16B {…, type=3}) |
| 战斗对象 | **c = e+16** | writer 0X1413E4150 的 a1 = c; 误读 e+8/+12 得 "id=0 type=3" 即此 |
| holder id 对 | 内联 {type u32@c+8, id u32@c+12} | sub_142220340(c), type 62 = holder 类; 不是指针解引用也不是槽头 |

字段 (c = 对象基):

| 偏移 (c) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | u32 | holder.type — id 对之 type (id 对 {type, id}) | type 62 = holder 类; 内联非指针解引用 |
| +12 | u32 | holder.id — id 对之 id |  |
| +13..+23 | — | = **vt2 持久化 vtable 槽 (obj+16)** — 陆 0x1429a84b8 / 海 0X1429DBF90; obj 包装布局: obj+0 vt1 / obj+8 refid / obj+24 holder 对 |  |
| +24 | CCombatant 容器* | attacker = *(c+24) | 容器包装: cont=rp(c+24/32); **cont[0] = vtable (属映像区间) ⇒ cb = cont 本体**; 见下注 |
| +32 | CCombatant 容器* | defender = *(c+32) | 容器包装同上 |
| +40 | CProvince* | location = *(*(c+40)+164) |  |
| +48 | uint32 | day | >0x7FFFFFFF → naval_combat 键 |
| +52 | uint32 | duration |  |
| +56 | 匿名结构 (NNB 形状) | terrain 串对象 | 门 byte@tobj+16, 串@tobj+24, 引号 |

> **侧容器解引用 (定案)**: 侧容器 cont 的 **+0 是 vtable** (落在映像区间
> [BASE, BASE+0x37ec000)), 不是数据指针 — 33 场陆战 66 个侧容器 66/66 实测。
> 因此 cb = cont 本体。若误把 cont[0] 当数据指针去走 "el=rp(d) → cb=rp(el+16)"
> 解包, 会把代码字节读成堆指针: 攻击侧因 count 读到垃圾巨值被门挡住而侥幸
> 走兜底, 防守侧 count 恰 =1 而误入解包 → **整侧字段静默丢失** (实测
> land_combat[27]/[31] defender 39 行全丢)。

#### 4.22.4 CCombatant 基座与战斗持久化族 (CCombatHistory / NCombatLog / SCombatSideData / SEquipmentPool)

**CCombatant** (cb = 战斗方基座, 232B; writer 0X1413E41F0 + 0X1412BD820; ctor sub_1413E05F0; loader 0X1413E33A0): 基座定案 — **+24 = 宿主战斗回指** (RemoveUnit 经它取 attacker/defender/location/duration); **+216 = is_attacker 旗** (海军 pair-init 第一只=1 第二只=0)。

编制对象 (编成组/编制组合对象; unit 经虚槽[8] 取得) 布局补行 (推定):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +1136 | fixed×1e-5 | 计划度 (min_planning/has_max_planning 直读) | 推定 |

> ⚠ 编制对象+1136 与 §4.18 CArmy+1136 (bonus, tok 10931) 为**异基同名偏移**, 勿混。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +16 | fixed×1e-5 | shore_bombardment_collateral_damage_factor | >0 |
| +24 | CCombat* | **宿主战斗回指** (ctor a2) | 不序列化 |
| +32 | CUnit* | unit 容器数据指针 — {d, c} 8B 指针, id 对内联@elem+24 {type, id} | 恒写 |
| +33..+43 | — | = unit 容器尾 {cap@+40}  |  |
| +44 | u32 | unit 容器计数 | 恒写 |
| +45..+55 | — | = unit 容器尾 {alloc@+48}  |  |
| +56 | 侵入链表 | **参战 tag 链表 A = 参战单位 logical_country (unit+480) 集** — 32B 节点 {tag u32@0, prev@8, next@16, u8@24}; {head@56, tail@64, count@72} (消费点见下表) | 不序列化 |
| +80 | 侵入链表 | **参战 tag 链表 B = 与 logical 不同的 owner (unit+472) 集** (远征军原属主参战认定) {head@80, tail@88, count@96} | 不序列化 |
| +104 | 容器 24B | **参战 tag 平铺数组** {data@104, cap@112, count@116, alloc@120} — u32 tag (与链 A 同键 = logical_country 集, dedup sub_1401B0250) | 不序列化 |
| +128 | 匿名结构 (32B 形状) 向量 | **weighted_participants 容器本体 (32B)** — tok 10755 块 (1.19.2 该 token 尚为 erwan_reserved 未用; 元素按国家); RH 表: 空哨兵/数据@+136, 计数@+144 = 块门, 掩码 u32@+148, extra u8@+152 (桶数 = 掩码+1+extra); 桶 24B {hash u32@+0, 距离 byte@+4 (≠0 占用), tag id u32@+8, weight **i64 fixed×1e-5**@+16}; writer 0X1413E41F0 尾段 → sub_1411DCF90 (按 tag 升序发 `"TAG" 值`); loader case 10755 → 对象基 +128 | 计数≠0 写块 |
| +152 | u8 | 运行时旗 (ctor 0; 未名) | 不序列化 |
| +156 | f32 | 标量 (ctor 1063675494 = 0.9; 未名) | 不序列化 |
| +160 | fixed×1e-5 | size 容器数据指针 — fixed 数组 (1.19.2 @+128) | c>0 |
| +161..+171 | — | = size 容器尾 {cap@+168} (ctor 按国家数扩容) |  |
| +172 | u32 | size 容器计数 | c>0 |
| +173..+183 | — | = size 容器尾 {alloc@+176}  |  |
| +184 | fixed×1e-5 | losses | 恒写 |
| +192 | 容器 24B | **第二 per-country fixed 数组 = size 孪生** {data@192, cap@200, count@204, alloc@208} (1.19.2 @+160) — ctor sub_1413E05F0 与 +160 连调 sub_140611B00 按国家数扩容, 但全 dump 无读方 → 无消费者无 writer, 恒零沿袭 | 不序列化 |
| +216 | u8 | **is_attacker 旗** (ctor a3; RemoveUnit 以它选侧); **+218 = player_participates** | 不序列化 |
| +219 | uint8 | has_flanked_opponent | ≠0 写 yes |
| +224 | tag_id | last_hit → 引号串 | tid>0 |
| +232 | idpair 向量 | front id 对列表 {d, c} 8B 指针 | 同 unit |
| +233..+243 | — | = front 容器尾 {cap@+240}  |  |
| +244 | u32 | front 容器计数 | 同 unit |
| +245..+255 | — | = front 容器尾 {alloc@+248}  |  |
| +256 | 匿名结构 (NNB 形状)* | reserves id 对列表 | 同 unit |
| +257..+267 | — | = reserves 容器尾 {cap@+264}  |  |
| +268 | u32 | reserves 容器计数 | 同 unit |
| +269..+279 | — | = reserves 容器尾 {alloc@+272}  |  |
| +280 | 匿名结构 (NNB 形状)* | retreat id 对列表 | 同 unit |
| +281..+291 | — | = retreat 容器尾 {cap@+288}  |  |
| +292 | u32 | retreat 容器计数 | 同 unit |
| +293..+303 | — | = retreat 容器尾 {alloc@+296}  |  |
| +304 | CCombatTactic* | tactic ref → ru32(tac+152) | 指针非空 (writer 另有 vmethod80 门未接) |
| +305..+319 | — | = tactic ref 尾 + air_plane 前置  |  |
| +320 | 匿名结构 (飞机条目) | air_plane 容器数据指针 — {d, c} 8B 指针 → **CAirInLandCombat** (vt 0x1429A8270; writer 0X1412BD780 / reader 0x1412BA1D0): amount u32@A+20 / air_wing 对{A+8,+12} (13161) / air_count u32@A+16 (13162) / damage_factor fixed@A+24 (13163) 恒写; date hours@A+40 ≠ dword_143086B20 才写 (族A 证1, ptr=A+48) |  |
| +321..+331 | — | = air_plane 容器尾 {cap@+328}  |  |
| +332 | u32 | air_plane 容器计数 |  |
| +333..+343 | — | = air_plane 容器尾 {alloc@+336}  |  |
| +344 | fixed×1e-5 | anti_air_attack | >0 |
| +352 | uint32 | air_kills | >0 (<0x80000000 防御) |
| +360..+400 | fixed×1e-5 ×6 | air/ground/prevented dmg (str/org 对) | >0 |
| +353..+407 | — | = air_kills/air dmg 六值区内  |  |
| +408 | 匿名结构 (NNB 形状)* | org fixed 数组 (writer 0X1406128E0) | c>0 |
| +409..+419 | — | = org_loss_summary 容器尾 {cap@+416} (**键名正名 org_loss_summary** tok 13839) |  |
| +420 | u32 | org 容器计数 | c>0 |
| +421..+431 | — | = org_loss_summary 容器尾 {alloc@+424}  |  |
| +432 | 匿名结构 (NNB 形状)* | str_loss_summary fixed 数组 | c>0 |
| +433..+443 | — | = str_loss_summary 容器尾 {cap@+440}  |  |
| +444 | u32 | str_loss_summary 容器计数 | c>0 |
| +445..+455 | — | = str_loss_summary 容器尾 {alloc@+448}  |  |
| +456 | uint32 | org_loss_summary_index | 恒写 |
| +460 | uint32 | num_org_losses | 恒写 |
| +464 | NCombatLog::CStatsObserver 内嵌 | log (lb = cb+464; CStatsObserver 身份合一 — dtor 调 observer dtor sub_140CD8930@+464, 其 vt 0X295D748 slot2 恰 = 0X140CE0990) | 恒写块, 下表 |

> **实名与 1.19.3 漂移**: 自 +232 起的陆域段属 **CLandCombatant** (vt 0x1429A82C0, writer 0x1412BD820 = 基座 writer 0x1413E41F0 后缀自有段, 与 §4.22.2 边界战族 writer 追加同源); 1.19.3 相对 1.19.2 于基座 **+128 处插入 32B 新域 = weighted_participants 容器 (tok 10755, 定案)**, 自旧 +128 起布局**整段 +32 平移** (size 128→160 / losses 152→184 / 孪生 160→192 / is_attacker 184→216 / player_participates 186→218 / has_flanked 187→219 / last_hit 192→224 / front 200→232 … log 432→464, 全段 writer/loader/ctor 一致), 基座头 ≤+127 未动; 基座 200B → **232B** 定案 (last_hit 尾 +228 对齐; CLandCombatant 与 CNavalCombatant 自有段首字段均 @+232 互证)。

参战 tag 链表 A 消费点:

| 消费 | 定位 |
|---|---|
| leader_hours 结算 | — |
| InvolvesCountry | sub_1413E15E0 |
| cb+218 | — |
| 玩家单位 UI | — |
| 海战参战国旗 | sub_1417EDD40 → view+2656/+2664 两侧 |

log 子族 (lb):

| 偏移 (lb) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (group 条目) | group[N] 容器数据指针 — {d, c} 8B 指针 → writer 0X140CE00D0 (元素布局见本表后子表) | 对恒写 / 池空判写 / tid>0 |
| +9..+19 | — | = group 容器尾 {cap@+16} |  |
| +20 | u32 | group[N] 容器计数 |  |
| +21..+31 | — | = group 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (12B) | leader_hours[N] 容器数据指针 — {d, c} 12B 条 {对@0, time u32@8} | writer 0X140CE0B80 |
| +33..+43 | — | = leader_hours 容器尾 {cap@+40}  |  |
| +44 | u32 | leader_hours[N] 容器计数 |  |
| +45..+55 | — | = leader_hours 容器尾 {alloc@+48}  |  |
| +56 | 匿名结构 (32B) | damage[N] 容器数据指针 — {d, c} 32B 条 {from tid@8, receiver@12, to@16, value fixed@24} (**SDamageDone**, loader 内符号) | 恒写 (0X140CE11D0) |
| +57..+67 | — | = damage 容器尾 {cap@+64}  |  |
| +68 | u32 | damage[N] 容器计数 |  |
| +69..+79 | — | = damage 容器尾 {alloc@+72}  |  |
| +80 | fixed×1e-5 | total_damage | >0 |
| +88 | 内嵌 | combat_side_data (同下侧 writer) | |
| +89..+615 | — | = combat_side_data SCombatSideData 内嵌 528B 本体 (+88..+615, 下表) |  |
| +616 | fixed×1e-5 | progress (**结算时高者判胜** — consolidation sub_140CDB850 `if(*(v4+616)>*(v5+616)) 置 win 位`) | >0 |
| +624 | uint32×30 | modifier_hours | 恒写 |
| +625..+743 | — | = modifier_hours u32[30] 定长数组本体 (+624..+743; loader case 14172 范围解析 {+624,+744}) |  |
| +744 | uint8 | bit0→snow bit1→win; **bit2 = 已结算/consolidated 旗** (ctor 清三位 `&=0xF8`; consolidation `|=4u`; writer 不发) | 仅真写 yes |

lb+8 group[N] 条目 (ge = 元素基; CActivityInGroup, vt 0X295D6F8, sizeof 0x88=136):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| +8 | u32 | group 对.type — 对 {type@ge+8, id@ge+12} |
| +12 | u32 | group 对.id |
| +16..+63 | 匿名结构 | division_template 内联 8B 对 + enemy_dmg 16B {type, id, fixed} (子偏移未单列) |
| +64 | 池 | damaged_equipment 池 |
| +128 | tid | damage_dealer |
| +132 | tid | damage_taker |

**侧数据 = SCombatSideData** (528B; vt 0x2946xxx, ctor sub_140CD85E0 符号; writer 0X140CE0D20, combat_side_data/combat_data 双侧共用; S = 侧基)。全字段表:

| 偏移 (S) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | manpower_lost | >0 |
| +16 | fixed×1e-5 | manpower_lost_air_factor | >0 |
| +24 | 匿名结构 (NNB 形状)* | equipment_lost | 池空判 (见下) |
| +25..+87 | — | = equipment_lost 池本体尾 (64B SEquipmentPool) |  |
| +88 | SEquipmentPool ×4 (stride 64) | **池#2-5 = equipment_lost 按 reason[0..3] 四桶** (+88/+152/+216/+280) — 写入原语 sub_140CDA010 (CStatsObserver::AddEquipmentLoss, combatlog.cpp:0x2C4/0x2D5 断言): 恒写总池 (S+24) 后按 reason 分桶 (枚举见下表; 与 COrdersGroupLogs 四 CVector\<CLoss*\> 桶同维) | 池空判 |
| +344 | 匿名结构 (NNB 形状)* | equipment_captured_by_enemy | 池空判 |
| +345..+407 | — | = equipment_captured_by_enemy 池本体尾 (64B) |  |
| +408 | 匿名结构 (NNB 形状)* | equipment_recovered | 池空判 |
| +409..+471 | — | = equipment_recovered 池本体尾 (64B) |  |
| +472 | 匿名结构 (16B) | 16B 容器数据指针 — modifier_hours 数组 (token 0x375C) | B 候选 (零叶未实证) |
| +473..+483 | — | = modifier_hours 容器尾 {cap@+480} (hybrid buffer, RTTI allocator 条目 USModifierHours) |  |
| +484 | u32 | 16B 容器计数 | B 候选 (零叶未实证) |
| +485..+495 | — | = modifier_hours 容器尾 {alloc@+488}  |  |
| +496 | tag_id | tags 容器数据指针 — {d, c} u32 tid 数组 | c>0 |
| +497..+507 | — | = tags 容器 data 尾; cap 推定 +504 |  |
| +508 | u32 | tags 容器计数 | c>0 |
| +509..+519 | — | = tags 容器尾 + leader 对前置 (ctor 哨兵 qword_14333D528); alloc 推定 +512 |  |
| +520 | u32 | leader.type — id 对之 type (对 {type, id}) | 任一非零写 |
| +524 | u32 | leader.id — id 对之 id | 任一非零写 |

reason 枚举 (equipment_lost 四桶分桶键):

| 值 | 名称 | 判据/语义 |
|---|---|---|
| 0 | combat | — |
| 1 | attrition | — |
| 2 | attrition_in_combat | combats@unit+424 非空 |
| 3 | training | og+413 training 旗 + TRAINING_MIN_STRENGTH 门 |

注: 存档 reason 值实测 {0,1,3}; 证伪参照 = CAIMilitaryMinister AI 备战评估。

**池空判** 0X141010BA0: 容器A {d@P+8, c@P+20} 24B 条 elem+16 全零 → 整块不写。

**SEquipmentPool** (writer 0X141012DB0; 战斗侧/空军翼/合同族共用; P = 包装基址)。⚠ **同体异名统一 (定案)** (全书集中登记, 他处行内以「同体异名」短标指代): ① 正名 **SEquipmentPool** (对象域别名 CEquipmentVariantPool — 同 writer 0X141012DB0 同布局, 见 §4.23.2/§4.24); ② 正名 **SCombatData** (命名空间限定形 NCombatLog::CManager — vt 0X295D8D8, 见下 combat_log)。

| 偏移 (P) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (24B) | 空判容器A 容器数据指针 — {d, c} 24B 条 | 空判用 |
| +9..+19 | — | = 空判容器A 尾 {cap@+16} |  |
| +20 | u32 | 空判容器A 容器计数 | 空判用 |
| +21..+31 | — | = 空判容器A 尾 {alloc@+24} |  |
| +32 | CEquipmentVariant* | 条目 容器数据指针 — {d, c} 16B {variant, amount fixed×1e-5}; id 对 = {type@var+8, id@var+12} | 条目写门 amount≠0 ∨ az |
| +33..+43 | — | = 条目容器尾 {cap@+40} |  |
| +44 | u32 | 条目 容器计数 |  |
| +45..+55 | — | = 条目容器尾 {alloc@+48} |  |
| +56 | uint8 | **az = allow_zero_entries** | 恒写 |

**战斗历史 (CCombatHistory)**: 链表头@gs+648+8, next@e+56, 存档序 = 链表序; 无 start_date。逐条 (e = 条目):

| 偏移 (e) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +16 | hours | **end_date 族B** (§3.7a) | 恒写 |
| +17..+31 | — | = end_date CGregorianDate vt 槽区 (节点 vt@e+8) |  |
| +32 | uint32 | type | 恒写 |
| +36 | tag_id | attacker tid (tid=0 → "---") | 恒写 |
| +40 | tag_id | defender tid (tid=0 → "---") | 恒写 |
| +44 | uint32 | location | 恒写 |
| +45..+55 | — | = location 尾 + next 前置  |  |
| +56 | 匿名结构 (NNB 形状)* | next (链表) | — |

**combat_log**: gs+2176 = manager 指针数组 (按国家 id 索引), 计数@gs+2188; manager (SCombatData 同体异名 ⚠②, vt 0X295D8D8) **块写门 = 日志数 count@mgr+20 ≠ 0** (0X140CDD360, 空日志国家整块不写)。manager writer 0X140CE0580:

| 偏移 (mgr) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (log 条目) | log[N] 容器数据指针 — {d, c} 8B 指针逐条 (元素 vt 0X295D888 校验) | count≠0 = 块门 |
| +9..+19 | — | = log 容器尾 {cap@+16} |  |
| +20 | u32 | log[N] 容器计数 | count≠0 = 块门 |
| +21..+31 | — | = log 容器尾 {alloc@+24} |  |
| +32 | uint32 | tag tid | 恒写引号 |

条目 COrdersGroupLogs (0xE8, writer 0X140CE0710):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (子条目) | enemy_equipment 容器数据指针 — {d, c} 8B 指针子条目 | c>0 |
| +9..+19 | — | = enemy_equipment 容器尾 {cap@+16}  |  |
| +20 | u32 | enemy_equipment 容器计数 | c>0 |
| +21..+31 | — | = enemy_equipment 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (子条目) | equipment_recovered 容器数据指针 — {d, c} 同构 | c>0 |
| +33..+43 | — | = equipment_recovered 容器尾 {cap@+40}  |  |
| +44 | u32 | equipment_recovered 容器计数 | c>0 |
| +45..+55 | — | = equipment_recovered 容器尾 {alloc@+48}  |  |
| +56 | CLoss* 向量 | **equipment 四容器合并序 #1** {d, c} 8B 指针, writer 按容器序连续写 — +56..+151 = CVector\<CLoss*\>[4] 内联数组 (eh vector dtor 铁证); 元素 CLoss 族 vt 0X295D518 / CEquipmentLoss 0X295D568 / CManpowerLoss 0X295D5B8; CLoss::Serialize 0X140CE0540 = reason@+8 tok 13902 + date 代理@+32 |  |
| +57..+67 | — | = 四容器 #1 尾 {cap@+64}  |  |
| +68 | u32 | 四容器 #1 计数 | |
| +69..+79 | — | = 四容器 #1 尾 {alloc@+72}  |  |
| +80 | 匿名结构 (NNB 形状)* | 四容器 #2 | |
| +81..+91 | — | = 四容器 #2 尾 {cap@+88}  |  |
| +92 | u32 | 四容器 #2 计数 | |
| +93..+103 | — | = 四容器 #2 尾 {alloc@+96}  |  |
| +104 | 匿名结构 (NNB 形状)* | 四容器 #3 | |
| +105..+115 | — | = 四容器 #3 尾 {cap@+112}  |  |
| +116 | u32 | 四容器 #3 计数 | |
| +117..+127 | — | = 四容器 #3 尾 {alloc@+120}  |  |
| +128 | 匿名结构 (NNB 形状)* | 四容器 #4 | |
| +129..+139 | — | = 四容器 #4 尾 {cap@+136}  |  |
| +140 | u32 | 四容器 #4 计数 | |
| +141..+151 | — | = 四容器 #4 尾 {alloc@+144}  |  |
| +152 | 匿名结构 (manpower 子条目) | manpower 容器数据指针 — {d, c} → 子条目: reason u32@+8 恒写, date hours@+24 (族A, ptr=+32) 恒写, mp_losses 3×u32@+40 恒写 |  |
| +153..+163 | — | = manpower 容器尾 {cap@+160}  |  |
| +164 | u32 | manpower 容器计数 |  |
| +165..+175 | — | = manpower 容器尾 {alloc@+168}  |  |
| +176 | CPerTemplateStats* | division_template 容器数据指针 — {d, c} → CPerTemplateStats (0x38): division 对 {type@+8, id@+12} 恒写, date hours@+40 (族A 证3, ptr=+48) 恒写, SCombatStats 子对象@+16 vt 槽2 虚写 win u32@条目+24 / total u32@条目+28 |  |
| +177..+187 | — | = division_template 容器尾 {cap@+184}  |  |
| +188 | u32 | division_template 容器计数 |  |
| +189..+199 | — | = division_template 容器尾 {alloc@+192}  |  |
| +200 | 匿名结构 (8B) | combat_data_index 容器数据指针 — 内联 8B {id i32@0 (符号化), attacker u8@4 → yes/no} | 恒写 |
| +201..+211 | — | = combat_data_index 容器尾 {cap@+208}  |  |
| +212 | u32 | combat_data_index 容器计数 | 恒写 |
| +213..+223 | — | = combat_data_index 容器尾 {alloc@+216}  |  |
| +224 | u32 | group.type — id 对之 type (对内联 {type, id}) | 恒写 |
| +228 | u32 | group.id — id 对之 id | 恒写 |

装备子条目 (writer 0X140CE04F0) = 三件套:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | reason |
| +9..+23 | — | = CLoss reason 尾 + date 24B vt1@+16  |
| +24 | hours | date (族A, ptr=+32) |
| +25..+39 | — | = date 24B 尾 {hours@+24, vt2@+32=代理}  |
| +40 | 内嵌 | SEquipmentPool 块 (0x2F4E) |

**combat_data_entry 池** (存档顶层块名; 引擎侧 = 全局静态存储不经 gs; 条目无独立 RTTI 类 — 负定案)。三件套:

| 项 | 地址 | 说明 |
|---|---|---|
| 数据数组指针 | qword_14333CB70 (BASE+53623808) | 条目 **1096B**, 按槽位索引 |
| ref_count 并行 u16 数组 | qword_14333CB88 (BASE+53623832) | refs[2×slot] little-endian u16, **>0 = 存活才写** |
| 存活计数 | dword_14333CBB8 (BASE+53623880) | writer (0X140CDFFF0) 循环: 存活数达 count 即终止 |

条目 1096B = {id u32, ref u32, combat_data 块 (token 14165)} — combat_data 内含 attacker/defender 两侧各 528B = SCombatSideData@CStatsObserver@NCombatLog。条目头 writer 0X140CE0CD0: id u32 / ref_count / combat_data 块恒写。combat_data writer 0X140CE0BC0 (本体 = 1096B 条目; 侧 writer 同上 0X140CE0D20):

| 偏移 (cd) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 内嵌 | attacker 侧 | 恒写块 |
| +9..+535 | — | = attacker 侧 SCombatSideData 528B 本体 (+8..+535) |  |
| +536 | 内嵌 | defender 侧 | 恒写块 |
| +537..+1071 | — | = defender 侧 SCombatSideData 528B 本体 (+536..+1063) + date vt1@+1064  |  |
| +1072 | hours | **date (族A 证2, ptr=cd+1080)** | 恒写 |
| +1073..+1087 | — | = date 24B 尾 {hours@+1072, vt2@+1080=代理} + province 前置  |  |
| +1088 | uint32 | province | ≠0 |
| +1092 | uint8 | defensive_victory | 仅真写 yes |
| +1093 | uint8 | snow | 仅真写 yes |
| +1094 | uint8 | overrun | 仅真写 yes |
| +1095 | uint8 | player_is_attacker (token 0x4DBC) | 恒写 yes/no |

#### 4.22.5 CNavalCombat 海战战斗族

族对象层级与 writer 链:

| 层 | 匿名结构 (NNB 形状) | vtable | sizeof | writer |
|---|---|---|---|---|
| 1 | CNavalCombat | 0x1429DDB08 / 0X1429DBF90 (双表) | — | 0x141c6d0d0 (= 陆战基座 0X1413E4150 + 海军扩展) |
| 2 | CNavalCombatant (参战方) | 0x1429E3E98 (基 CCombatant 0x1429BBB40) | — | 0X141622520 |
| 3 | CFEXGroup (组) | 0x142a59ac8 (RTTI 直证) | 200=0xC8 | 0x141c6d0d0 |
| 4 | CFEXMember (组内 member 条目) | 0X142A1F1C8 (RTTI 直证) | 456=0x1C8 | 0X1419760B0 |
| 5 | CFEXAir (组内 air 条目) | 0x142A212E8 (RTTI 直证) | 328=0x148 | 0X14197D990 |
| 6 | convoy 条目 (挂 CNavalCombat 下; 无独立 RTTI 类名) | — | 0x48=72 (ctor sub_141AD7DF0) | 0X141AD8690 |

进海战分支判据 = day u32@c+48 > 0x7FFFFFFF (0xFFFFFFFF = −1 表示海战)。

**CNavalCombat** (c = 对象基; a1 = c)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | holder id 对.type (B400 内联; 非槽头 e+8/+12 — 那是包装 type=3) — **GUI: NavalCombatView target** (refid → view+64; OnReload 0X1417EA930 再归一化) | 恒写 |
| +12 | uint32 | holder id 对.id | 恒写 |
| +13..+23 | — | = **vt2 持久化 vtable 槽 (obj+16)** — 陆 0x1429a84b8 / 海 0X1429DBF90; obj 包装布局: obj+0 vt1 / obj+8 refid / obj+24 holder 对 |  |
| +24 | 匿名结构 (NNB 形状)* | attacker 参战方 (直指, 无陆战容器包装) | |
| +32 | 匿名结构 (NNB 形状)* | defender 参战方 | |
| +40 | 匿名结构 (NNB 形状)* | location → 省 idx = u32@对象+164 (陆海基座共有) | 恒写 |
| +48 | uint32 | day (基座共有; 海战按有符号解释, 0xFFFFFFFF = −1) | 恒写 |
| +52 | uint32 | duration (基座共有) | 恒写 |
| +56 | 匿名结构 (NNB 形状)* | terrain 串对象 (门 byte@串对象+16, 串@串对象+24) | |
| +64 | u8 ×3 | 运行时旗 (+64/+65/+66; ctor 0, writer 不发) — 本表全书统一 res (类布局) 坐标 (attacker@+24 等多函数三向互证) | 不序列化 |
| +72 | 56B | 运行时区 (+72..+127 = obj+88..+143): **定案 = 4×16B 内联槽 {ptr, fixed}** (活跃陆战槽内容 = {type 70 idb 条目 (装备族), fixed 1.0/2-3/144-204/1.0}; 三级 ctor 与 writer/loader 均不触及 → runtime-only, 槽内 fixed 语义未决) | 不序列化 |
| +128 | 匿名结构 (NNB 形状)* | 运行时指针 (ctor 0; 未名) | 不序列化 |
| +136 | CNavalCombatant* | **attacker 镜像指针** (第二份; pair-init sub_1415C28F0 同写) | 不序列化; 定案: 生命期所有权副本 — dtor sub_1415C43E0 经镜像释放两参战方  |
| +144 | CNavalCombatant* | **defender 镜像指针** (第二份) | 同上  |
| +152 | u32 | 运行时标量 (ctor 0; 未名) | 不序列化  |
| +176 | convoy 条目* | convoy[N] 容器数据 — 条目 writer 0X141AD8690 | count>0 且 client/ntt 非空 |
| +177..+187 | — | = convoy 容器尾 {cap@+184} (convoy 条目 sizeof 0x48=72 = vt@0 + 表 8 字段恰满) |  |
| +188 | uint32 | convoy[N] 容器计数 | 同上 |
| +189..+199 | — | = convoy 容器尾 {alloc@+192}  |  |
| +200 | uint32 | client 容器数据 — 内联 8B refid 对, 裸名重复 | |
| +201..+211 | — | = client 容器尾 {cap@+208}  |  |
| +212 | uint32 | client 容器计数 | |
| +213..+223 | — | = client 容器尾 {alloc@+216}  |  |
| +224 | uint32 | naval_transport 容器数据 — 内联 8B refid 对, 裸名重复 | |
| +225..+235 | — | = naval_transport 容器尾 {cap@+232}  |  |
| +236 | uint32 | naval_transport 容器计数 | |
| +237..+247 | — | = naval_transport 容器尾 {alloc@+240}  |  |
| +248 | uint32 | unique_id | 恒写 |
| +252 | uint8 | port_strike | 仅真写 yes |
| +253 | uint8 | naval_strike | 仅真写 yes |
| +256 | uint32 | sunk_convoys | >0 才写 |
| +260 | uint8 | hide | 仅真写 yes |
| +261 | uint8 | convoy_combat | 仅真写 yes |
| +264 | fixed×1e-5 | progress — **GUI: 战斗进度条** (combat vt[25] → view+2704; COMBAT_PROGRESS_DESC) | 恒写 |

**CNavalCombatant** (cb = 对象基; writer 0X141622520)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +32 | CUnit* 向量 | unit 容器数据 (8B 指针元) — id 对内联@elem+24, 裸名重复 | |
| +33..+43 | — | = unit 容器尾 {cap@+40, alloc@+48}  |  |
| +44 | uint32 | unit 容器计数 | |
| +45..+231 | — | = **CCombatant 基座字段区** (基座 ctor sub_1413E05F0 被首调: weighted_participants@128/size@160/losses@184/is_attacker@216/has_flanked@219/last_hit@224 等全在其中; 海军只是不发这些键 — 归属定案) |  |
| +232 | uint32 | group[N] 容器数据 — **GUI: 海战双侧网格** (攻/守组×舰图标 → CCombatBoxGrids+24 8 槽 + CFEXShipIcon; sub_1417ED140) | |
| +233..+243 | — | = group[N] 容器尾 {cap@+240}  |  |
| +244 | uint32 | group[N] 容器计数 | |
| +245..+255 | — | = group 容器尾 {alloc@+248}  |  |
| +256 | 容器 24B | **CFEXAir* 数组** {data@256, cap@264, count@268, alloc@272} (: ctor sub_141976630/sizeof 328 铁证) | 不序列化 |
| +280 | 容器 24B | **参战将领 (admiral) 指针数组** {data@280, cap@288, count@292, alloc@296} (: leader+3680/+440 军衔等级反推铁证) | 不序列化 |
| +304 | CCombatTactic* | **CCombatTactic\*** (RTTI 直证; +64 处无名串) — 海战 writer sub_141622520 **不发射本槽** (海战将领面板运行时专用); 陆战侧同槽由 sub_1412BD820 发 tok 11927 `tactic` (门 = 指针非空 ∧ vt[80]) | 不序列化 |
| +312 | 匿名结构 (NNB 形状)* | last_leader → id 对@ptr+8 | |
| +320 | uint8 | disengage | |
| +328 | fixed ×2 | **screening_efficiency / carrier_screening_efficiency** (+328/+336) | 不序列化 |
| +344 | fixed×1e-5 | positioning | 恒写 |
| +352 | fixed×1e-5 | new_ships_positioning_penalty | ≠0 才写 |
| +360 | fixed×1e-5 | positioning_dominance_bonus | 恒写 |
| +368 | fixed×1e-5 | anti_air | 恒写 |
| +376 | fixed×1e-5 | total_initial_strength | 恒写 |
| +384 | fixed×1e-5 | total_damage_dealt | 恒写 |
| +392 | fixed×1e-5[36] | damage_dealt_by_gun_types.#1 — 36 值恒写单行 | 恒写 |
| +393..+679 | — | = damage_dealt_by_gun_types fixed[36] 数组本体 (+392..+679) |  |
| +680 | f32 | **damage_dealt_by_ship_types 表 load factor = 1.0f** (ctor 1065353216) | 不序列化  |
| +688 | 匿名结构 (16B 形状) RH 桶数组 | damage_dealt_by_ship_types — token→fixed RH 哈希表 {load f32@680, buckets@688, count@696 (=写门), aux 16B 容器@704}; loader 经 sub_14161A260(+680, token) 按键插入; 元 {token@+16, fixed@+24}, 键 = token 名 | 门 *(cb+696)≠0 |

- is_attacker (基座+216) GUI 消费: 脱离战斗命令载荷 CDisengageFromNavalCombatCommand {+40 海战 refid tok 0x2916, +48 is_attacker tok 0x28F5}; 玩家侧选取 sub_1417E7B30。
- screening 消费: CFEX 伤害减免 = 1−(1−a)(1−b) 合成 (SCREENING_TOOLTIP_LOW_INFO + 四个 SCREEN_RATIO/CAPITAL_RATIO define 加权铁证)。

**组对象 = CFEXGroup** (g = 组基; sizeof 200; vt 0x142a59ac8; ctor sub_141C69AF0; writer 0x141c6d0d0; loader 0X141C6C970):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | CFEXMember* 向量 | member[N] 容器数据 (vt 0X142A1F1C8, sizeof 456; ctor sub_14196F350) | |
| +9..+19 | — | = member 容器尾 {cap@+16}  |  |
| +20 | uint32 | member[N] 容器计数 | |
| +21..+31 | — | = member 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (NNB 形状)* | opponent_group = *(g+32) → 在 *(oppg+56) 的 group 数组找下标 (**loader 读档时清零**: case 12419 u32 解析 + `*(+32)=0`, 运行时再解回指针 — 定案) | 找到才写 |
| +40 | i32 | **opponent_group 下标缓存** (ctor = −1) | 不序列化  |
| +48 | fixed×1e-5 | forces_compare | 恒写 |
| +56 | CNavalCombatant* | **宿主参战方回指** (ctor a2; 与「*(oppg+56) 的 group 数组」自洽: oppg+56=对方 combatant, 其+232=group 数组) | 不序列化  |
| +64 | uint32 | disengage_counter (**ctor = dword_143335E1C define 初值**) | 恒写 |
| +68 | uint32 | chasing_counter | 恒写 |
| +72 | qword ×2 | 运行时 (+72/+80; ctor 0, 未名) | 不序列化  |
| +88 | CFEXAir* 向量 | air[N] 容器数据 (vt 0x142A212E8, sizeof 328; ctor sub_141976630) | |
| +89..+99 | — | = air 容器尾 {cap@+96}  |  |
| +100 | uint32 | air[N] 容器计数 | |
| +101..+111 | — | = air 容器尾 {alloc@+104}  |  |
| +112 | CFEXMember* 向量 | members_to_delete 容器数据 (零样本未接; 推定同 member 型) | |
| +113..+123 | — | = members_to_delete 容器尾 {cap@+120} (loader case 13869 创建 member 推入) |  |
| +124 | uint32 | members_to_delete 容器计数 | |
| +125..+135 | — | = members_to_delete 容器尾 {alloc@+128}  |  |
| +136 | CFEXAir* 向量 | airs_to_delete 容器数据 (零样本未接; 推定同 air 型) | |
| +137..+147 | — | = airs_to_delete 容器尾 {cap@+144} (loader case 13870 创建 air 推入) |  |
| +148 | uint32 | airs_to_delete 容器计数 (alloc@+152) | |
| +160 | qword ×4 | 运行时 (+160/+168/+176/+184; ctor 0, 未名) + +192 u32 (sizeof 200 尾部) | 不序列化  |

**member 条目 = CFEXMember** (m = 条目基; sizeof 456; vt 0X142A1F1C8; ctor sub_14196F350; writer 0X1419760B0; loader 0X1419748F0):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | ship 对.type (ship 对 {m+8,+12} / convoy 对 {m+16,+20}) | 四值任一非零写 |
| +12 | uint32 | ship 对.id | 同上 |
| +16 | uint32 | convoy 对.type | 同上 |
| +20 | uint32 | convoy 对.id | 同上 |
| +24 | 内嵌 | member.cached_info (见下表) | |
| +25..+223 | — | = cached_info **SCachedInfo 内嵌 200B 本体** (带自 vt CFEXMember::SCachedInfo::vftable; 全字段见下 member.cached_info 表) |  |
| +224 | uint32 | state | 恒写 |
| +228 | uint32 | hours_to_arrive | 恒写 |
| +232 | CFEXGroup* | **宿主组回指** (ctor a2) | 不序列化  |
| +240 | fixed×1e-5[3] | cooldown.#1 — 3 值恒写 | 恒写 |
| +241..+263 | — | = cooldown fixed[3] 本体 (+240..+263; loader case 14622 范围 {+240,+264}) |  |
| +264 | 内联 32B | damage_received 容器数据 — 元 {vt@0, ship 对@8, tag tid@16, damage i64@24}; writer 0X1419765D0 键名直证 = 10400 `ship` / 10754 `tag` / 12459 `damage` | c>0 才写 |
| +265..+275 | — | = damage_received 容器尾 {cap@+272}  |  |
| +276 | uint32 | damage_received 容器计数 | 同上 |
| +277..+287 | — | = damage_received 容器尾 {alloc@+280}  |  |
| +288 | uint32 | unique_id | 恒写 |
| +292 | uint32 | critical_hits_received | >0 才写 |
| +296 | uint32 | evacuated | ≠0 才写 |
| +300 | uint32 | hidden (**ctor = −1** = 写门 ≠0xFFFFFFFF 来源) | ≠0xFFFFFFFF 才写 |
| +304 | fixed×1e-5 | escape_progress | ≠0 才写 |
| +312 | 块基 | last_target 块 (writer 0X1419763F0: convoy u8@lt+8 / size u32@lt+12) | 门 b@m+328 ≠0 |
| +313..+327 | — | = last_target 块 **CLastTargetInfo** 本体 (vt 0x142a20e98; loader case 11081: convoy u8@+320, size u32@+324, 首载置 vt@+312 并立门 +328) |  |
| +328 | uint8 | last_target 门字节 | ≠0 才写块 |
| +336 | SAirHit* 向量 | air_hit[N] 容器数据 (元素 vt 0X1429DC138, sizeof 24, ctor sub_1415C5D80; writer 0X1415C7C60): tag tid@ah+20 恒写; equipment_variant_index = *(ah+8) 非空 → 对@ptr+8; count u32@ah+16 恒写 | |
| +337..+347 | — | = air_hit 容器尾 {cap@+344} (SAirHit malloc 0x18=24 互证) |  |
| +348 | uint32 | air_hit[N] 容器计数 | |
| +349..+359 | — | = air_hit 容器尾 {alloc@+352}  |  |
| +360 | 8B 指针 向量 | **damage_received 容器** {data@360, cap@368, count@372, alloc@376} — dtor 虚删 + 合并器 sub_1415C75C0 (经 thunk sub_141973D60 = `(a1+360)`) + 持久化迁移至 ShipEntry+264; 合并器语义 = **tag 键控聚合累加器** (按 8B 键@元素+8 + tag@+20 配对, 命中则 i32@元素+16 累加并虚析构源元素, 未命中则 1.5× 增长 push); writer 不发射 (runtime-only) | 不序列化 |
| +384 | SNavalHit* 向量 | naval_hit[N] 容器数据 (元素 vt 0x1429DDD38, sizeof 80, ctor sub_1415C6010; writer 0X1415C7CD0 = 元素 vt[2]): target@h+8 / name 串@h+16 / convoy u8@h+48 / damage fixed@h+56 / strength fixed@h+64 / last_hit u8@h+72 全恒写 | |
| +385..+395 | — | = naval_hit 容器尾 {cap@+392} (SNavalHit malloc 0x50=80 互证) |  |
| +396 | uint32 | naval_hit[N] 容器计数 | |
| +397..+407 | — | = naval_hit 容器尾 {alloc@+400}  |  |
| +408 | fixed×1e-5[6] | damage_received_by_gun_types.#1 — 6 值恒写 (loader case 15518 范围 {+408,+456}; 456=sizeof 恰满) | 恒写 |

**member.cached_info** (ci = m+24, 内嵌; writer 0X141976430)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | tag_id | tag (ctor 经 sub_140BB3E00 注册 — 同国家表 registered-tag 模式) | 恒写 |
| +12 | uint32 | index | 恒写 |
| +16 | uint32 | type | 恒写 |
| +24 | fixed×1e-5 | build_cost_ic | ≠0 才写 |
| +32 | fixed×1e-5 | strength | ≠0 才写 |
| +40 | uint8 | pride_of_the_fleet | |
| +41 | uint8 | convoy | |
| +48 | string | ship 舰名 (len@+64) | len≠0 才写 |
| +49..+79 | — | = ship 名 MSVC SSO 32B 本体 {size@+64, cap@+72}  |  |
| +80 | string | equipment_variant (len@+96) | len≠0 才写 |
| +81..+111 | — | = equipment_variant MSVC SSO 32B 本体 {size@+96, cap@+104}  |  |
| +112 | string | sprite ("convoy"/"submarine"…) | 恒写 |
| +113..+143 | — | = sprite MSVC SSO 32B 本体 {size@+128, cap@+136}  |  |
| +144 | string | sunk_by (len@+160) | len≠0 才写 |
| +145..+175 | — | = sunk_by MSVC SSO 32B 本体 {size@+160, cap@+168}  |  |
| +176 | uint32 | highest_eq_variant id 对.type | 对 ≠ qword_14333D528 哨兵 |
| +180 | uint32 | highest_eq_variant id 对.id | 同上 |
| +184 | uint32 | convoy_id 对.type | 任一非零 |
| +188 | uint32 | convoy_id 对.id | 同上 |
| +192 | int32 | convoy_index | ≥0 才写 |

**group air 条目 = CFEXAir** (ae = 条目基; sizeof 328; vt 0x142A212E8; ctor sub_141976630; writer 0X14197D990; loader 0X14197CBF0; **+8 = CFEXGroup\* 宿主组回指**, ctor a2):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +24 | int32 | carrier | ≠−1 才写 |
| +28 | uint32 | air_base 对.type | 任一非零 |
| +32 | uint32 | air_base 对.id | 同上 |
| +40 | uint32 | naval_strike 容器数据 — 内联对, 裸名重复 | |
| +41..+51 | — | = naval_strike 容器尾 {cap@+48}  |  |
| +52 | uint32 | naval_strike 容器计数 | |
| +53..+63 | — | = naval_strike 容器尾 {alloc@+56}  |  |
| +64 | uint32 | air_wing 容器数据 — 内联对, 裸名重复 | |
| +65..+75 | — | = air_wing 容器尾 {cap@+72}  |  |
| +76 | uint32 | air_wing 容器计数 | |
| +77..+87 | — | = air_wing 容器尾 {alloc@+80}  |  |
| +88 | uint32 | max | 恒写 |
| +92 | uint32 | alive | 恒写 |
| +96 | uint32 | casualties | 恒写 |
| +100 | tag_id | tag (**ctor 经 sub_140BB3E00 注册** — 同国家表 registered-tag 模式) | 恒写 |
| +104 | — | = last_external_wave_date 24B vt1 槽 (见下) |  |
| +112 | hours | last_external_wave_date — **24B {vt1@+104, hours@+112, vt2@+120=ADEC0 代理}** (ctor 双 vt + hours=dword_143086B20 默认; 24B 定案) | 恒写 |
| +113..+119 | — | = hours 尾  |  |
| +128 | uint8 | external_wave_complete | 恒写 yes/no |
| +129 | uint8 | external (**ctor = (a3==0)** — 初值定案) | 恒写 yes/no |
| +136 | string | name | 恒写 |
| +137..+167 | — | = name MSVC SSO 32B 本体 {size@+152, cap@+160=15}  |  |
| +168 | string[32B] | names 串数组 — 引号单行 | 门 u32@ae+180 ≠0 |
| +169..+179 | — | = names 容器尾 {cap@+176}  |  |
| +180 | uint32 | names 门 | |
| +181..+191 | — | = names 容器尾 {alloc@+184} (门 = count@+180) |  |
| +192 | fixed×1e-5 | damage_mult (ctor=100000=1.0) | 恒写 |
| +200 | qword ×6 | 运行时标量 (+200/+208/+216/+224/+232/+240; ctor 全零, 未名) | 不序列化  |
| +248 | uint32 | time_duration | 恒写 |
| +256 | SNavalHit* 向量 | naval_hit[N] 容器数据 (同 member 条目) | |
| +257..+267 | — | = naval_hit 容器尾 {cap@+264}  |  |
| +268 | uint32 | naval_hit[N] 容器计数 | |
| +269..+279 | — | = naval_hit 容器尾 {alloc@+272}  |  |
| +280 | SAirHit* 向量 | air_hit[N] 容器数据 (同 member 条目) | |
| +281..+291 | — | = air_hit 容器尾 {cap@+288}  |  |
| +292 | uint32 | air_hit[N] 容器计数 |  |
| +293..+303 | — | = air_hit 容器尾 {alloc@+296} |  |
| +304 | 容器 24B | **damage_received 容器** {data@304, cap@312, count@316, alloc@320} — sizeof 328 恰满; 与 AirEntry+112 **同族同源** (合并器 sub_1415C75C0, 经 thunk sub_14197A570 = `(a1+304)`); 持久化迁移至 AirEntry+112; writer 不发射 (runtime-only) | 不序列化 |

**convoy 条目** (cv = 条目基; writer 0X141AD8690; 存档键 convoy; RTTI 无独立类名):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | id 对.type (B400 内联) | 恒写 |
| +12 | uint32 | id 对.id | 恒写 |
| +13..+23 | — | = CReferenceObject 头尾 {u8 注册标志@+16, pad} |  |
| +24 | 匿名结构 (NNB 形状)* | equipment_variant_index — 非空 → 对@ptr+8 | |
| +32 | fixed×1e-5 | strength | 恒写 |
| +40 | fixed×1e-5 | organisation | 恒写 |
| +48 | 匿名结构 (NNB 形状)* | tag 三段链① client 对 — 有效 → tag = *(obj+24) | tid>0 写 |
| +56 | 匿名结构 (NNB 形状)* | tag 三段链② transfer 对 — 有效 → tag = *(obj+88) | 同上 |
| +64 | uint32 | tag 三段链③ 兜底 tid | tid>0 写 |
| +68 | uint32 | convoy_index | 恒写 |

重复块契约 (原始存档实证): `unit={ id=N type=T }` 单 refid 块被
savefull 折叠成单叶, 同父重复保持裸名重复 (multiset, 同 focus.completed),
不编 [N]; 多叶块 (group/air_plane/leader_hours/damage) 才按 (父,块名) 编号。

#### 4.22.6 naval_combat_result 全族 (gs+1472 容器; ⚠ 与 4.22.5 是**两个族**)

进行中海战 (4.22.5) 与 战果报告池 (本节) 无结构关系, 仅命名相近。

容器 = gs+1472 {d} / gs+1484 {c} 裸 {d, c@d+12} 形态 (非对象), 元素 8B 指针。顶层 writer 链: sub_1401F2E40 逐元素 ADEC0 (tok 0x34FC=13564, elem) → 共享壳 0X1424BEC50 → 块内容 0X140CE6B20 (不在索引; 反汇编 + ctor 0X140CE15E0 / reader 0X140CE5AF0 三向互洽)。块门 = 计数>0 仅此一门 (save/checksum 同路径)。提取形态 = 顶层匿名重复块, 块级 [N] 记在维度 (首块裸, 第 2 起 [2]..; 维度内路径不含块名)。sizeof(CNavalCombatResults) = **0x168=360** 定案: 读档工厂 case 13564 `malloc_base(0x168)` → ctor → push gs+1472 (dump 行 5207661); 第二分配点 combatnaval.cpp:973 同 0x168。读档工厂另在 gs+1496 经 sub_1401B7250 维护 location→块 运行时桶索引 — 注册器 sub_1401CAE40 全体**无 writer 调用** → 纯运行时派生索引, 不发射 (定案)。

**CNavalCombatResults** (vt 0x14295DD70; sizeof 0x168=360; 块内容 writer 0X140CE6B20)。发射序 = id → location → date → attacker → defender → port_strike → naval_strike → importance → to_discard_date → shown_to_countries (表行序 = 偏移升序, 发射序以本句为准)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | uint32 | 自 refid.type (全局命名空间 4713) | 恒写 (`id` 块 0X142220340 同行双写; tok 0xB=11) |
| +12 | uint32 | 自 refid.id | 恒写 (同上) |
| +16 | uint8 | flag (ctor=0, 语义未追) | writer 不发 |
| +24 | CNavalCombatResultSide 内嵌 (112B) | attacker | 恒写 (ADEC0 整块; tok 0x28F5) |
| +25..+135 | — | = **attacker CNavalCombatResultSide 内嵌 112B 本体** (+24..+135) 内部 — 子布局见下表  |  |
| +136 | CNavalCombatResultSide 内嵌 (112B) | defender | 恒写 (tok 0x28F6) |
| +137..+247 | — | = **defender CNavalCombatResultSide 内嵌 112B 本体** (+136..+247) 内部  |  |
| +248 | 匿名结构 (NNB 形状)* | 两侧迭代对 {&attacker, &defender} 之一 | writer 不发 |
| +256 | 匿名结构 (NNB 形状)* | 迭代对之另一 | writer 不发 |
| +264 | uint32 | location (省 id) | 恒写; tok 0x286D |
| +272 | vptr | CGameDate 载体 (ctor 写 vt) | writer 不发 |
| +280 | int32 | date 值 (ctor = 43791240 "-1.1.1.1" 合法值) | 恒写 (经别名槽 +288; tok 0x284A) |
| +288 | vptr | date 序列化别名槽 (vt 0x1427183d8; 别名 writer 0X140533F70 读 this-8) | — |
| +296 | uint8 | port_strike | 恒写 yes/no 均写 (tok 0x32AB) |
| +297 | uint8 | naval_strike | 恒写 yn (tok 0x309D) |
| +304 | vptr | CGameDate 载体 (to_discard) | writer 不发 |
| +312 | int32 | to_discard_date 值 (ctor = 43808760 "1.1.1.1") | 恒写 (经别名槽 +320; tok 0x3C96) |
| +320 | vptr | to_discard 序列化别名槽 (同 vt) | — |
| +328 | uint32 | importance (ctor 默认 3; load 分派置 0; 黑档实测 0/1/2 = 游戏逻辑赋值) | 恒写; tok 0x3C97 |
| +336 | int32 向量 | shown_to_countries 容器数据 — int 国家 id 数组 stride 4, 原生逐行裸 tag 串 | **计数@+348≠0 才发块**; tok 0x4DD9; 提取形 `shown_to_countries.#N` 恒编号 |
| +344 | 匿名结构 (NNB 形状)* | 容器 end 槽 | — |
| +348 | uint32 | shown_to_countries 容器计数 | |

**CNavalCombatResultSide** (内嵌 0x70=112B; vt 0x14295DD20; writer 0X140CE6760; 继承 CPersistent — 内嵌对象无自 refid)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | CNavalCombatAirEntry* 向量 | air_wing 数组数据 — 8B 指针元素 → CNavalCombatAirEntry; 重复键第 2 起编 [N] | 门 计数@+20>0; tok 0x3369 air_wing |
| +9..+19 | — | = air_wing 容器 {d@8, **cap@16**, c@20, alloc@24} 的 data 尾 + cap@16 (pdx 24B) |  |
| +20 | int32 | air_wing 计数 | |
| +21..+31 | — | = air_wing count@20 尾 + **alloc@24**  |  |
| +32 | CNavalCombatShipEntry* 向量 | ship 数组数据 — 8B 指针元素 → CNavalCombatShipEntry; [N] 同上 | 门 计数@+44>0; tok 0x28A0 ship |
| +33..+43 | — | = ship 容器 {d@32, **cap@40**, c@44, alloc@48} 的 data 尾 + cap@40  |  |
| +44 | int32 | ship 计数 | |
| +45..+55 | — | = ship count@44 尾 + **alloc@48**  |  |
| +56 | int32 向量 | countries 数组数据 — int tag 数组 stride 4, 原生逐行裸 tag 串 (BA5C20→AF590) | 门 计数@+68≠0; 块键 tok 0x2D49; 提取形 `countries.#N` 恒编号 (段手动计数, 规避 seqc("#1") 双编 bug) |
| +57..+67 | — | = 四容器 #1 尾 {cap@+64}  |  |
| +68 | int32 | countries 计数 | |
| +69..+79 | — | = countries count@68 尾 + **alloc@72**  |  |
| +80 | uint32 | last_leader.type — id 对 (0X142220180) | 门 type/id 任一非零 **且 sub_14221F310 解析成功** (leader 消亡则整键不发); tok 0x3501 |
| +84 | uint32 | last_leader.id | 同上 |
| +88..+112 | 填充 | 对齐尾垫 (attacker/defender stride 0x70) | — |

**CNavalCombatShipEntry** (条目; vt 0X14295C490; writer 0X140CE6C50; dtor 0X140CE1B50; 布局下界 ≥0x118)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | uint32 | unique_id.type (type=4713) | 恒写 (0X142220260; tok 0x30AA unique_id) |
| +12 | uint32 | unique_id.id | 恒写 (同上) |
| +16 | SCachedInfo 内嵌 (0xC8=200B) | cached_info | 恒写 (ADEC0; tok 0x31EB) — **与 4.22.5 member.cached_info 同一 writer 0X141976430 同一结构**, 全字段表见 §4.22.5 member.cached_info 行 |
| +17..+215 | — | = **SCachedInfo 内嵌 200B (0xC8)** 本体 (+16..+215) — 全字段表见 §4.22.5 member.cached_info 行 (同一 writer 0X141976430 同结构) |  |
| +216 | SNavalHit* 向量 | naval_hit 数组数据 — 8B 指针元素 → SNavalHit; [N] 第 2 起编 | 门 计数@+228>0; tok 0x30A8 |
| +217..+227 | — | = naval_hit 容器 {d@216, **cap@224**, c@228, alloc@232... } 的 data 尾 + cap@224 — ⚠ 见下行宿主回指 说明 +232 为 CFEXGroup* 而非 alloc  |  |
| +228 | int32 | naval_hit 计数 | |
| +232 | CFEXGroup* | **宿主组回指** (ctor a2) | 不序列化  |
| +240 | SAirHit* 向量 | air_hit 数组数据 → SAirHit | 门 计数@+252>0; tok 0x30A9 |
| +241..+251 | — | = air_hit 容器 {d@240, **cap@248**, c@252, alloc@256} 的 data 尾 + cap@248  |  |
| +252 | int32 | air_hit 计数 | |
| +253..+263 | — | = air_hit count@252 尾 + **alloc@256**  |  |
| +264 | 8B 指针 向量 | [runtime-only] 第三容器数据 (元素类待裁: 已知 8B 键@+8 / i32@+16 / tag@+20) | dtor 实证, **writer 不发** |
| +265..+275 | — | = damage_received 容器尾 {cap@+272}  |  |
| +276 | int32 | 第三容器计数 | |

**SNavalHit** (vt 0x1429DDD38; sizeof 0x50=80; writer 0X1415C7CD0; ctor 0X1415C6010; reader malloc(80); 六字段全恒写)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | target (省 id) | 恒写; tok 0x6B target |
| +16 | 串 (32B) | name | 恒写 (!AAFD0 时); tok 0x1B name |
| +17..+47 | — | = SNavalHit name SSO 32B 本体 (buf@16 尾 + size@+32 + cap@+40=15) |  |
| +48 | uint8 | convoy | 恒写 yes/no 均写 (⚠ 异于 cached_info.convoy 的 yes-only); tok 0x2E93 |
| +56 | fixed×1e-5 | damage | 恒写; tok 0x30AB |
| +64 | fixed×1e-5 | strength | 恒写; tok 0x28A6 |
| +72 | uint8 | last_hit | 恒写 yn; tok 0x30AC |

**SAirHit** (vt 0X1429DC138; sizeof 0x18=24; writer 0X1415C7C60; ctor 0X1415C5D80; reader malloc(24))。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | 匿名结构 (NNB 形状)* | 装备数据库对象 → refid @obj+8 | 门 ptr≠0 (0X142220260); tok 0x3643 equipment_variant_index |
| +16 | uint32 | count | 恒写; tok 0x29EA count |
| +20 | tag_id (i32) | tag (国家 id, BA5C20 串化) | 恒写 — **发射序首字段**, 先于 equipment_variant_index; tok 0x2A02 tag |

**CNavalCombatAirEntry** (条目; vt 0X14295C440; writer 0X140CE6630; ctor 0X140CE1450; sizeof ≈0x80 — ctor 三容器尾推, 分配点未找)。原生发射序 = max → alive → killed → tag → equipment_variant_index → air_base → naval_hit×N → air_hit×N; 段 evi 前置与原生序不同 — 叶键互异, 多重集无序配对无害 (20 档实证)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | 匿名结构 (NNB 形状)* | 装备数据库对象 → refid @obj+8 | 恒写 (0X142220260, **原生无空门**; 段加 kptr 防御); tok 0x3643 |
| +16 | uint32 | max | 恒写; tok 0x2A4 max |
| +20 | uint32 | alive | 恒写; tok 0x30A3 alive |
| +24 | uint32 | killed | 门 >0 才写; tok 0x336C killed |
| +28 | tag_id (i32) | tag (BA5C20 串化) | 恒写; tok 0x2A02 |
| +32 | 串 (SSO 32B) | air_base (ctor 写 cap 15 布局锚) | 恒写 (!AAFD0 时); tok 0x2FB6 |
| +33..+63 | — | = CNavalCombatAirEntry air_base SSO 32B 本体 (buf@32 尾 + size@+48 + cap@+56=15) |  |
| +64 | SNavalHit* 向量 | naval_hit 数组数据 | 门 计数@+76>0; tok 0x30A8 |
| +65..+75 | — | = air_wing 容器尾 {cap@+72}  |  |
| +76 | int32 | naval_hit 计数 | |
| +77..+87 | — | = air_wing 容器尾 {alloc@+80}  |  |
| +88 | SAirHit* 向量 | air_hit 数组数据 | 门 计数@+100>0; tok 0x30A9 |
| +89..+99 | — | = air 容器尾 {cap@+96}  |  |
| +100 | int32 | air_hit 计数 | |
| +101..+111 | — | = air_hit count@100 尾 + **alloc@104**  |  |
| +112 | 8B 指针 向量 | [runtime-only] 第三容器数据 (元素类待裁: 已知名串 +16/+32/+40, i64@+56, u8@+72) | ctor DA30 实证, **writer 不发** |
| +113..+123 | — | = members_to_delete 容器尾 {cap@+120} (loader case 13869 创建 member 推入) |  |
| +124 | int32 | 第三容器计数 | |

写门汇总 (全部复核):

| 门 | 语义 | 适用字段 |
|---|---|---|
| 块门 | `*(i32*)(gs+1484) > 0` — 仅此一门 | 顶层 naval_combat_result 块 |
| 子列表门 | 计数 >0 / ≠0 | >0: air_wing / ship / naval_hit / air_hit; ≠0: countries / shown_to_countries |
| 值门 | 逐字段判据见左 | killed>0; strength / build_cost_ic fix≠0; cached_info convoy / pride yes-only (SNavalHit convoy 则 yn 均写); ship 名 / sunk_by / equipment_variant 串 len≠0; convoy_index ≥0; convoy_id 任一非零; highest_eq_variant refid ≠ 哨兵 qword_14333D528 |
| last_leader 双门 | {type, id} 任一非零 且 sub_14221F310 解析成功 (leader 消亡则整键不发) | last_leader |
| AAFD0 字符串抑制 | 正常文本档恒 false, 导出侧可忽略 | 含 !AAFD0 的串字段 |

同族边界 (非本块, 勿混入):

| 项 | 辨析 |
|---|---|
| CDispatchNavalCombatResultsCommand (vt 0x142993578; 命令 writer slot22 0X14116F7B0, tok 0x34FD) | 运行时清除命令, 非存档结构 |
| sub_140CE6D20 (vptr 0x14295DE20; 写 region 0x2A4B / is_sunk 0x3945 / equipment 0x2F4E / ship 0x28A0 / country 0x289A ×2 / to_discard_date 0x3C96) | RTTI 扫描未名, 疑海战事故报告姊妹类 |
| UI 族六件: CNavalCombatResultsWindow / CNavalCombatResultsMapIcon / Lost·Survivor GridBoxItem | 纯 UI |
| sunk_convoys_history {d@gs+1448, c@gs+1460} | 相邻容器 (元素 writer 0X140EB39E0, tok 0x3821/0x3822) |

不确定点:

| 项 | 状态 |
|---|---|
| ship / air 条目精确 sizeof = **0x120 / 0x88** (读档工厂 case 10400/13161 malloc 实参 + 条目深拷贝 sub_140CE21B0 同值双证) | 定案 |
| 元素 +16 u8 flag = **CReferenceObject 注册/有效标志** (ctor 清 0 / sub_14221E700 置 1 / reader·writer 均不碰 → runtime-only) | 定案 |
| 第三容器与 ShipEntry+264 / AirEntry+112 **同族** (容器元 {data@0, cap@8, count@12, alloc@16}; 两个合并器: sub_1415C75C0 = tag 键控聚合累加 (i32@元素+16), sub_1415C7780 = 名串键控聚合累加 (i64@元素+56 + u8@元素+72 布尔或); 经 thunk sub_141973D60=+360 / sub_141973D70=+336 / sub_141973D80=+384 / sub_14197A570=+304 / sub_14197A580=+280 / sub_14197A590=+256 接入条目深拷贝; **三 thunk 实际调用点定案**: 聚合器 sub_140CE21B0(src, dst) 内对 (dst+240, dst+264, dst+216) 连续三调 = 条目侧三容器, 其宿主 a1+32 为条目容器 / a1+44 为计数) | 待裁 (元素类名无 RTTI 直证; 调用点与聚合方向已定案) |
| gs+1496 location 索引**不发射** (注册器 sub_1401CAE40 全体无 writer 调用) | 定案 |
| countries 串化 BA6730 vs BA5C20 | 定案: BA6730 = 「tag>0 门 + BA5C20 解析 + AF590 发射」薄包装, 解析本体同一, 对导出无影响 |
| highest_eq_variant 哨兵 qword_14333D528 实值 = **0** (空 id 对; 该址在 .data 零填充尾, 全 dump 0 写点) | 高置信 |
| cached_info.tag 原生无 >0 门而段加防御门 (tid=0 边界) | 防御门无害 (高置信); 本档 4 海战 61 member tag 全 >0 无 tid=0 样本  |
| 存活期语义 (海战结束压入 / to_discard_date 过期清除, dispatch 命令族) | 推定 |

#### 4.22.7 战术视图族 (CCombatTactic / CTacticsListView / PreferredTactics entries)

CCombatTactic 布局 8 偏移定案 (CTacticsListEntry Refresh 消费; target = CCombatTactic\*@entry+32, SetTarget 0X141C70760):

| 偏移 (tactic) | 类型 | 语义 |
|---|---|---|
| +112 | MSVC 串 | 图标串 |
| +312..+352 | f64 ×6 | 六值 |
| +360..+369 | 匿名结构 (10B) | 双阶段索引 (+360/+364) + 双门字节 (+368/+369) |

| 项 | 定案 |
|---|---|
| CTacticsListView ×3 target | combat (SetCombat 0X141C70F60; att/def +40/+48 ✓册; **combat+208 = 阶段** 新定案) 或 leader/country 枚举 (注册表 gs+1024 链) |
| CTacticsListView 池化布局 | +2728/+2752/+2832 等 9 成员定案 |
| 撞偏移复核 | 0X1415CE480 = 回收助手 / 0X1415CEFB0 = Clear, 确属本族, 与 CLandCombatView 异类 (⚠ 排雷见 4.22.7) |
| CSelectArmyLeaderPreferredTacticsEntry | 基 entry + CButtonWrapper@+72; entry+64 = CLandCombat\* (推定) |
| 其可用判定 | skill+440 军衔等级 (✓§4.4) ≥ define **PREFERRED_TACTIC_CHARACTER_SKILL_LEVEL_REQUIRED** ∧ 国有战术 ∧ CP |
| CSelectCountryPreferredTacticsEntry | CP 价公式定案 = cc+496 command_power (✓§4.3) ≥ 100000 × (**country_modifiers[#589]** 截整 ✓册查表 + define **PREFERRED_TACTIC_COMMAND_POWER_COST**) |

#### 4.22.8 CShipCombatReader (海战视图特效静态配置; vt 0x1429E82F0)

writer = CFG 空桩 → **不入档** (静态 reader); 源 = gfx/naval_combat_fl.txt (推定); reader 0x141664C90 / ctor-dtor 0x141661700。

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | MSVC 串 32B | naval_formation (12631) | 阵容字串 |
| +40 | fixed | naval_formation_scale (12632) | 阵容缩放 |
| +48 | MSVC 串 32B | naval_combat_formation (12633) | 战形字串 |
| +80 | fixed | naval_combat_formation_scale (12634) | 战形缩放 |
| +84 | u64 | naval_random_start_time (12913) | 随机起始时刻 |
| +88 | vec | naval_hit_effects_small (12635) | {d@88, cap@96, c@100, alloc@104} 图形特效对象 |
| +112 | vec | naval_hit_effects_big (12636) | 同上 |
| +136 | vec | naval_miss_effects_small (12637) | 同上 |
| +160 | vec | naval_miss_effects_big (12638) | 同上 |
| +184 | u64 | naval_death_time (12640) | 死亡时刻 |

> 与 §4.22 海战 combatant +384 SNavalHit (战斗事件收发器) 同名不同域, 勿混。

> **本域 GUI 类布局**: 见 4.30.18 / 4.31.37 / 4.31.49 / §4.31.23。

#### 4.22.9 CCombat 行为槽 (每小时战斗步进契约; 虚表 0x1429BBC58 基 / 0x1429A83D8 陆)

CCombatManager (§4.22.1 gs+608) 每小时逐战斗调虚表槽[15] = 战斗步进主入口
(时序上下文 §4.2.13)。行为槽定案 (COL 链直读):

| 槽 | 语义 | 备注 |
|---|---|---|
| [8] | `return 3` 常量 getter | 基类共享 |
| [9] | **IsActive**: 双侧参战 tag/单位耗尽即结束 | CLandCombat = 基类判定+两侧容器计数 |
| [11] | GetDuration (历史 entry 消费) | 基类 purecall, 陆/海各自覆写 |
| [12] | **progress 读取**: Σ己侧全部师当前 org (0x1412B5360) | 经 sub_140CDF0E0 每小时整量重写 lb+616 |
| [13] | **首小时初始化** (byte+81=1 / 清 byte+82 结束旗) | CLandCombat 先做两侧大体量初始化 sub_1412AC450 |
| [14] | **结束标记** (byte+82=1, 通知两侧) / 领袖 XP (损失比×0.5) | 双用途: 步进域 [14]=标记, 基类槽[15] 四连内 [14]=XP |
| [15] | **每小时战斗步进主入口** | 全链 = 战术重掷核 (12h) → 时长计数 → 参战国 tag 遍历 → 基类四连, 详 §4.2.13 |
| [16] | 结束复核 bool(self, idx, count) | 基类 purecall |
| [19] | **伤害执行步** (sub_1412B3300) | 目标分配 → 闪避 → STR/ORG 骰 → 穿甲偏转 → TakeDamage; 尾推 progress |
| [22] | **修饰符全量重算** (stacking/over-width/补给/夜战/挖掩/岸轰/空优/情报/包围, 39 define) | 每小时步进第 1 步 |
| [32] | weighted_participants (情报权重) | 步进第 4 环 |

**CArmy::TakeDamage = 0x140C8F510**: 实扣 +1056 strength / +1064 organisation
(mod 660/661/662; war support 扣减)。伤害流水: 目标分配
(DAMAGE_SPLIT_ON_FIRST_TARGET + 「打弱」评分 = 硬攻×硬度+软攻×(1−硬度)) →
闪避 (防御/突破值: 有防御 90% / 无 60% 命中) → STR 骰 1+rand(2) / ORG 骰
1+rand(4) (装甲优势 2/6) → ×0.06/×0.053 × PIERCING_THRESHOLDS{1,0.75,0.5,0}。

**战术重掷核 (sub_1412BBF90)**: 每 TACTIC_SWAP_FREQUENCEY(12) 小时, 双方技能
最高领袖 skill 比较 + 侦察优方 +RECON_SKILL_IMPACT(5) 当量; 胜方加权
(INITIATIVE_PICK_COUNTER_ADVANTAGE_FACTOR 0.35×技能差) 掷反制战术; a1+208 =
当前战术相位; 战术六值聚合进 battle+160..+200。

**组织度分工**: 战时扣减唯一入口 = TakeDamage(+1064); 恢复
(RELIABILITY_ORG_REGAIN, sub_140C82C10) 与移动耗减在师域小时更新。
