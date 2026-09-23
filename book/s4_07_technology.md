> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.7 CTechnologyStatus (科技)

**获取**: `ts = *(cc + 3936)`; **vtable RVA 0X2974FA0**; ctor 0X140ED3E80;
writer 0X140EE5430。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CSubUnitStatBonus 内嵌 56B | 子单位加成累计器 {vt@+8, 向量@{+16,+24,+28,+32} 与 {+40,+48,+52,+56}} | ctor sub_1406419E0 直写 vt; Reset sub_140641D40 |
| +64 | vector\<CTechnology*\> 24B | **_ResearchedTechs** (已完成科技, 按 tech+8 名 token 排序的二分查找容器) {cap@72, count@76, alloc@80} | assert "_ResearchedTechs.Contains( pTechnology ) == false" (technology.h:0x27D); loader case 11869 在 level≥max 时二分插入 |
| +88 | vector\<u32\> 24B | **per-建筑 max_level 加成缓存** (按建筑 def+736 索引; 完成科技时按 tech+56 {def*,u32} 对 max 累积) {cap@96, count@100, alloc@104} | 写点 0X140EE3E70 `ts88[4*def+736]=max(cur,val)`; 消费 0X1411731F0 配 loc BUILDING_CURRENT_MAX_LEVEL_CAPPED |
| +112 | vector\<指针\> 24B | **国家可用战斗战术 (combat tactics) 累积表** (元素=tactic 对象, id@elem+148 去重) {cap@120, count@124, alloc@128} | 完成科技时把 tech+80 元素按 +148 去重 push; fallback 构造串 "nullCombatTactic" |
| +136 | vector\<CTechnology*\> 24B | technologies {cap@144, count@148, alloc@152} — **元素 8B 指针** (count<4096) | 导出须过滤门 (下) |
| +160 | vector\<CResearchSlot*\> 24B | slots {cap@168, count@172, alloc@176} — **元素 8B 指针** (writer 双重解引用实锤; 对象 0x48B) | loader case 11879 逐槽 malloc(0x48); **GUI: 研究槽行** (research_slots_grid; Repopulate@48[9] 0X1415FA1A0 → 0X1415FA300 建行 CResearchSlotItem(0x580), item+1336=slot; 可见门 sub_1415FB5D0 非本人槽不画) |
| +184 | vector\<指针\> 24B | **_EquipmentBonuses** (国家侧生效装备加成列表) {cap@192, count@196, alloc@200} | assert "!_EquipmentBonuses.Contains( &Bonus )" (technology.cpp:0x5D7) |
| +208 | vector\<40B 条 {def ptr@0, name 串@+8..}\> 24B | **_AdvisorBonuses** (国家侧顾问/加成列表) {cap@216, count@220, alloc@224} | assert "!_AdvisorBonuses.Contains( Bonus )" (technology.cpp:0x5E5) |
| +232 | vector\<CLimitedUseTechBonus*\> 24B | limited_use_bonus {cap@240, count@244, alloc@248} — **元素 8B 指针** (对象 0x80B); **per-tech lub 块 BlackICE 实测峰值 115 (GER/bi8), 防御界须 ≥256** | loader case 13283 malloc(0x80)+push |
| +256 | vector\<CLimitedUseTechCostReduction*\> 24B | cost_reduction {cap@264, count@268, alloc@272} — **元素 8B 指针** (对象 0x70B) | loader case 19531 增长码全四元组 |
| +280 | vector\<CTechnologySharingGroup*\> 24B | **本国 technology sharing group 成员表** (组 id@elem+8) {cap@288, count@292, alloc@296} | CModifyTechnologySharingBonusEffect::Execute 0X14031FB10 → sub_140ED5110 按组 id 查找; Add/Remove 效果经 gs 管理器 push/erase |
| +304 | CCountry* | 回指 (ctor 参数 a2) | +312=`*(a2+8)` 即国 tag 初值 |
| +312 | u32 | override_icons_tag | loader case 17939 互证; 定案: writer sub_140BB59C0 = 通用 tag 发射器, **tag>0 门** (零叶不发射, 发射为引号国家串) |
| +316 | u32 | next_bonus_id (ctor/Reset 置 1; 取后自增) | loader case 13286 → sub_1424C08D0(a2, a1+316) 实写 (§4.7.6 dest 透传) |
| +320 | u32 | land doctrine 相关缓存 (注册 doctrine tech 时 `*(ts+320)=sub_140ED79C0(ts,tech)`) | 推定 |
| +328 | vector\<CTechnology*\> 定容 4 | **四军种 doctrine 当前 tech 指针槽: [0]=land / [1]=naval / [2]=air / [3]=special_forces** {cap@336, count@340, alloc@344} | ctor 定容 4; 0X140ED6CD0 按模板 folder 名 memcmp "land/naval/air/special_forces_doctrine_folder" 写入 |

**过滤门 (导出 technologies 时)** — writer 0X140EE5430 四条件或 (定案; bonus 是
叶门非块门):
① `level > 0`; ② `research_points raw i64 > 0`;
③ `level < max_level(模板@tech+352, max@模板+988)` 且科技挂在研究槽
(slots {data@ts+160, count@ts+172}, ∃ slot: `*(*(slot)+24)==tech`;
仅 level<max 时查槽, 且 slots count>0 才进入);
④ `u32@tech+476 ≠ 0` (limited_use_bonus 引用列表计数)。

⚠ **加载顺序注记**: Init 需 +148==0 ("already initialized"); 存档 technologies
块到达时若容器为空 (Init 未跑), ts loader case 11869 查找失败静默 skip。

#### 4.7.1 CTechnology (504B)

**CTechnology** (504B=0x1F8; 双 vtable: 主 vt@+0, TListenerTrait listener vt@+16
{听众列表 data@24, cap@32, count@36, alloc@40}; writer 0X140EE5180;
loader 0X140EE16F0):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | token | name = 模板名 token (ctor `+8=*(template+60)`) | ⚠ template+60=名 token 非数字 id; **GUI: 在研科技名** (slot+24 tech → tech+8 → title 窗; sub_140EDEBB0 → sub_140EC9A60) |
| +48 | 匿名结构 (32B 形状)* | 次级通知列表头 (懒分配; 32B 条 {u32=1, ptr=tech+16, u8, u8}) | 推定 |
| +56 | vector\<16B {def*, u32}\> 24B | **本科技授予的建筑 max_level 加成表** (源自模板+584 48B 条) {cap@64, count@68, alloc@72} | CompleteResearch 将其 max 累积进 ts+88 |
| +80 | vector\<指针\> 24B | **本科技解锁的战斗战术** (源自模板+608 40B 条, 按名查全局表; fallback "nullCombatTactic") {cap@88, count@92, alloc@96} | CompleteResearch 推入 ts+112 |
| +104 | vector\<指针\> 24B | 完成时注入 CProductionStatus 的解锁列表 A (源自模板+632, 库 qword_14332EEC0 解析; 携 design_team) {cap@112, count@116, alloc@120} | 高置信 (疑 equipment variant 族); **GUI: 科技图标回退源** (*(tech+104) 首元 +1000 旗 → 首解锁装备图; 模板图为先) |
| +128 | vector\<指针\> 24B | 完成时注入生产的解锁列表 B (源自模板+656) {cap@136, count@140, alloc@144} | 高置信 |
| +152 | vector\<CSubUnitDefinition*\> 24B | 完成时注入 cc+3952 管理器的解锁列表 (sub_140D0E200(cc+3952, elem, 1)) {cap@160, count@164, alloc@168} | 定案 : 元素 = **CSubUnitDefinition\*** (科技解锁的子单位定义, 非 equipment variant); cc+3952 管理器 = {+32 副本数组 (1656B 克隆, clone ctor 0X1403C77D0, 按 elem+1420 回溯 DB 母本), +56 token RH 去重}, 克隆体 +1471 = 解锁旗 OR 累积; CCountry writer 键 12181 "deployment" 整对象落盘 |
| +176 | vector\<CTechnology*\> 24B | **被本科技门控的后继科技表** (源自模板+860; 同时把本科技注册进对方听众列表, 并写对方 +360=本科技) {cap@184, count@188, alloc@192} | 状态变化逐个 sub_140ED6B50 通知 |
| +200 | vector\<CTechnology*\> 24B | **前置/关联科技表** (源自模板+776; GetTechState 读其 +368 参与本科技状态计算) {cap@208, count@212, alloc@216} | 高置信 |
| +224 | vector 24B | 源自模板+824 列表 (40B 条) 的关联科技 {cap@232, count@236, alloc@240} | 推定 (path/XOR 族) |
| +248 | vector 24B | 源自模板+800 列表的关联科技 (含听众互注册) {cap@256, count@260, alloc@264} | 推定 (path/XOR 族) |
| +272 | vector\<指针\> 24B | **_EquipmentBonuses (per-tech)** {cap@280, count@284, alloc@288} | assert 内层循环址互证 |
| +296 | vector\<40B 条 {def@0, name 串@+8}\> 24B | **_AdvisorBonuses (per-tech)** {cap@304, count@308, alloc@312} | assert 40B 步进名串比较互证 |
| +320 | vector 24B | **特殊项目 (program) 引用表** {data@320, cap@328, count@332, alloc@336} — 元素 u32 = `cc+4008 program_status` 表的键 (program id); 唯一消费点 = 研究成本计算 0X140ED6E30 (`sub_140E76C20(*(*(ts+304)+4008), &v74, tech+320)` 逐 id 查表求和, 并以 loc `BASIC_RESEARCH_TECHNOLOGY_BONUS` / `AMOUNT` 展示) | 定案 (ctor 空 / writer 不发射) |
| +344 | CTechnologyStatus* | 回指 (SetLevel/GetTechState 经它回 ts) | |
| +352 | CTechnologyTemplate* | 模板 (template+988=max_level, +60=名 token, +56=1 基库序, +736=0 基索引, +1312/+1328=XP boost 配置; §4.7.7) | writer/loader/Init 三证 |
| +360 | CTechnology* | **门控科技回链** (本科技被 +176 主之科技门控时指主; InitPostRead `if(!+360)` 才重算 +368) | 高置信; **GUI: 科技图标门** (!tech+360 ∨ sub_140EE3DD0(template+1034 ∨ tech+116==0) — **tech+116 = +104 容器 count** (非独立字段), 图标门第二键) |
| +368 | u32 | **科技状态枚举缓存**: 1=前置齐 / 2=可研究 (默认) / 3=可研究 (含 +360 门控支路) / 4=已研究 (level≥max) / 5=在研 / 6=不可研究 (XP boost 不足等) | 0X140EDEE40 全文; InitPostRead/RefreshAll 重算并通知 |
| +372 | u32 | level | SetLevel=0X140EE34F0 互证; loader case 10348 → sub_1424C08D0(a2, a1+372) 实写 |
| +376 | CGameDate 24B {vt1@+376, hours@+384, vt2@+392} | date (ctor 哨兵 43808760; 门 = 本值≠0 — ctor 恒初始化 → 块写则 date 必写, 未完成科技 = "1.1.1.1"; ADEC0 代理 = a1+392=&vt2) | 定案 |
| +400 | i64 | **加成值累计器** (AddAdvisorBonus `+=def+48`; AddEquipmentBonus `+=bonus+56`; 运行时重算, writer 不写) | 高置信 |
| +408 | fixed×1e-5 | research_points (键 11868) | loader 实写; **GUI: 进度条分子** (tech+408 ∨ slot+32; 分母 = 模板+992×qword_143332BA0/1e5 ∨ qword_143332A38; 归一 1e7; research_progressbar) |
| +416 | fixed×1e-5 | design_team_bonus (键 19165) | ≠0 才写; loader 实写 |
| +424 | fixed×1e-5 | research_points_from_design_team (键 16378) | ≠0 才写; loader 实写 |
| +432 | std::map 根 {count@+440} | **research_points_per_mio** (key=token, value=fixed; 键 19181, RB-tree 遍历) | writer+loader 双证 |
| +448 | fixed×1e-5 | ahead_reduction (键 13284) | ≠0 才写; loader 实写 |
| +456 | fixed×1e-5 | bonus (键 10931) | ≠0 才写 (**叶门**, 不参与块存在门); loader 实写 |
| +464 | vector\<u32\> 24B | limited_use_bonus.uses {cap@472, count@476, alloc@480} uint32 数组 (count<64) | |
| +488 | u8 | **use_experience = _BoostedByXP** (键 15370) | ≠0 才写; assert "_BoostedByXP == false" (technology.cpp:0x82A) 双锚; **GUI: ETA 门** (tech+488 → 剩余天数 ETA_SHORT_D/DAYS; sub_140EDA1B0; 门 = 在研且窗可见) |
| +492 | u32 | design_team 对.type (id 对 {type@492, id@496}) | 任一非零才写; loader case 19159 "双双有效才落"; **GUI: 设计商图标/名** (GFX_research_line_mio_bg; sub_14221F310 + sub_140DB8C20) |
| +496 | u32 | design_team 对.id | |
| +500 | u32 token | **locked_design_team** (键 19182; lexer token 直存, 写出转串) | ≠"undefined"(19479) 才写 |

#### 4.7.2 CResearchSlot (1163B)

**CResearchSlot** (0x48B; ctor 0X140ED2CF0 + loader 内联构造互证):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | token | 名 (占位 10830="empty"; 有在研时 = tech+8 名 token) | RESEARCH_NO_RESEARCH 串常驻化 |
| +16 | CTechnologyStatus* | 回指 | |
| +24 | CTechnology* | 在研 tech | **GUI: 行标题/空槽支路** (tech+8 名 → title 窗; slot+24==0 → UNUSED_SLOT + GFX_research_line_bg + empty_research_slot_glow; 0X141BE4BF0) |
| +32 | fixed×1e-5 | research — **存档键 points** (键 12766; 定名) | **GUI: 进度条分子回退** (tech+408 缺时取本值; research_progressbar) |
| +40 | fixed×1e-5 | progress — **存档键 used_saved_points** (键 13499; 定名) | |
| +48 | u64 | 未知 (ctor/loader 均置 0, writer 不写) | 存在定案 / 语义未决 |
| +56 | fixed×1e-5 | points_factor | ≠100000 才写 (键 13956) |
| +64 | u32 | **槽位序号** (ctor 第三参 = ts+172 当前槽数; SyncSlotsToCount 以之定位) | 定案 |

#### 4.7.3 CLimitedUseTechBonus (2059B)

**CLimitedUseTechBonus** (0x80B; ctor 0X140ED2C20):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | u32 | uses (键 13285) | ≠0 才写 |
| +12 | u32 | **claim** (键 11310; 定名) | |
| +16 | MSVC SSO 32B (size@+32, cap@+40) | name | |
| +48 | u32 | id (ctor 初值 **−1**; AddLimitedUseTechBonus 经 sub_140735C80 落 next_bonus_id) | |
| +56 | vector\<CTechnologyTemplate*\> 24B | **technology 适用列表** (writer 逐条写模板+60 名 token; loader 按名解析+有效性旗模板+64 过滤) {cap@64, count@68, alloc@72} | 键 10335 |
| +80 | vector\<类别 def*\> 24B | **category 适用列表** (writer 写类别对象+44 id) {cap@88, count@92, alloc@96} | 键 702 |
| +104 | fixed×1e-5 | ahead_reduction (键 13284) | |
| +112 | fixed×1e-5 | bonus (键 10931) | |
| +120 | u32 | 尾部字段 (ctor 置 0; writer 不写) | 存在定案 / 语义未决 |

#### 4.7.4 CLimitedUseTechCostReduction (1803B)

**CLimitedUseTechCostReduction** (0x70B; ctor 0X140ED2C90):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | fixed×1e-5 | cost_reduction (键 19537) | |
| +16 | vector\<CTechnologyTemplate*\> 24B | tech 适用列表 {cap@24, count@28, alloc@32} | 键 10335 |
| +40 | u32 | uses (键 13285) | |
| +48 | MSVC SSO 32B (size@+64, cap@+72) | name | |
| +80 | u32 | id (ctor 初值 **−1**) | |
| +88 | vector\<类别 def*\> 24B | **category 适用列表**  {cap@96, count@100, alloc@104} | 键 702 |

#### 4.7.5 writer/loader 键速查 (本族全部存档键)

**ts writer (0X140EE5430) 键表** (载体列 = 对象@容器/字段):

| 键 (token) | 载体 | 备注 |
|---|---|---|
| override_icons_tag (17939) | ts+312 | |
| technologies (11869) | ts+136 容器 (count@+148) | 多块发射 |
| slots (11879) | ts+160 容器 (count@+172) | loader 逐槽 malloc(0x48) |
| next_bonus_id (13286) | ts+316 | loader 实写 (§4.7.6) |
| limited_use_bonus (13283) | ts+232 容器 (count@+244) | |
| limited_use_cost_reduction_bonus (19531) | ts+256 容器 (count@+268) | |

**CTechnology writer (0X140EE5180) 键序** (行序 = 落盘序):

| 序 | 键 (token) | 字段 | 备注 |
|---|---|---|---|
| 1 | level (10348) | tech+372 | loader 实写 |
| 2 | research_points (11868) | tech+408 | loader 实写 |
| 3 | research_points_per_mio (19181) | tech+432 (map, RB-tree 遍历) | |
| 4 | ahead_reduction (13284) | tech+448 | loader 实写 |
| 5 | bonus (10931) | tech+456 | ≠0 叶门 |
| 6 | limited_use_bonus (13283) | tech+464 (u32 数组) | 门 count@476 ≠0 且 >0; 落盘 = 数组恒单行 (逐值 sub_1424C2A10 同线写 + 尾一次换行), 叶值 = 全值空格连接 (#1 单叶, Red_Dusk SWE "20 21" 实证) |
| 7 | date (10314) | tech+376..+399 (ADEC0 代理@+392) | |
| 8 | use_experience (15370) | tech+488 | ≠0 才写 |
| 9 | design_team (19159) | tech+492/+496 | id 对 |
| 10 | locked_design_team (19182) | tech+500 | ≠"undefined"(19479) 才写 |
| 11 | design_team_bonus (19165) | tech+416 | ≠0 才写; loader 实写 |
| 12 | research_points_from_design_team (16378) | tech+424 | ≠0 才写; loader 实写 |

loader 弃键: sprite_level (10524, ts 侧) / 13854 / 11013 / 19537 (tech 侧, 判块跳过)。

#### 4.7.6 loader 读键落字段 (无「读弃」旁路)

CTechnology per-key loader (0X140EE16F0) 的六个数值键
(level/research_points/ahead_reduction/bonus/design_team_bonus/rp_from_design_team)
与 use_experience (ts 侧 next_bonus_id 同) **全部正常落字段**。

> **隐式 dest 透传 (reload 族 reader 通则)**: 读取帮手 `sub_1424C08D0` / `sub_1424C0A70` /
> `sub_1424C0C00` 的签名只显示 `(ctx)` 一参，**实为 `(ctx, dest)` 双参** —— 帮手自身
> 不碰 rdx，而内层校验器把 rdx 原样透传给解析原语：
> `sub_1424C08D0` → `sub_1424C5220` (0x1424C5237 `mov r8, rdx`) → `sub_14029D420(str, "%i", dest)`
> (vsscanf 形: rcx=串 / rdx=格式 / r8=dest)；
> `sub_1424C0C00` → `sub_1424C5640` (0x1424C5684 `mov byte ptr [rdx], 1` / 0x1424C56B8 `mov byte ptr [rdx], dil` = yes/no 双写)。
> 故调用点 `sub_1424C08D0(a2, a1+372)` 的第二参即 dest，值确实写入该字段。

#### 4.7.7 CTechnologyTemplate (科技模板; 跨类副产布局)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +56 | u32 | 1 基库序 | tech+352 行互证 |
| +60 | token | 名 token | 非数字 id |
| +64 | u8 | 有效旗 | lub loader 按之过滤 |
| +336 | — | 完成效果块 | |
| +392 | — | 完成 modifier | |
| +584 | 48B 条列表 | 建筑 max_level 加成列表 | tech+56 源 |
| +608 | 40B 条列表 | 战术列表 (计数@+620) | tech+80 源 |
| +632 | 匿名结构 (元素待裁) 向量 | 生产解锁列表 A (计数@+644) | tech+104 源 |
| +656 | 匿名结构 (元素待裁) 向量 | 生产解锁列表 B (计数@+668) | tech+128 源 |
| +776 | 匿名结构 (元素待裁) 向量 | 前置列表 (计数@+788) | tech+200 源 |
| +800 | 匿名结构 (元素待裁) 向量 | 关联科技列表 | 含听众互注册; tech+248 源 |
| +824 | 40B 条列表 | 关联科技列表 | tech+224 源 |
| +860 | 匿名结构 (元素待裁) 向量 | 被门控后继列表 | tech+176 源 |
| +984 | u32 | 科技可用年 | >0 门 (year 窗直证) |
| +988 | u32 | max_level | |
| +992 | — | 基础成本 | 进度条分母: ×qword_143332BA0/1e5 ∨ 空槽 qword_143332A38 |
| +1034 | bool | **force_use_small_tech_layout** (reader case 19623) | 科技图标门第二键 ∨ tech+116==0; 邻 +1036 = **show_equipment_icon** (reader case 13950) |
| +1104 | CAIResearchNeed 32B | **research 需求聚合** (need 条目 16B {token u32, need i64}; 向量 data@+1112; ctor 内联 sub_1413C4F10) | §4.34.6 |
| +1136 | 匿名结构 (NNB 形状) | **on_research_complete_limit** 触发器 (ctor sub_140549F40) | reader case 13738 limit 分支 (vt+40) / case 19672 |
| +1224 | 匿名结构 (NNB 形状) | **on_research_complete** 效果 (ctor sub_14053CFD0) | reader case 13738 (vt+24) |
| +1312 | u32 | XP boost 配置 | IsBoostableByXP = +1312≠0 且 +1328>0 |
| +1320 | — | XP boost 配置 | |
| +1328 | — | XP boost 配置 | >0 门 |

**解锁列表元素** (tech+104 列表首元):

| 元素+N | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +1000 | — | 首解锁旗 | → 首解锁装备图 (模板图为先, §4.7.1 +104 行) |

建筑 def (另族): +736 = 库内 0 基索引 (ts+88 快查表下标); +492=u8 /
+696/+700 = max_level 族 (0X1414BA740 消费)。

#### 4.7.8 CSelectTechTreeIconOrigin (科技树图标起源效果)

纯效果类: Parse → effect+88 tag token; Execute → ts = `*(cc+3936)`, 写
ts+312 override_icons_tag (与 §4.7 主表 +312 行双锚互证), 刷科技树 GUI。

#### 4.7.9 特殊项目 (special project) 状态机与 def 侧

**CProjectStateMachine** (616B; vt 0x142A300B8; COL 0x142D5EBD0; CHD nbases=2: self + CPersistent;
ctor 0x141A35060) = **内联三元状态容器** (非常规派生族):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | 匿名结构 (union 指针) | **current state 指针** (指向 +24 / +232 / +360 / +488 之一, 或自指 +24 表示「无状态」) | reader 0x141A37880 `*(a1+8) = a1+24` / `= v10` |
| +16 | u8 | **tag 有效门**: 1 = +8 指向自身 (+24) 即「无当前状态」; 0 = 指向实状态 | 同上 |
| +24 | CPrototypeProjectState (208B) | **slot 0 = PROTOTYPE_STATE** | 见下 |
| +232 | CSimpleProjectState (128B) | **slot 1 = RESEARCH_COMPLETED** | 见下 |
| +360 | CSimpleProjectState (128B) | **slot 2 = STOPPING_STATE** | 见下 |
| +488 | CSimpleProjectState (128B) | **slot 3 = STOPPED_STATE** | 见下 |

**状态名常量表** (字符串对象 = MSVC std::string 32B `{buf@+0 (16B), size@+16, cap@+24}`):

| slot | 串长 / SSO cap | 状态名 |
|---|---|---|
| 0 (+24) | 15 / 15 | PROTOTYPE_STATE |
| 1 (+232) | 18 / 31 (堆, malloc 0x20) | RESEARCH_COMPLETED |
| 2 (+360) | 14 / 15 | STOPPING_STATE |
| 3 (+488) | 13 / 15 | STOPPED_STATE |

> `.rdata` 同区串表 (VA 0x142A303A0 起) 依次 = `..._PROTOTYPE_PHASE` / `PROTOTYPE_STATE` /
> `RESEARCH_COMPLETED` / `STOPPING_STATE` / `STOPPED_STATE` / `SPECIAL_PROJECT_RESEARCH_TIME_TOOLTIP_TOTAL` /
> `REMAINING_DAYS`; 四串精确 file offset = 0x2A2E998 / 0x2A2E9A8 / 0x2A2E9C0 / 0x2A2E9D0。
> slot 0 的串在 ctor 里被 `CPrototypeProjectState::vftable` 覆写取代, 故 ctor 内无 strcpy (高置信)。
> **精度有损** (round-trip 后 `PROTOTYPE_STATE` 变 `RROTOTYPE_STATE`) — 凡从 double 立即数
> 反解字符串, 必须回 exe 按 ASCII 直搜复核。

**状态迁移** (reader 0x141A37880 的 switch, 键 = 14059 current_state):

| current_state 值 | 目标 |
|---|---|
| 0 | `*(a1+8) = a1+24` (无状态) |
| 1 | a1+232 (RESEARCH_COMPLETED / Simple) |
| 2 | a1+360 (STOPPING_STATE / Simple) |
| 3 | a1+488 (STOPPED_STATE / Simple) |
| default | 断言 `"bad state for project state machine"` (project_state.cpp:629), 回落 = 无状态 |

**writer 0x141A37CD0 发射键表** (只三键):

| 键 | 值 | 说明 |
|---|---|---|
| 14059 current_state | `*(u32*)(*(u64*)(this+8) + 120)` | = 当前 state 对象的 +120 (即 0/1/2/3) — 与「+120 = 状态枚举 id」互为铁证 |
| 10018 prototype_state | sub_1424C2E20(stream, this+24) | slot 0 整块 |
| 10045 stopping_state | sub_1424C2E20(stream, this+360) | slot 2 整块 |

> ⇒ **只有 +24 (prototype) 与 +360 (stopping) 两块内容被序列化**; +232 / +488 两槽仅靠
> `current_state` 索引在 reader 里指回去, 其 phase_progress 不落盘 (默认 0) — 语义自洽:
> RESEARCH_COMPLETED / STOPPED_STATE 是终态标记, 无进行中进度 (高置信)。
> writer 开头 `if (*(char*)(this+16) == -1) sub_140722EC0(&v6, this+8)` = +8/+16 联合体的
> 惰性初始化守卫 (与 reader 的 +16 门呼应)。
> **迁移单向链 (推定)**: slot 0 → slot 1 → slot 2 → slot 3; reader 的 switch 无 case 指向 +24
> ⇒ 载档后 `current_state == 0` 即「无状态」, 不可能再回 PROTOTYPE_STATE; slot 0 的进入点未定位。
> 断言串给出源文件 = `special_projects/projects/project_state.cpp`。

**CBaseProjectState** (128B; vt 0x142A2FFB0; COL 0x142D5E9F0; CHD nbases=2: self + CPersistent):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | 0x141A35570 | 析构 (sub_141A35480 + free) |
| [1] | 0x1424BEC50 | **Save wrapper** (CPersistent 全族同址指纹) |
| [2] | 0x141A37CB0 | **writer 本体** = `write(10251 phase_progress, *(qword*)(this+72))` |
| [3] | 0x1424BE690 | **Load wrapper** (同址指纹) |
| [4] | 0x141A37790 | **reader 本体** = 仅认 10251 → this+72; 否则报 `"Unexpected token when parsing project state"` |
| [5] | 0x14011D220 | `return 0` 桩 (CPersistent [5] 同址) |
| [9] | 0x141A357A0 | **CopyAssign**: 拷 +72 (qword) + +80 (u32), 不带 vptr |

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | 匿名结构 (88B 块) | **内嵌回调/监听体** {+8 自指/链表头, +16 u8 门=1, +24 函数对象 56B, +80 槽} — 析构 sub_141A35480 读 `+8+112` 容量判堆/内联 (SSO 上限 15) | ctor + dtor |
| +72 | i64 | **phase_progress** (键 10251) — 本状态内进度 | writer/reader |
| +80 | u32 | phase_progress 尾槽 (与 +72 同写同拷; 推定 = 进度分母/门) | writer 0x141A37CB0 |
| +88 | MSVC 串 32B | 状态名 {buf@+88, size@+104, cap@+112=15} | ctor |
| +120 | u32 | **状态枚举 id** (0/1/2/3, 与 SM switch 的 current_state 同域) | ctor 三处写 1/2/3 |

**CPrototypeProjectState vs CSimpleProjectState** (两者 CHD 均 nbases=3, sizeof 差 8):

| 项 | CPrototypeProjectState (vt 0x142A30060) | CSimpleProjectState (vt 0x142A30008) |
|---|---|---|
| 状态枚举 +120 | 0 | 1 / 2 / 3 (三实例) |
| 额外字段 | +128 u32 / +132 u32 / +136 u32 / +140 u32 | 无 (sizeof = 基 + 8) |
| writer [2] | **0x141A37D50** 覆写: 先 `write(10252 project_progress, *(u32*)(this+136))` → `write(16380 iterations, *(u32*)(this+140))` → 基 writer (10251) | 继承基 0x141A37CB0 (只写 10251) |
| reader [4] | **0x141A37AA0** 覆写: 10252 → +136 / 16380 → +140 / 10251 → +72 | 继承基 0x141A37790 |
| CopyAssign [9] | **0x141A35820** 覆写: +128/+132/+136/+140 + +72/+80 | 继承基 0x141A357A0 (只 +72/+80) |
| dtor [0] | 0x141A35650 | 0x141A35570 (与基同址) |

> **语义**: 只有 prototype 态需要双进度轴 — phase_progress (10251) = 当前阶段内进度,
> project_progress (10252) = 项目总进度, iterations (16380) = 原型迭代次数。三 Simple 态
> (完成 / 停止中 / 已停) 只需阶段进度 ⇒ 不覆写 writer/reader (定案)。
> +128 / +132 只在 CopyAssign 里被拷、无 writer/reader 键 ⇒ 运行时缓存 (高置信)。

**CNarrative** (72B; vt 0x14271B0B8; 基 CPersistent; reader 0x140A91F50):

| 偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +8 | MSVC 串 32B | 27 name | 叙事名 |
| +40 | MSVC 串 32B | 10644 desc | 叙事描述文本 |

> reader 只有两键 ⇒ CNarrative = **项目叙事文本对 (name/desc)**; writer 空桩 ⇒ 不入存档。

**CComplexity** (vt 0x1427C5020; 基 CPersistentWithToken; reader 0x141465300) —
它是 **CProjectTemplate 的成员子对象** (不是基类): ctor 链 = `sub_140A932C0(template)` →
`*(template) = CProjectTemplate::vftable` → `sub_140A93320(template+24)` 构造 CComplexity 成员;
CPersistent 基子对象 (vptr 落点) = **template+32**。

> **基准约定**: 下表 `B` = CComplexity 的 CPersistent 基子对象基址 = template+32
> (reader 的 this 即 B); token 在 **B−8**。

| 偏移 (相对 B) | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| −8 | u32 | — | **token = 19479 `undefined`** |
| +0 | vtable | — | CComplexity vptr (= template+32) |
| +8 | u32 | 675 min | **复杂度下限** (默认 = dword_1433321F4) |
| +12 | u32 | 676 max | **复杂度上限** (默认同上) |
| +16 | u64 | — | 0 (ctor `*(_OWORD*)(C+8) = 0` 覆盖 +8..+23) |
| +24 | NProject::SOutput vt | — | SOutput 子对象 |
| +32 | 匿名结构 (88B) | — | effect/条件体 (ctor sub_14053CFD0) |
| +120 | 匿名结构 (88B) | — | 同上 |
| +208 | 匿名结构 (88B) | — | 同上 |
| +296 | 匿名结构 | — | (ctor sub_1406419E0) |
| +352 | 指针 | — | 空 |
| +360 | 指针 | — | 空 |
| +368 | 匿名结构 (容器) | — | {allocator, data, 尾} 同构三组 (与 +376/+384) |
| +376 | 匿名结构 (容器) | — | {allocator, data, 尾} 同构三组 (与 +368/+384) |
| +384 | 匿名结构 (容器) | — | {allocator, data, 尾} 同构三组 (与 +368/+376) |
| +440 | 匿名结构 | — | — |
| +456 | u8 | — | 门 |
| +464 | CNarrative vt | — | **CNarrative 子对象起点** (= CProjectTemplate+496) |
| +472 | MSVC 串 32B | — | CNarrative name |
| +504 | MSVC 串 32B | — | CNarrative desc |
| +536 | MSVC 串 32B | — | CComplexity 自有串 (三串组) |
| +568 | MSVC 串 32B | — | CComplexity 自有串 (三串组) |
| +600 | MSVC 串 32B | — | CComplexity 自有串 (三串组) |
| +632 | 匿名结构 | — | (ctor sub_14011DF40) |
| +656 | 匿名结构 (88B) | — | (ctor sub_140549F40) |
| +744 | 匿名结构 (88B) | — | (ctor sub_140549F40) |
| +840..+1064 | 容器/分配器/字节混布 | — | locale/哈希桶等 |
| +1080 | — | — | 尾 (推定 sizeof ≈ 1088) |

> **复杂度参数语义**: min / max = 该模板在复杂度轴上的取值区间 (键 675/676);
> CComplexity 的 reader 只有这两键 ⇒ 其余字段全是运行时容器 (高置信)。
> 校验函数 = slot[7] **0x141465030** (源文件 `special_projects/projects/project_complexity.cpp`),
> 两条诊断: `"in Complexity <name>, there is no values set. Using default"` (行 41) /
> `"in Complexity <name>, invalid values. No progress can be made. Using default"` (行 47)。
> 判据 (定案): `v7[5] <= 0` (即 max ≤ 0) 且 `v7[4] & 0x80000000` (min < 0) → 非法; 两者皆空 → 用默认值。
> ⇒ **min ≥ 0 且 max > 0** 是合法条件。

**CProjectTemplate 侧挂载点** (def 顶层; 与本族相关的键):

| 键 | → 偏移 | 落到 |
|---|---|---|
| 10032 complexity | template+32 | CComplexity 子对象 (其 vptr) |
| 11620 narrative | template+496 | CComplexity 内的 CNarrative 子对象 (其 vptr) |
| 10819 ai_will_do | template+1016 | — |
| 10028 special_project_parent | template+664 | — |
| 10044 empty_reward_weight | template+904 | 带门 `+960 u8` 的块 |
| 10126 breakthrough_cost | (循环) | 专精突破成本表 (校验 `"Breakthrough cost of specialization: "`) |
| 15606 project_tags | template+776 | — |
| 16388 unique_prototype_rewards | template+880 | `CInlinableGameItem<CPrototypeReward>` reader |
| 17462 resource_cost | template+968 | — |
| 17468 generic_prototype_rewards | template+880 | 同上 (SUniformReader variant) |
| 11562 visible | template+688 | CTrigger 子对象 |

> CProjectTemplate sizeof ≥ 1144 (ctor 尾部 `sub_140549F40(a1+1112)`), writer 空桩;
> vt 0x142940798, COL 0x142CC3988, 基 CPersistentWithToken ← CPersistent, ctor 0x140A932C0。

> **本域 GUI 类布局**: 见 4.30.23 / 4.31.21 / 4.31.35。
