

### 4.2 游戏时序 (时间推进驱动链 / 每小时 tick 调度 / 日期边界)

> **本册定位**: 引擎如何把现实时间换算成游戏小时推进, 以及每个游戏小时的
> 完整调度顺序 (hourly/daily/weekly/monthly/yearly 各粒度的分发点)。
> 字段布局归各本体分册 (CGameState 字段归 §4.1, CSession 归 §4.28,
> CCommand 派生族归 §4.33); 本册记**顺序与触发契约**。
> 时间推进在引擎内是「命令」: 与玩家指令同一命令管线, 联机同构。

#### 4.2.1 驱动链总览

应用主循环链 (定案):

```
WinMain (0x1425896A0) → main (sub_140126E50: SDL_Init/日志/tbb 自举)
  → CGameApplication::Init (虚表槽[9] = 0x140180BC0; gameapplication.cpp 日志链)
      InitGame 内 malloc 0x640 构造 CFrontEndIdler 并 SetIdler = 前端菜单 idler
  → CApplication::Run (sub_14222E7E0, noreturn; application.cpp 族)
      主线程钉核 → StartUp (虚表槽[10]: 单实例检查) → while 帧循环:
        sub_14222EEB0(app, 1)   每帧一步
      → SteamAPI_Shutdown / exit
```

每帧一步 sub_14222EEB0(app, a2) (clausewitz random.h:74 主线程断言):
dt = now − app+792 (先算) → **idler 派发 `*(app+56) 虚表槽[4] = Idle(idler, a2)`**
→ idler 切换段 (+64 请求旗: 旧 current 进 +120 调 OnSuspend/OnLeave, +112 待入 →
+56, 对新 current 调槽[11] OnEnter/槽[5]/槽[9]) → 帧计数 app+816++ → a2=1 时按
`1.0/设置帧率` 睡眠限帧。

| 段 | 函数/对象 | 语义 | 证据 |
|---|---|---|---|
| Idle 本体 | CInGameIdler::Idle (0x140DD3A50, 基类 CGameIdler 虚表槽[4] 覆写) | 游戏主循环体; CFrontEndIdler 覆写同槽 = 菜单场景 | 虚表 0x142968FF0 槽[4] 直读 |
| 暂停门 | `帧耗时 && !this+1729 && !this+1732` | 权威暂停位不通过则不调调度器 (时间冻结) | this = CInGameIdler 实例; 1729 = §4.1.2 已载暂停位 |
| 调度器 | sub_1401F0590(gs, dt) | 小时进度累积 + 到点生成 CHourlyTickCommand; **门 qword_14332F6A0 非空** (OnEnter setterB 写; 菜单态为 0 → 空操) | 本体反编译 |
| 入队 | sub_142250B00(session, cmd, flag) | 命令发送 (session.cpp:374): 盖 tick 号 cmd+22 = min(session+128, 0x7FFF) → server 虚表槽[5] (字节+40) 入队 (server.cpp:319) | 单机 server = CDummyServer (0x142B52C28) |
| 派发 | sub_142252D00(session) | 命令派发循环 ("Executing command: "/"Discarding command: " 日志; "Update within execution. Skipping." 防重入 session.cpp:600/629) | session.cpp 日志串 |
| 执行 | CHourlyTickCommand::Execute = 0x140F06BF0 | 虚表 0x142976F78 槽[10] (与 §4.00.3 CCommand [10]=Execute 定案一致) | exe 虚表直读 |
| 推进 | sub_1401DD370(gs, 载荷) | gs hourly tick (§4.2.4 骨架) | 本体反编译 |

idler 单例与切换 (定案): 全局 qword_14332F698/qword_14332F6A0 由 **OnEnter (虚表槽[11])**
写入 — 前端 CFrontEndIdler::OnEnter (sub_140B3E1F0) 只写 F698; 游戏内
**CInGameIdler::OnEnter = 0x140DE0150 (jmp thunk → setterB sub_1402A2A30): F698 = F6A0 = this**。
游戏内运行时 idler 实例 = CInGameIdler (CFrontEndIdler 派生), 主虚表 0x142968FF0
(基表 0x142949D50 的槽[64..69] 全为 return-0 桩 — 菜单态脉冲空操的机制根源)。
SetIdler = sub_14222EA60 (写 +112 待入 + 置 +64 请求旗)。

> 备注: 暂停拦截在**生成侧** (不生成 CHourlyTickCommand), 不在 Execute 侧;
> 暂停不清空累积器 gs+1208 已有进度。一帧最多推进一小时 (gs+1216 tick 标志)。

#### 4.2.2 时间推进调度器 sub_1401F0590 (小时进度累积)

| 步 | 动作 | 细节 |
|---|---|---|
| 1 | 取速度档 | `v = gs+1212` (§4.1 已载 speed u32, 键 110) |
| 2 | 取每秒速率 | 自定义表 `dword_1433386CC` (长度) + `qword_1433386C0` (float*) 非零时用之 (mod/调试可覆盖), v clamp [0, 长度-1]; 否则默认表 (下表) |
| 3 | 时间加成 | sub_140DC7290: `min(2.0, 1.0 + 0.2 * idler+2396)`; idler+2396 = 加速脉冲计数, 每次 tick 生成后减 1 (sub_140DE4DE0, clamp 0) |
| 4 | 累积 | `gs+1208 (float) += dt / (速率 × 加成)`; 速率 ≤ 0 时直接置 1.0 (立即推进) |
| 5 | 生成 | `!gs+1216 && gs+1208 ≥ 1.0 && session+84` → 重置 gs+1208 = 1.0f, 就地构造 (sub_140F057A0) CHourlyTickCommand (载荷 = qword_14333CEA8 checksum 数组) 并入队 |

默认速度表 (栈上 5 项; 前 4 项整块来自 `xmmword_142724360`, 第 5 项 = 表副本紧邻
槽置 0; 值 = 现实秒/游戏小时, 定案):

| 下标 (= gs+1212 值) | 秒/小时 | 语义 |
|---|---|---|
| 0 | 2.0 | UI 速度 1 (最慢) |
| 1 | 0.5 | UI 速度 2 |
| 2 | 0.2 | UI 速度 3 |
| 3 | 0.1 | UI 速度 4 |
| 4 | **0.0** | **UI 速度 5 = 不限速**: 速率 ≤ 0 分支直接置累积器 1.0 → 每帧立即生成 tick; 硬上限 = 每帧一小时 (gs+1216 门) |

#### 4.2.3 CHourlyTickCommand::Execute 与 CSession 状态枚举

CHourlyTickCommand 本体布局归 §4.33 (id 12092); 此处记行为槽定案:

| 槽 | 值 | 语义 |
|---|---|---|
| [10] Execute | 0x140F06BF0 | 见下步骤 |
| 构造通道一 | sub_140F057A0 | 就地构造 (本地生成, 唯一调用点 = sub_140F0590) |
| 构造通道二 | sub_140F05A30 | 从网络包模板拷贝构造 (联机) |
| 构造通道三 | sub_140F05C80 | 无参工厂, 注册于命令工厂表 (注册号 3092, 反序列化用) |

Execute 步骤 (定案):

| # | 动作 |
|---|---|
| 1 | gamestate 断言 (gamestate.h:1116/1117) |
| 2 | 读 `session+72` (sub_140CE9520), **≠ 13** 才调 `sub_1401DD370(gs, cmd+40 载荷)` |
| 3 | session+84 为真时遍历玩家条目 (gs+260 计数, 160B/条), 对国家 id ≠ 本地且超时的发 0x50B 掉线命令 (两分支: gs+1212≤0 走 sub_140DE5F90 构造入队, 否则虚表+760 直发) |

> 备注: session+72 = **CSession 联机状态枚举**, 13 = HOTJOIN_WAITING_FOR_SAVE
> —— `≠13` 门 = 「热加入等待存档的客户端不推进时间」, **不是暂停检查**
> (暂停门在 §4.2.2 生成侧)。

> CSession 状态枚举全表 (19 值, session.cpp:269 SetState switch, 定案) = **§4.28.11** (CSession 布局所有权册)。

#### 4.2.4 gs hourly tick 顺序骨架 (sub_1401DD370)

定义 0x1401DD370 (gamestate.cpp 族)。每次 CHourlyTickCommand::Execute 调一次;
第二参 = 命令 +40 载荷 (checksum 数组, 联机对比用)。顺序定案:

| # | 粒度 | 动作 |
|---|---|---|
| 1 | 每小时 | 构造 CClientPingCommand (0x48B, 含当前日期) 并入队 |
| 2 | 每小时 | `gs+1216 = 1` (tick 进行中) |
| 3 | 每小时 | 保存旧日期分量 (旧日/旧月/旧年积日/旧年) |
| 4 | 每小时 | `CGameDate 虚表槽[1] (gs+1120, 参数 1)` = **Advance 1 小时** |
| 5 | 每小时 | 重算日期分量缓存 gs+1144/+1148/+1152/+1156/+1160 (dword_143085210 = 闰年月首累计日表) |
| 6 | 边界 | 计算四布尔: 换日 (日分量变) / 换周 (换日且总天数 %7==0) / 换月 (月索引变) / 换年 (年积日变) |
| 7 | 边界 | profiler 日期粒度采样 sub_140BBBEA0 (gs+2008): 五槽打点 "Hour"/"Day"/"Week"/"Month"/"Year" (性能采样, 非游戏逻辑; 见 §4.2.5) |
| 8 | 联机 | checksum 对比: sub_140DB1830 算本地 vs 载荷 → OUT_OF_SYNCH 判定与日志 (gamestate.cpp:4744-4795); CNetworkServer/CProxyServer 或 debug 旗才走 |
| 9 | 每小时 | 遍历 gs+2240 容器 (计数@+2252): 每 tag 查 _AllPlaythroughData (gs+2200, §4.1.8) → 条目 = **NCareerProfile::SPlaythroughCountryData** (2488B, vt 0x142721478), 在其 +2064 的 **SCareerProfileIntermediateStatistics** 上调三函数 = **9 条 CTimeSeries 滚动统计窗口推进** (2 月窗 24 / 6 时窗 48·12·48·48·48·96 / 1 日窗 30) — 生涯档案统计域, 非模拟逻辑 (月边界 sub_14069D160 / 日边界 sub_140694E60 / 每小时 sub_140699C10) |
| 10 | 每小时 | **sub_1401DF400(gs)** = hourly 游戏逻辑主调度 (§4.2.6) |
| 11 | 日 | **sub_1401D4810(gs)** = daily update |
| 12 | 周 | (日边界内) **sub_1401F2430(gs)** = weekly update |
| 13 | 月 | **sub_1401E34F0(gs)** = monthly update (月份==5 即 6 月仅 profiler 包装, 无额外调用) |
| 14 | 年 | (profiler 域 "gamestate.yearly") 遍历 **gs+784 国家指针数组** ({data@784, cap@792, count@796}, 槽 0=哨兵, InitGameState 尾注册) 逐国调 sub_14071A940 = 清理 cc+656 师列表中师+840 CEquipmentVariantPool 零值条目 (门 = allow_zero u8@师+896==0); 后 sub_140207890 = PDX SDK 遥测批 (country_count / in_game_date / nr_country / nr_dynamic_country) |
| 15 | 分发 | CInGameIdler 主虚表 0x142968FF0 槽: 槽[64] (字节+512, 0x140DDA020) 每小时 = GUI 日期脉冲 + idler+2216 倒计时/idler+1680 旗 / 槽[65] (+520, 0x140DD9740) 日 = gs 四连到期清扫 + GUI 日刷 + 游戏条目日期激活 / 槽[66] (+528, 0x140DDAC60) 周 = GUI 周脉冲 + 超 100MiB 日志轮转 (filelogger.cpp:256, 备份数 6) / 槽[67] (+536, 0x140DDA1B0) 月 = 月脉冲 + GUI 大刷新 / 槽[68] (+544, 0x140DD9FF0) 月==5 / 槽[69] (+552, 0x140DDACC0) 年 — GUI 侧薄脉冲 (驱动 iface (idler+1720, CInGameInterface) 的六档节拍注册表; 布局与家族归 §4.28.14) |
| 16 | 每小时 | **sub_1401D6290(gs)** = hourly 收尾调度 (§4.2.6) |
| 17 | 每小时 | sub_140BBED50(gs+1248) = CPeaceConferenceManager (§4.1 已载 @+1248) 每小时处理 |
| 18 | 每小时 | `gs+1216 = 0`; 错误检查 (gamestate.cpp:4980); `gs+1208 = 0` |

> 备注: 骨架各阶段间反复出现的块 (`byte_1430864E0 门 + sub_1402A3210 帧间隔判定
> [预算表 flt_1427361C0 = 0.0166..0.05s] + sub_14222EEB0(mgr, 0) + 虚表+136/
> sub_142253AF0`) = **长 tick 帧保活重入**: 判定距上次步进已到帧间隔则同步重入
> 一帧 (a2=0 不限帧), 使存档/长计算期间窗口不假死; mgr = CInGameIdler+1328 所存
> 管理器 (CApplication 本体)。不是 profiler, 不携带游戏语义。
> 备注: 步骤 15 六槽 = GUI 侧节拍脉冲 (§4.2.4 内联); 步骤 10-14 内容分别见
> §4.2.6 / §4.2.7 / §4.2.8 / §4.2.10 / §4.2.11。

#### 4.2.5 日期边界判定与 profiler 采样器

边界计算 (定案): 旧日/旧月取自 Advance 前的 CGameDate 分量读数; 总天数 =
`(hours − 43800000) / 24`; 换周 = 换日且 `总天数 % 7 == 0`; 年积日 = 总天数 % 365;
月索引经 dword_143085210 累计表折算。

profiler 日期采样器 sub_140BBBEA0(a1=gs+2008, 日期, 日/周/月/年布尔):

| 槽偏移 (十进制) | 触发 | 标签 |
|---|---|---|
| +16 | 每小时 | "Hour" |
| +24 | 换日 | "Day" |
| +32 | 换周 | "Week" (附带子调用 sub_1424DF900 = VFS IsValid 检查) |
| +40 | 换月 | "Month" |
| +48 | 换年 | "Year" |

> 备注: 每槽动作 = sub_140BBC400 累计耗时/计数并写 "%s\t%s\t%f\n" profile 行;
> a1+8 为启用门。**这是日期粒度的性能采样, 不派发任何游戏逻辑**。
> 备注: 启用入口 = 控制台 `gamestate_timer`/`gstimer` 或启动参数
> `-gamestatetimer`; 产物文件 = logs/gametimer_<时间戳>.tsv; 工具全貌见 §4.9。

#### 4.2.6 hourly 主调度 (CGameState::HourlyUpdate, sub_1401DF400)

profiler 域 **"gamestate.hourly"**; gamestate.cpp:5918-5920 断言窗口 (定案)。
系统序列 (按函数体顺序):

| 序 | 子系统 | gs 槽 | 要点 |
|---|---|---|---|
| 1 | 军队状态小时统计 | +2416 | **CUnitMetricsCollector** (unitmetricscollector.cpp 定名): 收集开了 +413 IsCollectingMetrics 旗的作战计划编组, 14 键按小时窗口累计, 写 logs/metrics/*.log — **纯遥测, 默认关闭, 不进游戏逻辑** |
| 2 | 三数组预收集 | +2464 族 | 全体国家数组 (门 = 有资州或收容流亡政府) → DoCountryHourlyUpdates / AI 策略数组 (就绪检查+预热) → ai_update / 国家下标数组 (gs+2464) → 战略空军 |
| 3 | 补给 | +984 | **CSupplySystem::UpdateSupply(bool)** 12 阶段 (§4.2.12) |
| 4 | 突袭 | +1008 | 相位机推进 + 情报阈值预警 (§4.2.14) |
| 5 | 天气 | +1672 | 昼夜并行 + 区域状态机 + 确定性翻面 (§4.2.15) |
| 6 | 战略空军 | +1680 | **CStrategicAirManager::HourlyUpdate** 12 步 (§4.2.17) |
| 7 | 战略海军 | +1688 | 串行维护遍 + 并行重算遍, 国序 %24 错峰 (§4.2.16) |
| 8 | 谍报/特工 | +1696 | sub_140EB2EC0: 有特工时逐元素七连推进 (sub_1412002E0/17C0/1B60/0DF0/14C0/1FF0/23C0, NOperativeMissions 任务族) + 尾置单例 +82 脏旗 (**勿再引"空更新"旧说**) |
| 9 | 阵营 | +1016 | **CFactionSystem::HourlyUpdate** (§4.2.18) |
| 10 | playthrough 监听查询 / autoexit 检查 | | "g_ExitOnTriggerText was invalid" |
| 11 | **DoCountryHourlyUpdates** (sub_1401D85A0) | | 六阶段, 见下表 (gamestate.cpp:5216/5259) |
| 12 | 战斗 | +608 | CCombatManager 每小时推进 (§4.2.13) |
| 13 | **ai_update** (sub_1401D7E40) | | 收集的 CAICountry 策略数组以作业 "Short Task" 并行发射 |
| 14 | DoCareerProfileHourlyUpdate | | |

> 备注: 每两子系统间夹一个**帧保活重入块** (§4.2.4 备注: byte_1430864E0 门 +
> sub_1402A3210 帧间隔判定 + sub_14222EEB0(mgr,0) 重入一帧), 防长 tick 假死,
> 非游戏语义。

DoCountryHourlyUpdates 六阶段 (profiler 名定案):

| 阶段 | profiler 名 | 内容 |
|---|---|---|
| 0 | — | 双键排序: `cc+5488` (**每国小时更新耗时 EWMA, α=0.02s — 纯自测量负载均衡排序键**; sub_1406FDBA0 头 stamp cc+5496 / 尾 sub_140CFEAF0 回写) + `cc+668` 师数, 均升序 (插入/并行归并两套) |
| 1 | preHourlyUpdate | 活跃国 (cc+1156>0) 串行: theatre 管理/移除 (pass 细节见阶段 3) |
| 2 | hourly_parallel | countryHourlyUpdateOnlyChangeSafePrivateAndCache |
| 3 | HourlyCountryComponentUpdate | 串行逐国六 pass: ① theatre 小时推进+失效移除 ("Removing Theater %s from %s"); ② cc+5136 关注 tag 表每小时失效清理; ③ gs+784 容器级单步; ④ **CProductionStatus (cc+3944) 生产小时推进**; ⑤ capital 完整性检查 ("<TAG> has NO capital defined."); ⑥ 多组件复合 = **decision.hourly** (cc+4000 挂起队列激活+冷却减时+七重评) + 装备市场 (cc+4024) + 人力 (cc+808) + 情报机构 (cc+4032) + 行动管理 (cc+5544) + 角色 (cc+4080) + CConvoys 派生值 (cc+4744 懒缓存) + **错峰日步 `hour == 国家下标 %24` 时 cc+5632 沿海防御比率重算** |
| 4 | (army 并行段) | 扁平全师数组并行: **army+1080 师级聚合缓存小时重算** (书 +1080 未名标量定案) + gs+1032 二维查询表小时重建 + 舰队第二遍并行; **hourlyUpdateUnits** = 占领 bundle 包夹 (theatre.cpp) + 单位容器步进 + **CCountryFuelStatus 燃料小时结算** (cc+5504); **army 错峰日步: `((army+28 师 id)+1) % 24 == hour` → 仅 HQ 师 (army+1584 leader 旗) 执行指挥链/部署关系重算** — 每师每天恰一次 |
| 5 | hourlyUpdateUnits | (并入阶段 4 描述) |
| 6 | postHourlyUpdate | 串行; **on_daily 派发** (§4.2.9) + 消费 cc+4744 convoys 派生值 |

hourly 粒度收尾两函数 (骨架 §4.2.4 步骤 16/17):

| 函数 | 语义 |
|---|---|
| sub_1401D6290 | to_be_deleted 队列清扫 (gs+1224/1236, SRWLock, gamestate.cpp:5732 断言): idpair→对象 (sub_14221F310 三级表) → RTTI 判 CUnit → DeleteUnit (sub_1401D6690, "RemoveReferences from DeleteUnit" @ gamestate.cpp:7156); 非 unit 条目留队 |
| sub_140BBED50(gs+1248) | CPeaceConferenceManager 每小时推进: sub_140BBEDA0 逐和会推进+收割 (+221 结束旗); 首个和会经 sub_140E50B20 人类参与守门 — **human_ai 全局旗 (BASE+0x332F639) 在此参与判定**, 被托管时 AI 自动接手 (sub_140E50BB0) |

#### 4.2.7 daily (CGameState::DailyUpdate, sub_1401D4810)

profiler 域 **"gamestate.daily"**; gamestate.cpp:6227/6310 source_location。
触发: 日边界 (骨架 §4.2.4 步骤 11)。系统序列 (32 步归并):

| 序 | 子系统 | 要点 |
|---|---|---|
| 1 | 力量平衡 daily +1104 | sub_140E560D0: 逐 CPowerBalance 条目 `value += Σ成员国 cc+1464 键152 (MODIFIER_POWER_BALANCE_DAILY, idmap:153)` → range 定位/切换 (旧 on_deactivate/新 on_activate) → `trend = Σ键153 + 7×Σ键152` 定 trending 侧 (负=left/正=right); weekly 版 sub_140E58B90 同构 |
| 2 | 空军 +1680 / 海军 +1688 / 铁路 +992 | **CStrategicAirManager::DailyUpdate** ("airmanager.daily", strategicair.cpp:6097): 区域港口打击限制并行重算 + 逐活跃国并行 + 逐翼训练经验 (AIR_WING_COUNTRY_XP_FROM_TRAINING_FACTOR, 按飞机份额分给远征贡献国) + 空军基地访问授权重算与亡国清理; **CStrategicNavyManager::DailyUpdate** ("navymanager.daily"): 串行逐国 CStrategicNavy 六步 = tag%7 **周**错峰 access 缓存重建 + 观察省清零 + per_region_danger 周衰减 + required_convoys 逐区域重算 + 护航效率恢复 (CONVOY_EFFICIENCY_REGAIN_* 双 define) + 护航存在史环形缓冲 — 海军任务推进在每小时版, 非此 |
| 3 | 州并行 | CStateDailyUpdateThreaded (vt 0x1427233F0), 州 [1, count) (数组 gs+712): 逐州 worker sub_1409D7760 = **按州 id%N 错峰** (`id%N == gs+1156 年积日%N`, N = dword_14332F650 运行时 define; owner 亡国强制) 掷**州事件候选**入 st+2000 队列 (确定性 RNG) → 结算到期 temporary_resource → CResistance 推进 + 占领表双缓冲换位 + 三类 modifier 重建, **MODIFIER_LOCAL_FACTORIES (mdef 65) 变化 → 生产脏旗 cc+3944+1192** |
| 4 | 活跃国过滤 | **cc+1156 = owned_states 计数 > 0** 为活跃 (与 weekly/monthly 同门); 序 4a gs+992 = **CRailwayManager 铁路冷却日递减** (railway_manager.cpp:544 "IsOnCooldown", 归零调 CSupplySystem vt[+24] 刷新补给网节点并 swap-remove) |
| 5 | 情报每日结算 | sub_1401D3420: 逐活国取 cc+4072 CCountryIntel, define 权重打包上下文, 机构分支 (≤8) 步进, 跨国 4×i64 聚合 + 资源观测折算 (countryintel.cpp:391) |
| 6 | 战略区域并行 | "daily.strategic_region_update": **CNavalRegionDominance 制海权每日重算** — current ← previous×日比例、decline_from = target/(target+外部)×1e5、重建排序优势条目表 |
| 7 | 占领 | "daily.occupation_update": 串行逐**占领者**国 → CCountryOccupationStatus (cc+4048) 六阶段: 选驻军模板 / 占领法重验换法 (countryoccupationstatus.cpp:561) / 抵抗州↔记录对账 / **逐控制州合规/抵抗推进** (res+64 += res+72, res+16 += res+24, ×1e-5 顶 10000000) / 记录明细 / 失效清理 |
| 8 | 州合规修复 | sub_1409D73E0: CResistance 变化刷地图 → **省控制权漂移修复** (州 owner≠省 controller 且非战争豁免 → 归还; 无主州 → SetOwner=控制者, state.cpp:2295) → **不可通行州 (湖) 邻居推举控制器** (state.cpp:2108/2110/2205) → 空军基地随控制权换主 (state.cpp:1763 "air base without access") |
| 9 | 研究共享 | "tech_share.daily", **CTechnologySharingGroup** (vt 0x142721740) 虚表槽[9]: **只做成员资格巡检** (组触发器 +152 求值不满足 → 研究侧摘链 + 槽[11]踢除); 加成传播不在 daily |
| 10 | 国家 daily 并行 | "country.daily_parallel" (gamestate.cpp:6310) 活跃国 + 全量国成员函数 sub_1406E8C70 |
| 11 | 外交两 pass | FirstPass (sub_140D357E0): 重建每国 dip+248 敌国集 + **dip+344 分类码** (§4.10 已改) + 阵营敌意聚合; SecondPass: 聚合派系成员/宗主-附属链 → **dip+272/+296 共同敌国**; 两遍原因 = pass2 消费 pass1 产物 (并行一致性: 先各写自己再互读新账) |
| 12 | 学说 daily +1024 | **NDoctrines::CDoctrineSystem::DailyUpdate** (tbb 符号直证): 对 CPdxArray<CCountryDoctrineStatus> 两遍并行 (mastery 日结算 + 求值/终结) |
| 13 | **CCountry::DailyUpdate** (sub_1406E76A0) | 门 = cc+1156>0; 活跃分支 31 步: 内战目标清理 → exile_divisions_transfer 到期 → 人力/生产/资源/科研/部署 → 市场 → 旗/政治/外交/核弹/焦点/后勤/燃料/operations/经验 → **on_border_war_lost** (门 = 控制州 state+2149 活跃旗 且 进度 > define BORDER_WAR_VICTORY, 派发后 sub_1409DDA30 熄火) → army.daily (虚表槽[19] 字节+152) → 志愿/远征军所有权重整 → fleets.daily (快照迭代) → railway_guns.daily → **投降/流亡日更 sub_1406E16C0** ("Attempting to surrender to nulltag" / FACTION_LEADER_CAPITULATED / BECAME_EXILE) → trade_influence.daily → 志愿军清扫 → 剧场 → incoming 外交+角色+特殊项目 → **queued_events 延迟事件派发后清表** → 修正重算门; 非活跃分支仅军队维护+投降判定; 每 5 国插帧保活重入 |
| 14 | post_daily 并行 | CCountryPostDailyUpdateThreaded (RTTI 定名, 活跃国, 每国 SRW 锁): **AI 战略日更 + logistics.postdailythreaded + CLoopHistory 国史** — 三件并行安全活挪出串行段 |
| 15 | 生产快照 + AI 国家战略 | sub_1406E8C70 (全量国 tbb 并行) = **CProductionStatus 容器 F(+1208)→B(+208) 快照发布 memcpy** (B = AI 生产挑选, 轻量 AI 喂数, 与序 13 重头 31 步分工); AI 国家战略: 串行 sub_14066A580 = **CStrategy 5-9 天随机间隔重算**; 并行 sub_14066A050 = 每日全量 Update (ai_strategy.cpp:476 + 112 槽冲账表 + 战争领袖变更检测); 门 = AI 启用旗 (ai+96) + 激活旗 (+99) — **非决议/焦点** |
| 16 | 阵营二次 +1016 / 市场 +1000 / 突袭 +1008 / 天气 +1672 | 阵营第二次 = 内务五步 (目标/升级/项目日更 + **UpdatePower 族成员矩阵重算** + 成员贡献分摊; 第一次序 19 只更 faction+2552 CFactionTheaterManager); 装备市场 = **购买合同交付推进** (成交即付/分期) + 到期结算 (define PURCHASE_CONTRACT_DELIVERY_TOTAL_DAYS), 非价格清算; 突袭 daily = 目标冷却 (target_cooldowns +56) 递减到期清除; 天气 daily = 省份自定义天气修正按天到期摘除 (模拟演化在 hourly) |
| 17 | profiler 锁刷写 | idler+2576 成员, AcquireSRWLockExclusive(+2584) 下刷写 |
| 18 | 旗/事件/渲染/紧张度/兵棋 | sub_140CBFA90 = **flag_manager.daily** (profiler 直证): 定时旗 u16 天数倒数到期摘除; sub_1401F0AF0 = **pending_events (gs+1376) 过期清除** (gamestate.cpp:4548, 只清除不派发); sub_140F2D910 = 玩家国 operations 结构快照 diff (变则 ++全局版本号驱动 GUI 重建); sub_140EF2F30 = **占领 bundle 收口** (与 sub_140EED690 配对 — 中段整个跑在 bundle 窗口内); sub_140DF8520 = 地图季节调色板按日期插值 (纯渲染, Tree_season.bmp); sub_140F05110 = **CWorldThreat 世界紧张度按日期进度向目标漂移** + 死条目清扫 |
| 19 | career profile | HasGameStarted (gs+2617) 门 → sub_1401D8400 |

> 备注: daily/hourly 各表中的 sub_1401C6930/6AB0/6BB0/6C30/6CB0/6D30/6DB0 等
> 取用器全是 `pdx::scoped_ptr` 惰性解引用 thunk (pdx_scopedptr.h:124 "_pPtr"),
> 业务语义在解引用后的真函数 — 读表时按"取用器+真函数"两层理解。
> 备注: **"country.calc_modifier" (sub_1406DADE0) = 13 pass 修正重算**: 静态修正名
> 缓存表 (40+ 项) / stability·war_support 按偏离 DEFAULT_* 插值 / attache_sent
> (token 14553) / lacking_consumer_goods / pride_of_the_fleet 族 / **难度五档
> diff_{very_easy,easy,normal,hard,very_hard}_{ai,player}** (gs+1584 难度 +
> IsAI); 重算门 = POTF 沉没惩罚到期 + 动态修正容器 dirty 路径。

#### 4.2.8 weekly (CGameState::WeeklyUpdate, sub_1401F2430)

profiler 域 **"gamestate.weekly"**。极简版 daily:

| 序 | 子系统 | 要点 |
|---|---|---|
| 1 | 力量平衡 weekly +1104 | sub_140E58B90: 与 daily 版 (sub_140E560D0) 逐行同构, **唯一差异 = 成员国修正键 153 (MODIFIER_POWER_BALANCE_WEEKLY)** (daily 用键 152) |
| 2 | 州 weekly | sub_1409E09B0 = **抵抗破坏工厂** (state.cpp:2323): 占领国州级修正 MODIFIER_LOCAL_FACTORY_SABOTAGE (mdef 76) 作每周概率 (random_fixed ∈[0,100000)), 命中 → 随机选州内 1 条有等级建筑, 伤害 = SABOTAGE_FACTORY_DAMAGE(100.0)×(1+抵抗度), clamp ≤1 级; **翻案旧"抵抗/合规推定"** |
| 3 | 国 weekly | **sub_140718CA0 = CCountry::WeeklyUpdate** (country.cpp:5793): 周累加族 — cc+5312 宣传稳定惩罚 clamp [-0.2,0] / cc+4304 stability clamp [0,1] / cc+5320..5344 四战争支持度惩罚 (-0.3/-0.5/-0.2) / cc+4312 war_support clamp / WEEKLY_MANPOWER (mdef 62) + 流亡 mdef 588 人力 / 占领日志按 GARRISON_LOG_MAX_MONTHS(12) 清理; **on_weekly 派发点** (§4.2.9); major 断言 = cc+5210 与 GetMajors 表一致性 (country.cpp:5810, debug 一次性) |
| 4 | DoCareerProfileWeeklyUpdate | gs+2240 tag 数组并行 |

> 备注: weekly 触发在 hourly tick 内 **daily 调用紧后** (总天数 %7==0),
> 不在 daily 函数体内。开局初始化序列 (行 7065010 区段) 依次跑
> HourlyUpdate → WeeklyUpdate → DailyUpdate → MonthlyUpdate 各一遍。

#### 4.2.9 on_actions 派发机制 (on_daily / on_weekly / on_monthly)

数据层 (定案): COnActionDataBase — `on_daily_<TAG>`/`on_weekly_<TAG>`/`on_monthly_<TAG>`
按国家 tag 存 +312 三列派发表 (24B/tag); PostLoad (sub_140A774B0) 另缓存通用
`on_daily`/`on_weekly`/`on_monthly` 于 +144/+152/+160。解析器 sub_140A760D0
(onaction.cpp:434/449/464 报错串)。

执行器 sub_140A79BA0: HasGameStarted (gs+2617) 门 → 直挂事件 + random_events
加权掷骰入事件队列 → 效果块执行。**脚本随机种子 = 总小时数 + source_location id**
(同刻同点结果确定性)。

| on_action | 引擎派发函数 | 触发时机 |
|---|---|---|
| on_daily / on_daily_<TAG> | sub_140705630 = CCountry::PostHourlyUpdate (country.cpp:4861) | **hourly 主调度六阶段之 postHourlyUpdate 串行段**; 判据 `(tag + gs+1128 总小时) % 24 == 0` → 每国每天恰一次, 时辰由 tag 固定 (引擎把每日负载摊到 24 个 tick 的削峰设计); **与 CGameState::DailyUpdate 无关** |
| on_weekly / on_weekly_<TAG> | sub_140718CA0 = CCountry::WeeklyUpdate (country.cpp:5793) | CGameState::WeeklyUpdate 国循环内 (与引擎 weekly 同帧同刻) |
| on_monthly / on_monthly_<TAG> | sub_140703490 = CCountry::MonthlyUpdate (country.cpp:5677) | CGameState::MonthlyUpdate 国循环内 |

> 备注: **无 on_hourly on_action** — on_action 最细粒度 = on_daily。
> "decision.hourly" (§4.2.6 阶段 3) 是决策评估, 非 on_action;
> ABILITY_ON_HOURLY/ABILITY_ON_DAILY token 属单位能力冷却域 (非 on_actions 体系, 不在本册范围)。
> CCountry::DailyUpdate 内另有命名 on_action "on_border_war_lost" 触发点。

#### 4.2.10 monthly (CGameState::MonthlyUpdate, sub_1401E34F0)

profiler 域 **"gamestate.monthly"**。触发: 月边界 (骨架 §4.2.4 步骤 13);
月份==5 (6 月) 处仅 profiler 包装无额外调用。系统序列:

| 序 | 子系统 | 要点 |
|---|---|---|
| 1 | **CCountry::MonthlyUpdate** (sub_140703490) | 门 = owned_states>0 (cc+1156); 十段: dip 月更 (MONTHLY_LEASED_IC_DECAY 衰减 + 限时好恶刷新 + 脏表重建) / **major 全量重算** (无宗主 && is_top_ic_country(cc+5211) && 工厂 ≥ MAJOR_MIN_FACTORIES=35 → cc+5210) + 补判 (0.7×top 均值) / "country.calc_modifier" pass (§4.2.7 备注) / 州征兵 + **阵营人力上缴** (token 10476, faction+2288 按 tag 记账 + mdef 648) / 逐国改善关系月更 / **on_monthly 派发** (§4.2.9) / 玩家专属 tag 管理器引用计数 / **季度舰队重整** (月长表 {31,28,...} 直读, 1/5/9 月触发 sub_140218EB0) |
| 2 | 阵营月更 (+1016) | sub_140D92DF0: 门 = `当前绝对月 == cgs+1192 记录绝对月 + 1` (**每自然月一次守卫**); 主体 = **仅含玩家阵营**的每条 faction goal 以玩家国为 scope 月度重放效果 (AI-only 阵营不跑) |
| 3 | 学说月更 (+1024) | sub_140D7F220: 只对玩家国 doctrine status (160B 元素) 跑月步; 无效 tag 断言 doctrine_system.cpp:80 后兜底元素 0; AI 国不经此路径 |
| 4 | 三个 "Short Task" | lambda_1 power_balance 玩家侧月更 / lambda_2 月度 history log (门 = 控制台 `history_logger` 开关, nlohmann/json 写 logs/history_dump, armies/navies/compliance/resistance 等全键, historylogger.cpp:594) / lambda_3 GameTelemetry::SendProvincesOccupiedSnapshot (tbb 逐国, 国数≥2) |

#### 4.2.11 yearly (CGameState 年边界, gs+784 国家数组)

**不存在 yearly 订阅者系统, 也无 on_yearly on_action** (全语料 0 命中
on_yearly/on_anniversary/on_new_year)。年边界实际动作 (骨架 §4.2.4 步骤 14):

| 动作 | 内容 |
|---|---|
| sub_14071A940 逐国 | 遍历 cc+656 师列表, 逐师清理师+840 CEquipmentVariantPool 零值条目 (门 = allow_zero u8@师+896==0, sub_14100D9B0) |
| sub_140207890 | PDX SDK TelemetryEvent 遥测批: 上报 country_count / in_game_date / nr_country (owned_states>0) / nr_dynamic_country (动态 tag) |

#### 4.2.12 补给小时更新 (CSupplySystem::UpdateSupply, sub_140ECD400)

入口链: HourlyUpdate 计时域 4 → sub_1401C6D30 (gs+984 scoped_ptr 解引用) →
sub_140EC8DB0 (强制第二参 = 1)。真名 = tbb 任务符号直读 **CSupplySystem::UpdateSupply(bool)**;
体内 **15 个 tbb parallel_for** (lambda_1..lambda_22)。第二参 = **小时步进模式旗 (定案)**:
1 = 每小时错峰模式 (调拨按整点过滤、国家每日重算按时隙); 0 = 全量立即模式
(全收、跳过错峰、哈希清理扩容) — 全 dump 仅 3 处 a2=0 调用 (读档/初始化路径)。

| 阶段 | 动作 | 并行 |
|---|---|---|
| 0 | 脏检: 每国 120B 记录@ss+64 (+112 旗), 比对 owned_states 变化与补给系数宏缓存 (cc+1464 键 567, fixed×1e-5) | lambda_1 |
| 1 | 打脏: 记录旗 \|= 2, tag 入脏国列表 {ss+160} | 串行 |
| 2 | 三条 id 列表刷新 (ss+88/112/136 → sub_140ECC340/sub_140ECC820) + 逐脏国补给状态重算 | 串行 |
| 3 | 补给节点全局遍历 (token 1812); 取 `小时 = now % 24` 为全程错峰相位 | 串行/并行双路 |
| 4 | CSupplyCalculationData (**800B/国**, ss+288) 更新 | lambda_2 |
| 5 | 国家 id 恒等排列上 8 连 pass: 依赖列表构建 (120B 记录 +88/+100 → calcdata+232)/字节标志压缩剔除 id | lambda_3/4/6/7/8 |
| 6 | 每省 **216B 记录**扩容 (省界 = gs+700) + 4B/省数组 + 省级 pass | lambda_11 |
| 7 | 护航/运输队按整点收集 (232B 元素, +4 时刻 `%24==当前小时`; a2=0 全收 + ss+232 哈希清理扩容) | 串行 |
| 8 | **国家每日重算错峰: `id % 24 == 当前小时` 才执行** (sub_14122E520 清累计 + 30 槽日环 国对象+552..+624 清新槽) — 每日补给重算摊平到 24 小时的削峰机制 | lambda_16 |
| 9 | 分发结算: **省满足率 = 省记录 rec[1]/rec[0]** (clamp ≤100000); 流入写 calcdata+184 区 40B 条目 {来源/快照/数量}; **库存扣减 calcdata+64** | 串行 + lambda_19 |
| 10 | 每国三连 pass (sub_14122B820/B300/C700/F110) + 观察者钩子 (单例虚槽[16]→+88→+23776) | 混合 |
| 11 | 最终并行结算 + **打下一轮脏标** (sub_140ECACF0: 省 32B 记录旗 \|= 4 入 ss+88, 国记录旗 \|= 4 入 ss+184) | lambda_21/22 |

> 备注: ss = CSupplySystem 对象 (gs+984 解引用); 脏国记录 120B/国、省记录 216B/省、
> 计算数据 800B/国均为本系统私有缓冲 (ss+64/312/288)。

#### 4.2.13 战斗小时更新 (CCombatManager, sub_140BB8AE0, gs+608)

每小时对每场活跃战斗: 首小时初始化 → 活跃判定 → XP 收集结算 → 结束善后 +
战史滑窗。CCombat 虚表行为槽 (COL 链直读; CCombat vt 0x1429BBC58 /
CLandCombat 0x1429A83D8 / CNavalCombat 0x1429DDB08 / CLandBorderWarCombat 0x1429BC5F0):

| 槽 | 语义 |
|---|---|
| [9] | **IsActive**: 双侧参战 tag/单位耗尽即结束 (基类查参战 tag 链表 cb+72 + 共同 tag; CLandCombat 加两侧容器计数) |
| [13] | **首小时初始化** (byte+81=1 已初始化 / 清 byte+82 结束旗; CLandCombat 先做两侧大体量初始化 sub_1412AC450) |
| [14] | **结束标记** (byte+82=1, 通知两侧) |
| [15] | **每小时战斗步进主入口** (CLandCombat 0x1412B81D0): ① 按 define 周期调 **sub_1412BBF90 = 战术重掷核** (见下); ② `++(a1+68)` 时长计数; ③ 遍历两侧参战国 tag 链表, 可战斗者 (sub_140CC6980) 调 **sub_1412BBDB0** (聚合己侧全师人力 (+976 求和) 与装备量 (师+840 池 category&4) max-写**战争统计对象** +360/+364/+416; 状态位计数 = 修饰槽位图+多国旗, 仅玩家参战侧执行带 UI 通知); ④ 尾调基类 0x1413E28C0 = **对两侧 combatant 依次调槽[22] 修饰符全量重算 → 槽[19] 伤害执行步 → 槽[14] 领袖 XP (损失比×0.5) → 槽[32] weighted_participants (情报权重)** — **XP 只是四连的最后一环** |
| [16] | 结束复核 bool(self, idx, count) (基类 purecall) |
| [11] | GetDuration (历史 entry 消费) |

流程 (五阶段):

| 阶段 | 动作 |
|---|---|
| A | playthrough id 重同步 (gs+1312 优先, 非正取 +1316; 与 cm+32 缓存比, 经 gs+832 恒等表判等价 — 同原初国切换不清场); 非等价清战斗两侧指针 |
| B | 战史修剪 sub_140BB8910: CCombatHistory (cm+40) 尾部追加 = end_date 升序; **保留 168 小时 (7 天) 滑窗** + 回档守卫 (head.end_date > now 全弹) |
| C | 主循环 (置 cm+72 _bInCombatUpdate=1): 逐战斗跳过已结束 (+82) → 首小时初始化 ([13]) → 活跃判定 ([9]) → **[15] 每小时战斗步进** (数值推进/单位处理/XP 收集, 见槽表) → 未结束/已结束分别记录 |
| D | XP 结算 sub_140BB6F60: leader 经验即时发放 (CUnitLeader::AddExperience: leader+3688 += xp, 超 `100000×单位阈值(+444)` 即升级) + **tbb 并行 ApplyCombatXpGains** (任务符号直读, EJobType 参与) + 收尾晋升扫描 (leader+3576/+3588 单位阈值 +2208) |
| E | 结束善后: 二次遍历, 已结束或 [16] 复核真 → **RemoveCombat** (swap-remove; combatmanager.cpp:1169/1173/1189 三断言) → [14] 通知两侧 → **CCombatHistory::Add** → 逐省 (省战斗数组 province+224) 去重善后 sub_140BB9220 (同原初国战斗聚合 / 撤退判定 / **胜负 = SCombatSideData progress (lb+616) 高者置 win**) |

**战术重掷核 sub_1412BBF90** (每 `TACTIC_SWAP_FREQUENCEY`=12 小时, dword_143335D98 defines 直证; 或任一侧 +304 空): 双方**技能最高领袖 skill 等级** (combatant vt[29] 逐单位取领袖取最大) 比较, 侦察优方 (侧内最大侦察值 statId 6) +`RECON_SKILL_IMPACT`=5 技能当量; 占优方经 sub_1412BB330 (**战术加权随机选择**, "Couldn't select a tactic in phase") 按 `INITIATIVE_PICK_COUNTER_ADVANTAGE_FACTOR`(0.35)×技能差权重掷「反制败方当前战术」的新战术; 未被反制战术六值 (+312..+352) 经 sub_1412AE250 聚合进 battle+160..+200; **a1+208 = 当前战术相位**。

**每小时数值流水** (基类槽[15] 四连):

| 步 | 槽 | 内容 |
|---|---|---|
| 1 | 槽[22] | 修饰符全量重算: stacking/over-width/补给/夜战/挖掩/岸轰/空优/情报/包围 (**39 个 define 全部定名**) |
| 2 | 槽[19] → sub_1412B3300 | **伤害执行步**: 目标分配 (DAMAGE_SPLIT_ON_FIRST_TARGET 主目标 + 强度占比溢出 + 「打弱」评分 = 硬攻×硬度+软攻×(1−硬度), 低 org 优先) → 逐对开火: 防御/突破值给闪避点 (有防御剩 90%/无 60% 命中, sub_140BF9A70) → **STR 骰 1+rand(2) / ORG 骰 1+rand(4)** (装甲优势换 2/6) → ×STR 0.06/ORG 0.053 ×穿甲偏转表 (PIERCING_THRESHOLDS{1,0.75,0.5,0}) → **CArmy::TakeDamage (0x140C8F510) 实扣 +1056 strength/+1064 organisation** (mod 660/661/662, war support 扣减) |
| 3 | 槽[19] 尾 | **progress (lb+616) 推进**: vt[12] (0x1412B5360) = Σ己侧全部师当前 org, 经 sub_140CDF0E0 每小时整量重写 → 结算 (sub_140CDB850) **高者判胜 = 剩余组织度比较** |
| 4 | 槽[14]+XP | 领袖 XP (损失比×0.5 分配; XP 预置系数 0.9f = CCombatant+156 常量) + tbb 并行 ApplyCombatXpGains (§4.2.13 阶段 D) |

> 备注: RNG 保护 (random.h:74 主线程断言) 包裹结算段。
> 备注: **组织度分工** — 战时扣减唯一入口 = 战斗域 TakeDamage (+1064); 恢复
> (RELIABILITY_ORG_REGAIN, sub_140C82C10) 与移动耗减在师域 tbb 并行小时更新。

#### 4.2.14 突袭小时更新 (NRaids::CRaidSystem, sub_140E86100, gs+1008)

全串行两遍 (遍 a1+216 分组数组, 176B/组, 组内 +128 实例指针表倒序):

| 遍 | 动作 |
|---|---|
| 一 | 逐实例 sub_140FED6C0 = CRaidInstance 每小时推进 (raid_instance.cpp): **相位机 1→2→3→4→5**; 准备中每小时 `++(item+68)`; 各 `raid_canceled_*` 取消路径; 自动发射按 `5×值/100000` 桶对玩家档位 +52 判定 |
| 二 | 对未置旗 (+400==0) 实例做**预警判定**: 取发起国 (+160) 的 CCountryIntel (国家+4072, §4.11.7) 矩阵中目标国行 (32B = 4×int64 定点 civilian/army/navy/air), 列号 = 突袭类型定义 `*(*(item+152)+32)+32` 0..3 四象限选一; 与 define `NIntel.RAID_MIN_INTEL_FOR_WARNING_ON_LAUNCH`×100 (defines_intel.h:242) 比较: **相位 2 达标线随准备进度从 10^7 线性降到 define 值, 相位 3/4 为定值**; 达标置 +400 旗并经 sub_1419ABC90 按双侧相关度挂入 +240 预警池 (消费方 = alert id 73-77 族) |

> 备注: 方向定案 = `[A][B]` = A 关于 B 的情报 (CAddIntelEffect::Execute 0x14034A8D0
> 交叉验证); +160 = 发起国 (raid_source.cpp:410 源省断言链)。

#### 4.2.15 天气小时更新 (CWeatherManager, sub_140F1C6E0, gs+1672)

| 阶段 | 动作 |
|---|---|
| 0 | 禁用门 (+841/+842 双旗, "skipping (_bDisabled=%d)" weathermanager.cpp:366) |
| 1 | 种子推进 (+776 `_nRandomSeed` += RNG, :374) |
| 2 | 昼夜 tbb 并行 (CDayNightUpdateThreaded) |
| 3 | 迭代数 = +840 init 旗 ? +760 nInitPasses : 1 (":382 nInitPasses") |
| 4 | 主更新 sub_140F18AD0 ("DoUpdatePasses"): 轮转收集 +40 有效区域 (384B SWeatherPerProvince) → tbb 并行 (主线程自动回退串行) + Modifiers/Region 两段 |
| 5 | 收尾 |

区域状态机核心 (sub_140F11820): 历史轮转 (+264/+272/+320 存上轮) → 特殊区域名单比对 → 类别修正表 → **确定性哈希噪声** h(seed+776, pass, region_id) `%100000-50000` 随机游走推进平滑值 (+352) → 强度计 (+64) 按周期条目增益/衰减并钳位。
**翻面判定 sub_140F22420**: 平滑值 ≤ 下阈值 (+480) → 关; 否则概率 = 时长比 × 全局库系数 × 周期修正 × **滞回** (开→×+640 更易续开, 关→×+648) × 类别修正, 再按 (种子, 遍数, region_id) 确定性哈希 `%100000` 掷骰置 +304 active 位 — **同种子同局面可复现 (无墙钟随机)**。

> 备注: 384B 区域条目全字段表 (SWeatherPerProvince: +44 类别 / +64 强度计 / +304
> active 位 / +352 平滑值 / +368 噪声值等) 与 352B 区域周期条目见 findings 同名册。

#### 4.2.16 战略海军小时更新 (CStrategicNavyManager, sub_140EA79F0, gs+1688)

每国一个 CStrategicNavy 实例 (+8 数组 / +20 计数)。两遍:

| 遍 | 形态 | 动作 |
|---|---|---|
| 一 | 串行 | 舰队-任务一致性校验 / 分组聚合 / 脏旗触发的最近邻重排 / 失效句柄 swap-remove 紧缩 / **`hour == countryIdx % 24` 错峰日更新** (第三处 %24 削峰: on_daily、补给每日重算同款) |
| 二 | tbb 并行 | 收集 CNavalMission* 逐任务 sub_140FBE250 (navalmission.cpp:5043 断言): 按区域∩省份区间谓词过滤敌护航, `mission+64 = Σ计数×规模` |

> 备注: 两遍角色 = 串行遍改容器 (维护), 并行遍无冲突纯重算 (结算)。

#### 4.2.17 战略空军小时更新 (CStrategicAirManager::HourlyUpdate, sub_140C57D30, gs+1680)

吃 gs+2464 ActiveCountryIndices (strategicair.cpp:6547 断言)。12 步 (按函数体顺序):

| 步 | 内容 |
|---|---|
| 1 | 并行逐 SA → 逐池 → 逐翼: 任务指派/换任务 (sub_140F68040) + **CAirWing::HourlyUpdate (sub_140F62750, airwing.cpp:1596)** |
| 2 | **HourlyUpdateThreadedInternal (sub_140C58660)**: 5 段内部 parallel_for over CAirUpdateCache — 确定性空战/效能解决核心 (cc+1464 修正查表 + 区域战斗数据) |
| 3-4 | gs+2536 region→兵力树前置; 逐 SA 待查翼列表 = **每小时翼解散清扫** (无机无人 → 装备退还 cc+3944 生产库存 + ace 回收; 空池删除) |
| 5 | per-state/region 数据并行重建 |
| 6-7 | 逐活跃国 cc+4824 失效项清理; 逐 SA 任务/区域表维护 (ActiveMissions 增删) |
| 8 | 并行逐任务重算 **mission+184 扰断值** (define 因子 × cc+1464 修正 × 有效机数, ×1e5 定点连乘) |
| 9 | 并行逐 SA **disruption 总量重算** (+ 阵营规则/指挥功率门) |
| 10-12 | 交战区域任务完成度/区域计分推进; gs+2536 已完结条目清理; 逐区域 **ProcessGroundMission (sub_140F82110, airmission.cpp:2398)** 地面任务每小时推进 (目标重选/空投位) |

CAirWing::HourlyUpdate 逐翼要点: other_combats 死引用压缩 / 无效任务取消 (任务掩码 0x400) / 任务状态机步进 / **空投执行 (0x40 位: 选省 + 投放落人)** / 解散门 (无机无人/transfer_to_warehouse/部署未完成) / **部署计时 +1h** / 经验入账 (训练增益封顶) / timed_disabling 减时。

> 备注: 空战损失结算不在本层 (属战斗域); 空降落人在翼级本函数, 非战斗域。

#### 4.2.18 阵营小时更新 (CFactionSystem::HourlyUpdate, sub_140D928C0, gs+1016)

| 段 | 并行性 | 动作 |
|---|---|---|
| 前奏 | 串行 | 活跃国 extracted 战略资源 (cc+4600 CCountryResources+40) 清零后累加进阵营系统全局池 (+56) 与所属阵营池 (fac+2320, 经 diplo+656 取 CFaction*) |
| 并行 | "CFaction::ParallelPreHourlyUpdate" | 逐阵营 **influence 总量重算** (成员 lock-free 归约 → fac+2072) + 挂起 faction goal 预评估置态 |
| 串行 | "CFaction::HourlyUpdate" | **"faction_goals"**: 目标推进 + 达成后对目标国施效 (宣战族) |

> 备注: 无租借/远征军逻辑 (已穷尽排除)。

#### 4.2.19 关键全局量与字段索引

| 符号/字段 | 含义 | 分册 |
|---|---|---|
| qword_14332F260 | CGameState* 单例 | §4.1 |
| qword_14332F698 / qword_14332F6A0 | 全局 idler 单例双槽 — 由 idler **OnEnter (虚表槽[11])** 写入: 游戏内 = **CInGameIdler 实例** (CFrontEndIdler 派生, 主虚表 0x142968FF0; OnEnter = 0x140DE0150 thunk → setterB sub_1402A2A30 双写), 菜单态 = CFrontEndIdler (OnEnter sub_140B3E1F0 只写 F698, F6A0=0 → 时间调度器空操); 槽[17] 读对象+896 = CSession*; **+1328 = 管理器指针 (CApplication 本体: +56 current / +112 待入 / +120 旧 / +64 切换旗 / +128 保留旗)** | §4.28.14 |
| gs+1120 / gs+1128 | 内嵌 CGameDate 当前时刻 / hours | §4.1 |
| gs+1144..+1160 | 日期分量缓存 (每 tick 刷新) | §4.1 |
| gs+1208 | 小时进度累积器 (float) | §4.1 |
| gs+1212 | 速度档 (键 110) | §4.1 |
| gs+1216 | tick 进行中标志 (u8) | §4.1 |
| gs+1248 | CPeaceConferenceManager 头 (hourly 处理) | §4.1 |
| dword_143085210 | 闰年月首累计日表 | 本册 |
| dword_1433386CC / qword_1433386C0 | 自定义速度表长度/指针 | 本册 |
| qword_14333CEA8 / dword_14333CEB4 | GS checksum 数组/长度 | 本册 |
| session+72 | CSession 联机状态枚举 (19 值全表) | §4.28.11 |
| session+84 | 游戏已开始标志 | §4.28.11 |
| session+128 | 会话 tick 号 (16 位截断) | §4.28.11 |
| idler+1729 / idler+1732 | 暂停权威位 / Idle 第二暂停门 (与 +1731 toggle pending 并存勿混) | §4.28.14 |
| idler+2396 | 加速脉冲计数 (每 tick 减 1) | §4.28.14 |
