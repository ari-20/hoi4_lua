# hoi4_bridge 架构

DLL 自身的架构说明：各模块怎么拼在一起、为什么是这个形状。

**本文不覆盖**（各自有权威文档，本文不重复）：

| 内容 | 去哪看 |
|---|---|
| 构建、mod 注册、启动参数、控制面用法、环境变量 | `README.md` |
| 引擎类布局 / 偏移 / 槽契约 / writer 语义 | `book/hoi4_runtime_classes.md` |

本文对 DLL 内部机制的陈述以源码为准；清单章节（§7）是从注册表与路由表**生成**的，源码改了清单就该跟着改。

---

## 1. 运行形态

### 1.1 交付单元

`hoi4_bridge.dll` 注入 hoi4.exe（1.19.3.0 rev c01a3d50，ImageBase 0x140000000），在游戏进程内宿主一个 Lua 5.4.7 VM，并开一个 loopback HTTP 控制面。

它是**单文件交付**：所有版本相关地址编译进 DLL（`hoi4_offsets.h` 的 `kOffValues` 表），没有需要随行分发的伴生文件。

### 1.2 启动序列

```
launcher (CREATE_SUSPENDED + QueueUserAPC(LoadLibraryW))
  └─ DllMain(PROCESS_ATTACH)            ← hoi4_detour.cpp
       ├─ DisableThreadLibraryCalls
       ├─ L("=== hoi4_bridge loaded ===")   ← 只写内存环（loader lock 下禁文件 IO）
       ├─ install_hooks()
       │    ├─ g_base = GetModuleHandleW(NULL)
       │    ├─ offsets_load()  ← PE 签名校验，不过即拒绝
       │    ├─ install_abs_jmp(FindCommandByName / EffectRouter / TriggerRouter)
       │    ├─ build_my_tvt() / build_my_vtable()
       │    └─ install_v4_vtable_hook()   ← 帧心跳（槽交换，非体重定向）
       └─ CreateThread(lua_init_thread)   ← Lua 初始化不在 loader lock 里做
            ├─ 解析日志路径、开真实日志文件
            ├─ luaL_openlibs + 硬化 stdlib 面
            ├─ 注册 hoi4.* 全表 + 元表
            ├─ 首轮加载各启用 mod 的 lua/*.lua（平铺，不递归）
            └─ 置 g_initialized   ← 最后发布
```

`g_initialized` 在初始化**全部完成之后**才置位：帧顶判据是 `g_L && g_initialized`，只看 `g_L != NULL` 会进到一个半初始化的 VM。

### 1.3 失败即退出（fail-closed）

三道闸门任一不过，`DllMain` 返回 `FALSE`，DLL 不激活，游戏原样继续跑：

1. **PE 签名**：`TimeDateStamp` / `SizeOfImage` / `CheckSum` 三者与表内期望值全等，否则 `[off] game image signature mismatch`。
2. **表项非零**：`kOffValues` 任一项为 0 即拒绝（防「表没填完就上线」）。
3. **槽位内容校验**：装帧钩子前现读 `vt[slot]`，必须等于期望的引擎函数指针，不等就 `slot4 mismatch ... NOT hooking`（版本漂移下绝不盲改）。

同样的纪律贯穿运行时：内存写有写域门、引擎调用有调用域门（§3.2），都是**拒绝**而不是「尽力而为」。

---

## 2. 线程模型

### 2.1 唯一安全点：帧顶主线程

引擎不是线程安全的。整个 DLL 只有一条规则：**碰游戏内存的代码只在引擎主线程的帧顶执行**。

帧钩子挂在 `CInGameIdler` 虚表 slot 4（`FUN_140DBF240`，RVA 0xDBF240）——引擎每渲染帧在**固定主线程**上调用它，且它是 effect 派发的**父层**，结构上处于任何 effect 回调之外。主菜单与加载画面不经过它，相位判据因此是免费的。

首次进入时记录主线程 tid（`hook_note_main_thread`），钩子设施据此区分「可内联跑 Lua」与「必须 fail-open」。

### 2.2 锁

`g_luaLock`（SRWLOCK）+ `g_luaOwner`(tid) + `g_luaDepth` 的递归簿记：

- 帧顶用 `TryAcquireSRWLockExclusive` —— **绝不阻塞帧线程**，抢不到就丢这一帧（`g_tickDropped++`），丢帧无害。
- effect/trigger 回调路径与帧顶同一套簿记：同一线程可重入（深度计数），跨线程直接拒绝。
- 另设 `g_tickOwnerTid` 做帧内再入的偏执保护。

worker 侧没有第二条进入路径——它们只能入队。

### 2.3 帧顶派发顺序

`tick_dispatch_lua()`（`hoi4_frame.cpp`）在持锁后按固定顺序执行：

| 序 | 调用 | 作用 |
|---|---|---|
| 1 | `session_dispatch_locked` | 消费会话事件。会话切换自身会触发全量重载，故必须最先 |
| 2 | `maybe_reload_locked` | 脚本 mtime 检测，**1 Hz 节流** |
| 3 | `reload_execute_locked` | 执行挂起的全量重载（帧顶浅栈执行） |
| 4 | `timer_dispatch_locked` | 到期定时器回调 |
| 5 | `async_dispatch_locked` | 把 worker 完成的任务交付给主状态回调 |
| 6 | `hook_dispatch_observe` | 交付 observe 模式钩子事件（任意线程入队，只能在此交给 Lua） |
| 7 | `http_poll_main(4)` | 消费 `/console` `/lua` `/game/pause`，**每帧上限 4 条** |

顺序有语义：会话事件必须早于重载（切换本身要重载）；重载必须在浅栈上（避免嵌套回调路径耗尽栈）；HTTP 放最后且限量，防止重 chunk 堵帧——单 chunk 目标是 <1s，超了心跳会误报、窗口会假死。

### 2.4 worker 线程族

| 线程 | 数量 | 职责 | 碰引擎？ |
|---|---|---|---|
| 引擎主线程 | 1 | 帧顶派发；唯一跑 Lua、唯一碰引擎 | 是 |
| httplib server workers | cpp-httplib 内部池 | 收请求 → 入队 → 等应答 | 否（只入队） |
| async 池 | `ASYNC_WORKERS` | 跑 mod 提交的 Lua 任务（每任务独立 `lua_State`） | 否（worker 状态是裸 `lua_State`） |
| 采样线程 | 1 | 周期挂起主线程取 RIP / 走栈回溯 | 只读（挂起窗口零锁零分配） |
| http_client worker | 每请求 1 | 出站 HTTP(S) 交换 | 否 |
| Lua 初始化线程 | 1 | `lua_init_thread`，启动期一次 | 启动期 |

### 2.5 回调再入

effect/trigger 回调在引擎线程内、帧内、持锁状态下被调起，因此可以在回调里直接读内存、注册新函数、触发其它 effect。这正是「Lua 只在主线程跑」这条规则能成立的原因：回调天然已经在安全点上。

反向约束也要记住：**非主线程调起的钩子回调不能跑 Lua**。sync 模式钩子在非主线程被调用时 fail-open——转发原函数、不跑 Lua，计数落 `dropped_off_thread`，用 `hook_status` 查。

---

## 3. 引擎交互机制

### 3.1 机制总表

| 机制 | 实现位置 | 门禁 | 用于 |
|---|---|---|---|
| 内存读 | `hoi4_primitives.cpp` | 无（只读） | 一切取数 |
| 内存写 | `hoi4_primitives.cpp` | 写域门 + 写后回读校验 | 改状态、改载荷 |
| 虚表槽钩子 | `hoi4_hook.cpp` | 安装门（6 条，§3.3） | 拦/改/替换虚方法 |
| 函数体重定向 | `hoi4_detour.cpp` + `hoi4_lde.h` + `hoi4_pdata.h` | LDE 全指令窃取 + 拒绝相对流 + `.pdata` 函数起点门 + 悬停验证 | 拦非虚函数（路由器、mod 指定目标） |
| effect/trigger 路由 | `hoi4_vtable.cpp` | 名快照 + 工厂实例 | mod 自定义 effect/trigger |
| 控制台桥 | `hoi4_console.cpp` | 名查找 → 表项现读 | 调原生命令、注册伪命令 |
| 会话检测 | `hoi4_session.cpp` | DR 硬件执行断点 | 会话生命周期事件 |
| 引擎调用 | `hoi4_call.cpp` | 调用域门 + 调用域前置检查 | 主动驱动引擎函数 |
| 采样分析 | `hoi4_sampler.cpp` | 主线程挂起（零锁） | 性能取证 |
| 出站网络 | `hoi4_http_client.cpp` | worker 线程 + 硬 deadline | 外部服务 |
| defines 扫描 | `hoi4_defines*.cpp` | 映像扫描 | 静态数值 |

### 3.2 内存读写与两道门

`hoi4_memgate.cpp` 是承重墙，两道理**只收不放**：

**写门** `memgate_write_ok(addr,len)`——`[addr,addr+len)` 每一页必须：

- `MEM_COMMIT` 且 `PAGE_READWRITE` / `PAGE_WRITECOPY`（**可执行页一律拒写**）；
- `GetModuleHandleExW(FROM_ADDRESS)` 解析出的宿主模块必须**就是 hoi4.exe**（桥自身 `.data`、kernel32 数据全拒）；
- 不落在当前线程 TEB 区、不落在当前线程栈区。

配套的每线程单区域缓存：导出循环对同一缓冲连写数千次，只在跨区域时跑 `VirtualQuery`。

**调用门** `memgate_exec_ok(addr)`——目标必须落在 hoi4.exe 映像的**可执行节**内。启动时从 PE 头解析节表建区间（上限 64 节），线性扫描。效果：`kernel32!VirtualAlloc/VirtualProtect/LoadLibraryA`、新分配的 RWX 页、桥内部地址全部从 `call_u64/call_void` 不可达——因此**只读页没有可达的解锁路径**，永久只读。

桥内部那些**内存派生**的函数指针（`load_save` 的 `app->vt[+880]`、`game_pause` 的 `mgr->vt[+656]`）在调用前过同一道门，伪造堆 vtable 无法再驾驶未受检的桥调用点。过门失败时 `pause` 落直写兜底，`load_save` 直接报 failed。

写原语全部带**写后回读校验**：回读不符返 `false` 并记 `[mem] write_... read-back mismatch`，不再无条件报 true。

### 3.3 虚表槽钩子（Tier 1）

`hoi4_hook.cpp` 提供 mod 面向的能力：**替换 / 包装 / 观察一个既有引擎虚方法**。做法是把 `vt[slot]` 这一个数据 qword 换成 `hk_thunk_N`，**不碰任何代码字节**。

```
vt[slot] (引擎 .rdata qword) -> hk_thunk_N -> hk_dispatch(N, ...)
                                                    |
                                      链式回调，末环调真正的原实现
```

四种能力：**观察**（只看不改，事件带 `ctx.ret`）、**改参数**（改完调 `ctx.call_orig()`）、**改返回值**、**替换**（不调 `call_orig`）。同一 `(vt,slot)` 上可挂多条，按注册序成链。

安装门（任一不过即拒绝并记 audit）：

1. `vt` 与 `slot` 在合理范围（槽号上限 512，链数上限 32——两者是不同维度）；
2. 槽内当前值必须是**引擎代码**（或本设施自己的 thunk，用于同槽再挂）；
3. 槽内不得是 `_purecall`（基类虚表填充符）——钩基类槽拦不到任何东西且不报错；
4. 槽内不得是 `_guard_check_icall_nop`（CFG 空桩）；
5. id 唯一、链未满、条目未满；
6. 目标地址过调用域门。

**粒度陷阱**（本设计存在的意义就是让它可见）：槽钩子是**逐类**的。CEffect 有 600+ 派生类各自覆写 `[13]`，钩基类虚表一个都拦不到。要拦全族请钩共享分派器（effect/trigger 路由器已由 DLL 钩好）。

**为什么不做函数体重定向**：框架已经付过这个学费。第一次 idler 钩子用内联 abs-jmp 改函数体，**首帧即崩**，dump 定案根因是被窃序言含 `mov rax,rsp`，而函数体后面用 `lea rbp,[rax-68h]` + 两次 `movaps` 经 rax 寻址；蹦床的跳回指令把 rax 覆盖成跳回地址，于是 `rbp = (.text 地址) - 0x68`，movaps 写飞。教训：**abs-jmp 蹦床会踩 rax**，只有被窃字节的输出在恢复点已死时才安全。槽交换只动一个数据 qword，函数体逐字节不变，**根本不存在这个失效模式**。

### 3.4 函数体重定向（Tier 2）

`hoi4_detour.cpp` 是 Tier 2 引擎，用于**非虚**目标。两处使用者：

- **框架自身 3 个目标**（DllMain 期安装，永不卸载）：`FindCommandByName`、`EffectRouter`、`TriggerRouter`；
- **mod 侧 `hoi4.detour`**（仅进程首次脚本加载期可安装）。

流程：

1. **窃取**：用 LDE（`hoi4_lde.h`，纯解码器，可单测）从目标开头窃取**整条指令**直到 ≥12 字节。遇到不认识的 opcode、**相对控制流**、或 **RIP 相对操作数**一律**硬拒绝**——窃来的字节要逐字节拷到别处的 stub，RIP 相对操作数会改按 stub 地址解析，而本设施不实现重定位。
2. **stub**：`VirtualAlloc` 一段空间，拷入被窃字节，尾部接跳回，写完翻 **RX**（W^X，因为 detour 无卸载、蹦床永不修改）。
3. **出站补丁**：目标处写 `movabs rax; jmp rax`（12 字节），余下补 NOP 到指令边界。

#### 3.4.1 mod 侧目标资格门（`hoi4.detour`）

安装前逐条校验，任一不过即拒绝，**未产生任何字节改动**：

| 门 | 判据 |
|---|---|
| 首载期 | 仅在进程首次脚本加载期（`in_first_script_load`）。热重载与会话切换也会重跑脚本，但那时游戏满载多线程，不是改代码字节的窗口 |
| 镜像内 | 目标落在 hoi4.exe 的可执行节（`memgate_exec_ok`） |
| 函数起点 | `.pdata` RUN 表二分查得 `begin == rva`——改指令流中段是灾难 |
| 窗口在函数内 | `rva + N <= EndAddress`，否则吃进下一个函数的序言 |
| 序言可窃 | LDE 全指令窃取成功，无相对控制流、无 RIP 相对操作数 |
| 不在已补丁窗口 | 与框架自身 3 个目标及既有 Tier 2 目标的字节窗口不相交 |

`.pdata` 表（138286 项函数边界）由 `hoi4_pdata.cpp` 提供，采样器与 detour 门共用。

**为什么第 6 道门不能省**：框架自己的补丁字节 `48 B8 <imm64> FF E0` 是**可被 LDE 解码的**（`movabs` + `jmp rax`，既非相对控制流也无 RIP 相对），所以第 5 道门拦不住它，只能靠窗口重叠检查显式拒绝。

#### 3.4.2 安装期并发：悬停-验证-提交

改写 12 字节**不可能原子**（这是与 Tier 1 的本质差别：Tier 1 写的是一个对齐 qword，x64 上原子）。因此 `detour_patch_entry` 采用：

```
枚举本进程线程（Toolhelp32）
  → 逐线程 OpenThread（全部分配在悬停之前完成）
  → SuspendThread 全部（自己除外）
  → 逐线程 GetThreadContext，检查 RIP ∉ [target, target+N)
      命中 → 恢复全部线程并拒绝
  → VirtualProtect → memcpy 补丁 → 还原保护 → FlushInstructionCache
  → ResumeThread 全部
```

**悬停窗口内零分配、零用户态锁**（只调 `SuspendThread`/`GetThreadContext`/`VirtualProtect`/`memcpy`/`ResumeThread`，全是内核路径或纯内存写）——这正是把分配前移的原因，否则会与持有进程堆锁的线程互锁。实测 `threads_verified` 为 4（首载期）到 36（运行期）。

**无重试**：首载期本就没有高频调用，命中即拒绝并提示重启。

#### 3.4.3 没有卸载（设计取舍）

Tier 1 卸载 = 写回一个 qword，原子安全。Tier 2 卸载 = 回写 N 字节，**与安装同一个并发问题**；更糟的是若有线程停在补丁中段，回写后它会从指令中部继续解释原指令流。因此**不提供 `undetour`**：

| 项 | 决定 |
|---|---|
| `hoi4.undetour` | 不提供（`nil`） |
| 代码补丁生命周期 | 进程级，永不回写 |
| 代价 | 每次调用多一跳 + 重放被窃序言（纳秒级）；新增目标需重启 |

**热重载不受影响**：回调按 id 每次调用现解析，所以改回调体 → mtime → 重载 → 重绑 → 立即生效。只有**换目标**才需要重启。

#### 3.4.4 递归与重入

detour 拦的是**地址**，所以目标自递归（或经 `call_orig` 再入）会再次进 thunk。每线程 per-slot 深度计数上限 `HK_MAX_DEPTH`(8)，超限 **fail-open**（转发蹦床、不跑 Lua）并计数 `depth_capped`。

**跳回的编码选择**（这里翻过案）：

```
FF 25 00 00 00 00     jmp qword ptr [rip+0]
<8 字节绝对目标>
```

- 为什么不用 `movabs rax,imm64; jmp rax`：执行跳回时被窃指令**已经跑完**，它们的寄存器输出在恢复点是活的。旧写法踩 rax，正是杀死第一版 idler 钩子的那个根因。
- 为什么不用 `E9 rel32`：stub 是 `VirtualAlloc` 出来的，可能离映像远超 ±2GB，`E9` 会静默截断。

**出站补丁保留 abs-jmp 是刻意的**：它在函数入口执行，早于任何被窃指令，此时 rax 是调用方易失的暂存，踩它可证明无害；保留它还让窃取门槛停在 12 字节（换成无寄存器的出站形式需要 14 字节，会改变既有目标实际窃到哪些指令）。

### 3.5 路由注册表

effect/trigger 的路由是 DLL 的核心 mod 能力：mod 文本里写 `m4_debug_hello = yes` → 路由器钩子 → 名快照命中 → 引擎工厂造实例 → 走引擎原解析路径 → 绑定到 Lua 函数 → 推入 effect 列表。执行时引擎对实例调一个虚表槽，被替换的槽 thunk 看到绑定就调 Lua。

要点：

- mod 函数是 `local` + 注册进 registry，**不在 `_G`**；运行期直调走 `hoi4.get_effect/get_trigger(名)`。
- registry **同名覆盖 = 热更新**；这样推上去的闭包只活在当前会话，定稿要落回 `.lua` 文件。
- 名快照有容量上限，超出部分**不可路由**（会记 `[registry] name snapshot hit the ... cap`）。
- 绑定的壳与 bind 表跨会话保留并重盖世代（§3.7）。

已证伪的做法（不要再试）：实例上的**虚表指针交换**——即便内容完全一致、RTTI COL 保留也崩，引擎按虚表身份做绑定。

### 3.6 控制台桥

`hoi4_console.cpp` 让 Lua 调原生控制台命令。激活用**双通道**：引擎全局槽主动读 + 懒构造兜底，不依赖引擎首次 `FindCommandByName`。

- `hoi4.console("cmd a b")`：命令行切词**只认空格**，引号是普通字节，无分组/无剥离/无转义。含空格的参数永远传不进去。
- `hoi4.console_argv(cmd, a1, a2, ...)`：按参数边界直调，逐参数不限长、不限个数。**要传含空格参数只有这条路。**
- 命令表可枚举：管理器 → `+0` 条目数组基址 / `+12` 计数，条目跨距 456，名在 `+8`。
- 伪命令 `lua <chunk>` 是手工拼的表项（非引擎注册），与 `/lua` 同执行器。
- **命令回显无长度上限**（`help` 约 10KB），旧的固定 8KB 缓冲已除。

### 3.7 会话生命周期

引擎事实：gs 单例槽在 1.19.3 **恰好两个写者**——ctor 路径 `mov [slot], rax`、dtor 路径 `mov [slot], 0`。检测方式是这两条指令上的 **DR 硬件执行断点**，不补丁代码、无窃取风险、只在主线程。

关键语义（踩过的坑都在这）：

- 这两个写只在进程**首次**会话创建时触发。菜单往返与游戏内读档**不重写该槽**，因此不产生 ctor/dtor 事件。
- 游戏内读档在引擎层**不是**会话切换：gs 不销毁，路由 effect 不重解析，壳与 bind 存活。读档期事件在首帧合并为一次 end+start 派发。
- 为覆盖「就地读档」这个盲区，额外在引擎自己的读档入口（`OFF_LOAD_ENTRY`）挂 DR 事件：就地读档不销毁 gs（无 ctor/dtor 写），但从 mod 侧看仍是完整切换（新世界 + 旧脚本环境），所以它同样置 END+START 走同一套清理。
- 读档会清掉 `HasGameStarted` 门（gs+2617）且不重跑会话启动函数 → 每日/每周/每月派发全部短路。故读档后**幂等重开**该门（对正常启动无害）。
- 脚本侧：会话切换调 `force_reload_locked()` 全量 re-dofile；bind 表**保留** + 重盖世代 + `obj+0x20` token 校验（旧世代 GC 在同指针切换时清光活绑定 = 路由 effect 全灭，已修）；vtable 钩子是进程级的，`hook_session_regen()` 只刷新簿记，**补丁保留**。
- launcher `-start_save=` 载入后自动强制 reload 全部脚本；**导出不自动执行**。

### 3.8 引擎调用原语

`call_u64` / `call_void`：0~4 参，带 SEH 守卫，目标过调用域门。每个调用前还有前置检查：当前线程 == 持 `g_luaLock` 的 Lua 回调线程、gamestate 单例存活、引擎自己的 forbid 门 `*(u32*)(TLSSlot[TlsIndex]+16) == 0` 放行。

注意引擎的 `args` 容器是自定义布局（**计数在 第 12 字节处 不在 第 8 字节**，也不是 `std::vector`），别按 `std::vector` 布局伪造参数容器——会被读成 begin 指针高位当计数，走数千条垃圾串。

### 3.9 采样器

`hoi4_sampler.cpp`：进程内采样式分析器。专用线程周期挂起主线程取 RIP；`profile_start(1, true)` 开栈模式，经 ntdll 的 `RtlLookupFunctionEntry` + `RtlVirtualUnwind` 走完整调用栈。函数归属靠引擎自身 `.pdata`（启动时解析约 138k 个函数起点表），**不需要符号文件**。

- 挂起窗口**零锁零分配**，主线程持堆锁也不死锁。
- 连续 64 次捕获失败**自动停机**，不留僵尸采样器。
- leaf 直方图经 `profile_top(n)` 直读；栈模式 `profile_folded()` 落 `<userdir>/profile_folded.txt`（folded 格式，文件头带 `# samples= base=`）。
- 离线标注与火焰图见 `mods/lua_verify/tools/sampler_annotate.py`。

### 3.10 出站网络

`hoi4_http_client.cpp`：出站 HTTP(S) 走 **cpp-httplib + mbedTLS**（与入站 server 同栈）。

- **全请求硬 deadline**（默认 180s）：交换跑 worker 线程，调用方只等剩余预算，超期返 `(nil,"timeout")`，detached worker 由自身分阶段超时兜底。
- **阻塞调用线程**——游戏代码一律经 `async_exec` 走工作线程。
- TLS 证书校验走 **Windows 根证书库**，SNI/Host 对原域名，安全不降级。
- 代理**发现**用 OS 自身配置源（`WinHttpGetIEProxyConfigForCurrentUser` + WPAD，自查注册表 `ProxyEnable`——IE API 会泄漏已停用的残留 `ProxyServer`），但不用 WinHTTP 传输。
- 地址族：DNS 名先探针（v4 优先、每址 1.2s、总 2.5s），`set_hostname_addr_map` 钉 IP 而 SNI/证书仍对真域名；探针失败无害地落回直连。

### 3.11 静态资源与 defines

DLL 侧只提供扫描原语：`define_lookup` / `define_targets` / `defines_build` / `defines_count`。**静态资源知识本身住在 Lua 层**（`mods/*/lua/resource.lua`），因为那是布局知识而非机制。

defines 表在 Lua 层有**进程内缓存**：表文件更新后须 `dofile(resource.lua)(GAME.layout)` 重挂载，否则读旧表。

---

## 4. 请求与事件流

### 4.1 HTTP 请求生命周期

```
httplib worker                    引擎主线程（帧顶）
  ├─ 收请求
  ├─ 入队（payload 拷进队列）
  ├─ 等待 ────────────────────────► http_poll_main(4)
  │                                   ├─ 出队
  │                                   ├─ 执行（console / lua / pause）
  │                                   └─ 写回结果
  └─ 取结果，应答
```

worker **只入队**，不碰引擎。引擎工作全部在帧顶 `http_poll_main` 里做，每帧上限 4 条，剩余排到下一帧。

两个 payload 上限，**取小者**：

| 门 | 值 | 条件 |
|---|---|---|
| `HTTP_PAYLOAD_MAX` | 64KB | 恒有 |
| httplib form-urlencoded 上限 | 8KB | content-type 为 `application/x-www-form-urlencoded` 时 |

`curl --data-binary` 不带 `-H` 时默认发后者，所以 **>8KB 的 @文件 chunk 必须显式带 `-H "Content-Type: text/plain"`**，否则是 413 空响应（与服务端 64KB 门无关）。等价稳定通道：`--data-binary 'return dofile("<绝对路径>")'`。

`/lua` **只在游戏内可执行**（帧顶 poll；主菜单超时属设计）。

### 4.2 SSE

`GET /events` 推 `session_start` / `session_end`。会话事件由 DR 断点在主线程产生，SSE 扇出到所有已连接客户端。

### 4.3 会话切换时序

```
DR 事件（ctor/dtor 写）
  └─ 置 g_evStart / g_evEnd（可能同一读档合并为 END+START）
       └─ 下一帧帧顶 session_dispatch_locked 消费
            ├─ hook_session_regen()    ← vtable 补丁保留，只刷新簿记
            ├─ force_reload_locked()   ← 全量 re-dofile = 新脚本环境
            ├─ bind 表重盖世代 + obj+0x20 token 校验
            └─ 幂等重开 HasGameStarted 门
```

---

## 5. 扩展配方

### 5.1 新增 `hoi4.*` API

1. `src/hoi4_common.h` 声明 `int hoi4_xxx(lua_State *Ls);`（放在对应分节下，保持分组）。
2. 实现。**若读写内存或调用引擎，必须先过 `memgate_write_ok` / `memgate_exec_ok`**，并给写操作加回读校验。
3. `src/hoi4_main.cpp` 的 `hoi4_lib[]` 加一行 `{"xxx", hoi4_xxx},`。
4. `tools/build_dll.cmd` 重建。
5. 游戏内 `POST /lua` 热验；定稿落回 `.lua` 文件（探针推上去的闭包只活当前会话）。

### 5.2 新增 HTTP 端点

1. `src/hoi4_http_server.cpp` 的 setup 里注册 `svr.Get/Post`。
2. handler **不得直接碰引擎**——只读进程外状态，或把工作入队。
3. 引擎工作写进主线程的 `http_poll_main` 执行路径。
4. 注意两个 payload 上限（§4.1）；状态型请求（如 `/game/pause`）要写清 body 契约。

### 5.3 新增镜像偏移

1. 取证（`tools/scan_gs_writers.py` 一类扫描器，或反编译语料）。
2. `src/hoi4_common.h` 的 `OFF_*` 枚举加项——**枚举顺序即索引**，必须与值表同序。
3. `src/hoi4_offsets.h` 的 `kOffValues` 同序加行（值 + 证据注）。
4. 重建。PE 签名门与「表项非零」门会自动把填错的表挡在启动阶段。

### 5.4 新增钩子

**先分清层级**：虚方法 → Tier 1（`hook_vt`）；非虚函数 → Tier 2（`install_abs_jmp`，需 LDE 能干净窃取序言）。

Tier 1 选目标：

1. 确认该方法是**引擎经虚表调用**的（书 §4.00.x 的槽契约表；`ref/vt_rtti.json` 查类名）。
2. 槽号走书的家族槽表，勿凭猜。
3. 确认槽内不是 `_purecall` / `_guard_check_icall_nop`。
4. `hoi4.hook_vt(vt, slot, fn, {id=..., args=..., ret=..., mode=...})`。
5. **触发式验证**：装上 observe 后主动触发一次该行为再看命中（零风险）。不要用「干等一段时间零命中」去否定虚表调用——低频路径在窗口内本来就不触发。
6. `hoi4.unhook_vt(id)` 卸除。

Tier 2 选目标：

1. 游戏内 `hoi4.detour_probe(addr)` 勘察（**只读，随时可用**，不受首载门限制）——它一次报全 G1~G6 的结论、`.pdata` 函数边界、需窃字节数与十六进制。
2. `ok=true` 才写进 mod 的 `.lua`：`hoi4.detour(addr, fn, {id=..., args=..., this=..., mode=...})`。
3. **重启游戏**（首载期安装）。
4. 之后**只改回调体** → 热重载立即生效，无需再重启。换目标才需重启。

⚠ 目标必须是**函数起点**且序言无相对跳转 / 无 RIP 相对操作数；`jmp real_fn` 转发桩会被拒（提示改钩目的地）。

### 5.5 mod 侧读写层

reader（容器布局 / 偏移 / 枚举链 / 挂载点）住 `hoi4_layout.lua` + `objects_v2.lua`；writer 发射规则住 `sv2/sv2_sec_*.lua`。**段内内联临时先行可以，定稿必须上提到 reader 层。**

容器遍历一律走 `GAME.layout` 的枚举原语（`M.vec` / `M.rh` / `M.rb` / `M.list`），禁止新写手写 `for` + 偏移步进骨架；结构计数禁止硬编码，用 `country_count()` / `state_count()` / `province_count()` 或容器自身计数。

`mods/example` 持有 `hoi4_layout.lua` / `resource.lua` / `objects_v2.lua` 的同名同步拷贝——**改层须双侧同步**。

---

## 6. 可观测

### 6.1 日志分节

每条日志带一个 `[tag]` 前缀，便于 grep 单域。日志落 `<userdir>/logs/`（每次启动被引擎清空；需要留存的产物不要放这里）。

| tag | 域 |
|---|---|
| `init` | 启动、Lua 就绪、调试模式 |
| `off` / `ver` | 偏移表装载、PE 签名校验 |
| `bridge` / `hook` | 桥机器指针、Tier 1/2 钩子装卸 |
| `frame` | 帧钩子安装与周期进度 |
| `lua` / `reload` / `policy` | chunk 执行、脚本重载、文件访问白名单 |
| `effect` / `trigger` / `registry` / `bind` | 路由注册、名快照容量、绑定表 |
| `console` / `capture` | 控制台调用、控制台管理器抓取 |
| `session` | 会话事件与重盖 |
| `timer` / `async` | 定时器、异步任务池 |
| `http` / `httpc` | 入站服务、出站客户端 |
| `call` / `load_save` / `pause` | 受门控的引擎调用、读档、暂停 |
| `mem` / `memgate` | 内存原语、写域/调用域拒绝 |
| `defines` | defines 扫描 |
| `sampler` | 采样器 |
| `harden` | stdlib 面削减 |
| `capacity` | 各表容量水位 |
| `paths` | 路径解析回退 |
| `audit` / `log` | 审计通道、日志自身 |
| `fatal` | 致命拒绝路径 |

### 6.2 audit

审计通道记录**被拒绝的操作**与**代码重定向**，同键去重（`distinct_first`）。读法：写域门拒绝 → `[memgate]`；内存原语拒绝 → `[mem]`；钩子装卸与拒绝 → `hook` 审计行（`audit_hook`）；调用域拒绝 → `mem_deny`。原则是**重定向绝不静默**。

### 6.3 capacity

`[capacity]` 在启动时报各表水位：名快照 fx/512、tr/512、watch/256、binds/512，以及 `hooks=%d/64 hslots=%d/32`。**表满 = 静默失效**（不可路由 / 不可挂），所以水位是要看的数。

---

## 7. 附录：清单

> 清单从源码生成，改注册表/路由表后应同步本节。

### 7.1 `hoi4.*` API（69）

**内存读**：`base` `to_number` `read_u64` `read_u32` `read_u16` `read_u8` `read_f32` `read_f64` `read_cstr` `read_str` `read_bytes`

**内存写**（全部带写后回读校验）：`write_u8` `write_u16` `write_u32` `write_u64` `write_f32` `write_f64` `write_str`

**路径与 mod**：`game_dir` `user_data_dir` `logs_dir` `save_dir` `read_dir` `mods_json` `read_mod_descriptor`

**注册与控制台**：`console` `console_argv` `effect` `trigger` `get_effect` `get_trigger`

**定时器**：`every` `after` `every_cancel` `timers_count`

**异步**：`async_exec` `async_cancel` `async_poll` `async_status`

**网络**：`http_request`

**scope**：`scope_country` `scope_state_id` `eval_value`

**游戏控制**：`game_speed` `game_set_speed` `game_pause`

**引擎调用原语**：`call_u64` `call_void` `engine_alloc` `engine_free` `name_to_token` `load_save`

**defines**：`define_lookup` `define_targets` `defines_build` `defines_count`

**采样分析**：`profile_start` `profile_stop` `profile_top` `profile_folded` `profile_threads` `profile_status`

**钩子（Tier 1，虚表槽）**：`hook_vt` `unhook_vt` `hook_list` `hook_status`

**重定向（Tier 2，函数体；无 unhook）**：`detour` `detour_list` `detour_status` `detour_probe`

**其他**：`log` `debug` `watch`

### 7.2 HTTP 端点（11）

| 方法 | 路径 | 语义 |
|---|---|---|
| GET | `/health` | 会话与游戏状态（`session_active` / `paused` / `game_hour` / `speed` / `date`） |
| POST | `/console` | 执行控制台命令，body = raw cmd |
| POST | `/lua` | 执行 Lua chunk，body = raw chunk 或 `{"chunk":"..."}` |
| POST | `/game/pause` | 暂停设值，body 必须是 `1` 或 `0`（set-state，非 toggle） |
| POST | `/profile/start` | `?ms=&stacks=&scope=` |
| POST | `/profile/stop` | 停止采样，保留数据 |
| POST | `/profile/top` | `?n=` leaf 直方图 |
| POST | `/profile/folded` | `?path=` 栈数据落盘 |
| GET | `/profile/status` | 采样计数 |
| GET | `/profile/threads` | 每线程 tid/hits/cpu_ms 表 |
| GET | `/events` | SSE：`session_start` / `session_end` |

### 7.3 源文件索引

| 文件 | 行数 | 职责 |
|---|---|---|
| `hoi4_async.cpp` | 891 | 异步任务池 + 跨状态序列化 |
| `hoi4_hook.cpp` | 1109 | 钩子设施（Tier 1 虚表槽 + Tier 2 门/安装） |
| `hoi4_sampler.cpp` | 767 | 采样式性能分析器 |
| `hoi4_console.cpp` | 708 | 控制台桥 + 崩溃取证 |
| `hoi4_launcher.cpp` | 636 | launcher（独立 exe） |
| `hoi4_main.cpp` | 621 | DLL 入口、Lua 引导、`hoi4_lib[]` 注册表 |
| `hoi4_paths.cpp` | 599 | 路径解析三级回退 |
| `hoi4_audit.cpp` | 533 | 审计通道 |
| `hoi4_http_server.cpp` | 485 | 入站 HTTP 控制面 |
| `hoi4_http_client.cpp` | 455 | 出站 HTTP(S) |
| `hoi4_common.h` | 424 | 共享声明 + `OFF_*` 枚举 |
| `hoi4_vtable.cpp` | 408 | effect/trigger 路由与 vtable 构造 |
| `hoi4_lua_policy.cpp` | 391 | Lua 文件访问白名单 |
| `hoi4_primitives.cpp` | 385 | 内存读写原语 |
| `hoi4_defines.cpp` | 382 | defines 扫描 |
| `hoi4_call.cpp` | 265 | 受门控引擎调用 + 写侧包装 |
| `hoi4_lde.h` | 215 | 指令长度解码器（纯，可单测） |
| `hoi4_session.cpp` | 212 | 会话生命周期（DR 断点） |
| `hoi4_detour.cpp` | 344 | Tier 2 函数体重定向引擎 + DLL 入口（`DllMain`） |
| `hoi4_pdata.cpp` | 89 | `.pdata` 函数边界表（采样器 + detour 门共用） |
| `hoi4_memgate.cpp` | 168 | 内存域两道门 |
| `hoi4_timer.cpp` | 159 | 定时器 |
| `hoi4_harden.cpp` | 145 | stdlib 面削减 |
| `hoi4_frame.cpp` | 142 | 帧顶派发 + 帧钩子 |
| `hoi4_game.cpp` | 133 | 游戏控制（速度/暂停） |
| `hoi4_hook.h` | 130 | 钩子契约与设计理由 |
| `hoi4_pol.h` | 110 | 策略层接口 |
| `hoi4_defines_lua.cpp` | 98 | defines 的 Lua 绑定 |
| `hoi4_registry.cpp` | 74 | effect/trigger registry |
| `hoi4_scope.cpp` | 70 | scope 上下文访问器 |
| `hoi4_offsets.h` | 62 | 地址值表 + 证据注 |
| `hoi4_offsets.cpp` | 41 | 值表发布 + 签名校验 |
| `hoi4_bridge.cpp` | 35 | 桥杂项 |
