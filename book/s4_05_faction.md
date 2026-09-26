

### 4.5 CFactionSystem (阵营)

**获取**: `fac = *(gs + 1016)` (facsys)。hourly = sub_140D928C0
("CFaction::ParallelPreHourlyUpdate"); CreateFaction 入口 = sub_140D91E00
(CCreateFactionEffect::Execute 0X1404AB570: `sub_140D91E00(*(gs+1016), tag, name, 0,0,0)`,
写新阵营 +2544 色槽 = 槽序−1)。

| 项 | 值 |
|---|---|
| RTTI 名 | — |
| sizeof | — |
| vtable RVA | — |
| writer | 0X140D94370 |
| loader | 0X140D94100 (vtable slot[4]) |
| 挂载点 | `*(gs + 1016)` |

| 偏移 (facsys) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CFactionMemberStatus 稀疏阵 | **countries** (键 11593; 元素 208B, 见 4.5.1) | data@+8, size u32@+20 |
| +32 | CFaction* 向量 | **CFaction 挂载** {data@+32, count@+44} 8B 指针, 写序 = 容器序 | |
| +56 | CStrategicResourcePool 内嵌 | **extracted 资源池** (键 16085; 条目 +0 = i64 定点 value, +8 = 资源 token; 元素表见 4.5.8) | hourly 与每阵营 fac+2320 池互转 (sub_140BCB530(fac+2320, country+40)) |

#### 4.5.1 CFactionMemberStatus (成员条目 208B = 0xD0)

元素 writer = SPersist\<CFactionMemberStatus\>::Write; loader sub_14118EB00;
ctor/Reset sub_14118D1A0; 日重置 sub_14118EC80; el = data+208×slot。
**槽占用条件** (λ 0X140D94270): `ru32(el+0)>0 且 *(*(国家数组[ru32(el)]+3976)+656)≠0`
或 completed_faction_goals 计数非零; 写形 = 先裸 size 再逐占用槽 `{index=N data={…}}`:

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | u32 | 国家 idx (槽占用 λ `ru32(el+0)>0` 之源头) | |
| +8 | 容器 24B | **influence_status** {data@8, cap@16, count@20 (**运行时恒=5** = EInfluenceStatType::COUNT), alloc@24} — 8B i64×1e-5 元 ×5 类目; 稀疏阵键 12819 只写非零槽 (λ 0X14118F590); AddInfluence sub_14118D8E0 断言 type<5 | 占用 = 值非零; **GUI: influence 占比分子** (+56 = 100000×Σ本表÷fac+2080) |
| +32 | 容器 24B | **power_projection_stats** {data@32, cap@40, count@44 (恒=4), alloc@48} — 4×i64 fixed; GetPowerProjectionStat sub_14118DAB0 断言 idx<4 (faction_member_status.cpp:0x60); tooltip sub_140D8BC20 按 idx 0..3 求和 | |
| +56 | i64 fixed | **阵营 influence 占比** (sub_140D8F610 = 100000×成员Σinfluence÷fac+2080, clamp≤1.0; 写点 = 重算批一处 + 日重置清 0) — **GUI: 成员国列表行数值** (100×*(+56) 百分比化; 访问器 sub_140BB4AC0 = facsys+8+208×tag) | 定案 |
| +64 | i64 fixed | **+56 占比的镜像/前值副本** — 日重置 sub_14118EC80 同函数连续两次 `sub_1424EF6F0(&v, 100000)` 分别写 +64 与 +56 (均钳 ≥0); ctor sub_14118D1A0 同式成对写; 重算批 sub_140D8F610 只写 +56 | 高置信 |
| +72 | i64 fixed | initiative (键 13573; 日重置 0) | ≠0 才写; 领袖无此字段 = 0 |
| +80 | u32 | **阵营 influence 排名** (sub_140D8F740 降序排名, 1=最高; def 铁证 = token 19617 `faction_influence_rank` = 成员列表 sort_influence 排序键; 写点同 +56) — **GUI: 成员国列表行计数** | 定案 |
| +96 | 匿名结构 (24B 形状) RH 桶数组 | **member_upgrades** {buckets@96, count@104, mask u32@108, extra u8@112, lf f32@116=0.9} — 24B 桶 {dist+1 u8@4, key u32 token@8, value def 指针@16}; 键 10473 | 门 = 表非空 (20 档实测恒空) |
| +120 | i64 fixed | contribution (键 10477) | ≠0 才写; **GUI: 人力窗上限成分** (sub_14118A620 = 本值与 defines 基数求上限) |
| +128 | i64 fixed ×2 **内联** | **contribution_gain 定点对** (键 10504, 定长数组恒写 2 元, 内联 2×i64 — writer `for(v7=+128; v7!=+144; ++v7)` + loader case 10504 区间读双证) | 恒写 |
| +136 | i64 fixed | contribution_gain 定点 2 | 恒写 |
| +144 | 匿名结构 (元素待裁) 向量 | 容器 X (名未决) {data@144, cap@152, alloc@160(&off_143085170), count@168, **sentinel i32@172=−1**} — 日重置 sub_14118EC80 释放并 count 清 0 + +172 归 −1; ctor sub_14118D1A0 同置; loader sub_14118EB00 键表 {12819,13573,14209,12502,10477,10504} **无落 +144 的 case** ⇒ 不序列化; 语义未决 (无消费点) | 形态定案 / 语义未决 |
| +176 | i64 fixed | war_score_breakdown (键 12502; 日重置 0) | 恒写 |
| +184 | 容器 24B | **completed_faction_goals** {data@184, cap@192, count@196, alloc@200} — 8B CFactionGoal def 指针元, 写 token@def+8; 键 14209 | 门 count≠0 (20 档实测恒空) |

#### 4.5.2 CFaction (2688B = 0xA80)

ctor sub_140D87F90 (逐项吻合到 +2672); writer 0X140D8FCF0; loader slot[4] =
sub_140D8D880 (全键表见 4.5.6)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | CReferenceObject 基 24B | {vt@0, id 对 {type@+8=88, id@+12}, **u8 flag@+16 = CReferenceObject 基类 IsStored 旗** (ctor 置 0; 注册成功由 vt[9] sub_14221E990→sub_14221E700 尾 `*(a1+16)=1` (id.cpp:130); 反注册 sub_14221EA60 首行 `if(!*(a1+16)) return 0` (id.cpp:210) 据此短路) | id 对恒写 |
| +24 | MSVC SSO 32B (size@+40) | **name** 引号 ("孟买条约" 等; SetFactionName 效果写 +24; GetName sub_140D8BB80 读 +24/+40) | **门 size≠0** (定案); **GUI: 阵营名行** (sub_140D8BB80; 外交 header faction_name 同链) |
| +56 | MSVC SSO 32B | **cached display name** (GetName 结果缓存: +24 非空→+24, 否则 template+208 名; 写入点 sub_140B59200; 不序列化) | |
| +88 | 容器 24B | **members** {data@88, cap@96, count@100, alloc@104} — 8B CCountry* 元, tag=ru32(cc+8) 引号; AddMember sub_140D89A30 1.5x 增长 | c>0; **GUI: 成员国列表行** (sub_141474550: 色 = cc+848 沿宗主链取色 sub_1406ECF80 / 值 = facsys 条目+56 占比/+80 排名; 首元 = 领袖旗; faction_countries_window) |
| +112 | CGameDate 24B {vt1@+112, hours@+120, vt2@+128} | **faction_leader_change_date** (SetLeader sub_140D8ED20 `*(a1+120)=*(gs+1128)`; ADEC0 arg=a1+128=&vt2) | **≠43817520** (双哨兵 §3.7) |
| +136 | CIdeologyGroup* | ideology def obj → token idx@def+8 → 裸名 | 恒写; def 对象 |
| +144 | **CRule 内嵌 1016B** (+144..+1159) | 阵营规则缓存 (运行时态; 拷贝源 = ideology def+96; 布局见下子表; 消费侧 sub_140D8A2A0 → sub_140638DB0(a2, a1+144)) | 不序列化 |
| +1160 | **CModifier 内嵌 192B** (+1160..+1351) | faction modifier (运行时合成; 源自 ideology def: +1168=*(ideology+1352), pairs 自 ideology+1360 经 sub_1405570F0 拷入 +1176; 全布局见 §4.3.8 CModifier 通用表) | 不序列化 |
| +1352 | MSVC SSO 32B (size@+1368) | icon 引号 | 恒写; **GUI: 图标行 + 命令写入链** (CFactionIconItem 读 = CFactionIconsDatabase qword_14332EEE8 {data@+80, count@+92}, §4.26.8; CSetFactionIconAndColor Execute 写本字段, icon 串@cmd+48) |
| +1384 | NFactions::CFactionTemplate* | template def obj → token 名 (sub_1424BE600) 引号; 默认 = token 10355 **original_generic_faction_template**; loader 成功后 rule_status+goal_status 双重建 | ptr≠0; def 对象 |
| +1392 | **CFactionRuleStatus 内嵌 176B** (+1392..+1567) | rule_status 块 (布局见下子表) | |
| +1568 | CFactionGoalStatus 内嵌 **424B** (+1568..+1991 恰满) | goal_status (见 4.5.3) | 恒写块 |
| +1992 | **CFactionProgramStatus 内嵌 ~64B** = faction_programs | {vt@0, **CRef\<NProject::CProgram\> 向量 {data@8, cap@16, count@20, hybrid 内联 allocator@+24→inline@+32 (容 4)}**}; 元素 **8B CRef 双 u32 对** (writer sub_142220180 每元恰写两 u32 + u32 指针 +2 步进铁证; 内联@+32 容 4 = 4×8B), 键 10482, 逐个 sub_142220180 写 GUID | **门 = count@+20≠0** (20 档实测恒空) |
| +2072 | i64 fixed×1e-5 | **total_power_projection** (阵营力量投射总值缓存, 累加钳 ≥0; AddPowerProjection sub_140D89E00; tooltip sub_140D8BC20 + loc TOTAL_POWER_PROJECTION "Total Power Projection: $VAL\|0H$"; 重算 sub_140D8FC30 从成员表 +88 汇总) | |
| +2080 | i64 fixed | **阵营级 influence 累计 (占比分母)** — sub_140D8F610 体: `v13 = *(fac+2080); v14 = Σ成员 influence(+8 容器 8B 元); v15 = 100000*v14/v13` (钳 ≤100000) 写成员 +56; 重算批 sub_140D8FC30 内 _InterlockedExchange64 归零 | 定案; **GUI: influence 占比分母** |
| +2088 | fixed×1e-5 | power_projection_from_effects (AddPowerProjection 同点互证; loc POWER_PROJECTION_FROM_EFFECTS) | ≠0 才写 |
| +2096 | CFactionSystem* | facsys 回指 (ctor `*(a1+2096)=*(gs+1016)`) | |
| +2104 | **CFactionUpgradeStatus 内嵌 184B** | upgrades 块 — 管理器本体 (见 4.5.4; 424B 是其 slots 向量条目步长) | 恒写块 |
| +2288 | CArmyManpowerValues 内嵌 32B | manpower_pool {vt@2288, 容器@2296}; writer 双写 ADEC0(+2288) + sub_140C6AD50(+2288, out, 13877=manpower_pool) | 空块不发射 (20 档恒空); **GUI: CRequestManpowerWindow 消费链** (池合计 sub_140D8BAD0→sub_140C69830 + 成员 contribution(+120) + defines 基数 → REQUEST_FACTION_MANPOWER_VALUES; 提交 NFactions::CUseFactionMemberManpower {+40 amount/+44 tag}; 校验 "not enough manpower in pool"; 见 4.5.11) |
| +2320 | CStrategicResourcePool 内嵌 | extracted 资源池 (键 16085; facsys hourly 把成员国资源 sub_140BCB530(fac+2320, country+40) 汇入; 内部 176B 细分未做; 元素表见 4.5.8) | 恒写块 |
| +2496 | uint8 | is_color_overridden → yes/no (键 16901; 同族 13500/10300 = yes/no 读弃、12817 = 定点数读弃) | 恒写 |
| +2512 | CColor 内嵌 | color (布局见下子表) | 恒写; **GUI: 阵营色写入链** (CFactionColorPickerWindow btn_ok 写 picker+2992 CColor → CCreateFactionCommand+128 → sub_140D91E00 → 本字段; 初始色 = CFactionTemplate rgba@+384 (旗@+400) ∥ 玩家国 cc+880; 见 4.5.10); **CSetFactionIconAndColor Execute 写 rgba = CColor+16** (cmd+80 CColor 拷入, 与 picker 链同字段无冲突) |
| +2552 | **CFactionTheaterManager 内嵌 64B** | pings 块 (布局见下子表; RTTI NFactions::NAi::CAiFactionTheater) | 键 19753=pings, 门 theaters 非空 (20 档实测恒空) |
| +2616 | uint8 | research (键 13500) | 恒写 |
| +2617 | uint8 | manpower → yes/no (键 10300); 亦作 military_unlocked 旗读写点 (set/has_faction_military_unlocked, loc 系 FACTION_ACCESS_TAB_MILITARY; 两名一事) | 恒写 |
| +2624 | CVariables 内嵌 64B | variables (布局见下子表; random 门 ru32(vo+8)!=1, faction 恒 1 故无 random 叶) | 非空才写块 (键 10826) |

CRule 内嵌布局 (fac+N 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt | 0x142718B48 (基 CPersistent) |
| +8 | MSVC 串 | name |
| +40 | 覆盖链表 | {head@+40, +48, count@+56} |
| +60 | u8 | 语义未决 |
| +64..+91 | 28B 字节数组 | rule 默认值 (初始化 = 规则库条目+50 默认值) |
| +92..+119 | 28B 字节数组 | rule 覆盖值 |
| +120..+1015 | 28×MSVC 串 内嵌数组 | 规则名串组 |

CFactionRuleStatus 布局 (fac+1392 相对; writer 0X1419966A0; loader case 19557;
CSetFactionRuleEffect → sub_140D8EC80 → sub_141995D40(fac+1392, rule,…)
+ 逐成员通知 sub_1406FF1F0):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt | — |
| +8 | CFaction* | faction 回指 |
| +16 | — | 0 |
| +32 | 哈希A | {sentinel@+32, count@+40, extra@+48, lf@+52 = 0.9f} |
| +64 | 哈希B | 同哈希A 形 |
| +88 | 容器 24B | **rules 向量** {data@+88, cap@+96, count@+100, alloc@+104} — CFactionRule def 指针; 键 12667=rules, 写 token@def+8 |
| +120 | 哈希C | — |
| +152 | 哈希D | — **GUI: change_rule_window populate sub_141C0D680 消费** (cpp:83 "show_filter_offset" 断言; RH 8B 元 {distance@0, rule token@+4}; 见 4.5.12) |

CColor 内嵌布局 (fac+2512 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt | — |
| +16 | rgba f32×4 | 颜色值 (`int(f*255)` **截断**; alpha ≠1.0 才第 4 值, writer 0X14224CA10) |
| +32 | u16 | 0xFFFF 哨兵 (ctor −1; CreateFaction 写槽序−1, 重排 sub_140D922F0 写槽 idx — **阵营色索引/槽号** 高置信) |

CFactionTheaterManager 布局 (fac+2552 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt | — |
| +8 | CFaction* | faction 回指 |
| +16 | 容器 24B | theaters {data@+16, cap@+24, count@+28, alloc@+32}; **条目 stride = 168B** (GUI 消费定案: +0 name / +32 tag / +36 commander / **+48 flags 向量 {count@+60}** / **+72 regions 向量 {count@+84}**, 见 §4.31.31) |
| +40 | — | 0 |
| +48 | — | 0 |

theaters 条目 (内层键 12065=regions):

| 条目偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | MSVC 串 | name |
| +32 | u32 | tag (键 10754) |
| +36 | 匿名结构 (元素待裁) 向量 | commander (键 11355) |
| +120 | — | execution_type (键 13994); 枚举 0=careful / 1=balanced / 2=rush / 3=rush_weak |
| def+8 | token | template (键 19482) |

CVariables 内嵌布局 (fac+2624 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt | — |
| +8 | u32 | 1 (random 门 ru32(vo+8)!=1 读此) |
| +12 | — | 种子 1587985054 |
| +24 | — | &unk_1430851A0 |
| +32 | — | 0 |
| +40 | u8 | 0 |
| +44 | f32 | 0.9 |
| +48 | — | 0 |

#### 4.5.3 CFactionGoalStatus (goal_status, faction+1568, 424B 恰满)

ctor sub_140A25C70 / writer 0X140A299E0 / loader 0X140A28300。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | CFaction* | faction 回指 | |
| +16 | 匿名结构 (faction manifest 定义)* | manifest def → token idx@def+8 裸名 (键 19587; CSetFactionManifestEffect::Execute 0X1404ABBE0 → sub_140A28B90) | ptr≠0; def 对象 (类名未证, RTTI 无 Manifest 定义类); **GUI: manifest 门/名** (sub_140A21BE0; MANIFEST / FOREIGN_MANIFEST_ENTRY; def+2664/+2872 门字段未决) |
| +24 | 容器 24B | **goals** {data@24, cap@32, count@36, alloc@40} — 1344B 步长: goal def@+0 (idx@def+8 裸名), status u32@+8 (0=active 11390 / 1=completed 12583 / 2=canceled 19620, 断言 "Invalid goal status" faction_goal_status.cpp:0x2F), date 24B {hours@1328, vt1@1320, vt2@1336} 键 508=game_data (无门恒写; 默认 43808760 → "1.1.1.1"); AddGoal sub_140A26840 (DLC50 门) → sub_140A26A70 去重插入 | c>0; **GUI: 目标列表** (sub_140A27930 → FOREIGN_GOAL_ITEM_ENTRY) |
| +48 | 容器 24B | **available_goals 平铺 def 指针数组** {data@48, cap@56, count@60, alloc@64} — 8B 元按槽分段拼接 (区间切分器 sub_140A278C0: `begin=data+8*off[slot]`, off=+168 表) | 不序列化 (运行时重建 sub_140A28FD0) |
| +72 | 容器 24B | **completed_goals** {data@72, cap@80, **count@84**, alloc@88} — 8B def 指针元; 键 12787 | 门 count≠0 |
| +96 | 容器 24B | **canceled_goals** {data@96, cap@104, **count@108**, alloc@112}; 键 12788 | 门 count≠0 |
| +120 | 内联容器 | **extra_goal_slots** (i32×3 内联 {data@120→inline@152, cap@128=3, count@132, allocator CPdxStaticInlineBufferAllocator\<int,3\>@144}; 引擎按有符号打印, −1 在档); 槽名 0=short_term 1=medium_term 2=long_term (sub_140A233B0); AddFactionGoalSlot 效果 → sub_140A26820 `*(data+4*slot)+=n` | 值≠0 |
| +168 | 内联容器 | **per-slot available goal 计数/前缀偏移表** (i32×4 内联 {data@168→inline@200, cap@176=4, count@180, allocator\<int,4\>@192}; 切分器 sub_140A278C0 以之为 +48 数组段界) | 不序列化 |
| +216 | 内联容器 | **per-slot 可用 goal token 表** (CPdxArray\<LexerToken\>×3 内联 {data@216→inline@248, cap@224=3, count@228, allocator\<CPdxArray,3\>@240}; 元素 24B 子数组存 goal def+3400 lexer token; 重建按 def+3336 槽 idx 推; UI CChangeGoalItem 族); **GUI: CChangeGoalWindow populate sub_141C08C40 逐槽建 CFilterGoalItem** (槽 idx = window+1664 = 0/1/2 short/medium/long_term; 元素 = goal def+3400 token 互证; 见 4.5.12) | 不序列化 |
| +320 | 内联容器 | **game_data** (CGameDate×3 内联 {data@320→inline@352, cap@328=3, count@332, allocator\<CGameDate,3\>@344}; 24B 元 {vt1@0, hours@8, vt2@16}; 按槽 idx 最近变更日期; AddGoal 写 `*(data+24*slot+8)=*(gs+1128)`) | 键 508=game_data |

#### 4.5.4 CFactionUpgradeStatus (upgrades, faction+2104, 184B)

ctor sub_1413F9DF0 / writer 0X1413FC350 / loader 0X1413FB750。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | vt | CFactionUpgradeStatus | |
| +16 | 匿名结构 (24B 形状) RH 桶数组 | **member_upgrades** {buckets@16, count 未决@24, mask@28, extra u8@32, lf@36=0.9} — 24B 桶 {dist+1@4, key token@8, value def 指针@16}; 键 10473 排序发射; loader case 10473→sub_1413F9490 | |
| +40 | CTechnologySharing 内嵌 80B | tech_sharing_group (键 14100) | |
| +120 | CDoctrineSharingStatus 内嵌 32B | doctrine (键 13817) | |
| +152 | 容器 24B | **slots 向量** {data@152, cap@160, count@164, alloc@168} — **424B 条目** (键 11879; loader case→sub_1413F98A0; 条目类名未决, 字段表见下) | |
| +176 | CFaction* | faction 回指 | |

slots 424B 条目 (writer 键互证):

| 槽偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | CAdvisorTemplate* | advisor def obj (idx@def+24 token 裸名) | ptr≠0; def 对象; 键 10454 |
| +8 | int32 | owner 国 idx → 引号 tag | >0; 键 10302 |
| +16 | CGameDate 24B {vt1@+16, hours@+24, vt2@+32} | spymaster_change_date | 键 19142; **≠43817520** |
| +40 | CModifier (192B) | spymaster (布局见 §4.4 CModifier 通用表) | 键 19140 = ADEC0(0x4AC4) |
| +232 | CModifier (192B) | modifier | 键 10597 = ADEC0(0x2965) |

#### 4.5.5 效果类锚定 (Execute = vtable slot[13])

| 效果 | Execute | 落点 |
|---|---|---|
| create_faction | 0X1404AB570 | → CFactionSystem::CreateFaction sub_140D91E00(facsys, tag, name) |
| add_to_faction | 0X1404AAC20 | → 外交链 + AddMember |
| add_faction_goal | 0X1404AA980 | → CFactionGoalStatus::AddGoal sub_140A26840(fac+1568, def, 1, …) (DLC50 门) |
| add_faction_goal_slot | 0X1404AA9C0 | → sub_140A26820(fac+1568, slot, n) (extra_goal_slots[slot]+=n) |
| set_faction_manifest | 0X1404ABBE0 | → sub_140A28B90(fac+1568, manifest def) |
| set_faction_name | 0X1404ABCE0 | → 写 fac+24 name 串 (经外交 +656 取阵营) |
| set_faction_leader | 0X1404ABB50 | → CFaction::SetLeader sub_140D8ED20 (写 +120=当前日期) |
| set_faction_spy_master | 0X1404AC040 | → sub_1413FC040(fac+2104, 0, tag, 0) |
| set_faction_rule | 0X1404ABE50 | → sub_140D8EC80 → sub_141995D40(fac+1392, rule) + 逐成员通知 |
| set_faction_upgrade | 0X1404AC090 | → a1+88 upgrade ref 虚调用 (CSetFactionUpgradeCommand 族) |
| dismantle/remove_from/leave_faction / remove_faction_goal / create_from_template | 0X1404AB8B0 / 0X1404ABAB0 / 0X1404ABA40 / 0X1404ABA70 / 0X1404AB6F0 | 均经外交 +656 链到 CFaction/CFactionSystem 方法 |

#### 4.5.6 CFaction loader 键表 (slot[4] = sub_140D8D880)

| 键 | 目标/行为 |
|---|---|
| 27 | +24 name |
| 181 | +1352 icon |
| 86 | +2512 color |
| 11838 | +136 ideology |
| 10918 | +88 members |
| 15149 | +128 日期代理 |
| 19482 | +1384 template (成功后 rule_status + goal_status 双重建) |
| 19557 | +1392 rule_status |
| 19589 | +1568 goal_status |
| 19753 | +2552 pings |
| 10482 | +1992 faction_programs |
| 12393 | +2104 upgrades |
| 13877 | +2288 manpower_pool |
| 16085 | +2320 extracted 资源池 |
| 10826 | +2624 variables |
| 16901 / 13500 / 10300 / 12817 | 读弃定案: 前三键 = yes/no 串读弃、12817 = 定点数读弃 — 仅 sub_1424C0C00/ABB10 消费, 无存储点 |

#### 4.5.7 定义对象侧副产 (CFactionTemplate / CFactionGoal; CIdeology 落点)

CFactionTemplate (库 getter sub_1404B2E60: +80 data / +92 count):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +208 | MSVC 串 | name (GetName 回退源) |
| +368 | CColor | color (16B 内嵌投影 = 裸 rgba, 见 §4.00.10) |
| +384 | rgba f32×4 | 初始阵营色 (取色窗/CreateFaction 初始色源) |
| +400 | u8 | has_color 旗 |

CFactionGoal def (库 getter sub_1404B2D60):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | — | 库内小整数 idx |
| +3336 | i32 | 槽 idx (0..3) |
| +3400 | token | lexer token (per-slot 可用 goal 表元素) |

CIdeology (意识形态 def) / CIdeologyGroup (意识形态组对象) 的**定义体与组对象全布局 = §4.10.12 (权威, 勿重述)**。
本侧仅记 **fac 落点** (自 ide/组 def 拷入阵营对象): fac+96 CRule 1016B (拷贝源) / fac+1120 CColor (ctor sub_14224BEE0) / fac+1152 与 fac+1344 CModifier 192B (pairs 自 ideology+1360 经 sub_1405570F0 拷入 fac+1176)。

CFactionUpgrade def (库 = qword_14332EEF0; faction goal/manifest def 库 = qword_14332EEE0, 与 CFactionIconsDatabase qword_14332EEE8 相邻):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +104 | u32 | 预期级 (推定) |
| +240 | 匿名结构 (NNB 形状) | def 虚槽[13] 取回值 (`sub_140A2B6D0 = return *(def+240)`) |
| +248 | u32 | **阈值/目标计数常量** (def 侧) — 日重置 sub_14118EC80 把 `*(def+248)` 作为**目标值**传入成员状态更新: `v17 = *(def+248); (*(*(sub_140A2B6D0(def))+96))(status, member, &v17)` |

相关 on-action 键: on_leave_faction / on_become_faction_member /
on_assume_faction_leadership。

#### 4.5.8 CStrategicResourcePool (阵营侧宿主: faction+2320 / facsys+56)

阵营侧宿主 (faction+2320 / facsys+56 同类); vt 0X29515A0, 元素 writer 0X140BCCAF0;
写门 = 条目 value ≠ 0 才写; 写序 = 向量序 = 资源定义序。
**类布局 (176B; 双级写门; 元素 16B {value i64×1e-5@0, name_id u32@+8}) = §4.13.6 (权威, 勿重述)**。

> **本域 GUI 类布局**: 见 4.30.40 / 4.30.41 / 4.30.42 / 4.30.43 / 4.31.21 / 4.31.31 / 4.31.32 / 4.31.56。
