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
| TLS +2104 | 每线程 context 指针槽 (context 24B: +0 = 当前节点 / +8 = 线程 profiler 对象 / +16 = 节点池) |
| qword_1435E3C58 | **节点池空闲表基址** (元素 = 24B 节点池对象指针; 线程退出时 context 回收入表, sub_1424CFE50) |
| dword_1435E3C60 / dword_1435E3C64 | 空闲表容量 / 计数 |
| qword_1435E3C68 | 空闲表分配器 (虚槽[1] allocate / 虚槽[2] deallocate) |
| qword_1435E3C40 | 主线程静态节点池 (主线程节点不经空闲表回收) |
| qword_1435E3C28 / dword_1435E3C30 / dword_1435E3C34 / qword_1435E3C38 | 每线程 profiler 对象数组 (48B/对象, +40 = 线程 id) / 容量 / 计数 / 分配器 |
| qword_1435E3CA8 | 当前 zone 条目指针 (条目栈顶; 推入存 RAII+8, 薄形弹出恢复) |
| dword_1430C721C | **merge 模式旗** (0 = 按名归并 + 导出降序 by 节点+32 累计时长; 非 0 = 逐次新建节点 + 导出升序 by 节点+24 起始 ticks + 不建条目; 定案) |
| stru_1435E3C18 | SRWLock (推入/弹出锁) |

zone 条目布局 (56 字节/条, 无独立 RTTI 类（负定案）; 数组元素按偏移升序):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | char* | zone 名 |
| +8 | uint32 | 累计命中数 (GUI 计数列读此) |
| +16 | uint32 | 导出期按 qword 读: 非 0 时刷新为 Xtime_get_ticks() (sub_1424D20C0); 写者未见 (待裁) |
| +24 | uint64 | 累计耗时 (QPC ticks; 显示毫秒 = 值/10000) |
| +32 | 匿名结构 (NNB 形状) 向量 24B | 子 zone 表 (引擎向量 {begin@+32, 容量@+40, 计数@+44, 分配器@+48}; 元素 = 72B 堆节点指针; push = sub_1401205A0; 节点布局见下表) |
| +44 | uint32 | 子 zone 计数 (即 +32 容器 count 槽) |

72B 堆采样节点 (malloc 0x48, 无独立 RTTI 类; 池化回收):

| 偏移 | 类型 | 语义 | 写者 / 读者 |
|---|---|---|---|
| +0 | 对象指针 | 所属线程 profiler 对象 (48B, 其 +40 = 线程 id); 归并键 1 | 构造 sub_1424D03C0 写 / 归并查 sub_1424D0310 比对 |
| +8 | char* | zone 名串指针; 归并键 2 | 构造写 / 归并查比对 / 导出期作 zone 名 |
| +16 | uint32 | **进入计数** (两形推入各 ++) | sub_1424CF260 / sub_1424CF380 |
| +24 | uint64 | 起始 QPC ticks | 两形推入写 Xtime_get_ticks / 弹出读作出账 |
| +32 | uint64 | **累计 QPC 时长** (导出排序键) | 两形弹出各 `+= now − start` (sub_1424CF9B0 / sub_1424CFA60) |
| +40 | 节点指针 | 父节点 | 构造写 / 弹出恢复 current |
| +48 | 节点指针 | 首子节点 (新子节点前插到此) | 构造写 / 导出递归入口 sub_1424D35D0 |
| +56 | 节点指针 | 下一兄弟 (兄弟链) | 构造写 / **导出排序重排此链** |
| +64 | 对象指针 | 所属节点池 (24B 引擎向量, 回收用) | 构造写 |

生命周期 (定案):

| 环节 | 函数 | 要点 |
|---|---|---|
| 启动 | sub_1424D3730 | 断言主线程且未在采样; 置 g_IsProfiling; 建表; 推 "non_assigned" 根桶 |
| 推入 (薄形) | sub_1424CF260 | RAII 构造; 记起点击入 TLS 链与条目 |
| 推入 (层级形) | sub_1424CF380 | 第 4 参 = zone 层级, `层级 <= dword_1430C7218` 才记录; 同表同链 |
| 弹出 (薄形) | sub_1424CF9B0 | RAII 析构 (推入 sub_1424CF260 的对偶): 节点+32 += now − start; 恢复 current = 父节点(+40); merge 模式另累计条目+24 / ++条目+8 / 恢复条目栈 qword_1435E3CA8 |
| 弹出 (层级形) | sub_1424CFA60 | RAII 析构 (推入 sub_1424CF380 的对偶): 节点+32 += now − start; 恢复 current = 父节点 |
| 线程退出回收 | sub_1424CFE50 | **非 RAII 弹出** — 每线程 context (TLS+2104) 析构期经 _tlregdtor 注册调用: context+16 节点池归还空闲表 qword_1435E3C58; 清 context+0/+16 |
| 按名查/建 | sub_1424D0310 / sub_1424D3360 | 同串归并同条目; 新条目追加表尾 |
| 分段重启 | sub_1401DF400 开头 | hourly 模式 (模式值 2) 下每次 HourlyUpdate 先重启采样 = 逐小时分段快照 |
| 停止导出 | sub_1424D39D0 → sub_1424D20C0 → sub_1424D35D0 | JSON 落盘 (字段 type / start / duration / duration_in_ms / entry); 递归后序排序各节点子链: merge 旗 dword_1430C721C = 0 → sub_1424CEAB0 (std::sort **降序** by 节点+32 累计时长), 非 0 → sub_1424CEEB0 (**升序** by 节点+24 起始 ticks); 排序后重写节点+56 兄弟链 |

> 备注: 两形推入共用同一条目表与 TLS 链, 层级形仅多一道层级过滤。
> 备注: 薄形推入有 IsMainThread 断言; **层级形推入无线程断言** (仅 g_IsProfiling ∧ 层级 <= dword_1430C7218), 可由 worker 线程经 TLS context + 池空闲表独立建树 (与 §4.2.7 daily 并行段层级 zone 名单相符)。

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
| preHourlyUpdate / hourly_parallel / HourlyCountryComponentUpdate / hourlyUpdateUnits / postHourlyUpdate | hourly 五分段 (gamestate.hourly 子段)。preHourlyUpdate 内含 DoTradeRoutesUpdate 资源输送路线重算与 CSupplySystem::UpdateSupply 供应节点并算两大头; HourlyCountryComponentUpdate 六棒 = 战区清理→war_relation 表失效→战区管理器国家级刷新→生产线维护→首都失效检查/迁都→国家杂项簇 (delayed_events/calc_modifier/decision.hourly + 错峰海岸防护), 棒间插 observer 槽刷新; hourlyUpdateUnits = 占领统计 bundle ++→逐国单位聚合→bundle --→tbb 部队并行→串行逐 army 错峰重建; postHourly = CalcMod 批量重算 + 错峰 on_action 派发 + 72B 桶到期 + 缓存重算 |

#### 4.9.4 工具入口与产物

| 入口 | 形态 | 语义/产物 |
|---|---|---|
| 控制台 `profile` | 命令 (handler sub_140277780; 登记帮助 "profile options", 参数提示 "<on> <off> <print> <clear>") | 函数内逐字比对可识别修饰词 (定案): "hourly" = 逐小时分段模式, 缺省 = total sums; "merge" = merge 旗 dword_1430C721C (0 = 按名归并 + 导出降序 by 累计时长, 非 0 = 逐次新建节点 + 升序 by 起始 ticks + 不建条目; 定案); "level" / "file" 已确认参与比对, 语义待裁; 非法组合回显 "invalid args"; dump 落 logs/profiler.log |
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

#### 4.9.5 性能分析域函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x1412E19D0 | 无名 sub_（调用图定位） 调用图传播: 3/4 锚点投 §4.9 |
| 0x140666460 | （无名） 调用图传播: 2 锚点投 §4.9（100%） |
| 0x141009B50 | （无名） 调用图传播: 2 锚点投 §4.9（100%） |
| 0x141009AE0 | （无名） 调用图传播: 3 锚点投 §4.9（100%） |
| 0x1411803D0 | （无名） 调用图传播: 3 锚点投 §4.9（100%） |
| 0x141009BC0 | （无名） 调用图传播: 2 锚点投 §4.9（100%） |
