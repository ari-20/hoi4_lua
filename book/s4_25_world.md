

### 4.25 世界层全局对象 (CVariables / region 制海 / threat / 选择组 / 游戏规则 / 脚本地图实体)

> 顶层全局块分驻: variables/region/threat/选择组/游戏规则/脚本地图实体 = 本册; power_balance (按国家索引) → §4.3.21/§4.3.22; 海军战史 (沉船总账/运输船月账) → §4.16.13/§4.16.14;
> 会话与身份注册 → §4.28; 特务/operation → §4.11; 编制模板 → §4.18; factions → §4.5。

#### 4.25.1 CVariables (56B, variables)

CVariables = ***(gs+2432)***; 元 writer `ADEC0(0x2A4A, *(a1+2432))`; 写序 = 键字节序 (收集后排序, 非桶序)。
**通用布局 (56B: vt@0 / random 种子对 +8/+12 / count@+32 / mask@+36 / extra +40 / max_load_factor +44=0.9 / 尾槽 +48)、RH 桶结构、条目 0x30、空表哨兵 &unk_1430851A0、扫描防御界 (M.lim.PTR_HUGE) = §4.13.2 (权威, 勿重述)**;
gs 侧宿主差异 = +48 尾槽传 `&dword_14332F2A0` (CGameState 域; 全注册表见 §4.13.2)。

#### 4.25.2 region 制海族 (CStrategicRegion / CNavalRegionDominance / CDominanceValues)

⚠ 原记「CNavalRegion」实名 **CStrategicRegion** (serfam:883; ctor sub_140E1F940 写
`CStrategicRegion::vftable`; 双子对象 +0 主表 / +8 CSelectable 次表 — 多继承
CPersistent ← CSelectable ∥ TGeographicalArea)。

region 块 (原版键 10827 "region"; 书环境 346 = 运行时 lexer id): gs writer
sub_1401F2E40 开块 → 数组按 id 1..count-1 发射 {id, 对象多态写}; 数组 =
***(gs+736)***, 数 = ***(gs+748)***; 宿主装载 = gs reader sub_1401E59D0 (块 10827
分支: id→`*(gs+736)[id]`→槽[3] Load wrapper; 原记「loader case 10827」两处实为引用持类)。

CStrategicRegion 条目主表 (sizeof 328 = 0x148, malloc 双证; ctor sub_140E1F940;
writer = 主 vt 0x14296D558 槽[2] sub_140E24810 — 原记「vt 槽1」系槽位误配;
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
| +104 | 容器 24B | 交集州表 (unique CState*) | 不序列化 | 元 = prov+192 州回指按州 id 去重 (gs 州计数字节数组去重) |
| +128 | 容器 24B | 逐州覆盖率表 (qword, fixed×1e-5, 与 +104 平行) | 不序列化 | = 1e5 × 本区在该州省数 / 州+36 总省数; 州+36=0 → −1.0 哨兵 |
| +152 | fixed×1e-5 | 陆地省占比 (desc+210 bit0 计数/总数) | 不序列化 | 重建收尾三占比一并算; 总数 = 本次成功加入省数 |
| +160 | fixed×1e-5 | 海洋省占比 (desc+210 双 0 计数/总数) | 不序列化 | air-ai 阈值 50000=0.5 判海区消费; 海区环 BFS 门 (+160≠0) |
| +168 | fixed×1e-5 | 湖泊省占比 (desc+210 bit1 计数/总数) | 不序列化 | |
| +176 | 容器 24B | _Neighbors 邻接区指针表 (CStrategicRegion*) | 不序列化 | 断言 strategicregion.cpp:633; 邻省经 desc+112 邻接表 → prov+200 属区去重; 访问器 sub_140E23A70 |
| +200 | 容器 24B | _NeighborAdjs 邻接载荷表 (96B 元, 与 +176 序对齐) | 不序列化 | 元 {旗@0, 接触数 u32@+4, 锚距² i64@+8, 边条目对容器@+16/@+64, 对侧省表@+40, 旗@+88}; 配对查询 sub_140E23570 线性搜 +176 后返 +200+96×idx |
| +224 | uint32 | Σ desc+192 (逐成员省累加; 重置清 0) | 不序列化 | desc+192 语义待裁 (已排除 = 省数: 无去重逐省累加) |
| +232 | CNavalRegionDominance* | dominance (键 10209) | 恒写块 | ctor malloc(0x80) → sub_141002AA0 |
| +240 | i32×2 | 锚点坐标对副本 {x@240, y@244} = 模板+224/228 双字拷贝 | 不序列化 | getter sub_140E23A60; 邻接距离直读模板侧, 便览副本定位 (高置信) |
| +248 | 容器 24B | 海区邻接环 1 跳 (u32 区 id, 升序) | 不序列化 | BFS sub_140E21EA0 唯一写者 (计算下标 a1+24×depth+248); 海区门 = 对方 +160≠0; 读点待裁 (推定海军可达链) |
| +272 | 容器 24B | 海区邻接环 2 跳 | 不序列化 | 同上 |
| +296 | 容器 24B | 海区邻接环 3 跳 | 不序列化 | 同上; 三环收尾各自排序 (≤32 元插入排序, 否则折半递归) |
| +320 | uint32 | 更新相位 = +96 % (2×NAir::HOURS_DELAY_AFTER_EACH_COMBAT) | 不序列化 | ctor −1; 门 sub_140E24530 对 (gs+1128−43800000) 取模放行周期更新 |

注: 条目 vt 0X296FC50 族属 CPowerBalance, 与 dominance 无关。

CNavalRegionDominance (dom) 主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CNavalRegionDominance | 不序列化 | |
| +8 | CNavalRegion* | region 回指 | | |
| +16 | std::map | countries | 恒写 | {head@+16, size@+24}; 节点 key = 国 idx u32@+28; 中序 = 写序; 裸 tag 空格连 |
| +40 | RH | values | ru32(dom+48)>0 | 88B 桶 {dist u8@+4, key 国 idx@+8, value obj@+16}; 桶数组 {buckets@+40, count@+48, mask@+52, extra u8@+56, lf f32@+60 = 0.9} |
| +64 | 匿名结构 (80B 形状) 向量 | 优势条目表 {data@+64, cap@+72, count@+76, alloc 哨兵@+80} — 80B 条 {国 tag@+0, 强度 qword@+32} | 不序列化 | has_naval_control 遍历源 (sub_141003F50); 探针 3 区恒空; 推定 |
| +96 | 容器 24B | 容器#2 | | {data@+96, cap@+104, count@+108, alloc@+112}; 元素 **16B {CProvince\* @+0, value i64 @+8}**; 消费 = sub_141004230 逐元填 NAVAL_HEADQUARTER_PLACE_VALUE 值对 |
| +120 | fixed×1e-5 | 优势门阈值 (define 派生: = *(sub_1415A5560(*(region+48))+128); 探针 250.0 / 100.0) | 不序列化 | 推定 (阈值链定案) |
| — | — | sizeof = 128 (malloc 0x80 直证); reader = 槽[4] 0x1410060C0 (键 11593 countries / 19260 values, 与 writer 两块互证); 19260 块仅 u32@+48>0 发射 (writer 门不对称, reader 无条件接受); +88 ctor 置 0 无消费 | — | 增补定案 |

注: values 值元 = CDominanceValues; 写序 = key 升序 (λ 0X141001700 收集后排序)。

CDominanceValues 值元子表 (vt 0x142984BF0; slot2 = 0X1419DE3F0 六值 writer; 六值恒写):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | vt | CDominanceValues | |
| +24 | fixed×1e-5 | current | |
| +32 | fixed×1e-5 | base_target | |
| +40 | fixed×1e-5 | target | |
| +48 | fixed×1e-5 | individual_ratio | |
| +56 | fixed×1e-5 | previous | |
| +64 | fixed×1e-5 | decline_from | |

#### 4.25.3 threat (CWorldThreat / CThreatSource)

holder = **CWorldThreat\* = *(gs+1712)***; vt 0X142974AA8; ctor 0X140F03310; 64B。
GUI: CWorldTensionPopUpWindow 双源之一 (populate sub_1418B47B0: 本 holder + 各国 dip+792)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CWorldThreat | 不序列化 | |
| +8 | uint64 | **逐国紧张度总值 Σ** | | 写点 sub_140F05160: 重算 +40 逐国表后 `*(th+8)=0` 再逐国 `+= *(*(th+16)+8*i)+16` (= Σ CThreatSource.threat) |
| +16 | 容器 24B | threat 指针数组 | | {data@+16, cap@+24, count@+28, alloc@+32} |
| +40 | fixed×1e-5 值数组 | **逐国紧张度值表** | 不序列化 | 下标门 idx<count@+52, 钳 [0, 10000000]; 读器 sub_140F03E30 直取 `*(data+8×idx)` (写点 sub_140F05160 抚平后按 CThreatSource+16 累加); 非指针数组 (定案) |

元素 = CThreatSource 96B; vt 0x1429766E8; ctor 0X140F032A0; writer 0X140F055E0。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CThreatSource | 不序列化 | |
| +8 | uint32 | tag 国 idx | idx>0 | GUI: 紧张度条目 target (CWorldTensionEntry entry+40 = 本对象指针); 排序比较器定案 |
| +12 | uint32 | target idx | | |
| +16 | fixed×1e-5 | threat | 恒写 | GUI: 紧张度条目显示值 (populate sub_1418B4360) |
| +24 | fixed×1e-5 | final_threat | 恒写 | GUI: 同 +16 |
| +32 | fixed×1e-5 | daily | 恒写 | |
| +40 | CGameDate (内嵌 24B) | date | 无门 date3 | {vt1@+40, hours@+48, vt2@+56}; ctor 哨兵 43808760; writer ADEC0 收 a1+56 = &vt2 (通则 §3.7a); GUI: 条目日期 |
| +64 | MSVC SSO 32B | label | | 引号; size@+80; GUI: 条目标签 |

注: +16/+24/+32 为三个独立单值字段 (各 8B)。

#### 4.25.4 游戏规则定义族 (CGameRule / CGameRuleOption / CGameRulesDatabase)

**CGameRule** (单条规则定义, CPersistent, 208B, vt 0x14293B9B8 9 槽; writer 未覆写 = 定义件不进存档 writer, 运行态走 CGameRulesInstance):

| 偏移 | 类型 | 名称 | reader token | 备注 |
|---|---|---|---|---|
| +8 | u32 | 规则名 lexer 动态 token id (解析驱动 sub_140A35CB0 现驻留 `__PAIR64__(序号, token id)`; 原记「FNV-1 hash32」翻案) | — | 解析对键名现算 |
| +12 | u32 | 装入序号 | — | 非玩家选中态 |
| +16 | 容器 24B | 选项表 | 10598 option | count@+28; 共享 CPdxHybridInlineBufferAllocator<CGameRuleOption,6> |
| +40 | i32 | 默认选项索引 | 11405 default | 重复默认项报错 (gamerules.cpp:187 源串) |
| +48 | string | 规则名 | 27 name | |
| +80 | string | required_dlc | 15200 | 空值抛 invalid dlc name |
| +112 | string | exclude_dlc | 19658 | 同上校验 |
| +144 | 向量 24B | group 串表 | 63 group | count@+156, alloc@+160 |
| +168 | string | 图标名 | 181 icon | |
| +200 | byte | 评估门旗 (两评估器 skip 未置位规则) | — | 定案 |
| +201 | byte | IsActive 旗 (SetOption sub_140A38860 断言 `pRule->IsActive()`, gamerules.cpp:417) | — | 定案 (原「旗 2 待裁」收口) |

**CGameRuleOption** (单选项, CPersistent, 160B, vt 0x14293BA08; reader 0x140A37B40):

| 偏移 | 类型 | 名称 | reader token |
|---|---|---|---|
| +8 | u32 | 选项名 lexer 动态 token id (同 +8 翻案) | 27 name |
| +16 | string | text | 143 |
| +48 | string | desc | 10644 |
| +80 | u32 | allow_achievements | 15201 |
| +88 | string | required_dlc | 15200 |
| +120 | string | exclude_dlc | 19658 |
| +152 | byte | 旗 | — (待裁) |

**CGameRulesDatabase** (规则库单例 **qword_14332EF20**, TGameItemDatabase 谱系, 112B, vt 0x14293BAD8 5 槽):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | 匿名结构 (24B 形状) | idb 基类容器 | §4.26 骨架位 |
| +40 | 向量 24B | 规则定义表 | cap@+48 / count@+52; 扩容 ×1.5 |
| +64 | 24B 向量 | 空 | 待裁 |
| +88 | 24B 向量 | 空 | 待裁 |

> 解析驱动 sub_140A35CB0: 逐规则栈上构造 CGameRule (键哈希+序号) → 共享 Load
> wrapper 0x1424BE690 → 虚表[4] reader (CGameRule 0x140A37680) → append +40
#### 4.25.4a CGameRulesInstance (游戏规则运行态实例, gs+1088)

56B (0x38) RTTI 独立类; vt 0x14293BA58 六实槽 ([2] writer sub_140A39830 /
[3] Load wrapper 0x1424BE690 / [4] reader ReadMember sub_140A37DC0,
gamerules.cpp:545 断言自证类名); gs+1088 形态 = pdx scoped_ptr 裸指针
(三处 pdx_scopedptr.h 断言 + 两条 gs 重置路径 malloc(0x38))。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 容器 24B {data@8, cap@16, count@20} | **唯一序列化成员**: 规则选中表, 元素 8B = {规则名 token id, 选中选项名 token id}; 同规则 upsert 至多一条; 只记非默认选中 (ReadMember 对默认项且无既存条目不入账) | 元素 8B token 对 — 原 s4_01「token 对向量」证实 |
| +32..+48 | 派生旗区 | scorched_earth / paratroopers / wargoals 三态 / volunteers 三态 / lend_lease / peace_score 三项 / maximum_fort_level 等 — 由 sub_140A38C70 按选中选项名串重算, 不进存档 | 运行期派生 |

存档块协议: 键 15202 `game_rules`; CGameState::Save 经 sub_1424C2E20 委托实例
槽[1]→[2]; 载入 = gs reader case 15202 重置后经蹦床走槽[3]→[4]; **键与值皆以名串
落盘** (token id 会话本地, 对拍必须按名匹配); 取值经 sub_140A36C50 回落规则默认项
(rule+40)。规则库单例 = qword_14332EF20 (实例不持指针, 纯 id 二分关联)。
构造 = sub_140A34D20 (世界重置步 4, §4.28.18 内 49.2 步 13 步分解表; 默认值 +32 word = 257 / +36 = −1 / +44 = 1); 初始化/重灌 = **sub_140A355F0**
(把选项 id 数组从临时表重灌 ×1.5 扩容并重建查找表; 不触 +8 选中表)。

> 向量; 选项流读 sub_1424C0AA0。


#### 4.25.5 脚本地图实体与环境物族 (CScriptedMapEntityManager / CAmbientObject / CAmbientObjectType; 均可序列化)

**CScriptedMapEntityManager** (存档内脚本地图实体注册表, 40B; vt 0x1427216F0; writer 0x140E97CD0 / reader 0x140E97440): +8 u32 下一实体 id (键 11 `id`) / +16 注册表 {d@16, c@28}, 16B 元 {u32 id@0, CScriptedMapEntity* @8}; 块 438 `entity` 逐元素序列化条目 (条目类 CScriptedMapEntity, vt 0x142973108, writer 0x140E97C00 / reader 0x140E971B0 皆真)。

**CScriptedMapEntity** (152B; ctor sub_140E967E0): +0 vt / +8 u32 实体 id (=注册表 key) / +16..+40 MSVC 串 32B 实体名 (token 27 `name`, 恒写) / +48/+56/+64 i64×1e-5 x/y/z (token 32/33/421, 恒写) / +72 i64×1e-5 min_zoom (token 15083, 恒写; ctor 默认 = defines f32 dword_14333479C×1e5) / +80 f32 渲染高度 = z/1e5+地形高程 (运行时派生不序列化) / +88 i64×1e-5 scale (token 93, 恒写; ctor 默认 100000) / +96 i64×1e-5 rotation (token 342, 恒写) / +104..+128 MSVC 串 32B 动画名 (token 64 `animation`, size@+120≠0 才写) / +136 CAndTrigger* visible 脚本触发器反指 (token 11562, 指针非空才写, 发触发器对象 +96 名串) / +144..+152 填充。发射序 = name→x→y→z→scale→rotation→min_zoom→[animation]→[visible]; 数值 i64×1e-5 十进制定点尾零修剪。唯一写入方 = CCreateEntityEffect::Execute (sub_140350C40, create_entity effect 族); 显式 id 经参数槽 fixed×1e-5 求值截 u32 (脚本字面量 `id = 21985` 实得 2198500000); 载入侧条目 key 文本经 int32 饱和 (>INT32_MAX → 2147483647, 存档往返伪影)。

**CAmbientObject** (环境装饰物实例, 96B; vt 0x1429E7368 + 次表 0x1429E73B8 (mdisp 8 = CSelectable); writer 0x141646F30 / reader 0x141646930): +24 name (27) / +56..+64 position vec3 (fixed×1e-5, 块 76) / +68..+76 rotation vec3 (块 342) / +80 CAmbientObjectType* 反指。

**CAmbientObjectType** (环境物类型定义 + 实例容器; vt 0x1429E7318; writer 0x141647160 / reader 0x141646A70): +8 type 名 (225) / +40 animation (64, 默认 "idle") / +72 use_animation (366) / +76 scale (93, 默认 1.0) / +80 time_duration (10925, >0 写) / +88 sound_effect (11419) / +120 max_visible (10926, 默认 -1) / +124 always_visible (11600: 0=16 格空间网格存储 @+152 / 1=平面数组存储 @+160) / +136 CAndTrigger* dlc_allowed (17943); type 侧以键 65 `object` 逐条创建 CAmbientObject 并按位置塞格。

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
| writer | CSelectionGroupWriter 0X1401F2BE0 (vt 0X27211D0) | — |
| reader | 0X1401E9820 = **CSelectionGroupReader** (RTTI 实名, vt 0x142721220) | — |

SControlGroupData (32B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | — | vtable |
| +8 | — | CSelectable id 对 |
| +16 | u32 | 键 10304 province / 键 11925 naval — 三独立键位之一 (创建命令按当前地图模式==2 把同一省 id 分流落 +16 或 +20) |
| +20 | u32 | 键 11926 air (地图模式分流落点, 同上) |
| +24 | u32 | state id (type-6 CState 条目 +88; 恒走自己键) |

存档形 (键 selection_groups, 10286; 每玩家一块):

| 项 | 值 | 语义 |
|---|---|---|
| owner | tag (键 10754) | 取自 gs+784 玩家国家指针数组 元素+8 |
| 组键 | 十进制槽位序号串 "0".."9" (itoa) | ⚠ 20 档无 selection_groups 叶, 无对拍样本; reader atoi 对称性高置信 |
| 组内 | SControlGroupData 数组 | — |
| 写门 | 该玩家 10 组中存在非空组 | — |
