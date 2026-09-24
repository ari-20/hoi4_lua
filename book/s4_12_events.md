

### 4.12 事件与决议域 (事件 option / 决策状态与冷却 / 定时活动与定时条目)

> **定位**: 事件 (option 定义体) 与决议/决策全链 —— CEventOption、CDecisionStatus
> 状态聚合、冷却记录、定时·定向决策实例、定时活动族与定时条目族。
> 决议 GUI (DecisionView 族) 见 §4.30.12; 决议命令族 (CSelect/Ignore) 见其命令表;
> 事件 effect (country_event/news_event 族) 见 §4.32.11。
> 国家侧挂载点 (cc+4000 ds) 见 §4.3 (批5 后为 §4.3.10)。

#### 4.12.1 CEventOption (事件 option 定义体, 504B; vt 0x142999B48)

不入档 (writer = CFG 空桩; reader 0x141539CE0 = 事件文件脚本解析; ctor 0x14117F370)。宿主 = CEvent+280 内嵌一份 (至 +784), 另 CEvent+872 = option 指针向量 (Parse 逐块 new+push, +884 序号)。

| 偏移 | 类型 | 语义 (键 token) |
|---|---|---|
| +8 | u32 | 宿主 event id token (作子对象 parse 的 scope token) |
| +16 | CAIMTTHChance 内嵌 272B | ai_chance (10599, 子 vt[3] 读) |
| +288 | CEffect 内嵌 88B | option 效果体 (匿名效果 token 全走 default → 子 vt[4]) |
| +376 | std::string 32B | name (27) |
| +408 | CAndTrigger 内嵌 92B | trigger (10595, 子 vt[5] 带宿主 token; +32 = 10600) |
| +496 | u32 | option 序号 (内嵌默认 -1) |
| +500 | u8 | original_recipient_only (11705) |
| +501 | u8 | 11705 已给旗 |

#### 4.12.2 决策状态族 (CDecisionStatus / 冷却 / 定时·定向决策)

**CDecisionStatus** (国家决策状态聚合, 456B; CPersistent@0, vt 0x1427EB5C0; writer 0x140738AA0 / reader 0x140733A20 / ctor 0x140723C70; 挂 cc+4000, 见 §4.3)。内部容器统一 24B 元 {data@0, cap@8, count@12, alloc@16}:

| 偏移 | 容器/语义 (存档键) | 备注 |
|---|---|---|
| +8 | owner (CCountry*) | ctor 入参直存 |
| +16 | 运行时容器 | 不序列化 |
| +64 | **decisions_taken** (14343) | 决策名串列表 (writer 逐元写 *(dec+288) 名) |
| +88 | **decision_to_re_enable** (14542) | CDecisionCooldown* |
| +112 | **decision_to_remove** (14543) | CDecisionCooldown* |
| +136 | 运行时容器 | 不序列化 |
| +160 | **active_timed_decision** (14347) | CTimedDecision* (书 §4.3 "d@160 c@172" 即此) |
| +184 | 运行时容器 | 不序列化 |
| +208 | 运行时容器 | 不序列化 |
| +232 | **active_targeted_decision** (14422) | CTargetedDecision* |
| +256 | **active_targeted_timed_decision** (14814) | CTargetedDecision* |
| +280 | 运行时容器 | 不序列化 |
| +304 | 运行时容器 | 不序列化 |
| +328 | **random_item** (14734) | 24B 记录元 |
| +352 | 运行时容器 | 不序列化 |
| +376 | 运行时容器 | 不序列化 |
| +400 | 运行时容器 | 不序列化 |
| +424 | 运行时容器 | 不序列化 |
| +448 | u16 ctor=1 | **决策脏/待更新旗** (+448 u8; +449 = 独立第二旗)。ctor sub_140723C70 写 `*(WORD*)(a1+448)=1` (= +448 置 1 / +449 置 0); 多处更新点写 `*(BYTE*)(a1+448)=1`; 消费/清除点 = `sub_1407378E0(ds, flag)`: `if (*(BYTE*)(ds+448) || flag) {…重算…}; *(BYTE*)(ds+448)=0`; ds 取得链 = sub_1406CF4D0 单行 `return *(QWORD*)(a1+4000)` (+449 语义未决) |

**CDecisionCooldown** (冷却记录, 24B; vt 0x1427EB450; writer 0x140738A50 / reader 0x1407337F0): +8 CDecision* (写名 = *(dec+288); 读按名走决策库 RH 反查 sub_140722CC0 + 280 有效门) / +16 i32 days (10605)。垃圾键抛 "Unexpected token when reading decision on cooldown"。

**CTimedDecision** (定时决策实例, 32B; IDecision@0 + CPersistent@8 双基, 主 vt 0x1427EB4A0 / 次 0x1427EB4B8; writer 0x140738E20 / reader 0x1407349C0): +16 CDecision* decision (11142 名串) / +24 u32 days (10605) / **+28 u32 state (439 块)**。

state 枚举 (CTimedDecision): 0 active (11390) / 1 completed (12583) / 2 failed (14349) / 3 aborted (14811) / 4 re_enable_cooldown (14816); 非法值抛 "Unknown state for timed decision"。

**CTargetedDecision** (定向决策实例, 96B; 同双基, 主 vt 0x1427EB508 / 次 0x1427EB520; writer 0x140738D50 / reader 0x1407346A0): +16 decision (11142) / +24 STargetedDecisionTarget 内嵌 target (107, 通用递归读; **布局定案 = 16B, 仅 8B idpair {tag_id u32@+8, idx u32@+12}**: vt 0x142765CF8, writer sub_140738A10 (tag>0 发引号 tag 名, 否则发 idx 数字) / reader sub_140732670) / +32 u32 state (**反序列化落点**, reader sub_1407346A0 直接写 0..4) / +40 u32 state (439, **存档发射源**, writer sub_140738D50 读) / +36 u8 ignore (**reader 的 11736 分支写此槽**, 非 +44) / +48 u32 days (10605) / +56 32B 运行时串 / +88 i32 ctor=-1 运行时。

state 枚举 (CTargetedDecision): 0 available (12264) / 1 completed (12583) / 2 re_enable_cooldown (14816) / 3 failed (14349) / 4 aborted (14811)。

#### 4.12.3 决议 (cc+4000) 与状态枚举

ds = *(cc+4000)。

decisions 状态枚举 (writer 0X140738D50 switch; 定案):

| 值 | 名称 |
|---|---|
| 2 | re_enable_cooldown |
| 3 | failed |
| 4 | aborted |

ds 容器总表:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| ds+16 | 容器 24B | 可用决议表 (pass A 源) | 元素 = 可用 decision def/条目; UI 消费定案 |
| ds+64 | 容器 {c@ds+76} | taken | 决议行状态机五态码 sub_141723540 (0=隐 / 1=成本足 / 2=成本未足 / 3=采纳 / 4=采纳+冷却) |
| ds+88 | 容器 {c@ds+100} | to_re_enable | 采纳判定消费 |
| ds+160 | CTimedDecision* 向量 | active_timed 源 | → CDecisionViewTimedDecisionItem (entry@+2736) |
| ds+232 | 容器 {c@ds+244 推定} | active_targeted 源 | → CDecisionViewTargetedDecisionItem (entry@+4024) |
| ds+256 | 匿名结构 (元素待裁) 向量 | att_timed 源 | 同上 |
| ds+304 | 容器 24B {c@ds+316} | 类别态表 | 类别可见门 +568 ∧ available ∧ should_show ∧ power-balance (+976/+992, 经 gs+1104); 类别行分组键 = *(def+368) = CDecisionCategory* |
| cc+5360 | 名集合 (定案) | ignored 决议名集合 = player_settings (存档 token 14423) 内 ignored 集 | 写侧: CIgnoreDecisionCommand::Execute 0X141157240 (byte+72=1 插入 / =0 删除); CIgnoreAllAvailableDecisionCommand::Execute 0X141156FD0 全量插入 |

决议命令族 (CSelect/Ignore 四枚, id 经 vt[11] GetId 实证): 载荷布局与
GUI 绑定全表见 §4.33 (id 14345 / 14383 / 14768 / 14769)。

注: CategoryItem cb sub_141D74190 = 折叠切换 (win+1680 表), 非命令。

决议 def 侧锚:

| 偏移 | 名称/语义 |
|---|---|
| +288 | 名 (行名/图标; ignored 集 cc+5360 名键查询 → 状态元 1/2) |
| +368 | CDecisionCategory* (定案; 类别对象 1016B = 0x3F8: 双 vt 0x1427eb330/0x1427eb380, ctor 0X140723750, 装载器 sub_140726190 "Duplicate category" 断言, key 派发器 0X1407332B0 全 key 落名 available/allowed/visible/icon/picture/priority/scripted_gui/custom_icon/on_map_area/visibility_type/highlight_states; def ctor 初值 = TNullObject 单例 qword_143330DD8) |
| +376 | 可用门 |
| +396 | 可用门 |
| +1600 | 成本 |
| +1620 | 成本 |
| +2444 | 目标上下文分支 |
| +2528 | 目标上下文分支 |
| +2816 | 行按钮门 (byte) |
| +2817 | 行按钮门 (byte) |
| +3296 | on_map_mode 枚举 (key 15414; 定案): 0=map_only / 1=decision_view_only / 2=map_and_decisions_view (默认 2; Finalize 0X140730250 无目标字段时压 1); 行门 {1,2} = 决议视图可见, {0,2} = 地图呈现门 |

targeted / timed entry:

| entry | 偏移 | 名称/语义 |
|---|---|---|
| targeted | +32 | target_tag |
| targeted | +36 | state |
| targeted | +40 | state |
| targeted | +44 | ignore |
| timed | +24 | 日数 |
| timed | +28 | 门: state ∉ {3,4} |

类别对象 (= *(def+368)):

| 偏移 | 名称/语义 |
|---|---|
| +464 | scripted_gui 名串本体 (MSVC SSO: 缓冲@+464 / **size@+480** / cap@+488); ReadKey case 14961 写 +464; 门 = size ≠0 → EventCategoryHeader / =0 → InfoItem (定案) |
| +544 | SOnMapLocator vector (304B 元素, key 15048 on_map_area; pass F 逐 locator 求 CScriptTargets 命中 → OnMapLocatorItem) |
| +544 | SOnMapLocator vector 尾 (304B 元素, 见 §4.30.12) |
| +568 | 可见门 |
| +976 | power-balance 类别名副本串 (缓冲@+976 / **size@+992** / cap@+1000); +1008 = 类别值 i32 (默认 −1) |

#### 4.12.4 定时活动族 (CBaseTimedActivity 系 + 活动库)

**CBaseTimedActivity** (抽象基, 104B; vt 0x142944A10 19 槽含 5 _purecall; writer 0x140ADCC60 / reader 0x140ADC130): +8 u32 类 token (CPersistentWithToken, 例 timed_wargoal=13319) / +16 owner (10302) / +20 target (107) / +24 i64 total_cost (13317, >0 写) / +32 i64 daily_cost (13318, >0 写) / +40 i64 points (12766, >0 写) / +48 CGameDate start_date (10464) / +72 CGameDate end_date (10465) / +96 u8 pay_upfront (13899)。派生各自的 writer 继承调用; 效果类 ctor 直证 start_date.hours = *(gs+1128) 当前日期。

| 派生 (载体 = 存档 timed 块) | vt/writer | 追加字段 |
|---|---|---|
| CTimedEffectActivity | vt 0x142944B50; writer 0x140ADCDC0 (dump 缺件, 推定 = 调基 writer, reader 0x140ADC430 零自有键互证) | 无自有存档键 |
| CTimedWargoalActivity | ctor 0x140AD7390 | (timed_wargoal=13319) |
| CDemilitarizedZoneTimedEffect (demilitarized_zone=12531) | vt 0x1429DC140; writer 0x1415A8E90 / reader 0x1415A8BB0 | **+104 州 id 容器** (states=11835; ctor 自 a5 州 id 数组拷贝) |
| CWarReparationTimedEffect (war_reparation=12532) | vt 0x1429DC1E0; writer 0x1415A8ED0 / reader 0x1415A8BD0 | **+104 u32 civilian_factories (19421) / +108 u32 num_of_civilian_factories_available_for_projects (14729)** |
| CResourceRightsTimedEffect (resource_rights=12533) | vt 0x1429DC280; writer/reader 与 demilitarized 同 (12531/12533 双 token 复用同 writer) | **+104 州 id 容器** (states=11835; 买权州清单) |
| CTimedStageCoupActivity | writer 0x140ADCDD0 | +104 location(10349)/+112 equipment(12110)/+144 ideology(11838) |
| 专项活动 (civilian) | writer 0x1415A8ED0 / 0x1415A8E90 | civilian_factories(19421)@+104 / num_of_civilian_factories_available_for_projects(14729)@+108 / states(11835)@+104 |

**CTimedActivityDatabase** (活动类型库, 72B; TGameItemDatabase 单基, vt 0x142944D48; ctor 0x140AD6F00; **idb timed_activity 已挂** 0x332F0B8): +40 CEquipmentArcheTypePool vt 复用名 / +48 条目数组 (idb arr) / +56 cap / +60 count (idb cnt); 条目 = 16B 内联元。

**CTimedActivityEquipmentDistributable** (设备分发活动, ≈136B; CEquipmentDistributable@0 + CPersistent@24 多基, 主 vt 0x142944BF0 / 次 0x142944C28; writer 0x140ADCD50 / reader 0x140ADC3A0): 基 = priority@+8 (141, ≠1 写) / +32 produced 池 (12204, 非空写) / +64 运行时池 / +96 need 池 (12111)。

#### 4.12.5 定时条目与理念/国策 def 周边

**CTimedIdea** (定时理念条, 24B; vt 0x14294FD58; writer 0x140BB07D0 / reader 0x140BAE240): +8 CIdea* idea (10491, 写名 = *(idea+64)) / +16 u32 days (10605)。挂 ps+104 timed_ideas (§4.10)。

**CTimedModifier** (定时修饰条, 48B; vt 0x1427D61C8; writer 0x140612730 / reader 0x140610770 / ctor 0x140556560): +8 CModifier* modifier (10597, 写名 = *(mod+424)) / +16 CGameDate date (10314) / +40 u8 ruler_modifier (11487) / +41 u8 permanent (11017) / +42 u8 hidden (11404)。

**CIdeaResearchBonus** (idea def 侧 research_bonus trait, 72B; CPersistentWithToken@0 + THashedKeyValueTrait@16 多基, vt 0x142981590; Load wrapper 0x140FD4B40): +8 类 token (拷自 owner idea) / +16 32B trait key (+48 FNV-1a u32, Load 现算) / +56 CFixedPoint value / +64 CIdea* owner。writer = CFG 桩 = 不落盘 (def 侧重载重建; 工厂嵌 CIdea loader 0x140FD4C70, 容器 = CIdea+2672)。

**CNationalFocusDependency** (国策依赖条, 72B; vt 0x142739AC8; reader 0x1402D8690 / ctor 0x1402CB990): +8 32B 备用枚举串 / +32 32B 依赖名 (键 10601 `or` / 13239 `focus` 均写入)。writer = CFG 桩 (focus def 静态成分, 不落盘)。

**CNationalFocusStyleDatabase** (focus style 双 RH 名表; vt 0x142739A78; 非 TGameItemDatabase): 实体 = 内嵌 **CNationalFocusDatabase+48 起 160B** {+48 vt, +56 i32=-1, 双 RH map (0x1430868C0 / 0x143086920, load factor 0.90)}; 不与 idb 规格相合, 不可挂 resource.lua key。

#### 4.12.6 CSavedEventTarget (112B, saved_event_target)

内联向量 {data@gs+1728, count@gs+1740}; 元素 112B = CSavedEventTarget;
writer 0X14053C090; eventscope.cpp 断言 "CSavedEventTarget cannot persist
CCombatant" (:0x58E); +106..+111 = 112B 对齐尾 pad。⚠ 该 writer/reader 指纹的 RTTI
持有者实为 **CNullSavedEventTarget** (vt 0x1427D4438, TNullObject 变体) — 空对象承担
整组读写。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CSavedEventTarget | 不序列化 | |
| +8 | uint32 | state | ≠0 | |
| +12 | uint32 | country 国 idx | >0 | → 引号 |
| +16 | uint32 | character id 对.type | 双非零 (对) | id@+20 |
| +20 | uint32 | character id 对.id | 双非零 (对) | |
| +24 | uint32 | operation id 对.type | 双非零 (对) | id@+28 |
| +28 | uint32 | operation id 对.id | 双非零 (对) | |
| +32 | CStrategicRegion* | strategic_region | ptr≠0 | = *(obj)+88 |
| +40 | CCombatant* | combatant | 引擎断言永不持久化 | 指针 (+40..+47) |
| +48 | uint32 | ace id 对.type | 双非零 (对) | id@+52 |
| +52 | uint32 | ace id 对.id | 双非零 (对) | |
| +56 | uint32 | unit id 对.type | 双非零 (对) | id@+60 |
| +60 | uint32 | unit id 对.id | 双非零 (对) | |
| +64 | uint32 | industrial_organisation id 对.type | 双非零 (对) | id@+68 |
| +68 | uint32 | industrial_organisation id 对.id | 双非零 (对) | |
| +72 | uint32 | purchase_contract id 对.type | 双非零 (对) | id@+76 |
| +76 | uint32 | purchase_contract id 对.id | 双非零 (对) | |
| +80 | uint32 | raid_instance id 对.type | 双非零 (对) | id@+84 |
| +84 | uint32 | raid_instance id 对.id | 双非零 (对) | |
| +88 | uint32 | project id 对.type | 双非零 (对) | id@+92 |
| +92 | uint32 | project id 对.id | 双非零 (对) | |
| +96 | uint32 | faction id 对.type | 双非零 (对) | id@+100 |
| +100 | uint32 | faction id 对.id | 双非零 (对) | |
| +104 | uint16 | name 索引 | 0 = 无 name | 串表 = rp(BASE+53626272), 条目 32B MSVC 引号 |
| +106..+111 | — | 对齐尾 pad | 不序列化 | |

⚠ qword_14333D530 是指针全局, 须先解引用再用。

#### 4.12.7 fired_event_names

桶数 = ru32(gs+1340), 桶头数组 = *(gs+1344) (8B/桶); 写序 = 桶升序 + 链序。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | 匿名结构 (NNB 形状) | key | | 事件名宿主 (串/token 双态) |
| +8 | 节点* | next | | next 链 |

名解析决策表 (形态|判别|读法):

| 形态 | 判别 | 读法 |
|---|---|---|
| 串 | qword@key+48 ≠ 0 | 双候选: @key+48 值 ≤4096 → 视为 MSVC 串对象 (@key+32: buf@+32/size@+48/cap@+56) 的 size, 按 SSO 读; 大值且 kptr → 视为裸 C 串指针, read_cstr; 皆失败回退 token 形态 |
| token | qword@key+48 = 0 | token@key+12 → 运行时 lexer 表 |
