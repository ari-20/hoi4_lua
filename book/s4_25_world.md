

### 4.25 世界层全局对象 (CVariables / region 制海 / threat / 选择组 / 游戏规则 / 脚本地图实体)

> 顶层全局块分驻: variables/region/threat/选择组/游戏规则/脚本地图实体 = 本册; power_balance (按国家索引) → §4.3.21/§4.3.22; 海军战史 (沉船总账/运输船月账) → §4.16.13/§4.16.14;
> 会话与身份注册 → §4.28; 特务/operation → §4.11; 编制模板 → §4.18; factions → §4.5。

#### 4.25.1 CVariables (56B, variables)

CVariables = ***(gs+2432)***; 元 writer `ADEC0(0x2A4A, *(a1+2432))`; 写序 = 键字节序 (收集后排序, 非桶序)。
**通用布局 (56B: vt@0 / random 种子对 +8/+12 / count@+32 / mask@+36 / extra +40 / max_load_factor +44=0.9 / 尾槽 +48)、RH 桶结构、条目 0x30、空表哨兵 &unk_1430851A0、扫描防御界 (M.lim.PTR_HUGE) = §4.13.2 (权威, 勿重述)**;
gs 侧宿主差异 = +48 尾槽传 `&dword_14332F2A0` (CGameState 域; 全注册表见 §4.13.2)。

#### 4.25.2 region 制海族 (CNavalRegion / CNavalRegionDominance / CDominanceValues)

region (346 叶): 数组 = ***(gs+736)***, 数 = ***(gs+748)***; id 1..count-1;
robj = *(数组+8×id), robj vt 槽1 = 0X140E24810。

CNavalRegion 条目主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +56 | MSVC SSO 32B | name | size≠0 | |
| +72 | uint32 | name 的 size | 不序列化 | 写门字段 |
| +232 | CNavalRegionDominance* | dominance | 恒写块 | writer 0X141006490 = vt 0x142984C40 slot2; ctor 0X141002AA0 |

注: 条目 vt 0X296FC50 族属 CPowerBalance, 与 dominance 无关。

CNavalRegionDominance (dom) 主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CNavalRegionDominance | 不序列化 | |
| +8 | CNavalRegion* | region 回指 | | |
| +16 | std::map | countries | 恒写 | {head@+16, size@+24}; 节点 key = 国 idx u32@+28; 中序 = 写序; 裸 tag 空格连 |
| +40 | RH | values | ru32(dom+48)>0 | 88B 桶 {dist u8@+4, key 国 idx@+8, value obj@+16}; 桶数组 {buckets@+40, count@+48, mask@+52, extra u8@+56, lf f32@+60 = 0.9} |
| +64 | 匿名结构 (80B 形状) 向量 | 优势条目表 {data@+64, cap@+72, count@+76} — 80B 条 {国 tag@+0, 强度 qword@+32} | 不序列化 | has_naval_control 遍历源 (sub_141003F50); 探针 3 区恒空; 推定 |
| +96 | 容器 24B | 容器#2 | | {data@+96, cap@+104, count@+108, alloc@+112}; 元素 **16B {CProvince\* @+0, value i64 @+8}**; 消费 = sub_141004230 逐元填 NAVAL_HEADQUARTER_PLACE_VALUE 值对 |
| +120 | fixed×1e-5 | 优势门阈值 (define 派生; 探针 250.0 / 100.0) | 不序列化 | 推定 |

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
| +8 | u32 | 规则键 FNV-1 hash32 | — | 解析对键名现算 |
| +12 | u32 | 装入序号 | — | 非玩家选中态 |
| +16 | 容器 24B | 选项表 | 10598 option | count@+28; 共享 CPdxHybridInlineBufferAllocator<CGameRuleOption,6> |
| +40 | i32 | 默认选项索引 | 11405 default | 重复默认项报错 (gamerules.cpp:187 源串) |
| +48 | string | 规则名 | 27 name | |
| +80 | string | required_dlc | 15200 | 空值抛 invalid dlc name |
| +112 | string | exclude_dlc | 19658 | 同上校验 |
| +144 | 向量 24B | group 串表 | 63 group | count@+156, alloc@+160 |
| +168 | string | 图标名 | 181 icon | |
| +200 | byte | seen 旗 | — | 读到任一 DLC token 置 1 |
| +201 | byte | 旗 2 | — | 待裁 |

**CGameRuleOption** (单选项, CPersistent, 160B, vt 0x14293BA08; reader 0x140A37B40):

| 偏移 | 类型 | 名称 | reader token |
|---|---|---|---|
| +8 | u32 | 选项键 hash32 | 27 name |
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
> 向量; 选项流读 sub_1424C0AA0。


#### 4.25.5 脚本地图实体与环境物族 (CScriptedMapEntityManager / CAmbientObject / CAmbientObjectType; 均可序列化)

**CScriptedMapEntityManager** (存档内脚本地图实体注册表, 40B; vt 0x1427216F0; writer 0x140E97CD0 / reader 0x140E97440): +8 u32 下一实体 id (键 11 `id`) / +16 注册表 {d@16, c@28}, 16B 元 {u32 id@0, CScriptedMapEntity* @8}; 块 438 `entity` 逐元素序列化条目 (条目类 CScriptedMapEntity, vt 0x142973108, writer 0x140E97C00 / reader 0x140E971B0 皆真)。

**CScriptedMapEntity** (152B; ctor sub_140E967E0): +0 vt / +8 u32 实体 id (=注册表 key) / +16..+40 MSVC 串 32B 实体名 (token 27 `name`, 恒写) / +48/+56/+64 i64×1e-5 x/y/z (token 32/33/421, 恒写) / +72 i64×1e-5 min_zoom (token 15083, 恒写; ctor 默认 = defines f32 dword_14333479C×1e5) / +80 f32 渲染高度 = z/1e5+地形高程 (运行时派生不序列化) / +88 i64×1e-5 scale (token 93, 恒写; ctor 默认 100000) / +96 i64×1e-5 rotation (token 342, 恒写) / +104..+128 MSVC 串 32B 动画名 (token 64 `animation`, size@+120≠0 才写) / +136 CAndTrigger* visible 脚本触发器反指 (token 11562, 指针非空才写, 发触发器对象 +96 名串) / +144..+152 填充。发射序 = name→x→y→z→scale→rotation→min_zoom→[animation]→[visible]; 数值 i64×1e-5 十进制定点尾零修剪。唯一写入方 = CCreateEntityEffect::Execute (sub_140350C40, create_entity effect 族); 显式 id 经参数槽 fixed×1e-5 求值截 u32 (脚本字面量 `id = 21985` 实得 2198500000); 载入侧条目 key 文本经 int32 饱和 (>INT32_MAX → 2147483647, 存档往返伪影)。

**CAmbientObject** (环境装饰物实例, 96B; vt 0x1429E7368 + 次表 0x1429E73B8 (mdisp 8 = CSelectable); writer 0x141646F30 / reader 0x141646930): +24 name (27) / +56..+64 position vec3 (fixed×1e-5, 块 76) / +68..+76 rotation vec3 (块 342) / +80 CAmbientObjectType* 反指。

**CAmbientObjectType** (环境物类型定义 + 实例容器; vt 0x1429E7318; writer 0x141647160 / reader 0x141646A70): +8 type 名 (225) / +40 animation (64, 默认 "idle") / +72 use_animation (366) / +76 scale (93, 默认 1.0) / +80 time_duration (10925, >0 写) / +88 sound_effect (11419) / +120 max_visible (10926, 默认 -1) / +124 always_visible (11600: 0=16 格空间网格存储 @+152 / 1=平面数组存储 @+160) / +136 CAndTrigger* dlc_allowed (17943); type 侧以键 65 `object` 逐条创建 CAmbientObject 并按位置塞格。

#### 4.25.6 选择组 (selection_groups; gs+1624)

> ⚠ **宿主口径待裁**: 本节记「按玩家 ×10 组 (每组 10 槽 24B, 玩家块 stride 240B)」, 主文件 §4.1 gs+1624 行记
> 「= 国家库条数, 每国一组 240B」。两说对「一块 = 一玩家还是一国」不一致 — 按玩家数取法 `(*gs_vt+72)(gs)`
> 由 writer 侧实证, 但与主文件行未对齐, 未定。

| 项 | 值 | 语义 |
|---|---|---|
| 容器 | gs+1624 | 按玩家 ×10 组二维槽 |
| 玩家块 | stride 240B (= 10 × 24B) | 玩家数 = `(*gs_vt+72)(gs)` 虚拟取 |
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
| +16 | u32 | province id 对.type (province/state 分流 = 按当前地图模式是否为 2) |
| +20 | u32 | province id 对.id |
| +24 | u32 | state id (type-6 CState 条目 +88) |

存档形 (键 selection_groups, 10286; 每玩家一块):

| 项 | 值 | 语义 |
|---|---|---|
| owner | tag (键 10754) | 取自 gs+784 玩家国家指针数组 元素+8 |
| 组键 | 十进制槽位序号串 "0".."9" (itoa) | ⚠ 20 档无 selection_groups 叶, 无对拍样本; reader atoi 对称性高置信 |
| 组内 | SControlGroupData 数组 | — |
| 写门 | 该玩家 10 组中存在非空组 | — |
