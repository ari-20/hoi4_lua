## 中文说明

《钢铁雄心 IV》运行时扩展框架（1.19.3.0, rev c01a3d50）：注入式 DLL
（`hoi4_bridge.dll`），在游戏内承载 Lua 虚拟机，把 mod 脚本的
effect/trigger 路由进引擎，并开放环回 HTTP 控制面；配套
`hoi4_launcher.exe` 确定性注入器（CREATE_SUSPENDED + QueueUserAPC，
游戏启动前完成加载）。

**版本说明**：当前仅支持 hoi4.exe 1.19.3.0-c01a3d50。DLL 加载时校验 PE
签名，其他构建一律拒绝激活——游戏换版需重新推导 `src/hoi4_offsets.h`
地址表并重编。

## ⚠ 危险性提示

本框架会在游戏进程内执行所有已启用 mod 的 `lua/` 目录下的 Lua 代码。
脚本仍可任意读写游戏进程内存、直接调用引擎函数、执行控制台命令、发起
出站 HTTP——足以损坏存档或游戏安装。

框架对**操作系统层面**的权限做了收窄（源码：`src/hoi4_harden.cpp` /
`src/hoi4_lua_policy.cpp` / `src/hoi4_audit.cpp`；在加载任何 mod 脚本前
生效）：

- **标准库裁剪**：`os.execute` / `os.exit` / `os.tmpname` /
  `os.setlocale` / `os.getenv`、`io.popen` / `io.tmpfile`、
  `package` / `require` 全部移除；`debug` 仅留 `getinfo` /
  `traceback`（砍掉 `getupvalue` / `getregistry` 等逃逸链）。
- **文件访问受限**：`dofile` / `loadfile` / `io.*` / `os.remove` /
  `os.rename` 只能触达已注册根目录——已启用 mod 的目录 + 存档目录；
  其余位置一律拒绝。
- **审计日志**（默认开启）：出站 HTTP、文件访问、代码加载逐目标记入
  `<文档>\...\logs\audit\hoi4_audit.log`；
  内存 / 引擎调用按 mod 在会话结束汇总。级别 `-audit=<off|normal|verbose>`
  或环境变量 `HOI4_AUDIT`。

沙箱覆盖不到框架的核心面——游戏内存读写与引擎调用仍是全权，控制台
与出站 HTTP 也仍可用（仅审计、不拦截）——这正是框架存在的意义。
因此启用 mod 仍应以信任为前提：

- **本仓库**自身的代码开源，且每次推送都有自动安全检测（ClamAV
  产物扫描、CodeQL 静态分析、gitleaks 密钥扫描）。
- 本仓库**不对其他 mod 内的代码作任何担保**。只启用你读过并信任的
  mod 的 Lua，且只把它指向一个你接受损坏的游戏安装。

### 目录

```
src/                 DLL + launcher 源码（C/C++，MSVC）
book/                类布局全书
mods/                Lua mod：lua_verify（内存↔存档一致性验证）与
                     example（功能样板，见下）
ref/                 书引用的机器可读数据件（token/defines/rtti 等）
third-party/         httplib 0.56.0（单头 vendor）/ Lua 5.4.7（与官方
                     tarball 逐字节一致，C++ 侧一律经 lua.hpp）/
                     Mbed TLS v3.6.4（submodule）
tools/               构建脚本（build_mbedtls 逻辑在 PowerShell）
tests/               纯函数单测（LDE 钩装指令长度译码器 + 路径沙箱判定）
```

### DLL 构建

前置：Visual Studio 2022（C++ 工具集 + CMake 组件），按顺序：

```
git clone --recurse-submodules <本仓库>
git -C third-party/mbedtls submodule update --init   # mbedtls 自带的嵌套 framework 子模组

tools\build_mbedtls.cmd    # Mbed TLS 静态库（Release，/MT）
third-party\lua54\build_lua.cmd  # lua54_static.lib
tools\build_dll.cmd        # hoi4_bridge.dll + hoi4_launcher.exe
```

`tools\run_tests.cmd` 跑单元测试；`tools\build_dll_check.cmd` 编译+链接
到一次性产物，用于游戏运行（DLL 被锁）时的构建校验。

- 设环境变量 `HOI4_DEPLOY_DIR` 后，`build_dll.cmd` 构建成功会把两个产物
  复制过去（launcher 从自己所在目录加载 DLL，两者须同目录）。

### mod 注册
- **mod 注册**：游戏读取的是 userdir（`文档\Paradox Interactive\Hearts of
  Iron IV\mod\`）下带 `path=` 的描述文件。新机器克隆后运行一次：

```
mods\register_userdir.cmd    （或 powershell -File mods\register_userdir.ps1）
```

### 两个 mod 的作用

- **example**：功能样板 mod，演示桥接能力。游戏内决议开关每日
  tick：自动轮换存档（`autosave_<时间戳>.hoi4`，滚动保留 12 份）、
  空科研槽自动随机研究、空国策槽自动选国策，空闲民工自动建造；另有 RNG 重播种
  （`eval_effect example_reseed_rng = yes`）和 LLM「存档锐评」事件
  （API key 填在 `mods/example/review_config.txt`，模板见
  `review_config.example`）。
- **lua_verify**：内存 ↔ 存档数据一致性验证（导出内存世界态并与存档
  文件对拍）。**对普通用户无用**。使用它需要在游戏设置中关闭二进制
  存档（settings.txt：`save_as_binary=no`），否则存档侧无法解析。

### lua_verify 使用流程

导出内存中的世界态，与同一时刻的存档逐字段对拍，定位两侧不一致的
数据。这是修改导出段后做回归验证的主要手段。需要 `-http` 控制面、
文本存档与 Python 3（对拍工具）。全程暂停态操作——读档后引擎自动
暂停；若已继续游戏，先置暂停（body 必须是 `1` / `0`）：
`curl -X POST 127.0.0.1:17389/game/pause --data-binary '1'`

1. 前置：`settings.txt` 置 `save_as_binary=no`，带 `-http` 带档启动：
   `hoi4_launcher.exe -start_save=<档名> -http=17389`
2. 重存对拍基准档（独立 POST，~20s 等写盘）：
   `curl -X POST 127.0.0.1:17389/lua --data-binary 'hoi4.console("savegame anchor1") return "ok"'`
3. 导出内存态：
   `curl -X POST 127.0.0.1:17389/lua --data-binary 'return sv2_export()'`
   → 落 `mods/lua_verify/lua/tmp_savefull_mem.txt`，成功另写
   `tmp_savefull_done.flag`（返回叶数；脚本化等待可用
   `mods/lua_verify/tools/wait_export.py`）。段文件
   （`lua/sv2/sv2_sec_*.lua`）在每次导出时重载，磁盘改动即生效。
4. 提取基准件（**必须**用 `savefull3.py`，勿拿 mem 顶替）：
   `python mods/lua_verify/tools/savefull3.py "<文档>\Paradox Interactive\Hearts of Iron IV\save games\anchor1.hoi4" extract`
   → `tmp_savefull_all.txt`
5. 对拍：
   `python mods/lua_verify/tools/linediff.py tmp_savefull_all.txt mods/lua_verify/lua/tmp_savefull_mem.txt`
   → `tmp_linediff_report.txt`：MATCH / DIFF / MISS_MEM / MISS_SAVE /
   EXEMPT（写盘时刻 / 墙钟类豁免叶，清单与裁定规则见 `linediff.py`
   头部；豁免只能人工裁定，勿擅自扩大）。

`sv2_export("<档名>")` 亦可在一次调用内完成重存 + 导出（同帧同刻），
但嵌套 savegame 偶发崩溃——优先用上面拆分的两步。

### mod 选择

launcher 不能选择 mod。启用/停用 mod 请用 **Paradox Launcher**（播放
集）选择，或手动编辑 `<文档>\Paradox Interactive\Hearts of Iron
IV\dlc_load.json` 的 `enabled_mods`。前提是描述文件已注册（见上，
`mods\register_userdir.cmd`）。

### 使用

直接运行 `hoi4_launcher.exe` 即可——无需任何参数。launcher 自动定位
HOI4 安装，在游戏代码运行前把 `hoi4_bridge.dll` 注入游戏进程并启动
游戏。launcher 与 DLL 必须同目录。DLL 日志写在
`<文档>\...\logs\hoi4_bridge.log`。

### launcher 如何找到 hoi4.exe

1. `--exe=<路径>`——显式指定（路径必须存在）；
2. Steam 自动发现：注册表 `HKCU\Software\Valve\Steam\SteamPath` →
   `steamapps/libraryfolders.vdf` → 找到持有 app id 394360 的库 →
   其 `installdir`；
3. 都找不到则拒绝启动，提示使用 `--exe=`。

### 常用启动参数（单横线——原样直通 hoi4.exe）

| 参数 | 作用 |
|---|---|
| （无） | 正常启动——直接双击 exe 等价 |
| `-start_save=<档名>` | 启动时读档；并按存档头的 mod 块回写启用 mod 清单 |
| `-start_tag=<TAG>` | 以指定国家 TAG 开新局 |
| `-debug` | 开启游戏调试控制台 |
| `-human_ai` | 让游戏 AI 托管玩家国（测试用） |
| `-http[=<端口>]` | **DLL新增功能**，开启环回控制面（默认 17389） |
| `-audit=<级别>` | **DLL新增功能**，审计日志级别（off/normal/verbose，默认 normal） |

### launcher 参数（双横线——launcher 消费，不传给游戏）

| 参数 | 作用 |
|---|---|
| `--exe=<路径>` | 覆盖 hoi4.exe 位置 |
| `--probe` | 解析全部路径并打印，不启动游戏 |

### 控制面（需 `-http`）

| 端点 | 语义 |
|---|---|
| `GET /health` | 会话/游戏状态（帧心跳判据，主菜单为 false） |
| `POST /lua` | 在主 VM 执行 Lua 片段（raw body） |
| `POST /console` | 执行控制台命令 |
| `POST /game/pause` | 幂等暂停设值（非 toggle） |
| `GET /events` | SSE 事件流（会话开始/结束） |

### 环境变量

| 变量 | 使用者 | 用途 |
|---|---|---|
| `HOI4_DEPLOY_DIR` | `build_dll.cmd` | 构建成功后产物复制目标目录 |
| `HOI4_GAME_DIR` | 分析工具、`scan_gs_writers` | HOI4 安装目录覆盖 |
| `HOI4_EXE` | `scan_gs_writers.py` | hoi4.exe 路径覆盖 |
| `HOI4_USERDIR` | L2 工具、`session_regression.py` | userdir 覆盖 |
| `HOI4_WORKSHOP` | `random_start_tag.py` | workshop 内容目录覆盖 |
| `HOI4_DLL_DEBUG=1` | DLL | 详细桥接日志 |
| `HOI4_AUDIT` | DLL | 审计日志级别（off/normal/verbose） |
| `MOD_LUA_DIR` | `wait_export.py`、Lua 侧 | mods lua 目录覆盖 |

依赖许可证见 `THIRD-PARTY-NOTICES.md`。

## 致谢

本项目的主要开发工作由 AI 完成，感谢：
**DeepSeek-V4-Flash-0731**、**deepseek-v4.1-flash**、**glm-5.3**、
**glm-5.3-flash**、**kimi-k3**。

---

## English

Runtime-extension framework for Hearts of Iron IV (1.19.3.0, rev
c01a3d50): a DLL (`hoi4_bridge.dll`) injected into the game that hosts a
Lua VM, routes mod-scripted effects/triggers through the engine, and
exposes a loopback HTTP control plane — plus `hoi4_launcher.exe`, the
deterministic injector (CREATE_SUSPENDED + QueueUserAPC) that loads the
bridge before the game starts.

**Version note**: only hoi4.exe 1.19.3.0-c01a3d50 is supported for now.
The DLL verifies the game's PE signature at load and refuses to activate
on any other build — a new game version means re-deriving the address
table in `src/hoi4_offsets.h` and rebuilding.

## ⚠ Safety

The framework executes Lua from every enabled mod's `lua/` directory
inside the game process. Scripts can still read and write game process
memory freely, call engine functions directly, run console commands and
make outbound HTTP requests — enough to corrupt saves or a game install.

OS-level privileges are narrowed (sources: `src/hoi4_harden.cpp` /
`src/hoi4_lua_policy.cpp` / `src/hoi4_audit.cpp`; all applied before any
mod script loads):

- **Stdlib reduction**: `os.execute` / `os.exit` / `os.tmpname` /
  `os.setlocale` / `os.getenv`, `io.popen` / `io.tmpfile`, `package` /
  `require` are removed; `debug` keeps only `getinfo` / `traceback` (the
  `getupvalue` / `getregistry` escape chains are gone).
- **File access restricted**: `dofile` / `loadfile` / `io.*` /
  `os.remove` / `os.rename` can only reach registered roots — the enabled
  mods' directories plus the save directory; every other location is
  rejected.
- **Audit log** (on by default): outbound HTTP, file access and code
  loads are recorded per distinct target in
  `<Documents>\...\logs\audit\hoi4_audit.log`; memory/engine calls are
  summarised per mod at session end. Level: `-audit=<off|normal|verbose>`
  or the `HOI4_AUDIT` environment variable.

The sandbox cannot cover the framework's core surface — game memory and
engine calls remain unrestricted, and console commands / outbound HTTP
remain available (audited, not blocked) — that is the point of the
framework. Enabling a mod therefore still requires trust:

- The code in THIS repository is open source and automatically scanned
  on every push (ClamAV artifact scan, CodeQL static analysis, gitleaks
  secret scan).
- We make NO claim about code inside other mods. Only enable mods whose
  Lua you have read and trust, and only point this at a game installation
  you are prepared to break.

### Layout

```
src/                 DLL + launcher sources (C/C++, MSVC)
book/                the class-layout book
mods/                Lua mods: lua_verify (memory↔save consistency
                     verification) and example (functional sample, below)
ref/                 machine-readable data files the book references
third-party/         httplib 0.56.0 (vendored single header) / Lua 5.4.7
                     (byte-identical to the official tarball; C++ side
                     always includes via lua.hpp) / Mbed TLS v3.6.4
                     (submodule)
tools/               build scripts (build_mbedtls logic in PowerShell)
tests/               unit tests (LDE hook-length decoder + path sandbox)
```

### Building the DLL

Prerequisites: Visual Studio 2022 (C++ toolset + CMake component), then:

```
git clone --recurse-submodules <this repo>
git -C third-party/mbedtls submodule update --init   # mbedtls's own nested 'framework' submodule

tools\build_mbedtls.cmd          # Mbed TLS static libs (Release, /MT)
third-party\lua54\build_lua.cmd  # lua54_static.lib
tools\build_dll.cmd              # hoi4_bridge.dll + hoi4_launcher.exe
```

`tools\run_tests.cmd` runs the unit tests; `tools\build_dll_check.cmd`
compiles+links to a throwaway artifact — use it to verify the build while
the game is running and the real DLL is locked.

- With `HOI4_DEPLOY_DIR` set, a successful `build_dll.cmd` copies both
  artifacts there (the launcher loads the DLL from its own directory, so
  the two files belong together).

### Registering mods

- **Mod registration**: the game reads descriptors with `path=` under the
  userdir (`Documents\Paradox Interactive\Hearts of Iron IV\mod\`). Run
  once per fresh clone:

```
mods\register_userdir.cmd    (or: powershell -File mods\register_userdir.ps1)
```

### The two mods

- **example** — functional sample mod showing bridge capabilities.
  In-game decisions toggle daily ticks: autosave rotation
  (`autosave_<timestamp>.hoi4`, keeps the last 12), auto-research for
  empty research slots, auto-national-focus for empty focus slots, and
  auto-building on idle civilian factories; plus RNG reseeding
  (`eval_effect example_reseed_rng = yes`) and an LLM "save review" event
  (API key goes into `mods/example/review_config.txt`, see
  `review_config.example`).
- **lua_verify** — memory↔save consistency verification: exports the
  in-memory world state and diffs it against the save file. **Useless for
  normal players.** Requires text saves (settings.txt:
  `save_as_binary=no`), or the save side cannot be parsed.

### Using lua_verify

Exports the in-memory world state and diffs it field-by-field against a
save from the same instant to locate inconsistent data. This is the main
regression check after changing export segments. Requires the `-http`
control plane, text saves and Python 3 (for the diff tools). Do
everything paused — the game pauses automatically after loading a save;
if it has been resumed, pause first (the body must be `1` / `0`):
`curl -X POST 127.0.0.1:17389/game/pause --data-binary '1'`

1. Prerequisites: `save_as_binary=no` in `settings.txt`; start with
   `-http`: `hoi4_launcher.exe -start_save=<name> -http=17389`
2. Re-save the anchor (a separate POST; wait ~20 s for the write to
   finish):
   `curl -X POST 127.0.0.1:17389/lua --data-binary 'hoi4.console("savegame anchor1") return "ok"'`
3. Export the memory state:
   `curl -X POST 127.0.0.1:17389/lua --data-binary 'return sv2_export()'`
   → writes `mods/lua_verify/lua/tmp_savefull_mem.txt` and, on success,
   `tmp_savefull_done.flag` (returns the leaf count;
   `mods/lua_verify/tools/wait_export.py` polls for the flag). Segment
   files (`lua/sv2/sv2_sec_*.lua`) are reloaded on every export, so disk
   edits take effect immediately.
4. Extract the anchor (**always** with `savefull3.py`, never substitute
   the mem file):
   `python mods/lua_verify/tools/savefull3.py "<Documents>\Paradox Interactive\Hearts of Iron IV\save games\anchor1.hoi4" extract`
   → `tmp_savefull_all.txt`
5. Diff:
   `python mods/lua_verify/tools/linediff.py tmp_savefull_all.txt mods/lua_verify/lua/tmp_savefull_mem.txt`
   → `tmp_linediff_report.txt`: MATCH / DIFF / MISS_MEM / MISS_SAVE /
   EXEMPT (write-time and wall-clock exempt leaves; the list and the
   adjudication rule live in the `linediff.py` header; exemptions are
   human-adjudicated only — do not widen them on your own).

`sv2_export("<name>")` can re-save and export in a single call (same
frame, same instant), but the nested save occasionally crashes — prefer
the split two-step above.

### Choosing mods

The launcher cannot select mods. Enable/disable them with the **Paradox
Launcher** (playset), or edit the `enabled_mods` list in
`<Documents>\Paradox Interactive\Hearts of Iron IV\dlc_load.json` by
hand. Descriptors must be registered first (see above,
`mods\register_userdir.cmd`).

### Usage

Run `hoi4_launcher.exe` — no arguments needed. It locates your HOI4
install, injects `hoi4_bridge.dll` into the game process before any game
code runs, and starts the game. The launcher and the DLL must stay in the
same folder. The DLL logs to `<Documents>\...\logs\hoi4_bridge.log`.

### How the launcher finds hoi4.exe

1. `--exe=<path>` — explicit override (path must exist);
2. Steam auto-detect: registry `HKCU\Software\Valve\Steam\SteamPath` →
   `steamapps/libraryfolders.vdf` → the library holding app id 394360 →
   its `installdir`;
3. otherwise the launcher refuses to start and asks for `--exe=`.

### Common launch options (single dash — passed through to hoi4.exe verbatim)

| option | effect |
|---|---|
| *(none)* | normal start — double-clicking the exe is equivalent |
| `-start_save=<name>` | load this save at startup; also re-syncs the enabled-mod list from the save's mod block |
| `-start_tag=<TAG>` | start a new game as country TAG |
| `-debug` | enable the game's debug console |
| `-human_ai` | let the game AI play the player country (testing) |
| `-http[=<port>]` | **DLL feature**: enable the loopback control plane (default 17389) |
| `-audit=<level>` | **DLL feature**: audit log level (off/normal/verbose, default normal) |

### Launcher flags (double dash — consumed by the launcher, not the game)

| flag | effect |
|---|---|
| `--exe=<path>` | override the hoi4.exe location |
| `--probe` | resolve every path, print it, exit without launching |

### Control plane (needs `-http`)

| endpoint | semantics |
|---|---|
| `GET /health` | session/game state (frame-heartbeat based; false in the main menu) |
| `POST /lua` | execute a Lua chunk in the main VM (raw body) |
| `POST /console` | execute a console command |
| `POST /game/pause` | idempotent pause set-state (not a toggle) |
| `GET /events` | SSE stream (session start/end) |

### Environment variables

| variable | used by | purpose |
|---|---|---|
| `HOI4_DEPLOY_DIR` | `build_dll.cmd` | where a successful build copies the artifacts |
| `HOI4_GAME_DIR` | analysis tools, `scan_gs_writers` | HOI4 install dir override |
| `HOI4_EXE` | `scan_gs_writers.py` | hoi4.exe path override |
| `HOI4_USERDIR` | L2 tools, `session_regression.py` | userdir override |
| `HOI4_WORKSHOP` | `random_start_tag.py` | workshop content dir override |
| `HOI4_DLL_DEBUG=1` | the DLL | verbose bridge logging |
| `HOI4_AUDIT` | the DLL | audit log level (off/normal/verbose) |
| `MOD_LUA_DIR` | `wait_export.py`, Lua side | mods lua dir override |

Dependency licenses: see `THIRD-PARTY-NOTICES.md`.

## Acknowledgements

The primary development work of this project was carried out by AI — with
thanks to DeepSeek-V4-Flash-0731, deepseek-v4.1-flash, glm-5.3,
glm-5.3-flash and kimi-k3.
