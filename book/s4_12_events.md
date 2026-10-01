

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
| +448 | u16 ctor=1 | **决策脏/待更新旗** (+448 u8; +449 = 独立第二旗)。ctor sub_140723C70 写 `*(WORD*)(a1+448)=1` (= +448 置 1 / +449 置 0); 多处更新点写 `*(BYTE*)(a1+448)=1`; 消费/清除点 = `sub_1407378E0(ds, flag)`: `if (*(BYTE*)(ds+448) || flag) {…重算…}; *(BYTE*)(ds+448)=0`; **+449 = decision_to_remove 处理重入锁字节 (定案)**: sub_140737480 入口 `if(!*(ds+449)){*(ds+449)=1;…处理 ds+112 到期/移除…; *(ds+449)=0;}` 防 remove 效果级联重入, 稳态恒 0; ds 取得链 = sub_1406CF4D0 单行 `return *(QWORD*)(a1+4000)` |

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
| 0 | active |
| 1 | completed |
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
| ds+256 | 匿名结构 (元素待裁) 向量 | att_timed 源 | 元素 = CTargetedDecision* (§4.12.2 ds+256 行定案) |
| ds+304 | 容器 24B {c@ds+316} | 类别态表 | 类别可见门 +568 ∧ available ∧ should_show ∧ power-balance (+976/+992, 经 gs+1104); 类别行分组键 = *(def+368) = CDecisionCategory* |
| cc+5360 | 名集合 (定案) | ignored 决议名集合 = player_settings (存档 token 14423) 内 ignored 集 | 写侧: CIgnoreDecisionCommand::Execute 0X141157240 (byte+72=1 插入 / =0 删除); CIgnoreAllAvailableDecisionCommand::Execute 0X141156FD0 全量插入 |

决议命令族 (CSelect/Ignore 四枚, id 经 vt[11] GetId 实证): 载荷布局与
GUI 绑定全表见 §4.33 (id 14345 / 14383 / 14768 / 14769)。

注: CategoryItem cb sub_141D74190 = 折叠切换 (win+1680 表), 非命令。

决议 def 侧锚 (CDecision, sizeof 3384; ctor sub_140723280; ReadKey 钩子 = def+8 表 0x1427eb3e8 槽[4] = sub_140732770):

| 偏移 | 名称/语义 |
|---|---|
| +288 | 名 (行名/图标; ignored 集 cc+5360 名键查询 → 状态元 1/2) |
| +368 | CDecisionCategory* (定案; 类别对象 1016B = 0x3F8: 双 vt 0x1427eb330/0x1427eb380, ctor 0X140723750, 装载器 sub_140726190 "Duplicate category" 断言, key 派发器 0X1407332B0 全 key 落名 available/allowed/visible/icon/picture/priority/scripted_gui/custom_icon/on_map_area/visibility_type/highlight_states; def ctor 初值 = TNullObject 单例 qword_143330DD8) |
| +376 | **available trigger 体** (存在旗 u32@+396; 求值 sub_1407313C0: bypass byte_14332F632 → 1, 否则类别门 ∧ (!旗 ∥ Eval(体))) |
| +464 | **allowed trigger 体** (旗@+484; 求值点 = 采纳命令路径 CSelectDecisionCommand, 点击时) |
| +552 | **visible trigger 体** (旗@+572; 求值 sub_1407367D0→sub_140736830 = 类别 visible ∧ def visible; profiler "should_show") |
| +1208 | cancel_effect trigger |
| +1536 | desc 串 |
| +1600 | 成本 |
| +1620 | 成本 |
| +1776 | alert_days |
| +1984 | days_remove |
| +2192 | days_re_enable |
| +2400 | fire_only_once (bool; **置位则冷却不倒计时, 永久占用**) |
| +2444 | 目标上下文分支 |
| +2528 | 目标上下文分支 |
| +2816 | 行按钮门 (byte) |
| +2817 | 行按钮门 (byte) |
| +3120 | timeout_effect |
| +3240 | ai_will_do trigger (+2404 预求值旗; decision.cpp:425 " has a ai_will_do pre-evaluated to zero" 警告) |
| +3296 | on_map_mode 枚举 (key 15414; 定案): 0=map_only / 1=decision_view_only / 2=map_and_decisions_view (默认 2; Finalize 0X140730250 无目标字段时压 1); 行门 {1,2} = 决议视图可见, {0,2} = 地图呈现门 |

决议求值时机: 引擎侧 decision.hourly (sub_14072FC90, §4.2.6) 每小时入口但核心评估/冷却递减带**日错峰门 sub_140731CF0**: `(gs+1128 − 43800000) % 24 == country_idx % 24` — 即每国每天一次; GUI 侧 = 决议视图列表重建时 (sub_14171D370 五态: taken → 3/4; visible ∧ available → 2−成本判定 sub_140726C20; 否则 0 隐藏)。冷却递减双通道: re_enable (ds+88) 主循环内 `--cd+16 days < 1` swap-remove; remove (ds+112) = sub_140737480 `--cd+16` 到期 → 从 decisions_taken (ds+64) 移除名 + swap-remove。

targeted / timed entry:

| entry | 偏移 | 名称/语义 |
|---|---|---|
| targeted | +32 | target_tag (target 对象 16B@entry+24 的 +8; 子 writer tag>0 引号名否则 idx 数字) |
| targeted | +36 | target.idpair.idx (target 对象 +12; 同槽两视角) |
| targeted | +40 | state (唯一槽; writer/reader 同槽) |
| targeted | +44 | ignore |
| timed | +24 | 日数 |
| timed | +28 | 门: state ∉ {3,4} |

类别对象 (= *(def+368)):

| 偏移 | 名称/语义 |
|---|---|
| +72 | available trigger (ReadKey sub_1407332B0) |
| +160 | allowed trigger (旗@+180) |
| +248 | visible trigger (旗@+268; 消费 sub_140736830 类别 visible 门) |
| +344 | icon 串 |
| +376 | picture |
| +408 | priority |
| +464 | scripted_gui 名串本体 (MSVC SSO: 缓冲@+464 / **size@+480** / cap@+488); ReadKey case 14961 写 +464; 门 = size ≠0 → EventCategoryHeader / =0 → InfoItem (定案) |
| +544 | SOnMapLocator vector (304B 元素, key 15048 on_map_area; pass F 逐 locator 求 CScriptTargets 命中 → OnMapLocatorItem) |
| +544 | SOnMapLocator vector 尾 (304B 元素, 见 §4.30.12) |
| +568 | 可见门 |
| +568 | visibility_type 枚举 (0x2BEF/0x3C37/0x3C38/0x3C39 四子 token; ReadKey) ⚠ 同偏移双文档行待裁 |
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

活动库行为链: 库单例 getter sub_140164030/sub_140173520; AddTimedActivity sub_140ADA270 (绑 owner cc+3944 生产状态, 每日进度初值 = IC_TO_EQUIPMENT_COUP_RATIO × sub_140E69340(生产)); 进度公式 sub_140AD9ED0 (timedactivity.cpp:143 断言 "UsePoliticalPowerCost() || UseEndDate()": 有 total_cost → `points×1e5/total_cost`, 否则日期区间比); IsFinished = 基表槽[15] sub_140ADA4E0 (进度 ≥100000); IsActive = 槽[12] sub_140ADA500 (target cc+1156 >0); GetDesc = 槽[11] sub_140AD9980 (loc "POLITICS_TIMEDACTIVITY_PROGRESS")。工厂 sub_140AD7DD0 (effect 侧): 12531 demilitarized_zone → sub_1415A7840 / 12532 war_reparation → sub_1415A7800 / 13319 timed_wargoal / 13424 stage_coup (256B)。**timed_wargoal = justify 主逻辑 sub_141106980 每次 justify tick 栈上构造 (ctor sub_140AD7390) 即时发射** — 调槽[13] sub_140ADA7D0 完成 (=宣战 sub_1406D1A60) / [17] sub_140ADBEF0 (on_action "on_justifying_wargoal_pulse") / [18] sub_140ADB480, 不持久化。DMZ 创建 sub_141454710 (end_date = now + 24×dword_143332BB8); DMZ 槽[18] sub_1415A8800 到期恢复 (遍历 +104 州 id 逐州恢复)。**持久活动日推进链 (定案)**: 日推进写者 = **sub_140ADCBD0 DailyTick**
(`points@+40 += daily_cost@+32`, 门 = pay_upfront@+96 ∨ daily_cost ≤ 当前 PP;
非 upfront 返回消耗由上游扣 PP → sub_140BA7470 AddPoliticalPower); 驱动宿主 =
**politics.daily sub_140BA8300** (CPolitics::DailyUpdate, politics.cpp:491;
country.daily sub_1406E76A0 内联调 *(cc+3984), §4.2.7 序13「政治」步) 四段:
清理段 (槽[12] IsActive==0 → dtor + swap-remove, target 亡国静默蒸发不还原;
三持久活动 [12] 覆写恒真样板 0x1401807B0 不受此清理) → 日扣段 (DailyTick +
扣 PP) → 完结段 (槽[15] IsFinished → 槽[14] (全类空桩) → dtor + 紧缩) →
timed_ideas 递减。三持久活动 (DMZ/赔款/资源权) **daily_cost 恒 0** (ctor 清零
+ 运行时创建现场均不设置) → points 从不写 — **免写推进定案** (纯日期分支:
进度 = max(PP 分支, 1e5×(now−start)/(end−start)); 到期槽[18] OnFinished 还原
效果 + 完结段销毁)。三模式穷举失败根因 = 调用方全部虚调用 (槽 [12]/[15]/
[17]/[18]), 文本 grep 天然落空。
虚表 19 槽定名 (exe 直读): [9]=GetName (loc 键) / [10]=GetDesc (GUI tooltip) —
两槽基表 _purecall 纯虚; [12]=IsActive / [13]=OnAdd 即时效果 (append
sub_140BA7570 后立即调 — 创建即生效: DMZ 逐州置非军事化 / 赔款给 target 加
offmap 民工 sub_1410DC4E0 (断言 peacetimedeffect.cpp:180) / 资源权逐州授开采
权 sub_140CA6300) / [14]=OnRemove (全类空) / [15]=IsFinished (DMZ 覆写
sub_1415A8330: owner 亡国直接完成; 赔款/资源权 sub_1415A8370: 和约断直接完成) /
[17]=OnDailyPulse / [18]=OnFinished 还原 (DMZ sub_1415A8800 解除非军事化 /
赔款 sub_1415A8B50 按 +108 实加数移除 offmap 工厂 / 资源权 sub_1415A89A0
撤销开采权)。
工厂勘误: 12531 → sub_1415A7760 (DMZ ctor, 128B) / 12532 → sub_1415A7840
(赔款 ctor, 112B) — 两 ctor 旧标注错位; 工厂唯一文本调用者 = CPolitics reader
sub_140BAD850 (存档多态重建), effect 侧运行时创建走直接 malloc+ctor (DMZ
sub_141454710 / 赔款 sub_141455B80 / 资源权 sub_141454CE0; 天数 define =
PEACE_TIMED_EFFECT_LENGTH_{DEMILITARIZED_ZONE dword_143332BB8 / WAR_REPARATION
dword_143332CA0 / RESOURCE_RIGHTS dword_143332D80})。⚠ **12533 读档缺口
(引擎缺陷, 结构定案)**: 资源权活动 writer 照写 (sub_140BB0520 键 13320 段无
过滤) 但工厂无 12533 分支 → 读档 "Invalid type" (timedactivity.cpp:250) 拒收
静默丢失 → 到期还权失效 (开采权永久化; 后果推定)。和约条目 12534
dismantle_industry = 即时条目非定时活动。

定时活动五类虚表槽全景 (exe .rdata 直读; 槽 | 基表 CBaseTimedActivity 0x142944A10 |
CTimedEffectActivity 0x142944B50 | DMZ 0x1429DC140 | 赔款 0x1429DC1E0 | 资源权
0x1429DC280):

| 槽 | 基表 | DMZ/赔款/资源权 覆写 | 语义 |
|---|---|---|---|
| [0] | _purecall | dtor 各异 (DMZ/资源权 共用 sub_1415A7870 / 赔款 sub_1415A78E0) | 析构 |
| [2] | sub_140ADCC60 | 各异 (DMZ/资源权 sub_1415A8E90 / 赔款 sub_1415A8ED0) | writer |
| [4] | sub_140ADC130 | 各异 (DMZ/资源权 sub_1415A8BB0 / 赔款 sub_1415A8BD0) | reader |
| [9] | _purecall | 各异 | GetName (loc 键; DMZ/赔款共用 PEACE_TIMED_EFFECT_DEMILITARIZED_ZONE_NAME / 资源权 PEACE_TIMED_EFFECT_RESOURCE_RIGHTS) |
| [10] | _purecall | 各异 | GetDesc (带参长文本, GUI tooltip) |
| [11] | sub_140AD9980 | — | GetProgressDesc ("POLITICS_TIMEDACTIVITY_PROGRESS") |
| [12] | sub_140ADA500 | 三持久活动 = 恒真样板 0x1401807B0 | IsActive (基 = target cc+1156>0) |
| [13] | CFG 桩 | 各异 (sub_1415A83E0 / sub_1415A8740 / sub_1415A8580) | OnAdd 即时效果 |
| [14] | CFG 桩 | — (全类空) | OnRemove |
| [15] | sub_140ADA4E0 | DMZ sub_1415A8330 / 赔款=资源权 sub_1415A8370 | IsFinished |
| [16] | CFG 桩 | 仅赔款 sub_1415A8C10 | (赔款独有; IsActive 门 + CModifier 构造) |
| [17] | _purecall | — (timed_wargoal 覆写 on_justifying_wargoal_pulse) | OnDailyPulse |
| [18] | _purecall | 各异 (sub_1415A8800 / sub_1415A8B50 / sub_1415A89A0) | OnFinished 还原 |
| [1]/[3]/[5..8] | wrapper/桩 | — | Save/Load wrapper / 空 |

CTimedEffectActivity [9]/[10] = sub_1401773F0 (PP 驱动活动通用名/描述); 工厂
sub_140AD7DD0 分支: 12531→sub_1415A7760 / 12532→sub_1415A7840 / 13319→
timed_wargoal (0x90) / 13424→stage_coup (0x100)。sub_140ADA270 = stage_coup
装备需求清单采集 (非 append — 真正 append = sub_140BA7570)。

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

哈希插入 sub_1401CA1D0: 哈希 = sub_14221EF50(token) % 桶数; 节点 16B {事件指针@+0, next@+8}; **头插**; ++水位(gs+1336)。运行期写入 = 事件发射尾 (`ev+1057 fire_only_once → sub_1401EDE40 → sub_1401CA1D0`); **读档重建 = sub_1401F1760** (遍历 fired_events gs+1352 token 对 → 查哈希不在则插入; 调用者 = CInGameIdler::[6] sub_140DD6A30 开局/读档完成初始链) — gs+1352 (持久) 与 gs+1336 (运行索引) 为同一集合两态, 载入零态 = 哈希空由初始链重建; 无运行期清空点。查询 = sub_1401DF300 桶链比对。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | 匿名结构 (NNB 形状) | key | | 事件名宿主 (串/token 双态) |
| +8 | 节点* | next | | next 链 |

名解析决策表 (形态|判别|读法):

| 形态 | 判别 | 读法 |
|---|---|---|
| 串 | qword@key+48 ≠ 0 | 双候选: @key+48 值 ≤4096 → 视为 MSVC 串对象 (@key+32: buf@+32/size@+48/cap@+56) 的 size, 按 SSO 读; 大值且 kptr → 视为裸 C 串指针, read_cstr; 皆失败回退 token 形态 |
| token | qword@key+48 = 0 | token@key+12 → 运行时 lexer 表 |

#### 4.12.8 事件触发与发射链 (CEventManager / CEvent / 调度 / option 执行)

**CEventManager** (单例 qword_143339C20, 惰性构造 sub_140A0D4A0; 224B, ctor sub_140A0CDB0; 文件读取 sub_140A0D9A0 "Reloading Events: " + tbb ReadEvents_CEventManager):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | CPdxArray | 国家事件数组 (国家侧检查消费) |
| +24 | CPdxArray | 州事件数组 (州 worker 消费) |
| +48 | CPdxArray | 第三数组 (装载桶形态) |
| +160 | unordered_map | 文件桶 map (键 = 事件文件名 FNV-1a; 桶对象 +48 起为该文件事件容器; 定案无集中归并点 — boot 载入 sub_140A0C190 (并行, a4=0) 事件直接 append 进 mgr+0/mgr+24 消费数组, 仅 watcher 热重载 (a4=1) 走本桶 + mgr+48 staging, 详 §4.28.17) |

检查调度 = **每 20 天错峰** (EVENT_PROCESS_OFFSET = dword_143336F50, 默认 20): 国家侧 CGameState::DailyUpdate 并行波 → sub_1401BA6F0 → sub_1406E8210, 相位 = cc+4750 (ctor sub_1406C9CC0 写 country_idx % 20), 门 = 相位 == gs+1156 年积日 % 20; 州侧 worker sub_1409D7760, 相位 = st+2032 (州 ctor sub_1409CFB10 写 定义对象+160 % 20)。bypass 旗 byte_14332F61A && !IsAI → 免相位门强制检查 (调试)。

**AddEventsToFire sub_140A0D4E0** (掷骰筛选, 五步): ① is_triggered_only (ev+1055) 置位跳过 / exclusive (ev+1058) 本轮只掷一个; ② fire_only_once (ev+1057) → 查 gs+1336 哈希 (sub_1401DF300) 已 fired 跳过; ③ trigger 预筛 sub_141180350 (系统启用位门 `(ev+1048 & dword_14332F248) == ev+1048` → ev+104 CTrigger 槽[3] Evaluate); ④ MTTH 权重 sub_14117FC00 → 核 sub_140551E40: 基值 = CEvent+896 MTTH 块 +920 (默认 1 天), 逐 CMTTHModifier (块内 +928 向量; factor@+88 乘/add@+296 加) → `1e6×N_days/MTTH` 钳 [1,1e6]; ⑤ 掷骰 `rng % 1e6 < P ∥ force` 入队。

发射链: 掷中候选 → **cc+4776 容器** ({data@+4776, count@+4788}; 与 cc+4752 delayed_events 相邻勿混) → CCountry::DailyUpdate 串行段 "country.queued_events" 逐条再复核 trigger → sub_140A0F4F0 (断言 "Scope.GetRandom() != CCrudeRandom()") → **sub_140A0F6F0 真发射体**: fire_only_once 复核 → timeout_days (ev+1032) 到期时刻 = now+24×days → sub_1401CAFF0 pending_events (gs+1376) 入队 (56B 元 {fire_id/CEvent*/scope*/tag/date×2}; scope = CEventScope 176B 深克隆, §4.00.4a) → AI/hidden (IsAI ∥ ev+1059) 路径逐 option 掷 (sub_141539CB0 trigger + sub_141539B80 CAIMTTHChance 权重) 构造 CSelectEventOptionCommand (sub_141539E40, 240B) 入命令队列; 玩家路径 = idler 虚槽 +240 挂事件收件箱; fire_only_once 落账 sub_1401CA1D0 (§4.12.7); major (ev+1056) → 广播分支 (遍历 gs+784 各国)。

**CEvent** (1064B = 0x428; vt 0x142999BE8 11 槽 + 第二表 0x142999C40 @+24 名串基视图; ctor sub_14117F1A0; ReadKey = sub_141180B10; 活体抽验 5 实例全对上):

| 偏移 | 类型 | 键/语义 | 置信 |
|---|---|---|---|
| +8 | u32 | **CIdPair.type = 50** (ctor 写哨兵 qword_14333D528 整 8B; 原「id token / 事件序号」两行翻案为一个 idpair) | 定案 |
| +12 | u32 | **CIdPair.id** (writer 键 11 写 +12; fired 表以 CEvent 指针为键非此值; 活体 1000001) | 定案 |
| +16 | u8 | idpair 已注册旗 (setter 成功置 1) | 定案 |
| +24 | ptr | 第二 vtable 0x142999C40 (名串基视图; 原「MTTH 基值」翻案) | 定案 |
| +32 | SSO 32B | 事件规范名 (id 键反查成功回填; 活体 "denmark_political_events.1"; 原 +32 数组/串两说 — **串说胜结案**) | 定案 |
| +64 | SSO 32B | id 键原文串 (finalize 缺 option 报错打印此串) | 定案 |
| +96 | u32 | **事件族类型码** (ctor 第二参; 作 +104/+280/+896 子解析 scope): country/news/unit_leader = 4 / state = 2 / operative = 8 (装载器五分支 + 活体双证) | 定案 |
| +104 | CAndTrigger 88B | trigger (10595; vt[5] Parse 带 +96; 发射门 = +1048 位掩码) | 定案 |
| +192 | CAndTrigger 88B | **show_major** (13801; Parse scope 字面 4) — 原「第二 trigger」键名定案 | 定案 |
| +280 | CEventOption 504B | 内嵌默认 option (序号 −1; immediate 键 10837 → 其 vt[3]) | 定案 |
| +784 | CEffect 88B | **after 块** (17136) | 定案 |
| +872 | 向量 24B | option 指针向量 {data@872, cap@880, **count@884**, alloc@888}; 元 = malloc(0x1F8) CEventOption (ctor 第三参 = push 前计数 = option 序号) | 10598 |
| +896 | CMeanTimeToHappen 56B | **mean_time_to_happen 块** {类型码@+912, MTTH 基值@+920 (默认 1 天), CMTTHModifier* 向量@+928} — 原「+24 基值/+32 modifier 数组」两行系权重核块内坐标误锚, 双双翻案 | 10596 |
| +952 | 向量 24B | **title 向量** — 元 CTriggeredText* (128B: 文本串 + CAndTrigger) | 10643 |
| +976 | 向量 24B | **desc 向量** (同构; 注册期缺 desc 检查 count@988) | 10644 |
| +1000 | SSO 32B | picture (464) | 定案 |
| +1032 | i32 | timeout_days (ctor 默认 = 全局 dword_143336720) | 14389 |
| +1036 | u32 | 解析出处·文件 id (Parse override 从解析上下文取 8B 戳) | 定案 |
| +1040 | u32 | 解析出处·行号 | 定案 |
| +1044 | u8 | 出处已置旗 (dtor 若置位回写 0xAA 毒值) | 定案 |
| +1048 | u32 | 系统依赖位掩码 (触发预筛门 `(v & dword_14332F248) == v`); ⚠ 已定位写者只写 0, 非零写者未定位 (待裁) | 门公式定案 |
| +1052 | u8 | 国家作用域族旗 (state_event = 0, 其余 1) | 定案 |
| +1053 | u8 | operative_leader_event 专属旗 | 定案 |
| +1054 | u8 | unit_leader_event 旗 | 定案 |
| +1055 | u8 | is_triggered_only (11115; 置位跳过掷骰) | 定案 |
| +1056 | u8 | major (11241) | 定案 |
| +1057 | u8 | fire_only_once (11002; fired 哈希键 = CEvent 指针) | 定案 |
| +1058 | u8 | exclusive (11776; 本轮已掷中一个则其余跳过) | 定案 |
| +1059 | u8 | hidden (11404; finalize 门) | 定案 |
| +1060 | u8 | news_event 旗 (12776) | 定案 |
| +1061 | u8 | fire_for_sender (13947; ctor 默认 1) | 定案 |
| +1062 | u8 | minor_flavor (12941) | 定案 |

> CMTTHModifier 504B 构成补齐: CAndTrigger 门头 + factor/add 两 CScopedVariable 208B
> (初值 1.0/0), 与 §4.34 MTTH 行完全吻合; CAIMTTHChance 272B 实为 CMeanTimeToHappen 派生类。
> ⚠ 延时事件 writer 路 (sub_141181300 键 440) 读 +32 为串名的旧疑案按串说结案 (见 +32 行)。

option 执行链: 三入口 (玩家点击/超时自动/AI 选择) 同归 **CSelectEventOptionCommand::Execute → sub_14117FA30** (event.cpp:271 "Executing event: %i with option #%i"; idx<0 → 内嵌默认 option, 0≤idx<count → ev+872 元素) → sub_141539B70 = option+288 CEffect 槽[12] ExecuteChecked (vt+96; §4.00.3 同口径, 内部转调 [13])。option trigger 过滤 sub_141539CB0 (`!opt+501 ∥ opt+500 == immediate` 门 → opt+408 CAndTrigger 槽[3] Evaluate)。玩家事件窗口: sub_14123B0B0 建 "options_grid" 时逐 option 过滤 (窗口+4732 immediate 旗) — **窗口构建时一次性求值, 非每帧**; 超时自动选 sub_14123C410 (gs+1128 ≥ 窗口+4672 门 → 第一个 trigger 过的 option)。

#### 4.12.9 CDelayedEvent 生命周期 (延时事件通道; 布局 = §4.3.11 delayed_event 表)

类布局、容器 (cc+4752 data / cc+4764 count) 与元素存档键 = §4.3.11 (元素 0xC8; vt 0x1427E7488 / writer sub_141181300 / reader 0x141180910 / ctor 0x14117F120; +16..+191 内嵌 CEventScope 递归表同节)。与定时决策 CTimedDecision (§4.12.2) 无亲缘。运行链 (定案):

| 阶段 | 链 | 语义 |
|---|---|---|
| 创建 (入队) | 事件 effect 族共用 Execute **sub_141393950** (country_event = CCountryEventEffect token 10127 / news_event = CNewsEventEffect 12776 / state·unit_leader·operative_leader_event 系同构) | 定位 CEvent ({type=50, id} idpair RTDynamicCast 或名) → 延时小时 = eval(+1232) + 24×eval(+1440 days) + 720×eval(+1648 months) + random [0, eval(+2064)) (门 +1856; 载荷槽族 = §4.32.1.1 事件族骨架行) → **延时 >0: sub_1406D0880(接收国, event, &originator, scope, hours) 入接收国 cc+4752**; 延时 =0: 当场 sub_140A0F6F0 直发 (不入队) |
| 等待 | **sub_1406FC980** (profiler "country.delayed_events"; hourly pass⑥ 复合体 sub_1406FD800 首调, §4.2.6) | 逐元素 `--(elem+196)` 每小时递减; bypass = byte_14332F61A ∧ !sub_1406FFDB0(cc) (human_ai 旗参与 AI 判定); 元素+8 空 → "Corrupt event." (country.cpp:13436) |
| 到点 | trigger 复核 → 发射 | 造 scope (country = cc+8 属主) → CEvent+104 trigger 复核 (sub_141180350 槽[3]) → 过 = **sub_140A0F6F0(CEventManager 单例, ev, &elem+192, &cc+8, scope, 1)** = §4.12.8 真发射体 — **到点后与掷骰命中事件走同一条发射链, 无独立链**; 复核失败 → 静默删除; 哨兵门: CEvent+8 == qword_14333D528 (多处用作「无事件」填充; 推定无效事件标记, 待裁) → 不发射仅移除 |
| 移除 | swap-remove | 尾元补位 + cc+4764-- + vt[0] 析构 |
| 读档 | delayed_event 块 (键 11463) 逐元素重建 | 事件解析失败 ("Invalid event id") → 元素静默丢弃 (元素+8 空不 push) |

> ⚠ cc+4752 (本通道 = 显式延时 hours/days/months, 纯 hourly) 与 cc+4776 (queued_events = MTTH 掷骰命中, 每日检查调度 §4.12.8) 相邻两通道勿混。


#### 4.12.10 链内深扫定址补注表 (e4 批 G 快裁 B 档集中落账; 置信 = 快裁级, 细作时升定案)

| 来源 | 函数与身份 / 建议落点 |
|---|---|
| part01 | sub_141511CE0（910 行，#3） / 事件/消息(外交) / 书 `s4_12_events.md` 消息/新闻事件发射族补本件（流亡者消息：EXILE_MESSAGE_ARRIVED/REINFORCEMENTS/RETURNED 三态 + SENDER/RECEIVER/COUNT/LOCATION 字段）；触发链注 `s4_02_gametick.md:267` §4.2.7 CCountry::DailyUpdate 的 exile_divisions_transfer 到期步（wrapper sub_141511C30 ← sub_1406E76A0） |
| part07 | sub_140736F50（#13） / decision.hourly 内部件 / 书 `s4_12_events.md`（决策域）+ `s4_02_gametick.md`:214 pass⑥ 定址补注：sub_14072FC90 内本步（挂起/到期族 + sub_140727AE0 激活 + 通知 + cc+3944 生产联动） |
| part08 | sub_140CDAC60（188 行，#13） / 事件/军事日志 / 落点候选 `s4_12_events.md:303` 事件检查波节（宿主 sub_1406E8210 已实名）或 `s4_22_combat.md` NCombatLog 节（0x140CD 邻域）；细作先裁条目语义（到期事件 or 战斗日志条目老化）再定册 |
| part10 | sub_140728D60（#5） / 决议/任务 / 书 `s4_12_events.md`（+1208 cancel_effect trigger / +3120 timeout_effect 字段行）补执行器地址对：timeout = sub_140728D60、cancel = sub_140728400；`s4_03_CCountry.md:1147` +576 cancel_effect 行同注 |
