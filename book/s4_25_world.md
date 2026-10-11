

### 4.25 世界层全局对象 (CVariables / region 制海 / threat / 选择组 / 游戏规则 / 脚本地图实体)

> 顶层全局块分驻: variables/region/threat/选择组/游戏规则/脚本地图实体 = 本册; power_balance (按国家索引) → §4.3.21/§4.3.22; 海军战史 (沉船总账/运输船月账) → §4.16.13/§4.16.14;
> 会话与身份注册 → §4.28; 特务/operation → §4.11; 编制模板 → §4.18; factions → §4.5。

#### 4.25.1 CVariables (56B, variables)

CVariables = ***(gs+2432)***; 元 writer `ADEC0(0x2A4A, *(a1+2432))`; 写序 = 键字节序 (收集后排序, 非桶序)。
**通用布局 (56B: vtable@0 / random 种子对 +8/+12 / count@+32 / mask@+36 / extra +40 / max_load_factor +44=0.9 / 尾槽 +48)、RH 桶结构、条目 0x30、空表哨兵 &unk_1430851A0、扫描防御界 (M.lim.PTR_HUGE) = §4.13.2 (权威, 勿重述)**;
gs 侧宿主差异 = +48 尾槽传 `&dword_14332F2A0` (CGameState 域; 全注册表见 §4.13.2)。

#### 4.25.2 region 制海族 (CStrategicRegion / CNavalRegionDominance / CDominanceValues)

⚠ 类实名 **CStrategicRegion** (serfam:883; ctor sub_140E1F940 写
`CStrategicRegion::vftable`; 双子对象 +0 主表 / +8 CSelectable 次表 — 多继承
CPersistent ← CSelectable ∥ TGeographicalArea)。

region 块 (原版键 10827 "region"; 书环境 346 = 运行时 lexer id): gs writer
sub_1401F2E40 开块 → 数组按 id 1..count-1 发射 {id, 对象多态写}; 数组 =
***(gs+736)***, 数 = ***(gs+748)***; 宿主装载 = gs reader sub_1401E59D0 (块 10827
分支: id→`*(gs+736)[id]`→槽[3] Load wrapper)。

CStrategicRegion 条目主表 (sizeof 328 = 0x148, malloc 双证; ctor sub_140E1F940;
writer = 主 vtable 0x14296D558 槽[2] sub_140E24810;
reader = 槽[4] sub_140E23A90; 序列化面恰 2 键, 其余全部运行时字段):

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | CSelectable 子对象 | 选择类型 6 / 旗@+20 | 不序列化 | ctor sub_140BC2AA0(+8, 6) |
| +24 | TGeographicalArea 基子对象 (72B, +24..+96) | 成员省表 {CProvince* data@24, cap@32, count@36, 分配器@40 = off_143085170 空态哨兵} | 不序列化 | 重建 sub_140E23BB0 灌省并反写 prov+200; 重置 sub_140E22460 清反指; 基 ctor sub_140E1F880 / dtor sub_1409D0190 |
| +48 | CStrategicRegionTemplate* | 模板回指 (TGeographicalArea 域) | 不序列化 | Dominance 阈值取 模板+128 |
| +56 | MSVC SSO 32B | name (键 27; TGeographicalArea 域) | size≠0 | {buf@56..71, size@72, cap@80}; 空则 UI 回退 模板+32 名 |
| +88 | uint32 | 定义文件 id (= 模板+160; TGeographicalArea 域) | 不序列化 | 邻接/BFS/海军键统一以 +88 为区数字身份; +96 与之恒同 (报错串 "strategic area %s(%d)" 直证) |
| +96 | uint32 | region id (ctor a3; writer 发射用) | 不序列化 | id 1..count-1 |
| +100 | uint32 | 锚点省 id (u16 值) | 不序列化 | 模板锚 (模板+224/+228) 查 CMap+2096 省 id 纹理; 重建尾写, 越界 0 |
| +104 | CState* 向量 24B | 交集州表 (unique CState*) | 不序列化 | 元 = prov+192 州回指按州 id 去重 (gs 州计数字节数组去重) |
| +128 | 匿名结构 (NNB 形状) 向量 24B | 逐州覆盖率表 (qword, fixed×1e-5, 与 +104 平行) | 不序列化 | = 1e5 × 本区在该州省数 / 州+36 总省数; 州+36=0 → −1.0 哨兵 |
| +152 | fixed×1e-5 | 陆地省占比 (desc+210 bit0 计数/总数) | 不序列化 | 重建收尾三占比一并算; 总数 = 本次成功加入省数 |
| +160 | fixed×1e-5 | 海洋省占比 (desc+210 双 0 计数/总数) | 不序列化 | air-ai 阈值 50000=0.5 判海区消费; 海区环 BFS 门 (+160≠0) |
| +168 | fixed×1e-5 | 湖泊省占比 (desc+210 bit1 计数/总数) | 不序列化 | |
| +176 | CStrategicRegion* 向量 24B | _Neighbors 邻接区指针表 (CStrategicRegion*) | 不序列化 | 断言 strategicregion.cpp:633; 邻省经 desc+112 邻接表 → prov+200 属区去重; 访问器 sub_140E23A70 |
| +200 | 匿名结构 (96B 形状) 向量 24B | _NeighborAdjs 邻接载荷表 (96B 元, 与 +176 序对齐) | 不序列化 | 元 {旗@0, 接触数 u32@+4, 锚距² i64@+8, 边条目对容器@+16/@+64, 对侧省表@+40, 旗@+88}; 配对查询 sub_140E23570 线性搜 +176 后返 +200+96×idx |
| +224 | uint32 | Σ desc+192 (逐成员省累加; 重置清 0) | 不序列化 | desc+192 语义待裁 (已排除 = 省数: 无去重逐省累加) |
| +232 | CNavalRegionDominance* | dominance (键 10209) | 恒写块 | ctor malloc(0x80) → sub_141002AA0 |
| +240 | int32×2 | 锚点坐标对副本 {x@240, y@244} = 模板+224/228 双字拷贝 | 不序列化 | getter sub_140E23A60; 邻接距离直读模板侧, 便览副本定位 (高置信) |
| +248 | uint32 向量 24B | 海区邻接环 1 跳 (u32 区 id, 升序) | 不序列化 | BFS sub_140E21EA0 唯一写者 (计算下标 a1+24×depth+248); 海区门 = 对方 +160≠0; 读点待裁 (推定海军可达链) |
| +272 | 匿名结构 (NNB 形状) 向量 24B | 海区邻接环 2 跳 | 不序列化 | 同上 |
| +296 | 匿名结构 (NNB 形状) 向量 24B | 海区邻接环 3 跳 | 不序列化 | 同上; 三环收尾各自排序 (≤32 元插入排序, 否则折半递归) |
| +320 | uint32 | 更新相位 = +96 % (2×NAir::HOURS_DELAY_AFTER_EACH_COMBAT) | 不序列化 | ctor −1; 门 sub_140E24530 对 (gs+1128−43800000) 取模放行周期更新 |

注: 条目 vtable 0X296FC50 族属 CPowerBalance, 与 dominance 无关。
注: 省→区回写 = CProvince+200 单指针 (§4.14 +200 行) — **一省恰属一区为设计定案** (单指针形态直证); 定义文件一省多属时后建区静默覆盖前者, 无去重告警 (高置信)。

CNavalRegionDominance (dom) 主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CNavalRegionDominance | 不序列化 | |
| +8 | CNavalRegion* | region 回指 | | |
| +16 | std::map | countries | 恒写 | {head@+16, size@+24}; 节点 key = 国 idx u32@+28; 中序 = 写序; 裸 tag 空格连 |
| +40 | RH | values | ru32(dom+48)>0 | 88B 桶 {dist u8@+4, key 国 idx@+8, value obj@+16}; 桶数组 {buckets@+40, count@+48, mask@+52, extra u8@+56, lf f32@+60 = 0.9} |
| +64 | 匿名结构 (80B 形状) 向量 | 优势条目表 {data@+64, cap@+72, count@+76, alloc 哨兵@+80} — 80B 条 {国 tag@+0, 强度 qword@+32} | 不序列化 | has_naval_control 遍历源 (sub_141003F50); 探针 3 区恒空; 推定 |
| +96 | 匿名结构 (NNB 形状) 向量 24B | 容器#2 | | {data@+96, cap@+104, count@+108, alloc@+112}; 元素 **16B {CProvince\* @+0, value i64 @+8}**; 消费 = sub_141004230 逐元填 NAVAL_HEADQUARTER_PLACE_VALUE 值对 |
| +120 | fixed×1e-5 | 优势门阈值 (define 派生: = *(sub_1415A5560(*(region+48))+128); 探针 250.0 / 100.0) | 不序列化 | 推定 (阈值链定案) |
| — | — | sizeof = 128 (malloc 0x80 直证); reader = 槽[4] 0x1410060C0 (键 11593 countries / 19260 values, 与 writer 两块互证); 19260 块仅 u32@+48>0 发射 (writer 门不对称, reader 无条件接受); +88 ctor 置 0 无消费 | — | 增补定案 |

注: values 值元 = CDominanceValues; 写序 = key 升序 (λ 0X141001700 收集后排序)。

CDominanceValues 值元子表 (vtable 0x142984BF0; slot2 = 0X1419DE3F0 六值 writer; 六值恒写):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | vtable | CDominanceValues | |
| +24 | fixed×1e-5 | current | |
| +32 | fixed×1e-5 | base_target | |
| +40 | fixed×1e-5 | target | |
| +48 | fixed×1e-5 | individual_ratio | |
| +56 | fixed×1e-5 | previous | |
| +64 | fixed×1e-5 | decline_from | |

#### 4.25.3 threat (CWorldThreat / CThreatSource)

holder = **CWorldThreat\* = *(gs+1712)***; vtable 0X142974AA8; ctor 0X140F03310; 64B。
GUI: CWorldTensionPopUpWindow 双源之一 (populate sub_1418B47B0: 本 holder + 各国 dip+792)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CWorldThreat | 不序列化 | |
| +8 | uint64 | **逐国紧张度总值 Σ** | | 写点 sub_140F05160: 重算 +40 逐国表后 `*(th+8)=0` 再逐国 `+= *(*(th+16)+8*i)+16` (= Σ CThreatSource.threat) |
| +16 | 匿名结构 (NNB 形状) 向量 24B | threat 指针数组 | | {data@+16, cap@+24, count@+28, alloc@+32} |
| +40 | fixed×1e-5 值数组 | **逐国紧张度值表** | 不序列化 | 下标门 idx<count@+52, 钳 [0, 10000000]; 读器 sub_140F03E30 直取 `*(data+8×idx)` (写点 sub_140F05160 抚平后按 CThreatSource+16 累加); 非指针数组 (定案) |

元素 = CThreatSource 96B; vtable 0x1429766E8; ctor 0X140F032A0; writer 0X140F055E0。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CThreatSource | 不序列化 | |
| +8 | uint32 | tag 国 idx | idx>0 | GUI: 紧张度条目 target (CWorldTensionEntry entry+40 = 本对象指针); 排序比较器定案 |
| +12 | uint32 | target idx | | |
| +16 | fixed×1e-5 | threat | 恒写 | GUI: 紧张度条目显示值 (populate sub_1418B4360) |
| +24 | fixed×1e-5 | final_threat | 恒写 | GUI: 同 +16 |
| +32 | fixed×1e-5 | daily | 恒写 | |
| +40 | CGameDate (内嵌 24B) | date | 无门 date3 | {vtable1@+40, hours@+48, vtable2@+56}; ctor 哨兵 43808760; writer ADEC0 收 a1+56 = &vtable2 (通则 §3.7a); GUI: 条目日期 |
| +64 | MSVC SSO 32B | label | | 引号; size@+80; GUI: 条目标签 |

注: +16/+24/+32 为三个独立单值字段 (各 8B)。

**AddThreatSource (0x140F03550, threat.cpp:128, 定案)**: 值钳位 = **clamp(a3, −10000000, +10000000)** (fixed×1e-5 = ±100.0; 下界为负 = 源级允许负输入, 由 sub_1424EF6F0 定点取负 helper `*a1 = -a2` 构成 — IDA 伪装成 define 查表, 勿误读; 聚合表层 +40 仍 [0, 1e7])。CThreatSource 96B 填充: +8 = tag / +12 = target / **+16 threat = (天数 ≤ 0 ? 钳后值 : 0)** / **+24 final = 钳后值** / **+32 daily = (天数 > 0 ? 整除 钳值/天数 : 0)**; 断言 `_vFinalThreat == _vThreat || _DailyChange != 0_fixed`。holder+16 向量按 tag lower_bound 定插; 尾 = 国脏标记 sub_140D42820 + Σ 重算族 sub_140F04DB0 + qword_14332F698 vt+184 失效通知 (身份未决)。

**UpdateThreatSource (0x140F05380, threat.cpp:379, 高置信)**: holder+16 向量**倒序 (最新优先)** 扫, 匹配 = tag 等价 (sub_140BB52F0) ∧ target 等价 ∧ **`源+32 daily > 0` 严格** — **瞬时源 (天数 ≤ 0 创建, daily=0) 对 Update 不可见**; 未命中 → :379 断言仅 debug 门, 正式版静默无操作。命中后: **+24 final = clamp(新值, ±1e7)**; Δ = final − current(+16); **daily = |旧 daily| × sign(Δ); 结果 < 0 → 替换为 TENSION_DECAY_DAILY define (qword_143335EC0)** — 日变更恒不落负, 负向变化用标准衰减率兜底; +16 本体不动, 由衰减 tick (sub_140F05110/F04EE0, §4.2.6 相位 18) 向锚 +24 收敛。断言 :133 `( _DailyChange != 0 || _vThreat == _vFinalThreat ) && "Invalid ThreatSource for Update"`。

#### 4.25.4 游戏规则定义族 (CGameRule / CGameRuleOption / CGameRulesDatabase)

**CGameRule** (单条规则定义, CPersistent, 208B, vtable 0x14293B9B8 9 槽; writer 未覆写 = 定义件不进存档 writer, 运行态走 CGameRulesInstance):

| 偏移 | 类型 | 名称 | reader token | 备注 |
|---|---|---|---|---|
| +8 | uint32 | 规则名 lexer 动态 token id (解析驱动 sub_140A35CB0 现驻留 `__PAIR64__(序号, token id)`; ) | — | 解析对键名现算 |
| +12 | uint32 | 装入序号 | — | 非玩家选中态 |
| +16 | 匿名结构 (NNB 形状) 向量 24B | 选项表 | 10598 option | count@+28; 共享 CPdxHybridInlineBufferAllocator<CGameRuleOption,6> |
| +40 | int32 | 默认选项索引 | 11405 default | 重复默认项报错 (gamerules.cpp:187 源串) |
| +48 | string | 规则名 | 27 name | |
| +80 | string | required_dlc | 15200 | 空值抛 invalid dlc name |
| +112 | string | exclude_dlc | 19658 | 同上校验 |
| +144 | 向量 24B | group 串表 | 63 group | count@+156, alloc@+160 |
| +168 | string | 图标名 | 181 icon | |
| +200 | uint8 | 评估门旗 (两评估器 skip 未置位规则) | — | 定案 |
| +201 | uint8 | IsActive 旗 (SetOption sub_140A38860 断言 `pRule->IsActive()`, gamerules.cpp:417) | — | 定案 (原「旗 2 待裁」收口) |

**CGameRuleOption** (单选项, CPersistent, 160B, vtable 0x14293BA08; reader 0x140A37B40):

| 偏移 | 类型 | 名称 | reader token |
|---|---|---|---|
| +8 | uint32 | 选项名 lexer 动态 token id | 27 name |
| +16 | string | text | 143 |
| +48 | string | desc | 10644 |
| +80 | uint32 | allow_achievements | 15201 |
| +88 | string | required_dlc | 15200 |
| +120 | string | exclude_dlc | 19658 |
| +152 | uint8 | 旗 | — (待裁) |

**CGameRulesDatabase** (规则库单例 **qword_14332EF20**, TGameItemDatabase 谱系, 112B, vtable 0x14293BAD8 5 槽):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | 匿名结构 (24B 形状) | idb 基类容器 | §4.26 骨架位 |
| +40 | 向量 24B | 规则定义表 | cap@+48 / count@+52; 扩容 ×1.5 |
| +64 | 24B 向量 | 空 | 待裁 |
| +88 | 24B 向量 | 空 | 待裁 |

> 解析驱动 sub_140A35CB0: 逐规则栈上构造 CGameRule (键哈希+序号) → 共享 Load
> wrapper 0x1424BE690 → vtable[4] reader (CGameRule 0x140A37680) → append +40
#### 4.25.4a CGameRulesInstance (游戏规则运行态实例, gs+1088)

56B (0x38) RTTI 独立类; vtable 0x14293BA58 六实槽 ([2] writer sub_140A39830 /
[3] Load wrapper 0x1424BE690 / [4] reader ReadMember sub_140A37DC0,
gamerules.cpp:545 断言自证类名); gs+1088 形态 = pdx scoped_ptr 裸指针
(三处 pdx_scopedptr.h 断言 + 两条 gs 重置路径 malloc(0x38))。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 匿名结构 (8B 形状) 向量 24B | **唯一序列化成员**: 规则选中表, 元素 8B = {规则名 token id, 选中选项名 token id}; 同规则 upsert 至多一条; 只记非默认选中 (ReadMember 对默认项且无既存条目不入账) | 元素 8B token 对 — 原 s4_01「token 对向量」证实 |
| +32..+48 | 派生旗区 | scorched_earth / paratroopers / wargoals 三态 / volunteers 三态 / lend_lease / peace_score 三项 / maximum_fort_level 等 — 由 sub_140A38C70 按选中选项名串重算, 不进存档 | 运行期派生 |

存档块协议: 键 15202 `game_rules`; CGameState::Save 经 sub_1424C2E20 委托实例
槽[1]→[2]; 载入 = gs reader case 15202 重置后经蹦床走槽[3]→[4]; **键与值皆以名串
落盘** (token id 会话本地, 对拍必须按名匹配); 取值经 sub_140A36C50 回落规则默认项
(rule+40)。规则库单例 = qword_14332EF20 (实例不持指针, 纯 id 二分关联)。
构造 = sub_140A34D20 (世界重置步 4, §4.28.18 内 49.2 步 13 步分解表; 默认值 +32 word = 257 / +36 = −1 / +44 = 1); 初始化/重灌 = **sub_140A355F0**
(把选项 id 数组从临时表重灌 ×1.5 扩容并重建查找表; 不触 +8 选中表)。

> 向量; 选项流读 sub_1424C0AA0。


#### 4.25.5 脚本地图实体与环境物族 (CScriptedMapEntityManager / CAmbientObject / CAmbientObjectType; 均可序列化)

**CScriptedMapEntityManager** (存档内脚本地图实体注册表, 40B; vtable 0x1427216F0; writer 0x140E97CD0 / reader 0x140E97440): +8 u32 下一实体 id (键 11 `id`) / +16 注册表 {d@16, c@28}, 16B 元 {u32 id@0, CScriptedMapEntity* @8}; 块 438 `entity` 逐元素序列化条目 (条目类 CScriptedMapEntity, vtable 0x142973108, writer 0x140E97C00 / reader 0x140E971B0 皆真)。

**CScriptedMapEntity** (152B; ctor sub_140E967E0): +0 vtable / +8 u32 实体 id (=注册表 key) / +16..+40 MSVC 串 32B 实体名 (token 27 `name`, 恒写) / +48/+56/+64 i64×1e-5 x/y/z (token 32/33/421, 恒写) / +72 i64×1e-5 min_zoom (token 15083, 恒写; ctor 默认 = defines f32 dword_14333479C×1e5) / +80 f32 渲染高度 = z/1e5+地形高程 (运行时派生不序列化) / +88 i64×1e-5 scale (token 93, 恒写; ctor 默认 100000) / +96 i64×1e-5 rotation (token 342, 恒写) / +104..+128 MSVC 串 32B 动画名 (token 64 `animation`, size@+120≠0 才写) / +136 CAndTrigger* visible 脚本触发器反指 (token 11562, 指针非空才写, 发触发器对象 +96 名串) / +144..+152 填充。发射序 = name→x→y→z→scale→rotation→min_zoom→[animation]→[visible]; 数值 i64×1e-5 十进制定点尾零修剪。唯一写入方 = CCreateEntityEffect::Execute (sub_140350C40, create_entity effect 族); 显式 id 经参数槽 fixed×1e-5 求值截 u32 (脚本字面量 `id = 21985` 实得 2198500000); 载入侧条目 key 文本经 int32 饱和 (>INT32_MAX → 2147483647, 存档往返伪影)。

**CAmbientObject** (环境装饰物实例, 96B; vtable 0x1429E7368 + 次表 0x1429E73B8 (mdisp 8 = CSelectable); writer 0x141646F30 / reader 0x141646930): +24 name (27) / **+56..+68 position vec3 f32** (内存态 float; 序列化块 76 = i32×1e-5 定点 — writer 读 float 转 i32×1e-5, reader 除 1e5 存 float; writer/reader/图形视图 ctor sub_1416462E0 三读一致, 高置信; 与 CScriptedMapEntity 的 i64 定点内存态不同) / **+68..+80 rotation vec3 f32** (块 342, 同定点转换) / +80 CAmbientObjectType* 反指。**渲染视图对象** (32B 无名 POD, 渲染管理器视图数组 @宿主+1272 {data@1272, cap/count@1276}; 门 = sub_141646910(elem) ∧ elem+89 运行期字节; ctor sub_1416462E0): +0 sim 对象反指 / +8 qword 图形句柄 (sub_14228CD30(entity, 7, 6, 0), 首参 = 类型/模型 def 对象 (d4064 第 4 例跨域同构收窄), 尾参 (7, 6, 0) 语义仍待裁) / +16 u16 常量 256 (语义未决) / +20 u32 类型 time_duration (读 type+80) / +24 u32=0; 类型名查表 type+8 串 → sub_142291330/sub_142293530 取图形实体; 非 always_visible (type+124) 时 position.y += 全局设置对象 qword_143339D28 返回的 f32 偏移; type+72 use_animation 非 0 且缺 "idle" 动画 → graphics/ambientobject.cpp:340 (旗 65540) "<name> is animated but have no idle animation!" (名取 sim+24)。

**CAmbientObjectType** (环境物类型定义 + 实例容器; vtable 0x1429E7318; writer 0x141647160 / reader 0x141646A70): +8 type 名 (225) / +40 animation (64, 默认 "idle") / +72 use_animation (366) / +76 scale (93, 默认 1.0) / +80 time_duration (10925, >0 写) / +88 sound_effect (11419) / +120 max_visible (10926, 默认 -1) / +124 always_visible (11600: 0=16 格空间网格存储 @+152 / 1=平面数组存储 @+160) / +136 CAndTrigger* dlc_allowed (17943); type 侧以键 65 `object` 逐条创建 CAmbientObject 并按位置塞格。

#### 4.25.6 选择组 (selection_groups; gs+1624)

> 宿主口径定案 = **运行时每国一组** (活体探针: gs+1636 计数 = 440 == countryCount(), 单机档
> 按「按玩家」应为 1 组; cap@1632 = 474 为容量余量)。本节「按玩家 ×10 组」的"玩家块 stride 240B"
> 表述转为**存档侧**口径 — 落盘仅玩家块 (20 档无 selection_groups 叶, 存档形未对拍), 与运行时
> 每国一组在「运行时 vs 落盘」两维并存。

| 项 | 值 | 语义 |
|---|---|---|
| 容器 | gs+1624 | 每国一组 {data@1624, cap@1632, count@1636, alloc@1640}; 组 stride 240B (= 10 槽 × 24B) |
| 组块 | stride 240B (= 10 × 24B) | 运行时块数 = 国家库条数 (活体 440); writer 侧取数 `(*gs_vt+72)(gs)` 待与 0X1401F2BE0 复核 |
| 槽 | 24B {units_data@0, cap@8, count@12, alloc@16} | 空槽判 count>0 |
| 槽元素 | SControlGroupData 32B | 布局见下表 |
| 创建命令 | 0X140DC5730 逐类型分支 (RTTI 直证); 拷贝器 0X1401E3DC0 | — |
| writer | CSelectionGroupWriter 0X1401F2BE0 (vtable 0X27211D0) | — |
| reader | 0X1401E9820 = **CSelectionGroupReader** (RTTI 实名, vtable 0x142721220) | — |

SControlGroupData (32B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | — | vtable |
| +8 | — | CSelectable id 对 |
| +16 | uint32 | 键 10304 province / 键 11925 naval — 三独立键位之一 (创建命令按当前地图模式==2 把同一省 id 分流落 +16 或 +20) |
| +20 | uint32 | 键 11926 air (地图模式分流落点, 同上) |
| +24 | uint32 | state id (type-6 CState 条目 +88; 恒走自己键) |

存档形 (键 selection_groups, 10286; 每玩家一块):

| 项 | 值 | 语义 |
|---|---|---|
| owner | tag (键 10754) | 取自 gs+784 玩家国家指针数组 元素+8 |
| 组键 | 十进制槽位序号串 "0".."9" (itoa) | ⚠ 20 档无 selection_groups 叶, 无对拍样本; reader atoi 对称性高置信 |
| 组内 | SControlGroupData 数组 | — |
| 写门 | 该玩家 10 组中存在非空组 | — |

#### 4.25.7 地图生成器省定义装载 (mapgenerator.cpp; 2 函闭环)

簇清册 (体内 cpp 锚 2/2; 书内原空白带, 全部本批新定性):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141543070 | 611 | mapgenerator.cpp :192 | 省定义文本解析 (分号 8 列 → 40B 记录向量) |
| sub_141544CF0 | 93 | 同 CU :526 | 省定义文件装载驱动 (读全文件 → 解析 → 栅格构建) |

**省定义解析** (sub_141543070; (this, 全文 std::string*, out 省定义向量*) — this 形参未消费; out = CMapGenerator+0): 按 '
' 切行 → 每行按 CR 再按 ';' 切字段 (内联 8 字段缓冲 + locale 守卫)。列语义 (0 基):

| 列 | 消费 | 记录字段 |
|---|---|---|
| 0 | strtol | +0 u16 省 id |
| 1/2/3 | strtol | +2/+3/+4 u8 R/G/B |
| 4 | 串匹配 | +5 u8 类型位旗: land = 2 / sea = 4 / lake = 8 / 其余 = 1 |
| 5 | "true" 比对 | +7 bool |
| 6 | 串拷贝 | +8 std::string 名 (缺省 "unknown") |
| 7 | strtol | +6 u8 (语义待裁) |

记录 40B (向量 {data, cap+8, count+12, 分配器+16}, 1.5 倍增长) = 头 8B + 32B 名串。字段数 <3 → 整行跳过 + :192 断言 (B51 门, 闩 byte_14338A8A9) "CMapGenerator - Insufficient province variables on line: <行>"; 3..7 列 → 缺省回填且**返回值置 1** (语义 = 「本文件出现过缺列回填」, 高置信)。fallback 路径直接 malloc 40 逐格填 (pdx_scopedptr.h 断言站, B52 门)。

**装载驱动** (sub_141544CF0; (gen, arg2, 路径*, outFlag byte*)): 打开文件 → 尺寸 ≤ 0 → :526 "Error reading <路径> the file seems empty" (CLogStream) → 读全文件 → 解析返 1 则 *outFlag = 1 → sub_1415446A0(gen, arg2, 1) 颜色→省 id 栅格构建返 1 亦置旗。总驱动 = sub_141543C00 (两路径两次调用本函; 邻接阶段 sub_1415449A0/sub_141542F30/sub_141545C50 待裁)。

**CMapGenerator 布局实证段**: +0 省定义向量 (40B/条) / +24 颜色栅格向量 (u16/像素) / +48 栅格宽 / +52 栅格高。

未决: 列 7 语义 / 栅格构建 sub_1415446A0 内部与 provinces 位图来源 / 邻接阶段四函 / 总驱动全流程。

#### 4.25.8 战略区数据库装载 (strategic_region_database.cpp; 2 函闭环 — 定义块装载循环 / weatherpositions.txt 解析)

簇清册 (体内 cpp 锚 2/2; 模板类布局 §4.26 已收, 装载链本批新定):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_140AC02C0 | 175 | strategic_region_database.cpp:101 (B51, 闩 byte_14333A0E0) + null_object.h:133 (B52, 闩 byte_14333A0E1) | `strategic_region` (12014) 块装载循环 |
| sub_140AC0AB0 | 669 | :202/:208/:215/:220 (均 65540) | map/weatherpositions.txt 解析器 (模板 +200 向量唯一写者) |

**三源总装载** (sub_140A65010): ① map/strategicregions 目录 — 已载门 = 单例 +20 非 0 → "DB already loaded when loading <路径>" (gameitemdatabase.h:160, TGameItemDatabase 模板族互证); 未载 → 存路径 +8 → sub_140AC0750 枚举 *.txt 逐文件装载 → 尾随虚槽[2]/[4] 后处理; ② map/colors.txt → sub_140AC08E0 (未读); ③ map/weatherpositions.txt → sub_140AC0AB0。

**数据库单例** (getter sub_140163C30; 全局槽 **qword_14332F080**, §4.26 库表同源): {+0 主虚表 (Reload 尾调 [2]/[3]/[4] 三连装载后钩), **+8 = _Paths 24B pdx 向量头** (data@+8 = &元素[0], 读串 = _Paths[0] 别名), **+20 = _Paths 计数** ("已载" = count != 0, gameitemdatabase.h:281 断言直读域), +32 reload 深度计数, +40 项指针数组, +48 容量, +52 计数 (= max id+1), +56 分配器, +112 活体对象计数}。

**定义块装载循环** (sub_140AC02C0): 节点键 == 12014 (strategic_region) 门 → malloc 336 → **sub_1415A3DF0 = CStrategicRegionTemplate ctor** (vftable 字面量直证; +168 有效旗 = 1; **+176 = 天气周期向量** (CWeatherChancePeriod 224B 元, count@+188, 定案 §4.20.9) / +200 天气位置点集 / +240 未决 三向量 + +272 SSO 初始化) → **虚槽[3] Load wrapper 消费整块** (CPersistent 槽契约互证); id = 模板 +160, id < 1 → assert "Invalid ID, not in range > 0." 后析构; 数组挂载槽 = 数据库数组 + 8×id (容量不足 ×1.5 保底 id+1 扩, 新槽填 null 对象 qword_14333A0D8 或 0 — §4.26 null 实例登记互证); 双串拷入 +96/+128 (目录项 64B 双 32B 串, 语义推定 = 定义文件路径/文件名); 流守卫 = 内嵌解析器 +100 一次性旗 + vtable[1] 状态 == 19 终止。

**weatherpositions.txt 解析器** (sub_140AC0AB0): 文件格式 = 逐行 5 字段 `region_id;x;y;z;small` (`;` 分隔, 剥 CR); 字段数 ≠ 5 → ":208 invalid arguments count."; 空文件 → ":215 is empty."; 打开失败 → ":220 Failed to read weather positions file" (cpp 文件名与错误串同体 = 装载器语义直证)。逐行: 字段 0 = 战略区模板 id (越界回退槽 0) → 模板 +168 有效旗门 (0 → ":202 invalid region id."); 字段 1-3 strtof = x/y/z; 字段 4 == "small" = 旗。落点 = 模板 +200 向量 (16B 元, ×1.5 扩容) — **战略区的地图天气表现点集 (区内每点三维坐标 + 小型标记), 非序列化静态资源, 与 +176 定义内 weather 块 (224B 元) 是两个不同向量** (§4.26 布局行已补)。

未决: colors.txt 装载器 / 模板 +96/+128 双串语义活体验证 / missing_triggers 生产者全景 (§4.32.21)。

#### 4.25.9 战略区域模板后处理 (strategicregiontemplate.cpp; 6 函闭环 — 中心计算/温度校验/链接解析/省描述符新行)

簇清册 (体内 cpp 锚 6/6; 全部新定性; 模板布局 §4.26 + 装载链 §4.25.8 已收):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_1415A4770 | 134 | :405 断言 "IsRegionCenterSet() && Calculations where incorrect" (B52, 闩 byte_14338A945) | CalculateRegionCenter |
| sub_1415A6420 | 75 | :515 断言 (B52) | FindPositionInRegion (逐省 bbox 点测 + 细步搜索兜底) |
| sub_1415A6A10 | 268 | :559/:577/:585 (CLogStream 65540) | LateInit 链接解析 (**missing_triggers 类报错生产者之一**) |
| sub_1415A5630 | 272 | :172/:178/:191 (格式化日志 4096) | weather 温度区间连续性校验 (虚槽触发, 槽位待裁); nudger 期同算法第二实现 = §4.20.9 |
| sub_1415A68E0 | 48 | :232/:238 断言 (B51) | SetId (nudge/编辑域, 唯一调用方 sub_141B61FC0) |
| sub_1415A5480 | 44 | :537 + null_object.h:133 (B52) | GetTerrainType (+304 访问器, null 兜底 qword_14333A248) |

**调用链 (定案)**: 战略区 DB 后处理三 pass (sub_140AC05C0 → 4770 / sub_140AC16C0 → 6420 / sub_140AC1990 → 6A10; DB 单例 §4.25.8 互证)。

**Template 布局增补 (§4.26 336B 表)**: **+232 i32×2 计算中心 {x, y}** (4770 输出落点; +224/+228 静态锚点外的第三组坐标) / **+304 CTerrainType* _pTerrainType** (断言串直证; naval_terrain 名解析产物; null 兜底 = CTerrainType null 实例)。中心计算 = Σ(bbox 中心)/N 均值 → 首个含点省精化 → 双兜底 → 空省拷静态锚点。

**weather 元素 224B 内部 (定案)**: +8 = 区间起点 / +32 = 区间终点; **全年 365 天连续性校验**: 重叠 (:172) / 空档 (:178) / 不覆盖整年 (:191) 三错误全为格式化日志无中断。

**static_modifiers 元素 80B 内部 (定案)**: +0 modifier 名 / +32 trigger 名 / +64 trigger 对象 (库 qword_14332F058; 无效 → 报错 + **元素删除**) / +72 modifier 对象 (sub_14055B160 单例解析; NULL → 报错 + 删除)。特例: **trigger 名 "always" (0x61776C61 直证) 跳库直通保留**。

**省静态描述符新行** (§4.14.3 表已补): desc+88 = 战略区模板 id / desc+136..+148 = bbox {min_x, min_y, w, h}。

未决: 温度校验虚槽槽位 / Template +96/+128 双串语义 (旧未决) / 中心兜底三件内部。

#### 4.25.10 世界层全局对象函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x14043F5C0 | NCareerProfile::CCheckMedal::GetDesc：NCareerProfile::CCheckMedal::GetDesc NCareerProfile::CCheckMedal::GetDesc；断言 gameitemdatabase.h:142（func_names 直接命名，无其他自… |
| 0x140E20E00 | （未命名）strategicregion.cpp:164 strategicregion.cpp:164；"Game state needs to be initialized"，战略区域 |
| 0x140F38E60 | sub_140F38E60 gradientbordermanager.cpp:2451 "Hole in Strategic Regions DB at ID ="（战略区域数据库完整性检查） |
| 0x14019E780 | NScript::CNamedCollection::Load NScript::CNamedCollection::Load：VT CNamedCollection，STR '!_Paths.IsEmpty()'/'============================='（gameitemdatabase.… |
| 0x14043FF80 | NCareerProfile::CCheckPoints::GetDesc NCareerProfile::CCheckPoints::GetDesc：STR '_NOT'/'VALUE'（生涯档案检查点触发描述） |
| 0x140440900 | NCareerProfile::CCheckValue::GetDesc NCareerProfile::CCheckValue::GetDesc：STR '_NOT'/'VALUE'/'TOOLTIP_VALUE' |
| 0x140DB41C0 | （无名） vftable 类 CVariables::（静态资源/库装载） |

#### 4.25.11 世界层全局对象函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x141264FE0 | vtable/RTTI 类 CMapArrowDefinition sub_141264FE0 + vtable/RTTI 类 CMapArrowDefinition; 被 CMapArrowManager::LoadDefinitions? 等 1 命名函数调用 |
| 0x140E968D0 | CScriptedMapEntity::[0] CScriptedMapEntity::[0] + vtable/RTTI 类 CScriptedMapEntity; vtable/RTTI 含 CScriptedMapEntity; 被 CScriptedMapEntity::[0] 等 1 命名函数调用 |
#### 4.25.13 世界层全局对象函数补遗（81 函）

| VA | 语义/证据 |
|---|---|
| 0x141377300 | NScript::SScriptedKey::[3] vtable 槽 NScript::SScriptedKey::[3]（func_names RTTI 名） |
| 0x1406AFC60 | NCareerProfile::CRibbonDatabase::[1] vtable 槽 NCareerProfile::CRibbonDatabase::[1]（func_names RTTI 名） |
| 0x1406AB430 | NCareerProfile::CMedalDatabase::[1] vtable 槽 NCareerProfile::CMedalDatabase::[1]（func_names RTTI 名） |
| 0x1402F6790 | NLoc::SScopeLocalizer::[2] vtable 槽 NLoc::SScopeLocalizer::[2]（func_names RTTI 名） |
| 0x14175A9A0 | NDivisionDesigner::CNicheSelectionItem::[0] vtable 槽 NDivisionDesigner::CNicheSelectionItem::[0]（func_names RTTI 名） |
| 0x141F7C970 | NDesignerUI::CNicheIconListItem::[0] vtable 槽 NDesignerUI::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x141761510 | NDivisionDesigner::CNicheSelectionItem::[0] vtable 槽 NDivisionDesigner::CNicheSelectionItem::[0]（func_names RTTI 名） |
| 0x141F7CA20 | NDesignerUI::CNicheIconListItem::[0] vtable 槽 NDesignerUI::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x141FDD840 | NCareerProfile::CMedalItem::[0] vtable 槽 NCareerProfile::CMedalItem::[0]（func_names RTTI 名） |
| 0x14043E4F0 | NCareerProfile::CCheckValue::[0] vtable 槽 NCareerProfile::CCheckValue::[0]（func_names RTTI 名） |
| 0x14201E930 | NCareerProfile::CProfilePictureItem::[0] vtable 槽 NCareerProfile::CProfilePictureItem::[0]（func_names RTTI 名） |
| 0x14043E5A0 | NCareerProfile::CCheckPoints::[0] vtable 槽 NCareerProfile::CCheckPoints::[0]（func_names RTTI 名） |
| 0x14015F350 | NScript::CConstant::[0] vtable 槽 NScript::CConstant::[0]（func_names RTTI 名） |
| 0x140A6CAA0 | NInlayWindowScript::SProgressbar::[0] vtable 槽 NInlayWindowScript::SProgressbar::[0]（func_names RTTI 名） |
| 0x140160D80 | NCareerProfile::SCareerProfileStatistics::[0] vtable 槽 NCareerProfile::SCareerProfileStatistics::[0]（func_names RTTI 名） |
| 0x141EFADE0 | NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[0] func_names 名 NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[0] |
| 0x14177CBB0 | NEquipmentDesigner::CEquipmentSpriteListItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentSpriteListItem::[0]（func_names RTTI 名） |
| 0x1402CD4D0 | NScript::SScriptedKey::[0] vtable 槽 NScript::SScriptedKey::[0]（func_names RTTI 名） |
| 0x14201E8B0 | NCareerProfile::CProfileBackgroundItem::[0] vtable 槽 NCareerProfile::CProfileBackgroundItem::[0]（func_names RTTI 名） |
| 0x1406AD120 | NCareerProfile::CProfilePictureDatabase::[1] vtable 槽 NCareerProfile::CProfilePictureDatabase::[1]（func_names RTTI 名） |
| 0x141783A80 | NEquipmentDesigner::CEquipmentSpriteListItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentSpriteListItem::[0]（func_names RTTI 名） |
| 0x14177CB40 | NEquipmentDesigner::CEquipmentNameGroupItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentNameGroupItem::[0]（func_names RTTI 名） |
| 0x1407206B0 | NCountry::CMetadataDatabase::[1] vtable 槽 NCountry::CMetadataDatabase::[1]（func_names RTTI 名） |
| 0x1409CAED0 | NDLC::CMetadataDatabase::[1] vtable 槽 NDLC::CMetadataDatabase::[1]（func_names RTTI 名） |
| 0x140331C00 | NScript::NMath::CExpression::[0] vtable 槽 NScript::NMath::CExpression::[0]（func_names RTTI 名） |
| 0x141CCBC00 | NCareerProfile::CFrontendCareerProfileView::[0] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[0]（func_names RTTI 名） |
| 0x1406143E0 | NAcclimatization::CData::[0] vtable 槽 NAcclimatization::CData::[0]（func_names RTTI 名） |
| 0x141996940 | NCareerProfile::CProfileBadgeUpdateListener::[1] vtable 槽 NCareerProfile::CProfileBadgeUpdateListener::[1]（func_names RTTI 名） |
| 0x14201FBE0 | NCareerProfile::CCareerProfileSimpleDropdownItem::[0] vtable 槽 NCareerProfile::CCareerProfileSimpleDropdownItem::[0]（func_names RTTI 名） |
| 0x1401C99D0 | NCareerProfile::SPlaythroughCountryData::[0] vtable 槽 NCareerProfile::SPlaythroughCountryData::[0]（func_names RTTI 名） |
| 0x14054AAD0 | CVariables::[0] vtable 槽 CVariables::[0]（func_names RTTI 名） |
| 0x141EF67B0 | NCareerProfile::CCareerProfileViewUpdateable::[0] vtable 槽 NCareerProfile::CCareerProfileViewUpdateable::[0]（func_names RTTI 名） |
| 0x140A6C990 | NInlayWindowScript::SButton::[0] vtable 槽 NInlayWindowScript::SButton::[0]（func_names RTTI 名） |
| 0x141FDDB00 | NCareerProfile::CMedalItem::[0] vtable 槽 NCareerProfile::CMedalItem::[0]（func_names RTTI 名） |
| 0x141FDE3A0 | NCareerProfile::CRibbonItem::[0] vtable 槽 NCareerProfile::CRibbonItem::[0]（func_names RTTI 名） |
| 0x140A23370 | NLoc::SEnvironmentLocalizer::[1] vtable 槽 NLoc::SEnvironmentLocalizer::[1]（func_names RTTI 名） |
| 0x14043E4B0 | NCareerProfile::CCheckMedal::[0] vtable 槽 NCareerProfile::CCheckMedal::[0]（func_names RTTI 名） |
| 0x141FE4B70 | NCareerProfile::CCareerProfilePageDot::[0] vtable 槽 NCareerProfile::CCareerProfilePageDot::[0]（func_names RTTI 名） |
| 0x14201DC60 | NCareerProfile::CCountryItem::[0] vtable 槽 NCareerProfile::CCountryItem::[0]（func_names RTTI 名） |
| 0x141EFAE80 | NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[3] func_names 名 NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[3] |
| 0x14015FF10 | NScript::CNamedCollection::[0] vtable 槽 NScript::CNamedCollection::[0]（func_names RTTI 名） |
| 0x1402F6390 | NLoc::SScopeLocalizer::[1] vtable 槽 NLoc::SScopeLocalizer::[1]（func_names RTTI 名） |
| 0x14015F2E0 | NScript::CCollection::[0] vtable 槽 NScript::CCollection::[0]（func_names RTTI 名） |
| 0x1406AB3F0 | NCareerProfile::CCareerProfileMedal::[0] vtable 槽 NCareerProfile::CCareerProfileMedal::[0]（func_names RTTI 名） |
| 0x1401C9A20 | NCareerProfile::SProfileData::[0] vtable 槽 NCareerProfile::SProfileData::[0]（func_names RTTI 名） |
| 0x140683530 | NPdxLoc::CFormattedLocalization::[0] vtable 槽 NPdxLoc::CFormattedLocalization::[0]（func_names RTTI 名） |
| 0x14015F2A0 | NPdxLoc::CBoundLocalization::[0] vtable 槽 NPdxLoc::CBoundLocalization::[0]（func_names RTTI 名） |
| 0x140160ED0 | NCareerProfile::SGameModeStatistics::[0] vtable 槽 NCareerProfile::SGameModeStatistics::[0]（func_names RTTI 名） |
| 0x140720670 | NCountry::CMetadata::[0] vtable 槽 NCountry::CMetadata::[0]（func_names RTTI 名） |
| 0x1419C4050 | NCareerProfile::CBasePopupWindow::[0] vtable 槽 NCareerProfile::CBasePopupWindow::[0]（func_names RTTI 名） |
| 0x141C28C20 | NAirInterfaceUtil::CMissionIconItem::[0] vtable 槽 NAirInterfaceUtil::CMissionIconItem::[0]（func_names RTTI 名） |
| 0x141EF6770 | NCareerProfile::CCareerProfileView::[1] vtable 槽 NCareerProfile::CCareerProfileView::[1]（func_names RTTI 名） |
| 0x140A1EBF0 | NScript::CNamedCollection::[10] vtable 槽 NScript::CNamedCollection::[10]（func_names RTTI 名） |
| 0x14043E700 | NCareerProfile::CVariableTrigger::[0] vtable 槽 NCareerProfile::CVariableTrigger::[0]（func_names RTTI 名） |
| 0x14068F290 | NCareerProfile::SCareerProfileIntermediateStatistics::[0] vtable 槽 NCareerProfile::SCareerProfileIntermediateStatistics::[0]（func_names RTTI 名） |
| 0x14068F2D0 | NCareerProfile::SCareerProfileModDataSet::[0] vtable 槽 NCareerProfile::SCareerProfileModDataSet::[0]（func_names RTTI 名） |
| 0x1406AFC20 | NCareerProfile::CCareerProfileRibbon::[0] vtable 槽 NCareerProfile::CCareerProfileRibbon::[0]（func_names RTTI 名） |
| 0x1409CAE90 | NDLC::CMetadata::[0] vtable 槽 NDLC::CMetadata::[0]（func_names RTTI 名） |
| 0x1419C4090 | NCareerProfile::CMedalPopupWindow::[0] vtable 槽 NCareerProfile::CMedalPopupWindow::[0]（func_names RTTI 名） |
| 0x14201B0C0 | NCareerProfile::CMedalDisplaySlot::[0] vtable 槽 NCareerProfile::CMedalDisplaySlot::[0]（func_names RTTI 名） |
| 0x14054A610 | （无名） 体设 CVariables::vftable（RTTI 名） |
| 0x140160D20 | NCareerProfile::SCareerProfileAwards::[0] vtable 槽 NCareerProfile::SCareerProfileAwards::[0]（func_names RTTI 名） |
| 0x1401C99A0 | NCareerProfile::SCareerProfileCountryData::[0] vtable 槽 NCareerProfile::SCareerProfileCountryData::[0]（func_names RTTI 名） |
| 0x1406AB4F0 | NCareerProfile::CCareerProfileMedal::CTierColors::[0] vtable 槽 NCareerProfile::CCareerProfileMedal::CTierColors::[0]（func_names RTTI 名） |
| 0x1419C4014 | NCareerProfile::CBasePopupWindow::[1] vtable 槽 NCareerProfile::CBasePopupWindow::[1]（func_names RTTI 名） |
| 0x14175A874 | NDivisionDesigner::CNicheSelectionItem::[1] vtable 槽 NDivisionDesigner::CNicheSelectionItem::[1]（func_names RTTI 名） |
| 0x14177C75C | NEquipmentDesigner::CEquipmentNameGroupItem::[1] vtable 槽 NEquipmentDesigner::CEquipmentNameGroupItem::[1]（func_names RTTI 名） |
| 0x14177C768 | NEquipmentDesigner::CEquipmentSpriteListItem::[1] vtable 槽 NEquipmentDesigner::CEquipmentSpriteListItem::[1]（func_names RTTI 名） |
| 0x14177C774 | NEquipmentDesigner::CNicheIconListItem::[1] vtable 槽 NEquipmentDesigner::CNicheIconListItem::[1]（func_names RTTI 名） |
| 0x1419C4020 | NCareerProfile::CBasePopupWindow::[0] vtable 槽 NCareerProfile::CBasePopupWindow::[0]（func_names RTTI 名） |
| 0x1419C402C | NCareerProfile::CMedalPopupWindow::[1] vtable 槽 NCareerProfile::CMedalPopupWindow::[1]（func_names RTTI 名） |
| 0x141CCBBEC | NCareerProfile::CFrontendCareerProfileView::[1] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[1]（func_names RTTI 名） |
| 0x141F7C958 | NDesignerUI::CNicheIconListItem::[1] vtable 槽 NDesignerUI::CNicheIconListItem::[1]（func_names RTTI 名） |
| 0x141FDD834 | NCareerProfile::CMedalItem::[1] vtable 槽 NCareerProfile::CMedalItem::[1]（func_names RTTI 名） |
| 0x141FE4B24 | NCareerProfile::CCareerProfilePageDot::[0] vtable 槽 NCareerProfile::CCareerProfilePageDot::[0]（func_names RTTI 名） |
| 0x14201B0AC | NCareerProfile::CMedalDisplaySlot::[1] vtable 槽 NCareerProfile::CMedalDisplaySlot::[1]（func_names RTTI 名） |
| 0x141CCBC70 | NCareerProfile::CFrontendCareerProfileView::[15] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[15]（func_names RTTI 名） |
| 0x141CCBC80 | NCareerProfile::CFrontendCareerProfileView::[6] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[6]（func_names RTTI 名） |
| 0x141CCBC90 | NCareerProfile::CFrontendCareerProfileView::[5] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[5]（func_names RTTI 名） |
| 0x141CCBD30 | NCareerProfile::CFrontendCareerProfileView::[14] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[14]（func_names RTTI 名） |
| 0x141CCBE60 | NCareerProfile::CFrontendCareerProfileView::[9] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[9]（func_names RTTI 名） |
#### 4.25.15 世界层全局对象函数补遗（70 函）

| VA | 语义/证据 |
|---|---|
| 0x141629960 | NUtils::BuildRaidWarningTooltip func_names 名 NUtils::BuildRaidWarningTooltip |
| 0x140440C40 | NCareerProfile::CNumOfPointsTrigger::GetDesc func_names 名 NCareerProfile::CNumOfPointsTrigger::GetDesc |
| 0x1406A85C0 | NCareerProfile::SCareerProfileAwards::Writer func_names 名 NCareerProfile::SCareerProfileAwards::Writer |
| 0x14043FC60 | NCareerProfile::CCheckPlaythroughValue::GetDesc func_names 名 NCareerProfile::CCheckPlaythroughValue::GetDesc |
| 0x1401FEBA0 | NGameTelemetry::SendProvincesOccupiedSnapshot? func_names 名即证据（省份占领遥测快照发送） |
| 0x1412C2760 | NAIAirEvaluation::FillRegionOccupationData? func_names 名 NAIAirEvaluation::FillRegionOccupationData? |
| 0x14043EAE0 | NCareerProfile::CHasPlayerFlag::Evaluate func_names 名 NCareerProfile::CHasPlayerFlag::Evaluate |
| 0x141C32790 | NCountryStatTracking::CConstructedBuildingsTracker::[2] vtable 槽 NCountryStatTracking::CConstructedBuildingsTracker::[2]（func_names RTTI 名） |
| 0x1406AA550 | NCareerProfile::SGameModeStatistics::Writer func_names 名 NCareerProfile::SGameModeStatistics::Writer |
| 0x141DED770 | NCareerProfile::CPlaythroughOverviewWindow::Reload func_names 名 NCareerProfile::CPlaythroughOverviewWindow::Reload |
| 0x1417838A0 | NEquipmentDesigner::CEquipmentNameGroupItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentNameGroupItem::[0]（func_names RTTI 名） |
| 0x1404419A0 | NCareerProfile::CCheckMedal::ParseToken func_names 名 NCareerProfile::CCheckMedal::ParseToken |
| 0x1419C51F0 | NCareerProfile::CBasePopupWindow::[1] vtable 槽 NCareerProfile::CBasePopupWindow::[1]（func_names RTTI 名） |
| 0x140441E20 | NCareerProfile::CVariableTrigger::ParseToken func_names 名 NCareerProfile::CVariableTrigger::ParseToken |
| 0x14201B320 | NCareerProfile::CRibbonDisplaySlot::[0] vtable 槽 NCareerProfile::CRibbonDisplaySlot::[0]（func_names RTTI 名） |
| 0x14201B200 | NCareerProfile::CMedalDisplaySlot::[0] vtable 槽 NCareerProfile::CMedalDisplaySlot::[0]（func_names RTTI 名） |
| 0x1404415E0 | NCareerProfile::CCheckRibbon::ValidateLate func_names 名 NCareerProfile::CCheckRibbon::ValidateLate |
| 0x140D94270 | NPdx::Z::SSparseArrayWriter<鈥�>::[1] func_names 名 NPdx::Z::SSparseArrayWriter<鈥�>::[1] |
| 0x141DED2C0 | NCareerProfile::CPlaythroughOverviewWindow::[0] vtable 槽 NCareerProfile::CPlaythroughOverviewWindow::[0]（func_names RTTI 名） |
| 0x140BC8D70 | CVariables::Reader func_names 名 CVariables::Reader |
| 0x140441D50 | NCareerProfile::CCheckPoints::ParseToken func_names 名 NCareerProfile::CCheckPoints::ParseToken |
| 0x14177CC30 | NEquipmentDesigner::CNicheIconListItem::[0] vtable 槽 NEquipmentDesigner::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x141EF7B40 | NCareerProfile::CCareerProfileView::[2] vtable 槽 NCareerProfile::CCareerProfileView::[2]（func_names RTTI 名） |
| 0x14043E780 | NCareerProfile::CCheckPlaythroughRatio::Evaluate func_names 名 NCareerProfile::CCheckPlaythroughRatio::Evaluate |
| 0x14043E950 | NCareerProfile::CCheckRatio::Evaluate func_names 名 NCareerProfile::CCheckRatio::Evaluate |
| 0x14118F590 | NPdx::Z::SSparseArrayWriter<鈥�>::[1] func_names 名 NPdx::Z::SSparseArrayWriter<鈥�>::[1] |
| 0x141E3FCE0 | NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[0] func_names 名 NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[0] |
| 0x14043E8C0 | NCareerProfile::CCheckPoints::Evaluate func_names 名 NCareerProfile::CCheckPoints::Evaluate |
| 0x1406AA260 | NCareerProfile::SCareerProfileIntermediateStatistics::Writer func_names 名 NCareerProfile::SCareerProfileIntermediateStatistics::Writer |
| 0x141783AF0 | NEquipmentDesigner::CNicheIconListItem::[0] vtable 槽 NEquipmentDesigner::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x14043EA60 | NCareerProfile::CCheckValue::Evaluate func_names 名 NCareerProfile::CCheckValue::Evaluate |
| 0x14043E840 | NCareerProfile::CCheckPlaythroughValue::Evaluate func_names 名 NCareerProfile::CCheckPlaythroughValue::Evaluate |
| 0x1406A15A0 | NCareerProfile::SCareerProfileMedalData::Reader func_names 名 NCareerProfile::SCareerProfileMedalData::Reader |
| 0x14043E650 | NCareerProfile::CNumOfPointsTrigger::[0] vtable 槽 NCareerProfile::CNumOfPointsTrigger::[0]（func_names RTTI 名） |
| 0x141C326C0 | NCountryStatTracking::CConstructedBuildingsTracker::[1] vtable 槽 NCountryStatTracking::CConstructedBuildingsTracker::[1]（func_names RTTI 名） |
| 0x1406A16A0 | NCareerProfile::SCareerProfileStatistics::Reader func_names 名 NCareerProfile::SCareerProfileStatistics::Reader |
| 0x1406A18C0 | NCareerProfile::SCareerProfileStatistics::SReadAdapterV1::Reader func_names 名 NCareerProfile::SCareerProfileStatistics::SReadAdapterV1::Reader |
| 0x14043ECF0 | NCareerProfile::CSetPlaythroughVariableTrigger::Evaluate func_names 名 NCareerProfile::CSetPlaythroughVariableTrigger::Evaluate |
| 0x14043ED80 | NCareerProfile::CSetVariableTrigger::Evaluate func_names 名 NCareerProfile::CSetVariableTrigger::Evaluate |
| 0x1406AD0A0 | NCareerProfile::CProfileBackgroundDatabase::[1] vtable 槽 NCareerProfile::CProfileBackgroundDatabase::[1]（func_names RTTI 名） |
| 0x141CCBCA0 | NCareerProfile::CFrontendCareerProfileView::Reload func_names 名 NCareerProfile::CFrontendCareerProfileView::Reload |
| 0x1406A1770 | NCareerProfile::SPlaythroughCountryData::Reader func_names 名 NCareerProfile::SPlaythroughCountryData::Reader |
| 0x140441F00 | NCareerProfile::CCheckMedal::STooltips::Reader func_names 名 NCareerProfile::CCheckMedal::STooltips::Reader |
| 0x140A6D230 | NInlayWindowScript::SButton::Reader func_names 名 NInlayWindowScript::SButton::Reader |
| 0x1406A1720 | NCareerProfile::SGameModeStatistics::Reader func_names 名 NCareerProfile::SGameModeStatistics::Reader |
| 0x141E3FD70 | NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[3] func_names 名 NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[3] |
| 0x140441DE0 | NCareerProfile::CCheckRibbon::ParseToken func_names 名 NCareerProfile::CCheckRibbon::ParseToken |
| 0x1406AC310 | NCareerProfile::CCareerProfileMedal::CTierColors::Reader func_names 名 NCareerProfile::CCareerProfileMedal::CTierColors::Reader |
| 0x1417AD110 | NCareerProfile::CBasePopupWindow::Teardown func_names 名 NCareerProfile::CBasePopupWindow::Teardown |
| 0x14043E740 | NCareerProfile::CCheckMedal::Evaluate func_names 名 NCareerProfile::CCheckMedal::Evaluate |
| 0x1406A1660 | NCareerProfile::SCareerProfileRibbonData::Reader func_names 名 NCareerProfile::SCareerProfileRibbonData::Reader |
| 0x14043EA10 | NCareerProfile::CCheckRibbon::Evaluate func_names 名 NCareerProfile::CCheckRibbon::Evaluate |
| 0x1406AA780 | NCareerProfile::SPlaythroughCountryData::Writer func_names 名 NCareerProfile::SPlaythroughCountryData::Writer |
| 0x1402E30B0 | NCareerProfile::CStepMissiolinis::Execute func_names 名 NCareerProfile::CStepMissiolinis::Execute |
| 0x141E3FD30 | NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[2] func_names 名 NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[2] |
| 0x1406A1620 | NCareerProfile::SCareerProfileModDataSet::Reader func_names 名 NCareerProfile::SCareerProfileModDataSet::Reader |
| 0x140A6D270 | NInlayWindowScript::SProgressbar::Reader func_names 名 NInlayWindowScript::SProgressbar::Reader |
| 0x1406AA370 | NCareerProfile::SCareerProfileMedalData::Writer func_names 名 NCareerProfile::SCareerProfileMedalData::Writer |
| 0x140A91E60 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x140A91E90 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x140A91EC0 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x140AD29F0 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x1406AA7F0 | NCareerProfile::SProfileData::Writer func_names 名 NCareerProfile::SProfileData::Writer |
| 0x1406AA400 | NCareerProfile::SCareerProfileRibbonData::Writer func_names 名 NCareerProfile::SCareerProfileRibbonData::Writer |
| 0x1406AA3C0 | NCareerProfile::SCareerProfileModDataSet::Writer func_names 名 NCareerProfile::SCareerProfileModDataSet::Writer |
| 0x14043FC30 | NCareerProfile::CCheckPlaythroughRatio::GetDesc func_names 名 NCareerProfile::CCheckPlaythroughRatio::GetDesc |
| 0x141F0CB10 | NInterfaceMessages::SScopedListener<鈥�>::[0] func_names 名 NInterfaceMessages::SScopedListener<鈥�>::[0] |
| 0x141EF8B90 | NCareerProfile::CCareerProfileViewUpdateable::IsValid func_names 名 NCareerProfile::CCareerProfileViewUpdateable::IsValid |
| 0x14043F4A0 | NCareerProfile::CNumOfPointsTrigger::GetValue func_names 名 NCareerProfile::CNumOfPointsTrigger::GetValue |
| 0x1419C4038 | NCareerProfile::CMedalPopupWindow::[0] vtable 槽 NCareerProfile::CMedalPopupWindow::[0]（func_names RTTI 名） |
#### 4.25.17 世界层全局对象函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x1422990C0 | （无名） 断言站点 bitmapfont.cpp:2326 |
| 0x14125F200 | （无名） 断言站点 pdxmaptexturegeneration.cpp:612 |
| 0x1412607B0 | （无名） 断言站点 pdxmaptexturegeneration.cpp:274 |
| 0x14126F810 | （无名） 断言站点 maparrowmanager.cpp:1152 |
| 0x141260370 | （无名） 断言站点 pdxmaptexturegeneration.cpp:254 |

#### 4.25.18 世界层全局对象函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x1415ADA60 | （无名） 调用图传播: 2 锚点投 §4.25（50%） |
| 0x141663710 | （无名） 调用图传播: 2 锚点投 §4.25（50%） |
| 0x140A03EC0 | （无名） 调用图传播: 2 锚点投 §4.25（100%） |
| 0x140E96A40 | （无名） 调用图传播: 2 锚点投 §4.25（50%） |
| 0x141662440 | （无名） 调用图传播: 5 锚点投 §4.25（60%） |
| 0x141664B60 | （无名） 调用图传播: 2 锚点投 §4.25（50%） |

#### 4.25.19 世界层全局对象函数补遗（9 函）

| VA | 语义/证据 |
|---|---|
| 0x141250FA0 | 同区段近邻 sub_141264FE0(距 0x14040)属 4.25 族 sub_141250FA0 + 同区段近邻 sub_141264FE0(距 0x14040)属 4.25 族 |
| 0x141656700 | 调用图上游传播(占 60%, 2 票) sub_141656700 + 调用图上游传播(占 60%, 2 票) |
| 0x1424FCF20 | 调用图上游传播(占 100%, 1 票) sub_1424FCF20 + 调用图上游传播(占 100%, 1 票) |
| 0x142237360 | 调用图上游传播(占 100%, 1 票) sub_142237360 + 调用图上游传播(占 100%, 1 票) |
| 0x141264150 | 同区段近邻 sub_141264FE0(距 0xE90)属 4.25 族 sub_141264150 + 同区段近邻 sub_141264FE0(距 0xE90)属 4.25 族 |
| 0x1422599F0 | 调用图上游传播(占 100%, 1 票) sub_1422599F0 + 调用图上游传播(占 100%, 1 票) |
| 0x1424FD660 | 调用图上游传播(占 100%, 1 票) sub_1424FD660 + 调用图上游传播(占 100%, 1 票) |
| 0x142291340 | 调用图上游传播(占 100%, 1 票) sub_142291340 + 调用图上游传播(占 100%, 1 票) |
| 0x14143C7B0 | 域关键词匹配 sub_14143C7B0 + 域关键词匹配 |

#### 4.25.20 世界层全局对象函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x142225A50 | （无名） 调用图传播: 3 锚点投 §4.25（67%） |

#### 4.25.21 世界层全局对象函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x141B241E0 | 无名 sub_（断言站点/串定位） 断言站点 pdxmapgeneration.cpp:689 |
| 0x141B29D50 | 无名 sub_（断言站点/串定位） 串字面量 "ui_raid_mapmode" |
| 0x1418CD480 | 无名 sub_（断言站点/串定位） 串字面量 "ping_mapicon_offensive" |
| 0x141FE9950 | CCareerProfilePages::CreateTooltipHandlers::lambda_21 func_names 名「CCareerProfilePages::CreateTooltipHandlers::lambda_21」 |
| 0x1418CD740 | 无名 sub_（断言站点/串定位） 串字面量 "radar_mapico" |
| 0x141575ED0 | 无名 sub_（断言站点/串定位） 串字面量 "WindowWithAllMapModes" |
| 0x141B54650 | 无名 sub_（断言站点/串定位） 串字面量 "Terrain bitmap reloaded" |

#### 4.25.22 世界层全局对象函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x1422769D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.25 |
| 0x1423FDAF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.25 |
| 0x140A36BD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.25 |
| 0x140B559C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.25 |

#### 4.25.23 世界层全局对象函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141FC47A0 | 旧存档检测 旧存档检测：版本比对 dword_143335FEC + "OLD_SAVEGAME" 标记写入 |

#### 4.25.24 世界层全局对象函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x14024C5A0 | 相机锁定切换 std::string 初始化 + "Camera movement unlocked!" / "Camera movement locked!" + vt 304 |
| 0x1422184C0 | 相机视图设置 全局 qword_143451D98：+112 置 8 + 调 sub_1421CE2D0（相机注册）+ sub_1421D9420 + +416 = a1 |

#### 4.25.25 世界层全局对象函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141664D90 | 未决窗口函数 · 多指针对象析构 在 +32 数组定位后对 a2 槽 4/5/11/17/23/89/90/96/102/108 逐个 sub_142290140 释放 |

#### 4.25.26 世界层全局对象函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x1412DE900 | 地图层条件更新（由 gamegui 帧更新按 a1+1784 旗触发） 调用者 0x140B58470 结构（a1+1784/1808/1832/1840 分派同批 unitstacks/地形更新）；全局单例 qword_14332F698/qword_14332F6A0 |
| 0x1421E3940 | 地图视口计算 __m128 float 视口/坐标运算 + 全局 qword_143451C80（与 0x1421D72D0 同一单例）→ 地图视口计算 |
| 0x14201D520 | NCareerProfile::CCountryItem 构造 NCareerProfile::CCountryItem 构造：VT 该类，STR 'btn_bg' |
| 0x140E235D0 | CStrategicRegion::[1] 名:CStrategicRegion::[1] |
| 0x1406A1330 | NCareerProfile::SCareerProfileIntermediateStatistics::Reader 类名（职业档案中间统计反序列化） |
| 0x141546A50 | CAdjacencyRule::[0] 邻接规则（地图拓扑） |

#### 4.25.27 世界层全局对象函数补遗（171 函）

| VA | 语义/证据 |
|---|---|
| 0x141B7F6C0 | 业务 a1+968 列表 × 224 步长条目，a1+80 选 10 个时间通道，0..100000 钳位后 /100000 作 alpha 混合 18 个颜色结构：定时关系通道→地图图标颜色计算 |
| 0x140CF12C0 | CControllerArea::[3] 业务 func_names 名 CControllerArea::[3] + 调 CIcon::[54]/0x140D5A620；0x140CF1 邻域 COwnerArea/areas.cpp（近邻传播） |
| 0x1402B37E0 | CHistoryLogger::OnDailyUpdate? 业务 func_names 名 CHistoryLogger::OnDailyUpdate?（历史日志每日更新入口） |
| 0x141596940 | 业务 夹于 CScriptableValue::Reader(d=9072) 与 tbb::finish_reduce<CFindEdgesThreaded>::[0](d=6720)，脚本值/并行寻边族 |
| 0x1415966A0 | 业务 夹于 CScriptableValue::Reader(d=8400) 与 tbb::finish_reduce<CFindEdgesThreaded>::[0](d=7392)，脚本值/并行寻边族（与 0x141596940 同簇） |
| 0x141653530 | CCitySettings::SDistanceMesh::Reader 业务 CCitySettings::SDistanceMesh::Reader，城市距离网格反序列化 |
| 0x1406E5990 | sub_1406E5990 业务 串 SCORE_CALC_TOTAL/SCORE_CALC_SCORE_MULT |
| 0x140D38190 | sub_140D38190 业务 串：_pInstance && \ 、 C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\games |
| 0x14194F640 | 业务 断言站点 gamestate.h:25 ->§4.1; 断言站点 gamestate.h:26 ->§4.1; 串 "_pInstance && \"gamestate unitiliali" |
| 0x140E21640 | sub_140E21640 业务 串：C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\triggers\\career_profil |
| 0x140A2E2C0 | 业务 类路由 NIndustrialOrganisation ->§4.25; 串 "Multiple limits in target effect" ->§4.32; 调用图 IDF top §4.1 frac 1.00 |
| 0x141209400 | 业务 类路由 NOperativeMissions ->§4.25; 串 "icon"; 串 "icon" |
| 0x14221D4A0 | 业务 断言站点 graphicalmap.cpp:32; 断言站点 strategicregion.cpp:32; 类路由 NInternationalMarket ->§4.25 |
| 0x14227C930 | 业务 断言站点 doctrine_effects.cpp:52 ->§4.25; 断言站点 doctrine_effects.cpp:57 ->§4.25; 断言站点 doctrine_effects.cpp:62 ->§4.25 |
| 0x14108F4D0 | 业务 断言站点 orderscommands.cpp:82; 类路由 NCareerProfile ->§4.25; 类路由 CAnyCountryWithOriginalTagTrigger ->§4.32 |
| 0x1421CE700 | 相机钳位 相机/视口参数钳位：全局相机对象 qword_143451C80（+592/+624/+628/+208 浮点）+ fmaxf(4.0, …) 下限 |
| 0x141AD9CA0 | 业务 类路由 NInternationalMarket ->§4.25; 串 "UNIT_LEADER_NO_LEADER"; 串 "Multiple limits in target effect" ->§4.32 |
| 0x1424D4270 | 业务 类路由 NCareerProfile ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.24 |
| 0x1411957F0 | 业务 类路由 NFactions ->§4.25; 类路由 NProject ->§4.25; 串 "kernel32.dll" |
| 0x14016AF00 | 业务 类路由 CHasUnitLeaderTrigger ->§4.32; 类路由 NCareerProfile ->§4.25; 调用图 IDF top §4.1 frac 1.00 |
| 0x141488BE0 | 业务 断言站点 armiesview.cpp:24; 串 "_SortComparators.GetSize() == 1 \ \ _"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1424D8A30 | 业务 断言站点 sub_doctrine_template.cpp:50; 断言站点 sub_doctrine_template.cpp:54; 断言站点 gamestate.h:25 ->§4.1 |
| 0x140F8CD40 | 业务 类路由 NFactions ->§4.25; 串 "displayIndex must be in the range 0 "; 串 "index must be in the range of 0 - %d" |
| 0x142139700 | 业务 类路由 NPdx ->§4.25; 串 "gamma value does not match sRGB"; 串 "gamma value does not match libpng es" |
| 0x1424FB700 | 业务 类路由 NDoctrines ->§4.25; 类路由 NCombatLog ->§4.25; 串 "AMOUNT" |
| 0x141B3F1F0 | 业务 断言站点 physfs.cpp:34 ->§4.1; 类路由 NAiNavalGoals ->§4.25; 类路由 NAiNavalGoals ->§4.25 |
| 0x1421D4050 | 相机状态 全局相机对象 qword_143451C80：读其 +846 子项，v6+320 &#124;= v6+328 标志合并 + +888 / 0x800000 分支 |
| 0x1421F8660 | 业务 断言站点 career_profile_trigger_implementation.cpp:92 ->§4.25; 断言站点 gamestate.h:26 ->§4.1; 类路由 NCareerProfile ->§4.25 |
| 0x140B5D320 | 业务 断言站点 countrycommands.cpp:2; 类路由 CAddProductionLineCommand ->§4.33; 类路由 NProject ->§4.25 |
| 0x1401BF770 | 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 0.73 |
| 0x140A8DA20 | 业务 断言站点 null_object.h:33; 串 "_pInstance"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x141981010 | 业务 断言站点 ordersgroup.cpp:10; 断言站点 pdxmeshobject.cpp:814 ->§4.1; 串 "VALUE" |
| 0x14164D480 | 业务 断言站点 pdx_anim.cpp:24; 串 "sprite"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x1421F6830 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 断言站点 doctrine_triggers.cpp:38 ->§4.25; 断言站点 ingameinterfacehandler.cpp:44 |
| 0x14178F970 | 业务 类路由 NCareerProfile ->§4.25; 调用图 IDF top §4.1 frac 0.48; 反传 1/2 调用者 §4.23 |
| 0x1401AC710 | 业务 断言站点 doctrine_system.cpp:80; 类路由 NDoctrines ->§4.25; 串 "air" |
| 0x140A258A0 | 业务 类路由 CFixedWindow ->§4.30; 调用图 IDF top §4.1 frac 1.00; 邻域 21/25 票 §4.25（同类方法连续排放） |
| 0x140AD24E0 | 业务 断言站点 pdx_pinned_array.h:28 ->§4.1; 断言站点 career_profile_trigger_implementation.cpp:89 ->§4.25; 断言站点 raid_instance.cpp:10 ->§4.25 |
| 0x141ED2BF0 | 业务 类路由 CServer ->§4.36; 调用图 IDF top §4.1 frac 1.00; 邻域 17/18 票 §4.25（同类方法连续排放） |
| 0x1401BEFD0 | 业务 类路由 NIndustrialOrganisation ->§4.25; 串 "set_mio_funds_gain_factor expects a "; 调用图 IDF top §4.1 frac 1.00 |
| 0x140F72A30 | 业务 断言站点 career_profile_trigger_implementation.cpp:76 ->§4.25; 类路由 NDoctrines ->§4.25; 类路由 CSetOrderGroupOrdersInstanceNamesCommand ->§4.33 |
| 0x140FF81C0 | 业务 类路由 CSetAreaDefenseSettingCommand ->§4.33; 类路由 CAddConveyorLineCommand ->§4.33; 类路由 NAirWingReorganizationUI ->§4.25 |
| 0x140A90B30 | 业务 断言站点 gamestate.h:25 ->§4.1; 断言站点 gamestate.h:26 ->§4.1; 断言站点 pdx_robin_hood_table.h:58 ->§4.00 |
| 0x140A4C130 | 业务 类路由 CCapitalMapIcon ->§4.31; 类路由 CMapIcon ->§4.31; 类路由 NFactions ->§4.25 |
| 0x140A57D10 | 业务 断言站点 orderscommands.cpp:49; 串 "Mismatch between write and read"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x140EC1A20 | 业务 类路由 NInternationalMarket ->§4.25; 类路由 NInternationalMarket ->§4.25; 串 "title" |
| 0x1421F5130 | 业务 断言站点 database_scoped_variables.h:93; 断言站点 gamestate.h:16 ->§4.1; 断言站点 gamestate.h:17 ->§4.1 |
| 0x1424E8DC0 | 业务 断言站点 gamestate.h:26 ->§4.1; 类路由 NRaids ->§4.25; 串 "_ThreadForbidCount == 0 && \"Current" |
| 0x141B16850 | 业务 断言站点 gamestate.h:25 ->§4.1; 断言站点 gamestate.h:26 ->§4.1; 断言站点 peaceactions.cpp:11 |
| 0x140B5CB70 | 业务 类路由 NRaids ->§4.25; 调用图 IDF top §4.1 frac 0.77; 邻域 3/3 票 §4.25（同类方法连续排放） |
| 0x1421F8910 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 CCountryManpower ->§4.28; 调用图 IDF top §4.1 frac 0.59 |
| 0x140A45D80 | 业务 断言站点 gamesynchronizationmanager.cpp:62; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"; 串 "); v7 = sub_14011D290(v6, a2); " |
| 0x1413B7450 | 业务 断言站点 null_object.h:40; 串 "_pInstance"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x141181E90 | 业务 类路由 NInternationalMarket ->§4.25; 调用图 IDF top §4.1 frac 1.00; 邻域 8 票 §4.28（票散） |
| 0x140A25980 | 业务 类路由 CCombatHistoryEntry ->§4.31; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.26 |
| 0x141B2B080 | 业务 类路由 NFactions ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.25 |
| 0x140D8DE70 | 业务 类路由 NIndustrialOrganisation ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.12 |
| 0x1422D7B30 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 NRaids ->§4.25; 串 "EFFECT_MIO_UNLOCK_POLICY" |
| 0x141FB5F20 | 业务 串 "Invalid renderer"; 串 "Invalid renderer"; 调用图 IDF top §4.1 frac 1.00 |
| 0x140A60B70 | 业务 断言站点 folder_status.cpp:39; 类路由 CCryptology ->§4.28; 串 "Cannot assign subdoctrine to invalid" |
| 0x140175530 | 业务 类路由 NIndustrialOrganisation ->§4.25; 串 "EFFECT_MIO_UNLOCK_TRAIT"; 调用图 IDF top §4.1 frac 1.00 |
| 0x1421FED00 | 业务 类路由 NDoctrines ->§4.25; 调用图 IDF top §4.1 frac 1.00 |
| 0x1402D0BD0 | 业务 类路由 NProject ->§4.25; 串 "Scoped character has no scientist ro"; 串 "trade" |
| 0x141B046A0 | 业务 串 "Video subsystem has not been initial"; 串 "Invalid window" ->§4.30; 串 "The specified window isn't an OpenGL" |
| 0x1409ECC40 | 业务 类路由 NDoctrines ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26 |
| 0x1413B69C0 | 业务 类路由 NOperativeMissions ->§4.25; 调用图 IDF top §4.1 frac 1.00; 邻域 22/28 票 §4.25（同类方法连续排放） |
| 0x141596EC0 | 业务 断言站点 create_equipment_variant_scheduler.cpp:18; 断言站点 create_equipment_variant_scheduler.cpp:14; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x140E83FA0 | 业务 断言站点 unit_stats.cpp:12; 类路由 CAddConstructionCommand ->§4.33; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x141619090 | 业务 断言站点 relationstripview.cpp:77 ->§4.1; 串 "Not supported!"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1420694A0 | 业务 断言站点 pdx_view.h:9; 串 "reinterpret_cast<const TDerived*>( t"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x141665DB0 | 业务 断言站点 cic_bank.cpp:66; 类路由 NIndustrialOrganisation ->§4.25; 类路由 CSetEquipmentVariantHighlightCommand ->§4.33 |
| 0x140FDEBD0 | 业务 类路由 CArmyGroupCommand ->§4.33; 串 "Couldn't send rumble packet"; 调用图 IDF top §4.1 frac 1.00 |
| 0x141B00B30 | 业务 类路由 CProductionLineMilitaryItem ->§4.31; 类路由 NCareerProfile ->§4.25; 串 "Parameter '%s' is invalid" |
| 0x140FE3910 | 业务 类路由 CNavalMissionSetTypeCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00; 邻域 17/21 票 §4.25（同类方法连续排放） |
| 0x141FFA810 | 业务 断言站点 production.cpp:40 ->§4.8; 类路由 NDoctrines ->§4.25; 串 "SET_SUB_DOCTRINE_EFFECT" |
| 0x14014E700 | 业务 断言站点 subunitdefinition.cpp:99; 类路由 NIndustrialOrganisation ->§4.25; 串 "Unknown subunit type" |
| 0x141079F50 | 业务 断言站点 raid_items.cpp:21 ->§4.25; 类路由 CMergeArmiesCommand ->§4.33; 类路由 NOperativeMissions ->§4.25 |
| 0x1413B73B0 | 业务 类路由 NFactions ->§4.25; 类路由 CSetAreaDefenseSettingCommand ->§4.33; 类路由 CCryptologyViewCountryEntry ->§4.31 |
| 0x140151050 | 业务 串 "Posteffect volumes OFF."; 串 "Posteffect volumes ON."; 调用图 IDF top §4.1 frac 0.98 |
| 0x1424C6520 | 业务 类路由 NInternationalMarket ->§4.25; 串 "DIPLOMACY_REVOKE_INTERNATIONAL_MARKE"; 串 "DIPLOMACY_REQUEST_INTERNATIONAL_MARK" |
| 0x141001680 | 业务 类路由 CProductionLineInterfaceFactoriesScaleCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.25 |
| 0x140B67C20 | 业务 串 "combat"; 调用图 IDF top §4.1 frac 1.00; 邻域 3/3 票 §4.25（同类方法连续排放） |
| 0x141799FE0 | 业务 断言站点 eventscope.h:93; 串 "( pScope == this \ \ pScope->_pFrom !"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1409D0660 | 业务 断言站点 pdxoptional.h:73 ->§4.1; 串 "_bIsSet"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x14146BC90 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 NProject ->§4.25; 类路由 CCountryIntelligenceAgencyView ->§4.30 |
| 0x142481C90 | 业务 断言站点 gameapplication.cpp:15; 断言站点 doctrine_effects.cpp:35 ->§4.25; 类路由 NDoctrines ->§4.25 |
| 0x14251D708 | 业务 断言站点 doctrine_effects.cpp:10 ->§4.25; 类路由 NDoctrines ->§4.25; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x140F9AC90 | 业务 类路由 NNavalCombatHit ->§4.25; 类路由 NCareerProfile ->§4.25; 类路由 CFrontEndView ->§4.30 |
| 0x14147D6B0 | 业务 串 "FILE*"; 调用图 IDF top §4.1 frac 0.54; 反传 1/1 调用者 §4.26 |
| 0x14253799C | 业务 类路由 NFactions ->§4.25; 类路由 CAddMassFactoryAssignmentCommand ->§4.33; 串 "FACTION_UPGRADE_NO_FACTION" |
| 0x140A613E0 | 业务 类路由 CUnlockResearchCommand ->§4.33; 类路由 CScriptedGUIDiplomacyPopup ->§4.30; 调用图 IDF top §4.1 frac 1.00 |
| 0x141A08E70 | 业务 串 "SDL_RenderDrawPointsF(): Passed NULL"; 串 "Invalid renderer"; 调用图 IDF top §4.1 frac 0.44 |
| 0x141BAF190 | 业务 类路由 COperativeMapIconEntry ->§4.31; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.34 |
| 0x140FF8480 | 业务 类路由 CUpdateSupplyNodeCountrySettingsCommand ->§4.33; 类路由 CResourceMapIcon ->§4.31; 类路由 NFactions ->§4.25 |
| 0x141980FA0 | 业务 断言站点 pdx_cloudstorage.cpp:41; 类路由 NCareerProfile ->§4.25; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x141FFA950 | 业务 类路由 CContainerWindow ->§4.30; 调用图 IDF top §4.1 frac 0.75; 反传 1/1 调用者 §4.31 |
| 0x1424E65E0 | 业务 类路由 NDoctrines ->§4.25; 串 "UNLOCK_SUBUNIT_EFFECT"; 串 "NAME" |
| 0x141757C10 | 业务 类路由 NAirWingReorganizationUI ->§4.25; 串 "Lua function expected"; 调用图 IDF top §4.1 frac 1.00 |
| 0x141CF5AE0 | 业务 串 "Name or special project need to be s"; 调用图 IDF top §4.1 frac 1.00; 邻域 6/13 票 §4.25（同类方法连续排放） |
| 0x141987350 | 业务 类路由 NFactions ->§4.25; 类路由 CContainerWindow ->§4.30; 串 "Couldn't write init packet" |
| 0x14192E140 | 业务 类路由 NRaids ->§4.25; 调用图 IDF top §4.1 frac 0.67; 邻域 5/11 票 §4.28（同类方法连续排放） |
| 0x1417F3390 | 业务 类路由 CIntelligenceAgencyCreationCommand ->§4.33; 类路由 NFactions ->§4.25; 类路由 NIndustrialOrganisation ->§4.25 |
| 0x140686FE0 | 业务 断言站点 buildingreference.cpp:48; 类路由 CVictoryPointMapIcon ->§4.31; 串 "synthetic_refinery" |
| 0x1409C29F0 | 业务 断言站点 equipmentvariant.cpp:24 ->§4.23; 类路由 CMassRemoveProductionsLineCommand ->§4.33; 类路由 CNavyCancelActivityCommand ->§4.33 |
| 0x14153CBC0 | 业务 断言站点 fleetsbottombar.cpp:95; 断言站点 doctrine_effects.cpp:73 ->§4.25; 类路由 CDisbandTheaterGroupCommand ->§4.33 |
| 0x140686DD0 | 业务 串 "coastal_bunker"; 调用图 IDF top §4.1 frac 0.75; 邻域 19/20 票 §4.25（同类方法连续排放） |
| 0x14136ECA0 | 业务 断言站点 peace_conference_database.cpp:12 ->§4.1; 断言站点 combatlog.cpp:40 ->§4.22; 类路由 NIndustrialOrganisation ->§4.25 |
| 0x141AF78B0 | 业务 类路由 CCollabarationViewItem ->§4.31; 串 "(mission specific)"; 串 "(generic)" |
| 0x142286B30 | 业务 类路由 NFactions ->§4.25; 类路由 CCarrierAirWingCompositionEntry ->§4.31; 调用图 IDF top §4.1 frac 1.00 |
| 0x141661880 | 业务 类路由 NInternationalMarket ->§4.25; 类路由 CStandardGridBox ->§4.30; 调用图 IDF top §4.1 frac 1.00 |
| 0x1420F5FB0 | 业务 类路由 NRaids ->§4.25; 类路由 NFactions ->§4.25; 串 "AUTONOMY_CHANGE_TO_DESC" |
| 0x140A4EA90 | 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 0.88; 邻域 20/24 票 §4.25（同类方法连续排放） |
| 0x141A08DC0 | 业务 串 "InitializeCriticalSectionEx"; 调用图 IDF top §4.1 frac 0.46; 邻域 7/13 票 §4.25（同类方法连续排放） |
| 0x142486D00 | 业务 类路由 NCareerProfile ->§4.25; 调用图 IDF top §4.1 frac 1.00; 邻域 2/2 票 §4.31（同类方法连续排放） |
| 0x140A69500 | 业务 断言站点 orderinstance.cpp:24; 串 "NO_ADVANCE_ALLOWED"; 串 "!\"Battleplans - illegal disconnecti" |
| 0x1417743B0 | 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.8 |
| 0x140CBDBF0 | 业务 类路由 CNavalMissionMassMoveCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00; 邻域 10/15 票 §4.25（同类方法连续排放） |
| 0x1406B3D00 | 业务 断言站点 grand_doctrine_template.cpp:61; 串 "Attempt to access milestone for inva"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1411B3860 | 业务 类路由 NNotification ->§4.25; 类路由 COrderSetCollapseCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00 |
| 0x1420ADB80 | 业务 串 "missing_triggers.txt"; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.25 |
| 0x141FFF730 | 业务 断言站点 pdx_conditional_view.h:25 ->§4.1; 串 "ActiveBranch < BranchCount"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x1424C6270 | 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00 |
| 0x140159050 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 CHasCapturedOperativeTrigger ->§4.32; 类路由 CCountryIntelligenceAgencyView ->§4.30 |
| 0x141FF7020 | 业务 串 "Declaring wars without wargoal is no"; 串 "Declaring wars without wargoal is no"; 调用图 IDF top §4.1 frac 1.00 |
| 0x141B167B0 | 业务 断言站点 merge_groups_option.cpp:81; 类路由 NAirSelectionUI ->§4.25; 串 "(null)" |
| 0x141BFB2F0 | 业务 类路由 CProductionLineShipRefitItem ->§4.31; 调用图 IDF top §4.1 frac 0.68; 反传 1/1 调用者 §4.25 |
| 0x14162D3A0 | 业务 类路由 COrderConnectCommand ->§4.33; 类路由 CSetEquipmentVariantOverrideModelCommand ->§4.33; 类路由 NAirSelectionUI ->§4.25 |
| 0x141F9E600 | 业务 类路由 NFactions ->§4.25; 类路由 NProject ->§4.25; 串 "Parameter '%s' is invalid" |
| 0x140A67D50 | 业务 类路由 NFactions ->§4.25; 类路由 CIcon ->§4.31; 调用图 IDF top §4.1 frac 1.00 |
| 0x140194D00 | 业务 断言站点 timing.cpp:45; 类路由 NDoctrines ->§4.25; 串 "timing not initialized" |
| 0x140D941D0 | 业务 类路由 CSetPendingReassignTargetCommand ->§4.33; 类路由 CSetEquipmentVariantNameListCommand ->§4.33; 串 "NAME" |
| 0x140FF2EB0 | 业务 类路由 CSelectionGroupCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00; 邻域 14/22 票 §4.25（同类方法连续排放） |
| 0x140CBB9E0 | 业务 类路由 CFactionSystem ->§4.10; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.34 |
| 0x140AA5E40 | 业务 类路由 CPromoteUnitLeaderCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.29 |
| 0x141AE5DB0 | 业务 类路由 CDonePeaceConferenceCommand ->§4.33; 串 "%s expected, got %s"; 调用图 IDF top §4.1 frac 1.00 |
| 0x142423910 | 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00; 邻域 2/2 票 §4.31（同类方法连续排放） |
| 0x1409D3BC0 | 业务 类路由 CArmy ->§4.18; 类路由 CSetArmyLeaderPreferredTacticCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00 |
| 0x1409FAC60 | 业务 类路由 CSetCountryReinforcementPriorityCommand ->§4.33; 类路由 NInternationalMarket ->§4.25; 类路由 NAirSelectionUI ->§4.25 |
| 0x141FFA2A0 | 业务 类路由 CLessCombatWidthThanOpponentTrigger ->§4.32; 类路由 CTacticsListEntry ->§4.31; 串 "SDL_OPENGL_ES_DRIVER" |
| 0x141B6E950 | 业务 类路由 NCareerProfile ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 2/2 调用者 §4.21 |
| 0x1420CA280 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 CIsExiledInTrigger ->§4.32; 串 "CreateTexture(D3DPOOL_SYSTEMMEM)" |
| 0x1409F19E0 | 业务 类路由 CArmyHistoryEntryItem ->§4.31; 串 "ASSIGN_COMMANDER_MEDAL_TOOLTIP"; 调用图 IDF top §4.23 frac 0.29 |
| 0x140155970 | 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25 |
| 0x1424EB6E0 | 业务 类路由 CHasStabilityTrigger ->§4.32; 类路由 NCombatLog ->§4.25; 类路由 NFactions ->§4.25 |
| 0x142474410 | 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00; 邻域 2/2 票 §4.31（同类方法连续排放） |
| 0x14153FB10 | 业务 类路由 NFactions ->§4.25; 类路由 NAirSelectionUI ->§4.25; 串 "__index" |
| 0x14246C210 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 CAddPopularityEffect ->§4.32; 调用图 IDF top §4.1 frac 1.00 |
| 0x14145B670 | 业务 类路由 NFactions ->§4.25; 类路由 CExtendedScrollbar ->§4.31; 串 "Joystick only has %d balls" |
| 0x1409C0010 | 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26 |
| 0x1401EB140 | 业务 类路由 NInternationalMarket ->§4.25; 类路由 CAmountManpowerInDeploymentQueueTrigger ->§4.32; 类路由 CServer ->§4.36 |
| 0x140B68530 | 业务 类路由 CStratAirEnableMissionCommand ->§4.33; 类路由 NProject ->§4.25; 串 "DIPLOMACY_REVOKE_MILACC" |
| 0x141A01C50 | 业务 类路由 NRaids ->§4.25; 调用图 IDF top §4.1 frac 0.53; 反传 1/1 调用者 §4.30 |
| 0x141773610 | 业务 类路由 CCreateConveyorExtendedCommand ->§4.33; 类路由 NProject ->§4.25; 串 "Parameter '%s' is invalid" |
| 0x1417942E0 | 业务 类路由 CInGameMenuSaveWindow ->§4.30; 串 "split_wing_btn"; 串 "unable to generate a unique filename" |
| 0x141BB0C50 | 业务 类路由 NAiNavalGoals ->§4.25; 串 "relation_strip_view"; 串 "Passed a NULL sem" |
| 0x14203D0F0 | 业务 断言站点 doctrine_effects.cpp:9 ->§4.25; 类路由 COverlappingElementsBox ->§4.30; 类路由 CMetaEffect ->§4.32 |
| 0x1413BAB30 | 业务 类路由 NFactions ->§4.25; 类路由 CSetWingReinforcementPreferenceCommand ->§4.33; 类路由 NRaids ->§4.25 |
| 0x14198B680 | 业务 串 "DIPLOMACY_REVOKE_OFFER_AIR_BASE_ACCE"; 串 "DIPLOMACY_OFFER_AIR_BASE_ACCESS"; 调用图 IDF top §4.1 frac 1.00 |
| 0x141FE83A0 | 业务 类路由 NProject ->§4.25; 串 "navy_theater_fleet_item"; 调用图 IDF top §4.1 frac 1.00 |
| 0x1406ACA90 | 业务 类路由 CProductionStatus ->§4.8; 类路由 CSetWingReinforcementPreferenceCommand ->§4.33; 串 "mouse_input" |
| 0x14161EB00 | 业务 类路由 NWarScoreDistributionHelper ->§4.25; 类路由 CTimedActivityDistributableViewItem ->§4.31; 串 "TIMED_ACTIVITY_ENTRY_DESC" |
| 0x141B92B10 | 业务 类路由 NIndustrialOrganisation ->§4.25; 类路由 NInternationalMarket ->§4.25; 类路由 CNullCheckBox ->§4.30 |
| 0x1409F8030 | 业务 类路由 NRaids ->§4.25; 类路由 NFactions ->§4.25; 类路由 NFactions ->§4.25 |
| 0x141F89B40 | 业务 类路由 CContainerWindow ->§4.30; 类路由 CMarkSunkShipInfoAsReadCommand ->§4.33; 串 "System audio output device" |
| 0x141932370 | 业务 类路由 NAirSelectionUI ->§4.25; 调用图 IDF top §4.1 frac 1.00; 邻域 5 票 §4.28（票散） |
| 0x142444710 | 业务 断言站点 convoys.cpp:12; 断言站点 gfx_dx11.cpp:55 ->§4.35; 类路由 CLockAllTemplateEffect ->§4.32 |
| 0x1402B2B20 | 业务 断言站点 effectimplementation.cpp:49 ->§4.32; 断言站点 doctrine_triggers.cpp:88 ->§4.25; 类路由 NDoctrines ->§4.25 |
| 0x14158C680 | 业务 类路由 CIntelligenceAgencyCancelUpgradeCommand ->§4.33; 类路由 CNullEditBox ->§4.30; 类路由 CHasManpowerTrigger ->§4.32 |
| 0x1422D7E80 | 业务 断言站点 effectimplementation.cpp:55 ->§4.32; 断言站点 doctrine_triggers.cpp:13 ->§4.25; 类路由 CPeaceActionCategoryEntry ->§4.31 |
| 0x141097CE0 | 业务 断言站点 adjacencyrule.cpp:60; 类路由 NProject ->§4.25; 类路由 CScientistList ->§4.31 |
| 0x1406A4AA0 | 业务 类路由 NProject ->§4.25; 类路由 CShipHistoryEntryItem ->§4.31; 类路由 CContainerWindow ->§4.30 |

#### 4.25.28 世界层全局对象函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x1406AA440 | NCareerProfile::SCareerProfileStatistics::Writer 业务 存档 writer：数组 a1+20（元素步长 2056）逐项 sub_1424C24F0 写出 + token 240/15953 写入（sub_1424BC260(18) 取串），第二数组 a1+32（元素… |

#### 4.25.29 世界层全局对象函数命名空间补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x14201ABE0 | NCareerProfile::CRibbonDisplaySlot + "ca NCareerProfile::CRibbonDisplaySlot + "career_profile_ribbon_ §4.1 CGameState/gamestate |
| 0x140440370 | NCareerProfile::CCheckRibbon::GetDesc NCareerProfile::CCheckRibbon::GetDesc（GetDesc 角色） |
| 0x14069EF70 | NCareerProfile::SCareerProfileAwards::Reader func_names 全名 NCareerProfile::SCareerProfileAwards::Reader，Reader/Writer 角色定 §4.29 |
| 0x1406A17E0 | NCareerProfile::SProfileData::Reader NCareerProfile::SProfileData::Reader + 名字角色规则(NCareerProfile::SProfileData::Reader); 被 NCareerProfile::SProfileData::Rea… |
| 0x141FDDB40 | NCareerProfile::CModAchievementItem::[0] — ACHIEVEMENT_UNLOCKED_WHEN / CAREER_PROFILE_MOD_ACHIEVEMENT_AVAILABLE_WHEN ACHIEVEMENT_UNLOCKED_WHEN / CAREER_PROFI… |
| 0x1419C4430 | NCareerProfile::CBasePopupWindow::Setup func_names 全名 + UI 后缀类（CBasePopupWindow） |

#### 4.25.30 世界层全局对象函数补遗（8 函）

| VA | 语义/证据 |
|---|---|
| 0x140BC7EF0 | 业务 调用者 sub_140BC6060 持 "Country/State/Leader scope variables ("、"logs/variable_dumps/"、"Temp Variables:"（变量转储助手） |
| 0x140CAD110 | 业务 串字面量 'TRADE_ROUTE_DELIVERY_TYPE_LOCKED' [4.25×1,4.8×1] |
| 0x140C17940 | 业务 串字面量 'STAT_BASE_VALUE' [4.25×1] |
| 0x140C16220 | 业务 串字面量 'STAT_BASE_VALUE' [4.25×1] |
| 0x1424D0490 | 业务 反调用图传播 2.0 权重锚点投 §4.25（top 占比 1.00） |
| 0x14014CC10 | 业务 反向调用图 1/2 调用者投 §4.25; 唯一被调用者在书内 §4.1 |
| 0x140CABE50 | 业务 反调用图传播 1.0 权重锚点投 §4.25（top 占比 1.00） |
| 0x1414ED320 | 业务 mangled `_Func_impl_no_alloc<lambda_103>::_Create` 属 `NCountryGameVariableInitialization::Create`（`unordered_map<CString, SGameValueFunctionEntry>`，入口签名 `… |

#### 4.25.31 常量串 getter 结构定案（16 函）

| VA | 语义/证据 |
|---|---|
| 0x14073DE00 | 常量串 getter: 返回常量串 "NCareerProfile::NAVAL_INVASION_MEDAL_DIVISION_MIN_BATTALION_COUNT"（高置信） |
| 0x14073DE30 | 常量串 getter: 返回常量串 "NCareerProfile::ORCHESTRA_OF_BOOM_RIBBON_SPECIAL_BATTALION_COUNT"（高置信） |
| 0x14073DE60 | 常量串 getter: 返回常量串 "NCareerProfile::TURNING_TIDE_MEDAL_DIVISION_MIN_BATTALION_COUNT"（高置信） |
| 0x14073DD60 | 常量串 getter: 返回常量串 "NCareerProfile::ENGINEERING_BEHEMOTH_MEDAL_ARMOR_RATING_BRONZE"（高置信） |
| 0x14073DD80 | 常量串 getter: 返回常量串 "NCareerProfile::ENGINEERING_BEHEMOTH_MEDAL_ARMOR_RATING_SILVER"（高置信） |
| 0x14073DD70 | 常量串 getter: 返回常量串 "NCareerProfile::ENGINEERING_BEHEMOTH_MEDAL_ARMOR_RATING_GOLD"（高置信） |
| 0x14073DD30 | 常量串 getter: 返回常量串 "NCareerProfile::CASTLES_IN_THE_AIR_MEDAL_AIR_DEFENSE_BRONZE"（高置信） |
| 0x14073DD50 | 常量串 getter: 返回常量串 "NCareerProfile::CASTLES_IN_THE_AIR_MEDAL_AIR_DEFENSE_SILVER"（高置信） |
| 0x14073DE40 | 常量串 getter: 返回常量串 "NCareerProfile::PARADROP_AWARD_DIVISION_MIN_BATTALION_COUNT"（高置信） |
| 0x14073DD40 | 常量串 getter: 返回常量串 "NCareerProfile::CASTLES_IN_THE_AIR_MEDAL_AIR_DEFENSE_GOLD"（高置信） |
| 0x14073DE50 | 常量串 getter: 返回常量串 "NCareerProfile::STEEL_AT_HIGH_SPEED_RIBBON_TANK_SPEED"（高置信） |
| 0x14073DE10 | 常量串 getter: 返回常量串 "NCareerProfile::NAVAL_INVASION_MEDAL_MAX_DURATION"（高置信） |
| 0x14073DE20 | 常量串 getter: 返回常量串 "NCareerProfile::NEVERMINE_ME_MEDAL_MIN_RATIO"（高置信） |
| 0x14073DDF0 | 常量串 getter: 返回常量串 "NCareerProfile::MOD_STATISTICS_GROUP_NAME"（高置信） |
| 0x14073DD20 | 常量串 getter: 返回常量串 "NCareerProfile::BLITZ_THIS_TACTIC_NAME"（高置信） |
| 0x14073DDE0 | 常量串 getter: 返回常量串 "NCareerProfile::MOD_STATISTICS_GROUP"（高置信） |

#### 4.25.32 单调用转发桩结构定案（102 函）

| VA | 语义/证据 |
|---|---|
| 0x1424C6400 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00（推定） |
| 0x1402CBC90 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 串 "Scoped character has no scientist ro"; 串 "trade"（推定） |
| 0x140A4D250 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 0.88; 邻域 20/24 票 §4.25（同类方法连续排放）（推定） |
| 0x14143C310 | 转发桩: 转发至 域关键词匹配 sub_14143C7B0 + 域关键词匹配（推定） |
| 0x140B73FB0 | 转发桩: 转发至 业务 断言站点 timing.cpp:45; 类路由 NDoctrines ->§4.25; 串 "timing not initialized"（推定） |
| 0x1426175F0 | 转发桩: 被调者 0x140A4D250 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1426304D0 | 转发桩: 被调者 0x1411BCDB0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x14263E100 | 转发桩: 转发至 业务 断言站点 armiesview.cpp:24; 串 "_SortComparators.GetSize() == 1 \ \ _"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1426F6160 | 转发桩: 转发至 业务 类路由 NDoctrines ->§4.25; 串 "UNLOCK_SUBUNIT_EFFECT"; 串 "NAME"（推定） |
| 0x14258E3E0 | 转发桩: 转发至 业务 串 "Posteffect volumes OFF."; 串 "Posteffect volumes ON."; 调用图 IDF top §4.1 frac 0.98（推定） |
| 0x1425A2A80 | 转发桩: 被调者 0x1402CBC90 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x140A59270 | 转发桩: 转发至 业务 断言站点 orderscommands.cpp:49; 串 "Mismatch between write and read"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x140A592B0 | 转发桩: 转发至 业务 断言站点 orderscommands.cpp:49; 串 "Mismatch between write and read"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1401C1670 | 转发桩: 转发至 业务 类路由 NInternationalMarket ->§4.25; 类路由 CAmountManpowerInDeploymentQueueTrigger ->§4.32; 类路由 CServer ->§4.36（推定） |
| 0x140D889B0 | 转发桩: 转发至 业务 类路由 NIndustrialOrganisation ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.12（推定） |
| 0x14192A860 | 转发桩: 转发至 业务 类路由 NRaids ->§4.25; 调用图 IDF top §4.1 frac 0.67; 邻域 5/11 票 §4.28（同类方法连续排放）（推定） |
| 0x140A46770 | 转发桩: 转发至 业务 断言站点 gamesynchronizationmanager.cpp:62; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"; 串 "); v7 = sub_14011D290(v6, a2); "（推定） |
| 0x141FFA4E0 | 转发桩: 转发至 业务 类路由 CContainerWindow ->§4.30; 调用图 IDF top §4.1 frac 0.75; 反传 1/1 调用者 §4.31（推定） |
| 0x140F42930 | 转发桩: 转发至 同区段近邻 sub_141264FE0(距 0x14040)属 4.25 族 sub_141250FA0 + 同区段近邻 sub_141264FE0(距 0x14040)属 4.25 族（推定） |
| 0x14179EB80 | 转发桩: 转发至 业务 断言站点 eventscope.h:93; 串 "( pScope == this \ \ pScope->_pFrom !"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1425FC4D0 | 转发桩: 被调者 0x140A4D250 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x140B56F10 | 转发桩: 转发至 调用图上游传播(占 60%, 2 票) sub_141656700 + 调用图上游传播(占 60%, 2 票)（推定） |
| 0x1401F82F0 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 0.73（推定） |
| 0x142639340 | 转发桩: 转发至 业务 断言站点 null_object.h:40; 串 "_pInstance"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1425F26A0 | 转发桩: 转发至 业务 类路由 CProductionStatus ->§4.8; 类路由 CSetWingReinforcementPreferenceCommand ->§4.33; 串 "mouse_input"（推定） |
| 0x14015EFA0 | 转发桩: 转发至 业务 断言站点 doctrine_system.cpp:80; 类路由 NDoctrines ->§4.25; 串 "air"（推定） |
| 0x141987270 | 转发桩: 转发至 业务 类路由 NFactions ->§4.25; 类路由 CContainerWindow ->§4.30; 串 "Couldn't write init packet"（推定） |
| 0x142628F50 | 转发桩: 转发至 业务 断言站点 raid_items.cpp:21 ->§4.25; 类路由 CMergeArmiesCommand ->§4.33; 类路由 NOperativeMissions ->§4.25（推定） |
| 0x14177B0C0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.8（推定） |
| 0x1425F8210 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26（推定） |
| 0x1425F8200 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26（推定） |
| 0x14267A740 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14258BFC0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x140B508A0 | 转发桩: 转发至 调用图上游传播(占 60%, 2 票) sub_141656700 + 调用图上游传播(占 60%, 2 票)（推定） |
| 0x1426370F0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x142217AB0 | 转发桩: 转发至 相机视图设置 全局 qword_143451D98：+112 置 8 + 调 sub_1421CE2D0（相机注册）+ sub_1421D9420 + +416 = a1（推定） |
| 0x1422184A0 | 转发桩: 转发至 相机视图设置 全局 qword_143451D98：+112 置 8 + 调 sub_1421CE2D0（相机注册）+ sub_1421D9420 + +416 = a1（推定） |
| 0x140E7D110 | 转发桩: 转发至 业务 类路由 CUnlockResearchCommand ->§4.33; 类路由 CScriptedGUIDiplomacyPopup ->§4.30; 调用图 IDF top §4.1 frac 1.00（推定） |
| 0x142626370 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x142225BB0 | 转发桩: 转发至 调用图上游传播(占 100%, 1 票) sub_142291340 + 调用图上游传播(占 100%, 1 票)（推定） |
| 0x14258C270 | 转发桩: 转发至 业务 反向调用图 1/2 调用者投 §4.25; 唯一被调用者在书内 §4.1（推定） |
| 0x142606530 | 转发桩: 被调者 0x140B508A0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1426153C0 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x1426EA760 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26（推定） |
| 0x142590560 | 转发桩: 被调者 0x1401C1670 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142623EB0 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x142626180 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x142639380 | 转发桩: 转发至 业务 类路由 NFactions ->§4.25; 类路由 CSetAreaDefenseSettingCommand ->§4.33; 类路由 CCryptologyViewCountryEntry ->§4.31（推定） |
| 0x142639390 | 转发桩: 转发至 业务 类路由 NFactions ->§4.25; 类路由 CSetAreaDefenseSettingCommand ->§4.33; 类路由 CCryptologyViewCountryEntry ->§4.31（推定） |
| 0x1426393B0 | 转发桩: 转发至 业务 类路由 NFactions ->§4.25; 类路由 CSetAreaDefenseSettingCommand ->§4.33; 类路由 CCryptologyViewCountryEntry ->§4.31（推定） |
| 0x1426393D0 | 转发桩: 转发至 业务 类路由 NFactions ->§4.25; 类路由 CSetAreaDefenseSettingCommand ->§4.33; 类路由 CCryptologyViewCountryEntry ->§4.31（推定） |
| 0x1426668D0 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x142617440 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x142623FC0 | 转发桩: 转发至 （无名） 体设 CVariables::vftable（RTTI 名）（推定） |
| 0x14263B940 | 转发桩: 被调者 0x14143C310 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1426F5B50 | 转发桩: 转发至 业务 类路由 NCareerProfile ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.24（推定） |
| 0x14258C7C0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14258C8E0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x1425EF670 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x1425F81F0 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26（推定） |
| 0x142663810 | 转发桩: 被调者 0x14177A830 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142675EC0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14268B2C0 | 转发桩: 转发至 业务 断言站点 fleetsbottombar.cpp:95; 断言站点 doctrine_effects.cpp:73 ->§4.25; 类路由 CDisbandTheaterGroupCommand ->§4.33（推定） |
| 0x1426F6090 | 转发桩: 转发至 业务 类路由 NDoctrines ->§4.25; 串 "UNLOCK_SUBUNIT_EFFECT"; 串 "NAME"（推定） |
| 0x14258C890 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x142639460 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x1417A1FE0 | 转发桩: 转发至 业务 断言站点 eventscope.h:93; 串 "( pScope == this \ \ pScope->_pFrom !"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1425F3690 | 转发桩: 被调者 0x1402CBC90 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x14268F2B0 | 转发桩: 转发至 业务 断言站点 production.cpp:40 ->§4.8; 类路由 NDoctrines ->§4.25; 串 "SET_SUB_DOCTRINE_EFFECT"（推定） |
| 0x14177A830 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/1 调用者 §4.8（推定） |
| 0x1425A2190 | 转发桩: 被调者 0x1402CBC90 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1425FD670 | 转发桩: 转发至 业务 类路由 NFactions ->§4.25; 类路由 CIcon ->§4.31; 调用图 IDF top §4.1 frac 1.00（推定） |
| 0x1425FD8C0 | 转发桩: 被调者 0x1402CBC90 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142615220 | 转发桩: 被调者 0x140D889B0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142662C40 | 转发桩: 被调者 0x14192A860 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142663DA0 | 转发桩: 转发至 业务 断言站点 unit_stats.cpp:12; 类路由 CAddConstructionCommand ->§4.33; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1426F6080 | 转发桩: 转发至 业务 类路由 NDoctrines ->§4.25; 串 "UNLOCK_SUBUNIT_EFFECT"; 串 "NAME"（推定） |
| 0x14265B010 | 转发桩: 转发至 业务 类路由 CIntelligenceAgencyCreationCommand ->§4.33; 类路由 NFactions ->§4.25; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x1401AB5D0 | 转发桩: 转发至 NScript::CNamedCollection::Load NScript::CNamedCollection::Load：VT CNamedCollection，STR '!_Paths.IsEmpty()'/'============================='（gameite…（推定） |
| 0x142657A00 | 转发桩: 被调者 0x14177B0C0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1426157D0 | 转发桩: 被调者 0x140D889B0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142638F40 | 转发桩: 被调者 0x140A4D250 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x14263E2C0 | 转发桩: 转发至 业务 断言站点 armiesview.cpp:24; 串 "_SortComparators.GetSize() == 1 \ \ _"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x14265B000 | 转发桩: 转发至 业务 类路由 CIntelligenceAgencyCreationCommand ->§4.33; 类路由 NFactions ->§4.25; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14265B020 | 转发桩: 转发至 业务 类路由 CIntelligenceAgencyCreationCommand ->§4.33; 类路由 NFactions ->§4.25; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14265B030 | 转发桩: 转发至 业务 类路由 CIntelligenceAgencyCreationCommand ->§4.33; 类路由 NFactions ->§4.25; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14265C570 | 转发桩: 被调者 0x140D889B0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142662D50 | 转发桩: 被调者 0x14192A860 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x142680DC0 | 转发桩: 被调者 0x14177B0C0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x14268DE70 | 转发桩: 被调者 0x140A4D250 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x14268F050 | 转发桩: 转发至 业务 类路由 CLessCombatWidthThanOpponentTrigger ->§4.32; 类路由 CTacticsListEntry ->§4.31; 串 "SDL_OPENGL_ES_DRIVER"（推定） |
| 0x14268F3D0 | 转发桩: 被调者 0x141FFA4E0 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1425FD700 | 转发桩: 转发至 业务 断言站点 orderinstance.cpp:24; 串 "NO_ADVANCE_ALLOWED"; 串 "!\"Battleplans - illegal disconnecti"（推定） |
| 0x1426309F0 | 转发桩: 转发至 业务 类路由 NProject ->§4.25; 类路由 CContinentEntry ->§4.31; 类路由 NIndustrialOrganisation ->§4.25（推定） |
| 0x14263E4B0 | 转发桩: 转发至 业务 断言站点 armiesview.cpp:24; 串 "_SortComparators.GetSize() == 1 \ \ _"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x14263E820 | 转发桩: 转发至 业务 断言站点 armiesview.cpp:24; 串 "_SortComparators.GetSize() == 1 \ \ _"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1426906D0 | 转发桩: 被调者 0x140A4D250 -> §4.25 (E:单调用转发(被调者入书))（推定） |
| 0x1426EA920 | 转发桩: 转发至 业务 类路由 NCombatLog ->§4.25; 调用图 IDF top §4.1 frac 1.00; 反传 1/2 调用者 §4.26（推定） |
| 0x1426F6170 | 转发桩: 转发至 业务 类路由 NDoctrines ->§4.25; 串 "UNLOCK_SUBUNIT_EFFECT"; 串 "NAME"（推定） |
| 0x1426F61A0 | 转发桩: 转发至 业务 类路由 NDoctrines ->§4.25; 串 "UNLOCK_SUBUNIT_EFFECT"; 串 "NAME"（推定） |
| 0x1411BCDB0 | 转发桩: 转发至 业务 类路由 NNotification ->§4.25; 类路由 COrderSetCollapseCommand ->§4.33; 调用图 IDF top §4.1 frac 1.00（推定） |
| 0x1401AC860 | 转发桩: 转发至 业务 断言站点 doctrine_system.cpp:80; 类路由 NDoctrines ->§4.25; 串 "air"（推定） |

#### 4.25.33 世界层全局对象函数补遗（16 函）

| VA | 语义/证据 |
|---|---|
| 0x140611980 | 反调用图单链锚点（0.5）投 §4.25；锚点 `sub_140556050` |
| 0x141598860 | 反调用图单链锚点（0.5）投 §4.25；锚点 `LOWORD` |
| 0x141A8E0E0 | 串 "![MD]\nGets the definite name of the current country." + 内联名 "GetNameDefinite" + aCountry_3；写 vtable off_1430B4B40 |
| 0x141A8DAC0 | 串 "![MD]\nGets the change rate description of the current country's power balance." + 内联名 "GetChangeRateDesc" + aCountry_3；末尾写 vtable off_1430B4EC0；同族 0x141A… |
| 0x1403A03E0 | 调用链 CDbRefVariable::GetForTooltip?@140397020 |
| 0x140AC7B10 | 调用图传播: 1 个命名调用者（1 游戏类，如 NDlcLocked::$00::Z::SUniformReader<…>::[3]）；多数投 §4.25 |
| 0x140DBE8E0 | 游戏 CU 簇内: NIndustrialOrganisation::SHistoryWithEqu / CInGameIdler::[0] |
| 0x140E000F0 | 游戏 CU 邻近: NInternationalMarket::CPurchaseDraftItem / CPdxHybridInlineBufferAllocator<H::$0CA: |
| 0x140FF1330 | 游戏 CU 簇内: NRaids::CRaidInstance::Writer / CCountryOccupationStatus::[0] |
| 0x1411F7AF0 | 串 "STAT_BASE_VALUE" |
| 0x1413B37A0 | 游戏 CU 簇内: NInternationalMarket::CRequestMarketAcce / CMarketRequestAutomation::HandleSendingM |
| 0x141480F90 | 游戏 CU 簇内: NDoctrines::CTrackStatus::Writer / NProject::CProjectPool::[0] |
| 0x1416182C0 | 游戏 CU 簇内: NFactions::COfferJoinFactionAction::Writ / start_for<…>::[1] |
| 0x141B16100 | 游戏 CU 簇内: CEvolveTankImgui::[8] / NInternationalMarket::COverrideMarketEqu |
| 0x141BFAE30 | 游戏 CU 邻近: _Func_impl_no_alloc<…>::[3] / NFactions::NUi::CDoctrineSharingFolderIt |
| 0x141EEADF0 | 游戏 CU 簇内: NProject::NUi::CProjectItem::[0] / CProgramAvailableProjectsView::Setup? |

#### 4.25.34 世界层全局对象函数补遗（96 函）

| VA | 语义/证据 |
|---|---|
| 0x14055C990 | 业务 邻域 modifier.cpp x2/pdxmodifier.cpp + 串 YES/NO + pdx_robin_hood_table.h x7 + qword_14332ED90 x7 |
| 0x1414F6C90 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F6AB0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F82C0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F6970 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x141981A70 | COfferDockingRightsRelation::[21] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7CF0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140F7ED40 | sub_140F7ED40 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F81B0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F7F50 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F64F0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7720 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414FFF30 | sub_1414FFF30 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x141955960 | sub_141955960 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F6100 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F8380 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F7E00 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F8C40 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F98B0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F70A0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F9020 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F5E20 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F9370 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F89C0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F7E90 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7800 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7910 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F79A0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7A30 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7C10 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7450 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7550 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7600 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F6810 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7AC0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7B40 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F9A10 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F8430 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F9170 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F9120 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F90E0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1414F5EF0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F5FB0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7890 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F91C0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140F2C370 | sub_140F2C370 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F8260 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x140D138A0 | sub_140D138A0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140F98980 | sub_140F98980 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x141955540 | sub_141955540 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14171AB40 | sub_14171AB40 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14193D370 | sub_14193D370 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140D3C9B0 | sub_140D3C9B0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1415EC3E0 | sub_1415EC3E0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140CFA490 | sub_140CFA490 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140FB8170 | sub_140FB8170 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140F9AC40 | sub_140F9AC40 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F84B0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 变参读取（VCString 键 + 定点 ×1e-5） |
| 0x1410ECF40 | sub_1410ECF40 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14144CBC0 | sub_14144CBC0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1415157C0 | sub_1415157C0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140D3FDF0 | sub_140D3FDF0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F73D0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F61E0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14147DC80 | sub_14147DC80 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7DB0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x141502EA0 | sub_141502EA0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1415EC450 | sub_1415EC450 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F61A0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F9870 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F74D0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7CA0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F90B0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7350 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F60C0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1413D82F0 | sub_1413D82F0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F5EB0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F5F70 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F7390 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14199FCB0 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14199FC50 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414929D0 | sub_1414929D0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F6030 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F6060 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F6090 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F6D30 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x14199FD20 | VCString::U?$equal_to::std::_Func_impl_no_alloc<…>::[2] 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140D8A6B0 | sub_140D8A6B0 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x140BB4C00 | sub_140BB4C00 业务 国家游戏变量 SGameValue 读取（VCString 键表，定点 ×1e-5） |
| 0x1414F5C60 | 同 gamestate.h:1125/1126 断言；100000×sub_140533410(v10, qword_14332F260+1120)；func_names 名 VCString::...equal_to 系槽契约误注（体证为准） |
| 0x1409E1F10 | 断言 "_pInstance && \"gamestate unitilialized"" + "_ThreadForbidCount == 0 && ..." + gamestate.h:1125/1126；*(a3+168) 索引 *(qword_14332F260+89*8)；100000×sub_1413… |
| 0x140B71820 | CU 同类簇: 邻接 140B716B0（CMapIconManagerImpl::[0]）/ 140B72210（CMapIconManagerImpl::[4]） |
| 0x14102ECF0 | CU 同类簇: 邻接 141029200（COrderInstance::[0]）/ 141037300（COrderInstance::[8]） |
| 0x1410B92D0 | CU 同类簇: 邻接 1410B4C40（CAIMilitaryMinister::[0]）/ 1410BBB80（CAIMilitaryMinister::[14]） |
| 0x141EE1DA0 | CU 同类簇: 邻接 141EE1B20（CAiFrontImportanceMapModeConfig::[0]）/ 141EE2240（CAiFrontImportanceMapModeConfig::[3]） |
| 0x1420791D0 | CU 同类簇: 邻接 142075E70（CDLCDescriptor::[0]）/ 142079C00（CDLCDescriptor::[7]） |
