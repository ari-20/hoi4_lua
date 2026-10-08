

### 4.22 战斗族 (CCombat / details / logmgr / history)

#### 4.22.1 战斗管理挂载与三类分流 (CCombatManager @gs+608)

获取路径与 vtable:

| 偏移 (gs) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +608 | CCombatManager (内嵌) | 战斗主管理 | vtable 0X2950688; 0X2950688 存于槽自身 (非指针; 探针定案) |
| +616 | CCombat* | 战斗明细 (details) 容器数据 — {count@+628}; 元素主 vtable 分流 CLandCombat / CNavalCombat / CLandBorderWarCombat |  |
| +617..+627 | — | = details 容器尾 {cap@+624} |  |
| +628 | uint32 | details 容器计数 | logmgr 实为 +2176/+2188 容器 (元素 NCombatLog::CManager, vtable 0X295D8D8), 非本槽 |
| +629..+639 | — | = details 容器尾 {alloc@+632} |  |
| +640 | uint32 | **玩家国缓存** (country-link index 域) | ctor sub_140BB3E00(·,0) 初始化 (country-link 解析, gamestate.cpp:7520 断言; 经 sub_1401DA7C0 查 gs+832 链表); hourly (sub_140BB8AE0) 与 gs+1312/1316 玩家 union 直比, 变化时写回并逐战斗 sub_1413E3EE0 通知; 不序列化 (link-index 与玩家 union 值域精确等同待裁) |
| +648 | CCombatHistory (内嵌) | 战斗历史 (hist) | vtable 0X2950638 (= mgr+40) |
| +656 | CCombatHistory* | **CCombatHistory 链表头** — Clear sub_140BB7BB0 沿 next@e+56 逐节点 free; 节点带 CGregorianDate vtable@e+8 = end_date 族B (§3.7a) |  |
| +664 | 匿名结构 (NNB 形状)* | 历史链表 **tail** | Clear 同清 (高置信) |
| +672 | uint32 | 历史条目 **count** | Clear 同清 (高置信) |
| +676 | uint8 | 运行时旗 (ctor 0; 未名) | 不序列化 |
| +680 | uint8 | **_bInCombatUpdate 战斗更新中旗** | 断言 "Removing combat during combat update!" combatmanager.cpp:0x495; 不序列化 |
| +688..+2175 | — | **非战斗族** (mgr sizeof≈80, ctor 止于 +72; 本段属 gs 其他子系统 — 定案) |  |
| +2176 | NCombatLog::CManager* | combat log manager 指针数组数据 (按国家) | 元素 NCombatLog::CManager vtable 0X295D8D8 |
| +2177..+2187 | — | = log manager 数组尾 (cap 候选 +2184 未直读) |  |
| +2188 | uint32 | log manager 数组 **界/计数** | gs loader case 14037 `if(id <= *(a1+2188))` 直证; CManager sizeof 0x28=40 {vtable@0, log{d@8,c@20}, tag@32} |

三类分流与字段族:

| 项 | 规则/定案 | 备注 |
|---|---|---|
| 场容器三类分流 | gs+616 场容器混装三类对象, **主 vtable `*e` 分流**: 陆战 0X29A83D8 / 海战 0X29DDB08 / 边界战 0X29BC5F0** | ⚠ 按 day 正负分流会把 CLandBorderWarCombat (day=68 正值) 误入 land_combat, 致 8196 插槽后索引整体漂移 (~770 伪 DIFF) — 必须按主 vtable 分流 |
| 海陆战分流 | combat `day uint32 > 0x7FFFFFFF` 即海战 (NBAT 前缀) | 陆战按 id 升序重编号 |
| 魔数 | 陆战 600/65536 魔数已改通用 |  |
| combat_details 字段族 | 参战双 attacker/defender 各含 units/losses/size/org_damage/str_damage/manpower casualties 等 | writer 0x1413E4150 陆战块 + combatant 族 (0X1414B59B0 系生产线族 writer 勿混, §4.8); pfx 参数区分 CBAT/NBAT 前缀 |

序列化 (§4.00.1 标准槽契约): [1] Save wrapper 0x1424BEC50 / [2] writer 0x140BBAFF0 /
[3] Load wrapper 0x1424BE690 / [4] reader 0x140BBA070 (mgr 无坐标桥, a1 = 本体)。
reader 键表 (三元素类均双 vtable 主@+0 / CPersistent@+16, 序列化统一从 +16 基进;
堆分配后经 sub_140BB6CA0 线性查重注册):

| 键 (token) | 元素类 | 尺寸 | ctor |
|---|---|---|---|
| land_combat (10521) | CLandCombat | 216 | sub_1412AA360 |
| naval_combat (10522) | CNavalCombat | 296 | sub_1415C2330 |
| border_war_combat (14757) | CLandBorderWarCombat | 248 | sub_1413EB800 (reader 分支尾另调 sub_1413EFB00 = 读档后修复步) |

history 键 10293 直读 +648 (经槽[+24] Load wrapper); history writer 门 =
count@+672 非零 (侵入链表逐元素多态写, writer 0x140BBAEA0)。writer 逐条目键 =
元素虚槽[+80] 返回的静态 token id (GetSaveToken), 值 = 元素+16 CPersistent 基。

#### 4.22.2 边界战族 (CLandBorderWarCombat / CLandBorderWarCombatant)

独立 `border_war_combat` 块, 首块裸名。块 writer 0X1413F0070 (vtC 0X29BC6D0 slot2) = 陆战基座 0x1412bd810 追加:

| 偏移 (c) | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +200 | int64 (fixed×1e-5) | combat_width |  |
| +208 | uint32 | combat_state |  |
| +212 | uint32 | minimum_duration_in_days | 工厂写点 e+228 = 本表 +212 同物 (坐标系消解, 见 +224 行注) |
| +216 | int32 | start (bi1 实测 −2) |  |
| +224 | uint8 | change_state_after_war (yn) | **定案 (坐标系消解)**: 运行时三函 (工厂 sub_140BB6B70 / 结算 sub_1413EE780 / 状态机 sub_1413ED810) 同基 e 满足 **e = c + 16** — 工厂三写 e+216/+228/+240 = 本表 +200/+212/+224 逐一吻合, 「工厂证 +240/+228 冲突」系 e 坐标误读; 工厂 e+216 写脚本 fixed 值 = **combat_width (+200)**, start (+216 = e+232) 由状态机双侧就位时写 (早前「+216 两方一致」系同数值撞车, 已废); 实参溯源 = CStartBorderWarEffect 载荷 +2936 求值 (战宽) / +3408 (本旗) / +3412 (minimum_duration) |

side 元素 CLandBorderWarCombatant writer 0X1413F0100 = 0X1412BD820 追加:

| 偏移 (cb) | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +1216 | uint32 | tag tid | tid=0 → "---" |
| +1224 | 匿名结构 (NNB 形状)* | state = \*(\*(cb+1224)+88) |  |
| +1232 | CProvince* 向量 | province 容器 {d@cb+1232, c@cb+1244} → 元素 +164 裸名 (省 id) |  |
| +1256 | id 对 | orders_group {type@cb+1256, id@cb+1260} | 折叠单叶 |
| +1264 | uint32 | max_units |  |
| +1272 | int64 (fixed×1e-5) | modifier (AE590 族) |  |
| +1280 | MSVC 串 | on_win | 门 size@+16≠0 |
| +1312 | MSVC 串 | on_lose | 门 size@+16≠0 |
| +1344 | MSVC 串 | on_cancel | 门 size@+16≠0 |
| +1376 | int64 (fixed×1e-5) | dig_in_factor (AE590 族) |  |
| +1384 | int64 (fixed×1e-5) | terrain_factor (AE590 族) |  |
| +1392 | 匿名结构 (12B 形状) 向量 | removed_unit 容器 {d@cb+1392, c@cb+1404} — 12B 条 {id 对@0, hours u32@8} |  |

注: token 0x39A3 = removed_unit 块键本身 / 0x28A3 = unused / 0x3170 = hours 字段键, 均与 on_* 无关 (探针 token_name 定案); 真键 = **on_win 14747 / on_lose 14748 / on_cancel 14749** (连号, 与 writer 字段序同序)。
证据: `sub_1413F0070` (border_war 块 writer) / `sub_1413F0100` (侧元素 writer) 对基座 `sub_1412BD810` / `sub_1412BD820` 的追加调用。

CWar (战争对象; 挂载 = 关系对象+744, §4.10.4) 布局补行 — +32/+73 实为 **CRelation 基字段** (CWarRelation 464B 即战争对象本体, 无独立 CWar 类):

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +32 | hours | 开战日期 (CRelation 基) | 高置信 |
| +73 | uint8 | 状态旗 (非 0 = 排除于统计/存活判定; CRelation 基) | 高置信 |

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
| +8 | uint32 | holder.type — id 对之 type (id 对 {type, id}) | type 62 = holder 类; 内联非指针解引用 |
| +12 | uint32 | holder.id — id 对之 id |  |
| +13..+23 | — | = **vtable2 持久化 vtable 槽 (obj+16)** — 陆 0x1429a84b8 / 海 0X1429DDBE0; obj 包装布局: obj+0 vtable1 / obj+8 refid / obj+24 holder 对 |  |
| +24 | CCombatant* 向量 | attacker = *(c+24) | 容器包装: cont=rp(c+24/32); **cont[0] = vtable (属映像区间) ⇒ cb = cont 本体**; 见下注 |
| +32 | CCombatant* 向量 | defender = *(c+32) | 容器包装同上 |
| +40 | CProvince* | location = *(*(c+40)+164) |  |
| +48 | uint32 | day | >0x7FFFFFFF → naval_combat 键 |
| +52 | uint32 | duration |  |
| +56 | CProvince* (运行时) / 匿名结构 (NNB 形状, 序列化形态) | **战斗所在省** — 运行时经 sub_140CE7410 = *(c+56) 直取, 6 处省字段读互证 (省 +164 id / +184 地形 def / +192 州 / +200 天气区 / +272 单位数组 / +392 tag; §4.22.17) | 序列化侧以 terrain 串对象形态落盘 (门 byte@tobj+16, 串@tobj+24, 引号) — 同槽两期 (运行时省指针 / 写盘 terrain 串), 待裁 |

> **侧容器解引用 (定案)**: 侧容器 cont 的 **+0 是 vtable** (落在映像区间
> [BASE, BASE+0x37ec000)), 不是数据指针 — 33 场陆战 66 个侧容器 66/66 实测。
> 因此 cb = cont 本体。若误把 cont[0] 当数据指针去走 "el=rp(d) → cb=rp(el+16)"
> 解包, 会把代码字节读成堆指针: 攻击侧因 count 读到垃圾巨值被门挡住而侥幸
> 走兜底, 防守侧 count 恰 =1 而误入解包 → **整侧字段静默丢失** (实测
> land_combat[27]/[31] defender 39 行全丢)。

#### 4.22.4 CCombatant 基座与战斗持久化族 (CCombatHistory / NCombatLog / SCombatSideData / SEquipmentPool)

**CCombatant** (cb = 战斗方基座, 232B; writer 0X1413E41F0 + 0X1412BD820; ctor sub_1413E05F0; loader 0X1413E33A0): 基座定案 — **+24 = 宿主战斗回指** (RemoveUnit 经它取 attacker/defender/location/duration); **+216 = is_attacker 旗** (海军 pair-init 第一只=1 第二只=0)。

**CLandCombatant** (陆军参战方, vtable 0x1429A82C0; writer vtable[2] = 0x1412BD820 = 上行基域 writer 同址 → 字段覆盖即基座 232B 全量, 无自有增量; reader 0x1412BA300) — 类名绑定补注: §4.18.5 vtable[22] 战斗修正消费 (kind=4 条目) 的 this 即本类; PERS 指纹实证进存档, 账面 = 基座表全量 (原「散提维持」结案)。

编制对象 (编成组/编制组合对象; unit 经虚槽[8] 取得) 布局补行:

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +1136 | fixed×1e-5 | bonus (tok 10931; min_planning/has_max_planning 直读此字段 — 引擎触发器命名与字段名不一致) | 定案 (运行时 lexer token_name(10931)="bonus"; 活体 GER 3 师 0.4055/0.2473/0) |

> 编制对象+1136 与 §4.18 CArmy+1136 同基 (AsArmy = return this, §4.18.13): 同一字段
> bonus, 曾两记为「异基勿混」系误注, 已并案。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +16 | fixed×1e-5 | **岸轰总值** (每小时 [22] 重算写入 = Σ舰攻击/参战数×cap) | >0 |
| +24 | CCombat* | **宿主战斗回指** (ctor a2) | 不序列化 |
| +32 | CUnit* | unit 容器数据指针 — {d, c} 8B 指针, id 对内联@elem+24 {type, id} | 恒写 |
| +33..+43 | — | = unit 容器尾 {cap@+40}  |  |
| +44 | uint32 | unit 容器计数 | 恒写 |
| +45..+55 | — | = unit 容器尾 {alloc@+48}  |  |
| +56 | 侵入链表 | **参战 tag 链表 A = 参战单位 logical_country (unit+480) 集** — 32B 节点 {tag u32@0, prev@8, next@16, u8@24}; {head@56, tail@64, count@72} (消费点见下表) | 不序列化 |
| +80 | 侵入链表 | **参战 tag 链表 B = 与 logical 不同的 owner (unit+472) 集** (远征军原属主参战认定) {head@80, tail@88, count@96} | 不序列化 |
| +104 | uint32 向量 24B | **参战 tag 平铺数组** {data@104, cap@112, count@116, alloc@120} — u32 tag (与链 A 同键 = logical_country 集, dedup sub_1401B0250) | 不序列化 |
| +128 | 匿名结构 (32B 形状) 向量 | **weighted_participants 容器本体 (32B)** — tok 10755 块; RH 表: 空哨兵/数据@+136, 计数@+144 = 块门, 掩码 u32@+148, extra u8@+152 (桶数 = 掩码+1+extra); 桶 24B {hash u32@+0, 距离 byte@+4 (≠0 占用), tag id u32@+8, weight **i64 fixed×1e-5**@+16}; writer 0X1413E41F0 尾段 → sub_1411DCF90 (按 tag 升序发 `"TAG" 值`); loader case 10755 → 对象基 +128 | 计数≠0 写块 |
| +152 | uint8 | 运行时旗 (ctor 0; 未名) | 不序列化 |
| +156 | float | 标量 (ctor 1063675494 = 0.9; 未名) | 不序列化 |
| +160 | fixed×1e-5 | size 容器数据指针 — fixed 数组 | c>0 |
| +161..+171 | — | = size 容器尾 {cap@+168} (ctor 按国家数扩容) |  |
| +172 | uint32 | size 容器计数 | c>0 |
| +173..+183 | — | = size 容器尾 {alloc@+176}  |  |
| +184 | fixed×1e-5 | losses | 恒写 |
| +192 | 匿名结构 (NNB 形状) 向量 24B | **第二 per-country fixed 数组 = size 孪生** {data@192, cap@200, count@204, alloc@208} — ctor sub_1413E05F0 与 +160 连调 sub_140611B00 按国家数扩容, 但全 dump 无读方 → 无消费者无 writer, 恒零沿袭 | 不序列化 |
| +216 | uint8 | **is_attacker 旗** (ctor a3; RemoveUnit 以它选侧); **+218 = player_participates** | 不序列化 |
| +219 | uint8 | has_flanked_opponent | ≠0 写 yes |
| +224 | tag_id | last_hit → 引号串 | tid>0 |
| +232 | idpair 向量 | front id 对列表 {d, c} 8B 指针 | 同 unit; **运行时元素消费 = CUnit\*** (vtable[21]/[46]/+312/+496 全按完整单位; writer 发射 refid 不变) |
| +233..+243 | — | = front 容器尾 {cap@+240}  |  |
| +244 | uint32 | front 容器计数 | 同 unit |
| +245..+255 | — | = front 容器尾 {alloc@+248}  |  |
| +256 | 匿名结构 (NNB 形状)* | reserves id 对列表 | 同 unit (元素运行时 = CUnit\*) |
| +257..+267 | — | = reserves 容器尾 {cap@+264}  |  |
| +268 | uint32 | reserves 容器计数 | 同 unit |
| +269..+279 | — | = reserves 容器尾 {alloc@+272}  |  |
| +280 | 匿名结构 (NNB 形状)* | retreat id 对列表 | 同 unit (元素运行时 = CUnit\*) |
| +281..+291 | — | = retreat 容器尾 {cap@+288}  |  |
| +292 | uint32 | retreat 容器计数 | 同 unit |
| +293..+303 | — | = retreat 容器尾 {alloc@+296}  |  |
| +304 | CCombatTactic* | tactic ref → ru32(tac+152) | 指针非空 (writer 另有 vmethod80 门未接) |
| +305..+319 | — | = tactic ref 尾 + air_plane 前置  |  |
| +320 | 匿名结构 (飞机条目) | air_plane 容器数据指针 — {d, c} 8B 指针 → **CAirInLandCombat** (vtable 0x1429A8270; writer 0X1412BD780 / reader 0x1412BA1D0): amount u32@A+20 / air_wing 对{A+8,+12} (13161) / air_count u32@A+16 (13162) / damage_factor fixed@A+24 (13163) 恒写; date hours@A+40 ≠ dword_143086B20 才写 (族A 证1, ptr=A+48) |  |
| +321..+331 | — | = air_plane 容器尾 {cap@+328}  |  |
| +332 | uint32 | air_plane 容器计数 |  |
| +333..+343 | — | = air_plane 容器尾 {alloc@+336}  |  |
| +344 | fixed×1e-5 | anti_air_attack | >0 |
| +352 | uint32 | air_kills | >0 (<0x80000000 防御) |
| +360..+400 | fixed×1e-5 ×6 | air/ground/prevented dmg (str/org 对) | >0 |
| +353..+407 | — | = air_kills/air dmg 六值区内  |  |
| +408 | 匿名结构 (NNB 形状)* | org fixed 数组 (writer 0X1406128E0) | c>0 |
| +409..+419 | — | = org_loss_summary 容器尾 {cap@+416} (**键名正名 org_loss_summary** tok 13839) |  |
| +420 | uint32 | org 容器计数 | c>0 |
| +421..+431 | — | = org_loss_summary 容器尾 {alloc@+424}  |  |
| +432 | 匿名结构 (NNB 形状)* | str_loss_summary fixed 数组 | c>0 |
| +433..+443 | — | = str_loss_summary 容器尾 {cap@+440}  |  |
| +444 | uint32 | str_loss_summary 容器计数 | c>0 |
| +445..+455 | — | = str_loss_summary 容器尾 {alloc@+448}  |  |
| +456 | uint32 | org_loss_summary_index | 恒写 |
| +460 | uint32 | num_org_losses | 恒写 |
| +464 | NCombatLog::CStatsObserver 内嵌 | log (lb = cb+464; CStatsObserver 身份合一 — dtor 调 observer dtor sub_140CD8930@+464, 其 vtable 0X295D748 slot2 恰 = 0X140CE0990) | 恒写块, 下表 |

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
| +20 | uint32 | group[N] 容器计数 |  |
| +21..+31 | — | = group 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (12B) | leader_hours[N] 容器数据指针 — {d, c} 12B 条 {对@0, time u32@8} | writer 0X140CE0B80 |
| +33..+43 | — | = leader_hours 容器尾 {cap@+40}  |  |
| +44 | uint32 | leader_hours[N] 容器计数 |  |
| +45..+55 | — | = leader_hours 容器尾 {alloc@+48}  |  |
| +56 | 匿名结构 (32B) | damage[N] 容器数据指针 — {d, c} 32B 条 {from tid@8, receiver@12, to@16, value fixed@24} (**SDamageDone**, loader 内符号) | 恒写 (0X140CE11D0) |
| +57..+67 | — | = damage 容器尾 {cap@+64}  |  |
| +68 | uint32 | damage[N] 容器计数 |  |
| +69..+79 | — | = damage 容器尾 {alloc@+72}  |  |
| +80 | fixed×1e-5 | total_damage | >0 |
| +88 | 内嵌 | combat_side_data (同下侧 writer) | |
| +89..+615 | — | = combat_side_data SCombatSideData 内嵌 528B 本体 (+88..+615, 下表) |  |
| +616 | fixed×1e-5 | progress (**结算时高者判胜** — consolidation sub_140CDB850 `if(*(v4+616)>*(v5+616)) 置 win 位`) | >0 |
| +624 | uint32×30 | modifier_hours | 恒写 |
| +625..+743 | — | = modifier_hours u32[30] 定长数组本体 (+624..+743; loader case 14172 范围解析 {+624,+744}) |  |
| +744 | uint8 | bit0→snow bit1→win; **bit2 = 已结算/consolidated 旗** (ctor 清三位 `&=0xF8`; consolidation `|=4u`; writer 不发) | 仅真写 yes |

lb+8 group[N] 条目 (ge = 元素基; CActivityInGroup, vtable 0X295D6F8, sizeof 0x88=136):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | group 对.type — 对 {type@ge+8, id@ge+12} |
| +12 | uint32 | group 对.id |
| +16..+63 | 匿名结构 | division_template 内联 8B 对 + enemy_dmg 16B {type, id, fixed} (子偏移未单列) |
| +64 | 池 | damaged_equipment 池 |
| +128 | tid | damage_dealer |
| +132 | tid | damage_taker |

**侧数据 = SCombatSideData** (528B; vtable 0x2946xxx, ctor sub_140CD85E0 符号; writer 0X140CE0D20, combat_side_data/combat_data 双侧共用; S = 侧基)。全字段表:

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
| +484 | uint32 | 16B 容器计数 | B 候选 (零叶未实证) |
| +485..+495 | — | = modifier_hours 容器尾 {alloc@+488}  |  |
| +496 | tag_id | tags 容器数据指针 — {d, c} u32 tid 数组 | c>0 |
| +497..+507 | — | = tags 容器 data 尾; cap 推定 +504 |  |
| +508 | uint32 | tags 容器计数 | c>0 |
| +509..+519 | — | = tags 容器尾 + leader 对前置 (ctor 哨兵 qword_14333D528); alloc 推定 +512 |  |
| +520 | uint32 | leader.type — id 对之 type (对 {type, id}) | 任一非零写 |
| +524 | uint32 | leader.id — id 对之 id | 任一非零写 |

reason 枚举 (equipment_lost 四桶分桶键):

| 值 | 名称 | 判据/语义 |
|---|---|---|
| 0 | combat | — |
| 1 | attrition | — |
| 2 | attrition_in_combat | combats@unit+424 非空 |
| 3 | training | og+413 training 旗 + TRAINING_MIN_STRENGTH 门 |

注: 存档 reason 值实测 {0,1,3}; 证伪参照 = CAIMilitaryMinister AI 备战评估。

**池空判** 0X141010BA0: 容器A {d@P+8, c@P+20} 24B 条 elem+16 全零 → 整块不写。

**SEquipmentPool** (writer 0X141012DB0; 战斗侧/空军翼/合同族共用; P = 包装基址)。⚠ **同体异名统一 (定案)** (全书集中登记, 他处行内以「同体异名」短标指代): ① 正名 **SEquipmentPool** (对象域别名 CEquipmentVariantPool — 同 writer 0X141012DB0 同布局, 见 §4.23.2/§4.24); ② 正名 **SCombatData** (命名空间限定形 NCombatLog::CManager — vtable 0X295D8D8, 见下 combat_log)。

| 偏移 (P) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (24B) | 空判容器A 容器数据指针 — {d, c} 24B 条 | 空判用 |
| +9..+19 | — | = 空判容器A 尾 {cap@+16} |  |
| +20 | uint32 | 空判容器A 容器计数 | 空判用 |
| +21..+31 | — | = 空判容器A 尾 {alloc@+24} |  |
| +32 | CEquipmentVariant* | 条目 容器数据指针 — {d, c} 16B {variant, amount fixed×1e-5}; id 对 = {type@var+8, id@var+12} | 条目写门 amount≠0 ∨ az |
| +33..+43 | — | = 条目容器尾 {cap@+40} |  |
| +44 | uint32 | 条目 容器计数 |  |
| +45..+55 | — | = 条目容器尾 {alloc@+48} |  |
| +56 | uint8 | **az = allow_zero_entries** | 恒写 |

**战斗历史 (CCombatHistory)**: 链表头@gs+648+8, next@e+56, 存档序 = 链表序; 无 start_date。逐条 (e = 条目):

| 偏移 (e) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +16 | hours | **end_date 族B** (§3.7a) | 恒写 |
| +17..+31 | — | = end_date CGregorianDate vtable 槽区 (节点 vtable@e+8) |  |
| +32 | uint32 | type | 恒写 |
| +36 | tag_id | attacker tid (tid=0 → "---") | 恒写 |
| +40 | tag_id | defender tid (tid=0 → "---") | 恒写 |
| +44 | uint32 | location | 恒写 |
| +45..+55 | — | = location 尾 + next 前置  |  |
| +56 | 匿名结构 (NNB 形状)* | next (链表) | — |

**combat_log**: gs+2176 = manager 指针数组 (按国家 id 索引), 计数@gs+2188; manager (SCombatData 同体异名 ⚠②, vtable 0X295D8D8) **块写门 = 日志数 count@mgr+20 ≠ 0** (0X140CDD360, 空日志国家整块不写)。manager writer 0X140CE0580:

| 偏移 (mgr) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (log 条目) | log[N] 容器数据指针 — {d, c} 8B 指针逐条 (元素 vtable 0X295D888 校验) | count≠0 = 块门 |
| +9..+19 | — | = log 容器尾 {cap@+16} |  |
| +20 | uint32 | log[N] 容器计数 | count≠0 = 块门 |
| +21..+31 | — | = log 容器尾 {alloc@+24} |  |
| +32 | uint32 | tag tid | 恒写引号 |

条目 COrdersGroupLogs (0xE8, writer 0X140CE0710):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | 匿名结构 (子条目) | enemy_equipment 容器数据指针 — {d, c} 8B 指针子条目 | c>0 |
| +9..+19 | — | = enemy_equipment 容器尾 {cap@+16}  |  |
| +20 | uint32 | enemy_equipment 容器计数 | c>0 |
| +21..+31 | — | = enemy_equipment 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (子条目) | equipment_recovered 容器数据指针 — {d, c} 同构 | c>0 |
| +33..+43 | — | = equipment_recovered 容器尾 {cap@+40}  |  |
| +44 | uint32 | equipment_recovered 容器计数 | c>0 |
| +45..+55 | — | = equipment_recovered 容器尾 {alloc@+48}  |  |
| +56 | CLoss* 向量 | **equipment 四容器合并序 #1** {d, c} 8B 指针, writer 按容器序连续写 — +56..+151 = CVector\<CLoss*\>[4] 内联数组 (eh vector dtor 直证); 元素 CLoss 族 vtable 0X295D518 / CEquipmentLoss 0X295D568 / CManpowerLoss 0X295D5B8; CLoss::Serialize 0X140CE0540 = reason@+8 tok 13902 + date 代理@+32; reader 0X140CDE000 双键 (10314 date→+32 子块 / 13902 reason→u32@+8)。CEquipmentLoss (vtable 0X295D568) = CLoss + equipment 块@+40 (≥48B): writer 0X140CE04F0 = equipment(12110)@+40 + reason + date / reader 0X140CDDF90 同三键; CManpowerLoss (vtable 0X295D5B8) 预期同构加 manpower 数 (未展开) |  |
| +57..+67 | — | = 四容器 #1 尾 {cap@+64}  |  |
| +68 | uint32 | 四容器 #1 计数 | |
| +69..+79 | — | = 四容器 #1 尾 {alloc@+72}  |  |
| +80 | 匿名结构 (NNB 形状)* | 四容器 #2 | |
| +81..+91 | — | = 四容器 #2 尾 {cap@+88}  |  |
| +92 | uint32 | 四容器 #2 计数 | |
| +93..+103 | — | = 四容器 #2 尾 {alloc@+96}  |  |
| +104 | 匿名结构 (NNB 形状)* | 四容器 #3 | |
| +105..+115 | — | = 四容器 #3 尾 {cap@+112}  |  |
| +116 | uint32 | 四容器 #3 计数 | |
| +117..+127 | — | = 四容器 #3 尾 {alloc@+120}  |  |
| +128 | 匿名结构 (NNB 形状)* | 四容器 #4 | |
| +129..+139 | — | = 四容器 #4 尾 {cap@+136}  |  |
| +140 | uint32 | 四容器 #4 计数 | |
| +141..+151 | — | = 四容器 #4 尾 {alloc@+144}  |  |
| +152 | 匿名结构 (manpower 子条目) | manpower 容器数据指针 — {d, c} → 子条目: reason u32@+8 恒写, date hours@+24 (族A, ptr=+32) 恒写, mp_losses 3×u32@+40 恒写 |  |
| +153..+163 | — | = manpower 容器尾 {cap@+160}  |  |
| +164 | uint32 | manpower 容器计数 |  |
| +165..+175 | — | = manpower 容器尾 {alloc@+168}  |  |
| +176 | CPerTemplateStats* | division_template 容器数据指针 — {d, c} → CPerTemplateStats (0x38): division 对 {type@+8, id@+12} 恒写, date hours@+40 (族A 证3, ptr=+48) 恒写, SCombatStats 子对象@+16 vtable 槽2 虚写 win u32@条目+24 / total u32@条目+28 |  |
| +177..+187 | — | = division_template 容器尾 {cap@+184}  |  |
| +188 | uint32 | division_template 容器计数 |  |
| +189..+199 | — | = division_template 容器尾 {alloc@+192}  |  |
| +200 | 匿名结构 (8B) | combat_data_index 容器数据指针 — 内联 8B {id i32@0 (符号化), attacker u8@4 → yes/no} | 恒写 |
| +201..+211 | — | = combat_data_index 容器尾 {cap@+208}  |  |
| +212 | uint32 | combat_data_index 容器计数 | 恒写 |
| +213..+223 | — | = combat_data_index 容器尾 {alloc@+216}  |  |
| +224 | uint32 | group.type — id 对之 type (对内联 {type, id}) | 恒写 |
| +228 | uint32 | group.id — id 对之 id | 恒写 |

装备子条目 (writer 0X140CE04F0) = 三件套:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | reason |
| +9..+23 | — | = CLoss reason 尾 + date 24B vtable1@+16  |
| +24 | hours | date (族A, ptr=+32) |
| +25..+39 | — | = date 24B 尾 {hours@+24, vtable2@+32=代理}  |
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
| +537..+1071 | — | = defender 侧 SCombatSideData 528B 本体 (+536..+1063) + date vtable1@+1064  |  |
| +1072 | hours | **date (族A 证2, ptr=cd+1080)** | 恒写 |
| +1073..+1087 | — | = date 24B 尾 {hours@+1072, vtable2@+1080=代理} + province 前置  |  |
| +1088 | uint32 | province | ≠0 |
| +1092 | uint8 | defensive_victory | 仅真写 yes |
| +1093 | uint8 | snow | 仅真写 yes |
| +1094 | uint8 | overrun | 仅真写 yes |
| +1095 | uint8 | player_is_attacker (token 0x4DBC) | 恒写 yes/no |

#### 4.22.5 CNavalCombat 海战战斗族

族对象层级与 writer 链:

| 层 | 匿名结构 (NNB 形状) | vtable | sizeof | writer |
|---|---|---|---|---|
| 1 | CNavalCombat | 0x1429DDB08 / 0x1429DDBE0 (双表) | — | 0x1415C5BC0 (首调基座 sub_1413E4150 再写 +176..+264) |
| 2 | CNavalCombatant (参战方) | 0x1429E3E98 (基 CCombatant 0x1429BBB40) | — | 0X141622520 |
| 3 | CFEXGroup (组) | 0x142a59ac8 (RTTI 直证) | 200=0xC8 | 0x141c6d0d0 |
| 4 | CFEXMember (组内 member 条目) | 0X142A1F1C8 (RTTI 直证) | 456=0x1C8 | 0X1419760B0 |
| 5 | CFEXAir (组内 air 条目) | 0x142A212E8 (RTTI 直证) | 328=0x148 | 0X14197D990 |
| 6 | convoy 条目 (挂 CNavalCombat 下; 无独立 RTTI 类名) | — | 0x48=72 (ctor sub_141AD7DF0) | 0X141AD8690 |

进海战分支判据 = day u32@c+48 > 0x7FFFFFFF (0xFFFFFFFF = −1 表示海战)。

**CNavalCombat** (c = 对象基; a1 = c)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | holder id 对.type (B400 内联; 非槽头 e+8/+12 — 那是包装 type=3) — **GUI: NavalCombatView target** (refid → view+64; Reload 0X1417EA930 再归一化) | 恒写 |
| +12 | uint32 | holder id 对.id | 恒写 |
| +13..+23 | — | = **vtable2 持久化 vtable 槽 (obj+16)** — 陆 0x1429a84b8 / 海 0X1429DDBE0; obj 包装布局: obj+0 vtable1 / obj+8 refid / obj+24 holder 对 |  |
| +24 | 匿名结构 (NNB 形状)* | attacker 参战方 (直指, 无陆战容器包装) | |
| +32 | 匿名结构 (NNB 形状)* | defender 参战方 | |
| +40 | 匿名结构 (NNB 形状)* | location → 省 idx = u32@对象+164 (陆海基座共有) | 恒写 |
| +48 | uint32 | day (基座共有; 海战按有符号解释, 0xFFFFFFFF = −1) | 恒写 |
| +52 | uint32 | duration (基座共有) | 恒写 |
| +56 | 匿名结构 (NNB 形状)* | terrain 串对象 (门 byte@串对象+16, 串@串对象+24) | |
| +64 | uint8 ×3 | 运行时旗 (+64/+65/+66; ctor 0, writer 不发) — 本表全书统一 res (类布局) 坐标 (attacker@+24 等多函数三向互证) | 不序列化 |
| +72 | 64B | 运行时区 (+72..+135 = obj+88..+151): **定案 = 4×16B 内联槽 {fixed@+0, CEquipmentVariant*@+8}** (活体: 前 3 槽 fixed=0 + 各持一条 CEquipmentVariant* — vtable RVA 0x2951608, +8 = token 70, 实例跨战斗共享 = def 侧; 尾槽 fixed=100.0 (fixed×1e-5) + 空指针, 尾槽指针位与 +128 行同位; 三级 ctor 与 writer/loader 均不触及 → runtime-only; fixed 业务语义未决) | 不序列化 |
| +128 | 观察者指针 | **战斗结束回调观察者** (基类结束通知 sub_1413E2CF0: 非空调其虚槽[2]; dtor 不释放 = 外部登记/注销) | 不序列化 |
| +136 | CNavalCombatant* | **attacker 镜像指针** (第二份; pair-init sub_1415C28F0 同写) | 不序列化; 定案: 生命期所有权副本 — dtor sub_1415C43E0 经镜像释放两参战方  |
| +144 | CNavalCombatant* | **defender 镜像指针** (第二份) | 同上  |
| +152 | uint32 | **海战天气现象枚举** {0 无 / 2 rain_heavy / 3 snow / 4 blizzard / 5 sandstorm} (每小时 sub_1415C5820 按区条现象旗刷新) | 不序列化 |
| +160 | 匿名结构 (NNB 形状)* | **区天气修正块指针缓存** (= 区条+72, 每小时同函数刷新) — 海战侧天气通道之一 | 不序列化 |
| +168 | fixed | **昼夜覆盖快照** (DayNight 值, sub_140F19660, 每小时刷新) | 不序列化 |
| +176 | convoy 条目* | convoy[N] 容器数据 — 条目 writer 0X141AD8690 | count>0 且 client/ntt 非空 |
| +177..+187 | — | = convoy 容器尾 {cap@+184} (convoy 条目 sizeof 0x48=72 = vtable@0 + 表 8 字段恰满) |  |
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
| +260 | uint8 | hide — 消费点 = 报告生成门 (sub_1415C4C90 首门 `!hide`, 隐蔽战斗不生成海战结果报告); 置位点未钉 | 仅真写 yes |
| +261 | uint8 | convoy_combat | 仅真写 yes |
| +264 | fixed×1e-5 | progress — **GUI: 战斗进度条** (combat vtable[25] → view+2704; COMBAT_PROGRESS_DESC); 初值写者 = 槽13 首小时初始化 sub_1415C4740 (两侧 CFEX 组+744 合成 sub_14198A080); ⚠ **CFEXGroup::CreateMember (sub_141C6A730) 以本槽作 CFEXMember+288 unique_id 自增源** (`member+288 = ++*(combat+264)`), 与 progress 语义冲突, 待裁 (§4.22.5a) | 恒写 |

**CNavalCombatant** (cb = 对象基; writer 0X141622520)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +32 | CUnit* 向量 | unit 容器数据 (8B 指针元) — id 对内联@elem+24, 裸名重复 | |
| +33..+43 | — | = unit 容器尾 {cap@+40, alloc@+48}  |  |
| +44 | uint32 | unit 容器计数 | |
| +45..+231 | — | = **CCombatant 基座字段区** (基座 ctor sub_1413E05F0 被首调: weighted_participants@128/size@160/losses@184/is_attacker@216/has_flanked@219/last_hit@224 等全在其中; 海军只是不发这些键 — 归属定案)。**+224 写点 (§4.22.15)**: 侧单位表清空时 = 撤出单位 logical_country (unit+480) — 「last_hit」业务名与写点不符, 待裁 | |
| +232 | uint32 | group[N] 容器数据 — **GUI: 海战双侧网格** (攻/守组×舰图标 → CCombatBoxGrids+24 8 槽 + CFEXShipIcon; sub_1417ED140) | |
| +233..+243 | — | = group[N] 容器尾 {cap@+240}  |  |
| +244 | uint32 | group[N] 容器计数 | |
| +245..+255 | — | = group 容器尾 {alloc@+248}  |  |
| +256 | 匿名结构 (NNB 形状) 向量 24B | **CFEXAir* 数组** {data@256, cap@264, count@268, alloc@272} (: ctor sub_141976630/sizeof 328 直证) | 不序列化 |
| +280 | 匿名结构 (NNB 形状) 向量 24B | **参战将领 (admiral) 指针数组** {data@280, cap@288, count@292, alloc@296} (: leader+3680/+440 军衔等级反推直证) | 不序列化 |
| +304 | 海=领袖指针 / 陆=CCombatTactic* | **海战侧 = 当前主将 (最高技能 admiral) 指针** — vtable[29] 择优 sub_14161E5C0 (admiral 数组取军衔最大), sub_141620940 每小时 `if(!cb+304) cb+304 = vtable[29](self); cb+312 = 同值` (cb+312 = last_leader 镜像; **另两写点 = AddUnit 尾 (+304 恒写 / +312 仅择优结果非空时写) 与 RemoveUnit 尾无条件重选** (§4.22.5a)); 海战 writer sub_141622520 不发射本槽; 陆战侧同槽 = CCombatTactic* (sub_1412BD820 发 tok 11927 `tactic`, 入栈点 sub_1412BB330 见 §4.22.7) | 不序列化 |
| +312 | 匿名结构 (NNB 形状)* | last_leader → id 对@ptr+8 | |
| +320 | uint8 | disengage | |
| +328 | fixed ×2 | **screening_efficiency / carrier_screening_efficiency** (+328/+336) | 不序列化 |
| +344 | fixed×1e-5 | positioning | 恒写 |
| +352 | fixed×1e-5 | new_ships_positioning_penalty (每小时递减写者 sub_141620940: >0 时 −= qword_143331DE0) | ≠0 才写 |
| +360 | fixed×1e-5 | positioning_dominance_bonus | 恒写 |
| +368 | fixed×1e-5 | anti_air | 恒写 |
| +376 | fixed×1e-5 | total_initial_strength | 恒写 |
| +384 | fixed×1e-5 | total_damage_dealt | 恒写 |
| +392 | fixed×1e-5[36] | damage_dealt_by_gun_types.#1 — 36 值恒写单行 | 恒写 |
| +393..+679 | — | = damage_dealt_by_gun_types fixed[36] 数组本体 (+392..+679) |  |
| +680 | float | **damage_dealt_by_ship_types 表 load factor = 1.0f** (ctor 1065353216) | 不序列化  |
| +688 | 匿名结构 (16B 形状) RH 桶数组 | damage_dealt_by_ship_types — token→fixed RH 哈希表 {load f32@680, buckets@688, count@696 (=写门), aux 16B 容器@704}; loader 经 sub_14161A260(+680, token) 按键插入; 元 {token@+16, fixed@+24}, 键 = token 名 | 门 *(cb+696)≠0 |
| +744 | 匿名结构 (NNB 形状) 向量 | **以主将 (cb+304) 为键的命中缓存·桶 A** (sub_141622360 每小时清 sub_141989F40 后记录 (主将, member 开火数据)) | 不序列化 |
| +872 | 匿名结构 (NNB 形状) 向量 | 同上·桶 B (state==4 与否分桶) | 不序列化 |
| +880..+992 | uint64×15 | 每小时统计快照区 (combatant 自身累加, 尾段整体搬到 cb+744 缓存对象) | 不序列化 |

> 废弃 reader 键 **15516 `damage_dealt_by_box_types`** — reader (sub_1416209E0, §4.22.5a) 分发到本键但**不写任何 cb 字段**, 仅 reader 状态门 (载荷 a2+192 == 3 → sub_1424C2100); 与 15515/15517 同族命名残留, 老存档兼容读取。

- is_attacker (基座+216) GUI 消费: 脱离战斗命令载荷 CDisengageFromNavalCombatCommand {+40 海战 refid tok 0x2916, +48 is_attacker tok 0x28F5}; 玩家侧选取 sub_1417E7B30。
- screening 消费: CFEX 伤害减免 = 1−(1−a)(1−b) 合成 (SCREENING_TOOLTIP_LOW_INFO + 四个 SCREEN_RATIO/CAPITAL_RATIO define 加权直证)。

**组对象 = CFEXGroup** (g = 组基; sizeof 200; vtable 0x142a59ac8; ctor sub_141C69AF0; writer 0x141c6d0d0; loader 0X141C6C970):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | CFEXMember* 向量 | member[N] 容器数据 (vtable 0X142A1F1C8, sizeof 456; ctor sub_14196F350) | |
| +9..+19 | — | = member 容器尾 {cap@+16}  |  |
| +20 | uint32 | member[N] 容器计数 | |
| +21..+31 | — | = member 容器尾 {alloc@+24}  |  |
| +32 | 匿名结构 (NNB 形状)* | opponent_group = *(g+32) → 在 *(oppg+56) 的 group 数组找下标 (**loader 读档时清零**: case 12419 u32 解析 + `*(+32)=0`, 运行时再解回指针 — 定案) | 找到才写 |
| +40 | int32 | **opponent_group 下标缓存** (ctor = −1) | 不序列化  |
| +48 | fixed×1e-5 | forces_compare | 恒写 |
| +56 | CNavalCombatant* | **宿主参战方回指** (ctor a2; 与「*(oppg+56) 的 group 数组」自洽: oppg+56=对方 combatant, 其+232=group 数组) | 不序列化  |
| +64 | uint32 | disengage_counter (**ctor = dword_143335E1C define 初值**) | 恒写 |
| +68 | uint32 | chasing_counter | 恒写 |
| +72 | uint64 ×2 | 运行时 (+72/+80; ctor 0, 未名) | 不序列化  |
| +88 | CFEXAir* 向量 | air[N] 容器数据 (vtable 0x142A212E8, sizeof 328; ctor sub_141976630) | |
| +89..+99 | — | = air 容器尾 {cap@+96}  |  |
| +100 | uint32 | air[N] 容器计数 | |
| +101..+111 | — | = air 容器尾 {alloc@+104}  |  |
| +112 | CFEXMember* 向量 | members_to_delete 容器数据 (零样本未接; 推定同 member 型) | |
| +113..+123 | — | = members_to_delete 容器尾 {cap@+120} (loader case 13869 创建 member 推入) |  |
| +124 | uint32 | members_to_delete 容器计数 | |
| +125..+135 | — | = members_to_delete 容器尾 {alloc@+128}  |  |
| +136 | CFEXAir* 向量 | airs_to_delete 容器数据 (推定同 air 型); **运行时写者 = 0x141C6CC50** (member 移除时自 air 数组 {d@+88, c@+100} swap-remove 摘除匹配 air+16==目标的条目推入; 断言 "!pAir->IsExternal()" :1069 → **CFEXAir+129 = IsExternal 旗字节**, 闩 byte_14338C4A5) | |
| +137..+147 | — | = airs_to_delete 容器尾 {cap@+144} (loader case 13870 创建 air 推入) |  |
| +148 | uint32 | airs_to_delete 容器计数 (alloc@+152) | |
| +160 | uint64 ×4 | 运行时 (+160/+168/+176/+184; ctor 0, 未名) + +192 u32 (sizeof 200 尾部) | 不序列化  |

**member 条目 = CFEXMember** (m = 条目基; sizeof 456; vtable 0X142A1F1C8; ctor sub_14196F350; writer 0X1419760B0; loader 0X1419748F0; **舰/运输 idpair 取值器 0x140CE3010** = ship 对非空取 ship 对 @+8, 否则取 convoy 对 @+16, 两者皆空 → 断言 "Invalid FexMember: neither a ship nor a convoy"; 返回原始 8B idpair 非已解析对象; 两取值器均为一行函数 — ship 侧 sub_1411D7040 = `*out = *(qword*)(a1+8)`, convoy 侧 IDA 误名 `std::fpos<_Mbstatet>::state` = `*out = *(qword*)(a1+16)`); 另有成对单侧解析器 (解出对象, 空对返 0): ship 侧 sub_141622D40 (读 member+8) / convoy 侧 sub_140535C40 (读 member+16), 五分类普查与外溢执行点消费):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | ship 对.type (ship 对 {m+8,+12} / convoy 对 {m+16,+20}) | 四值任一非零写 |
| +12 | uint32 | ship 对.id | 同上 |
| +16 | uint32 | convoy 对.type | 同上 |
| +20 | uint32 | convoy 对.id | 同上 |
| +24 | 内嵌 | member.cached_info (见下表) | |
| +25..+223 | — | = cached_info **SCachedInfo 内嵌 200B 本体** (带自 vtable CFEXMember::SCachedInfo::vftable; 全字段见下 member.cached_info 表) |  |
| +224 | uint32 | state | 恒写 |
| +228 | uint32 | hours_to_arrive | 恒写 |
| +232 | CFEXGroup* | **宿主组回指** (ctor a2) | 不序列化  |
| +240 | fixed×1e-5[3] | cooldown.#1 — 3 值恒写 | 恒写 |
| +241..+263 | — | = cooldown fixed[3] 本体 (+240..+263; loader case 14622 范围 {+240,+264}) |  |
| +264 | 内联 32B | damage_received 容器数据 — 元 {vtable@0, ship 对@8, tag tid@16, damage i64@24}; writer 0X1419765D0 键名直证 = 10400 `ship` / 10754 `tag` / 12459 `damage` | c>0 才写 |
| +265..+275 | — | = damage_received 容器尾 {cap@+272}  |  |
| +276 | uint32 | damage_received 容器计数 | 同上 |
| +277..+287 | — | = damage_received 容器尾 {alloc@+280}  |  |
| +288 | uint32 | unique_id | 恒写 |
| +292 | uint32 | critical_hits_received | >0 才写 |
| +296 | uint32 | evacuated | ≠0 才写 |
| +300 | uint32 | hidden (**ctor = −1** = 写门 ≠0xFFFFFFFF 来源) | ≠0xFFFFFFFF 才写 |
| +304 | fixed×1e-5 | escape_progress | ≠0 才写 |
| +312 | 块基 | last_target 块 (writer 0X1419763F0: convoy u8@lt+8 / size u32@lt+12) | 门 b@m+328 ≠0 |
| +313..+327 | — | = last_target 块 **CLastTargetInfo** 本体 (vtable 0x142a20e98; loader case 11081: convoy u8@+320, size u32@+324, 首载置 vtable@+312 并立门 +328) |  |
| +328 | uint8 | last_target 门字节 | ≠0 才写块 |
| +336 | SAirHit* 向量 | air_hit[N] 容器数据 (元素 vtable 0X1429DC138, sizeof 24, ctor sub_1415C5D80; writer 0X1415C7C60): tag tid@ah+20 恒写; equipment_variant_index = *(ah+8) 非空 → 对@ptr+8; count u32@ah+16 恒写 | |
| +337..+347 | — | = air_hit 容器尾 {cap@+344} (SAirHit malloc 0x18=24 互证) |  |
| +348 | uint32 | air_hit[N] 容器计数 | |
| +349..+359 | — | = air_hit 容器尾 {alloc@+352}  |  |
| +360 | 8B 指针 向量 | **damage_received 容器** {data@360, cap@368, count@372, alloc@376} — dtor 虚删 + 合并器 sub_1415C75C0 (经 thunk sub_141973D60 = `(a1+360)`) + 持久化迁移至 ShipEntry+264; 合并器语义 = **tag 键控聚合累加器** (按 8B 键@元素+8 + tag@+20 配对, 命中则 i32@元素+16 累加并虚析构源元素, 未命中则 1.5× 增长 push); writer 不发射 (runtime-only) | 不序列化 |
| +384 | SNavalHit* 向量 | naval_hit[N] 容器数据 (元素 vtable 0x1429DDD38, sizeof 80, ctor sub_1415C6010; writer 0X1415C7CD0 = 元素 vtable[2]): target@h+8 / name 串@h+16 / convoy u8@h+48 / damage fixed@h+56 / strength fixed@h+64 / last_hit u8@h+72 全恒写 | |
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

**group air 条目 = CFEXAir** (ae = 条目基; sizeof 328; vtable 0x142A212E8; ctor sub_141976630; writer 0X14197D990; loader 0X14197CBF0; **+8 = CFEXGroup\* 宿主组回指**, ctor a2):

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
| +104 | — | = last_external_wave_date 24B vtable1 槽 (见下) |  |
| +112 | hours | last_external_wave_date — **24B {vtable1@+104, hours@+112, vtable2@+120=ADEC0 代理}** (ctor 双 vtable + hours=dword_143086B20 默认; 24B 定案) | 恒写 |
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
| +200 | uint64 ×6 | 运行时标量 (+200/+208/+216/+224/+232/+240; ctor 全零, 未名) | 不序列化  |
| +248 | uint32 | time_duration | 恒写 |
| +256 | SNavalHit* 向量 | naval_hit[N] 容器数据 (同 member 条目) | |
| +257..+267 | — | = naval_hit 容器尾 {cap@+264}  |  |
| +268 | uint32 | naval_hit[N] 容器计数 | |
| +269..+279 | — | = naval_hit 容器尾 {alloc@+272}  |  |
| +280 | SAirHit* 向量 | air_hit[N] 容器数据 (同 member 条目) | |
| +281..+291 | — | = air_hit 容器尾 {cap@+288}  |  |
| +292 | uint32 | air_hit[N] 容器计数 |  |
| +293..+303 | — | = air_hit 容器尾 {alloc@+296} |  |
| +304 | 匿名结构 (NNB 形状) 向量 24B | **damage_received 容器** {data@304, cap@312, count@316, alloc@320} — sizeof 328 恰满; 与 AirEntry+112 **同族同源** (合并器 sub_1415C75C0, 经 thunk sub_14197A570 = `(a1+304)`); 持久化迁移至 AirEntry+112; writer 不发射 (runtime-only) | 不序列化 |

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

#### 4.22.5a CNavalCombatant 运行时行为面 (naval_combatant.cpp; 8 函 1319 行)

全簇 = CNavalCombatant 加入/移除/分队/记伤/读档行为函数, §4.22.5 仅收 writer 与字段表, 本节收行为面; 与 §4.22.5 字段表 + §4.22.15 增删员对零冲突。

清册 (体内锚全部为 naval_combatant.cpp 路径断言/日志):

| VA | 行数 | 定性 |
|---|---|---|
| 0x14161AB40 | 424 | **AddTaskForce** — 特混舰队加入海战 (:951 断言 "vTotalWeights > 0_fixed", 闩 byte_14338A9C4; :954 random_fixed; pdx_scoped_buffer.h:54 断言, 闩 byte_143330D92) |
| 0x1416209E0 | 330 | **Load** — vtable[4] reader, 13 token 分发 (:1308 CLogStream "invalid size for combat damage history", 通道 65540) |
| 0x141620FA0 | 219 | **RegisterDamage** — 伤害记账 (三枚举断言 :355/:358/:361, 闩 byte_14338A9BB/A9BC/A9BD) |
| 0x141621320 | 194 | **RemoveUnit** — 海军特化包装 (:1031 断言 "pUnit->IsNavy()", 闩 byte_14338A9C6) |
| 0x14161E6D0 | 152 | **FindBestGroupForTaskForce** — 战力比匹配选组 + 回退 |
| 0x14161FBC0 | 72 | **TrimGroups** — 组数 > COMBAT_MAX_GROUPS 守卫/裁剪 (:1247 CLogStream "invalid number of groups", 通道 65540) |
| 0x14161B3C0 | 56 | **AddUnit** — 海军特化包装 (:1013 断言, 闩 byte_14338A9C5) |
| 0x14161A9E0 | 50 | **AddMember** — 成员入组 (组桶 = sub_142233FA0(file, 989) 确定性 hash 取模选组, count==0 ∨ 桶空则建新组) + 强度累加 (源 = a2+32, 对象身份待裁) + 参与登记 |

本簇新增写点/新事实 (cb = CNavalCombatant):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +24 | CNavalCombat* | 战斗回指 (两等价访问器 sub_1401F6EA0 / sub_14161A9D0 均 `return *(cb+24)`) | 定案 |
| +232 | 引擎向量 | group[N] 容器 {d@+232, count@+244}; 元 = CFEXGroup* (malloc 0xC8, ctor sub_141C69AF0) — 增/删/选组/裁剪六函同槽 | 定案 |
| +280 | 引擎向量 | 参战将领数组 {d@+280, count@+292}; 移除 = swap-remove + `--*(admiral+3704)` (CCharacter+3704 进行中海战计数, §4.4.2) | 定案 |
| +320 | uint8 | disengage — 新写点 = RemoveUnit 在战斗状态 > 1 时置 0 | 定案 |
| +352 | fixed×1e-5 | new_ships_positioning_penalty — **新写点 (增量)** = `+= POSITIONING_PENALTY_FOR_SHIPS_JOINED_COMBAT_AFTER_IT_STARTS × 舰数`, 钳 MAX_POSITIONING_PENALTY_FOR_NEWLY_JOINED_SHIPS; 门 = 战斗状态 (combat+68) > 0 | 定案 |
| +360 | fixed×1e-5 | positioning_dominance_bonus — **新写点 (一次性, 门 `!*(cb+360)`)** = 仅 tf+884 == 4 (护航) ∧ 战斗状态 ≤ 1 | 定案 |
| +376 | fixed×1e-5 | total_initial_strength — **新写点 (增量)** = `+= Σ CShip+1784` (舰当前强度, §4.16.18) | 定案 |
| +384 | fixed×1e-5 | total_damage_dealt — **新写点** = `+= damage` (敌方成员非 none 时) | 定案 |
| +392 | fixed×1e-5[36] | damage_dealt_by_gun_types — **索引定案 = 6×成员类型 + 武器类型** (列 = 武器 0..5, 行 = 成员类型 0..5); 记账 `*(cb+392 + 8·(weapon + 6·member)) += damage` | 定案 |
| +680 | RH 表 | damage_dealt_by_ship_types — **新写点 (运行时)**: 键 = CShip+136 舰型 token (无可解析舰 → 默认 11923 `convoy`), `*(RH 条目+24) += damage` | 定案 |

CNavalCombat (combat = *(cb+24)) 本簇消费的运行时字段 (§4.22.5 表外):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +56 | CProvince* (运行时) | **战斗所在省** (sub_140CE7410 = *(c+56) 直取; 与陆战侧 §4.22.17 六处省字段读同访问器互证); 读 **+200 → +232 链** (护航优势奖励池); 序列化形态 = terrain 串对象 (§4.22.5) | 定案 |
| +68 | int32 | **战斗状态**: ≤1 = 接敌前 (算加入数/算优势奖励); >1 = 已交战 (封锁加入, 清 disengage 与 combat+277) | 定案 |
| +268 | uint8 | **全员加入门** (真 → 加入数 = 全舰, 跳过侦测判定) | 定案 |
| +269 | uint8 | 同族门 (另一 naval 函数与 +268 同读, 经 sub_14161A9D0(cb) 旁证) | 推定 |
| +277 | uint8 | 交战中清 0 的运行时旗 (RemoveUnit/状态>1 路径) | 定案 |

CFEXGroup / CFEXMember 行为槽 (布局见 §4.22.5):

| 函数 | 语义 |
|---|---|
| sub_141C6A7C0 (326) | CFEXGroup::GetOrCreateMember(group, ship, state) — 建成员 (ctor sub_14196F0F0) 并置 member+224 state |
| sub_141C6A730 (31) | CFEXGroup::CreateMember(group, ship, flag) — malloc 0x1C8 (sizeof 直证) + ctor + `member+288 = ++*(combat+264)` + `member+232 = group` (宿主回指) + push group+8 |
| sub_141C69DC0 (24) | CFEXGroup::GetMemberByShip — 线性扫 member 数组按 ship idpair (member+8/+12) 匹配 |
| sub_141C6AE20 (11) | GetMemberByShip + sub_141C6AD90 二次确认 (组内含舰谓词) |
| sub_1419753F0 (6) | `*(member+224) = state` (状态置位器) |
| sub_141975270 (10) | `*(member+408 + 8·weapon) += damage` (member 侧 6 槽伤害记账) |
| sub_141622D40 (12) | 成员 idpair@+8 → CShip* 解析 |

CUnit / CTaskForce 侧新事实:

| 偏移/槽 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| CUnit 虚槽[9] (+72) | CTaskForce* | **海军单位的任务舰队解析器** (AddUnit/RemoveUnit 取 tf; ⚠ 与 §4.22.15 所记 CCountry vtable[9] = 国家对象解析器同名槽不同类) | 定案 |
| tf+832 → CFleet+176 | CFleet* → leader idpair | **舰队提督解析链** = sub_140D64510 (§4.16.19): `*(tf+832)` → sub_140D50EE0 读 fleet+176 idpair → sub_14221F310 → CCharacter* | 定案 |

AddTaskForce (0x14161AB40) 加入判定 (a1=cb, a2=tf, a3=CFEXGroup*, a4=fixed=本侧定位):

| 步 | 机制 |
|---|---|
| 1 接敌展开度 | `spread = clamp(EFFICIENCY_TO_JOIN_COMBAT_RATIO_PENALTY × (100000 − a4) / 100000 + MISSION_SPREADS[tf+884], 0, 100000)` |
| 2 全员门 | combat+268 ≠ 0 → 加入数 = 全舰 (跳过侦测) |
| 3 侦测折减 | 满情报/无目标 → 折减 = 100000 − MISSION_DEFAULT_SPREAD_BASE × spread / 100000; 有提督 (sub_140D64510(tf) ≠ 0) → `折减 = (提督 stat 86 + 100000) × 折减 / 100000` (经 sub_14055E360(fleet+664, out, 86)); 加入数 = clamp(折减 × 舰数 / 100000, 1, 舰数) |
| 4 加入计时 | hours_to_arrive = sub_14161B7C0(tf, a4) (公式见下) |
| 5 护航优势 | combat+68 ≤ 1 ∧ `!*(cb+360)` ∧ tf+884 == 4: 经 `*(*(combat+56) + 200) + 232` 取目标国装备市场池 → ratio = 1e5×A/DOMINANCE_CONTROLLED_THRESHOLD_RATIO; excess = ratio − 1e5; r = clamp(1e5×excess/DOMINANCE_EFFECT_ON_POSITIONING_FOR_CONVOY_ESCORT_MAX_RATIO, 0, 1e5); `cb+360 = DOMINANCE_EFFECT_ON_POSITIONING_FOR_CONVOY_ESCORT × r / 1e5` (一次性) |
| 6 强度累加 | cb+376 += Σ CShip+1784 (全舰, 与加入数无关) |
| 7 成员创建 | 全员加入: 每舰 GetOrCreateMember(ship, **state 1**); 部分加入: 每舰 GetOrCreateMember(ship, **state 4**) + member+228 = hours_to_arrive, 再按权重 `sub_140C3AAE0(ship) + sub_140C3A950(ship) + 1000` **确定性加权随机** (random_fixed :954, 累权重 ≥ 阈值即中, swap-remove) 选 N 舰置 member+224 = 1; 零加入 (含 combat+68 > 1): 每舰 state 4 + member+228 = hours_to_arrive |
| 8 定位惩罚 | combat+68 > 0: cb+352 += POSITIONING_PENALTY_FOR_SHIPS_JOINED_COMBAT_AFTER_IT_STARTS × 舰数, 钳 MAX_POSITIONING_PENALTY_FOR_NEWLY_JOINED_SHIPS |
| 9 尾 | sub_141622360(cb) = 每小时命中缓存记录 (§4.22.5 已收) |

> hours_to_arrive (sub_14161B7C0, 写 member+228): org 比 = clamp(1e5 × Σ CShip+1792 / Σ sub_140C37E70(ship), 0, 1e5) (sub_140C37E70 = `max(100, (ship+768 + stat70) × (stat71 + 1e5 + stat638) / 1e5)`, stat 71/638 = §4.16.21 org cap 同族); 时长 = BASE_JOIN_COMBAT_HOURS × (1e5 + LOW_ORG_FACTOR_ON_JOIN_COMBAT_DURATION × (1 − org比)); `+= EFFICIENCY_TO_TIME_TO_JOIN_COMBAT_PENALTY × (1e5 − a4 定位)`; tf 统计 25 经 COORDINATION_EFFECT_ON_TIME_TO_JOIN_COMBAT 缩放为除数; 终值 = 1e5 × 时长 / 除数, 钳。

RemoveUnit 海军包装 (sub_141621320): 断言 IsNavy → vtable[9] 取 tf → 双层循环统计该 tf 舰在各组覆盖率 → CCombatant::RemoveUnit 基类 (§4.22.15) → sub_140D64510(tf) 解提督: cb+32 单位表已空 → 直接从 cb+280 swap-remove + `--*(admiral+3704)`; 否则遍历剩余单位解提督, 仍被引用则保留, 全部不再引用才移除 → 门 `!*(gs+2618)` ∧ cb+32 非空 → sub_1415C5AF0(combat) + cb+304 = cb vtable[29](cb); cb+312 同值 (无条件重选)。

RegisterDamage (sub_141620FA0) 双枚举映射:

| 枚举 | 映射 (0..5 合法, 6 = 断言) |
|---|---|
| 武器类型 | 敌方为潜艇 (sub_141973D30 解船 + sub_140C3B220) → 3; a2 ∈ {2,0,1} → {0,1,2}; 无成员 → 4; 无敌 → 5 |
| 成员类型 | member+16 有 convoy idpair (sub_141973C70) → 3; member+224 state 经 sub_1419723B0 映射 {1,2,8}→0, 3→1, 4→2, {5,6}→4; 无成员 → 5 |

> 记账: `cb+392[6·成员类型 + 武器] += damage`; 敌方非 none → cb+384 += damage ∧ CShip+136 舰型 token (缺省 11923 `convoy`) 经 sub_14161A260(cb+680) 入 RH 条目+24 += damage; 尾 sub_141975270(member, 武器, damage) → member+408[武器] += damage。

FindBestGroupForTaskForce (sub_14161E6D0): 组数 < COMBAT_MAX_GROUPS → 返 0 (不选); tf 战力比 (sub_140D68BE0/C70/D00 三聚合) 与各组比 (sub_141C6A270 计数 + sub_141C6A370 双聚合) 按 BEST_CAPITALS_TO_SCREENS_RATIO 最近匹配选最优组; 无匹配 → 选 member 数 (group+20) 最小组; 再无 → file:line 确定性 hash (sub_142233FA0 @ :161) 取模选组。

Load (sub_1416209E0) reader 13 键:

| token | 键名 | 动作 | §4.22.5 字段 |
|---|---|---|---|
| 63 | group | malloc 0xC8 CFEXGroup + ctor + **vtable[3] Load** 递归 + push cb+232 | +232 ✓ |
| 10403 | unit | idpair 解引 −16 → CCombatant::AddUnit(cb, unit, 100000) + sub_1416212A0 | +32 ✓ |
| 10725 | positioning | cb+344 fixed | +344 ✓ |
| 12002 | disengage | cb+320 u8 | +320 ✓ |
| 12166 | anti_air | cb+368 fixed | +368 ✓ |
| 13569 | last_leader | idpair 解引 → cb+312 指针 (门: reader 对象 a2+296 的 +8/+9 双旗) | +312 ✓ |
| 15349 | new_ships_positioning_penalty | cb+352 fixed | +352 ✓ |
| 15515 | damage_dealt_by_gun_types | 容器 count == 36 → 拷 36 fixed 至 cb+392..+679; 否则 CLogStream "invalid size for combat damage history" :1308 | +392 ✓ (count 门新) |
| 15516 | damage_dealt_by_box_types | reader 状态门 (a2+192 == 3 → sub_1424C2100), **不写任何字段** (废弃键, 见 §4.22.5 注) | — |
| 15517 | damage_dealt_by_ship_types | 嵌套块: '=' (64) 分支取串 → sub_14161A260(cb+680, token) RH 插入, 值@条目+24 | +680 ✓ |
| 15519 | total_initial_strength | cb+376 fixed | +376 ✓ |
| 15520 | total_damage_dealt | cb+384 fixed | +384 ✓ |
| 17134 | positioning_dominance_bonus | cb+360 fixed | +360 ✓ |

define 落名 (defines_map_1193.txt 直证):

| 全局 | define |
|---|---|
| qword_143334800 | EFFICIENCY_TO_JOIN_COMBAT_RATIO_PENALTY |
| qword_1433398C0 | MISSION_SPREADS (数组, 索引 = tf+884 任务类型) |
| qword_143331B70 | MISSION_DEFAULT_SPREAD_BASE |
| qword_143331BF0 | POSITIONING_PENALTY_FOR_SHIPS_JOINED_COMBAT_AFTER_IT_STARTS |
| qword_143331CE0 | MAX_POSITIONING_PENALTY_FOR_NEWLY_JOINED_SHIPS |
| qword_143334E00 | DOMINANCE_EFFECT_ON_POSITIONING_FOR_CONVOY_ESCORT |
| qword_143334EC0 | DOMINANCE_EFFECT_ON_POSITIONING_FOR_CONVOY_ESCORT_MAX_RATIO |
| qword_143337260 | DOMINANCE_CONTROLLED_THRESHOLD_RATIO |
| dword_143330F5C | BASE_JOIN_COMBAT_HOURS |
| qword_143331018 | LOW_ORG_FACTOR_ON_JOIN_COMBAT_DURATION |
| qword_143334770 | EFFICIENCY_TO_TIME_TO_JOIN_COMBAT_PENALTY |
| qword_1433348B8 | COORDINATION_EFFECT_ON_TIME_TO_JOIN_COMBAT |
| qword_143334820 | BEST_CAPITALS_TO_SCREENS_RATIO |
| dword_143335C54 | COMBAT_MAX_GROUPS |

#### 4.22.5b 海战网格行聚合与排序 (0x1417D-E 带; 定案)

宿主 = sub_1417ED140 (§4.22.5 表 combat+232 行 GUI 消费体): 8 个 24B 行向量 (a1+24 起步进 24B ×8) 各走稳定降序排序 + a1+216 32B 元向量 (sub_1417DF250/sub_1417DFE90 实例) + 汇总文本/图标计数段。

**聚合行 (40B) 布局** (填充器 sub_1417ECC10/sub_1417EC9F0):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | 24B 向量 {data, alloc@8, count@12} | CFEXMember const* 成员船指针数组 (CPdxHybridInlineBufferAllocator<CFEXMember const*,128> 背书; assign/swap 原语 = sub_1417E2F70) |
| +24 | i32 | 聚合统计键① (填充侧读 CFEXMember+36, 推定对应舰船 +1548 值) |
| +28 | i32 | 聚合统计键② (填充侧读 CFEXMember+40, 推定对应舰船 +1576 值) |
| +32 | u8 | member+65 字节 |
| +33 | u8 | member+224 state (✓§4.22.5) |
| +34 | u8 | 军通反旗 (sub_140700600 假 → 1) |
| +35 | u8 | 计算字节 |
| +36 | u32 | owner tag = member+32 (sub_140BB52F0 同原初国比对参与行匹配) |

排序 = **std::stable_sort 插入 pass sub_1417DF550** (MSVC ISORT_MAX=32 块内; 全函数域 0x1417DF550): comparator 六键降序稳定 ① +32 → ② +24 → ③ +28 → ④ 向量 count (+12) → ⑤ +35 → ⑥ max(成员+288 unique_id) (+288 自增源互证 ✓); 全等时地址比较 tiebreak (实现恒定性, 待裁)。编排 = sub_1417DDCB0 (>32 元按 1280B = 32 行分块逐块+归并) / sub_1417DFFA0 (缓冲减半 malloc 链)。

#### 4.22.6 naval_combat_result 全族 (gs+1472 容器; ⚠ 与 4.22.5 是**两个族**)

进行中海战 (4.22.5) 与 战果报告池 (本节) 无结构关系, 仅命名相近。

容器 = gs+1472 {d} / gs+1484 {c} 裸 {d, c@d+12} 形态 (非对象), 元素 8B 指针。顶层 writer 链: sub_1401F2E40 逐元素 ADEC0 (tok 0x34FC=13564, elem) → 共享壳 0X1424BEC50 → 块内容 0X140CE6B20 (不在索引; 反汇编 + ctor 0X140CE15E0 / reader 0X140CE5AF0 三向互洽)。块门 = 计数>0 仅此一门 (save/checksum 同路径)。提取形态 = 顶层匿名重复块, 块级 [N] 记在维度 (首块裸, 第 2 起 [2]..; 维度内路径不含块名)。sizeof(CNavalCombatResults) = **0x168=360** 定案: 读档工厂 case 13564 `malloc_base(0x168)` → ctor → push gs+1472 (dump 行 5207661); 第二分配点 combatnaval.cpp:973 (malloc 语句) 同 0x168 — refid 绑定+注册行锚 = :996 (互补非冲突)。读档工厂另在 gs+1496 经 sub_1401B7250 维护 location→块 运行时桶索引 — 注册器 sub_1401CAE40 全体**无 writer 调用** → 纯运行时派生索引, 不发射 (定案)。

**存活期聚合链 (定案)**: 每小时相位 12 战斗结束 → 基类结束通知 sub_1413E2CF0 调**槽[23] 战斗结束钩子** (基类/陆战 = CFG 空桩, **仅 CNavalCombat 覆写 = sub_1415C4C90 海战结果生成** — 陆战不产生本族报告) → 门 = `!hide` ∧ 一侧结束 ∧ 一侧空; strike 战斗 (port/naval) 才走查重 — gs+1496 location 桶查同省既有报告 → 命中 sub_140CE4F90 合并 (刷 date + 侧匹配度判并侧 + 深拷贝 sub_140CE21B0 + 重算 importance); 未命中新建 (malloc 0x168 + ctor sub_140CE15E0 + refid 绑定) → **聚合器 sub_140CE5D50**: date = gs+1128 / location = 省 id / 两侧 = c+136/+144 镜像指针消费 / strike 旗直拷 / importance = 两侧和经 COMBAT_RESULT_PRIORITY_THRESHOLDS 线性查档 clamp ≤2 / to_discard_date = now + COMBAT_RESULT_PRIORITY_DAY_TO_LIVE[档] / shown_to_countries = 两侧活国并集 / +248/+256 = 主/次侧迭代对 (胜侧在前)。**每日清除** sub_1401D7830 (shown 空 ∨ to_discard 过期 → sub_1401EBA80 swap-remove + location 桶解除); **已读注销** = CDispatchNavalCombatResultsCommand::Execute sub_141156890 → sub_140CE4BE0 从 shown_to_countries 移除 tag。

**CNavalCombatResults** (vtable 0x14295DD70; sizeof 0x168=360; 块内容 writer 0X140CE6B20)。发射序 = id → location → date → attacker → defender → port_strike → naval_strike → importance → to_discard_date → shown_to_countries (表行序 = 偏移升序, 发射序以本句为准)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | uint32 | 自 refid.type (全局命名空间 4713) | 恒写 (`id` 块 0X142220340 同行双写; tok 0xB=11) |
| +12 | uint32 | 自 refid.id | 恒写 (同上) |
| +16 | uint8 | CReferenceObject 注册/有效旗 (ctor 清 0 / sub_14221E700 置 1) | writer 不发 |
| +24 | CNavalCombatResultSide 内嵌 (112B) | attacker | 恒写 (ADEC0 整块; tok 0x28F5) |
| +25..+135 | — | = **attacker CNavalCombatResultSide 内嵌 112B 本体** (+24..+135) 内部 — 子布局见下表  |  |
| +136 | CNavalCombatResultSide 内嵌 (112B) | defender | 恒写 (tok 0x28F6) |
| +137..+247 | — | = **defender CNavalCombatResultSide 内嵌 112B 本体** (+136..+247) 内部  |  |
| +248 | 匿名结构 (NNB 形状)* | 主/次侧迭代对 — 胜侧 (sub_140CE32A0 判定) 在前 | writer 不发 |
| +256 | 匿名结构 (NNB 形状)* | 迭代对之另一 (次侧) | writer 不发 |
| +264 | uint32 | location (省 id) | 恒写; tok 0x286D |
| +272 | vptr | CGameDate 载体 (ctor 写 vtable) | writer 不发 |
| +280 | int32 | date 值 (ctor = 43791240 "-1.1.1.1" 合法值) | 恒写 (经别名槽 +288; tok 0x284A) |
| +288 | vptr | date 序列化别名槽 (vtable 0x1427183d8; 别名 writer 0X140533F70 读 this-8) | — |
| +296 | uint8 | port_strike | 恒写 yes/no 均写 (tok 0x32AB) |
| +297 | uint8 | naval_strike | 恒写 yn (tok 0x309D) |
| +304 | vptr | CGameDate 载体 (to_discard) | writer 不发 |
| +312 | int32 | to_discard_date 值 (ctor = 43808760 "1.1.1.1") | 恒写 (经别名槽 +320; tok 0x3C96) |
| +320 | vptr | to_discard 序列化别名槽 (同 vtable) | — |
| +328 | uint32 | importance (ctor 默认 3; load 分派置 0; 黑档实测 0/1/2 = 游戏逻辑赋值) | 恒写; tok 0x3C97 |
| +336 | int32 向量 | shown_to_countries 容器数据 — int 国家 id 数组 stride 4, 原生逐行裸 tag 串 | **计数@+348≠0 才发块**; tok 0x4DD9; 提取形 `shown_to_countries.#N` 恒编号 |
| +344 | 匿名结构 (NNB 形状)* | 容器 end 槽 | — |
| +348 | uint32 | shown_to_countries 容器计数 | |

**CNavalCombatResultSide** (内嵌 0x70=112B; vtable 0x14295DD20; writer 0X140CE6760; 继承 CPersistent — 内嵌对象无自 refid)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | CNavalCombatAirEntry* 向量 | air_wing 数组数据 — 8B 指针元素 → CNavalCombatAirEntry; 重复键第 2 起编 [N] | 门 计数@+20>0; tok 0x3369 air_wing |
| +9..+19 | — | = air_wing 容器 {d@8, **cap@16**, c@20, alloc@24} 的 data 尾 + cap@16 (pdx 24B) |  |
| +20 | int32 | air_wing 计数 | |
| +21..+31 | — | = air_wing count@20 尾 + **alloc@24**  |  |
| +32 | CNavalCombatShipEntry* 向量 | **归属: 本行 (writer 键 10400 ship) 实产于战果侧 CNavalCombatResultSide (ship 数组 +32/+44, air +8/+20; writer sub_140CE6760), 活体 CNavalCombat 本体 +32/+44 = 打包 id 句柄非容器**; 活体真链 = +152/+160 两侧 force 容器 → force+232{d}/+244{c} 任务分舰队 → tf+8{d}/+20{c} 真实 CShip\* (元素vtable槽 [1][3][5] 与 CShip 基表全同、[0][2][4] 派生覆写, 活体直证) (air 在 tf+88/+100 与 +136/+148) | 门 计数@+44>0; tok 0x28A0 ship |
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

**CNavalCombatShipEntry** (条目; vtable 0X14295C490; writer 0X140CE6C50; dtor 0X140CE1B50; 布局下界 ≥0x118)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | uint32 | unique_id.type (type=4713) | 恒写 (0X142220260; tok 0x30AA unique_id) |
| +12 | uint32 | unique_id.id | 恒写 (同上) |
| +16 | SCachedInfo 内嵌 (0xC8=200B) | cached_info | 恒写 (ADEC0; tok 0x31EB) — **与 4.22.5 member.cached_info 同一 writer 0X141976430 同一结构**, 字段表 = §4.22.5 member.cached_info 行 |
| +17..+215 | — | = **SCachedInfo 内嵌 200B (0xC8)** 本体 (+16..+215) — 字段表 = §4.22.5 member.cached_info 行 (同一 writer 0X141976430 同结构) |  |
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

**SNavalHit** (vtable 0x1429DDD38; sizeof 0x50=80; writer 0X1415C7CD0; ctor 0X1415C6010; reader malloc(80); 六字段全恒写)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | target (省 id) | 恒写; tok 0x6B target |
| +16 | 串 (32B) | name | 恒写 (!AAFD0 时); tok 0x1B name |
| +17..+47 | — | = SNavalHit name SSO 32B 本体 (buf@16 尾 + size@+32 + cap@+40=15) |  |
| +48 | uint8 | convoy | 恒写 yes/no 均写 (⚠ 异于 cached_info.convoy 的 yes-only); tok 0x2E93 |
| +56 | fixed×1e-5 | damage | 恒写; tok 0x30AB |
| +64 | fixed×1e-5 | strength | 恒写; tok 0x28A6 |
| +72 | uint8 | last_hit | 恒写 yn; tok 0x30AC |

**SAirHit** (vtable 0X1429DC138; sizeof 0x18=24; writer 0X1415C7C60; ctor 0X1415C5D80; reader malloc(24); **读取分派器 0x1415C79A0** = 4 token 全吻合: count(10730)→+16 / tag(10754)→+20 / equipment(12110) 块 / equipment_variant_index(13891)→+8; 12110 = reader-only 键, writer 不发)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | 匿名结构 (NNB 形状)* | 装备数据库对象 → refid @obj+8 | 门 ptr≠0 (0X142220260); tok 0x3643 equipment_variant_index |
| +16 | uint32 | count | 恒写; tok 0x29EA count |
| +20 | tag_id (int32) | tag (国家 id, BA5C20 串化) | 恒写 — **发射序首字段**, 先于 equipment_variant_index; tok 0x2A02 tag |

**CNavalCombatAirEntry** (条目; vtable 0X14295C440; writer 0X140CE6630; ctor 0X140CE1450; sizeof 0x88 = 136, 分配点 sub_140CE21B0 malloc 直证; **读取分派器 0x140CE53F0** = 9 token 与字段表 8/9 项完全吻合: max(676)→+16 / tag(10754)→+28 / equipment(12110) 块 / air_base(12214)→+32 / alive(12451)→+20 / naval_hit(12456) 入 +64 容器 (malloc 80 → SNavalHit ctor) / air_hit(12457) 入 +88 容器 (malloc 24 → SAirHit ctor) / killed(13164)→+24 / equipment_variant_index(13891)→+8; **12110 = equipment 块 = reader-only 键** — sub_140BDF080 = CEquipmentVariantReference 解析, 同写 tag@+28 与装备变体指针@+8, writer 不发此键)。原生发射序 = max → alive → killed → tag → equipment_variant_index → air_base → naval_hit×N → air_hit×N; 段 evi 前置与原生序不同 — 叶键互异, 多重集无序配对无害 (20 档实证)。全字段表:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vptr | vftable | — |
| +8 | 匿名结构 (NNB 形状)* | 装备数据库对象 → refid @obj+8 | 恒写 (0X142220260, **原生无空门**; 段加 kptr 防御); tok 0x3643 |
| +16 | uint32 | max | 恒写; tok 0x2A4 max |
| +20 | uint32 | alive | 恒写; tok 0x30A3 alive |
| +24 | uint32 | killed | 门 >0 才写; tok 0x336C killed |
| +28 | tag_id (int32) | tag (BA5C20 串化) | 恒写; tok 0x2A02 |
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
| CDispatchNavalCombatResultsCommand (vtable 0x142993578; 命令 writer slot22 0X14116F7B0, tok 0x34FD) | 运行时清除命令, 非存档结构 |
| sub_140CE6D20 (vptr 0x14295DE20; 写 region 0x2A4B / is_sunk 0x3945 / equipment 0x2F4E / ship 0x28A0 / country 0x289A ×2 / to_discard_date 0x3C96) | RTTI 扫描未名, 推定海战事故报告姊妹类 |
| UI 族六件: CNavalCombatResultsWindow (5088B; 内嵌 **CInternalSideData 每侧聚合件 ×2 @+3912/+4480** (560B/件: 10 容器 +8..+247, idpair ×2 @+248/+256, SSO 串 ×7 @+264..+487, 子对象指针 @+536/+552; 复位 sub_1417D6980, 真 ctor sub_1417D61A0; 纯显示侧零存档 — survivors_grid 装配 sub_1417D7740)) / CNavalCombatResultsMapIcon / Lost·Survivor GridBoxItem | 纯 UI |
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

**CCombatTactic = 静态数据库类** (非战斗内对象): 加载器 sub_1406C01D0 (common/combat_tactics; TGameItemDatabase 模式 — 先装 nullCombatTactic 哨兵 (id=0, CNullCombatTactic 派生) → 逐行 malloc(0x178=376) + ctor sub_1406BD5B0(实例, 名, id 自增 1 起) → 名哈希入桶 + 顺序数组); 数据库单例 sub_1406BDB00; 相位表 @db+40 (32B/条, 经 battle+208 相位下标取条); id getter sub_1406C00D0 = *(u32*)(+152); **+224 = 条件触发器容器** (槽[3] Evaluate; 失败打 "TACTIC_CONDITIONS_NOT_MET")。
**入栈点** = 战术重掷核 sub_1412BBF90 (每 TACTIC_SWAP_FREQUENCEY 12h 或一侧 cb+304 空) → sub_1412BB330 加权随机: 成功 `cb+304 = sub_1406BDDF0(db, 选中 id)` / 失败 `cb+304 = nullCombatTactic` + "Couldn't select a tactic in phase '...' - missing default fallback tactics?" 断言。**权重填充 sub_1412BC860 四道门**: ① tactic+368 旗 ∨ 国家可用; ② 槽[10] 有效; ③ +224 触发器 Evaluate; 乘子 = INITIATIVE_PICK_COUNTER_ADVANTAGE_FACTOR (反制当前战术) × COUNTRY_PREFERRED_TACTIC_WEIGHT_FACTOR (国家修正块 preferred tactic) × ARMY_GENERAL_PREFERRED_TACTIC_WEIGHT_FACTOR (己方将领偏好) × FIELD_MARSHAL_PREFERRED_TACTIC_WEIGHT_FACTOR (对方将领偏好)。

CCombatTactic 布局全表 (376B 全覆盖; CTacticsListEntry Refresh 消费; target = CCombatTactic\*@entry+32, SetTarget 0X141C70760):

| 偏移 (tactic) | 类型 | 语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | only_show_for 国 tag id | 定案 |
| +16 | MSVC 串 32B | 内部名 (FNV32 桶键) | 定案 |
| +48 | MSVC 串 32B | 显示名 (活体 = 本地化文案「进攻」等; 本地化覆写点未定位) | 定案/覆写点待裁 |
| +80 | MSVC 串 32B | countered_by 串 — 加载器尾 (combattactics.cpp:406) 名哈希查桶回填 +144 = 对方 id; 判定 sub_1406C01B0 = 对方 id == 本方 +144; **被反制侧六值不聚合** (sub_1412AE250) | counter 链闭环 |
| +112 | MSVC 串 32B | 图标串 | 定案 (原锚吻合) |
| +144 | uint32 | countered_by 对方 id (加载器回填) | 定案 |
| +152 | uint32 | id (= 顺序下标; 越界回 null 哨兵) | 定案 (原锚吻合) |
| +160 | fixed×1e-5 | aggressiveness — **无消费者** (键可解析写入, 全扫无读; vanilla 未用, 推定预留键) | 推定 |
| +168 | 内联 base 权重块 | CMeanTimeToHappen 形状 {factor@+192, 修饰符向量@+200..+216}; 求值器 sub_1405520E0, 无修饰符直返 +192; +184 常量 16 用途未名 | 定案/16 待裁 |
| +224 | CAndTrigger 88B 内联 | 条件触发器 (token 10600 "and"; 子条件向量@+232) — 槽[3] Evaluate, 失败打 "TACTIC_CONDITIONS_NOT_MET" | 定案 (原锚吻合) |
| +312 | fixed×1e-5 | combat_width | 定案 |
| +320 | fixed×1e-5 | attacker | 定案 |
| +328 | fixed×1e-5 | defender | 定案 |
| +336 | fixed×1e-5 | attacker_movement_speed | 定案 |
| +344 | fixed×1e-5 | attacker_org_damage_modifier | 定案 |
| +352 | fixed×1e-5 | defender_org_damage_modifier | 定案 |
| +360 | int32 | 阶段索引 1 | 定案 |
| +364 | int32 | 阶段索引 2 | 定案 |
| +368 | uint8 | 可用旗 (active) | 定案 (原锚吻合) |
| +369 | uint8 | is_attacker 旗 (键 11472, bool reader; ctor 与 +368 双字同置 1 = 默认真) | 定案 |
| +372 | uint32 | 图形注册表条目索引 (ctor 期按名哈希查询/注册, 活体按加载序连号) | 推定 |

六值类型 = 定点×1e-5 (i64), 非 f64 (活体位型 5000/25000/400000 + parser 读取路径双证); +160/+192 同为 fixed。六值定名双源 = reader token 表 + tooltip 格式化器 sub_1406BDE10 的 TACTICS_* loc 键。权重填充六值聚合即上述六值进 battle+160..+200。
数据库单例 = BASE+0x3330C90 (桶@+4/+8、顺序数组@+16/+24/+28、相位表@+40 32B 串×5、计数@+52); vtable 11 槽 ([3] Load wrapper→[4] Reader、[9] GetName = &+48、[10] 恒真有效槽)。

**ParseKey 键分发表** (sub_1406C07F0; 16 键, token 名全部核对):

| 键 token | 名 | 目标 | 读取器 |
|---|---|---|---|
| 15546 | only_show_for | +8 | tag 解析 |
| 11921 | countered_by | +80 | 串 |
| 464 | picture | +112 | 串 |
| 11922 | aggressiveness | +160 | 定点 |
| 11398 | base | +168 | **vtable thunk sub_1424C0AA0 = `(*(a2+24))(a2,a1)` → CMeanTimeToHappen::Parse** |
| 10519 | phase | +360 | 相位名→下标 |
| 13968 | display_phase | +364 | 同上 |
| 11390 | active | +368 | bool |
| 11472 | is_attacker | +369 | bool |
| 11471 | combat_width | +312 | 串→定点 |
| 10485 / 10486 | attacker / defender | +320 / +328 | 同上 |
| 13965 | attacker_movement_speed | +336 | 同上 |
| 19535 / 19538 | attacker_org_damage_modifier / defender_org_damage_modifier | +344 / +352 | 同上 |
| 10595 | trigger | +224 | CAndTrigger (vtable+40 槽带 parser) |
| 其他 | — | — | CLogStream 通道 65540「Unknown combat tactic effect '...'」(:131, 无中断) |

> ⚠ **11398「base」分派去歧义 (定案)**: IDA 伪码该分支调用形似普通定点读, 若据此落盘会把 +168 降级为标量。汇编级复核: `lea rdx,[r14+0xA8]` → `call sub_1424C0AA0` (5 行 vtable thunk), 即 CMeanTimeToHappen::Parse — **+168 内联权重块定案不动**。

**相位名查表** (sub_1406C0100): 线性扫 db+40 顺序数组 (32B SSO 条目, count@db+52), 按 size@+16 与字节比对, 返回下标或 0xFFFFFFFF; **字面量 "no" → −2** (显式特例, 非查表失败); 未知相位名 → CLogStream 通道 65540「Unknown combat phase」(:107/:125)。

**加载器尾段** (sub_1406C01D0, 依赖解析): countered_by 串长度 (tactic+96) >0 的条目 → 名哈希查桶; 未命中 → 回退 null 战术; null 战术 IsValid (vtable+80) 为假 → CLogStream 通道 65540「dependency for tactic '...' doesnt exist: '...'」(:406, 无中断); 命中则 tactic+144 = 目标战术 +152 id (counter 链闭环)。

**CMeanTimeToHappen 求值器** (sub_1405520E0): `*out = factor`; 修饰符容器 (count@块内+44) 内每个 CModifier 若 Evaluate (vtable+24) 通过: `*out = *out × 修饰值 / 100000 + 加数@mod+296` (块内相对坐标 +24 factor / +32 容器; = tactic 绝对坐标 +192 / +200, 与上表一致)。

| 项 | 定案 |
|---|---|
| CTacticsListView ×3 target | combat (SetCombat 0X141C70F60; att/def +40/+48 ✓册; **combat+208 = 阶段** 新定案) 或 leader/country 枚举 (注册表 gs+1024 链) |
| CTacticsListView 池化布局 | +2728/+2752/+2832 等 9 成员定案 |
| 撞偏移复核 | 0X1415CE480 = 回收助手 / 0X1415CEFB0 = Clear, 确属本族, 与 CLandCombatView 异类 (⚠ 排雷见 4.22.7) |
| CSelectArmyLeaderPreferredTacticsEntry | 基 entry + CButtonWrapper@+72; entry+64 = CLandCombat\* (推定) |
| 其可用判定 | skill+440 军衔等级 (✓§4.4) ≥ define **PREFERRED_TACTIC_CHARACTER_SKILL_LEVEL_REQUIRED** ∧ 国有战术 ∧ CP |
| CSelectCountryPreferredTacticsEntry | CP 价公式定案 = cc+496 command_power (✓§4.3) ≥ 100000 × (**country_modifiers[#589]** 截整 ✓册查表 + define **PREFERRED_TACTIC_COMMAND_POWER_COST**) |

#### 4.22.8 CShipCombatReader (海战视图特效静态配置; vtable 0x1429E82F0)

writer = CFG 空桩 → **不入档** (静态 reader); 源 = gfx/naval_combat.txt; reader 0x141664C90 / ctor-dtor 0x141661700。

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | MSVC 串 32B | naval_formation (12631) | 阵容字串 |
| +40 | float | naval_formation_scale (12632) | 阵容缩放 (ctor 默认 1.0f) |
| +48 | MSVC 串 32B | naval_combat_formation (12633) | 战形字串 |
| +80 | float | naval_combat_formation_scale (12634) | 战形缩放 |
| +84 | float | naval_random_start_time (12913) | 随机起始时刻 |
| +88 | vec | naval_hit_effects_small (12635) | {d@88, cap@96, c@100, alloc@104} 图形特效对象 |
| +112 | vec | naval_hit_effects_big (12636) | 同上 |
| +136 | vec | naval_miss_effects_small (12637) | 同上 |
| +160 | vec | naval_miss_effects_big (12638) | 同上 |
| +184 | float | naval_death_time (12640) | 死亡时刻 |

> 与 §4.22 海战 combatant +384 SNavalHit (战斗事件收发器) 同名不同域, 勿混。

> **本域 GUI 类布局**: 见 4.30.18 / 4.31.37 / 4.31.49 / §4.31.23。

#### 4.22.9 CCombat 行为槽 (每小时战斗步进契约; vtable 0x1429BBC58 基 / 0x1429A83D8 陆)

CCombatManager (§4.22.1 gs+608) 每小时逐战斗调vtable槽[15] = 战斗步进主入口
(五阶段调度链 = §4.22.9a)。行为槽定案 (COL 链直读):

| 槽 | 语义 | 备注 |
|---|---|---|
| [8] | `return 3` 常量 getter | 基类共享 |
| [9] | **IsActive**: 双侧参战 tag/单位耗尽即结束 | CLandCombat = 基类判定+两侧容器计数 |
| [11] | GetDuration (历史 entry 消费) | 基类 purecall, 陆/海各自覆写 |
| [12] | **progress 读取**: Σ己侧全部师当前 org (0x1412B5360) | 经 sub_140CDF0E0 每小时整量重写 lb+616 |
| [13] | **首小时初始化** (byte+81=1 / 清 byte+82 结束旗) | CLandCombat 先做两侧大体量初始化 sub_1412AC450 |
| [14] | **结束标记** (byte+82=1, 通知两侧) / 领袖 XP (损失比×0.5) | 双用途: 步进域 [14]=标记, 基类槽[15] 四连内 [14]=XP |
| [15] | **每小时战斗步进主入口** | 全链 = 战术重掷核 (12h) → 时长计数 → 参战国 tag 遍历 → 基类四连, 详 §4.22.9a |
| [16] | 结束复核 bool(self, idx, count) | 基类 purecall |
| [19] | **伤害执行步** (**0x1412B82E0**) | 目标分配 (ENGAGEMENT_WIDTH_PER_WIDTH 预算 + DAMAGE_SPLIT_ON_FIRST_TARGET 聚焦钳 0.9 + 打弱评分) → 闪避 → STR/ORG 骰 → 穿甲偏转 → TakeDamage; 空军支援波次 (2×4h 冷却) + 侧翼检测 (≥3 省 → cb+219) + cb+220 敌空军旗; 尾推 progress |
| [22] | **修饰符全量重算** (stacking/over-width/补给/夜战/挖掩/岸轰/空优/情报/包围, 34 distinct define) | 每小时步进第 1 步 |
| [23] | **战斗结束钩子** (结束通知 sub_1413E2CF0 内调) | 基类/CLandCombat = CFG 空桩; **仅 CNavalCombat 覆写 = sub_1415C4C90 海战结果生成** (§4.22.6 聚合链) |
| [29] ⚠ combatant 层 | **当前主将 getter** (两行属 CCombatant 主表 34 槽, 非 CCombat 26 槽/CLandCombat 27 槽) | 基类 = 返回 0 桩; 海军覆写 sub_14161E5C0 = admiral 数组取军衔最大 |
| [32] ⚠ combatant 层 | weighted_participants (情报权重) | 步进第 4 环 |

**CArmy::TakeDamage = 0x140C8F510**: 实扣 +1056 strength / +1064 organisation
(mod 660/661/662; war support 扣减)。伤害流水: 目标分配
(DAMAGE_SPLIT_ON_FIRST_TARGET + 「打弱」评分 = 硬攻×硬度×1.2 + 软攻×(1−硬度)×1.0
(权重 define; **目标装甲 > 攻方穿甲时评分 ×0.5 降权**); 低 org 优先) →
闪避 (sub_140BF9A70: **90/60 = 闪避率, 命中 10%/40%**;
真值由调用方钉死 `if(判定) 掷伤害骰`) → STR 骰 1+rand(2) / ORG 骰
1+rand(4) (装甲优势 2/6) → ×0.06/×0.053 × 穿甲偏转 (阈值表
PIERCING_THRESHOLDS{1,0.75,0.5,0} 出索引 → 乘数表 **PIERCING_THRESHOLD_DAMAGE_VALUES
{1,0.8,0.65,0.5}**; 装甲=0 除零守卫 ×1)。

**战术重掷核 (sub_1412BBF90)**: 每 TACTIC_SWAP_FREQUENCEY(12) 小时, 双方技能
最高领袖 skill 比较 + 侦察优方 +RECON_SKILL_IMPACT(5) 当量; 胜方加权
(INITIATIVE_PICK_COUNTER_ADVANTAGE_FACTOR 0.35×技能差) 掷反制战术; a1+208 =
当前战术相位; 战术六值聚合进 battle+160..+200。

**组织度分工**: 战时扣减唯一入口 = TakeDamage(+1064); 恢复
(RELIABILITY_ORG_REGAIN, sub_140C82C10) 与移动耗减在师域小时更新。

**伤害流水增补 (定案)**: STR/ORG 伤害修正真源 = LAND_COMBAT_STR/ORG_DAMAGE_MODIFIER 0.060/0.053; **穿甲双比值分工** (方向相反): 目标穿甲/射手装甲 → 骰面档 (装甲优势扩骰 STR 2/ORG 6); 射手穿甲/目标装甲 → 伤害乘数档 {1, 0.8, 0.65, 0.5} (穿甲不足减伤); **stats+664 = 装甲 (stat 63) / +672 = 穿甲 (stat 64) 定案** (乘数档守卫除数 = 目标装甲, 与 §4.18.10 情报估计互证)。闪避 = **unit+596 闪避配额计数器** (防御覆盖序号 vs 计数比较切换 90/60 档并 ++; 输入 = eff_def×(防 stat/10)/1e5)。新定案字段: CLandCombat c+64 战宽门 / c+152 边界战旗 (3 消费点) / CCombatant cb+220 敌空军旗 (陆海同槽) / CArmy 槽 46 = GetCombatWidth (Σ subunit def+88×营数) / 槽 39 = org 比 / 槽 34 = 强度比; 战术六值 c+168/+176 = combat_tactics.txt attacker/defender **伤害权** (加进骰基数: 强度比 + 该值); 战宽 getter = CLandCombat 槽 26 (0x1412ADE10, 地形×战术宽度+方向附加); 增援链 = 权重² 随机 + 接受率门 + 超宽踢尾 (COMBAT_OVER_WIDTH_PENALTY −1/% 钳 −0.33); 附带建筑损伤 sub_1412ABD80 (要塞 FORT 0.005/命中率 5% + 基建 0.0022 — ⚠ 两数值↔define 名对应待裁: LAND_COMBAT_COLLATERAL_FORT_FACTOR 驱动同省建筑条支 / LAND_COMBAT_COLLATERAL_INFRA_FACTOR 驱动州内省支, 数值缺省未对表; 暴击支 CRITICAL_BOMBARDMENT_DAMAGE 弹窗 ×40 巨伤 0.25%); debug 门 "Debug.OldCombat" byte_14332F64F / byte_143389FD4 控制台全跳伤害步。

**combatland.cpp 簇 (8 函数全读) 增补 (定案)**: **三联机制闭环** — **cb+8 = u64 每小时激活修正位图** (kind idx 0..29, 置位原语 sub_1413E1190) → 伤害步首调 sub_140CDA7E0 逐位折入 observer **lb+624 modifier_hours** 后复位 (combatlog.cpp:789 断言 !consolidated); CUnit+368 队列 + cb+8 位图 + modifier_hours 三账并行。
- **kind 索引表 0..29 全落** (值式要点): 0 指挥官技能/特质 (sub_1412B6C00 营权重×特质聚合, 州归属条件件 mods 175-180) / 2 包围 (ENCIRCLED_PENALTY−mod265, 守方∧州+210&1) / 3 经验 / 4 计划 (攻) / 5 stacking (COMBAT_STACKING_ 三 define, 交战省去重广度) / 6 超宽 / 7 挖掩 (守, ×边界战 dig_in_factor cb+1376) / 8 两栖登陆罚 (攻, 随进度衰减) / 9 要塞防御 (守∧Σ要塞>0, ×terrain_factor cb+1384) / 11 岸轰 (**推送值取负** = −clamp(cb+16, 0, SHORE_BOMBARDMENT_CAP); **cb+16 本身不封顶**, 写式 = Σ炮击单位值/(100×其参战炮击数)×(1+同省海战 mod358)) / 12 铁路炮 (−ATTACK_TO_BOMBARDMENT_MODIFIER_FACTOR × **最强敌铁路炮炮击值 (max, sub_1412AA870)** /100; 挖掩乘子 = 1−0.8×值/100, 要塞乘子 = 1−1.333×值/100 仅攻方) / 13 多线战斗 / 14 敌空优 / 15 空支 (AIR_SUPPORT_BASE×空支比) / 16 空降罚 / 17 补给缺乏 (缺额×COMBAT_SUPPLY_LACK_ 四 define) / 18 陆军情报 / 19 高层六源混流 (mods 427-430/574-579/346/553/348, 业务归并名待裁) / 20 州 tag 条件 (mod347) / 21 边界战 modifier (cb+1272) / 22 GIE 特质组 / 23 将军地形特质标记 (仅置位图不推队列) / 24 将领特质聚合 (州+1968 州单位表 64B/条, 特质旗位→mod id 映射表) / 27 每师 vtable[23]×terrain_factor / 28 天气 (mods 173/174/477) / 29 夜战 (昼光>0.8 才罚); kind 1/10/25/26+ 写点在簇外。
- **cb 新字段/写点**: +376 (实扣 STR 累加) / +384 (实扣 ORG 累加, 齐射命中后 +=, 业务名推定); +219 侧翼写点 = 去重省数 ≥ FLANKED_PROVINCES_COUNT; +220 = 敌 cb'+332≠0; +304 战术写点 = 加权抽中 → 库条, 落空 → CNullCombatTactic 兜底 + "Couldnt select a tactic in phase" (:3827); +344 = 师均×1e5 (Σ师 stats+544); 边界战三槽 **+1272/+1376/+1384 vtable[22] 运行时消费首次实证** (两类侧对象共用 vtable[22])。
- **两栖入侵基值**: accC/accD = lerp(AMPHIBIOUS_INVADE_{ATTACK,DEFEND}_LOW[+mod27]→HIGH, 进度 v), v = 修正和 + 1e5×移动进度/路径总长, clamp[0,1e5]; 消耗 = accA×accC / accB×accD。
- **战术权重三偏好 define 实名** (§4.22.12 增补): 国家偏好 = cc+5584 战术实例 (tactic+372 权重修正 id) ×(1+COUNTRY_PREFERRED_TACTIC_WEIGHT_FACTOR) / 军长 = 将+4272 vtable[10] ×(1+ARMY_GENERAL_…) / 军群长 = 军+440→军群将+4272 ×(1+FIELD_MARSHAL_…); 五门含国家解锁表 + tactic+224 条件触发器 (失败发 TACTIC_CONDITIONS_NOT_MET 中止)。
- **空支波次 define 实名**: 再武装窗 = 条+40 + 2×HOURS_DELAY_AFTER_EACH_COMBAT (书「2×4h 冷却」define 直证); 空支底数分母 = max(10, 1e5×LAND_AIR_COMBAT_MAX_PLANES_PER_ENEMY_WIDTH×own_width/1e5)。
- 簇清册: vtable[22] 修饰符全量重算 sub_1412AF7C0 (2249B, 无参战者断言 :1067) / 战术权重 sub_1412BC860 / vtable[19] 伤害步 sub_1412B82E0 / 指挥官聚合 sub_1412B6C00 (断言 :2141 营权重与特质表等长) / 齐射内层 sub_1412B3300 / 附带建筑 sub_1412ABD80 (暴击 RNG :3908, 常规 :3974, 州内要塞 :3996) / 战术掷骰 sub_1412BB330 / 增援拣选 sub_1412B3BB0 (权重² + rand%100<权重/1000)。

#### 4.22.9a CCombatManager 小时更新链 (五阶段)

CCombatManager (§4.22.1, gs+608) 每小时推进 (挂点 = HourlyUpdate 相位 12,
§4.2.6): 首小时初始化 → 活跃判定 → XP 收集结算 → 结束善后 + 战史滑窗。
行为槽语义与战术重掷核细节 = §4.22.9。

五阶段:

| 阶段 | 动作 |
|---|---|
| A | playthrough id 重同步 (gs+1312 优先, 非正取 +1316; 与 cm+32 缓存比, 经 gs+832 恒等表判等价 — 同原初国切换不清场); 非等价清战斗两侧指针 |
| B | 战史修剪 sub_140BB8910: CCombatHistory (cm+40) 尾部追加 = end_date 升序; **保留 168 小时 (7 天) 滑窗** + 回档守卫 (head.end_date > now 全弹) |
| C | 主循环 (置 cm+72 _bInCombatUpdate=1): 逐战斗跳过已结束 (+82) → 首小时初始化 ([13]) → 活跃判定 ([9]) → **[15] 每小时战斗步进** (步序见下) → 未结束/已结束分别记录 |
| D | XP 结算 sub_140BB6F60: leader 经验即时发放 (CUnitLeader::AddExperience: leader+3688 += xp, 超 `100000×单位阈值(+444)` 即升级) + **tbb 并行 ApplyCombatXpGains** (任务符号直读, EJobType 参与) + 收尾晋升扫描 (leader+3576/+3588 单位阈值 +2208) |
| E | 结束善后: 二次遍历, 已结束或 [16] 复核真 → **RemoveCombat** (swap-remove; combatmanager.cpp:1169/1173/1189 三断言) → [14] 通知两侧 → **CCombatHistory::Add** → **sub_140BB79A0 逐省善后 (省单位表去重遍历) → 逐单位 sub_140BB9220 重跑进省判定** (留省单位夺省/与省内在场者开新战 = 生命周期间歇闭环; 勘误定案: 本行旧记单函 sub_140BB9220 直带「同原初国战斗聚合/撤退判定/胜负置位」——胜负实际 = 槽[24] 终局结算内 consolidation 以两侧 lb+616 progress 高者置 win, sub_140BB9220 本体不含胜负置位; 省战斗数组 = prov+368/+380, 按槽[11] GetTypeId 过滤) |

槽[15] 主入口步序 (CLandCombat 0x1412B81D0; 定案): ① 按 define 周期调
**sub_1412BBF90 = 战术重掷核** (§4.22.9); ② `++(a1+68)` 时长计数; ③ 遍历两侧
参战国 tag 链表, 可战斗者 (sub_140CC6980) 调 **sub_1412BBDB0** = 聚合己侧全师
人力 (+976 求和) 与装备量 (师+840 池 category&4) max-写**战争统计对象**
+360/+364/+416 (状态位计数 = 修饰槽位图+多国旗, 仅玩家参战侧执行带 UI 通知);
④ 尾调基类 0x1413E28C0 = 对两侧 combatant 四连 (下表)。

四连流水 (基类槽[15] 尾; 各槽语义详见 §4.22.9 槽表):

| 步 | 槽 | 内容 |
|---|---|---|
| 1 | 槽[22] | 修饰符全量重算: stacking/over-width/补给/夜战/挖掩/岸轰/空优/情报/包围 (**PE 直接引用 34 distinct (40 次; 原「39」口径复核不上, 改 34)**) |
| 2 | 槽[19] → sub_1412B3300 | **伤害执行步** (目标分配 → 闪避 → STR/ORG 骰 → 穿甲偏转 → TakeDamage 全参数 = §4.22.9 [19]) |
| 3 | 槽[19] 尾 | **progress (lb+616) 推进**: vtable[12] (0x1412B5360) = Σ己侧全部师当前 org, 经 sub_140CDF0E0 每小时整量重写 → 结算 (sub_140CDB850) **高者判胜 = 剩余组织度比较** |
| 4 | 槽[14]+XP | 领袖 XP = 损失比因子 × 领袖均摊 (share = 0.5 + 0.5/N, 单领袖 ×1.0; 0.5 = CONSTANT_XP_RATIO_FOR_MULTIPLE_LEADERS_IN_SAME_COMBAT — 原「损失比×0.5」平乘式说废) + tbb 并行 ApplyCombatXpGains (阶段 D) (F1 验算) |

> 备注: RNG 保护 (random.h:74 主线程断言) 包裹结算段。
> 海战共用本五阶段骨架: CNavalCombat 主vtable槽[15] = sub_1415C3600 (海战每小时
> 步进主入口, 伤害五层/撤退/结束全链见 §4.22.10)。

#### 4.22.10 海战小时步进主循环

海战与陆战共用 CCombatManager sub_140BB8AE0 (§4.22.9a 五阶段), 逐战斗统一调
主vtable槽[15]; **CNavalCombat 槽[15] = sub_1415C3600 = 海战每小时步进主入口**
(无独立海战管理器)。坐标注: CCombat 层海战对象有 16B 前缀包装 e (数组元素
= malloc 基, 运行时槽 a1 = e; §4.22.5 表基 c = e+16); CNavalCombatant /
CFEXGroup / CFEXMember 无前缀 (定案)。

主入口五步: ① 天气刷新 sub_1415C5820 (c+152 天气现象 {2,3,4,5} / c+160 区条
修正 / c+168 昼昼 sub_140F19660); ② **CFEXGroup 对手组配对 sub_1415C55D0**
(strike 战斗 → 对方组聚合值最大者 (无果 RNG 兜底 combatnaval.cpp:157); 非
strike → 未配对活跃组中命中缓存相合度 sub_141C6C040 最优 → 双向写 group+32);
③ 未配对组同侧合并 sub_1415C52B0 (swap-remove + 成员转移 + 组析构); ④ 两侧
combatant 推进 sub_141620940 (主将 vtable[29] sub_14161E5C0 军衔最大 + cb+312 镜像;
cb+352 >0 → −= POSITIONING_PENALTY_HOURLY_DECAY_FOR_NEWLY_JOINED_SHIPS;
命中缓存重建 sub_141622360: 清 cb+744/cb+872 两桶 → 逐组逐 member (state==4
走桶 A, 其余桶 B) → cb+880..+992 统计快照 15 qword 搬入); ⑤ **基类四连
sub_1413E28C0** (两侧 cb vtable[22]→[19]→[14]→[32] — 四连是 **combatant 层vtable槽**,
§4.22.9 表内两曾混排的两层现分列)。

伤害结算五层 (定案): ① 槽[22] sub_14161E400 属性重算 (cb+344 positioning /
cb+328/336 screening / cb+368 anti_air = Σ船值×SHIP_TO_FLEET_ANTI_AIR_RATIO×
positioning/1e10); ② 槽[19] sub_14161F810 → 逐组 **sub_141C6B560** (清组统计
+160..+192 → 统计对方隐蔽单位五类分布 → **group+72 = 平均反潜探测×
NAVAL_COMBAT_SUB_DETECTION_FACTOR + group+80 air 反潜×NAVAL_COMBAT_AIR_SUB_
DETECTION_FACTOR** → forces_compare 重算 → 无效 member 清理 (推 group+112) →
air time_duration 递减 → 防守方无活跃战力 → 潜艇 member+300 =
SUBMARINE_REVEALED_TIMEOUT); ③ **CFEXMember 状态机 sub_141973470** (state 枚举
定案: **1=进场/待命, 2=交战, 4=撤退中, 8=撤离(escape_progress), 16=已撤出,
32=击沉**; 位掩码 &0xB=活跃, &0x38=撤离类); ④ 开火驱动 **sub_141973E20**
(cooldown[gun_idx] 充能 → 目标选择 sub_141971CC0 (对方组内加权随机, 潜艇按
TF 激进度与敌组分类计数选类别) → last_target 块写 (member+312 vtable/+320 有船/
+324 对方组数/+328 门) → 鱼雷揭示掷骰 → member+300 = SUBMARINE_HIDE_TIMEOUT);
⑤ 开火执行 **sub_1419740C0** (参数: a1 开火方 member / a2 目标 member /
a3 武器槽 **0=重炮 1=鱼雷 2=轻炮** (轻炮对潜艇目标切深弹模式) / a4 射击方
unit; 同武器充能够即连发, 每发耗 A90槽7 并掷 rand×100 开火门): 命中括号 =
攻击量 × ((mod439+1e5 − 0.5×(1e5−cb+344)/1e5) − mod440)/1e5 (位置罚项
Q=DAMAGE_PENALTY_ON_MINIMUM_POSITIONING 0.5; pos=0 → 括号减半, pos=1e5 →
罚零), 下钳 0 无上钳; 重击概率 = (mod396(目标) + mod442(射击方)+1e5 +
mod467(射击国)) × **暴击基数 (A90 槽1)**/1e5, rand < 阈值即暴击;
伤害波动 ×(1e5 + COMBAT_DAMAGE_RANDOMNESS×(rand−5000)/1e5)/1e5 (R=0.5 →
区间 **[×0.975, ×1.475) 非对称上偏**, 期望 ≈×1.225; 该 define 全引擎唯一
消费点, 陆战不用); 穿甲伤害乘子 ×A90槽6/1e5 (仅鱼雷穿透支路 =
1e5−(mod451+目标unit+608) 实际生效, 炮系与未穿支路恒 ×1e5 —
COMBAT_ARMOR_PIERCING_DAMAGE_REDUCTION=0 废档); **装甲的全部作用点 =
NAVY_PIERCING 双表** (sub_14196FD60: ratio = 1e5×穿甲/装甲 (装甲=0 → 1e7),
降序阈值 {2.00,1.00,0.75,0.50,0.10,0.00} 取首个 ≤ratio 档 → ×
DAMAGE_VALUES{1,1,0.7,0.4,0.3,0.1} 缩攻击量 / ×CRITICAL_VALUES{2.00,1.00,
0.75,0.50,0.10,0.00} 缩暴击基数); STR 伤害 ×COMBAT_DAMAGE_TO_STR_FACTOR
(0.6); ORG ×COMBAT_DAMAGE_TO_ORG_FACTOR(1.0) 再 ×(1e5−**血量比**)/1e5
(血量比 = 1e5×str/max(max_str,100), 船 +1784/+776, convoy +32/装备def+744 —
满血 ORG 伤害 0); 暴击部件概率 = 1e5×目标船+1384×CHANCE_TO_DAMAGE_PART_ON_
CRITICAL_HIT(0.1)/1e5 ÷ **可靠性 (船+808)** (可靠性≤0 ∨ 概率≥1e5 → 必损);
部件未损 → STR/ORG 双量 ×A90槽2 暴击乘子 (炮 1e5+COMBAT_CRITICAL_DAMAGE_
MULT(5.0)×(1e5−可靠性)/1e5, 鱼雷恒 2.0); member+292 critical_hits_received++
两路都计; 入账 sub_141620FA0; 伤害应用 船 sub_140C3E0E0 / convoy
sub_141AD8610; 实际伤害>0 → **SNavalHit 记录 sub_1415C6250** (按目标聚合
hit+56 +=, 新建 = malloc(0x50)+sub_1415C5DB0, 挂开火方 member+384) ∧
sub_14196FA40(目标, 射击国, id, 伤害) 伤害记账/经验链; 击沉判定 →
**sub_141975480** (尾部 `*(member+224) = 32` = state 32 击沉唯一写点)) (定案)。

伤害输入层 **sub_141970A90** 产 8 qword (调用方先 xorps 清零; 齐射层数值总线):

| 槽 | 语义 | 式/来源 |
|---|---|---|
| 0 | 攻击量 | 武器攻击值 (重炮 sub_140C3A580 / 鱼雷 sub_140C3AC00 / 轻炮 sub_140C3A5D0; 轻炮对潜艇 sub_140C3B220 深弹模式 = 传入基数×DEPTH_CHARGES_DAMAGE_MULT(0.7)/1e5, 基数≤0 直接返) × NAVY_PIERCING DAMAGE_VALUES 桶值/1e5 |
| 1 | 暴击基数 | 炮 = COMBAT_BASE_CRITICAL_CHANCE(0.05)×(1e5−目标可靠性)/1e5 × CRITICAL_VALUES 桶值/1e5; 鱼雷 = COMBAT_TORPEDO_CRITICAL_CHANCE(0.1)×(mod450+1e5+目标unit+616)/1e5 |
| 2 | 暴击伤害乘子 | 炮 = 1e5+COMBAT_CRITICAL_DAMAGE_MULT(5.0)×(1e5−目标可靠性)/1e5; 鱼雷 = COMBAT_TORPEDO_CRITICAL_DAMAGE_MULT(2.0) |
| 3 | 每发开火概率 (×100 量纲) | 100×COMBAT_BASE_HIT_CHANCE(0.1)×v19×clamp((目标剖面/GUN_HIT_PROFILES[武器])², 0, 1e5)×org/船员罚, floor = 5e4 (COMBAT_MIN_HIT_CHANCE 0.005); 掷骰 100×rand<槽3; v19 = mod40+1e5[+mod455 对国]+mod447/448/449 (按武器)+shooter 船槽值 (+592 重炮/+600 轻炮); GUN_HIT_PROFILES = {70 重炮, 100 鱼雷, 45 轻炮} (深弹模式覆盖 100 ∧ ×DEPTH_CHARGES_HIT_CHANCE_MULT(1.1)); 罚 = COMBAT_LOW_ORG_HIT_CHANCE_PENALTY(−0.5)×(1e5−org)/1e5 + COMBAT_LOW_MANPOWER_HIT_CHANCE_PENALTY(−0.25)×(1e5−船员比)/1e5 (船员比 = 1e5×船+2056/+2060 钳位[0,1e5]) |
| 4 | shooter 穿甲 | sub_140C3A570 |
| 5 | 目标装甲 | sub_140C3A520 (convoy = sub_141AD8080) |
| 6 | 穿甲伤害乘子 | 穿透 (穿甲==1e5 ∨ 装甲<穿甲) → 鱼雷 1e5−(mod451+目标unit+608), 炮/轻炮 1e5; 未穿 → clamp ≡ 1e5 |
| 7 | 充能需求 | sub_141972A70 (开火门/每发消耗) |

接战激活 sub_141971610 (海战开场逐级投入): duration > ALL_SHIPS_ACTIVATE_TIME
(8) → 1; 否则按船型类别与两侧空优效率 (修正 11) 对比 CARRIER_ONLY(0)/
CAPITAL_ONLY_COMBAT_ACTIVATE_TIME(6); 比较全严格 >; 两侧空优合计为 0 时
阈值改写 0/2。维修撤退 sub_1419717F0: TF 激进度 (TF+916, 0-5; {0,1}→LOW
(0.9) / 2→MEDIUM (0.6) / {3,4}→HIGH (0.4), 5 = 断言非法 (阈值保持 1e5 不退))
→ REPAIR_AND_RETURN_PRIO_{LOW,MEDIUM,HIGH}_COMBAT 阈值; 航母/主力 ×
CAPITAL_SHIP_COMBAT_RETREAT_MULT (0.5)。空战步 sub_141C6C580: air 条目分类收集 →
sub_14197B890 空战判定, 门 = c+272 air 旗 ∧ port_strike (高置信)。

撤退链 (定案): 玩家命令 CDisengageFromNavalCombatCommand::Execute
sub_141350F40 → **sub_141621730(cb,1)** (无组 → cb+320=1; 有组 → 逐 member
state 1/2→8、4→16); member 级自动脱离 sub_141971760; UI 撤离按钮 =
sub_141C6CEA0(group, id对); case 8 自动撤离: escape_progress += 逃速
(sub_14196FE80)/24 → ≥100000 → 16 + 航母 air 条目移除 + convoy 护航解除。

结束链 (定案): 槽[16] sub_1415C3690 (主循环阶段 E 二次遍历): **++duration
(e+68)** + progress 重算 (sub_14198A080 = 100000×攻方桶值/(攻+守), 双 0 → 50000; e+280 写入无条件,
strike 旗 (e+268) 只门结束判定) + 侧脱离判定 (无组 ∨ 全组无战力 ∨ 全组无对手) → 善后
sub_1416222E0 → 结束; 槽[14] sub_1415C4690 结束标记: convoy 残余
CONVOY_SINKING_SPILLOVER 沉没外溢 → **非 strike 胜负 = state 32 计数少者胜**
→ 逐 admiral sub_140C1E880(leader, win, cb) → 基类 → 槽[23] (§4.22.6 结果链)。
创建链: **sub_140BB99D0** (combatmanager.cpp:1049; 拦截判定: 双方 strike 目标
交集 RNG 重定向 sub_140D794E0) → malloc(296)+ctor sub_1415C2330 (e+0 vtable1
0x1429DDB08 / e+16 vtable2 0x1429DDBE0) → 槽[6] sub_1415C28F0 pair-init (两侧
malloc(1008) **CNavalCombatant sizeof 定案 0x3F0** + ctor sub_14161A4A0, 双指针
同源) → 槽[17] SetLocation (terrain = 战区天气区 sub_1415A5560(省+200+48)) →
槽[18] 省内其他 TF 卷入 (sub_14161AB40: positioning 初值 = MISSION_SPREADS
[qword_1433398C0][TF+884] + EFFICIENCY_TO_JOIN_COMBAT_RATIO_PENALTY×(1−效率))
(定案; C7/C8 尾部高置信)。

新字段: c+65/c+66 (e+81/+82) = 已初始化旗/结束旗; c+272 (e+288) = air 战斗
门旗; CNavalCombat 活体 sizeof e=296/c=280; CCombatant 基座+24 = 宿主战斗回指
(sub_1401F6EA0); CNavalCombatant+220 = 对方 air 旗; CFEXGroup +160..+184 =
敌方隐蔽单位分类计数 (AF10 类/+164 B210 类/+168 AF20∧¬B220/+172 B220 潜艇/
+176 invalid/+180 convoy/+184 B230 类) / +188 本组 air 计数 / +192 敌方可反潜
船计数; CFEXMember+300 = 潜艇隐蔽/暴露状态 (HIDE/REVEALED_TIMEOUT, 递减写者
= sub_141973470 状态机步) / +312..+328 last_target 块运行时写者 sub_141973E20 / +168 sprite
(击沉时写船名/"convoy")。SNavalHit 运行时记录器 sub_1415C6250 / SAirHit
sub_1415C60E0 (定案)。

#### 4.22.11 边界战执行链 (CLandBorderWarCombat)

**主轴 (定案)**: 边界战完全复用 §4.22.9a CCombatManager 五阶段骨架 —
CLandBorderWarCombat (vtable 0x1429BC5F0, 27 槽 — slot[27] 位 = vtC COL 前哨) 只覆写少量虚槽; **槽[15]
sub_1413ED810 = 前置三态状态机后直接调 CLandCombat 步进主入口
sub_1412B81D0** (复用陆战链)。槽契约: [9] IsActive sub_1413EE680 / [11]
GetTypeId (token **14757 border_war_combat**, 枚举 1, find_by_states 过滤) /
[12] 时长门 (≥ COMBAT_MINIMUM_TIME dword_1433349A4) / [13] 首小时初始化
sub_1413EF0F0 / [14] 终局结算 sub_1413EE780 / [15] 每小时步进 / [16] 结束
复核 (共享 CLandCombat: 任一侧槽[20] 真 → 槽[24] 胜负执行) / [25] 现算进度
(clamp(100000×A/(A+B)); A+B≤0 → 50000) / [26] GetWidth (c+200 combat_width
× (c+144+1e5)/1e5)。

推进状态机 (槽[15] 前置, 定案): **c+208 state 0(待就位)→1(单侧就位, 记日期
c+220)→2(双侧就位, 记 c+216 = start, 进入交战)**; 就位门 = 侧单位容器计数
(side+32 data, +12 计数)。

IsActive (槽[9]) 结束条件: ① **sub_140700570 真 = 双方已互相宣战 (关系行
+744 存在 CWarRelation ∧ +73==0) → 移除 (升级为全面战争)**; ② 同国/战争对象
失效∧(关系+672 ∥ 同阵营 ∥ 特殊关系) → 移除; ③ state<2 → 活跃; ④ state==2 →
双方单位计数均非 0。

判负 (侧槽[20] sub_1413EFBF0, 定案): ① 编制组 (cb+1256) 无效; ② 州控制权
链丢失 (state+204/+200/省+392 任一 ≠ 我方); ③ 状态机 1 超
BORDER_WAR_WIN_DAYS_AGAINST_EMPTY_OPPONENTS 天无单位; ④ 状态机 2 无单位;
⑤ 打满 minimum_duration_in_days 后 Σ战力 <1000 ∨ 槽[25] 判定。

终局结算 (槽[14], borderwarcombat.cpp:605/616, 定案): 按 **c+225 attacker 胜
/ c+226 defender 胜 / c+228 cancel** 三旗或槽[20] 现算分流 (结算体直读: e+241/+242/+244 = c+225/+226/+228; **c+227 结算未读**, 原记 c+227 cancel 系差 1 字节, c+227 语义待裁) → 胜方对家 on_win
+ 败方 on_lose (cb+1280/+1312; cancel → 双方 on_cancel cb+1344; 经
sub_140A0F4F0 真发射) → **change_state_after_war (c+224 = 工厂 e+240, 坐标系消解定案) 真则败方州
sub_1409DE560 + sub_1409DDA40 + sub_1409DFC20 三连**; **新: 转移后败方 owned_states (cc+1156) ≤ 0 → sub_1406D3F00 (CCountry::Annex) 胜方吞并败方**; 汇合善后 = 双方编制组 +432 战斗回指
清零 + sub_1409DD080 清州挂载 + 非战态双向 AI 意愿清除 (sub_140D42D70)。

每日 on_border_war_lost (§4.2.7 序13 补全, 定案): 扫 **cc+1120/cc+1132 国家
边界战州数组**, 门 = state+2149 活跃 ∧ sub_1409D5BA0 进度 >
NMilitary::BORDER_WAR_VICTORY (qword_1433327B8); **进度 = 州内参战单位
BORDER_WAR_POWER (单位虚槽[30]) 按归属国分桶占比**。损耗不在步进内算:
start_border_war 时给编制组挂 **BORDER_WAR_ATTRITION modifier** (量 =
BORDER_WAR_ATTRITION_FACTOR × 进度/1e5); 受伤单位经侧槽[16] 进
removed_unit 暂离 (HOURS_REQ_REJOIN_BORDER_WAR_FOR_INJURED_UNITS 倒计时,
槽[19] 消费回归)。

创建链: CStartBorderWarEffect::Execute → 工厂 sub_140BB6B70 (malloc 248 +
ctor + 挂 gs+616 + 侧装配 1416B×2 + 省登记 province+368 在场战斗数组 (sub_140E797F0 add-unique)。干预面
(Execute = vtable[13] 直证): start / set_border_war (置 state+2149 旗
sub_14030F980) / set_border_war_data (14741) / finalize_border_war (置胜旗 +
**silent c+228** — 结算活证: c+228 门 = 不发任何 on_action, 即 silent 语义本体; minimum_duration_in_days 系工厂 e+228 = c+212, 与本旗无关) /
cancel_border_war (置 c+227 — 该字节结算未读, 与 c+228 cancel 门差 1 字节待裁) (定案)。

#### 4.22.12 陆战战术选择流

**触发** (定案): CLandCombat::[15]（sub_1412B81D0）首段 — 任一侧无战术 ∨
`时长 % TACTIC_SWAP_FREQUENCEY(12h)` → 重掷核 **sub_1412BBF90**。

**主动权** (定案): 双方 vtable[29] 最高技能将领比大小，侦察大者（侧内逐军师统计
对象+208 取 max）+ RECON_SKILL_IMPACT(5) 技能当量; **主动权合计严格大者后掷并反制
败方新战术**，反制乘子 = 1 + INITIATIVE_PICK_COUNTER_ADVANTAGE_
FACTOR(0.35)×技能差; **平局 = 攻方先掷且双方均无反制乘子** (dump 直读); counter
目标 = 战术 **+144（单值 id，非位图**; 由 countered_by 串加载后解析）。

**RNG 消费定案**: 每次重掷消费 **2 次全局流** — 相位种子 (combatland.cpp:3420) +
加权选择 (:3803); 重掷核尾部把后掷方战术相位写入 battle+208 (前掷方相位被覆盖,
"no" 相位不写)。

**权重五门三偏好** (sub_1412BC860, 定案): active 旗 ∨ 国家解锁表（gs+1024
注册表对象 +40 名哈希数组）→ 槽[10] → +224 条件触发器（失败静默零权，仅
tooltip 发 TACTIC_CONDITIONS_NOT_MET）→ 未解锁权重 0; 偏好乘子 = 国家
cc+5584 / 主将 leader+4272 / 编制内领袖。

**相位定案**: battle+208 = 当选战术 +360（`phase` 名查 db+40 相位表，"no"=−2,
相位表由 combat_tactics 特殊键 **"phases"** 构建）; **相位不门控选择**，只供
GUI/文案。六值聚合: counter 关系成立则对方六值整侧归零（sub_1412AE250 +
sub_1406C01B0）。CCombatTactic 六值 +312..+352 定名（combat_width/attacker/
defender/attacker_movement_speed/双方 org damage modifier）（定案）。

#### 4.22.13 战斗创建家族与 RemoveCombat (combatmanager.cpp; 8 函闭环 — 5 新 + 3 精化)

簇清册 (体内 cpp 锚 8/8; 伴生直证 sub_1412AA360 = CLandCombat ctor, 216B: vtable@+0 与 +16 双 COL, +152 字节 0, +160..+207 清零, +208 = −1):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_140BB99D0 | 264 | Random :1278/:1292 + 断言 | 海战创建主链 (双方 TF; strike 交集 RNG 重定向) | 已收 §4.22.10, 本批精化 |
| sub_140BBA1B0 | 168 | 断言 :1169/:1173/:1189 | **CCombatManager::RemoveCombat** | 新 |
| sub_140BB7D50 | 147 | :1049 | 类型分发战斗工厂 (1 = 陆 / 2 = 海) + 管理器注册 | 新 |
| sub_140BB8180 | 116 | 断言 :976 | 空袭运输船即时海战 (栈上 CNavalCombat 一回合结算) | 新 |
| sub_140BBAC40 | 95 | 断言 :584 | 单位入境 → 加入既有战斗或建新战斗 | 新 |
| sub_140BB7660 | 78 | :1049 | 海战创建·无守方版 (RNG 重定向 + +277 = 1) | 新 |
| sub_140BB77E0 | 70 | :1049 | 海战创建·双侧版 (尾段 = 对方侧 combatant 添加) | 已收 (s4_14 建+插入), 本批精化尾段语义 |
| sub_140BB6B70 | 62 | :1152 | 边界战工厂 (CLandBorderWarCombat 248B) | 已收 §4.22.11, 本批互证 + 尾段三写新证 (见该节 ⚠ 表注) |

**CCombatManager 管理器面** (sub_140BBA1B0 定案): +8 指针向量 {d, count@+20} = 活跃战斗表 (swap-remove); +40 容器 = 第二登记 (RemoveCombat 内 sub_140BB6D00 摘除); +72 uint8 = 更新中旗。

**RemoveCombat 流程** (sub_140BBA1B0): 重入门 byte_14333C882 断言 :1169 → 更新中旗断言 :1173 + CLogStream 附**栈踪** ("…\nStack trace:\n" + sub_1422DF7E0) 拒删返 0 → 线性扫 +8 向量把所有 ==combat 槽 swap-remove → 计数减少才继续: combat+12 旗 → sub_1402A00F0(qword_14332F698, combat) 摘第二注册 → **vtable+112 (槽[14]) 终局结算** → **vtable+56 (槽[7])** → sub_140BB6D00(mgr+40) → vtable[0](combat, 1) 释放 → 清门返 1; 计数未减 → 断言 :1189 返 0。调用面 5 处 = 通用摘除 API。

战斗创建家族五件分工:

| 函数 | 类型 | 产物 | 守方 | 特化段 |
|---|---|---|---|---|
| sub_140BB7D50 | a3 = 1 / 2 | malloc 216 + sub_1412AA360 CLandCombat / malloc 296 + sub_1415C2330 CNavalCombat | a4/a5 双侧 (sub_1413E0AA0/E10, 100000) | type1 走 gamestate 断言组 + sub_1401E4470; :1049 profiler 标记 |
| sub_140BB7660 | 海 | CNavalCombat | **无守方** (E10(combat, 0, 100000)) | 头部 sub_140D794E0 RNG 重定向; 尾 sub_1415C3730 任务配置 + **combat+277 = 1**; 唯一调用方 sub_140FAACD0 |
| sub_140BB77E0 | 海 | CNavalCombat | a4/a5 = 舰船引用+数 | 头部 RNG 重定向; 尾 sub_1415C3DE0 (combatnaval.cpp:669, 对方侧 combatant 对 {ref, id} 入 combat+240 向量 {d@+240, cap@+248, count@+252, alloc@+256}) |
| sub_140BB99D0 | 海 | CNavalCombat | a3 TF | 双方 strike 任务 (+864 门 +912 旗) → 目标表交集 (sub_140CDCC80, 栈缓冲) → Random :1278 选目标省 → 其单位过滤 (单位+184 解引用 +210 字节 &3 == 0) → Random :1292 选省 → 双方 sub_140D794E0 重定向; a3 已在战斗支路 = 直调其战斗 vtable+144 (槽[18]) 加入; 海区异同门 = TF 位置 +164 比对 |
| sub_140BB8180 | 即时 | **栈上** CNavalCombat | a5 运输船侧 (sub_1415C3DE0) | 空袭方 a2 机翼对 a5 运输: 断言 :976 "We are attacking our own convoys!" (tag 相同或同阵营); vtable+240 (槽[30]) 判定 → sub_1415C3600 步进 → sub_140BB6F60 → 槽[16] sub_1415C3690 + 槽[14] sub_1415C4690 → sub_1415C24A0 析构返结果; 调用方 sub_140F82CA0 |

公共骨架 (7D50/7660/77E0/99D0 一致, 99D0 已收互证全符): 管理器 +8 向量线性查重 (命中记 index 否则 push) → vtable+48 (槽[6], index, count) → vtable+136 (槽[17] SetLocation) → sub_1413E0AA0/E10 双侧 → 省 (+224 单位表/+236 计数) 逐单位排除双方后 vtable+144 (槽[18]) 卷入 → sub_140E797F0(省, combat) 省战斗数组 add-unique (✓ s4_14 prov+368)。

**入境加战 sub_140BBAC40** (:584): 门 sub_140C00520 → 逐省单位找对手 (can-join sub_140C01660; 军 lead vetting sub_140C891E0/sub_1412BB000) → 省战斗数组 (+368/+380) 按 vtable+88 (槽[11] GetTypeId) 过滤后 vtable+144 加入 → 未加入则 **sub_140BB7D50(mgr, 省, 单位类型+1, …)** (单位类型 0 陆 → type1 / 1 海 → type2; 海军到此处 = :584 断言 "DONT CALL THIS FOR NAVIES… /Dan" 后仍落工厂)。唯一调用方 = sub_140BB9220 (combatmanager 域内)。

已收三函精化: ① sub_140BB99D0 补 Random :1278/:1292 两随机锚与单位过滤; ② sub_140BB77E0 尾段 = 对方侧 combatant 添加 (非泛用注册); ③ sub_140BB6B70 profiler 标记 :1152 + SetLocation 目标 = *(*(a3+16)) 两级解引用 + 尾段三写 (+216 = a4 start 脚本值 / +228 = a6 
 minimum_duration_in_days / +240 = a5 change_state_after_war — 实参语义经 s4_32 调用式 define 键对照; 与 §4.22.11 writer 表 +212/+224 成对冲突, ⚠ 待裁见该节表注)。

未决: 即时海战返值语义 (sub_1415C24A0 析构返值) / sub_140BB6F60 中段语义 / CLandCombat 全字段表 (ctor 可见段之外) / 边界战 +228/+240 vs writer 表冲突的活体探针终审。

#### 4.22.14 护航入战双变体与海战辅助 (combatnaval.cpp; 6 函闭环 — 3730/3DE0 全拆 / SetLocation 实现体 / 敌对侧判定)

> 坐标约定: 本簇 a1 = e (malloc 基), c = e−16 (§4.22.5/§4.22.10 基制, 四函独立互证 — §4.22.11 冲突消解同款)。

簇清册:

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_1415C26D0 | 65 | :1183 断言 "No countries in the combat :(" | 敌对侧属国判定 helper | 新 |
| sub_1415C4BA0 | 47 | :1031/:1034 断言 | 槽[17] SetLocation 实现体 | 创建链点名 → 本批实现体 |
| sub_1415C4C90 | 151 | refid :996 | 槽[23] 海战结果生成 | 已收, 本批互证 (:973 malloc / :996 绑定注册互补) |
| sub_1415C55D0 | 136 | :157 RNG 兜底 | CFEXGroup 对手组配对 | 已收, 细节补全 (相合度成本 = 100000−v 取最小; strike 路 = 聚合 out[0]+out[2] 取最大) |
| sub_1415C3730 | 348 | :632/:656 + :637 断言 "You are adding twice a convoy to the same combat!… - bcareil" | 被袭护航群入战装配 (全入守方) | §4.22.13 一句 → 本批全定性 |
| sub_1415C3DE0 | 305 | :669/:674/:694 | 参战侧归属版护航入战 | 同上 |

**双变体全拆** (3730 / 3DE0 同构四差异):

| 项 | 3730 (被袭群, 全入守方) | 3DE0 (参战侧归属) |
|---|---|---|
| 防重容器 | c+200 client {d@e+216, cap, c@e+228} | c+224 naval_transport {d@e+240..alloc@e+256} |
| a2 tag 位 | +24 | +88 |
| 侧归属 | **无条件挂守方** (e+160 = c+144 defender) | **攻方 cb+56 参战国节点链** (节点 {tag@+0, next@+16}; 链上命中 ∨ 同原初国 sub_140BB52F0) → 攻方, 否则守方 |
| convoy 条目 ctor | sub_141AD7C30 (条目, a2+8 解析, 群内序号, 群 id) | sub_141AD7D10 |

公共: a2+16 未置 → refid 绑定 (a2 本身是注册实体); 防重门命中 → 断言 (3730 :637 闩 byte_14338A996 / 3DE0 :674 闩 byte_14338A997); 战斗 holder (c+8) 反向写入 a2+88 容器 (载荷→战斗双向登记); a2 tag → 国 → **cc+4608 经 sub_1410219F0 取 16B 群表 {qword 群 id, fixed×1e-5 数量}** → **数量定点除 1e5 (魔数 0x29F16B11C6D1E109 >> 78)** → 逐条 malloc 72 入 c+176 convoy 容器。调用方 = sub_140BB7660 (3730; 尾写 e+277 = c+261 convoy_combat = 1) / sub_140BB77E0 (3DE0; 书「combat+240 向量」系 e 坐标, 与 c+224 同物互证)。

**敌对侧判定** (sub_1415C26D0): e+40/+48 = c+24/+32 双参战方; cb+72 门 + cb+56 tag; a2 idpair → sub_140BB5490 归一 → sub_140700570 敌对判定 → 敌对侧经 sub_1413E11B0 产属国 idpair; 双侧无国 → :1183 断言。语义 = 「给一个国家, 找出交战双方中与其敌对的参战国」(4 调用点)。

**SetLocation 实现体** (sub_1415C4BA0): :1031 断言 → e+56 = c+40 location ← 省; :1034 断言 → e+72 = c+56 terrain 串 ← sub_1415A5560(省+200+48) (书创建链 terrain 语句的实现体, 行号新证 :1031/:1034)。

未决: cb+56 参战国链名义 (CCombatant 基座区 +45..+231 未具名段) / 护航载荷载体类型名 / cc+4608 群表语义。

#### 4.22.15 CCombatant 增删员对与 Join 判定 (combat.cpp; 4 函新 + 包装对精化 — 基座布局大增补)

簇清册 (体内 cpp 锚 6/6):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_1413E12F0 | 133 | :208 日志 "Add unit to combat" | **CCombatant::AddUnit 基类实现** (主表槽[15] = vtable+120 推定) | 新 |
| sub_1413E3660 | 175 | :238 日志 "Remove unit from combat" | **CCombatant::RemoveUnit** (含国家战斗统计五连) | 新 |
| sub_1413E1B20 | 46 | :324 断言 `false && "no location should lack terrain"` (B52) | 地形值 getter (五参) | 新 |
| sub_1413E3D90 | 69 | :1001 日志 "Join: %s,%s" | **CCombat::TryJoinUnit** (敌对测试分流双侧) | 新 |
| sub_1413E0AA0 / sub_1413E0E10 | 163/165 | :1103/:1104 与 :1119/:1120 断言 | AddAttackerUnit / AddDefenderUnit 包装 | 已收, 本批精化 (E10 首行判空 = 守方可空; AA0 返 unit vtable[44] 结果 E10 丢弃) |

**CCombatant 基座布局增补** (cb; 书 §4.22.5 既有名外新增):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +32 | 引擎向量 | 本侧单位指针表 {d@+32, alloc@+48, count@+44} (12F0 push ×1.5 / 3660 压缩) |
| +56 | 32B 节点双链表 {head@+56, tail@+64, count@+72} | **参与国表** (节点 {tag u32@0, prev@8, next@16, byte@24}; 11B0 登记/3660 释放重建) |
| +80 | 32B 节点双链表 {head@+80, tail@+88, count@+96} | **异国表** (owner ≠ controller 且非同国别名时入列; 11B0 条件分支) |
| +104 | 集合 | 参与 controller tag 集 |
| **+218** | uint8 | **涉及玩家国旗** (sub_1413E3F00 遍历 +56 链命中 gs+1312/1316 玩家 union → 置 1; 增删员尾调刷新, 入口清 0) |
| **+224** | u32 | 写点定案 = 侧单位表清空时存撤出单位 logical_country (业务名待裁 — §4.22.5 行已补注) |

**combat 侧**: +40/+48 = 攻/守 cb 双证 / +68 = 时长小时数 (RemoveUnit 取 /24 喂国家统计) / +72 = 地形描述符。

**AddUnit 流程** (sub_1413E12F0): 单位入 +32 向量 → 日志 (名 = 引号 tag 串, %i = 省 id) → **sub_1413E11B0 参与登记** (controller 头插 +56 链 + 入 +104 集; 二 tag 相异且非别名同国 → owner 头插 +80 链) → 非军队单位 (unit+8 == 0) 且 gs+2613 == 0 → **RH 表 +128 插入 {键 = 别名归一 tag}, 桶权重 += 100000 × 人力 (unit 虚槽[7] 对象 +976, §4.18 解散分摊同源)** → 刷 +218。

**RemoveUnit 流程** (sub_1413E3660): 敌对复查 v2 (链查 controller tag) → +32 压缩摘除 → **表空则 cb+224 = unit+480** → 释放两链按剩余单位重建 → v2 ∧ 可战斗 ∧ controller 已离 ∧ 非军队: **国家战斗统计五连** (战斗+68/24 天数 → 对象 +356 容器累加; 攻侧 ++ +532 / 守侧 ++ +536; cb+8 bit2 包围 → ++ +80; bit15 敌空优 → ++ +84 — 全 _InterlockedIncrement)。调用方 = combatland 域 / 海军 combatant 摘除。

**TryJoinUnit** (sub_1413E3D90): 先 unit+424 进行中战斗向量线性查重 (命中返 0) → 双侧 cb **虚槽[21] (vtable+168) 敌对测试** → 恰一边为真才加入 (v12∧¬v11 → 攻侧 AA0; 反之 E10); test_only 只判不加; 返 1 = 属一侧。


**combatlog.cpp 50-99 行簇增补**: **gCombatData 全局实名与静态布局** (断言 "gCombatData._Refs[ n ] > 0 && gCombatData._Used[ n ]" combatlog.cpp:129 直证): _Refs = qword_14333CB88 (u16/槽) / _Used = qword_14333CBA0 (u8/槽) / 在用槽计数 = dword_14333CBB8 / 释放侧 CAS 自旋锁 = dword_14333CBBC; 释放原语 = 0x140CDFEE0 (自旋 + RAII 解锁渲染)。**装备损失写原语对**: 带数量 = 0x140CDA010 (恒写总池 a1+112, reason 0..3 桶 a1+176/+240/+304/+368, sub_14100CCE0; reason≥4 "This should never happen" :725) / **无数量变体 = 0x140CDA160** (sub_14100CAE0 两参, :701 同断言) — 与书池表读数差恒 88 = 表基 S = 写原语 a1+88 (观察者内嵌子对象一层, 非冲突); 前置断言统一 = `*(observer+744) & 4` (_bFinalized 旗, :684/:708/:789 三站独立闩)。**修正位图折入 0x140CDA7E0** 复核一致 (bit0..29 → +624..+740 三十槽)。**装备伤害 idpair 分摊 0x140CD9BF0** (结构定案/业务名推定): 成员对象 {16B idpair 键表@+40 {key0,key1,i64 量}, 累计器@+64, 来源国 stamp@+132}; 份额 = 100000×量/总量 (溢出钳 0xFFFFFFFF), :1178 断言。


**combatmanager.cpp 三创建函数同形骨架 (模式注, 互证补强)**: malloc → ctor (海战 sub_1415C2330 296B / 边界战 sub_1413EB800 248B) → refid 绑定 (sub_14221F390 + sub_14221E700(obj+16)) → profiler 标记 (:1049/:1152) → 活跃战斗表 (+8 d/+20 count) 线性查重登记 → vtable+48 槽[6] 设注册位 → vtable+136 **槽[17] 设 holder 引用 (三函共用; 海战传 a3, 边界战传 *(a3+16))** → init → vtable+144 槽[18] combatant 入战 → sub_140E797F0 反向登记 → 尾配置 (海战单侧版 0x140BB7660 **+277=1 = convoy_combat**; 双侧版 0x140BB77E0 无 +277, 尾段 sub_1415C3DE0; 边界战 0x140BB6B70 尾三写 +216/+228/+240)。入境加战 0x140BBAC40 补证: :584 断言前有**仅陆军 (type==0) 的单位自身 lead vetting 块** (sub_140C891E0 不过 → return 0, 对手侧之外); vtable+144 加入第 3 实参 = 1。

#### 4.22.16 NumCombatsBombarding 结构细化与参战 tag 链谓词 (1 函 = 0x1412AD270 复核 + 新谓词 sub_1412B2B40, 定案)

0x1412AD270 (CTaskForce\* a1) = **NumCombatsBombarding** (df111 定名复核通过; 分母消费 = §4.22:1054 kind 11 ÷ 其参战炮击数): 双源收集 — 源 A = TF+884 == 9 (岸轰任务) ∧ TF+960 非零 → 任务对象 +200 96B 元数组 (计数+212) → 条目 +40 8B 指针数组 (计数+52) → 元素 +0/+368 指针数组 (计数+380); 源 B = TF+496 (省) → +184 → **+124 计数** (sub_140E7F530) / 元素 sub_140E7F3F0。过滤 = 元素 vt+88 (槽 11) 判别真才收 (推定战斗/可炮击对象); 跨源指针查重去重 (×1.5 扩容, off_143085170 分配器)。**计数谓词 sub_1412B2B40 (国, 元素) 新定案**: 元素 +48 容器 (先) 与 +40 容器 (兜底) 各 **+56 = tag 链表头**, 节点 {i32 tag@+0, next@+16}; 逐 tag 非零 → sub_140BB5490 索引 + **sub_140700570(国, &tag)** (交战/敌对判定, §4.22:1228 同款) 真 → 返 1 — 即 +40/+48 = 战斗两侧参战方容器 (推定攻/守), +56 = 各自 tag 链表头。返回 = TF 轰击目标集合中「TF 所属国 (TF+472 tag → sub_140BB48F0) 参战」的去重战斗数, 与 kind 11 分母语义闭环。

#### 4.22.17 CLandCombatant::[22] 每小时修饰符重算全量定案 (combatland.cpp; 1 函 = 0x1412AF7C0, 定案)

身份表:

| 项 | 值 |
|---|---|
| 身份 | CLandCombatant vtable[22] (vtable 偏移 +176); CLandBorderWarCombatant 共用同实现 |
| 源码位 | combatland.cpp:1067 (断言 "No participants"); 另 :1228 (NumCombatsBombarding > 0) |
| 签名 | (CLandCombatant* a1 = 本侧 cb, CLandCombatant* a2 = 敌方 cb′) |
| 返回值 | cb+344 归一化 = **师均防空 (fixed×1e-5)**; 无单位返 cb+44 原始计数 |
| 调用时机 | 每小时 (CCombatManager HourlyUpdate → CLandCombat 槽[15] 步序, 两侧 cb 各调一次); 读档/新局首小时亦调 |
| 顶层门 | cb+72 参战 tag 链计数 == 0 → 断言返回 |
| 有效逻辑 | 2249 行中约 1300 行为析构/清理样板 |

CLandCombatant 本函读写字段 (cb 相对):

| 偏移 | 类型 | 语义 | 本函行为 |
|---|---|---|---|
| +8 | uint32 位图 | 每小时修正位图 (kind 0..29) | 首调 sub_1413E1AB0 清 0; 逐 kind 置位 sub_1413E1190 |
| +16 | int64 fixed×1e-5 | 岸轰总值 | 写; **不封顶** |
| +24 | CCombat* | 宿主战斗回指 (sub_1401F6EA0 = *(cb+24)) | 读 |
| +32 | CUnit** | 本侧全单位容器 (count@+44, 含预备队) | 主循环遍历 |
| +56 | 侵入链表 | 参战 tag 链表 A {head@56, tail@64, count@72} | 读 (己方 tag 集) |
| +216 | uint8 | is_attacker | 读 = 全函数攻守分流开关 |
| +232 | CUnit** | front 列表 (count@+244) | 读 = 战宽求和 / 叠层计数 |
| +320 | 结构数组 | 己方空军出动条目 {amount i32@+20, damage_factor i64@+24} (count@+332) | 读 = 空支底数 |
| +344 | int64 fixed×1e-5 | 师均防空 | 写 (前置 0 → 累加 Σ师 stats+544 → 尾段 1e5×Σ/(1e5×unit_count) 归一化) |
| +1272 | int64 fixed×1e-5 | 边界战 modifier | 读 (仅 combat+152) → kind 21 |
| +1376 | int64 fixed×1e-5 | 边界战 dig_in_factor | 读 (仅边界战) → kind 7 乘子 |
| +1384 | int64 fixed×1e-5 | 边界战 terrain_factor | 读 → kind 7/9/27 乘子; 非边界战 = 100000 |

> +1272/+1376/+1384 = vt[22] 运行时消费首次实证 (与 §4.22.4 CLandBorderWarCombatant writer 字段互证); 语义链 = combat+152 旗 → cb+1272 (modifier) / cb+1376 (dig_in) / cb+1384 (terrain_factor)。

六步流程:

| 步 | 动作 |
|---|---|
| 0 | 无参战者门 + 基类重置 (cb+8 清 0; 逐师 unit+596 闪避配额清 0) |
| 1 | 两栖基值整写: 过滤两栖入侵中 (sub_140C00350); prep = clamp[0,1e5](mod140 + 陆军师将军库 mod140 + mod454(键 prov+392 tag) + 1e5×移动进度/路径总长); accC(unit+408) = lerp(AMPHIBIOUS_INVADE_ATTACK_LOW, HIGH, prep); accD(unit+416) = lerp(DEFEND_LOW+mod27, HIGH, prep) — **直写非队列** (确认 §4.18.5) |
| 2 | 岸轰 → cb+16: 邻接海洋省舰队扫描 (def+210&3==0 海洋门) + war_relation 战略区单位两路; 每 TF v = 1e5×岸攻合计/(1e5×max(1, NumCombatsBombarding)); cb+16 = Σv/100 ×(1+敌将 mod358); kind 11 推送值 = −clamp(cb+16, 0, SHORE_BOMBARDMENT_CAP) |
| 3 | 循环前全局量: (a) 叠层惩罚 kind 5 = clamp(COMBAT_STACKING_PENALTY×超出数, −99000, 0), 超出数 = front 计数 − COMBAT_STACKING_EXTRA×max(0, 交战省去重数−1) − COMBAT_STACKING_START; (b) 空支底数 kind 15 = AIR_SUPPORT_BASE × min(1, Σ出动/(max(10, 3×敌战宽))); (c) 超宽惩罚 kind 6 = COMBAT_OVER_WIDTH_PENALTY×超出比; (d) 边界战分流 (combat+152 → cb+1272/cb+1384, 否则 0/100000); (e) 铁路炮三折算 (下表) |
| 4 | 逐师主循环: 将领五库标量 (库 +624/+4024/+4064/+4104/+4144) → cb+344 防空累加 → 攻方调 sub_1412AEFC0 (内推 kind 8 两栖罚 / kind 16 空降罚) → 逐 kind 推入 → 尾钳 A/B ≥ 1000 (加法模式) |
| 5 | 补给缺乏 kind 17 (见公式表); 循环尾守方上报 AI 意图 (省在场单位计数); cb+344 归一化 |

铁路炮三折算 (门 = 铁路炮特性门 sub_1401AEB50(35); 输入 = sub_1412AA870 取**覆盖本省的最强敌铁路炮炮击值 max**):

| 输出 | 公式 |
|---|---|
| kind 12 值 | −ATTACK_TO_BOMBARDMENT_MODIFIER_FACTOR × attack / 100 |
| 挖掩乘子 (kind 7) | 1 + (−ATTACK_TO_ENTRENCHMENT_MODIFIER_FACTOR × attack / 100)/1e5 |
| 要塞乘子 (仅攻方, 入 sub_1412AEFC0) | 1 + (−ATTACK_TO_FORTS_MODIFIER_FACTOR × attack / 100)/1e5 |

> ⚠ sub_1412AA870 非「空优比」: 体读 = 遍历 war_relation (14346) 取对方国单位表中射程覆盖本省 (sub_140E8BF00) 的铁路炮, sub_140E88880 取炮击值, **保留最大值**并 sub_140E883C0 标记参战。

补给缺乏 (kind 17) 完整公式:

| 项 | 公式 |
|---|---|
| 门 | 有效补给比 < 100000 ∧ unit+1192 (空降倒计时) ≤ 0 |
| lack | 100000 − 有效补给比 |
| 州因子 | v186 = mod603 (LOCAL_SUPPLY_IMPACT); 师国非州核心 → += mod604 |
| 国因子 | v185 = 100000; 师国 ∈ 州核心 tag 列表 → = mod595 (SUPPLY_PENALTY_ON_CORE) + 100000 |
| 推送 | kind17 = side_define (COMBAT_SUPPLY_LACK_{ATTACKER,DEFENDER}_{ATTACK,DEFEND}) × lack × (v186 + v185) / 1e10, atk/def 各一 |

> ⚠ mod595 以 **+100000 基线**进入 (即 (1+mod595) 乘子式), mod603/604 与 mod595 同属一个 (v186+v185) 因子 — 与 §4.18 战斗修正行的骨架一致, 本节补完整式。

队列原语与双模式:

| 函数 | 语义 |
|---|---|
| sub_1413E1190(cb, kind) | 置 cb+8 位图第 kind 位 (UI 修饰展示用) |
| sub_140BF97C0(unit, kind, atk, def) | 推 24B 条 {kind u32@0, atk i64@+8, def i64@+16} 入 unit+368; 模式由 dword_1430B132C 选: 非零 = **乘法** A = A×(atk+1e5)/1e5 (下钳 1000) / 零 = **加法** A += atk; 尾段向战斗数组 (+424) 传播 |
| sub_1412AAAF0 | 糖: atk‖def 才推 |
| sub_140BFBA50 | 加法模式尾钳 A/B ≥ 1000 |

> 三账并行: cb+8 位图 (UI) + CUnit+368 队列 (明细) + A(+392)/B(+400) 累加器 (乘积); 伤害步 (vt[19]) 首调 sub_140CDA7E0 把位图折入 observer lb+624 modifier_hours 后复位。

kind 推送全表 (逐师循环; 值列 = (attack, defense)):

| kind | 攻守门 | 值 | define/mod |
|---|---|---|---|
| 0 | 两方 | (mod95, mod96) | 指挥官聚合 sub_1412B6C00 (营权重×特质) |
| 2 | 仅守 | (ENCIRCLED−mod265, 同) | ENCIRCLED_PENALTY; 门 = 地形陆 ∧ 合围判定 |
| 3 | 两方 | (当前堑壕现值, 同) | sub_140C7E840 (非等级) |
| 4 | 仅攻 | (unit+1136, 同) | 师计划 bonus (§4.18.17) |
| 5 | 两方 | (v393, 同) | COMBAT_STACKING_PENALTY, 下钳 −0.99 |
| 6 | 两方 | (v401, 同) | COMBAT_OVER_WIDTH_PENALTY |
| 7 | 仅守 | ((1+挖掩乘子)×DIG_IN_FACTOR×max_org×挖掩等级×cb+1376, 同) | DIG_IN_FACTOR |
| 8 | 仅攻 | sub_1412AEFC0 内推 | AMPHIBIOUS_LANDING_PENALTY ×(1−…DECREASE 衰减) |
| 11 | 两方 | (−clamp(cb+16,0,CAP), 同) | SHORE_BOMBARDMENT_CAP |
| 12 | 两方 | (v400, v400) | 铁路炮 −0.4×attack/100 |
| 13 | 仅守 | (−0.5, −0.5) | MULTIPLE_COMBATS_PENALTY; 门 = 师 OG 在本战斗单位数 >1 |
| 14 | 两方 | (0, v174) | ENEMY_AIR_SUPERIORITY_IMPACT; AA 基 = stats+544 + mods×区域敌空优 |
| 15 | 两方 | (v182, 同) | AIR_SUPPORT_BASE × (1+mod135 天气+州) × (1+库 mod357) |
| 16 | 仅攻 | sub_1412AEFC0 内推 (<0 才推) | PARADROP_PENALTY |
| 17 | 两方 | 见上 | COMBAT_SUPPLY_LACK 四 define + mods 603/604/595 |
| 18 | 两方 | (DEF_F×intel, ATK_F×intel) | ARMY_INTEL_COMBAT_BONUS_FACTOR × 情报网络强度 sub_14142E340 |
| 19 | 两方/仅攻/仅守 | 六源混流 | mods 427-430 (流亡/GIE) / 574-579 (vs major/minor, 键 = 敌国旗 国+5210) / 346+553 (攻) / 348 (守, 取敌方 tag 集合最极端值) |
| 20 | 仅攻 | (mod347, 0) | ATTACK_BONUS_AGAINST_A_COUNTRY_ON_ITS_CORES; 门 = 敌 tag ∈ 州核心 |
| 21 | 两方 | (cb+1272, 同) | 边界战 modifier (仅 combat+152) |
| 22 | 仅流亡 | (427+428, 429+430) | 政府 in exile 同国变体并档 |
| 23 | 两方 | **仅置位图, 不推队列** | 门: 敌 tag ∈ 国+288 容器 |
| 24 | 两方 | (Σmods, Σmods) | 将领地形特质聚合 (仅陆地省; 州单位表 +1968 64B/条 script 求值 + 特质旗位→mod 映射) |
| 27 | 两方 | (v395×terr/1e5, 同) | cb vt[23] 每师地形值; 负值先 ×(1−mod353); ×v395 (cb+1384) |
| 28 | 仅守/两方 | (mod173×R, mod174/477×R) | 天气 × 模板抗候系数 (unit+1208) |
| 29 | 仅攻 | (v234, 0) | 库+624 + BASE_NIGHT_ATTACK_PENALTY + stats+832 + mod259; 门 = 天气省结构 +576 的 u64 > 80000 |

kind 24 特质旗位映射 (特质 flags@+1448, 门字节@+1464 命中即停):

| 旗 | 攻 mod | 守 mod |
|---|---|---|
| &4 | 183 | 184 |
| &0x10000000 | 185 | 186 |
| &8 | 189 | 191 |
| &0x10 | 349 | 350 |
| &0x20 | 181 | 182 |
| 特质+1463 非零 | 187 | 188 |
| &0x40000000 | 190 | — (仅攻) |
| (基础) | 192 | 193 |

订正项 (对历史 findings):

| 项 | 订正 |
|---|---|
| 叠层下钳符号 | sub_1424EF6F0(ptr, v) 体 = `*ptr = -v` (存**负**常量) ⇒ 钳位 max(值, −99000), 非 +99000 (IDA 显示易误读) |
| cb+16 封顶 | cb+16 本身**不封顶**; 封顶只作用于 kind 11 推送值 |
| kind 11 符号 | 推送值带负号 |
| 铁路炮源 | sub_1412AA870 = 最强敌铁路炮炮击值 (max), 非空优比 |
| cb+219/cb+220/FLANKED_PROVINCES_COUNT/vt[29] 海战分支/vt[12] progress | **均不在本函** (历史 findings 误归; 通读全函数逐行确认); 写点应另定 (推定在 CLandCombat 槽[15] 步序其他环节) |

> 待裁: kind 18 的 define↔qword 映射 (两 define 均为 1.0, 原版无行为差异; 推送参数序 a3←DEF_F / a4←ATK_F 与命名反向); kind 29 夜战门字段 (天气省结构 +576) 命名 — 代码极性要求其为**夜暗度** (>0.8 触发夜罚), 字段名需对 weather.cpp 结构定案。
