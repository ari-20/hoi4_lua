

### 4.00 基类契约层 (接口vtable / 槽位语义)

> **本册定位**: 全书其余分册是「**实例级**」字段表 (某类在某偏移存什么)。
> 本册记「**基类级**」契约 (<u>vtable槽位语义</u> / 基子对象偏移 / 抽象性) —— 是
> 复用时「**先查基类定槽位，再只啃差异**」的索引层。每类新增时若其基类已在本册，
> 序列化/解析入口不再需要逐类反查。
>
> **解vtable通道**: RTTI COL 解vtable (扫 .rdata 取
> `{sig=1, td_rva, self_rva}` 的 COL → 反查指向它的指针 → vtable = ptr+8) +
> 跨类槽位对照 + dump 直读 ctor 装表点。
>
> ⚠ **vtable读法前置**: `_purecall` (0X14253C3B8) = 纯虚/未实现槽;
> `_guard_check_icall_nop` (0X14012A2C0) = CFG 空桩 (含 ICF 折叠的等价空函数,
> 全 exe 12740 处引用) —— 二者都不携带语义, 读vtable时必须识别后再数槽。

#### 4.00.1 序列化基类 CPersistent (每类 Save/Load 入口)

CCountry / CState / CProvince / CCharacter / CPoliticalStatus / CCountryPlayerSettings /
CCommand 的 RTTI 基链均含 `CPersistent @0`, 其主vtable前 6 槽槽位语义同构;
槽 [1]/[3]/[5] 全类同址 (定义在 CPersistent 且不被覆写), 槽 [2]/[4] 逐类变 (纯虚):

| 槽 | 语义 | 证据 (同址函数) |
|---|---|---|
| [0] | 析构 (各派生类自有 dtor) | CCountry sub_1406CED50 / CState sub_1409D0F70 / CPoliticalStatus sub_140BA71D0 … |
| [1] | **Save 入口** (共享 wrapper: `sub_1424C4410(stream)` → 调 [2] → `sub_1424C3A20(stream)`) | 7 类同址 **sub_1424BEC50** |
| [2] | **每类 writer 本体** (纯虚/覆写) | CCountry **sub_1407191B0** / CCountryPlayerSettings **0X1414E7670** / CState sub_1409E0E90 / CProvince sub_140E81390 / CPoliticalStatus sub_140BB0520 / CCharacter sub_140FA6520 / CCommand sub_14226A110 |
| [3] | **Load 入口** (共享 wrapper, 详下契约) | 7 类同址 **sub_1424BE690** |
| [4] | **每类 reader/parser 本体** (纯虚/覆写) | CCountry **sub_140705CE0** / CState sub_1409DBE00 / CProvince sub_140E7F720 / CPoliticalStatus sub_140BAD850 / CCountryPlayerSettings 0X1414E7110 / CCharacter sub_140FA50B0 / CCommand sub_142269E60 |
| [5] | **重复键检测谓词** `TrackKey(this, token)` — 返真才把键登记进查重表; 基类恒假 (默认不查重) | 7 类同址 **sub_14011D220** |
| [6] | **预载钩** `PreLoad(this)` — wrapper 进块前调用; 基类空桩; 仅 CFactionGoal 0x140A236E0 / CDoctrineSystem 0x140D7F080 / CFactionSystem 0x140D92C60 / CRaidSystem 0x140E862B0 四类覆写 (= System/Goal 读档前重置自身) | 基类 CFG 桩 |
| [7] | **文件位置后验钩** `PostLoad2(this, filename, startLine, endLine)` — 块尾 PostLoad 之后调用; 基类空桩; ≥25 类覆写 (集中静态资源模板族 CTrait/CTemplate/CDatabaseEntry) | 基类 CFG 桩 |
| [8] | **PostLoad(this)** — 本对象块闭合瞬间即调; 178 类实装 (清单 `ref/postload_classes_1193.txt`) | 基类 CFG 桩 |

> 旁证: §4.3 记 CCountry writer = sub_1407191B0; CCountryPlayerSettings
> serialize = 0X1414E7670 (= 槽[2])、parse = 0X1424BE690 (= 槽[3] Load 入口) ——
> 与「槽[2]=writer / 槽[4]=reader」定案吻合 (定案, 非推定)。
> 补证: 槽[5] = return 0 桩 0x14011D220 在装备族 (CEquipmentStats /
> CEquipmentStatsGroup / CEquipmentGroup) 同址再证; 部分族 [9] = Clear/Reset

> ⚠ **「[3] 自定 Load」盲区 (定案)**: 部分类把 [3] 从标准 Load wrapper (`sub_1424BE690`)
> 换成**自定解析器**, 并把 [4] 退化为 `sub_1424BEC40` (= `return sub_1424C2060(a2)`,
> "Unexpected token" 报错桩) —— 已知实例群: `CAssetFactoryParticle` (0x142B501A8,
> [3] = 0x142331870) / `CBrowserType` (0x142B53C58, [3] = 0x1422DE0B0) /
> **§4.19 本地化表达式族六类** (CBoundLocalization / CFormattedLocalization /
> NScript::CConstant / CCollection / CNamedCollection / NMath::CExpression) /
> **CTraitTemplate** (§4.8.12b; [3] 自定 wrapper 落 +968/+976, [4] 标准非退化 — 变体形态) /
> **CTask** (§4.8.12a; [4] = 报错桩形态, [2] 亦 CFG 空桩 — 纯运行时对象零序列化)。
> **`ref/serfam_1193.txt` 的指纹判据 = `[1]==0x1424BEC50 && [3]==0x1424BE690`,
> 故该族结构性失明** (不在表内) — 用 serfam 判定「是否 CPersistent 族」时须先排除本形态。
> 虚槽 (例 0x140631ED0 / 0x140631EA0 / 0x140631EE0, stats/bonus/group 三族)。
>
> **CPersistent 本身无 COL / 无 `vftable` 符号** (grep=0): 它是**抽象接口** ——
> 从不单独实例化, 故 exe 不发射其 COL; 具体类的vtable = CPersistent 槽 + 派生类新槽。
> 槽 [1]/[3]/[5] 全类同址 ⇒ 定义在 CPersistent 且不被覆写; 槽 [2]/[4] 逐类变 ⇒ 纯虚。
>
> **CCountry 谱系 = 单链 CPersistent ← CAIOwner ← CCountry** (vtable 实测 11 槽,
> mi=false); 槽 [8] = CCountry::PostLoad (sub_1406FE1D0 → thunk sub_1406FE1E0,
> 大级联: 政治名重建 → 逐单位 vtable+224 钩 → 情报池/战斗/战区重挂 → 占领修复
> sub_140FF9DE0(cc+4048,0) 等 20+ 子步); [9][10] (sub_1401F8A60) = ICF 恒等汇点
> 推定归 CAIOwner 层 (唯 CCountry 一派生, 离线不可再分)
> **CUnit 例外**: CPersistent 在其 **@16** (次基子对象), 故 CUnit 主vtable [2]/[4] 为空
> (真实序列化槽在其 +16 子对象vtable) —— **多基类时 CPersistent 槽位随 mdisp 漂移, 勿按主vtable硬套**。

CPersistent 谱系 —— 除上表 7 类外, 另两族**非**实体基类与 CRelation 也挂同址 Save/Load 槽;
**[1]=sub_1424BEC50 & [3]=sub_1424BE690 同址 = 判 CPersistent 谱系的通用指纹** (工具法见 §4.00.4):

| 家族 | vtable | [1] Save | [3] Load | 派生 | 备注 |
|---|---|---|---|---|---|
| CDatabaseObject | 0x142718150 | sub_1424BEC50 | sub_1424BE620 (变体) | 24 | 非实体基类 |
| CReferenceObject | 0x1427de248 | sub_1424BEC50 | sub_1424BE690 | 71 | CCharacter 即经它继承 |
| CRelation | 0x1429601C8 | 同址 | 同址 | — | 指纹同样成立 |

全谱系清单资产: `ref/serfam_1193.txt` (1.19.3 现役指纹表, 1,153 行) ——
用指纹 (slot1=0X1424BEC50 & slot3=0X1424BE690) 扫全 exe, 得 **1151 个可序列化类**,
每行 = `类名 / vtable / writer[2] / reader[4] / 槽数`; 统计 writer 真实现 900 /
purecall 1 / guard_nop 250 (guard_nop = 该层不覆写 writer); 抽查 CCountry 0X1407191B0 /
CArmy 0X140C90550 / CAce 0X14061BD30 均与书内定案一致。用法: 需某类的 writer/reader → 直接查本表。

共享 Load wrapper sub_1424BE690 调用序 (persistent.cpp, 定案):
① `vtable[6](this)` 预载钩 → ② 循环取 token, 键经 `vtable[5](this,token)` 谓词
(返真才登记查重; 重键报 `Duplicate "k" in file: "f" near line: N`, 文件名/行号
getter = sub_1424BF960 / sub_1424BFBA0) → ③ `vtable[4](this, parser, token)` 逐块
ReadKey, 嵌套子对象各自递归走同一 wrapper (统一入口 thunk = sub_1424C0AA0
`return obj->vtable[3](obj, parser)`) → ④ 块尾 (tok 4/19) 即调 **`vtable[8](this)` =
PostLoad** → `vtable[7](this, filename, startLine, endLine)` 后验钩。
**无集中全局 PostLoad pass** — 全局次序 = 存档文档深度优先序 (先子后父、
同层按落盘键序), 全装载链见 §4.28.17。

**块读取循环同形骨架** (三 Load 入口逐项比对, 定案; ctx = wrapper 的 parser 实参, reader = ctx+40 指向的取词器, 类名未决):

| 元素 | 偏移 | 语义 |
|---|---|---|
| 取词器 | ctx+40 | vt[1] 取 token id → 落 reader+16; id==0 → reader+24 = 19 (EOF 哨兵) |
| eof 武装旗 | reader+100 | 首读后置 1, 避免重复取 token |
| token 类型 | reader+24 | 19 = EOF / 4 = 块尾 |
| 分派键 | ctx+48 | 当前 token id |
| 前进 | sub_1424C1540(ctx, 1) | 推进到下一 token |
| 跳未知块 | sub_1424C2170 + sub_1424C2060 | persisted_designs 的 else 分支 |
| 跳错误块 | sub_1424C1E40(ctx) | unitnames / reinforcement 的错误出口 |

> 退出条件两形: EOF 即停 (unitnames sub_140AF02C0, reader+24==19) / EOF 或块尾 (persisted_designs sub_1419214F0, 4‖19); reinforcement sub_14150F1B0 为单块 switch 形, 原语同族。⚠ 与 §4.00.17 CReader (脚本侧, +24 = 错误计数) 为两套对象, 勿混用偏移。

#### 4.00.2 GUI 框架基类 (View 底座 / tooltip / popup)

| 基类 | vtable | 槽数 | 派生规模 | 定位 |
|---|---|---|---|---|
| **CTooltipHandler** | 0x14273AA08 | 2 | 972 直接派生 | 抽象 tooltip 钩子接口 |
| CUpdateable | 0x14294c198 | 6 | 125 | Update / populate 底座 |
| CReloadDispatcher | 0x14271a630 | 4 | 330 | ret0 空实现层 |
| **CTemplateChanger** | 0x1429E9BF8 | 6 | — | 收集可换编制目标 (非抽象: [0][1] = _purecall / [2] sub_14169D500 / [3] ret0 / [4] CFG_nop / [5] ret0) |
| CReloadableInterface | 0x142B3F238 | 4 | 290 | Reload 接口 |

CTooltipHandler vtable槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 纯虚钩子; 签名定案 `bool BuildTooltip(hovered CGuiObject*, CString& out)` |
| [1] | sub_1402DE980 | 析构 |

CTooltipHandler 调用与挂接:

| 项 | 值 |
|---|---|
| 调用方 | sub_14163BB80 (悬停组装器简版: hovered+117 旗 &4 = **GetToBeKilled()** (tooltips.cpp:15 断言实名) 禁用门 ∧ 全局门 byte_14332F61F → vtable[70] 取 handler → 调钩子 (出参 = 状态头 **≥96B** {标题串@+0, 正文串@+32, 快捷键提示串@+64}; §4.30.5 部署 tooltip 实证 +64 = SSO 定长赋值 "ctrl+g+d"); false / 无 handler → 兜底 sub_1419A7F60); **全序版姊妹函 = 0x14163B600** (tooltips.cpp, 305 行, 五级优先链 = scoped 本地化 → 无键本地化 → raw 文本 id 四槽 (+144/+152 恒生效 / +160/+168 悬停变体优先, 经 qword_1435BA038 文本库 16B/元有序二查) → CTooltipHandler 钩子 → 兜底串; 挂接表 = .rdata 0x14294A0F0 槽[0] 无 RTTI 自定义分派表, 勿与简版混同) |
| 挂接 | CGuiObject@48 子对象 vtable[69] = SetTooltipHandler (存窗口 +128, 递归子窗); **CButton 基族直证**: CButtonStandard/CIcon/CButtonDrag vt+552 = 0x1414A57E0 (写 button+80) / vt+560 = 0x1406773A0 (读) — 552/8=69, 560/8=70 同槽 |
| 读取 | vtable[70] = getter (读 +80) |

CUpdateable vtable槽表 (0x14294c198, 6 槽; 契约定案 — standardinterface.cpp 断言串对偶佐证):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 析构 |
| [1] | — | **IsValid** (基实现推进 timeout_progressbar 后 return 未超时; 派生全部 base && 条件组合) |
| [2] | — | **Refresh** (派生 populate 用法归并入此名) |
| [3] | — | IsFor (推定: 共享谓词 `+8 && +8==arg` = ctor 绑定指针与入参比较, 全族零覆写) |
| [4] | — | **Setup** (基 = ret0) |
| [5] | — | **Teardown** (基 = guard_nop; 6 槽口径复证, slot[6] 起 = 下一vtable COL) |

CReloadDispatcher vtable槽表 (0x14271a630, 4 槽; 契约定案 — 控制台 `reload` 派发与枚举壳直证):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 析构 |
| [1] | — | **Update** (带可选参数表的推进/处理回调, bool) |
| [2] | — | **Reload** (无参重载/重建, bool; 控制台 `reload <name>` 派发调 vtab+16) |
| [3] | — | **CollectReloadNames** (向引擎字符串表容器追加本对象可重载条目名) |

CTemplateChanger vtable槽表 (0x1429E9BF8, 6 槽):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | **CollectTargetDivisions(out\<CArmy\*\>)** |
| [2] | — | **CollectAvailableTemplates(tag, out, &hq_flag)**: 遍历 cc+440 模板容器, 滤锁门 sub_140BA2440 + obsolete@+542 + is_army_hq@+436 旗 |

> CArmyDivisionStatsView@80 / CArmyDivisionListView@0 两视图同构覆写 (stats 主表
> 6 槽挂 CUpdateable@64 + CTemplateChanger@80; 基族「同族不同序」实例)。
>
> **CArmyDivisionStatsView 五表 28 槽全定**: 主 0x1429EA2E0 (4: [0] 析构 sub_141697C40 / [1] ret0 / [2] sub_1416ADD60 Reload / [3] CFG_nop) · @40 iface 0x1429EA308 (10) · @64 CUpdateable 0x1429EA360 (6: [0] sub_141697B08 / [1] sub_1416B88A0 / [2] sub_1416AD770 / [3] sub_1402E02D0 / [4] ret0 / [5] CFG_nop) · @80 CTemplateChanger 0x1429EA398 (6: [0] sub_141698860 / [1] sub_14169B5D0 / [2] sub_14169D450 / [3] ret0 / [4] CFG_nop / [5] ret0) · @112 CTooltipHandler 0x1429EA3D0 (2: [0] sub_1416A2270 BuildTooltip / [1] sub_141697B14)。
> **CArmyDivisionListView 二表**: 主 0x1429E9F18 (6: [0] 析构 sub_141698540 / [1] sub_14169B400 / [2] sub_14169D420 / [3] ret0 / [4] CFG_nop / [5] ret0) · @32 tooltip 0x1429E9F50 (2: [0] sub_14169F350 / [1] sub_141697AF0)。

CReloadableInterface vtable槽表 (0x142B3F238, 4 功能槽; 契约 = CReloadDispatcher 扇出):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | sub_142256130 | 析构 (sub_1422560A0 + free) |
| [1] | — | **Update** (继承契约) |
| [2] | _purecall | **Reload** (纯虚重抽象, 强制窗口实现) |
| [3] | — | **CollectReloadNames** (基 = CFG_nop 空默认; 派生逐条 push) |

> 三独立实现同构: CCountryView 0X1412375D0 / CPopUpWindow@16 0X140B7D300 /
> CShipStatsView 0X141BED890 = 释放旧窗 → 工厂重建 → 注入 tooltip →
> `return sub_14225D3C0(win+48)^1`。

CCountryView 公共 View 基座: 主 vtable **0x1429A3F38, 17 槽, 抽象**; 基链
`CReloadableInterface@0 ← CReloadDispatcher@0 ← CTooltipHandler@40 ←
CInGameUpdateableInterface@48`; CCountryStateView (0x1429F82E8) / CCountryNavalRegionView
(0x1429F6D78) 同链, 17 槽中 11 槽同址。

| 槽 | 函数 | 语义 |
|---|---|---|
| [2] | — | **Reload 实现** (基类纯虚落点) |
| [5] | — | **IsOpenAndVisible**: `win=+1400 → !win->vtable[73] && byte165&8` |
| [9] | State 0X14174A990 | **Refresh**: 悬停==+1416 → populate_b sub_14174ECF0; ==+1408 → populate_a sub_14174DD50 |
| [11] | State 0X14174AA40 / Naval 0X141735770 | **SetTarget**: State +1408=a2, +1416=*(a2+192); Naval +6912=a2+200 |
| [14] | State 0X14174AF00 (2.6 万行) / Naval 0X141735BE0 | **populate 主** (纯虚) |
| [15] | State 0X141746070 (1.2 万行) / Naval 0X141734CC0 | **populate 副** (纯虚) |
| [16] | — | 界面对象刷新 (断言 `_Idler.CanUpdateGui`) |

> 补槽 (PE 直读): [0] = _purecall 析构 / [1][12][13] = ret0 / [3][6][10] = CFG_nop / [4] = 0x141237840 = **Repopulate sub_141236980** (sub_141237840 实调后者; 「退订 sub_141236280」为误配, 废) + +1400 窗口非空虚调 win+48 子对象 vtable[15] / [7] = 0x141237500 关窗转发 (win+48 子对象 vtable[16]) / [8] = 0x141237570 win 主vtable [12] 转发 ([4][7][8] 高置信)。

CCountryView 成员锚:

| 偏移 | 名称 | 语义 |
|---|---|---|
| +40 | 匿名结构 (NNB 形状) | 基链挂载 |
| +48 | iface | CInGameUpdateableInterface 子对象 |
| +56 | 匿名结构 (NNB 形状) | — |
| +1400 | 当前窗口 | [5] IsOpenAndVisible 消费 |
| +1408 | 目标 | [11] SetTarget 写入 |
| +1416 | 绑定句柄 | [11] SetTarget 写 *(a2+192) |
| Naval +6840 | Naval 专用锚 | — |
| Naval +6912 | Naval 专用锚 | [11] SetTarget 写 a2+200 |

CInGameUpdateableInterface (0x142A41C20, 10 槽) vtable槽表 (基类桩 + **派发侧语义**, 定案):

| 槽 | 基类 | 派发侧语义 (sub_140B68600 "interface.tick" 逐层无门直调) |
|---|---|---|
| [0] | — | 析构 |
| [1] | 断言桩 "Override this function before using!" (updateableinterface.cpp L37-67) | **年** 动作 (无门) |
| [2] | 断言桩 (同 [1]) | **5 月** 动作 (无门) |
| [3] | 断言桩 (同 [1]) | **月** 动作 |
| [4] | 断言桩 (同 [1]) | **周** 动作 |
| [5] | 断言桩 (同 [1]) | **日** 动作 |
| [6] | 断言桩 (同 [1]; 视图覆写 = 全量刷新) | **时** 动作 (经 vtable[8] 门) |
| [7] | 断言桩 (同 [1]; 视图覆写 = 逐帧 Update) | **每帧** 动作 (bit0 层, 无门) |
| [8] | 0X141237590 (共享) | IsOpenAndVisible 转发 (调主 vtable[5]); 兼**时层派发门** |
| [9] | — | **Repopulate** (纯虚) = 脏重建 (脏标在 iface+20) |

> **interface.tick 中央派发** (定案): sub_140B68600 (体首 profiler 字面量 "interface.tick") —
> mgr (= idler+1720 大视图对象) 七层注册列表 (begin@+144/+120/+96/+72/+48/+24/+0,
> 条目 = 8B 裸接口子对象指针) 按 iface+16 七位层掩码逐层遍历, 逐项 `entry->vtable[槽](entry)`
> — **门语义 (定案)**: 月/周/日三层与帧层一样过 vtable[8] IsOpenAndVisible 门, 年/6月两层无门; [2] 槽层 = 月==5 (0-based, 即 6 月, 月份计算器 sub_140177650 返回 0-based); 年/6月/周三层现无任何注册者 (引擎保留档位, 详 §4.30.46); 另 mgr+200 = 23 固定槽视图数组 (换国 vtable[6] / 帧尾脏标 vtable[9])。
> 遍历函数由 CInGameIdler::Idle (0x140DD3A50) **直调** (xref 唯一) — 与渲染链
> (DDDDF0 → 223D2C0, §4.28.14) 并列, 不经渲染路径。
> 注册/退订三件: sub_1412362A0 (win+48, mgr, 层掩码) / sub_141236820 (按 7 位掩码逐层
> push_back, bit0 带去重) / sub_141236330 (镜像退订); CTopBar ctor 0x14188FDC0 以
> 掩码 0x17 (每帧+时+日+月) 注册。⚠ win+23448 = CTopBar 本地子 widget 启停表
> (旗字节 + vector, 消费 sub_14189EEB0 逐 widget +228 bit7 广播), **非**中央注册表。

> 视图 @48 子对象只覆写 [6] (全量刷新) / [7] (逐帧 Update) / [9]。

CPopUpWindow 三vtable (主 0x14294C238 14 槽 / @16 0x14294C2B0 4 槽 / @56 0x14294C2D8 2 槽);
主vtable = CUpdateable[0..5] + 自有槽:

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | sub_140B7B930 | 析构 |
| [1] | sub_140B826E0 | populate |
| [2] | — | CFG_nop |
| [3] | sub_1402E02D0 | 共享谓词 `+8 && +8==arg` |
| [4] | — | ret0 |
| [5] | — | CFG_nop |
| [6] | sub_140B82510 | — |
| [7] | sub_140B7CC80 | IsOpenAndVisible (`win=+1392 → !vtable[73] && byte165&8`) |
| [8] | sub_140B7CC20 | — |
| [9] | sub_140B7CD00 | — |
| [10] | sub_140B7CCD0 | — |
| [11] | — | **OnOpen** (纯虚) — 派生共享实现 0x140B7E3F0: 先 `sub_140B7D780` 建窗并绑 accept_button/decline_button (+180/+181) 再尾调本表 [14] Populate (**50 类**命中); CDefaultInfoPopUpWindow 变体 0x140B7E410 绑 ok_button 后同样委托 [14] |
| [12] | — | **OnClose** (纯虚) — 派生共享实现 0x140B7BE00: 单行 `return this->vtable[15](this)` (**56 类**命中) |
| [13] | — | CFG_nop |

> 建窗原语 = `sub_140B7D560` CreateWindow (+1392 已有窗时断言 `"_pWindow == 0 && \"Window already created.\""`, popupwindow.cpp:154)。
> 同槽两套名: 本表 OnOpen/OnClose 与 GUI 册 SetupDerived/teardown 指同一机制 ([11] 装配后委托 [14], [12] 清理后转发 [15])。

@16 子对象vtable (CReloadableInterface 形, 4 槽; 真表 0x14294C2B0):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | sub_140B7B2F0 | 析构 |
| [1] | — | ret0 |
| [2] | 0X140B7D300 | Reload 实现 |
| [3] | — | CFG_nop |

> 注失实撤除: 主表 14 槽与 @16 表 4 槽书内已全列 (COL 边界复核: 主表 [13] 后 = @16 表 COL; @16 [3] 后 = @56 表 COL)。

@56 子对象vtable (CTooltipHandler 形, 2 槽; 真表 0x14294C2D8):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | purecall | tooltip 钩子本体留纯虚; CDefaultConfirmationPopUpWindow 以 ret0 覆写 = 永不产 tooltip |
| [1] | sub_140B7B2FC | 析构 (单行 `return sub_140B7B930(this−56)`) |

CPopUpWindow 成员锚:

| 偏移 | 名称 | 语义 |
|---|---|---|
| +64 | CButtonEventDispatcher | 按钮事件分发 |
| +1368 | SSO 串 | — |
| +1392 | 窗口管理 | [7] IsOpenAndVisible 消费 |
| +1408 | CGregorianDate | — |

**CDefaultConfirmationPopUpWindow 扩槽契约 (定案)**: **[12] = Close→OnClose 转发桩 0x140B7BE00** (单行 `return this->vtable[15](this)`, CDefaultConfirmationPopUpWindow 系全族共享含 InfoPopUp 分支与 CAcceptCommandDialog; 基类 CPopUpWindow [12] 纯虚) / **[14] = Populate (灌 title/description 元素) / [15] = OnClose 关闭清理虚槽** (基类 CPopUpWindow 实装 0x140B7B2F0; CDefaultConfirmationPopUpWindow/CDefaultInfoPopUpWindow 抽象层纯虚; default_confirmation_popup 专用确认族具体类默认 CFG 空桩; CAcceptCommandDialog 覆写 0x1415BC810 = 遍历 +4184 命令数组销毁未投命令) **/ [16] = OnAccept / [17] = 关闭门 (默认 ret 1)**; accept/decline glue OnClick = sub_140B7CD90 / sub_140B7CFE0 双回调链; +1440/+1448 = accept/decline 控件 / +1520/+2808 = 双 glue / +1400 = 关窗旗。三通用弹窗: CStandardInfoPopUpWindow (def default_info_popup_window; 标题串@+2728/描述串@+2760 经 [14] Populate 0X141BE5690 灌入); CDefaultInfoPopUpWindow (抽象基, [14..16] 纯虚); CConfirmationPopUpWindow (def confirmation_popup_window 独立分支 + CAutomaticPause@+1440; 标题+2744/正文+2776/发送接收方旗 tag@+2808/+2812/战争图标变体+2816; 实测消费 = MILESTONE_UNLOCK_HEADER 通知)。**CAcceptCommandDialog** (def default_confirmation_popup): **载荷 = CCommand\* 数组 @+4184 {count@+4196}** — 接受 ([16]) 逐个 sub_142250B00 投递, 关闭 ([15]) 销毁未投命令。

default_confirmation_popup 专用确认窗族 (基座主vtable 0x14294C358 18 槽, 槽 14/15/16 基座纯虚; 派生统一覆写 = 槽14 OnInit 装 TITLE/DESC loc 键 / 槽15 空 / 槽16 OnConfirm; 统一布局 +4096 = 宿主控制器 / +4104 起载荷; 确认统一链 = 宿主 vtable+136 取命令队列 → 命令 ctor → sub_142250B00 入队):

| 类 | vtable (主) | 确认语义 | OnConfirm 去向 |
|---|---|---|---|
| CConfirmAssignUnitsToFront | 0x142A2F7C0 | 批量指派部队到前线 (单位 CRef 向量载荷) | 命令入队 |
| CConfirmCancelNavyActivityDialog | 0x1429DD038 | 海军行动取消 | 命令入队 |
| CConfirmCancelShipRefittingDialog | 0x1429DD110 | 舰船改装取消 | 命令入队 |
| CConfirmConsolidateUnits | 0x142A68548 | 整编/合并残编部队 | 命令入队 |
| CConfirmDeleteAllEquipmentProductionLines | 0x142A9CCE0 | 删除全部装备生产线 (CONFIRMCANCELALLPRODUCTIONLINE loc 直证) | 命令入队 |
| CConfirmDeleteAllOrders | 0x142A2F570 | 删除全部作战计划 | 命令入队 |
| CConfirmDeleteEquipment | 0x142A9CFE8 | 删除装备设计/变体 | 命令入队 |
| CConfirmDeleteOrder | 0x142A2F648 | 删除单条入侵/伞降计划 (CONFIRM_DELETE_ORDER_INVASION/PARADROP) | 命令入队 |
| CConfirmDeleteOrdersGroup | 0x142A67870 | 删除编组/指令组 | 命令入队 |
| CConfirmDispatchAccidentsDialog | 0x1429DCF60 | 海军事故派遣 (NAVAL_ACCIDENT_DISPATCH loc) | 命令入队 |
| CConfirmDispatchResultsDialog | 0x1429DCE88 | 海战胜果派遣 (本族根邻位) | 命令入队 |
| CConfirmKickBanPlayerDialog | 0x142A851C8 | MP 大厅踢/禁玩家 (无 Populate, OnAccept 直出命令 0x141E59B30) | 命令入队 |
| CConfirmRemoveAllRegions | 0x1429DD1E8 | 海军战区整块区域清空 (NAVAL_CONFIRM_REMOVE_ALL_REGIONS) | 命令入队 |
| CConfirmRemoveBuildingLevel | 0x142A9DDC0 | 州建筑降级/移除 | 命令入队 |
| CConfirmTrainingGroupDialog | 0x142A6A1B0 | 训练组设定训练目标 | new **COrderSetTrainingCommand** (ctor 0x14183B160, 0x38B) |
| CConfirmUnassignUnits | 0x142A68B60 | 批量取消单位指派 (按指挥官拆分批) | new **COrderUnassignCommand** (ctor 0x14183B4B0, 0x50B) |
| CExitPeaceConferenceDialog | 0x142A84740 | 退出和平会议 | new **CDonePeaceConferenceCommand** (ctor 0x141E535C0, 0x30B) |
| CTraitAssignmentConfirmation | 0x142A9C920 | 将领特性指派 | new **CLearnTraitCommand** (ctor 0x141837690) |
| COperationRefundDialog | 0x142A82018 | 情报行动退款 | new **CDeleteOperationCommand** (ctor 0x141A24E10) |
| CSetPrideOfTheFleetDialog | 0x142A91E88 | 舰队旗舰设定 | new **CSetPrideOfTheFleetCommand** (ctor 0x14134A550, 0x38B) |
| CRandomAllConfirm | 0x142A43550 | 开局「全部随机」 | 直写宿主开局设置旗 (+304=0, +308/+309 两选项), 无命令 |
| CConfirmSwitchEquipment | 0x142A9CDB8 | 换生产线生产型号 (CONFIRM_SWITCH_PRODUCTION_MODEL_*, DAYS 代价) | 直调 sub_141DBD100 换型号, 无命令 |
| CConfirmSaveGame | 0x142A7AA30 | 覆盖同名存档确认 (**自绘面板非 CWindow**, 基 CReloadableInterface+CInGameUpdateableInterface+CTooltipHandler) | OK → sub_141DEA350 → sub_140DA3530 按当前格式直接重存, 无命令 |
| CConfirmResearchTechnology | 0x142A4E768 | 重科技确认 (**离群**: 基 CInGameUpdateableInterface 15 槽 view 基座, 经科技视图 sub_1413D38F0 挂 default_confirmation_popup) | 视图回调 |
| CConnectionLostDialog | 0x142A03880 | MP 断线信息 (**CDefaultInfoPopUpWindow 族 17 槽**, 槽14 订阅 save_sub 事件) | OK → sub_140DDE880 → sub_140B661C0 断开流程, 非命令 |

**CDiplomacyPopupWindowBase** (外交弹窗抽象基, vtable 0x1429F9658 四表; 槽 11/12 留纯虚 = 接受/拒绝回调派生实现; 槽 14 = 展示即 CAutomaticPause SetPause(2) 自动暂停, 槽 15 配对恢复; 宿主指针@+4096) → 派生 CStandardDiplomacyPopup / CScriptedGUIDiplomacyPopup / CIncomingLendLeaseDiplomacyPopup / CForeignManpowerDiplomacyPopup。

> ⚠ **CTooltipHandler 基子对象偏移逐类不同** (CPopUpWindow +56 / CShipStatsView +40 /
> CArmyDivisionStatsView +112), 无固定偏移可套。
>
> ⚠ **槽位方差法多基坑**: 该法只收后代**主vtable** —— 多基后代
> (CReloadableInterface+CUpdateable 并存) 会把 A 基槽实现误记为 B 基覆写 (实例
> CEventWindow 0X141239A40); 大家族结果按主基分层后再读。
>
> ⚠ **基族「同族不同序」**: CDivisionDesignerView 与 CCountryView 同基族但
> 排序不同 (iface@40 + tooltip@64 + **CModelListItemParent@72**, 主vtable仅 6 槽,
> 无 [9]/[11]/[14][15]) —— **17 槽基座不可跨类硬套**, 每个 View 逐类解基链。

#### 4.00.3 脚本效应基类 (effect / trigger 引擎)

| 基类 | vtable | **虚函数槽数** | 派生规模 |
|---|---|---|---|
| **CEffect** | 0x1427D4990 | **25** (槽 0..24) | 604 |
| **CTrigger** | 0x1427d55f0 | **23** (槽 0..22) | 639 |
| CCommand | 0x142977040 | 24 (槽 0..23) | 452 |
| CCommand 基表 0x1427214C8 | 同上 (派生覆写 [9][10][11][13][22][23] = _purecall; [0] = 析构 sub_1401C94A0 / [5] = ret0 桩 / [6][7][8][14] = CFG 空桩; [17] sub_1401773F0 = 空串 GetDesc 默认) | | |

> ⚠ **槽数口径**: vtable 含前哨 COL 槽 [-1] —— 拷贝整表 (含 [-1] COL) 时
> CEffect/CTrigger 指针总数 = 26/24; **数函数槽、跨类对照时按纯虚函数槽 25/23**。
> CEffect 基链含 `CProfiledScopeObject` + `CPdxArray<CEffect*>`; CTrigger 含
> `CTriggerDataMembers` + `CProfiledScopeObject` + `CPdxArray<CTrigger*>
>
> **CTrigger::Parse (0x140550030) 兜底链五站** (注册名 → 注册树 qword_143330050 → building db (0x332EE28, 条目+32 门 → 320B 包装) → strategic_resource db (0x332F088, 条目+16 门 → 184B) → 0x332EF38 RH 按 token (56B 桶 → 312B; 该库未入 idb 103 key, 身份待裁) → sub_140F88330 (→312B) → **scripted_trigger_template db (0x332F058, 按名, 条目+88 null 旗 → 104B 包装)**。`。

**CEffect 全槽表** (覆盖数 = 470 个实测vtable中覆写该槽的类数; 「默认」= 基类共享实现):

| 槽 | 语义 | 覆盖 | 证据 |
|---|---|---|---|
| [0] | 析构 | 148 变 | MSVC 惯例 |
| [1] | **GetName** (读 +32 id ≥0 则查注册表返 std::string*; 否则 +44 token 转名并缓存 +56) | 468 同 sub_14053FF00 | 全家族同址 (只触 CEffect 通用字段) |
| [2] | **固定 getter** `*(a1+32)` (int) | 470 全同 sub_140177730 | 无覆写 |
| [3] | **块级 Parse** — 逐键分派 (键 token → 各键子解析回调), 未识别键回落 [4] | 42 | sub_140540B90 |
| [4] | **载荷键解析主体** — 逐类标量键解析 (tooltip/var/value/min/max/array/index/limit/side/gfx 等), 未识别键回落 AddSubEffect (解析期按 token/名实例化子效果并追加, if/else 链 + 作用域校验 + 数据库兜底, effect.cpp:392/435/445) | 180 | sub_140540EE0 (回落) |
| [5] | 默认 `return 1`; 覆写实态 = **载荷完整性校验钩子** (返 bool; A 抛/B log/自愈复位三形态; 覆写样本 :6007/:6369/:18348/:23259/:24369/:8021/:10555 + randomize 校验器 1403A4DB0; 精确调用点待裁) | 21 | sub_1401807B0 |
| [6] | ★ **ParseTargetToken** (token id switch 填位掩码 + `event_target:` 解析) — **仅作用域键**; 类专属键在 [4] | 29 | sub_14053D4C0: `switch(token){11412/11413/10691/10639/10302/15793/10303/10315/10171 → *(a1+36)\|=位}` + `strncmp(s,"event_target:")` |
| **[7]** | ★ **GetDesc** (默认 = 空 MSVC 串) | **309** | sub_1401773F0 写空串; `CEffectShowDependentTooltip` 在此槽有实实现 (sub_141398350), `CEffectTooltipEffect` 用默认空串 |
| [8] | **BuildTooltip** (递归拼 tooltip 串: token→串 + 深度缩进 + [14] 门 + 调 [7] 取键值对 + 子递归 [8]; 覆写多为 CEvery*/循环类) | 20 | sub_14053F090 |
| [9] | GetDesc wrapper (`调用 [7]` 后返 a2) | 461 同 sub_140177420 | 全家族同址 |
| [10] | 逐类 (4) | — | — |
| [11] | **HasMultipleTooltipVars** (默认: 叶 0; 单子查子 [7] 串空; 多子数 "非空" 个数 >1) | 4 | sub_140540690 |
| [12] | **ExecuteChecked** — Execute 作用域校验包装 (过则调 [13]; 不过按 [19] 掩码抛 "Invalid Scope", effect.cpp:555) | 5 | sub_14053D9E0 |
| **[13]** | ★ **Execute** | **375** | 9 锚点全中: CAddLegitimacyEffect 0X14034AA80 / CAddStateClaimEffect / CAddStateCoreEffect / CCreateEquipmentVariantEffect 0X14049BFA0 / CCreateUnitEffect / CAddIntelEffect / CCreateFactionEffect / CSetFactionManifestEffect / CSetFactionRuleEffect |
| [14] | 默认 `return 1` | 462 | sub_1401807B0 |
| [15] | 默认 (恒定) | 470 同 sub_14053FFD0 | 无覆写 |
| [16] | 默认 (恒定) | 470 同 sub_1405404F0 | 无覆写 |
| [17] | 默认 (恒定) | 470 同 sub_14053FFA0 | 无覆写 |
| [18] | 默认 (恒定) | 470 同 sub_1405404C0 | 无覆写 |
| [19] | **GetSupportedScopeMask** (引擎文档构建器 0x14053EE80 直证标签 "supported_scope"; 同掩码兼执行门: sub_140540810 逐位探 ctx 各子 scope, 全不中报 "invalid effect scope" effect.cpp:685; 覆写全为常数, ICF 折叠: 44 类 return 2 / 265 类 return 4) | 309 变 | sub_140120540 (基) |
| [20] | **GetSupportedTargetMask** (文档构建器直证标签 "supported_target"; 每类常数位掩码: 基 `return 2`; 覆写 12/16/128/1532 等, 1532 = target 词汇 THIS\|ROOT\|PREV\|FROM\|OWNER\|CONTROLLER\|CAPITAL\|OCCUPIED) | 348 同 sub_140177700 | [22] 以 target 类型码映射逐位校验 (与 CTrigger[17] 同款) |
| [21] | **IsValidScopeMask** `!a2 \|\| ![19](a1) \|\| ([19](a1)&a2)` | 470 全同 sub_14053D7F0 | 调 [19]; scope 掩码可接受性判定 |
| [22] | **ValidateTargets** (+36 `&0x400` 门 + 逐位配对 [20] 掩码, 缺位返 0) | 470 全同 sub_14053D750 | — |
| [23] | **ResolveReferences** (基 = guard_nop; 派生 trait/policy 族实装: 遍历名字数组按名查 gameitemdb 条目后绑定, gameitemdatabase.h:142 断言) | 396 = guard_nop | ICF; h1j 六实例: load_focus_tree 1403A7F70 (FNV 查树) / swap_ruler_traits 1403A8240 (成对强制 :2667) / targeted 三族 1403A82D0 (ICF×3, +280 旗 :14629) / unlock_decision_tooltip 1403A8530 / category 1403A84A0 (B 型 :14287) / start_border_war 1403A81A0 (双侧三事件校验) |
| [24] | 默认 (恒定) | 468 同 sub_140541A30 | — |

> ⚠ [6] = ParseTargetToken 槽 (作用域键解析), **跳过此槽 = token 流错位崩溃**; 块级 Parse 主入口 = [3]。

**CTrigger 全槽表** (覆盖数 = 546 个实测vtable; 另有可选扩展槽 [23], 仅 241/546 实测vtable含):

| 槽 | 语义 | 覆盖 | 证据 |
|---|---|---|---|
| [0] | 析构 | 89 变 | — |
| [1] | **GetName** (建子触发器时存关键字 token 到 +32; 本槽查 lexer 返 token 文本, 未命中经 +44 懒构缓存串 +56; 与 CProfiledScopeObject/CEffect [1] 同一虚函数) | 544 同 sub_14054E9E0 | 仅 CScriptedTrigger 族覆写返脚本名 |
| [2] | **IsAssignTrigger** (基 `return 0`; 16 覆写全为变量/数组/日志赋值型 → `return 1`) | 532 同 sub_14011D220 | 与错误串 "Non **assign** trigger is not enclosed in {}" 术语吻合 |
| [3] | **校验作用域的 Evaluate 外壳** — 作用域合法 → 转 [22]; 非法 → 报 "Invalid Scope, supported/provided" (trigger.cpp:460) 返 0 | 545 同 sub_14054D0B0 | count_triggers 语义建立于此槽 |
| [4] | **ParseValueKeys** (覆写主体 = 逐类值键解析: bool 族共享 0X1413A2430 / 比较族 0X1413A2540 / 名 token 族 0X14031EDE0; 原语 = sub_1424C08D0(整) / sub_1424C0A70(fixed×1e-5 内层 sub_1424C53E0) / sub_1424C0C00(bool); **基实现 = scope-target token 兜底**: switch 9 token → +36 类型码 + `event_target:` 查表, 败报 "Invalid scope target assigned" trigger.cpp:530) | 47 | 0x14054AE70 (基) |
| [5] | ★ **Parse** — 块解析主入口 (存 lexer 位 +44; 非 assign 触发器无 `{}` 包裹报 "Non assign trigger is not enclosed in {}"; 循环取 token 逐个调 [6]; 收尾校验调 [7], 假 → parser 报错 trigger.cpp:563; 覆写 = 直接数据形态触发器, bool 族共用 0X1413AAAA0 / while_loop 特例 = 内联 CAndTrigger) | 21 | 0x14054FD00 (基) |
| [6] | ★ **ParseToken** — 逐 token 分派 (值类 token → 消费为本触发器参数落 [4]; 触发器关键字 → 建子触发器工厂 "Unknown trigger-type" + 校验子 scope "Invalid scope type for trigger" trigger.cpp:686 + 挂 +8 子表 + 调子 [5]; if/else_if/else 配栈 = CIfTrigger 在此槽的覆写; 数组/变量族 108 组覆写解析各自值形态) | 93 | sub_140550030 (同 CEffect[4] 形态) |
| [7] | **Validate** (基恒真; [5] 块解析收尾调用, 假 → parser 报错 trigger.cpp:563; 6 覆写 = 集合/网络/学说族查配置缺失) | 542 同 sub_1401807B0 | 同址三用之一 (与 [13] 基/赋值族 [2] 覆写共享 `mov al,1;ret`) |
| [8] | **GetScopeTargetID** (按 +36 类型码从 ctx 各字段取 scope 实体, 返实体 +8 缓存 id) | 546 同址 (全继承) | sub_14054EB40 |
| [9] | GetScopeTargetUID (推定; 同分派, 直读实体 +168 = 权威 id 源) | 546 同址 (全继承) | sub_14054F360 |
| [10] | GetScopeTargetObject (推定; 同分派, 句柄解引用返对象指针; 0x200 位走 event_target 查表) | 546 同址 (全继承) | sub_14054F1B0 |
| [11] | **GetTooltip** (遍历 +8 子表: 子 [21] 描述 + '\n' + 子 [3] 满足布尔交回调拼行, 递归子 [11]; 容器类 23 组覆写改头部/递归形态) | 24 | sub_14054C580 |
| [12] | **GetTooltipText** (遍历子表调 [21]+[3], 按 Evaluate==a4 前缀本地化 TRIGGER_UNFULLFILLED_PREFIX / TRIGGER_FULLFILLED_PREFIX — 前缀 helper = sub_14054F770 / sub_14054E880, 按缩进参数重复 "   ", 递归子 [12]; 量词子类实例: any_army_leader = 0x140452910 / any_navy_leader = 0x140453F30, a1+88 tooltip 串空时回退 loc 键 TRIGGER_ANY_ARMY_LEADER_STARTS / TRIGGER_ANY_NAVY_LEADER_STARTS, tooltip 只取过滤名单首元素入 scope) | 24 | sub_14054C800 |
| [13] | **ValidateLate** (基恒真; 批量校验入口遍历触发器队列逐个调本槽, 假 → 抛 "Trigger failed to validate: " trigger.cpp:117; 52 覆写 = 引用数据库条目族: 名字串查表解析 id 后绑定) | 446 同 sub_1401807B0 | 同址三用之二; 与 [7] 分名按调用点 (解析收尾即时 vs 延迟批队列), 引擎原名未决 |
| [14] | **GetSupportedScopeMask** (文档构建器 0x14054E320 直证标签 "supported_scope"; 纯虚! 派生全常数体: 主流 return 4 国家域 / return 8 角色长域 / return 0 变量赋值类; 消费者 sub_14054F7E0 逐位探 ctx、[3] 错误串、[16] [18]) | 纯虚 | ICF 折叠组: 0x1402E30E0=return 4 等 |
| [15] | **GetSupportedTargetMask** (文档构建器直证标签 "supported_target"; 纯虚! 派生常数体 return 0/2/316/1532, 词汇 = target 列; 唯一消费者 [17]: ==2 直接判无效, 其余按类型码映射逐位验证; 与 CEffect[20] 同构) | 纯虚 | 0x140177700=return 2 组等 |
| [16] | **IsScopeCompatible** `!a2 \|\| ![14]() \|\| ([14]()&a2)` (所需掩码与外部掩码有交集; 无覆写) | 546 同址 (全继承) | sub_14054CD60 |
| [17] | **ValidateAssignedScope** (+36 &0x400 已指派门 → [15] 掩码, ==2 → false, 类型码映射逐位验证; 无覆写) | 546 同址 (全继承) | sub_14054CCD0 |
| [18] | RegisterTrigger (推定; 基 = guard_nop 空体; ~112 覆写按 [14] 掩码位把关键字文本注册进不同 per-scope 注册表) | 424 = guard_nop | ICF |
| [19] | Traverse (推定; 取 ctx+56 访问器造遍历状态, 递归子 [19] 短路 bool; 无覆写) | 546 同 sub_14054ACB0 | — |
| [20] | Traverse2 (推定; 同 [19] 形态递归子 [20], 尾多访问器状态清理; 仅 CScriptedTrigger 覆写; 与 [19] 分工待裁) | 545 同 sub_14054AD90 | — |
| **[21]** | ★ **GetDesc** (返回 CString 描述) | **427** | CAlwaysTrigger sub_1403F2080 ("TRIGGER_ALWAYS_TRUE/FALSE") / CIsDebugTrigger 0X14041E0C0 / CIsGeneralCapturedTrigger sub_1402F9080 (皆 `__m128i*` 输出缓冲组装串) |
| **[22]** | ★ **Evaluate** (返回 bool) | **402** | CIsDebugTrigger `return byte_14332EC69 == *(a1+88)` / CAlwaysTrigger `return *(u8*)(a1+88)` / CIsGeneralCapturedTrigger sub_1402F8C90 全 bool 返回 |
| [23] | 逐类扩展槽 (基类 23 函数槽 0..22 之外) | 167 变 | 仅 241/546 实测vtable含此槽 |

**effect/trigger 通用载荷槽** (`a1` = effect/trigger 对象真身; 各卡载荷偏移的总表底稿)

| 载荷偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +120 | CTrigger* | limit 过滤触发器 (every/random 收集族) | 推定 |
| +208 | 列表数据 | 收集结果列表 (分配器/容量 @+224, 扩容 ×1.5) | 推定 |
| +232 | int32 | 目标截断上界 (键 `random_select_amount`; 收集骨架截断步读此值) | 推定 |
| +240 | u8 ∨ 匿名结构 (NNB 形状) | `include_invisible` 门 (列表收集族) ∨ 内嵌 `original_tag` 表达式对象 (模板实例化差异: `*WithOriginalTag` 系, Parse 键 19098) | 推定 |

**求值上下文与目标选择字** (effect/trigger 共用口径; 中间层族批量定名时横向定案):

| 位置 | 语义 | 证据 |
|---|---|---|
| 对象+36 | 目标选择位字 (state owner/controller/occupation/固定 tag 等位选; 0x200 = 命名目标, 0x400 = 参与 assigned-scope 校验开关) | GetTargetTag/GetTargetID 槽族派发 + [17]/[22] 校验门 |
| 对象+40 | 固定 tag token (u16, 经 map 查找) | 命名目标分支 |
| 对象+88..+295 | 内嵌 CScopedVariable 208B = 目标 spec (CCountryEffect 族; 非空门 = 块+8 dword → 扩展槽[25] 求值 sub_1405437F0, 否则透传基类; 证 = 296B 单值派生类 ctor/dtor/大小三证精确闭合) | CCountryEffect[25]/[26] (43 派生类成对共享) |
| ctx+24/32/40 | 作用域链节点 (各 scope 子对象槽) | 执行门逐位探针 |
| ctx+80 | character scope | GetTargetCharacter 槽族 |
| ctx+120 | MIO scope | GetTargetMio 槽族 |
| ctx+168 | 州 id (int) | 断言 "Effect checking state controller needs a scope with state assigned." effect.cpp:703 |

掩码位词汇表 (引擎自文档渲染器 sub_14053E190): state / character / combatant / MIO / raid / project / faction / any。

> 载荷参数格通用形态 = **208B 步长 + 门字节** (变量族与脚本值槽系共用; 常见载荷槽位
> 88 / 120 / 152 / 296 / 328 / 504 / 712 / 1608 / 1816 / 2024) — 推定。
> `+240` 行为同偏移双义, 按模板实例化区分 (见上表行内 ∨ 形)。

> **注册壳**: CEffectEntry<T> (16B {vtable@0, doc 串@8}) / CTriggerEntry<T> (24B {vtable@0, desc 串@8, 旗 u8@16}) — vtable仅 2 槽 ([0] 析构/[1] 工厂 malloc+ctor+绑实例), **不含任何键解析**; 注册表 = RB 树 {节点+32=token, +40=entry} (effects qword_143330000 map@+0 / triggers qword_143330050 map@+24)。
>
> **注册插入原语 (定案)**: sub_1405415A0(map, token, entry) = std::map emplace 尾 — 段① debug 前置查重 (门 byte_1435E1B52 + 一次性闩 byte_143330020; 手写 lower-bound 下行, 落点命中即 sub_1424C8080 抛 "_EffectEntries.find( Token ) == _EffectEntries.end()" effect.cpp:83 = 重复注册的编译期断言) → 段② 无条件插 48B 节点 (j_j__malloc_base(0x30): +32 token / +40 entry, 三指针全指 head = 新叶, 色=黑) → sub_1401F6470 红黑重平衡 (尾 node+40 = entry 赋值在平衡之后)。调用点形态 (全语料 10+ 处同构) = 懒构造单例 (qword_143330000 为空 → sub_14053D840) → j_j__malloc_base(0x10) 建 entry (vtable = CEffectEntry<T>::vftable, +8 = 官方 doc 串常量, 形如 "Adds maneuver skill to a unit leader\nExample: add_coordination = 1") → 插入 = §4.32 附注 W1 「temp/plain 名 → $00/$0A 实例」注册映射的落点函数。
>
> **报错侧 (引用互证升定案)**: sub_140540990(effect, &业务串) = effect 错误日志统一入口 — 构造 CLogger (effect.cpp:813, 类别 4096 = §4.26 错误计数同款) → sub_14053FA80 取 effect 名/参数对拼前缀 → 追加 .rdata 常量后缀 → 追加调用方业务串 (文案由调用方 strcpy 入栈 SSO 传入, 如 "value for set_mio_task_capacity is negative."); 8 处调用点抽样一致。
>
> **容器锁哨兵 (待裁)**: map/vector 插入路径在建节点前判 size 槽 == 0x555555555555555 (全语料 78 处同形, 均为容器 size 槽等于该值) → 命中调 unknown_libname_10 (推定 = 抛异常或 terminate, 语义未决) = 容器「已锁定/只读」标记; 与 §4.32/§4.00 容器族的关系待机器码确认。

> **逐类载荷键解析槽 (定案)**: 脚本键 → 载荷偏移的落点 = **CEffect vtable [4]** /
> **CTrigger vtable [4]** (逐类覆写) 与 [6] (通用值消费); 实现形态 = 键 token 减法链
> (`sub r8d,K ; je …`, 未识别键回落通用 0x1424C2060)。通用槽: CEffect [3] = 0x140540B90
> (块分派) / [5] = 0x1401807B0 / [6] = 0x14053D4C0 (仅作用域键); CTrigger [3] = 0x14054D0B0 /
> [4] = 0x14054AE70 (基, scope-target 兜底) / [5] = 0x14054FD00 (块 Parse) / [6] = 0x140550030 (token 分派)。**查某 effect/trigger 的键落点 → 取该类 [4]/[6]
> 。样本 = CAddBuildingConstructionEffect (vtable 0x14274DDE0):
> [4] = 0x14031DB40 逐键 cmp 225 type / 10304 province / 10348 level / 11829 instant_build。

> **用法**: 要读某 effect/trigger 类的行为 → 取该类的 [13] (CEffect, Execute) 或
> [22] (CTrigger, Evaluate) 槽函数; 要读其本地化描述 → [7]/[21] (GetDesc)。
> **CEffect 与 CTrigger 的 GetDesc/行为槽位号不同** (7/13 vs 21/22), 勿混。
> 覆写数极低的槽 (1-5 变) = 基类共享样板; 覆写数高的槽 = 逐类行为所在。

#### 4.00.4 CEventScope 求值/事件 scope 上下文对象 (176B = 0xB0; vftable RVA 0x27D43E8; writer sub_14053BDA0 / reader vtable[4] sub_140538F20 17 键对账)

> Execute/Evaluate 求值上下文与事件 scope 同体 (effect 端 ctx / trigger 端 ctx 同构)。
> 原「无独立 RTTI 类」负定案修正: 有 vftable (0x27D43E8, 活体+类树双证)。
> ⚠ 原 +192/+296 两行废 (sizeof 176B 内两偏移结构上不可能, 系 effect/loader-ctx
> 侧偏移误置); 原 +92 并回 +88 (operation id 对高位 dword, 无独立槽)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | 国 tag id (键 10394; tag 串→id 查表, 失败报 "Invalid country tag.") | 定案 |
| +12 | uint32 | RNG 计数 (键 10171; loader ctx+192==3 走二进制读否则 hash 派生; 每次取用自增 +1, sub_1402F17B0 写点直证) | 定案 |
| +16 | uint32 | RNG 种子 | 定案 |
| +24 | CEventScope* | root 作用域 (键 11412; owned 持有 @+48, malloc(0xB0) 递归读入) | 定案 |
| +32 | CEventScope* | from 作用域 (键 10639; owned @+56; eventscope.h:193 防环断言 "Infinite cycle in event FROM scope" 直证) | 定案 |
| +40 | CEventScope* | prev 作用域 (键 11413; owned @+64) | 定案 |
| +48 | 引用计数对象槽 | root 的 owned 持有位 (析构 sub_140535820 虚调释放) | 定案 |
| +56 | 引用计数对象槽 | from 的 owned 持有位 | 定案 |
| +64 | 引用计数对象槽 | prev 的 owned 持有位 | 定案 |
| +72 | CStrategicRegion* | **strategic_region 裸指针** (键 12014; 按 id 查 gs 区域表回填指针) | 定案 |
| +80 | 8B id 对 | character (键 19478; sub_1401B2240 成对读) | 定案 |
| +88 | 8B id 对 | operation (键 12059; loader ctx+296 门限定; 原 +92 = 本对高位, 无独立槽) | 定案 |
| +96 | CCombatant* | combatant 裸指针 — **不持久化** (writer 断言 "CEventScope cannot persist CCombatant", eventscope.cpp:184) | 定案 |
| +104 | 8B id 对 | ace (键 12770) | 定案 |
| +112 | 8B id 对 | unit (键 10403; 解析端有 obj−16 容器调整) | 定案 |
| +120 | 8B id 对 | MIO industrial_organisation (键 14501) | 定案 |
| +128 | 8B id 对 | purchase_contract (键 19773) | 定案 |
| +136 | 8B id 对 | raid_instance (键 19183) | 定案 |
| +144 | 8B id 对 | project (键 10022) | 定案 |
| +152 | 8B id 对 | **faction (键 10877)** — 书缺行 | 定案 |
| +160 | 块 | saved_event_target (键 13217; 112B 元 CSavedEventTarget; 0x30B 堆节点双容器: @+0 常规 target 按名 u16 排序有序向量 / @+24 tooltip 向量; **仅 @+0 持久化**; 实现面全链见 §4.12.6) | 定案 |
| +168 | uint32 | 州 id (键 439) | 定案 |
| +172 | uint8 | 作用域存在旗 (scope_exists 极性锚定) | 定案 (活体 = 1) |

- 附注: 除 +72/+96 两裸指针外, 句柄槽全部为 8B id 对 {表选择子, 键} (sub_14221F310 注册表解析);
  空槽判定 = 全零判定 (哨兵 qword_14333D528 在 1.19.3 活体 = 0, 书记 0x02DF8CA0_0005EA66 系 1.19.2 值)。
- **类型判别 u32 键** = sub_1405367F0 (scope → 乘数键, 逐型 {combatant 3, country 31, strategic_region 37, state 59, MIO 82, purchase_contract 113, faction 727, raid_instance 1949})。
- 帧重置原语 = sub_140534CA0 (集合求值器首匹配访客的追加原语与之同函数): 重置 = {+8=0, +12=1, +16=1587985054, +24/+32 FROM 链拷, +72..+152 十一型句柄槽清哨兵 (十三型 = country / strategic_region / character / operation / combatant / ace / unit / MIO / purchase_contract / raid_instance / project / faction / state; +8 country 与 +168 state 另清零)} — 求值帧复用入口 (§4.00.12 求值器引)。
- 子 scope RNG 派生 (sub_1402F17B0, 效果 wrapper — 卡归属待裁): 新建 scope 后从父 {+12 计数++, +16 种子} 经 splitmix32 族混淆链 (常数例 1255572915 / 1759714724 / 458671337 / 2126043716) 现场派生新对写子 +16/+12 — 子 scope 种子非继承父值; 随后挂 unit leader (sub_14053B8E0) + +32 ← 父 (SetFrom 形) + 尾调效果本体 sub_141393500。
- 附注: 源键位场 (+36 u32 作用域键位图 + event_target tag u16@+40) **属 effect/trigger 对象**
  (§4.00.3 [6]/[4] 行), 不在 CEventScope 上 (176B 内 +32/+40 被指针占满)。⚠ CEffect[6]
  parse (sub_14053D4C0) 与 CTrigger[4] parse (sub_14054AE70) 在 controller (0x020 vs 0x440)/
  occupied (0x040 vs 0x420) 两键位映射上互相交叉且 CEffect 版与共享求值器相反 — 疑引擎真实不一致。
- 附注 (定案, 函数族): 本表对象 = **CEventScope** (CCountry+16 是 name 串缓存; +16 内嵌 scope 实为 delayed_event 元素 (0xC8) 的 +16, §4.12);
  函数族全在 0x53 区 — **拷贝构造 sub_140534F00** (置 vftable+默认值后经 sub_140535FD0 拷全部
  载荷并克隆 +160 块) / **默认根构造 sub_140535110** (root/from/prev = 自指根哨兵) /
  **析构 sub_140535820** (+48/+56/+64 三引用计数对象虚调释放 + 销毁 +160 块) /
  **SetCountry sub_14053A610** (写 +8; clear=1 先 sub_14053BD00 全清) / **SetState sub_14053B5F0** / **SetCharacter sub_14053B330** (带 clear 参, a3 → sub_14053BD00 清槽; debug 门下空 character 必触发 "Character.IsValid()" :583) / **SetUnit sub_14053B6B0** (ref.h:83 站加严: sub_14221F310 返回须非零且 ≠16 — 排除的谱系形态, 语义待裁; 失败兜底写 CID 哨兵; 无尾段 IsValid — 与 character 不对称)。TLS+16 dword = _ThreadForbidCount (线程禁入门本体, TLS+2144 = 按需初始化旗)。
  (写 +168) / **Clear sub_14053BD00** (+8=none tag、+72..+168 清哨兵, 保 root/from/prev 与 +160 块) /
  writer 0X14053BDA0 (§4.3.23 同锚)。sub_140535815 **非函数** = `add rsp,20h; pop rbx; ret`
  共享 epilogue (MSVC 单列 .pdata), 火焰热度实归 sub_1405357E8 (+160 saved_event_target 块 finalize)。
- 附注 (高置信, 运行时形态): +48/+56/+64 = 引用计数对象槽 (书原"未名 runtime-only"定性收窄);
  +80..+155 运行时形态 = 引用指针**或**哨兵 qword_14333D528 (= 0x02DF8CA0_0005EA66) —
  writer 侧 id 对为派生形态; +96 combatant 槽 ctor 清 0 与"永不持久化"断言互证;
  +160 = 0x30B 堆节点双容器 (112B 元素 ×2)。
- 附注 (定案, 链路): 事件选项执行 (§4.33.18) 本体零族内调用 — 内嵌 scope 块只作指针传入;
  scope 的构造/填充/析构全发生在派发侧 (双国版 sub_14066B0D0 / 国家+州描述符版
  sub_1407386A0, eventscope.h:193 无限 FROM 环断言); 入队后消费路径未决。
  另 sub_140BB3E00 与 sub_140BB3E72 = gamestate.h:1126 国家索引规范化的**代码克隆对**
  (同断言/同 guard/四条独立证据), 火焰热度为同一逻辑函数机械分摊。

setter 全家对照 (定案, 函数→槽一一对应; 消费端构造临时 scope 的全部写入点; id 对槽 setter 的统一断言通道 = ref.h:83 `"GetPtr() != 0 && \"This Object is not created or a valid CReferenceObject...\""` — 先解 \*(a2+8) 再落槽, 无效引用 = debug 断言 + 落哨兵 qword_14333D528):

| setter | 槽 | 语义 | 备注 |
|---|---|---|---|
| sub_14053A610 | +8 | SetCountry (clear 门变体 = sub_14053B470 tag 版) | 消费端最高频 (178 调用点) |
| sub_14053B670 | +72 | strategic_region 裸指针直写 | |
| sub_14053A400 | +80 | character CID 对直写 | 断言 "Character.IsValid()" |
| sub_14053B8E0 | +80 | character (自 unit leader 取) | 断言 "pUnitLeader->LookupCharacter()" |
| sub_14053B330 | +80 | character (自 CReferenceObject 取 a2+8) | ref.h:83 |
| sub_14053B0F0 | +88 | operation id 对 | ref.h:83 |
| sub_14053A590 | +96 | combatant 裸指针直写 | |
| sub_14053A250 | +104 | ace id 对 | ref.h:83 |
| sub_14053B6B0 | +112 | unit (取 a2+24) | 断言 "pUnit" eventscope.cpp:598 |
| sub_14053B030 | +120 | MIO id 对 | ref.h:83 |
| sub_14053B1B0 | +128 | purchase_contract id 对 | ref.h:83 |
| sub_14053B270 | +136 | raid_instance id 对 | ref.h:83 |
| sub_14053A690 | +152 | faction id 对 | ref.h:83 |
| sub_14053B5F0 | +168 | SetState (u32 直写) | |
| sub_14053B4B0 | +168 | SetState (自描述符 a2+88 取 id) | |

配套: getter sub_140535C20 (+80 解析) / sub_140535DB0 (+88 解析); **第二构造变体 sub_140534FE0** (默认根 + 全槽哨兵 + **+16 写 RNG 种子初值魔数 1587985054**, 高置信 — 与 CVariables ctor 种子#2 常量同源); 全载荷拷贝 = sub_140535FD0 (copy ctor 内核)。scope RNG 进入/退出配对体 = sub_140542150 (TLS random_seed 重哈希, §4.32.16a)。

- 附注 (定案, idpair 解析原语口径): **sub_14221F310(idpair) 返回 = 该类 CReferenceObject 子对象地址** (全零/未注册 → 0; 三档表选择子 type>4712 / 100..4712 / <100)。子对象偏移随类而异: CUnit 系 = raw+16 (本体 = 返回值−16; 三处独立互证: 判零式 `v==16` / 返回+456..+460 落 CUnit+472/+476 owner 域 / GetTheatre 调用前显式−16); CAirGroup 等以 CReferenceObject 为首基的类 = raw+0 (解析值直接作 this, airtheatre.cpp 三消费点直证; CAirWing 注册值 = 本体 real+16 同 CUnit 系, −16 回本体三消费点一致)。**sub_1402AA280 = raw 直取糖** (函数体即 CUnit 系−16)。凡消费解析返回值再按偏移读, 偏移一律属 raw 坐标系, 帧原点按类先定 — 勿按返回值基址记偏移。

#### 4.00.5 基类普查与工具法

- **槽位方差法 (定基类槽语义的通用法)** 以 `CEffect` 为例:
  取该基类全部后代类 → 各解vtable → 逐槽统计「有多少类覆写 / 出现多少种取值」。
  - **恒定槽 (1 种取值)** = 基类共享样板 (如 CEffect[2] 470 类全同) → 读一次即懂。
  - **高方差槽** = 纯虚/逐类行为所在 (如 CEffect[13] 375 类覆写 = Execute)。
  - 再用「已知方法地址反查落在哪槽」(如 9 个 `Execute` 锚点全落 CEffect[13]) 定名。
- ⚠ **COL 判据坑**: MSVC COL signature **多继承=1 / 单继承=0** —— 只认 sig=1 会
  把 `CBoolTrigger`(114 派生) 等大批单继承基类误判为「抽象无vtable」;
  解vtable须同时接受 sig=0/1 (sig=0 时自指 RVA 校验写在 +20 语义不同, 靠派生类反查兜底)。
- **抽象判据**: 类无 COL-referencing vtable 且无自有 `vftable` 符号 ⇒ 抽象/不可实例化
  (CPersistent / CPersistentWithToken / CTriggerDataMembers / CPdxAllocator / CObjectType …)。

#### 4.00.6 控件层 (按钮管线 / 网格列表 / 选项)

**CGridBox 运行时布局** (gridbox.h; 断言 `Index < _Elements.GetSize()` :654 = +428 计数; 6 消费者互证):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +368 | int32 | max_slots 横 (type 侧 max_slots_horizontal(617)→type+440 运行时对应) |
| +372 | int32 | max_slots 纵 (max_slots_vertical(616)→type+444 对应) |
| +384 | uint8 | 流向字节 (add_horizontal(614)→type+456 对应): 1 → d1 先增 / 0 → d2 先增 |
| +392 | CCoordPair* | 格坐标数组 data (8B 元 {u32 d1, u32 d2}) |
| +400 | int32 | 坐标数组 cap |
| +404 | int32 | 坐标数组 count (= 活动行数; 填充循环先复用已有行, 越界才 malloc 新行) |
| +416 | CGuiObject** | _Elements 条目指针数组 data |
| +424 | int32 | _Elements cap |
| +428 | int32 | _Elements count = GetSize() (:654 断言对象; 下标界) |
| +504 | CButtonEventDispatcher | 内嵌 (见下) |

五原语: AddItem@格 sub_1402DE9B0 (gridbox, item, &cell, 旗, 1) / 追加(自动格) sub_1402DEC80 / 重排 sub_1422C7E50 (填充完统一调) / 显窗 sub_1422C4970 / 滚动范围 sub_1422CAA00。下一格算法 (三处同构): 读坐标数组末元素, +384=1 → d1+1 (≥+368 → d1=0,d2+1, 界 +372); +384=0 → 对称; 任一界 ≤0 = 不设界直落 AddItem。回收池喂入 (消费侧) = 宿主+32 池 data / 宿主+44 池 idx (`data[8×(idx−1)]` 后 idx−1) — §4.31.96 池 B 的宿主内嵌无 vftable 形态; pdx_view §3.12 迭代器 + 96B 条目直接喂格 (sub_1420572B0)。

按钮管线 (定案): widget 侧 CButtonStandard (vtable 0x142B472E8 = CGuiObject 链@0 +
CButtonObservable@128 订阅表) 经 Broadcast sub_1422AFA70 逐个调 observer->vtable[1];
观察者侧三级: **CButtonEventDispatcher** ← **CButtonObserver** ← **CButtonObserverGlue**。
**CButtonWrapper (0x14294C180, 2 槽, 1368B) = glue 的按钮句柄宿主 (定案)**: 主基 CTooltipHandler ([0] BuildTooltip 委托 +1304 std::function, callable 在 +1360), 次基 CButtonObserverGlue (+24 = 20×64B 事件回调表); 注册 = 订阅 button+128 (observer = wrapper+16) 且当 +1360 callable 非空时 `button->vt[69](button, wrapper)` 注册为 tooltip handler (写 button+80)。builder 0x1422DCB20 / Init 0x1422DDB50 / Assign 0x1422DDC40 / Clear 0x1422DD950 — 布局与注册链全表见 §4.31.95; ref/hoi4_runtime_vt2class.json 无 CButtonWrapper 条目 (CLegacyButtonObserverGlue\<T\> 特化 465 个)。

CButtonEventDispatcher (0x14273AA20, 2 槽) vtable槽表 ([0] = 析构 sub_1402DE810: `*a1 = &CButtonEventDispatcher::'vftable'; if(a2&1) free` / [1] = _purecall Dispatch):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | Dispatch (纯虚) |

> [0] = scalar deleting 析构 sub_1402DE810 (`*a1 = &vftable; if(a2&1) free`) — 注失实撤除 (正文已含)。

CButtonObserver: 抽象, = CButtonEventDispatcher + 10 纯虚 OnXxx (BaseClassArray
mdisp 全 0 直证); 具体槽位经 CButtonObserverGlue 落位。

CButtonObserverGlue (基表 0x14273AA38, 12 槽, 479 派生) vtable槽表 ([0] = 析构 thunk sub_1402DE7C0: `sub_1402DE480(Block+8); *Block = &CButtonEventDispatcher::'vftable'; if(a2&1) free`; ⚠ 0x142A17008 是 `CLegacyButtonObserverGlue<CCryptologyMapIcon>` 特化表, 其 [0] 与基表同址):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | **0x1422AFB40** (button.cpp 共享实现, 479 派生共用) | 事件总路由 Dispatch (switch event->type, 分派表见下) |
| [2] | — | OnDrag |
| [3] | — | OnClick |
| [4] | — | OnRightClick |
| [5] | — | OnDoubleClick |
| [6] | — | OnMouseDown |
| [7] | — | OnMouseEnter |
| [8] | — | OnMouseUp |
| [9] | — | OnMouseLeave |
| [10] | — | OnMouseWheel |
| [11] | — | OnKeyboardActivate |

> [0] = 析构 thunk sub_1402DE7C0 (定案)。+8 起 20×64B std::function 回调表 (**槽内 +56 = callable
> 指针**; 写入侧锚点 E1190→k3 互证)。游戏代码 = CLegacyButtonObserverGlue\<T\>
> (12 槽与基类全同址, 特化全在 ctor 绑定: OnClick→回调槽 k0 / OnRightClick→k3 /
> OnDoubleClick→k4)。

事件类型枚举 (event+36):

| 值 | 名称 | 语义 |
|---|---|---|
| 1 | Up | — |
| 2 | Down | — |
| 3 | Enter | — |
| 4 | Leave | — |
| 5 | Click | 左→槽 / 右→槽 |
| 6 | DoubleClick | 兜底转 Click |
| 7 | Drag | — |
| 8 | Wheel | — |
| 9 | 键盘 Activate | — |

Dispatch (0x1422AFB40) 事件类型 → 槽位分派表 (事件结构 = 载荷 A@+0 / 载荷 B@+8 / 载荷 C@+16 / 位置载荷@+24 / 鼠标按钮 u32@+32 / 事件类型 u32@+36):

| 事件类型 | 按钮约束 | 目标槽 | 透传实参 | 返回值 |
|---|---|---|---|---|
| 0 | — | 不分派 | — | 0 |
| 1 (Up) | 仅按钮 1 | [8] (+64) | +24 | 1 |
| 2 (Down) | 仅按钮 1 | [6] (+48) | +24 | 1 |
| 3 (Enter) | 无约束 | [7] (+56) | +24 | 1 |
| 4 (Leave) | 无约束 | [9] (+72) | +24 | 1 |
| 5 (Click) | 按钮 1 → [3] (+24) 无参; 按钮 2 → [4] (+32) 带 +24 | 见左 | [3] 无参 / [4] 带 +24 | 1 |
| 6 (DoubleClick) | 仅按钮 1 | [5] (+40) | 无参 | 1 |
| 7 (Drag) | 仅按钮 1 | [2] (+16) | +24, +0, +8 (三参) | 1 |
| 8 (Wheel) | 按钮 0..4 全部分派, **不做校验** | [10] (+80) | +24, +16 (两参) | 处理槽返回值 |
| 9 (键盘 Activate) | 仅按钮 1 | [11] (+88) | +24 | 处理槽返回值 |
| >9 | — | 不分派 | 断言 "Invalid event type" (button.cpp, 门 byte_1435E1B51) | 0 |

> 鼠标按钮校验边界 (定案): 合法按钮 = 1(左)/2(右)/3(中)/4(X1); 类型 1/2/5/6/7/9 在按钮 ≥5 时发 "Invalid mouse button" (各带独立 latch, 门 byte_1435E1B51, once-only); 按钮 2..4 在非 Click 事件静默不分派 (非非法)。按钮 0 = 空载荷。

CObservable 模板:

| 项 | 值 |
|---|---|
| 链表头 | +8 |
| 尾 | +16 |
| 计数 | +24 |
| 延迟删除旗 | +28 |
| [1] Subscribe | 0X142230980 |
| [2] Unsubscribe | 0X1422AF9C0 |

网格/列表:

| 类 | vtable | 槽数 | 要点 |
|---|---|---|---|
| CStandardGridBoxItem | 0x142B45EF0 | 19 | +8 打包 cell 坐标 / +16 CGuiObject\* 薄转发器集; Select/Unselect = byte165&0x10; COL 0x142DDF5C0, 全 exe 唯一基表 |
| CStandardGridBox (容器) | — | — | 内嵌 CButtonEventDispatcher@504 + dispatcher 列表@+416 |
| TListboxItem | 0x142B42AA8 | 24 | 大部纯虚的列表条目接口, +8=CGuiObject\*; 与 GridBoxItem **同构姊妹接口** (转发函数同址直证) |
| CStandardlistboxItem | 0x142B42B70 + 0x142A86410 (双 vtable) | 13+24 | = COption + TListboxItem 组合 |

选项:

| 类 | vtable | 槽数 | 要点 |
|---|---|---|---|
| COption | 0x142B4A5A0 | 9 | Check/Uncheck (广播) / IsChecked / SetChecked (静默); flag@+48; COL 0x142DE1590 |
| COptionObservable | 0X142B40C48 | 4 | 纯 observable mixin |

观察者小族:

| 类 | vtable | 槽数 | 纯虚槽 | 胶水形态 |
|---|---|---|---|---|
| CCheckBoxObserver | 0X142739AF8 | 7 | [1]..[6] 回调 | 胶水 = {vtable, target, 6×fnptr} + forwarder 池 0X1402E08A0-0X1402E10B0 |
| CScrollbarObserver | 0x1429c3da0 | 6 | — | 复用同池, 槽序非顺序: [1]→+16 / [2]→+40 / [3]→+24 / [4]→+32 / [5]→+48 |
| CTextBufferObserver | 0x1429ad1c8 | 10 | [2][4][6][8] | 胶水 = {fnptr, delta} 16B 对 |

#### 4.00.7 命令层 CCommand

| 项 | 值 |
|---|---|
| RTTI | CCommand |
| vtable | 0x142977040 (24 槽) |
| 直接派生 | 452 |
| 基链 | CPersistent@0 |
| writer / reader | 全家族共享 0X14226A110 / 0X142269E60 (槽 [2]/[4]; 唯一例外 = CIsHighCommand 自行覆写) |
| 基类实例大小 | 0x28B |

CCommand vtable槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | 共享 (见 §4.00.1) | Save wrapper |
| [2] | 0X14226A110 | **writer 本体, 全家族共享** (412 vtable方差各 1 种取值, 具体命令类不覆写) |
| [3] | 共享 (见 §4.00.1) | Load wrapper |
| [4] | 0X142269E60 | **reader 本体, 全家族共享** (同 [2]) |
| [9] | — | **IsValid** (基座默认 = mov al,1 真; 派生覆写) |
| [10] | — | **Execute** (基座有默认体; 派生覆写, 与 CEffect[13] 同性质) |
| [11] | — | **GetTypeId** (基座默认写 10455; 每类常数, 示例: CAddAdvisor=19564 / CAddConstruction=12151, 全表 445 值零碰撞, 值域 290..19942, 全表 = §4.33.2) |
| [12] | — | 会话旗标 (高置信) |
| [13] | — | **Clone** (基座有默认体; drain 侧克隆重播用) |
| [15] | — | 会话旗标 (高置信) |
| [16] | — | 会话旗标 (高置信) |
| [17] | — | GetDesc (默认空串) |
| [18] | — | +16 (u32) getter |
| [19] | — | +16 (u32) setter |
| [20] | — | +20 (u16) getter |
| [21] | — | +20 (u16) setter |
| [22] | — | **载荷 writer** (基座默认 = 空实现; 派生覆写) |
| [23] | — | **载荷 reader** (基座有默认体; 派生覆写) |

> 补槽 (PE 直读): [0] = 0x1401C94A0 析构 / [5] = ret0 / [6][7][8][14] = CFG 空桩 — 与抽象基表 0x1427214C8 逐槽同构, 具体命令表六槽无新行为。每类差异序列化全走 [22]/[23] 载荷钩子 (家族 452 派生中
> 仅 CIsHighCommand 覆写 [2]/[4], 其余全同址)。

执行与路由: 执行 = **vtable [10] Execute**; 路由 = order.cpp:273 **id→构造函数表**
(按 [11] GetTypeId); 会话链: post sub_142250B00 (写 +12 发送方 / +22 tick 戳) →
drain sub_142252D00 (IsValid 门 → Execute → [13] 克隆重播, +8 重播门旗防重入)。

CCommand 实例布局 (基类 0x28B):

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | — | 重播门旗 | — | drain 侧重播防重入 |
| +12 | — | 发送方 player id | — | ctor 写 −1; post 写入 |
| +16 | uint32 | 定向命令目标 machine id | — | getter [18] / setter [19]; 槽[5] 定向发送按它查连接 (§4.36.3) |
| +20 | uint16 | 定向命令目标辅 id | — | getter [20] / setter [21] |
| +22 | — | tick 戳 | — | 0xFFFF=未投递; post 写入 |
| +24..+32 | — | SInternalData 持久项 | — | 单字段跨字节范围; +28 = **identity 序号** (u32, 主机侧分配, 命令日志顺序键, "ID:" 日志值) / +32 = **origin 序号** (u32, 发送侧分配, 客户端回声 RTT 配对键, 主机转发时保留) (§4.36.3) |
| +40 起 | — | 派生载荷 | — | 各具体命令类布局另查 |

> reader 双通道: token 65 = 文本逐 token 调 [23]; token 499 = 二进制整块。
> 载荷 token 流（基座契约实证）: 基座 writer 写 499（SInternalData blob）+ 65 循环头后
> 逐字段调 [22]; 基座 reader 收 65 后循环取 parser 当前 token 逐个派发 [23]（哨兵
> token 4/19 收束; 未接 token → 0x1424BEC40 读弃）。

载荷判读原语语义表 (reader/writer 函数 → 语义; 逐命令载荷定案的判读基座):

| 地址 | 语义 | 证据 |
|---|---|---|
| 0x1424C0AA0(parser, obj) | 嵌套 CPersistent 对象读: 调 obj→vtable[3] (Load wrapper) | 单行虚调, 槽 24/8=3 |
| 0x1424C08D0(parser, out) | 读 u32 (缓存未命中走 0x1424C1E40 兜底; "%i" 探测 0x1424C5220) | 体 = 0x1424C5220 探测 |
| 0x1424C0840(parser, out) | 读 int ("%d" 探测 0x1424C5130, 与 08D0 同构) | 体探测直证 |
| 0x1424C0900(parser, out) | 读 u32 变体 (0x1424C5250 探测) | 体同构 |
| 0x1424C0A70(parser, out) | **读 fixed×1e-5 (i64 承载)** — 内层 0x1424C53E0 = "%lli" 整部 + '.' 后至多 5 位小数 ("00000" pad) 定点十进制解析 (原「读 i64」与本表 :371 行 fixed×1e-5 归一) | 体直证 |
| 0x1424C0BD0(parser, out) | 读 i64 — 内层 0x1424C55E0 = strtol(text,&end,10) (失败抛 "Malformed token") | 体直证 |
| 0x1424C0C00(parser, out) | 读 u8/bool (0x1424C5640) | 体同构 |
| 0x1424C0C30(parser, obj) | 读文本标量 → 40B 临时对象 (大小 u32@+12); 落 MSVC 串走 resize+data 对 | reader case 直证 |
| 0x1424C0AB0(parser, &str, flag) | 读 MSVC 串 (失败回退 "Unreadable String") | 体含该串 |
| 0x14221F970(parser, &id) | **CID 列表跳读器**: 要求列表头 (type 3 '{'), 跳读至 '}'/EOF (11/225 数字型 "%u" 探测前进); **出参恒写 0** (单出口双清) — CID 语义仅存于错误串 "Expected start of list reading CID"; 值流是否经 parser ctx 提交未决 (price_levels 键 idpair 数据流矛盾待裁) | 体直证 (单出口) |
| 0x140BB5560(parser, out) | tag 串解析→u32 (读 parser+200 当前串→0x140BB3EF0 查表) | 体直证 |
| 0x1401F95D0(parser, c) | 读 u32 数组 (循环至哨兵 token 4/19; 元素 0x1424C08D0 push; 1.5 倍扩容) | 体直证 |
| 0x1424C2060(parser) | 未知键默认汇点: 报 "Unexpected token" + 跳过子树 | 体直证 |
| 0x1424C21D0(parser) | 跳过子树变体 (无报错, 静默吞; CCountry::Load railway 门假支同款) | reader case 直证 |
| 0x1424C2100(parser) | 块深度平衡跳过器: 遇嵌套块 ++ / 遇块尾 --, 扫顶返回 (类型 3 遗留键值逐子值扫描; 返回值丢弃语义待裁) | CCountry::Load LABEL_117 直证 |
| 0x1424BEC40 | 共享读弃空 reader (基座 [23] 默认; 体 = 纯转调 0x1424C2060) | 体 = 读弃 |

**std_pair_parser.h 模板族 (20 件全量定性)**: `pair_parser<First,Second>` 模板 20 实例化 =
pdx 容器解析族 (std_map/unordered_map/array parser) 的 **pair 值元素专用层** (文本 token 流域,
与 defines 装载器族同形态学但域不同 — 不碰 lua/define 槽)。骨架: 门① type≠3 ('{') 抛
"Expected start of list for pair of element" → 循环 {First@+0 / Second@槽 (+1/+4/+8/+32/+40
由实例定) / ≥2 抛 "third element"} → n≠2 抛 "less than two" → 尾门 ctx+24 错误计数 →
sub_1424C0060(ctx, "std_pair_parser.h", 71); **@变量解析内建于骨架**; 三个 throw 串全簇共享。
消费域终端 8 个 (gamestate/itemdatabase/equipment find_and_replace/country_supply/eventscope/
linechart/variablescripthelper/scopedptr), 24 调用点无未接件。**price_levels 文本装载链闭环
(定案)**: sub_140DF2C40 (std_map 装载器, 节点 {key 8B@+28 双 u32 字典序, value@+36} 与 §4.23
price_levels 布局精确吻合) → sub_140DF2600 pair (first = 0x14221F970 跳 CID 列表, second = 内联
token 开关 low(19365)/normal(119)/high(19367)→0/1/2, default 报
international_market_serializer.cpp:378) — 与 §4.23 档因子映射 0→LOW/1→标准/2→HIGH 全对上。

**S\*Reader 解析描述子族 (机制定案, 全族 43 类批扫)**: 资源文件
(gfx/sound/entity/weather/粒子/字体/posteffect) 的 `S*Reader` 命名类是**解析器
栈上描述子, 非持久数据** — 宿主解析函数按 token 分支栈上构造 Reader (写
vtable + 目标槽地址) → 喂给三条统一块读通道: **sub_1424C0AA0** (嵌套 CPersistent
读 thunk, 上表首行) / **sub_1424BE690** (Load wrapper) / **sub_1424BEC40** (异常
thunk) → 产物搬进宿主资源数据库条目, Reader 随栈帧丢弃。多宿主类由 copy/move
ctor (vector 中转) 解释, 无堆生命周期反例。已知例外 (持久/非描述子):
SGfxSettingsReader = CEntitySprite+1392 内嵌 ≥104B (owner 回指 +1456, 双 SSO);
SSpriteFramePair = 48B 运行时 sprite 选择值对象 (非 Reader); SCVAASettings =
CSettings+896 内嵌 56B; SAudioContext/SSDLAudioContext = 音频后端运行时件。
| 0x140CEE8F0 | jmp 0x1424BEC40 (增量链接 thunk → 共享读弃) | PE 字节 e9 4b 03 7d 01 |
| 0x1424C2E20(w, tok, obj) | 写嵌套对象: 字段头 (tok + 类型 1) 后调 obj→vtable[1] (Save wrapper) | 体直证 |
| 0x1424C2EA0(w, tok, &str, f) | 写串 | 体直证 |
| 0x1424C2F40(w, tok, u32) / 0x1424C34F0(w, tok, i64) / 0x1424C37B0(w, tok, u8) | 写 u32 / i64 / u8 (值格式化分别 0x1424C49E0/0x1424C4900/0x1424C4D20) | 三者同构 |
| 0x1424C3290(w, tok, obj) | 写文本标量 (40B 临时对象形态) | writer case 直证 |
| 0x1424C4220(w, tok) | 写字段头 (块起 + token 名 + 类型 1) | 体直证 |
| 0x1424C4410(w) / 0x1424C3E60(w) / 0x1424C3A20(w) | 缩进 ++ / 缩进回显 / 块收 | 体直证 |
| 0x1401B3D80(w, tok, c) | 写 u32 数组块 (count>0 才发射; 元素 0x1424C2A10; 尾 0x1401F4F00(w,16)) | 体直证 |
| 0x1424CD070 / 0x1424CB4D0 | MSVC 串 resize / data 对 (0x1424C0C30 文本标量落串路径) | reader 直证 |
| 0x140BB4E70(obj) | tag→名串 (writer 侧, 与 0x140BB5560 读向互逆) | 体直证 |

**CPendingAction 待命指令族** (unitcontroller.cpp 域, 与 CCommand 邻接但**非 CPersistent 不入存档** — 运行时待命队列, Execute 时直发命令域命令): 基 = CPendingAction (vtable 0x1429CBC40, [1..6] 全纯虚); 5 派生恰 7 槽契约: [1] 入队预检门 / [2] 类 id 枚举常量 (AddMovement=0 / AddStrategicRedeploy=1 / TransportUnit=2 / StratNavyTransfer=3 / CancelMovement=4, 各为编译器 `return N` 共享桩) / [3] RegisterRefs (引用收集入引擎 vector {ptr@0, cap@+8, count@+12, alloc@+16}, push = sub_1401205A0) / [4] ClearRefsIfIn / [5] IsValid / [6] Execute (AddMovement→sub_140BF9A40; CancelMovement→sub_140BFB4A0; AddStrategicRedeploy→new CStrategicRedeploymentCommand 0x50B; TransportUnit→栈构 CTransportUnitCommand 0x60B; StratNavyTransfer→sub_140EA9660)。入队统一入口 **sub_1414D4B50**(owner, pending): [1] 门 → [3] 收集 → 倒扫 owner+272 待命列表 (count@+284) 逐条 [4] 去重 (同对象旧指令被清引用, IsValid 假则虚析构移除) → push — **新指令实时取代同对象旧待命指令**。工厂: sub_1414C3860 Cancel (unitcontroller 拒动路径两调用簇互证: [15] 校验败清理 / 补给门拒) / 1414C38F0 AddMovement / 1414C3A50 AddStrategicRedeploy / 1414C3AE0 TransportUnit; StratNavyTransfer 在海军转移函数内联构。布局: CPendingAddMovement 56B (+8 CUnit*, +16 路径容器, +48 旗, +52 u32) / CPendingAddStrategicRedeploy 32B / CPendingCancelMovement 24B / CPendingStratNavyTransfer 56B (+16 单位 CReferenceObject 对向量, count@+28) / CPendingTransportUnit 32B (+8 CReferenceObject 智能对经 sub_14221F310 三档 id 库解析)。

#### 4.00.8 负定案与抽象判据

- **CProfiledScopeObject** (TD 0X14313C158, vtable 0x1427180e8): **无数据成员 (定案)** — vtable 仅 2 槽 ([0] dtor+profiler 注销 / [1] GetName 返 "unnamed"); 是
  CEffect 的 virtual base (**有 COL**)。派生 1280 但**纯抽象埋点**,
  **不单列条目**。
- **CPdxAllocator** (TD 0X14313BBF0, vtable 空引用): 内存分配器, **与导出/GUI 无关, 不列条目**。
- **CPersistentWithToken** (TD 0x14313A488, 无 vtable — 全 .rdata 扫 COL→TD 零命中): 抽象; 继承 CPersistent + 静态 token (+8 u32, getter sub_1413CFAF0; 基 reader = sub_1424BEC40 = 单行 `return sub_1424C2060(a2)` 读弃)
  访问器族 (待并入 §4.00.1 —— 未决)。

#### 4.00.9 引擎设施族 (分配器 / 文件 / Steam / 音频 / 网格 / 水印)

通用桩清单 (1.19.3, 读槽/读语义前先滤): `_purecall` = 0x14253C3B8 / CFG 空桩 0x14012A2C0 / `return 0` false 桩 0x14011D220 / `return 1` true 桩 0x1401807B0 / UserMathErrorFunction (未实现占位) 0x140120540 / __acrt_select_exit_lock (ICF 常数桩) 0x140177700 / trivial getter (返 this+8 指针) 0x1402AA270。

**分配器族**: CPdxAllocator 接口 = {dtor, Allocate(size), Free(ptr), 预留槽} 4 槽。

| 类 | vtable | 一句话 |
|---|---|---|
| CPdxNewDeleteAllocator | 0x142716590 | 默认分配器: [1]=0x14011D230 `j_j__malloc_base` / [2]=0x14011D250 `j_free`; **全局默认实例 = off_143085170 (va 0x143085170)**, 引擎容器 ctor 普遍写 = 探针验证容器 allocator 槽的基准值 |
| CPdxLinearAllocator | 0x142B94DC8 | 线性 bump 分配器: +8 游标 / +16 末端 / +24 chunk 链头 (头 24B {next,size,used}, dtor 沿链经 backing 释放) / +32 当前 chunk / +40 backing 分配器 (缺省 off_143085170) / +48 就地旗; 缓冲区起点先 8 对齐 (pad = 8−(start&7), chunk 头落对齐后地址); 就地模式余量 <0x18 (a3 < pad 或 a3−pad < 0x18) → 回退分支 (+48 置 1 + 回退构造 sub_1424FB7D0) + :102 B51/flags=0 日志 (闩 byte_1435E40A0) |

注: **空容器共享哨兵 = 数据槽 0x2E85170**（活体三处独立互证: CStrategicResourcePool 尾槽 / CFocusStatus 空容器槽 / CCountryOperationManager 空槽均读得 `base+0x2E85170`）—— 引擎空容器/未扩展槽普遍以该静态对象指针填充, 探针读到此值按「空」解读, 勿当业务指针或业务量。

**文件族** (全非 CPersistent, 不入档):

| 类 | vtable | 槽 | 一句话 |
|---|---|---|---|
| CFile | 0x142B93ED0 | 18 | 抽象文件基座 (9 纯虚): +8 标志=1 / +16 a3 / +20 a4 / +24 CString 路径 |
| CMemoryFile | 0x142B934E0 | 18 | 全实现: +8 标志=1 / +12 u16=0 / +16 a3 / +20 **模式** (0=起点 / 1=截断 [关源 sub_141254450 + 清 +72] / 2=末尾, 其他 "Not Implemented!" :90) / +56 数据源 (源+0 = 内嵌缓冲) / +64 内存缓冲 / +72 **高水位** / +76 位置 (slot[15]) / +80 **容量** / +84 **溢出旗** ("Out of space" :291/:247) / +85 owned 旗; slot[14] = GetSize; Reopen 0x1424EE320 (:61/:90) / WriteByte 0x1424EE5E0 (:247) / Write 0x1424EE6D0 (:291) — 写路径: 有源透写 (溢出走源自身写), 无源写 +64 缓冲 (容量足更新高水位, 不足回退位置 + 置溢出旗) |
| CArchiveFile | 0x142B92878 | 18 | PHYSFS 归档 (virtualfilesystem.cpp): +56 归档句柄 / +64 旗 |
| CRemoteFile | 0x142B46D58 | 19 | CMemoryFile 薄子类: 槽 [1..17] 逐槽同址全继承, 仅自有 dtor |
| CCloudFile | 0x142B6D268 | 16 | 云文件抽象基座 (14 纯虚), 实现 = CSteamCloudFile |
| CFileLogger | 0x142B3AC78 | 5 | CLogger 子类: +72 sink / +88..+112 状态槽×4 |
| CFileWatcher | 0x1429A66F8 | 5 | CReloadableInterface 系: +40 监视文件名 / +96 std::function 回调 (LoadDefinitions<CMapArrowManager> lambda 内 new 0x68); **下有 win32 原生层** (pdxfilewatcher_windows.cpp, 条目 0x8A8, §4.00.19) |

**CFileIntegrityWatermark** (存档完整性水印; vtable 0x142A9A450 4 槽; 基 CReloadableInterface ← CReloadDispatcher; 非 CPersistent): +40 CFile* 水印文件句柄 / +48 宿主上下文 (其 +1272 = 文件系统对象)。[2] 0x141F57500 = Reset/Reopen: 关旧 → 经文件系统开 "file_integrity_watermark" → 状态门 (file+4324==1) 时写 "watermark_header" 段。存档容器内反篡改水印设施, 不入存档数据层。

**Steam 平台封装族** (10 类, 全非 CPersistent; 抽象 Context 基 RTTI 均在二进制确认):

| 类 | vtable | 槽 | 基 |
|---|---|---|---|
| CSteamAchievementsContext | 0x142B5BE00 | 16 | CAchievementsContext (抽象); 实现域见 §4.28.8a |
| CSteamBrowserContext | 0x142B5E628 | 5 | CBrowserContext |
| CSteamBrowserInstance | 0x142B5E8A8 | 21 | CBrowserInstance |
| CSteamCloudFile | 0x142B6D370 | 16 | CCloudFile |
| CSteamCloudStorageContext | 0x142B6D2F0 | 15 | CCloudStorageContext (字段: +56 CSteamCloudFile* 数组 / +68 count / +72 allocator) |
| CSteamMatchmakingContext | 0x142B6D940 | 46 | CMatchmakingContext |
| CSteamNetContext | 0x142B6E2A8 | 26 | CNetContext |
| CSteamStoreContext | 0x142B6F180 | 20 | CStoreContext |
| CSteamUGCContext | 0x142B6F460 | 22 | CUGCContext (抽象基 0x142B6F2E8 含 16 纯虚) |

**音频族**: **`?A0x9ca8863a::CAmbientSoundDatabase`** (环境音库, TGameItemDatabase 模板实例; 类表 vtable 0x1427E3658 / 模板基表 0x1427E3628; ctor 兼 creator 0x14066ECD0; 单例槽 **0x143330540**) — ⚠ **该类只存在于匿名命名空间** (`?A0x9ca8863a::`), 全局名查找会落空; 条目为无 RTTI 内联 POD (200B/元素)。以下全非 CPersistent: **CMusicPlaybackListener** (vtable 0x142A03C98 11 槽, 基 TListenerTrait\<CMusicPlayer,0\>, [2..10] 纯虚回调接口); **CStandardMusicPlaybackController** (0x142A7C7A8, + CTooltipHandler 双基, [2] 转发 +5200 音频通道); **CStandardMusicPlaylistController** (0x142A7CA68 13 槽, +16 指针数组 {count@+28}, [4] 批操作)。

**CMusicPlayerSettings** (音乐播放器设置; vtable 0x14294EAF0 10 槽; **CPersistent 但写用户设置文件不入存档** — "SaveToFile called without loading first" 串 + savefull 零命中双证): writer 0x141927670 / reader 0x141927530; +8 串列表 (705 enabled) / +32 串列表 (14065 disabled)。

**CSong** (曲目 def 项, 104B; vtable 0x14294C030 44 槽; CPersistent 但 writer = CFG 空桩 = 解析件不入档; reader 0x140B74DD0): +8 song 名串 (token 11418) / +40 CMeanTimeToHappen 内嵌 (token 446 chance 块) / +96 u32=0; def 去向 = boot 枚举 `music/*.txt`, 顶层 music(573) 块逐条 new CSong, **playlists 键 (复数) 解析回调 = sub_140B91500** (调用方 = 音乐设置解析器 sub_1401858B0, 栈构串 "playlists" 字节级实证; 体 = 装载 a1+240 CMusicPlayerSettings 子对象 + 日志 "MusicPlayerSettings Loaded with %u available track and %u selected stations." musicplayer.cpp:366, 计数取 +44 可用曲目数 / +260 已选站点数)。**曲目列表一次性构建 sub_140B90FB0** (musicplayer.cpp:30): 一次性门 = a1+356 字节; 元数据 = *(*(sub_14222BDB0(a1,a2)+856)), 未就绪警告 "Music metadata is not ready yet, this will stall interface load!"; 两段 sub_140B90310 构建 — 可用曲目 {data@+32, count@+44} + 引擎向量 **(a1+336) (count@+12); a1 类身份推定 CMusicPlayer (TU + 与 sub_140B91500 共用 +44 计数槽互证)。**语音族** (SAPI 无障碍, 全排除): PdxSpeechToTextInterface (0x142B5D220 抽象) → PdxSpeechToTextWinSAPI (0x142B5D260, 次 vtable@+32 = SAPI COM 事件基; 三函数 {Initialize 0x1423ABBA0 / Activate 0x1423AB9C0 / Deactivate 0x1423ABAD0} 定性复核维持排除 — 实例槽 +40 ISpRecognizer / +48 ISpRecoContext / +56 ISpRecoGrammar / **+64 u8 激活旗** (Activate 置 / Deactivate 清, 主 vtable+48 = IsActivated 守门; 识别器开关 = (a1+40)vtable+136, 语法开关 = (a1+56)vtable+176, 三函数同址直证; 监听者容器 §4.00.31), 零游戏数据接触); PdxTextToSpeechInterface (0x142B5D150 抽象) → PdxTextToSpeechWinSAPI (0x142B5D1B0); SpeechInput (0x142B3FDE0, 基 SpeechRecognitionListener 0x142B3FDB8) = 语音输入单例, Activate/Deactivate 即开关; **处理器容器 = {data@+16, cap i32@+24, count i32@+28, alloc 对象@+32}** (元素 = 处理器裸指针 8B; 与 §4.00.31 同骨架异偏移 — PdxStT 容器在 +8/+16/+20/+24, SpeechInput 多一层 SpeechRecognitionListener 基): AddHandler 0x1422680B0 (空参断言 / 容器满才 1.5× 扩容 f32 中转) / RemoveHandler 0x1422683C0 (未命中 "trying to remove an unknown handler!" :78 / 命中带去重紧缩); ⚠ **AddHandler 无查重** — AddListener 有 duplicate 断言, 两族同名方法语义不同。**输入实现族** (pdx 引擎层, 全排除): CPdxEvents (0x142B3E948) / CPdxEventHandler (0x1427361E0) / CPdxSystem (0x142B51678, 基 CSystem) / CPdxKeyBoard (0x142B594D8, 多基 CKeyBoard + 键按/抬 Observable) / CPdxMouse (0x142B59550, 多基 CMouse + 5 Observable) / CPdxTouchDevice (0x142B51578)。**CTrack** (0x142B57FA8, 多基 CButton + CButtonObservable@+128) = GUI 滑轨元素, 与音频曲目无关; **CRomeBitmap** (0x1429D61E8, 基 CBitmap) = 位图实现 (装载链 §4.00.37); **CPostEffectVolumeReloader** (0x1429A7228, 基 CReloadDispatcher) = 16B 回调壳挂 owner+352, 仅 posteffectvolumes 热重载。

**网格渲染族**: **CPdxMeshObject** (渲染实例; vtable 0x142B409F0 22 槽; 基 CPdx3DObjectHelper\<CPdxMeshType\> ← CPdx3DObject): +88 CPdxMeshType* / +112 渲染句柄 / +140..+160 包围盒 f32×6 / +184/+192 列表 / +200 分配器 (= off_143085170); ctor 0x142275B60 经 0x142309CC0 向 type 注册, dtor 0x14230E280 解注册。**CPdxMeshType** (网格类型 = 资产 lexer; vtable 0x142B4D7A0 15 槽; 基 CPdx3DTypeHelper\<CPdxMeshType,CPdxMeshObject\> ← CPdx3DType ← CPersistentWithToken; **writer = CFG 空桩 = 入资产库不入存档**; 槽语义: [4] reader / [9] .mesh 装载 0x14230A510 / [13] 对象工厂 — 三槽模式全族一致, 装载全机制 §4.35.16a): reader 0x14230D680 键 file(26)→+184 串 (读入 `\`→`/` 归一; "dlc/" 前缀 assert) / animation(64)→+216 SAnimationLookup vec (+8 FNV 去重, 重复 terminate) / meshsettings(677)→+96 SMeshData vec (216B; 六 std::string @+8/+40/+72/+104/+136/+168 步进 32 + 登记 id 对 @+200 u64 init −1 / +208 u32; 串语义待裁, 全布局 §4.35.16g) / variant(793)→+120 串集 / preload_textures(673)→+370 u8; 嵌套 **SAnimationLookup** (56B; vtable 0x142B4D750; reader 0x14230DAE0 键 id(11)→+8 FNV 键 / type(225)→+24 串 + +16 动画资源, 查无 terminate); 基 reader 0x1422D7A60 键 name(27)→+16 / scale(93)→+48 f32 / cull_distance(368)→+52 f32 **读入即平方**; ctor 0x142308F20 置 +160..+180 包围盒 FLT_MAX/-FLT_MAX 哨兵对。

**3D/2d 双系总图** (渲染对象整族 writer 空桩 = 不写存档): 3D 双系 = **CPdx3DObject** (vtable 0x142B40960, 实例基元, 非 CPersistent) ↔ **CPdx3DType** (0x142B41580, CPersistentWithToken, reader = 全族公共 0x1422D7A60 三键表见上), 业务类经 CPdx3D*Helper 模板桥接 (RTTI `?$CPdx3DObjectHelper`); 2d 双系 = **CGraphicalObject** (0x142B44120 基元) → C2dObject (0x142B3D060) → C2dVisibleObject → 实例链, Type 侧 C2dObjectType ← CObjectType ← CPersistentWithToken (其解析件并入 §4.30.31 精灵/GUI 模板族)。占位对 CPdxDummy3DObject (0x142B57DC8) / CPdxDummy3DType (0x142B57E58, reader 直通基 0x1422D7A60)。

**CArrowType** (地图箭头 def; vtable 0x142B51AC8; reader 0x142356D10; 实例 CArrowObject 0x142B47C08: +112 绘制批次对象 / +128 数据 / +136 计数 / +144 分配器): 13 键 = height(31)→+144 f32 / size(47)→+64 f32 / endAt(88)→+68 f32 / color(86)→+80 CColor / colortwo(268)→+112 / specular(74)→+224 串 / effect(89)→+304 / normal(119)→+192 / texture(415)→+160 / overlay(489)→+256 / heading(184)→+152 f32 / type(225)→+148 i32; 未命中键回落 CPdx3DType reader。**CAnimatedMapTextType** (浮动地图文字 def; vtable 0x142B519D0; reader 0x1423563F0): position(76)→+224 / speed(110)→+64 / maxWidth(145)→+236 / textblock(261)→+80 内嵌 CTextBlock (成功校验 sub_1424C0050; 失败 :29 flags=0 日志 + 追 '\n'); 未命中键回落未知块处理器 sub_1422D7A60。**CTextBlock** (排版块 def; vtable 0x14294AC88; reader 0x1422D5C70, **无 default 回落**): font(30)→+48 串 / size(47)→+120/+124 i32 对 / position(76)→+112/+116 = **增量修正** (+120 += +112−新x 后 +112=新x, y 同理 = 滚动定位) / color(86)→+16 CColor / format(114)→+128 取首字符 's'=0/'t'=1/'u'=2 / text(143)→+80 串。

**CPdxPostEffectVolumeManager** (后效 def 宿主, 0x178 (376B); vtable 0x1429A71B8, 多基 CPersistent + CLostDeviceInterface@+8; writer 空桩; reader 0x141288FE0; 宿主 = gamerendering.cpp 宿主对象 +184, ctor sub_1412849D0): +72..+100 f32 全局默认后效参数 / +128 哈希表 (装填因子 1.0) / **+280 矢量 = posteffect_values** (160B 元 SPostEffectValuesReader) / **+304 矢量 = posteffect_volume** (200B 元; 缺 posteffect_values_day 时报错不入) / **+328 = posteffect_height_volume reader 数组** {data@+328, count@+340} (112B 元 SPostEffectHeightVolumeReader) / +352 "posteffectvolumes" 名登记槽; **+192 = height vol 结果向量** {data@192, count@204} 40B 元 / **+216 = box vol 结果向量** {data@216, count@228} 40B 元 (装载后构建器 0x141288170 物化; 全案 §4.35.36)。元素 CPdxPostEffectVolume (0x1429A7140 抽象) / CPdxPostEffectVolumeBox (0x1429A7168) / CPdxPostEffectHeightVolume (0x1429A7190) 连 CPersistent 都不是 = 纯运行时几何体。**CGraphicalMap** (地图渲染根, 0x750 (1872B); vtable 0x14294ACF8, 多基 + CLostDeviceInterface@+8; reader 0x140B56AE0; 宿主 = gameapplication.cpp 宿主对象 +880, ctor sub_140B4F9C0): reader 仅自有键 type(225) → new 168B 层对象入 +312 矢量 {cap@+320, count@+324, alloc@+328}; +88 = 大渲染子对象 (malloc 0x5D30); **+96 = CWrapWorldShadowMap\* (672B, ctor sub_1422D9670, shadowblur FX 双实例; §4.35.61)**。**CTerrainGraphics** (地形图形 def; vtable 0x1429C0EF0, 多基 CPersistentWithToken + THasNullObject; reader 0x14143F220): color(86)→+64 / type(225)→+88 经 TGameItemDatabase (qword_14332F0A8) 按名取图元句柄 (句柄[16]=0 时续读块) / texture(415)→+100 f32 / perm_snow(11857)→+104 u8 / spawn_city(12109)→+105 u8。

**重载器族** (8B 瘦对象 CReloadDispatcher 系 = 文件变更→[2] Reload; 注册 = sub_1422564C0(&扩展名), 文件监视器按扩展名分发): 扩展名↔类↔挂载点 = particle→CParticleReloader (0x142B3D6F8, gfx 管理器 +206256; [1] 路径谓词 0x14223C810 经纹理管理器 qword_143453090 桶遍历, [2] 0x14223C9E0 条目 +8==385 (token = pdxparticle) 者调 sub_142297540); **CPdxParticleType def 侧布局 (本批新收)**: +64 = 解析出的粒子特效对象指针 qword, +184 = type 名串 (MSVC string, cap@+208); 解析链 = sub_1423FDAE0() 特效库单例 getter → sub_1423FD4F0(db, 名) → 写 +64; type 键读入 = sub_1422973E0 (token 225 = type, 失败 :69 "Could not find particle effect [...] near line ... in file ..."); 装载后校验 = sub_142297540 (成功 → sub_142296A40(a1,1), 失败 :55 "Particle type [...] is broken. Particle effect is NULL") / mesh→CMeshReloader (+206272) / anim→**CAnimationReloader** (0x142B3D770, +206280; ⚠ 主 vtable 尾部 [6..9] 带 CPersistent 槽 = Save wrapper/writer 空桩/Load wrapper/reader 0x14223B400, 指纹按 slot1 判定故 serfam 未命中) / guianim→**CGuiAnimationReloader** (0x142B3D898 主 CReloadDispatcher + 0x142B3D8C0 次 CPersistent mdisp=8, +206288 含宿主回指 +16; reader 0x14223B0D0 经 SGfxFileReader 解析 spriteTypes(53) 门定义入 3 个 RH 集, 其余块 skip; [2] 0x14223C3C0 重解析) / defines→**CDefinesReloader** (0x14271BA70, 第一宿主 +936; [2] 0x1401A4A20 → sub_14074A9E0(1) defines 全量热重载) / countrycolors→**CCountryColorsReloader** (0x14271BA98, +944; [2] 0x1401A4900 → sub_1401CCB50(gamestate) + sub_140A66D80 刷国家颜色) / assets→**CAssetsReloader** (0x142B3C3A0, 启动器对象 +784; [2] 0x14222E6A0 → sub_14222DDC0(qword_143452450, 0/1) 双遍重载)。texture→CTextureReloader (+206264) 见 §4.30.31 注。

**defines_game.h 装载器簇 (19055 行, 模式定性 + top 8 抽样; 定案)**: 540 函全部 = **纯单键 define 装载器** (C++ 模板实例化, lua → CDefines 槽单向载入一次; 零 getter/零写入器/零业务函数 — 「CDefines 槽 getter 族」系误称, 独立复核与 df97 裁定一致); 行数 ∝ 钳位复杂度 (无钳 60-90 行 → 向量长钳 198 行); 抽样 8/8 键与 ref/defines_map_1193.txt 相符, 6 键界值首次定值 (BOOST_IDEOLOGY_MAX_DRIFT_BY_OPERATIVE 仅下界 −10.0 / COMPLIANCE_FACTOR_ON_STATE_CONTROLLER_CHANGE [−10,+10] / CONTRACT_ESTIMATE_AVERAGE_CONVOY_COUNT_ALPHA 仅下界 0 / MIN_LAND_EQUIPMENT_CONVERSION 系 [0,+10] / BASE_NAVAL_EQUIPMENT_CONVERSION 系 [0,+10] / SURRENDER_LIMIT_MULT 系 [0,+10]); **非字面界构造器通道** = fx1e-5 取负 sub_1424EF6F0 / fx32k 零 sub_1424ED3F0; **引擎侧零消费 define 2 键** (BOOST_IDEOLOGY_MAX_DRIFT_BY_OPERATIVE 与 MIN_LAND_EQUIPMENT_CONVERSION 系, 全语料除装载器外零引用); 消费点 2 则 (COMPLIANCE_FACTOR… → sub_140F9B6E0 交接时 compliance×(define+1e5)/1e5 / BASE_NAVAL… → sub_140BD41D0 成本累计); **LUA_REGISTRYINDEX 常量硬证** = 4294957296 (= −10000 的 u32 视图, 引擎 Lua 取 LUAI_MAXSTACK = 9000 档, vendor lua.h 逐行核对); 装载期警告格式 = 冒号双空格 + 共享 "
" 字面量 unk_142732CE0; 分配器伴生全局 qword_1433386D0 + LUA_NOREF(−2) 清理门; GAME_SPEED_SECONDS「截断零填」精化 = 逻辑截断 + resize helper 补齐。

**defines_ai.h 装载器簇 (18935 行, 946 函; 模式定性+top6 抽样; 定案)**: 946/946 = 纯单键 define 装载器 (NAI 单命名空间, 键/槽零重复, 骨架与 defines_game 逐段同构); 钳位密度 18.9% (min-only 145 / 双侧 34 / max-only 0, 约为 defines_game 六成), 簇内零向量钳; 槽区 0x143330E2C..0x1433385F0 (~29.6KB .data 尾部窗口, 与他命名空间成员交错共享 — NSupply 103 槽 / NMilitary dword_143331A90 等同窗混居; 奇地址段 = bool/i32 未对齐 packed 区); 对表 943/944 (缺口键 BUILDING_TARGETS_BUILDING_PRIORITIES = qword_1433384A0 已补入 ref map, 消费 = sub_141303B60 建筑名解析器)。**读者族九种定型**: fx1e-5 sub_142072500 (562) / **i32 sub_142070630** (293, type==3 → lua_tointeger, 错误 pdx_lua.cpp:526/527) / **f32 sub_142070980** (48, :558/559) / **bool sub_142072840** (19, type==1) / vec<f32> sub_142070C60 (13) / fx32k sub_142072200 (5) / 数值·索引向量 sub_142070C50 (4, 推定) / vec<string> sub_1420711A0 (1, 24B 向量头 + 32B MSVC 串 push, lua_next 迭代) / 数值向量 sub_142071190 (1, 推定)。**打印器四分族 = 打印器跟随字面量表达类型, 非 define 编码** (fx1e-5 值打印 sub_1424ED3A0 / fx32k 界打印 sub_1424ED350 取址形 / i32 sub_14015AB70 / 混合形 = fx 侧 0 界走 i32 打印器 — 先行 defines_game 批记法按此细分)。抽样 8 函界值首定/复验 (AIFC_ACTIVATE 双侧 [0,+1.0] / AIR_DESIGN_CUTOFF fx32k [0%,100%] / CALL_ALLY [0.01,+1.0] 非零下界立即数直写 / MAX_AIR_REGIONS i32 [1,100000] 等), 与钳位族表零冲突。⚠ 读者调用第三实参有 2 例传值形态 (无 & 前缀) — 批量提取须兼容; 槽 IDA 名前缀 (qword_/dword_/flt_) 不承载语义, 值型以读者为准。

#### 4.00.26 pdx_array_parser.h 数组块 Load 模板契约 (9 实例族; §4.00.17 协议的数组消费端全形)

**两个同骨架模板站点**: pdx_array_parser.h:32 ('{' 门) = CPdxArray\<T\> 动态数组版 (本节九实例族), 与 **std_array_parser.h:48 = std::array\<T,N\> 定长数组版** (实例 0x14069D900, 218 行, std::array\<u32,52\>); 两版八步骨架逐步同构 (§4.00.17 协议), 三点差异: ① 尾门断言行 48 (非 32); ② **定长上限 N 元素 + 溢出丢弃 + 警告** "Overflow: exceeded max number of elements, dropping the rest" (动态版走 CPdxArray 扩容无上限); ③ **目标 = 定长数组 a3[i], 标量经 `_InterlockedExchange((volatile i32*)(a3+4×i), v)` 写入, 非 CPdxArray 追加**。

CPdxArray\<T\> 版八步骨架 (定案): ①入口 '{' 门 (reader+192 值 token id ≠ 3 → "Unexpected token" 错误节点, 入口错配**不做跳块**) → ②lexer 前瞻槽惰性 ensure (lexer = reader+40; +100 旗未置 → lexer vtable[1], 宿主+40 惰性求值协议族第 14 消费点; 前瞻槽 = 72B token 槽再偏移 24: id@+24/旗@+28/串@+32) → ③前瞻 id ∈ {4 '}', 19 坏} 收圈 → ④前进 + 取当前 token (72B: id@0/旗@4/串@8/len@20) → ⑤'@' 注解代换 (sub_1424C04A0, 结果回写 token 槽) → ⑥值 token 拷回 reader 值槽 {id@192, 旗@196, 串@200} → ⑦CPdxArray 追加 (max(count+1, cap×1.5); allocator 对齐实参随元素: 4B 元 = 4 余 8; 迁移三形态 = POD memcpy / move-ctor+旧删构 / push 助手; 新元素按 T 形初始化) → ⑧尾门 = 错误计数 reader+24 == 0 返 1, 否则 ParseAssert 报 `... in file: "...pdx_array_parser.h" near line: 32` 返 0。

九实例身份表 (5 已载对读相符 + 4 零覆盖补全):

| VA | 行数 | 元素形态 | 元素解析 | 分派键 → 宿主偏移 | 书内状态 |
|---|---|---|---|---|---|
| 0x1403A9490 | 253 | 40B {MSVC 串 32B, int32@32} | sub_140612C40 | 键 12278 → +88 / → +16 / → +8 | 零覆盖 |
| 0x1411D5AB0 | 238 | 216B 多态容器元素 (带 vtable) | sub_1424C0AA0 (元素 vtable[3]) | 键 19309 → +120 | 零覆盖 |
| 0x141402370 | 233 | 56B {CID 8B, 毒化 u8@16 = 0xAA} | sub_1413FD050 | 键 19472 → +224 | 零覆盖 |
| 0x1411A5320 | 230 | 8B 对象 (带 ctor) | sub_141427F20 | 键 12279 → +112 | 零覆盖 |
| 0x141207010 | 224 | 8B CID (哨兵逐元写) | sub_14221F970 | (s4_11 operatives +192) | 已载 |
| 0x141206C60 | 223 | 16B {指针, i64 定点} 对 | sub_140E94CA0 | (s4_11 states +144) | 已载 |
| 0x140D40F90 | 216 | 4B u32 (tag) | sub_140BB5560 | (s4_10 guarantees +880) | 已载 |
| 0x1403A9110 | 210 | 8B 标量槽 (i64) | sub_1424C08D0 | (s4_11 core_states +168) | 已载 |
| 0x14122D280 | 186 | 104B 结构 | sub_141215120 | (s4_21 temp_nodes +432) | 已载 |

> 互证: 哨兵 CID qword_14333D528 容器元素初始化又一消费点; 毒化字节 0xAA 家族于数组元素再现 (推定未初始化哨兵同族); allocator 对齐随元素第三组两证成三证。

**defines_military.h 装载器簇 (18523 行, 994 函; 模式定性+10 函抽样; 定案, 纯确认批零勘误)**: 994/994 = 纯单键 define 装载器 (与先行全量定性批及 §4.26.5b 增补条逐项互证一致); **行数谱按钳位方向定量** = 无钳 74-86 (825 函) / 仅下界 97-118 (123) / 双侧 127-191 (44) / 仅上界 2 例; 钳位闭区间语义 + 先下后上判定序 + 同警告双打印器混用。**全簇消费普查 (先行批未做)**: 951/994 define 有引擎消费者, 共 1670 (槽, 消费函) 对; **43 键引擎侧零消费** (NAir 13 / NMilitary 12 / NNavy 18, 成族分布 — AIR_COMBAT_FINAL_DAMAGE 三兄弟 / DETECT_EFFICIENCY 三兄弟 / PARACHUTE_FAILED 三兄弟 / TRAINING_ACCIDENT 四兄弟等, 全清单见 archive findings); 消费点抽查 3 槽 (railwaygun 移速 / navy 情报半界 / damage_split 聚焦钳) 全部书内已载, 零新消费点; 异类函之谜 = 提取器正则伪影 (槽参无 & 衰减形态, 与 defines_ai 批传值 2 例同族)。

**defines_supply.h 装载器簇 (103 函; 全簇普查; 定案)**: 103/103 = 纯单键装载器 (**NSupply 单命名空间独占** — 全语料 "NSupply" 字面量恰 103 处 = 本簇装载器; 断言路径 301 计账闭合 = 103×2 错误分支 + 81 + 7×2 钳位警告); 读者仅两型 = fx1e-5 ×91 + i32 ×12 (无 f32/bool/向量, 供给域浮点全 fx1e-5); **钳位密度 85.4% (88/103) = 全 defines 头最密族** (仅下界 81: 0×75 / 1×3 / 1000 / 5000 / 10000 各 1 + 双侧 7 / max-only 0) — 供给量带符号, 防御性 min-0 全钳成族; 行数谱与 military 逐档同构 (无钳 74-86 / 仅下界 97-118 / 双侧 127-166), 行数膨胀源 = 每钳位警告分支 ostream+EH 垫约 19-25 行; 对表 103/103 零缺口; 槽区 0x143330E50..0x1433383A0 全 4 对齐, 与 NAI/NMilitary 交错共享 CDefines 窗; **消费面全量普查 95/103 键有消费者** (219 对/110 函), 零消费 8 键成族 (NODE_BASE_SUPPLY_ADD 四兄弟 / FLOATING_HARBOR_DECAY_MAX_NAVAL_BONUS+PENALTY 双子 / NUMBER_OF_SHOWN_SUPPLY_SOURCES_IN_SUPPLY_MAPMODE / SUPPLY_NODE_MIN_SUPPLY_THRESHOLD; 同族 AIR 对有消费 = 浮港衰减只接空袭侧); 浮港衰减公式定案 0x141230750 (失控制 NO_CONTROL_PENALTY +100000 起点 → MAX_AIR_PENALTY 与 MAX_AIR_BONUS 按空袭比定点插值 → FLOATING_HARBOR_MIN_DECAY 下限; NAVAL 插值对无分支 = 键存而逻辑未实装); TRAIN_ANTI_AIR 三兄弟 (HIT_CHANCE / ATTACK_TO_AMOUNT / HIT_ROLL_COUNT [1,100]) 全部只进 0x140F75A00 airmission.cpp:4494 空袭物流打击主结算; TRAIN_ARMOR_TARGETING_WEIGHT 唯一消费 = 0x14122B820 country_supply.cpp:660 (火车满足率唯一写者, 键名绑定补齐); ALERT_LOW / ALERT_VERY_LOW_SUPPLY_LEVEL 双门限唯一消费 = 0x141639980 供给警报警示链; MAX_RAILWAY_LEVEL = NSupply (装载器 0x1409AAA80 唯一直证, 全簇最热点 32 消费函)。⚠ KEY 实参 `(__int64)` 强转形态 11 例 + 槽参传值无 & 形态为批量提取两大漏配伪影, 提取正则须同时兼容。

**defines 四小簇 (project 33 / mapmode 596 / industrial_organisation 17 / faction_defines 83 函; 全量机器提取 729/729 单读者; 定案)**: NProject 单 ns (钳位 79% = min 16 + 双侧 10 全 [0,+1.0]; 向量尾块 3 槽 0x1433399F8..A28; vanilla 拼写错误键 SUPPORTIVE_SCIENITST_PROGRESS_BONUS 原样照录); **defines_mapmode 双 ns = NMapIcons ×493 (优先级族) + NMapMode ×103 (透明度/颜色/索引)** — NMapIcons 才是多数派 (82.7%); 特型读者最密集簇 (f32×4 ×44 / CColor ×7 / vec3f ×4 / vec2f ×2 / vec<f32> ×2), **钳位 16/596 = 2.7% 全 defines 最低** (优先级/索引/颜色天然非负); faction_defines 三 ns = NFactions ×75 + NGraphics ×6 (FACTION_PING_MAP_ 配色组) + NMapMode ×2 (FACTION_THEATER_COLOR_INDEX / FACTION_THEATER_HIGHLIGHT_COLOR_INDEX), 全 defines 簇唯一断言路径带子目录 (diplomacy\factions\), 串槽 2 个 .data 离群 0x14308FEE8/F10 (串/日期类槽离群主区形态); NIndustrialOrganisation 单 ns 17 函 (钳位 71% 全 min-0; **fx32k 消费实样 `(槽×v)>>15` 与装载 ×32768 精确互逆** + MIO tooltip 本地化注入 sub_1406C74F0 — define 槽直喂本地化通道实例)。四簇全 max-only = 0 (书载「max-only 全库仅 NMilitary 两键」增证 729 函零违例); INTEL_MAP_MODE_MAP_ICON_OFFSET = NMapIcons / FACTION_PING_MAP_AVAILABLE_COLOR = NGraphics (§4.26.5b 漏收名条 NS 已按三重直证更正); 颜色键五编码并存 (df275 graphics 簇增第五编码 = 逐通道标量拆分 BORDER_COLOR_*_{R,G,B,A} 36 键) 详 §4.26 读者家族表注。

**defines_graphics.h 装载器簇 (552 函; 同族收官批, 全量机器提取; 定案)**: 552/552 纯单键装载器, 源行 :8..:651 全互异零宏族; **四 ns 簇 = 全 defines 已定簇最大 ns 数** (NGraphics 426 [地图渲染/边框/箭头/光照/天气/后处理] + NInterface 86 [纯 UI 度量 — tooltip 偏移/双击时限/缩放/效率因子族] + NAirGfx 39 [空军视觉/动画 — 动画曲线/编队视觉拆分/空战场景上限] + NMapIcons 1 [TOP_MAP_ICON]); **NAirGfx/NInterface 为家族新见命名空间** (「头文件 ≠ 命名空间」再增两实例); **f32 标量读者首次成簇内多数派** (280/552 = 50.7%, 视觉浮点参数主体; 先行簇多数派 ai=fx1e-5 / mapmode=i32); 钳位密度 6.3% = 已定簇次低 (max-only 全库仅 NMilitary 两键再增 552 函零违例); 界值谱含 i32 min 10000 (MAX_NUMBER_OF_TEXTURES) 与 f32 [0.01, 60.0] 位型双侧; 缺口键 11 (9 CColor + 2 vec3f, 离线扫描漏收, findings 持 VA/读者/NS 三项完备数据); 槽区主 0x143330E69..0x143339080 + 主区外仅 2 串槽离群 (0x14308B020/B048 RAILWAY_BRIDGE_ 双子, 串槽离群通形第三证) + CColor 五连排段 (52 个相邻 gap 恰 32); 槽尾与 NIntel 向量尾块紧邻不重叠 (.data 尾块纪律跨簇互证); 消费抽查 6/6 全中 (含 vec\<float4\> xmm 16B/元素消费直证)。**defines 装载器同族战役至此全部闭合** (14 簇 4,375 函: ai/game/military/supply/intel/diplomacy/project/raid_defines/mapmode/industrial_organisation/faction/doctrines/graphics + defines.cpp 骨架)。

**字体族** (全 .gfx/.gui 解析件 writer 空桩, 不入存档): **CFont** (vtable 0x142B57ED0, 基 CPersistentWithToken; reader 0x14237E6B0): name(27)→+16 / cursor_offset(659)→+48 / selection_offset(720)→+56 ← **CBitmapFont** (0x142B41888, 附 +64 CLostDeviceInterface 虚基; reader 0x14229EC60; ctor 0x1422980C0): +72 宿主回指 / +88 color / +96 border_color / +208 fontfiles 串向量 {cap@+216, count@+220, alloc@+224} / +272 textcolors 定长阵列 / +12560 icons_add_height u8 / +12564 icon_scale f32=1.0 / +12568 起 40 个 32B 图元槽; reader 键 path(372) 追加 / fontfiles(718) 重置整表载入 (两者混用告警) / color(86) / border_color(461) / textcolors(714) / icons_add_height(595) / icon_scale(604); fontName(34)/colorcodes(297)/color_override(370) = deprecated 告警跳过 ← **CGameBitmapFont** (0x1429E6BE8, sizeof 0x3640; 脚本 `bitmapfont`(295) 块经 def 工厂钩子 0x140B410E0 malloc+ctor 0x141640D30 产出, 同钩子 a3==271 分支产 0x2C0 伴随对象); **CBitmap** (0x142B49820 无基) = **两级 BMP 装载链** (bitmap.cpp, 与字体无序列化关系): ctor 0x1422E4500 (width/height/位深白名单 {8,16,24,32}, 越界 :21 throw; 布局 +8 宽 / +12 高 / +16 字节每像素 / +20 位深 / +24 色数 (8→256 / 16→65536 / 24→16777216 / 32→0) / +28 行字节 (width·bpp 未 4 对齐) / +40 像素缓冲 / +48 就绪旗) → 高层装载 0x1422E46E0 (读 14B "BM" 头 + 40B INFOHEADER, 位深白名单 {1,8,16,24}; "BM" 不符 = 静默回卷返 0 不抛, 越界位深 :102 throw; 尾调 this vtable[3] = 底层装载 0x1422E4990, 高置信) → 底层 0x1422E4990 (重读头, 压缩仅收 RGB(0)/RLE8(1), **RLE8 全解码** = 编码运行/delta/绝对运行+奇对齐填充; +32 = 精确 BMP 行宽 (width·bpp+3)&~3 与 +28 行距分立); 高层 sizeimage 兜底口径 (width+3)&~3 不乘 bpp = 引擎 quirk, 仅本地变量无消费实害。

**资产工厂族**: **CAssetFactoryAudio** (vtable 0x142B503F8, ctor 0x1423492E0, dtor 变体 0x142349050 / 0x142349870; 基 CPersistent): [1] Save wrapper 0x1424BEC50 / **[2] writer = CFG 空桩** / [3] Load wrapper 0x1424BE690 / [4] **reader 0x14234A010**; 对象 +8 资产名串 (推定) / +24 CAudio* 音频管理器句柄 / +32 soundeffect(276) 向量<SSoundEffectReader 152B> / +56 category(702) 向量<SCategoryReader 88B>; 六键分派表 + 装载后链接三段见 §4.35.16g。**CAssetFactory** (.asset 工厂基类; vtable 0x142B50890, 基 CPersistent; writer 空桩; reader 0x14234DB90): reader 开头三旗门 = `+24 != (a3==438)` 按键型二分 (实体键时 +24 须 1 / 非实体键时须 0) / `+25` 局部装载旗置位时只收 light(84)/entity(438)/particle(407) 三键 / +26 particle 待处理旗; 四键分派 animation(64)→SAnimationData / light(84)→SAnimatedLightReader / particle(407)→SParticleSystemReader / entity(438)→SEntityReader, 全链见 §4.35.16g。**CAssetFactoryParticle** (0x142B501A8): [3] = **自定义 Load wrapper 0x142331870** (全量 SParticleSystemReader 解析), [4] = 基 reader — 与 CBrowserType (0x142B53C58, [3] 自定义 Load 0x1422DE0B0, reader 0x14236DFF0) 同属「wrapper 自定类」serfam 盲区实例 (另见 §4.00.1)。**CBrowser** (0x142B46F70, 基 CGuiObject + CTextInputReceiver@+128) = 内嵌 CEF 网页窗, 排除; CBrowserContext/CBrowserInstance 抽象基实现见本表 Steam 族。**开发/调试设施族 (负定案, 整族排除出存档域)**: **CNudgerStrategy** (vtable 0x142A42FF0, 7 槽 5 纯虚, 无基非 CPersistent) = nudge 编辑器资产微调策略抽象基; 派生 CStateNudger (0x142A44BF0) / CStrategicRegionNudger (0x142A45220) / CSupplyNudger (0x142A45568); 应用函 = sub_141B6F650 (nudger+11808 = _CurrentlyEdited, :424 断言; 先清计数整表重建, 遍历选择列表 {d@+16/count@+28} 逐元 RTDynamicCast<CProvince> 取 prov+164 省 id, 追加入编辑对象 int 向量 {d@+8/cap@+16/count@+20/alloc@+24}, MT 1.5× 增长) / CUnitsNudger (0x142A45A18) / CDatabaseNudger / CWeatherNudger / CBuildingsNudger / CAmbientObjectNudger (0x142A43130) 同构 `CNudgerStrategy@0 + CReloadableInterface/CReloadDispatcher@40` 多基 (12 槽), 激活 = 编辑器 GUI `interface/nudge.gui`, 仅写 mod 文本文件零存档面; **CDBNudger** (vtable 0x142A44290 + 次 0x142A442D0, ctor 兼 dtor 0x141B504F0 / 0x141B51B40, sizeof ≥16448 — ctor 最大写偏移 16440, 上界提示; 槽 [1] 0x141B51F00 / [2] 0x141B52180 / [3] 0x141B52FF0) = 库级 nudge 器巨型对象 (~16KB)。**CCameraControlStrategy** (vtable 0x142AFDA60, 11 槽 4 纯虚, 独立抽象基与 Nudger 无继承) → CFirstPersonStrategy (0x142AFDA90) / CTurnTableStrategy (0x142AFE5F8), 部署于 assetviewer/previewer 调试查看器。**HOI4EditorInterface** (vtable 0x142727500, 基 CEditorInterface) = 启动参数 `-editor`/`--editor` 进入编辑器主循环 (sub_14209E610) 的界面根类。**sub_14209E610 = 进程主入口体** (WinMain 实现; 双角色定案: 常态分支建 CMapApplication 走游戏路, `-editor` 分支进 PdxEditor 编辑器路 — pdx_editor/startup.cpp 断言串 + mount previewer_assets/userdir 解析/日志挂载即编辑器分支段; 旧两处记载「WinMain 体」与「编辑器主循环」系同一函数的两段)。**CMapIdler** (12736B, CIdler 轻量支 +CLostDeviceInterface@8, 非 CGameIdler 支) = assetviewer/previewer 调试场景 idler (ctor 直绑 previewer_quit/record/next_asset 等 12 键); **CNudgeIdler** (3984B, CGameIdler 支 + CReloadDispatcher@1512) = nudge 编辑器场景 idler (副表邻串 interface/nudge.gui/ambient_objects/strategic_regions/buildings) — 两者与上列 Nudger/相机策略同场景。**CEvolveEquipmentImgui** (0x142A3D808, 7 纯虚) → **CEvolvePlaneImgui** (vtable 0x14299B678, ctor 0x141198770, 104B, [2] 0x141B06800 OnUpdate) / **CEvolveShipImgui** (0x14299B768, ctor 0x141198800, 112B, [2] 0x141B076E0) / **CEvolveTankImgui** (0x14299B7E0, ctor 0x141198890, 120B, [2] 0x141B08020) = "DEBUG UI" 装备演化调试器。四类**均非 CPersistent** (槽 [1..4] = `_purecall` / CFG 桩 / 0x14039DAB0 / 0x1401807B0 样板) ⇒ 纯编辑器层不可序列化。**CLogger** (vtable 0x142B91D18, 4 槽 2 纯虚抽象基) → CFileLogger (§4.00.9 文件族) / CFilterLogger (0x142B3AF58, 按类别 id 哈希路由转发, 全局表 qword_1434521A8 + OutputDebugString 旁路) / CNullLogger (0x142B91D40 空实现); **CTestLogger** (0x1429B3A68, CPersistent 壳 writer 空桩) → CEquipmentInFieldLogger / CManpowerLogger 遥测件, **CTestLoggersArray** (0x142737248) reader 0x14136E580 = 多态反序列化工厂 (tag 14054/14055); CTest/CTestBundle (0x142737148/0x142737198, writer 空桩) 与 CTestDatabase (0x142737218, 常驻装载 "tests" 目录) 同属自动化测试框架。**StackWalker** (0x142B58708) → CCustomStackWalker (0x142B5B3D8, 线程局部单例 0x1435B9F60) → CPdxCrashReportImpl (0x142B5B320 接口) → CPdxCrashReportWindows (0x142B5AA48) → CrashReporter.exe = 崩溃诊断链。**CAutotestSettings** (0x142724378, writer 空桩 reader 0x1401F8D30, 版本 tag 15531) 与 **CAnimViewerGraphics** (0x142AFD7B8, reader 0x14223B060, 版本 tag 53/55/296) 均为只读入解析件。以上整族 serfam 命中者 writer 一律 CFG 空桩 = 引擎不落盘。**调试右键菜单 (rightclickmenu.gui)** (定案): **`interface/rightclickmenu.gui` 是 -debug 模式的开发者菜单, 与玩家单位下令无关** (玩家右键下令真实入口在地图输入/选择层 sub_140DCEFD0 簇)。构建器 = **sub_1402A3730** (每次右键按名清空重建 rightClickMenu 窗内 "options" listbox): 门 = debug 旗 byte_14332EC69 (启动串 "debug"/"crash_data_log" 置位; 控制台命令可翻转) ∧ 修饰键 ∧ button==2, 三个 idler (frontend sub_140B3CA20 / ingame sub_140DD3A50 [额外门 idler+2061, 写者未定位] / nudge sub_1412D49D0) 每帧扫各自 GUI 事件队列拾取。条目 = 三类硬编码对象 × .gui 模板: CRightClickReloadItem (vtable 0x1429A9E58, 模板 right_click_entry_2, "Reload: <开窗源 .gui 文件名>") / CRightClickOpenItem (vtable 0x1429AA018, 模板 right_click_entry, "Open: <州相关串>", 门 = 地图命中省视图 → state+168 有效旗 ∧ CStateDatabase 单例 qword_14332F070 已载断言 gameidler.cpp:1382) / CRightClickCloseItem (vtable 0x1429A9C98, loc CLOSE, 仅置 +1376 关闭旗); 另 empty_right_click_entry 250x21 无按钮占位行 — 仅占位行 (count≤1) 时菜单隐藏。 **CStateNudger 导出回调 = 0x141B5A9C0** (307 行, 非虚 GUI 回调 — 不在主副两 vtable 内, 经函数指针挂接; nudger\statenudger.cpp:566): 执行序 = 取当前州 (nudger+16 → +184 → +88 州 id) → state = TGameItemDatabase 单例 qword_14332F070 元素数组[id] (取数原语 sub_140ABC450: 元素数组 @库+40 / 计数 @库+52, **越界返元素[0]** 默认对象模式; 库头 +8 = **_Paths 向量头** (读串 = _Paths[0] 别名) / +20 = **_Paths 计数** (非 0 即已载, §4.00.51)) → 装载旗/源目录门不过 → :566 `The state database has not been loaded.` (B51 消息形, 软不中止) → 相对路径 = `<库源目录>/<state+96 名串>` → **PHYSFS_getWriteDir() ≠ state+128 (州文件当前目录串) 时 VFS 读入→写出同步** (短写 throw `Failed writing file`) 并回写 state+128 → `ShellExecuteA(0, "open", <写目录>/<路径>, 0, 0, 1)` 系统默认程序打开。state 元素字段: +96 州名串 / +128 当前所在目录串。**CStrategicRegionNudger 同构回调 = 0x141B63820** (209 行, 高置信; strategicregionnudger.cpp:926 同款串 "The strategic region database has not been loaded.", 闩 byte_14338C191): 链路全同 (nudger+16 → +192 指针字段宿主 → +88 区域 id → 库单例经 sub_140163C30 取 / 装载门单例经 sub_1401DB540 — 两 getter 是否同库两入口未决) → 相对路径 = `<源目录>/<区域+96 名串>` → VFS 同步回写区域 +128 (长度 +144 / 容量 +152) → ShellExecuteA 打开; nudge 库 SStrategicRegion 元素字段与 state 元素同位 (+96 名 / +128 目录)。**CBuildingsNudger 导出回调 = 0x141B4A3F0** (292 行, 高置信; 挂接点 = GUI 构建 sub_141B41A00 注册回调 @ nudger+17056, 同窗 +18344 挂 CCheckBoxObserverGlue<CBuildingsNudger>): 链路同构, 差异仅在选中对象取数为一跳 `nudger+256 → +88` 州 id (另两族为 nudger+16 → +184/+192 → +88 两跳), 后续 sub_140ABC450 → state+96 名串 → state+128 目录串比较 → PHYSFS 同步 → ShellExecuteA 打开 `<写目录>/<州名>` 完全相同; 选中对象 (CBuildingTemplate / CBuilding 二选一) 真名待运行时 vt 校验 (其 +88 = 州 id 与 §4.13 载 CBuilding+88 = CModifier 冲突)。主 vtable 0x142A44BF0 12 槽逐槽 dump 已核 ([8] = adjustor thunk → 副表首槽; [5]/[11] = CFG 空桩; [7] 值 0x142D6B198 似邻接数据待裁)。Open/Reload 动作 = **WinExec 经 dilepad 开发者工具通道** (CLogger 名串 "dilepad"; "@FILE@"/"@LINEINFO@" 占位符命令行), 零 CCommand 投递、零引擎调用。菜单开着再右键 = memcmp 源文件名短路不重建。旁系: byte_14332F60C 门 (右键+单修饰键) 走「窗口名::元素名」调试叠字层, 不经本菜单。**Graphviz DOT 图导出族** (调试/诊断类文件导出, 零存档面; 高置信): DOT 序列化器 sub_1411BB9B0 产出 `graph G <label>; a--b c--d;` 形语法 ("graph" 串 + "--" 边符 + ";" 语句尾); 节点标签安全包装器 sub_1411B9250 (数值 → DOT 合法 ID: 查静态转义映射表 unk_14333DD30 短路, 未命中则首尾加双引号并把内嵌 `"` 转义为 `\"`; 表内容待裁); 已知落点 = 情报网图导出 sub_14029BC00 ("intel-network-of-" 文件名前缀 + std::ofstream 落盘) → sub_1411C16D0 (SRW 锁内取图数据 sub_1411BF060) → 序列化器 → 包装器 ×3 站点; 族段 = sub_1411B8xxx / B9xxx / BAxxx / BBxxx / BCxxx。

**MP 平台抽象基 ← 实现配对表** (§4.00.9 Steam 族补基座行; 基座全纯虚接口, 实现见 Steam 族/本表):

| 抽象基 | vtable | 槽/纯虚 | 实现 |
|---|---|---|---|
| CNetContext | 0x142B6E000 | 26 / 25 | CSteamNetContext |
| CMatchmakingContext | 0x142B6D620 | 46 / 45 | CSteamMatchmakingContext |
| CCloudStorageContext | 0x142B6D1E8 | 15 (全纯虚) | CSteamCloudStorageContext |
| CStoreContext | 0x142B6EFC8 | 20 / 13 (默认体断言 "Method not implemented for this store backend.", pdx_store_interface.h) | CSteamStoreContext |
| CUGCContext | 0x142B6F2E8 | 27 / 19 | CSteamUGCContext |
| CSystem | 0x142B3CE30 | 9 / 7 | CPdxSystem |
| CPdxEvents | 0x142B3E948 | 26 / 9 | **CSdlEvents** (0x142B52948; [1] 0x142361E60 主事件泵 (返 1 = 退出请求旗; 高置信, §4.00.22) / [2] 0x142362CD0 do-PollEvent 循环抽干 (加载期兜底泵) / [3] 0x142362D10 注册 watch 回调对 / [4] 0x142362CF0 PushEvent 类型 256) |

**网络服务器族**: **CServer** (抽象基, vtable 0x142B52AC8 31 槽, [5][6] 纯虚; [4] 0x142363E10 经 +72 连接对象转发发包; [29] 0x142363AF0 SendGameState) → 三实现封闭集 **CDummyServer** (0x142B52C28, 248B, 单机本地环回非空桩——单机命令走完整序列化回路) / **CNetworkServer** (0x142B53020, 296B, 联机主机) / **CProxyServer** (0x142B53598, 552B, 客户端, proxy_server.cpp); **CSteamNetContext** (连接/传输上下文, CServer+72, Steam P2P)。全族字段表与 31 槽vtable归 **§4.36.2**。**CSession** (会话信息可观察包装, vtable 0x142B3E9D8; +8/+16 观察者双链表首尾 / +24 count / +28 挂起旗 / +40 全局计数门 dword_143453198; ctor 重载对 = sub_14224E3E0/sub_14224E870 (9 参全量重载; 函数体首段逐行同构 + CSession::vftable 直证, 创建会话对象本身)。**CPlayerLobby** (大厅玩家面板, vtable 0x142A0EC58; RTTI lambda 证 KickPlayer/BanPlayer; [22] 0x14186F3A0 = server_id_button → SERVER_ID_COPY)。**CChat** (游戏内聊天控制器, vtable 0x1429ADE98, 基 CReloadableInterface ← CReloadDispatcher ← HotkeyListener; slash 命令表 `/slap /whisper /invite /newchannel /ban /kick /roll /save` 硬编码; 创建点 sub_1419A9090) → **CGameChat** (0x142A24E48, chat_window/chat_inbox_window/chat_item)。**CFriendsHandler** (平台好友表处理器, vtable 0x1429D5378 19 槽, 懒建单例存储 qword_143339C70, getter sub_140A31BB0) → **CFriendsHandlerSteam** (680B Steam 后端: ctor 内建基后原位换表; 内嵌 "CAREER_PROFILE_YOU" 自好友件 CFriendsHandlerFriendSteam + 5 个排行榜/文件共享 CCallResult)。**ChatSettingsProviderImpl** (vtable 0x142969468; 6 薄 getter 全委托 CSettings 单例 (0x1401FA5E0) +904/+912 域 (§4.28.11))。**HotkeyManager** (vtable 0x142B3EE88, 基 CPdxEventHandler; **264B**; 单例 qword_1434531A8 懒建点 ctor sub_142254A50 (§4.28.21 已锚); 全字段表 + 监听者表 + 输入三态时钟机见 §4.00.20)。

**CApplication 应用族** (只载不存 + 单实例锁): **CApplication** (vtable 0x142B3C288 + 次表@+8; 基 CPersistent + CApplicationObservable 多基) — 主表 [1] **无 Save wrapper (CFG 空桩)**、[2] writer 空桩、[3] Load wrapper + [4] reader 0x14222E600 (只读 name(27)→+72 窗类名) = **应用单例只载不存** (serfam 指纹需 [1]+[3] 故未命中); ctor 0x14222B420 内 `FindWindowExA(0,0,+72,0)` 单实例互斥 ("An instance of this game is already running on this computer! Exiting."), **实例指针落 qword_143452450 (主单例定案**: ctor 写入, 18 引用全在 CApplication 编译单元 0x14222B5F0..0x14222EDD0)。**CApplicationObservable** (应用事件广播壳, vtable 0x142B3C260 主表 4 槽; CApplication/CGameApplication/CMapApplication 公共多基 mdisp 8)。**CMapApplication** (0x142AE6950, 主进程应用; ctor sub_1420A13C0 由 WinMain 体 sub_14209E610 内建) / **CGameApplication** (**1.19.3 主表 0x1427168E0 19 槽 — 0x1427182E0 = 1.19.2 旧址, 1.19.3 同址为字符串数据, 全表与热重载家族见 §4.28.21a**; 对象 1272B = malloc(0x4F8); **ctor = sub_140147EE0** (main.cpp:2136 直调, 对象 1272B; 预建 CSession "localhost" + ~28 对热重载注册 + 加载条组 65 回调, 详 §4.28.21); sub_140151EC0 = **析构函数** (恢复双 vtable 后 j_free 释放 20+ 成员对象); sub_14015FB30 = 标量删除析构包装。**CGameGraphics** (0x14294A338, 基 CGraphics + CLostDeviceInterface 虚继承@+206320; [1] SaveW/[3] LoadW 持久化图形设置到用户设置**非存档**; CGraphics 布局持双 2D 树 +496/+864 等槽 — 详 §4.35.3)。

**词法 / 序列化 I/O / 异常 / 日志 / 系统杂件族** (全非 CPersistent 零 gameplay 耦合; 批量登记免再查):

| 类 | 定性 | 一句话 |
|---|---|---|
| CLexer | 简卡 | **pdx parser lexer 本体** ≥104B: {+8 源对象 (其 +8 = 当前行号 u32, 取行号原语 sub_1424BDB80), +16 GetToken 返值缓存, +24 当前 token 槽 (72B 同 CReader 槽形; 取失败 id 置 19), +32 文件名指针 (+44 有效旗), +96 配置, +100 已缓存旗, +101 模式旗}; 文件版经 CVirtualFile 开读 + 1MB 缓冲; 懒构 token 表 sub_1424BD740 = boot 表已载 e4c3a 同件 (token_name 消费的引擎 token 空间读取端); **token 表读端细节 (token id → 名串入口 sub_1424BC260, lexer.cpp:381): 表基 qword_1435E1AE0, 条目 32B, 计数 dword_1435E1AB4, 懒构旗 byte_1435E1AB0; 越界返哨兵 `&qword_1430C71F8` + latch 断言 "Getting Lexer string of token that is not in the lookup table - This is very serious" (byte_1435E1AFE)**; 取槽地址原语 sub_1401AD740 |
| CBinLexer / CTextLexer | 负定案 | CLexer 零覆写换表派生 (二进制/文本 lex 变体; CTextLexer ctor sub_1424BB330) |
| CWriter | 简卡 | pdx 序列化 writer 抽象基 ≥32B: 持写出口接口@+16 (+25 持有旗) |
| CReader | 全字段表 | pdx parser reader 核心 ≥336B, 详 **§4.00.17** (错误节点链表 + 三 token 槽 + '@' 注解表 + 标量 reader 族) |
| CException | 简卡 | 异常基类 ≥80B: {+8 dword 错误码, +16/+48 双 SSO 串}; 构造被派生内联 |
| CFileException | 简卡 | 引擎主文件异常 (throw 站点 179 处遍布 VFS/解析/加载域); 与基类共址 = **构造链内联非 ICF** (拷贝 ctor 先写基表后覆写派生表) |
| CChoiceException | 负定案 | 同构派生仅换表; 全 dump 3 处, 几乎未用 |
| CLogStream | 简卡 | std::ostream 派生日志流 ≥256B (sink@+128); VFS 错误日志行发射端; **通道旗实测六值: 4096 (格式化错误级) / 65536 = 0x10000 (装载完成日志族) / 65539 (ExecuteHistory 专用) / 65540 (一般行式) / 65544 = 0x10008 (测试框架日志类别, tests.cpp:32 与 CTest 族条目互证) / 769 = 0x301 (热加入/大厅状态日志族, 位义待裁)** — 65539 与 65540 差 bit0, 位义未裁 |
| CFormat | 简卡 | **GUI 文本格式件** (非文件格式): CObservable←CTextBuffer←CFormat 链 ≥288B; +80 SSO + 格式参数族 (+136=1/+144=256/+148=64/+248=1000000) |
| CExcelParse | 负定案 | 表格解析遗留件; 全 dump 仅自身 dtor 对, 无构造点 = 死代码 |
| CVirtualFile | 简卡 | VFS 文件句柄封装 ≥56B: {后端句柄@+8, 路径 SSO@+16, mode@+48}; 双重载 ctor |
| CVirtualLogFile | 简卡 | CVirtualFile 派生 (mode=1 写换表), 日志文件封装 |
| SVirtualFile_PHYSFS / SVirtualFile_STD | 简卡 | VFS 双后端: PHYSFS {24B 句柄 {vtable, 写旗, PHYSFS_File*} 或 32B 错误串, ok 字节@+32, 锚 virtualfilesystem_physfs.cpp:1247} / CRT FILE* {FILE*@+16, dtor fclose + "Failed to close file" 断言} |
| CTextureHandler | 简卡 | 渲染纹位管理器: 纹理数组@+8 (步距 72B, 计数@+20) 逐一释放 |
| CCollisionObject | 简卡 | 16B 壳 {vtable, 目标@+8}; 按 +328 旗从源数组筛碰撞目标 (碰撞查询基础设施) |
| CThreadProfileObject | 简卡 | 每线程画像注册件 ≥48B: {+8 线程名 SSO, +40 tid}; 主线程特判 dword_1435E3BF4 (profiling 域 §4.9 配套) |
| CTbbThreadObserver | 负定案 | 16B 栈对象 {vtable, +8 观察旗}; bootstrap 内挂 TBB 调度器观察 (§4.28.21 装配链同函数) |
| CDebugLineHelper | 负定案 | dev 调试线渲染 helper ≥48B: {+8 属主渲染器, +16 模式 id, +40 32KB 缓冲 (debuglinehelper.cpp:72)}; 零 gameplay |
| CSysInfo | 负定案 | pdx 引擎纯虚接口空壳 (12 槽 = dtor + 11×_purecall); 全引擎唯一实现 = CNullSysInfo (8B 全桩); 零 gameplay (telemetry/diag 候选排除) |
| CPdxParticleType / C2dCircularProgressBarType / C2dPieChartType | 负定案 | 渲染 def 三件: writer CFG 空桩 + 存档零命中; 实例侧已载 (CPdxParticleObject §4.31.94 / C2dCircularProgressBar §4.30 / C2dPieChartTemplate §4.30), def 侧无独立布局账 |

**音频后端带 (0x1423B1AD0-0x1423E0000, ~430 函数; 负定案: 零 gameplay 操作面, 批量登记防误判)**: Vorbis 解码 + **SDL 设备回调 = 软件混音内核 0x1423BA890 (§4.31.134) + 限幅器 sub_1423C0E70 + 排序族 sub_1423B94A0/B9580** (原统称「Vorbis+OpenAL 输出」的 OpenAL 表述与 SDL_AudioSpec/设备句柄证据冲突, 待裁; 输出侧 sub_1423C0B90→sub_1423BF5D0 喂 STEREO16@44100, 格式码 0x8010)。⚠ 排雷: sub_1423D74A0 形似「整数 DDA 地形剖面」、sub_1423D6C80 形似「Dijkstra 寻路」, 实为 **Vorbis floor 曲线容差判定核** (Bresenham 走格 + dB 域 [-140,0] 量化 10bit, 系数 1024/140) 与 **floor 曲线→折线段贪心合并拟合器** (SIMD Σx²/Σh² 采样统计 → 线拟合 → 0x8000 插值旗)。结构 = 三张无 RTTI 类型分派表 (.rdata 0x142B64700/708/710, 全镜像唯一数据引用; floor 两型 / residue 三型各持 7-8 槽函数族) + 帧装配总核 sub_1423D9930 (0..14 逐级表 × 通道 × mag/ang 耦合); 包魔数 "vorbis" 六字节, setup 头结构序 codebook ("BCV" sync)→floor→residue→mapping(类型必须 0)→mode→framing 与规范逐项吻合; 区带两端与 Steam 浏览器/回调 + Steam Cloud (PE 名直证) 交错。⚠ dword_1430C76A8 = **CPUID SIMD 特性级** (cpuid 派发位非图形设置; 带外大量 `>=2/>=5` 读点易误判为配置项)。河流面假设已证伪 (CPdxMap 省河流点/rivers.bmp 装载器与本区带零互调)。

**音频族持有关系** (补 §4.31.94 SAudioContext/SSDLAudioContext 简卡): SAudioContext 双 RH 表 (均 32B 内嵌形, 桶 48B {dist u8@+4, 名串 32B@+8, 值@+40}, FNV-1a 32 位, 哨兵 = data + 48×(mask+extra+1)) = **+2088 音效资产表 (定案**: 值 = CAudioSoundSDL* — PCM 逐出器 0x1423C1420 值对象直读 +240/+360/+252 与 SSoundReader 插入器 sub_1423BE9F0 同表双证; 原记「类目表 (推定挂 CAudioCategory)」系误判, 类目资产实走工厂 +56 向量) / **+2184 音乐名表 (直证: CAudioMusic 工厂 sub_1423B5C40 `v37 = a1+2184` 按名 FNV-1a 探测, 重名断言 pdx_audio.cpp:1294; 原记 +2160 系 2192−32 倒推误)**。SSDLAudioContext: +2372 音频使能旗 (工厂入口守卫) / +8..+72 八音乐实例槽 / +72..+2120 256 音效实例槽 (+2056 峰值) / +2384 SRWLOCK + +2400 设备句柄 (插入锁内) / **+2536 qword 上下文** (音乐实例工厂拷入实例 +32)。SAudioContext 另 **+2200 = u16 音乐 id 计数器** (资产工厂 ctor 拷入资产 +8)。资产 = CAudioMusic 240B 注册项, 分段布局 (名字 C 串@+16 ≤64B / 路径串@+80 / 音量 f32@+208 / 解码数据句柄@+216 / 时长 i64 ns@+224 / 格式 i32@+232 / 信息 i32@+236; 全表与注册链 §4.00.30) / CAudioSoundSDL ≥368B (+16 名串 / +80 源文件路径串 / +208 音量 1.0 / +220 装载有效性门 / +224 SDL_AudioCVT 内嵌 ~64B (S16 立体声目标) / +240 PCM 数据缓冲 / +248 原 PCM 字节数 / +252 缓存记账量 / +256 分配倍率 / +360 引用计数 (装载置 1 / 播放 ++ / 声部回收 −−) / +364 LRU 时戳 = dword_1435DA0C8; 原记 ≥248B 系 +240 截止误); 实例 = CAudioMusicInstanceSDL 440B {+8 源资产, +20 i32 状态 (**可听集 = {1,3,4}**, 2 = 静默不混音不推进音量, 0 = 终结; 4 推定淡出), +24 声道, +32 qword 上下文 (← SSDLAudioContext+2536), +64..+76 音量/淡入 f32 族, +80 u16 id (← 资产+8), +82 代际 (资产+10++ 回绕 255→1), +83 槽位, +88 解码对象 (848B, §4.00.30), +104 i32 双义 (ctor −1 哨兵 = **音量前值缓存**, 混音器读写), +112..+272 / +272..+432 双 160B 子对象, +432 i32 双缓冲切换索引 (自增 ≥2 回绕 0), +436 u8 就绪旗} / CAudioSoundInstanceSDL 128B {+8 源资产, +64..+76 音量族, +88 全局 tick 镜像 dword_1435DA0C8, +92 f32=1.0×3}; 两 SDL 工厂同形制 (同签名/守卫/SRW 插入), 实例音量 = 实参 × 源资产 +208 f32。

**SDL 像素转换带 (0x14210 段邻位, 负定案: 零 gameplay 操作面, 批量登记防误判)**: 内嵌 SDL2 库件 — **0x14210A5B0 = SDL_ConvertPixels_ARGB8888_to_YUV 一族** (7 种 YUV 目标: 打包 4:2:2 YUY2/UYVY/YVYU + 平面 4:2:0 YV12/IYUV/NV12/NV21, 含色度 2x2 下采样; 调用链 SDL_ConvertPixels 0x142103A50 → RGB→YUV 分发 0x14210F570 → 本函, 三层全闭合 SDL 段无引擎直调); **0x14210A330 = GetYUVPlanes** (错误串自带真名; 出参恒 a7=U(Cb)/a8=V(Cr): YV12=[Y][V][U] / IYUV=[Y][U][V] / NV12 U 前 / NV21 V 前交错全直证); **dword_1430BA500 = SDL YUV conversion mode** {0=JPEG / 1=BT.601 / 2=BT.709 / 3=auto (h>576 阈值直证)}, setter/getter = 0x1421101F0/1E0/1C0; 系数表 unk_1430BA510 = 3 行×10 floats (行首低字节 = Y 偏置推定 0/16); 源格式 = ARGB8888 定案 (中转格式码 0x16362004 经 SDL_PIXELFORMAT 名串直证), 分量序 BYTE0=B/1=G/2=R 高置信 (待数据段数值终证)。IDA 失真: SSE 向量化标量展开 (>>10/>>18 = 4 像素均值, 勿当魔法常数)。同段 0x1421093C0 SDLTimer (§4.00 线程表) 邻位互证。未通读余量: YUV→RGB 双核心 0x142110200/0x1421108C0 与 fourcc→fourcc 0x14210FDB0。

#### 4.00.10 CColor (颜色值对象; writer 0X14224CA10)

CColor = 全引擎通用 4×f32 颜色值对象 (阵营色 / 战区色 / 图例 / 命令载荷 / GUI 预设色块等 30+ 处), 非任何域专有。
**内嵌尺寸随宿主变化 (三档实测)**: 完整对象 **32B** (vtable@0 + 纯垫 8B@8 + rgba f32×4@16..31, 见 §4.24, ctor 0X14224BEB0); 常见内嵌投影 **16B** (裸 rgba, 无 vtable, 阵营/战区色槽); GUI 行件投影 **24B** ({vtable, 16B RGB}, 如 §4.31.20 CColorPickerPresetEntry+1312)。**判宿主取尺寸, 勿按单一值推广** (ctor 0X14224BEB0)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | vtable | vtable | |
| +8..+15 | — | 纯垫 8B | ctor 只写 vtable@0 + 四 float@16..31; writer 只读 a1[4..7] |
| +16 | float | r | |
| +20 | float | g | |
| +24 | float | b | |
| +28 | float | a | **≠1.0 (f32 精确比较) 才追加第 4 值** |

注: 写出 = `(int)(float)(v*255.0)` **截断 (向零)**。⚠ 凡本 writer (CColor) 输出一律截断,
无 round-half 变体 — 三处曾按 `floor(v*255+0.5)` 舍入 (theatre 色之外的
faction color / volunteers group_color / fleet color), 锚件实测定案:
f32 分量小数部分 >0.5 时两者必分歧, 截断 15/15 命中而舍入全错。
注: 写门 = !readonly ⇒ 文本存档恒写。
注: 读侧 rf32 → `math.floor(v*255)` (v≥0 时 = 截断, 与 C 双精度乘法逐位一致)。

#### 4.00.11 CGameDate / CGregorianDate (日期值对象; 推进槽 + 双哨兵)

CGameDate = 全引擎日期值对象 (内嵌 24B 三段形 `{vtable1@+0, hours i64@+8, vtable2@+16}`;
CGameDate ⊂ CGregorianDate, dtor 将 vtable 复位 CGregorianDate 基 vtable)。gs 当前时刻 =
gs+1120 (hours@1128), 载入快照 gs+152, start_date gs+1184 (§4.1.2)。

| 槽 (字节偏移) | 语义 | 证据 |
|---|---|---|
| vtable槽[1] (字节+8) | **Advance(n)** — 推进 n 小时; gs hourly tick 每小时以 `(gs+1120, 1)` 调用 (§4.2.4 步骤 4) | 0x1401DD370 体内vtable调用 |
| 构造哨兵 | hours = 43808760 = "1.1.1.1" (ctor); 43817520 = "2.1.1.1" (默认构造, dword_14306EB38, 带门字段跳过); 43791240 = "-1.1.1.1" 为合法值勿滤; dword_143086B08 = **CGameDate::EndOfTime** (== 比较判空日期, timedactivity.cpp:156 断言文本直证命名; 数值待 PE 复核) | §4.1.2 既有定案 |
| 纪元换算 | 总小时 43800000 = 纪元偏移; `(hours − 43800000)/24` = 总天数 (周边界 %7 判据, §4.2.5) | hourly tick 体内算式 |

注: 分量读取 (年/月/日/月索引) 走 gs+1144 日期分量缓存 (hourly tick 每小时重算,
dword_143085210 = 闰年月首累计日表), 非逐次从 hours 解析。

#### 4.00.12 拦截层 (框架对引擎函数的两种改写形态)

桥 DLL 对引擎的介入只有两种形态, 二者的**分界是「改数据还是改代码」**, 决定了各自的
能力边界与可逆性。选择拦截手段时先查本表: 虚方法一律走 A, 只有非虚目标才用 B。

| 形态 | 改写对象 | 可拦目标 | 覆盖范围 | 可逆 |
|---|---|---|---|---|
| **A vtable槽交换** | `vtable[slot]` 单个数据 qword | 经该槽调用的虚方法 | 只覆盖走该槽的调用方 | 可逆 (写回原 qword, 原子) |
| **B 函数体重定向** | 函数前 N 字节 (N ≥ 12, 整指令边界) | 任意有 `.pdata` 边界的函数 | 覆盖全部调用方 (直接 + 间接) | **不可逆** (无卸载) |

**A 的粒度陷阱**: 槽钩子是**逐类**的。基类vtable那些槽为 `_purecall`, 钩基表一个都拦不到
且不报错。要拦全族须钩**共享分派器** (effect/trigger 路由器即此类), 不要逐个钩派生类vtable。

**B 的四道前置条件** (缺一即拒, 全部 fail-closed):

| # | 条件 | 判据 |
|---|---|---|
| 1 | 目标是函数**起点** | `.pdata` RUN 表 (138286 项, `BeginAddress` 升序) 二分查得 `begin == rva` |
| 2 | 窃取窗口**不越出函数末尾** | `rva + N <= EndAddress`, 否则会吃进下一个函数的序言 |
| 3 | 序言可窃 | 逐条整指令解码 (LDE), 拒绝**相对控制流**与 **RIP 相对操作数** (后者需重定位, 未实现) |
| 4 | 目标**不在本进程已补丁窗口内** | 框架自身 3 个目标 (见下) 与既有 B 类目标都登记窗口 |

⚠ 条件 3 **拦不住**框架自己的补丁字节 (`48 B8 <imm64> FF E0` 是可解码的 `movabs`+`jmp rax`),
故条件 4 必须独立存在, 不能省。

**B 的蹦床跳回编码**: `FF 25 00 00 00 00` + 8 字节绝对地址 (无寄存器、无 ±2GB 范围限制)。
禁用 `movabs rax,imm64; jmp rax` —— 被窃指令已执行, 其寄存器输出在恢复点是活的, 踩 rax
即 `CInGameIdler` slot4 (0xDD3A50) 那次首帧崩溃的根因 (序言 `mov rax,rsp` → 函数体
`lea rbp,[rax-68h]` + movaps)。禁用 `E9 rel32` —— 蹦床是 `VirtualAlloc` 出的, 可能距映像
远超 ±2GB, 位移会静默截断。

**B 的安装期并发**: 改写 12 字节**不可能原子** (区别于 A 的对齐 qword 写)。安装须
「悬停全部线程 → 逐线程验证 RIP 不在 `[target, target+N)` → 提交 → 恢复」; 悬停窗口内
零分配零用户锁 (全部分配与 `OpenThread` 前移), 否则与持堆锁/loader lock 的线程互锁。

**B 的装载窗口**: 仅在**进程首次脚本加载期**允许安装 (此时引擎尚未进入渲染循环)。
热重载与会话切换也会重跑脚本, 但那时游戏满载多线程, 不是改代码字节的窗口。

**B 的回调生命周期**: 目标、回调、mode 在首载期绑定后**冻结**, 热重载不重绑 (重绑实测
不生效, 会留下「脚本以为新代码在跑、实际跑旧闭包」的静默错值)。

**框架自身已占用的补丁窗口** (B 类, 永久):

| 目标 | RVA | 用途 |
|---|---|---|
| `FindCommandByName` | 0x24B54C0 | 控制台命令名查找 (伪命令 `lua` 注入点) |
| `EffectRouter` | 0x540EE0 | effect 名 → 工厂实例派发 |
| `TriggerRouter` | 0x550030 | trigger 名 → 工厂实例派发 |
| `CInGameIdler` vtable slot4 | 0xDD3A50 (槽在 vtable+32) | 帧心跳 (A 类: 槽交换, 非补丁) |

#### 4.00.4a CEventScope 消费路径

**CEventScope (176B) 三叉链 (定案)**: +24/+32/+40 = root/from/prev 指针
(自指即停); **+48/+56/+64 = 外层节点 owned 深拷贝** (析构 sub_140535820 经
vtable[0] deleting dtor 释放三节点 (旧「引用计数对象槽」为误读, 废))。入队
sub_1401CAFF0 深克隆现场 scope (拷贝构造 + 链深克隆 sub_140536360);
pending_events 元素 56B = {fire_id@+0, CEvent*@+8, scope*@+16, tag@+24,
CGameDate@+32/+48} (⚠ gs+1376 块键 = **13793**; 13801 系 show_major)。
消费 = **CSelectEventOptionCommand (240B) +56 内嵌第三份深克隆**; Execute
(vtable[10] = sub_14153A110) 用它渲染事件/选项名 + 发通知 + 推进 scope RNG, 末尾
sub_14117FA30(ev, cmd+56, idx) 跑 option CEffect[13], 再 sub_1401EBBE0 出队
释放。玩家路径全链: idler vtable+240 sub_140DC5B10 → 216B 收件箱元素
(interface+1192) → 泵 sub_140B6B050 → CEventWindow ctor sub_1412381A0 (scope
平拷@+120); 点击 sub_141239AA0 / 超时 sub_14123C410 / AI 掷骰三入口同归命令。
**CEventScope reader = vtable[4] sub_140538F20 全键表** (country/state/random/
root/from/prev/saved_event_target 等 17 键, token 名全对上); save_event_target
写在最外层 FROM 节点 +160 块 (find-by-name 命中覆盖)。delayed_events
(cc+4752) = 第二通道: 到期消费 sub_1406FC980 把持久 scope 重入发射链。读档
重建 = loader case 13793 逐元素 Load 后复用 sub_1401CAFF0 显式 pending_id
再入队 (定案)。

**interface 收件箱通道全貌** (ingameinterfacehandler.h 定案): 容器 = handler+1192 {data, cap@1200, count@1204, alloc@1208}, **216B 条目** {载荷 u32@+0, CEventScope 拷贝@+24 (kind4), u8@+200 (kind4), **分发 kind u8@+208**}, **尾插 ×1.5 扩容 (线性排空向量, 非环形队列)**; 推送骨架 = h:197 ThreadIsMainThread 断言 (每实例化一个注册旗字节, 全语料仅此一锚 ×38 处) → 尾插 → `byte_14332F6AA` (= settings **render_thread** 旗) 为 0 才立即泵。**泵三件**: sub_140B6B050 (cpp:1031, CanUpdateGui 断言仅 render_thread 旗下查 \*(\*(handler+384)+1458)) → 分发器 sub_140B60870 (switch kind) → 排空 sub_140B6B8C0 (kind4 析构 scope 拷贝; 尾 count = 0 data 复用)。**kind 0-6 分发表**: 0 = 泛用刷新 (handler+392 对象 vtable 槽[9]) / 1 = 视图码标脏 (handler+8N+200 处理器表, 23 = "Why would you do this?!" 断言哨; sub_141236950 标脏) / 2 = 位掩码区刷新 (**执行体 = sub_140B6E480 (dispatcher case 2 直达; kind 2 行函数锚 = 本函)**; 1→+592 / 2→+624 / 4→+472 / 8→+648 / **16·32·64→+600/+608/+616 三装备设计器** / 128→+728; 三段链 = 请求端 sub_140B699F0 懒构建+置位 +1012 → 本函就绪标脏 → 帧消费 sub_140B65570/65000 清位+推数, **+1012 多位同挂落 default 全清不刷 quirk**) / 3 = 视图切换 (**inbox 路径 sub_140B69C90(a1[3], *a2, 0) 固定 a3=0 = 清返回栈; 压栈仅发生在直接调用方 a3≠0**; 当前码 +1008, 旧码栈 {+168, cap+176, c+180}; 码 23 不压) / 4 = **CEventWindow 弹窗** (malloc 0x1290 → ctor sub_1412381A0, scope 拷贝@+24 — 上链的完整展开) / 5 = tag 匹配关窗 (关 18/19) / 6 = **监听广播** (handler+1216 表逐元 vtable 槽[1])。7 个实例化旗字节 = 58C(kind1) / 1E1(kind2) / 8D4(kind5) / DC24(kind3) / 3F5(kind0) / CF8C(kind4) / 8A46A(kind6)。36 个推送消费端全定性 (13 个 RTTI 实名: CSetPortraitEffect[13] (12,1) / CSetStateNameEffect[13] / CAddRaidHistoryEntryEffect[13] 双推送 / CNavyCancelRefit·CPromoteUnitLeader·CBecomeSpyMaster·CSetDivisionTemplateSymbol·CCreateTrade [10] / 四特工转移动作共享 [56] (4,1) / CLeaveFactionConfirmationWindow[17] (12,3) / CProgramOngoingProjectView[11] = kind6 监听注册端; 余 23 个 = DeleteUnit (2,2) / 租借取消 (14,1) / conveyor 收尾 (14,1) / 建筑改级伴随件 / 游戏速度写者 / 教程族等, 全部对上书内既有锚)。handler+384 = GUI 根句柄 (+1458 = CanUpdateGui 字节 / +1272 = 窗口管理器)。

**收件箱通道增补 (36 函闭环定案)**: 36 函 = **泛用推送原语 6 件 + 业务侧内联展开 30 件**; 原语本体 VA 全定 = kind0 sub_1401B1DE0 (无参刷新, 旗 byte_14332F3F5) / kind1 sub_140224C30 (载荷变量) / kind2 sub_140142A60 (定载荷 2 → +624 区; 调用者 = 0x1419A 国际市场域) / kind3 sub_1411420E0 (载荷变量) / kind4 sub_140DBDC60 (216B 条目包装, 旗 byte_14333CF8C) / kind5 sub_1402E3960 (载荷=tag); 旗字节全 VA = kind0 14332F3F5 / kind1 14332F58C / kind2 14332F1E1 / kind3 14333DC24 / kind4 14333CF8C / kind5 14332F8D4 / kind6 byte_143338A46 (推定)。**新定 VA**: CAddRaidHistoryEntryEffect[13]::Execute = 0x1404A41E0 (**双推送 (14,1)+(4,2)**; ctor 0x1404A4050 匿名命名空间 vftable 直证) / CSetStateNameEffect[13]::Execute = 0x1403111C0 (效果参数串经 sub_142245E60 token→名写 state+56, 异则失效对 sub_140E139B0/C0) / **handler+1212 = clamp(0..4) 五档值镜像** (写者 0x1401EDE50 + kind0 刷新; 调用者 settings 域 0x140F069B0/6EF0/07110 — 「游戏速度写者」候选升高置信, 档语义待裁)。**五命令 VA 对上 s4_33**: CCreateTrade 0x141BA54B0 (15,1) / CPromoteUnitLeader 0x1413670D0 ((5,5); **Execute 尾推 (5,5) 关确认窗**, 与 kind5 关 18/19 及 LEADER_PROMOTE_POPUP 链吻合) / CSetDivisionTemplateSymbol 0x141B9F780 (1,2) / CNavyCancelRefit 0x1413527B0 (2,1) / CBecomeSpyMaster 0x141A27370 ((0,0); DLC50 门 sub_1401AEB50(50) + 扣费 dword_143335C90(PP)/1433357C8(情报))。**kind4 拷贝语义 (定案)**: 216B 源条目逐字段拷 (+0 u32/+8 u64/+16 u32/scope@+24 经 sub_140534CA0/+200 u8/+208 kind=4); **×1.5 扩容迁移时 kind4 条目先 sub_140535820(scope+24) 析构再搬运**。事件真发射体 sub_140A0F6F0 增补: 发射后推 (3,1) 视图 3 标脏, 有递归自调 (事件链串联)。新收/待裁伴随件: 外交动作命令执行驱动器 0x141104690 (深度门 a2<12 递归自调, "Infinity loop in diplomatic action command execution"; iface+2576/+2584 SRW 域) / 州天气区重算伴随件 0x1414E78E0 ((0,1); 调用链 0x1410DBD30 → 0x140704260 thunk → 天气区 384B 槽更新) / 当前显示国变更通知器 0x140460730 ((14,1)+(4,2) 双推; 读 gs+1312/+1316 与 *(handler+472) 比对; 4 调用者 = 命令 Execute 族) / 特工视图切换 0x141824F40 (20,3) / 外交动作对清理 0x141443350 (5,1) / 四 (5,1) tag 门件 0x140498860/0x140FE4980/0x140A94440/0x140ABB020; 待裁容器主身份五件 = 0x140CBC200 (a1+1880 摘除+(14,1)) / 0x140D141C0 (a1+72 倒序清扫+(14,1)) / 0x140C03E00 (a1+424 摘除+(4,2)) / 0x140A94440 宿主 / 0x140460730 调用者族 (读 +824 对象 vt[+16] 写 +32)。

**docvar（@target 文本变量）注册器** (暗区定案): 框架 = lambda 签名
`CFixedPoint(CEventScope const&, int, CScopedVariable const*)` 的求值回调注册; leader/army
族全集 = **sub_14006EF30** (6,040 行; number of units controlled by leader /
num_units_in_state 等键), state 族 = **sub_140069A80** (resource@steel /
non_damaged_building_level 等)。loc 文本 `@变量名` 的可用集以此二注册器为准。


**sub_14006EF30 形态与全局表 (定案)**: 本函 = **MSVC 动态初始化器** (语料零 C 级调用者, 尾 `return atexit(sub_1426FDD60)`), 直线构建 63 个注册块 {键名, stateless lambda 求值器, tooltip 描述} → 一次性 bulk-insert 全局 **std::unordered_map @ unk_14333C980** (64B: max_load 1.0f@+0 / list 哨兵@+8 / 桶向量@+24 / mask=7@+48 / maxidx=8@+56; 键 = std::string, 值 104B = {std::function 64B@+0, 描述串@+64, u8 旗@+96}; 哈希 = FNV-1a 32, 基 0x811C9DC5 素 16777619; map 节点 = {next@0, hash@8, key@16, value@48})。**消费端** = CUnitLeader::AddTriggerDynamicVariable (sub_140C0F3F0 系, 三副本 ±0x280) find-or-add — 触发器后备动态变量与内建 docvar **共用此表** (值旗候选: 0 = 内建 / 1 = 触发器后备, 待裁); CVariables 尾槽持表指针作名字解析 (§4.13 CVariables 表清单)。lambda 构造拓扑 = 39 件 0x140C06A70..F30 (0x20 步进 std::function ctor) + 24 体内直写 = 63, 与键数对齐。

**leader/army/operative 域 docvar 63 键全集** (高置信; 键序 = 注册序):

| 键 | 语义 | @target 参数 |
|---|---|---|
| num_units | 受 leader 控制的单位数 | — |
| num_units_in_state | leader 在某州控制的单位数 | @州 id |
| state_deployed | 将军已部署 HQ 所在州 id (未部署/海上 = 0) | — |
| province_deployed | 将军已部署 HQ 所在省 id (同上) | — |
| num_equipment | leader 军队中某装备数量 | @装备 |
| num_target_equipment | 军队所需某装备数量 | @装备 |
| num_ships_with_type | leader 控制的某型舰船数 | @舰种 |
| num_ships | leader 控制的舰船数 | — |
| num_units_with_type | 某主战型单位数 | @主战型 |
| num_cavalry | 骑兵主战型单位数 | — |
| num_infantry | 步兵主战型单位数 | — |
| num_armored | 装甲主战型单位数 | — |
| num_artillery | 炮兵主战型单位数 | — |
| num_special | 特战主战型单位数 | — |
| num_mechanized | 机械化的主战型单位数 | — |
| num_motorized | 摩托化的主战型单位数 | — |
| num_rocket | 火箭主战型单位数 | — |
| num_battalions | 营数 | — |
| num_battalions_with_type | 某子单位营数 | @子单位型 |
| has_orders_group | 有 orders group = 1 否则 0 | — |
| num_battle_plans | leader 战役计划数 | — |
| num_traits | leader 特质总数 | — |
| num_personality_traits | 性格特质数 | — |
| num_status_traits | 状态特质数 | — |
| num_assigned_traits | 已分配特质数 | — |
| num_terrain_traits | 地形特质数 | — |
| num_max_traits | 可分配特质上限 | — |
| num_basic_traits | 基础特质数 | — |
| skill_level | leader 技能等级 | — |
| army_attack_level | 军队攻击等级 | — |
| attack_level | leader 攻击等级 | — |
| army_defense_level | 军队防御等级 | — |
| defense_level | leader 防御等级 | — |
| logistics_level | 后勤等级 | — |
| planning_level | 规划等级 | — |
| maneuvering_level | 机动等级 | — |
| coordination_level | 协同等级 | — |
| average_stats | 单位 leader 平均数值 | — |
| sum_unit_terrain_modifier | 各军队位置地形修正之和 | @修正 |
| leader_modifier | leader 修正值 | @修正 |
| unit_modifier | 单位修正值 | @修正 |
| num_units_in_combat | 交战中单位数 | — |
| avg_defensive_combat_status | 防御战平均进度 | — |
| avg_offensive_combat_status | 进攻战平均进度 | — |
| avg_combat_status | 全部战斗平均进度 | — |
| num_units_defensive_combats | 防御战单位数 | — |
| num_units_offensive_combats | 进攻战单位数 | — |
| unit_ratio_ready_for_plan | 就绪计划单位比例 | — |
| avg_unit_planning_ratio | 全单位平均规划比 | — |
| avg_unit_entrenchment_ratio | 全单位平均堑壕比 | — |
| num_units_defensive_combats_on | 在某地形防御作战单位数 | @地形 |
| num_units_offensive_combats_against | 对某地形进攻作战单位数 | @地形 |
| num_units_crossing_river | 正渡河单位数 | — |
| num_units_on_climate | 处于需适应气候位置的单位数 | @气候 |
| avg_units_acclimation | 某气候平均单位适应度 | @气候 |
| own_capture_chance_factor | 特工被捕概率因子 | — |
| own_forced_into_hiding_time_factor | 「forced into hiding」时间因子 | — |
| own_harmed_time_factor | 「harmed」时间因子 | — |
| intel_yield_factor_on_capture | 被捕时被敌方抽取情报的速率 | — |
| operation_state | 特工被指派行动的州 id (未指派 = 0) | — |
| operation_country | 特工被指派行动的国家 id (未指派 = 0) | — |
| operation_type | 特工被指派行动的 token | — |
| operative_captor | 捕获该特工的国家 tag | — |
**消费端全量形态 (eventscope.h 簇 620 函数定性)**: 该簇 = **CEventScope 的消费端集合**
(620/620 函数体内嵌 eventscope.h:193 防环断言; 0x14053 区 CEventScope 方法本体**不在簇内** —
按簇名找类方法会扑空)。三块构成: ① 集合算子体系 ≈239 个 (§下) ② 临时 scope 构造/拆解
用户 272 个 (ctor→用→dtor 164 / copy 44 / 多 setter 手搭链 64) ③ 业务域消费端 ≈139 个
(on_action 派发实现 42 — §4.12.9b 的执行层名单 / console trigger·effect 命令 /
NLoc::SScopeLocalizer scope 本地化 desc (虚槽[25] 取基文案 + 按深度缩进) / 触发器内树
求值包装 53 (名单快照→逐元素设 scope→sub_14054AB30 评内树, all/any 语义) / 杂项 30
(scripted_gui_ai 求值入口 sub_1413277E0 / 装备库查询 / AI 目标评分))。事件真发射体簇内
仅 sub_140A0F6F0 一个 (其余事件族函数只构造 scope 后转投)。防环断言语义 = 「把旧 scope
设为新临时 scope 的 from 前」检查一级自反 (不递归查全链, 高置信)。

**script_collection_evaluator.h 集合算子链游走器** (双批互证定案; 与 §4.32 count_in_collection
所引 triggers 侧同体系两侧): 模板 `CCollectionEvaluator<元素类型>` = 脚本集合「算子链运行期
游走器」, **195 实例 = 13 元素类型 (country/state/faction/unit/character/combatant/**ace**/
project/operation_instance/industrial_organisation/purchase_contract/raid_instance/
strategic_region; 无 province) × 每型恰 15 族内分发/无字面量变体**。链视图 = `{begin,end}` 指向
**16B/条 {kind u32@+0, payload@+8}** 数组 (无独立 RTTI 类); 游走器统一五参 `(求值帧, &链视图,
当前元素, 访客, 游标)`, 逐元素 ctor(sub_140535110)/bind/dtor 固定成本 + :193 FROM 环守卫;
bind helper 按型分件 (13 型全直证): country sub_14053B470 / state sub_14053B4B0 /
combatant sub_14053A590 / character sub_14053B330 / unit sub_14053B6B0 / ace sub_14053A250 /
strategic_region sub_14053B670 / industrial_organisation sub_14053B030 / purchase_contract
sub_14053B1B0 / raid_instance sub_14053B270 / project sub_14053B4F0 / operation_instance
sub_14053B0F0 / faction sub_14053A690。kind 七类骨架: 0-3 = 四内建集合源 (faction_members
19584 = dip+656→成员{+88,+100} / owned_states 12321 = cc+1144 / controlled_states 12320 =
cc+1120 / country_and_all_subjects 10237 = dip+368 附属 tag); **kind 4 = 通用算子节点**
(payload 对象指针, 空返 0, 非空新 scope 上 vtable[3] 判定真才递归); **kind 5/6 = 极性对且语义逐型分叉** (state 链 = st+176 cores 隶属门
± 即「该州是/不是 <tag> 核心」过滤对; country/faction/io 链 = named/dynamic 集合源禁用
报错, 名经 sub_1403C4FE0/C50A0 以 token 13178/17404 运行时取; **离线名 = is_core_of / is_not_core_of**, kind 0-3 switch 序 = 19584 faction_members / 12321 owned_states / 12320 controlled_states / 10237 country_and_all_subjects) — **kind 值非全局统一枚举**。**296 形 VA 映射** (首匹配收集访客, 逐字节同构, 0x1404C 块内 10 实例): 0x1404C10B0 = character (bind sub_14053B330) / 0x1404C35E0 = industrial_organisation (bind sub_14053B030) / 0x1404C49F0 = raid_instance (bind sub_14053B270) / 0x1404C1760 = combatant (bind sub_14053A590) / 0x1404C2F30 = operation_instance (bind sub_14053B0F0 体内直证) / 0x1404C5690 = strategic_region (bind sub_14053B670) / 0x1404C5D40 = unit (bind sub_14053B6B0, 越端分支按同族克隆律推定) / 0x1404C3C90 = project (bind sub_14053B4F0) / 0x1404C0A00 = ace (bind sub_14053A250, 分发器 sub_1404C6A00 经 ace 帧槽 getter sub_140536740 直投) / 0x1404C4340 = purchase_contract (bind sub_14053B1B0, getter sub_140535D30); eventscope.h:193 防环断言字节级 = 总门 byte_1435E1B52 + 每站点闩 byte_14332F520, flags=1 断言级。
内建源可迭代性 = 元素类型静态决定 (country 型全四源; faction 仅 kind0; 其余 9 型全报错)。
三种失败通道: GetSize 不支持 (evaluator.h:130) / [Parallel]ForEach 不支持 (:230) / 链尾非叶
断言 `"Target and leaf node in operator doesn't match"` (:171)。⚠ **:230 错误通道被 all 计数 (293) / any 计数 (295) / [Parallel]ForEach 三家族共用** — 报错串文案不是家族判别依据, 家族身份只看叶动作契约 (all = bool 旗清零中止返 1 / any = 计数 ≤0 置 ok 旗短路 / ForEach = 计数递减 + 完成旗)。**走查三形**: A 断言形克隆
(93: 越端断言+返 0, 无叶动作 — count 族引擎/输入分发器的模板全组实例化, country 型真计数叶
sub_1404E8570 在簇外); B 叶派发单例 (52: 越端 = 访客派发, 返 1 = 全链短路信号; all 计数 293 形含 operation_instance 型 sub_1404EE4C0); C GetSize 形
(0x140A1 域: **叶 = 末链节 cursor==count−1 而非越端** — 源 kind 直读计数, 算子 `**a4 += vtable[3]
判定`, 中段源 = 导航跳型迭代后跨型递归 state walker sub_140A1A5D0)。**访客族目录 (B 形叶动作)**:
any 计数 (295 形, `--计数 ≤0 → ok=1 返 1` 短路; **VA 锚 9 实例** = 0x1404F1910 = ace / 0x1404F65C0 = strategic_region / 0x1404F4500 = industrial_organisation / 0x1404F4BB0 = project / 0x1404F5260 = purchase_contract / 0x1404F5910 = raid_instance (bind sub_14053B270) / 0x1404F2670 = combatant (bind sub_14053A590) / 0x1404F1FC0 = character (bind sub_14053B330) / 0x1404F6C70 = unit (bind sub_14053B6B0, eventscope.cpp:598 "pUnit" 断言直证) (逐字节同构, 唯一调用方 = any 引擎分发器 sub_140505340; opcode 0-3 报错臂 token = 19584 faction_members / 12321 owned_states / 12320 controlled_states / 10237 country_and_all_subjects; **kind 5/6 = 动态名报错臂** (算子名经 sub_1403C4FE0 / sub_1403C50A0 运行时取, 同 :230 通道; 与 296 形同款, §4.00.4) — 该形仅 kind 4 主臂受支持 (0x1404F2670 combatant 实例直证); **scope 装载 helper 按元素类型特化家族** (293/295/296 三家族共用): sub_140535110 默认根 / sub_14053A610 country / sub_14053B030 industrial_organisation / sub_14053B4F0 project / sub_14053A250 ace); df59 全家族分布 (后续补池单): 295 形 any 余 1 实例 = 0x1404F3E50 operation_instance ([Parallel]ForEach 形已录); 293 形 all 计数 10 实例全齐 (unit 0x1404F1270 / ace 0x1404EBFE0 / project 0x1404EF200 三员已补入主锚清单); 旁系 = 423 形 country 0x1404F2D20 / 326 形 faction 0x1404F36D0 / 263·265 形 state; **访客状态块 = {+0 子触发器对象, +8 →i32 剩余计数, +16 →bool ok 旗}**; 叶动作 = bind → sub_14054AB30 逐元素子触发器求值, 真才减计数; **[Parallel]ForEach 形** (走查三形外第四形, 错误通道 :230 同名) = 0x1404F3E50 = operation_instance 型 (bind sub_14053B0F0), 越端叶动作契约 a4 = {+0 访客对象, +8 int\* 剩余计数, +16 bool\* 完成旗} — 计数归零的完成者置完成旗返 1) / all 计数 (293 形, 同减无 ok 旗; **VA 锚 10 实例 = 0x1404EEB60 = industrial_organisation (bind sub_14053B030, getter sub_140535CA0) / 0x1404EF8A0 = purchase_contract (getter sub_140535D30) / 0x1404EFF40 = raid_instance (getter sub_140535D70) / 0x1404F0BD0 = strategic_region (ctx+72 直读) / 0x1404EC680 = character (bind sub_14053B330, getter sub_140535C20) / 0x1404ECD20 = combatant (ctx+96 直读) / 0x1404EE4C0 = operation_instance (bind sub_14053B0F0 体内直证, getter sub_140535DB0) / 0x1404F1270 = unit (getter sub_140535DD0) / 0x1404EBFE0 = ace (bind sub_14053A250, getter sub_140536740) / 0x1404EF200 = project (bind sub_14053B4F0, getter sub_140535D90)** — 分发器 sub_140504D30 实证 = 293 形家族分发器 (按 ctx 元素槽/getter 分派; **尾支 sub_140535C60 → sub_1404EDD60 元素类型未决**); 叶动作 sub_14054AB30 假 → **(BYTE**)(a4+8)=0** 中止返 1; 各锚三重证 (报错串 type 段 + 叶动作契约 + 分发器分支); 293 形 10 实例全齐, B 形游走器) / 首匹配收集
(296/291/260 形, 旗@+176 已置返 0, 否则 sub_140534CA0 追加+置旗+返 1) / 末元素比较 (0x14140 域
283/280/313/253/249 形 ×20, sub_14141C5A0 后 `(容器末元素==NULL)==期望旗@+32` —
collection_contains/条件收集消费侧)。

短路语义逐消费族不同 (定案): **all 族** (all_collection_elements 引擎 sub_1404C9E00) 叶访客
失败置 `*ok=0` 返 1 逐层上抛中止, 空集恒真; **any 族** (sub_1404CA360) `--count` ≤0 置 ok=1
短路; **count/ForEach 族** (count_in_collection 五模式 sub_14051DC20 分派) 无短路全量遍历
(叶对象数组 vtable[12] 副作用访问); **GetSize** 末链节 `**a4 += 1` 累加 (0x140A 族 = ForEach+
GetSize 双模式合一)。消费面另含 collection 输入解析 type-4/6 (sub_1403C5160/sub_140A12F10)
与两套同形世界根分发器 (sub_14140EA50 / sub_1404BA300: case1 = gs+784 国家表过滤
cc+1156>0 有拥有州 / case2 = 全部国家 / case3 = gs 州表 → sub_1404BF620 state 型 / case4 → sub_1404C63F0 十二型 getter 首非空分发 / case5 = named 集合 input_impl.h:228 禁用; sub_1404BA300 上游 = sub_1404C7100 虚表间接 (a1+96==5 → named 集合链 sub_140A1D560, 否则 a1+112 直链) — df59 消费者未决闭合)。**count/ForEach 族 walker 实例族 (sub_1404C63F0 = 381 行十三路全表, getter 返 0 即下一路)**: 头支 country 0x1404BC260 (421 行, 四源全支持) / 尾支 state 0x1404BF620 (260 行) / faction 0x1404BCC30 (328 行, 仅 kind0) 三源支持变体 + **回调派发形 291 行 ×10** (character 0x1404BB4A0 / combatant 0x1404BBB80 (bind sub_14053A590 两调用点直证, df359) / ace 0x1404BADC0 / strategic_region 0x1404BFC40 / operation_instance 0x1404BD3C0 / unit 0x1404C0320 (bind sub_14053B6B0, getter sub_140535DD0) / industrial_organisation 0x1404BDAA0 (bind sub_14053B030, getter sub_140535CA0) / purchase_contract 0x1404BE860 / raid_instance 0x1404BEF40 / project 0x1404BE180 (bind sub_14053B4F0 两调用点直证, df360); 逐字节同码克隆, 差异仅类型串/bind/自递归名; 全语料无第 11 例)。**叶契约三形辨析** (共用 :230 错误通道与七类 kind 骨架, 家族身份只看叶动作): ① 回调派发形 — 叶 = sub_140534CA0 构 176B 叶 CEventScope (+16 = 1587985054, 全引用槽 qword_14333D528 哨兵) 逐访客 vt[12] 派发, **恒返 0 无短路**, a4 = {+0 持有者 → +8 访客数组 data, +20 count}; ② 296 首匹配收集形 — 旗 @a4+176 已置返 0 否则收集置旗返 1 短路 (VA 集与 291 形完全不相交); ③ 计数形 (0x1404F3E50 [Parallel]ForEach) — sub_14054AB30 子触发器求值 + 计数递减 + 归零置完成旗返 1, a4 = {+0 子触发器, +8 int* 剩余, +16 bool* 完成旗} — 三形 a4 出参互不相通, 勿跨形互读。case 4 的 return 1 = 与 all/any 族共享模板骨架的不可达死码; unit 型 kind 5/6 named/dynamic 禁用报错直证 (原清单缺 unit)。**经典 every_owned_state / any_country 等卡不经本簇**
(§4.3 直遍历 own 容器, 独立实现)。与 CTrigger 槽关系: 不占 [22] Evaluate 槽, 是上述触发器
引擎下层共用迭代核心; 逐元素子触发器求值 = sub_14054AB30。**求值帧 = CEventScope** (类型化元素槽 +72..+152 见 §4.00.4 帧
槽表; scope 分发器 sub_140A1CDA0: 帧+8>0 → country, 否则按 +72..+152 槽序试 11 getter 经
sub_14221F310 ref 解析命中投对应类型 walker; state 分支 = gs+712 州表界检查, 越界
"Failed to find state with id: %d" input_impl.h:184); 14 个分发器骨架逐一锚定: 8 count 族变体
(sub_1405028D0/2E0/34F0/3B00/4720/220/4110 → §4.32 count 五模式) + any/all 引擎
(sub_140504D30/sub_140505340) + 4 世界根 (sub_1404C63F0/6A00/sub_14141B4B0/1BAC0) +
input type-4 (sub_1403C5160) + GetSz (sub_140A1CDA0); tbb 并行叶与串行叶共享调 state walker
sub_1404EAE90 (12 调用点)。叶层双实现: 串行与 tbb 并行
(198 行同构族 ×31: 8 层区间栈二分分裂 + continuation/child task + 取消支持)。容器锚负定案:
成员/州/国家表全部书已收, 本簇新原语 = 链视图形态 + kind 表 + 访客协议四款。同族同型同
行数多实例 = **逐字节同码克隆** (仅自递归名/断言守卫字节异, 链接器未做 ICF)。断言通道 =
sub_1424C8080 (条件断言, debug 总门 byte_1435E1B52 + 每站点 once 门) / 错误收集
sub_1424C8950 + 格式化 sub_1424C8E60 + 算子名 sub_1424BC260。

**输入侧全套 (script_collection_input_impl.h 簇 43 函数, 定案)**: 描述符 16B `{int type, ptr payload}`; **type 表**: 1 = `game=all_countries` (国家表过滤 cc+1156>0) / 2 = `all_possible_countries` / 3 = 全州 (键 token 19578 离线名与语义不符, 待裁) / 4 = `scope` → **13 源联合分发** / 5 = `collection=` (运行期 :228 禁嵌套) / 6 = `constant=`。**分派器三形态**: 62 行 ×8 / 234 行 ×4 (无计数模式) / 454 行 ×1 (ForEach+GetSize 双模式, 判别 = a3 容器空非空 — 上段「双模式合一」的机制补全); **381 行组 ×15** = 同模板逐域实例 (各带 13 个域独占叶函数), 与 15 个消费者 1:1 闭合 (非 ICF 克隆)。**type-6 常量对象**: +24 值类型字节 {3=单 tag, 4=单 state, 8=tag 数组{begin, count@+12}, 9=state 数组}; 双实现 = 157 组回调版 (:296) / 216-213 组链游走版 (:328)。`constant:` 前缀解析 = sub_140A1C4A0 (前缀剥离 + `.` 分段 token 化 + CConstantDatabase 查表与 §4.19.5 布局互证 + sub_140AA5BE0 链解析); 比例计数 sub_14051C360 = 阈值脚本值 ÷100000 (定点 1.0); 世界根分发器每域两变体 (0x1404 域 0x1404BA300 书已收 + 0x1404BA860; 0x14140 域 0x14040EA50 + 0x14140EFB0)。

#### 4.00.13 CSelectable (选择态基类; 16B 无基类多态根 — rtti bases 空, 不继承 CPersistent)

ctor 唯一 = sub_140BC2AA0(this, type); 不序列化。凡带选择态的对象 (师/舰队/翼/
战斗/省/州/战略区/环境物/特工/铁路炮) 经它或其内嵌获得选择态。

| 偏移 | 类型 | 语义 | 备注 | 置信 |
|---|---|---|---|---|
| +0 | vtable | vtable (宿主为主基时 = 宿主主表; 内嵌时 = 次表视口) | 纯类表 0x142950FB0 | 定案 |
| +8 | uint32 | **可选类型枚举 id** (非实例 id; 消费端按它分派/过滤) | ctor `*(uint32*)(a1+8) = a2` | 定案 |
| +12 | uint8 | _bSelected 选中字节 (ctor 0; Select 置 1; DeselectNotify 清 0; dtor 断言 = false, selectable.cpp:51) | — | 定案 |

vtable 6 槽 (纯类 0x142950FB0): [0] dtor sub_140BC2B60 / [1] 纯虚 (名称填入 out, 各
宿主布局不一) / [2] 纯虚 OnSelected(mgr 容器, Select 尾回调 vtable[+16]) / [3] 纯虚
OnDeselected(选择集已空旗, vtable[+24]) / [4] 纯虚通知广播 (选择集全体 vtable[+32]) /
[5] IsSelectable 基类默认恒真 (sub_1401807B0; 地理/战斗类普遍继承)。

**类型枚举全表** (17 个 ctor 调用点穷举): 0 = CArmy (CUnit 经主表) / 1 = CTaskForce /
2 = CAirWing / 3 = CCombat (子类共享) / 4 = CProvince (内嵌 @+8) / 5 = CState (@+8) /
6 = CStrategicRegion (@+8) / 9 = CAmbientObject (@+8) / 11 = CFleet (@+24) /
12 = COperativeLeader (@+3928) / 13 = CRailwayGun (主表); 7/8/10 无宿主 (负定案)。
多选规则: 空集或同 type id 方可加选; 陆军(0)/铁路炮(13) 额外要求 *(obj+672) =
CTheatre* 相等 (同战区方可混选)。选择管理器 = 双全局 qword_14332F698/F6A0 (同对象),
容器 @+1336, _Selection 双向链表 head@+48/tail@+56/count@+64, 节点 32B。

**方法地址** (selectable.cpp, 定案): Add = sub_140BC32D0 (:71 IsSelected 假 + :72 链查重双断言, 闩 byte_14333C897/C898; 尾插 + vtable[+16] OnSelected + 监听者广播) / Remove = sub_140BC2D80 (:82 断言, 闩 byte_14333C899; **a3 = 是否走 DeselectNotify**, 否则直清 obj+12; 未找到 :104, 串原文 "selecatble" 引擎错拼, 闩 byte_14333C89A) / Clear = sub_140BC2F60 (逐 head 摘除, **恒走** DeselectNotify) / CanAdd = sub_140BC2CC0 (战区键取件 sub_140BF9660) / 成员级加入门 = sub_140DDFA60 (属主相同 + 组 id 相同或双方非零经 sub_140BB52F0 判同)。

宿主内嵌偏移: CArmy/CTaskForce/CAirWing/CCombat/CRailwayGun = +0 (主表) /
CProvince·CState·CStrategicRegion·CAmbientObject = +8 (次表) / CFleet = +24 (次表
0x142962A70 — §3.9 谱系补行) / COperativeLeader = +3928 (次表 0x142956018)。


#### 4.00.14 CUnitAdjuster (三维修正器; 40B; vtable 0x142789CD0)

跨域通用修正件 — 州地形五统计组 (§4.18.19)、将领 per-skill 数组与四技能缓存 (§4.4)、
trait 条件修正表 (§4.4.23)、战术权重 (§4.22.7) 共用同一 40B 布局:

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vtable | CUnitAdjuster | 0x142789CD0 |
| +8 | uint32 | 上下文 token (地形 token / 品类 token 等; factory sub_141016A40) | 定案 |
| +16 | fixed×1e-5 | attack 修正 | 定案 |
| +24 | fixed×1e-5 | defence 修正 | 定案 |
| +32 | fixed×1e-5 | movement 修正 | 定案 |

消费 = RecalcSkillBonuses sub_140C21280 (§4.4) / 战术权重四道门 (§4.22.7) / 州五统计组
(§4.18.19: night 11944 / fort 11947 / river 11946 / amphibious 11945 / snow 12036)。

#### 4.00.16 存档值对象族 (S 结构体 POD; CPersistent 四槽, 全 writer/reader 存档键直证)

跨域内嵌小件集中账 (元素 16-96B; 宿主容器/域各注; 与 §4.00.10 CColor / §4.00.11 CGameDate 同为值对象层):

| 类 (尺寸) | 布局要点 (键名 id) | 宿主/域 |
|---|---|---|
| NWarScoreDistributionHelper::SRedistribution (16B) | {+8 reason u32 (13902), +12 points u32 (12766)}; writer 0x141983170; CPdxHybridInlineBufferAllocator 内联容器 | 和会 war_score_breakdown.redistributions (§4.10.5) / 战争分数 0x140D3F8B0 |
| SCombatDataIndexPersistence (16B) | {+8 id u32 (11; ctor −1), +12 attacker u8 (10485)}; 块键 14168 | 战斗日志管理器 +200 容器 (§4.22) |
| LeaderHoursPersistence (24B 推定) | {+8 leader 16B (10423), +16 time u32 (424)}; 块键 14165 | 领导 persist 域 +32 map |
| SUnitActivityData (16B) + SArmyUnitActivityData / SAirUnitActivityData (24B) | 基 {+8 combat (10518), +12 training (12218), 双 0 不写}; 派生 +16 idpair qword 条件写; 拷贝循环直证继承 | 池化容器元素 (单位活动统计) |
| SUnitOfficerData (88B) | {+8 seed (10647), +16 name SSO (27), +48 portraits 16B (19497), +80 male u8 (12775)}; erase-返回-拷贝 88B 步距 | 单位级随机军官持久生成数据 (§4.4 域) |
| SAdvisorData (96B) | {+8 ledger 枚举 (10354), +16 traits vec (12278), +40 advisor_traits vec (15544), +64 slot_type SSO (19588)}; 内嵌实例 = CAddAdvisorRoleToCharacterCommand +56 (152B 命令载槽快照) | 顾问槽 (§4.4 角色 / §4.34.10 部长) |
| SAdvisorBonus (64B) | {+8 加成名 SSO, +40 i32 ctor −1 (resolved id 推定), +48 待裁}; **reader 按名 FNV-1a 查表**; writer 0x1413E04E0 / reader 走 unexpected-token 空块 | 顾问加成按名解析 |
| CState::STemporaryResourceData (32B) | {+8 days (10605), +16 16B 资源载荷}; push 循环 0x1409D1150 | CState+2224 容器 (§4.13 州域) |
| CFEXMember::SReceivedDamageData (32B) | {+8 ship 16B (10400), +16 tag 串 (10754), +24 damage qword (12459)}; 32B 步距 | 海军战斗日志成员 (0x14197 域, §4.22 邻) |
| CChatSyncAllCommand::SChannelInfo (72B) | {+8 id (11), +16 name (27), +48 userslist (228)}; 72B 步距 | 聊天全服同步命令载荷 (§4.33 命令域) |
| CIdCounterStore::SIdCounter (16B) | {+8 type (225), +12 id (11)}; **自定义 Save 槽 0x140BBD7A0** (开块/收块非标形态) | id 自增计数器存档 (§4.28.5 id_counter_store) |
| NProject::SProjectContext (≥48B) | 键序 province (10304) → progress (11013) → character idpair (19478, 位旗 +20) → country (10394, 旗 +28) → scientist (16389, 旗 +36); 位旗门控可选字段 | 工程/科研进度上下文 |
| NIndustrialOrganisation::SHistoryWithEquipment | date CGameDate (10314, 旗 +32) → units u32 (12202) | MIO 历史条目 (§4.8.12b 域) |
| CFrontSection::SPerCountrySection | country 串 (10394 经 0x140BB4E70) → index (524) → count (10730) | 前线每国分段 (§4.34.18 CAIFront 域) |
| CNamedEquipmentBonus (≥200B) | name SSO@+128 (27) → prefix SSO@+160 (12536, 门 qword@+176) → modifier 块@+8 → id@+192 (11) | named_equipment_bonuses 200B 元 (§4.8 容器行) |
| CCountryCharacters::SAdvisorSlotInfo (16B) | {+8 database_advisor_slot_count, +12 current_advisor_slot_count} (writer 0x1410F0610) | §4.4 角色域 |
| SRibbonForAchievement | {+8 frames u32[] (251, count@+20), +44 colors u32[] (581, count@+56)} (writer 0x1406214C0) | 成就绶带 (§4.28.8 生涯域) |
| CDecisionStatus::SDecisionRandomCountItem | {+8 决策 ptr (名取其 +288, 键 11142), +16 count (10730), +20 target (107)} (writer 0x140738F10) | 决议域 |
| CIgnoreTargetedDecisionCommand::SDecisionData | {+8 target 串 (107), +12 target_state (14965), +16 decision 串 (11142)} (writer 0x1411713D0) | 决议命令载荷 |
| SOptionalEquipmentAssets | {+8 model 串 (15755), +40 icon 块 (181)} (writer 0x141463C80) | 装备资产可选件 |

**只读解析件 10 件** (PERS 但 writer 空桩 = 只载不存, 解析域入住零存档面): **CDynamicEquipmentGroup (216B; CEquipmentGroup 派生双 COL 子对象@+104; writer CFG 空桩 = def 只读解析件; reader 0x140A0B160 三键 icon (181) →+16 串 / description (15906) →+48 串 / equipment_type (16217) →+80 块; ctor 0x141915650)** / CNationalFocusStyleDatabase (PERS 壳全惰 — reader = 错误桩 0x1424BEC40, 无实读) / SNationalFocusStyle (国策风格, §4.3.15 邻) / SCriticalPart (关键部件) / SModifierStat / SNamesPool / SInitialScientistSkillLevel (科学家初始技能) / SAce (ace 读入件, §4.3.12 已载域) / CBuildingTemplate::SCountryModifier (建筑模板内嵌) / SMeshVariant (渲染解析) / CCitySettings::{SDistanceMesh, SGroup} (零独立 vftable 写点内嵌件)。**CHighlightStates** 维持负定案 (决议 highlight 块内嵌, writer 空桩; ctor 事实 {CAndTrigger@+8, CPersistentScriptTargets@+96})。

**语音三件** (无障碍域, 运行时件): SpeechInputHandler / PdxTextToSpeechState / PdxSpeechToTextState — 锚 CPlayerLobby+9856/+9880 内嵌与 pdx 懒单例; 简卡免布局。

#### 4.00.17 pdx 解析协议 (CReader 全布局 / token 槽 / 标量 reader 族 / unordered_map 读件)

> 定性 (负定案): pdx_parser.h 簇 = **CReader 流式解析协议 + `Load(CReader&, T&)` 模板重载族, 无 DOM 节点树** — "节点"仅存在于 CReader 的三个 72B token 槽与 96B 错误节点链表。三层分工: **CLexer** (token 生产, §4.00.9 简卡) → **CReader** (协议 + 标量转换 + 错误) → **Load 模板** (逐类型块读取循环, 49 个实例化, 断言 pdx_parser.h:2222 ×44 / :1203 ×4)。

CReader 主表 (≥336B; ctor sub_1424BEC90 逐字段直证; dtor sub_1424BEF30):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | vtable | CReader 主vtable | |
| +8 | 错误节点* | 错误链表首 (最早错误) | append 时 count==0 才写 |
| +16 | 错误节点* | 错误链表尾 (最新错误) | 每次报错更新 |
| +24 | uint32 | 错误计数 | 无错误判据 = `reader+24 == 0` (sub_1424C0050); 断言 parser.cpp:891 |
| +32 | uint8 | 错误态旗 | 报错置 1 |
| +40 | CLexer* | 持有的 lexer (唯一 token 源) | |
| +48 | token 槽 72B | **键 token** | GetKeyEqualsValue 填 |
| +120 | token 槽 72B | **算子 token** | {1 "=", 467 ">", 468 "<", 792 "?="} |
| +192 | token 槽 72B | **当前/值 token** | 块入口预读判据; 标量 reader 全吃此槽 |
| +264 | CPdxArray | 数组一 {data@+264, 计数@+272, 分配器@+280} | 用途未定 |
| +288 | uint8 | 持有旗 | |
| +296 | 指针 | id 解析门对象 (字节 +8/+9 双门) | CID 读 sub_14221F970 非门即跳过赋值 |
| +304 | CPdxArray | **'@' 注解表** {data@+304, 计数 int@+316, 分配器@+320} | ≤0 = 空 |
| +328 | uint8 | 毒化字节 0xAA (**ctor 与 dtor 双写** — dtor 清 +332 时重置) | 布尔/完整性哨兵 (推定) |
| +332 | uint8 | 旗 | ctor 0 |

| 槽内偏移 (token 槽) | 类型 | 语义 |
|---|---|---|
| +0 | uint32 | token id (lexer id 空间; 3 "{" / 4 "}" / 19 坏) |
| +4 | uint8 | 旗 (已解析/替换标记; '@' 注解路径用) |
| +8..+72 | CPdxHybridInlineBuffer 串 | token 文本 (21B 内联); 内层 = {文本 ptr@+0, dword@+8 (dtor 清零), **文本长度 u32@+12**, **分配器对象 ptr@+16 (dtor 虚调 vtable[2] 回收)**} — 三处消费点直证 (dtor / 报错器 sub_1424C0200 / 对象头写入 sub_1424C27C0) |

| 偏移 (错误节点 96B) | 类型 | 语义 |
|---|---|---|
| +0 | MSVC string 32B | 错误消息 |
| +32 | uint32 | 行号 (报错时 lexer 现取) |
| +40 | MSVC string 32B | 文件名 (空则全局空串) |
| +72 | 错误节点* | prev |
| +80 | 错误节点* | next (链 append-only) |
| +88 | uint8 | 旗 |

协议机制:

| 机制 | 函数 | 语义 |
|---|---|---|
| 键-算子-值步 | sub_1424C1540 | GetKeyEqualsValue: 消费键→reader+48 → 校验算子→+120 → 预读值→+192; 值 token 为 "}" 时向 +192 写空串 id 0 |
| '@' 注解 | sub_1424C04A0 / 注册器 sub_1424C1790 | token 文本 '@' 开头 = 注解引用: 剥 '@' 后 FNV-1a 32 位查 reader+304 注解表代换, 结果回写 **lexer token 槽** (reader+192 值槽由后续记键段另拷, 两段分离) 当普通 token 消费 (脚本文件头 `@名 = 值` 局部变量代换); 第二字符 '(' = 未实现断言 (:1087, B51)。**条目 112B 跨距** {名串@+0 (键 = token 串剥首字符), FNV-1a hash u32@+32, 替换 token id@+40, 旗 u8@+44, 值串@+48}; 探测 = 线性步进 +112 比对 hash (非 robin-hood); 扩容 max(计数+1, 容量×1.5) 旧表逐元素移构; 重名 → :1049 "Variable name %s is already taken." (4096 不中断); 值串首仍为 '@' 时再解析一层 (嵌套引用) |
| i64 读 | sub_1424C08D0 | `sscanf(token, "%i")` |
| **fixed×1e-5 读** | sub_1424C0A70 | `sscanf("%lli")` 整部 + '.' 后 ≤5 位小数 (不足补 '0') 拼成 int64 — 小数→定点协议解析侧落点 |
| bool 读 | sub_1424C4E30 | `strncmp("yes", 4) == 0` |
| CID 读 | sub_14221F970 | `{ family id }` 两元素; 受 reader+296 门 |
| tag 读 | sub_140BB5560 | tag id (与 country 索引间接表 sub_140BB5490 配套) |
| 多态容器读 | sub_1424C0AA0 | `容器->vtable[3](容器, reader)` |
| 跳块 | sub_1424C2170 | GetToken 循环数 '{'/'}' 平衡至配对 '}' |
| yes\|id 联合标量 | sub_1402F0990 | "yes" → bool 域 / 整数 → id 域两支 |
| CircularBuffer 读 | sub_140E993A0 | 先读 u32 向量再逐元素按写位环形推入; 断言 "The capacity of the buffer should be set before reading it" (:1622) |
| 错误节点 append | sub_1424C1EF0 | 建节点接链表 (+8/+16/+24/+32 更新) |
| ParseAssert 日志 | sub_1424C0060 | `Error: "<源文本上下文>" in file: "<名>" near line: N` (上下文 = 当前+前行源文本 '\n' 连接) |

错误消息族 (串直证): "Expected opening brace" / "Expected start of list" / "Expected start of list for pair of element" / "Encountered a third element while reading pair" / "Encountered less than two elements while reading pair" / "Malformed token" / "Unexpected token" / "not yet implemented" / `Expected opening bracers when reading named inlined item` (**具名内联条目 reader 模板族专用**, 5 实例化共用 — CFactionRule sub_140A2DCC0 / CFactionUpgrade sub_140A2C290 已证同形, df389; "bracers" = 引擎原文讹写)。

**pdx_unordered_map_parser.h (6 实例, 断言 :43 全同)**: 骨架 = clear 目标表 → '{' 门 → 循环 pair 解析 (`{ 键 值 }` 二元子表, 键值皆裸 token 无 '='; 第三元素/不足两元素各报错) → 键哈希 → CPdxRobinHoodTable find-or-insert (32B 内嵌表头 + 24B 桶 {hash u32@+0, dist u8@+4, key u32@+8, value qword@+16}; 一实例 64B 桶串键)。键哈希三型: **tag → country 索引** (sub_140BB5490 = `*(gs+832 间接表)[tag]` — §3.2「tag id → country index 间接表」的函数级落点; gs 空则裸 tag 直返, 带 gamestate.h:1126 线程禁入断言; 与 §4.3 original-tag 恒等表同表) / **CID 雪崩** (sub_14221EF50, §3.2b 同式) / 串键内联。六实例 = sub_1411FE9B0 (f32 值) / sub_1411FE5A0 (块结构值) / sub_141005BA0 (向量值) / sub_1401E5150 (对象指针值; token 357 "none" = null — ⚠ 勿读作 "undefined", 那是 token 19479) / sub_1411FE190 (CID 键) / sub_1414DED70 (SBookmarkPlaythroughData + 计数, 64B 桶)。

#### 4.00.18 pdx 写入协议 (parser.cpp 写侧八函闭环 — 写原语 token 分派 / 动态 token 区间重发 / 存盘驱动链)

簇清册 (体内 cpp 锚 8/8; 全部新定性):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_1424BFBB0 | 185 | :666 断言 "Trying to write unsafe with nullptr" (B52, 闩 byte_1435E1B42) | 写入原语 writeToken(token, str), 文本/二进制双模 |
| sub_1424C27C0 | 54 | :146 断言 "PersistentObject != nullptr" (B52, 闩 byte_1435E1B24) | CPersistent 对象头写入 + Save wrapper 调用 |
| sub_1424C3B00 / sub_1424C3BE0 | 29+29 | :259/:270 断言 "pObject != nullptr" (B52) | 存盘入口包装 A/B (64/32 位值参, 旗 0/1, 模板双实例) |
| sub_1424C1790 | 275 | :1049 报错串 | '@' 别名注册 (§4.00.17 表) |
| sub_1424C04A0 | 204 | :1087 断言 "not yet implemented" (B51, 闩 byte_1435E1B43) | '@' 别名解析 (§4.00.17 表) |
| sub_1424C0200 | 90 | :1111 报错串 | unexpected-token 报错器 ("Error: unexpected token in file: \"%s\" near line: %d ( %s )", 4096 — 文件名带引号, 代码直证) |
| sub_1424BEF30 | 62 | 体内 `CReader::vftable'` 直证 | CReader 析构 (全清) |

**token 分派表** (二进制模式; 文本模式全走 sink 虚槽[6] 写原串; token 本体恒先写 u16, 16/17/18 例外不写):

| token | 载荷 |
|---|---|
| 12 | 4 字节整数 |
| 13 | 8 字节 (串→8B, 疑似定点) |
| 14 | 1 字节 bool: 串 "yes"/"no" (走 sink 虚槽[7]) |
| 15 | u16 长度 + 原串字节 |
| 16/17/18 | 无载荷 (结构符, 直返) |
| 20 | 4 字节值 |
| 23 | u16 长度 + 原串 (动态 token 重发载体, 见下) |
| 359 | 8 字节定点; 文本模式重格式化 "%lld.%0.5d" — **fixed×1e5 文本形的生产者侧** (书写规范 7 增证) |
| 668 / 791 | 8 字节整数 (strtoll/strtoull 型, 精确语义待裁) |

**动态 token 区间重发机制 (新定案 — mod token 存档兼容通道)**: token ∈ (dword_1435E1ABC, dword_1435E1AB4] 时不写数值 id, 改写 **token 23 + u16 长度 + 原串字节** = 二进制流内联新 token 定义, 读端据此重注册。区间由 sub_1424BD740 装载期写定 (§4.00.9 懒构 token 表同件): 静态树 off_1430C6DE0 (条目 48B, 掩码 dword_1430C6DEC) 之外落动态表 qword_1435E1AC0 (条目 72B, 计数 dword_1435E1ACC / 容量 dword_1435E1AC8, ×1.5 扩容); 区间端点 = 引擎侧 token id 极值; 区间查询带锁 (unk_1435E1AD8) 双检。

**对象头写入与存盘驱动链**: sub_1424C27C0 → 状态复位 → 类型名 → writeToken(类型 token, 名) → token 1 写名 → 尾调 a3 虚槽[1] (= CPersistent Save wrapper, §4.00.1 槽契约增证)。sub_1424C3C90 共享尾: _RTDynamicCast(ctx+16, CFile→CChecksumFile) — 校验文件直调 Save; 否则构流 + **栈上 CWriter** 再调 Save。

**sink 对象**: 保存上下文 +16 = 输出 sink (虚槽[6] 写串 / [7] 写 bool / [8] 写原始字节), +24 = 二进制旗 (0 = 文本)。

未决: token 13/668/791 精确数值语义 / sub_1424C3C90 else 分支 Save 实参 (反编译丢参) / CReader +264/+296 子对象类型。

#### 4.00.19 win32 文件监视原生层 (pdxfilewatcher_windows.cpp; 3 函闭环 — §4.00 CFileWatcher 包装层之下的裸 HANDLE 层)

簇清册 (体内 cpp 锚 3/3; 无 RTTI 类, 裸结构):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_14224CBA0 | 456 | :21 "FindFirstChangeNotification failed: %s" (0x2000) | AddWatch 批量注册 (目录枚举 → 逐目录 ReadDirectoryChangesW) |
| sub_14224D620 | 164 | :121 断言 "Double forward slashes in filepath!" (B51, 闩 byte_143453161) | CompletionRoutine (异步完成回调) |
| sub_14224D9A0 | 42 | :21 | 重挂/武装单目录监视 |

**监视条目 0x8A8 = 2216B**: +56 回调对象 (克隆自工厂, 触发 = 虚槽[2] 调用 (ctx, 路径串)) / +64 用户上下文 / +72 目录句柄 (CreateFileA, 0x4200000 = BACKUP_SEMANTICS|OVERLAPPED) / +80 watchSubtree / +81 已武装旗 / +82 停止旗 / **+88 去重纪元戳** (与全局 qword_143452450 宿主 +816 比对, 未变整批跳过) / +96 监视 id (dword_1430BDF10 单调递增) / +100 FILE_NOTIFY_INFORMATION 缓冲 2048B / **+2152 OVERLAPPED (+2176 hEvent = 条目自身指针走私 — 完成回调据此取 this)** / +2184 路径串。全局注册表 qword_143453148 族 {基址/计数/容量/分配器}; 全局使能旗 byte_1434530D4 (关时注册不发与完成回调 995 分支短路)。

**完成回调语义**: hEvent → this → 清已武装旗; 错误 995 (OPERATION_ABORTED) → 停止旗置位则终清理; 正常 → 纪元戳防重 → 遍历通知项 **只处理 Action == 3 (FILE_ACTION_MODIFIED)** → 路径拼装 ('\'→'/', 探 "//" 断言后替为 "/") → 回调 (+56 虚槽[2]) → **尾调重挂 (每次触发需重发 ReadDirectoryChangesW 闭环)**。

未决: 条目 +0..+55 未初始化区 / qword_143452450 宿主身份与纪元戳生成时机。


#### 4.00.20 HotkeyManager 输入状态机与监听者表 (hotkeymanager.cpp; 3 函闭环 — AddListener 0x142254580 / RemoveListener 0x1422557A0 / HandleInputEvent 0x142254FE0)

HotkeyManager (vtable 0x142B3EE88, 基 CPdxEventHandler, 264B; 单例 qword_1434531A8, 懒建 ctor sub_142254A50 = malloc(0x108)):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +16 | RobinHood 槽位[] (40B/元) | 监听者表 data (ctor 预置静态空表 &unk_1430BDF20) | ctor + Add/Remove |
| +28 | uint32 | 桶 mask (ctor 0 = 单桶初始) | Add/Remove (`mask & hash`) |
| +32 | uint8 | 额外槽计数 (探针溢出统一落点 = mask + 本值 + 1) | Add/Remove |
| +36 | float | 默认 1.0 (延迟类, 语义未决) | ctor (1063675494) |
| +40 | 匿名结构 (时钟对象) | 输入时钟 (读经过秒 / 重置 / 取回) | ctor + HandleInputEvent |
| +56 | uint8 | 时钟运行旗 (ctor 1; 未运行 → 三态各自告警) | ctor + HandleInputEvent |
| +64 | 匿名结构 (按键追踪器) | 已按键状态 (匹配 / 记录两原语) | ctor + HandleInputEvent |
| +76 | uint32 | 短路门 (已匹配 ∧ key down ∧ 本旗 0 → 状态直接置 3) | HandleInputEvent |
| +104 | uint32 | 热键状态 (短路路径置 3; 记录路径 down→2 / up→1; ctor 0) | HandleInputEvent |
| +108 | uint32 | 输入序列状态 (0=Idle / 1=FirstInput / 2=Sequence; ctor 0) | HandleInputEvent |
| +112 | 匿名结构 | ctor 初始化; 本批三函数未消费 | ctor |
| +248 | double | 空闲阈值 (Idle 态: 时钟经过 ≥ 本值 → 进 FirstInput; ctor 0) | HandleInputEvent |

> +14 / +80 / +92 三偏移在 ctor 全段 + 三方法中均无消费点; 本表为 ctor + AddListener/RemoveListener/HandleInputEvent 三方法联证的现态。

监听者表槽位 (表元素, 40B):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | uint32 | FNV-1a hash (7 字节复合键) | Add/Remove 内联 FNV |
| +4 | uint8 | 探针距离 (0xFF = 空槽; >0 = 已占) | Add/Remove |
| +8 | uint64 | 键 (7 字节复合) | Add/Remove |
| +16 | IHotkeyListener*[] | 监听者向量 {data@+16, count@+28} | Add 尾插 / Remove 保序压缩 |

热键 id 结构 (Add/Remove 第二参, 16B):

| 偏移 | 类型 | 入 FNV 键方式 |
|---|---|---|
| +0 | uint32 | 全 4 字节 (键 bits 0..3) |
| +4 | uint32 | 不入键 (推定扫描码/修饰键影子, 语义未决) |
| +8 | uint32 | 低 1 字节 (键 byte 4) |
| +12 | uint32 | 低 3 字节 (键 bytes 5..7) |

> 复合键 = `+0 | (+8 & 0xFF) << 32 | (+12 & 0xFFFFFF) << 40`; FNV-1a (offset 0x811C9DC5 / prime 0x16777619) 过 7 字节。

Add/Remove 语义: AddListener — 空监听者 → 告警返 0; 命中槽位且监听者向量已含同指针 → 告警「same listener twice」返 0; 空槽 → 增长缓冲预备向量后插入; 尾插返 1。RemoveListener — 空槽 → 告警「no entry for the event」返 0; 向量无此监听者 → 告警「no such listener registered」返 0; 命中 → 保序压缩 (双指针线性剔除) 返 1。三告警的 `%s` 参数 = 事件名经 sub_142272AC0(id) 取串。

HandleInputEvent 状态机:

| 步 | 条件 | 行为 |
|---|---|---|
| 1 | 事件过热键类事件门 (两谓词合取) | 进入处理 |
| 2 | 匹配已按键 ∧ 事件 key down ∧ +76 门为 0 | 短路: +104 = 3, 返 |
| 3 | 否则 | 记录键; +104 = (down ? 2 : 1) |
| 4 | switch +108 | 按下表三态转移 |
| 5 | — | 时钟三件: 读经过秒 / 重置 / 取回 |

三态时钟机 (+108):

| 值 | 态 | 行为 |
|---|---|---|
| 0 | OnInputWithIdle | 时钟未运行 (+56==0) → 告警; 经过 ≥ +248 阈值 → 转 1; 重置时钟 |
| 1 | OnInputWithFirstInput | 时钟未运行 → 告警; 直接转 2; 重置时钟 |
| 2 | OnInputWithSequence | 时钟未运行 → 告警; 重置时钟 |
| default | — | 告警「unknown hotkey state %d」 |

错误处理: 本簇全为格式化错误日志形态 (通道 0x2000, 无中断); 无断言、无 throw。

#### 4.00.21 海军命令取消确认弹窗族运行期 (acceptcommanddialog.cpp; Populate 分发 0x1415BCAF0 + 命令数组生长 0x1415BA1A0 + 五 Build 函联证)

弹窗对象 (CConfirmCancelNavyActivityDialog / CConfirmCancelShipRefittingDialog, 4168B; CDefaultConfirmationPopUpWindow 族 [14]=Populate 覆写):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +4096 | CCommand*[] | 命令数组 data (待投命令; 接受时逐个投递) | 生长逻辑 (1.5× 扩容 + 线性查重尾插) |
| +4104 | 分配器对象指针 | 数组分配器 (vtable{alloc@+8, free@+16}; ctor 预置 &off_143085170) | 生长函双虚调用 |
| +4108 | uint32 | 命令数组计数 (引擎自定义布局, 计数@data+12) | 生长函 |
| +4112 | uint8 | — (ctor 0) | ctor |
| +4120 | CTaskForceIdPair[] | TaskForces 选择集 data (元素 8B = idpair {type u32@+0, id u32@+4}) | 分发 + 五 Build 函 (`v29 += 2` 步进 8B) |
| +4132 | uint32 | TaskForces 计数 (@data+12) | 同上 |
| +4160 | uint8 | REUNITE/策略提示门旗 (作 a4 传入各 Build 函) | 分发 |

> 本族命令数组 @+4096 与 §4.00 CAcceptCommandDialog 的载荷 @+4184 为**两套并行实现** (本族另立 CCommand* 数组, 未复用 CAcceptCommandDialog 槽位)。

选择上下文 (Populate 第三参 a3, 匿名结构; TaskForces 容器形):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | CTaskForceIdPair* | TaskForces data (8B/元) |
| +12 | uint32 | 计数 |

CTaskForce 消费侧偏移 (与 §4.16.18 表逐项一致):

| 偏移 (tf 基址) | 类型 | 语义 |
|---|---|---|
| +496 | CProvince* | 当前省份 (== repair_target → 「IN_BASE」文案分支) |
| +840 | CShip*[] | 舰船容器 data (改装进度逐舰遍历) |
| +1124 | uint32 | repair_mode (父队 ≠0 → WARN_ON_POLICY) |
| +1200 | idpair {u32,u32} | repair_parent (行内 8B; 非空 → 解析父队) |
| +1208 | uint32 | detached_activity 枚举 1..4 (分流主键) |
| +1216 | 对象指针 | repair_target (+192 → 名 id) |
| vtable[13] (vtable+104) | — | GetFleet → CFleet* (本地化「FLEET」格式参数源) |

> 坐标系定案: 句柄解析器返回 **tf+16** (与 §4.16 writer/loader 的「元素+16」约定同源), 故函数体内字面 +1192/+1184/+1200 = tf+1208/tf+1200/tf+1216; 空对象哨兵 = 解析返回 16 (tf 基址 0)。

Populate 分发流程 (sub_1415BCAF0):

| 步 | 行为 |
|---|---|
| 1 | 遍历 TaskForces (+4120/+4132): 首个有效 tf 的 detached_activity(+1208) 记为分流主键; 任一 tf activity==3 且可取消改装 → 二级旗 |
| 2 | 调基类 Populate (CDefaultConfirmationPopUpWindow [14] 链) |
| 3 | 按分流主键 switch (下表) |
| 4 | 写回 title / description |

detached_activity 分流表 (枚举全表, 断言串 + §4.16.18 双证):

| 值 | 语义 (断言串原文) | 分流函 | 文案键 |
|---|---|---|---|
| 1 | IsRepairing | sub_1415BF300 | NAVY_REPAIR_CANCEL_* |
| 2 | IsMovingToRefit | sub_1415BE6E0 | NAVY_REFIT_CANCEL_* (FLEET/TARGET) |
| 3 | IsRefitting (+ 可取消二级判定) | 可取消 → sub_1415BEBC0; 否则 → sub_1415BDC30 + 确认按钮改 NAVY_REFIT_ABORT_CONFIRM_BUTTON_TEXT | NAVY_REFIT_CANCEL_* / NAVY_REFIT_ABORT_* |
| 4 | IsReinforcing | sub_1415BEE00 | NAVY_REINFORCE_CANCEL_* |

文案装配规则:

| 场景 | 规则 |
|---|---|
| 单选 (计数==1) | `*_DESC_ONE`, 格式参数 FLEET (tf vtable[13] 舰队名) + TARGET (repair_target+192 名 id); 修理分支另判 tf+496==repair_target → `*_DESC_ONE_IN_BASE` |
| 多选 | `*_DESC_MULT`, 单参数 = 选择数 (104B 格式参数块, 步距 0x68) |
| 改装中止 (基实现 sub_1415BDE50) | 逐 tf 遍历舰船 (tf+840), 逐舰装 NAVY_REFIT_PROGRESS_LIST_ENTRY / _COMPLETE, 汇成 PROGRESS_LIST + NUM_SHIPS, 落 NAVY_REFIT_ABORT_DESC (a4=1) 或 NAVY_REFIT_CANCEL_DESC (a4=0) |
| a4 旗 (源 +4160) | 非零 → 描述尾追加 NAVY_REPAIR_CANCEL_DESC_REUNITE; 修理分支另逐队查父队 repair_mode(tf+1124) ≠0 → 追加 NAVY_REPAIR_CANCEL_DESC_WARN_ON_POLICY |

错误处理: 全为断言形态 (B52 门 a4=1, 每断言一个一次性 latch 字节); 三/四连断言序列 = GetSize()>0 → GetHeadData().IsValid() → 订单态断言; 本族 latch = byte_14338A984..byte_14338A994 (连续 17 个)。

#### 4.00.22 CSdlEvents 主事件泵 (pdxevents_sdl.cpp; 槽[1] 630 行全案)

**槽[1] = 0x142361E60 主事件泵** (每帧泵干 SDL 队列, 返 1 = 请求退出 — CApplication::Run +776 退出旗消费相接; 档 = 高置信: 调用壳 sub_142231680 `(*(vt+8))(v4, …)` 直调 + 五参 char 返值签名全等 + 单例 getter sub_14224E100 = qword_143453168 + 地址紧邻已收槽 [2][3][4]; 语料无 .rdata, vtable 内容无直证)。泵参五件: a1 = this (单例) / a2 = 帧上下文直通 / a3 = 事件观察者 (vt+88 = 十型事件分发, vt+248 = 鼠标在窗旗; 壳传 idler 槽 = 被 HotkeyManager 顶替位) / a4 = 键谓词助手 (vt+32 绑定筛 / vt+48/+56 放行) / a5 = 直通 ctx。

CSdlEvents 对象布局 (本批直证):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | 鼠标捕获/模态深度 (非零 → 鼠标事件走捕获窗投递链 sub_142361B80) |
| +16 | byte | 触摸合成鼠标过滤旗 (置位 → 丢 which == SDL_TOUCH_MOUSEID(-1) 的鼠标事件) |
| +17 | byte | 左键双击闩 armed |
| +20 | uint32 | 左键双击闩 SDL_GetTicks 戳 |
| +24 | byte | 右键双击闩 armed |
| +28 | uint32 | 右键双击闩 SDL_GetTicks 戳 |
| +32 | byte | 中键双击闩 armed |
| +36 | uint32 | 中键双击闩 SDL_GetTicks 戳 |
| +40 | void* | SDL_DROPFILE 回调 ctx |
| +48 | 函数指针 | SDL_DROPFILE 回调 fn |
| +68 | byte | 键名投递抑制旗 (真 → 仅 a4 两谓词放行时投递) |

> 三键双击 = 自实现: GetDoubleClickTime 阈值 + armed/戳闩对, 泵头逐帧过期, arm 一键清另两闩; 不用 SDL 自带 clicks 计数。

事件分派全表 (定案):

| SDL 事件 (值) | 动作 |
|---|---|
| QUIT (256) | break → CApplication 单例链收尾: 销毁 app+856 渲染器槽 +88 子对象 + PDX SDK 缓存收尾 (PDX::SDK::Api::Cache_GetData 实名) → SDL thunk sub_1420BD8A0 → 返 1 |
| WINDOWEVENT (512) | event@+12: 1 SHOWN/4 MOVED/5 RESIZED/9 RESTORED → CPdxWindow 单例 (qword_143452190 懒建 8B) vt+24(1); 7 MINIMIZED → vt+24(0)+续调 sub_142222690; 8 MAXIMIZED → vt+24(1)+同; 0xA ENTER → SDL_GetModState × GetKeyboardState[91] 对账 (修 Win32 修饰键失步) + 观察者 vt+248(1); 0xB LEAVE → vt+248(0); 0xC/0xD FOCUS → vt+24(1/0) + app 单例判空链 |
| SYSWMEVENT (513) | Win32 消息 == WM_CLOSE (0x10) → 自身 vt+32 推 SDL_QUIT (即槽[4] PushEvent) |
| KEYDOWN/UP (768/769) | mod 掩码 (&3 shift / &0xC0 ctrl / &0x300 alt / &0xC00 gui) + scancode@+16/sym@+20 构键名串 → 遍历输入绑定单例 qword_1435B9CE8 经 a4 vt+32 筛 → 投递门五析取 (+68 ∥ a4 vt+56 ∥ vt+48 ∥ 名空 ∥ ¬sub_142272FD0) → a2 vt+24; 串含特殊键 → a2 vt+16; 三特殊键谓词走 app 单例链 (控制台/截图快捷径, 推定) |
| TEXTINPUT (771) | 文本 @事件+12 (SDL 2.0.20 布局) 构串 → a2 vt+24 |
| MOUSEMOTION (1024) | 丢双击三闩 → 观察者 vt+88(10, xrel@+28, yrel@+32) + 事件包投递 |
| MOUSEBUTTONDOWN (1025) | button@+16 (1 左/2 中/3 右): 闩 armed → vt+88(7/8/9) 双击并清闩; 否则 vt+88(1/2/3) down 并 arm 本键清另两 |
| MOUSEBUTTONUP (1026) | vt+88(4/5/6) up + 事件包投递 |
| MOUSEWHEEL (1027) | 门 (¬+16 ∥ which≠−1) ∧ y≠0 → vt+88(0, 0, sign(y)) + 投递 |
| DROPFILE (4096) | +48 回调(*+40, 文件名) → SDL_free (sub_1420BD9B0) |

内部鼠标事件枚举 (观察者 vt+88 首参 0..10, down/up/dbl 三元组对称): 0=滚轮 / 1=Ldown / 2=Rdown / 3=Mdown / 4=Lup / 5=Rup / 6=Mup / 7=L双击 / 8=R双击 / 9=M双击 / 10=移动。

ImGuiIO 喂入轨 (qword_143451C80 单例非零整泵换轨; **单例身份 = ImGui 上下文全局 ImGuiContext\***, 裁定证据见 §4.26 待裁注收口: 1458 处引用 1454 处集中 ImGui 函数区 0x1421C-0x1421F, SDL 泵/触屏层/后端初始化零引用; 触屏活动表另立, input_touch.cpp 两函零引用该单例): **单例+8 = ImGuiIO**; SDL 事件泵向 ImGuiIO 喂入: 按键喂 +320 ctrl / +321 shift / +322 alt / +323 gui + **KeysDown[512]@+324** ⚠ dg036 InputTextEx 本体经验读 KeyCtrl..Super = **ctx+328..331** (IO+320..323, Shift→K_SHIFT 或位 / Ctrl→Home/End 语义直证) 与泵喂记法错位 8 字节 — 双方均经验锚定, 疑泵写双份或 IO 成员口径差, 待收口 (scancode 直索引, wassert 上界 0x1FF; 与 imgui.h IO 输入段成员序逐项自洽 = KeyCtrl..Super@IO+312..315 → KeysDown@IO+316); 鼠标键喂 +304/+305/+306 (MouseDown@IO+296); 滚轮步进 +312 y / +316 x (±1.0 f32; IO+304/+308); 状态+920 置位丢 1025/1027 (触控自合成鼠标时弃真鼠标) / +921 置位丢 768/769/771 (虚拟键盘活动弃硬件键; 两旗业务名推定, ImGuiContext 读法下重锚未决 = PDX 扩展态候选); TEXTINPUT 改追加进状态件 (sub_1421CBC00)。clausewitzlib 触点活动表容器见 §4.00.39。

输入绑定单例 qword_1435B9CE8 (pdx_scoped_singleton.h:18 断言直证): RH 12B 桶 {u8 占用, u32 键, i32 引用计数@+8}, 键 = 73244475 混淆串哈希; 减引用侧独立遍历销减 (sub_1401B04A0); 业务类名未取 (身份推定 = 绑定管理器)。

> SDL thunk 族定性: sub_1420BD880 = PollEvent / BD650 = GetTicks / BD5E0 = GetModState / BD9B0 = free / BD8A0 = 退出收尾 (按调用形态与实参)。qword_143452190 = CPdxWindow 全局单例 (懒建 8B); qword_143451C80 = **ImGui 上下文全局 ImGuiContext\*** (裁定 + 证据 §4.26; +8 = ImGuiIO)。

#### 4.00.23 pdx_ugc_steam 工坊提交域 (CSteamUGCContentItem 运行期全案; pdx_ugc_steam.cpp)

类名经错误串 `CSteamUGCContentItem::OnQueryCompleted failed with error number: %i` 实名直证 (§4.31.33 登记行由推定升高置信)。运行期布局 (≥8872B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 40B 单元基 | 查询路 CallResult 块 (回调 0x142404120 = OnQueryCompleted); 三路统一形态 = {头 16B, hAPICall@块+16, obj@块+24, fn@块+32}, 块基址 +8/+48/+88 等距 40 |
| +48 | 40B 单元基 | 新建路 CallResult 块 (回调 sub_142404070) |
| +64 | uint64 | 新建路 SteamAPICall_t (非 0 = 已注册, 重注册前先 Unregister) |
| +72 | CSteamUGCContentItem* | 新建路 CallResult 上下文 (= this) |
| +80 | 函数指针 | 新建路回调 sub_142404070 |
| +88 | 40B 单元基 | 更新路 CallResult 块 (回调 sub_142404300) |
| +104 | uint64 | 更新路 SteamAPICall_t |
| +112 | CSteamUGCContentItem* | 更新路 CallResult 上下文 |
| +120 | 函数指针 | 更新路回调 sub_142404300 |
| +128 | uint32 | 状态机: 0 空闲 / 1 新建中 (CreateItem 已发) / 2 查询中 (查询发起 0x142403260 已发) / 3 提交更新中 (SubmitItemUpdate 已发) |
| +136 | uint64 | publishedFileID (查询匹配锚 / StartItemUpdate 实参) |
| +144 | char[128] | 标题缓冲 (strncpy 128) |
| +273 | char[8000] | 描述缓冲 (strncpy 8000) |
| +8274 | char[] | 目录串 A (传 Steam 前补尾 '/') |
| +8531 | char[] | 内容目录串 B (传前 "//"→"/" 归一) |
| +8788 | uint32 | EUGCUpdateAction 直通 {0,1,2}; 值域外跳过对应 setter |
| +8792 | byte | 已有物品旗 (提交双路总门: 0 = CreateItem 新建 / 1 = StartItemUpdate 更新) |
| +8800 | char** | SetItemTags 数组 data (SteamParamStringArray_t 前半) |
| +8808 | int32 | SetItemTags 计数 (> 0 才调) |
| +8816 | byte | 新建路置 1 旗 (语义待裁) |
| +8824 | uint64 | 句柄槽复用 (query handle / UGCUpdateHandle_t; 回调尾清 0) |
| +8832 | 函数指针 | 完成回调 (实参 = 管理器, 上下文, item, status) |
| +8840 | 指针 | 完成回调上下文 |
| +8848 | uint64 | 提交入口载荷 A (a3 直存, 语义待裁) |
| +8856 | uint64 | 提交入口载荷 B (a4 直存, 语义待裁) |
| +8864 | CSteamUGCContext* | Steam UGC 管理器 (§4.00.9 已登记; 其 +152 = appID / +168 = ISteamUGC* 裸接口) |

**查询发起 0x142403260** (本批全定性): 总门 `+128 != 0` → pdx_ugc_steam.cpp:142 "Item is already processing a Steam request. Cannot start another." (闩 byte_1435DA8A3) 返 0 → Steam 门 `SteamInternal_ContextInit(&off_143085188)` 空 → :148 "Steam isn't running!" (闩 byte_1435DA8A4) 返 0 → mgr(+8864)+160 成员对象 vtable+16 取查询参数 (u32) → ISteamUGC(mgr+168) **vtable[0]** 建查询 (7 实参形; ISteamUtils vtable+72 两次同值调用推定 GetAppID) → 句柄落 +8824 → ISteamUGC **vtable+160**(handle, 1) (推定 SetReturnLongDescription — 与 OnQueryCompleted 读 8000 字描述闭环) → ISteamUGC **vtable+32**(handle) 发送得 SteamAPICall_t (0 即失败) → `+128 = 2` (查询中) + 注册 +8 块 CallResult (旧句柄非空先 SteamAPI_UnregisterCallResult)。ISteamUGC 槽名 (CreateQuery*Request / SendQueryUGCRequest / SetReturnLongDescription) 待对 Steamworks SDK 版本核 (待裁)。

提交双路 0x142403470 (260 行, 四参形, a1 幽灵参数全程未消费) / 0x1424039D0 (196 行, 单参重载 = 更新分支逐行同构): 共同前置 = 状态 +128≠0 → 断言 "Item is already processing a Steam request. Cannot start another." / SteamInternal_ContextInit 空指针 → 断言 "Steam isn't running!" (新建路站点串 "Steam is not running!", 异串同义)。新建路 = ISteamUGC vt+272(appID, 0) (CreateItem 推定高置信) → 状态 1 → 注册 CallResult; 更新路 = vt+280 StartItemUpdate(appID, publishedFileID) → handle 存 +8824 → 按序 setter (非空/有效才调): vt+320 (action, +8788 映射直通) → vt+288 (标题) → vt+304 (handle, "english" — SetItemLanguage 定案) → vt+296 (描述; IDA 实参表截断, 推定 SetItemDescription) → vt+344 (内容目录归一) → vt+336 (目录 A 补尾 '/') → vt+328 SetItemTags → vt+424 SubmitItemUpdate(handle, **"Initial Upload"**) — **changenote 恒此字面, 非首次提交亦然 (引擎 quirk 定案)**; 失败返 0 / 成功状态 3 + 注册 CallResult 返 1。

OnQueryCompleted 0x142404120 (87 行): 载荷 = SteamUGCQueryCompletedResponse_t {handle@+0, EResult@+8, numResults@+12}; OK ∧ numResults>0 → 逐条 GetQueryUGCResult (vt+40) (details = SteamUGCDetails_t 形 {publishedFileId@+0, title[129]@+24, description[8000]@+153}, 高置信); 匹配 (定案) = publishedFileId == +136 精确 ∨ title 与 +144 逐字节同名 (同名即改挂新 id) → 写 +136 + strncpy 标题/描述 + 8792 = 1 (后续提交走更新路); 查无 → 8792 保持 0 (走 CreateItem)。尾部恒走: 状态 = 0, 句柄 = 0, 调 +8832 回调 (status: 1 = 查询 OK / 2 = 未找到或错误)。

> Steam ISteamUGC 槽偏移十件: +40 GetQueryUGCResult / +272 CreateItem (推定) / +280 StartItemUpdate / +288 标题 / +296 描述 (推定) / +304 SetItemLanguage (定案) / +320 action setter / +328 SetItemTags / +336 目录 A / +344 内容目录 / +424 SubmitItemUpdate。

#### 4.00.24 pdxasset 装载器 (pdxasset.cpp; 文本/二进制双格式, 2 函)

主循环 0x142506B50 (331 行, 签名 (宿主, 文件名串, append 旗)): 文件经 sub_1424DF570 打开 (1 MiB 缓冲) 一次性读入 NUL 结尾; 打开失败 ∧ append → CLogStream "Could not open file: … while appending to …" (pdxasset.cpp:390) / 非 append 静默返 0。**格式分派 (定案)** = 文件头与全局串 off_1430C7468 strncmp (匹配 = 二进制, 否则纯文本; 前缀串内容未取证)。文本格式: '#' 注释行 / '[' 块头 (前导 [ 数 = 嵌套深度, ']' 截名须在行尾前) / 其余键值行 → 栈顶对象 sub_1425074A0。块头深度语义 (两格式共用): 深度 n > 0 → 沿解析栈 `栈底 + 112×(深度−1)` 回退 n 层后 PushAsset (空栈跳过)。

二进制指令流 (只认 '[' 与 '!', 其他字节停机):

| 指令 | 布局 (字节序) | 语义 |
|---|---|---|
| '[' ×n + 名 (NUL 结尾) | 深度 n 块头 | PushAsset |
| '!' + 'f' | u8 名长 + 名 + 'f' + int32 计数 + float×计数 | 浮点数组注入 sub_142506A30 |
| '!' + 'i' | 同形 (int32×计数) | 整数组注入 sub_142506900 |
| '!' + 's' | 同形 ({int32 长度, 字节}×计数) | 串数组 (pdx_scoped_buffer bump 分配指针数组, §3.2a acquire/release 协议) → sub_142506700 |

解析栈 (宿主内嵌, CPdxArray 主流形 §3.1): {data@+88 (112B 元), cap@+96, count@+100, CPdxAllocator*@+104 (vt[+8] allocate 对齐 8 / vt[+16] deallocate)}; 增长 = max(深度+1, 容量×1.5)。PushAsset 0x1425064A0 (123 行): 名长 ≥ 64 → 告警 "Asset has too long name (max 64): " **仅截断不中止**; 元素 112B = {+0 char[64] 资产名内嵌缓冲, 其余 48B 待裁}; 新元素构造于栈顶, 深度++, 返回栈顶元素地址。

#### 4.00.25 音乐域运行期 (musicmanager.cpp + pdx_audiosound_sdl.cpp; 4 函)

**musicmanager 解析器 0x140B74680** (437 行; 唯一调用点 = boot 装载链 sub_1401858B0 逐文件调用, a3 = app+872 加载屏作 GUI 上下文; musicmanager.cpp 断言 :147/:163/:176 直证): token 573 music → new CSong (ctor 细化: MTTH = 56B 定形 — factor u32 初值 4@+56 / qword 100000 fixed 1.0@+64 / +72 = 24B pdx 内联缓冲件 {16B 零缓冲 + off_143085170 接口}; +96 独立 u32 = 0 维持) + vtable[3] Parse + push **全局 CSong 数组单例 qword_14333C5C0** (24B CPdxArray<CSong*> 主流形); 本地 station 名空 → :163 `Error no music_station defined for songs in [file] %s [location] %s` 且 **song 仍以空名注册 (引擎怪癖)**。token 766 music_station → 全局电台名数组 {data qword_14333C6A0, cap, count, alloc} memcmp 去重 + sub_14225C5A0 (加载屏, 名, quiet=1) GUI type 校验, 失败 :147 `Missing music_station faceplate GUI component containerWindowType with name: %s` 不追加。song 名在装载期即经 sub_1423B6140 对 SSDLAudioContext 音乐名表实存校验 (miss → pdx_audio.cpp:1356 `Could not find music named %s` 返 0), 结果挂注册条目。**音乐管理器对象 unk_14333C610**: +0..+23 CPdxArray<8B 客户端> / +24 客户端包装内嵌指针 / +32..+51 CPdxArray<88B 注册条目> — 条目 {+0 station 串 (32B), +32 song 串 (32B), +64 音乐名表查找结果, +72 CSong*, +80/+84 清零}。尾 :176 `Loaded N songs.`。**sub_14225C5A0 = GUI type 名解析门** (返回 type 对象, 其 +72 可被下游消费; quiet 参抑制 gui.cpp:931 原生报错)。

pdx_audiosound_sdl 三函 (pdx_audiosound_sdl.cpp 八行号锚直证):

| VA | 行数 | 身份/机制 |
|---|---|---|
| 0x1423C1680 | 276 | WAV 装载/缓存器: 路径串 @+80 → 组装自定义 SDL_RWops (read = 0x1423C1BE0 / seek = 0x1423C1C90 / hidden.data@+48 = 引擎 VFS 文件对象; write = 0 / close = 占位 / +0 size 槽未写 = 无害怪癖) → SDL_LoadWAV_RW → 采样率 ≠44100 告警 :136 (仅告警不中断) → SDL_BuildAudioCVT (目标 32784 = AUDIO_S16LSB 立体声) → malloc ×(+256 倍率) + memcpy → +360 = 1 → 记账 dword_1435DA0C4 += +252 → debug 门内 :164 `Audio cached "<名>" (<KB> KB). Total audio cache: N MB`。失败四出口 :108/:128/:149/:176 均拼 SDL_GetError |
| 0x1423C1420 | 105 | PCM 缓存逐出器 (a1 = 音效资产表 +2088): 条件 = +240 非 0 ∧ +360 零引用 ∧ +364 < dword_1435DA0C8 − 1200 (LRU 窗口 1200 tick); 逐出 = 记账 −= +252 → SDL free (+240) → 置 0; **每 call ≤5 个**; debug 门内 :32 `Audio evicted ...`; 桶推进带 pdx_robin_hood_table.h:58 哨兵断言 (§3.2 机制层互证) |
| 0x1423C1BE0 | 28 | 自定义 RWops read 回调: 断言 :86 `nSize != 0` → `read(*(rwops+48), buf, nmemb×size)/size` (fread 语义部分读向下取整); 引擎文件读包装带 virtualfilesystem.cpp:370 `IsValid()` 断言 (新源文件锚) |

音频全局 tick = dword_1435DA0C8 (递增点 = 声部回收 tick sub_1423BF4B0 头部; 声部回收 = SRWLock@+2384 + SDL_LockAudioDevice(mgr+2400) 临界区内: 声部+8 源资产 −−(+360) → +104 PCM 块释放 → 删声部)。播放启动 sub_1423BF080 双写点: +364 = tick / +240==0 → 懒装载 0x1423C1680, 否则 ++(+360)。SDL thunk 扩表: sub_1420BD830 = LoadWAV_RW / sub_1420BD3E0 = BuildAudioCVT / sub_1420BD5B0 = GetError / sub_1420BD9D0 = SDL 侧 malloc / sub_1420BD410 = FreeAudioCVT 或 ConvertAudio (待裁) / sub_1420BD470 = FreeWAV / sub_1420BD840 + sub_1420BD980 = Lock/UnlockAudioDevice。

#### 4.00.27 CFileLogger 引擎文本日志器全案 (filelogger.cpp; 8 函 — 20 日志器装配/settings 位旗/轮转/logs 清空机制点)

RTTI 直证 CFileLogger::vftable 0x142B3AC78 (vtable[1] = Write 0x142224240 PE 实读命中); 另 CVirtualLogFile::vftable 直写于普通文件开启器 0x1424DF6C0 (ctor 0x1424DF570 先装基表 CVirtualFile 再覆写派生表)。

**CFileLogger 对象布局** (定案):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable* | 0x142B3AC78 |
| +8 | std::string (32B) | 缓存的当前游戏日期串 ([date] 前缀源) |
| +40 | bool | 日期串有效旗 (0 → 写 [no_game_date]) |
| +72 | CVirtualFile* (scoped ptr) | 日志文件对象 (pdx_scopedptr.h:124 断言守卫) |
| +80 | uint32 | settings 位旗 (下表) |
| +88 | uint64 | 累计字节数 (每次备份/清剪 += 文件尺寸) |
| +96 | uint64 | 累计条目数 (每次备份/清剪 += +112 后清零) |
| +104 | uint64 | 清剪阈值 (四参 ctor 实参; 三参 ctor 清零) |
| +112 | uint64 | 本次条目计数 (Write 末尾 ++; 清剪时并入 +96) |

**settings 位旗表** (0x142224240 + 装配实参 + 真实日志文件三重互证, 定案): 0x01 禁自动刷盘 / 0x02 行首墙钟 [HH:MM:SS] / 0x04 [文件名:行号] 前缀 / 0x08 文件尺寸 > +104 → ClearFile(0) 原地剪 (LOGGER_CLEAR_WHEN_FILE_SIZE) / 0x10 条目数 > +104 → ClearFile(0) (LOGGER_CLEAR_WHEN_NUM_ENTRIES) / 0x20 超阈值丢弃本条不维护文件 / 0x40 用游戏时间串替代墙钟 / 0x80 游戏日期前缀。行组装序 = 时间戳 → 日期 → [file:line] → ": " → 消息体 → `\n`→`\r\n` 归一 (sub_1424CCEA0) → 写串 → ++计数 → 条件刷盘; 入口类别查证 (filelogger.cpp:55, 全局表 qword_1434521A8 511 桶) 仅喂断言不参与行内容。

**20 日志器装配总表** (装配厂 0x140122920, 调用方 = 命令行初始化 0x140126E50; 每器 = malloc 0x78 + 路径拼接 logs 目录 + 名 + infix qword_143085030 (默认空) + ".log"):

| 名字 | settings | 阈值 | 行前缀效果 |
|---|---|---|---|
| system_debug / scenario_testing / game / ai / setup / system / memory / time / text / graphics | 134 | — | 时钟+[file:line]+日期 |
| ai_trace | 130 | — | 时钟+日期 |
| error | 非 debug 166 (134+0x20); debug 旗 byte_14332EC69 时 134 | 非 debug 100 MB (0x6400000) | 时钟+[file:line]+日期; 超 100MB 丢条不剪 (防崩溃刷屏) |
| message | 198 | — | 时钟+游戏时间(0x40)+[file:line]+日期 |
| code_revisions / custom_automated_stats | 0 | — | 裸行 |
| received_commands / executed_commands / posted_commands / sent_commands | 206 | 100 MB | 时钟+[file:line]+日期; 超限原地剪 |
| random | 1 | — | 裸行 + 禁自动刷盘 (轮转点显式补 Flush) |

> **0x01 位旗消费点 (定案)**: CFileLogger::Flush 0x142223FA0 / Close 0x1422240E0 = settings 位旗 0x01 (禁自动刷盘) 的**唯二消费点** — Close 尊重位 (置位 → 跳过刷盘直接关), Flush 无视 (无条件强制)。两函同骨架: 全局互斥锁 sub_1424C9350 (RAII sub_1424D3E00 加锁 / j__Mtx_unlock 解锁 / sub_142223230 unwind) + 双断言 (pdx_scopedptr.h:124 "_pPtr" 闩 byte_1434521A3 = **通用 scoped_ptr 解引站, 非 filelogger.cpp 专属** / filelogger.cpp:313 "_pFile->IsValid()" 闩 byte_1434521A1) + 核心调 CVirtualFile::Flush 0x1424DF900。调用链: Flush = sub_140DDAC60 (idler 槽[66] 周) random 单例 qword_14332EC60 轮转后强制刷盘 + session 收尾点; Close = CFileLogger dtor 链 / Logger 析构替换链 (Close 后再 CVirtualFile::Close 0x1424DF8C0)。

**ClearFile (0x1422249C0) 双模**: a2=0 全剪 (尺寸账入 +88/+96 → Reopen(1) 截断重开, 失败 :167 → 写 "[Log pruned of %d entries. %u KB.]"); a2>0 保尾模 = .temp 改名回拷尾部 4096 字节块循环 (剪的是尾部字节非条目, 消息文案按条目 — 引擎原文如此; **全语料零调用点 = 预留/死路**)。

**备份轮转 (0x1422233B0) = random.log 专供** (定案): 逆序 i = BackupCount..0, 名 = 目录前缀 + "random" (硬编码) + (i>0 ? "_"+i : "") + ".log"; i==BackupCount 删除否则改名到 i+1 → Reopen(1) (:296) → 写 "[Saved backup of %d entries. %u KB.]"; BackupCount = dword_14308500C (PE 默认 6, 语料零写者待裁); 4 调用点全部作用于 random 单例 qword_14332EC60 (其一 = byte_143452529 门 = random 日志门)。行为级实证 = 真实 logs 目录 random_N.log 链。

**logs/ 启动清空机制点 (定案)**: 20 个日志文件在命令行初始化全部以 **mode 1 (截断写)** 打开 (普通开启器 CVirtualLogFile; 轮转/清剪重开路径同 mode 1) — 截断发生在打开时刻; **被清空的只是 logs 根目录这 20 个固定 .log, 子目录 (audit/metrics/variable_dumps) 与非 logger 文件不受影响**。

**CLogger 族 vtable 三态** (与 §4.26 错误计数消费面互证): CLogger 抽象基 (0x142B91D18, 5 槽) 下 CFileLogger [2]/[3] = 常量桩 (ret1/ret0 共享微型桩, IDA 符号名不承载语义); **CFilterLogger (0x142B3AF58) 四槽全真函数, [3] = 计数器实装 0x142225530 — §4.26「错误计数 = 全局 vtable[3](4096) 前后差」的全局即 CFilterLogger 实例**; CNullLogger 全空。文件层动词表 (CVirtualFile/CVirtualLogFile): ctor 0x1424DF570 (mode 入 +48; 0 读/1 截断写/2 VFS 写) / Reopen 0x1424E0000 / IsValid 0x1414D4D70 / Flush 0x1424DF900 / Close 0x1424DF8C0 / GetSize 0x1424DFA20+AB0 / WriteString 0x1424E15D0 / Write+Read 0x1424E14D0+03A0 / Seek 0x1424E0970 / rename 0x1424DDFC0 / delete+exists 0x1424E0B20+B90; 默认缓冲 0x100000 (1 MB)。断言 9 站 (filelogger.cpp :36/:55/:157/:167/:188/:256/:260/:296/:313), 门 = byte_1435E1B52 全簇一致, latch byte_143452199..1A3 十枚。 增补: WriteString 细节 (size@串+16, 空串返 1, _Mode∈{1,2} 门, 统一写入口 sub_1424DE700 返实际写入数); 新站 = Reopen 变体 0x1424DFE50 ("No file to reopen" :529, 打开原语 sub_1424DDBD0 第 4 参 = 缓冲大小 0x100000) / Write-CRLF 变体 0x1424E1860 (+16 旗开时 256 KiB alloca 栈缓冲逐字节 LF→CR LF 翻译, 短写 throw CFileException) / 日志打开辅助 0x1424E07A0 (拼 .log, 失败 "Could not open file") / 句柄解析+代际校验 0x1424E0440 (IsValid 三站); 句柄族字段 = +8 底层句柄 / +16 LF-CRLF 旗 / +48 _Mode / +56 当前文件指针; CFileException 构造器 = sub_1424F1070 (80B: 行号, file 串, msg 串); virtualfilesystem.cpp 断言 latch 簇 = byte_1435E3EAD..B7 (与 filelogger.cpp 簇两文件两簇)。

**CTest 族运行时机制 (tests.cpp 增补, §4.00.9 类壳之上)**: 六函 = CTest::Execute 0x1402AEA20 (436 行) / CTestBundle::PrintResults 0x1402AE4C0 (三桶汇总 "'<名>' RESULTS" failed/passed/didn't run) / CTestDatabase::InitLogger 0x1402AE0D0 / SaveFailSnapshot 0x1402B0070 / 桶名打印 0x1402AE940 / catch funclet 0x1425A12B0。**CTest 字段表** (定案): +8 测试名 SSO / +40 成功条件 CPdxScopedPtr* / +48 失败条件 CPdxScopedPtr* (解引用助手 sub_1402AD850 = pdx_scopedptr.h:124 判空 + __debugbreak; 条件对象 vtable+24 = Evaluate) / +56 结果态 (0 未决/1 OK/2 FAIL) / +60 剩余计数 (语义推定) / +64 acceptable_fail_rate double / +72 值记录器容器 (CTestLoggersArray* 推定; 元素 vtable+72 = 值格式化)。**Update 驱动** 0x1402AF230 (簇外): 门 = 全局测试旗 byte_14332F70E; 首帧 bundles 装载 + 懒建 logger; 每帧 gs+1128 日期 ≤ bundle+48 (束结束日期) → 逐测试 Execute (OK → "OK - <名> (<日期>)" / FAIL → "FAIL - ..." + **TEST_FAIL_<日期> 失败快照**); 出束 → PrintResults 一次 (bundle+88 报告旗); 尾 db+72 writer vtable[0] 后清 0 (置位者未决)。**SaveFailSnapshot 双路落盘**: 幂等门 = 每游戏日一次 (db+88 记上次日期); writer 路 = temp+删+改名三步写 (writer vtable[14] 载荷 / [2] 填充; 路径 = app->vt[+880]()+168 存档目录); 引擎路 = sub_140BC0880 构造 192B 存档请求 (双 CGameDate, +136 = 43808760 "1.1.1.1" ctor 哨兵直证) → sub_140DA3530 入引擎。**测试日志** = CFileLogger (ctor 0x1422230C0) 写 `logs/tests/tests_<%Y_%m_%d_%H_%M_%S>.log`, 类别 65544 (0x10008; 错误 4096); CONFIG 行打印 acceptable_fail_rate。**新 RTTI 锚**: VCTestDatabase::?$TGameItemDatabase 0x1427371E8 (CTestDatabase 属库族直证) / **CTestAndTrigger 0x1427372E8** (书未载类, 本体待裁)。

**CPdxCrashReporter 本体 (pdx_crashreport.cpp 补链定案)**: CU = `clausewitz\pdx_crashreport2\pdx_crashreport.cpp` (目录名带 2)。1032B (malloc 0x408) 单例; **_pInstance = qword_1435B9F40** / 实例槽 qword_1435B9F48; +0 = CPdxCrashReportImpl 接口指针 (48B impl 对象 sub_142395310 构造) / +216 = crash 目录串 (追加 "crash_reporter/", 并经 sub_1424E35F0 登记设置系统 qword_1435E3EC0 键 "crash_reporter_dir") / +760 旗 / +768 = CPdxCrashReportWindows* (16B 工厂, vtable 与书链一致)。ctor 0x142391780: SPdxCrashReportSettings 四必填 (AppName/SCMBranch/SCMCommit/SCMTimeStamp, 缺项各抛 PdxError) + AppId/UploadURL 上传门 ("needs either an AppId or an UploadURL for PDX_LIVEBUILDs") + :202 断言 (闩 byte_1435B9F56)。Create 0x142393230 (magic static + 旧实例仅告警 :158 "resulted in a memory leak") / Instance 0x142392640 (:150 断言闩 byte_1435B9F54)。WriteMetadataFile 0x1423944A0: 文本 metadata = "# Crash Information" 12 字段 (AppName/AppVersion/SCMBranch/SCMCommit/SCMTimeStamp/DateTime/BuildType/Platform/Architecture/OperatingSystem/SystemLanguage/CPUModel/LaunchArguments) + "# Application Specific Data" 块 (设置系统 qword_1435E3EC0 全枚举) + **debug 旗 byte_14332EC69 行 ("debug: 1")** — 与右键菜单 debug 门同一全局跨域互证。

#### 4.00.28 CStringTokenizer 拆词器 (stringtokenizer.h; 1 函 = 0x141379670, 265 行 — 书未收簇)

**真签名 4 参** (所有调用点伪码只显 1 参, rdx/r8/r9 被 IDA 丢弃): `(const std::string& text /*rcx*/, CPdxArray<u32str32>& out /*rdx, 24B*/, const DelimiterSet& delims /*r8, 32B = 256 位集*/, uint32 (*remap)(uint32) /*r9, 逐码点改写回调*/)`。

流水: ① **UTF-8 → UTF-32** = sub_1424FE550 → 内层 sub_1424FE880 (ConvertUTF.cpp:741; 失败格式化 "Failed conversion of utf8 string: %s"; 出长 `*a5 = (end−begin)>>2`) → UCS4 串 {buf/ptr@+0, size@+16, cap@+24}, 内联阈 cap ≤ 3 (16B = 4 码点), **恒附 u32 终止符** (memcpy 4×size+4)。② 逐码点 `remap(token[i])` 原地回写。③ 分隔判定 sub_1422FBEF0(cp, set) = 256 位位集查询 (`set[8×(cp>>6)]` 取 qword + `_bittest64(&v, cp & 0x3F)`), **cp > 0xFF 恒非分隔符**; 注册端 sub_1422FBED0(cp, set) = 置位。④ 非分隔符且非跳过态 → push 进累积 UCS4 串。⑤ **分隔符 token 分派表**:

| 码点 | 动作 | 机制 |
|---|---|---|
| 0x11 (17) | 跳 1 码点 | 每轮递减 |
| 0x12 (18) | 跳 3 码点 | 每轮递减 |
| 0x13 (19) | 引号态 | 后续码点无视位集直累积, 直到下一分隔符清态 |
| 0x14 (20) / 0x1A (26) | 区段态 | 跳至同码点再现即关闭; ⚠ **断言 "not implemented" @ :80 (latch byte_14338A211) — 实现未完成** |
| 其他 | 继承当前区段态 | 维持 |

⑥ 落词: **词长 ≤ 2 码点丢弃**; 否则 sub_141380BE0 拷成 **32B 元素** push 进 out (CPdxArray, cap 满走 `alloc→vt[1](32×newcap, align 8)` 迁移, 1.5× 增长)。⑦ 收尾 sub_141381570 末次落词 + 两 UCS4 串析构。

**分隔符集合** (空白归一化器 sub_141875D00 注册进全局位集 unk_14338B228): `{0, 9 (TAB), 10 (LF), 13 (CR), 17, 18, 19, 20, 26}` — 前四 ASCII 空白, 后五结构控制码 (与分派表逐项对上)。调用方两路: 空白归一化器 sub_141875D00 (拆词 → 空格 join → 回 UTF-8) / 本地化 tooltip 格式器 sub_1413840E0 (3 站, 调 §4.19.9 localize.cpp 入口 sub_142245E60)。未决: 词长 ≤ 2 丢弃的业务语义 (推定 = 过滤纯控制码段) / remap 回调真身 (推定大写折叠或 UCS4 规范化)。

#### 4.00.29 CDbRefVariable 脚本库引用 (db_ref_variable.h; 2 函 = PostValidate 0x1403A6360 / GetDbObject 0x14032AD40 — 书未收簇)

**对象布局** (≥216B):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | MSVC 串 32B / 指针 (联合) | state 0 = **名串** ({buf@+0, size@+16, cap@+24}); state 1 = **已绑库对象指针** |
| +56 | 指针 | 拥有者/错误接收器引用 (移动构造 sub_14032C510: `*(dst+56) = src+56`, 自指调 vt[1] 克隆; 释放调 vt+32 清 0) |
| +208 | u8 | 状态字节: 0 = 未 PostValidate / 1 = 已解析缓存 +0 (重复 PostValidate → :97 "Duplicate call to PostValidate" 断言) / −1 = 析构态 (→ sub_14032A150 = sub_1403BAAF0 **noreturn 致命路径**) / 其他 = 变量引用态 |

**PostValidate (0x1403A6360)** = 名路径一次性绑定: state 0 → gameitemdatabase.h:142 单例断言 (qword_14332EF30) → sub_140A42670 = **TGameItemDatabase 按名查** (sub_140BC96D0 构串 view + sub_140A3F140 查 db+104 表 / db+80) → `!*(v9+56)` (库条目无效旗) → 错误 **"Invalid %s: %s. If you wanted to reference a variable, you need to explicitly prefix it with var: or temp_var:."**; 成功 → sub_1403B9B10 释放旧槽 + state=1 + `*a1 = v9`, 返回条目有效旗; 失败返 1 (宽容)。

**GetDbObject (0x14032AD40)** = 运行期取库对象访问器 (描述符 a1: +64 = TGameItemDatabase 单例指针, +72 = 严格校验旗): state 1 → 返缓存; **state 非 0 (变量引用路径) 四步链**: ① sub_140544C90 = scopedvariable.cpp:1288 脚本值求值器 → v15 = fixed×1e-5 值; ② `v4 = sub_1424BC260(v15 / 100000)` = **token id → 名串入口** (lexer.cpp:381, 表基 qword_1435E1AE0 + 32×id); ③ gameitemdatabase.h:142 单例断言 → sub_140A42670 按名查; ④ `*(a1+72) && !*(v5+56)` → 错误 "variable does not reference a valid %s: %s"。state 0 → :121 "Not post validated" + null_object.h:133 → 返 **qword_14332FB10 (null object 单例, 高置信)**。

**关键机制 (定案)**: var:/temp_var: 变量在脚本侧以 **token id × 1e5 定点**存入 db_ref_variable, 运行期经「脚本值求值 → ÷1e5 还原 token id → lexer token 表取名 → 库按名查」四步解析; 直接名引用则在 PostValidate 期一次性绑定并缓存 (与 §4.10/§4.33 temp_var:old_ideology_token 同形)。未决: 状态字节「其他」取值集合 / GetDbObject 描述符类型 (RTTI 未取得)。

#### 4.00.30 音乐资产装载与注册链 (pdx_audiomusic.cpp + assetfactory_audio.cpp; 解码 0x1423C07C0 / 外联 catch 0x1426F3990 / 批量预装 sub_1423B5940 + 上下游工厂 2)

**CAudioMusic 资产 240B 全布局** (工厂 sub_1423B5C40, vtable 符号 `&CAudioMusic::`vftable`` 直证):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | `CAudioMusic::`vftable`` |
| +8 | u16 | 实例 id 基 (ctor 拷自 SAudioContext+2200; 实例工厂再拷入实例 +80) |
| +10 | u8 | 代际 (ctor 1; 实例工厂 ++ 回绕 255→1) |
| +12 | i32 | 计数 (ctor 1; 语义未决) |
| +16 | char[] | **名字 C 字符串** (≤64B; 表键 — 工厂对 +16 跑 strlen + FNV-1a 32 位) |
| +80 | MSVC 串 32B | **文件路径** (缓冲@+80 / 长度@+96 / 容量@+104; 解码入口按 a1+64 裸 C 串读) |
| +112..+208 | — | 空区 (注册期零) |
| +208 | f32 | **音量** (ctor 1.0; 注册时由 init 结构 +192 覆写 = 拷贝在后) |
| +216 | qword | 解码后数据句柄 (装载前 0) |
| +224 | i64 | 时长 (纳秒 = f64 秒 × 1e9 截断) |
| +232 | i32 | 格式枚举 (1 或 2, 由解码信息块 +4 派生: `(info+4 != 1) + 1`) |
| +236 | i32 | 解码信息块 +8 (采样率/声道级, 语义待裁) |

**注册链 (定案)**: assetfactory_audio.cpp 的 **music(573)** case → 栈建 **SMusicReader 240B** (vtable 符号 `&SMusicReader::`vftable``@+0, 数据区 +8..+232) → sub_1424DC920 解析路径入 +72 (串形, 镜像到资产 +80) → sub_1423B5C40(SAudioContext+24, &reader+8)。工厂内: **224B 块拷贝** (14 × oword, reader+8..+232 → 资产+16..+240, 尾正好落在对象末) → FNV-1a 32 (offset basis 0x811C9DC5 / prime 16777619) → sub_1423B2DB0 入 SAudioContext **+2184 robin_hood 表** (桶 48B {dist u8@+4, 名串 32B@+8, 值@+40}; data@表+8 = ctx+2192, mask i32@+2204, extra u8@+2208, 桶数 = mask+extra+1)。**重名处置 (新发现)**: latch byte_1435BA0AB 未置 → 告警 pdx_audio.cpp:1294 "Music with name '%s' already added" 并返 0; 已置 → **静默返回已有项**。资产 id = `*(u16*)(ctx+2200)`。

**音乐文件解码入口 0x1423C07C0** (224 行; 高置信): 签名 `(a1 = 资产内嵌数据基址 = CAudioMusic+16, a2 = 模式)`, 两调用点 `sub_1423C07C0(asset+16, 0/1)` 直证。路径串 = a1+64 裸 C 字符串。

| 模式 | 阅读器 | 回调表 (4 函数指针, 栈上) | 装载形态 |
|---|---|---|---|
| a2 != 0 流式 | 栈上 56B, sub_1424DF570(reader, &path, 0, 0x100000, 1) (1 MB 缓冲) | {sub_1423C0DA0, sub_1423C0E10, sub_1423C0D50, sub_14072DEA0} | malloc 0x20 建引擎容器 {data@+0, cap i32@+8, count i32@+12, alloc@+16 = &off_143085170}; cap×1.5 增长; count = GetSize → resize (尾 memset 补 0) → Read 全文件入缓冲 |
| a2 == 0 内存 | 堆上 56B (malloc 0x38) | {sub_1423C0CD0, sub_1423C0D00, sub_1423C0CB0, sub_1423C0D40} | 直接解码 |

解码 = sub_1423C4E40(源, 新对象, 0, 0, &回调表); **新对象 = malloc(0x350) = 848B 解码对象** (两模式共用; 返回后存入实例 +88 — §4.00.25 原称「流句柄」, 实为解码对象)。成功尾段读三接口: sub_1423C4DF0 → 信息块 (info+4 dword → 格式枚举; info+8 dword) / sub_1423C58A0 → 数据句柄 / sub_1423C6300 → 时长 f64 秒。**回写宿主 (a1 = 资产+16)**: +200 = 数据句柄 qword (→ 资产+216) / +208 = `(int)(时长秒 × 1000000000.0)` i64 纳秒 (→ 资产+224) / +216 = `(info+4 != 1) + 1` dword (→ 资产+232) / +220 = info+8 dword (→ 资产+236); 失败路径置 +200 = +216 = 0。bad_alloc 处理 (pdx_audiomusic.cpp:158) 拼接 `阅读器路径 + ":" + what() + " size " + GetSize` 后告警; **0x1426F3990 = 同 catch 的外联形态** (36 行, 消费上下文对象 {异常@+112, 阅读器@+120, 串缓冲@+176/+336}, 与内联块同串同站点)。

**音乐批量预装载 sub_1423B5940 (新, 高置信)**: 遍历 SAudioContext+2184 表 (跳 dist==0 空桶), 对每项以**流式模式** sub_1423C07C0(资产+16, 1) 装载 → sub_1423C0790(对象) → sub_1423BF7B0(资产) 释放; 遍历序含 robin_hood 迭代哨兵自检 (pdx_robin_hood_table.h:58 "_pEntry->_DistancePlus1 != nIteratorSentinelDistance", 门 byte_1435E1B52 + latch byte_1435BA0B0)。= 启动期预热全音乐表的证据 (装载后即释放, 运行期再按需重装)。

**CAudioMusicInstanceSDL 工厂 sub_1423BE580 增补** (高置信, ctor 段 vtable 符号直证): 槽位分配 = 于 SSDLAudioContext +8..+72 八槽线性找首个空槽, 全程 AcquireSRWLockExclusive(ctx+2384) 并以 ctx+2400 为锁参数; 满槽或解码失败 → vtable[0](this, 1) 释放返 0。音量族: +68 = a4 × 资产音量 f32@+208 (目标量) / +64 = 非淡入基量 / +76 = a5。状态 +20: a5 ≤ 0 → 1, a5 > 0 → 3 (1=播放 / 3=淡入, 推定)。未决: 解码对象 848B 的类名 (语料无 RTTI 符号, 推定属 SMusicReader 家族) / 成功尾 `v4[210] = 0` dword 写落 malloc(0x350) 尾后 4B (元类型失真或真实尺寸 0x354, 未决)。

#### 4.00.31 PdxSpeechToTextInterface 语音监听者容器 (pdx_speech_stt_interface.cpp; 2 函 = AddListener 0x1423AB550 / RemoveListener 0x1423AB7A0)

**对象布局 (定案)**: {vtable@+0, 监听者容器@+8 = {data@+8, cap i32@+16, count i32@+20, alloc ptr@+24}}, 元素 = 监听者**裸指针 8B**; 分配器 = CPdxHybridInlineBufferAllocator\<Listener*,N\> (经 vt+8 allocate / vt+16 deallocate, off_143085170 全局堆单例兜底, §4.00 CPdxHybridInlineBuffer 契约)。

| 函数 | 机制 |
|---|---|
| AddListener 0x1423AB550 | a2 == 0 → cpp:9 "trying to add nullptr listener!" 断言; 线性查重命中 → cpp:15 "trying to add a duplicate listener!"; 未命中 → newcap = (int)(float)(cap × 1.5) (f32 中转, 大 cap 精度损失), count+1 > newcap 则 newcap = count+1; allocate(8×newcap, 8) → memcpy 旧数据 → deallocate(old) → 写回 data/cap/count |
| RemoveListener 0x1423AB7A0 | a2 == 0 → cpp:26 "trying to remove nullptr listener!" 断言; 线性查找未命中 → cpp:32 "trying to remove an unknown listener!"; 命中 → **带去重紧缩** (从命中位起逐元前移, 跳过所有等于 a2 的项 — 容器内同指针多份一并清掉), 尾写新 count |

> 族已排除 (SAPI 无障碍, 零游戏数据接触); 仅作容器布局与断言站点台账。Initialize 0x1423ABBA0 的 SAPI COM 链 (CoInitializeEx(0, 6) / CoCreateInstance ×2 / SetId "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Recognizers" / EnumerateTokens("language=409", "VendorPreferred")) 与 SAPI 逐槽语义 (SetRecognizer/SetInput/SetInterest/SetRecoState/SetGrammarState 按实参形态推定, 逐槽待裁) 不再展开。

#### 4.00.32 CPdxCommandLine 命令行解析器 (pdx_commandline.cpp; 2 函 = 解析器 0x1424E3960 / 工厂 0x1424E3490 — 书未收簇)

**解析器 0x1424E3960 (261 行, 定案)**: 签名 `(a1 = 输出容器, a2 = 源串对象)`; a2 = MSVC std::string 形 (长度 i32@+16, 逐字符访问 sub_1424CB4D0 = operator[] 返 `&buf[i]`)。输出容器 a1 = {data@+0, count i32@+12}, **元素跨距 64** (`v19 = *v3 + (count<<6)`), 元素 64B = 2 × 32B std::string, 推定 = {name, value} 选项对 (单串 push 经 sub_1424E3F20)。状态机 `v5` 三态:

| 态 | 语义 |
|---|---|
| 0 | token 起始 |
| 1 | 选项名内 |
| 2 | 选项值内 |

分词 switch (case 值 = ASCII):

| case | 行为 |
|---|---|
| 0 (串尾) | 落当前 token |
| 32 (空格) | 查**分隔符静态表** qword_1430C73A0 (字节数组, 计数 dword_1430C73AC): 在表内 → 落 token, 否则并入当前 token |
| 34 (引号) | sub_1424CBBB0 找配对引号 + sub_1424CC260 取子串落 token; **不配对 → cpp:206 "String literal with unmatched \" in command line argument, clearing arguments" + sub_140126D50(a1) 清空 + 返 0** |
| 43 '+' / 47 '/' | 选项名开始 (态→1) |
| 45 '-' | 选项名开始, 且**吞掉第二个连续 '-'** (支持 `--long`) |
| 61 '=' | 仅选项名态转值态 (态→2), 否则当普通字符 |
| default | 并入当前 token (起始态同时置 1) |

尾段 = **稳定排序** (推定 std::stable_sort 形): n ≤ 32 走插入 sub_1424E2BD0, 否则归并 sub_1424E2F10; 懒分配 scratch = `n − n/2` 元 (每元 64B, 上限 0x3FFFFFFFFFFFFFF 元, 分配失败折半重试, 底线 64 元栈缓冲); 栈上末两参 = 一个 64B 元素级交换暂存 (2 × std::string)。

**分隔符静态表 (新发现)**: 全局 qword_1430C73A0 (缓冲) / dword_1430C73AC (计数), 初始化块挂 `CPdxHybridInlineBufferAllocator<char,4,int>::`vftable`` (qword_1430C73B8) + 基接口 off_143085170 (qword_1430C73C8): 查询槽 vtable+32 判等 sub_140161230 → 命中取内联 4 字节缓冲 (`qword_1430C73A0 = &unk_1430C73C0`, 计数 4), 否则调查询克隆填; 尾 sub_140185CC0(..., &v37, 4) 落表。推定 = 4 个默认分隔符字符 (空格已硬编码 case 32, 表内为其余如 tab; 具体四字符未验)。

**工厂 0x1424E3490 (30 行, 定案)**: `j_j__malloc_base(0x28)` = **40B 命令行对象**, 存全局单例 qword_1435E3EC0; 布局 = {+0/+16 两个 oword (sub_14011DF40 ctor, 推定容器或串), +24 i32 = −1 (哨兵/索引), +32 qword = 0}; 随后调 sub_1424E3720(obj, a1, a2) 真初始化 (a1 = u32 旗, a2 = argv/命令行串); 失败 → cpp:28 "Failed creating commandline" 断言返 0。单例经 Init_thread_header(&dword_1435E3EC8) + atexit(nullsub_2) 保护。未决: 输出元素 64B 内部布局与排序比较器 (需读 sub_1424E3F20 / sub_1424E2F10 / sub_1424E2BD0); 40B 对象 +0/+16 两 oword 语义与 +24 的 −1 哨兵含义。

#### 4.00.33 modifier 定义表完整性诊断 (pdxmodifier.cpp; 1 函 = 0x1405580E0)

**机制 (定案)**: 启动期 debug 门校验, 总门 byte_1435E1B51 (debug_assert 族, §4.00「断言门按宏族分门」一致)。表 = 平坦数组 {data qword_14332ED90, count dword_14332ED9C}, 条目 120B (与 §4.10 def 全局库 qword_14332ED90 (120B/条) / §4.13 规则表 `qword_14332ED90+120×id` 一致):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | MSVC 串 32B | modifier 名 (缓冲@+0 / 长度@+16 / 容量@+24) |
| +112 | i32 | **名字 token id** (0 = 无名 → 走「定义但未实现」分支; 非零经 sub_1424BC260 取名, 非零投影即「已实现」) |

逐条: `+112 == 0` → cpp:788 "Error in definitions array" (latch byte_143330436, once 形) + cpp:789 `序号 + " is defined but not implemented."` 风格日志; `+112 != 0` → sub_14055D110(条目, &out_std::string) 取本地化串 (推定 = 按名查 loc), 与条目名**逐字节比较**: 相等 → cpp:796 "No localization for modifier " + 名 (即落回键本身 = 无本地化)。未决: +112 已实现旗与书既有 +104 flags 的关系 (两字段并存, 正交还是联动未验) / sub_14055D110 是否确为 loc 查询 (推定)。

**同表 JSON 文档导出器 0x140558CE0 (定案, 函级新定性)**: 脚本文档 JSON 导出主函 sub_140299AD0 的 "modifiers" 节生成器 (该主函 10 键 = script_concepts / loc_formatter / script_collection_input / script_collection_operator / script_math_functions / loc_objects / effects / modifiers / dynamic_variables / console_commands; 开发期文档导出通道, 与本节完整性诊断分工不同)。第一段 = **内置条目 1..665 全量逐条下发** (665 = 1.19.3 原版内置 modifier 数, 新常数; +112 token 经 sub_1424BC260 取名写 "name" 字段, 0 = 无名跳过取名仍出记录) → `sub_14060F5D0(def, 0, &rec)` 内置态附加字段。第二段 = **动态 (mod 追加) 条目自主表 667 起** (666 空档语义未决); 名池 qword_1433300B0 = 16B/条 {+0 token u32, +8 char* 名}; 名非空 → **FNV-1a 前 8 字节**哈希 → sub_140552990 本地 robin-hood 表 (48B/条 {+4 距离, +8 key, +16 u32 主表条目号, +24 vector\<string\>}) 查找/插入 → 收尾逐桶组内排序 (≤32 插排 / >32 归并) 后 `sub_14060F850` 出 JSON = **同名多定义归并展示**; 名空 → `sub_14060F5D0(def, 1, &rec)` 动态无名态。断言 pdx_robin_hood_table.h:58 `_pEntry->_DistancePlus1 != nIteratorSentinelDistance` (闩 byte_143330435, flags=1)。JSON writer 族 = sub_1424C5F00 建容器 / sub_1424C5F10 建值 / sub_1424C5DE0 挂键 / sub_1424C5E30 字段赋值 / sub_1424C5E90 数组追加。

#### 4.00.34 Dear ImGui 后端初始化 (pdx_dearimgui.cpp; 1 函 = 0x142081EB0 — 补 §4.26 面板族的后端契约)

**流程 (高置信)**: off_1430BF7C0(a1) 探针返 >1 → 直接返 (已初始化/错误); 否则六步:

| 步 | 操作 |
|---|---|
| ① | sub_1421CFA90(0) 建上下文 (共享上下文 = null) |
| ② | sub_14220D390() / sub_142219270() = IO/风格初始化 |
| ③ | v2 = sub_1421D1F50() → `*v2 \|= 0x20` (推定 = ImGuiIO.ConfigFlags \|= ImGuiConfigFlags_NavEnableKeyboard) |
| ④ | **v2[13..34] = 22 × i32 键映射** (推定 = ImGuiIO+52 起 KeyMap[ImGuiKey 0..21] = Tab/四方向/PgUp/PgDn/Home/End/Ins/Del/Backspace/Space/Enter/Esc/A..G), 值 = 引擎键码 {43, 80, 79, 82, 81, 75, 78, 74, 77, 73, 76, 42, 44, 40, 41, 88, 4, 6, 25, 27, 28, 29} (仅映射 22 键, 其余键位 0) |
| ⑤ | sub_1421FD2E0(0) 平台后端初始化 → GetActiveWindow() → sub_142206740(hwnd) 窗口后端检查; 失败 → cpp:132 "Success && \"Could initialize the window backend!\"" 断言 (latch byte_14344A598) |
| ⑥ | 渲染后端两态 (探针返 0 / 1 分派): 0 → sub_142205B30(文件名 (qword_143453090+128)); 1 → sub_142204BB0(sub_140AD9970(*(qword_143453090+128)), sub_1401AD6E0(...)); 失败 → cpp:173 "Success && \"Could not initialize the rendering backend!\"" 断言 (latch byte_14344A599) |

qword_143453090 = 纹理/GFX 管理器单例 (§4.00.25 纹理管理器 / §4.4 +368 注册表查询缓存一致), **+128 = 图形设备/后端描述** 供 ImGui 渲染后端挂接。未决: KeyMap 22 常量的引擎键码语义 (仅推定) / v2 是否确为 ImGuiIO (KeyMap@+52 与仅 22 键映射对现代 ImGui 版本偏少, 需核 imgui.h 版本) / qword_143451C80 身份冲突见 §4.26 待裁注。


#### 4.00.34a imgui 事件图作用域构造器 (event_graph_imgui.cpp; 1 函 = 0x141B00F10)

`sub_141B00F10(a1 = 待构造作用域, a2 = 选区对象, a3)`: sub_1422333C0/sub_142233450 取根序号 → **sub_140534FE0(a1, 根序号)** = §4.00 已收「CVariables/CScope 第二构造变体」（默认根 + 全槽哨兵 + +16 RNG 种子 1587985054）→ CInGameIdler（qword_14332F698）**vt[20]（+160）** 取当前上下文 id；三分支：① sub_140A0DF00(sub_140A0D4A0(), a2) 命中（当前选中）→ sub_14053B5F0 = §4.00 **SetState**（u32 直写 +168）；② a2+1053「角色作用域」旗 → 断言闩告警 :44 "Character scope not supported yet"（不设作用域）；③ 否则 sub_14053A610 = §4.00 **SetCountry**（写 +8，clear=1 先全清）。三个 sub_14053xxx 均为 §4.00 已定案 scope setter，直接互证。〈高置信〉
#### 4.00.35 计时单例 (timing.cpp; 5 函 = 初始化器 0x140221770 / 作用域对 0x1402200E0 与 0x1402203F0 / getter 0x140220E30 与 0x1402227D0 — §4.2.5 机制本体)

**计时单例 = qword_14332F498 (BASE+0x32F498), 464B 独立堆对象** (初始化器 malloc 0x1D0 直证; getter 返回它, 4 处调用点同证 — §4.2.5 备注)。全布局:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | uint64 | tick 计数器 (ctor sub_1401F7F80 初始化; 秒窗滚动基准) |
| +8 | uint64 | 上一采样窗 tick (sub_140222530 判 `now − +8 ≤ 1000000000` 同窗) |
| +16 | CPdxArray | 日期标记数组 (32B 元 CGameDate; sub_140222530 经 sub_14021EC40 推入) |
| +40 | CPdxArray | Daily 段序列 (sub_140220EA0 推日期) |
| +64 | CPdxArray | Weekly 段序列 (sub_1402210A0) |
| +88 | CPdxArray | Monthly 段序列 (sub_140221060) |
| +112 | CPdxArray | 第四段序列 (sub_1402210E0; 语义未决) |
| +136 | CPdxArray | 总账样本数组 (120B 元 = +216..+336 整窗快照; {data@136, cap@144, count@148, alloc@152}) |
| +160 | CPdxArray | 每秒缓冲 A (双缓冲之一, 窗口翻转时交换; 推定) |
| +184 | CPdxArray | 每秒缓冲 B (同上; 推定) |
| +208 | uint32 | 上一窗样本计数 (sub_140222530 滚动时落值) |
| +216..+320 | uint64 ×14 | **计时域耗时累加器** (域 id 索引; sub_1402203F0 写 `+216+8×id`; sub_140222CE0 每时清零) |
| +328 | uint64 | 残差累加器 (= 窗总耗 − Σ(+216..+320), sub_140222530 每窗重算) |
| +336 | uint64 | 窗口起始 tick (sub_140222CE0 清零时刷新; 窗总耗 = now − +336) |
| +344 | CPdxArray | 小时账数组 (sub_140220EE0 推入) |
| +356 | uint32 | 计数 (sub_140220F00 窗口翻转时清 0) |
| +368 | CPdxArray | 秒账数组 (sub_140220F00 推入) |
| +380 | uint32 | 计数 (同上清 0) |
| +392 | uint32 | 当前窗样本计数 (1e9 tick 阈滚动) |
| +396 | uint8 | **使能旗** (sub_140222860 读; 控制台 `gamestate_timer`/`gstimer` 或 `-gamestatetimer` 翻转) |
| +400 | CPdxArray | (sub_140220640 填充; 语义未决) |
| +424 | std::string | (sub_14011FC50 填充; ctor SSO cap=15; 推定输出文件名) |
| +456 | uint32 | (sub_140222870 的 v14; 未决) |
| +460 | uint8 | (sub_140222870 的 v15; 未决) |

> +216..+336 = 120B 整窗块 (15 qword = 14 域槽 + 残差), 与总账样本的 120B 元素一一对应。域 id (§4.2.5): 2=state.daily_parallel / 4=补给 / 7=天气 / 8=空军 / 9=海军 / 11=市场 / 12=突袭, 全部 < 14 与 14 域槽上界一致。作用域对 = 16B 栈对象 `{int 域id@+0, uint64 起始tick@+8}` (+4 填充)。断言闩三枚 = byte_14332F4A8 (:36 收尾侧) / byte_14332F4A9 (:45 开启侧) / byte_14332F4AA (:58 双重初始化 "Trying to initialize timing twice"), 均 report-once 形。**sub_14011DF40 = CPdxArray 默认 ctor (定案)**: 三写 `{0, 0, &off_143085170}` = data=0 / {cap,count}=0 / alloc = §3.2a 全局纯堆单例。单例关停 = sub_1426F7EC0 (非空 → sub_140220B10 释放)。**ctor 初始化序 (0x140221770 直证)**: +8 ← +0 拷贝 → +16 子对象 (sub_140220180) → +336 = 0 → +344/+368 两 CPdxArray (sub_14011DF40) → +392 dword = 0 → +400 CPdxArray → +424 std::string SSO (cap 15 / +456 dword=0 / +460 byte=0) → 收尾 sub_140222870; 双重初始化时旧单例经 sub_140220B10 释放替换。

#### 4.00.36 PDX SDK 上下文与 UTF-8→UTF-16 转换族 (contextowner.cpp 1 函 = sub_142225C00 / system_utils.cpp 2 函 = 0x1424FA370 + 0x1426F6380 — 书未收簇)

**PDX SDK 上下文初始化 sub_142225C00(a1 = 宿主, a2 = 游戏名串, a3 = 版本串)** (定案): 门 = `*(a1+80)` 非空 → Important 断言 contextowner.cpp:344 "PdxSdk is not null - creating a new one will cause a memory leak and other issues." (闩 byte_1434521B8)。构造栈上 `PDX::SDK::Config`, 逐项 SetEnvironment(3) / SetGameName(a2) / SetGameVersion(a3) / SetLanguage(36) / SetNumberOfClients(10) / SetEcosystem(8)。Steam 分支 (门 sub_1424BA300): AppId 串 (sub_1424CA660) → SetSteamAppId; 玩家 id = SteamInternal_ContextInit(&off_1430871B0) → 槽+16 虚调 → sub_1424CB370 转串 → SetGamingNetworkPlayerId; 网络名恒 "steam"。设置系统 qword_1435E3EC0 读两键: **"pdx-launcher-session-token"** (串) → SetSessionToken / **"gdpr-compliant"** (布) → SetSkipLegalDocumentsFlow。目录 = PHYSFS_getWriteDir() + "%s/logs" → SetLogFileDirectory / "%s/account" → SetCacheFileDirectory。`malloc(8)` → `PDX::SDK::Api::Api` → **`*(a1+80) = api` (宿主 +80 = `PDX::SDK::Api* _PdxSdk`)**; 尾调 Api::Startup → Future\<LoginResult\> (出参 8B)。

> 宿主类名未决 (无 RTTI 串直证; 调用点 = 游戏启动主链, a2="hoi4", 同链另有 sub_142225910 / sub_142226150 → 推定 CMapApplication 成员)。Config 枚举原始值 (Environment=3 / Language=36 / NumberOfClients=10 / Ecosystem=8) 的 PDX SDK 含义未决。

**UTF-8 → UTF-16 转换主函数 sub_1424FA370** (188 行, 定案; 出参 a1 = std::u16string, 输入 a2 = 源串): 出参 SSO 初始化直写 **内联 cap = 7** (§3.5 第三变体)。转换器 vtable 符号直证 = `std::wstring_convert<std::codecvt_utf8_utf16<wchar_t,1114111,0>, wchar_t, ...>` (标准 locale facet, 最大码点 1114111 = 0x10FFFF)。回写堆形态判据 `*(a1+24) > 7`; 释放走 MSVC 标准串路径 (size+1 ≥ 0x1000 时解 `*(ptr-8)` 偏移块)。**容错**: 捕 std::range_error (非法 UTF-8 序列) → 错误上报 system_utils.cpp:228 (旗 4096) + 拼接 "Failed to convert " + 源串 + " from utf8 to utf16." → 清 ios_base 状态后**重试转换** (EH 状态机回 try 边), 不向外抛。

**错误处理分支 sub_1426F6380** (27 行) 揭示的转换器状态对象布局 (≥544B, 推定): +48 u32 位域错误旗 (`|= 4` = 转换失败位) / +256 错误上报上下文 / +416 std::ios_base 子对象 (vtable = `std::ios_base::vftable`) / +536 char* 源串指针。

#### 4.00.37 CRomeBitmap 装载链 (rome_bitmap.cpp; 2 函 = 高层 0x141546070 / 底层 vtable[3] = 0x1415461F0)

**CRomeBitmap 布局** (与 §4.00 CBitmap 布局逐字段吻合, 定案; ctor 0x141545FD0 直写 `*a1 = &CRomeBitmap::vftable`):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | CRomeBitmap::vftable (0x1429D61E8) |
| +8 | uint32 | 宽 (biWidth; 底层装载器写) |
| +12 | uint32 | 高 (biHeight) |
| +16 | uint32 | 每像素字节数 (1 位→1 / 8→1 / 16→2 / 24→3) |
| +20 | uint32 | 位深 (白名单 {1, 8, 16, 24}) |
| +24 | uint32 | **biClrUsed 直拷** (底层装载器写; ⚠ 覆盖 CBitmap ctor 的派生色数) |
| +28 | uint32 | 行距/目标步进 (width×bpp **未 4 对齐**; 1 位 → width>>3) |
| +32 | uint32 | 精确 BMP 行宽 ((width×bpp+3)&~3; 1 位 → >>3) |
| +40 | 指针 | 像素缓冲 (malloc = height×+28 + 7) |

**高层 0x141546070** (95 行, 定案): 共享头部读取器 sub_1422E48E0 (读 14B 文件头校验 `v8[0]==19778` ("BM"), 不符 → seek(0) 静默回卷返 0 不抛; 读 40B INFOHEADER; **biSizeImage==0 时补算 = biHeight × 行宽**; 尾 seek(0) 回卷) → 位深白名单 = 位掩码 **65794 = 0x10102** (bit1/bit8/bit16 置位) + 显式 ==24; 非法位深 → rome_bitmap.cpp:24 (旗 4096) "We do not support bitdepth at <n>" 返 0 → 分配缓冲 → 虚调槽[3] (`(*(a1+24))(a1, src, buf, -1, 0)`)。

**底层 0x1415461F0** (164 行, 定案): 再读 14B 头 (非 "BM" → :72 "Attempting to load an illegal bitmap-type with a corrupt header.") → 读 40B INFOHEADER → 压缩白名单 {0=RGB, 1=RLE8} (其他返 0) → 位深白名单 {1,8,16,24} (`((bitcount-8)&0xFFF7)!=0 && !=24` → :92 "Attempting to load an unsupported bitmap-type") → 写布局字段 → **非 24 位时 seek(bfOffBits) 跳调色板** (24 位数据紧随 INFOHEADER) → 逐行 read(dest, +32) 拷 height 行。

> **行拷贝怪癖 (新发现, 定案)**: 每行读 **+32 (4 对齐行宽)** 字节, 目标指针步进 **+28 (未对齐行距)** → 每行末 ≤3 字节 padding 溢进下一行起始 (被下一行读覆盖), 末行溢出由 malloc 的 **+7 松弛**吸收。复刻布局须照此分配, 勿假设目标行 4 对齐。RLE8 (压缩==1) 路径**跳过逐行拷贝循环** (本层不解码 RLE8 行, 是否有外层解码待裁)。CBitmap 族 vtable[3] = 底层装载槽契约 (基槽 0x1422E4990) 在 CRomeBitmap 成立 (槽[3] = 0x1415461F0) — 定案。

#### 4.00.38 环境战斗音区域与单位语音播报 (ambientbattlesound.cpp 1 函 = sub_140671F50 / voiceover.cpp 1 函 = sub_141969B00 — 书未收簇)

**环境战斗音区域对象** (类名未决; sub_140671F50 由成员位置列表算中心+半径, 定案): +0 f32 中心 X (输出) / +4 f32 中心 Y (输出) / +8 f32 半径 (输出) / +16 CPdxArray 成员数组 {data@16, cap@24, count@28, alloc@32}。count = *(int*)(a1+28), Important 断言 "nSize > 0" (ambientbattlesound.cpp:311, 闩 byte_143330550)。位置链 = `成员+184 → S*; S+184 = int x; S+188 = int y` (int 直转 float, 推定地图像素坐标; E/S 类名未决)。算法: 遍历算 min/max 包围盒 → 四边各外扩 **BATTLE_SOUND_INIT_RADIUS** (define, dword_143334600) → 中心 = (max+min)/2, **半径 = sqrt((dx²+dy²)×0.25) = 半对角线**。同族查询形 sub_140671770: 入参 {f32 x, y, radius} → 外扩 BATTLE_SOUND_INIT_RADIUS 得 24B 查询矩形 (与区域对象配套的空间查询)。

**单位语音播报触发器 sub_141969B00(a1 = 状态枚举, a2 = 国家 tag 串)** (定案; 调用点 = 单位选中音效族 "select_general"/"select_tank"/"select_vehicle"/"select_army" 之后):

| 全局 | 类型 | 语义 |
|---|---|---|
| dword_143334898 | float | define **VOICE_OVER_COOLDOWN** (冷却秒) |
| qword_14338B3D8 | double | 上次播报时刻 (magic-static 初始化 = −(float)VOICE_OVER_COOLDOWN) |
| dword_14338B3D0 | uint32 | 上次播报的声音 id (正在播放门) |
| dword_1430B4258 | float | 监听器字段缓存 (变化检测) |
| byte_14338B3E4 | uint8 | 断言闩 (voiceover.cpp:30) |

> 双门: 冷却 `VOICE_OVER_COOLDOWN + qword_14338B3D8 > now` → 跳过; 正在播放 `sub_1423B7F00(handler, &dword_14338B3D0)` → 跳过。音效处理器 = `*(单例+144)` (单例经 sub_14222BDB0), 空 → Important 断言 voiceover.cpp:30 "sound effect handler SHOULD be available here" → 跳过。**状态枚举 a1** = 0=Idl / 1=Neu / 2=Pos / 3=Ret / 4=Mov (字面量 aTagInfantryIdl/Neu/Pos/Ret/Mov), 越界跳过。标签 = a2 串前 3 字节 (国家 tag) 覆盖缓冲的 "Tag" 占位 → **"\<TAG\>Infantry\<State\>"** (命名约定推定, 待运行时确认)。声音事件查表 `sub_1423B7110(**(单例+856), tag, 0)`。监听器变化检测: `dword_1430B4258 != *(float*)(监听器对象+212)` → 更新缓存 + 重设参数 (sub_1423B5AE0/sub_1423B5B40)。播放 sub_1423B7F30 → 声 id → 回写时刻+id。

#### 4.00.39 触点活动表 (clausewitzlib/input_touch.cpp; 2 函 = 事件分派 0x1423840B0 / GetTouch 0x142383F80 — 书未收簇)

**容器布局** (a1, 定案): +8 元素指针 / +16 u32 容量 / +20 u32 计数 / +24 分配器对象 (vtable[1] alloc / [2] free, ×1.5 增长 + 下限钳)。**元素 20B** = {id u32@+0, cur 位置 8B@+4, prev 位置 8B@+12, pad u32@+16}; 事件入参 = {id u32@+0, 类型 u32@+4, 位置 8B@+8}。

**事件分派 (0x1423840B0)**: case 0 按下 = 满容扩容后保序追加 {id, 位置@+4, +12/+16 清零} / case 1 抬起 = 按 id 线性查找后保序移除 (memcpy 左移全部后继), 未找到 → input_touch.cpp:53 "Touch not found" 断言 / case 2 移动 = 按 id 查找后 `elem+12 ← elem+4` (旧 cur 滚入 prev) → `elem+4 ← 新位置`, 未找到 → :68 同串断言。**GetTouch (0x142383F80)**: 越界 → :16 "Invalid touch index" 断言 + 出参写 {id=0xFFFFFFFF, 0, 0} (id=−1 哨兵); 有效 → 20B 整拷。

> 纯容器层 — 不含坐标变换与手势分派 (手势逻辑在本文件其余函数或事件泵消费侧, 语料不可见); prev 位置槽 = 移动事件提供的两帧位移原料 (消费方未决)。两函语料内零 xref (间接引用); 与 ImGuiIO 喂入轨 (qword_143451C80, §4.00.22) 零耦合 — 触点活动表是独立对象。

#### 4.00.40 校验/编码/版本杂件三卡 (simplechecksum.cpp + CyoEncode/CyoDecode.cpp + version_number.cpp + blob.cpp — 书未收簇; 12 函零真加密负定案)

**simplechecksum.cpp 三函 (校验和壳管线, 推定/定案)**: 主函 0x1414E5F70 (195 行) = 「计算→写回→回验」壳: RAII 进入 → 虚槽[3] (vt+24) 守卫调 (a1+16 旗, 0) → sub_1414E58A0 算校验和出串 → 虚槽[3] (旗, 2) 恢复 → sub_1424C44F0 写回 → **虚槽[9] (vt+72) 返 char = 验证结果** (多态实现承担「校验」, 本函无查表/轮数/盐/多项式等加密原语); 两次 CFileException catch → 一次性旗 byte_14338A75A (:72) / byte_14338A75B (:98)。伴生 thunk 对 0x142640E30/0x142640ED0 (各 28 行, 恒返 0): 断言总门 byte_1435E1B51 + 对应旗 → 对象 vt[1] 取错误串 (空则不发) → "simplechecksum.cpp" :98 / :72 断言 — 与主函 catch 路径旗/行号一一对应。

**CyoEncode/CyoDecode = 标准 RFC 4648 base64 (定案, 无魔改; 公开域库)**: 编码 0x142509750 (块 3→4; 字母表 @0x142B956E0 = `A-Za-z0-9+/=`, pad '=' 索引 64; 位重排标准式; 余 1 字节 → 2 pad / 余 2 → 1 pad; 入参空 → throw std::runtime_error("Invalid parameter"))。解码 0x142509440 (块 4→3; 反查表 byte_1430C75B0[128]: '+'→62 '/'→63 '0'-'9'→52-61 'A'-'Z'→0-25 'a'-'z'→26-51 '='→64 其余 0xFF; 输出计数按 pad 递减; 长度 %4 ≠ 0 → throw "Invalid source, size is not a multiple of 4"; wassert in1..in4 ≤ 0x7F / ≠ 0xFF / ≤63 — in3/in4 容忍 64 = pad)。返回值 = 输出总字节数。⚠ 文件名「Cyo」与本簇「cryptology」命名均有迷惑性 — 本批 12 函无一涉及真加密。

**version_number 格式化 0x142222CE0 (216 行, 高置信)**: 版本对象 → 串 "a.b.c.d": 分量数 @a1+76 合法域 [2,4] (非法 → version_number.cpp:89 "Invalid version number" 断言 + 返 "???"); 循环 4 次: i ≥ 分量数 → "*" 占位, 否则分量 int→串; i < 3 插 "." 分隔。a4 分支追加 "." + 常量串 (语义待裁 — xmmword_1427179B0 原始字节 {1, 0xF} 读作 1 字节 0x01 串疑 IDA 隐参/邻接常量误拼); a3 分支隐参丢失待裁。本函只做格式化, 无比较/解析逻辑。

**blob.cpp = CPdxArray\<int8\>::SubArray (0x1424D62F0, 147 行, 定案)**: 容器布局 {data@+0, size u32@+12}; 断言 blob.cpp:25 "( CPdxArray<int8>::SizeTAlias ) nPos1 < _Data.GetSize() && nPos2 >= nPos1"; 取区间 [nPos1, nPos2), **nPos2 > size 时静默钳到 [nPos1, size)** 不报错; 产出经栈临时 (off_143085170) + 移动赋值进 out (1.5× 增长 + memcpy, 分配器 vt[+8]/[+16])。

**ConvertUTF 0x1424FE880 补强** (§4.00.28 互证全量吻合): 内层状态机 = sub_1424FED00(&pSrc, Src+len, &pDest, pDest+4×count, **0**) — 末实参 = 转换 flags (严格模式), 返非 0 = 失败; 失败 → 输入复制进栈 std::string 后走 ConvertUTF.cpp:741 日志 (类别 4096) 返 0; 成功 → 出长 `*a5 = (pDest 终 − a3) >> 2` (UTF-32 码点数) 返 1; 哨兵 = 目标 a3+4×a4 (码点粒度) / 源 Src+a2 (字节粒度)。

#### 4.00.41 pdx_scoped_buffer 线程本地 scratch 句柄 (pdx_scoped_buffer.cpp; 1 函 = sub_1424E40D0, 定案)

#### 4.00.42 标准网格盒布局提交/回收通道 (standardgridbox.cpp; 1 函 = sub_1422C7170, 高置信/描述结构未决)

#### 4.00.43 CChecksumFile 打开模式分派 (checksumfile.cpp; 1 函 = sub_1424FBAA0, 定案/模式名推定)

sub_1424FBAA0: a3 == 0 → :23 B51「OPEN_READ is not allowed, assuming OPEN_WRITE.」+ `(*(a1+96))(a1)` (vtable+96 = Close) + sub_1424F11A0(a1, 名, **1**); a3 == 1 → Close + sub_1424F11A0(a1, a2, **1**); a3 == 2 → sub_1424F11A0(a1, a2, **2**) (不关文件); a3 ≥ 3 → :33 B51「Invalid enum」(闩 byte_1435E40A2 / byte_1435E40A3)。模式 = **0 = 只读 (降级为写) / 1 = 写 / 2 = 追加** (1/2 语义名推定); a2 = 文件名/路径。

#### 4.00.44 浏览器文本输入转发 (browserui.cpp; 1 函 = sub_1422CEFB0, 定案/解码器语义推定)

#### 4.00.45 静态 ID 哈希表尺寸统计 (id.cpp; 1 函 = sub_14221FC40, 定案)

#### 4.00.46 TLSF 型分配器空闲块合并插入 (1 函 = sub_142100780 + 区分配器 sub_142100F10, 机制定案/真名未决)

#### 4.00.47 CPdxRobinHoodTable 文本落盘 writer (1 函 = 0x1414DB8A0, 定案/token 名待裁)

0x1414DB8A0 (a1, writer ctx a2, 表 a3) — `<string,dword>` RH 表排序确定化文本输出: 遍历上界 = `data + ((_Size+extra+1) << 6)` (桶 64B, 末槽 0xFF 哨兵; :58 腐坏 tripwire 闩 **byte_14338A73A**)。**收集** = 全部非空桶 → 40B/条 {键串 32B @+0, dword @+32 ← 桶+40} (1.5x 增长); **排序确定化** = 主键 dword 值域, 同值次键键串 (n ≤ 32 插入排序 sub_1414DD330 / n > 32 sub_1414DDC00, 栈阈值 102) — 同值条目落盘按键名字典序稳定 (对拍友好)。**写出** = 逐条按键反查活表 (sub_1414DB460, iter == end 跳过 = **只写仍存活的键**); 块名惰性 sub_1424BC260(16) + sub_1424BFF20; 逐条 = 写键 → 旗空写 token 18 分隔 → 写值 (iter+48) → 收条目; 尾关块。token 16/18 名未决 (离线表无此两 id, 需游戏内 token_name)。

sub_142100780 (heap, block, next_block, size) → 返 block+16 载荷址 — 空闲块 forward-coalesce 插入器: next 头 bit1 = 0 (空闲) → 先摘后继 (小类双向链 + 位图清位 / 大类树摘除: 父+24/子+32/+40/同值链+48/类字节+56) 再并区间; bit1 = 1 (分配) → 直接登记。**heap 头**: +0 u32 小类位图 (<0x20) / +4 u32 大类位图 / +8/+16 边界块指针 (合并对象为边界块时直改 size) / +24 最低有效指针基线 (低于基线视为空跳写, 空页保护) / +64 小类链头 16B×28 / +592 大类树根 8B×64。TLSF 两级槽位: size/8 ≥ 0x20 → SL = size>>8, fl = floor(log2) (位减法链), slot = 2fl+bit ∈ [0,63]; 同值块挂 +16 链。块头 = `size|3` (bit0|bit1 = 分配态), 空闲头 = `merged|1` + 页脚。**调用方 0x142100F10** = VirtualAlloc 区分配器: 区链 heap+872 {start@0, size@8, next@16, flags@24}, +848/+856 合计/峰值, 相邻区合并走本函; 全局配置 qword_143450DC8..DE8。所属分配器真名未决。

sub_14221FC40: 双 B52 断言 — `_pStaticIdHashTable` (qword_143451DB8) 非空 (:620, 闩 byte_14345214C) ∧ `_CleanStaticSize == −1` (:625, 闩 byte_14345214D, 判 dword_1430BDDB0 ≠ −1); 累加 = 表头 count (qword_143451DB8+16) + 遍历 bucket 指针数组 qword_143451DC0…dword_1434520E0 (8B 步) 逐项 `+= *(int*)(bucket+16)`, 结果写 dword_1430BDDB0 = _CleanStaticSize。

sub_1422CEFB0 (CEF 文本输入): a1+32 = 浏览器实例, 空 → :115 B51「Browser forgot to unregister itself for text input」(闩 byte_14348119C) 返 0; 入参 a2 = MSVC 32B 串 (size@+16 为界, cap@+24 > 0xF 取间接) → `sub_1424FEA80(&cur, end, &out16, out12, 0)` **逐码点解码** (返 3 = 终止) → 每个 **UTF-16 码元** 经 sub_141AC9990(browser, cp, 3, 修饰键状态) 送入浏览器字符回调 (修饰键 = sub_1422CEBC())。sub_1424FEA80 推定 = UTF-8→UTF-16 解码器 (§4.00.28 CStringTokenizer 同族拆码链)。

sub_1422C7170: 门 = a1+16 = **_pWindow** (:120 断言, 闩 byte_143481177); a2+56 = 临时接口对象 v5; 有窗且有接口 → `(**v5)(v5, &v7)` (**vtable[0] 产 56B 栈描述 v7**, 返计数/尺寸) → sub_1422C3C20(_pWindow, v7) 应用布局; 尾 `(*(v5+32))(v5, v5 != a2)` (**vtable+32 回收**, bool 实参 = 「对象非容器自身」) + `*(a2+56) = 0` 清槽。与 §4.00.6 CGridBox 运行时布局五原语同族 (本函为子件布局提交/回收通道)。56B 描述结构 / sub_1422C3C20 应用语义 / vt+32 回收签名未决。

sub_1424E40D0 (句柄构造器; §3.2a acquire/release 协议的线程本地实现): 句柄 = {&TLS 槽@+0 (TLS+2120 = 缓冲基址 ptr), i32 位置快照@+8}; TLS+2136 bit0 惰性初始化门 → malloc(dword_1435E3ECC) → TLS+2120 (同时 TLS+2128 = 0); 双断言 — :10 dword_1435E3ECC > 0 (闩 byte_1435E3ED0) / :11 TLS+2120 非 0 (闩 byte_1435E3ED1); _tlregdtor(qword_142705E00)。

#### 4.00.48 Huffman+RLE u16 数组块解码家族 (5 例同构 + 三件套 0x142493AF0/32F0/3440, 高置信/子系统归属待裁)

#### 4.00.49 平台层多按钮消息框簇 (分发 sub_1420EE500 → TaskDialog 路 sub_14212E8A0 → 自绘回退 0x14212ED80; DialogFunc 实名 = 0x14212E6C0, 定案)

**分发 sub_1420EE500**: 平台系统 qword_143450BC8 +648 虚槽 = 自定义消息框钩子 (无 → 「Video subsystem has not been initialized」); 钩子缺失或窗口域拒绝 (码 20) → TaskDialog 路。**TaskDialog 路 sub_14212E8A0**: LoadLibraryW(comctl32) + TaskDialogIndirect (TASKDIALOGCONFIG 栈构 cbSize=160, flags = TDF_POSITION_RELATIVE_TO_WINDOW, 图标 MB_ICON 位映射 0xFFFE/0xFFFF/0xFFFD, 按钮 12B/个 {id = 100+i, text}); HRESULT 失败 → 自绘回退。**自绘回退 0x14212ED80**: 按钮上限 **65435** (控件 id 16 位界); 图标资源序数 32513/32515/32516; 平均字宽 = MS 文档公式 `(cx/52+1)/2` (编译器折叠 ×1321528399 = 2^35/13, PE 验算 ✓); 内存 DLGTEMPLATE 构建 (sub_14212E080 = 模板分配器, **sub_14212DB10 = DLGITEMTEMPLATE 追加器**: class 序数 128 = Button / 130 = Static; 样式 0x50020003 图标 / 0x50022080 正文 / 0x50010000 按钮, 默认按钮 |= 0x20000|0x1; 按钮文本 '&'→'&&' 转义) → DialogBoxIndirectParamW。**返回协议**: <100 = 错误码 {0 句柄无效 / −1 错误 / 50..52 指针无效 / 53 默认按钮缺失}; 20 = 取消 (出参 −1); 100+i = 按钮 ret 值 (按钮条目 16B {flags@0, ret@+4, text@+8})。

家族主例 0x142492510 (decoder, → char 1 = 块已解/0 = 失败或完成) + 同构 4 例 (语料 L1387943/L2625360/L5284315/L5287431), 共用三件套。**decoder 布局**: +0 错误沉没接口 (vt[1] = 报错回调; +40 = i32 错误码) / +40 24B 位读状态 / +348 每块子块数 / +416 清零表长 / +508/+512 索引区间 [begin,end) / +520 位宽 w / +528 索引数组指针 / +540 流中断标记 (0 = 无) / +584 源游标 (vt[2] = 取下一压缩块, +32 已消费偏移) / +592 流态 (+24/+28 位累加器与计数 / +32 剩余子块数 / +36 清零表 / +52 终止闩 / +56 pending / +96 Huffman 表*)。**Huffman 表**: +152 = 256×u32 快表码长 / +1176 = 256×u8 打包符号 {高 nibble = 附加位位数 (15 = 特殊长游程), 低 nibble = 载荷类 (0 = 游程, 1 = 单步 ±, 他 = 非法 → **错误 121**)} / 慢径 counts/offsets 树, 最大码长 16。**解码**: 逐索引取目标 u16; 快表 8 位 MSB-first 命中 → 消 n 位; 低 nibble = 1 → 读 1 位选 δ = ±(1<<w) 对 u16 做**模 2^w 回绕加减**; = 0 → 游程 (长 = (1<<n)+读 n 位; n = 15 → 余量非零者全施 δ)。**事务回滚** = 施 δ 前压索引入回滚表, 任一步失败逐个清 0 (逐调用原子)。**位读器 sub_1424932F0**: 字节泵 vt[3], 25 位水位; **0xFF 转义** = 连续 0xFF 后尾字节 NN (0 → 补字面 0xFF; ≠0 → 写 decoder+540 中断标记, 位欠数 → **错误 120** + stream+52 置 1)。**块推进 sub_142493AF0**: cursor+32 += bitcnt/8 → 取下一块 → 清表/stream+32 = 0/pending = +348; 仅当中断标记 == 0 才清 +52 闩。子系统归属待裁 (回绕 u16 + 事务 + 块流形态与图像/动画帧域吻合, 推定)。**族增补 = 0x142493BA0「新块事务准备」态 (高置信)**: 清零表本体 +176 / 清零段条目数组 +424 / 错误码 17/118/125 / 流态 +8 形态回调槽 / +516/+520/+297/+536 语义增量; 状态机链 sub_142476CA0 → sub_142476FF0 → sub_1424931B0, 清零执行器 = sub_142493560; 权重三角表族 7 件 (值/填充模式需数据段)。

#### 4.00.50 变量注册表引用条目解出重建 (1 函 = 0x141817660, 机制定案/宿主类待裁)

0x141817660 (host a1; caller = thunk sub_141817BB0(a1+176)); 单例门 qword_14332F6A0 非空 (与 qword_14332F698 同值双槽, 安装器 = sub_1402A2A30 两槽同写)。**机制**: 枚举原语 sub_140DC7320(reg, &keys, &objs) 遍历 sub_140BC30C0(reg+1336) 链表 (条目 +16 = next), 按 *(值+8) **类型码分派** — 码 1 → 值本体入 objs / 码 11 → `值−24` 入 keys (**−24 outer 回退型**, 新形态, 对照 §3.2b −16 型); keys 逐元 sub_1417FE670 变换 → sub_141804D30 消费; objs 逐元解出 = 槽值默认哨兵 qword_14333D528 (CRef 默认构造) → 非空取 *(obj+24) → sub_14221F310 解析 → 失败走 **ref.h:83 GetPtr 断言** (flags=1, once-guard byte_14332F70D); 解出数组 → sub_14134AC80(a1+24) 挂载。

#### 4.00.51 TGameItemDatabase<T>::Reload 模板共享体 (四实例 = 0x1401971D0 / 0x14019DA00 / 0x141B5B610 / 0x140197890, 定案)

**Reload(db, bool quiet)** 三实例逐字节同构 (T = CAIStrategyPlanDatabase qword_14332EE10 / CHistoricalAgencyDatabase qword_14332EDB8 / CStrategicRegionDatabase qword_14332F080 / 第四实例闩 byte_14332F0F4 + LoadOne sub_140613F10 + boot 编排者 sub_140195760; 差异仅闩字节 / T 专属 pre-hook / LoadOne 三面; **第 5 实例 = 0x14019E0C0 (CIdeaDatabase idea 库, 闩 byte_14332F167, pre-hook sub_140A41B00 语义未决, LoadOne = 共享装载体 sub_140A43130 = §4.10:1806 点名件))**; quiet = 1 = 跳过头行与空态报告 (**有错仍报**)。**第 6 实例 = 0x1401A1EB0 (CScriptedDiplomaticActionTemplateDatabase, 单例 qword_14332F048; 闩 byte_14332F1B7 / 无 pre-hook (仅 magic-static dword_14332ECF0 守卫) / LoadOne = sub_140AB2F20 = ".txt" 枚举装载; creator sub_140173660 (:127 闩 byte_14332F1B5) / ctor sub_140AB0EF0 (RTTI 双表) / getter sub_140163930 (:149 闩 byte_14332F1B6) / boot 编排者 sub_140195BB0; def 目录 = common/scripted_diplomatic_actions, LoadDatabases sub_14018BB20 步 96; 步 95 = resistance_activity 三件套 sub_1401733E0/sub_140163730/sub_14018A950 同构推定)**。**第 7 实例 = 0x1401A2A10 (CScriptedMapModeDatabase, 单例 qword_14332F040, getter sub_140163A30 闩 byte_14332F1B3; 闩 byte_14332F1B4 / pre-hook = B 型 _Paths 头清空 + off_143085170 vtable+16 释放 (off_143085170 = **共享静态分配器对象定案**, vtable+8 分配 / +16 释放; bookmark ctor sub_14067C250 +24/+56 两处嵌入直证) / LoadOne = sub_140AAF740 (boot 共享装载器, 按 def+232 串匹配) / boot 编排者 sub_140195C50)**。**第 8 = 0x140197F50 (CAgencyUpgradeDatabase, 单例 qword_14332EDC0, Get 链 sub_1401957B0→sub_1401619B0; 闩 byte_14332F0FC, pre-hook sub_1406234C0 = B 型原地清空, LoadOne sub_1406243A0)** / **第 9 = 0x14019F940 (COccupationModifierDatabase, 单例 qword_14332EF90, Get sub_140162F30; 闩 byte_14332F183, pre-hook sub_140A70820 = A 型 gs :1126 访问器, LoadOne sub_140A70FC0)** / **第 10 = 0x1402DA2B0 (CBookmarkDatabase, 单例 qword_14332EE20 新录, 库 ctor sub_14067C250 RTTI 直证; 闩 byte_14332F74C, pre-hook sub_14067D0A0 型别待裁, LoadOne sub_14067D4F0; 简化 reload 入口 sub_1402D7570 零静态调用点 = 函数指针注册消费)**。**Load 孪生 sub_14018AE40** (:160 "DB already loaded when loading " 重载警告): _Paths = {名} 单路径 + LoadOne + **仅 vtable+16/+32 两钩** (无 +24、无深度计数、无误差记账) — 与 Reload 三钩形态的差异面。**执行序**: 日志上下文 vtable[+24](4096) 计数基线 → :281 `!_Paths.IsEmpty() && "Cant reload when not loaded"` B52 断言 (判据 = db+20; 闩 A byte_14332F116 / B byte_14332F0F9 / C byte_14338C190) → _Paths 快照 (sub_140186170 = §4.29 dlc_load 合并件新消费点) → **T 专属 pre-hook** (A = gamestate 钩子: :1126 `_ThreadForbidCount == 0` B52 闩 byte_14332ED01 + gs+2617 门 / B = _Paths 头清空 / C 待裁) → move 回填 + `++db+32` (reload 深度计数) → 逐路径 :303「Reloading Database: <路径>」头行 + **LoadOne** (A/B = sub_140648730/140621C50 = ".txt" 枚举装载, C 待裁) → `--db+32` → **主虚表 [2]/[3]/[4] 三连装载后钩** (语义待裁) → 误差记账 (终值行计数 − 基线 − 已知头行 = 错误行数; verbose: :331 "no errors." / :324 "<N> errors." / :336 分隔线) → 尾 sub_140612D60(行数) = idler qword_14332F698 vtable+184 取对象 → sub_140B645C0 行数上报 (推定加载屏/日志窗)。**boot 编排者** sub_140195710/1958E0 (A/B) = pdx_bindable_loc_validator.cpp:16「second instance of a singleton」断言单例 (闩 byte_1435BA068) + Reload(0) + checksum 尾链 sub_140538B50。**库布局增补**: +8 = _Paths 24B pdx 向量 {data@+8 = &元素[0], count@+20} (库+8 直读串 = _Paths[0] 别名) / +32 = reload 深度计数; A 库主虚表 = 0x1427E1B18。

#### 4.00.52 CStateNudger 选州处理 (主 vtable 槽 [3] = 0x141B5A410, 高置信)

0x141B5A410 (nudger a1, GUI 消息 a2): 事件类型 sub_14139E9A0 **1 = 按下 / 2 = 释放** (释放且键号 ≠ 4 → 清 a1+797); 拾取链 = gs vtable+120 (槽 15) 取地图视图 → 事件对象前两 int 转鼠标 x/y → sub_140B53F00(view, &x, &y, 1, 0) → 州 id; 州对象 = gs+8 子对象 vt[1] → **有效性门 = *(state+184) 解引用 → +210 字节 & 3 非零** (字段语义待裁)。单选路 (a1+780==0 ∨ +796==0): sub_141B5D820 整表清 → 比较当前选区首元素与 *(state+192) → 相等仅 sub_141B5BD80 (高亮) / 不等加 sub_141B58680 (取消旧); 多选路 (+780 > 0 ∧ +796): gs+1288 对象 vt[5]/vt[7] 两查询 (推定修饰键) → 遍历 **a1+768/+780 第二列表** — shift 型 → 追加进选区数组 a1+16 (cap@+24, count@+28, 1.5× 增长, 分配器对象 a1+32 vt[1] alloc / vt[2] free) / ctrl 型 → 仅高亮 (BD80 族, 完整 VA 见 findings)。**CStateNudger 布局增补**: +8 gs/管理器指针 (+1288 选择/输入对象槽) / +192 命中测试缓存 / +768/+780 第二列表 / +796 多选模式旗 / +797 粘滞旗 (释放键≠4 清零)。尾事件消费 sub_142275B50。

#### 4.00.53 Unicode 简单大写映射表函数 (ConvertUTF.cpp 邻域; 1 函 = 0x1424FEF40, 语义定案/真名无锚)

0x1424FEF40 (`uint 码点 → uint 大写` 纯映射, 3,919 行全真码零内存访问零被调; 建议名 unicode_simple_toupper, 真名无锚): **1240 码点映射** (1222 case + 18 边界 else-if), 无映射恒等返回。**表冻结 ~Unicode 8.0** (含 Cherokee 小写 AB70 系 / Old Hungarian 10CC0 系, 无 Adlam/Osage/Mtavruli); delta 主峰 −32 (522 项 ASCII/Latin-1/希腊/西里尔/全角族), 非平凡映射抽验 (0x131 ı→I / 0x17F ſ→S / 0xFF ÿ→0x178 Ÿ / 0xB5 µ→0x39C Μ 等) 全与 UnicodeData 吻合。**同 TU 函数族** (地址连续): sub_1424FED00 = ConvertUTF 状态机 (§4.00.28) → 本函 → **sub_142502B10 = u32 串原位大写** (CStr32 布局 data@+0 / len u32@+16 / cap@+24, ≤3 码元内联 SSO)。**消费域**: 地图国名/区域名标签大写化 (countryname.cpp 0x141647360, §4.35) / 存档与版本字段名及 GUI 位置类型名不区分大小写匹配 (0x14231CBB0 锚 'name'/'version'/'tags' / 0x14138FAC0 锚 "pos_add_at_right_bottom") / sub_14226AF10 = UTF-8 原位折叠压缩循环 (write-cursor ≤ read-cursor)。⚠ 0x141387290 IDA 名 "fegetround" = **误名** (实为一行 toupper∘fold 包装, 与 CRT 无关); 伴生 sub_142270370 = tolower 型折叠 (语料无横幅, 推定)。

#### 4.00.54 0x14254 区 = 静态链接 UCRT (导航标注; 1 代表函 = 0x14254DE28 printf 格式分派核心, 定案)

**0x14254000 起区段 = 静态链接 UCRT 代码** (0x14254DE28 = `__crt_stdio_output::stream_output_adapter` 实名直证; 同区 sub_14254B47C/B88C/B06C = 整数十/十六/八进制写出 helper, unknown_libname_43x/44x = 无符号 CRT 原语)。**上界延伸 ≥0x142584xxx**: locale 初始化四件套 __acrt_locale_initialize_{ctype=0x142571860, monetary=0x142583A74, numeric=0x142583FFC, time=0x142584760} 实名族直证 (ctype 构建器 = __crt_locale_data 五连 calloc 384 项×3 表 + GetCPInfo 门 + CP65001 前导 0xC2..0xF4 特例; 表发布带 -128 偏置, 引用计数 +256)——反编译分析可**整区跳过**, 非游戏逻辑。printf 格式状态块布局 (实测): +8 locale\* / +32 chars_written (−1 = 错误) / +40 flags 位 (0x01 '+' / 0x02 空格 / 0x04 左对齐 / 0x08 零填充 / 0x10 有符号十进制 / 0x20 '#' / 0x40 负值) / +44 width / +48 precision / +56 无输出旗 / +57 format char / +64 串数据 / +72 串长 / +76 宽串旗 / +1120 输出流。

#### 4.00.55 0x14246 区 = libpng 静态链 (导航标注; 代表函 = png_do_rgb_to_gray 0x14246F540, 定案)

**0x14246 区 = vendored libpng 第三方带** (png_do_rgb_to_gray 直证: 调用者 0x14246EAE0 = **png_read_transform_row**, "png_do_rgb_to_gray found nongray pixel" 串直证) — 反编译分析可整区跳过, 非游戏逻辑。连带定案: png_struct 字段图 = 七 gamma 表族 @+720..+768 / rgb_to_gray_status@+1072; libpng 版本号待裁。
