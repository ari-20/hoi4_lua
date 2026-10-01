

### 4.00 基类契约层 (接口虚表 / 槽位语义)

> **本册定位**: 全书其余分册是「**实例级**」字段表 (某类在某偏移存什么)。
> 本册记「**基类级**」契约 (<u>虚表槽位语义</u> / 基子对象偏移 / 抽象性) —— 是
> 复用时「**先查基类定槽位，再只啃差异**」的索引层。每类新增时若其基类已在本册，
> 序列化/解析入口不再需要逐类反查。
>
> **解虚表通道**: RTTI COL 解虚表 (扫 .rdata 取
> `{sig=1, td_rva, self_rva}` 的 COL → 反查指向它的指针 → vtable = ptr+8) +
> 跨类槽位对照 + dump 直读 ctor 装表点。
>
> ⚠ **虚表读法前置**: `_purecall` (0X14253C3B8) = 纯虚/未实现槽;
> `_guard_check_icall_nop` (0X14012A2C0) = CFG 空桩 (含 ICF 折叠的等价空函数,
> 全 exe 12740 处引用) —— 二者都不携带语义, 读虚表时必须识别后再数槽。

#### 4.00.1 序列化基类 CPersistent (每类 Save/Load 入口)

CCountry / CState / CProvince / CCharacter / CPoliticalStatus / CCountryPlayerSettings /
CCommand 的 RTTI 基链均含 `CPersistent @0`, 其主虚表前 6 槽槽位语义同构;
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
> 从不单独实例化, 故 exe 不发射其 COL; 具体类的虚表 = CPersistent 槽 + 派生类新槽。
> 槽 [1]/[3]/[5] 全类同址 ⇒ 定义在 CPersistent 且不被覆写; 槽 [2]/[4] 逐类变 ⇒ 纯虚。
>
> **CCountry 谱系 = 单链 CPersistent ← CAIOwner ← CCountry** (vt 实测 11 槽,
> mi=false); 槽 [8] = CCountry::PostLoad (sub_1406FE1D0 → thunk sub_1406FE1E0,
> 大级联: 政治名重建 → 逐单位 vt+224 钩 → 情报池/战斗/战区重挂 → 占领修复
> sub_140FF9DE0(cc+4048,0) 等 20+ 子步); [9][10] (sub_1401F8A60) = ICF 恒等汇点
> 推定归 CAIOwner 层 (唯 CCountry 一派生, 离线不可再分)
> **CUnit 例外**: CPersistent 在其 **@16** (次基子对象), 故 CUnit 主虚表 [2]/[4] 为空
> (真实序列化槽在其 +16 子对象虚表) —— **多基类时 CPersistent 槽位随 mdisp 漂移, 勿按主虚表硬套**。

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
① `vt[6](this)` 预载钩 → ② 循环取 token, 键经 `vt[5](this,token)` 谓词
(返真才登记查重; 重键报 `Duplicate "k" in file: "f" near line: N`, 文件名/行号
getter = sub_1424BF960 / sub_1424BFBA0) → ③ `vt[4](this, parser, token)` 逐块
ReadKey, 嵌套子对象各自递归走同一 wrapper (统一入口 thunk = sub_1424C0AA0
`return obj->vt[3](obj, parser)`) → ④ 块尾 (tok 4/19) 即调 **`vt[8](this)` =
PostLoad** → `vt[7](this, filename, startLine, endLine)` 后验钩。
**无集中全局 PostLoad pass** — 全局次序 = 存档文档深度优先序 (先子后父、
同层按落盘键序), 全装载链见 §4.28.17。

#### 4.00.2 GUI 框架基类 (View 底座 / tooltip / popup)

| 基类 | vtable | 槽数 | 派生规模 | 定位 |
|---|---|---|---|---|
| **CTooltipHandler** | 0x14273AA08 | 2 | 972 直接派生 | 抽象 tooltip 钩子接口 |
| CUpdateable | 0x14294c198 | 6 | 125 | Update / populate 底座 |
| CReloadDispatcher | 0x14271a630 | 4 | 330 | ret0 空实现层 |
| **CTemplateChanger** | 0x1429E9BF8 | 6 | — | 收集可换编制目标 (非抽象: [0][1] = _purecall / [2] sub_14169D500 / [3] ret0 / [4] CFG_nop / [5] ret0) |
| CReloadableInterface | 0x142B3F238 | 4 | 290 | Reload 接口 |

CTooltipHandler 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 纯虚钩子; 签名定案 `bool BuildTooltip(hovered CGuiObject*, CString& out)` |
| [1] | sub_1402DE980 | 析构 |

CTooltipHandler 调用与挂接:

| 项 | 值 |
|---|---|
| 调用方 | sub_14163BB80 (悬停组装器: hovered+117 旗 &4 禁用门 → vt[70] 取 handler → 调钩子; false / 无 handler → 兜底 sub_1419A7F60) |
| 挂接 | CGuiObject@48 子对象 vt[69] = SetTooltipHandler (存窗口 +128, 递归子窗) |
| 读取 | vt[70] = getter (读 +80) |

CUpdateable 虚表槽表 (0x14294c198, 6 槽; 契约定案 — standardinterface.cpp 断言串对偶佐证):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 析构 |
| [1] | — | **IsValid** (基实现推进 timeout_progressbar 后 return 未超时; 派生全部 base && 条件组合; 旧记「Update 纯虚」归并) |
| [2] | — | **Refresh** (派生 populate 用法归并入此名) |
| [3] | — | IsFor (推定: 共享谓词 `+8 && +8==arg` = ctor 绑定指针与入参比较, 全族零覆写) |
| [4] | — | **Setup** (基 = ret0) |
| [5] | — | **Teardown** (基 = guard_nop; 6 槽口径复证, slot[6] 起 = 下一虚表 COL) |

CReloadDispatcher 虚表槽表 (0x14271a630, 4 槽; 契约定案 — 控制台 `reload` 派发与枚举壳直证):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 析构 |
| [1] | — | **Update** (带可选参数表的推进/处理回调, bool) |
| [2] | — | **Reload** (无参重载/重建, bool; 控制台 `reload <name>` 派发调 vtab+16) |
| [3] | — | **CollectReloadNames** (向引擎字符串表容器追加本对象可重载条目名) |

CTemplateChanger 虚表槽表 (0x1429E9BF8, 6 槽):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | **CollectTargetDivisions(out\<CArmy\*\>)** |
| [2] | — | **CollectAvailableTemplates(tag, out, &hq_flag)**: 遍历 cc+440 模板容器, 滤锁门 sub_140BA2440 + obsolete@+542 + is_army_hq@+436 旗 |

> CArmyDivisionStatsView@80 / CArmyDivisionListView@0 两视图同构覆写 (stats 主表
> 6 槽挂 CUpdateable@64 + CTemplateChanger@80; 基族「同族不同序」实例)。
>
> **CArmyDivisionStatsView 五表 28 槽全定**: 主 0x1429EA2E0 (4: [0] 析构 sub_141697C40 / [1] ret0 / [2] sub_1416ADD60 Reload / [3] CFG_nop) · @40 iface 0x1429EA308 (10) · @64 CUpdateable 0x1429EA360 (6: [0] sub_141697B08 / [1] sub_1416B88A0 / [2] sub_1416AD770 / [3] sub_1402E02D0 / [4] ret0 / [5] CFG_nop) · @80 CTemplateChanger 0x1429EA398 (6: [0] sub_141698860 / [1] sub_14169B5D0 / [2] sub_14169D450 / [3] ret0 / [4] CFG_nop / [5] ret0) · @112 CTooltipHandler 0x1429EA3D0 (2: [0] sub_1416A2270 BuildTooltip / [1] sub_141697B14)。
> **CArmyDivisionListView 二表**: 主 0x1429E9F18 (6: [0] 析构 sub_141698540 / [1] sub_14169B400 / [2] sub_14169D420 / [3] ret0 / [4] CFG_nop / [5] ret0) · @32 tooltip 0x1429E9F50 (2: [0] sub_14169F350 / [1] sub_141697AF0)。

CReloadableInterface 虚表槽表 (0x142B3F238, 4 功能槽; 契约 = CReloadDispatcher 扇出):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | sub_142256130 | 析构 (sub_1422560A0 + free) |
| [1] | — | **Update** (继承契约) |
| [2] | _purecall | **Reload** (纯虚重抽象, 强制窗口实现; 旧记 Reload 归并) |
| [3] | — | **CollectReloadNames** (基 = CFG_nop 空默认; 派生逐条 push) |

> 三独立实现同构: CCountryView 0X1412375D0 / CPopUpWindow@16 0X140B7D300 /
> CShipStatsView 0X141BED890 = 释放旧窗 → 工厂重建 → 注入 tooltip →
> `return sub_14225D3C0(win+48)^1`。

CCountryView 公共 View 基座: 主 vt **0x1429A3F38, 17 槽, 抽象**; 基链
`CReloadableInterface@0 ← CReloadDispatcher@0 ← CTooltipHandler@40 ←
CInGameUpdateableInterface@48`; CCountryStateView (0x1429F82E8) / CCountryNavalRegionView
(0x1429F6D78) 同链, 17 槽中 11 槽同址。

| 槽 | 函数 | 语义 |
|---|---|---|
| [2] | — | **Reload 实现** (基类纯虚落点) |
| [5] | — | **IsOpenAndVisible**: `win=+1400 → !win->vt[73] && byte165&8` |
| [9] | State 0X14174A990 | **Refresh**: 悬停==+1416 → populate_b sub_14174ECF0; ==+1408 → populate_a sub_14174DD50 |
| [11] | State 0X14174AA40 / Naval 0X141735770 | **SetTarget**: State +1408=a2, +1416=*(a2+192); Naval +6912=a2+200 |
| [14] | State 0X14174AF00 (2.6 万行) / Naval 0X141735BE0 | **populate 主** (纯虚) |
| [15] | State 0X141746070 (1.2 万行) / Naval 0X141734CC0 | **populate 副** (纯虚) |
| [16] | — | 界面对象刷新 (断言 `_Idler.CanUpdateGui`) |

> 补槽 (PE 直读): [0] = _purecall 析构 / [1][12][13] = ret0 / [3][6][10] = CFG_nop / [4] = 0x141237840 = **Repopulate sub_141236980** (sub_141237840 实调后者; 「退订 sub_141236280」为误配, 废) + +1400 窗口非空虚调 win+48 子对象 vt[15] / [7] = 0x141237500 关窗转发 (win+48 子对象 vt[16]) / [8] = 0x141237570 win 主虚表 [12] 转发 ([4][7][8] 高置信)。

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

CInGameUpdateableInterface (0x142A41C20, 10 槽) 虚表槽表 (基类桩 + **派发侧语义**, 定案):

| 槽 | 基类 | 派发侧语义 (sub_140B68600 "interface.tick" 逐层无门直调) |
|---|---|---|
| [0] | — | 析构 |
| [1] | 断言桩 "Override this function before using!" (updateableinterface.cpp L37-67) | **年** 动作 (无门) |
| [2] | 断言桩 (同 [1]) | **5 月** 动作 (无门) |
| [3] | 断言桩 (同 [1]) | **月** 动作 |
| [4] | 断言桩 (同 [1]) | **周** 动作 |
| [5] | 断言桩 (同 [1]) | **日** 动作 |
| [6] | 断言桩 (同 [1]; 视图覆写 = 全量刷新) | **时** 动作 (经 vt[8] 门) |
| [7] | 断言桩 (同 [1]; 视图覆写 = 逐帧 Update) | **每帧** 动作 (bit0 层, 无门) |
| [8] | 0X141237590 (共享) | IsOpenAndVisible 转发 (调主 vt[5]); 兼**时层派发门** |
| [9] | — | **Repopulate** (纯虚) = 脏重建 (脏标在 iface+20) |

> **interface.tick 中央派发** (定案): sub_140B68600 (体首 profiler 字面量 "interface.tick") —
> mgr (= idler+1720 大视图对象) 七层注册列表 (begin@+144/+120/+96/+72/+48/+24/+0,
> 条目 = 8B 裸接口子对象指针) 按 iface+16 七位层掩码逐层遍历, 逐项 `entry->vt[槽](entry)`
> — **门语义 (定案)**: 月/周/日三层与帧层一样过 vt[8] IsOpenAndVisible 门, 年/6月两层无门; [2] 槽层 = 月==5 (0-based, 即 6 月, 月份计算器 sub_140177650 返回 0-based); 年/6月/周三层现无任何注册者 (引擎保留档位, 详 §4.30.46); 另 mgr+200 = 23 固定槽视图数组 (换国 vt[6] / 帧尾脏标 vt[9])。
> 遍历函数由 CInGameIdler::Idle (0x140DD3A50) **直调** (xref 唯一) — 与渲染链
> (DDDDF0 → 223D2C0, §4.28.14) 并列, 不经渲染路径。
> 注册/退订三件: sub_1412362A0 (win+48, mgr, 层掩码) / sub_141236820 (按 7 位掩码逐层
> push_back, bit0 带去重) / sub_141236330 (镜像退订); CTopBar ctor 0x14188FDC0 以
> 掩码 0x17 (每帧+时+日+月) 注册。⚠ win+23448 = CTopBar 本地子 widget 启停表
> (旗字节 + vector, 消费 sub_14189EEB0 逐 widget +228 bit7 广播), **非**中央注册表。

> 视图 @48 子对象只覆写 [6] (全量刷新) / [7] (逐帧 Update) / [9]。

CPopUpWindow 三虚表 (主 0x14294C238 14 槽 / @16 0x14294C2B0 4 槽 / @56 0x14294C2D8 2 槽);
主虚表 = CUpdateable[0..5] + 自有槽:

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | sub_140B7B930 | 析构 |
| [1] | sub_140B826E0 | populate |
| [2] | — | CFG_nop |
| [3] | sub_1402E02D0 | 共享谓词 `+8 && +8==arg` |
| [4] | — | ret0 |
| [5] | — | CFG_nop |
| [6] | sub_140B82510 | — |
| [7] | sub_140B7CC80 | IsOpenAndVisible (`win=+1392 → !vt[73] && byte165&8`) |
| [8] | sub_140B7CC20 | — |
| [9] | sub_140B7CD00 | — |
| [10] | sub_140B7CCD0 | — |
| [11] | — | **OnOpen** (纯虚) — 派生共享实现 0x140B7E3F0: 先 `sub_140B7D780` 建窗并绑 accept_button/decline_button (+180/+181) 再尾调本表 [14] Populate (**50 类**命中); CDefaultInfoPopUpWindow 变体 0x140B7E410 绑 ok_button 后同样委托 [14] |
| [12] | — | **OnClose** (纯虚) — 派生共享实现 0x140B7BE00: 单行 `return this->vt[15](this)` (**56 类**命中) |
| [13] | — | CFG_nop |

> 建窗原语 = `sub_140B7D560` CreateWindow (+1392 已有窗时断言 `"_pWindow == 0 && \"Window already created.\""`, popupwindow.cpp:154)。
> 同槽两套名: 本表 OnOpen/OnClose 与 GUI 册 SetupDerived/teardown 指同一机制 ([11] 装配后委托 [14], [12] 清理后转发 [15])。

@16 子对象虚表 (CReloadableInterface 形, 4 槽; 真表 0x14294C2B0):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | sub_140B7B2F0 | 析构 |
| [1] | — | ret0 |
| [2] | 0X140B7D300 | Reload 实现 |
| [3] | — | CFG_nop |

> 注失实撤除: 主表 14 槽与 @16 表 4 槽书内已全列 (COL 边界复核: 主表 [13] 后 = @16 表 COL; @16 [3] 后 = @56 表 COL)。

@56 子对象虚表 (CTooltipHandler 形, 2 槽; 真表 0x14294C2D8):

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

**CDefaultConfirmationPopUpWindow 扩槽契约 (定案)**: **[12] = Close→OnClose 转发桩 0x140B7BE00** (单行 `return this->vt[15](this)`, CDefaultConfirmationPopUpWindow 系全族共享含 InfoPopUp 分支与 CAcceptCommandDialog; 基类 CPopUpWindow [12] 纯虚) / **[14] = Populate (灌 title/description 元素) / [15] = OnClose 关闭清理虚槽** (基类 CPopUpWindow 实装 0x140B7B2F0; CDefaultConfirmationPopUpWindow/CDefaultInfoPopUpWindow 抽象层纯虚; default_confirmation_popup 专用确认族具体类默认 CFG 空桩; CAcceptCommandDialog 覆写 0x1415BC810 = 遍历 +4184 命令数组销毁未投命令) **/ [16] = OnAccept / [17] = 关闭门 (默认 ret 1)**; accept/decline glue OnClick = sub_140B7CD90 / sub_140B7CFE0 双回调链; +1440/+1448 = accept/decline 控件 / +1520/+2808 = 双 glue / +1400 = 关窗旗。三通用弹窗: CStandardInfoPopUpWindow (def default_info_popup_window; 标题串@+2728/描述串@+2760 经 [14] Populate 0X141BE5690 灌入); CDefaultInfoPopUpWindow (抽象基, [14..16] 纯虚); CConfirmationPopUpWindow (def confirmation_popup_window 独立分支 + CAutomaticPause@+1440; 标题+2744/正文+2776/发送接收方旗 tag@+2808/+2812/战争图标变体+2816; 实测消费 = MILESTONE_UNLOCK_HEADER 通知)。**CAcceptCommandDialog** (def default_confirmation_popup): **载荷 = CCommand\* 数组 @+4184 {count@+4196}** — 接受 ([16]) 逐个 sub_142250B00 投递, 关闭 ([15]) 销毁未投命令。

default_confirmation_popup 专用确认窗族 (基座主虚表 0x14294C358 18 槽, 槽 14/15/16 基座纯虚; 派生统一覆写 = 槽14 OnInit 装 TITLE/DESC loc 键 / 槽15 空 / 槽16 OnConfirm; 统一布局 +4096 = 宿主控制器 / +4104 起载荷; 确认统一链 = 宿主 vtable+136 取命令队列 → 命令 ctor → sub_142250B00 入队):

| 类 | vt (主) | 确认语义 | OnConfirm 去向 |
|---|---|---|---|
| CConfirmAssignUnitsToFront | 0x142A2F7C0 | 批量指派部队到前线 (单位 CRef 向量载荷) | 命令入队 |
| CConfirmCancelNavyActivityDialog | 0x1429DD038 | 海军行动取消 | 命令入队 |
| CConfirmCancelShipRefittingDialog | 0x1429DD110 | 舰船改装取消 | 命令入队 |
| CConfirmConsolidateUnits | 0x142A68548 | 整编/合并残编部队 | 命令入队 |
| CConfirmDeleteAllEquipmentProductionLines | 0x142A9CCE0 | 删除全部装备生产线 (CONFIRMCANCELALLPRODUCTIONLINE loc 铁证) | 命令入队 |
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

**CDiplomacyPopupWindowBase** (外交弹窗抽象基, vt 0x1429F9658 四表; 槽 11/12 留纯虚 = 接受/拒绝回调派生实现; 槽 14 = 展示即 CAutomaticPause SetPause(2) 自动暂停, 槽 15 配对恢复; 宿主指针@+4096) → 派生 CStandardDiplomacyPopup / CScriptedGUIDiplomacyPopup / CIncomingLendLeaseDiplomacyPopup / CForeignManpowerDiplomacyPopup。

> ⚠ **CTooltipHandler 基子对象偏移逐类不同** (CPopUpWindow +56 / CShipStatsView +40 /
> CArmyDivisionStatsView +112), 无固定偏移可套。
>
> ⚠ **槽位方差法多基坑**: 该法只收后代**主虚表** —— 多基后代
> (CReloadableInterface+CUpdateable 并存) 会把 A 基槽实现误记为 B 基覆写 (实例
> CEventWindow 0X141239A40); 大家族结果按主基分层后再读。
>
> ⚠ **基族「同族不同序」**: CDivisionDesignerView 与 CCountryView 同基族但
> 排序不同 (iface@40 + tooltip@64 + **CModelListItemParent@72**, 主虚表仅 6 槽,
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

**CEffect 全槽表** (覆盖数 = 470 个实测虚表中覆写该槽的类数; 「默认」= 基类共享实现):

| 槽 | 语义 | 覆盖 | 证据 |
|---|---|---|---|
| [0] | 析构 | 148 变 | MSVC 惯例 |
| [1] | **GetName** (读 +32 id ≥0 则查注册表返 std::string*; 否则 +44 token 转名并缓存 +56) | 468 同 sub_14053FF00 | 全家族同址 (只触 CEffect 通用字段) |
| [2] | **固定 getter** `*(a1+32)` (int) | 470 全同 sub_140177730 | 无覆写 |
| [3] | **块级 Parse** — 逐键分派 (键 token → 各键子解析回调), 未识别键回落 [4] | 42 | sub_140540B90 |
| [4] | **载荷键解析主体** — 逐类标量键解析 (tooltip/var/value/min/max/array/index/limit/side/gfx 等), 未识别键回落 AddSubEffect (解析期按 token/名实例化子效果并追加, if/else 链 + 作用域校验 + 数据库兜底, effect.cpp:392/435/445) | 180 | sub_140540EE0 (回落) |
| [5] | 默认 `return 1` | 449 | sub_1401807B0 |
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
| [23] | **ResolveReferences** (基 = guard_nop; 派生 trait/policy 族实装: 遍历名字数组按名查 gameitemdb 条目后绑定, gameitemdatabase.h:142 断言) | 396 = guard_nop | ICF |
| [24] | 默认 (恒定) | 468 同 sub_140541A30 | — |

> ⚠ [6] = ParseTargetToken 槽 (作用域键解析), **跳过此槽 = token 流错位崩溃**; 块级 Parse 主入口 = [3]。

**CTrigger 全槽表** (覆盖数 = 546 个实测虚表; 另有可选扩展槽 [23], 仅 241/546 实测虚表含):

| 槽 | 语义 | 覆盖 | 证据 |
|---|---|---|---|
| [0] | 析构 | 89 变 | — |
| [1] | **GetName** (建子触发器时存关键字 token 到 +32; 本槽查 lexer 返 token 文本, 未命中经 +44 懒构缓存串 +56; 旧记 GetKey 归并 — 与 CProfiledScopeObject/CEffect [1] 同一虚函数) | 544 同 sub_14054E9E0 | 仅 CScriptedTrigger 族覆写返脚本名 |
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
| [12] | **GetTooltipText** (遍历子表调 [21]+[3], 按 Evaluate==a4 前缀本地化 TRIGGER_UNFULLFILLED_PREFIX / TRIGGER_FULLFILLED_PREFIX, 按缩进参数重复 "   ", 递归子 [12]) | 24 | sub_14054C800 |
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
| [23] | 逐类扩展槽 (基类 23 函数槽 0..22 之外) | 167 变 | 仅 241/546 实测虚表含此槽 |

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

> **注册壳**: CEffectEntry<T> (16B {vt@0, desc 串@8}) / CTriggerEntry<T> (24B {vt@0, desc 串@8, 旗 u8@16}) — 虚表仅 2 槽 ([0] 析构/[1] 工厂 malloc+ctor+绑实例), **不含任何键解析**; 注册表 = RB 树 {节点+32=token, +40=entry} (effects qword_143330000 map@+0 / triggers qword_143330050 map@+24)。

> **逐类载荷键解析槽 (定案)**: 脚本键 → 载荷偏移的落点 = **CEffect vtable [4]** /
> **CTrigger vtable [4]** (逐类覆写) 与 [6] (通用值消费); 实现形态 = 键 token 减法链
> (`sub r8d,K ; je …`, 未识别键回落通用 0x1424C2060)。通用槽: CEffect [3] = 0x140540B90
> (块分派) / [5] = 0x1401807B0 / [6] = 0x14053D4C0 (仅作用域键); CTrigger [3] = 0x14054D0B0 /
> [4] = 0x14054AE70 (基, scope-target 兜底) / [5] = 0x14054FD00 (块 Parse) / [6] = 0x140550030 (token 分派)。**查某 effect/trigger 的键落点 → 取该类 [4]/[6]
> 。样本 = CAddBuildingConstructionEffect (vt 0x14274DDE0):
> [4] = 0x14031DB40 逐键 cmp 225 type / 10304 province / 10348 level / 11829 instant_build。

> **用法**: 要读某 effect/trigger 类的行为 → 取该类的 [13] (CEffect, Execute) 或
> [22] (CTrigger, Evaluate) 槽函数; 要读其本地化描述 → [7]/[21] (GetDesc)。
> **CEffect 与 CTrigger 的 GetDesc/行为槽位号不同** (7/13 vs 21/22), 勿混。
> 覆写数极低的槽 (1-5 变) = 基类共享样板; 覆写数高的槽 = 逐类行为所在。

#### 4.00.4 CEventScope 求值/事件 scope 上下文对象 (176B = 0xB0; vftable RVA 0x27D43E8; writer sub_14053BDA0 / reader vt[4] sub_140538F20 17 键对账)

> Execute/Evaluate 求值上下文与事件 scope 同体 (effect 端 ctx / trigger 端 ctx 同构)。
> 原「无独立 RTTI 类」负定案修正: 有 vftable (0x27D43E8, 活体+类树双证)。
> ⚠ 原 +192/+296 两行废 (sizeof 176B 内两偏移结构上不可能, 系 effect/loader-ctx
> 侧偏移误置); 原 +92 并回 +88 (operation id 对高位 dword, 无独立槽)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | u32 | 国 tag id (键 10394; tag 串→id 查表, 失败报 "Invalid country tag.") | 定案 |
| +12 | u32 | RNG 计数 (键 10171; loader ctx+192==3 走二进制读否则 hash 派生) | 定案 |
| +16 | u32 | RNG 种子 | 定案 |
| +24 | CEventScope* | root 作用域 (键 11412; owned 持有 @+48, malloc(0xB0) 递归读入) | 定案 |
| +32 | CEventScope* | from 作用域 (键 10639; owned @+56) | 定案 |
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
| +160 | 块 | saved_event_target (键 13217; 112B 元 CSavedEventTarget; 0x30B 堆节点双容器) | 定案 |
| +168 | u32 | 州 id (键 439) | 定案 |
| +172 | uint8 | 作用域存在旗 (scope_exists 极性锚定) | 定案 (活体 = 1) |

- 附注: 除 +72/+96 两裸指针外, 句柄槽全部为 8B id 对 {表选择子, 键} (sub_14221F310 注册表解析);
  空槽判定 = 全零判定 (哨兵 qword_14333D528 在 1.19.3 活体 = 0, 书记 0x02DF8CA0_0005EA66 系 1.19.2 值)。
- 附注: 源键位场 (+36 u32 作用域键位图 + event_target tag u16@+40) **属 effect/trigger 对象**
  (§4.00.3 [6]/[4] 行), 不在 CEventScope 上 (176B 内 +32/+40 被指针占满)。⚠ CEffect[6]
  parse (sub_14053D4C0) 与 CTrigger[4] parse (sub_14054AE70) 在 controller (0x020 vs 0x440)/
  occupied (0x040 vs 0x420) 两键位映射上互相交叉且 CEffect 版与共享求值器相反 — 疑引擎真实不一致。
- 附注 (定案, 函数族): 本表对象 = **CEventScope** (原记「CCountry+16 内嵌 176B 件同体」误置 —
  CCountry+16 是 name 串缓存; +16 内嵌 scope 实为 delayed_event 元素 (0xC8) 的 +16, §4.12);
  函数族全在 0x53 区 — **拷贝构造 sub_140534F00** (置 vftable+默认值后经 sub_140535FD0 拷全部
  载荷并克隆 +160 块) / **默认根构造 sub_140535110** (root/from/prev = 自指根哨兵) /
  **析构 sub_140535820** (+48/+56/+64 三引用计数对象虚调释放 + 销毁 +160 块) /
  **SetCountry sub_14053A610** (写 +8; clear=1 先 sub_140BD00 全清) / **SetState sub_14053B5F0**
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

#### 4.00.5 基类普查与工具法

- **槽位方差法 (定基类槽语义的通用法)** 以 `CEffect` 为例:
  取该基类全部后代类 → 各解虚表 → 逐槽统计「有多少类覆写 / 出现多少种取值」。
  - **恒定槽 (1 种取值)** = 基类共享样板 (如 CEffect[2] 470 类全同) → 读一次即懂。
  - **高方差槽** = 纯虚/逐类行为所在 (如 CEffect[13] 375 类覆写 = Execute)。
  - 再用「已知方法地址反查落在哪槽」(如 9 个 `Execute` 锚点全落 CEffect[13]) 定名。
- ⚠ **COL 判据坑**: MSVC COL signature **多继承=1 / 单继承=0** —— 只认 sig=1 会
  把 `CBoolTrigger`(114 派生) 等大批单继承基类误判为「抽象无虚表」;
  解虚表须同时接受 sig=0/1 (sig=0 时自指 RVA 校验写在 +20 语义不同, 靠派生类反查兜底)。
- **抽象判据**: 类无 COL-referencing vtable 且无自有 `vftable` 符号 ⇒ 抽象/不可实例化
  (CPersistent / CPersistentWithToken / CTriggerDataMembers / CPdxAllocator / CObjectType …)。

#### 4.00.6 控件层 (按钮管线 / 网格列表 / 选项)

按钮管线 (定案): widget 侧 CButtonStandard (vt 0x142B472E8 = CGuiObject 链@0 +
CButtonObservable@128 订阅表) 经 Broadcast sub_1422AFA70 逐个调 observer->vt[1];
观察者侧三级: **CButtonEventDispatcher** ← **CButtonObserver** ← **CButtonObserverGlue**。

CButtonEventDispatcher (0x14273AA20, 2 槽) 虚表槽表 ([0] = 析构 sub_1402DE810: `*a1 = &CButtonEventDispatcher::'vftable'; if(a2&1) free` / [1] = _purecall Dispatch):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | Dispatch (纯虚) |

> [0] = scalar deleting 析构 sub_1402DE810 (`*a1 = &vftable; if(a2&1) free`) — 注失实撤除 (正文已含)。

CButtonObserver: 抽象, = CButtonEventDispatcher + 10 纯虚 OnXxx (BaseClassArray
mdisp 全 0 铁证); 具体槽位经 CButtonObserverGlue 落位。

CButtonObserverGlue (基表 0x14273AA38, 12 槽, 479 派生) 虚表槽表 ([0] = 析构 thunk sub_1402DE7C0: `sub_1402DE480(Block+8); *Block = &CButtonEventDispatcher::'vftable'; if(a2&1) free`; ⚠ 0x142A17008 是 `CLegacyButtonObserverGlue<CCryptologyMapIcon>` 特化表, 其 [0] 与基表同址):

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | — | 事件总路由 (switch event->type) |
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
| TListboxItem | 0x142B42AA8 | 24 | 大部纯虚的列表条目接口, +8=CGuiObject\*; 与 GridBoxItem **同构姊妹接口** (转发函数同址铁证) |
| CStandardlistboxItem | 0x142B42B70 + 0x142A86410 (双 vt) | 13+24 | = COption + TListboxItem 组合 |

选项:

| 类 | vtable | 槽数 | 要点 |
|---|---|---|---|
| COption | 0x142B4A5A0 | 9 | Check/Uncheck (广播) / IsChecked / SetChecked (静默); flag@+48; COL 0x142DE1590 |
| COptionObservable | 0X142B40C48 | 4 | 纯 observable mixin |

观察者小族:

| 类 | vtable | 槽数 | 纯虚槽 | 胶水形态 |
|---|---|---|---|---|
| CCheckBoxObserver | 0X142739AF8 | 7 | [1]..[6] 回调 | 胶水 = {vtbl, target, 6×fnptr} + forwarder 池 0X1402E08A0-0X1402E10B0 |
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

CCommand 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [1] | 共享 (见 §4.00.1) | Save wrapper |
| [2] | 0X14226A110 | **writer 本体, 全家族共享** (412 虚表方差各 1 种取值, 具体命令类不覆写) |
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

执行与路由: 执行 = **虚表 [10] Execute**; 路由 = order.cpp:273 **id→构造函数表**
(按 [11] GetTypeId); 会话链: post sub_142250B00 (写 +12 发送方 / +22 tick 戳) →
drain sub_142252D00 (IsValid 门 → Execute → [13] 克隆重播, +8 重播门旗防重入)。

CCommand 实例布局 (基类 0x28B):

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | — | 重播门旗 | — | drain 侧重播防重入 |
| +12 | — | 发送方 player id | — | ctor 写 −1; post 写入 |
| +16 | u32 | 暂存A | — | getter [18] / setter [19] |
| +20 | u16 | 暂存B | — | getter [20] / setter [21] |
| +22 | — | tick 戳 | — | 0xFFFF=未投递; post 写入 |
| +24..+32 | — | SInternalData 持久项 | — | 单字段跨字节范围 |
| +40 起 | — | 派生载荷 | — | 各具体命令类布局另查 |

> reader 双通道: token 65 = 文本逐 token 调 [23]; token 499 = 二进制整块。
> 载荷 token 流（基座契约实证）: 基座 writer 写 499（SInternalData blob）+ 65 循环头后
> 逐字段调 [22]; 基座 reader 收 65 后循环取 parser 当前 token 逐个派发 [23]（哨兵
> token 4/19 收束; 未接 token → 0x1424BEC40 读弃）。

载荷判读原语语义表 (reader/writer 函数 → 语义; 逐命令载荷定案的判读基座):

| 地址 | 语义 | 证据 |
|---|---|---|
| 0x1424C0AA0(parser, obj) | 嵌套 CPersistent 对象读: 调 obj→vt[3] (Load wrapper) | 单行虚调, 槽 24/8=3 |
| 0x1424C08D0(parser, out) | 读 u32 (缓存未命中走 0x1424C1E40 兜底) | 体 = 0x1424C5220 探测 |
| 0x1424C0900(parser, out) | 读 u32 变体 (0x1424C5250 探测) | 体同构 |
| 0x1424C0A70(parser, out) | 读 i64 (0x1424C53E0) | 体同构 |
| 0x1424C0C00(parser, out) | 读 u8/bool (0x1424C5640) | 体同构 |
| 0x1424C0C30(parser, obj) | 读文本标量 → 40B 临时对象 (大小 u32@+12); 落 MSVC 串走 resize+data 对 | reader case 直证 |
| 0x1424C0AB0(parser, &str, flag) | 读 MSVC 串 (失败回退 "Unreadable String") | 体含该串 |
| 0x14221F970(parser, &id) | 读 CIdentifier/CID (8B idpair): 要求列表头 (type 3), 错误串 "Expected start of list reading CID" | 体直证 |
| 0x140BB5560(parser, out) | tag 串解析→u32 (读 parser+200 当前串→0x140BB3EF0 查表) | 体直证 |
| 0x1401F95D0(parser, c) | 读 u32 数组 (循环至哨兵 token 4/19; 元素 0x1424C08D0 push; 1.5 倍扩容) | 体直证 |
| 0x1424C2060(parser) | 跳块/读弃助手 | 体直证 |
| 0x1424BEC40 | 共享读弃空 reader (基座 [23] 默认) | 体 = 读弃 |
| 0x140CEE8F0 | jmp 0x1424BEC40 (增量链接 thunk → 共享读弃) | PE 字节 e9 4b 03 7d 01 |
| 0x1424C2E20(w, tok, obj) | 写嵌套对象: 字段头 (tok + 类型 1) 后调 obj→vt[1] (Save wrapper) | 体直证 |
| 0x1424C2EA0(w, tok, &str, f) | 写串 | 体直证 |
| 0x1424C2F40(w, tok, u32) / 0x1424C34F0(w, tok, i64) / 0x1424C37B0(w, tok, u8) | 写 u32 / i64 / u8 (值格式化分别 0x1424C49E0/0x1424C4900/0x1424C4D20) | 三者同构 |
| 0x1424C3290(w, tok, obj) | 写文本标量 (40B 临时对象形态) | writer case 直证 |
| 0x1424C4220(w, tok) | 写字段头 (块起 + token 名 + 类型 1) | 体直证 |
| 0x1424C4410(w) / 0x1424C3E60(w) / 0x1424C3A20(w) | 缩进 ++ / 缩进回显 / 块收 | 体直证 |
| 0x1401B3D80(w, tok, c) | 写 u32 数组块 (count>0 才发射; 元素 0x1424C2A10; 尾 0x1401F4F00(w,16)) | 体直证 |
| 0x1424CD070 / 0x1424CB4D0 | MSVC 串 resize / data 对 (0x1424C0C30 文本标量落串路径) | reader 直证 |
| 0x140BB4E70(obj) | tag→名串 (writer 侧, 与 0x140BB5560 读向互逆) | 体直证 |

**CPendingAction 待命指令族** (unitcontroller.cpp 域, 与 CCommand 邻接但**非 CPersistent 不入存档** — 运行时待命队列, Execute 时直发命令域命令): 基 = CPendingAction (vt 0x1429CBC40, [1..6] 全纯虚); 5 派生恰 7 槽契约: [1] 入队预检门 / [2] 类 id 枚举常量 (AddMovement=0 / AddStrategicRedeploy=1 / TransportUnit=2 / StratNavyTransfer=3 / CancelMovement=4, 各为编译器 `return N` 共享桩) / [3] RegisterRefs (引用收集入引擎 vector {ptr@0, cap@+8, count@+12, alloc@+16}, push = sub_1401205A0) / [4] ClearRefsIfIn / [5] IsValid / [6] Execute (AddMovement→sub_140BF9A40; CancelMovement→sub_140BFB4A0; AddStrategicRedeploy→new CStrategicRedeploymentCommand 0x50B; TransportUnit→栈构 CTransportUnitCommand 0x60B; StratNavyTransfer→sub_140EA9660)。入队统一入口 **sub_1414D4B50**(owner, pending): [1] 门 → [3] 收集 → 倒扫 owner+272 待命列表 (count@+284) 逐条 [4] 去重 (同对象旧指令被清引用, IsValid 假则虚析构移除) → push — **新指令实时取代同对象旧待命指令**。工厂: sub_1414C3860 Cancel (unitcontroller 拒动路径两调用簇互证: [15] 校验败清理 / 补给门拒) / 1414C38F0 AddMovement / 1414C3A50 AddStrategicRedeploy / 1414C3AE0 TransportUnit; StratNavyTransfer 在海军转移函数内联构。布局: CPendingAddMovement 56B (+8 CUnit*, +16 路径容器, +48 旗, +52 u32) / CPendingAddStrategicRedeploy 32B / CPendingCancelMovement 24B / CPendingStratNavyTransfer 56B (+16 单位 CReferenceObject 对向量, count@+28) / CPendingTransportUnit 32B (+8 CReferenceObject 智能对经 sub_14221F310 三档 id 库解析)。

#### 4.00.8 负定案与抽象判据

- **CProfiledScopeObject** (TD 0X14313C158, vtable 0x1427180e8): **无数据成员 (定案)** — vt 仅 2 槽 ([0] dtor+profiler 注销 / [1] GetName 返 "unnamed"); 是
  CEffect 的 virtual base (**有 COL**)。派生 1280 但**纯抽象埋点**,
  **不单列条目**。
- **CPdxAllocator** (TD 0X14313BBF0, vtable 空引用): 内存分配器, **与导出/GUI 无关, 不列条目**。
- **CPersistentWithToken** (TD 0x14313A488, 无 vtable — 全 .rdata 扫 COL→TD 零命中): 抽象; 继承 CPersistent + 静态 token (+8 u32, getter sub_1413CFAF0; 基 reader = sub_1424BEC40 = 单行 `return sub_1424C2060(a2)` 读弃)
  访问器族 (待并入 §4.00.1 —— 未决)。

#### 4.00.9 引擎设施族 (分配器 / 文件 / Steam / 音频 / 网格 / 水印)

通用桩清单 (1.19.3, 读槽/读语义前先滤): `_purecall` = 0x14253C3B8 / CFG 空桩 0x14012A2C0 / `return 0` false 桩 0x14011D220 / `return 1` true 桩 0x1401807B0 / UserMathErrorFunction (未实现占位) 0x140120540 / __acrt_select_exit_lock (ICF 常数桩) 0x140177700 / trivial getter (返 this+8 指针) 0x1402AA270。

**分配器族**: CPdxAllocator 接口 = {dtor, Allocate(size), Free(ptr), 预留槽} 4 槽。

| 类 | vt | 一句话 |
|---|---|---|
| CPdxNewDeleteAllocator | 0x142716590 | 默认分配器: [1]=0x14011D230 `j_j__malloc_base` / [2]=0x14011D250 `j_free`; **全局默认实例 = off_143085170 (va 0x143085170)**, 引擎容器 ctor 普遍写 = 探针验证容器 allocator 槽的基准值 |
| CPdxLinearAllocator | 0x142B94DC8 | 线性 bump 分配器: +8 游标 / +16 末端 / +24 chunk 链头 (头 24B {next,size,used}, dtor 沿链经 backing 释放) / +32 当前 chunk / +40 backing 分配器 (缺省 off_143085170) / +48 就地旗; 就地模式余量 <0x18 断言 pdx_linear_allocator.cpp:102 |

**文件族** (全非 CPersistent, 不入档):

| 类 | vt | 槽 | 一句话 |
|---|---|---|---|
| CFile | 0x142B93ED0 | 18 | 抽象文件基座 (9 纯虚): +8 标志=1 / +16 a3 / +20 a4 / +24 CString 路径 |
| CMemoryFile | 0x142B934E0 | 18 | 全实现: +56 数据源 / +64 内存缓冲 / +76 位置 (slot[15] 读出) / +85 owned 旗 |
| CArchiveFile | 0x142B92878 | 18 | PHYSFS 归档 (virtualfilesystem.cpp): +56 归档句柄 / +64 旗 |
| CRemoteFile | 0x142B46D58 | 19 | CMemoryFile 薄子类: 槽 [1..17] 逐槽同址全继承, 仅自有 dtor |
| CCloudFile | 0x142B6D268 | 16 | 云文件抽象基座 (14 纯虚), 实现 = CSteamCloudFile |
| CFileLogger | 0x142B3AC78 | 5 | CLogger 子类: +72 sink / +88..+112 状态槽×4 |
| CFileWatcher | 0x1429A66F8 | 5 | CReloadableInterface 系: +40 监视文件名 / +96 std::function 回调 (LoadDefinitions<CMapArrowManager> lambda 内 new 0x68) |

**CFileIntegrityWatermark** (存档完整性水印; vt 0x142A9A450 4 槽; 基 CReloadableInterface ← CReloadDispatcher; 非 CPersistent): +40 CFile* 水印文件句柄 / +48 宿主上下文 (其 +1272 = 文件系统对象)。[2] 0x141F57500 = Reset/Reopen: 关旧 → 经文件系统开 "file_integrity_watermark" → 状态门 (file+4324==1) 时写 "watermark_header" 段。存档容器内反篡改水印设施, 不入存档数据层。

**Steam 平台封装族** (10 类, 全非 CPersistent; 抽象 Context 基 RTTI 均在二进制确认):

| 类 | vt | 槽 | 基 |
|---|---|---|---|
| CSteamAchievementsContext | 0x142B5BE00 | 16 | CAchievementsContext (抽象) |
| CSteamBrowserContext | 0x142B5E628 | 5 | CBrowserContext |
| CSteamBrowserInstance | 0x142B5E8A8 | 21 | CBrowserInstance |
| CSteamCloudFile | 0x142B6D370 | 16 | CCloudFile |
| CSteamCloudStorageContext | 0x142B6D2F0 | 15 | CCloudStorageContext (字段: +56 CSteamCloudFile* 数组 / +68 count / +72 allocator) |
| CSteamMatchmakingContext | 0x142B6D940 | 46 | CMatchmakingContext |
| CSteamNetContext | 0x142B6E2A8 | 26 | CNetContext |
| CSteamStoreContext | 0x142B6F180 | 20 | CStoreContext |
| CSteamUGCContext | 0x142B6F460 | 22 | CUGCContext (抽象基 0x142B6F2E8 含 16 纯虚) |

**音频族**: **`?A0x9ca8863a::CAmbientSoundDatabase`** (环境音库, TGameItemDatabase 模板实例; 类表 vt 0x1427E3658 / 模板基表 0x1427E3628; ctor 兼 creator 0x14066ECD0; 单例槽 **0x143330540**) — ⚠ **该类只存在于匿名命名空间** (`?A0x9ca8863a::`), 全局名查找会落空; 条目为无 RTTI 内联 POD (200B/元素)。以下全非 CPersistent: **CMusicPlaybackListener** (vt 0x142A03C98 11 槽, 基 TListenerTrait\<CMusicPlayer,0\>, [2..10] 纯虚回调接口); **CStandardMusicPlaybackController** (0x142A7C7A8, + CTooltipHandler 双基, [2] 转发 +5200 音频通道); **CStandardMusicPlaylistController** (0x142A7CA68 13 槽, +16 指针数组 {count@+28}, [4] 批操作)。

**CMusicPlayerSettings** (音乐播放器设置; vt 0x14294EAF0 10 槽; **CPersistent 但写用户设置文件不入存档** — "SaveToFile called without loading first" 串 + savefull 零命中双证): writer 0x141927670 / reader 0x141927530; +8 串列表 (705 enabled) / +32 串列表 (14065 disabled)。

**CSong** (曲目 def 项, 104B; vt 0x14294C030 44 槽; CPersistent 但 writer = CFG 空桩 = 解析件不入档; reader 0x140B74DD0): +8 song 名串 (token 11418) / +40 CMeanTimeToHappen 内嵌 (token 446 chance 块) / +96 u32=0; def 去向 = boot 枚举 `music/*.txt`, 顶层 music(573) 块逐条 new CSong, playlist 键另由 sub_140B91500 处理。**语音族** (SAPI 无障碍, 全排除): PdxSpeechToTextInterface (0x142B5D220 抽象) → PdxSpeechToTextWinSAPI (0x142B5D260, 次 vt@+32 = SAPI COM 事件基); PdxTextToSpeechInterface (0x142B5D150 抽象) → PdxTextToSpeechWinSAPI (0x142B5D1B0); SpeechInput (0x142B3FDE0, 基 SpeechRecognitionListener 0x142B3FDB8) = 语音输入单例, Activate/Deactivate 即开关。**输入实现族** (pdx 引擎层, 全排除): CPdxEvents (0x142B3E948) / CPdxEventHandler (0x1427361E0) / CPdxSystem (0x142B51678, 基 CSystem) / CPdxKeyBoard (0x142B594D8, 多基 CKeyBoard + 键按/抬 Observable) / CPdxMouse (0x142B59550, 多基 CMouse + 5 Observable) / CPdxTouchDevice (0x142B51578)。**CTrack** (0x142B57FA8, 多基 CButton + CButtonObservable@+128) = GUI 滑轨元素, 与音频曲目无关; **CRomeBitmap** (0x1429D61E8, 基 CBitmap) = 位图实现; **CPostEffectVolumeReloader** (0x1429A7228, 基 CReloadDispatcher) = 16B 回调壳挂 owner+352, 仅 posteffectvolumes 热重载。

**网格渲染族**: **CPdxMeshObject** (渲染实例; vt 0x142B409F0 22 槽; 基 CPdx3DObjectHelper\<CPdxMeshType\> ← CPdx3DObject): +88 CPdxMeshType* / +112 渲染句柄 / +140..+160 包围盒 f32×6 / +184/+192 列表 / +200 分配器 (= off_143085170); ctor 0x142275B60 经 0x142309CC0 向 type 注册, dtor 0x14230E280 解注册。**CPdxMeshType** (网格类型 = 资产 lexer; vt 0x142B4D7A0 14 槽; 基 CPdx3DTypeHelper\<CPdxMeshType,CPdxMeshObject\> ← CPdx3DType ← CPersistentWithToken; **writer = CFG 空桩 = 入资产库不入存档**): reader 0x14230D680 键 file(26)→+184 串 / animation(64)→+216 SAnimationLookup vec / meshsettings(677)→+96 SMeshData vec (stride 216, 6×CString+CColor 元) / variant(793)→+120 串集 / preload_textures(673)→+370 u8; 基 reader 0x1422D7A60 键 name(27)→+16 / scale(93)→+48 f32 / cull_distance(368)→+52 f32 **读入即平方**; ctor 0x142308F20 置 +160..+180 包围盒 FLT_MAX/-FLT_MAX 哨兵对。

**3D/2d 双系总图** (渲染对象整族 writer 空桩 = 不写存档): 3D 双系 = **CPdx3DObject** (vt 0x142B40960, 实例基元, 非 CPersistent) ↔ **CPdx3DType** (0x142B41580, CPersistentWithToken, reader = 全族公共 0x1422D7A60 三键表见上), 业务类经 CPdx3D*Helper 模板桥接 (RTTI `?$CPdx3DObjectHelper`); 2d 双系 = **CGraphicalObject** (0x142B44120 基元) → C2dObject (0x142B3D060) → C2dVisibleObject → 实例链, Type 侧 C2dObjectType ← CObjectType ← CPersistentWithToken (其解析件并入 §4.30.31 精灵/GUI 模板族)。占位对 CPdxDummy3DObject (0x142B57DC8) / CPdxDummy3DType (0x142B57E58, reader 直通基 0x1422D7A60)。

**CArrowType** (地图箭头 def; vt 0x142B51AC8; reader 0x142356D10; 实例 CArrowObject 0x142B47C08: +112 绘制批次对象 / +128 数据 / +136 计数 / +144 分配器): 13 键 = height(31)→+144 f32 / size(47)→+64 f32 / endAt(88)→+68 f32 / color(86)→+80 CColor / colortwo(268)→+112 / specular(74)→+224 串 / effect(89)→+304 / normal(119)→+192 / texture(415)→+160 / overlay(489)→+256 / heading(184)→+152 f32 / type(225)→+148 i32; 未命中键回落 CPdx3DType reader。**CAnimatedMapTextType** (浮动地图文字 def; vt 0x142B519D0; reader 0x1423563F0): position(76)→+224 / speed(110)→+64 / maxWidth(145)→+236 / textblock(261)→+80 内嵌 CTextBlock。**CTextBlock** (排版块 def; vt 0x14294AC88; reader 0x1422D5C70, **无 default 回落**): font(30)→+48 串 / size(47)→+120/+124 i32 对 / position(76)→+112/+116 = **增量修正** (+120 += +112−新x 后 +112=新x, y 同理 = 滚动定位) / color(86)→+16 CColor / format(114)→+128 取首字符 's'=0/'t'=1/'u'=2 / text(143)→+80 串。

**CPdxPostEffectVolumeManager** (后效 def 宿主, 0x178 (376B); vt 0x1429A71B8, 多基 CPersistent + CLostDeviceInterface@+8; writer 空桩; reader 0x141288FE0; 宿主 = gamerendering.cpp 宿主对象 +184, ctor sub_1412849D0): +72..+100 f32 全局默认后效参数 / +128 哈希表 (装填因子 1.0) / **+280 矢量 = posteffect_values** (160B 元 SPostEffectValuesReader) / **+304 矢量 = posteffect_volume** (200B 元; 缺 posteffect_values_day 时报错不入) / +328 posteffect_height_volume 挂点 / +352 "posteffectvolumes" 名登记槽。元素 CPdxPostEffectVolume (0x1429A7140 抽象) / Box (0x1429A7168) / HeightVolume (0x1429A7190) 连 CPersistent 都不是 = 纯运行时几何体。**CGraphicalMap** (地图渲染根, 0x750 (1872B); vt 0x14294ACF8, 多基 + CLostDeviceInterface@+8; reader 0x140B56AE0; 宿主 = gameapplication.cpp 宿主对象 +880, ctor sub_140B4F9C0): reader 仅自有键 type(225) → new 168B 层对象入 +312 矢量 {cap@+320, count@+324, alloc@+328}; +88 = 大渲染子对象 (malloc 0x5D30)。**CTerrainGraphics** (地形图形 def; vt 0x1429C0EF0, 多基 CPersistentWithToken + THasNullObject; reader 0x14143F220): color(86)→+64 / type(225)→+88 经 TGameItemDatabase (qword_14332F0A8) 按名取图元句柄 (句柄[16]=0 时续读块) / texture(415)→+100 f32 / perm_snow(11857)→+104 u8 / spawn_city(12109)→+105 u8。

**重载器族** (8B 瘦对象 CReloadDispatcher 系 = 文件变更→[2] Reload; 注册 = sub_1422564C0(&扩展名), 文件监视器按扩展名分发): 扩展名↔类↔挂载点 = particle→CParticleReloader (0x142B3D6F8, gfx 管理器 +206256; [1] 路径谓词 0x14223C810 经纹理管理器 qword_143453090 桶遍历, [2] 0x14223C9E0 条目 +8==385 者调 sub_142297540) / mesh→CMeshReloader (+206272) / anim→**CAnimationReloader** (0x142B3D770, +206280; ⚠ 主 vt 尾部 [6..9] 带 CPersistent 槽 = Save wrapper/writer 空桩/Load wrapper/reader 0x14223B400, 指纹按 slot1 判定故 serfam 未命中) / guianim→**CGuiAnimationReloader** (0x142B3D898 主 CReloadDispatcher + 0x142B3D8C0 次 CPersistent mdisp=8, +206288 含宿主回指 +16; reader 0x14223B0D0 经 SGfxFileReader 解析 spriteTypes(53) 门定义入 3 个 RH 集, 其余块 skip; [2] 0x14223C3C0 重解析) / defines→**CDefinesReloader** (0x14271BA70, 第一宿主 +936; [2] 0x1401A4A20 → sub_14074A9E0(1) defines 全量热重载) / countrycolors→**CCountryColorsReloader** (0x14271BA98, +944; [2] 0x1401A4900 → sub_1401CCB50(gamestate) + sub_140A66D80 刷国家颜色) / assets→**CAssetsReloader** (0x142B3C3A0, 启动器对象 +784; [2] 0x14222E6A0 → sub_14222DDC0(qword_143452450, 0/1) 双遍重载)。texture→CTextureReloader (+206264) 见 §4.30.31 注。

**字体族** (全 .gfx/.gui 解析件 writer 空桩, 不入存档): **CFont** (vt 0x142B57ED0, 基 CPersistentWithToken; reader 0x14237E6B0): name(27)→+16 / cursor_offset(659)→+48 / selection_offset(720)→+56 ← **CBitmapFont** (0x142B41888, 附 +64 CLostDeviceInterface 虚基; reader 0x14229EC60; ctor 0x1422980C0): +72 宿主回指 / +88 color / +96 border_color / +208 fontfiles 串向量 {cap@+216, count@+220, alloc@+224} / +272 textcolors 定长阵列 / +12560 icons_add_height u8 / +12564 icon_scale f32=1.0 / +12568 起 40 个 32B 图元槽; reader 键 path(372) 追加 / fontfiles(718) 重置整表载入 (两者混用告警) / color(86) / border_color(461) / textcolors(714) / icons_add_height(595) / icon_scale(604); fontName(34)/colorcodes(297)/color_override(370) = deprecated 告警跳过 ← **CGameBitmapFont** (0x1429E6BE8, sizeof 0x3640; 脚本 `bitmapfont`(295) 块经 def 工厂钩子 0x140B410E0 malloc+ctor 0x141640D30 产出, 同钩子 a3==271 分支产 0x2C0 伴随对象); **CBitmap** (0x142B49820 无基) = 底层 BMP 载入器 (+48 就绪旗, 读 14B 头), 与字体无序列化关系。

**资产工厂族**: **CAssetFactoryAudio** (vt 0x142B503F8, ctor 0x1423492E0, dtor 变体 0x142349050 / 0x142349870; 基 CPersistent): [1] Save wrapper 0x1424BEC50 / **[2] writer = CFG 空桩** / [3] Load wrapper 0x1424BE690 / [4] **reader 0x14234A010**; 对象 +32/+56 两子容器 (sub_142348FE0 / sub_142348F70)。**CAssetFactory** (.asset 工厂基类; vt 0x142B50890, 基 CPersistent; writer 空桩; reader 0x14234DB90): reader 开头双旗门 = `+24 != (a3==438)` skip / `+25` 置位时只收 light(84)/entity(438)/particle(407) 三键, animation(64) → SAnimationData。**CAssetFactoryParticle** (0x142B501A8): [3] = **自定义 Load wrapper 0x142331870** (全量 SParticleSystemReader 解析), [4] = 基 reader — 与 CBrowserType (0x142B53C58, [3] 自定义 Load 0x1422DE0B0, reader 0x14236DFF0) 同属「wrapper 自定类」serfam 盲区实例 (另见 §4.00.1)。**CBrowser** (0x142B46F70, 基 CGuiObject + CTextInputReceiver@+128) = 内嵌 CEF 网页窗, 排除; CBrowserContext/CBrowserInstance 抽象基实现见本表 Steam 族。**开发/调试设施族 (负定案, 整族排除出存档域)**: **CNudgerStrategy** (vt 0x142A42FF0, 7 槽 5 纯虚, 无基非 CPersistent) = nudge 编辑器资产微调策略抽象基; 派生 CStateNudger (0x142A44BF0) / CStrategicRegionNudger (0x142A45220) / CSupplyNudger (0x142A45568) / CUnitsNudger (0x142A45A18) / CDatabaseNudger / CWeatherNudger / CBuildingsNudger / CAmbientObjectNudger (0x142A43130) 同构 `CNudgerStrategy@0 + CReloadableInterface/CReloadDispatcher@40` 多基 (12 槽), 激活 = 编辑器 GUI `interface/nudge.gui`, 仅写 mod 文本文件零存档面; **CDBNudger** (vt 0x142A44290 + 次 0x142A442D0, ctor 兼 dtor 0x141B504F0 / 0x141B51B40, sizeof ≥16448 — ctor 最大写偏移 16440, 上界提示; 槽 [1] 0x141B51F00 / [2] 0x141B52180 / [3] 0x141B52FF0) = 库级 nudge 器巨型对象 (~16KB)。**CCameraControlStrategy** (vt 0x142AFDA60, 11 槽 4 纯虚, 独立抽象基与 Nudger 无继承) → CFirstPersonStrategy (0x142AFDA90) / CTurnTableStrategy (0x142AFE5F8), 部署于 assetviewer/previewer 调试查看器。**HOI4EditorInterface** (vt 0x142727500, 基 CEditorInterface) = 启动参数 `-editor`/`--editor` 进入编辑器主循环 (sub_14209E610) 的界面根类。**sub_14209E610 = 进程主入口体** (WinMain 实现; 双角色定案: 常态分支建 CMapApplication 走游戏路, `-editor` 分支进 PdxEditor 编辑器路 — pdx_editor/startup.cpp 断言串 + mount previewer_assets/userdir 解析/日志挂载即编辑器分支段; 旧两处记载「WinMain 体」与「编辑器主循环」系同一函数的两段)。**CMapIdler** (12736B, CIdler 轻量支 +CLostDeviceInterface@8, 非 CGameIdler 支) = assetviewer/previewer 调试场景 idler (ctor 直绑 previewer_quit/record/next_asset 等 12 键); **CNudgeIdler** (3984B, CGameIdler 支 + CReloadDispatcher@1512) = nudge 编辑器场景 idler (副表邻串 interface/nudge.gui/ambient_objects/strategic_regions/buildings) — 两者与上列 Nudger/相机策略同场景。**CEvolveEquipmentImgui** (0x142A3D808, 7 纯虚) → **CEvolvePlaneImgui** (vt 0x14299B678, ctor 0x141198770, 104B, [2] 0x141B06800 OnUpdate) / **CEvolveShipImgui** (0x14299B768, ctor 0x141198800, 112B, [2] 0x141B076E0) / **CEvolveTankImgui** (0x14299B7E0, ctor 0x141198890, 120B, [2] 0x141B08020) = "DEBUG UI" 装备演化调试器。四类**均非 CPersistent** (槽 [1..4] = `_purecall` / CFG 桩 / 0x14039DAB0 / 0x1401807B0 样板) ⇒ 纯编辑器层不可序列化。**CLogger** (vt 0x142B91D18, 4 槽 2 纯虚抽象基) → CFileLogger (§4.00.9 文件族) / CFilterLogger (0x142B3AF58, 按类别 id 哈希路由转发, 全局表 qword_1434521A8 + OutputDebugString 旁路) / CNullLogger (0x142B91D40 空实现); **CTestLogger** (0x1429B3A68, CPersistent 壳 writer 空桩) → CEquipmentInFieldLogger / CManpowerLogger 遥测件, **CTestLoggersArray** (0x142737248) reader 0x14136E580 = 多态反序列化工厂 (tag 14054/14055); CTest/CTestBundle (0x142737148/0x142737198, writer 空桩) 与 CTestDatabase (0x142737218, 常驻装载 "tests" 目录) 同属自动化测试框架。**StackWalker** (0x142B58708) → CCustomStackWalker (0x142B5B3D8, 线程局部单例 0x1435B9F60) → CPdxCrashReportImpl (0x142B5B320 接口) → CPdxCrashReportWindows (0x142B5AA48) → CrashReporter.exe = 崩溃诊断链。**CAutotestSettings** (0x142724378, writer 空桩 reader 0x1401F8D30, 版本 tag 15531) 与 **CAnimViewerGraphics** (0x142AFD7B8, reader 0x14223B060, 版本 tag 53/55/296) 均为只读入解析件。以上整族 serfam 命中者 writer 一律 CFG 空桩 = 引擎不落盘。**调试右键菜单 (rightclickmenu.gui)** (定案): **`interface/rightclickmenu.gui` 是 -debug 模式的开发者菜单, 与玩家单位下令无关** (原 §4.33 十余行「rightclickmenu 地图右键菜单派发链」标注系路过 Idle 巨函的误标, 已勘误 — 玩家右键下令真实入口在地图输入/选择层 sub_140DCEFD0 簇)。构建器 = **sub_1402A3730** (每次右键按名清空重建 rightClickMenu 窗内 "options" listbox): 门 = debug 旗 byte_14332EC69 (启动串 "debug"/"crash_data_log" 置位; 控制台命令可翻转) ∧ 修饰键 ∧ button==2, 三个 idler (frontend sub_140B3CA20 / ingame sub_140DD3A50 [额外门 idler+2061, 写者未定位] / nudge sub_1412D49D0) 每帧扫各自 GUI 事件队列拾取。条目 = 三类硬编码对象 × .gui 模板: CRightClickReloadItem (vt 0x1429A9E58, 模板 right_click_entry_2, "Reload: <开窗源 .gui 文件名>") / CRightClickOpenItem (vt 0x1429AA018, 模板 right_click_entry, "Open: <州相关串>", 门 = 地图命中省视图 → state+168 有效旗 ∧ CStateDatabase 单例 qword_14332F070 已载断言 gameidler.cpp:1382) / CRightClickCloseItem (vt 0x1429A9C98, loc CLOSE, 仅置 +1376 关闭旗); 另 empty_right_click_entry 250x21 无按钮占位行 — 仅占位行 (count≤1) 时菜单隐藏。Open/Reload 动作 = **WinExec 经 dilepad 开发者工具通道** (CLogger 名串 "dilepad"; "@FILE@"/"@LINEINFO@" 占位符命令行), 零 CCommand 投递、零引擎调用。菜单开着再右键 = memcmp 源文件名短路不重建。旁系: byte_14332F60C 门 (右键+单修饰键) 走「窗口名::元素名」调试叠字层, 不经本菜单。

**MP 平台抽象基 ← 实现配对表** (§4.00.9 Steam 族补基座行; 基座全纯虚接口, 实现见 Steam 族/本表):

| 抽象基 | vt | 槽/纯虚 | 实现 |
|---|---|---|---|
| CNetContext | 0x142B6E000 | 26 / 25 | CSteamNetContext |
| CMatchmakingContext | 0x142B6D620 | 46 / 45 | CSteamMatchmakingContext |
| CCloudStorageContext | 0x142B6D1E8 | 15 (全纯虚) | CSteamCloudStorageContext |
| CStoreContext | 0x142B6EFC8 | 20 / 13 (默认体断言 "Method not implemented for this store backend.", pdx_store_interface.h) | CSteamStoreContext |
| CUGCContext | 0x142B6F2E8 | 27 / 19 | CSteamUGCContext |
| CSystem | 0x142B3CE30 | 9 / 7 | CPdxSystem |
| CPdxEvents | 0x142B3E948 | 26 / 9 | **CSdlEvents** (0x142B52948; [2] 0x142362CD0 do-PollEvent 循环抽干 / [3] 0x142362D10 注册 watch 回调对 / [4] 0x142362CF0 PushEvent 类型 256) |

**网络服务器族**: **CServer** (抽象基, vt 0x142B52AC8 ≥30 槽, [5][6][7][30][35][36] 纯虚; [4] 0x142363E10 经 +72 连接对象转发发包) → 唯一 RTTI 实现 **CProxyServer** (0x142B53598, proxy_server.cpp; [6] Update 间隔 >1.0s 打 "Long update!"; [3] 清 +348/+392/+472 连接状态 (24B 条, count@+480)); CDummyServer (0x142B52C28 31 槽, 单机空实现)。**CSession** (会话信息可观察包装, vt 0x142B3E9D8; +8/+16 观察者双链表首尾 / +24 count / +28 挂起旗 / +40 全局计数门 dword_143453198; ctor 重载对 = sub_14224E3E0/sub_14224E870 (9 参全量重载; 函数体首段逐行同构 + CSession::vftable 直证, 创建会话对象本身)。**CPlayerLobby** (大厅玩家面板, vt 0x142A0EC58; RTTI lambda 证 KickPlayer/BanPlayer; [22] 0x14186F3A0 = server_id_button → SERVER_ID_COPY)。**CChat** (游戏内聊天控制器, vt 0x1429ADE98, 基 CReloadableInterface ← CReloadDispatcher ← HotkeyListener; slash 命令表 `/slap /whisper /invite /newchannel /ban /kick /roll /save` 硬编码; 创建点 sub_1419A9090) → **CGameChat** (0x142A24E48, chat_window/chat_inbox_window/chat_item)。**CFriendsHandler** (平台好友表处理器, vt 0x1429D5378 19 槽, 懒建单例存储 qword_143339C70, getter sub_140A31BB0) → **CFriendsHandlerSteam** (680B Steam 后端: ctor 内建基后原位换表; 内嵌 "CAREER_PROFILE_YOU" 自好友件 CFriendsHandlerFriendSteam + 5 个排行榜/文件共享 CCallResult)。**ChatSettingsProviderImpl** (vt 0x142969468; 6 薄 getter 全委托 CSettings 单例 (0x1401FA5E0) +904/+912 域 (§4.28.11))。**HotkeyManager** (vt 0x142B3EE88, 基 CPdxEventHandler; +14 子对象串表 / +80 注册表 count@+92; 单例旗 byte_1434531B1)。

**CApplication 应用族** (只载不存 + 单实例锁): **CApplication** (vt 0x142B3C288 + 次表@+8; 基 CPersistent + CApplicationObservable 多基) — 主表 [1] **无 Save wrapper (CFG 空桩)**、[2] writer 空桩、[3] Load wrapper + [4] reader 0x14222E600 (只读 name(27)→+72 窗类名) = **应用单例只载不存** (serfam 指纹需 [1]+[3] 故未命中); ctor 0x14222B420 内 `FindWindowExA(0,0,+72,0)` 单实例互斥 ("An instance of this game is already running on this computer! Exiting."), **实例指针落 qword_143452450 (主单例定案**: ctor 写入, 18 引用全在 CApplication 编译单元 0x14222B5F0..0x14222EDD0)。**CApplicationObservable** (应用事件广播壳, vt 0x142B3C260 主表 4 槽; CApplication/CGameApplication/CMapApplication 公共多基 mdisp 8)。**CMapApplication** (0x142AE6950, 主进程应用; ctor sub_1420A13C0 由 WinMain 体 sub_14209E610 内建) / **CGameApplication** (0x1427182E0 族, 对象 1272B = malloc(0x4F8); **ctor = sub_140147EE0** (main.cpp:2136 直调, 对象 1272B; 预建 CSession "localhost" + ~28 对热重载注册 + 加载条组 65 回调, 详 §4.28.21); sub_140151EC0 = **析构函数** (恢复双 vtable 后 j_free 释放 20+ 成员对象); sub_14015FB30 = 标量删除析构包装。**CGameGraphics** (0x14294A338, 基 CGraphics + CLostDeviceInterface 虚继承@+206320; [1] SaveW/[3] LoadW 持久化图形设置到用户设置**非存档**; CGraphics 布局持双 2D 树 +496/+864 等槽 — 详 §4.35.3)。

#### 4.00.10 CColor (颜色值对象; writer 0X14224CA10)

CColor = 全引擎通用 4×f32 颜色值对象 (阵营色 / 战区色 / 图例 / 命令载荷 / GUI 预设色块等 30+ 处), 非任何域专有。
**内嵌尺寸随宿主变化 (三档实测)**: 完整对象 **32B** (vt@0 + 纯垫 8B@8 + rgba f32×4@16..31, 见 §4.24, ctor 0X14224BEB0); 常见内嵌投影 **16B** (裸 rgba, 无 vt, 阵营/战区色槽); GUI 行件投影 **24B** ({vt, 16B RGB}, 如 §4.31.20 CColorPickerPresetEntry+1312)。**判宿主取尺寸, 勿按单一值推广** (ctor 0X14224BEB0)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | vt | vtable | |
| +8..+15 | — | 纯垫 8B | ctor 只写 vt@0 + 四 float@16..31; writer 只读 a1[4..7] |
| +16 | f32 | r | |
| +20 | f32 | g | |
| +24 | f32 | b | |
| +28 | f32 | a | **≠1.0 (f32 精确比较) 才追加第 4 值** |

注: 写出 = `(int)(float)(v*255.0)` **截断 (向零)**。⚠ 凡本 writer (CColor) 输出一律截断,
无 round-half 变体 — 三处曾按 `floor(v*255+0.5)` 舍入 (theatre 色之外的
faction color / volunteers group_color / fleet color), 锚件实测定案:
f32 分量小数部分 >0.5 时两者必分歧, 截断 15/15 命中而舍入全错。
注: 写门 = !readonly ⇒ 文本存档恒写。
注: 读侧 rf32 → `math.floor(v*255)` (v≥0 时 = 截断, 与 C 双精度乘法逐位一致)。

#### 4.00.11 CGameDate / CGregorianDate (日期值对象; 推进槽 + 双哨兵)

CGameDate = 全引擎日期值对象 (内嵌 24B 三段形 `{vt1@+0, hours i64@+8, vt2@+16}`;
CGameDate ⊂ CGregorianDate, dtor 将 vt 复位 CGregorianDate 基 vt)。gs 当前时刻 =
gs+1120 (hours@1128), 载入快照 gs+152, start_date gs+1184 (§4.1.2)。

| 槽 (字节偏移) | 语义 | 证据 |
|---|---|---|
| 虚表槽[1] (字节+8) | **Advance(n)** — 推进 n 小时; gs hourly tick 每小时以 `(gs+1120, 1)` 调用 (§4.2.4 步骤 4) | 0x1401DD370 体内虚表调用 |
| 构造哨兵 | hours = 43808760 = "1.1.1.1" (ctor); 43817520 = "2.1.1.1" (默认构造, dword_14306EB38, 带门字段跳过); 43791240 = "-1.1.1.1" 为合法值勿滤 | §4.1.2 既有定案 |
| 纪元换算 | 总小时 43800000 = 纪元偏移; `(hours − 43800000)/24` = 总天数 (周边界 %7 判据, §4.2.5) | hourly tick 体内算式 |

注: 分量读取 (年/月/日/月索引) 走 gs+1144 日期分量缓存 (hourly tick 每小时重算,
dword_143085210 = 闰年月首累计日表), 非逐次从 hours 解析。

#### 4.00.12 拦截层 (框架对引擎函数的两种改写形态)

桥 DLL 对引擎的介入只有两种形态, 二者的**分界是「改数据还是改代码」**, 决定了各自的
能力边界与可逆性。选择拦截手段时先查本表: 虚方法一律走 A, 只有非虚目标才用 B。

| 形态 | 改写对象 | 可拦目标 | 覆盖范围 | 可逆 |
|---|---|---|---|---|
| **A 虚表槽交换** | `vt[slot]` 单个数据 qword | 经该槽调用的虚方法 | 只覆盖走该槽的调用方 | 可逆 (写回原 qword, 原子) |
| **B 函数体重定向** | 函数前 N 字节 (N ≥ 12, 整指令边界) | 任意有 `.pdata` 边界的函数 | 覆盖全部调用方 (直接 + 间接) | **不可逆** (无卸载) |

**A 的粒度陷阱**: 槽钩子是**逐类**的。基类虚表那些槽为 `_purecall`, 钩基表一个都拦不到
且不报错。要拦全族须钩**共享分派器** (effect/trigger 路由器即此类), 不要逐个钩派生类虚表。

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
| `CInGameIdler` vt slot4 | 0xDD3A50 (槽在 vt+32) | 帧心跳 (A 类: 槽交换, 非补丁) |

#### 4.00.4a CEventScope 消费路径

**CEventScope (176B) 三叉链 (定案)**: +24/+32/+40 = root/from/prev 指针
(自指即停); **+48/+56/+64 = 外层节点 owned 深拷贝** (析构 sub_140535820 经
vt[0] deleting dtor 释放三节点 (旧「引用计数对象槽」为误读, 废))。入队
sub_1401CAFF0 深克隆现场 scope (拷贝构造 + 链深克隆 sub_140536360);
pending_events 元素 56B = {fire_id@+0, CEvent*@+8, scope*@+16, tag@+24,
CGameDate@+32/+48} (⚠ gs+1376 块键 = **13793**; 13801 系 show_major)。
消费 = **CSelectEventOptionCommand (240B) +56 内嵌第三份深克隆**; Execute
(vt[10] = sub_14153A110) 用它渲染事件/选项名 + 发通知 + 推进 scope RNG, 末尾
sub_14117FA30(ev, cmd+56, idx) 跑 option CEffect[13], 再 sub_1401EBBE0 出队
释放。玩家路径全链: idler vt+240 sub_140DC5B10 → 216B 收件箱元素
(interface+1192) → 泵 sub_140B6B050 → CEventWindow ctor sub_1412381A0 (scope
平拷@+120); 点击 sub_141239AA0 / 超时 sub_14123C410 / AI 掷骰三入口同归命令。
**CEventScope reader = vt[4] sub_140538F20 全键表** (country/state/random/
root/from/prev/saved_event_target 等 17 键, token 名全对上); save_event_target
写在最外层 FROM 节点 +160 块 (find-by-name 命中覆盖)。delayed_events
(cc+4752) = 第二通道: 到期消费 sub_1406FC980 把持久 scope 重入发射链。读档
重建 = loader case 13793 逐元素 Load 后复用 sub_1401CAFF0 显式 pending_id
再入队 (定案)。



**docvar（@target 文本变量）注册器** (暗区定案): 框架 = lambda 签名
`CFixedPoint(CEventScope const&, int, CScopedVariable const*)` 的求值回调注册; leader/army
族全集 = **sub_14006EF30** (6,040 行; number of units controlled by leader /
num_units_in_state 等键), state 族 = **sub_140069A80** (resource@steel /
non_damaged_building_level 等)。loc 文本 `@变量名` 的可用集以此二注册器为准。

#### 4.00.13 CSelectable (选择态基类; 16B 无基类多态根 — rtti bases 空, 不继承 CPersistent)

ctor 唯一 = sub_140BC2AA0(this, type); 不序列化。凡带选择态的对象 (师/舰队/翼/
战斗/省/州/战略区/环境物/特工/铁路炮) 经它或其内嵌获得选择态。

| 偏移 | 类型 | 语义 | 备注 | 置信 |
|---|---|---|---|---|
| +0 | vt | 虚表 (宿主为主基时 = 宿主主表; 内嵌时 = 次表视口) | 纯类表 0x142950FB0 | 定案 |
| +8 | u32 | **可选类型枚举 id** (非实例 id; 消费端按它分派/过滤) | ctor `*(u32*)(a1+8) = a2` | 定案 |
| +12 | u8 | _bSelected 选中字节 (ctor 0; Select 置 1; DeselectNotify 清 0; dtor 断言 = false, selectable.cpp:51) | — | 定案 |

虚表 6 槽 (纯类 0x142950FB0): [0] dtor sub_140BC2B60 / [1] 纯虚 (名称填入 out, 各
宿主布局不一) / [2] 纯虚 OnSelected(mgr 容器, Select 尾回调 vt[+16]) / [3] 纯虚
OnDeselected(选择集已空旗, vt[+24]) / [4] 纯虚通知广播 (选择集全体 vt[+32]) /
[5] IsSelectable 基类默认恒真 (sub_1401807B0; 地理/战斗类普遍继承)。

**类型枚举全表** (17 个 ctor 调用点穷举): 0 = CArmy (CUnit 经主表) / 1 = CTaskForce /
2 = CAirWing / 3 = CCombat (子类共享) / 4 = CProvince (内嵌 @+8) / 5 = CState (@+8) /
6 = CStrategicRegion (@+8) / 9 = CAmbientObject (@+8) / 11 = CFleet (@+24) /
12 = COperativeLeader (@+3928) / 13 = CRailwayGun (主表); 7/8/10 无宿主 (负定案)。
多选规则: 空集或同 type id 方可加选; 陆军(0)/铁路炮(13) 额外要求 *(obj+672) =
CTheatre* 相等 (同战区方可混选)。选择管理器 = 双全局 qword_14332F698/F6A0 (同对象),
容器 @+1336, _Selection 双向链表 head@+48/tail@+56/count@+64, 节点 32B。

**方法地址** (selectable.cpp, 定案): Add = sub_140BC32D0 (":71/:72 断言; 尾插 + vt[+16] OnSelected + 监听者广播) / Remove = sub_140BC2D80 (":82/:104; :104 串原文 "selecatble" 引擎错拼) / Clear = sub_140BC2F60 / CanAdd = sub_140BC2CC0 (战区键取件 sub_140BF9660) / 成员级加入门 = sub_140DDFA60 (属主相同 + 组 id 相同或双方非零经 sub_140BB52F0 判同)。

宿主内嵌偏移: CArmy/CTaskForce/CAirWing/CCombat/CRailwayGun = +0 (主表) /
CProvince·CState·CStrategicRegion·CAmbientObject = +8 (次表) / CFleet = +24 (次表
0x142962A70 — §3.9 谱系补行) / COperativeLeader = +3928 (次表 0x142956018)。


#### 4.00.14 CUnitAdjuster (三维修正器; 40B; vt 0x142789CD0)

跨域通用修正件 — 州地形五统计组 (§4.18.19)、将领 per-skill 数组与四技能缓存 (§4.4)、
trait 条件修正表 (§4.4.23)、战术权重 (§4.22.7) 共用同一 40B 布局:

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vt | CUnitAdjuster | 0x142789CD0 |
| +8 | u32 | 上下文 token (地形 token / 品类 token 等; factory sub_141016A40) | 定案 |
| +16 | fixed×1e-5 | attack 修正 | 定案 |
| +24 | fixed×1e-5 | defence 修正 | 定案 |
| +32 | fixed×1e-5 | movement 修正 | 定案 |

消费 = RecalcSkillBonuses sub_140C21280 (§4.4) / 战术权重四道门 (§4.22.7) / 州五统计组
(§4.18.19: night 11944 / fort 11947 / river 11946 / amphibious 11945 / snow 12036)。


#### 4.0.15 链内深扫定址补注表 (e4 批 G 快裁 B 档集中落账; 置信 = 快裁级, 细作时升定案)
| e4a1_supply_chain | sub_140EC80C0 / 4456648 / 111 / **lam 1_5 叶 = 逐国脏检谓词** (书已有 EC80C0 缩写) / 旗失配/系数宏变/owned_states 变/首都州变 → 返 1 (需重算) / 四项检查直读 120B 记录 +112/+32/+88/+0; 书 lam1_5「结 |
| e4a2a_daily_big | sub_1401E0C60 / 603425 / 98 / **NCombatLog::CManager 逐国数组构建** (重置步11) / gs+2176 {data@2176, cap@2184, count@2188} 为每国 malloc(40/0x28) 建 NCombatLog::CManager ( |
| e4a2a_daily_big | sub_140E9D710 / 5751026 / 32 / **CStrategicNavyManager 构造** (重置步12 新建支) / 64B/0x40 海军战略管理器 ctor (基类 sub_1414E8460) / `*(a1) = &CStrategicNavyManager::vftable` |
| e4a2b_daily_small | sub_1401C66B0 / 3726812 / 21 / **scoped_ptr 取用器 thunk → gs+1704 (0x6A8) CCharacterManager** / 同上读 `*(gs+1704)` / thunk 体直证; L6309264 (重置尾步, e4a2a: CCharacterM |
| e4a2b_daily_small | sub_140E85ED0 / 2733133 / 15 / **突袭管理器目标表 fold = daily 序16 突袭半本体** (书「目标冷却递减」无地址即此) / 对突袭管理器 (gs+1008) 目标表 {数据@+216, 计数@+228} 逐条 (176B 步进) 调 sub_1414E9540 / 调 |
| e4a3_deleteunit | sub_140C04370 / 2731164 / CUnit::ClearExpeditionaryOwner / unit+476 > 0 且 type==0 时: sub_14070FF60(远征属主国, unit) 从属主国 idreg (国+760/+772) 摘除 → 清 unit+476 = 0 |
| e4b1a_tick_big | sub_140ED1DB0 / 6359617 / **情报前置聚合 pass** / 每活跃国遍历阵营/关联国集 (sub_1406CF6C0→sub_140D230E0), 逐国 32B 四象限求和 + 命中门 (obj+496 → +184 字节&3==0) 的关联国二分插入排序表 (sub_140ED1B6 |
| e4b1a_tick_big | sub_140D02C30 / 483182 / **四象限情报值计算核** / 静态池 ≤6 类 + 动态池 ≤7 类逐源 (sub_140D05A00) 累计 32B 四象限到 per-key 输出表, 末尾逐项按 INTEL_COUNTRY_LEVEL_MAXIMUMS (a4[0..3]) 钳位 / 锚 1 |
| e4b1a_tick_big | sub_140D02FB0 / 3639665 / **静态池键读取器** / 读 ci+160 {数据@160, 计数@172} 72B/池 (CStaticIntelSourcePool, 书已有) 逐池抽键 (sub_1411AD700) 入 24B 元列表 / 锚 1 唯一调用 L4968214; +160 |
| e4b1a_tick_big | sub_140D06820 / 1627263 / **CCountryIntel 静态源槽重建** / 清 +64 区 (sub_140D023D0) 与 +88 {c@100} 24B 列表后按静态池键列表重插 (sub_140CFF070) / 锚 1 唯一调用 L4968299; +64/+88 落在书 § |
| e4b1a_tick_big | sub_140D06820 / 1627263 / **CCountryIntel 静态源槽重建** / 清 +64 区 (sub_140D023D0) 与 +88 {c@100} 24B 列表后按静态池键列表重插 (sub_140CFF070) / 锚 1 唯一调用 L4968299; +64/+88 落在书 § |
| e4b1a_tick_big | sub_140D02EB0 / 713006 / **资源观测基准读** (4 键 mdef 549–552) / 断言 `_Owner.IsValid()` (countryintel.cpp:391) 后取 owner 国, 读 cc+1464 键 549/550/551/552 成 32B 四象限基准 / * |
| e4b1a_tick_big | sub_140E7A910 / 7788742 / **CProvince 重置** (ctor 内 (47,6)) / 逐省: sub_140E81180(+24)、清 +208/+216、+368 数组 (计数@380) vt[11]==1 → sub_140671660、+392 取值、清 5 计数器、+40 |
| e4b1a_tick_big | sub_140E7A910 / 7788742 / **CProvince 重置** (ctor 内 (47,6)) / 逐省: sub_140E81180(+24)、清 +208/+216、+368 数组 (计数@380) vt[11]==1 → sub_140671660、+392 取值、清 5 计数器、+40 |
| e4b1b_tick_small | sub_140D06670 / 3751725 / 情报 / **ci+16 intel 矩阵整体赋值半件** / 栈上矩阵描述子 {ptr@+0, count@+12} → 成员矩阵 {data@+16, count@+28}: 清计数 → sub_1401A8930 容量重灌 → memcpy 32B×coun |
| e4b1b_tick_small | sub_140D03640 / 5810858 / 情报 / **ci+160 static_intel_pools 逐池摘除半件** / 逐 72B 池 (CStaticIntelSourcePool) 调 sub_1411AEAD0 / 体直证 {data@+160, count@+172}; 调用点 L496 |
| e4b1b_tick_small | sub_140D071A0 / 4765376 / 情报 / **ci+184 dynamic_intel_pools 逐池日结 fold (钳 7)** / min(count@+196, 7) 逐 56B 池 (CDynamicIntelSourcePool) 调 sub_14197E590(池, 打包上下文) |
| e4b1b_tick_small | sub_14197E590（被调） / 405678 / 情报 / **动态池 accumulator 四象限逐元累加件** / 遍历池 +8 accumulator {d@+8, c@+20} 40B 元, sub_14197E370 三连逐元累加进栈上 v30 累加器, 喂打包上下文 / 体直证; 14197E |
| e4b1b_tick_small | sub_140D035C0 / 7844764 / 情报 / **ci+184 dynamic_intel_pools 逐池 fold #2 (无钳)** / 全量逐 56B 池调 sub_14197E8B0(池, a2[i], a2[i]+56 对数组实参) / 体直证 (同 +184/+196/56B 阵列); |
| e4b1b_tick_small | sub_140D02970 / 7937385 / 情报 / **ci+112 prev_day ← ci+88 当日 dynamic_pools 日界快照半件** / 转调 sub_140D023D0(ci+112, ci+88) / 体直证 (纯转发); 调用点 L4968298; +88/+112 槽名与 § |
| e4b1b_tick_small | sub_140D023D0（被调） / 5739045 / 情报 / (基础设施) 24B 元容器数组深拷贝件 / 清 dst (池还+计数归零) → sub_140D06B20 重灌 → 逐 24B 元 {data, cap, count, alloc} 置空后 sub_140D049B0 自 src 拷贝 |
| e4b1b_tick_small | sub_140D023D0（被调） / 5739045 / 情报 / (基础设施) 24B 元容器数组深拷贝件 / 清 dst (池还+计数归零) → sub_140D06B20 重灌 → 逐 24B 元 {data, cap, count, alloc} 置空后 sub_140D049B0 自 src 拷贝 |
| e4b1b_tick_small | sub_140716510 / 3824620 / 情报 / **CRadarsPool (cc+4344 内嵌) 日结 pass 包装** / 转调 sub_1410A99A0(cc+4344) / 体直证; 调用点 L4967852 (逐活国前置三连之一); cc+4344 = CRadarsPool (书 § |
| e4b1b_tick_small | sub_1407164F0 / 843761 / 情报 / **cc+5552 tokens scoped_ptr 解引用 → CCountryOperationTokenManager 日结 fold** / `sub_1414079B0(thunk(cc+5552))` / 体直证; 调用点 L4967853; |
| e4b1b_tick_small | sub_1407164F0 / 843761 / 情报 / **cc+5552 tokens scoped_ptr 解引用 → CCountryOperationTokenManager 日结 fold** / `sub_1414079B0(thunk(cc+5552))` / 体直证; 调用点 L4967853; |
| e4b1b_tick_small | sub_1401C3890 / 1700850 / 情报 / **情报结算 scratch 上下文双缓冲归还半件** / 两段: 槽 B {ptr@+24, 计数@+32/+36, owner@+40} 非空则 owner vtable[2] 释放并清零; 槽 A {data@+0, cap@+12, owner@ |
| e4b1b_tick_small | sub_1401C3890 / 1700850 / 情报 / **情报结算 scratch 上下文双缓冲归还半件** / 两段: 槽 B {ptr@+24, 计数@+32/+36, owner@+40} 非空则 owner vtable[2] 释放并清零; 槽 A {data@+0, cap@+12, owner@ |
| e4b1b_tick_small | sub_142233720 / 7862246 / ctor / **random 调用记录环 72 槽全清场半件** (确定性 RNG/OOS 调试基建) / 门旗 byte_14345252B 置位时, 72 槽 × 40B (槽区 143452540 起, 40B 步进) 逐槽: 头字段置 43800000 |
| e4b1b_tick_small | sub_140F0A990 / 800212 / ctor / **metrics 单例重置件** / 门 qword_14333D3E0 存在时: sub_140F10BB0 四连容器清 (a1/a1+64/a1/a1) + 字@+128、字节@+130 清零 + 双日期槽 @+144/@+168 = 43808 |
| e4b1b_tick_small | sub_140F0A990 / 800212 / ctor / **metrics 单例重置件** / 门 qword_14333D3E0 存在时: sub_140F10BB0 四连容器清 (a1/a1+64/a1/a1) + 字@+128、字节@+130 清零 + 双日期槽 @+144/@+168 = 43808 |
| e4b1b_tick_small | sub_140BC6010 / 7871358 / ctor / **CVariables (gs+2432) 启用条目清场半件** / 逐 48B 条目 {data@+24, count@+32}: 条目 +4 启用旗置位者调 sub_140153530 (MSVC 串释放, cap@+32/buf@+8) 并清 |
| e4b1b_tick_small | sub_1401AE6A0 / 2819986 / ctor / **系统启用位图 getter** (位图 = dword_14332F248) / `return dword_14332F248` / 体直证; 位图写者 sub_1401AEDA0 (逐位 /= 1/0x20/0x40/0x80/0x100/0 |
| e4b1b_tick_small | 12 / sub_1401C15F0 / scratch 单缓冲归还半件 (池 D7BA0), 入书轻 |
| e4b1b_tick_small | 13 / sub_1401C1870 / scratch 单缓冲归还半件 (池 D7CB0), 入书轻 |
| e4b1b_tick_small | 21 / sub_1401C14C0 / scratch owner 侧释放半件, 入书轻 |
| e4b2_dd6a30 | sub_140D46170 / 1179289 / 209 / **CDiplomacyStatus (cc+3976) 附属关系列表重建** / 从关系容器 (+8/+20) 筛 puppet 条目 (谓词 = 条目+648 描述符 token 12497 且宗主 tag 匹配) 重建 +368 tag 列表 / |
| e4b2_dd6a30 | sub_140DD7A60 / 3393639 / 153 / **阵营×附属关系网全局置脏 pass** (ingameidler 编译区) / 遍历 owned_states>0 的国 (cc+1156 门), 经 diplo+656 CFaction 收集成员附属列表 (diplo+368) 去重合并, 逐 |
| e4b2_dd6a30 | sub_140DD7A60 / 3393639 / 153 / **阵营×附属关系网全局置脏 pass** (ingameidler 编译区) / 遍历 owned_states>0 的国 (cc+1156 门), 经 diplo+656 CFaction 收集成员附属列表 (diplo+368) 去重合并, 逐 |
| e4b2_dd6a30 | sub_1406EB150 / 3557399 / 116 / **GenerateNonHistoricalAttributes (随机理念/特质授予)** / 扫 cc+3984 政治 +128 容器 (非历史旗 +56=0 者) 按 RNG 谓词 (sub_140FD3FC0/FD3B10) 授理念 (sub |
| e4b2_dd6a30 | sub_1406FEF10 / 5511629 / 110 / **舰队/舰船初始化重算** (country.cpp) / 构建期门 (gs+2613) 外逐 cc+632 舰队逐舰船 sub_140D7A7E0(ship,1) 重算, 再扫 sub_1406CF8C0(country) +88/+100 容器 |
| e4b2_dd6a30 | sub_1406FEF10 / 5511629 / 110 / **舰队/舰船初始化重算** (country.cpp) / 构建期门 (gs+2613) 外逐 cc+632 舰队逐舰船 sub_140D7A7E0(ship,1) 重算, 再扫 sub_1406CF8C0(country) +88/+100 容器 |
| e4b2_dd6a30 | sub_140715370 / 3448335 / 110 / **贸易影响 (trade influence) 全对缓存重建** (country.cpp) / 逐他国 sub_1407155C0 计算双边贸易影响入 +252 对表, 完成置 cc+264=1 缓存旗; 第二参真时校验他国 `_HasCached |
| e4b2_dd6a30 | sub_14070BC80 / 7749561 / 79 / **逐师上限钳制 + 逐舰载机重算** / 逐 cc+656 师容器元素: vt[+304](槽38) 取上限钳 unit+532 (sub_140C8F170); 逐 cc+632 舰队逐舰 sub_140D6EEB0 条目表逐项 sub_140C3D |
| e4b2_dd6a30 | sub_14070BC80 / 7749561 / 79 / **逐师上限钳制 + 逐舰载机重算** / 逐 cc+656 师容器元素: vt[+304](槽38) 取上限钳 unit+532 (sub_140C8F170); 逐 cc+632 舰队逐舰 sub_140D6EEB0 条目表逐项 sub_140C3D |
| e4b2_dd6a30 | sub_140EF9150 / 3634105 / 74 / **战区系统全局重置** (theatre 编译区) / 主线程断言后清零 theatre 区 ~12 个全局 (dword_14333D2CC 族 + 两 memset 区) 并调 6 个子重置 (sub_140EFAC10/EF9F40/EF88B0 |
| e4b2_dd6a30 | sub_140705950 / 2576223 / 72 / **逐舰队位置/归属重算** / 逐 cc+632 舰队: sub_140D54A30 强制重解 (清 +216 缓存 → 经 +168 位置查 sub_140EA4300 区域 → sub_140D59E00 回填), 条件分支走 sub_140D58 |
| e4b2_dd6a30 | sub_140705950 / 2576223 / 72 / **逐舰队位置/归属重算** / 逐 cc+632 舰队: sub_140D54A30 强制重解 (清 +216 缓存 → 经 +168 位置查 sub_140EA4300 区域 → sub_140D59E00 回填), 条件分支走 sub_140D58 |
| e4b2_dd6a30 | sub_1406FEE10 / 5762856 / 23 / **CProductionStatus (cc+3944) 生产线初始化** / 逐 +160/+172 生产线: sub_140BE2770 / sub_140BE2D20 / sub_140BE2620(line, +256 容器) 三连 / cc+ |
| e4b2_dd6a30 | sub_1406FEE10 / 5762856 / 23 / **CProductionStatus (cc+3944) 生产线初始化** / 逐 +160/+172 生产线: sub_140BE2770 / sub_140BE2D20 / sub_140BE2620(line, +256 容器) 三连 / cc+ |
| e4b2_dd6a30 | sub_1406FEE10 / 5762856 / 23 / **CProductionStatus (cc+3944) 生产线初始化** / 逐 +160/+172 生产线: sub_140BE2770 / sub_140BE2D20 / sub_140BE2620(line, +256 容器) 三连 / cc+ |
| e4b2_dd6a30 | sub_1406FF150 / 5767500 / 23 / **名称组 tracker (师/舰/…) 清空重置** / 对 cc+112 division_names_tracker / cc+120 ship_names_tracker / cc+136 族两槽各跑 sub_1409C5740 (清计数 +2 |
| e4b2_dd6a30 | sub_140E773D0 / 6832141 / 20 / **program_status (cc+4008) 逐项目向 idler 管理器登记置脏** / 逐项目条目 (+32/+44 容器, 类型 +28): idler vt[+128] 取管理器 → sub_140B53EE0 按型取槽 → 槽+5979 |
| e4b2_dd6a30 | sub_140BBAE50 / 4785877 / 17 / **gs+608 容器逐元素清旗 (两子对象)** (待裁) / 遍历 {data@+8, count@+20} 容器, 每元素对 +40/+48 两子对象跑 sub_1413E3F00 (清 +218 旗 + 玩家国门重估) / 唯二调用者 = 本锚 |
| e4b2_dd6a30 | sub_1401E1540 / 5815491 / 13 / **补给+铁路 init 对** / sub_1401C6D30(gs+984) → sub_140EC97A0 (CSupplySystem init) + sub_1401C6AB0(gs+992) → sub_140E94B20 (铁路 init) |
| e4b2_dd6a30 | sub_1401E1540 / 5815491 / 13 / **补给+铁路 init 对** / sub_1401C6D30(gs+984) → sub_140EC97A0 (CSupplySystem init) + sub_1401C6AB0(gs+992) → sub_140E94B20 (铁路 init) |
| e4b2_dd6a30 | sub_1401E1120 / 6871782 / 11 / **gs+1824 ← 进度 marker id** / *(gs+1824) = sub_142233FA0("gamestate.cpp", 2432) / 源定位串; gs+1824 槽本单新识 (与书 gs 表核对为空位) / **入书** (轻 |
| e4b2_dd6a30 | sub_140705930 / 3820811 / 11 / **rs (cc+4600) 租借/护航条目逐条重算** / rs 存在时逐 +1808/+1820 条目: 取条目+128 对象 → owner tag (对象+204) → sub_141228A70 计算回写条目+984 / 调用点紧跟 sub_1 |
| e4b2_dd6a30 | sub_140B51FF0 / 1779156 / 7 / **铁路逐国重算驱动 (包装)** / 经 idler vt[+128] 管理器取上下文 → sub_1415AE6C0(ctx): gs+992 铁路管理器逐国 (+68 旗门) sub_1415AA8B0 / sub_1415AE6C0 内直读 gs+ |
| e4b2_dd6a30 | sub_140B51FF0 / 1779156 / 7 / **铁路逐国重算驱动 (包装)** / 经 idler vt[+128] 管理器取上下文 → sub_1415AE6C0(ctx): gs+992 铁路管理器逐国 (+68 旗门) sub_1415AA8B0 / sub_1415AE6C0 内直读 gs+ |
| e4b2_dd6a30 | sub_1406FF1E0 / 7937630 / 7 / **rs 控制州联动重算** / `sub_140CB5010(*(cc+4600))`: 按 owner controlled_states (cc+1120) 过滤重算 rs +1808/+1820 条目 / 单跳转体; sub_140CB5010 直 |
| e4c1a_order_big | sub_140DC9860 / 1931344 / 670 / **框选主实现 (CInGameIdler 拖框→世界视锥→按类型收单位)** / 清选择 → 框 8 角反投影成 6 平面视锥 → 按类型优先级表逐类查可视对象 → 过 can-add 门后逐个加入选择集 / 8×sub_1422D8920 (角点+ |
| e4c1a_order_big | sub_140DC9860 / 1931344 / 670 / **框选主实现 (CInGameIdler 拖框→世界视锥→按类型收单位)** / 清选择 → 框 8 角反投影成 6 平面视锥 → 按类型优先级表逐类查可视对象 → 过 can-add 门后逐个加入选择集 / 8×sub_1422D8920 (角点+ |
| e4c1a_order_big | sub_140DC9860 / 1931344 / 670 / **框选主实现 (CInGameIdler 拖框→世界视锥→按类型收单位)** / 清选择 → 框 8 角反投影成 6 平面视锥 → 按类型优先级表逐类查可视对象 → 过 can-add 门后逐个加入选择集 / 8×sub_1422D8920 (角点+ |
| e4c1a_order_big | sub_140B54210 / 3117605 / 398 / **点选收集器 (屏幕点→可选对象; 同省多队轮选)** / 三拾取面射线命中单位 (同省叠队从现选位次循环轮转) → 失败落省 id 图拾取, 返回 selectable (对象+8) / 断言 "Implement selection test" |
| e4c1a_order_big | sub_140B54210 / 3117605 / 398 / **点选收集器 (屏幕点→可选对象; 同省多队轮选)** / 三拾取面射线命中单位 (同省叠队从现选位次循环轮转) → 失败落省 id 图拾取, 返回 selectable (对象+8) / 断言 "Implement selection test" |
| e4c1a_order_big | sub_141816E80 / 2137648 / 328 / **海军选择混编吞点击 (naviesview)** / 海军模式 (+257) 下右键点省: 把选择集中的舰队 (type 11 直选 ∪ type 1 任务舰队经 sub_140D64500 归并父舰队去重) 逐个 sub_141816DE0 重指 |
| e4c1a_order_big | sub_140B53890 / 4266144 / 248 / **屏幕点→世界坐标反投影 (三拾取面)** / 对至多 3 个拾取面 (obj+32+16 / +560 / +1104, 门旗 +1784/+1648/+1649) 各射线步进取 ≤256 命中点, 取距屏点最近者; 全空落地图平面交兜底 (sub |
| e4c1a_order_big | sub_140B53890 / 4266144 / 248 / **屏幕点→世界坐标反投影 (三拾取面)** / 对至多 3 个拾取面 (obj+32+16 / +560 / +1104, 门旗 +1784/+1648/+1649) 各射线步进取 ≤256 命中点, 取距屏点最近者; 全空落地图平面交兜底 (sub |
| e4c1a_order_big | sub_140B53890 / 4266144 / 248 / **屏幕点→世界坐标反投影 (三拾取面)** / 对至多 3 个拾取面 (obj+32+16 / +560 / +1104, 门旗 +1784/+1648/+1649) 各射线步进取 ≤256 命中点, 取距屏点最近者; 全空落地图平面交兜底 (sub |
| e4c1a_order_big | sub_140B6C390 / 7569269 / 95 / **CInGameInterfaceHandler 省点击分派 (SelectProvince)** / 记 +192 当前省 id 后按地图模式分派: 模式表非空调 lambda 'SelectProvince' 经 sub_140DFD540; 模式 |
| e4c1a_order_big | sub_140B6AC80 / 6683001 / 73 / **点中对象向地图视图态接纳 (SelectProvince 前置)** / 对点中 selectable 做视图侧登记: type 6 → +528 表查 (sub_1417A10C0), type 4 → +520 表查 (sub_14129AB00 |
| e4c1a_order_big | sub_140B6AC80 / 6683001 / 73 / **点中对象向地图视图态接纳 (SelectProvince 前置)** / 对点中 selectable 做视图侧登记: type 6 → +528 表查 (sub_1417A10C0), type 4 → +520 表查 (sub_14129AB00 |
| e4c1a_order_big | sub_140BC2D80 / 2611763 / 64 / **CSelectionSet::Remove (selectable.cpp:82/104)** / 链表查 obj 摘除 (sub_140BC3260); a3 真 → sub_140BC30F0 全量反选通知, 假 → 仅清 selectable+ |
| e4c1a_order_big | sub_140BC2D80 / 2611763 / 64 / **CSelectionSet::Remove (selectable.cpp:82/104)** / 链表查 obj 摘除 (sub_140BC3260); a3 真 → sub_140BC30F0 全量反选通知, 假 → 仅清 selectable+ |
| e4c1a_order_big | sub_140B669A0 / 677447 / 59 / **选中省 refid 表→对象指针数组收集** / 遍历 handler+768 {计数@+780} 8 字节 refid 表, 非零项经 sub_14221F310 解引用后 1.5 倍扩容推入出参数组 / 供锚 ESC 路判空 (数组计数 = v15 |
| e4c1a_order_big | sub_142081C30 / 4759631 / 33 / **控制台输入面板历史 ↓ (下一条)** / 面板激活 (+124) 时历史索引 +1 (上限 计数-1), 走 +128 节点链 (next@+40) 取条目 → sub_1422F27C0 回填编辑框 → sub_1422F4D80 刷新 / 全局 |
| e4c1a_order_big | sub_142081C30 / 4759631 / 33 / **控制台输入面板历史 ↓ (下一条)** / 面板激活 (+124) 时历史索引 +1 (上限 计数-1), 走 +128 节点链 (next@+40) 取条目 → sub_1422F27C0 回填编辑框 → sub_1422F4D80 刷新 / 全局 |
| e4c1a_order_big | sub_142081C30 / 4759631 / 33 / **控制台输入面板历史 ↓ (下一条)** / 面板激活 (+124) 时历史索引 +1 (上限 计数-1), 走 +128 节点链 (next@+40) 取条目 → sub_1422F27C0 回填编辑框 → sub_1422F4D80 刷新 / 全局 |
| e4c1a_order_big | sub_142081C30 / 4759631 / 33 / **控制台输入面板历史 ↓ (下一条)** / 面板激活 (+124) 时历史索引 +1 (上限 计数-1), 走 +128 节点链 (next@+40) 取条目 → sub_1422F27C0 回填编辑框 → sub_1422F4D80 刷新 / 全局 |
| e4c1a_order_big | sub_1420805C0 / 742220 / 55 / **控制台输入面板历史 ↑ (上一条)** / 索引 -1 回溯; 索引归 0 再按时恢复草稿 (sub_1422F27D0(&Buf2)) 并置 -1 / 同上; 与 1C30 成对 / **入书 (轻)**: 同上 |
| e4c1a_order_big | sub_142081140 / 3704393 / 40 / **控制台面板值步进 +** / 同上取 + 步长写回 / 同上; 锚键 0x4000001E 分支 / **入书 (轻)**: 同上 |
| e4c1a_order_big | sub_140F41710 / 7754217 / 40 / **下令允许谓词 (UI 阻塞判定)** / 当前面板/视图无阻塞 (子窗 +128/+136 空或 +688 旗、+144/+544/+545/+608 忙旗清、修饰键与地图模式组合、铁路炮工具 sub_140E8B6D0 假、sub_140F498E |
| e4c1a_order_big | sub_140F41710 / 7754217 / 40 / **下令允许谓词 (UI 阻塞判定)** / 当前面板/视图无阻塞 (子窗 +128/+136 空或 +688 旗、+144/+544/+545/+608 忙旗清、修饰键与地图模式组合、铁路炮工具 sub_140E8B6D0 假、sub_140F498E |
| e4c1a_order_big | sub_140DDFA60 / 1676633 / 33 / **选择集成员加入门 (逐成员过滤)** / 成员过 vt[+40] 门 → 属主同 (sub_140BFD3F0 相等) 且 (组 id *(成员+480) 相等或双方非零经 sub_140BB52F0 判同) → sub_140BC32D0 加入 |
| e4c1a_order_big | sub_140B69010 / 3662398 / 24 / **ESC 全局取消链 (单机分支)** / *(idler+1720+536) 未完态时: 取 idler+384 会话对象, RTTI 排除 CNetworkServer/CProxyServer 且 vt[+744] 假 → vt[+752](…, |
| e4c1b_order_small | sub_142272F40 / 1710148 / L3920099 / **字符键码匹配谓词** / 同上形态, 期望键 = sub_1422686D0(字符) (char→keycode, pdxkeys.cpp 断言串) / 体直证; 锚内消费 'h'(104) → sub_140DDCAB0 取消移动 (§ |
| e4c1b_order_small | sub_140D11940 / 1802030 / L3919899 等 ×8 / **事件鼠标载荷指针取件 (+72)** / `return a1+72` (纯偏移访问器) / 体直证 (2 拍); 与 sub_14139E9B0/A0 成对消费 {+72,+76}; 全语料 234 处高频通用访问器 (§4. |
| e4c1b_order_small | sub_14139E9A0 / 1802142 / L3920109/0120/0186/0225 / **相位读取器 (事件+76 u32)** / `return *(u32*)(a1+4)` (1=press, 2=release) / 体直证; ==1 → ping/拖拽锚支, ==2 → 下令支 (§4. |
| e4c1b_order_small | sub_142081040 / 4818735 / L3919930 / **数值步进聚焦件关闭半件** / 调 `*(焦点件+104)+48` 对象 vt[16] 后 `*(焦点件+124)=0` (去激活) / 体直证; 焦点件 = 全局 qword_14344A590 (sub_1420804B0 mallo |
| e4c1b_order_small | sub_1420812A0 / 3765888 / L3919937 / **数值步进聚焦件开启半件** / vt[15] + sub_1422AE130(GUI 状态字节+116 置 bit4 清 bit5) + 属主 vt[12] + `+124=1` / 体直证; 门 = 控制台管理器 qword_1435E |
| e4c1b_order_small | sub_1417CD970 / 5772664 / L3920202 / **攻击 ping is_offensive 旗解析器** / 当前 Shift∧Ctrl (iface vt[7]∧[6]) 真时: 锁 A(+5242) 未锁 → 取 vt[5] 否则 1; 假时: 锁 A → 1, 锁 B(+5243) |
| e4c1b_order_small | sub_1417CD970 / 5772664 / L3920202 / **攻击 ping is_offensive 旗解析器** / 当前 Shift∧Ctrl (iface vt[7]∧[6]) 真时: 锁 A(+5242) 未锁 → 取 vt[5] 否则 1; 假时: 锁 A → 1, 锁 B(+5243) |
| e4c1b_order_small | sub_1417CD970 / 5772664 / L3920202 / **攻击 ping is_offensive 旗解析器** / 当前 Shift∧Ctrl (iface vt[7]∧[6]) 真时: 锁 A(+5242) 未锁 → 取 vt[5] 否则 1; 假时: 锁 A → 1, 锁 B(+5243) |
| e4c1b_order_small | sub_140B64FF0 / 7936647 / L3920292 / **关闭当前界面视图包装** / `sub_140B65430(handler, *(u32*)(handler+1008), 0)` / 体直证; 被调断言串 ingameinterfacehandler.cpp:2598 直证类名; +1 |
| e4c1b_order_small | sub_140B65400 / 7883027 / L3920417 / **框选前置: handler+192 写归一化 tag + 关视图 0** / `*(u32*)(handler+192) = *sub_140BB3E00(&v, 0)` (gs 国链解析, gamestate.cpp:0x1D60) → |
| e4c1b_order_small | sub_1415B76D0 / 6843074 / L3920159 / **联队(空军翼)选中判定** / idler 全局 qword_14332F6A0 +1336 首元素 `+8 == 2` / 体直证; 消费 = 真 → sub_1415B72C0 投 CStratAirEnableMissionComm |
| e4c2b_boot_small | sub_140145C80 / 6791214 / 1 / **CDatabaseReloader\<CScriptedEffectTemplateDatabase\> 构造器** / 装 vtable + 槽 +8 看柄清零; 路径非空且调试门开时经 sub_14224D3B0 注册 "common/script |
| e4c2b_boot_small | sub_140145C80 / 6791214 / 1 / **CDatabaseReloader\<CScriptedEffectTemplateDatabase\> 构造器** / 装 vtable + 槽 +8 看柄清零; 路径非空且调试门开时经 sub_14224D3B0 注册 "common/script |
| e4c2b_boot_small | sub_1401750E0 / 1801632 / 1 / (基建) **std::function 取用 invoke 适配器** (reloader 家族回调道) / `return vtable[2](a1)` — 被 reloader 构造器装进 `_Func_impl_no_alloc` 作 invoke |
| e4c2b_boot_small | sub_1401543D0 / 882121 / 1 / **CReloadDispatcher vtable 装配半件** / `*a1 = &CReloadDispatcher::vftable` (基类构造头两拍) / 体直证 (RTTI 名直证); 锚1 内 8 处 (L5971613/1675/1731/ |
| e4c2b_boot_small | sub_1401498B0 / 1683594 / 1 / **localisation 目录 watcher 注册件** (无 reloader 载体, 仅落看柄) / 调试门开时 sub_14224D3B0({"localisation",12}, 1, 回调 sub_140193F80, NULL) → dw |
| e4c2b_boot_small | sub_1401498B0 / 1683594 / 1 / **localisation 目录 watcher 注册件** (无 reloader 载体, 仅落看柄) / 调试门开时 sub_14224D3B0({"localisation",12}, 1, 回调 sub_140193F80, NULL) → dw |
| e4c2b_boot_small | sub_14014C370 / 6794230 / 1 / **NCareerProfile::SGameModeStatistics 构造器** / 装 vtable + 两子结构 (sub_14014C2E0 @+8/+88) + 槽 a1[8]/a1[9] 清零 + a1[10]=&off_143085170 |
| e4c2b_boot_small | sub_14014C370 / 6794230 / 1 / **NCareerProfile::SGameModeStatistics 构造器** / 装 vtable + 两子结构 (sub_14014C2E0 @+8/+88) + 槽 a1[8]/a1[9] 清零 + a1[10]=&off_143085170 |
| e4c2b_boot_small | sub_1422333C0 / 5894599 / 1 / **CPdxSystem 单例工厂 getter** / 返回 qword_143452500 (lazy ctor sub_1422333D0 = `CPdxSystem::vftable`; 槽[1] 为对象工厂, 产品同时落全局 qword_1434 |
| e4c2b_boot_small | sub_1422333C0 / 5894599 / 1 / **CPdxSystem 单例工厂 getter** / 返回 qword_143452500 (lazy ctor sub_1422333D0 = `CPdxSystem::vftable`; 槽[1] 为对象工厂, 产品同时落全局 qword_1434 |
| e4c2b_boot_small | sub_1423A9D40 / 1717864 / 2 / (基建) **STT 槽 lazy 分配半件** / qword_1435BA090 空则 malloc(8) 置空槽 (scoped_ptr 载体) / 体直证; 锚2 L4226793 (首拍), 填充件 sub_1423A9E40 后拍 / 不单列入 |
| e4c2b_boot_small | sub_1423A9D40 / 1717864 / 2 / (基建) **STT 槽 lazy 分配半件** / qword_1435BA090 空则 malloc(8) 置空槽 (scoped_ptr 载体) / 体直证; 锚2 L4226793 (首拍), 填充件 sub_1423A9E40 后拍 / 不单列入 |
| e4c2b_boot_small | sub_142254570 / 2819769 / 2 / **HotkeyManager 单例 getter** / `return qword_1434531A8` (lazy ctor sub_142254A50 = `HotkeyManager::vftable` 264B) / 体直证 + 写者 sub_ |
| e4c2b_boot_small | sub_142254570 / 2819769 / 2 / **HotkeyManager 单例 getter** / `return qword_1434531A8` (lazy ctor sub_142254A50 = `HotkeyManager::vftable` 264B) / 体直证 + 写者 sub_ |
| e4c2b_boot_small | sub_1422551C0 / 792683 / 2 / **HotkeyManager 首启初始化半件** (once 旗 byte_1434531B0) / 首次: sub_14224DC90(a1+40) 启时钟 + double@+248/+256 = 实参双浮点; 再入返回 0 / 体直证; 锚2 L42 |
| e4c2b_boot_small | sub_1422551C0 / 792683 / 2 / **HotkeyManager 首启初始化半件** (once 旗 byte_1434531B0) / 首次: sub_14224DC90(a1+40) 启时钟 + double@+248/+256 = 实参双浮点; 再入返回 0 / 体直证; 锚2 L42 |
| e4c2b_boot_small | sub_1401FAE10 / 7948003 / 2 / (单 accessor) **CSettings +952 double getter** / `return *(double*)(settings+952)` (单例 getter sub_1401FA5E0 = qword_14332F408 = C |
| e4c2b_boot_small | sub_140B39270 / 5874888 / 2 / **全局外链回调槽重置件** / `qword_1434811A0=0; qword_1434811A8=&sub_140B38740` (默认实现 = `ShellExecuteA(0,"open",url,0,0,1)`; 设置字节 CSettings |
| e4c2b_boot_small | sub_140B39270 / 5874888 / 2 / **全局外链回调槽重置件** / `qword_1434811A0=0; qword_1434811A8=&sub_140B38740` (默认实现 = `ShellExecuteA(0,"open",url,0,0,1)`; 设置字节 CSettings |
| e4c2b_boot_small | sub_140B39270 / 5874888 / 2 / **全局外链回调槽重置件** / `qword_1434811A0=0; qword_1434811A8=&sub_140B38740` (默认实现 = `ShellExecuteA(0,"open",url,0,0,1)`; 设置字节 CSettings |
| e4c2b_boot_small | sub_14222E1B0 / 7947332 / 2 / **LoadAssets 步薄包装** / 转调 sub_14222DDC0(a1, a2, 0, 0) / 体直证 (纯转发); 锚2 L4226910: 实参 LOBYTE(v34)=1 + 紧随 gameapplication.cpp:849 "Lo |
| e4c2b_boot_small | sub_140643800 / 2812680 / 2 / **平台 variant 单例 getter** / `return qword_1433304E0` (120B; swap-in 件 sub_140643870 = 锚2 L4226797 每启动换新实例; ctor sub_1406434B0 纯清零 |
| e4c2b_boot_small | sub_140643800 / 2812680 / 2 / **平台 variant 单例 getter** / `return qword_1433304E0` (120B; swap-in 件 sub_140643870 = 锚2 L4226797 每启动换新实例; ctor sub_1406434B0 纯清零 |
| e4c2b_boot_small | sub_140643800 / 2812680 / 2 / **平台 variant 单例 getter** / `return qword_1433304E0` (120B; swap-in 件 sub_140643870 = 锚2 L4226797 每启动换新实例; ctor sub_1406434B0 纯清零 |
| e4c2b_boot_small | sub_142075EB0 / 3843260 / 2 / **PHYSFS 挂载管理器 getter** (无 lazy) / `return qword_14344A568` (200B 无 vtable; lazy 版 sub_142078180 + ctor sub_142075200) / 体直证; 消费 |
| e4c2b_boot_small | sub_142075EB0 / 3843260 / 2 / **PHYSFS 挂载管理器 getter** (无 lazy) / `return qword_14344A568` (200B 无 vtable; lazy 版 sub_142078180 + ctor sub_142075200) / 体直证; 消费 |
| e4c2b_boot_small | sub_142075EB0 / 3843260 / 2 / **PHYSFS 挂载管理器 getter** (无 lazy) / `return qword_14344A568` (200B 无 vtable; lazy 版 sub_142078180 + ctor sub_142075200) / 体直证; 消费 |
| e4c2b_boot_small | sub_140643810 / 5802228 / 2 / **平台 variant Steam 判定件** / `SteamAPI_IsSteamRunning() && sub_1423C1CE0()==1 && sub_140643D00(a1, 挂载mgr+104)` 全过则走 Steam 解析; 否则兜底 |
| e4c2b_boot_small | sub_140643810 / 5802228 / 2 / **平台 variant Steam 判定件** / `SteamAPI_IsSteamRunning() && sub_1423C1CE0()==1 && sub_140643D00(a1, 挂载mgr+104)` 全过则走 Steam 解析; 否则兜底 |
| e4c2b_boot_small | sub_140643810 / 5802228 / 2 / **平台 variant Steam 判定件** / `SteamAPI_IsSteamRunning() && sub_1423C1CE0()==1 && sub_140643D00(a1, 挂载mgr+104)` 全过则走 Steam 解析; 否则兜底 |
| e4c2b_boot_small | sub_140643810 / 5802228 / 2 / **平台 variant Steam 判定件** / `SteamAPI_IsSteamRunning() && sub_1423C1CE0()==1 && sub_140643D00(a1, 挂载mgr+104)` 全过则走 Steam 解析; 否则兜底 |
| e4c3a_part1 | sub_1424BD740 / 6342071 / 解析器/lexer / lexer token 表构建（`pdx_parser/lexer.cpp` 直证，`!_TokenTree.Contains(Key)` 断言；editor 锚 ×1） / 定案 / **值得**：token 表构建路径与 GAME.la |
| e4c3b_part1 | sub_140D030E0 / 3517294 / 外交/谍报 / 情报来源池族复位（RTTI 直证 **CDynamicIntelSourcePool**：6×72B 池条目 + 7×56B 池对象补齐至下限；非锚调用方 sub_140243250 "Invalid pool name: " 池名查证）；锚一调 |
| e4c3b_part1 | sub_140D030E0 / 3517294 / 外交/谍报 / 情报来源池族复位（RTTI 直证 **CDynamicIntelSourcePool**：6×72B 池条目 + 7×56B 池对象补齐至下限；非锚调用方 sub_140243250 "Invalid pool name: " 池名查证）；锚一调 |
| e4c3b_part1 | sub_140639060 / 6776767 / 政治/内政（规则） / **CRuleOverrides 复位**：28 槽逐一从默认表恢复（qword_1433304C0+50，56B 步进默认字节 + 92 处旗清 + 28×32B 数组重置 sub_1424CB690 + 链表清）；锚一对 cc+1640 |
| e4c3c_part1 | sub_140E1B280 / 2883936 / 1409 行 / 地图模式着色 / **idler「国家视图应用链」更新步内的逐省着色计算**：a2 虚表[25] 取地图模式对象 v5，先走 sub_140F4A200 批量旗路径（pdx_scoped_buffer + gs+700 省数粒度、省下标从 1 起 |
| e4c3c_part1 | sub_140E1B280 / 2883936 / 1409 行 / 地图模式着色 / **idler「国家视图应用链」更新步内的逐省着色计算**：a2 虚表[25] 取地图模式对象 v5，先走 sub_140F4A200 批量旗路径（pdx_scoped_buffer + gs+700 省数粒度、省下标从 1 起 |
| e4c3c_part1 | sub_140E1B280 / 2883936 / 1409 行 / 地图模式着色 / **idler「国家视图应用链」更新步内的逐省着色计算**：a2 虚表[25] 取地图模式对象 v5，先走 sub_140F4A200 批量旗路径（pdx_scoped_buffer + gs+700 省数粒度、省下标从 1 起 |
| e4c3c_part1 | sub_140E1B280 / 2883936 / 1409 行 / 地图模式着色 / **idler「国家视图应用链」更新步内的逐省着色计算**：a2 虚表[25] 取地图模式对象 v5，先走 sub_140F4A200 批量旗路径（pdx_scoped_buffer + gs+700 省数粒度、省下标从 1 起 |
| e4c3c_part2 | sub_140B572D0 / 6073765 / 563 行 / 地图叠加绘制/渲染 / 双 idler 槽[29] 帧渲染共用的**地图叠加绘制层**（part1 高置信）：淡入淡出钳位动画（+1728/+1732/+316）→ 箭头渲染状态机启停（1422D9D70/DAC30 对，箭头状态对象 = 锚一 a |
| e4c3c_part2 | sub_140B572D0 / 6073765 / 563 行 / 地图叠加绘制/渲染 / 双 idler 槽[29] 帧渲染共用的**地图叠加绘制层**（part1 高置信）：淡入淡出钳位动画（+1728/+1732/+316）→ 箭头渲染状态机启停（1422D9D70/DAC30 对，箭头状态对象 = 锚一 a |
| e4c3c_part2 | sub_140B572D0 / 6073765 / 563 行 / 地图叠加绘制/渲染 / 双 idler 槽[29] 帧渲染共用的**地图叠加绘制层**（part1 高置信）：淡入淡出钳位动画（+1728/+1732/+316）→ 箭头渲染状态机启停（1422D9D70/DAC30 对，箭头状态对象 = 锚一 a |
| e4c3c_part2 | 3. **sub_140E8AC00（railway_gun.cpp 直证，定案）** — RAILWAY_GUN_POSSIBLE_RANGES define 数组 @qword_1433399E0 按 100000 档位取值；与 part1 待裁件 sub_140E89B80（扫描取极值消费方）合看可一笔入书军事域 |
| e4c3c_part2 | 3. **sub_140E8AC00（railway_gun.cpp 直证，定案）** — RAILWAY_GUN_POSSIBLE_RANGES define 数组 @qword_1433399E0 按 100000 档位取值；与 part1 待裁件 sub_140E89B80（扫描取极值消费方）合看可一笔入书军事域 |
| e4d1_part1 | 5 / 3919 / sub_1424FEF40 (6971300) / 数据/查表 / 编译期 id 重映射 switch 表：连续区段平移（如 71896→71864）+ 恒等段；调用方形态 = 对 u32 数组逐元原位重映射（sub_142502B10），读档迁移/重排修正族 / 推定 / A |
| e4d1_part1 | 5 / 3919 / sub_1424FEF40 (6971300) / 数据/查表 / 编译期 id 重映射 switch 表：连续区段平移（如 71896→71864）+ 恒等段；调用方形态 = 对 u32 数组逐元原位重映射（sub_142502B10），读档迁移/重排修正族 / 推定 / A |
| e4d1_part2 | 24 / sub_1423CE9C0 / 1305 / 情报（推定） / 零串巨函；唯一实质被调 = sub_1423CDE10 ×2（countryintel.cpp 直证件）；上游链 1423C6F10 → 1423CC600 → 本件全零串 / 推定 / A（身份待裁） |
| e4d1_part2 | 24 / sub_1423CE9C0 / 1305 / 情报（推定） / 零串巨函；唯一实质被调 = sub_1423CDE10 ×2（countryintel.cpp 直证件）；上游链 1423C6F10 → 1423CC600 → 本件全零串 / 推定 / A（身份待裁） |
| e4g_part02 | 14 / 444 / sub_140C14160 (1047544) / 军事/角色 / CUnitLeader 对象工厂：`units/unitleader.cpp` + malloc **0x10B8=4280** + ctor sub_140C0B7D0（从 character 实例化将领对象）；CUnitL |
| e4g_part02 | 14 / 444 / sub_140C14160 (1047544) / 军事/角色 / CUnitLeader 对象工厂：`units/unitleader.cpp` + malloc **0x10B8=4280** + ctor sub_140C0B7D0（从 character 实例化将领对象）；CUnitL |
| e4g_part02 | 26 / 412 / sub_140729470 (1014913) / 事件/scope / CEventScope 取州对象原语：`eventscope.h` assert `pScope == this \/\/ pScope->_pFrom != this` + 读 scope+168（书 §4.00.4 |
| e4g_part10 | 1 / 163 / sub_140F84680 (3290476) / 空军/空投任务 / 空投（paradrop）任务执行分叉：被调 sub_140E7EE70 = 空降落地处理（part06 #14 定案，on_units_paradropped_in_state）+ 0x140F5/F6 机翼族 + sub_ |
| e4g_part10 | 4 / 162 / sub_140736C30 (7469983) / 决议/任务 / decision 定时链到期清扫编排：调 **timeout_effect 执行器 #5 ×1 + cancel_effect 执行器 #26 ×2** + scope 构造族 sub_140535110/53A610/544C |
| e4g_part10 | 5 / 162 / sub_140728D60 (7443595) / 决议/任务 / **timeout_effect 字段执行器**（串直证）：eventscope.h `pScope == this \/\/ pScope->_pFrom != this` 断言 + CEventScope 清场族 sub_1 |
| e4g_part10 | 12 / 159 / sub_1406685B0 (3351275) / AI / AI UpdateStrategy 内步（领导策略/省集容器重建）：调 sub_140D3CA30（AI 省集/前线容器装配，part05 #12 B）+ sub_140666BC0 + 0x14064 AI 容器族；唯一调用方 = |
| e4g_part11 | 6 / 148 / sub_14152B030 (2355432) / 地理/州归属解析 / 谓词收国集原语：gs+784 国表逐国（country+1156 >0 门）过 sub_140700280/sub_140700600 双谓词后收 qword 向量；供归属解析簇作候选源（sub_14152A2B0 体内首 |
| e4g_part11 | 9 / 148 / sub_140F66BE0 (5587740) / 空军 / CAirWing `_StatsPerMission` remap 重建器：18 位任务掩码 → remap int8[18] 逐位填槽号（a1+24..+41）+ 统计条目数组对齐条数（624B/条，sub_140F596E0 零构 |
| e4g_part11 | 22 / 144 / sub_141A26700 (4377641) / 军事/行动 / CCreateOperationCommand 建令工厂（88B）：+40/+41 ← a3+64/+65、+44 ← 行动定义 id（a3+72 解引）、+48 特工委派 12B 数组（sub_140F2B4A0）、+72 |
| e4g_part12 | sub_140713AD0（138 行，#12） / 军事/投降链 / part03 #11（投降链事件装配 sub_140704380）步内补行：预算 *(+672) 比例扣减 + 最大余额补差（对象 +3944→+664），分配对象类别细作时定（疑舰队/资产分割） |
| e4g_part12 | sub_140727010（135 行，#28） / 政治/决议 / 决议域册（part09 #32 同节）补决议目标 tag 清单构建：容器形态分支（sub_140C2BEF0 取清单 / sub_140C2CAF0 门+遍历有效国）→ 24B 条目 {tag,id,旗} 压表 sub_140722480 |
| e4g_part12 | sub_140727010（135 行，#28） / 政治/决议 / 决议域册（part09 #32 同节）补决议目标 tag 清单构建：容器形态分支（sub_140C2BEF0 取清单 / sub_140C2CAF0 门+遍历有效国）→ 24B 条目 {tag,id,旗} 压表 sub_140722480 |
| e4g_part12 | sub_140727010（135 行，#28） / 政治/决议 / 决议域册（part09 #32 同节）补决议目标 tag 清单构建：容器形态分支（sub_140C2BEF0 取清单 / sub_140C2CAF0 门+遍历有效国）→ 24B 条目 {tag,id,旗} 压表 sub_140722480 |
| e4g_part12 | sub_140727010（135 行，#28） / 政治/决议 / 决议域册（part09 #32 同节）补决议目标 tag 清单构建：容器形态分支（sub_140C2BEF0 取清单 / sub_140C2CAF0 门+遍历有效国）→ 24B 条目 {tag,id,旗} 压表 sub_140722480 |
| e4g_part14 | 9 / 119 / sub_1409C62C0 (4474518) / 军事/师命名 / divisionnamesdatabase.cpp:316 "!Invalid value" / 319 "!not supported" 直证：按 a1+96 命名库种类 (0..3) 分派取名（0/1/2 → sub_14 |
| e4g_part14 | 9 / 119 / sub_1409C62C0 (4474518) / 军事/师命名 / divisionnamesdatabase.cpp:316 "!Invalid value" / 319 "!not supported" 直证：按 a1+96 命名库种类 (0..3) 分派取名（0/1/2 → sub_14 |
| e4g_part14 | 18 / 117 / sub_14109A2A0 (3427022) / 军事/核弹 / nuke.cpp:583/586 直证：建 CEventScope（FROM = *(a2+192)+88 属主 tag）→ itemdatabase（qword_14332EFA0，gameitemdatabase.h:14 |
| e4g_part14 | 25 / 116 / sub_140A0CC30 (5648171) / 事件/资产装载 / 事件命名条目 → 0x38 节点搬移（string + 3 qword，move 语义清源串）；调用方 = "Events loaded" 宿主 sub_140A0C190 + "Short Task" 宿主 sub_14 |
| e4g_part15 | 8 / 114 / sub_1411F88E0 (516781) / 谍报/情报网 / (tag,id) 清单解析（sub_14221F310）→ tag 过滤 → 48B 输出条目构建（两 vt+88 取值 + sub_140C19190 格式化 + +288 容器三级下钻）；双调用方 0x1411F/0x141 |
| e4g_part15 | 11 / 114 / sub_140CD1AE0 (3432810) / career/成就 / career profile 工时计数步进件：+544 InterlockedIncrement → 24/8760（时→日/年）阈值比较 → 达门 sub_1406A4D60 推进（码 2）+ 玩家 tag 门镜像； |
| e4g_part15 | 40 / 108 / sub_140B532E0 (7684842) / GUI/地图标签 / 同 id 连通块泛洪收集件：省 idx@+164 标记位图（pdx_scoped_buffer）+ 邻接表（条目+184 → 48B 步距邻居）+ 池分配 + id 回调匹配 BFS；6 调用点全 = **分组条目表重建 |
| e4g_part17 | sub_140CFA4F0（100 行，#20） / 军事/人力统计查询 / 落点候选 = 人力统计命名槽采集体 sub_140CFCB10（0x140CF 区，MANPOWER_USAGE 系十余命名槽，若主 agent 认为该采集器值得入书再随册细作）；细作先裁 army+976 子对象与 gs+3952 容器 |

| 来源 | 函数与身份 / 建议落点 |
|---|---|
| part16 | sub_1405441F0（106 行，#22） / 脚本/作用域变量 / 书 `s4_00_bases.md:407` CScopedVariable 目标 spec 行（或 `s4_12_events.md:346`）补 random_seed 变量构建/注册步（scopedvariable.cpp；变量挂 gs _pVariables）；细作先裁 random_seed 语义（疑预置随机源变量，与 s4_01:208 multiplayer_random_seed 静态槽对碰） |
