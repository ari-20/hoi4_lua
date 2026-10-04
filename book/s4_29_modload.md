### 4.29 mod 装载与虚拟文件系统 (descriptor 解析 / 启用清单 / PHYSFS 挂载)

> **定位**: 启动阶段的 mod 装载全链 —— `.mod`/`.dlc` 文件解析 (`descriptor` key 派发)、
> `dlc_load.json` 启用清单读取、mod 注册表、启用集合的依赖排序与优先级、以及
> 引擎虚拟文件系统 (PhysicsFS) 的挂载封装。
> 关键结论: **引擎全文件 I/O 走 PHYSFS**; mod 内容能否被解析, 取决于该 mod 目录
> 是否被挂进 PHYSFS 搜索路径, 而非其文件是否存在。mod 间优先级 = 权重 (依赖降权)
> + registry id (`.mod` 文件名) 字典序, 见 §4.29.4。

#### 4.29.1 PHYSFS 虚拟文件系统层 (virtualfilesystem_physfs.cpp)

引擎静态链入 **PhysicsFS** (108 个 `?PHYSFS_*` 导出符号, 见 §4.29.6)。

引擎封装层 (`clausewitz/pdx_core/virtualfilesystem_physfs.cpp`) 关键函数:

| 函数 | 语义 | 要点 |
|---|---|---|
| sub_1424DD3E0 | VFS 初始化 | `PHYSFS_init` → `PHYSFS_permitSymbolicLinks(1)` → 设写目录 (`PHYSFS_setWriteDir`) 或回落 `PHYSFS_mount(PHYSFS_getBaseDir, 0, 0)` |
| sub_1424DD6B0 | **批量挂载** | 逐路径 `PHYSFS_mount(path, 0, 0)` (三参 appendToPath=0) → `PHYSFS_getSearchPath()` 重建路径表, 缓存于 `qword_1435E3E70`, 同时反斜杠→正斜杠归一化 |
| sub_1424DD760 | 单次挂载 (带挂点) | `PHYSFS_mount(path, mountpoint, 0)`; 失败报 `"Failed to mount '%s' on '%s': %d (%s)"` (virtualfilesystem_physfs.cpp:522) |
| sub_1424DD7F0 | 挂载 + 设写目录 | `PHYSFS_mount` + `PHYSFS_setWriteDir`; 失败断言 `"Cannot set write dir."` (:687) |
| sub_1424DB5F0 | 挂载后刷新 | 被上述各挂载路径在成功后统一调用 |

> 备注: `PHYSFS_mount` 第三参 `appendToPath` 恒为 0 — 挂载顺序 (而非 append 语义)
> 决定同名文件的优先级: **后挂载者优先** (PHYSFS 搜索路径前插)。库层实现点 =
> mount 公共核心 sub_1424F77F0 头插分支 (§4.29.1a)。

#### 4.29.1a PHYSFS 库本体 (physfs.cpp / vendored PhysicsFS 3.x 魔改)

分工定案: 库实现层 `clausewitz/pdx_core/physfs/physfs.cpp` (0x1424F24F0..0x1424F9220,
19 函数) 与封装层 (§4.29.1, virtualfilesystem_physfs.cpp 0x1424DD 域) 两层 — 封装层调库
导出, 库不感知引擎。库状态 Config 块基址 `xmmword_1435E3F90` (sub_1424F6320 magic-static
getter; `word_1435E4088` 已初始化旗):

| 偏移 | 内容 |
|---|---|
| +8 | 搜索路径 DirHandle 单链表头指针 |
| +16 | 写目录 DirHandle 句柄 (空 → mkdir/写报错误码 13) |
| +40 | archiver 列表头指针 (openDirectory 扩展名选型循环起点) |
| +64 | 挂载前缀长度 (canonical 化缓冲预留) |
| +88 | 全局互斥体 (std::mutex; 冻结位 =1 时全库跳锁) |
| +248 | init 成功位 (archiver 注册完置 1) |
| +249 | permitSymbolicLinks 旗 (VFS init 封装层置 1) |
| +250 | 冻结位 (freezeConfig 写; =1 锁消隐) |

挂载公共核心 sub_1424F77F0(io, newDir, mountPoint, appendToPath) = mount/mountIo/
mountHandle/mountMemory/addToSearchPath/setSaneConfig 七入口公共: dirName strcmp 去重
(已挂载直返成功) → createDirHandle (sub_1424F70D0) → **appendToPath=0 头插 / 非 0 尾插**
(§4.29.1 前插定案 / §4.29.4 挂载序逆序即优先级序的函数级实现点)。DirHandle 56B:
{+0 io, +8 dirName, +16 mountPoint (尾随 '/'), +32 dirName 长度, +40 archiver, +48 next}。

freezeConfig (0x1424F3620) = 翻转 +250 返回旧值 (set-state 语义)。引擎用法 =
**临时解冻窗**: `old = freeze(0)` → 装载/挂载 → `freeze(old)` (silhouette_portraits 装载
sub_140124A70 等); 帧内常规文件访问跑在锁消隐态, 跨线程装载窗内恢复互斥。

getPrefDir 死链 (负定案): `PHYSFS_getPrefDir` 唯一调用者 = `PHYSFS_setSaneConfig`
(0x1424F5640), 而 setSaneConfig 全 dump 无调用者 — **引擎 userdir 解析不经 PHYSFS
prefdir 路线**, 三级回退全在引擎侧 sub_140120DA0: userdir.txt 存在即用 (来源旗
byte_14332EC54) → 否则读 launcher-settings.json "gameDataPath" 键 (sub_1401223E0,
含 %USER_DOCUMENTS% 替换与路径分隔归一; 来源旗 byte_14332EC55) → 回退
Documents/\<app\>。PHYSFS 只接收算好的路径 (sub_1424DD7F0 设写目录)。

游戏 boot 接线 (定案): main sub_140126E50 → sub_140128C10: VFS init 封装
sub_1424DD3E0 (PHYSFS_init + permitSymbolicLinks(1) + 挂 baseDir) → userdir 解析
sub_140120DA0 → 挂载+设写目录 sub_1424DD7F0 → "if.pdx" 批量挂载 sub_1424DD6B0 →
CDLCManager (+104 容器) 逐条 DLC 挂载 sub_142078210 → mod 向量逐条 sub_142078230 →
"integrated_dlc" 目录 \*.dlc 枚举挂载 (sub_1424E0BA0)。sub_14209E610 =
编辑器域 boot ("PdxEditor"/pdx_editor\startup.cpp, 显式 PHYSFS_freezeConfig(1)), 与游戏运行时无关。

库内部函数定位 (19 函数浓缩; 断言行号均 physfs.cpp):

| 函数 | 身份 | 要点 |
|---|---|---|
| ?PHYSFS_init | 库初始化 | baseDir/userDir 解析 (尾分隔符断言 :1271/:1272) + archiver 两轮注册 + state+248=1 |
| ?PHYSFS_mkdir | 写目录下组件级建目录 | verifyPath + 逐段 stat/mkdir; 写目录空 → 错误码 13; 唯一引擎入口 = VFS「确保目录树」封装 sub_1424DBA40 (截图落盘/openWrite 前置) |
| ?PHYSFS_getPrefDir | prefdir 计算+逐级建目录 | 静态缓存 0x1435E4098; 引擎死链 (见上) |
| ?PHYSFS_readBytes | 缓冲读循环 | PHYSFS_File {+0 io, +24 buf, +32 bufsize, +40 datalen, +48 bufpos}; zip/7z 头部小读同走此路 |
| sub_1424F8A60 | openDirectory (archiver 选型) | 扩展名 utf8stricmp 匹配循环 + 兜底循环 → archiver+48 openArchive; 无命中 → 错误码 6 |
| sub_1424F70D0 | createDirHandle | openDirectory + 填 dirName/mountPoint (尾随 '/') |
| sub_1424F9220 | verifyPath (路径越界/symlink 防线) | 挂点前缀校验 + 逐组件 stat; symlink 拒绝 = +249 旗=0 时 (错误码 12); stat/openRead/enumerate/mkdir/delete 五导出共用 |
| sub_1424F6AE0 | createNativeIo | 'r'/'w'/'a' 三模式 + 80B io 对象 |
| sub_1424F8410 | 枚举桥 (挂点影子条目) | 请求目录是 mountPoint 严格前缀时发射挂载点组件名, filetype 恒 4 (vendored 扩展标记「挂载点影子目录」, 值域外) |
| sub_1424F2740 / 2610 / 24F0 | memoryIo destroy/dup/read 三件套 | 48B MemoryIoInfo {buf, len, pos, parent, refcount, destruct}; PHYSFS_mountMemory 后端; refcount 原子, 减 0 才 destruct |
| sub_1424F68F0 / 6440 / 6D90 / 6590 | DirTree init/add/free | 64 哈希桶; add 两函数互递归建中间目录; zip (sub_1425189D0) 与 7z (sub_142512FA0) 条目装载共用 |
| sub_1424F8630 / 75F0 | archiver 注销两型 | deinit 全注销 (仍有挂载 → 错误码 8 + "nothing should be mounted during shutdown" 断言) / 单注销 |
| sub_1424F2910 | lockConfig | 输出 {链表头, 互斥体, 冻结位} 三元组; 冻结位=0 才加锁; 九导出统一入口 |
| sub_142515B30 / sub_14250AD70 | zip / 7z openArchive (相邻簇) | zip 局部头签名 "PK\x03\x04" / 7z 签名 0xAFBC7A37+0x1C27 |

错误码全表 (PHYSFS_getErrorByCode 0x1424F3850, 30 项; vendored 相对上游在 1 插
unknown error、9 插 invalid argument): 0 no error / 1 unknown error / 2 out of memory /
3 not initialized / 4 already initialized / 5 argv[0] is NULL / 6 unsupported /
7 past end of file / 8 files still open / 9 invalid argument / 10 not mounted /
11 not found / 12 symlinks are forbidden / 13 write directory is not set /
14 file open for reading / 15 file open for writing / 16 not a file /
17 read-only filesystem / 18 corrupted / 19 infinite symbolic link loop / 20 i/o error /
21 permission denied / 22 no space available for writing / 23 filename is illegal or
insecure / 24 tried to modify a file the OS needs / 25 directory isn't empty /
26 OS reported an error / 27 duplicate resource / 28 bad password /
29 app callback reported error。每线程错误码槽 = tls[TlsIndex]+2140。

#### 4.29.2 descriptor 解析 (dlc.cpp)

`.mod`/`.dlc` 文件为 PDX 脚本格式, 由 token 派发器 **sub_14207AE90** 按 key 落槽。
descriptor 对象 = **CDLCDescriptor** (sizeof 672 / 0x2A0, 拷贝构造 sub_142074CF0 逐字段印证);
注册表节点 736 (0x2E0) = 树头 32 + 键串 32 + CDLCDescriptor 672 (§4.29.4)。
key token → 槽位 (对象基点 a1; token id 取运行时 lexer):

| token | key | 偏移 | 类型 | 备注 |
|---|---|---|---|---|
| 27 | name | +8 | MSVC 串 | 注册表键 |
| 763 | localizable_name | +40 | MSVC 串 | — |
| 372 | path | +104 | MSVC 串 | mod 内容根目录 |
| 376 | archive | +136 | MSVC 串 | — |
| 373 | dependencies | +168 | MSVC 串容器 | 元素 = MSVC 串 |
| **382** | **replace_path** | **+192** | **MSVC 串容器** | 追加写入 |
| 383 | user_dir | +216 | MSVC 串 | — |
| 377 | checksum | +248 | MSVC 串 | — |
| 463 | tags | +312 | MSVC 串容器 | 写入 sub_140142BF0 |
| 464 | picture | +336 | MSVC 串 | — |
| 611 | supported_version | +368 | MSVC 串 | 经 sub_142222830 校验 |
| 702 | category | +456 | MSVC 串 | — |
| 238 | version | +488 | MSVC 串 | — |
| 712 | remote_file_id | +520 | MSVC 串 | — |
| 713 | description_file | +552 | MSVC 串 | — |
| 374 | steam_id | +624 | uint64 | 写入 sub_1424C08D0 (存储区 8B — 拷贝构造两 dword 连拷; 唯一解析写者 sscanf("%i") 4B 写, 高位保持 0) |
| 375 | pdx_id | +632 | MSVC 串 | — |
| 378 | affects_checksum | +665 | uint8 | 写入 sub_1424C0C00 |
| 610 | affects_compatability | +666 | uint8 | 同上 |
| 459 | disable_time_widget | +667 | uint8 | 同上 |
| 725 | third_party_content | +668 | uint8 | 写入 sub_1424C0C00; +664..+668 五字节区 (拷贝构造按字节整段复制) |

> 备注: 未列出的 key 落 `sub_1424BEC40(a1, a2)` 默认分支 (未知 key 跳过)。
> 备注: `supported_version` 校验失败仅告警 `"Invalid supported_version in %s"` (dlc.cpp:218), 不阻止装载。

加载序 (单个 `.mod`):

| 序 | 函数 | 动作 |
|---|---|---|
| 1 | sub_14207BCA0 | 对 mod 根目录 (`+48`) 执行 `FindFiles("*.mod")`, 逐个文件调 (2) |
| 2 | sub_142076090 | 解析该 `.mod` 文件 → key 派发 (上表) → 校验路径/number 组合, 异常报 `"Incorrect MOD descriptor: \"%s\""` (:1829) |
| 3 | sub_142074270 | 插入注册表 (`a1+176`): 有序 map, 节点 `malloc(0x2E0)` = 树头 32 + 键串 32 (`sub_1401FF2C0` 比较) + CDLCDescriptor 672 (sub_142074CF0 拷贝); **键 = descriptor name (+8)** (76090 插入键拷自 +8, 比较器同; +72 registry id = 扫描器解析前注入的文件相对路径, 独立字段非键) |
| 4 | sub_142075820 | 临时 descriptor 对象析构 |

> 备注: 扫描阶段 `FindFiles` 不区分启用状态 — 目录下所有 `*.mod` 都被解析并注册; 启用筛选在 §4.29.3。
> 备注: `.dlc` 走平行路径 sub_14207B540 (`FindFiles("*.dlc")`)。

#### 4.29.3 启用清单读取 (dlc_load.json)

装载对象 (加载器 a1) 字段:

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | 外部参数 1 | — | 构造期注入 |
| +8 | 外部参数 2 | — | 构造期注入 |
| +16 | MSVC 串 | 路径串 1 | — |
| +48 | MSVC 串 | 路径串 2 | `.mod` 扫描根 |
| +80 | 匿名结构 (NNB 形状) 向量 | disabled_dlcs | count@+92 |
| +104 | 匿名结构 (NNB 形状) 向量 | enabled_mods | count@+116 |

| 函数 | 语义 | 要点 |
|---|---|---|
| sub_142079C40 | 装载对象构造 | 先调 sub_14207BCA0 / sub_14207B540 扫描目录, 后调 sub_142075540 读清单 |
| sub_14207B540 | `.dlc` 扫描 | 同 §4.29.2 模式 |
| sub_14207BCA0 | `.mod` 扫描 | 同上 |
| sub_142075540 | 读 `dlc_load.json` | **两段式**: 填调用方栈上临时 {+0 disabled_dlcs, +24 enabled_mods} 两 24B NNB 向量, 装载 ctor 尾经 sub_140186170 区间合并进 mgr+104 / mgr+80; 打开文件 → 解析 JSON → 读失败报 `"Failed to read '%s'."` (dlc.cpp:78), 超限 (16MB) 报 `"'%s' is bigger than %llu, will not read."` (:68); **路径 = PHYSFS VFS 相对路径 (实读 `<userdir>/dlc_load.json`), 文件缺失 = 静默跳过** (存在门不过无告警); 引擎只读不写 (写方 = launcher) |
| sub_14207AC20 | JSON 数组 → MSVC 串容器 | 逐元素取串, 非串元素报 `"Expect only strings in dlcs/mods arrays."` (:97), 数组读取失败报 `"Error reading dlcs/mods arrays."` (:102) |

> 备注: enabled_mods 条目 = `mod/<文件名>.mod` 形态的 registry id (文件相对路径), 与记录 +72 处 registry id 串匹配 (`sub_14011D540`) — **不是** descriptor `name` 字段值; disabled_dlcs 同按记录 +72 匹配。

#### 4.29.4 启用集合排序与优先级 (sub_142076450)

sub_142076450 对启用集合建 16 字节条目表 `{int 权重 @+0, CDLCDescriptor* @+8}` 再排序,
排序结果**正序**驱动挂载:

| 环节 | 函数 | 要点 |
|---|---|---|
| 条目收集 (DLC 侧) | sub_142076450 首循环 | 遍历 `a1+160` 有序容器 (`sub_1401FF1F0` 后继迭代); 记录 +664 位旗置位、registry id (节点+136 = 记录+72) 不在 disabled_dlcs (`+80` 容器) → 入表, 权重 0 |
| 条目收集 (mod 侧) | sub_142076450 次循环 | 遍历 `a1+176` 有序 map (键序迭代); registry id 命中 enabled_mods (`+104` 容器, `sub_14011D540` 逐串比对) → 入表, 权重 10000 |
| 依赖降权 | sub_142076450 降权循环 | 外层 do..while 至不动点 (链条多轮收敛): 每条目逐条 dependency (记录 +168 容器) 与全表条目的 **descriptor 名 (记录 +8 MSVC 串)** 全等比较; 命中且被依赖者权重 ≥ 依赖者 → 被依赖者权重 `--` |
| 排序 | sub_142073EC0 / sub_142073FF0 | **权重升序**; 同权 tiebreak = `sub_1401FF2C0` 比较 **registry id (记录 +72)** 字典序; ≤32 条插入排序, >32 条临时缓冲归并 (std::stable_sort 形态, 同一比较关系, 推定) |
| 挂载 | sub_14207AB80 | 正序逐条: 记录 +584 type == 1 (steam DLC) 快路径 = archive (+136) 或 path (+104) 直接 `sub_14207AB80(+280, 串)` 前缀拼接挂载; **type ≠ 1 → 转通用挂载块 (非循环中止 — 全部 folder mod (type 8) 都走它)**: archive 形 (VFS 存在 → 前缀拼挂 / fopen 探测败报 `"Could not find archive for mod: %s"` dlc.cpp:647 / 成功裸 archive 直挂) 与 folder 形 (VFS 存在 → sub_14207C000 拼挂 / 绝对路径分支直挂 / 失败报 `"Folder not found for Mod %s path: %s: "` :665, %s1 = **+40 localizable_name**); 两路径汇合续下一条目; **+280 挂载前缀 = PHYSFS_getRealDir(路径)** (扫描期写入记录 +280) |

> 备注: 挂载路径 = `sub_14207C000(记录 +280 挂载根, 记录 +104 路径, 输出)`: 两串以 `/` 拼接后反斜杠→正斜杠归一化; 其一为空则直取另一。该函数只做路径规范化。+280 前缀非 token 填充 (descriptor 解析后注入)。
> 备注: 最终搜索路径 = 挂载序的**逆序** (正序挂载 + PHYSFS 前插): mod 组整体索引小于 DLC 与原版; 同权 mod 组内 **registry id 字典序靠后者索引越小** (优先级越高)。
> 备注 (**定案**): 同权 mod 间的优先级由 **registry id (即 userdir `mod/` 下 `.mod` 文件名)** 决定 — descriptor 的 `name` 字段、`dlc_load.json` 数组顺序、launcher playset 顺序均不参与排序比较 (后两者只决定启用集合成员); dependencies 是唯一能把条目改离 registry id 字典序位的机制 (被依赖者降权 → 挂载提前 → 优先级降低, 文件被依赖者覆盖)。

#### 4.29.5 replace_path 语义 (定案)

**挂载点表** (全局): 表 `qword_1435E3E78` / 计数 `dword_1435E3E84` / 容量 `dword_1435E3E80`;
记录 64B = 两个 MSVC 串 (各 32B: 指针@+0 / 长度@+8 / 容量@+16), 由 `sub_1424DB6E0` 追加:

| 记录 | 内容 | 备注 |
|---|---|---|
| 首串 (记录+0) | 物理路径 | 声明 replace_path 的 mod 目录 |
| 次串 (记录+32) | 挂载点前缀 | replace_path 值, 如 `common/decisions` |

> 备注: 实测某巨 mod 单独声明 30 条, 覆盖 `events` / `history/*` / `common/*` / `map` / `portraits` / `gfx/*` 等 (与其 descriptor 的 replace_path 行数一致)。

| 环节 | 函数 | 要点 |
|---|---|---|
| 解析 | sub_14207AE90 (token 382) | descriptor +192 MSVC 串容器 (data@+192 / count@+204) |
| 建表 | sub_1424DB6E0 | `(物理路径, 挂载点前缀)` 追加进挂载点表 |
| 触发 | sub_142076450 | 遍历 +192 容器逐条建表 (每个 replace_path 一条记录) |
| 判定 | sub_1424DA110 | 对请求目录求挂载点表命中记录的最小搜索路径索引 `v11`; 枚举条目经 `PHYSFS_getRealDir` 得物理源, 求其在搜索路径表的索引 `v36`; **`v36 > v11` 即丢弃** |
| 枚举 | sub_1424DC020 | `PHYSFS_enumerateFiles` + `PHYSFS_stat` 按目录/文件类型分派 |

> 判定读法: 枚举条目经 `PHYSFS_getRealDir` 得物理源, 在搜索路径表定位其索引 `v36`; `v36 > v11` 即不收录 (LABEL_62)。`v11` 初值 `0x7FFFFFFF` (= 无命中), 仅当请求目录命中挂载点表记录时被压到该记录的搜索路径索引。
> 备注: 目录级独占, 非文件级覆盖 — 声明者缺的文件不会由低优先级源补位。
> 备注 (**定案**): `v11` = 全部命中记录的声明者索引**最小值** — 声明者自身与其上方 (索引更小) 的源不受过滤, 下方全部隐藏。声明者优先级由 §4.29.4 排序决定: 声明者排索引 1 → 同目录其他 mod / DLC / 原版内容全部消失; 声明者被依赖降权推后 (实测索引 5) → 索引 ≤4 的 mod 内容照常保留。多声明者命中同一目录时取最小索引者的排位为界。

#### 4.29.6 PHYSFS 导出符号清单 (108)

> 下表展开 88 名 (全部真实导出); 另有 20 个实导出未逐名列: isSymbolicLink、
> setBuffer、signed 整型 read/write/swap 全族 {S,L}{B,L}E{16,32,64}。

| 族 | 符号 |
|---|---|
| 初始化/配置 | init / deinit / isInit / setAllocator / getAllocator / setSaneConfig / setRoot / permitSymbolicLinks / symbolicLinksPermitted / freezeConfig |
| 挂载 | mount / mountHandle / mountIo / mountMemory / unmount / addToSearchPath / removeFromSearchPath / getMountPoint / getSearchPath / getSearchPathCallback / getRealDir / isDirectory / exists / stat |
| 枚举 | enumerate / enumerateFiles / enumerateFilesCallback / freeList |
| 读写 | openRead / openWrite / openAppend / read / readBytes / write / writeBytes / seek / tell / eof / flush / close / fileLength / getLastModTime / delete / mkdir |
| 整型读写 | readU[BL]E16/32/64 · writeU[BL]E16/32/64 · swapU[BL]E16/32/64 |
| 路径/编码 | getBaseDir / getCdRomDirs / getCdRomDirsCallback / getDirSeparator / getPrefDir / getUserDir / getWriteDir / setWriteDir / getLastError / getLastErrorCode / getErrorByCode |
| 字符串比较/转换 | caseFold / stricmp (utf8/utf16/ucs4) / utf8From{Latin1,Ucs2,Ucs4,Utf16} / utf8To{Ucs2,Ucs4,Utf16} |
| 其他 | registerArchiver / deregisterArchiver / supportedArchiveTypes / getLinkedVersion |

#### 4.29.7 静态资源层与 mod 装载的关系

`resource.lua` 的 idb 库锚 (`M.rva.idb`) 全部是 hoi4.exe 内静态全局槽, 不受 mod 装载影响; 槽内对象由启动期内容加载填充 — mod 内容文件 (如 `common/decisions/`) 被 §4.29.5 判定丢弃或未被 PHYSFS 视图命中时, 对应库条目数不增加。

| 观测面 | 用途 |
|---|---|
| 决策库类别名单 | 判据: 引擎实际解析到的 `common/decisions/categories` 文件集合 (§4.29.5 判定的实测取证面) |
| 库条目数 | mod 内容已解析的量化指标 |

> 备注: mod 内容文件被 §4.29.5 独占过滤时 **无解析告警** — 表现为"文件存在但静默不生效", 与文件缺失可区分 (后者伴随 texture/parse 报错)。

#### 4.29.7a PHYSFS 挂载管理器单例 (qword_14344A568)

**"dlc" / "mod" 搜索路径的 owner 管理器** (CGameApplication::Init 步 12 域预接, getter 族
sub_140643800/3810; §4.28.21); 与 §4.29.4 挂载优先级体系互证 — dlc_load.json 解析出的
mod/dlc 目录挂载经此管理器执行。

#### 4.29.8 synchronized_dynamic_tokens boot 期预装载 (sub_140176F30)

common/synchronized_dynamic_tokens/*.txt 枚举逐文件 token 预注册 (CGameApplication::Init
步 1, §4.28.21); 完成旗 byte_1435E1AB1 置位 + dword_1435E1AB8 ← dword_1435E1AB4 计数快照。
**语义 = mod token id 空间的 boot 期预填充** (先于 mod 装载的固定 token 集) — 与
「离线 token 表 ≠ 运行时 lexer」纪律同源: 凡按 token id 取名仍须游戏内
GAME.layout.token_name, 但此目录的 token 在任何 mod 之前即占位。

#### 4.29.9 DLC feature gate 与归属校验链 (gamedlc.cpp / dlc.cpp)

**feature gate** (sub_1401AEB50, gamedlc.cpp:230): feature id → **dword_14332F248 位测试** (未知 id 一次性告警 "Unrecognized DLC feature flag."); boot 掩码构建 sub_1401AEDA0 = 12 名查询置位 + 收尾强制 `|=0x1E` (四个 legacy 扩展恒开); 掩码 setter/getter = sub_1401AED90/0x1401AE6A0 (存档 11546 恢复环 sub_141998D60→sub_1401AED90); 超集判定 sub_1401AED80 `(mask & g) == mask`; 伴生全局 dword_14332F24C = 4608 (语义未定)。位→DLC 名 (代码字面串): 0x1 Poland / 0x20 La Resistance / 0x40 Battle for the Bosporu / 0x80 No Step Back / 0x100 By Blood Alone / 0x400 Arms Against Tyranny / 0x800 Trial of Allegiance / 0x2000 Gotterdammerung / 0x4000 Graveyard of Empires / 0x8000 No Compromise No Surrender / 0x10000 Peace For Our Time / 0x20000 Thunder at Our Gates; 位 0x2/0x4/0x8/0x10 ↔ TFV/DoD/WtT/MtG 四名对应为推定 (恒置无查询串)。431 个消费点 (效果/命令族大量消费, 最热 id 50/57/19/25)。

**DLC 归属校验链**: CDLCManager::VerifyAllDLCOwnership sub_14207C2A0 (tbb 符号直证类名; **dlc_signature 缓存**命中跳过逐项校验, 否则并行校验后回写); 签名 = sub_142078270 = **MD5(MachineGuid 注册表值 + Σ.dlc 文件字节 + 66B 盐 "DontStealMyGamePlz__WINNERS_DONT_USE_DRUGS__DONT_COPY_THAT_FLOPPY")**; 单件校验 sub_14207CC90 (校验和门→商店后端查询, 0=拥有/2=未拥有/3=校验和致命; type 表实际只走 1=steam); 单件校验和 sub_1420774D0 = MD5(name+itoa(len)+path+itoa(steam_id)+itoa(0)+pops_id+deps+replace_paths+"y"/"n"+archive 字节+**19B 盐 "h4rdc0r3Gam3r4lyfe"**); 串行兜底 sub_14207D4B0。

**注册表与 UGC**: `.dlc` 扫描 sub_14207B540 (**两注册表统一键 = descriptor name (+8)** — 76090/B540 插入键均拷自 +8, 插入比较器同; 插入前门按 type 校验 steam_id 低半 +624 / pops_id 串 size +608 / +648 pdx_id 非空, type 0 拒绝 "Incorrect DLC descriptor" :858); 过滤谓词 sub_14207AA60 (types 1/3/5/6/7 查 disabled_dlcs 按 +72 精确匹配, 2/4/8 经 sub_142079430 变换后按 **name +8** 比对 — 两条不同匹配路径, 变换 = '\' 切分 ≥2 段弃再 '/' 切分重组 (推定), type 0 = "Unknown source" 告警返 0); Workshop 安装器 sub_142079E00 (挂载 workshop 目录→找 zip→写 `ugc_<id>.mod` 描述件→按 ugc 键回查); 订阅增量安装 sub_142075200 (mtime < 安装时间才重装)。**CDLCManager 具名** (qword_14344A568 单例, 兼 §4.29.7a 挂载管理器)。**CDLCDescriptor 增补**: +592 pops_id (token 765) / +584 type (ctor 默认 0; 解析后推断仅当原值 0/6: path 非空∧archive 空 → **8** (mod folder) / 反之 → 2) / **+664 = 所有权验证旗** (ctor dword = 0x100 即 byte+665 affects_checksum = 1 而 +664 = 0; **写者 = VerifyAllDLCOwnership sub_14207C2A0** 置 1, 唯一读者 = 挂载收集门 — DLC 只收旗非零者) / +628 = steam_id 高半 (默认 0) / +648 = pdx_id 串 size (默认 0) / +72 registry id (装载器注入非解析键) / +280 = **PHYSFS_getRealDir** 挂载前缀 / **+368 supported_version = CVersionNumber 对象** (80B, token 611 经 sub_142222840 解析, 分量数组 +384/分量数 +396, 有效 = 分量 [2,4], 前缀相等判兼容如 "1.19"≡"1.19.3" — 非 MSVC 串); 764/767 rail_id/msgr_id 负定案。**boot 全链 (定案)**: main → 单例 → PHYSFS_freezeConfig(1) → 装载 ctor ("dlc","mod" 两前缀) → .dlc 扫描尾调 VerifyAllDLCOwnership → .mod 扫描 → dlc_load.json → -exclude_dlc (幂等追加 disabled_dlcs) → 版本不匹配弹窗 ("Unsupported Mods") → 挂载主函数; **feature gate 域 (gamedlc.cpp) 与本簇零调用关系** — 掩码 = 已安装 DLC feature 位, 所有权旗 = 商店后端验证, 两套正交。
