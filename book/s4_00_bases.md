

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
| [3] | **Load 入口** (共享 wrapper) | 7 类同址 **sub_1424BE690** |
| [4] | **每类 reader/parser 本体** (纯虚/覆写) | CCountry **sub_140705CE0** / CState sub_1409DBE00 / CProvince sub_140E7F720 / CPoliticalStatus sub_140BAD850 / CCountryPlayerSettings 0X1414E7110 / CCharacter sub_140FA50B0 / CCommand sub_142269E60 |
| [5] | const false getter (共享, 返 0) | 7 类同址 **sub_14011D220** |
| [6] | 空桩 (guard_nop/ICF) | — |
| [7] | 空桩 (guard_nop/ICF) | — |

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
> NScript::CConstant / CCollection / CNamedCollection / NMath::CExpression)。
> **`ref/serfam_1193.txt` 的指纹判据 = `[1]==0x1424BEC50 && [3]==0x1424BE690`,
> 故该族结构性失明** (不在表内) — 用 serfam 判定「是否 CPersistent 族」时须先排除本形态。
> 虚槽 (例 0x140631ED0 / 0x140631EA0 / 0x140631EE0, stats/bonus/group 三族)。
>
> **CPersistent 本身无 COL / 无 `vftable` 符号** (grep=0): 它是**抽象接口** ——
> 从不单独实例化, 故 exe 不发射其 COL; 具体类的虚表 = CPersistent 槽 + 派生类新槽。
> 槽 [1]/[3]/[5] 全类同址 ⇒ 定义在 CPersistent 且不被覆写; 槽 [2]/[4] 逐类变 ⇒ 纯虚。
>
> **CCountry 谱系 = 单链 CPersistent ← CAIOwner ← CCountry** (vt 实测 11 槽,
> mi=false); 槽 [8] 起 (CCountry sub_1406FE1D0 日更 / [9][10] sub_1401F8A60)
> 推定归 CAIOwner 层 (唯 CCountry 一派生, 离线不可再分); [9][10] = ICF 恒等汇点
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

> 其余槽未列 (未决)。

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

CInGameUpdateableInterface (0x142A41C20, 10 槽) 虚表槽表:

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | — | 析构 |
| [1] | — | 断言桩 "Override this function before using!" (updateableinterface.cpp L37-67) |
| [2] | — | 断言桩 (同 [1]) |
| [3] | — | 断言桩 (同 [1]) |
| [4] | — | 断言桩 (同 [1]) |
| [5] | — | 断言桩 (同 [1]) |
| [6] | — | 断言桩 (同 [1]; 视图覆写 = 全量刷新) |
| [7] | — | 断言桩 (同 [1]; 视图覆写 = 逐帧 Update) |
| [8] | 0X141237590 (共享) | IsOpenAndVisible 转发 (调主 vt[5]) |
| [9] | — | **Repopulate** (纯虚) |

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

> 其余槽未列 (未决)。

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
| **[13]** | ★ **Execute** | **375** | 9 锚点全中: CAddLegitimacyEffect 0X140362C80 / CAddStateClaimEffect / CAddStateCoreEffect / CCreateEquipmentVariantEffect 0X14049BFA0 / CCreateUnitEffect / CAddIntelEffect / CCreateFactionEffect / CSetFactionManifestEffect / CSetFactionRuleEffect |
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
| 对象+88 | 目标 spec 优先级指针 (CCountryEffect: 非空则优先于基类透传) | CCountryEffect[25] |
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

#### 4.00.4 求值/事件 scope 上下文对象

> 无独立 RTTI 类 (负定案) — Execute/Evaluate 求值上下文与事件 scope 共用的引擎上下文对象,
> 按求值槽位引用 (effect 端 ctx / trigger 端 ctx 同体)。挂接见 §4.32 各卡「scope ctx」引用。

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | u32 | 国 tag id (求值与事件 scope 共用基槽) | 高置信 (三批互证) |
| +12 | u32 | RNG 计数 | 高置信 |
| +16 | u32 | RNG 种子 | 高置信 |
| +24 | 匿名结构 (NNB 形状)* | root 作用域对象 | 高置信 (sub_14054D0B0 / sub_14054EB40 消费) |
| +32 | 匿名结构 (NNB 形状)* | from 作用域对象 | 高置信 |
| +40 | 匿名结构 (NNB 形状)* | prev 作用域对象 | 推定 |
| +80 | 句柄 | 类型化对象句柄 (CCharacter ref; 解引用 = sub_140535C20) | 高置信 |
| +92 | 句柄 | 类型化对象句柄 (与 +80 同式位对) | 推定 |
| +96 | 句柄 | combatant 对象句柄 | 推定 |
| +104 | 句柄 | 类型化对象句柄 (与 +80 同式位对) | 推定 |
| +112 | 句柄 | CArmy 引用 id 对 | 推定 |
| +120 | 句柄 | MIO 对象句柄 | 推定 |
| +128 | 句柄 | 采购合同对象句柄 | 推定 |
| +136 | 句柄 | RAID 引用 id 对 | 推定 |
| +144 | 句柄 | NProject 项目句柄 | 推定 |
| +168 | u32 | 州 id (州域 effect/trigger 直读) | 高置信 (八批互证) |
| +172 | uint8 | 作用域存在旗 (非零 = 有效; scope_exists 极性锚定) | 推定 |
| +192 | — | create_equipment_variant 语境槽 | 推定 |
| +296 | — | 所有者限定槽 (CEventScope+96 = CCombatant\* 单指针消费旁证) | 推定 |

- 附注: 事件 scope 对象另有 id 对容器 {data@+8, count@+20} (子效果解引用; §4.12.6 CSavedEventTarget 112B 元)。
- 附注: scope 侧位场 =+36 u32 作用域键位图 (this/root/prev/from/owner/controller/occupied/capital/random/0x400 已处理 + event_target tag u16@+40) — 与 §4.00.3 [6] Parse 行一致。

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

> 槽 [0] 未列 (未决)。

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

> 槽 [0] 未列 (未决)。+8 起 20×64B std::function 回调表 (**槽内 +56 = callable
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

> 其余槽未列 (未决)。每类差异序列化全走 [22]/[23] 载荷钩子 (家族 452 派生中
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

**CPendingAction 待命指令族** (unitcontroller.cpp 域, 与 CCommand 邻接但**非 CPersistent 不入存档** — 运行时待命队列, Execute 时直发命令域命令): 基 = CPendingAction (vt 0x1429CBC40, [1..6] 全纯虚); 5 派生恰 7 槽契约: [1] 入队预检门 / [2] 类 id 枚举常量 (AddMovement=0 / AddStrategicRedeploy=1 / TransportUnit=2 / StratNavyTransfer=3 / CancelMovement=4, 各为编译器 `return N` 共享桩) / [3] RegisterRefs (引用收集入引擎 vector {ptr@0, cap@+8, count@+12, alloc@+16}, push = sub_1401205A0) / [4] ClearRefsIfIn / [5] IsValid / [6] Execute (AddMovement→sub_140BF9A40; CancelMovement→sub_140BFB4A0; AddStrategicRedeploy→new CStrategicRedeploymentCommand 0x50B; TransportUnit→栈构 CTransportUnitCommand 0x60B; StratNavyTransfer→sub_140EA9660)。入队统一入口 **sub_1414D4B50**(owner, pending): [1] 门 → [3] 收集 → 倒扫 owner+272 待命列表 (count@+284) 逐条 [4] 去重 (同对象旧指令被清引用, IsValid 假则虚析构移除) → push — **新指令实时取代同对象旧待命指令**。工厂: sub_1414C3860 Cancel / 1414C38F0 AddMovement / 1414C3A50 AddStrategicRedeploy / 1414C3AE0 TransportUnit; StratNavyTransfer 在海军转移函数内联构。布局: CPendingAddMovement 56B (+8 CUnit*, +16 路径容器, +48 旗, +52 u32) / CPendingAddStrategicRedeploy 32B / CPendingCancelMovement 24B / CPendingStratNavyTransfer 56B (+16 单位 CReferenceObject 对向量, count@+28) / CPendingTransportUnit 32B (+8 CReferenceObject 智能对经 sub_14221F310 三档 id 库解析)。

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

**资产工厂族**: **CAssetFactoryAudio** (vt 0x142B503F8, ctor 0x1423492E0, dtor 变体 0x142349050 / 0x142349870; 基 CPersistent): [1] Save wrapper 0x1424BEC50 / **[2] writer = CFG 空桩** / [3] Load wrapper 0x1424BE690 / [4] **reader 0x14234A010**; 对象 +32/+56 两子容器 (sub_142348FE0 / sub_142348F70)。**CAssetFactory** (.asset 工厂基类; vt 0x142B50890, 基 CPersistent; writer 空桩; reader 0x14234DB90): reader 开头双旗门 = `+24 != (a3==438)` skip / `+25` 置位时只收 light(84)/entity(438)/particle(407) 三键, animation(64) → SAnimationData。**CAssetFactoryParticle** (0x142B501A8): [3] = **自定义 Load wrapper 0x142331870** (全量 SParticleSystemReader 解析), [4] = 基 reader — 与 CBrowserType (0x142B53C58, [3] 自定义 Load 0x1422DE0B0, reader 0x14236DFF0) 同属「wrapper 自定类」serfam 盲区实例 (另见 §4.00.1)。**CBrowser** (0x142B46F70, 基 CGuiObject + CTextInputReceiver@+128) = 内嵌 CEF 网页窗, 排除; CBrowserContext/CBrowserInstance 抽象基实现见本表 Steam 族。**开发/调试设施族 (负定案, 整族排除出存档域)**: **CNudgerStrategy** (vt 0x142A42FF0, 7 槽 5 纯虚, 无基非 CPersistent) = nudge 编辑器资产微调策略抽象基; 派生 CStateNudger (0x142A44BF0) / CStrategicRegionNudger (0x142A45220) / CSupplyNudger (0x142A45568) / CUnitsNudger (0x142A45A18) / CDatabaseNudger / CWeatherNudger / CBuildingsNudger / CAmbientObjectNudger (0x142A43130) 同构 `CNudgerStrategy@0 + CReloadableInterface/CReloadDispatcher@40` 多基 (12 槽), 激活 = 编辑器 GUI `interface/nudge.gui`, 仅写 mod 文本文件零存档面; **CDBNudger** (vt 0x142A44290 + 次 0x142A442D0, ctor 兼 dtor 0x141B504F0 / 0x141B51B40, sizeof ≥16448 — ctor 最大写偏移 16440, 上界提示; 槽 [1] 0x141B51F00 / [2] 0x141B52180 / [3] 0x141B52FF0) = 库级 nudge 器巨型对象 (~16KB)。**CCameraControlStrategy** (vt 0x142AFDA60, 11 槽 4 纯虚, 独立抽象基与 Nudger 无继承) → CFirstPersonStrategy (0x142AFDA90) / CTurnTableStrategy (0x142AFE5F8), 部署于 assetviewer/previewer 调试查看器。**HOI4EditorInterface** (vt 0x142727500, 基 CEditorInterface) = 启动参数 `-editor`/`--editor` 进入编辑器主循环 (sub_14209E610) 的界面根类。**CMapIdler** (12736B, CIdler 轻量支 +CLostDeviceInterface@8, 非 CGameIdler 支) = assetviewer/previewer 调试场景 idler (ctor 直绑 previewer_quit/record/next_asset 等 12 键); **CNudgeIdler** (3984B, CGameIdler 支 + CReloadDispatcher@1512) = nudge 编辑器场景 idler (副表邻串 interface/nudge.gui/ambient_objects/strategic_regions/buildings) — 两者与上列 Nudger/相机策略同场景。**CEvolveEquipmentImgui** (0x142A3D808, 7 纯虚) → **CEvolvePlaneImgui** (vt 0x14299B678, ctor 0x141198770, 104B, [2] 0x141B06800 OnUpdate) / **CEvolveShipImgui** (0x14299B768, ctor 0x141198800, 112B, [2] 0x141B076E0) / **CEvolveTankImgui** (0x14299B7E0, ctor 0x141198890, 120B, [2] 0x141B08020) = "DEBUG UI" 装备演化调试器。四类**均非 CPersistent** (槽 [1..4] = `_purecall` / CFG 桩 / 0x14039DAB0 / 0x1401807B0 样板) ⇒ 纯编辑器层不可序列化。**CLogger** (vt 0x142B91D18, 4 槽 2 纯虚抽象基) → CFileLogger (§4.00.9 文件族) / CFilterLogger (0x142B3AF58, 按类别 id 哈希路由转发, 全局表 qword_1434521A8 + OutputDebugString 旁路) / CNullLogger (0x142B91D40 空实现); **CTestLogger** (0x1429B3A68, CPersistent 壳 writer 空桩) → CEquipmentInFieldLogger / CManpowerLogger 遥测件, **CTestLoggersArray** (0x142737248) reader 0x14136E580 = 多态反序列化工厂 (tag 14054/14055); CTest/CTestBundle (0x142737148/0x142737198, writer 空桩) 与 CTestDatabase (0x142737218, 常驻装载 "tests" 目录) 同属自动化测试框架。**StackWalker** (0x142B58708) → CCustomStackWalker (0x142B5B3D8, 线程局部单例 0x1435B9F60) → CPdxCrashReportImpl (0x142B5B320 接口) → CPdxCrashReportWindows (0x142B5AA48) → CrashReporter.exe = 崩溃诊断链。**CAutotestSettings** (0x142724378, writer 空桩 reader 0x1401F8D30, 版本 tag 15531) 与 **CAnimViewerGraphics** (0x142AFD7B8, reader 0x14223B060, 版本 tag 53/55/296) 均为只读入解析件。以上整族 serfam 命中者 writer 一律 CFG 空桩 = 引擎不落盘。

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

**网络服务器族**: **CServer** (抽象基, vt 0x142B52AC8 ≥30 槽, [5][6][7][30][35][36] 纯虚; [4] 0x142363E10 经 +72 连接对象转发发包) → 唯一 RTTI 实现 **CProxyServer** (0x142B53598, proxy_server.cpp; [6] Update 间隔 >1.0s 打 "Long update!"; [3] 清 +348/+392/+472 连接状态 (24B 条, count@+480)); CDummyServer (0x142B52C28 31 槽, 单机空实现, 工厂 sub_14224E3E0/E870)。**CSession** (会话信息可观察包装, vt 0x142B3E9D8; +8/+16 观察者双链表首尾 / +24 count / +28 挂起旗 / +40 全局计数门 dword_143453198)。**CPlayerLobby** (大厅玩家面板, vt 0x142A0EC58; RTTI lambda 证 KickPlayer/BanPlayer; [22] 0x14186F3A0 = server_id_button → SERVER_ID_COPY)。**CChat** (游戏内聊天控制器, vt 0x1429ADE98, 基 CReloadableInterface ← CReloadDispatcher ← HotkeyListener; slash 命令表 `/slap /whisper /invite /newchannel /ban /kick /roll /save` 硬编码; 创建点 sub_1419A9090) → **CGameChat** (0x142A24E48, chat_window/chat_inbox_window/chat_item)。**CFriendsHandler** (平台好友表处理器, vt 0x1429D5378 19 槽, 懒建单例存储 qword_143339C70, getter sub_140A31BB0) → **CFriendsHandlerSteam** (680B Steam 后端: ctor 内建基后原位换表; 内嵌 "CAREER_PROFILE_YOU" 自好友件 CFriendsHandlerFriendSteam + 5 个排行榜/文件共享 CCallResult)。**ChatSettingsProviderImpl** (vt 0x142969468; 6 薄 getter 全委托 CSettings 单例 (0x1401FA5E0) +904/+912 域)。**HotkeyManager** (vt 0x142B3EE88, 基 CPdxEventHandler; +14 子对象串表 / +80 注册表 count@+92; 单例旗 byte_1434531B1)。

**CApplication 应用族** (只载不存 + 单实例锁): **CApplication** (vt 0x142B3C288 + 次表@+8; 基 CPersistent + CApplicationObservable 多基) — 主表 [1] **无 Save wrapper (CFG 空桩)**、[2] writer 空桩、[3] Load wrapper + [4] reader 0x14222E600 (只读 name(27)→+72 窗类名) = **应用单例只载不存** (serfam 指纹需 [1]+[3] 故未命中); ctor 0x14222B420 内 `FindWindowExA(0,0,+72,0)` 单实例互斥 ("An instance of this game is already running on this computer! Exiting."), **实例指针落 qword_143452450 (主单例定案**: ctor 写入, 18 引用全在 CApplication 编译单元 0x14222B5F0..0x14222EDD0)。**CApplicationObservable** (应用事件广播壳, vt 0x142B3C260 主表 4 槽; CApplication/CGameApplication/CMapApplication 公共多基 mdisp 8)。**CMapApplication** (0x142AE6950, 主进程应用; ctor sub_1420A13C0 由 WinMain 体 sub_14209E610 内建) / **CGameApplication** (0x1427182E0 族, ctor sub_140151EC0 注册 defines 组, caller sub_14015FB30)。**CGameGraphics** (0x14294A338, 基 CGraphics + CLostDeviceInterface 虚继承@+206320; [1] SaveW/[3] LoadW 持久化图形设置到用户设置**非存档**)。

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
