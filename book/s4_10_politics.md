

### 4.10 CDiplomacyStatus / CPolitics / 自治

方法群 (dip/rs/ps/party/autonomy 五类) 锚 = diplomacy.cpp / relation.cpp / politics.cpp assert 系 + 效果类 Execute (CEffect 槽 13) 批量锚定。日期对象统一形态 = CGregorianDate 24B {vt@+0, hours@+8, greg vt@+16} (§3.7a)。

#### 4.10.1 CDiplomacyStatus (dip)

| 项 | 值 |
|---|---|
| 挂载点 | `*(cc+3976)` (dip) |
| sizeof | ≥1024B |
| vtable RVA | 0X142960198 |
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
| +56 | POD 数组 | 瞬时暂存列表 {data@+56, cap@+64, count@+68, alloc@+72} (扁平 POD 数组 — 增长码无 vtable 装配, teardown 走 pdx 24B 通用释放 sub_14011EBD0 而非逐元 dtor; 全档 333 国运行时全空 — 疑战争结算/和会期工作缓冲; 无 `*(…+3976)+56` 消费形态, 外交 UI 不消费) | 定案 |
| +80 | POD 数组 | 瞬时暂存列表 {data@+80, cap@+88, count@+92, alloc@+96} (同 +56, 全档全空; 外交 UI 不消费) | 定案 |
| +104 | CWargoal** | **available_wargoals 容器数据** {data@+104, cap@+112, count@+116, alloc@+120} — 8B 指针元 → wargoal 对象 (元+60=目标国 idx); **与 cc+1328 非同一容器** (全量计数分布: 同值 4 / 仅本侧 1 / 仅 cc+1328 侧 14) | writer 键 0x337C; GUI 见下方 GUI 消费表 |
| +128 | CWargoal** | **wargoals 容器数据** {data@+128, cap@+136, count@+140, alloc@+144} — 完整 CWargoal 对象 (vt 0x1429E0058; 动态 token@元+64 = type 定义指针→*(def+8)) | writer 键 0x331D ↔ 存档 `wargoals={...}` (定案) |
| +152 | tag_id 容器 | **当前交战国 tag 缓存 (enemies)** {data@+152, cap@+160, count@+164, alloc@+168} — u32 tag 列表 (0X140D37C60 经 war rel 求最早开战时刻铁证; 0X140D3F100 = "is_enemy" 谓词查此; 己敌三件套 {+152 插入序/+248 排序集/+344 平行战争计数}) | 定案 |
| +176 | uint32 向量 | **战争同盟军缓存** {data@+176, cap@+184, count@+188, alloc@+192} — u32 tag 列表 = 我方所在战争阵营全体成员 (**不含自己**; 探针互见互证: i3/i4 互列对方各不含己, 孤军作战国为空) | 定案 |
| +200 | tag_id 容器 | **generate_wargoal 列表** {data@+200, cap@+208, count@+212, alloc@+216} (token 13339 直名; 推定 = 我方正在辩护战目标的目标国缓存; 谓词序: +152(交战) → +200 → +224 → +368(已有战目标) = "潜在敌国" 判定; 对账档均空, 写入点未定位 — 推定与 CTimedWargoalActivity (ps+8) 生命周期联动) | 定案 |
| +224 | tag_id 容器 | **generate_wargoal_against 列表** {data@+224, cap@+232, count@+236, alloc@+240} (token 13860 直名; **= 本国正在 justify 的目标国列表** (is_justifying_wargoal_against; sub_140D40290 直读, 方向 = 我方为发动方 — 定案); 0X1403CFE50 逐国双向查 +368/+224) | 定案 |
| +248 | tag_id 向量 | **敌国 tag 排序集** {data@+248, cap@+256, count@+260, alloc@+264} — +152 的升序 set 版 (探针: 插入序 {24,188,66} vs 排序 {24,66,188}) | 定案 |
| +272 | tag_id 向量 | **共同敌国排序集** {data@+272, cap@+280, count@+284, alloc@+288} — 与盟友共享的敌国升序 set (仅同盟国非空, 孤军国为空; 与 +296 成对: 排序/插入序) | 高置信 |
| +296 | tag_id 向量 | **共同敌国插入序列表** {data@+296, cap@+304, count@+308, alloc@+312} — +272 的插入序版 (序与 +152 一致; ⚠ Reset2 不清此槽 — 小不对称, reader 防御) | 高置信 |
| +320 | tag_id 向量 | **占领我方核心州的敌国 tag 缓存** {data@+320, cap@+328, count@+332, alloc@+336} (0X140D45F10 静态铁证: 逐敌国(+152) → 其 controlled_states(cc+1120) → state owner==我 且 cores(state+176) 含我 (overlord 解析) → 推入; 探针互证 ⊂ +152) | 定案 |
| +344 | uint32 向量 | **per-敌国关系分类码** {data@+344, cap@+352, count@+356, alloc@+360} — 与 +248 严格平行同序的 u32 码表 (∈{1,4,5-11}: 1=基础可交互 / 4=阵营聚合 / 5=对方视我交战 / 6=对方对我造理由 / 7-8=附属链 / 9-11=taken_lead_to_wars 族); 每日外交 FirstPass (sub_140D357E0) 全量重建: 清 +248/+344 → 扫全量国 bitmap 去重后平行追加 — SecondPass 聚合共同敌国 dip+272/+296 消费 | 定案 |
| +368 | 扁平 u32 数组 | **附属国 tag 缓存** {data@+368, cap@+376, count@+380, alloc@+384} (定案): sub_1401B1470 stride-4 线性查定形态; 四消费者定语义 — sub_140E649A0 工厂分成 / 0X140B35D80 附属+自治 tooltip / 0X1406DECD0「我是其附属」谓词 / contains 0X140D3F050「wargoal 针对附属视同针对宗主」 | writer 不序列化; GUI 见下方 GUI 消费表 |
| +392 | tag_id | overlord tag 标量 (CAutonomyProgressView "overlord_name"/"SUBJECT_OF_NAME" 直名) | 与 war_relation 表 wr+392「second_wargoals cap」不同基, 无真冲突 |
| +400 | tag_id 容器 | **governments_in_exile_we_host** (u32 tag idx 列表) {data@+400, cap@+408, count@+412, alloc@+416} | writer 键 0x3ABB |
| +424 | uint32 | **_HostingUs** (流亡东道国 idx) | assert `_HostingUs.IsValid` (0X140D43B50); writer 键 0x3AB9 ↔ `hosting_our_government_in_exile="ENG"` |
| +432 | fixed×1e-5 (i64) | **legitimacy** (钳 0..上限) | CAddLegitimacyEffect::Execute 0X140362C80 → 0X140D344D0; writer 键 0x2C41 ↔ `legitimacy=100` |
| +440 | uint32 | exile_army_leaders | writer 键 0x3AC0; daily legitimacy≥阈值 → 造将+1 |
| +448 | 内嵌 CModifier (~192B) | 外交动态修正块 | ctor 装 CModifier vt (形态定案/语义推定) |
| +640 | uint8 | **流亡活动旗** (政府流亡中 = 1) | daily 0X140D3B920:280; 且 legitimacy≤0 → 流亡终结 |
| +641 | uint8 | **naval_blockade** | writer 键 0x27F8 ↔ `naval_blockade=yes` (定案; 10232 亦 = CNavalBlockadeRelation token) |
| +648 | CCountry* | **属主国回指** | 全方法群通用 |
| +656 | CFaction* | **所属派系指针**; 成员容器 {d@+88, c@+100} | SetFaction 0X140D44800 (断言 "enemies in the faction"); GUI 见下方 GUI 消费表 |
| +664 | CGregorianDate 24B | **trade 日期** (上次贸易日期) {vt@+664, hours@+672, greg vt@+680} — writer 0x140D47400 写 `if (*(+672) != 43808760) sub_1424C2E20(v2, 10350, +680)`, 键 10350 = token 表直名 `trade`; reader 0x140D41330 case 10350 → `sub_1424C0AA0(a2, +680)`; rs 侧同键 = rs+112 (rs writer 0x140D2DB40) — ⚠ 对账档 0 例 `trade=` 的根因 = 门为「hours ≠ 43808760 初始哨兵」, 无贸易则恒不写 | writer 键 10350 |
| +688 | CGregorianDate 24B | **last_surrender_date** {vt@+688, hours@+696, greg vt@+704} — writer token 0x3681=13953 直名 + 存档键序 (faction_join_date 前) 互证; 实档普遍出现 (单档 7–21 例) | writer 键 13953 |
| +712 | CGregorianDate 24B | **faction_join_date** {vt@+712, hours@+720, greg vt@+728} | writer 键 0x386A; SetFaction 写当前小时 |
| +736 | uint8 | **capitulated** | writer 键 0x3549 ↔ `capitulated=yes`; uncapitulate 0X140D45D80 置 0; GUI: 战争盟友行显示 (CWarAllyItem Refresh sub_141E7B700) |
| +744 | CGregorianDate 24B | **capitulated_date** {vt@+744, hours@+752, greg vt@+760} | writer 键 0x3CB2 (定案; +736 门控) |
| +768 | 匿名结构 (40B) | 待处理外交行动 容器数据 {data@+768, cap@+776, count@+780, alloc@+784} — (proposed), 40B 条 | 布局见 §4.10.8; 插入 0X140D34C80 |
| +792 | CWarOverView 向量 | **当前战争一览缓存** {data@+792, cap@+800, count@+804, alloc@+808} — **48B 元 = {side1: u32 tag 向量 24B, side2: u32 tag 向量 24B}** (构建器 0X140D3C3E0(dip, out=dip+792): 从 dip+32 滤 war 关系取战争双方阵营, 无序去重插入; 三直接调用点 (0X1415D6FF0 外交视图 + CWarOverView populate 两点); RTTI 无 CIncomingDiplomaticAction 类 — 无独立 RTTI 类) | 定案; GUI 见下方 GUI 消费表 |
| +816 | CRelationStatus** | **脏关系缓存** {data@+816, cap@+824, count@+828, alloc@+832} | daily 重建并逐元 attitude 刷新 (0X140D3B920; 高置信) |
| +840 | uint8 | 脏关系缓存重建旗 | 高置信 |
| +848 | CCurrentAutonomyStatus* | 自治 CCurrentAutonomyStatus | 见 §4.10.9; writer 0X14067AA30 |
| +856 | 匿名结构 (12B 形状) 向量 | **taken_lead_to_wars** {data@+856, cap@+864, count@+868, alloc@+872} — 12B 条 {tag u32, reason u32, days u32} | writer 键 0x4B9A + SLeadsToWarReader (定案; rs 侧无对应行) |
| +880 | uint32 | cached_allies_and_gurantees 容器数据 {data@+880, cap@+888, count@+892, alloc@+896} (存档原拼写 "gurantees") | writer 键 0x4B97; u32 idx 数组 → tag 名 |
| +904 | CMilitaryAccess* 向量 | **_MilitaryAccesses** {data@+904, cap@+912, count@+916, alloc@+920} (CMilitaryAccess::Add + COfferMilitaryAccess::Add 共容器, offer 共存; find-or-push "Contains == false" 断言 diplomacy.cpp:0x31C); **元素 vt RVA 0x2960408 = CMilitaryAccessRelation** (活体直证) | assert `_MilitaryAccesses.IsEmpty` (0X140D3A1B0:379) |
| +928 | CDockingRights* 向量 | **_NavalAccesses** {data@+928, cap@+936, count@+940, alloc@+944} = docking_rights(+offer) 缓存 (CDockingRights::Add + COfferDockingRights::Add; first 侧) | 定案 |
| +952 | CDockingRights* 向量 | **_OfferNavalAccesses** {data@+952, cap@+960, count@+964, alloc@+968} = offer_docking_rights 侧 (CDockingRights::Add second 侧; 方向分工未证 — 待裁, 需活体读 offer_docking_rights 落侧) | 定案 |
| +976 | CAirBaseAccess* 向量 | **air_base_access(+offer) 缓存** {data@+976, cap@+984, count@+988, alloc@+992} (CAirBaseAccess::Add + COfferAirBaseAccess::Add); **元素 vt RVA 0x2A217F8 = COfferAirBaseAccessRelation** (活体直证: 本档唯一非空条目即 offer 侧) | 定案 |
| +1000 | 指针容器 | **captured (被俘将领缓存)** {data@+1000, cap@+1008, count@+1012, alloc@+1016} — 8B 指针元 | writer 键 0x3D14 ↔ `captured={`; "captured generals cache" 串 (定案; rs 侧无对应行) |

dip 字段 GUI 消费 (消费点 ≥3 者立表):

| 字段 | 消费点 | 用途 |
|---|---|---|
| dip+104 available_wargoals | 宣战面板 wargoals_grid ([7] 0X141C99DA0) | 我方侧网格 (wg+60==对方 tag ∧ 对方 dip+368/{+380} 含) |
| dip+368 附属国 tag 缓存 | 宣战网格对方侧门 / B15 贸易过滤 subject 支 / CSubjectViewItem / CActiveWargoalStripView 附属覆盖 (§4.10.16) | 附属覆盖判定 (wg 针对附属视同针对宗主) |
| dip+656 CFaction* | 目标国 header 阵营名 (sub_140D8BB80, faction_name; 无 → DIPLOMACY_NO_FACTION) / FactionView 取链 (gs+1312/1316 → 本槽) / B15 贸易过滤白名单 (members {d@+88, c@+100} CCountry* 集) | 阵营归属展示/过滤 |
| dip+792 当前战争一览缓存 | CWarOverView 同构副本 (side1 集@+23576/count+23588, side2@+23600/count+23612; 聚合旗+23624 / 三过滤器+23625-27 / 双排序模式+72/+76; populate sub_1418AC420 → sub_1418AFFC0/sub_1418ADFA0) | 战争一览 |
| rs+648 puppet 槽 | CSubjectRelationstripView target 链 (+56 附属国 tag → dip+8 → 本槽) | 附属关系条 (§4.10.2 槽分配表) |

#### 4.10.2 CRelationStatus (rs)

rs = dip+8 active_relations 容器元素, sizeof 0x9C0。

关系对象落入点 = `sub_140D20230(rel)`: 取 `dip = *(cc+3976)` → `dip+8 表[对方国 idx]` → 在**对方 dip 的 +208 容器** (count@+220) 查重, 命中即报 "Initializing Duplicate Relationship: %s between %s and %s" (relation.cpp:200); 未命中走 vt[21] (0xD8) 插入。关系类由 token 工厂 `sub_140D1EE80(token)` 分派构造 (CPersistentReloadableGameItemDatabase 族)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CTimedOpinionModifier* 向量 | **CTimedOpinionModifier\* 内联 2 向量** {data@+8, cap@+16, count@+20, alloc@+24} (ctor 装 CPdxHybridInlineBufferAllocator\<CTimedOpinionModifier*,2\> vtable; 元素 8B; 形态定案 = 内联 2 元素混合缓冲指针向量; 语义 (附属/临时意见暂存) 保留 — 无 writer/parse 触及, 插入点未定位) |
| +80 | uint32 | **对方国 idx**; AddOpinionModifier 0X140D19390 / 事件 scope 构造 |
| +88 | CGregorianDate 24B | **last_send_diplomat** {vt@+88, hours@+96, greg vt@+104}; writer 键 10568 门 hours≠哨兵 (定案; available_wargoals 真身 = dip+104) |
| +112 | CGregorianDate 24B | **trade** {vt@+112, hours@+120, greg vt@+128}; writer 键 10350 ↔ `trade="1940.4.1.15"` (定案; wargoals 真身 = dip+128) |
| +136 | CGregorianDate 24B | **trade_equipment** {vt@+136, hours@+144, greg vt@+152}; writer 键 11180 |
| +160 | CGregorianDate 24B | **truce_until** {vt@+160, hours@+168, greg vt@+176}; writer 键 13835 |
| +184 | CGregorianDate 24B | **kicked** {vt@+184, hours@+192, greg vt@+200}; writer 键 14445 |
| +208 | CRelation* 向量 | **_Relations** (非属主侧关系) {data@+208, cap@+216, count@+220, alloc@+224}; assert `_Relations.IsEmpty` (teardown 0X140D1E470) |
| +232 | token 向量 | **_OwnedRelation** (= 书内 "relations") {data@+232, cap@+240, count@+244, alloc@+248}; assert `_OwnedRelation.IsEmpty`; writer 逐元动态 token@元+8 |
| +256 | CTimedOpinionModifier* 向量 | opinions {data@+256, cap@+264, count@+268, alloc@+272} — **指针元 8B → CTimedOpinionModifier 本体 64B** {过期 hours@+24, modifier def@+40, 旗@+57} (容器为指针数组, 0X140D2A150 逐元解引用刷新); AddOpinionModifier 0X140D19390; parse 10913 — 定案 (1.19.3 锚: writer 0x140A82C60 / reader 0x140A824E0; +48 value i64 / +56 decay 旗 / +57 do_not_expire 旗) |
| +280 | 匿名结构 (元素) 向量 | modifiers {data@+280, cap@+288, count@+292, alloc@+296}; AddRelationModifier 0X140D19590; writer 10597 写元+424 名 |
| +320 | 匿名结构 (16B 形状) 向量 | **生效修正值块** {data@+320, count@+332} 16B 条; AddRelationModifier 添加 (sub_140557840); teardown 遍历 |
| +496 | CDiplomacyStatus* | **属主 dip 回指**; *(*(rs+496)+648)+8 = 属主国 |
| +568 | llth 块基 | llth 块基 {+576, +584, +592, +600} 四 fixed×1e-5 (⚠ 块基 = +568, +576 为首个分量); writer 键 12950: 四分任非零才写 |
| +720 | u32 | faction_join |
| +744 | 指针槽 | **_pWarRelation**; assert `_pWarRelation == nullptr`; GUI: CWarRelationStripView target 链终点 (+56 本国 tag → dip+8 active_relations[对方idx] → 本槽; 条目 +40 = token 10637 "war" / +44 = 侧模式 1=initiator/2=receiver, relationstripview.cpp 铁证; 宿于 CDiplomacyView 双实例) |
| +768 | int32 | cached_sum; writer 键 11598; 重算 0X140D2D8D0 — opinion 唯一 UI 出口 = sub_1406F4490 (dip+8 active_relations → rs+768), 外交国列表行 opinion 全走此函数 |
| +776 | fixed×1e-5 | border_friction; writer 键 11286 ↔ `border_friction_claim=` |
| +784 | u8 旗 | **「与对方共同参战」旗** (has_war_together_with 判据) — 读点 = sub_140D256B0 `*(u8*)(a1+784)`, 由 CHasWarTogetherTrigger (vt 0x14278E4C0) 槽[22] Evaluate sub_1403D9B20 调用; 置位点 = setter sub_140D2CFD0 ← sub_140D46650 (rs 全量重建, 先全量清 0 再对满足条件的对方国置 1); teardown sub_141B60F80 清 0。**被门控者** = llth 四累加器 sub_140D2A0A0(+584) / sub_140D2A0C0(+576) / sub_140D2A0E0(+600) / sub_140D2A100(+592), 四者体首行均 `if (*(BYTE*)(a1+784))` ⇒ +784 是 llth 累计的前置使能, **非 llth 旗本身**; llth 块本体 = rs+568 起 32B (writer sub_140D2DB40 发 token 12950); **活体分布: 全量 135000 rs 条目中仅 20 条置位** |
| +792 | CAIAttitude* | attitude (名 SSO@+16); writer 键 11737 ↔ `attitude="attitude_hostile"` |
| +800 | uint8 | attitude 锁定旗 A; "Locked attitude for %s" 0X140D19E10 |
| +801 | uint8 | attitude 锁定旗 B; 同上 |
| +804 | fixed5 数组 | recently_leased_ic; writer 键 13887 |
| +808 | rule_overrides 块基 | **rule_overrides 块基** (flags 28 槽 @+816 步进 4 / desc 28×32B @+928 / vec 28×24B @+1824 的块基); writer 键 10146 (门 = flag 数 + vec 计数和 >0); Reset 逐个析构 |
| +816..+924 | u8 [28] | rule_overrides 槽 k flag (槽 k = 816 + 4k, k∈[0,27]) |
| +928..+1792 | 串 [28] | rule_overrides 槽 k desc 串 (槽 k = 928 + 32k, 每串 32B) |
| +1824..+2472 | 容器 [28] | rule_overrides 槽 k vec 容器 (槽 k = 1824 + 24k, 每槽 24B); 键 token@rules_base+56k+40, rules_base = `*(BASE+53575920)` |

per-relation-type 活动关系缓存槽分配 (+504..+760, 8B 步进 ~32 槽; 方法 = 19 关系子类 vtable **vt[21]=Add / vt[22]=Remove** 逐类读槽):

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

teardown 实清 23 槽; 不清 +624/+632/+640/+688/+696 五槽 (引擎特例/遗漏, reader 防御)。槽族写入门 = `*(rs+440)<=0 && !*(rs+356)` (两计数未名)。

#### 4.10.3 关系对象基类 (rel) 与落盘规则

关系对象 = relations {d@rs+232, c@rs+244} 8B 指针数组, 元素基址 rel; 基类 writer sub_140D2DAA0 (全 11 型共用)。

| 偏移 (rel) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | uint32 | first_idx | |
| +20 | uint32 | second_idx | |
| +21..+31 | — | = first_idx@+16 / second_idx@+20 尾 + start CGameDate {vt1@+24, hours@+32, vt2@+40} 头 (ctor 0X140D17AB0: `*(+32)=43808760`, `+24/+40=CGameDate::vftable`) | |
| +32 | hours | start | CGameDate 槽@+40, 族A |
| +33..+55 | — | = start 日期 {hours@+32 尾, vt2@+40} + end CGameDate {vt1@+48, hours@+56, vt2@+64} 头 | |
| +56 | hours | end | CGameDate 槽@+64, 族A |
| +57..+71 | — | = end 日期 {hours@+56 尾, vt2@+64} + cancel u8@+72 前 pad | |
| +72 | uint8 | cancel — **+73 uint8 = 基类 CRelation 级「隐藏/抑制关系」门**: writer 不发射/parser 不装载/运行时零写点 (59 处全局 +73 写点逐函数过筛无一属关系族, 仅基 ctor `*(_WORD*)(a1+72)=0` 随 cancel 清零, 本 build 恒 0 预留死字段); 读点约 12 函数全经 rs+744 解引, 极性一致「置位=视同无此战争/关系」, sub_140D39900 对 guarantee 关系同查 +73 证基类通用门; 业务名高置信 = hidden relation | |

落盘规则 (全 11 型通用):

| 规则 | 内容 |
|---|---|
| war 挂载点 | rs+232 容器 (运行时探针定案); 运行时 token@+8 = 14346 "war_relation" (与存档同名), 非 writer 侧 10637 "war"; 单侧挂载 (每对仅 1 例, 如 JAP→CHI 挂 JAP 侧) |
| end_date 通用门 (全 11 型通用, 非 nap 专有) | `i32@(rel+56) > i32@(rel+32)` 才写 end_date (end_hours > start_hours); 无哨兵比较; 未设 (0 ≤ start) 不写 |
| cancel 互斥 | `ru8(rel+72)≠0` 时写 cancel=yes **且 start_date 不写** (互斥) |

**Relation 工厂 0x140D1EE80** (存档 reader/运行时 clone 型分发: switch(token) → malloc + 基 ctor 0x140D17AB0(this, token) + 装 vt):

| 类 | vt | token | sizeof | 扩展 |
|---|---|---|---|---|
| CGuaranteeRelation | 0x1429607C8 | 10458 | 80 | 无 (rs 槽 +656/+664, Add 方向实证 first→+656/second→+664) |
| CNonAggressionPactRelation | 0x142960888 | 12220 | 80 | 无 (rs 单槽 +720; 槽[10] = ret1) |
| CMilitaryAccessRelation | 0x142960408 | 10548 | 80 | 无 (rs 槽 +672, 与 offer 共槽族) |
| COfferMilitaryAccessRelation | 0x1429604C8 | 12232 | 80 | 单继承 CMilitaryAccessRelation, 只换 token |
| CDockingRightsRelation | 0x142A21928 | 15098 | 80 | 无 (rs 槽 +688/+696) |
| COfferDockingRightsRelation | 0x142A219E8 | 15099 | 80 | 单继承 CDockingRightsRelation |
| CAirBaseAccessRelation | 0x142A21738 | 10298 | 80 | 无 (rs 槽 +704/+712) |
| COfferAirBaseAccessRelation | 0x142A217F8 | 10325 | 80 | 单继承 CAirBaseAccessRelation |
| CLicenceProductionAccessRelation | 0x142960348 | 19331 | 80 | 无 (rs 槽 +728/+736) |
| CEmbargoRelation | 0x142960B60 | 12916 | 80 | 无 (方向落 rs+752/+760; Add 0x140D28480 含已 embargo 查重) |
| CBoostPartyPopularityRelation | 0x142960708 | 12525 | 88 | **+80 = CIdeology\*** (writer 0x140D2DA60 自有, 键 ideology=11838 = u32@(*(rel+80)+8); DB = 0x332EF38; rs 槽 +536/+544) |
| CImproveRelationsRelation | 0x142960588 | 11479 | 96 | +80 qword / +88 i32 (工厂 sub_140D1EE80 case 11479 定形态: +80 初 0 / +88 初 −1 哨兵; 无自有 writer/reader, 不序列化; 语义保留; rs 槽 +504/+512) |
| CAttacheRelation | 0x142960648 | 14553 | 136 | **+80 内嵌 CCommandPowerAllocator 56B** (ctor 0x1414E6F40 挂 qword_143334350 参数源; 不序列化; rs 槽 +520/+528) |

| NInternationalMarket::CEquipmentPurchaseRelation | 0x142A21BB8 | 13288 | 80 | 无 (rs 槽 +624/+632 成对; 槽[10] = ret0) |
| NInternationalMarket::CMarketAccessRightsRelation | 0x142A21C80 | 13696 | 80 | 无 (rs 单槽 +640; 槽[10] = ret1) |

**槽[10] 覆写分布 (定案)**: CRelation[10] = purecall (0x14253C3B8); 覆写为 ret1 (0x1401807B0) 的共 **3 类** —
CNonAggressionPactRelation / CMarketAccessRightsRelation / CWarRelation; 其余全族覆写为 ret0 (0x14011D220)。

同族顺带: CLendLeaseRelation (12618, 80B) / CSubjectRelation (12497, §4.10.7) / CWarRelation (14346, §4.10.4)。

#### 4.10.4 war 关系对象 (wr)

war 关系对象 (运行时 token@+8==14346 "war_relation"; writer sub_140D2DE80 先调基类); 基址 wr。

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
| +352 | int32 | hostility_reason_instigator 枚举 | ≠6 才写; ⚠ **+352=instigator / +348=defender** (writer 先读 +352) |
| +360 | idpair | first_wargoals 容器数据指针 — {d@+360, cap@+368, c@+372}, 元素 8B 紧致对 {type u32@+0, id u32@+4}, 非指针; 写形 `id=N type=T` 多重集 | c>0 (cap 槽已知) |
| +372 | u32 | first_wargoals 容器计数 | c>0 |
| +384 | idpair | second_wargoals 容器数据指针 — {d@+384, cap@+392, c@+396} 同上 | c>0 (cap 槽已知) |
| +396 | u32 | second_wargoals 容器计数 | c>0 |
| +408 | CWargoal* | wargoals 容器数据指针 — {d@+408, cap@+416, c@+420} (token 13085): CWargoal 指针, 动态 token@元+48 | c>0 (cap 槽已知) |
| +420 | u32 | wargoals 容器计数 | c>0 |
| +432 | MSVC 串 | **战争名串** ({data, cap@+456=15}; 形态定案/语义推定) | |

CWargoal 落盘槽 (wg 基址; 与上表 wr 异基):

| 偏移 (wg) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +120 | tag_id 容器数据 | puppets 容器数据 (4B tag id 元素; GER→BEL puppet_wargoal_focus 首例) | c>0 |
| +132 | u32 | puppets 容器计数 | c>0 |

CWargoal 元素细部 (元素基址 e; CWarGoal 全布局, vt 0x1429E0058; writer 0x1415E0C20 / reader 0x1415E08F0; inner 亚对象 @e+56; dtor 0x1415DE530 从每州反引表 {d@state+128, c@+140} swap-remove 摘除):

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

⚠ 元素门 = CState vt 精确匹配 0X2936CC0 且 id≠0 (尾槽 id=0 / 悬垂槽首 qword 恰落模块区间曾出垃圾 id 51112 — 模块范围门不够, 须精确 vt)。

#### 4.10.5 war_score 子对象 (ws)

war_score 子对象 (实名 **CWarScoreBreakdown**, vt 0x142960128; writer 0x14117B070 / reader 0x14117AD10): ws = wr+112 或 wr+224; vtable 槽1 = 0X14117B070。键 token: first=10462 / second=10463 / equipment_damage=14358 / province_capture=14359 / air_damage_str=13622 / strategic_air=12247 / sunk_ship=11928 / convoy_attack=11970 / casualties=13394 / lend_lease_sent=14483 / lend_lease_received=14484 / captured_provinces=12513。

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
| +64 | fixed×1e-5 | casualties (i64, 占 +64..+71; +72..+79 = 对齐填充) | 同上 |
| +80 | fixed×1e-5 | lend_lease_sent | 同上 |
| +88 | fixed×1e-5 | lend_lease_received | 同上 |
| +96 | std::map 头 | captured_provinces std::map 头 (节点 key u32@+28, **值不写 (set 语义)**; 中序 = 升序 = 存档序) | |
| +104 | u64 | captured_provinces std::map size | size≠0 |

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
| +80 | u8 | 自治关系旗 A (ctor 默认 1; set_autonomy 写 — 推定) | |
| +81 | u8 | 自治关系旗 B (ctor 默认 1; 与 +80 同元 0x0101 — 推定) | |
| +88 | CAutonomousState* | autonomy_state → MSVC 串@obj+8 引号 | ptr≠NULL; def 对象 (名 MSVC@obj+8) |
| +96 | fixed×1e-5 | value | **raw≠0 才写** |

#### 4.10.8 proposed 外交行动条目

proposed 外交行动条目 (40B; action token 10546 系)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | uint32 | index |
| +4 | pad | 对齐 (定案) |
| +8 | CGameDate vt | date 对象基 (定案; date 对象 24B) |
| +16 | hours | date |
| +24 | greg vt | date 对象子 vt |
| +32 | uint32 | action (token → 名) |
| +36 | pad | 对齐 (定案) |

#### 4.10.9 CCurrentAutonomyStatus

CCurrentAutonomyStatus (dip+848; writer 0X14067AA30)。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | fixed×1e-5 (i64) | progress (i64; AddAutonomyScore 钳 [+56-margin, margin++72]) |
| +16 | 匿名结构 (含 SSO) | path 容器数据指针 — {d@+16, cap@+24, c@+28, alloc@+32}; 元素 = 名 (SSO@+8); cap/alloc 新增 |
| +28 | u32 | path 容器计数 |
| +29..+39 | — | = path 容器 {d@16, cap@24, c@28, alloc@32} 的 count 尾 (29..31) + alloc@32 (pdx 24B) |
| +40 | CAutonomousState* | current_state; def 对象 — **GUI: 附庸关系条自治档位** (CSubjectRelationstripView 命中; loc AUTONOMY_RELATION_DESC/DESC2 + "GFX_\<level\>_icon" 图标链) |
| +48 | CAutonomousState* | prev_state; def 对象 |
| +56 | fixed×1e-5 (i64) | **progress 下界基 (min bound)** (getter 0X1406774A0) |
| +57..+63 | — | = progress 下界基 i64@56 的尾字节 (56..63 为一个 8B 定点) |
| +64 | CAutonomousState* | next_state (名 SSO@+8); def 对象 (名 SSO@+8) |
| +72 | fixed×1e-5 (i64) | **progress 上界基 (max bound)** (getter 0X140677390) |
| +73..+95 | — | = 上界基 i64@72 尾 (73..79) + qword@80 (ctor 未命名, 未序列化) + **last_change CGameDate {vt1@88, hours@96, vt2@104}** 头部 (writer 0X14067AA30 `ADEC0(a2,0x431D,a1+104)` 直证) |
| +96 | hours | last_change |
| +97..+111 | — | = last_change 日期 {hours@96 尾 97..99, pad 100..103, vt2@104..111} |
| +112 | 匿名结构 (64B) | effects 容器数据指针 — {d@+112, cap@+120, c@+124, alloc@+128}; 元素: value i64@+0 (raw 读法 = lo+hi×2^32 符号化, 勿转浮点 — Lua 5.4 `format("%d")` 崩), desc SSO@+8, hash u32@+40, hours@+56; cap/alloc 新增 |
| +124 | u32 | effects 容器计数 |

CAutonomousState def 侧补行 (def 库 = **0x332EE18** (qword_14332EE18, §4.26 autonomous_state key; 旧引 qword_14332EE18 在 1.19.3 无命中 = 1.19.2 残影已删); 形态 {data@+48, count@+60}; 条目 +40 hash / 名串 @+8..+24):

| 偏移 (def) | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +1544 | i64 | 自治等级 rank 权重 (×qword_1433339F8/100000 缩放) | 推定 |

#### 4.10.10 CPolitics (ps)

| 项 | 值 |
|---|---|
| 挂载点 | `*(cc+3984)` (ps) |
| RTTI 名 | CPoliticalStatus (§3.9) |
| vtable RVA | 0X294FDA8 |
| writer | — |
| loader | — |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CTimedStageCoupActivity* 向量 | **timed activities** (政治限时活动: 战目标辩护/政变/装备分发) {data@+8, cap@+16, count@+20, alloc@+24} — 元 = 动态 token@元+8 对象 (工厂 sub_140AD7DD0 产 CTimedStageCoupActivity 等) | writer 键 0x3408 |
| +32 | CPoliticalParty** | parties 容器数据指针 — {d@+32, cap@+40, c@+44, alloc@+48} | 元素见 §4.10.11 (cap/alloc 新增); GUI: 政党饼图源 (C2dPieChartTemplate; party+136 popularity 顶点 + 色 sub_1411A4780(party)+16) |
| +33..+43 | — | = parties 容器 {d@32, cap@40, c@44, alloc@48} 的 data 尾 (33..39) + **cap@40..43** (ctor 0X140BA6EF0) | |
| +44 | u32 | parties 容器计数 | 元素见 §4.10.11 |
| +45..+55 | — | = parties count@44 尾 (45..47) + **alloc@48..55** | |
| +56 | CIdea* 向量 | **可用理念缓存 CIdea\* 向量** {data@+56, cap@+64, count@+68, alloc@+72} (定案): AddParty 0X140BAE830 第二循环遍历 **CIdeaDatabase** (qword_14332EF30, ctor sub_140A3F6E0 vftable 直名) 填充, 元素门 `*(idea+56)` 旗与 CIdea ctor 0X140FCCEA0 同位互证; 同函数第一循环 = CIdeologyGroupDatabase → parties@ps+32; 不序列化 | GUI: 理念窗候选向量 = ps+80 ideas 与 ps+56 拼接 |
| +73..+79 | — | = 可用意识形态容器 {d@56, cap@64, c@68, alloc@72} 的 count 尾 (69..71) + **alloc@72** | |
| +80 | CIdea** | ideas 容器数据指针 — {d@+80, cap@+88, c@+92, alloc@+96} (定案) | cap/alloc 新增; GUI: 理念窗 (CPoliticalIdeasWindow: 候选向量 = 本表 + ps+56 拼接; SetTarget sub_141582ED0 assert politicalideaswindow.cpp; 宿主 CCountryPoliticsView+31296) **+ 可选理念装备判定** (CPoliticalSelectableIdeaItem) **+ 精神窗** (CSpiritItemWindow) |
| +92 | u32 | ideas 容器计数 | |
| +104 | 匿名结构 (24B 形状) 向量 | **timed_ideas** {d@+104, cap@+112, c@+116, alloc@+120} 24B 条 = **CTimedIdea** {vt, CIdea*@+8 (名=token@idea+8), days u32@+16} (定案; writer 键 13420; "Invalid timed idea in savegame" 互证; 类级卡 §4.8.12) | cap@+112 新增 |
| +121..+127 | — | = timed_ideas 容器 {d@104, cap@112, c@116, alloc@120} 的 **alloc@120 尾字节** (117..119 count 尾 + 120..127 alloc) | |
| +128 | CIdeology 向量 | **per-ideology-group {lead ideology, group} 条目向量** {data@+128, cap@+136, count@+140, alloc@+144} — 8B 元 → 16B 结构 {CIdeology* lead, CIdeologyGroup* group} (AddParty 尾按组数扩容 malloc(0x10) 填; 消费 0X140BA92B0: `ps+128[*(group+92)-1]` 取元, lead 有效则跨组内成员累加 popularity = **组内意识形态 popularity 聚合/boost 数据**) | 定案 |
| +145..+151 | — | = per-ideology-group 容器 {d@128, cap@136, c@140, alloc@144} 的 count 尾 (141..143) + **alloc@144** | |
| +152 | CGregorianDate 24B | **last_election** {vt@+152, hours@+160, greg vt@+168} (writer 键 0x2BDD; 定案 — 书内 i32@+160 互证) | |
| +169..+175 | — | = last_election CGameDate {vt@152, hours@160, greg vt@168} 的 **vt2@168 尾字节** | |
| +176 | CGregorianDate 24B | **next_election** {vt@+176, hours@+184, greg vt@+192} (SetPolitics 推进; 高置信) | **GUI: 选举行** (门 = ps+236 elections_allowed && ps+232 election_frequency>0 → `elections` 显隐 + 日期; POLITICS_NEXT_ELECTION / POLITICS_NOELECTIONS) |
| +193..+199 | — | = next_election CGameDate {vt@176, hours@184, greg vt@192} 的 **vt2@192 尾字节** | |
| +200 | CCountry* | **属主国回指** (AddPoliticalPower 打印国名, politics.cpp:1623) | |
| +201..+207 | — | = **属主国回指 CCountry\*@+200** 尾 7B (ctor `*(+200)=a2`) | |
| +208 | CPoliticalParty* | ruling_party 指针 (定案) | **GUI: 执政党块** (sub_1415F5960: sub_1411A3300 → leader 名 sub_140FCB280 / 像 sub_140B47270 → leader_name / leader_portrait; 无 → GFX_leader_unknown) |
| +209..+223 | — | = ruling_party 指针@+208 尾 7B (209..215) + qword@216 (ctor 置 0, 语义未名) | |
| +224 | fixed×1e-5 | political_power | |
| +232 | uint32 | election_frequency | |
| +236 | uint8 | elections_allowed | |
| +237 | u8 | **parties 脏旗** (AddParty 尾置 1) | 高置信 |
| +240 | 匿名结构 (16B map/set) | 未名 16B map/set (dtor `sub_140150FB0(Block+30)` 树析构; politics.cpp 内无使用者, writer/parse 均不触) | 形态定案/语义待裁 |
| +256 | boost::shared_ptr | **PP 变动通知器** (AddPoliticalPower/SetPoliticalPower 尾调 sub_14032F840; 形态定案/语义推定) | ⚠ MIO 实例挂在 CPolitics 下经本槽 (cc+3984→+256 listenable 枚举源; COrganisationListWindow 命中); 与 PP 通知器双说并存 — 或即同一 listenable 机制的两种消费 (未证 — 未决) |
| +920 | 指针容器 24B | 未名对象指针容器 {data@+920, cap@+928, count@+932, alloc@+936} — 8B 堆对象指针元; 全量国家 440/451 非空 (单国 5..831 条) | 语义待裁 |
| +944 | 指针容器 24B | 未名对象指针容器 {data@+944, cap@+952, count@+956, alloc@+960} — 8B 堆对象指针元; 单国量级 5..15 条 | 语义待裁 |
| +3672 | 动态修正管理器* | 动态修正管理器挂载; 条目 64B 与 SDynamicModifierEntry (§4.13.4) 同构 | 推定 |
| — | ⚠ | **dip = `*(cc+3976)` / ps = `*(cc+3984)` 相邻 8B 两对象, 勿混** — 二者各持同名族容器且偏移仅差 8 (如双方各有 docking-rights 四元组), 取错基址会读到另一对象的容器 | 陷阱 |

> **理念过期通知接缝**: `politics.daily` 的 `sub_140BA8300` (断言串 `politics.cpp` + `"politics.daily"`) 在理念过期时
> `malloc(0x5A8)` + ctor `sub_14192F2E0` 建 `NNotification::CIdeaExpiredNotification` 并经
> `sub_141391400(iface+1240, obj)` 入队 (详见 §4.17.4); 同段紧邻 `*(v54+1204)` = 接口处理器 +1192 历史容器 count
> (216B 记录, tag=12)。

CIdea (理念 def; 库 = CIdeaDatabase qword_14332EF30) 布局补行:

| 偏移 (def) | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +2816 | token 容器数据 | 特质 token 表; 计数 @+2828 (has_idea_with_trait / remove_ideas_with_trait 消费) | 推定 |

#### 4.10.11 CPoliticalParty (party 条目)

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | ideology (token) |
| +9..+15 | — | = ideology token@+8 尾 7B |
| +16 | CCountry* | **属主国指针** (ctor a2; 高置信) |
| +24 | CIdeologyGroup* | **所属意识形态组** (ctor a3; GetParty 比对; **GUI: 意识形态图标/名** — sub_140B48C70 / 140B376B0 / 140616BC0: +8 组 id → ideology_ico / ideology_name / party_name) |
| +32 | u32 | **属主国 idx** (ctor tag idx) |
| +33..+39 | — | = 属主国 idx u32@+32 尾 7B |
| +40 | string (SSO) | name |
| +41..+71 | — | = name SSO 32B 本体 (buf@40 尾 + size@+56 + cap@+64=15; 标准 MSVC 串) |
| +72 | string (SSO) | long_name |
| +73..+103 | — | = long_name SSO 32B 本体 |
| +104 | uint8 | default_flag |
| +112 | 匿名结构 (leader 条目) | country_leaders 容器数据指针 — {d@+112, cap@+120, c@+124, alloc@+128}; 元素: char id 对 = `((e+8)+8)` {type lo, id hi}, **subideology = *(CIdeology\*)@(e+320)** (名串 @CIdeology+16; 高置信); cap/alloc 新增; **GUI: ideology_ico 有领袖分支引用门** (party+112 引用槽 + party+124 有效门 → CCountryLeader → sub_140B48C70 取其 +16 SSO 名拼 `GFX_ideology_<名>[_<TAG>]`) |
| +124 | u32 | country_leaders 容器计数 (= "leader_count" 别名; writer 以 *(a1+124) 为循环上界) |
| +125..+135 | — | = country_leaders 容器 {d@112, cap@120, c@124, alloc@128} 的 count@124 尾 (125..127) + **alloc@128..135** |
| +136 | fixed×1e-5 | popularity — **GUI: 政党饼图顶点值** (political_pie_chart; Σ=1e7 归一; GER 十党实测) |
| +144 | 内嵌 CRule | **党派规则覆写对象** (ctor 装 CRule vt; SetPartyRule 0X1411A3630; 内含 28 槽 ×32B 串数组 @对象+120, 与 rs rule_overrides 同族; 形态定案) |

#### 4.10.12 CIdeology / CIdeologyGroup (意识形态 def 与组对象)

**CIdeology** (意识形态 def, 320B; ctor 0X141190B80; 库 = CIdeologyDatabase qword_14332EF38):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt | — |
| +16 | MSVC 串 | name |
| +48 | i32 | id (−1) |
| +64 | CModifier 192B | modifier (定案: +64..+255) |
| +256 | CColor | color (16B 内嵌投影, 见 §4.00.10) |
| +288 | — | = sub_141191580 |

**CIdeologyGroup** (组对象; party+24 所指, 每党一独立组时各自成组; vt 0X14293B020,
ctor sub_141190D90; 库 = CIdeologyGroupDatabase qword_143330DB8)。下表偏移相对**组对象自身**;
fac 侧落点 (fac+96/+1120/+1152/+1344) 见 §4.5.7。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | token id | **组名 token** (CPersistentWithToken 基座; 基 ctor 先置 357=none, 本类 ctor 覆写 = a2) |
| +20 | token id | **组名 token** (ctor 同参 a2 双写, 与 +8 同命名空间同值 — 定案) |
| +24 | SSO 串 | 组名串 = token_name(a2) |
| +64 | int32 | 装载序 (ctor −1; 装载后循环赋 0..n) |
| +1536 | u32 | **`<ideology>_drift` 的 modifier def 索引** (该意识形态每日支持率变化; 探针 totalist=844 … national_populist=871) |
| +1544 | u32 | **`<ideology>_drift_from_guarantees` 的 modifier def 索引** (846/849/852/855/858/861/864/867/870/873) |
| +1589 | u8 | 执政党组旗 (compare_ideology_with_faction 短路返 1; 名未名, 推定) |

两索引 = GetPopularityTooltip 的取值来源 (def 名 = 游戏内 `GAME.layout.modifier_token(idx)` 反查 + KR loc); drift 分档缩放见 §4.10.15。

#### 4.10.13 CDiplomaticAction 基类布局 (sizeof 120)

基构造 sub_1410F9CB0 直读; 装写 CDiplomaticAction::vftable; 装填循环 sub_1412ED0E0; 设值器 sub_14113F980。assert diplomaticaction.cpp:0x62D (SetActor) / .h:0x1FC 同文案 `_Actor … _Recipient … CanTargetSelf`。基类 writer/reader 真体 = sub_141141470 / sub_14113E7A0 (派生类槽 [2]/[4] 常见 thunk 直通)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | 动作 token | 定案; ctor sub_141140020 装载并同刻解 db 条目入 +88/+96 |
| +16 | u8 | initiator_matters (writer 恒写 yes, 键 0x3365) | 定案; ctor 以 dword 清零 +16..+19 |
| +17..+19 | u8×3 | 伴随布尔 (未序列化) | 定案 |
| +20 | uint32 | actor (键 0x292E; ctor *a2 双写 +20/+24) | 定案; 设值器 sub_14113F980 写 +20; 宣战面板 +20 = 我方 |
| +24 | uint32 | original_actor (键 0x2FCF) | 定案; 执行器控制权交 +24 |
| +28 | uint32 | recipient (键 0x292F; ctor *a3 双写 +28/+32) | 定案; assert 同函数读 a1[7] = +28; 宣战面板 +28 = 对方 |
| +32 | uint32 | original_recipient (键 0x2FD0) | 定案 |
| +40 | CGameDate 24B | date {vt1@+40, hours@+48, vt2@+56} (键 0x284A, 经 vt2 代理; §3.7a 通用形态) | 定案 |
| +64 | CGameDate 24B | last_command_date {vt1@+64, hours@+72, vt2@+80} (键 0x2A2B, 经 vt2 代理) | 定案 |
| +88 | TGameItemDatabase 条目* | on_action 动作库条目 (qword_14332EFA0; 键 0x34D8, 条目+24 置位才写) | 定案; 查找 sub_140A79050 |
| +96 | void* | 第二 db 查找产物 (sub_1406B4F60) | 定案; 未序列化 |
| +104 | int32 | type 动作型别 (键 0xE1) | 定案 |
| +108 | int32 | envoy 经办 id (键 0x2AD3; ctor 缺省 -1) | 定案 |
| +112 | u8 | human 人控标记 (键 0x2B76, 置位才写) | 定案 |
| +113 | u8 | value 通用布尔 (键 0x308) | 定案 |
| +114 | u8 | 尾旗 (未序列化) | 定案 |

writer 落盘序: human? → type → actor → original_actor → recipient → original_recipient → date → value=yes → last_command_date → envoy → initiator_matters=yes → on_action?; reader 按 token 分发回各槽。

CScriptedDiplomaticAction (sizeof 0x80, def@+120) 为首族; CNavalBlockadeAction 见 §4.31.39。

主表 67 槽行为语义 (全族 14 类共享骨架; 未列槽 = 基共享样版/常量桩):

| 槽 | 语义 | 置信 |
|---|---|---|
| [23] | GetName (每类唯一; 按 +113 value 二分出 `DIPLOMACY_X` / `DIPLOMACY_REVOKE_X` loc) | 定案 |
| [24] | Clone (每类唯一; malloc(sizeof) 逐字段拷 — sizeof 实证源) | 定案 |
| [25] | 可执行/目标谓词 (分组变体: Docking/AirBase 四元组 = `+113 && !+104`; MilAccess/NAP 对 = `+113`; Ask/Give = `+104==0`; 其余常 0) | 高置信 |
| [26] | ResolveType (仅 Mil/OfferMil/Docking/OfferDocking/AirBase/OfferAirBase 6 类: 目标已挂 offer 关系则 +8 改写对方型 token 并同步 +88/+96 def — offer↔正式 动态换型机制本体; 例 0x1411410B0) | 定案 |
| [34] | thunk→槽[25] (uniform 0x141103020) | 定案 |
| [37] | CanExecute + 拒绝原因 loc 串 (每类唯一) | 高置信 |
| [56] | Apply 副作用 (DeclareWar 0x141105A00 = 开战本体; Guarantee 0x1411074B0 = 威胁度结算; Docking/Offer/Mil/OfferMil 共享 0x141108920; 其余 = CFG 空桩) | 高置信 |
| [64] | **AI 决策主体 (每派生类唯一大函数)** — 基类为未实现桩 0x1411186D0 (4 行 + 断言 `"You should have implemented me in derived class!"` diplomaticaction.cpp:1655); 派生覆写体含决策 loc 族 (CAskForStateControlAction `DR_HAS_CORE_ON_ANY_STATE`/`DR_NOT_CONTROLING_ENOUGH_TERRITORY`/`DR_NO_PARTICIPATION`; COfferMilitaryAccessAction `DR_THEM_PUPPET`/`DR_IDEOLOGICAL_ACCEPTANCE`; CSendAttacheAction `DR_ATTACHE`/`DR_STRATEGIC_HOSTILITY` 等) | 定案 (槽形) / 高置信 (语义) |
| [65] | **AI 意愿/接受度组装入口** `sub_14110DC10(a1, a2, a3)` — 依次装配 loc `DR_AI_CHEAT` / `DR_AI_UNABLE_TO_ACCEPT` / `DR_BASE_RELUCTANCE` 后尾转 vt[35] 0x1410FFB40 (遍历关系数组按 flag/值累加 100000 基数算 score); 30 类共享此实现 | 定案 |

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

族形态: 全族主虚表 19 槽零功能覆写 (唯一差异槽 [0] dtor); CFilterItem 基槽0 = purecall (抽象); 类特异行为全在 ctor + 副虚表 CTooltipHandler 槽0 (tooltip 构建器, 每类真覆写) + 非虚 setter。

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
| sub_1415EF2C0 | CFilterTokenItem | CIdeologyGroup 库 qword_143330DB8+96 数组驱动 (token=def+20) | 1 | +3912 |
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
| dip+400 | u32 数组数据 | governments_in_exile_we_host — u32 tag id 元 → 引号 tag 列表 (writer 0X140D47400 逐元素 BA5C20; 定案) |  |
| dip+412 | u32 | gov_in_exile_we_host 容器计数 |  |
| dip+424 | uint32 | hosting tid (流亡政府接收国) |  |
| dip+432 | fixed×1e-5 | legitimacy |  |
| dip+696 | hours | last_surrender_date | 哨兵 43808760 不写 |
| dip+736 | uint8 | capitulated |  |
| dip+752 | hours | capitulated_date | 哨兵 43808760 不写 |
| cc+2488 区 | uint32 | government_in_exile_tag | +2488>0 时 140BA5C20(+2488) → tag |
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

ctor sub_1410DCD10 / 执行 sub_1410DDFE0 (1600+ 行, 执行体未展开)。由 start_civil_war 卡构建 (§4.32)。

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +8 | u32 | target 国 id | 推定 |
| +16 | CIdeologyGroup* | 意识形态组 A | 推定 |
| +24 | CIdeologyGroup* | 意识形态组 B | 推定 |
| +32 | u16 | 样式字 (ctor = 0x0101) | 推定 |
| +34 | u8 | 样式字节 (ctor = 1) | 推定 |
| +40 | fixed×1e-5 | ratio #1 (钳 [0, 100000] 脚本值) | 推定 |
| +48 | fixed×1e-5 | ratio #2 | 推定 |
| +56 | fixed×1e-5 | ratio #3 | 推定 |
| +64 | fixed×1e-5 | ratio #4 | 推定 |
| +72 | int32 | mode (4 = army size / 3 = 谓词收集 states) | 推定 |
| +80 | MSVC 串 | states 串 | 推定 |
| +104 | int32 | army_size (mode=4 时载入) | 推定 |
| +112 | 匿名结构 (元素待裁) 向量 | 角色 id 数组 (三源汇入) | 推定 |
| +120 | 匿名结构 (元素待裁) 向量 | 角色 id 数组 尾/第二槽 | 推定 |
| +128 | — | 尾槽 (ctor 布局, 语义未名) | 推定 |

#### 4.10.21 CNavalBlockadeAction (海上封锁动作, vt 0x142A36AF0)

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

| 控制器 | vt | +32 token | 布局摘要 | 对应 Action 类 (vt) |
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
| CDiplomacyLendLeaseActionController | 0x142A5C860 | 0x314A lend_lease | 富壳 ~9160B: 3×button glue + 4×observer 块 + 内嵌 lend_lease_equipment_window | CLendLeaseAction (0x1429AB588) |
| CDiplomacyNavalBlockadeActionController | 0x142A5DC80 | 0x27F8 naval_blockade | 纯 5 写壳 40B | CNavalBlockadeAction (0x142A36AF0) §4.31.39 |
| CDiplomacyRequestExpeditionaryForcesController | 0x142A5D528 | 0x3421 request_expeditionary_forces | 基类 40 + 内嵌 scrollbar glue | CRequestPuppetForcesAction (0x14298D848) |
| CDiplomacyRequestLicensedProductionController | 0x142A5DBD0 | 0x37BF request_licensed_production | 基类 40 + 3×button glue | CRequestLicensedProductionAction (0x14298EB68) |
| CDiplomacySendAttacheActionController | 0x142A5D018 | 0x38D9 send_attache | 纯 5 写壳 40B | CSendAttacheAction (0x14298CD60) |
| CDiplomacySendExpeditionaryForceController | 0x142A5D2F8 | 0x33FE send_expeditionary_force | MI: +40 次基 CSendUnitsGroupController (mdisp 40) | CSendExpeditionaryForceAction (0x14298D408) |
| CDiplomacySendVolunteersController | 0x142A5D428 | 0x3415 send_volunteers | 同上 MI 形态 | CSendVolunteerAction (0x14298D1E8) |
| CDiplomacyStageCoupController | 0x142A5D758 | 0x346F stage_coup | 基类 40 + 3×button glue | CStageCoupAction (0x14298DC88) |


#### 4.10.23 外交动作·租借/许可/人力/政变族 (CDiplomaticAction 子类)

**CLendLeaseBaseAction** (租借数据基座, 328B; vt 0x1429D1128; writer 0x1415047D0 = 基 writer + 5 键 / reader 0x141504380): +120 i64 fuel_daily (14674, %lld 原值) / +128 i64 fuel_percentage (15308) / +136 CEquipmentVariantPool 64B equipment (12110) / +200 同形 production_percentage (13307) / +264 同形 once (10346)。**CLendLeaseAction** (vt 0x1429AB588; +8 = 12618 lend_lease; 布局与基逐字节全等, 零新增)。**CIncomingLendLeaseAction** (360B; vt 0x1429D1358; +8 = 14027 incoming_lend_lease): +328 archetype 表 (12103, 8B 元 = archetype def*) / +352 u8 fuel_requested (15298); writer 0x1415046F0 / reader 0x1415040C0。CEquipmentVariantPool 元素 = 16B {variant 指针@0, amount i64×1e-5@+8}, 落盘形 `equipment={ id=<token@元+8> amount=<fixed> }`, 零值元仅 allow_zero_entries(+56) 置位时写。

**CRequestLicensedProductionAction** (176B 推定; vt 0x14298EB68; +8 = 14271; writer 0x1411416C0 / reader 0x14113F040): +120 start 变体表 (105, 8B 元 = CVariant*) / +144 cancel 变体表 (10469) / +168 u8 request_access_to_licence_production 旗 (19353)。**CRequestForeignManpowerAction** (vt 0x14298EFA8; +8 = 19135): +120 u32 manpower (10300); writer 0x141141690 / reader 0x14113F020。**CRequestPuppetForcesAction** (vt 0x14298D848; +8 = 13345 request_expeditionary_forces): +120 u32 division (471); writer 0x1411417A0 / reader 0x14113F2D0。**CStageCoupAction** (vt 0x14298DC88; +8 = 13423; writer 0x141141900 / reader 0x14113F480): +120 CState* location (10349, 写 = *(state+88)) / +128 CIdeology* ideology (11838, 写 = token@ideology+8, 门 = *(ideology+16))。

零载荷名录 (纯基 writer/reader 直通; ctor 仅装 +8 token):

| 类 | vt | token |
|---|---|---|
| CCancelLicensedProductionAction | 0x14298ED88 | 14272 cancel_licensed_production |
| CCancelAccessToLicenseProductionAction | 0x14298E948 | 19348 cancel_access_to_licence_production |
| CRequestAccessToLicenseProductionAction | 0x14298E728 | 19353 request_access_to_licence_production (token id 复用: 本类 +8 作动作 token, CRequestLicensedProductionAction +168 作载荷旗键 — 两类各装自身 vftable, 双入口并存为设计如此) |
| CCancelForeignManpowerAction | 0x14298F1C8 | 19136 cancel_foreign_manpower |
| CReturnAllExpeditionaryForcesAction | 0x14298D628 | 13334 return_expeditionary_forces |
| CSendAttacheAction | 0x14298CD60 | 14553 send_attache (ctor 直置 +16 initiator_matters=1) |
| CIncreaseAutonomyAction | 0x14298E508 | 14079 increase_autonomy |
| CReduceAutonomyAction | 0x14298E2E8 | 14078 reduce_autonomy |

**CIncomingDiplomaticActionStatus** (40B; vt 0x1429D2768; writer 0x1415148A0 / reader 0x141513BB0): +8 pending 容器 {d@+8, c@+20} 8B 元 = CIncomingDiplomaticAction*; 元素 (32B, vt 0x142A376E0; writer 0x141AA6F30 / reader 0x141AA6E40) = {vt, +8 null 对象, +16 u8, +24 内嵌动作指针 (写经 0x141141270)}; 逐元 N={...} 下标块落盘 — 国级「待处理外交动作」收件箱的持久化状态。


#### 4.10.24 AI 态度族 (CAIAttitude 基 + 8 变体)

对象 48B (工厂 sub_140636FB0 逐例 malloc 0x30); 变体间**零字段差异**, 差异只在行为槽。+8 u32 态度 id / +16 std::string 32B 内部名串 ("attitude_<名>"; rs+792 写名串经此复原指针, 键 11737)。全族 18 槽主虚表: [1]/[3] CPersistent wrapper / [2] = CFG 空桩 (对象自身零写出) / [4] 基共享 reader / **[9] = 候选门** (rs 重算 sub_140D19E10 遍历 `(vt+72)(att)` 为真才评分) / [10..16] 布尔谓词语义待裁 / **[17] = 态度评分函数** (签 `(this, out*, tag_dip*, scope*)`, 逐变体数百行大函数)。

| 类 | vt | id | slot9..16 矩阵 (ret1/ret0) | slot[17] 评分 |
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

**Action 族** (CDiplomaticAction 派生, 主虚表 67 槽全族同形; sizeof 来源 = clone 槽 [24] 的 malloc 实参):

| 类 | vt | sizeof | +8 token | ctor | writer / reader | 扩展字段 |
|---|---|---|---|---|---|---|
| NFactions::CAssumeFactionLeadershipAction | 0x1429E2518 | 120 | 15097 assume_faction_leadership | 0x1415FFE70 | 基类直通 0x141141470 / 0x14113E7A0 | 无 (零扩展) |
| NFactions::CCreateFactionAction | 0x1429E2738 | 152 | 12659 create_faction | 0x1415FFFA0 | 0x141617A30 / 0x1416178C0 | +120 std::string 32B = 阵营名 (键 27 name) |
| NFactions::CJoinFactionAction | 0x1429E2958 | 128 | 12243 join_faction | 0x141600240 | 基类直通 | +120 u8 (不序列化, AI 瞬态旗) |
| NFactions::COfferJoinFactionAction | 0x1429E2B78 | 136 | 12244 offer_join_faction | 0x1416005D0 | 0x141617A80 / 0x1416178F0 | +120 u8 (键 10260 confirm) / +124 i32 war_with tag (键 10800, 门 >0) / +128 u8 (不序列化) |
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
| +256 | +136 | i64 | 补贴 CIC 总额 |
| +264 | +144 | 匿名结构 (48B 形状) 向量 | subsidies {data@264, count@276} |
| +288 | +168 | uint32 | speed |
| +296 | +176 | std::map 头 | price_levels (节点 key = CEquipmentVariant idpair 8B) |
| +312 | +192 | u8 | 懒计算完成标志 |
| +320 | +200 | i64 (fixed×1e-5) | 补贴抵扣 |
| +328 | +208 | i64 (fixed×1e-5) | 合同总 CIC 价 |
| +336 | — | CIdentifier 8B | **本类独有**: request 变体引用 (键 12613; writer 门 = 两 u32 任一非 0 且 sub_14221F310 可解析) |

> 载荷落盘序 = def 写序 (§4.23.3: contract_draft → price_levels → prices) → request; 内嵌 def 与合同/requests 元素共用 writer sub_140DF1EC0。

**关系对象族补 2 类** (CRelation 派生, 主虚表 23 槽):

| 类 | vt | token | sizeof | 工厂分支 | rs 活动槽 | 槽差异 (相对 CRelation) |
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

| 类 | vt | ctor | 宿主 | 要点 |
|---|---|---|---|---|
| NFactions::CFactionProgramStatus | 0x1429661B8 | 0x140D88890 | CFaction+1992 (内嵌) | 向量 = `CPdxHybridInlineBufferAllocator<CRef<NProject::CProgram>,4,int>`; 元素 8B CRef 双 u32 对; +8 data / +16 count / +20 cap / +24 内联 allocator 指针 (内联区 +32, 容 4) / +64 = &off_143085170 |
| NFactions::CFactionRuleStatus | 0x142A22AF8 | 0x141994640 | CFaction+1392 (内嵌 176B) | +8 宿主回指; 三段同构块 (rule / goal / program) 各 32B: 块内 +8 qword 0 / +16 u8 置位旗 / +20 f32 0.9 阈值; 第 2/3 段基 = +120 (&unk_143085A80) / +152 (&unk_143085D70) |
| NFactions::CDoctrineSharingStatus | 0x1429BDD30 | — | CFactionUpgradeStatus+120 | +128/+136 两 qword (0) + 三处 off_143085170 共享空缓冲 (+144/+168) → 三个容器; +176 = 宿主回指 |
| NFactions::CTechnologySharingFaction | 0x142A4EC20 | 0x141BE6070 | CFactionUpgradeStatus+40 (内嵌) | 基类 CTechnologySharing (vt 挂 +0, +8 = 357 `none`); 本类仅换 vt, 零新字段 |
| NFactions::CFactionUpgradeStatus | 0x1429BDD80 | 0x1413F9DF0 | CFaction+2104 | +40 = CTechnologySharingFaction 内嵌 / +120 = CDoctrineSharingStatus 内嵌 |

**CDiplomaticAction 基类三契约槽** (来向动作应答器 = CAIForeignMinister::Hourly → `sub_1412EF660`):

| 槽 | vt 偏移 | 语义 | 覆写情况 |
|---|---|---|---|
| [25] | +200 | **待决/可决谓词** (pending): 假 → 直接跳过 (不产 acting command) | 8 个分组变体 (见下) |
| [29] | +232 | **保留槽**: 52 派生类零覆写, base = ret 0 → 本 build 恒假; 「WillAIAccept」实际由自由函数完成 | 零覆写 |
| [33] | +264 | **IsAutoAccept** (脚本/规则强制自动接受) | 仅 5 类覆写 |
| [34] | +272 | thunk→[25] (uniform 0x141103020) | 5 类改 ret0 短路 |
| [37] | +296 | CanExecute — 应答器末端二次复核 | — |
| [39] | +312 | **AI 接受分阈值判定**, base 0x141100520 = `return score >= dword_143337560` | 52 类零覆写 |

> **WillAIAccept 实际路径 (定案)**: `sub_140B37CF0(action)` = `vt[39](action, sub_14110A890(action, &原因串表, 0, 0))`
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

**[38] = 该动作声明的关系型 token** (vt+304; 52 派生类中 37 覆写、仅 10 个唯一实现;
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
| 6 | 0x1415FFFA0 | CCreateFactionAction | 恒 (尾部分值 `100000 × qword_143333BF8 × sub_1411178A0(action) / 100000`) |

> 分值统一 = `100000 × sub_1411178A0(action, 0/1)` (`sub_1411178A0` = 取 vt[64] AI 决策分);
> CCreateFactionAction 额外乘全局 `qword_143333BF8`。前置门 = 本国 `dip+656 CFaction*` 非空 ∧
> `faction+88 members[0]` id 对匹配 (只有领袖国才走本通道)。
> 第三条通道 = 市场合同 (GUI 草稿窗 + AI 直接构造 sub_14119AE70 / sub_141B95250), 不经 StartAction。

#### 4.10.26 和会管理器 (CPeaceConferenceManager, 内嵌 @gs+1248)

| 项 | 值 | 语义 |
|---|---|---|
| peace_conference | pc = gs+1248 (内嵌 CPeaceConferenceManager, vt 0X2720E48; gs+1624 = 选择组容器, 非和会; CGameState ctor 0X1401BFD30 `a1[156]=vt` 直证; Reset 0X140BBE710; writer 槽2 0X140BBF150) | 会议/决议池/分数树; SCHEMA 结构见 objects 层 SCHEMA_COUNTRY/STATE |

**CPeaceConferenceManager** (内嵌 @gs+1248):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | — | vtable (0X2720E48) |
| +8 | 容器 24B | active_peace 会议指针数组 {d@8, cap@16, c@20, alloc@24} (CPeaceConference*; writer 逐元素 ADEC0, 键 13632 = active_peace) |
| +32 | CString sso | 管理器名 (runtime-only) |


**清偿批补注（和会结算链定案）**: 玩家 tag 主选 = `dword[gs+1312]` 非零否则 `dword[gs+1316]`（⚠ 旧行文「+328>0 时取 +1316」方向反——328 是 1312 的 dword 下标，1312 为主选分支）。CDone(13830) = conf+472/+456 双树落账 → **sub_140E45FB0 结束流程**: 回合推进（清 440/488/456）→ 竞标落账（成员 +76 累加）→ 终局 0x141041BB0（PEACE_CONFERENCE_CALCULATING + 逐对象终结 + UI 终交接）；无脚本 on_action。CPass(12566) Execute = thunk 直转同函数。

conf+216..520 区字段巡礼:

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +216 | u32 | 回合计数 | 定案 |
| +220 | u8 | 本机已表态旗（玩家 tag ∉ 456 树） | 定案 |
| +221 | u8 | completed | 定案 |
| +224..240 | CPeaceWinnerAi* 向量 | CPeaceWinnerAi scoped {data@224, count@236} | 定案 |
| +248..264 | 匿名结构 (元素待裁) 向量 | 谈判方成员表（元素=国对象指针，+8 取 tag） | 定案 |
| +272..284 | 匿名结构 (元素待裁) 向量 | 第二对象数组（两轮终结处理） | 高置信 |
| +296 | 向量 | scoped 对象数组（终局逐元素虚槽[0]） | 高置信 |
| +320 | 向量 | scoped 对象数组（终局逐元素虚槽[0]） | 高置信 |
| +344 | 向量 | scoped 对象数组（终局逐元素虚槽[0]） | 高置信 |
| +368 | 门旗 | 竞标落账门（非零跳过 +76 累加） | 定案 |
| +416 | 容器 | 回合推进清空区 | 定案 |
| +440 | 树 | 回合推进清空区 树 {head@+440, size@+448} | 定案 |
| +448 | — | = +440 树的 size 字段 | 定案 |
| +456 | 树 | 本回合已表态表（set\<tag\>，节点 32B 键@+28） | 定案 |
| +472 | 树 | 完成表（Done 落账；3A9E0 全员判定）; conf+480 非零时 conf writer 以键 12813 `done` 落盘 (节点+28 tag → 串值) | 定案 |
| +488 | 树 | 已结束回合竞标快照归档 {head@+488, size@+496}（EndTurn 写 46260；查 470B0；退出清理 40C80） | 定案 |
| +496 | — | = +488 树的 size 字段 | 定案 |
| +504 | 树 | 与 488 配对的回合态树（414E0 查询） | 高置信 |
| +520 | u32 | 40C80 清理步清零计数 | 高置信 |

#### 4.10.27 CPeaceConference (active_peace 元素)

**CPeaceConference** (vt 0X2950E58; ctor 0X140BBDB70; writer 槽2 0X140E527D0; Start 0X140E4F240, 断言 MainLoser/MainWinner.IsValid peaceconference.cpp:0x295/0x296)。下表 = writer 全解码 + UI 消费对照; token 已直名; 行序 = 偏移升序, writer 键序 = 落盘序 (以 writer token / 存档键列承载):

| 偏移 | 类型 | writer token | 存档键 | UI 消费 (函数) | 语义 | 置信 |
|---|---|---|---|---|---|---|
| +8 | qword idpair | — (CReferenceObject 胶水) | — | sub_141E584E0 直读 → popup+5248; Reload 回写 win+20744 | conf 自身 refid | 定案 |
| +24 | u32 | 0x32DB (13019) | peace_conference_name_state_id | — | 会议目标州 id | 定案 |
| +28 | u32 | 0x2EFD (12029) | winner_scope | — | 获胜方 scope | 定案 |
| +32 | u32 | 0x2EFE (12030) | loser_scope | — | 战败方 scope | 定案 |
| +40 | i64 fix5 | 0x296B (10603) | factor | — | 初始分数/点数池 (ctor = 100000) | 定案 |
| +48 | u32 | — (writer 未写) | — | Start 分数初始化链 sub_140E500B0 写 (断言 WinnersTotalScore>0) | = Σ winner 条目 +72 original_score (逐 winner 累加) | 定案 |
| +52 | u32 | 0x292E (10542) | actor | Start 断言 0x295 直读 +52 | = MainLoser, 主战败侧 tag | 定案 |
| +56 | u32 | 0x292F (10543) | recipient | Start 断言 0x296 | = MainWinner, 主战胜侧 tag | 定案 |
| +60 | u8 | — (writer 未写) | — | FinalizeAnnounce 0x140E42B50 读, 喂占领/驻军回退门 | 战败方单位处理旗 (OutWinners≤1 ∧ OutLosers>1 ∧ +180 非空 ∧ loser∉+168 时清零) | 推定 |
| +64..+95 | SSO | 0xDD (221) | message | — | 会议消息串 | 定案 |
| +96 | 容器 24B {d@96, c@+108} | — (不序列化) | — | sub_1401B0250 线性 contains | = OutWinners u32 tag 数组 (sub_140E40640 断言实名) | 定案 |
| +120 | 容器 24B | — | — | sub_1401B0250 线性 contains | = OutLosers u32 tag 数组 (同上断言实名) | 定案 |
| +144 | {d@144, c@+156} u32 表 | 0x3AF6 (15094) | occupied_winners | — | 占领获胜方 tag 表 | 定案 |
| +168 | 容器 24B {data@168, cap@176, count@180} | — (writer/reader 双向不碰) | — | 唯一读者 FinalizeAnnounce 0x140E42B50 二分成员查 (按国 idx 序) | 有序 tag 表 — 纯运行时空表兜底 (ctor 空表, 填充点未找到; 若恒空则清零条件由前三项决定) | 待裁 |
| +192 | {d@192, c@+204} | 0x2F66 (12134) | civil_war_losers | — | map: tag → 串 | 定案 |
| +216 | u32 | — | — | w3: `*(conf+216)` → +1 显示 | 当前竞标阶段 (0-based) | 定案 |
| +220 | u8 | — | — | w3/w9 文案门 | 正在提出需求旗 (PEACE_CURRENTLY_MAKING_DEMANDS / PEACE_WAITING_…) | 定案 |
| +221 | u8 | 0x3127 (12583) | completed | 主分派分支门; bid click 门; popup 装载门 | 会议已结束旗 | 定案 |
| +248 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3120 (12576) | winners | sub_140E38720(conf,&tag) 逐元查 tag@elem+8 | 获胜方条目 (元素布局见下表) | 定案 |
| +272 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3121 (12577) | losers | — | 战败方条目 {tag@elem+16} | 定案 |
| +296 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3125 (12581) | liberated | w2: `conf+308` 计数门 (与 +332 相加) | 解放国条目 {tag@elem+8} — 出叶 (计数门) | 定案 |
| +320 | scoped_ptr<CPersistent> | 0x32E0 (13024) | subject | 同上门 | 附庸国条目 {tag@+8, overlord tag@+88} — 出叶 (计数门); 条目 +80 = CPersistent 副体 vtable (mdisp 80), 非值槽 | 定案 |
| +344 | 容器 24B {data@+344, count@+356} | — (writer 未写) | — | CPeaceSummaryPopUpWindow 消费 | 强制改政体条目容器 — 条目 = CConferenceForceGovernmentParticipant (副体 vt@+80); 查/建按 (国 tag@+8 × 实施方 tag@+88) 双匹配, 意识形态由实施方国派生 (sub_140E382F0/0x140E380F0) | 定案 |
| +368 | scoped_ptr<匿名结构 (NNB 形状)> | 0x3108 (12552) | solo_winner | sub_140E3F7D0 门 (非零 → 分差=0) | 单一获胜方 {tag@+8} | 定案 |
| +416 | {d@416, c@+428} 表 | — | — | w2 显隐门; sub_140E400F0 逐元 +64 分值 | = CPdxArray<scoped<CPeaceAction>> 当前竞标表 (dynamic_cast 直证; CPeaceAction 布局见下表) | 定案 |
| +440 | RB-tree | — | — | sub_140E400F0 树游 (+25 色标) | = map<CPeaceAction*, scoped<CPeaceAction>> 竞价覆盖表 (节点+32 键 / +40 值; 总分调 Σ(新+64−旧+64); 键类型高置信, 余定案) | 定案 |
| +472 | RB-tree (门 +480) | 0x320D (12941) | minor_flavor | 未消费 (负) | map: 节点+28 tag → 18 | 定案 |
| +504 | RB-tree (门 +512) | 0x2835 (10293) | history | 未直接消费 (负; UI 走运行时列表 + `current_and_history_actions` 窗) | map: 节点+32 tag → {节点+40{+52} bidding (12850) 引用表} | 定案 |
| +520 | u32 | — | — | w5: 输光 && `conf+520 <= 0` 分支 | = 当前竞标方 tag (GetCurrentNegotiator sub_140E47890 + 行头点击 sub_141E50A00 写证) | 定案 |
| +524 | u32 | — | — | sub_140E4F220 写 (变化检测) | UI 选中/过滤国 tag | 定案 |
| +528 | u32 | — | — | w5 传 sub_14185CEC0 (available_actions 构建) | 选中 action token (复位值 = 19479 undefined) | 定案 |
| +532 | u32 | — | — | bid click 写; w5 作 ACTION 参数 | 过滤行动 id (PEACE_FILTER_DEMANDS_DESCRIPTION) | 高置信 |
| +536 | qword | 0x4B89 (19337) | peace_threat | CPeaceSummaryPopUpWindow 负消费 | 和会威胁值 | 定案 |
| +544 | qword 标量累加器 | — (ctor 清零, writer/reader 不碰) | — | 写点未找到; 前批「缴获装备值 GUI 消费」未能复现 (混淆源: 空军窗口 +312 对象+544 读 BM_ENEMY_AIR_SUPERIORITY_COUNTER / 战报 EQUIPMENT_CAPTURED_* 独立条目特性) | 语义推定, 待复验 | 推定 |
| +552 | RB-tree | — | — | 读法 sub_140E47D70 / 内战残余转让 0x140E48DF0 / pc_does_state_stack_demilitarized / _dismantled 二审 | **map<u32 州 id → CStatePeaceAction\* 数组>** (key = 州 id@节点+32; value count@节点+88, 元素@节点+96; 按州竞标叠层, 值按回合分层); **写方三组**: 载入重建 虚槽[8]→0x140E4C490 / EndTurn·终局前置 0x140E4D220 / GUI 0x141E571B0·0x141E48CF0→0x140E3B6B0, 插入原语 sub_140E2E9D0 | 定案 |
| +568 | RB-tree | — | — | 0x140E46DA0 消费 | qword 键 (取自对象 +8, 疑动作 refid 对 — 推定); accessor 与 +552 同族 (sub_140E2E650/2EED0/31B00/30F50) | 键推定 / 值未决 |
| +584 | RB-tree | — | — | sub_140E524B0 以动作/条目 +52 查 | u32 giver tag 键 (推定); accessor 同族 (sub_140E2EC10/2E280/31A20/30930) | 键推定 / 值未决 |
| +616 | i64 | — | — | — | 和会开始墙钟 FILETIME ticks (Xtime_get_ticks; 100ns, 1601 纪元) | 定案 |
| +624 | u32 | 0x2AAD (10925) | time_duration | — | time_duration 累计秒 = 写时墙钟叶 (EXEMPT, 见 §4.10.26) | 定案 |

+552/+568/+584 三棵 RB-tree 均由 Start (0X140E4F240) 清空。

**和会终结算链** (三入口同链: 交互终局 sub_140E45FB0→0x140E41BB0 / Start 即时结算分支 0x140E4F240 / 载入后重建 = 虚槽 [8] 0x140E49760 只跑第一环): ① **RebuildOutcomes 0x140E38ED0** (清空重建 +296/+320/+344 结果条目 + winner 净化 + 由 +504 history 聚合 SplitData 分组定胜负写四方份额/胜支旗; status∈{3,4} 的行动不参与结算); ② **EndWarsTerminate 0x140E41F70** (流亡托管清退 + 胜×败双边停战, 写点全在国/外交侧); ③ 三结果数组虚槽 [0] 逐元素销毁; ④ **CivilWarRemainderTransfer 0x140E48DF0** (内战败方未叠层残余州转让内战胜方 winner 条目+328); ⑤ **FinalizeAnnounce 0x140E42B50** (双边占领/驻军省 controller 回退 + liberated 首都兜底 + 和约名/PEACE_TREATY_THREAT 事件); ⑥ 交接 0x140B66080。回合推进链 (0x140E50BB0) 内联复用 ①; **GetTurnScoreShare 0x140E3F6B0** 只读 winner+88 份额数组喂 initiative 累计 (+76), 与终局链正交。

⚠ 竞标分值 = CPeaceAction+64 (sub_140E400F0 所加为竞标对象), 非 winners 条目内偏移。

**CPeaceAction 增量**: **+48 = taker 行动方 tag** (cost/taker_flag 双消费, CBiddingsPopupItem 域; 全布局 = §4.10.28: +52 giver / +56 negotiator / +60 status / +64 cost); winners 条目增量: **+36 = 州数** (CPeaceSummaryPopUpWindow 读)。**CPeaceSummaryPopUpWindow 消费验证**: conf+248 winners/+272 losers (**条目+16 tag ✓** — 与 losers 行 {tag@elem+16} 互证)/+296 liberated/+320 subject/+52/+56 white peace/conf+64 message 全中; **subject 条目+96 与 tag@+8 并存待裁**。CBiddingsPopupItem: item+40 = _pConference / item+48 = _pAction (断言实名); wargoal_icon 显隐读 conf+520 ✓ / tooltip 走 GetCurrentNegotiator sub_140E47890 ✓; 宿主 = CPeaceBiddingsPopUpWindow (vt[2]=populate 直证, 与 §4.30.22 三行池边界 = Popup 变体独立类)。

winners 条目 (scoped 条目, 元素基 = 条目基; = CConferenceWinnerParticipant):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+8 | tag_id | tag (sub_140E38720 逐元比对位) |
| 元素+24 | CState** 数组 {data@+24, cap@+32, count@+36} | 受让州指针数组 (聚合器 0x140E38A70 推入 = "+36 州数"的数组本体 ✓; RebuildOutcomes 清零) |
| 元素+48 | 树 {头@+48, size@+56} | **_TakenShips** (take_navy 竞标累加表, assert 实名): map\<loser_tag, {夺船清单 vector@节点+40, _RatioScreening qword@节点+64 钳≤1_fixed}\>; 唯一写点 = 聚合 sub_140E51A70 case 12526 → sub_141454600; 不落盘, RebuildOutcomes 重建 |
| 元素+76 | u32 | 当前分 (回合链 `+=` 累加槽, 写点 0x140E50BB0) |
| 元素+88 | 匿名结构 (元素待裁) 向量 | ScoreDistributionForWinner 数组 (GetTurnScoreShare 0x140E3F6B0 按回合下标读) |
| 元素+328 | u32 向量 {data@+328, cap@+336, count@+340} | 内战败方残余受让州 id (CivilWarRemainderTransfer 写; writer 键 taken_states_civil_war 12135 ✓; 执行侧消费 sub_1414559B0 → sub_1409DE560 设归属 + 州+140 清零) |

> **分数链 (定案)**: Start → sub_140E500B0 定总分池 (= conf+48, Σ original_score) → sub_141459450 InitScore 写 +72 original_score 并回填 +128 war_score_breakdown 体 (+144..+272) → sub_1414579E0 按 FractionsPerTurn 把 +72 摊到 +88 = **逐回合计划进账表** → 每回合 EndTurn (0x140E50BB0) 经 GetTurnScoreShare 累加 +76 = **已进账累计**; +280/+304 = score_from_countries/amounts **按来源国分项明细** (平行数组 count 同步 assert, 不齐则整对不存 — 填充点未锁定 待裁); +80 = non_refunded_score (13155), +112 = ratio qword (694) — 均落盘。winner writer = 0x141459B70 (this = 条目+64 副体); 受让州数组/+48 _TakenShips 不落盘。

CPeaceAction (当前竞标表元素; CStatePeaceAction 派生):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | token | 类型 |
| +16 | SSO | token 串 |
| +56 | tag_id | negotiator 谈判方 tag (§4.10.28 ✓) |
| +64 | — | 分值 |
| +72 | u32 | (CStatePeaceAction 派生) state id |
| +76 | u8 | (CStatePeaceAction 派生) **demilitarized** 旗 — 推定 |
| +77..+78 | u8 | (CStatePeaceAction 派生) 中间叠加 bool×2 (未名) |
| +79 | u8 | (CStatePeaceAction 派生) **dismantled** 旗 — 推定 |

#### 4.10.28 和会候选出叶裁定

| 存档键 (token) | 裁定 | 依据 |
|---|---|---|
| liberated (12581) | 出叶 | w2 计数门 (sub_1418657D0 L301) |
| subject (13024) | 出叶 | 同上计数门 |
| history (10293) | 未出叶 | 树本体无 UI 读; UI `current_and_history_actions` 窗走运行时 +416 列表 (语义旁证) |
| redistributions (14497) | 不随本块出叶 (推定) | token 不在 conference writer; 疑在州转移侧 |
| score_from_countries (13833) | 不随本块出叶 (推定) | token 不在 conference writer; 疑对应 winners 条目 +64 值槽 |

#### 4.10.29 active_peace.time_duration (墙钟豁免叶)

| 项 | 值 | 语义 |
|---|---|---|
| 公式 | u32@p+624 + (Xtime_get_ticks − i64@p+616) / 1e7 | writer 落盘时刻重算 now − 和会开始; resave ↔ 导出恒差墙钟间隔 (同 #session/seconds_played 族) |
| 豁免 | EXEMPT_LEAVES ('peace_conference', 'active_peace.time_duration') | 豁免已裁定 |
| 时基 | Xtime = FILETIME 100ns (1601 纪元) | 嵌入式 os.time 返回 1601 纪元秒 (已含 11644473600 偏移; 桌面 lua 是 1970 — 换算注意双加; 段实现带幂等自检) |
| ⚠ 多块形 | `active_peace[2].time_duration` 不在豁免键内 | 现无多块并存实例, 出叶即暴露 |

#### 4.10.30 和会静态库与参与者族 (1.19.3 实名)

**CPeaceConferenceDatabase** (和会静态库, 256B 单例 0x332EFC8; vt 0x14271AF60; ctor 0x140172B00; 校验 [2]=0x140A848D0; Reset 0x140A847C0; **非标准 idb 形状**, 已挂 §4.26.8 附注形): 三内联 vec + 默认类别内嵌:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | CPeaceActionCategoryEntry 内嵌 136B | 默认和会行动类别 (+8 token 默认 10724 other / +16 is_default 旗) |
| +176 | u8 | has_default_category 旗 (恰一类别可 default, .cpp:250/296 断言) |
| +184 | 内联 vec | peace_action_categories (19833): 元素 136B {vt@0, token@+8, is_default u8@+16, 三串@+24/+56/+88, u32@+120} |
| +208 | 内联 vec | peace_action_modifiers (19831): 元素 192B = CPeaceActionModifier |
| +232 | 内联 vec | peace_ai_desires (15110): 元素 184B = CPeaceActionScriptedAiDesire |

访问器: sub_140A84A30(db, token) 类别查 (未中告警 + 返默认); sub_140A84750(db, token) modifier 查 (+140 旗 ∧ +8 id)。

**CPeaceActionModifier** (和会行动修正静态定义, 192B; vt 0x14293F9E8; writer = CFG 空桩不落盘; reader 0x140A85360): +8 定义名 token / +16 enable 条件对象 (+36 计数门) / +104 i64 cost_multiplier (19001, 默认 100000) / +112 CPdxArray<40B> peace_action_type (19832) / +136 category (702, 默认 other) / +140 u8 faction_modifier (19616) / +144 名串 32B / +184 装载序。

**CPeaceActionScriptedAiDesire** (和会 AI 欲望定义, 184B; vt 0x14293FA38; writer 桩; reader 0x140A85420): +8 token / +16 enable (+36 计数) / +104 u32 ai_desire (15455) / +112 peace_action_type 表 / +136 名串 / +176 装载序。

**和会参与者族 5 类** (conf+248 winners / +272 losers / +296 liberated / +320 subject / +344 强制改政体容器之元素; 多基 CPersistent 副体位: Winner/Liberated = b+64, Subject/ForceGov = b+80; writer/reader 的 this = 副体, 故 a1−56 / a1−72 同指 complete-object b+8 = country CRef):

| 类 | vt | mdisp | 键与字段 (complete-object b) |
|---|---|---|---|
| CConferenceWinnerParticipant | 0x1429C24D0 | 64 | country(10394)@b+8 / original_score(12578)@b+72 / score(11044)@b+76 / non_refunded_score(13155)@b+80 / score_distribution(19829) 串@b+88 / ratio(694) qword@b+112 / war_score_breakdown(12502) 内嵌 112B@b+128 / score_from_countries(13833) vec@b+280 / score_from_amounts(13834) vec@b+304 (双表须等长, 不齐则整对不存 .cpp:310) / taken_states_civil_war(12135) vec@b+328; **不落盘**: +24 受让州数组 / +48 _TakenShips 树 / +248 scoped (运行时重建); writer 0x141459B70 (this = 条目+64) |
| CConferenceLoserParticipant | 0x1429C2520 | 0 | screening_ic(13205) fixed@b+48 / civil_war_target(12619) u8@b+176 / civil_war_enemy(14217) **tag 数组 {ptr@b+180, count}** (writer this = 条目+144, 字段 writer 视 +192/+320/+324 与 b 坐标恰差 144 互证; 填充点 sub_140E4FA60, cpp:3848 BestCivilWarWinner 断言; reader 0x141458A30 同偏移) — **civil_war_enemy = 内战获胜方 tag 组** (CivilWarRemainderTransfer 读点) |
| CConferenceLiberatedParticipant | 0x1429C2588 | 64 | country@b+8 / liberators(12579) 平铺 u32 vec@b+72 |
| CConferenceSubjectParticipant | 0x1429C25F8 | 80 | country@b+8 / overlord(11135) tag@b+88 / ratio(694)@b+104 / is_main_puppet(12870) u8@b+112 |
| CConferenceForceGovernmentParticipant | 0x1429C2668 | 80 | country@b+8 / enforcer(19845) tag@b+88 / ratio(694)@b+104 / is_main_puppet(12870)@b+112 |

参与者族运行时派生字段 (RebuildOutcomes 0x140E38ED0 及其聚合器 0x140E38A70/0x140E389A0 写, 坐标 = complete-object b; 回合推进/终局/载入重建三处复用):

| 类 | 偏移 | 类型 | 名称/语义 |
|---|---|---|---|
| CConferenceWinnerParticipant | b+24 | CState** 数组 {cap@+32, count@+36} | 受让州指针数组 (0x140E38A70 推入; RebuildOutcomes 清零) |
| CConferenceWinnerParticipant | b+48 | 树 {size@+56} | **_TakenShips** (map\<loser_tag, {夺船清单 vector, _RatioScreening ≤1_fixed}\>; take_navy 聚合写, 不落盘运行时重建) |
| CConferenceWinnerParticipant | b+328 | u32 向量 {cap@+336, count@+340} | 内战败方残余受让州 id (= writer 键 taken_states_civil_war 12135 ✓; CivilWarRemainderTransfer 写) |
| CConferenceLoserParticipant | b+192? | qword | 份额 (fixed×1e-5; 组总=0 时 0xFFFFFFFF) — ⚠ 坐标基待裁 (与 screening_ic writer 视 +192 同位, 分组写点 0x140E3DF10 的基址未复核) |
| CConferenceLoserParticipant | b+200? | u8 | 胜支旗 (SplitData 分组定胜负 0x140E3DF10 写) — 同上坐标待裁 |
| CConferenceLiberatedParticipant | b+72 | u32 向量 | winner tag 数组 (= writer 键 liberators 12579 ✓) |
| CConferenceLiberatedParticipant | b+96 | u32 | 未名 (ctor 清零) |
| CConferenceLiberatedParticipant | b+104 | qword | 份额 |
| CConferenceLiberatedParticipant | b+112 | u8 | 胜支旗 |
| CConferenceSubjectParticipant | b+64 | map\<token → 州 id 向量\> | modifier 表 (键 = 四旗 token 12531..12534, 0x140E389A0 写) |
| CConferenceSubjectParticipant | b+96 | u32 | 未名 (ctor 清零) |
| CConferenceSubjectParticipant | b+104 | qword | 份额 (= writer 键 ratio 694 同槽) |
| CConferenceSubjectParticipant | b+112 | u8 | 胜支旗 (= writer 键 is_main_puppet 12870 同槽) |
| CConferenceForceGovernmentParticipant | b+64 | map\<token → 州 id 向量\> | modifier 表 (同 Subject) |
| CConferenceForceGovernmentParticipant | b+96 | u32 | 未名 (ctor 清零) |
| CConferenceForceGovernmentParticipant | b+104 | qword | 份额 (= ratio 694 同槽) |
| CConferenceForceGovernmentParticipant | b+112 | u8 | 胜支旗 (= is_main_puppet 12870 同槽) |

> 参与者 tag 双坐标待裁: GUI 侧读条目+16 (主表接口) 与 writer 侧 b+8 (CPersistent 副体) 并存 — GUI 走主表副读, writer 走副体; 与既有「subject 条目+96 vs tag@b+8」同性质, 配对关系待裁。

**CPeaceProposalAction** (和平提案记录, 120B; vt 0x14298BE80; CDiplomaticAction 派生 §4.10.13; clone 0x1411018D0): +8 token = 12474 peace_proposal; 派生段与基类全同 (§4.10.13 表); 无自有新字段 (sizeof = 基类 120)。

**CWarGoalType** (战目标类型脚本定义, ~820B; vt 0x14293BEA0; TNullObject vt 0x14293BFA8; writer = CFG 空桩不落盘; reader 0x140A3B930; 载库 CWarGoalDatabase 0x332EF28 = idb wargoal 已挂): +64 allowed(12263) / +152 available(12264) / +240 take_states(12495) / +328 liberate(12496) / +416 puppet(12497) / +504 force_government(12498) / +592 instant_reward(12306) / +680 war_name(11288) 串 / +716 take_states_limit(12530) / +720 liberate_limit(12571) / +724 puppet_limit(12572) / +728 force_government_limit(13558) / +732 generate_base_cost(13337) / +736 generate_per_state_cost(13338) / +740 expire(12277) / +744..+800 四组代价×威胁量化系数 (take_states_cost 12558 / liberate_cost 12573 / puppet_cost 12560 / force_government_cost 12561 / 四 threat_factor 13557-13561; 读形 = 100000 + read*1000/100000 定点) / +808 threat(11197) i64 / +816 annex(10726)。

#### 4.10.31 和约动作族 (CPeaceAction 独立基族 — 非 CDiplomaticAction 系)

**CPeaceAction** (vt 0x1429D2CA0, ctor 0x141518F90, writer 真体 0x141520010 / reader 真体 0x14151F740): +8 u32 行动类 token (ctor a2) / +16 name 32B (27, token 直名串) / **+48 taker (12501)** 得地/受益方 tag / **+52 giver (12500)** 失地/出让方 tag / **+56 negotiator (12518)** 谈判方 tag / **+60 status (208)** u32 / **+64 cost (10323)** 行动代价 u32。中间基 **CStatePeaceAction** (vt 0x1429D2DC0): +72 state (439) / +76..+79 四旗。派生:

| 类 | vt | token | 增量字段 |
|---|---|---|---|
| CTakeStateAction | 0x1429D2EE0 | 12495 take_states | = CStatePeaceAction 全量: +72 state (439) / **+76 demilitarized_zone (12531) / +77 war_reparation (12532) / +78 resource_rights (12533) / +79 dismantle_industry (12534)** (置位才写); writer 0x1415200C0 / reader 0x14151FA50 |
| CTakeNavyPeaceAction | 0x1429D3360 | 12526 take_navy | +16 name 覆写 = "PEACE_TAKE_NAVY_LABEL" / +72 ship 引用 qword (键 10400, 写 = u32@ship+8) / +80 ratio qword (694); writer 0x141520150 / reader 0x14151FAC0; 工厂 sub_14151B860 (cpp:309) 12526 分支, 存档侧经动作装载器 sub_1419F4A70 (12585 actions) 重建; UI 行构建 sub_141860410, tooltip "take all screening ships" |
| CForceGovernmentAction | 0x1429D3240 | 12498 force_government | +72 state / **+80 = 目标国 tag** (puppet=12497 键; 意识形态不存于动作, 由 taker(+48) 国执政意识形态派生 — SplitData 键三处读证) |
| CPuppetCountryAction | 0x1429D3120 | 12497 puppet | +72 state / +80 TAG (writer 与 ForceGovernment 同址) / +88 预留 |
| CLiberateCountryAction | 0x1429D3000 | 12496 liberate | +72 state / **+80 = 被解放 TAG** (liberate=12496 键) |

> conf+416 竞标表元素 = CPdxArray<scoped<CPeaceAction>> (dynamic_cast 直证同族); pc_is_state_claimed_and_taken_by 触发器读 action+8==12495/+48 ✓; 派生槽 [8+] 每类真覆写 (执行/检验行为, 未逐读)。

> **本域 GUI 类布局**: 见 4.30.44 / 4.31.39 / 4.31.55。
