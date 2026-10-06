

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

**数据库单例** (sub_140163C30): {+8 路径串, +20 已载旗, +40 项指针数组, +48 容量, +52 计数 (= max id+1), +56 分配器, +112 活体对象计数}。

**定义块装载循环** (sub_140AC02C0): 节点键 == 12014 (strategic_region) 门 → malloc 336 → **sub_1415A3DF0 = CStrategicRegionTemplate ctor** (vftable 字面量直证; +168 有效旗 = 1; +176/+200/+240 三向量 + +272 SSO 初始化) → **虚槽[3] Load wrapper 消费整块** (CPersistent 槽契约互证); id = 模板 +160, id < 1 → assert "Invalid ID, not in range > 0." 后析构; 数组挂载槽 = 数据库数组 + 8×id (容量不足 ×1.5 保底 id+1 扩, 新槽填 null 对象 qword_14333A0D8 或 0 — §4.26 null 实例登记互证); 双串拷入 +96/+128 (目录项 64B 双 32B 串, 语义推定 = 定义文件路径/文件名); 流守卫 = 内嵌解析器 +100 一次性旗 + vtable[1] 状态 == 19 终止。

**weatherpositions.txt 解析器** (sub_140AC0AB0): 文件格式 = 逐行 5 字段 `region_id;x;y;z;small` (`;` 分隔, 剥 CR); 字段数 ≠ 5 → ":208 invalid arguments count."; 空文件 → ":215 is empty."; 打开失败 → ":220 Failed to read weather positions file" (cpp 文件名与错误串同体 = 装载器语义直证)。逐行: 字段 0 = 战略区模板 id (越界回退槽 0) → 模板 +168 有效旗门 (0 → ":202 invalid region id."); 字段 1-3 strtof = x/y/z; 字段 4 == "small" = 旗。落点 = 模板 +200 向量 (16B 元, ×1.5 扩容) — **战略区的地图天气表现点集 (区内每点三维坐标 + 小型标记), 非序列化静态资源, 与 +176 定义内 weather 块 (224B 元) 是两个不同向量** (§4.26 布局行已补)。

未决: colors.txt 装载器 / 模板 +96/+128 双串语义活体验证 / missing_triggers 生产者全景 (§4.32.21)。

#### 4.25.9 战略区域模板后处理 (strategicregiontemplate.cpp; 6 函闭环 — 中心计算/温度校验/链接解析/省描述符新行)

簇清册 (体内 cpp 锚 6/6; 全部新定性; 模板布局 §4.26 + 装载链 §4.25.8 已收):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_1415A4770 | 134 | :405 断言 "IsRegionCenterSet() && Calculations where incorrect" (B52, 闩 byte_14338A945) | CalculateRegionCenter |
| sub_1415A6420 | 75 | :515 断言 (B52) | FindPositionInRegion (逐省 bbox 点测 + 细步搜索兜底) |
| sub_1415A6A10 | 268 | :559/:577/:585 (CLogStream 65540) | LateInit 链接解析 (**missing_triggers 类报错生产者之一**) |
| sub_1415A5630 | 272 | :172/:178/:191 (格式化日志 4096) | weather 温度区间连续性校验 (虚槽触发, 槽位待裁) |
| sub_1415A68E0 | 48 | :232/:238 断言 (B51) | SetId (nudge/编辑域, 唯一调用方 sub_141B61FC0) |
| sub_1415A5480 | 44 | :537 + null_object.h:133 (B52) | GetTerrainType (+304 访问器, null 兜底 qword_14333A248) |

**调用链 (定案)**: 战略区 DB 后处理三 pass (sub_140AC05C0 → 4770 / sub_140AC16C0 → 6420 / sub_140AC1990 → 6A10; DB 单例 §4.25.8 互证)。

**Template 布局增补 (§4.26 336B 表)**: **+232 i32×2 计算中心 {x, y}** (4770 输出落点; +224/+228 静态锚点外的第三组坐标) / **+304 CTerrainType* _pTerrainType** (断言串直证; naval_terrain 名解析产物; null 兜底 = CTerrainType null 实例)。中心计算 = Σ(bbox 中心)/N 均值 → 首个含点省精化 → 双兜底 → 空省拷静态锚点。

**weather 元素 224B 内部 (定案)**: +8 = 区间起点 / +32 = 区间终点; **全年 365 天连续性校验**: 重叠 (:172) / 空档 (:178) / 不覆盖整年 (:191) 三错误全为格式化日志无中断。

**static_modifiers 元素 80B 内部 (定案)**: +0 modifier 名 / +32 trigger 名 / +64 trigger 对象 (库 qword_14332F058; 无效 → 报错 + **元素删除**) / +72 modifier 对象 (sub_14055B160 单例解析; NULL → 报错 + 删除)。特例: **trigger 名 "always" (0x61776C61 直证) 跳库直通保留**。

**省静态描述符新行** (§4.14.3 表已补): desc+88 = 战略区模板 id / desc+136..+148 = bbox {min_x, min_y, w, h}。

未决: 温度校验虚槽槽位 / Template +96/+128 双串语义 (旧未决) / 中心兜底三件内部。
