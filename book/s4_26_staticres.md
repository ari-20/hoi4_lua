

### 4.26 静态资源访问层 (idb 库规格 / 访问器 API / 防御界 / 离线资产 / 验证体系)

#### 4.26.0 总览与纪律

- **实现位置**: `resource.lua` (自 hoi4_layout 拆出; hoi4_layout 经 `MOD_LUA_DIR`
  dofile 挂载并 attach 到 `GAME.layout`, 段侧调用不变), 段侧包装在 `SV2.lib`。
- ⚠ **分层纪律**: 静态资源一律调统一访问器 —— 段内散写内联曾致 modobj 修饰
  定义表 0x3169C0 掉位事故 (少一个 3)。
- **库家族规模**: TGameItemDatabase 模板实例 103 个 → **81 key 入规格表**
  (§4.26.4) + 22 形态外 (布局已定案, 需专写 reader, §4.26.4)。
- **旧静态槽位表 (legacy STATIC) 已删**: 曾有两代实现并存 —— 对象层的
  `Runtime.definitions` 读一份 legacy `STATIC` 表 (1.19.2 六库/扩展库地址),
  本节 idb 族 (`resource.lua`) 是 1.19.3 后继。旧者既无调用方 (实测
  `sv2_export` 全路径 0 次触达), 地址又已失效 (活体返回垃圾计数), 故
  `STATIC` 表 + `definitions` 一并移除。**静态资源访问唯一入口 = 本节
  idb 族**; 需旧六库枚举者用 `M.idb_count/M.idb_token` 按 §4.26.4 规格重写。

#### 4.26.1 replace_path 与 mod 加载语义

- mod 声明 `replace_path="X"` 后，路径 X **只从声明 replace 的 mod 读取**
  ——vanilla 与其它非替换 mod 的文件全部跳过（KR 主 mod 替换 74 路径 /
  BlackICE 65；technology 下 19 个 vanilla tech 来自非替换 mod 却未入 DB
  实证）。
- `dlc_load.json` enabled_mods 数组序 = 加载序；同 relpath 文件后者覆盖。

引擎行为补充:

| 项 | 结论 | 证据 |
|---|---|---|
| original_* 副本 | 被 mod 覆盖的定义在库内保留 `original_*` 前缀副本 | faction_rule / rule_group / template 共 7 个 |
| FNV-1a 大小写不敏感 | country_tag_alias 的 int/INT 同库同义 | — |
| building cnt/lookup 分歧 | 库 cnt(78) 与 lookup.size(85) 数据级分歧 | GetItem 数组语义为准，roundtrip 全过 |
| building lookup 元布局 | 形态定案 : 非 40B 名录 — 85 桶×24B 哈希桶/链 {alloc, 节点链头, (1,1)}, 节点 {next, hash64, …}; 「仅 1 项可读名」系 40B 错位巧合; 条目名以 arr 侧 GetItem 为准 | 定案 |

#### 4.26.2 基础访问器 (token / 反查 / FNV)

| # | 项 | 语义 |
|---|---|---|
| 1 | lexer token 表 | 表指针 `*(BASE+56396672)`（std::string 数组 stride 0x20），上限 id `u32@(BASE+56396628)` |
| 2 | `GAME.layout.token_name(id)` | 热重载重建缓存，悬垂安全；越界/0 → nil |
| 3 | `SV2.lib.tok(t)` | 段侧包装；取不到兜底原值 |
| 4 | ⚠ 运行时 ≠ 离线 token 表 | 运行时表含 mod token，id 空间整体重排 ≠ 离线 `ref/token_table_1193.txt`（原版 exe 提取）。实例：离线 20002=`arms_factory` / 游戏内 20002=`authoritarian_democrat`。**禁止用离线表按 id 取名，一律走游戏内 `token_name`** |
| 5 | name→token 反查 | `GAME.layout.name_to_token(name)`：全表扫建 {name→id} 索引，每进程一次（与 get_flag 共缓存） |
| 6 | FNV-1a 哈希 | 串版 `GAME.layout.fnv1a(s)`（variables RH 表键）；指针版（8 字节逐字节 h=0x811C9DC5 起，h^=b; h*=0x01000193）见 §4.3.12 |

#### 4.26.3 非 DB 静态注册表

| 表 | 挂载 | 布局 | 访问器 |
|---|---|---|---|
| modifier 定义表 | `rp(BASE+53569984)` | stride 120, token u32@def+112, cnt@BASE+53569996 (BHU 4,486 / kr2 5,285); **id 空间两段定案: 静态宇宙 = 0..665 稠密 666 槽 (注册点全解 100%, 离线 id→名全表数据件 `ref/modifier_idmap.txt`), 动态段 = 脚本动态 modifier 自 666 起编号** (wrapper sub_14060C290 内 index = 计数器+666, 随 mod 变, 离线不可枚举; 旧「712 项」含错位窗假阳证伪, 以 666 全表为准) | `modifier_token(idx)` / `modifier_count` / `modifier_category_mask`（掩码 u32@0x332f248） |
| modifier tooltip 格式化器 | `sub_14055A0C0(修正块, out, def_idx, lambda, …)` → `sub_1410E46D0(值串, 国名, 件)` | 越界门: `a3 > dword_14332ED9C`（=cnt 槽）→ 越界返空串 | loc 模板 `$MODIFIER$: $VALUE$` 渲染入口 |
| modifier tooltip 取数 | — | 越界过 → 查定义表 `qword_14332ED90 + 120*a3`; 类别掩码 `u32@def+104` 经 `qword_1433300A0(修正块)` 谓词门滤 | GUI `Get*Tooltip` 族逐修正名 + 值组装多行串 |
| external_rules 定义 | `rp(BASE+53575920)` | `M.dim.EXTERNAL_RULES`=28 槽, 键 token u32@defs+56*i+40（[0]="none" 哨兵+27 规则键） | `rule_key(i)` / `rule_def_flags(i)`（字节@+48/49/50） |
| SET 名串表 | `rp(BASE+53626272)` | **指针全局须先解引用**，条目 32B MSVC; count 实时@0x333d53c; idx=0 无名 | `set_name(idx)` / `set_count` |
| CSavedEventTarget | scope 内联@事件+16; 触发 = from==自指 且 \*(sc+160)≠0 | 容器 \*(sc+160) = {data@0, cap@8, count@12}; 元素 112B (布局见下表); 叶序 state→country→name, 第 2+ 目标编 [N]; writer sub_14053BDA0 + 元素 sub_14053C090 | 段内 emit_scope |
| id 注册表 (#.id) | BASE+54758992/58/60 | 三源 RH (buckets@+8, mask@+20, +40 是 hash seed), value=u64@vp+8=(id<<32)\|type, 逐型 max; 源③ 8B×100 槽 | `idreg_unit_resolve` / `idreg_maxima`（§4.26.5） |
| grand doctrine 定义库 | `qword_14332EEA8` | 定义库 {data@+56, mask@+68, extra@+72}; 推定 | — |
| sub doctrine 定义库 | `qword_14332EEB0` | 定义库; 推定 | getter sub_14052AE00 |
| rule def 表 | `qword_1433304C0` | 56B/条; 推定 | has_rule GetDesc 名来源 |
| 事件目标名表 | `qword_14333D530` | 32B/条; 推定 | has_event_target GetDesc 名来源 |
| 原 tag → 国 id 展开表库 | `qword_14332F260` | 表对象 {data, count@+12}; ⚠ 地址与 gs 单例全局同名址, 宿主归属未裁; 推定 | getter sub_1401DBD80 |
| 歌曲库 | `unk_14333C610` | —; 高置信 | — |
| 内容启用位掩码 | `dword_14332F248` | u32; 亦经 modifier 类别掩码出口读 (同址两名); 推定 | — |
| 循环迭代上限 | `dword_1433368E0` | u32 (值未取); 推定 | — |
| ironman 前置强制旗 | `byte_14332F646` | u8; 推定 | — |
| 调试模式全局 | `byte_14332EC69` | u8; is_debug / debug 警告开关; 高置信 | — |
| 动态国判定阈值 | `qword_143330D98 + 136` | u32; 推定 = 静态国家计数 (该全局 = 事件目标注册表); 推定 | — |

CSavedEventTarget 元素布局 (112B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | vt | — |
| +8 | u32 | state | ≠0 写 .state |
| +12 | i32 | country tid | >0 写 .country |
| +104 | u16 | 名字索引 | ≠0 → set_name(idx) |

#### 4.26.4 idb 库规格 (102 key)

⚠ **"家族统一 arr@64/cnt@76/token@+8" 不成立** — 仅 4 库标准族，其余
arr/cnt/名字段随派生类漂移（cnt 漂移实例 52/60/76/84/92/100/108/132/
148/188/212）。扩新库必须逐库 ctor 定案后落同款规格表。本表由
`resource.lua M.rva.idb` 生成，规格以代码注释为准。

| key | 单例 RVA | arr@ | cnt@ | def 名 | nonull | 备注 |
|---|---|---|---|---|---|---|
| state_category | 0x332f968 | +64 | +76 | tok8 | 否 | CStateCategoryDatabase 14 (13+none) tok8; STATE 段 (kr2 事故族) |
| building | 0x332ee28 | +64 | +76 | tok8 | 否 | CBuildingDatabase 56 (55+none) tok8; states buildings (取代 legacy BLD2_NAMES); **+232/+244 与 +832/+844 = 两类别 def 子集容器** (高置信, 填充点未找; GUI = 海军 HQ 站点匹配链, §4.16.14) |
| equipment | 0x332eec0 | +104 | +116 | tok8 | 否 | CEquipmentDatabase 457 tok8 (变体+原型合并; upgrades@176/38, modules@224/313 另有) |
| technology | 0x332f0a0 | +72 | +84 | "sso16" | 否 | 553 (arr[0]=null 空名) sso@def+16; folders@168/17 (folders 子表元素类 = **CTechnologyFolder**, 208B, ctor sub_140ACC080); 条目类 = CTechnologyTemplate (见下「条目类」表) |
| focus | 0x332ef70 | +88 | +100 | tok8 | 否 | CNationalFocusDatabase 10888 tok8; arr@64/22 = focus styles (名 sso@+8) |
| idea | 0x332ef30 | +104 | +116 | tok8 | 否 | CIdeaDatabase 5797 tok8; 分类@216/25 tok8, @160/15 sso16 |
| decision | 0x332ee80 | +40 | +52 | "tok16" | 否 | CDecisionDatabase 4128 tok16; lookup@64 (40B 元, 非指针数组); 分类@88/594 (名 sso@def+24) |
| strategic_resource | 0x332f088 | +40 | +52 | tok8 | 否 | 8 (7+none) tok8; db+64 是字符串另物 |
| autonomous_state | 0x332ee18 | +64 | +76 | "msvc8" | 否 | ⚠ 特例: 无 arr/cnt — defs=内联指针数组@db+48, 名 MSVC@def+8, count 扫描; puppet 名也可直接读 def 对象 sso@+8 (§4.10) |
| ideology_group | 0x3330db8 | +96 | +108 | tok8 | 是 | 4 tok8 无 Null Object (democratic/communism/fascism/neutrality) |
| sub_unit | 0x332f090 | +64 | +76 | tok8 | 否 | CSubUnitDatabase 158 (157+none) tok8 (charmgr sub_unit_modifiers 键) |
| wargoal | 0x332ef28 | +64 | +76 | tok8 | 否 | CWarGoalDatabase 11 (10+none) tok8 |
| gamerules | 0x332ef20 | +40 | +52 | tok8 | 否 | ⚠ 稀疏: 86 槽大半脏指针 (BHU 仅 4 槽可命名), 枚举须逐槽 kptr+名过滤; 规则实例侧用 rule_key |
| terrain | 0x332f0a8 | +64 | +76 | "sso24" | 否 | CTerrainDatabase A 族; sso@def+24 (+8 非 token) |
| opinion_modifier | 0x332efc0 | +40 | +52 | tok8 | 否 | B 族 tok8 |
| strategic_region | 0x332f080 | +40 | +52 | "sso32" | 否 | "%s (%i)" 直证 |
| state | 0x332f070 | +40 | +52 | "none" | 否 | 按 id 无名 |
| country_leader | 0x332ee68 | +64 | +76 | tok8 | 否 | A 族标准 |
| continuous_focus | 0x332ee60 | +48 | +60 | "sso24" | 是 | miss 返 0, arr[0] 真实元素 (hash@+16 不参与取名; def 名直写 sso24 —— 泛化 sso24h16 别名会丢名致断名) |
| agency_upgrade | 0x332edc0 | +64 | +76 | tok8 | 否 | 标准 tok8; TNullObject@0x3330480 |
| ai_focus | 0x332ee08 | +64 | +76 | tok8 | 否 | 标准 tok8; CNullAIFocusDatabaseEntry |
| ai_equipment_role | 0x332edd8 | +64 | +76 | "msvc8" | 否 | CNull…Entry |
| ai_role | 0x332edf0 | +64 | +76 | "sso16" | 否 | CNullAIRoleDatabaseEntry |
| ai_strategy_plan | 0x332ee10 | +72 | +84 | "sso24" | 否 | ⚠ cnt 漂移 84 (B 族 72 起步实例) |
| bookmark | 0x332ee20 | +40 | +52 | "sso16" | 否 | TNullObject@0x332f350 |
| unit_leader | 0x332f0d0 | +88 | +100 | "sso16" | 否 | TNullObject@0x333a2a8 |
| aces | 0x332edb0 | +40 | +52 | "msvc8" | 是 | miss→0 无 Null Object |
| scripted_window | 0x332f060 | +40 | +52 | "msvc8" | 是 | miss→0 |
| ability | 0x332eda8 | +40 | +52 | "none" | 否 | 定案: nm = MSVC 串@def+112 (探针: 14 条全读出, force_attack…rotating_reserves) |
| ai_area | 0x332edc8 | +40 | +52 | "none" | 否 |  |
| ai_attitude | 0x332ede8 | +64 | +76 | "none" | 否 |  |
| country_scorer | 0x332f018 | +136 | +148 | "none" | 否 | TReloadable 样板 (内联 null@db+160) |
| timed_activity | 0x332f0b8 | +48 | +60 | "none" | 否 | 内联 16B 元 |
| career_medal | 0x332ee30 | +40 | +52 | "sso72" | 否 | 库类 `NCareerProfile::CMedalDatabase` (TGameItemDatabase 族, 96B; ctor 0x1406AAE10; 条目类 `NCareerProfile::CCareerProfileMedal`); A 族; 条目 u32@+8 是硬编码 id 非 token, 显示串@+72 = loc 串 sub_1406ABD30; +104=描述, +136=quote 仅绶带; 布局全回收见 §4.3 |
| career_picture | 0x332ee38 | +40 | +52 | "none" | 否 | 库类 `NCareerProfile::CProfilePictureDatabase` (64B; ctor 0x1406AC6E0); GUI-only |
| career_background | 0x332ee40 | +40 | +52 | "none" | 否 | 库类 `NCareerProfile::CProfileBackgroundDatabase` (64B; ctor 0x1406AC470; def 去向 `common/profile_backgrounds`) |
| career_ribbon | 0x332ee48 | +40 | +52 | "none" | 否 | 库类 `NCareerProfile::CRibbonDatabase` (96B; ctor 0x1406AF690; 条目类 `NCareerProfile::CCareerProfileRibbon`); medal 同型 getter 族 (+72 名/+104 描述/+136 quote) |
| ai_fleet_template | 0x332ef88 | +80 | +92 | tok8 | 是 | PersistentReloadable; tok8 (FNV@+8) |
| ai_taskforce_template | 0x332ef80 | +80 | +92 | tok8 | 是 | fleet 同构 (nm 推定) |
| focus_inlay_window | 0x332efd0 | +80 | +92 | "none" | 是 |  |
| frontend_background | 0x332ef18 | +80 | +92 | "none" | 是 |  |
| strategic_location | 0x332f078 | +80 | +92 | "none" | 是 | nm 推定 |
| scripted_trigger_template | 0x332f058 | +64 | +76 | "sso96" | 否 | null=TNullObject@0x33121140 |
| scripted_diplomatic_action | 0x332f048 | +40 | +52 | "none" | 否 | 定案: nm = MSVC 串@def+16 (探针: 2 条) |
| scripted_map_mode | 0x332f040 | +40 | +52 | "none" | 否 | **def 名串在 +232** (MSVC 32B: 缓冲@+232 / size@+248 / cap@+256) — 探针按 sso 族偏移取不到故误判无串; def 类 = `CScriptedMapMode` (vt 0x142942720), 库 = `CScriptedMapModeDatabase` (vt 0x1429427A0) ← TGameItemDatabase 模板, 单例 qword_14332F040; 匹配直证 = boot 加载器 sub_140AAF740 按 `def+232` 串 memcmp; def 其余键: 602 top→+8 / 603 bottom→+120 / 19186 failure→+264 / 19187 limited_success→+268 / 19188 critical_success→+272 |
| equipment_group | 0x3330480 | +96 | +108 | tok8 | 是 | A 族变体 GetByToken vec@96/tok8@+8 |
| character_advisor_generation | 0x332ee50 | +40 | +52 | "none" | 否 | 同族推测 |
| ideology | 0x332f528 | +96 | +108 | tok8 | 否 | miss 回退 +120 默认槽 (TNullObject<CIdeology>@0x3339d00) |
| country_tag_alias | 0x332ee78 | +96 | +108 | "tok264" | 否 | ⚠ token 在元素+264 非 +8 (防呆) |
| mtth | 0x332ef58 | +96 | +108 | tok8 | 否 | tok8; byte@128 = 内容解析开关 (1=只登名/0=全解析; 条目布局 §4.26.11) |
| historical_agency | 0x332edb8 | +40 | +52 | "none" | 是 | 库类 `CHistoricalAgencyDatabase` (64B; ctor 0x140171B60); **本库 def 无名键** — reader 0x140621F70 四键: `picture`(464)→+40 SSO / `names`(12767)→+16 串列 / `default`(11405)→+160 子块 / `available`(12264)→+72 子块; resource.lua 键源应改 `nm="none"` |
| scientist_trait | 0x332f010 | +96 | +108 | tok8 | 是 | tok8 |
| difficulty_settings | 0x332ee88 | +40 | +52 | "sso56" | 否 | getter = sub_140170630 单例 creator (`qword_14332EE88`, `_pInstance && "Instance already created."` gameitemdatabase.h:127 断言链; 并列的 sub_140170120 在 1.19.3 不存在) |
| operations | 0x332efa8 | +96 | +108 | tok8 | 是 | TReloadable 三连 |
| operation_phases | 0x332efb0 | +96 | +108 | tok8 | 是 |  |
| operation_tokens | 0x332efb8 | +96 | +108 | tok8 | 是 |  |
| on_action_data | 0x332efa0 | +64 | +76 | "none" | 否 | A 族; arr[0]=COnActionList null@0x3339e80 |
| unit_medal | 0x332f0c8 | +64 | +76 | "none" | 否 | 库类 `CUnitMedalDatabase` (TGameItemDatabase<CUnitMedalDatabase>, 88B; ctor 0x140AE1830; creator 0x140173F00; boot 载 `common/unit_medals` via loader 0x14018B960); A 族; arr[0]=TNullObject@0x333a278; def GUI 锚: +152 图标 gfx 基名串/+1068 frame/+760 基础花费/+184·+568 双 modifier 文本源, 详见 §4.18 |
| test_db | 0x332f0b0 | +40 | +52 | "none" | 否 | 测试桩 (无 parse 路径, 常态空) |
| faction_goal | 0x332eee0 | +80 | +92 | tok8 | 是 |  |
| faction_icons | 0x332eee8 | +80 | +92 | tok8 | 是 |  |
| faction_member_upgrade | 0x332eef0 | +80 | +92 | tok8 | 是 |  |
| faction_member_upgrade_group | 0x332eef8 | +80 | +92 | tok8 | 是 |  |
| faction_rule | 0x332ef00 | +80 | +92 | tok8 | 是 |  |
| faction_rule_group | 0x332ef08 | +80 | +92 | tok8 | 是 |  |
| faction_template | 0x332ef10 | +80 | +92 | tok8 | 是 |  |
| ai_faction_theater | 0x3330c60 | +80 | +92 | tok8 | 是 |  |
| doctrine_folder | 0x332eea0 | +80 | +92 | tok8 | 是 |  |
| grand_doctrine | 0x332eea8 | +80 | +92 | tok8 | 是 |  |
| sub_doctrine | 0x332eeb0 | +80 | +92 | tok8 | 是 |  |
| doctrine_track | 0x332eeb8 | +80 | +92 | tok8 | 是 |  |
| ai_bonus_weight | 0x332edd0 | +96 | +108 | tok8 | 是 | TRS |
| mio_organisation | 0x332ef48 | +96 | +108 | tok8 | 是 | TRS (Add 直证 sub_140168160; 副表@160) |
| mio_policy | 0x332ef40 | +96 | +108 | tok8 | 是 | TRS |
| project | 0x332efe8 | +80 | +92 | tok8 | 是 |  |
| prototype_reward | 0x332eff8 | +80 | +92 | tok8 | 是 |  |
| specialization | 0x332f068 | +96 | +108 | tok8 | 是 | TRS |
| raid_category | 0x332f000 | +120 | +132 | tok8 | 是 | 库类 `NRaids::CRaidDatabase` (vt 0x14271B3A8, TReloadableGameItemDatabase); 双仓之 categories 仓 (types 仓 vec@176/cnt@188 需专读); 条目类 = CRaidCategory (224B, 工厂 sub_140A9D170 → db+88) / CRaidType (3064B, 工厂 sub_140A9D2D0 → db+144); 详见 §4.27.2 |
| script_constant | 0x332f020 | +80 | +92 | tok8 | 是 | 库类 `NScript::CConstantDatabase` (128B, 3 基含 TGameItemDatabase; ctor 内联于 sub_14018BB20); 条目 = `NScript::CConstant` (64B, vt 0x14271B5D0); 目录 `common/script_constants`; **首条必须是 `schema` (18061)**; 详见 §4.19.5 |
| script_named_collection | 0x332eed8 | +80 | +92 | tok8 | 是 | 库类 `NScript::CNamedCollectionDatabase` (128B, ctor sub_1401720E0); 条目 = `NScript::CNamedCollection` (408B, vt 0x1427198D8); 目录 `common/collections`; 详见 §4.19.6 |
| ai_naval_goal | 0x332ef78 | +80 | +92 | tok8 | 是 |  |

跨库通用定案:

| # | 定案 |
|---|---|
| 1 | **标准族** = {arr T**@64, cnt i32@76, def token u32@+8}; GetItem sub_140AE2E50: idx<1 或 ≥cnt 回退 arr[0]（多数库 arr[0]="none"） |
| 2 | **A 族** = 名索引 vector@40（40B 条目 {sso 串@0, FNV hash@32}）+ 元素数组 {arr@64, cap@72, cnt@76}（terrain/country_leader/sub_unit） |
| 3 | **B 族** = pdx vector {T** data@X, cap@X+8, cnt i32@X+12, alloc@X+16}（X=40/48/72/88/104 随库漂移） |
| 4 | **PR 族** (PersistentReloadable) = {vec@8 基类(=_Paths 文件路径表非条目), 表@48 (size@64/mask@68), 条目 vec@80/cnt@92, token vec@104}，无 null 回退 |
| 5 | **TRS 族** (TReloadableGameItemDatabaseSpecific) = {条目 vec@96/cnt@108, 宽名表@64 stride 56 {dist@4, token@8, 值@16, 名 sso@24}}；@128 起 32B = boost::signals2 信号（vt off_1427028E0）非数据 |
| 6 | **TReloadable 0x80/0x88 骨架** = {vec24@40, RH-map@64 (73244475 乘法 hash, stride 56, 静态默认条目@72), 条目 vec@96/cnt@108, 默认槽@120, byte@128} |
| 7 | token = FNV-1a 大小写不敏感 hash；`sub_140AC4C70`（arr@88/cnt@100/token@+84）是 sub_unit 第二数组的 GetItem，勿误配 strategic_region |
| 8 | **索引语义通则**: 存档引用静态定义一律写 def 名（token/内嵌串），**无任何字段写 idb 下标**; 唯一例外 = charmgr sub_unit_modifiers 容器 B key |
| 9 | **两套命名空间判别**: 值是小整数且 ≤ idb_count → 查表确认; 数千~数万 → lexer token; ⚠ 绝不可混用互喂 (BLD2 事故) |

形态外 22 库（完整布局定案; reader = `M.idb_find(key, name)` 形态分发）:

哈希族基元 (全族共有):

| 项 | 语义 |
|---|---|
| pdx RH 表头 (32B 内联) | {**+0 桶数组指针 (ctor 置 `.data` 静态空缓冲**, 非 0 亦非 NULL: sub_1411F1AE0 置 `&unk_1430B2A10/2A40/2A90` 族; 收缩路径 sub_1411F7F30 count 归零时 free 后回退 `&unk_1430B2A40`), +8 桶指针 (空态 = .data 静态缓冲), +16 count u32, +20 mask u32, +24 extra u8, +28 满载 f32 0.9}; **nbuckets = mask+1+extra**; 桶 {+0 hash u32, +4 探测步数 u8 (1-based, 起始槽 = 1), +8 键/值} |
| 键哈希两族 | **cs/ci-FNV-1a32** (seed 0x811C9DC5, 素数 0x01000193; ci 版折 A-Z, 配 stricmp) 与 **wang 混洗** (0x45D9F3B 双乘, 特形类用); 键名与存值哈希可不同层 (db10 存名哈希) |
| MSVC unordered_map | 哨兵节点@head, +8 size, +16/+24 桶对; 节点 = {链@0/+8, 键串@16, 值@48} |
| std::map | 头@40 {_Left@8? 按 _Myhead 形}; 节点 {键串@32, 值@node_val} |
| token 键库 | 键 = u32 lexer token 而非名哈希 → `idb_find` 走有界线性扫 (keytok) |
| **空槽判据 (活体定案)** | **hash 槽 == 0**。桶 +4 的探测步数在**已填充槽上也可为 0** (equipment_graphic 起始槽即 0), 0xFF 本族未用 —— 早期按"步数==0 即空"读, 致探测链越过链中途填充槽即断 |
| **探测回绕模数 (活体定案)** | **nb = mask+1+extra**, 非 mask+1。表增长后尾部槽 (idx ≥ mask+1) 仍持条目 (power_balance nb=22/mask=15: 槽16-21 有键), 用 `& mask` 回绕永不可达 → 位移键全灭 |
| **探测起点** | `hash & mask` (u32 与 mask 按位与), 逐槽 +1 以 **%nb** 回绕; 命中后须键串复核 (防碰撞误配) |

| key | 单例 RVA | 形态 | 布局要点 | 回退 |
|---|---|---|---|---|
| name | 0x332ef68 | umap | 哨兵@48/size@56/桶@64; 节点 0x428 {键串@16, 值 CCountryNames 1016B@48}; 键 cs-FNV | miss → 内嵌 default@db+104 (token 11405) |
| name_group | 0x332ee90 | chain4 | **4 链式表** {@40+16t count, @44+16t 模数 **511**, @48+16t 桶阵}; 节点 16B {entry@0, next@8} 头插; 键 ci-FNV%511; entry 0x170 {名@8, hash@40, type@336} | miss → 0 (无 Null) |
| unit_names | 0x332f0d8 | inline | vec@64 stride **120**, cnt@76 = 国家数; 元素 {str@0/32/64, 容器@96}; +40 = "(generic)" 存根 | — |
| portrait | 0x332efd8 | umap | 文化组→CCountryPortraits 400B (节点 448B); 大洲索引 vec@104/cnt@116 (token 10572) | miss → **函数级静态空对象 0x143339ED0** (非 db 内嵌) |
| power_balance | 0x332efe0 | rh | stride **456** {hash@0, dist@4, 键串@8, 值 CPowerBalanceTemplate 408B 内嵌@48}; 键 ci-FNV | miss → TNullObject 0x14333A068 |
| occupation_modifier | 0x332ef90 | rh | stride 48 {键串@8, COccupationModifier*@40}; 键 **cs**-FNV+memcmp; 值 +176 修饰器类型 (4=invalid 拒收) | miss → 0 |
| occupation_law | 0x332ef98 | rh | 同族 stride 48; 值 COccupationLaw 0x340; +96 有序法序列 (空则造 dummy_law) | miss → 0 (⚠ 与上库挂载槽仅差 8) |
| resistance_activity | 0x332f008 | rh | 同族 stride 48; 值 CResistanceActivity 0x390 | miss → 0 |
| ai_strategy | 0x332ee00 | vec3 | 三向量: 名注册表@40 (40B {string, ci-hash}), 条目指针@64/@88, _StrategySpecificData*@112 (cnt@124); 条目 0xD50 {名@3336, hash@3368, id@3376} | miss → TNullObject 0x1433304E8 (3408B) |
| character_template | 0x332ee58 | rh (token 键) | 双表 @64/@96, stride 24 {dist@4, **token u32@8**, 值 T*@16}; 值有效性门 value+16 u8; 表A=角色模板 (表B=顾问模板 推定) | miss → TNullObject 0x143330C60 (0x248) |
| insignia_graphics | 0X332D9A0 | kind8 | **内联固定 8×64B @+40**, 访问器 = db+40+kind*64 (无越界检查); 元素 {名串@8, SInsigniaIconInfo* 向量@40} | 无 Null |
| scriptable_localization | 0x332f038 | umap | 同 name 形 (哨兵@48/size@56); 键 cs-FNV; common/scripted_localisation 定义对象 | miss → 空串 |
| equipment_graphic | 0x332eec8 | rh4 | 接口 vt@40 + **4 张内联 RH 表 @48/80/112/144**, **stride 72** {hash@0, 步数@4, 键串@8, 值 40B@16}; 键 = **字符串 FNV-1a32** (非 token; 活体直证 armored_car_chassis_5 → hash db11bfe7); 首表 30/39 槽有效 | miss → 空图形@0x143330C78 (48B 壳) |
| ncountry_metadata | 0x332ee70 | stdmap | 节点 120B {键 8B@32, 值 CMetadata 80B@40} | miss → 内嵌默认@db+56 + Null 0x143330DB8 |
| dlc_metadata | 0x332ee98 | stdmap | 节点 304B {键 = DLC id 串@32, 值 CMetadata 240B@64} | miss → TNullObject 0x143339B40 "INVALID_DLC" |
| train_gfx | 0x332f0c0 | slots | 内嵌记录@40 (名 sso + entity@72) + 指针 vec@104 + 双槽位阵 vec@176/@200 (元素 = 内联 24B 嵌套 vec) | — |
| technology_sharing_group | 0x332f098 | rh (token 键) | 接口 vt@40 + RH 表@48, stride 24 {token@8, T*@16}; +80 = 默认模板 CTechnologySharingGroupTemplate* (160B) | 回退默认模板 (推定) |
| script_enum | 0x332f028 | rh (token 键) | RH@64, stride 40 {name token@8, 值 = 内联 pdx vec\<u32\>@16 (枚举成员 token 列)} | miss → 空 vec@40 兜底 |
| scripted_effect_template | 0x332f050 | PR 族 | 扩展 ".txt"@40 / RH map@48 stride24 / 条目 vec@80 (cnt@92) / token vec@104 / reload vec@128; 条目 CScriptedEffectTemplate 128B, 名 sso@+96 | 无 Null (nonull) |
| peace_conference | 0x332efc8 | inline-vecs | 三内联 vec @184/@208/@232; vec@208 元素 192B {id@8, 有效标志@+140} | — |
| project_dynamic_modifier | 0x332eff0 | 标准 | vec@40/cnt@52, 元素即 u32 token (线性扫) | — |
| message_handler | 0x332ef60 | 非内容库 | **消息类型注册表 + 设置处理器** (剧证实证): 类型 vec@64/cnt@76 ([0]=Null), 设置 vec@40, 使能 u8@112 | Null 0x143339E60 / 0x143339E58 |

> 全 22 库共享 `TGameItemDatabase` 骨架 (+0 vt / +8 基类 24B 容器 / +32 dword);
> 挂载槽存指针须先解引用。`idb_count` 对 rh/rh4/umap/chain4 形态按表头取真 count,
> stdmap/vec3/slots/kind8 无单值 count 返 0 (按名 idb_find 取)。

边界语义:

| 项 | 结论 | 证据 |
|---|---|---|
| 越界回退 | idx<1 或 ≥cnt 回退 arr[0] Null Object（多数库="none"） | BHU probe 实拍 |
| nonull 库返回 | nonull 库与 technology[0] 返回 nil | BHU probe 实拍 |
| def 名 token | def 名 token 全为 lexer token; **technology / autonomous_state 两库例外**（名即串） | — |
| item_token 兼容壳 | 仅适用标准族; 现无外部调用者, 建议迁 `idb_token` | — |

#### 4.26.5 补全访问器 API

| 访问器 | 语义 | 备注 |
|---|---|---|
| `idb_token(key, idx)` / `idb_count(key)` | 103 库规格表 (§4.26.4) 统一访问: 库内 idx→def 名 / 真 count (形态感知: rh/umap/chain4 按表头取, stdmap/vec3/slots/kind8 返 0) | 主消费: 定义 cap→真 count 六库 (technology/sub_unit/equipment/building/project/idea) 与对象层; 越界回退 arr[0] Null Object 语义见 §4.26.4 末 |
| `idb_index_of_token(key, tok)` | token→库内 idx 线性反查 (sub_140AC4FA0 同构), 仅 tokN 库 | 命中含 0 (Null Object 槽); 未命中 nil; sso/msvc 系库 nil; 现仅 L1 不变量电池消费 |
| `idreg_unit_resolve(ty, id)` | (type,id)→对象 三源分域: ty>4712→源① 0x3451db0 / ty∈[100,4712]→源② 0x3451db8 / ty<100→源③ 0x3451dc0+8*ty | RH 桶 24B {dist@+4, type@+8, id@+12, obj@+16}; 对象 = raw+16 调整指针 (= CPersistent 子对象, §3.9 谱系定案) |
| `idreg_maxima` | 三源合并 {[type]=max 已分配 id}, 门 type≥4712 且 <9423 且 id>0 | writer sub_14221EF70 填充语义; 消费 session_meta #.id; kr2 实拍 {4713=35724} |
| `mods_registry` / `mods_playset_tails` | mods 管理器 rp(0x344a568): RB 中序 {{name,path}} (head@+176, 名@+72/路径@+136) + 播放集末两段 "a/b" 集 {d@+104, c@+116} | 写序=中序; kr2 实拍 72 注册/5 播放集; 消费 global_tails sec_mods |
| `cde_table` | combat_data_entry 静态表 {data=0x333cb70 (1096B 元), refs=0x333cb88 (u16), count=0x333cbb8} | writer 0X140CDFFF0; kr2 实拍 count=47 |
| `rule_def_flags(i)` | rules 实例槽 i 字节 @+48/+49/+50 | sub_140638A10 拷入 state+64+slot; 值级对拍备用 |
| `M.rb_inorder(head)` | MSVC RB 中序 walker | {_Left@0,_Parent@8,_Right@16,_Isnil@25}; 防御界 1e5 帧 |
| `define(name)` / `define_f(name)` | CDefines 运行时读取（**地址来源 = DLL 侧镜像扫描**, 见 §4.26.5a） | define 返原始 qword; 未知名 nil。**值编码八族** (活体全表对拍定案): fx1e-5 (2110) / 裸 i32 (805) / 裸 i64 (692) / f32 位型 (382) / **fx32k = 定点×32768** (70) / **u8 低字节 bool** (30) / u16 (7) / f64 位型 (1); 同名多命名空间 217 名 (返首个命中)。活体: OUT_OF_SUPPLY_SPEED=-80000 |
| `define_at(name, i)` / `define_targets(name)` | 多命名空间寻址: 第 i 个 (1 起) 存储 / 全部地址数组 | 同 name 注册进多 namespace 时各槽**独立且都有效** (如 FUEL_COST_MULT 双址 0x3332F60=0.35 / 0x3334550=0.10); 按值域选槽 |
| `modifier_category(idx)` | modifier 定义表类属掩码 u32@def+104 | 引擎谓词 sub_14055F700 左操作数, charmgr 块门精确式 `cat==0 or (modifier_category_mask&cat)~=0` 消费 |
| `map_ptr` / `province_state(pid)` / `province_is_land(pid)` | CMap 单例三访问器 | kr2 探针定案; 布局见 §4.26.8 CMap 行; 现无段侧消费 |
| `idb_find(key, name)` | 哈希/内联形态库统一按名取条目 (22 形态外库): 支持 rh / rh4 / umap / stdmap / chain4 / inline / kind8 / 标准指针数组 / **msvc8 (内联@db+48 + 扫描计数)**; token 键库传 token id (keytok) | kr2 活体验收: name(BOL)/name_group(BLR_MAR_01)/power_balance(真实键)/technology_sharing_group(nee_research)/character_template(27139)/occupation_law/scriptable_localization 全中, 负例 nil; 102 key 全量 idb_count+idb_find 无异常 |
| `loc_text(key)` | 本地化文本直查 (当前语言), 未命中 nil | 布局 §4.26.8 本地化行; kr2 活体验收: GER→德意志 / FRA→法兰西 / RECRUIT_OPERATIVE_TITLE→选择招募一名特工 / CANNOT_CHANGE_LEADER_WAR→R-军队正处于边境冲突!, 不存在的 key (SOV@KR 环境) 正确返 nil |
| 库能力分级 (活体) | 102 库三级 | **A 双通 60**（枚举 idb_token + 按名 idb_find, 全 std 族）/ **C 按名型 31**（名在哈希键或值对象内, 不可枚举但按名可取: character_template/scriptable_localization/name/portrait/state/unit_names 等）/ **D 计数 0 11**（aces/ai_strategy/dlc_metadata 等需专读或空库）; 条目计数总和 29,377 |
| `terrain_lut(byte)` / `province_terrain_name(pid)` | terrain 库 LUT 与省地形双读 | 布局 §4.26.8 CTerrainDatabase 扩展行 / §4.14.3 省静态描述符; 无参 terrain_lut()=LUT count; 三侧对账 (`terrain_l2.py`) 四项全 MATCH: 落盘序≡运行时序 25/25 / 第二数组⊆磁盘 / **LUT↔color 同余 25/25** / type 回链⊆categories; 活体 32 类, 省 1=lakes 22=mountain 3953=plains |

段侧消费普查（全文 grep mod lua）—— 段/reader 实际调用面:

| 访问器 | 消费点 |
|---|---|
| `token_name` | 17 处全段面（段内经 `SV2.lib.tok` 兜底包装） |
| `idb_count` / `idb_token` | 对象层 + 角色管理器 |
| `modifier_token` | 4 处（含 global_tails） |
| `modifier_count` / `modifier_category` / `modifier_category_mask` | 角色管理器 charmgr 门 |
| `idreg_unit_resolve` | global_tails 3 处 |
| `idreg_maxima` | session_meta |
| `mods_registry` / `mods_playset_tails` | global_tails sec_mods |
| `cde_table` | combat_data_entry |
| `rule_key` / `set_name` / `rb_inorder` / `rh_iter` | 各 1-3 处 |

> 现无段侧消费（探针/验证备用，删前须再普查）: `map_ptr`/`province_state`/
> `province_is_land`、`define`/`define_f`、`rule_def_flags`、`idb_index_of_token`
> (仅 verify)、`item_token` (兼容壳, §4.26.4 末)、`set_count`。

#### 4.26.5a CDefines 地址复原: DLL 侧镜像扫描

`M.define` 的 name→地址表**不来自任何数据文件**, 而是进程内一次性扫像复原: 引擎注册每个 define 时发射固定四指令序列, 名字与目标地址都是编译期常量, 故该表烙在 `.text` 字节里。

| 项 | 内容 |
|---|---|
| 扫描签名 | `lea r8,[目标全局]` `lea rdx,[名字串]` `lea rcx,[rsp+n]` `call 装载器` = 字节 `4c 8d 05 <d32> 48 8d 15 <d32> 48 8d 4c 24 <n> e8 <rel32>` |
| 名字取值 | `lea rdx` 的 disp32 指向 `.rdata` 内**裸名字串** (NUL 结尾) |
| 目标取值 | `lea r8` 的 disp32 指向 `.data` 内该 define 的存储槽 (RVA = 返回值; 调用方加 `hoi4.base()`) |
| 护栏 (关键) | 仅当名字出现在装载器诊断串 `Error reading "NAME"` 的**引号内**才收。该串整条形如 `Error reading "NAME": no lua object named NAI\n` — **必须读到闭引号为止**, 读整条 C 串会因尾部 `: ...\n` 不可打印而全军覆没 (guard 集空 → 拒绝猜) |
| 扫描范围 | 仅 `.text` (1.19.3 = 39 MB); 实测命中区间仅 ~2.25 MB / 36 页, 全扫 ~0.07 s |
| 跨版本 | 地址随版本变, 但**签名与护栏不变** → 无需任何重生成步骤; 这正是取代离线表的原因 |

> 扫描结果 (1.19.3): **4,422 名**, 与离线基线 `ref/defines_map_1193.txt` 比对 miss=0 (基线 4,424 名中 2 名未复现), 15 处地址差**全部**是多命名空间取槽不同 (两址都有效, 值域可判), 另 18 个 name 为离线扫描器漏收的真 define。

#### 4.26.6 具名防御界与结构维度 (M.lim / M.dim)

| 表 | 内容 | 证据口径 |
|---|---|---|
| M.lim | PTR_SANE=4096 / PTR_HUGE=65536 / FIXED_SMALL=64 | 防御惯例（内容列表防垃圾指针; 64 级仅 writer 明文有界或固定槽） |
| M.dim | EXTERNAL_RULES=28 / RULE_OVERRIDES=28 / LOGISTICS_SLOTS=19 / HISTORY_QUEUES=3 / AI_STRATEGY_SLOTS=112 / MODIFIER_HOURS=30 | **只收定案**，逐项标 [二进制]/[惯例] 出处 |

核验范例:

| 案例 | 结论 | 证据 |
|---|---|---|
| RULE_OVERRIDES=28 | writer 明文常量 | sub_1406386B0 字面枚举 28 flag + 28 容器（进入 0x14063C690; ⚠ 旧址 sub_140D2DB40 = CRelationStatus writer, 清偿批勘误）; CRuleOverrides 定长 [+808,+2496) 无 count |
| PORTRAITS 上限 | 结构上限 = 6 分支×2 尺寸 = 12（插入按键去重覆盖）; 16 纯防御 | 0X14139E9C0 |
| NTT unit 列表行数 | 真值 = 容器 count@T+68 | writer 0X140E28F40 无明文常量 |

> 队列行数等运行时真值一律读对象自身字段，勿造字面量。

#### 4.26.7 离线 dump 资产 (python/agent 侧, 非运行时)

| 资产 | 内容 | 状态 |
|---|---|---|
| `ref/token_table_1193.txt` | 静态 token 全表 10,765 条 (id 11..19998) | 现役 (离线, exe 提取) |
| `ref/token_map_1193.txt` | 10,765 条, 提取注册函数 sub_1400831C0 (含 entry/idglob/caller 溯源列) | session_meta 数据源 |
| defines 旧版映射 (1.19.2 期, 已废) | CDefines 3,592 唯一名 = 2,236 定点×1e5 + 1,356 裸 i32, **双 loader** sub_142072500/B690, 20 重名=双命名空间 | 历史版 |
| `ref/defines_map_1193.txt` | **4,424 名 / 4,452 目** / 25 多义名（全 loader 族扫描; 形态含 `(float *)&`/`(bool *)&` cast 与无 `&` 全局; 护栏 = 调用点后 1.5KB 内有 `Error reading "NAME"` 诊断串） | **冻结基线**（1.19.3 离线快照, 无再生配方; 运行时数据源已改为镜像扫描, 见 §4.26.5a） |
| `ref/serfam_1193.txt` | 1,153 行 CPersistent 族指纹表 (slot1=Save wrapper 判定; 盲区见 §4.00.1/方法论) | 现役 (可序列化性速查) |
| `ref/boot_registry.tsv` | 320 槽 boot 注册表 (槽位/ctor 签名/库分级; §4.26.8 数据源) | 现役 |
| `ref/vt_rtti.json` | 9,254 vtable→RTTI 类名 | 版本变更需重扫 |
| `ref/rtti_hierarchy.json` | 8,755 类继承谱系 (**仅 mdisp/基链可用**) | ⚠ **该文件的 vt 地址字段 = 1.19.2 旧值, 禁作地址用** — 取 vtable 一律 `vt_rtti.json` 或 exe 直读 (旧值与 1.19.3 实测址处为 RTTI 数据, 非代码槽) |
| `ref/hoi4_runtime_classes_map.json` | 8,755 类 → 运行时信息合并视图 (实 vftable 地址 + COL 层 vt/mdisp + CPersistent 族 writer/reader/slots); 8,634 类有 vftable, 1,148 类带 writer/reader | 合并产物 (派生自上述三表; 版本变更需重生成) |
| `ref/hoi4_runtime_vt2class.json` | 9,259 条 vftable 地址 → 类名 (按地址排序) | 探针逆向替换表 (读对象首 qword 直查类名) |

#### 4.26.8 普查登记补遗 (未入 idb 规格表的注册表)

| 项 | 挂载 | 要点 |
|---|---|---|
| CFactionIconsDatabase | qword_14332EEE8 | 阵营图标库 {data@+80, count@+92}; GUI 消费 = CFactionIconItem 图标行 (§4.31.31) |
| CMap (省→州/海陆/描述符) | `rp(BASE+53714216)` (0x840B) | +40 省→州 **i16 数组指针** (0=海/无州); +568 省非海序 **u32 数组指针** (0xFFFFFFFF=海); +616 省静态描述符 **8B 指针数组** {data@+616, cap@+624, cnt@+628} (元素 = 描述符*; id@desc+196, bbox@desc+136..148); +560=省表界 (=gs+700=max 省 id+1), +564=陆省数 (kr2 13907/10771 三读互证); 访问器 `M.map_ptr`/`province_state`/`province_is_land`/`province_terrain_name` |
| 本地化运行时管理器 | `rp(BASE+56336440)` | **定案** (sub_14239ED90/sub_14239C290 + 活体双证): **mgr+0 = 当前语言 texts 对象** {+32 = 有序 16B 索引 {u64 fnv1_64(key)@0, i32 值偏移@+8} 二分查找, cnt u32@+44 (kr2 英 280,475)}; **mgr+32 = 全局串 blob 数据指针** (blob+0 直指串数据; cap u32@mgr+40 / used u32@mgr+44, 量级数十 MB), 内容 = "key\0value\0" 紧邻对, 索引值偏移指向值 (key 在值前 -#key-1 处, 冲突确认用); mgr+8 = 10 语言注册条目向量 (cnt@+20, 104B 元 {名 SSO@0, 三容器}) 为装载侧脚手架非运行时查询路径; FNV-1 64 (seed 0xCBF29CE484222325, 素数 0x100000001B3); 访问器 `M.loc_text(key)` (命中级; ⚠ 文本须 read_cstr — read_str 对 UTF-8 长串返 nil) |
| CEventDatabase | 0x3339c20 (0xE0) | events/ 递归装载; namespace 无独立表（串字段+解析侧） |
| CTerrainDatabase 扩展 | 0x332f0a8 | **第二数组 {arr@+112, cnt@+124} = 图形地形类别** (名 `terrain_N`/`desert_hills`/`forest_13`/`mountain_variation_*`, 与 A 族 arr@64/cnt@76 的**游戏性**地形 `mountain`/`forest`/`plains` 分属两套); **类别→DB LUT int[]@+136 / cnt@+148** (位图字节 → 第二数组下标; <1 或 ≥cnt@+124 → Null Object); 省地形位图 obj+368 {宽@+8, 高@+12, 步长@+16, 行距@+28, data@+40} byte=类别; 消费 sub_141652F90 (地图渲染/混合, a2=GAMESTATE, 位图宿主 = 渲染对象 `*(a1+40)`); 访问器 `M.terrain_lut(byte)`/`M.province_terrain_name(pid)` (desc+168 → def 名 SSO@+24, 游戏性名空间); **磁盘侧链路直证** (`common/terrain/*.txt` terrain 块每条 = `{ type = <游戏性名>, color = { <位图字节> }, texture = N }`): 位图字节 → LUT → 第二数组 idx → 条目 → type = 游戏性 terrain, 全链四段活体对拍 MATCH; ⚠ 同游戏性类型多色变体 = 同名多条目 (desert×3 / jungle_blend_18×2), 解析须保落盘序不折叠; **CTerrain def 侧**: def+16 = 有效旗 u8, def+140 = 位掩码位 u32 (has_terrain 载荷消费; 推定); **def+136 = A 族下标** (CEquipmentBonus attrition reader 实证, equipmentbonus.cpp:274); **def+8 = 存档 lexer token** (attrition 发射键, 与 +24 sso 名并行两通道) |
| 成就单例 | `rp(BASE+53575824)` (0xA8B) | 门 = qword@sing+8 非零; RB 树@sing+0; 节点键 MSVC@+32; 条目 vector {begin@+64, count@+76}; 解锁门 u8@+33, 名 MSVC@+40; 块 writer 0X1401F27F0; 复原流程 sub_14061DCB0 |
| ai_focus 静态枚举 | token 13447-13454 (+13820) | 8+1 固定 focus 非表; country.ai 合法性门 |
| unit_leader 特质库 | 0x332f0d0 | trait NullObject 0xA90 全字段 |
| 勋章库 | 0x332f0c8 | medal 名串 def+24（writer 同源, 免 token 反查）; 单例槽 = **BSS 零初始化堆指针槽** (boot_registry: 88B / ctor sub_140AE1830 / creator sub_140173F00), 载 `common/unit_medals` (loader 0x14018B960, 调用点 = 内容注册总入口 sub_14018BB20); 运行期由 creator 建堆单例 |
| MIO org 名解析闭环 | 0x332ef48 | token@+56 创建时拷 org+64（运行时读 +96/+128 不变） |
| 内容注册总入口 | sub_14018BB20 | 登记三元组 = malloc(size)→ctor→store 0x1433xxxxx 槽; 离线产线产 `ref/boot_registry.tsv` (320 槽, boot 链内 169 = 全库宇宙, 带 ctor 54; 103 key 规格表命中 101, 未中 2 = `name` 库 store 形态为 `*(_QWORD *)&slot =` 不匹配扫描正则 (19 引用手证槽在) + `entry` 伪槽 RVA 0x170 非库地址); 创建习语三形态 (内联/独立 creator/工厂·shared_ptr·自登记), 版本迁移按槽位+ctor 签名 join |
| Null Object 哨兵 | 38 个 | arr[0] 身份校验锚; gs 双 vtable@+0/+8, ctor 0X1401BF930; reload 总线头 off_143085170 = gs+2592 与新库壳+96 共用 |
| script_enum_equipment_bonus_type 注册库 | 0x332EED0 | vec ptrs@+96 / cnt@+108 / 项 token@+8 (CSpecificEquipmentBonus Load 校验铁证, 缺项报错由 token 10987 给出); 装备加成类型 script enum 注册; **候选 idb 新挂 key** (未入 103 键) |
| COnActionDataBase | TGameItemDatabase 形态 (ctor 直证: 桶@+8/+16, count@+32, hash 向量@+40) | on_action 静态库; **非 CPersistent** 无 serfam 指纹, savegame 负定案定案 |
| CMapArrowManager 定义库 (地图箭头/符号) | `LoadDefinitions<CMapArrowManager>` 链 (与 §4.00 CFileWatcher 行同源) | 4 成员定义件均为 CPersistent 9 槽标准壳、**writer = CFG 空桩 (只装不存)**: CMapArrowDefinition (vt 0x1429A6348, reader 0x14126A800; loader 组合 Button/Text 子件) / CMapArrowButtonDefinition (vt 0x1429A62F8, reader 0x14126A680; tok 27/76/225/13075/15784 → 串入 +8/+40/+80/+84) / CMapArrowTextDefinition (vt 0x1429A62A8, reader 0x14126AD90; tok 30/89/11861 三串) / CMapSymbolDefinition (vt 0x142A3FD28, reader 0x141B1FA40; tok 27/47/143/415/11861 + +112 内嵌 STextDef 子类) |
| graphical_culture 库 Null 哨兵 | CNullGraphicalCultureType (vt 0x14293C058 11 槽) | CPersistent 族但 writer 空桩、reader 复用基 0x1424BEC40; 槽[9] 0x14067D3E0 只回吐内嵌名串 — 与 CNullAI*DatabaseEntry 同形态 |

**CNull\* 空对象族机制 (定案)**: `CNull<真类>` = **外壳对象 (Null 虚表) + 内部真实控件对象 (独立 malloc, 尺寸 = 真类 ctor 尺寸)**, 并把 `TNullGuiObjectTrait<CNull<真类>>` 作为**尾基子对象**挂进外壳 (RTTI mdisp 即 trait 偏移)。ctor 统一形: `v = malloc(真类尺寸); v = 真类 ctor(v, …); 外壳初始化(内层 v); 外壳 vtable ← CNull<真类>; 外壳 vftable 双写 (+0/+…); 外壳[trait_mdisp] = &TNullGuiObjectTrait<…>;` → **语义 = 「接口非空但行为全空」的兜底控件**, 由 GUI 查型失败路径返回; 无独立状态、无 RTTI 新族、非 CPersistent。**负定案**: 该族**不需要逐类字段表** — 状态全在真类对象内, Null 外壳仅换表 + 挂 trait; 族级信息即下表。

| 类 | 主 vt | ctor | 内层 malloc | trait mdisp |
|---|---|---|---|---|
| CNullButtonStandard | 0x142B54788 (+次 0x142B54B38) | 0x142377F10 | 0x378 (888) | 528 |
| CNullCheckBox | 0x142B55320 (+次 0x142B555B0) | 0x142378120 | 0x378 (888) | 472 |
| CNullDropDownBox | 0x142B57588 | 0x1423783A0 | 0x150 (336) | 2848 |
| CNullEditBox | 0x142B558B0 (+次 0x142B55B40) | 0x142378440 | 0x180 (384) | 632 |
| CNullExtendedScrollbar | 0x142B571F0 (+次 0x142B57470 / 0x142B57500) | 0x142378500 | 0x1F8 (504) | 5664 |
| CNullButtonDrag | 0x142B54B80 (+次 0x142B54F08) | 0x142377D50 | 0x378 (888) | — |
| CNullBrowser | 0x142B555F8 | 0x142377CA0 | 0x130 (304) | — |
| CNullInstantTextBox | 0x142B55BD8 | 0x142378750 | 0x1D0 (464) | — |
| CNullIcon | 0x142B55EA0 (+次 0x142B56258) | 0x1423785B0 | 0x140 (320) | — |
| CNullContainerWindow | 0x142B562A0 (+次 0x142B56518) | 0x142378300 | 0x598 (1432) | — |
| CNullSmoothListBox | 0x142B56E48 (+次 0x142B56F40) | 0x142378A50 | 0x268 (616) | — |
| CNullStandardGridBox | 0x142B567B8 | 0x142378C70 | 0x1D0 (464) | — |
| CNullStandardListBox | 0x142B56A78 (+次 0x142B56BA8) | 0x142378D10 | 0x268 (616) | — |
| CNullTrack | 0x142B54F50 (+次 0x142B552D8) | 0x142378F20 | 0x378 (888) | — |
| CNullOverlappingElementsBox | 0x142B57828 | 0x142378940 | 0x130 (304) | — |
| CNullGraphicalObject | 0x142B58358 | 0x14011A310 (静态初始化) | — | — |
| CNullKeyBoard | 0x142B3C978 (+次 0x142B3C9C8) | 0x142230E80 | (共用基 ctor) | — |
| CNullTouchDevice | 0x142B3C798 | 0x142230E80 | — | — |
| CNullIdler | 0x142B41808 | 0x142297F70 | — | — |

> 非 GUI 同族旁证 (同 TNullObject 模式): `CNullSavedEventTarget` (0x1427BDF68, 基 `CSavedEventTarget`+`CPersistent`) / `CNullAIEquipmentRoleDatabaseEntry` (0x1427DFA70, 448B) / `CNullAIAttitude` (0x1427E0768) / `CNullAIRoleDatabaseEntry` (0x1427E0A40) / `CNullAIStrategyPlanDatabaseEntry` (0x1427E1A00) / `CNullAIFocusDatabaseEntry` (0x1427E21D8) / `CNullCombatTactic` (0x1427E6588) / `CNullCustomMapMode` (0x1427EAA78) / `CNullAIEquipmentDesignEntry` (0x1429C71F0) / `CNullAITemplateEntry` (0x1429C7A38) / `CNullSysInfo` (0x142B51610) / `CNullMouse` (0x142B3C9F0 等 5 表) / `CNullLogger` (0x142B91D40)。

负结论（停止寻找）:

| 项 | 结论 | 证据 |
|---|---|---|
| 军衔名 | 无注册表 | 无 ranks 目录/RankDatabase, 走 localization |
| 天气 | 无独立运行时注册表 | 编译期 enum |
| 补给 | 无独立省注册表 | hub=省建筑 supply_node, 摩托化等级 50000/100000 内联 0X14194D5F0, 基数 = define SUPPLY_HUB_FULL_MOTORIZATION_TRUCK_COST |

#### 4.26.9 验证体系

| 层 | 工具 | 覆盖 | 基线 (KR2) |
|---|---|---|---|
| L1 不变量电池 (实现侧校验脚本, 非本节数据) | 逐库不变量 | 81 key 逐库: count 恒等式（cnt@76==lookup.size@52+1, 显式标准族）/名字净度（控制字节）/token 有效域/双向 roundtrip/Null 语义 | 80 绿 + gamerules 特形豁免; building 恒等式分歧=信息级 |
| L2 内容文件对账 | `staticres_l2.py`（replace_path 感知层叠） | 32 库映射: 25 名字级 + 4 计数级（ability/ai_area/focus_inlay_window/scripted_diplomatic_action）+ 3 跨库名白名单 | **29 MATCH / 3 SKIP / 0 DIFF**（SKIP: ai_strategy 无访问器 / country_scorer 引擎按需注册 9/19 / gamerules 选项值库） |
| L2c 顺序对账 | 探针（可升格） | 引擎保留文件定义序（文件字母序×文件内序）: state_category 18 名逐位一致; building/opinion_modifier 序一致仅差 *_spawn 伪条目 | 可行，未自动化 |
| L2d lookup 哈希自洽 | `staticres_lookup_probe.lua` | lookup{MSVC@+0, hash u32@+32} 逐条 fnv(lower(name))==hash + lookup↔arr 名集 | 5 库全绿（含 country_leader 2222 条） |

- **必跑时机**: 游戏版本变更、resource.lua 规格表改动、新库挂 key。
- 报告/枚举输出至 mod 侧 tools 目录。
- 对账深化方向（未决）: L2e 字段级值对账（需逐库 def 对象布局 RE，建议只对
  有消费者库做）；存档引用对账（save 引用 token ⊆ 库名集）。

#### 4.26.10 CTweakable 调试值控件族 (引擎活体调参系统)

管理器双单例 (定案):

| 项 | 值 |
|---|---|
| 名桶注册表 | 懒建单例 qword_1435E1A90 (0x40B: +8 桶数组基址, +48 mask 初值 7 = 8 桶起步, +0 float 1.0); getter sub_1424B84D0 |
| 插序向量 | 懒建单例 qword_1435E1A88 (24B Pdx 向量); getter sub_1424B8620 |
| 注册入口 | sub_1424B6990(obj): +40 键名 FNV-1 (basis 0x811C9DC5, prime 0x01000193) → hash&mask 入桶链 (节点 {+8 next, +16 名串 32B, +48 值串}); **重名调新对象槽[2] SetValue(旧值) = 热迁移**; 再 push 插序向量 |

**CTweakable** 基类 (152B, vt 0x142B911B0 4 槽; 槽 [1] 值串化 / [2] SetValue / [3] GetType):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | fn ptr | apply/format 回调 (out, input, self) | Bool/Float/Int/Alias 各有具名变体 |
| +16 | qword | 附加上下文 1 | 保留槽 (ctor 置零, 无第二写点 — 负定案) |
| +24 | CClass* | 回调上下文 = **引擎变量指针** | 回调内解引用写值 |
| +32 | qword | 附加上下文 2 | 保留槽 (ctor 置零, 无第二写点 — 负定案) |
| +40 | string | 注册键名 | FNV-1 输入 |
| +72 | string | 显示名 | |
| +104 | string | 描述串 | 推定 |
| +136 | int | **注册期类别 id** (ctor 形参直落, 非运行期计算; 样例恒 1 = 该类唯一注册值) | 高置信 |
| +144 | CClass* | **SetValue 读写目标 = 引擎变量指针** | |

typed 派生 (布局同基类, 只覆写三值槽):

| 类 | vtable | SetValue 语义 | GetType | sizeof |
|---|---|---|---|---|
| CTweakableBool | 0x142B91228 | "0"/"false"/"no"=假, 其余=真, 写 +144; 回调空输入=翻转 | 0 | 152 |
| CTweakableFloat | 0x142B91200 | atof 写 +144; **+152/+156 = min/max (推定)** | 1 | 160 |
| CTweakableInt | 0x142B91250 | atoi 写 +144 | 2 | 160 |
| CAliasString | 0x142B911D8 | 串值型 tweak | 3 | 152 |

行控件 11 类 (CTweakerListItem 主表@0 + TListboxItem 次表@56, 各 14 槽, [13]=业务槽):

| 类 | vtable | GUI 工厂名 | 自有字段 (+152 起) | sizeof |
|---|---|---|---|---|
| CTweakableTitle | 0x142AF9C48 | tweaker_titlecomponent | +152 标题串 | 184 |
| CTweakableLabel | 0x142AF9D88 | tweaker_labelcomponent | +152 标签子件 | 168 |
| CTweakableCategory | 0x142AFA0D8 | tweaker_collapsable | +152 类目名 / +232 展开旗 / +256 折叠钮 glue | — |
| CTweakableBoolManipulator | 0x142AFAA78 | tweaker_boolcomponent | +168 勾选钮 glue | — |
| CTweakableIntManipulator | 0x142AFA8D0 | tweaker_slidercomponent | +152 滑条 / +160 回写 glue / +272 目标 | — |
| CTweakableDropDown | 0x142AF9F30 | tweaker_dropdown | +184 目标 / +240 下拉列表 / +248 变量指针副本 | ≫1.5K |
| CTweakableEnumManipulator | 0x142AFA558 | tweaker_listcomponent | +168 目标 / +176 索引哨兵 -1 / +184 选项向量 | — |
| CTweakableGraphManipulator | 0x142AFA3B0 | tweaker_graphcomponent | +152 图子件 / +160 目标 | — |
| CTweakableArrayCurveManipulator | 0x142AFA758 | tweaker_curvearraycomponent | +152 目标 / +392/+400 变量指针与上下文副本 | — |
| CTweakableTextbox | 0x142AFADB8 | tweaker_textboxcomponent | +168 目标缓冲 / +176 编辑串 | — |
| CTweakableCharArrayManipulator | 0x142AFA270 | tweaker_textboxcomponent_long | +152 定长 / +336 目标 | — |

> **活体验证（test1 会话实测）**: 双单例遍历走通、节点名 MSVC 读法逐字命中；侧发现该注册表实为**引擎级通用名值表**，launcher 参数名（http/auto_run/start_save）与脚本 tweak 共表注册。
> **对象句柄路径（清偿定案）**: 节点存值不存对象 = 设计事实；**插序向量 qword_1435E1A88 元素即 CTweakable\***（静态 v20[count]=a1 铁证; 运行时 61 对象 = 60 Bool+1 Int, +144 引擎变量指针全非空）；名→对象 = sub_1424B8380 对向量线性名扫（不经桶）；round-trip = 文件值→桶节点值串→按名扫向量→SetValue（载入向闭合, 活体 SetValue FLIP/RESTORE 实测）; **SetValue 只写引擎变量 (obj+144 所指), 不创建不刷新桶节点 = 单向镜像**（写出走遍历插序向量的持久化 writer, 与 SetValue 无关）。
> **桶链细勘（定案）**: 桶数组 16B/槽存首/末节点对; 空桶槽存**外部堆哨兵**地址; 链经哨兵成环（朴素遍历无哨兵判等会无限计数）; **权威节点数 = 表+16 count 字段**; 桶节点唯一写入源 = argv `name=value` 参数注册循环（sub_14207DB70 → sub_14207D560, call site 0x14209E610/0x140126E50）。
> ⚠ **桶节点数与对象数不可比（口径纪律）**: 桶 = 会话期被设值过的参数名值镜像（实测仅 3 个 launcher 参数, 无一对应活对象）; 61 = 编译期固化注册对象数; 「134 vs 61」类样本 = 双表口径差 + 链走过计数叠加（样本本体不可复现, 待裁）。

> GUI 工厂注册锚: ArrayCurve→0x142071040 / DropDown→0x142072650 /
> EnumManipulator→0x142072DC0, 挂全局 0x143316920 名→工厂槽。

#### 4.26.11 建筑/州类目/自治档/占领修正/抵抗活动 def 布局 (元素类实名绑定)

idb 四库 + building 库的元素 def 布局 (全部 vt[2]=空桩 = 只读 def 不入档; 库挂载状态 = §4.26.4 已挂)。

**CBuildingTemplate** (buildings.txt 建筑 def, ≥1216B; vt 0x1427E4260; reader 0x1414BB530 ~80 键; 校验器 vt[7]=0x1414BAB90; 元素库 = building key 0x332EE28):

| 偏移 | 类型 | 键 (token) | 备注 |
|---|---|---|---|
| +8 | u32 | — | db 注册 id (dword; 名另见 +528 loc 串) |
| +40 | 匿名结构 (16B 形状) 向量 | tags (463) — {d@40, c@52}; **元素 = 4B token 值** (活体定案: naval_base → token **31210 `naval_buildings_tag`**; supply_node 同 c=1) | 块 |
| +64 | 匿名结构 (NNB 形状) | country_modifiers (11577) | 块 |
| +288 | 匿名结构 (NNB 形状) | state_modifiers (16619) | 块 (校验: 项须州修正) |
| +504 | 匿名结构 (16B 形状) 向量 | local_resources_* 前缀 | {d@504,c@516} 16B 元 {资源 def id u32, i64 量} |
| +528 | MSVC 串 | — | 本地化键 |
| +560 | MSVC 串 | — | 大写 loc |
| +592 | 匿名结构 (NNB 形状) | missing_tech_loc (18024) | 块 |
| +664 | 匿名结构 (NNB 形状) | specialization (10012) | 块 |
| +688 | 匿名结构 (NNB 形状) | level_cap (10768) | 块; 块内 +700 = 省限 |
| +740 | i64 | icon_frame (12120) | |
| +744 | i64 | base_cost (12094) | |
| +748 | i64 | base_cost_conversion (13606) | |
| +756 | i64 | per_level_extra_cost (14126) | |
| +760 | i64 | naval_production (12123) | |
| +764 | i64 | military_production (12124) | |
| +768 | i64 | general_production (12125) | |
| +772 | i64 | naval_fort (12553) | |
| +776 | i64 | land_fort (12554) | |
| +780 | i64 | rocket_production (12979) | |
| +784 | i64 | rocket_launch_capacity (13298) | |
| +788 | i64 | air_defence (11958) | |
| +796 | u32 | show_on_map_meshes (12182) | 默认 1 |
| +800 | u8/u16 | has_destroyed_mesh (13752) | |
| +801 | u8 | disable_grow_animation (10046) | |
| +802 | u8 | only_display_if_exists (16642) | |
| +808 | MSVC 串 | special_icon (16643) | |
| +840 | i64 fixed | damage_factor (13163) | 默认 100000 |
| +848 | i64 fixed | repair_speed_factor (15662) | 默认 100000 |
| +856 | i64 | value (776) | |
| +864 | u8 | is_buildable (11938) | 默认 1 |
| +865 | u8 | is_port (12113) | |
| +866 | u8 | infrastructure (12203) | |
| +867 | u8 | air_base (12214) | |
| +868 | u8 | radar (12237) | |
| +869 | u8 | anti_air (12166) | |
| +870 | u8 | only_costal (12096) | |
| +871 | u8 | **`refinery` (12978)** — 磁盘直证 `common/buildings/00_buildings.txt` 的 `synthetic_refinery = { refinery = yes }` | 定案 |
| +872 | u8 | nuclear_reactor (12980) | |
| +873 | u8 | disabled_in_dmz (13354) | |
| +874 | u8 | always_shown (13566) | |
| +875 | u8 | disable_auto_nudging (17431) | |
| +876 | u8 | infrastructure_construction_effect (14249) | |
| +877 | u8 | show_modifier (15314) | |
| +878 | u8 | fuel_silo (15503) | |
| +879 | u8 | centered (19886) | |
| +880 | u8 | supply_node (19646) | |
| +881 | u8 | allied_build (10187) | |
| +882 | u8 | need_supply (10578) | 校验串: 仅省建筑可用 |
| +883 | u8 | (10071 inherit) | |
| +884 | u8 | need_detection (19201) | |
| +885 | u8 | naval_headquarter (10193) | |
| +886 | u8 | naval_supply_hub (10194) | |
| +887 | u8 | (10352 键, 原版表无 — 推定 DLC/新键) | |
| +888 | u8 | affects_energy (16533) | |
| +892 | u32 | detecting_intel_type (19532) | |
| +976 | 匿名结构 (元素待裁) 向量 | state_damage_modifier (10031) 族之一 (province_damage_modifiers 10029→+976 静态修正表) | "Could not find static modifier" 直证 |
| +1000 | 匿名结构 (元素待裁) 向量 | state_damage_modifier (10031) | |
| +1048 | 匿名结构 (元素待裁) 向量 | modules (15211) | |
| +1088 | 内嵌 CConstructionSpeedFactor | construction_speed_factor (16385) | ≥108B: +8 factor(10603) / +16 trigger(10595) 子对象 / +36 trigger 存在旗 (mandatory); vt 0x1429CB628 |
| +1204 | u8 | hide_if_missing_tech (17942) | |
| +1208 | CModifier | dlc_allowed (17943) | CModifier 族名单 |

**CStateCategory** (state_category def; vt 0x1429BA8D0; reader 0x1413C4D50; 库单例 0x332F968): +8 名 token hash / +24 MSVC 名串 / +64 CColor 子对象 (color 86; 注册进 CState 库色池, **+324 = 色池索引**) / +96 内嵌 CModifier (其余键如 local_building_slots 全落此) / +184 本地化名 / +316 float 0.9。

**CAutonomousState** (自治档 def; vt 0x1427E3770; reader 0x140678D40): +8 名 MSVC 串 / +40 FNV-1a32 hash / +424 loc 描述串; 脚本键: default(11405)→+45 / is_puppet(13416)→+46 / use_overlord_color(19107)→+44 / allowed(12263)→+48 块 / modifier(10597)→+336 块 / rule(10876)→+528 块 / can_take_level(14118)→+136 / can_lose_level(14119)→+224 / min_freedom_level(14058)→+193 / cost(10323)→+195 / manpower_influence(15148)→+194 / peace_conference_initial_freedom(15406)→+196 / ai_subject_wants_higher(14121)→+197 块 / ai_overlord_wants_lower(14122)→+204 块 / ai_overlord_wants_garrison(14188)→+1688 / allowed_levels_filter(15403)→+312 名单 / use_for_peace_conference_weight(15407)→+1776 i64 (×100000 缩放)。

**COccupationModifier** (占领修正 def, 0x340 级; vt 0x1429BA640; reader 0x1413C3290): +8 def id / +16 名 / +48 tooltip(146) / +80 icon(181) / +128 small_icon(19032) / +176 type(225) 枚 (默认 4=invalid) / +184 threshold(695) / +192 margin(630) / +200 alert_level(19364) 三档枚 / +208 alert_margin(19369) 默认 1000000 / +216 visible(11562) 块 / +304 enabled(705) 块 / +392 on_enable(15738) 块 / +480 on_disable(15739) 块 / +568 内嵌 CModifier state_modifier(15741) / +760 is_dynamic(10445)。

**CResistanceActivity** (抵抗活动 def, 912B; vt 0x142941280; reader 0x140AA1060): +8 名 / +40 available(12264) 触发器块 88B / +128 weight(593) 数值提供子 56B / +184 effect(89) 块 / +272 内嵌 CModifier state_modifier(15741) / +360 本地化串 / +464 max_amount(409) 208B / +672 duration(109) 208B / +880 alert_text(19039)。

**CBuildingSpawnPoint** (建筑地图生成锚点, 名录; vt 0x1427E42C0; reader 0x1414DF9B0): +17 is_port(12113) / +18 only_costal(12096) / +19 centered(19886) / **+20 max (676, i32)** / **+24 show_on_map_meshes (12182, i32)** / +28 type(225) 枚 1=province/0=state / +32 disable_auto_nudging(17431)。**无 x/y 字段** (旧「推定 x/y」系误读, 撤销)。

**国策/理念 def 周边 (1.19.3 实名)**: CNationalFocusDependency (国策依赖条, 72B, vt 0x142739AC8, 键 or/focus 均落 +32 名串; writer 桩不落盘) / CNationalFocusStyleDatabase (focus style 双 RH 名表 = 内嵌 CNationalFocusDatabase+48 起 160B, 骨架不合 idb 不可挂) — 详 §4.8.12。


**CScriptedDiplomaticActionTemplate** (scripted_diplomatic_actions/*.txt def, ~1888B; vt 0x142942828; writer = CFG 空桩不入档; parser 0x140AB3F60; idb scripted_diplomatic_action 已挂 0x332F048, 实例侧 CScriptedDiplomaticAction def@+120 指向本类): +8 名 token / +16 名 MSVC 串 / +48 requires_acceptance (15456) / +56 visible (11562) 触发块 / +144 allowed (12263) / +232 can_be_sent (15465) / +320 can_be_accepted (15464) / +408 selectable (15474) / +496 send_scripted_gui (15452) / +504 receive_scripted_gui (15451) / +512 ai_desire (15455) / +568 ai_acceptance 表 (15454) / +592 icon (181) 内嵌 208B / +800 cost (10323) 同形 / +1008 command_power (14467) 同形 / +1216 cost_string (15453) / +1248 show_acceptance_on_action_button (15462) / +1256 reset_send_effect (15463) / +1344 reset_receive_effect (15450) / +1432 complete_effect (14341) / +1520 reject_effect (15604) / +1608 on_sent_effect (15605) / +1696 send_description (15449) / +1728 receive_description (15448) / +1760 accept_title (15444) / +1792 accept_description (15445) / +1824 reject_title (15446) / +1856 reject_description (15447)。**88B 块类名定案**: 5 个条件块 (+56/+144/+232/+320/+408) = 内联 **`CAndTrigger`** (ctor 0x140549F40); 4 个效果块 (+1256/+1432/+1520/+1608) = 内联 **`CEffect`** (ctor 0x14053CFD0); 模板 ctor 0x140AB0C40 逐槽调, reader 0x140AB3F60 对应 case 走 `(*(vt+40))` CTrigger Load wrapper / `(*(vt+24))` CEffect Load wrapper。


**COpinionModifier** (common/opinion_modifiers/*.txt 静态定义条, 128B; vt 0x14293F6D8; writer = CFG 空桩不入档; reader 0x140A822B0; ctor 0x140A801F0; idb opinion_modifier 已挂 0x332EFC0): +8 条名 token / +16 u8 THasNullObject 有效旗 (真条=1/Null=0) / +24 名串 32B (target=1 时 reader 改写 "<名>_target") / +56 名串副本 / +88 db 键 u32 / +96 db 序号 / **+104 i64 decay / +112 i16 value / +114 i16 min_trust / +116 i16 max_trust / +118 i16 存续天数** (10604 months×30 / 10605 days / 10606 years×365 三键汇入; 默认 -1 永久) / +120 u8 target 旗 / +121 u8 trade 旗。TNullObject 单例 qword_143339EB8。存档 `opinion_modifier={...}` 块真身 = CTimedOpinionModifier (§4.10)。



**名字/头像库族 (1.19.3 实名与值对象)**: CUnitNamesPool (单国名字池, 120B; vt 0x1429461B8; writer 桩; reader 0x140AF4230): +8 prefix (12536) / +40 generic 名集 (12537, 读入去重合并) / +64 unique 名集 (12538) / +88 select_effect (13244) — 即 unit_names key (0x332F0D8) 的元素类型 (120B×国数 vector@+64/cnt@+76)。CNameGroupDatabase (4 范畴链式表: +40 names_divisions / +56 names_ships / +72 codenames_operatives / +88 names_railway_guns; [2]=0x1409C28D0 PostFinalize 引用缝合, 全库族唯一非桩 [2]) 与 CUnitNamesDatabase (common/units/names; 120B 池向量@+64/cnt@+76 = 国数)**归属易互换已钉死**: 4 目录装载者 = 0x140162D30/qword_14332EE90 (name_group key), "common/units/names" 装载者 = 0x1401642B0/qword_14332F0D8 (unit_names key)。CPortraitPool (单性别加权池, 72B; vt 0x14293FC70; reader 0x140A891C0): +8 male 池 (12775, 40B 元 {weight u64@0, 名串@8}) / +32 female 池 (10773) / +56 性别已设旗 (weight 须先于 male/female) / +64 u64 weight (593, 默认 100000)。CPoliticalPortraitPool (名字→池映射, 元素 112B = {名串 32B, FNV@+32, CPortraitPool 内嵌 72B}; vt 0x14293FCC0; reader 0x140A88F70) = CCountryPortraits+224 槽。**CCountryPortraits** (portrait idb 值对象, 400B) = vt + 3×CPortraitPool (+8/+80/+152) + CPoliticalPortraitPool (+224) + 2×CPortraitPool (+256/+328)。CCharacterTemplateDatabase (角色模板库, 184B; 双 RH 表 @+64/@+96, miss → TNullObject 0x143330C60; 单例 qword_14332EE58, 载 "common/characters") 与 CNameDatabase (common/names; RH map 16 桶起 {mask@+88=7/extra@+96=8}, 节点 0x428, 单例 qword_14332EF68) 均已在 idb 规格内。



**AI 数据库族 ctor 级复核 (8 库全在 idb 规格内, 零冲突)**: ai_area (0x332EDC8, CAIAreaDatabase 112B, arr@40/cnt@52; 条目 CAIArea 104B {名@8, continents@56, strategic_regions@80}) / ai_attitude (0x332EDE8, 96B, arr@64/cnt@76; **+88 = NullObject 默认条目指针 qword_1433304A8, ctor push 成 arr[0]**) / ai_equipment_role (0x332EDD8, 112B; Null 条目 = CNullAIEquipmentRoleDatabaseEntry 448B, ctor 0x141488530) / ai_role (0x332EDF0, 88B, sso16 名表) / ai_strategy (0x332EE00, 136B vec3: 名注册表@40 {40B 元 {string, ci-hash}} / 条目@64/@88 / _StrategySpecificData@112 cnt@124) / ai_strategy_plan (0x332EE10, 96B; **+48 = 默认缓冲 &aFff_0[4]**; arr@72/cnt@84) / ai_fleet_template + ai_taskforce_template (0x332EF88/0x332EF80, PR 族 128B 同构; **默认桶缓冲不同**: fleet = &unk_143085E50 / taskforce = &unk_143085E20; 条目 CAiFleetTemplate 80B {token=FNV@8, 双 32B 组 {串, 权重}} / CAiTaskforceTemplate 264B {CAndTrigger@72, 双组, i32 编成上限 10})。


库值对象/条目布局 (idb 已挂, ctor 级复核零冲突):

| 类 | 关键布局 |
|---|---|
| CStrategicLocationTemplate (要冲定义, 40B; vt 0x14271B960) | +8 token 哨兵 357 none / +16 vec<{building u32, level u32}> (data@16/cap@24/cnt@28); reader 每键解 building type (miss → "Invalid building type", strategic_locations_database.cpp:11), RHS 必整数; 形 `suez_canal = { suez_canal = 2 }` |
| CStrategicRegionTemplate (战略区定义, 336B; vt 0x1429DBE50) | +8 provinces (10288) / +32 名规范化 sso32 / +64 名原文 (27) / +160 id (181, ctor -1) / +168 u8=1 / +176 weather (12040, 元素 224B, 内 period=12042) / +272 naval_terrain (15147) / +312 static_modifiers (15136, 元素 80B); **writer 0x1415A6F40 = nudge/调试回写通道** (非存档, 存档侧 = CStrategicRegion 实例 §4.3) |
| CDifficultySetting (自定义难度项, 120B; vt 0x142935978) | +8 HasNullObject 活位 / +16 multiplier 对象 (10912, 默认 null 单例 qword_143330368) / +24 countries 国名哈希列 (11593) / +48 modifier 文本 (10597) / +56 key 名 (220) / +88 icon (181); **def ↔ 存档实例 CDifficultySettingItem (0xD8, gs+1064) 分工对** |
| CBookmark (主菜单书签, 400B; vt 0x1427E3E08; writer=CFG) | +16 name (27) / +48 desc (10644) / +112 picture (464) / +160 filters (10669) / +240 default → CBookmarkCountryEntry* 列 (11405, 每块 344B) / +384 date (10314); 消费只在前端 |
| CCountryTagAliasEntry (~800B; vt 0x1427EA8D0) | **+264 u32 别名 token** (resource.lua tok264 ✓); 键表 = 12048 variable / 13272 fallback / 13649 original_tag / 15763 country_score / 15764 global_event_target / 15765 event_target; ctor 端验 "invalid alias tag %s" / "alias is already existing tag %s" |
| CMTTHDatabaseEntry (MTTH 条目 = `mtth:` scoped var 目标, 56B; vt 0x14271A658 9 槽; 谱系 CMeanTimeToHappen→CPersistentWithToken; writer = CFG 空桩) | +8 u32 db 名 token / +16 u32 内嵌上下文 token (db 条目 = 16382) / +24 i64 base (fixed×1e-5, ctor 默认 100000) / +32 CMTTHModifier** 向量 {cap@+40, count@+44, alloc@+48}; reader token 分派: base 11398 / factor 10603 / months 10604 (×30e5) / days 10605 (×1e5) / years 10606 (×365e5) / modifier 10597 (new CMTTHModifier 0x1F8); 未知名 fatal "unknown command '%s' for MTTH in file … line …" |
| CScriptEnumDatabase 深读 | +40 空 vec = **miss 兜底仓** (键不在 → 返空 vec); RH@64 stride 40 {name token@8, 值 = 内联 vec<u32>@16}; 喂件 = common/script_enums.txt |
| CTechnologySharingGroupDatabase 深读 | **唯一 CPersistent 族 db** (次表 @+40, mdisp=40); +48 RH 表头 {cnt@64, extra@72, mlf@76} / +80 默认模板 160B; reader = token 14094 technology_sharing_group |


**库类名录** (key → 类 → 槽): 下表给出 idb 规格表各行 key 的**库类实名与槽地址** (补全「key → 类」映射):

| book key | 库类 | 槽 |
|---|---|---|
| aces | CAcesDatabase | 0x14332EDB0 |
| ability | CAbilityDatabase | 0x14332EDA8 |
| agency_upgrade | CAgencyUpgradeDatabase | 0x14332EDC0 |
| ai_fleet_template | CAiFleetTemplateDatabase | 0x14332EF88 |
| ai_bonus_weight | NIndustrialOrganisation::CAiBonusWeightDatabase | 0x14332EDD0 |
| ai_faction_theater | NFactions::NAi::CAiFactionTheaterDatabase | 0x14332EDE0 |
| autonomous_state | CAutonomousStateDatabase | 0x14332EE18 |
| continuous_focus | CContinuousFocusDatabase | 0x14332EE60 |
| country_leader | CCountryLeaderDatabase | 0x14332EE68 |
| country_metadata | NCountry::CMetadataDatabase | 0x14332EE70 |
| country_tag_alias | CCountryTagAliasDatabase | 0x14332EE78 |
| difficulty_settings | CDifficultySettingsDatabase | 0x14332EE88 |
| dlc_metadata | NDLC::CMetadataDatabase | 0x14332EE98 |
| doctrine_folder | NDoctrines::CFolderDatabase | 0x14332EEA0 |
| grand_doctrine | NDoctrines::CGrandDoctrineDatabase | 0x14332EEA8 |
| sub_doctrine | NDoctrines::CSubDoctrineDatabase | 0x14332EEB0 |
| doctrine_track | NDoctrines::CTrackDatabase | 0x14332EEB8 |
| faction_goal | NFactions::CFactionGoalDatabase | 0x14332EEE0 |
| faction_member_upgrade | NFactions::CFactionMemberUpgradeDatabase | 0x14332EEF0 |
| faction_rule | NFactions::CFactionRuleDatabase | 0x14332EF00 |
| faction_rule_group | NFactions::CFactionRuleGroupDatabase | 0x14332EF08 |
| ideology | CIdeologyDatabase | 0x14332EF38 |
| mio_organisation | NIndustrialOrganisation::COrganisationDatabase | 0x14332EF48 |
| focus_inlay_window | CFocusInlayWindowDatabase | 0x14332EFD0 |
| historical_agency | CHistoricalAgencyDatabase | 0x14332EDB8 |
| occupation_modifier | COccupationModifierDatabase | 0x14332EFC0 (真库槽) |
| operations | COperationsDatabase | 0x14332EFA8 |
| operation_phases | COperationPhasesDatabase | 0x14332EFB0 |
| operation_tokens | COperationTokensDatabase | 0x14332EFB8 |
| opinion_modifier | COpinionModifierDatabase | 0x14332EFC0 |
| portrait | CPortraitDatabase | 0x14332EFD8 |
| project | NProject::CProjectDatabase | 0x14332EFE8 |
| project_dynamic_modifier | NProject::CProjectDynamicModifierDatabase | 0x14332EFF0 |
| prototype_reward | NProject::CPrototypeRewardDatabase | 0x14332EFF8 |
| resistance_activity | CResistanceActivityDatabase | 0x14332F008 |
| scientist_trait | CScientistTraitDatabase | 0x14332F010 |
| script_constant | NScript::CConstantDatabase | 0x14332F020 |
| script_named_collection | NScript::CNamedCollectionDatabase | 0x14332EED8 |
| scripted_diplomatic_action | CScriptedDiplomaticActionTemplateDatabase | 0x14332F048 |
| strategic_location | CStrategicLocationDatabase | 0x14332F078 |
| strategic_region | CStrategicRegionDatabase | 0x14332F080 |
| strategic_resource | CStrategicResourceDatabase | 0x14332F088 |
| technology | CTechnologyDatabase | 0x14332F0A0 |
| unit_leader | CUnitLeaderDatabase | 0x14332F0D0 |
| unit_medal | CUnitMedalDatabase | 0x14332F0C8 |
| career_picture | NCareerProfile::CProfilePictureDatabase | 0x14332EE38 |
| career_background | NCareerProfile::CProfileBackgroundDatabase | 0x14332EE40 |
| career_medal | NCareerProfile::CMedalDatabase | 0x14332EE30 |
| career_ribbon | NCareerProfile::CRibbonDatabase | 0x14332EE48 |

**条目类 ≠ 「库名去 Database」的 5 处** (按库名推条目类会取到运行时件) 见下表:

| 库 | 条目类 | 说明 |
|---|---|---|
| CContinuousFocusDatabase | **CContinuousFocusPalette** | reader sub_1406C2C80 直证 `malloc 0x90` → `&CContinuousFocusPalette::vftable'` |
| CAcesDatabase | **CAce** | AddItem sub_140618600 / sub_140618860 `malloc 0x178` → ctor sub_1406176C0; CAceModifier (0xF8) 是其内嵌子件 (aces.cpp:207) |
| CStrategicLocationDatabase | **CStrategicLocationTemplate** | 模板实参直证 |
| CTechnologyDatabase | **CTechnologyTemplate** | 0x590 为定义条目; CTechnology (0x1F8) 是运行时科技件 |
| CUnitLeaderDatabase | **CUnitLeaderTemplate** | 0xC0 为定义条目; CUnitLeader (0x10B8 / 0xFC8) 是运行时将领 |

**无独立 RTTI 条目类** (2 库, 条目为内联 POD):

| 库 | 条目形态 | 证据 |
|---|---|---|
| CCharacterAdvisorGenerationDatabase | 56B 内联元素 (含 name sso), 无 vftable | 装载器 sub_1406B1C80 → sub_1406B1050; vector 增长助手 sub_1406B0880 按 `56*count` 分配, 逐字段 `+24 = 15` (sso cap) 初始化 |
| ?A0x9ca8863a::CAmbientSoundDatabase | 200B 内联元素, 无 vftable | dtor sub_14066E360 里 `v5 += 200` 步进释放 |

**派生族统计** (49 库) 见下表:

| 族 | 数 | 类 |
|---|---|---|
| PR (`CPersistentReloadableGameItemDatabase<DB,Entry,Cfg>`) | 16 | CAiFleetTemplate / CFocusInlayWindow / CStrategicLocation / NDoctrines::{CFolder, CGrandDoctrine, CSubDoctrine, CTrack} / NFactions::{CFactionGoal, CFactionMemberUpgrade, CFactionRule, CFactionRuleGroup, NAi::CAiFactionTheater} / NProject::{CProject, CPrototypeReward} / NScript::{CConstant, CNamedCollection} |
| TRS (`TReloadableGameItemDatabaseSpecific<DB,Entry>`) | 8 | CCountryTagAlias / CIdeology / COperationPhases / COperationTokens / COperations / CScientistTrait / NIndustrialOrganisation::{CAiBonusWeight, COrganisation} |
| 裸 T (仅 `TGameItemDatabase<T>`, 非 CPersistentReloadable 派生) | 23 | 其余 |
| T + CPersistent 多基 (**双虚表**) | 2 | CAutonomousStateDatabase / CContinuousFocusDatabase |
| 合计 | 49 | — |

> 族口径与 idb 规格表吻合: PR 族 = `{vec@8 基类(=_Paths), 表@48, 条目 vec@80/cnt@92, token vec@104}`;
> TRS 族 = `{条目 vec@96/cnt@108, 宽名表@64 stride 56}`。
> **PR 族模板第三参 = 条目名取法编译期开关**: `NDatabaseConfig::SDefaultLexerTokenConfig<Entry>` /
> `SDefaultConfig` / `SDefaultDelayedLexerTokenConfig` / 各库自有 `SXxxDatabaseConfig`。
> ⚠ **T + CPersistent 双虚表库** (CAutonomousStateDatabase / CContinuousFocusDatabase) —
> `resource.lua` 若按单 vtable 取类名会落空。

**目录 ↔ 类名不一致 (3 处 + 1)** — 按类名推目录会静默不加载:

| 库类 | 实际脚本目录 | 按类名推得的目录 (错误) |
|---|---|---|
| COccupationModifierDatabase | `common/resistance_compliance_modifiers` | common/occupation_modifiers |
| CStrategicRegionDatabase | `map/strategicregions` (无下划线, 带 map/ 前缀) | common/strategic_regions |
| CStrategicResourceDatabase | `common/resources` | common/strategic_resources |
| CCharacterAdvisorGenerationDatabase | `common/generation` | common/character_advisor_generation |

**非 qword_14332Exxx 段的库槽** (3 库):

| 库 | 情况 |
|---|---|
| CCharacterAdvisorGenerationDatabase | 无独立 .data 槽; DB 对象由 qword_14332EE50 承载 (内联在总入口) |
| COpinionModifierDatabase | 库槽 = qword_14332EFC0 (正常段内); ⚠ 其 TNullObject 哨兵 **0x143339EB8** 易被误当库槽 |
| ?A0x9ca8863a::CAmbientSoundDatabase | 槽 = qword_143330540 (不在 0x14332Exxx 段) |

**无 gameplay 消费的库** (负定案, 不参与存档面):

| 库 | 负结论 |
|---|---|
| NCareerProfile::CProfilePictureDatabase / CProfileBackgroundDatabase | 纯前端生涯档案图库 (`common/profile_pictures` / `common/profile_backgrounds`), 条目仅 32B 句柄包装 |
| ?A0x9ca8863a::CAmbientSoundDatabase | 匿名命名空间音效库 (`sound/combat_sounds`), 条目 200B 内联; 纯音频播放侧 |
| CDifficultySettingsDatabase | 难度设置静态库; 条目 120B; 只在开局难度选择/GUI 侧消费 |
| NCountry::CMetadataDatabase / NDLC::CMetadataDatabase | stdmap 形态元数据库 (`country_metadata` / `dlc_metadata/dlc_info`); DLC 归属与国别元信息 |

**库形态补注**: ① `mtth` **byte@128 = 内容解析开关**（定案）: boot 双通道装载 — ctor/boot 首遍置 1 并 sub_140188F30 只登记名（内容被 brace-skip 0x1424C2100）→ 次遍 sub_140192E80 首句清零后逐名全量解析（0x140552390 CMeanTimeToHappen reader）; 活体实证 byte=0 且 59 条目已含解析值（base≠ctor 默认）；CCountryTagAliasEntry reader 同机制; ② `ability` 名 MSVC@def+112 由「定案」改注**高置信** (resource.lua nm="none 暂计数" 对拍分歧); ③ `difficulty_settings` getter = **sub_140170630** (单例 creator, 槽 0x14332EE88, `_pInstance && "Instance already created."` gameitemdatabase.h:127 断言链); 并列的 sub_140170120 在 1.19.3 **不存在** (dump 无该函数头); ④ `message_handler` = 非内容库 (注册表+设置处理器, 未入 idb 规格表, 其值类 CMessageType/CMessageTypeSettings 见 §4.28.10); ⑤ `country_tag_alias` 单例 0x332EE78 ✓ / `mtth` 0x332EF58 ✓ / `technology_sharing_group` 0x332F098 (C 按名) / `script_enum` 0x332F028; 14 库分级切片: A 10 / C 2 / D 1 (aces) / 非内容库 1。

**CAceModifier** (王牌修正 def; vt 0x1427DE3A0; writer = CFG 空桩 = 解析件; reader 0x14061B390): +40 type 枚举 / +48 chance f32 / +56 effect 嵌套子对象。⚠ 与 CContextLocalizationText 虚表相邻 (0x1427DE358 vs …3A0), 归属勿混。

**CTechnologyPath** (科技树路径 def; idb 项, 基 THashedKeyValueTrait mdisp=8; writer = CFG 空桩 = 解析件): +8 leads_to_tech 串 (FNV-1a 入 +40) / +48 research_cost_coeff f32 / +144 ignore_for_layout u8。

**成就定义族** (def 去向 `common/achievements/*.txt`; writer 全空桩 = 只载不存): **CBaseAchievement** (vt 0x1427DECC0 基, reader 0x140620960 共用回退): possible(10886)→+16 CBaseTrigger\* (malloc 0x58) / happened(10887)→+24 第二触发器 / hidden(11404)→+32 u8; **CAchievement** (0x1427DED30, reader 0x140620920 先查自身 Miss 回退基): +80 id (11) 整型短码; **CAchievementMod** (0x1427DEDF0, reader 0x140620940): +120 ribbon (16053) 块读 — mod 成就与生涯 ribbon 体系挂钩 (token 区 16001+ career/awards 系, 与 §4.28.8 medal/ribbon 族同邻域); 运行时实现层 CAchievementsContext 抽象 ← CSteam (§4.00.9) / CDummyAchievementsContext 单机空实现。

**成就运行时族** (与上列定义族**同名不同物、无继承关系、无共同虚表**; 平台成就状态机, 非 CPersistent):

| 类 | vt | ctor | 布局要点 |
|---|---|---|---|
| CAchievementBase | 0x142B5BA98 | 0x142397F30 (dtor) | 抽象基: 8 槽 = [0] dtor + [1..7] = `_purecall` (0x14253C3B8) → 7 纯虚 |
| CPrimeAchievement | 0x142B5BAE0 | 0x142397EA0 | 96B: +8 qword (ctor a3) / **+16 = `CAchievementsContext*`** (vt[1][2] 内以 `**(a1+16)+112` 虚调上下文) / +24 SSO / +56 SSO / **+88 u8 = 达成旗** |
| CAchievementsContext | 0x142B5BB28 | 0x142397F60 (dtor) | 抽象 (多数槽 `_purecall`); 实现 = CSteam / CDummyAchievementsContext |

> CPrimeAchievement 行为槽: [1] sub_142398600 = 达成置位 (+88==0 → +88=1 → 通知上下文) / [2] sub_1423982C0 = 复位 (+88==1 → +88=0 → 通知) / [5] sub_1403CFD80 = `return *(u8*)(a1+88)` 查询。
> ⚠ 定义族 (`CBaseAchievement` / `CAchievement`) 是成就定义数据 (id/触发器/ribbon), 运行时族是平台成就状态 (键/描述/达成旗) — 两族**勿互指**。

**书签定义族** (def 去向 `common/bookmarks`; writer 空桩; 库 = **CBookmarkDatabase** TGameItemDatabase 模板 (vt 0x1427E3E88), 附 Null 变体 VCBookmark TNullObject 0x1427E3FF0): **CBookmark** (vt 0x1427E3E08, 基 CPersistent + THasNullObject; reader 0x14067DB80) 14 键: name(27)→+16 / picture(464)→+112 / desc(10644)→+48 串 / effect(89)→+264 触发器槽 / filters(10669)→+160 列表 / label_order(19089)→+184 追加合并 / default_country(13212)→+144 CCountryTag 校验读 / date(10314)→+384 块读 / default(11405)→+392 / sort_unplayed_first(11473)→+393 / include_majors_in_minor_list(18242)→+394 / apply_filter_to_majors(18953)→+395 / apply_filter_to_other_country(18646)→+396 / scrollable_country_list(18923)→+397 u8 系; 匿名国家子块 → +240 向量追加 (= CBookmarkCountryEntry, ctor 0x14067BFC0) + +216 id 收集 + +356/+360 已玩/未玩计数。**CBookmarkCountryEntry** (reader 0x14067E210) 9 键: history(10293)→+24 / label(519)→+128 列表 / ideology(11838)→+152 组指针校验读 / required_dlc(15200)→+0 本对象解析 / available(12264)→+184 触发器槽 / minor(11242)→+272 / assume_not_played_if_missing_data(12791)→+273 / version(238)→+280 / override_leader_portrait(12792)→+312。**CCountryScorerDatabase** (打分器库, def 去向 `common/scorers/country`; TReloadableGameItemDatabase 模板; vt 0x142941570 7 槽, null 项 "null_country_scorer"): 条目 reader 0x140AA4060 唯一键 targets(15733) → malloc 0x140 (320B) **SSingleScorerEntry** (内嵌 CScriptTargets@+8 + 双 CBaseTrigger + 双串 + flags@+248/+256) 追加 +24 指针向量 {cap@+32, count@+36}。

**CTreeShortcut** (国策树快捷键 def; vt 0x142739B18 9 槽; writer 空桩 = 解析件; reader 0x1402D9470): target(107)→+16 串 / name(27)→+48 串 / scroll_wheel_factor(626)→+176 / trigger(10595)→+88 子对象 vt+40; 未知键抛 "Error in focus tree shortcut"。

**CUpgradeWindowOverride** (升级窗口覆盖 def; vt 0x14295B7D8 9 槽 + 后接两组内嵌子对象虚表; writer 空桩 = 解析件; **三组 = 内嵌子对象定案** — RTTI CHD 层级各自仅 {自身, CPersistent}, 三 COL this_off 全 0, 非多基): 外壳 reader 0x140C9B3D0 键 upgrade(15356)→+8 串 / override(14561)→+40 串; 内嵌 **USModifierStat** (第二虚表, reader 0x140C9B410) 键 type(225)→+20 / value(776)→+16 / modifier(10597)→+8 查表; 内嵌匿名 ns **CModuleCountLimit** (第三虚表, reader 0x140C9B340) 键 category(702)→+40 / title(10643)→+8 / count(10730)→+48+52 / module(15222)→+44。

**CFrontEndBackgroundDatabase** (主菜单背景项库; vt 0x14271A2C0 5 槽; 基 CPersistentReloadableGameItemDatabase; 启动初始化 sub_1401835A0): def 去向 common/profile_backgrounds; 条目类邻位 = CFrontEndBackgroundDatabaseItem。**CFrontEndBackgroundManager** (vt 0x142A62D08; 前端初始化 sub_14163E810): 背景选择/切换管理器。



**CTerrainType** (terrain 库 A 族游戏性地形 def, ≥504B; vt 0x1429C0EA0; writer=CFG; reader 0x14143F460; ctor 0x14143BB90): +8 i32 = **def 名 token** (基类 ctor sub_1424BE3C0 直写 357 = `none` 哨兵, 装载后由 reader 覆写) / +16 u8 有效旗 / +24 名 SSO 32B / +56 库内序号 / +64 CColor 内联 32B (86) / +96 movement_cost (10331, <1000 强抬并告警 terrain.cpp:181) / +104 combat_width (11471) / +112 combat_support_width (19635) / +120 ai_terrain_importance_factor (13826) / +128 minimum_seazone_dominance (10173) / **+140 u32 位掩码: bit0=inland_sea (10761) / bit1=is_water (10418), parse 期按 yes 置位** / +148 worth (13287) / +152 match_value (14014) / +160 u32 = **`sound_type` (11052) 枚举: 0=plains / 1=sea / 2=forest / 3=desert** (reader 0x14143F460 case 11052 以 memcmp 四串; 磁盘互证 `common/terrain/00_terrain.txt` 每条 `sound_type = forest` 等) / +168 CModifier 内嵌 ~192B (未知键兜底) / +360 CUnitAdjuster 内嵌 40B (12202 units) / +408 逐单位类型地形加成子块表 {d@408, c@420}, 元素 272B / +496 supply_flow_penalty_factor (19650)。**has_terrain 负定案**: 该 trigger (sub_1404365C0) 只按 **def+8 token** 在 terrain 库内匹配条目、命中后读 **def+16 有效旗**, **不读 +140 两位**。

**CInsigniaTypeGraphics** (insignia_graphics 库 kind8 元素, 64B; vt 0x14293D378; writer=CFG; reader 0x140A56120): +8 gfx 名 SSO (12472) / +40 SInsigniaIconInfo* 向量 {d@40, c@52} (181 icon 逐条 malloc 136B 构造)。

**CSubUnitCategory** (单位类目定义, ≥108B; vt 0x142985DC0; 名录): +16 类目名 SSO / +48 序号 (-1) / +56 容器 {d@56, c@68} / +84 i64=357 = **def 名 token** (ctor 0x141017F70 直写 357 = `none` 哨兵)。**CGraphicalCultureType** (graphicalculturetype 裸名定义; vt 0x14293BFF8; 名录): +8 FNV 名哈希 / +16 名 SSO / +48 库内序号 / +96 固定 800B 表 (推定层/肖像映射)。**CTrainGfxDatabase** (train gfx 库; vt 0x1429453B8, 5 槽非 CPersistent; 名录): idb train_gfx 已挂 (0x332F0C0, 内嵌记录@40 + 指针 vec@104 + 双槽位阵@176/@200), dtor 0x140ADED40 容器群直证 +152 第三 vec 亦存在。


**脚本化值/文本/模板族 (三库已挂, 布局全录)**: CScriptableValue (脚本值求值对象, 248B; vt 0x1429DAFC8; writer=CFG; reader 0x1415945D0): +8 CScopedVariable 208B 基值 (base 11398) / +216 CPdxArray<CScriptableValueModifier*> modifier 表 (10597, 逐条 504B) / +240 上下文 id; **CScriptableValueModifier** (504B; vt 0x1429DAF08; CAndTrigger 后代): +88 CScopedVariable factor (种子 1.0) / +296 CScopedVariable add (种子 0) + 基条件表全 AND。**SModifierDefinitonReader** (modifier_definitions 行解析器, 32B 栈件; vt 0x1427DDA50; reader 0x140610B80): +8 precision (19052) / +12 显示格式位包 (color_type 19042: good→bit1 / neutral→bit2; value_type 19043: percentage→bit0 / yes_no→bit5 / percentage_in_hundred→bit7) / +16 postfix 枚 (19049: 1 days / 2 hours / 4 daily) / **+24 category 位掩** (state=0x10 / country=0x8 / army=0x20 / ai=0x100 / naval=0x1 / air=0x2 / politics=0x80 / unit_leader=0x4 / intelligence_agency=0x10000 / scientist=0x40000 / peace=0x40 / defensive=0x200 / aggressive=0x400 / war_production=0x800 / military_advancements=0x1000 / military_equipment=0x2000 / autonomy=0x4000 / government_in_exile=0x8000; all=0xFFFFFF)。**CScriptableLocalization** (defined_text 条目, 64B; vt 0x142942470; writer = 死断言 "Should not happen!" 永不写盘; reader 0x140AAC7A0): +8 name / +40 STriggerKeyPair 数组 (元素 24B {vt@0, loc 载荷*@8 (localization_key 799 或 random_list 10172 二选一, 同文件互斥), CAndTrigger*@16})。**CScriptableLocalizationDatabase** = umap 哨兵@48/size@56/cs-FNV/node+48 值槽 + reload 钩 (dword_14333A0A0) — 「链表走反」修复族的第三例代码级证据。**CScriptedTriggerTemplate** (模板 and-trigger 树, 136B; vt 0x142942C50): THasNullObject@88 + 名 sso@+96 + idx@+128; [1] GetName 覆写 0x1401776D0。**CScriptedTriggerTemplateDatabase**: vec@64/cnt@76 (槽 0 = TNullObject 0x88B) + 双 RH 表 (LF 0.9)。**CScriptedEffectTemplateDatabase**: 条目 vec@80/cnt@92 (条目 128B, 名 sso@+96) + **[2] = "d_" 前缀依赖收集器** (0x140AB4AC0) → +128 reload vec。

#### 4.26.12 GUI/渲染模板 Type 族 (指针)

精灵 (CSpriteType 族) 与 GUI 控件 (CGuiType 族) 模板 Type 全表 = 模板解析件族 (writer = CFG 空桩, 不入存档), 已移至 GUI 域 §4.30.31 / §4.30.32。
