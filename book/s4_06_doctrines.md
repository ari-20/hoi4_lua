> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.6 NDoctrines (学说族)

本族分两侧: 运行时侧 (`CDoctrineSystem` / `CCountryDoctrineStatus` / `CFolderStatus` / `CTrackStatus` /
`STemporary*` / GUI 件, 见 §4.6 正文) 与 **def 侧** (静态定义库, 见 §4.6.1–4.6.12)。
def 侧八类全部不入存档 (writer = CFG 空桩)。

**CDoctrineSystem**: `doc = *(gs + 1024)`。国家条目容器: data@doc+8,
count@doc+20, stride 0xA0, 元素按国家 idx 排列。

**CCountryDoctrineStatus** (vtable RVA 0X29653F8, writer 0X1413CF470; 0xA0 字节):

| 偏移 | 类型 | 名称 | 语义 | 上界 |
|---|---|---|---|---|
| +8 | — | country | TAG 写入 (sub_140BB59C0) | |
| +16 | 匿名结构 (80B) | folders 容器数据指针 | {data, count}; 元素内联 80B | count<16 |
| +17..+27 | — | = folders 容器 {data@16, **cap@24**, count@28, alloc@32} 的 data 尾 (17..23) + cap@24 (pdx 24B 通式) |  |  |
| +28 | u32 | folders 容器计数 |  | count<16 |
| +29..+39 | — | = folders count@28 尾 (29..31) + **alloc@32**  |  |  |
| +40 | CCombatTactic* | enable_tactic 容器数据指针 | {data, count}; 元素 8B 指针 → token@目标+152 | <64 |
| +41..+51 | — | = enable_tactic 容器 {d@40, **cap@48**, c@52, alloc@56} 的 data 尾 + cap@48  |  |  |
| +52 | u32 | enable_tactic 容器计数 |  | <64 |
| +53..+63 | — | = enable_tactic count@52 尾 + **alloc@56**  |  |  |
| +64 | 匿名结构 (64B) | cost_reduction 容器数据指针 | {data, count}; 元素内联 64B | <64 |
| +65..+75 | — | = cost_reduction 容器 {d@64, **cap@72**, c@76, alloc@80} 的 data 尾 + cap@72  |  |  |
| +76 | u32 | cost_reduction 容器计数 |  | <64 |
| +77..+87 | — | = cost_reduction count@76 尾 + **alloc@80**  |  |  |
| +88 | 匿名结构 (112B) | daily_mastery 容器数据指针 | {data, count}; 元素内联 112B | <64 |
| +89..+99 | — | = daily_mastery 容器 {d@88, **cap@96**, c@100, alloc@104} 的 data 尾 + cap@96  |  |  |
| +100 | u32 | daily_mastery 容器计数 |  | <64 |
| +101..+111 | — | = daily_mastery 计数尾 + 容器头 |  |  |
| +112 | 匿名结构 (24B) | **equipment_bonus 容器** {data@112, cap@120, **count@124**, alloc@128} | writer 0X1413CF470 块尾第五段; 条目 24B **SDoctrineEquipmentBonusHandle** (vt 0X2965210): {vt@0, id lexer token u32@+8 (装备原型名, token 串发射不带引号), index u32@+12 (调用方 ordinal: 选中路径 0/track 跨档序号/milestone 序号), equipment_bonus u32@+16 (国家 named_equipment_bonus 库槽位号, sub_140E60110 经 last_named_equipment_bonus 递增分配, 非加成数值), pad@20}; 块门 = count≠0 (零容器连键带体不写), 条目无逐条门 0 值照写 (MD towed_gun_equipment index=0 bonus=0 实证); +136..+159 第六个 24B 容器 = 运行时不序列化 | count≠0 |

GUI: NDoctrines::CCountryDoctrineView — folders 容器消费 (target = +1408 scopedptr 子控制器 CFolderView 族; folder 库容器命中; folder 模板 token 12989 跳过门)。

**CFolderStatus** (vtable 0X29653A8; 80B):

| 偏移 | 类型 | 名称 |
|---|---|---|
| +8 | — | folder 名 (指针→对象→token@+8 转名) |
| +16 | — | grand_doctrine 名 (同上) |
| +24 | 匿名结构 (96B) | tracks 容器数据指针 — {data, count}; 元素内联 96B (count<64) |
| +25..+35 | — | = tracks 容器 {d@24, **cap@32**, c@36, alloc@40} 的 data 尾 + cap@32 (元素内联 96B) |
| +36 | u32 | tracks 容器计数 |

**CTrackStatus** (vtable 0X2965358; 96B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | NDoctrines::CSubDoctrineTemplate* | sub_doctrine 名 (指针→token@+8); def 对象 |
| +16 | uint32 | rewards |
| +24 | fixed×1e-5 | mastery |
| +32 | fixed×1e-5 | mastery_bank |
| +40 | fixed×1e-5 | daily_mastery |
| +48 | 匿名结构 (24B) | leaders_daily_mastery 容器数据 — {data@+48, count@+60} 24B 元 (writer 0X14147CD00) |
| +49..+59 | — | = leaders_daily_mastery 容器 {d@48, **cap@56**, c@60, alloc@64} 的 data 尾 + cap@56 (24B 元) |
| +60 | u32 | leaders_daily_mastery 容器计数 |

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
| +40 | **内嵌 NDoctrines::STrackFilter (48B, vt 0X1427CFC00)** | filter 对象 vtable — ⚠ dm+40 非 {data,count} 容器; dm+48/52 是定义指针, 按容器 data/count 读即错; 布局见下表 |
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

**CDoctrineListItem / CDoctrineSharingFolderItem (学说行件, GUI)**: CDoctrineListItem = CDoctrineSelectionList 学说行: **def 本体 @+1440** (assert 铁证); **def 侧三偏移定案: def+40 = name / def+104 = gfx / def+36 = XP 类别**; 选中帧由宿主 0X141F3AC50 管理 (dynamic_cast 钉死共享基 = CStandardGridBoxItem)。CDoctrineSharingFolderItem = 学说共享文件夹行: **folder def @+2776 (def+96 = icon gfx)**; 共享态 @+2784 驱动 lock_icon/unlock_button 显隐 + 成本着色 (FACTION_UNLOCK_BUTTON); 命令出口 = **CUnlockFolderDoctrineSharingCommand {+40 / +48}**。

#### 4.6.1 NDoctrines def 侧族总览

脚本目录 `common/doctrines/{folders,tracks,grand_doctrines,subdoctrines}` 对应四个 def 库, 全部
**PR 形态** (`CPersistentReloadableGameItemDatabase`), 单例槽存库对象指针 (`malloc(0x80)`, 128B)。
装载器 = `sub_14018BB20` 内连续四段 (目录串 + `+40 = ".txt"` 后缀)。

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
| common/doctrines/tracks | CTrackTemplate | name / background / background_offset / icon / icon_frame / active / mastery |
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
`CTrackTemplate*` 数组; **track → subdoctrine 是反向的** — subdoctrine 持 `track` 指针 (`+760`), 即
subdoctrine 声明自己可放进哪个 track; subdoctrine `+784` 内联 rewards 数组; grand/sub 各自 `+768` 内联
milestones 数组; mastery 条件块 (CMasteryConditions) 为**内嵌**非指针 (Sub `+832` / Track `+120`)。

#### 4.6.2 CDoctrineBaseTemplate (学说 def 基类)

vtable RVA 0x142719078, sizeof 776, ctor `sub_140147250`; 基类 CDatabaseObject ← CPersistentWithToken。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | CPersistentWithToken 基字段 |
| +16 | uint64 | 未定 | 基 ctor 不置; 实读为小整数对 (非指针) — 未决 |
| +24 | uint8 | 已解析标志 | Load wrapper sub_1424BE620 置 1 |
| +32 | CString (32B) | description | 键 description (15906) |
| +36 | uint32 | xp_type | 键 xp_type (16769) |
| +40 | CString (32B) | name 本地化键 | 键 name (27) |
| +72 | NPdxLoc::CBoundLocalization (64B) | 绑定本地化 | ctor sub_140147000 |
| +104 | CString (32B) | icon | 键 icon (181) |
| +136 | CAndTrigger (104B) | available 触发块 | 键 available (12264) 亦写 +608 |
| +224 | CModifier (192B) | 内联修正块 (扁平效果键) | ctor + reader |
| +472 | 匿名结构 (24B) | 容器 A 头 | ctor sub_14011DF40 |
| +496 | 匿名结构 (24B) | 容器 B 头 | ctor |
| +520 | 匿名结构 (88B) | visible 块表数据 | 键 visible (11562) |
| +608 | 匿名结构 (88B) | available 块表数据 | 键 available (12264) |
| +696 | NDoctrines::CMeanTimeToHappen (56B) | ai_will_do | 键 ai_will_do (10819) |
| +752 | uint32 | 计算值 | SubDoctrine 校验后写 (sub_141528800) |

⚠ `+16` 非 folder 指针: 基 ctor `sub_140147250` 未对它写入, 且活体实读为小整数对
(如 `0xe700000066`), 与 Grand 的 `+760` folder 指针从不同值 — 语义 **未决** (原「基类保留的第二份
folder 指针」推定已推翻)。folder 归属一律读 Grand 的 `+760`。

reader = `sub_1409CC710` (grand/sub 先试自有键, 未命中转此); 未识别键静默丢弃 (基 `sub_1424BEC40` →
`sub_1424C2060` 读弃)。writer[2] = CFG 空桩 `0x14012A2C0` → **def 不入存档**。

#### 4.6.3 CFolderTemplate (学说文件夹 def)

vtable RVA 0x142718f88, sizeof 272, ctor `sub_140147C60`; 基类同 CDoctrineBaseTemplate 的祖先链但不继承它。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | 基 |
| +24 | uint8 | 已解析标志 | ctor |
| +32 | NPdxLoc::CBoundLocalization (64B) | name 本地化键 | 键 name (27) |
| +64 | CString (32B) | tab_gfx | 键 tab_gfx (16785) |
| +96 | CString (32B) | ledger_gfx | 键 ledger_gfx (16748) |
| +128 | uint32 | color_frame | 键 color_frame (16797) |
| +136 | 匿名结构 (88B) | available 触发块数据 | 键 allowed/available (12264) |
| +224 | CString (32B) | icon | 键 icon (181) |
| +264 | uint32 | xor 表 | 键 xor (10354) → sub_1415280E0 |

- `ledger` (10354) 键在 folder 脚本出现但 reader 无 case — **未决**。
- `sound` (441) 键在 folder 脚本出现但 reader 无 case — **待裁** (或由基类/另一层处理)。
- ⚠ CFolderTemplate **不继承 CDoctrineBaseTemplate**: name 在 +32 (非 +40), icon 在 +224 (非 +104), 无 xp_type。

#### 4.6.4 CGrandDoctrineTemplate (大条令 def)

vtable RVA 0x142719148, sizeof 824, ctor `sub_1401497F0`; 基类 = CDoctrineBaseTemplate。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +760 | NDoctrines::CFolderTemplate* | folder 定义指针 | 键 folder (11873), 查 CFolderDatabase 按名解析 |
| +768 | 匿名结构 (400B) | milestones 数组数据 | 键 milestones (16771) → sub_1409CD530 |
| +772 | uint32 | milestones 计数 | |
| +784 | void* | allocator (off_143085170) | ctor |
| +792 | NDoctrines::CTrackTemplate** | tracks 数组数据 | 键 tracks (16772), 经 SUniformDatabaseReader<CTrackDatabase> |
| +816 | uint32 | max_track_rows | 键 max_track_rows (16804) |
| +820 | uint32 | max_track_columns | 键 max_track_columns (16805) |

⚠ Grand 的 `+760` = folder 指针; Sub 的 `+760` = track 指针 (**同偏移不同语义, 两族必须分别记表**)。
ctor 只显式初始化到 +816 (`a1[95..99]` / `a1[102]`); +820 由 reader 写。

#### 4.6.5 CSubDoctrineTemplate (子条令 def)

vtable RVA 0x1427192f8, sizeof 968, ctor `sub_14014B2B0`; 基类 = CDoctrineBaseTemplate。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +760 | NDoctrines::CTrackTemplate* | track 定义指针 | 键 track (139), 查 CTrackDatabase 按名解析 |
| +768 | 匿名结构 (400B) | milestones 数组数据 | 键 milestones (16771) → sub_1409CD530 |
| +772 | uint32 | milestones 计数 | |
| +784 | NDoctrines::CRewardTemplate* | rewards 数组数据 | 键 rewards (16770) 块循环逐元素产 472B 元 |
| +792 | uint32 | rewards cap | |
| +796 | uint32 | rewards 计数 | |
| +800 | void* | allocator (off_143085170) | ctor |
| +808 | 匿名结构 (24B) | xor 表 | 键 xor (12043) → sub_1403B7500 |
| +816 | uint8 | reward_gfx | 键 reward_gfx (16803) |
| +820 | uint32 | allow_in_multiple_tracks | 键 allow_in_multiple_tracks (16806) |
| +832 | NDoctrines::CMasteryConditions (96B) | 内嵌 mastery 条件块 | 键 mastery (16780) → sub_1409E5560 |
| +928 | CString (32B) | 自有串 | ctor (cap 15 @+952) |
| +960 | uint8 | 标志 | 键 allow_in_multiple_tracks 目标之一; ctor 置 0 |

终结/校验 `sub_1409E6560`: 断言 `+772 != 0` ("Subdoctrine %s has no track assigned") 与 `+796 != 0`
("Subdoctrine %s has no scripted rewards"); 逐 rewards 元素调 `sub_1409E4DC0`; 调 vt[8] 槽以计算
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
| +216 | NPdxLoc::CBoundLocalization (64B) | name 绑定本地化 | 键 name (27) → sub_1424C0AA0 |
| +248 | uint32 | progress_type | 键 progress_type (16773) |
| +252 | uint32 | background_offset | 键 background_offset (16798) |
| +256 | CString (32B) | background | 键 background (156) |
| +288 | CString (32B) | icon_frame | 键 icon_frame (12120) |
| +320 | CString (32B) | icon | 键 icon (181) |

⚠ CTrackTemplate 的 `name` 写 +216 = CBoundLocalization 首址 (与 ctor 同址), 即 name 走**绑定本地化**而非
CString — 与 CDoctrineBaseTemplate 的 name→+40 (CString) 不同址。`frame` 键 (文件夹文档示例) 无 reader case
— **待裁**。

#### 4.6.7 CMilestoneTemplate (里程碑 def)

vtable RVA 0x1427190f8, sizeof 400, ctor `sub_1409CD980` (**基类 = 裸 CPersistent**, 无 CDatabaseObject
/ 无 CPersistentWithToken)。**非独立命名 def 对象** — 作为 grand/sub `+768` 内联数组元素存在, 数组
`malloc(400*n)` + `memset(0x190)` + 逐元素 ctor; 另有拷贝式 ctor `sub_140149B70` (数组扩展用)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint64 | required_progress | 键 required_progress (16774) → sub_1424C0AA0 |
| +16 | CAndTrigger (104B) | 触发内容块 | ctor sub_14053CFD0; 条目分派经 sub_141529A80 |
| +120 | 匿名结构 (88B) | CModifier 查表区 | ctor sub_140555FB0 |
| +208 | CModifier (192B) | 内联修正块 | ctor sub_1424BE3C0 |
| +352 | CString (32B) | 串 | ctor sub_14011DF40 |
| +488 | 匿名结构 (24B) | 容器头 | ctor sub_14011DF40 |

reader `sub_1409CCA50` 仅一键 `required_progress`; 其余全部读弃。reader 首行 `sub_141529A80(a1+16, …)` 为
CAndTrigger 条目分派 — 该函数被用作**门** (`if (!门) 读键 else 跳过`), 门方向 **未决** (影响
`required_progress` 是否真被处理)。writer[2] = CFG 空桩 → 不入存档。

#### 4.6.8 CRewardTemplate (奖励 def)

vtable RVA 0x1427192a8, sizeof 472, ctor `sub_1409E5750`; 基类 CPersistentWithToken。
**非独立命名 def 对象** — 作为 subdoctrine `+784` 内联数组元素, `malloc(472*n)` + `memset(0x1D8)`; 另有
拷贝式 ctor `sub_14014ABE0`。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | name token | reader 由名串求 token 后写 |
| +16 | CString (32B) | 串 A | ctor |
| +48 | CString (32B) | 串 B | ctor |
| +80 | CAndTrigger (104B) | 触发内容块 | ctor sub_14053CFD0; 条目分派经 sub_141529A80 |
| +184 | 匿名结构 (88B) | CModifier 查表区 | ctor sub_140555FB0 |
| +272 | CModifier (192B) | 内联修正块 | ctor sub_1424BE3C0 |
| +464 | uint64 | mastery | 键 mastery (16780) → sub_1424C0AA0 |

reader `sub_1409E5240` 仅一键 `mastery`; 其余读弃。**不存在独立的奖励类型枚举 (负定案)**: 脚本侧
reward 条目 = 具名 + 类别/单位子块, 无 `type = xxx` 键; 引擎侧只有 name token / 2×CString /
CAndTrigger@+80 / CModifier@+272 / mastery@+464。奖励的「类型」由 CModifier@+272 内的 mdef 键集合
表达, 非枚举 — 与项目/装备域的 CPrototypeRewardOption (有独立枚举) 不同。writer[2] = CFG 空桩 → 不入存档。

#### 4.6.9 CMasteryConditions (掌握条件块)

vtable RVA 0x142719258, sizeof 96, ctor `sub_140149930`; **基类 = 裸 CPersistent**。
内嵌于 CSubDoctrineTemplate@+832 与 CTrackTemplate@+120 (两处 ctor 实证)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | multiplier | 键 multiplier (10912) |
| +16 | 匿名结构 (8B) | categories 向量数据 | 键 categories (11352); 元素 32B 条件条目 |
| +24 | uint32 | categories 容量 | |
| +28 | uint32 | categories 计数 | |
| +40 | 匿名结构 (8B) | equipment 向量数据 | 键 equipment (12110); 元素 32B |
| +48 | uint32 | equipment 容量 | |
| +52 | uint32 | equipment 计数 | |
| +64 | 匿名结构 (8B) | sub_units 向量数据 | 键 sub_units (12176); 元素 32B |
| +72 | uint32 | sub_units 容量 | |
| +76 | uint32 | sub_units 计数 | |
| +88 | uint8 | 计算标志 #1 | evaluator 写 |
| +89 | uint8 | 计算标志 #2 | evaluator 写 |
| +90 | uint8 | 计算标志 #3 | evaluator 写 |

三键子解析器 (`sub_1409E3110` categories / `sub_1409E3530` equipment / `sub_1409E2CF0` sub_units)
共享骨架: 循环读块内未具名标量 → 取 token 条目 → `malloc(0x20)` 产 32B 条件条目入向量。

求值链 (定案): 装载期三键各建 token 集合向量 (+16/+40/+64 三组 {data,cap,count}); 终结期由
CSubDoctrineTemplate 终结函数 `sub_1409E6560` 经 vt[8] 槽调 evaluator `sub_1409E4870`; 求值对三组向量
各跑同一套两遍扫描, 用**位掩码**测试对象的标志字段 (一律读 `obj+1448`): 第 1 遍掩码 `0x408000003C` 写
+89 / 第 2 遍 `0x80004003C1` 写 +88 / 第 3 遍 `0x1F0037FC00` 只扫第三组 (+64) 写 +90 并返回。
categories 组的对象是双层 (`*(vec)+68` 计数 → `*(vec+56)` 子向量)。三组语义 = +16 categories /
+40 equipment / +64 sub_units (与脚本样本对齐)。**掩码位→档位语义 未决**。

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
| | description (15906) | +32 |
| | icon (181) | +104 |
| | xp_type (16769) | +36 |
| | xp_cost (19741) | +32 (与 description 同址 — 待裁) |
| | available (12264) | +608 |
| | visible (11562) | +520 |
| | ai_will_do (10819) | +696 |
| CFolderTemplate | name (27) | +32 |
| | icon (181) | +224 |
| | tab_gfx (16785) | +64 |
| | ledger_gfx (16748) | +96 |
| | color_frame (16797) | +128 |
| | available (12264) | +136 |
| | xor (10354) | +264 |
| CGrandDoctrineTemplate | folder (11873) | +760 |
| | milestones (16771) | +768 |
| | tracks (16772) | +792 |
| | max_track_rows (16804) | +816 |
| | max_track_columns (16805) | +820 |
| CSubDoctrineTemplate | track (139) | +760 |
| | rewards (16770) | +784 |
| | xor (12043) | +808 |
| | reward_gfx (16803) | +816 |
| | allow_in_multiple_tracks (16806) | +820 |
| | mastery (16780) | +832 |
| CTrackTemplate | name (27) | +216 (待裁: 与 CBoundLocalization 同址) |
| | active (11390) | +32 |
| | icon (181) | +320 |
| | icon_frame (12120) | +288 |
| | background (156) | +256 |
| | background_offset (16798) | +252 |
| | progress_type (16773) | +248 |
| | mastery (16780) | +120 |
| CMilestoneTemplate | required_progress (16774) | +8 (未决: 门方向待定) |
| CRewardTemplate | mastery (16780) | +464 (未决: 门方向待定) |
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
| CGroupBtn | **非学说类** — 唯一存在者是 NCombatLogView::CGroupBtn (战斗日志视图); 学说侧 entry 按钮类未发射独立 RTTI — 未决 |
