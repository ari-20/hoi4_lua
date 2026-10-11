

### 4.7 CTechnologyStatus (科技)

**获取**: `ts = *(cc + 3936)`; **vtable RVA 0X2974FA0**; sizeof **352** (0x160, malloc 直证); ctor 0X140ED3E80;
writer 0X140EE5430。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CSubUnitStatBonus 内嵌 56B | 子单位加成累计器 {vtable@+8, 向量@{+16,+24,+28,+32} 与 {+40,+48,+52,+56}} | ctor sub_1406419E0 直写 vtable; Reset sub_140641D40 |
| +64 | vector\<CTechnology*\> 24B | **_ResearchedTechs** (已完成科技, 按 tech+8 名 token 排序的二分查找容器) {cap@72, count@76, alloc@80} | assert "_ResearchedTechs.Contains( pTechnology ) == false" (technology.h:0x27D); loader case 11869 在 level≥max 时二分插入 |
| +88 | vector\<uint32\> 24B | **per-建筑 max_level 加成缓存** (按建筑 def+736 索引; 完成科技时按 tech+56 {def*,u32} 对 max 累积) {cap@96, count@100, alloc@104} | 写点 0X140EE3E70 `ts88[4*def+736]=max(cur,val)`; 消费 0X1411731F0 配 loc BUILDING_CURRENT_MAX_LEVEL_CAPPED |
| +112 | vector\<指针\> 24B | **国家可用战斗战术 (combat tactics) 累积表** (元素=tactic 对象, id@elem+148 去重) {cap@120, count@124, alloc@128} | 完成科技时把 tech+80 元素按 +148 去重 push; fallback 构造串 "nullCombatTactic" |
| +136 | vector\<CTechnology*\> 24B | technologies {cap@144, count@148, alloc@152} — **元素 8B 指针** (count<4096) | 导出须过滤门 (下) |
| +160 | vector\<CResearchSlot*\> 24B | slots {cap@168, count@172, alloc@176} — **元素 8B 指针** (writer 双重解引用直证; 对象 72B) | loader case 11879 逐槽 malloc(0x48); **GUI: 研究槽行** (research_slots_grid; Repopulate@48[9] 0X1415FA1A0 → 0X1415FA300 建行 CResearchSlotItem(0x580), item+1336=slot; 可见门 sub_1415FB5D0 非本人槽不画) |
| +184 | vector\<指针\> 24B | **_EquipmentBonuses** (国家侧生效装备加成列表) {cap@192, count@196, alloc@200} | 国家侧去重 = 0x140ED5340 线性查 (无断言); assert "!_EquipmentBonuses.Contains( &Bonus )" (technology.cpp:1495) 载体同函但校验对象 = per-tech tech+272/+284 表 |
| +208 | vector\<40B 条 {def ptr@0, name 串@+8..}\> 24B | **_AdvisorBonuses** (国家侧顾问/加成列表) {cap@216, count@220, alloc@224} | assert "!_AdvisorBonuses.Contains( Bonus )" (technology.cpp:0x5E5) |
| +232 | vector\<CLimitedUseTechBonus*\> 24B | limited_use_bonus {cap@240, count@244, alloc@248} — **元素 8B 指针** (对象 128B); **per-tech lub 块 BlackICE 实测峰值 115 (GER/bi8), 防御界须 ≥256** | loader case 13283 malloc(0x80)+push |
| +256 | vector\<CLimitedUseTechCostReduction*\> 24B | cost_reduction {cap@264, count@268, alloc@272} — **元素 8B 指针** (对象 112B) | loader case 19531 增长码全四元组 |
| +280 | vector\<CTechnologySharingGroup*\> 24B | **本国 technology sharing group 成员表** (组 id@elem+8) {cap@288, count@292, alloc@296} | CModifyTechnologySharingBonusEffect::Execute 0X14031FB10 → sub_140ED5110 按组 id 查找; Add/Remove 效果经 gs 管理器 push/erase |
| +304 | CCountry* | 回指 (ctor 参数 a2) | +312=`*(a2+8)` 即国 tag 初值 |
| +312 | uint32 | override_icons_tag | loader case 17939 互证; 定案: writer sub_140BB59C0 = 通用 tag 发射器, **tag>0 门** (零叶不发射, 发射为引号国家串) |
| +316 | uint32 | next_bonus_id (ctor/Reset 置 1; 取后自增) | loader case 13286 → sub_1424C08D0(a2, a1+316) 实写 (§4.7.6 dest 透传) |
| +320 | uint32 | **land doctrine 等级缓存** (doctrine tech 注册 sub_140ED6CD0 写 = sub_140ED79C0 计算值; land_doctrine_level 触发器读) | 定案 |
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

**CTechnology** (504B=0x1F8; 双 vtable: 主 vtable@+0, TListenerTrait listener vtable@+16
{听众列表 data@24, cap@32, count@36, alloc@40}; writer 0X140EE5180;
loader 0X140EE16F0):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | token | name = 模板名 token (ctor `+8=*(template+60)`) | ⚠ template+60=名 token 非数字 id; **GUI: 在研科技名** (slot+24 tech → tech+8 → title 窗; sub_140EDEBB0 → sub_140EC9A60) |
| +48 | 匿名结构 (32B 形状)* | 次级通知列表头 (懒分配; 32B 条 {u32=1, ptr=tech+16, u8, u8}) | 推定 |
| +56 | vector\<16B {def*, uint32}\> 24B | **本科技授予的建筑 max_level 加成表** (源自模板+584 48B 条) {cap@64, count@68, alloc@72} | CompleteResearch 将其 max 累积进 ts+88 |
| +80 | vector\<指针\> 24B | **本科技解锁的战斗战术** (源自模板+608 40B 条, 按名查全局表; fallback "nullCombatTactic") {cap@88, count@92, alloc@96} | CompleteResearch 推入 ts+112 |
| +104 | vector\<指针\> 24B | 完成时注入 CProductionStatus 的解锁列表 A (源自模板+632, 库 qword_14332EEC0 解析; 携 design_team) {cap@112, count@116, alloc@120} | 高置信 (equipment variant 族); **GUI: 科技图标回退源** (*(tech+104) 首元 +1000 旗 → 首解锁装备图; 模板图为先) |
| +128 | vector\<指针\> 24B | 完成时注入生产的解锁列表 B (源自模板+656) {cap@136, count@140, alloc@144} | 高置信 |
| +152 | vector\<CSubUnitDefinition*\> 24B | 完成时注入 cc+3952 管理器的解锁列表 (sub_140D0E200(cc+3952, elem, 1)) {cap@160, count@164, alloc@168} | 定案 : 元素 = **CSubUnitDefinition\*** (科技解锁的子单位定义, 非 equipment variant); cc+3952 管理器 = {+32 副本数组 (1656B 克隆, clone ctor 0X1403C77D0, 按 elem+1420 回溯 DB 母本), +56 token RH 去重}, 克隆体 +1471 = 解锁旗 OR 累积; CCountry writer 键 12181 "deployment" 整对象落盘 |
| +176 | vector\<CTechnology*\> 24B | **被本科技门控的后继科技表** (源自模板+848 容器; 同时把本科技注册进对方听众列表, 并写对方 +360=本科技) {cap@184, count@188, alloc@192} | 状态变化逐个 sub_140ED6B50 通知 |
| +200 | vector\<CTechnology*\> 24B | **前置/关联科技表** (源自模板+776; GetTechState 读其 +368 参与本科技状态计算) {cap@208, count@212, alloc@216} | 高置信 |
| +224 | vector 24B | **互斥科技表** (源自模板+824, 脚本键 XOR; CompleteResearch sub_140EE1270 互斥门: 任一 +368==4 已研究 → 断言拒绝) {cap@232, count@236, alloc@240} | 定案 |
| +248 | vector 24B | **path 族引用** (研究路径树, 源自模板+800; 含听众互注册) {cap@256, count@260, alloc@264} | 定案 |
| +272 | vector\<指针\> 24B | **_EquipmentBonuses (per-tech)** {cap@280, count@284, alloc@288} | assert 内层循环址互证 路由写点 = 0x140ED5340 (AddEquipmentBonus 国家侧入口: ts+184 去重 → etype+56 科技 token 表逐 tech push + tech+400 += bonus+56); per-tech 摘除 = 0x140EE27D0 (断言 :1516 Contains, erase + tech+400 -= entry+48); 国家侧全清 = 0x140EE2610 (pop-back + def+56 受影响科技表 1 基下标 → ts+136 数组级联, :3245 越界兜底) |
| +296 | vector\<40B 条 {def@0, name 串@+8}\> 24B | **_AdvisorBonuses (per-tech)** {cap@304, count@308, alloc@312} | assert 40B 步进名串比较互证 |
| +320 | vector 24B | **特殊项目 (program) 引用表** {data@320, cap@328, count@332, alloc@336} — 元素 u32 = `cc+4008 program_status` 表的键 (program id); 唯一消费点 = 研究成本计算 0X140ED6E30 (`sub_140E76C20(*(*(ts+304)+4008), &v74, tech+320)` 逐 id 查表求和, 并以 loc `BASIC_RESEARCH_TECHNOLOGY_BONUS` / `AMOUNT` 展示) | 定案 (ctor 空 / writer 不发射) |
| +344 | CTechnologyStatus* | 回指 (SetLevel/GetTechState 经它回 ts) | |
| +352 | CTechnologyTemplate* | 模板 (template+988=max_level, +60=名 token, +56=1 基库序, +736=0 基索引, +1312/+1328=XP boost 配置; §4.7.7) | writer/loader/Init 三证 |
| +360 | CTechnology* | **门控科技回链** (本科技被 +176 主之科技门控时指主; InitPostRead `if(!+360)` 才重算 +368) | 高置信; **GUI: 科技图标门** (!tech+360 ∨ sub_140EE3DD0(template+1034 ∨ tech+116==0) — **tech+116 = +104 容器 count** (非独立字段), 图标门第二键); 研究 tooltip 步 A: 非空且 level < tpl+988 (未满级) → 发单条需求行 (dg053) |
| +368 | uint32 | **科技状态枚举缓存**: 0=ctor 态 / 1=前置齐 / 2=可研究 (默认) / 3=可研究 (含 +360 门控支路) / 4=已研究 (level≥max) / 5=在研 / 6=不可研究 (XP boost 不足等) | 0X140EDEE40 全文; InitPostRead/RefreshAll 重算并通知 |
| +372 | uint32 | level | SetLevel=0X140EE34F0 互证; loader case 10348 → sub_1424C08D0(a2, a1+372) 实写 |
| +376 | CGameDate 24B {vtable1@+376, hours@+384, vtable2@+392} | date (ctor 哨兵 43808760; 门 = 本值≠0 — ctor 恒初始化 → 块写则 date 必写, 未完成科技 = "1.1.1.1"; ADEC0 代理 = a1+392=&vtable2) | 定案 |
| +400 | int64 | **加成值累计器** (AddAdvisorBonus `+=def+48`; AddEquipmentBonus `+=bonus+56`; 运行时重算, writer 不写) | 高置信 |
| +408 | fixed×1e-5 | research_points (键 11868) | loader 实写; **GUI: 进度条分子** (tech+408 ∨ slot+32; 分母 = 模板+992×qword_143332BA0/1e5 ∨ qword_143332A38; 归一 1e7; research_progressbar) |
| +416 | fixed×1e-5 | design_team_bonus (键 19165) | ≠0 才写; loader 实写 |
| +424 | fixed×1e-5 | research_points_from_design_team (键 16378) | ≠0 才写; loader 实写 |
| +432 | std::map 根 {count@+440} | **research_points_per_mio** (key=token, value=fixed; 键 19181, RB-tree 遍历) | writer+loader 双证 |
| +448 | fixed×1e-5 | ahead_reduction (键 13284) | ≠0 才写; loader 实写 |
| +456 | fixed×1e-5 | bonus (键 10931) | ≠0 才写 (**叶门**, 不参与块存在门); loader 实写 |
| +464 | vector\<uint32\> 24B | limited_use_bonus.uses {cap@472, count@476, alloc@480} uint32 数组 (count<64); **元素 = 待兑现有限用途加成 id** (lub+48 键匹配 ts+232 / cr+80 键匹配 ts+256; 兑现链 0x140EE3680 摘除元素, 释放链 0x140ED9A20 — 详见 §4.7.3) | |
| +488 | uint8 | **use_experience = _BoostedByXP** (键 15370) | ≠0 才写; assert "_BoostedByXP == false" (technology.cpp:0x82A) 双锚; **GUI: ETA 门** (tech+488 → 剩余天数 ETA_SHORT_D/DAYS; sub_140EDA1B0; 门 = 在研且窗可见) |
| +492 | uint32 | design_team 对.type (id 对 {type@492, id@496}) | 任一非零才写; loader case 19159 "双双有效才落"; **GUI: 设计商图标/名** (GFX_research_line_mio_bg; sub_14221F310 + sub_140DB8C20) |
| +496 | uint32 | design_team 对.id | |
| +500 | uint32 token | **locked_design_team** (键 19182; lexer token 直存, 写出转串) | ≠"undefined"(19479) 才写 |

> **_ResearchedTechs 增删对** (technology.h:637/642; 共用二分下界模板, 键 = tech+8 名 token): **AddResearchedTech 0x140ED5930** (断言 "_ResearchedTechs.Contains( pTechnology ) == false" :637) → sub_140EE0FF0(ts+64, scratch, &tech) 有序插入; **RemoveResearchedTech 0x140EE2BD0** (断言 "_ResearchedTechs.Contains( pTechnology )" :642) → 二分定位 → memcpy 尾部前移覆盖 → --count@+76 (无 cap 回缩)。两函均被 **SetLevel 0x140EE34F0** (jmp 形) 及 0x140EDFFB0 / 0x140EE2D30 (call 形) 调用 ⇒ **等级 ≥ max 入册 / 否则出册**, 与过滤门①②及 loader case 11869 三向闭合。

#### 4.7.2 CResearchSlot (72B)
#### 4.7.1a 子单位加成来源持久化 (subunit_stat_bonus_persistent.cpp; 1 函 = 0x14197F890 — 新收)

来源持久化对象读取器 (类名推定 CSubUnitStatBonusPersistent, 无 RTTI 直证): a1+8 内嵌 CSubUnitStatBonus (56B, 本节 CTechnology+8 同体) 负责未派发 token; 自身字段 = +64 来源类型枚举 u32 / +68 来源名 token id / +72 数量 / +80 本地化键 std::string。token 派发:

| token id | 名 | 处理 |
|---|---|---|
| 11 | id | sub_1424C0960 → a1+68 (读 token id u32) |
| 225 | type | 读 token id → a1+64 枚举 (下表); 未命中 → :33 "Unkown subunit bonus source type" (原文拼写) |
| 19053 | number | sub_1424C08D0 读整数 (是否写 +72 待裁: §4.00 reader 单参定义 vs 本处双参调用) |
| 799 | localization_key | sub_1424C0AB0 → a1+80 读串 (a3=0 拒绝含换行符的串) |
| 其他 | — | 委派 a1+8 内嵌对象 vtable 槽 [4] (CPersistent reader, §4.00.1) |

type → 来源类型枚举 (token id → 枚举值): 10022 project → 1 / 89 effect → 2 / 16775 grand_doctrine → 3 / 16778 sub_doctrine → 4 / 16770 rewards → 5 / 16771 milestones → 6。


**CResearchSlot** (72B; ctor 0X140ED2CF0 + loader 内联构造互证):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | token | 名 (占位 10830="empty"; 有在研时 = tech+8 名 token) | RESEARCH_NO_RESEARCH 串常驻化 |
| +16 | CTechnologyStatus* | 回指 | |
| +24 | CTechnology* | 在研 tech (reader case 12766 落 points 后附带清 slot+24 — 读档即解除在研) | **GUI: 行标题/空槽支路** (tech+8 名 → title 窗; slot+24==0 → UNUSED_SLOT + GFX_research_line_bg + empty_research_slot_glow; 0X141BE4BF0) |
| +32 | fixed×1e-5 | research — **存档键 points** (键 12766; 定名) | **GUI: 进度条分子回退** (tech+408 缺时取本值; research_progressbar) |
| +40 | fixed×1e-5 | progress — **存档键 used_saved_points** (键 13499; 定名) | |
| +48 | u64 | **死字段 (负定案)**: 全语料无运行时写者 (ctor/loader 置 0, SetTechnology/daily 链均不触) | 保留槽 |
| +56 | fixed×1e-5 | points_factor | ≠100000 才写 (键 13956) |
| +64 | uint32 | **槽位序号** (ctor 第三参 = ts+172 当前槽数; SyncSlotsToCount 以之定位) | 定案 |

#### 4.7.3 CLimitedUseTechBonus (128B)

**CLimitedUseTechBonus** (128B; ctor 0X140ED2C20):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | uses (键 13285) | ≠0 才写 |
| +12 | uint32 | **claim** (键 11310; 定名) | |
| +16 | MSVC SSO 32B (size@+32, cap@+40) | name | |
| +48 | uint32 | id (ctor 初值 **−1**; AddLimitedUseTechBonus 经 sub_140735C80 落 next_bonus_id) | |
| +56 | vector\<CTechnologyTemplate*\> 24B | **technology 适用列表** (writer 逐条写模板+60 名 token; loader 按名解析+有效性旗模板+64 过滤) {cap@64, count@68, alloc@72} | 键 10335 |
| +80 | vector\<类别 def*\> 24B | **category 适用列表** (writer 写类别对象+44 id) {cap@88, count@92, alloc@96} | 键 702 |
| +104 | fixed×1e-5 | ahead_reduction (键 13284) | |
| +112 | fixed×1e-5 | bonus (键 10931) | |
| +120 | uint32 | **死字段 (负定案)**: 无写者 (ctor 置 0; id 分配器只写 +48; uses 消耗链不触) | 保留槽 |

> reader = 0x1413CF8C0 (vtable 0x1429750A0 [4]): 键 13285→+8 / 11310→+12 / 27→+16 串 / 11→+48 / 10335→+56 (模板+64 有效门, 失败 → "No tech named %s at: %s" :41) / 702→+80 (类别 def+48 有效门) / 13284→+104 / 10931→+112; 默认分支落 CPersistent 基 sub_1424BEC40。
> **claim/uses 双计账** (断言串 `_ClaimsActive` 定名): +12 = 在用认领, +8 = 已兑现。**兑现** 0x1413CF730 (`--+12; ++ +8`, :95 断言) ← 调用者 sub_140EE3680 (研究完成链): 遍历 **tech+464** 待兑现 id 数组 (count@+476) 按 **lub+48 id** 在 ts+232 容器线性匹配 → 兑现 → memmove 摘除元素; **释放** 0x1413CFB00 (`--+12`, :107 断言) ← 调用者 sub_140ED9A20 (研究停止清理器): 段① tech+464 逐 id 在 ts+232 按 lub+48 匹配释放; 段② 同 id 在 **ts+256** cost_reduction 容器按 **cr+80 id** 匹配 (pdx_scopedptr.h:124 `_pPtr` 断言护空) → sub_1413D0090; 段③ 尾部清零 tech+448 (ahead_reduction) / +456 (bonus) / +476 (uses 计数) — 三项均为**研究期瞬时值**, 停止研究即重置 (writer 0x140EE5180 键 13284/10931/13283 三证)。
> ⇒ **tech+464 元素 = 待兑现有限用途加成 id**, 与 ts+232 (lub, +48 键) **与** ts+256 (cr, +80 键) 两容器构成主键关系。

#### 4.7.4 CLimitedUseTechCostReduction (112B)

**CLimitedUseTechCostReduction** (112B; ctor 0X140ED2C90):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | fixed×1e-5 | cost_reduction (键 19537) | |
| +16 | vector\<CTechnologyTemplate*\> 24B | tech 适用列表 {cap@24, count@28, alloc@32} | 键 10335 |
| +40 | uint32 | uses (键 13285) | |
| +48 | MSVC SSO 32B (size@+64, cap@+72) | name | |
| +80 | uint32 | id (ctor 初值 **−1**) | |
| +88 | vector\<类别 def*\> 24B | **category 适用列表**  {cap@96, count@100, alloc@104} | 键 702 |

> reader = 0x1413CFE50 (vtable 0x1429750F0 [4]): 键 19537→+8 / 10335→+16 (同 lub 模板+64 有效门, 失败 → "No tech named %s at: %s" :38) / 13285→+40 / 27→+48 串 / 11→+80 / 702→+88; 默认分支落 sub_1424BEC40。
> **+88 category 容器增长码 (定案)**: count==cap 时 newcap = max(count+1, (int)(float)(cap×1.5)); 分配/释放经 alloc@+104 指向的分配器对象 vtable+8/+16; memcpy 旧数据 → dealloc 旧 data → 写回 data/cap/count。与 lub 的 702 分支 (直接调通用 push sub_1401205A0) **形态异构** — 两类 category 容器增长实现不同。

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
| +48 | uint32 | **名串大小写折叠 FNV-1a32 hash** (基 0x811C9DC5 × 16777619, A−Z+32; 命名 ctor sub_140ACAFE0 从规格化名键 +32 拷入; ctor −1 哨兵) | §4.7.17 查找键 / 自引用门 |
| +56 | uint32 | 1 基库序 | tech+352 行互证 |
| +60 | token | 名 token | 非数字 id |
| +64 | uint8 | 有效旗 | lub loader 按之过滤 |
| +72 | CAndTrigger 88B | **allow 触发器** (ReadMember case 11138 定名) | §4.7.15 ctor 三触发器形块之一; 块内 +8 = 子触发器向量 (= 模板 +80) — parent 继承把 parent 块地址压入此向量 = 链式 AND (§4.7.17) |
| +160 | CAndTrigger 88B | **allow_branch 触发器** (ReadMember case 14260 定名) | §4.7.15 ctor 三触发器形块之一; 块内 +8 = 子触发器向量 (= 模板 +168), parent 继承压入点 (§4.7.17) |
| +248 | CAndTrigger 88B | **unlock 触发器** (ReadMember case 12260 定名) | §4.7.15 ctor 三触发器形块之一; 块内 +8 = 子触发器向量 (= 模板 +256) |
| +336 | CSubUnitStatBonus 内嵌 56B | **科技直挂加成容器** {vtable@+336, subunit 克隆向量@+344, 装备加成对向量@+368} (ctor sub_1406419E0(a1+336); 336+56=392 与 +392 CModifier 紧随咬合) | subunit/装备原型·装备类别直挂块落点 = ReadMember 默认分支第一级 sub_1406431D0: subunit 库命中 (sub_140AC4FA0) → malloc 1656B 统计克隆 (sub_141018080) + 块内容解析进克隆统计 (sub_1424C0AA0) → 入 +344 向量; 装备原型/类别库命中 (sub_140AC4C70) → 16B 对 {CEquipmentArchetype*, 统计克隆} 入 +368 向量; 直挂块不进 CSpecificEquipmentBonus (无名字无 instant 概念, 恒生效) |
| +392 | CModifier 内嵌 | **modifier 容器** (科技块 modifier 块键 + modifier 直挂标量键共用 — 前者 ReadMember case 10597 串写入, 后者默认分支第二级经 vtable+32 槽 reader) | ctor 直写 CModifier vtable (§4.7.15) |
| +408 | u32 数组容器 data 槽 | = +392 内嵌 CModifier 的 +16 向量 data 槽 (§4.13:58 形状); 修正 id 清单 → 研究 tooltip 修正清单段 (sub_14055AB90, dg053); 解 §4.31:1279 未决「修正容器是否即 template+392」 | 新消费点 (dg053) |
| +584 | 48B 条列表 | 建筑 max_level 加成列表 | tech+56 源 |
| +608 | 40B 条列表 | 战术列表 (计数@+620) | tech+80 源 |
| +632 | 24B 容器 (40B 条) | 生产解锁列表 A — **40B 名键条目表** {SSO 串@+0, FNV hash@+32} (本表以名键查库 db+216 装备解锁反向索引, §4.7.17; 元素 +1365 = 已解锁旗门; **指针向量在 CTechnology 层 §4.7.1 +104, 非本表**) (计数@+644) | tech+104 源 |
| +656 | 24B 容器 (40B 条) | 生产解锁列表 B — **40B 名键条目表** (同 +632 形; prod 双表 sub_140E5E220 注册) (计数@+668) | tech+128 源; 指针向量在 §4.7.1 +128 |
| +680 | 24B 条列表 {目标指针@0, 触发器@8} (计数@+692) | **子单位解锁 (带触发器门)** — 逐条触发器求值 (对象 vtable+24 槽) 为真 ∨ … 且目标+16 有效 | tech+152 源 (ctor 0x140ED2DD0) |
| +704 | 40B 条列表 (计数@+716) | **科技 categories 类别表** — 40B 名键条目 {SSO 串@+0, hash@+32}, 经库 db+120 FindByName (sub_140AC7EE0) 解析到类别 def (sub_140ACBD90; def+48 有效门; 反向索引 = def+56 模板向量, §4.7.17; 无效报 "Technology \"X\" has invalid category \"Y\"" technology.cpp:199) | **tech+248 源** (tech+248 = categories 类别指针表, 非 path 引用) |
| +752 | 152B 条列表 {名串@+8, research_cost_coeff@+48, ignore_for_layout@+144} (计数@+764) | **path 条目表** (前驱视角出边; ReadMember case 372, 条内 reader sub_140AD2BC0: leads_to_tech → 名 / research_cost_coeff → +48 / ignore_for_layout (token 14640) → +144) | UI 树连线 + 后继 research_cost 缩放 (coeff×本科技成本基准); GUI 研究栏消费 sub_140EE2F80/0x140EE2FE0 递归计数; 多块并列 = 多条出边; **装载尾重建期另写两域** (§4.7.17): +56 源科技名串 (hash 现算落 +88) + **+96 有序 56B per-folder 位置对表** {folder 名串@+0, hash@+32, 16B 位置对@+40} (二分维护 sub_140AC9350) |
| +776 | 8B 指针向量 | 前置列表 (元素 = 8B 指针 → 对象+56 = 40B 名键, 经 sub_140ACBF30 查库; 元素类待裁) (计数@+788) | tech+200 源; GUI 需求行消费 (研究 tooltip 步 B: 逐条查国家科技状态, 未满级 (level < max_level) 者收集名称, **任一前置满级则整段跳过**; 措辞由 +1033 选, dg053) |
| +800 | 48B 条列表 {名串, 所需等级@+40} | **dependencies 等级依赖表** (ReadMember case 373 循环 push; 等级门 — 前置科技须达该 level 才可研究, **全条 AND**; 资格判定 0x140ED7CE0/0x140ED8F00 **现读模板不缓存**) | 前置列表 +776 = **OR 语义**; 无独立 prerequisites 脚本键 (前置 = path 反向边 + 本表); tech+248 ≠ 本行源 (tech+248 实为 categories, 见 +704 行); GUI: 科技树 tooltip 需求列表消费 (逐条 level vs ts 条目 +372, 未满灰显, dg038) |
| +824 | hash 表 | **互斥科技表** (脚本键 XOR — ReadMember case 12043, 大小写不敏感同 token; 无 mutually_exclusive 脚本键, 负定案; 重复入表报 "Duplicate technology" 栈上串); GUI: tooltip 互斥清单消费 (+1033 学说旗选标题变体, dg038) | tech+224 源 |
| +848 | 24B 容器 (40B 条) | **sub_technologies** (ReadMember case 12044) 被门控后继列表 {d@848, cap@856, count@860, alloc@864} | tech+176 源; 元素 = 40B 名键 {SSO 串@+0, hash@+32}, 经 sub_140AC80E0 解析到后继模板 (§4.7.17 遍 C2) |
| +872 | u32 数组 | **特殊项目 id 表** {data@+872, count@+884} — AddResearchPoints sub_140ED5690 notify 时逐 id 调 sub_140E75C40 推进 cc+4008 program_status; GUI: tooltip breakthrough 键族 TECHNOLOGY_RESEARCH_BREAKTHROUGH_* (AMOUNT = dword_1433331B8 基值, dg038) | 定案 |
| +896 | 匿名结构 (NNB 形状) 向量 24B | **folder 关联条目列表** (键 11873 folder; 元素 56B = CFolderPosition, 下表) | 消费器 sub_140ED6CD0 doctrine 四军种 folder 名 memcmp 源 (§4.7 已载) |
| +920 | 24B 容器 (80B 条) | **root-key 有序向量** (科技树布局用) {data@+920, cap@+928, count@+932, alloc@+936} — 有序 vector<SRootKey 80B> (元素 {root 名串@+0, 名 hash@+32, folder 名串@+40, folder hash@+72}; 比较器 sub_140AC9870 = hash 优先 → stricmp 名 → 第二串) | §4.7.17 遍 B: root 判定 + BFS 下游传播写 |
| +976 | uint32 | **parent 名 FNV-1a32 折叠 hash** (ctor −1 哨兵; ReadMember case 135 经 sub_140459C70 现算落 +944+32) | §4.7.17 自引用门 + 子科技 parent 定案 |
| +984 | uint32 | start_year (token 11874; 「科技可用年」系语义释义) | >0 门 |
| +988 | uint32 | max_level | |
| +992 | uint32 | **research_cost** (ReadMember case 11876; 基准成本, 完成门 = BASE_TECH_COST × 本值 / 1e5) | 进度条分母: ×qword_143332BA0/1e5 ∨ 空槽 qword_143332A38 |
| +1033 | uint8 | **三语义同字节**: 科技共享加成豁免 (sub_140ED6C10 首门, 命中即返 0) + AI 落后年份加权豁免 (0x140ED5B50) + **情报可见性门豁免** (科技树件状态计算 sub_141433870, 命中走自定门 sub_141434600 而非阈值比较); ReadMember token 13817 (原版语料未出现, 键名待裁); **第四消费点 = 学说标题变体** (tooltip RESEARCH_DOCTRINE_EXCLUSIVE_INFO_TITLE 选题 + bonus 学说列表 sub_140ED65D0 门, dg038); **第五消费点 = 需求行措辞变体** (研究 tooltip 步 A/B: 1 → RESEARCH_DOCTRINE_REQUIREMENTS_SINGLE「Requires Doctrine」/ 0 → RESEARCH_REQUIREMENTS_SINGLE「Requires Technology」, dg053) | 三语义定案, 键名待裁 |
| +1034 | bool | **force_use_small_tech_layout** (reader case 19623) | 科技图标门第二键 ∨ tech+116==0; 邻 +1036 = **show_equipment_icon** (reader case 13950) |
| +1035 | uint8 | **hidden 旗** (ReadMember case 11404) | 消费者 0x2060254 所属 GUI/AI 函数读同字节 (资格检查旁路) |
| +1048 | 值块 (CMeanTimeToHappen 形 {factor@+24, 修饰符容器@+32}) | **脚本 AI 权重块** — 研究 tooltip AI 调试段: sub_1405520E0 求值 (§4.22:999) × sub_140ED5B50 终权重, byte_14332F63D ai_view 门 (dg053) | 新字段 (dg053) |
| +1104 | CAIResearchNeed 32B | **research 需求聚合** (need 条目 16B {token u32, need i64}; 向量 data@+1112; ctor 内联 sub_1413C4F10) | §4.34.6 |
| +1136 | 匿名结构 (NNB 形状) | **on_research_complete_limit** 触发器 (ctor sub_140549F40) | reader case 13738 limit 分支 (vtable+40) / case 19672 |
| +1224 | 匿名结构 (NNB 形状) | **on_research_complete** 效果 (ctor sub_14053CFD0) | reader case 13738 (vtable+24); **vtable+64 = tooltip 文本槽** (研究 tooltip 步 9 取效果描述, dg053) — 与 vtable+96 执行槽分工 (聚合器 0x140EE3E70) |
| +1244 | uint8 | **on_research_complete 效果存在门** (聚合器 0x140EE3E70: 门真且 gs+2617 真 → 模板+1136 触发器求值 (vtable+24 槽) 真 → 执行模板+1224 效果 (vtable+96 槽)) | —; ⚠ 研究 tooltip 按 DWORD 读 (bool 门无实质影响, 待裁, dg053) |
| +1312 | uint32 | XP 类型 (0=不可 XP 解锁) / **+1320 = 解锁 XP 量 / +1328 = 加速 XP 量** | IsBoostableByXP = +1312≠0 且 +1328>0; SetBoostedByXP 扣模板+1328 量 XP 置 +488 (0x140EE4ED0); UnlockByXP 门 = +1312≠0∧+1320>0 (0x140EE5010) SetBoostedByXP a2=0 = 免费置位分支 (+488=1 不扣 XP); 真扣原语 = sub_140EE4D40(cc, +1328 量, +1312 类型) 返 bool |
| +1320 | — | XP boost 配置 | 研究 tooltip 首门读 *(int64*)(+1320) > 0 = 跨 +1320/+1328 两 u32 (待裁: 若为 IDA 把两邻接 u32 比较合并为 qword, 则 XP 解锁支吞 XP 加速支, 需汇编复核, dg053) |
| +1328 | — | XP boost 配置 | >0 门 |
| +1344 | uint8 | **is_special_project_tech** (ReadMember case 10159) — special_project 旗 (科技树件 GFX 后缀门: 非 0 → 后缀追加 "_special_project") | 新锚 |

CFolderPosition (folder 关联条目; 56B; vtable 0x1429440B8; def 侧件 — writer 槽 [2] =
CFG 空桩不落档; reader 0x140AD2A80 键 27 name / 76 position):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | MSVC 串 32B | folder 名串 (reader case 27 写入) |
| +40 | uint32 | 名串小写折叠 FNV-1a hash 缓存 (基值 0x811C9DC5 × 16777619, A-Z+32 折叠; 默认 −1; 写名后现算) |
| +48 | position 载荷 8B | 键 76 position 值对象 (内部类型待裁, 基链暗示 CVector\<int,1\> 族) |

> 消费链: sub_140AD01A0 遍历 template+896 条目, 对 folder def 容器逐项 +40 hash
> 相等 (预筛) && 名串 stricmp 相等配对, 未中返回 null_object 单例; 上游
> sub_140ED6CD0 对返回 def 名串 memcmp 四军种 folder 名 → 写 CTechnologyStatus+320。

**解锁列表元素** (tech+104 列表首元):

| 元素+N | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +1000 | — | 首解锁旗 | → 首解锁装备图 (模板图为先, §4.7.1 +104 行) |

建筑 def (另族): +736 = 库内 0 基索引 (ts+88 快查表下标); +492=u8 /
+696/+700 = max_level 族 (0X1414BA740 消费)。

#### 4.7.7a CTechnologyTemplate::ReadMember 全键表 (sub_140AD2D30; 定案)

锚: technologytemplate.cpp:425 (on_research_complete 内嵌 limit 弃用警告 → 落 +1136) /
:450 (xp_research_cost (token 15372) 弃用警告 "deprecated, use xp_boost_cost")。
模板 = 只读 def 不入存档 (folder/path/categories/加成块全部启动期从 common/technologies 重读)。

| 键 | → 偏移 | 落到 |
|---|---|---|
| parent (135) | +944 | 串表 (经 sub_140459C70 写串并现算 FNV-1a32 落 +976) |
| path (372) | +752 | 152B 条 (§4.7.7 +752 行) |
| dependencies (373) | +800 | 48B 条 (§4.7.7 +800 行) |
| special_project_specialization (10122) | +872 | id 表 |
| is_special_project_tech (10159) | +1344 | bool |
| modifier (10597) | +392 | CModifier 串写入 |
| desc (10644) | +1000 | 串 |
| ai_will_do (10819) | +1048 | 触发器 |
| allow (11138) | +72 | 触发器 |
| categories (11352) | +704 | 40B 条 (stricmp "Duplicate category" 去重) +728 hash |
| hidden (11404) | +1035 | bool |
| folder (11873) | +896 | CFolderPosition 56B push |
| start_year (11874) | +984 | u32 |
| max_level (11875) | +988 | u32 |
| research_cost (11876) | +992 | u32 |
| xor (12043; 脚本写 XOR, 大小写不敏感同 token) | +824 | hash ("Duplicate technology" 栈上串去重) |
| sub_technologies (12044) | +848 | 40B 条 (带触发器) |
| enable_equipments (12155) | +632 | 原型指针向量 ("Duplicate equipment" 去重) |
| unlock (12260) | +248 | 触发器 |
| enable_building (13053) | +584 | 48B 条 {building, +40=max_level} |
| enable_tactic (13143) | +608 | 40B 条 |
| ai_research_weights (13201) | +1104 | 聚合表 (§4.34.6) |
| enable_subunits (13258) | +680 | 条目 {CSubUnitDefinition*, 触发器} (DLC 门) |
| on_research_complete (13738) | +1224 | 效果 (内嵌 limit → +1136 警告) |
| (键名待裁) (13817) | +1033 | 三语义豁免旗 |
| show_equipment_icon (13950) | +1036 | bool |
| allow_branch (14260) | +160 | 触发器 |
| show_effect_as_desc (14896) | +1032 | bool |
| enable_equipment_modules (15212) | +656 | hash ("Duplicate equipment module" 去重) |
| (键名待裁) (15371) | +1336 | fixed; **键名语义可裁 = XP boost 量** (tooltip 三消费点互证: RESEARCH_WITH_XP_TEXT_TOOLTIP VALUE / 已 boost 判定 sub_140EE10C0 / 汇总加成项, dg038) |
| xp_research_type (15373) | +1312 | 枚举 |
| doctrine_name (19333) | +1352 | 串 |
| sub_tech_index (19408) | +1040 | int |
| force_use_small_tech_layout (19623) | +1034 | bool |
| on_research_complete_limit (19672) | +1136 | 触发器 |
| xp_unlock_cost (19858) | +1320 | u32 |
| xp_boost_cost (19859) | +1328 | u32 |
| 默认 (直挂块键 = subunit/装备原型·装备类别名) | +336 | CSubUnitStatBonus (第一级 sub_1406431D0, 两级库 miss → 走下行) |
| 默认 (modifier 直挂标量键, 62 种) | +392 | CModifier (第二级, vtable+32 槽 reader) |

> 静态 equipment_bonus 键 (token 12647) 在 ReadMember 无 case (负定案) — 科技块直写该键被默认分支吞掉; 具名装备加成唯一合法通道 = on_research_complete 内 add_equipment_bonus 效果 (CSpecificEquipmentBonus → ts+184)。

#### 4.7.8 CSelectTechTreeIconOrigin (科技树图标起源效果)

纯效果类: Parse → effect+88 tag token; Execute → ts = `*(cc+3936)`, 写
ts+312 override_icons_tag (与 §4.7 主表 +312 行双锚互证), 刷科技树 GUI。

#### 4.7.9 特殊项目 (special project) 状态机与 def 侧

**CProjectStateMachine** (616B; vtable 0x142A300B8; COL 0x142D5EBD0; CHD nbases=2: self + CPersistent;
ctor 0x141A35060) = **内联三元状态容器** (非常规派生族):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | 匿名结构 (union 指针) | **current state 指针** (指向 +24 / +232 / +360 / +488 之一) | reader 0x141A37880 `*(a1+8) = a1+24` / `= v10` |
| +16 | uint8 | **tag 三值**: 1 = PROTOTYPE 活动态 (ctor 默认, +8 指向 +24) / 0 = Simple 态 / −1 = 惰性哨兵 (writer 守卫) | 同上 (§4.7.9a 同判) |
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
| 0 | `*(a1+8) = a1+24`, tag 置 1 (回 PROTOTYPE 态) |
| 1 | a1+232 (RESEARCH_COMPLETED / Simple) |
| 2 | a1+360 (STOPPING_STATE / Simple) |
| 3 | a1+488 (STOPPED_STATE / Simple) |
| default | 断言 `"bad state for project state machine"` (project_state.cpp:629), 回落 = tag 1 (PROTOTYPE); 另有姊妹函 **sub_141A36EE0** (同文件 :607 同断言, 闩 byte_14338B5F0) = 槽号 → 槽对象 (映射同 +24/+232/+360/+488), 返 **u32@slot+80** (字段语义未决) |

**writer 0x141A37CD0 发射键表** (只三键):

| 键 | 值 | 说明 |
|---|---|---|
| 14059 current_state | `*(u32*)(*(u64*)(this+8) + 120)` | = 当前 state 对象的 +120 (即 0/1/2/3) — 与「+120 = 状态枚举 id」互为直证 |
| 10018 prototype_state | sub_1424C2E20(stream, this+24) | slot 0 整块 |
| 10045 stopping_state | sub_1424C2E20(stream, this+360) | slot 2 整块 |

> ⇒ **只有 +24 (prototype) 与 +360 (stopping) 两块内容被序列化**; +232 / +488 两槽仅靠
> `current_state` 索引在 reader 里指回去, 其 phase_progress 不落盘 (默认 0) — 语义自洽:
> RESEARCH_COMPLETED / STOPPED_STATE 是终态标记, 无进行中进度 (高置信)。
> writer 开头 `if (*(char*)(this+16) == -1) sub_140722EC0(&v6, this+8)` = +8/+16 联合体的
> 惰性初始化守卫 (与 reader 的 +16 门呼应)。
> 迁移为枢纽图 (定案, §4.7.9a): PROTOTYPE 可直达各态, reader case 0 = 回 PROTOTYPE 的进入点。
> 断言串给出源文件 = `special_projects/projects/project_state.cpp`。

**CBaseProjectState** (128B; vtable 0x142A2FFB0; COL 0x142D5E9F0; CHD nbases=2: self + CPersistent):

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
| +72 | int64 | **phase_progress** (键 10251) — 本状态内进度 | writer/reader |
| +80 | uint32 | phase_progress 尾槽 (与 +72 同写同拷) — 完成门直接证据: 相位满判定 = progress ≥ 100000×(int)(+80) | writer 0x141A37CB0 |
| +88 | MSVC 串 32B | 状态名 {buf@+88, size@+104, cap@+112=15} | ctor |
| +120 | uint32 | **状态枚举 id** (0/1/2/3, 与 SM switch 的 current_state 同域) | ctor 三处写 1/2/3 |

**CPrototypeProjectState vs CSimpleProjectState** (两者 CHD 均 nbases=3, sizeof 差 80 = 208 vs 128):

| 项 | CPrototypeProjectState (vtable 0x142A30060) | CSimpleProjectState (vtable 0x142A30008) |
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

**CNarrative** (72B; vtable 0x14271B0B8; 基 CPersistent; reader 0x140A91F50):

| 偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +8 | MSVC 串 32B | 27 name | 叙事名 |
| +40 | MSVC 串 32B | 10644 desc | 叙事描述文本 |

> reader 只有两键 ⇒ CNarrative = **项目叙事文本对 (name/desc)**; writer 空桩 ⇒ 不入存档。

**CComplexity** (vtable 0x1427C5020; 基 CPersistentWithToken; reader 0x141465300) —
它是 **CProjectTemplate 的成员子对象** (不是基类): ctor 链 = `sub_140A932C0(template)` →
`*(template) = CProjectTemplate::vftable` → `sub_140A93320(template+24)` 构造 CComplexity 成员;
CPersistent 基子对象 (vptr 落点) = **template+32**。

> **基准约定**: 下表 `B` = CComplexity 的 CPersistent 基子对象基址 = template+32
> (reader 的 this 即 B); token 在 **B−8**。

| 偏移 (相对 B) | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| −8 | u32 | — | **token = 19479 `undefined`** |
| +0 | vtable | — | CComplexity vptr (= template+32) |
| +8 | uint32 | 名字 token (默认 357 none; 进诊断文案) | 定案 |
| +16 | uint32 | **675 min = 复杂度下限** (ctor 默认 = dword_1433321F4; 键分派 sub_1414654F0 + 校验器三证) | 定案 |
| +20 | uint32 | **676 max = 复杂度上限** (默认同上; 原「+12」订正) | 定案 |
| +24 | NProject::SOutput vtable | SOutput 子对象 | 定案 |
| +24 | NProject::SOutput vtable | — | SOutput 子对象 |
| +32 | CEffect (88B) 内联 | effect/条件体 (ctor sub_14053CFD0) | H 批升格 |
| +120 | 匿名结构 (88B) | — | 同上 |
| +208 | 匿名结构 (88B) | — | 同上 |
| +296 | 匿名结构 | — | (ctor sub_1406419E0) |
| +352 | 指针 | — | 空 |
| +360 | 指针 | — | 空 |
| +368 | 匿名结构 (24B 形状) 向量 ×4 | — | 四个 24B 容器步长 24 @ B+368/392/416/440 (ctor 四置分配器哨兵) |
| +440 | 匿名结构 | — | — |
| +456 | uint8 | — | 门 |
| +464 | CNarrative vtable | — | **CNarrative 子对象起点** (= CProjectTemplate+496) |
| +472 | MSVC 串 32B | — | CNarrative name |
| +504 | MSVC 串 32B | — | CNarrative desc |
| +536 | MSVC 串 32B | — | CComplexity 自有串 (三串组) |
| +568 | MSVC 串 32B | — | CComplexity 自有串 (三串组) |
| +600 | MSVC 串 32B | — | CComplexity 自有串 (三串组) |
| +632 | 匿名结构 | — | (ctor sub_14011DF40) |
| +656 | 匿名结构 (88B) | — | (ctor sub_140549F40) |
| +744 | 匿名结构 (88B) | — | (ctor sub_140549F40) |
| +840..+1064 | 匿名结构 (NNB 形状) | — | locale/哈希桶等 |
| +1080 | — | — | 尾 (推定 sizeof ≈ 1088) |

> **sizeof = 1088 定案** (与 CProjectTemplate+1112 相邻成员精确咬合); 校验器 slot[7] 有第三诊断
> "Max is smaller than min" (cpp:53); [3] = 自定 Load wrapper → serfam 失明根因确认。
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
| 15606 project_tags | template+1072 | vector<u32> {data@1072, cap@1080, count@1084} (元素解析 sub_140A937A0 push); template+776 属键 12264 available (CTrigger), 另 12263 allowed → +1112 |
| 16388 unique_prototype_rewards | template+880 | `CInlinableGameItem<CPrototypeReward>` reader (SUniformReader<CPrototypeRewardDatabase,6>) |
| 17462 resource_cost | template+968 | — |
| 17468 generic_prototype_rewards | template+880 | 同上 (SUniformReader 模板参数 <…,1>, 与 16388 的 <CPrototypeRewardDatabase,6> 参数差) |
| 11562 visible | template+688 | CTrigger 子对象 |

> CProjectTemplate sizeof ≥ 1144 (ctor 尾部 `sub_140549F40(a1+1112)`), writer 空桩;
> vtable 0x142940798, COL 0x142CC3988, 基 CPersistentWithToken ← CPersistent, ctor 0x140A932C0。

> **本域 GUI 类布局**: 见 4.30.23 / 4.31.21 / 4.31.35。

研究点结算链 (定案): CCountry::DailyUpdate → sub_140ED9D00 "tech.daily" 逐研究槽 (ts+160 容器 count@172): ① 槽日结算 sub_140ED9B70 — 空槽攒分 `slot+32 = min(slot+32 + 100000, qword_143332A38)` (+1.0/日, 顶 = 空槽成本 define); 有 tech 走 folder 有效门 + 有限用途加成过期清理 (folder+120 计数 vs dword_143333168 窗口, tech+464 uses 数组紧凑化); ② 完成门 = 成本 (BASE_TECH_COST × 模板+992 / 1e5) ≤ tech+408 → sub_140EE1270 CompleteResearch (互斥门 tech+224; SetLevel → 聚合 sub_140EE3E70 五路: tech+104 装备原型解锁 sub_140E5E490 / tech+128 装备 B sub_140E5E220 / tech+152 子单位 sub_140D0E200(cc+3952) / tech+56 建筑 max_level 缓存 ts+88 / tech+80 战术 ts+112 + 完成效果块 + doctrine tech 注册 sub_140ED6CD0 四 folder 名比对 land/naval/air/special_forces → ts+320 等级缓存 / ts+328 槽); ③ slot 日推进 sub_140EE3680 — 日产点 sub_140ED69A0 (聚合速度 sub_140ED6E30 含 tech+320 特殊项目表求和 + ahead 罚 sub_140ACDB60 读 tech+448) → 本日投入 = min(100000×剩余/日产, slot+32) → sub_140ED5690 AddResearchPoints (tech+408 += 点数; 模板+872 特殊项目推进)。

> **GUI 视图消费面旁注 (df361)**: 特殊项目视图条目刷新器 sub_141EEBD10 (0x141EE 域, 源文件待裁 — df201 旧标 effects/effectimplementation.cpp 与本体不符, 归属待裁): 条目对象 +32 CRef 上下国 / +40 项目实例 (其 +40 = CProjectStateMachine\* 直通 §4.7.9 布局) / +1480 进度条 / +1488 可用性图标 (GFX_unavailable_project) / +1496..+1520 禁用组三件套 / +1528 条目容器 (+416/+428); 研究天数 = sub_140FE2CB0 → 状态机天数, ≥ **0x53E2D61FD320 无穷哨兵** → INFINITY 文案 (哨兵 GUI 消费面新增); loc = PROGRAM_VIEW_RESEARCH_TIME / DAYS。本体细表留 findings (df361)。

#### 4.7.9a 特殊项目状态机迁移与推进链

**tag 语义定案 (旧判读废)**: SM+16 三值 — **1 = PROTOTYPE 活动态 / 0 = Simple 态
/ −1 = 惰性哨兵**; reader case 0 显式写 tag=1 (旧「current_state=0=无状态」
判读错误)。**slot 0 进入点三处**: SM ctor 0x141A35060 尾 (每个 CProject 生而
PROTOTYPE) / 读档 case 0 / **Restart sub_141A37C50** (任意态 → PROTOTYPE 并清
SM+432 stopping 进度; 由 complete_effect 对已完成项目重开时调用)。

**迁移图定案 (旧「单向链 0→1→2→3」推定废)**: 实际是**枢纽图** — PROTOTYPE 可直达
RESEARCH_COMPLETED / STOPPING / STOPPED 三态; STOPPING→STOPPED 是唯一必经中间
步; RESEARCH_COMPLETED→PROTOTYPE (restart) 回边存在; RESEARCH_COMPLETED 是
停止类迁移唯一禁区 (守卫 `tag==0 && current==+232` 时 no-op)。迁移函数
(SM 自由函数非虚槽): **Complete = sub_141A35940 / BeginStopping =
sub_141A37C70 / Stop = sub_141A372F0 (a2 衰减旗 → SM+160 按 qword_143332E18
比例衰减) / Restart = sub_141A37C50**; 谓词: IsResearchCompleted sub_141A37260
/ IsStopping sub_141A372C0 / IsStopped sub_141A37290 (tag==1 即 IsPrototype)。
读档 sub_141A37880: state>3 断言 "bad state for project state machine"
(project_state.cpp:629)。

**SM 挂载定案**: CProjectStateMachine = **CProject+40 的 616B 堆对象** (非内联;
CProject = 448B, ctor sub_140FE0070 malloc 0x268; 池内联数组步长 448)。

推进链 (定案): CCountry::DailyUpdate 在 queued_events 段前依次 — ①
sub_140E785D0 (CProgramStatus 日更: 设施日更 sub_141443DD0 / S+56 待删队列
清算 / 数活跃科学家 / S+104 逐 token 基础研究入账 sub_140E75C40
(dword_1433335B8×n) / scientist+308 倒计时); ② **sub_141482020 CProjectPool
日更** (资源重聚 sub_1414830F0 → 逐项目 **sub_140FE2A80** (IsStopped 分支另调 sub_140FE4700 已停项目日巡): 门 = 设施 CRef
已设 ∧ 未完成 ∧ (设施引用失效 ∨ 停态) → sub_141A37390 推进; 推进后完成
→ sub_140FE3F00 结算 (+445 只结算一次门 / RNG 种子 project.cpp:416/417/418 三粒 / 迭代奖励
sub_140FE0D20 / SProjectHistory 88B 追加 / 事件 "special_project_researched");
**设施健康且态=PROTOTYPE → BeginStopping** (设施未派科学家则项目转入停止)。
日推进 sub_141A37390: STOPPING +100000/日; 其余态增量 = 设施/科学家速度
sub_141BE7200; **`sp_fast` (sub_1411AA750) 翻转 byte_14332F680** (相位门放宽: progress>0 即满) /
**`sp_instant` (sub_1411AB1E0) 翻转 byte_14332F681** (状态直接迁移; 非停态→+232 tag=0,
STOPPING→+488) — ⚠ 引擎源码命令名↔行为旗绑定本身互换: 敲 `sp_fast` 得「任意正进度
即过门」、敲 `sp_instant` 得「状态一步迁移」(命令注册区 + 两函数体直证; 同族 =
`sp_available` / `sp_research_all` / `sp_unlock_all` / `sp_breakthrough`)。

**原型态推进 sub_141A37490 (定案)**: 相位满 (phase_progress ≥ 100000×相位长)
→ **iterations(+140)++** → 从 [_ComplexityMin(+128), _ComplexityMax(+132))
掷随机复杂度 → project_progress(+136) += v9 钳 [0,100]; <100: 经 +144/+200
回调发迭代奖励事件; ≥100: 经 +64 回调发项目完成; 完成后遍历 CProgram+176
支援科学家容器对各国同 token 项目 sub_140FE0A30 加进度。+128/+132 由模板经
sub_141A37C20 初始化 (template+48/+52; 另写 SM+104 = slot0+80 相位分母 ← template+16、SM+440 = slot2+80 ← dword_1433323B0; 断言 "_ComplexityMax != 0 && \"Complexity
in Project is 0\"" project_state.cpp:240)。

**研究点银行定案**: S+80 = CBreakthroughProgress (24B 无 vtable), 其 +8 =
std::map 头 → **S+88 map<u32,u32> 是其成员** (键 = 专精 id, 值 = 点数;
入账 sub_140E75C40); 来源 = AddResearchPoints notify (科技+872 表) / 基础研究
/ 阵营支援科学家 sub_140E77EB0 / effect。effect 族: complete_project Execute
= sub_140493810 (未完成强制完成 / 已完成换设施 restart) / add_project_progress
= sub_140493270 → sub_140FE0A30 / add_breakthrough_progress = sub_140493160。
池重建 sub_141483450 → sub_141481780 (模板+1112 allowed (键 12263) trigger 求值; 新建 gs+1904 id
发生器, 通知 type 86)。


#### 4.7.10 CTechnologySharingGroup (科技共享组实例, 80B = 0x50; vtable 0x142721740 19 槽; writer/reader = 槽[2]/[4], 存档键 14100 "tech_sharing_group" — 与库内容文件键 14094 "technology_sharing_group" 为两个 token)

**宿主形态**: gs+928 = **vector\<组指针\>** {data@928, cap@936, count@940, alloc@944} 持全部实例
(非单指针; 组实例惰性创建 — 首个 add_to_tech_sharing_group 效果才 malloc(0x50) 推入);
国家侧成员表 = ts+280 (CModifyTechnologySharingBonusEffect 0X14031FB10 → sub_140ED5110 按组 id 查找)。

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vtable | 0x142721740 (19 槽) | [2]/[4] 序列化 (键 11 = id / 14116 = bonuses / 11593 = countries) |
| +8 | uint32 | 组 id (= 模板名 token; 初始 357 none) | 定案 |
| +16 | fixed×1e-5 | 每国加成标量 (ctor 自模板+112 research_sharing_per_country_bonus 拷贝) | 定案 |
| +24 | uint32 向量 24B | 成员 tag 表 {d@24, cap@32, count@36, alloc@40} | 11593 |
| +48 | i64 向量 24B | **与成员表平行同下标的加成累加器数组** {d@48, cap@56, count@60, alloc@64} | 14116 |
| +72 | 模板回指 160B | CTechnologySharingGroupTemplate (查库失败回退库+80 默认模板); +48[i] 与 +24[i] 平行 push/swap-remove | 定案 |

vtable 19 槽: [2]/[4] 序列化 / [9] 每日巡检 (唯一 daily 职责, §4.2 步 9) / [10]/[11] 加/踢成员
(+24 与 +48 双数组平行 push/swap-remove) / [12]..[17] 模板代理 (name/desc/picture/categories/
已研成计数/成员 tag 表; is_faction_sharing (模板+120) 分流槽[16]/[17] 阵营成员表 vs 自有成员表) /
[18] 固定串。

**加成传播定案** (补「不在 daily」空白): join/leave 即时双向维护 (组 ↔ ts+280), 数值无缓存槽,
在研究成本求值时**懒计算** (sub_140ED6E30 → sub_140ED6C10 → sub_140D821E0; GUI tooltip 同链 — **实体 = 科技树条目 tooltip 巨函 sub_141BD1840**, ts+280 成员表迭代直证, dg038)。
单组公式: `(1e5 + 修正207 MODIFIER_RESEARCH_SHARING_PER_COUNTRY_BONUS_FACTOR) × N ×
(own_48[i] + 组+16) / 1e5`; **N = 组内已研成 (状态 == 4) 该科技的成员数**; 双门 = 组 categories ∩
科技 categories 非空 + 科技模板+1033 字节 (**共享加成豁免门**, 命中即不计入; 双语义同字节见模板表); clamp [0, MAX_TECH_SHARING_BONUS]。

效果/触发器五件套: add (14092) → sub_1401CA430 全链 / remove → sub_1401EB690 / modify
(effect+88/+96 → `+48[idx] += 值`, sub_140D83BC0); vtable 0x1427521D0/0x1427522E0/0x1427524F0
([13] = Execute)。模板 160B 全键表: id/name/desc/picture/research_sharing_per_country_bonus/
is_faction_sharing/categories/available。阵营级派生类 CTechnologySharingFaction 多 `upgrade=` 键
(reader 待裁); 科技模板+1033 字节 = 共享豁免 + AI 落后年份豁免双语义 (键名待裁)。

#### 4.7.11 特设项目速度因子合成 (project_modifier.cpp; 2 函闭环 — 全因子公式定案)

> 簇名勘误: TSV 簇名 "oject_modifier.cpp" 系截断 — 两函体内锚均 = special_projects\projects\project_modifier.cpp, 属特设项目域 (与 §4.7.9a 推进链同域), 非环境对象域。

簇清册 (体内 cpp 锚 2/2; sub_141BE7200 与 §4.7.9a 日推进 sub_141A37390/原型态推进 sub_141A37490 两函号互证全合):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141BE7200 | 713 | :161 ("…without a program", 闩 byte_14338C407) / :174 ("pBuilding && Program without building", byte_14338C408), B52 门 | 项目速度因子合成 (定点 1e5 乘积) |
| sub_141BE7F90 | 123 | :95 ("pScientist->GetScientistRole() && …", byte_14338C406, B52 门) | 科学家速度因子聚合 (主 + 48B/条额外科学家) |

**全因子公式 (定案)**: speed = clamp_health × resource × Π_modifiers × scientist × supply (除 1e5 经魔数乘法; 乘积尾钳 ≥ 0; 程序槽空 → 断言 :161 返 100000 中性):

| 因子 | 来源 | define/tooltip |
|---|---|---|
| clamp_health | 程序→建筑 (+72 引用, +700 分支二路) → 建筑健康值; 伪码两支均归 100000 (待汇编裁) | — |
| supply | 程序+248 原始利用率 → 钳位 [qword_143332638, 100000] | 下限 = **MINIMUM_PROJECT_SPEED_FACTOR_FROM_SUPPLY**; 非 100% → tooltip "SPECIAL_PROJECT_SUPPLY_UTILIZATION" |
| resource | qword_143332BF0 + def+304×(100000−qword_143332BF0)/100000 | qword_143332BF0 = **MINIMUM_PROJECT_SPEED_FACTOR_FROM_RESOURCE_SHORTAGE**; tooltip "SPECIAL_PROJECT_ACQUIRED_RESOURCE_FACTOR" |
| Π_modifiers | 项目 def+32 子对象 {id 清单 data@+968, count@+980} 逐 id 三源连乘: ① cc+1448 国家修正容器; ② tag 键 208B 步距开放寻址表 (宿主 *(X+2256), X = *(上下文+192); miss 落默认槽/+1352 兜底) 命中项 +16 容器; ③ 科学家因子 | tooltip "SPECIAL_PROJECT_RESEARCH_TIME_TOOLTIP_MODIFIER" |
| scientist | sub_141BE7F90: 主科学家 (程序 +88/+92 CRef) × 逐额外科学家 (+176 数组 48B/条, 首 8B = CRef); 每人经岗位对象 (char+192, 无岗位断言 :95) sub_14140B030 取岗位修正值; 岗位 +308 > 0 → 初值 = **SCIENTIST_INJURED_FACTOR** (qword_1433336B0); 修正 id = def+32 子对象首字段 (主修正 id) | tooltip "…SCIENTIST_SKILL(_ADDITIONAL)" |

尾节 = "SPECIAL_PROJECT_FACILITY_SPEED_FACTOR" (FACTOR = 总积)。调用者 7 处: §4.7.9a 两推进函 + project_state 三件 (prototype 相位 tooltip) + 效果消费两件。同族辅助: sub_141BE6B20 (容器内单修正值读 + tooltip 行) / sub_141BE8220 (科学家群连乘) / sub_140FE32B0 (主修正 id 读) / sub_14221F310 (CRef 三段 id 空间解析: id<100 直槽 qword_143451DC0[id] / 100 表 qword_143451DB8 / >4744 表 qword_143451DB0)。

未决: 建筑健康因子 clamp 形态 / tag 键 208B 修正表宿主身份 / desc 键第二段实参 (§4.31.101)。

#### 4.7.12 特殊项目产出视图 unit bonus 区块 (project_output_view.cpp; 1 函 — 簇名勘误记录: t_output_view.cpp 系 project_output_view.cpp 子串伪簇)

sub_142019730 (668 行; 锚 project_output_view.cpp :385 断言 "pDef" + :402 断言 "Pair.first && Pair.second" + technologyinfo_statlist.h:61 断言 "Units.GetSize() > 0", 全 B52): **unit_stat_bonus_rewards 区块重建器** (特殊项目产出视图的 unit buff 奖励区; (view, y 基线) 入, 返累计后 y)。上游 = sub_14201A360 同 CU 大重建。

view 布局: +96 容器窗 (查 unit_stat_bonus_rewards 子窗; 空区块隐 header 早退) / +240 数据模型 {+272 奖励数组 32B/条 {奖励 def, units data, dword, units 计数, 分配 vtable}, +292 奖励数, +304 对组数组 16B/条, +316 对组数} / +336 statlist 行缓存容器。

重建循环: 头 = 子窗 vtable 槽 6 设位置 + header 文本 SPECIAL_PROJECT_REWARD_UNIT_BONUS; 每奖励/对组 (空 → :385/:402 断言): 建 statlist 行 (malloc 5952 → sub_141EFC5E0, 模板名 technology_unit_statlist_item_upgrade); **统计键名 = "unit_" + token_name(token)** (串前插 "unit_" 5 字节常量; 计数 ≤0 → :61 断言); 行入缓存 → 104B 填充块 {+16 def, +32 哨兵 qword_14333D528, units 向量} → sub_141BDDD10 灌行 → 显示 → y += 行高 + 6 行距。尾: 显示 header + 逐条清 units 引用释放。

未决: 该簇他函 (project_output_view.cpp 全簇除本函外未在本批) / 对组数组业务语义。

#### 4.7.12a 特设项目 explainable checks 族 (project_explainable_checks.cpp; 1 函 + 3 同族调用方 — 书未收域)

explainable check = UI 失败原因解释器 (签名 `(check, explainer, 未用) → bool`; explainer 非空才产解释)。**科学家技能检查 = 0x141BF3700** (定案):

- `*check` = 检查数据对象, 其 **+88 = optional\<科学家 idpair\>** (两 dword 皆 0 → 返 0); `check+8` = 技能/修正 id (经 sub_140FE32B0 读 = §4.7 主修正 id 读)。
- 科学家 = sub_14221F310(idpair); `pScientist = *(科学家+192)` (**CCharacter+192 = CScientist\***, §4.4 科学家角色槽, 块键 16389) — null → assert `"pScientist && \"Scientist does not have scientist role\""` (:66)。
- 计数 = sub_141460080(pScientist+264, 技能 id) (§4.4 CScientist skills 容器 +264 取级)。
- 失败 && explainer 非空 → 本地化 "SCIENTIST_LACKING_SKILL" + 技能名 → 写 explainer。

同族互证: sub_141BF3530 = 「已指派科学家」检查 (loc PROGRAM_VIEW_REQUIRE_SCIENTIST); 调用方两路 = sub_141BF39D0 (逐科学家筛选循环) + sub_141BF3AD0 (特设项目「可开工」组合校验器, 串 SPECIAL_PROJECT_UNABLE_TO_START / SPECIAL_PROJECT_BREAKTHROUGH_COST_ENOUGH / SPECIAL_PROJECT_BREAKTHROUGH_COST_NOT_ENOUGH / SPECIALIZATION / AMOUNT)。未决: check 数据对象类名 / explainer 类名。

#### 4.7.13 CTechnologySharingGroupTemplate 类目表排序 (technology_sharing_template.cpp; 7 函 = 同一 40B 元素上的 std::sort 算法族实例化 — 非业务新机制)

#### 4.7.14 country_culture 本地化键校验器 (cultural_formatter.cpp; 1 函 = sub_140531F10, 高置信)

sub_140531F10 (localization/formatter/ 族第三员, 前两员 tech_formatter sub_140533050 / tech_effect 校验 sub_140533250 同 §4.7 已收): a1 token 经 sub_1424BC260 取名视图 (24B std::string → 16B strview {ptr, len}) → 谓词 sub_142244840 (本地化键存在性) 假 → CLogStream 4096 :26「Invalid localize key for country_culture」(常量串无格式参); 返谓词值。本件为**校验器形** (无 sret 显示名输出, 返 bool), 非格式化器。

簇本质: 模板类目表的排序机器。元素 40B = {MSVC SSO 串 (类目名) @+0..+31, uint32 类目 token @+32, pad @+36}; 比较序 = token 升序, 同 token 按 stricmp(名)。

模板 160B 类目区读点 (§4.26 库条目 technology_sharing_group +80 = 默认模板指针; §4.7.10 实例 +72 模板回指不变):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +16 | SSO 串 | 模板名 (cap @+40) |
| +128 | 指针 | 类目向量 data |
| +140 | uint32 | 类目向量 count |

7 函逐函算法定性:

| VA | 行数 | 身份 (MSVC 算法名) |
|---|---|---|
| 0x1413D0B70 | 789 | introsort 分区核 `_Sort_unchecked` 主体 (枢轴取中, 返回枢轴界 {first,last} 出参) |
| 0x1413D05C0 | 273 | make_heap 实例化 (`(末−首)×0x6666666666666667>>64>>4` = ÷40 元素计数; 自 count/2−1 逐位下滤) |
| 0x1413D01A0 | 268 | insertion sort 实例化 (小于首元整段右移, 否则逐位回退) |
| 0x1413D17B0 | 106 | `_Adjust_heap` (下滤 + 尾上滤委派) |
| 0x1413D19B0 | 87 | `_Push_heap` 上滤 (洞位回填 sub_1401599D0 move-assign) |
| 0x1413D1E40 | 48 | 比较器本体 (token 不等 → token 比较; 相等 → stricmp(名); 相等且同名 → 断言) |
| 0x1413D2080 | 34 | 排序入口 (模板方法 SortCategories) |

排序驱动链 (定案): 入口 0x1413D2080: 模板 +16 名 SSO → sub_142244840 本地化键存在校验失败 → technology_sharing_template.cpp:48 格式化日志 "There is no localization for the technology sharing group name: %s" (不中断) → 类目向量排序。introsort 参数 (驱动 0x1413D1D00, 簇外伴生): 区间 <1320 字节 (=32 元素, MSVC _ISORT_MAX) → 插入排序; 递归深度限制每层 ×3/4; 深度耗尽 → make_heap + sort_heap 堆回退 (0x1413D1B50 = sort_heap)。

"Duplicate category" 断言 (:55, 7 函中 6 函引用): 比较器内两元素 token 相等且 stricmp(名)==0 → 格式化器 sub_1424C8950 + 消息 "Duplicate category" (xmmword_142944240, PE .rdata 字节直证) = 严格弱序违例自检, 非 STL 通用断言。同排 .rdata 的 "Duplicate technology" (0x142944258) .rdata 副本无引用, 但**活串定案**: CTechnologyTemplate::ReadMember (sub_140AD2D30) 的 XOR 分支 (case 12043) 与 sub_technologies 分支 (case 12044) 各自栈上构造同名串 (长度 20) 报重复; "Duplicate technology category %s scripted at: %s" 属 effects 侧他 TU (书已邻接), 勿混。断言行号 :55 = 比较器, :48 = 排序入口, 一文件两站点。**_Push_heap (0x1413D19B0) 洞位下移实现**: 先 free 目标串 (堆分支含 len+1≥0x1000 容器溢出哨兵 → invalid_parameter_noinfo_noreturn) → 两条 16B OWORD move → 源串头复位 {cap=15, len=0}; 比较器**内联**在本函 (非调 0x1413D1E40); 签名 (数组基, 根边界 idx, 新元素 idx, 待插入 40B 元)。


**technology.cpp 50-99 行簇补录**: **InitPostRead = 0x140EE0400** (自报串 :2554): 遍历 ts+136 {c@+148} 逐科技 GetTechState 重算写 tech+368; 状态变化双路通知 = tech+24 {c@+36} 听众表逐元虚槽[2] (传旧态) + tech+176 {c@+188} 门控后继逐个 sub_140ED6B50; **满级补跑** = tech+372(level) ≥ 模板+988(max_level) → sub_140EE3E70 完成聚合器 + 尾链 sub_1413C5260(v18, 模板+1112, 100000) (语义待裁)。**GetTechnology 按名 = 0x140ED4F30** (名→token sub_140ACBF30 → sub_140ED5080; 未命中 "Technology … doesnt exist" :3230 + debug 警告 "will crash prolly" :3231 返 0)。

**tech_formatter 两函 (新收, 定案)**: ① **科技名本地化格式化器 sub_140533050** (tech_formatter.cpp:34, sret 返显示名) — token → sub_1424BC260 取名视图 → 串规整 sub_140BC96D0 → GetTechnology 按名 (cc+3936 科技状态) → sub_140EDB120(tech, out, 0, 1, 1) 取显示名 (该函语义推定); 未命中日志 "Unable to find technology %s for country %s"。② **tech_effect token 校验器 sub_140533250** (:43) — qword_14332F0A0 CTechnologyDatabase 单例 (gameitemdatabase.h:142 断言) → sub_140AD0B40 线性查 `*(e+60)==id` → 模板+64 有效旗为 0 → 警告 "Invalid token for tech_effect" (与 §4.32 can_research 同门)。

#### 4.7.15 CTechnologyTemplate 真类 ctor 全字段地图 (1 函 = 0x140ACACF0, 定案; 双 vftable 直证)

0x140ACACF0: **§4.7.7 补漏行** = +728 / +920 容器头、+72/+160/+248 三触发器形块、**+392 = CModifier vtable 直写**、+1336 第三 fixed、尾段四串 / +1416; 15 容器头 7 组 EH 析构元素类型聚类。

#### 4.7.16 特殊项目历史条目 → 叙事展示记录转换器 (NProject 域; 1 函 = 0x141A382F0, 定案)

身份表:

| 项 | 值 |
|---|---|
| 语义 | NProject::SProjectHistory (88B) 条目 → 叙事/上下文展示记录 (CNarrative + CGameDate 双内嵌) |
| 签名 | (出参记录 a1, SProjectHistory 条目 a2, 项目拥有者 a3) → 返回 a1 (构造器式) |
| 调用者 | ① sub_140FE0AC0 = SProjectHistory 数组拷贝 (逐 88B 条目调本函数, vtable 符号直证); ② sub_141FA44F0 = 突破页 UI 刷新 (loc ONGOING_PROJECT_BREAKTHROUGH_PAGE_HEADER; a1+4312 项目对象, 其 +104 = 88B 历史数组 / +116 条目计数) |

SProjectHistory 条目 (a2, 88B):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | NProject::SProjectHistory |
| +8 | uint32 | token_a (分支键) |
| +12 | uint32 | token_b (分支键; 叙事表内匹配键) |
| +16 | SProjectContext | 48B 上下文 |
| +64 | CGameDate 内嵌 | 日期 (本函数取其 +72 小时域作记录日期) |

出参记录 (sub_141A37F50 构造, ≥176B):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | 指针 | 源/def 指针 |
| +8 | 指针 | 上下文柄 |
| +16 | CNarrative 内嵌 104B | vtable@+16; 三 std::string@+24/+56/+88 (名/标题/描述); 有效旗 u8@+120 |
| +128 | 指针 | 上下文/状态指针 |
| +136 | CGameDate 内嵌 | vtable@+136; 日期 dword@+144; 第二 vtable@+152; 有效旗 u8@+160 |
| +168 | uint8 | 布尔 (分支 ② 置 1) |
| +172 | int32 | 计数/等级 (多实例旗) |

三分支 (按 token 对分派):

| 分支 | 条件 | 行为 |
|---|---|---|
| ① 迭代进度奖励 | (+8, +12) 双双 == 11013 (progress, §4.00 SProjectContext 键序直证) | Init_thread 守卫懒构造静态叙事: malloc(0x30) 建 "SPECIAL_PROJECT_ITERATION_PROGRESS_REWARD" 串挂 unk_1430B44F8 + 三叙事串 unk_1430B4528/4580/45D8 + def/上下文 off_1430B44B0/4520 + 描述符族 qword_1430B4668..46C0 (atexit 注册); 取 a2+72 日期 |
| ② 角色对支 | 双双 == 19479 (character idpair 族 token, §4.00 邻域) | def = a3+472, 上下文 = a3+32, 布尔 = 1, 日期 = a2+72 |
| ③ 通用叙事 | 其余 | a3+856 容器 (16B 元, count@+868) 按 token 查对象 → 其 +264 叙事定义表 (156B/元, count@+276, 表内按元+8 == a2+12 匹配; 三 SSO 串 @元+116/+124/+132); 同容器按 a2+8 查第二对象取 +276 计数 > 1 作多实例旗; 栈建 CNarrative + CGameDate → 构造 |

> 待裁: a3 容器 (+856) 元素类与 CProjectPool/CProgram 的 RTTI 对应关系 (§4.3 cc+4008 域锚点未反查); 静态叙事槽逐槽语义; 分支 ③ 第二实参具名 (反编译省略)。

#### 4.7.17 CTechnologyDatabase 装载尾重建器 (sub_140ACE570 = vtable[2]; technologytemplate.cpp; 定案)

**身份**: CTechnologyDatabase (RTTI `.?AVCTechnologyDatabase@@`, TD 0x143228010 / 基 TD 0x143228040 = `.?AV?$TGameItemDatabase@VCTechnologyDatabase@@@@` / COL 0x142CC69B0); 主 vtable 0x142944150 = **TGameItemDatabase 5 槽族表**: [0] 0x14012A2C0 CFG 桩 / [1] 0x140ACBD10 标量删除析构 / **[2] = 本函数 (装载尾重建器)** / [3][4] 0x14012A2C0 CFG 桩。⚠ 该 [2] **不是** §4.00.1 的 CPersistent writer 槽 (族表 [1] 是析构非 Save wrapper; 库不落盘, 模板 = 只读 def)。调用链 = boot `sub_14018BB20 → sub_140163E30` (取单例 qword_14332F0A0) `→ sub_14018B330(db, "common/technologies")` (家族 Load 包装: 目录解析 → `(*vt+16)(a1)` = 本函数 → `(*vt+32)(a1)` = CFG 空桩); 语料零直接调用者 (PE 唯一 VA 交叉引用 = vtable 槽); 重复装载被 db+20 已载旗拒绝 ("DB already loaded when loading")。同构先例 = CBuildingDatabase (§4.26.11b)。

**三遍扫描** (模板主数组 db+72 {data, cap@+80, count@+84}; null object 占 array[0], 循环从下标 1 起):

| 遍 | 动作 |
|---|---|
| A1 | 自 parent 跳过门: parent 名 hash (+976) == 自身名 hash (+48) 且 stricmp(parent, name)==0 → 跳过本模板 (防自引用) |
| A2 | 查 parent 模板: sub_140AC80E0 (FindByName, 40B 键) → 未中 = null object |
| A3/A4 | allow / allow_branch 继承: 把 parent 触发器块地址压入**子块内 +8 的子触发器向量** (模板 +80 / +168) = 链式 AND |
| A5 | 六列表尾插继承: +584 (48B) / +632 / +656 / +704 (40B 名键) / +680 (24B) / +848 (40B 名键); +728 hash 表经 sub_1401E1640 合并 |
| A6 | 三标量空值兜底: +984 start_year / +1033 豁免旗 / +992 research_cost 为 0 ← parent |
| A7/A8 | 特化校验: +884 计数 > 2 → "Technology has more than two specializations." (:865); 逐 +872 id 在 CSpecializationDatabase (qword_14332F068) 查, 未中 → "Technology has an invalid specialization \"%s\"" (:874) |
| A9/A10 | 反向索引登记: +704 名键 → db+120 类别对象 (有效门 +48, 模板向量 +56); +896 CFolderPosition 条目 → db+168 folder 对象 (有效门 +56, 模板向量 +64, 位置向量 +88) |
| A11 | XOR 路径树坐标: 逐 +752 path 边查后继模板 → 配对共享 folder (hash+stricmp) → path 条目 +56 记源名 (hash@+88) + +96 有序 56B per-folder 位置对表更新 → folder→边有序映射聚合 → sub_140AD5330 定案 (≥2 对; 两后继互在对方 +824 互斥表 → 判 XOR 对, 建 152B 树坐标对象挂 path 条目 +120; >2 对警告 :780; 缺坐标警告 :803; 非对称断言 :786 "Mutual exclusive paths are not symmetric") |
| B | root-key 计算与 BFS 下游传播: 模板无前置 (+776 空) ∨ 前置不含本 folder → 建 SRootKey 入 +920 有序向量; 仅当有新增才沿 +752 path 边 (跳过 ignore_for_layout@+144) 压后继入工作栈 |
| C1 | 装备解锁反向索引: 逐 +632 名键 → db+216 24B 条目 {vector<模板*>@+0, vtable@+16}; 未中 → malloc(0x18) 建对象入数组 + 键入 db+240 查表 |
| C2 | 子科技 parent 定案: 逐 +848 名键查子模板; parent 名空 → 拷本模板名 + hash; 冲突 → 警告 "Subtechnology %s has two parents…" (:1036) + 断言 "Subtechnology has two different parents" (:1037) |
| C3 | 子科技 folder 继承: 子 +908 folder 计数 0 → 拷本模板 +896 的 56B CFolderPosition 条目 |

**CTechnologyDatabase 库布局** (ctor sub_140ACA4A0 + 本函数双证; 四对 array+lookup 容器):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | CTechnologyDatabase 主表 0x142944150 (5 槽族表) |
| +20 | uint32 | 已载旗 (重复装载门) |
| +72 | 24B 容器 | 模板主数组 (元素 = CTechnologyTemplate*; array[0] = null object 0x143339CD8) |
| +96 | 24B 容器 | 模板名 lookup (40B 键 {SSO 串@+0, hash@+32}) |
| +120 | 24B 容器 | 类别对象数组 (推定 CTechnologyCategory; array[0] = null) |
| +144 | 24B 容器 | 类别 lookup (40B 键) |
| +168 | 24B 容器 | folder 对象数组 (CTechnologyFolder 208B, null 0x14333A228) |
| +192 | 24B 容器 | folder lookup (40B 键) |
| +216 | 24B 容器 | 装备解锁条目数组 (元素 24B = {vector<模板*>@+0, vtable@+16}) |
| +240 | 24B 容器 | 装备解锁 lookup (40B 键) |

> FindByName 族不变量 = Array.GetSize() == Lookup.GetSize() + 1 (gameitemdatabasehelper.h:35, null object 占 array[0]); 四实例化闩 = byte_14333A23E (模板) / 23F (类别) / 241 (folder) / 242 (装备解锁)。

**path 条目 (152B) 装载尾新增两域**: +56 源科技名串 (hash 现算落 +88) + **+96 有序 56B per-folder 位置对表** {folder 名串@+0, hash@+32, 16B 位置对@+40} (二分维护 sub_140AC9350)。

> 未决: 类别对象 / folder 对象全布局 (仅见有效门 + 模板向量 + 位置向量); db+216 条目语义名 (推定 = 装备→解锁科技反向索引, 消费方未闭环); +776 前置表元素类 (8B 指针 → 对象+56 名键, 构造点未定位); sub_140AD5330 坐标取整数学; +920 root-key 消费方 (推定 = 科技树布局渲染层); db+40 标签装载参数槽; XOR >2 对的降级选择逻辑。

#### 4.7.18 科技域函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140ED3E80 | sub_140ED3E80 CTechnologyStatus vtable + tbb 并行初始化（科技状态对象） |
| 0x141BE2770 | sub_141BE2770 CConfirmResearchTechnology vtable（确认研究科技） |
| 0x141F0DDD0 | sub_141F0DDD0 BREAKTHROUGH_PROGRESS / TECHNOLOGY_BONUS / SPECIALIZATION / EXP / PROGRAM_BASIC_RESEARCH（科技研究进度 UI） |
| 0x1413CA460 | sub_1413CA460 学说经验不足（country_doctrine_status.cpp:263，DOCTRINE_ARMY_XP_INSUFFICIENT） |
| 0x1413C7670 | （无名） vftable 类 NDoctrines::STemporaryMasteryGain::（学说） |

#### 4.7.19 科技域函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x141CC4120 | （无名，按上游/loc 定性） loc "GRAND_DOCTRINE_SELECTION_TITLE" |
| 0x1415FA720 | （无名，按上游/loc 定性） gamestate.h:1125 |
| 0x1409CC8A0 | sub_1409CC8A0 特征串:DOCTRINE_UNLOCK_REWARD_TITLE |
| 0x140AC6890 | CTechnologySharingGroupTemplate::[0] CTechnologySharingGroupTemplate::[0] + vtable/RTTI 类 CTechnologySharingGroupTemplate; vtable/RTTI 含 CTechnologySharingGr… |
| 0x141F3A4D0 | sub_141F3A4D0 特征串:doctrine_list_item ; SUBDOCTRINE_DESCRIPTION |

#### 4.7.20 科技域函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x140EE1B60 | CTechnologyStatus::Reader 序列化 Reader 角色；loc \"RESEARCH_NO_RESEARCH\"，被调 pdx_scopedptr.h:124/Reader/parser.cpp:1087/localize.cpp:641 |
| 0x140ACD580 | 研究提前惩罚显示 研究提前惩罚显示；loc \"RESEARCH_YEAR_AHEAD_PENALTY\"/\"RESEARCH_YEAR_AHEAD_PENALTY_RED\"+\"VALUE\"/\"YEARS\"/\"REDUCED_YEARS\"/\"RED\" |
| 0x141CB1050 | "BREAKTHROUGH_BONUS_TECHNOLOGY_RESEARCH/ "BREAKTHROUGH_BONUS_TECHNOLOGY_RESEARCH/TECHNOLOGY/PROGRESS" §4.7 科技 |
| 0x1415FA300 | "slots_window/research_slots_grid" 研究槽 U "slots_window/research_slots_grid" 研究槽 UI §4.7 科技 |
| 0x14145FB20 | sub_14145FB20（无名） scientist_skill_levels.cpp:292 站点，"Define SCIENTIST_SKILL_LEVEL_SPEED_MODIFIER size must be ... THREHOLDS size + 1" + SCIENTIST_SKILL_LEVEL… |
| 0x141A05B20 | sub_141A05B20（无名） VALUE / PROGRAM_SCIENTIST_BREAKTHROUGH / SPECIALIZATION GUI 键，夹于 NProject::CProgramConsumer::Writer(d=80) 与 CWeatherChancePeriod::[7]，项目科学家… |

#### 4.7.21 科技域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x141BDC380 | （无名，按证据定性） 键 RESEARCH_DESIGN_TEAM_IS_BUSY + NAME（科研设计团队忙碌状态） |
| 0x1414BA2C0 | 科技键 "TECH" + gamestate.h:1125 站点 + pdx_core 单例断言 |
| 0x140ED4EF0 | CTechnologyStatus::[0] vtable 槽 CTechnologyStatus::[0]（func_names RTTI 名） |

#### 4.7.22 科技域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|

#### 4.7.23 科技域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x140ED4860 | （无名） 体设 CTechnologyStatus::vftable（RTTI 名） |

#### 4.7.24 科技域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|

#### 4.7.25 科技域函数补遗（21 函）

| VA | 语义/证据 |
|---|---|
| 0x1415985B0 | （无名） 调用图传播: 3 锚点投 §4.7（67%） |
| 0x141BA5ED0 | （无名） 调用图传播: 3 锚点投 §4.7（67%） |
| 0x141EE8860 | （无名） 调用图传播: 8 锚点投 §4.7（100%） |
| 0x140ED5140 | （无名） 调用图传播: 4 锚点投 §4.7（50%） |
| 0x140EE2910 | （无名） 调用图传播: 4 锚点投 §4.7（50%） |
| 0x141178730 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x141EE7CE0 | （无名） 调用图传播: 4 锚点投 §4.7（100%） |
| 0x1409E78E0 | （无名） 调用图传播: 2 锚点投 §4.7（100%） |
| 0x140550F30 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x142275720 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x141EF05E0 | （无名） 调用图传播: 4 锚点投 §4.7（100%） |
| 0x141A35880 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x141EE9110 | （无名） 调用图传播: 6 锚点投 §4.7（100%） |
| 0x141A371B0 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x140324D00 | （无名） 调用图传播: 4 锚点投 §4.7（50%） |
| 0x140305AC0 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x1412192B0 | （无名） 调用图传播: 2 锚点投 §4.7（100%） |
| 0x140FE57A0 | （无名） 调用图传播: 6 锚点投 §4.7（83%） |
| 0x140EE11D0 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x141EF08B0 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |
| 0x14145E080 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |

#### 4.7.26 科技域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141F073B0 | 科技部署将领修正 串 "TECHNOLOGY_DEPLOYED_GENERAL_MODIFIERS_HEADER"/"leader_bonuses_grid" → 科技部署将领修正 |

#### 4.7.27 科技域函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x140AD0580 | sub_140AD0580 special_forces_doctrine_folder（特种部队学说文件夹 UI） |
| 0x140D81710 | 无名领域函数 sub_140D81710 被调用者定名: CTechnologySharing::GetFullTooltip? 等命中 §4.7（占 100%，共 2 callee） |
| 0x141F41FE0 | sub_141F41FE0 特征串:spirit_grid_over_defined |
| 0x140A08DC0 | 调用图上游传播(占 57%, 2 票) sub_140A08DC0 + 调用图上游传播(占 57%, 2 票) |
| 0x1401548B0 | 域关键词匹配 sub_1401548B0 + 域关键词匹配 |
| 0x140AD25D0 | 调用图上游传播(占 50%, 2 票) sub_140AD25D0 + 调用图上游传播(占 50%, 2 票) |
| 0x140AD2920 | 域关键词匹配 sub_140AD2920 + 域关键词匹配 |

#### 4.7.28 科技域函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x140AD1660 | （无名） 调用图传播: 3 锚点投 §4.7（100%） |
| 0x140AD1890 | （无名） 调用图传播: 6 锚点投 §4.7（100%） |
| 0x1413D0A00 | （无名） 调用图传播: 3 锚点投 §4.7（100%） |

#### 4.7.29 科技域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x140323140 | 业务逻辑（见证据锚） "Invalid target for CStealRandomTechBonusEffect"（科技窃取效果实现） |
| 0x14197F410 | 业务逻辑（键 MODIFIER_DOCTRINE_PREFIX） "MODIFIER_DOCTRINE_PREFIX"×2（学说修正前缀，idb 断言） |
| 0x14140AA30 | 业务逻辑（键 SCIENTIST_TOOLTIP_NAME） "SCIENTIST_TOOLTIP_NAME"/"SCIENTIST_TOOLTIP_SUPPORTIVE"/"PROG"/"CONT"/"LORE"（科学家 tooltip） |
| 0x140CCCA20 | CDoctrineSystem 学说系统 (vtable类名 CDoctrineSystem) vtable引用 CDoctrineSystem vftable |

#### 4.7.30 科技域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x140D84580 | （无名） 调用图传播: 4 锚点投 §4.7（50%） |
| 0x140D846A0 | （无名） 调用图传播: 4 锚点投 §4.7（50%） |
| 0x141EE9370 | （无名） 调用图传播: 3 锚点投 §4.7（100%） |
| 0x140D83AE0 | （无名） 调用图传播: 4 锚点投 §4.7（50%） |

#### 4.7.31 科技域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x14140CEB0 | （无名） 调用图传播: 2 锚点投 §4.7（50%） |

#### 4.7.32 科技域函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141F0CF10 | 无名 sub_（断言站点/串定位） 串字面量 "PROGRAM_ITEM_BASIC_RESEARCH_TOOLTIP" |
| 0x141A36590 | 无名 sub_（断言站点/串定位） 串字面量 "SPECIAL_PROJECT_RESEARCH_TIME_TOOLTIP_TOTAL" |
| 0x141BD8380 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_research_folder_strip" |
| 0x140EE3B70 | 无名 sub_（断言站点/串定位） 断言站点 technology.cpp:2565 |

#### 4.7.33 科技域函数补遗（8 函）

| VA | 语义/证据 |
|---|---|
| 0x1409E97B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x1414E3B70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x141BB0700 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x1414E3EC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x1410488F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x140EE4A50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x141A357B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |
| 0x1424C4EA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.7 |

#### 4.7.34 科技域函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x1411AB140 | 科技隐藏切换 控制台命令"Toggle all hidden technologies"（0x1F 长度）+ vtable+184 作用域 |

#### 4.7.35 科技域函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x141FA37F0 | 科技UI "ONGOING_PROJECT_GO_TO_NEXT/PREVIOUS_BREAKTHROUGH" 按方向选择 + vtable+520 条件分支；科研突破导航 UI |
| 0x140DB7460 | 科研完成回调 "on_mio_tech_reseach_completed" 回调注册（sub_140A53810 + sub_1413AE5C0 + malloc(0x20)） |
