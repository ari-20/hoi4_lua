

### 4.27 突袭族 (CRaidSystem / CCountryRaidStatus / CRaidInstance / CRaidDatabase)

> **定位**: 突袭 (raid) 全链 — 系统入口 (gs+1008)、国家状态、实例、def 侧库与
> 成功率计算族。GUI 侧 (图标数据族/行件/设置窗/反馈窗) 见 §4.31.28/§4.31.34;
> 命令族 (CRemoveRaidCommand / CCreateRaidCommand) 见 §4.33。

#### 4.27.1 CRaidSystem / CCountryRaidStatus / CRaidInstance (raid 主体)

| 项 | 值 | 语义 |
|---|---|---|
| 系统入口 | `raids = *(gs+1008)` | |
| countries 容器 | {data@+216, count@+228}, 元素 0xB0 stride | |
| CCountryRaidStatus | vtable 0X29CCD88, writer 0X1414EACF0, ctor 0X1414E9000 | 下表 |
| CRaidInstance | vtable 0X2983A78 (+24 第二 vtable = CEquipmentDistributable 0X2983AD0), writer 0X140FEF9C0, ctor 0X140FE9980, dtor 0X140FE9F90, 尺寸 0x1D8=472 | 下表 |
| CRaidSystem | vtable 0X2971F98, ctor 0X140E83B80 (+8 = 目标管理器内联) | 目标管理器见下 |

**CCountryRaidStatus** (元素 0xB0 stride; countries.#N = 槽位 idx+1, 440 全槽恒写):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | tag tid (tid>0) |
| +16 | 匿名结构 (NNB 形状)* | dummy 对象 (id 对 @*(+16)+8 {type@+0, id@+4}, 恒写) |
| +24 | CRaidInstance* | raid_instance 容器数据指针 — 指针数组 (c>0) |
| +25..+35 | — | = raid_instance 容器尾 {cap@+32, c@+36, alloc@+40} |
| +36 | uint32 | raid_instance 容器计数 |
| +48 | CRaidCategory* 向量 24B | used_types (键 16724; CRaidCategory* 指针数组 {d@48, cap@56, c@60, alloc@64}; 元素→def token 名串; 插入点 0X1414E9FA0 `if(*(def+3017)) push`) |
| +72 | 匿名结构 (64B 形状) 向量 24B | target_cooldowns (键 16727; CRaidTargetCooldownStatus 64B 元素 {d@72, cap@80, c@84, alloc@88}; 元 = {vtable@0, SRaidTarget 40B 拷贝@8..47, +48..+63 = 目标位置快照尾槽 (leader_province) + cooldown 天数 u32@+56 (def+3020)}; 元素内无日期) |
| +96 | uint32 | priority (恒写; ctor 默认 = 1) |
| +104 | uint32 向量 24B | available raid types (CRaidType* 数组 {d@104, cap@112, c@116, alloc@120}; 从 CRaidDatabase 单例 qword_14332F000+176 按 tag 过滤重建; 不写盘; 名推定/备选 usable_types) |
| +128 | 匿名结构 (NNB 形状) 向量 24B | active raids (CRaidInstance* 数组 {d@128, cap@136, c@140, alloc@144}; phase≠5; CreateRaid 查重 "Already has a raid against this target") |
| +152 | 匿名结构 (NNB 形状) 向量 24B | ended raids (历史) (CRaidInstance* 数组 {d@152, cap@160, c@164, alloc@168}; phase==ENDED; 按 end_date + define dword_143332398 天龄淘汰) |

**CRaidInstance** (writer 0X140FEF9C0, a1 = inst; 全字段定案):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | id.type — id 对之 type (对 {type, id} (B400)) | 恒写 |
| +12 | uint32 | id 对.id — B400 壳 | 恒写 |
| +16 | uint8 | 基类标志 (=0) | 高置信 |
| +24 | CEquipmentDistributable 内嵌 24B | 第二基类 {vtable@+24, u32=1@+32, ptr=0@+40} (RTTI 直证) | 不序列化 |
| +48 | uint8 | auto_launch (键 10155) | ≠0 |
| +52 | uint32 | auto_launch_option 枚举 (0=VERY_LOW 1=LOW 2=MEDIUM 3=HIGH(默认) 4=VERY_HIGH) | ≠3 才写 |
| +56 | uint32 | phase: 0=NONE 1=ASSEMBLING 2=PREPARING 3=PREPARED 4=IN_PROGRESS 5=ENDED (断言 "Saving invalid raid phase!" raid_instance.cpp:0xDB) | ≠0 |
| +60 | uint32 | outcome: 0=NONE 1=FAILURE 2=LIMITED_SUCCESS 3=SUCCESS 4=CRITICAL_SUCCESS 5=CANCELED | ≠0 |
| +64 | uint32 | risk_level (0=LOW 1=MEDIUM(默认) 2=HIGH) | ≠1 才写 |
| +68 | uint32 | prep_time (键 16597) | ≠0 |
| +72 | uint32 | nr_days_launchable (键 11172) | ≠0 |
| +80 | fixed×1e-5 | distance (键 11738) | ≠0 |
| +88 | CCountryRaidStatus* | owning status 回指 (CreateRaid 0X1414E9320 `ctor(v15, a1=status)`; runtime-only) | 不序列化 |
| +96 | CVariables 内嵌 56B | variables (键 10826; {vtable@96, u32=1@104, seed@108, ptr@120, …, parent@144}; ctor sub_140BC5BD0) | ADEC0 |
| +152 | NRaids::CRaidType* | type → token 名 = token_name(u32@*(inst+152)+8) 引号 | ptr≠0; def 对象 = **CRaidType** (3064B); **def 侧锚: CRaidType+2600/+2624 = additional_equipment / essential_equipment 两张 256B 元素 RH 表** (GUI 装备需求行 required 列数据源; current 列 = +272 装备池查找 / nukes 行 = +336, §4.31.28 互证) |
| +160 | 内嵌 | target = SRaidTarget (0X140FE7D20): building def ptr@+160 → template token@*(def+480)+8, location u32@*(def+472)+108 (NHQ 同构); province ptr@+168→+164; state ptr@+176→+88 | 块空判 0X140FE78B0; **GUI: 目标图标条目数据源** (访问器 sub_1406ABC90 = `return inst+160` 直证; 40B 拷贝宿主 = CRaidTargetMapIconData+2832 / gamestate 目标条目+8) |
| +161..+199 | — | = SRaidTarget 40B 本体 {building@160, province@168, state@176, leader id 对@184/+188, leader_prov@192} (CreateRaid 拷入 a3) |  |
| +200 | uint32 | unit id 对.type | 空判 = 4 dword @+200..+212 全 0 (0X141466A00); **GUI: 参与单位行 = 16B 双 id 对 {师, 翼} 同形互证** (CRaidUnitItem+120, §4.31.28) |
| +204 | uint32 | unit id 对.id | 同上 |
| +205..+215 | — | = unit id 对×2 尾 (两 qword 哨兵 = qword_14333D528) |  |
| +216 | 内嵌 | raid_source (56B, 非指针; 布局见下表) | b@+4≠0 (0X141593F60) |
| +217..+271 | — | = raid_source 56B 本体细分 {+220 u8 有效门, +224 ptr, +232 id 对哨兵, +240 u32, +248 building 内嵌块 (sub_1413C0880 构造)} |  |
| +272 | CEquipmentVariantPool 内嵌 64B | equipment (键 12110; {vtable@272, 容器1{d@280, cap@288, c@292, alloc@296}, 容器2{d@304, cap@312, c@316, alloc@320}, u8@328}; ctor 0X14100C710 — CEquipmentVariantPool 同体异名, §4.23.3) | 空判 sub_141010BA0 + ADEC0 |
| +336 | uint32 | nukes (键 13517) | ≠0 |
| +344 | CCommandPowerAllocator 内嵌 56B | 突袭指挥点花费分配器 {vtable@344, ptr@352, qword@360, CString 名@368 cap@392=15} (RTTI 直证) | 不序列化 |
| +400 | uint8 | detected → yes | ≠0 |
| +408 | vtable (CGameDate 族) | end_date (0x28E1) 内嵌 CGameDate vtable 指针 | 定案 |
| +416 | uint32 | end_date 内嵌 CGameDate hours | 定案 |
| +417..+431 | — | = end_date 24B 本体 {vtable1@408, hours@416, vtable2@424=ADEC0 代理基} |  |
| +432 | uint8 | end_date 门 bool | ≠0 才写; 定案 |
| +440 | uint32 向量 24B | show_for (键 11173; u32 tag id 数组 {d@440, cap@448, c@452, alloc@456} — 可见该突袭的国家列表) | c>0 |
| +464 | tag_id | victim_country (键 10164) → 引号 | tid>0 |

raid_source (@inst+216; 56B 内嵌块):

| 块+N | 类型 | 名称/语义 |
|---|---|---|
| 块+0 | u32 | type enum → token 映射 (见下表) |
| 块+8 | CProvince* | province ptr → +164 |
| 块+16 | idpair {type@+0, id@+4} | **ship (0x28A0=10400)** — 舰源 id 对 {type=51}; 任一 ≠0 才写 |
| 块+24 | tag_id | tag tid |
| 块+32 | 内嵌块 | building {location u32@块+40, template token@块+44} (sub_1413C0880 构造) |

GUI 行件内联拷贝 = **64B 扩展版** (CRaidSourceItem, §4.31.28): 前 56B 与本块同体, **+56 = 距离 fixed** (GUI 侧计算补尾, 不落盘); 点击路由 = CRaidGuiManager::SelectSource 0X14129B1C0 / SelectUnit 0X14129B670 (mgr+128 写 16B 引用) 或 CGameGui vtable+440 地图 ping — 行件均无直接 CCommand 出口, 全走 **CRaidGuiManager 状态机 (mgr+72 step)**。 |

raid_source type enum → token 映射:

| 值 | token | 语义 |
|---|---|---|
| 0 | 12214 | — |
| 1 | 13303 | — |
| 2 | 12790 | — |
| 3 | 12175 | — |
| 4 | 12173 | — |
| 5 | 10319 | — |

**raid targets mgr** (@CRaidSystem+8; ctor 0X14195DED0, writer 0X141960FF0, 重建 0X14195ED40, raid_target_manager.cpp):

| 偏移 (mgr) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | 匿名结构 (target 条目) | target 容器数据指针 — 数组 {d, c} 8B 指针 (targets.target[N] 数组序) |  |
| +1..+11 | — | = target 容器尾 {cap@+8, c@+12, alloc@+16} |  |
| +12 | uint32 | target 容器计数 |  |
| +24 | 匿名结构 (NNB 形状) | 目标索引辅助 (+24/+56/+112; target ptr↔index 双向簿记; 断言 "Inconsistent target index" raid_target_manager.cpp:0xFA) — 与 +32/+64/+120 三合为三张 RH 目标反查索引 | 不序列化 |
| +32 | CRaidTargetStatus* RH 桶数组 | 目标反查索引 (+32/+64/+120; 各 {种子 u32+lf f32 前缀, 24B 桶 {hash, key*, value*}}): 表#2 = CBuildingStatus*→CRaidTargetStatus* (探针 53 项 ≈ detectable 51); **表#1 = 省 id (省+164)→target (sub_14195C6E0) / 表#3 = leader 对象指针 (idpair 经 sub_14221F310 解引用)→target (sub_14195C920)** — reader sub_141960960 三插入器直证补全 (原「表#1/#3 本档空推定」系运行时未观测, 补全非推翻); 第四张 = +88 _StateTargets 州 id 直下标 (§4.27.6) | 不序列化 |
| +88 | 匿名结构 (8B 形状) 向量 24B | **州索引目标查找数组 _StateTargets** {d@88, cap@96, c@100, alloc@104} (8B 元; 按 gs+724 = **州数** 预分配清零, 按州 id 直下标; :363 断言串实名 _StateTargets — 原记「省索引/省数」系标注笔误, §4.1 州 712/724 互证) | 不序列化 |
| +144 | uint32 | next_state | 恒写 |
| +145..+163 | — | = existing targets 容器 {d@152, cap@160, c@164=existing_target_num 键同址, alloc@168} |  |
| +164 | uint32 | existing_target_num | 恒写 |
| +165..+187 | — | = detectable targets 容器 {d@176, cap@184, c@188=detectable_target_num 键同址, alloc@192} |  |
| +188 | uint32 | detectable_target_num | 恒写 |
| +189..+199 | — | = detectable 容器尾 + next_target 前置 |  |
| +200 | uint32 | next_target | 恒写 |

per-target (writer 0X141A3B1E0; t = target 元素):

| 偏移 (t) | 类型 | 名称/语义 | 写门/备注 |
|---|---|---|---|
| +0 | uint32 | existing = existing_target_num (键 0x4B03=19203) | u32 哨兵 0xFFFFFFFF ↔ -1 |
| +4 | uint32 | detectable = detectable_target_num (键 0x4B04=19204) | u32 哨兵 0xFFFFFFFF ↔ -1 |
| +8 | 内嵌 | SRaidTarget (全指针门无判别枚举, 下表) |  |
| +9..+47 | — | = SRaidTarget 40B 本体 (内层表见下) |  |
| +48 | uint8 | dynamic (键 0x3313=13075) | 恒写 yes/no |
| +49 | uint8 | valid (键 0x4AF6=19190) | 恒写 yes/no |
| +56 | uint8 | detected 容器数据指针 — u8 数组 {d, c} | c>0 |
| +57..+67 | — | = detected 容器尾 {cap@+64, c@+68} (键 0x4B06=19206) |  |
| +68 | uint32 | detected 容器计数 | c>0 |

内层 SRaidTarget (@t+8):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | CBuilding* | building ptr → template = token@*(bld+480)+8, location = u32@*(bld+472)+108 |
| +8 | CProvince* | province ptr → id@+164 |
| +16 | CState* | state ptr → id@+88 |
| +24 | uint32 | leader.type — id 对之 type (id 对) |
| +28 | uint32 | leader.id — id 对之 id |
| +32 | CProvince* | leader_prov ptr → +164 |


#### 4.27.2 突袭 def 侧 (CRaidDatabase / CRaidType / CRaidCategory)

**CRaidDatabase 单例与对象工厂** (偏移升序):

| 项 | 值 |
|---|---|
| 单例槽 | qword_14332F000 (`_pInstance && "Instance not created."` 断言, gameitemdatabase.h:142); 懒构造器 sub_1401731C0 (Init_thread 模式, malloc 0xC8, 三层 vtable 直写 TGameItemDatabase→TReloadableGameItemDatabase→CRaidDatabase) |
| 装载路 | LoadDatabases (sub_14018BB20, LOADING_DATABASES 阶段) → 目录数组 {"common/raids/categories", "common/raids"} .txt → InitFromDirectory → 逐文件 CRaidCategory/CRaidType reader; **db = 进程级静态资源, 会话读档不重 parse** (修正器对象生在 def 装载期, 随 db 重建整体废弃) |
| ⚠ 勿混认 | qword_14332F080 = **CStrategicRegionDatabase** 单例 (ctor sub_140ABFD90), 非 raid DB |
| CRaidType 工厂 | sub_140A9D2D0(db, name) → malloc 0xBF8 + ctor 0x140A9A170, 注册进 **db+144** 哈希表 (查重 sub_140A972A0(db+144)) |
| CRaidCategory 工厂 | sub_140A9D170(db, name) → malloc 0xE0 + 内联 ctor, 注册进 **db+88** 哈希表 |
| CRaidType+32 = CRaidCategory* | reader `case 702 category` → `*(a1+32) = sub_140A9D170(sub_1401636B0(), &name)` |
| 其它 db 视图 | db+120/+132 = 容器 (sub_141B2AD10 遍历); db+176/+188 = raid types 容器 (sub_1414EA5E0, §4.27.1 available raid types 源) |

> ⚠ **CRaidInstance+152 def 侧锚 (定案)**: **+2600/+2624 的宿主是 CRaidType, 不是 CRaidCategory** — CRaidCategory 只有 224B, 而 CRaidType = 3064B,
> 其 ctor 在 +2600/+2624 各建一个 RH 表 (malloc 0x30 桶头), reader 键分别是
> **19200 additional_equipment** 与 **16725 essential_equipment**。⇒ CRaidInstance+152 指向的 def 是 **CRaidType*** (高置信;
> 两者 token 都在 +8, 故 token_name 取法不受影响)。

**CRaidCategory** (224B; vtable 0x142940C08; ctor 0x140A98BD0; reader 0x141591080):

| 偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +8 | uint32 | — | token (CPersistentWithToken) |
| +24 | uint8 | — | 门 (ctor 0) |
| +32 | uint32 | 19252 intel_source | **情报来源枚举**: 默认 3; 0=19238 civilian / 1=10397 army / 2=11925 naval / 3=11926 air |
| +36 | uint8 | 16733 free_targeting | 自由选目标旗 |
| +40 | CTrigger (88B) | 11562 visible | 可见条件 |
| +128 | CTrigger (88B) | 12264 available | 可用条件 |
| +216 | CString 32B | 12815 faction_influence_score_on_success | 成功后阵营影响力分 (字符串形态, 待裁) |

> sizeof = 224 (ctor `memset 0xE0` 定案)。

**CRaidType** (3064B; vtable 0x142940C88; ctor 0x140A9A170; reader 0x140A9EAF0):

| 偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +8 | uint32 | — | token (CPersistentWithToken) |
| +24 | uint8 | — | 门 (ctor 0) |
| +32 | CRaidCategory* | 702 category | 类别 (db 内建/查找) |
| +40 | 匿名结构 | 19243 arrow | 箭头参数块 (sub_140A98030) |
| +48 | 匿名结构 | 16731 unit_model | 单位模型 (sub_140A987F0) |
| +56 | CString 32B | — | (ctor; 无键映射, 待裁) |
| +88 | CString 32B | — | (同上) |
| +120 | int64 | — | 0 (ctor) |
| +128 | int64 | — | **100000** (ctor 默认 = 1.0 fixed) |
| +136 | 匿名结构 | 16687 unit_animations | (sub_140A98600) |
| +152 | 分配器对象* | — | off_143085170 |
| +160 | CTrigger (88B) | 12263 allowed | 允许条件 |
| +248 | CTrigger (88B) | 11562 visible | 可见条件 |
| +336 | CTrigger (88B) | 16728 show_target | 显示目标条件 |
| +424 | CTrigger (88B) | 12264 available | 可用条件 |
| +512 | CTrigger (88B) | 16587 launchable | 可发动条件 |
| +600 | CTrigger (88B) | 19724 launchable_from | 发动来源条件 |
| +688 | CTrigger (88B) | 14819 cancel_trigger | 取消条件 |
| +776 | 88B trigger 形块 | target type 块 (键名未反查) | isEmpty = +12/+36 双计数全零 + 伴生 +848/+850/+868/+892/+924/+73 旗 (§4.27.5 校验器直证); 伴生 dword 归属待裁 |
| +992 | CRaidSuccessLevels (1480B) | 19185 success_levels | 结果档位 (见下) |
| +2472 | CRaidSuccessFactors (104B) | 16591 success_factors | 成功率因子 (见下) |
| +2576 | 匿名结构 (88B 元素) 向量 | 19189 unit_requirements | 元素 88B {d@2576, cap@2584, c@2588, alloc@2592} |
| +2600 | 匿名结构 | 19200 additional_equipment | **std::map 红黑树** {节点 48B malloc(0x30), key = 装备类型对象, value = i32 定点 amount} — 值对象 CEquipmentRequirements (256B) 属 +2576 unit_requirements 路径 |
| +2616 | uint32 | — | **nukes 需求表#1 旁 dword** (reader 键 13517 直写; 与 +2600 表并存) |
| +2624 | 匿名结构 | 16725 essential_equipment | 同 +2600 形态 (std::map 红黑树) |
| +2640 | uint32 | — | **nukes 需求表#2 旁 dword** (键 13517 直写; 消费 = 核弹装填通道 sub_140FEC7E0: nuke_type 匹配 + max(+2616,+2640)−nukes 上限) |
| +2648 | 匿名结构 | 16588 starting_point | (sub_140A98220) |
| +2664 | 分配器对象* | — | off_143085170 |
| +2688 | 分配器对象* | — | off_143085170 |
| +2696 | uint8 | — | 0 |
| +2704 | CString 32B | 19198 unit_icon | 单位图标 |
| +2736 | CString 32B | 19199 target_icon | 目标图标 |
| +2768 | CString 32B | 16735 custom_terrain_icon | 地形图标 |
| +2800 | CString 32B | 19211 equipment_icon | 装备图标 (ctor 初值 `GFX_raid_equipment_generic`) |
| +2832 | CString 32B | 10151 custom_map_icon | 地图图标 |
| +2864 | CString 32B | 16732 launch_sound | 发动音效 |
| +2896 | CString 32B | 16736 target_loc_key | 目标 loc 键 |
| +2928 | int64 | 14467 command_power | 指挥点花费 |
| +2936 | 匿名结构 (24B 形状) 向量 | 10819 ai_will_do | AI 权重 (sub_1424C0AA0) |
| +2992 | fixed×1e-5 | 10387 range_factor | 射程系数 |
| +3000 | fixed×1e-5 | 591 max_distance | 最大距离 |
| +3016 | uint8 | 16762 unlimited_ai_range | AI 射程无限旗 |
| +3017 | uint8 | 11002 fire_only_once | 仅一次旗 |
| +3020 | uint32 | 14545 days_re_enable | 再启用天数 (ctor 默认 = dword_143331648) |
| +3024 | uint32 | 16720 days_to_prepare | 准备天数 (ctor 默认 −1) |
| +3032 | int64 | 16679 ai_min_success_chance | AI 最低成功率 |
| +3040 | uint8 | — | 0 |
| +3048 | int64 | 19251 speed_multiplier | 速度倍率 (ctor 默认 100000) |
| +3056 | uint32 | 19439 nuke_type | 核弹类型 id (sub_141099BD0) |

**通用 reader 原语表** (def 族通用):

| 原语 | 签名 | 语义 |
|---|---|---|
| sub_1424C0AA0 | (stream, dest) | **按 dest vtable [3] 分发解析子块**: `(*(*(dest)+24))(dest, stream)` = Load wrapper |
| sub_1424C0AB0 | (stream, dest, flag) | 读字符串进 dest (std::string 32B, SSO) |
| sub_1424C0A70 | (stream, dest) | 读数 (i64/f64) 进 dest |
| sub_1424C08D0 | (stream, dest) | 读 u32 进 dest |
| sub_1424C0C00 | (stream, dest) | 读 u8 进 dest |
| sub_1424C2F40 / sub_1424C2E20 / sub_1424C34F0 | (stream, token, val) | writer: u32 / 子块 / i64 |

**CRaidSuccessFactors** (104B) = vtable@0 + 三组「因子组」容器 (每组 32B = {base@0 i64, data@8, cap@16, count@20, alloc@24}):

| 偏移 | 键 (token) | 组 | 元素 |
|---|---|---|---|
| +8 | 10347 success | 成功因子组 | CRaidSuccessChanceModifier* 指针数组 |
| +40 | 16590 critical | 大成功因子组 | 同上 |
| +72 | 16734 disaster | 灾难因子组 | 同上 |

> reader [4] = 0x141591B70 (`case 10347 → +8` / `16590 → +40` / `16734 → +72`);
> 组元素 reader = 0x14158A3A0 (遍历块内 token 直到块尾) → 每 token 调工厂 0x1415917E0;
> 组聚合 = 0x14158AEE0 (遍历元素指针数组, 逐个调元素 vtable[7] 取值函数, 累加后 clamp 到 [0,100000]);
> validate [7] = 0x1415902F0: `if (success.base <= 0 && success.count == 0) → 报错`
> (串 `": success_factors - 'success' must either have positive base value or contain at least one modifier
> in order to count as valid"`, raid_database_extras.cpp:948) — 直证组布局 base@+0 / count@+20。

**CRaidSuccessLevels** (1480B) = vtable@0 + 四个「结果档」元素 (各 368B; **子块起点 = +1000/+1368/+1736/+2104**, 空判 = 档内 +56/+232/+408 三 qword 全零 — §4.27.5 校验器 :121 直证):

| 偏移 | 键 (token) | 档 |
|---|---|---|
| +8 | 19186 failure | 失败 |
| +376 | 19187 limited_success | 有限成功 |
| +744 | 10347 success | 成功 |
| +1112 | 19188 critical_success | 大成功 |

**结果档元素** (368B):

| 元素内偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +0 | int64 | 19250 destroy_additional_equipment | 摧毁额外装备数 (ctor 默认 100000) |
| +8 | 匿名结构 (88B, count@+20) | 16594 actor_effects | 发动方效果块 (读掩码 2048) |
| +96 | 匿名结构 (88B, count@+20) | 16723 victim_effects | 受害方效果块 (读掩码 2048) |
| +184 | 匿名结构 (88B, count@+20) | 16589 division_effects | 师级效果块 (读掩码 256) |
| +272 | CString 32B | 16768 custom_sound | 自定义音效 |
| +304 | CString 32B | 19493 visual_effect | 视觉特效 (sub_14158A590) |
| +336 | CString 32B | — | 无键映射 (待裁) |

> validate [7] = 0x1415903D0: 检查 12 个 dword = 4 档 × 3 效果块的 count@+20
> (偏移 36/124/212/404/492/580/772/860/948/1140/1228/1316, 12/12 命中 ⇒ 元素 stride 368 与块内偏移三重互证);
> 全零 ⇒ 报错 `": success_levels must have at least one non-empty raid outcome in order to count as valid"`
> (raid_database_extras.cpp:712)。

**CRaidSuccessChanceModifier 基类槽位契约** (两派生 = **NRaids::CRaidSuccessChanceStandardModifier** (48B, vtable 0x1429DA408) / **NRaids::CRaidSuccessChanceCustomModifier** (208B, vtable 0x1429DA468; COL 0x142D1F518/0x142D1F598), vtable同序对照):

| 槽 | Standard (vtable 0x1429DA408) | Custom (vtable 0x1429DA468) | 语义 |
|---|---|---|---|
| [0] | 0x1401C90A0 | 0x14158ABA0 | 析构 |
| [1] | 0x141591B10 | 0x1415915B0 | **reader** |
| [2] | 0x1415906B0 | 0x1415906A0 | **IsValid**: Std = `weight(+16)≠0 ‖ start_weight(+40)≠0`; Custom = `formula.count(+100) ≥ 1` |
| [3] | 0x14158C870 | 0x14158C860 | **CanTargetAffect**: Std = token 白名单; Custom = `u8@+200` |
| [4] | 0x14158C840 | 0x14158C830 | **CanActorAffect**: Std = token ∈ {12335 air_superiority, 12524 intel, 13025 resistance}; Custom = `u8@+201` |
| [5] | 0x141590610 | 0x141590600 | **UsesScopes(mask)**: Std = token 白名单; Custom = sub_141592760(this, 264, 1) (264 = bit8\|bit256) |
| [6] | 0x141592610 | 0x141592550 | 目标相关谓词 (Custom: `+132 ≠ 0` 门) |
| [7] | 0x14158C4E0 | 同址 (基类共享) | **Compute(target)** — 单目标求值; 因子聚合链的调用点 = `(*(vtable+56))(elem, &out, target)` |
| [8] | 0x14158C5A0 | 同址 (基类共享) | **Compute(target, arg4…arg6)** — 6 参求值 |
| [9] | 0x14158DF40 | 0x14158DE40 | 目标解析 + 诊断 (`"Failed to find target state/province for raid when computing success chance modifier"`) |
| [10] | 0x14158E980 | 0x14158E8A0 | 断言 `"Non-unit success chance modifier computed based on only a unit"` (raid_database_extras.cpp:1227); sub_140535110 / sub_140541DC0 / sub_1405520E0 三件套 = CVariables 局部作用域 + 求值 (推定 = tooltip/求值包装) |

> 槽 [7]/[8] 两派生**同址** ⇒ 定义在基类且不被覆写; [0]-[6]/[9]/[10] 逐派生覆写。
> ⚠ **契约形态**: 本族 = 精简 11 槽 def 侧契约 — [1] = ParseKey 单键 reader (由
> sub_14158A1B0 块循环驱动, 非逐键 switch 大表), **无 Save/Load wrapper / 无 writer**
> = 不入存档的 def 侧脚本对象 (运行期事件也不加修正器 — 全 exe 唯一构造点 = 工厂);
> 与宿主 CRaidSuccessFactors 的 CPersistent 九槽形态两层并存, 勿混排。
> Std [3] CanTargetAffect 白名单 = {11058 interception / 12166 anti_air / 12237 radar /
> 12335 air_superiority / 13025 resistance / 16599 enemy_units}; [5] UsesScopes 白名单 =
> {10406 strength / 11930 experience / 11958 air_defence / 11979 organisation / 12196 recon /
> 12229 strategic_bomber / 12238 air_agility / 12668 reliability} (mask 实参被忽略);
> [6] 参与门: Std = 仅 resistance 非 0 时查 owner-target 关系 (sub_140E7E780);
> Custom = enable CAndTrigger 门。Compute [7] = 先查 [6] 门 (真 → 贡献 0), 否则
> [9]/[10] 取输入值 → 区间映射; owner = CRaidInstance+88 对象 +8 tag, target = inst+160。
> 工具函数 RTTI 直证: `NRaids::NUtils::BuildRaidSuccessFactorsTooltip(CRaidInstance const&, CToolTip&)`
> 与 `BuildRaidWarningTooltip(...)` 的 lambda 参数类型 = `CRaidSuccessChanceModifier const&`
> ⇒ 修正器对象被 tooltip 逐条遍历 (高置信)。

**Std 输入值取值表** ([9] 无单位 / [10] 带单位两变体; token 分派全表):

| token | 取值 |
|---|---|
| 12335 air_superiority | 目标州→战略区域 owner 空域数据: `100000×x/(x+y)` (分母 ≤0 → 50000); 区域缺失报 "Failed to find target strategic region..." |
| 12524 intel | 56B 情报结构五项和 − 第六项 (sub_140FE6110/150) |
| 13025 resistance | 目标州 `*(state+632)` 抵抗值 |
| 16599 enemy_units | 目标省 +272 容器逐国: `tag==victim ∨ 同阵营` 累加 100000 (省内敌国计数) |
| 11058 interception | 目标区域机翼遍历: 类型==4 ∧ 基地==区域 → 累加 `100000×wing+124` |
| 12166 anti_air | `100000×(int)州防空等级 sub_1409D8110` |
| 12237 radar | owner+4344 覆盖查 (0 → 0, 否则 100000 二值) |
| 12229 strategic_bomber / 12238 air_agility / 12668 reliability / 11958 air_defence | 单位族: 机翼/师 + 目标省 → 对应 getter (strength = 师 vtable 槽[34] / organisation = 槽[36] / experience = sub_141466640 / recon = sub_140BFD6E0) |
| 其它 | out = 0 |

**修正器字段表** (偏移升序):

| 偏移 | Std | Custom | 键 (token) | 名称/语义 |
|---|---|---|---|---|
| +8 | uint32 | uint32 | — | token = 修正器 id (air_superiority / intel / resistance / …) |
| +16 | int64 | int64 | 593 weight | 权重 |
| +24 | int64 | int64 | 16596 reference | 参考值 (ctor 默认 100000) |
| +32 | int64 | int64 | 16601 start_reference | 起始参考 |
| +40 | int64 | int64 | 16600 start_weight | 起始权重 |
| +48 | — | uint32 | 10646 scope | **作用域位掩码** (ctor 0): 读值 token 分派 439 state→2 / 10394 country→4 / 10403 unit→256 / 19478 character→8, 其它值报 "Invalid scope type for custom raid success chance modifier"; 此值 = UsesScopes 快路径缓存掩码 |
| +56 | — | CMeanTimeToHappen 56B | 16675 formula | **公式块** (ai_will_do 同族: 基值 + 条件加权条目; ctor sub_1405516A0; IsValid 所查 count@+44 即本块容器 +100) |
| +112 | — | CAndTrigger 88B | 10376 enable | **启用条件** (ctor sub_140549F40, 默认 +144 = 10600 and; slot[6] 求值出口 = 其 vtable[+24]) |
| +132 | — | uint32 | — | 计数/门 (slot[6] 用) |
| +200 | — | uint8 | 16676 can_target_affect | 默认 0 |
| +201 | — | uint8 | 16677 can_actor_affect | 默认 1 |

**工厂 0x1415917E0 分派规则** (按 token; dump 394357-394539 逐句实读):

| 修正器 token | 产出 |
|---|---|
| 11398 base | **不建对象** — sub_1424C0A70 读数直落组 base 字段 (组+0) 后 return |
| 白名单 15 token (10406 strength / 11058 interception / 11930 experience / 11958 air_defence / 11979 organisation / 12166 anti_air / 12196 recon / 12229 strategic_bomber / 12237 radar / 12238 air_agility / 12335 air_superiority / 12524 intel / 12668 reliability / 13025 resistance / 16599 enemy_units) | **Standard** (malloc 0x30; token = 脚本 token 本身; 无 IsValid 门直入组容器) |
| 其它任意 token | **Custom** (malloc 0xD0; token = 键名串 FNV 哈希 sub_1424BB460; 解析块体后过 vtable[2] IsValid 门, 假 → 报 "Custom success chance modifier not correctly set up" 并销毁) |

> 原「11398 → Custom / 其它任意 token → Standard」两行互换系误记, 说废 (PE + dump 双重直读)。

> Custom 建好后调 `(*vtable[2])(obj)` 校验, false ⇒ 报 `"Custom success chance modifier not correctly set up"`
> (Custom 的 IsValid = formula 至少 1 条)。

**成功率计算链** (运行期反推 def 消费):

| 步 | 内容 |
|---|---|
| def 侧 | CRaidInstance+152 → CRaidType*; CRaidType+2472 → CRaidSuccessFactors (.success@+8 / .critical@+40 / .disaster@+72); CRaidType+992 → CRaidSuccessLevels |
| 运行期 | 0x140FEA7B0 = CRaidInstance 结果判定 (调试重判变体 — 控制台强制档命令调用; 生产链内联于 0x140FEE5F0, 数值同码): `v9 = 0x14158F200(risk_level)` 基础成功率 (全局槽 qword_143331888/9A0/B00); `v11 = 0x14158C770(factors+2472) → 0x14158AEE0(factors+8)` success 组聚合; `v12 = 0x14158C2C0(factors+2472)` 三组聚合和 + risk 灾难基值 (全局槽 qword_1433311C8/2A8/390); `v8 = 0x14158AF70(factors+2472) → 0x14158AEE0(factors+40)` critical 组聚合; `v10 = 0x14158C2C0(...)` 再取一次 = disaster 组; roll = random_fixed %1e5, file:line 实参仅作日志不作种子 |
| 阈值 | `成功阈值 v2 = clamp(v9 + v11, 0, 100000 − v12)` |
| 判定 | `roll < 阈值 × critical_sum / 100000` → 4 CRITICAL_SUCCESS; `roll < 阈值` → 3 SUCCESS; **roll ∈ [阈值, 阈值+disaster) → 1 FAILURE (灾难带); roll ≥ 阈值+disaster → 2 LIMITED_SUCCESS** (低 roll 好; 阈值 = clamp(risk+success, 0, 100000−disaster), 断言 "Disaster risk and success chance sum to more than 1" raid_instance.cpp:491); 结果经 0x140FEC8B0(inst, outcome) 写 inst+60 outcome 并结算 |

| 全局槽 | define 名 | 写入者 |
|---|---|---|
| qword_143331888 | RAID_LOW_RISK_SETTING_SUCCESS_MODIFIER | sub_140992BC0 |
| qword_1433319A0 | RAID_MEDIUM_RISK_SETTING_SUCCESS_MODIFIER | sub_1409931D0 |
| qword_143331B00 | RAID_HIGH_RISK_SETTING_SUCCESS_MODIFIER | sub_1409925B0 |
| qword_1433311C8 | RAID_LOW_RISK_SETTING_DISASTER_MODIFIER | sub_140992900 |
| qword_1433312A8 | RAID_MEDIUM_RISK_SETTING_DISASTER_MODIFIER | sub_140992F10 |
| qword_143331390 | RAID_HIGH_RISK_SETTING_DISASTER_MODIFIER | sub_1409922F0 |

> 两族选择器同构: `0x14158F200(risk)` 返 success 基值 / `0x14158DBB0(risk)` 返 disaster 基值,
> 均按 `risk==0→LOW / 1→MEDIUM / 2→HIGH / 其它→0` 三分支。
> risk_level 来自 CRaidInstance+64 (0=LOW / 1=MEDIUM / 2=HIGH), 与 §4.27.1 一致 (互证)。

**三因子组的角色分工** (由 0x140FEA7B0 读出):

| 组 | 聚合函数 | 在判定式中的角色 |
|---|---|---|
| success (+8) | 0x14158C770 → 0x14158AEE0(factors+8) = 纯组内求和 | **抬高成功阈值**: `v2 = clamp(v9 + success_sum, 0, 100000 − disaster_total)` |
| critical (+40) | 0x14158AF70 → 0x14158AEE0(factors+40) = 纯组内求和 | **缩放暴击阈值**: `critical_threshold = v2 × critical_sum / 100000` |
| disaster (+72) | 0x14158C2C0 → 组内求和 + risk 灾难基值 | **压低成功上限**: `max = 100000 − disaster_total` |

> 0x14158C2C0 被调两次: 第一次取 v12 作 clamp 上界, 第二次取 v10 供断言 `v2 + v10 > 100000` 检查 —
> 纯函数同参同值, 故断言只在 clamp 走了 `v2<0→0` 分支时才可能触发 (高置信)。
> 结果码与 §4.27.1 CRaidInstance+60 outcome 枚举 (0 NONE / 1 FAILURE / 2 LIMITED_SUCCESS /
> 3 SUCCESS / 4 CRITICAL_SUCCESS / 5 CANCELED) 逐一吻合 (定案)。

**单因子求值函数表** (Compute 内层):

| 函数 | 作用 |
|---|---|
| 0x14158C450 | **区间映射**: `out = clamp(start_weight + (weight − start_weight) × (ref − start_reference) × 100000 / (reference − start_reference), min(start_weight, weight), max(start_weight, weight))` — 输入度量在 start_reference 处贡献 start_weight、reference 处贡献 weight, 两点线性插值、两点外截断; **除零 (reference == start_reference) 贡献 = max(start_weight, weight)** (quot = 0xFFFFFFFF 加基项后截断到上端, 非 0) (原式常数项与斜率方向均误, 说废; dump 3716756-3716798 逐句) |
| 0x14158AC10 | **作用域注入**: 按 UsesScopes 掩码写 CVariables (+176 局部变量表); 无条件首步 sub_141592B00 = 目标省/州/leader 基础 scope (SRaidTarget 字段), 掩码位 **2 = state (439, sub_140FE6C70 → 州 id) / 4 = country (10394, owner_tag) / 8 = character (19478, 乘员) / 256 = unit (10403, 师/翼)** (reader 键值分派 + 注入函数双重直证; 原「province/state/country/leader」含糊措辞说废) |
| 0x141592760 | **UsesScopes 实现**: Custom = 扫 formula 触发器的 scope 掩码; `(v3 & a2) != 0` 快路径 (v3 = 缓存掩码@+48) |
| 0x14158DF40 | **目标解析 + 诊断** (state/province 缺失时报错) |

**需求判定 — CRaidType+2576 的 88B 复合元素** (sub_140A965F0 追加, stride 88):

| 元素内偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +0 | 匿名结构 (24B 形状) 向量 | 12110 equipment | CEquipmentRequirements 数组 {d@0, cap@8, c@12, alloc@16}, 元素 256B (ctor sub_14158AAB0) |
| +24 | CBattalionTypeRequirements vtable | 19191 battalion_types | **CBattalionTypeRequirements** 内嵌子对象 |
| +32 | 匿名结构 (24B 形状) 向量 | — | battalion_types 记录数组 {d@+32, cap@+40, c@+44, alloc@+48}, **记录 20B** |
| +56 | OWORD | — | 直拷字段 (CopyAssign) |
| +72 | OWORD | — | 直拷字段 |
| +80 | uint8 | — | 0 |

> 元素 reader = sub_140A989E0 → 每 token 调 0x141592080: `12110 equipment` → 追加 256B
> CEquipmentRequirements 元素 → sub_1424C0AA0 分发其 reader 0x141590CA0;
> `19191 battalion_types` → sub_1424C0AA0(stream, elem+24) → 分发 CBattalionTypeRequirements reader 0x141590AC0。

**CBattalionTypeRequirements** (this = 元素+24; vtable 0x142940BB8; ctor 0x140A9A6C0 写 `*(a1+24) = vftable`):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 匿名结构 (24B 形状) 向量 | battalion type 记录数组 {d@+8, cap@+16, c@+20, alloc@+24} |

> **记录结构 (20B, 定案)**: `{token u32@+0 (营/子单位 id), min u32@+4 + valid u8@+8, max u32@+12 + valid u8@+16}` —
> reader 以 `v6 += 5` (5 dword = 20B) 步进; 块内键 **675 min / 676 max** 由 sub_141589AA0 写入 {值, valid} 对;
> 重复 token 报 `"duplicate battalion type entry"`。
> **校验 (slot[7] = 0x14158FB30)**: 遍历 +32 记录容器, 对每条记录的 token 查
> `sub_140AC4FA0(qword_14332F090, token)` (子单位定义库单例) 的 +16 有效旗, 无效 ⇒ 报
> `"'<name>' is not a valid sub-unit definition"` (raid_database_extras.cpp:253)。
> ⇒ **判定库 = qword_14332F090 (子单位/营定义库)**。

**CEquipmentRequirements** (256B 元素; vtable 0x142940B68; reader 0x141590CA0):

| 偏移 | 类型 | 键 (token) | 名称/语义 |
|---|---|---|---|
| +8 | CEquipmentGroup vtable | — | CEquipmentGroup 内嵌子对象 (ctor 后覆写为 CAnonymousEquipmentGroup) |
| +16 | uint32 | — | 装备组 id/type (reader 键 225 从解析出的组写入) |
| +24 | CString 32B | — | 组名 {buf@+24, size@+40, cap@+48} |
| +56 | CString 32B | — | 组描述 {buf@+56, size@+72, cap@+80} |
| +88 | 匿名结构 (32B 形状) 向量 | — | (sub_14011DF40) |
| +112 | CAnonymousEquipmentGroup vtable | — | 第二个 CAnonymousEquipmentGroup 子对象 |
| +120 | 匿名结构 (32B 形状) 向量 | — | — |
| +144 | uint8 | — | 旗 |
| +152 | 匿名结构 (32B 形状) 向量 | — | — |
| +176 | uint8 | — | 旗 |
| +184 | 匿名结构 (32B 形状) 向量 | — | — |
| +208 | uint8 | — | 旗 |
| +216 | 匿名结构 (24B 形状) 向量 | 15211 modules | 模块 id 数组 (元素 24B, sub_1403099D0 读) |
| +240 | int64 | 417 amount | 数量 (sub_141589AA0 读) |
| +244 | uint8 | — | 0 |
| +252 | uint8 | — | 0 |

> sizeof = 256 (`memset 0x100` + `<< 8` stride 定案)。
> 两处需求表挂载: CRaidType+2600 ← 键 19200 additional_equipment; CRaidType+2624 ← 键 16725 essential_equipment (同 reader)。
> 容器 reader 0x141590CA0 三键: **225 type** → 从 CEquipmentGroup 逐字段解析出 256B 元素
> (sub_140A08390 取组名 → CAnonymousEquipmentGroup 装配 → 拷入 +8..+208); **417 amount** → 元素 +240;
> **15211 modules** → 元素 +216 容器。
> **校验 (slot[7] = 0x14158FCD0)**: 遍历 +88 容器 (每 40B 一条字符串记录) 对每条查
> sub_1409F8840 / sub_1409F7F60(qword_14332EEC0, …) (类型/原型库)、sub_140F88330 (类别判定)、
> qword_14332EED0 哈希表 (装备组), 全不中 ⇒ 报
> `"'<name>' is neither a type, an archetype, a category nor an equipment group"` (raid_database_extras.cpp:81);
> 随后遍历 +216 模块容器对每模块查 sub_1409F8460(qword_14332EEC0, id) ⇒ 无效报 `"'<id>' is not a valid module"` (行 91)。
> ⇒ **判定库 = qword_14332EEC0 (装备类型/原型库) + qword_14332EED0 (装备组库)**。

> 与 §4.27.1 CRaidInstance+272 装备池 / +336 nukes 的接缝: def 侧的 CRaidType+2600 (additional) /
> +2624 (essential) 是 GUI「装备需求行 required 列」的数据源, 运行期 current 列来自 inst+272
> (CEquipmentVariantPool) — 与 §4.31.28 记法一致, 仅宿主类需由 CRaidCategory 改为 CRaidType。

#### 4.27.2b CRaidInstance vtable槽位与 CEquipmentDistributable 契约 (reader 侧定案)

主vtable 0x142983A78 17 槽: [2]=writer 0x140FEF9C0 / [4]=**reader 0x140FEE810** (19 键全表, 10 键新定名: 225 type/107 target/10403 unit/10383 raid_source/10465 end_date/10519 phase/19011 outcome/19196 risk_level/19197 auto_launch_option/19206 detected) / [8]=**读档重挂 0x140FEDEB0** / [11..16] = 第二vtable 0x142983AD0 同块排放 (0x142983AD0 − 0x142983A78 = 88)。**CEquipmentDistributable 六槽契约** (第二基): [1]=UsesEquipment 0x140FEE450 (两 map contains → 定点 1e5/0) / [2]=Distribute 0x140FEE540 (this = inst+24 → −24 调整 thunk; 按两 map 需求缺口装填 inst+272 池, 返未满足量) / [3]=GetPriority = status+96×1e5 / [4]=GetId {0, inst id, kind=14} — 纯虚槽唯一覆写。

实现层增补: 剩余小时估算 sub_140FEA4A0 (phase2 = 24×days−prep_time; phase4 = ceil(剩余距/时距), GUI 进度消费); SetPreparationProgress sub_140FEF570 (消息串直证方法名); StartRaid 成功失败两路尾都**无条件挂 system+240 预警池** (sub_1419ABC80); status+16 dummy = 占位 CRaidInstance。

#### 4.27.3 相位机执行链与目标选择

**管理器小时入口** (挂点 = HourlyUpdate 计时域 12, §4.2.14/§4.2.6):
sub_140E86100 (gs+1008) 全串行两遍 (遍 a1+216 分组数组, 176B/组, 组内 +128
实例指针表倒序): 遍一 = 逐实例下述每小时推进链; 遍二 = 尾段**预警判定**。

**每实例每小时 sub_140FED6C0 顺序** (raid_instance.cpp, 定案): ① phase==5 →
断言 "Updating a raid that has been ended!" 返回; ② 单位可解除指派检查
(sub_1414670A0: 师存在 ∧ assignment 一致) 失败 → 取消
"raid_canceled_cannot_unassign_unit"; ③ 单位在源区分流 (sub_141466410 师在源
州/翼在源区 ∨ sub_141466F20 可抵达源; 不在 → "raid_canceled_cannot_reach_source"
/ 无单位名 → "raid_canceled_no_unit"); ④ 源射程复查 (仅源 type 3/4 且
phase≠4; 失败 → "raid_canceled_source_moved_out_of_range"); ⑤ 结构大检查
(源有效 sub_141593930 / 源省可解析 sub_141593A60 / 源合法性 (舰存活 ∨ 源省
owner==属主 ∨ 同阵营) / def+目标有效 / 单位可解析+属主一致 / unit_requirements
(type+2576) 任一满足 sub_140A9CD50 — 任一失败 → EndRaid(5) 无理由取消);
⑥ 每相位推进 sub_140FEF850; ⑦ 1→2 迁移 (CanStartPreparing sub_140FEB990:
仅 phase 1 可真 = 单位在源 + 装备 + 门链第 4 层; 断言 :576) → SetPhase 2;
⑧ 自动发射检查 sub_140FED100。

每相位推进 **sub_140FEF850**: ① cancel_trigger (type+688 块) 求值真 →
EndRaid(5) (days_to_prepare≤0 回退 BASE_DAYS_TO_PREPARE dword_143330E64); ② 有效性复查 (phase<4 → 门链第 4 层 / ≥4 → 第 6 层; 失败 →
EndRaid(5)); ③ **相位 2 (PREPARING)**: 门全过时剩余 = 24×days_to_prepare −
prep_time(+68) >0 → ++(+68), ≤0 → 到期; ④ **相位 4 (IN_PROGRESS)**:
distance(+80) += 每小时行程 sub_141465B50; 剩余小时 <1 → 到期。

计时到期 **sub_140FEE5F0**: 相位 2 → 直迁 3 (裸写无副作用); 相位 4 →
**掷骰判档** (roll = random_fixed %100000; 四值链 = risk 基值 sub_14158F200 /
success 和 sub_14158C770 / critical 和 sub_14158AF70 / disaster 和
sub_14158C2C0; 阈值 = clamp(risk+success, 0, 100000−disaster); 映射见
§4.27.2 判定行) → EndRaid(outcome)。

自动发射 **sub_140FED100** (3→4): 门 = auto_launch(+48)≠0 ∧ CanLaunch
(sub_140FEB800, 仅 phase 3 可真); 桶 = min(5×chance/100000, 4) ≥
auto_launch_option(+52) → 发射记账 → SetPhase 4。SetPhase **sub_140FEA1A0**:
副作用 →2 清 prep_time / →4 清 distance。手动发射 **sub_140FEE320 LaunchRaid**
(调用者 CExecuteRaidCommand::Execute sub_141B32E70)。发射记账
sub_1414E9FA0: fire_only_once (type+3017 → 插 used_types) + 目标冷却
(type+3020 days>0 → status+72 追加 64B 元 {vtable@0, CRaidType*@+8,
**SRaidTarget@+16..+55**, days@+56})。

供弹端 (引擎侧, 定案): CCountry::DailyUpdate → **sub_141097D50** 产弹 (§4.3.10a) + **sub_141098240** 自动把可用弹装填就绪核突袭 (写 inst+336 族) — inst+336 的引擎侧写者。

结算 **EndRaid sub_140FEC8B0(inst, outcome)** 十五步 (定案): ① phase=5 +
outcome(+60); ② 重建 active/ended 两表; ③ 释放源 + 解除单位指派; ④
victim_country(+464) 解析; ⑤ 档位 def (outcome 1→type+1000 / 2→+1368 /
3→+1736 / 4→+2104); ⑥ AI 通知 (strategic ai+8392 环 80B 元素); ⑦ 视效
(档位 +304/+336 串 → 目标省挂实体); ⑧ **效果执行 sub_14158D490**: actor 块
(level+8)/victim 块(+96) 以 raid 作用域、division 块(+184) 以单位作用域各调
块 vtable 槽12 Execute; 尾 destroy_additional_equipment (数量 clamp [0,100000] →
按比例从 inst+272 池抽取销毁); ⑨ nukes(+336)=0; ⑩ **装备归还 sub_140FEF310**
(def 旗 &1 → 归还国库存; 分队路径旗 → 分队; 核弹: inst+336>0 → 消耗
country+4880 数组 [72×nuke_type(type+3056)] 槽); ⑪ 指挥点释放 (inst+344
分配器); ⑫ end_date = gs+1128; ⑬ 取消时 show_for += 属主/目标国; ⑭ 非 5:
show_for 补交战国 + active→ended 迁移 + **outcome 3/4 → 阵营影响力分**
(category+216 faction_influence_score_on_success); ⑮ 预警池摘除
(system+240)。

日更 **sub_1414E9540** (country+1156>0 门): 冷却元素 days−1 到期压缩删除 /
CanLaunch 天数累计 (+72) / ended 淘汰 (show_for 非空跳过; 天龄 >
RAID_OUTCOME_REPORT_DAYS_TO_LIVE → 销毁; "DateEnded.has_value()"
country_raid_status.cpp:176)。

触发器门链 (六层嵌套, 每层含下层; 定案): ① visible (type+248) sub_140A9CEB0
→ ② +fire_only_once 已用 sub_140A9B5C0 → ③ +show_target (type+336)
sub_140A9B420 → ④ +!目标冷却 + available (type+424) sub_140A9C4B0 → ⑤
+launchable (type+512) sub_140A9C790 → ⑥ +launchable_from (type+600)
sub_140A9C990; 变体: 严格门 sub_140A9C430 / 显示门 sub_140A9CBB0; 独立
cancel_trigger sub_140A9F720。每小时复查只到第 4/6 层; 相位 4 飞行中仅
cancel_trigger 可拦。装备检查 sub_140FE9EB0: new_phase==1 跳过; essential
(type+2624) 与 additional (type+2600) 两表对 inst+272 池 + inst+336 nukes
均须满足。

速度/距离 (定案): 每小时行程 sub_141465B50 = 海军型 NAVAL_TRANSFER_BASE_SPEED
×NAVAL_SPEED_MODIFIER / 舰源 = 舰速×LAND_SPEED_MODIFIER / 空运 = 最快
transport (def 旗&0x100000) 属性62×LAND_SPEED_MODIFIER (无 → 断言
raid_unit.cpp:532 后 base = 1e5 兜底); 终式 = RAID_UNIT_SPEED_MULTIPLIER × base ×
type+3048 speed_multiplier。源→目标距离 sub_1415934A0: type 0/1/3/4 →
路径距离 ×100000/300000 (**÷3**); type 2 海军 → gs 系。射程 sub_141593390:
AI 且 type+3016 unlimited_ai_range → 直通; 否则 距离有效 ∧ !(type+3008 旗 ∧
距离>type+3000) ∧ 单位射程 ≥ 距离。

扫省热路径宿主 (定案): **hourly 入口 sub_140E86100 自身** — 首语句经冷尾
thunk 0x1419608A0 调 sub_14195ED40 扫省再尾跳检测 (反编译器曾把它伪装成
_DeleteExceptionPtr(a1+8) — ICF 假名; PE 全镜像 E8 扫描直证唯一 call);
驱动链 = sub_1401DF400 (§4.2.6 步5) → 突袭域【扫省+检测 → 逐国相位机 →
预警】。next_target 轮转游标消费者 = **sub_14195E7E0 DetectTargets** (tbb
任务符号直证; 钳制 ∈[0,detectable_num) 后 (i+next_target)%num 轮转选目标
逐国检测, 尾 (budget+next_target)%num 推进); next_state (mgr+144) 对称,
唯一读/写方 = sub_14195ED40。

**StartRaid 尾声 sub_140FEC020 = 海军装备征用 (定案)**: 0x80004003C1 =
EQUIPMENT_NAVAL 装备旗掩码 (switch 命名表直证); essential/additional 表含
海军旗才继续 → 三层枚举己方舰队→特混舰队→舰船, 货舱 (舰+96, 16B {装备,量})
按到源省路径距离升序抽入 inst+272 池, **捐赠过的舰被除名销毁**
(sub_140D76BD0 = CTaskForce::ScuttleShip 断言直证)。cc+1156 门 = owned_states
计数 (无州国/流亡跳过冷却维护只清冷却)。**sub_140A9B350 定案 = CP 花费门 (旧 allowed 判读废)**
(type+2928 经 sub_1406FCEF0: 修正 331/333 − cc+504 已分配 ≥ 花费, strict 另查
cc+496) ∧ essential 装备可达门 (CNuke amount + 护航 + type+2624 表) — 非
allowed (type+160); sub_140A9C6D0 = 同体参序变体。档位 +336 = visual_effect
块的 **animation 成员** (token 64; +304 = token 438 entity, 块键 19493; 音效
另列 +272 custom_sound); 消费 = 目标省实体上生成 entity 原型按 FNV 名挂动画。
AI 可用类型 = 两段过滤 (sub_140E82A80 从 status+104 容器按 (tag,category,
target) 收集 → 就地压缩保留 CP+essential 门 ∧ visible+未用; available/
launchable 留发射门再查) (定案)。

目标选择 (定案): mgr 侧 **sub_14195ED40 增量轮转扫省** (预算 =
MAX_STATE_TARGETS_TO_EVALUATE_PER_HOUR; 每省 get-or-create 80B
CRaidTargetStatus {existing@0, detectable@4, SRaidTarget@8, 旗@48, 容器@56});
**GetTargetsForType sub_140E82C00** 三重过滤 (受害国非己非同阵营 ∧ 建筑模板
+884 旗 / type+776 目标种类块 (建筑查表 / 省份白名单 / 全通旗) / 严格门∨显示
门) → 40B SRaidTarget 候选。AI 侧: 节拍 = 每日 ∧ RAIDS_ENABLE_AI ∧ 错峰
(RAIDS_CREATE_FREQUENCY_DAYS); 建计划 (打分 = 战略欲望 × 近期打过同目标因子
RAIDS_AVOID_SAME_TARGET_FACTOR × ai_will_do; **「近期」= 环条目天龄 ≤
RAIDS_AVOID_SAME_TARGET_DURATION_DAYS 180 天**; 欲望项 = clamp(1000×desire+1e5,
≥0); 已在打跳过) → 匹配
(**「最近源×最优单位」二重贪心**: 源按路径距离升序 / 单位按商式
`500×max(1+Σ成功率修正, 0) ÷ (1+0.1×km)` 降序 (km = MAP_SCALE_PIXEL_TO_KM
7.114 × 路径距, 3× 与 ÷3 相消), 首个过射程+适配) → 维护 (可用 CP 不足 → 取消
低分在飞 RAIDS_SCORE_DIFF_TO_CANCEL; **nr_days_launchable > 
RAIDS_CANCEL_AFTER_DAYS_LAUNCHABLE 60 → AI 取消**) → 发射 (CanLaunch ∧ 成功率
(success 组聚合, 不含 risk 基值) ≥ ai_min_success_chance
(type+3040 旗?type+3032:RAIDS_MIN_SUCCESS_FOR_LAUNCH) → CExecuteRaidCommand)
→ 创建 (**门 = 可用 CP ≥ RAIDS_COMMAND_POWER_CAP_TO_CREATE** (资源门非冷却);
CCreateRaidCommand risk=MEDIUM / auto_launch=0)。玩家侧 CCreateRaidCommand
ctor sub_141B319B0 (a7 risk→+168 / a8 auto_launch→+172) → Execute → CreateRaid
→ StartRaid **sub_140FEE030** (指挥点分配器建立+扣费 type+2928; 失败断言
"Insufficient command power" :350; 成功 → phase=1)。

CRaidType 新字段: +776 目标种类过滤块 / +848 核突袭旗 (nuclear_raids 专路) /
+3008 max_distance 有效旗 / +3040 ai_min_success_chance 有效旗 (定案)。

**预警判定** (管理器遍二, 对未置旗 (+400==0) 实例, 定案): 取**受害国**
CCountryIntel (国家+4072, §4.11.7) 矩阵中**发起国行** (inst+88+8, 32B = 4×int64
定点 civilian/army/navy/air), 列号 = 突袭类型定义
`*(*(item+152)+32)+32` 0..3 四象限选一; 与 define
`NIntel.RAID_MIN_INTEL_FOR_WARNING_ON_LAUNCH`×100 (defines_intel.h:242) 比较:
**相位 2 达标线随准备进度从 10^7 线性降到 define 值 (严格 >), 相位 3/4 为定值
(取 ≥)**; 运行期只用 ON_LAUNCH 一档 — HALFWAY/EARLY 两 define 仅情报台账 GUI
消费; 达标
置 +400 旗并经 sub_1419ABC90 按双侧相关度挂入 +240 预警池 (消费方 = alert
id 73-77 族)。方向定案 = `[A][B]` = A 关于 B 的情报 (CAddIntelEffect::Execute
0x14034A8D0 交叉验证)。

#### 4.27.4 突袭创建状态机 GUI 全链 (raid_gui_manager.cpp; 5 函闭环 — ERaidCreationStep 枚举 / 状态机三入口 / 刷新执行体)

簇清册 (体内 cpp 锚/RTTI 5/5):

| 函数 | 行数 | 体内锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_14129D580 | 421 | 断言 :227/:246 + RTTI `CBuildingReference::vftable` | 状态机行列表刷新执行体 (step 1 单位候选 / step 2 源建筑候选) | 新 |
| sub_14129B1C0 | 107 | 断言 :454 + gamestate.h:1116/1117 | CRaidGuiManager::SelectSource (step 2→3 + 发射) | 已收 VA, 机制闭环 |
| sub_14129B670 | 93 | 断言 :423 | CRaidGuiManager::SelectUnit (step 1→2 + 唯一源自动级联) | 已收 VA, 细化 |
| sub_14129B4A0 | 93 | 断言 :366/:379 | CRaidGuiManager::SelectTarget (step 0→1 状态机入口) | 已收 VA, 身份细化 |
| sub_14129C0E0 | 44 | 错误日志 :981/:987 | CRaidGuiManager::ActivateNukeCategory (核类目激活入过滤器) | 新 |

**ERaidCreationStep 枚举 (断言串三名直证)**: 0 = WaitingForTarget (:366/:379) / 1 = SelectingUnit (:423) / 2 = SelectingSource (:454) / 3 = (名未取; SelectSource 完成态, 行件反馈段跳过条件 step != 3, 推定)。

**状态机全链**: SelectTarget: step 0→1, 写 mgr+80 数据宿主 + mgr+88 40B SRaidTarget 快照 + 地图模式切换 (sub_140E139B0+sub_140E16B80) + 输入态 + 选择集服务 → 刷新执行体。SelectUnit: step 1→2, 写 mgr+128 16B 单位引用 {师 idpair, 翼 idpair} → 刷新 (16B 单位候选排序灌 CRaidSetupView) → **唯一源时自动级联 SelectSource**。SelectSource: step 2→3, 暂存源行件关键字段 mgr+144..+195 → mgr+280 非 0 时按 gs 选国组装请求 (+152 = 48B 目标块; sub_140FEF660 写 64B CRaidSourceItem; sub_140FEF6B0 写单位引用) → sub_141B2D0D0 派发。刷新执行体 (sub_14129D580): step 1 = 16B 单位候选 (sub_1411612D0 从 mgr+200/+212 生成; 排序键 ctx = {*(mgr+80)+2480, …}; ≤32 插入排序 / >32 归并) → sub_141B31240 灌视图; step 2 = 56B 源元素 (mgr+224 数组 n@+236) → sub_1415934A0 变换 → 64B CRaidSourceItem 内联 (+32 覆 CBuildingReference vtable / +56 距离 — §4.27.1「64B 扩展版」直证) → sub_141B31210 灌视图。ActivateNukeCategory: 全局类目名 qword_1430900F8 → 查 CRaidCategory (失败 :981 / **cat+36 = 可目标省旗**, 0 → :987) → sub_141B29740 写 mgr+4648 过滤器。

**mgr 布局补充** (ctor 互证外 9 项): +80 数据宿主 / +88..+127 SRaidTarget 当前目标快照 (空判 sub_140FE78B0 = §4.27.1 raid+160 同函数; SelectSource 时 48B 整体拷入请求 +152) / +128 16B 参战单位引用 (读写两侧闭环) / +144..+195 52B 源行件暂存 / +224/+236 56B 源元素数组 {data, count} / +280 发射/反馈宿主 (+88 byte 门控制反馈) / +4648 CRaidFilter (核类目写入点) / +6176 挂起句柄 / +6192..+6231 第二 SRaidTarget 快照 (地图选点缓存, +6216 写哨兵 qword_14333D528)。

未决: step 3 枚举名 / CRaidCategory+36 在 def 侧表行位。

#### 4.27.5 突袭库装载与校验 (raid_database.cpp; 3 函闭环 — 顶层块分发 / CRaidType 六检 / db 校验)

簇清册 (体内 raid_database.cpp 串锚 3/3; 全为虚拟/函数指针调用 = 装载框架回调, 类/工厂 §4.27.2 已收):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_140A9BAE0 | 227 | 解析错误位记录 :374 | CRaidDatabase 顶层块分发器 (name + categories/types 两块, 读后双排序) |
| sub_140A9DE10 | 258 | 日志 :100..:126 (65540) | CRaidType 解析后校验器 (6 检查, 带 文件:行 报告) |
| sub_140A9E870 | 124 | 日志 :388/:397 (4096) + pdx_robin_hood_table.h:58 断言 | CRaidDatabase 装载后校验器 |

**顶层分发** (sub_140A9BAE0): 名槽 db+32/+64 (仅首名保留) / **token 11352 categories → db+120 容器 (计数 +132) / token 12300 types → db+176 容器 (计数 +188)** (书容器定位互证, token 名本批补) / 其他 token 跳块; **读后双 stable_sort** (指针数组保序供二分; ≤512 栈 4096B / ≤32 插入排)。

**CRaidType 六检** (全非致命, 报告形 `<file>:<line>: Missing or invalid <X> for raid type '<名>'`): +776 target type 块空 (isEmpty = +12/+36 双计数零 + 伴生旗) / +2576 requirements 向量全无效 / +2648 starting point 双 dword 零 / +2472 success factors (+2480 组0 base ≤ 0 且 +2500 == 0) / **+992 success levels 四档位子块 (+1000/+1368/+1736/+2104, 368B 步距) 全空** / +2736 target icon 空串。**布局补行: CRaidType +776 = target type 块 (88B, §4.27.2 表 +688 与 +992 间空档已补); success_levels 子块分解已补 §4.27.2**。

**db 校验** (sub_140A9E870): RH 表 (db+144 族) 与 M.rh「nbuckets = mask+1+extra」形态全同 (节点 24B, 距离字节@+4, 哨兵断言); :388 category 引用检查 — type+32 为 **token 357 "none" 占位** 或门未置 → 日志 (解析失败落 db 内建 none 占位 — §4.27.2 互证并补占位机制); :397 **types 计数 > 8191 (0x1FFF) 上限** (raid UI cache 系统上限)。

未决: 名登记与两子块读取器内部 / success_factors +2500 dword 归属。

#### 4.27.6 突袭目标管理器读档与维护 (raid_target_manager.cpp; 2 函新 + 2 帮手 — reader 键分派 / 三索引键型全钉 / UpdateListsFor)

簇清册 (体内 cpp 锚 3/3 + 帮手实名):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_141960960 | 255 | :58 断言 "unknown target type" (B52, 闩 byte_14338B3BD) | **mgr reader 键分派器** (107 target / 472 next_state / 19203 existing_target_num / 19204 detectable_target_num / 19205 next_target) | 新 |
| sub_14195E280 | 194 | :250 断言 "Inconsistent target index" (B52, 闩 byte_14338B3BE) | UpdateListsFor 共享列表+swap-remove 维护原语 | 新 (书该断言宿主补 VA) |
| sub_14195ED40 | 259 | :363 断言 "_StateTargets[ StateId ]" | mgr 增量轮转扫省重建 | 已收 §4.27.3 互证 (附赠成员实名 _StateTargets) |
| sub_141960ED0 | 65 | lambda vftable 实名 | **CRaidTargetManager::UpdateListsFor(CRaidTargetStatus&)** | 新 (实名直证) |

**reader 键分派** (sub_141960960; wrapper 0x140E83590): target 键建 80B 条目 (ctor 逐字段与 §4.27.1 per-target 表互证: existing@+0/detectable@+4 双 −1 / SRaidTarget 5 槽零 + leader id 对@+32 写哨兵 / u16@+48 = 0x0100 dynamic=0 valid=1) → 注册 (mgr+0 容器 push, 增长时逐旧槽反查簿记重挂 sub_1419608C0) → UpdateListsFor → **反查索引分发 (三 RH 表 + 一平板数组, 键型全钉)**:

| 落点 | 键 | 哈希/寻址 | 插入器 |
|---|---|---|---|
| mgr+24 表 (桶@+32) | 省 id (省+164) | 73244475 32 位终混 | sub_14195C6E0 |
| mgr+56 表 (桶@+64) | building 对象指针 | FNV-1a | sub_14195C4A0 |
| mgr+112 表 (桶@+120) | leader 对象指针 (idpair 解引用) | FNV-1a | sub_14195C920 |
| mgr+88 _StateTargets | 州 id 直下标 | — | data[州id] = 条目 |
| 全空 | — | — | :58 断言 |

**维护原语** (sub_14195E280; (条目, 24B 容器, add, 反查访问器×3)): add 路 = 查 idx → 无效/槽位冲突 → 重插 (:250 断言) 按.idx=count 落表, 自洽直写; remove 路 = data[idx]==目标 → **swap-remove** (尾元填位 + 新 idx 回写)。UpdateListsFor (sub_141960ED0) 两遍: ① existing 列表 (mgr+152), 门 = 条目+49 valid; ② detectable 列表 (mgr+176), 门 = valid ∧ building 非空 ∧ 建筑模板 +964 旗 (§4.27.3 GetTargetsForType 同旗位)。

未决: 台账海任务记录完整布局 (§4.31.106) / gs+5160 tag 列表语义。

#### 4.27.7 突袭箭头与源/目标运行时读侧 (raid_arrow / raid_source / raid_target; 8 函 1787 行)

GUI 地图箭头族 + 源/目标取值器的运行时读侧; 全部经断言源文件路径 / vtable 符号直证类属。

8 函清册:

| VA | 体行 | 定性 | 证据 |
|---|---|---|---|
| 0x141CEB080 | 38 | `NRaids::NGfx::CRaidArrow::GetArrowTypeName(int)` — 箭头类型→maparrows 名 | 断言 raid_arrow.cpp:43 |
| 0x141CEB1D0 | 824 | `CRaidArrow::UpdateArrow(CRaidInstance*)` — 全量重建地图箭头 | 断言 :85 / :387 (B52) + :388 格式化日志 |
| 0x141CEC4D0 | 99 | `CRaidArrow::UpdateUnitMovement(bool)` — 单位图标沿路径推进 | 断言 :293 (B52) |
| 0x1415934A0 | 199 | `CRaidSource::CalculateDistance(CRaidTarget*, SDistanceResult&)` — 源→目标距离, 海/陆分路 | 断言 raid_source.cpp:410/:416/:427/:446 (均 B52) |
| 0x141593D50 | 85 | `CRaidSource::GetTypeName(std::string&)` — 类型→loc 键/州名 | 断言 :253 / :264 (均 B52) |
| 0x141592DA0 | 46 | `CRaidSource::SetFromBuilding(CBuilding*)` — 建筑源构造 (type 5) | 断言 :114 (**B51 门 a4=0**, 闩 byte_14338A8ED) |
| 0x140FE7000 | 366 | `CRaidTarget::GetDisplayName(std::string&, CRaidInstance*)` — 本地化显示名 | 格式化日志 raid_target.cpp:429 (通道 4096) |
| 0x140FE7710 | 56 | `CRaidTarget::GetName(std::string&)` — 原始名/串表键 | 断言 :292 (B52) |

上层调度 sub_141CEC320 = CRaidArrow::Update(arrow, raid) (本族唯一共同调用方, 见下)。

**CRaidArrow** (`NRaids::NGfx::CRaidArrow`; ctor sub_14167D5A0; 尺寸 ≥84B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | 主vtable; thunk sub_141CEB1C0 = `sub_141CEB1D0(this, *(this+56))` (重载/重绘入口, 经 TReloadListener 派发) |
| +8 | vtable | `TReloadListener<1>` 第二基类vtable; ctor 把本对象注册进两个全局监听表 (表基 qword_143339AF8 / qword_14332F330, 各持 data/cap/count, 8B 元, 增长 ×1.5) |
| +16 | 匿名结构 (NNB 形状)* | 地图单位图标实例 (堆); 创建 sub_141CE9680 (置 "idle" 态) / 释放 sub_141CE9780 (析构后置 0) / 设变换 sub_141CE9990 / 显隐动画 sub_141CE97B0 / 沿路径推进 sub_141CE97E0; **创建经 sub_14228CD30(obj,7,6,0), 类名语料未证 — 待裁** |
| +24 | uint8 | 单位图标"移动中"状态镜像; 调度器比对并翻转 (翻转时调 sub_141CE97B0) |
| +32 | uint64 | 属主/场景句柄 (ctor 第二参); 创建/释放 CMapArrow 的上下文 (sub_14126F380 / sub_14126FAD0 第一参) |
| +40 | 匿名结构 (NNB 形状)* | 按 maparrows.txt 名创建的地图箭头实例 (sub_14126F380); 名 = GetArrowTypeName(箭头类型) |
| +48 | uint8 | 可见旗; 调度器依可见性集合 (sub_141B29930 二分查找) 置 0/1; 0 时隐藏图标并跳过更新 |
| +56 | CRaidInstance* | 当前突袭; ==0 时 UpdateUnitMovement 触发 :293 断言 |
| +64 | uint64 | 源省句柄缓存 (CRaidSource::GetSourceProvince(raid+216) 结果); 变化即触发 UpdateArrow 重建 |
| +72 | float | 突袭进度 (0..1): raid type 4 = `(int)*(qword)sub_140FEA340(raid) / 100000.0`; type 5 = 1.0; 其余 = 0; UpdateUnitMovement 走 sub_141CEC860 lerp 重算 |
| +76 | float | 箭头路径长度 = sub_141267C60(arrow+40) (路径提交后) |
| +80 | int32 | 重建后清 0 的旗/计数 |

**箭头类型枚举** (GetArrowTypeName 返回值; 定案):

| 值 | maparrows 名 | 段数/平滑 define 对 (defines_map_1193.txt 直证) |
|---|---|---|
| 0 | active_raid_line | 无段插值 (仅起点+终点) |
| 1 | active_raid_ballistic | RAID_ARROW_BALLISTIC_MAX_SEGMENT_LENGTH (0x1433325A8) / RAID_ARROW_BALLISTIC_MAX_SEGMENTS (0x143332660) |
| 2 | active_raid_air | RAID_ARROW_AIR_MAX_SEGMENT_LENGTH (0x143332C64) / RAID_ARROW_AIR_MAX_SEGMENTS (0x143332D08) |
| 3 | active_raid_naval | RAID_ARROW_NAVAL_SHARP_TURN_SMOOTHNESS (0x143332EB8) / RAID_ARROW_NAVAL_SUBDIVISIONS (0x143332DEC); 海军寻路 |
| 4 | active_raid_land | RAID_ARROW_LAND_SHARP_TURN_SMOOTHNESS (0x143333118) / RAID_ARROW_LAND_SUBDIVISIONS (0x143333040); 陆寻路 |

非法值 → raid_arrow.cpp:43 断言 (B52 门 a4=1, 闩 byte_14338C5D4) 后返回空串 (非致命)。

UpdateArrow (0x141CEB1D0) 十四步:

| # | 动作 | 要点 |
|---|---|---|
| 1 | 释放旧资源 | sub_141CE9780(arrow+16) 释放图标; arrow+56 = 0; 旧 CMapArrow (arrow+40) 经 sub_14126FAD0(arrow+32) 释放后置 0 |
| 2 | 存 raid | arrow+56 = a2; a2==0 或 *(raid+152)==0 → 直接返回 (空箭头) |
| 3 | 取源/类型 | arrow+64 = CRaidSource::GetSourceProvince(raid+216); 箭头类型 = *(*(raid+152)+40) (CRaidType+40 箭头参数块首域) |
| 4 | 建 CMapArrow | 名 = GetArrowTypeName(类型); sub_14126F380(arrow+32, 名, ...) → arrow+40 |
| 5 | 建失败路径 | arrow+40==0 → 拼串 "Failed to create arrow with name: <名> - Is it missing from maparrows.txt?" → :387 断言 (B52, 闩 byte_14338C5D9) + :388 格式化错误日志 (通道 4096) → 返回 |
| 6 | 注册回调 | sub_14126C800(arrow, sub_1414D4CD0, this); type 1 → sub_141CEACA0, type 2 → sub_141CEAAA0 (sub_14126C5B0) |
| 7 | 选色 | raid type ∈ {4,5} → ACTIVE_RAID_ARROW_COLOR (0x143333A40); sub_140FEB800(raid,0) 真 (phase 3 PREPARED) → READY_RAID_ARROW_COLOR (0x143333990); 否则 PREPARING_RAID_ARROW_COLOR (0x1433338D0) |
| 8 | 端点 | 起点 = sub_141B3C130(raid+216) (源位置); 终点 = sub_141F5D7D0(CRaidInstance::GetTarget(raid) = raid+160) (目标位置) |
| 9 | 经度环绕 | 若 \|end.x − start.x\| > (CMap+64)×0.5 → 较西侧者 += CMap+64 (int 读, qword_143339D28 = CMap 单例); 保证插值走短弧 |
| 10 | 直线段 (type 0/1/2) | type 0 折叠为 1 段; type 1/2: 段数 = **min(MAX_SEGMENTS, max(1, ceil(dist / MAX_SEGMENT_LENGTH)))**; 逐点线性插值 |
| 11 | 寻路段 (type 3/4) | type 3 → sub_140E86040(gs+1008, 源省, 目标省, out) 海军; type 4 → sub_140E86000 陆; **失败 (有效旗 0) → 回退直线流程** |
| 12 | 曲线采样 | sub_141CE9A90 生成平滑曲线; SHARP_TURN_SMOOTHNESS>0 → 细分; 每 4 控制点按 SUBDIVISIONS 做 **Catmull-Rom** 采样 (基函数见下) |
| 13 | 提交 | sub_14126C4E0(arrow+40, 路径向量); sub_14126ADE0; arrow+76 = sub_141267C60(arrow+40); arrow+72 = 进度; arrow+80 = 0 |
| 14 | 建图标 | sub_141CE9680(arrow+16, *(*(raid+152)+48) (CRaidType+48 unit_model), raid+200, sub_140FECFA0(raid)) |
| 门 | gamestate 断言 | gamestate.h:1116/1117 (读 gs 前) 与 1125/1126 (`_pInstance` / `_ThreadForbidCount`, B52, 一次性闩 byte_14332EDF9/FA、byte_14332ED00/01) |

> **Catmull-Rom 基函数** (PE 侧验算 = 标准均匀 CR 整体 ×0.5; t = i/SUBDIVISIONS): P0 = −t+2t²−t³ / P1 = 2−5t²+3t³ / P2 = t+4t²−3t³ / P3 = t³−t²; 采样坐标 = (P0·基0 + P1·基1 + P2·基2 + P3·基3) × 0.5, 两通道 (曲元素 x 列 = stride 12 首 float, y 列 = +4 float) 分别插值后量化 **int32 定点 1e-5, 四舍五入远离零**: `(v>=0.0) + v*100000.0 - 0.5` 后 (int) 截断。
> **路径向量形态**: 引擎自定义向量 (data@+0 / cap@+8 / count@+12), 元素 **16B** {int32 坐标 A@+0, int32 坐标 B@+8, +4/+12 未写}, 增长 ×1.5; 直线段经 sub_141CEA910 追加、曲线段内联直写同向量 (元素序/尺寸一致 = 推定, 未读 sub_141CEA910 体)。

UpdateUnitMovement (0x141CEC4D0) 七步:

| # | 动作 | 要点 |
|---|---|---|
| 1 | 前置校验 | raid = arrow+56; ==0 → :293 断言 (B52, 闩 byte_14338C5D8); arrow+40==0 → 返回 |
| 2 | type 4 目标刷新 | sub_140FEA340(raid, out) 取目标点 + sub_140FEA400(raid, out) 作用 |
| 3 | 进度 | arrow+72 = sub_141CEC860() (NaN 安全 lerp: (1−t)·a + t·b) |
| 4 | 端点 | sub_141267860(arrow+40) → 起点/终点向量 (float×3 各) |
| 5 | 偏移 | 起点 += RAID_UNIT_ENTITY_OFFSET (三 float: dword_1433333C0/C4/C8); 终点取负 = 方向向量 (x 异或 0x80000000, y/z 取负) |
| 6 | 设变换 | sub_141CE9990(arrow+16, pos, dir) — 含 x 环绕 (pos.x > CMap+64 → 减 CMap+64), 构 4×4 矩阵经 sub_1424FDB40/FC420, 末调 sub_142290960 |
| 7 | 推进 | sub_141CE97E0(arrow+16, 进度浮点, active^1, *(*(raid+152)+136) (CRaidType+136 unit_animations)) — 遍历路径段数组 (count@+12, 元素 **72B**, 段位置定点 1e-5 @元素+64), 跳过累计长度 ≤ 进度的段 |

上层调度 sub_141CEC320 (CRaidArrow::Update) 五步:

| # | 动作 | 要点 |
|---|---|---|
| 1 | 可见性 | *(raid+152) 非空 → sub_141B29930(v5+4648, *(raid+152)) 二分查找 (被查对象 id @其+32; 集合 = 持有者+1488 有序树) 假 → arrow+48=0, 隐藏图标, 返回 |
| 2 | 置可见 | arrow+48 = 1 |
| 3 | 重建判定 | raid 变 (arrow+56 ≠ raid) **或** (CRaidSource 有效 (sub_141593370(raid+216)) **且** raid type ≠ 4 **且** arrow+64 ≠ GetSourceProvince(raid+216)) → UpdateArrow |
| 4 | 移动态 | v10 = type==4 \|\| (type==5 && arrow+72 < 0.99900001 && *(raid+60) ≠ 5); 与 arrow+24 比对: 变化 → sub_141CE97B0(arrow+16, v10) + (v10 时 UpdateUnitMovement(1)); 不变且 v10 → UpdateUnitMovement(0) |
| 5 | 收尾 | sub_141CEC460(arrow, …) |

> ⚠ UpdateArrow 中 `if (!*v5)` 包裹成功体系 IDA 控制流倒置 (成功路径经 LABEL_41 选色后 goto LABEL_42 跳入); 语义按成功路径读, **高置信**。
> 移动态判据 `*(raid+60) ≠ 5` = **outcome ≠ CANCELED** (§4.27.1 +60 outcome 枚举直证 — 已取消的突袭不再推进单位图标)。
> 箭头色三档对 phase: {4,5} = IN_PROGRESS/ENDED → ACTIVE; phase 3 PREPARED → READY; 其余 → PREPARING (§4.27.1 +56 phase 枚举互证)。

**CRaidSource 运行时读侧** (无 vtable 结构; ctor sub_141592F00; 内嵌于 CRaidInstance+216):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | int32 | 类型枚举 (见下表) |
| +4 | uint8 | 有效旗 (0 → GetSourceProvince 返 0, CalculateDistance 判失败; SetFromBuilding 清 0) |
| +8 | uint64 | 省句柄 (type 0/1/2 预存; SetFromBuilding 清 0) |
| +16 | idpair {type@+16, id@+20} | type 3/4 源 (sub_14221F310 校验); 初值 = qword_14333D528 (共享空句柄哨兵) |
| +24 | int32 | type 5: = *(building+392) (SetFromBuilding 直填) — ⚠ 与 §4.27.1 存档侧表「tag tid」冲突, 待裁 |
| +32 | CStateID 子对象 | type 5: ctor sub_1413C0880; sub_1413C08A0 → CState*, 州名 @ CState+528 — ⚠ §4.27.1 存档侧表记「building 内嵌块 (sub_1413C0880 构造)」同 ctor 异名, 待裁 |
| +40 | int32 | type 5: 省 id (gs vtable[1](gs+8, id) 取省句柄) — ⚠ 存档侧表记「location u32」, 待裁 |
| +44 | int32 | type 5: sub_1413C0720 结果 v5[3] (省/建筑关联量) — ⚠ 存档侧表记「template token」, 待裁 |
| +48 | int32 | type 5: sub_1413C0720 结果 v5[4] |

> 取值器 `CRaidSource::GetSourceProvince` (sub_141593A60): !(+4) → 0; type 0/1/2 → *(+8); type 3/4 → idpair 经 sub_14221F310 → *(*(obj+1832)+496); type 5 → gs vtable[1](gs+8, *(+40)); 其余 → 0。

**类型枚举** (三函互证, 定案):

| 值 | 源语义 | GetTypeName loc 键 | CalculateDistance 路由 |
|---|---|---|---|
| 0 | 空军基族建筑 | 由 *(building+124) 子类型决定 (0→"air_base" / 1→"rocket_site" / 2→"mega_gun_emplacement", 其余 → :253 断言) | sub_140E7C150 直接距离 |
| 1 | 火箭发射场 | "rocket_site" | sub_140E7C150 |
| 2 | 海军基地 | "naval_base" | **sub_140E86040 海军寻路** (gs+1008) |
| 3 | 空军基族建筑 | 同 0 | sub_140E7C150 |
| 4 | 空军基族建筑 | 同 0 | sub_140E7C150 |
| 5 | 省建筑/州 | 州名 (CStateID → CState+528) | **sub_140E86000 陆寻路** (gs+1008) |

**CalculateDistance (0x1415934A0)**: 取源省 (:410 断言, 闩 byte_14338A8F0) → 有效旗 (:416, 闩 byte_14338A8F1) → 取目标省 (type 2 → sub_140FE6AB0 海军专用无回退; 其余 → sub_140FE6A10(target, 1) 允许回退 主省→建筑省→次省/州省; :427, 闩 byte_14338A8F2) → type 0/1/3/4 直接距离 / type 2 海寻路 / type 5 陆寻路 / default :446 断言 (闩 byte_14338A8F3)。

**SDistanceResult** (出参, 9B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | uint64 | 距离 (定点; 直接距离支 = (100000 × raw) / 300000 = **raw/3 截断**; 哨兵支 = 0xFFFFFFFF; 寻路支由 sub_140E86040/000 直写) |
| +8 | uint8 | 有效旗 (1 = 有距离, 0 = 不可达/输入非法) |

> ⚠ **raid 直接距离 (sub_140E7C150) 哨兵 = INT64_MAX (0x7FFFFFFFFFFFFFFF)** (PE 侧穷举定案: 命中集合 = {INT64_MAX, INT64_MIN, INT64_MIN+1}), **≠ pathfind.h A\* 簇 INF 哨兵 92233720200000 (§4.14)** — 不同寻路簇不同哨兵, 勿混用。源级谓词 IDA 常量失真无法反推, 措辞层待裁; 语义 (INT64_MAX = 不可达) 高置信。
> raw 单位与 ÷3 系数的业务含义 (疑定点 1e-5 地图距离 → raid 单位换算) 未决。

**CRaidTarget 运行时布局** (无 vtable; 内嵌于 CRaidInstance+160; ≥40B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | CBuilding* | 建筑目标 (sub_1410DBD10 校验省建筑 → sub_1410DB850 取省); GetDisplayName 取 *(建筑+480)+528 = 建筑类型名 |
| +8 | CProvince* | 主省目标 (GetProvince 首选; GetProvinceName/GetDisplayName 优先来源) |
| +16 | CState* | 州目标 (GetProvince 回退, sub_140FE6010 转省) |
| +24 | idpair {type@+24, id@+28} | 引用型目标 (sub_14221F310 校验) |
| +32 | CProvince* | 次省/leader_province (GetProvince 次选; 胜利点检查入口) |

> 与 §4.27.1 SRaidTarget 存档块 (building@+0 / province@+8 / state@+16 / leader id 对@+24 / leader_prov@+32) **逐项一致** — 第二证据, 定案加固。

**GetDisplayName (0x140FE7000) 五步**: ① 基名 = GetProvinceName (sub_140FE6E60, 取 +8/+32 省名, sub_140E7D730 省信息) → ② 自定义名 (raid+2896 非空且 sub_142244840 校验通过 → 以自定义名为 loc 键; 校验失败 → :429 格式化错误日志 "Localization key not found for custom raid target name in %s: %s", 不中断) → ③ 建筑目标 (+0) → loc 键 "RAID_TARGET_NAME" / "WHAT" = 建筑类型名 / "LOCATION" = 基名 → ④ 省目标 (+8 其次 +32) → 胜利点建筑 (info+16 非 0) → 键 "raid_target_name_victory_point"; 否则地形/州名 → 键 "PROV_TOOLTIP_LOCATION_STATE" (TERRAIN + NAME 两参) → ⑤ 无目标 → out = 基名。参数表 = 104B 元素 eh-vector (元 = int32 序号@+0 + std::string@+8)。

**GetName (0x140FE7710) 变体优先级** (定案):

| 优先级 | 条件 | 结果 |
|---|---|---|
| 1 | +8 非 0 | 串表键 **10304** |
| 2 | +0 非 0 | u32 = *(*(+0)+480)+8 → sub_1424BC260 串表查询 |
| 3 | +16 非 0 | 串表键 **439** |
| 4 | +24 idpair 非零且校验通过 | 串表键 **10423** |
| 5 | 皆不满足 | :292 断言 ("Unexpected target type", B52, 闩 byte_14333D77D) + 空串 |

> ⚠ GetName 优先级表与 GetDisplayName 分支结构不同 (后者先合并 +8/+32 为省支、先判 +0 建筑支); 两函各自定案, 勿互推。

**CRaidType 消费侧收口** (*(raid+152) 四字段 ↔ §4.27.2 CRaidType 表逐项对上, 零冲突):

| CRaidType 偏移 | 书内 def 侧 (§4.27.2) | 本批运行时消费侧 | 档 |
|---|---|---|---|
| +32 | CRaidCategory* (键 702 category) | 可见性集合二分查找的 id 键 (@其+32) — ⚠ 两语义冲突, 待裁 | 待裁 |
| +40 | 箭头参数块 (键 19243 arrow) | **块首域 = 箭头类型枚举 0..4** (GetArrowTypeName 输入; UpdateArrow 步 3) | 复证一致 |
| +48 | 单位模型 (键 16731 unit_model) | 单位图标创建第 2 参 (sub_141CE9680, UpdateArrow 步 14) | 复证一致 |
| +136 | unit_animations (键 16687) | **路径段数组** (data@+0/count@+12, 元素 72B, 段位置定点 1e-5 @元素+64; UpdateUnitMovement 步 7) | 复证一致 |

> U.3 (*(CRaidInstance+152) 类名) 由书内 §4.27.1 定案 (NRaids::CRaidType*) 收口 — 本批原标「未决」的突袭令对象 = **CRaidType**。
> **CRaidInstance 相关偏移补证**: +56 = phase (观测 3 PREPARED/4 IN_PROGRESS/5 ENDED, 与 §4.27.1 六值枚举一致) / +60 = outcome (移动态判据 ≠5 = CANCELED) / +88 属主 / +96 CVariables / +152 CRaidType* / +160 CRaidTarget / +184 空句柄 / +200 图标创建第 3 参 / +216 CRaidSource / +272 CEquipmentVariantPool / +344 CCommandPowerAllocator / +2896 自定义名 SSO (data@+2896 / ptr@+2912 / len@+2920)。

**未决**: CRaidArrow+16 图标对象类名 (创建经 sub_14228CD30(obj,7,6,0), 语料无 vftable 符号) / CRaidArrow 路径向量直线分支元素序 (须读 sub_141CEA910) / sub_140E7C150 距离语义与 ÷3 系数 / CalculateDistance 哨兵源级谓词 (IDA 常量失真) / CRaidSource +24/+32/+40/+44 与存档侧表的命名冲突 / CRaidType+32 双语义 / 可见性集合持有者 (qword_14332F6A0 vtable+184 → +4648/+1488 集合, 未入书) / GetProvinceName 空串分支兜底。
