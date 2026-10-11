

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

#### 4.25.10 世界层全局对象函数补遗（31 函）

| VA | 语义/证据 |
|---|---|
| 0x1404A4F20 | NRaids::CDamageRaidUnitEffect::[7] `EFFECT_RAID_DAMAGE`+`_RATIO`/`_PLANE`/`_UNIT`/`_STRENGTH`/`STR_VAL`/`ORG_VAL` 伤害构成 |
| 0x1402FF650 | NIndustrialOrganisation::CShowIndustrialOrgTooltip::GetDesc：NIndustrialOrganisation::CShowIndustrialOrgTooltip::GetDesc NIndustrialOrganisation::CShowIndustr… |
| 0x1416133E0 | NFactions::COfferJoinFactionAction::GetRequestDescText：NFactions::COfferJoinFactionAction::GetRequestDescText NFactions::COfferJoinFactionAction::GetRequestD… |
| 0x141C1D450 | NFactions::NUi::CAssignResearchFacilityWindow::[5] `faction_program_facility_item`+`NFactions::NUi::CResearchFacilityItem`/`NProject::NUi::CProjectFilterList… |
| 0x141C26EA0 | NFactions::NUi::CRuleTypeItem::[0]：NFactions::NUi::CRuleTypeItem::[0] |
| 0x140305BB0 | NInternationalMarket::CAddEquipmentSubsidyEffect::GetDesc：NInternationalMarket::CAddEquipmentSubsidyEffect::GetDesc NInternationalMarket::CAddEquipmentSubsid… |
| 0x141470830 | NFactions::NUi::CFactionTabSection::[0]：NFactions::NUi::CFactionTabSection::[0] NFactions::NUi::CFactionTabSection::[0]；串 FACTION_ACCESS_TO_MILITARY_TAB/FACT… |
| 0x14206C300 | NInternationalMarket::CPriceLevelsWidget::[0]：NInternationalMarket::CPriceLevelsWidget::[0] NInternationalMarket::CPriceLevelsWidget::[0]；串 INTERNATIONAL_MAR… |
| 0x140306230 | NInternationalMarket::CCancelPurchaseContractEffect::GetDesc（func_names 名） func_names 名 + 串 "INTERNATIONAL_MARKET_EQUIPMENT_AMOUNT"/"EFFECT_MARKET_CANCEL_PUR… |
| 0x140494B20 | NProject::CAddBreakthroughProgress::[7]（func_names 名） func_names 名 + 串 "ADD_BREAKTHROUGH_PROGRESS_EFFECT_DESC"/"ADD_BREAKTHROUGH_PROGRESS_EFFECT_SPECIALIZATI… |
| 0x141F17F30 | NProject::NUi::CScientistItem::[0]：NProject::NUi::CScientistItem::[0] NProject::NUi::CScientistItem::[0]；串 SCIENTIST_RECRUIT_COST_DEFAULT/DESC/LAST + SPECIAL… |
| 0x14043F5C0 | NCareerProfile::CCheckMedal::GetDesc：NCareerProfile::CCheckMedal::GetDesc NCareerProfile::CCheckMedal::GetDesc；断言 gameitemdatabase.h:142（func_names 直接命名，无其他自… |
| 0x1420066A0 | NInternationalMarket::CMarketAccessOverviewItem::[0]：NInternationalMarket::CMarketAccessOverviewItem::[0] NInternationalMarket::CMarketAccessOverviewItem::[0… |
| 0x142021910 | NIndustrialOrganisation::CLoadQueuePopUp::[0]：NIndustrialOrganisation::CLoadQueuePopUp::[0] NIndustrialOrganisation::CLoadQueuePopUp::[0]；串 INDUSTRIAL_ORG_QU… |
| 0x141CF4230 | NAirSelectionUI::CSelectedAirGroupView::[9]（func_names 名） func_names 名 + 串 "wings_compact_number_of_elements"：空军联队选择视图 |
| 0x140E20E00 | （未命名）strategicregion.cpp:164 strategicregion.cpp:164；"Game state needs to be initialized"，战略区域 |
| 0x141F169D0 | NFactions::NUi::CFactionMemberScientistItem::[0]：NFactions::NUi::CFactionMemberScientistItem::[0] NFactions::NUi::CFactionMemberScientistItem::[0]；串 FACTION_… |
| 0x140F38E60 | sub_140F38E60 gradientbordermanager.cpp:2451 "Hole in Strategic Regions DB at ID ="（战略区域数据库完整性检查） |
| 0x140497580 | NProject::CCompletePrototypeReward::[23]（func_names 名） func_names 名 + 串 "No prototype reward was provided"/"No project has the prototype reward option"/"No i… |
| 0x1408A2A80 | NDefines::CDefineRegistryHelper_NInterfaceFIXED_TOOLTIP_POSITION::[0]（func_names 名） func_names 名 + 断言 defines_graphics.h:534 ×4 + 串 "Error reading \"FIXED_TO… |
| 0x14019E780 | NScript::CNamedCollection::Load NScript::CNamedCollection::Load：VT CNamedCollection，STR '!_Paths.IsEmpty()'/'============================='（gameitemdatabase.… |
| 0x14043FF80 | NCareerProfile::CCheckPoints::GetDesc NCareerProfile::CCheckPoints::GetDesc：STR '_NOT'/'VALUE'（生涯档案检查点触发描述） |
| 0x140496860 | NProject::CInjureScientistEffect 槽7 NProject::CInjureScientistEffect 槽7：STR 'SPECIAL_PROJECT_INJURE_SCIENTIST_FOR_DAYS'/'Scoped character has no scientist role' |
| 0x140A2B780 | NFactions::CFactionUpgradeGroup 槽8（faction_upgrade_group.cpp:112） NFactions::CFactionUpgradeGroup 槽8（faction_upgrade_group.cpp:112）：STR 'default upgrade is n… |
| 0x141611590 | NFactions::CAssumeFactionLeadershipAction::GetActionTitleText（func_names 名） func_names 名 + 串 "DIPLOMACY_MESSAGE_ACTION_TITLE"/"_RECIPIENT_DESC"/"FACTION"：接任派… |
| 0x1420256F0 | NIndustrialOrganisation::CUpgradeVariantPopup 槽14 NIndustrialOrganisation::CUpgradeVariantPopup 槽14：STR '..._CONFIRM_POPUP_HEADER'/'EQUIPMENT_NAME'/'XPCOST'/… |
| 0x140495A20 | NProject::CAddScientistXpEffect 槽7 NProject::CAddScientistXpEffect 槽7：STR 'SCIENTIST_ADD_XP_SPECIALIZATION_EFFECT'/'SPECIALIZATION'/'timeout_progressbar' |
| 0x140440900 | NCareerProfile::CCheckValue::GetDesc NCareerProfile::CCheckValue::GetDesc：STR '_NOT'/'VALUE'/'TOOLTIP_VALUE' |
| 0x141BFEBD0 | NFactions::NUi::CConfirmFactionFacilityProgram 槽16（gamestate.h:1125） NFactions::NUi::CConfirmFactionFacilityProgram 槽16（gamestate.h:1125）：STR 'FACILITYNAME'/… |
| 0x141C1B760 | NFactions::NUi::CRequestManpowerWindow 槽6（gamestate.h:1125） NFactions::NUi::CRequestManpowerWindow 槽6（gamestate.h:1125）：STR 'REQUEST_FACTION_MANPOWER_VALUES'… |
| 0x140DB41C0 | （无名） vftable 类 CVariables::（静态资源/库装载） |

#### 4.25.11 世界层全局对象函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x141264FE0 | vtable/RTTI 类 CMapArrowDefinition sub_141264FE0 + vtable/RTTI 类 CMapArrowDefinition; 被 CMapArrowManager::LoadDefinitions? 等 1 命名函数调用 |
| 0x140E968D0 | CScriptedMapEntity::[0] CScriptedMapEntity::[0] + vtable/RTTI 类 CScriptedMapEntity; vtable/RTTI 含 CScriptedMapEntity; 被 CScriptedMapEntity::[0] 等 1 命名函数调用 |

#### 4.25.12 世界层全局对象函数补遗（9 函）

| VA | 语义/证据 |
|---|---|
| 0x1404A2740 | NProject::CCanAssignFactionSupportiveScientistToFaction::GetDesc 串 TRIGGER_FACTION_SUPPORTIVE_SCIENTIST_SPOTS / FACTIONNAME |
| 0x141FFDFC0 | NInternationalMarket::CPurchasableEquipmentWindow 槽 0 串 INTERNATIONAL_MARKET_FILTER_COUNTRY_BUTTON / INTERNATIONAL_MARKET_FILTERED_COUNTRY |
| 0x1402FBD80 | NIndustrialOrganisation::CUnlockTraitEffect::Execute "complete_mio_trait - trait is already unlocked. Do nothing." + industrial_org_effect_implementation.cpp… |
| 0x1420122B0 | NAiNavalGoals::CMineLayingObjective::[6] 类名（AI 海军布雷目标槽 6）+ "provinces" 串 |
| 0x1413B2130 | NInternationalMarket::CRequestMarketAccessRightsAction::CanExecute 类名 + "TRIGGER_UNFULLFILLED_PREFIX" loc 键（市场准入请求动作） |
| 0x141BFE8C0 | NFactions::NUi::CBecomeLeaderConfirmationWindow::[16] COST/FACTION/COOLDOWN loc 键 + CBecomeLeaderConfirmationWindow 类名 |
| 0x14179DE40 | NFactions::NUi::CFactionTheaterSwitch::[6] 类名 + "_miniature" 串（派系战场剧院切换 GUI 槽 6） |
| 0x1404A3140 | NProject::CIsProjectCompletedTrigger::GetDesc TRIGGER_IS_SPECIAL_PROJECT_COMPLETED / TRIGGER_IS_NOT_SPECIAL_PROJECT_COMPLETED loc 键 |
| 0x1420518F0 | NInternationalMarket::CPurchaseContractEntry::[0] "PURCHASE_CONTRACT_CANCEL" + buttonwrapper.h:34 断言（购买合同条目按钮） |

#### 4.25.13 世界层全局对象函数补遗（772 函）

| VA | 语义/证据 |
|---|---|
| 0x141AA52E0 | NInternationalMarket::CRequestEquipmentPurchaseAction::[24] vtable 槽 NInternationalMarket::CRequestEquipmentPurchaseAction::[24]（func_names RTTI 名） |
| 0x1420127B0 | NAiNavalGoals::CMineSweepingObjective::[10] vtable 槽 NAiNavalGoals::CMineSweepingObjective::[10]（func_names RTTI 名） |
| 0x142010CD0 | NAiNavalGoals::CConvoyRaidingObjective::[10] vtable 槽 NAiNavalGoals::CConvoyRaidingObjective::[10]（func_names RTTI 名） |
| 0x1413B1440 | NInternationalMarket::CRequestMarketAccessRightsAction::[24] vtable 槽 NInternationalMarket::CRequestMarketAccessRightsAction::[24]（func_names RTTI 名） |
| 0x1416024E0 | NFactions::CLeaveFactionAction::[24] vtable 槽 NFactions::CLeaveFactionAction::[24]（func_names RTTI 名） |
| 0x141F15DB0 | NFactions::NUi::CFilterRuleItem::[0] vtable 槽 NFactions::NUi::CFilterRuleItem::[0]（func_names RTTI 名） |
| 0x141377300 | NScript::SScriptedKey::[3] vtable 槽 NScript::SScriptedKey::[3]（func_names RTTI 名） |
| 0x14203CCC0 | NInternationalMarket::CSubsidyOverview::[0] vtable 槽 NInternationalMarket::CSubsidyOverview::[0]（func_names RTTI 名） |
| 0x141BBEEA0 | NNotification::CNotification::[0] vtable 槽 NNotification::CNotification::[0]（func_names RTTI 名） |
| 0x141EEE190 | NProject::NUi::CProgramOngoingProjectView::[12] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[12]（func_names RTTI 名） |
| 0x14179DA40 | NFactions::NUi::CFactionPingCountryItem::[20] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[20]（func_names RTTI 名） |
| 0x142014A80 | NAiNavalGoals::CTrainingObjective::[7] vtable 槽 NAiNavalGoals::CTrainingObjective::[7]（func_names RTTI 名） |
| 0x141B3B2E0 | NRaids::NUi::CRaidList::[6] vtable 槽 NRaids::NUi::CRaidList::[6]（func_names RTTI 名） |
| 0x141F8BD60 | NInternationalMarket::CMarketOverviewPanelController::[1] vtable 槽 NInternationalMarket::CMarketOverviewPanelController::[1]（func_names RTTI 名） |
| 0x14052B290 | NDoctrines::CAddDailyMasteryEffect::[5] vtable 槽 NDoctrines::CAddDailyMasteryEffect::[5]（func_names RTTI 名） |
| 0x141958F30 | NOperativeMissions::CDiplomaticPressure::[13] vtable 槽 NOperativeMissions::CDiplomaticPressure::[13]（func_names RTTI 名） |
| 0x1404987B0 | NProject::CEveryScientistEffect::[26] vtable 槽 NProject::CEveryScientistEffect::[26]（func_names RTTI 名） |
| 0x1406AFC60 | NCareerProfile::CRibbonDatabase::[1] vtable 槽 NCareerProfile::CRibbonDatabase::[1]（func_names RTTI 名） |
| 0x1406AB430 | NCareerProfile::CMedalDatabase::[1] vtable 槽 NCareerProfile::CMedalDatabase::[1]（func_names RTTI 名） |
| 0x1401605C0 | NRaids::CRaidDatabase::[1] vtable 槽 NRaids::CRaidDatabase::[1]（func_names RTTI 名） |
| 0x141FBABE0 | NIndustrialOrganisation::CDetailsInitialTraitItem::[0] vtable 槽 NIndustrialOrganisation::CDetailsInitialTraitItem::[0]（func_names RTTI 名） |
| 0x141E8AF40 | NRaids::NUi::CRaidUnitMapIconData::[1] vtable 槽 NRaids::NUi::CRaidUnitMapIconData::[1]（func_names RTTI 名） |
| 0x140160760 | NDoctrines::CRewardTemplate::[0] vtable 槽 NDoctrines::CRewardTemplate::[0]（func_names RTTI 名） |
| 0x142006460 | NInternationalMarket::CMarketAccessOverviewWindow::[0] vtable 槽 NInternationalMarket::CMarketAccessOverviewWindow::[0]（func_names RTTI 名） |
| 0x140A4BD20 | NIndustrialOrganisation::CPolicyDatabase::[0] vtable 槽 NIndustrialOrganisation::CPolicyDatabase::[0]（func_names RTTI 名） |
| 0x141F61F30 | NAirSelectionUI::CMergeGroupsOption::[3] vtable 槽 NAirSelectionUI::CMergeGroupsOption::[3]（func_names RTTI 名） |
| 0x14203CB90 | NInternationalMarket::CSubsidyOverview::CListController::[0] vtable 槽 NInternationalMarket::CSubsidyOverview::CListController::[0]（func_names RTTI 名） |
| 0x141E2F140 | NFactions::NUi::CFactionIconWindow::[0] vtable 槽 NFactions::NUi::CFactionIconWindow::[0]（func_names RTTI 名） |
| 0x140493FE0 | NProject::CInjureScientistEffect::[13] vtable 槽 NProject::CInjureScientistEffect::[13]（func_names RTTI 名） |
| 0x141F23760 | NIndustrialOrganisation::CEquipmentIconItem::[8] vtable 槽 NIndustrialOrganisation::CEquipmentIconItem::[8]（func_names RTTI 名） |
| 0x140A9D0E0 | NRaids::CRaidDatabase::[5] vtable 槽 NRaids::CRaidDatabase::[5]（func_names RTTI 名） |
| 0x142041D20 | NInternationalMarket::CMarketEquipmentItem::[0] vtable 槽 NInternationalMarket::CMarketEquipmentItem::[0]（func_names RTTI 名） |
| 0x141FA4340 | NProject::NUi::CProjectOutputRewardWindow::[6] vtable 槽 NProject::NUi::CProjectOutputRewardWindow::[6]（func_names RTTI 名） |
| 0x141F606B0 | NAirSelectionUI::CConsolidateWingsOption::[1] vtable 槽 NAirSelectionUI::CConsolidateWingsOption::[1]（func_names RTTI 名） |
| 0x141F629E0 | NAirSelectionUI::CRemoveFromGroupOption::[1] vtable 槽 NAirSelectionUI::CRemoveFromGroupOption::[1]（func_names RTTI 名） |
| 0x1402F6790 | NLoc::SScopeLocalizer::[2] vtable 槽 NLoc::SScopeLocalizer::[2]（func_names RTTI 名） |
| 0x141CEDB10 | NAirSelectionUI::CStrategicPrioritiesWindow::[0] vtable 槽 NAirSelectionUI::CStrategicPrioritiesWindow::[0]（func_names RTTI 名） |
| 0x142014800 | NAiNavalGoals::CInvasionSupportObjective::[1] vtable 槽 NAiNavalGoals::CInvasionSupportObjective::[1]（func_names RTTI 名） |
| 0x1416175F0 | NFactions::CJoinFactionAction::[57] vtable 槽 NFactions::CJoinFactionAction::[57]（func_names RTTI 名） |
| 0x141F11FD0 | NFactions::NUi::CChangeGoalItemRow::[0] vtable 槽 NFactions::NUi::CChangeGoalItemRow::[0]（func_names RTTI 名） |
| 0x141956E70 | NOperativeMissions::CControlTrade::[18] vtable 槽 NOperativeMissions::CControlTrade::[18]（func_names RTTI 名） |
| 0x141F63440 | NAirSelectionUI::CSplitWingOption::[1] vtable 槽 NAirSelectionUI::CSplitWingOption::[1]（func_names RTTI 名） |
| 0x140A94280 | NProject::CProjectDatabase::[2] vtable 槽 NProject::CProjectDatabase::[2]（func_names RTTI 名） |
| 0x141617440 | NFactions::CAssumeFactionLeadershipAction::[57] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[57]（func_names RTTI 名） |
| 0x14175A9A0 | NDivisionDesigner::CNicheSelectionItem::[0] vtable 槽 NDivisionDesigner::CNicheSelectionItem::[0]（func_names RTTI 名） |
| 0x140CD90A0 | NCombatLog::CEquipmentLoss::[0] vtable 槽 NCombatLog::CEquipmentLoss::[0]（func_names RTTI 名） |
| 0x1419578E0 | NOperativeMissions::CCounterIntelligence::[13] vtable 槽 NOperativeMissions::CCounterIntelligence::[13]（func_names RTTI 名） |
| 0x141B34C60 | NRaids::NUi::CRaidFeedbackView::[0] vtable 槽 NRaids::NUi::CRaidFeedbackView::[0]（func_names RTTI 名） |
| 0x1414774D0 | NFactions::NUi::CCountryFactionView::[9] vtable 槽 NFactions::NUi::CCountryFactionView::[9]（func_names RTTI 名） |
| 0x14200BF60 | NInternationalMarket::CEquipmentStockpileEquipmentItem::[0] vtable 槽 NInternationalMarket::CEquipmentStockpileEquipmentItem::[0]（func_names RTTI 名） |
| 0x14052B1C0 | NDoctrines::CAddMasteryEffect::[25] vtable 槽 NDoctrines::CAddMasteryEffect::[25]（func_names RTTI 名） |
| 0x141F63100 | NAirSelectionUI::CSplitSelectionButton::[1] vtable 槽 NAirSelectionUI::CSplitSelectionButton::[1]（func_names RTTI 名） |
| 0x141481D70 | NProject::CProjectPool::[0] vtable 槽 NProject::CProjectPool::[0]（func_names RTTI 名） |
| 0x141A04CB0 | NProject::CBreakthroughProgress::[2] vtable 槽 NProject::CBreakthroughProgress::[2]（func_names RTTI 名） |
| 0x141CF6C70 | NAirSelectionUI::CAirWingsToolbarController::[1] vtable 槽 NAirSelectionUI::CAirWingsToolbarController::[1]（func_names RTTI 名） |
| 0x142022260 | NIndustrialOrganisation::CSaveQueuePopUp::[15] vtable 槽 NIndustrialOrganisation::CSaveQueuePopUp::[15]（func_names RTTI 名） |
| 0x141796E70 | NFactions::NUi::CFactionTheaterItem::[0] vtable 槽 NFactions::NUi::CFactionTheaterItem::[0]（func_names RTTI 名） |
| 0x142007A30 | NInternationalMarket::CRequestAutomationOptionsWindow::[0] vtable 槽 NInternationalMarket::CRequestAutomationOptionsWindow::[0]（func_names RTTI 名） |
| 0x141F21C90 | NIndustrialOrganisation::CEquipmentIconItem::[0] vtable 槽 NIndustrialOrganisation::CEquipmentIconItem::[0]（func_names RTTI 名） |
| 0x141EEE860 | NProject::NUi::CProgramOngoingProjectView::[1] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[1]（func_names RTTI 名） |
| 0x140A2A260 | NFactions::CFactionUpgrade::[4] vtable 槽 NFactions::CFactionUpgrade::[4]（func_names RTTI 名） |
| 0x14205C830 | NAirSelectionUI::NQuickWingDeployment::CWingQuickDeployWidget::[0] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CWingQuickDeployWidget::[0]（func_names RTT… |
| 0x141CB1B40 | NProject::NUi::CFacilitiesTabView::[8] vtable 槽 NProject::NUi::CFacilitiesTabView::[8]（func_names RTTI 名） |
| 0x141F7C970 | NDesignerUI::CNicheIconListItem::[0] vtable 槽 NDesignerUI::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x140E856A0 | NRaids::CRaidSystem::[0] vtable 槽 NRaids::CRaidSystem::[0]（func_names RTTI 名） |
| 0x141C0C690 | NFactions::NUi::CChangeRuleWindow::[0] vtable 槽 NFactions::NUi::CChangeRuleWindow::[0]（func_names RTTI 名） |
| 0x141958180 | NOperativeMissions::CCounterIntelligence::[18] vtable 槽 NOperativeMissions::CCounterIntelligence::[18]（func_names RTTI 名） |
| 0x141F61FD0 | NAirSelectionUI::CMergeGroupsOption::[1] vtable 槽 NAirSelectionUI::CMergeGroupsOption::[1]（func_names RTTI 名） |
| 0x141761510 | NDivisionDesigner::CNicheSelectionItem::[0] vtable 槽 NDivisionDesigner::CNicheSelectionItem::[0]（func_names RTTI 名） |
| 0x141FBAF50 | NIndustrialOrganisation::CEquipmentTypeHeaderItem::[0] vtable 槽 NIndustrialOrganisation::CEquipmentTypeHeaderItem::[0]（func_names RTTI 名） |
| 0x141F7CA20 | NDesignerUI::CNicheIconListItem::[0] vtable 槽 NDesignerUI::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x140302F80 | NInternationalMarket::CAddEquipmentSubsidyEffect::[0] vtable 槽 NInternationalMarket::CAddEquipmentSubsidyEffect::[0]（func_names RTTI 名） |
| 0x141FDD840 | NCareerProfile::CMedalItem::[0] vtable 槽 NCareerProfile::CMedalItem::[0]（func_names RTTI 名） |
| 0x142047BC0 | NInternationalMarket::CPurchaseDraftItem::[0] vtable 槽 NInternationalMarket::CPurchaseDraftItem::[0]（func_names RTTI 名） |
| 0x142059AB0 | NInternationalMarket::CAddToMarketEquipmentItem::[0] vtable 槽 NInternationalMarket::CAddToMarketEquipmentItem::[0]（func_names RTTI 名） |
| 0x140D7D860 | NDoctrines::CFolderStatus::[0] vtable 槽 NDoctrines::CFolderStatus::[0]（func_names RTTI 名） |
| 0x14043E4F0 | NCareerProfile::CCheckValue::[0] vtable 槽 NCareerProfile::CCheckValue::[0]（func_names RTTI 名） |
| 0x14201E930 | NCareerProfile::CProfilePictureItem::[0] vtable 槽 NCareerProfile::CProfilePictureItem::[0]（func_names RTTI 名） |
| 0x140492890 | NProject::CCompleteProjectEffect::[6] vtable 槽 NProject::CCompleteProjectEffect::[6]（func_names RTTI 名） |
| 0x141617750 | NFactions::CLeaveFactionAction::[57] vtable 槽 NFactions::CLeaveFactionAction::[57]（func_names RTTI 名） |
| 0x141CF4190 | NAirSelectionUI::CAirWingEntry::[18] vtable 槽 NAirSelectionUI::CAirWingEntry::[18]（func_names RTTI 名） |
| 0x14203D6F0 | NInternationalMarket::CSubsidyOverview::[2] vtable 槽 NInternationalMarket::CSubsidyOverview::[2]（func_names RTTI 名） |
| 0x14015FBD0 | NAiNavalGoals::CGoalTemplate::[0] vtable 槽 NAiNavalGoals::CGoalTemplate::[0]（func_names RTTI 名） |
| 0x14043E5A0 | NCareerProfile::CCheckPoints::[0] vtable 槽 NCareerProfile::CCheckPoints::[0]（func_names RTTI 名） |
| 0x142010670 | NAiNavalGoals::CConvoyRaidingObjective::[0] vtable 槽 NAiNavalGoals::CConvoyRaidingObjective::[0]（func_names RTTI 名） |
| 0x14203D2F0 | NInternationalMarket::CSubsidyOverview::CListController::[1] vtable 槽 NInternationalMarket::CSubsidyOverview::CListController::[1]（func_names RTTI 名） |
| 0x140494180 | NProject::CSetProjectFlagEffect::[13] vtable 槽 NProject::CSetProjectFlagEffect::[13]（func_names RTTI 名） |
| 0x14206C270 | NInternationalMarket::CPriceLevelsWidget::[0] vtable 槽 NInternationalMarket::CPriceLevelsWidget::[0]（func_names RTTI 名） |
| 0x140A9B910 | NRaids::CEquipmentRequirements::[0] vtable 槽 NRaids::CEquipmentRequirements::[0]（func_names RTTI 名） |
| 0x141617590 | NFactions::CDismantleFactionAction::[57] vtable 槽 NFactions::CDismantleFactionAction::[57]（func_names RTTI 名） |
| 0x141CC33E0 | NDoctrines::CFolderView::[1] vtable 槽 NDoctrines::CFolderView::[1]（func_names RTTI 名） |
| 0x141957860 | NOperativeMissions::CCounterIntelligence::[20] vtable 槽 NOperativeMissions::CCounterIntelligence::[20]（func_names RTTI 名） |
| 0x141958EB0 | NOperativeMissions::CDiplomaticPressure::[20] vtable 槽 NOperativeMissions::CDiplomaticPressure::[20]（func_names RTTI 名） |
| 0x141BA7D20 | NFactions::CSetFactionIconAndColor::[0] vtable 槽 NFactions::CSetFactionIconAndColor::[0]（func_names RTTI 名） |
| 0x140A49830 | NIndustrialOrganisation::CPolicy::[0] vtable 槽 NIndustrialOrganisation::CPolicy::[0]（func_names RTTI 名） |
| 0x141FBAD20 | NIndustrialOrganisation::CDetailsSeparatorItem::[0] vtable 槽 NIndustrialOrganisation::CDetailsSeparatorItem::[0]（func_names RTTI 名） |
| 0x14015F350 | NScript::CConstant::[0] vtable 槽 NScript::CConstant::[0]（func_names RTTI 名） |
| 0x140A6CAA0 | NInlayWindowScript::SProgressbar::[0] vtable 槽 NInlayWindowScript::SProgressbar::[0]（func_names RTTI 名） |
| 0x141956280 | NOperativeMissions::CControlTrade::[20] vtable 槽 NOperativeMissions::CControlTrade::[20]（func_names RTTI 名） |
| 0x142053320 | NInternationalMarket::CEditMarketStockpileWindow::[0] vtable 槽 NInternationalMarket::CEditMarketStockpileWindow::[0]（func_names RTTI 名） |
| 0x140FC8530 | NDoctrines::CFolderStatus::[8] vtable 槽 NDoctrines::CFolderStatus::[8]（func_names RTTI 名） |
| 0x141F193C0 | NProject::NUi::CRecruitScientistWindow::[0] vtable 槽 NProject::NUi::CRecruitScientistWindow::[0]（func_names RTTI 名） |
| 0x14205D710 | NAirWingReorganizationUI::NInternal::CFilterListItem::[0] vtable 槽 NAirWingReorganizationUI::NInternal::CFilterListItem::[0]（func_names RTTI 名） |
| 0x141B3A810 | NRaids::NUi::CRaidList::[0] vtable 槽 NRaids::NUi::CRaidList::[0]（func_names RTTI 名） |
| 0x140D7DA20 | NDoctrines::STemporaryCostReduction::[0] vtable 槽 NDoctrines::STemporaryCostReduction::[0]（func_names RTTI 名） |
| 0x1415C6050 | NNavalCombatHit::SNavalHit::[0] vtable 槽 NNavalCombatHit::SNavalHit::[0]（func_names RTTI 名） |
| 0x140161080 | NIndustrialOrganisation::STreeFlavorText::[0] vtable 槽 NIndustrialOrganisation::STreeFlavorText::[0]（func_names RTTI 名） |
| 0x142011CE0 | NAiNavalGoals::CInvasionDefenseObjective::[3] vtable 槽 NAiNavalGoals::CInvasionDefenseObjective::[3]（func_names RTTI 名） |
| 0x142006380 | NInternationalMarket::CCancelMarketAccessPoup::[0] vtable 槽 NInternationalMarket::CCancelMarketAccessPoup::[0]（func_names RTTI 名） |
| 0x140160D80 | NCareerProfile::SCareerProfileStatistics::[0] vtable 槽 NCareerProfile::SCareerProfileStatistics::[0]（func_names RTTI 名） |
| 0x141CF3400 | NAirSelectionUI::CAirWingEntry::[0] vtable 槽 NAirSelectionUI::CAirWingEntry::[0]（func_names RTTI 名） |
| 0x141FD4300 | NAirSelectionUI::CGunEmplacementWingsSelectionItem::[0] vtable 槽 NAirSelectionUI::CGunEmplacementWingsSelectionItem::[0]（func_names RTTI 名） |
| 0x1417996A0 | NFactions::NUi::CFactionPingCountryItem::[21] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[21]（func_names RTTI 名） |
| 0x141F0F900 | NProject::NUi::CProgramItem::[1] vtable 槽 NProject::NUi::CProgramItem::[1]（func_names RTTI 名） |
| 0x141ADD320 | NFactions::NUi::CInviteCountryItem::[21] vtable 槽 NFactions::NUi::CInviteCountryItem::[21]（func_names RTTI 名） |
| 0x141F8C760 | NInternationalMarket::CMarketSellerPanelController::[0] vtable 槽 NInternationalMarket::CMarketSellerPanelController::[0]（func_names RTTI 名） |
| 0x1404936E0 | NProject::CAddScientistTraitEffect::[13] vtable 槽 NProject::CAddScientistTraitEffect::[13]（func_names RTTI 名） |
| 0x141EFADE0 | NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[0] func_names 名 NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[0] |
| 0x14177CBB0 | NEquipmentDesigner::CEquipmentSpriteListItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentSpriteListItem::[0]（func_names RTTI 名） |
| 0x141F33CD0 | NProject::NUi::CProjectHistoryItem::[0] vtable 槽 NProject::NUi::CProjectHistoryItem::[0]（func_names RTTI 名） |
| 0x14015F880 | NFactions::CFactionIconPool::[0] vtable 槽 NFactions::CFactionIconPool::[0]（func_names RTTI 名） |
| 0x141471200 | NProject::NUi::CProjectSimpleRoster::[4] vtable 槽 NProject::NUi::CProjectSimpleRoster::[4]（func_names RTTI 名） |
| 0x14146D390 | NFactions::NUi::CIntelligenceTabSection::[0] vtable 槽 NFactions::NUi::CIntelligenceTabSection::[0]（func_names RTTI 名） |
| 0x1402CD4D0 | NScript::SScriptedKey::[0] vtable 槽 NScript::SScriptedKey::[0]（func_names RTTI 名） |
| 0x14201E8B0 | NCareerProfile::CProfileBackgroundItem::[0] vtable 槽 NCareerProfile::CProfileBackgroundItem::[0]（func_names RTTI 名） |
| 0x140A2D9A0 | NFactions::CFactionRuleGroup::[4] vtable 槽 NFactions::CFactionRuleGroup::[4]（func_names RTTI 名） |
| 0x141E8BE90 | NRaids::NUi::CEnemyRaidMapIconData::[5] vtable 槽 NRaids::NUi::CEnemyRaidMapIconData::[5]（func_names RTTI 名） |
| 0x140160540 | NProject::CPrototypeRewardOption::[0] vtable 槽 NProject::CPrototypeRewardOption::[0]（func_names RTTI 名） |
| 0x142029300 | NIndustrialOrganisation::CTraitTreeItem::[3] vtable 槽 NIndustrialOrganisation::CTraitTreeItem::[3]（func_names RTTI 名） |
| 0x141BF9280 | NFactions::NUi::CFactionCommanderWindow::[6] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[6]（func_names RTTI 名） |
| 0x141CEDBD0 | NAirSelectionUI::CStrategicPriorityItem::[0] vtable 槽 NAirSelectionUI::CStrategicPriorityItem::[0]（func_names RTTI 名） |
| 0x141FDB0F0 | NAirSelectionUI::CAirWingOptionButton::[0] vtable 槽 NAirSelectionUI::CAirWingOptionButton::[0]（func_names RTTI 名） |
| 0x141C22560 | NProject::NUi::CScientistRoster::[9] vtable 槽 NProject::NUi::CScientistRoster::[9]（func_names RTTI 名） |
| 0x141EEE060 | NProject::NUi::CPreviewState::[1] vtable 槽 NProject::NUi::CPreviewState::[1]（func_names RTTI 名） |
| 0x1420533B0 | NInternationalMarket::CEditMarketStockpileWindow::[12] vtable 槽 NInternationalMarket::CEditMarketStockpileWindow::[12]（func_names RTTI 名） |
| 0x141B373C0 | NRaids::NUi::CRaidTypeIconItem::[0] vtable 槽 NRaids::NUi::CRaidTypeIconItem::[0]（func_names RTTI 名） |
| 0x141EEA670 | NProject::NUi::CProjectItem::[0] vtable 槽 NProject::NUi::CProjectItem::[0]（func_names RTTI 名） |
| 0x1406AD120 | NCareerProfile::CProfilePictureDatabase::[1] vtable 槽 NCareerProfile::CProfilePictureDatabase::[1]（func_names RTTI 名） |
| 0x141C19790 | NFactions::NUi::CFactionProgramItem::[27] vtable 槽 NFactions::NUi::CFactionProgramItem::[27]（func_names RTTI 名） |
| 0x141CECBB0 | NAirSelectionUI::CAirWingsByBaseView::[0] vtable 槽 NAirSelectionUI::CAirWingsByBaseView::[0]（func_names RTTI 名） |
| 0x14146CF10 | NFactions::NUi::CFactionCountrySection::[0] vtable 槽 NFactions::NUi::CFactionCountrySection::[0]（func_names RTTI 名） |
| 0x14015F0C0 | NIndustrialOrganisation::CAiBonusWeightDatabase::[1] vtable 槽 NIndustrialOrganisation::CAiBonusWeightDatabase::[1]（func_names RTTI 名） |
| 0x1401602E0 | NIndustrialOrganisation::CPolicyDatabase::[1] vtable 槽 NIndustrialOrganisation::CPolicyDatabase::[1]（func_names RTTI 名） |
| 0x140A51CE0 | NIndustrialOrganisation::COrganisationTemplate::[0] vtable 槽 NIndustrialOrganisation::COrganisationTemplate::[0]（func_names RTTI 名） |
| 0x1417B9B90 | NInternationalMarket::CCountryInternationalMarketView::[6] vtable 槽 NInternationalMarket::CCountryInternationalMarketView::[6]（func_names RTTI 名） |
| 0x14016A970 | NIndustrialOrganisation::COrganisationDatabase::[6] vtable 槽 NIndustrialOrganisation::COrganisationDatabase::[6]（func_names RTTI 名） |
| 0x1418EB740 | NRaids::NUi::CRaidMapIcon::[4] vtable 槽 NRaids::NUi::CRaidMapIcon::[4]（func_names RTTI 名） |
| 0x141823420 | NFactions::NUi::CLegacyCreateFactionWindow::[5] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[5]（func_names RTTI 名） |
| 0x141783A80 | NEquipmentDesigner::CEquipmentSpriteListItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentSpriteListItem::[0]（func_names RTTI 名） |
| 0x141F60430 | NAirSelectionUI::CCloseViewOption::[3] vtable 槽 NAirSelectionUI::CCloseViewOption::[3]（func_names RTTI 名） |
| 0x1402F95F0 | NIndustrialOrganisation::CShowIndustrialOrgTooltip::[0] vtable 槽 NIndustrialOrganisation::CShowIndustrialOrgTooltip::[0]（func_names RTTI 名） |
| 0x14052B420 | NDoctrines::CAddMasteryEffect::[5] vtable 槽 NDoctrines::CAddMasteryEffect::[5]（func_names RTTI 名） |
| 0x140493660 | NProject::CAddScientistLevelEffect::[13] vtable 槽 NProject::CAddScientistLevelEffect::[13]（func_names RTTI 名） |
| 0x14177CB40 | NEquipmentDesigner::CEquipmentNameGroupItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentNameGroupItem::[0]（func_names RTTI 名） |
| 0x14204FB50 | NInternationalMarket::SCivAssignment::[0] vtable 槽 NInternationalMarket::SCivAssignment::[0]（func_names RTTI 名） |
| 0x1402F9540 | NIndustrialOrganisation::CAddAttachPolicyCostEffect::[0] vtable 槽 NIndustrialOrganisation::CAddAttachPolicyCostEffect::[0]（func_names RTTI 名） |
| 0x140456380 | NIndustrialOrganisation::CHasIndustrialOrganisationTrigger::[0] vtable 槽 NIndustrialOrganisation::CHasIndustrialOrganisationTrigger::[0]（func_names RTTI 名） |
| 0x140D7D8F0 | NDoctrines::CTrackStatus::[0] vtable 槽 NDoctrines::CTrackStatus::[0]（func_names RTTI 名） |
| 0x14015EE30 | NProject::CSpecializationDatabase::[1] vtable 槽 NProject::CSpecializationDatabase::[1]（func_names RTTI 名） |
| 0x141ADB730 | NFactions::NUi::CKickFromFactionCountryItem::[0] vtable 槽 NFactions::NUi::CKickFromFactionCountryItem::[0]（func_names RTTI 名） |
| 0x140D7D7F0 | NDoctrines::CDoctrineSystem::[0] vtable 槽 NDoctrines::CDoctrineSystem::[0]（func_names RTTI 名） |
| 0x1417BA140 | NInternationalMarket::CCountryInternationalMarketView::[9] vtable 槽 NInternationalMarket::CCountryInternationalMarketView::[9]（func_names RTTI 名） |
| 0x14194F910 | NFactions::CFactionTheaterManager::[0] vtable 槽 NFactions::CFactionTheaterManager::[0]（func_names RTTI 名） |
| 0x141F0CB50 | NProject::NUi::CProgramItem::[0] vtable 槽 NProject::NUi::CProgramItem::[0]（func_names RTTI 名） |
| 0x141F60CE0 | NAirSelectionUI::CHoldWingsOption::[1] vtable 槽 NAirSelectionUI::CHoldWingsOption::[1]（func_names RTTI 名） |
| 0x140628930 | NIndustrialOrganisation::CAiBonusWeightList::[0] vtable 槽 NIndustrialOrganisation::CAiBonusWeightList::[0]（func_names RTTI 名） |
| 0x141983020 | NWarScoreDistributionHelper::CFactionInfluenceRedistributer::[2] vtable 槽 NWarScoreDistributionHelper::CFactionInfluenceRedistributer::[2]（func_names RTTI 名） |
| 0x141E8AEF0 | NRaids::NUi::CRaidUnitMapIconData::[0] vtable 槽 NRaids::NUi::CRaidUnitMapIconData::[0]（func_names RTTI 名） |
| 0x141CF6D10 | NAirSelectionUI::CAirWingsToolbarController::[0] vtable 槽 NAirSelectionUI::CAirWingsToolbarController::[0]（func_names RTTI 名） |
| 0x14200FB00 | NAiNavalGoals::CCoastDefenseObjective::[3] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[3]（func_names RTTI 名） |
| 0x141F0A0D0 | NFactions::NUi::CFactionMemberUpgradeItem::[1] vtable 槽 NFactions::NUi::CFactionMemberUpgradeItem::[1]（func_names RTTI 名） |
| 0x141F62CC0 | NAirSelectionUI::CSelectAllOption::[1] vtable 槽 NAirSelectionUI::CSelectAllOption::[1]（func_names RTTI 名） |
| 0x1407206B0 | NCountry::CMetadataDatabase::[1] vtable 槽 NCountry::CMetadataDatabase::[1]（func_names RTTI 名） |
| 0x141B2CEC0 | NRaids::NUi::CRaidInstanceView::[7] vtable 槽 NRaids::NUi::CRaidInstanceView::[7]（func_names RTTI 名） |
| 0x142011220 | NAiNavalGoals::CInvasionDefenseObjective::[0] vtable 槽 NAiNavalGoals::CInvasionDefenseObjective::[0]（func_names RTTI 名） |
| 0x1404563F0 | NIndustrialOrganisation::CHasPolicyTrigger::[0] vtable 槽 NIndustrialOrganisation::CHasPolicyTrigger::[0]（func_names RTTI 名） |
| 0x141F63C90 | NAirSelectionUI::CWingsCountWidget::[1] vtable 槽 NAirSelectionUI::CWingsCountWidget::[1]（func_names RTTI 名） |
| 0x142048070 | NInternationalMarket::NPrivate::CTotalIcon::[0] vtable 槽 NInternationalMarket::NPrivate::CTotalIcon::[0]（func_names RTTI 名） |
| 0x1409CAED0 | NDLC::CMetadataDatabase::[1] vtable 槽 NDLC::CMetadataDatabase::[1]（func_names RTTI 名） |
| 0x1420253C0 | NIndustrialOrganisation::CUpgradeVariantPopup::[16] vtable 槽 NIndustrialOrganisation::CUpgradeVariantPopup::[16]（func_names RTTI 名） |
| 0x141A04ED0 | NProject::CProgramConsumer::[0] vtable 槽 NProject::CProgramConsumer::[0]（func_names RTTI 名） |
| 0x141F8A720 | NInternationalMarket::CMarketBuyerPanelController::[0] vtable 槽 NInternationalMarket::CMarketBuyerPanelController::[0]（func_names RTTI 名） |
| 0x142024210 | NIndustrialOrganisation::CUpgradeVariantPopup::[0] vtable 槽 NIndustrialOrganisation::CUpgradeVariantPopup::[0]（func_names RTTI 名） |
| 0x141F62C70 | NAirSelectionUI::CSelectAllOption::[3] vtable 槽 NAirSelectionUI::CSelectAllOption::[3]（func_names RTTI 名） |
| 0x1402F96D0 | NIndustrialOrganisation::CUnlockPolicyTooltipEffect::[0] vtable 槽 NIndustrialOrganisation::CUnlockPolicyTooltipEffect::[0]（func_names RTTI 名） |
| 0x140331C00 | NScript::NMath::CExpression::[0] vtable 槽 NScript::NMath::CExpression::[0]（func_names RTTI 名） |
| 0x140456460 | NIndustrialOrganisation::CHasTraitTrigger::[0] vtable 槽 NIndustrialOrganisation::CHasTraitTrigger::[0]（func_names RTTI 名） |
| 0x141FD70E0 | NAirSelectionUI::CRocketWingsSelectionItem::[12] vtable 槽 NAirSelectionUI::CRocketWingsSelectionItem::[12]（func_names RTTI 名） |
| 0x141CCBC00 | NCareerProfile::CFrontendCareerProfileView::[0] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[0]（func_names RTTI 名） |
| 0x141AA6650 | NInternationalMarket::CRequestEquipmentPurchaseAction::[23] vtable 槽 NInternationalMarket::CRequestEquipmentPurchaseAction::[23]（func_names RTTI 名） |
| 0x141613A60 | NFactions::CAssumeFactionLeadershipAction::[23] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[23]（func_names RTTI 名） |
| 0x141FC0940 | NIndustrialOrganisation::CTraitTree::[12] vtable 槽 NIndustrialOrganisation::CTraitTree::[12]（func_names RTTI 名） |
| 0x141BE6250 | NFactions::CTechnologySharingFaction::[18] vtable 槽 NFactions::CTechnologySharingFaction::[18]（func_names RTTI 名） |
| 0x141C22130 | NProject::NUi::CScientistRoster::[5] vtable 槽 NProject::NUi::CScientistRoster::[5]（func_names RTTI 名） |
| 0x141F352E0 | NDoctrines::CTrackItem::[0] vtable 槽 NDoctrines::CTrackItem::[0]（func_names RTTI 名） |
| 0x1419525F0 | NOperativeMissions::CBoostIdeology::[0] vtable 槽 NOperativeMissions::CBoostIdeology::[0]（func_names RTTI 名） |
| 0x141613CF0 | NFactions::COfferJoinFactionAction::[23] vtable 槽 NFactions::COfferJoinFactionAction::[23]（func_names RTTI 名） |
| 0x141FF2660 | NInternationalMarket::CMarketPanelController::[0] vtable 槽 NInternationalMarket::CMarketPanelController::[0]（func_names RTTI 名） |
| 0x141613B30 | NFactions::CDismantleFactionAction::[23] vtable 槽 NFactions::CDismantleFactionAction::[23]（func_names RTTI 名） |
| 0x141613C10 | NFactions::CKickFromFactionAction::[23] vtable 槽 NFactions::CKickFromFactionAction::[23]（func_names RTTI 名） |
| 0x140A946E0 | NProject::CProjectTemplate::[3] vtable 槽 NProject::CProjectTemplate::[3]（func_names RTTI 名） |
| 0x141796CE0 | NFactions::NUi::CFactionPingCountryItem::[0] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[0]（func_names RTTI 名） |
| 0x141613AD0 | NFactions::CCreateFactionAction::[23] vtable 槽 NFactions::CCreateFactionAction::[23]（func_names RTTI 名） |
| 0x141C19720 | NFactions::NUi::CFactionProgramItemEmpty::[0] vtable 槽 NFactions::NUi::CFactionProgramItemEmpty::[0]（func_names RTTI 名） |
| 0x141C225D0 | NProject::NUi::CScientistRoster::[7] vtable 槽 NProject::NUi::CScientistRoster::[7]（func_names RTTI 名） |
| 0x141F0A080 | NFactions::NUi::CFactionMemberUpgradeButton::[0] vtable 槽 NFactions::NUi::CFactionMemberUpgradeButton::[0]（func_names RTTI 名） |
| 0x141613C80 | NFactions::CLeaveFactionAction::[23] vtable 槽 NFactions::CLeaveFactionAction::[23]（func_names RTTI 名） |
| 0x141613BA0 | NFactions::CJoinFactionAction::[23] vtable 槽 NFactions::CJoinFactionAction::[23]（func_names RTTI 名） |
| 0x141822D20 | NFactions::NUi::CLegacyCreateFactionWindow::[0] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[0]（func_names RTTI 名） |
| 0x141E2F240 | NFactions::NUi::CFactionColorPickerWindow::[5] vtable 槽 NFactions::NUi::CFactionColorPickerWindow::[5]（func_names RTTI 名） |
| 0x141F11F70 | NFactions::NUi::CChangeGoalItem::[0] vtable 槽 NFactions::NUi::CChangeGoalItem::[0]（func_names RTTI 名） |
| 0x141B3A8A0 | NRaids::NUi::CRaidList::[5] vtable 槽 NRaids::NUi::CRaidList::[5]（func_names RTTI 名） |
| 0x1420128E0 | NAiNavalGoals::CMineSweepingObjective::[1] vtable 槽 NAiNavalGoals::CMineSweepingObjective::[1]（func_names RTTI 名） |
| 0x1406143E0 | NAcclimatization::CData::[0] vtable 槽 NAcclimatization::CData::[0]（func_names RTTI 名） |
| 0x140D894D0 | NFactions::CFactionProgramStatus::[0] vtable 槽 NFactions::CFactionProgramStatus::[0]（func_names RTTI 名） |
| 0x141996940 | NCareerProfile::CProfileBadgeUpdateListener::[1] vtable 槽 NCareerProfile::CProfileBadgeUpdateListener::[1]（func_names RTTI 名） |
| 0x141ECFFB0 | NAiNavalGoals::CObjective::[0] vtable 槽 NAiNavalGoals::CObjective::[0]（func_names RTTI 名） |
| 0x14200FD60 | NAiNavalGoals::CTrainingObjective::[0] vtable 槽 NAiNavalGoals::CTrainingObjective::[0]（func_names RTTI 名） |
| 0x1420133F0 | NAiNavalGoals::CNavalDominanceObjective::[0] vtable 槽 NAiNavalGoals::CNavalDominanceObjective::[0]（func_names RTTI 名） |
| 0x141F614D0 | NAirSelectionUI::CReinforcementPreferenceOption::[1] vtable 槽 NAirSelectionUI::CReinforcementPreferenceOption::[1]（func_names RTTI 名） |
| 0x140A9E310 | NRaids::CRaidType::[5] vtable 槽 NRaids::CRaidType::[5]（func_names RTTI 名） |
| 0x141F5F8D0 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[12] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[12]（func_n… |
| 0x14202D690 | NAirWingReorganizationUI::CAirWingReorganizationWindow::[8] vtable 槽 NAirWingReorganizationUI::CAirWingReorganizationWindow::[8]（func_names RTTI 名） |
| 0x141955C60 | NOperativeMissions::CControlTrade::[0] vtable 槽 NOperativeMissions::CControlTrade::[0]（func_names RTTI 名） |
| 0x142044BB0 | NInternationalMarket::CPurchaseDraftItem::[0] vtable 槽 NInternationalMarket::CPurchaseDraftItem::[0]（func_names RTTI 名） |
| 0x142011D90 | NAiNavalGoals::CInvasionDefenseObjective::[1] vtable 槽 NAiNavalGoals::CInvasionDefenseObjective::[1]（func_names RTTI 名） |
| 0x1418EB7B0 | NRaids::NUi::CRaidMapIcon::[2] vtable 槽 NRaids::NUi::CRaidMapIcon::[2]（func_names RTTI 名） |
| 0x14203D340 | NInternationalMarket::CSubsidyOverview::CListController::[2] vtable 槽 NInternationalMarket::CSubsidyOverview::CListController::[2]（func_names RTTI 名） |
| 0x140177790 | NFactions::CFactionUpgrade::[14] vtable 槽 NFactions::CFactionUpgrade::[14]（func_names RTTI 名） |
| 0x14146CE90 | NFactions::NUi::CFactionArmySection::[0] vtable 槽 NFactions::NUi::CFactionArmySection::[0]（func_names RTTI 名） |
| 0x141C0C990 | NFactions::NUi::CChangeRuleWindow::[5] vtable 槽 NFactions::NUi::CChangeRuleWindow::[5]（func_names RTTI 名） |
| 0x140A2C5F0 | NFactions::CFactionMemberUpgradeGroup::[11] vtable 槽 NFactions::CFactionMemberUpgradeGroup::[11]（func_names RTTI 名） |
| 0x14163AC70 | NDoctrines::CCountryDoctrineView::[0] vtable 槽 NDoctrines::CCountryDoctrineView::[0]（func_names RTTI 名） |
| 0x141EEE820 | NProject::NUi::CProgramOngoingProjectView::[8] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[8]（func_names RTTI 名） |
| 0x141E2F030 | NFactions::NUi::CFactionColorPickerWindow::[0] vtable 槽 NFactions::NUi::CFactionColorPickerWindow::[0]（func_names RTTI 名） |
| 0x140A91EF0 | NProject::SOutput::[3] vtable 槽 NProject::SOutput::[3]（func_names RTTI 名） |
| 0x141E75970 | NFactions::NUi::CFactionButton::[1] vtable 槽 NFactions::NUi::CFactionButton::[1]（func_names RTTI 名） |
| 0x141FC0F00 | NIndustrialOrganisation::COrganisationTreeWindow::[0] vtable 槽 NIndustrialOrganisation::COrganisationTreeWindow::[0]（func_names RTTI 名） |
| 0x141797050 | NFactions::NUi::CFactionTheaterWindow::[5] vtable 槽 NFactions::NUi::CFactionTheaterWindow::[5]（func_names RTTI 名） |
| 0x142028AE0 | NIndustrialOrganisation::CTraitTreeItem::[5] vtable 槽 NIndustrialOrganisation::CTraitTreeItem::[5]（func_names RTTI 名） |
| 0x142059810 | NInternationalMarket::CAddToMarketEquipmentItem::[23] vtable 槽 NInternationalMarket::CAddToMarketEquipmentItem::[23]（func_names RTTI 名） |
| 0x142022070 | NIndustrialOrganisation::CDeleteQueuePopUp::[16] vtable 槽 NIndustrialOrganisation::CDeleteQueuePopUp::[16]（func_names RTTI 名） |
| 0x140A53B90 | NIndustrialOrganisation::COrganisationTemplate::[3] vtable 槽 NIndustrialOrganisation::COrganisationTemplate::[3]（func_names RTTI 名） |
| 0x1419D6110 | NInternationalMarket::CPurchaseRequest::[0] vtable 槽 NInternationalMarket::CPurchaseRequest::[0]（func_names RTTI 名） |
| 0x140A4BDD0 | NIndustrialOrganisation::CPolicyTemplate::[3] vtable 槽 NIndustrialOrganisation::CPolicyTemplate::[3]（func_names RTTI 名） |
| 0x141AA5280 | NInternationalMarket::CRequestEquipmentPurchaseAction::[0] vtable 槽 NInternationalMarket::CRequestEquipmentPurchaseAction::[0]（func_names RTTI 名） |
| 0x141C22AE0 | NFactions::NUi::CFactionScientistRoster::[7] vtable 槽 NFactions::NUi::CFactionScientistRoster::[7]（func_names RTTI 名） |
| 0x141ADB680 | NFactions::NUi::CInviteCountriesWindow::[0] vtable 槽 NFactions::NUi::CInviteCountriesWindow::[0]（func_names RTTI 名） |
| 0x141ADB5F0 | NFactions::NUi::CFactionCountryItem::[0] vtable 槽 NFactions::NUi::CFactionCountryItem::[0]（func_names RTTI 名） |
| 0x141C1CBC0 | NFactions::NUi::CResearchFacilityItem::[0] vtable 槽 NFactions::NUi::CResearchFacilityItem::[0]（func_names RTTI 名） |
| 0x141CB0600 | NProject::NUi::CFacilitiesTabView::[12] vtable 槽 NProject::NUi::CFacilitiesTabView::[12]（func_names RTTI 名） |
| 0x141EEE120 | NProject::NUi::CStartedResearchState::[1] vtable 槽 NProject::NUi::CStartedResearchState::[1]（func_names RTTI 名） |
| 0x140A539F0 | NIndustrialOrganisation::COrganisationDatabase::[3] vtable 槽 NIndustrialOrganisation::COrganisationDatabase::[3]（func_names RTTI 名） |
| 0x141F16870 | NFactions::NUi::CFactionMemberScientistItem::[0] vtable 槽 NFactions::NUi::CFactionMemberScientistItem::[0]（func_names RTTI 名） |
| 0x142069E50 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[6] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[6]（func_names RTTI 名） |
| 0x141CB3200 | NProject::NUi::CFacilitiesTabView::[6] vtable 槽 NProject::NUi::CFacilitiesTabView::[6]（func_names RTTI 名） |
| 0x142069DF0 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[2] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[2]（func_names RTTI 名） |
| 0x142069E30 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[3] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[3]（func_names RTTI 名） |
| 0x142069E10 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[4] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[4]（func_names RTTI 名） |
| 0x141E87680 | NRaids::NUi::CActiveRaidMapIconData::[5] vtable 槽 NRaids::NUi::CActiveRaidMapIconData::[5]（func_names RTTI 名） |
| 0x1404A3FE0 | NRaids::CDamageRaidUnitEffect::[0] vtable 槽 NRaids::CDamageRaidUnitEffect::[0]（func_names RTTI 名） |
| 0x141F617F0 | NAirSelectionUI::CHoldWingsOption::[3] vtable 槽 NAirSelectionUI::CHoldWingsOption::[3]（func_names RTTI 名） |
| 0x141FA3A30 | NProject::NUi::CProjectOutputRewardWindow::[8] vtable 槽 NProject::NUi::CProjectOutputRewardWindow::[8]（func_names RTTI 名） |
| 0x141B37280 | NRaids::NUi::CRaidInstanceItem::[0] vtable 槽 NRaids::NUi::CRaidInstanceItem::[0]（func_names RTTI 名） |
| 0x141B37440 | NRaids::NUi::CRaidUnitItem::[0] vtable 槽 NRaids::NUi::CRaidUnitItem::[0]（func_names RTTI 名） |
| 0x142060890 | NAirWingReorganizationUI::NInternal::CManpowerListItem::[0] vtable 槽 NAirWingReorganizationUI::NInternal::CManpowerListItem::[0]（func_names RTTI 名） |
| 0x1420608F0 | NAirWingReorganizationUI::NInternal::CManpowerListItem::[0] vtable 槽 NAirWingReorganizationUI::NInternal::CManpowerListItem::[0]（func_names RTTI 名） |
| 0x141B37BB0 | NRaids::NUi::CRaidInstanceItem::[0] vtable 槽 NRaids::NUi::CRaidInstanceItem::[0]（func_names RTTI 名） |
| 0x140303040 | NInternationalMarket::CCreatePurchaseContractEffect::[0] vtable 槽 NInternationalMarket::CCreatePurchaseContractEffect::[0]（func_names RTTI 名） |
| 0x140492620 | NProject::CCompleteProjectEffect::[0] vtable 槽 NProject::CCompleteProjectEffect::[0]（func_names RTTI 名） |
| 0x1417A0DE0 | NFactions::NUi::CFactionUiManager::[1] vtable 槽 NFactions::NUi::CFactionUiManager::[1]（func_names RTTI 名） |
| 0x14163AE00 | NDoctrines::CCountryDoctrineView::[7] vtable 槽 NDoctrines::CCountryDoctrineView::[7]（func_names RTTI 名） |
| 0x14204CA10 | NInternationalMarket::CPurchaseContractEntry::[0] vtable 槽 NInternationalMarket::CPurchaseContractEntry::[0]（func_names RTTI 名） |
| 0x1417B9BE0 | NInternationalMarket::CCountryInternationalMarketView::[7] vtable 槽 NInternationalMarket::CCountryInternationalMarketView::[7]（func_names RTTI 名） |
| 0x14146D4B0 | NFactions::NUi::CRequestManpowerWindow::[0] vtable 槽 NFactions::NUi::CRequestManpowerWindow::[0]（func_names RTTI 名） |
| 0x141822DD0 | NFactions::NUi::CNewFactionWindow::[0] vtable 槽 NFactions::NUi::CNewFactionWindow::[0]（func_names RTTI 名） |
| 0x141956FE0 | NOperativeMissions::CCounterIntelligence::[0] vtable 槽 NOperativeMissions::CCounterIntelligence::[0]（func_names RTTI 名） |
| 0x1419588D0 | NOperativeMissions::CDiplomaticPressure::[0] vtable 槽 NOperativeMissions::CDiplomaticPressure::[0]（func_names RTTI 名） |
| 0x141F394F0 | NDoctrines::CDoctrineSelectionList::[1] vtable 槽 NDoctrines::CDoctrineSelectionList::[1]（func_names RTTI 名） |
| 0x141954400 | NOperativeMissions::CBuildIntelNetwork::[0] vtable 槽 NOperativeMissions::CBuildIntelNetwork::[0]（func_names RTTI 名） |
| 0x14179F7F0 | NFactions::NUi::CFactionTheaterSwitch::[0] vtable 槽 NFactions::NUi::CFactionTheaterSwitch::[0]（func_names RTTI 名） |
| 0x141FD9E50 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[0] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[0]（func_names… |
| 0x14201FBE0 | NCareerProfile::CCareerProfileSimpleDropdownItem::[0] vtable 槽 NCareerProfile::CCareerProfileSimpleDropdownItem::[0]（func_names RTTI 名） |
| 0x141BFB9C0 | NFactions::NUi::CDoctrineSharingFolderItem::[0] vtable 槽 NFactions::NUi::CDoctrineSharingFolderItem::[0]（func_names RTTI 名） |
| 0x141FBB5B0 | NIndustrialOrganisation::CEquipmentTypeHeaderItem::[12] vtable 槽 NIndustrialOrganisation::CEquipmentTypeHeaderItem::[12]（func_names RTTI 名） |
| 0x142006400 | NInternationalMarket::CMarketAccessOverviewItem::[0] vtable 槽 NInternationalMarket::CMarketAccessOverviewItem::[0]（func_names RTTI 名） |
| 0x140FC2780 | NOperativeMissions::CNoMission::[20] vtable 槽 NOperativeMissions::CNoMission::[20]（func_names RTTI 名） |
| 0x1419DECD0 | NOperativeMissions::CPropaganda::[0] vtable 槽 NOperativeMissions::CPropaganda::[0]（func_names RTTI 名） |
| 0x141F63C50 | NAirSelectionUI::CWingsCountWidget::[2] vtable 槽 NAirSelectionUI::CWingsCountWidget::[2]（func_names RTTI 名） |
| 0x140492510 | NProject::CAddBreakthroughPoints::[0] vtable 槽 NProject::CAddBreakthroughPoints::[0]（func_names RTTI 名） |
| 0x140628F20 | NIndustrialOrganisation::CAiBonusWeightDatabase::[0] vtable 槽 NIndustrialOrganisation::CAiBonusWeightDatabase::[0]（func_names RTTI 名） |
| 0x140493FB0 | NProject::CCompletePrototypeReward::[13] vtable 槽 NProject::CCompletePrototypeReward::[13]（func_names RTTI 名） |
| 0x1409E6C80 | NDoctrines::CTrackTemplate::[8] vtable 槽 NDoctrines::CTrackTemplate::[8]（func_names RTTI 名） |
| 0x140A9BA30 | NRaids::CRaidSuccessLevels::[0] vtable 槽 NRaids::CRaidSuccessLevels::[0]（func_names RTTI 名） |
| 0x140303240 | NInternationalMarket::CScriptEquipmentAmountEntry::[0] vtable 槽 NInternationalMarket::CScriptEquipmentAmountEntry::[0]（func_names RTTI 名） |
| 0x141FB7C90 | NIndustrialOrganisation::CQueueToUnlockWindow::[2] vtable 槽 NIndustrialOrganisation::CQueueToUnlockWindow::[2]（func_names RTTI 名） |
| 0x1404981C0 | NProject::CAddScientistXpEffect::[4] vtable 槽 NProject::CAddScientistXpEffect::[4]（func_names RTTI 名） |
| 0x141FA30A0 | NProject::NUi::CProjectOutputRewardWindow::[0] vtable 槽 NProject::NUi::CProjectOutputRewardWindow::[0]（func_names RTTI 名） |
| 0x140DB4690 | NIndustrialOrganisation::SHistoryWithEquipment::[0] vtable 槽 NIndustrialOrganisation::SHistoryWithEquipment::[0]（func_names RTTI 名） |
| 0x14200C6F0 | NInternationalMarket::CCancelSellingContractPopup::[16] vtable 槽 NInternationalMarket::CCancelSellingContractPopup::[16]（func_names RTTI 名） |
| 0x14204FBB0 | NInternationalMarket::SConvoyAssignment::[0] vtable 槽 NInternationalMarket::SConvoyAssignment::[0]（func_names RTTI 名） |
| 0x1404937C0 | NProject::CClearProjectFlagEffect::[13] vtable 槽 NProject::CClearProjectFlagEffect::[13]（func_names RTTI 名） |
| 0x141F602B0 | NAirSelectionUI::CAggressivenessOptionSelections::[1] vtable 槽 NAirSelectionUI::CAggressivenessOptionSelections::[1]（func_names RTTI 名） |
| 0x141F60E20 | NAirSelectionUI::CDayNightCycleOptionSelections::[1] vtable 槽 NAirSelectionUI::CDayNightCycleOptionSelections::[1]（func_names RTTI 名） |
| 0x140CD9310 | NCombatLog::SCombatData::[0] vtable 槽 NCombatLog::SCombatData::[0]（func_names RTTI 名） |
| 0x140498180 | NProject::CAddScientistLevelEffect::[4] vtable 槽 NProject::CAddScientistLevelEffect::[4]（func_names RTTI 名） |
| 0x141FB55B0 | NIndustrialOrganisation::CSavedQueueItem::[0] vtable 槽 NIndustrialOrganisation::CSavedQueueItem::[0]（func_names RTTI 名） |
| 0x141A32860 | NOperativeMissions::CCountryBased::[9] vtable 槽 NOperativeMissions::CCountryBased::[9]（func_names RTTI 名） |
| 0x141ADB6E0 | NFactions::NUi::CInviteCountryItem::[0] vtable 槽 NFactions::NUi::CInviteCountryItem::[0]（func_names RTTI 名） |
| 0x141B37370 | NRaids::NUi::CRaidSourceItem::[0] vtable 槽 NRaids::NUi::CRaidSourceItem::[0]（func_names RTTI 名） |
| 0x141F24200 | NIndustrialOrganisation::COpenRosterButtonForPoliticalScreen::[1] vtable 槽 NIndustrialOrganisation::COpenRosterButtonForPoliticalScreen::[1]（func_names RTTI 名） |
| 0x141F32B80 | NProject::NUi::CProjectSimpleItem::[0] vtable 槽 NProject::NUi::CProjectSimpleItem::[0]（func_names RTTI 名） |
| 0x141F33BC0 | NProject::NUi::CProjectHistoryItem::[0] vtable 槽 NProject::NUi::CProjectHistoryItem::[0]（func_names RTTI 名） |
| 0x141C17890 | NFactions::NUi::CGoalItem::[0] vtable 槽 NFactions::NUi::CGoalItem::[0]（func_names RTTI 名） |
| 0x140FED0A0 | NRaids::CRaidInstance::[4] vtable 槽 NRaids::CRaidInstance::[4]（func_names RTTI 名） |
| 0x141B37230 | NRaids::NUi::CRaidFilterCategoryItem::[0] vtable 槽 NRaids::NUi::CRaidFilterCategoryItem::[0]（func_names RTTI 名） |
| 0x141C1FC30 | NProject::NUi::CSpecializationSortItem::[0] vtable 槽 NProject::NUi::CSpecializationSortItem::[0]（func_names RTTI 名） |
| 0x141C26A00 | NFactions::NUi::CRuleTypeItem::[0] vtable 槽 NFactions::NUi::CRuleTypeItem::[0]（func_names RTTI 名） |
| 0x141CC2790 | NDoctrines::CFolderTabItem::[0] vtable 槽 NDoctrines::CFolderTabItem::[0]（func_names RTTI 名） |
| 0x141F13A00 | NFactions::NUi::CFilterGoalItem::[0] vtable 槽 NFactions::NUi::CFilterGoalItem::[0]（func_names RTTI 名） |
| 0x141F394A0 | NDoctrines::CDoctrineListItem::[0] vtable 槽 NDoctrines::CDoctrineListItem::[0]（func_names RTTI 名） |
| 0x141FB5560 | NIndustrialOrganisation::CQueueItem::[0] vtable 槽 NIndustrialOrganisation::CQueueItem::[0]（func_names RTTI 名） |
| 0x140A23390 | NFactions::CFactionGoal::[1] vtable 槽 NFactions::CFactionGoal::[1]（func_names RTTI 名） |
| 0x1419820A0 | NInternationalMarket::CMarketAccessRightsRelation::[0] vtable 槽 NInternationalMarket::CMarketAccessRightsRelation::[0]（func_names RTTI 名） |
| 0x141C07BC0 | NFactions::NUi::CChangeGoalWindow::[5] vtable 槽 NFactions::NUi::CChangeGoalWindow::[5]（func_names RTTI 名） |
| 0x141E878F0 | NRaids::NUi::CRaidUnitMapIconData::[4] vtable 槽 NRaids::NUi::CRaidUnitMapIconData::[4]（func_names RTTI 名） |
| 0x140A2BEB0 | NFactions::CFactionMemberUpgradeGroup::[12] vtable 槽 NFactions::CFactionMemberUpgradeGroup::[12]（func_names RTTI 名） |
| 0x140456330 | NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[0] vtable 槽 NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[0]（func_names RTTI 名） |
| 0x1401C99D0 | NCareerProfile::SPlaythroughCountryData::[0] vtable 槽 NCareerProfile::SPlaythroughCountryData::[0]（func_names RTTI 名） |
| 0x1418EB790 | NRaids::NUi::CRaidMapIcon::[0] vtable 槽 NRaids::NUi::CRaidMapIcon::[0]（func_names RTTI 名） |
| 0x140A9B9E0 | NRaids::CRaidSuccessFactors::[0] vtable 槽 NRaids::CRaidSuccessFactors::[0]（func_names RTTI 名） |
| 0x141C24150 | NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0]（func_names RTTI 名） |
| 0x14146CCD0 | NFactions::NUi::CConfirmRuleWindow::[0] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[0]（func_names RTTI 名） |
| 0x14146CD70 | NFactions::NUi::CConfirmGoalWindow::[0] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[0]（func_names RTTI 名） |
| 0x140A91420 | NProject::CHasFloatingHarborTrigger::[21] vtable 槽 NProject::CHasFloatingHarborTrigger::[21]（func_names RTTI 名） |
| 0x1419830C0 | NWarScoreDistributionHelper::CTowardsOverlordRedistributer::[2] vtable 槽 NWarScoreDistributionHelper::CTowardsOverlordRedistributer::[2]（func_names RTTI 名） |
| 0x141CEDAD0 | NAirSelectionUI::CMissionToolbarController::[1] vtable 槽 NAirSelectionUI::CMissionToolbarController::[1]（func_names RTTI 名） |
| 0x1409CBE10 | NDoctrines::CFolderTemplate::[8] vtable 槽 NDoctrines::CFolderTemplate::[8]（func_names RTTI 名） |
| 0x141B1B6E0 | NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand::[0] vtable 槽 NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand::[0]（func_nam… |
| 0x1413B23F0 | NInternationalMarket::CRequestMarketAccessRightsAction::[57] vtable 槽 NInternationalMarket::CRequestMarketAccessRightsAction::[57]（func_names RTTI 名） |
| 0x141FFE380 | NInternationalMarket::CPurchaseEquipmentItem::[0] vtable 槽 NInternationalMarket::CPurchaseEquipmentItem::[0]（func_names RTTI 名） |
| 0x14200C6B0 | NInternationalMarket::CEquipmentStockpileEquipmentItem::[0] vtable 槽 NInternationalMarket::CEquipmentStockpileEquipmentItem::[0]（func_names RTTI 名） |
| 0x14129AC10 | NRaids::NUi::CRaidGuiManager::[1] vtable 槽 NRaids::NUi::CRaidGuiManager::[1]（func_names RTTI 名） |
| 0x140177740 | NFactions::CFactionMemberUpgrade::[14] vtable 槽 NFactions::CFactionMemberUpgrade::[14]（func_names RTTI 名） |
| 0x14054AAD0 | CVariables::[0] vtable 槽 CVariables::[0]（func_names RTTI 名） |
| 0x141FCF220 | NAirSelectionUI::SAirMissionItem::[1] vtable 槽 NAirSelectionUI::SAirMissionItem::[1]（func_names RTTI 名） |
| 0x14146D030 | NFactions::NUi::CFactionHeaderSection::[0] vtable 槽 NFactions::NUi::CFactionHeaderSection::[0]（func_names RTTI 名） |
| 0x141C05DA0 | NProject::NUi::CProgramList::[0] vtable 槽 NProject::NUi::CProgramList::[0]（func_names RTTI 名） |
| 0x141EF67B0 | NCareerProfile::CCareerProfileViewUpdateable::[0] vtable 槽 NCareerProfile::CCareerProfileViewUpdateable::[0]（func_names RTTI 名） |
| 0x140D342D0 | NWarScoreDistributionHelper::CDistributionForOneWinner::[0] vtable 槽 NWarScoreDistributionHelper::CDistributionForOneWinner::[0]（func_names RTTI 名） |
| 0x1420691A0 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[1] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[1]（func_names RTTI 名） |
| 0x140CD9140 | NCombatLog::CLoss::[0] vtable 槽 NCombatLog::CLoss::[0]（func_names RTTI 名） |
| 0x140CD9220 | NCombatLog::CManpowerLoss::[0] vtable 槽 NCombatLog::CManpowerLoss::[0]（func_names RTTI 名） |
| 0x14203CC70 | NInternationalMarket::NDetails::CSubsidyListItem::[1] vtable 槽 NInternationalMarket::NDetails::CSubsidyListItem::[1]（func_names RTTI 名） |
| 0x141BF8DD0 | NFactions::NUi::CFactionCommanderWindow::[12] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[12]（func_names RTTI 名） |
| 0x140160360 | NIndustrialOrganisation::CPolicyTemplate::[0] vtable 槽 NIndustrialOrganisation::CPolicyTemplate::[0]（func_names RTTI 名） |
| 0x140A6C990 | NInlayWindowScript::SButton::[0] vtable 槽 NInlayWindowScript::SButton::[0]（func_names RTTI 名） |
| 0x141C5A860 | NFactions::NUi::CFactionListItem::[0] vtable 槽 NFactions::NUi::CFactionListItem::[0]（func_names RTTI 名） |
| 0x141FC2A20 | NDoctrines::CRewardItem::[0] vtable 槽 NDoctrines::CRewardItem::[0]（func_names RTTI 名） |
| 0x142012560 | NAiNavalGoals::CMineLayingObjective::[1] vtable 槽 NAiNavalGoals::CMineLayingObjective::[1]（func_names RTTI 名） |
| 0x142044C50 | NInternationalMarket::NPrivate::CTotalIcon::[0] vtable 槽 NInternationalMarket::NPrivate::CTotalIcon::[0]（func_names RTTI 名） |
| 0x142044C10 | NInternationalMarket::CPurchaseDraftWindow::[0] vtable 槽 NInternationalMarket::CPurchaseDraftWindow::[0]（func_names RTTI 名） |
| 0x140496DA0 | NProject::CEveryScientistEffect::[27] vtable 槽 NProject::CEveryScientistEffect::[27]（func_names RTTI 名） |
| 0x142049DA0 | NInternationalMarket::CPurchaseDraftWindow::[6] vtable 槽 NInternationalMarket::CPurchaseDraftWindow::[6]（func_names RTTI 名） |
| 0x141983090 | NWarScoreDistributionHelper::CSmallScoresRedistributer::[2] vtable 槽 NWarScoreDistributionHelper::CSmallScoresRedistributer::[2]（func_names RTTI 名） |
| 0x140492560 | NProject::CAddScientistXpEffect::[0] vtable 槽 NProject::CAddScientistXpEffect::[0]（func_names RTTI 名） |
| 0x141FDDB00 | NCareerProfile::CMedalItem::[0] vtable 槽 NCareerProfile::CMedalItem::[0]（func_names RTTI 名） |
| 0x141FDE3A0 | NCareerProfile::CRibbonItem::[0] vtable 槽 NCareerProfile::CRibbonItem::[0]（func_names RTTI 名） |
| 0x142049D70 | NInternationalMarket::CPurchaseDraftItem::[22] vtable 槽 NInternationalMarket::CPurchaseDraftItem::[22]（func_names RTTI 名） |
| 0x140A93AD0 | NProject::CProjectTemplate::[0] vtable 槽 NProject::CProjectTemplate::[0]（func_names RTTI 名） |
| 0x141F22810 | NIndustrialOrganisation::COrganisationListItem::[12] vtable 槽 NIndustrialOrganisation::COrganisationListItem::[12]（func_names RTTI 名） |
| 0x140A9B990 | NRaids::CRaidCategory::[0] vtable 槽 NRaids::CRaidCategory::[0]（func_names RTTI 名） |
| 0x140497DA0 | NProject::CInjureScientistEffect::[3] vtable 槽 NProject::CInjureScientistEffect::[3]（func_names RTTI 名） |
| 0x141B29D30 | NRaids::NUi::CRaidFilter::[8] vtable 槽 NRaids::NUi::CRaidFilter::[8]（func_names RTTI 名） |
| 0x141377BF0 | NNotification::CExternallyCompletedFocusNotification::[0] vtable 槽 NNotification::CExternallyCompletedFocusNotification::[0]（func_names RTTI 名） |
| 0x14146D1C0 | NProject::NUi::CScientistRoster::[0] vtable 槽 NProject::NUi::CScientistRoster::[0]（func_names RTTI 名） |
| 0x141ADB630 | NFactions::NUi::CFactionMemberCountriesWindow::[0] vtable 槽 NFactions::NUi::CFactionMemberCountriesWindow::[0]（func_names RTTI 名） |
| 0x140A23370 | NLoc::SEnvironmentLocalizer::[1] vtable 槽 NLoc::SEnvironmentLocalizer::[1]（func_names RTTI 名） |
| 0x14157E2A0 | NFactions::NUi::CFactionListWindow::[0] vtable 槽 NFactions::NUi::CFactionListWindow::[0]（func_names RTTI 名） |
| 0x14043E4B0 | NCareerProfile::CCheckMedal::[0] vtable 槽 NCareerProfile::CCheckMedal::[0]（func_names RTTI 名） |
| 0x141C1CB80 | NProject::NUi::CProjectFilterListItem::[0] vtable 槽 NProject::NUi::CProjectFilterListItem::[0]（func_names RTTI 名） |
| 0x141FE4B70 | NCareerProfile::CCareerProfilePageDot::[0] vtable 槽 NCareerProfile::CCareerProfilePageDot::[0]（func_names RTTI 名） |
| 0x14201DC60 | NCareerProfile::CCountryItem::[0] vtable 槽 NCareerProfile::CCountryItem::[0]（func_names RTTI 名） |
| 0x142013980 | NAiNavalGoals::CTrainingObjective::[6] vtable 槽 NAiNavalGoals::CTrainingObjective::[6]（func_names RTTI 名） |
| 0x141B30B20 | NRaids::NUi::CRaidSetupView::[7] vtable 槽 NRaids::NUi::CRaidSetupView::[7]（func_names RTTI 名） |
| 0x1420128A0 | NAiNavalGoals::CMineSweepingObjective::[6] vtable 槽 NAiNavalGoals::CMineSweepingObjective::[6]（func_names RTTI 名） |
| 0x141C22120 | NProject::NUi::CScientistRoster::[13] vtable 槽 NProject::NUi::CScientistRoster::[13]（func_names RTTI 名） |
| 0x142059A70 | NInternationalMarket::CAddToMarketEquipmentItem::[24] vtable 槽 NInternationalMarket::CAddToMarketEquipmentItem::[24]（func_names RTTI 名） |
| 0x140A2A100 | NFactions::CFactionIconPool::[4] vtable 槽 NFactions::CFactionIconPool::[4]（func_names RTTI 名） |
| 0x1403085E0 | NInternationalMarket::CAnyPurchaseContractTrigger::[25] vtable 槽 NInternationalMarket::CAnyPurchaseContractTrigger::[25]（func_names RTTI 名） |
| 0x141B1C8B0 | NProject::NUi::CProgramView::[1] vtable 槽 NProject::NUi::CProgramView::[1]（func_names RTTI 名） |
| 0x141F0E1C0 | NProject::NUi::CProgramItem::[1] vtable 槽 NProject::NUi::CProgramItem::[1]（func_names RTTI 名） |
| 0x141A328D0 | NOperativeMissions::CNoMission::[17] vtable 槽 NOperativeMissions::CNoMission::[17]（func_names RTTI 名） |
| 0x140A2A2F0 | NFactions::CFactionMemberUpgrade::[12] vtable 槽 NFactions::CFactionMemberUpgrade::[12]（func_names RTTI 名） |
| 0x141EFAE80 | NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[3] func_names 名 NCareerProfile::W4EProfileOwner::8::$$A6AXXZ::V?$function::std:鈥�::[3] |
| 0x14015FE90 | NDoctrines::CMilestoneTemplate::[0] vtable 槽 NDoctrines::CMilestoneTemplate::[0]（func_names RTTI 名） |
| 0x14015FF10 | NScript::CNamedCollection::[0] vtable 槽 NScript::CNamedCollection::[0]（func_names RTTI 名） |
| 0x1402F6390 | NLoc::SScopeLocalizer::[1] vtable 槽 NLoc::SScopeLocalizer::[1]（func_names RTTI 名） |
| 0x1418EB930 | NRaids::NUi::CRaidMapIcon::[8] vtable 槽 NRaids::NUi::CRaidMapIcon::[8]（func_names RTTI 名） |
| 0x14015CB60 | NFactions::NAi::CAiFactionTheaterDatabase::[1] vtable 槽 NFactions::NAi::CAiFactionTheaterDatabase::[1]（func_names RTTI 名） |
| 0x14015F2E0 | NScript::CCollection::[0] vtable 槽 NScript::CCollection::[0]（func_names RTTI 名） |
| 0x140160C10 | NIndustrialOrganisation::CTraitTemplate::[0] vtable 槽 NIndustrialOrganisation::CTraitTemplate::[0]（func_names RTTI 名） |
| 0x140492690 | NProject::CCompletePrototypeReward::[0] vtable 槽 NProject::CCompletePrototypeReward::[0]（func_names RTTI 名） |
| 0x140528F80 | NDoctrines::CAddMasteryEffect::[0] vtable 槽 NDoctrines::CAddMasteryEffect::[0]（func_names RTTI 名） |
| 0x1406AB3F0 | NCareerProfile::CCareerProfileMedal::[0] vtable 槽 NCareerProfile::CCareerProfileMedal::[0]（func_names RTTI 名） |
| 0x140CD93D0 | NCombatLog::CStatsObserver::SCombatSideData::[0] vtable 槽 NCombatLog::CStatsObserver::SCombatSideData::[0]（func_names RTTI 名） |
| 0x140D89490 | NFactions::CFaction::[0] vtable 槽 NFactions::CFaction::[0]（func_names RTTI 名） |
| 0x140FE0A00 | NProject::SProjectHistory::[0] vtable 槽 NProject::SProjectHistory::[0]（func_names RTTI 名） |
| 0x141CF39D0 | NAirSelectionUI::CSelectedAirGroupView::[12] vtable 槽 NAirSelectionUI::CSelectedAirGroupView::[12]（func_names RTTI 名） |
| 0x141F22840 | NIndustrialOrganisation::COrganisationListItem::[12] vtable 槽 NIndustrialOrganisation::COrganisationListItem::[12]（func_names RTTI 名） |
| 0x141F60230 | NAirSelectionUI::CDayNightCycleOptionSelections::[0] vtable 槽 NAirSelectionUI::CDayNightCycleOptionSelections::[0]（func_names RTTI 名） |
| 0x1401C9A20 | NCareerProfile::SProfileData::[0] vtable 槽 NCareerProfile::SProfileData::[0]（func_names RTTI 名） |
| 0x140683530 | NPdxLoc::CFormattedLocalization::[0] vtable 槽 NPdxLoc::CFormattedLocalization::[0]（func_names RTTI 名） |
| 0x140B64420 | NFactions::NUi::CFactionPingView::[0] vtable 槽 NFactions::NUi::CFactionPingView::[0]（func_names RTTI 名） |
| 0x14146DA50 | NFactions::NUi::CAssignTheaterLeaderPopup::[15] vtable 槽 NFactions::NUi::CAssignTheaterLeaderPopup::[15]（func_names RTTI 名） |
| 0x1402F97E0 | NIndustrialOrganisation::CEveryIndustrialOrgEffect::[25] vtable 槽 NIndustrialOrganisation::CEveryIndustrialOrgEffect::[25]（func_names RTTI 名） |
| 0x1404595B0 | NIndustrialOrganisation::CAllIndustrialOrgTrigger::[23] vtable 槽 NIndustrialOrganisation::CAllIndustrialOrgTrigger::[23]（func_names RTTI 名） |
| 0x1404595E0 | NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[23] vtable 槽 NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[23]（func_names RTTI 名） |
| 0x1404A3870 | NProject::CAllActiveScientistsTrigger::[23] vtable 槽 NProject::CAllActiveScientistsTrigger::[23]（func_names RTTI 名） |
| 0x1404A38D0 | NProject::CAnyActiveScientistTrigger::[23] vtable 槽 NProject::CAnyActiveScientistTrigger::[23]（func_names RTTI 名） |
| 0x14146DA20 | NFactions::NUi::CLeaveFactionConfirmationWindow::[16] vtable 槽 NFactions::NUi::CLeaveFactionConfirmationWindow::[16]（func_names RTTI 名） |
| 0x14015F2A0 | NPdxLoc::CBoundLocalization::[0] vtable 槽 NPdxLoc::CBoundLocalization::[0]（func_names RTTI 名） |
| 0x14015FA60 | NDoctrines::CFolderTemplate::[0] vtable 槽 NDoctrines::CFolderTemplate::[0]（func_names RTTI 名） |
| 0x14015FE50 | NDoctrines::CMasteryConditions::[0] vtable 槽 NDoctrines::CMasteryConditions::[0]（func_names RTTI 名） |
| 0x14015FF50 | NProject::CNarrative::[0] vtable 槽 NProject::CNarrative::[0]（func_names RTTI 名） |
| 0x140160500 | NProject::CPrototypeReward::[0] vtable 槽 NProject::CPrototypeReward::[0]（func_names RTTI 名） |
| 0x140160ED0 | NCareerProfile::SGameModeStatistics::[0] vtable 槽 NCareerProfile::SGameModeStatistics::[0]（func_names RTTI 名） |
| 0x140161040 | NProject::SOutput::[0] vtable 槽 NProject::SOutput::[0]（func_names RTTI 名） |
| 0x1404925A0 | NProject::CInjureScientistEffect::[0] vtable 槽 NProject::CInjureScientistEffect::[0]（func_names RTTI 名） |
| 0x140528FC0 | NDoctrines::STemporaryMasteryGain::[0] vtable 槽 NDoctrines::STemporaryMasteryGain::[0]（func_names RTTI 名） |
| 0x140720670 | NCountry::CMetadata::[0] vtable 槽 NCountry::CMetadata::[0]（func_names RTTI 名） |
| 0x140A909D0 | NProject::CHasFloatingHarborTrigger::[0] vtable 槽 NProject::CHasFloatingHarborTrigger::[0]（func_names RTTI 名） |
| 0x14146DB70 | NFactions::NUi::CInviteToFactionPopup::[15] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[15]（func_names RTTI 名） |
| 0x141796F10 | NFactions::NUi::CFactionTheaterWindow::[0] vtable 槽 NFactions::NUi::CFactionTheaterWindow::[0]（func_names RTTI 名） |
| 0x1419AB4D0 | NRaids::NUi::CPlayerStatusCache::[0] vtable 槽 NRaids::NUi::CPlayerStatusCache::[0]（func_names RTTI 名） |
| 0x1419C4050 | NCareerProfile::CBasePopupWindow::[0] vtable 槽 NCareerProfile::CBasePopupWindow::[0]（func_names RTTI 名） |
| 0x141C28C20 | NAirInterfaceUtil::CMissionIconItem::[0] vtable 槽 NAirInterfaceUtil::CMissionIconItem::[0]（func_names RTTI 名） |
| 0x141CEDA50 | NAirSelectionUI::CAirMissionButton::[0] vtable 槽 NAirSelectionUI::CAirMissionButton::[0]（func_names RTTI 名） |
| 0x141CEDA90 | NAirSelectionUI::CAirStrategicTargetButton::[0] vtable 槽 NAirSelectionUI::CAirStrategicTargetButton::[0]（func_names RTTI 名） |
| 0x141EEE0E0 | NProject::NUi::CProgramOngoingProjectView::[0] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[0]（func_names RTTI 名） |
| 0x141EF6770 | NCareerProfile::CCareerProfileView::[1] vtable 槽 NCareerProfile::CCareerProfileView::[1]（func_names RTTI 名） |
| 0x141F1A860 | NIndustrialOrganisation::CPolicyWindow::[0] vtable 槽 NIndustrialOrganisation::CPolicyWindow::[0]（func_names RTTI 名） |
| 0x141FBABA0 | NIndustrialOrganisation::CBonusTypeIconItem::[0] vtable 槽 NIndustrialOrganisation::CBonusTypeIconItem::[0]（func_names RTTI 名） |
| 0x141FFB810 | NInternationalMarket::CPurchaseEquipmentItem::[0] vtable 槽 NInternationalMarket::CPurchaseEquipmentItem::[0]（func_names RTTI 名） |
| 0x14146DAB0 | NFactions::NUi::CDismantleFactionConfirmationWindow::[15] vtable 槽 NFactions::NUi::CDismantleFactionConfirmationWindow::[15]（func_names RTTI 名） |
| 0x14146DBA0 | NFactions::NUi::CKickFromFactionPopup::[15] vtable 槽 NFactions::NUi::CKickFromFactionPopup::[15]（func_names RTTI 名） |
| 0x141C07D90 | NFactions::NUi::CChangeGoalWindow::[8] vtable 槽 NFactions::NUi::CChangeGoalWindow::[8]（func_names RTTI 名） |
| 0x141F22880 | NIndustrialOrganisation::COrganisationListItem::[2] vtable 槽 NIndustrialOrganisation::COrganisationListItem::[2]（func_names RTTI 名） |
| 0x141F382C0 | NDoctrines::NImpl::CSubDoctrineInfoPolicy::[1] vtable 槽 NDoctrines::NImpl::CSubDoctrineInfoPolicy::[1]（func_names RTTI 名） |
| 0x142047850 | NInternationalMarket::CPurchaseDraftItem::[23] vtable 槽 NInternationalMarket::CPurchaseDraftItem::[23]（func_names RTTI 名） |
| 0x14045AE80 | NInternationalMarket::CAllPurchaseContractTrigger::[23] vtable 槽 NInternationalMarket::CAllPurchaseContractTrigger::[23]（func_names RTTI 名） |
| 0x14045AEB0 | NInternationalMarket::CAnyPurchaseContractTrigger::[23] vtable 槽 NInternationalMarket::CAnyPurchaseContractTrigger::[23]（func_names RTTI 名） |
| 0x140A1EBF0 | NScript::CNamedCollection::[10] vtable 槽 NScript::CNamedCollection::[10]（func_names RTTI 名） |
| 0x14146DAE0 | NFactions::NUi::CDoctrineSharingPopup::[15] vtable 槽 NFactions::NUi::CDoctrineSharingPopup::[15]（func_names RTTI 名） |
| 0x14015CC60 | NFactions::CFactionGoalDatabase::[1] vtable 槽 NFactions::CFactionGoalDatabase::[1]（func_names RTTI 名） |
| 0x14015CCA0 | NFactions::CFactionIconsDatabase::[1] vtable 槽 NFactions::CFactionIconsDatabase::[1]（func_names RTTI 名） |
| 0x14015CCE0 | NFactions::CFactionMemberUpgradeDatabase::[1] vtable 槽 NFactions::CFactionMemberUpgradeDatabase::[1]（func_names RTTI 名） |
| 0x14015CD20 | NFactions::CFactionMemberUpgradeGroupDatabase::[1] vtable 槽 NFactions::CFactionMemberUpgradeGroupDatabase::[1]（func_names RTTI 名） |
| 0x14015CD60 | NFactions::CFactionRuleDatabase::[1] vtable 槽 NFactions::CFactionRuleDatabase::[1]（func_names RTTI 名） |
| 0x14015CDA0 | NFactions::CFactionRuleGroupDatabase::[1] vtable 槽 NFactions::CFactionRuleGroupDatabase::[1]（func_names RTTI 名） |
| 0x14015CDE0 | NFactions::CFactionTemplateDatabase::[1] vtable 槽 NFactions::CFactionTemplateDatabase::[1]（func_names RTTI 名） |
| 0x14015CE60 | NDoctrines::CFolderDatabase::[1] vtable 槽 NDoctrines::CFolderDatabase::[1]（func_names RTTI 名） |
| 0x14015CEE0 | NAiNavalGoals::CGoalDatabase::[1] vtable 槽 NAiNavalGoals::CGoalDatabase::[1]（func_names RTTI 名） |
| 0x14015CF20 | NDoctrines::CGrandDoctrineDatabase::[1] vtable 槽 NDoctrines::CGrandDoctrineDatabase::[1]（func_names RTTI 名） |
| 0x14015CFA0 | NProject::CProjectDatabase::[1] vtable 槽 NProject::CProjectDatabase::[1]（func_names RTTI 名） |
| 0x14015CFE0 | NProject::CPrototypeRewardDatabase::[1] vtable 槽 NProject::CPrototypeRewardDatabase::[1]（func_names RTTI 名） |
| 0x14015D0A0 | NDoctrines::CSubDoctrineDatabase::[1] vtable 槽 NDoctrines::CSubDoctrineDatabase::[1]（func_names RTTI 名） |
| 0x14015D0E0 | NDoctrines::CTrackDatabase::[1] vtable 槽 NDoctrines::CTrackDatabase::[1]（func_names RTTI 名） |
| 0x14015F140 | NFactions::NAi::CAiFactionTheater::[0] vtable 槽 NFactions::NAi::CAiFactionTheater::[0]（func_names RTTI 名） |
| 0x14015F480 | NDoctrines::CDoctrineBaseTemplate::[0] vtable 槽 NDoctrines::CDoctrineBaseTemplate::[0]（func_names RTTI 名） |
| 0x14015F840 | NFactions::CFactionGoal::[0] vtable 槽 NFactions::CFactionGoal::[0]（func_names RTTI 名） |
| 0x14015F900 | NFactions::CFactionUpgrade::[0] vtable 槽 NFactions::CFactionUpgrade::[0]（func_names RTTI 名） |
| 0x14015F940 | NFactions::CFactionUpgradeGroup::[0] vtable 槽 NFactions::CFactionUpgradeGroup::[0]（func_names RTTI 名） |
| 0x14015F980 | NFactions::CFactionRule::[0] vtable 槽 NFactions::CFactionRule::[0]（func_names RTTI 名） |
| 0x14015FA20 | NFactions::CFactionTemplate::[0] vtable 槽 NFactions::CFactionTemplate::[0]（func_names RTTI 名） |
| 0x14015FC50 | NDoctrines::CGrandDoctrineTemplate::[0] vtable 槽 NDoctrines::CGrandDoctrineTemplate::[0]（func_names RTTI 名） |
| 0x140160B90 | NDoctrines::CSubDoctrineTemplate::[0] vtable 槽 NDoctrines::CSubDoctrineTemplate::[0]（func_names RTTI 名） |
| 0x140160BD0 | NDoctrines::CTrackTemplate::[0] vtable 槽 NDoctrines::CTrackTemplate::[0]（func_names RTTI 名） |
| 0x14043E700 | NCareerProfile::CVariableTrigger::[0] vtable 槽 NCareerProfile::CVariableTrigger::[0]（func_names RTTI 名） |
| 0x1404925E0 | NProject::CSetProjectFlagEffect::[0] vtable 槽 NProject::CSetProjectFlagEffect::[0]（func_names RTTI 名） |
| 0x1404926D0 | NProject::CEveryScientistEffect::[0] vtable 槽 NProject::CEveryScientistEffect::[0]（func_names RTTI 名） |
| 0x14068F290 | NCareerProfile::SCareerProfileIntermediateStatistics::[0] vtable 槽 NCareerProfile::SCareerProfileIntermediateStatistics::[0]（func_names RTTI 名） |
| 0x14068F2D0 | NCareerProfile::SCareerProfileModDataSet::[0] vtable 槽 NCareerProfile::SCareerProfileModDataSet::[0]（func_names RTTI 名） |
| 0x1406AFC20 | NCareerProfile::CCareerProfileRibbon::[0] vtable 槽 NCareerProfile::CCareerProfileRibbon::[0]（func_names RTTI 名） |
| 0x1409CAE90 | NDLC::CMetadata::[0] vtable 槽 NDLC::CMetadata::[0]（func_names RTTI 名） |
| 0x140A267D0 | NFactions::CFactionGoalStatus::[0] vtable 槽 NFactions::CFactionGoalStatus::[0]（func_names RTTI 名） |
| 0x140A9BA90 | NRaids::CRaidType::[0] vtable 槽 NRaids::CRaidType::[0]（func_names RTTI 名） |
| 0x140ABAB50 | NProject::CSpecializationTemplate::[0] vtable 槽 NProject::CSpecializationTemplate::[0]（func_names RTTI 名） |
| 0x140CD9260 | NCombatLog::COrdersGroupLogs::[0] vtable 槽 NCombatLog::COrdersGroupLogs::[0]（func_names RTTI 名） |
| 0x140CD92D0 | NCombatLog::CStatsObserver::[0] vtable 槽 NCombatLog::CStatsObserver::[0]（func_names RTTI 名） |
| 0x140DB45B0 | NIndustrialOrganisation::COrganisation::[0] vtable 槽 NIndustrialOrganisation::COrganisation::[0]（func_names RTTI 名） |
| 0x140DF2480 | NInternationalMarket::CEquipmentConvoyClient::[0] vtable 槽 NInternationalMarket::CEquipmentConvoyClient::[0]（func_names RTTI 名） |
| 0x14146CC90 | NFactions::NUi::CAssignResearchFacilityWindow::[0] vtable 槽 NFactions::NUi::CAssignResearchFacilityWindow::[0]（func_names RTTI 名） |
| 0x14146CDC0 | NFactions::NUi::CCountryFactionView::[0] vtable 槽 NFactions::NUi::CCountryFactionView::[0]（func_names RTTI 名） |
| 0x14146CE50 | NFactions::NUi::CDoctrineSharingWindow::[1] vtable 槽 NFactions::NUi::CDoctrineSharingWindow::[1]（func_names RTTI 名） |
| 0x14146D080 | NFactions::NUi::CFactionProgramList::[0] vtable 槽 NFactions::NUi::CFactionProgramList::[0]（func_names RTTI 名） |
| 0x14146D210 | NFactions::NUi::CFactionTabSection::[0] vtable 槽 NFactions::NUi::CFactionTabSection::[0]（func_names RTTI 名） |
| 0x14146DBD0 | NFactions::NUi::CLeaveFactionConfirmationWindow::[15] vtable 槽 NFactions::NUi::CLeaveFactionConfirmationWindow::[15]（func_names RTTI 名） |
| 0x14153D460 | NFriendsHandler::CDownloadProfileRequestSteam::[0] vtable 槽 NFriendsHandler::CDownloadProfileRequestSteam::[0]（func_names RTTI 名） |
| 0x14167DA00 | NRaids::NGfx::CRaidArrow::[0] vtable 槽 NRaids::NGfx::CRaidArrow::[0]（func_names RTTI 名） |
| 0x141796CA0 | NFactions::NUi::CFactionCountryListWindow::[0] vtable 槽 NFactions::NUi::CFactionCountryListWindow::[0]（func_names RTTI 名） |
| 0x14192F3F0 | NNotification::CIdeaExpiredNotification::[0] vtable 槽 NNotification::CIdeaExpiredNotification::[0]（func_names RTTI 名） |
| 0x1419C4090 | NCareerProfile::CMedalPopupWindow::[0] vtable 槽 NCareerProfile::CMedalPopupWindow::[0]（func_names RTTI 名） |
| 0x141BE61F0 | NFactions::CTechnologySharingFaction::[13] vtable 槽 NFactions::CTechnologySharingFaction::[13]（func_names RTTI 名） |
| 0x141C236F0 | NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0]（func_names RTTI 名） |
| 0x141C3B5E0 | NIndustrialOrganisation::COrganisationListWindow::[0] vtable 槽 NIndustrialOrganisation::COrganisationListWindow::[0]（func_names RTTI 名） |
| 0x141CB0270 | NProject::NUi::CProjectHistoryRoster::[0] vtable 槽 NProject::NUi::CProjectHistoryRoster::[0]（func_names RTTI 名） |
| 0x141CB0430 | NProject::NUi::CProjectSimpleRoster::[0] vtable 槽 NProject::NUi::CProjectSimpleRoster::[0]（func_names RTTI 名） |
| 0x141F0CBC0 | NProject::NUi::CProgramItemBase::[0] vtable 槽 NProject::NUi::CProgramItemBase::[0]（func_names RTTI 名） |
| 0x141F1A820 | NIndustrialOrganisation::COrganisationDetailWindow::[0] vtable 槽 NIndustrialOrganisation::COrganisationDetailWindow::[0]（func_names RTTI 名） |
| 0x141F1A8A0 | NIndustrialOrganisation::CQueueToUnlockWindow::[0] vtable 槽 NIndustrialOrganisation::CQueueToUnlockWindow::[0]（func_names RTTI 名） |
| 0x141F5DE50 | NAirSelectionUI::CAirWingsSelectionList::[1] vtable 槽 NAirSelectionUI::CAirWingsSelectionList::[1]（func_names RTTI 名） |
| 0x141F603F0 | NAirSelectionUI::CCloseViewOption::[0] vtable 槽 NAirSelectionUI::CCloseViewOption::[0]（func_names RTTI 名） |
| 0x141F8BCC0 | NInternationalMarket::CMarketOverviewPanelController::[0] vtable 槽 NInternationalMarket::CMarketOverviewPanelController::[0]（func_names RTTI 名） |
| 0x141FBACE0 | NIndustrialOrganisation::CDetailsModifierItem::[0] vtable 槽 NIndustrialOrganisation::CDetailsModifierItem::[0]（func_names RTTI 名） |
| 0x141FFB7D0 | NInternationalMarket::CPurchasableEquipmentWindow::[0] vtable 槽 NInternationalMarket::CPurchasableEquipmentWindow::[0]（func_names RTTI 名） |
| 0x14200C010 | NInternationalMarket::CMarketStockpileWindow::[0] vtable 槽 NInternationalMarket::CMarketStockpileWindow::[0]（func_names RTTI 名） |
| 0x14201B0C0 | NCareerProfile::CMedalDisplaySlot::[0] vtable 槽 NCareerProfile::CMedalDisplaySlot::[0]（func_names RTTI 名） |
| 0x142021730 | NIndustrialOrganisation::CLoadQueuePopUp::[0] vtable 槽 NIndustrialOrganisation::CLoadQueuePopUp::[0]（func_names RTTI 名） |
| 0x142058F00 | NInternationalMarket::CAddEquipmentToMarketWindow::[0] vtable 槽 NInternationalMarket::CAddEquipmentToMarketWindow::[0]（func_names RTTI 名） |
| 0x1404A38A0 | NProject::CAllScientistsTrigger::[23] vtable 槽 NProject::CAllScientistsTrigger::[23]（func_names RTTI 名） |
| 0x1404A3900 | NProject::CAnyScientistTrigger::[23] vtable 槽 NProject::CAnyScientistTrigger::[23]（func_names RTTI 名） |
| 0x141F381C0 | NDoctrines::NImpl::CGrandDoctrineInfoPolicy::[1] vtable 槽 NDoctrines::NImpl::CGrandDoctrineInfoPolicy::[1]（func_names RTTI 名） |
| 0x140FECFB0 | NRaids::CRaidInstance::[3] vtable 槽 NRaids::CRaidInstance::[3]（func_names RTTI 名） |
| 0x141BE61D0 | NFactions::CTechnologySharingFaction::[9] vtable 槽 NFactions::CTechnologySharingFaction::[9]（func_names RTTI 名） |
| 0x140459CF0 | NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[26] vtable 槽 NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[26]（func_names RTTI 名） |
| 0x1409CDEF0 | NDoctrines::CGrandDoctrineTemplate::[14] vtable 槽 NDoctrines::CGrandDoctrineTemplate::[14]（func_names RTTI 名） |
| 0x14146DB10 | NFactions::NUi::CFactionIntelligencePopup::[15] vtable 槽 NFactions::NUi::CFactionIntelligencePopup::[15]（func_names RTTI 名） |
| 0x14146DB40 | NFactions::NUi::CFactionTheaterPopup::[15] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[15]（func_names RTTI 名） |
| 0x141BE6220 | NFactions::CTechnologySharingFaction::[14] vtable 槽 NFactions::CTechnologySharingFaction::[14]（func_names RTTI 名） |
| 0x14146DA80 | NFactions::NUi::CConfirmFactionFacilityProgram::[15] vtable 槽 NFactions::NUi::CConfirmFactionFacilityProgram::[15]（func_names RTTI 名） |
| 0x1417970AC | NFactions::NUi::CFactionPingCountryItem::[0] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[0]（func_names RTTI 名） |
| 0x141C03310 | NFactions::NUi::CFactionPopup::[17] vtable 槽 NFactions::NUi::CFactionPopup::[17]（func_names RTTI 名） |
| 0x141C01DF0 | NFactions::NUi::CConfirmGoalWindow::[15] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[15]（func_names RTTI 名） |
| 0x141FD4B90 | NAirSelectionUI::CGunEmplacementWingsSelectionItem::[12] vtable 槽 NAirSelectionUI::CGunEmplacementWingsSelectionItem::[12]（func_names RTTI 名） |
| 0x141482A40 | NProject::CProjectPool::[8] vtable 槽 NProject::CProjectPool::[8]（func_names RTTI 名） |
| 0x14054A610 | （无名） 体设 CVariables::vftable（RTTI 名） |
| 0x141796C60 | NFactions::NUi::CFactionPingCountryItem::[1] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[1]（func_names RTTI 名） |
| 0x141825540 | NFactions::NUi::CLegacyCreateFactionWindow::[7] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[7]（func_names RTTI 名） |
| 0x140303440 | NInternationalMarket::CRandomPurchaseContractEffect::[25] vtable 槽 NInternationalMarket::CRandomPurchaseContractEffect::[25]（func_names RTTI 名） |
| 0x1413AFF90 | NIndustrialOrganisation::CRandomIndustrialOrgEffect::[28] vtable 槽 NIndustrialOrganisation::CRandomIndustrialOrgEffect::[28]（func_names RTTI 名） |
| 0x14203CACC | NInternationalMarket::CSubsidyOverview::[0] vtable 槽 NInternationalMarket::CSubsidyOverview::[0]（func_names RTTI 名） |
| 0x141CF33E8 | NAirSelectionUI::CSelectedAirGroupView::[1] vtable 槽 NAirSelectionUI::CSelectedAirGroupView::[1]（func_names RTTI 名） |
| 0x141FB0B70 | NIndustrialOrganisation::CPolicyItem::[1] vtable 槽 NIndustrialOrganisation::CPolicyItem::[1]（func_names RTTI 名） |
| 0x141FD62E4 | NAirSelectionUI::CRocketWingsSelectionItem::[1] vtable 槽 NAirSelectionUI::CRocketWingsSelectionItem::[1]（func_names RTTI 名） |
| 0x141BF8C60 | NFactions::NUi::CFactionCommanderWindow::[1] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[1]（func_names RTTI 名） |
| 0x141C17878 | NFactions::NUi::CGoalItem::[1] vtable 槽 NFactions::NUi::CGoalItem::[1]（func_names RTTI 名） |
| 0x141C5A854 | NFactions::NUi::CFactionListItem::[1] vtable 槽 NFactions::NUi::CFactionListItem::[1]（func_names RTTI 名） |
| 0x141CECBA4 | NAirSelectionUI::CAirWingsByBaseView::[0] vtable 槽 NAirSelectionUI::CAirWingsByBaseView::[0]（func_names RTTI 名） |
| 0x141CF33D0 | NAirSelectionUI::CAirWingEntry::[1] vtable 槽 NAirSelectionUI::CAirWingEntry::[1]（func_names RTTI 名） |
| 0x141F0CACC | NProject::NUi::CProgramItem::[0] vtable 槽 NProject::NUi::CProgramItem::[0]（func_names RTTI 名） |
| 0x141FBAB2C | NIndustrialOrganisation::CDetailsInitialTraitItem::[0] vtable 槽 NIndustrialOrganisation::CDetailsInitialTraitItem::[0]（func_names RTTI 名） |
| 0x141FD9E3C | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[1] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[1]（func_names… |
| 0x14205330C | NInternationalMarket::CEditMarketStockpileWindow::[1] vtable 槽 NInternationalMarket::CEditMarketStockpileWindow::[1]（func_names RTTI 名） |
| 0x140160D20 | NCareerProfile::SCareerProfileAwards::[0] vtable 槽 NCareerProfile::SCareerProfileAwards::[0]（func_names RTTI 名） |
| 0x1401C99A0 | NCareerProfile::SCareerProfileCountryData::[0] vtable 槽 NCareerProfile::SCareerProfileCountryData::[0]（func_names RTTI 名） |
| 0x1406AB4F0 | NCareerProfile::CCareerProfileMedal::CTierColors::[0] vtable 槽 NCareerProfile::CCareerProfileMedal::CTierColors::[0]（func_names RTTI 名） |
| 0x140F313F0 | NRaids::CRaidTargetCooldownStatus::[0] vtable 槽 NRaids::CRaidTargetCooldownStatus::[0]（func_names RTTI 名） |
| 0x14200634C | NInternationalMarket::CCancelMarketAccessPoup::[1] vtable 槽 NInternationalMarket::CCancelMarketAccessPoup::[1]（func_names RTTI 名） |
| 0x141FBAB50 | NIndustrialOrganisation::CDetailsModifierItem::[1] vtable 槽 NIndustrialOrganisation::CDetailsModifierItem::[1]（func_names RTTI 名） |
| 0x140492910 | NProject::CEveryActiveScientistEffect::[25] vtable 槽 NProject::CEveryActiveScientistEffect::[25]（func_names RTTI 名） |
| 0x140492930 | NProject::CEveryScientistEffect::[25] vtable 槽 NProject::CEveryScientistEffect::[25]（func_names RTTI 名） |
| 0x14146CB1C | NFactions::NUi::CConfirmGoalWindow::[1] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[1]（func_names RTTI 名） |
| 0x141955CC0 | NOperativeMissions::CControlTrade::[17] vtable 槽 NOperativeMissions::CControlTrade::[17]（func_names RTTI 名） |
| 0x1419C4014 | NCareerProfile::CBasePopupWindow::[1] vtable 槽 NCareerProfile::CBasePopupWindow::[1]（func_names RTTI 名） |
| 0x14167D9AC | NRaids::NGfx::CRaidArrow::[0] vtable 槽 NRaids::NGfx::CRaidArrow::[0]（func_names RTTI 名） |
| 0x1419571E0 | NOperativeMissions::CCounterIntelligence::[17] vtable 槽 NOperativeMissions::CCounterIntelligence::[17]（func_names RTTI 名） |
| 0x141958B10 | NOperativeMissions::CDiplomaticPressure::[17] vtable 槽 NOperativeMissions::CDiplomaticPressure::[17]（func_names RTTI 名） |
| 0x141FCF084 | NAirSelectionUI::SAirMissionItem::[0] vtable 槽 NAirSelectionUI::SAirMissionItem::[0]（func_names RTTI 名） |
| 0x142051CC0 | NInternationalMarket::CPurchaseContractEntry::[18] vtable 槽 NInternationalMarket::CPurchaseContractEntry::[18]（func_names RTTI 名） |
| 0x142000C50 | NInternationalMarket::CPurchaseEquipmentItem::[22] vtable 槽 NInternationalMarket::CPurchaseEquipmentItem::[22]（func_names RTTI 名） |
| 0x141983100 | NWarScoreDistributionHelper::CTowardsPlayersRedistributer::[2] vtable 槽 NWarScoreDistributionHelper::CTowardsPlayersRedistributer::[2]（func_names RTTI 名） |
| 0x141391B20 | NNotification::CNotificationContainer::[8] vtable 槽 NNotification::CNotificationContainer::[8]（func_names RTTI 名） |
| 0x141F8A960 | NInternationalMarket::CMarketBuyerPanelController::[1] vtable 槽 NInternationalMarket::CMarketBuyerPanelController::[1]（func_names RTTI 名） |
| 0x141F8BD40 | NInternationalMarket::CMarketOverviewPanelController::[2] vtable 槽 NInternationalMarket::CMarketOverviewPanelController::[2]（func_names RTTI 名） |
| 0x141ADB5D0 | NFactions::NUi::CInviteCountryItem::[1] vtable 槽 NFactions::NUi::CInviteCountryItem::[1]（func_names RTTI 名） |
| 0x141ADB5DC | NFactions::NUi::CKickFromFactionCountryItem::[1] vtable 槽 NFactions::NUi::CKickFromFactionCountryItem::[1]（func_names RTTI 名） |
| 0x141C1CB70 | NFactions::NUi::CResearchFacilityItem::[1] vtable 槽 NFactions::NUi::CResearchFacilityItem::[1]（func_names RTTI 名） |
| 0x141F32B70 | NProject::NUi::CProjectSimpleItem::[1] vtable 槽 NProject::NUi::CProjectSimpleItem::[1]（func_names RTTI 名） |
| 0x141F33BB0 | NProject::NUi::CProjectHistoryItem::[1] vtable 槽 NProject::NUi::CProjectHistoryItem::[1]（func_names RTTI 名） |
| 0x141FB5508 | NIndustrialOrganisation::CSavedQueueItem::[1] vtable 槽 NIndustrialOrganisation::CSavedQueueItem::[1]（func_names RTTI 名） |
| 0x14179F7E0 | NFactions::NUi::CFactionTheaterSwitch::[1] vtable 槽 NFactions::NUi::CFactionTheaterSwitch::[1]（func_names RTTI 名） |
| 0x1418EB0FC | NRaids::NUi::CRaidMapIcon::[1] vtable 槽 NRaids::NUi::CRaidMapIcon::[1]（func_names RTTI 名） |
| 0x141A058B0 | NProject::CProgramConsumer::[10] vtable 槽 NProject::CProgramConsumer::[10]（func_names RTTI 名） |
| 0x141B371A4 | NRaids::NUi::CRaidInstanceItem::[1] vtable 槽 NRaids::NUi::CRaidInstanceItem::[1]（func_names RTTI 名） |
| 0x141B371BC | NRaids::NUi::CRaidSourceItem::[1] vtable 槽 NRaids::NUi::CRaidSourceItem::[1]（func_names RTTI 名） |
| 0x141B371E0 | NRaids::NUi::CRaidUnitItem::[1] vtable 槽 NRaids::NUi::CRaidUnitItem::[1]（func_names RTTI 名） |
| 0x141EEE048 | NProject::NUi::CProgramOngoingProjectView::[0] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[0]（func_names RTTI 名） |
| 0x141F20D34 | NIndustrialOrganisation::COrganisationListItem::[1] vtable 槽 NIndustrialOrganisation::COrganisationListItem::[1]（func_names RTTI 名） |
| 0x141F20D40 | NIndustrialOrganisation::COrganisationListItem::[1] vtable 槽 NIndustrialOrganisation::COrganisationListItem::[1]（func_names RTTI 名） |
| 0x141FBAB38 | NIndustrialOrganisation::CDetailsInitialTraitItem::[1] vtable 槽 NIndustrialOrganisation::CDetailsInitialTraitItem::[1]（func_names RTTI 名） |
| 0x141FBAB74 | NIndustrialOrganisation::CEquipmentTypeHeaderItem::[1] vtable 槽 NIndustrialOrganisation::CEquipmentTypeHeaderItem::[1]（func_names RTTI 名） |
| 0x141FBAB8C | NIndustrialOrganisation::CHistoryItem::[1] vtable 槽 NIndustrialOrganisation::CHistoryItem::[1]（func_names RTTI 名） |
| 0x141FCBBA0 | NAirSelectionUI::CAirBaseSelectionItem::[1] vtable 槽 NAirSelectionUI::CAirBaseSelectionItem::[1]（func_names RTTI 名） |
| 0x141FCF078 | NAirSelectionUI::CAirWingSelectionItem::[1] vtable 槽 NAirSelectionUI::CAirWingSelectionItem::[1]（func_names RTTI 名） |
| 0x141FD42F0 | NAirSelectionUI::CGunEmplacementWingsSelectionItem::[1] vtable 槽 NAirSelectionUI::CGunEmplacementWingsSelectionItem::[1]（func_names RTTI 名） |
| 0x14200BDE8 | NInternationalMarket::CMarketStockpileWindow::[1] vtable 槽 NInternationalMarket::CMarketStockpileWindow::[1]（func_names RTTI 名） |
| 0x140FE9F80 | NRaids::CRaidInstance::[0] vtable 槽 NRaids::CRaidInstance::[0]（func_names RTTI 名） |
| 0x141298B90 | NRaids::NUi::CRaidGuiManager::[0] vtable 槽 NRaids::NUi::CRaidGuiManager::[0]（func_names RTTI 名） |
| 0x141391384 | NNotification::CNotificationContainer::[0] vtable 槽 NNotification::CNotificationContainer::[0]（func_names RTTI 名） |
| 0x14146CAE0 | NFactions::NUi::CConfirmRuleWindow::[0] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[0]（func_names RTTI 名） |
| 0x14146CAEC | NFactions::NUi::CConfirmRuleWindow::[1] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[1]（func_names RTTI 名） |
| 0x14146CAF8 | NFactions::NUi::CFactionPopup::[0] vtable 槽 NFactions::NUi::CFactionPopup::[0]（func_names RTTI 名） |
| 0x14146CB04 | NFactions::NUi::CFactionPopup::[1] vtable 槽 NFactions::NUi::CFactionPopup::[1]（func_names RTTI 名） |
| 0x14146CB10 | NFactions::NUi::CConfirmGoalWindow::[0] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[0]（func_names RTTI 名） |
| 0x14146CB28 | NFactions::NUi::CCountryFactionView::[1] vtable 槽 NFactions::NUi::CCountryFactionView::[1]（func_names RTTI 名） |
| 0x14146CB40 | NFactions::NUi::CDoctrineSharingPopup::[0] vtable 槽 NFactions::NUi::CDoctrineSharingPopup::[0]（func_names RTTI 名） |
| 0x14146CB4C | NFactions::NUi::CDoctrineSharingPopup::[1] vtable 槽 NFactions::NUi::CDoctrineSharingPopup::[1]（func_names RTTI 名） |
| 0x14146CB58 | NFactions::NUi::CFactionArmySection::[1] vtable 槽 NFactions::NUi::CFactionArmySection::[1]（func_names RTTI 名） |
| 0x14146CB64 | NFactions::NUi::CFactionCountrySection::[1] vtable 槽 NFactions::NUi::CFactionCountrySection::[1]（func_names RTTI 名） |
| 0x14146CB70 | NFactions::NUi::CFactionHeaderSection::[1] vtable 槽 NFactions::NUi::CFactionHeaderSection::[1]（func_names RTTI 名） |
| 0x14146CB7C | NFactions::NUi::CFactionResearchSection::[1] vtable 槽 NFactions::NUi::CFactionResearchSection::[1]（func_names RTTI 名） |
| 0x14146CB88 | NFactions::NUi::CFactionTabSection::[1] vtable 槽 NFactions::NUi::CFactionTabSection::[1]（func_names RTTI 名） |
| 0x14146CBA0 | NFactions::NUi::CFactionTheaterPopup::[1] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[1]（func_names RTTI 名） |
| 0x14146CBAC | NFactions::NUi::CIntelligenceTabSection::[1] vtable 槽 NFactions::NUi::CIntelligenceTabSection::[1]（func_names RTTI 名） |
| 0x14146CBB8 | NFactions::NUi::CInviteToFactionPopup::[0] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[0]（func_names RTTI 名） |
| 0x14146CBC4 | NFactions::NUi::CInviteToFactionPopup::[1] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[1]（func_names RTTI 名） |
| 0x14163AC54 | NDoctrines::CCountryDoctrineView::[1] vtable 槽 NDoctrines::CCountryDoctrineView::[1]（func_names RTTI 名） |
| 0x14163AC60 | NDoctrines::CCountryDoctrineView::[0] vtable 槽 NDoctrines::CCountryDoctrineView::[0]（func_names RTTI 名） |
| 0x14168833C | NAirSelectionUI::CAirSelectionView::[1] vtable 槽 NAirSelectionUI::CAirSelectionView::[1]（func_names RTTI 名） |
| 0x14175A874 | NDivisionDesigner::CNicheSelectionItem::[1] vtable 槽 NDivisionDesigner::CNicheSelectionItem::[1]（func_names RTTI 名） |
| 0x14177C75C | NEquipmentDesigner::CEquipmentNameGroupItem::[1] vtable 槽 NEquipmentDesigner::CEquipmentNameGroupItem::[1]（func_names RTTI 名） |
| 0x14177C768 | NEquipmentDesigner::CEquipmentSpriteListItem::[1] vtable 槽 NEquipmentDesigner::CEquipmentSpriteListItem::[1]（func_names RTTI 名） |
| 0x14177C774 | NEquipmentDesigner::CNicheIconListItem::[1] vtable 槽 NEquipmentDesigner::CNicheIconListItem::[1]（func_names RTTI 名） |
| 0x141796C94 | NFactions::NUi::CFactionTheaterItem::[1] vtable 槽 NFactions::NUi::CFactionTheaterItem::[1]（func_names RTTI 名） |
| 0x1417B9148 | NInternationalMarket::CCountryInternationalMarketView::[1] vtable 槽 NInternationalMarket::CCountryInternationalMarketView::[1]（func_names RTTI 名） |
| 0x1417C959C | NNotification::CLegacyMessagePopUpNotification::[1] vtable 槽 NNotification::CLegacyMessagePopUpNotification::[1]（func_names RTTI 名） |
| 0x141822AF4 | NFactions::NUi::CFactionSetupWindow::[1] vtable 槽 NFactions::NUi::CFactionSetupWindow::[1]（func_names RTTI 名） |
| 0x141822B00 | NFactions::NUi::CFactionSetupWindow::[0] vtable 槽 NFactions::NUi::CFactionSetupWindow::[0]（func_names RTTI 名） |
| 0x141822B0C | NFactions::NUi::CNewFactionTemplateItem::[1] vtable 槽 NFactions::NUi::CNewFactionTemplateItem::[1]（func_names RTTI 名） |
| 0x14192F3E4 | NNotification::CIdeaExpiredNotification::[1] vtable 槽 NNotification::CIdeaExpiredNotification::[1]（func_names RTTI 名） |
| 0x1419C4020 | NCareerProfile::CBasePopupWindow::[0] vtable 槽 NCareerProfile::CBasePopupWindow::[0]（func_names RTTI 名） |
| 0x1419C402C | NCareerProfile::CMedalPopupWindow::[1] vtable 槽 NCareerProfile::CMedalPopupWindow::[1]（func_names RTTI 名） |
| 0x141B1C7EC | NProject::NUi::CProgramView::[0] vtable 槽 NProject::NUi::CProgramView::[0]（func_names RTTI 名） |
| 0x141B29608 | NRaids::NUi::CRaidFilter::[1] vtable 槽 NRaids::NUi::CRaidFilter::[1]（func_names RTTI 名） |
| 0x141B29614 | NRaids::NUi::CRaidFilter::[0] vtable 槽 NRaids::NUi::CRaidFilter::[0]（func_names RTTI 名） |
| 0x141B308BC | NRaids::NUi::CRaidSetupView::[1] vtable 槽 NRaids::NUi::CRaidSetupView::[1]（func_names RTTI 名） |
| 0x141B308C8 | NRaids::NUi::CRaidSetupView::[0] vtable 槽 NRaids::NUi::CRaidSetupView::[0]（func_names RTTI 名） |
| 0x141B34C4C | NRaids::NUi::CRaidFeedbackView::[1] vtable 槽 NRaids::NUi::CRaidFeedbackView::[1]（func_names RTTI 名） |
| 0x141B37198 | NRaids::NUi::CRaidInstanceItem::[0] vtable 槽 NRaids::NUi::CRaidInstanceItem::[0]（func_names RTTI 名） |
| 0x141B371B0 | NRaids::NUi::CRaidSourceItem::[0] vtable 槽 NRaids::NUi::CRaidSourceItem::[0]（func_names RTTI 名） |
| 0x141B371C8 | NRaids::NUi::CRaidTypeIconItem::[1] vtable 槽 NRaids::NUi::CRaidTypeIconItem::[1]（func_names RTTI 名） |
| 0x141B371D4 | NRaids::NUi::CRaidUnitItem::[0] vtable 槽 NRaids::NUi::CRaidUnitItem::[0]（func_names RTTI 名） |
| 0x141BBED18 | NNotification::CNotification::[1] vtable 槽 NNotification::CNotification::[1]（func_names RTTI 名） |
| 0x141BF8C6C | NFactions::NUi::CFactionCommanderWindow::[0] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[0]（func_names RTTI 名） |
| 0x141BFB9A8 | NFactions::NUi::CDoctrineSharingFolderItem::[1] vtable 槽 NFactions::NUi::CDoctrineSharingFolderItem::[1]（func_names RTTI 名） |
| 0x141C19630 | NFactions::NUi::CFactionProgramItem::[1] vtable 槽 NFactions::NUi::CFactionProgramItem::[1]（func_names RTTI 名） |
| 0x141C1963C | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x141C19648 | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x141C19654 | NFactions::NUi::CFactionProgramItemEmpty::[1] vtable 槽 NFactions::NUi::CFactionProgramItemEmpty::[1]（func_names RTTI 名） |
| 0x141C236D8 | NFactions::NUi::CIntelligenceAdvisorSelectionItem::[1] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSelectionItem::[1]（func_names RTTI 名） |
| 0x141C236E4 | NFactions::NUi::CIntelligenceAdvisorSlotItem::[1] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSlotItem::[1]（func_names RTTI 名） |
| 0x141C269F0 | NFactions::NUi::CRuleTypeItem::[1] vtable 槽 NFactions::NUi::CRuleTypeItem::[1]（func_names RTTI 名） |
| 0x141C3B4B4 | NIndustrialOrganisation::COrganisationListWindow::[1] vtable 槽 NIndustrialOrganisation::COrganisationListWindow::[1]（func_names RTTI 名） |
| 0x141CB0258 | NProject::NUi::CFacilitiesTabView::[0] vtable 槽 NProject::NUi::CFacilitiesTabView::[0]（func_names RTTI 名） |
| 0x141CB0264 | NProject::NUi::CFacilitiesTabView::[1] vtable 槽 NProject::NUi::CFacilitiesTabView::[1]（func_names RTTI 名） |
| 0x141CC2778 | NDoctrines::CFolderTabItem::[1] vtable 槽 NDoctrines::CFolderTabItem::[1]（func_names RTTI 名） |
| 0x141CCBBEC | NCareerProfile::CFrontendCareerProfileView::[1] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[1]（func_names RTTI 名） |
| 0x141CF33DC | NAirSelectionUI::CSelectedAirGroupView::[0] vtable 槽 NAirSelectionUI::CSelectedAirGroupView::[0]（func_names RTTI 名） |
| 0x141E88034 | NRaids::NUi::CRaidTargetMapIconEntry::[0] vtable 槽 NRaids::NUi::CRaidTargetMapIconEntry::[0]（func_names RTTI 名） |
| 0x141EEA658 | NProject::NUi::CProjectItem::[1] vtable 槽 NProject::NUi::CProjectItem::[1]（func_names RTTI 名） |
| 0x141EEE030 | NProject::NUi::CProgramOngoingProjectView::[0] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[0]（func_names RTTI 名） |
| 0x141EEE03C | NProject::NUi::CProgramOngoingProjectView::[1] vtable 槽 NProject::NUi::CProgramOngoingProjectView::[1]（func_names RTTI 名） |
| 0x141F0A068 | NFactions::NUi::CFactionMemberUpgradeButton::[1] vtable 槽 NFactions::NUi::CFactionMemberUpgradeButton::[1]（func_names RTTI 名） |
| 0x141F0CAC0 | NProject::NUi::CProgramItem::[1] vtable 槽 NProject::NUi::CProgramItem::[1]（func_names RTTI 名） |
| 0x141F0CAD8 | NProject::NUi::CProgramItem::[0] vtable 槽 NProject::NUi::CProgramItem::[0]（func_names RTTI 名） |
| 0x141F0CAE4 | NProject::NUi::CProgramItemBase::[1] vtable 槽 NProject::NUi::CProgramItemBase::[1]（func_names RTTI 名） |
| 0x141F0CAFC | NProject::NUi::CProgramItemBase::[0] vtable 槽 NProject::NUi::CProgramItemBase::[0]（func_names RTTI 名） |
| 0x141F11F58 | NFactions::NUi::CChangeGoalItem::[1] vtable 槽 NFactions::NUi::CChangeGoalItem::[1]（func_names RTTI 名） |
| 0x141F139F4 | NFactions::NUi::CFilterGoalItem::[1] vtable 槽 NFactions::NUi::CFilterGoalItem::[1]（func_names RTTI 名） |
| 0x141F1498C | NFactions::NUi::CChangeRuleItem::[1] vtable 槽 NFactions::NUi::CChangeRuleItem::[1]（func_names RTTI 名） |
| 0x141F1685C | NFactions::NUi::CFactionMemberScientistItem::[1] vtable 槽 NFactions::NUi::CFactionMemberScientistItem::[1]（func_names RTTI 名） |
| 0x141F17E8C | NProject::NUi::CScientistItem::[1] vtable 槽 NProject::NUi::CScientistItem::[1]（func_names RTTI 名） |
| 0x141F1A808 | NIndustrialOrganisation::COrganisationDetailWindow::[1] vtable 槽 NIndustrialOrganisation::COrganisationDetailWindow::[1]（func_names RTTI 名） |
| 0x141F1A814 | NIndustrialOrganisation::CQueueToUnlockWindow::[1] vtable 槽 NIndustrialOrganisation::CQueueToUnlockWindow::[1]（func_names RTTI 名） |
| 0x141F20D10 | NIndustrialOrganisation::CEquipmentIconItem::[0] vtable 槽 NIndustrialOrganisation::CEquipmentIconItem::[0]（func_names RTTI 名） |
| 0x141F20D28 | NIndustrialOrganisation::COrganisationListItem::[0] vtable 槽 NIndustrialOrganisation::COrganisationListItem::[0]（func_names RTTI 名） |
| 0x141F352D0 | NDoctrines::CTrackItem::[1] vtable 槽 NDoctrines::CTrackItem::[1]（func_names RTTI 名） |
| 0x141F39494 | NDoctrines::CDoctrineListItem::[1] vtable 槽 NDoctrines::CDoctrineListItem::[1]（func_names RTTI 名） |
| 0x141F5F800 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[0] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[0]（func_nam… |
| 0x141F5F80C | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[1] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[1]（func_nam… |
| 0x141F7C958 | NDesignerUI::CNicheIconListItem::[1] vtable 槽 NDesignerUI::CNicheIconListItem::[1]（func_names RTTI 名） |
| 0x141FA3034 | NProject::NUi::CProjectOutputRewardWindow::[0] vtable 槽 NProject::NUi::CProjectOutputRewardWindow::[0]（func_names RTTI 名） |
| 0x141FA3040 | NProject::NUi::CProjectOutputRewardWindow::[1] vtable 槽 NProject::NUi::CProjectOutputRewardWindow::[1]（func_names RTTI 名） |
| 0x141FB0B64 | NIndustrialOrganisation::CPolicyItem::[0] vtable 槽 NIndustrialOrganisation::CPolicyItem::[0]（func_names RTTI 名） |
| 0x141FB54FC | NIndustrialOrganisation::CQueueItem::[1] vtable 槽 NIndustrialOrganisation::CQueueItem::[1]（func_names RTTI 名） |
| 0x141FBAB20 | NIndustrialOrganisation::CBonusTypeIconItem::[0] vtable 槽 NIndustrialOrganisation::CBonusTypeIconItem::[0]（func_names RTTI 名） |
| 0x141FBAB5C | NIndustrialOrganisation::CDetailsSeparatorItem::[0] vtable 槽 NIndustrialOrganisation::CDetailsSeparatorItem::[0]（func_names RTTI 名） |
| 0x141FBAB68 | NIndustrialOrganisation::CEquipmentTypeHeaderItem::[0] vtable 槽 NIndustrialOrganisation::CEquipmentTypeHeaderItem::[0]（func_names RTTI 名） |
| 0x141FBAB80 | NIndustrialOrganisation::CHistoryItem::[0] vtable 槽 NIndustrialOrganisation::CHistoryItem::[0]（func_names RTTI 名） |
| 0x141FC2A14 | NDoctrines::CRewardItem::[1] vtable 槽 NDoctrines::CRewardItem::[1]（func_names RTTI 名） |
| 0x141FCBB94 | NAirSelectionUI::CAirBaseSelectionItem::[0] vtable 槽 NAirSelectionUI::CAirBaseSelectionItem::[0]（func_names RTTI 名） |
| 0x141FCF06C | NAirSelectionUI::CAirWingSelectionItem::[0] vtable 槽 NAirSelectionUI::CAirWingSelectionItem::[0]（func_names RTTI 名） |
| 0x141FD42E4 | NAirSelectionUI::CGunEmplacementWingsSelectionItem::[0] vtable 槽 NAirSelectionUI::CGunEmplacementWingsSelectionItem::[0]（func_names RTTI 名） |
| 0x141FD62D8 | NAirSelectionUI::CRocketWingsSelectionItem::[0] vtable 槽 NAirSelectionUI::CRocketWingsSelectionItem::[0]（func_names RTTI 名） |
| 0x141FD9E30 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[0] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[0]（func_names… |
| 0x141FDD834 | NCareerProfile::CMedalItem::[1] vtable 槽 NCareerProfile::CMedalItem::[1]（func_names RTTI 名） |
| 0x141FE4B24 | NCareerProfile::CCareerProfilePageDot::[0] vtable 槽 NCareerProfile::CCareerProfilePageDot::[0]（func_names RTTI 名） |
| 0x141FFB6E4 | NInternationalMarket::CPurchasableEquipmentWindow::[0] vtable 槽 NInternationalMarket::CPurchasableEquipmentWindow::[0]（func_names RTTI 名） |
| 0x141FFB6F0 | NInternationalMarket::CPurchasableEquipmentWindow::[1] vtable 槽 NInternationalMarket::CPurchasableEquipmentWindow::[1]（func_names RTTI 名） |
| 0x141FFB708 | NInternationalMarket::CPurchaseEquipmentItem::[1] vtable 槽 NInternationalMarket::CPurchaseEquipmentItem::[1]（func_names RTTI 名） |
| 0x142006358 | NInternationalMarket::CMarketAccessOverviewItem::[1] vtable 槽 NInternationalMarket::CMarketAccessOverviewItem::[1]（func_names RTTI 名） |
| 0x142006364 | NInternationalMarket::CMarketAccessOverviewWindow::[0] vtable 槽 NInternationalMarket::CMarketAccessOverviewWindow::[0]（func_names RTTI 名） |
| 0x142006370 | NInternationalMarket::CMarketAccessOverviewWindow::[1] vtable 槽 NInternationalMarket::CMarketAccessOverviewWindow::[1]（func_names RTTI 名） |
| 0x142007A14 | NInternationalMarket::CRequestAutomationOptionsWindow::[0] vtable 槽 NInternationalMarket::CRequestAutomationOptionsWindow::[0]（func_names RTTI 名） |
| 0x142007A20 | NInternationalMarket::CRequestAutomationOptionsWindow::[1] vtable 槽 NInternationalMarket::CRequestAutomationOptionsWindow::[1]（func_names RTTI 名） |
| 0x14200BDB8 | NInternationalMarket::CCancelSellingContractPopup::[1] vtable 槽 NInternationalMarket::CCancelSellingContractPopup::[1]（func_names RTTI 名） |
| 0x14200BDC4 | NInternationalMarket::CEquipmentStockpileEquipmentItem::[1] vtable 槽 NInternationalMarket::CEquipmentStockpileEquipmentItem::[1]（func_names RTTI 名） |
| 0x14200BDD0 | NInternationalMarket::CMarketStockpileWindow::[0] vtable 槽 NInternationalMarket::CMarketStockpileWindow::[0]（func_names RTTI 名） |
| 0x14200BDDC | NInternationalMarket::CMarketStockpileWindow::[1] vtable 槽 NInternationalMarket::CMarketStockpileWindow::[1]（func_names RTTI 名） |
| 0x14200F13C | NAiNavalGoals::CCoastDefenseObjective::[1] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[1]（func_names RTTI 名） |
| 0x142011ED4 | NAiNavalGoals::CMineLayingObjective::[1] vtable 槽 NAiNavalGoals::CMineLayingObjective::[1]（func_names RTTI 名） |
| 0x14201652C | NProject::NUi::CDetailedOutputItem::[0] vtable 槽 NProject::NUi::CDetailedOutputItem::[0]（func_names RTTI 名） |
| 0x14201B0AC | NCareerProfile::CMedalDisplaySlot::[1] vtable 槽 NCareerProfile::CMedalDisplaySlot::[1]（func_names RTTI 名） |
| 0x142021534 | NIndustrialOrganisation::CDeleteQueuePopUp::[0] vtable 槽 NIndustrialOrganisation::CDeleteQueuePopUp::[0]（func_names RTTI 名） |
| 0x142021540 | NIndustrialOrganisation::CDeleteQueuePopUp::[1] vtable 槽 NIndustrialOrganisation::CDeleteQueuePopUp::[1]（func_names RTTI 名） |
| 0x14202154C | NIndustrialOrganisation::CLoadQueuePopUp::[0] vtable 槽 NIndustrialOrganisation::CLoadQueuePopUp::[0]（func_names RTTI 名） |
| 0x142021564 | NIndustrialOrganisation::CSaveQueuePopUp::[0] vtable 槽 NIndustrialOrganisation::CSaveQueuePopUp::[0]（func_names RTTI 名） |
| 0x142021570 | NIndustrialOrganisation::CSaveQueuePopUp::[1] vtable 槽 NIndustrialOrganisation::CSaveQueuePopUp::[1]（func_names RTTI 名） |
| 0x1420240C8 | NIndustrialOrganisation::CUnlockTraitPopup::[0] vtable 槽 NIndustrialOrganisation::CUnlockTraitPopup::[0]（func_names RTTI 名） |
| 0x1420240D4 | NIndustrialOrganisation::CUnlockTraitPopup::[1] vtable 槽 NIndustrialOrganisation::CUnlockTraitPopup::[1]（func_names RTTI 名） |
| 0x1420240E0 | NIndustrialOrganisation::CUpgradeVariantPopup::[0] vtable 槽 NIndustrialOrganisation::CUpgradeVariantPopup::[0]（func_names RTTI 名） |
| 0x1420240EC | NIndustrialOrganisation::CUpgradeVariantPopup::[1] vtable 槽 NIndustrialOrganisation::CUpgradeVariantPopup::[1]（func_names RTTI 名） |
| 0x14202B888 | NAirWingReorganizationUI::CAirWingReorganizationWindow::[0] vtable 槽 NAirWingReorganizationUI::CAirWingReorganizationWindow::[0]（func_names RTTI 名） |
| 0x14202B894 | NAirWingReorganizationUI::CAirWingReorganizationWindow::[1] vtable 槽 NAirWingReorganizationUI::CAirWingReorganizationWindow::[1]（func_names RTTI 名） |
| 0x142041D14 | NInternationalMarket::CMarketEquipmentItem::[1] vtable 槽 NInternationalMarket::CMarketEquipmentItem::[1]（func_names RTTI 名） |
| 0x142044B68 | NInternationalMarket::CPurchaseDraftItem::[1] vtable 槽 NInternationalMarket::CPurchaseDraftItem::[1]（func_names RTTI 名） |
| 0x142044B74 | NInternationalMarket::CPurchaseDraftWindow::[0] vtable 槽 NInternationalMarket::CPurchaseDraftWindow::[0]（func_names RTTI 名） |
| 0x142044B80 | NInternationalMarket::CPurchaseDraftWindow::[1] vtable 槽 NInternationalMarket::CPurchaseDraftWindow::[1]（func_names RTTI 名） |
| 0x142044B98 | NInternationalMarket::NPrivate::CTotalIcon::[1] vtable 槽 NInternationalMarket::NPrivate::CTotalIcon::[1]（func_names RTTI 名） |
| 0x14204CA00 | NInternationalMarket::CPurchaseContractEntry::[1] vtable 槽 NInternationalMarket::CPurchaseContractEntry::[1]（func_names RTTI 名） |
| 0x142053300 | NInternationalMarket::CEditMarketStockpileWindow::[0] vtable 槽 NInternationalMarket::CEditMarketStockpileWindow::[0]（func_names RTTI 名） |
| 0x142058E24 | NInternationalMarket::CAddEquipmentToMarketWindow::[0] vtable 槽 NInternationalMarket::CAddEquipmentToMarketWindow::[0]（func_names RTTI 名） |
| 0x142058E30 | NInternationalMarket::CAddEquipmentToMarketWindow::[1] vtable 槽 NInternationalMarket::CAddEquipmentToMarketWindow::[1]（func_names RTTI 名） |
| 0x142058E3C | NInternationalMarket::CAddToMarketEquipmentItem::[1] vtable 槽 NInternationalMarket::CAddToMarketEquipmentItem::[1]（func_names RTTI 名） |
| 0x14205ECC0 | NAirWingReorganizationUI::NInternal::CEquipmentEntry::[1] vtable 槽 NAirWingReorganizationUI::NInternal::CEquipmentEntry::[1]（func_names RTTI 名） |
| 0x142060878 | NAirWingReorganizationUI::NInternal::CManpowerListItem::[1] vtable 槽 NAirWingReorganizationUI::NInternal::CManpowerListItem::[1]（func_names RTTI 名） |
| 0x14206C264 | NInternationalMarket::CPriceLevelsWidget::[1] vtable 槽 NInternationalMarket::CPriceLevelsWidget::[1]（func_names RTTI 名） |
| 0x140E759FC | NProject::CProgramStatus::[0] vtable 槽 NProject::CProgramStatus::[0]（func_names RTTI 名） |
| 0x141956CD0 | NOperativeMissions::CControlTrade::[8] vtable 槽 NOperativeMissions::CControlTrade::[8]（func_names RTTI 名） |
| 0x141F241F0 | NIndustrialOrganisation::COpenRosterButtonForPoliticalScreen::[0] vtable 槽 NIndustrialOrganisation::COpenRosterButtonForPoliticalScreen::[0]（func_names RTTI 名） |
| 0x142010DE0 | NAiNavalGoals::CConvoyRaidingObjective::[6] vtable 槽 NAiNavalGoals::CConvoyRaidingObjective::[6]（func_names RTTI 名） |
| 0x14200FB60 | NAiNavalGoals::CCoastDefenseObjective::[5] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[5]（func_names RTTI 名） |
| 0x142010370 | NAiNavalGoals::CConvoyProtectionObjective::[5] vtable 槽 NAiNavalGoals::CConvoyProtectionObjective::[5]（func_names RTTI 名） |
| 0x142010E00 | NAiNavalGoals::CConvoyRaidingObjective::[5] vtable 槽 NAiNavalGoals::CConvoyRaidingObjective::[5]（func_names RTTI 名） |
| 0x142011D80 | NAiNavalGoals::CInvasionDefenseObjective::[5] vtable 槽 NAiNavalGoals::CInvasionDefenseObjective::[5]（func_names RTTI 名） |
| 0x1420128D0 | NAiNavalGoals::CMineSweepingObjective::[5] vtable 槽 NAiNavalGoals::CMineSweepingObjective::[5]（func_names RTTI 名） |
| 0x1420131B0 | NAiNavalGoals::CNavalBlockadeObjective::[5] vtable 槽 NAiNavalGoals::CNavalBlockadeObjective::[5]（func_names RTTI 名） |
| 0x1420139B0 | NAiNavalGoals::CNavalDominanceObjective::[5] vtable 槽 NAiNavalGoals::CNavalDominanceObjective::[5]（func_names RTTI 名） |
| 0x1420147F0 | NAiNavalGoals::CInvasionSupportObjective::[5] vtable 槽 NAiNavalGoals::CInvasionSupportObjective::[5]（func_names RTTI 名） |
| 0x142014EE0 | NAiNavalGoals::CTrainingObjective::[5] vtable 槽 NAiNavalGoals::CTrainingObjective::[5]（func_names RTTI 名） |
| 0x141A058A0 | NProject::CProgramConsumer::[11] vtable 槽 NProject::CProgramConsumer::[11]（func_names RTTI 名） |
| 0x141C22AD0 | NFactions::NUi::CFactionScientistRoster::[4] vtable 槽 NFactions::NUi::CFactionScientistRoster::[4]（func_names RTTI 名） |
| 0x140E000E0 | NInternationalMarket::CPurchaseDraftItem::[24] vtable 槽 NInternationalMarket::CPurchaseDraftItem::[24]（func_names RTTI 名） |
| 0x141CCBC70 | NCareerProfile::CFrontendCareerProfileView::[15] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[15]（func_names RTTI 名） |
| 0x141CCBC80 | NCareerProfile::CFrontendCareerProfileView::[6] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[6]（func_names RTTI 名） |
| 0x141CCBC90 | NCareerProfile::CFrontendCareerProfileView::[5] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[5]（func_names RTTI 名） |
| 0x141CCBD30 | NCareerProfile::CFrontendCareerProfileView::[14] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[14]（func_names RTTI 名） |
| 0x141CCBE60 | NCareerProfile::CFrontendCareerProfileView::[9] vtable 槽 NCareerProfile::CFrontendCareerProfileView::[9]（func_names RTTI 名） |
| 0x141E87670 | NRaids::NUi::CEnemyRaidMapIconData::[2] vtable 槽 NRaids::NUi::CEnemyRaidMapIconData::[2]（func_names RTTI 名） |
| 0x141E8B010 | NRaids::NUi::CRaidUnitMapIconData::[2] vtable 槽 NRaids::NUi::CRaidUnitMapIconData::[2]（func_names RTTI 名） |
| 0x141B31510 | NRaids::NUi::CRaidSetupView::[9] vtable 槽 NRaids::NUi::CRaidSetupView::[9]（func_names RTTI 名） |
| 0x140DF2580 | NInternationalMarket::CEquipmentConvoyClient::[15] vtable 槽 NInternationalMarket::CEquipmentConvoyClient::[15]（func_names RTTI 名） |
| 0x14167DB14 | NRaids::NGfx::CRaidArrow::[1] vtable 槽 NRaids::NGfx::CRaidArrow::[1]（func_names RTTI 名） |
| 0x142069024 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[0] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[0]（func_names RTTI 名） |
| 0x141FFF010 | NInternationalMarket::CPurchasableEquipmentWindow::[2] vtable 槽 NInternationalMarket::CPurchasableEquipmentWindow::[2]（func_names RTTI 名） |
| 0x14200CFA0 | NInternationalMarket::CMarketStockpileWindow::[2] vtable 槽 NInternationalMarket::CMarketStockpileWindow::[2]（func_names RTTI 名） |
| 0x1419ABDF0 | NRaids::NUi::CPlayerStatusCache::[1] vtable 槽 NRaids::NUi::CPlayerStatusCache::[1]（func_names RTTI 名） |
| 0x14145A9A0 | NAiNavalGoals::CMineLayingObjective::[0] vtable 槽 NAiNavalGoals::CMineLayingObjective::[0]（func_names RTTI 名） |
| 0x140DF2590 | NInternationalMarket::CEquipmentConvoyClient::[17] vtable 槽 NInternationalMarket::CEquipmentConvoyClient::[17]（func_names RTTI 名） |
| 0x140A90A10 | NProject::CHasFloatingHarborTrigger::[22] vtable 槽 NProject::CHasFloatingHarborTrigger::[22]（func_names RTTI 名） |
| 0x1404A6320 | NRaids::CDamageRaidUnitEffect::[19] vtable 槽 NRaids::CDamageRaidUnitEffect::[19]（func_names RTTI 名） |

#### 4.25.14 世界层全局对象函数补遗（772 函）

| VA | 语义/证据 |
|---|---|

#### 4.25.15 世界层全局对象函数补遗（697 函）

| VA | 语义/证据 |
|---|---|
| 0x14199ECD0 | NIndustrialOrganisation::CreateDynamicVariables func_names 名 NIndustrialOrganisation::CreateDynamicVariables |
| 0x141A3B2F0 | NRaids::CreateDynamicVariables func_names 名 NRaids::CreateDynamicVariables |
| 0x14146EB00 | NFactions::NUi::CFactionCountrySection::[0] vtable 槽 NFactions::NUi::CFactionCountrySection::[0]（func_names RTTI 名） |
| 0x141E759C0 | NFactions::NUi::CFactionButton::[0] vtable 槽 NFactions::NUi::CFactionButton::[0]（func_names RTTI 名） |
| 0x141FD6480 | NAirSelectionUI::CRocketWingsSelectionItem::[0] vtable 槽 NAirSelectionUI::CRocketWingsSelectionItem::[0]（func_names RTTI 名） |
| 0x141C00BA0 | NFactions::NUi::CInviteToFactionPopup::[16] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[16]（func_names RTTI 名） |
| 0x141D227C0 | NDoctrines::CEntryButton::[0] vtable 槽 NDoctrines::CEntryButton::[0]（func_names RTTI 名） |
| 0x141F12180 | NFactions::NUi::CChangeGoalItem::[0] vtable 槽 NFactions::NUi::CChangeGoalItem::[0]（func_names RTTI 名） |
| 0x141610230 | NFactions::COfferJoinFactionAction::[59] vtable 槽 NFactions::COfferJoinFactionAction::[59]（func_names RTTI 名） |
| 0x14146DF80 | NFactions::NUi::CFactionArmySection::[0] vtable 槽 NFactions::NUi::CFactionArmySection::[0]（func_names RTTI 名） |
| 0x14146FAC0 | NFactions::NUi::CFactionHeaderSection::[0] vtable 槽 NFactions::NUi::CFactionHeaderSection::[0]（func_names RTTI 名） |
| 0x1418235F0 | NFactions::NUi::CFactionSetupWindow::[0] vtable 槽 NFactions::NUi::CFactionSetupWindow::[0]（func_names RTTI 名） |
| 0x141BFF8E0 | NFactions::NUi::CConfirmRuleWindow::[16] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[16]（func_names RTTI 名） |
| 0x141CEDCE0 | NAirSelectionUI::CMissionToolbarController::[0] vtable 槽 NAirSelectionUI::CMissionToolbarController::[0]（func_names RTTI 名） |
| 0x141BFEFA0 | NFactions::NUi::CConfirmGoalWindow::[16] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[16]（func_names RTTI 名） |
| 0x14160F7D0 | NFactions::CJoinFactionAction::[59] vtable 槽 NFactions::CJoinFactionAction::[59]（func_names RTTI 名） |
| 0x141615CF0 | NFactions::CJoinFactionAction::CanExecute func_names 名 NFactions::CJoinFactionAction::CanExecute |
| 0x140A94E30 | NProject::CProjectTemplate::[4] vtable 槽 NProject::CProjectTemplate::[4]（func_names RTTI 名） |
| 0x14202CD40 | NAirWingReorganizationUI::CAirWingReorganizationWindow::[0] vtable 槽 NAirWingReorganizationUI::CAirWingReorganizationWindow::[0]（func_names RTTI 名） |
| 0x1416127C0 | NFactions::CJoinFactionAction::GetRequestDescText func_names 名 NFactions::CJoinFactionAction::GetRequestDescText |
| 0x141612120 | NFactions::CCreateFactionAction::GetRequestDescText func_names 名 NFactions::CCreateFactionAction::GetRequestDescText |
| 0x140306840 | NInternationalMarket::CCreatePurchaseContractEffect::GetDesc func_names 名 NInternationalMarket::CCreatePurchaseContractEffect::GetDesc |
| 0x142024B30 | NIndustrialOrganisation::CUnlockTraitPopup::[0] vtable 槽 NIndustrialOrganisation::CUnlockTraitPopup::[0]（func_names RTTI 名） |
| 0x141FD43A0 | NAirSelectionUI::CGunEmplacementWingsSelectionItem::[0] vtable 槽 NAirSelectionUI::CGunEmplacementWingsSelectionItem::[0]（func_names RTTI 名） |
| 0x141615440 | NFactions::CCreateFactionAction::CanExecute func_names 名 NFactions::CCreateFactionAction::CanExecute |
| 0x141612DE0 | NFactions::CKickFromFactionAction::GetRequestDescText func_names 名 NFactions::CKickFromFactionAction::GetRequestDescText |
| 0x141F0E1E0 | NProject::NUi::CProgramItem::[0] vtable 槽 NProject::NUi::CProgramItem::[0]（func_names RTTI 名） |
| 0x141AA57D0 | NInternationalMarket::CRequestEquipmentPurchaseAction::GetAiAcceptanceFactors func_names 名 NInternationalMarket::CRequestEquipmentPurchaseAction::GetAiAccept… |
| 0x141FC2A60 | NDoctrines::CRewardItem::[0] vtable 槽 NDoctrines::CRewardItem::[0]（func_names RTTI 名） |
| 0x14205D7A0 | NAirWingReorganizationUI::NInternal::CFilterListItem::[0] vtable 槽 NAirWingReorganizationUI::NInternal::CFilterListItem::[0]（func_names RTTI 名） |
| 0x141629960 | NUtils::BuildRaidWarningTooltip func_names 名 NUtils::BuildRaidWarningTooltip |
| 0x141FBC720 | NIndustrialOrganisation::CHistoryItem::[8] vtable 槽 NIndustrialOrganisation::CHistoryItem::[8]（func_names RTTI 名） |
| 0x141FB1FA0 | NIndustrialOrganisation::CPolicyItem::[0] vtable 槽 NIndustrialOrganisation::CPolicyItem::[0]（func_names RTTI 名） |
| 0x141FD1760 | NAirSelectionUI::SAirMissionItem::[0] vtable 槽 NAirSelectionUI::SAirMissionItem::[0]（func_names RTTI 名） |
| 0x1404A5C50 | NRaids::CRaidReduceProjectProgressRatioEffect::[7] vtable 槽 NRaids::CRaidReduceProjectProgressRatioEffect::[7]（func_names RTTI 名） |
| 0x140EE8E20 | NTheatreManager::InitializeFrontsForCountries func_names 名 + tbb 任务分配 |
| 0x141957990 | NOperativeMissions::CCounterIntelligence::[15] vtable 槽 NOperativeMissions::CCounterIntelligence::[15]（func_names RTTI 名） |
| 0x141FCBCC0 | NAirSelectionUI::CAirBaseSelectionItem::[0] vtable 槽 NAirSelectionUI::CAirBaseSelectionItem::[0]（func_names RTTI 名） |
| 0x141F14F50 | NFactions::NUi::CChangeRuleItem 槽 0 func_names 名 + gamestate 访问断言 |
| 0x140DBB350 | NIndustrialOrganisation::COrganisation::Reader func_names 名 NIndustrialOrganisation::COrganisation::Reader |
| 0x140459020 | NIndustrialOrganisation::CIsOrganisationTrigger::GetDesc func_names 名 NIndustrialOrganisation::CIsOrganisationTrigger::GetDesc |
| 0x140440C40 | NCareerProfile::CNumOfPointsTrigger::GetDesc func_names 名 NCareerProfile::CNumOfPointsTrigger::GetDesc |
| 0x141C26A50 | NFactions::NUi::CActiveRuleText::[0] vtable 槽 NFactions::NUi::CActiveRuleText::[0]（func_names RTTI 名） |
| 0x141611210 | NFactions::CDismantleFactionAction::[21] vtable 槽 NFactions::CDismantleFactionAction::[21]（func_names RTTI 名） |
| 0x141827EE0 | NFactions::NUi::CLegacyCreateFactionWindow::[6] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[6]（func_names RTTI 名） |
| 0x1406A85C0 | NCareerProfile::SCareerProfileAwards::Writer func_names 名 NCareerProfile::SCareerProfileAwards::Writer |
| 0x141C06330 | NProject::NUi::CProgramList::[2] vtable 槽 NProject::NUi::CProgramList::[2]（func_names RTTI 名） |
| 0x142014B90 | NAiNavalGoals::CTrainingObjective::[10] vtable 槽 NAiNavalGoals::CTrainingObjective::[10]（func_names RTTI 名） |
| 0x140CE0D20 | NCombatLog::CStatsObserver::SCombatSideData::Writer func_names 名 + 按令牌写（sub_1424C2E20(a2, 14163, …)） |
| 0x1409CDAB0 | NDoctrines::CGrandDoctrineTemplate::[13] vtable 槽 NDoctrines::CGrandDoctrineTemplate::[13]（func_names RTTI 名） |
| 0x142006F80 | NInternationalMarket::CMarketAccessOverviewWindow 槽 11 串 country_grid / country_list_window + func_names 名 |
| 0x1414EACF0 | NRaids::CCountryRaidStatus::Writer func_names 名 NRaids::CCountryRaidStatus::Writer |
| 0x14146DC00 | NProject::NUi::CFilterEntryItem<鈥�>::[0] func_names 名 NProject::NUi::CFilterEntryItem<鈥�>::[0] |
| 0x141C00760 | NFactions::NUi::CFactionIntelligencePopup::[16] vtable 槽 NFactions::NUi::CFactionIntelligencePopup::[16]（func_names RTTI 名） |
| 0x141F32D60 | NProject::NUi::CProjectSimpleItem::[0] vtable 槽 NProject::NUi::CProjectSimpleItem::[0]（func_names RTTI 名） |
| 0x140300040 | NIndustrialOrganisation::CUnlockIndustrialOrgTooltipEffect::GetDesc func_names 名 NIndustrialOrganisation::CUnlockIndustrialOrgTooltipEffect::GetDesc |
| 0x1413CDE50 | NDoctrines::CCountryDoctrineStatus::[8] vtable 槽 NDoctrines::CCountryDoctrineStatus::[8]（func_names RTTI 名） |
| 0x14043FC60 | NCareerProfile::CCheckPlaythroughValue::GetDesc func_names 名 NCareerProfile::CCheckPlaythroughValue::GetDesc |
| 0x140DBCCC0 | NIndustrialOrganisation::COrganisation::Writer func_names 名 NIndustrialOrganisation::COrganisation::Writer |
| 0x1402FECD0 | NIndustrialOrganisation::CSetOrganisationNameKeyEffect::GetDesc func_names 名 NIndustrialOrganisation::CSetOrganisationNameKeyEffect::GetDesc |
| 0x140CDDC50 | NCombatLog::CStatsObserver::CActivityInGroup::Reader func_names 名 NCombatLog::CStatsObserver::CActivityInGroup::Reader |
| 0x1402FC080 | NIndustrialOrganisation::CAddAttachPolicyCooldownEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddAttachPolicyCooldownEffect::GetDesc |
| 0x141B29FF0 | NRaids::NUi::CRaidFilter::[7] vtable 槽 NRaids::NUi::CRaidFilter::[7]（func_names RTTI 名） |
| 0x1401FEBA0 | NGameTelemetry::SendProvincesOccupiedSnapshot? func_names 名即证据（省份占领遥测快照发送） |
| 0x141FB69B0 | NIndustrialOrganisation::CSavedQueueItem::[0] vtable 槽 NIndustrialOrganisation::CSavedQueueItem::[0]（func_names RTTI 名） |
| 0x142047C80 | NInternationalMarket::CPurchaseDraftWindow::[0] vtable 槽 NInternationalMarket::CPurchaseDraftWindow::[0]（func_names RTTI 名） |
| 0x141C34F80 | NFriendsHandler::CDownloadProfileRequestSteam::[1] vtable 槽 NFriendsHandler::CDownloadProfileRequestSteam::[1]（func_names RTTI 名） |
| 0x140495360 | NProject::CAddScientistLevelEffect::[7] vtable 槽 NProject::CAddScientistLevelEffect::[7]（func_names RTTI 名） |
| 0x1402FD360 | NIndustrialOrganisation::CAddSizeEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddSizeEffect::GetDesc |
| 0x140CDE800 | NCombatLog::CStatsObserver::Reader func_names 名 |
| 0x140308290 | NInternationalMarket::CCreatePurchaseContractEffect::ParseToken func_names 名 NInternationalMarket::CCreatePurchaseContractEffect::ParseToken |
| 0x140FE4C50 | NProject::CProject::Reader func_names 名 NProject::CProject::Reader |
| 0x140E771A0 | NProject::CProgramStatus::[8] vtable 槽 NProject::CProgramStatus::[8]（func_names RTTI 名） |
| 0x1412C2760 | NAIAirEvaluation::FillRegionOccupationData? func_names 名 NAIAirEvaluation::FillRegionOccupationData? |
| 0x141BE62C0 | NFactions::CTechnologySharingFaction::[12] vtable 槽 NFactions::CTechnologySharingFaction::[12]（func_names RTTI 名） |
| 0x142027E30 | NIndustrialOrganisation::CTraitTreeItem::[6] vtable 槽 NIndustrialOrganisation::CTraitTreeItem::[6]（func_names RTTI 名） |
| 0x140497AF0 | NProject::CAddScientistTraitEffect::[3] vtable 槽 NProject::CAddScientistTraitEffect::[3]（func_names RTTI 名） |
| 0x141BAE4B0 | NFactions::CUnlockFolderDoctrineSharingCommand::PayloadReader func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::PayloadReader |
| 0x140A23880 | NFactions::CFactionGoal::[4] vtable 槽 NFactions::CFactionGoal::[4]（func_names RTTI 名） |
| 0x140A299E0 | NFactions::CFactionGoalStatus::Writer func_names 名 NFactions::CFactionGoalStatus::Writer |
| 0x141F39EE0 | NDoctrines::CDoctrineSelectionList::[0] vtable 槽 NDoctrines::CDoctrineSelectionList::[0]（func_names RTTI 名） |
| 0x140A4FAB0 | NIndustrialOrganisation::CTraitTemplate::[7] vtable 槽 NIndustrialOrganisation::CTraitTemplate::[7]（func_names RTTI 名） |
| 0x1404A1A30 | NProject::CHasScientistLevelTrigger::Evaluate func_names 名 NProject::CHasScientistLevelTrigger::Evaluate |
| 0x142059B70 | NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[0] func_names 名 NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[0] |
| 0x141B29A00 | NRaids::NUi::CRaidFilter::IsVisible func_names 名 NRaids::NUi::CRaidFilter::IsVisible |
| 0x14203CE50 | NInternationalMarket::NDetails::CSubsidyListItem::[0] vtable 槽 NInternationalMarket::NDetails::CSubsidyListItem::[0]（func_names RTTI 名） |
| 0x14052D3C0 | NDoctrines::CMasteryTrigger::GetDesc func_names 名 NDoctrines::CMasteryTrigger::GetDesc |
| 0x1402FDD90 | NIndustrialOrganisation::CSetAttachPolicyCostEffect::GetDesc func_names 名 NIndustrialOrganisation::CSetAttachPolicyCostEffect::GetDesc |
| 0x142069720 | NInternationalMarket::NDetails::CSubsidyDraftListItemView::[0] vtable 槽 NInternationalMarket::NDetails::CSubsidyDraftListItemView::[0]（func_names RTTI 名） |
| 0x141F5FB60 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[11] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[11]（func_n… |
| 0x142010130 | NAiNavalGoals::CConvoyProtectionObjective::[6] vtable 槽 NAiNavalGoals::CConvoyProtectionObjective::[6]（func_names RTTI 名） |
| 0x140628F60 | NIndustrialOrganisation::CAiBonusWeightList::Reader func_names 名 NIndustrialOrganisation::CAiBonusWeightList::Reader |
| 0x141F5FDC0 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::Update func_names 名 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::Update |
| 0x14202C4D0 | NAirWingReorganizationUI::CAirWingReorganizationWindow::[12] vtable 槽 NAirWingReorganizationUI::CAirWingReorganizationWindow::[12]（func_names RTTI 名） |
| 0x140CDE050 | NCombatLog::CManager::Reader func_names 名 NCombatLog::CManager::Reader |
| 0x14043EAE0 | NCareerProfile::CHasPlayerFlag::Evaluate func_names 名 NCareerProfile::CHasPlayerFlag::Evaluate |
| 0x141C01B90 | NFactions::NUi::CBecomeLeaderConfirmationWindow::[15] vtable 槽 NFactions::NUi::CBecomeLeaderConfirmationWindow::[15]（func_names RTTI 名） |
| 0x14052D900 | NDoctrines::CMasteryTrigger::ParseToken func_names 名 NDoctrines::CMasteryTrigger::ParseToken |
| 0x141ADFC50 | NFactions::NUi::CKickFromFactionCountryItem::[20] vtable 槽 NFactions::NUi::CKickFromFactionCountryItem::[20]（func_names RTTI 名） |
| 0x1404A1030 | NProject::CAllActiveScientistsTrigger::Evaluate func_names 名 NProject::CAllActiveScientistsTrigger::Evaluate |
| 0x141C01E20 | NFactions::NUi::CConfirmRuleWindow::[15] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[15]（func_names RTTI 名） |
| 0x141FB3110 | NIndustrialOrganisation::CPolicyItem::[8] vtable 槽 NIndustrialOrganisation::CPolicyItem::[8]（func_names RTTI 名） |
| 0x14045A840 | NInternationalMarket::CContractContainsEquipmentTrigger::GetDesc func_names 名 NInternationalMarket::CContractContainsEquipmentTrigger::GetDesc |
| 0x141B397D0 | NRaids::NUi::CRaidSourceItem::[8] vtable 槽 NRaids::NUi::CRaidSourceItem::[8]（func_names RTTI 名） |
| 0x141C32790 | NCountryStatTracking::CConstructedBuildingsTracker::[2] vtable 槽 NCountryStatTracking::CConstructedBuildingsTracker::[2]（func_names RTTI 名） |
| 0x141F9B170 | NAirSelectionUI::CEquipmentPriorityOption::[0] vtable 槽 NAirSelectionUI::CEquipmentPriorityOption::[0]（func_names RTTI 名） |
| 0x1402FD850 | NIndustrialOrganisation::CAddTaskCapacityEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddTaskCapacityEffect::GetDesc |
| 0x14146D840 | NFactions::NUi::CCountryFactionView::ClearContents func_names 名 NFactions::NUi::CCountryFactionView::ClearContents |
| 0x141F62EF0 | NAirSelectionUI::CSplitSelectionButton::[3] vtable 槽 NAirSelectionUI::CSplitSelectionButton::[3]（func_names RTTI 名） |
| 0x1402FC6A0 | NIndustrialOrganisation::CAddDesignTeamAssignCostEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddDesignTeamAssignCostEffect::GetDesc |
| 0x1404A3CC0 | NProject::CHasScientistLevelTrigger::ParseToken func_names 名 NProject::CHasScientistLevelTrigger::ParseToken |
| 0x1406AA550 | NCareerProfile::SGameModeStatistics::Writer func_names 名 NCareerProfile::SGameModeStatistics::Writer |
| 0x1403040D0 | NInternationalMarket::CCancelPurchaseContractEffect::Execute func_names 名 NInternationalMarket::CCancelPurchaseContractEffect::Execute |
| 0x14179E0C0 | NFactions::NUi::CFactionTheaterWindow::[6] vtable 槽 NFactions::NUi::CFactionTheaterWindow::[6]（func_names RTTI 名） |
| 0x142010380 | NAiNavalGoals::CConvoyProtectionObjective::[1] vtable 槽 NAiNavalGoals::CConvoyProtectionObjective::[1]（func_names RTTI 名） |
| 0x1404A15B0 | NProject::CAnyScientistTrigger::Evaluate func_names 名 NProject::CAnyScientistTrigger::Evaluate |
| 0x140459EE0 | NInternationalMarket::CAnyPurchaseContractTrigger::Evaluate func_names 名 NInternationalMarket::CAnyPurchaseContractTrigger::Evaluate |
| 0x140497FB0 | NProject::CAddBreakthroughProgress::[4] vtable 槽 NProject::CAddBreakthroughProgress::[4]（func_names RTTI 名） |
| 0x1404A3930 | NProject::CHasProjectFlagTrigger::[23] vtable 槽 NProject::CHasProjectFlagTrigger::[23]（func_names RTTI 名） |
| 0x141C03130 | NFactions::NUi::CLeaveFactionConfirmationWindow::[14] vtable 槽 NFactions::NUi::CLeaveFactionConfirmationWindow::[14]（func_names RTTI 名） |
| 0x141DED770 | NCareerProfile::CPlaythroughOverviewWindow::Reload func_names 名 NCareerProfile::CPlaythroughOverviewWindow::Reload |
| 0x14200FB70 | NAiNavalGoals::CCoastDefenseObjective::[1] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[1]（func_names RTTI 名） |
| 0x1417838A0 | NEquipmentDesigner::CEquipmentNameGroupItem::[0] vtable 槽 NEquipmentDesigner::CEquipmentNameGroupItem::[0]（func_names RTTI 名） |
| 0x140529510 | NDoctrines::CAddDailyMasteryEffect::Execute func_names 名 NDoctrines::CAddDailyMasteryEffect::Execute |
| 0x140459D20 | NInternationalMarket::CAllPurchaseContractTrigger::Evaluate func_names 名 NInternationalMarket::CAllPurchaseContractTrigger::Evaluate |
| 0x1404A3620 | NProject::CIsScientistInjured::GetDesc func_names 名 NProject::CIsScientistInjured::GetDesc |
| 0x14052CEF0 | NDoctrines::CHasGrandDoctrineInFolderTrigger::GetDesc func_names 名 NDoctrines::CHasGrandDoctrineInFolderTrigger::GetDesc |
| 0x141ED1C40 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] |
| 0x141ED1DB0 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] |
| 0x141ED2200 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] |
| 0x141ED27C0 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] |
| 0x141ED2930 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[1] |
| 0x1420220B0 | NIndustrialOrganisation::CSaveQueuePopUp::[16] vtable 槽 NIndustrialOrganisation::CSaveQueuePopUp::[16]（func_names RTTI 名） |
| 0x140A91A00 | NProject::SOutput::[8] vtable 槽 NProject::SOutput::[8]（func_names RTTI 名） |
| 0x141F32BD0 | NProject::NUi::CProjectSimpleRoster::[7] vtable 槽 NProject::NUi::CProjectSimpleRoster::[7]（func_names RTTI 名） |
| 0x141CB34B0 | NProject::NUi::CFacilitiesTabView::Update func_names 名 NProject::NUi::CFacilitiesTabView::Update |
| 0x1405297D0 | NDoctrines::CAddMasteryEffect::Execute func_names 名 NDoctrines::CAddMasteryEffect::Execute |
| 0x141F33F90 | NProject::NUi::CProjectHistoryRoster::[6] vtable 槽 NProject::NUi::CProjectHistoryRoster::[6]（func_names RTTI 名） |
| 0x1402FE4E0 | NIndustrialOrganisation::CSetFundsEffect::GetDesc func_names 名 NIndustrialOrganisation::CSetFundsEffect::GetDesc |
| 0x141615B70 | NFactions::CDismantleFactionAction::CanExecute func_names 名 NFactions::CDismantleFactionAction::CanExecute |
| 0x141F63200 | NAirSelectionUI::CSplitWingOption::[2] vtable 槽 NAirSelectionUI::CSplitWingOption::[2]（func_names RTTI 名） |
| 0x1402FD630 | NIndustrialOrganisation::CAddSizeUpRequirementFactorEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddSizeUpRequirementFactorEffect::GetDesc |
| 0x1402FE2C0 | NIndustrialOrganisation::CSetDesignTeamChangeCostEffect::GetDesc func_names 名 NIndustrialOrganisation::CSetDesignTeamChangeCostEffect::GetDesc |
| 0x1402FE930 | NIndustrialOrganisation::CSetIndustrialManufacturerAssignCostEf鈥�::[7] func_names 名 NIndustrialOrganisation::CSetIndustrialManufacturerAssignCostEf鈥�::[7] |
| 0x1402FCD00 | NIndustrialOrganisation::CAddFundsGainFactorEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddFundsGainFactorEffect::GetDesc |
| 0x1402FD140 | NIndustrialOrganisation::CAddResearchBonusEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddResearchBonusEffect::GetDesc |
| 0x1402FEFE0 | NIndustrialOrganisation::CSetResearchBonusEffect::GetDesc func_names 名 NIndustrialOrganisation::CSetResearchBonusEffect::GetDesc |
| 0x14052C3B0 | NDoctrines::CHasGrandDoctrineInFolderTrigger::ParseValueKeys func_names 名 NDoctrines::CHasGrandDoctrineInFolderTrigger::ParseValueKeys |
| 0x140CE0990 | NCombatLog::CStatsObserver::Writer func_names 名 NCombatLog::CStatsObserver::Writer |
| 0x1402FCAE0 | NIndustrialOrganisation::CAddFundsEffect::GetDesc func_names 名 NIndustrialOrganisation::CAddFundsEffect::GetDesc |
| 0x1409CC3B0 | NDoctrines::CDoctrineBaseTemplate::[12] vtable 槽 NDoctrines::CDoctrineBaseTemplate::[12]（func_names RTTI 名） |
| 0x1402FEB50 | NIndustrialOrganisation::CSetOrganisationIconEffect::GetDesc func_names 名 NIndustrialOrganisation::CSetOrganisationIconEffect::GetDesc |
| 0x141FC07A0 | NIndustrialOrganisation::CTraitTree::[23] vtable 槽 NIndustrialOrganisation::CTraitTree::[23]（func_names RTTI 名） |
| 0x140301010 | NIndustrialOrganisation::CSetIndustrialManufacturerAssignCostEf鈥�::[23] func_names 名 NIndustrialOrganisation::CSetIndustrialManufacturerAssignCostEf鈥�::[23] |
| 0x141EEAC20 | NProject::NUi::CProjectItem::[0] vtable 槽 NProject::NUi::CProjectItem::[0]（func_names RTTI 名） |
| 0x141F19440 | NProject::NUi::CRecruitScientistWindow::[8] vtable 槽 NProject::NUi::CRecruitScientistWindow::[8]（func_names RTTI 名） |
| 0x14200BE00 | NInternationalMarket::CCancelSellingContractPopup::[0] vtable 槽 NInternationalMarket::CCancelSellingContractPopup::[0]（func_names RTTI 名） |
| 0x1413B1530 | NInternationalMarket::CRequestMarketAccessRightsAction::[56] vtable 槽 NInternationalMarket::CRequestMarketAccessRightsAction::[56]（func_names RTTI 名） |
| 0x141FFC410 | NInternationalMarket::CPurchasableEquipmentWindow::[12] vtable 槽 NInternationalMarket::CPurchasableEquipmentWindow::[12]（func_names RTTI 名） |
| 0x141610BD0 | NFactions::CAssumeFactionLeadershipAction::[58] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[58]（func_names RTTI 名） |
| 0x14160F640 | NFactions::CDismantleFactionAction::[59] vtable 槽 NFactions::CDismantleFactionAction::[59]（func_names RTTI 名） |
| 0x1404419A0 | NCareerProfile::CCheckMedal::ParseToken func_names 名 NCareerProfile::CCheckMedal::ParseToken |
| 0x14179F850 | NFactions::NUi::CFactionUiManager::[0] vtable 槽 NFactions::NUi::CFactionUiManager::[0]（func_names RTTI 名） |
| 0x1404A2D70 | NProject::CHasScientistSpecializationTrigger::GetDesc func_names 名 NProject::CHasScientistSpecializationTrigger::GetDesc |
| 0x141C02060 | NFactions::NUi::CKickFromFactionPopup::[14] vtable 槽 NFactions::NUi::CKickFromFactionPopup::[14]（func_names RTTI 名） |
| 0x141FD9EB0 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[0] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionEntry::[0]（func_names… |
| 0x1404973D0 | NProject::CCompleteProjectEffect::[23] vtable 槽 NProject::CCompleteProjectEffect::[23]（func_names RTTI 名） |
| 0x141AA66C0 | NInternationalMarket::CRequestEquipmentPurchaseAction::[57] vtable 槽 NInternationalMarket::CRequestEquipmentPurchaseAction::[57]（func_names RTTI 名） |
| 0x1404A46F0 | NRaids::CDamageRaidUnitEffect::[13] vtable 槽 NRaids::CDamageRaidUnitEffect::[13]（func_names RTTI 名） |
| 0x14200F9A0 | NAiNavalGoals::CCoastDefenseObjective::[6] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[6]（func_names RTTI 名） |
| 0x140A2D450 | NFactions::CFactionRule::[8] vtable 槽 NFactions::CFactionRule::[8]（func_names RTTI 名） |
| 0x1419C51F0 | NCareerProfile::CBasePopupWindow::[1] vtable 槽 NCareerProfile::CBasePopupWindow::[1]（func_names RTTI 名） |
| 0x14200C050 | NInternationalMarket::CMarketStockpileWindow::[12] vtable 槽 NInternationalMarket::CMarketStockpileWindow::[12]（func_names RTTI 名） |
| 0x141E88040 | NRaids::NUi::CRaidTargetMapIconEntry::[0] vtable 槽 NRaids::NUi::CRaidTargetMapIconEntry::[0]（func_names RTTI 名） |
| 0x14200F870 | NAiNavalGoals::CCoastDefenseObjective::[10] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[10]（func_names RTTI 名） |
| 0x141A326E0 | NOperativeMissions::CCountryBased::[16] vtable 槽 NOperativeMissions::CCountryBased::[16]（func_names RTTI 名） |
| 0x14052AB70 | NDoctrines::CUnlockCombatTacticEffect::GetDesc func_names 名 NDoctrines::CUnlockCombatTacticEffect::GetDesc |
| 0x141602110 | NFactions::CCreateFactionAction::[24] vtable 槽 NFactions::CCreateFactionAction::[24]（func_names RTTI 名） |
| 0x141CB02F0 | NProject::NUi::CFacilitiesTabView::[0] vtable 槽 NProject::NUi::CFacilitiesTabView::[0]（func_names RTTI 名） |
| 0x141688350 | NAirSelectionUI::CAirSelectionView::[0] vtable 槽 NAirSelectionUI::CAirSelectionView::[0]（func_names RTTI 名） |
| 0x1417C95B0 | NNotification::CLegacyMessagePopUpNotification::[0] vtable 槽 NNotification::CLegacyMessagePopUpNotification::[0]（func_names RTTI 名） |
| 0x141BA7BF0 | NFactions::CModifyFactionTheater::[0] vtable 槽 NFactions::CModifyFactionTheater::[0]（func_names RTTI 名） |
| 0x140300C20 | NIndustrialOrganisation::CSetDesignTeamChangeCostEffect::ResolveReferences func_names 名 NIndustrialOrganisation::CSetDesignTeamChangeCostEffect::ResolveRefer… |
| 0x140A2D860 | NFactions::CFactionRule::[4] vtable 槽 NFactions::CFactionRule::[4]（func_names RTTI 名） |
| 0x1414E91B0 | NRaids::CCountryRaidStatus::[0] vtable 槽 NRaids::CCountryRaidStatus::[0]（func_names RTTI 名） |
| 0x1416025D0 | NFactions::COfferJoinFactionAction::[24] vtable 槽 NFactions::COfferJoinFactionAction::[24]（func_names RTTI 名） |
| 0x140497E90 | NProject::CAddBreakthroughPoints::[4] vtable 槽 NProject::CAddBreakthroughPoints::[4]（func_names RTTI 名） |
| 0x140D7D6D0 | NDoctrines::CCountryDoctrineStatus::[0] vtable 槽 NDoctrines::CCountryDoctrineStatus::[0]（func_names RTTI 名） |
| 0x141BAE340 | NFactions::CSetFactionUpgradeCommand::PayloadReader func_names 名 NFactions::CSetFactionUpgradeCommand::PayloadReader |
| 0x141F625D0 | NAirSelectionUI::CRemoveFromGroupOption::[2] vtable 槽 NAirSelectionUI::CRemoveFromGroupOption::[2]（func_names RTTI 名） |
| 0x141F62D70 | NAirSelectionUI::CSplitSelectionButton::[2] vtable 槽 NAirSelectionUI::CSplitSelectionButton::[2]（func_names RTTI 名） |
| 0x141F60800 | NAirSelectionUI::CCreateAirGroupOption::[2] vtable 槽 NAirSelectionUI::CCreateAirGroupOption::[2]（func_names RTTI 名） |
| 0x140E75B10 | NProject::CProgramStatus::[1] vtable 槽 NProject::CProgramStatus::[1]（func_names RTTI 名） |
| 0x141EEE6D0 | NProject::NUi::CStartedResearchState::[0] vtable 槽 NProject::NUi::CStartedResearchState::[0]（func_names RTTI 名） |
| 0x14045A690 | NInternationalMarket::CDealCompletionTrigger::GetValue func_names 名 NInternationalMarket::CDealCompletionTrigger::GetValue |
| 0x142016540 | NProject::NUi::CDetailedOutputItem::[0] vtable 槽 NProject::NUi::CDetailedOutputItem::[0]（func_names RTTI 名） |
| 0x140498200 | NProject::CCompleteProjectEffect::[4] vtable 槽 NProject::CCompleteProjectEffect::[4]（func_names RTTI 名） |
| 0x142021600 | NIndustrialOrganisation::CDeleteQueuePopUp::[0] vtable 槽 NIndustrialOrganisation::CDeleteQueuePopUp::[0]（func_names RTTI 名） |
| 0x141B34F70 | NRaids::NUi::CRaidFeedbackView::[0] vtable 槽 NRaids::NUi::CRaidFeedbackView::[0]（func_names RTTI 名） |
| 0x14045A0E0 | NInternationalMarket::CBuyerTrigger::Evaluate func_names 名 NInternationalMarket::CBuyerTrigger::Evaluate |
| 0x142069080 | NInternationalMarket::CSubsidyDraft::[0] vtable 槽 NInternationalMarket::CSubsidyDraft::[0]（func_names RTTI 名） |
| 0x141602020 | NFactions::CAssumeFactionLeadershipAction::[24] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[24]（func_names RTTI 名） |
| 0x1413FA240 | NFactions::CFactionUpgradeStatus::[0] vtable 槽 NFactions::CFactionUpgradeStatus::[0]（func_names RTTI 名） |
| 0x141602210 | NFactions::CDismantleFactionAction::[24] vtable 槽 NFactions::CDismantleFactionAction::[24]（func_names RTTI 名） |
| 0x1419569F0 | NOperativeMissions::CControlTrade::[14] vtable 槽 NOperativeMissions::CControlTrade::[14]（func_names RTTI 名） |
| 0x14146D250 | NFactions::NUi::CFactionTheaterPopup::[0] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[0]（func_names RTTI 名） |
| 0x141FD6330 | NAirSelectionUI::CRocketWingsSelectionItem::[0] vtable 槽 NAirSelectionUI::CRocketWingsSelectionItem::[0]（func_names RTTI 名） |
| 0x141F9B060 | NAirSelectionUI::CEquipmentPriorityOption::[1] vtable 槽 NAirSelectionUI::CEquipmentPriorityOption::[1]（func_names RTTI 名） |
| 0x1413B0130 | NIndustrialOrganisation::CRandomIndustrialOrgEffect::ParseToken func_names 名 NIndustrialOrganisation::CRandomIndustrialOrgEffect::ParseToken |
| 0x1420073F0 | NInternationalMarket::CMarketAccessOverviewWindow::Update func_names 名 NInternationalMarket::CMarketAccessOverviewWindow::Update |
| 0x141ADD280 | NFactions::NUi::CFactionMemberCountriesWindow::[8] vtable 槽 NFactions::NUi::CFactionMemberCountriesWindow::[8]（func_names RTTI 名） |
| 0x1414443E0 | NProject::CProgram::Writer func_names 名 NProject::CProgram::Writer |
| 0x14045A330 | NInternationalMarket::CSellerTrigger::Evaluate func_names 名 NInternationalMarket::CSellerTrigger::Evaluate |
| 0x140441E20 | NCareerProfile::CVariableTrigger::ParseToken func_names 名 NCareerProfile::CVariableTrigger::ParseToken |
| 0x1403080F0 | NInternationalMarket::CRandomPurchaseContractEffect::ParseToken func_names 名 NInternationalMarket::CRandomPurchaseContractEffect::ParseToken |
| 0x14205EDD0 | NAirWingReorganizationUI::NInternal::CEquipmentEntry::[0] vtable 槽 NAirWingReorganizationUI::NInternal::CEquipmentEntry::[0]（func_names RTTI 名） |
| 0x141BAD870 | NFactions::CAddFactionGoalCommand::PayloadReader func_names 名 NFactions::CAddFactionGoalCommand::PayloadReader |
| 0x141C5A8A0 | NFactions::NUi::CFactionListWindow::[5] vtable 槽 NFactions::NUi::CFactionListWindow::[5]（func_names RTTI 名） |
| 0x140A28210 | NFactions::CFactionGoalDatabase::[0] vtable 槽 NFactions::CFactionGoalDatabase::[0]（func_names RTTI 名） |
| 0x14052BB60 | NDoctrines::CHasCombatTacticTrigger::Evaluate func_names 名 NDoctrines::CHasCombatTacticTrigger::Evaluate |
| 0x14201B320 | NCareerProfile::CRibbonDisplaySlot::[0] vtable 槽 NCareerProfile::CRibbonDisplaySlot::[0]（func_names RTTI 名） |
| 0x14201B200 | NCareerProfile::CMedalDisplaySlot::[0] vtable 槽 NCareerProfile::CMedalDisplaySlot::[0]（func_names RTTI 名） |
| 0x1402FB900 | NIndustrialOrganisation::CSetOrganisationNameKeyEffect::Execute func_names 名 NIndustrialOrganisation::CSetOrganisationNameKeyEffect::Execute |
| 0x1419E0320 | NOperativeMissions::CPropaganda::IsValid func_names 名 NOperativeMissions::CPropaganda::IsValid |
| 0x141FBEC80 | NIndustrialOrganisation::COrganisationTreeWindow::[0] vtable 槽 NIndustrialOrganisation::COrganisationTreeWindow::[0]（func_names RTTI 名） |
| 0x141823340 | NFactions::NUi::CFactionSetupWindow::ClearContents func_names 名 NFactions::NUi::CFactionSetupWindow::ClearContents |
| 0x1420131C0 | NAiNavalGoals::CNavalBlockadeObjective::[1] vtable 槽 NAiNavalGoals::CNavalBlockadeObjective::[1]（func_names RTTI 名） |
| 0x1404415E0 | NCareerProfile::CCheckRibbon::ValidateLate func_names 名 NCareerProfile::CCheckRibbon::ValidateLate |
| 0x140E75A10 | NProject::CProgram::[0] vtable 槽 NProject::CProgram::[0]（func_names RTTI 名） |
| 0x141F33C10 | NProject::NUi::CProjectHistoryRoster::[7] vtable 槽 NProject::NUi::CProjectHistoryRoster::[7]（func_names RTTI 名） |
| 0x141C5AA10 | NFactions::NUi::CFactionListItem::[0] vtable 槽 NFactions::NUi::CFactionListItem::[0]（func_names RTTI 名） |
| 0x141959050 | NOperativeMissions::CDiplomaticPressure::[12] vtable 槽 NOperativeMissions::CDiplomaticPressure::[12]（func_names RTTI 名） |
| 0x140FE9F90 | NRaids::CRaidInstance::[0] vtable 槽 NRaids::CRaidInstance::[0]（func_names RTTI 名） |
| 0x1419563B0 | NOperativeMissions::CControlTrade::[12] vtable 槽 NOperativeMissions::CControlTrade::[12]（func_names RTTI 名） |
| 0x1402FB6C0 | NIndustrialOrganisation::CSetIndustrialManufacturerAssignCostEf鈥�::[13] func_names 名 NIndustrialOrganisation::CSetIndustrialManufacturerAssignCostEf鈥�::[13] |
| 0x1416177E0 | NFactions::COfferJoinFactionAction::[57] vtable 槽 NFactions::COfferJoinFactionAction::[57]（func_names RTTI 名） |
| 0x1402FBB10 | NIndustrialOrganisation::CSetSizeUpRequirementFactorEffect::Execute func_names 名 NIndustrialOrganisation::CSetSizeUpRequirementFactorEffect::Execute |
| 0x1402FB1B0 | NIndustrialOrganisation::CSetDesignTeamAssignCostEffect::Execute func_names 名 NIndustrialOrganisation::CSetDesignTeamAssignCostEffect::Execute |
| 0x140CD8FF0 | NCombatLog::CStatsObserver::CActivityInGroup::[0] vtable 槽 NCombatLog::CStatsObserver::CActivityInGroup::[0]（func_names RTTI 名） |
| 0x1402FB9F0 | NIndustrialOrganisation::CSetResearchBonusEffect::Execute func_names 名 NIndustrialOrganisation::CSetResearchBonusEffect::Execute |
| 0x140A50690 | NIndustrialOrganisation::STraitId::Reader func_names 名 NIndustrialOrganisation::STraitId::Reader |
| 0x140FE3460 | NProject::CProject::[8] vtable 槽 NProject::CProject::[8]（func_names RTTI 名） |
| 0x14052BA80 | NDoctrines::CDoctrineTrackCompletedTrigger::Evaluate func_names 名 NDoctrines::CDoctrineTrackCompletedTrigger::Evaluate |
| 0x140A94360 | NProject::CProjectTemplate::[7] vtable 槽 NProject::CProjectTemplate::[7]（func_names RTTI 名） |
| 0x141B29620 | NRaids::NUi::CRaidFilter::[0] vtable 槽 NRaids::NUi::CRaidFilter::[0]（func_names RTTI 名） |
| 0x141C19810 | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x1419DF030 | NOperativeMissions::CPropaganda::GetEfficiency func_names 名 NOperativeMissions::CPropaganda::GetEfficiency |
| 0x140D94270 | NPdx::Z::SSparseArrayWriter<鈥�>::[1] func_names 名 NPdx::Z::SSparseArrayWriter<鈥�>::[1] |
| 0x14052BF90 | NDoctrines::CHasSubdoctrineInTrackTrigger::Evaluate func_names 名 NDoctrines::CHasSubdoctrineInTrackTrigger::Evaluate |
| 0x1402FB2E0 | NIndustrialOrganisation::CSetDesignTeamChangeCostEffect::Execute func_names 名 NIndustrialOrganisation::CSetDesignTeamChangeCostEffect::Execute |
| 0x141DED2C0 | NCareerProfile::CPlaythroughOverviewWindow::[0] vtable 槽 NCareerProfile::CPlaythroughOverviewWindow::[0]（func_names RTTI 名） |
| 0x140529CB0 | NDoctrines::CUnlockSubUnitEffect::Execute func_names 名 NDoctrines::CUnlockSubUnitEffect::Execute |
| 0x141B322F0 | NRaids::NNet::CSetRaidAutoLaunchOption::Clone func_names 名 NRaids::NNet::CSetRaidAutoLaunchOption::Clone |
| 0x141B32390 | NRaids::NNet::CSetRaidRiskLevelCommand::Clone func_names 名 NRaids::NNet::CSetRaidRiskLevelCommand::Clone |
| 0x1402FA630 | NIndustrialOrganisation::CAddAttachPolicyCostEffect::Execute func_names 名 NIndustrialOrganisation::CAddAttachPolicyCostEffect::Execute |
| 0x141B321B0 | NRaids::NNet::CRemoveRaidCommand::Clone func_names 名 NRaids::NNet::CRemoveRaidCommand::Clone |
| 0x141C23730 | NFactions::NUi::CIntelligenceAdvisorSlotItem::[0] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSlotItem::[0]（func_names RTTI 名） |
| 0x140301490 | NIndustrialOrganisation::CShowIndustrialOrgTooltip::ResolveReferences func_names 名 NIndustrialOrganisation::CShowIndustrialOrgTooltip::ResolveReferences |
| 0x140529980 | NDoctrines::CSetGrandDoctrineEffect::Execute func_names 名 NDoctrines::CSetGrandDoctrineEffect::Execute |
| 0x141B32250 | NRaids::NNet::CSetRaidAutoComplete::Clone func_names 名 NRaids::NNet::CSetRaidAutoComplete::Clone |
| 0x141C19660 | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x140BC8D70 | CVariables::Reader func_names 名 CVariables::Reader |
| 0x14052C890 | NDoctrines::CDoctrineTrackCompletedTrigger::GetDesc func_names 名 NDoctrines::CDoctrineTrackCompletedTrigger::GetDesc |
| 0x141A7BAD0 | NDoctrines::CUnlockSubDoctrineCommand::Clone func_names 名 NDoctrines::CUnlockSubDoctrineCommand::Clone |
| 0x141BA7DB0 | NFactions::CAddFactionGoalCommand::Clone func_names 名 NFactions::CAddFactionGoalCommand::Clone |
| 0x141CF3550 | NAirSelectionUI::CSelectedAirGroupsView::[0] vtable 槽 NAirSelectionUI::CSelectedAirGroupsView::[0]（func_names RTTI 名） |
| 0x140529BF0 | NDoctrines::CUnlockCombatTacticEffect::Execute func_names 名 NDoctrines::CUnlockCombatTacticEffect::Execute |
| 0x1403012C0 | NIndustrialOrganisation::CSetSizeUpRequirementFactorEffect::ResolveReferences func_names 名 NIndustrialOrganisation::CSetSizeUpRequirementFactorEffect::Resolv… |
| 0x140D91C10 | NFactions::CFactionSystem::[0] vtable 槽 NFactions::CFactionSystem::[0]（func_names RTTI 名） |
| 0x1414EA3B0 | NRaids::CCountryRaidStatus::Reader func_names 名 NRaids::CCountryRaidStatus::Reader |
| 0x141B32120 | NRaids::NNet::CExecuteRaidCommand::Clone func_names 名 NRaids::NNet::CExecuteRaidCommand::Clone |
| 0x141B31F60 | NRaids::NNet::CCancelRaidCommand::Clone func_names 名 NRaids::NNet::CCancelRaidCommand::Clone |
| 0x140300F10 | NIndustrialOrganisation::CSetFundsGainFactorEffect::ResolveReferences func_names 名 NIndustrialOrganisation::CSetFundsGainFactorEffect::ResolveReferences |
| 0x1403011E0 | NIndustrialOrganisation::CSetResearchBonusEffect::ResolveReferences func_names 名 NIndustrialOrganisation::CSetResearchBonusEffect::ResolveReferences |
| 0x1403013A0 | NIndustrialOrganisation::CSetTaskCapacityEffect::ResolveReferences func_names 名 NIndustrialOrganisation::CSetTaskCapacityEffect::ResolveReferences |
| 0x1404A2CC0 | NProject::CHasFacilitySpecializationTrigger::GetDesc func_names 名 NProject::CHasFacilitySpecializationTrigger::GetDesc |
| 0x1404A4870 | NRaids::CRaidAddUnitExperienceEffect::[13] vtable 槽 NRaids::CRaidAddUnitExperienceEffect::[13]（func_names RTTI 名） |
| 0x14052AAB0 | NDoctrines::CSetSubDoctrineEffect::GetDesc func_names 名 NDoctrines::CSetSubDoctrineEffect::GetDesc |
| 0x141ADD370 | NFactions::NUi::CInviteCountriesWindow::[10] vtable 槽 NFactions::NUi::CInviteCountriesWindow::[10]（func_names RTTI 名） |
| 0x1404A6330 | NRaids::CRaidAddUnitExperienceEffect::[23] vtable 槽 NRaids::CRaidAddUnitExperienceEffect::[23]（func_names RTTI 名） |
| 0x141BA87D0 | NFactions::CUpdateIntelligenceAdvisorSlotCommand::Clone func_names 名 NFactions::CUpdateIntelligenceAdvisorSlotCommand::Clone |
| 0x141B1BA50 | NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::Clone func_names 名 NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::Clone |
| 0x141BA8230 | NFactions::CFactionSetCommanderCommand::Clone func_names 名 NFactions::CFactionSetCommanderCommand::Clone |
| 0x140CE0580 | NCombatLog::CManager::Writer func_names 名 NCombatLog::CManager::Writer |
| 0x14202ED10 | NAirWingReorganizationUI::CAirWingReorganizationWindow::Update func_names 名 NAirWingReorganizationUI::CAirWingReorganizationWindow::Update |
| 0x141B1BDF0 | NInternationalMarket::CMarketStockpileEquipmentTransferCommand::Clone func_names 名 NInternationalMarket::CMarketStockpileEquipmentTransferCommand::Clone |
| 0x140A2A4B0 | NFactions::CFactionMemberUpgrade::[13] vtable 槽 NFactions::CFactionMemberUpgrade::[13]（func_names RTTI 名） |
| 0x14131A9D0 | NFactions::CSetFactionPingExecutionType::Clone func_names 名 NFactions::CSetFactionPingExecutionType::Clone |
| 0x141BA8190 | NFactions::CFactionAttachScientistCommand::Clone func_names 名 NFactions::CFactionAttachScientistCommand::Clone |
| 0x140441D50 | NCareerProfile::CCheckPoints::ParseToken func_names 名 NCareerProfile::CCheckPoints::ParseToken |
| 0x141BA8610 | NFactions::CSetFactionTheaterPinVisibility::Clone func_names 名 NFactions::CSetFactionTheaterPinVisibility::Clone |
| 0x1413B2050 | NInternationalMarket::CRequestMarketAccessRightsAction::[23] vtable 槽 NInternationalMarket::CRequestMarketAccessRightsAction::[23]（func_names RTTI 名） |
| 0x141ED2AA0 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[2] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[2] |
| 0x14052D300 | NDoctrines::CHasSubdoctrineInTrackTrigger::GetDesc func_names 名 NDoctrines::CHasSubdoctrineInTrackTrigger::GetDesc |
| 0x140A2A1A0 | NFactions::CFactionUpgrade::[11] vtable 槽 NFactions::CFactionUpgrade::[11]（func_names RTTI 名） |
| 0x14200F180 | NAiNavalGoals::CCoastDefenseObjective::[0] vtable 槽 NAiNavalGoals::CCoastDefenseObjective::[0]（func_names RTTI 名） |
| 0x141BA7EE0 | NFactions::CClearFactionTheater::Clone func_names 名 NFactions::CClearFactionTheater::Clone |
| 0x141F5F820 | NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[0] vtable 槽 NAirSelectionUI::NQuickWingDeployment::CPlaneTypeSelectionWindow::[0]（func_nam… |
| 0x1403003B0 | NIndustrialOrganisation::CUnlockPolicyTooltipEffect::GetDesc func_names 名 NIndustrialOrganisation::CUnlockPolicyTooltipEffect::GetDesc |
| 0x14147B640 | NDoctrines::STrackFilter::Writer func_names 名 NDoctrines::STrackFilter::Writer |
| 0x141BAE0B0 | NFactions::CModifyFactionTheater::PayloadReader func_names 名 NFactions::CModifyFactionTheater::PayloadReader |
| 0x141BA8740 | NFactions::CUnlockFolderDoctrineSharingCommand::Clone func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::Clone |
| 0x141BADE60 | NFactions::CFactionAttachScientistCommand::PayloadReader func_names 名 NFactions::CFactionAttachScientistCommand::PayloadReader |
| 0x140458F00 | NIndustrialOrganisation::CHasTraitTrigger::GetDesc func_names 名 NIndustrialOrganisation::CHasTraitTrigger::GetDesc |
| 0x141BA82D0 | NFactions::CFactionUnattachScientistCommand::Clone func_names 名 NFactions::CFactionUnattachScientistCommand::Clone |
| 0x141A7BA40 | NDoctrines::CUnlockGrandDoctrineCommand::Clone func_names 名 NDoctrines::CUnlockGrandDoctrineCommand::Clone |
| 0x14131AA60 | NFactions::CUseFactionMemberManpower::Clone func_names 名 NFactions::CUseFactionMemberManpower::Clone |
| 0x141BA7E50 | NFactions::CAddFactionProgramCommand::Clone func_names 名 NFactions::CAddFactionProgramCommand::Clone |
| 0x141BA8100 | NFactions::CEraseFactionRuleCommand::Clone func_names 名 NFactions::CEraseFactionRuleCommand::Clone |
| 0x141BA86B0 | NFactions::CSetFactionUpgradeCommand::Clone func_names 名 NFactions::CSetFactionUpgradeCommand::Clone |
| 0x140459820 | NIndustrialOrganisation::CHasIndustrialOrganisationTrigger::ValidateLate func_names 名 NIndustrialOrganisation::CHasIndustrialOrganisationTrigger::ValidateLate |
| 0x141BA8580 | NFactions::CSetFactionRuleCommand::Clone func_names 名 NFactions::CSetFactionRuleCommand::Clone |
| 0x14052ACD0 | NDoctrines::CUnlockSubUnitEffect::GetDesc func_names 名 NDoctrines::CUnlockSubUnitEffect::GetDesc |
| 0x1402F9760 | NIndustrialOrganisation::CUnlockIndustrialOrgTooltipEffect::ParseTargetToken func_names 名 NIndustrialOrganisation::CUnlockIndustrialOrgTooltipEffect::ParseTa… |
| 0x1402FFF60 | NIndustrialOrganisation::CTraitTooltipEffect::GetDesc func_names 名 NIndustrialOrganisation::CTraitTooltipEffect::GetDesc |
| 0x140300760 | NIndustrialOrganisation::CAddDesignTeamChangeCostEffect::ResolveReferences func_names 名 NIndustrialOrganisation::CAddDesignTeamChangeCostEffect::ResolveRefer… |
| 0x140A923D0 | NProject::CPrototypeRewardOption::Reader func_names 名 NProject::CPrototypeRewardOption::Reader |
| 0x14177CC30 | NEquipmentDesigner::CNicheIconListItem::[0] vtable 槽 NEquipmentDesigner::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x141EF7B40 | NCareerProfile::CCareerProfileView::[2] vtable 槽 NCareerProfile::CCareerProfileView::[2]（func_names RTTI 名） |
| 0x140160460 | NProject::CProjectDynamicModifierDatabase::[1] vtable 槽 NProject::CProjectDynamicModifierDatabase::[1]（func_names RTTI 名） |
| 0x14043E780 | NCareerProfile::CCheckPlaythroughRatio::Evaluate func_names 名 NCareerProfile::CCheckPlaythroughRatio::Evaluate |
| 0x14043E950 | NCareerProfile::CCheckRatio::Evaluate func_names 名 NCareerProfile::CCheckRatio::Evaluate |
| 0x141F0F2C0 | NProject::NUi::CProgramItem::[2] vtable 槽 NProject::NUi::CProgramItem::[2]（func_names RTTI 名） |
| 0x141952960 | NOperativeMissions::CBoostIdeology::GetEfficiency func_names 名 NOperativeMissions::CBoostIdeology::GetEfficiency |
| 0x14205C250 | NInternationalMarket::CMarketStockpileClearCommand::Clone func_names 名 NInternationalMarket::CMarketStockpileClearCommand::Clone |
| 0x141471850 | NFactions::NUi::CCountryFactionView::Reload func_names 名 NFactions::NUi::CCountryFactionView::Reload |
| 0x14045A7B0 | NInternationalMarket::CBuyerTrigger::GetDesc func_names 名 NInternationalMarket::CBuyerTrigger::GetDesc |
| 0x14118F590 | NPdx::Z::SSparseArrayWriter<鈥�>::[1] func_names 名 NPdx::Z::SSparseArrayWriter<鈥�>::[1] |
| 0x141BA83A0 | NFactions::CRemoveFactionProgramCommand::Clone func_names 名 NFactions::CRemoveFactionProgramCommand::Clone |
| 0x1406338F0 | NFactions::NAi::CAiFactionTheater::[4] vtable 槽 NFactions::NAi::CAiFactionTheater::[4]（func_names RTTI 名） |
| 0x141E2F2A0 | NFactions::NUi::CFactionIconWindow::[5] vtable 槽 NFactions::NUi::CFactionIconWindow::[5]（func_names RTTI 名） |
| 0x1414714F0 | NFactions::NUi::CCountryFactionView::[7] vtable 槽 NFactions::NUi::CCountryFactionView::[7]（func_names RTTI 名） |
| 0x141C00AE0 | NFactions::NUi::CFactionTheaterPopup::[16] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[16]（func_names RTTI 名） |
| 0x142012230 | NAiNavalGoals::CMineLayingObjective::[10] vtable 槽 NAiNavalGoals::CMineLayingObjective::[10]（func_names RTTI 名） |
| 0x140529180 | NDoctrines::CSetSubDoctrineEffect::ParseTargetToken func_names 名 NDoctrines::CSetSubDoctrineEffect::ParseTargetToken |
| 0x141F20D50 | NIndustrialOrganisation::CEquipmentIconItem::[0] vtable 槽 NIndustrialOrganisation::CEquipmentIconItem::[0]（func_names RTTI 名） |
| 0x141994760 | NFactions::CFactionRuleStatus::[0] vtable 槽 NFactions::CFactionRuleStatus::[0]（func_names RTTI 名） |
| 0x141CF3480 | NAirSelectionUI::CSelectedAirGroupView::[0] vtable 槽 NAirSelectionUI::CSelectedAirGroupView::[0]（func_names RTTI 名） |
| 0x140CDEBC0 | NCombatLog::SCombatData::Reader func_names 名 NCombatLog::SCombatData::Reader |
| 0x14052C180 | NDoctrines::CDoctrineTrackCompletedTrigger::ParseValueKeys func_names 名 NDoctrines::CDoctrineTrackCompletedTrigger::ParseValueKeys |
| 0x141B372D0 | NRaids::NUi::CRaidSimpleTextItem::[0] vtable 槽 NRaids::NUi::CRaidSimpleTextItem::[0]（func_names RTTI 名） |
| 0x14195C330 | NOperativeMissions::CRootOutResistance::IsValid func_names 名 NOperativeMissions::CRootOutResistance::IsValid |
| 0x140DF24C0 | NInternationalMarket::CPurchaseContract::[0] vtable 槽 NInternationalMarket::CPurchaseContract::[0]（func_names RTTI 名） |
| 0x141FB0B80 | NIndustrialOrganisation::CPolicyItem::[0] vtable 槽 NIndustrialOrganisation::CPolicyItem::[0]（func_names RTTI 名） |
| 0x141B1CA10 | NProject::NUi::CProgramView::Reload func_names 名 NProject::NUi::CProgramView::Reload |
| 0x142058F40 | NInternationalMarket::CAddToMarketEquipmentItem::[0] vtable 槽 NInternationalMarket::CAddToMarketEquipmentItem::[0]（func_names RTTI 名） |
| 0x1419546D0 | NOperativeMissions::CBuildIntelNetwork::GetEfficiency func_names 名 NOperativeMissions::CBuildIntelNetwork::GetEfficiency |
| 0x141956300 | NOperativeMissions::CControlTrade::[13] vtable 槽 NOperativeMissions::CControlTrade::[13]（func_names RTTI 名） |
| 0x141C07470 | NFactions::NUi::CChangeGoalWindow::[0] vtable 槽 NFactions::NUi::CChangeGoalWindow::[0]（func_names RTTI 名） |
| 0x14045ADF0 | NInternationalMarket::CSellerTrigger::GetDesc func_names 名 NInternationalMarket::CSellerTrigger::GetDesc |
| 0x140459470 | NIndustrialOrganisation::CIsTraitAvailableTrigger::GetDesc func_names 名 NIndustrialOrganisation::CIsTraitAvailableTrigger::GetDesc |
| 0x140459510 | NIndustrialOrganisation::CIsTraitUnlockedTrigger::GetDesc func_names 名 NIndustrialOrganisation::CIsTraitUnlockedTrigger::GetDesc |
| 0x140CE0BC0 | NCombatLog::SCombatData::Writer func_names 名 NCombatLog::SCombatData::Writer |
| 0x141A38A00 | NProject::SProjectContext::Writer func_names 名 NProject::SProjectContext::Writer |
| 0x141E3FCE0 | NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[0] func_names 名 NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[0] |
| 0x141611A90 | NFactions::CCreateFactionAction::GetEnableTrigger func_names 名 NFactions::CCreateFactionAction::GetEnableTrigger |
| 0x1404940C0 | NProject::CModifyProjectFlagEffect::[13] vtable 槽 NProject::CModifyProjectFlagEffect::[13]（func_names RTTI 名） |
| 0x1406416B0 | NIndustrialOrganisation::CTraitBonus::Reader func_names 名 NIndustrialOrganisation::CTraitBonus::Reader |
| 0x141F14A30 | NFactions::NUi::CChangeRuleItemPair::[0] vtable 槽 NFactions::NUi::CChangeRuleItemPair::[0]（func_names RTTI 名） |
| 0x14043E8C0 | NCareerProfile::CCheckPoints::Evaluate func_names 名 NCareerProfile::CCheckPoints::Evaluate |
| 0x14052C510 | NDoctrines::CHasSubdoctrineInTrackTrigger::ParseValueKeys func_names 名 NDoctrines::CHasSubdoctrineInTrackTrigger::ParseValueKeys |
| 0x140456890 | NIndustrialOrganisation::CHasEquipmentTypeTrigger::Evaluate func_names 名 NIndustrialOrganisation::CHasEquipmentTypeTrigger::Evaluate |
| 0x1406AA260 | NCareerProfile::SCareerProfileIntermediateStatistics::Writer func_names 名 NCareerProfile::SCareerProfileIntermediateStatistics::Writer |
| 0x14052BC50 | NDoctrines::CHasCompletedSubdoctrineTrigger::Evaluate func_names 名 NDoctrines::CHasCompletedSubdoctrineTrigger::Evaluate |
| 0x141FB7CB0 | NIndustrialOrganisation::CQueueToUnlockWindow::Reload func_names 名 NIndustrialOrganisation::CQueueToUnlockWindow::Reload |
| 0x1404598D0 | NIndustrialOrganisation::CHasPolicyTrigger::ValidateLate func_names 名 NIndustrialOrganisation::CHasPolicyTrigger::ValidateLate |
| 0x141600760 | NFactions::CCreateFactionAction::[0] vtable 槽 NFactions::CCreateFactionAction::[0]（func_names RTTI 名） |
| 0x140D94100 | NFactions::CFactionSystem::Reader func_names 名 NFactions::CFactionSystem::Reader |
| 0x141783AF0 | NEquipmentDesigner::CNicheIconListItem::[0] vtable 槽 NEquipmentDesigner::CNicheIconListItem::[0]（func_names RTTI 名） |
| 0x14043EA60 | NCareerProfile::CCheckValue::Evaluate func_names 名 NCareerProfile::CCheckValue::Evaluate |
| 0x14146CF90 | NFactions::NUi::CFactionGoalsSection::[0] vtable 槽 NFactions::NUi::CFactionGoalsSection::[0]（func_names RTTI 名） |
| 0x1415C7BE0 | NNavalCombatHit::SNavalHit::Reader func_names 名 NNavalCombatHit::SNavalHit::Reader |
| 0x140456F60 | NIndustrialOrganisation::CIsTraitAvailableTrigger::Evaluate func_names 名 NIndustrialOrganisation::CIsTraitAvailableTrigger::Evaluate |
| 0x14043E840 | NCareerProfile::CCheckPlaythroughValue::Evaluate func_names 名 NCareerProfile::CCheckPlaythroughValue::Evaluate |
| 0x142011EE0 | NAiNavalGoals::CMineLayingObjective::[0] vtable 槽 NAiNavalGoals::CMineLayingObjective::[0]（func_names RTTI 名） |
| 0x1406A15A0 | NCareerProfile::SCareerProfileMedalData::Reader func_names 名 NCareerProfile::SCareerProfileMedalData::Reader |
| 0x140CDE2A0 | NCombatLog::CManpowerLoss::Reader func_names 名 NCombatLog::CManpowerLoss::Reader |
| 0x141FBAE40 | NIndustrialOrganisation::CHistoryItem::[0] vtable 槽 NIndustrialOrganisation::CHistoryItem::[0]（func_names RTTI 名） |
| 0x140308570 | NInternationalMarket::CScriptEquipmentAmountEntry::Reader func_names 名 NInternationalMarket::CScriptEquipmentAmountEntry::Reader |
| 0x141796FA0 | NFactions::NUi::CFactionTheaterSwitch::[5] vtable 槽 NFactions::NUi::CFactionTheaterSwitch::[5]（func_names RTTI 名） |
| 0x141BAEE00 | NFactions::CModifyFactionTheater::PayloadWriter func_names 名 NFactions::CModifyFactionTheater::PayloadWriter |
| 0x140CD9180 | NCombatLog::CManager::[0] vtable 槽 NCombatLog::CManager::[0]（func_names RTTI 名） |
| 0x14043E650 | NCareerProfile::CNumOfPointsTrigger::[0] vtable 槽 NCareerProfile::CNumOfPointsTrigger::[0]（func_names RTTI 名） |
| 0x1419528D0 | NOperativeMissions::CBoostIdeology::Clone func_names 名 NOperativeMissions::CBoostIdeology::Clone |
| 0x1417B9160 | NInternationalMarket::CCountryInternationalMarketView::[0] vtable 槽 NInternationalMarket::CCountryInternationalMarketView::[0]（func_names RTTI 名） |
| 0x141CF0450 | NAirSelectionUI::NQuickWingDeployment::CQuickWingDeployUIContro鈥�::[1] func_names 名 NAirSelectionUI::NQuickWingDeployment::CQuickWingDeployUIContro鈥�::[1] |
| 0x141BADF40 | NFactions::CFactionSetCommanderCommand::PayloadReader func_names 名 NFactions::CFactionSetCommanderCommand::PayloadReader |
| 0x1402FB800 | NIndustrialOrganisation::CSetIndustrialOrgFlagEffect::Execute func_names 名 NIndustrialOrganisation::CSetIndustrialOrgFlagEffect::Execute |
| 0x1416F7EF0 | NDoctrines::CEntryButton::[1] vtable 槽 NDoctrines::CEntryButton::[1]（func_names RTTI 名） |
| 0x141B34650 | NRaids::NNet::CSetRaidAutoLaunchOption::PayloadReader func_names 名 NRaids::NNet::CSetRaidAutoLaunchOption::PayloadReader |
| 0x141E2F0A0 | NFactions::NUi::CFactionIconItem::[0] vtable 槽 NFactions::NUi::CFactionIconItem::[0]（func_names RTTI 名） |
| 0x140CE0650 | NCombatLog::CManpowerLoss::Writer func_names 名 NCombatLog::CManpowerLoss::Writer |
| 0x1413C6FF0 | NDoctrines::NUtils::SMasteryFromUnitLeader::Reader func_names 名 NDoctrines::NUtils::SMasteryFromUnitLeader::Reader |
| 0x140E86CC0 | NRaids::CRaidSystem::Writer func_names 名 NRaids::CRaidSystem::Writer |
| 0x141C2F280 | NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>::[0] func_names 名 NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>::[0] |
| 0x141B30B40 | NRaids::NUi::CRaidSetupView::Reload func_names 名 NRaids::NUi::CRaidSetupView::Reload |
| 0x14205ECD0 | NAirWingReorganizationUI::NInternal::CEquipmentEntry::[0] vtable 槽 NAirWingReorganizationUI::NInternal::CEquipmentEntry::[0]（func_names RTTI 名） |
| 0x14146D0C0 | NFactions::NUi::CFactionResearchSection::[0] vtable 槽 NFactions::NUi::CFactionResearchSection::[0]（func_names RTTI 名） |
| 0x140528EE0 | NDoctrines::CAddDailyMasteryEffect::[0] vtable 槽 NDoctrines::CAddDailyMasteryEffect::[0]（func_names RTTI 名） |
| 0x141B1C800 | NProject::NUi::CProgramView::[0] vtable 槽 NProject::NUi::CProgramView::[0]（func_names RTTI 名） |
| 0x140456C40 | NIndustrialOrganisation::CHasPolicyTrigger::Evaluate func_names 名 NIndustrialOrganisation::CHasPolicyTrigger::Evaluate |
| 0x141954650 | NOperativeMissions::CBuildIntelNetwork::Clone func_names 名 NOperativeMissions::CBuildIntelNetwork::Clone |
| 0x141A389A0 | NProject::SProjectHistory::Reader func_names 名 NProject::SProjectHistory::Reader |
| 0x140160190 | NIndustrialOrganisation::COrganisationDatabase::[1] vtable 槽 NIndustrialOrganisation::COrganisationDatabase::[1]（func_names RTTI 名） |
| 0x1419DEFB0 | NOperativeMissions::CPropaganda::Clone func_names 名 NOperativeMissions::CPropaganda::Clone |
| 0x1416174F0 | NFactions::CCreateFactionAction::[57] vtable 槽 NFactions::CCreateFactionAction::[57]（func_names RTTI 名） |
| 0x141C326C0 | NCountryStatTracking::CConstructedBuildingsTracker::[1] vtable 槽 NCountryStatTracking::CConstructedBuildingsTracker::[1]（func_names RTTI 名） |
| 0x14200DDC0 | NInternationalMarket::CMarketStockpileWindow::Update func_names 名 NInternationalMarket::CMarketStockpileWindow::Update |
| 0x1404A1960 | NProject::CHasFacilitySpecializationTrigger::Evaluate func_names 名 NProject::CHasFacilitySpecializationTrigger::Evaluate |
| 0x1404A1D50 | NProject::CHasScientistSpecializationTrigger::Evaluate func_names 名 NProject::CHasScientistSpecializationTrigger::Evaluate |
| 0x1416176C0 | NFactions::CKickFromFactionAction::[57] vtable 槽 NFactions::CKickFromFactionAction::[57]（func_names RTTI 名） |
| 0x140A31AE0 | NFriendsHandler::CFriend::[0] vtable 槽 NFriendsHandler::CFriend::[0]（func_names RTTI 名） |
| 0x141B346E0 | NRaids::NNet::CSetRaidRiskLevelCommand::PayloadReader func_names 名 NRaids::NNet::CSetRaidRiskLevelCommand::PayloadReader |
| 0x141BAD990 | NFactions::CAddFactionProgramCommand::PayloadReader func_names 名 NFactions::CAddFactionProgramCommand::PayloadReader |
| 0x141BAE270 | NFactions::CSetFactionPingExecutionType::PayloadReader func_names 名 NFactions::CSetFactionPingExecutionType::PayloadReader |
| 0x140308210 | NInternationalMarket::CAddEquipmentSubsidyEffect::ParseToken func_names 名 NInternationalMarket::CAddEquipmentSubsidyEffect::ParseToken |
| 0x142021580 | NUI::CScopedPopUp<CPopUpWindow>::[0] func_names 名 NUI::CScopedPopUp<CPopUpWindow>::[0] |
| 0x141953AB0 | NOperativeMissions::CBoostIdeology::IsValid func_names 名 NOperativeMissions::CBoostIdeology::IsValid |
| 0x14163B370 | NDoctrines::CCountryDoctrineView::Setup func_names 名 NDoctrines::CCountryDoctrineView::Setup |
| 0x1404A3B10 | NProject::CCanAssignFactionSupportiveScientistToFaction::Parse func_names 名 NProject::CCanAssignFactionSupportiveScientistToFaction::Parse |
| 0x141FBADB0 | NIndustrialOrganisation::CEquipmentTypeHeaderItem::[0] vtable 槽 NIndustrialOrganisation::CEquipmentTypeHeaderItem::[0]（func_names RTTI 名） |
| 0x141B34530 | NRaids::NNet::CRemoveRaidCommand::PayloadReader func_names 名 NRaids::NNet::CRemoveRaidCommand::PayloadReader |
| 0x14052BE10 | NDoctrines::CHasGrandDoctrineInFolderTrigger::Evaluate func_names 名 NDoctrines::CHasGrandDoctrineInFolderTrigger::Evaluate |
| 0x141B345C0 | NRaids::NNet::CSetRaidAutoComplete::PayloadReader func_names 名 NRaids::NNet::CSetRaidAutoComplete::PayloadReader |
| 0x141F199E0 | NProject::NUi::CRecruitScientistWindow::[10] vtable 槽 NProject::NUi::CRecruitScientistWindow::[10]（func_names RTTI 名） |
| 0x140493740 | NProject::CAddScientistXpEffect::[13] vtable 槽 NProject::CAddScientistXpEffect::[13]（func_names RTTI 名） |
| 0x141A355B0 | NProject::CProjectStateMachine::[0] vtable 槽 NProject::CProjectStateMachine::[0]（func_names RTTI 名） |
| 0x140CDEFA0 | NCombatLog::CStatsObserver::SDamageDone::Reader func_names 名 NCombatLog::CStatsObserver::SDamageDone::Reader |
| 0x141F149A0 | NFactions::NUi::CChangeRuleItem::[0] vtable 槽 NFactions::NUi::CChangeRuleItem::[0]（func_names RTTI 名） |
| 0x1406A16A0 | NCareerProfile::SCareerProfileStatistics::Reader func_names 名 NCareerProfile::SCareerProfileStatistics::Reader |
| 0x140ABB1C0 | NProject::CSpecializationTemplate::Reader func_names 名 NProject::CSpecializationTemplate::Reader |
| 0x1406A18C0 | NCareerProfile::SCareerProfileStatistics::SReadAdapterV1::Reader func_names 名 NCareerProfile::SCareerProfileStatistics::SReadAdapterV1::Reader |
| 0x14043ECF0 | NCareerProfile::CSetPlaythroughVariableTrigger::Evaluate func_names 名 NCareerProfile::CSetPlaythroughVariableTrigger::Evaluate |
| 0x14043ED80 | NCareerProfile::CSetVariableTrigger::Evaluate func_names 名 NCareerProfile::CSetVariableTrigger::Evaluate |
| 0x14045A2C0 | NInternationalMarket::CHasMarketAccessWithTrigger::Evaluate func_names 名 NInternationalMarket::CHasMarketAccessWithTrigger::Evaluate |
| 0x1406AD0A0 | NCareerProfile::CProfileBackgroundDatabase::[1] vtable 槽 NCareerProfile::CProfileBackgroundDatabase::[1]（func_names RTTI 名） |
| 0x141CCBCA0 | NCareerProfile::CFrontendCareerProfileView::Reload func_names 名 NCareerProfile::CFrontendCareerProfileView::Reload |
| 0x141F17EA0 | NProject::NUi::CScientistItem::[0] vtable 槽 NProject::NUi::CScientistItem::[0]（func_names RTTI 名） |
| 0x141993960 | NFactions::CFactionProgramStatus::Writer func_names 名 NFactions::CFactionProgramStatus::Writer |
| 0x140CDDF90 | NCombatLog::CEquipmentLoss::Reader func_names 名 NCombatLog::CEquipmentLoss::Reader |
| 0x14052D680 | NDoctrines::CHasDoctrineTrigger::ValidateLate func_names 名 NDoctrines::CHasDoctrineTrigger::ValidateLate |
| 0x141959E10 | NOperativeMissions::CQuietIntelNetwork::Clone func_names 名 NOperativeMissions::CQuietIntelNetwork::Clone |
| 0x14195AE90 | NOperativeMissions::CRootOutResistance::Clone func_names 名 NOperativeMissions::CRootOutResistance::Clone |
| 0x14146D420 | NFactions::NUi::CInviteToFactionPopup::[0] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[0]（func_names RTTI 名） |
| 0x1406A1770 | NCareerProfile::SPlaythroughCountryData::Reader func_names 名 NCareerProfile::SPlaythroughCountryData::Reader |
| 0x14163ACD0 | NDoctrines::CCountryDoctrineView::ClearContents func_names 名 NDoctrines::CCountryDoctrineView::ClearContents |
| 0x141BE5FF0 | NFactions::CDoctrineSharingStatus::Writer func_names 名 NFactions::CDoctrineSharingStatus::Writer |
| 0x141591BC0 | NRaids::CRaidSuccessLevels::Reader func_names 名 NRaids::CRaidSuccessLevels::Reader |
| 0x14147BA60 | NDoctrines::STemporaryMasteryGain::Reader func_names 名 NDoctrines::STemporaryMasteryGain::Reader |
| 0x141BAF0F0 | NFactions::CUpdateIntelligenceAdvisorSlotCommand::PayloadWriter func_names 名 NFactions::CUpdateIntelligenceAdvisorSlotCommand::PayloadWriter |
| 0x14052D5E0 | NDoctrines::CHasMasteryLevelTrigger::Validate func_names 名 NDoctrines::CHasMasteryLevelTrigger::Validate |
| 0x141BAE150 | NFactions::CRemoveFactionProgramCommand::PayloadReader func_names 名 NFactions::CRemoveFactionProgramCommand::PayloadReader |
| 0x1419D72B0 | NInternationalMarket::CEquipmentConvoyClient::Reader func_names 名 NInternationalMarket::CEquipmentConvoyClient::Reader |
| 0x14052D630 | NDoctrines::CMasteryTrigger::Validate func_names 名 NDoctrines::CMasteryTrigger::Validate |
| 0x140457020 | NIndustrialOrganisation::CIsTraitUnlockedTrigger::Evaluate func_names 名 NIndustrialOrganisation::CIsTraitUnlockedTrigger::Evaluate |
| 0x141BAEF90 | NFactions::CSetFactionPingExecutionType::PayloadWriter func_names 名 NFactions::CSetFactionPingExecutionType::PayloadWriter |
| 0x140441F00 | NCareerProfile::CCheckMedal::STooltips::Reader func_names 名 NCareerProfile::CCheckMedal::STooltips::Reader |
| 0x141C209F0 | NProject::NUi::CScientistList::Reload func_names 名 NProject::NUi::CScientistList::Reload |
| 0x140459C20 | NIndustrialOrganisation::CIsTraitAvailableTrigger::ParseToken func_names 名 NIndustrialOrganisation::CIsTraitAvailableTrigger::ParseToken |
| 0x141BE5E90 | NFactions::CDoctrineSharingStatus::Reader func_names 名 NFactions::CDoctrineSharingStatus::Reader |
| 0x141CB1C00 | NProject::NUi::CProjectHistoryRoster::Reload func_names 名 NProject::NUi::CProjectHistoryRoster::Reload |
| 0x141CB1C70 | NProject::NUi::CProjectSimpleRoster::Reload func_names 名 NProject::NUi::CProjectSimpleRoster::Reload |
| 0x140CE11D0 | NCombatLog::CStatsObserver::SDamageDone::Writer func_names 名 NCombatLog::CStatsObserver::SDamageDone::Writer |
| 0x1414717E0 | NFactions::NUi::CAssignResearchFacilityWindow::Reload func_names 名 NFactions::NUi::CAssignResearchFacilityWindow::Reload |
| 0x1402FB8C0 | NIndustrialOrganisation::CSetOrganisationIconEffect::Execute func_names 名 NIndustrialOrganisation::CSetOrganisationIconEffect::Execute |
| 0x140A6D230 | NInlayWindowScript::SButton::Reader func_names 名 NInlayWindowScript::SButton::Reader |
| 0x141483890 | NProject::CProjectPool::Writer func_names 名 NProject::CProjectPool::Writer |
| 0x1415C7CD0 | NNavalCombatHit::SNavalHit::Writer func_names 名 NNavalCombatHit::SNavalHit::Writer |
| 0x141A7D090 | NDoctrines::CUnlockSubDoctrineCommand::PayloadWriter func_names 名 NDoctrines::CUnlockSubDoctrineCommand::PayloadWriter |
| 0x141BAEA20 | NFactions::CAddFactionGoalCommand::PayloadWriter func_names 名 NFactions::CAddFactionGoalCommand::PayloadWriter |
| 0x1402F9660 | NIndustrialOrganisation::CUnlockTraitEffect::[0] vtable 槽 NIndustrialOrganisation::CUnlockTraitEffect::[0]（func_names RTTI 名） |
| 0x141BAE1C0 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadReader func_names 名 NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadReader |
| 0x141AA4CC0 | NInternationalMarket::CCancelEquipmentPurchaseAction::[23] vtable 槽 NInternationalMarket::CCancelEquipmentPurchaseAction::[23]（func_names RTTI 名） |
| 0x14163AD30 | NDoctrines::CCountryDoctrineView::PreSetup func_names 名 NDoctrines::CCountryDoctrineView::PreSetup |
| 0x140CDE000 | NCombatLog::CLoss::Reader func_names 名 NCombatLog::CLoss::Reader |
| 0x14160CEF0 | NFactions::CKickFromFactionAction::GetAiAcceptance func_names 名 NFactions::CKickFromFactionAction::GetAiAcceptance |
| 0x141BAE220 | NFactions::CSetFactionIconAndColor::PayloadReader func_names 名 NFactions::CSetFactionIconAndColor::PayloadReader |
| 0x1414EB1F0 | NRaids::CRaidTargetCooldownStatus::Writer func_names 名 NRaids::CRaidTargetCooldownStatus::Writer |
| 0x141B1C340 | NInternationalMarket::CMarketStockpileEquipmentTransferCommand::PayloadReader func_names 名 NInternationalMarket::CMarketStockpileEquipmentTransferCommand::Pa… |
| 0x14147BB40 | NDoctrines::STemporaryMasteryGain::Writer func_names 名 NDoctrines::STemporaryMasteryGain::Writer |
| 0x141BADA20 | NFactions::CClearFactionTheater::PayloadReader func_names 名 NFactions::CClearFactionTheater::PayloadReader |
| 0x1406A1720 | NCareerProfile::SGameModeStatistics::Reader func_names 名 NCareerProfile::SGameModeStatistics::Reader |
| 0x141B38060 | NRaids::NUi::CRaidUnitItem::[0] vtable 槽 NRaids::NUi::CRaidUnitItem::[0]（func_names RTTI 名） |
| 0x141E3FD70 | NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[3] func_names 名 NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[3] |
| 0x14147BAD0 | NDoctrines::STemporaryCostReduction::Writer func_names 名 NDoctrines::STemporaryCostReduction::Writer |
| 0x141529A30 | NDoctrines::SDoctrineEquipmentBonusHandle::Reader func_names 名 NDoctrines::SDoctrineEquipmentBonusHandle::Reader |
| 0x1415C7C60 | NNavalCombatHit::SAirHit::Writer func_names 名 NNavalCombatHit::SAirHit::Writer |
| 0x140641810 | NIndustrialOrganisation::CTraitBonus::Writer func_names 名 NIndustrialOrganisation::CTraitBonus::Writer |
| 0x140456CD0 | NIndustrialOrganisation::CHasTraitTrigger::Evaluate func_names 名 NIndustrialOrganisation::CHasTraitTrigger::Evaluate |
| 0x140441DE0 | NCareerProfile::CCheckRibbon::ParseToken func_names 名 NCareerProfile::CCheckRibbon::ParseToken |
| 0x141BAED40 | NFactions::CFactionSetCommanderCommand::PayloadWriter func_names 名 NFactions::CFactionSetCommanderCommand::PayloadWriter |
| 0x14146D150 | NFactions::NUi::CFactionRulesSection::[0] vtable 槽 NFactions::NUi::CFactionRulesSection::[0]（func_names RTTI 名） |
| 0x1402FABD0 | NIndustrialOrganisation::CAddTaskCapacityEffect::Execute func_names 名 NIndustrialOrganisation::CAddTaskCapacityEffect::Execute |
| 0x14052B4C0 | NDoctrines::CAddMasteryBonusEffect::ParseToken func_names 名 NDoctrines::CAddMasteryBonusEffect::ParseToken |
| 0x1406AC310 | NCareerProfile::CCareerProfileMedal::CTierColors::Reader func_names 名 NCareerProfile::CCareerProfileMedal::CTierColors::Reader |
| 0x14052B470 | NDoctrines::CAddDailyMasteryEffect::ParseToken func_names 名 NDoctrines::CAddDailyMasteryEffect::ParseToken |
| 0x141BAE2F0 | NFactions::CSetFactionTheaterPinVisibility::PayloadReader func_names 名 NFactions::CSetFactionTheaterPinVisibility::PayloadReader |
| 0x142058FE0 | NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[0] func_names 名 NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[0] |
| 0x1417AD110 | NCareerProfile::CBasePopupWindow::Teardown func_names 名 NCareerProfile::CBasePopupWindow::Teardown |
| 0x1417B98A0 | NInternationalMarket::CCountryInternationalMarketView::ClearContents func_names 名 NInternationalMarket::CCountryInternationalMarketView::ClearContents |
| 0x1404A19E0 | NProject::CHasProjectFlagTrigger::Evaluate func_names 名 NProject::CHasProjectFlagTrigger::Evaluate |
| 0x140456D10 | NIndustrialOrganisation::CIndustrialOrgFlagTrigger::Evaluate func_names 名 NIndustrialOrganisation::CIndustrialOrgFlagTrigger::Evaluate |
| 0x140456D90 | NIndustrialOrganisation::CIsOrganisationAvailableTrigger::Evaluate func_names 名 NIndustrialOrganisation::CIsOrganisationAvailableTrigger::Evaluate |
| 0x14043E740 | NCareerProfile::CCheckMedal::Evaluate func_names 名 NCareerProfile::CCheckMedal::Evaluate |
| 0x140458FE0 | NIndustrialOrganisation::CIsOrganisationAvailableTrigger::GetDesc func_names 名 NIndustrialOrganisation::CIsOrganisationAvailableTrigger::GetDesc |
| 0x140458FA0 | NIndustrialOrganisation::CIsAssignedToTaskTrigger::GetDesc func_names 名 NIndustrialOrganisation::CIsAssignedToTaskTrigger::GetDesc |
| 0x142059E70 | NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[1] func_names 名 NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[1] |
| 0x14052B510 | NDoctrines::CAddMasteryEffect::ParseToken func_names 名 NDoctrines::CAddMasteryEffect::ParseToken |
| 0x1406A1660 | NCareerProfile::SCareerProfileRibbonData::Reader func_names 名 NCareerProfile::SCareerProfileRibbonData::Reader |
| 0x140459430 | NIndustrialOrganisation::CIsOrganisationVisibleTrigger::GetDesc func_names 名 NIndustrialOrganisation::CIsOrganisationVisibleTrigger::GetDesc |
| 0x140A4C3A0 | NIndustrialOrganisation::STreeFlavorText::Reader func_names 名 NIndustrialOrganisation::STreeFlavorText::Reader |
| 0x140301880 | NIndustrialOrganisation::CUnlockPolicyTooltipEffect::ParseToken func_names 名 NIndustrialOrganisation::CUnlockPolicyTooltipEffect::ParseToken |
| 0x14043EA10 | NCareerProfile::CCheckRibbon::Evaluate func_names 名 NCareerProfile::CCheckRibbon::Evaluate |
| 0x141A38AC0 | NProject::SProjectHistory::Writer func_names 名 NProject::SProjectHistory::Writer |
| 0x141983110 | NWarScoreDistributionHelper::SRedistribution::Reader func_names 名 NWarScoreDistributionHelper::SRedistribution::Reader |
| 0x140DBB840 | NIndustrialOrganisation::SHistoryWithEquipment::Reader func_names 名 NIndustrialOrganisation::SHistoryWithEquipment::Reader |
| 0x1419D7490 | NInternationalMarket::CEquipmentConvoyClient::Writer func_names 名 NInternationalMarket::CEquipmentConvoyClient::Writer |
| 0x141BAE9A0 | NFactions::CUseFactionMemberManpower::PayloadReader func_names 名 NFactions::CUseFactionMemberManpower::PayloadReader |
| 0x1406AA780 | NCareerProfile::SPlaythroughCountryData::Writer func_names 名 NCareerProfile::SPlaythroughCountryData::Writer |
| 0x140A92630 | NProject::CPrototypeReward::SThreshold::Reader func_names 名 NProject::CPrototypeReward::SThreshold::Reader |
| 0x1402FA760 | NIndustrialOrganisation::CAddDesignTeamAssignCostEffect::Execute func_names 名 NIndustrialOrganisation::CAddDesignTeamAssignCostEffect::Execute |
| 0x1402FA7A0 | NIndustrialOrganisation::CAddDesignTeamChangeCostEffect::Execute func_names 名 NIndustrialOrganisation::CAddDesignTeamChangeCostEffect::Execute |
| 0x1402FA950 | NIndustrialOrganisation::CAddFundsGainFactorEffect::Execute func_names 名 NIndustrialOrganisation::CAddFundsGainFactorEffect::Execute |
| 0x1402FA990 | NIndustrialOrganisation::CAddIndustrialManufacturerAssignCostEf鈥�::[13] func_names 名 NIndustrialOrganisation::CAddIndustrialManufacturerAssignCostEf鈥�::[13] |
| 0x1402FA9D0 | NIndustrialOrganisation::CAddResearchBonusEffect::Execute func_names 名 NIndustrialOrganisation::CAddResearchBonusEffect::Execute |
| 0x1402FAB90 | NIndustrialOrganisation::CAddSizeUpRequirementFactorEffect::Execute func_names 名 NIndustrialOrganisation::CAddSizeUpRequirementFactorEffect::Execute |
| 0x141BAECE0 | NFactions::CFactionAttachScientistCommand::PayloadWriter func_names 名 NFactions::CFactionAttachScientistCommand::PayloadWriter |
| 0x141CF0640 | NAirSelectionUI::NQuickWingDeployment::CQuickWingDeployUIContro鈥�::[2] func_names 名 NAirSelectionUI::NQuickWingDeployment::CQuickWingDeployUIContro鈥�::[2] |
| 0x140CE0940 | NCombatLog::COrdersGroupLogs::CPerTemplateStats::Writer func_names 名 NCombatLog::COrdersGroupLogs::CPerTemplateStats::Writer |
| 0x1404A1E90 | NProject::CIsScientistInjured::Evaluate func_names 名 NProject::CIsScientistInjured::Evaluate |
| 0x142059040 | NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[1] func_names 名 NInternationalMarket::CAddEquipmentToMarketWindow::CCountryEqui鈥�::[1] |
| 0x1402E30B0 | NCareerProfile::CStepMissiolinis::Execute func_names 名 NCareerProfile::CStepMissiolinis::Execute |
| 0x1402FAC40 | NIndustrialOrganisation::CClearIndustrialOrgFlagEffect::Execute func_names 名 NIndustrialOrganisation::CClearIndustrialOrgFlagEffect::Execute |
| 0x141616640 | NFactions::CKickFromFactionAction::CanExecute func_names 名 NFactions::CKickFromFactionAction::CanExecute |
| 0x1404A1E50 | NProject::CIsScientistActiveTrigger::Evaluate func_names 名 NProject::CIsScientistActiveTrigger::Evaluate |
| 0x141BAF050 | NFactions::CSetFactionUpgradeCommand::PayloadWriter func_names 名 NFactions::CSetFactionUpgradeCommand::PayloadWriter |
| 0x141BAF0A0 | NFactions::CUnlockFolderDoctrineSharingCommand::PayloadWriter func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::PayloadWriter |
| 0x141E3FD30 | NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[2] func_names 名 NPdxScopedPtrInternal::$0A::VCSetOperativeMissionCommand::U?$SD鈥�::[2] |
| 0x1404A1DE0 | NProject::CIsProjectBeingResearchedTrigger::Evaluate func_names 名 NProject::CIsProjectBeingResearchedTrigger::Evaluate |
| 0x141B348F0 | NRaids::NNet::CRemoveRaidCommand::PayloadWriter func_names 名 NRaids::NNet::CRemoveRaidCommand::PayloadWriter |
| 0x141B34950 | NRaids::NNet::CSetRaidAutoComplete::PayloadWriter func_names 名 NRaids::NNet::CSetRaidAutoComplete::PayloadWriter |
| 0x141BE6520 | NFactions::CTechnologySharingFaction::Reader func_names 名 NFactions::CTechnologySharingFaction::Reader |
| 0x140A4BE20 | NIndustrialOrganisation::CPolicy::Reader func_names 名 NIndustrialOrganisation::CPolicy::Reader |
| 0x140E86AB0 | NRaids::CRaidSystem::Reader func_names 名 NRaids::CRaidSystem::Reader |
| 0x141A05A90 | NProject::CProgramConsumer::Reader func_names 名 NProject::CProgramConsumer::Reader |
| 0x141B1B970 | NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand::PayloadReader func_names 名 NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand… |
| 0x141B1BB90 | NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::PayloadReader func_names 名 NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::… |
| 0x1406A1620 | NCareerProfile::SCareerProfileModDataSet::Reader func_names 名 NCareerProfile::SCareerProfileModDataSet::Reader |
| 0x141B349B0 | NRaids::NNet::CSetRaidAutoLaunchOption::PayloadWriter func_names 名 NRaids::NNet::CSetRaidAutoLaunchOption::PayloadWriter |
| 0x14204A570 | NInternationalMarket::CPurchaseDraftWindow::Update func_names 名 NInternationalMarket::CPurchaseDraftWindow::Update |
| 0x1404A1930 | NProject::CHasBreakthroughPointsTrigger::Evaluate func_names 名 NProject::CHasBreakthroughPointsTrigger::Evaluate |
| 0x140A6D270 | NInlayWindowScript::SProgressbar::Reader func_names 名 NInlayWindowScript::SProgressbar::Reader |
| 0x140CDEF60 | NCombatLog::COrdersGroupLogs::SCombatStats::Reader func_names 名 NCombatLog::COrdersGroupLogs::SCombatStats::Reader |
| 0x140CDF000 | NCombatLog::CStatsObserver::SCombatSideData::SModifierHours::Reader func_names 名 NCombatLog::CStatsObserver::SCombatSideData::SModifierHours::Reader |
| 0x141B34A10 | NRaids::NNet::CSetRaidRiskLevelCommand::PayloadWriter func_names 名 NRaids::NNet::CSetRaidRiskLevelCommand::PayloadWriter |
| 0x14146CBD0 | NProject::NUi::CFilterEntryItem<鈥�>::[0] func_names 名 NProject::NUi::CFilterEntryItem<鈥�>::[0] |
| 0x14052C200 | NDoctrines::CHasCompletedSubdoctrineTrigger::ParseValueKeys func_names 名 NDoctrines::CHasCompletedSubdoctrineTrigger::ParseValueKeys |
| 0x141BAF000 | NFactions::CSetFactionTheaterPinVisibility::PayloadWriter func_names 名 NFactions::CSetFactionTheaterPinVisibility::PayloadWriter |
| 0x1417BA110 | NInternationalMarket::CCountryInternationalMarketView::Setup func_names 名 NInternationalMarket::CCountryInternationalMarketView::Setup |
| 0x1406AA370 | NCareerProfile::SCareerProfileMedalData::Writer func_names 名 NCareerProfile::SCareerProfileMedalData::Writer |
| 0x141B1BBD0 | NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::PayloadWriter func_names 名 NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::… |
| 0x141B1B9B0 | NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand::PayloadWriter func_names 名 NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand… |
| 0x141A7D040 | NDoctrines::CUnlockGrandDoctrineCommand::PayloadWriter func_names 名 NDoctrines::CUnlockGrandDoctrineCommand::PayloadWriter |
| 0x1404A1E20 | NProject::CIsProjectCompletedTrigger::Evaluate func_names 名 NProject::CIsProjectCompletedTrigger::Evaluate |
| 0x140CE04F0 | NCombatLog::CEquipmentLoss::Writer func_names 名 NCombatLog::CEquipmentLoss::Writer |
| 0x140A91E60 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x140A91E90 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x140A91EC0 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x140AD29F0 | NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] func_names 名 NDlcLocked::$00::Z::SUniformReader<鈥�>::[3] |
| 0x14147AB30 | NDoctrines::STrackFilter::Reader func_names 名 NDoctrines::STrackFilter::Reader |
| 0x140DBD140 | NIndustrialOrganisation::SHistoryWithEquipment::Writer func_names 名 NIndustrialOrganisation::SHistoryWithEquipment::Writer |
| 0x141A05AD0 | NProject::CProgramConsumer::Writer func_names 名 NProject::CProgramConsumer::Writer |
| 0x140459C00 | NIndustrialOrganisation::CCheckNumberOfUnlockedTraitsTrigger::ParseToken func_names 名 NIndustrialOrganisation::CCheckNumberOfUnlockedTraitsTrigger::ParseToken |
| 0x1406AA7F0 | NCareerProfile::SProfileData::Writer func_names 名 NCareerProfile::SProfileData::Writer |
| 0x142007E40 | NInternationalMarket::CRequestAutomationOptionsWindow::Update func_names 名 NInternationalMarket::CRequestAutomationOptionsWindow::Update |
| 0x141BAEAE0 | NFactions::CClearFactionTheater::PayloadWriter func_names 名 NFactions::CClearFactionTheater::PayloadWriter |
| 0x140459B30 | NIndustrialOrganisation::CCheckNumberOfUnlockedTraitsTrigger::Parse func_names 名 NIndustrialOrganisation::CCheckNumberOfUnlockedTraitsTrigger::Parse |
| 0x141B1C390 | NInternationalMarket::CMarketStockpileEquipmentTransferCommand::PayloadWriter func_names 名 NInternationalMarket::CMarketStockpileEquipmentTransferCommand::Pa… |
| 0x140A4C0F0 | NIndustrialOrganisation::CPolicy::Writer func_names 名 NIndustrialOrganisation::CPolicy::Writer |
| 0x141BE6800 | NFactions::CTechnologySharingFaction::Writer func_names 名 NFactions::CTechnologySharingFaction::Writer |
| 0x140CE1190 | NCombatLog::COrdersGroupLogs::SCombatStats::Writer func_names 名 NCombatLog::COrdersGroupLogs::SCombatStats::Writer |
| 0x140CE1250 | NCombatLog::CStatsObserver::SCombatSideData::SModifierHours::Writer func_names 名 NCombatLog::CStatsObserver::SCombatSideData::SModifierHours::Writer |
| 0x141BAEF40 | NFactions::CSetFactionIconAndColor::PayloadWriter func_names 名 NFactions::CSetFactionIconAndColor::PayloadWriter |
| 0x1413C7390 | NDoctrines::NUtils::SMasteryFromUnitLeader::Writer func_names 名 NDoctrines::NUtils::SMasteryFromUnitLeader::Writer |
| 0x140456F30 | NIndustrialOrganisation::CIsOrganisationVisibleTrigger::Evaluate func_names 名 NIndustrialOrganisation::CIsOrganisationVisibleTrigger::Evaluate |
| 0x140A51170 | NIndustrialOrganisation::STraitId::Writer func_names 名 NIndustrialOrganisation::STraitId::Writer |
| 0x141B2A4B0 | NRaids::NUi::CRaidFilter::Reload func_names 名 NRaids::NUi::CRaidFilter::Reload |
| 0x141FC15D0 | NIndustrialOrganisation::CTraitTree::PreSetup func_names 名 NIndustrialOrganisation::CTraitTree::PreSetup |
| 0x140456CA0 | NIndustrialOrganisation::CHasResearchCategoryTrigger::Evaluate func_names 名 NIndustrialOrganisation::CHasResearchCategoryTrigger::Evaluate |
| 0x141529F40 | NDoctrines::SDoctrineEquipmentBonusHandle::Writer func_names 名 NDoctrines::SDoctrineEquipmentBonusHandle::Writer |
| 0x141BAEF00 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadWriter func_names 名 NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadWriter |
| 0x140457180 | NIndustrialOrganisation::CHasPolicyTrigger::ParseValueKeys func_names 名 NIndustrialOrganisation::CHasPolicyTrigger::ParseValueKeys |
| 0x141611A50 | NFactions::CAssumeFactionLeadershipAction::GetCostText func_names 名 NFactions::CAssumeFactionLeadershipAction::GetCostText |
| 0x141950D50 | NFactions::CFactionTheaterManager::Reader func_names 名 NFactions::CFactionTheaterManager::Reader |
| 0x14205C370 | NInternationalMarket::CMarketStockpileClearCommand::PayloadReader func_names 名 NInternationalMarket::CMarketStockpileClearCommand::PayloadReader |
| 0x1419935C0 | NFactions::CFactionProgramStatus::Reader func_names 名 NFactions::CFactionProgramStatus::Reader |
| 0x141BAEA90 | NFactions::CAddFactionProgramCommand::PayloadWriter func_names 名 NFactions::CAddFactionProgramCommand::PayloadWriter |
| 0x141A32890 | NOperativeMissions::CCountryBased::Reader func_names 名 NOperativeMissions::CCountryBased::Reader |
| 0x141995A40 | NFactions::CFactionRuleStatus::Reader func_names 名 NFactions::CFactionRuleStatus::Reader |
| 0x140459C60 | NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[25] vtable 槽 NIndustrialOrganisation::CAnyIndustrialOrgTrigger::[25]（func_names RTTI 名） |
| 0x140CE0540 | NCombatLog::CLoss::Writer func_names 名 NCombatLog::CLoss::Writer |
| 0x141BAF150 | NFactions::CUseFactionMemberManpower::PayloadWriter func_names 名 NFactions::CUseFactionMemberManpower::PayloadWriter |
| 0x1418249F0 | NFactions::NUi::CFactionSetupWindow::PreSetup func_names 名 NFactions::NUi::CFactionSetupWindow::PreSetup |
| 0x14203DDF0 | NInternationalMarket::CSubsidyOverview::Update func_names 名 NInternationalMarket::CSubsidyOverview::Update |
| 0x141F8BD00 | NInternationalMarket::CMarketOverviewPanelController::OnFilterC鈥�::[0] func_names 名 NInternationalMarket::CMarketOverviewPanelController::OnFilterC鈥�::[0] |
| 0x141ED1580 | NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[0] func_names 名 NAiNavalGoals::CObjectiveTypeTracker<鈥�>::[0] |
| 0x1406AA400 | NCareerProfile::SCareerProfileRibbonData::Writer func_names 名 NCareerProfile::SCareerProfileRibbonData::Writer |
| 0x14045A440 | NInternationalMarket::CContractContainsEquipmentTrigger::ParseValueKeys func_names 名 NInternationalMarket::CContractContainsEquipmentTrigger::ParseValueKeys |
| 0x1406AA3C0 | NCareerProfile::SCareerProfileModDataSet::Writer func_names 名 NCareerProfile::SCareerProfileModDataSet::Writer |
| 0x141951C80 | NFactions::CFactionTheaterManager::Writer func_names 名 NFactions::CFactionTheaterManager::Writer |
| 0x14200DDA0 | NInternationalMarket::CCancelSellingContractPopup::Update func_names 名 NInternationalMarket::CCancelSellingContractPopup::Update |
| 0x14043FC30 | NCareerProfile::CCheckPlaythroughRatio::GetDesc func_names 名 NCareerProfile::CCheckPlaythroughRatio::GetDesc |
| 0x1413B7700 | NInternationalMarket::$$A6AXAEBVCPurchaseContract::V?$function:鈥�::[0] func_names 名 NInternationalMarket::$$A6AXAEBVCPurchaseContract::V?$function:鈥�::[0] |
| 0x14146CC20 | NProject::NUi::CProjectListFilterWindow<鈥�>::[0] func_names 名 NProject::NUi::CProjectListFilterWindow<鈥�>::[0] |
| 0x141C3B5A0 | NIndustrialOrganisation::$$A6AXAEBVCOrganisationListWindow::V?$鈥�::[0] func_names 名 NIndustrialOrganisation::$$A6AXAEBVCOrganisationListWindow::V?$鈥�::[0] |
| 0x141CB02B0 | NProject::NUi::CProjectListFilterWindow<鈥�>::[0] func_names 名 NProject::NUi::CProjectListFilterWindow<鈥�>::[0] |
| 0x141F0CB10 | NInterfaceMessages::SScopedListener<鈥�>::[0] func_names 名 NInterfaceMessages::SScopedListener<鈥�>::[0] |
| 0x140456D60 | NIndustrialOrganisation::CIsAssignedToTaskTrigger::Evaluate func_names 名 NIndustrialOrganisation::CIsAssignedToTaskTrigger::Evaluate |
| 0x140456C10 | NIndustrialOrganisation::CHasPolicyActiveTrigger::Evaluate func_names 名 NIndustrialOrganisation::CHasPolicyActiveTrigger::Evaluate |
| 0x141CF0630 | NAirSelectionUI::NQuickWingDeployment::CQuickWingDeployUIContro鈥�::[0] func_names 名 NAirSelectionUI::NQuickWingDeployment::CQuickWingDeployUIContro鈥�::[0] |
| 0x141EF8B90 | NCareerProfile::CCareerProfileViewUpdateable::IsValid func_names 名 NCareerProfile::CCareerProfileViewUpdateable::IsValid |
| 0x1417B9154 | NInternationalMarket::CCountryInternationalMarketView::[0] vtable 槽 NInternationalMarket::CCountryInternationalMarketView::[0]（func_names RTTI 名） |
| 0x14043F4A0 | NCareerProfile::CNumOfPointsTrigger::GetValue func_names 名 NCareerProfile::CNumOfPointsTrigger::GetValue |
| 0x14146CAD4 | NProject::NUi::CFilterEntryItem<鈥�>::[1] func_names 名 NProject::NUi::CFilterEntryItem<鈥�>::[1] |
| 0x14146CB94 | NFactions::NUi::CFactionTheaterPopup::[0] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[0]（func_names RTTI 名） |
| 0x141F20D1C | NIndustrialOrganisation::CEquipmentIconItem::[1] vtable 槽 NIndustrialOrganisation::CEquipmentIconItem::[1]（func_names RTTI 名） |
| 0x142021528 | NUI::CScopedPopUp<CPopUpWindow>::[1] func_names 名 NUI::CScopedPopUp<CPopUpWindow>::[1] |
| 0x14205C390 | NInternationalMarket::CMarketStockpileClearCommand::PayloadWriter func_names 名 NInternationalMarket::CMarketStockpileClearCommand::PayloadWriter |
| 0x14015BFC0 | NFactions::CFactionGoal::[0] vtable 槽 NFactions::CFactionGoal::[0]（func_names RTTI 名） |
| 0x141954630 | NOperativeMissions::CBuildIntelNetwork::GetMissionData func_names 名 NOperativeMissions::CBuildIntelNetwork::GetMissionData |
| 0x141959DF0 | NOperativeMissions::CQuietIntelNetwork::GetMissionData func_names 名 NOperativeMissions::CQuietIntelNetwork::GetMissionData |
| 0x14195ABA0 | NOperativeMissions::CRootOutResistance::GetMissionData func_names 名 NOperativeMissions::CRootOutResistance::GetMissionData |
| 0x1419DED30 | NOperativeMissions::CPropaganda::GetMissionData func_names 名 NOperativeMissions::CPropaganda::GetMissionData |
| 0x141B3A800 | NRaids::NUi::CRaidList::[1] vtable 槽 NRaids::NUi::CRaidList::[1]（func_names RTTI 名） |
| 0x141FFB6FC | NInternationalMarket::CPurchasableEquipmentWindow::[1] vtable 槽 NInternationalMarket::CPurchasableEquipmentWindow::[1]（func_names RTTI 名） |
| 0x141377BD8 | NNotification::CExternallyCompletedFocusNotification::[1] vtable 槽 NNotification::CExternallyCompletedFocusNotification::[1]（func_names RTTI 名） |
| 0x14146CB34 | NFactions::NUi::CCountryFactionView::[0] vtable 槽 NFactions::NUi::CCountryFactionView::[0]（func_names RTTI 名） |
| 0x1419C4038 | NCareerProfile::CMedalPopupWindow::[0] vtable 槽 NCareerProfile::CMedalPopupWindow::[0]（func_names RTTI 名） |
| 0x141B2B5CC | NRaids::NUi::CRaidInstanceView::IsVisible func_names 名 NRaids::NUi::CRaidInstanceView::IsVisible |
| 0x141B2B5D8 | NRaids::NUi::CRaidInstanceView::[1] vtable 槽 NRaids::NUi::CRaidInstanceView::[1]（func_names RTTI 名） |
| 0x141B34C40 | NRaids::NUi::CRaidFeedbackView::IsVisible func_names 名 NRaids::NUi::CRaidFeedbackView::IsVisible |
| 0x141B3718C | NRaids::NUi::CRaidFilterCategoryItem::[1] vtable 槽 NRaids::NUi::CRaidFilterCategoryItem::[1]（func_names RTTI 名） |
| 0x141C15180 | NFactions::NUi::CFactionCommanderItem::[1] vtable 槽 NFactions::NUi::CFactionCommanderItem::[1]（func_names RTTI 名） |
| 0x141C1FC7C | NProject::NUi::CSpecializationSortItem::[1] vtable 槽 NProject::NUi::CSpecializationSortItem::[1]（func_names RTTI 名） |
| 0x141C2F150 | NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>::[0] func_names 名 NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>::[0] |
| 0x141C2F15C | NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>::[1] func_names 名 NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>::[1] |
| 0x141CF33F4 | NAirSelectionUI::CSelectedAirGroupsView::[0] vtable 槽 NAirSelectionUI::CSelectedAirGroupsView::[0]（func_names RTTI 名） |
| 0x141F0CAF0 | NProject::NUi::CProgramItemBase::[0] vtable 槽 NProject::NUi::CProgramItemBase::[0]（func_names RTTI 名） |
| 0x141FBAB44 | NIndustrialOrganisation::CDetailsModifierItem::[0] vtable 槽 NIndustrialOrganisation::CDetailsModifierItem::[0]（func_names RTTI 名） |
| 0x141FBEC6C | NIndustrialOrganisation::COrganisationTreeWindow::[1] vtable 槽 NIndustrialOrganisation::COrganisationTreeWindow::[1]（func_names RTTI 名） |
| 0x142006340 | NInternationalMarket::CCancelMarketAccessPoup::[0] vtable 槽 NInternationalMarket::CCancelMarketAccessPoup::[0]（func_names RTTI 名） |
| 0x14200BDAC | NInternationalMarket::CCancelSellingContractPopup::[0] vtable 槽 NInternationalMarket::CCancelSellingContractPopup::[0]（func_names RTTI 名） |
| 0x14202151C | NUI::CScopedPopUp<CPopUpWindow>::[0] func_names 名 NUI::CScopedPopUp<CPopUpWindow>::[0] |
| 0x142021558 | NIndustrialOrganisation::CLoadQueuePopUp::[1] vtable 槽 NIndustrialOrganisation::CLoadQueuePopUp::[1]（func_names RTTI 名） |
| 0x142044B8C | NInternationalMarket::NPrivate::CTotalIcon::[0] vtable 槽 NInternationalMarket::NPrivate::CTotalIcon::[0]（func_names RTTI 名） |
| 0x14205D700 | NAirWingReorganizationUI::NInternal::CFilterListItem::[1] vtable 槽 NAirWingReorganizationUI::NInternal::CFilterListItem::[1]（func_names RTTI 名） |
| 0x142026978 | NIndustrialOrganisation::CTraitTreeItem::[0] vtable 槽 NIndustrialOrganisation::CTraitTreeItem::[0]（func_names RTTI 名） |
| 0x140308790 | NInternationalMarket::CRequestMarketAccessRightsAction::[10] vtable 槽 NInternationalMarket::CRequestMarketAccessRightsAction::[10]（func_names RTTI 名） |
| 0x14131D870 | NFactions::CSetFactionPingExecutionType::GetTypeId func_names 名 NFactions::CSetFactionPingExecutionType::GetTypeId |
| 0x14131D880 | NFactions::CUseFactionMemberManpower::GetTypeId func_names 名 NFactions::CUseFactionMemberManpower::GetTypeId |
| 0x141A7BF70 | NDoctrines::CUnlockGrandDoctrineCommand::GetTypeId func_names 名 NDoctrines::CUnlockGrandDoctrineCommand::GetTypeId |
| 0x141A7BF80 | NDoctrines::CUnlockSubDoctrineCommand::GetTypeId func_names 名 NDoctrines::CUnlockSubDoctrineCommand::GetTypeId |
| 0x141B1B960 | NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand::GetTypeId func_names 名 NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand::Ge… |
| 0x141B1BB80 | NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::GetTypeId func_names 名 NInternationalMarket::CSetMarketRequestAutomationOptionsCommand::GetT… |
| 0x141B1C0B0 | NInternationalMarket::CMarketStockpileEquipmentTransferCommand::GetTypeId func_names 名 NInternationalMarket::CMarketStockpileEquipmentTransferCommand::GetTypeId |
| 0x141B33710 | NRaids::NNet::CCancelRaidCommand::GetTypeId func_names 名 NRaids::NNet::CCancelRaidCommand::GetTypeId |
| 0x141B33720 | NRaids::NNet::CCreateRaidCommand::GetTypeId func_names 名 NRaids::NNet::CCreateRaidCommand::GetTypeId |
| 0x141B33730 | NRaids::NNet::CExecuteRaidCommand::GetTypeId func_names 名 NRaids::NNet::CExecuteRaidCommand::GetTypeId |
| 0x141B33740 | NRaids::NNet::CRemoveRaidCommand::GetTypeId func_names 名 NRaids::NNet::CRemoveRaidCommand::GetTypeId |
| 0x141B33750 | NRaids::NNet::CSetRaidAutoComplete::GetTypeId func_names 名 NRaids::NNet::CSetRaidAutoComplete::GetTypeId |
| 0x141B33760 | NRaids::NNet::CSetRaidAutoLaunchOption::GetTypeId func_names 名 NRaids::NNet::CSetRaidAutoLaunchOption::GetTypeId |
| 0x141B33770 | NRaids::NNet::CSetRaidRiskLevelCommand::GetTypeId func_names 名 NRaids::NNet::CSetRaidRiskLevelCommand::GetTypeId |
| 0x141BAA4E0 | NFactions::CAddFactionGoalCommand::GetTypeId func_names 名 NFactions::CAddFactionGoalCommand::GetTypeId |
| 0x141BAA4F0 | NFactions::CAddFactionProgramCommand::GetTypeId func_names 名 NFactions::CAddFactionProgramCommand::GetTypeId |
| 0x141BAA500 | NFactions::CClearFactionTheater::GetTypeId func_names 名 NFactions::CClearFactionTheater::GetTypeId |
| 0x141BAA510 | NFactions::CCreateFactionTheater::GetTypeId func_names 名 NFactions::CCreateFactionTheater::GetTypeId |
| 0x141BAA520 | NFactions::CEraseFactionRuleCommand::GetTypeId func_names 名 NFactions::CEraseFactionRuleCommand::GetTypeId |
| 0x141BAA530 | NFactions::CFactionAttachScientistCommand::GetTypeId func_names 名 NFactions::CFactionAttachScientistCommand::GetTypeId |
| 0x141BAA540 | NFactions::CFactionSetCommanderCommand::GetTypeId func_names 名 NFactions::CFactionSetCommanderCommand::GetTypeId |
| 0x141BAA550 | NFactions::CFactionUnattachScientistCommand::GetTypeId func_names 名 NFactions::CFactionUnattachScientistCommand::GetTypeId |
| 0x141BAA560 | NFactions::CModifyFactionTheater::GetTypeId func_names 名 NFactions::CModifyFactionTheater::GetTypeId |
| 0x141BAA570 | NFactions::CRemoveFactionProgramCommand::GetTypeId func_names 名 NFactions::CRemoveFactionProgramCommand::GetTypeId |
| 0x141BAA580 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::GetTypeId func_names 名 NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::GetTypeId |
| 0x141BAA590 | NFactions::CSetFactionIconAndColor::GetTypeId func_names 名 NFactions::CSetFactionIconAndColor::GetTypeId |
| 0x141BAA5A0 | NFactions::CSetFactionRuleCommand::GetTypeId func_names 名 NFactions::CSetFactionRuleCommand::GetTypeId |
| 0x141BAA5B0 | NFactions::CSetFactionTheaterPinVisibility::GetTypeId func_names 名 NFactions::CSetFactionTheaterPinVisibility::GetTypeId |
| 0x141BAA5C0 | NFactions::CSetFactionUpgradeCommand::GetTypeId func_names 名 NFactions::CSetFactionUpgradeCommand::GetTypeId |
| 0x141BAA5D0 | NFactions::CUnlockFolderDoctrineSharingCommand::GetTypeId func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::GetTypeId |
| 0x141BAA5E0 | NFactions::CUpdateIntelligenceAdvisorSlotCommand::GetTypeId func_names 名 NFactions::CUpdateIntelligenceAdvisorSlotCommand::GetTypeId |
| 0x142012550 | NAiNavalGoals::CMineLayingObjective::[5] vtable 槽 NAiNavalGoals::CMineLayingObjective::[5]（func_names RTTI 名） |
| 0x14205C360 | NInternationalMarket::CMarketStockpileClearCommand::GetTypeId func_names 名 NInternationalMarket::CMarketStockpileClearCommand::GetTypeId |
| 0x14206A410 | NInternationalMarket::CSubsidyDraft::IsValid func_names 名 NInternationalMarket::CSubsidyDraft::IsValid |
| 0x141B35090 | NRaids::NUi::CRaidFeedbackView::Reload func_names 名 NRaids::NUi::CRaidFeedbackView::Reload |
| 0x140307420 | NInternationalMarket::CCancelPurchaseContractEffect::GetSupportedScopeMask func_names 名 NInternationalMarket::CCancelPurchaseContractEffect::GetSupportedScop… |
| 0x140496EC0 | NProject::CHasProjectFlagTrigger::GetSupportedScopeMask func_names 名 NProject::CHasProjectFlagTrigger::GetSupportedScopeMask |
| 0x1413B2040 | NInternationalMarket::CRequestMarketAccessRightsAction::[43] vtable 槽 NInternationalMarket::CRequestMarketAccessRightsAction::[43]（func_names RTTI 名） |
| 0x141611B10 | NFactions::CCreateFactionAction::[43] vtable 槽 NFactions::CCreateFactionAction::[43]（func_names RTTI 名） |

#### 4.25.16 世界层全局对象函数补遗（697 函）

| VA | 语义/证据 |
|---|---|

#### 4.25.17 世界层全局对象函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x1422990C0 | （无名） 断言站点 bitmapfont.cpp:2326 |
| 0x14125F200 | （无名） 断言站点 pdxmaptexturegeneration.cpp:612 |
| 0x140D935E0 | NFactions::VCFactionMemberStatus::U?$SDefaultSetSize::NPdx::NIm鈥�::[3] func_names 名 NFactions::VCFactionMemberStatus::U?$SDefaultSetSize::NPdx::NIm鈥�::[3] |
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
