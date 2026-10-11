

### 4.5 CFactionSystem (阵营)

**获取**: `fac = *(gs + 1016)` (facsys)。hourly = sub_140D928C0
("CFaction::ParallelPreHourlyUpdate"); CreateFaction 入口 = sub_140D91E00
(CCreateFactionEffect::Execute 0X1404AB570: `sub_140D91E00(*(gs+1016), tag, name, 0,0,0)`,
写新阵营 +2544 色槽 = 槽序−1)。

| 项 | 值 |
|---|---|
| RTTI 名 | CFactionSystem@NFactions |
| sizeof | ≥232 (ctor 至 +56 池 176B) |
| vtable RVA | 0x29665d8 |
| writer | 0X140D94370 |
| loader | 0X140D94100 (vtable slot[4]) |
| 挂载点 | `*(gs + 1016)` |

| 偏移 (facsys) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CFactionMemberStatus 稀疏阵 | **countries** (键 11593; 元素 208B, 见 4.5.1) | data@+8, size uint32@+20 |
| +32 | CFaction* 向量 | **CFaction 挂载** {data@+32, count@+44} 8B 指针, 写序 = 容器序 | |
| +56 | CStrategicResourcePool 内嵌 | **extracted 资源池** (键 16085; 条目 +0 = i64 定点 value, +8 = 资源 token; 元素表见 4.5.8) | hourly 与每阵营 fac+2320 池互转 (sub_140BCB530(fac+2320, country+40)) |

#### 4.5.1 CFactionMemberStatus (成员条目 208B = 0xD0)

元素 writer = SPersist\<CFactionMemberStatus\>::Write; loader sub_14118EB00;
ctor/Reset sub_14118D1A0; 日重置 sub_14118EC80; el = data+208×slot。
**槽占用条件** (λ 0X140D94270): `ru32(el+0)>0 且 *(*(国家数组[ru32(el)]+3976)+656)≠0`
或 completed_faction_goals 计数非零; 写形 = 先裸 size 再逐占用槽 `{index=N data={…}}`:

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | uint32 | 国家 idx (槽占用 λ `ru32(el+0)>0` 之源头) | |
| +8 | 匿名结构 (NNB 形状) 向量 24B | **influence_status** {data@8, cap@16, count@20 (**运行时恒=5** = EInfluenceStatType::COUNT), alloc@24} — 8B i64×1e-5 元 ×5 类目; 稀疏阵键 12819 只写非零槽 (λ 0X14118F590); AddInfluence sub_14118D8E0 断言 type<5 | 占用 = 值非零; **GUI: influence 占比分子** (+56 = 100000×Σ本表÷fac+2080) |
| +32 | 匿名结构 (NNB 形状) 向量 24B | **power_projection_stats** {data@32, cap@40, count@44 (恒=4), alloc@48} — 4×i64 fixed; GetPowerProjectionStat sub_14118DAB0 断言 idx<4 (faction_member_status.cpp:0x60); tooltip sub_140D8BC20 按 idx 0..3 求和 | |
| +56 | int64 fixed | **阵营 influence 占比** (sub_140D8F610 = 100000×成员Σinfluence÷fac+2080, clamp≤1.0; 写点 = 重算批一处 + 日重置清 0) — **GUI: 成员国列表行数值** (100×*(+56) 百分比化; 访问器 sub_140BB4AC0 = facsys+8+208×tag) | 定案 |
| +64 | int64 fixed | **+56 占比的镜像/前值副本** — 日重置 sub_14118EC80 同函数连续两次 `sub_1424EF6F0(&v, 100000)` 分别写 +64 与 +56 (均钳 ≥0); ctor sub_14118D1A0 同式成对写; 重算批 sub_140D8F610 只写 +56 | 高置信 |
| +72 | int64 fixed | initiative (键 13573; 日重置 0) | ≠0 才写; 领袖无此字段 = 0 |
| +80 | uint32 | **阵营 influence 排名** (sub_140D8F740 降序排名, 1=最高; def 直证 = token 19617 `faction_influence_rank` = 成员列表 sort_influence 排序键; 写点同 +56) — **GUI: 成员国列表行计数** | 定案 |
| +96 | 匿名结构 (24B 形状) RH 桶数组 | **member_upgrades** {buckets@96, count@104, mask u32@108, extra u8@112, lf f32@116=0.9} — 24B 桶 {dist+1 u8@4, key u32 token@8, value def 指针@16}; 键 10473 | 门 = 表非空 (20 档实测恒空) |
| +120 | int64 fixed | contribution (键 10477) | ≠0 才写; **GUI: 人力窗上限成分** (sub_14118A620 = 本值与 defines 基数求上限) |
| +128 | i64 fixed ×2 **内联** | **contribution_gain 定点对** (键 10504, 定长数组恒写 2 元, 内联 2×i64 — writer `for(v7=+128; v7!=+144; ++v7)` + loader case 10504 区间读双证) | 恒写 |
| +136 | int64 fixed | contribution_gain 定点 2 | 恒写 |
| +144 | CPdxArray\<pair\<CAiFactionTheater const\*, CFixedPoint\>\> | **AI 阵营战区权重表** {data@+144, cap@+152, **count@+156**, alloc@+160(&off_143085170)} — 元素 16B {战区 def 指针, 定点权重}; 权重计算 sub_141A49210 (CAiFactionTheaterDatabase qword_14332EDE0 逐模板算分); **1.19.3 无 push 写点 = 恒空运行时态, 日重置防御性释放**; loader 键表 {12819,13573,14209,12502,10477,10504} 无落 +144 的 case ⇒ 不序列化 | 形态定案 / 恒空定案 |
| +168 | int32 | **权重表有效条目计数** (df392 新档·推定: CleanupAfterMembershipChange 每按 +144 表置一位 0xFF 即 dec +168; 无重置点/其他读者证据, 需 grep 全域读者定案) | 推定 |
| +172 | int32 | **该成员国当前所属 AI 阵营战区分组 idx (−1 = 未分配)** — 日重置归 −1 (每日重评估); 消费链 4 处: 舰队发奖 sub_14118B9C0 (分组匹配 → 战区 commander 收益 qword_1433360B8×定点/100000) / GUI 选中态 / 成员国列表过滤 / 本地化键 FACTION_THEATER_COUNTRY_SELECT_NO_OWNER; **df392 复位写点** = CleanupAfterMembershipChange 擦除非成员 tag 时无条件置 −1 | 定案 |
| +176 | int64 fixed | war_score_breakdown (键 12502; 日重置 0) | 恒写 |
| +184 | CFactionGoal* 向量 24B | **completed_faction_goals** {data@184, cap@192, count@196, alloc@200} — 8B CFactionGoal def 指针元, 写 token@def+8; 键 14209 | 门 count≠0 (20 档实测恒空) |

#### 4.5.2 CFaction (2688B = 0xA80)

ctor sub_140D87F90 (逐项吻合到 +2672); writer 0X140D8FCF0; loader slot[4] =
sub_140D8D880 (全键表见 4.5.6)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | CReferenceObject 基 24B | {vtable@0, id 对 {type@+8=88, id@+12}, **u8 flag@+16 = CReferenceObject 基类 IsStored 旗** (ctor 置 0; 注册成功由 vtable[9] sub_14221E990→sub_14221E700 尾 `*(a1+16)=1` (id.cpp:130); 反注册 sub_14221EA60 首行 `if(!*(a1+16)) return 0` (id.cpp:210) 据此短路) | id 对恒写 |
| +24 | MSVC SSO 32B (size@+40) | **name** 引号 ("孟买条约" 等; SetFactionName 效果写 +24; GetName sub_140D8BB80 读 +24/+40) | **门 size≠0** (定案); **GUI: 阵营名行** (sub_140D8BB80; 外交 header faction_name 同链) |
| +56 | MSVC SSO 32B | **cached display name** (GetName 结果缓存: +24 非空→+24, 否则 template+208 名; 写入点 sub_140B59200; 不序列化) | |
| +88 | CCountry* 向量 24B | **members** {data@88, cap@96, count@100, alloc@104} — 8B CCountry* 元, tag=ru32(cc+8) 引号; AddMember sub_140D89A30 1.5x 增长 | c>0; **GUI: 成员国列表行** (sub_141474550: 色 = cc+848 沿宗主链取色 sub_1406ECF80 / 值 = facsys 条目+56 占比/+80 排名; 首元 = 领袖旗; faction_countries_window) |
| +112 | CGameDate 24B {vtable1@+112, hours@+120, vtable2@+128} | **faction_leader_change_date** (SetLeader sub_140D8ED20 `*(a1+120)=*(gs+1128)`; ADEC0 arg=a1+128=&vtable2) | **≠43817520** (双哨兵 §3.7) |
| +136 | CIdeologyGroup* | ideology def obj → token idx@def+8 → 裸名 | 恒写; def 对象 |
| +144 | **CRule 内嵌 1016B** (+144..+1159) | 阵营规则缓存 (运行时态; 拷贝源 = ideology def+96; 布局见下子表; 消费侧 sub_140D8A2A0 → sub_140638DB0(a2, a1+144)) | 不序列化 |
| +1160 | **CModifier 内嵌 192B** (+1160..+1351) | faction modifier (运行时合成; 源自 ideology def: +1168=*(ideology+1352), pairs 自 ideology+1360 经 sub_1405570F0 拷入 +1176; 全布局见 §4.3.8 CModifier 通用表) | 不序列化 |
| +1352 | MSVC SSO 32B (size@+1368) | icon 引号 | 恒写; **GUI: 图标行 + 命令写入链** (CFactionIconItem 读 = CFactionIconsDatabase qword_14332EEE8 {data@+80, count@+92}, §4.26.8; CSetFactionIconAndColor Execute 写本字段, icon 串@cmd+48) |
| +1384 | NFactions::CFactionTemplate* | template def obj → token 名 (sub_1424BE600) 引号; 默认 = token 10355 **original_generic_faction_template**; loader 成功后 rule_status+goal_status 双重建 | ptr≠0; def 对象 |
| +1392 | **CFactionRuleStatus 内嵌 176B** (+1392..+1567) | rule_status 块 (布局见下子表) | |
| +1568 | CFactionGoalStatus 内嵌 **424B** (+1568..+1991 恰满) | goal_status (见 4.5.3) | 恒写块 |
| +1992 | **CFactionProgramStatus 内嵌 ~64B** = faction_programs | {vtable@0, **CRef\<NProject::CProgram\> 向量 {data@8, cap@16, count@20, hybrid 内联 allocator@+24→inline@+32 (容 4)}**}; 元素 **8B CRef 双 u32 对** (writer sub_142220180 每元恰写两 u32 + u32 指针 +2 步进直证; 内联@+32 容 4 = 4×8B), 键 10482, 逐个 sub_142220180 写 GUID | **门 = count@+20≠0** (20 档实测恒空) |
| +2072 | int64 fixed×1e-5 | **total_power_projection** (阵营力量投射总值缓存, 累加钳 ≥0; AddPowerProjection sub_140D89E00; tooltip sub_140D8BC20 + loc TOTAL_POWER_PROJECTION "Total Power Projection: $VAL\|0H$"; 重算 sub_140D8FC30 从成员表 +88 汇总) | |
| +2080 | int64 fixed | **阵营级 influence 累计 (占比分母)** — sub_140D8F610 体: `v13 = *(fac+2080); v14 = Σ成员 influence(+8 容器 8B 元); v15 = 100000*v14/v13` (钳 ≤100000) 写成员 +56; 重算批 sub_140D8FC30 内 _InterlockedExchange64 归零 | 定案; **GUI: influence 占比分母** |
| +2088 | fixed×1e-5 | power_projection_from_effects (AddPowerProjection 同点互证; loc POWER_PROJECTION_FROM_EFFECTS) | ≠0 才写 |
| +2096 | CFactionSystem* | facsys 回指 (ctor `*(a1+2096)=*(gs+1016)`) | |
| +2104 | **CFactionUpgradeStatus 内嵌 184B** | upgrades 块 — 管理器本体 (见 4.5.4; 424B 是其 slots 向量条目步长) | 恒写块 |
| +2288 | CArmyManpowerValues 内嵌 32B | manpower_pool {vtable@2288, 容器@2296}; writer 双写 ADEC0(+2288) + sub_140C6AD50(+2288, out, 13877=manpower_pool) | 空块不发射 (20 档恒空); **GUI: CRequestManpowerWindow 消费链** (池合计 sub_140D8BAD0→sub_140C69830 + 成员 contribution(+120) + defines 基数 → REQUEST_FACTION_MANPOWER_VALUES; 提交 NFactions::CUseFactionMemberManpower {+40 amount/+44 tag}; 校验 "not enough manpower in pool"; 见 4.5.11) |
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
| +0 | vtable | 0x142718B48 (基 CPersistent) |
| +8 | MSVC 串 | name |
| +40 | 覆盖链表 | {head@+40, +48, count@+56} |
| +60 | uint8 | **覆盖清理墓碑保留旗** (唯一读者 sub_14063C170 RemoveExpiredOverrides: 覆盖值与基线全等即失效时, =1 仅标链表节点 flag@+24 保留 / =0 物理摘除并 free; 拷贝 ctor sub_14014AC90 显式清 0 = 运行时旗非内容; 置位写点待裁) |
| +64..+91 | 28B 字节数组 | rule 默认值 (初始化 = 规则库条目+50 默认值) |
| +92..+119 | 28B 字节数组 | rule 覆盖值 |
| +120..+1015 | 28×MSVC 串 内嵌数组 | 规则名串组 |

CFactionRuleStatus 布局 (fac+1392 相对; writer 0X1419966A0; loader case 19557;
CSetFactionRuleEffect → sub_140D8EC80 → sub_141995D40(fac+1392, rule,…)
+ 逐成员通知 sub_1406FF1F0):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | — |
| +8 | CFaction* | faction 回指 |
| +16 | NFactions::CFactionTemplate* | **模板回指** (三函一致消费: 规则库查 sub_1404AC0F0 / 模板名取 sub_1424BE600 入错误串 — §4.5.11; ctor 观察到的 0 系装载前态) |
| +32 | 哈希A | {sentinel@+32, count@+40, extra@+48, lf@+52 = 0.9f} — ⚠ 槽名义待重验: 读者 sub_1404AC0F0 实读 data@+32 / mask&@+44 (count 槽推定为 data / lf 槽推定为 mask; §4.5.11) |
| +64 | 哈希B | 同哈希A 形 |
| +88 | CFactionRule* 向量 24B | **rules 向量** {data@+88, cap@+96, count@+100, alloc@+104} — CFactionRule def 指针; 键 12667=rules, 写 token@def+8 |
| +112 | 哈希C (容器基) | {data@+120, mask&@+132} — 读者 sub_140A2F180(rs+112,…) 直证容器基 = +112 (书旧记 +120 系 data 槽误当基, 已改); 键 = def 指针 8 字节 FNV-1a, 值 = def (§4.5.11) |
| +152 | 哈希D | — **GUI: change_rule_window populate sub_141C0D680 消费** (cpp:83 "show_filter_offset" 断言; RH 8B 元 {distance@0, rule token@+4}; 见 4.5.12) |

CColor 内嵌布局 (fac+2512 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | — |
| +16 | rgba float×4 | 颜色值 (`int(f*255)` **截断**; alpha ≠1.0 才第 4 值, writer 0X14224CA10) |
| +32 | uint16 | 0xFFFF 哨兵 (ctor −1; CreateFaction 写槽序−1, 重排 sub_140D922F0 写槽 idx — **阵营色索引/槽号** 高置信) |

CFactionTheaterManager 布局 (fac+2552 相对; ctor sub_14194F550 64B 直证):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | — |
| +8 | CFaction* | faction 回指 |
| +16 | uint32 向量 24B | theaters {data@+16, cap@+24, count@+28, alloc@+32}; **条目 stride = 168B** (运行时条目; commander 元素 = 8B 内联 CRef id-pair, sub_141950A80 判非零后 sub_14221F310 解引用; GUI 视 +0 name / +32 tag / +36 commander / **+48 = 国家 tag (CCountryTag u32) 排序列表 {data@条目+48, cap@+56, count@+60}** (df392: 成员变动时按阵营资格经 sub_14194F1C0 lower_bound 擦除, 有序为擦除前提) / **+72 = int32 下标列表 {data@+72, cap@+80, count@+84}** (df392: 元素被当作 member+144 表与 mgr+40 表的字节下标逐位置 0xFF; 与 +144 表 16B 元形态冲突 → 待裁, 见下 CleanupAfterMembershipChange 段) / **+160 脏标志 u8** (df392 新档: sub_1419511D0 置 1, 压缩时据此跳过覆盖), 见 §4.31.31) |
| +40 | 匿名结构 (1B 形状) 向量 24B | **第二向量** {data@+40, cap@+48, count@+52, alloc@+56} — per-theater 分组字节表 (元素 1B; 与 member_status+172 同 idx 域比对, sub_14118B9C0; **df392 写点**: 成员退出/战区清除时 sub_1419510E0 按条目+72 下标逐位置 0xFF) |

theaters 序列化键集 (writer sub_141BAEB30 / loader 双证): 10754 tag→+40 / 27 name 串→+48 / 13994 execution_type→+80 / 11355 commander idpair→+84 (sub_142220180) / 11593 regions u32 数组 {data@+96, count@+108} / 12065 容器→+120 / 12799 容器→+144 / 19482 template def→+168 / 524 枚举→+176 — 序列化条目与运行时 168B 条目偏移不齐 = 两套基 (对应关系待裁)。战区模板 def = NFactions::NAi::CAiFactionTheater 264B (库 qword_14332EDE0 {data@+80, count@+92}; +8 名 token / +32 name 串 / +64 +120 +144 容器 / +168 对象 / +256 u8 旗; **+120 = regions 容器** 24B CPdxArray {data@+120, cap@+128, count@+132, alloc@+136} — 推定, 无调用者仅字段对齐)。**地区表校验器 0x1406336F0** (ai_faction_theater.cpp; a1 = 模板 def 推定): count@+132 == 0 → 错误 "\<名\>: region list is empty" (:30); 最大元 (sub_14251D090 int 数组 max) > `CStrategicRegionDatabase (qword_14332F080) +52 库计数 − 1` → 错误 "\<名\>: region list contains invalid entries (max id = \<上限\>!)" (:38) + **清 count@+132 = 0** 使该地区表失效 — 即地区 id 为密集数组下标, 最大合法 id = count−1。

theaters 条目 (内层键 12065=regions):

| 条目偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | MSVC 串 | name |
| +32 | uint32 | tag (键 10754) |
| +36 | 匿名结构 (元素待裁) 向量 | commander (键 11355) |
| +120 | — | execution_type (键 13994); 枚举 0=careful / 1=balanced / 2=rush / 3=rush_weak |
| def+8 | token | template (键 19482) |

**CFactionTheaterManager::CleanupAfterMembershipChange = sub_141951690** (df392 定案, 289 行, asm 逐条核验): 阵营成员变动后的战区清理, 单实参 this (无返回值)。三调用方 = **CFaction::RemoveMember sub_140D8E2F0** (尾调 sub_141951690(a1+2552) — §4.32 leave_faction 链闭合) / sub_1419505F0 / sub_1419507E0。**三重资格过滤** (两遍扫描共用): ① 条目+32 归属国 tag > 0; ② cc+1156 owned_states 计数 > 0 (活跃国门); ③ sub_14118D710(归属国) == *(CFaction**)(mgr+8) (当前阵营 == 本 faction)。任一失败 = 失格, 收集之。

| 遍 | 动作 | 手段 |
|---|---|---|
| 第一遍 | 收集失格战区索引入本地 int 向量 (SSO 32 元内联缓冲分配器) | sub_1419511D0(mgr, 向量) = 索引合法者条目+160 置脏 → 全量 sub_1419510E0 复位分组 → 就地压缩 theaters (跳脏位逐段移动) → sub_141950E90 收尾 → 逐条 sub_14194FBC0 刷新 |
| 第二遍 | 逐剩余战区: 收集其 +48 tag 列表内失格 tag → sub_14194F1C0 擦除 → 对每个被擦 tag 的 CFactionMemberStatus 条目按条目+72 下标把 +144 表逐字节置 0xFF 并 dec +168, 再无条件 +172 = −1 | 本地 CCountryTag 向量 (同分配器 SSO 32 元) |

**同域新函 (df392 首立)**: sub_1419511D0 = 战区条目批量摘除 (置脏 → 复位 → 压缩 → 刷新链; 压缩移动经 sub_14011FE60 name / +32 tag / +36 commander / +48 sub_140157780 / +72+96 sub_140155CD0 / +120 / +128 / +136 sub_140157780 / +160 旗) / sub_14194F1C0 = 排序 int 容器批量擦除 (lower_bound → 越等值段 → memcpy 移位 → count −= n, 返擦除数) / sub_1419510E0 = 单战区分组清理 (+48 tag 逐一 member+172 = −1 + 按 +72 下标置 member+144 与 mgr+40 表字节 0xFF; 亦被 CClearFactionTheater sub_1419503E0 复用, §4.33) / sub_141950E90 向量收尾 + sub_14194FBC0 单战区刷新 (仅见调用, 体未通读)。

⚠ **条目+72 下标 vs member+144 表步长冲突 (待裁)**: df392 与 sub_1419510E0 均以**字节步长**索引 +144 表 (add 寻址不带 scale, 逐字节写标记值), 与 §4.5.1 +144 表「16B 元 pair」形态定案不能同时成立。可能解: ① +144 表元素实为 1B (书形态待翻); ② +72 元素是字节偏移而非下标; ③ 该标记路径为防御性死码 (书已载 +144 表 1.19.3 恒空、count@+156 恒 0 ⇒ 循环体永不执行, 仅 +172 = −1 生效, 从未被真实数据检验)。需查权重计算 sub_141A49210 的写入步长方可定案。

CVariables 内嵌布局 (fac+2624 相对):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | — |
| +8 | uint32 | 1 (random 门 ru32(vo+8)!=1 读此) |
| +12 | — | 种子 1587985054 |
| +24 | — | &unk_1430851A0 |
| +32 | — | 0 |
| +40 | uint8 | 0 |
| +44 | float | 0.9 |
| +48 | — | 0 |

#### 4.5.3 CFactionGoalStatus (goal_status, faction+1568, 424B 恰满)

ctor sub_140A25C70 / writer 0X140A299E0 / loader 0X140A28300。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | CFaction* | faction 回指 | |
| +16 | 匿名结构 (faction manifest 定义)* | manifest def = **NFactions::CFactionGoal** (H 批类名落定 — 库模板参数直证, goal/manifest 同类; sizeof 3408B; +896 内嵌 CRatioProgress ≥2416B (CProgress 基 1120B + 派生扩展至 +2408; 后继 def 字段 +3336 钉上界 ≤2440B)) → token idx@def+8 裸名 (键 19587; CSetFactionManifestEffect::Execute 0X1404ABBE0 → sub_140A28B90, DLC50 门) | ptr≠0; **双半缩放偏移基准 = CProgress 相对 (def+928/def+1472)**; +3336 优先级类 (manifest 恒 4, 活证五阵营); entry 1344B 布局定案 (entry+96 = def+896 活证地址和; entry+1312 = 紧随 +296 CRule (1016B) 之后的独立 qword 槽 (默认 0x53E2D61FD320; 语义两说待裁: initiative 分摊源 vs s4_32 faction_manifest_fulfillment 触发器名锚定 manifest 履行值; **立即数本身 = fixed×1e-5 域饱和上界** (92233720124192, 定点换算 sub_1424ED580 溢出钳位值, 见 §4.00), 引擎通用「定点域最大值」哨兵)); def+2664 u8 / def+2872 u32 = 描述需实例状态门对 — 任一非零则 tooltip 结合 faction+1592 goals 容器内当前实例进度渲染 (sub_140A222D0) |
| +24 | uint32 向量 24B | **goals** {data@24, cap@32, count@36, alloc@40} — 1344B 步长: goal def@+0 (idx@def+8 裸名), status u32@+8 (0=active 11390 / 1=completed 12583 / 2=canceled 19620, 断言 "Invalid goal status" faction_goal_status.cpp:0x2F), date 24B {hours@1328, vtable1@1320, vtable2@1336} 键 508=game_data (无门恒写; 默认 43808760 → "1.1.1.1"); 块外键 19593 (goals) / 条目内键 19592 (goal) / status 键 208; AddGoal sub_140A26840 (DLC50 断言实在内层 sub_140A26A70 首行) 去重插入; 条目 init 三路并存: AddGoal 路径构造器 sub_140A261E0 (写 vtable1@1320/hours@1328=43808760/vtable2@1336 — 单 24B CGameDate 的 vtable1@+0/vtable2@+16 两段形, 非两对象) / 读档追加器 sub_140A23AC0 (malloc 1344×cap, memset +12 起 0x534 + CGameDate@1320 init) / +16 区 sub-ctor sub_140A263A0; **goals 条目 reader = 0x140A23C70** (块 driver 0x140A24D20 先清零向量 → 追加 → 三键解析: 19592 goal 库查 def 入 +0 (未找到 :81 "Goal Status does not have a goal token:%s") / 208 status {11390→0, 12583→1, 19620→2, 余断言 :63 "Invalid goal status token"} / 508 game_data → +1336; 尾段 = **def 派生载荷重建**: +16 区重灌 / +96 = def+896 / +112 / +120 区 (176B) / +296 CRule 重默认 ctor 后整块拷入 / +1312 = 0x53E2D61FD320 — **落盘契约 = 每条只存 {goal, status, game_data} 三键, +16..+1319 def 派生载荷读档后由 def 现算重建**) | c>0; **GUI: 目标列表** (sub_140A27930 → FOREIGN_GOAL_ITEM_ENTRY) |
| +48 | 匿名结构 (8B 形状) 向量 24B | **available_goals 平铺 def 指针数组** {data@48, cap@56, count@60, alloc@64} (重建序 sub_140A28FD0 增量 = ① count 双清 → +216 容量重置 (cap<3 时 x1.5 扩至 3, 3 个 24B 子数组清零) → +168 偏移表 resize 4 清零 → 遍历 **goal def 库 sub_1404B2D60()** {+80 def 指针数组, +92 数量} → 可用性谓词 **sub_140A21DB0(def, status+8 faction 回指)** → 按 def+3336 类分桶 (+168 bucket[class]++, >=4 不入桶) + def+3400 token 去重入 +216 第 class 槽 + 尾插 +48; 桶前缀和即 +168 段界生成端; 收尾双 **stable_sort** = +48 数组 (8B 元, 栈阈 0x200) + +216 三子数组各排 (4B 元, 栈阈 0x400, j+=24 步进); 调用者三处 = faction+1568 显式 / sub_140A27B80 / sub_140A28EA0) — 8B 元按槽分段拼接 (区间切分器 sub_140A278C0: `begin=data+8*off[slot]`, off=+168 表) | 不序列化 (运行时重建 sub_140A28FD0) |
| +72 | 匿名结构 (NNB 形状) 向量 24B | **completed_goals** {data@72, cap@80, **count@84**, alloc@88} — 8B def 指针元; 键 12787 | 门 count≠0 |
| +96 | 匿名结构 (NNB 形状) 向量 24B | **canceled_goals** {data@96, cap@104, **count@108**, alloc@112}; 键 12788 | 门 count≠0 |
| +120 | 匿名结构 (NNB 形状) 向量 | **extra_goal_slots** (i32×3 内联 {data@120→inline@152, cap@128=3, count@132, allocator CPdxStaticInlineBufferAllocator\<int,3\>@144}; 引擎按有符号打印, −1 在档); 槽名 0=short_term 1=medium_term 2=long_term (sub_140A233B0); AddFactionGoalSlot 效果 → sub_140A26820 `*(data+4*slot)+=n` | 值≠0 |
| +168 | 匿名结构 (NNB 形状) 向量 | **per-slot available goal 计数/前缀偏移表** (i32×4 内联 {data@168→inline@200, cap@176=4, count@180, allocator\<int,4\>@192}; 切分器 sub_140A278C0 以之为 +48 数组段界) | 不序列化 |
| +216 | 匿名结构 (24B 形状) 向量 | **per-slot 可用 goal token 表** (CPdxArray\<LexerToken\>×3 内联 {data@216→inline@248, cap@224=3, count@228, allocator\<CPdxArray,3\>@240}; 元素 24B 子数组存 goal def+3400 lexer token; 重建按 def+3336 槽 idx 推; UI CChangeGoalItem 族); **GUI: CChangeGoalWindow populate sub_141C08C40 逐槽建 CFilterGoalItem** (槽 idx = window+1664 = 0/1/2 short/medium/long_term; 元素 = goal def+3400 token 互证; 见 4.5.12) | 不序列化 |
| +320 | 匿名结构 (24B 形状) 向量 | **game_data** (CGameDate×3 内联 {data@320→inline@352, cap@328=3, count@332, allocator\<CGameDate,3\>@344}; 24B 元 {vtable1@0, hours@8, vtable2@16}; 按槽 idx 最近变更日期; AddGoal 写 `*(data+24*slot+8)=*(gs+1128)`) | 键 508=game_data |

**CRule (1016B, RTTI `.?AVCRule@@` 直证; faction goal 条目 +296 内嵌)**: ctor sub_140638A10; +8 desc 串 (token 10644) / +40 链表头 24B / +64 规则值表 byte×28 / +92 显式设定旗 byte×28 / +120 override 名串槽 32B×28 (元构造 sub_14011E1C0); 紧随其后的条目 +1312 独立 qword = 0x53E2D61FD320 (64 位立即数 = fixed×1e-5 域饱和上界哨兵, 非 CRule 内部字段); 全域机制见 §4.3.7a。

#### 4.5.4 CFactionUpgradeStatus (upgrades, faction+2104, 184B)

ctor sub_1413F9DF0 / writer 0X1413FC350 / loader 0X1413FB750。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | vtable | CFactionUpgradeStatus | |
| +16 | 匿名结构 (24B 形状) RH 桶数组 | **member_upgrades** {buckets@16, **count@24**, mask@28, extra u8@32, lf@36=0.9} — 24B 桶 {dist+1@4, key token@8, value def 指针@16}; 键 10473 排序发射; loader case 10473→sub_1413F9490; ctor sub_1413F9DF0 直证 count@24 | |
| +40 | CTechnologySharing 内嵌 80B | tech_sharing_group (键 14100) | |
| +120 | CDoctrineSharingStatus 内嵌 32B | doctrine (键 13817) | |
| +152 | 匿名结构 (424B 形状) 向量 24B | **slots 向量** {data@152, cap@160, count@164, alloc@168} — **424B 条目 = 阵营情报顾问槽 ×4** (slot0 = spymaster, slot 名 "intelligence_advisor_slot_spymaster"/"intelligence_advisor_slot"; DLC25 门 sub_1401AEB50; 键 11879; loader case→sub_1413F98A0; 条目无独立 RTTI 类名 = 内联结构; 写者 sub_1413FC040 = set_faction_spy_master 落点: 写 +0 advisor def/+8 owner, owner>0 → +24 = gs+1128 当前小时、≤0 → 哨兵; 字段表见下) | |
| +176 | CFaction* | faction 回指 | |

slots 424B 条目 (writer 键互证):

| 槽偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | CAdvisorTemplate* | advisor def obj (idx@def+24 token 裸名) | ptr≠0; def 对象; 键 10454 |
| +8 | int32 | owner 国 idx → 引号 tag | >0; 键 10302 |
| +16 | CGameDate 24B {vtable1@+16, hours@+24, vtable2@+32} | spymaster_change_date | 键 19142; **≠43817520** |
| +40 | CModifier (192B) | spymaster (布局见 §4.4 CModifier 通用表) | 键 19140 = ADEC0(0x4AC4) |
| +232 | CModifier (192B) | modifier | 键 10597 = ADEC0(0x2965) |

> **槽资格检查器 sub_1413FA740 (df362 定案)**: 判「国家能否出任/替换槽」——槽被他人占 → 先验 initiative ≥ FACTION_INTELLIGENCE_UNLOCK_COST (dword_1433357C8), 再按槽构 CDiplomaticAction 派生动作 (0=CTransferSpyMasterAction 19141 / 1=Cryptology 10541 / 2=CounterIntel 10540 / 3=Operations 10544; 基布局 = §4.10.13) 过「MP 服务器直通 → 在途检查 → agency 通用条件 (cc+4032 +108/+192)」∧ initiative ∧ 自转移豁免+库条件求值三重 AND; 槽空或候选即现任 → sub_140FD8F60 (BECOME_SPY_MASTER_* 五文案族 + FACTION_INTEL_HEAD_OF_〈槽名〉 键)。调用方 sub_141C24180 (带文案出参) / sub_141C25130 系 (无)。

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
| set_faction_upgrade | 0X1404AC090 | 载荷对象(a1+88) 取升级 def (vtable[13]/+104 getter) → **花费 = *(def+248)** → 载荷 vtable[12](scope tag, &花费) 执行购买; 货币 = initiative (loc FACTION_UPGRADE_NOT_ENOUGH_INITIATIVE; 命令 NFactions::CSetFactionUpgradeCommand ctor sub_141BA8EB0) |
| dismantle_faction | 0X1404AB8B0 | 门 = 有阵营 ∧ **发起者是领袖** (members[0] tag 比对) → 直接 RemoveFaction sub_140D922F0 + 名字刷新; 非领袖无操作 (§4.5.9) |
| set_faction_rule | 0X1404ABE50 | → sub_140D8EC80 → sub_141995D40(fac+1392, rule) + 逐成员通知 |
| set_faction_upgrade | 0X1404AC090 | → a1+88 upgrade ref 虚调用 (CSetFactionUpgradeCommand 族) |
| create_from_template | 0X1404AB6F0 | → 先 sub_14118BA30(cc,0,1,1) 离开现有阵营, 再 **CreateFaction 六参形态** sub_140D91E00(facsys, tag, name@a1+176, 备选名@a1+96(门 a1+128), 本地化名@a1+144(门 a1+160), template@a1+208); 尾 sub_140A66B70/6D00 名字刷新 |
| dismantle/remove_from/leave_faction / remove_faction_goal | 0X1404AB8B0 / 0X1404ABAB0 / 0X1404ABA40 / 0X1404ABA70 | 均经外交 +656 链到 CFaction/CFactionSystem 方法 |

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
| +384 | rgba float×4 | 初始阵营色 (取色窗/CreateFaction 初始色源) |
| +400 | uint8 | has_color 旗 |

CFactionGoal def (库 getter sub_1404B2D60):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | — | 库内小整数 idx |
| +3336 | int32 | 槽 idx (0..3) |
| +3400 | token | lexer token (per-slot 可用 goal 表元素) |

**CFactionGoal 装载三连校验 (0x140A233F0, faction_goal.cpp, 高置信; 全部致命 — ios_base failure → terminate)**: ① +3404 auto_complete 置 ∧ ratio_progress (def+896 内嵌) 空 → :83 "<goal 名>: auto_complete is set, but ratio_progress is empty"; ② +3405 is_manifest 置 ∧ ratio_progress 空 → :87 同款 (置位时跳过 ③); ③ **+3400 group == 357 (空哨兵, 库内小整数索引哨兵通则)** → :93 "<goal 名> does not have have a group" (源串双 have 原样; 仅报错非终止)。旁路: **def+2664 byte ∨ def+2872 dword 置位 → 三连全跳** (推定 = 内建/特殊 goal; 两槽与 §4.5.3 已载「描述需实例状态门对」同槽)。

**派系规则装载校验 (faction_rule.cpp, 高置信)**: 错误通道 = CLogStream 链式拼接 (sub_1424C9240 → sub_1424C9AE0 → sub_1424C8E30 / sub_1424CB4C0 / sub_14011D290 → sub_1424C89E0 写 &CLogStream::vftable, 尾 std::ios_base 析构 sub_14251C47C) 后**抛出引擎错误**, 装载期未捕获即致命 (unwind = terminate())。① **CFactionRule 引用修正存在性 0x140A2D080** (flags 65540): 遍历 rule+568 (24B pdx 向量 {data@+568, cap@+576, count@+580, alloc@+584}, 元 = u32 peace action modifier id), 逐 id 查 **qword_14332EFC8 (TGameItemDatabase 实例)** 存在性 (sub_140A84750); 失败 → faction_rule.cpp:53 "Peace action modifier '<名>' referenced in '<条目名>' is missing or is not a faction modifier (NOTE: peace action modifiers used by faction rules must use 'faction_modifier = yes')" (与 §4.10 CPeaceActionModifier +140 faction_modifier 字段互证)。② **CFactionRuleGroup 默认规则存在性 0x140A2D580** (宿主 = **组**, 非 rule — CFactionRule ctor sub_140147950 在 +40 起 ctor 六个 CAndTrigger (sub_140549F40), +40 不可能是 16B 步距数据数组; 且文案 "is missing from" 为组语义; flags 4096): 组+32 默认 id (**== 357 (none 哨兵) 直接跳过**), 遍历组+40 / +52 (16B 步距) 元素解引用后 +8 = id 比对; 找不到 → :207 "default rule '<名>' is missing from '<组名>'"。**CFactionRuleGroup 布局 (推定 → 高置信)**: +8 u32 名 id (df389 旁证转强: 基初始化器 sub_1424BE3C0 对 CModifier / CFactionRule / CFactionRuleGroup 三方同写 +8 = 357, 名 id 为基族共用字段而非组专属) / +32 默认规则 id (357 哨兵) / +40 rules 数组 {data@+40, cap@+48, count@+52, alloc@+56}, 16B 元 {CFactionRule* @0, …}, 匹配键 = 条目+8 名 id。**库级编排器 sub_140A2E520** (本批新定位): 遍历库 a1+80 数组 (8B 元, count@+92) 逐**组**, 每组遍历其 +40 数组 (16B 步距, count@+52) 逐**条目** → 0x140A2D080(条目)。

CIdeology (意识形态 def) / CIdeologyGroup (意识形态组对象) 的**定义体与组对象全布局 = §4.10.12 (权威, 勿重述)**。
本侧仅记 **fac 落点** (自 ide/组 def 拷入阵营对象): fac+96 CRule 1016B (拷贝源) / fac+1120 CColor (ctor sub_14224BEE0) / fac+1152 与 fac+1344 CModifier 192B (pairs 自 ideology+1360 经 sub_1405570F0 拷入 fac+1176)。

CFactionUpgrade def (库 = qword_14332EEF0; faction goal/manifest def 库 = qword_14332EEE0, 与 CFactionIconsDatabase qword_14332EEE8 相邻):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +104 | uint32 | 预期级 (推定) |
| +240 | 匿名结构 (NNB 形状) | def 虚槽[13] 取回值 (`sub_140A2B6D0 = return *(def+240)`) |
| +248 | uint32 | **阈值/目标计数常量** (def 侧) — 日重置 sub_14118EC80 把 `*(def+248)` 作为**目标值**传入成员状态更新: `v17 = *(def+248); (*(*(sub_140A2B6D0(def))+96))(status, member, &v17)` |

相关 on-action 键: on_leave_faction / on_become_faction_member /
on_assume_faction_leadership。


#### 4.5.7a CFactionTemplate 规则域 (faction_template.cpp; 2 函 — 装载后规则解析器 + 九键 reader)

CU = `hoi4\source\diplomacy\factions\faction_template.cpp`。对 §4.5.7 直证无冲突; 本节补规则域与 def 布局增补。

**def 布局增补** (书 §4.5.7 已载 +208 name / +368 color / +384 rgba / +400 has_color 之外):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +8 | uint32 | 模板名 token (10355 = original_generic_faction_template 基准) |
| +32 | CPersistent 成员 | visible 条件 (虚读) |
| +120 | CPersistent 成员 | available 条件 (虚读) |
| +240 | u32 数组 {data@240, cap@248, count@252, alloc@256} | default_rules token 数组 |
| +264 | RH 表 (24B 桶 {dist u8@+4, 组 def@+8, 规则 def@+16}; 头 buckets@272 / mask@284 / extra@288) | 规则解析结果 (装载后构建, 非 reader 侧) |
| +296 | CFactionGoal* | manifest goal def |
| +304 | 容器 | goals uniform 列表 (CInlinableGameItem\<CFactionGoal\>::SUniformReader\<CFactionGoalDatabase,7\> vftable 直证) |
| +328 | uint32 | can_leader_join_other_factions |
| +336 | — | icon (读形 sub_1424C0AB0, 返回类型待裁) |

**装载后规则解析器 0x140A2FDB0 (829 行, 定案)**: 前置注入 = `*(u32*)(tpl+8) != 10355` (非默认模板) → sub_140A2F710 push token **change_leader_rule_influence** 进 +240 数组 (1.5× 增长直证)。两遍解析: 第一遍 = 逐 +240 token 在规则组库 sub_140177440() {data@+80, count@+92} 全库各规则组 def 的 +40 容器 (16B 元, def+8 = token) 找匹配 — 命中以组 def 指针 8B FNV-1a 为键查/插 +264 RH 表 (value = 组内命中元素 def), 未命中 :77 "Default rule '<规则名>' did not match any of the rule groups in '<模板名>'", 表内重复 :86 (完整句式待裁); 第二遍 = 逐规则组 def 不在模板表者按 **组 def+32 (组默认规则 token)** 找元素插入。结果 = 「规则组 → 该模板生效的规则 def」全映射 (阵营运行时规则经此间接, 与 §4.5.2 fac+144 CRule 拷贝源衔接)。错误 = PdxError 抛出形。

**reader 0x140A310B0 九键全实名**: 27 name → +208 / 86 color → +368 CColor + +384 rgba 16B + +400 has_color (CColor::vftable 直证) / 181 icon → +336 / 10440 can_leader_join_other_factions → +328 / 11562 visible → +32 (虚读 vt[+40]) / 12264 available → +120 / 19541 default_rules → +240 / 19587 manifest → goal 库 (§4.5.7 getter) 按 token 查, 空 :34 "Faction goal not found in the database: <名>", `*(def+3405)` is_manifest 旗 0 → :38 " is_manifest flag is not set for <名>" / 19593 goals → +304 uniform 列表读。未知键跳块。
#### 4.5.8 CStrategicResourcePool (阵营侧宿主: faction+2320 / facsys+56)

阵营侧宿主 (faction+2320 / facsys+56 同类); vtable 0X29515A0, 元素 writer 0X140BCCAF0;
写门 = 条目 value ≠ 0 才写; 写序 = 向量序 = 资源定义序。
**类布局 (176B; 双级写门; 元素 16B {value i64×1e-5@0, name_id u32@+8}) = §4.13.6 (权威, 勿重述)**。

> **本域 GUI 类布局**: 见 4.30.40 / 4.30.41 / 4.30.42 / 4.30.43 / 4.31.21 / 4.31.31 / 4.31.32 / 4.31.56。
> **访问器** (定案, vftable 符号直证): 复制减 sub_140BCB3B0 / 复制加 sub_140BCB470 /
> 按 tag 加 sub_140BCB580 (阵营汇入 sub_140BCB530 为 hourly 主通道)。
> **facsys+56 全局池读侧** (§4.00.4b): docvar `global_resource_extracted_total` 求值体 sub_140BCC2F0 逐元素求和 = 世界已开采资源总量; `global_resource_extracted` sub_1401F52D0 经 facsys+64 池 data 16B 步进定长槽直读单资源。

#### 4.5.9 阵营目标/升级/项目/创立/解散/易主执行链

**目标五态状态机** (entry+8, 定案): 0 active / 1 completed / 2 canceled /
**3 待完成 / 4 待取消** (并行相置态 → 同一 tick 串行相消费; 3/4 永不落盘,
writer 断言 "Invalid goal status" faction_goal_status.cpp:47)。

hourly 双相 (宿主 = CFactionSystem::HourlyUpdate sub_140D928C0, §4.2.18 展开):

| 相 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 前奏 | sub_140D928C0 | 清 facsys+56 全局池与逐阵营 fac+2320 池 → 逐活跃国汇入 cc+4600+40 资源 (有阵营国再入阵营池) | 定案 |
| 并行叶 | sub_140D8D470 | **CFaction::ParallelPreHourlyUpdate** (tbb): 力量投射 sub_140D8FC30 (`fac+2072 = FACTION_POWER_EFFECTS_WEIGHT qword_143333D60 × fac+2088 /1e5 + 成员求和`) + 目标置态 sub_140A270E0 (progress ≥100000 ∨ check_completed → status=3; check_canceled → 4); check_completed = sub_140A22050 (门 def+60, 求值 def+40 CAndTrigger 槽[3], scope=阵营领袖) / check_canceled = sub_140A21FA0 (门 def+588, def+568) | 定案 |
| 串行施效 | sub_140D8CA20 → sub_140A27280 | zone **"faction_goals"**: 逐条目 sub_140A27530 — status 3 → 盖章 +1328 = gs+1128 + **执行 on_completion 效果块** (门 def+412, def+392, 领袖 scope) → status 1; status 4 → 盖章 + **on_cancel** (门 def+676, def+656) → status 2; 完成登记 sub_140A28070 (push completed_goals +72 + 逐成员 completed_faction_goals member+184 广播); 玩家门 → 历史记录 "goal_completed" + 生涯计数 faction_goals_completed (member+220; def+3336==2 长期档 +232); 取消 push canceled_goals +96; 尾 sub_140D8F3C0 逐成员脏派发 (sub_1406FF1F0) | 定案 |
| 成员变更即时结算 | sub_140A27190 | 同款置态循环 + status 3 即时登记置 1 (**不执行效果块** — 效果仍等 hourly) | 定案 |

daily 五步内务 (**sub_140D8D490**, DLC50 "Deeper Factions" 门; 调用顺序 =
theater 版 sub_140D935A0 → sub_140D8D850 在前, 五步 sub_140D93560 在后):

| 步 | 函数 | 语义 | 置信 |
|---|---|---|---|
| ① goal 进度 | sub_140A29690 → sub_140A29920 | 门 = status==0 ∧ (def+2664 ∨ def+2872); 领袖 scope 求值 def+896 CProgress (sub_140A1FFE0) → **sub_14153B770 更新 entry+16 CProgressStatus**: 缓存进度 entry+1312 不变返 0; 变则重算阶段列表 (阶段库 = def+904 指针, 1808B 条目 {+24 CModifier, +40 u8 门, +568 CRule}) + 全量并入修正 + CRule 合并 + **双半缩放** (entry+120 修正: def+32 半 × progress + def+576 半 × (1e5−progress)); 返回脏旗 (bit2 修正/bit4 规则) | 定案 |
| ② 升级巡检 | sub_1413669E0 | 仅虚调 (fac+2104)+40 CTechnologySharing **vtable[9]** = 研究共享成员资格巡检 (§4.2.7 序9 同槽); 成员级升级进度在成员状态日重置 sub_14118EC80 尾 (逐升级 def: obj=*(def+240) 调 vtable[12](成员状态, &def+248 阈值)); **升级货币 = initiative** (FACTION_UPGRADE_NOT_ENOUGH_INITIATIVE) | 定案 |
| ③ 项目贡献 | sub_141993400 | 逐 program (fac+1992) 逐成员: 贡献 = FACTION_INFLUENCE_SCIENTIST_CONTRIBUTION_VALUE qword_143333D20 × (mdef648+1e5)/1e5 → sub_14118D870 入账 | 定案 |
| ④ 影响力矩阵 | sub_140D8F420 | N×N 矩阵 → **CFaction::UpdateInfluence** (tbb 符号 sub_140D84E00) → 归约 fac+2080 (InterlockedExchange) → 成员占比 +56 (sub_140D8F610) + 排名 +80 (sub_140D8F740) | 定案 |
| ⑤ initiative 分摊 | sub_140D84FF0 | **PassiveInitiativeGeneration** (lambda 符号): 池 = PASSIVE_INITIATIVE_GENERATION qword_1433351D0 × manifest 条目进度 (entry+1312)/1e5 → 逐成员 initiative(+72) += 池×占比(+56)/1e5 | 定案 |

阵营升级/图标 def 族 (faction 域库件三定案):

| 类 | 定案 |
|---|---|
| NFactions::CFactionUpgradeGroup | 成员升级组的**共享实现基座** (def 件 13 槽家族形状); 无独立实例/无独立库/无加载路径 = 结构性基类, 不立节 |
| NFactions::CFactionMemberUpgradeGroup (256B) | faction_member_upgrade_group 库 (0x332EEF8) 条目 (malloc 0x100); 布局: +8 名 token / +32/+64 name/desc 绑定本地化 (NPdxLoc::CBoundLocalization 32B ×2) / +96 icon SSO / +128 upgrades 列表 (内联分配器 4 元缓冲, 元素 16B CFactionUpgrade 指) / +232 default_upgrade (10510) / +248 upgrade_type (10450) / +252 display_as_percentage (ctor 1, **恒 1 死键**)。消费 = 上表 set_faction_upgrade (花费 \*(def+248)) + fac+2104 + AI 周更 |
| NFactions::CFactionIconPool (56B) | faction_icons 库 (0x332EEE8) 条目 (malloc 0x38); +32 = icons reloadable 向量 (GFX 名串列表, 唯一键 19742, `@` 前缀条目走脚本值解析); GUI = CFactionIconItem/Window (§4.31.31) |

创立链: create_faction 效果 sub_1404AB570 (先离旧阵营) → **CreateFaction
sub_140D91E00** (DLC50 门; 无 template → 默认 token 10355
original_generic_faction_template; malloc 2688 + ctor sub_140D87F90 → push
facsys+32 → **fac+2544 色槽 = count−1** → 注册 sub_14221E700 → 创建者
dip+656 = fac)。ctor 直插创建者为 **members[0]** (领袖=首元不变量源头,
sub_140D8E970; 初始色 = 创建者沿宗主链取色 +32); 附属国逆序递归加入 +
FACTION_CREATED_UNDER_MASTER 通知。AddMember sub_140D89A30
(faction.cpp:837/838 断言; 递归带 dip+368/dip+400 附属; 全量修正重算;
**on_become_faction_member** faction.cpp:1190; 升级侧登记)。成员变更统一刷新
sub_140D8D590 (升级/共享重建 → 逐成员 on_action → goal daily 重跑 → 开局后
即时结算 → rule 重建) (定案)。

解散两径 (定案): dismantle 效果 (门 = 发起者是领袖 members[0]) → 直接
**RemoveFaction sub_140D922F0**; 任何人离队 (join/leave 开关 sub_14118BA30:
领袖 → 给合规成员发跟随通知 + 全员踢 sub_140D8DF30; 非领袖 → RemoveMember
sub_140D8E2F0 递归附属) 后成员数归 0 → 自动同函数。RemoveFaction = 向量内
swap-delete (尾元补位) + 色槽重排 (维持 槽==向量位 不变量) + 全员踢 + GUI 刷
+ **vtable[0] 删除析构**; 不在向量 → 断言 "Removing factions that is not supposed
to exist" (faction_system.cpp:333)。吞并路径: CCountry::Annex 尾被吞并者离队
→ 队空即解散。

易主五入口全收敛 **SetLeader sub_140D8ED20** (swap members[0]↔members[idx] +
fac+120 = gs+1128 + **on_assume_faction_leadership** faction.cpp:1262/1265):
领袖离队接替 (RemoveMember 内, DLC16 门两轮 major→非 major; 接替者搜索
sub_140D89220 = 候选 ∧ major 旗轮次 ∧ 无宗主 ∧ 非流亡, 比较 IC (cc+3944) +
人力 (cc+808)) / 领袖投降退位 (sub_1406E16C0 → sub_140D8D370 =
FACTION_LEADER_CAPITULATED 载体) / 同阵营吞并领袖 (Annex 尾 SetLeader(
吞并者)) / set_faction_leader 效果 / assume_faction_leadership 外交行动
sub_1416026E0 (faction_diplomatic_actions.cpp:643 断言) (定案)。

goal def (CFactionGoal) 触发器/效果块定名: +40 check_completed (门 +60) /
+304 allowed (键 12263; 脚本键名实为 allowed, available=12264 别行; 门 +324, 可用目标重建筛选) / +568 check_canceled (门 +588) /
+392 on_completion (门 +412) / +656 on_cancel (门 +676) / +896 内嵌 CRatioProgress ≥2416B (§4.5.3)
(求值 sub_140A1FFE0) / +904 阶段库指针 (1808B 条目) / +2664∪+2872∪+3404 进度
化目标联合门 (定案)。goals 条目 (1344B): +16 CProgressStatus 内嵌 (~1280B,
GetFullDescription 符号定名; +96 CProgress 指针 / +120 CModifier / +296 CRule) /
+1312 缓存进度值 (i64 fixed×1e-5, 100000 = 100%) (定案)。

**负定案: 1.19.3 无 on_faction_created** (全语料 0 命中); on_action 三派发点 =
on_become_faction_member / on_leave_faction / on_assume_faction_leadership。
DLC50 = "Deeper Factions" (faction_goal_status.cpp:184 断言串)。


#### 4.5.9a CProgress 互斥量校验 (progress.cpp; 1 函 = 0x140A21300)

`sub_140A21300(a1, a3_源文件串, a4_行号)` — a2 = 脚本进度对象:

| a2 偏移 | 类型 | 语义 |
|---|---|---|
| +1184 | bool | total_amount 有门 |
| +1392 | int32 | total_amount 值 |
| +1768 | bool | completed_amount 有门 |
| +1976 | int32 | completed_amount 值 |

两对 bool 与值恒差 208 字节（平行结构）；双门同开 → CLog 65540 + 文件/行上下文（progress.cpp:199 total 版 / :205 completed 版）。类名依文件域与 §4.5.9「CProgress 求值」引用推定。
#### 4.5.10 NFactions::CFactionRule (def 侧规则对象; ctor sub_140147950, 928B (0x3A0) — 具名内联条目 reader sub_140A2DCC0 malloc 直证, df389)

faction_rule 库 (qword_14332EF00, §4.26.4) 的条目类; rules 向量 (CFactionRuleStatus+88, 键 12667) 持其指针。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | NFactions::CFactionRule |
| +8 | uint32 | 名 token id (具名内联条目 reader sub_140A2DCC0 取名注册后直写; ctor 路径经基初始化器 sub_1424BE3C0 置 357 = 无名哨兵, df389) |
| +24 | uint8 | 0 初值 |
| +32 | uint32 | 357 (none 哨兵 token) |
| +40..+568 | 6× CAndTrigger 88B (步 88, ctor sub_140549F40) | 六联子结构 (规则六槽; ctor 写 &CAndTrigger::vftable, 块内 +32 = 10600; 同 CScriptedTriggerTemplate 88B ctor 族) |
| +568 | 24B pdx 向量 | peace action modifier id 数组 {data@+568, cap@+576, count@+580, alloc@+584} (ctor sub_14011DF40, alloc = &off_143085170; 消费 = 0x140A2D080 逐 u32 id 查 TGameItemDatabase qword_14332EFC8; unwind 的 std::locale dtor 系 IDA 对模板向量析构的符号复用, 非串) |
| +592 | CModifier 192B 内嵌 | §4.3.8 通用布局 |
| +784 | 容器 (预留 4 元) | dtor sub_140153590 |
| +840 | 末块 (sub_14053CFD0) | 类尾 |

#### 4.5.11 CFactionRuleStatus 生命周期三段 (faction_rule_status.cpp; 3 函闭环 — 三写口共享 set 核心)

簇清册 (体内 cpp 锚 3/3; 同族入口 sub_141995D40 书已收, 三函本体未收):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_141995A60 | 144 | 断言 "Trying to set faction manifest without Deeper Factions DLC" :118 (a4=1→B52, 闩 byte_14338B45A) | set 单条规则核心 |
| sub_141994260 | 235 | 格式化错误日志 :89 "failed to set rule … while loading a save file" (4096) | loader (存档 rules 块解析 → set 核心) |
| sub_141996190 | 287 | 格式化错误日志 :48 "failed to set default rule … while creating a faction from template" (4096) | 模板建局默认规则批量装填 |

**set 核心** (sub_141995A60; set_rule(rs, def, out_flags, need_dlc_check, notify)): DLC 门 = need_dlc_check ∧ !sub_1401AEB50(50) ("Deeper Factions DLC") → 断言 :118 返 0; rules 向量 (+88) 线性查重已在 → 返 1; 哈希B 反查 → crule+144 缓存关联对象谓词假 → *out |= 2 + sub_141994E90 级联; def+608 谓词假 → *out |= 2; notify ∧ *(def+860) → 领袖国 scope 构造 → def+840 vtable+96 派发; **FNV(def) 插哈希C (基 +112)**; rules 向量 push (×1.5)。**三写口闭环**: 模板建局 (996190) → 存档回放 (994260, 读档期不查 DLC 不派通知) → 运行期 set_faction_rule 效果链 (书已收) — 共享本核心。

**loader** (sub_141994260): pdx 解析协议形态; '@' 前缀 → sub_1424C04A0 变量间接 (§4.4.27 同款); 每条解出 {rule_id→rs+192, 旗→rs+196, 串→rs+200/+212} → sub_1404AC0F0 查哈希A 得 def (miss 或 set 失败 → :89)。**模板装填** (sub_141996190): 全局默认规则名表逐名 FNV 查模板 +272 规则哈希 → def; 失败 → :48 (模板名 = sub_1424BE600(*(rs+16)) — +16 模板回指第二证)。

哈希形通用观察 (双证): {基+8 data, 基+20 mask&, 基+24 extra u8}, 桶 24B {+4 占用, +8 键, +16 值} 线性探测; 模板侧表 {data@+272, mask&@+284, extra@+288} 同构。

未决: 哈希A/B/D 四行槽名义重验 (§4.5 表 ⚠ 注) / def+608/+840/+860 三槽语义 / 排序模式键 UI 名 (§4.30.55)。

#### 4.5.12 CChangeGoalWindow 条目族: CChangeGoalItem 构造与 populate 链 (1 ctor = 0x141F117E0 + 链 4 函, 定案 (ctor)/链归属高置信)

**NFactions::NUi::CChangeGoalItem::CChangeGoalItem** 0x141F117E0 (this, 模板节点 a2, 窗口回指 a3), sizeof = **1448** (唯一调用点 sub_141C07520 malloc 直证); 基类 = **CStandardGridBoxItem** (sub_1422C6040 直证, 与 CChangeGoalItemRow 同基族); 容器名 "change_goal_item_container"; 双 std::function 回调 (RTTI lambda 符号直证), 签名 `void(CGui::A const*, CChangeGoalWindow*)`, 捕获 this, 传入 "button" 子件构建。

| 偏移 | 内容 | 档 |
|---|---|---|
| +0 | 主 vtable (CChangeGoalItem 表) | 定案 |
| +16 | 模板节点 (后续子件查找源) | 定案 |
| +24 | 第二 vtable (多继承接口视口, 接口名 `CGui::A` 系推定) | 定案写/接口名推定 |
| +32 | CButtonWrapper 内嵌 ("button" 子件 sub_1422DC710 构建后 sub_1422DD480 装入) | 定案 |
| +48 | CButtonObserverGlue (vtable + sub_1402DDEF0 状态) | 定案 |
| +1400 | **CChangeGoalWindow 回指** (lambda 签名第二参直证类名) | 定案 |
| +1408 | 0 (ctor 清零) | 定案 |
| +1416 | qword_14333D528 单例 (写点未寻获, 身份未决) | 定案写/未决身份 |
| +1424 | "rule_name" 子件 (sub_1422BC600 查找) | 定案 |
| +1432 | "cost" 子件 (旧值经 vt+552 空护释放后覆盖) | 定案 |
| +1440 | rule_name 子件解引用组件指针 (sub_1422CAAC0) | 定案 |

**populate 执行链 (新定名, 链函类名归属靠 RTTI lambda 与容器名)**: 上游入口 = SetupDerived sub_141C08510 (§4.5.12a) → **sub_141C08E30** (goal 过滤 populate 分派器: 读 window+1664 槽 idx, <3 单槽否则三槽全跑) → sub_141C08EA0; toggle 侧 sub_141F13DC0 → sub_141C07DB0 → **sub_141C08EA0** (goal token 收集 + 排序; 8B 元数组, ≤32 插排/二分分裂) → **sub_141C07520** (遍历 24B 元素 {data@+0, cap@+8, count@+12}; 逐元素 malloc 1448 + ctor; **token 357 哨兵初值**与 def+3400 `==357 空` 互证) → ctor; 与 §4.5 上文 sub_141C08C40 逐槽建 CFilterGoalItem 为同窗两族条目链。析构链 (EH unwind 反推) = sub_1422DD3E0 (button wrapper) / sub_1402DE470 / sub_1402DE480 (回调数组) / sub_1422C6230 (基类)。

#### 4.5.12a CChangeGoalWindow::SetupDerived (UI 装配 + populate 链上游入口; sub_141C08510, 定案)

CChangeGoalWindow (NFactions::NUi 命名空间; vtable 0x142A51298; sizeof 1704 = 0x6A8; 窗名 "change_goal_window"; **非 CPersistent** — 零序列化面) 挂父窗 CCountryFactionView::SetupDerived (sub_141472080) 的 +1416 (§4.30 四窗位)。

SetupDerived 主流程: 按名创建 5 个 .gui 子件 + close 钮 (创建器: grid = sub_1422BA420 / list = sub_1422BDA50 / 复选框 = sub_1422BA060 / 按钮回调 = sub_1422DC8A0 → 装入 +112 CButtonWrapper sub_1422DD480) → 绑双 CCheckBoxObserverGlue (子件+128 → vt[1] 注册) → 应用镜像态 (+1680/+1681) → 取玩家 tag (gs+1312>0 ? 1312 : 1316 → sub_140BB48F0 tag→国) → country+3976 (CDiplomacy) +656 = CFaction* → 非空时驱动 sub_141C08E30 (goal 过滤 populate 分派, 按 +1664) 与 sub_141C08C40 (goal 条目 populate)。

窗布局 (偏移升序):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +80 | 指针 | GUI 上下文 (按名创建子件宿主; 基类 ctor sub_1422DBB20 设定) |
| +104 | 指针 | "box_list" 容器 |
| +112 | CButtonWrapper | "close" 钮 (ctor 预置; sub_1422DD480 装入) |
| +128 | CButtonObserverGlue | close 钮观察者 |
| +1488 | 指针 | "grid_container" (旧值经 (old+48) vt[69] 释放) |
| +1520 | 指针 | "show_unavailable" 复选框 |
| +1528 | 指针 | "show_completed" 复选框 |
| +1536 | CCheckBoxObserverGlue<CChangeGoalWindow> | show_unavailable 绑定 (回指 this@+1544 / 回调 sub_141C07C00@+1552) |
| +1600 | CCheckBoxObserverGlue<CChangeGoalWindow> | show_completed 绑定 (回指@+1608 / 回调@+1616) |
| +1672 | 指针 | "filter_buttons" 容器 (sub_141C08C40 首先重置) |
| +1696 | qword | box_list vt[19] 调用结果首 qword (语义未决) |

回调 sub_141C07C00: 读两复选框态 (sub_1422C96A0) → 写 +1680/+1681 → 取玩家 CFaction → 刷新。复选框置态对 = sub_1422C9DB0 (真分支) / sub_1422C9F20 (假分支) + 后处理 sub_1422C8E90 (恒配 0); 三助手语料无横幅, 按用法定性。

#### 4.5.13 阵营影响点 console 命令 handler (1 函 = 0x140259160, 机制定案/实名待裁)

0x140259160 (`<amount> [tag]`): .data 函数指针表注册 (语料无地址引用, 实名待运行时命令表比对)。amount = fixed 100.0 (字面 10000000); tag 缺省 = 会话国 (gs+1312/1316 玩家 tag 对)。门 = `dip(cc+3976)+656` faction 非空 → **CFactionMemberStatus::SetInfluenceStat** (faction_member_status.cpp:0x6A 断言站, kind<5 门, **kind 1 槽写入** — 成员状态影响点设置器新定性) → 尾经 idler vt+184 hub → `sub_140B674F0(hub, 20)` → Repopulate 刷新面板 #20。回显 = "Added " + " faction influence points to " + sub_140BB4BB0 (国名/tag 串推定; 数值插值点未见, 疑 IDA 内联合并)。

#### 4.5.14 set_faction_rule 效果族 GetDesc/tooltip 合成器 (1 函 = 0x1404B1BE0, 高置信/类名槽位推定)

0x1404B1BE0: scope → 阵营 → **CFactionRuleStatus 开址索引查 CFactionRule\*** → 本地化 "SET_FACTION_RULE_EFFECT"{RULE, FACTION} + '\n'。全语料唯一消费该键、无直接调用者 (纯 vtable 引用, GetDesc 槽家族)。**CFactionRuleStatus 开址索引新布局 (定案)**: base@**fac+1424** / mask@**+1436** / maxdist@**+1440**, 桶 24B, hash 乘数 **0x045D9F3B** (§4.6.1 同族常数)。

#### 4.5.15 阵营系统函数补遗（180 函）

| VA | 语义/证据 |
|---|---|
| 0x141183140 | 派系外交描述构建（领袖/目标/成员） 串 DIPLOMACY_FACTION_DESC/DIPLOMACY_FACTION_LEADER/DIPLOMACY_FACTION_OTHER_MEMBERS + LEADER/TARGET/FACTION |
| 0x141187F00 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_RULE_CAN_REMOVE" |
| 0x1418A48A0 | （无名） 调用图传播: 17 锚点投 §4.5（94%） |
| 0x1401CD910 | （无名） 调用图传播: 47 锚点投 §4.5（53%） |
| 0x14164F680 | （无名） 调用图传播: 34 锚点投 §4.5（53%） |
| 0x141182750 | 派系战争贡献预期收益 串 "CONTRIBUTION_EXPIDITIONARY_FORCES/INFLUENCE/MANPOWER_EXPECTED_GAIN" → 派系战争贡献预期收益 |
| 0x141EB5940 | （无名） 调用图传播: 30 锚点投 §4.5（53%） |
| 0x14231C3B0 | （无名） 调用图传播: 10 锚点投 §4.5（80%） |
| 0x14118BE70 | 派系战区 tooltip 串 "FACTION_THEATER_TOOLTIP"/"FACTION_THEATER_TOOLTIP_COMMANDER"/"NUM_COUNTRIES" → 派系战区 tooltip |
| 0x1419F96E0 | 无名 sub_（断言站点/串定位） 串字面量 "PEACE_COST_BREAKDOWN_MODIFIER_FACTION_POWER_PROJEC" |
| 0x140195D90 | （无名） 调用图传播: 33 锚点投 §4.5（58%） |
| 0x14241C2C0 | （无名） 调用图传播: 12 锚点投 §4.5（67%） |
| 0x1418A52B0 | （无名） 调用图传播: 16 锚点投 §4.5（100%） |
| 0x1401995C0 | （无名） 调用图传播: 30 锚点投 §4.5（67%） |
| 0x140196B10 | （无名） 调用图传播: 30 锚点投 §4.5（67%） |
| 0x14019A340 | （无名） 调用图传播: 30 锚点投 §4.5（67%） |
| 0x140196450 | （无名） 调用图传播: 29 锚点投 §4.5（69%） |
| 0x140199C80 | （无名） 调用图传播: 29 锚点投 §4.5（69%） |
| 0x1401A06C0 | （无名） 调用图传播: 30 锚点投 §4.5（67%） |
| 0x1414C7700 | （无名） 调用图传播: 47 锚点投 §4.5（66%） |
| 0x140C94D50 | （无名） 调用图传播: 19 锚点投 §4.5（84%） |
| 0x141798E20 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_THEATER_DEFAULT_NAME" |
| 0x141185000 | 业务逻辑（键 NAME） "NAME"/"FACTION"/"THEATER"/"THEATER_COMMANDER_MODIFIER"（派系战区指挥官修正） |
| 0x14182E1E0 | （无名） 调用图传播: 10 锚点投 §4.5（50%） |
| 0x141189D50 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_INITIATIVE_TOOLTIP" |
| 0x140D876B0 | CFaction::PassiveInitiativeGeneration? func_names 名 CFaction::PassiveInitiativeGeneration? |
| 0x141182080 | 派系战区提示 FACTION_THEATER_TOOLTIP_COUNTRY / NO_COUNTRIES |
| 0x1418A5DC0 | （无名） 调用图传播: 5 锚点投 §4.5（80%） |
| 0x142418BF0 | （无名） 调用图传播: 22 锚点投 §4.5（68%） |
| 0x1415149E0 | sub_1415149E0（无名） COUNTRY / REASON / DIPLOMACY_CLOSED_MARKET GUI 键，夹于 CIncomingDiplomaticActionStatus::Writer(d=320) 与 SInvasionReport::[0](d=5520)，入站外交状态/入侵报告族 |
| 0x141B09F80 | 派系战区 "The faction hasn't created any theaters :(" + "NO TEMPLATE" + "Theaters - " |
| 0x14019B260 | （无名） 调用图传播: 20 锚点投 §4.5（70%） |
| 0x1401A14C0 | （无名） 调用图传播: 19 锚点投 §4.5（74%） |
| 0x14019CD60 | （无名） 调用图传播: 20 锚点投 §4.5（70%） |
| 0x1401A42A0 | （无名） 调用图传播: 19 锚点投 §4.5（74%） |
| 0x1418A6FA0 | （无名） 调用图传播: 4 锚点投 §4.5（100%） |
| 0x14143EB40 | （无名） 调用图传播: 15 锚点投 §4.5（53%） |
| 0x1413ACFE0 | （无名） 调用图传播: 23 锚点投 §4.5（61%） |
| 0x140D851B0 | CFaction::UpdatePower? func_names 名 CFaction::UpdatePower? |
| 0x141CA4C40 | sub_141CA4C40（无名） DIPLOMACY_EFFECT_HEADER / wargoal_name GUI 键，夹于 CDiplomacySendVolunteersController::[0]，外交派遣志愿军效果头 UI |
| 0x1402B1BA0 | （无名） 调用图传播: 4 锚点投 §4.5（100%） |
| 0x1422267B0 | （无名） 调用图传播: 9 锚点投 §4.5（67%） |
| 0x141866960 | 无名 sub_（调用图定位） 调用图传播: 3/4 锚点投 §4.5 |
| 0x140A2E080 | CFactionRuleGroup 派系规则组 (vtable类名 CFactionRuleGroup) vtable引用 CFactionRuleGroup vftable |
| 0x1415544E0 | （无名） 调用图传播: 12 锚点投 §4.5（67%） |
| 0x140DEA910 | （无名） 调用图传播: 6 锚点投 §4.5（50%） |
| 0x14054FB10 | （无名） 调用图传播: 9 锚点投 §4.5（67%） |
| 0x14071BE30 | （无名） 调用图传播: 9 锚点投 §4.5（78%） |
| 0x1422E16C0 | （无名） 调用图传播: 24 锚点投 §4.5（62%） |
| 0x14240C310 | （无名） 调用图传播: 7 锚点投 §4.5（86%） |
| 0x142226DD0 | （无名） 调用图传播: 6 锚点投 §4.5（100%） |
| 0x140615470 | （无名） 调用图传播: 15 锚点投 §4.5（60%） |
| 0x141F817C0 | （无名） 调用图传播: 6 锚点投 §4.5（67%） |
| 0x1405305F0 | （无名） 调用图传播: 16 锚点投 §4.5（56%） |
| 0x140D866B0 | 无名领域函数 sub_140D866B0 被调用者定名: CFaction::UpdatePower? 等命中 §4.5（占 100%，共 2 callee） |
| 0x140DEABE0 | （无名） 调用图传播: 6 锚点投 §4.5（50%） |
| 0x141E7BD30 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_NO_FACTION" |
| 0x141186560 | GUI：FACTION_MAX_NUMBER_OF_THEATERS loc 键 FACTION_MAX_NUMBER_OF_THEATERS/FACTION_UPGRADE_NOT_ENOUGH_INITIATIVE |
| 0x140A2C820 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_RULE_AVAILABLE" |
| 0x140670250 | （无名） 调用图传播: 9 锚点投 §4.5（67%） |
| 0x1415526A0 | （无名） 调用图传播: 6 锚点投 §4.5（67%） |
| 0x14156A4F0 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x141863050 | 无名 sub_（调用图定位） 调用图传播: 3/5 锚点投 §4.5 |
| 0x141824A30 | 无名 sub_（断言站点/串定位） 串字面量 "TYPE_FACTION_NAME" |
| 0x141C5AF80 | 无名 sub_（断言站点/串定位） 串字面量 "RANK_TEXT_FACTION" |
| 0x1418AA5F0 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x140AA5030 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x1424F20A0 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x14135F9E0 | （无名） 调用图传播: 3 锚点投 §4.5（100%） |
| 0x141E76760 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_topbar_faction" |
| 0x141ADBA70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1418643B0 | sub_1418643B0 特征串:peaceconference_wait_window ; waiting_for_players |
| 0x1422FD110 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x141555480 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x140A21E40 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_GOAL_AVAILABLE" |
| 0x1402B2360 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x1424C0390 | （无名） 调用图传播: 12 锚点投 §4.5（75%） |
| 0x141B309D0 | （无名） 调用图传播: 10 锚点投 §4.5（70%） |
| 0x141EE4A80 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x141F95C40 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x140666AF0 | （无名） 调用图传播: 5 锚点投 §4.5（60%） |
| 0x140C97CF0 | （无名） 调用图传播: 13 锚点投 §4.5（69%） |
| 0x141478CF0 | sub_141478CF0 特征串:DIPLOMACY_ASSUME_FACTION_LEADERSHIP_NOT_CAPITULATED_PROGRESS |
| 0x142226CF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x14165B210 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x141FAE030 | （无名） 调用图传播: 6 锚点投 §4.5（83%） |
| 0x141C1FF90 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x140BC0300 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x140220CD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x140D8CB90 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x141ADB1A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x14052F880 | （无名） 调用图传播: 7 锚点投 §4.5（71%） |
| 0x14146D730 | （无名） 调用图传播: 6 锚点投 §4.5（50%） |
| 0x142227A30 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x141A47010 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x14118EF50 | 无名 sub_（断言站点/串定位） 断言站点 faction_member_status.cpp:130 |
| 0x1417A0100 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_THEATER_MAP_MODE_ADJACENT" |
| 0x1424F1310 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x140532B90 | （无名） 调用图传播: 7 锚点投 §4.5（71%） |
| 0x1424F13D0 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.5 |
| 0x14118D970 | 无名 sub_（断言站点/串定位） 断言站点 faction_member_status.cpp:86 |
| 0x141950DF0 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x140532B00 | （无名） 调用图传播: 7 锚点投 §4.5（71%） |
| 0x14064AD30 | （无名） 调用图传播: 4 锚点投 §4.5（50%） |
| 0x1424CC680 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x141070030 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x141532D20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x14022CFF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x142634460 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x1425F2160 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x140E1A340 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x141F60180 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1418B3530 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x140EC99D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1426169A0 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x141CB0550 | （无名） 调用图传播: 6 锚点投 §4.5（50%） |
| 0x141A95330 | 无名 sub_（断言站点/串定位） 断言站点 faction_text.cpp:36 |
| 0x142634850 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x141EF5800 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x14263DFA0 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x142410280 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x1425F2280 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x1401E3AC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x142616780 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x1424CB4E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x140A57EA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1426166D0 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x142616860 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x141E86AF0 | （无名） 调用图传播: 7 锚点投 §4.5（71%） |
| 0x142616620 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x141C04FE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x14263DE30 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x1426162F0 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x14263DEF0 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x14263E050 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x142671B10 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x140AB0490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x142634590 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x142616230 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x142616570 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x1425F1FA0 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x1425F2050 | （无名） 调用图传播: 7 锚点投 §4.5（57%） |
| 0x141FB1F20 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x141380DE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x140B89640 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D5EB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1401C9140 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x141B29810 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x1412D5E30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D5F30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D5FB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D6030 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D60B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D6130 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x1412D61B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x140D8D3F0 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x140F23570 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x141E15A10 | （无名） 调用图传播: 9 锚点投 §4.5（100%） |
| 0x1401C2490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x140D8A3B0 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x1415E5A40 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x14167BDB0 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x1424C9130 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x1418EB0A0 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x141994FD0 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x141BAE9E0 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x14221E5A0 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x1401246C0 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x14126A640 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x1401201D0 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x141F53A70 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x1411908E0 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x1415E5990 | （无名） 调用图传播: 3 锚点投 §4.5（67%） |
| 0x141FACA10 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x141EED9A0 | （无名） 调用图传播: 4 锚点投 §4.5（75%） |
| 0x1417407B0 | （无名） 调用图传播: 3 锚点投 §4.5（100%） |
| 0x14118DFE0 | （无名） 调用图传播: 2 锚点投 §4.5（50%） |
| 0x1418EB070 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x141796C40 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |
| 0x141C1CB50 | （无名） 调用图传播: 2 锚点投 §4.5（100%） |

#### 4.5.16 阵营系统函数补遗（9 函）

| VA | 语义/证据 |
|---|---|
| 0x140D86540 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.5 |
| 0x140614440 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.5 |
| 0x1413B2A70 | 无名 sub_（调用图定位） 调用图传播: 3/5 锚点投 §4.5 |
| 0x140AA5CF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x141557620 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.5 |
| 0x142005320 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.5 |
| 0x1418A45B0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.5 |
| 0x141E17950 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.5 |
| 0x142226520 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.5 |

#### 4.5.17 阵营系统函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x14014F1F0 | 数据库析构 数据库析构：vtable 名 CPersistentReloadableGameItemDatabase<NFactions::CFactionRuleGroupDatabase> 直接标识派系规则组库 |

#### 4.5.18 阵营系统函数补遗（31 函）

| VA | 语义/证据 |
|---|---|
| 0x140D87A10 | CFaction::UpdatePower? / CFaction::UpdatePower CFaction::UpdatePower §4.3 CCountry |
| 0x14112ECC0 | CDeclareWarAction::[53] func_names 全名 + 类域（CDeclareWarAction） |
| 0x140140370 | 无名（证据推断） 类名/模板：Z::_Func_impl_no_alloc 、 NFactions::CFactionMemberUpgradeDatabase 、 NF |
| 0x14160F4B0 | NFactions::CLeaveFactionAction::[59] 名:NFactions::CLeaveFactionAction::[59] |
| 0x140AB1810 | CScriptedDiplomaticAction::[56] func_names 全名 + 类域（CScriptedDiplomaticAction） |
| 0x141C96450 | CDiplomacyStandardController::[13] 名:CDiplomacyStandardController::[13] |
| 0x141BA7F80 | NFactions::CCreateFactionTheater::Clone func_names 全名 + 派系命名空间 NFactions |
| 0x140D8CA30 | NFactions::CFaction::[8] func_names 全名 + 派系命名空间 NFactions |
| 0x14111F7B0 | CEmbargoAction::[59] 名:CEmbargoAction::[59] |
| 0x141C9CB50 | CDiplomacyStageCoupController::[7] func_names 全名 + 类域（CDiplomacyStageCoupController） |
| 0x141C93BF0 | CDiplomacyStandardController::[0] 名:CDiplomacyStandardController::[0] |
| 0x141100770 | CAskForStateControlAction::[24] 名:CAskForStateControlAction::[24] |
| 0x141102210 | CSendVolunteerAction::[24] func_names 全名 + 类域（CSendVolunteerAction） |
| 0x141610110 | NFactions::CKickFromFactionAction::[59] func_names 全名 + 派系命名空间 NFactions |
| 0x140A2A320 | NFactions::CFactionMemberUpgrade::[11] func_names 全名 + 派系命名空间 NFactions |
| 0x141139BE0 | CGuaranteeAction::[57] func_names 全名 + 类域（CGuaranteeAction） |
| 0x14014F2C0 | 未决窗口函数 · 派系模板库析构 `CPersistentReloadableGameItemDatabase<NFactions::CFactionTemplateDatabase,...>` 析构 |
| 0x140AB3C60 | CScriptedDiplomaticAction::[57] func_names 全名 + 类域（CScriptedDiplomaticAction） |
| 0x141C979B0 | CDiplomacyCountryDeclareWarActionController::[2] func_names 全名 + 类域（CDiplomacyCountryDeclareWarActionController） |
| 0x1411008A0 | CBoostPartyPopularityAction::[24] func_names 全名 + 类域（CBoostPartyPopularityAction） |
| 0x141100AD0 | CCancelAccessToLicenseProductionAction::[24] func_names 全名 + 类域（CCancelAccessToLicenseProductionAction） |
| 0x1411017E0 | COfferMilitaryAccessAction::[24] func_names 全名 + 类域（COfferMilitaryAccessAction） |
| 0x141C9A7D0 | CDiplomacyGiveStateControlController::[7] func_names 全名 + 类域（CDiplomacyGiveStateControlController） |
| 0x141234AD0 | CUnitMoveAction::[22] func_names 全名 + 类域（CUnitMoveAction） |
| 0x14151AEC0 | CLiberateCountryAction::[24] func_names 全名 + 类域（CLiberateCountryAction） |
| 0x141121750 | CSendExpeditionaryForceAction::[59] func_names 全名 + 类域（CSendExpeditionaryForceAction） |
| 0x14151AFF0 | CPuppetCountryAction::[24] func_names 全名 + 类域（CPuppetCountryAction） |
| 0x140AD7940 | CTimedWargoalActivity::[0] 限时战争目标活动 |
| 0x1419966A0 | NFactions::CFactionRuleStatus::Writer func_names 全名 + 派系命名空间 NFactions |
| 0x14113A200 | CRequestAccessToLicenseProductionAction::[57] func_names 全名 + 类域（CRequestAccessToLicenseProductionAction） |
| 0x141981420 | COfferAirBaseAccessRelation::[22] func_names 全名 + 类域（COfferAirBaseAccessRelation） |

#### 4.5.19 阵营系统函数补遗（19 函）

| VA | 语义/证据 |
|---|---|
| 0x14012D500 | gameitemdatabase.h:882 业务 派系图标池构造：写 `NFactions::CFactionIconPool::`vftable'`，gameitemdatabase.h:882 模板断言 |
| 0x140D86F30 | CFaction::UpdateInfluence? 业务 派系影响力更新，func_names 名带 ? |
| 0x140AA4CD0 | 业务 CDiplomaticAction::GetFirstCountryRef 逐国迭代 + 字符串拼接，外交 action 参与国描述生成（与 0x140A008C0 同结构克隆） |
| 0x140A008C0 | 业务 CDiplomaticAction::GetFirstCountryRef 逐国迭代 + 字符串拼接，与 0x140AA4CD0 同结构克隆（额外写 a2+264） |
| 0x140D88B10 | 业务 夹于 CFaction::UpdatePower?(d=4352) 与 CPdxHybridInlineBufferAllocator<SWarBlobT>(d=2384)，派系实力/战争数据族 |
| 0x141AB0340 | 业务 夹于 CIncomingDiplomaticAction::Writer(d=37904) 与 CAbstractArmyLeaderItem::[1](d=64588)，入站外交 action/将领条目族 |
| 0x1412E1B00 | sub_1412E1B00 业务 串：FACTION_ACCESS_TAB_MILITARY 、 FACTION_ACCESS_TAB_LOCK 、 FACTION_ACCESS |
| 0x140D91960 | (无名) 业务 VA 邻域有名函数簇（tbb::interface9::internal::2::$$CBVauto_partitioner::Z::start_f…::[1]; tbb::interface9::internal::2::$$CBVauto_partitioner::Z::start_f…::[… |
| 0x140C728B0 | sub_140C728B0 业务 串：C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\diplomacy\\factions\\sc |
| 0x140A2E410 | 业务 断言站点 project_commands.cpp:84; 断言站点 gamelobby.cpp:79 ->§4.5; 断言站点 gamelobby.cpp:80 ->§4.5 |
| 0x14064C640 | 业务 断言站点 achievements_mod_storage.cpp:48 ->§4.5; 类路由 CSavedAchievementMod ->§4.28; 串 "Cloud save file for mod achievement " |
| 0x1424D3BB0 | 业务 断言站点 gamelobby.cpp:2 ->§4.5; 断言站点 raid_effect_implementation.cpp:91 ->§4.32; 断言站点 scripttargets.cpp:43 |
| 0x142507330 | 业务 断言站点 gamelobby.cpp:0 ->§4.5; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"; 串 "![MD]\n" |
| 0x1423245F0 | 业务 断言站点 gamelobby.cpp:32 ->§4.5; 断言站点 ai_occupation.cpp:31; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1423ECF90 | 业务 断言站点 gamelobby.cpp:67 ->§4.5; 类路由 CSetPoliticalPowerEffect ->§4.32; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1421D2630 | 业务 断言站点 career_profile.cpp:86; 断言站点 achievements_mod_storage.cpp:69 ->§4.5; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1424758C0 | 业务 断言站点 achievements_mod_storage.cpp:12 ->§4.5; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"; 调用图 IDF top §4.1 frac 0.75 |
| 0x140FF8730 | 业务 断言站点 faction_member_status.cpp:86 ->§4.5; 串 "!\"GetInfluenceStat out of range\""; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x140153450 | 业务 串 "GFX_upgrade_frame_1"; 串 "click_default"; 调用图 IDF top §4.1 frac 1.00 |

#### 4.5.20 阵营系统函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x141ADF8F0 | NFactions::NUi::CInviteCountryItem::[20] 业务 *Item 类（派系 UI 邀请国家条目）vtable 槽 20 |
| 0x1413FC350 | NFactions::CFactionUpgradeStatus::Writer 业务 func_names 名 |
| 0x141C00280 | NFactions::NUi::CDismantleFactionConfirmationWindow::[16] 业务 NFactions::NUi::CDismantleFactionConfirmationWindow::[16] 解散派系确认窗口槽方法；类名自文档 |
| 0x141F0A510 | NFactions::NUi::CFactionMemberUpgradeItem::[0] 业务 NFactions::NUi::CFactionMemberUpgradeItem::[0] 派系成员升级条目槽方法；类名自文档 |
| 0x1414705D0 | NFactions::NUi::CFactionResearchSection::[0] 业务 NFactions::NUi::CFactionResearchSection 阵营科研区段 GUI（gamestate.h:1125） |

#### 4.5.21 阵营系统函数命名空间补遗（366 函）

| VA | 语义/证据 |
|---|---|
| 0x141798640 | NFactions::NUi::CFactionTheaterItem::[0] CGameState 单例访问（gamestate.h 断言 _pInstance && / _ThreadForbidCount == 0） |
| 0x141C02C80 | NFactions::NUi::CFactionIntelligencePopup::[14] NFactions::NUi::CFactionIntelligencePopup::[14] + 域关键词匹配; 串 "_pInstance && \"; 源码路径 hoi4 |
| 0x1416023F0 | NFactions::CKickFromFactionAction::[24] NFactions::CKickFromFactionAction::[24] + vtable/RTTI 类 CDiplomaticAction; vtable/RTTI 含 CDiplomaticAction; 被 NFactio… |
| 0x1417987E0 | NFactions::NUi::CFactionTheaterSwitch::[0] NFactions::NUi::CFactionTheaterSwitch::[0] + 域关键词匹配; 串 "FACTION_THEATER_SWITCH_TO_FACTION_VIEW_TOO"; 被调源码 clausewitz |
| 0x141BF8C80 | NFactions::NUi::CFactionCommanderWindow::[0] NFactions::NUi::CFactionCommanderWindow::[0] + 名字角色规则(NFactions::NUi::CFactionCommanderWindow::[0]); vtable/RTTI… |
| 0x141BF9420 | NFactions::NUi::CFactionCommanderWindow::[11] func_names 全名 NFactions::NUi::CFactionCommanderWindow::[11]，*Command 角色定 §4.2 |
| 0x141BA7AE0 | NFactions::CCreateFactionTheater::[0] 业务类 CCommandNFactions（类名/调用链证据） |
| 0x14160C250 | NFactions::CAssumeFactionLeadershipAction::GetAiAcceptance NFactions::CAssumeFactionLeadershipAction::GetAiAcceptance + 域关键词匹配; 被调源码 hoi4; 被 NFactions::CAssu… |
| 0x140A2BB50 | NFactions::CFactionUpgradeGroup::[4] NFactions::CFactionUpgradeGroup::[4] + 域关键词匹配; 被 NFactions::CFactionUpgradeGroup::[4] 等 1 命名函数调用 |
| 0x141610D60 | NFactions::CLeaveFactionAction::[21] DIPLOMACY_MESSAGE_OTHERS_TITLE / _OTHERS_DESC + COUNTRY/FACTION，退出阵营行动 |
| 0x14160EF80 | NFactions::COfferJoinFactionAction::[17] |
| 0x141C00590 | NFactions::NUi::CDoctrineSharingPopup::[16] NFactions::NUi::CDoctrineSharingPopup::[16]（学说） |
| 0x141C178E0 | NFactions::NUi::CGoalItem::[0] NFactions::NUi::CGoalItem::[0] + CATEGORY / FACTION_ADD_GOAL / FACTION_GOAL / FACTION_GOAL_ITEM_TOOLTIP（阵营目标项） |
| 0x14160EAE0 | NFactions::CJoinFactionAction::[17] NFactions::CJoinFactionAction::[17] + COUNTRY / DIPLOMACY_MESSAGE_OTHERS_TITLE / FACTION（加入阵营动作） |
| 0x14160CF50 | NFactions::CLeaveFactionAction::GetAiAcceptance NFactions::CLeaveFactionAction::GetAiAcceptance（派系退会 AI 接受度） |
| 0x141BFE6D0 | NFactions::NUi::CAssignTheaterLeaderPopup::[16] 阵营规则/解散阵营/傀儡行动/召盟友/政变/选举/内战/独立保证/战争目标/合法性/意识形态任务（NFactions::NUi::CAssignTheaterLeaderPopup::[16]） |
| 0x141C021B0 | NFactions::NUi::CBecomeLeaderConfirmationWindow::[14] 阵营规则/解散阵营/傀儡行动/召盟友/政变/选举/内战/独立保证/战争目标/合法性/意识形态任务（NFactions::NUi::CBecomeLeaderConfirmationWindow::[14]） |
| 0x141C1CFA0 | NFactions::NUi::CResearchFacilityItem::[0] 阵营规则/解散阵营/傀儡行动/召盟友/政变/选举/内战/独立保证/战争目标/合法性/意识形态任务（NFactions::NUi::CResearchFacilityItem::[0]） |
| 0x1416133E0 | NFactions::COfferJoinFactionAction::GetRequestDescText：NFactions::COfferJoinFactionAction::GetRequestDescText NFactions::COfferJoinFactionAction::GetRequestD… |
| 0x141C1D450 | NFactions::NUi::CAssignResearchFacilityWindow::[5] `faction_program_facility_item`+`NFactions::NUi::CResearchFacilityItem`/`NProject::NUi::CProjectFilterList… |
| 0x141C26EA0 | NFactions::NUi::CRuleTypeItem::[0]：NFactions::NUi::CRuleTypeItem::[0] |
| 0x141470830 | NFactions::NUi::CFactionTabSection::[0]：NFactions::NUi::CFactionTabSection::[0] NFactions::NUi::CFactionTabSection::[0]；串 FACTION_ACCESS_TO_MILITARY_TAB/FACT… |
| 0x141F169D0 | NFactions::NUi::CFactionMemberScientistItem::[0]：NFactions::NUi::CFactionMemberScientistItem::[0] NFactions::NUi::CFactionMemberScientistItem::[0]；串 FACTION_… |
| 0x140A2B780 | NFactions::CFactionUpgradeGroup 槽8（faction_upgrade_group.cpp:112） NFactions::CFactionUpgradeGroup 槽8（faction_upgrade_group.cpp:112）：STR 'default upgrade is n… |
| 0x141611590 | NFactions::CAssumeFactionLeadershipAction::GetActionTitleText（func_names 名） func_names 名 + 串 "DIPLOMACY_MESSAGE_ACTION_TITLE"/"_RECIPIENT_DESC"/"FACTION"：接任派… |
| 0x141BFEBD0 | NFactions::NUi::CConfirmFactionFacilityProgram 槽16（gamestate.h:1125） NFactions::NUi::CConfirmFactionFacilityProgram 槽16（gamestate.h:1125）：STR 'FACILITYNAME'/… |
| 0x141C1B760 | NFactions::NUi::CRequestManpowerWindow 槽6（gamestate.h:1125） NFactions::NUi::CRequestManpowerWindow 槽6（gamestate.h:1125）：STR 'REQUEST_FACTION_MANPOWER_VALUES'… |
| 0x141BFE8C0 | NFactions::NUi::CBecomeLeaderConfirmationWindow::[16] COST/FACTION/COOLDOWN loc 键 + CBecomeLeaderConfirmationWindow 类名 |
| 0x14179DE40 | NFactions::NUi::CFactionTheaterSwitch::[6] 类名 + "_miniature" 串（派系战场剧院切换 GUI 槽 6） |
| 0x1416024E0 | NFactions::CLeaveFactionAction::[24] vtable 槽 NFactions::CLeaveFactionAction::[24]（func_names RTTI 名） |
| 0x141F15DB0 | NFactions::NUi::CFilterRuleItem::[0] vtable 槽 NFactions::NUi::CFilterRuleItem::[0]（func_names RTTI 名） |
| 0x14179DA40 | NFactions::NUi::CFactionPingCountryItem::[20] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[20]（func_names RTTI 名） |
| 0x141E2F140 | NFactions::NUi::CFactionIconWindow::[0] vtable 槽 NFactions::NUi::CFactionIconWindow::[0]（func_names RTTI 名） |
| 0x1416175F0 | NFactions::CJoinFactionAction::[57] vtable 槽 NFactions::CJoinFactionAction::[57]（func_names RTTI 名） |
| 0x141F11FD0 | NFactions::NUi::CChangeGoalItemRow::[0] vtable 槽 NFactions::NUi::CChangeGoalItemRow::[0]（func_names RTTI 名） |
| 0x141617440 | NFactions::CAssumeFactionLeadershipAction::[57] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[57]（func_names RTTI 名） |
| 0x1414774D0 | NFactions::NUi::CCountryFactionView::[9] vtable 槽 NFactions::NUi::CCountryFactionView::[9]（func_names RTTI 名） |
| 0x141796E70 | NFactions::NUi::CFactionTheaterItem::[0] vtable 槽 NFactions::NUi::CFactionTheaterItem::[0]（func_names RTTI 名） |
| 0x140A2A260 | NFactions::CFactionUpgrade::[4] vtable 槽 NFactions::CFactionUpgrade::[4]（func_names RTTI 名） |
| 0x141C0C690 | NFactions::NUi::CChangeRuleWindow::[0] vtable 槽 NFactions::NUi::CChangeRuleWindow::[0]（func_names RTTI 名） |
| 0x141617750 | NFactions::CLeaveFactionAction::[57] vtable 槽 NFactions::CLeaveFactionAction::[57]（func_names RTTI 名） |
| 0x141617590 | NFactions::CDismantleFactionAction::[57] vtable 槽 NFactions::CDismantleFactionAction::[57]（func_names RTTI 名） |
| 0x141BA7D20 | NFactions::CSetFactionIconAndColor::[0] vtable 槽 NFactions::CSetFactionIconAndColor::[0]（func_names RTTI 名） |
| 0x1417996A0 | NFactions::NUi::CFactionPingCountryItem::[21] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[21]（func_names RTTI 名） |
| 0x141ADD320 | NFactions::NUi::CInviteCountryItem::[21] vtable 槽 NFactions::NUi::CInviteCountryItem::[21]（func_names RTTI 名） |
| 0x14015F880 | NFactions::CFactionIconPool::[0] vtable 槽 NFactions::CFactionIconPool::[0]（func_names RTTI 名） |
| 0x14146D390 | NFactions::NUi::CIntelligenceTabSection::[0] vtable 槽 NFactions::NUi::CIntelligenceTabSection::[0]（func_names RTTI 名） |
| 0x140A2D9A0 | NFactions::CFactionRuleGroup::[4] vtable 槽 NFactions::CFactionRuleGroup::[4]（func_names RTTI 名） |
| 0x141BF9280 | NFactions::NUi::CFactionCommanderWindow::[6] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[6]（func_names RTTI 名） |
| 0x141C19790 | NFactions::NUi::CFactionProgramItem::[27] vtable 槽 NFactions::NUi::CFactionProgramItem::[27]（func_names RTTI 名） |
| 0x14146CF10 | NFactions::NUi::CFactionCountrySection::[0] vtable 槽 NFactions::NUi::CFactionCountrySection::[0]（func_names RTTI 名） |
| 0x141823420 | NFactions::NUi::CLegacyCreateFactionWindow::[5] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[5]（func_names RTTI 名） |
| 0x141ADB730 | NFactions::NUi::CKickFromFactionCountryItem::[0] vtable 槽 NFactions::NUi::CKickFromFactionCountryItem::[0]（func_names RTTI 名） |
| 0x14194F910 | NFactions::CFactionTheaterManager::[0] vtable 槽 NFactions::CFactionTheaterManager::[0]（func_names RTTI 名） |
| 0x141F0A0D0 | NFactions::NUi::CFactionMemberUpgradeItem::[1] vtable 槽 NFactions::NUi::CFactionMemberUpgradeItem::[1]（func_names RTTI 名） |
| 0x141613A60 | NFactions::CAssumeFactionLeadershipAction::[23] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[23]（func_names RTTI 名） |
| 0x141BE6250 | NFactions::CTechnologySharingFaction::[18] vtable 槽 NFactions::CTechnologySharingFaction::[18]（func_names RTTI 名） |
| 0x141613CF0 | NFactions::COfferJoinFactionAction::[23] vtable 槽 NFactions::COfferJoinFactionAction::[23]（func_names RTTI 名） |
| 0x141613B30 | NFactions::CDismantleFactionAction::[23] vtable 槽 NFactions::CDismantleFactionAction::[23]（func_names RTTI 名） |
| 0x141613C10 | NFactions::CKickFromFactionAction::[23] vtable 槽 NFactions::CKickFromFactionAction::[23]（func_names RTTI 名） |
| 0x141796CE0 | NFactions::NUi::CFactionPingCountryItem::[0] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[0]（func_names RTTI 名） |
| 0x141613AD0 | NFactions::CCreateFactionAction::[23] vtable 槽 NFactions::CCreateFactionAction::[23]（func_names RTTI 名） |
| 0x141C19720 | NFactions::NUi::CFactionProgramItemEmpty::[0] vtable 槽 NFactions::NUi::CFactionProgramItemEmpty::[0]（func_names RTTI 名） |
| 0x141F0A080 | NFactions::NUi::CFactionMemberUpgradeButton::[0] vtable 槽 NFactions::NUi::CFactionMemberUpgradeButton::[0]（func_names RTTI 名） |
| 0x141613C80 | NFactions::CLeaveFactionAction::[23] vtable 槽 NFactions::CLeaveFactionAction::[23]（func_names RTTI 名） |
| 0x141613BA0 | NFactions::CJoinFactionAction::[23] vtable 槽 NFactions::CJoinFactionAction::[23]（func_names RTTI 名） |
| 0x141822D20 | NFactions::NUi::CLegacyCreateFactionWindow::[0] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[0]（func_names RTTI 名） |
| 0x141E2F240 | NFactions::NUi::CFactionColorPickerWindow::[5] vtable 槽 NFactions::NUi::CFactionColorPickerWindow::[5]（func_names RTTI 名） |
| 0x141F11F70 | NFactions::NUi::CChangeGoalItem::[0] vtable 槽 NFactions::NUi::CChangeGoalItem::[0]（func_names RTTI 名） |
| 0x140D894D0 | NFactions::CFactionProgramStatus::[0] vtable 槽 NFactions::CFactionProgramStatus::[0]（func_names RTTI 名） |
| 0x140177790 | NFactions::CFactionUpgrade::[14] vtable 槽 NFactions::CFactionUpgrade::[14]（func_names RTTI 名） |
| 0x14146CE90 | NFactions::NUi::CFactionArmySection::[0] vtable 槽 NFactions::NUi::CFactionArmySection::[0]（func_names RTTI 名） |
| 0x141C0C990 | NFactions::NUi::CChangeRuleWindow::[5] vtable 槽 NFactions::NUi::CChangeRuleWindow::[5]（func_names RTTI 名） |
| 0x140A2C5F0 | NFactions::CFactionMemberUpgradeGroup::[11] vtable 槽 NFactions::CFactionMemberUpgradeGroup::[11]（func_names RTTI 名） |
| 0x141E2F030 | NFactions::NUi::CFactionColorPickerWindow::[0] vtable 槽 NFactions::NUi::CFactionColorPickerWindow::[0]（func_names RTTI 名） |
| 0x141E75970 | NFactions::NUi::CFactionButton::[1] vtable 槽 NFactions::NUi::CFactionButton::[1]（func_names RTTI 名） |
| 0x141797050 | NFactions::NUi::CFactionTheaterWindow::[5] vtable 槽 NFactions::NUi::CFactionTheaterWindow::[5]（func_names RTTI 名） |
| 0x141C22AE0 | NFactions::NUi::CFactionScientistRoster::[7] vtable 槽 NFactions::NUi::CFactionScientistRoster::[7]（func_names RTTI 名） |
| 0x141ADB680 | NFactions::NUi::CInviteCountriesWindow::[0] vtable 槽 NFactions::NUi::CInviteCountriesWindow::[0]（func_names RTTI 名） |
| 0x141ADB5F0 | NFactions::NUi::CFactionCountryItem::[0] vtable 槽 NFactions::NUi::CFactionCountryItem::[0]（func_names RTTI 名） |
| 0x141C1CBC0 | NFactions::NUi::CResearchFacilityItem::[0] vtable 槽 NFactions::NUi::CResearchFacilityItem::[0]（func_names RTTI 名） |
| 0x141F16870 | NFactions::NUi::CFactionMemberScientistItem::[0] vtable 槽 NFactions::NUi::CFactionMemberScientistItem::[0]（func_names RTTI 名） |
| 0x1417A0DE0 | NFactions::NUi::CFactionUiManager::[1] vtable 槽 NFactions::NUi::CFactionUiManager::[1]（func_names RTTI 名） |
| 0x14146D4B0 | NFactions::NUi::CRequestManpowerWindow::[0] vtable 槽 NFactions::NUi::CRequestManpowerWindow::[0]（func_names RTTI 名） |
| 0x141822DD0 | NFactions::NUi::CNewFactionWindow::[0] vtable 槽 NFactions::NUi::CNewFactionWindow::[0]（func_names RTTI 名） |
| 0x14179F7F0 | NFactions::NUi::CFactionTheaterSwitch::[0] vtable 槽 NFactions::NUi::CFactionTheaterSwitch::[0]（func_names RTTI 名） |
| 0x141BFB9C0 | NFactions::NUi::CDoctrineSharingFolderItem::[0] vtable 槽 NFactions::NUi::CDoctrineSharingFolderItem::[0]（func_names RTTI 名） |
| 0x141ADB6E0 | NFactions::NUi::CInviteCountryItem::[0] vtable 槽 NFactions::NUi::CInviteCountryItem::[0]（func_names RTTI 名） |
| 0x141C17890 | NFactions::NUi::CGoalItem::[0] vtable 槽 NFactions::NUi::CGoalItem::[0]（func_names RTTI 名） |
| 0x141C26A00 | NFactions::NUi::CRuleTypeItem::[0] vtable 槽 NFactions::NUi::CRuleTypeItem::[0]（func_names RTTI 名） |
| 0x141F13A00 | NFactions::NUi::CFilterGoalItem::[0] vtable 槽 NFactions::NUi::CFilterGoalItem::[0]（func_names RTTI 名） |
| 0x140A23390 | NFactions::CFactionGoal::[1] vtable 槽 NFactions::CFactionGoal::[1]（func_names RTTI 名） |
| 0x141C07BC0 | NFactions::NUi::CChangeGoalWindow::[5] vtable 槽 NFactions::NUi::CChangeGoalWindow::[5]（func_names RTTI 名） |
| 0x140A2BEB0 | NFactions::CFactionMemberUpgradeGroup::[12] vtable 槽 NFactions::CFactionMemberUpgradeGroup::[12]（func_names RTTI 名） |
| 0x141C24150 | NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0]（func_names RTTI 名） |
| 0x14146CCD0 | NFactions::NUi::CConfirmRuleWindow::[0] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[0]（func_names RTTI 名） |
| 0x14146CD70 | NFactions::NUi::CConfirmGoalWindow::[0] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[0]（func_names RTTI 名） |
| 0x140177740 | NFactions::CFactionMemberUpgrade::[14] vtable 槽 NFactions::CFactionMemberUpgrade::[14]（func_names RTTI 名） |
| 0x14146D030 | NFactions::NUi::CFactionHeaderSection::[0] vtable 槽 NFactions::NUi::CFactionHeaderSection::[0]（func_names RTTI 名） |
| 0x141BF8DD0 | NFactions::NUi::CFactionCommanderWindow::[12] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[12]（func_names RTTI 名） |
| 0x141C5A860 | NFactions::NUi::CFactionListItem::[0] vtable 槽 NFactions::NUi::CFactionListItem::[0]（func_names RTTI 名） |
| 0x141ADB630 | NFactions::NUi::CFactionMemberCountriesWindow::[0] vtable 槽 NFactions::NUi::CFactionMemberCountriesWindow::[0]（func_names RTTI 名） |
| 0x14157E2A0 | NFactions::NUi::CFactionListWindow::[0] vtable 槽 NFactions::NUi::CFactionListWindow::[0]（func_names RTTI 名） |
| 0x140A2A100 | NFactions::CFactionIconPool::[4] vtable 槽 NFactions::CFactionIconPool::[4]（func_names RTTI 名） |
| 0x140A2A2F0 | NFactions::CFactionMemberUpgrade::[12] vtable 槽 NFactions::CFactionMemberUpgrade::[12]（func_names RTTI 名） |
| 0x14015CB60 | NFactions::NAi::CAiFactionTheaterDatabase::[1] vtable 槽 NFactions::NAi::CAiFactionTheaterDatabase::[1]（func_names RTTI 名） |
| 0x140D89490 | NFactions::CFaction::[0] vtable 槽 NFactions::CFaction::[0]（func_names RTTI 名） |
| 0x140B64420 | NFactions::NUi::CFactionPingView::[0] vtable 槽 NFactions::NUi::CFactionPingView::[0]（func_names RTTI 名） |
| 0x14146DA50 | NFactions::NUi::CAssignTheaterLeaderPopup::[15] vtable 槽 NFactions::NUi::CAssignTheaterLeaderPopup::[15]（func_names RTTI 名） |
| 0x14146DA20 | NFactions::NUi::CLeaveFactionConfirmationWindow::[16] vtable 槽 NFactions::NUi::CLeaveFactionConfirmationWindow::[16]（func_names RTTI 名） |
| 0x14146DB70 | NFactions::NUi::CInviteToFactionPopup::[15] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[15]（func_names RTTI 名） |
| 0x141796F10 | NFactions::NUi::CFactionTheaterWindow::[0] vtable 槽 NFactions::NUi::CFactionTheaterWindow::[0]（func_names RTTI 名） |
| 0x14146DAB0 | NFactions::NUi::CDismantleFactionConfirmationWindow::[15] vtable 槽 NFactions::NUi::CDismantleFactionConfirmationWindow::[15]（func_names RTTI 名） |
| 0x14146DBA0 | NFactions::NUi::CKickFromFactionPopup::[15] vtable 槽 NFactions::NUi::CKickFromFactionPopup::[15]（func_names RTTI 名） |
| 0x141C07D90 | NFactions::NUi::CChangeGoalWindow::[8] vtable 槽 NFactions::NUi::CChangeGoalWindow::[8]（func_names RTTI 名） |
| 0x14146DAE0 | NFactions::NUi::CDoctrineSharingPopup::[15] vtable 槽 NFactions::NUi::CDoctrineSharingPopup::[15]（func_names RTTI 名） |
| 0x14015CC60 | NFactions::CFactionGoalDatabase::[1] vtable 槽 NFactions::CFactionGoalDatabase::[1]（func_names RTTI 名） |
| 0x14015CCA0 | NFactions::CFactionIconsDatabase::[1] vtable 槽 NFactions::CFactionIconsDatabase::[1]（func_names RTTI 名） |
| 0x14015CCE0 | NFactions::CFactionMemberUpgradeDatabase::[1] vtable 槽 NFactions::CFactionMemberUpgradeDatabase::[1]（func_names RTTI 名） |
| 0x14015CD20 | NFactions::CFactionMemberUpgradeGroupDatabase::[1] vtable 槽 NFactions::CFactionMemberUpgradeGroupDatabase::[1]（func_names RTTI 名） |
| 0x14015CD60 | NFactions::CFactionRuleDatabase::[1] vtable 槽 NFactions::CFactionRuleDatabase::[1]（func_names RTTI 名） |
| 0x14015CDA0 | NFactions::CFactionRuleGroupDatabase::[1] vtable 槽 NFactions::CFactionRuleGroupDatabase::[1]（func_names RTTI 名） |
| 0x14015CDE0 | NFactions::CFactionTemplateDatabase::[1] vtable 槽 NFactions::CFactionTemplateDatabase::[1]（func_names RTTI 名） |
| 0x14015F140 | NFactions::NAi::CAiFactionTheater::[0] vtable 槽 NFactions::NAi::CAiFactionTheater::[0]（func_names RTTI 名） |
| 0x14015F840 | NFactions::CFactionGoal::[0] vtable 槽 NFactions::CFactionGoal::[0]（func_names RTTI 名） |
| 0x14015F900 | NFactions::CFactionUpgrade::[0] vtable 槽 NFactions::CFactionUpgrade::[0]（func_names RTTI 名） |
| 0x14015F940 | NFactions::CFactionUpgradeGroup::[0] vtable 槽 NFactions::CFactionUpgradeGroup::[0]（func_names RTTI 名） |
| 0x14015F980 | NFactions::CFactionRule::[0] vtable 槽 NFactions::CFactionRule::[0]（func_names RTTI 名） |
| 0x14015FA20 | NFactions::CFactionTemplate::[0] vtable 槽 NFactions::CFactionTemplate::[0]（func_names RTTI 名） |
| 0x140A267D0 | NFactions::CFactionGoalStatus::[0] vtable 槽 NFactions::CFactionGoalStatus::[0]（func_names RTTI 名） |
| 0x14146CC90 | NFactions::NUi::CAssignResearchFacilityWindow::[0] vtable 槽 NFactions::NUi::CAssignResearchFacilityWindow::[0]（func_names RTTI 名） |
| 0x14146CDC0 | NFactions::NUi::CCountryFactionView::[0] vtable 槽 NFactions::NUi::CCountryFactionView::[0]（func_names RTTI 名） |
| 0x14146CE50 | NFactions::NUi::CDoctrineSharingWindow::[1] vtable 槽 NFactions::NUi::CDoctrineSharingWindow::[1]（func_names RTTI 名） |
| 0x14146D080 | NFactions::NUi::CFactionProgramList::[0] vtable 槽 NFactions::NUi::CFactionProgramList::[0]（func_names RTTI 名） |
| 0x14146D210 | NFactions::NUi::CFactionTabSection::[0] vtable 槽 NFactions::NUi::CFactionTabSection::[0]（func_names RTTI 名） |
| 0x14146DBD0 | NFactions::NUi::CLeaveFactionConfirmationWindow::[15] vtable 槽 NFactions::NUi::CLeaveFactionConfirmationWindow::[15]（func_names RTTI 名） |
| 0x141796CA0 | NFactions::NUi::CFactionCountryListWindow::[0] vtable 槽 NFactions::NUi::CFactionCountryListWindow::[0]（func_names RTTI 名） |
| 0x141BE61F0 | NFactions::CTechnologySharingFaction::[13] vtable 槽 NFactions::CTechnologySharingFaction::[13]（func_names RTTI 名） |
| 0x141C236F0 | NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSelectionItem::[0]（func_names RTTI 名） |
| 0x141BE61D0 | NFactions::CTechnologySharingFaction::[9] vtable 槽 NFactions::CTechnologySharingFaction::[9]（func_names RTTI 名） |
| 0x14146DB10 | NFactions::NUi::CFactionIntelligencePopup::[15] vtable 槽 NFactions::NUi::CFactionIntelligencePopup::[15]（func_names RTTI 名） |
| 0x14146DB40 | NFactions::NUi::CFactionTheaterPopup::[15] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[15]（func_names RTTI 名） |
| 0x141BE6220 | NFactions::CTechnologySharingFaction::[14] vtable 槽 NFactions::CTechnologySharingFaction::[14]（func_names RTTI 名） |
| 0x14146DA80 | NFactions::NUi::CConfirmFactionFacilityProgram::[15] vtable 槽 NFactions::NUi::CConfirmFactionFacilityProgram::[15]（func_names RTTI 名） |
| 0x1417970AC | NFactions::NUi::CFactionPingCountryItem::[0] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[0]（func_names RTTI 名） |
| 0x141C03310 | NFactions::NUi::CFactionPopup::[17] vtable 槽 NFactions::NUi::CFactionPopup::[17]（func_names RTTI 名） |
| 0x141C01DF0 | NFactions::NUi::CConfirmGoalWindow::[15] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[15]（func_names RTTI 名） |
| 0x141796C60 | NFactions::NUi::CFactionPingCountryItem::[1] vtable 槽 NFactions::NUi::CFactionPingCountryItem::[1]（func_names RTTI 名） |
| 0x141825540 | NFactions::NUi::CLegacyCreateFactionWindow::[7] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[7]（func_names RTTI 名） |
| 0x141BF8C60 | NFactions::NUi::CFactionCommanderWindow::[1] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[1]（func_names RTTI 名） |
| 0x141C17878 | NFactions::NUi::CGoalItem::[1] vtable 槽 NFactions::NUi::CGoalItem::[1]（func_names RTTI 名） |
| 0x141C5A854 | NFactions::NUi::CFactionListItem::[1] vtable 槽 NFactions::NUi::CFactionListItem::[1]（func_names RTTI 名） |
| 0x14146CB1C | NFactions::NUi::CConfirmGoalWindow::[1] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[1]（func_names RTTI 名） |
| 0x141ADB5D0 | NFactions::NUi::CInviteCountryItem::[1] vtable 槽 NFactions::NUi::CInviteCountryItem::[1]（func_names RTTI 名） |
| 0x141ADB5DC | NFactions::NUi::CKickFromFactionCountryItem::[1] vtable 槽 NFactions::NUi::CKickFromFactionCountryItem::[1]（func_names RTTI 名） |
| 0x141C1CB70 | NFactions::NUi::CResearchFacilityItem::[1] vtable 槽 NFactions::NUi::CResearchFacilityItem::[1]（func_names RTTI 名） |
| 0x14179F7E0 | NFactions::NUi::CFactionTheaterSwitch::[1] vtable 槽 NFactions::NUi::CFactionTheaterSwitch::[1]（func_names RTTI 名） |
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
| 0x141796C94 | NFactions::NUi::CFactionTheaterItem::[1] vtable 槽 NFactions::NUi::CFactionTheaterItem::[1]（func_names RTTI 名） |
| 0x141822AF4 | NFactions::NUi::CFactionSetupWindow::[1] vtable 槽 NFactions::NUi::CFactionSetupWindow::[1]（func_names RTTI 名） |
| 0x141822B00 | NFactions::NUi::CFactionSetupWindow::[0] vtable 槽 NFactions::NUi::CFactionSetupWindow::[0]（func_names RTTI 名） |
| 0x141822B0C | NFactions::NUi::CNewFactionTemplateItem::[1] vtable 槽 NFactions::NUi::CNewFactionTemplateItem::[1]（func_names RTTI 名） |
| 0x141BF8C6C | NFactions::NUi::CFactionCommanderWindow::[0] vtable 槽 NFactions::NUi::CFactionCommanderWindow::[0]（func_names RTTI 名） |
| 0x141BFB9A8 | NFactions::NUi::CDoctrineSharingFolderItem::[1] vtable 槽 NFactions::NUi::CDoctrineSharingFolderItem::[1]（func_names RTTI 名） |
| 0x141C19630 | NFactions::NUi::CFactionProgramItem::[1] vtable 槽 NFactions::NUi::CFactionProgramItem::[1]（func_names RTTI 名） |
| 0x141C1963C | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x141C19648 | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x141C19654 | NFactions::NUi::CFactionProgramItemEmpty::[1] vtable 槽 NFactions::NUi::CFactionProgramItemEmpty::[1]（func_names RTTI 名） |
| 0x141C236D8 | NFactions::NUi::CIntelligenceAdvisorSelectionItem::[1] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSelectionItem::[1]（func_names RTTI 名） |
| 0x141C236E4 | NFactions::NUi::CIntelligenceAdvisorSlotItem::[1] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSlotItem::[1]（func_names RTTI 名） |
| 0x141C269F0 | NFactions::NUi::CRuleTypeItem::[1] vtable 槽 NFactions::NUi::CRuleTypeItem::[1]（func_names RTTI 名） |
| 0x141F0A068 | NFactions::NUi::CFactionMemberUpgradeButton::[1] vtable 槽 NFactions::NUi::CFactionMemberUpgradeButton::[1]（func_names RTTI 名） |
| 0x141F11F58 | NFactions::NUi::CChangeGoalItem::[1] vtable 槽 NFactions::NUi::CChangeGoalItem::[1]（func_names RTTI 名） |
| 0x141F139F4 | NFactions::NUi::CFilterGoalItem::[1] vtable 槽 NFactions::NUi::CFilterGoalItem::[1]（func_names RTTI 名） |
| 0x141F1498C | NFactions::NUi::CChangeRuleItem::[1] vtable 槽 NFactions::NUi::CChangeRuleItem::[1]（func_names RTTI 名） |
| 0x141F1685C | NFactions::NUi::CFactionMemberScientistItem::[1] vtable 槽 NFactions::NUi::CFactionMemberScientistItem::[1]（func_names RTTI 名） |
| 0x141C22AD0 | NFactions::NUi::CFactionScientistRoster::[4] vtable 槽 NFactions::NUi::CFactionScientistRoster::[4]（func_names RTTI 名） |
| 0x14146EB00 | NFactions::NUi::CFactionCountrySection::[0] vtable 槽 NFactions::NUi::CFactionCountrySection::[0]（func_names RTTI 名） |
| 0x141E759C0 | NFactions::NUi::CFactionButton::[0] vtable 槽 NFactions::NUi::CFactionButton::[0]（func_names RTTI 名） |
| 0x141C00BA0 | NFactions::NUi::CInviteToFactionPopup::[16] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[16]（func_names RTTI 名） |
| 0x141F12180 | NFactions::NUi::CChangeGoalItem::[0] vtable 槽 NFactions::NUi::CChangeGoalItem::[0]（func_names RTTI 名） |
| 0x141610230 | NFactions::COfferJoinFactionAction::[59] vtable 槽 NFactions::COfferJoinFactionAction::[59]（func_names RTTI 名） |
| 0x14146DF80 | NFactions::NUi::CFactionArmySection::[0] vtable 槽 NFactions::NUi::CFactionArmySection::[0]（func_names RTTI 名） |
| 0x14146FAC0 | NFactions::NUi::CFactionHeaderSection::[0] vtable 槽 NFactions::NUi::CFactionHeaderSection::[0]（func_names RTTI 名） |
| 0x1418235F0 | NFactions::NUi::CFactionSetupWindow::[0] vtable 槽 NFactions::NUi::CFactionSetupWindow::[0]（func_names RTTI 名） |
| 0x141BFF8E0 | NFactions::NUi::CConfirmRuleWindow::[16] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[16]（func_names RTTI 名） |
| 0x141BFEFA0 | NFactions::NUi::CConfirmGoalWindow::[16] vtable 槽 NFactions::NUi::CConfirmGoalWindow::[16]（func_names RTTI 名） |
| 0x14160F7D0 | NFactions::CJoinFactionAction::[59] vtable 槽 NFactions::CJoinFactionAction::[59]（func_names RTTI 名） |
| 0x141615CF0 | NFactions::CJoinFactionAction::CanExecute func_names 名 NFactions::CJoinFactionAction::CanExecute |
| 0x1416127C0 | NFactions::CJoinFactionAction::GetRequestDescText func_names 名 NFactions::CJoinFactionAction::GetRequestDescText |
| 0x141612120 | NFactions::CCreateFactionAction::GetRequestDescText func_names 名 NFactions::CCreateFactionAction::GetRequestDescText |
| 0x141615440 | NFactions::CCreateFactionAction::CanExecute func_names 名 NFactions::CCreateFactionAction::CanExecute |
| 0x141612DE0 | NFactions::CKickFromFactionAction::GetRequestDescText func_names 名 NFactions::CKickFromFactionAction::GetRequestDescText |
| 0x141F14F50 | NFactions::NUi::CChangeRuleItem 槽 0 func_names 名 + gamestate 访问断言 |
| 0x141C26A50 | NFactions::NUi::CActiveRuleText::[0] vtable 槽 NFactions::NUi::CActiveRuleText::[0]（func_names RTTI 名） |
| 0x141611210 | NFactions::CDismantleFactionAction::[21] vtable 槽 NFactions::CDismantleFactionAction::[21]（func_names RTTI 名） |
| 0x141827EE0 | NFactions::NUi::CLegacyCreateFactionWindow::[6] vtable 槽 NFactions::NUi::CLegacyCreateFactionWindow::[6]（func_names RTTI 名） |
| 0x141C00760 | NFactions::NUi::CFactionIntelligencePopup::[16] vtable 槽 NFactions::NUi::CFactionIntelligencePopup::[16]（func_names RTTI 名） |
| 0x141BE62C0 | NFactions::CTechnologySharingFaction::[12] vtable 槽 NFactions::CTechnologySharingFaction::[12]（func_names RTTI 名） |
| 0x141BAE4B0 | NFactions::CUnlockFolderDoctrineSharingCommand::PayloadReader func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::PayloadReader |
| 0x140A23880 | NFactions::CFactionGoal::[4] vtable 槽 NFactions::CFactionGoal::[4]（func_names RTTI 名） |
| 0x140A299E0 | NFactions::CFactionGoalStatus::Writer func_names 名 NFactions::CFactionGoalStatus::Writer |
| 0x141C01B90 | NFactions::NUi::CBecomeLeaderConfirmationWindow::[15] vtable 槽 NFactions::NUi::CBecomeLeaderConfirmationWindow::[15]（func_names RTTI 名） |
| 0x141ADFC50 | NFactions::NUi::CKickFromFactionCountryItem::[20] vtable 槽 NFactions::NUi::CKickFromFactionCountryItem::[20]（func_names RTTI 名） |
| 0x141C01E20 | NFactions::NUi::CConfirmRuleWindow::[15] vtable 槽 NFactions::NUi::CConfirmRuleWindow::[15]（func_names RTTI 名） |
| 0x14146D840 | NFactions::NUi::CCountryFactionView::ClearContents func_names 名 NFactions::NUi::CCountryFactionView::ClearContents |
| 0x14179E0C0 | NFactions::NUi::CFactionTheaterWindow::[6] vtable 槽 NFactions::NUi::CFactionTheaterWindow::[6]（func_names RTTI 名） |
| 0x141C03130 | NFactions::NUi::CLeaveFactionConfirmationWindow::[14] vtable 槽 NFactions::NUi::CLeaveFactionConfirmationWindow::[14]（func_names RTTI 名） |
| 0x141615B70 | NFactions::CDismantleFactionAction::CanExecute func_names 名 NFactions::CDismantleFactionAction::CanExecute |
| 0x141610BD0 | NFactions::CAssumeFactionLeadershipAction::[58] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[58]（func_names RTTI 名） |
| 0x14160F640 | NFactions::CDismantleFactionAction::[59] vtable 槽 NFactions::CDismantleFactionAction::[59]（func_names RTTI 名） |
| 0x14179F850 | NFactions::NUi::CFactionUiManager::[0] vtable 槽 NFactions::NUi::CFactionUiManager::[0]（func_names RTTI 名） |
| 0x141C02060 | NFactions::NUi::CKickFromFactionPopup::[14] vtable 槽 NFactions::NUi::CKickFromFactionPopup::[14]（func_names RTTI 名） |
| 0x140A2D450 | NFactions::CFactionRule::[8] vtable 槽 NFactions::CFactionRule::[8]（func_names RTTI 名） |
| 0x141602110 | NFactions::CCreateFactionAction::[24] vtable 槽 NFactions::CCreateFactionAction::[24]（func_names RTTI 名） |
| 0x141BA7BF0 | NFactions::CModifyFactionTheater::[0] vtable 槽 NFactions::CModifyFactionTheater::[0]（func_names RTTI 名） |
| 0x140A2D860 | NFactions::CFactionRule::[4] vtable 槽 NFactions::CFactionRule::[4]（func_names RTTI 名） |
| 0x1416025D0 | NFactions::COfferJoinFactionAction::[24] vtable 槽 NFactions::COfferJoinFactionAction::[24]（func_names RTTI 名） |
| 0x141BAE340 | NFactions::CSetFactionUpgradeCommand::PayloadReader func_names 名 NFactions::CSetFactionUpgradeCommand::PayloadReader |
| 0x141602020 | NFactions::CAssumeFactionLeadershipAction::[24] vtable 槽 NFactions::CAssumeFactionLeadershipAction::[24]（func_names RTTI 名） |
| 0x1413FA240 | NFactions::CFactionUpgradeStatus::[0] vtable 槽 NFactions::CFactionUpgradeStatus::[0]（func_names RTTI 名） |
| 0x141602210 | NFactions::CDismantleFactionAction::[24] vtable 槽 NFactions::CDismantleFactionAction::[24]（func_names RTTI 名） |
| 0x14146D250 | NFactions::NUi::CFactionTheaterPopup::[0] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[0]（func_names RTTI 名） |
| 0x141ADD280 | NFactions::NUi::CFactionMemberCountriesWindow::[8] vtable 槽 NFactions::NUi::CFactionMemberCountriesWindow::[8]（func_names RTTI 名） |
| 0x141BAD870 | NFactions::CAddFactionGoalCommand::PayloadReader func_names 名 NFactions::CAddFactionGoalCommand::PayloadReader |
| 0x141C5A8A0 | NFactions::NUi::CFactionListWindow::[5] vtable 槽 NFactions::NUi::CFactionListWindow::[5]（func_names RTTI 名） |
| 0x140A28210 | NFactions::CFactionGoalDatabase::[0] vtable 槽 NFactions::CFactionGoalDatabase::[0]（func_names RTTI 名） |
| 0x141823340 | NFactions::NUi::CFactionSetupWindow::ClearContents func_names 名 NFactions::NUi::CFactionSetupWindow::ClearContents |
| 0x141C5AA10 | NFactions::NUi::CFactionListItem::[0] vtable 槽 NFactions::NUi::CFactionListItem::[0]（func_names RTTI 名） |
| 0x1416177E0 | NFactions::COfferJoinFactionAction::[57] vtable 槽 NFactions::COfferJoinFactionAction::[57]（func_names RTTI 名） |
| 0x141C19810 | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x141C23730 | NFactions::NUi::CIntelligenceAdvisorSlotItem::[0] vtable 槽 NFactions::NUi::CIntelligenceAdvisorSlotItem::[0]（func_names RTTI 名） |
| 0x141C19660 | NFactions::NUi::CFactionProgramItem::[0] vtable 槽 NFactions::NUi::CFactionProgramItem::[0]（func_names RTTI 名） |
| 0x141BA7DB0 | NFactions::CAddFactionGoalCommand::Clone func_names 名 NFactions::CAddFactionGoalCommand::Clone |
| 0x140D91C10 | NFactions::CFactionSystem::[0] vtable 槽 NFactions::CFactionSystem::[0]（func_names RTTI 名） |
| 0x141ADD370 | NFactions::NUi::CInviteCountriesWindow::[10] vtable 槽 NFactions::NUi::CInviteCountriesWindow::[10]（func_names RTTI 名） |
| 0x141BA87D0 | NFactions::CUpdateIntelligenceAdvisorSlotCommand::Clone func_names 名 NFactions::CUpdateIntelligenceAdvisorSlotCommand::Clone |
| 0x141BA8230 | NFactions::CFactionSetCommanderCommand::Clone func_names 名 NFactions::CFactionSetCommanderCommand::Clone |
| 0x140A2A4B0 | NFactions::CFactionMemberUpgrade::[13] vtable 槽 NFactions::CFactionMemberUpgrade::[13]（func_names RTTI 名） |
| 0x14131A9D0 | NFactions::CSetFactionPingExecutionType::Clone func_names 名 NFactions::CSetFactionPingExecutionType::Clone |
| 0x141BA8190 | NFactions::CFactionAttachScientistCommand::Clone func_names 名 NFactions::CFactionAttachScientistCommand::Clone |
| 0x141BA8610 | NFactions::CSetFactionTheaterPinVisibility::Clone func_names 名 NFactions::CSetFactionTheaterPinVisibility::Clone |
| 0x140A2A1A0 | NFactions::CFactionUpgrade::[11] vtable 槽 NFactions::CFactionUpgrade::[11]（func_names RTTI 名） |
| 0x141BA7EE0 | NFactions::CClearFactionTheater::Clone func_names 名 NFactions::CClearFactionTheater::Clone |
| 0x141BAE0B0 | NFactions::CModifyFactionTheater::PayloadReader func_names 名 NFactions::CModifyFactionTheater::PayloadReader |
| 0x141BA8740 | NFactions::CUnlockFolderDoctrineSharingCommand::Clone func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::Clone |
| 0x141BADE60 | NFactions::CFactionAttachScientistCommand::PayloadReader func_names 名 NFactions::CFactionAttachScientistCommand::PayloadReader |
| 0x141BA82D0 | NFactions::CFactionUnattachScientistCommand::Clone func_names 名 NFactions::CFactionUnattachScientistCommand::Clone |
| 0x14131AA60 | NFactions::CUseFactionMemberManpower::Clone func_names 名 NFactions::CUseFactionMemberManpower::Clone |
| 0x141BA7E50 | NFactions::CAddFactionProgramCommand::Clone func_names 名 NFactions::CAddFactionProgramCommand::Clone |
| 0x141BA8100 | NFactions::CEraseFactionRuleCommand::Clone func_names 名 NFactions::CEraseFactionRuleCommand::Clone |
| 0x141BA86B0 | NFactions::CSetFactionUpgradeCommand::Clone func_names 名 NFactions::CSetFactionUpgradeCommand::Clone |
| 0x141BA8580 | NFactions::CSetFactionRuleCommand::Clone func_names 名 NFactions::CSetFactionRuleCommand::Clone |
| 0x141471850 | NFactions::NUi::CCountryFactionView::Reload func_names 名 NFactions::NUi::CCountryFactionView::Reload |
| 0x141BA83A0 | NFactions::CRemoveFactionProgramCommand::Clone func_names 名 NFactions::CRemoveFactionProgramCommand::Clone |
| 0x1406338F0 | NFactions::NAi::CAiFactionTheater::[4] vtable 槽 NFactions::NAi::CAiFactionTheater::[4]（func_names RTTI 名） |
| 0x141E2F2A0 | NFactions::NUi::CFactionIconWindow::[5] vtable 槽 NFactions::NUi::CFactionIconWindow::[5]（func_names RTTI 名） |
| 0x1414714F0 | NFactions::NUi::CCountryFactionView::[7] vtable 槽 NFactions::NUi::CCountryFactionView::[7]（func_names RTTI 名） |
| 0x141C00AE0 | NFactions::NUi::CFactionTheaterPopup::[16] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[16]（func_names RTTI 名） |
| 0x141994760 | NFactions::CFactionRuleStatus::[0] vtable 槽 NFactions::CFactionRuleStatus::[0]（func_names RTTI 名） |
| 0x141C07470 | NFactions::NUi::CChangeGoalWindow::[0] vtable 槽 NFactions::NUi::CChangeGoalWindow::[0]（func_names RTTI 名） |
| 0x141611A90 | NFactions::CCreateFactionAction::GetEnableTrigger func_names 名 NFactions::CCreateFactionAction::GetEnableTrigger |
| 0x141F14A30 | NFactions::NUi::CChangeRuleItemPair::[0] vtable 槽 NFactions::NUi::CChangeRuleItemPair::[0]（func_names RTTI 名） |
| 0x141600760 | NFactions::CCreateFactionAction::[0] vtable 槽 NFactions::CCreateFactionAction::[0]（func_names RTTI 名） |
| 0x140D94100 | NFactions::CFactionSystem::Reader func_names 名 NFactions::CFactionSystem::Reader |
| 0x14146CF90 | NFactions::NUi::CFactionGoalsSection::[0] vtable 槽 NFactions::NUi::CFactionGoalsSection::[0]（func_names RTTI 名） |
| 0x141796FA0 | NFactions::NUi::CFactionTheaterSwitch::[5] vtable 槽 NFactions::NUi::CFactionTheaterSwitch::[5]（func_names RTTI 名） |
| 0x141BAEE00 | NFactions::CModifyFactionTheater::PayloadWriter func_names 名 NFactions::CModifyFactionTheater::PayloadWriter |
| 0x141BADF40 | NFactions::CFactionSetCommanderCommand::PayloadReader func_names 名 NFactions::CFactionSetCommanderCommand::PayloadReader |
| 0x141E2F0A0 | NFactions::NUi::CFactionIconItem::[0] vtable 槽 NFactions::NUi::CFactionIconItem::[0]（func_names RTTI 名） |
| 0x14146D0C0 | NFactions::NUi::CFactionResearchSection::[0] vtable 槽 NFactions::NUi::CFactionResearchSection::[0]（func_names RTTI 名） |
| 0x1416174F0 | NFactions::CCreateFactionAction::[57] vtable 槽 NFactions::CCreateFactionAction::[57]（func_names RTTI 名） |
| 0x1416176C0 | NFactions::CKickFromFactionAction::[57] vtable 槽 NFactions::CKickFromFactionAction::[57]（func_names RTTI 名） |
| 0x141BAD990 | NFactions::CAddFactionProgramCommand::PayloadReader func_names 名 NFactions::CAddFactionProgramCommand::PayloadReader |
| 0x141BAE270 | NFactions::CSetFactionPingExecutionType::PayloadReader func_names 名 NFactions::CSetFactionPingExecutionType::PayloadReader |
| 0x141F149A0 | NFactions::NUi::CChangeRuleItem::[0] vtable 槽 NFactions::NUi::CChangeRuleItem::[0]（func_names RTTI 名） |
| 0x141993960 | NFactions::CFactionProgramStatus::Writer func_names 名 NFactions::CFactionProgramStatus::Writer |
| 0x14146D420 | NFactions::NUi::CInviteToFactionPopup::[0] vtable 槽 NFactions::NUi::CInviteToFactionPopup::[0]（func_names RTTI 名） |
| 0x141BE5FF0 | NFactions::CDoctrineSharingStatus::Writer func_names 名 NFactions::CDoctrineSharingStatus::Writer |
| 0x141BAF0F0 | NFactions::CUpdateIntelligenceAdvisorSlotCommand::PayloadWriter func_names 名 NFactions::CUpdateIntelligenceAdvisorSlotCommand::PayloadWriter |
| 0x141BAE150 | NFactions::CRemoveFactionProgramCommand::PayloadReader func_names 名 NFactions::CRemoveFactionProgramCommand::PayloadReader |
| 0x141BAEF90 | NFactions::CSetFactionPingExecutionType::PayloadWriter func_names 名 NFactions::CSetFactionPingExecutionType::PayloadWriter |
| 0x141BE5E90 | NFactions::CDoctrineSharingStatus::Reader func_names 名 NFactions::CDoctrineSharingStatus::Reader |
| 0x1414717E0 | NFactions::NUi::CAssignResearchFacilityWindow::Reload func_names 名 NFactions::NUi::CAssignResearchFacilityWindow::Reload |
| 0x141BAEA20 | NFactions::CAddFactionGoalCommand::PayloadWriter func_names 名 NFactions::CAddFactionGoalCommand::PayloadWriter |
| 0x141BAE1C0 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadReader func_names 名 NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadReader |
| 0x14160CEF0 | NFactions::CKickFromFactionAction::GetAiAcceptance func_names 名 NFactions::CKickFromFactionAction::GetAiAcceptance |
| 0x141BAE220 | NFactions::CSetFactionIconAndColor::PayloadReader func_names 名 NFactions::CSetFactionIconAndColor::PayloadReader |
| 0x141BADA20 | NFactions::CClearFactionTheater::PayloadReader func_names 名 NFactions::CClearFactionTheater::PayloadReader |
| 0x141BAED40 | NFactions::CFactionSetCommanderCommand::PayloadWriter func_names 名 NFactions::CFactionSetCommanderCommand::PayloadWriter |
| 0x14146D150 | NFactions::NUi::CFactionRulesSection::[0] vtable 槽 NFactions::NUi::CFactionRulesSection::[0]（func_names RTTI 名） |
| 0x141BAE2F0 | NFactions::CSetFactionTheaterPinVisibility::PayloadReader func_names 名 NFactions::CSetFactionTheaterPinVisibility::PayloadReader |
| 0x141BAE9A0 | NFactions::CUseFactionMemberManpower::PayloadReader func_names 名 NFactions::CUseFactionMemberManpower::PayloadReader |
| 0x141BAECE0 | NFactions::CFactionAttachScientistCommand::PayloadWriter func_names 名 NFactions::CFactionAttachScientistCommand::PayloadWriter |
| 0x141616640 | NFactions::CKickFromFactionAction::CanExecute func_names 名 NFactions::CKickFromFactionAction::CanExecute |
| 0x141BAF050 | NFactions::CSetFactionUpgradeCommand::PayloadWriter func_names 名 NFactions::CSetFactionUpgradeCommand::PayloadWriter |
| 0x141BAF0A0 | NFactions::CUnlockFolderDoctrineSharingCommand::PayloadWriter func_names 名 NFactions::CUnlockFolderDoctrineSharingCommand::PayloadWriter |
| 0x141BE6520 | NFactions::CTechnologySharingFaction::Reader func_names 名 NFactions::CTechnologySharingFaction::Reader |
| 0x141BAF000 | NFactions::CSetFactionTheaterPinVisibility::PayloadWriter func_names 名 NFactions::CSetFactionTheaterPinVisibility::PayloadWriter |
| 0x141BAEAE0 | NFactions::CClearFactionTheater::PayloadWriter func_names 名 NFactions::CClearFactionTheater::PayloadWriter |
| 0x141BE6800 | NFactions::CTechnologySharingFaction::Writer func_names 名 NFactions::CTechnologySharingFaction::Writer |
| 0x141BAEF40 | NFactions::CSetFactionIconAndColor::PayloadWriter func_names 名 NFactions::CSetFactionIconAndColor::PayloadWriter |
| 0x141BAEF00 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadWriter func_names 名 NFactions::CRemoveIntelligenceAdvisorFromSlotCommand::PayloadWriter |
| 0x141611A50 | NFactions::CAssumeFactionLeadershipAction::GetCostText func_names 名 NFactions::CAssumeFactionLeadershipAction::GetCostText |
| 0x141950D50 | NFactions::CFactionTheaterManager::Reader func_names 名 NFactions::CFactionTheaterManager::Reader |
| 0x1419935C0 | NFactions::CFactionProgramStatus::Reader func_names 名 NFactions::CFactionProgramStatus::Reader |
| 0x141BAEA90 | NFactions::CAddFactionProgramCommand::PayloadWriter func_names 名 NFactions::CAddFactionProgramCommand::PayloadWriter |
| 0x141995A40 | NFactions::CFactionRuleStatus::Reader func_names 名 NFactions::CFactionRuleStatus::Reader |
| 0x141BAF150 | NFactions::CUseFactionMemberManpower::PayloadWriter func_names 名 NFactions::CUseFactionMemberManpower::PayloadWriter |
| 0x1418249F0 | NFactions::NUi::CFactionSetupWindow::PreSetup func_names 名 NFactions::NUi::CFactionSetupWindow::PreSetup |
| 0x141951C80 | NFactions::CFactionTheaterManager::Writer func_names 名 NFactions::CFactionTheaterManager::Writer |
| 0x14146CB94 | NFactions::NUi::CFactionTheaterPopup::[0] vtable 槽 NFactions::NUi::CFactionTheaterPopup::[0]（func_names RTTI 名） |
| 0x14015BFC0 | NFactions::CFactionGoal::[0] vtable 槽 NFactions::CFactionGoal::[0]（func_names RTTI 名） |
| 0x14146CB34 | NFactions::NUi::CCountryFactionView::[0] vtable 槽 NFactions::NUi::CCountryFactionView::[0]（func_names RTTI 名） |
| 0x141C15180 | NFactions::NUi::CFactionCommanderItem::[1] vtable 槽 NFactions::NUi::CFactionCommanderItem::[1]（func_names RTTI 名） |
| 0x14131D870 | NFactions::CSetFactionPingExecutionType::GetTypeId func_names 名 NFactions::CSetFactionPingExecutionType::GetTypeId |
| 0x14131D880 | NFactions::CUseFactionMemberManpower::GetTypeId func_names 名 NFactions::CUseFactionMemberManpower::GetTypeId |
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
| 0x141611B10 | NFactions::CCreateFactionAction::[43] vtable 槽 NFactions::CCreateFactionAction::[43]（func_names RTTI 名） |
| 0x140D935E0 | NFactions::VCFactionMemberStatus::U?$SDefaultSetSize::NPdx::NIm鈥�::[3] func_names 名 NFactions::VCFactionMemberStatus::U?$SDefaultSetSize::NPdx::NIm鈥�::[3] |
| 0x141BADA70 | NFactions::CCreateFactionTheater::PayloadReader NFactions::CCreateFactionTheater |
| 0x140D8FCF0 | NFactions::CFaction::Writer NFactions::CFaction::Writer（阵营对象存档序列化） |
| 0x1413FB750 | NFactions::CFactionUpgradeStatus::Reader |
| 0x141BAE7B0 | NFactions::CUpdateIntelligenceAdvisorSlotCommand::PayloadReader 序列化 Reader/Writer 或网络命令载荷读写（NFactions::CUpdateIntelligenceAdvisorSlotCommand::PayloadReader） |
| 0x141827B00 | NFactions::NUi::CFactionSetupWindow::[9] |
| 0x141C02910 | NFactions::NUi::CDismantleFactionConfirmationWindow::[14] NFactions::NUi::CDismantleFactionConfirmationWindow 解散派系确认窗槽[14] |
| 0x141C01850 | NFactions::NUi::CKickFromFactionPopup::[16] / "DIPLOMACY_KICK_FROM_FACTION_POPUP_DESC" "DIPLOMACY_KICK_FROM_FACTION_POPUP_DESC" + COUNTRY/FACTION §4.31 GUI/窗… |
| 0x141E2FA90 | NFactions::NUi::CFactionIconWindow::[6] NFactions::NUi::CFactionIconWindow::[6] + gamestate（阵营图标窗口） |
| 0x141C1CC20 | NFactions::NUi::CAssignResearchFacilityWindow::[7] / NFactions::NUi::CAssignResearchFacilityW NFactions::NUi::CAssignResearchFacilityWindow 槽 7 §4.31 GUI/窗口/列表 |
| 0x141ADBBA0 | NFactions::NUi::CInviteCountryItem::[0] / NFactions::NUi::CInviteCountryItem 槽 0 NFactions::NUi::CInviteCountryItem 槽 0 §4.31 GUI/窗口/列表 |
| 0x141F13A50 | NFactions::NUi::CFilterGoalItem::[0] 名:NFactions::NUi::CFilterGoalItem::[0] |
| 0x141471090 | NFactions::NUi::CIntelligenceTabSection::[0] 名:NFactions::NUi::CIntelligenceTabSection::[0] |
| 0x141602300 | NFactions::CJoinFactionAction::[24] 业务类 CJoinFactionActionNFactions（类名/调用链证据） |
| 0x14179BF90 | NFactions::NUi::CFactionTheaterWindow::[4] 业务类 CFactionTheaterWindow（类名/调用链证据） |

#### 4.5.22 阵营系统函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141BF7CE0 | 业务 阵营指挥官窗口构造（std::function 回调安装） CLS NFactions::NUi::CFactionCommanderWindow + CButtonObserverGlue（vtable 名内） |
| 0x1401559D0 | 业务 反调用图传播 1.5 权重锚点投 §4.5（top 占比 0.56） |
| 0x14118B760 | 业务 反向调用图 2/3 调用者投 §4.5; 唯一被调用者在书内 §4.1 |
| 0x141827740 | NFactions::NUi::CFactionSetupWindow::Setup 业务 阵营设置窗口 Setup：sub_141825690(this) + sub_141237840(this)；类无 RTTI，取 func_names 槽契约名 |

#### 4.5.23 常量串 getter 结构定案（75 函）

| VA | 语义/证据 |
|---|---|
| 0x14073FC40 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_LAND_SUPPLY_USAGE_MODIFIER_SKILL_FACTOR"（高置信） |
| 0x14073FC60 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_NAVY_SUPPLY_USAGE_MODIFIER_SKILL_FACTOR"（高置信） |
| 0x14073FC30 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_LAND_SUPPLY_USAGE_MODIFIER_BASE"（高置信） |
| 0x14073FC50 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_NAVY_SUPPLY_USAGE_MODIFIER_BASE"（高置信） |
| 0x14073FB30 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_HEAD_OF_COUNTER_INTEL_BONUS_COUNTRY"（高置信） |
| 0x14073FB40 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_HEAD_OF_COUNTER_INTEL_BONUS_OTHERS"（高置信） |
| 0x14073FA80 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_EXPEDITIONARY_FORCE_PROVIDER_FACTOR"（高置信） |
| 0x14073FA90 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_EXPEDITIONARY_FORCE_RECIEVER_FACTOR"（高置信） |
| 0x14073FB50 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_HEAD_OF_CRYPTOLOGY_BONUS_COUNTRY"（高置信） |
| 0x14073FB70 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_HEAD_OF_OPERATIONS_BONUS_COUNTRY"（高置信） |
| 0x14073FB60 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_HEAD_OF_CRYPTOLOGY_BONUS_OTHERS"（高置信） |
| 0x14073FB80 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_HEAD_OF_OPERATIONS_BONUS_OTHERS"（高置信） |
| 0x14073FC20 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_COUNTRY_LIMIT_SKILL_FACTOR"（高置信） |
| 0x14073FA10 | 常量串 getter: 返回常量串 "NFactions::DOCTRINE_SHARING_MONTHLY_MASTERY_GAIN_PER_COMMANDER"（高置信） |
| 0x14073FC00 | 常量串 getter: 返回常量串 "NFactions::FACTION_TAKE_OVER_RELUCTANCE_VERSUS_HUMAN_INFLUENCE"（高置信） |
| 0x14073FC80 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_REGION_LIMIT_SKILL_FACTOR"（高置信） |
| 0x14073FAA0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_GARRISON_SUPPORT_PROVIDER_FACTOR"（高置信） |
| 0x14073FAB0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_GARRISON_SUPPORT_RECIEVER_FACTOR"（高置信） |
| 0x14073F8F0 | 常量串 getter: 返回常量串 "NFactions::AI_FACTION_THEATER_COMMANDER_SELECTION_RANDOMNESS"（高置信） |
| 0x14073F900 | 常量串 getter: 返回常量串 "NFactions::AI_FACTION_THEATER_TEMPLATE_SELECTION_RANDOMNESS"（高置信） |
| 0x14073FAF0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_SCIENTIST_CONTRIBUTION_VALUE"（高置信） |
| 0x14073F950 | 常量串 getter: 返回常量串 "NFactions::AI_PING_FORCE_CONCENTRATION_AGGRESSIVE_FACTOR"（高置信） |
| 0x14073FAC0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_INDUSTRIAL_CAPACITY_FACTOR"（高置信） |
| 0x14073FBD0 | 常量串 getter: 返回常量串 "NFactions::FACTION_MANPOWER_RECIEVE_CONTRIBUTION_SCALAR"（高置信） |
| 0x14073FC10 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_COUNTRY_LIMIT_BASE"（高置信） |
| 0x14073FC70 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_REGION_LIMIT_BASE"（高置信） |
| 0x14073F960 | 常量串 getter: 返回常量串 "NFactions::AI_PING_FORCE_CONCENTRATION_CAREFUL_FACTOR"（高置信） |
| 0x14073F9D0 | 常量串 getter: 返回常量串 "NFactions::ASSIGN_FACILITY_TO_FACTION_INITIATIVE_COST"（高置信） |
| 0x14073FA00 | 常量串 getter: 返回常量串 "NFactions::DOCTRINE_SHARING_BASE_MASTERY_GAIN_MONTHLY"（高置信） |
| 0x14073FB20 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_ALLOWED_ADVISOR_TRAIT"（高置信） |
| 0x14073FBA0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_SHARING_SPY_SLOT_GAIN"（高置信） |
| 0x14073F980 | 常量串 getter: 返回常量串 "NFactions::AI_PING_FORCE_CONCENTRATION_TARGET_WEIGHT"（高置信） |
| 0x14073F9E0 | 常量串 getter: 返回常量串 "NFactions::BECOME_FACTION_LEADER_INFLUENCE_THRESHOLD"（高置信） |
| 0x14073FBC0 | 常量串 getter: 返回常量串 "NFactions::FACTION_MANPOWER_GIVE_CONTRIBUTION_SCALAR"（高置信） |
| 0x14073FC90 | 常量串 getter: 返回常量串 "NFactions::FACTION_THEATER_COMMANDER_SECONDARY_BONUS"（高置信） |
| 0x14073F970 | 常量串 getter: 返回常量串 "NFactions::AI_PING_FORCE_CONCENTRATION_FRONT_FACTOR"（高置信） |
| 0x14073FBF0 | 常量串 getter: 返回常量串 "NFactions::FACTION_SUPREME_COMMANDER_EFFECTIVENESS"（高置信） |
| 0x14073FD50 | 常量串 getter: 返回常量串 "NFactions::THEATER_COMMANDER_LAND_EXPERIENCE_SCALE"（高置信） |
| 0x14073FD60 | 常量串 getter: 返回常量串 "NFactions::THEATER_COMMANDER_NAVY_EXPERIENCE_SCALE"（高置信） |
| 0x14073F9F0 | 常量串 getter: 返回常量串 "NFactions::BECOME_FACTION_LEADER_INFLUENCE_WEIGHT"（高置信） |
| 0x14073FD40 | 常量串 getter: 返回常量串 "NFactions::REPLACING_UNFINISHED_FACTION_GOAL_COST"（高置信） |
| 0x14073F8D0 | 常量串 getter: 返回常量串 "NFactions::AI_FACTION_POWER_PROJECTION_TRESHOLD"（高置信） |
| 0x14073FA60 | 常量串 getter: 返回常量串 "NFactions::FACTION_DOCTRINE_SHARING_UNLOCK_COST"（高置信） |
| 0x14073FD20 | 常量串 getter: 返回常量串 "NFactions::PEACE_CONFERENCE_MINIMAL_REQUIREMENT"（高置信） |
| 0x14073FAE0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_LEND_LEASE_FACTOR"（高置信） |
| 0x14073FB10 | 常量串 getter: 返回常量串 "NFactions::FACTION_INITIATIVE_CHANGE_RULE_COST"（高置信） |
| 0x14073FB00 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_WAR_SCORE_FACTOR"（高置信） |
| 0x14073FB90 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_SHARING_BONUS"（高置信） |
| 0x14073F8E0 | 常量串 getter: 返回常量串 "NFactions::AI_FACTION_POWER_PROJECTION_VALUE"（高置信） |
| 0x14073FA70 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_EFFECTS_FACTOR"（高置信） |
| 0x14073FBB0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INTELLIGENCE_UNLOCK_COST"（高置信） |
| 0x14073FA30 | 常量串 getter: 返回常量串 "NFactions::FACTION_CONTRIBUTION_DEBT_LIMIT"（高置信） |
| 0x14073FAD0 | 常量串 getter: 返回常量串 "NFactions::FACTION_INFLUENCE_LEADER_BONUS"（高置信） |
| 0x14073FBE0 | 常量串 getter: 返回常量串 "NFactions::FACTION_REPLACE_COMMANDER_COST"（高置信） |
| 0x14073F910 | 常量串 getter: 返回常量串 "NFactions::AI_MAX_POWER_PROJECTION_SCORE"（高置信） |
| 0x14073F920 | 常量串 getter: 返回常量串 "NFactions::AI_MIN_POWER_PROJECTION_SCORE"（高置信） |
| 0x14073F9A0 | 常量串 getter: 返回常量串 "NFactions::AI_PING_INVASION_UNIT_REQUEST"（高置信） |
| 0x14073FA20 | 常量串 getter: 返回常量串 "NFactions::FACTION_ASSIGN_SCIENTIST_COST"（高置信） |
| 0x14073FCA0 | 常量串 getter: 返回常量串 "NFactions::FACTION_UNLOCK_COMMANDER_COST"（高置信） |
| 0x14073FD00 | 常量串 getter: 返回常量串 "NFactions::PASSIVE_INITIATIVE_GENERATION"（高置信） |
| 0x14073FD10 | 常量串 getter: 返回常量串 "NFactions::PEACE_CONFERENCE_MAX_DISCOUNT"（高置信） |
| 0x14073F9C0 | 常量串 getter: 返回常量串 "NFactions::AI_THEATER_CREATION_PENALTY"（高置信） |
| 0x14073F990 | 常量串 getter: 返回常量串 "NFactions::AI_PING_FRONT_UNIT_REQUEST"（高置信） |
| 0x14073FCD0 | 常量串 getter: 返回常量串 "NFactions::MAX_NUM_MEDIUM_TERM_GOALS"（高置信） |
| 0x14073FA50 | 常量串 getter: 返回常量串 "NFactions::FACTION_DEFAULT_TEMPLATE"（高置信） |
| 0x14073FCE0 | 常量串 getter: 返回常量串 "NFactions::MAX_NUM_SHORT_TERM_GOALS"（高置信） |
| 0x14073F930 | 常量串 getter: 返回常量串 "NFactions::AI_PICK_FROM_TOP_AMOUNT"（高置信） |
| 0x14073F9B0 | 常量串 getter: 返回常量串 "NFactions::AI_PING_NAVAL_DOMINANCE"（高置信） |
| 0x14073FCC0 | 常量串 getter: 返回常量串 "NFactions::MAX_NUM_LONG_TERM_GOALS"（高置信） |
| 0x14073F8C0 | 常量串 getter: 返回常量串 "NFactions::AI_DAYS_TO_SELECT_GOAL"（高置信） |
| 0x14073F940 | 常量串 getter: 返回常量串 "NFactions::AI_PING_AREA_PRIORITY"（高置信） |
| 0x14073FA40 | 常量串 getter: 返回常量串 "NFactions::FACTION_DEFAULT_ICON"（高置信） |
| 0x14073FCB0 | 常量串 getter: 返回常量串 "NFactions::MAX_FACTION_THEATERS"（高置信） |
| 0x14073FD30 | 常量串 getter: 返回常量串 "NFactions::RANK_FOR_SHINY_FLAG"（高置信） |
| 0x14073FCF0 | 常量串 getter: 返回常量串 "NFactions::MAX_PROJECT_COUNT"（高置信） |

#### 4.5.24 单调用转发桩结构定案（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140D90310 | 转发桩: 转发至 无名领域函数 sub_140D866B0 被调用者定名: CFaction::UpdatePower? 等命中 §4.5（占 100%，共 2 callee）（推定） |
| 0x1425A13B0 | 转发桩: 转发至 业务 串 "GFX_upgrade_frame_1"; 串 "click_default"; 调用图 IDF top §4.1 frac 1.00（推定） |
| 0x14258F890 | 转发桩: 转发至 业务 串 "GFX_upgrade_frame_1"; 串 "click_default"; 调用图 IDF top §4.1 frac 1.00（推定） |
| 0x1425F0520 | 转发桩: 转发至 业务 断言站点 achievements_mod_storage.cpp:48 ->§4.5; 类路由 CSavedAchievementMod ->§4.28; 串 "Cloud save file for mod achievement "（推定） |
| 0x14179EE00 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 串字面量 "FACTION_THEATER_DEFAULT_NAME"（推定） |

#### 4.5.25 阵营系统函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141019670 | 串 invalid dlc name:；调 CDiplomaticAction::GetFirstCountryRef[slot] + sub_1401AE230/1424C1EF0（数据库读取） |
| 0x1406E9490 | 邻域传播改判（锚 0x1406EFBF0 §4.5，距离 0x6760）；跳点串 "!_RailwayGuns.Contains( &RailwayGun ) && \"Adding RailwayGun unit to country " / "which already owns it\"" |
| 0x141A24150 | 串 "FACTION_UPGRADE_INTELLIGENCE_NAME_BONUS" |
| 0x141A418A0 | 串 "FACTION_GOAL_AVAILABLE" |

#### 4.5.26 阵营系统函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x14118FA30 | 业务 邻域 faction_member_status.cpp x5/SPersist::Write/ideology.cpp Reader + qword_14332F698+1264→+384 全局链 + off_143085170 x23 可变参 + a1+1784/1648 标志 + a1+144..19… |
| 0x141ADBED0 | NFactions::NUi::CKickFromFactionCountryItem::[0] 业务 CKickFromFactionCountryItem 构造（vtable slot0） |
| 0x141C19930 | NFactions::NUi::CFactionProgramItemEmpty::[0] 业务 游戏类 vtable 槽（NFactions::NUi::CFactionProgramItemEmpty） |
| 0x1410FEF60 | 断言 ref.h:83；调用者 CLendLeaseAction::[47]；调 CIcon::[70]、CLendLeaseAction::[47]、DNameStatusNode::[0] |
| 0x142259800 | memcpy；调 CDiplomaticAction::GetFirstCountryRef[slot] + 0x14015 段构造簇 + sub_1424C1540/0AA0（解析原语） |
| 0x140A2F3C0 | CU 同类簇: 邻接 140A2E630（NFactions::CFactionRuleGroupDatabase::[2）/ 140A2F980（NFactions::CFactionTemplateDatabase::[2]） |
| 0x141994060 | CU 同类簇: 邻接 141993960（NFactions::CFactionProgramStatus::Writer）/ 141994760（NFactions::CFactionRuleStatus::[0]） |
