

### 4.6 NDoctrines (学说族)

本族分两侧: 运行时侧 (`CDoctrineSystem` / `CCountryDoctrineStatus` / `CFolderStatus` / `CTrackStatus` /
`STemporary*` / GUI 件, 见 §4.6 正文) 与 **def 侧** (静态定义库, 见 §4.6.1–4.6.12)。
def 侧八类全部不入存档 (writer = CFG 空桩)。

**CDoctrineSystem**: `doc = *(gs + 1024)` — **32B 容器对象定案** {vtable 0x142965448 (RTTI NDoctrines::CDoctrineSystem; 0x1427C5020 系 NProject::CComplexity vtable勿混) 族 9 槽
(serfam 记 32 系断言串字节误计), data@doc+8, cap@doc+16, count@doc+20, alloc@doc+24};
writer 0x140D810B0 (块键 11593 countries) / reader 0x140D7FDA0 / PreLoad 0x140D7F080;
国家条目 stride 0xA0, 元素按国家 idx 排列; 活体 cap==count==440 全中。

**CCountryDoctrineStatus** (vtable RVA 0X29653F8, writer 0X1413CF470; 0xA0 字节):

| 偏移 | 类型 | 名称 | 语义 | 上界 |
|---|---|---|---|---|
| +8 | — | country | TAG 写入 (sub_140BB59C0) | |
| +16 | 匿名结构 (80B) | folders 容器数据指针 | {data, count}; 元素内联 80B | count<16 |
| +17..+27 | — | = folders 容器 {data@16, **cap@24**, count@28, alloc@32} 的 data 尾 (17..23) + cap@24 (pdx 24B 通式) |  |  |
| +28 | uint32 | folders 容器计数 |  | count<16 |
| +29..+39 | — | = folders count@28 尾 (29..31) + **alloc@32**  |  |  |
| +40 | CCombatTactic* | enable_tactic 容器数据指针 | {data, count}; 元素 8B 指针 → token@目标+152 | <64 |
| +41..+51 | — | = enable_tactic 容器 {d@40, **cap@48**, c@52, alloc@56} 的 data 尾 + cap@48  |  |  |
| +52 | uint32 | enable_tactic 容器计数 |  | <64 |
| +53..+63 | — | = enable_tactic count@52 尾 + **alloc@56**  |  |  |
| +64 | 匿名结构 (64B) | cost_reduction 容器数据指针 | {data, count}; 元素内联 64B | <64 |
| +65..+75 | — | = cost_reduction 容器 {d@64, **cap@72**, c@76, alloc@80} 的 data 尾 + cap@72  |  |  |
| +76 | uint32 | cost_reduction 容器计数 |  | <64 |
| +77..+87 | — | = cost_reduction count@76 尾 + **alloc@80**  |  |  |
| +88 | 匿名结构 (112B) | daily_mastery 容器数据指针 | {data, count}; 元素内联 112B | <64 |
| +89..+99 | — | = daily_mastery 容器 {d@88, **cap@96**, c@100, alloc@104} 的 data 尾 + cap@96  |  |  |
| +100 | uint32 | daily_mastery 容器计数 |  | <64 |
| +101..+111 | — | = daily_mastery 计数尾 + 容器头 |  |  |
| +112 | 匿名结构 (24B) | **equipment_bonus 容器** {data@112, cap@120, **count@124**, alloc@128} | writer 0X1413CF470 块尾第五段; 条目 24B **SDoctrineEquipmentBonusHandle** (vtable 0X2965210): {vtable@0, id lexer token u32@+8 (装备原型名, token 串发射不带引号), index u32@+12 (调用方 ordinal: 选中路径 0/track 跨档序号/milestone 序号), equipment_bonus u32@+16 (国家 named_equipment_bonus 库槽位号, sub_140E60110 经 last_named_equipment_bonus 递增分配, 非加成数值), pad@20}; 块门 = count≠0 (零容器连键带体不写), 条目无逐条门 0 值照写 (MD towed_gun_equipment index=0 bonus=0 实证); +136..+159 第六个 24B 容器 = 运行时不序列化 | count≠0 |

GUI: NDoctrines::CCountryDoctrineView — folders 容器消费 (target = +1408 scopedptr 子控制器 CFolderView 族; folder 库容器命中; folder 模板 token 12989 跳过门)。

**CFolderStatus** (vtable 0X29653A8; 80B; 整类 writer vtable[2] sub_140FC99F0 — 落盘序 grand_doctrine 键 16775 (+16 ptr≠0 门) → folder 键 11873 (+8 ptr≠0 门) → tracks 块 16772 (+36≠0 门) → completed_subdoctrines 键 16791 (+68≠0 门, 逐 8B 指针发 token 名不带引号); reader vtable[4] sub_140FC9020):

| 偏移 | 类型 | 名称 |
|---|---|---|
| +8 | — | folder 名 (指针→对象→token@+8 转名) |
| +16 | — | grand_doctrine 名 (同上) |
| +24 | 匿名结构 (96B) | tracks 容器数据指针 — {data, count}; 元素内联 96B (count<64) |
| +25..+35 | — | = tracks 容器 {d@24, **cap@32**, c@36, alloc@40} 的 data 尾 + cap@32 (元素内联 96B) |
| +36 | uint32 | tracks 容器计数 |
| +48 | CCountryDoctrineStatus* | owner 回指针 (不序列化; 触发器上下文 *(+48)+8 = status+8 TAG 槽) |
| +56 | CSubDoctrineTemplate* 向量 | completed_subdoctrines 容器 {d@56, cap@64, c@68} (8B 元素; writer/reader 双向) |
| +72 | allocator* | completed 容器分配器 (CPdxHybridInlineBufferAllocator, vtable 0x2965598; 扩容经其 vtable+8/vtable+16) |

**CTrackStatus** (vtable 0X2965358; 96B; **整类 writer vtable[2] = sub_14147CD00, reader vtable[4] = sub_14147C2C0** — 全 serfam 共享 wrapper vtable[1]/[3] 0x1424BEC50/0x1424BE690):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | NDoctrines::CSubDoctrineTemplate* | sub_doctrine 名 (指针→token@+8); def 对象 |
| +16 | uint32 | rewards |
| +24 | fixed×1e-5 | mastery |
| +32 | fixed×1e-5 | mastery_bank |
| +40 | fixed×1e-5 | daily_mastery |
| +48 | 匿名结构 (24B) | leaders_daily_mastery 容器数据 — {data@+48, count@+60} 24B 元 |
| +49..+59 | — | = leaders_daily_mastery 容器 {d@48, **cap@56**, c@60, alloc@64} 的 data 尾 + cap@56 (24B 元) |
| +60 | uint32 | leaders_daily_mastery 容器计数 |

家族辅助函数 (folder_status.cpp; debug 门 byte_1435E1B51 — track_status.cpp 全 TU 与 doctrine_triggers.cpp:109 断言同用此门, 非全书惯用 byte_1435E1B52):

| 函数 | 语义 |
|---|---|
| sub_140FC8730 | ValidTrackIndex (`0≤idx<+36`; 负 idx 断言 "Invalid track index" :281) |
| sub_140FC81C0 | GetTrackTemplate: +16 grand def → def+792 tracks 名表 [idx] |
| sub_140FC8670 | STrackFilter 五字段匹配判定 (filter+8 track→GetTrackTemplate / +16 folder→folder+8 / +24 grand→folder+16 / +32 sub_doctrine→tracks[idx]+8 / +40 track_index≠−1→==idx; 字段 0 = 通配) |
| sub_140FC6D90 | AssignSubDoctrine (校验→sub_14147C8A0; 断言 :239) |
| sub_140FC7D90 | RefreshTrackActiveDaily: 逐 track, active 触发器门 (sub_1409E6B80, 上下文 = owner+8) → track+72 = 增益否则 0 (**track+72 每日 mastery 产出的写入者**) |
| sub_140FC87B0 | CompleteMilestone: 去重追加 completed → 注册 sub_1413CD240(owner, milestone+16, **type 6**, grand+40, grand+8, idx) (milestone 注册/注销 type=6, 与换 grand 的 type 3 并列; 注销对应 sub_140FC8CE0: 定位链 = folder+24 逐 track (96B 步) 元+8 匹配 *(a2+8) → sub_1409CDA20 在 folder+16 grand def 按 idx+id 查 milestone → sub_1413CEE00(folder+48 推定 owner, milestone+16, type 6, *(folder+16)+8, idx); 未中断言 "Could not find milestone to remove" :660, 闩 byte_14333D6CC) |
| sub_140FC6EB0 | GetTrackMasteryDetails (见下式) |

GetTrackMasteryDetails 增益合成式: `sum = track.daily_mastery(+40) + Σ active daily_mastery 条目(+88, STemporaryMasteryGain, filter 匹配 sub_140FC8670) + 3 项国家侧修正源 + Σ active bonus(+96)`; `factor = 100000 + 三修正源`; `gain = sum×factor/100000` (÷1e5 截断), `0<gain<qword_1433341F0 → 钳到下限`; `bank = gain×qword_143334480/100000` (MASTERY_BANK_CONVERSION_RATE); a4≠0 时发 5 组本地化行 (DOCTRINE_MONTHLY_MASTERY_GAIN_FROM_UNITS / …_BONUS / …_BONUS_FACTOR / MASTERY_BANK_CONVERSION_RATE / DOCTRINE_MONTHLY_MASTERY_BANK)。

日更 tbb 两遍 pass (160B 元素 CCountryDoctrineStatus 数组并行遍历): pass A sub_140D7BEA0 → 逐 folder sub_140FC7D90 刷 active 产出; pass B sub_140D7C1A0 → 逐 folder **sub_140FC8DC0** ("Invalid track index" :281 断言为 family 内联辅助 — 8DC0/7EB0/7D90 三站共享, 同 latch byte_14333D6C6) — **前半段**: 逐 track 算单位掌握度 (CMasteryConditions (子学说+832 / 模板+120) 域旗 +88/+89/+90 门控三军 xp 条目聚合 sub_141A32E90 → track+40 daily_mastery); **后半段**: 应用 cost_reduction (CCountryDoctrineStatus +136 容器 = cost_reduction 条目数组, 80B 元素步进, 元素 +8/+32/+56 三修正槽, 日步逐条 `基础值×缩减/1e5`, >0 才经 sub_14147C7B0 灌入 track)。CCountryDoctrineStatus reader (vtable[4]) = 0x1413CED70 (与 writer 0x1413CF470 对)。

**STemporaryCostReduction** (64B 内联):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | uses |
| +16 | string | name |
| +17..+47 | — | = name SSO 32B 本体 (buf@16 尾 + size@+32 + cap@+40=15) |
| +48 | fixed×1e-5 | cost_factor |
| +56 | NDoctrines::CFolderTemplate* | folder 名 (指针→token@+8; writer `sub_1424C2EA0(a2, 11873, sub_1424BE600(*(a1+56)), 0)`) |

**STemporaryMasteryGain** (112B 内联):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | string | name |
| +9..+39 | — | = name SSO 32B 本体 (buf@8 尾 + size@+24 + cap@+32=15) |
| +40 | **内嵌 NDoctrines::STrackFilter (48B, vtable 0x1427D1130)** | filter 对象 vtable — ⚠ dm+40 非 {data,count} 容器; dm+48/52 是定义指针, 按容器 data/count 读即错; 布局见下表 |
| +41..+87 | — | = STrackFilter 内嵌体本体 (+40..+87) + 尾 pad |
| +88 | fixed×1e-5 | daily_mastery |
| +96 | fixed×1e-5 | bonus |
| +104 | uint32 | days |

**STrackFilter 内嵌体** (48B, dm+40 起; writer 0X14147B640, 叶序 track→folder→grand_doctrine→sub_doctrine→track_index):

| 偏移 (filter) | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | 匿名结构 (NNB 形状) | track 定义指针 | = dm+48; ptr≠0 写 `track "名"` |
| +16 | 匿名结构 (NNB 形状) | folder 定义指针 | = dm+56 |
| +24 | 匿名结构 (NNB 形状) | grand_doctrine 定义指针 | = dm+64 |
| +32 | 匿名结构 (NNB 形状) | sub_doctrine 定义指针 | = dm+72 |
| +40 | int32 | track_index | = dm+80; 默认 −1, ≠−1 才写 |

四定义指针所指定义对象名均 = token_name(ru32(rp(p)+8))。

**CTrackProgressItem (学说 track 进度行, GUI)**: NDoctrines::CTrackProgressItem ("track_progress_item", 56B) = 学说文件夹按钮下每国 track 进度行 **{+40 track / +48 索引 / +52 tag}**; Update sub_141F690B0: status_text = 进度值 / full_mastery_icon = 全掌握门; 宿主 = entry_button.cpp 学说按钮。

学说状态对象 (tag 对 → CCountryDoctrineStatus helper 产出) 补行:

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +16 | 元素 (80B) 数组数据 | 学说状态条目表; 计数 @+28; 条目+16 → 级数 @子对象+804; 状态对象+24 = 已选 doctrine 槽 | 推定 |

**CDoctrineListItem / CDoctrineSharingFolderItem (学说行件, GUI)**: CDoctrineListItem = CDoctrineSelectionList 学说行: **def 本体 @+1440** (assert 直证); **def 侧三偏移定案: def+40 = name / def+104 = gfx / def+36 = XP 类别**; 选中帧由宿主 0X141F3AC50 管理 (dynamic_cast 钉死共享基 = CStandardGridBoxItem)。CDoctrineSharingFolderItem = 学说共享文件夹行: **folder def @+2776 (def+96 = icon gfx)**; 共享态 @+2784 驱动 lock_icon/unlock_button 显隐 + 成本着色 (FACTION_UNLOCK_BUTTON); 命令出口 = **CUnlockFolderDoctrineSharingCommand {+40 / +48}**。

#### 4.6.1 NDoctrines def 侧族总览

脚本目录 `common/doctrines/{folders,tracks,grand_doctrines,subdoctrines}` 对应四个 def 库, 全部
**PR 形态** (`CPersistentReloadableGameItemDatabase`), 单例槽存库对象指针 (`malloc(0x80)`, 128B)。
装载器 = `sub_14018BB20` 内连续四段 (目录串 + `+40 = ".txt"` 后缀)。

**set_grand_doctrine 令牌查表 = sub_140529020** (doctrine_effects.cpp:65; 定案): effect 对象 a1+88 = 大学说 def 指针槽; 查 CGrandDoctrineDatabase 单例 qword_14332EEA8 的 RH 表 (db+56 桶基 / stride 24, 桶 {hash@+0, dist u8@+4, token u32@+8, 值指针@+16}; mask db+68 / extra db+72; 哈希 0x45D9F3B 双轮雪崩 + xor-fold, 键 = v4 ^ HIWORD(*a2), 与 §4.26 同族同常数); 走法 = 首桶 dist==0 → miss, 线性探针 (>本桶 dist → miss); 命中另两道门 (非哨兵桶 ∧ 桶+16 值指针非空, 空值槽亦走未找到日志); 命中写 a1+88, 返 1; 未命中 → a1+88 = 0 + CLog 4096 "set_grand_doctrine - Grand doctrine not found: %s" (:65, 令牌名经 sub_1424BC260)。前置 gameitemdatabase.h:142 断言 (B52/闩 byte_14332FF6B)。a1 归属 set_grand_doctrine 效果类为推定 (文件域 + 令牌名直证)。

| 库 | vtable (RVA) | 单例槽 | 目录 | sizeof |
|---|---|---|---|---|
| NDoctrines::CFolderDatabase | 0x142719048 | qword_14332EEA0 | common/doctrines/folders | 128 |
| NDoctrines::CGrandDoctrineDatabase | 0x142719228 | qword_14332EEA8 | common/doctrines/grand_doctrines | 128 |
| NDoctrines::CSubDoctrineDatabase | 0x1427193d8 | qword_14332EEB0 | common/doctrines/subdoctrines | 128 |
| NDoctrines::CTrackDatabase | 0x1427194c8 | qword_14332EEB8 | common/doctrines/tracks | 128 |

条目容器: data@+80 / count@+92; 名字查找 = `hash(名)` → `DB+56 + 24*idx` 线性探测 (探测序字节在槽 +4,
条目对象指针在槽 +16), mask@+68 / 溢出桶数@+72。哈希 = 逐次 `h ^= h>>16; h *= 73244475; h ^= h>>16`。
CFolderDatabase 的模板实例特例: `TGameItemDatabase<CFolderDatabase>` (非 `...<CFolderTemplate>`)。

脚本 schema 与目录延伸:

| 目录 | def 类 | 脚本键 |
|---|---|---|
| common/doctrines/folders | CFolderTemplate | allowed / name / ledger / ledger_gfx / tab_gfx / color_frame / sound |
| common/doctrines/tracks | CTrackTemplate | name / background / background_offset / icon / icon_frame / active / progress_type / mastery |
| common/doctrines/grand_doctrines | CGrandDoctrineTemplate | folder / name / description / icon / available / xp_cost / xp_type / ai_will_do / tracks / milestones + 扁平效果键 |
| common/doctrines/subdoctrines (**递归**) | CSubDoctrineTemplate | track / allow_in_multiple_tracks / name / description / icon / available / visible / reward_gfx / xp_cost / xp_type / ai_will_do / rewards / xor + 扁平效果键 |

装载链 (def 侧只做「名字→对象」独立表化; 无一次性实例化遍历, 绑定 = 惰性按名解析):

| 阶段 | 函数 |
|---|---|
| 四目录注册 + ".txt" + 库单例 | sub_14018BB20 |
| 库对象 malloc(0x80) + 三层 vftable | sub_140171640 / sub_1401719E0 / sub_140173840 / sub_140173C40 |
| 元素建对象 (malloc sizeof + ctor) | 见 §4.6.2–4.6.9 各类 ctor |
| def→运行时主接缝 (唯一同触 grand/sub/track 三单例; 迭代 `*(DB+80)` / `*(DB+92)`) | sub_140B036C0 |
| 运行时状态 reader 内按名解析 def (folder / grand_doctrine / track / tracks 四键) | sub_140FC9020 |
| 运行时状态数组建表 | sub_140D7B8F0 / sub_140D7B4F0 / sub_1413C7830 / sub_140FC6480 |
| 子条令终结 (校验 + mastery 求值 + rewards 逐项) | sub_1409E6560 |
| CMasteryConditions 求值器 (三遍掩码扫描 → +88/+89/+90) | sub_1409E4870 |

层级与引用关系 (定案): folder ← grand (`+760` 持 folder 定义指针) → grand `+792` tracks 名表解析为
`CTrackTemplate*` 数组; **track → subdoctrine 是反向的** — subdoctrine 持 `+760` tracks 容器 {d@760, cap@768, c@772, alloc@776} (8B CTrackTemplate\* 元, 逐名查库 push), 即 subdoctrine 声明自己可放进哪些 track; subdoctrine `+784` 内联 rewards 数组; **milestones 仅 grand 有** (`+768` 内联数组, cap@776/计数@780 — Sub 无此容器, 键 16771 读弃); mastery 条件块 (CMasteryConditions) 为**内嵌**非指针 (Sub `+832` / Track `+120`)。

#### 4.6.2 CDoctrineBaseTemplate (学说 def 基类)

vtable RVA 0x142719078, sizeof 776, ctor `sub_140147250`; 基类 CDatabaseObject ← CPersistentWithToken。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | CPersistentWithToken 基字段 |
| +16 | uint64 | CDatabaseObject 持久化 id 槽 | Load wrapper sub_1424BE620 从流读 qword 直写; def 不入存档 → 运行时无写者 = **死字段** (活体读到堆残留小整数对, 不承载学说语义) |
| +24 | uint8 | 已解析标志 | Load wrapper sub_1424BE620 置 1 |
| +32 | uint32/int | **xp_cost 数值** | 键 xp_cost (19741), 整数读 sub_1424C08D0; XP 成本结算器 sub_1413CB2D0 读此槽 |
| +36 | uint32 | xp_type | 键 xp_type (16769); 枚举 {1=army, 2=navy, 3=air} (文案三键 DOCTRINE_{ARMY,NAVY,AIR}_XP_INSUFFICIENT / 槽位映射 / CCountryExperienceStatus 三槽序三方一致) |
| +40 | CString (32B) | name 本地化键 | 键 name (27) |

> **doctrine_utils 两函 (新收)**: ① **XP 类型 → 开销 define 名取数器 sub_1413C6880** (doctrine_utils.cpp:102, sret 返 std::string): 枚举 1/2/3 → `DOCTRINE_ARMY_XP_COST` / `DOCTRINE_NAVY_XP_COST` / `DOCTRINE_AIR_XP_COST` (malloc 0x20, size 21/21/20, cap 31), 其余空串 + 断言 "Unknown XP type" (闩 byte_14338A2EB, 仅警告级) — 调用方据此名查 define 取 XP 开销基值 (§4.34.9 AI XP 开销规划链的 define 源)。② **GetRandomUnlockedTactics sub_1413C6760** (:73): 国 tag → cc+3936 科技状态 → 容器 A (sub_14072DC10) {data@+0, count@+12} + 容器 B (sub_1413C6600(tag) 返对象 +40, {data@+40, count@+52} — 与本表 +40 同址, 推定 = enable_tactic 侧); 总数 0 → 断言; 自定义哈希混合 RNG 状态对 (常量 1255572915/458671337/−1831433054/1759714724, FNV 变体) 后 `&0x7FFFFFFF % 总数`, `++*a2` 推进; 两段拼接取 8B CCombatTactic* 元 (v15 ≥ A 计数 → 取 B, 否则取 A)。容器分工语义推定。
| +72 | NPdxLoc::CBoundLocalization (32B) | **description 绑定本地化** | 键 description (15906) → sub_1424C0AA0 |
| +104 | CString (32B) | icon | 键 icon (181) |
| +136 | CEffect 内嵌效果块 | **学说效果载体** (25 槽, [12] = Execute; 块内 +88 起内嵌 CModifier = def+224 / +104 mdef 查表区 = def+240 / +280 CSubUnitStatBonus 56B = def+416 / +336 战术解锁名表 = def+472 计数@def+484 / +360 equipment_bonus 源表 = def+496 门@def+508); available (12264) 亦写 +608 | |
| +224 | CModifier | 内联修正块 (扁平效果键) — CEffect+88 | ctor + reader |
| +416 | CSubUnitStatBonus (56B) | 子单位加成 — CEffect+280 | 注册经 sub_140D0E490(cc+3952) |
| +472 | 匿名结构 (24B) | 战术解锁名表 (40B 条目向量, 计数@+484) — CEffect+336 | 注册入 CCountryDoctrineStatus+40 enable_tactic 容器 |
| +520 | 匿名结构 (88B) | visible 块表数据 | 键 visible (11562) |
| +608 | 匿名结构 (88B) | available 块表数据 | 键 available (12264) |
| +696 | NDoctrines::CMeanTimeToHappen (56B) | ai_will_do | 键 ai_will_do (10819) |
| +752 | uint32 | **mastery gain factor 修正量** | Grand 写 sub_141528630 (查 mod_grand_doctrine_mastery_gain_factor) / Sub 写 sub_141528800 (查 mod_subdoctrine_mastery_gain_factor) |

⚠ `+16` 非 folder 指针 (死字段, 见表注)。folder 归属一律读 Grand 的 `+760`。
效果注册/注销 (五通道: 即时 Execute / RebuildModifiers / enable_tactic / cc+3952 子单位 / cc+3944 named_equipment_bonus 前缀 MODIFIER_DOCTRINE_PREFIX) = sub_1413CD240 / sub_1413CEE00, type 参数 3 = grand / 4 = sub / 5 = reward 档。

reader = `sub_1409CC710` (grand/sub 先试自有键, 未命中转此); 未识别键静默丢弃 (基 `sub_1424BEC40` →
`sub_1424C2060` 读弃)。writer[2] = CFG 空桩 `0x14012A2C0` → **def 不入存档**。

#### 4.6.3 CFolderTemplate (学说文件夹 def)

vtable RVA 0x142718f88, sizeof 272, ctor `sub_140147C60`; 基类同 CDoctrineBaseTemplate 的祖先链但不继承它。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | 基 |
| +24 | uint8 | 已解析标志 | ctor |
| +32 | NPdxLoc::CBoundLocalization (32B) | name 本地化键 | 键 name (27) |
| +64 | CString (32B) | tab_gfx | 键 tab_gfx (16785) |
| +96 | CString (32B) | ledger_gfx | 键 ledger_gfx (16748) |
| +128 | uint32 | color_frame | 键 color_frame (16797) |
| +136 | 匿名结构 (88B) | allowed 触发块数据 | 键 **allowed (12263)** (base 才用 12264 available) |
| +224 | CString (32B) | sound | 键 sound (441) → sub_1424C0AB0; icon (181) 键无 reader case (读弃, folder 图标走 ledger_gfx+96 / tab_gfx+64) |
| +264 | uint32 | **ledger 位标志** | 键 ledger (10354) → sub_1415280E0 位或集合: hidden=1/army=\|4/navy=\|8/air=\|0x10/civilian=\|2/military=0x1C/all=0x1E/invalid=0xFFFF |

- folder reader 无 icon (181) case (读弃); Sub 侧真 xor 键 = 12043。
- ⚠ CFolderTemplate **不继承 CDoctrineBaseTemplate**: name 在 +32 (非 +40), icon 在 +224 (非 +104), 无 xp_type。

#### 4.6.4 CGrandDoctrineTemplate (大条令 def)

vtable RVA 0x142719148, sizeof 824, ctor `sub_1401497F0`; 基类 = CDoctrineBaseTemplate。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +760 | NDoctrines::CFolderTemplate* | folder 定义指针 | 键 folder (11873), 查 CFolderDatabase 按名解析 |
| +768 | 匿名结构 (400B) | milestones 数组数据 | 键 milestones (16771) → sub_1409CD530; cap@+776, 计数@+780 |
| +784 | void* | allocator (off_143085170) | ctor |
| +792 | NDoctrines::CTrackTemplate** | tracks 数组数据 | 键 tracks (16772), 经 SUniformDatabaseReader<CTrackDatabase>; 容器头 {d@792, cap@800, 计数@804, alloc@808} |
| +816 | uint32 | max_track_rows | 键 max_track_rows (16804) |
| +820 | uint32 | max_track_columns | 键 max_track_columns (16805) |

⚠ Grand 的 `+760` = folder 指针; Sub 的 `+760` = track 指针 (**同偏移不同语义, 两族必须分别记表**)。
⚠ **milestone 数须 == track 数** (终结函数 sub_1409CDF20 断言 :47; 门 2 读 tracks 计数@+804, 门 4 要求 +780 == +804)。
ctor 只显式初始化到 +816 (`a1[95..99]` / `a1[102]`); +820 由 reader 写。

**终结函数 (vtable [8])**: Grand = **sub_1409CDF20** (func_names rtti `NDoctrines::CGrandDoctrineTemplate::[8]` 直证) — 四校验门 (断言 :34/:38/:42/:47, 含 milestone 数 == track 数) + 逐里程碑 sub_1409CCAB0 (变量键 "DOCTRINE") + +752 写入 (mastery gain factor 修正量, Grand 查 mod_grand_doctrine_mastery_gain_factor); Sub = sub_1409E6560。

#### 4.6.5 CSubDoctrineTemplate (子条令 def)

vtable RVA 0x1427192f8, sizeof 968, ctor `sub_14014B2B0`; 基类 = CDoctrineBaseTemplate。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +760 | NDoctrines::CTrackTemplate* 向量 | tracks 容器 {d@760, cap@768, c@772, alloc@776} | 键 track (139) 逐名查 CTrackDatabase push, 8B 元素; Sub 无 milestones 容器 (键 16771 读弃) |
| +784 | NDoctrines::CRewardTemplate* | rewards 数组数据 | 键 rewards (16770) 块循环逐元素产 472B 元; **前缀和取值器 sub_1409E5A50** (out, index): index<0 ∨ ≥+796 → :111「Reward index out of bounds」B51 (闩 byte_143339BC9) + out=0; 否则 Σ sub_1409E4DA0(+784+472×i), i=0..index (累计奖励, 逐级/解锁进度展示用) |
| +792 | uint32 | rewards cap | |
| +796 | uint32 | rewards 计数 | |
| +800 | void* | allocator (off_143085170) | ctor |
| +808 | 匿名结构 (24B) | xor 表 | 键 xor (12043) → sub_1403B7500 |
| +832 | NDoctrines::CMasteryConditions (96B) | 内嵌 mastery 条件块 | 键 mastery (16780) → sub_1409E5560 |
| +928 | CString (32B) | **reward_gfx** | 键 reward_gfx (16803) → sub_1424C0AB0 |
| +960 | uint8 | **allow_in_multiple_tracks** | 键 allow_in_multiple_tracks (16806) → bool 读 sub_1424C0C00 |
| track (139) | — | track 定义指针值形态门 | `*(ctx+192)==3` (裸标识符) 才解析 |

终结/校验 `sub_1409E6560`: 断言 `+772 != 0` ("Subdoctrine %s has no track assigned") 与 `+796 != 0`
("Subdoctrine %s has no scripted rewards"); 逐 rewards 元素调 `sub_1409E4DC0`; 调 vtable[8] 槽以计算
CMasteryConditions; 最后 `+752 = sub_141528800`。独有虚槽: [8] `sub_1409E6560` (终结/校验) /
[11] `sub_1409CBF20` / [12] `sub_1409E5B30` / [13] `sub_1409E60F0` / [14] `sub_1409E6530`。

#### 4.6.6 CTrackTemplate (学说轨道 def)

vtable RVA 0x142719408, sizeof 360, ctor `sub_14014B620`; 基类同 CFolderTemplate 的祖先链。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | 基 |
| +24 | uint8 | 标志 | ctor |
| +32 | 匿名结构 (88B) | active 触发块数据 | 键 active (11390) |
| +120 | NDoctrines::CMasteryConditions (96B) | 内嵌 mastery 条件块 | 键 mastery (16780) → sub_1409E5560 |
| +216 | NPdxLoc::CBoundLocalization (32B) | name 绑定本地化 | 键 name (27) → sub_1424C0AA0 |
| +248 | uint32 | progress_type | 键 progress_type (16773), **裸 token 直存** (子 token 原样, 默认 357 none) |
| +252 | uint32 | background_offset | 键 background_offset (16798) |
| +256 | CString (32B) | background | 键 background (156) |
| +288 | CString (32B) | icon_frame | 键 icon_frame (12120) |
| +320 | CString (32B) | icon | 键 icon (181) |

⚠ CTrackTemplate 的 `name` 写 +216 = CBoundLocalization 首址 (与 ctor 同址), 即 name 走**绑定本地化**而非
CString — 与 CDoctrineBaseTemplate 的 name→+40 (CString) 不同址。`frame` 键无 reader case = **读弃 (负定案)**。

#### 4.6.7 CMilestoneTemplate (里程碑 def)

vtable RVA 0x1427190f8, sizeof 400, ctor `sub_1409CD980` (**基类 = 裸 CPersistent**, 无 CDatabaseObject
/ 无 CPersistentWithToken)。**非独立命名 def 对象** — 仅作为 grand `+768` 内联数组元素存在 (Sub 无 milestones), 数组
`malloc(400*n)` + `memset(0x190)` + 逐元素 ctor; 另有拷贝式 ctor `sub_140149B70` (数组扩展用)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint64 | required_progress | 键 required_progress (16774) → sub_1424C0A70 (fixed5 标量 reader) |
| +16 | CEffect 内嵌效果块 | 触发/效果内容块 (ctor sub_14053CFD0; 条目认领谓词 sub_141529A80) | 块内 +88 CModifier = mile+104 / +104 查表区 = mile+120 / +280 CSubUnitStatBonus = mile+296 / +336 CString = mile+352 / +360 容器头 = mile+376 |
| +120 | 匿名结构 (88B) | CModifier 查表区 (CEffect+104) | ctor sub_140555FB0 |

reader `sub_1409CCA50` 仅一键 `required_progress`; 其余全部读弃。reader 首行 `sub_141529A80(a1+16)` = **CEffect 条目认领谓词** (触发器/effect 子块认领 → 返 1) — 结构 `if (!认领) { 键分派 }`, **required_progress (16774) → +8 确被处理** (认领的 token 由 CEffect 消化; 反编译丢参成单参, 三参完整形式见 base reader)。writer[2] = CFG 空桩 → 不入存档。

#### 4.6.8 CRewardTemplate (奖励 def)

vtable RVA 0x1427192a8, sizeof 472, ctor `sub_1409E5750`; 基类 CPersistentWithToken。
**非独立命名 def 对象** — 作为 subdoctrine `+784` 内联数组元素, `malloc(472*n)` + `memset(0x1D8)`; 另有
拷贝式 ctor `sub_14014ABE0`。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | reader 由名串求 token 后写 |
| +16 | CString (32B) | 串 A | ctor |
| +48 | CString (32B) | 串 B | ctor |
| +80 | CEffect 内嵌效果块 | 触发/效果内容块 (ctor sub_14053CFD0; 认领谓词 sub_141529A80; mastery (16780) → +464 确被处理) | 块内 +88 CModifier = rwd+168 / +104 查表区 = rwd+184 / +280 CSubUnitStatBonus = rwd+360 |
| +464 | uint64 | mastery | 键 mastery (16780) → sub_1424C0A70 (fixed5 标量 reader) |

reader `sub_1409E5240` 仅一键 `mastery`; 其余读弃。**不存在独立的奖励类型枚举 (负定案)**: 脚本侧
reward 条目 = 具名 + 类别/单位子块, 无 `type = xxx` 键; 引擎侧只有 name token / 2×CString /
CEffect@+80 (内嵌 CModifier/查表区/CSubUnitStatBonus) / mastery@+464。奖励的「类型」由内嵌 CModifier 的 mdef 键集合
表达, 非枚举 — 与项目/装备域的 CPrototypeRewardOption (有独立枚举) 不同。writer[2] = CFG 空桩 → 不入存档。

#### 4.6.9 CMasteryConditions (掌握条件块)

vtable RVA 0x142719258, sizeof 96, ctor `sub_140149930`; **基类 = 裸 CPersistent**。
内嵌于 CSubDoctrineTemplate@+832 与 CTrackTemplate@+120 (两处 ctor 实证)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | multiplier | 键 multiplier (10912) |
| +16 | 匿名结构 (8B) | sub_units 向量数据 | 键 sub_units (12176); 元素 32B 条件条目 |
| +24 | uint32 | sub_units 容量 | |
| +28 | uint32 | sub_units 计数 | |
| +40 | 匿名结构 (8B) | categories 向量数据 | 键 categories (11352); 元素 32B |
| +48 | uint32 | categories 容量 | |
| +52 | uint32 | categories 计数 | |
| +64 | 匿名结构 (8B) | equipment 向量数据 | 键 equipment (12110); 元素 32B |
| +72 | uint32 | equipment 容量 | |
| +76 | uint32 | equipment 计数 | |
| +88 | uint8 | 域旗·海军 (掩码 0x80004003C1) | evaluator 写 |
| +89 | uint8 | 域旗·陆 (掩码 0x408000003C) | evaluator 写 |
| +90 | uint8 | 域旗·空 (掩码 0x1F0037FC00) | evaluator 写, 求值器返回值 |

三键子解析器 (`sub_1409E2CF0` sub_units / `sub_1409E3110` categories / `sub_1409E3530` equipment)
共享骨架: 循环读块内未具名标量 → 取 token 条目 → `malloc(0x20)` 产 32B 条件条目入向量。

**单位/条件匹配谓词 sub_1409E4070** (定案) = 三表或匹配: sub_units 按 def+8 名 token / categories 按 def+1288 类指针 / equipment 按 def+1448 位域 AND 条件掩码 (三偏移与 §4.18 定案吻合)。

**单位侧掌握度链 (定案)**: 域旗 (+88海/+89陆/+90空) 门控三军 xp 条目聚合 → 每 track daily_mastery (驱动点 sub_140FC8DC0 前半段 → sub_141A32E90 → track+40):
- **陆 (sub_1409E3C20)**: 师掌握度 = `100000 × Σ(权重[i]×manpower_i) / (100000 × Σ(manpower_i × 计数_i))`; 权重向量在**师宿主 +928** (平行模板营表, 计数门 vs 模板+180; 断言 mastery_conditions.cpp:118/:126/:140); 模板取值**优先 old_template (+960) 回退 template (+952)**; 营表 = 模板 d+168 平铺表 (16B 元)。⚠ 分子缺 ×计数_i — 两读法 (权重向量已含计数聚合 vs 引擎漏乘) 待同型多营师探针区分 (U1); :140 "Matching manpower exceeds total" 断言为该不变量的护栏。
- **海 (sub_1409E3F50)**: 遍舰队船列, 价值 = 100000×ship+2056, 匹配 `cond, ship+128`。
- **空 (sub_1409E3A30)**: 遍航空队装机表, 价值 = 数量×装备因子, 匹配 `cond 装备位掩码 & 装备+1032` (跳过前导 count==0 空槽)。
- **日聚合归一化 (sub_141A32AD0 尾部)**: 有效日增益 = `(MAX_MONTHLY_MASTERY_GAIN/30) × cur/(cur + BASE_MASTERY_GAIN_TARGET_MANPOWER)`, cur = v4/24; 常量 3000000 = 30×1e5 / 2400000 = 24×1e5 量纲已核; 乘 TRAINING_MASTERY_GAIN_FACTOR。
- **define 全局真名** (均 sub_142072500 注册落名): qword_143334028 = TRAINING_MASTERY_GAIN_FACTOR / qword_143334110 = MAX_MONTHLY_MASTERY_GAIN / qword_143333F48 = BASE_MASTERY_GAIN_TARGET_MANPOWER / qword_143333060 = DOCTRINE_SHARING_BASE_MASTERY_GAIN_MONTHLY / qword_143333110 = DOCTRINE_SHARING_MONTHLY_MASTERY_GAIN_PER_COMMANDER。
- **XP 不足消费门 sub_1413CC990** (a2=0 干跑): `es` 换算 Q15→1e5 后 `*es < 100000×xp_cost`。

求值链 (定案): 装载期三键各建 token 集合向量; 终结期由 CSubDoctrineTemplate 终结函数
`sub_1409E6560` 经 vtable[8] 槽调 evaluator `sub_1409E4870`; 三遍扫描各持一个**领域位掩码**
测试元素对象的标志字段 (一律读 `obj+1448`; categories 组对象双层 `*(vec)+68` 计数 →
`*(vec+56)` 子向量): 第 1 遍陆掩码 `0x408000003C` 写 +89 / 第 2 遍海军掩码 `0x80004003C1`
写 +88 / 第 3 遍空掩码 `0x1F0037FC00` 写 +90 并返回。掩码位词表 = §4.34.9 category 位表。

组覆盖矩阵 (lua_verify 覆盖文件改 def 重载活体实证):

| 域旗 | categories (+40) | equipment (+64) | sub_units (+16) |
|---|---|---|---|
| +89 陆 | 实证 (category_all_infantry 等) | 实证 (type 名 infantry 入 track mastery 翻旗) | 实证 (infantry / armored_car) |
| +88 海军 | 未测 (无海军 category 名可用) | 实证 (capital_ship) | 实证 (carrier / destroyer) |
| +90 空 | **实证不扫** (category_fighter 入 categories 不翻旗) | 实证 (fighter / interceptor) | 未测 (无空型 sub_unit) |

- 配置面实测: **subdoctrine 语境 mastery 的 equipment 键报错** "Invalid equipment
  category: equipment" 且整块 mastery 被弃 (track 语境同键正常) —— equipment 域掌握
  条件只能配在 track mastery。equipment 组取值词表 = type 名 (§4.34.9; track 实证接受
  infantry / fighter / capital_ship 等), 非装备原型名。

#### 4.6.10 NDoctrines def 侧 writer/reader 槽总表

| 类 | vtable (RVA) | writer[2] | reader[4] | Load wrapper[3] | 入存档 |
|---|---|---|---|---|---|
| CDoctrineBaseTemplate | 0x142719078 | 0x14012A2C0 (CFG 空桩) | sub_1409CC710 | sub_1424BE620 | 否 |
| CFolderTemplate | 0x142718f88 | 0x14012A2C0 (CFG 空桩) | sub_1409CBE40 | sub_1424BE620 | 否 |
| CGrandDoctrineTemplate | 0x142719148 | 0x14012A2C0 (CFG 空桩) | sub_1409CE150 | sub_1424BE620 | 否 |
| CSubDoctrineTemplate | 0x1427192f8 | 0x14012A2C0 (CFG 空桩) | sub_1409E6770 | sub_1424BE620 | 否 |
| CTrackTemplate | 0x142719408 | 0x14012A2C0 (CFG 空桩) | sub_1409E6CB0 | sub_1424BE620 | 否 |
| CMilestoneTemplate | 0x1427190f8 | 0x14012A2C0 (CFG 空桩) | sub_1409CCA50 | sub_1424BE690 | 否 |
| CRewardTemplate | 0x1427192a8 | 0x14012A2C0 (CFG 空桩) | sub_1409E5240 | sub_1424BE690 | 否 |
| CMasteryConditions | 0x142719258 | 0x14012A2C0 (CFG 空桩) | sub_1409E4B30 | sub_1424BE690 | 否 |

全族 writer = CFG 空桩 `0x14012A2C0` + 槽 [5] `sub_14011D220` (return 0) → **def 侧 8 类全部不入存档**。
槽 [1] = `sub_1424BEC50` (Save wrapper) 全族同址; 槽 [3] 分两支: 有 CDatabaseObject 的用 `sub_1424BE620`,
裸 CPersistent 的用 `sub_1424BE690` (与 §4.00.1 吻合)。

#### 4.6.11 NDoctrines def 侧键→偏移映射总表

| 类 | 键 (token id) | 目标偏移 |
|---|---|---|
| CDoctrineBaseTemplate | name (27) | +40 |
| | description (15906) | +72 |
| | icon (181) | +104 |
| | xp_type (16769) | +36 |
| | xp_cost (19741) | +32 |
| | available (12264) | +608 |
| | visible (11562) | +520 |
| | ai_will_do (10819) | +696 |
| CFolderTemplate | name (27) | +32 |
| | tab_gfx (16785) | +64 |
| | ledger_gfx (16748) | +96 |
| | color_frame (16797) | +128 |
| | allowed (12263) | +136 |
| | sound (441) | +224 |
| | ledger (10354) | +264 |
| CGrandDoctrineTemplate | folder (11873) | +760 |
| | milestones (16771) | +768 (cap@+776, 计数@+780) |
| | tracks (16772) | +792 |
| | max_track_rows (16804) | +816 |
| | max_track_columns (16805) | +820 |
| CSubDoctrineTemplate | track (139) | +760 容器 {d@760, c@772} |
| | rewards (16770) | +784 |
| | xor (12043) | +808 |
| | reward_gfx (16803) | +928 |
| | allow_in_multiple_tracks (16806) | +960 |
| | mastery (16780) | +832 |
| CTrackTemplate | name (27) | +216 CBoundLocalization (定案) |
| | active (11390) | +32 |
| | icon (181) | +320 |
| | icon_frame (12120) | +288 |
| | background (156) | +256 |
| | background_offset (16798) | +252 |
| | progress_type (16773) | +248 |
| | mastery (16780) | +120 |
| CMilestoneTemplate | required_progress (16774) | +8 (定案: CEffect 认领谓词门方向 = 未认领才进键分派) |
| CRewardTemplate | mastery (16780) | +464 (同上定案) |
| CMasteryConditions | multiplier (10912) | +8 |
| | categories (11352) | +16 |
| | equipment (12110) | +40 |
| | sub_units (12176) | +64 |

#### 4.6.12 NDoctrines 学说域随族类未决项

| 类 / 项 | 判定 |
|---|---|
| CMasteryTrigger / CHasCompletedSubdoctrineTrigger / CHasDoctrineTrigger / CDoctrineTrackCompletedTrigger / CHasSubdoctrineInTrackTrigger / CHasMasteryLevelTrigger / CHasCombatTacticTrigger / CHasGrandDoctrineInFolderTrigger | trigger 族, 归 §4.32 |
| CSetGrandDoctrineEffect / CSetSubDoctrineEffect / CAddDailyMasteryEffect / CAddMasteryBonusEffect / CAddMasteryEffect / CUnlockCombatTacticEffect / CUnlockSubUnitEffect | effect 族, 归 §4.32 |
| CUnlockGrandDoctrineCommand / CUnlockSubDoctrineCommand | command 族, 归 §4.33 |
| NUtils::USAdvisorDoctrineBonus / USMasteryFromUnitLeader / USMaxSubdoctrineMastery | 静态资源布局, 归 §4.26 |
| CGroupBtn | **非学说类 (负定案)** — 唯一存在者是 NCombatLogView::CGroupBtn (战斗日志视图); 学说侧 entry 按钮 = entry_button.cpp GUI 宿主 (无独立 RTTI; 宿主函数 sub_141D23680, 字段 +1408 tag/+1416 子列表容器/+1424 关联窗/+1432 folder def) |

#### 4.6.13 学说树维护链 (写者族 + 调度)

维护链 (定案; 容器挂点 = doc = *(gs+1024) CDoctrineSystem, 国家条目 data@doc+8/count@doc+20, 160B stride, tag 定位器 sub_140D7DAC0):

| 环节 | 函数 | 要点 |
|---|---|---|
| XP 成本门 | sub_1413CB2D0 | `def+32 xp_cost × (1 − cost_reduction 折扣)` (折扣源 CCountryDoctrineStatus+64 容器, sub_1413CB6D0 读); 玩家/AI 共用 (AI 评分 sub_1413CBB60 = 三参糖) |
| Execute 入口 | 0x141A7BF90 (CUnlockGrandDoctrineCommand::IsValid) → sub_1413CCBA0 / 0x141A7C1B0 (CUnlockSubDoctrineCommand::IsValid) → sub_1413CBDB0 + sub_1413CCD80 独立链 | 已选查重 (任一 folder+16 == 该 grand → 拒) → available 求值 (def+608 块 vtable+24) → Set 链 |
| 换 grand | sub_140FC6A20 SetGrandDoctrine | 逐 track Clear → 按新 grand def+804 槽数补建 CTrackStatus (track+80 = CCountryDoctrineStatus* 回指 / +88 = CFolderStatus* 回指 — 断言串 "Country/Folder status pointer is invalid" 两端直证, 闩 byte_14338A503..A507 五站) → folder+16 = 新 def → 旧注销 sub_1413CEE00(type3) / 新注册 sub_1413CD240(type3) → UI 通知 |
| 换 sub | sub_14147C8A0 SetSubDoctrine | mastery_bank (track+32) 存量保存 → Clear → track+8 = 新 def → 注销/注册 type4 → sub_14147C000 存量重结算 (换学说保留已攒掌握度) |
| 清空 | sub_14147C650 Clear | +16 rewards / +24 mastery / +32 mastery_bank 清零; 逐奖励档注销 type5 |
| mastery 推进 | sub_14147C000 AddMastery | `track+24 += 增量`; 逐 reward 门槛消耗制 (门槛 = def 档条目+464, 零回退 define qword_143333E60, 经 sub_1409E4DA0; 累计 ≥ 门槛 → 档数++ 且累计 −= 门槛); 档数变化 → sub_14147CB00 发放 (type5 注册 + UI 消息); 全档完成 (track+16 == def+796) → sub_140FC87B0 完成通知 |
| mastery 汇入 effect | sub_1413CDA80 (STrackFilter 匹配: 逐 track sub_140FC8670 读 filter 五字段测试) + sub_1413CD100 (单 track def 或全量汇入) | 逐命中 track AddMastery; 无命中报 "Failed to add mastery to any tracks" |

调度: 日边界 CDoctrineSystem::DailyUpdate sub_140D7ED90 (tbb 两遍遍国家条目) + 串行收尾逐国 sub_1413CCF90: ① 逐 folder sub_140FC7EB0 folder 日步 — track def active 触发器门 (sub_1409E6B80) → track+72 每日 mastery 产出值 >0 灌入 (完成判定 = sub_14147C2A0; 完成或无 def → sub_14147BFD0 衰减支路, 未完成 → sub_14147C000 正常灌入); ② daily_mastery 容器 (+88, 112B 元) 逐条 `--days` + 到期紧凑删除。月边界 sub_140D7F220 (仅玩家国)。

#### 4.6.14 学说选择列表行件族 (doctrine_selection_items.cpp; 6 函闭环 — info policy 策略对象 / CDoctrineListItem 全布局 / tooltip 详略开关)

簇清册 (体内 cpp 锚 6/6; 书内原仅 def 五锚零 VA 覆盖 — 本簇 6 锚即书 def 锚的出处函):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141F381E0 | 34 | :50 断言 "Invalid track index" (B51, 闩 byte_14338CA1B) | track 进度查询包装 |
| sub_141F39550 | 48 | :413 断言 "No doctrine info policy set…" (闩 byte_14338CA20) | info policy vtable[0] 文本查询包装 (出串可空 = 干跑判定) |
| sub_141F3A1B0 | 46 | :427 同文案断言 (闩 byte_14338CA21) | info policy vtable[1] 五参查询 (返 int = XP 成本) |
| sub_141F3B220 | 39 | :398 断言 "Failed to access settings" (闩 byte_14338CA1F) | tooltip 详略开关切换 (ctx+4176 取反 → settings+624 同步写回) |
| sub_141F39660 | 460 | :97 断言 "Invalid doctrine in selection list" (闩 byte_14338CA1C) | tooltip 组装器 (键分派双路; 宿主类未定名, def 在 +1416 异于行件 +1440) |
| sub_141F3A6C0 | 316 | :179 断言 "Invalid doctrine assigned to doctrine list item" (闩 byte_14338CA1D) | CDoctrineListItem::Update 行刷新器 |

**info policy 策略对象 (新定案)**: 学说选择列表持 +4160 当前学说 def / **+4184 info policy 对象指针** (未设 = 两查询断言返 0 非致命)。接口至少两槽: vtable[0] = (policy, 国解析件, def, *(列表+1416), char, out 串*, *(列表+1476)) → bool — 学说可用性/文本查询, **出串传 0 = 干跑** (仅判可用); vtable[1] = (policy, 国解析件, def, *(列表+1416), int) → int — XP 成本查询。国取数链 = 列表+8 对象取 tag → sub_140BB5490 → idpair → sub_1413C6600。

**CDoctrineListItem 全布局** (ctor sub_141F383E0, RTTI 名 `NDoctrines::CDoctrineListItem` 直出; 书 def 五锚全部在本簇直证 — +1440 def 本体直证即 :179 断言): +0/+24 双 vtable / +32 CDoctrineSelectionList* / +40 基子对象 / +1408 名称文本件 / +1416 成本按钮件 / +1424 gfx 处理器 (vtable 槽 91 传 def+104 帧, 槽 81/82 可用双态) / **+1440 学说 def 指针** / +1448 可用旗字节 (强制不可用门) / +1456/+1464 顾问槽 0/1 容器件 / +1472..+1488 文本三件 (ctor 清零)。点击 lambda 全名直出 (回带 def 与 bool)。
**NDoctrines::CDoctrineSelectionList 构造器 = 0x141F38BC0** (387 行, sizeof 4192B = 0x1060 malloc 直证; 簇名甄别: lection_items.cpp = **doctrine_selection_items.cpp 断行伪影**, :248 拼合直证; 定案): 构造点 = 学说 UI 窗 SetupContent (查 "doctrine_selection_list" 容器 → 构造 → 存窗 +744 → sub_141F3A2B0 初始化; 旧值非空先经 vtable+8 释放)。布局: +8 上下文 (ctor a3) / +16 title_text / +24 description_text / +32 宿主窗 (其 vtable+552 槽以自身注册回调通道) / +40 list_container / +48 doctrines_grid / +56 close / +1424 unlock / +2792 details 三 CButtonWrapper (三 lambda 统一签名 `(CContainerWindow*, NDoctrines::CFolderView*)`) / +4176 byte = settings 单例 (sub_1401FA5E0) +624 设置旗拷贝 (details 初始态; 取不到 → :248 `Failed to get settings instance` 断言, latch byte_14338CA1E, B51 门) / +4160/+4168/+4184 零初始化槽。

**NDoctrines 阵营学说共享窗 (faction_doctrine_sharing_window.cpp — 簇名 octrine_ 系 `faction_d|octrine_sharing_window.cpp` 断行伪影第 4 例, 首例断在字符串字面量拼接处; diplomacy/factions/ui/; 4 函闭环, 定案)**: 窗对象 +8/+1376 tooltip 双目标 / +16 FACTION_UPGRADE_DOCTRINE_BONUS 文本 / +24 FACTION_TOTAL_SUBDOCTRINES 文本 / +32 gridbox / +40/+44 阵营 CID / +2752 CFaction* / +2760 共享激活旗 / +2764/+2768 主门 CID / +2776 选中条目 / +2784 条目激活旗 / +2788/+2792 条目阵营 CID。**tooltip 主构建器 0x141BFBB60** (920 行): CID 门 :50 断言 (latch byte_14338C411) → folder 标题/激活态双文案 (色参 3932160/13369344) → 共享明细 = sub_141BFB400 收集 **NDoctrines::NUtils::SMaxSubdoctrineMastery 24B 条目**向量 (CPdxHybridInlineBufferAllocator<型, 20, int> RTTI 直证; 归并 170 阈 §3.2a 同款) × doctrine 加成库单例 qword_14332EEB8 (+80/+92) 双层循环 → 逐加成四参 FACTION_DOCTRINE_SHARING_ACTIVE_BONUS {COUNTRY_FLAG/SUBDOCTRINE_NAME/TRACK_NAME/MASTERY (值 9 = 定点格式码)}; 解锁按钮分支 = sub_141BFBA20 判定 (gs+1312/1316 initiative 双槽主非正取备 → 对象 +72 ≥ 需求 qword_143332FB0) → FACTION_UNLOCK_DOCTRINE_SHARING(_CANNOT) + FACTION_UPGRADE_NOT_ENOUGH_INITIATIVE {VALUE = qword_143332FB0}。**三目标分派 0x141BFCBA0**: folder 汇总 (静态 folder 表 × 阵营成员 +88/+100 逐国计完成数) / 升级加成 (**qword_143333110 = DOCTRINE_SHARING_MONTHLY_MASTERY_GAIN_PER_COMMANDER** 定点 > 0 时附 INCREASE_PROMPT; 旧俗称 BONUS_PER_COMMANDER) / 默认标题。**条目装配回调 0x141BFD7E0**: 选中 vtable+128 + 条目 +117 |= 0x10 (取消 &= ~0x10 + vtable+120 双写); 解锁按钮 VALUE = 'H'(可解锁)/'R'(不可) 单字符热键提示; 控制器 vtable+648/+656 启禁用。**列表填充 0x141BFDD70**: 阵营 +2224 = doctrine sharing 运行时区 (+2232 data/+2244 count = 已解锁 folder 指针数组, 线性查命中 = 已解锁旗); gridbox 池不足 malloc 2800 + sub_141BFB500 构造 (条目类 NDoctrines::CRewardItem RTTI 旁证), 越池断言 gridbox.h:654 (byte_14338A4FF); 多余条目 memmove 紧缩 + vtable[0](1) 释放; 尾 FACTION_TOTAL_SUBDOCTRINES 汇总 + 刷新。**gridbox 控件布局 (定案)**: +368 列 / +372 行 / +384 纵排旗 / +392 位置对数组 {8B = row+col 双 dword} / +416 元素指针数组 — 与 §4.31.112 stations_grid 同构互证。TU latch 块 = byte_14338C411..C414。

**阵营共享增益逻辑层 (faction_doctrine_sharing.cpp — diplomacy/factions/ 下逻辑层, 与上述 UI 窗 CU 不同编译单元)**: 增益 = `DOCTRINE_SHARING_BASE_MASTERY_GAIN_MONTHLY (qword_143333060) + DOCTRINE_SHARING_MONTHLY_MASTERY_GAIN_PER_COMMANDER (qword_143333110) × 有指挥官的阵营战区数` (sub_141BE5A90)。⚠ 局部键名 NUM_COMMANDERS / 全局名 ..._PER_COMMANDER 指**阵营战区已指派指挥官的数量** — 计数源 = CFactionTheaterManager 战区列表里指挥官 CRef 非零且可解析的条目 (§4.5 CFactionTheaterManager commander 元素 = 8B 内联 CRef id-pair, sub_141950A80 判非零后 sub_14221F310 解引用), 非阵营成员国数、非指挥官总数。消费侧 = 上述 GUI 窗 (a3=0 干算路径) + 阵营逻辑层月更。

**Update 七步** (sub_141F3A6C0): def 空 → :179; 可用判定 = +1448 门 ‖ policy vtable[0] 干跑 (不可用加前缀 TRIGGER_UNFULLFILLED_PREFIX); 名称 = def+40 (书互证) → 写 +1408; gfx = def+104 (书互证) + 槽 81/82 双态; 成本 = policy vtable[1], ≤0 或强制不可用 → +1416 钮隐藏; 顾问槽 = **SAdvisorDoctrineBonus 16B 元 {顾问 id, 活性旗}** 向量 (sub_1413C61D0 填充) → 槽 0/1 按计数显隐 + GUI 上下文工厂 (qword_14332F698+1272, §4.11.25 同款) 绑行; 成本文本 = xp 类别 **def+36** (书互证), **可负担门 = 国 XP ≥ 100000 × 成本 (fixed×1e5)**。

**tooltip 双路** (sub_141F39660): 键 +1392 → XP 刷 + 主文本 (干跑) + 104B 元数组构造 + def vtable 槽 12 成本文本 + policy **vtable 槽 13 (带统计数组, 详略开关开) / 14 (简版)** 二分支 + 尾注 DOCTRINE_DETAILS_BUTTON_PROMPT + CSubDoctrineTemplate 子条令附加文本; 键 +1448 → 顾问掌握 tooltip (ADVISOR_DOCTRINE_FAVOR/NAME + ADVISOR_MASTERY_GAIN_POTENTIAL/ACTIVE 二选一)。

**track 包装** (sub_141F381E0): track_idx == −1 → :50 断言; 否则状态链查询 — **学说状态对象 +16 = 80B/条元素数组, 计数 +28, 条目+8 = track def 指针** (线性扫匹配; §4.6 状态对象补行互证)。

未决: tooltip 宿主类定名 / policy 对象装填者 / settings+624 设置项名 / 顾问行绑定第 4 参语义。

#### 4.6.15 大型学说 UI 轨道条目 (doctrines\ui\track_item.cpp; 5 函闭环 — NDoctrines::CTrackItem 运行期)

#### 4.6.16 教条文件夹视图刷新 (folder_view.cpp; 1 函 = sub_141CC5AF0, 高置信/谓词推定)

sub_141CC5AF0: 门 = a1+1416 教条文件夹对象 (空 → :208 纯日志「Invalid doctrine folder in folder view」, 闩 byte_14338C4FE); 归属国判定链 = 文件夹 a1[1]+2800 tag → sub_140BB5490 归一 → sub_1413C60B0 取国 → sub_1413CBB70(国, &out_bool, 文件夹, 0) 谓词 (推定 = 「该文件夹对当前国有费用减免可显」)。**显隐元件 = a1+1448** (UI 对象 @+48; 谓词真 → Show = vtable+120 并清 byte+165 bit4 / 假 → Hide = vtable+128 并置 bit4); 谓词真额外取本地化 sub_1402E31F0(buf, "DOCTRINE_COST_REDUCTION_VALUE", "VALUE", &谓词) → sub_1422CA920 写 a1+1456 文本件; 尾三连 sub_141CC36C0 → sub_141CC5C40 → sub_141CC5E40。显隐对律与 §4.27 / §4.35.37 同族。

CU = `hoi4\source\doctrines\ui\track_item.cpp` (5/5 函断言串一致); RTTI 直证 `NDoctrines::CTrackItem` (继承 CStandardGridBoxItem, _RTDynamicCast 判型直证)。同命名空间家族 RTTI: CDoctrineListItem / CFolderTabItem / CFolderStatus / CCountryDoctrineStatus / **CGrandDoctrineDatabase (TGameItemDatabase 族)** / CTrackTemplate / **CRewardItem** / CDoctrineSelectionList / CDoctrineBaseTemplate / STemporaryCostReduction。周边 define = NDoctrines.BASE_MASTERY_GAIN_TARGET_MANPOWER / MIN_MASTERY_GAIN_PER_DAY。

五函身份表:

| VA | 行数 | 身份 |
|---|---|---|
| 0x141F35370 | 644 | 精通 (mastery) tooltip 构建器 (头两段文本 a2/a2+32) |
| 0x141F36330 | 581 | 子学说槽 tooltip 构建器 (未分配/未激活/里程碑/收益; 尾调 0x141F35370) |
| 0x141F37980 | 433 | 轨道 → GUI 绑定刷新 (列表数据 + 逐控件 vtable[91] 写值槽) |
| 0x141F370A0 | 414 | 奖励网格刷新 (网格元逐个 _RTDynamicCast → CRewardItem 按状态刷新) |
| 0x141F36F50 | 31 | GetTrack: 索引(+32) → 轨道对象 (容器 +72 → data@792/count@804 指针向量; 越界 :614 断言返 0) |

精通 tooltip 键流 (定案, 函数体串直证): 情报不足 (folder 状态 ∈ {0,3}) → 单段 DOCTRINE_MASTERY_INSUFFICIENT_INTEL; 轨道未激活 → DOCTRINE_TRACK_NOT_ACTIVATED; 正文分流 = 有储备银行 (+1552) 或预览旗 (+1560) → MASTERY_INITIAL_FROM_RESERVE {VALUE} / 银行有值 → DOCTRINE_CURRENT_BANKED_MASTERY {VALUE} / 否则 DOCTRINE_CURRENT_MASTERY {VALUE} (现值 sub_141F36060); 激活 → MASTERY_GAIN_EXPLANATION {TRAINING_RATE = qword_143334028}; 未激活无旗 → MASTERY_BANK_EXPLANATION_EMPTY/_FULL {PERCENT ×2 = qword_143334480 / unk_1427CBDE8(9) / qword_143334558} (判满 sub_14147C2A0); 兜底 TRACK_INACTIVE_EXPLANATION。子学说槽键 = NO_SUBDOCTRINE_ASSIGNED / ASSIGN_SUBDOCTRINE_AFTER_GRAND_DOCTRINE / SELECT_SUB_DOCTRINE_PROMPT / SUBDOCTRINE_BENEFIT_DESCRIPTION / DOCTRINE_MILESTONE_TITLE / DOCTRINE_REWARD_ACTIVE / MILESTONE_UNLOCK_EXPLANATION 等。绑定刷新: "DOCTRINE_COST_REDUCTION_VALUE" 变量块; 轨道字段 +256/+272 → 控件@+1504 / +288/+304 → @+1488 / +320/+336 → @+1480 (vtable[91] = 通用写值槽); 奖励网格 = +1464 对象 {count@404, 元素@416, size@428} (gridbox.h:654 断言)。

本地化变量元素 = 104B {i32 类型@0 (9 = 浮点), const char* 名@8, 值…}, 经 eh vector constructor iterator 构表 → sub_142245E60(&out, 键, 表, n) → sub_140129C10 追加 + sub_1424CB5C0 换行; 状态位 |= 值为 EH 簿记位图非业务旗。条目对象部分布局 (消费点实测, 形态级): +32 轨道索引 / +48 学说上下文主 (+1416 当前国家钩) / +56 列表数据控件 / +64 按钮包装 (buttonwrapper.h vtable[71] IsNullObject) / +80 附加控件 (vtable[81]) / +1464 奖励网格 / +1480/+1488/+1504 三值控件 / +1552 储备银行对象 (推定待裁) / +1560 预览旁路旗。a1−24 互调形态 = 两 tooltip 函收条目内层视图 (内层 +48/+72 ↔ 外层 +24/+48, 偏移差 24)。
