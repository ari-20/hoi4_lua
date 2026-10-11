

### 4.10 CDiplomacyStatus / CPolitics / 自治

方法群 (dip/rs/ps/party/autonomy 五类) 锚 = diplomacy.cpp / relation.cpp / politics.cpp assert 系 + 效果类 Execute (CEffect 槽 13) 批量锚定。日期对象统一形态 = CGregorianDate 24B {vtable@+0, hours@+8, greg vtable@+16} (§3.7a)。

#### 4.10.1 CDiplomacyStatus (dip)

| 项 | 值 |
|---|---|
| 挂载点 | `*(cc+3976)` (dip) |
| sizeof | ≥1024B |
| vtable RVA | 0X142961CE8 |
| writer | 0X140D47400 |
| loader | — |
| Reset | 0X140D33640 |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CRelationStatus* | active_relations 容器数据 {data@+8, cap@+16, count@+20, alloc@+24} | 稠密指针数组, 槽位 = 对方国家 idx; 元素 CRelationStatus (0x9C0); GUI: opinion 唯一 UI 出口链起点 (sub_1406F4490: 本表[idx] → rs+768 cached_sum) |
| +16 | uint32 | active_relations 容器 cap | Reset 0X140D33640 四元组直读 |
| +20 | uint32 | active_relations 容器计数 | |
| +24 | 匿名结构 (NNB 形状) | active_relations 容器 allocator | 高置信 |
| +32 | CRelation 向量 | **全关系对象缓存** {data@+32, cap@+40, count@+44, alloc@+48} — 8B 元 = CRelation* (含全部 18 型; setter clone 族三件套维护: _Relations(rs+208) + dip+32 + _OwnedRelation(rs+232) 摘旧挂新; 0X140D3C3E0 以 token@+8==14346 滤 war; 探针: 交战国 count>100) | 定案 |
| +56 | POD 数组 | 瞬时暂存列表 {data@+56, cap@+64, count@+68, alloc@+72} (扁平 POD 数组 — 增长码无 vtable 装配, teardown 走 pdx 24B 通用释放 sub_14011EBD0 而非逐元 dtor; 全档 333 国运行时全空 — 推定战争结算/和会期工作缓冲; 无 `*(…+3976)+56` 消费形态, 外交 UI 不消费) | 定案 |
| +80 | POD 数组 | {data@+80, cap@+88, count@+92, alloc@+96} — **politics 消费点已定位** (popularity 核 sub_140BA7770 逐 rs 查 rs+320 值表 [组+1544 drift_from_guarantees 索引] = guarantee 关系 → 被保证方执政组 drift 供献) | 定案 (消费) |
| +104 | CWargoal** | **available_wargoals 容器数据** {data@+104, cap@+112, count@+116, alloc@+120} — 8B 指针元 → wargoal 对象 (元+60=目标国 idx); **与 cc+1328 非同一容器** (全量计数分布: 同值 4 / 仅本侧 1 / 仅 cc+1328 侧 14) | writer 键 0x337C; GUI 见下方 GUI 消费表 |
| +128 | CWargoal** | **wargoals 容器数据** {data@+128, cap@+136, count@+140, alloc@+144} — 完整 CWargoal 对象 (vtable 0x1429E0058; 动态 token@元+64 = type 定义指针→*(def+8)) | writer 键 0x331D ↔ 存档 `wargoals={...}` (定案) |
| +152 | uint32 向量 | **当前交战国 tag 缓存 (enemies)** {data@+152, cap@+160, count@+164, alloc@+168} — u32 tag 列表 (0X140D37C60 经 war rel 求最早开战时刻直证; 0X140D3F100 = "is_enemy" 谓词查此; 己敌三件套 {+152 插入序/+248 排序集/+344 平行战争计数}) | 定案 |
| +176 | uint32 向量 | **战争同盟军缓存** {data@+176, cap@+184, count@+188, alloc@+192} — u32 tag 列表 = 我方所在战争阵营全体成员 (**不含自己**; 探针互见互证: i3/i4 互列对方各不含己, 孤军作战国为空) | 定案 |
| +200 | 匿名结构 (NNB 形状) 向量 | **generate_wargoal 列表** {data@+200, cap@+208, count@+212, alloc@+216} (token 13339 直名; 推定 = 我方正在辩护战目标的目标国缓存; 谓词序: +152(交战) → +200 → +224 → +368(已有战目标) = "潜在敌国" 判定; 对账档均空, 写入点未定位 — 推定与 CTimedWargoalActivity (ps+8) 生命周期联动) | 定案 |
| +224 | 匿名结构 (NNB 形状) 向量 | **generate_wargoal_against 列表** {data@+224, cap@+232, count@+236, alloc@+240} (token 13860 直名; **= 本国正在 justify 的目标国列表** (is_justifying_wargoal_against; sub_140D40290 直读, 方向 = 我方为发动方 — 定案); 0X1403CFE50 逐国双向查 +368/+224) | 定案 |
| +248 | tag_id 向量 | **敌国 tag 排序集** {data@+248, cap@+256, count@+260, alloc@+264} — +152 的升序 set 版 (探针: 插入序 {24,188,66} vs 排序 {24,66,188}) | 定案 |
| +272 | tag_id 向量 | **共同敌国排序集** {data@+272, cap@+280, count@+284, alloc@+288} — 与盟友共享的敌国升序 set (仅同盟国非空, 孤军国为空; 与 +296 成对: 排序/插入序) | 高置信 |
| +296 | tag_id 向量 | **共同敌国插入序列表** {data@+296, cap@+304, count@+308, alloc@+312} — +272 的插入序版 (序与 +152 一致; ⚠ Reset2 不清此槽 — 小不对称, reader 防御) | 高置信 |
| +320 | tag_id 向量 | **占领我方核心州的敌国 tag 缓存** {data@+320, cap@+328, count@+332, alloc@+336} (0X140D45F10 静态直证: 逐敌国(+152) → 其 controlled_states(cc+1120) → state owner==我 且 cores(state+176) 含我 (overlord 解析) → 推入; 探针互证 ⊂ +152) | 定案 |
| +344 | uint32 向量 | **per-敌国关系分类码** {data@+344, cap@+352, count@+356, alloc@+360} — 与 +248 严格平行同序的 u32 码表 (∈{1,4,5-11}: 1=基础可交互 / 4=阵营聚合 / 5=对方视我交战 / 6=对方对我造理由 / 7-8=附属链 / 9-11=taken_lead_to_wars 族); 每日外交 FirstPass (sub_140D357E0) 全量重建: 清 +248/+344 → 扫全量国 bitmap 去重后平行追加 — SecondPass 聚合共同敌国 dip+272/+296 消费 | 定案 |
| +368 | 扁平 u32 数组 | **附属国 tag 缓存** {data@+368, cap@+376, count@+380, alloc@+384} (定案): sub_1401B1470 stride-4 线性查定形态; 四消费者定语义 — sub_140E649A0 工厂分成 / 0X140B35D80 附属+自治 tooltip / 0X1406DECD0「我是其附属」谓词 / contains 0X140D3F050「wargoal 针对附属视同针对宗主」 | writer 不序列化; GUI 见下方 GUI 消费表 |
| +392 | tag_id | overlord tag 标量 (CAutonomyProgressView "overlord_name"/"SUBJECT_OF_NAME" 直名) | 与 war_relation 表 wr+392「second_wargoals cap」不同基, 无真冲突 |
| +400 | uint32 向量 | **governments_in_exile_we_host** (u32 tag idx 列表) {data@+400, cap@+408, count@+412, alloc@+416} | writer 键 0x3ABB |
| +424 | uint32 | **_HostingUs** (流亡东道国 idx) | assert `_HostingUs.IsValid` (0X140D43B50); writer 键 0x3AB9 ↔ `hosting_our_government_in_exile="ENG"` |
| +432 | fixed×1e-5 (int64) | **legitimacy** (钳 0..上限) | add 链 = CAddLegitimacyEffect::Execute **0X14034AA80** → 0X140D344D0 (+= 钳 [0, qword_143335DC0]); set 链 = CSetLegitimacyEffect::Execute **0X140362C80** → 0X140D45000 (直写钳位) — 原「CAddLegitimacyEffect 0X140362C80」系两链地址误挂 (vtable RTTI + 函数体 debug 串双证 :19115/:19143); writer 键 0x2C41 ↔ `legitimacy=100` |
| +440 | uint32 | exile_army_leaders | writer 键 0x3AC0; daily legitimacy≥阈值 → 造将+1 |
| +448 | 内嵌 CModifier (~192B) | 外交动态修正块 | ctor 装 CModifier vtable (形态定案/语义推定) |
| +640 | uint8 | **流亡活动旗** (政府流亡中 = 1) | daily 0X140D3B920:280; 且 legitimacy≤0 → 流亡终结 |
| +641 | uint8 | **naval_blockade** | writer 键 0x27F8 ↔ `naval_blockade=yes` (定案; 10232 亦 = CNavalBlockadeRelation token) |
| +648 | CCountry* | **属主国回指** | 全方法群通用 |
| +656 | CFaction* | **所属派系指针**; 成员容器 {d@+88, c@+100} | SetFaction 0X140D44800 (断言 "enemies in the faction"); GUI 见下方 GUI 消费表 |
| +664 | CGregorianDate 24B | **trade 日期** (上次贸易日期) {vtable@+664, hours@+672, greg vtable@+680} — writer 0x140D47400 写 `if (*(+672) != 43808760) sub_1424C2E20(v2, 10350, +680)`, 键 10350 = token 表直名 `trade`; reader 0x140D41330 case 10350 → `sub_1424C0AA0(a2, +680)`; rs 侧同键 = rs+112 (rs writer 0x140D2DB40) — ⚠ 对账档 0 例 `trade=` 的根因 = 门为「hours ≠ 43808760 初始哨兵」, 无贸易则恒不写 | writer 键 10350 |
| +688 | CGregorianDate 24B | **last_surrender_date** {vtable@+688, hours@+696, greg vtable@+704} — writer token 0x3681=13953 直名 + 存档键序 (faction_join_date 前) 互证; 实档普遍出现 (单档 7–21 例) | writer 键 13953 |
| +712 | CGregorianDate 24B | **faction_join_date** {vtable@+712, hours@+720, greg vtable@+728} | writer 键 0x386A; SetFaction 写当前小时 |
| +736 | uint8 | **capitulated** | writer 键 0x3549 ↔ `capitulated=yes`; uncapitulate 0X140D45D80 置 0; GUI: 战争盟友行显示 (CWarAllyItem Refresh sub_141E7B700) |
| +744 | CGregorianDate 24B | **capitulated_date** {vtable@+744, hours@+752, greg vtable@+760} | writer 键 0x3CB2 (定案; +736 门控) |
| +768 | 匿名结构 (40B) | 待处理外交行动 容器数据 {data@+768, cap@+776, count@+780, alloc@+784} — (proposed), 40B 条 | 布局见 §4.10.8; 插入 0X140D34C80 |
| +792 | CWarOverView 向量 | **当前战争一览缓存** {data@+792, cap@+800, count@+804, alloc@+808} — **48B 元 = {side1: u32 tag 向量 24B, side2: u32 tag 向量 24B}** (构建器 0X140D3C3E0(dip, out=dip+792): 从 dip+32 滤 war 关系取战争双方阵营, 无序去重插入; **六直接调用点** (0X1415D6FF0 外交视图 + CWarOverView populate 两点 + RebuildDipCaches sub_140D46650 内重建 +792 + 外交视图两填充器 sub_141CA4F00 CallAlly / sub_141CA54B0 JoinAlly, df365 + df403); RTTI 无 CIncomingDiplomaticAction 类 — 无独立 RTTI 类) | 定案; GUI 见下方 GUI 消费表 |
| +816 | CRelationStatus** | **脏关系缓存** {data@+816, cap@+824, count@+828, alloc@+832} | daily 重建并逐元 attitude 刷新 (0X140D3B920; 高置信) |
| +840 | uint8 | 脏关系缓存重建旗 | 高置信 |
| +848 | CCurrentAutonomyStatus* | 自治 CCurrentAutonomyStatus | 见 §4.10.9; writer 0X14067AA30 |
| +856 | 匿名结构 (12B 形状) 向量 | **taken_lead_to_wars** {data@+856, cap@+864, count@+868, alloc@+872} — 12B 条 {tag u32, reason u32, days u32} | writer 键 0x4B9A + SLeadsToWarReader (定案; rs 侧无对应行) |
| +880 | uint32 | cached_allies_and_gurantees 容器数据 {data@+880, cap@+888, count@+892, alloc@+896} (存档原拼写 "gurantees"; **loader = sub_140D40F90** — 元素 token u32 tag 名→id, 与 writer 侧对称) | writer 键 0x4B97; u32 idx 数组 → tag 名 |
| +904 | CMilitaryAccess* 向量 | **_MilitaryAccesses** {data@+904, cap@+912, count@+916, alloc@+920} (CMilitaryAccess::Add + COfferMilitaryAccess::Add 共容器, offer 共存; find-or-push "Contains == false" 断言 **diplomacy.cpp:752** — 原 :0x31C(796) 系 1.19.2 旧行号, 1.19.3 断言行单调带 752..813 内无 796; find-or-add 载体 = 0x140D34500); **元素 vtable RVA 0x2960408 = CMilitaryAccessRelation** (活体直证) | assert `_MilitaryAccesses.IsEmpty` (0X140D3A1B0:**664**; :666/:668 NavalAccesses/OfferNavalAccesses 同排) |
| +928 | CDockingRights* 向量 | **_NavalAccesses** {data@+928, cap@+936, count@+940, alloc@+944} = docking_rights(+offer) 缓存 (CDockingRights::Add + COfferDockingRights::Add; first 侧; find-or-add 载体 = 0x140D345C0, 断言 :770); 元素 = CDockingRightsRelation (token 15098@+8) — **方向定案 (活体): 本国授予对方** (元素 tag 对 {授予方@+16, 接收方@+20}, 本国在前; +24 起两 CGregorianDate, 次日期常为 1.1.1.1 哨兵) | 定案 |
| +952 | CDockingRights* 向量 | **_OfferNavalAccesses** {data@+952, cap@+960, count@+964, alloc@+968} = offer_docking_rights 侧 (CDockingRights::Add second 侧; 载体 = 0x140D34680, 断言 :787); **方向定案 (活体): 本国收到的 offer** — 元素 tag 对 {授予方@+16, 接收方@+20} 对方在前, 与授予方 +928 逐条镜像闭环 (GER 授 15 国 ↔ SPR 收 GER/ITA/ROM/JAP/SIA/INS/D04 七方) | 定案 |
| +976 | CAirBaseAccess* 向量 | **air_base_access(+offer) 缓存** {data@+976, cap@+984, count@+988, alloc@+992} (CAirBaseAccess::Add + COfferAirBaseAccess::Add; 载体 = 0x140D34350, 断言 :803); **元素 vtable RVA 0x2A217F8 = COfferAirBaseAccessRelation** (活体直证: 本档唯一非空条目即 offer 侧) | 定案 |
| +1000 | 匿名结构 (NNB 形状) 向量 | **captured (被俘将领缓存)** {data@+1000, cap@+1008, count@+1012, alloc@+1016} — 8B 指针元 | writer 键 0x3D14 ↔ `captured={`; "captured generals cache" 串 (定案; rs 侧无对应行); 三释放件 0x140D42C10/0x140D42F10/0x140D42D70 (:4198/:4221/:4244) 共用无效槽 swap-remove + 一次性断言 (闩 byte_14333CE31/32/33); 元素业务键 = 对象+288 tag 双形态匹配 {原 tag, link index (sub_140BB5490)}, 按国释放外参 = 该双字键 |

dip 字段 GUI 消费 (消费点 ≥3 者立表):

| 字段 | 消费点 | 用途 |
|---|---|---|
| dip+104 available_wargoals | 宣战面板 wargoals_grid ([7] 0X141C99DA0) | 我方侧网格 (wg+60==对方 tag ∧ 对方 dip+368/{+380} 含) |
| dip+368 附属国 tag 缓存 | 宣战网格对方侧门 / B15 贸易过滤 subject 支 / CSubjectViewItem / CActiveWargoalStripView 附属覆盖 (§4.10.16) | 附属覆盖判定 (wg 针对附属视同针对宗主) |
| dip+656 CFaction* | 目标国 header 阵营名 (sub_140D8BB80, faction_name; 无 → DIPLOMACY_NO_FACTION) / FactionView 取链 (gs+1312/1316 → 本槽) / B15 贸易过滤白名单 (members {d@+88, c@+100} CCountry* 集) | 阵营归属展示/过滤 |
| dip+792 当前战争一览缓存 | CWarOverView 同构副本 (side1 集@+23576/count+23588, side2@+23600/count+23612; 聚合旗+23624 / 三过滤器+23625-27 / 双排序模式+72/+76; populate sub_1418AC420 → sub_1418AFFC0/sub_1418ADFA0) | 战争一览 |
| rs+648 puppet 槽 | CSubjectRelationstripView target 链 (+56 附属国 tag → dip+8 → 本槽) | 附属关系条 (§4.10.2 槽分配表) |

justify 运行期成本链 (sub_1410FF6C0, 每次 justify tick 求工期; 全 ×1e5 定点): `base = def+732 + 州数×def+736` (a4+12 州数; 已交战/已宣 sub_1406FD220 → 减 def+732; vs major at war sub_14113A8F0 → ×(1+WARGOAL_VERSUS_MAJOR_AT_WAR_REDUCTION −0.75); 下限 1.0); `time_factor = enemy_justify_time(248,target) + sub_1410FEBE0 + 1.0 + justify_time(246,taker) [+ justify_when_major_war(247,taker)]`; `ramp = max(WARGOAL_PER_JUSTIFY_AND_WAR_COST_FACTOR 1.5×dip+236 − 1.0, 0)` (dip+236 = +224 列表 count, 同时 justify 目标数); `cost = base × max(time_factor+ramp, 0) × min(BASE_GENERATE_WARGOAL_DAILY_PP 0.2, 1.0) × (subversive_upkeep(110,taker) − foreign_subversive(109,target) + 1.0) × (1 + WARGOAL_WORLD_TENSION_REDUCTION −0.5×world_tension)`; 下限 MIN_WARGOAL_JUSTIFY_COST 2.0; `days = round(cost / BASE_GENERATE_WARGOAL_DAILY_PP)` (sub_1410FECE0; define=0/溢出 → 0xFFFFFFFF)。wargoal def cost 字段映射 (reader 键): take_states_cost 12558→def+744 / liberate_cost 12573→+752 / puppet_cost 12560→+760 / force_government_cost 12561→+768 / 四 threat_factor 13557-13561→+776..+800 (13558→+728 走普通 dword 读 = force_government_limit); 字段读形 = 100000 + trunc(raw/100)。

#### 4.10.2 CRelationStatus (rs)

rs = dip+8 active_relations 容器元素, sizeof 2496 (0x9C0); vtable 0x142960B10;
writer = vtable[2] 0x140D2DB40 / reader = vtable[4] 0x140D2B300 (serfam:624);
ctor 0x140D17B30 / dtor 0x140D181F0 / Reset(teardown) 0x140D1E470 /
每日重算 Recalculate 0x140D1FDC0 (dip daily sub_140D3C000 逐 rs 调用) /
cached_sum 重算 0x140D2D8D0。

关系对象落入点 = `sub_140D20230(rel)`: 取 `dip = *(cc+3976)` → `dip+8 表[对方国 idx]` → 在**对方 dip 的 +208 容器** (count@+220) 查重, 命中即报 "Initializing Duplicate Relationship: %s between %s and %s" (relation.cpp:200); 未命中走 vtable[21] (0xD8) 插入。关系类由 token 工厂 `sub_140D1EE80(token)` 分派构造 (CPersistentReloadableGameItemDatabase 族)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CTimedOpinionModifier* 向量 | **CTimedOpinionModifier\* 内联 2 向量** {data@+8, cap@+16, count@+20, alloc@+24}; **插入点定案 = Recalculate (0x140D1FDC0) 把 +256 中「未锁过期 ∧ 已过期」∨「值折算为 0」的失效 opinion 指针推入本表** (过期判据 `!*(e+57) && gs+2256 ≥ *(e+24)`; 零值 `sub_140A81F40(e)==0`) — 失效 opinion 回收暂存队列; **消费者 = rs 日更 sub_140D251B0** (复查过期/零值 → swap-remove + vtable[0] 析构 + 逐次 cached_sum 重算); Recalculate 每轮先清空本队列 |
| +24 | allocptr | 属 +8 向量头 (指向 +32 分配器本体), 非独立字段 (定案) |
| +32 | 分配器本体 32B | CPdxHybridInlineBufferAllocator 本体 {vtable@32, 内联缓冲 2×8B @40..55, 共享空缓冲 off_143085170@56} (定案) |
| +64 | int64 fixed | **实力比** = 1e10 × v35 ÷ (1e5×v34), 钳 [0, 1e8] ({v35,v34} = sub_1406F3160(属主国, 对方idx) 双出参; **边界: v34≤0 → 直接 1e8**, 非除零); Recalculate 每日重写 (公式定案) |
| +72 | u8 旗 | 修饰块重算差异旗 (sub_140559750(现块) != sub_140559750(全量重建块); 重建器 sub_140D1AE20 栈上建 192B 新 CModifier 比对) (高置信) |
| +73 | u8 旗 | attache 旗 = (rs+520 槽关系对象) ? 其 vtable[9] : 0 (定案) |
| +74 | u8 旗 | 交战旗 = *(rs+744) ∧ 非隐藏 ∧ is-at-war 谓词 sub_140D3F440 (定案) |
| +80 | uint32 | **对方国 idx**; AddOpinionModifier 0X140D19390 / 事件 scope 构造 |
| +88 | CGregorianDate 24B | **last_send_diplomat** {vtable@+88, hours@+96, greg vtable@+104}; writer 键 10568 门 hours≠哨兵 (定案; available_wargoals 真身 = dip+104); reader 另收 10567 `last_war` = legacy 键 (format==3 整键跳过) |
| +112 | CGregorianDate 24B | **trade** {vtable@+112, hours@+120, greg vtable@+128}; writer 键 10350 ↔ `trade="1940.4.1.15"` (定案; wargoals 真身 = dip+128) |
| +136 | CGregorianDate 24B | **trade_equipment** {vtable@+136, hours@+144, greg vtable@+152}; writer 键 11180 |
| +160 | CGregorianDate 24B | **truce_until** {vtable@+160, hours@+168, greg vtable@+176}; writer 键 13835; **truce 型 (13911) 唯一落点** (truce 无对象子类, 见节尾负结论) |
| +184 | CGregorianDate 24B | **kicked** {vtable@+184, hours@+192, greg vtable@+200}; writer 键 14445 |
| +208 | CRelation* 向量 | **_Relations** (非属主侧关系) {data@+208, cap@+216, count@+220, alloc@+224}; teardown 先过 war 滤 (a2/a3 门 + token 14346 + 州 scope 双查 sub_140700600/450) 再 vtable[22] Remove / sub_140D1CC40 End |
| +232 | CRelation* 向量 | **_OwnedRelation** (= 书内 "relations") {data@+232, cap@+240, count@+244, alloc@+248}; writer 逐元按**动态 token@元+8** 发射; reader default → 工厂 sub_140D1EE80 → vtable[3] Parse → relation.cpp:3221 "RelationToSelf==false" 断言 → sub_140D20230 插入 |
| +256 | CTimedOpinionModifier* 向量 | opinions {data@+256, cap@+264, count@+268, alloc@+272} — **指针元 8B → 本体 64B** {**def token u32@+8 (reader 查重键)**, 双 16B CGameDate (+24 运行期过期时刻 / +32 序列化 date, 键 10314), modifier def@+40, value i64@+48 (键 776), decay 旗@+56 (键 11050), do_not_expire 旗@+57 (键 14504)}; def i16 {base@+112, min@+114, max@+116, days@+118}; 过期时刻 = gs+2256 + 24×days (已存在取 max); 序列化 modifier 键 10597; parse 10913: malloc 0x40 → ctor sub_140A80670 → **按 def id 查重合并** (命中 sub_140A827D0(old, 新值) 后弃新 — **SetValue 定案**: 骨架 = 写 *(a1+48) 后钳位 [1e5×(i16)(def+114), 1e5×(i16)(def+116)] + dip+392 tag 别名对账 (双非零异名 → sub_140BB52F0) + sub_140D2D8D0 缓存重算; 调试日志门 byte_143452529 :300/:305; **对偶 AddValue = 0x140A80930** (+= 形, :317/:322; 全语料唯一运行期调用点 = 关系日更链, 增量出自 sub_140D237B0)) 否则尾插 (1.19.3 锚: writer 0x140A82C60 / reader 0x140A824E0) |
| +280 | 指针向量 24B | **键 10597 `modifier` 按名静态修正条目指针表** {d@280, cap@288, count@292, alloc@296} (元素 +424 = 名串 SSO); writer 逐元发射名串, reader 按名查单例库 qword_143330098 后尾插 (书此前无此行) |
| +304 | CModifier 头 16B | 修饰块上下文头 {vtable@304, token u32@312 = 357 `none` 默认}; 其 +16 即 +320 vecA / +28 即 +332 |
| +320 | 匿名结构 (16B 形状) 向量 | **生效修正值表 vecA** {data@+320, cap@+328, count@+332} 16B 条 = {def_idx u32@0, pad@4, value i64@8} **按 def_idx 有序** (二分插入/同 def 累加); def 全局库 = qword_14332ED90 (120B/条); AddRelationModifier sub_140557840; teardown 遍历 sub_14055F700 (定案) |
| +344 | 向量 24B | **活动修饰实例指针表 vecB** {d@344, cap@352, **count@356**, alloc@360} — 元 = 192B CModifier 完整实例 {头 16B + 嵌套 176B 块}; Add 路径 sub_14060C920 产实例 (可从 vecC 自由表取) 后尾插 (定案) |
| +368 | 向量 24B | **192B 实例回收自由表 vecC** {d@368, cap@376, count@380, alloc@384} (清理时 vecB 指针整体并入 sub_140185E10) (定案) |
| +392 | std::string 32B | 修饰块名串 {buf@392, size@408, cap@416=15} (定案) |
| +432 | 哈希表 | **池1 = 开放寻址哈希表** {桶指针@432 (初始共享空桶 &unk_143086E30), **元素计数@440**, u8@448, 负载因子 f32@452 = 0.85}; 元 40B = {key u32@0, 占用旗@4, 24B 值@8} (定案) |
| +464 | 哈希表 | **池2 = 第二哈希表** {桶指针@464 (&unk_143086E80), 计数@472, u8@480, lf f32@484 = 0.85}; 元 8B = {占用旗, key u32}; 键哈希 = 73244475 乘加异或折叠 (定案) |
| +488 | int32 | = −1 (ctor/Reset; 克隆时从源块 +168 复制); 语义未决 |
| +492 | int32 | = 1; **实例克隆使能 index** (sub_140557840 以 v12−1 为序号调 sub_14060C920 产实例, 0 = 禁; 克隆时由源索引覆写) |
| +496 | CDiplomacyStatus* | **属主 dip 回指**; *(*(rs+496)+648)+8 = 属主国 |
| +568 | SLendLeaseHistory 40B | **SLendLeaseHistory 对象** {vtable@568, 4×fixed @576/584/592/600} (原「llth 块基」正名); writer 键 12950: 四分任非零才写 (sub_1424ED3F0 取值); reader 12950 → vtable[3] 直写; teardown 重建本地同名对象后清 576..600 四 qword (vtable 不动) |
| +720 | uint32 | faction_join |
| +744 | 指针槽 | **_pWarRelation**; assert `_pWarRelation == nullptr`; GUI: CWarRelationStripView target 链终点 (+56 本国 tag → dip+8 active_relations[对方idx] → 本槽; 条目 +40 = token 10637 "war" / +44 = 侧模式, relationstripview.cpp 直证; 宿于 CDiplomacyView 双实例; **war+73 u8 旗 == 0 = 战争有效门** (opinion 12673 交战基础项, §4.10.2a; 语义推定非和会中) |
| +768 | int32 | cached_sum; writer 键 11598 (非零才写); 重算 0X140D2D8D0 (体直证): 门 = !gs+2613 ∧ (!sub_1401E2930(gs) ∨ gs+2617) → sub_1406F44D0(现算, a1 = *(rs+496)+648 链取国, a2 = rs+80) → clamp 先 max 后 min → 写本槽 → 尾调 sub_1407155C0(cc, &tag, 0) (§4.10.2a) — opinion 唯一 UI 出口 = sub_1406F4490 |
| +776 | fixed×1e-5 | border_friction; writer 键 11286 (非零才写, f64 通道 sub_1424C34F0) ↔ `border_friction_claim=` |
| +784 | u8 旗 | **「与对方共同参战」旗** (has_war_together_with 判据) — 读点 = sub_140D256B0, 由 CHasWarTogetherTrigger 槽[22] 调用; 置位点 = setter sub_140D2CFD0 ← sub_140D46650 (rs 全量重建); **被门控者** = llth 四累加器 (体首行 `if (*(BYTE*)(a1+784))` ⇒ 前置使能非旗本身); **活体分布: 全量 135000 rs 条目中仅 20 条置位** |
| +786 | uint8 | 析构护栏旗 (dtor 置 1 → 调 Reset(0,0) → 清 0, 抑制 Reset 副作用路径; ctor 置 0) |
| +792 | CAIAttitude* | attitude (名 SSO@+16); writer 键 11737 ↔ `attitude="attitude_hostile"`; ctor/Reset = 态库 sub_1401615B0()+88 默认条目; reader 按名 sub_140636220 查库 |
| +800 | uint8 | attitude 锁定旗 A (ctor/Reset 清 0); "Locked attitude for %s" 0X140D19E10 |
| +801 | uint8 | attitude 锁定旗 B (默认 **1**) |
| +804 | uint32 | **recently_leased_ic = 每日递减计数器** (daily sub_140D2A150 对 dword_1433374D0 递减, 负则钳 0; ); 键 13887 (writer >0 才写, reader 单 int 装载) |
| +808 | rule_overrides 块基 | **rule_overrides 块基** (flags 28 槽 @+816 步进 4 / desc 28×32B @+928 / vec 28×24B @+1824 的块基); writer 键 10146 (**门 = Σ28 旗 + Σ28 vec 计数 > 0**, writer 双循环现算); ctor sub_140D17E50; teardown = 新规则覆盖块整体赋值 sub_140D18B70 (该块 = 运行期求值块非 CRule 类: tri-state u32×28 @块+8 / 条件修正向量 28×24B @块+1016, §4.3.7a) |
| +816..+924 | uint8 [28] | rule_overrides 槽 k flag (槽 k = 816 + 4k, k∈[0,27]) |
| +928..+1792 | 串 [28] | rule_overrides 槽 k desc 串 (槽 k = 928 + 32k, 每串 32B) |
| +1824..+2472 | 匿名结构 (NNB 形状) 向量 | rule_overrides 槽 k vec 容器 (槽 k = 1824 + 24k, 每槽 24B); 键 token@rules_base+56k+40, rules_base = `*(BASE+53575920)` |

per-relation-type 活动关系缓存槽分配 (+504..+760, 8B 步进 ~32 槽; 方法 = 19 关系子类 vtable **vtable[21]=Add / vtable[22]=Remove** 逐类读槽):

| 槽 (rs) | 关系型 (token) | 备注 |
|---|---|---|
| +504..+519 | improve_relation (11479) | |
| +520..+535 | send_attache (14553) | |
| +536..+551 | boost_party_popularity (12525) | |
| +552..+567 | lend_lease (12618) | 0X140D2CC90 清建筑访问 = 摘除副作用; 槽主 CLendLeaseRelation (对象+20 = 租借关联对方 tag dword, is_lend_leasing 直证; 推定) |
| +568..+600 | — | llth 块 (见主表 +568 行) |
| +608..+623 | naval_blockade (10232) | helper 同写 `*(dip+641)=a2!=0` (dip+641 旗来源) |
| +624..+639 | equipment_purchase | 不在 18 常驻 token 列 |
| +640 | market_access_rights (13696) | 单槽 |
| +648 | puppet (12497) | GUI: CSubjectRelationstripView target 链命中 (§4.10.1 GUI 消费表) |
| +656..+671 | guarantee (10458) | |
| +672..+687 | military_access (10548) + offer_military_access (12232) | 共槽 |
| +688..+703 | docking_rights (15098) + offer | 共轭 |
| +704..+719 | air_base_access (10298) + offer | 共轭 |
| +720 | non_aggression_pact (12220) | 单槽 |
| +728..+743 | licence_production_access (19331) | |
| +744 | war_relation (14346) | 主表 +744 行 = _pWarRelation 槽 |
| +752..+767 | embargo (12916) | 方向定名 (高置信): 752 = is_embargoing 半 (施行 embargo 侧) / 760 = is_embargoed_by 半 (被 embargo 侧), 触发器名锚定 |

teardown 实清 **27 槽** (26 qword 清单 + 744 单独; 槽区 33 qword 中不清 6: +568 为 vtable 头只清数据 + 624/632/640/688/696 — 引擎特例/遗漏, reader 防御)。槽族写入门 = `*(rs+440)<=0 && !*(rs+356)`: **+356 = vecB 活动修饰实例数 / +440 = 池1 哈希表元素数 (两计数定案)**; 两计数皆零才直落全清, 否则清修饰块并**将 rs 自 dip+56/对方 dip+80 两缓存摘除** (sub_1401B33B0 双侧 — dip+56/+80 实为「修饰活动关系」的 rs 指针缓存, 原推定"瞬时暂存列表"按此增注)。

**24 型↔槽位缺口闭合 (负结论)**: 原「关系注册表」实为外交面板 relation strip view 注册表 (sub_1415EAE80, 112B/条, token@+40/side@+44, 56 条 24 token) 非"工厂注册"。truce (13911) **无对象槽** (数据 = rs+160 truce_until); timed_wargoal (13319) / timed_stage_coup (13424) / demilitarized_zone (12531) / war_reparation (12532) **不占 rs 槽** — 对象形态 = CBaseTimedActivity 族 (工厂 sub_140AD7DD0; 存 **ps+8 指针向量, writer 键 13320**); resource_rights (12533) 无工厂分支 (timedactivity.cpp:250 断言) 载入即跳过。**§4.10.2 槽分配表无需加行**; CTimedWargoalActivity 构造反向双登记 dip+200/224 (升定案)。

**CTimedWargoalActivity ctor 补全 (0x140AD7390, diplomacy.h:696/:718, 定案)**: +8 = **13319** (timed_wargoal cookie 直名); 基链 CBaseTimedActivity → CTimedWargoalActivity 双 vtable; 两 tag @+16/+20; **CGameDate ×2 内嵌 @+48/+72** (各 24B 双 vtable 形态 §3.7a: vt1@+48/+72, hours@+56/+80, vt2@+64/+88; 哨兵 dword_143086B08 = 43808760 "1.1.1.1" 缓存, 高置信); **bool @+96**; +104 容器 (sub_14011DF40 ctor + sub_1401E1640 填充); +128 指针参 a4; +136 清零。**反向双登记**: 国(a1+20) 的 dip+200 表 Contains(a1+16)? 不在则插 (diplomacy.h:696 "Dupe should not happen?" 断言) / 国(a1+16) 的 dip+224 表同款 (:718)。

**CDiplomacy 双关系向量 (0x140D19750 / 0x140D19820, diplomacy.h:613/:629, 高置信)**: **RelationsWithModifier {data@dip+56, count@+68}** (我给的带修正关系) / **RelationsWithModifierOnUs {data@dip+80, count@+92}** (给我的) — 两表相邻各 24B; push_back 前线性查重, 断言 `!_RelationsWithModifier.Contains( pNewRelation ) && "Already added"` — **查重仅 debug 门, 正式版重复插入不设防**。

**SetRelation\<T\> 换槽模板族** (16 实例全同构, 147 行逐字节一致, 唯 assert-once 守卫字节异): SetRelation(rs, newRel, slot): ① 旧 \*slot 从 rs+208 (_Relations) swap-remove → ② 从
dip+32 {count@+44} (dip 级全关系对象指针容器, casualties 触发器所扫) swap-remove →
③ GetFirst≠GetSecond 断言 (:5043) → ④ 旧对象 vtable[0](1) 删除析构 → ⑤ \*slot = newRel 挂回
rs+208 + sub_140D194C0(dip, newRel) 登记; first==属主或同阵营 (sub_140BB52F0) 再挂 rs+232。
16 实例槽位与 Add/Remove (vtable[21]/[22]) 配对:

| swap 实例 | rs 槽 | Add | Remove |
|---|---|---|---|
| 0x140D16240 | +504/+512 improve_relation | 0x140D289A0 | 0x140D26810 |
| 0x140D14F70 | +520/+528 send_attache | 0x140D275A0 | 0x140D26090 |
| 0x140D15220 | +536/+544 boost_party_popularity | 0x140D27B30 | 0x140D26430 |
| 0x140D164F0 | +552/+560 lend_lease | 0x140D28AB0 | 0x140D268F0 |
| 0x140D16FB0 | +608/+616 naval_blockade | 0x140D2D140 | 0x140D2D170 |
| 0x140D15CE0 | +624/+632 equipment_purchase | 0x140D2CFC0 | 0x140D2CFB0 |
| 0x140D16A50 | +640 market_access_rights | 0x140D2D130 | 同函数双向 |
| 0x140D154D0 | +648 puppet | 0x140D27BE0 本体 (包装 0x140D29630) | 0x140D27190 |
| 0x140D15F90 | +656/+664 guarantee | 0x140D288F0 | 0x140D26770 |
| 0x140D16D00 | +672/+680 military_access + offer | 0x140D28C10 / 0x140D29190 | 0x140D26A30 / 0x140D26E30 |
| 0x140D15780 | +688/+696 docking_rights + offer | 0x140D2CFF0 | 0x140D2CFA0 |
| 0x140D14CC0 | +704/+712 air_base_access + offer | 0x140D2CFE0 | 0x140D2CEA0 |
| 0x140D17260 | +720 non_aggression_pact | 0x140D290B0 | 0x140D26D90 |
| 0x140D167A0 | +728/+736 licence_production_access | 0x140D28B60 | 0x140D26990 |
| 0x140D17510 | +744 war_relation | 0x140D2D1D0 (rs 守卫安装) | 0x140D27510 |
| 0x140D15A30 | +752/+760 embargo | 0x140D28480 | 0x140D264D0 |

0x140D2CExx–0x140D2D1xx 系列 = rs 缓存槽通用 set/clear 包装 (Add/Remove 各以 newRel/0 调 swap);
dock/air/equipment_purchase/market_access/naval_blockade 五对对象本体 Add/Remove 走
internationalmarket TU (0x1419xxxxx), rs 槽维护仍经本族 swap。

**全族虚槽矩阵要点 (20 vtable PE .rdata 直读, 定案)**: [9] 可选用门覆写 7 类 (improve
0x140D1C560 / attache 0x140D1C0E0 / boost 0x140D1C220 / guarantee 0x140D1C440 /
NAP=LendLease 共享 0x140D1C5E0 / embargo 0x140D1C2C0; **war = ret0**, 战争不经此门停);
[11] SetParticipants 覆写 3 处 (基共享 0x140D24D30 / CSubjectRelation 0x140D24DE0 /
CWarRelation 0x140D24EB0); [12] 提案 tick 仅 CWarRelation (0x140D1FD50); [14] 日 tick 仅
CImproveRelationsRelation (0x140D2A1C0, 内调步长公式 — 「改善关系日更走 vtable[14]」唯一实现类);
[13] 特有 boost 0x140D24080 / improve 0x140D240E0, 余共享 0x140AD80B0; 特有 writer 仅
war (0x140D2DE80) / boost (0x140D2DA60) / subject (0x140D2DE20), 特有 reader 仅 subject
(0x140D2B870), 余全族共用基 reader 0x140D2B100 (推定升定案)。

**war 行为面补全 (定案)**: SetParticipants 0x140D24EB0 ([11] 覆写): 调基 + 双向初始化 war score 子对象
  (sub_14117AD00(wr+112, first, second) / (wr+224, second, first) — **+224 视角互换构造期直证**);
  **同阵营腐局兜底**: sub_140D3F440 判真 → "Game corrupted: refusing to create war relation …
  same faction" (:651) + **rel+72 = 1** 照建但标记取消 (§4.31.3 IsCancelMarker 置位点定案)。
- **war score 家族**: GetWarScore 0x140D24260 (选 +112/+224, 断言 :768; 两方向子结构各 112B — 输入序 → +112, 交换序 → +224) / 分数重算 0x140D25FA0
  (hostility_reason 哨兵 6 断言 :678; wr+112/+224 各调 0x1411794F0; 调用者 = dip 修正变化
  force=1 — 战争分数在修正变化时重算) / **CalcWarBlobProgressOf 0x140D1A9D0: 战争 blob 进度 =
  (我方就绪度−敌方就绪度)/2 + 50000 clamp 0..100000** (侧就绪度 = avg(100000−投降进度
  sub_1406DA100), major 旗 cc+5210 分桶; 失败 \*out = 50000) / IsOnLosingSide 0x140D25700
  (阈值 50000 = 0.5, +344 极性配对; 非对称判定 = instigator 侧 (+344 与查询侧异) 严格 < 0.5 / defender 侧 ≤ 0.5 — 半数即「败」的非对称裁定, 断言 :886 串直书真名) / GetWargoals 0x140D244C0 (选 +360/+384, 断言 :1127) /
  AddCasualties 0x140D19270 (+80/+88, :699) 与 AddUnknownCasualties 0x140D198F0 (+96/+104,
  :725; known/unknown 两对计数器业务分野未决, 通知三通道 = sub_140CC2940/CCB500/CC4990) — 写方 = 陆 0x140C67E90/0x140C6AA90、海 0x140D77FF0/0x140F63580、空
  0x140E8C020/0x140E8D6D0/0x140E88330 全战斗分支, **伤亡记账全链闭合**。
- **CWarRelation::Add 0x140D29BA0** ([21]): rel+72 已置位 (cancel 标记) 不安装; 双侧 rs 经守卫
  安装器 sub_140D2D1D0 装 +744 (断言 :4111 同阵营 / :4115 自交; 体内腐局检查门 = ¬gs+2613, 世界构建期跳过同阵营查); gs+2617 (游戏内) ∧ ¬gs+2618
  (和平会议中) → **fire `on_war_relation_added`** (:603, 双 scope 按 +344 选侧)。gs 三旗语义
  (高置信): +2613 = 载入/重建期 (跳过阵营清理与断言) / +2617 = 游戏内事件可发 / +2618 =
  和平会议窗口 (Reset End 路径与事件均跳过)。
- SetDefender 0x140D2CEB0 补全: 按侧匹配反推 +344 (a2==first → +344=0 / ==second → +344=1)。

**CSubjectRelation (puppet) 补全 (定案)**: Add 本体 0x140D27BE0 (407 行; vtable[21] 包装 0x140D29630
先抓 subject 颜色快照 = CCountryColors+32/+64/+80 三段拷贝): 双侧摘旧 puppet → 双方非隐藏 war →
**CWarRelation::End + 双 dip 缓存重建 = 附庸化终止战争** → subject 阵营成员 (dip+152 名单) 逐个
摘其对 subject 的非隐藏 war → 流亡 host 处理 (dip+424) → 资源清理 → **subject 外交状态受控
Reset = sub_140D3A1B0 (CDiplomacyStatus::Reset 大拆卸: wargoal 清 / 逐 rs 调 rs::Reset(四参) /
离阵营 / 缓存日期流亡 access 全清; a2 = {keepWar?, keepCivilWar?, keepSubject?, keepFaction?}
选项块 + a2+4 = tag — 附庸化以 subject 关系旗字节 {+80,+81,+82} 作选项块 + 宗主 tag 调它,
保留项由旗决定; 原「自治旗传播」定性系函数体未读时误判, diplomacy.cpp 簇体读定案)** →
UI 刷新 → overlord 阵营逐成员处理 →
**sub_14118BA30(subject, overlord faction, 0, 1) = 附庸加入宗主阵营** → 双侧 +648 安装 + attitude
更新; **尾部双向战争同步循环 (定案, dump 直读)** = JoinWarCommit (reason=1, puppet) 双侧同步——
宗主当前全部活跃战争逐场拉 subject 入战, subject 侧同构反向, 保证附庸化后双边战争参与集一致。
**rel+82 = u16 新字段** (Add 本体读点; reader 无对应 token = 未序列化, 待裁)。reader
ParseToken 0x140D2B870 (vtable[4]): 776 → +96 / 14057 → +88 / 14111 → +88 (自治 def 按名查, 查无报
"Wrong autonous state name: %s!!!" :2744/2745; 两键分工待裁) / 19849 → +80 byte / 19848 →
+81 byte / default → 基 reader。

**rs::Reset 0x140D1E470 扩展 (书已收机制, 补证)**: 签名 (rs, keepWarRelations,
keepCivilWarRelations, &tag); war 保留判定 = 内战谓词 sub_140700600 受 keepCivilWar 门 /
常规谓词 sub_140700450 受 keepWar 门; 拆除路径 = RTDynamicCast 判 CWarRelation ∧ ¬gs+2618 →
vtable[22] + CWarRelation::End 0x140D1CC40 + sub_140E4C9E0 双向和会侧终战; 尾部 +784 = u16 0
(同时清 784 参战旗与 785) / +800 = u16 0x0100 (800=0, 801=1 = attitude 标脏待重算, 与
UpdateAttitude +801 脏旗相容)。

**rs 级阵营成员战争目标解析器 0x140D1E1C0** (rs 日更 sub_140D251B0 唯一调用; 体读定案, 业务名
推定): 属主与「对方」实为同阵营成员开战时 (断言 :4973 "I'm at war with a faction member of
mine!"), 统计属主阵营 (dip+656 阵营对象, 成员 data@+88/count@+100) 中对属主 vs 对对方持非隐藏
war 的成员数: 阵营多数打对方 ∧ (属主非 major cc+5210 ∨ 对方 major) → 战争目标改指对方国对象,
否则指属主; overlord 链 (cc+392) 收束 sub_14118BA30(宗主, 0, 1)。

**diplomacy.cpp 簇对账增补 (27 函数全读, 断言串口径 27/27 闭环)**: 本簇 = 外交状态维护层
(建战/参战/复国/阵营礼仪/日更/流亡/缓存重建), AI 决策走 CDiplomaticAction 命令通道落地才进本簇。
与 §4.10.2 关系槽的两层分工闭合: **access 四类关系 (mil/dock/offer dock/air) 各有 dip 级 tag 缓存
Add/Remove 八件** (Add = 线性 find-or-push, Remove = swap-remove + "Removed" 断言; 断言源行单调
752..813) — 维护的是 dip 级缓存, rs 槽本体走 SetRelation 换槽模板族。**新定案**:

- **on_war / on_peace 发射点 (定案)**: RebuildDipCaches sub_140D46650 尾 (gs+2617 门内), 交战国数
  (dip+164 建前快照) 0↔非0 翻转驱动 (:1488 on_war / :1494 on_peace); RebuildDipCaches = +152/+176/
  +248/+272/+296/+344/+792/rs+784 的唯一重建器; 变化时 cc+4320 |= 0xFFFFFFF (28 位外交脏掩码, 语义待裁)。
- **CreateWar 核心 sub_140D34EC0 增补**: 三重腐局门 (:3390 同阵营 / :3399 重复开战 / :3404 建战失败 /
  :3413 建成即消失 — **末者提示 on_war_relation_added 脚本钩子可取消战争**) → SetInstigator/SetDefender
  → 双侧 RebuildDipCaches → gs+2613 门内盟友通知环 → 尾 sub_1407050D0 (待裁)。**参战第二路径** =
  JoinWarCommit sub_140D406F0 (:3538 目标已在战门) + CanJoinCivilWar sub_140D39400 (修正 295 阈值
  qword_143333B68) — 与宣战侧拉盟 sub_141102580 互补 (join_allies/内战助战侧)。
- **复国 (uncapitulate) 双入口**: 独立体 sub_140D45D80 (DailyUpdate 可调) + RebuildDipCaches 内联;
  资格门 sub_140D39C00 = **原首都州 controller (state+204) ∈ {己, 同原初国 (sub_140BB52F0)} ∧ 投降进度
  sub_1406DA100 < qword_143333C18** (state+204 = 州 controller tag, state 表增补候选; 原首都无主
  controller==0 或被非同原初国占据 → 谓词恒真 = 维持投降); 恢复 = 清 dip+736 + fire on_uncapitulation
  (独立体 0x140D45D80, 门 = +736 置位 ∧ 资格门假, 断言 "trying to uncapitulate a non-existing country?"
  :1516; 发射器 = sub_140162FB0 管理器 → sub_140A792B0 名查表 → sub_140A79BA0 fire)。
- **proposed 条目 +16 = 过期时刻 (今日+expire, 非创建时刻)**: expire 三档 = call_allies(12233)/
  join_allies(13663) → dword_1433314A0 / request_equipment_purchase(13289) → dword_143331548 /
  其余 → 随机 [D, 2D); 插入去重键 = (action token@+32, actor tag@+0)。
- **流亡复国归还链**: ReturnFromExile sub_140D43B50 新增 = 开头重调工厂捐赠器撤净修正 292/293/294 /
  host 摘牌按 tag 相等 ∨ 同阵营双判 / **远征军归还** (两容器收集属主==己/同阵营 → sub_1406E6830
  一次性转出) / **海军转出专函数 sub_140D45680** (host 全阵营逐成员, 舰船按属主 tag@船+2052 过滤,
  逐船分离 + 任务群转出 sub_1406D2EC0, 失败日志 :3869) / cc+808 人力池减 cc+832 (推定)。
- **被俘将领三释放件** (dip+1000 容器 count@+1012, 元素 8B refid, 属主 tag @ char+288): 全释放
  sub_140D42C10 (:4198) / 非交战释放 sub_140D42F10 (:4221) / 按国释放 sub_140D42D70 (:4244);
  释放 = sub_140C22F80(g, 1)。
- **共享脏冲刷内联体**: 三消费点 (daily force=0 / 修正变化 force=1 / hourly) 携带同一
  sub_142234110(dip+828, "diplomacy.cpp", **:2297**, 0) 序列 — :2297 = 内联体行号 (collect-if-empty →
  逐个 UpdateAttitude → 清 +828/+840), 非 DailyUpdate 函数体独占。

#### 4.10.2a opinion 现算求和器 (sub_1406F44D0; country.cpp 1970 行; 定案)

**sub_1406F44D0(cc, to_tag, a3 文本, a4 文本, verbose, indent)** = 对 (cc → to_tag) 累加内置 opinion 项返**未钳位**总和; a3/a4 非空旁路装配逐项解释行 (a4 通道带 4 空格 indent 前缀)。消费双层 = sub_1406F3940 (opinion tooltip, rs+768 缓存 MISS 通道) / sub_140D2D8D0 (重算 → 钳 [MIN_OPINION_VALUE dword_143331754, MAX dword_14333169C] → 写 rs+768 → 尾调 sub_1407155C0, 语义未裁)。⚠ 项 modifier 数字 = **idb opinion modifier 定义 token id** (sub_140A81F20 查 TGameItemDatabase), 非 loc 键号。

| 项 | 门/公式 | modifier id |
|---|---|---|
| 交战基础 (赋值互斥非累加) | war = rs+744 非空 ∧ war+73 旗==0 → 赋值; else-if sub_140D24AC0 → 赋值 (均假 = 0) | 12673 / 13374 |
| 战时附加 ×3 | sub_140D24BD0 / D24C80 / D2D780 (n×值) (三件语义待裁) | 13372 / 13371 / 13373 |
| 同派系 | dip+656 派系成员数组 (d@+88, c@+100) 线性搜对方国对象 | 12674 |
| 执政党域 ×3 | 双方 cc+3984 politics+208; 13247 = 经 sub_1411A3300 返回子对象 +320 相等; 13248/13249 = party+24 直比相等/不等 (待裁) | 13247-13249 |
| 傀儡/敌友 | sub_140D25830 (§4.10.7); 14555 = sub_140D24860(对方 rs); 14556 = 遍历 dip+152 enemies 任一满足 (共同敌人; D24860 待裁) | 13254 / 14555 / 14556 |
| 双日期衰减 | rs+120 与 rs+144 均 ≠ 43808760 哨兵 → (两日期月数和) × 值 | 13253 |
| 租借装备 | leased = sub_140D240F0(rs); ratio = rnd1e5(1e5·leased ÷ (1e5·MAX_REMEMBERED_LEASED_IC dword_1433373A8)); += rnd1e5(ratio × MAX_OPINION_FOR_LEASED_IC dword_14333742C); 键 DIPLOMACY_OPINION_LEASED_EQUIPMENT | — |
| 志愿军 | n = 宿主国 +784 volunteers_sent 计数 (元素 CID → CUnit, **CUnit+480 = owner 派遣国** == 我) + +5040 volunteers_transfer (源 == 我; 师数 = 元素+28); v = rnd1e5(1e5·OPINION_PER_VOLUNTEER qword_143337568·n) 钳 MAX_OPINION_FROM_VOLUNTEERS dword_143337600; 键 DIPLOMACY_OPINION_SENT_VOLUNTEERS | — |
| 民主 WT | *(party+24)+1570 旗非 0 → wt = sub_1401DB350(gs, &out, to_tag) (>0); += rnd(wt × OPINION_FOR_DEMO_FROM_WT_GENERATION qword_143337698 ÷ 1e5); 键 DIPLOMACY_OPINION_FOR_DEMO_FROM_WT_GENERATION | — |
| _Relations 列表 | rs+208 (count +220) 元素 r: r+20 tag 匹配我方 (== ∨ sub_140BB52F0) → 定义 = sub_140A81F20(idb, r+8), def+121 旗 0 才累加 sub_140A81FE0 | — |
| opinions 列表 | rs+256 (count +268) 元素 e: def = e+40, def+121 旗 0 → += sub_140A81F40(e) | — |

新偏移注记: rs+120/+144 双日期槽 (高置信, 写入方未决); war_relation+73 u8 旗 (推定 = 战争有效/非和会中门); CUnit+480 owner tag (推定); CPoliticalParty+24/+320 (待裁)。

#### 4.10.3 关系对象基类 (rel) 与落盘规则

关系对象 = relations {d@rs+232, c@rs+244} 8B 指针数组, 元素基址 rel; 基类 writer sub_140D2DAA0 (全 11 型共用)。

| 偏移 (rel) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | uint32 | first_idx | |
| +20 | uint32 | second_idx | |
| +21..+31 | — | = first_idx@+16 / second_idx@+20 尾 + start CGameDate {vtable1@+24, hours@+32, vtable2@+40} 头 (ctor 0X140D17AB0: `*(+32)=43808760`, `+24/+40=CGameDate::vftable`) | |
| +32 | hours | start | CGameDate 槽@+40, 族A |
| +33..+55 | — | = start 日期 {hours@+32 尾, vtable2@+40} + end CGameDate {vtable1@+48, hours@+56, vtable2@+64} 头 | |
| +56 | hours | end | CGameDate 槽@+64, 族A |
| +57..+71 | — | = end 日期 {hours@+56 尾, vtable2@+64} + cancel u8@+72 前 pad | |
| +72 | uint8 | cancel — **+73 uint8 = 基类 CRelation 级「隐藏/抑制关系」门**: writer 不发射/parser 不装载/运行时零写点 (59 处全局 +73 写点逐函数过筛无一属关系族, 仅基 ctor `*(_WORD*)(a1+72)=0` 随 cancel 清零, 本 build 恒 0 预留死字段); 读点约 12 函数全经 rs+744 解引, 极性一致「置位=视同无此战争/关系」, sub_140D39900 对 guarantee 关系同查 +73 证基类通用门; 业务名高置信 = hidden relation | |

落盘规则 (全 11 型通用):

| 规则 | 内容 |
|---|---|
| war 挂载点 | rs+232 容器 (运行时探针定案); 运行时 token@+8 = 14346 "war_relation" (与存档同名), 非 writer 侧 10637 "war"; 单侧挂载 (每对仅 1 例, 如 JAP→CHI 挂 JAP 侧) |
| end_date 通用门 (全 11 型通用, 非 nap 专有) | `i32@(rel+56) > i32@(rel+32)` 才写 end_date (end_hours > start_hours); 无哨兵比较; 未设 (0 ≤ start) 不写 |
| cancel 互斥 | `ru8(rel+72)≠0` 时写 cancel=yes **且 start_date 不写** (互斥) |

**Relation 工厂 0x140D1EE80** (存档 reader/运行时 clone 型分发: switch(token) → malloc + 基 ctor 0x140D17AB0(this, token) + 装 vtable):

| 类 | vtable | token | sizeof | 扩展 |
|---|---|---|---|---|
| CGuaranteeRelation | 0x1429607C8 | 10458 | 80 | 无 (rs 槽 +656/+664, Add 方向实证 first→+656/second→+664) |
| CNonAggressionPactRelation | 0x142960888 | 12220 | 80 | 无 (rs 单槽 +720; 槽[10] = ret1) |
| CMilitaryAccessRelation | 0x142960408 | 10548 | 80 | 无 (rs 槽 +672, 与 offer 共槽族) |
| COfferMilitaryAccessRelation | 0x1429604C8 | 12232 | 80 | 单继承 CMilitaryAccessRelation, 只换 token |
| CDockingRightsRelation | 0x142A21928 | 15098 | 80 | 无 (rs 槽 +688/+696) |
| COfferDockingRightsRelation | 0x142A219E8 | 15099 | 80 | 单继承 CDockingRightsRelation |
| CAirBaseAccessRelation | 0x142A21738 | 10298 | 80 | 无 (rs 槽 +704/+712) |
| COfferAirBaseAccessRelation | 0x142A217F8 | 10325 | 80 | 单继承 CAirBaseAccessRelation |
| CNavalBlockadeRelation | 0x142A21AD0 | 10232 | 80 | 无 (rs 槽 +608/+616; 槽[10] = ret1; 工厂 if-chain 头部分支 → ctor 0x141981B70; Add/Remove = internationalmarket TU 0x141981C60/0x141981BD0, rs 槽维护仍经 swap 族) |
| CLicenceProductionAccessRelation | 0x142960348 | 19331 | 80 | 无 (rs 槽 +728/+736) |
| CEmbargoRelation | 0x142960B60 | 12916 | 80 | 无 (方向落 rs+752/+760; Add 0x140D28480 含已 embargo 查重) |
| CBoostPartyPopularityRelation | 0x142960708 | 12525 | 88 | **+80 = CIdeology\*** (writer 0x140D2DA60 自有, 键 ideology=11838 = u32@(*(rel+80)+8); DB = 0x332EF38; rs 槽 +536/+544) |
| CImproveRelationsRelation | 0x142960588 | 11479 | 96 | +80 qword / +88 i32 (工厂 sub_140D1EE80 case 11479 定形态: +80 初 0 / +88 初 −1 哨兵; **+88 运行期无写者, ≥0 停止分支不可达**; 无自有 writer/reader, 不序列化; rs 槽 +504/+512) |
| CAttacheRelation | 0x142960648 | 14553 | 136 | **+80 内嵌 CCommandPowerAllocator 56B** (ctor 0x1414E6F40 挂 qword_143334350 参数源; 不序列化; rs 槽 +520/+528) |

| NInternationalMarket::CEquipmentPurchaseRelation | 0x142A21BB8 | 13288 | 80 | 无 (rs 槽 +624/+632 成对; 槽[10] = ret0) |
| NInternationalMarket::CMarketAccessRightsRelation | 0x142A21C80 | 13696 | 80 | 无 (rs 单槽 +640; 槽[10] = ret1) |

**槽[10] 覆写分布 (定案)**: CRelation[10] = purecall (0x14253C3B8); 覆写为 ret1 (0x1401807B0) 的共 **4 类** —
CNonAggressionPactRelation / CMarketAccessRightsRelation / CWarRelation / CNavalBlockadeRelation
(PE vtable 0x142A21AD0 槽[10] 直读); 其余全族覆写为 ret0 (0x14011D220)。

同族顺带: CLendLeaseRelation (12618, 80B, vtable 0x142960948, **零扩展定案**) / CSubjectRelation
(12497, **vtable 0x142960A08, sizeof 104B**, §4.10.7) / CWarRelation (14346, §4.10.4)。工厂分支结构
= if-chain (10232/10298/10325/15098/15099) + switch 其余, 未命中 token 返 0。

#### 4.10.4 war 关系对象 (wr)

war 关系对象 (运行时 token@+8==14346 "war_relation"; writer sub_140D2DE80 先调基类); 基址 wr。
**CWarRelation vtable 0x142960288 / sizeof 464B** (工厂 malloc 直证); 无独立「CWar」聚合类 — 战争 = 挂 rs+744 的双边对模型, 多国战争 = 多条 CWarRelation; UI「一场战争」= dip+792 聚合视图。
**宣战链**: CDeclareWarAction::Apply sub_141105A00 → 参战方构建 sub_141102580 (沿宗主链上溯) → rs+744 已有且 +73 未置则复用; 创建核心 sub_140D34EC0 (diplomacy.cpp:3390 同阵营战争断言) → rs vtable[21] AddRelation (工厂 14346) → **SetInstigator sub_140D2D000 (写 wr+344/+352) / SetDefender sub_140D2CEB0 (写 wr+344/+348)** (relation.cpp:824/848) → 双侧 dip 缓存重建 sub_140D46650。
**终结三路径**: 和会 EndWarsTerminate 0x140E41F70 / 白和平 = CWhitePeaceEffect::Execute sub_140368F10 (scope(2,2) factor 0 立即结算和会 sub_140BBEAD0) / 吞并 = CAnnexCountryEffect::Execute sub_14034D880 → CCountry::Annex sub_1406D3F00 → 逐敌 sub_140D1CC40。**sub_140D1CC40 = CWarRelation::End** (双侧 rs 各调 sub_140D1C9F0 → wr vtable[22] Remove 自摘); sub_140D1C9F0 = rs 侧终战清理: flag=1 → **rs+168 truce_until.hours = 当前日期 + dword_143331800 停战时长 define**; 通知属主; rs+552/rs+560 租借槽族逐个 Remove (**战争结束解除租借**)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +80 | int64 | first_casualties | **原值不缩放**, 恒写 |
| +88 | int64 | second_casualties | **原值不缩放**, 恒写 |
| +96 | int64 | first_unknown_casualties | 恒写 (0 也写) |
| +104 | int64 | second_unknown_casualties | 恒写 (0 也写) |
| +112 | 内嵌 112B | war_score_first_vs_second (writer 0X14117B070) | 恒写块 — 112B 子对象全宽, 无独立字段 (布局见 §4.10.5) |
| +224 | 内嵌 112B | war_score_second_vs_first | 恒写块 — 同上 (112B 全宽; 定案) |
| +336 | fixed×1e-5 | threat | 恒写 (0 也写) |
| +344 | uint8 | first_was_instigator → yes/no | 恒写; GUI: instigator/defender 选择子复用 (sub_140D230C0/D0D960) |
| +348 | int32 | hostility_reason_defender 枚举 (§4.10.6) | ≠6 才写 |
| +352 | int32 | hostility_reason_instigator 枚举 | ≠6 才写; ⚠ **+352=instigator / +348=defender** (writer 先读 +352)。⚠ 执行侧 SetInstigator sub_140D2D000 (断言 :824) 体读 = +352 无条件写, `==6` 判定施于 +348 (命中 6→5 迁移) — 与 writer 门「≠6 才写」的关系 (两路并存/门挂错偏移) 待裁 |
| +360 | idpair | first_wargoals 容器数据指针 — {d@+360, cap@+368, c@+372}, 元素 8B 紧致对 {type u32@+0, id u32@+4}, 非指针; 写形 `id=N type=T` 多重集 | c>0 (cap 槽已知) |
| +372 | uint32 | first_wargoals 容器计数 | c>0 |
| +384 | idpair | second_wargoals 容器数据指针 — {d@+384, cap@+392, c@+396} 同上 | c>0 (cap 槽已知) |
| +396 | uint32 | second_wargoals 容器计数 | c>0 |
| +408 | CWargoal* | wargoals 容器数据指针 — {d@+408, cap@+416, c@+420} (token 13085): CWargoal 指针, 动态 token@元+48 | c>0 (cap 槽已知) |
| +420 | uint32 | wargoals 容器计数 | c>0 |
| +432 | MSVC 串 | **战争名串** ({data, cap@+456=15}; 形态定案/语义推定) | |

CWargoal 落盘槽 (wg 基址; 与上表 wr 异基):

| 偏移 (wg) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +120 | tag_id | puppets 容器数据 (4B tag id 元素; GER→BEL puppet_wargoal_focus 首例) | c>0 |
| +132 | uint32 | puppets 容器计数 | c>0 |

CWargoal 元素细部 (元素基址 e; CWarGoal 全布局, vtable 0x1429E0058; writer 0x1415E0C20 / reader 0x1415E08F0; inner 亚对象 @e+56; dtor 0x1415DE530 从每州反引表 {d@state+128, c@+140} swap-remove 摘除):

| 偏移 (e) | 类型 | 名称/语义 (键 token) | 写门 |
|---|---|---|---|
| e+24 | CGregorianDate 24B | 创建日期 (gate: hours@+32) | — |
| e+40 | date 对象 24B 尾段 | expire (12277): gate = hours@+32 − 43800000 ≥ 17520 (创建 2 年后才写) | gate |
| inner+0 | tag CRef | wargoaldata_actor (13376) | 恒写 |
| inner+4 | tag CRef | wargoaldata_recipient (13377) | 恒写 |
| inner+8 | CWarGoalType* | type (225): 经 CWarGoalDatabase (0x332EF28) 解析, 写 *(def+8) | 恒写 |
| inner+16 | CState** vec | take_state_focus.states (11835): {d@e+72, cap@e+80, c@e+84, alloc@e+88} — ptr 元素 → state id u32@ptr+88; 单行空格连接 | c>0 |
| inner+40 | u32 vec | liberate (12496): {d@e+96, cap@e+104, c@e+108, alloc@e+112} | c>0 |
| inner+64 | u32 vec | puppets (12582): {d@e+120, cap@e+128, c@e+132, alloc@e+136} | c>0 |

⚠ 元素门 = CState vtable 精确匹配 0X2936CC0 且 id≠0 (尾槽 id=0 / 悬垂槽首 qword 恰落模块区间曾出垃圾 id 51112 — 模块范围门不够, 须精确 vtable)。

#### 4.10.5 war_score 子对象 (ws)

war_score 子对象 (实名 **CWarScoreBreakdown**, vtable 0x142960128; writer 0x14117B070 / reader 0x14117AD10): ws = wr+112 或 wr+224; vtable 槽1 = 0X14117B070。键 token: first=10462 / second=10463 / equipment_damage=14358 / province_capture=14359 / air_damage_str=13622 / strategic_air=12247 / sunk_ship=11928 / convoy_attack=11970 / casualties=13394 / lend_lease_sent=14483 / lend_lease_received=14484 / captured_provinces=12513。

| ws 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | first | idx>0 (实恒写) |
| +12 | uint32 | second 国家 idx → tag 引号 | idx>0 (实恒写) |
| +16 | fixed×1e-5 | equipment_damage | **全恒写 (0 也写)** |
| +24 | fixed×1e-5 | province_capture | 同上 |
| +32 | fixed×1e-5 | air_damage_str | 同上 |
| +40 | fixed×1e-5 | strategic_air | 同上 |
| +48 | fixed×1e-5 | sunk_ship | 同上 |
| +56 | fixed×1e-5 | convoy_attack | 同上 |
| +64 | fixed×1e-5 | casualties (i64, 占 +64..+71) | 同上 |
| +72 | fixed×1e-5 | **casualties 第二槽 = 本国 unknown casualties 折算分** (勘误定案: 旧记「对齐填充」系误 — sub_141179D90 写 / sub_14117ACB0 读 / sub_141179490 合并 max; **运行时字段不落盘**, writer 不写故存档侧仍呈填充) | 新验 (dump 三函数直读) |
| +80 | fixed×1e-5 | lend_lease_sent | 同上 |
| +88 | fixed×1e-5 | lend_lease_received | 同上 |
| +96 | std::map 头 | captured_provinces std::map 头 (节点 key u32@+28, **值不写 (set 语义)**; 中序 = 升序 = 存档序) | |
| +104 | u64 | captured_provinces std::map size | size≠0 |
| +120..+131 | — | 壳侧向量 {data@壳+120, count@壳+132} (壳 = winner 元素e, 即 e+248{d}/e+260{c}) 的**转发槽** — 本内层对象不带该向量 | |
| +144 | uint32 | 壳字段 total_score_before (= e+272), 不在内层 vtable 门内, 写者与 total_score_before 同函数 | 恒写 |

**redistributions** (壳层向量, 非本对象内层): 形 = 壳 e+248{d}/e+260{c}, 16B 元
{reason u32@+0, points **i32**@+4} (points 可负, 活体实测 {3,3}/{3,-1}); writer
`sub_1419848B0` (tok 14497 门 count≠0; 匿名块 #1.. 恒编号, 块内 reason/points 两叶);
与 total_score_before (tok 14498) 同函数相邻发射 — 「玩家在战争中把战争分数重新分配给
盟友」的记录。〈定案: 活体合成+存档对拍双证〉

视角归一:

| 子对象 | first_idx 对应 | 读取侧 |
|---|---|---|
| ws@wr+112 | wr first_idx (wr+16) | 各按子对象自身 +8/+12 出数, 不做任何交换 |
| ws@wr+224 | wr **second**_idx (wr+20); 视角互换由引擎在子对象内完成 | 同上 |

first_* 字段一律以 wr+16 为 first。

#### 4.10.6 hostility_reason 枚举

writer switch 实证; 裸名 (bare token) 无引号。

| 值 | 名 |
|---|---|
| 0 | war (10637) |
| 1 | puppet |
| 2 | ally |
| 3 | asked_to_join |
| 4 | guarantee |
| 5 | not_applicable |
| 6 | (不写) |

#### 4.10.7 puppet 关系 (token 12497)

writer sub_140D2DE20, 专有叶先于基类。

| rel 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +80 | uint8 | 自治关系旗 A (ctor 默认 1; set_autonomy 写 — 推定) | |
| +81 | uint8 | 自治关系旗 B (ctor 默认 1; 与 +80 同元 0x0101 — 推定) | |
| +88 | CAutonomousState* | autonomy_state → MSVC 串@obj+8 引号 | ptr≠NULL; def 对象 (名 MSVC@obj+8) |
| +96 | fixed×1e-5 | value | **raw≠0 才写** |
依赖描述符 (关系条目 +648 指向; 定案): {+8 token 12497 "puppet", +16 宗主 tag, +20 附属 tag}; 判定 sub_140D25830 (条目 +648 描述符与 +80 比对, loc 因子 DR_THEM_PUPPET, 45 调用者全 GetAiAcceptanceFactors)。

#### 4.10.8 proposed 外交行动条目

proposed 外交行动条目 (40B; action token 10546 系)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | uint32 | index |
| +4 | pad | 对齐 (定案) |
| +8 | CGameDate vtable | date 对象基 (定案; date 对象 24B) |
| +16 | hours | date |
| +24 | greg vtable | date 对象子 vtable |
| +32 | uint32 | action (token → 名) |
| +36 | pad | 对齐 (定案) |

#### 4.10.9 CCurrentAutonomyStatus

CCurrentAutonomyStatus (dip+848; writer 0X14067AA30)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | fixed×1e-5 (int64) | progress (i64; AddAutonomyScore 钳 [+56-margin, margin++72]) |
| +16 | 匿名结构 (含 SSO) | path 容器数据指针 — {d@+16, cap@+24, c@+28, alloc@+32}; 元素 = 名 (SSO@+8); cap/alloc 新增 |
| +28 | uint32 | path 容器计数 |
| +29..+39 | — | = path 容器 {d@16, cap@24, c@28, alloc@32} 的 count 尾 (29..31) + alloc@32 (pdx 24B) |
| +40 | CAutonomousState* | current_state; def 对象 — **GUI: 附庸关系条自治档位** (CSubjectRelationstripView 命中; loc AUTONOMY_RELATION_DESC/DESC2 + "GFX_\<level\>_icon" 图标链) |
| +48 | CAutonomousState* | prev_state; def 对象 |
| +56 | fixed×1e-5 (int64) | **progress 下界基 (min bound)** (getter 0X1406774A0) |
| +57..+63 | — | = progress 下界基 i64@56 的尾字节 (56..63 为一个 8B 定点) |
| +64 | CAutonomousState* | next_state (名 SSO@+8); def 对象 (名 SSO@+8) |
| +72 | fixed×1e-5 (int64) | **progress 上界基 (max bound)** (getter 0X140677390) |
| +73..+95 | — | = 上界基 i64@72 尾 (73..79) + qword@80 (ctor 未命名, 未序列化) + **last_change CGameDate {vtable1@88, hours@96, vtable2@104}** 头部 (writer 0X14067AA30 `ADEC0(a2,0x431D,a1+104)` 直证) |
| +96 | hours | last_change |
| +97..+111 | — | = last_change 日期 {hours@96 尾 97..99, pad 100..103, vtable2@104..111} |
| +112 | 匿名结构 (64B) | effects 容器数据指针 — {d@+112, cap@+120, c@+124, alloc@+128}; 元素: value i64@+0 (raw 读法 = lo+hi×2^32 符号化, 勿转浮点 — Lua 5.4 `format("%d")` 崩), desc SSO@+8, hash u32@+40, hours@+56; cap/alloc 新增 |
| +124 | uint32 | effects 容器计数 |

CAutonomousState def 侧补行 (def 库 = **0x332EE18** (qword_14332EE18, §4.26 autonomous_state key; 旧引 qword_14332EE18 在 1.19.3 无命中); 形态 {data@+48, count@+60}; 条目 +40 hash / 名串 @+8..+24):

| 偏移 (def) | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +1544 | int64 | min_freedom_level (× qword_1433339F8 = AUTONOMOUS_TOTAL_SCORE /100000 缩放; §4.10.9 顺序重算边界基) | 定案 |

#### 4.10.10 CPolitics (ps)

| 项 | 值 |
|---|---|
| 挂载点 | `*(cc+3984)` (ps; 外层键 12282 `politics`) |
| RTTI 名 | CPoliticalStatus (§3.9) |
| vtable RVA | 0X294FDA8 |
| sizeof | 0x110 = 272B (ctor 0x140BA6EF0) |
| writer | 0x140BB0520 (vtable[2]) |
| loader | 0x140BAD850 (vtable[4]) |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CTimedStageCoupActivity* 向量 | **timed activities** (政治限时活动: 战目标辩护/政变/装备分发) {data@+8, cap@+16, count@+20, alloc@+24} — 元 = 动态 token@元+8 对象 (工厂 sub_140AD7DD0 产 CTimedStageCoupActivity 等) | writer 键 0x3408 |
| +32 | CPoliticalParty** | parties 容器数据指针 — {d@+32, cap@+40, c@+44, alloc@+48} | 元素见 §4.10.11 (cap/alloc 新增); GUI: 政党饼图源 (C2dPieChartTemplate; party+136 popularity 顶点 + 色 sub_1411A4780(party)+16) |
| +33..+43 | — | = parties 容器 {d@32, cap@40, c@44, alloc@48} 的 data 尾 (33..39) + **cap@40..43** (ctor 0X140BA6EF0) | |
| +44 | uint32 | parties 容器计数 | 元素见 §4.10.11 |
| +45..+55 | — | = parties count@44 尾 (45..47) + **alloc@48..55** | |
| +56 | CIdea* 向量 | **可用理念缓存 CIdea\* 向量** {data@+56, cap@+64, count@+68, alloc@+72} (定案): AddParty 0X140BAE830 第二循环遍历 **CIdeaDatabase** (qword_14332EF30, ctor sub_140A3F6E0 vftable 直名) 填充, 元素门 `*(idea+56)` 旗与 CIdea ctor 0X140FCCEA0 同位互证; 同函数第一循环 = CIdeologyGroupDatabase → parties@ps+32; 不序列化 | GUI: 理念窗候选向量 = ps+80 ideas 与 ps+56 拼接 |
| +73..+79 | — | = 可用意识形态容器 {d@56, cap@64, c@68, alloc@72} 的 count 尾 (69..71) + **alloc@72** | |
| +80 | CIdea** | ideas 容器数据指针 — {d@+80, cap@+88, c@+92, alloc@+96} (定案) | cap/alloc 新增; GUI: 理念窗 (CPoliticalIdeasWindow: 候选向量 = 本表 + ps+56 拼接; SetTarget sub_141582ED0 assert politicalideaswindow.cpp; 宿主 CCountryPoliticsView+31296) **+ 可选理念装备判定** (CPoliticalSelectableIdeaItem) **+ 精神窗** (CSpiritItemWindow) |
| +92 | uint32 | ideas 容器计数 | |
| +104 | 匿名结构 (24B 形状) 向量 | **timed_ideas** {d@+104, cap@+112, c@+116, alloc@+120} 24B 条 = **CTimedIdea** {vtable, CIdea*@+8 (名=token@idea+8), days u32@+16} (定案; writer 键 13420; "Invalid timed idea in savegame" 互证; 类级卡 §4.8.12) | cap@+112 新增 |
| +121..+127 | — | = timed_ideas 容器 {d@104, cap@112, c@116, alloc@120} 的 **alloc@120 尾字节** (117..119 count 尾 + 120..127 alloc) | |
| +128 | {CIdea*, CIdeologyGroup*} 16B 结构* 向量 | **per-ideology-group 槽位表** {data@+128, cap@+136, count@+140, alloc@+144} — 8B 元 → 16B 结构 {CIdea* 槽位当前占用理念, CIdeologyGroup* 组} (AddParty 尾按组数扩容 malloc(0x10) 填; 消费 0X140BA92B0 换装费用链: 门 = 组+16 u8 旗, 取 `ps+128[组+92−1]` 条目, 首字段按 CIdea* 消费 — +56 有效旗 / +2736 removal_cost / +2752 level 三偏移直证 (CIdeology 320B 容不下 +2736), 次字段经 sub_1401AD740 取组内理念表累加新旧 level 之间各级 removal_cost) | 定案 |
| +145..+151 | — | = per-ideology-group 容器 {d@128, cap@136, c@140, alloc@144} 的 count 尾 (141..143) + **alloc@144** | |
| +152 | CGregorianDate 24B | **last_election** {vtable@+152, hours@+160, greg vtable@+168} (writer 键 0x2BDD; 定案 — 书内 i32@+160 互证) | |
| +169..+175 | — | = last_election CGameDate {vtable@152, hours@160, greg vtable@168} 的 **vtable2@168 尾字节** | |
| +176 | CGregorianDate 24B | **next_election** {vtable@+176, hours@+184, greg vtable@+192} (推进 = politics.daily 内联: elections_allowed ∧ now ≥ next → on_new_term_election → last=now, next += frequency 月; writer 不写) | **GUI: 选举行** (门 = ps+236 elections_allowed && ps+232 election_frequency>0 → `elections` 显隐 + 日期; POLITICS_NEXT_ELECTION / POLITICS_NOELECTIONS) |
| +193..+199 | — | = next_election CGameDate {vtable@176, hours@184, greg vtable@192} 的 **vtable2@192 尾字节** | |
| +200 | CCountry* | **属主国回指** (AddPoliticalPower 打印国名 — **双变体**: :1602 i64 溢出守卫版 [daily/活动收取主路径] + :1623 直加版 [效果/命令侧]; 共钳位 POLITICAL_POWER_LOWER_CAP/UPPER_CAP 两 define 注册串直证) | |
| +201..+207 | — | = **属主国回指 CCountry\*@+200** 尾 7B (ctor `*(+200)=a2`) | |
| +208 | CPoliticalParty* | ruling_party 指针 (定案) | **GUI: 执政党块** (sub_1415F5960: sub_1411A3300 → leader 名 sub_140FCB280 / 像 sub_140B47270 → leader_name / leader_portrait; 无 → GFX_leader_unknown) |
| +209..+223 | — | = ruling_party 指针@+208 尾 7B (209..215) + qword@216 (**死字段负定案**: ctor/Reset 清 0, 全语料零业务读写) | |
| +224 | fixed×1e-5 | political_power | |
| +232 | uint32 | election_frequency (ctor/Reset 默认 48 月; 键 12281) | |
| +236 | uint8 | elections_allowed (ctor 默认 1; 键 12299 yes/no) | |
| +237 | uint8 | **parties 构建完成旗** (0 时国初始化先 Reset 再重建; AddParty 构建完置 1, Reset 清 0) | 定案 |
| +240 | 匿名结构 (16B) | **boost::signals2::signal<void()> 外壳头** (dtor sub_140150FB0 = signals2 析构, 含 signal_base vftable 与 shared_ptr 控制块释放; ctor +240 = &off_142718900 空哨兵) | 定案 |
| +256 | boost::shared_ptr | **同一 signal 的 shared_ptr\<signal_impl\>** (+256 px/+264 pn; 控制块 vtable RVA 0x271F648, RTTI `sp_counted_impl_p<signal_impl<void(), optional_last_value<void>>>`); 业务语义 = **PP 变动通知** (发射点 = AddPoliticalPower ×2 / SetPoliticalPower 尾 sub_14032F840); MIO listenable 说系误记 — COrganisationListWindow 信号签名 void(COrganisationListWindow const&) 且宿主在 cc+3944 MIO 管理器域 | 定案 |
| — | ⚠ | **dip = `*(cc+3976)` / ps = `*(cc+3984)` 相邻 8B 两对象, 勿混** — 二者各持同名族容器且偏移仅差 8 (如双方各有 docking-rights 四元组), 取错基址会读到另一对象的容器 | 陷阱 |

> writer 落盘序 (9 键): parties 12280 (count>0) / ideas 12271 (count>0, 元内副键 18 slot 名族) / timed_idea 13420 (count>0) / timed_activities 13320 (count>0) / ruling_party 12296 (ptr≠0) / last_election 11229 (恒写) / election_frequency 12281 (恒写) / elections_allowed 12299 (恒写) / political_power 12318 (恒写)。reader 另有 12569 occupation_policy 显式跳块分支 (旧档兼容不装载); ruling_party 按 ideology token 在已建党列表查, 查不到报 "Unable to find ruling party"。行为链: 每日 PP 增益 sub_140BA9420 = (BASE qword_1433333D0 + mod37)×(mod39+100000)/100000 + timed activities 贡献 (**收取入账走 :1602 守卫版** — 活动失效判定 = vtable+96 / 完成 = vtable+120→vtable+112); 选举周期 daily 内联推进 (:491 on_new_term_election 发射点); 政变 SetRulingParty sub_140BAD750 60/40 算法 (新执政党 6e6, 余党均分 4e6/(N−1)) + 执政党变更通知 sub_140BAD510 (阵营同步判据精化 = members[0] tag 相等 ∨ 同阵营; 尾段 = on_ruling_party_change_immediate 发射 :1637 + temp_var:old_ideology_token = 旧组 token×1e5 + 48B 消息件入队); **popularity 每日重归一**: :1691/:1697 断言在 politics.daily 内联, 归一 (差额补最大党) 在支持度核 sub_140BA7770 收尾, 提交器 = **sub_1411A5EA0 = CPoliticalParty::SetPopularity** (party+136 直写 clamp [0,1e7] 替换非累加); sub_140BA8FC0 = parties 收集器; 支持度计算核 = sub_140BA7770 (公式定案, politics.cpp:1770/1781 断言): mdef253 MASTER_IDEOLOGY_DRIFT overlord 门 + 重分配核 ÷1e5 magic + 归一补最大党, 分档缩放 sub_140BA9100 七档 (PE 逐一验证, 日更主路径同走); 校验断言 = TotalPopularity==100 ∧ PopularityChange ∈ [0,100]。
> **理念过期通知接缝**: `politics.daily` 的 `sub_140BA8300` (断言串 `politics.cpp` + `"politics.daily"`) 在理念过期时
> `malloc(0x5A8)` + ctor `sub_14192F2E0` 建 `NNotification::CIdeaExpiredNotification` 并经
> `sub_141391400(iface+1240, obj)` 入队 (详见 §4.17.4); 同段紧邻 `*(v54+1204)` = 接口处理器 +1192 历史容器 count
> (216B 记录, tag=12)。

CIdea (理念 def; 库 = CIdeaDatabase qword_14332EF30) 完整布局定案见 §4.10.12a
(traits 元素 = CTrait\* 对象指针, 定案见 §4.10.12a; +2816 计数在 +2828)。

#### 4.10.11 CPoliticalParty (party 条目)

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | ideology (token) |
| +9..+15 | — | = ideology token@+8 尾 7B |
| +16 | CCountry* | **属主国指针** (ctor a2; 高置信) |
| +24 | CIdeologyGroup* | **所属意识形态组** (ctor a3; GetParty 比对; **GUI: 意识形态图标/名** — sub_140B48C70 / 140B376B0 / 140616BC0: +8 组 id → ideology_ico / ideology_name / party_name) |
| +32 | uint32 | **属主国 idx** (ctor tag idx) |
| +33..+39 | — | = 属主国 idx u32@+32 尾 7B |
| +40 | string (SSO) | name |
| +41..+71 | — | = name SSO 32B 本体 (buf@40 尾 + size@+56 + cap@+64=15; 标准 MSVC 串) |
| +72 | string (SSO) | long_name |
| +73..+103 | — | = long_name SSO 32B 本体 |
| +104 | uint8 | default_flag |
| +112 | 匿名结构 (leader 条目) | country_leaders 容器数据指针 — {d@+112, cap@+120, c@+124, alloc@+128}; 元素: char id 对 = `((e+8)+8)` {type lo, id hi}, **subideology = *(CIdeology\*)@(e+320)** (名串 @CIdeology+16; 高置信); cap/alloc 新增; **GUI: ideology_ico 有领袖分支引用门** (party+112 引用槽 + party+124 有效门 → CCountryLeader → sub_140B48C70 取其 +16 SSO 名拼 `GFX_ideology_<名>[_<TAG>]`) |
| +124 | uint32 | country_leaders 容器计数 (= "leader_count" 别名; writer 以 *(a1+124) 为循环上界) |
| +125..+135 | — | = country_leaders 容器 {d@112, cap@120, c@124, alloc@128} 的 count@124 尾 (125..127) + **alloc@128..135** |
| +136 | fixed×1e-5 | popularity — **GUI: 政党饼图顶点值** (political_pie_chart; Σ=1e7 归一; GER 十党实测) |
| +144 | 内嵌 CRule | **党派规则覆写对象** (ctor 装 CRule vtable; SetPartyRule 0X1411A3630; 内含 28 槽 ×32B 串数组 @对象+120, 与 rs rule_overrides 同族; 形态定案) |

#### 4.10.12 CIdeology / CIdeologyGroup (意识形态 def 与组对象)

**CIdeology** (意识形态 def, 320B; ctor 0X141190B80; 库 = CIdeologyDatabase 子库 (组库 ctor sub_140A459B0 内 malloc(0x80) 创建, qword_14332EF38 = 组库 CIdeologyGroupDatabase 全局; qword_143339D00 = TNullObject<CIdeology>)):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | — |
| +16 | MSVC 串 | name |
| +48 | int32 | id (−1) |
| +64 | CModifier 192B | modifier (定案: +64..+255) |
| +256 | CColor | color (16B 内嵌投影, 见 §4.00.10) |
| +288 | CIdeologyGroup* | **所属意识形态组指针** (start_civil_war 组 B 解析直证: *(ideology+288)) |

**CIdeologyGroup** (组对象; party+24 所指, 每党一独立组时各自成组; vtable 0X14293C680,
ctor sub_141190D90; 库 = CIdeologyGroupDatabase qword_14332EF38)。下表偏移相对**组对象自身**;
fac 侧落点 (fac+96/+1120/+1152/+1344) 见 §4.5.7。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | token id | **组名 token** (CPersistentWithToken 基座; 基 ctor 先置 357=none, 本类 ctor 覆写 = a2) |
| +20 | token id | **组名 token** (ctor 同参 a2 双写, 与 +8 同命名空间同值 — 定案) |
| +24 | SSO 串 | 组名串 = token_name(a2) |
| +56 | u32 | 组 id 候选 (loc 取值 GetPartySupport 比对键; 语义待裁, §4.19.2a) |
| +64 | int32 | 装载序 (ctor −1; 装载后循环赋 0..n) |
| +1536 | uint32 | **`<ideology>_drift` 的 modifier def 索引** (该意识形态每日支持率变化; 探针 totalist=844 … national_populist=871) |
| +1544 | uint32 | **`<ideology>_drift_from_guarantees` 的 modifier def 索引** (846/849/852/855/858/861/864/867/870/873) |
| +1589 | uint8 | 执政党组旗 (compare_ideology_with_faction 短路返 1; 名未名, 推定) |

两索引 = GetPopularityTooltip 的取值来源 (def 名 = 游戏内 `GAME.layout.modifier_token(idx)` 反查 + KR loc); drift 分档缩放见 §4.10.15。

#### 4.10.12a CIdea (理念 def; ideas 存档元素)

3344B (0xD10); 主 vtable 0x1429815E0 (槽[2] writer = CFG 空桩 → **不序列化**; 槽[4]
reader 0x140FD4C70; 槽[3] Load wrapper 0x140732610); ctor 0x140FCCEA0; 带键名工厂
sub_140FCD0E0 (+24/+64/+96/+8/+3289/+192/+656 全在此派生); dtor sub_140FCD7E0;
+16 副基第二vtable (2 槽, 基类名未定)。存档: politics 块 ideas (键 12271) =
**纯名表** (writer sub_140BB0520 逐理念名后跟 BFF20(流,18,…) 系空写哨兵 —
sub_1424BFBB0 对 token 16/17/18 直返不写; 原「元内副键 18 slot 名族」系此误读)。

| 偏移 | 类型 | 名称/语义 | 键/备注 | 置信 |
|---|---|---|---|---|
| +8 | uint32 | 名 token (基 ctor 置 357=none 哨兵; 工厂 = 键名 name→token 直写) | — | 定案 |
| +16 | vtable | 副基第二vtable (形状 {vtable, 键串@+24}) | 基类名未定 | 高置信 |
| +24 | MSVC SSO 32B | 数据库键串 (ctor 填 "null"; 工厂 = 键名拷贝) | — | 定案 |
| +56 | uint8 | 可用/有效旗 (ctor 1; 加挂/换装/存档读回/GUI 费用链消费门) | — | 定案 |
| +64 | MSVC SSO 32B | 名串 (DB 键名; 过期通知/GUI/错误串消费) | — | 定案 |
| +96 | uint32 | DB 条目 id (ctor −1; 工厂 = 条目+32) | 语义推定 = 库内序号 | 定案 |
| +104 | CStaticModifier 544B | 内嵌静态修正 #1 (opinion/trade effect 系读 +112/+121) | 无 reader 键入口, 填充点未决 | 定案 |
| +192 | MSVC SSO 32B | 修正注册键串 ("MODIFIER_POLITICS_PREFIX"+显示名; 工厂双写 + reader 键 27 一写 = 第三写点) | 27 | 定案 |
| +648 | CStaticModifier 544B | **`modifier` 块实体** (+656 = 修正 id = 名 token; +664 base pairs); 经 "MODIFIER_POLITICS_PREFIX"+名 键注册进国家修正聚合 (sub_140BB0030) | 10597 | 定案 |
| +1192 | 引擎向量 24B | targeted_modifier 条目 (元素 = **544B 内嵌 CStaticModifier** — reader resize 至 count+1 后逐元调 ctor sub_140556430 (步距 544), count@+1204, 值块解析直入新元; 与 CCountryLeaderTrait+344 同键 14623 同形 §4.4.27) | 14623 | 定案 |
| +1216 | CRule 1016B | rule 覆盖块 (与 CCountry+1640/+2656 同款 ctor; 1216+1016 = 2232 严丝合缝) | 10876 | 定案 |
| +2232 | CAndTrigger 88B | available | 12264 | 定案 |
| +2320 | CAndTrigger 88B | allowed | 12263 | 定案 |
| +2408 | CAndTrigger 88B | allowed_civil_war | 13948 | 定案 |
| +2496 | CAndTrigger 88B | visible | 11562 | 定案 |
| +2584 | CAndTrigger 88B | allowed_to_remove | 13393 | 定案 |
| +2672 | 引擎向量 24B | research_bonus (元素 CIdeaResearchBonus* 72B, owner 落元+64) | 12641 | 定案 |
| +2696 | 引擎向量 24B | equipment_bonus (元素 CTraitEquipmentBonus* 160B, owner 落元+120) | 12647 | 定案 |
| +2720 | CIdeaGroupType* | 所属组 (ctor = null-object 单例 sub_140A42A70, 装载后指真组; 组+92 槽序 / +96 CIdeaCategory* / +104 cost_factor) | — | 定案 |
| +2728 | fixed×1e-5 | cost (实付 = cost × (100000+组/门类 cost_factor)/100000, sub_140FCF650) | 10323 | 定案 |
| +2736 | fixed×1e-5 | removal_cost (换装退费/费用链读旧 idea) | 12269 | 定案 |
| +2744 | uint32 | **组内下标** (SetIndex sub_140FD6650 写点直证: `*(idea+2744) = a2`, 入库/目录两路均经; ctor 0; 读侧消费待裁) | — | 写点定案/读侧待裁 |
| +2748 | int32 | (ctor −1; 同上零读写) | — | 未决 |
| +2752 | uint32 | level (ctor −1; 费用链按新旧 level 插值累加中间级 removal_cost) | 10348 | 定案 |
| +2760 | CMeanTimeToHappen 56B | ai_will_do (+24 = 100000 基权重) | 10819 | 定案 |
| +2816 | 引擎向量 24B | traits 产物 = **CTrait\* 数组** (元素 = trait 库 qword_14332EE68 条目指针, token 在元+8; ) | 12278 → +2840 暂存 → DB finalize 转换灌入 | 定案 |
| +2840 | 引擎向量 24B | traits 装载期暂存 (32B 串; 转换后清空, 不持久) | 12278 | 定案 |
| +2864 | uint8 | default | 11405 | 定案 |
| +2872 | CEffect 88B | on_add | 12356 | 定案 |
| +2960 | CEffect 88B | on_remove | 14710 | 定案 |
| +3048 | CAndTrigger 88B | do_effect (添加时求值) | 13321 | 定案 |
| +3136 | MSVC SSO 32B | picture | 464 | 定案 |
| +3168 | MSVC SSO 32B | 脚本 `name` 串 (显示名优先源, 非空则盖过 +64; 与 +64 两套并存) | 27 | 定案 |
| +3200 | CAndTrigger 88B | cancel | 10469 | 定案 |
| +3288 | uint8 | cancel_if_invalid (ctor 1) | 13669 | 定案 |
| +3289 | uint8 | 键名含 `[` 旗 (变体理念标记; 工厂直写) | — | 定案 |
| +3332 | uint32 | ledger 位掩码 (回退链 idea→组+112→门类+132) | — | 高置信 |
| +3336 | uint8 | is_good | — | 定案 |

> 费用链: 实付 = cost(+2728) × (1+组+104/门类+128 cost_factor) (sub_140FCF650)
> + 旧 idea removal_cost(+2736) + 新旧 level(+2752) 之间各级 removal_cost 累加
> (sub_140BA92B0)。理念修正注册键 = "MODIFIER_POLITICS_PREFIX"+显示名 (+192 工厂双写 + reader
> 键 27 一写; 消费者 sub_140BB0030)。reader 键 702 (category) = 弃用告警
> (idea.cpp:697 "Idea: category defined in %s (deprecated)", 通道 4096), 无字段落点。

#### 4.10.13 CDiplomaticAction 基类布局 (sizeof 120)

基构造 sub_1410F9CB0 直读; 装写 CDiplomaticAction::vftable; 装填循环 sub_1412ED0E0; 设值器 sub_14113F980。assert diplomaticaction.cpp:0x62D (SetActor) / .h:0x1FC 同文案 `_Actor … _Recipient … CanTargetSelf`。基类 writer/reader 真体 = sub_141141470 / sub_14113E7A0 (派生类槽 [2]/[4] 常见 thunk 直通)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | 动作 token | 定案; ctor sub_141140020 装载并同刻解 db 条目入 +88/+96 |
| +16 | uint8 | initiator_matters (writer 恒写 yes, 键 0x3365) | 定案; ctor 以 dword 清零 +16..+19 |
| +17..+19 | uint8×3 | 伴随布尔 (未序列化) | 定案 |
| +20 | uint32 | actor (键 0x292E; ctor *a2 双写 +20/+24) | 定案; 设值器 sub_14113F980 写 +20; 宣战面板 +20 = 我方 |
| +24 | uint32 | original_actor (键 0x2FCF) | 定案; 执行器控制权交 +24 |
| +28 | uint32 | recipient (键 0x292F; ctor *a3 双写 +28/+32) | 定案; assert 同函数读 a1[7] = +28; 宣战面板 +28 = 对方 |
| +32 | uint32 | original_recipient (键 0x2FD0) | 定案 |
| +40 | CGameDate 24B | date {vtable1@+40, hours@+48, vtable2@+56} (键 0x284A, 经 vtable2 代理; §3.7a 通用形态) | 定案 |
| +64 | CGameDate 24B | last_command_date {vtable1@+64, hours@+72, vtable2@+80} (键 0x2A2B, 经 vtable2 代理) | 定案 |
| +88 | TGameItemDatabase 条目* | on_action 动作库条目 (qword_14332EFA0; 键 0x34D8, 条目+24 置位才写) | 定案; 查找 sub_140A79050 |
| +96 | void* | 第二 db 查找产物 (sub_1406B4F60) | 定案; 未序列化 |
| +104 | int32 | type 动作型别 (键 0xE1) | 定案 |
| +108 | int32 | envoy 经办 id (键 0x2AD3; ctor 缺省 -1) | 定案 |
| +112 | uint8 | human 人控标记 (键 0x2B76, 置位才写) | 定案 |
| +113 | uint8 | value 通用布尔 (键 0x308) | 定案 |
| +114 | uint8 | 尾旗 (未序列化) | 定案 |

writer 落盘序: human(未决) → type → actor → original_actor → recipient → original_recipient → date → value=yes → last_command_date → envoy → initiator_matters=yes → on_action(未决); reader 按 token 分发回各槽。

CScriptedDiplomaticAction (sizeof 0x80, def@+120) 为首族; CNavalBlockadeAction 见 §4.31.39。

主表 67 槽行为语义 (全族 14 类共享骨架; 未列槽 = 基共享样版/常量桩):

| 槽 | 语义 | 置信 |
|---|---|---|
| [23] | GetName (每类唯一; 按 +113 value 二分出 `DIPLOMACY_X` / `DIPLOMACY_REVOKE_X` loc) | 定案 |
| [24] | Clone (每类唯一; malloc(sizeof) 逐字段拷 — sizeof 实证源) | 定案 |
| [25] | 可执行/目标谓词 (分组变体: Docking/AirBase 四元组 = `+113 && !+104`; MilAccess/NAP 对 = `+113`; Ask/Give = `+104==0`; 其余常 0) | 高置信 |
| [26] | ResolveType (仅 Mil/OfferMil/Docking/OfferDocking/AirBase/OfferAirBase 6 类: 目标已挂 offer 关系则 +8 改写对方型 token 并同步 +88/+96 def — offer↔正式 动态换型机制本体; 例 0x1411410B0) | 定案 |
| [28] | AI 接受前回调: 仅当决策 = 接受 **且** 走评估性接受路径 (a4=1) 时调用; 自动接受 (a4=0) 跳过 (ProcessAIDecision §4.10.23b) | 高置信 |
| [29] | WillAIAccept 谓词 (ai_foreign_minister.cpp:188 日志直证; 另一入口 sub_140B37CF0) | 高置信 |
| [33] | IsAutoAccept 谓词 (ai_foreign_minister.cpp:181 日志直证) | 高置信 |
| [34] | thunk→槽[25] (uniform 0x141103020) | 定案 |
| [37] | CanExecute + 拒绝原因 loc 串 (每类唯一) | 高置信 |
| [56] | Apply 副作用 (DeclareWar 0x141105A00 = 开战本体; Guarantee 0x1411074B0 = 威胁度结算; Docking/Offer/Mil/OfferMil 共享 0x141108920; 非主族实体 6 件 = CCallAllyAction 0x141105320 (伴随门候选 0x1411401E0, §4.10.25b) / CJoinAllyAction 0x1411078D0 / CPeaceProposalAction 0x141108960 (和会建立) / CRequestLicensedProductionAction 0x141108F30 / CRequestForeignManpowerAction 0x141108DF0 / CTransferSpyMaster+3×CTransferHeadOf 共享 0x141109ED0; 其余 = CFG 空桩) | 高置信 / 定案 (6 件 vtable 直证) |
| [64] | **AI 决策主体 (每派生类唯一大函数)** — 基类为未实现桩 0x1411186D0 (4 行 + 断言 `"You should have implemented me in derived class!"` diplomaticaction.cpp:1655; vtable 反查挂桩 8 类 = 基/CReduceAutonomy/CIncreaseAutonomy/CRequest·CancelAccessToLicenseProduction 系/CLendLeaseBase/NInternationalMarket::CCancelEquipmentPurchase); 个例 = **CCallAllyAction[64] = 0x141117950** (PE 0x14298C700+512 直证; 分数式见 §4.10.25a, 体未读) / 附带 PE 复核: CJoinAllyAction[64] = 0x14111B250 / CAskForStateControlAction[64] = 0x140120540 = `UserMathErrorFunction` (返 0 数学错误桩 = AI 决策未实现占位, 与基类桩异曲同工) / CGiveStateControlAction[65] = 0x14110E100 (书 [65] 行未列) / **CGiveStateControlAction[64] sub_141119EC0** (319 行纯数值式决策分, 无 DR_ 串: 同战争参战门 :11616 → 己方控制州不足门 GIVE_STATE_CONTROL_MIN_CONTROLLED → 参战度差值门 MIN_CONTROL_DIFF → 基分 BASE_SCORE+DIFF_FACTOR×差值 → 逐州首都距离项 MAX_SCORE_DIST 内 × DIST_SCORE_MULT → 逐州 controller 三档 NEIGHBOR_SCORE {受让方同盟/actor/其他}) — ⚠ **各派生 DR_ loc 因子族系 [65] 接受度装配器产出, 勿记本槽名下** (vtable 直证) | 定案 (槽形) / 高置信 (语义) |
| [65] | **AI 意愿/接受度组装入口** `sub_14110DC10(a1, a2, a3)` — 依次装配 loc `DR_AI_CHEAT` / `DR_AI_UNABLE_TO_ACCEPT` / `DR_BASE_RELUCTANCE` 后尾转 vtable[35] 0x1410FFB40 (**纯函数**: 只读 a2 条目表 {值@+0, 旗@+4, 负@+5} 40B 步进, 正负两路交叉相乘 /1e5 求和, 不写 a2 不读 a1 → 基座与派生的双次尾调幂等无害); 30 类共享此实现; **派生覆写实体系** (vtable 直证): **CJoinAllyAction[65] sub_14110E2C0** (1,604 行 18 因子装配器: DR_HELP_IS_NICE/OPINION/THEM_PUPPET/US_PUPPET/US_{DEMOCRATIC,NEUTRAL,COMMUNIST,FASCIST} (CALL_ALLY_{DEMOCRATIC,NEUTRAL,COMMUNIST,FASCIST}_DESIRE)/US_{INDUSTRY,MILITARY}_STRENGTH (RELATIVE_{INDUSTRY,ARMY}_STRENGTH_MAX, 式 = W−X×W/1e5 再向零量化)/US_TIME_AT_WAR (WAR_LENGTH_NR_MONTHS×月数)/BORDERS_ENEMY/US_LOSING_WARS (THRESHOLD=0 显式除零保护贡献 0)/THEM_WANTS_US 二分; 位掩码供 tooltip 只装配已见因子; **尾段 sub_14110A180 = cc(recipient)+1448 按 token 315 写入点本体; token 参不止 315 — COfferJoinFactionAction[65] 传 317 (DR_MODIFIER 同体第二用例, §4.10.38h) / CJoinFactionAction[65] 亦传 317 (读 dip(orig_recipient)+1448, §4.10.38l)**) / **CCallAllyAction[65] sub_14110B9D0** (1,846 行 15 因子装配器: DR_HELP_IS_NICE (JOIN_ALLY_BASE_DESIRE)/OPINION (同阵营门 +20)/THEM_PUPPET (+1000)/US_PUPPET (+20)/US_{DEMOCRATIC,NEUTRAL,COMMUNIST,FASCIST} (JOIN_ALLY_{...}_DESIRE — ⚠ 与 CJoinAllyAction[65] 的 CALL_ALLY_* 族命名交叉, 归属以 PE vtable 0x14298C700+520 直证为准)/TOO_DANGEROUS (FRONT_IS_DANGEROUS)/逐敌 NOT_READY 日期式 (NOT_READY_FOR_WAR_BASE + NOT_READY_FOR_WAR_VAL_PER_DAY_SINCE_CALL × 天数(当前 − act+48), 负值且阻断攻防战因子)/TRUCE_BREAK (−50 × 剩余天数/BASE_TRUCE_PERIOD, COST 参 = 比例 × TRUCE_BREAK_COST_PP)/DEFENSIVE_WAR (+50) ∨ OFFENSIVE_WAR (−50, recipient 民主门)/GUARANTEEING (+100) ∨ GUARANTEE (opinion/5)/ATTITUDE 双形态 (recipient 单发 + 逐敌, CAIAttitude vtable[10]/[11]/[12] = +20/+20/−20)/MODIFIER 组; 尾段 sub_14110A180 = **cc(recipient)+1448** 按 **token 316 = MODIFIER_AI_JOIN_ALLY_DESIRE_FACTOR** 写入 (步 7 另读只读镜像 **cc+1464** = sub_14055E360 直查 token 316 值 < 0 门); 保证双向谓词 sub_140D256F0 (x+656 != 0) **同名双义 — rs 参 = guarantee 槽 / dip 参 = 阵营, 参型决定语义**) / **CAskForStateControlAction[65] sub_14110AD10** (6 因子: DR_HAS_CORE_ON_ANY_STATE/DR_HAS_CLAIM_ON_ANY_STATE/DR_NOT_CONTROLING_ENOUGH_TERRITORY/DR_NO_PARTICIPATION/DR_NOT_ENOUGH_PARTICIPATION/DR_TRUST_THE_PLAYER); 其余派生体 (CAskForLicenseAction sub_141114380 / 战争协作件 sub_141110160 / 参战威胁枚举件 sub_14113BF20 / **COfferJoinFactionAction = 0x141608CB0** (PE vtable 0x1429E2B78+520 直证, 29 因子全表 = §4.10.38h; 首因子门 = 自有字段 +120 置位 → DR_STRATEGIC_ALLIANCE +10000)) 按本槽语义归位 | 定案 |

GetName loc 键表 (toggle = +113): CDeclareWarAction DIPLOMACY_WAR; CAskForStateControlAction DIPLOMACY_ASKSTATECONTROL; CGiveStateControlAction DIPLOMACY_GIVESTATECONTROL; CBoostPartyPopularityAction DIPLOMACY_BOOST_PARTY_POPULARITY; CEmbargoAction DIPLOMACY_EMBARGO/REVOKE_EMBARGO; CGuaranteeAction DIPLOMACY_GUARANTEE/REVOKE_GUARANTEE; CImproveRelationAction DIPLOMACY_IMPROVERELATIO(字面量截断形)/CANCEL_IMPROVERELATION; CMilitaryAccessAction DIPLOMACY_MILACC/REVOKE_MILACC; COfferMilitaryAccessAction DIPLOMACY_OFFER_MILACC/REVOKE_OFFER_MILACC; CDockingRightsAction DIPLOMACY_DOCKING_RIGHTS/REVOKE_DOCKING_RIGHTS; COfferDockingRightsAction DIPLOMACY_OFFER_DOCKING_RIGHTS/REVOKE_OFFER_DOCKING_RIGHTS; CAirBaseAccessAction DIPLOMACY_AIR_BASE_ACCESS/REVOKE_AIR_BASE_ACCESS; COfferAirBaseAccessAction DIPLOMACY_OFFER_AIR_BASE_ACCESS/REVOKE_OFFER_AIR_BASE_ACCESS; CNonAggressionPactAction DIPLOMACY_NONAGGRESSIONPAC(截断形)/REVOKE_NONAGGRESSIONPACT。

序列化特化 4 类 (其余 10 类纯基 writer/reader):

| 类 | writer / reader | sizeof | 扩展字段 |
|---|---|---|---|
| CAskForStateControlAction | 0x1411412E0 / 0x14113E2F0 | 144 | **states 容器 {d@+120, c@+132} u32 州 id 数组**, 键 states=11835 |
| CGiveStateControlAction | 同上共用 | 144 | 同上 (布局零差异; 差异 = token/GetName/Apply 分边) |
| CBoostPartyPopularityAction | 0x141141310 / 0x14113E310 | 128 | **+120 = CIdeology\***, 键 ideology=11838 = u32@(*(a1+120)+8); DB = 0x332EF38 |
| CDeclareWarAction | 0x141141400 / 0x14113E710 | 136 | **+120 wargoal.type u32 / +124 wargoal.id u32** (键 wargoal=11490 块, 门任一≠0, 写形 `{id=+124 type=+120}`) + **+128 u8 call_allies** (键 12233, 门非0) |

动作 token 全表 (SetActionType sub_141140020: 写 +8 并双查 DB 刷 +88/+96): declare_war=10111 / ask_for_state_control=13781 / give_state_control=13782 / boost_party_popularity=12525 / embargo=12916 / guarantee=10458 / improve_relations=11479 / military_access=10548 / offer_military_access=12232 / non_aggression_pact=12220 / docking_rights=15098 / offer_docking_rights=15099 / air_base_access=10298 / offer_air_base_access=10325 (Action token ≡ Relation token)。Apply 读旗 +17 = 执行门槛旗 (定案)。宣战本体 = 槽[56] 0x141105A00 (不进 CCommand 队列)。

#### 4.10.14 incoming_diplomatic_action 落盘分型

存档键 incoming_diplomatic_action (RTTI 无 CIncomingDiplomaticAction 类); action 类按子类复用 +120 偏移。

| action 子类 | writer | +120 形态 | 其他键 |
|---|---|---|---|
| CSendVolunteerAction | 0x141141860 | division hybrid buffer {d@act+120, c@act+132} 8B 元 (CPdxHybridInlineBufferAllocator, 构造 sub_1410F8EF0); 非 versus; 写序 id=元+4 / type=元+0, {0,0} 跳过 | given_air_volunteer_permission = u8@act+176, 无条件写 yes/no (键 0x3866) |
| CJoinAllyAction | 0x141141600 | versus = u32 tag 数组 {d@act+120, c@act+132} (stride 4, 元素 tag_id→引号 tag); count>0 开块 | 无尾字段 |
| CCallAllyAction | 0x141141350 | versus 同上形态 | 尾加键 hidden(11404) = u8@act+144 |
| CAddWarGoalAction | 0x1411412B0 | 战目标载荷 | — |
| CGenerateWarGoalAction | 0x1411415A0 | 战目标载荷 | — |

versus (键 0x294B) 仅上述发射 versus 的 action 类写 (send_volunteers 系不发)。

#### 4.10.15 GetPopularityTooltip 数值映射 (GUI)

CPoliticalStatus::GetPopularityTooltip (sub_140BAAA20, RTTI lambda 载体定位)。

链 = ps+200 属主国 → 国+3976 dip → 该意识形态修正和 → sub_140BA9100 分档缩放 → 归一化比值; 渲染经修饰定义表 (qword_14332ED90, 120B stride, §4.26.3) + sub_14055A0C0 / sub_1410E46D0。

⚠ tooltip = 意识形态每日支持率变化 (drift), 非人气份额; `100000×分档后drift/Σdrift` 只是归一化比值 (drift 索引源 = CIdeologyGroup+1536/+1544, 见 §4.10.12)。

分档缩放 = sub_140BA9100(party, out, 修正和), 按 party+136 人气分档:

| 人气分档 (party+136) | 除数 |
|---|---|
| ≤20% | 不变 (÷1) |
| >20% | 2 |
| >30% | 3 |
| >40% | 4 |
| >50% | 5 |
| >60% | 6 |
| >70% | 7 |

倒数-magic 定点。Σpopularity = 10,000,000 (GER 十党实测 {383220,449347,550445,0,601467,615503,431871,5647289,999854,321004}; 归一)。

#### 4.10.16 外交视国家列表过滤器簇 (GUI)

族形态: 全族主vtable 19 槽零功能覆写 (唯一差异槽 [0] dtor); CFilterItem 基槽0 = purecall (抽象); 类特异行为全在 ctor + 副vtable CTooltipHandler 槽0 (tooltip 构建器, 每类真覆写) + 非虚 setter。

CFilterItem 基布局 (ctor sub_141C3ECD0):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +16 | 元素指针 | 行根元素 |
| +24 | uint32 枚举 | param 过滤器类 (下表) |
| +28 | uint8 | checked 勾选态 (SetChecked sub_141C41140 写 +28 + 按钮帧 1/2) |

param 过滤器类枚举:

| 值 | 名 |
|---|---|
| 0 | 按州 |
| 1 | 意识形态组 |
| 2 | (未见; neighbor 预留推定) |
| 3 | 阵营 |
| 4 | major |
| 5 | subject |

CDiplomacyCountryListController 四创建点 (全定案):

| 创建点 | 条目类 | 驱动/载荷 | param | 控制器挂载 |
|---|---|---|---|---|
| sub_1415EE3B0 | CFilterTokenItem | CStateDatabase qword_14332F070 驱动 | 0 | +3888 (激活集) |
| sub_1415EF2C0 | CFilterTokenItem | CIdeologyGroup 库 qword_14332EF38+96 数组驱动 (token=def+20) | 1 | +3912 |
| sub_1415EEEA0 | CFilterFactionItem | CFactionSystem+32 数组; item+72=*(fac+8) id 对 CRef; 名 = CFaction::GetName sub_140D8BB80 = fac+24 (template+1384→+208 逐字互证, §4.5) | 3 | +3936 (fac id 对数组) |
| sub_1415EDE60 | CFilterMajorItem | 无 target; +40="MAJOR" 字面 | 4 | +3960 (major-only 旗) |

应用 = sub_1415F0460 串联 AND: cc+1156 门 → 州链 (sub_1406EC810(cc)+48 → +320 之 +44 id ∈ +3888) → 理念组 (cc+3984 → +208 ruling_party → +24 group → +8 ∈ +3912; 数组存 def+20 token ≡ 应用读 group+8 — ctor 同参双写定案, §4.10.12) → 阵营 (cc+3976 dip → dip+656 CFaction id 对 ∈ +3936, 空则放行) → major (!+3960 旗 ∥ cc+5210 互证)。tooltip = CORE_FILTER_BY / CORE_FILTER_BY_MAJOR。

#### 4.10.17 关系条簇 (GUI)

| 类 | target/链 | 用途 |
|---|---|---|
| CActiveFactionStripView | target = +56 本国 tag (模式恒 0); 谓词 = 双方 cc+3976 → **dip+656 CFaction\*** 相等 (双消费互证); faction+88 members ✓ + 阵营名 sub_140D8BB80 ✓ | 阵营关系条; [20] 独有覆写 0X141CAB180 = faction_general_desc + members[0] 领袖行 |
| CActiveWargoalStripView | 链 = **dip+104 available_wargoals** {data+104, c+116} → wg+60==对方 ∨ 对方 **dip+368 contains wg+60** (与 dip+368 = 附属国 tag 缓存定案互证) → 逐 wargoal sub_1415DECF0 名行 | 活动战目标条 |
| CActiveRaidMapIconData | target = 非虚 SetRaid sub_141E87920 写 **+2784 = CRaidInstance\*** (内嵌宿主 CRaidMapIcon+5888; icon+136 = 当前变体指针); 变体基族四兄弟内嵌布局 icon+152/3040/5888/8688; +2792 结束旗; [6] 帧更新结束自动派发 CRemoveRaidCommand | 袭击地图图标 |

CActiveRaidMapIconData 消费的 CRaidInstance 锚 (五册锚互证):

| raid 偏移 | 语义 |
|---|---|
| +56 | phase ==5 |
| +60 | outcome 枚举序 |
| +152 | category |
| +160 | SRaidTarget |
| +200 | unit id 对 |

#### 4.10.18 投降/流亡/志愿航空队族 (dip = *(cc+3976), writer 0X140D47400)

dip 即 CDiplomacyStatus 本体字段, 挂载见 §4.10 主表:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| dip+400 | u32 数组数据 | governments_in_exile_we_host — u32 tag id 元 → 引号 tag 列表 (writer 0X140D47400 逐元素 sub_140BB4E70; 定案) |  |
| dip+412 | u32 | gov_in_exile_we_host 容器计数 |  |
| dip+424 | uint32 | hosting tid (流亡政府接收国) |  |
| dip+432 | fixed×1e-5 | legitimacy |  |
| dip+696 | hours | last_surrender_date | 哨兵 43808760 不写 |
| dip+736 | uint8 | capitulated |  |
| dip+752 | hours | capitulated_date (键 15538) | 门 = dip+736 capitulated ≠0 (无哨兵比较; §4.10.1 +744 行同判) |
| cc+2488 区 | uint32 | government_in_exile_tag | +2488>0 时 sub_140BB4E70(+2488) → tag |
| cc+4876 | uint32 | original_tag tid | 串表名; "---" 不写 |

#### 4.10.19 CVolunteerForceTransfer / CExileDivisionsTransfer 元素字段图 (块 writer sub_141523660 / sub_141513970)

| 字段 | 偏移 (T) | 写门 |
|---|---|---|
| to 0x2990 | tag id u32@T+8 → rp(gs+856)+32*tid 名串 | 恒写 |
| from 0x298F | tag id u32@T+12 → rp(gs+856)+32*tid 名串 | 恒写 |
| days 0x296D | u32@T+40 | 恒写 |
| sender 0x240 (volunteers) / is_to_host 0x3AC2 (exile) | u8@T+44 | 恒写 yes/no |
| target_provinces 0x2D15 | u32@T+48 | 恒写 |
| group 0x3F / leader 0x28B7 {type@T+56,id@+60} / leader_unit 0x41BF {T+64,+68} | [u8@T+52 门] | 门开才写; leader 系 (type, id)≠0 + 解析成功 |
| group_color 0x35CF | CColor 内嵌@T+80 f32×3@+16..24 位型×255 **截断** (同 §4.00.10) | 恒写 |
| group_name 0x35D0 | MSVC 串@T+112 | size@T+128 >0 才写 |
| division 0x1D7 | {count i32@T+28, data@T+16} 8B 内联对 {type@0, id@+4} | (type, id)≠0 + 解析成功 (失败不耗 [N] 编号) |
| force 0x19E | u8@T+144 | ≠0 写 yes |

exile 族同构 (to/from/days/target_provinces 全同), 仅无 sender/group/leader/color/name/force。

#### 4.10.20 CCivilWarSetup (内战装配对象; vtable `&CCivilWarSetup::vftable'`)

ctor sub_1410DCD10 / 执行 sub_1410DDFE0。三构造点: start_civil_war 无参包装 sub_140242B20 (组 A = 执政党组, 组 B = *(ideology def+288), ratio = {50000,100000,100000,100000}) / start_civil_war 效果本体 sub_140365800 (effectimplementation.cpp:7742; +976 army_size 卡值 → mode=4; +1184 门 → 遍历 cc+1144/+1156 controlled_states 逐州收集) / 政变 timed activity (timedactivity.cpp:831; 规模 = 组人气占比 × 稳定度因子, 钳 ≤1e5; 指定州且 controller==目标 → mode=4 + army_size=*(state+88); 稳定度消费走 cc getter sub_1406F8750 非 ps)。
执行体两侧关系: 前置失败 loc DIPLOMACY_CIVIL_WAR_FAILED / _ALREADY_AT_WAR_FAILED / _INSTANT_FAILED + "not enough dynamic tags" (civilwar.cpp:679); 叛乱党无则断言 "No party of revolting ideology, what to do?"; **war goal 装配 sub_140D3B700 建 civil_war 型 wargoal → 推入国 +1328 容器** (civilwar.cpp:913) → CDeclareWarAction 宣战 (sub_1410F9A70, 失败报 "Attempted to spawn invalid civil war: %s vs %s" :926); 新国侧 SetRulingParty + 新党 popularity = qword_143333BC0 (define INSTANT_WIN_POPULARITY_WIN 缓存槽, 注册点直证; PE 静态初值系 define 装载前占位)。

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +8 | uint32 | target 国 tag id (三调用点均传 &tag) | 定案 |
| +16 | CIdeologyGroup* | 组 A = 原执政意识形态组 (*(party+24)) | 定案 |
| +24 | CIdeologyGroup* | 组 B = 叛乱意识形态组 (效果参数组或 *(ideology+288)) | 定案 |
| +32 | uint16 | 257 (0x0101) 双布尔位对 | 形态定案/位语义未名 |
| +34 | uint8 | 1 | 同上 |
| +40 | fixed×1e-5 | ratio #1 = 叛乱方份额 (默认 50%; 未设者执行体回退 +40) | 定案 |
| +48 | fixed×1e-5 | ratio #2 (=100000) | 定案 |
| +56 | fixed×1e-5 | ratio #3 (=100000) | 定案 |
| +64 | fixed×1e-5 | ratio #4 (=100000) | 定案 |
| +72 | int32 | mode: 0 默认 / 4 = army size / 3 = 谓词收集 states | 0/4 定案 / 3 维持 |
| +76 | tag_id | **civil_war_initiator tag** (执行体拷新国+4872, 落盘键 token 14338; timedactivity 政变构造点写入) | 定案 |
| +80 | u32 pdx 向量 | **州 id 向量** {data@+80, cap@+88, size@+92, allocdesc@+96} (非 MSVC 串; 串形态写入 +80 必致 dtor 释放垃圾必崩, 反证定案); 唯一填充点 = start_civil_war 效果本体 sub_140365800 内三处 sub_1401E1640(setup+80, …) (谓词收集/裸表直填/裸表过滤三路, 均置 mode=3); 消费 = 执行体 sub_1410DDFE0 在 mode∈{2,3,5} 分支经 sub_1410DD5D0 把元素按州 id 解析成 CState* 列表、逐州 sub_1409D43A0 军事权重求和 ×3 得叛军规模 | 定案 |
| +104 | uint32 | **州 id** (唯一消费者 sub_1410DD5D0 按 1≤v<gs+724 解析 CState\* 并对 +80 向量去重; 政变构造点写入值 = \*(CState+88) 州 id; 效果侧写入的是官方 size (0-1 修饰子) 卡值) | 定案 |
| +112 | u32 idpair 向量 | 角色 CID 数组 {data@+112, cap@+120, count@+124, alloc@+128} (8B 元素 8B 步进; 汇入侧 RH 桶距非数组步进) | 定案 |

#### 4.10.21 CNavalBlockadeAction (海上封锁动作, vtable 0x142A36AF0)

CDiplomaticAction 派生 (§4.10.13 基类 120B 全量复用, 自身零新字段); CPersistent 落盘, writer/reader = sub_141617A70 / sub_1416178E0 均 thunk 直通基类真体 (sub_141141470 / sub_14113E7A0)。ctor sub_141AA1B10; clone sub_141AA1F30 (malloc 120B 逐字段拷)。+8 token = 0x27F8 naval_blockade。

| 槽 | 地址 | 语义 |
|---|---|---|
| [23] | sub_141AA2A00 | 名称产出: 按已封锁否发 DIPLOMACY_NAVAL_BLOCKADE / _REVOKE |
| [24] | sub_141AA1F30 | Clone (120B) |
| [37] | sub_141AA2C90 | 可执行性检查 + 拒绝理由收集 (DIPLOMACY_MESSAGE_DECLINED_MESSAGE_* 群: AT_WAR_WITH / IN_THE_SAME_FACTION / IS_OVERLORD / IS_SUBJECT / LANDLOCKED_COUNTRY / NO_ACCESS_TO_SEA / NO_FLEET / MISSING_PP) |
| [40] | sub_141AA2420 | 代价: 100000 × dword_143332318 × (已有封锁数+1), 产出 COST 节点 |
| [41] | sub_141AA2820 | 代价 tooltip (NAVAL_BLOCKADE_COST / _DAILY) |
| [56] | sub_141AA2020 | 执行: 读目标关系表元素 +608 既有封锁关系槽 (§4.10 关系槽表 ✓) → sub_141AA2B10 复核 → sub_1406CF890 单位处理 |
| [57] | sub_141AA3AB0 | return sub_1401AEB50(51) (AI 分类) |
| [64] | sub_141AA20E0 | 可行性/兵力检查 (sub_1406F3940 计数 + 关系 +608/+752 门) |

#### 4.10.22 外交视图子控制器族 (19 类名录; 纯 GUI 壳, 不序列化)

基类 CDiplomacyViewActionSubController (sizeof 40): +8 = 宿主 CDiplomacyView / +16 = 父转发控制器 / +24 = 内嵌子窗对象 / +32 = 动作 token。19 个派生类全挂该基 (+CTooltipHandler), ctor 同构模板 (基类 ctor sub_141C8B9A0 五写, 子类仅多写 +32 token 常量), dtor 只清 UI 机件, 全族与序列化族无涉。族内 21 槽模型: [3] 装子窗 / [7] 子窗内容填充 (族内主差异槽, 逐类覆写) / [14] send/cancel 订阅接线 / [20] 动作名产出; Ask/Give 另带 [21] OnStateClick (§4.31.39 末段); InviteFaction 是族内唯一变体 (token 由 ctor 第 4 参动态传入)。富壳类多出的全是 UI 机件 (observer glue / 内嵌子窗), 无数据面。控制器 ↔ 动作键 ↔ Action 类对照:

| 控制器 | vtable | +32 token | 布局摘要 | 对应 Action 类 (vtable) |
|---|---|---|---|---|
| CDiplomacyAskForStateControlController | 0x142A5D870 | 0x35D5 ask_for_state_control | 州控制子族 (基 CAbstractStateControlController) + 2×button glue | CAskForStateControlAction (0x14298DEA8) |
| CDiplomacyBoostPartyPopularityController | 0x142A5D640 | 0x30ED boost_party_popularity | 基类 40 + button glue | CBoostPartyPopularityAction (0x14298DA68) |
| CDiplomacyCallAllyActionController | 0x142A5D130 | 0x2FC9 call_allies | 基类 40 + 2×button glue | CCallAllyAction (0x14298C700) |
| CDiplomacyCountryAddWarGoalActionController | 0x142A5CD50 | 0x30F7 add_wargoal | 战目标子族 (基 CDiplomacyCountryBaseWarGoalActionController) | CAddWarGoalAction (0x14298BA40) |
| CDiplomacyCountryDeclareWarActionController | 0x142A5CB88 | 0x277F declare_war | 基类 40 + button glue + checkbox glue (宣战确认勾选) | CDeclareWarAction (0x14298B820) |
| CDiplomacyCountryGenerateWarGoalActionController | 0x142A5CE00 | 0x341B generate_wargoal | 战目标子族 | CGenerateWarGoalAction (0x14298BC60) |
| CDiplomacyDefaultScriptedDiplomaticActionController | 0x142A5C748 | 0x165 none (后填) | 纯 5 写壳 40B | CScriptedDiplomaticAction (0x1429428D8) |
| CDiplomacyGiveStateControlController | 0x142A5D990 | 0x35D6 give_state_control | 州控制子族 + 2×button glue | CGiveStateControlAction (0x14298E0C8) |
| CDiplomacyGuaranteeActionController | 0x142A5CF68 | 0x28DA guarantee | 基类 40 + 2×vector (88B) | CGuaranteeAction (0x14298C0A0) |
| CDiplomacyInviteFactionController | 0x142A5C698 | 动态 (ctor a4) | 纯 5 写壳 40B; token 动态传入 (族内唯一) | NFactions::COfferJoinFactionAction (0x1429E2B78) |
| CDiplomacyJoinAllyActionController | 0x142A5D248 | 0x355F join_allies | 基类 40 + button glue | CJoinAllyAction (0x14298C920) |
| CDiplomacyLendLeaseActionController | 0x142A5C860 | 0x314A lend_lease | 富壳 **9164B** (malloc 0x23D0; ctor 0x141C8A950 / dtor 0x141C8C570 / 条目追加器 0x141C8CC60): +72 = 24B pdx 条目容器 {data, cap@+80, count@+84, alloc@+88 = off_143085170}; +96..+9112 = **7×1288B 同型胶水** CLegacyButtonObserverGlue<本类> (前 3 显式绑定 / 后 4 经合并构造器 0x141C88370; 7 OnClick = sub_141C947D0 / 94AB0 / 94730 / 948B0 / 946A0 / 945A0 / 949B0); +9144 = **ctor 内即时构造** CLendLeaseEquipmentWindow (0x580, 窗名 "lend_lease_equipment_window", ctor 0x141F27020); +9152 = CRef 哨兵; +9160 = 已填充条目数 int (容器 count@+84 之外的第二计数); 唯一调用方 = 动作面板 ctor sub_1415E2950 (§4.30:629) | CLendLeaseAction (0x1429AB588) |
| CDiplomacyIncomingLendLeaseActionController | 0x142A5C978 | 14027 incoming_lend_lease | 富壳 **9192B** (malloc 0x23E8; ctor 0x141C8A0E0 / dtor 0x141C8C330 / 异常清理 0x141C8B9D0): 与上条同族增量 = **条目容器 1 只 → 2 只** (+72 按国行表 / +96 请求表, 各 24B CPdxArray, alloc = off_143085170) → 胶水起点 +96 → +120 (**7×1288B 同型胶水** CLegacyButtonObserverGlue<本类>, 前 3 显式绑定 / 后 4 经合并构造器 0x141C87F70; 7 OnClick = sub_141C94740 / 94A90 / 94720 / 94830 / 94620 / 94520 / 94930) → 尾段对应齐 (+9136..+9160 四分类槽 / +9168 = **CIncomingLendLeaseEquipmentWindow** (0x560B, 窗名 "incoming_lend_lease_equipment_window", ctor 0x141F26920) / +9176 CRef 哨兵 / +9184 / +9188 双容器第二计数, OnClick sub_141C94740 各为逆序循环上界); 与上条尺寸差 28B = 容器 24B + 计数 4B; 唯一调用方 = 动作面板 ctor sub_1415E2950 (§4.30:629) | CIncomingLendLeaseAction (0x1429D1358, §4.10.23) |
| CDiplomacyNavalBlockadeActionController | 0x142A5DC80 | 0x27F8 naval_blockade | 纯 5 写壳 40B | CNavalBlockadeAction (0x142A36AF0) §4.31.39 |
| CDiplomacyRequestExpeditionaryForcesController | 0x142A5D528 | 0x3421 request_expeditionary_forces | 基类 40 + 内嵌 scrollbar glue | CRequestPuppetForcesAction (0x14298D848) |
| CDiplomacyRequestLicensedProductionController | 0x142A5DBD0 | 0x37BF request_licensed_production | 基类 40 + 3×button glue | CRequestLicensedProductionAction (0x14298EB68) |
| CDiplomacySendAttacheActionController | 0x142A5D018 | 0x38D9 send_attache | 纯 5 写壳 40B | CSendAttacheAction (0x14298CD60) |
| CDiplomacySendExpeditionaryForceController | 0x142A5D2F8 | 0x33FE send_expeditionary_force | MI: +40 次基 CSendUnitsGroupController (mdisp 40) | CSendExpeditionaryForceAction (0x14298D408) |
| CDiplomacySendVolunteersController | 0x142A5D428 | 0x3415 send_volunteers | 同上 MI 形态 | CSendVolunteerAction (0x14298D1E8) |
| CDiplomacyStageCoupController | 0x142A5D758 | 0x346F stage_coup | 基类 40 + 3×button glue | CStageCoupAction (0x14298DC88) |


#### 4.10.23 外交动作·租借/许可/人力/政变族 (CDiplomaticAction 子类)

**CLendLeaseBaseAction** (租借数据基座, 328B; vtable 0x1429D1128; writer 0x1415047D0 = 基 writer + 5 键 / reader 0x141504380): +120 i64 fuel_daily (14674, %lld 原值) / +128 i64 fuel_percentage (15308) / +136 CEquipmentVariantPool 64B equipment (12110) / +200 同形 production_percentage (13307) / +264 同形 once (10346)。**CLendLeaseAction** (vtable 0x1429AB588; +8 = 12618 lend_lease; 布局与基逐字节全等, 零新增)。**CIncomingLendLeaseAction** (360B; vtable 0x1429D1358; +8 = 14027 incoming_lend_lease): +328 archetype **表容器** {data@+328, cap@+336, count@+340, 分配器@+344} (键 12103; 元 8B = archetype def 指针, 经装备库单例 qword_14332EEC0 按 token 解析; 增长 1.5×; 解析失败 → :1979 一次性断言, 该原型不入表, 非致命) / +352 u8 fuel_requested (15298); writer 0x1415046F0 / reader 0x1415040C0。CEquipmentVariantPool 元素 = 16B {variant 指针@0, amount i64×1e-5@+8}, 落盘形 `equipment={ id=<token@元+8> amount=<fixed> }`, 零值元仅 allow_zero_entries(+56) 置位时写。
**视图数据回集 sub_141C9D5A0** (diplomacyviewcontrollers.cpp:913; controller → CLendLeaseAction): action = `*(*(a1+16)+2640)+1328` 解引用; 先调 action vt slot 68 (推定回集前清场); 遍历条目数组 (基 a1+72 / count a1+9160): 条目 +9330 过滤旗置位 → 跳过; 量 = sub_141F28C00(item) 解析 item+9312 文本串 (×1e5; item+48==1 时 ×1000), ≤0 跳过; +9328 fuel 旗 → sub_141504670 按 item+48 枚举累 action+120 (0) / +128 (1) / 2 无操作; 否则按枚举 0/1/2 选 +136/+200/+264 三池, sub_14100CCE0 有序插入 (元素 24B {variant ptr@+0, token@+8, count@+12}, 排序键 = *(variant)+1048); 枚举 >2 → :913 "Invalid Enum" 断言。


**CRequestLicensedProductionAction** (176B 推定; vtable 0x14298EB68; +8 = 14271; writer 0x1411416C0 / reader 0x14113F040): +120 start 变体表 (105, 8B 元 = CVariant*) / +144 cancel 变体表 (10469) / +168 u8 request_access_to_licence_production 旗 (19353)。**CRequestForeignManpowerAction** (vtable 0x14298EFA8; +8 = 19135): +120 u32 manpower (10300); writer 0x141141690 / reader 0x14113F020。**CRequestPuppetForcesAction** (vtable 0x14298D848; +8 = 13345 request_expeditionary_forces): +120 u32 division (471); writer 0x1411417A0 / reader 0x14113F2D0。**CStageCoupAction** (vtable 0x14298DC88; +8 = 13423; writer 0x141141900 / reader 0x14113F480): +120 CState* location (10349, 写 = *(state+88)) / +128 CIdeology* ideology (11838, 写 = token@ideology+8, 门 = *(ideology+16))。

零载荷名录 (纯基 writer/reader 直通; ctor 仅装 +8 token):

| 类 | vtable | token |
|---|---|---|
| CCancelLicensedProductionAction | 0x14298ED88 | 14272 cancel_licensed_production |
| CCancelAccessToLicenseProductionAction | 0x14298E948 | 19348 cancel_access_to_licence_production |
| CRequestAccessToLicenseProductionAction | 0x14298E728 | 19353 request_access_to_licence_production (token id 复用: 本类 +8 作动作 token, CRequestLicensedProductionAction +168 作载荷旗键 — 两类各装自身 vftable, 双入口并存为设计如此) |
| CCancelForeignManpowerAction | 0x14298F1C8 | 19136 cancel_foreign_manpower |
| CReturnAllExpeditionaryForcesAction | 0x14298D628 | 13334 return_expeditionary_forces |
| CSendAttacheAction | 0x14298CD60 | 14553 send_attache (ctor 直置 +16 initiator_matters=1) |
| CIncreaseAutonomyAction | 0x14298E508 | 14079 increase_autonomy |
| CReduceAutonomyAction | 0x14298E2E8 | 14078 reduce_autonomy |

**CIncomingDiplomaticActionStatus** (40B; vtable 0x1429D2768; writer 0x1415148A0 / reader 0x141513BB0): +8 pending 容器 {d@+8, c@+20} 8B 元 = CIncomingDiplomaticAction*; **+32 收件箱属国 tag** (日志国名实参源, §4.10.23b); 元素 (32B, vtable 0x142A376E0; writer 0x141AA6F30 / reader 0x141AA6E40) = {vtable, +8 CIdentifier 8B 引用句柄 (ctor 默认 null 单例 qword_14333D528), +16 u8 (语义未决), +24 内嵌动作指针 (写经 0x141141270)}; 逐元 N={...} 下标块落盘 — 国级「待处理外交动作」收件箱的持久化状态。


#### 4.10.23a 租借族运行期 (lendleaseaction.cpp; 张力门 0x141503460 / AI 分配器 0x1414FBC00 / 回复标题 0x141502A90 / 回复正文 0x1415005C0 / 顶层装配 0x1415010A0 / reader 0x1415040C0 六函闭环)

行为槽实名:

| 槽 | VA | 语义 |
|---|---|---|
| GetAiAcceptance | 0x1414FEF10 | **恒返 0** (入站租借无 AI 接受度; :1993 一次性断言「AI 只用普通租借动作」; 入站租借的 AI 决策由发起方 AI 的分配器驱动) |
| [28] 执行槽 | 0x141503F20 | 实装调用方: 以 a1+264 once 池为目标池调 AI 分配器 |
| CanExecute (CLendLeaseBaseAction) | 0x141502FB0 | 租借张力上限门 (本批未逐句读) |

张力上限门链 (sub_141503460; 调用方 = 租借动作 CanExecute 链):

| 步 | 行为 |
|---|---|
| 1 规则门 | 游戏状态+136 对象 +45 字节置位 → 直接返 0 (通过; 推定 = 禁用租借张力上限游戏规则开关) |
| 2 国家取件 | 发起国/接收国取件; 附庸关系 = 国+392 宗主 tag (0 = 独立); 自治对象 = 国+848 |
| 3 双向自治判定 | a4 反向旗双路各查「接收方是发起方附庸」与「发起方是接收方附庸」; 判定为附庸且自治对象为空 → B52 断言 (八处 latch byte_14338A770..77; 附庸必有自治对象的不变量) |
| 4 通用张力门 | 通用外交张力门 sub_14113AB20 (modifier 236 基线; DIPLOMACY_TOO_LOW_TENSION/_REVERSED/_REASON loc 键族) |
| 5 描述追加 | 门通过且描述串非空 → 修饰器格式化追加 |

张力门修饰器 (书内零落名, 本批定案):

| modifier id | 名 | 取值对象 | 格式化 |
|---|---|---|---|
| 236 | MODIFIER_LEND_LEASE_TENSION_LIMIT | 基线: 反向旗为 0 → 发起国 (国+1464 修正器表); 非 0 → 接收国 | 精度 2, 钳 −1 |
| 237 | MODIFIER_LEND_LEASE_TENSION_LIMIT_WITH_OVERLORD | 宗主侧追加: 接收方是发起方附庸 → 接收国; 发起方是接收方附庸 → 发起国 | 同形, id 237 |

AI 装备分配器 (sub_1414FBC00; a4 = 目标池或 0 干跑):

| 步 | 行为 |
|---|---|
| 1 意愿缩放 | AI 国家对象 +104 成员的虚槽 vtable+32 = 租借意愿求值器; 意愿 d → 1000×d 钳 [0, 90000] (d ≥ 90 封顶 90%) |
| 2 玩家→AI 旗 | byte_14332F619 ∧ 发起国非 AI ∧ 目标国 AI → 宽松路径 (不施加 define 上下限); AI 间走 define 约束 |
| 3 逐原型可行性 | 装备类型 = 原型+1240; 可行性求值返假 → 拒绝; 非 AI 路径再施加 define 上下限, 量不足 → 拒绝 |
| 4 变体选体 | convoy 类 → 国家仓库该类型变体 + 上限收紧; 普通装备 → 扫国家仓库装备池取量最大变体 (平手时 NEW/OLD 变体序破平), 量 = 半量固定 1e5 算术 |
| 5 交付 | 有变体 → 入池原语 0x14100CCE0 入目标池; 两路无变体 → :557 一次性断言 + 返 0 |

分配器消费的 define (书内零引用):

| 全局 | define 名 | 用途 |
|---|---|---|
| qword_1433312C0 | LENDLEASE_FRACTION_OF_STOCKPILE | 非 AI 路径上限 (define × 上下文值 / 100000, 再 min(请求量, 上限)) |
| qword_143331360 | MINIMUM_MONTHLY_LEND_LEASE_EQUIPMENT | 非 AI 路径下限 (量 < define → 拒绝该原型) |
| qword_1433314B0 | MINIMUM_CONVOY_TO_ASK_LEND_LEASE | convoy 分支门 |
| qword_1433313F8 | MINIMUM_EQUIPMENT_TO_ASK_LEND_LEASE | 普通装备分支门 |

> 干跑调用方 = §4.34 租借燃料请求门 sub_1414FCA40 (a4=0, 返假直接拒, 返真再查 +352 fuel_requested 走燃料分支); 实装调用方 = [28] 执行槽 0x141503F20 (传 +264 once 池)。

交付档枚举 (三处同枚举, 五 loc 键直证):

| 枚举 | 标题 loc 键 | 正文格式 | 调用方传入池 |
|---|---|---|---|
| 0 | …DESC_TITLE_MONTHLY | UNITS 正文 (反编译显示整体跳过, 推定 IDA 控制流失真, 待裁) | equipment 池 (+136) |
| 1 | …DESC_TITLE_DAILY | UNITS 正文 (无装备, 仅燃料) | 0 (燃料 = fuel_daily) |
| 2 | …DESC_TITLE_PERCENTAGE | PERCENTAGE 正文 | production_percentage 池 (+200) |
| 3 | …DESC_TITLE_PERCENTAGE_DAY | PERCENTAGE 正文 (无装备, 仅燃料) | 0 (燃料 = fuel_percentage 经换算) |
| 4 | …DESC_TITLE_ONCE | UNITS 正文 | once 池 (+264) |
| ≥5 | 断言 → 回落 MONTHLY | 断言 → 回落 UNITS | — |

回复描述装配 (顶层 sub_1415010A0): 前缀 `DIPLOMACY_MESSAGE_REPLYED_INCOMING_LEND_LEASE_DESC_SOMETHING` + '\n', 然后五段分段构建器 (枚举 0/2/4/1/3), 每段 '\n' 分隔; 空池空油段出空串。分段构建器: 空池空油捷径 → 标题 → 正文 (UNITS / PERCENTAGE) → 燃料 NAME-VALUE 对 (类型码 10) → 逐装备 NAME-VALUE 对 (变体名 + 量, 类型码 1 / 9); 格式参数组 104B×2 元, 步距 0x68。

#### 4.10.23b 来向外交动作 AI 决策执行体 (incomingdiplomaticactionstatus.cpp; ProcessAIDecision 0x141514260 382 行)

**CIncomingDiplomaticActionStatus** (§4.10.23 40B; 本批直证): +8 引擎向量 24B pending 容器 {data@+8, cap@+16, count@+20, alloc@+24}, 元 = CIncomingDiplomaticAction* 8B; +32 uint32 收件箱属国 tag。

**CIncomingDiplomaticAction** (32B 容器元素; ctor sub_141AA6AB0):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | CIncomingDiplomaticAction::vftable (ctor 先装基 CReferenceObject 表后覆) |
| +8 | CIdentifier 8B | 引用句柄 (ctor 默认 null 单例 qword_14333D528; ③日志打印此槽) |
| +16 | uint8 | ctor 置 0 (writer/reader 不触及; 语义未决) |
| +24 | CDiplomaticAction* | 内嵌动作 (scoped_ptr; ctor 从入参 move; 断言 incoming_diplomatic_action.cpp:0x18 / :89 / :95 / :101 + pdx_scopedptr.h:119) |

访问器四件套: 有效性谓词 sub_141AA6E30 = `+24 != 0` (无断言); 取动作 sub_141AA6DB0 (断言 :89) / sub_141AA6BF0 (断言 :95, 纯读); **release** sub_141AA6EB0 (读 +24 后置 0, 断言 :101) — 决策执行路径用此夺取所有权。

调用链 (定案): `CAIForeignMinister::Hourly sub_1412EF660 → sub_141AA6CD0 / sub_141145390 造 CIncomingDiplomaticActionActingCommand (+40 国 tag / +44 来向动作 idpair / +52 决策 / +56 走 AI 响应链旗) → 命令队列 → sub_1411577E0::Execute → sub_141514260(status, idpair, decision, flag)`。

执行流程 (定案):

| 步 | 动作 | 失败处理 |
|---|---|---|
| 1 | a2 (idpair) 经 sub_14221F310 解析为 CIncomingDiplomaticAction* | 解析失败直接 return |
| 2 | sub_141AA6E30 判 +24 非空 | 空 → :110 ③日志 "... incoming actions has no underlying CDiplomaticAction. Will not be executed." (通道 65540; 动作名取 v9+8, 国名取 self+32) → return |
| 3 | 构建调试串 (动作 token 名 sub_1424BC260(action+8) + 受援国名 sub_140BB4E70(action+28)), 未见消费即释放 (推定内联日志残留) | — |
| 4 | 线性扫 pending 容器 (data@+8, count@+20) 逐元比对 | 越界 → :134 ③日志 "... not found in <国> incoming actions. Will not be executed." → return |
| 5 | `sub_141513CF0(self+8, &out, idx)` 摘除该元 (槽位前移 + 尾槽析构 + count 递减, 被摘对象出参返出); 调用方 `*out = 0` 接管所有权 | — |
| 6 | sub_141AA6DB0(被摘) → 动作; `sub_141138CA0` IsValid 校验 | 失败 → 跳步 8 (不执行, 仅删件) |
| 7 | 决策分派 (a3): **1 = DECLINE** (action+104 = 1) / **2 = ACCEPT** (action+104 = 2; a4=1 则先调动作 vtable[28] (+224) 评估性接受前回调) | 其余值 → :160 ③日志 "Invalid AI decision when processing incoming diplomatic action!" → return |
| 8 | 接受/拒绝两路同尾: sub_141AA6EB0(被摘) 释放动作所有权 → sub_1410F9DE0 = CDiplomaticActionCommand 栈件 ctor → sub_141138E10 IsValid → sub_141104D80 命令执行循环 | — |
| 9 | 析构删除被摘的 incoming 动作对象; 释放调试串 | — |

> 决策枚举与 §4.10.25a `0=PROPOSE / 1=DECLINE / 2=ACCEPT` 一致 (AI 侧 decision 赋值 = 2 接受 / 1 拒绝, 落 action+104 同枚举)。自动接受路径 = 动作 vtable[33] (+264) IsAutoAccept 谓词为真 → decision=2, flag=0; 评估性路径 = vtable[29] (+232) WillAIAccept → decision=2, flag=1 (ai_foreign_minister.cpp:181/:188 日志直证)。

#### 4.10.24 AI 态度族 (CAIAttitude 基 + 8 变体)

对象 48B (工厂 sub_140636FB0 逐例 malloc 0x30); 变体间**零字段差异**, 差异只在行为槽。+8 u32 态度 id / +16 std::string 32B 内部名串 ("attitude_<名>"; rs+792 写名串经此复原指针, 键 11737)。全族 18 槽主vtable: [1]/[3] CPersistent wrapper / [2] = CFG 空桩 (对象自身零写出) / [4] 基共享 reader / **[9] = 可选用门** (非 null 恒真; rs 重算 sub_140D19E10 遍历 `(vtable+72)(att)` 为真才评分) / [10..16] 七谓词 **定案** (WantsAntagonize/WantsWeaken/WantsAlly/WantsBefriend/WantsProtect/WantsIgnore/IsThreatened; 方法名表 0x1427E0868..08D0 直证, 全表 §4.10.35) / **[17] = 态度评分函数** (签 `(this, out*, tag_dip*, scope*)`, 逐变体数百行大函数)。

| 类 | vtable | id | slot9..16 矩阵 (ret1/ret0) | slot[17] 评分 |
|---|---|---|---|---|
| CAIAttitude (基) | 0x1427E02A8 | — | 10000000 | 0x140634170 (空实现 *out=0) |
| CNeutralAttitude | 0x1427E0340 | 1 | 10000010 | 0x140634FF0 |
| CHostileAttitude | 0x1427E03D8 | 2 | 11100000 | 0x140634AD0 |
| CFriendlyAttitude | 0x1427E0508 | 3 | 10011000 | 0x140634620 |
| CProtectiveAttitude | 0x1427E05A0 | 4 | 10011100 | 0x140635680 |
| COutragedAttitude | 0x1427E0470 | 5 | 11100001 | 0x1406351E0 |
| CThreatenedAttitude | 0x1427E0638 | 6 | 10111001 | 0x140635D70 |
| CAlliedAttitude | 0x1427E06D0 | 7 | 10011000 (= Friendly 全同) | 0x140634180 |
| CNullAIAttitude | 0x1427E0768 | 0 (推定) | 00000000 | 0x140634170 (基共享) |

库 = **CAIAttitudeDatabase** 单例 0x332EDE8 (idb ai_attitude 已挂 ✓): 条目数组 +64/count@+76 (8B CAIAttitude*), 名 map +40; 全族**非每国一份** = 库内 8+1 单例谓词对象; 全族不入档 (存档侧分工 = 外层 rs+792 写名串)。

#### 4.10.25 阵营/国际市场动作族 (CDiplomaticAction 子类)

**Action 族** (CDiplomaticAction 派生, 主vtable 67 槽全族同形; sizeof 来源 = clone 槽 [24] 的 malloc 实参):

| 类 | vtable | sizeof | +8 token | ctor | writer / reader | 扩展字段 |
|---|---|---|---|---|---|---|
| NFactions::CAssumeFactionLeadershipAction | 0x1429E2518 | 120 | 15097 assume_faction_leadership | 0x1415FFE70 | 基类直通 0x141141470 / 0x14113E7A0 | 无 (零扩展) |
| NFactions::CCreateFactionAction | 0x1429E2738 | 152 | 12659 create_faction | 0x1415FFFA0 | 0x141617A30 / 0x1416178C0 | +120 std::string 32B = 阵营名 (键 27 name); **[65] = 0x1416040B0 (create 接受度因子装配器, §4.10.38n); [56] = 0x1416027C0 (Apply); [64] = 0x14160C360 (AI 决策分)** |
| NFactions::CJoinFactionAction | 0x1429E2958 | 128 | 12243 join_faction | 0x141600240 | 基类直通 | +120 u8 (不序列化, AI 瞬态旗); **[65] = 0x1416061A0 = join 接受度因子装配器 (§4.10.38l, 19 因子 + 4 委托组); [64] = 0x14160CB10 (DR_PREFER_OTHER_FACTION 扫描评估分)** |
| NFactions::COfferJoinFactionAction | 0x1429E2B78 | 136 | 12244 offer_join_faction | 0x1416005D0 | 0x141617A80 / 0x1416178F0 | +120 u8 (键 10260 confirm; [65] 行为 = DR_STRATEGIC_ALLIANCE +10000 门, 语义推定「已结盟直邀」) / +124 i32 war_with tag (键 10800, 门 >0; 本函未消费) / +128 u8 (不序列化; [65] 行为 = 跳过 DR_PREFER_OTHER_FACTION 扫描门) |
| NFactions::CKickFromFactionAction | 0x1429E2D98 | 120 | 14426 kick_from_faction | 0x141600380 | 基类直通 | 无 |
| NFactions::CLeaveFactionAction | 0x1429E2FB8 | 120 | 13522 leave_faction | 0x1416004B0 | 基类直通 | 无 (ctor 直写 +8, 不走 SetActionType) |
| NFactions::CDismantleFactionAction | 0x1429E31D8 | 120 | 12716 dismantle_faction | 0x141600110 | 基类直通 | 无 |
| NInternationalMarket::CRequestEquipmentPurchaseAction | 0x142A37318 | 344 | 13289 request_equipment_purchase | 0x141AA4FA0 | 0x141AA6A30 / 0x141AA6860 | +120..+335 = contract_definition 216B 全量内嵌 (见下表) + +336 CIdentifier 8B (键 12613 request) |
| NInternationalMarket::CCancelEquipmentPurchaseAction | 0x142A36F48 | 136 | 19774 cancel_equipment_purchase | 0x141AA3AC0 | 0x141AA4F50 / 0x141AA4EC0 | +120 CIdentifier 8B (键 19773 purchase_contract, ctor 默认 qword_14333D528) / +128 u8 (键 10257 release_to_country_stockpile) |
| NInternationalMarket::CRequestMarketAccessRightsAction | 0x142749510 | 128 | 13696 market_access_rights | 0x1413B1070 | 0x1413B2490 / 0x1413B2440 | +113 基类 value = request(1)/revoke(0) 判别; +120 u8 (键 10069, ctor=1) |

> 全族 token ≡ 同名关系对象 token (例外: 关系侧 13288 `equipment_purchase_contract_relation` vs 动作侧 13289 `request_equipment_purchase`)。
> 阵营 6 类中 5 类**零扩展字段** (sizeof 120 恰等基类), 差异全在行为槽。
> **+113 = 「正向/撤销」判别**, 写入点 = **基类 ctor 第 7 参** (`sub_1410F9CB0` 尾 `*(u8*)(a1+113) = a7`);
> 实测取值: 阵营 7 类 + CRequestMarketAccessRightsAction = 1, CCancelEquipmentPurchaseAction / CRequestEquipmentPurchaseAction = 0 —
> 由 ctor 形参固化, 非运行期置位。

**CRequestEquipmentPurchaseAction 载荷** = contract_definition 216B 逐字段镜像 (偏移差恒 = 120):

| act 偏移 | def 偏移 | 类型 | 语义 |
|---|---|---|---|
| +120 | +0 | CEquipmentVariantPool 64B | prices (价格池) |
| +184 | +64 | int32 | seller (tag_id) |
| +188 | +68 | int32 | buyer (tag_id) |
| +192 | +72 | CEquipmentVariantPool 64B | equipments 请求池 |
| +256 | +136 | int64 | 补贴 CIC 总额 |
| +264 | +144 | 匿名结构 (48B 形状) 向量 | subsidies {data@264, count@276} |
| +288 | +168 | uint32 | speed |
| +296 | +176 | std::map 头 | price_levels (节点 key = CEquipmentVariant idpair 8B) |
| +312 | +192 | uint8 | 懒计算完成标志 |
| +320 | +200 | int64 (fixed×1e-5) | 补贴抵扣 |
| +328 | +208 | int64 (fixed×1e-5) | 合同总 CIC 价 |
| +336 | — | CIdentifier 8B | **本类独有**: request 变体引用 (键 12613; writer 门 = 两 u32 任一非 0 且 sub_14221F310 可解析) |

> 载荷落盘序 = def 写序 (§4.23.3: contract_draft → price_levels → prices) → request; 内嵌 def 与合同/requests 元素共用 writer sub_140DF1EC0。

**关系对象族补 2 类** (CRelation 派生, 主vtable 23 槽):

| 类 | vtable | token | sizeof | 工厂分支 | rs 活动槽 | 槽差异 (相对 CRelation) |
|---|---|---|---|---|---|---|
| NInternationalMarket::CEquipmentPurchaseRelation | 0x142A21BB8 | 13288 equipment_purchase_contract_relation | 80 | `case 13288` malloc 0x50 → sub_141981D00 | +624/+632 (成对: first / second 侧) | [0]dtor / [9]ret0 / [10]ret0 / [21]Add 0x141981DE0 / [22]Remove 0x141981D30 |
| NInternationalMarket::CMarketAccessRightsRelation | 0x142A21C80 | 13696 market_access_rights | 80 | `case 13696` malloc 0x50 → sub_141982070 | +640 (单槽) | [0]dtor / [9]ret0 / **[10]ret1** / [17]GetName `DIPLOMACY_INTERNATIONAL_MARKET_ACCESS_RIGHTS` 0x1419820E0 / [21]Add 0x1419821A0 / [22]Remove 0x141982110 |

> **关系注册表 (权威关系型名录)** = 引导序列 `sub_1415EAE80`, 实测 19 型 (注册 fn + token + 名 + 槽数):
> `sub_141CA6840` 12220 non_aggression_pact 1 / 11479 improve_relation 2 / 14553 send_attache 2 / 10548 military_access 2 /
> 12232 offer_military_access 2 / 15098 docking_rights 2 / 15099 offer_docking_rights 2 / 10298 air_base_access 2 /
> 10325 offer_air_base_access 2 / 10458 guarantee 2 / 19331 licence_production_access 1 (仅 second 侧) /
> 12497 puppet 1 (仅 second 侧) / 12618 lend_lease 2 / **13288 equipment_purchase_contract_relation 2** /
> 12525 boost_party_popularity 2 / 12916 embargo 2 / 10232 naval_blockade 2;
> `sub_141CA66B0` **13696 market_access_rights 1 (单槽)**;
> `sub_141CA6900` 13911 truce 1;
> `sub_141CA68C0` 13319 timed_wargoal / 13424 timed_stage_coup / 12531 demilitarized_zone / 12532 war_reparation / 12533 resource_rights 各 2。

**阵营状态对象族** (CPersistent 派生, 非 Action/Relation):

| 类 | vtable | ctor | 宿主 | 要点 |
|---|---|---|---|---|
| NFactions::CFactionProgramStatus | 0x1429661B8 | 0x140D88890 | CFaction+1992 (内嵌) | 向量 = `CPdxHybridInlineBufferAllocator<CRef<NProject::CProgram>,4,int>`; 元素 8B CRef 双 u32 对; +8 data / +16 count / +20 cap / +24 内联 allocator 指针 (内联区 +32, 容 4) / +64 = &off_143085170 |
| NFactions::CFactionRuleStatus | 0x142A22AF8 | 0x141994640 | CFaction+1392 (内嵌 176B) | +8 宿主回指; 三段同构块 (rule / goal / program) 各 32B: 块内 +8 qword 0 / +16 u8 置位旗 / +20 f32 0.9 阈值; 第 2/3 段基 = +120 (&unk_143085A80) / +152 (&unk_143085D70) |
| NFactions::CDoctrineSharingStatus | 0x1429BDD30 | — | CFactionUpgradeStatus+120 | +128/+136 两 qword (0) + 三处 off_143085170 共享空缓冲 (+144/+168) → 三个容器; +176 = 宿主回指 |
| NFactions::CTechnologySharingFaction | 0x142A4EC20 | 0x141BE6070 | CFactionUpgradeStatus+40 (内嵌) | 基类 CTechnologySharing (vtable 挂 +0, +8 = 357 `none`); 本类仅换 vtable, 零新字段 |
| NFactions::CFactionUpgradeStatus | 0x1429BDD80 | 0x1413F9DF0 | CFaction+2104 | +40 = CTechnologySharingFaction 内嵌 / +120 = CDoctrineSharingStatus 内嵌 |

**CDiplomaticAction 基类三契约槽** (来向动作应答器 = CAIForeignMinister::Hourly → `sub_1412EF660`):

| 槽 | vtable 偏移 | 语义 | 覆写情况 |
|---|---|---|---|
| [25] | +200 | **待决/可决谓词** (pending): 假 → 直接跳过 (不产 acting command) | 8 个分组变体 (见下) |
| [29] | +232 | **保留槽**: 52 派生类零覆写, base = ret 0 → 本 build 恒假; 「WillAIAccept」实际由自由函数完成 | 零覆写 |
| [33] | +264 | **IsAutoAccept** (脚本/规则强制自动接受) | 仅 5 类覆写 |
| [34] | +272 | thunk→[25] (uniform 0x141103020) | 5 类改 ret0 短路 |
| [37] | +296 | CanExecute — 应答器末端二次复核 | — |
| [39] | +312 | **AI 接受分阈值判定**, base 0x141100520 = `return score >= dword_143337560` (= DIPLOMATIC_ACTION_GOOD_BAD_RATIO_THRESHOLD, vanilla 1) | 52 类零覆写 |

> **WillAIAccept 实际路径 (定案)**: `sub_140B37CF0(action)` = `vtable[39](action, sub_14110A890(action, &原因串表, 0, 0))`
> = 「接受分 ≥ 全局阈值」判定; `sub_14110A890(action, out, a3, a4) → i32` = **AI 接受分组装器** (独立函数, 非槽)。

**slot [25] 分组变体表** (8 组):

| 实现 | 谓词 | 使用类 |
|---|---|---|
| 0x14011D220 | 恒 0 (「永不可决」= 不参与 AI 应答) | Ask 系外的多数阵营/市场/自治/间谍类 |
| 0x1401807B0 | 恒 1 | CCallAllyAction / CJoinAllyAction / CPeaceProposalAction / CCancelLicensedProductionAction / COfferJoinFactionAction / CCreateFactionAction / CRequestAccessToLicenseProductionAction / CRequestForeignManpowerAction / CSendExpeditionaryForceAction / CSendVolunteerAction / 4×CTransferHeadOf* |
| 0x14113F690 | `*(u32*)(a1+104) == 0` | CAskForStateControlAction / CGiveStateControlAction / CRequestEquipmentPurchaseAction |
| 0x14113F6A0 | `*(u8*)(a1+113)` | CMilitaryAccessAction / CNonAggressionPactAction / COfferMilitaryAccessAction / CSendAttacheAction / CJoinFactionAction |
| 0x14113F6B0 | `*(u32*)(a1+132) && !*(u32*)(a1+156)` | CRequestLicensedProductionAction |
| 0x1413B2460 | `*(u8*)(a1+113) && !*(u32*)(a1+104)` | Docking/AirBase 四元组 / CRequestMarketAccessRightsAction |
| 0x141504400 | (lend_lease 族专有) | CLendLeaseBaseAction / CLendLeaseAction / CIncomingLendLeaseAction |
| 0x140AB4800 | 脚本动作 (读脚本槽) | CScriptedDiplomaticAction |

> **[33] 仅 5 类覆写为「强制接受」**: CCallAllyAction (0x14112F630 = 对方 cc+81==0) /
> CJoinAllyAction (0x14112F660 = 对方 dip+392 主导国为自己) / CEmbargoAction /
> CRequestPuppetForcesAction / CReturnAllExpeditionaryForcesAction (后三者 = ret1 0x1401807B0)。

**[38] = 该动作声明的关系型 token** (vtable+304; 52 派生类中 37 覆写、仅 10 个唯一实现;
未覆写者继承基类默认 0x141125D40 → 357 `none`):

| 实现 | token | 名 | 覆写类 |
|---|---|---|---|
| 0x141125D40 | 357 | none (基类默认) | 未覆写者全部继承 |
| 0x141125D00 | 10284 | access | CAirBaseAccessAction / COfferAirBaseAccessAction / CDockingRightsAction / COfferDockingRightsAction / CMilitaryAccessAction / COfferMilitaryAccessAction / CAskForStateControlAction / CGiveStateControlAction (8 类) |
| 0x141125D10 | 10457 | alliance | CCallAllyAction / CJoinAllyAction / CNonAggressionPactAction / CRequestPuppetForcesAction / CReturnAllExpeditionaryForcesAction / CSendExpeditionaryForceAction / CSendVolunteerAction (7 类) |
| 0x141125D20 | 14273 | licensed_production | CRequestLicensedProductionAction / CCancelLicensedProductionAction / CRequestAccessToLicenseProductionAction / CCancelAccessToLicenseProductionAction (4 类) |
| 0x141125D30 | 19137 | foreign_manpower | CRequestForeignManpowerAction / CCancelForeignManpowerAction (2 类) |
| 0x141125D50 | 10878 | influence | CEmbargoAction / CGuaranteeAction (2 类) |
| 0x141125D60 | 10689 | relation | CImproveRelationAction / CSendAttacheAction (2 类) |
| 0x141125D70 | 12497 | puppet | CIncreaseAutonomyAction / CReduceAutonomyAction (2 类) |
| 0x1414FFF10 | 14027 | incoming_lend_lease | CIncomingLendLeaseAction (1 类) |
| 0x1414FFF20 | 12618 | lend_lease | CLendLeaseAction (1 类) |
| **0x141611A40** | **10877** | **faction** | CAssumeFactionLeadershipAction / CCreateFactionAction / CDismantleFactionAction / CJoinFactionAction / CKickFromFactionAction / CLeaveFactionAction / COfferJoinFactionAction (**阵营 7 类共用**) |

**slot [56] Apply 副作用分派** (阵营族):

| 类 | slot [56] | 副作用要点 |
|---|---|---|
| CAssumeFactionLeadershipAction | 0x1416026E0 | 无日志串 (纯状态迁移) |
| CCreateFactionAction | 0x1416027C0 | 发 `on_faction_formed` on_action + `X_JOINS_FACTION_THREAT` |
| CJoinFactionAction | 0x141602F80 | 发 `join_faction` on_action + 威胁度 |
| COfferJoinFactionAction | 0x1416038E0 | 同上 + 日志 "AutoJoin setting ACCEPT" |
| CKickFromFactionAction | 0x141603450 | 无串 |
| CLeaveFactionAction | 0x141603810 | 发 `disband` |
| CDismantleFactionAction | 0x141602D40 | 发 `disband` |
| CRequestEquipmentPurchaseAction | 0x141AA53F0 | 日志 `refused_market_trade` (拒绝路径) |
| CCancelEquipmentPurchaseAction | 0x141AA3D40 | 走市场系统取消 (含 gamestate 断言组) |

**AI 阵营通道** (与通用外交动作通道并列的第二条 AI 通道):
CAIForeignMinister 主评估 `sub_1412E9A00` 在调 StartAction `sub_1412F0810` 之外, **并列调用
`sub_1412EB730`** (阵营子评估器, ai_foreign_minister.cpp, 1180 行), 覆盖 6 型动作:

| 顺序 | 构造 ctor | 类 | 门 |
|---|---|---|---|
| 1 | 0x1416004B0 | CLeaveFactionAction | sub_1416166B0(action, 0, 0) (CanExecute) + 分值 |
| 2 | 0x1415FFE70 | CAssumeFactionLeadershipAction | 恒 |
| 3 | 0x141600380 | CKickFromFactionAction | 恒 |
| 4 | 0x141600240 | CJoinFactionAction | 恒 |
| 5 | 0x1416005D0 | COfferJoinFactionAction | sub_141616A80(action, 0, 0) (CanExecute) 门 |
| 6 | 0x1415FFFA0 | CCreateFactionAction | 恒 (尾部分值 `100000 × qword_143333BF8 × sub_1411178A0(action) / 100000`; qword_143333BF8 = define **DIPLOMACY_CREATE_FACTION_FACTOR**; 本表外 **COfferJoinFactionAction[64] AI 决策分 = 0x14160D180** 新址) |

> 分值统一 = `100000 × sub_1411178A0(action, 0/1)` (`sub_1411178A0` = 取 vtable[64] AI 决策分);
> CCreateFactionAction 额外乘全局 `qword_143333BF8`。前置门 = 本国 `dip+656 CFaction*` 非空 ∧
> `faction+88 members[0]` id 对匹配 (只有领袖国才走本通道)。
> 第三条通道 = 市场合同 (GUI 草稿窗 + AI 直接构造 sub_14119AE70 / sub_141B95250), 不经 StartAction。

#### 4.10.25a CDiplomaticAction 执行器与命令通道 (diplomaticaction.cpp 定案)

**type 枚举 (+104)** = {0=PROPOSE, 1=DECLINE, 2=ACCEPT} (三源互证: 串映射 sub_14112F0B0 本体落名 — 0/1/2 → "PROPOSE"/"DECLINE"/"ACCEPT", 越界 "UNKNOWN" + 断言 :1063; 唯一调用者 = AI 应答器 sub_1412EF660)。**执行器 = CDiplomaticAction::Execute sub_141103030** (自由函数): vtable[26] ResolveType → +104 三态分派 → PP 载荷结算 / 双侧通知 / vtable[27] 接受-拒绝簿记 (拒绝日期冷却 + on_action; 接受撤 offer 关系) → Apply 或 incoming 投递 → 新闻件 + UI 刷新。**9 个调用点** (grep 全语料实扫): 命令队列循环 sub_141104690 (唯一常规通道) / sub_1416038E0 (COfferJoinFaction AutoJoin ACCEPT) / 内战生成器 sub_1410DDFE0 (civilwar.cpp 串定案, 宣战直发) / 控制台与调试 6 处 (0x140353ED0 / 0x140358440 / 0x140355DD0 / 0x140358160 / 0x140304EA0 / 0x140243BE0, 细分待裁)。**命令堆工厂 sub_141102DA0** (定案): `_pAction` 空 → 断言 :760; **action+72 盖 gs+1128 当日时间戳** (last_command_date) 后 malloc 0x30 装 (assert :116); 14 调用点全落名 (队列循环/AI 应答族/市场合同 AI ×2/通用发送壳 ×10); 命令 [10] Execute = thunk 0x141104D80 → 同循环。

**CDiplomaticActionCommand** (48B CCommand 派生, vtable 0x14298B708; +40 = _pAction; [9] IsValid 0x141138E10 / [13] Clone 0x141100530; ctor sub_1410F9DE0): 执行循环 sub_141104690 (递归深 ≤12 :142 断言; **call_allies(12233) 弹窗门** — handler+1192 收件箱推送 216B 元 {+0 u32=2, +208 u8=2}, **尾插** — 收件箱为尾插线性向量, §4.00.4a); 收件箱投递 sub_141513B40。上游: UI 动作按钮 → §4.10.22 controller → 本命令队列; AI 应答 → CAIForeignMinister::Hourly → sub_1412EF660 → 同队列; 宣战旁路不进队列 (CDeclareWarAction::Apply 直调, 书已收)。Clone [13] 0x141100530 体: malloc 0x30 → 字段拷贝 +12/+20/+22/+24/+25/+28/+32 逐项 → 目标 +8/+16 清零 → _pAction 克隆 = sub_1410FC5F0 取工厂 → vt+192 无参克隆 → 旧值判空销毁 (unique_ptr reset 拆显); 克隆为空 → 断言 "_pAction != nullptr" :126, 闩 byte_14333DB84。

**vtable槽新语义** (执行器直读; 槽位定案/语义高置信): [27] 已接受谓词 (+216) / [40] PP 载荷 (+320) / [44] PP 金额退款旗 (+352) / [46] 关系 token 出参 (+368) / [47][48] actor/recipient 国 (+376/+384) / [57] CanApply (尾转 +456) / [10]-[21] 通知谓词+消息构建 12 槽 / [22] (+176) incoming 串 / **[62] (+496) + [63] (+504) = 通知出口双侧调用** ([62] 前有 sub_1406FFC90(国) 门控, [63] 无条件紧跟 — 形如 actor 侧门控 / recipient 侧无条件; 方向归属待裁)。**三类 vtable 补全** (exe COL 解析): CCallAllyAction 0x14298C700 / CJoinAllyAction 0x14298C920 / CAskForStateControlAction 0x14298DEA8 / CGiveStateControlAction 0x14298E0C8 / CDiplomaticActionCommand 0x14298B708。

**AI 公式 (capstone 逐指令核验)**: CCallAllyAction[64] 分数式 = +5×join 分 + CALL_ALLY_BASE_DESIRE + Σmodifier(cc+1464, 键 315) → ≥ DIPLOMATIC_ACTION_PROPOSE_SCORE 时 +1000 → major(cc+5210)×2 → 有宗主 ÷2 → −10×versus 威胁 (define 8 名全对名); CJoinAllyAction[65] = 1604 行 18 因子装配器 (1e-5 定点), 尾转 vtable[35]。

新消费点与外围 (定案): **宣战后自动阵营邀约链** = Apply 尾对 dip+656 为空的战争目标构建 COfferJoinFactionAction (CanExecute + WillAIAccept 门入队); **宣战校验器** sub_141137F30 (declare_war(10111) db 触发器 + 附属同阵营/自战门; CDeclareWarAction[57] 等 4 调用点); **cc+1448** = 按国 AI 因子容器 (token 315/316/317 键, CJoinAllyAction[65] / CCallAllyAction[65] 尾段消费; ⚠ 容器挂在**国对象 cc** 非 dip — 旧措辞 dip+1448 系误, 以本条与 §4.10.38l 为准; CCallAllyAction[65] 步 7 另读只读镜像 **cc+1464**); **dip+176** = state_control 族参战度求值实参; **间谍主转交 PP 槽** = sub_140BB4560(cc)+72 (i64 1e-5, 扣费 = 100000×FACTION_INTELLIGENCE_UNLOCK_COST); **CRequestForeignManpowerAction+120** = 请求人力数 (cc+808 池收支); **CRequestLicensedProductionAction** = 书「序列化特化 4 类」之外第 5 例 (槽[4] reader sub_14113F040; 派生容器 +120{c@+132}/+144{c@+156}/+168); CGenerateWarGoalAction[32] = 阵营一致性谓词 (dip+656/dip+392 双门); **执行遥测** = qword_14332F5C0 按 action token 下标 u32 计数数组 (byte_14332F5A1 门; cap@5C8/count@5CC/分配器@5D0); **第二张统计/成就上报表 qword_14332EF60** (byte_143330D86 门 → 动作+112 u8 旗 → sub_140162B30 → sub_140A685B0(h, token) → sub_1414E7D70(载荷, token 块, +28 recipient, +20 actor, +113 value, +104 type) → sub_140A68410(h, …); 语义未决, 与计数数组并列); 界面弹窗向量 = 视图+1192/{cap+1200, count+1204} (216B 元 push-front)。

**视角国双槽选择器** (执行器 + 0x1411403E0 + 0x141137F30 三处同构自读, 高置信): `gs+1312 > 0 ? gs+1312 : gs+1316` (sub_140BB4390(gs+槽) 取当前视角国); 槽语义待裁 (gs+1312/1316 = **内联 4B TAG 串对非 id 对** — §4.28.14 收口: OOS 报告窗 char* 逐字节比 + OOS dump 名 TAG 分量经 sub_140BB4E70 取串, 4 处消费点同选择式)。

**Apply 内联 helper 两对** (定案, 唯一调用者直证):
- **CCallAllyAction::Apply (0x141105320)** 内联二件: ① **链式召唤评估器 sub_1410FCC40** (547 行) = actor 被召参战后评估是否把自己的盟友也拉进来 — 遍历 actor 阵营成员 (faction+88 数组/faction+100 计数) 跳过已在关系数组 (dip+368 data/dip+380 count) 者 → 栈上构造 CCallAllyAction (基 ctor 第 5/6/7 参 = 0,−1,1; v76 = 12233 call_allies; 双查 db 刷 +88/+96) → 自/目同一性门 + 含战争门 → AI 决策分 (vtable[64] → 关系对象+104 的 vtable+32 槽按 key 73 累加修正) → **阈值闸 dword_143337858** (低于则跳过) → 人控国门 (sub_1406F8410(国)+81 u8) → WillAIAccept (sub_14110A890 装器分; 基类 sub_141100520 时比较 ≥ dword_143337560) → 通过则参战威胁枚举件 sub_14113BF20 + **Called 列表尾插** + 断言 :6092 `!Called.Contains(&Ally)` (闩 byte_14333DB90); Called = {data+0, cap+8, count+12, alloc+16} 的 CCallAllyAction* 线性向量, 1.5× 扩容。② **被召参战新闻件 sub_1411403E0** (613 行) — 见 §4.10.25b。
- **CJoinAllyAction::Apply (0x1411078D0)** 内联一件: **参战威胁新闻件 sub_1410FE420** (354 行) — 见 §4.10.25b。

**on_action 触发门** = gs+2617 u8 旗 (置位才走 vtable[+184] GetName + sub_140A79BA0(qword_14332EFA0, +88 条目, …, 0) on_action 派发; 两处断言 :754/:765, 高置信)。**新闻发射** = sub_140F30190(载荷, qword_14332F698, …) (incoming 串 = vtable[+176]), 生命周期 sub_140F30200/sub_14011F300。**战后刷新双国** = qword_14332F6A0 旗 → 对 actor/recipient 各 sub_140D2D8D0(*(国+8)+8*idx) 战况视图重算 (旗语义未决)。

#### 4.10.25b diplomaticaction.cpp 补遗 (4 函书未收 + 因子 loc 键全名)

**4 函清册** (均唯一调用者直证, 高置信):

| VA | 体行 | 定性 | 唯一调用者 | 错误处理 |
|---|---|---|---|---|
| 0x1410FCC40 | 547 | CCallAllyAction::Apply 链式召唤评估器 (递归体) | 0x141105320 (槽[56]) | ①×多 |
| 0x1411403E0 | 613 | CCallAllyAction::Apply 被召参战新闻件构建器 | 0x141105320 (槽[56]) | ①×3 |
| 0x1410FE420 | 354 | CJoinAllyAction::Apply 参战威胁新闻件 | 0x1411078D0 (槽[56]) | ①×4 |
| 0x1411401E0 | 51 | CCallAllyAction 同阵营/宗主关系谓词 (char 返回, CanExecute 前置门) | 宣战校验器族 | ①×1 |

**被召参战新闻件 sub_1411403E0 六步** (参数: a1 = PopupData, a1+0 = _pWar 战争关系指针, a1+8 = 被召国句柄指针, a1+20 = 发起国 tag u32 非零门, a2 = 发起国句柄):

| 步 | 语义 |
|---|---|
| 1 | 视角国双槽选择器 (gs+1312/gs+1316, 同 §4.10.25a) |
| 2 | 两侧 dip+8 国数组 → +744 关系对象 → +73 u8 旗判已应战 (双方都已应战则跳过新闻) |
| 3 | 断言 :5804 `PopupData._pWar && "Missing War Relation"` (闩 byte_14333DB8F) |
| 4 | 三分支 loc 键: 视角国≠被召国且非同国 → 取被召国战争关系, 无关系或旗未置 = `DIPLOMACY_CALLED_WAR_ENEMY`, 否则 `DIPLOMACY_CALLED_WAR_ALLY`; 被召国 dip+392 宗主 == 发起国 → `MASTER_CALLED_US_TO_WAR` (MASTER 参数 = 发起国名); 发起国 dip+392 宗主 == 被召国 → `PUPPET_CALLED_YOU_TO_WAR` (PUPPET 参数 = 发起国名); 皆不满足 → 无新闻直接返回 |
| 5 | 标题统一 `DIPLOMACY_JOINED_WAR_TITLE`; 参数三元组 {COUNTRY1=被召国名, COUNTRY2=发起国名, WAR=战争名} (eh vector constructor iterator 0x68 跨距 ×3) |
| 6 | sub_1410FD630(a1+8, …) + sub_140F30190(…, qword_14332F698, …) 新闻发射 |

**参战威胁新闻件 sub_1410FE420 六步** (参数: a1 = 加入方 tag 句柄, a2 = 被援方 tag 句柄, a3 = 战争关系对象, 空则断言):

| 步 | 语义 |
|---|---|
| 1 | 前置门: 战争目标国 (sub_140D230C0(a3)) == a2, 或 sub_140D25650(a3) 内战旗 |
| 2 | 参战国清单: sub_140D22110(a3) → sub_140D38F30(dip, warId, …) 得 tag 数组 |
| 3 | 威胁值 = max over 全部参战国 of sub_140F039B0(…); 再 **× qword_1433365C8 / 100000** (1e-5 定点缩放) |
| 4 | loc 键二分: 内战 → `X_JOINS_CIVIL_WAR_THREAT`, 否则 `X_JOINS_ATTACKER_WAR_THREAT` |
| 5 | 断言 :7537 `pWarRelation && "Missing War Relation"` (闩 byte_14333DB93) |
| 6 | 参数对 {WHO, WAR} → sub_142245E60 本地化 → **sub_1401CBC90(gs, tag, 威胁值 i64 1e-5, 文本, 0, 0)** 威胁度系统发射 |

> **新全局量**: 参战威胁系数 qword_1433365C8 (i64, 1e-5 定点; 威胁 = 系数×max(参战国威胁)/1e5; 唯一消费点 — 定案) / 盟友召唤决策分阈值 dword_143337858 (i32; 唯一消费点 — 定案; = DIPLOMATIC_ACTION_PROPOSE_SCORE, vanilla 50)。外交动作族阈值 define 对名补全: dword_143337AC0 = DIPLOMATIC_ACTION_BREAK_SCORE (vanilla −10, 关系破裂阈值)。威胁基值取**全部参战国**最大值 (非仅被援方) — 定案。

**同阵营/宗主关系谓词 sub_1411401E0** (char 返回, 读动作 +20 actor/+28 recipient): actor 与 recipient 已存在战争关系 (dip+8 国数组 → +744 → +73 u8 旗) → 0; actor dip+656 阵营为空 → 1; 两同阵营 → 0; recipient 的宗主 (recipient.dip+392 tag > 0) 与 actor 同阵营 (宗主 dip+656 == actor 阵营) → 断言 :2926 `"Subject not in same faction"` + 0; 否则 1。⚠ 本函为 §4.10.13 [37] CanExecute 在 CCallAllyAction 上的伴随门候选 (无 vtable 直证) — 高置信。

**CJoinAllyAction[65] 18 因子 loc 键全名校实** (sub_14110E2C0 1604 行; 真实逻辑 ≈700 行, 余为 MSVC EH 状态机展开 + j_free 串析构样板; `_OWORD v227[2]` 等 32B 栈块 = std::string SSO, 非结构数组):

| 因子 loc 键 | 语义线索 |
|---|---|
| DR_HELP_IS_NICE | a3=1 (AI 视角) 分支首因子 |
| DR_OPINION | 双侧关系意见 (US/THEM 参数对) |
| DR_THEM_PUPPET / DR_US_PUPPET | 宗主/附庸方向因子 |
| DR_US_DEMOCRATIC / DR_US_NEUTRAL / DR_US_COMMUNIST / DR_US_FASCIST | 意识形态四分 (CALL_ALLY_*_DESIRE 族) |
| DR_US_INDUSTRY_STRENGTH / DR_US_MILITARY_STRENGTH | 相对实力 (RELATIVE_INDUSTRY / ARMY_STRENGTH_MAX) |
| DR_US_TIME_AT_WAR | 参战时长 (WAR_LENGTH_NR_MONTHS×月数) |
| DR_BORDERS_ENEMY / DR_BORDERS_AT_LEAST_ONE_ENEMY | 边境接敌 (ENEMY / NR_ENEMY 参数) |
| DR_US_LOSING_WARS | 战败方因子 (THRESHOLD=0 显式除零保护, 贡献 0) |
| DR_THEM_WANTS_US / DR_THEM_DO_NOT_WANT_US | 双向意愿二分 |

> 尾部断言 :7401 `!EnemiesOnMyBorder.Contains(VersusTag) && "Enemy country was duplicated"` — EnemiesOnMyBorder = 边境接敌缓存向量, 唯一断言。
> **CDeclareWarAction::Apply (0x141105A00) 调用链补证**: 拉盟包装器对 sub_1410FFC50 (断言 :110; 第二方向 sub_1410FFF50 零断言 — 支持书内「第二列表方向」推定, 档仍推定) / 盟友 tag 双列表 sub_1411026E0 / IsValid 二次校验 sub_141138E10 + 含战争门伴随 sub_141138CA0 / **直调执行循环 sub_141104690 不进队列** (宣战旁路复核) / 阵营邀约 ctor sub_1416005D0 / 阵营族 writer sub_141617A20 / **自递归 ×2** (对 original_recipient 宗主/附庸连锁宣战; 断言 :2281 `war relation was created against the original recipient's overlord, which should never happen.`, 闩 byte_14333DB8C) / 前置结算 sub_14110A420。威胁度发射 loc 键 `THREAT_CB_WAR` / `THREAT_NO_CB_WAR` (+TARGET 参数) = 宣战侧威胁度入口。
> **宣战校验器 sub_141137F30 断言补注**: :1937 反断言形 `!"subject not in same faction"` = 附属国/宗主参战一致性门; 本函亦用视角国双槽选择器。

**未决**: gs+1312/gs+1316 槽语义 (推定玩家 tag/观察备用 tag) / qword_14332F6A0 战后刷新旗 / qword_14332EF60 + byte_143330D86 上报表语义 / 槽[62]/[63] 方向归属 / 0x1410FFF50 列表方向 / CCallAllyAction[37] 地址 (0x1411401E0 候选, 缺 vtable 直证) / 宣战自递归双 callsite 分支条件 (宗主链/附庸链)。

#### 4.10.26 和会管理器 (CPeaceConferenceManager, 内嵌 @gs+1248)

| 项 | 值 | 语义 |
|---|---|---|
| peace_conference | pc = gs+1248 (内嵌 CPeaceConferenceManager, vtable 0X2720E48; gs+1624 = 选择组容器, 非和会; CGameState ctor 0X1401BFD30 `a1[156]=vtable` 直证; Reset 0X140BBE710; writer 槽2 0X140BBF150) | 会议/决议池/分数树; SCHEMA 结构见 objects 层 SCHEMA_COUNTRY/STATE |

**CPeaceConferenceManager** (内嵌 @gs+1248):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | — | vtable (0X2720E48) |
| +8 | CPeaceConference* 向量 24B | active_peace 会议指针数组 {d@8, cap@16, c@20, alloc@24} (CPeaceConference*; writer 逐元素 ADEC0, 键 13632 = active_peace) |
| +32 | CString sso | 管理器名 (runtime-only, 不序列化 — writer/reader 仅 13632 会议容器, 探针空串互证; 运行期临时名, 写点未定位) |


**清偿批补注（和会结算链定案）**: 玩家 tag 主选 = `dword[gs+1312]` 非零否则 `dword[gs+1316]`（⚠ 旧行文「+328>0 时取 +1316」方向反——328 是 1312 的 dword 下标，1312 为主选分支）。CDone(13830) = conf+472/+456 双树落账 → **sub_140E45FB0 结束流程**: 回合推进（清 440/488/456）→ 竞标落账（成员 +76 累加）→ 终局 0x141041BB0（PEACE_CONFERENCE_CALCULATING + 逐对象终结 + UI 终交接）；无脚本 on_action。CPass(12566) Execute = thunk 直转同函数。

conf+216..520 区字段巡礼:

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +216 | uint32 | 回合计数 | 定案 |
| +220 | uint8 | 本机已表态旗（玩家 tag ∉ 456 树） | 定案 |
| +221 | uint8 | completed | 定案 |
| +224..240 | CPeaceWinnerAi* 向量 | CPeaceWinnerAi scoped {data@224, count@236} | 定案 |
| +248..264 | 匿名结构 (元素待裁) 向量 | 谈判方成员表（元素=国对象指针，+8 取 tag） | 定案 |
| +272..284 | 匿名结构 (元素待裁) 向量 | 第二对象数组（两轮终结处理） | 高置信 |
| +296 | 向量 | scoped 对象数组（终局逐元素虚槽[0]） | 高置信 |
| +320 | 向量 | scoped 对象数组（终局逐元素虚槽[0]） | 高置信 |
| +344 | 向量 | scoped 对象数组（终局逐元素虚槽[0]） | 高置信 |
| +368 | 门旗 | 竞标落账门（非零跳过 +76 累加） | 定案 |
| +416 | 匿名结构 (NNB 形状) 向量 | 回合推进清空区 | 定案 |
| +440 | 树 | 回合推进清空区 树 {head@+440, size@+448} | 定案 |
| +448 | — | = +440 树的 size 字段 | 定案 |
| +456 | 树 | 本回合已表态表（set\<tag\>，节点 32B 键@+28） | 定案 |
| +472 | 树 | 完成表（Done 落账；3A9E0 全员判定）; conf+480 非零时 conf writer 以键 12813 `done` 落盘 (节点+28 tag → 串值) | 定案 |
| +488 | 树 | 已结束回合竞标快照归档 {head@+488, size@+496}（EndTurn 写 46260；查 470B0；退出清理 40C80） | 定案 |
| +496 | — | = +488 树的 size 字段 | 定案 |
| +504 | 树 | 与 488 配对的回合态树（414E0 查询） | 高置信 |
| +520 | uint32 | 40C80 清理步清零计数 | 高置信 |
> 参与者单位: 五个 scoped 数组单位 24B 头 {alloc_vt@0, data@8, cap@16, count@20} 连排 (ctor 0x140BBDB70 五连头直证); 其中 losers 单位 data@+280 / liberated 单位 data@+304 — 单位 cap 同名异位于头内 +16 (高置信); 活体: losers 单位 count 恒 1 = 单一主败方条目, liberated 单位头活读 0x7FF6 前缀值 = 静态 allocator 描述符 off_143085170 (实际数据落点 +288/+312 推定)。

**和会左菜单相关行动取值器 sub_141E471F0** (peaceavailableactions.cpp:398; 高置信): 三级行动槽优先序 — **a1+1344 (qword 168) → 状态 3**; **a1+1336 (qword 167) → 状态 = vt+248 谓词 ? 2 : 1** (谓词实参 = 和会对象 sub_14185CDC0(a1+32)+528 的 dword 与 sub_140E47A20 返回表首元); **a1+1328 (qword 166) → 状态 = sub_14151EC00(v5) ? 0 : 6**; 空行动 → :398 断言 "in PC left side menu, relevant action should never be null" (闩 byte_14338C88E); 出参对 = {qword@a2, int@a2+8}; 状态枚举取值集 {0,1,2,3,6}, 语义未决。

#### 4.10.27 CPeaceConference (active_peace 元素)

**CPeaceConference** (vtable 0X2950E58; ctor 0X140BBDB70; writer 槽2 0X140E527D0; Start 0X140E4F240, 断言 MainLoser/MainWinner.IsValid peaceconference.cpp:0x295/0x296)。下表 = writer 全解码 + UI 消费对照; token 已直名; 行序 = 偏移升序, writer 键序 = 落盘序 (以 writer token / 存档键列承载):

| 偏移 | 类型 | writer token | 存档键 | UI 消费 (函数) | 语义 | 置信 |
|---|---|---|---|---|---|---|
| +8 | uint64 idpair | — (CReferenceObject 胶水) | — | sub_141E584E0 直读 → popup+5248; Reload 回写 win+20744 | conf 自身 refid | 定案 |
| +24 | uint32 | 0x32DB (13019) | peace_conference_name_state_id | — | 会议目标州 id | 定案 |
| +28 | uint32 | 0x2EFD (12029) | winner_scope | — | 获胜方 scope | 定案 |
| +32 | uint32 | 0x2EFE (12030) | loser_scope | — | 战败方 scope | 定案 |
| +40 | int64 fix5 | 0x296B (10603) | factor | — | 初始分数/点数池 (ctor = 100000) | 定案 |
| +48 | uint32 | — (writer 未写) | — | Start 分数初始化链 sub_140E500B0 写 (断言 WinnersTotalScore>0) | = Σ winner 条目 +72 original_score (逐 winner 累加) | 定案 |
| +52 | uint32 | 0x292E (10542) | actor | Start 断言 0x295 直读 +52 | = MainLoser, 主战败侧 tag | 定案 |
| +56 | uint32 | 0x292F (10543) | recipient | Start 断言 0x296 | = MainWinner, 主战胜侧 tag | 定案 |
| +60 | uint8 | — (writer 未写) | — | FinalizeAnnounce 0x140E42B50 读, 喂占领/驻军回退门 | 战败方单位处理旗 (OutWinners≤1 ∧ OutLosers>1 ∧ +180 非空 ∧ loser∉+168 时清零) | 推定 |
| +64..+95 | SSO | 0xDD (221) | message | — | 会议消息串 | 定案 |
| +96 | 匿名结构 (NNB 形状) 向量 24B | — (不序列化) | — | sub_1401B0250 线性 contains | = OutWinners u32 tag 数组 (sub_140E40640 断言实名) | 定案 |
| +120 | 匿名结构 (NNB 形状) 向量 24B | — | — | sub_1401B0250 线性 contains | = OutLosers u32 tag 数组 (同上断言实名) | 定案 |
| +144 | {d@144, c@+156} u32 表 | 0x3AF6 (15094) | occupied_winners | — | 占领获胜方 tag 表 | 定案 |
| +168 | 匿名结构 (NNB 形状) 向量 24B | — (writer/reader 双向不碰) | — | 唯一读者 FinalizeAnnounce 0x140E42B50 二分成员查 (按国 idx 序) | 有序 tag 表 — **纯运行时空表兜底定案** (ctor 空表; 活体 3 场和会全生命周期 count 恒 0, 唯一读者 FinalizeAnnounce 二分未命中即走清零条件分支) | 定案 |
| +192 | {d@192, c@+204} | 0x2F66 (12134) | civil_war_losers | — | map: tag → 串 内战吞并收尾事件 = on_civil_war_end_before_annexation (触发器 0x140E46820, 主 scope + FROM scope, eventscope.h:193 防环; 书内 on_action 清单此前未录) | 定案 |
| +216 | uint32 | — | — | w3: `*(conf+216)` → +1 显示 | 当前竞标阶段 (0-based) | 定案 |
| +220 | uint8 | — | — | w3/w9 文案门 | 正在提出需求旗 (PEACE_CURRENTLY_MAKING_DEMANDS / PEACE_WAITING_…) | 定案 |
| +221 | uint8 | 0x3127 (12583) | completed | 主分派分支门; bid click 门; popup 装载门 | 会议已结束旗 | 定案 |
| +248 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3120 (12576) | winners | sub_140E38720(conf,&tag) 逐元查 tag@elem+8 | 获胜方条目 (元素布局见下表) | 定案 |
| +272 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3121 (12577) | losers | — | 战败方条目 {tag@elem+16} | 定案 |
| +296 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3125 (12581) | liberated | w2: `conf+308` 计数门 (与 +332 相加) | 解放国条目 {tag@elem+8} — 出叶 (计数门) | 定案 |
| +320 | scoped_ptr<CPersistent> | 0x32E0 (13024) | subject | 同上门 | 附庸国条目 {tag@+8, overlord tag@+88} — 出叶 (计数门); 条目 +80 = CPersistent 副体 vtable (mdisp 80), 非值槽 | 定案 |
| +344 | 匿名结构 (NNB 形状) 向量 24B | — (writer 未写) | — | CPeaceSummaryPopUpWindow 消费 | 强制改政体条目容器 — 条目 = CConferenceForceGovernmentParticipant (副体 vtable@+80); 查/建按 (国 tag@+8 × 实施方 tag@+88) 双匹配, 意识形态由实施方国派生 (sub_140E382F0/0x140E380F0) | 定案 |
| +368 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3108 (12552) | solo_winner | sub_140E3F7D0 门 (非零 → 分差=0) | 单一获胜方 {tag@+8} | 定案 |
| +376 | RB-tree | — | — | 节点键 dword@+28 (州 id); 读法 = 竞价可用性门① 0x140E4A400 (命中后第三门 sub_140E46DC0 真 → 不可用) | 州在册表 (键 = 州 id; 值域与写入者未决) | 待裁 (语义) |
| +416 | {d@416, c@+428} 表 | — | — | w2 显隐门; sub_140E400F0 逐元 +64 分值 | = CPdxArray<scoped<CPeaceAction>> 当前竞标表 (dynamic_cast 直证; CPeaceAction 布局见下表) | 定案 |
| +440 | RB-tree | — | — | sub_140E400F0 树游 (+25 色标) | = map<CPeaceAction*, scoped<CPeaceAction>> 竞价覆盖表 (节点+32 键 / +40 值; 总分调 Σ(新+64−旧+64); 键类型高置信, 余定案) 条目+60 = submitted 旗 (提交州行动置 1); 条目/行动 vtable 槽 33 (+264) = 提交/激活调用 (第三参统一传 conf+528) | 定案 |
| +472 | RB-tree (门 +480) | 0x320D | minor_flavor | 未消费 (负) | map: 节点+28 tag → 18; **落盘键 = 12813 `done`** (0x320D 直读) | 定案 |
| +504 | RB-tree (门 +512) | 0x2835 (10293) | history | 未直接消费 (负; UI 走运行时列表 + `current_and_history_actions` 窗) | map: 节点+32 tag → {节点+40{+52} bidding (12850) 引用表} | 定案 |
| +520 | uint32 | — | — | w5: 输光 && `conf+520 <= 0` 分支 | = 当前竞标方 tag (GetCurrentNegotiator sub_140E47890 + 行头点击 sub_141E50A00 写证) | 定案 |
| +524 | uint32 | — | — | sub_140E4F220 写 (变化检测) | UI 选中/过滤国 tag | 定案 |
| +528 | uint32 | — | — | w5 传 sub_14185CEC0 (available_actions 构建) | 选中 action token (复位值 = 19479 undefined) 另作条目/行动槽 33 提交调用第三实参 (UI 分发器 0x140E412D0 case0/2/5) | 定案 |
| +532 | uint32 | — | — | bid click 写; w5 作 ACTION 参数 | 过滤行动 id (PEACE_FILTER_DEMANDS_DESCRIPTION) | 高置信 |
| +536 | uint64 | 0x4B89 (19337) | peace_threat | CPeaceSummaryPopUpWindow 负消费 | 和会威胁值 | 定案 |
| +544 | qword 标量累加器 | — (ctor 0x140BBDB70 清零) | — | **休眠成员**: 全 dump 生命周期检索全负 (writer/reader/Start/EndTurn/UI/loader 及树访问器共现, 字节+索引形双查; 异类 0x140E5C870 已剔除); 真值恒 0; 业务名未决 (疑裁撤特性遗留) | 定案 | 休眠 |
| +552 | RB-tree | — | — | 读法 sub_140E47D70 / 内战残余转让 0x140E48DF0 / pc_does_state_stack_demilitarized / _dismantled 二审 | **map<u32 州 id → CStatePeaceAction\* 数组>** (key = 州 id@节点+32; value count@节点+88, 元素@节点+96; 按州竞标叠层, 值按回合分层); **写方三组**: 载入重建 虚槽[8]→0x140E4C490 / EndTurn·终局前置 0x140E4D220 / GUI 0x141E571B0·0x141E48CF0→0x140E3B6B0, 插入原语 sub_140E2E9D0 条目+88 = 竞价者 tag (同 tag / 内战等价 sub_140BB52F0 已竞价 → 州不可再报, 0x140E4A400 门③) | 定案 |
| +568 | RB-tree | — | — | 0x140E46DA0 (SHIP_CLAIM tooltip 0x1419E2310; **peacetooltiphelper.cpp 和会文本域 (簇名 cetooltiphelper 系 IDA 断行伪影)**: 三函数链 = 行动详情面板 sub_1419E3670 (先 PEACE_THREAT_GENERATED) → 分发 sub_1419E1860 (mode==2 → **0x1419E13C0 争夺明细**: RTTI 分派 CStatePeaceAction (+72 state id) / CTakeNavyPeaceAction (+72 ship 门, +52 备用), 头键 PEACE_CONFERENCE_{STATE,SHIP}_CONTEST_BREAKDOWN_BEGIN, 未知类型断言 :536 / 否则 → 2310 claim 明细) → **0x1419E1A50 单条 claim 行** (三参本地化 PEACE_CONFERENCE_CLAIM_OR_CONTEST_BREAKDOWN_ITEM + BID_WILL_RESULT_IN_CONFLICT + 条件 BID_WILL_PULL_BACK_PLAYER; 断言 :435 行动+48 = taker tag; 玩家发起前缀 "players_icon")) + EndTurn 门 0x140E524B0 | **map<ship refid qword → 行动指针数组容器>** (键 = take_navy 动作 +72 ship 引用之 +8 refid, capstone `mov rdx,[rax+0x48]` 直证 — 原「动作 refid 对」键说废; 值 = {count@节点+88, 元素@节点+96}, 元素 take_navy 系行动指针高置信; take_navy 有船分支按舰查) | 定案 |
| +584 | RB-tree | — | — | sub_140E524B0 (EndTurn 门) + 0x140E47A00 | **map<u32 giver tag → 行动指针数组容器>** (键 = action+52 giver 直读; take_navy 无船分支按出让方挂层; 值形同 +568) | 定案 |
| +600 | RB-tree {head@+600, size@+608} | **InfluenceDataCache** = map<state_id, map<tag, InfluenceData>> (断言串 Conference.GetInfluenceDataCache() 直证; 外层节点 56B = 32B 头+4B 键+16B 内层 map; 内层值域 = 三距离 +40/+48/+56 + 邻接数 +128; 消费 = 和会影响力折扣 0x1419F9DA0, §4.10.37) | — | ctor 建树 (节点 56B 分配); 无 unwind dtor | 定案 | 待裁复核毕 |
| +616 | int64 | — | — | — | 和会开始墙钟 FILETIME ticks (Xtime_get_ticks; 100ns, 1601 纪元) | 定案 |
| +624 | uint32 | 0x2AAD (10925) | time_duration | — | time_duration 累计秒 = 写时墙钟叶 (EXEMPT, 见 §4.10.26) | 定案 |

+552/+568/+584 三棵 RB-tree 均由 Start (0X140E4F240) 清空。

**Start 参与国枚举链**: +616 = Xtime_get_ticks() → **sub_140E40640 参与国枚举器** — 先 sub_140D38F40 从 dip 侧收双侧 → sub_140E387C0 交叉剔除 → winner_scope(+28)/loser_scope(+32) 三档展开: 1 = 相关国过滤 sub_140E332B0 (本体/同阵营/主从链) / 2 = 阵营聚合 sub_140E33060 (成员入列 + 阵营领袖 faction+88 members[0] 锚定) / 3 = 本体+附属 sub_140E4F1C0 (主战国 + dip+368 附属数组全加); conf+24 = 败方首都州 (sub_1406F6DD0); 白和平 scope(2,2) = 阵营全员自动终战互证。**枚举器 sub_140E40640 体级定案**: 7 参 = (winner_tag=conf+56, loser_tag=conf+52, winner_scope=conf+28, loser_scope=conf+32, OutWinners=conf+96, OutLosers=conf+120, OutOccupiedWinners=conf+144); scope switch 后 **loser_scope==0 侧走 CanSurrender sub_1406D7B20 原位紧缩而 winner_scope==0 原样保留** (语义分化); 双侧逐 tag 活战争关系裁剪 (rel = *(dip+8 行表[对方 idx])+744, rel 空 ∨ rel+73 非 0 → 剔除); loser_scope≠3 → **sub_140E51570 = OutOccupiedWinners 填充器** (消费 sub_1406F6DF0 首都取数 + sub_140D3F440 占领查询); winners 空 → 断言 :851 ("when the f would this happen?...") 后兜底把 winner_tag 推入三表 (恢复语义推定); 尾断言 :856/:857 两侧非空 (latch byte_14333D033/D034/D035)。return 0 = dip 收集或交叉剔除后任一侧空。**winners 条目+88 = ScoreDistributionForWinner** = u32 逐回合计划进账向量 {data@+88, cap@+96, count@+100, alloc@+104} (sub_1414579E0, conferenceparticipants.cpp:425 "ScoreLeftToReceive >= 0"; 回合分 = min(max(ceil(0.05×ceil(w_i×总分池)), ceil(w_i×original_score)), 剩余), 剩余 = Σceil(w_i×orig)−已摊, w = PEACE_SCORE_DISTRIBUTION 权重表; 0.05 = **qword_143337058 = PEACE_SCORE_MINOR_BOOST_FRACTION** 只在下限 max() 分支, 无 ×回合数项)。**total_score_before = ceil(原始合成分) (点数制)**; 总分池 conf+48 = Σ b+72, b+72 = round(PEACE_SCORE_SCALE_FACTOR 1.35 × LosersTotalValue/WinnersTotalScore × 个人净分) (全链 fixed15)。**war_score 上浮 Add API 族** (ws 字段 ← combat 侧调用者): equipment_damage +16 ← sub_141179790/650/AC0; province_capture +24 ← sub_1411799C0; air_damage_str +32 ← sub_1411795A0; strategic_air +40 ← sub_1411794F0/A90 (统一入口 sub_140D25FA0 对 wr+112/wr+224 双侧各调一次); sunk_ship +48 ← sub_141179BE0 (0x141975480 战斗结算 / 0x140C3C060 naval); convoy_attack +56 ← sub_141179B90 (0x141975480)。

**和会终结算链** (三入口同链: 交互终局 sub_140E45FB0→0x140E41BB0 / Start 即时结算分支 0x140E4F240 / 载入后重建 = 虚槽 [8] 0x140E49760 只跑第一环): ① **RebuildOutcomes 0x140E38ED0** (清空重建 +296/+320/+344 结果条目 + winner 净化 + 由 +504 history 聚合 SplitData 分组定胜负写四方份额/胜支旗; status∈{3,4} 的行动不参与结算); ② **EndWarsTerminate 0x140E41F70** (流亡托管清退 + 胜×败双边停战, 写点全在国/外交侧); ③ 三结果数组虚槽 [0] 逐元素销毁; ④ **CivilWarRemainderTransfer 0x140E48DF0** (内战败方未叠层残余州转让内战胜方 winner 条目+328); ⑤ **FinalizeAnnounce 0x140E42B50** (双边占领/驻军省 controller 回退 + liberated 首都兜底 + 和约名/PEACE_TREATY_THREAT 事件); ⑥ 交接 0x140B66080。回合推进链 (0x140E50BB0) 内联复用 ①; **GetTurnScoreShare 0x140E3F6B0** 只读 winner+88 份额数组喂 initiative 累计 (+76), 与终局链正交。

⚠ 竞标分值 = CPeaceAction+64 (sub_140E400F0 所加为竞标对象), 非 winners 条目内偏移。

**CPeaceAction 增量**: **+48 = taker 行动方 tag** (cost/taker_flag 双消费, CBiddingsPopupItem 域; 全布局 = §4.10.28: +52 giver / +56 negotiator / +60 status / +64 cost); winners 条目增量: **+36 = 州数** (CPeaceSummaryPopUpWindow 读)。**CPeaceSummaryPopUpWindow 消费验证**: conf+248 winners/+272 losers (**条目+16 tag ✓** — 与 losers 行 {tag@elem+16} 互证)/+296 liberated/+320 subject/+52/+56 white peace/conf+64 message 全中; subject 条目 +96 = **动态新建国 tag 输出槽** (非 tag@b+8 镜像 — vtable[10] Execute 动态建国后落此, §4.10.30 运行时字段表); 参与者 tag 双坐标 = 类结构差异 (Beneficiary 系 +8 / loser 系 +16, sub_140E38250 直证), b+8 = 唯一权威坐标 (writer/触发器/Execute 三方直证)。CBiddingsPopupItem: item+40 = _pConference / item+48 = _pAction (断言实名); wargoal_icon 显隐读 conf+520 ✓ / tooltip 走 GetCurrentNegotiator sub_140E47890 ✓; 宿主 = CPeaceBiddingsPopUpWindow (vtable[2]=populate 直证, 与 §4.30.22 三行池边界 = Popup 变体独立类)。

winners 条目 (scoped 条目, 元素基 = 条目基; = CConferenceWinnerParticipant):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+8 | tag_id | tag (sub_140E38720 逐元比对位) |
| 元素+24 | CState** 数组 {data@+24, cap@+32, count@+36} | 受让州指针数组 (聚合器 0x140E38A70 推入 = "+36 州数"的数组本体 ✓; RebuildOutcomes 清零) |
| 元素+48 | 树 {头@+48, size@+56} | **_TakenShips** (take_navy 竞标累加表, assert 实名): map\<loser_tag, {夺船清单 vector@节点+40, _RatioScreening qword@节点+64 钳≤1_fixed}\>; 唯一写点 = 聚合 sub_140E51A70 case 12526 → sub_141454600; 不落盘, RebuildOutcomes 重建 |
| 元素+76 | u32 | 当前分 (回合链 `+=` 累加槽, 写点 0x140E50BB0) |
| 元素+88 | u32 向量 {data@88, cap@96, count@100, alloc@104} | ScoreDistributionForWinner 数组 — 逐回合进账份额 (填充 sub_1414579E0, conferenceparticipants.cpp:425; 读 GetTurnScoreShare 0x140E3F6B0 按回合下标; 落盘键 19829 = u32 列表非串) |
| 元素+328 | u32 向量 {data@+328, cap@+336, count@+340} | 内战败方残余受让州 id (CivilWarRemainderTransfer 写; writer 键 taken_states_civil_war 12135 ✓; 执行侧消费 sub_1414559B0 → sub_1409DE560 设归属 + 州+140 清零) |

> **分数链 (定案)**: Start → sub_140E500B0 定总分池 (= conf+48, Σ original_score) → sub_141459450 InitScore 写 +72 original_score 并回填 +128 war_score_breakdown 体 (+144..+272) → sub_1414579E0 按 FractionsPerTurn 把 +72 摊到 +88 = **逐回合计划进账表** → 每回合 EndTurn (0x140E50BB0) 经 GetTurnScoreShare 累加 +76 = **已进账累计**; +280/+304 = score_from_countries/amounts **按来源国分项明细** (平行数组 count 同步 assert, 不齐则整对不存 — 填充点未锁定 待裁); +80 = non_refunded_score (13155), +112 = ratio qword (694) — 均落盘。winner writer = 0x141459B70 (this = 条目+64 副体); 受让州数组/+48 _TakenShips 不落盘。

CPeaceAction (当前竞标表元素; CStatePeaceAction 派生):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | token | 类型 |
| +16 | SSO | token 串 |
| +56 | tag_id | negotiator 谈判方 tag (§4.10.28 ✓) |
| +64 | — | 分值 |
| +72 | uint32 | (CStatePeaceAction 派生) state id |
| +76 | uint8 | (CStatePeaceAction 派生) **demilitarized** 旗 — 推定 |
| +77..+78 | uint8 | (CStatePeaceAction 派生) 中间叠加 bool×2 (未名) |
| +79 | uint8 | (CStatePeaceAction 派生) **dismantled** 旗 — 推定 |

**按钮批量提交 (CPeaceBiddingsPopUpWindow, 0x141E58160; 新收)**: 门 = this+5248 会议 CRef idpair 双零 ∨ sub_14221F310 解析失败 → 断言 peaceconferencepopups.cpp:343 "_Conference.IsValid() && Conference needs to be valid for CPeaceBiddingsPopUpWindow buttons to work"; 早出 = sub_141860F10(*(this+5232)) (提交状态/锁, 待裁); 遍历按钮向量 {d@this+24, c@this+48} (8B 元 CBiddingsPopupItem*), 仅处理 按钮+56 旗置位者, 载荷 = 按钮+48 _pAction: **种类 0** (this+8) → sub_14151FD10(action) (本地执行, 语义待裁); **种类 1** → +5248/+5252 idpair 非零时解析会议否则传 0 → sub_140E4CAA0(会议, action) (会议侧提交, 语义待裁); 其他 → 断言 :361 "Don't know this kind of peace bidding popup"; 收尾 sub_1418646F0(*(this+5232))。

#### 4.10.28 和会候选出叶裁定

| 存档键 (token) | 裁定 | 依据 |
|---|---|---|
| liberated (12581) | 出叶 | w2 计数门 (sub_1418657D0 L301) |
| subject (13024) | 出叶 | 同上计数门 |
| history (10293) | 未出叶 | 树本体无 UI 读; UI `current_and_history_actions` 窗走运行时 +416 列表 (语义旁证) |
| redistributions (14497) | 出叶 (CDistributionForOneWinner 内嵌块, 见下 CDistributionForOneWinner 表与 CConferenceWinnerParticipant b+128 行 — writer/reader 双向直证) | 本 token 非独立 conference 键, 经 b+248 矢量数据落盘 |
| score_from_countries (13833) | 不随本块出叶 (推定) | token 不在 conference writer; 推定对应 winners 条目 +64 值槽 |

#### 4.10.29 active_peace.time_duration (墙钟豁免叶)

| 项 | 值 | 语义 |
|---|---|---|
| 公式 | u32@p+624 + (Xtime_get_ticks − i64@p+616) / 1e7 | writer 落盘时刻重算 now − 和会开始; resave ↔ 导出恒差墙钟间隔 (同 #session/seconds_played 族) |
| 豁免 | EXEMPT_LEAVES ('peace_conference', 'active_peace.time_duration') | 豁免已裁定 |
| 时基 | Xtime = FILETIME 100ns (1601 纪元) | 嵌入式 os.time 返回 1601 纪元秒 (已含 11644473600 偏移; 桌面 lua 是 1970 — 换算注意双加; 段实现带幂等自检) |
| ⚠ 多块形 | `active_peace[2].time_duration` 不在豁免键内 | 现无多块并存实例, 出叶即暴露 |

#### 4.10.30 和会静态库与参与者族 (1.19.3 实名)

**CPeaceConferenceDatabase** (和会静态库, 256B 单例 0x332EFC8; vtable 0x14271AF60; ctor 0x140172B00; 校验 [2]=0x140A848D0; Reset 0x140A847C0; **非标准 idb 形状**, 已挂 §4.26.8 附注形): 三内联 vec + 默认类别内嵌:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | CPeaceActionCategoryEntry 内嵌 136B | 默认和会行动类别 (+8 token 默认 10724 other / +16 is_default 旗 / **+128 u32** → db+168 拷贝式回写) |
| +176 | uint8 | has_default_category 旗 (恰一类别可 default; **:250/:296 = 格式化错误日志 + 后来者 is_default 清零** — 默认类别先到先得; 真断言在 :212 — 勘误: 原记「:250/296 断言」形态误标; **访问器 sub_140A84A30 的未命中日志在 :226** (CLog 4096「Missing peace action category for '%s'」, token 名经 sub_1424BC260), :250/:296 属装载/校验期另一函数) |
| +184 | 内联 vec | peace_action_categories (19833): 元素 136B {vtable@0, token@+8, is_default u8@+16, 三串@+24/+56/+88, u32@+120} |
| +208 | 内联 vec | peace_action_modifiers (19831): 元素 192B = CPeaceActionModifier |
| +232 | 内联 vec | peace_ai_desires (15110): 元素 184B = CPeaceActionScriptedAiDesire (**元素内布局**: +8/+16/+104/+112/+136/+176 六槽, 解析器 0x140A839B0 逐条构后推本 vec) |

访问器: sub_140A84A30(db, token) 类别查 (未中告警 + 返默认); sub_140A84750(db, token) modifier 查 (+140 旗 ∧ +8 id)。

**CPeaceActionModifier** (和会行动修正静态定义, 192B; vtable 0x14293F9E8; writer = CFG 空桩不落盘; reader 0x140A85360): +8 定义名 token / +16 enable 条件对象 (+36 计数门) / +104 i64 cost_multiplier (19001, 默认 100000) / +112 CPdxArray<40B> peace_action_type (19832) / +136 category (702, 默认 other) / +140 u8 faction_modifier (19616) / +144 名串 32B / +184 装载序。

**CPeaceActionScriptedAiDesire** (和会 AI 欲望定义, 184B; vtable 0x14293FA38; writer 桩; reader 0x140A85420): +8 token / +16 enable (+36 计数) / +104 u32 ai_desire (15455) / +112 peace_action_type 表 / +136 名串 / +176 装载序。

**和会参与者族 5 类** (conf+248 winners / +272 losers / +296 liberated / +320 subject / +344 强制改政体容器之元素; 多基 CPersistent 副体位: Winner/Liberated = b+64, Subject/ForceGov = b+80; writer/reader 的 this = 副体, 故 a1−56 / a1−72 同指 complete-object b+8 = country CRef):

| 类 | vtable | mdisp | 键与字段 (complete-object b) |
|---|---|---|---|
| CConferenceWinnerParticipant | 0x1429C24D0 | 64 | country(10394)@b+8 / original_score(12578)@b+72 / score(11044)@b+76 / non_refunded_score(13155)@b+80 / score_distribution(19829) = **u32 列表**@b+88 {data@88, cap@96, count@100, alloc@104} (逐回合进账份额; 串说废 — writer 走 sub_1401B3D80 u32 列表原语, 读 GetTurnScoreShare 按回合下标) / ratio(694) qword@b+112 / war_score_breakdown(12502) = **CDistributionForOneWinner 全体内嵌 @b+128 (≈152B, 下节)** / score_from_countries(13833) vec@b+280 / score_from_amounts(13834) vec@b+304 (两写原语空表皆不落; 填充点未锁定待裁) / taken_states_civil_war(12135) vec@b+328; **不落盘**: +24 受让州数组 / +48 _TakenShips 树 (原「+248 scoped 不落盘」说废 — b+248 = redistributions 矢量数据指针, 经键 14497 落盘, writer/reader 双向直证); writer 0x141459B70 (this = 条目+64) |
| CConferenceLoserParticipant | 0x1429C2520 | 0 | screening_ic(13205) fixed@b+48 / civil_war_target(12619) u8@b+176 / civil_war_enemy(14217) **u32 标量 tag @b+180** (writer this = 条目+144, 字段 writer 视 +192/+320/+324 与 b 坐标恰差 144 互证; 填充点 sub_140E4FA60, cpp:3848 BestCivilWarWinner 断言; reader 0x141458A30 同偏移) — **civil_war_enemy = 内战获胜方 tag 组** (CivilWarRemainderTransfer 读点) |
| CConferenceLiberatedParticipant | 0x1429C2588 | 64 | country@b+8 / liberators(12579) 平铺 u32 vec@b+72 {data@72, count@84} |
| CConferenceSubjectParticipant | 0x1429C25F8 | 80 | country@b+8 / overlord(11135) tag@b+88 / ratio(694)@b+104 / is_main_puppet(12870) u8@b+112 |
| CConferenceForceGovernmentParticipant | 0x1429C2668 | 80 | country@b+8 / enforcer(19845) tag@b+88 / ratio(694)@b+104 / is_main_puppet(12870)@b+112 |

**参与者→tag 解析链 (0x1418600D0, peaceconferencewindow.cpp:1150 "what is this taker tab you clicked on ?", 高置信)**: 和会窗口 "taker tab" 点击路径按 tab 序取 tag — tab 0 → 基础参与者 tag 直槽 `*(a4+8)`; tab 1 → RTTI 下溯: Subject / ForceGovernment → **+88**; Liberated → **+72 CountryTags 表** 取 tag (sub_141860200; 断言 pcw.cpp:1101 `!CountryTags.IsEmpty() && "No liberators or enforced in beneficiary participant"`; 取表首元素 (*解引返回值, 高置信)); 都不中 → 0。**和会窗口展示层两函 (SetBiddingsInWinnerItem 0x141868380 / 本解析链) 不经人类守门双条件 (sub_140E50B20 / sub_1402AA8A0 零出现) — 守门只在 hourly 推进链 (§4.2.6), UI 层不设防**。SetBiddingsInWinnerItem (pcw.cpp:1533, 高置信): 窗 +20824 出参 / +20656 biddings 引用 / **+20744 = `_Conference` optional** (双 dword 判空 → sub_14221F310 AccessPtr); 胜方表态项 +2608 = tag / +2592 = GUI 元素; 断言 `HasWinner(...) && "Trying to display biddings for a non winner"`; 尾 = 高度累加 `*a3 = 旧值 + 追加` (行高累计, 槽语义待裁)。

**NWarScoreDistributionHelper::CDistributionForOneWinner** (vtable 0x142961D88, 9 槽标准 CPersistent: writer 0x1419848B0 / reader 0x1419846C0; 无二级基; ≈152B; ctor = 拷贝构造 0x140D332A0; 全 exe 无堆分配点 = 纯内嵌于 CConferenceWinnerParticipant b+128; 构建点 sub_141984170 和会计算路径现场构造):

| 偏移 | 类型 | 初值 | reader 键 | 语义 |
|---|---|---|---|---|
| +8 | CWarScoreBreakdown 内嵌 (vtable 0x142960128) | 清零 | 12502 war_score_breakdown → 子块委派 | **键写的是整个 CDistribution** (参与者 writer 实证), 前面 112B 只是该对象的头部 |
| +120 | 矢量 24B | 空 | 14497 redistributions → sub_141983420 | 元 16B {u32@0, u8@4, qword@8} 受让分配条目; count@+132≠0 才开块 — **b+248 即此矢量 data** |
| +144 | uint32 | 0 | 14498 total_score_before → sub_1424C08D0 | 再分配前总分 (恒写; = ceil(原始合成分), 点数制) |

**redistribution 五类** (NWarScoreDistributionHelper; 通用执行器 sub_141982440: 逐 winner amount = clamp(vtable[1](tag, dist), 0, total), amount>0 → dist+120 向量记负 points, Σ 后 round(Σ/N) 均摊; 金额式统一 1e5×系数×tsb/1e5 取整 round-half-up):

| 类 | 金额式 | 门/对象 |
|---|---|---|
| CTowardsFactionLeaderRedistributer sub_141982BB0 | round(PEACE_SCORE_TRANSFERRED_TO_FACTION_LEADER 0.1 × tsb) | 阵营领袖国 (faction+88 members[0]) |
| CTowardsOverlordRedistributer sub_141982DA0 | round(MODIFIER_PEACE_SCORE_RATIO_TRANSFERRED_TO_OVERLORD (token 614) × tsb) | dip+392 宗主匹配的附属 |
| CTowardsPlayersRedistributer sub_141982F70 | round(MODIFIER_PEACE_SCORE_RATIO_TRANSFERRED_TO_PLAYERS (token 613) × tsb) | 只取自 AI 国; 使能 = ∃人控胜者 |
| CSmallScoresRedistributer sub_141982B40 | ratio < PEACE_SCORE_RESET_LOW_SCORE_THRESHOLD 0.05 → 交出全部 tsb | AI 国; 使能 = ∃ratio ≥ 0.1 接收方门 |
| CFactionInfluenceRedistributer sub_141982A90 | round(PEACE_SCORE_TRANSFERRED_FROM_FACTION_INFLUENCE 0.1 × tsb) | 同阵营非 top-2 影响成员; DLC 门 + rank==1 国建 |

参与者族运行时派生字段 (RebuildOutcomes 0x140E38ED0 及其聚合器 0x140E38A70/0x140E389A0 写, 坐标 = complete-object b; 回合推进/终局/载入重建三处复用):

| 类 | 偏移 | 类型 | 名称/语义 |
|---|---|---|---|
| CConferenceWinnerParticipant | b+24 | CState** 数组 {cap@+32, count@+36} | 受让州指针数组 (0x140E38A70 推入; RebuildOutcomes 清零) |
| CConferenceWinnerParticipant | b+48 | 树 {size@+56} | **_TakenShips** (map\<loser_tag, {夺船清单 vector, _RatioScreening ≤1_fixed}\>; take_navy 聚合写, 不落盘运行时重建) |
| CConferenceWinnerParticipant | b+328 | u32 向量 {cap@+336, count@+340} | 内战败方残余受让州 id (= writer 键 taken_states_civil_war 12135 ✓; CivilWarRemainderTransfer 写) |
| CConferenceLoserParticipant | b+192 | qword | 份额 (fixed×1e-5; 组总=0 时 0xFFFFFFFF) — 坐标基定案 (写点 = RebuildOutcomes 按 SplitData type 拷贝; 份额 = 1e10×w/(1e5×Σw), w×1e5 溢出守卫同 0xFFFFFFFF) |
| CConferenceLoserParticipant | b+200 | u8 | 胜支旗 (SplitData 分组定胜负 0x140E3DF10 写; 胜支 = 锦标赛 key 首字段 setl 小胜 / 权重 setg 大胜) |
| CConferenceLiberatedParticipant | b+72 | u32 向量 | winner tag 数组 (= writer 键 liberators 12579 ✓) |
| CConferenceLiberatedParticipant | b+96 | u32 | 动态建国 tag 相关槽 — vtable[10] Execute = **0x1414551E0** (on_action = on_liberate; 体含 "our_liberators" 串, 断言 :1014/:1016; **无动态建国链**) |
| CConferenceLiberatedParticipant | b+104 | qword | 份额 |
| CConferenceLiberatedParticipant | b+112 | u8 | 胜支旗 |
| CConferenceSubjectParticipant | b+64 | map\<token → 州 id 向量\> | modifier 表 (键 = 四旗 token 12531..12534, 0x140E389A0 写) |
| CConferenceSubjectParticipant | b+96 | u32 | **动态新建国 tag 输出槽** — vtable[10] Execute = **0x1414555D0** (on_action = on_puppet; sub_141459690 分配动态 tag + 逐州 SetOwner 建国后落此, Execute 以之解析新国继续; 不序列化, ctor 清零); b+112 is_main_puppet 兼「用既有国」门 |
| CConferenceSubjectParticipant | b+104 | qword | 份额 (= writer 键 ratio 694 同槽) |
| CConferenceSubjectParticipant | b+112 | u8 | 胜支旗 (= writer 键 is_main_puppet 12870 同槽) |
| CConferenceForceGovernmentParticipant | b+64 | map\<token → 州 id 向量\> | modifier 表 (同 Subject) |
| CConferenceForceGovernmentParticipant | b+96 | u32 | **动态新建国 tag 输出槽** (同 Subject; Execute = **0x141455010**, on_action = on_force_government, 含 sub_141459690 建国链) |
| CConferenceForceGovernmentParticipant | b+104 | qword | 份额 (= ratio 694 同槽) |
| CConferenceForceGovernmentParticipant | b+112 | u8 | 胜支旗 (= is_main_puppet 12870 同槽) |

> 参与者 tag 坐标: writer/reader 副体视角 (a1−56/−72) 与触发器读点 (pc_is_forced_government_to 条目+8) 及 Execute (sub_141459690 首参) 三方全部落 complete-object **b+8 = 唯一权威 tag 坐标 (定案)**, 无第二存储; b+96 = 动态新建国 tag 槽 (非镜像, 见上表); 「GUI 条目+16」读点未定位, 维持待裁 — 建议复核 §4.31 相关注记原始出处。中间基实名 = CConferenceBeneficiaryWithStackableParticipant (Subject/ForceGov ctor 链直证; 其 +64 = 64B map 哨兵节点 malloc(0x40) {3×self, u16 257@+24}, 即 Subject/ForceGov b+64 modifier map 头节点)。

> **族根基类 CConferenceBeneficiaryParticipant** (vtable 0x1429C2480, 槽 [5] purecall = 抽象直证; ctor sub_141453890): 基帧 {+0 vtable (派生覆写), +8 country tag (ctor a2, = 上文 b+8 权威坐标的写入点), +16 qword 待裁 (疑国家引用载荷, ctor a3 透传), +24 受让州数组 data (与 Winner b+24 CState** 数组对齐), +32 cap+count, +40 24B 容器头, +48 = 72B 树哨兵节点 malloc(0x48) {3×self, u16 257@+24} (= Winner b+48 _TakenShips 树头)}。五派生 ctor (sub_141453A70/141453F20/141453960/141453FB0) 坐标与本表逐一对齐。

**CConferenceLoserParticipant** (208B; ctor **sub_141453AC0** 定案补全 — 上句「五派生」实列四址系漏败方; vftable 写点唯一): +8 qword (ctor a2 透传, 待裁) / **+16 = 国 tag** (重建链 sub_140BB48F0(loser+16) tag→国解析的权威用法; 与受益族 +8 坐标不同源 — 败方不继承受益基帧, 直继自身 vtable) / +24 32B 容器头 (待裁) / +48 screening_ic (ctor 清零) / **+56 / +80 / +104 / +128 = 四行动条目表** CPdxArray 24B (take_states 12495 / liberate 12496 / puppet 12497 / force_government 12498) / **+152 take-navy 条目表** / +176 civil_war_target / +180 civil_war_enemy = u32 标量 tag (写点 = SetupCivilWarOutcome 0x140E4FA60: 败方条目 +180 = 胜方 tag DWORD 直写, 断言 :3848「BestCivilWarWinner...」闩 byte_14333D055 / :3855「pLoser」闩 byte_14333D056; 败方容器 = conf+120 data/+132 count u32 tag 元; 纯内战路 sub_140E45310 = AnnexedByWinner 全吞并) / +200 清零 (待裁)。

**重建链 (定案)**: 总入口 sub_141455F50 五步序 {sub_141457220 填 +56 (88B 条目) / **sub_141456140 = 步骤 2 → CLiberateCountryAction (12496, +80)** / **sub_141456940 = 步骤 3 → puppet 表 (+104, token 12497) 重建, 门 = 国非党魁; 构 CPuppetCountryAction ctor sub_1415190D0: 96B, +72 州 / +80 tag / +88 = 0** / sub_141455F90 填 +128 (门 = 国非党魁 sub_140D40550 假; 构 **CForceGovernmentAction** ctor sub_141518EF0: +72 州 / +80 tag) / 0x141456E30 填 +152} — 五步映射 +56/+80/+104/+128/+152 补全; 变体 sub_141458940 同序但门 = ¬(loser+176) (内战目标国不重建 — civil_war_target 消费面新证); 上游触发 sub_140E4F240 (peaceconference.cpp) 逐败方调用。**take-navy 清单 0x141456E30 (定案)**: sub_1406EB830 取装备池变体表 → 逐变体 sub_14100FF30 解出 (空 → :933 `Variant from equipment pool is null` 断言); 变体+1032 **bit6 (0x40)** → 入选, 每变体金额 = 100000/N (定点均摊) 构 **CTakeNavyPeaceAction** (ctor sub_1415191A0, 88B, a3 = &loser+16 tag) 推 +152; 候选空 → 顺序扫池取首个 **0x80 或 0x100** 旗变体, 以空槽 + 全额 100000 构单条目 (:951 同串断言)。

**投影计数 0x141457530 / 裸 gather 0x141457D80** (定案; 同 switch 分派: 12495→+56 / 12496→+80 / 12497→+104 / 12498→+128 / 12527 (take_navy) → 断言 :728 `Peace action type is not state related` / 其余 → :731 `unknown peace action type`): 主体 sub_141452F50 = 容器全元拷入 scratch → 元 vtable[19] 可派门 (+ vtable[15] 同源门链) → 州匹配 (条目 +72 == 行动 +88 — 两个不同子类布局, 勿按同一偏移混读) → 幸存元推入出参表; 530 差分 = 出参非空取首元 vtable[16] 把结果写调用方 u32 出参 (空表写 0) — 「该行动类型下匹配量值」投影 (调用方 sub_140E3B9F0 = peaceconference.cpp:2455 `pLoser` 断言点; 12495 走捷径直取行动+200 tag)。sub_140E38250 = 败方查找原语 (conf+272 败方向量 {data@272, count@284} 按 tag 匹配 — 元解引 +16 == tag 或流亡同源判)。 0x140E3B9F0 实名 = CPeaceConference::CalcPossibleActionForState (:2467 断言串自名, 分派 12495 直取 +200 / 12496-98 委派投影计数; pLoser 断言 :2455)。

**按类型 + 目标 tag 聚合可用行动 sub_141457400** (定案): 已结算旗 (a1+176) 置位 → 空聚合; 五型分派 12495 (take_states) → a1+56 / 12496 (liberate) → a1+80 / 12497 (puppet) → a1+104 / 12498 (force_government) → a1+128, 均经聚合器 sub_1414531F0 (收集表内元素 → vtable[16] 取目标 tag → 直配或 sub_140BB52F0 等价判 → sub_140E49E10 州可用性门 → 入 24B 出参容器); **12526 (take_navy) → a1+152** 经独立聚合器 sub_141458720 → sub_141453700 (**不走州门** — take_navy 在投影/gather 变体被 :728 拒入, 在本聚合器合规, 两族差异定案); 非候选类型断言 :685 (闩 byte_14338A4E9)。
**三 on_action 全局** (sub_140E4FED0 初始化, 经 sub_140A792B0 在 on_action 库按名填, 门 = 条目+24): qword_14333D010 = "on_liberate" / qword_14333D018 = "on_puppet" / qword_14333D020 = "on_force_government"; 三 Execute 各发其一, payload = 双记录链 {b+96 新 tag, b+88 源 tag}, 经 sub_140162FB0() → sub_140A79BA0。

> **CMessage 基 (72B; vtable 0x1429CCCB8 仅 2 槽, 无 Save/Load = 运行时件)**: {+8/+16 消息行链表 first/last, +24 行数 u32, +28 u8, +32 sender tag (推定), +36 target tag (推定), +40 CGameDate 创建时刻 (**= \*(gs+1128) 当前日期直证**), +56 CGameDate 第二日期 (未填待裁), +64 qword 待裁}; 行节点 88B malloc(0x58) {串 32B ×2 (原文/本地化推定), prev@+64, next@+72, u8@+80}。**CDiplomaticMessage** (vtable 0x1429CCCD0; ctor sub_1414E7D70): 基段 + {+72 u32, +76 u8}。

**CPeaceProposalAction** (和平提案记录, 120B; vtable 0x14298BE80; CDiplomaticAction 派生 §4.10.13; clone 0x1411018D0): +8 token = 12474 peace_proposal; 派生段与基类全同 (§4.10.13 表); 无自有新字段 (sizeof = 基类 120)。

**CWarGoalType** (战目标类型脚本定义, ~820B; vtable 0x14293BEA0; TNullObject vtable 0x14293BFA8; writer = CFG 空桩不落盘; reader 0x140A3B930; 载库 CWarGoalDatabase 0x332EF28 = idb wargoal 已挂): +64 allowed(12263) / +152 available(12264) / +240 take_states(12495) / +328 liberate(12496) / +416 puppet(12497) / +504 force_government(12498) / +592 instant_reward(12306) / +680 war_name(11288) 串 / +716 take_states_limit(12530) / +720 liberate_limit(12571) / +724 puppet_limit(12572) / +728 force_government_limit(13558) / +732 generate_base_cost(13337) / +736 generate_per_state_cost(13338) / +740 expire(12277) / +744..+800 四组代价×威胁量化系数 (take_states_cost 12558 / liberate_cost 12573 / puppet_cost 12560 / force_government_cost 12561 / 四 threat_factor 13557-13561; 读形 = 100000 + read*1000/100000 定点) / +808 threat(11197) i64 / +816 annex(10726)。

#### 4.10.31 和约动作族 (CPeaceAction 独立基族 — 非 CDiplomaticAction 系)

**CPeaceAction** (vtable 0x1429D2CA0, ctor 0x141518F90, writer 真体 0x141520010 / reader 真体 0x14151F740): +8 u32 行动类 token (ctor a2) / +16 name 32B (27, token 直名串) / **+48 taker (12501)** 得地/受益方 tag / **+52 giver (12500)** 失地/出让方 tag / **+56 negotiator (12518)** 谈判方 tag / **+60 status (208)** u32 / **+64 cost (10323)** 行动代价 u32。中间基 **CStatePeaceAction** (vtable 0x1429D2DC0): +72 state (439) / +76..+79 四旗。派生:

| 类 | vtable | token | 增量字段 |
|---|---|---|---|
| CTakeStateAction | 0x1429D2EE0 | 12495 take_states | = CStatePeaceAction 全量: +72 state (439) / **+76 demilitarized_zone (12531) / +77 war_reparation (12532) / +78 resource_rights (12533) / +79 dismantle_industry (12534)** (置位才写); writer 0x1415200C0 / reader 0x14151FA50 |
| CTakeNavyPeaceAction | 0x1429D3360 | 12526 take_navy | +16 name 覆写 = "PEACE_TAKE_NAVY_LABEL" / +72 ship (键 10400; writer 写 u32@ship+8; reader 运行态按 ship+8 refid 从 giver 舰船表反查 CShip* 指针落 +72, 源成员名 _pCapitalShip, 未命中断言 "Giver should possess this ship" :1233) / +80 ratio qword (694); writer 0x141520150 / reader 0x14151FAC0; 工厂 sub_14151B860 (cpp:309) 12526 分支, 存档侧经动作装载器 sub_1419F4A70 (12585 actions) 重建; UI 行构建 sub_141860410, tooltip "take all screening ships" |
| CForceGovernmentAction | 0x1429D3240 | 12498 force_government | +72 state / **+80 = 目标国 tag** (puppet=12497 键; 意识形态不存于动作, 由 taker(+48) 国执政意识形态派生 — SplitData 键三处读证) |
| CPuppetCountryAction | 0x1429D3120 | 12497 puppet | +72 state / +80 TAG (writer 与 ForceGovernment 同址) / +88 预留 |
| CLiberateCountryAction | 0x1429D3000 | 12496 liberate | +72 state / **+80 = 被解放 TAG** (liberate=12496 键); 校验包装 0x141519780 = cores 门 (lib_cc+1192/+1204, 断言 "Liberated state was not a core" :811) + 尾调通用接收方校验叶 sub_141519890; liberate 校验三变体 0x14151EE00/0x14151ECD0/0x14151EF90 (:779/:1104/:933) 共享尾 = action state ∈ giver.cc owned_states (cc+1144 第三处独立消费); 门栈差异 = 参与者对 sub_140E47340 (pLoser 查找) / sub_140E48090 (成员判定) + ECD0 入口 politics+69 旗 + EF90 cc+1328{c@+1340} 在册快通道 (元素 {+56 tag, +120 tag 向量}, 业务名待裁) + LABEL_18 politics+77 旗 ∧ 特性门 21 ∧ 关系门 sub_1406760A0 (语义待裁); vtable 槽位归属未决 (需 exe 直读) |

> conf+416 竞标表元素 = CPdxArray<scoped<CPeaceAction>> (dynamic_cast 直证同族); pc_is_state_claimed_and_taken_by 触发器读 action+8==12495/+48 ✓; 派生槽 [8+] 每类真覆写 (执行/检验行为, 未逐读)。

> **本域 GUI 类布局**: 见 4.30.44 / 4.31.39 / 4.31.55。

#### 4.10.32 投降/吞并/流亡全链

投降全链 = 以 CCountry 为主体、CDiplomacyStatus (dip) 为状态载体的日更驱动链
(sub_1406E16C0, country.cpp:5248-5433, §4.2.7 序13 在册):

| 步 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 门 1/2 | cc+5208 ∧ sub_140BBED40 | 和会挂起旗 (=0 才进; 置 1 = sub_140E49810 / 清 0 = sub_140E45730 peaceconference.cpp:726) ∧ 活跃和会存在 (mgr+20 ≠0 跳过) | 定案 |
| 进度计算 | **sub_1406DA100** | 进度 = 100000×占领比/surrender_limit: cc+1076=0 (无受控省; cc+1076 = cc+1064 controlled_provinces 向量计数 — 取用 thunk sub_1406ECFE0 直证, 原「本土 VP 点基数」说废) → 直接 100000; base = BASE_SURRENDER_LIMIT (qword_143333CD0) + 修正 146 MODIFIER_SURRENDER_LIMIT; 上限 = min(100000−修正 148 MAX_SURRENDER_LIMIT_OFFSET, MIN_SURRENDER_LIMIT); 有 recipient (cc+12) → base −= SURRENDER_LIMIT_REDUCTION_PER_COLLABORATION × 合作占领度; 无核心 → × SURRENDER_LIMIT_MULT_FOR_COUNTRIES_WITH_NO_CORES; +修正 147 FORCED 后双钳; 占领比 = 100000−100000×(cc+4924/4920)/(cc+4932/4928) | 定案 |
| 进度满门 | BASE_SURRENDER_LEVEL qword_1433314A8 | ≥ 100000 ∨ owned_states≤0 ∨ dword_14332F650 强制投降旗命中 → 执行体 | 定案 |
| CanSurrender | **sub_1406D7B20** | ① 无 owned_states → 1; ② 宗主不可降; ③ 同阵营 major 与 recipient 有活战争且进度未满 → "CAN_SURRENDER_FACTION_MEMBERS" 0; ④ 傀儡 → 递归宗主; ⑤ 开战天数 = (gs+1128 − wr+32)/24 ≥ DAYS_OF_WAR_BEFORE_SURRENDER → 1 否则 "CANNOT_SURRENDER_NOT_ENOUGH_DAYS" 0 | 定案 |
| 执行体 | sub_1406E16C0 内 | ① **on_capitulation_immediate**; ② 附属 autonomy 扰动; ③ 本土移交编排 sub_1406DFF00 (锚 = cc+4124 州 ∨ 首都州; 两 COwnerArea 累计 VP × TENSION_CAPITULATE 入紧张度); ④ **逐省逐州移交 sub_1406E0420** (占领 bundle 窗口: 省在场单位 — 本国陆单位入删除列表 / 敌方控制省否决; 省 SetController sub_140E801A0 (recipient/维持) / 州 owner==本国 → **SetController sub_1409DDA40(州, recipient)** 否则还给他国 owner; 尾 sub_1409DFC20 再判定); ⑤ 紧张度 = 州 VP × (cores 含 recipient → TENSION_ANNEX_CORE / claims 含 → _CLAIM / 否则 _NO_CLAIM) × wargoal 比例; ⑥ **CGameState::DeleteUnit sub_1401D6690** 删境内单位; ⑦ 部署清理 sub_140D12EC0; ⑧ 无立足点 → PP 清零随机分发; ⑨ 落章 dip+736=1 / dip+752=gs+1128; ⑩ **on_capitulation**; ⑪ 开除阵营 sub_140D8D370 (leader → sub_140D89220 选新领袖 → SetLeader); ⑫ 受降国核心州布抵抗 sub_140711100; ⑬ 无流亡 → **sub_141515620 终结全部战争关系**; ⑭ 舰队处置分支 (有立足点保留 / 否则停产+燃料清+舰队 sub_141022530; 领袖移交∨host>0 → 流亡海军移交 sub_141020680) | 定案 |
| 和会创建 | 尾段 LABEL_243 | 参与者计算 sub_140E4DD80 (发 on_before_peace_conference_start) → **CreatePeaceConference sub_140BBEAD0** (malloc 632 + ctor sub_140E366D0; 与白和平同入口) → Start sub_140E4F240 (conf+52/56 MainLoser/Winner ✓ §4.10.27; 参与国枚举 + 全自动 AI 局立即 EndWarsTerminate = §4.10.4 路径①) → **sub_140E49810: conf+96 winners (c@+108) 与 conf+120 losers (c@+132) 逐 tag 置 *(国+5208)=1** = 和会门反向闭合 | 定案 |

流亡政府建立 (定案): 入口 **sub_1406D5FA0 BecomeExileOnCapitulation**
(country.cpp:14947 断言; 门 = 曾是领袖 ∧ faction 存活 ∧ sub_140D8A4D0) →
**SetHost sub_140D34DC0** (dip+424 权威写者: 旧 host 摘除 → `*(dip+424) =
host tid` → host 侧 dip+400 数组 push 本国 tag → sub_14118BA30 入 host 阵营
→ legitimacy (dip+432) = clamp(≤GIE_MAX_LEGITIMACY, 基 = GIE_CAPITULATE_
MAX_STOCKPILE_TRANSFER × sub_140D3D630/1e5)) → 装备/生产转移 host
(sub_140713DD0) → 流亡师转移建立 (CExileDivisionsTransfer, §4.10.19) →
收留者逐个转新 host (**on_host_changed_from_capitulation**) → 玩家国弹窗
BECAME_EXILE。

吞并链 (annex_country, 定案): **CAnnexCountryEffect::Execute sub_14034D880**
→ **CCountry::Annex sub_1406D3F00** (1436 行主干): 通知 → 突袭清理 → 生产
清理 → 舰队转移 sub_141022AB0 → **装备转移 sub_14100CCE0 ×2** (现役 ×
ANNEX_FIELD_EQUIPMENT_RATIO / 库存 × ANNEX_STOCKPILES_RATIO) → 阵营成员分摊
→ 军队处理 → **占领 bundle 内逐州 SetOwner sub_1409DE560 (所有权!) + 逐省
SetController** → 终战 (sub_140D1E470 ×2 → **sub_140D1CC40 CWarRelation::End**
+ dip+792 重置) → dip 缓存重建 sub_140D46650 → **sub_141515B00 撤销全部
市场合同** → 五连清理 → 布抵抗 → **sub_1406FF1F0(双方, 0xFFFFFFF) 全位
修正重算**。⚠ 投降只走**控制权**转移 (SetController), 吞并走**所有权**
(SetOwner) — 两链共用原语但语义不同。

新字段: cc+12 = SurrenderRecipient tag 缓存 / cc+1076 = cc+1064 controlled_provinces 向量计数 (原「本土 VP 点基数」说废) /
cc+4920/4924/4932 = 占领点计数族 (与 +4928 配对) / cc+5209 = 阵营领袖资格旗
(推定); dip+152 = 战争参与方敌方 tag 数组 (count@+164) / dip+392 = 宗主 tag /
dip+648 = 本国 CCountry 回指 / dip+656 = CFaction*; CFaction+1480 =
member_rules 条目数组 (count@+1492, sub_140D8A4D0 leader/特权判定);
CWarRelation+32 = 战争开始时刻 (开战天数计算); CPeaceConference+96/+120 =
winners/losers 原 tag 数组 (定案)。§4.3.1 cc+5208 行写者补齐 (置 1 =
sub_140E49810 / 清 0 = sub_140E45730) 升定案。

#### 4.10.33 自治度日增减执行链

挂点 = CCountry::DailyUpdate 外交步 → **CDiplomacy::DailyUpdate sub_140D3B920**
(zone "diplomacy.daily") 段④ `dip+848 非空 → sub_140675C00` (定案)。全链
DLC 门 sub_1401AEB50(5) (TfV 自治域)。

**CCurrentAutonomyStatus::DailyUpdate sub_140675C00 四类日增益** (全经
**AddAutonomyScore sub_1406745B0**: effects 条目 value+=增量 / progress(+8)+=
增量 / 钳位 [下界基(+56)−margin, 上界基(+72)+margin], margin =
AUTONOMOUS_SPILLOVER×AUTONOMOUS_TOTAL_SCORE = 125 分) (定案):

| 类型 | 来源 | 公式 |
|---|---|---|
| 0 | 宗主国 modifier 键 289 subjects_autonomy_gain | ≠0 → 记账 |
| 1 | 本国键 286 autonomy_gain × (键 287 global_factor + 1) | ≠0 → 记账 |
| 2 | 向宗主出口资源 (CCountryResources+1832 容器 Σ) | (键 278 + RESOURCE_SENT_AUTONOMY_DAILY_BASE + FACTOR×Σ) × (键 279+1) × (键 287+1) |
| 3 | **war score 贡献 (定案)**: 傀儡对宗主战争贡献分 × 0.6 → autonomy progress | sub_1406789C0 (dump 直读; 通道 3 = 傀儡 war score→自治度) |
| 8 | 活跃武官 (rs+528 = **宗主→我 −0.05** ATTACHE_TO_SUBJECT_EFFECT / rs+520 = **我→宗主 +0.05** ATTACHE_TO_OVERLORD_EFFECT; 原「我→宗主/宗主→我」两箭头对调说废 — define 注释 + 注册行双证, F5 验算) | ≠0 → 记账 |

**不自动换档 (定案)**: progress 顶到钳位带即停; 升/降档 = 显式命令 —
CPromoteAutonomyCommand sub_14067A3F0 (PP 代价 = next.def+1560, 缺省
AUTONOMY_LEVEL_CHANGE_PP_FREE=300) / CRemoveAutonomyCommand sub_1406783A0
(代价 = prev.def+1560 × (键 645 附件成本因子+1)) → 均调 **sub_1406798F0
换档执行**: effects 整账清空 → current(+40)=新档 → 按 rdata 0x27E3A98 九类
启用掩码预建 0 值账目行 (类型 2,3,5,6,7,8) → 全量修正重算 → 刷名缓存;
**last_change(+96 CGameDate hours) = gs+1128** (sanctuary 30 天冷静期起点)。

每日换档判定 sub_1406797A0 (日计算器尾调): ① path 容器重建 sub_1406746E0
(遍历 CAutonomousState 库 qword_14332EE18; 候选门 = current.def+312
allowed_levels_filter 名单 ∧ def+48 allowed 触发器 (subject,overlord) scope
求值); ② current 仍在 path → sub_140679660 只重算 prev/next/边界基 (下界基 =
**AUTONOMOUS_TOTAL_SCORE** (qword_1433339F8, defines_map_1193.txt 直证; 满值 5000) ×current.def+1544 min_freedom_level / 上界基 = next 同式, 无 next
= AUTONOMOUS_TOTAL_SCORE 满值); current 被 path 筛出 (定义变更) → 按 progress 重定位到最后一个
合法档 → 换档。**def+1544 = min_freedom_level (定名, 旧「rank 权重」推定废)**。

生命周期: ctor sub_140673ED0 (136B; +80 = 属主国回指 **CCountry\* 定名**;
+96 哨兵) / 设档定位 sub_1406799C0 (progress = 下界+比例×带宽) / 关系生效
重建 sub_140D3B0F0 (rel+88 档位 ← set_autonomy effect 闭环) / 附属缺档补建
sub_140D3C240 (初始档 = 库序第一个 def+45 default 且 allowed, 挂 gs 级国家
初始化 pass sub_1401DA490) / PostLoad sub_1406780F0 (vtable[8]; !current 兜底
+ 恒重算边界) / **reader sub_1406791C0 (vtable[4], 书缺补)** (键 11013 progress /
89 effects / 372 path / 472 next / 14059 current / 14060 prev / 17181 →
+104 日期槽 (原「17181 last_change」定名说废 — sanctuary 锚定的 last_change 在 +88
日期对象 hours@+96, promote/remove 双写 gs+1128 且 **writer 不写 +96** ⇒ 读档后
+96 回哨兵 43808760, sanctuary 冷静期不跨存档 — F5 验算; 17181 用途待裁);
"Wrong autonous state name: %s!!!" autonomousstate.cpp:438) /
writer sub_14067AA30 (hash u32@条目+40 不落盘)。def 新字段: +45 default 旗 /
+48 allowed 触发器 / +312 filter 名单 / +1544 min_freedom_level / +1560 升降档
PP 代价 (定案)。

> F5 验算边界注 (27 项 25 一致, 公式层全部站住): ① 升档硬门 = progress ≥ 上界基 (a3=1
> 预览/AI 通道走 MAX_SCORE_DIFF_TO_CHANGE_AUTONOMY = 10 分容差); ② sanctuary 拒绝
> 文案 AUTONOMY_NOT_ENOUGH_TIME (DURATION 30 / REMAINDER 差值), 门 sub_140678120
> 升降共用; ③ 两命令换档成功均 fire on_subject_autonomy_level_change; ④ remove 缺省
> 槽代价 PP_ANNEX(300); ⑤ 类型 2 资源容器布局 (+1832 外层 24B / 值 +152 / tag +136)。
> F6 验算 (sub_14121F1D0 后勤满足度, 6 项全一致): 火车比 clamp 实为双向 [0,1e5] 含
> INT64_MIN 溢出守卫; 流量比容器精确布局 begin@css+208 / 计数@+220 / 跨距 40 /
> 子对象@+32 判空跳过 — §4.21.1c 主体定案全部站住。

#### 4.10.34 流亡 legitimacy 链与 diplomacy.daily 全函数

**CDiplomacyStatus::DailyUpdate sub_140D3B920** ("diplomacy.daily",
diplomacy.cpp:2297) 六段 (定案): ① **wargoal 过期**: 倒序扫 dip+104
available_wargoals, wg 日期 ≥ 43817520 哨兵 ∧ < gs+1128 → 三处摘除
(dip+104/dip+128/对方 cc+1328) + fire **on_wargoal_expire**; ② rs 日更 ×2
(sub_140D2AF60: 关系对象虚槽[14] 日 tick — 改善关系步长公式 sub_140D237B0
(relation.cpp:1746, 全 ×1e5 定点): v13 = 1e5×opinion(B 对 A, cached_sum);
v18 = 1e5×K/(v13+1e5) (opinion>0) 否则 1e5×K/(1e5−v13), K = qword_1430B1360
= 2e7 (=200.0); v19 = min(v18, 5e5) cap 5.0/日; 步长 = (mod155_B+1e5+mod155_A)×
(0.5 + v19/2 + mod154_B + mod154_A)/1e5 [154 = OPINION_GAIN_MONTHLY 双侧 /
155 = OPINION_GAIN_MONTHLY_FACTOR 双侧]; 双方执政 party 的 ideology 名
stricmp 相等 → 再乘 (mod157_B+mod157_A+1e5)×(mod156_B+步长)/1e5 [156/157 =
SAME_IDEOLOGY 系]; **符号恒正, opinion 值从不数值递减** (条目按过期时刻整体
摘除; decay 旗 = 生命周期旗); 基线 opinion=0 → ≈+3.0/日, |opinion|≥39 脱出
cap; 日更内 PP≤0 → 维持费效果仍执行 + 发 DIPLOMACY_MESSAGE_CANCELED
(REASON=US_NO_POWER); 维持费扣费玩家专属 (A==玩家 ∨ subject 链; 目标国
+1156>0 免扣) /
sub_140D251B0: rs+776 border_friction ← rs+64 + rs+256 opinions 到期复查
(do_not_expire@+57 旗; 失效 → +8 队列回收 §4.10.2)); ③ war relation 提案 (rs+744 非空 ∧ !hidden →
sub_140D1FD50 = CWarRelation::[12]); ④ 自治 daily (§4.10.33); ⑤ 流亡块
(下); ⑥ 脏关系缓存消费 (下)。

流亡块 (dip+424 host>0 门, 定案): a) **dip+640 = 完全解放旗** (未投降
dip+736 ∧ 投降进度 sub_1406DA100 ==0 — define 注释 "fully liberated...reinstated when it reaches 0" 直证); b)
`dip+432 = clamp(0, GIE_MAX_LEGITIMACY=100, +日变)` — **日变公式
sub_140D36850** = (修正 431 LEGITIMACY_DAILY + [完全解放?
GIE_LIBERATED_NATION_DAILY_LEGITIMACY_CHANGE(−1.5):0] + Σ他国关系修正 432)
× (1e5+修正 506 LEGITIMACY_FACTOR+Σ关系 506)/1e5 (tooltip 键
GIE_LEGITIMACY_DAILY_TOTAL 直证); c) 完全解放 ∧ legitimacy ≤0 →
**ReturnFromExile sub_140D43B50** (diplomacy.cpp:3743): 清 legitimacy/造将
计数 → host 摘牌 → 流亡军归还 → dip+424=0 → fire
**on_exile_government_reinstated**; d) host 工厂捐赠 sub_140D429A0 (按
legitimacy/GIE_MAX 占比向 dip+464 修正值块写修正 292/293/294
INDUSTRIAL/MILITARY_FACTORY/DOCKYARD_DONATIONS); e) **造将**: dip+440 <
count ∧ legitimacy ≥ GIE_EXILE_ARMY_LEADER_LEGITIMACY_LEVELS {30,60,90}
[dip+440] → sub_1406E6420 造将 (写 **leader+3796 government_in_exile_tag**
= §4.4 键 15034 运行期写者闭环; 置信级 trait 掷骰), ++dip+440; f) dip+320
占领核心州敌国缓存重建 sub_140D45F10。
流亡人力日增长 (计算步 sub_140CFC720; 公式定案): (exile/max) 整除比 ×
EXILE_MANPOWER_DAILY_GROWTH 族 4 define + mdef436 (含宗主块), 下限 1; 附:
自治 def 库单例 = sub_140161C30 (库查 sub_140675FC0(库, 名), 查无且 ≠ "none" 串)。

脏关系缓存 (dip+816, 升定案): 三消费点同构 (daily force=0 / sub_140D409D0
修正变化 force=1 / sub_140D3A110 hourly-AI 经 **sub_140D428E0
MarkAllAttitudesDirty** 全量标脏后冲刷); 重建器 sub_140D45AE0 判据 = 对方
激活 ∧ (当前态度失效 ∨ rs+801 脏 ∨ force∧分数<1.0); 消费 = sub_140D19E10
UpdateAttitude (当前态度 **1.5× 粘滞择优**)。**rs+801 = attitude 脏旗**
(置 1 = MarkAllAttitudesDirty / 清 0 = UpdateAttitude 尾)。

#### 4.10.35 外交 AI 态度变体谓词 [10..16] 定案

七槽全部定名 (三重证据: .rdata 槽序方法名表 0x1427E0868..08D0 / 国家游戏
变量注册链 "ai_attitude_wants_*"/"is_threatened" 静态名串逐槽绑定 /
dynamic_variables 文档):

| 槽 (+80 起) | 谓词 | 语义 |
|---|---|---|
| [10] (+80) | WantsAntagonize | 想对抗 |
| [11] (+88) | WantsWeaken | 想削弱 |
| [12] (+96) | WantsAlly | 想结盟 |
| [13] (+104) | WantsBefriend | 想交好 |
| [14] (+112) | WantsProtect | 想保护 |
| [15] (+120) | WantsIgnore | 想忽视 |
| [16] (+128) | IsThreatened | 受威胁 |

七槽实现只是共享常量桩 (0x1401807B0 = `return 1` / 0x14011D220 =
`return 0`), 变体差异纯在槽矩阵 — 语义自洽: Hostile/Outraged =
antagonize+weaken (Outraged 加 threat) / Friendly/Allied = ally+befriend
(Protective 加 protect) / Threatened = weaken+ally+befriend+threat / Neutral
唯 ignore。**槽 [9] = 可选用门** (非 null 恒真): 消费者 sub_140D45AE0/
sub_140D409D0 用它收集「态度不达标」(门假/锁定/评分<100000) 关系到 gs+816
再逐个喂 sub_140D19E10 重算 (态度生命周期闭环, §4.10.34)。CNullAIAttitude
id=0 定案 (ctor sub_14002F9F0, 名 "noattitude", 单例 qword_1433304A8, 不入
DB 数组)。ai_attitude_*_weight 权重变量: 名运行期拼接 "ai_"+名+"_weight",
通用 eval 0x1414F6B80 直调各态度 [17] 评分。⚠ §4.34.10 旗矩阵 COutragedAttitude
行 [10][11][12] 有误, 实测 = **[10][11][16]** (§4.10.24 矩阵本身正确)。
ai_attitudes.txt 头注释的 annex/coalition/vassalize/warn 四旗在 1.19.3 无
虚槽无消费者 (历史词表, 负定案)。

#### 4.10.36 改善关系月更收集链 (sub_140D1D080; CImproveRelationsRelation 生命周期收尾)

挂点 = CCountry::MonthlyUpdate (§4.2.10) 「逐国改善关系月更」段: 对每对活跃他国 B
(id>0 ∧ ≠A ∧ 非同国 ∧ owned_states>0) 取 A 的 rs (dip+8 active_relations[B idx]) 调
**sub_140D1D080** — 每月一次, 非玩家/AI 触发。日更推进 = 关系对象虚槽[14] 分发器
sub_140D2AF60 (§4.10.34 ②已载), 本函数 = 生命周期收尾 (月度)。

执行流 (定案): ①rs+504 空 → 返; ②虚槽[9] = **0x140D1C560「非隐藏 war relation ∨ 停止判定」门** (战争即停且不发消息); ③停止判定 sub_140D24720 (relation.cpp:1556):
improve_relation opinion modifier 定义 (token 11479) 缺失 → **一次性日志 + 返真**;
Σ对方侧 rs+256 opinions
中该 def 的值 ≥ **MAX_TRUST_VALUE (dword_14333154C = 100)** ∨ 对象 +88 ≥ 0 (ctor 哨兵 −1;
写者未定位) → 真; ④虚槽[22] Remove (sub_140D26810): 对方 B 对 A 的 opinion modifier
decay 旗 (+56) 清 0 + 双侧摘槽 (A 侧 rs+504 / B 侧 rs+512); ⑤仅停止判定为真时向消息系统发射。

消息发射 (走 §4.28.10 消息设置族, **非 §4.17 警报/通知面**): 单一类型
**STOPIMPROVERELATIONSMAXOPINION** (handler 单例 0x332EF60 按名查 CMessageType) →
CMessage (0x48B: vtable@0 / kv 链头尾@+8/+16 / 计数@+24 / from_tag@+32 / to_tag@+36 /
CGameDate×2@+40/+56 / CMessageType*@+64) 入 handler+88 队列, **from = to = 改善方 A**
(路由由 CMessageTypeSettings 五路开关消费端判定)。kv 参数: WHO = A 名 (A==玩家 →
localize DIPLO_OUR) / TARGET = B 名 (rs+80, **每日刷新**) / RECIPIENT = B==玩家 → localize DIPLO_US
否则 B 名 / MESSENGER = localize MESSAGE_HEAD_DIP (MAX_OPINION kv 在 1.19.3 不存在, 旧读取为死 spill);
前缀 = 玩家国 cc+272 kv 上下文整链。⚠ MESSAGE_HEAD_DIP / DIPLO_US / DIPLO_OUR /
STOPIMPROVERELATIONSMAXOPINION 四键在 1.19.3 原版本地化树 0 命中 = 代码键残留 (运行期
文本渲染走 key 回退, 推定)。

CImproveRelationsRelation (96B; vtable 0x142960588; 工厂 sub_140D1EE80 case 11479):
+80 qword = Add 时 opinion 快照 `100000×opinion(B 对 A)` (fixed×1e-5, ctor 0) /
+88 i32 = 状态字段 (工厂置 −1; **运行期无写者** — 探针 83 活实例恒 −1 + 两窗口
DR0 零真命中; 停止判定的 `+88 ≥ 0` 分支实际不可达, 停止完全由 MAX_TRUST_VALUE
值域条件驱动)。Add = sub_140D289A0
(虚槽[21], 同时给 B 对 A 的 opinion modifier 置 decay 旗 +56 = 1)。

> 同构 kv+CMessage 兄弟生产者 (全 dump handler+112 门控入队点共 4 处):
> CDiplomaticAction 执行器 sub_141103030 (MESSAGE_HEAD_DIPLOMACY, §4.32 give_guarantee 行) /
> CCountry::Annex sub_1406D3F00 (§4.10 终结链) / 本函数 / 余一处 (未逐一认领)。

外交动作执行器增补 (定案, vtable 直证批):

- **拉盟链三件套**: CCallAllyAction::Apply sub_141105320 → **接受度筛选器 sub_1410FCC40** (547 行: 构造栈上临时 CCallAllyAction 152B (基 ctor 第 7 参 = 1 → +113 = 1; token +8 = 12233) → IsValid 谓词 sub_141138CA0 → vtable[64] 决策分 (与基类桩 0x1411186D0 相等则直调桩返 0 = 去虚化形态) → sub_1401DBCE0 对象以 (73, tag, 12233) 查询加成 → `< DIPLOMATIC_ACTION_PROPOSE_SCORE(qword_143337858)` 弃) → **通知构建器 sub_1411403E0** (613 行: 玩家国门 bHasWar (cc+744 非空 ∧ !+73 字节) → 三分支 loc = DIPLOMACY_CALLED_WAR_ENEMY/ALLY + MASTER_CALLED_US_TO_WAR + PUPPET_CALLED_YOU_TO_WAR, 标题 DIPLOMACY_JOINED_WAR_TITLE)。CCallAllyAction 工厂 = sub_1410F8D00 (malloc 152B, +144 hidden = 0)。
- **宣战尾部拉盟包装器对** (sub_1410FFC50/1410FFF50, 定案; FFF50 第二列表方向推定): CDeclareWarAction::Apply 尾部 sub_1411026E0 建双列表 (8B 盟友 tag 列表 / 16B {tag,tag} 对列表) → 逐项构造 CCallAllyAction → vtable[37] CanExecute 门 → 栈上装 CDiplomaticActionCommand (断言 :110) → IsValid → 直调执行循环 sub_141104690 — 不进队列。
- **CJoinAllyAction::Apply sub_1411078D0** → 参战威胁因子构建器 sub_1410FE420 (X_JOINS_ATTACKER_WAR_THREAT / X_JOINS_CIVIL_WAR_THREAT 二分; scale = qword_1433365C8, 不在 defines_map 未决)。
- **[56] 实体三件**: CPeaceProposalAction sub_141108960 (仅 ACCEPT; bHasWar 门 :4025; 战分取负补 1e5 → sub_140BBEAD0(gs, actor, recipient, 分值, 1, 2, 1, &out) 和会建立器 (角色推定); 无战 → "Cannot set up a peace conference…" :4039) / CRequestLicensedProductionAction sub_141108F30 (清 +144 容器逐条撤销许可 → ACCEPT 且 +168 旗 → 同类再请求动作 176B → 命令包装直调循环 :12602/:12606) / CRequestForeignManpowerAction sub_141108DF0 (仅 ACCEPT; 请求量 = +120, clamp 至给予国 +808 池可用量 → 给予方扣池 sub_140CFE7E0 + 接收方 +144 记账 + 刷新; 量 0 断言 :12935)。
- **转交族共享 [56] sub_141109ED0**: CTransferSpyMasterAction + CTransferHeadOf{CounterIntel,Cryptology,Operations}Action 四表同槽单实现 (0x14298F3E8/610/838/A60), 类差异经 vtable[67] 角色钩子分流: faction 门断言 :13306 → sub_1413FC040(faction+2104 CFactionUpgradeStatus, role, tag, 0) 转交登记 (role 枚举待裁) → 规则门 sub_1401AEB50(50) → 间谍 PP 槽 sub_140BB4560(cc)+72 扣 100000×FACTION_INTELLIGENCE_UNLOCK_COST 钳 ≥0 → 收件箱 (视图 +1192 容器) 尾插 216B 元 {+0 u32=4, +208 u8=1} + sub_140B6B050 刷新。
- **CGenerateWarGoalAction[32] 前置门** (sub_1411401E0 扩): bHasWar 同形门 (cc+744/!+73) 假 → 返 0; 阵营一致性四门 (无阵营返 1 / 同阵营返 0 / subject 宗主同阵营断言 :2926 "Subject not in same faction" 返 0)。
- **bHasWar 同形前置门** (cc+744 非空 ∧ !*(u8*)(cc+73) = 「处于战争」) 四点独立消费互证 (141108960/141119EC0/1411401E0/1411403E0) — 建议后续以此命名归并。

politics.cpp 簇对账增补 (11 函数闭环; 断言行号谱 139..1781 单调, 单编译单元确认):

**三 on_action 发射点全定案**: `on_new_term_election` :491 (politics.daily 段①) /
`on_government_change` :884 (SetElectionSettings 合体函数 sub_140BA7D80 — 签名
(ps, 组, elections_allowed, frequency, out 日期*); 组指针非空即换党; 尾全局脏旗
qword_14333CFB8+129 = 0x0101 待裁) / `on_ruling_party_change_immediate` :1637
(sub_140BAD1F0 发射器, gs+2617 门; **temp_var:old_ideology_token = 旧执政组 token×1e5**
fire 前设置)。

**无效理念移除/替换器 sub_140BABD00** (新定性): 门 = idea 组空 (idea+2720 → 组 +48 计数
≤0) ∨ removal_cost (idea+2736) > −1e5 → 直移除; 否则组内三谓词筛替代取最后命中; 消息键
POLITICS_INVALID_IDEA_REMOVED/_REPLACED; 由 politics.daily 段⑥驱动 (sub_140FD6660 谓词)。
**理念装备/移除统一入口 sub_140BAF050(ps, 移除|0, 加入|0, −1)** (簇外, 三方消费)。

**SetRulingParty 第三实现 = sub_140BAE690 (组查找版)** (新定性): 线性扫 parties 找
party+24 组指针 == 目标; 调用者 = set_politics 效果 Execute (sub_140364020 全形式 +
sub_140286380 ruling_party 分支) + 内战执行体 sub_1410DDFE0。**EnsurePartyLeaders
sub_140BA8E70** (:139; sub_1411A3300 无领袖判定 / sub_1411A4610 创建; 6 调用点)。

**popularity 构成补全为四源** (核 sub_140BA7770 全读): ① 国家修正 cc+1464 [组+1536] /
② 执政意识形态修正块 [组+1536] (sub_1406F98C0 取, 空则新建) / ③ **guarantee 修正** (dip+80
容器逐 rs 查 [组+1544 drift_from_guarantees]) / ④ 宗主同组加成 [cc+1464][253] (sub_1406CF890
= CCountry::GetPolitics 命名候选, 返回 cc+3984); 另 boost 关系贡献第二累加器 (dip+32 全关系
缓存, rel vtable 槽[20] 激活 ∧ rel+80 == 本党组 → sub_140D1A160 影响值)。迁移核 sub_140BACF00:
七档缩放只作用正 drift (boost/补正走 a5=1 不缩放); 收件箱 tag=12 = 理念过期弹窗类
(对照 call_allies = 2)。

**parties 存档块读法定案** (键 12280): 按 ideology token 匹配已建党 (party+8 == 块名
token), **党本体由静态 def 构建存档不新建**, 无此党跳块; 命中走党 vtable+24 Parse。

**国初始化 politics 装配器 sub_140BACB70** (新定性, 调用点未定位疑虚槽挂载): 选举重推 +
造领袖 + 执政党 popularity 最大兜底 + **理念 equipment_bonus (idea+2696
CTraitEquipmentBonus 表) → CProductionStatus (cc+3944) 应用链** (sub_140FCDF30→sub_140E5F740)
+ 控制州 owner 核实 (sub_1409DB650)。

politics.daily 七段定案: ① 选举推进 / ② PP 日增 (:1602 守卫版入账) / ③ popularity /
④ timed activities (vtable+96 失效 → vtable+112 完成效果) / ⑤ timed_ideas 过期 (收件箱 tag=12 +
CIdeaExpiredNotification, 门 = idea+124 旗 == 0) / ⑥ 无效理念日检 / ⑦ 过期收尾
(CalcMod + sub_1406DD0C0 + sub_1406FF1F0(cc, 520 = bit3+bit9))。:1691/:1697 daily 版断言对
与 tooltip 版 :1770/:1781 成对。CIdeologyGroup+175 u8 旗 = 新字段候选 (语义待裁)。

#### 4.10.12b idea_database.cpp 装载域增补 (CIdeaDatabase 骨架与双加载器; 6 函闭环)

清册 (6/6 函体内含 idea_database.cpp 路径锚): AddWithDupCheck 0x140A40D60 (67) / AddGroup
0x140A40B50 (120) / AddCategory 0x140A41C40 (267) / PostLoad 0x140A43720 (116, **虚槽 [3]**
PE vtable 直证; 组+112 ← slot_ledgers 槽+40 位旗; 逐理念 GetLedger 回退链 ==0xFFFF →
"idea %s has no ledger assigned") / 目录版解析器 0x140A43C30 (740; idea_categories+ideas
两键) / 全量版孪生解析器 0x140A40E90 (709; 三键含 slot_ledgers=19323; 外部 LoadAll 逐文件
调它再逐类别 AddCategory)。

**CIdeaDatabase 布局骨架** (定案): +80 名索引 / +104 主表 {data, cap@112, count@116,
alloc@120} / +128 RH 表 (读侧待裁) / +160 **类别表** (CIdeaCategory, 键 = +16 名串 sso16,
15 计 = idea_tags 类别数) / +184 类别名哈希表 (48B 槽) / +216 **组表** (CIdeaGroupType,
元素 +8 token, 25 计 = 原版组数) / +240 slot_ledgers 表 — 三哈希表同族 48B 槽。

**同名组合并律** (定案): AddGroup 按组 token 查 +216, 同名旧组存在 → 旧组归并理念
(sub_140FCDE60) + 新壳 vtable[0] deleting-dtor (实参 1) 销毁; 无旧组 → 查类别 (无 → "Idea group %s cannot be
associated with a category (/idea_tags/)" :345) → SetCategory (sub_140FD6590: **收件对象 = CIdeaGroupType** — 组+96 类别/+48 槽位) → push 组表; 类别无效 "It will be ignored" 不入库。AddWithDupCheck =
**内联线性扫描** (自下标 1 线扫 +104 比元素+8 token, 命中有效理念才报 "Duplicate idea."
:311 ([0] = Null Object 占位; 槽位占用旗 = elem+56); 追加 sub_1401205A0(a1+104) / 名注册 sub_140623390(a1+80, idea+64); PE 无 G2 共享调用)。四制造商类别
(tank/naval/aircraft/materiel_manufacturer) 特判注册 `<名>_MIO` 槽 id (id 源 =
qword_14333D6E8 管理器, advisor.cpp 同源 — 同源写者实证 = sub_14129F190 (advisor.cpp:255, CAdvisor+632 = sub_141484090(管理器, 名 hash) 查索引, miss 断言 + 慢路 sub_141483B40 get-or-generate; §4.4.27))。

**伴生类布局** (RTTI 直名 ctor): CIdeaGroupType 120B / CIdeaCategory 136B。ledger 位旗链
(idea+3332 → 组+112 → 类别+132) 与 §4.6 doctrine 位旗全表完全互证 (hidden=1/civilian=2/
army=4/navy=8/air=0x10/military=0x1C/全集=0x1E/invalid=0xFFFF) — 升定案。

**装载链全家** (增补定案): 三 wrapper = LoadDB-plain sub_140188B20 (gameitemdatabase.h:160 "DB already loaded") / InitFromDirectory sub_1401897A0 (:179 同检查) / LoadFiles sub_14019E0C0 ("Reloading Database: " 逐路径) → 共享装载体 0x140A43130; **双解析模式门 = 主表计数 db+116** (>1 已载 → 目录版解析器逐文件 / ≤1 首载 → 全量版装载器 0x140A3DF60 → 全量版解析器); 家族 [2]+[3]+[4] 三连对号 (非 ReadContent 二阶段); 全量版两调用点同在 0x140A3DF60 体内 (循环内 + 循环后尾随), 非异函; 预装载助手 sub_140A43300 写 db+48 基路径串。**CIdea 条目 = 3344B (malloc 0xD10, ctor sub_140FCD0E0)**; 新字段: **+2720 = 所属组指针 (qword) / +2744 = 库内 id u32 (插入序 = 主表下标)** (sub_140FD6650 双写; 归并路径重指旧组); CIdeaGroupType 120B / CIdeaCategory 136B 升 malloc 直证; 目录版组内特键 law(13681) → 组+88 / designer(13889) → 组+89 / use_list_view(19657) → 组+108 (组级键解析器 sub_140FD5DE0 三 case), 同类别同名 stricmp 合并律; AddWithDupCheck 尾 push 主表 + +80 名索引 (键 = entry+64 名串); PostLoad slot_ledgers 探测 = FNV-1(组名) 线性步进 48B 槽 {dist@+4, string@+8, value@+40}, miss → 组+112 = 0。

⚠ ref/token_table_1193.txt 9635/10065/10396 三 id 与 PE 立即数链语义不符 (局部漂移,
疑 mod 填充重排同源); 位旗语义以本节 + §4.6 为准, token 名以运行时 lexer 复核为准。

未决: CIdeaGroupType vtable[3] 装载器本体 / +128 RH 读侧 / 全量版第二调用域 / +2744 读侧
消费 / CIdeaCategory +80/+56 语义。

#### 4.10.12c CIdea 装载收尾 FinalizeIdeas (idea.cpp 0x140FD42D0 432 行)

调用方 = idea_database.cpp 装载收尾循环 (唯一调用点): 遍历库主表 (data@库+104, count@库+116) 逐条调本函, 尾随 sub_140FD19F0 (ledger 解析, 返 0xFFFF → "idea %s has no ledger assigned", 通道 4096)。

触及布局 (idea 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +64 | MSVC SSO 32B | 名串 (错误日志实参) |
| +120 | CModifier (内嵌于 +104 CStaticModifier, = +104+16) | 修正累加器目标 |
| +648 | CStaticModifier 544B | 源修正 (modifier 块) 累入 +120 |
| +2696 | 引擎向量 24B | equipment_bonus {data@+2696, cap@+2704, count@+2708, alloc@+2712}, 元 = CTraitEquipmentBonus* 160B |
| +2816 | 引擎向量 24B | traits 产物 {data@+2816, cap@+2824, count@+2828, alloc@+2832}, 元 = CTrait* 8B |
| +2840 | 引擎向量 24B | traits 装载期暂存 {data@+2840, count@+2852}, 元 = 32B std::string SSO (非 8B 指针) |

执行流程 (定案):

| 步 | 动作 | 门 |
|---|---|---|
| 1 | 遍历 +2840 (count@+2852, 元 32B SSO 串), `sub_14071F960(trait 库 qword_14332EE68, 串)` → CTrait*; trait+16 有效旗 → 入 +2816 (1.5× 增长) | 无效 → :791 "Invalid trait for idea : %s %s" (通道 4096), 不中断 |
| 2 | +2840 清空 (全量析构 + count=0) + shrink-to-fit (分配器 vtable+24 判 cap 归零后换 data) | — |
| 3 | 遍历 +2696, 逐条对装备库 (count@库+116) 枚举类型 sub_1409F87A0, sub_140631E70(bonus, type) 全不中 → :816 "Idea %s equipment_bonus. No valid type of equipment: %s" (通道 4096), 不中断 | 门 = 全局旗 byte_14332EC69 |
| 4 | `sub_1405583A0(+120)` 清零 → `sub_140557840(+120, +648, 100000, −1, 0)` 累入 modifier 块 | 修正累加 |
| 5 | 逐 trait (+2816): `sub_140557840(+120, trait+152, 100000, −1, 0)` 累入特质修正; 再逐 trait 的 equipment_bonus 向量 (trait+368 data / trait+380 count) | — |
| 6 | 装备加成并合: 对每条 CSpecificEquipmentBonus — 在 +2696 查同条目 (+48 token 相等 **且** +16 名 stricmp 相等); 未中 → malloc 0xA0 逐层构造 (CEquipmentStats → CEquipmentBonus → CSpecificEquipmentBonus → CTraitEquipmentBonus 四段 vtable 装换 + 字段拷贝: 名+16 / token+48 / stats+64..+76 / +88..+100 / +8 / +112 / +116 / owner+120 / trait 名 SSO+128) 入 +2696; 已中 → sub_1406315B0(旧件+56, 新件+56) 并合装备加成图 | — |
| 7 | +2696 压缩: 谓词 sub_140632100(件+56) 为假的条目剔除前移, count@+2708 递减 | — |
| 8 | trait 库 / 装备库访问前各一次 gameitemdatabase.h:142 断言 (B52, 闩 byte_14332F8D3 / byte_14332F582) | 库实例门 |

#### 4.10.37 peacecosthelper.cpp 和会代价折扣族 (8 函闭环; conf+600 消费侧)

清册 (8/8 函体内含 peacecosthelper.cpp 路径锚): GetCost 主体·state 流 0x1419F7600 (419) /
无州流 A 0x1419F8660 (365) / 无州流 B 0x1419F7ED0 (365, 三主体同五断言链 :567-577) /
影响力折扣 0x1419F9DA0 (246) / 合规折扣 0x1419F93C0 (172) / 退款因子表 0x1419FC1C0 (120) /
距离曲线 0x1419F8DF0 (117) / 行动类专用修正分派 0x1419FA2E0 (103)。

**三主体六因子乘法链** (定案; 起点 100000 fixed1e5, 每因子 cost×factor/100000 级联):
① desc 堆叠因子 (0x1419FB4A0: desc+0..+3 四字节旗 → PEACE_COST_FACTOR_STACK_{DEMILITARIZED_ZONE / WAR_REPARATION / RESOURCE_RIGHTS / DISMANTLE_INDUSTRY} 四项可叠加条款**加法堆叠** + 1.0 基座一次乘入; 日志 _STACKABLE) → ② giver UNCAPITULATED 因子 (公式见下) →
③ 合规折扣 → ④ taker×giver×negotiator 因子 → ⑤ 仅州相关流: 专用修正扫描 (枚举列表逐项查
FA2E0, 取首个非 1.0) + 影响力折扣 → ⑥ 末因子 = CONTESTED_BID 竞价递增 (定案): conf+552/+568/+584 = 三张竞价计数 std::map 锚 (非标量) — 州流键 = state id (wrapper 0x1419FB900) / 无州流 A 键 = 目标描述符+8 (分发 0x1419FB390) / 无州流 B 键 = giver tag; map 节点值+36 = 竞价计数; 因子 = 1.0 连乘 PEACE_COST_FACTOR_CONTESTED_BID 计数次, 上钳 PEACE_COST_FACTOR_CONTESTED_MAX (0x1419F53F0 系三助手同式); 计数==1 日志 _CONTESTED_BID / >1 _CONTESTED_BID_PLURAL — 多国争同一目标单价几何递增到上限。
尾 = breakdown 串发 PEACE_COST_BREAKDOWN_MODIFIER 日志 (通道标签 "PERC", debug 明细门)。
**IsStateRelated = (type != 12526 take_navy)** — 对五型集 {take_states/liberate/puppet/ ⚠ 断言文案实名 IsTargetingState (vtable+240 同槽双名义, 0x140E412D0 :1155 断言直证); sub_14151EC00 = IsFromAvailableList (语义补全)。
force_government=12495-12498, take_navy=12526} 恰为州相关判定; 无州两流的 :577 断言退化
= 只收非州相关行动。

**② UNCAPITULATED 因子公式** (0x1419F9110, PE 侧验算定案): 门 = CDiplomacyStatus+736 投降旗 (cc+3976 解引用) ∨ 投降进度 sub_1406DA100 ≥ BASE_SURRENDER_LEVEL (qword_1433314A8, 启动期 define 注册通道不在离线 map) → 因子 1.0; 未投降时 **因子 = 1.0 + PEACE_INCREASE_COST_FACTOR_PER_MISSING_PERCENT_FOR_CAPITULATION × (100 × 投降缺口)**, clamp 下界 1.0 — 缺口越大索取越贵; 中间域 Q15 定点 (换算常量 3276800 = 100<<15 / 3276800000 = 32768×100000, 非魔数除); 日志 _UNCAPITULATED。

**影响力缓存全形** (增补定案): conf+600 = 双层 std::map<state_id, map<tag, ImpactEntry>> (MSVC 红黑树节点 56B), **ImpactEntry = {dist_capital@+0, dist_core@+8, dist_controlled@+16, n_adj i32@+24}**; 内层 tag 键序 = sub_140BB5490 索引序 (非 tag 数值序); INFLUENCE 族 14 define 全对号 (major/minor 因子按 cc+5210)。距离曲线魔数除 0x29F16B11C6D1E109 五点 python 验算 = ÷100000 (与书 >>78 形态为 128 位乘积合并写法等价)。

**影响力折扣公式** (定案, 全 fixed1e5): 标量 = cc+5210 major 旗 ? INFLUENCE_MAJOR_FACTOR :
INFLUENCE_MINOR_FACTOR; 因子 = 标量 × (RATIO_CAPITAL×f_cap + RATIO_CORE×f_core +
RATIO_CONTROLLED×f_ctrl − PER_ADJACENCY×邻接数) / 1e10; f_x = 距离曲线(距离_x,
NEUTRAL_DIST_x, MAX_DIST_x, MIN/MAX_DIST_COST_MODIFIER)。**距离曲线** (0x1419F8DF0):
两段线性 + 钳位 — 0 距 → MIN 因子, 半距 → 1.0, 全距 → MAX 因子; 除 1e5 用魔数
0x29F16B11C6D1E109 >> 78 (PE 验算 = 2^78/1e5 向上取整变体)。

**合规折扣** (定案): 门 = negotiator == st+204 controller (civil-war 等价 sub_140BB52F0);
st+680 对 PEACE_COST_FACTOR_COMPLIANCE_STEPS (threshold, factor) 对数组从高往低找首个
threshold ≤ 值取配对因子, 全不满足 = 100000; 断言项数偶数/首项 = 0。

**专用修正四型分派** (0x1419FA2E0, 定案): 12495 take_states 门 = 附属对象+816 旗或
state id ∈ a2+72 数组 / 12496 liberate / 12497 puppet / 12498 force_government 各配
读取器与门; default = :727 断言 (take_navy 不应到达)。**退款因子** 0x1419FC1C0 =
PEACE_CONTEST_REFUND_FACTOR 数组拷贝 (空表回退单元素 {100000})。

**NDiplomacy define 全表锚定** (16 项): INFLUENCE_{NEUTRAL/MAX}_DIST_{CAPITAL/CORE/
CONTROLLED} 六距离 (qword_143333220..730) / MIN/MAX_DIST_COST_MODIFIER (0x143333868/950) /
RATIO_{CAPITAL/CORE/CONTROLLED} (0x143333A68/B58/C58) / PER_ADJACENCY (0x143333E20) /
MINOR/MAJOR_FACTOR (0x143333FF0/F20) / COMPLIANCE_STEPS (0x143338620) / REFUND_FACTOR
(0x143338650); 三对 half<max 启动校验 = defines.cpp:165/170/175 (错误日志形态)。

未决: 因子①②④与三末函数 (其他 CU) / InfluenceDataCache 填充点 / FA2E0 的 a2 宿主类名 /
四消费宿主 (出价/GUI 与 AI 评估两族推定) 定性。


**战败州集合消费点** = sub_140E46390 (断言源 peaceconference.cpp; `_AllLoserStates.count(StateId)==0` 门 — 和会战败国州集合的州级查询)。

#### 4.10.38 志愿军转移运行期 (volunteerstransfer.cpp; 3 函闭环 — 读档分发器 / 编组接管 / StartTransfer)

簇清册 (体内 cpp 锚 3/3; §4.10.19 writer 侧已收, 运行期本批全定性):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141522170 | 288 | :95 断言 "Bad army" (B51, 闩 byte_14338A84B) + ref.h:83 + gamestate.h:1116/1117 | CVolunteerForceTransfer 读档字段分发器 (CPersistent 槽[4] 型; **func_names sym 直证 = CVolunteerForceTransfer::Reader**) |
| sub_141522750 | 112 | :409/:418 断言 | 志愿军移交接管执行体 |
| sub_141522BE0 | 514 | :793/:851/:888 日志 + :799 断言 (闩 byte_14338A84E) | StartTransfer 本体 |

**读档 12 键互证** (§4.10.19 writer 表全符, token id 数值逐一咬合): to→T+8 / from→T+12 (名串经**国家库 qword_143330D98** 的 FNV-1a 还原 tag — sub_14071BC80 名→索引 + sub_14071BD10 取条目首 u32; 读档早期 gs+856 `_CountryLinkTags` 串表未构建, 故绕过正规串→link 入口 sub_1401DA870 直调国家库 — 与 writer 侧 `rp(gs+856)+32*tid` 取串路径**不对称**) / days→T+40 / sender→T+44 / group→T+52 / force→T+144 / target_provinces→T+48 / group_color→T+80 / group_name→T+112 / leader→T+56/+60 / leader_unit→T+64/+68。**division (471) 新定案 = 读档侧内联整建 CArmy**: malloc 1672 → **ctor sub_140C6D470 = CArmy ctor** (四基表; 基 ctor sub_140BF8B50 类型号 0; +840 起装备/人力子块); **owner = sender (T+44) 非 0 → from 国, 否则 to 国**; 嵌套块经 **CArmy+16 子对象 (第二基, vtable 0x14295A490) vtable[3] Load wrapper** Parse; **主 vtable (0x14295A2B0) 槽[23]** 假 = 空军 → :95 "Bad army" 断言 → DeleteUnit (sub_1401D6690) 立删; 真 → division CRef 写 T+16 + **从 *(army+496) 的省在场四表摘除该师 (sub_140E7FA10 = CProvince::RemoveUnit; 主表 data@+224/count@+236 + 分型 +248/+272/+296, §4.18.20)** + **取件器 sub_140BF9660 = *(army+672) 非空时 sub_140F00A60 从该宿主军数组 (data@+104/count@+116) swap-tail 移除** ( ctor 默认归属地摘出, 保持“转移中”纯容器态; 真正入战区在 StartTransfer 本节 / 到期交接 sub_141522750)。

**编组接管** (sub_141522750; 门 = group 旗 ∧ count > 0): 首军战区空 → :409 断言 → **sub_140EF1180(theatre, 0, 组名, 组色, 0) = 东道侧新建编组** (承 §4.10.19 快照) → 逐军同战区并入 (异战区 :418 断言) → 新组非空 ∧ leader 解析成功 ∧ **leader 无现任 HQ** (+4168/+4172 全零) → 栈构 64B → **sub_14184B2E0 = CSetArmyLeaderCommand::Execute** 派令 → leader_unit 解析 ≠16 → sub_140BF5BC0; 新组空 → 释放。唯一调用方 = sub_141520DE0 到期日 tick (days 每日 −1; 失效条目 swap-删; 到期走省查找交接 (失败回退 (from,to)→(from,from)) → 逐军 vtable[29] 传送 + vtable[22] 重算 → 本函; 失败次日重试)。

**StartTransfer** (sub_141522BE0): T+48 ← CProvince+164 省 id / T+40 ← dword_143335500 = **VOLUNTEERS_TRANSFER_SPEED** (define 定名); 人机日志文案 × human_ai 全局旗 (byte_14332F639 仅文案, 排雷条同址互证); 逐 division 空指针 → :799 断言 (**AddDivisions = sub_141522980** 文案直证); sender 侧军须在 from 国列表; **非 sender = 装备返还分支**: army+848/+872 两向量 + +896 byte 装池 → sub_141010F70(army+840, **qword_143335470 = VOLUNTEERS_RETURN_EQUIPMENT** 定名) → 入库存; 首个带组军 → 组名/色/leader 快照回填 (T+52 = 1); 组长军 → leader_unit; from 国 human → 引用清除; **尾部分流: sender → 一律发 on_action "on_send_volunteers" (THIS = from 国, FROM = to 国)**; 非 sender ∧ to 国 human → 逐战区登记。

#### 4.10.38a 流亡师转移运行期 (exiledivisionstransfer.cpp; 3 函闭环 — §4.10.38 志愿军族的 exile 姊妹链)

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| 0x141512DC0 | 251 | ref.h:83 + gamestate.h:1116/1117 (serfam_1193.txt:310 直证 reader 槽) | CExileDivisionsTransfer 读档字段分发器 |
| 0x141513480 | 157 | :126 空表前置 / :138 查重 "Division already in transfer." | _DivisionsInTransfer 追加器 (AddDivisions) |
| 0x1415137F0 | 75 | :485/:502 日志 (byte_143452529 门) | StartTransfer 转隶执行 |

reader 六键 (与 §4.10.19 writer 表咬合): to 10640 → +8 / from 10639 → +12 / days 10605 → +40 / is_to_host 15042 → +44 / target_provinces 11541 → +48 / division 471 → 逐条; 其余落基类分发 sub_1424BEC40。布局 56B 恰满: _DivisionsInTransfer = CRef<CArmy> CID 8B 元数组 {data@+16, cap@+24, count@+28, allocator*@+32} (writer 只写 {count, data} 对) / +52..+55 填充。**division 装载 = CArmy 内联整建** (与 §4.10.38 志愿军同构): malloc 1672 → ctor sub_140C6D470 → 槽[3] Parse → 槽[23] 校验, 失败 debug_assert "Bad army" (:84) + sub_1401D6690 删除; **归属 tag 由 is_to_host 选择 (≠0 → from, ==0 → to)** — 志愿军侧用 sender (+44), 两族分叉点。通过 → CID push + 从 *(army+496) 的省在场四表摘除 (sub_140E7FA10) + *(army+672) 非空时 sub_140F00A60 从该宿主军数组 (data@+104/count@+116) swap-tail 移除 (§4.10.38 同构)。

StartTransfer (0x1415137F0): target_provinces(+48) ← a2+164 (上游字段未决); from tag → 国对象; 人机日志文案 (AI/NOAI × humanai/nohumanai — human_ai 全局旗 byte_14332F639 再证); 逐 CID 解析 (失败置 0 跳过) → sub_140BFB4A0 + 属主挂接 + **sub_140710140(from国, army) 转隶**; sub_1406FFDB0(from国) 真 → 日志 "RemoveReferences" (:502) → sub_1406CF0E0 → sub_1402AC3C0 引用清除 (门条件未决)。

> 日志串写 `CExileDivisionsEscaping::StartTransfer` — 该类名 RTTI 谱系 (serfam/vt2class) 无载, 三函 this 布局与 CExileDivisionsTransfer 完全同体 (键映射一一咬合); 判读 = 源码内旧名/姊妹名残留, 书定名 (RTTI 优先) 不变, 定案。

**归因链**: 唯一调用方 sub_1406E71F0 = CreateVolunteersTransfer (country.cpp:13592 锚) — murmur 分组 → malloc 160 + ctor sub_1415201A0 → 三 setter + AddDivisions → 空即删 → push cc+5040 容器 (书互证) → 即调 StartTransfer。

未决: 关联 helper 名义 (属主注销/摘除/记账/编组建六函) / division 内联整建的存档形态活体验证。

#### 4.10.38b 和会胜方 AI 出价链 (peacewinnerai.cpp; 5 函闭环 — 评分公式 PE 验算 + CPeaceBiddingTurn 装配)

#### 4.10.38c 和会参与者胜方排序比较器 (peaceconferencewindow.cpp; 1 函 = sub_14185CBA0, 高置信)

#### 4.10.38d 和会行动 tooltip 生成分发器 (peacetooltiphelper.cpp; 1 函 = sub_1419E16C0, 定案/形参语义待裁)

#### 4.10.38e 和会分数对账 (peaceconferencepopups.cpp; 1 函 = sub_141E57480, 定案/退额语义待裁)

#### 4.10.38f 和会快捷竞价按钮 (peacebiddingswindow.cpp; 1 函 = sub_141E507B0, 定案/两旗语义名待裁)

#### 4.10.38g 和会需求堆叠/竞标 tooltip 构造器 (peaceconference 域; 1 函 = 0x14185E5B0, 高置信)

0x14185E5B0 (a1 = 和会需求条目, a2 = 竞标方 tag/序号, a3 = std::string* 出参): 产物形态 = `PEACE_STACK_WITH（与 {ACTION} 堆叠）\n[禁用原因]\n<竞标数>` — localize `PEACE_STACK_WITH` (1 参 ACTION) → sub_140E47A20 取需求类型 token → sub_14185F2A0 同需求堆叠/竞标计数 (推定)。**禁用注记双门**: 需求类型 ∉ {12497 puppet, 12498} → 追加 `PEACE_STACKABLE_ACTION_DISABLED_NOT_RELEVANT_PRIMARY`; 计数 ≤ 0 → 追加 `PEACE_BID_ACTION_DISABLED_NO_ITEM` (12497 = puppet 书证; 12498 待裁; puppet 族且计数 >0 时不加禁用 = 按钮可用)。尾 sub_140E3C540 数字串化 + 竞标数并入。

sub_141E507B0 (CPeaceBiddingQuickAccess 快捷按钮点击; 类身份 = `CLegacyButtonObserverGlue<CPeaceBiddingQuickAccess>` 闭包绑定直证): 门 = sub_141860F10(*(a1+16)) (和会提交状态, 假才继续); kind = *(DWORD*)(a1+1312) — 0 → `*(BYTE*)(会议+20756) = 1` / 1 → `*(BYTE*)(会议+20757) = 1` / 其他 → :146「Don't know this kind of peace bidding quick access button」B52 (闩 byte_14338C89C); 收尾恒调 sub_1418646F0(会议) (和会主填充分发)。**会议对象 +20756 / +20757 = 两类快捷竞价旗** (紧邻 §4.30 已收 +20736 completed 窗柄区; 旗名无串证待裁)。⚠ 与 §4.30:579 出价弹窗处理器 (+1312 类型 0/1 → ON_CLICK_OPEN_*_POPUP 键) 同窗族不同件 (本件写旗不开弹窗)。

sub_141E57480: 参与者/行动数组 a1+56 (计数 a1+68) 逐元 — `*a2 += *(u32*)(元+64)` (SpentScore 累加); 会议对象 = (a1+5248 idpair 双 dword 非零) ? sub_14221F310(a1+5248) : 0 (CRef → 本体, 与 §4.10:1381 CPeaceBiddingsPopUpWindow +5248 _Conference 同字段同族) → `*a3 += sub_140E3E250(会议, 元)` (RefundedScore); 尾 B52 断言 SpentScore ≥ RefundedScore「Refunding more than we spent」(:292, 闩 byte_14338C8B7)。sub_140E3E250 退额计算语义未决。

sub_1419E16C0 (同簇分发链 sub_1419E1860 / 0x1419E13C0 的第三件, §4.10.30): 432B 栈构建器 (sub_1419E0700 初始化 / sub_1419E0880 析构 / sub_1419E2660 收尾发射); a2 = CPeaceAction*; `_RTDynamicCast<CStatePeaceAction>` → sub_14151E710 取 state 对象 → sub_1419E4C40(a1, state, a4, v19); `_RTDynamicCast<CTakeNavyPeaceAction>` → 两准备器 sub_140E47890(v18, a1) / sub_140E479E0(v17, a2, a1) → 行动详情面板 sub_1419E3670 + sub_1419E31B0(a1, action, a4, v19); 两者皆非 → :424 B52 断言「what kind of peace action is this ?」(闩 byte_14338B4D1); 恒返 1。a1/a4/a5/a6 语义未决 (推定 a1 = 和会 UI 面板)。

sub_14185CBA0 (UI 列表排序比较器): a1 = {会议 qword@+0 / tab u32@+8 / 相关胜方 tag u32@+16}; 两侧 tag 各经 §4.10.26 taker tab 解析链 sub_1418600D0 解析。**三级序**: ① 主序 = 「tag == 相关胜方 tag」‖ (双非零 ∧ sub_140BB52F0 同原初国), 两侧不等 → 返该布尔 (相关胜方优先); ② 次序 = sub_140E49A40(tag) 谓词布尔 (推定 = 「仍是有效胜方」); ③ 末序 = sub_140E48090(会议, tag) 取 **CConferenceWinnerParticipant**, `*(wp+72) > *(other+72)` = **original_score 严格降序** (+72 = §4.10 已载 original_score tok 12578)。任一 tag 无效 → :1201 断言 (闩 byte_14338B20D); 任一 winner 对象空 → :1204 断言 (闩 byte_14338B20E,「How are we missing winners here?」)。

CU = `hoi4\source\peaceconference\peacewinnerai.cpp`。操作对象 = CConferenceWinnerParticipant AI 副对象 (W: +0 conf / +8 tag = Negotiator / +24 选定行动容器 count@+36 / +44 完成旗 / +48 候选容器 count@+60)。产物流终点 = **CPeaceBiddingTurn** (0x40B; ctor sub_1419F4490 vftable 符号直证; +8 tag, 两容器 @+16/+40)。

五函身份表:

| VA | 行数 | 身份 |
|---|---|---|
| 0x1419F1950 | 152 | W AI 回合总入口 (预算 = winner+76 当前分) |
| 0x1419F2360 | 477 | 评估主管线 (分派 + 聚合树 + 排序输出; 被 §4.10.37 行动详情面板 sub_1419E3670 复用) |
| 0x1419F2EA0 | 179 | take_states (12495) 州级评估 |
| 0x1419F2D50 | 55 | liberate/puppet/force_government (12496-12498) 单州评估 |
| 0x1419F3770 | 292 | 出价装配 (CPeaceBiddingTurn 构建) |

**总入口流程**: 清 W 容器 → 逐 loser (conf+272) sub_140E46A00 收候选 → sub_1419F2360 评估排序 → 预算 = *(sub_140E48090(conf, W+8) + 76) → 逐候选 sub_1419F3580 (vtable+216 查重 / 元素+24 分值 > 0 ∧ 可见性门 / vtable+160 算花费累计超预算即停 — **按分值降序逐个"买", 分数用完即停**) → 门 (W+60 ∨ sub_140E49AB0) ∧ **conf+216 ≤ 100** (conf+216 = 当前回合数 GetCurrentTurnNumber, 新读点; > 100 → :189 断言 "AI did 100 turns, this probably indicates a problem") → sub_1419F3770 出价装配。断言 :155 "Winner is invalid" / :160 "This should only run for AI controlled countries" (门 byte_14332EC69)。调用方 = sub_140E363C0 (tbb task 并行遍历 winners) + sub_140E4EBA0。

**评估主管线**: 种子对 = sub_1405339D0(gs+1120) + conf+216 + 国索引序 + 候选数 (sub_1405339D0 = *(gs+1128) − 43800000 = 游戏开始以来小时数, 43800000 = 1936-01-01 纪元基); v59[1] = 1587985055 − v59[0] 反码扰动。逐候选按行动 vtable+240 州相关谓词分派: 真 → sub_1419F3D00 (conf+552 竞价 map 记忆化查询 — AI 评估消费竞价 map, §4.10.37 互证); 假 → 12495 → 0x1419F2EA0 / 12496-12498 → 0x1419F2D50 / 其他 :278 断言 (latch byte_14338B51C); 12526 take_navy → 12B 键树查建 → sub_1419FB390 竞价 wrapper + sub_1419F1380 折算; 其他 :294 断言 (byte_14338B51D)。聚合树 (malloc 0x60 std::map; 键 = 12B {token 串比较, tag 索引序, region 值}) in-order 遍历, 节点均值 = Σ分值/count (溢出守卫 0xFFFFFFFF), ≤32 插入 / >32 归并排序输出。

**AI 索取州三档分级 (定案)**: 评分键 token = **core (10322, CState+176 数组 +188 计数命中) > claim (11310, CState+152 数组 +164 计数命中) > undefined (19479, 均未命中)**, 键 = {token, tag 索引序, 区域值 *(region+200)+88}; 三 define 开关旗 byte_143330F45 (任意) / byte_143330EEF (core) / byte_143330F44 (claim)。断言 :91 "!State.GetProvinces().IsEmpty()" / :93 "pRegion"; 0x1419F2D50 体内另有 :121 "pRegion" 空门 (闩 byte_14338B518, 第三闩; region 源 = *(*(a4+24)+200), 值 = *(region+88) 与本行区域值同址)。

**评分公式 (PE 侧验算定案)**: 折算核 sub_1419F1380 — cost = GetCost(action) (sub_1419F7600 §4.10.37 州流主体同函数直证 → **AI 出价同样被 CONTESTED_BID 竞价溢价抑制**); base = Σ cost_multiplier (sub_140A842B0 收 CPeaceActionModifier, 元素 +104 = cost_multiplier (19001)); **score = (10^12 / cost) × (base + 100) / 100** — 分值 ∝ 代价倒数, 修正因子 = (Σcost_multiplier + 100)/100 (基座 100 = 1.0 加法); score > 0 才入树节点值容器。⚠ 量纲疑点 (未决): §4.10.30 记 cost_multiplier 默认 100000 (fixed 1e5) 与此处百分数域 (100 = 1.0) 消费冲突, 需运行时探针定裁。魔数 0x29F16B11C6D1E109 在此仅作溢出守卫取高位符号位, 非参与运算。

**出价装配 (0x1419F3770)**: 复制选定行动 → sub_1419F4490 建 CPeaceBiddingTurn 写 W+16 (scoped ptr) → 断言 :434 "ClonedPeaceActions.GetSize() == SelectedPeaceActions.GetSize()" (byte_14338B51E) + 逐对 vtable+208 Equals (:439 "Should be clones", byte_14338B51F) → 逐克隆 **+56 = W+8 (negotiator)** / **+48 = 元素+8 (taker)** 写点直证 (§4.10.28/§4.10.30 互证) → 尾 sub_14151FD50: 行动 vtable+160 算 cost → **+64 = 竞标分值写点直证**。


**idea_formatter.cpp 理念名格式化器 2×2 矩阵 (四函定案)**: {守卫版 0x140531FC0 (值参) / 0x140532270 (对象+8 参), 直通版 0x1405328E0 / 0x1405329F0} × {worker A sub_140FCF820 (:23) / worker B sub_140FD2240 (:57)}。守卫 = 装箱变体 RTTI 甄别 (formatted_localization.h:96 "Formatter called with invalid localization context" 一次性断言), 失败落 "NULL"; idea 门 = CIdea+56 有效性旗 (书定案互证), 查询失败 ("Idea token <名> is not associated with any idea") 落空串; idea 查询 = sub_140A427B0(sub_14022FA90(), token) (CIdeaDatabase, 库单例 qword_14332EF30 邻域)。

#### 4.10.38h COfferJoinFactionAction AI 接受度因子装配 (1 函 = 0x141608CB0 = slot[65], 定案)

0x141608CB0 (action\* a1, 因子条目出表 a2, 带文案 a3): 计算「被邀国是否接受加入邀请方阵营」因子清单, 尾 `return vtable[35](a1, a2)` (基实现 0x1410FFB40 关系累加求和); 首调基座 sub_14110DC10 (DR_AI_CHEAT/DR_AI_UNABLE_TO_ACCEPT/DR_BASE_RELUCTANCE)。条目原语 = sub_140AB0AD0 构造 {string 32B, i32 score, u8 flag} + sub_140AB0930 入列; 文案三型 = sub_142245E60 无参 / sub_1402E3540 单参 (US/THEM) / sub_1402E3840 多参。actor = a1+20/+24 邀请方, recipient = a1+28/+32 被邀方 (接受度按 recipient 视角)。

**29 因子表** (loc 键 | 条件 | 分值 | define):

| 因子 | 条件 | 分值 | define |
|---|---|---|---|
| DR_STRATEGIC_ALLIANCE | a1+120 置位 | +10000 | — |
| DR_FACTION_UNSTABLE | 邀请方有阵营 ∧ sub_140D8CC70 | dword_143335604 | FACTION_UNSTABLE_ACCEPTANCE |
| DR_THEM_PUPPET / DR_US_PUPPET | sub_140D25830 对向判定 | +1000 / +20 | — |
| DR_US_HELPED_THEM_WITH_COUP | 被邀 country+4872 == 邀请方 tag (或同原初国) | dword_143337B30 | DIPLOMACY_FACTION_JOIN_COUP_INITIATOR_BONUS |
| DR_IDEOLOGICAL_ACCEPTANCE | `*(i64*)sub_14055E360(被邀+1464 矩阵, 邀请 po+1540)/1e5` ≠ 0; po 异 → −1000 (邀请方 sub_1406F8410+75 旗免; 被邀同旗未置再 −1000) | 计算值 | — |
| DR_STRATEGIC_HOSTILITY / _NOT_ALLIANCE / _ALLIANCE | 策略查询 id 1 / 6 (country vt[9]→+552→+104 vt[4](id, tag, 0)) | −值 / 原值 | — |
| DR_MAJOR | 被邀 +5210 置; po+1570 未置 → −30, po+1568 置 → −50 | −30/−50 | — |
| DR_KICKED_FROM_FACTION | 关系条目 +8 被踢日期 ≠ 哨兵 43808760; BASE−DECAY×周数 > 0 | −罚值 | BASE/DECAY_RATE_OF_NEGATIVE_OPINION_AFTER_BEING_KICKED (3331AB0/3331B60) |
| (组) DR_STRATEGIC_CONTAIN | 任一侧为阵营领袖 (faction+88→+8 tag) | — | sub_141600820 (尾参 10) |
| DR_FACTION_POWER_PROJECTION | `clamp(VALUE×(faction+2072−TRESHOLD)/1e5, MIN, MAX)`; 前置 sub_141600F40 (语义未开) | 计算值 | AI_FACTION_POWER_PROJECTION_VALUE/TRESHOLD(原文拼错)/AI_MIN/MAX_POWER_PROJECTION_SCORE (3333278/33331D0/3333318/33333E8) |
| DR_FACTION_TENSION | 双方同 po; `100×张力 sub_1401DBE50 × 系数/1e5` > 0 | 计算值 | DIPLOMACY_FACTION_GLOBAL_TENSION_FACTOR (3333E98) |
| DR_FACTION_SURRENDER | sub_1406DA100 × 系数/1e5 > 0 | 计算值 | DIPLOMACY_FACTION_SURRENDER_LEVEL (33357C0) |
| DR_FACTION_NEUTRALITY | 中立块 (门: 同 po ∧ po+1571 / 异 po 互斥) | −(PENALTY + min(100, 中立值就近量化)) | DIPLOMACY_FACTION_NEUTRALITY_PENALTY (3333DF8) |
| DR_STRATEGIC_NEUTRALITY_THREAT | 策略 id 13 > 0 ∧ !sub_140D24990 | +min(100, 值) | — |
| DR_FACTION_WRONG_IDEOLOGY | 异 po ∧ !被邀 po+1571 | −(PENALTY + 量化(中立包, 上限 200000)) | DIPLOMACY_FACTION_WRONG_IDEOLOGY_PENALTY (3333CA8) |
| DR_FACTION_CIVIL_WAR_RELUCTANCE | 被邀战中∧被邀内战 −50 / 被邀和平∧邀请战中∧邀请内战 −(SCARED_MINOR 75) | −50 / −75 | DIPLOMACY_SCARED_MINOR_EXTRA_RELUCTANCE (3334078) |
| DR_FACTION_SAME_WAR | 双方战中 ∧ 同战列表 ∧ 非直接互战 | +100 | — |
| DR_FACTION_BOTH_LOSING_WAR | 双方败战区间 sub_140D36020 均非空 | dword_143331170 | JOIN_FACTION_BOTH_LOSING |
| DR_AT_WAR_WITH_ALLY_RELUCTANCE | 战 id 数组 (dip+176/+188) ∩ 邀请方 war 列表 (dip+152/+164) 非空 (sub_140308980) | dword_143337A88 | DIPLOMACY_AT_WAR_WITH_ALLY_RELUCTANCE |
| DR_FACTION_NEITHER_AT_WAR | 双方和平 | −30 | — |
| DR_FACTION_WAR_RELUCTANCE_WAR | 被邀和平 ∧ 邀请战中 ∧ 非内战 | v228 + dword_143333F30 | DIPLOMACY_FACTION_WAR_RELUCTANCE (3333F30) |
| DR_ATTITUDE (组) | 态度对象 vt[10]/[11] → 跳过, vt[12] → +20; 逐第三国分值族 = +10 (vt[10] 中断) / +10 (vt[11]) / −50 (vt[12]) / −20 (vt[14]) | ±20 | — |
| DR_MODIFIER (组) | sub_14110A180(被邀+1448, **317**, …) 意见修正 | 逐修正 | — |
| DR_PREFER_OTHER_FACTION | 被邀无阵营 ∧ !a1+128: 扫 gs+1016 阵营管理器 mgr+32/+44, 栈构 CJoinFactionAction (120B, token 12243) 评估 vtable[64] 分 (= 0x14160CB10; 0x14160D180 属 COfferJoinFactionAction[64], PE 双 vtable 直证), po 异减半 / 领袖关系 +656/+664 非零倍增, 取最大 ≠ 邀请方阵营才发 | dword_143335868 | DIPLO_PREFER_OTHER_FACTION |
| DR_DISTANCE_BETWEEN_CAPITALS | sub_141600C90 装配器 | 计算值 | — |

**对象偏移组 (消费形态定案)**: country **+3984** = 外交/政治包装指针 (sub_1406CF890 直读; 链 +3984→+208→+24 = 意识形态对象) / **+1464** = 意识形态接受度矩阵 (按对方 po+1540 索引, 1e-5 定点) / +5210 major 旗 / **+4872** = 政变协助国 tag; 意识形态旗 +1540 id / +1568 (DR_MAJOR −50) / +1570 (DR_MAJOR −30 与 SCARED_MINOR 资格) / +1571 (中立块); dip +32/+44 在战关系向量 (元素+8 == token 14346, sub_140D3FD60) / +152/+164 tag|war 列表 / +176/+188 tag 数组 (sub_1401B0250 按 tag + 原初归一查) / +656/+664 关系条目旗; faction +88 领袖载体→+8 tag / **+2072** 实力投影 raw; gs+1016 阵营管理器。哨兵 43808760 (CGameDate ctor) 再添被踢日期消费例。

#### 4.10.38i 派遣志愿军威胁发射执行器 (1 函 = 0x1411095F0, 结构定案)

0x1411095F0: 「派遣志愿军」威胁条目装配 (SEND_VOLUNTEER_THREAT 本地化键全语料唯一)。kind == 2 门 → CID 收集 (`!=16` 空外层判 + 双字段过滤 + vtable[7]) → 威胁值 = `sub_140F039B0(A, B) × qword_1433357F8 × count / 1e5` — 与 §4.10:1227 参战威胁管线同型但**因子异** (1433357F8 ≠ 1433365C8, define 名未决) → {COUNT, TARGET} 两参发射 sub_1401CBC90。

#### 4.10.38j 战争关系和谈提案发起校验 (1 函 = 0x141135010, 高置信)

0x141135010: 和谈提案发起前置校验, 四键 = **DIPLOMACY_PEACE_PROPOSAL_MUST_BE_LOSING** / **DURATION_TO_SHORT** (最短持续 = dword_1433368C8) / **YOU_NOT_WAR_LEADER** / **THEY_NOT_WAR_LEADER**。链 = cc+3976 CDiplomacyStatus → dip+8 active_relations → 条目 +744 **_pWarRelation** (书内既有); war relation +73 旗 / +32 字段消费。

#### 4.10.38k 战争参与国列表构建器 (A = 0x141985AF0 / B = 0x141985F60 / 包装 0x1419863F0 与 0x1419867A0, 定案)

0x141985AF0 (构建器 A 三相): ① 候选收集 (14346 war 滤 + **+73 抑制门**, t100 互证) → ② 互战对去重 (保留 sub_140D3F440 关联方) → ③ 降序 swap-remove。B = 配对变体。

#### 4.10.38l CJoinFactionAction AI 接受度因子装配 (1 函 = 0x1416061A0 = slot[65], 定案)

身份表:

| 项 | 值 |
|---|---|
| 真名 | NFactions::CJoinFactionAction vtable[65] (PE 直读 0x1429E2958+520; 同表 [56]=0x141602F80 / [64]=0x14160CB10 / [35]=0x1410FFB40) |
| 语义 | join_faction 的 AI 接受度因子装配器 (阵营领袖视角); 19 个 in-body DR_ loc 因子 + 4 委托组, 尾转 vtable[35] = 0x1410FFB40 基类关系累加器 (join/offer 双族一致) |
| 断言 | faction_diplomatic_actions.cpp:1925 "Recipient's faction should be set or we could not ask to join their faction" (recipient dip+656 必须有阵营; ask to join = join 非 offer) |
| 签名 | (CJoinFactionAction* a1, 因子条目出表 a2, 带文案旗 a3); 因子条目原语 sub_140AB0AD0 = {string 32B, i32 score, u8 flag}; 前置首调 sub_14110DC10 = 基座三因子 (§4.10.13 [65] 行) |

四国句柄 (CDiplomaticAction 基类, §4.10.13):

| 基类偏移 | 键 | 语义 |
|---|---|---|
| +20 | 0x292E | actor = 申请加入国 (joiner) |
| +24 | 0x2FCF | original_actor (战争态/人控判据) |
| +28 | 0x292F | recipient = 阵营领袖国 (**评估视角 = 本侧**) |
| +32 | 0x2FD0 | original_recipient (意识形态中立块/战争态) |

join vs offer 因子集差异 (对 §4.10.38h 的 29 因子):

| 类 | 因子 |
|---|---|
| join 独有 (3) | DR_TOO_MUCH_THREAT (sub_14160E250(recipient, actor) > 0 → 固定 −1000) / DR_PLAYER_ASKING_FACTION (正向; 判据 = !sub_1406FFDB0(orig_actor) = 真人控 ∧ 未 human_ai) / DR_COMMUNIST_NOT_NEIGHBOUR (负向; po(orig_recipient)+1569 旗 ∧ 阵营无成员邻接 joiner) |
| join 缺 (10) | DR_STRATEGIC_ALLIANCE / DR_FACTION_UNSTABLE / DR_US_HELPED_THEM_WITH_COUP / DR_US_PUPPET / DR_MAJOR / DR_KICKED_FROM_FACTION / DR_FACTION_SURRENDER / DR_FACTION_CIVIL_WAR_RELUCTANCE / DR_FACTION_NEITHER_AT_WAR / DR_PREFER_OTHER_FACTION |
| 共用 define 异键 | DR_WAR_REASON (join 独有 loc 键, 值用 DIPLOMACY_FACTION_WAR_RELUCTANCE); join 的 DR_FACTION_WAR_RELUCTANCE_WAR 改**固定 −200** 且触发条件异 (orig_recipient 与**邻接 major** 交战, 非 offer 的「被邀和平 ∧ 邀请战中」) |

19 in-body 因子表:

| 因子 | 判据 | 值 |
|---|---|---|
| DR_WAR_REASON | actor 在战 ∧ ¬(relation+784 共同参战) ∧ orig_actor 战列表与 orig_recipient 无交集 | dword_143333F30 (负) |
| DR_AT_WAR_WITH_ALLY_RELUCTANCE | dip(orig_actor)+176 战 id 与 dip(orig_recipient)+152 命中 | dword_143337A88 (负) |
| DR_THEM_PUPPET | relation+648 token 12497 (主体关系) | +1000 |
| DR_TOO_MUCH_THREAT | sub_14160E250(recipient, actor) > 0 | −1000 (字面量) |
| DR_IDEOLOGICAL_ACCEPTANCE | 接受度矩阵 (公式下) | 计算值 |
| DR_STRATEGIC_HOSTILITY | 策略链 vt[+32](1, idx(actor)) = hostility → −max(0, v) | ≠0 发 |
| DR_STRATEGIC_ALLIANCE / NOT_ALLIANCE | 策略链 vt[+32](6, idx(actor)) | >0 / <0 分发 |
| DR_FACTION_MATCHING_MAJOR | po 同 ∧ country(actor)+5210 major 旗 | dword_143333D38 (正) |
| DR_FACTION_TENSION | 世界张力 > 0 (公式下) | 计算值 (正) |
| DR_FACTION_NEUTRALITY | po(orig_recipient)+1571 中立旗 | −(dword_143333DF8 + min(100, 意见值)) |
| DR_STRATEGIC_NEUTRALITY_THREAT | 中立旗 ∧ 策略链 vt[+32](13, idx(orig_actor)) > 0 ∧ ¬关系谓词 | +min(100, 值) |
| DR_FACTION_WRONG_IDEOLOGY | 异 po ∧ ¬中立旗 | −(2×意见 + dword_143333CA8) |
| DR_PLAYER_ASKING_FACTION | 见上 | dword_143334108 (正) |
| DR_COMMUNIST_NOT_NEIGHBOUR | 见上 | dword_143332FD0 (负) |
| DR_ATTITUDE (双形) | 形一 = 单对态度对象 (vt+96 → +20 / vt+112 → +10); 形二 = 逐交战第三国 (+10/+10/−50/−20) | 分值族 |
| DR_FACTION_WAR_RELUCTANCE_WAR | 在战 ∧ po(orig_recipient)+1568 旗 ∧ 交战方邻接 recipient 且 major | −200 (字面量) |
| DR_FACTION_SAME_WAR | 同战列表 ∧ 非直接互战 | +100 (字面量) |
| DR_FACTION_BOTH_LOSING_WAR | ¬同战 ∧ 双侧战局分均 < 50000 | dword_143331170 (负) |

4 委托组:

| 委托 | VA | 调用形 |
|---|---|---|
| DR_STRATEGIC_CONTAIN 组 | sub_141600820 | (country(actor), country(recipient), a2, dip(actor)+152, dip(recipient)+152, a3, **1**) — 尾参 join 传 1 / offer 传 10 |
| DR_FACTION_POWER_PROJECTION 前置 | sub_141600F40 | (a2, recipient, actor, faction(recipient), a3) — 前置断言 :1925 |
| DR_MODIFIER 组 | sub_14110A180 | (country(recipient)+1448, **token 317**, 国名串, a2, a3) |
| DR_DISTANCE_BETWEEN_CAPITALS | sub_141600C90 | (country(actor), country(recipient), a2) |

关键公式:

| 因子 | 公式 |
|---|---|
| DR_IDEOLOGICAL_ACCEPTANCE | 基值 = 接受度矩阵[po(recipient)+1464, po(actor)+1540 id] / 1e5; 异 po → −1000; po(actor)+75 旗置 → 豁免第一罚; po(recipient)+75 旗未置 → 再 −1000 |
| DR_FACTION_TENSION | v = 100 × 世界张力 (gs+1712→+8); v > 0 → 量化(DIPLOMACY_FACTION_GLOBAL_TENSION_FACTOR × v / 1e5) — hi-mul 魔数 0x29F16B11C6D1E109 = ceil(2^78/100000) 实现 /1e5 (PE 侧验算), 与 §4.10.38h offer 同式同系数 |
| DR_WAR_REASON 门链 | ① actor 无在战关系 → 跳过; ② relation+784 共同参战 → 跳过; ③ orig_actor 无在战关系 → 直发; ④ 遍历 dip(orig_actor)+152/+164 与 dip(orig_recipient)+152 逐项匹配, 全不命中才发 |

新消费点 (书未收):

| 宿主 | 偏移 | 语义 |
|---|---|---|
| 意识形态对象 | +1569 | 旗 = DR_COMMUNIST_NOT_NEIGHBOUR 门 |
| country | +4220 | 邻居计数 (0 → country.h:1776 未初始化断言, 记忆旗 byte_14332FC62) |
| CFaction | +100 | 成员数 (≤0 支路 = COMMUNIST_NOT_NEIGHBOUR 阵营空时直接判罚) |
| CRelation | +784 | 共同参战旗 = DR_WAR_REASON 前置跳过门 (旗位书已收, 本链新增消费点) |

define 配对 (defines_map_1193 逐项核):

| 地址 | define 名 | 因子 | 方向 |
|---|---|---|---|
| 0x143333F30 | DIPLOMACY_FACTION_WAR_RELUCTANCE | DR_WAR_REASON | 负 |
| 0x143337A88 | DIPLOMACY_AT_WAR_WITH_ALLY_RELUCTANCE | DR_AT_WAR_WITH_ALLY_RELUCTANCE | 负 |
| 0x143333D38 | DIPLOMACY_FACTION_SAME_IDEOLOGY_MAJOR | DR_FACTION_MATCHING_MAJOR | 正 |
| 0x143333E98 | DIPLOMACY_FACTION_GLOBAL_TENSION_FACTOR | DR_FACTION_TENSION | 正 (qword 系数) |
| 0x143333DF8 | DIPLOMACY_FACTION_NEUTRALITY_PENALTY | DR_FACTION_NEUTRALITY | 负 |
| 0x143333CA8 | DIPLOMACY_FACTION_WRONG_IDEOLOGY_PENALTY | DR_FACTION_WRONG_IDEOLOGY | 负 |
| 0x143334108 | DIPLOMACY_FACTION_PLAYER_JOIN | DR_PLAYER_ASKING_FACTION | 正 |
| 0x143332FD0 | DIPLOMACY_COMMUNIST_NOT_NEIGHBOUR | DR_COMMUNIST_NOT_NEIGHBOUR | 负 |
| 0x143331170 | JOIN_FACTION_BOTH_LOSING | DR_FACTION_BOTH_LOSING_WAR | 负 |

> 待裁: sub_14160E250 参数方向 (本处 (recipient, actor) vs [64] 处 (actor, recipient)); po+1568/+1569 旗的意识形态归属; sub_141600820 尾参语义差 (join 1 / offer 10)。未决: define 槽 PE 静态读值与游戏值不符 (疑运行期 CDefines 解析 00_defines.lua 填入, 静态槽不持值)。

#### 4.10.38m 未交战相关国家 tag 收集器 (sub_141957200, 定案)

身份表:

| 项 | 值 |
|---|---|
| VA | 0x141957200 (语料 289 行体, 零断言串) |
| 签名 | (a1 出参向量头, a2 国家 tag 句柄); a1 实为 24B CPdxArray 头 {data@+0, cap@+8, count@+12, alloc@+16} (IDA _OWORD* 为宽度标记, 清零写 +0 与 +16 = data 与 alloc 槽); 返回 a1 |
| 语义 | 与 a2 国未处于有效交战的相关国家 tag 收集器: 取 dip 后三方扫描 (阵营成员 / 宗主 / 关系数组), 每候选查 rs+744 战争关系, 门 = 无关系 ∨ rs+73 置位 → 收集 tag, 排序后写入出参向量 |
| 源文件域 | 推定外交视图/地图模式域 (两调用者均在 0x140E15 带; 零断言串, 仅靠 VA 带推定) |

三方扫描 (门同形, 各含一份 1.5× 向量增长模板内联):

| 路 | 入口 | 遍历 | 收集条件 |
|---|---|---|---|
| 阵营成员 | dip+656 非空 → 阵营+88 数组 (界 +100, 步长 8B, 条目+8 = 成员 tag; 条目+8==0 时 idx 取 0) | 全成员 | 同门 |
| 宗主 | dip+392 (tag > 0) | 单值 | 同门 |
| 关系数组 | dip+368 data (界 dip+380), 元素 = 关系 tag (==0 时 idx 取 0) | 全关系 | 同门 |

候选 → rs 解析: idx = sub_140BB5490(tag), rs = *(dip+8)[idx], war = rs+744; 门 = (war 为空) ∨ *(u8*)(war+73) 为真。

偏移消费表:

| 对象 | 偏移 | 语义 | 书位 |
|---|---|---|---|
| cc | +3976 | CDiplomacyStatus* 挂载点 (sub_140BB48F0(a2) 返回) | §4.10.1 直证 |
| dip | +8 | CRelationStatus* 数组 (idx = 对方国 idx) | §4.10.1 直证 |
| dip | +368 / +380 | 关系 tag 数组 data / 计数 | §4.10.25a 直证 |
| dip | +392 | 宗主 tag | §4.10.1 直证 |
| dip | +656 | CFaction* (空 → 跳过阵营成员路) | §4.10.1 直证 |
| 阵营 | +88 / +100 | 成员数组 data / 成员计数 | §4.5 直证 |
| rs | +73 | 战争有效旗 (置位 = 无效/已结束 → 本函收集条件之一) | §4.10.1 (门方向本函直证) |
| rs | +744 | _pWarRelation (空 = 无战争关系 → 收集) | §4.10.1 直证 |

> rs+73 门方向: 本函收集「未交战」者 = 无 war ∨ +73 置位; 与 §4.10.38k 构建器 A 的「+73 抑制门」及 §4.10.38l 的交战判据 (有 war ∧ +73 未置位) 互补 — 两向共同钉死 +73 置位 = 战争无效/已结束。

排序与落盘 (Src = 16B 栈向量 {data@+0, cap@+8, count@+12}, 4B/元, 分配器 off_143085170):

| 件 | 语义 |
|---|---|
| sub_14012B520(vec, tag) | 排序/去重前置 (操作 vec+0/+12/+16, memcpy 重建 count); 推定 |
| sub_140EB6080(vec, tag) | 排序/去重后置; 推定 |
| sub_1401B6990(Src, n) | 小数组排序 (n ≤ 32 路); 推定 |
| sub_1401B6CF0(a, n, size, buf, bufcap, 0) | 归并排序核 (n > 32 路; 辅助缓冲 > 1024 元上堆否则栈 16B, 半数大小递减 malloc 重试); 推定 |
| sub_140157780(dst, src) | 向量赋值, 结果落出参 a1; 推定 |

调用与姐妹件:

| 件 | 调用形 | 语义 |
|---|---|---|
| sub_140E15A40 | case 8: 分支 (配 unk_143334850 与 sub_140305890) | 调用者 A; a3 枚举语义待裁 |
| sub_140E157F0 | if (a3 == 8) 分支, 结果经 sub_140157780 转赋 | 调用者 B; a3 == 12 的姐妹件 = sub_141955EB0 (体未读) |

> 待裁: 两调用者的 a3 枚举语义 (8/12 两档 = 哪两种外交视图/地图模式); 姐妹件 sub_141955EB0 本体; 排序族四件的算法细节; unk_143334850 是否 define 槽。

#### 4.10.38n CCreateFactionAction AI 接受度因子装配 (1 函 = 0x1416040B0 = slot[65], 类归属高置信 / 因子链定案)

0x1416040B0 (CCreateFactionAction* a1, 因子条目出表 a2, 带文案旗 a3): 计算「被邀国是否接受共建新阵营」因子清单, 尾 `return vtable[35](a1, a2)` (基实现 0x1410FFB40 关系累加求和); 首调基座 sub_14110DC10 (DR_AI_CHEAT / DR_AI_UNABLE_TO_ACCEPT / DR_BASE_RELUCTANCE, §4.10.13 [65] 行)。**类归属 = 高置信** (PE vtable 第三方记录 0x1429E2738+520 + 语料内 ctor 0x1415FFFA0 / Apply 0x1416027C0 / clone 152B 同簇佐证; dump 无 vtable 数据段, 语料内无 [65] 槽位直证); **因子链 = 定案** (体直证 + 与 §4.10.38h/§4.10.38l 逐项对上)。Apply 0x1416027C0: type==2 (ACCEPT) ∧ 被邀国无阵营 (dip(recipient)+656 == 0) ∧ 有 OwnedStates (cc(recipient)+1156 > 0) → CreateFaction sub_140D91E00(facsys, a1+24 原初发起国 tag, a1+120 阵营名) → sub_14118BA30(被邀国, faction, 1) 加入 → 发 on_faction_formed + X_JOINS_FACTION_THREAT。

四国句柄同 §4.10.38l (+20 actor / +24 original_actor / +28 recipient / +32 original_recipient); 全函只读四 tag, **从不读 a1+120** (与族表 +120 = 阵营名串相容; join/offer 的 +120 是 u8 旗, 其 [65] 会消费)。

**20 步因子表** (步序 = 体序):

| 因子 | 条件 | 分值 |

|---|---|---|

| (基座) DR_AI_CHEAT / DR_AI_UNABLE_TO_ACCEPT / DR_BASE_RELUCTANCE | 无条件 (sub_14110DC10) | 基座定义 |

| DR_THEM_PUPPET | sub_140D25830(relation(orig_recipient → orig_actor)) 傀儡关系 | +1000 |

| DR_US_PUPPET | sub_140D25830(relation(orig_actor → orig_recipient)) 傀儡关系 | **−100** (offer = +20, 字面量 0xFFFFFF9C) |

| DR_US_HELPED_THEM_WITH_COUP | country(orig_recipient)+4872 == orig_actor tag (∨ 双非空 ∧ 同原初国 sub_140BB52F0) | dword_143337B30 |

| DR_IDEOLOGICAL_ACCEPTANCE | 见公式; 值 ≠ 0 才发 | 计算值 |

| DR_STRATEGIC_HOSTILITY | 策略查询 id 1 (recipient 侧) −max(0, v) ≠ 0 | −max(0, q(1)) |

| DR_STRATEGIC_ALLIANCE / DR_STRATEGIC_NOT_ALLIANCE | 策略查询 id 6 ≠ 0 | q(6) 原值 (>0 / ≤0 分发) |

| (组) DR_STRATEGIC_CONTAIN 族 | actor ∨ recipient 为本阵营领袖 (dip+656→faction+88→+8 tag 等于本国 tag ∨ 同原初国) | sub_141600820(actor 国, recipient 国, a2, dip(actor)+152, dip(recipient)+152, a3, **1**) |

| (组) DR_OPINION | opinion(recipient → actor) / 10 ≠ 0 (sub_1406F4490 读 rs+768 cached_sum) | opinion / 10 |

| (组) DR_OPINION_DIPLOMATIC_PRESSURE | 同组, 无领袖短路 (本函直调 sub_141600FC0 传 a4=0) | 压力值 >> 15 (sub_1424ED3F0) |

| DR_FACTION_TENSION | po(orig_actor) == po(orig_recipient) ∧ 紧张度 × 100 > 0 | 量化(qword_143333E98 × 100 × 紧张度 / 1e5), **向零取整** |

| DR_FACTION_WRONG_IDEOLOGY | po 异 ∧ ¬中立旗 | −(量化(2 × 紧张度包) + dword_143333CA8) |

| DR_FACTION_NEUTRALITY | 立中立旗 po(orig_recipient)+1571 (同 po / 异 po 皆可) | −(dword_143333DF8 + min(100, 量化(紧张度包))) |

| DR_STRATEGIC_NEUTRALITY_THREAT | 步 13 落点 ∧ 策略查询 id 13 (orig_recipient 对 orig_actor) > 0 ∧ ¬休战 sub_140D24990 | +min(100, q(13)) |

| DR_ATTITUDE (单对) | relation(orig_recipient → orig_actor): ¬vt[10] ∧ ¬vt[11] ∧ vt[12] (WantsAlly) | **+20** |

| DR_ATTITUDE (逐敌循环) | 遍历 dip(orig_actor)+152/+164 交战国, 取 relation(orig_recipient → 第三国) 态度 | vt[10] **+20 并中断扫描** / vt[11] +20 / vt[12] −50 / vt[14] −10 |

| DR_FACTION_NEITHER_AT_WAR | 双方均和平 (sub_140D3FD60) | −30 |

| DR_FACTION_SAME_WAR | 双方在战 ∧ dip(recipient)+176 同战数组命中 ∧ ¬直接互战 (sub_140700570) | +100 |

| DR_FACTION_BOTH_LOSING_WAR | 双方在战 ∧ 非同战 ∧ 战局分 sub_140D36020 双侧均 < 50000 | dword_143331170 (负) |

步 12/13 分支: po 同 ∧ ¬中立 → 两因子皆跳; po 同 ∧ 立中立 → 仅 13; po 异 ∧ ¬中立 → 仅 12; po 异 ∧ 立中立 → 仅 13。步 14 只从 13 的落点进入。

**关键公式** (量化与取数链):

| 因子 | 公式 |

|---|---|

| DR_IDEOLOGICAL_ACCEPTANCE | 基值 = sub_14055E360(cc(recipient)+1464 矩阵, po(orig_actor)+1540 id) / 1e5; po(cur actor) ≠ po(cur recipient) → −1000; cc+1640+75 旗 (sub_1406F8410(actor)) 置 → 豁免第一罚; recipient 同旗未置 → 再 −1000; 非 0 才发 |

| DR_FACTION_TENSION | v = 100 × 世界紧张度 (sub_1401DBE50); v > 0 → hi-mul 魔数 0x29F16B11C6D1E109 (ceil(2^78/1e5), 总移位 78) 后 `v112 = v111 + (v111>>63)`, 余数非 0 则截断 = **向零取整** (正支截断丢弃 sub-1e5 余数, 负支进位; 与 sub_1424ED730 的就近量化不同); 同式同系数见 §4.10.38h/§4.10.38l |

| 紧张度包 (步 12/13) | sub_1401DB350(gs, out, &cc(orig_recipient)+8) = **原初被邀国已添加的世界紧张度** (gs+1712 CWorldThreat → +40 数组按 tag 下标 qword, 钳 0..10000000; §4.32 has_added_tension_amount 同入口) |

| 策略链 (步 6/7/14) | cc(recipient) → vt[+72] (slot 9, 推定 identity getter 返 country 本身) → sub_1406CF0E0(*(+552) = CCountryAI*) → +104 对象 vtable slot[4] (+32) → fn(obj+104, id, idx(对侧 tag), 0); ids = 1 敌意 / 6 结盟 / 13 中立威胁; 步 14 链与 idx 均用原初双侧 |

**三变体定位** (对 §4.10.38h offer / §4.10.38l join): 共用 THEM_PUPPET(+1000) / US_HELPED_THEM_WITH_COUP / IDEOLOGICAL_ACCEPTANCE / STRATEGIC 族 / CONTAIN 组 (尾参 1 = join 同) / FACTION_TENSION / WRONG_IDEOLOGY / NEUTRALITY / NEUTRALITY_THREAT / ATTITUDE 双形 / SAME_WAR / BOTH_LOSING / NEITHER_AT_WAR; **本族差异**: DR_US_PUPPET = −100 (offer +20) / 无 DR_STRATEGIC_ALLIANCE +10000 门 / 无 DR_PREFER_OTHER_FACTION / 无 offer 专属 UNSTABLE / MAJOR / KICKED / SURRENDER / CIVIL_WAR / AT_WAR_WITH_ALLY / WAR_RELUCTANCE_WAR / MODIFIER / DISTANCE_BETWEEN_CAPITALS / POWER_PROJECTION; **新增 DR_OPINION 组** (经 sub_141600FC0, join 侧经 wrapper sub_141600F40 发射)。

**US/THEM loc 标签方向 (逐键非统一, 体直证)**: 傀儡/政变类 (DR_THEM_PUPPET / DR_US_PUPPET / DR_US_HELPED_THEM_WITH_COUP) US = 发起国、THEM = 被邀国; 立场类 (DR_OPINION / 压力 / DR_STRATEGIC_HOSTILITY / _ALLIANCE / _NOT_ALLIANCE / DR_IDEOLOGICAL_ACCEPTANCE / DR_STRATEGIC_NEUTRALITY_THREAT) US = 被邀国 (评估视角)、THEM = 发起国; DR_ATTITUDE US = 被邀国形容词 (cc+48), THEM = 态度目标国 (单形 = 发起国 definite 名 cc+80; 循环形 = 第三国名)。

**新档函数**: sub_141600FC0 = DR_OPINION + DR_OPINION_DIPLOMATIC_PRESSURE 组本体 (opinion/10 ≠ 0 发 DR_OPINION; a4==0 时再发压力 >>15) / sub_141600F40 = 其 wrapper (领袖短路门, §4.10.38l 委托组) / sub_140D22030 = rs+792 CAIAttitude* getter / 外交压力链三件 (sub_1406F98C0 = gs+212 管理器宿主 sub_140EB2E80(mgr, &cc+8); sub_1411F6210 / sub_1411F6240 = 压力计算两形; sub_1424ED3F0 = fixed→整型)。

未决 6 项: ① 类归属语料内直证 (需 PE 侧 0x1429E2738+520 复读或运行时 vtable dump 升定案); ② 外交压力链层级语义与 >>15 量纲未逐层展开 (推定 = 国别意见修正 + fixed→整型); ③ CCountry vt[+72] (slot 9) 真身 (推定 identity getter, 未排除等布局包装对象); ④ sub_141600820 (CONTAIN 组) 内部因子未展开 (§4.10.38l 亦未展开); ⑤ 态度循环 vt[10] 命中即 break 的跨族差异是否有意设计 (join 同 break 形但分值异 +10/+10/−50/−20); ⑥ 步 4 门用原初双侧 / 文案用当前双侧 (跨族同形, 语义 = 原初关系判定 + 当前名显示, 未运行时验证)。

#### 4.10.39 政治外交域函数补遗（25 函）

| VA | 语义/证据 |
|---|---|
| 0x1406C1AE0 | （未命名）NATIONAL_FOCUS_NO_CURRENT_EFFECT NATIONAL_FOCUS_NO_CURRENT_EFFECT，国家焦点当前效果 |
| 0x1403F01A0 | CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>::[21] CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>::[21] + TRIGGER_HAS_(NOT_)AVAILABLE_IDEA_WITH_TRAITS … |
| 0x141C178E0 | NFactions::NUi::CGoalItem::[0] NFactions::NUi::CGoalItem::[0] + CATEGORY / FACTION_ADD_GOAL / FACTION_GOAL / FACTION_GOAL_ITEM_TOOLTIP（阵营目标项） |
| 0x1401474B0 | sub_1401474B0 NFactions::CFactionGoal 构造（正文 vtable+CProgress 子对象） |
| 0x140344A00 | CAddRemoveDynamicModifierEffect<$0A>::[13] CAddRemoveDynamicModifierEffect<$0A>::[13] + "modifier does not exist" / "invalid scope"（动态修正增删 effect） |
| 0x141191720 | Reader ideology.cpp:84；"no random ideology available for group %s"，意识形态反序列化 |
| 0x140724250 | sub_140724250 CDecision 三 vtable 析构：清 a1+3344/3360 等多个成员 string（CDecision 生命周期） |
| 0x14160EAE0 | NFactions::CJoinFactionAction::[17] NFactions::CJoinFactionAction::[17] + COUNTRY / DIPLOMACY_MESSAGE_OTHERS_TITLE / FACTION（加入阵营动作） |
| 0x1413A3830 | sub_1413A3830 ideology_support_trigger + "Usage: <Ideology> < <float>"（意识形态支持度触发器） |
| 0x1411F9540 | （未命名）调用链含 vtable `CModifier` + MODIFIER_IDEOLOGY_DRIFT_FROM_BOOST_IDEOLOGY_OPERATIVE_MISSION 调用链含 vtable `CModifier` + MODIFIER_IDEOLOGY_DRIFT_FROM_BOOST_IDE… |
| 0x141BA6EB0 | （未命名）NFactions::CCreateFactionTheater 构造 NFactions::CCreateFactionTheater 构造（vftable 赋值 + a1+48 串构造） |
| 0x140D8CD90 | sub_140D8CD90 faction.cpp:1190（on_become_faction_member 派系成员事件） |
| 0x140E33B00 | sub_140E33B00 和平会议（peaceconference.cpp:2787，Conference.HasWinner/ConflictingClaim 谈判定案） |
| 0x1411862F0 | sub_1411862F0 派系创建外交规则（DIPLOMACY_FACTION_UNAVAILABLE_US_PUPPET/DIPLOMACY_CREATE_FACTION_NOT_RULE） |
| 0x140C17B80 | （无名） modifier.h 修正器（断言站点 modifier.h:1191） |
| 0x14204A5B0 | （未命名）gamestate.h:1125 门控 + loc 串 REPLY_YES/RE gamestate.h:1125 门控 + loc 串 REPLY_YES/REPLY_NO（外交请求应答） |
| 0x14118D4C0 | （未命名）串 "Invalid faction upgrade" 串 "Invalid faction upgrade"（派系升级校验） |
| 0x1413F3140 | CReducedFocusCost::[2] CReducedFocusCost::[2]，pdx_robin_hood_table.h:58（国策成本降低容器） |
| 0x141C4F030 | （无名） vftable 类 CIdeaFolder::（政治/外交） |
| 0x141C61FE0 | （未命名）GUI 串 "autonomy_country_name"/"autonomy_ GUI 串 "autonomy_country_name"/"autonomy_country_flag"（自治附庸名/旗） |
| 0x14118A2B0 | （未命名）loc 串 FACTION_LEADER_BONUS_INFLUENCE/CON loc 串 FACTION_LEADER_BONUS_INFLUENCE/CONTRIBUTION_INFLUENCE/INDUSTRIAL_CAPACITY_INFLUENCE/WAR_SCORE_INFLUENCE（派… |
| 0x1414E80C0 | CDiplomaticMessage::[1] CDiplomaticMessage::[1]，串 "DECLINE_"/"START_"/"STOP_"（外交消息模板） |
| 0x1406C2960 | （未命名）loc 串 CONTINUOUS_FOCUS_LOCKED_DESC/CONTI loc 串 CONTINUOUS_FOCUS_LOCKED_DESC/CONTINUOUS_FOCUS_UNLOCKED_DESC/LEFT（连续国策锁定） |
| 0x141132AB0 | CGiveStateControlAction::CanExecute CGiveStateControlAction::CanExecute，串 DIPLOMACY_GIVESTATECONTROL_NOT_SAME_FACTION/_NOT_SAME_WAR（移交州控制权） |
| 0x141ADB010 | （无名） vftable 类 NFactions::NUi::CFactionCountryListWindow::（政治/外交） |

#### 4.10.40 政治外交域函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x1413F1230 | （无名）character_template.cpp:299 + is not a valid ideology. + tries to cumulate 2 times the same ideology character_template.cpp:299 + is not a valid ideology.… |
| 0x141C48750 | （无名，按上游/loc 定性） loc "name\ leading_pol_party_bg" |
| 0x1411A47D0 | （无名）POLITICS_ELECTION_FREQUENCY + MONTHS 键 POLITICS_ELECTION_FREQUENCY + MONTHS 键 |
| 0x1410DD970 | （无名，按上游/loc 定性） civilwar.cpp:247 断言 |
| 0x141585C20 | （无名，按上游/loc 定性） loc "continuous_small_glow\ pol_power_icon\ drop_continuo*" |
| 0x140A481D0 | vtable/RTTI 类 CIdeologyGroup sub_140A481D0 + vtable/RTTI 类 CIdeologyGroup |
| 0x140E550F0 | vtable/RTTI 类 CPowerBalanceSystem sub_140E550F0 + vtable/RTTI 类 CPowerBalanceSystem; 被调源码 hoi4 |

#### 4.10.41 政治外交域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x140ADC7D0 | sub_140ADC7D0（无名） gamestate.h:1125 + "ThreadIsMainThread()" ingameinterfacehandler.h 断言，紧邻 CTimedWargoalActivity::Reader/CBaseTimedActivity::Writer，定时战争目标活动 … |

#### 4.10.42 政治外交域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141F15440 | （无名，按证据定性） 键 FACTION_CHANGE_RULE_ITEM_COST + VALUE（阵营规则代价） |
| 0x140E33560 | 和会冲突声明裁决 peaceconference.cpp:2787 + "Conference.HasWinner( ConflictingClaim._Action->GetNegotiator() )" 断言 |
| 0x140E32980 | 和会竞标回合 "BiddingTurns.GetSize() > TurnNumber - 1"，peaceconference.cpp:1802 |
| 0x140D34290 | CDiplomacyStatus::[0] vtable 槽 CDiplomacyStatus::[0]（func_names RTTI 名） |

#### 4.10.43 政治外交域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|

#### 4.10.44 政治外交域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x140D33640 | （无名） 体设 CDiplomacyStatus::vftable（RTTI 名） |

#### 4.10.45 政治外交域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|

#### 4.10.46 政治外交域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x1413B5C90 | 市场准入权外交动作 vtable=NInternationalMarket::CRequestMarketAccessRightsAction + diplomaticaction.h 断言 |

#### 4.10.47 政治外交域函数补遗（319 函）

| VA | 语义/证据 |
|---|---|
| 0x14024ADC0 | （无名） 调用图传播: 82 锚点投 §4.10（51%） |
| 0x140E3E700 | （无名） 调用图传播: 82 锚点投 §4.10（51%） |
| 0x141AE0280 | （无名） 调用图传播: 94 锚点投 §4.10（59%） |
| 0x141AEFE20 | （无名） 调用图传播: 76 锚点投 §4.10（54%） |
| 0x141988080 | （无名） 调用图传播: 89 锚点投 §4.10（53%） |
| 0x14158B3C0 | （无名） 调用图传播: 40 锚点投 §4.10（50%） |
| 0x140076440 | （无名） 调用图传播: 71 锚点投 §4.10（59%） |
| 0x141544F90 | （无名） 调用图传播: 48 锚点投 §4.10（54%） |
| 0x140529D70 | GetDesc 调用图传播: 51 锚点投 §4.10（53%） |
| 0x1417F7390 | （无名） 调用图传播: 62 锚点投 §4.10（50%） |
| 0x141B550B0 | （无名） 调用图传播: 40 锚点投 §4.10（55%） |
| 0x141B65C20 | （无名） 调用图传播: 36 锚点投 §4.10（58%） |
| 0x14130A740 | （无名） 调用图传播: 86 锚点投 §4.10（55%） |
| 0x141B19630 | （无名） 调用图传播: 60 锚点投 §4.10（58%） |
| 0x141B4A950 | （无名） 调用图传播: 60 锚点投 §4.10（53%） |
| 0x140F1BB10 | （无名） 调用图传播: 54 锚点投 §4.10（50%） |
| 0x141AE7380 | （无名） 调用图传播: 24 锚点投 §4.10（50%） |
| 0x140290EC0 | （无名） 调用图传播: 40 锚点投 §4.10（52%） |
| 0x140EDA380 | （无名） 调用图传播: 48 锚点投 §4.10（50%） |
| 0x140BC0DD0 | （无名） 调用图传播: 67 锚点投 §4.10（52%） |
| 0x140536A10 | （无名） 调用图传播: 98 锚点投 §4.10（51%） |
| 0x140B49A40 | （无名） 调用图传播: 72 锚点投 §4.10（60%） |
| 0x1413BD100 | （无名） 调用图传播: 33 锚点投 §4.10（52%） |
| 0x141AE7D60 | （无名） 调用图传播: 22 锚点投 §4.10（50%） |
| 0x1419420E0 | （无名） 调用图传播: 41 锚点投 §4.10（54%） |
| 0x1419F6AA0 | （无名） 调用图传播: 27 锚点投 §4.10（56%） |
| 0x141B0EBE0 | （无名） 调用图传播: 30 锚点投 §4.10（53%） |
| 0x141F691A0 | （无名） 调用图传播: 73 锚点投 §4.10（51%） |
| 0x140278650 | （无名） 调用图传播: 34 锚点投 §4.10（59%） |
| 0x141B67320 | （无名） 调用图传播: 21 锚点投 §4.10（62%） |
| 0x1419F5F20 | （无名） 调用图传播: 32 锚点投 §4.10（50%） |
| 0x141AE1A10 | （无名） 调用图传播: 22 锚点投 §4.10（68%） |
| 0x141AF3970 | （无名） 调用图传播: 30 锚点投 §4.10（63%） |
| 0x141D537B0 | （无名） 调用图传播: 24 锚点投 §4.10（50%） |
| 0x140B2C3A0 | （无名） 调用图传播: 33 锚点投 §4.10（52%） |
| 0x140B431F0 | （无名） 调用图传播: 52 锚点投 §4.10（60%） |
| 0x141917BB0 | （无名） 调用图传播: 30 锚点投 §4.10（60%） |
| 0x1417DA6D0 | （无名） 调用图传播: 15 锚点投 §4.10（73%） |
| 0x1410F1390 | （无名） 调用图传播: 36 锚点投 §4.10（64%） |
| 0x140A56730 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141ECEAD0 | （无名） 调用图传播: 29 锚点投 §4.10（52%） |
| 0x14029A2A0 | （无名） 调用图传播: 35 锚点投 §4.10（51%） |
| 0x140B394B0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14133B0C0 | （无名） 调用图传播: 20 锚点投 §4.10（50%） |
| 0x141EFD530 | （无名） 调用图传播: 23 锚点投 §4.10（52%） |
| 0x140BD9800 | （无名） 调用图传播: 19 锚点投 §4.10（53%） |
| 0x141873530 | （无名） 调用图传播: 11 锚点投 §4.10（64%） |
| 0x141EAA2D0 | （无名） 调用图传播: 20 锚点投 §4.10（50%） |
| 0x140FB5270 | （无名） 调用图传播: 17 锚点投 §4.10（53%） |
| 0x140C155A0 | （无名） 调用图传播: 25 锚点投 §4.10（52%） |
| 0x141D37C20 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x140B89710 | （无名） 调用图传播: 16 锚点投 §4.10（50%） |
| 0x141AEA7F0 | （无名） 调用图传播: 21 锚点投 §4.10（52%） |
| 0x141FC8DC0 | （无名） 调用图传播: 11 锚点投 §4.10（55%） |
| 0x1420779F0 | （无名） 调用图传播: 16 锚点投 §4.10（50%） |
| 0x14177E4F0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1416DA320 | （无名） 调用图传播: 12 锚点投 §4.10（75%） |
| 0x141B0C160 | （无名） 调用图传播: 16 锚点投 §4.10（50%） |
| 0x1424EEFE0 | （无名） 调用图传播: 9 锚点投 §4.10（56%） |
| 0x141AEE250 | （无名） 调用图传播: 10 锚点投 §4.10（60%） |
| 0x1401DBE80 | （无名） 调用图传播: 16 锚点投 §4.10（56%） |
| 0x141951CA0 | （无名） 调用图传播: 17 锚点投 §4.10（53%） |
| 0x141CD92C0 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x141BCCE20 | （无名） 调用图传播: 22 锚点投 §4.10（64%） |
| 0x141F6A950 | （无名） 调用图传播: 10 锚点投 §4.10（60%） |
| 0x141CD9840 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x14061B810 | （无名） 调用图传播: 12 锚点投 §4.10（50%） |
| 0x141E90BF0 | （无名） 调用图传播: 10 锚点投 §4.10（50%） |
| 0x1402BA430 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x14191B6C0 | （无名） 调用图传播: 13 锚点投 §4.10（77%） |
| 0x141F57540 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141D88BC0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1409C9EE0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1402E29C0 | （无名） 调用图传播: 9 锚点投 §4.10（56%） |
| 0x14128D650 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x1415EFCE0 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x14226FDB0 | （无名） 调用图传播: 14 锚点投 §4.10（79%） |
| 0x140BC0A40 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x14052DC90 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141E70370 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x140A0F200 | （无名） 调用图传播: 10 锚点投 §4.10（70%） |
| 0x14209E210 | （无名） 调用图传播: 10 锚点投 §4.10（50%） |
| 0x141C11820 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140C53CC0 | （无名） 调用图传播: 13 锚点投 §4.10（54%） |
| 0x141589600 | （无名） 调用图传播: 10 锚点投 §4.10（50%） |
| 0x14025ABA0 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x140078490 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141876070 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x14145C8D0 | （无名） 调用图传播: 12 锚点投 §4.10（50%） |
| 0x14006B170 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141E4E8E0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141EB9DA0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x1420B3650 | （无名） 调用图传播: 7 锚点投 §4.10（71%） |
| 0x141BCD350 | （无名） 调用图传播: 10 锚点投 §4.10（60%） |
| 0x141E4E570 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x141EA38D0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x1402C3F90 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x1424EACF0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x14071D0D0 | （无名） 调用图传播: 11 锚点投 §4.10（55%） |
| 0x1413BDF40 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x140AF82F0 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x14023FB50 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x141FC4880 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1416C2320 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141CE6F00 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x1413E97D0 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x1418740F0 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x140ACE260 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140FD3890 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x140E345B0 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x1415289E0 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x1418721D0 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x141C5E640 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141871DD0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141BCC640 | （无名） 调用图传播: 9 锚点投 §4.10（56%） |
| 0x1402CE580 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x1424E7950 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1414A5EC0 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x141E4CDA0 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x14176B090 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x14006BD80 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141952390 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141713330 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1419ED810 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x141C81D00 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x141E488C0 | （无名） 调用图传播: 8 锚点投 §4.10（62%） |
| 0x1422F2190 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x141872F90 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1424BF970 | （无名） 调用图传播: 9 锚点投 §4.10（56%） |
| 0x140F04760 | （无名） 调用图传播: 12 锚点投 §4.10（67%） |
| 0x14186E090 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x14231B040 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14204A120 | （无名） 调用图传播: 12 锚点投 §4.10（67%） |
| 0x1406924B0 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x14039C9D0 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x141C36850 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x140339D60 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x140075540 | （无名） 调用图传播: 4 锚点投 §4.10（100%） |
| 0x1415B5F10 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x140710B60 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x1416BA520 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1410B8FD0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x141FE3AC0 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x1402C43F0 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141FE3D40 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141753E30 | （无名） 调用图传播: 8 锚点投 §4.10（62%） |
| 0x140FD03F0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140BD9F40 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x141C94F40 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1420B1BB0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x140A10F80 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x141EFB3E0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x14029A090 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x141B92270 | （无名） 调用图传播: 10 锚点投 §4.10（60%） |
| 0x141859AE0 | （无名） 调用图传播: 4 锚点投 §4.10（100%） |
| 0x1419C8D20 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x14022CAA0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x14240A8B0 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x1401AF560 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x140FD2700 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x1419B8A70 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x1410FE1B0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141F701D0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x14178FA80 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141A8D890 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A8D660 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A8DCE0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x140FEB510 | （无名） 调用图传播: 4 锚点投 §4.10（100%） |
| 0x141A95D00 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141952650 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141A89270 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1402C1C10 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141A87240 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141683370 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141B65A20 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141A84740 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A992C0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A990B0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1402C1E10 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x140144AE0 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x141A84550 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A95B10 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A89640 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A8BB10 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141FAD970 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x140B6CB00 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141A96D70 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141AE2DF0 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141CD5EB0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141495D30 | （无名） 调用图传播: 7 锚点投 §4.10（57%） |
| 0x141A81BC0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A96570 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A9A020 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A994C0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1413FF2D0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1424DE4C0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141A81010 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A854B0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A97CA0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141C8EB00 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141528460 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x141A852C0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A99E40 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x14168D750 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141D903B0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141A82540 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A850F0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A99870 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A93A50 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A82AE0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A81FB0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A82910 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A92840 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A817F0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A94E70 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A92300 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A92C00 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141A110E0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1419DFBA0 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141F8A780 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141A95040 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141959920 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x14239C9E0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x14027D510 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x140532E60 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141D3E6D0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141FDE990 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140A8B080 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140AF2590 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x141BC2330 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14168D330 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141DD1AB0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141958930 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141573F30 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141953210 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x1413BC4C0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x141C27760 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x14011AAD0 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x141954460 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141955CE0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x1415306F0 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x142054750 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x14022CD90 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14192AC80 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141483B50 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x142282EF0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1402C42B0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141667CC0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1402B3320 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14162B310 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x142327710 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140129960 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1423702D0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1415FFB30 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140FEB6C0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141046120 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x140E6E5E0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x141545B20 | （无名） 调用图传播: 8 锚点投 §4.10（50%） |
| 0x141927D50 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x14146C970 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x14201B9D0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140EF1760 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x140AE6790 | （无名） 调用图传播: 4 锚点投 §4.10（100%） |
| 0x142358650 | （无名） 调用图传播: 8 锚点投 §4.10（75%） |
| 0x142348E40 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x140E3CFA0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1402B5370 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x142015F40 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14113B530 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x1419C24D0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x14151E4A0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14195A0A0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x141169340 | PayloadReader 调用图传播: 8 锚点投 §4.10（50%） |
| 0x14151E5B0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14022C9A0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14072A790 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14128AC10 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x14226E3B0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14140BB60 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x140AEF000 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x1424CCC20 | （无名） 调用图传播: 5 锚点投 §4.10（60%） |
| 0x1425282F0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141380D20 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x14111F030 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x1415819F0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141955160 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140A458F0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140FD8D70 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1410246D0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1413B7520 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x14029DB10 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x142359CA0 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x142022750 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x1416745A0 | （无名） 调用图传播: 4 锚点投 §4.10（75%） |
| 0x141E508C0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140483440 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x140D43460 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140D3EA00 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x140D43200 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140D433E0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140D434E0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x14031E650 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x1401F0A30 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140476ED0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1410FF400 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x14031E6E0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140EF16F0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141DC8A20 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x1419E4BA0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1417F7120 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140F009E0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x141E509C0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x141E50980 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1415EC030 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1406F7100 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1410DC270 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x142238140 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140631650 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141B14CA0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |

#### 4.10.48 政治外交域函数补遗（22 函）

| VA | 语义/证据 |
|---|---|
| 0x1402DC240 | sub_1402DC240 uncomplete / focus + AcquireSRWLockExclusive/Release（国家焦点取消/完成操作，写锁） |
| 0x141A87E70 | sub_141A87E70 国家上次选举日期文本函数 GetLastElection（![MD] 文档串） |
| 0x14195E530 | sub_14195E530 调用 CRaidTargetManager::UpdateListsFor → 突袭目标管理器列表更新 |
| 0x1411BA4F0 | 同区段近邻 CPoliticalParty::[8](距 0x15620)属 4.10 族 sub_1411BA4F0 + 同区段近邻 CPoliticalParty::[8](距 0x15620)属 4.10 族 |
| 0x1411B3610 | 同区段近邻 CPoliticalParty::[8](距 0xE740)属 4.10 族 sub_1411B3610 + 同区段近邻 CPoliticalParty::[8](距 0xE740)属 4.10 族 |
| 0x1411F7980 | 同区段近邻 CPoliticalParty::[8](距 0x52AB0)属 4.10 族 sub_1411F7980 + 同区段近邻 CPoliticalParty::[8](距 0x52AB0)属 4.10 族 |
| 0x140A9E350 | sub_140A9E350 突袭（Raids）GUI/触发器（raid_tooltip） |
| 0x1411F0D00 | 同区段近邻 CPoliticalParty::[8](距 0x4BE30)属 4.10 族 sub_1411F0D00 + 同区段近邻 CPoliticalParty::[8](距 0x4BE30)属 4.10 族 |
| 0x1414E9940 | sub_1414E9940 突袭（Raids）GUI/触发器（tooltip_raid） |
| 0x1411E47D0 | 同区段近邻 CPoliticalParty::[8](距 0x3F900)属 4.10 族 sub_1411E47D0 + 同区段近邻 CPoliticalParty::[8](距 0x3F900)属 4.10 族 |
| 0x141197AC0 | 同区段近邻 CPoliticalParty::[8](距 0xD410)属 4.10 族 sub_141197AC0 + 同区段近邻 CPoliticalParty::[8](距 0xD410)属 4.10 族 |
| 0x141192090 | 同区段近邻 CPoliticalParty::[8](距 0x12E40)属 4.10 族 sub_141192090 + 同区段近邻 CPoliticalParty::[8](距 0x12E40)属 4.10 族 |
| 0x140A3FDA0 | 域关键词匹配 sub_140A3FDA0 + 域关键词匹配 |
| 0x1411E6690 | 同区段近邻 CPoliticalParty::[8](距 0x417C0)属 4.10 族 sub_1411E6690 + 同区段近邻 CPoliticalParty::[8](距 0x417C0)属 4.10 族 |
| 0x141C41380 | 域关键词匹配 sub_141C41380 + 域关键词匹配; 被调源码 hoi4 |
| 0x1411B3780 | 同区段近邻 CPoliticalParty::[8](距 0xE8B0)属 4.10 族 sub_1411B3780 + 同区段近邻 CPoliticalParty::[8](距 0xE8B0)属 4.10 族 |
| 0x1416E3C70 | 域关键词匹配 sub_1416E3C70 + 域关键词匹配 |
| 0x1411FCF00 | 同区段近邻 CPoliticalParty::[8](距 0x58030)属 4.10 族 sub_1411FCF00 + 同区段近邻 CPoliticalParty::[8](距 0x58030)属 4.10 族 |
| 0x1411CA730 | 同区段近邻 CPoliticalParty::[8](距 0x25860)属 4.10 族 sub_1411CA730 + 同区段近邻 CPoliticalParty::[8](距 0x25860)属 4.10 族 |
| 0x1411DDEF0 | 同区段近邻 CPoliticalParty::[8](距 0x39020)属 4.10 族 sub_1411DDEF0 + 同区段近邻 CPoliticalParty::[8](距 0x39020)属 4.10 族 |
| 0x1411DD770 | 同区段近邻 CPoliticalParty::[8](距 0x388A0)属 4.10 族 sub_1411DD770 + 同区段近邻 CPoliticalParty::[8](距 0x388A0)属 4.10 族 |
| 0x1411E5060 | 同区段近邻 CPoliticalParty::[8](距 0x40190)属 4.10 族 sub_1411E5060 + 同区段近邻 CPoliticalParty::[8](距 0x40190)属 4.10 族 |

#### 4.10.49 政治外交域函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x141A8C990 | 串 "Gets the name of the active side of ... power balance" 串 "Gets the name of the active side of ... power balance"，GetActiveSideName |
| 0x1411BD8F0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140B48B30 | 无名 · "GFX_rule_unknown" 规则图标键 "GFX_rule_unknown" 规则图标键 |
| 0x1411E4660 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x1411EFCC0 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |

#### 4.10.50 政治外交域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141C9DE50 | UI/数据绑定（loc autonomy_score_icon） loc 键 "autonomy_score_icon"/"MONTHLY_LL_FREEDOM_TO_PUPPET"/"MONTHLY_LL_FREEDOM_TO_MASTER"（自治度/租借自由度数据） |
| 0x141588A60 | 业务逻辑（键 ruling_party_info） "ruling_party_info"/"leader"/"pol_faction_icon"/"elections"/"POLITICS_NEXT_ELECTION"（政治面板数据） |
| 0x14023EA50 | 业务逻辑（见证据锚） "Please specify country tag to annex"/"Country tag does not exist!"（吞并控制台命令） |
| 0x141C82250 | 业务逻辑（键 opinion_bg） "opinion_bg"/"our_opinion"/"their_opinion"（外交关系意见 UI） |

#### 4.10.51 政治外交域函数补遗（22 函）

| VA | 语义/证据 |
|---|---|
| 0x14039FB20 | （无名） 调用图传播: 13 锚点投 §4.10（54%） |
| 0x1402B0BB0 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x14137CA70 | （无名） 调用图传播: 6 锚点投 §4.10（83%） |
| 0x14209D5D0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x141CA1530 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x140A588C0 | （无名） 调用图传播: 9 锚点投 §4.10（89%） |
| 0x141C510F0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1420B32C0 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x140C4F1A0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140C4F2D0 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x14151F540 | Reader 调用图传播: 6 锚点投 §4.10（50%） |
| 0x1420399F0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x140FC3690 | （无名） 调用图传播: 6 锚点投 §4.10（67%） |
| 0x140B39D60 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1419D26B0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1419C3680 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x1411EF550 | （无名） 调用图传播: 2 锚点投 §4.10（100%） |
| 0x1416D9DA0 | （无名） 调用图传播: 4 锚点投 §4.10（50%） |
| 0x1402E1B80 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140079F70 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |
| 0x140080240 | （无名） 调用图传播: 3 锚点投 §4.10（67%） |
| 0x1406F7140 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |

#### 4.10.52 政治外交域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141C95D90 | （无名） 调用图传播: 6 锚点投 §4.10（50%） |
| 0x141FE38C0 | （无名） 调用图传播: 6 锚点投 §4.10（100%） |
| 0x141FE3450 | （无名） 调用图传播: 3 锚点投 §4.10（100%） |
| 0x141C50C20 | （无名） 调用图传播: 2 锚点投 §4.10（50%） |

#### 4.10.53 政治外交域函数补遗（19 函）

| VA | 语义/证据 |
|---|---|
| 0x141E47300 | 无名 sub_（断言站点/串定位） 串字面量 "PEACE_STACK_WITH" |
| 0x140D22670 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_SUPPORT_ENEMIES" |
| 0x140D23150 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_RELATION_IMPROVEMENT_INVALID" |
| 0x140D3FE60 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_WAR_NO_WAR_NO_WARGOAL" |
| 0x141C81F80 | 无名 sub_（断言站点/串定位） 串字面量 "diplo_actions_entry_bg" |
| 0x141757E00 | 无名 sub_（断言站点/串定位） 串字面量 "global_diplorequesticon_window" |
| 0x141864110 | 无名 sub_（断言站点/串定位） 串字面量 "peaceconference_top_window" |
| 0x140E49B90 | 无名 sub_（断言站点/串定位） 断言站点 peaceconference.cpp:4828 |
| 0x140E38D80 | 无名 sub_（断言站点/串定位） 断言站点 peaceconference.cpp:1155 |
| 0x141F2BD90 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_INCOMING_LEND_LEASE_DEAL_DESC" |
| 0x141F2DA30 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_INCOMING_LEND_LEASE_DEAL_DESC" |
| 0x140E40BA0 | 无名 sub_（断言站点/串定位） 串字面量 "PEACE_CONFERENCE_COST_TOO_HIGH" |
| 0x141C94CD0 | 无名 sub_（断言站点/串定位） 断言站点 diplomacyviewcontrollers.cpp:5466 |
| 0x1417AEB80 | check_accept 触发器评估 构造 "check_accept" + sub_1422C9F20 |
| 0x140A849A0 | 无名 sub_（断言站点/串定位） 断言站点 peace_conference_database.cpp:212 |
| 0x141C51060 | 无名 sub_（断言站点/串定位） 断言站点 politicalideaswindow.cpp:485 |
| 0x141C94E90 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_NO_WARGOAL" |
| 0x1426358F0 | 无名 sub_（断言站点/串定位） 断言站点 ai_political_minister.cpp:2059 |
| 0x141514CF0 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_NO_AT_WAR" |

#### 4.10.54 政治外交域函数补遗（148 函）

| VA | 语义/证据 |
|---|---|
| 0x14221D5E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x142220C00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141DA4EC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1409FD630 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x142520D7C | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141C4C890 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141F47880 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141BC3A00 | 无名 sub_（调用图定位） 调用图传播: 2/4 锚点投 §4.10 |
| 0x1411B9FD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1415D0910 | 无名 sub_（调用图定位） 调用图传播: 5/9 锚点投 §4.10 |
| 0x141C80AD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141D751C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14006C470 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.10 |
| 0x141C99060 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14007EFA0 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.10 |
| 0x14007C550 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.10 |
| 0x141DEBED0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14007BE60 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.10 |
| 0x14007BC10 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.10 |
| 0x1416A9040 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x142256290 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1415EA9C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140B39280 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141A8B050 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8CFF0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8B4B0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8AE30 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8AA30 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8B280 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8CDC0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A87A50 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8AC30 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A87620 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A87840 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8C120 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8E2D0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A85690 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A86640 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A86A50 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A87420 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A8C570 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A84360 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x142255220 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141A84B30 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A86E40 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A91B50 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141BC75C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141A815F0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141A953B0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x141F49210 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141A972E0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.10 |
| 0x14007C0B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14007C300 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1400747E0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.10 |
| 0x142018740 | 无名 sub_（调用图定位） 调用图传播: 2/4 锚点投 §4.10 |
| 0x141F49060 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14007F480 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.10 |
| 0x140530000 | 无名 sub_（调用图定位） 调用图传播: 3/5 锚点投 §4.10 |
| 0x14228AA90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14006B7F0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.10 |
| 0x140075990 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.10 |
| 0x1418CC1F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141CA0400 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1411B7AD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140ABF5E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140A449C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141E6E0A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1411F2AD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14225BF50 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.10 |
| 0x14002F330 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14194F800 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1424CB1E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14174ADB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141F48F50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1411E4400 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14235B7F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1413BCC10 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.10 |
| 0x142526358 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141C83840 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140EAE840 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14201D280 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1419B8E10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14201D180 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1419B8740 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1424ED280 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1412A18C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141EA34A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14205DDB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140AF4A40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1418E92D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14145E0D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140B47820 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1410C8380 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14145CBF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140E522A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141F47BF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140A57160 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1411C9BC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1419CA1E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140FD28F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1417AAF70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1410E26E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141092020 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141A11E00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1416A8F80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141589550 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141CDFAA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141EDAD70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1414A6730 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140A4F620 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1414A2FF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1422F75E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1419FA510 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141B44F20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140BBBB10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1412FB760 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140A90A70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140D89180 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14204C8B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140BBBC80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140BBBBD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140A03A50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140FEB1A0 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.10 |
| 0x14071E6A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14071E750 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140A44B30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14053D930 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140E84B00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141CD6120 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141290510 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140B5C780 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14194F980 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141FA1610 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1414DE830 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1401F8570 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140DA0DC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x140B95740 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x142705C60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141195700 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14192A8D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x142281D60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14239C000 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141E48660 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141195F20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14137CC20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141AF9440 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141F9FD80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1426F8360 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |

#### 4.10.55 政治外交域函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x1411BAD60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x141761700 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x14204CD40 | 无名 sub_（调用图定位） 调用图传播: 5/10 锚点投 §4.10 |
| 0x141195590 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x1417674E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |
| 0x142358F90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.10 |

#### 4.10.56 政治外交域函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x141546FE0 | （无名） 串 "SUBMARINES"/"TRADE"/"PERMISSION_DESC"（许可描述键） |
| 0x1413DF240 | （无名） 串 "_research"/"POLITICAL_RESEARCH_BONUS_ENTRY"（CATEGORY/FACTOR 键） |
| 0x1410E0B20 | （无名） civilwar.cpp；断言 "Transferring into a war against a country the revolter is already at war against."/"Failed to create war." |
| 0x140B46E40 | （无名） 串 "GFX_ideology_" 前缀拼接（意识形态图标） |
| 0x14145ADD0 | （无名） 调 sub_1401AD740（CDiplomaticAction::GetFirstCountryRef）+ pdx_core 内存族（异步轮询形） |

#### 4.10.57 政治外交域函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x140D38FA0 | 关系判定 关系/功能判定：a1+656 目标 + sub_1401AEB50(18/16) 功能门 + sub_1406CF890 国家 + sub_141191500(*(+208)+24) 链校验 |
| 0x141BB5E60 | 关系判定 关系判定：a2+184+210 旗（位 1 置且位 2 未置）门控 + sub_140BB5490(a2+392) 国家索引 + a1+224 表比对 |

#### 4.10.58 政治外交域函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x14052FA50 | 未决窗口函数 · 顾问描述格式化 FILE formatted_localization.h + 串 "advisor_desc" 顾问描述格式化 |
| 0x140A45CD0 | 未决窗口函数 · 意识形态库析构 `TReloadableGameItemDatabase<CIdeologyDatabase>` + `TGameItemDatabase<CIdeologyDatabase>` 双 vtable 析构 |
