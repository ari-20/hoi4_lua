### 4.9 性能分析域 (日期采样器 / zone profiler / 工具入口)

引擎内置三套独立性能设施, 互相不共享状态; 日期采样器的对象布局与
日期边界判定另见 §4.2.5, 本册收运行时机制、内置区间名单与全部启用入口。

#### 4.9.1 设施总览

| 设施 | 核心机制 | 粒度 | 产物 |
|---|---|---|---|
| 日期采样器 | gs+2008 采样器对象 (启用门 a1+8; §4.2.5) | Hour / Day / Week / Month / Year 整刻耗时 | logs/gametimer_<时间戳>.tsv (表头 "Game Date \tTime Unit \tSeconds", 行格式 "%s\t%s\t%f\n") |
| zone profiler | pdx_core/profile.cpp 层次化区间统计 (g_IsProfiling 门, 仅主线程) | 逐 zone (子系统级) 累计耗时 × 命中 | GUI "Profiler" 窗口 Script tab 列表; dump 落 logs/profiler.log |
| 帧率面板 | debug "Profiler" 窗口 Timings tab | 逐刻 / 逐时 / 逐日 / 逐周 / 逐月 + 帧时间 / FPS / 显存 | 纯显示 + Save profile / Save reference 对照 |

#### 4.9.2 zone profiler 运行时 (pdx_core/profile.cpp)

全局量表:

| 符号 | 语义 |
|---|---|
| byte_1435E3BF2 | g_IsProfiling 总门 (1 = 采集中) |
| dword_1435E3BF4 | 主线程 id (IsMainThread 断言) |
| dword_1430C7218 | zone 层级上限 (推入层级 > 该值则不记录) |
| qword_1435E3C00 | zone 条目数组基址 |
| dword_1435E3C08 | 数组容量 (满时 ×1.5 扩容, 下限 128) |
| dword_1435E3C0C | 数组计数 |
| TLS +2104 | 当前 zone 指针槽 (线程本地推入链) |

zone 条目布局 (56 字节/条, 无独立 RTTI 类（负定案）; 数组元素按偏移升序):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | char* | zone 名 |
| +8 | uint32 | 累计命中数 (GUI 计数列读此) |
| +16 | uint32 | 活动推入深度 (每次推入递增) |
| +24 | uint64 | 累计耗时 (QPC ticks; 显示毫秒 = 值/10000) |
| +32 | 容器对象指针 | 子 zone 表 (推入构造 sub_14011DF40; 结构待裁) |
| +44 | uint32 | 子 zone 计数 (高置信) |

生命周期 (定案):

| 环节 | 函数 | 要点 |
|---|---|---|
| 启动 | sub_1424D3730 | 断言主线程且未在采样; 置 g_IsProfiling; 建表; 推 "non_assigned" 根桶 |
| 推入 (薄形) | sub_1424CF260 | RAII 构造; 记起点击入 TLS 链与条目 |
| 推入 (层级形) | sub_1424CF380 | 第 4 参 = zone 层级, `层级 <= dword_1430C7218` 才记录; 同表同链 |
| 按名查/建 | sub_1424D0310 / sub_1424D3360 | 同串归并同条目; 新条目追加表尾 |
| 分段重启 | sub_1401DF400 开头 | hourly 模式 (模式值 2) 下每次 HourlyUpdate 先重启采样 = 逐小时分段快照 |

> 备注: 两形推入共用同一条目表与 TLS 链, 层级形仅多一道层级过滤。
> 备注: profiler 只记录主线程 (IsMainThread 断言), 并行 worker 与渲染线程不入表。

#### 4.9.3 内置 zone 名单

薄形 (sub_1424CF260 字面调用点, 定案):

| zone 名 | 挂点 |
|---|---|
| non_assigned | 启动根桶 |
| ai_update | AI 总入口 |
| gamestate.hourly / gamestate.daily / gamestate.weekly / gamestate.monthly / gamestate.yearly | 主调度外层 (§4.2.6–§4.2.11) |
| state.daily_parallel / country.daily_parallel / country.post_daily_parallel | daily 并行三段 (§4.2.7) |
| interface.tick | 界面帧逻辑 |

层级形 (sub_1424CF380 字面调用点, 定案; 全名单):

| zone 名 | 域 |
|---|---|
| country.daily / country.calc_modifier / country.delayed_events | 国家逐日 |
| states.daily / daily.occupation_update / daily.strategic_region_update | 州/占领/战略区域逐日 |
| production.daily_serial / resources.daily / deployment.daily | 生产/资源/部署 |
| logistics.daily / logistics.postdailythreaded | 后勤 |
| nationalfocus.daily / focusweight.daily | 国策 |
| tech.daily / tech_share.daily / tech_strategies | 科技 |
| diplomacy.daily / politics.daily / faction_goals | 外交/政治/阵营 |
| leaders.daily / update_leader_strats / scripted_strategies | 领导人/策略 |
| airmanager.daily / navymanager.daily / theatre.daily_serial / theatremanager.endbundle / ai_theatres.daily | 空/海军/战区 |
| decision.hourly / player_decision_check / custom_decision_icon | 决议 |
| adjacency.tick / adjacency_check | 邻接 |
| flag_manager.daily / division_names.update | 旗/师名 |
| scripted_gui.window / scripted_gui_ai | 脚本 GUI |
| gui_click | 界面点击 |
| hourly_parallel | hourly 并行段 |
| preHourlyUpdate / HourlyCountryComponentUpdate / hourlyUpdateUnits / postHourlyUpdate | hourly 五分段 (gamestate.hourly 子段; 采样实测: preHourlyUpdate 内含 DoTradeRoutesUpdate 资源输送路线重算与 CSupplySystem::UpdateSupply 供应节点并算两大头, hourlyUpdateUnits = 每国单位聚合, postHourlyUpdate 段尾) |

#### 4.9.4 工具入口与产物

| 入口 | 形态 | 语义/产物 |
|---|---|---|
| 控制台 `profile` | 命令 (handler sub_140277780; 登记帮助 "profile options", 参数提示 "<on> <off> <print> <clear>") | 函数内逐字比对可识别修饰词 (定案): "hourly" = 逐小时分段模式, 缺省 = total sums; "merge" / "level" / "file" 已确认参与比对, 语义待裁; 非法组合回显 "invalid args"; dump 落 logs/profiler.log |
| 控制台 `gamestate_timer` (别名 `gstimer`) | 命令 (handler sub_14025D910; 提示 "on / off"; 帮助 "Enable / Disable recording of how long an hour / day / week etc takes to process.") | 开关日期采样器 (§4.2.5); on 建文件并回显 "Game state timer enabled." |
| 启动参数 `-gamestatetimer` | launcher 直通旗 (启动参数解析器置 byte_14332EC5E) | gamestate 就绪后自动启用日期采样器 (高置信) |
| debug GUI "Profiler" 窗口 | -debug 窗口清单成员 (与 pid_controller_editor / event_graph 等同列) | Timings / Script 两 tab, 见下表 |

GUI 两 tab 内容 (定案):

| tab | 展示/操作 |
|---|---|
| Timings | "Last tick" / "Hourly" / "Daily" / "Weekly" / "Monthly" 耗时与均值; 帧时间 (含不含 present 两口径)、FPS、ticks per second、显存用量、CPU 名 / 硬件线程数 / 多线程渲染开关; 采集控制 Enable/Disable Collection + Clear Data; "Save profile" / "Save reference" 与 "Delta" 对照列 (起日不匹配回显警告); 帧平滑开启时提示影响精度 |
| Script | zone profiler Start / Stop; 停止后逐 zone 行格式 "%5llims %5ix %s" (毫秒 / 命中 / 名); 保存回显 "Profiling data saved as %s" |

> 备注: logs/profiler.log dump 完成回显 "Profiling data dumped. It can be opened by the profile viewer in the game folder."
> 备注: zone 统计粒度 = 子系统级, 不含逐函数细分; 逐函数热点需采样式 profiler (桥内自建或外部 ETW)。
