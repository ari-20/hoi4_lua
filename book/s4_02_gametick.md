

### 4.2 游戏时序 (时间推进驱动链 / 每小时 tick 调度 / 日期边界)

> **本册定位**: 引擎如何把现实时间换算成游戏小时推进, 以及每个游戏小时的
> 完整调度顺序 (hourly/daily/weekly/monthly/yearly 各粒度的分发点)。
> 字段布局归各本体分册 (CGameState 字段归 §4.1, CSession 归 §4.28,
> CCommand 派生族归 §4.33); 本册记**顺序与触发契约**。
> 时间推进在引擎内是「命令」: 与玩家指令同一命令管线, 联机同构。
> 各相位的**执行线程归属与并行机制总纲** (tbb 算法层/双任务池/安全窗判据)
> 见 §3.11; 本册相位表不再逐行重复线程注。

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

命令泵宿主 sub_1401AAAD0 (定案): 两个 idler 的 Idle 每帧调用 — gamestate 锁
(Count≤2, gamestate.h:1140) → session+1952 挂 gs → **session+1960 登记帧保活回调
sub_1401E4320** → sub_142252D00 (命令泵) 派发 → 锁--。采样骨架帧 +1AAB01 = 其体
碎片 (5140−3925 ≈ 1215 落在限帧睡眠 sub_1401BA490), +251A348 = __scrt_common_main_seh
(CRT 入口), +222E897 = Run 循环体碎片 — 三帧为主线程全部栈的共有"住址"。
帧间隔判定 sub_1402A3210 = 欠额 1.0/1.5/2.0/4.0 阶梯倍乘 (速度档直读)。

| 段 | 函数/对象 | 语义 | 证据 |
|---|---|---|---|
| Idle 本体 | CInGameIdler::Idle (0x140DD3A50, 基类 CGameIdler 虚表槽[4] 覆写) | 游戏主循环体; CFrontEndIdler 覆写同槽 = 菜单场景; 帧顶 a2 块含 massconquer 帧测试器调用 (§1.1b.2); 暂停门分支内含警报管理器每帧更新 (idler+1944, §4.17.7) | 虚表 0x142968FF0 槽[4] 直读 |
| 暂停门 | `帧耗时 && !this+1729 && !this+1732` | 权威暂停位不通过则不调调度器 (时间冻结) | this = CInGameIdler 实例; 1729 = §4.1.2 已载暂停位 |
| 调度器 | sub_1401F0590(gs, dt) | 小时进度累积 + 到点生成 CHourlyTickCommand; **门 qword_14332F6A0 非空** (OnEnter setterB 写; 菜单态为 0 → 空操) | 本体反编译 |
| 入队 | sub_142250B00(session, cmd, flag) | 命令发送 (session.cpp:374): 盖 tick 号 cmd+22 = min(session+128, 0x7FFF) → server 虚表槽[5] (字节+40) 入队 (server.cpp:319) | 单机 server = CDummyServer (0x142B52C28) |
| 派发 | sub_142252D00(session) | 命令派发循环 ("Executing command: "/"Discarding command: " 日志; "Update within execution. Skipping." 防重入 session.cpp:600/629) | session.cpp 日志串 |
| 执行 | CHourlyTickCommand::Execute = 0x140F06BF0 | 虚表 0x142976F78 槽[10] (与 §4.00.3 CCommand [10]=Execute 定案一致) | exe 虚表直读 |
| 推进 | sub_1401DD370(gs, 载荷) | gs hourly tick (§4.2.4 骨架) | 本体反编译 |
| 限帧睡眠 | sub_1401BA490(ms_ptr) | 到点等待器: 目标 = QPC 频率归一 now_ns + 1e6×\*ms_ptr (超限钳 INT64_MAX) → 循环 `Sleep(剩余 ms)` (剩余 ≥1 天走 1 天步进, 溢出分支 `Sleep(0xFFFFF8BF)`); **主线程空闲期的采样落点** (性能分析里 leaf 落 ntdll 的 Sleep 即此, 非热点) | 本体反编译 |
| 每帧渲染 | 基类槽[28] (thunk 0x1402A1700+体) → 槽[29] (0x140DDDDF0) | 渲染就绪门 → 帧渲染 + 瞬态状态横幅 ×4 + 教程帧更 + 帧时长 EMA — 全链与布局见 §4.28.14 帧渲染槽对 | func_names rtti + 语料直读 |
| 资产泵 | sub_14029EEF0 | 双 idler Idle 每帧直调 → 14222EB50 地图 Idler 每帧对象更新分发 (动画/实体提交/效果/矩阵上载/死对象清扫; §4.28.14) | xref 全集 |
| 国家视图应用链 | Idle → sub_140A67810 → sub_140E1A890 (更新) + sub_140E1DAA0 (应用) | 每帧国家级双管理器 → 写 cc+1696/cc+1700 → 触发 sub_140B59200 重算; **更新步内层 = sub_140E1B280 逐省着色计算** (1,409 行; a2 虚表[25] 取地图模式对象按 +548 子模式分派判定, CFront RTTI 直证取色路径, 按 gs+700 省数逐省写色 dword 到 *(a1+56) 数组 (写原语 = sub_1419DCBD0: 容器 data@+0 按 4×下标写色, 变才写 + sub_14012B520 脏区传播; 宿主 140E1A890 尾部逐国展开), 省下标从 1 起 — 定案级, cc+1696/1700 仍未决) | 调用链直证 + e4c3c 定域 |

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
| 构造通道二 | sub_140F05A30 | **Clone (槽[13]) 实现** (调用者 = 泵内命令日志克隆 + CDummyServer 出队克隆; 联机侧客户端从广播流经工厂反序列化获得, 无专用包构造通道) |
| 构造通道三 | sub_140F05C80 | 无参工厂, 注册于命令工厂表 (注册号 3092, 反序列化用) |

Execute 步骤 (定案):

| # | 动作 |
|---|---|
| 1 | gamestate 断言 (gamestate.h:1116/1117) |
| 2 | 读 `session+72` (sub_140CE9520), **≠ 13** 才调 `sub_1401DD370(gs, cmd+40 载荷)` |
| 3 | session+84 为真时遍历玩家条目 (gs+248 数组 {计数@260}, 160B/条; **+152 = machine id ≠ 本机** (sub_140B54190 = session+164 getter) 才参与; +128 = u32 日期水位): 当前日期折天 − 水位 > LAG_DAYS_FOR_LOWER_SPEED (10 天, dword_1433361D0) 的掉队者 → **掉队降速/暂停链**: gs+1212>0 走虚表+760 (idler 槽[95], 每 13 次节流) 发 CDecreaseGameSpeedCommand(10456); gs+1212≤0 走 sub_140DE5F90 构造 CPauseGame(10732, 带玩家名条件 toggle) 入队; 命中一个即 return (每小时至多处理一个; 聊天通报与 25 天暂停档在 CClientPingCommand::Execute 侧, 见 §4.36.4) |

> 备注: session+72 = **CSession 联机状态枚举**, 13 = HOTJOIN_WAITING_FOR_SAVE
> —— `≠13` 门 = 「热加入等待存档的客户端不推进时间」, **不是暂停检查**
> (暂停门在 §4.2.2 生成侧)。

> CSession 状态枚举全表 (19 值, session.cpp:269 SetState switch, 定案) = **§4.28.16** (CSession 布局所有权册)。

#### 4.2.4 gs hourly tick 顺序骨架 (sub_1401DD370)

定义 0x1401DD370 (gamestate.cpp 族)。每次 CHourlyTickCommand::Execute 调一次;
第二参 = 命令 +40 载荷 (checksum 数组, 联机对比用)。顺序定案:

| # | 粒度 | 动作 |
|---|---|---|
| 1 | 每小时 | 构造 CClientPingCommand (id **11376**; 载荷 cmd+48 = 当前日期 / +64 = 本地国 tag / +68 = 本机连接信息) 并入队 (语义 §4.36.4) |
| 2 | 每小时 | `gs+1216 = 1` (tick 进行中) |
| 3 | 每小时 | 保存旧日期分量 (旧日/旧月/旧年积日/旧年) |
| 4 | 每小时 | `CGameDate 虚表槽[1] (gs+1120, 参数 1)` = **Advance 1 小时** |
| 5 | 每小时 | 重算日期分量缓存 gs+1144/+1148/+1152/+1156/+1160 (dword_143085210 = 闰年月首累计日表) |
| 6 | 边界 | 计算四布尔: 换日 (日分量变) / 换周 (换日且总天数 %7==0) / 换月 (月索引变) / 换年 (年积日变) |
| 7 | 边界 | profiler 日期粒度采样 sub_140BBBEA0 (gs+2008): 五槽打点 "Hour"/"Day"/"Week"/"Month"/"Year" (性能采样, 非游戏逻辑; 见 §4.2.5) |
| 8 | 联机 | checksum 对比: sub_140DB1830 算本地 vs 载荷 → OUT_OF_SYNCH 判定与日志 (gamestate.cpp:4744-4795); CNetworkServer/CProxyServer 或 debug 旗才走; 本端 checksum 计算 = sub_140DB1740, 哈希核 = **MurmurHash3 x86_32** (sub_1424ED930 update / sub_1424EDA70 finalize — 勘误: 原「sub_14024ED930/24EDA70」系 0x14 前缀笔误, RVA 正确; 全常量直证)。**OOS checksum 全貌 (定案)**: 命名空间 NGameSynchronizationHelper; **91 槽定长校验和** (快照 = 91×u32 逐槽与主机对拍), MurmurHash 流式 (每逻辑校验项一个 12B 哈希状态); 双变体 = Logging 变体 (91×12B 槽数组建立者 = **sub_140DB1560** gamesynchronizationmanager.cpp:1129, 填充后逐槽打 "Checksum: <i> <hash>"; 核心填充器 sub_140DA5C80/140DAB4C0 — **a2 位掩码**: bit0 = CGameState::Save 主块 writer a3=1 整态进流 → 槽 2 + 日志 "Full Persisted Game State" / bit1 = playthrough writer sub_1401F2DD0 → 槽 87 + "Playthrough Stats" / 恒执行 "Global Game State" 文本段; 仅 OOS 报告窗 sub_140DD8D60 用, 串行) 与 PdxHasher 静默变体 (sub_140DA8A40/140DAE720, hourly tick 生产路径, tbb 并行; 静默族 5 函数在簇外); 周期 = 每小时对拍一次 (CHourlyTickCommand 载荷携主机 91 槽 → sub_140DB1830 比较 → 差槽/OOS 标签上行 → sub_140DB1740 重算本地; **human_ai 旗置位也强制对拍**); 覆盖面 = 全局段 (槽 0/1 = multiplayer_random_seed/count 与 §4.28.13 随机流闭环; 槽 2/87 = 全持久态/playthrough 摘要 [后者 byte_143468B46 门控] / 槽 55 = debug_current_ref_id dword_1434520E0) + 省/前线/州/区天气/战斗走访 + 逐国 21 具名分区; **与存档 #checksum 无关** (存档 = MD5(文件+盐), 本簇 = 活体 gamestate 结构化分槽 MurmurHash) |
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
> 备注: 与 BBBEA0 并行的**阶段计时序列** (1DD370 自测量, 定案): sub_140222860 使能旗读
> (gs+2008+396) / sub_140222CE0 每时清零+盖章 / sub_140222530 总账序列 (+16 槽,
> HourlyUpdate 全程) / sub_140220EA0+221060+2210A0+2210E0 = Monthly/Weekly/第四/Daily
> 段序列 (槽 +88/+64/+112/+40); 样本经 sub_14021EC40 入 32B 日期标记数组。
> 备注: **计时域作用域件** (timing.cpp, 定案): 开启 = sub_1402200E0 (16B 栈对象
> {域id@+0, 起始tick@+8}, 使能旗 timing+396 开则记起始; timing.cpp:45 断言) /
> 收尾 = sub_1402203F0 (elapsed 累计到 timing+216+8×域id; timing.cpp:36) — 二者成对
> 夹每个 daily/hourly 子系统, 即表内「计时域 N」的机制本体。域 id 实测: 2 = state.daily_parallel /
> 4 = 补给 / 7 = 天气 / 8 = 空军 / 9 = 海军 / 11 = 市场 / 12 = 突袭。
> 备注: 启用入口 = 控制台 `gamestate_timer`/`gstimer` 或启动参数
> `-gamestatetimer`; 产物文件 = logs/gametimer_<时间戳>.tsv; 工具全貌见 §4.9。

#### 4.2.6 hourly 主调度 (CGameState::HourlyUpdate, sub_1401DF400)

profiler 域 **"gamestate.hourly"**; gamestate.cpp:5918-5920 断言窗口 (定案)。
系统序列 (按函数体顺序):

| 序 | 子系统 | gs 槽 | 要点 |
|---|---|---|---|
| 1 | 军队状态小时统计 | +2416 | **CUnitMetricsCollector** (unitmetricscollector.cpp 定名): 收集开了 +413 IsCollectingMetrics 旗的作战计划编组, 14 键按小时窗口累计, 写 logs/metrics/*.log — **纯遥测, 默认关闭, 不进游戏逻辑**; 四件 = sub_140F08C50/F09DE0/F0A580/F0ED00 (AVG_DEFENDER_ENTRENCHMENT_WHILE_ATTACKING / TOTAL_IN_COMBAT_MAN_HOUR 等键直证) |
| 2 | 三数组预收集 | +2464 族 | 全体国家数组 (门 = 有资州或收容流亡政府) → DoCountryHourlyUpdates / AI 策略数组 (就绪检查+预热) → ai_update / 国家下标数组 (gs+2464) → 战略空军 |
| 3 | 补给 (计时域 4) | +984 | **CSupplySystem::UpdateSupply(bool)** 12 阶段 (§4.21.1a) |
| 4 | **装备市场小时槽 (计时域 11)** | +1000 | sub_1401C67B0 → thunk 市场解引用断言, **返回值弃置 = 空转** (定案, §4.23.3a) — 全局市场唯一周期处理在 daily 序 16 |
| 5 | 突袭 (计时域 12) | +1008 | sub_1401C6A30 → **sub_140E86100 相位机推进** (gs+1008 + 域 12 直证) + 情报阈值预警 (§4.27.3) |
| 6 | 天气 (计时域 7) | +1672 | 昼夜并行 + 区域状态机 + 确定性翻面 (§4.2.15); 断言 "_pWeatherManager" 直证 |
| 7 | 战略空军 (计时域 8) | +1680 | **CStrategicAirManager::HourlyUpdate** 12 步 (§4.2.17); 断言 "_pStrategicAirManager" 直证 |
| 8 | 战略海军 (计时域 9) | +1688 | 串行维护遍 + 并行重算遍, 国序 %24 错峰 (§4.2.16); 断言 "_pStrategicNavyManager" 直证 |
| 9 | 谍报/特工 | +1696 | **sub_140EB3050 = 纯 assert 空转循环 (非业务)** — hourly 侧不推进特工; 业务七连 **sub_140EB2EC0 全库唯一调用点在 daily sub_1401D4810** (§4.2.7, 每日一次): 逐 8B CStrategicOperative* 调 sub_1411FAE40 (门 so+8 属主 tag>0) 七连推进 — sub_1412002E0 网数组重建+全网增益重算 (每网 sub_1411D63A0, §4.11.18) / sub_1412017C0 propaganda EWMA (so+304/+312 drift) / sub_141201B60 control_trade 表 / sub_141200DF0 diplomatic_pressure 双表 / sub_1412014C0 subversive+danger 双 PID / sub_141201FF0 UpdateIntelNetworkStateModifiers / sub_1412023C0 州 modifier 应用; 尾置 CMapModeManager(+48 子对象)+82 intel 地图模式脏旗 |
| 10 | playthrough 监听查询 / autoexit 检查 | | "g_ExitOnTriggerText was invalid" |
| 11 | **DoCountryHourlyUpdates** (sub_1401D85A0) | | 13 相位串行×并行交替, 见下表 (gamestate.cpp:5216/5259); 出口前双键排序先行一轮 (sub_1401B6AD0 归并 → sub_1401B6720 插入) |
| 12 | 战斗 (计时域 6) | +608 | CCombatManager 每小时推进 (§4.22.9a) |
| 13 | 阵营 | +1016 | **CFactionSystem::HourlyUpdate** (§4.2.18) — 位于战斗后、ai_update 前 (函数体顺序直读) |
| 14 | **ai_update** (sub_1401D7E40) | | 门 = idler vt+880 网络判别 + session+84; 收集的 CAICountry 策略数组以作业 "Short Task" 并行发射 |
| 15 | gs major top-K IC 重算 + career profile | | **sub_1401F1190** = gs major top-K IC 重算 (定案; ai_update 后无条件, 与 §4.2.10 行互引): K = max(MIN_MAJOR_COUNTRIES, 2), 逐国 (tag>0 ∧ owned_states>0) 工厂数 (sub_140E69340(cc+3944)) 插入排序, 写 cc+5211 top-IC 旗 (sub_1407128F0); 产物 gs+2168 top-IC 均值 (除零写 −1) / gs+1320 基准国 tag; 紧后独立调用 **sub_1401B1C40(gs+2240)** = DoCareerProfileHourlyUpdate 逐 tag 生涯统计 (该标签只覆盖此件) |

> 备注: 每两子系统间夹一个**帧保活重入块** (§4.2.4 备注: byte_1430864E0 门 +
> sub_1402A3210 帧间隔判定 + sub_14222EEB0(mgr,0) 重入一帧), 防长 tick 假死,
> 非游戏语义。

DoCountryHourlyUpdates (sub_1401D85A0, gamestate.cpp:5216/5259; 第二参 = 国家数组
{data@+0, 计数@+12}) — **串行相位 × 阻塞 tbb 波次交替共 13 相位**, 对国家主数组完整遍约
11 次 (活跃门 cc+1156>0); **6 个阻塞 join 点** — 主线程每相位结束等并行波次收干,
auto_partitioner 下主线程还亲自执行分到的串行份额 (采样旁证: join B 机制三件套
sub_1401F7380/sub_1401B8650/sub_1401BB280 各占 ~3%):

| 相位 | 内容 | 并行性 |
|---|---|---|
| 0 | preHourlyUpdate: 逐活跃国 sub_140705410 = ① 逐 CNuke 推进 (cc+4880, 72B/元素 = §4.3.8 尺寸直证; sub_14109A520) ② cc+4328 **CPlayerAiPrefs 托管偏好到期回默认** (§4.3.1): 门 sub_1414E82D0 (非默认签名 {1,0,0,1,−1}); sub_1414E8370 到期判定 (gs+1128 天数 ≥ timeout@+4340 + 365, 参考 CGameDate「1.1.1.1」哨兵 43808760 只读常量) → 写回默认 {偏好 0x01000001, −1}。theatre 管理/移除不在此相位 (在相位 5 pass①) | 串行 |
| 1 | CTaskForce 波次 #1: 逐国收集进全局数组 (qword_14332F2E0 / 计数 dword_14332F2EC) → sub_1401B1AF0 = **PdxParallelForContainer(CPdxArray\<CTaskForce\*\>)** 并行 (memfn **sub_140D74D20 = CTaskForce 海军总部挂接重建**, 定案: 遍历属主国 naval_headquarter_status (cc+4016 CBC 80B 条) 匹配 tf+496 当前省 (陆省换战略区) → 命中推入 tf+1832 naval_headquarter 容器; 前/后串行 pass sub_140D752B0/140D750B0 向总部对象 +48 注册表推 {旗 1/0, tf+824} 32B 订阅标记); 门 = sub_1401AEB50(52) 设置位测试 (dword_14332F248) | tbb join A |
| 2 | hourly_parallel: 国家数组拷贝双键排序 (键 = cc+5488 EWMA + cc+668 师数; >32 元素 sub_1401B6BE0 并行归并, 否则 sub_1401B6870 插入) → tbb parallel_for (auto_partitioner) 每国 sub_1406FDBA0 (countryHourlyUpdateOnlyChangeSafePrivateAndCache; EWMA stamp 头 sub_140CFEAD0 / 尾 sub_140CFEAF0, 作用于 cc+5424 块, 5496 = 块内 +72 槽) | **tbb join B** (阻塞) |
| 3 | sub_1401E4700 = **CGameState::ProcessDeferredTargetedDecisions**: Country Deferred + State Deferred Targeted Decisions 两段 (域名串直证) | 串行 |
| 4 | **DoTradeRoutesUpdate** (sub_1401D9890, §4.21.1b): 守卫对 sub_1401B79E0/B7A40 夹 (推定并行只读窗); 内部 sub_1401B1860 = PdxParallelCombine 合并段 (start_for 符号直证; 串行兜底逐国 + _InterlockedAdd 计数) | 内部 tbb |
| 5 | HourlyCountryComponentUpdate 串行逐活跃国六 pass: ① sub_1406FDEA0 theatre 小时推进+失效移除 ("Removing Theater %s from %s" country.cpp:4649; cc+360 战区指针数组, 归属 tag 无存活国 → swap-delete); ② sub_1406FD710 cc+5136 关注 tag 表失效清理 (token 14346 war_relation, 对端 +5160/+5184 并行表双向摘除); ③ sub_140F080F0(gs+784) 段级一次性 — 语料空洞 (三查确认: 无 marker/无体/不在 pdata; theatre.cpp 编译区, 推定战区管理器国家级整体刷新); ④ sub_1406FDE80 **CProductionStatus (cc+3944) 生产小时推进** (RTDynamicCast CGeneralProductionLine→CBuildingProductionLine, 不可建取消 + 联动对方国); 另 **sub_140E696E0 = CProductionStatus 每小时维护主入口** (定案: 三段全队列扫描 — +88 批筛 / +1192 旗分支 / +112 建筑线可建校验; 热点 = 每脏国每小时×全队列, +1192 脏旗源 = 州日更 MODIFIER_LOCAL_FACTORIES); ⑤ sub_1406FE1A0 capital 完整性检查 (串与选都/迁都逻辑实际宿主 = **sub_140718B60**, country.cpp:7071; "<TAG> has NO capital defined." → terminate; 失守 → sub_1406D88A0 选都 + 140710DD0 迁都); ⑥ sub_1406FD800 多组件复合 = **country.delayed_events** (cc+4752 数组, +196 倒计时到点 140A0F6F0 发射) → **country.calc_modifier** (MODIFIER_DECISION/MISSION_PREFIX) → **decision.hourly** (cc+4000; 内部结构 = sub_14072FC90: 挂起双表清空 → sub_140731CF0 门 → **sub_140738260 "Decision.UpdateTargetedDecisions"** 失效清扫+待激活实例化 sub_140725C90 → 到期清扫 → 六子 pass (含 sub_140737670 should_activate, CTimedDecision) → sub_1406DADE0 通知 → sub_1407378E0 清场; 可用性评估 sub_1407313C0 带 **byte_14332F632 bypass 旗**; 激活执行 sub_1407357F0 挂 CDecisionCooldown; 可见列表 sub_140727570) → cc+4024 装备市场 → cc+808 人力缓存 → cc+4032 情报机构 → cc+5544 **间谍行动 hourly** → cc+4080 **顾问槽刷新** → cc+4744 懒缓存重算 → **错峰日步 `hour == tag%24` 时 cc+5632 = DEFAULT_COASTAL_PROTECTION_STABILITY × 同阵营占比** (defines_game.h:70); ⑥ 为唯一在循环体内嵌帧保活重入的 pass | 串行 |
| 6 | 第 7 串行 pass: 逐活跃国 sub_14070F0A0 = **军队/舰队/铁路炮归属一致性清理** ("Army has wrong country ( " / "Fleet has wrong country ( " / "Fleet has no country, removing from " / "RailwayGun has wrong country" country.cpp 四串直证) | 串行 |
| 7 | 军队收集: 逐国收集 CArmy* 进本地数组 → tbb parallel_for (start_for 符号 = PdxParallelForContainer(CPdxArray\<CArmy\*\>); memfn = **sub_140C88A70 CArmy::HourlyUpdate**: gs+2617 门 → sub_1414E4780、+1192 倒数、**army+1080 attrition 缓存重算** (§4.18.14)、+976 求和 ×100000 写 +1208) | **tbb join C** (阻塞) |
| 8 | 海军可达性: gs+1032 管理器 (scoped_ptr, "_pPtr" 断言) 调用方临时置 +32=1 → sub_140E255E0 (→ sub_140E24860 PdxParallelForContainer 派发, EJobType=1; 串行叶 sub_1419EE650, §4.21) → 复位 +32=0 | **tbb join D** (阻塞) |
| 9 | CTaskForce 波次 #2: 重收集 → sub_1401B1AF0 并行 (memfn = **sub_140D71760 CTaskForce::HourlyUpdate** 高置信: idpair 解析 → 海军区域查询写 tf+1616 → 逐舰船 +840 数组三连 sub_140C32E10/C32C90/C3E4A0) | **tbb join E** (阻塞) |
| 10 | hourlyUpdateUnits: 占领 bundle 包夹 (sub_140EED690 ++ / sub_140EF2F30 −−, 计数归零 → profiler "theatremanager.endbundle" 复位 g_OccupationBundleConquer/Relation, theatre.cpp:5572) 内逐活跃国 sub_140717BC0 = **全单位 vt[18] 小时 tick 串行驱动**: ① cc+656 师容器逐师调 **vt[18]** (144 槽 = CArmy::[18] 0x140C881D0 每师每小时总入口, §4.18) + sub_140C00000 战中场次计数 → cc+4904; ② cc+632 舰队容器快照拷贝逐元调 **sub_140D577F0 = CFleet 小时驱动** (定案: fleet+176 有效性预处理 → 快照 task_force 容器 → 重组分支 (sub_140D51360 真 sub_140D530E0 / 假 sub_140D5A660 按 tf+884 分桶) → 逐 CTaskForce 双断言 fleet.cpp:548/550 调 **vt[18] = 0x140D705F0 移动更新**); ③ cc+680 铁路炮容器逐元调 vt[18] (CRailwayGun::[18] 0x140E8B8E0); 调试门 byte_143452529 仅包军队数/装备占用 before/after 条件日志 (country.cpp:13281/13314), vt[18] 循环无条件执行; 主线程采样占比 ~8-11% = hourly 调度内最重单件; 兄弟调用 sub_1407164E0 (**CCountryFuelStatus 燃料小时结算** cc+5504, §4.3.16) | 串行 (bundle 窗口) |
| 11 | 错峰日步 (**两套, 定案**): 同一相位源 `hour = (gs+1128 − 43800000) % 24` 分两腿 — ① tbb parallel_for (lambda_5) 每师门 `hour%24 == 师 id%24` (**无 +1**) → C881D0 内联日更块 = **CArmyRequests (+1144)**: 141510110 到期判断 (到期 14150F740 重建请求 + 经验按 +976 need/value 折减) + 14150E460 每小时无条件推进 (reinforcement/upgrades delivery → 140C78E90 装备入 +840 池 → 触发 vt[22] RefreshAbilities); ② 串行尾遍门 `((army+28 师 id)+1) % 24 == hour` (**有 +1**) → **sub_140C89090 指挥链聚合重建** (army+1584 leader 旗门; → army+192 = _pOrdersGroup → **og+136 = CArmyLeader\*** (§4.24.3) → sub_140C20F70 = 清**将领对象** 8 统计容器 +1816/+2008/+2200/+2392/+2968/+3160/+2584/+2776 (坐标 = 将领非 army) + 从将领 +3528 数组 (count@+3540) 四组键 (+864/+1056/+1248/+1440) 重灌 + vt[28] (0x140C20FA0 四槽聚合) + vt[30] + 将领名串广播; 聚合对象 = **CArmyLeader** 定案; ⚠ §4.18「国+136」坐标勘正为 og+136) — 相位差 +1 使指挥链与 requests 重建错日撞车, 各每师每天恰一次 | **tbb join F** (阻塞) |
| 12 | postHourlyUpdate (sub_140705630): ① sub_1406FF1F0 批量重算本小时累积修改器后 **cc+4320 清零** (§4.3.23); ② `(tag_idx + gs 小时) % 24 == 0` 错峰每日脉冲 → 确定性 random_int (random.cpp:258) → 构造 CEventScope → on_action ×2 (§4.2.9) — **on_daily 派发**; ③ cc+4880 72B/项桶数组 (计数 +4892) 逐桶到期处理 — **桶 = 核弹在途打击 CNuclearStrike** (24B 条 {+8=13718, +16 省 id, +20 飞行小时}; 相位 0 sub_14109A520 推进 / 本相位 sub_141098460 到期结算 sub_1410986E0 + 压缩删除, §4.3.10a); ④ cc+4744 convoys 派生值缓存重算 | 串行 |

> 备注: tbb 机制件 (join B 三件套, start_for 实例): 入口 sub_1401F7380 (execute 槽[1],
> 78B) → sub_1401B8650 (分裂派生) → sub_1401BB280 (等待/偷取 + 串行收尾逐国调
> sub_1406FDBA0); 分块粒度助手 sub_1401DB390 (EJobType 0→线程数 / 1→3×线程数 / 2→1,
> pdx_task.cpp:397)。并行发射体全景 (start_for 符号定案): +1BA6F0 daily 国家波 /
> +1BAA00 贸易 PdxParallelCombine / +1BACB0 军队 lambda_5 波 / +1BAF90 CArmy Mem_fn 波;
> +1C7B50 = combine 跨区间配对收集核 (原子计数+自旋锁); +1F7290/1F7470/1F7880/1F78D0 =
> 四个 start_for::execute 入口 (虚槽发射, 无文本调用者); **oneDPL (std::execution) 与
> PdxParallel 混用** (+1F7880/+1F78D0 族, parallel_policy_v1_execution_dpl_oneapi 符号直证)。

hourly 粒度收尾两函数 (骨架 §4.2.4 步骤 16/17):

| 函数 | 语义 |
|---|---|
| sub_1401D6290 | to_be_deleted 队列清扫 (gs+1224/1236, SRWLock, gamestate.cpp:5732 断言): idpair→对象 (sub_14221F310 三级表) → RTTI 判 CUnit → DeleteUnit (sub_1401D6690, "RemoveReferences from DeleteUnit" @ gamestate.cpp:7156); 非 unit 条目留队 |
| sub_1401D7460 | to_be_deleted **登记侧** (gamestate.cpp:6934 "Delete unit next"): SRWLock 独占下 unit idpair (+24, 8B) 二分插入 gs+1224 有序数组 (计数 gs+1236); 已在 gs+1400 数组 (计数 gs+1412) 则跳过 — 与 sub_1401D6290 清扫配对; 入径 = CArmy::[18] 兵力阈值解散 + DF7A40 卡死删除 |
| sub_140BBED50(gs+1248) | CPeaceConferenceManager 每小时推进: sub_140BBEDA0 逐和会推进+收割 (+221 结束旗); 首个和会经 sub_140E50B20 人类参与守门 — **human_ai 全局旗 (BASE+0x332F639) 在此参与判定**, 被托管时 AI 自动接手 (sub_140E50BB0) |

> **和会人类守门 sub_140E50B20 双条件定案** (human_ai 托管和会死锁根因, 运行时探针 + 反编译直证): 遍历 conf+96 OutWinners 逐国判定, 命中任一即返回「需等待人类」(= 跳过 sub_140E50BB0 AI 接手): ① sub_140700750(国) 人控 且 byte_14332F639=0 (human_ai 关) — human_ai 开则此条件失效 ✓; ② **sub_1402AA8A0(国) = 控制台 `ai` 命令族扮演判定 (byte_14332F63C 旗 + qword_14332F668/674 扮演国指针表)** — human_ai 不写这簇, 与 ① 完全正交。sub_1402AA8A0 语义: 63C=1 (白名单, 控制台 `ai` 开, 回显 "AI is now ON"): 空表→0 / 在表→1 / 不在→0; 63C=0 (黑名单, 默认): **空表→1 / 在表→0 / 不在→1**。默认态 (63C=0, 空表) 对全部国家返回 1 → 守门恒「等待」→ **human_ai 单开时和会死锁** (UI 全按钮无响应, 进度条冻结, conf+216 turn=0 / +220 waiting=1 / +456 已表态空; 实证: GER_1941_11_19_06 档 1942.1 赫尔辛基条约卡死, conf+520 negotiator=主胜方 tag)。**修复 = 控制台 `ai` 一次** (63C→1 空白名单全员 return 0 → 守门 return 0 → 下个 hourly sub_140E50BB0 自动接手, 和会当小时结算)。`ai` 副作用 = 全局「无人类扮演国」态, 与 human_ai 托管目标一致。

#### 4.2.7 daily (CGameState::DailyUpdate, sub_1401D4810)

profiler 域 **"gamestate.daily"**; gamestate.cpp:6227/6310 source_location。
触发: 日边界 (骨架 §4.2.4 步骤 11)。

> 调用者二通道 (定案): ① tick 日边界门 (常规); ② **CInGameIdler::InitData = sub_140DD6A30**
> (ingameidler.cpp:4888→5119, profiler 域串直证) 开局/读档完成初始链 — 顺序 =
> **Hourly (sub_1401DF400) → Weekly (sub_1401F2430) → Daily → Monthly (sub_1401E34F0)**
> 各一遍 (dump 行序 L7065010-13 直证; 旧字面序「+Daily+Weekly」废; 两路分叉与全链
> 定案见 §4.28.18 InitData 链表)。

系统序列 (32 步归并):

| 序 | 子系统 | 要点 |
|---|---|---|
| 1 | 力量平衡 daily +1104 | sub_140E560D0: 逐 CPowerBalance 条目 `value += Σ成员国 cc+1464 键152 (MODIFIER_POWER_BALANCE_DAILY, idmap:153)` → range 定位/切换 (旧 on_deactivate/新 on_activate) → `trend = Σ键153 + 7×Σ键152` 定 trending 侧 (负=left/正=right); weekly 版 sub_140E58B90 同构 |
| 2 | 空军 +1680 / 海军 +1688 / 铁路 +992 | **CStrategicAirManager::DailyUpdate = sub_140C50040** ("airmanager.daily", strategicair.cpp:6097; 计时域 8) 五拍: 前置重算 sub_140C65E90 → 逐活跃国 tbb 并行 → 串行逐国逐区域逐翼 sub_140F5D820 (训练经验 AIR_WING_COUNTRY_XP_FROM_TRAINING_FACTOR, 按飞机份额分给远征贡献国) → 24B/国暂存表 PdxParallelFor → 串行回填 sub_140C4C150; 另含区域港口打击限制并行重算 + 空军基地访问授权重算与亡国清理; 活跃国下标表 = gs+2464 (hourly 预收集产物, daily 只消费不重收集); **CStrategicNavyManager::DailyUpdate = sub_140EA33C0** ("navymanager.daily"; 计时域 9; 槽 gs+1688 thunk sub_1401C6C30): 薄循环逐国 [1,count), 体 = **sub_140EA2FD0** 六步 = tag%7 **周**错峰 access 缓存重建 + 观察省清零 + per_region_danger 周衰减 + required_convoys 逐区域重算 + 护航效率恢复 (CONVOY_EFFICIENCY_REGAIN_* 双 define) + 护航存在史环形缓冲 — 海军任务推进在每小时版, 非此 |
| 3 | 州并行 | CStateDailyUpdateThreaded (vt 0x1427233F0), 州 [1, count) (数组 gs+712): 逐州 worker sub_1409D7760 = **按州 id%N 错峰** (`id%N == gs+1156 年积日%N`, N = dword_14332F650 运行时 define; owner 亡国强制) 掷**州事件候选**入 st+2000 队列 (确定性 RNG) → 结算到期 temporary_resource → CResistance 推进 + 占领表双缓冲换位 + 三类 modifier 重建, **MODIFIER_LOCAL_FACTORIES (mdef 65) 变化 → 生产脏旗 cc+3944+1192** |
| 4 | 活跃国过滤 | **cc+1156 = owned_states 计数 > 0** 为活跃 (与 weekly/monthly 同门); 序 4a gs+992 = **CRailwayManager 铁路冷却日递减 = sub_140E942F0** (railway_manager.cpp:544 "IsOnCooldown"; 槽 thunk sub_1401C6AB0): 冷却表 {数据@+32, 计数@+44} 倒序逐条, 铁路条目 +104 计数 −−, 归零 → 调 gs+984 CSupplySystem 虚槽[+24] 刷补给网节点 + swap-remove |
| 5 | 情报每日结算 | **sub_1401D3420 (daily 序属; 唯一调用点在 DailyUpdate 体内 L4939435)** 六段管线 (全链定案见下方备注表): 前置聚合 → 上限/权重表打包 → 修复合成+资源观测基准 → 逐国四象限计算核 (**静 ≤6 + 动 ≤7 池** + INTEL_COUNTRY_LEVEL_MAXIMUMS 等级钳位) → 逐来源加权折算 + mdef 507–510 四通道缩放 → 并查集网络分组取 max 摊共享加成 → 应用收尾; 资源观测基准实体 = sub_140D02EB0 (countryintel.cpp:391 断言, mdef 549–552); 逐国结果槽 = 24B/国 (类型实名 **SCountryIntelInstance**, HybridInlineBuffer 分配器 vtable 名直证); 0xD0 区采样帧另含情报求差/容器深拷贝/串族, 与本链两集合不同 |
| 6 | 战略区域并行 | "daily.strategic_region_update": **CNavalRegionDominance 制海权每日重算** — current ← previous×日比例、decline_from = target/(target+外部)×1e5、重建排序优势条目表 |
| 7 | 占领 | "daily.occupation_update": 串行逐**占领者**国 → CCountryOccupationStatus (cc+4048) 六阶段: 选驻军模板 / 占领法重验换法 (countryoccupationstatus.cpp:561) / 抵抗州↔记录对账 / **逐控制州合规/抵抗推进** (res+64 += res+72, res+16 += res+24, ×1e-5 顶 10000000) / 记录明细 / 失效清理 |
| 8 | 州合规修复 | sub_1409D73E0: CResistance 变化刷地图 → **省控制权漂移修复** (州 owner≠省 controller 且非战争豁免 → 归还; 无主州 → SetOwner=控制者, state.cpp:2295) → **不可通行州 (湖) 邻居推举控制器** (state.cpp:2108/2110/2205) → 空军基地随控制权换主 (state.cpp:1763 "air base without access") |
| 9 | 研究共享 | "tech_share.daily", **CTechnologySharingGroup** (vt 0x142721740 19 槽) 虚表槽[9]: **只做成员资格巡检** (模板+152 scoped_ptr\<CTrigger\> available 键 12264 求值不满足 → 研究侧摘链 + 槽[11]踢除; 空 = 恒真); **加成传播不在 daily** — join/leave 即时双向维护 (组 ↔ ts+280), 数值无缓存槽, 研究成本求值时懒计算 (sub_140ED6E30→sub_140ED6C10→sub_140D821E0) |
| 10 | 国家 daily 并行 | "country.daily_parallel" (gamestate.cpp:6310) 活跃国 + 全量国成员函数 sub_1406E8C70; 其内调 **sub_1406E8210 = 事件检查波** (逐国相位门 cc+4750 == gs+1156 年积日 % EVENT_PROCESS_OFFSET(20) 才跑 CEventManager::AddEventsToFire, 掷中候选入 cc+4776; 州侧同构 sub_1409D7760 相位 st+2032, §4.12.8) |
| 11 | 外交两 pass | FirstPass (sub_140D357E0): 重建每国 dip+248 敌国集 + **dip+344 分类码** (§4.10 已改) + 阵营敌意聚合; SecondPass: 聚合派系成员/宗主-附属链 → **dip+272/+296 共同敌国**; 两遍原因 = pass2 消费 pass1 产物 (并行一致性: 先各写自己再互读新账) |
| 12 | 学说 daily +1024 | **NDoctrines::CDoctrineSystem::DailyUpdate** (tbb 符号直证): 对 CPdxArray<CCountryDoctrineStatus> 两遍并行 (mastery 日结算 + 求值/终结) |
| 13 | **CCountry::DailyUpdate** (sub_1406E76A0) | 门 = cc+1156>0; 活跃分支 31 步: 内战目标清理 → exile_divisions_transfer 到期 → 人力/生产/资源/科研/部署 → 市场 → 旗/政治/外交/核弹/焦点/后勤/燃料/operations/经验 → **on_border_war_lost** (门 = 控制州 state+2149 活跃旗 且 进度 > define BORDER_WAR_VICTORY, 派发后 sub_1409DDA30 熄火) → army.daily (虚表槽[19] 字节+152) → 志愿/远征军所有权重整 → fleets.daily (快照迭代) → railway_guns.daily → **logistics.daily** (sub_141371390 计时作用域) → **投降/流亡日更 sub_1406E16C0** ("Attempting to surrender to nulltag" / FACTION_LEADER_CAPITULATED / BECAME_EXILE) → trade_influence.daily → 志愿军清扫 → 剧场 → incoming 外交+角色+特殊项目 → **queued_events 延迟事件派发后清表** (串行段 "country.queued_events": 逐条再复核 trigger → sub_140A0F4F0 → sub_140A0F6F0 真发射, §4.12.8) → 修正重算门; 串行段第 4 步生产 = **sub_140E670A0 "production.daily_serial"** (§4.8.13; 在 sub_140CABB30 "resources.daily" 前); 焦点 = **sub_1402D0260(fp) "nationalfocus.daily"** (§4.3.15a; politics cc+3976 后、logistics cc+3992 前); 非活跃分支仅军队维护+投降判定; 每 5 国插帧保活重入 |
| 14 | post_daily 并行 | CCountryPostDailyUpdateThreaded (RTTI 定名, 活跃国, 每国 SRW 锁): **AI 战略日更 + logistics.postdailythreaded + CLoopHistory 国史** — 三件并行安全活挪出串行段 |
| 15 | 生产快照 + AI 国家战略 | sub_1406E8C70 (全量国 tbb 并行) = **CProductionStatus 容器 F(+1208)→B(+208) 快照发布 memcpy** (B = AI 生产挑选, 轻量 AI 喂数, 与序 13 重头 31 步分工); AI 国家战略: 串行 sub_14066A580 = **CStrategy 5-9 天随机间隔重算**; 并行 sub_14066A050 = 每日全量 Update (ai_strategy.cpp:476 + 112 槽冲账表 + 战争领袖变更检测); 门 = AI 启用旗 (ai+96) + 激活旗 (+99) — **非决议/焦点** |
| 16 | 阵营二次 +1016 / 市场 +1000 / 突袭 +1008 / 天气 +1672 | 阵营 daily 双入口 (实际顺序 = theater 版 sub_140D935A0 → sub_140D8D850 (仅 DLC50 门 + fac+2552 CFactionTheaterManager) 在**前**; 五步内务 sub_140D93560 → **sub_140D8D490** 在后 = ①goal 进度 (CProgress 求值 → CProgressStatus 双半缩放) ②升级 = 共享巡检 ③项目贡献 ④**CFaction::UpdateInfluence** 矩阵 ⑤**PassiveInitiativeGeneration** initiative 分摊, 详 §4.5.9); 装备市场 = **sub_140DEC850 合同快照遍历 → 逐合同 sub_1419D49C0** (cli 护运 Update + days++ + 到期结算 + 周期重启 + 延期架 flush, 全链 §4.23.3a); 突袭 daily = **sub_140E85ED0 目标表 fold** (计时域 12 内; 逐目标 sub_1414E9540 条目 +56 递减, 到期清除 + 亡国清整表); 天气 daily = **sub_140F186A0** (计时域 7; 槽 gs+1672 thunk sub_1401C6DB0): 逐天气区域 (mgr+40 数组, 计数 +52) 的定时修正表 {数据@+328, 计数@+340, 16B/条目} 天数 −− 到期 memcpy 摘除, 有摘除则 sub_140F21C60 重算 (省份自定义天气修正; 模拟演化在 hourly) |
| 17 | history logger 日更 | **CHistoryLogger::OnDailyUpdate 驱动器 = sub_1402C09B0** (门 = history logger 旗 byte_14332F625, settings 键 `dump_history` 亦可置位, toggle 回显 "History logger : on/off"): 天计数 (+88)++ + 状态字 (+108) = 5 → tbb PdxParallelForContainer 逐国发射 CHistoryLogger::OnDailyUpdate; 锁 = AcquireSRWLockExclusive(idler+2584) 护 idler+2576 = CHistoryLogger 对象 (qword_14332F698/6A0 = 同一 idler 指针双别名); weekly 尾对同一锁只做空获取/释放 (护卫体内无调用, dump 侧被内联/裁剪, 待裁) |
| 18 | 旗/事件/渲染/紧张度/兵棋 | sub_140CBFA90 = **flag_manager.daily** (profiler 直证): 定时旗 u16 天数倒数到期摘除; sub_1401F0AF0 = **pending_events (gs+1376) 过期清除** (gamestate.cpp:4548, 只清除不派发); sub_140F2D910 = 玩家国 operations 结构快照 diff (变则 ++全局版本号驱动 GUI 重建; 四件 = sub_140F28190/F28290/F28450/F28610, 静态槽 unk_14333D4xx diff 写/判定); sub_140EF2F30 = **占领 bundle 收口** (与 sub_140EED690 配对 — 中段整个跑在 bundle 窗口内); sub_140DF8520 = 地图季节调色板按日期插值 (纯渲染, Tree_season.bmp); sub_140F05110 = **CWorldThreat 世界紧张度按日期进度向目标漂移** + 死条目清扫, 条目衰减体 = sub_140F04EE0 (tension@+16 每步 ±TENSION_DECAY_DAILY (NDiplomacy, defines_diplomacy.h), 装载钳 [0,1e7], 收敛向锚 +24, 交战国免衰减 — 定案) |
| 19 | career profile | HasGameStarted (gs+2617) 门 → sub_1401D8400; ⚠ **序内更早的 sub_1401F1190 = gs major top-K IC 重算** (hourly 无条件, ai_update 后; K = max(MIN_MAJOR_COUNTRIES=7, 2), top-N 重排兼写 cc+5211 top-IC 旗; 产物 gs+2168 top-IC 均值 (除零护栏写 −1) / gs+1320 紧张度基准国; 0.7×均值补判 = monthly 无阵营国晋升通道消费), 非 career profile |

> 备注: **序 5 情报结算六段管线** (sub_1401D3420, 1100 行本体定案; 旧括注「机构分支
> (≤8) 步进」废 — 本体无该分支, 池上限 = 静 6/动 7, 与 §4.11.7 ctor 直证互证):
> ① 前置聚合 sub_140ED1DB0 = 每活跃国阵营/关联国集 32B 四象限求和 + 命中门关联国
> 二分插入排序表 (双容器输出);
> ② 表打包 = 静态上限 440B sub_140D05260 (INTEL_COUNTRY_LEVEL_MAXIMUMS 4×i64 缺省
> 100000 + 静源 4 槽 OP_TOKENS/BROKEN_CYPHER/RADAR/INTEL_NETWORK (**define 表序非池槽序**;
> RADAR 静源池槽 = 3, radar.cpp 三站点直证 §4.11.19), countryintel.cpp:98–112
> 断言直证; tooltip sub_141E9CAF0 双消费点) / 动态绝对上限 336B sub_140D04D70 (6 槽
> DYNAMIC_INTEL_SOURCE_*_ABSOLUTE_MAXIMUMS, :157–162, 缺省哨兵 92233720200000) /
> 权重 12 qword define (qword_143335C60 族);
> ③ 基准 = 修复合成 (mdef 208–211 两对 (1+add)×mul/1e5, **待 PE 验算**) + 资源观测
> sub_140D02EB0 (mdef 549–552 四象限基准);
> ④ 逐国计算 = 静池键 sub_140D02FB0 (ci+160, 72B/池) + 动池键 sub_140D04050 (ci+184,
> 56B/池) → 计算核 sub_140D02C30 (≤6 静 + ≤7 动逐源累计 + 等级上限钳位) → 加权折算
> sub_1401CE9A0 (ratio = 1e5×(计数+1e5)/(值+1e5), **待 PE 验算**) + mdef 507–510
> 四通道缩放 (**待 PE 验算**) → 主矩阵落行 sub_140D02970 (ci+112 prev_day ← ci+88 当日矩阵日界深拷贝) + 静源槽重建 sub_140D06820
> (清 +64 区/+88 列表按键重插; 静池逐池摘除 sub_140D03640 = remove 旗 swap-delete 消费点;
> 动态池逐池日结 fold 对 sub_140D071A0 accumulator 拍钳 7 池上限 + sub_140D035C0 values 拍) + 动态写回 (sub_140D06610) + 应用 (sub_140D06670); 伴随日结 = CRadarsPool (cc+4344) sub_140716510 / CCountryOperationTokenManager sub_1407164F0 / CCryptology (*(cc+4032)+288) sub_1407164C0; 取用器 = cc+4072 scoped_ptr thunk sub_1406CF760;
> ⑤ 网络共享 = 并查集分组 sub_1401CE2F0 (cc+3976 对象共享键: +392 id>0 → 共享国,
> 否则 +656 子对象 → +88 链首; 载体类名待裁) → 组内四象限 elementwise max → 共享加成 =
> qword_1433317A8 × (max−own)/1e5 (**待 PE 验算**) → sub_140D065B0 写回;
> ⑥ 应用收尾 sub_140D06670 (聚合槽) + sub_140D035C0 (权重表)。
> 备注: **特工推进单节拍 (每日)**: DailyUpdate 早期 (序 2 与序 4a 之间, gs+1696 非空门)
> 无条件调 sub_140EB2EC0 = 特工七连推进 — 全库唯一调用点; hourly §4.2.6 序 9 的
> +1696 派发实为 assert 空转 (sub_140EB3050), 谍报网重建/propaganda EWMA/双 PID
> 均每日一次, 非每小时。
> 备注: daily/hourly 各表中的 `sub_1401C6xx` 取用器全是 `pdx::scoped_ptr` 惰性解引用
> thunk (pdx_scopedptr.h:124 "_pPtr"), 业务语义在解引用后的真函数 — 读表按
> "取用器+真函数"两层理解。**thunk→槽位映射全表** (定案): sub_1401C6AB0 → gs+992 铁路管理器 /
> sub_1401C6BB0 → gs+1680 空军战略管理器 / sub_1401C6C30 → gs+1688 海军战略管理器 /
> sub_1401C6CB0 → gs+1696 特工管理器 / sub_1401C6DB0 → gs+1672 天气管理器 /
> sub_1401C66B0 → gs+1704 CCharacterManager / sub_1401C6730 → gs+1024 学说系统 /
> sub_1401C6830 → gs+1016 阵营系统 / sub_1401C6F30 → gs+1088 CGameRulesInstance /
> sub_1401C6E30 → gs+1712 CWorldThreat (DailyUpdate 尾直喂 sub_140F05110);
> 偏移变体 sub_1401FAD80 (pdx_scopedptr.h:129) → 设置单例 qword_14332F408+800 规则源表
> (仅重置/装载链消费, §4.28.18 步 4)。序 14 每国 SRW 锁的解锁半件 = sub_1401C1E60
> ({锁@+8, 持锁旗@+16} 形)。
> 备注: **确定性 RNG 双旗纪律** (定案, 与逐值对拍直接相关): ① 全局 byte_143452528 =
> random.cpp `IsForbidden` 禁止旗 — 置位期掷随机触发 "Calling random inside forbidden
> area! OUT OF SYNC" 断言 (设置转调件 sub_140151D20); ② TLS+88 = 每线程 AllowRandom 旗
> (ai_strategy.cpp:299 断言消费), 进入半件 sub_14064BAA0 / 清除半件 sub_14064C920 —
> post_daily worker (sub_140705580, 钉名) 与 DailyUpdate 国家并行段均以置/清对包住
> 会掷随机的段。探针在读档/重置链外掷随机前应自查两旗。伴生设施 = random 调用记录环
> (72×40B 槽, 清场/重置件 sub_142233720, 各槽写基准日期 43800000 = 统计窗起点, OOS 调试域)。
> 备注: **"country.calc_modifier" (sub_1406DADE0) = 13 pass 修正重算** (顺序定案; 首尾
> 以 mdef 104 旧/新值探 dirty, 变化则 sub_140E6D830(cc+3944) 传播): pass 1 清空聚合
> sub_1405583A0 → 2 生产/政治前置 (sub_140E65F30 / sub_140EE2610 / sub_140BB0030) →
> 3 内战/占领政府 sub_140D89FD0 → 4 全局规则修正 (gs) → 5 数组容器族 → 6 决议/任务
> 前缀查名合并 ×4 组 → 7 ideas/民族精神 sub_14119D900 → 8 attache (token 14553) /
> POTF 沉没舰队门 → 9 **动态修正聚合结果** (sub_140557BF0 求值 + sub_140557840
> cc+1464 ← CModifier#2 缩放并入) → 10 流亡/志愿族 (cc+1120 数组经 sub_1410DB210
> 转换合并) → 11 军事组织族 → 12 **难度五档** diff_{very_easy,easy,normal,hard,
> very_hard}_{ai,player} (gs+1584 难度 + IsAI, 按名查 def sub_14055D480) → 13 间谍
> 数组/宗主/难度曲线插值 (1433314F8/143330E98) → 尾 sub_1410F82C0(cc+5504) 燃料重算。
> 调度 = 每小时相位 6 pass⑥ + DailyUpdate 尾部重算门 + MonthlyUpdate pass; 事件驱动
> 补跑 10 个直接调用点 (决议激活/idea 变更等 effect 触发)。

#### 4.2.8 weekly (CGameState::WeeklyUpdate, sub_1401F2430)

profiler 域 **"gamestate.weekly"**。极简版 daily:

| 序 | 子系统 | 要点 |
|---|---|---|
| 1 | 力量平衡 weekly +1104 | sub_140E58B90: 与 daily 版 (sub_140E560D0) 逐行同构, **唯一差异 = 成员国修正键 153 (MODIFIER_POWER_BALANCE_WEEKLY)** (daily 用键 152) |
| 2 | 州 weekly | sub_1409E09B0 = **抵抗破坏工厂** (state.cpp:2323): 占领国州级修正 MODIFIER_LOCAL_FACTORY_SABOTAGE (mdef 76) 作每周概率 (random_fixed ∈[0,100000)), 命中 → 随机选州内 1 条有等级建筑, 伤害 = SABOTAGE_FACTORY_DAMAGE(100.0)×(1+抵抗度), clamp ≤1 级 |
| 3 | 国 weekly | **sub_140718CA0 = CCountry::WeeklyUpdate** (country.cpp:5793): 周累加族 — cc+5312 宣传稳定惩罚 clamp [MAX_PROPAGANDA_STABILITY_IMPACT=−0.2, 硬编码 0 上界] / cc+4304 stability clamp [0,1] / cc+5320..5344 四战争支持度惩罚 adder = max(stat×SCALE, −0.006 周内限) + decay(+0.001) + mod599/600/601, 逐字段 轰炸+5320 −0.3 / 英雄+5328 −0.3 (人控国含 human_ai 旗 ÷600, AI ÷200) / 护航+5336 −0.5 / 宣传+5344 −0.2, clamp [define 负下界, 硬编码 0 上界] / cc+4312 war_support clamp [MIN/MAX_WAR_SUPPORT = 0/1, 双 define] / WEEKLY_MANPOWER (mdef 62) + 流亡 mdef 588 人力 / 占领日志按 GARRISON_LOG_MAX_MONTHS(12) 清理; **on_weekly 派发点** (§4.2.9); major 断言 = cc+5210 与 GetMajors 表一致性 (country.cpp:5810, debug 一次性) |
| 4 | DoCareerProfileWeeklyUpdate | gs+2240 tag 数组 tbb 并行, 分裂树 sub_1401BCA30 |
| 0/5 | 帧泵 + 锁刷写 | 首尾帧泵①② (帧预算门 sub_1402A3210 + idler+1328 槽[17] 泵) + 尾 profiler 锁刷写 (idler+2576/+2584) — 与 daily 同构, 旧表漏行; ⚠ weekly 尾该锁为空获取/释放 (护卫体内无调用, 实体疑被内联/裁剪, 待裁 — 与 daily 序 17 CHistoryLogger 实刷不同) |

**CCountry::WeeklyUpdate sub_140718CA0** (country.cpp:5793, 定案) 十步主干:
① **collaboration 加权随机投降接收国周刷新** (写 cc+12, 与投降流共用
sub_1406DA380; "SurrenderRecipient.IsValid()" 断言) ②/④ 宣传惩罚源 = 谍报
每国对象 +312/+304 (propaganda_weekly_drift.stability/war_support) ③ cc+5312
宣传稳定惩罚 / cc+4304 stability / cc+5320..5344 四战争支持度惩罚 —
修正键 599/600/601 = MODIFIER_WEEKLY_CASUALTIES/CONVOYS/BOMBING_WAR_SUPPORT
(+ MAX_*/\*_DECAY 族) ⑤ WEEKLY_MANPOWER (mdef 62) + 流亡 mdef 588 人力
⑥ 占领日志 GARRISON_LOG_MAX_MONTHS(12) 清理 (sub_140FFF5D0) ⑦ **on_weekly
派发** (§4.2.9) ⑧ characters 域 scoped_ptr 空过 (返回值丢弃 = 域负证)
⑨ **物流 weekly = sub_141375A20 (thunk) → sub_141375840**: 全体国仓库
(+520/+532) 装备条目推队列 + 仅人控国 (gs+880/+904) 全装备库
current−(want+queued) 缺口重算 ⑩ major 断言 (country.cpp:5810 debug 一次性);
gs+820 = GetMajors 计数。

**AI 域 weekly machinery (定案)**: CAICore vt[7] (sub_1402AD3A0: mode2 预清理
→ 基派发 → 收尾) + 各 AI 模块槽[15] 覆写 (军事/外交/内政部长 + 加密/建局/
行动优先/军事子 AI 七体; COperativesAi 无周更); tick 侧派发点未定位 (唯一
未决, 建议运行期断点)。

**逐域负证 (定案)**: 全语料 rhythm zone 清点 — weekly 后缀唯一 (gamestate.weekly
+ AI 模块树); production ("weekly_production" 仅 UI 文案)/construction/
deployment/focus/politics/technology/doctrines/army/navy/air/theatre/events/
decisions/operations/resources/market/raids/projects/occupations/resistance/
weather/faction/flag **全部无 weekly 通道** (zone 零命中 + gs weekly 不触
对应槽位 + 域册零记载)。

> 备注: weekly 触发在 hourly tick 内 **daily 调用紧后** (总天数 %7==0),
> 不在 daily 函数体内。开局初始化序列 (行 7065010 区段) 依次跑
> HourlyUpdate → WeeklyUpdate → DailyUpdate → MonthlyUpdate 各一遍。

#### 4.2.9 on_actions 派发机制 (on_daily / on_weekly / on_monthly / on_war 等状态型)

数据层 (定案): COnActionDataBase — `on_daily_<TAG>`/`on_weekly_<TAG>`/`on_monthly_<TAG>`
按国家 tag 存 +312 三列派发表 (24B/tag); PostLoad (sub_140A774B0) 另缓存通用
`on_daily`/`on_weekly`/`on_monthly` 于 +144/+152/+160。解析器 sub_140A760D0
(onaction.cpp:434/449/464 报错串)。

执行器 sub_140A79BA0 (全引擎 86 调用点统一入口, a4 全 0): HasGameStarted (gs+2617;
a4 = IgnoreGameRunningCheck 才可豁免) ∧ gs+2618 删除期断言 → 列表 +24 存活门 →
直挂事件 + random_events 加权掷骰均先过 sub_141180350 触发器门才入事件队列
(sub_140A0F4F0) → 内联 CEffect **槽[12] ExecuteChecked (vt+96)** 同步执行效果块
(非入队)。**脚本随机 = Random::Get 全局流** (dword_143452520 counter / dword_143452524
seed 混合; file/line 实参仅入调试日志与 OOS 记账环, 不参与求值 — 勘误: 原「总小时数 +
source_location id 派生种子」不成立, 函数体直证 + §4.28.13 播种双链互证; 流随存档
序列化键 11458/11459, 跨机确定性来自全局流本身)。

| on_action | 引擎派发函数 | 触发时机 |
|---|---|---|
| on_daily / on_daily_<TAG> | sub_140705630 = CCountry::PostHourlyUpdate (country.cpp:4861) | **hourly 主调度六阶段之 postHourlyUpdate 串行段**; 判据 `(tag + gs+1128 总小时) % 24 == 0` → 每国每天恰一次, 时辰由 tag 固定 (引擎把每日负载摊到 24 个 tick 的削峰设计); **与 CGameState::DailyUpdate 无关** |
| on_weekly / on_weekly_<TAG> | sub_140718CA0 = CCountry::WeeklyUpdate (country.cpp:5793) | CGameState::WeeklyUpdate 国循环内 (与引擎 weekly 同帧同刻) |
| on_monthly / on_monthly_<TAG> | sub_140703490 = CCountry::MonthlyUpdate (country.cpp:5677) | CGameState::MonthlyUpdate 国循环内 |
| on_war / on_uncapitulation 等状态型 | sub_140D46650（diplomacy.cpp; 高置信） | 非周期脉冲 — 国级按位更新派发器 sub_1406FF1F0 **bit7** (§4.3.23) 在状态变更后逐次评估; 事件选项执行 CSelectEventOptionCommand::Execute 亦经此位 (§4.33.18) |

> 备注: **无 on_hourly on_action** — on_action 最细粒度 = on_daily。
> 状态型内层链 sub_140D46650 → sub_140D357E0 → sub_14066B0D0 / sub_1407386A0
> (两者含 CEventScope 断言 "( pScope == this \|\| pScope->_pFrom != this )") — scope 的
> 建/拷/灭全在派发侧 (族函数 §4.00.4); 入队后消费路径未决。
> "decision.hourly" (§4.2.6 阶段 3) 是决策评估, 非 on_action;
> ABILITY_ON_HOURLY/ABILITY_ON_DAILY token 属单位能力冷却域 (非 on_actions 体系, 不在本册范围)。
> CCountry::DailyUpdate 内另有命名 on_action "on_border_war_lost" 触发点。

#### 4.2.10 monthly (CGameState::MonthlyUpdate, sub_1401E34F0)

profiler 域 **"gamestate.monthly"**。触发: 月边界 (骨架 §4.2.4 步骤 13);
月份==5 (6 月) 处仅 profiler 包装无额外调用。系统序列:

| 序 | 子系统 | 要点 |
|---|---|---|
| 1 | **CCountry::MonthlyUpdate** (sub_140703490) | 门 = owned_states>0 (cc+1156); 十段: dip 月更 (MONTHLY_LEASED_IC_DECAY 衰减 + 限时好恶刷新 + 脏表重建) / **major 全量重算** (判定谓词 sub_14070C1C0: 无宗主 && (is_major cc+5209 ∨ is_top_ic cc+5211 ∧ 工厂 ≥ MAJOR_MIN_FACTORIES=35) ∨ 阵营主 → cc+5210; 在阵营内不自动降级; 同谓词亦用于 SetLeader/投降流亡) / "country.calc_modifier" pass (§4.2.7 备注) / 州征兵 + **阵营人力上缴** (token 10476, faction+2288 按 tag 记原人力 (不缩放); mdef648 = MODIFIER_FACTION_SUBJECT_CONTRIBUTION_GAIN 只缩放贡献分 ×(1+mdef648), 取条目+104 比率 × 州月征兵增量, 向零截断) / 逐国改善关系月更 / **on_monthly 派发** (§4.2.9) / 玩家专属 tag 管理器引用计数 / **季度舰队重整** sub_140218EB0 (触发月 = 4/8/12 月, 绝对月 %4==0; **玩家国专属门**); 十段细化: ① dip 月更 sub_140D409D0 (dip+804 租借 IC 按 NDiplomacy::MONTHLY_LEASED_IC_DECAY 衰减 + 限时好恶刷新 + 待定外交动作定时容器刷新) ② major 重算 (谓词内无 0.7 补判, 补判归段⑥) ⑥ **无阵营国晋升通道** (均值 = hourly 级 sub_1401F1190 写 gs+2168; 补判门 = 工厂 ≥ 0.7×均值 **且** ≥35 双条件 AND) ⑧ sub_1406CF380 = 返回值弃置无副作用取用器 (疑残留) ⑨ sub_140CD1500 = playthrough 统计月计数器 (+524 递增, 玩家国比较后置 +984 bit2, 单人限定) |
| 2 | 阵营月更 (+1016) | sub_140D92DF0: 门 = `当前绝对月 == abs_month(gs+1192 起始日期)+1 且同年` (gs+1192 = playthrough 起始日期 "PLAYTHROUGH_STATS_STARTING_DATE" 串直证, 非滚动记录月; 阵营 faction goal 「月更」实为**开局后第 2 个自然月一次性重放** — 12 月开局永不触发); 主体 = **仅含玩家阵营**的每条 faction goal 以玩家国为 scope 重放效果 (AI-only 阵营不跑) |
| 3 | 学说月更 (+1024) | sub_140D7F220: 只对玩家国 doctrine status (160B 元素) 跑月步; 无效 tag 断言 doctrine_system.cpp:80 后兜底元素 0; AI 国不经此路径 |
| 4 | 三个 "Short Task" | lambda_1 = **sub_1401C7460** power_balance 玩家侧月更 / lambda_2 = **sub_1401F7B00** SRW 锁下月度 history log (门 = 控制台 `history_logger` [PE 字符串对 "history_logger"+"Toggle history logger", 命令体 sub_140292DE0: 参数 = tag 掩码, "none" = 清空, 0 参 = 全选记录], nlohmann/json 写 **相对 CWD 的 history_dump/** [勘误精化: 原记「logs/history_dump」, 簇内目录创建/写盘均无 "logs/" 前缀拼接], historylogger.cpp:594) / lambda_3 = **sub_1402168D0** GameTelemetry 占领快照 (tbb 逐国, 国数≥2 门直证); 另 5 处帧泵 + Short Task join 形态 (旧表漏行) |

#### 4.2.11 yearly (CGameState 年边界, gs+784 国家数组)

> **AI 域 yearly 除外 (定案)**: AI 模块树有真 yearly 通道 — CAICore 虚槽[9]
> ("CAICore.YearlyUpdate" / "Module.YearlyUpdate", exe 虚表直读; AI monthly =
> 槽[8] sub_1402AB4B0 门 owned_states>0) — 旧「不存在 yearly 订阅者系统」加此
> 除外。其余域 monthly/yearly 负证与 weekly 同法成立 (rhythm zone 全清点,
> production/focus/characters/operations/raids/projects/market 等全无)。

**不存在 yearly 订阅者系统, 也无 on_yearly on_action** (全语料 0 命中
on_yearly/on_anniversary/on_new_year)。年门 (定案): 新绝对年 ≠ 旧绝对年 — 绝对年 =
`(gs+1128 总小时 − 43800000) / 8760` (8760 = 365×24, 每年恒 365 日; 43800000 = 纪元基点),
旧值缓存 = **gs+1144 年分量缓存** (§1.2); 日/周/月/年四粒度边界块为 tick 内同级 sibling。
年边界实际动作 (骨架 §4.2.4 步骤 14):

| 动作 | 内容 |
|---|---|
| sub_14071A940 逐国 | 遍历 cc+656 师列表, 逐师清理师+840 CEquipmentVariantPool 零值条目 (门 = allow_zero u8@师+896==0, sub_14100D9B0) |
| sub_140207890 | PDX SDK TelemetryEvent 遥测批: 上报 country_count / in_game_date / nr_country (owned_states>0) / nr_dynamic_country (动态 tag) |

#### 4.2.12 补给小时更新 (CSupplySystem::UpdateSupply, sub_140ECD400)

挂点: HourlyUpdate 计时域 4 (§4.2.6 序 3) → sub_1401C6D30 (gs+984 scoped_ptr
解引用) → sub_140EC8DB0 (强制第二参 = 1)。12 阶段执行链与 tbb lambda 族 =
§4.21.1a (域分册)。

#### 4.2.13 战斗小时更新 (CCombatManager, sub_140BB8AE0, gs+608)

挂点: HourlyUpdate 相位 12 (§4.2.6, 计时域 6)。CCombatManager 五阶段执行链 =
§4.22.9a; CCombat 行为槽契约 = §4.22.9; 海战步进 = §4.22.10; 边界战 = §4.22.11。

#### 4.2.14 突袭小时更新 (NRaids::CRaidSystem, sub_140E86100, gs+1008)

挂点: HourlyUpdate 计时域 12 (§4.2.6 序 5) → sub_1401C6A30 → sub_140E86100。
管理器两遍结构与预警判定 = §4.27.3 (域分册)。

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

**DoUpdatePasses 内层第一步 = sub_140F18800** (主线程断言 + 禁场 enter → tbb): 日期/小时相位取值 + 天气全局目标值 (50000×qword_143333508/1e5 = 50% 门限) + 步长 qword_1430B1DC8 = 1e10/(目标−当前) (相等时 0xFFFFFFFF 哨兵) + mgr+848..+892 functor 捕获 tbb 全量省 pass。
**天气省状态数组重建分发器 = sub_140F1CB90**: SWeatherPerProvince (384B) 主数组 + 352B 第二数组双轨重建 (经分配器虚槽 vt+8), 内联 CModifier 构造; 三相消费者 = 控制台命令 sub_14027B8E0 / 读档恢复 sub_1401E1580 / 初始化 sub_14022E040。

> 备注: 384B 区域条目 (SWeatherPerProvince) 已定锚字段: +44 类别 / +64 强度计 /
> +304 active 位 / +352 平滑值 / +368 噪声值; 其余字段未入册 (未决)。
> 352B 区域周期条目布局未入册 (未决)。

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
| 1 | 并行逐 SA → 逐池 → 逐翼: 任务指派/换任务 (sub_140F68040) + **CAirWing::HourlyUpdate (sub_140F62750, airwing.cpp:1596)** 十段: 任务 roll (lambda_1 sub_140C49E80: roll sub_140F7A420/7ACC0/796E0, SetMission/不可达清 0) → 0x400 无效任务取消 → 机数缓存重算 → 目标省表填充 (sub_141012F80, AA+航程过滤) → 空投三步 → 部署计时 → 转移推进 sub_140F64B70 → 待除名翼推入 sa+112 → 训练/经验 → combat 统计 |
| 2 | **HourlyUpdateThreadedInternal (sub_140C58660)**: 5 段内部 parallel_for over CAirUpdateCache — 确定性空战/效能解决核心 (cc+1464 修正查表 + 区域战斗数据); 并行 lambda 簇 10 函数 (sub_140C443C0/C44980/C44DD0/C450B0/C45AC0/C466D0/C46EA0/C47420/C476B0/C44C60/C44F40, 体嵌符号串直证; 早期记 lambda_1..4 = sub_140C49E80/C67840/C4A2F0/C4A6F0 + C4AA70 为其子集; lambda_1 tbb 分裂体 = sub_140C46030); 缓存形态 = 160B 网格行距 + byte+154 布尔格 + a1+320 分布表 24B 行距 |
| 3-4 | gs+2536 region→兵力树前置; 逐 SA 待查翼列表 = **每小时翼解散清扫** (无机无人 → 装备退还 cc+3944 生产库存 + ace 回收; 空池删除) |
| 5 | per-state/region 数据并行重建 |
| 6-7 | 逐活跃国 cc+4824 失效项清理; 逐 SA 任务/区域表维护 (ActiveMissions 增删) |
| 8 | 并行逐任务重算 **mission+184 扰断值** (define 因子 × cc+1464 修正 × 有效机数, ×1e5 定点连乘) |
| 9 | 并行逐 SA **disruption 总量重算** (+ 阵营规则/指挥功率门) |
| 10-12 | 交战区域任务完成度/区域计分推进; gs+2536 已完结条目清理; 逐区域 **ProcessGroundMission (sub_140F82110, airmission.cpp:2398)** 地面任务每小时推进 (目标重选/空投位) |

燃料结算位: ProcessAirBasesHourly (sub_140C5EFC0, 步 3-4 之后) tbb 并行逐基地 → 逐国容器 sub_140C57B70 清零重算 cp+216/+224/+232 (容量惩罚/任务/基础燃料, §4.15.9) — 先于序 10 燃料国级结算 (sub_1410F71B0 读到的 cp 值必为本小时新值); 翼 hourly 尾段把待除名翼推入 sa+112 (步 3-4 清扫消费)。

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
| session+72 | CSession 联机状态枚举 (19 值全表) | §4.28.16 |
| session+84 | 游戏已开始标志 | §4.28.16 |
| session+128 | 会话 tick 号 (16 位截断) | §4.28.16 |
| idler+1729 / idler+1732 | 暂停权威位 / Idle 第二暂停门 (与 +1731 toggle pending 并存勿混) | §4.28.14 |
| idler+2396 | 加速脉冲计数 (每 tick 减 1) | §4.28.14 |

#### 4.2.20 世界构建两路步序对照 (新局 zone 49 / 读档 zone 62)

> 新局与读档在前端命令层就分流 (书签应用 sub_1401A5630 vs 存档解析 sub_1401C8A60),
> 于 CStartGameCommand + FE 帧 StartNewGame 汇合; 分流点/入口三通道/就绪旗族见
> §4.28.18, 执行线程见 §3.11.4。本表只对齐两路步序。

| 阶段 | 新局 (sub_1401A5630, zone 49) | 读档 (sub_1401C8A60, zone 62) |
|---|---|---|
| 入口 | CSelectBookmarkCommand::Execute → sub_14067EEE0 (门 gs+2600 ≠ 目标书签) | sub_140DA04F0 v24[85]≠0 → sub_140D9FF80 → sub_1401E2AC0 (gs+2613 置 1, parallel_invoke 双轨 §3.11.4) |
| gs 重建 | sub_1401EA1B0 (ctor sub_1401D0E30 + 默认初始化链) | 同左 (两路共用) |
| HistoryDatabase | 销毁 → 重置 ID (sub_140175130) → 角色批产 (sub_1406B97D0) → 装载 (sub_140A3D640) → 两段日期区间应用 (条目 vt[17], §4.13.7) | 仅销毁 (62.3); **history 不再应用** (已物化进存档) |
| 数据填充 | 历史 effect + boot 模板解析值 (模板字面量) | 存档解析 (sub_142232930) + post-load (sub_1401DA490) |
| 收尾 | 49.5–49.8 (情报知识 / CGraphicalMap ResetGame / stateDef 收尾); gs+2600 = 所选书签 | post-load 全局重挂波; gs+2600 重置默认书签 (sub_1401DBBB0) |
| 汇合 | CStartGameCommand::Execute (FE+1590=1) → StartNewGame (门 FE+1591) → CInGameIdler ctor 开局补算 sub_140DD6A30 (Hourly/Daily/Weekly/Monthly 各一遍) → SetIdler → 首帧 | 同左 |

historylogger.cpp 簇对账增补 (11 函数闭环; 月度史志导出器本体首次全量深读):

**月度史志导出器 = sub_1402B6A00** (2109 行, §409 行 lambda_2 的实体; 6 件 0x1425A1xxx
catch funclet 与主函 catch 块逐句同构配对): 门 = byte_14332F625 ∧ HasGameStarted
(gs+2617); 双 PNG (`prov_<日期>.png` / `sea_<日期>.png`, 日期 = **gs+140** ToString) 写
history_dump/; **JSON 顶层 schema** = {map_file, sea_map_file, map_width/map_height =
地图尺寸宿主单例 qword_143339D28 +64/+68, t = ctx+104, num_days = ctx+88, date =
**gs+1120** 日期串 [与 gs+140 双日期槽, 权威语义未分辨], logs = ctx+136 串数组,
countries}; **per-country schema 约 20 键** = logs / name (字节 <32 替换 '_') / color
(palette B2B1B0) / allies (阵营+656) / enemies (+152) / potential_enemies (+248) /
fully_controlled_states 与 controlled_provinces (判别三态缓存自动机: state+420==1 ∧
sub_1401C4FE0 → fully, 旗数组 0/1/2) / resistance_data (cc+1120 占领州; 子键 = resistance
state+632 / compliance +680 / resistance_target +656 / law / garrison_ratio / eq_ratio
[infantry_equipment token 一次性缓存 qword_14332F718] / manpower_ratio) / factories 八键
(宿主 cc+3944) / armies / navies (任务数组三元组, ship+884 旗) / air_missions /
province_data 与 order_data (ctx+8/+32 槽表每国 96B RH 条目全字段: pos/num_units
[PE .rdata 实证 0x142738508]/num_attacking/num_defending/num_in_combat/dig_in_ratios/
move_data + type/num_days/num_units_at_front/path_data 等) / ai_theaters
(`{"name": 州名, "states": [id]}` 构造器 sub_1402C1080, 键 "states" PE 实证
0x1427202C8)。ctx (idler+2576) 布局 12 项消费点定案 (+1 首日旗 / +88 num_days / +104 t /
+112 tag 掩码 / +136 logs 行数组等); logger 开启后首日自动导出 invariants.json 一次
(**sub_1402B9A30 新定案**: 5 键 = provinces_center_point / state_id_to_provinces /
state_id_to_central_province / max_supply_value = 100 / attrition_supply = 钳位 [0,100],
公式 PE 验算待做); 月度任务挂接链 = .rdata 任务类 vtable 0x142723D50 族 (ctor
sub_1401B7EE0 / 注册 sub_1424D4DD0)。

未决: 每国 logs 组装器 sub_1402BE1D0 内部; 日更采集端 (sub_1402C09B0 驱动器 / OnDailyUpdate
体 / SProvinceData 布局); PNG 编码器; attrition_supply 公式 PE 验算 (核心纪律 8);
invariants 三填充函数; gs+140/gs+1120 双日期槽语义; sub_14029EED0 与书定案驱动器关系。
