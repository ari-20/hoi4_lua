# HOI4 运行时类结构全书

> 版本: HOI4 **1.19.3.0** rev c01a3d50 (ImageBase 0x140000000)
> 本书是用于mod制作的方法论说明，仅供学习交流使用

## 0. 阅读指南 (必读)

### 0.1 类型标注约定

文档全部使用 C 风格类型标注, 与任何实现语言无关:

| 标注 | 含义 | 字节 |
|---|---|---|
| `uint8 / int8` | 单字节 (int8 = 带符号) | 1 |
| `uint16 / int16` | 16 位整数 (小端) | 2 |
| `uint32 / int32` | 32 位整数 (小端) | 4 |
| `uint64 / int64` | 64 位整数 (小端) | 8 |
| `fixed×1e-5` | int64 定点数, 实际值 = raw × 1e-5 | 8 |
| `fixed×1e-5[n]` | 定点数组, 连续 n 个 int64 | 8n |
| `Q15` | int64 定点, 实际值 = raw / 32768 | 8 |
| `float` | IEEE 754 单精度 | 4 |
| `char[N]` | 固定长字节串 | N |
| `string` | MSVC std::string: `{buf/ptr@+0, size@+16, cap@+24}`, **内联判据 = cap≤15** (⚠ 勿按 size≤15 判: 串增长后缩短时 size≤15 但 cap>15, 数据在堆, 读内联得指针字节垃圾) | 32 |
| `cstr` | C 风格零结尾串 | - |
| `T*` | 指向类 T 的指针 (8 字节) | 8 |
| `T` (内联) | 类 T 的对象本体嵌入当前类 | sizeof(T) |
| `token` | uint32, 是游戏全局 token 表的索引, 经 token 表可解析为字符串名 | 4 |
| `tag_id` | uint32, 国家标签表索引; `tag串 = tag表 + 32 × tag_id` 处的 cstr | 4 |
| `hours` | int32, CGameDate 总小时; **基准 43800000 = 年 0.1.1.0** (GER 1937.7.5.22 = 60,772,581 ↔ /health game_hour 同基; 1936.1.1 ≈ 60,759,335); 哨兵 43808760 = "1.1.1.1" 未设 | 4 |

类型列/类名/偏移列等书写纪律细则见 §0.4。

### 0.2 通用铁律 (任何实现都必须遵守)

1. **vtable 校验**: 每个类条目标注其 vtable RVA (相对 ImageBase)。
   解引用任何对象指针前, 先读对象头 8 字节并与期望 RVA 比对, 不符即悬垂/复用,
   必须放弃访问。
2. **常见容器三型** (详见 §3):
   - std::vector: 连续元素, `{data 指针, count, cap}` 三件套的偏移随类而变,
     每个字段条目单独标注
   - robin-hood 哈希表: 桶 24 字节 `{值/指针@+0, dist uint32@+4, 键@+8}`;
     dist=0 空桶, dist∈{0xFE,0xFF} 墓碑/特殊标记双值都跳; 遍历上界 = mask+1+extra (extra 为尾部溢出桶数)
   - std::map (红黑树): 节点 `{left@+0, parent@+8, right@+16, isnil byte@+25,
     ...}`, 中序遍历顺序 = 存档顺序; 头节点 = 容器对象首指针
3. **业务浮点 = int64 × 1e-5 定点** (fixed×1e-5), 全游戏普遍使用
4. **稀疏编号定律**: 存档里的块编号 = 原始数组槽位。writer 跳过空槽时,
   消费方不得按顺序重编号 (编号错位 = 值级对拍全错的教训)
5. **重名块定律**: 同一父块内出现多个同名子块时 (如每目标国一个
   intel_network), 第 2 个及以后在存档提取中记为 `名字[N]` (N 从 2 起);
   读取端必须遍历全部实例
6. **写出门**: 每个字段条目标注 writer 的写出条件。读取端复刻同一条件,
   才能与存档逐叶对拍
7. **唯一实现原则**: 同一换算语义全库只能有一份实现, 散写副本 = 返工。
   reader 侧统一入口 = `hoi4_layout.lua` (数值/日历) 与 `objects_shared.lua`
   (读原语/共享助手), 段文件与域文件一律委托, 禁止就地重写:
   - **带符号读**: 一律 `M.i8/i16/i32/i64`(按地址) 或 `M.as_i8/i16/i32/i64`
     (就地符号化); **禁止手写 `v >= 0x80000000 and v - 0x100000000`**
     (位掩码/enum 字面量除外 — 那类不是符号化, 勿误改)。
     ⚠ i64 族 = 恒等/透传: 引擎 `read_u64` C 侧已是带符号重解释 (§3.7),
     `M.i64` 与 `M.as_i64` 只作符号语义标注, 不含换算;
     窄族 (i8/i16/i32) 补符号仍必需 (窄读零扩展, 值域为正)
   - **定点读**: `M.fix5`(×1e-5, 必须**除** 100000) / `M.q15`(÷32768)
   - **日历换算**: `M.date` / `M.date_raw` / `M.date_quoted` 三变体
     (门与输出形差异见 §3.7b), 禁止再写历法循环
   - **虚实表校验**: `M.vt.<类名>` (全表见 §0.2.1); **只收代码中真实
     出现过校验的类**, 无校验的类不入表 (凭空填值 = 引入错误常量)
8. **对象层文件布局** (实现侧; 语义条目仍按类散见 §4): 对象层按域分文件,
   入口 `objects_v2.lua` 只做「按依赖序加载 + 挂契约位」。域文件经
   `GAME.objects_shared` 取共享符号, 且**自行 dofile 共享层** —
   因 DLL 按文件名**字母序**平铺加载, 域文件先于 `objects_shared` 就位,
   依赖加载顺序 = 脆性设计。新增域文件必须遵守同一模式。
   两处幂等设施 (缺任一则对象层热重载失效):
   - **共享层世代守卫**: `objects_shared.lua` 开头 `if
     GAME.objects_shared.LAYOUT == GAME.layout then return 现表 end`
     — 世代判据 = `GAME.layout` **表身份** (`hoi4_layout` 每代重建该表)。
     守卫缺失时本文件每代被执行 2~3 次, 仅最后一份接得上全部域方法;
   - **域文件世代判据**: 域文件仅在 `SH.LAYOUT ~= GAME.layout` 时自举,
     否则复用现表, 使「本代首个域文件建层, 其余复用」——旧版仅判
     `not GAME.objects_shared` 会让域文件捕获**上一代**共享表 (全局表跨代
     存活), 靠 objects_v2 兜底重跑才收敛。
   ⚠ hot reload 改 `objects_shared.lua` 后须 touch 任一被 watch 的 lua
   触发整代重载; 单文件 dofile 不构成完整重挂载 (契约位由 objects_v2 挂)。
9. **GUI 类归册**: GUI 类布局统一归 §4.30 (主视图/面板/地图模式本体) 与 §4.31 (行件/条目/图标行);
   域册 (如 §4.5/§4.15/§4.16/§4.18) 只留「本域 GUI 类布局: 见 §4.xx」指针 + 数据面。
   判据 = 有无 CPersistent 基 / writer / 是否 def 或 effect —— **名字像 GUI 但承载域数据的类 (如 SDynamicModifierEntry / CCombatTactic) 留在域册**。
10. **提取器形态契约** (对拍/读取端必须按形态匹配, 与游戏内存布局无直接对应):

   | # | 形态 | 规则 | 对拍端要求 |
   |---|---|---|---|
   | 1 | `ops.<id>.intel_network` 重名编号 | 第一网裸名, 第 2+ 网 `intel_network[N]` (N 从 2) | schema 两种形态都覆盖 |
   | 2 | `sub_intel_networks.#N` | 提取器把匿名数组元素记为 `.#N` | 按 #N 序号对位 |
   | 3 | `字段.#1` (coverage_stats 等) | 多州列表被拆成 `字段.#N` 形态 | 需归一回裸字段再比对 |
   | 4 | **HEAD 裸键字符集缺 `/:@-`** | 提取器把含 `/:@-` 的裸键行 (旗名 `ai_diff:` / `mechanized_mortar_intro/complete` / `party_banned@`, 变量名 `ww1/*` / `offsite/*` / `german-soviet_treaty_slot`) 吞进 `@` 哨兵/`#N` 多 token 分支 | 对拍表现为**对称 MM/MS + #N 级联 DIFF 假象** (bi8 flags 1064/1064、variables 2131/2131+510DIFF 全为假象, 60 国 532 旗两侧同批); 修复 = 提取器正则扩字符集, export 无需改 |

### 0.2.1 vtable RVA 表 (M.vt)

对象层虚表校验值统一收于 `hoi4_layout.vt`，消费侧一律写
`GAME.layout.vt.<类名>`（`O.vt(addr, GAME.layout.vt.X)` 或
`BASE + GAME.layout.vt.X`）。**禁散写 `0x29xxxxx` 字面量**。

**收录纪律**: 只收代码中真实出现过 vtable 校验的类。无校验收录的类
**不入表** —— 凭空填值 = 引入错误常量，比散写字面量更危险。

| 类名 | RVA | 位置 / 说明 |
|---|---|---|
| CState | 0x2936cc0 | 州主虚表 (书 §4.13) |
| CProvince | 0x2971b18 | 省主虚表 (书 §4.14) |
| CCharacter | 0x297ea60 | gs+1704 角色 (书 §4.4) |
| CAdvisorTemplate | 0x29bba98 | 顾问模板 |
| CPolitics | 0x294fda8 | cc+3984 (书 §4.10) |
| CTechnologyStatus | 0x2974fa0 | cc+3936 (书 §4.7) |
| CBuildingStatus | 0x2999050 | 州级/国家级建筑池共用 |
| CDeployment | 0x294f5b0 | cc+3952 部署模板 |
| CSubUnitStatBonus | 0x295faa8 | 解锁兵种 bonus |
| CArmy_vt0 / CArmy_vt1 | 0x295a2b0 / 0x295a490 | CArmy 双虚表 (书 §4.18) |
| CNavyLeader | 0x2955dc0 | (书 §4.4.6; 海军将领导出族在角色册) |
| CStrategicNavyManager / CStrategicNavy / CNavalBase | 0x29732e0 / 0x2973260 / 0x29731c0 | gs+1688 海军三连 (PE COL 直证; 旧「海军基地三连」命名误) |
| CUnitMedalStore | 0x29c1818 | 部队授勋商店 (616B; §4.18 army_history 子表) |
| CUnitHistory | 0x29c1868 | 部队史块 (+1592 内嵌; 元 = CUnitHistoryEntry*) |
| CUnitHistoryEntry | 0x29c1bc8 | 部队史/授勋条目 (328B; §4.18) |
| CStrategicAirMgr | 0x2958918 | gs+1680 (书 §4.15) |
| CStrategicAirCountry | 0x29587d8 | 国条 |
| CAirWingPool | 0x297ae38 | 翼池 |
| CAirBase | 0x2958780 | 基地 |
| CStrategicAir_vt2 | 0x2958968 | 空军次虚表 |
| CCombatManager | 0x2950688 | gs+608 (书 §4.22) |
| CCombatLogManager | 0x295d8d8 | gs+616 |
| CCombatLogEntry | 0x295d888 | 日志条目 |
| CLandBorderWarCombat | 0x29bc5f0 | 边境战争战斗 |
| CCountryIntel | 0x295f188 | cc+4072 (书 §4.11) |
| CCountryIntelAgency | 0x2981f68 | cc+4032 |
| CStrategicOperativesMgr | 0x2973b80 | gs+1696 (书 §4.11) |
| CStrategicOperative | 0x29a2358 | |
| COperativesNet / COperativesSubNet | 0x29a1a58 / 0x29a1aa8 | |
| CCountryReportsMgr | 0x29D10A8 | cc+4064 (书写法 0x1429D10A8 低 32 位; RTTI vt_rtti.json 定案) |
| CCountryResources | 0x295c4b0 | cc+4600 (§4.3.25 全表; +24 = 0x295C4E8 CPersistent 序列化子表, writer/reader 收 a1 = rs+24) |
| CResourceDelivery | 0x295c320 | 交付路由元素 |
| CResourceOrigin | 0x295c370 | 资源起源元素 |
| CFuelStatus | 0x298b3a8 | cc+5504 (书 §4.3) |
| NProject::CProgramStatus (SM) / NProject::CProjectPool / NProject::CProgram | 0x2971838 / 0x29c6e28 / 0x29717e0 | cc+4008 (§4.7.9) |
| CBreakthroughProgress | 0x2a2c040 | |
| CEquipmentVariant | 0x2951608 | (书 §4.23.1) |
| CCountryExperienceStatus / CExperienceElem | 0x29a80c0 / 0x2958040 | cc+5512 |
| CPowerBalanceSystem / CPowerBalanceEntry | 0x296fca0 / 0x296fc50 | gs+1104 (书 §4.3) |
| CPeaceConferenceMgr | 0x270AE28 | gs+1248 (书 §4.10.26) |
| CPeaceConference / CWarScoreBreakdown | 0x2950e58 / 0x2960128 | (书 §4.10.27) |
| CDoctrineCs / CDoctrineFolder / CDoctrineTrack | 0x29653f8 / 0x29653a8 / 0x2965358 | (书 §4.6) |
| CLoopHistory / CLoopHistoryEntry | 0x29d2a48 / 0x29d29a8 | (书 §4.3.11) |
| COrganisation | 0x2967a28 | MIO (书 §4.8) |
| CWeatherManager | 0x2977810 | gs+1672 (书 §4.20) |
| CSupplySystem | 0x2973cf0 | gs+984 (书 §4.21) |
| CRailwayManager / CProvinceRailwayInfo | 0x2972cd0 / 0x2972c80 | (书 §4.14.6/§4.14.7) |
| CProductionStatus | 0x2970788 | 州监听元素 (**非** cc+3944; 书 §4.13) |
| CIntelSource | 0x295f138 | 谍报网内联 @net+168 (书 §4.11) |
| CActivityElem | 0x295a5b0 | 活动 xp_by_template 元素 (书 §4.3) |
| CActivityElemAir | 0x2965260 | 活动 xp_by_airwing 元素 (书 §4.3) |
| CCountryCharacters | 0x298ae18 | cc+4080 (书 §4.3; 旧称 legacy DEEP.chars_vt) |
| CWeatherProvince | 0x2977770 | 天气省级元素 (@mgr+0x10, stride 0x180; 书 §4.20) |
| CCountrySupplySystem | 0x29a2b08 | 补给国级元素 (书 §4.21) |
| CScriptedGuiData | 0x29848d8 | SGD (书 §4.30) |

> 元素级虚表 (容器内嵌对象) 与主虚表同表收录，以位置注记区分；校验用法相同。
> NRaids::CCountryRaidStatus (0x29ccd88) 因无核验类名暂**未**入表。

### 0.3 指针有效性

堆地址有效范围约 `[0x10000, 0x7FF000000000)`。越界即无效指针, 放弃访问。

### 0.4 书写规范

> 表格/类名/进制/层次不合规 = 返工。
> 本节为细则，冲突时以本节为准。

#### 0.4.1 层次与标题

1. 主文件节标题 = `## N` / `### N.x` / `#### N.x.y`；分册主标题 =
   `### 4.x`，小节一律 `#### 4.x.y` 真标题，**同文件内**编号连续不跳号。
   跨分册的节号是稳定 ID, 只增不重排: 分册被并入他节时其节号**作废不回收**
   (后续分册不整体前移 — 全书 §4.x 交叉引用按号寻址, 重排会静默错链);
   作废号在索引表注明去向, 空号允许存在。
2. 禁用加粗段落冒充标题；标题只写类名/主题，禁带批次名、日期、
   收编史后缀。
3. 同文件内同类小节命名风格统一（类名+尺寸/writer 信息格式一致）。

#### 0.4.2 表格体系（七表分类法）

写一条信息先判定属于哪一类，进对应的表；七类之外的信息才允许散文。

| 表 | schema | 出现条件 |
|---|---|---|
| 身份表 | 项 \| 值 | 标配。固定行序：RTTI 名 / sizeof / vtable RVA / writer / loader / 挂载点；缺项写 `—`，不省行 |
| 主表（字段布局） | 偏移 \| 类型 \| 名称 \| 写门 \| 备注 | 标配。写门只写序列化条件（恒写 / count>0 / ptr≠NULL / 不序列化）；备注只写一句语义 |
| 虚表槽表 | 槽 \| 函数 \| 语义 | 多态家族（effect/trigger/command、GUI view 等） |
| 元素子表 | 元素+N \| 类型 \| 名称 \| 备注 | 容器元素 >2 字段；挂主表容器行之后 |
| 枚举/映射表 | 值 \| 名称 \| 语义 | 字段取值为枚举或 token 映射 |
| GUI 消费表 | 字段 \| 消费点 \| 用途 | 消费点 ≥3 才立表；1–2 个写入主表备注格 |
| 流程步骤表 | 步 \| 函数 \| 语义/条件 \| 置信 | 执行链/调度链逐步展开。步列按链形态命名（步/入口/相位/层/阶段等）；单步条件并入语义列；纯顺序无分支的短链不立表（散文② 即可） |

散文仅限三种：① 判别分支（两形态写一行备注；≥3 形态用
形态|判别|读法 表）；② 流程/顺序（一行箭头链或编号短句；带条件分支
的升级为流程步骤表）；③ ⚠ 陷阱（一行一事，不写历史）。

容器尾 cap/alloc 同构信息不逐行占主表：由 §3.1 通则承载，主表只留
data/count 实字段行，特例才单独成行。

**流程内容归置**：全局时间调度骨架（驱动链 / 相位表 / hourly·daily·
weekly·monthly·yearly 主循环与跨域时序）= §4.2；域内业务执行链 = 域
分册。§4.2 对已由域分册承接的链只留挂点行（函数 + 触发时机 + §x.x
交叉引用），不重复链体；两头全写的链按此收口（先例：补给 §4.21.1a /
战斗 §4.22.9a / 突袭 §4.27.3）。

#### 0.4.3 表格机械纪律

1. **类型列禁匿名占位**：禁 `ptr`/`T*`/`T` — 单对象指针写 `CClass*`；
   容器数据指针写元素类名+`*`；原始元素写基本类型（`uint32`/
   `fixed×1e-5`/`tag_id`/`idpair`）；无名结构写 `匿名结构 (NNB 形状)`
   并在语义列给形。
2. **类名纪律**：标题/表行以真类名开头（RTTI 名优先）；存档节点名/
   块名不得冒充类名 — 无独立 RTTI 类写明「无独立 RTTI 类（负定案）」
   并给结构事实与存档键名称呼。
3. **偏移列**：① 统一十进制（token 值/vtable RVA/绝对地址 0x… 不属
   偏移，照旧 hex）；② 首列统一 `+N`（禁裸 `N`、禁 `+0xN`；挂载点
   `gs+784` 式同化）；③ plain 偏移行升序（子对象相对偏移行
   `inner +N`/`mod +N`/`元素+N` 带前缀钉位，不参与升序）；④ 禁合并
   偏移格（`+208/+224` 式一律拆行，id 对拆 type/id 两行并注联合门；
   单字段跨字节范围 `+32..+64` 允许；同偏移双文档行排序后相邻并加
   ⚠ 待裁注）。
4. **落盘序契约显式化**：布局表默认偏移升序；行序 = 引擎落盘序且
   承载契约时（如 164 键表），必须在表头/注记显式声明。
5. 元素布局超 2 字段拆子表，不塞单元格；同对象多表 schema 必须一致；
   表后备注一条只讲一件事。

#### 0.4.4 禁外联与禁批次

1. **禁外联**：内容外指一律禁止（「全字段表见 xxx.md」、findings/
   工具件/路径引用），只许书内交叉引用（§x.x）；例外仅 `ref/`
   数据件与函数名（sub_XXXX / 0xXXX 地址级引用）。
2. **禁批次**：正文不写批次名与日期戳 — 不写收编史、翻案过程、
   验证史，只留现态结论；可追溯性由 findings 文档与 git 承担。
3. **禁删除线留废案**（`~~旧说~~`）：被翻案的旧结论直接删除，表格内
   尤其不得出现删除线偏移/删除线字段名。
4. **待定标记封闭词表**五档，同义词一律归并：

| 标记 | 含义 |
|---|---|
| 定案 | 二进制 + 实测双证 |
| 高置信 | 单证强推 |
| 推定 | 间接证据 |
| 待裁 | 两说并存，待探针/裁定 |
| 未决 | 未查 |

#### 0.4.5 收编与校验

1. 外部 findings/段头注收编进书时：hex 偏移→十进制、refid 对拆行、
   升序重排，写门/证据信息不失真；收编即按 0.4.1–0.4.4 整形（批次名/
   日期/文件路径剥离，散文转表）；存疑转录标「待裁」。
2. **布局事实不滞留流程节**：流程调查中新定案的布局事实（偏移 /
   容器头 / 桶与条目布局）一律落对应类布局表（主表 / 元素子表），流程
   节只留 §x.x 交叉引用 — 布局行只活在流程步骤表格/散文里 = 收编未完成。
3. 交付前 `python tools/md_table_check.py` 必须报 0 问题；改完 grep 复查
   `\.md` / `全字段表见` / `+0x` / `~~` / 批次名残留。

## 0.A 复原流程 (给实现者)

1. 读 §1 拿全局根; §2 类树定位目标类
2. 按类条目实现: vtable 校验 → 字段表逐字段读取 → 容器按 §3 算法遍历
3. 写出条件复刻 (需要与存档对拍的场景)
4. 验证协议: 载入存档 → 同刻导出内存快照 + savegame 重存 → 对两者做逐叶
   值级对拍 (DIFF/MISS 必须 0)

## 1. 全局根

### 1.1 游戏状态单例

```
gs = *(BASE + 0X332F260)          -- CGameState 单例指针
国家数组 = *(gs + 784)             -- 8B/项 指针数组; 国家数 = *(gs + 796)
国家对象 cc = *(国家数组 + 8*idx)   -- idx = 国家数组序 (0-based, 0 = 哨兵)
tag 串表 = *(gs + 856)             -- tag_str(tid) = 读 (串表 + 32*tid) 的 C 串
州表 = *(gs + 712)                 -- 州对象数组, 州数 = u32@(gs+724) (states writer 循环界); state 详见 §4.13
省表 = *(gs + 688)                 -- CProvince 指针数组; 省数 *(gs + 700) (=max 省 id+1; kr2=13907 与 CMap+560/省表 null 终止三读互证)
```

### 1.1b 应用管理器与暂停标志

```
mgr = *(BASE + 0X332F698)          -- 应用管理器单例 (存/读档会话研究同一槽)
paused = *(u8*)(mgr + 1729)        -- 暂停标志; +1731 = 连按 pending 位
```
- **定案证据**: 暂停切换函数 `sub_140DDAD30` (mgr->vt+656, CPauseGame::apply
  目标) 的**每条翻转路径都恰好写 mgr+1729** (a2≠0 双置/双清 1729+1731;
  a2==0 条件翻转走 LABEL_54 `1729 = old==0`); 在线验证 1=时停 / 0=运行。
- 语义注意: vt+656(u8, 原因串) 是**切换+pending**语义非幂等 set
  (已暂停时按 1 先置 pending 再按才解); 读侧用 +1729, 写侧保持现有
  game_pause 封装。test1 档 (和会持续暂停) flag=1 与 hour 冻结吻合。

#### 1.1b.1 CInGameIdler 暂停/存档旗位与槽位

**对象与字段**: 全局槽 `BASE+0x332F698` 持 **CInGameIdler** 指针 (vt RVA 0x2968FF0); 暂停状态**不落盘** (运行时 UI 状态)。
主虚表实际槽范围 0..118 (119 槽), 其后接三个兄弟子表 (COL offset 8/1512/1520) — CInGameIdler 四基多重继承; 槽值三类桩先滤: `_guard_check_icall_nop` ×20 / `return 0` 桩 ×4 / CRT 桩 ×1。
读档恢复暂停 = sub_140DD9B20 (按 dword_14332EC58 跨档记忆; 读档前 pause(1) 的引擎实现)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +36 | f32 | 帧时长 EMA (槽[29] 帧尾 `36 = 36×0.95 + Δ×0.05`) | §4.28.14 帧渲染槽对 |
| +64 | u64 | 本帧耗时 (sub_1401F7F80 掐表; 原 f32 推定修正) | 同上 |
| +1264 | 指针 | 渲染管理器 (槽[28]/[29] 渲染链消费) | 同上 |
| +1457 | uint8 | 遮罩/输入联动边沿缓存 | 同上 |
| +1458 | uint8 | **GUI 更新脏标记** (槽[12] 写 1; "_Idler.CanUpdateGui()" 断言语境; ⚠ 与 interface handler 子对象 +1458 非同字段) | 槽[68]/[69] 清 |
| +1608 | int | 模态计数 (槽[73]/[74] 增减; 槽[82] 以 ≤0 作放行门) | |
| +1680 | uint8 | **自动存档请求旗** (三源置位: CAutosave 命令槽[91] / 日历边界 sub_140DE2C10 (autosave 间隔枚举 dword_143085008 分派) / +2216 倒计数归零槽[64]) | **非暂停旗** |
| +1681 | uint8 | **AUTOSAVING 横幅位** (请求处理后 sub_140DCE470 置 1, 存档完成 word 清零对收; 槽[91] `!a2 → 清 0`) | |
| +1713 | uint8 | 框选态 (槽[29] 段 4 门; 读者 5 处) | 同上 |
| +1720 | CInGameInterfaceHandler* | 界面处理器 (槽[23] getter; "ingameinterfacehandler.cpp" 断言定名) | |
| +1728 | uint8 | **toggle 进行标记** (槽[94] 置 1 / 槽[82] 清 0, 一次性「刚切过」) | 非 pending |
| +1729 | uint8 | **暂停旗** (1=暂停/小时冻结, 0=走表) | 权威判据; 直写即时生效 |
| +1730 | uint8 | **暂停锁定位** (槽[71] `1730=(a2==1)`; 锁定后普通 toggle 被门挡; sub_1406DD0C0 检测下降沿) | |
| +1731 | uint8 | 连按 pending 伴随位 (槽[82] pending 分支双置/双清 / 槽[106] 置 1; getter sub_1406DFDA0) | 读档后可被引擎置位 → 暂停设值短路 |
| +1732 | uint8 | **脚本/事件强制暂停镜像** (槽[4] 从 gs world 链同步; 以 `!1729 && !1732` 作自动推进门) | |
| +1733 | uint8 | gamestate 复位完成旗 (槽[104] 写 / 槽[81] 读; "Gamestate successfully resetted") | |
| +1764 | uint32 | 框选点 1 | 槽[29] 段 4 |
| +1768 | uint32 | 框选点 2 | 同上 |
| +1984 | SSO 串 | 暂停原因串·未暂停侧 (本次原因) | |
| +2016 | SSO 串 | 暂停原因串·已暂停侧 (最新原因) | |
| +2048 | double | 暂停时刻 wallclock | |
| +2056 | int | 原因防抖窗 (ctor 30) | |
| +2063 | uint8 | 暂停原因记录禁用旗 (槽[82] 记录门) | |
| +2073 | uint8 | 截图完成一次性旗 (写者 sub_140DD2540; 横幅后帧尾清) | dword_14333CF70 保显倒计数 |
| +2080 | uint8 | 存图完成一次性旗 (写者 sub_140DD2AB0; 同上) | dword_14333CF74 保显倒计数 |
| +2216 | int | **自动存档倒计数** (>0 递减槽[64] / ==0 触发 1680 / <0 禁用 sub_140DE2C00; 载入/退出分支清 0) | ⚠ 与 gs+2216 (all_playthrough_data 宿主) 撞车 |
| +2396 | uint32 | 联机重试计数 (槽[95] a1[599] 递增, >12 发网清零) | |

| 槽 (vt 偏移) | 函数 | 字段与语义 | 引擎调用链 |
|---|---|---|---|
| 主 vt 0x142968FF0 slot[7] (+56) | 0x140DDE8A0 | GFX/设备恢复流程 ("Start RestoreDeviceObjects"): 完成处 ×2 `1729=1` 强制暂停 | 设备丢失/重载链 |
| slot[64] (+512) | 0x140DDA020 | 自动存档倒计数推进 (每帧 sub_1401DD370 调; +2216 归零 → 1680=1) | 帧推进 |
| slot[71] (+568) | 0x140DE1BF0 | **锁定式暂停 toggle**: 门 `!1730 ∥ !1729 ∥ a2`; 翻 1729 且 `1730=(a2==1)` | 事件弹窗暂停 sub_1401CF000 / pause_in_hours 控制台 sub_14026F410 / AI 快照 sub_1414D40E0 |
| slot[78] (+624) | 0x140DE0710 | **强制暂停 + 冻结 GUI** (经 +1720 handler 置 +1108; 单机 `1729=1` 单置) | 模态操作 |
| slot[82] (+656) | 0x140DDAD30 | **带原因串的暂停设值**: 清 1728; 记录原因串 (a2≠0 走 pending 双置/双清 1729+1731; a2=0 走防抖/同因判定后**翻转 1729**, 翻 0 发 "Game unpaused.") | **CPauseGame::Execute** (vt 0x14296A560 slot[10] = 0x140DE8360; cmd+72 state / cmd+40 原因串 / cmd+73 非 0 先过 vt+744 短路) |
| slot[91] (+728) | 0x140DC6530 | **自动存档旗设值**: `*(a1+1680)=a2; if(!a2) *(a1+1681)=0;` | **CAutosave::Execute** (0x140DE7C40) → `idler->vt[728](*(cmd+40))` |
| slot[93] (+744) | 0x140DD85C0 | **暂停读 getter** (`return 1729`, 纯读) | 引擎统一入口 sub_140202ED0 (读 vt+744 + gs+1212 速度 → sub_140202690 时钟控制 — 速度与暂停在此汇合) |
| slot[94] (+752) | 0x140DE1F80 | **暂停 toggle 入口 (UI 键路径)**: 先 sub_140202ED0 引擎落值 + `1728=1`; 单机 `1729 = !1729`; 联机改发命令 | UI 键 / DLL 桥 |
| slot[95] (+760) | 0x140DC91E0 | **联机卡顿重试计数器** (非暂停族) | sub_140F06BF0 (联机 date 滞后路径) |
| slot[106] (+848) | 0x140DD2A70 | **按原因强制暂停**: a2∈{9,10,13} → `1729=1; 1731=1` + 构造暂停提示界面 | |

> 写 +1729 全部写点 = **7 函数 12 处** (槽[94] 翻转 / 槽[7] ×2 =1 / 槽[78] =1 / 槽[82] pending 双置双清+防抖翻转 / 槽[106] =1+1731 / sub_140DD9B20 读档恢复 / 槽[71] 锁定翻转); +1728 = toggle 一次性标记 (槽[94] 置 / 槽[82] 清); +1730 = 锁定位 (仅槽[71]); +1731 = pending (槽[82]/[106])。
> 实测暂停/恢复时 +1729 与引擎暂停态严格同步、+1680 恒 0, 与上表一致。
- 主菜单**存在前端 gs** (hour 冻结、uid 合法) — gs≠0 ≠ 在游戏中;
  "在游戏中"判据 = 帧心跳活性 (CInGameIdler slot4 仅游戏内跑),
  3s 无心跳即 session 关闭 (DLL session 活性判据, 函数名 = 桥侧 CInGameIdler slot4 消费点)。

#### 1.1b.2 massconquer 帧测试器 (sub_140DE1040)

控制台命令 `massconquer`（别名 `massc`，"Mass conquer tool"；官方文档标 "Not available in release build" 与语料存在性矛盾 — 是否在现役命令表注册待运行时验证）的每帧执行体 = PDX 自用占领/剧场压测器。命令处理器 sub_14028F8B0：置启用旗 byte_14333CF38=1、批次 dword_14333CF3C=1、tag 向量 {qword_14333CF48 data / dword_14333CF50 cap / dword_14333CF54 count；**[0] = 征服国, [1..] = 受害国**}（少于 2 tag 报错）。

挂点 = CInGameIdler::Idle（vt 槽[4]）**帧顶**（帧掐表后第一条件块），唯一门 = Idle a2；权威暂停位 +1729/+1732 的检查在同函数后段（仅门调度器）→ massconquer 调用点不受暂停位门控；a2 上游语义（游戏内帧 vs 未暂停帧）待裁。

| 阶段 | 动作 |
|---|---|
| 0 | 门 = 启用旗 ∧ tag 数 > 1；入口解除 RNG 禁区旗 byte_143452528（random.cpp:181/187 "Calling random inside forbidden area" OOS 断言门；getter sub_142234100 / setter sub_1422345B0；出口恢复），抽取锚 = (ingameidler.cpp, 1711) 确定性 RNG |
| 1 | 受控省池 = Σ 受害国 cc+1064 controlled_provinces（取用 thunk sub_1406ECFE0；逐省经 gs+8 次虚表槽[1] 按省 id 取 CProvince* — 槽名待裁）；池空 → 日志 "No provinces to conquer. Testing is over."（ingameidler.cpp:1696）停转 |
| 2 | **第①轮 征服**：有放回随机抽 N 省（N = dword_14333CF3C）→ 占领 bundle 开窗（sub_140EED690）→ 逐省 SetController = tag[0]（sub_140E801A0，第 3 实参恒 1 语义待裁）→ 收口（sub_140EF2F30）→ 剧场重校验 sub_140EEC180（置重校验模式旗 byte_14333D2B0 后重跑剧场更新族，差异旗 byte_14333D2B1 任一置位 = 不一致）→ 失败 → 日志 "Conquer happened as <tag0 名>" + 列省（ingameidler.cpp:1740）+ 停转，**征服保持不归还**（留场复现） |
| 3 | **第②轮 归还**：同二轮，SetController = 省默认控制国（dctl 读取器 sub_140E796B0：rp(prov+192) 有则 *(dctl+200) 否则 sub_140BB3E00 默认槽）→ 重校验 → 失败 → 日志 "Giving back..."（:1778）+ 停转 |
| 4 | 成功 → 批次 N = (N+1) mod 2×池大小（0→1）爬坡循环 |

接缝定案：**第四路征服（调试工具直接征服）** — 无战争/条约上下文，只走控制权（SetController）从不触所有权（SetOwner），帧级驱动；不属 §4.3.6 占领日更六阶段、§4.10.32 投降/吞并、§4.10.26-31 和会任何一路，与既有链仅在级联下游共享占领 bundle 聚合与 occ/dp 写门族（本函数不产生新写门形态）。负结论：函数体无任何游戏对象偏移直写、无 gs+1128 日期读、无序列化调用 — massconquer 启用会话中对拍必炸（每帧控制权翻转；默认 BSS 零关闭，不执行命令即无影响）。

> 待裁：gs+1312（Idle 顶部 >0 → 写 CSession+1941）；CInGameIdler vt 槽[110]（返回值传入本函数但被忽略）；sub_140EEC180 是否另有生产调用点；失败日志省列表条目形态（省名 vs 省 id）。

### 1.2 gs 偏移 → 管理器总表 (全部为指针, 解引用后见各节)

| gs 偏移 | 管理器 | 对应 API |
|---|---|---|
| +0 | vt1 (CGameState 主虚表 = CPersistent@0 序列化槽: [2] writer sub_1401F29A0 / [4] loader sub_1401E59D0) | — |
| +8 | vt2 (CProvinceProvider@8 省查询接口子虚表, RTTI 定名) | — |
| +16 | 存档头元数据对象 (NNB, 224B; ctor sub_140BC0880/07B0; 布局详 §4.1.2) | top_meta 各行在其内部 |
| +48 | ironman 存档名 (MSVC 串 {buf@48, size@64, cap@72}; = 存档头键 ironman 值 + 文件名基名; loader 比对不符 → +192 清 bit0) | top_meta |
| +144 | **CGameDate#0 载入快照** 24B {vt1@144, hours@152, vt2@160} (= gs+16 元数据对象成员; CGameDate = CGregorianDate@0+CDate@8+CPersistent@16, vt2 = 序列化基; 仅读档路径写 hours) | top_meta ⚠ 非当前日期, 见下注 |
| +192 | uint32 位域 (bit0 = **ironman/成就门** (名比对, 非 checksum); bit1 = 多人局; bit2 = cooperative_game; bit3 = tutorial; 清位者另含控制台 "ironman off" sub_140248770 与无 playstream 时 sub_14163DA10) | top_meta |
| +240 | uint8 (ctor 置 1 旗; 运行期旗, 不序列化, 无读者 — 负定案非存档数据) | top_meta |
| +248..+271 | **联机同步校验对象** (24B; CCheckSyncCommand 载荷源 — sub_140DA3F20 定时构造, ctor sub_140DE5D10 读 +248+12 dword 计数) | top_meta |
| +256 | 同上对象成员 (+248 对象 +8) | top_meta |
| +272 | 同上对象尾成员 (+248 对象 +24 起) | — |
| +384 | CHuman country-link id (CHuman@272 内 +112, §4.1.1; 旧记 bitfield 系 gs+192 bit3 事实的重复登记) | — |
| +432 | 匿名结构 (NNB 形状) | — |
| +468 | 会话/顶部元数据 (TOPC) | top_meta |
| +600 | 匿名结构 (32B 形状) | flags |
| +608 | CCombatManager (内嵌, vt@槽自身 0X2950688; **+608..+687 全区间 = mgr 体内**) | combat / combat_details |
| +616 | 战斗明细容器数据 (CCombat 宿主**; count@+628) | combat_details |
| +628 | 战斗明细容器计数 (logmgr = +2176/+2188 容器) | combat_details |
| +640 | 注册 id (combat mgr 体内) | — |
| +648 | CCombatHistory (内嵌, vt 0X2950638) | combat_history |
| +656 | CCombat* | combat 容器数据指针 |
| +672 | u32 | combat 容器计数 |
| +680 | _bInCombatUpdate 旗 (combat mgr 体内, 断言定案) | — |
| +688 | **省指针数组** 数据 | province_buildings / province_extras |
| +696 | u32 | **省数组 cap** (四元组 {data@688, cap@696, count@700, alloc@704}) (counts) |
| +700 | 省数 | counts |
| +704 | CPdxNewDeleteAllocator* | 省数组 allocator (—) |
| +712 | **州表** 数据 | state / state_buildings / state_extras |
| +720 | u32 | **州表 cap** (loader states 用 id<*(gs+724) 铁证) (counts) |
| +724 | u32 | **州表 count** (= 州库条目数, loader 铁证) (counts) |
| +728 | CPdxNewDeleteAllocator* | 州表 allocator (—) |
| +736 | 区域表数据 (loader case 10827 region) | strategic_region |
| +744 | u32 | 区域表 cap (—) |
| +748 | u32 | 区域表 count (counts) |
| +752 | CPdxNewDeleteAllocator* | 区域表 allocator (—) |
| +760 | 匿名结构 (NNB 形状) 向量 | region→country 表 |
| +784 | **国家指针数组** | (全部国家 API) |
| +796 | 国家数 | counts |
| +808 | scoped_ptr<匿名结构 (NNB 形状)> | — |
| +832 | scoped_ptr<匿名结构 (NNB 形状)> | — |
| +856 | **tag 串表** | (全部 tag 反查) |
| +880 | uint8 向量 | `_CountryControllersEnable` (按国家 idx; 探针 333/333 = country_count) |
| +904 | uint32 向量 | 控制器计数 (按国家 idx; 探针 333/333 = country_count) |
| +928 | CTechnologySharingGroup* 向量 24B | **tech_sharing_group 组指针表** {data@928, cap@936, count@940, alloc@944} — 持全部实例 (非单指针; 组实例惰性创建: 首个 add_to_tech_sharing_group 才 malloc(0x50) 推入; 活体 count=0); 布局见 §4.7 CTechnologySharingGroup |
| +936..+960 | 匿名结构 (NNB 形状) | — |
| +984 | CSupplySystem* (vt0 0X2973CC8; 序列化基+8) | supply2 (天气不在此 — 天气 = gs+1672) |
| +992 | 铁路管理 CRailwayManager | rail_way |
| +1000 | NInternationalMarket::CEquipmentMarketSystem* | equipment_market |
| +1008 | CRaidSystem* | raid_countries / raid_targets |
| +1016 | 阵营 CFactionSystem | factions / faction_members |
| +1024 | 学说 CDoctrineSystem | doctrine |
| +1032 | scoped_ptr<匿名结构 (NNB 形状)> | — |
| +1040 | idpair | 全局 unit-leader CID 注册表 数据指针 (定制 vector, CGameState::Save sub_1401F2E40: 条目 8B {type u32@+0 (=4713), id u32@+4}; idx0 = null 哨兵不写; 序 = 注册序; 即顶层 `unit_leader` 存档块) |
| +1048 | u32 | CID 注册表 cap (loader 12354 铁证) (—) |
| +1052 | u32 | 全局 unit-leader CID 注册表 计数 |
| +1064 | CDifficultySettingItem** | difficulty_settings 容器数据 (元素 0xD8, 内嵌 CModifier@+16; loader case 13999) (difficulty) |
| +1076 | u32 | difficulty_settings 容器计数 (difficulty) |
| +1088 | scoped_ptr<CGameRules> | game_rules |
| +1096 | entity 持久注册器 (loader case 438) | entity |
| +1104 | CPowerBalanceSystem* (vt 0X296FCA0) | power_balance / country_characters (§4.3.21) |
| +1112 | u32 | 哨兵字段 (-1; 语义未定) (—) |
| +1120 | 内嵌 CGameDate | **当前日期对象** {vt@1120, days@1128} (SetCurrentDate sub_1401EDBA0 铁证) (date) |
| +1136 | 尾 vtable (CGameDate) | 当前日期对象尾 vt2 (对象 = {vt1@1120, hours@1128, vt2@1136}) (date) |
| +1144..+1160 | 派生日期缓存 (year@+1144, monthlen@+1148, doy@+1156, month@+1160; SetCurrentDate 写入) | date |
| +1168 | 会话 id/哈希 (loader case 13954) | session |
| +1180 | u32 | **debug_current_ref_id** (载入 case 11597 → 本槽; 写盘取静态 dword_1434520E0) (id) |
| +1184 | 内嵌 CGameDate | **start_date** (日期#2 三元组 {vt1@1184, hours@1192, vt2@1200}; loader case 10464) (start_date) |
| +1192 | u32 (hours) | **start_date** hours (日期#2 三元组中点 {vt1@1184, hours@1192, vt2@1200}) (start_date) |
| +1200 | 尾 vtable (CGameDate) | start_date 日期#2 尾 vt2 (三元组 {vt1@1184, hours@1192, vt2@1200}; loader case 10464) (start_date) |
| +1212 | u32 | **游戏速度 speed** (loader case 110) (speed) |
| +1216 | uint8 | 旗 (未名) (—) |
| +1224 | scoped_ptr<匿名结构 (NNB 形状)> | — |
| +1248 | CPeaceConferenceManager (内嵌, vt 0X2720E48) | peace_conference |
| +1256 | 未名 (ctor 零) | — |
| +1264 | 未名 (ctor 零) | — |
| +1280 | 内嵌 SSO 串 (cap 15) | **恒空串** (当前档 32B 全零, 仅 cap 字段 @+1304 = 15, len 0) — 非会话名载体 (—) |
| +1312 | 玩家 tag 对 (ctor 零填; combat 族线索保留高置信) | player |
| +1316 | 玩家 tag 对 (ctor 零填; combat 族线索保留高置信) | player |
| +1320 | u32 | **tension_scaling_base_country** (国家 idx; loader case 13913) (tension) |
| +1336 | u32 | fired_event_names 水位 (—) |
| +1340 | u32 | fired_event_names 桶数 (= 511; malloc 0xFF8 = 8×511) (—) |
| +1344 | 匿名结构 (桶链) 数组 | **fired_event_names 链式哈希桶数组** (桶内节点 {next@+8, id u32@+12}; writer sub_1401F2E40 以 +1340 为桶数界逐条以 token 11 `id` 发射, 紧接注册块名串 `fired_event_names` — 定案) (fired_event_names) |
| +1352 | token 对 向量 | **fired_events** (loader case 11003; 8B 元素, push 原语 sub_1401CBF60, 容器 {data@1352, cap@1360, count@1364, alloc@1368} — 定案) (fired_events) |
| +1376 | 匿名结构 (56B 形状) 向量 | pending_events 元素 56B |
| +1400 | — | runtime-only 残渣 (无消费者、无 loader/writer — 负定案) |
| +1424 | 匿名结构 (0xA8 形状) 向量 | **sunk_ship 历史容器** {data@1424, cap@1432, count@1436, alloc@1440} (元素 0xA8, ctor sub_140C2DCF0; loader case 10293) (sunk_ship) |
| +1448 | scoped_ptr<匿名结构 (24B 形状)> | sunk_convoy 条目 (0x18 对象; loader 14369; 高置信) (sunk_convoy) |
| +1456 | 未名 | — |
| +1472 | CNavalCombatResults** | **naval_combat_result 主数组** {data@1472, cap@1480, count@1484, alloc@1488} (loader case 13564; 元素键 13564) (naval_combat_result) |
| +1496 | unordered_map | naval_combat_result by-id 索引 (buckets 16; loader 双写) (naval_combat_result) |
| +1560 | — | 未决区 (q@1560 + u32@1568 + u8@1572; 无消费者、不序列化 — 负定案) |
| +1576 | 匿名结构 (NNB 形状) | **gameplaysettings** (vt@+1576; loader case 11102; 难度枚举@+1584 = 其体内字段, §4.1.1) (gameplay) |
| +1584 | 会话/顶部元数据 (TOPC) | top_meta |
| +1600 | CArmy* 向量 | (探针 37 项, 元素 vt = CArmy) |
| +1624 | CSelectionGroup 数组**指针** (10 组 × 240B, 组内 10 槽 × 24B {data@0, cap@8, count@+12, alloc@16}; **指针数组, 非内嵌头**, loader case 10286 `*(gs+1624)+240*组号`) | selection_groups |
| +1632 | u32 | 选择组容器 cap (容器 = {data@1624, cap@1632, count@1636, alloc@1640}) (selection_groups) |
| +1636 | u32 | 选择组容器计数 (= 国家库条数; 每国一组 240B) (selection_groups) |
| +1640 | CPdxNewDeleteAllocator* | 选择组容器 allocator (—) |
| +1648 | u32 向量 | **MP_locked_countries** 数据 (国家 idx 列表; loader case 11572) (multiplayer) |
| +1660 | u32 | MP_locked_countries 计数 (multiplayer) |
| +1672 | CWeatherManager* (vt 0X2977810; loader case 12040) | weather |
| +1680 | 战略空军 CStrategicAirManager | strategic_air / air_wings |
| +1688 | CNavyManager* (别名, vt 0X29732E0; 元素 CStrategicNavy) | navy / program_status / deployment_hq |
| +1696 | 谍报 CStrategicOperativeManager (RTTI 正名) | operatives |
| +1704 | 角色 CCharacterManager | characters / leaders |
| +1712 | 匿名结构 (NNB 形状) | **threat 世界紧张度管理** (0x40; loader case 11197) (threat) |
| +1728 | 匿名结构 (112B 形状) 向量 | **saved_event_target** (loader case 13217; 元素 112B {state@+8/country tid@+12/character idpair@+16/name u16@+104}) (saved_event_target) |
| +1752 | 匿名结构 (NNB 形状) 向量 | scope→saved event target |
| +1776 | CReferencedDivisionTemplate** 容器数据 (count@+1788) | division_templates |
| +1784 | u32 | 编制模板容器 cap (loader 13369 循环 12112) (—) |
| +1788 | u32 编制模板容器计数 (stockpile 共用区语义见 §4.23.2) | division_templates 计数 |
| +1792 | CPdxNewDeleteAllocator* | 编制模板容器 allocator (—) |
| +1800 | CEquipmentVariant** 容器数据 (cap@+1808, count@+1812) | equipments |
| +1808 | u32 | 装备变体容器 cap (loader 12122) (—) |
| +1812 | u32 装备变体容器计数 | equipments 计数 |
| +1816 | CPdxNewDeleteAllocator* | 装备变体容器 allocator (—) |
| +1824 | u32 | **game_unique_seed** (loader case 13737) (seed) |
| +1832 | SSO 串 | **game_unique_id** (size@+1848, cap@+1856=15; loader case 15232) (uid) |
| +1864 | u32 | **land_combat_id** (loader case 13478) (id) |
| +1868 | u32 | **navy_id** (loader case 13477) (id) |
| +1872 | CNonstaticIdGenerator\<74\> (内嵌, vt 铁证) | **railway_gun_index** (**非裸 u32, 是 id 生成器对象**; loader case 19733) (railway_gun_index) |
| +1888 | CNonstaticIdGenerator\<79\> (内嵌) | **industry_organisation_index** (loader case 14492) (industry_organisation_index) |
| +1904 | CNonstaticIdGenerator\<86\> (内嵌) | **special_project_index** (loader case 16401) (special_project_index) |
| +1920 | CNonstaticIdGenerator\<83\> (内嵌) | **program** id 生成器 (vt RVA 0x2721040 = `$0FD::` 表; 计数值与写盘块 `program` 对证) (program) |
| +1936 | CNonstaticIdGenerator\<87\> (内嵌) | **program_supply_consumer** (loader case 12849) (program_supply_consumer) |
| +1952 | CIdCounterStore (内嵌) | **id_counter_store** (loader case 15101) (id_counter_store) |
| +1960 | 未名 | — |
| +1968 | 未名 | — |
| +2008 | 匿名结构 (160B 形状) | — |
| +2168 | u32 | **average_major_ic** (÷1e5 fixed5; loader case 13885) (ic) |
| +2176 | combat log manager 指针数组数据 (supply2 = rp(gs+984)+8; loader case 14037) | combat_log |
| +2188 | combat log 数组上界/计数 | combat |
| +2200 | 匿名结构 (NNB 形状) | **all_playthrough_data 宿主** (loader case 16067 + 合并 sub_1401E3270 铁证) (all_playthrough_data) |
| +2232 | uint8 | **statistics_collection_enabled** (loader case 15933) (statistics) |
| +2240 | scoped_ptr<匿名结构 (NNB 形状)> | — |
| +2264 | 匿名结构 (NNB 形状) | **intermediate_statistics** (0x180, ctor sub_14068E300; loader case 15959) (intermediate_statistics) |
| +2272 | 匿名结构 (NNB 形状) | **career_profile_player_flags** (0x20, ctor sub_140CBF4A0; loader case 16065) (career) |
| +2280 | unordered_map (未名; head 自环 + buckets 16) | — |
| +2344..+2368 | 未名 | — |
| +2376..+2400 | 未名容器簇 | — |
| +2408..+2424 | 未名 | — |
| +2432 | 全局 CVariables** (0x38, defines 全局入构; loader case 10826) | variables |
| +2440 | 24B 元素数组 | **逐国家 24B 数据数组** {cap@+2448, count@+2452, alloc@+2456} (count = 国家库条数 451) (—) |
| +2464 | scoped_ptr<匿名结构 (NNB 形状)> | — |
| +2492 | u32 | **cached_active_trade_route_count** (loader 10102) (trade) |
| +2496 | u32 | **next_trade_route_update_country_idx** (loader 10103) (trade) |
| +2504 | std::map (未名) | — |
| +2520 | std::map | **ships_built** (map<u32 键, u32 数量>; loader case 10192) (ships_built) |
| +2536 | 容器 (未名) | — |
| +2544 | 容器 (未名) | — |
| +2576 | 32B 元素数组 | **边界高亮自定义色表** (count@+2588 = defines BORDER_COLOR_CUSTOM_HIGHLIGHTS/4; gamestate.cpp:781 警言铁证) (border_color) |
| +2600 | 指针 | **当前书签对象** (新局 sub_1401A5630 写所选书签; 读档 sub_1401E2AC0 重置默认书签 — Null-Object getter sub_1401DBBB0; 全量重建门 = 与目标书签指针不等, sub_14067EEE0 → sub_1401A5630, §4.28.18) |
| +2608 | u32 | **tutorial 章节 id** (loader case 13842, 另置 gs+192 位域 bit3 与 u8@+2615=1) (tutorial) |
| +2612 | uint8 | **HasGameStarted** (getter sub_1401E2930; 世界构建 sub_1401E2AC0 开头置 1) |
| +2613 | uint8 | **世界构建进行中门** (sub_1401E2AC0 开头置 1 / 尾清 0; 多系统读者以 `!+2613` 作跳过门, §4.28.18) |
| +2615 | uint8 | tutorial 旗 A (同上) (tutorial) |
| +2616 | uint8 | tutorial 旗 B (同上) (tutorial) |

> **+152 CGameDate#0 = 载入快照, 非当前日期** (定案): 只有**读档**路径写它
> (loader 落档时的 hours), 此后**不随游戏时钟推进**; 新建开局走 ctor 不写,
> 停在 ctor 哨兵 43808760 (显示 "1.1.1.1")。**当前日期读 gs+1128**
> (= CGameDate@+1120 的 hours, §4.1.1 SetCurrentDate sub_1401EDBA0
> `a1[282] = *a2` 铁证; 与存档头 `date=` 逐刻吻合)。把 +152 当 date 用 =
> 新建档恒错、读档在载入刻之后全错, 且错得与真值同形 (只差几小时) 极难察觉。

### 1.3 运行时 vtable RVA 表 (BASE 相对, 每次解引用前校验)

| 常量名 | RVA | 类 |
|---|---|---|
| char | 0X297EA60 | CCharacter |
| raid_status | 0X29CCD88 | NRaids::CCountryRaidStatus |
| doctrine_cs | 0X29653F8 | NDoctrines::CCountryDoctrineStatus |
| folder | 0X29653A8 | CFolderStatus |
| track | 0X2965358 | CTrackStatus |
| province1 | 0X2971B18 | CProvince |
| HYBRID | 0x3085170 | CPdxHybridInlineBuffer (分配器标记) |
| OPS.so_vt | 0X29A2358 | CStrategicOperative (谍报机构国家条) |
| OPS.net_vt | 0X29A1A58 | CCountryIntelNetwork (谍报网) |
| OPS.sub_vt | 0X29A1AA8 | CSubIntelNetwork |
| OPS.mgr_vt | 0X2973B80 | CStrategicOperativeManager (谍报管理器) |
| SA.mgr 0X29588F8 / SA.sa_country 0X29587D8 / SA.pool 0X297AE38 | — | CStrategicAirManager / CStrategicAir (国条) / CAirWingPool |
| WX.mgr 0X2977810 / WX.prov 0X2977770 | 天气管理/省天气 | weather |
| CBT.mgr 0X2950688 / logmgr 0X295D8D8 / hist 0X2950638 | 战斗管理/日志/历史 | combat |
| EQ.vt 0X2951608 | 装备 | equipments |
| DTP.vt 0X294F5B0 | 编制模板 | division_templates |
| ARMY.vt0 0X295A2B0 / vt1 0X295A490 / pool_vt 0X2749270 | 集团军 | divisions |
| NAVY.mgr_vt 0X29732E0 / navy_vt 0X2973260 / base_vt 0X29731C0 | 海军 | navy |
| PB.sys_vt 0X296FCA0 / bop_vt 0X296FC50 | 力量平衡 | power_balance |
| MIO.org 0X2967A28 | MIO 组织 | mio |
| SELPC.pc_vt 0X2720E48 | 和会 | peace_conference |
| state buildings bs | 0X2999050 | 州/省建筑容器 |

(未录入本表的局部 vtable 常量一律以 §4 各类条目内标注为准; objects.lua 仅作历史出处引注)

### 1.4 控制台命令管理器 (CConsoleCmdManager)

| 挂载点 | 类型 | 语义 |
|---|---|---|
| BASE+0x35E1A80 | CConsoleCmdManager* | 命令管理器全局槽 (惰性构造; 取用前须先读槽, 空则先 ctor) |

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | 命令条目* | 条目数组基址 (条目跨距 456) |
| +12 | int | 条目计数 |
| +217 | uint8 | 投递旗 (原生提交路径每次清零) |

| 条目偏移 | 类型 | 语义 |
|---|---|---|
| +0 | uint8 | dev 旗字节 |
| +8 | std::string | 命令名 (SSO 内联; 查找走大小写不敏感比较) |
| +104 | 函数指针 | handler |
| +120 | void* | userdata (原样透传给 handler) |
| +136 | uint32 | flags |
| +264 | uint32 | 权限值 |

| handler ABI | 形 | 语义 |
|---|---|---|
| 参 1 | 匿名结构 (40B) | 返回槽: +0 uint8 状态 / +8 std::string 回显文本 |
| 参 2 | 匿名结构 (24B) | 参数容器: +0 元素数组基址 / +12 int 元素计数 |
| 参 3 | void* | 条目 +120 的 userdata |

| 参数元素 | 形 | 语义 |
|---|---|---|
| +0 | std::string (32B) | 单个参数 (元素跨距 32) |

> 条目数组为**值数组**: 枚举 = 逐条读 `+8` 名串, 计数取管理器 `+12`。
> 参数容器的计数在 `+12` **而非** `+8` — 按 std::vector 布局 (begin/end/cap) 伪造会被引擎读成 begin 指针高位当计数, 走进数千条垃圾串。
> 回显文本无长度上限, 长度取自 std::string 的 `+16` 字段; 读取方自行限幅会截断长输出 (help/list_flags 类命令远超千字节)。
> 命令名查找为**大小写不敏感**整串比较。

**原生命令行切词契约 (定案)**: 只按**空格**切分, 引号是**普通字节** — 无分组、无剥离、无转义。因此 `cmd "a b"` 恒为两个参数 `"a` 与 `b"`, 任何依赖"引号内空格算一个参数"的假设都不成立。

| 切词环节 | 语义 |
|---|---|
| 语句分隔 | 固定串 `" && "` (前后各一空格) |
| 语句首尾 | 剥 `\n \t \r` 与空格 |
| 参数分隔 | 仅空格; 制表符**不是**分隔符 (会成为 token 的一部分致命令名失配) |
| 连续空格 | 产生的空元素被剔除, 等效单空格 |
| 引号 | 普通字符, 原样保留进参数 |
| 转义 | 无 (`\"` 即两字符) |

> `.txt` 脚本词法器是**另一条路径**, 确有引号分组与剥离; 控制台不经过它, 两者语义不可互推。
> 需要传含空格参数时不能用命令行形式, 须按参数容器直接构造 (逐元素写入, 计数落 `+12`)。

## 2. 类树总览

```
CGameState (gs)
├─ [gs+784] CCountry* countries[440]
│    └─ CCountry (cc) — 详见 §4.3 国家树 (下挂 60+ 子系统指针)
├─ [gs+688] CProvince* provinces[]  → CProvince.buildings (CBs 0X2999050)
├─ [gs+712] CState states[]         → CState.variables / buildings / …
├─ [gs+856] tag 串表
├─ [gs+1008] CRaidSystem → CCountryRaidStatus[440+] → CRaidInstance (§4.27)
├─ [gs+1016] CFactionSystem → members (0xD0 stride)
├─ [gs+1024] CDoctrineSystem → CCountryDoctrineStatus (0xA0 stride)
│    └─ folders → tracks → (doctrine tree)
├─ [gs+1104] 力量平衡 CPowerBalanceSystem (按国家索引; §4.3.21)
├─ [gs+1248] CPeaceConferenceManager (内嵌; §4.10.26; 谍报网在国家侧, §4.11)
├─ [gs+1672] 天气管理 → CWeatherRegion[] / CWeatherProvince[]
├─ [gs+1680] CStrategicAirManager → sa_country[] → CAirWingPool[] → CAirWing
│    └─ CAirWing: mission(嵌) / equipment / combat_history / oc/gix/rdi
├─ [gs+1688] 海军 CNavyManager → navy → taskforce → ship
│    └─ CShip.history(+2264) 内嵌 CSunkShipInfo; gs+1424 沉船总账 / gs+1448 运输船月账 (§4.16.13/§4.16.14)
├─ [gs+1696] CStrategicOperatives mgr → so (COperative 槽)
├─ [gs+1704] CCharacterManager → historical[] + dynamic[] → CCharacter
│    └─ CCharacter → leader(CCommander) / operative / advisor / portraits
├─ [gs+992] CRailwayManager → CProvinceRailwayInfo (§4.14.6/§4.14.7)
├─ [gs+2520] ships_built RB-tree 造舰统计 (§4.1.16)
├─ [gs+1800/+1812] 装备定义/管理
└─ [gs+608/616/2176/648] 战斗: CCombatManager / details 容器 / logmgr / CCombatHistory (同 §1.2)
```

国家树 (cc 下挂, 偏移为十进制; 完整字段见 §4.1):

```
CCountry (cc)
├─ +3936  CTechnologyStatus (科技) → technologies[] / slots[] / limited_use_bonus[]
├─ +3952  CDeployment (部署) → unit_modifiers[112B] / conveyors / hq
├─ +4088  D60 incoming 容器
├─ +552   ( diplomacy → +2800 链: recently_invaded 等)
├─ +536   CVariables* (reader country_variables73)
├─ +544   scripted_gui_random 锚 (直读 cc+544 — ⚠ 536+544 = 0x220 = 544 数值巧合, 勿作链式读)
├─ 其余 60+ 子系统指针 — 全表见 §4.3.1 (CCountry 字段布局) 与 §1.2 (gs 管理器总表)
```

---
(以下 §3 起逐类详解 — 按 §2 树序)

## 3. 通用容器与数据结构算法 (语言无关)

### 3.1 std::vector

连续元素数组。三件套 `{data 指针, count, cap}` 的偏移**每个类各不相同**,
类条目中以 `容器: data@+X, count@+Y` 标注。元素两种形态:
- 元素为指针: 第 i 个元素 = `*(data + 8*i)`, 再解引用得对象
- 元素内联: 第 i 个元素地址 = `data + stride*i` (stride 在条目标注)

计数偏移的两种真实形态 (全库统计):

| 形态 | count 相对 data 的位移 | 规模 | 说明 |
|---|---|---|---|
| 主流 | 12 | 452 处 | `{data, cap, count}` — data 与 count 之间隔一个 cap 字段 |
| 变体 | 8 | 13 处 | `{data, count}` — 无 cap 间隔 |

> 两形态**不可合并为单一常量**: 差 4 字节会读到相邻字段当计数, 量级可能仍
> 落在合理区间 (不报错但错值)。取计数前须对表确认属哪一形态。
> 容器枚举原语以 delta 参数区分 (§3.10)。

### 3.2 robin-hood 哈希表

桶 24 字节: `{值或指针 uint64@+0, dist uint32@+4, 键 uint32@+8}`。
- dist = 0: 空桶; 墓碑/特殊标记 = **0xFE 与 0xFF 双值** (各表实证不一: apd RH map 0xFE=墓碑, 他表 0xFF=墓碑; 防御取并集)
- 遍历: 扫描全部桶, 跳过 dist∈{0, 0xFE, 0xFF}; 上界 = mask+1+extra
  (mask = 表对象内 uint32 字段, extra = 表对象内 uint8 字段, 位置见类条目;
  漏掉 extra 会丢失尾部分裂桶 —— OCC 表实测教训)
- 值对象仍需 vtable 校验 (残留指针可能是悬垂)
- ⚠ **桶分型注意 (待裁)**: 上式为通用正形; 在案存在布局不同的变体 — §4.1.8 gs+2208 桶 {dist uint8@+4, key u32@+8, value@+16} 与 §4.26.5 id 注册表桶 {dist@+4, type u32@+8, id u32@+12, obj@+16}。套用正形前先对表, 勿跨型混读。
- **RH 表通用尾**: {…, extra u8, **max_load_factor f32 = 0.9** (0x3F666666 = 1063675494)} — CVariables+44 / CNavalRegionDominance+60 / CModifier+148/+180 四处 ctor 常数同构互证。

### 3.3 std::map (红黑树)

节点布局:

| 偏移 | 内容 |
|---|---|
| +0 | left |
| +8 | parent |
| +16 | right |
| +25 | color/isnil byte |
| … | 键值 (偏移见类条目; 常见: 键 token@+32, 值@+40) |

- 容器对象首 8 字节 = 头节点指针; 头节点自身是哨兵
- 实节点判定: isnil 字节 == 0
- **中序遍历顺序 = 存档写入顺序** (对拍依赖此性质)

### 3.4 环形缓冲 (ring buffer)

`{buf 指针@+16, capacity uint32@+24, head uint32@+28, tail uint32@+32}`。
- 元素数 = tail - head; 为负则加 capacity
- 第 i 个元素 = `buf + ELEM_SIZE × ((head + i) mod capacity)`
- 序列化顺序 = head → tail

### 3.5 MSVC std::string (SSO)

布局:

| 偏移 | 类型 | 内容 |
|---|---|---|
| +0 | 匿名 union (内联 char[16] / 堆指针) | 字符缓冲 (内联) 或堆指针 |
| +16 | uint32 | size |
| +24 | — | cap |

- size ≤ 15: 字符内联在对象本体偏移 +0 处
- size > 15: +0 处是堆字符缓冲指针
- 读取: 按 size 逐字节取 (小端读取时取每字节低 8 位)
- 注意"自研变体串": 部分类 (如舰队名) 全量走堆指针形态, size 字段位置
  见类条目

读串双形态 (读取端必须区分) — 内存中存在两种"字符串"形态,
对应两种读原语, 不可混用:

1. **MSVC std::string 对象** (SSO 形态, §3.5 布局): 读原语吃**对象首址**,
   按 size+cap 判内联/堆。`size == 0` 时返回**空串 ""** 而非 nil
   (C 版此时返 nil, Lua 版返 "" — scripted_effects 1522 /
   scripted_triggers 889 / unit_names 20 对齐的依据; 消费端以 truthy 判
   存在时会误判, 须显式 `#s > 0` 判空)。
2. **裸 char 缓冲** (C 串, 零结尾): 读原语吃**缓冲首址**读到 \0。

`hoi4.read_str` 是**智能 reader**: 拿到的地址若实为裸堆串而非 std::string
对象, 会把开头字符误读成 size/buf 字段 — 两种症状:
- name_groups (NGRX) 链: 名为裸 char 缓冲, read_str 误读 size=0 → 返回
  空串 (truthy) → 全部导成空值;
- factory 条目名 (FCR) 链: read_str 返 `"?"` 哨兵 → `#name>=4` 长度门
  全滤 → 导出 0 行。

**铁律**: 已知字段是裸 char* 时一律 `read_cstr` (或等价零结尾读取);
不确定形态时按 `read_cstr 优先, read_str 兜底` 双试 (objects_v2
name_groups 同链写法: `hoi4.read_cstr(p) or hoi4.read_str(p)`)。

**长度上界与截断**: 三个串读取原语共用上界 `STR_READ_MAX = 131072`
(128 KB), 超出即截断 (不返 nil)。Lua 侧同值常量 = `M.lim.STR_READ_MAX`,
**两侧必须同步改**。

| 原语 | 输入 | 收尾 | 字节集 |
|---|---|---|---|
| `read_cstr(addr)` | 裸 C 串缓冲首址 | 首个 NUL 或 128 KB | 无过滤, 任意字节含 UTF-8 直通 |
| `read_str(addr)` | `std::string` 对象首址 | 首个 NUL (len 仅作上界) | 同上 |
| `read_bytes(addr, n)` | 任意地址 + 精确长度 | **无** (定长, 内嵌 NUL 保留) | 任意 (n ≤ 64 MB) |

> `read_str` 的内容在 NUL 处结束是**刻意**的: SSO 16 字节缓冲对短串尾部
> 留零, 若按 len 整取会带回 NUL 填充 (实测 `name_group[961]` 的 12 字符名
> `_refit_speed` 在 len=15 槽上会变成带 3 个 NUL 的串)。`M.read_msvc_str`
> 因此用 `#s == len` 判合法性 — 不等即视为填充/垃圾槽, 返 nil。
> `read_bytes` 是唯一能取定长缓冲/二进制块的途径 (`read_cstr` 遇内嵌 NUL
> 提前停, `read_str` 需合法串对象)。

### 3.6 id 对 (id-pair)

8 字节 `{type uint32@+0, id uint32@+4}`。序列化顺序: 先写 id 后写 type,
存档行形如 `id=<X+4> type=<X+0>`。

### 3.7 数值换算

- **读原语符号语义 (定案)**: `hoi4.read_u64` C 侧 = `lua_pushinteger((lua_Integer)
  *(volatile uint64_t*)addr)`, **已是带符号重解释** — 高位为 1 的 64 位值以
  **负值**入栈, 故 Lua 侧收到的就是最终带符号值, 无需再补符号。
  ⚠ 因此 `v >= 0x8000000000000000 and v - 0x10000000000000000` 是**恒真空操作**
  (左式对负数恒真, 右式 `0x10000000000000000` 字面量回绕为 0); 窄读
  (`read_u8/u16/u32`) 是零扩展, 补符号仍必需 — 8 字节无更宽类型可加宽, 位模式
  原样落地 (Lua 整数即带符号视图); 引擎**无** `read_i64` 函数 (与 read_u64
  逐字节同义, 只差名字所标的字段意图)
- fixed×1e-5: raw 为 **int64** (带符号), 值 = raw × 1e-5 = raw / 100000
  (入口 `M.fix5` / `M.fix5_raw`; 除法不可代以 `*1e-5`, 见 §4.34)
- **位模式重解释的拆字必须用位运算 (定案)**: 把 qword 位模式当 double 重解释
  (`M.define_f`: `string.pack("<I4I4", lo, hi)` 后 `unpack("<d")`) 时,
  取高低两字只能写 `lo = bits & 0xFFFFFFFF` / `hi = (bits >> 32) & 0xFFFFFFFF`。
  ⚠ 禁用 `bits % 0x100000000` / `math.floor(bits / 0x100000000)` 一族:
  `bits / 2^32` 走 float 除法, 商在低位非零时被舍入进位 → 高字差 1 →
  **尾数错 ~7e-7** (实测位模式 `0x966C…` → 误 `-3.6207579e-200` vs 真
  `-3.6207555e-200`; 20 万随机位模式中 1 例, 概率低但静默错值)。
  负数位模式无需先"转无符号": `&`/`>>` 对负数取的是同一位段, 构造上精确
- Q15: 值 = raw / 32768
- CGameDate hours → 日历: day0 = floor((h − 43800000)/24); 年 = floor(day0/365);
  年内天 = day0 mod 365; 按平年月表 (31,28,31,30,31,30,31,31,30,31,30,31)
  逐月扣减得月日; 时 = h mod 24 + 1。哨兵 43808760 ("1.1.1.1") = 未设,
  writer 恒省略该值。历史年份门已放宽 (任意 yr ≥ 1 有效, mod 档历法 1007/1910)
- **CGameDate 双哨兵**: 43808760 之外另有
  **43817520 ("2.1.1.1", dword_143086B38) = CGameDate 默认构造值**;
  带门字段 (writer `!=` 检查: faction spymaster_change_date /
  faction_leader_change_date / RCG.last_sunk_convoy_date 等) 一律跳过
  43817520; 无门字段 (threat.date / sunk_ship.date / goal game_data, writer
  ADEC0 恒写) 43817520 也照写 "2.1.1.1"。43808760 亦 = loader 落档转换值
  (goal game_data 默认 → "1.1.1.1" 照写)。
- **哨兵值全表 (u32 空间)**: 0 = 未初始化; 43808760 = 默认构造 "1.1.1.1";
  43817520 = CGameDate 默认构造 "2.1.1.1" (见上条); 43791240 (0x29C3388) =
  "-1.1.1.1" **合法值** (部分字段当哨兵滤, 部分字段照写, 见 §3.7b);
  43808760 (0x29C77F8) = obsolete_change_date 字段专属默认哨兵。
- **reader 侧唯一实现**: 日历换算全库只在 `hoi4_layout.lua` 实现一次
  (`M.date_opt` 核心 + `M.date`/`M.date_raw`/`M.date_quoted` 三个包装),
  `objects_v2` U.date / `sv2_lib` SL.date / 各 sv2 段一律委托, 禁止再写
  本地副本 (收敛前曾有 12 处拷贝, 语义分歧见 §3.7b)。
- **÷1e5 换算存在多条舍入路径 (GUI/显示域横向台账)**: ① 裸 magic-mul
  `imul 0x29F16B11C6D1E109; sar rdx,0xE` = **截断向零** (计数文本族常用);
  ② 舍入器 sub_1424ED730 = 正支 (x+50000)/1e5 **round-half-up**, 负支
  (x−50000)/1e5 **round-half-away-from-zero**; ③ Q15 分数支 sub_1424ED580
  加 0x4000 后 round-half-up 且带溢出饱和哨兵; ④ 阈值直比 (不换算, 比较在定点域);
  ⑤ float 域 `cvttss2si` (截断) 且无钳位 (如 CTinyUnitCounter spotting)。
  读显示值须按消费点所属路径定舍入方向, 勿统一按截断处理。

### 3.7a CGameDate 内嵌序列化两族判别通则

- **24B 双 vtable 通用形态 (序列化器直读 + CSunkShipInfo/CThreatSource/CHuman/
  COperativeLeader 四处 ctor 互证)**: CGameDate 实为 **24B 双 vtable**
  {vt1@+0 (0x1427183A8 玩法虚表), hours u32@+8, pad@+12, vt2@+16 (0x1427183d8
  持久化虚表)}。旧「族 A 16B {hours@X, vt@X+8}」= 同一 24B 对象的**后 16B** ——
  vt1@X−8 此前被系统性吞进 date 前 15B「未知」残留行 (典型 = 前字段尾+vt1 8B),
  这是一大批该类残留行的统一来源。序列化器 = **vt2 slot1 sub_140533F70**
  (读 hours=`*(arg−8)`, 全对象=`arg−16` → sub_1422690C0 转串)。判别规则不变:
  ADEC0 收 &vt2=基+16, hours=arg−8=基+8; 0X1422690C0 直调收对象基址,
  hours=arg+8。凡 ctor 现 "vt@X, hours 哨兵@X+8, vt@X+16" 三元组即命中。
- **族 A (ADEC0/vt 槽族)**: 内嵌形态 = 24B 对象后 16B (vt1@X−8 见上条):

  | 偏移 | 类型 | 内容 |
  |---|---|---|
  | +0 | uint32 | hours |
  | +4 | uint32 | pad |
  | +8 | 8B | vt |

  writer 把 `&vt (= 基址+8)` 传给
  `sub_1424C2E20(a2, 0x284A=10314 date, ptr)` → **hours = 序列化指针 − 8**;
  写门 (若有) 直读 hours@基址。实证:

  | 案例 | 序列化指针 (vt 槽) | hours 偏移 | 备注 |
  |---|---|---|---|
  | combat air_plane | +48 | +40 | 门同址 |
  | combat_data | +1080 | +1072 | |
  | CPerTemplateStats | +48 | +40 | |
  | combat_log 子条目 | +32 | +24 | |
  | technology date | +392 | +384 | 门同址 |
  | war_relation start | 槽@+40 | +32 | |
  | war_relation end | 槽@+64 | +56 | |
- **族 B (自由格式化器族, 目前唯一例)**: 战斗历史 end_date — writer
  `sub_1422690C0(a1+2=e+8, &str)` 把**基址−8 处**当参数, 格式化器读
  `*(arg+8)` → **hours = 参数+8 = e+16** (方向与族 A 相反!)。误读 e+8
  的症状 = 把 vt 低 32 位当 hours → "323369.4.26.9" 式巨年。
- **实用规则**: ADEC0 序列化的 date → hours = ptr−8; 见 0X1422690C0 直调
  → hours = arg+8。拿不准时对拍一个已知日期叶即可分辨。
- **发射器别名映射** (书内历史代号 → 1.19.3 dump 实名): ADEC0 =
  sub_1424C2E20 (嵌套块发射器) / ADFE0 = sub_1424C2F40 (u32 叶) /
  AE670 = sub_1424C35D0 (i64 fixed 叶) — 代号在 dump 无同名函数, 按名
  grep 落空时用本行换算。
- **24B 形态 (= 通用本体)**: CGameDate = 24B:

  | 偏移 | 类型 | 内容 |
  |---|---|---|
  | +0 | 8B | vtA (0x1427183A8 玩法虚表: 读 hours@+8) |
  | +8 | uint32 | hours |
  | +16 | 8B | vtB (0x1427183d8 持久化虚表: 写适配器 0x140533f70) |

  写适配器收 a1=vtB 地址, 内部 `sub_1422690C0(a1-16)` 回对象基址读 hours。
  读侧直取 ru32(obj+8), 无需碰 vt:

  | 字段 | CGameDate 基址 | hours 偏移 | 守卫 |
  |---|---|---|---|
  | creation_date | oi+64 | +72 | hours≠0 (43808760→"1.1.1.1" 照常写) |
  | starting_date | oi+88 | +96 | 同上 |
- 门哨兵 dword_143086B20 (BASE+50785056): air_plane date / state
  last_strategic_bombing 的"默认值不写"比较对象 (运行时读值比较)。

### 3.7b CGameDate 三变体 (门 + 输出形差异; 选型以所属 writer 为准)

日历算法 (含哨兵语义) 相同, 差异只在前置哨兵门与输出串形。**调用方按该字段
writer 的实写行为选变体, 禁止按"显示值看着一样"混用** (两者会给出不同结果):

| 变体 | 门 (u32 回绕后) | 输出形 | 适用 |
|---|---|---|---|
| `date(h[, min_year])` | 滤 {0, 0x29C3388, 43808760}; `min_year` 给"年<min_year 弃" | `Y.M.D.H` | U.date (`min_year=1`) / SL.date (无年门) |
| `date_raw(h)` | u32→i32 回绕, 滤 {≤0, 0x29C3388}; **43808760 照发 "1.1.1.1"** | `Y.M.D.H` | 部队/志愿者 start_date/end_date、country_scalars; legacy `date_from_hours_raw` |
| `date_quoted(h)` | **不滤** (nil 外一律换算, 含 0 → 负年) | `"Y.M.D.H"` 引号形 | combat naval last_external_wave_date、country_reports.date、theatre creation_date/starting_date |

注: 0x29C3388 在 `date_raw` 被滤、在 `date_quoted` 照写 "-1.1.1.1" —— 这是
两族最易互错的点; 0 在 `date_quoted` 产出负年份 ("-5000.1.1.1"), 非哨兵。

### 3.8 常见写出门 (序列化条件) 速查

| 门 | 语义 | 典型字段 |
|---|---|---|
| ≠0 才写 | 零值省略 | victory_points, nukes |
| >0 才写 | 无符号正数 | 各计数 |
| ≠100000 (fixed 1.0) | 非默认值 | building repair_speed_factor |
| ≠357 (token) | 357 = 空引用 | 部分引用字段 |
| string size ≠0 | 空串省略 | 省名等 |
| 四条件或: level>0 ∨ rp>0 ∨ 在研槽 ∨ lub计数≠0 | tech 块存在性 (见 §4.7) | technologies |
| int8 截断 | writer 只写低 8 位带符号 | air mission period |

### 3.9 RTTI 继承谱系

> 读法: vt 列 = `RVA@+mdisp` (mdisp = 该 vtable 子对象在完整对象中的位移;
> 多 vt = 多基类子对象)。基类列 = RTTI 基类数组全祖先扁平链, `@+N` =
> 该基类子对象位移, (虚) = 虚拟继承。
> **核心语义**: id 注册表 (§4.26.5 idreg_unit_resolve) 存的是 **CPersistent 子对象指针**
> — CArmy/CUnit/CAirWing 的 CPersistent@+16 ⇒ raw = res−16
> (volunteers/exile "库存指针 this 调整" 的根基, 谱系实证);
> CSupplySystem 的 CPersistent@+8 ⇒ 序列化基 = obj+8。
> **CPersistent 虚表槽契约 (Save/Load/writer/reader 入口) 见 §4.00.1**:
> 主虚表 [1]=Save/[2]=writer/[3]=Load/[4]=reader —— 新类定序列化入口直接取槽。

| 类 | vtable (RVA@+mdisp) | 基类 (← 扁平全祖先, @+N=子对象位移) |
|---|---|---|
| CCountry | 0X27E7360@+0 | CAIOwner ← CPersistent |
| CArmy | 0X295A2B0@+0 / 0X295A490@+16 / 0X295A500@+184 / 0X295A548@+824 | CUnit ← CSelectable ← CSupplyConsumer@+16 ← CReferenceObject@+16 ← CPersistent@+16 ← COrdersGroupMember@+184 ← IOfficerHolder@+824 |
| CUnit | 0X29530D8@+0 / 0X29532B0@+16 / 0X2953320@+184 | CSelectable ← CSupplyConsumer@+16 ← CReferenceObject@+16 ← CPersistent@+16 ← COrdersGroupMember@+184 |
| CRailwayGun | 0X2972228@+0 / 0X2972400@+16 / 0X2972470@+184 | CUnit ← CSelectable ← CSupplyConsumer@+16 ← CReferenceObject@+16 ← CPersistent@+16 ← COrdersGroupMember@+184 |
| CUnitLeader | 0X2955B90@+0 | CUnitLeaderBase@+24 ← CReferenceObject ← CPersistent ← …::…(模板trait)@+3808 |
| CArmyLeader | 0X2955CA8@+0 | CUnitLeader ← CUnitLeaderBase@+24 ← CReferenceObject ← CPersistent ← VCUnitLeader::…(模板trait)@+3808 |
| CNavyLeader | 0X2955DC0@+0 / 0X2955ED8@+3928 | CUnitLeader ← CUnitLeaderBase@+24 ← CReferenceObject ← CPersistent ← VCUnitLeader::…(模板trait)@+3808 ← CCustomizableBuildingListener@+3928 ← $00::…(模板trait)@+3928 ← NImpl::…(模板trait)@+3928 |
| COperativeLeader | 0X2955F00@+0 / 0X2956018@+3928 | CUnitLeader ← CUnitLeaderBase@+24 ← CReferenceObject ← CPersistent ← VCUnitLeader::…(模板trait)@+3808 ← COperativeLeaderBase@+3944 ← CSelectable@+3928 |
| CReferencedDivisionTemplate | 0X294F5B0@+0 | CReferenceObject ← CPersistent |
| CStrategicNavy | 0X2973260@+0 / 0X2973290@+8 | CBuildingListener ← $00::…(模板trait) ← NImpl::…(模板trait) ← CPersistent@+8 |
| CNavalBase | 0X29731C0@+0 | CPersistent |
| CSupplySystem | 0X2973CC8@+0 / 0X2973CF0@+8 | CProvinceListener ← $0A::…(模板trait) ← NImpl::CEmptyClass@+8 ← CPersistent@+8 |
| CCountrySupplySystem | 0X29A2B08@+0 / 0X29A2B58@+8 | CPersistent ← CEquipmentDistributable@+8 |
| CCombat | 0X29BBC58@+0 / 0X29BBD30@+16 | CSelectable ← CReferenceObject@+16 ← CPersistent@+16 |
| CLandCombat | 0X29A83D8@+0 / 0X29A84B8@+16 | CCombat ← CSelectable ← CReferenceObject@+16 ← CPersistent@+16 |
| CNavalCombat | 0X29DDB08@+0 / 0X29DDBE0@+16 | CCombat ← CSelectable ← CReferenceObject@+16 ← CPersistent@+16 |
| CLandBorderWarCombat | 0X29BC5F0@+0 / 0X29BC6D0@+16 | CLandCombat ← CCombat ← CSelectable ← CReferenceObject@+16 ← CPersistent@+16 |
| CCombatManager | 0X2950688@+0 | CPersistent |
| CCombatHistory | 0X2950638@+0 | CPersistent |
| CWeatherManager | 0X2977810@+0 | CPersistent |
| CPowerBalanceSystem | 0X296FCA0@+0 | CPersistent |
| CPowerBalance | 0X296FC50@+0 | CPersistent ← …::…(模板trait)@+8 |
| CNationalFocus | 0X2739C08@+0 | CPersistentWithToken ← CPersistent ← CProfiledScopeObject@+16(虚) |
| CJointNationalFocus | 0X2739DA0@+0 | CNationalFocus ← CPersistentWithToken ← CPersistent ← CProfiledScopeObject@+16(虚) |
| CContinuousNationalFocus | 0X27E6850@+0 | CPersistent |
| CNationalFocusTree | 0X2739BB8@+0 | CPersistent |
| CNationalFocusProgress | 0X2739D50@+0 | CPersistent |
| CTechnology | 0X2974EE0@+0 | CPersistentWithToken ← CPersistent ← $0A::…(模板trait)@+24 ← CTechnologyListener@+16 ← $0A::…(模板trait)@+16 ← NImpl::CEmptyClass@+24 |
| CIdeology | 0X293C6D0@+0 | CPersistentWithToken ← CPersistent ← CCountrySpecificNamedItem@+16 ← …::…(模板trait)@+56 |
| CIdeologyGroup | 0X293C680@+0 | CPersistentWithToken ← CPersistent ← …::…(模板trait)@+16 |
| CAutonomousState | 0X27E3770@+0 | CPersistent |
| CCurrentAutonomyStatus | 0X27E3870@+0 | CPersistent |
| CAIAttitude | 0X27E02A8@+0 | CPersistent |
| CAIResearchNeed | 0X27E1D70@+0 | (宿主类内嵌条目; §4.34.6) |
| CDiplomacyStatus | 0X2961CE8@+0 | CPersistent |
| CPoliticalStatus | 0X294FDA8@+0 | CPersistent |
| CAICore | 0X2AF8160@+0 | 根基类 (update 槽族 + 模块容器 @+32; §4.34) |
| CAIModule | 0X2AF82B8@+0 | 根基类 (部长公共基, 槽 [13] Hourly; §4.34) |
| CAIBaseGeneral | 0X2A1F158@+0 | CAIModule (§4.34.8) |
| CAIGeneral | 0X29880E0@+0 | CAIBaseGeneral (§4.34.8) |
| CAIVolunteerGeneral | 0X2A32080@+0 | CAIBaseGeneral (§4.34.8) |
| CCountryAI | 0X2736CA0@+0 / 0X2736D30@+104 | CAICore ← CAIStrategyStore@+104 |
| CStrategicAI | 0X27E1FB8@+0 / 0X27E2048@+104 / 0X27E2088@+2800 | CAICore ← CAIStrategyStore@+104 ← CPersistent@+2800 |
| CNameGroupTracker | 0X2935BB8@+0 | CPersistent |
| CFlagManager | 0X295D3D8@+0 | CPersistent |
| CReinforcementStatus | 0X29D1E48@+0 / 0X29D1E80@+24 | CEquipmentDistributable ← CPersistent@+24 |
| CArmyUpgradesStatus | 0X29D1FF8@+0 / 0X29D2030@+24 | CEquipmentDistributable ← CPersistent@+24 |
| CLogisticsStatus | 0X29B3B88@+0 | CPersistent |
| CLoopHistory | 0X29D2A48@+0 | CPersistent |
| CCountryOccupationStatus | 0X2984978@+0 / 0X29849B0@+24 | CGarrisonStatus ← CEquipmentDistributable ← CPersistent@+24 |
| CCountryExperienceStatus | 0X29A80C0@+0 | CPersistent |
| CBuildingStatus | 0X2999050@+0 | CPersistent |
| CCustomizableBuildingCollection | 0X27E7418@+0 | CPersistent ← CProvinceListener@+8(虚) ← $0A::…(模板trait)@+8(虚) ← NImpl::CEmptyClass@+16(虚) |
| CState | 0X2936CC0@+0 / 0X2936D10@+8 | …Template::…(模板trait)@+24 ← CPersistent ← CSelectable@+8 ← $0A::…(模板trait)@+96 |
| CProvince | 0X2971B18@+0 / 0X2971B68@+8 | CPersistent ← CSelectable@+8 ← $0A::…(模板trait)@+24 |
| CStrategicRegion | 0X296D558@+0 / 0X296D5A8@+8 | …Template::…(模板trait)@+24 ← CPersistent ← CSelectable@+8 |
| CCharacter | 0X297EA60@+0 | CReferenceObject ← CPersistent |
| CEvent | 0X2999BE8@+0 | CReferenceObject ← CPersistent ← …::…(模板trait)@+32 ← CProfiledScopeObject@+24(虚) |
| CEventScope | 0X27D43E8@+0 | CPersistent |
| CSavedEventTarget | 0X2721270@+0 | CPersistent |
| CAirWing | 0X297ADA8@+0 / 0X297ADE0@+16 | CSelectable ← CReferenceObject@+16 ← CPersistent@+16 |
| CAirWingPool | 0X297AE38@+0 | CReferenceObject ← CPersistent |
| CStrategicAir | 0X29587D8@+0 / 0X2958828@+8 | CPersistent ← CBuildingListener@+8 ← $00::…(模板trait)@+8 ← NImpl::…(模板trait)@+8 |
| CPeaceConferenceManager | 0X2720E48@+0 | CPersistent |
| CCombatTactic | 0X27E6528@+0 | CPersistent |
| CNullCombatTactic | 0X27E6588@+0 | CCombatTactic ← CPersistent |
| CSubUnitDefinition | 0X2789E08@+0 | …::…(模板trait)@+16 ← CCountrySpecificNamedItem@+24 ← CPersistentWithToken ← CPersistent |
| CUnitMedal | 0X29C17C8@+0 | CPersistentWithToken ← CPersistent ← …::…(模板trait)@+16 |
| CUnitMedalStore | 0X29C1818@+0 | CPersistent |
| CAdvisorTemplate | 0X29BBA98@+0 | CPersistent ← …::…(模板trait)@+8 |
| CCountryLeader | 0X2981350@+0 | CPersistent |
| CCountryLeaderTemplate | 0X29BCBC8@+0 | CPersistent ← VCCountryLeaderTemplate::…(模板trait)@+8 |
| CBuilding | 0X298A7B8@+0 | CPersistentWithToken ← CPersistent |
| CEquipmentVariant | 0X2951608@+0 | CReferenceObject ← CPersistent |
| CModifier | 0X27185F0@+0 | W4ModifierCategory::…(模板trait)@+16 ← CPersistentWithToken ← CPersistent |
| CCountryIntelNetwork | 0X29A1A58@+0 | CPersistent |
| CSubIntelNetwork | 0X29A1AA8@+0 | CPersistent |
| CStrategicOperative | 0X29A2358@+0 | CPersistent |

### 3.10 容器枚举原语 (唯一实现)

四族容器的遍历收敛为同一组原语, 住 `hoi4_layout.lua` 并挂 `GAME.layout`
(容器布局属 structure knowledge, 故**不进 DLL** — 游戏更新只改本层 Lua)。
各族返回同形 `(迭代器, 计数)`, 迭代器 yield `(序号, 元素地址)`; 容器不可用时
返回**空迭代器而非 nil**, 故 `for ... in` 可直接消费。

| 原语 | 目标容器 | 返回 | 迭代器 yield |
|---|---|---|---|
| `M.vec(base, doff, stride, opts)` | std::vector (§3.1) | 迭代器, 计数 | 序号, 元素地址 (或解引用值) |
| `M.rh(ht, stride, opts)` | robin-hood (§3.2) | 迭代器, 桶数 | 序号, 占位桶地址 |
| `M.rb(head, opts)` | std::map 红黑树 (§3.3) | 迭代器, nil | 序号, 节点地址 |
| `M.list(head, opts)` | 侵入式单链表 | 迭代器, nil | 序号, 节点地址 |

容器描述符表 `M.cont` (偏移一律引此, 禁散写):

| 描述符 | 字段 | 值 | 语义 |
|---|---|---|---|
| vec | delta | 12 | count 相对 data 位移 (主流形态, §3.1) |
| vec_alt | delta | 8 | count 相对 data 位移 (变体形态, §3.1) |
| rh | data | 8 | 元素数组指针 |
| rh | mask | 20 | 桶数减一 (uint32) |
| rh | extra | 24 | 尾部溢出桶字节 (uint8) |
| rh | count | 16 | 条目计数 (mask 缺失时兜底) |
| rh | dist | 4 | 桶内 dist 低字节非零 = 占用 |
| rb | root | 0 | 根指针 (树对象首字段) |
| rb | left | 0 | 左子 (节点内) |
| rb | parent | 8 | 父 (节点内) |
| rb | right | 16 | 右子 (节点内) |
| rb | isnil | 25 | 哨兵字节 (非零 = 头/哨兵节点) |
| list | next | 0 | next 指针 |

`opts` 通用项: `shape` (描述符名, 默认各族正形) / `max` (计数上界) /
`vt` (vtable RVA, 仅收首 qword 匹配的元素, 仅 vec) / `deref` (元素为指针
数组时解引用, 仅 vec) / `count` (计数偏移绝对值, 仅 vec, 省略按 delta 推)。

配套: `M.gather(iter)` 收集为数组 (空迭代器得空表); `M.rev_index(gen, build)`
建带代际戳的反查表。

| 反查 | 键 → 值 | 代际戳组成 |
|---|---|---|
| `M.state_index_map(g)` | 州指针 → state_id | 州表数据指针 + 州表计数 |

> 反查表的代际戳**必须同时含容器数据指针与计数**: 只盯计数会在"容器搬家但
> 计数未变"时留下悬垂旧指针的错映射 (token 表实测过一次真实搬家, 旧缓冲已释放)。
> 反查实例须住**文件级**: 放函数内则每次调用重建闭包, 缓存永不命中。
> 容器元素指针上界用 `M.lim.PTR_ELEM` (比通用 `M.const.PTR_HI` 紧一个量级),
> 更早剔除垃圾指针。

### 3.11 线程与并发模型

> 引擎并发总模型 = **主线程独占全部 gameplay 数据 + 双自建任务池承接发后不管作业 +
> tbb 算法层做阻塞 join 相位 + 零共享读锁**。线程纪律的显式载体 = debug 断言族
> (ThreadIsMainThread / _ThreadForbidCount / gs 访问计数 / CRandom 禁区), release 版全部
> 剔除 (纯纪律)。tick 相位与并行波的分布见 §4.2; 采样器线程表见 §4.9。

#### 3.11.1 线程清单

| 线程 | 数量 | 入口/创建 | 职责 |
|---|---|---|---|
| 主线程 | 1 | WinMain_0 (0x1425896A0) → main (0x140126E50) → CApplication::Run (0x14222E7E0, **SetThreadAffinityMask 钉单核**) → 帧顶 sub_14222EEB0 | 消息泵 (SDL_PumpEvents 每帧)/帧循环/idler/命令泵/tick 调度/渲染发起/暂停位判定 |
| PDX 池 worker (Short Task) | CPU数−1 | ctor sub_1424D4F40 (std::thread) → 循环 sub_1424D5490; 池对象 0x1435E3CD0 系 | 帧内短作业、AI 策略波、session 保活杂活 (发后不管) |
| PDX 池 worker (Long Task) | CPU数−1 | 同上; 池对象 0x1435E3DA0 系 | 异步文件 IO (sub_142266590 作业)、应用级长作业 |
| 音频线程 | 1 | std::thread @0x1423BA280 → 体 0x1423B9EC0 | 混音循环 (SRW mgr+2384, SDL_Delay 10ms 步进) |
| SDL 子系统线程 | 5 类 | SDLTimer 0x1421093C0 / SDL_joystick 0x14212D690 / HIDAPI Rumble 0x142163FD0 / SDLAudioP·C (1/设备) / SDLXInputDev haptic (1/设备) | SDL 内部 |
| tbb worker | 未决 | **生成点静态不可达** (CreateThread/_beginthreadex/rml 符号全量反查零命中) | tbb parallel_for/invoke 执行者 (运行期存在 = 采样器实证) |
| PHYSFS cdrom 探测 | 0–1 | 0x1425143C0 懒建 | 一次性 |

> 引擎自身零直调 CreateThread —— 生成通道穷举尽 = CRT std::thread 启动桩
> sub_142507E90 (唯一 beginthreadex 调用) × 2 处 (双池 + 音频) + SDL spawn 助手 7 调用点
> + PHYSFS 懒建 1; Windows 线程池/fiber/NtCreateThread 全零命中。

#### 3.11.2 双并行体系

| 维度 | tbb 算法层 | PDX 任务池 |
|---|---|---|
| 承载 | parallel_for / parallel_invoke / parallel algorithms (oneAPI DPL 后端) | 自建 std::thread worker × 2 池 |
| 派发点 | 全语料 380 个派发函数 (全量计数) | Short 提交口 0x1424D4E90 / 0x1424D4DD0; Long 0x1424D4D10 |
| 粒度控制 | EJobType 0→N 块 / 1→3N / 2→1 / 3→串行 (sub_1401DB390) | 任务对象 +8 引沉计数 / +88 状态 (1=running, 2=done) / +96 CV |
| join 语义 | 主线程阻塞等齐, **主线程亲自执行分到的份额** (spawn_root_and_wait) | 发后不管 (fire-and-forget) |
| 线程数来源 | 未决 (worker 生成点静态不可达) | dword_1435E3D98 = CPU数−1 (pdx_task.cpp:397 断言 NumTaskThreads > 0) |
| 典型用户 | hourly/daily/supply/天气等相位波 (§4.2); 存读档双轨 (§3.11.4) | AI 策略波 (hourly 相位 14)、Idle 短作业、异步 IO (Long) |

> **边界裁定**: 带 join 的数据并行 (整段等齐) 走 tbb; 发后不管的作业走 PDX 池。
> 两体系无静态互通证据 (tbb 不感知池线程; 池线程是否入 arena 未决, `/profile/threads`
> 抓相位 tid 分布可裁)。worker 主循环 = AcquireSRWLockExclusive(池+0) → 取任务 →
> 执行 → 状态置位 → CV 唤醒; 队列空则 CV 等待至停止旗。池创建 = sub_1424D53C0
> (main 内, 断言 `"NumTaskThreads > 0"`)。

#### 3.11.3 同步原语与 gs 保护

| 判据 | 定案 |
|---|---|
| 锁形态 | SRW 独占 88 处 / **共享读锁 0 处** (并发读从不加锁 = 结构事实); CS 主体属 CRT; 内核等待体 0 |
| 引擎侧锁 | 池锁 (每池一把 SRW, 极短临界区) / 音频设备表锁 (mgr+2384) / 地图缓冲层重算 (0x141599270) 等零星 |
| gs 保护 = 非锁 | debug 断言三件: ① gs 访问计数 dword_14332F268 (`Count <= 2` 夹持, gamestate.h:1140/1146); ② **_ThreadForbidCount** (thread_local, TLS+16; 访问器断言 `== 0`, 串 "Current thread is forbidden to access gamestate", 全语料 12699 处; **写者未决**); ③ CRandom 禁区 (串 "Calling random inside forbidden area! … OUT OF SYNC!") |
| 并行写隔离 | tbb 相位写「计算缓冲」(supply calcdata / EWMA 块等, §4.2 各相位已载), 安全前提 = 相位间 join + 相位内分区不交叠; MapReduce 走 SLockFreeReducer |
| 主线程断言 | 帧顶 sub_14222EEB0 `ThreadIsMainThread()` (random.h:74) |

#### 3.11.4 相位 × 执行线程总表 (稳态)

| 粒度 | 内容 | 执行线程 | 并行机制 |
|---|---|---|---|
| 每帧 | 消息泵/idler/命令泵/资产泵/渲染槽 [28]/[29]/GUI | 主线程独占 | 无 |
| 每帧 | Idle 内短作业供给 (0x140B58470 链 → Short 提交口) | Short 池 | 池任务 (主线程不等) |
| hourly 13 相位 | §4.2 相位 0–12: 串行相位主线程; join A–F 阻塞波 | 主线程 + tbb worker | tbb parallel_for |
| hourly 相位 4 | DoTradeRoutesUpdate | 同上 | tbb (PdxParallelCombine) |
| hourly 相位 14 | ai_update 收集的 AI 策略波 | **Short 池** | 池任务 |
| hourly 尾 | supply UpdateSupply 15 相位 (§4.2.6) | 主线程 + tbb worker | tbb |
| daily | 州并行/国家 daily/post_daily (每国 SRW 锁)/学说/空军/海军 (§4.2) | 主线程 + tbb worker | tbb |
| 存/读档 | **parallel_invoke: CSessionUpdateThreaded ∥ CGameStateSave/LoadThreaded** (读 0x1401E2AC0 / 存 0x1401ECC50) | 主线程 + tbb worker | tbb, 2 子任务 |
| 异步 IO | 文件加载作业 (任务名 "Long Task" + 文件名串) | Long 池 | 池任务 |
| 音频混合 | 设备表遍历+混音 | 音频线程 | 自有 SRW + 10ms 步进 |

> 存读档双轨 = **会话保活 (网络/命令泵) 与 savegame 主体并行** —— 「战役内读档不回
> 主菜单」的引擎侧承载 (§4.28 会话机制)。加载旗: 读档前置 `_InterlockedExchange`
> 置 dword_14332F284 = 0。线程集合两态不变, 差异只在 tbb 相位种类。

#### 3.11.5 外部读内存安全窗判据

| 窗口 | 安全性 | 依据 |
|---|---|---|
| 暂停态, 读 gs 主体 | 基本安全 (例外见下行) | 暂停 = 不生成 CHourlyTickCommand (§4.2.1); tbb 相位不启动; 帧循环只跑 GUI/渲染/命令泵 |
| 暂停态, 每帧仍被写的地址 | **一律不安全** | ① idler 自身域 (帧 EMA/倒计数/框选态); ② GUI·地图每帧缓存 (暂停态 RH 表仍 rehash 迁移, 州→index 反查表实证); ③ 音频管理器域 (10ms 步进); ④ 池/任务对象内部 (worker 仍弹任务); ⑤ SDL 线程域 |
| 暂停态, tbb 相位计算缓冲 | 暂停态安全; 运行态不可靠 | 只有相位在跑才写; 脏旗/缓存重建可被帧内 GUI 触发 |
| 运行态, 读 gs 主体 | **不安全** | hourly 并行波 + supply 15 相位 + daily 并行族随时在写; 无读锁 → 撕裂无防护 |
| 任何态, 读池 worker 持有的任务对象 | 不安全 | 引用计数 + 状态位双写 |

> **一句话判据**: 外部读安全 = 暂停 + 目标地址不在每帧写者清单 (idler/GUI/音频/池/SDL
> 域) + 不在 tbb 计算缓冲期。运行态与并行相位内的写无任何锁保护。

## 4. 类参考条目

> **§4 类参考条目已拆分至 `book/` 子目录**:
> 每节一个文件, 行号独立; 规范同书 §0.4; 全文检索用 `grep -r "模式" book/`;
> 表格校验 `python tools/md_table_check.py book/<file>.md` (整目录 `--dir`)。

| 节 | 文件 | 内容 |
|---|---|---|
| 4.00 | `book/s4_00_bases.md` | 4.00 基类契约层 (接口虚表 / 槽位语义) |
| 4.1 | `book/s4_01_CGameState.md` | 4.1 CGameState (游戏状态单例; 含会话元数据簇 top_meta — 同一对象, 合并于 §4.1.2/§4.1.6–§4.1.16) |
| 4.2 | `book/s4_02_gametick.md` | 4.2 游戏时序 (时间推进驱动链 / 每小时 tick 调度顺序 / 日期边界与 profiler 采样) |
| 4.3 | `book/s4_03_CCountry.md` | 4.3 CCountry (国家) |
| 4.4 | `book/s4_04_characters.md` | 4.4 CCharacterManager / CCharacter / CUnitLeader 派生族 (角色族) |
| 4.5 | `book/s4_05_faction.md` | 4.5 CFactionSystem (阵营) |
| 4.6 | `book/s4_06_doctrines.md` | 4.6 NDoctrines (学说族) |
| 4.7 | `book/s4_07_technology.md` | 4.7 CTechnologyStatus (科技) |
| 4.8 | `book/s4_08_production.md` | 4.8 CProductionStatus (生产) |
| 4.9 | `book/s4_09_profiling.md` | 4.9 性能分析域 (日期采样器 / zone profiler / 工具入口) |
| 4.10 | `book/s4_10_politics.md` | 4.10 CDiplomacyStatus / CPolitics / 自治 / 投降流亡借调族 |
| 4.11 | `book/s4_11_intelnet.md` | 4.11 情报—间谍系统 (谍报网 CCountryIntelNetwork / 特工与特务专项 COperativeLeader / 情报机构 CIntelligenceAgency / operation 块与行动令牌 / 情报账本与来源池 / 密码学; 含原 4.29) |
| 4.12 | `book/s4_12_events.md` | 4.12 事件与决议域 (CEventOption / CDecisionStatus 与冷却 / 定时·定向决策 / 定时活动与定时条目) |
| 4.13 | `book/s4_13_CState.md` | 4.13 CState (州) |
| 4.14 | `book/s4_14_CProvince.md` | 4.14 CProvince (省) |
| 4.15 | `book/s4_15_air.md` | 4.15 战略空军族 (CStrategicAirManager → CStrategicAir → CAirWingPool → CAirWing) |
| 4.16 | `book/s4_16_navy.md` | 4.16 海军族 (CStrategicNavyManager → CStrategicNavy → 基地/特混舰队/舰船 + 战史与战果记录) |
| 4.17 | `book/s4_17_notification.md` | 4.17 通知与警报系统族 (NNotification 六类 / handler 单例 / 派发三层 / 通用消息泵; **CAlertManager 警报系统 §4.17.7**; 容器行件 CNotificationContainer 布局归 §4.31.92) |
| 4.18 | `book/s4_18_army.md` | 4.18 陆军师族 (CArmy / CDivisionTemplate / requests / 部署 CDeployment 与 conveyor 三层; 含原 4.9) |
| 4.19 | `book/s4_19_loc_expr.md` | 4.19 本地化绑定/表达式系统族 (CContextLocalizationText `[...]` 求值 / bindable loc / CExpression / 脚本常量与命名集合) |
| 4.20 | `book/s4_20_weather.md` | 4.20 天气族 (CWeatherManager → 省天气 / 区域天气) |
| 4.21 | `book/s4_21_supply.md` | 4.21 补给系统 2 (CSupplySystem) |
| 4.22 | `book/s4_22_combat.md` | 4.22 战斗族 (CCombat / details / logmgr / history) |
| 4.23 | `book/s4_23_equipment.md` | 4.23 装备与市场 (装备定义 / 库存 / 全局市场 / 静态定义 / 属性枚举 / 升级模块) |
| 4.24 | `book/s4_24_theatre.md` | 4.24 战区族 (CTheatre / CFront / CFrontSection / CTheaterGroup / hq_deploy) |
| 4.25 | `book/s4_25_world.md` | 4.25 世界层全局对象 (CVariables / region 制海 / threat / 选择组 / 游戏规则 / 脚本地图实体) |
| 4.26 | `book/s4_26_staticres.md` | 4.26 静态资源访问层 (idb 库规格 / 访问器 API / 防御界 / 离线资产 / 验证体系) |
| 4.27 | `book/s4_27_raid.md` | 4.27 突袭族 (CRaidSystem / CCountryRaidStatus / CRaidInstance / 突袭 def 侧库与成功率族) |
| 4.28 | `book/s4_28_session.md` | 4.28 会话与身份注册块 (saved_event_target / player / mods / id 注册 / 生涯档案 / CRandom 随机流) |
| 4.29 | `book/s4_29_modload.md` | 4.29 mod 装载与虚拟文件系统 (descriptor 解析 / 启用清单 / PHYSFS 挂载 / replace_path 语义) |
| 4.30 | `book/s4_30_gui_map.md` | 4.30 GUI 主视图与地图 (面板/视图本体类布局 + 视图侧映射; 地图模式与脚本化 UI 基础设施) |
| 4.31 | `book/s4_31_gui_items.md` | 4.31 GUI 行件与条目族 (全部行件/条目/图标行类布局 + loc 映射) |
| 4.32 | `book/s4_32_effect_triggers.md` | 4.32 脚本 effect/trigger 全量逐名定案卡 |
| 4.33 | `book/s4_33_commands.md` | 4.33 命令子类 (具体 CCommand 派生: 载荷布局 + 行为槽 + 内层启动函数 + 调用方通道/分布 §4.33.19) |
| 4.34 | `book/s4_34_ai.md` | 4.34 AI 决策域 (CAICore 主干 / CCountryAI 部长分治 / tick 链 / AI 数据库族) |
