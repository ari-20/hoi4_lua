

### 4.12 事件与决议域 (事件 option / 决策状态与冷却 / 定时活动与定时条目)

> **定位**: 事件 (option 定义体) 与决议/决策全链 —— CEventOption、CDecisionStatus
> 状态聚合、冷却记录、定时·定向决策实例、定时活动族与定时条目族。
> 决议 GUI (DecisionView 族) 见 §4.30.12; 决议命令族 (CSelect/Ignore) 见其命令表;
> 事件 effect (country_event/news_event 族) 见 §4.32.11。
> 国家侧挂载点 (cc+4000 ds) 见 §4.3 (批5 后为 §4.3.10)。

#### 4.12.1 CEventOption (事件 option 定义体, 504B; vtable 0x142999B48)

不入档 (writer = CFG 空桩; reader 0x141539CE0 = 事件文件脚本解析; ctor 0x14117F370)。宿主 = CEvent+280 内嵌一份 (至 +784), 另 CEvent+872 = option 指针向量 (Parse 逐块 new+push, +884 序号)。

| 偏移 | 类型 | 语义 (键 token) |
|---|---|---|
| +8 | uint32 | 宿主 event id token (作子对象 parse 的 scope token) |
| +16 | CAIMTTHChance 内嵌 272B | ai_chance (10599, 子 vtable[3] 读) |
| +288 | CEffect 内嵌 88B | option 效果体 (匿名效果 token 全走 default → 子 vtable[4]) |
| +376 | std::string 32B | name (27) |
| +408 | CAndTrigger 内嵌 92B | trigger (10595, 子 vtable[5] 带宿主 token; +32 = 10600) |
| +496 | uint32 | option 序号 (内嵌默认 -1) |
| +500 | uint8 | original_recipient_only (11705) |
| +501 | uint8 | 11705 已给旗 |

#### 4.12.2 决策状态族 (CDecisionStatus / 冷却 / 定时·定向决策)

**CDecisionStatus** (国家决策状态聚合, 456B; CPersistent@0, vtable 0x1427EB5C0; writer 0x140738AA0 / reader 0x140733A20 / ctor 0x140723C70; 挂 cc+4000, 见 §4.3)。内部容器统一 24B 元 {data@0, cap@8, count@12, alloc@16}:

| 偏移 | 容器/语义 (存档键) | 备注 |
|---|---|---|
| +8 | owner (CCountry*) | ctor 入参直存 |
| +16 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +64 | **decisions_taken** (14343) | 决策名串列表 (writer 逐元写 *(dec+288) 名) |
| +88 | **decision_to_re_enable** (14542) | CDecisionCooldown* |
| +112 | **decision_to_remove** (14543) | CDecisionCooldown* |
| +136 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +160 | **active_timed_decision** (14347) | CTimedDecision* (书 §4.3 "d@160 c@172" 即此) |
| +184 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +208 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +232 | **active_targeted_decision** (14422) | CTargetedDecision* |
| +256 | **active_targeted_timed_decision** (14814) | CTargetedDecision* |
| +280 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +304 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +328 | **random_item** (14734) | 24B 记录元 |
| +352 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +376 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +400 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +424 | 匿名结构 (NNB 形状) 向量 | 不序列化 |
| +448 | uint16 ctor=1 | **决策脏/待更新旗** (+448 u8; +449 = 独立第二旗)。ctor sub_140723C70 写 `*(WORD*)(a1+448)=1` (= +448 置 1 / +449 置 0); 多处更新点写 `*(BYTE*)(a1+448)=1`; 消费/清除点 = `sub_1407378E0(ds, flag)`: `if (*(BYTE*)(ds+448) || flag) {…重算…}; *(BYTE*)(ds+448)=0`; **+449 = decision_to_remove 处理重入锁字节 (定案)**: sub_140737480 入口 `if(!*(ds+449)){*(ds+449)=1;…处理 ds+112 到期/移除…; *(ds+449)=0;}` 防 remove 效果级联重入, 稳态恒 0; ds 取得链 = sub_1406CF4D0 单行 `return *(QWORD*)(a1+4000)` |

**CDecisionCooldown** (冷却记录, 24B; vtable 0x1427EB450; writer 0x140738A50 / reader 0x1407337F0): +8 CDecision* (写名 = *(dec+288); 读按名走决策库 RH 反查 sub_140722CC0 + 280 有效门) / +16 i32 days (10605)。垃圾键抛 "Unexpected token when reading decision on cooldown"。

**CTimedDecision** (定时决策实例, 32B; IDecision@0 + CPersistent@8 双基, 主 vtable 0x1427EB4A0 / 次 0x1427EB4B8; writer 0x140738E20 / reader 0x1407349C0): +16 CDecision* decision (11142 名串) / +24 u32 days (10605) / **+28 u32 state (439 块)**。

state 枚举 (CTimedDecision): 0 active (11390) / 1 completed (12583) / 2 failed (14349) / 3 aborted (14811) / 4 re_enable_cooldown (14816); 非法值抛 "Unknown state for timed decision"。

**CTargetedDecision** (定向决策实例, 96B; 同双基, 主 vtable 0x1427EB508 / 次 0x1427EB520; writer 0x140738D50 / reader 0x1407346A0): +16 decision (11142) / +24 STargetedDecisionTarget 内嵌 target (107, 通用递归读; **布局定案 = 16B, 仅 8B idpair {tag_id u32@+8, idx u32@+12}**: vtable 0x142765CF8, writer sub_140738A10 (tag>0 发引号 tag 名, 否则发 idx 数字) / reader sub_140732670) / **+40 u32 state** (439; 单槽定案 — reader 0x1407346A0 写体+32 = obj+40 / writer 读同槽 / ctor 清 / 采纳写 1 四证; state=2 reader 兼接受旧别名 10376 enable, writer 只发射 14816) / **+44 u8 ignore** (11736) / +48 u32 days (10605) / **+56 32B 串 (键 19935 power_balance, 有存档键)** / +88 i32 ctor=-1 运行时。

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
| ds+136 | 匿名结构 (元素待裁) 向量 | timed 待激活 def 表 (推定: 可用性扫描填充) | hourly 十步序 sub_14072FC90 直读 |
| ds+160 | CTimedDecision* 向量 | active_timed 源 | → CDecisionViewTimedDecisionItem (entry@+2736) |
| ds+232 | 容器 {c@ds+244} | active_targeted 源 | → CDecisionViewTargetedDecisionItem (entry@+4024) |
| ds+256 | 匿名结构 (元素待裁) 向量 | att_timed 源 | 元素 = CTargetedDecision* (§4.12.2 ds+256 行定案) |
| ds+304 | 容器 24B {c@ds+316} | 类别态表 | 类别可见门 +568 ∧ available ∧ should_show ∧ power-balance (+976/+992, 经 gs+1104); 类别行分组键 = *(def+368) = CDecisionCategory* |
| ds+328 | SDecisionRandomCountItem 容器 | 随机计数条目 {vtable@+0, dec@+8, count@+16, aux@+20} | hourly 十步序直读 |
| ds+352 | 容器 24B | 候选目标挂起容器 1 (24B 条 {tag, def}; 计数 ds+364) | targeted 决议逐国枚举挂起 |
| ds+376 | 容器 24B | 候选目标挂起容器 2 (计数 ds+388) | 同上 |
| ds+400 | 容器 24B | 候选目标挂起容器 3 (计数 ds+412) | 同上 |
| ds+424 | 容器 24B | 候选目标挂起容器 4 (计数 ds+436) | 同上 |
| cc+5360 | 名集合 (定案) | ignored 决议名集合 = player_settings (存档 token 14423) 内 ignored 集 | 写侧: CIgnoreDecisionCommand::Execute 0X141157240 (byte+72=1 插入 / =0 删除); CIgnoreAllAvailableDecisionCommand::Execute 0X141156FD0 全量插入 |

决议命令族 (CSelect/Ignore 四枚, id 经 vtable[11] GetId 实证): 载荷布局与
GUI 绑定全表见 §4.33 (id 14345 / 14383 / 14768 / 14769)。

注: CategoryItem cb sub_141D74190 = 折叠切换 (win+1680 表), 非命令。

决议 def 侧锚 (CDecision, sizeof 3384; ctor sub_140723280; ReadKey 钩子 = def+8 表 0x1427eb3e8 槽[4] = sub_140732770):

| 偏移 | 名称/语义 |
|---|---|
| +288 | 名 (行名/图标; ignored 集 cc+5360 名键查询 → 状态元 1/2) |
| +368 | CDecisionCategory* (定案; 类别对象 1016B = 0x3F8: 双 vtable 0x1427eb330/0x1427eb380, ctor 0X140723750, 装载器 sub_140726190 "Duplicate category" 断言, key 派发器 0X1407332B0 全 key 落名 available/allowed/visible/icon/picture/priority/scripted_gui/custom_icon/on_map_area/visibility_type/highlight_states; def ctor 初值 = TNullObject 单例 qword_143330DD8) |
| +376 | **available trigger 体** (存在旗 u32@+396; 求值 sub_1407313C0: bypass byte_14332F632 → 1, 否则类别门 ∧ (!旗 ∥ Eval(体))) |
| +464 | **allowed trigger 体** (旗@+484; 求值点 = 采纳命令路径 CSelectDecisionCommand, 点击时) |
| +552 | **visible trigger 体** (旗@+572; 求值 sub_1407367D0→sub_140736830 = 类别 visible ∧ def visible; profiler "should_show") |
| +640 | **remove_trigger 体** (存在旗@+660; ReadKey sub_140732770 直读) |
| +728 | **cancel_trigger 体** (存在旗@+748; 运行时 cancel 判定对应本槽 — 旧对应 +1208 说废) |
| +816 | **modifier 块** (存在旗@+824) |
| +1032 | **complete_effect 体** (采纳执行体 sub_1407357F0 消费) |
| +1120 | **remove_effect 体** (存在旗@+1140; days_remove 到期执行) |
| +1208 | **cancel_effect 体** (存在旗@+1228; 原「cancel_effect trigger」精化为 effect 体) |
| +1296 | cost 值对象 (采纳扣 PP; ~14% 变量引用) |
| +1536 | desc 串 |
| +1600 | custom_cost_trigger trigger (键 14878 — 精化: 原「成本」笼统) |
| +1620 | **custom_cost_trigger 存在旗** (定案: 存在 → execute 免静态 cost + UI 可负担判定切 custom trigger) |
| +1776 | alert_days |
| +1984 | days_remove |
| +2192 | days_re_enable |
| +2400 | fire_only_once (bool; **置位则冷却不倒计时, 永久占用**; 运行期 = 「递减门跳过 + days≤0 仍入队」双点实现) |
| +2401 | is_good (bool; 使命成败方向反转) |
| +2402 | fixed_random_seed (bool, 推定) |
| +2403 | cancel_if_not_visible (bool) |
| +2444 | 目标上下文分支 (sub_141722BB0 候选州集合路径, 按 scope RNG 随机抽一; 收集器语义待裁) |
| +2528 | 目标上下文分支 (sub_141722BB0 主路径: 非零 → sub_140C2B460(def+2520, &候选, scope) 收集候选州后随机抽一) |
| +2800 | priority 高档 (缺省 = 类别 +960) |
| +2804 | priority 低档 (缺省 = 类别 +964) |
| +2816 | **is_timed byte** (定案: sub_140731E80 单行直证; 旧「行按钮门」说废) |
| +2817 | is_targeted byte (推定: targeted 采纳查表分派) |
| +2824 | days_mission_timeout 值对象 (sub_14072F040) |
| +3032 | should_activate trigger 体 (推定: 脚本键 activation ↔ 槽) |
| +3120 | timeout_effect |
| +3240 | ai_will_do trigger (+2404 预求值旗; decision.cpp:425 " has a ai_will_do pre-evaluated to zero" 警告) |
| +3296 | on_map_mode 枚举 (key 15414; 定案): 0=map_only / 1=decision_view_only / 2=map_and_decisions_view (默认 2; Finalize 0X140730250 无目标字段时压 1); 行门 {1,2} = 决议视图可见 (sub_1407313A0 = (v−1)<=1), {0,2} = 地图呈现门 (sub_1407313B0 = (v & 0xFFFFFFFD)==0) |

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

**CBaseTimedActivity** (抽象基, 104B; vtable 0x142944A10 19 槽含 5 _purecall; writer 0x140ADCC60 / reader 0x140ADC130): +8 u32 类 token (CPersistentWithToken, 例 timed_wargoal=13319) / +16 owner (10302) / +20 target (107) / +24 i64 total_cost (13317, >0 写) / +32 i64 daily_cost (13318, >0 写) / +40 i64 points (12766, >0 写) / +48 CGameDate start_date (10464) / +72 CGameDate end_date (10465) / +96 u8 pay_upfront (13899)。派生各自的 writer 继承调用; 效果类 ctor 直证 start_date.hours = *(gs+1128) 当前日期。

| 派生 (载体 = 存档 timed 块) | vtable/writer | 追加字段 |
|---|---|---|
| CTimedEffectActivity | vtable 0x142944B50; writer 0x140ADCDC0 (dump 缺件, 推定 = 调基 writer, reader 0x140ADC430 零自有键互证) | 无自有存档键 |
| CTimedWargoalActivity | ctor 0x140AD7390 | (timed_wargoal=13319) |
| CDemilitarizedZoneTimedEffect (demilitarized_zone=12531) | vtable 0x1429DC140; writer 0x1415A8E90 / reader 0x1415A8BB0 | **+104 州 id 容器** (states=11835; ctor 自 a5 州 id 数组拷贝) |
| CWarReparationTimedEffect (war_reparation=12532) | vtable 0x1429DC1E0; writer 0x1415A8ED0 / reader 0x1415A8BD0 | **+104 u32 civilian_factories (19421) / +108 u32 num_of_civilian_factories_available_for_projects (14729)** |
| CResourceRightsTimedEffect (resource_rights=12533) | vtable 0x1429DC280; writer/reader 与 demilitarized 同 (12531/12533 双 token 复用同 writer) | **+104 州 id 容器** (states=11835; 买权州清单) |
| CTimedStageCoupActivity | writer 0x140ADCDD0 | +104 location(10349)/+112 equipment(12110)/+144 ideology(11838) |
| 专项活动 (civilian) | writer 0x1415A8ED0 / 0x1415A8E90 | civilian_factories(19421)@+104 / num_of_civilian_factories_available_for_projects(14729)@+108 / states(11835)@+104 |

**CTimedActivityDatabase** (活动类型库, 72B; TGameItemDatabase 单基, vtable 0x142944D48; ctor 0x140AD6F00; **idb timed_activity 已挂** 0x332F0B8): +40 CEquipmentArcheTypePool vtable 复用名 / +48 条目数组 (idb arr) / +56 cap / +60 count (idb cnt); 条目 = 16B 内联元。

活动库行为链: 库单例 getter sub_140164030/sub_140173520; AddTimedActivity sub_140ADA270 (绑 owner cc+3944 生产状态, 每日进度初值 = IC_TO_EQUIPMENT_COUP_RATIO × sub_140E69340(生产)); 进度公式 sub_140AD9ED0 (timedactivity.cpp:143 断言 "UsePoliticalPowerCost() || UseEndDate()": 有 total_cost → `points×1e5/total_cost`, 否则日期区间比); IsFinished = 基表槽[15] sub_140ADA4E0 (进度 ≥100000); IsActive = 槽[12] sub_140ADA500 (target cc+1156 >0); GetDesc = 槽[11] sub_140AD9980 (loc "POLITICS_TIMEDACTIVITY_PROGRESS")。工厂 sub_140AD7DD0 (effect 侧): 12531 demilitarized_zone → sub_1415A7760 / 12532 war_reparation → sub_1415A7840 (变体 ctor sub_1415A7800) / 13319 timed_wargoal / 13424 stage_coup (256B)。**timed_wargoal = justify 主逻辑 sub_141106980 每次 justify tick 栈上构造 (ctor sub_140AD7390) 即时发射** — 调槽[13] sub_140ADA7D0 完成 (=宣战 sub_1406D1A60) / [17] sub_140ADBEF0 (on_action "on_justifying_wargoal_pulse") / [18] sub_140ADB480, 不持久化。DMZ 创建 sub_141454710 (end_date = now + 24×dword_143332BB8); DMZ 槽[18] sub_1415A8800 到期恢复 (遍历 +104 州 id 逐州恢复)。**持久活动日推进链 (定案)**: 日推进写者 = **sub_140ADCBD0 DailyTick**
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
vtable 19 槽定名 (exe 直读): [9]=GetName (loc 键) / [10]=GetDesc (GUI tooltip) —
两槽基表 _purecall 纯虚; [12]=IsActive / [13]=OnAdd 即时效果 (append
sub_140BA7570 后立即调 — 创建即生效: DMZ 逐州置非军事化 / 赔款给 target 加
offmap 民工 sub_1410DC4E0 (断言 peacetimedeffect.cpp:180) / 资源权逐州授开采
权 sub_140CA6300) / [14]=OnRemove (全类空) / [15]=IsFinished (DMZ 覆写
sub_1415A8330: owner 亡国直接完成; 赔款/资源权 sub_1415A8370: 和约断直接完成) /
[17]=OnDailyPulse / [18]=OnFinished 还原 (DMZ sub_1415A8800 解除非军事化 /
赔款 sub_1415A8B50 按 +108 实加数移除 offmap 工厂 / 资源权 sub_1415A89A0
撤销开采权)。
工厂 ctor 映射 (定案): 12531 → sub_1415A7760 (DMZ ctor, 128B) / 12532 → sub_1415A7840
(赔款 ctor, 112B); 工厂唯一文本调用者 = CPolitics reader
sub_140BAD850 (存档多态重建), effect 侧运行时创建走直接 malloc+ctor (DMZ
sub_141454710 / 赔款 sub_141455B80 / 资源权 sub_141454CE0; 天数 define =
PEACE_TIMED_EFFECT_LENGTH_{DEMILITARIZED_ZONE dword_143332BB8 / WAR_REPARATION
dword_143332CA0 / RESOURCE_RIGHTS dword_143332D80})。⚠ **12533 读档缺口
(引擎缺陷, 结构定案)**: 资源权活动 writer 照写 (sub_140BB0520 键 13320 段无
过滤) 但工厂无 12533 分支 → 读档 "Invalid type" (timedactivity.cpp:250) 拒收
静默丢失 → 到期还权失效 (开采权永久化; 后果推定)。和约条目 12534
dismantle_industry = 即时条目非定时活动。

定时活动五类vtable槽全景 (exe .rdata 直读; 槽 | 基表 CBaseTimedActivity 0x142944A10 |
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

**CTimedActivityEquipmentDistributable** (设备分发活动, ≈136B; CEquipmentDistributable@0 + CPersistent@24 多基, 主 vtable 0x142944BF0 / 次 0x142944C28; writer 0x140ADCD50 / reader 0x140ADC3A0): 基 = priority@+8 (141, ≠1 写) / +32 produced 池 (12204, 非空写) / +64 运行时池 / +96 need 池 (12111)。

**GetDaysRemaining sub_140AD80C0** (86 行; 断言 :172 "UsePoliticalPowerCost() ‖ UseEndDate() && timed activated was not set with any way to determined the duration"): 门 = daily_cost@+32 ≤ 0 ∧ end_date@+80 == dword_143086B08 (**CGameDate::EndOfTime 哨兵, :156 断言文本直证命名 — §4.00.11 哨兵族第三成员, 数值待 PE 复核**)。PP 分支: daily_cost > 0 → days = round_fixed5(1e5 × (total_cost@+24 − points@+40) / daily_cost) (sub_1424ED730; 溢出守卫 / total_cost==0 → 0xFFFFFFFF); 日期分支: end_date ≠ EndOfTime → days = (end_date − gs+1128 当前日期) (同扣 43800000 纪元 ÷24); 返回 **min(日期分支, PP 分支)** (INT_MAX 参与比较故单分支即取该分支)。唯一调用方 = sub_140AD7C40 (GetDesc/文案族推定)。

**stage_coup 完成执行器 sub_140ADA910** (617 行全展开; a1 = CTimedStageCoupActivity: +16 owner cc / +20 target tag / +104 location state / +152 内嵌结构)。三因子规模公式 (全部 1e5 定点): ① 意识形态人气占比 = 1e5 × Σ(target 国意识形态表中该活动 ideology@+24 匹配项 +136 权重) / Σ(全部 +136 权重), 总权重 0 → 0xFFFFFFFF; ② 稳定度因子 = 稳定度 ≤ qword_143331260 阈值时 = qword_143331128 + (1e5 − 稳定度)×(qword_1433311D0 − qword_143331128)/1e5 (不稳定度线性放大, 区间 define 三枚), 稳定度够高 → 0; ③ 军力基准 = sub_141010160(a1+152, …) (revolution target 强度提取)。政变规模 = ③ × (② × ① / 1e5) / 1e5, >1e5 时断言 :831 "vCoupSizeModifier <= 1_fixed" (一次性闩) 后钳 1e5。指定州门: +104 非空 且 (state+204 controller == target 或同 tag 伴随 sub_140BB52F0) → CCivilWarSetup +80 = mode 4 / +84 army_size = *(state+88) (§4.10 指定州引用互证)。规模 > 0 → 栈构 CCivilWarSetup (ctor sub_1410DCD10, 256B) → 执行 sub_1410DDFE0 → 逐字段析构。:871 起公告文案: 目标国名 + 三因子 argmax 选 loc 键 (三两比较树) → 本地化发射 (loc 键字面值数据段不可读, 未决) + 引擎日志。尾段: gs+1312/1316 (玩家 tag 槽, 按 gs+1312 计数选偏移) ≠ owner 且非同 tag 伴随 → 通知/清理路径。

timed_wargoal OnDailyPulse (sub_140ADBEF0) 补门细节: 发射门 = **owner 国 +3976 表按 target 国下标取条目** (owner = a1+16, target 下标 = sub_140BB5490(a1+20) 或 0; 条目 = *(*(cc+3976+8) + 8×下标)), 其 **+744 槽对象为空或 +73 旗已置** → 走日志不发射; 不满足则 :430/:433 双日志 (owner 名 + target 名) 后**仍不发射**; scope 组装 owner(this)+FROM(target), eventscope.h:193 无限循环守卫断言 (闩 byte_14332F520)。派发链 = sub_140162FB0 (事件系统) → sub_140A792B0 (查名, 线性扫) → sub_140A79BA0 (触发 on_justifying_wargoal_pulse, ROOT=owner / FROM=target)。

#### 4.12.5 定时条目与理念/国策 def 周边

**CTimedIdea** (定时理念条, 24B; vtable 0x14294FD58; writer 0x140BB07D0 / reader 0x140BAE240): +8 CIdea* idea (10491, 写名 = *(idea+64)) / +16 u32 days (10605)。挂 ps+104 timed_ideas (§4.10)。

**CTimedModifier** (定时修饰条, 48B; vtable 0x1427D61C8; writer 0x140612730 / reader 0x140610770 / ctor 0x140556560): +8 CModifier* modifier (10597, 写名 = *(mod+424)) / +16 CGameDate date (10314) / +40 u8 ruler_modifier (11487) / +41 u8 permanent (11017) / +42 u8 hidden (11404)。

**CIdeaResearchBonus** (idea def 侧 research_bonus trait, 72B; CPersistentWithToken@0 + THashedKeyValueTrait@16 多基, vtable 0x142981590; Load wrapper 0x140FD4B40): +8 类 token (拷自 owner idea) / +16 32B trait key (+48 FNV-1a u32, Load 现算) / +56 CFixedPoint value / +64 CIdea* owner。writer = CFG 桩 = 不落盘 (def 侧重载重建; 工厂嵌 CIdea loader 0x140FD4C70, 容器 = CIdea+2672)。

**CNationalFocusDependency** (国策依赖条, 56B = malloc 0x38 (focus 成员解析 case 13243) 直证; vtable 0x142739AC8; ctor 0x1402CB990 = vtable@0 + 两个 24B 容器 ctor @+8/@+32): +8 备选向量 {d@+8, c@+20} (Finalize sub_1402D4D90 把 +32 串解析成 focus def 指针灌入, 并写 def+1440 dependents 反向表) / +32 依赖名串向量 {d@+32, c@+44} (成员 reader 0x1402D8690 键 10601 `or` / 13239 `focus` 均 push 此表)。writer = CFG 桩 (focus def 静态成分, 不落盘)。脚本 prerequisite 语义 = **块间 AND / 块内 OR** — 每个 prerequisite 块 = 一条 CNationalFocusDependency 备选组, available 重建 sub_1402D7340 外层遍历依赖组向量, 逐组要求完成集命中任一备选 (组内任一命中即该组满足, 全部组满足才 available); IsAllowed sub_1402D6020 迭代 DFS 用 SAnyOfNode 栈同构 (组节点计数递减到 0 = 满足)。

**CNationalFocusStyleDatabase** (focus style 双 RH 名表; vtable 0x142739A78; 非 TGameItemDatabase): 实体 = 内嵌 **CNationalFocusDatabase+48 起 160B** {+48 vtable, +56 i32=-1, 双 RH map (0x1430868C0 / 0x143086920, load factor 0.90)}; 不与 idb 规格相合, 不可挂 resource.lua key。**finalize 校验器 (sub_141377710, nationalfocusstyle.cpp, 166 行, df305 定案)**: 逐样式插名字集合 — 重名 → :50 "Multiple styles scripted with the name %s, script will only find the first" (**首个赢**); isDefault 旗 (样式对象 +40 u8) 首个定默认 (+56 下标 = −1 初值), 重复默认 → :63 "Multiple default styles scripted, will use %s" (**首个默认赢**); 无默认有样式 → 默认 = 下标 0 + :86 "No default style scripted, will apply first one (%s) instead."; 全空 → :73 "No styles scripted, will create one in code and use that as default." → 代码生成兜底样式入表。**SNationalFocusStyle 176B (RTTI `SNationalFocusStyle::vftable` 直证)**: +8 样式名串 (兜底 "Code Generated Style") / +40 isDefault u8 (兜底 1) / +48 不可用态 GFX 键 (兜底 **GFX_focus_unavailable**) / +80 完成态 (**GFX_focus_completed**) / +112 可开始态 (**GFX_focus_can_start**) / +144 进行中 (**GFX_focus_current**) — 国策图标四态样式表。

#### 4.12.6 CSavedEventTarget (112B, saved_event_target)

内联向量 {data@gs+1728, count@gs+1740}; 元素 112B = CSavedEventTarget;
writer 0X14053C090; eventscope.cpp 断言 "CSavedEventTarget cannot persist
CCombatant" (:0x58E); +106..+111 = 112B 对齐尾 pad。⚠ 该 writer/reader 指纹的 RTTI
持有者实为 **CNullSavedEventTarget** (vtable 0x1427D4438, TNullObject 变体) — 空对象承担
整组读写; 懒单例 sub_140536660 (qword_14332FFC0, malloc 0x70, 先写 CSavedEventTarget vftable
再覆写 CNull 表) — get 按名 miss 时的回退。**键→槽 parse 分派器 = sub_140539530** (vtable槽形态;
14 键: name 27→+104 (串注册 u16) / state 439→+8 / country 10394→+12 (名→tag 管理器 qword_143330D98; **country/state 写入 = 复位全槽语义**, name u16 保留) / character 19478→+16 / operation 12059→+24 (sub_140538BA0 解析; 失败 :1492) / strategic_region 12014→+32 (id → gs+736 区域表界 gs+748 回填裸指针) / unit 10403→+56 / ace 12770→+48 / industrial_organisation 14501→+64 / purchase_contract 19773→+72 / raid_instance 19183→+80 / project 10022→+88 / faction 10877→+96; 三处 "Invalid id for X in saved event target" (:1482 character/:1492 operation/:1517 unit) = load 校验错误收集非断言)。**operator= sub_1405388D0**: name-flag 对齐断言 :49 + 拷后 vtable[9]=IsValid 虚调断言 :51。**scope 侧 per-scope 存储 (§4.00.4 +160) 双容器**: @+0 = 常规 target **按名 u16 排序的有序向量** (lower_bound sub_140534150 / 有序插入 sub_140538170), @+24 = tooltip 同构向量 (节点 = malloc 0x30 双 24B 向量头); **仅外层 scope 的 @+0 容器持久化** (writer sub_14053BDA0 尾段发 13217; tooltip 容器不落盘); Save/Get 函数对 = save_event_target 本体 sub_140539C80→sub_140539B50 (FROM 链 +32 到外层) / **SaveEventTargetTooltip sub_140539E00 (走 +24 ROOT 链, 与常规对唯一链差异)** / get = sub_140537CC0 (常规) / sub_140537D20 (tooltip); GetCharacter sub_140535E00 = +80 idpair → sub_14221F310 → sub_140F9F9C0 二段解析。 writer (0x14053C090) 发射序 = 439→10394→19478→12014→(combatant 非零即断言 :1422)→12770→12059→10403→14501→19773→19183→10022→10877→27 (idpair 门 = 双 dword 任一非零; country 经 sub_140BB4E70 转国对象)。save_event_target 覆盖路径断言 "Invalid scope in SaveEventTarget" :873 (once byte_14332FFD1); 插入内核 :852 断言含 CRefUtils::IsDereferenceLock() 豁免支, 插入返 pair<迭代器, 新插旗>, 已存在走 operator= 覆盖 (0x1405388D0, 拷贝域 +8..+104, 前置同名断言 :49 + 后置 IsValid :51)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CSavedEventTarget | 不序列化 | |
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

发射链: 掷中候选 → **cc+4776 容器** ({data@+4776, count@+4788}; 与 cc+4752 delayed_events 相邻勿混) → CCountry::DailyUpdate 串行段 "country.queued_events" 逐条再复核 trigger → sub_140A0F4F0 (**scope 包装层** — 双 tag 派生: scope+8 国 tag ≤ 0 时回退 scope+168 州 id → 界 [1, gs+724) → gs+712[id] → CState+200 owner tag; sub_140537B50(scope) 返 tag 指针, 调用方解引用取 dword; 断言判定式 = a3[4]==1587985054 && a3[3]==1 = 检出未经播种的帧默认 RNG, 对 §4.00.4 帧重置原语默认种子/计数) → **sub_140A0F6F0 真发射体**: fire_only_once 复核 → timeout_days (ev+1032) 到期时刻 = now+24×days → sub_1401CAFF0 pending_events (gs+1376) 入队 (56B 元 {fire_id/CEvent*/scope*/tag/date×2}; scope = CEventScope 176B 深克隆, §4.00.4a) → AI/hidden (IsAI ∥ ev+1059) 路径逐 option 掷 (sub_141539CB0 trigger + sub_141539B80 CAIMTTHChance 权重) 构造 CSelectEventOptionCommand (sub_141539E40, 240B) 入命令队列; 玩家路径 = idler 虚槽 +240 挂事件收件箱; fire_only_once 落账 sub_1401CA1D0 (§4.12.7); major (ev+1056) → 广播分支 (遍历 gs+784 各国)。

**CEvent** (1064B = 0x428; vtable 0x142999BE8 11 槽 + 第二表 0x142999C40 @+24 名串基视图; ctor sub_14117F1A0; ReadKey = sub_141180B10; 活体抽验 5 实例全对上):

| 偏移 | 类型 | 键/语义 | 置信 |
|---|---|---|---|
| +8 | uint32 | **CIdPair.type = 50** (ctor 写哨兵 qword_14333D528 整 8B; ) | 定案 |
| +12 | uint32 | **CIdPair.id** (writer 键 11 写 +12; fired 表以 CEvent 指针为键非此值; 活体 1000001) | 定案 |
| +16 | uint8 | idpair 已注册旗 (setter 成功置 1) | 定案 |
| +24 | vtable (名串基视图) | 第二 vtable 0x142999C40 | 定案 |
| +32 | SSO 32B | 事件规范名 (id 键反查成功回填; 活体 "denmark_political_events.1"; 原 +32 数组/串两说 — **串说胜结案**) | 定案 |
| +64 | SSO 32B | id 键原文串 (finalize 缺 option 报错打印此串) | 定案 |
| +96 | uint32 | **事件族类型码** (ctor 第二参; 作 +104/+280/+896 子解析 scope): country/news/unit_leader = 4 / state = 2 / operative = 8 (装载器五分支 + 活体双证) | 定案 |
| +104 | CAndTrigger 88B | trigger (10595; vtable[5] Parse 带 +96; 发射门 = +1048 位掩码) | 定案 |
| +192 | CAndTrigger 88B | **show_major** (13801; Parse scope 字面 4) — 原「第二 trigger」键名定案 | 定案 |
| +280 | CEventOption 504B | 内嵌默认 option (序号 −1; immediate 键 10837 → 其 vtable[3]) | 定案 |
| +784 | CEffect 88B | **after 块** (17136) | 定案 |
| +872 | 向量 24B | option 指针向量 {data@872, cap@880, **count@884**, alloc@888}; 元 = malloc(0x1F8) CEventOption (ctor 第三参 = push 前计数 = option 序号) | 10598 |
| +896 | CMeanTimeToHappen 56B | **mean_time_to_happen 块** {类型码@+912, MTTH 基值@+920 (默认 1 天), CMTTHModifier* 向量@+928} | 10596 |
| +952 | 向量 24B | **title 向量** — 元 CTriggeredText* (128B: 文本串 + CAndTrigger) | 10643 |
| +976 | 向量 24B | **desc 向量** (同构; 注册期缺 desc 检查 count@988) | 10644 |
| +1000 | SSO 32B | picture (464) | 定案 |
| +1032 | int32 | timeout_days (ctor 默认 = 全局 dword_143336720) | 14389 |
| +1036 | uint32 | 解析出处·文件 id (Parse override 从解析上下文取 8B 戳) | 定案 |
| +1040 | uint32 | 解析出处·行号 | 定案 |
| +1044 | uint8 | 出处已置旗 (dtor 若置位回写 0xAA 毒值) | 定案 |
| +1048 | uint32 | 系统依赖位掩码 (触发预筛门 `(v & dword_14332F248) == v`); ⚠ 写者 = 0x141180270 (event.cpp:362 段, `*(CEvent+1048) = sub_1401AE680(CEvent+32)`, 该辅助函对名串做 '.' 相关串操作后恒返 0 — 语义未决); 非零写者未定位 (待裁) | 门公式定案 |
| +1052 | uint8 | 国家作用域族旗 (state_event = 0, 其余 1) | 定案 |
| +1053 | uint8 | operative_leader_event 专属旗 | 定案 |
| +1054 | uint8 | unit_leader_event 旗 | 定案 |
| +1055 | uint8 | is_triggered_only (11115; 置位跳过掷骰) | 定案 |
| +1056 | uint8 | major (11241) | 定案 |
| +1057 | uint8 | fire_only_once (11002; fired 哈希键 = CEvent 指针) | 定案 |
| +1058 | uint8 | exclusive (11776; 本轮已掷中一个则其余跳过) | 定案 |
| +1059 | uint8 | hidden (11404; finalize 门) | 定案 |
| +1060 | uint8 | news_event 旗 (12776) | 定案 |
| +1061 | uint8 | fire_for_sender (13947; ctor 默认 1) | 定案 |
| +1062 | uint8 | minor_flavor (12941) | 定案 |

> CMTTHModifier 504B 构成补齐: CAndTrigger 门头 + factor/add 两 CScopedVariable 208B
> (初值 1.0/0), 与 §4.34 MTTH 行完全吻合; CAIMTTHChance 272B 实为 CMeanTimeToHappen 派生类。
> ⚠ 延时事件 writer 路 (sub_141181300 键 440) 读 +32 为串名的旧疑案按串说结案 (见 +32 行)。

option 执行链: 三入口 (玩家点击/超时自动/AI 选择) 同归 **CSelectEventOptionCommand::Execute → sub_14117FA30** (event.cpp:271 "Executing event: %i with option #%i"; idx<0 → 内嵌默认 option, 0≤idx<count → ev+872 元素) → sub_141539B70 = option+288 CEffect 槽[12] ExecuteChecked (vtable+96; §4.00.3 同口径, 内部转调 [13])。option trigger 过滤 sub_141539CB0 (`!opt+501 ∥ opt+500 == immediate` 门 → opt+408 CAndTrigger 槽[3] Evaluate)。玩家事件窗口: sub_14123B0B0 建 "options_grid" 时逐 option 过滤 (窗口+4732 immediate 旗) — **窗口构建时一次性求值, 非每帧**; 超时自动选 sub_14123C410 (gs+1128 ≥ **窗口+4712** 门 → 第一个 trigger 过的 option — ctor 写点 = 窗基址 +4712 CGameDate 值域, 同函数两读)。**option 描述取数 CEvent::GetEffectDesc 0x14117FF90** (profiler 作用域名 "geteffectdesc" 直证): idx ≥ 0 → ev+872 元 option+288 内嵌 CEffect **vtable+64 = 槽[8] BuildTooltip** (§4.00.3 CEffect 槽表口径, 非槽[7] GetDesc); **idx < 0 直写空 std::string, 不取 ev+280 immediate option 的描述** (仅轻量门断言 "Invalid event option index" event.cpp:176)。同簇 0x141180270 另携 option 数校验: count(+884) == 0 ∧ !hidden(+1059) → 日志 "<id 键串> non-hidden event with no options defined" (event.cpp:362; 与 eventmanager.cpp finalize 六检查 (本节下文 eventmanager.cpp 簇) 并存于两 TU, 非同一检查)。

**eventmanager.cpp 簇对账增补 (7 函数闭环)** — **CEvent finalize 六检查 sub_140A0DF40**
(新收): ① !hidden 且 title (+964 计数) 空 ": Event is missing a title." :555 / ② !hidden 且
desc (+988) 空 :557 / ③ option 空 :559 / ④ triggered_only 须 MTTH 基因子 = 1 (:563) /
⑤ !triggered_only ∧ MTTH == 1 天 ∧ !fire_only_once ": Event is set to trigger every day."
(:566) / ⑥ unit_leader_event 强制 triggered_only (:568) — 错误级 = log 非 fatal, 前缀 =
CEvent+64 id 键原文; MTTH 存储单位 = 1e-5 天。**五事件键分派表** (装载循环 sub_140A0E770,
全部 malloc 1064): country_event(10127)/unit_leader_event(14817)/news_event(12776) → 类型码
4 / state_event(10128) → 2 / operative_leader_event(19265) → 8; 旗写点 +1052/+1053/+1054
/+1060 全在语料对上; add_namespace (12373) = 全局命名空间登记表 {qword_14332F368 组, 40B 元
{名 SSO 32B, hash u32@+32}, stricmp+hash 双查重, 1.5× 扩容}。**命名空间 id 公式 (定案): id = 100000 × (登记槽序 + 10) + key 数字部分**; 裸整数字面量 id 域 < 1000000 (0xF4240 上限), 与命名空间域 ≥ 1000000 不相交; id 解析器同模板家族三实例 = 类型 50 event id 装载侧 sub_1411804E0 (CEvent 装载 case 11; 串分支查表 A + sub_14221E700 全局 id 登记与唯一性反查, 失败日志 namespacemanager.h:209 "Reverse id lookup") + **类型 50 脚本侧 sub_1401E5630 (第三实例, 不登记变体; 整数字面量 ≥ 1000000 即标错返 0, 标识符串 sub_1401F0720(串, 0) 查表 A; 其他类型兜底断言 :259 "Unexpected Type" + 日志 :260; 调用链 = on_action 随机事件 id 解析 sub_140A7A1C0 / 装载伴生 sub_141180910 / 事件容器装载域 sub_1401E59D0)** 与类型 72 operation id sub_140538BA0 (eventscope.cpp:1492 存档事件目标 operation 域; 查**静态表 B** qword_14332FFD8 — 运行期零写点恒空 = 负定案, 串形态解析必失败; 脚本值 type 12 = 整数字面量 / type 15 = 标识符串 三函一致局部定案; sub_1401F0720 第二参模式位 = 装载路 1 / 脚本路 0, 语义待裁); 表 A 读者主路 = sub_1401F0720 (脚本 id 解析海量调用), 表 B 读者 = sub_14053B9D0。**mgr+12 = 事件 id 映射** (值对象+48 = 该 id 当前事件指针);
热重载旧事件经此取出 → mgr+48 staging + 消费数组摘除 + sub_1401DA380 gs 注销 (装载侧补全);
boot 并行 sub_140A0C190 (tbb "Short Task", 描述符 +472 待载旗/+136 游标, 循环后串行尾调
"Events loaded <描述符>' #<条目计数>" 日志包装 sub_140A0D340 一次; 门 = 描述符+472 待载旗, 游标 = 描述符+136, 装载循环 = sub_140A0E770(管理器, 游标, 描述符, 0=boot) 返条目计数); 单文件热重载 sub_140A0D9A0 (惰性构造 CEventManager
单例 224B → E770(a4=1) → "no errors"/"<n> errors." 报告)。

**发射体 sub_140A0F6F0 补全** (主干互证一致): a6 = **immediate 旗** (定案, "PerformImmediate
<title>" 日志 + "immediate" profiler 作用域内执行 ev+280 默认 option effect = 脚本 immediate
块); AI 加权随机选项种子 = scope+168 + 同原初国 idx + gs 派生量混合哈希 &0x7FFFFFFF **%100**
(即包装层断言所指 "Scope.GetRandom()" 实现域, 非全局裸随机); 无可见 option → ": No valid
option for event" :387 且不发射; major 广播门 = ev+1056 ∧ a6 ∧ show_major trigger
(sub_1411812A0 = profiler 串 "major_trigger" 执行点直证) ∧ cc+1156 > 0 ∧ 非同原初国 → 递归
重发射; 发射尾 216B UI 通知 {载荷码 3, kind 1} 尾插 handler+1192 (§4.00.4a kind 分发表新
实测组合)。**F5A8 fired 计数器组补全布局** {data F5A8 / cap F5B0 / count F5B4 / alloc F5B8,
门 byte_14332F5A0, 索引 = CEvent+12; 唯一写点 = 发射头}。pending 查重原语 sub_1401DAE70 =
gs+1376 线性扫 (计数 gs+1388), 匹配 (CEvent*, scope 相等) 返 fire_id。

#### 4.12.9 CDelayedEvent 生命周期 (延时事件通道; 布局 = §4.3.11 delayed_event 表)

类布局、容器 (cc+4752 data / cc+4764 count) 与元素存档键 = §4.3.11 (元素 0xC8; vtable 0x1427E7488 / writer sub_141181300 / reader 0x141180910 / ctor 0x14117F120; +16..+191 内嵌 CEventScope 递归表同节)。与定时决策 CTimedDecision (§4.12.2) 无亲缘。运行链 (定案):

| 阶段 | 链 | 语义 |
|---|---|---|
| 创建 (入队) | 事件 effect 族共用 Execute **sub_141393950** (country_event = CCountryEventEffect token 10127 / news_event = CNewsEventEffect 12776 / state·unit_leader·operative_leader_event 系同构) | 定位 CEvent ({type=50, id} idpair RTDynamicCast 或名) → 延时小时 = eval(+1232) + 24×eval(+1440 days) + 720×eval(+1648 months) + random [0, eval(+2064)) (门 +1856; 载荷槽族 = §4.32.1.1 事件族骨架行) → **延时 >0: sub_1406D0880(接收国, event, &originator, scope, hours) 入接收国 cc+4752**; 延时 =0: 当场 sub_140A0F6F0 直发 (不入队) |
| 等待 | **sub_1406FC980** (profiler "country.delayed_events"; hourly pass⑥ 复合体 sub_1406FD800 首调, §4.2.6) | 逐元素 `--(elem+196)` 每小时递减; bypass = byte_14332F61A ∧ !sub_1406FFDB0(cc) (human_ai 旗参与 AI 判定); 元素+8 空 → "Corrupt event." (country.cpp:13436) |
| 到点 | trigger 复核 → 发射 | 造 scope (country = cc+8 属主) → CEvent+104 trigger 复核 (sub_141180350 槽[3]) → 过 = **sub_140A0F6F0(CEventManager 单例, ev, &elem+192, &cc+8, scope, 1)** = §4.12.8 真发射体 — **到点后与掷骰命中事件走同一条发射链, 无独立链**; 复核失败 → 静默删除; 哨兵门: CEvent+8 == qword_14333D528 (多处用作「无事件」填充; 推定无效事件标记, 待裁) → 不发射仅移除 |
| 移除 | swap-remove | 尾元补位 + cc+4764-- + vtable[0] 析构 |
| 读档 | delayed_event 块 (键 11463) 逐元素重建 | 事件解析失败 ("Invalid event id") → 元素静默丢弃 (元素+8 空不 push) |

> ⚠ cc+4752 (本通道 = 显式延时 hours/days/months, 纯 hourly) 与 cc+4776 (queued_events = MTTH 掷骰命中, 每日检查调度 §4.12.8) 相邻两通道勿混。

#### 4.12.9b on_action 系统 (onaction.cpp 装载与执行)

**COnActionDataBase** (336B; TGameItemDatabase 模板宿主; 单例旁 qword_143339E80 = 全局 Null Object; 装载总入口 = sub_140A79930: +312 表对齐国数扩容 → 枚举目录 *.txt → 逐文件 sub_140A760D0):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | Lookup 引擎数组 | {data@+40, cap@+48, count@+52}; 元素 40B {名串 32B, token u32@+32}; 分配器 +56 |
| +64 | Array 引擎数组 | {data@+64, cap@+72, count@+76}; 元素 = COnActionList*; **Array[0] = Null Object** (helper.h:35 断言「Array 比 Lookup 大 1」); 分配器 +80 |
| +88..+304 | COnActionList* ×28 | PostLoad 具名缓存 28 槽 (下表) |
| +312 | 按国三列派发表 | 引擎数组 {count@+324}; 行 24B = 国 idx (1 基), 列 +0=on_daily_ / +8=on_weekly_ / +16=on_monthly_ (F1 直写三列; §4.26.7 既载三槽即列 1-3) |

**COnActionList** (216B = 0xD8 malloc 直证; maxoff 312 系 DB 侧 a1+312 误聚合):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +8 | uint32 | 名字哈希低 32 位 |
| +16 | vtable* | 第二基 (CProfiledScopeObject) |
| +24 | uint8 | 有效位 (0 = Null Object — 查名落空无害化, 执行器直接返回) |
| +32 | string 32B | on_action 名 |
| +64 | uint32 | 名 token (空对象 = −1) |
| +72 | 引擎数组 | **random_events 表** {count@+84}; 元素 8B {事件引用 u32@0, 权重 u32@+4}; 分配器 +88 |
| +96 | 引擎数组 | **events 直挂表** {count@+108}; 元素 4B 事件引用; 分配器 +112 |
| +120 | CEffect 88B 内嵌 | `effect = {...}` 效果块 (Parse 键 89 转发其槽[3]; 执行 = **槽[12] ExecuteChecked vtable+96**) |
| +208 | uint32 | random_events 权重累加和 (写点 = Parse 侧每条 `*(a1+208) += weight`; 读侧消费点未决) |
| +212 | uint32 | 建立时 Array 索引 (ctor 读 DB+76 计数; 精化: 原「装载批次号」) |

查名原语 = sub_140A792B0 → sub_140A75940 (纯线性扫 Lookup: **token u32 相等预筛** (元素+32) + stricmp 确认, 无桶无哈希表; **未命中返 Array[0] Null Object 非 nil** — 查名即执行永远安全)。F3 Parse (vtable[3] sub_140A7A1C0, VA 钉定): 键 11353 random_events (校验门 byte_14332EC69 开时查无效事件报 :58) / 键 11354 events / 键 89 effect。PostLoad (vtable[2] sub_140A774B0) 28 槽缓存表: +88 on_army_leader_daily / +96 on_army_leader_won_combat / +104 on_army_leader_lost_combat / +112 on_navy_leader_won_combat / +120 on_navy_leader_lost_combat / +128 on_army_leader_promoted / +136 on_deployed_leader_defeated / **+144 on_daily / +152 on_weekly / +160 on_monthly (书既载三槽即 8-10 号)** / +168 on_generate_wargoal / +176 on_send_volunteers / +184 on_market_access_rights / +192 on_non_aggression_pact / +200 on_lend_lease / +208 on_guarantee / +216 on_improve_relation / +224 on_cancel_foreign_manpower / +232 on_boost_party_popularity / +240 on_stage_coup / +248 on_embargo / +256 on_request_licensed_production / +264 on_transfert_spymaster (引擎拼写非 transfer) / +272 on_request_foreign_manpower / +280 on_docking_rights / +288 on_military_access / +296 on_offer_military_access / +304 on_offer_air_base_access。尾链: 空军王牌/政治/timedactivity 三域缓存 PostLoad 扇出 (sub_140F85C30/0x140E4FED0/0x140ADCAC0 — 王牌 on_action 全局族 qword_14333D5F8..628 即此路填充) + "on_ruling_party_change_immediate" 弃用警告 (:390; 门 = +24 存活 ∧ 列表+140 — 内联 CEffect+20, 推定 effect 非空旗, 待裁)。

装载语义增补 (体读定案): ① **跨文件/同文件重名 = 合并追加** — 文件级装载 sub_140A760D0 查名命中且 +24 存活时**复用已有 COnActionList 对象**, 随后对其**无条件再调虚表槽[3] Parse** (sub_140A7A1C0): `effect` 键转发内联 CEffect+120 的槽[3] (token 流**追加**, §4.00.3 块 Parse 语义), `random_events` 逐条 push 进 +72 且 `*(a1+208) += weight` 累加, `events` 直挂表同追加 — 三通道全程无清空/去重, 同名多块 (跨文件 + 同文件) 全部叠加生效; 合并序 = 目录文件名字典序 × 文件内块序 (mod 压 vanilla 由 PHYSFS 挂载序决定)。② 装载器外层键 13527 = "on_actions"; 装载总入口开头重扩 +312 按国表 (×1.5 保底) 并清零新行。③ **掷骰体 sub_140A79410** (分派壳内联第二步, VA 钉定): 有效权重 = weight × CEvent+896 MTTH 块合成因子 (sub_1405520E0: 基值 +920 × ∏匹配 factor@项+88 / 1e5) / 1e5; 掷骰 = Random::Get("onaction.cpp", 196) & 0x7FFFFFFF % 总权重 → 累计权重线性扫描; **id=0 条目 = 「无事发生」概率质量** (占权重不发射; Parse 侧允许 push 不报错)。④ PostLoad 后 18 槽名串 = "on_" 前缀 (dword_14293EE74) + sub_1424BC260(token) 拼名, token id 按槽序 +200..+304 = 12618/10458/11479/19136/12525/13423/12916/14271/19141/19135/15098/10548/12232/10325 (前 14) 与 +168..+192 = 13339/13333/13696/12220 (抽验对 s4_10 全一致)。⑤ 错误报告三家族辨析: :492/:274/:175/:58/:85 = CLogStream 一行式错误日志 (sub_1424C9240 + sub_1424C9AE0 160B 栈对象 + 追加族 + sub_14011DD90 冲行), 非 throw 非 assert — 体内 ios/terminate EH 胶水系 ostream 构造噪音, 勿当 throw 判据。⑥ **死钩子 (排雷)**: `on_mio_tech_reseach_cancelled` / `on_mio_tech_reseach_completed` — 引擎派发名 strcpy 拼错 (Reseach; 派发点字面量直证), 原版脚本文件用正确拼写 `on_mio_tech_research_*` → 查名 (token 预筛 + stricmp 双关, sub_140A792B0) 永远落空 → 正确拼写的钩子定义永不触发; 引擎侧无正确拼写串, 想挂载须用拼错名。

decision.cpp 簇对账增补 (10 函数闭环; 决议装载/采纳/序列化侧):

**CPersistent 次基 this 调整定式** (方法论级定案): 决议族双基类 (CDecision /
CTimedDecision / CTargetedDecision) 的 writer/reader/ReadKey/Finalize 经**次基 CPersistent
vtable (vtable@8) 槽位派发, this = obj+8** — 三重直证 = 状态 writer 传 elem+8 (0x140738AA0) /
reader 内联构造双 vtable 后 `(vtable2[3])(obj+8)` (0x140733A20) / ReadKey 自证 `a1-8`
(0x140732770)。此类函数体内偏移一律 +8 才是对象视角。CDecisionStatus (主基@0) 与
CDecisionCategory (parse 走主基) 不调整。**次基 vtable slot[8] = 读后定稿钩** (新观测:
装载器对每新 CDecision 依次调 slot[3] parse 再 slot[8] 定稿; 家族泛化待更多样本, 推定)。

**装载链** (定案): 类别装载器 sub_140726190 (malloc 1016B CDecisionCategory, ctor
sub_140723750, 重名抛 "Duplicate category" :4547; **cat+24 = 类别名串**) → 决策装载器
sub_1407264D0 (malloc 0xD38 = **3384B CDecision** ✓书; 逐件 slot[3] + slot[8]; 尾日志
"Decisions loaded" :4520) → 注册器 sub_140725F50 (重名抛 :4529 → cat+496 push + 名索引);
决策管理器 {类别指针数组 @mgr+88..104 (id 即下标) / 名字索引 @mgr+112 / 已载计数 @mgr+52 /
决策名索引 @mgr+40/64}。

**CDecision 新字段落位约 25 行** (ReadKey 键表全录, 定案): obj+1032 = **complete_effect
效果体** (采纳以 vtable[13] Execute 发射 — 书表缺行) / obj+1120 remove_effect (14549) /
obj+640 remove_trigger (14818) / obj+728 cancel_trigger (14819) / obj+1568
custom_cost_text / obj+1728/1752/3208 war_with_on_{complete,remove,timeout} +
obj+3232..3234 war_with_target_on_* bool / obj+2401 is_good + obj+2402 fixed_random_seed +
obj+2403 cancel_if_not_visible / obj+2408 priority / obj+328 name 覆盖串 / obj+1512 icon
数组 / obj+816 modifier 块 (容器头, 列表体 = obj+832) / **obj+1008 targeted_modifier 544B
元列表 {d, n@1020}** / obj+1688 cosmetic_tag / obj+1720 cosmetic_ideology / obj+2416
highlight_states / obj+1504 ai_hint_pp_cost / obj+3344 power_balance 串 / obj+2800/2804
highlight_color_before/while_active (Finalize 对 BORDER_COLOR_CUSTOM_HIGHLIGHTS 计数越界
钳 -1) / **使命旗组 obj+2816 = is_timed byte (定案: sub_140731E80 单行直证; 「timeout 值同槽
19967」异说待裁 — 值对象定案在 +2824, sub_14072F040) / +2817 = selectable_mission 键槽
(键写旗, 运行时作 targeted 判定, 两读兼容) / +2818**。Finalize 定稿规则: 目标字段全空 → on_map_mode 压 1 ✓书; modifier 有而 days_remove
无 → 警告 :488; 使命成本未实现警告 :493。

**采纳执行双通道** (定案): 非目标化 sub_140727AE0 — bypass 全局旗 byte_14332F632 直通 ✓书;
成本纪律 = (obj+1620 非零 ∨ 普通使命对) → 成本强制 0, 否则 obj+1296 宿主求值扣除
(与 :493 警告互洽); complete_effect vtable[13] 发射; 状态入账 sub_140737E00。目标化
sub_140735910 — 双使命旗选 ds+256/:232 槽 → find-or-create → **targeted available 求值器
独立 = sub_140731670** (非目标化 = sub_1407313C0) → days 求值 0 压 1。**键 14541
decisions_taken_fire_once = 读后丢弃不恢复** (reader 只吞块)。

CTimedDecision days 键双 token (10605 days 与 12656 hours 同槽同读无换算, 待裁)。
CTargetedDecision 目标枚举器 sub_140727260 (def+272 类别字节 1..4 分派四路 resolver;
def+33 区分动态/静态目标路)。未决: 键 10283 真名 (vanilla 表 = deploy_army_hq, 落点为
成本宿主疑 token 复用); obj+1304 字节; hours 无换算; slot[8] 泛化。(obj+1620 语义已收口
= custom_cost_trigger 存在旗, 见 def 偏移表。)


**decisionviewutil.cpp 决议视图状态码域 0..12 (四函新收)**: 种类枚举 {0 普通, 1 timed, 3 targeted} (值 2 缺席; sub_14072E350 或直读 +28), **种类==3 → 码 12 全域短路**。分类器全量版 0x1417236E0 / 对偶版 0x141723970 (同谓词族 sub_1407313C0/726C20/72B400, 两入口形态)。状态码→GUI 配置器 0x1417242E0: 分组 {0,1,2,3,10,12} 双元件隐藏 / {4,11} B400 时长 / {5-9} F040 时长 + 条目+2401 特殊位; 视图元件 **+117 byte bit4 = 隐藏旗**; 进度条 = 1e10×a5 mod (1e5×时长) 防溢出定点模。三档映射器 0x141724200: {0,5,8,12}→1 / {1,2,6,7,9}→2 / {3,4,10,11}→3 (vtable 槽[22]; **与 GUI 配置分组不一致, 两映射独立勿互套**)。"Decision should not be in the interface." :94/:117/:150/:175 / "Unimplemented interface state for decision" :343/:382。

#### 4.12.10 事件域引用本地化键收集器 (1 函 = 0x1402256B0, 推定)

0x1402256B0: CEventManager 单例两向量喂入 → 三容器 (串@+8/+376) → set\<string\>; 过滤 = 全空白 (sub_1424CCBC0) ∧ FNV 键存在性 (sub_14239D0F0 → 本地化 DB qword_1435BA038)。用途推定 = 事件本地化键引用清查 (开发期工具通道), 宿主与调用侧待裁。
