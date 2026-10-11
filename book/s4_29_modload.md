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
| +0 | 第二 DirHandle 链表头 (deinit/单注销与 +8 链同查节点+40 挂载残留; 主链/写目录链语义待裁) |
| +8 | 搜索路径 DirHandle 单链表头指针 |
| +16 | 写目录 DirHandle 句柄 (空 → mkdir/写报错误码 13) |
| +32 | archiver 对象数组 (DirHandle+40 元素同源) |
| +40 | archiver 列表头指针 (openDirectory 扩展名选型循环起点) 四串描述符 {extension, description, author, url} (与上游 PHYSFS_Archiver 前四字段同构) |
| +48 | numArchivers (双数组计数) |
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
| ?PHYSFS_readBytes | 缓冲读循环 | PHYSFS_File {+0 io, +24 buf, +32 bufsize, +40 datalen, +48 bufpos}; zip/7z 头部小读同走此路 补 +8 forReading 旗 (0 → 错误码 15); |
| sub_1424F8A60 | openDirectory (archiver 选型) | 扩展名 utf8stricmp 匹配循环 + 兜底循环 → archiver+48 openArchive; 无命中 → 错误码 6 |
| sub_1424F70D0 | createDirHandle | openDirectory + 填 dirName/mountPoint (尾随 '/') |
| sub_1424F9220 | verifyPath (路径越界/symlink 防线) | 挂点前缀校验 + 逐组件 stat; symlink 拒绝 = +249 旗=0 时 (错误码 12); stat/openRead/enumerate/mkdir/delete 五导出共用 |
| sub_1424F6AE0 | createNativeIo | 'r'/'w'/'a' 三模式 + 80B io 对象 24B 句柄 {io@+0, path 副本@+8, mode@+16}; 原生 Io 80B 10 槽分发表; 'r'/'w'/'a' 三打开原语 = sub_142514720/142514750/142514690 |
| sub_1424F8410 | 枚举桥 (挂点影子条目) | 请求目录是 mountPoint 严格前缀时发射挂载点组件名, filetype 恒 4 (vendored 扩展标记「挂载点影子目录」, 值域外; 消费侧 = 回调 0x1424DAEC0 先 PHYSFS_stat 定真伪再分派, §4.29.1d) |
| sub_1424F2740 / 2610 / 24F0 | memoryIo destroy/dup/read 三件套 | 48B MemoryIoInfo {buf, len, pos, parent, refcount, destruct}; PHYSFS_mountMemory 后端; refcount 原子, 减 0 才 destruct dup/destroy 尾调槽 = vtable+56/+72 (非上游 PHYSFS_Io 标准序, vendored 魔改, 勿按上游序读槽) |
| sub_1424F68F0 / 6440 / 6D90 / 6590 | DirTree init/add/free | 64 哈希桶; add 两函数互递归建中间目录; zip (sub_1425189D0) 与 7z (sub_142512FA0) 条目装载共用 DirTree {+0 root, +8 哈希桶数组, +24 entrylen}; 条目 {+0 name, +8 哈希链, +16 子目录链头, +24 兄弟链, +32 isdir} (entrylen ≥ 40; addMkdir 中间目录恒 isdir=1, add 显式 isdir 参) |
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

#### 4.29.1d SVirtualFile 双后端与 VFS 文件 API (virtualfilesystem_physfs.cpp; 17 函族 + 同 TU 14 vtable 实现定案)

双后端文件句柄 (24B; 由打开工厂按 64B 路径对第二串选择后端):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | 主虚表 (8 槽, 见下表) |
| +8 | uint8 | 写模式旗 (mode≠0 置 1) |
| +16 | 后端句柄 | PHYSFS_File* (PHYSFS 后端) / FILE* (CRT 后端) |

| 后端 | 类 (RTTI) | vtable RVA | COL |
|---|---|---|---|
| PHYSFS | SVirtualFile_PHYSFS | 0x2B92718 | 0x142DEFDB0 |
| CRT | SVirtualFile_STD | 0x2B92760 | 0x142DEFE30 |

vtable 八槽 (两表同序; 包装器对空句柄返 0 并断言 "Invalid file", 唯 Eof 空句柄返 1):

| 槽 | 语义 | PHYSFS | STD |
|---|---|---|---|
| [0] | 析构 (close/fclose + 按 free 旗释放) | 0x1424D9FC0 | 0x1424DA070 |
| [1] | Read(buf, size) → 字节数 | 0x1424DB5B0 | 0x1424DB5D0 |
| [2] | Write(buf, size) → 全写返 size 否则 0 | 0x1424DE790 | 0x1424DE7C0 |
| [3] | Flush → bool | 0x1424DACE0 | 0x1424DAD00 |
| [4] | GetSize → 长度 | 0x1424DAD20 | 0x1424DAD40 |
| [5] | Seek(pos) → bool | 0x1424DB660 | 0x1424DB680 |
| [6] | Tell → 位置 (失败 −1) | 0x1424DB6A0 | 0x1424DB6C0 |
| [7] | Eof → bool | 0x1424DAE80 | 0x1424DAEA0 |

⚠ **Seek 槽极性反转 (定案)**: PHYSFS 版 0x1424DB660 返非零 = 成功; STD 版 0x1424DB680 (fseeki64) 返非零 = 失败 — 同为 `test eax,eax; setne al` 但被调 API 语义相反; 包装器 0x1424DE400 对 origin=SET 直透该返回值, 调用方按成功义消费时 STD 后端下行为反转 (影响面未裁)。

打开工厂 0x1424DD880 (双后端) 按路径对第二串 (+32 物理路径) 长度选后端 — 空 → 0x1424DDBD0 (PHYSFS: openRead / openWrite (前置 sub_1424DBA40 确保目录树) / openAppend); 非空 → CRT (L"rb"/L"wb"/L"ab" + wfopen); mode 契约 0=读 / 1=写 / 2=追加 / 其他 = "Not implemented" (:1247 / :1303)。出参 33B = {+0 错误串 (成功时首 8B 被句柄指针覆盖) / +32 成功旗}; 失败错误串 = PHYSFS 错误码文本 (回落 "unknown") 或 "fopen() failed: " + errno。唯一调用方 = CVirtualFile 构造 0x1424DF480 (virtualfilesystem.cpp TU): 句柄挂 this+8, a5=1 时错误串经 sub_1424E07A0 抛 CFileException。

VFS 文件操作包装族 (空句柄守卫): GetSize 0x1424DD310 (:1426) / Eof 0x1424DD610 (:1501, 空句柄返 1) / Read 0x1424DDF40 (:1364) / Write 0x1424DE700 (:1402) / Seek 0x1424DE400 (:1467, 三 origin)。

重命名 0x1424DDFC0 = PHYSFS_getRealDir 取物理根 → 反斜杠归一正斜杠 + 按 '/' 切组件 → 反向拼 newName 组件得目标物理全路径 → CRT rename; 失败日志 :778 (含 errno)。删除: 文件 0x1424DBFB0 / 递归目录 0x1424DBCC0 (列子目录 + 共享枚举器 + 逐文件删 + 自递归 + 尾删目录本身, 失败日志 :793 / :821)。

列子目录名 0x1424DC020 = 清出向量 (预扩容 ≥1024 槽, 1.5× 增长) → PHYSFS_enumerateFiles 逐条拼 `<dir>/<name>` → PHYSFS_stat, **只收 filetype==1 (目录)** 且名内含 ≥0x80 字节时告警 :899 不入表; filetype≠1 一律不入。枚举回调 0x1424DAEC0 = filetype 1 (目录) 入收集向量 / filetype 4 (挂点影子) 先 PHYSFS_stat 定真伪 (真目录入向量, 常规入树, 符号链接及其他丢弃, stat 失败告警 :94) / filetype 0·2·3 入收集红黑树 (节点 96B = {父/左/右 +24 颜色, +32 键 = 全 VFS 路径, +64 值}) / ≥5 跳过。递归枚举主链 0x1424DA110 = 深度守卫 (maxDepth, :915) → 扫挂载点表求命中记录最小搜索路径索引 → PHYSFS_enumerate → 条目经后缀 (a3) / 子串 (a4) 两级匹配 → getRealDir 取物理源求搜索路径表索引, 大于最小索引即丢弃 (replace_path 过滤, §4.29.5) → 逐子目录自递归; 入口 0x1424DC380 (64B 条目向量, 预扩容 ≥1024)。

vendored PHYSFS_Stat 布局 (填充者 0x1425148B0 = GetFileAttributesExW; 符号链接判定 = 属性含 0x400 且 FindFirstFileW dwReserved0 == 0xA000000C):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | uint64 | 文件长度 (目录 / 符号链接恒 0) |
| +8 | int64 | 最后写入时间 (FILETIME → Unix 秒) |
| +16 | int64 | 创建时间 |
| +24 | int64 | 最后访问时间 |
| +32 | int32 | 文件类型: 0 常规 / 1 目录 / 2 符号链接 / 3 其他 |
| +36 | int32 | 只读旗 (dwFileAttributes & 1) |

⚠ 与上游 PHYSFS_Stat 字段序**不同** (上游 filetype@+0 / filesize@+32) — 本族全部 filetype 判定读 +32, 勿按上游序读; 0x1424DD390 = 取最后写入时间 (stat+8) 非文件长度。

> 未决: 64B 路径对结构类名 (无 RTTI 的 POD); 0x1424DA110 的 a3/a4 过滤极性 (反编译控制流显示不匹配条目仍入表, 与「过滤器」直觉相反, 疑 SEH 状态机花括号错位); 回调 0x1424DAEC0 第五参来源 (寄存器透传, 推定物理源串); STD Seek 极性反转的调用方影响面; 枚举收集器树与向量的最终出表链路; "fopen() failed: " 的 errno 文本链; PHYSFS_FileType 枚举名 (0..3 按上游推得, 无源码直证)。
#### 4.29.1b zip 归档元数据解析链 (physfs_archiver_zip.cpp; 4 函闭环 — 书未收簇)

`clausewitz\pdx_core\physfs\` 第三方静态链入层 (§4.29.1a 只覆盖库本体与封装层, 不涉本簇); openArchive = sub_142515B30 (§4.29.1a 表末行)。归档句柄公共骨架: `a1+32` = seek 虚槽 / `a1+48` = filelength 虚槽 / sub_1424F6D00 = 顺序读 n 字节。三签名常量 (定案):

| 签名 | 值 | 结构 |
|---|---|---|
| 0x06054B50 | 101010256 | EOCD (22B + 注释) |
| 0x06064B50 | 101075792 | zip64 EOCD 记录 (≥56B) |
| 0x07064B50 | 117853008 | zip64 EOCD 定位器 (20B) |

| 函 | 角色 | 骨架要点 |
|---|---|---|
| sub_142518780 (helper) | EOCD 反扫 | 取 filelength; 尾部 256B 窗内自尾向头扫 4B 签名 0x06054B50; 出参 a2[0] = 文件尾偏移; 窗空 → sub_1424F9450(6) 返 −1 |
| sub_142518160 (helper) | zip64 记录定位 | 候选位三探 (a3 传入偏移 / a2−56 / a2−84), 逐处读 4B 比签名 0x06064B50; 命中返该位, 否则线性回扫; wassert "_pos > 0" |
| 0x1425183C0 | zip64 定位器解析 | seek 到 a5 (= EOCD 位 −20) → 签名须 0x07064B50, 否则返 0xFFFFFFFF; `*(a1+40) = 1` (zip64 标志); 读 4B 须 0 (disk number) / 8B = zip64 EOCD 记录偏移 / 4B 须 1 (total disks — 单盘约束) → 定位记录 → 跳 size/ver/disk → entries_on_disk(8) 须 == total_entries(8) (**单盘约束**) → `*a4` = total_entries → `*a3` = CD offset (8); `*a3 += *a2` (相对→绝对); wassert "((PHYSFS_uint64)pos) >= ui64" |
| 0x1425190E0 | 总解析入口 | EOCD 反扫得位 → 签名须 0x06054B50 → 走 0x1425183C0 zip64 路; 返回 ≤1 即定案 (1 = zip64 成功 / 0 = IO 失败); 返 −1 (非 zip64) → 解析 22B 明式 EOCD: disk(2) 须 0 / diskWithCD(2) 须 0 (单盘约束) / entriesOnDisk(2) == totalEntries(2) → `*a4` = totalEntries / `*a3` = offsetOfCD(4); 完整性门 `EOCD 位 ≥ CD size + CD offset`; `*a2` = 数据起始 = EOCD 位 − CD size − CD offset; `*a3 += *a2`; 尾校验 `EOCD 位 + commentLen + 22 == filelength` (注释长度对账, 明式路径独有); 任一门败 → sub_1424F9450(18) 返 0; wassert "rc == -1" |

> 出参契约 (两路径一致): `*a2` = 数据起始绝对偏移 / `*a3` = 中央目录绝对偏移 / `*a4` = 条目总数。IO 失败一律返 0 (静默), 结构不符经 sub_1424F9450 错误通道返 0, 签名不符返 0xFFFFFFFF。字段对应按 PKWARE APPNOTE 结构形状推得 (PHYSFS 源码未含于语料, 无独立佐证, 待裁)。


#### 4.29.1c clausewitzlib ZIP 归档读/写层 (zip.cpp; 15 函闭环 — CZipArchive 自管 POD)

读取器原语 = `(*(*a1)+32)(a1, buf, len)` (vtable+32 = Read); 读 46 字节头后校验签名 `*(dword*)a2 == 0x02014B50` ("PK\x01\x02"), 不符 → :1202 纯日志 (flags=0, 闩 byte_14348138D; B51 域门) + 返 0; 三变长字段: a2+28 u16 文件名长 → malloc(n+1) 挂 **a2+48**; a2+30 u16 扩展长 → **a2+56**; a2+32 u16 注释长 → **a2+64**; 各读后补 null 终止。与 §4.29.1b 的 physfs_archiver_zip.cpp 族为不同 TU (本节 = clausewitzlib 自有 zip.cpp)。**已解 (整族定案)**: a1 = CZipArchive 归档对象本身 (非游标), +96 = 开档结果; 三指针 (+48/+56/+64) 在解析失败时由调用方 0x1422E3590 释放 (含条目本身), 成功时归条目数组随归档对象生命周期。整族 15 函闭环, 见下。
CZipArchive (无独立 RTTI 的 POD; 读/写共用):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | CMemoryFile* | 底层流 (虚表槽契约见下) |
| +8 | uint32 | 位置/偏移: 构造初值 = GetSize(流); 开档后 = EOCD 的中央目录偏移; 写者 = 本地头写入点 (close 时 Seek 目标) |
| +16 | CDirEntry** | 条目指针数组 |
| +24 | uint32 | 数组容量 |
| +28 | uint32 | 数组计数 |
| +32 | CAllocator* | 分配器 (off_143085170 共享静态; +8 allocate / +16 deallocate) |
| +40 | uint8[22] | EOCD 缓冲 (构造置签名 0x06054B50) |
| +48 | uint16 | EOCD 本盘条目数 (写者每条目 ++) |
| +50 | uint16 | EOCD 总条目数 (写者 ++ / 读者 = 循环上界) |
| +52 | uint32 | EOCD 中央目录总大小 (每条目 += 46 + 名长 + 扩展长 + 注释长) |
| +56 | uint32 | EOCD 中央目录偏移 (落盘前 = +8) |
| +60 | uint16 | EOCD 注释长度 (构造置 0; 开档不读真值 → 不支持 zip 注释) |
| +64 | char* | 归档注释缓冲 (恒不分配) |
| +72 | uint8 | 模式旗 (观测调用点恒 0; 非 0 时每条目后自动全量重写中央目录) |
| +73 | uint8 | 自有工作缓冲旗 |
| +80 | uint8* | 工作缓冲 (缺省 malloc 50000000) |
| +88 | uint64 | 工作缓冲大小 (缺省 50000000; 压缩/解压前后半对分为输入/输出区) |
| +96 | uint8 | 开档结果 |

函数身份 (全族非 CPersistent — 自管 POD + 落盘字节序, 不走 token 流序列化):

| VA | 功能身份 |
|---|---|
| 0x1422E2560 | 构造 (挂流 / EOCD 缓冲置签名 / 缺省 50MB 工作缓冲 / 调开档) |
| 0x1422E3590 | 开档: GetSize < 22 → 空档成功; 定位末 22B → 校验签名 → 预扩容条目数组 (max(总条目, 容量×1.5)) → 循环解析挂入 → SeekToEnd 追加就位 |
| 0x1422E3C30 | 中央目录条目头解析 (上文) |
| 0x1422E2790 | 中央目录条目构造并追加 (本地头 30B → 46B 定头 + 偏移, 挂入数组, 累加 EOCD 计数) |
| 0x1422E2970 | 写入一个文件条目 (本地头 + 数据 + 头回填或数据描述符) |
| 0x1422E2D20 | 按名解压单个条目 (查表 → 定位本地头 → 五字段校验 → 方法分派 → CRC 验) |
| 0x1422E3960 | inflate 解压流 (raw deflate) + CRC32 验 |
| 0x1422E32C0 | bzip2 解压流 + CRC32 验 |
| 0x1422E41D0 | deflate 压缩流 (raw) + CRC32 累积 |
| 0x1422E3D90 | bzip2 压缩流 + CRC32 累积 |
| 0x1422E40E0 | 落盘全部中央目录 (逐条目 46B + 名 + 扩展 + 注释) + 22B EOCD |
| 0x1422E44D0 | close: Seek(当前位) → 0x1422E40E0 |
| 0x1422E2760 / 0x1422E2750 | SEH 清理 (本地头文件名/扩展缓冲; 归档注释缓冲) |
| 0x1422E2480 | 序列化辅助 (语料无调用点, 归属按地址推定) |

压缩方法契约: 0 = 存储 / 8 = raw deflate (zlib 版本串 "1.2.3", windowBits −15, memLevel 9; 存档调用点 level 7) / 12 = bzip2 (blockSize100k, workFactor 30); 其他 → :674。CRC-32 = 标准查表 dword_142B49120 (1024 项, 多项式 0xEDB88320 反射), 初值 0xFFFFFFFF 终翻转; 压缩路径按**新消费输入字节**累 CRC, 解压路径对**解压后明文**累 CRC, 收尾比对 ~CRC == 条目+16。不支持 zip64 与 zip 注释。

写入条目链 (0x1422E2970): 本地头 30B (签名 0x04034B50 / 版本需要 = 方法 0→10 · 8→20 · 12→46 / 旗 |= 8 / CRC 占位 0xFFFFFFFF / 未压缩大小 = GetSize(源)) + 文件名 → 方法分派 → 可寻址判定 = Seek 返回非 0: 成功 → 旗清 8 + 回填真 CRC/压缩大小; 不可寻址 → 追加 16B 数据描述符 (签名 0x08074B50) → 0x1422E2790 追加中央目录条目 → +8 前进 (有描述符时 +16)。

按名解压链 (0x1422E2D20): 遍历条目数组 strcmp(entry+48 文件名) → Seek(entry+42 本地头偏移) → 读 30B 本地头验签名 → 跳文件名/扩展 → 五字段校验 (版本 / 旗+方法 / 时间+日期 / 名长 / 扩展长; 无描述符旗时含 CRC 与两大小), 不符 → :750 → 方法分派 → 旗 & 8 时读 16B 描述符: 签名须 0x08074B50 且 CRC/压缩/未压缩须与目录头一致。

CDirEntry 72B 写侧补全: +4 版本制作 = 63 / +6..+30 逐字段从本地头拷 / +12·+14 时间日期恒 0 / +34 盘号 ← 归档+44 / +36·+38 内外属性恒 0 / +42 = 本地头相对偏移 ← 归档+8; 三指针 +48/+56/+64 读时 malloc(长+1) 并 null 终止。

LocalHeader 本地文件头工作结构 (落盘仅 +0..+29): +0 签名 0x04034B50 / +4 版本需要 / +6 通用旗 / +8 压缩方法 / +10·+12 时间日期 (恒 0) / +14 CRC32 / +18 压缩大小 / +22 未压缩大小 / +26 文件名长 / +28 扩展长 (恒 0); 工作态 +32 文件名缓冲 / +40 扩展缓冲 / +48 拥有旗。数据描述符 16B = {+0 签名 0x08074B50 / +4 CRC32 / +8 压缩大小 / +12 未压缩大小}。z_stream (本构建 sizeof = 88, uLong 为 4B, zlib wrapper 硬校验 88): +0 next_in / +8 avail_in / +12 total_in / +16 next_out / +24 avail_out / +28 total_out / +32 msg / +40 state / +48 zalloc / +56 zfree / +64 opaque。

CMemoryFile 虚表槽 (vtable 0x142B934E0; 本族依赖的流层契约): +32 Read (越界返 0) / +64 Write / +80 Seek (越界返 0, 否则置位返 1) / +88 SeekToEnd (位置 = GetSize) / +112 GetSize。

调用方: 存档/配置写入 = 0x140DC7790 / 0x140D9AB00 / 0x141C35570 (方法 8 / level 7 → 0x1422E2970 → 0x1422E44D0); 解压 = 0x141C35250 / 0x140DA3F20 / 0x142079E00 (Workshop 安装器, §4.29.10 附近) → 0x1422E2D20。21 个一次性日志闩 byte_14348137D..byte_143481391 与 zip.cpp 行号 674..1390 单调对应, 为 TU 归属的独立佐证。

> 未决: 0x1422E2970 可寻址判定与 0x1422E3590 中央目录定位的 Seek 第二实参 (寄存器透传, 目标位按上下文推定); 0x1422E2480 归属 (无调用点); +72 自动落盘模式触发条件 (观测恒 0); 追加模式覆写旧中央目录的边界 (新条目少于旧目录长度时尾部残留旧字节, 靠末尾新 EOCD 仍可解析); 解压缓冲半长划分边界; bz_stream 精确布局 (仅确认 +48 state / +64 bzfree / +72 opaque)。
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
> 备注 (高置信): 内容库同目录多文件的**装载序 = 文件名字典序** (ASCII: 数字 < 大写 < 小写) — 证据面 = defines 装载依赖反证 (00_graphics.lua 尾部 `for k,v in pairs(NDefines_Graphics)` 合并语句要求 00_defines.lua 先建 NDefines 外壳, 反序装载则 graphics 组被其后的整体赋值抹除) + 磁盘分层解析与运行时值级对账 0 差异佐证; 共享枚举器 sub_1424DC600 (§4.28.33 ReadContent 族), PHYSFS enumerate 内部稳定排序未逐层直证。后装载文件的同键内容覆盖先装载; 同名文件二选一整文件替换走挂载优先级 (本节判定), 异名文件按本装载序追加合并。

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
| 枚举 | sub_1424DC020 | `PHYSFS_enumerateFiles` + `PHYSFS_stat` **只收 filetype==1 (目录) 名**; 名含 ≥0x80 字节告警 :899 不入表 (filetype 判定读 vendored stat+32, §4.29.1d) |

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

#### 4.29.10 PHYSFS 目录归档 open (physfs_archiver_dir.cpp; 1 函 = sub_142514C60, 定案/错误码待裁)

sub_142514C60 (目录归档 open): 目录存在性/类型判定 sub_1425148B0 (出参 == 1 才继续, 否则 sub_1424F9450(6) 错误码 + 返 0; 错误码 6 按标准 PHYSFS 枚举 = FILES_STILL_OPEN 与语境不契, 疑魔改 fork 枚举改写, 待裁); 成功 → `*a4 = 1` 成功旗出参 + malloc(len+2) 逐字节拷贝目录串 → **末字符 != 0x5C (`\\`) 则追加单字节 `\\`** (强制尾随分隔符); 分配失败 → sub_1424F9450(2) (OOM, 与标准枚举位一致); 返回串 = DirHandle 的 dirName (§4.29 DirHandle 56B 形状 +8 的构造点)。wassert "io == NULL" :0x30 (无闩; IDA 条件反演 `if (a1)` 实为 `!a1`)。

**feature gate** (sub_1401AEB50, gamedlc.cpp:230): feature id → **dword_14332F248 位测试** (未知 id 一次性告警 "Unrecognized DLC feature flag."); boot 掩码构建 sub_1401AEDA0 = 12 名查询置位 + 收尾强制 `|=0x1E` (四个 legacy 扩展恒开); 掩码 setter/getter = sub_1401AED90/0x1401AE6A0 (存档 11546 恢复环 sub_141998D60→sub_1401AED90); 超集判定 sub_1401AED80 `(mask & g) == mask`; 伴生全局 dword_14332F24C = 4608 (语义未定)。位→DLC 名 (代码字面串): 0x1 Poland / 0x20 La Resistance / 0x40 Battle for the Bosporu / 0x80 No Step Back / 0x100 By Blood Alone / 0x400 Arms Against Tyranny / 0x800 Trial of Allegiance / 0x2000 Gotterdammerung / 0x4000 Graveyard of Empires / 0x8000 No Compromise No Surrender / 0x10000 Peace For Our Time / 0x20000 Thunder at Our Gates; 位 0x2/0x4/0x8/0x10 ↔ TFV/DoD/WtT/MtG 四名对应为推定 (恒置无查询串)。431 个消费点 (效果/命令族大量消费, 最热 id 50/57/19/25)。

**DLC 归属校验链**: CDLCManager::VerifyAllDLCOwnership sub_14207C2A0 (tbb 符号直证类名; **dlc_signature 缓存**命中跳过逐项校验, 否则并行校验后回写); 签名 = sub_142078270 = **MD5(MachineGuid 注册表值 + Σ.dlc 文件字节 + 66B 盐 "DontStealMyGamePlz__WINNERS_DONT_USE_DRUGS__DONT_COPY_THAT_FLOPPY")**; 单件校验 sub_14207CC90 (校验和门→商店后端查询, 0=拥有/2=未拥有/3=校验和致命; type 表实际只走 1=steam); 单件校验和 sub_1420774D0 = MD5(name+itoa(len)+path+itoa(steam_id)+itoa(0)+pops_id+deps+replace_paths+"y"/"n"+archive 字节+**19B 盐 "h4rdc0r3Gam3r4lyfe"**); 串行兜底 sub_14207D4B0。

**注册表与 UGC**: `.dlc` 扫描 sub_14207B540 (**两注册表统一键 = descriptor name (+8)** — 76090/B540 插入键均拷自 +8, 插入比较器同; 插入前门按 type 校验 steam_id 低半 +624 / pops_id 串 size +608 / +648 pdx_id 非空, type 0 拒绝 "Incorrect DLC descriptor" :858); 过滤谓词 sub_14207AA60 (types 1/3/5/6/7 查 disabled_dlcs 按 +72 精确匹配, 2/4/8 经 sub_142079430 变换后按 **name +8** 比对 — 两条不同匹配路径, 变换 = '\' 切分 ≥2 段弃再 '/' 切分重组 (推定), type 0 = "Unknown source" 告警返 0); Workshop 安装器 sub_142079E00 (挂载 workshop 目录→找 zip→写 `ugc_<id>.mod` 描述件→按 ugc 键回查); 订阅增量安装 sub_142075200 (mtime < 安装时间才重装)。**CDLCManager 具名** (qword_14344A568 单例, 兼 §4.29.7a 挂载管理器)。**CDLCDescriptor 增补**: +592 pops_id (token 765) / +584 type (ctor 默认 0; 解析后推断仅当原值 0/6: path 非空∧archive 空 → **8** (mod folder) / 反之 → 2) / **+664 = 所有权验证旗** (ctor dword = 0x100 即 byte+665 affects_checksum = 1 而 +664 = 0; **写者 = VerifyAllDLCOwnership sub_14207C2A0** 置 1, 唯一读者 = 挂载收集门 — DLC 只收旗非零者) / +628 = steam_id 高半 (默认 0) / +648 = pdx_id 串 size (默认 0) / +72 registry id (装载器注入非解析键) / +280 = **PHYSFS_getRealDir** 挂载前缀 / **+368 supported_version = CVersionNumber 对象** (80B, token 611 经 sub_142222840 解析, 分量数组 +384/分量数 +396, 有效 = 分量 [2,4], 前缀相等判兼容如 "1.19"≡"1.19.3" — 非 MSVC 串); 764/767 rail_id/msgr_id 负定案。**boot 全链 (定案)**: main → 单例 → PHYSFS_freezeConfig(1) → 装载 ctor ("dlc","mod" 两前缀) → .dlc 扫描尾调 VerifyAllDLCOwnership → .mod 扫描 → dlc_load.json → -exclude_dlc (幂等追加 disabled_dlcs) → 版本不匹配弹窗 ("Unsupported Mods") → 挂载主函数; **feature gate 域 (gamedlc.cpp) 与本簇零调用关系** — 掩码 = 已安装 DLC feature 位, 所有权旗 = 商店后端验证, 两套正交。


**largefile.cpp 联机大文件传输协议 (clausewitzlib 层, 书未收新域)**: 消息三件套 + ctor — **CStartFileTransfer 执行 0x1422E1000** (载荷 {+16 文件名, +40 size, +56 checksum, +44..+51 句柄槽}; 新建/复用 240B 句柄 sub_1422DFD20 → 按名+checksum+size 开档 sub_1422E19F0) / **CSendChunk 执行 0x1422E0E90** ({+40 块数据, +64 chunk 序号, +68 发送句柄}; 有句柄 sub_1422E0520 发出 / 无则 "CSendChunk Execute FAIL" :131) / **CChunkReceived ctor 0x1422DFBE0** (vtable 名直证; {+40 chunk, +44 id, +48 progress 定点 round(a4×1e5)}) / **执行 0x1422E0D00** (管理器缺位断言 "missing large file handle (chunk received)" :199)。管理器单例 = unk_1430B1DF8 (解引用经 sub_14221F310; **槽[10] = 收块/开档契约位**, ctor+apply 同槽互证; 槽[12] 取参), 日志类别码 769。类名 unk_1430B1DF8 挂载链未决。

#### 4.29.11 mod 装载与虚拟文件系统函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x141CDE520 | （未命名）OLD_SAVEGAME_POPUP OLD_SAVEGAME_POPUP，旧存档兼容弹窗 |
| 0x140BD20A0 | （未命名）串 "version_name"/"(selecting latest vers 串 "version_name"/"(selecting latest version)"，存档/模组版本选择逻辑 |

#### 4.29.12 mod 装载与虚拟文件系统函数补遗（12 函）

| VA | 语义/证据 |
|---|---|
| 0x140FFF910 | CCountryOccupationData::Writer — func_names 名 + pdx_robin_hood_table.h:58 断言 func_names 名 + pdx_robin_hood_table.h:58 断言 |
| 0x141922740 | （无名，按上游/loc 定性） 断言 "Expected start of block" |
| 0x14142D5F0 | （无名，按上游/loc 定性） gameitemdatabase.h:142 |
| 0x141921E00 | （无名，按上游/loc 定性） 断言 "Expected start of block" |
| 0x141401DE0 | （无名，按上游/loc 定性） std_pair_parser.h:71 |
| 0x1419640E0 | CAirRegionCombatData::Reader CAirRegionCombatData::Reader + 名字角色规则(CAirRegionCombatData::Reader); vtable/RTTI 含 SAirWingCombatData; 被 CAirRegionCombatData::R… |
| 0x1411A2690 | CCountryOperationManager::Writer 标签:pdx_scopedptr.h:134 |
| 0x1412852D0 | vtable/RTTI 类 SPostEffectVolumeReader sub_1412852D0 + vtable/RTTI 类 SPostEffectVolumeReader; 被 CPdxPostEffectVolumeManager::Reader 等 1 命名函数调用 |
| 0x14144CFC0 | CUnitHistory::Writer 标签:pdx_scopedptr.h:129 |
| 0x140B74390 | SNavalHitMissDataReader::Reader SNavalHitMissDataReader::Reader + 名字角色规则(SNavalHitMissDataReader::Reader); 串 "small"; 被 SNavalHitMissDataReader::Reader 等 1 命… |
| 0x142330790 | vtable/RTTI 类 SForceReader sub_142330790 + vtable/RTTI 类 SForceReader |
| 0x1404986F0 | STraitReader::[2] STraitReader::[2] + 域关键词匹配; 串 "simple statements are not allowed in this "; 被 STraitReader::[2] 等 1 命名函数调用 |

#### 4.29.13 mod 装载与虚拟文件系统函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140AADA20 | 可本地化文本/触发键对写入族 可本地化文本/触发键对写入族；邻 CScriptableLocalization::Writer(-3088B)/STriggerKeyPair::Writer(-2992B)，被调 gamestate.h:1125/1126 |
| 0x1423A1E80 | 字符串转义表（\\\\/\\\\\"/\\n/\\r/\\t 双向转义），邻 CFormat::[0](-1296B)/[2]，疑存档/文本输出转义 |
| 0x1411AC330 | 键值清单格式化 键值清单格式化；串 \":\"/\"<\"/\">\" ×5+\" = <PAYLOAD>\"，被调 lexer.cpp:381，邻 CPoliticalParty::Reader/Writer+CIntelSource::Reader/CStaticIntelSourcePool::Reader |
| 0x1414DA910 | SBookmarkPlaythroughData vtable SBookmarkPlaythroughData vtable §4.29 存档/序列化 |
| 0x1414855F0 | "Tried to write a mod achievement who wa "Tried to write a mod achievement who was not completed" + C §4.29 存档/序列化 |

#### 4.29.14 mod 装载与虚拟文件系统函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x140A6B770 | SNamesPool::Reader SNamesPool 名字池，namedatabase.cpp:56 |
| 0x14140D680 | SInitialScientistSkillLevel::Reader SInitialScientistSkillLevel，scientist_template.cpp:75 |
#### 4.29.16 mod 装载与虚拟文件系统函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x14232FEA0 | SVectorParamReader::Writer — func_names 名 + =/{ /空格/回车 四分量序列化四件套 x4 func_names 名 + =/{ /空格/回车 四分量序列化四件套 x4 |
#### 4.29.18 mod 装载与虚拟文件系统函数补遗（49 函）

| VA | 语义/证据 |
|---|---|
| 0x1420743E0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141800500 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1415541C0 | （无名） 调用图传播: 3 锚点投 §4.29（100%） |
| 0x142515780 | （无名） 调用图传播: 3 锚点投 §4.29（100%） |
| 0x1418F8970 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x140FF2290 | （无名） 调用图传播: 4 锚点投 §4.29（100%） |
| 0x1418007F0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1418F9420 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141552200 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141552450 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142514040 | （无名） 调用图传播: 3 锚点投 §4.29（100%） |
| 0x140FF2060 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141551AF0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x14154F580 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1424F87E0 | （无名） 调用图传播: 3 锚点投 §4.29（67%） |
| 0x140FF1CF0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x14154EE90 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x140228910 | （无名） 调用图传播: 4 锚点投 §4.29（50%） |
| 0x141DAB840 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1415508D0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141550A70 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142073290 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x14068AC50 | （无名） 调用图传播: 4 锚点投 §4.29（100%） |
| 0x141684D40 | （无名） 调用图传播: 2 锚点投 §4.29（50%） |
| 0x140C9FCD0 | （无名） 调用图传播: 7 锚点投 §4.29（57%） |
| 0x140C43DA0 | （无名） 调用图传播: 5 锚点投 §4.29（80%） |
| 0x1422576F0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141DACA60 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1416855B0 | （无名） 调用图传播: 2 锚点投 §4.29（50%） |
| 0x142515390 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142519340 | （无名） 调用图传播: 11 锚点投 §4.29（100%） |
| 0x14225E8A0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1424E2020 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141556750 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141550430 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142256170 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142513D70 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x140FF26E0 | （无名） 调用图传播: 3 锚点投 §4.29（100%） |
| 0x142515120 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1425198E0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141F7DCC0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142079B40 | （无名） 调用图传播: 3 锚点投 §4.29（67%） |
| 0x14061C290 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142078E30 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1424E1A40 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142514690 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x140C49AF0 | （无名） 调用图传播: 4 锚点投 §4.29（100%） |
| 0x141AEA6E0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x142519D50 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |

#### 4.29.19 mod 装载与虚拟文件系统函数补遗（37 函）

| VA | 语义/证据 |
|---|---|
| 0x141B67DC0 | sub_141B67DC0 CArchiveFile::[8] + strategic_region_names（存档写入战略区域名表） |
| 0x141485940 | sub_141485940 成就/游玩统计存取（achievements_mod_storage.cpp） |
| 0x14007A000 | sub_14007A000 堆分配+strcpy 构造路径串（语料字符串抽取失真） |
| 0x141FE4BB0 | sub_141FE4BB0 成就/游玩统计存取（playthrough_stats） |
| 0x140F3F1D0 | 同区段近邻 CBuildingProductionLine::Reader(距 0x2EFF0)属 4.29 族 sub_140F3F1D0 + 同区段近邻 CBuildingProductionLine::Reader(距 0x2EFF0)属 4.29 族 |
| 0x1413FD9F0 | 调用图上游传播(占 100%, 1 票) sub_1413FD9F0 + 调用图上游传播(占 100%, 1 票) |
| 0x141A443F0 | 同区段近邻 NProject::SProjectContext::Reader(距 0xBB50)属 4.29 族 sub_141A443F0 + 同区段近邻 NProject::SProjectContext::Reader(距 0xBB50)属 4.29 族 |
| 0x14054A8A0 | 调用图上游传播(占 54%, 7 票) sub_14054A8A0 + 调用图上游传播(占 54%, 7 票) |
| 0x140BC5980 | 调用图上游传播(占 50%, 3 票) sub_140BC5980 + 调用图上游传播(占 50%, 3 票) |
| 0x14032B900 | 域关键词匹配 sub_14032B900 + 域关键词匹配 |
| 0x1413FE270 | 调用图上游传播(占 100%, 1 票) sub_1413FE270 + 调用图上游传播(占 100%, 1 票) |
| 0x1409C61B0 | 调用图上游传播(占 100%, 1 票) sub_1409C61B0 + 调用图上游传播(占 100%, 1 票) |
| 0x141428320 | 域关键词匹配 sub_141428320 + 域关键词匹配; 源码路径 clausewitz; 被 CPoliticalParty::Writer 等 1 命名函数调用 |
| 0x1402D70F0 | 调用图上游传播(占 67%, 3 票) sub_1402D70F0 + 调用图上游传播(占 67%, 3 票) |
| 0x1413B5560 | 调用图上游传播(占 100%, 1 票) sub_1413B5560 + 调用图上游传播(占 100%, 1 票) |
| 0x1424CD560 | 调用图上游传播(占 78%, 5 票) sub_1424CD560 + 调用图上游传播(占 78%, 5 票) |
| 0x14129A2D0 | 同区段近邻 SPostEffectVolumeReader::Reader(距 0x10A80)属 4.29 族 sub_14129A2D0 + 同区段近邻 SPostEffectVolumeReader::Reader(距 0x10A80)属 4.29 族 |
| 0x140A9A810 | 调用图上游传播(占 42%, 3 票) sub_140A9A810 + 调用图上游传播(占 42%, 3 票) |
| 0x140F3CFA0 | 同区段近邻 CBuildingProductionLine::Reader(距 0x31220)属 4.29 族 sub_140F3CFA0 + 同区段近邻 CBuildingProductionLine::Reader(距 0x31220)属 4.29 族 |
| 0x14227F340 | 调用图上游传播(占 100%, 1 票) sub_14227F340 + 调用图上游传播(占 100%, 1 票) |
| 0x140E9D250 | 调用图上游传播(占 60%, 2 票) sub_140E9D250 + 调用图上游传播(占 60%, 2 票) |
| 0x1424C36C0 | 域关键词匹配 sub_1424C36C0 + 域关键词匹配; 被 CAirBase::Writer 等 6 命名函数调用 |
| 0x1414E6E90 | 域关键词匹配 sub_1414E6E90 + 域关键词匹配 |
| 0x142295B10 | 域关键词匹配 sub_142295B10 + 域关键词匹配 |
| 0x140F67050 | 同区段近邻 CBuildingProductionLine::Reader(距 0x7170)属 4.29 族 sub_140F67050 + 同区段近邻 CBuildingProductionLine::Reader(距 0x7170)属 4.29 族 |
| 0x140AEB7F0 | 调用图上游传播(占 100%, 1 票) sub_140AEB7F0 + 调用图上游传播(占 100%, 1 票) |
| 0x1406C20B0 | 域关键词匹配 sub_1406C20B0 + 域关键词匹配 |
| 0x14128A2C0 | 同区段近邻 SPostEffectVolumeReader::Reader(距 0xA70)属 4.29 族 sub_14128A2C0 + 同区段近邻 SPostEffectVolumeReader::Reader(距 0xA70)属 4.29 族 |
| 0x141622A40 | 调用图上游传播(占 100%, 1 票) sub_141622A40 + 调用图上游传播(占 100%, 1 票) |
| 0x1411A17D0 | 调用图上游传播(占 100%, 1 票) sub_1411A17D0 + 调用图上游传播(占 100%, 1 票) |
| 0x141923570 | 调用图上游传播(占 100%, 1 票) sub_141923570 + 调用图上游传播(占 100%, 1 票) |
| 0x1424CDB60 | 调用图上游传播(占 85%, 6 票) sub_1424CDB60 + 调用图上游传播(占 85%, 6 票) |
| 0x140F8CE60 | 调用图上游传播(占 75%, 2 票) sub_140F8CE60 + 调用图上游传播(占 75%, 2 票) |
| 0x14119D550 | 域关键词匹配 sub_14119D550 + 域关键词匹配 |
| 0x140549C30 | 域关键词匹配 sub_140549C30 + 域关键词匹配 |
| 0x141295020 | 同区段近邻 SPostEffectVolumeReader::Reader(距 0xB7D0)属 4.29 族 sub_141295020 + 同区段近邻 SPostEffectVolumeReader::Reader(距 0xB7D0)属 4.29 族 |
| 0x141A43380 | 同区段近邻 NProject::SProjectContext::Reader(距 0xAAE0)属 4.29 族 sub_141A43380 + 同区段近邻 NProject::SProjectContext::Reader(距 0xAAE0)属 4.29 族 |

#### 4.29.20 mod 装载与虚拟文件系统函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x141295200 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141400910 | （无名） 调用图传播: 2 锚点投 §4.29（50%） |
| 0x140F8E3C0 | （无名） 调用图传播: 2 锚点投 §4.29（50%） |
| 0x1419491C0 | PayloadReader func_names 名 PayloadReader（序列化读写器角色） |
| 0x1413FE350 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141A457B0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |

#### 4.29.21 mod 装载与虚拟文件系统函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x141C4A060 | 业务逻辑（见证据锚） null_object 绑定：null_object.h:133 断言 + 遍历 a1+56/a2 双数组置 qword_14332FB10 空对象指针 |
| 0x140B74170 | SNavalHitMissDataReader 海战命中未中读段 (vtable类名 SNavalHitMissDataReader) vtable引用 SNavalHitMissDataReader vftable |

#### 4.29.22 mod 装载与虚拟文件系统函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x141684B70 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x1415570D0 | （无名） 调用图传播: 4 锚点投 §4.29（100%） |
| 0x141557510 | （无名） 调用图传播: 4 锚点投 §4.29（100%） |
| 0x1418F95F0 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x141DACD00 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x14154DD60 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |
| 0x14154E120 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |

#### 4.29.23 mod 装载与虚拟文件系统函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141685730 | （无名） 调用图传播: 2 锚点投 §4.29（100%） |

#### 4.29.24 mod 装载与虚拟文件系统函数补遗（16 函）

| VA | 语义/证据 |
|---|---|
| 0x1405492D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142514580 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x140BC4BE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142514BA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142514780 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142518920 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x1425144B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142073DF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x141801300 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142513CB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x1402CCA30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x141F7DDC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142514B20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x142514840 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x141684CB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |
| 0x1420757B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.29 |

#### 4.29.25 mod 装载与虚拟文件系统函数补遗（71 函）

| VA | 语义/证据 |
|---|---|
| 0x140ABA1C0 | CScriptedWindowTemplate::SDynamicListInfo::Reader CScriptedWindowTemplate::SDynamicListInfo::Reader（Reader 角色） |
| 0x1422E7280 | CSystemMessage::Reader func_names 全名 CSystemMessage::Reader，Reader/Writer 角色定 §4.29 |
| 0x1410F7790 | CCountryFuelStatus::Reader CCountryFuelStatus::Reader（Reader 角色） |
| 0x140D11D60 | ULexerToken::UEAAXAEAVCReader::CDeploymentStatus::ReadMember::S…::[1] ULexerToken::...CDeploymentStatus::ReadMember（ReadMember 角色） |
| 0x14197CBF0 | CFEXAir::Reader CFEXAir::Reader（Reader 角色） |
| 0x140F84D40 | CAirMission::Reader CAirMission::Reader（Reader 角色） |
| 0x1414E7110 | CCountryPlayerSettings::Reader CCountryPlayerSettings::Reader + CDiplomaticAction::GetFirstCountryRef（国家玩家设置反序列化） |
| 0x14113E360 | CCallAllyAction::Reader / CCallAllyAction::Reader CCallAllyAction::Reader §4.29 存档/序列化 |
| 0x140AAC930 | STriggerKeyPair::Reader STriggerKeyPair |
| 0x141A00670 | CCreateEquipmentVariantScheduler::Reader CCreateEquipmentVariantScheduler |
| 0x14235CD70 | SGfxBlendStateReader::[4] func_names SGfxBlendStateReader::[4]，Reader 类定 §4.29 |
| 0x140E27690 | CNavalUnitTransfer::Reader func_names 全名 CNavalUnitTransfer::Reader，Reader/Writer 角色定 §4.29 |
| 0x140D84140 | CTechnologySharing::Writer / CTechnologySharing::Writer CTechnologySharing::Writer §4.29 存档/序列化 |
| 0x140C66C60 | CStrategicAirManager::Writer / CStrategicAirManager::Writer CStrategicAirManager::Writer §4.29 存档/序列化 |
| 0x1415C4790 | CNavalCombat::Reader CNavalCombat::Reader + CCombat::Reader（战斗/海战反序列化） |
| 0x141517EC0 | CLoopHistoryContainer::Writer / CLoopHistoryContainer::Writer CLoopHistoryContainer::Writer §4.29 存档/序列化 |
| 0x14142CA80 | SSupportCategoryStatMultiplier::Reader func_names SSupportCategoryStatMultiplier::Reader + 串 'Invalid subunit category'，Reader 角色定 §4.29 |
| 0x1409CE510 | SUniformDatabaseReader<…>::[0] SUniformDatabaseReader 槽 0 |
| 0x140A1F060 | SOperatorReader::[0] SOperatorReader 槽 0 |
| 0x1407209E0 | （未命名）L2 被调函数命名证据：CPersistent::Load L2 被调函数命名证据：CPersistent::Load（L2 被调名） |
| 0x14140CF50 | CScientist::Writer |
| 0x140DF9D40 | （无名） VA 邻近 CTreeSeasonType::Reader(±672)（存档/序列化） |
| 0x1415A15A0 | CStateHistory::Reader |
| 0x140AEBA20 | Reader Reader（unitleadertraits.cpp 单位领袖特质表） |
| 0x140A924C0 | SOutput::ReadMember 序列化结构成员读取（SOutput/SInvasionReport/SPrimeStat）（SOutput::ReadMember） |
| 0x141A0F330 | CWeatherTerrainModifier::Reader |
| 0x14235DCD0 | SGfxSamplersScope::Reader SGfxSamplersScope::Reader 图形采样器 |
| 0x1424BF3C0 | 未命名业务函数 序列化类 CWriter（方法角色 Reader/Writer） |
| 0x1419C5B70 | （无名） 被 CTutorialChapter::Reader 调用（存档/序列化） |
| 0x14063C2F0 | （无名） VA 邻近 CRule::Writer(±416)（存档/序列化） |
| 0x1423584A0 | （无名） 被 SGfxShaderFileReader::Reader 调用（存档/序列化） |
| 0x140FCC690 | CCountryLeader::Writer CCountryLeader::Writer（存档/序列化） |
| 0x142309890 | （无名） 被 CPdxMeshType::Reader 调用（存档/序列化） |
| 0x142357710 | （无名） VA 邻近 CFrameAnimatedSpriteType::Reader(±192)（存档/序列化） |
| 0x140AC7030 | CTechnologySharingGroupDatabase::Reader 序列化 Reader/Writer 或网络命令载荷读写（CTechnologySharingGroupDatabase::Reader） |
| 0x1411FEDB0 | CStrategicOperative::Reader 序列化 Reader/Writer 或网络命令载荷读写（CStrategicOperative::Reader） |
| 0x1422E70C0 | CPersonalChatMessage::Reader 名:CPersonalChatMessage::Reader |
| 0x142344CA0 | SParticleSystemReader::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 SParticleSystemReader |
| 0x140C28200 | CArmyLeader::Writer 序列化 Reader/Writer 或网络命令载荷读写（CArmyLeader::Writer） |
| 0x140F04CB0 | CWorldThreat::Reader 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CWorldThreat |
| 0x140D12330 | CDeploymentStatus::Reader 名:CDeploymentStatus::Reader |
| 0x1402CDED0 | （无名） 被 CContinuousNationalFocus::Reader 调用（存档/序列化） |
| 0x141006490 | CNavalRegionDominance::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CNavalRegionDominance |
| 0x1413E41F0 | CCombatant::Writer 名:CCombatant::Writer |
| 0x140F22F50 | SWeatherPerRegion::Writer 名:SWeatherPerRegion::Writer |
| 0x141376FF0 | CPositionOverride::Reader 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CPositionOverride |
| 0x140F20640 | SWeatherPerRegion::Reader func_names 全名 + 序列化角色 |
| 0x1410F0490 | CCountryCharacters::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CCountryCharacters |
| 0x14101F3E0 | SCriticalPart::Reader func_names 全名 + 序列化角色 |
| 0x1413F5C90 | CCountryCollaborationStatus::Writer func_names 全名 + 序列化角色 |
| 0x141964210 | SAirWingCombatData::Reader 名:SAirWingCombatData::Reader |
| 0x1412A8B70 | CCountryExperienceStatus::Reader func_names 全名 + 序列化角色 |
| 0x141510290 | CArmyReinforcementRequests::Writer 名:CArmyReinforcementRequests::Writer |
| 0x140EB36A0 | CStrategicOperativeManager::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CStrategicOperativeManager |
| 0x14234AA80 | SMusicReader::Reader SMusicReader::Reader + 名字角色规则(SMusicReader::Reader); 被 SMusicReader::Reader 等 1 命名函数调用 |
| 0x14144D130 | CUnitMedalStore::Writer func_names 全名 + 序列化角色 |
| 0x141964700 | SAirWingCombatData::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 SAirWingCombatData |
| 0x1406AC220 | Reader func_names 裸名 + 序列化角色（Reader） |
| 0x14151F640 | CLiberateCountryAction::Reader CLiberateCountryAction::Reader + 名字角色规则(CLiberateCountryAction::Reader); 被调源码 hoi4; 被 CLiberateCountryAction::Reader 等 1 命名函数调用 |
| 0x1406127C0 | CDynamicModifierContainer::SDynamicModifierEntry::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CDynamicModifierContainer |
| 0x1423507C0 | SEntityAttachmentGroupReader::Reader SEntityAttachmentGroupReader::Reader + 名字角色规则(SEntityAttachmentGroupReader::Reader); 被 SEntityAttachmentGroupReader::Rea… |
| 0x140ADCE40 | CTimedWargoalActivity::Writer func_names 全名 + 序列化角色 |
| 0x14163E520 | CSetGameRuleOption::PayloadReader CSetGameRuleOption::PayloadReader + 名字角色规则(CSetGameRuleOption::PayloadReader); 被调源码 clausewitz; 被 CSetGameRuleOption::Paylo… |
| 0x140BBC970 | CHuman::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CHuman |
| 0x14193EB10 | CHqDeploymentDistributable::Reader func_names 全名 + 序列化角色 |
| 0x141289850 | SPostEffectVolumeReader::Reader SPostEffectVolumeReader::Reader + 名字角色规则(SPostEffectVolumeReader::Reader); 被 SPostEffectVolumeReader::Reader 等 1 命名函数调用 |
| 0x141B1F1F0 | CTaskForceIdentity::Writer 序列化 Reader/Writer（方法角色 Reader/Writer）；类属 CTaskForceIdentity |
| 0x1418512E0 | COrderReplaceRootCommands::PayloadReader func_names 全名 + 序列化角色 |
| 0x140EB2070 | SSparseArrayWriter<…>::[1] SSparseArrayWriter<…>::[1] + 域关键词匹配; 被 SSparseArrayWriter<…>::[1] 等 1 命名函数调用 |
| 0x1415105B0 | CReinforcementRequest::Writer CReinforcementRequest::Writer + 名字角色规则(CReinforcementRequest::Writer); 被 CReinforcementRequest::Writer 等 1 命名函数调用 |
| 0x14070ABF0 | CCountryColors::Reader CCountryColors::Reader + 名字角色规则(CCountryColors::Reader); 被 CCountryColors::Reader 等 1 命名函数调用 |

#### 4.29.26 mod 装载与虚拟文件系统函数补遗（59 函）

| VA | 语义/证据 |
|---|---|
| 0x141DB9FF0 | sub_141DB9FF0 业务 robin_hood 迭代断言 _pEntry->_DistancePlus1 + gamestate 访问门 + off_143085170，Writer 族同形 |
| 0x140C64EE0 | （无名） 业务 gamestate.h:1125 门控 + pdx_scoped_buffer.h:54 + 通用序列化调用 |
| 0x14164A300 | （无名） 业务 pdx_scoped_buffer.h:54 断言 + 调 sub_14229B020（0x14229 资产序列化区段）：序列化缓冲写入 |
| 0x1423B5440 | （无名） 业务 pdx_scoped_buffer.h:54 + 0x1423B3-BF 序列化族调用 |
| 0x14118EFE0 | SPersist::Write 业务 func_names 名 SPersist::Write；robin_hood 断言 + 通用 Writer 调用 |
| 0x14139DF20 | （无名） 业务 pdx_scopedptr.h:134 + 调 CSteamCloudFile::[13] + 0x14139E8A0：Steam 云存档写入 |
| 0x14167E990 | gamestate.h:1116 业务 gamestate 访问（h:1116 双断言）+ pdx_scoped_buffer 写界断言 → CGameState 相关序列化 writer |
| 0x140F42BD0 | （无名） 业务 gamestate.h:1125 门控 + pdx_scoped_buffer.h:54 + 通用序列化调用 |
| 0x140CB9360 | CResourceOrigin::Reader 业务 func_names 名 CResourceOrigin::Reader + 调 CConvoyClient::Reader + gamestate.h:1125 门控 |
| 0x140E21900 | （无名） 业务 gameitemdatabase.h:142 + pdx_scoped_buffer.h:54 + CPdxLinearAllocator::[1] 调用 |
| 0x14144B4B0 | CUnitHistory::Reader 业务 Reader 角色（单位历史序列化读取器） |
| 0x140EE16F0 | CTechnology::Reader 业务 func_names 名 |
| 0x141B85660 | gamestate.h:1125 业务 gamestate 序列化 writer：自递归 + pdx_scoped_buffer.cpp:10/h:54 写入 + gamestate 槽调用，无类名 |
| 0x1422415D0 | SAnimationMapData::Reader 业务 func_names 名 SAnimationMapData::Reader；串 "scrolling"/"rotating_cw"/"pulsing"/"overlay" |
| 0x14103C330 | gamestate.h:1125 业务 gamestate 序列化 writer：h:1125 双断言 + pdx_scoped_buffer 写界断言 |
| 0x141B8F250 | 业务 夹于 PayloadReader(d=2912) 与 TListenerTrait<CProductionStatus>::[1](d=6016)，生产状态 payload 序列化族 |
| 0x141BAF660 | — 业务 邻域 NFactions::CUseFactionMemberManpower::PayloadWriter + CUpdateIntelligenceAdvisorSlotCommand::PayloadWriter = 命令负载序列化区段 |
| 0x141DEA620 | sub_141DEA620 业务 strcpy 构建 "save"/"game_name" 路径段，存档目录布局组装 |
| 0x1419EE6A0 | 业务 夹于 _Func_impl_no_alloc(d=20160) 与 CPeaceBiddingTurn::Reader(d=25552)，和会叫价回合族 |
| 0x141BAFC60 | 业务 夹于 NFactions::CUseFactionMemberManpower::PayloadWriter(d=2832) 与 CProfileBadgeItem::Setup?(d=30032)，派系人力/档案徽章条目族 |
| 0x140552C50 | — 业务 调用 RobinHood Grow 克隆 sub_14055ECF0（容器扩容），0x14055 区段 |
| 0x1414DD6B0 | 业务 夹于 CPendingTransportUnit::[4](d=28640) 与 CPersistedBookmarkPlaythroughDb::[3](d=2032)，待运输单位/持久化书签档案族 |
| 0x1424D74F0 | CChecksum::SetupVersionObject? 业务 CChecksum::SetupVersionObject + PdxParallelFor(YAXHHW4EJobType) 并行校验和构造版本对象 |
| 0x14152B030 | 业务 gamestate.h:1125，夹于 NDoctrines::SDoctrineEquipmentBonusHandle::Writer(d=4336) 与 CMissionStatsReadHelper::[0](d=4992)，学说装备奖励/任务统计族 |
| 0x140A96760 | 业务 夹于 SUniformReader<>::[2](d=2448) 与 NRaids::CEquipmentRequirements::[0](d=20912)，均匀读取器/突袭装备需求族（同尺寸 4644 克隆簇） |
| 0x1411A1110 | CCountryOperationManager::Reader 业务 func_names 名 CCountryOperationManager::Reader（国家行动管理器序列化读器） |
| 0x140554B70 | 业务 夹于 CPersistent::Reader(d=10208) 与 CDynamicModifier::[0](d=9872)，无业务串，持久化/动态修正族 |
| 0x140D9E0E0 | — 业务 strcpy(".hoi4") 扩展名匹配 + sub_1424CBA10 串比较，存档文件过滤回调 |
| 0x1401F9F30 | 业务 夹于 CAutotestSettings::Reader(d=4608) 与 CAutotestSettings::[0](d=1488)，自动测试设置族 |
| 0x140DEED70 | 业务 pdx_parser.h:2222 站点 "Expected opening brace" + 调 CDiplomaticAction::GetFirstCountryRef，token id（10373/10385/16024）分派至 a2+8/+16/+24，pdx 解析回调 |
| 0x142317D20 | 业务 串字面量 "refresh_internet" §4.29 mod装载/VFS |
| 0x1406AAB40 | 业务 调 CDiplomaticAction::GetFirstCountryRef，夹于 NCareerProfile::SProfileData::Writer(d=848) 与 TGameItemDatabase<CMedalDatabase>::[1]，生涯档案/勋章数据库族 |
| 0x1411B0AC0 | 业务 pdx_parser.h:2222 站点 "Expected opening brace" + 调 CDiplomaticAction::GetFirstCountryRef，紧邻 std::_Func_impl/boyer_moore_finder，pdx 解析回调 |
| 0x140A95DD0 | SUniformReader<…>::[2] 业务 SUniformReader<>::[2] 均匀读取器模板实例（Expected 特征），数值读取 |
| 0x140ADC440 | CTimedStageCoupActivity::Reader 业务 CTimedStageCoupActivity::Reader，政变阶段活动反序列化（gamestate.h:1125） |
| 0x14063BE80 | SOverrideSerializer::Reader 业务 SOverrideSerializer::Reader，rule override 反序列化（rule.cpp:428） |
| 0x140DF0170 | 业务 pdx_parser.h:2222 站点 "Expected opening brace" + 调 CDiplomaticAction::GetFirstCountryRef，紧邻 _Func_impl/NInternationalMarket::CEquipmentConvoyClient::[0]，pd… |
| 0x141BB6AE0 | 业务 gamestate.h:1125，夹于 NFactions::CUseFactionMemberManpower::PayloadWriter(d=31120) 与 CProfileBadgeItem::Setup?(d=1744)，派系人力/档案徽章族 |
| 0x140556CF0 | — 业务 CPdxHybridInlineBufferAllocator + CFixedPoint 类名（定点数序列化缓冲区） |
| 0x141219E80 | — 业务 CPdxHybridInlineBufferAllocator + CCountryTag 类名（国家标签序列化缓冲区） |
| 0x14006C000 | — 业务 CPdxHybridInlineBufferAllocator + CString 类名（字符串序列化缓冲区） |
| 0x14142C340 | — 业务 邻域 SSubUnitStats::Reader / SSupportCategoryStatMultiplier::Reader（0x14142CA50/80）= 属性 Reader 区段 |
| 0x1414FA2B0 | 业务 pdx_parser.h:2222 站点 "Expected opening brace" + 调 CDiplomaticAction::GetFirstCountryRef，紧邻 VCString::equal_to/_Func_impl 与 CCountryReportsManager::[0]，pdx… |
| 0x1406108F0 | CDynamicModifierContainer::SDynamicModifierEntry::Reader 业务 CDynamicModifierContainer::SDynamicModifierEntry::Reader（"Could not find dynamic modifier"） |
| 0x14117F400 | 业务 夹于 CWarScoreBreakdown::Writer(d=17296) 与 CEvent::[0](d=840)，战争分数拆分/事件族 |
| 0x1419760B0 | CFEXMember::Writer 业务 CFEXMember::Writer FEX 成员序列化 writer |
| 0x140EE5C10 | CTechnologySharingGroup::Reader 业务 CTechnologySharingGroup::Reader，科技共享组反序列化（"Invalid template id:"） |
| 0x141980820 | 业务 Init_thread 静态初始化，夹于 CSubunitBonusPersistent::Writer(d=3600) 与 CAirBaseAccessRelation::[0](d=2368)，子单位奖励/空军基地通行关系族 |
| 0x1402DC910 | CNationalFocusProgress::Writer 业务 CNationalFocusProgress::Writer，国策进度序列化（nationalfocus.cpp:1755 "Originator.IsValid()"） |
| 0x1423D49C0 | 业务 紧邻 CCloudFile::[0](d=31984)，云存档文件族 |
| 0x141295E60 | (无名) 业务 调用窗口内命名函数 sub_14207D230 |
| 0x141F8E540 | sub_141F8E540 业务 序列化类型名（strcpy 串 disabled_track） |
| 0x14142D240 | SSubUnitStats::Writer 业务 SSubUnitStats::Writer，子单位统计序列化（pdx_core 序列化辅助族） |
| 0x141434750 | 业务 串 "icon"; 串 "flag"; 调用图 IDF top §4.1 frac 1.00 |
| 0x1424FC2F0 | 业务 类路由 SParticleTextureReader ->§4.29; 调用图 IDF top §4.1 frac 1.00 |
| 0x141DE84C0 | sub_141DE84C0 业务 序列化类型名（strcpy 串 dark_overlay） |
| 0x1421D96D0 | 业务 断言站点 pdx_ugc_steam.cpp:23 ->§4.29; 类路由 CEditBox ->§4.30; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x1414C00C0 | 业务 断言站点 virtualfilesystem.cpp:70 ->§4.29; 类路由 CGameSetupRandomCountryWindow ->§4.30; 串 "IsValid()" |
| 0x1421D8E00 | 业务 断言站点 virtualfilesystem.cpp:6 ->§4.29; 类路由 CSmoothListboxItem ->§4.31; 串 "IsValid()" |


#### 4.29.27 mod 装载与虚拟文件系统函数补遗（8 函）

| VA | 语义/证据 |
|---|---|
| 0x1424D8B50 | 业务 "Could not open manifest file: "/"Did not find any directory info in the -dirs file!"/"sub_directories"/"file_extension" + CArchiveFile::[2] |
| 0x14067C8E0 | 业务 串字面量 'invalid dlc name: ' [4.29×1] |
| 0x141A43BC0 | 业务 反向调用图 1/2 调用者投 §4.29 |
| 0x14109AC00 | 业务 反向调用图 1/2 调用者投 §4.29 |
| 0x1402C1B60 | 业务 断言源码路径 json.h → §4.29 |
| 0x1401FA3D0 | 业务 反调用图传播 1.0 权重锚点投 §4.29（top 占比 1.00） |
| 0x1424DE7F0 | 业务 反调用图传播 1.0 权重锚点投 §4.29（top 占比 1.00） |
| 0x1424D9D00 | 业务 反调用图传播 1.0 权重锚点投 §4.29（top 占比 1.00） |

#### 4.29.28 单调用转发桩结构定案（8 函）

| VA | 语义/证据 |
|---|---|
| 0x1409C8F80 | 转发桩: 转发至 调用图上游传播(占 100%, 1 票) sub_1409C61B0 + 调用图上游传播(占 100%, 1 票)（推定） |
| 0x141F8E6C0 | 转发桩: 转发至 sub_141F8E540 业务 序列化类型名（strcpy 串 disabled_track）（推定） |
| 0x1424C4E70 | 转发桩: 转发至 调用图上游传播(占 78%, 5 票) sub_1424CD560 + 调用图上游传播(占 78%, 5 票)（推定） |
| 0x141B31840 | 转发桩: 转发至 同区段近邻 SPostEffectVolumeReader::Reader(距 0x10A80)属 4.29 族 sub_14129A2D0 + 同区段近邻 SPostEffectVolumeReader::Reader(距 0x10A80)属 4.29 族（推定） |
| 0x141B31860 | 转发桩: 转发至 同区段近邻 SPostEffectVolumeReader::Reader(距 0x10A80)属 4.29 族 sub_14129A2D0 + 同区段近邻 SPostEffectVolumeReader::Reader(距 0x10A80)属 4.29 族（推定） |
| 0x1425FF6A0 | 转发桩: 转发至 调用图上游传播(占 42%, 3 票) sub_140A9A810 + 调用图上游传播(占 42%, 3 票)（推定） |
| 0x1426EE760 | 转发桩: 转发至 （无名） 被 CPdxMeshType::Reader 调用（存档/序列化）（推定） |
| 0x1426F19E0 | 转发桩: 转发至 （无名） 被 CPdxMeshType::Reader 调用（存档/序列化）（推定） |

#### 4.29.29 mod 装载与虚拟文件系统函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x1411CC290 | caller 1411CC440(pdx_parser.h:2222) |
| 0x1406104F0 | func_names slot 契约名 Reader（序列化槽） |
| 0x140BBCEC0 | 路径锚 source\id_generator\id_counter_store.cpp |
| 0x141404EC0 | 调用图传播: 3 个命名调用者（2 游戏类，如 CCountryOperationTokenManager::ReadMember）；多数投 §4.29 |
| 0x14145BE90 | 游戏 CU 簇内: CCicBank::Writer / CScientistLevel::Reader |
| 0x1415AFC20 | 游戏 CU 邻近: CPdxHybridInlineBufferAllocator<H::$0BI: / CNavyTheaterGroup::[0] |

#### 4.29.30 mod 装载与虚拟文件系统函数补遗（327 函）

| VA | 语义/证据 |
|---|---|
| 0x140F4D8A0 | 业务 串 "\n- Roots["/"\n- Fallbacks[" x5（资产/VFS 回退链转储） |
| 0x140014740 | vftable CEffectEntry<CAddTimedUnitLeaderTraitEffect>; 描述串 "add a timed trait to unit leader" |
| 0x1400148C0 | vftable CEffectEntry<CClearCharacterFlagEffect>; 描述串 "clear character flag" |
| 0x140014980 | vftable CEffectEntry<CDemoteLeaderEffect>; 描述串 "Demotes field marshal to general" |
| 0x140014B60 | vftable CEffectEntry<CPromoteLeaderEffect>; 描述串 "promotes general to field marshal" |
| 0x140014D40 | vftable CEffectEntry<CReplaceUnitLeaderTraitEffect>; 描述串 "add trait to unit leader" |
| 0x140014E00 | vftable CEffectEntry<CSetCharacterFlagEffect>; 描述串 "set character flag" |
| 0x140016540 | vftable CEffectEntry<CAddBuildingConstructionEffect>; 描述串 "Starts building construction for amount of levels in specified state o" |
| 0x1400165A0 | vftable CEffectEntry<CAddClaimByEffect>; 描述串 "Add state claim by country." |
| 0x140016660 | vftable CEffectEntry<CAddCoreOfEffect>; 描述串 "Add state as core of country" |
| 0x1400166C0 | vftable CEffectEntry<CAddExtraSharedBuildingSlotsEffect>; 描述串 "add extra shared building slot to state" |
| 0x140016960 | vftable CEffectEntry<CClearStateFlagEffect>; 描述串 "clear state flag" |
| 0x140016CC0 | vftable CEffectEntry<CRemoveClaimByEffect>; 描述串 "Removes state claim by country." |
| 0x140016D20 | vftable CEffectEntry<CRemoveCoreOfEffect>; 描述串 "Removes state as core of country" |
| 0x140016F00 | vftable CEffectEntry<CSetBorderWarEffect>; 描述串 "starts a border war in a state with neighbouring state that also has b" |
| 0x140017020 | vftable CEffectEntry<CAddDemilitarizedZone>; 描述串 "sets the demilitarized status for currently scoped state" |
| 0x140017200 | vftable CEffectEntry<CSetStateFlagEffect>; 描述串 "set state flag" |
| 0x140017500 | vftable CEffectEntry<CAddDoctrineCostReduction>; 描述串 "adds a limited use cost reduction for doctrines" |
| 0x1400175C0 | vftable CEffectEntry<CAddTechBonusEffect>; 描述串 "adds a limited use tech bonus" |
| 0x140017680 | vftable CEffectEntry<CInheritTechnologyEffect>; 描述串 "Copies over technology state from target" |
| 0x1400177A0 | vftable CEffectEntry<CSelectTechTreeIconOrigin>; 描述串 "Override tech tree to use other countries icons" |
| 0x140017800 | vftable CEffectEntry<CSetResearchSlotsEffect>; 描述串 "Sets the number of research slots" |
| 0x140017980 | vftable CEffectEntry<CActivateDecisionEffect>; 描述串 "Activates specified decision for scope country" |
| 0x140017B60 | vftable CEffectEntry<CAddAceEffect>; 描述串 "adds an air ace" |
| 0x140017C20 | vftable CEffectEntry<CAddAIStrategyEffect>; 描述串 "Adds strategy entry to country AI" |
| 0x140017E00 | vftable CEffectEntry<CAddCommandPowerEffect>; 描述串 "add command power to country" |
| 0x140018160 | vftable CEffectEntry<AddFuelEffect>; 描述串 "add fuel to the country" |
| 0x1400182E0 | vftable CEffectEntry<CManpowerAddEffect>; 描述串 "Adds manpower to the country in scope or locally on a state if in stat" |
| 0x1400183A0 | vftable CEffectEntry<CAddNamedThreatEffect>; 描述串 "Adds country threat" |
| 0x1400184C0 | vftable CEffectEntry<CAddNukeEffect>; 描述串 "add nukes to country" |
| 0x1400185E0 | vftable CEffectEntry<CAddPoliticalPowerEffect>; 描述串 "add political power to country" |
| 0x1400186A0 | vftable CEffectEntry<CAddRegionEfficiency>; 描述串 "add efficiency factor to strategic region for from country" |
| 0x140018940 | vftable CEffectEntry<CAddStateClaimEffect>; 描述串 "add claim on state" |
| 0x1400189A0 | vftable CEffectEntry<CAddStateCoreEffect>; 描述串 "add core on state" |
| 0x140018A00 | vftable CEffectEntry<CAddThreatEffect>; 描述串 "Adds country threat" |
| 0x140018E80 | vftable CEffectEntry<CAddAirExperienceEffect>; 描述串 "add air experience for country" |
| 0x140018F40 | vftable CEffectEntry<CAddArmyExperienceEffect>; 描述串 "add army experience for country" |
| 0x1400190C0 | vftable CEffectEntry<CCancelBorderWar>; 描述串 "cancel border war between two states" |
| 0x140019180 | vftable CEffectEntry<CChangeTagEffect>; 描述串 "Changes player to other country" |
| 0x140019360 | vftable CEffectEntry<CClearGlobalEventTargetEffect>; 描述串 "clear a global event target" |
| 0x1400193C0 | vftable CEffectEntry<CClearGlobalEventTargetsEffect>; 描述串 "clear all global event targets" |
| 0x140019540 | vftable CEffectEntry<CClearCountryFlagEffect>; 描述串 "clear country flag" |
| 0x1400195A0 | vftable CEffectEntry<CClearGlobalFlagEffect>; 描述串 "clear global flag" |
| 0x140019600 | vftable CEffectEntry<CCompleteNationalFocusEffect>; 描述串 "completes a focus for a country" |
| 0x140019780 | vftable CEffectEntry<CLegacyCreateCorpsCommanderEffect>; 描述串 "create corps commander for country" |
| 0x140019900 | vftable CEffectEntry<CLegacyCreateFieldMarshalEffect>; 描述串 "create field marshal for country" |
| 0x140019960 | vftable CEffectEntry<CCreateImportEffect>; 描述串 "Creates trade between two countries" |
| 0x140019A20 | vftable CEffectEntry<CLegacyCreateNavyLeaderEffect>; 描述串 "create navy leader for country" |
| 0x140019C00 | vftable CEffectEntry<CCreateWargoalEffect>; 描述串 "creates wargoal for country in scope" |
| 0x140019D80 | vftable CEffectEntry<CDeclareWarEffect>; 描述串 "declares war on specified country" |
| 0x14001A0E0 | vftable CEffectEntry<CAddDivisionTemplateEffect>; 描述串 "add a division template to country" |
| 0x14001A200 | vftable CEffectEntry<CEndPuppetEffect>; 描述串 "Stops specefied country being a puppet of current country" |
| 0x14001ADA0 | vftable CEffectEntry<CGiveGuaranteeEffect>; 描述串 "guarantees specified country" |
| 0x14001AE00 | vftable CEffectEntry<CGiveMilitaryAccessEffect>; 描述串 "gives military access to the specified country" |
| 0x14001AF20 | vftable CEffectEntry<CGoToProvinceEffect>; 描述串 "Goes to stated province." |
| 0x14001AF80 | vftable CEffectEntry<CGoToStateEffect>; 描述串 "Goes to stated state." |
| 0x14001B040 | vftable CEffectEntry<CHoldElectionEffect>; 描述串 "Immediately holds an election in the target country" |
| 0x14001B520 | vftable CEffectEntry<CAddNavyExperienceEffect>; 描述串 "add naval experience for country" |
| 0x14001B5E0 | vftable CEffectEntry<CPlaySongEffect>; 描述串 "Plays song from database" |
| 0x14001BDC0 | vftable CEffectEntry<CRandomSubjectCountryEffect>; 描述串 "Executes child effects on random subject country that fulfills the lim" |
| 0x14001BEE0 | vftable CEffectEntry<CRandomizeVariableEffect<CVariableResolver>>; 描述串 "refer to randomize_temp_variable" |
| 0x14001BF40 | vftable CEffectEntry<CRandomizeWeatherEffect>; 描述串 "Randomize weather effect" |
| 0x14001C120 | vftable CEffectEntry<CReleaseNationEffect<0>>; 描述串 "releases specified country as a puppet using your owned states" |
| 0x14001C1E0 | vftable CEffectEntry<CReleaseNationEffect<1>>; 描述串 "releases specified country as a puppet using your owned or controlled " |
| 0x14001C240 | vftable CEffectEntry<CReleasePuppetEffect<0>>; 描述串 "releases specified country as puppet using states you own" |
| 0x14001C2A0 | vftable CEffectEntry<CReleasePuppetEffect<1>>; 描述串 "releases specified country as puppet using states you own or control" |
| 0x14001C6C0 | vftable CEffectEntry<CRemoveIdeasWithTraitEffect>; 描述串 "Remove all ideas with specified trait from country" |
| 0x14001C7E0 | vftable CEffectEntry<CRemoveOpinionModifierEffect>; 描述串 "Remove opinion modifier from target" |
| 0x14001C9C0 | vftable CEffectEntry<CRemoveStateClaimEffect>; 描述串 "remove claim on state" |
| 0x14001CA20 | vftable CEffectEntry<CRemoveStateCoreEffect>; 描述串 "remove core on state" |
| 0x14001CC00 | vftable CEffectEntry<CResetProvinceEffect>; 描述串 "reset name of a province back to localization one." |
| 0x14001CF60 | vftable CEffectEntry<CSaveEventTargetAsEffect>; 描述串 "save an event target" |
| 0x14001CFC0 | vftable CEffectEntry<CSaveGlobalEventTargetAsEffect>; 描述串 "save a global event target" |
| 0x14001D0E0 | vftable CEffectEntry<CEmbargoEffect>; 描述串 "embargos specified tag" |
| 0x14001D200 | vftable CEffectEntry<CSetBorderWarCombatData>; 描述串 "update border war properties" |
| 0x14001D440 | vftable CEffectEntry<CSetCountryFlagEffect>; 描述串 "set country flag" |
| 0x14001D4A0 | vftable CEffectEntry<CSetCountryLeaderIdeologyEffect>; 描述串 "change the ideology of active leader" |
| 0x14001D800 | vftable CEffectEntry<CSetFuelEffect>; 描述串 "set fuel for country" |
| 0x14001D8C0 | vftable CEffectEntry<CSetGlobalFlagEffect>; 描述串 "set global flag" |
| 0x14001DC20 | vftable CEffectEntry<CSetPartyNameEffect>; 描述串 "change partyname for an ideology in a country" |
| 0x14001DD40 | vftable CEffectEntry<CSetPoliticalPowerEffect>; 描述串 "set political power for country" |
| 0x14001DE60 | vftable CEffectEntry<CSetProvinceControllerEffect>; 描述串 "set controller for province" |
| 0x14001DF20 | vftable CEffectEntry<CSetRelationRuleEffect>; 描述串 "DEPRECATED: See add_relation_rule_override" |
| 0x14001E040 | vftable CEffectEntry<CSetStateControllerEffect>; 描述串 "set controller for state" |
| 0x14001E0A0 | vftable CEffectEntry<CSetStateOwnerEffect>; 描述串 "set owner for state" |
| 0x14001E2E0 | vftable CEffectEntry<CShowIdeasTooltipEffect>; 描述串 "show what idea does" |
| 0x14001E3A0 | vftable CEffectEntry<CSoundEffect>; 描述串 "Plays sound effect" |
| 0x14001E7C0 | vftable CEffectEntry<CTransferStateEffect>; 描述串 "set owner and controller for state" |
| 0x14001E940 | vftable CEffectEntry<CUnlockDecisionCategoryTooltipEffect>; 描述串 "localizes name of category and displays tooltip that shows it will be " |
| 0x14001EA00 | vftable CEffectEntry<CUnlockNationalFocusEffect>; 描述串 "unlocks a focus for a country" |
| 0x14001EE40 | vftable CTriggerEntry<CAIIrrationalityTrigger>; 描述串 "check the ai irrationality value" |
| 0x14001EEA0 | vftable CTriggerEntry<CAILiberateDesireTrigger>; 描述串 "check what liberation desire the country has towards a specified count" |
| 0x14001EF00 | vftable CTriggerEntry<CAIWantsDivisionsTrigger>; 描述串 "Will compare towards the amount of divisions an ai wants to have." |
| 0x14001F440 | vftable CTriggerEntry<CAlwaysTrigger>; 描述串 "always returns specified value" |
| 0x14001F620 | vftable CTriggerEntry<CAnyClaimTrigger>; 描述串 "check if there is a claim between a country and all others" |
| 0x14001F680 | vftable CTriggerEntry<CAnyCountryTrigger>; 描述串 "check if any country meets the trigger" |
| 0x14001FCE0 | vftable CTriggerEntry<CCanResearchTrigger>; 描述串 "check if country can research technology" |
| 0x14001FD40 | vftable CTriggerEntry<CCanSelectTrait>; 描述串 "check if leader can select a trait" |
| 0x14001FDA0 | vftable CTriggerEntry<CCasualtiesTrigger>; 描述串 "Check the amount of casualties a country has suffered in all of it's w" |
| 0x14001FF20 | vftable CTriggerEntry<CCivilwarTargetTrigger>; 描述串 "civilwar target is ( for civil wars checks )" |
| 0x14001FF80 | vftable CTriggerEntry<CClampVariableTrigger>; 描述串 "clamps a temp variable between two values/variables" |
| 0x140020280 | vftable CTriggerEntry<CControlsProvinceTrigger>; 描述串 "check controller for province" |
| 0x1400202E0 | vftable CTriggerEntry<CControlsStateTrigger>; 描述串 "check controller for state(s)" |
| 0x1400204C0 | vftable CTriggerEntry<CCountryExistsTrigger>; 描述串 "check if the specified country exist" |
| 0x140020520 | vftable CTriggerEntry<CCurrentConscriptionAmountTrigger>; 描述串 "Checks the current conscription amount of the country.\n" |
| 0x140020580 | vftable CTriggerEntry<CIsDateTrigger>; 描述串 "checks for a specific date" |
| 0x140020BE0 | vftable CTriggerEntry<CForeignManpowerTrigger>; 描述串 "check the amount of foreign garrison manpower we have" |
| 0x140020C40 | vftable CTriggerEntry<CHasFuelRatioTrigger>; 描述串 "Compares the fuel ratio to a variable.\nExample: fuel_ratio > 0.5" |
| 0x140020CA0 | vftable CTriggerEntry<CGameRulesAllowAchievements>; 描述串 "Returns true if all of the active game rule options allow achievements" |
| 0x140020D00 | vftable CTriggerEntry<CGarrisonManpowerNeedTrigger>; 描述串 "check the amount of manpower needed by garrisons" |
| 0x140020D60 | vftable CTriggerEntry<CGivesMilitaryAccessToTrigger>; 描述串 "check if country gives military access to specified country" |
| 0x140020F40 | vftable CTriggerEntry<CHasAnnexWarGoal>; 描述串 "Checks a country has annex war goal on another country" |
| 0x140020FA0 | vftable CTriggerEntry<CHasAnyCustomDifficultyTrigger>; 描述串 "Returns true if the game has any custom difficulty on" |
| 0x140021000 | vftable CTriggerEntry<CHasAnyLicenseTrigger>; 描述串 "Country has any active licenses\nExample: has_any_license = yes" |
| 0x140021120 | vftable CTriggerEntry<CHasArmySizeTrigger>; 描述串 "checks for amount of divisions, additionally of a specified type" |
| 0x140021360 | vftable CTriggerEntry<CHasBorderWar>; 描述串 "Checks if a there is any border wars for country/state" |
| 0x1400213C0 | vftable CTriggerEntry<CHasBorderWarBetween>; 描述串 "Checks if a there is a border war between two states" |
| 0x140021420 | vftable CTriggerEntry<CHasBorderWarWith>; 描述串 "Checks if a there is a border against a state/country" |
| 0x1400214E0 | vftable CTriggerEntry<CHasCapitulatedTrigger>; 描述串 "checks if the country has capitulated" |
| 0x140021660 | vftable CTriggerEntry<CHasCivilWarTrigger>; 描述串 "check if participant in civil war as revolter or target" |
| 0x140021780 | vftable CTriggerEntry<CHasCompletedNationalFocusTrigger>; 描述串 "has country completed focus" |
| 0x140021A20 | vftable CTriggerEntry<CHasCountryLeaderIdeologyTrigger>; 描述串 "Checks the Ideology of the active country leader" |
| 0x140021B40 | vftable CTriggerEntry<CDamagedBuildingsTrigger>; 描述串 "check for damaged buildings of nation" |
| 0x140021BA0 | vftable CTriggerEntry<CHasDecisionTrigger>; 描述串 "check if country has active selected decision" |
| 0x140021C00 | vftable CTriggerEntry<CHasDefensiveWarTrigger>; 描述串 "is country at defensive war" |
| 0x140021C60 | vftable CTriggerEntry<CHasDefensiveWarWithTrigger>; 描述串 "One country has defensive war against other country." |
| 0x140021CC0 | vftable CTriggerEntry<CHasDeployedAirForceSizeTrigger>; 描述串 "checks for amount of aircrafts, additionally of a specified type" |
| 0x140021D20 | vftable CTriggerEntry<CHasDesignBasedOnTrigger>; 描述串 "check if country has a buildable non-obsolete design based on an arche" |
| 0x140021D80 | vftable CTriggerEntry<CHasDLCTrigger>; 描述串 "Checks if player has a DLC.\nExample: has_dlc = \"name of the dlc\"" |
| 0x140021EA0 | vftable CTriggerEntry<CHasElectionsTrigger>; 描述串 "Checks the country's politics on allowing elections. has_elections = y" |
| 0x140021F00 | vftable CTriggerEntry<CHasEquipmentTrigger>; 描述串 "checks for amount of equipment stored" |
| 0x140022020 | vftable CTriggerEntry<CHasFocusTreeTrigger>; 描述串 "Does current country have the specified focus tree." |
| 0x140022080 | vftable CTriggerEntry<CHasFuelTrigger>; 描述串 "check amount of fuel\nexample:\nhas_fuel > 500" |
| 0x1400220E0 | vftable CTriggerEntry<CFullControlsStateTrigger>; 描述串 "check controller for state(s)" |
| 0x140022200 | vftable CTriggerEntry<CHasGovernmentTrigger>; 描述串 "does country government (ruling party) belong to ideology group" |
| 0x140022260 | vftable CTriggerEntry<CHasGuaranteedTrigger>; 描述串 "check if country has guaranteed specified country" |
| 0x1400222C0 | vftable CTriggerEntry<CHasIdeaTrigger>; 描述串 "check if country has idea" |
| 0x140022320 | vftable CTriggerEntry<CHasIdeaWithTraitTrigger>; 描述串 "check if country has idea with specified trait" |
| 0x140022380 | vftable CTriggerEntry<CHasCreateIntelligenceAgencyTrigger>; 描述串 "has country created an Intelligence Agency" |
| 0x1400223E0 | vftable CTriggerEntry<CHasLegitimacyTrigger>; 描述串 "Check scope country legitimacy 0-100: Example has_legitimacy < 60" |
| 0x1400224A0 | vftable CTriggerEntry<CHasManpowerTrigger>; 描述串 "check amount of manpower" |
| 0x140022560 | vftable CTriggerEntry<CHasMilitaryAccessToTrigger>; 描述串 "check country has military access to specified country" |
| 0x1400227A0 | vftable CTriggerEntry<CHasNonAggressionPactWith>; 描述串 "Check if country has non aggression pact with the specified country" |
| 0x140022860 | vftable CTriggerEntry<CHasOffensiveWarTrigger>; 描述串 "is country at offensive war" |
| 0x1400228C0 | vftable CTriggerEntry<CHasOffensiveWarWithTrigger>; 描述串 "One country has offensive war against other country." |
| 0x140022920 | vftable CTriggerEntry<CHasOffensiveWarWithoutFriendTrigger>; 描述串 "is country at offensive war without specific ally present" |
| 0x1400229E0 | vftable CTriggerEntry<CHasOpinionTrigger>; 描述串 "check what opinion the country has towards a specified country" |
| 0x140022A40 | vftable CTriggerEntry<CHasOpinionModifierTrigger>; 描述串 "check if a country has the opinion modifier" |
| 0x140022AA0 | vftable CTriggerEntry<CHasPoliticalPowerTrigger>; 描述串 "check amount of political power" |
| 0x140022DA0 | vftable CTriggerEntry<CHasRuleTrigger>; 描述串 "Checks if a rule set for a country.\nExample: has_rule = can_puppet" |
| 0x140022E60 | vftable CTriggerEntry<CHasStabilityTrigger>; 描述串 "check value of stability 0-1: Example has_stability < 0.6" |
| 0x140022EC0 | vftable CTriggerEntry<CHasStartDateTrigger>; 描述串 "Compare the initial start date of current game." |
| 0x140022F20 | vftable CTriggerEntry<CHasSubjectTrigger>; 描述串 "Checks if the country has for subject the given country" |
| 0x140022F80 | vftable CTriggerEntry<CHasTechTrigger>; 描述串 "check if country has technology" |
| 0x140023040 | vftable CTriggerEntry<CHasTemplateTrigger>; 描述串 "Check if country has a division template of specific name" |
| 0x140023220 | vftable CTriggerEntry<CHasTraitTrigger>; 描述串 "check if sides leader has trait" |
| 0x1400232E0 | vftable CTriggerEntry<CHasVariable>; 描述串 "Checks if a variable exists in a scope" |
| 0x1400233A0 | vftable CTriggerEntry<CHasWarTrigger>; 描述串 "is country at war" |
| 0x140023400 | vftable CTriggerEntry<CHasWarSupportTrigger>; 描述串 "check value of war_support 0-1: Example has_war_support < 0.6" |
| 0x140023460 | vftable CTriggerEntry<CHasWarTogetherTrigger>; 描述串 "Are the countries fighting on the same side of a war" |
| 0x1400234C0 | vftable CTriggerEntry<CHasWarWithTrigger>; 描述串 "is countries at war" |
| 0x140023520 | vftable CTriggerEntry<CHasWarWithMajorTrigger>; 描述串 "is country at war with a major" |
| 0x1400237C0 | vftable CTriggerEntry<CIsAITrigger>; 描述串 "Checks if country is AI controlled." |
| 0x140023880 | vftable CTriggerEntry<CIsBorderWar>; 描述串 "Checks if a the combatant or leader has a border war" |
| 0x1400238E0 | vftable CTriggerEntry<CIsCryptologyDepartmentActive>; 描述串 "has country an active cryptology department" |
| 0x140023940 | vftable CTriggerEntry<CIsDebugTrigger>; 描述串 "returns true if game is in debug mode (launched with -debug argument)" |
| 0x1400239A0 | vftable CTriggerEntry<CIsDecryptingTrigger>; 描述串 "checks if is currently decrypting a cipher. Example is_decrypting = GE" |
| 0x140023A00 | vftable CTriggerEntry<CIsDynamicCountryTrigger>; 描述串 "returns true if the country is a dynamic country (tag is D01-D50)" |
| 0x140023A60 | vftable CTriggerEntry<CIsEmbargoedByTrigger>; 描述串 "check if embargoed by specified country" |
| 0x140023AC0 | vftable CTriggerEntry<CIsEmbargoingTrigger>; 描述串 "check if country is embargoing specified country" |
| 0x140023B20 | vftable CTriggerEntry<CIsHostingGovernmentInExileTrigger>; 描述串 "Checks if scope country is hosting an exile. is_exile_host = yes" |
| 0x140023BE0 | vftable CTriggerEntry<CIsFactionLeaderTrigger>; 描述串 "check if country leads a faction" |
| 0x140023C40 | vftable CTriggerEntry<CIsFullyDecryptedTrigger>; 描述串 "checks if fully decrypted a cipher. Example is_fully_decrypted = GER" |
| 0x140023D00 | vftable CTriggerEntry<CIsGuaranteedByTrigger>; 描述串 "check if guaranteed by specified country" |
| 0x140023D60 | vftable CTriggerEntry<CIsHistoricalFocus>; 描述串 "check if the historical focus is active" |
| 0x140023E80 | vftable CTriggerEntry<CIsInFactionTrigger>; 描述串 "check if member of any faction" |
| 0x140023EE0 | vftable CTriggerEntry<CIsInFactionWithTrigger>; 描述串 "check if member of same faction as specified country" |
| 0x140023F40 | vftable CTriggerEntry<CIsInPeaceConferenceTrigger>; 描述串 "Checks if the country is currently in a peaceconference" |
| 0x140024000 | vftable CTriggerEntry<CIsIronmanTrigger>; 描述串 "Check if current game is ironman." |
| 0x1400240C0 | vftable CTriggerEntry<CIsLeadingVolunteerGroup>; 描述串 "is_leading_volunteer_group = FRA" |
| 0x140024120 | vftable CTriggerEntry<CIsLeadingVolunteerGroupWithOriginalCountry>; 描述串 "is_leading_volunteer_group_with_original_country = FRA" |
| 0x140024180 | vftable CTriggerEntry<CIsLendLeasingTrigger>; 描述串 "is lend-leasing country" |
| 0x1400242A0 | vftable CTriggerEntry<CIsMajorTrigger>; 描述串 "check if country is a major" |
| 0x140024300 | vftable CTriggerEntry<CIsNeighborOfTrigger>; 描述串 "check if neighbor ( controlled territory ) with specified country" |
| 0x140024360 | vftable CTriggerEntry<CIsOperationTypeTrigger>; 描述串 "checks the type of operation" |
| 0x1400243C0 | vftable CTriggerEntry<CIsOwnerNeighborOfTrigger>; 描述串 "check if neighbor ( owned territory ) with specified country" |
| 0x140024480 | vftable CTriggerEntry<CIsPuppetTrigger>; 描述串 "Checks if the country is puppet of any other country" |
| 0x1400244E0 | vftable CTriggerEntry<CIsPuppetOfTrigger>; 描述串 "Checks if the country is puppet of specified country" |
| 0x140024600 | vftable CTriggerEntry<CIsSpyMasterTrigger>; 描述串 "check if country is Spy Master" |
| 0x1400246C0 | vftable CTriggerEntry<CIsSubjectTrigger>; 描述串 "Checks if the country is subject of any other country" |
| 0x140024720 | vftable CTriggerEntry<CIsSubjectOfTrigger>; 描述串 "Checks if the country is subject of specified country" |
| 0x1400247E0 | vftable CTriggerEntry<CIsTutorial>; 描述串 "check if the tutorial is active" |
| 0x140024840 | vftable CTriggerEntry<CLandDoctrineLevelTrigger>; 描述串 "checks researched land doctrine level" |
| 0x140024900 | vftable CTriggerEntry<CWarLengthTrigger>; 描述串 "Check number of months the country has been at war" |
| 0x140024E40 | vftable CTriggerEntry<COccupiedStatesTrigger>; 描述串 "check the number of states occupied by nation" |
| 0x140024EA0 | vftable CTriggerEntry<CNumOfAvailableCivilianFactoriesTrigger>; 描述串 "check amount of available civilian factories" |
| 0x140024F00 | vftable CTriggerEntry<CNumOfAvailableMilitaryFactoriesTrigger>; 描述串 "check amount of available military factories" |
| 0x140024F60 | vftable CTriggerEntry<CNumOfAvailableNavalFactoriesTrigger>; 描述串 "check amount of available naval factories" |
| 0x140024FC0 | vftable CTriggerEntry<CNumOfCivilianFactoriesTrigger>; 描述串 "check amount of civilian factories" |
| 0x1400250E0 | vftable CTriggerEntry<CNumOfControlledStatesTrigger>; 描述串 "check amount of controlled stats" |
| 0x1400251A0 | vftable CTriggerEntry<CNumOfMilitaryFactoriesTrigger>; 描述串 "check amount of military factories" |
| 0x140025200 | vftable CTriggerEntry<CNumOfNavalFactoriesTrigger>; 描述串 "check amount of naval factories" |
| 0x140025260 | vftable CTriggerEntry<CNumOfNukesTrigger>; 描述串 "check amount of nukes" |
| 0x1400252C0 | vftable CTriggerEntry<CNumOfOperativesTrigger>; 描述串 "Checks the number of operatives the country controls" |
| 0x140025380 | vftable CTriggerEntry<CNumOfSupplyNodesTrigger>; 描述串 "check amount of supply nodes" |
| 0x1400254A0 | vftable CTriggerEntry<CNumResearchedTechnologies>; 描述串 "Number of researched technologies" |
| 0x140025500 | vftable CTriggerEntry<CCountSubjectsTrigger>; 描述串 "check the number of subjects of nation" |
| 0x140025560 | vftable CTriggerEntry<CCountTechnologySharingGroupsTrigger>; 描述串 "checks how many groups a nation is a member of" |
| 0x1400255C0 | vftable CTriggerEntry<COriginalResearchSlotsTrigger>; 描述串 "check number of research slots at start of game" |
| 0x140025620 | vftable CTriggerEntry<COriginalTagTrigger>; 描述串 "original tag is ( for civil wars checks )" |
| 0x140025680 | vftable CTriggerEntry<COwnsStateTrigger>; 描述串 "check owner for state(s)" |
| 0x140025980 | vftable CTriggerEntry<CRoundTempVariableTrigger>; 描述串 "Rounds a temporary variable\nExample: round_temp_variable = num_dogs" |
| 0x140025AA0 | vftable CTriggerEntry<CShipsInAreaTrigger>; 描述串 "checks for amount of ships in specified area" |
| 0x140025C80 | vftable CTriggerEntry<CSurrenderProgressTrigger>; 描述串 "check if a country is close to surrendering" |
| 0x140025CE0 | vftable CTriggerEntry<CTagTrigger>; 描述串 "country tag trigger" |
| 0x140025D40 | vftable CTriggerEntry<CTargetConscriptionAmountTrigger>; 描述串 "Checks the target conscription amount of the country.\n" |
| 0x140025DA0 | vftable CTriggerEntry<CThreatTrigger>; 描述串 "check the global threat value (world tension). 0-1 value" |
| 0x140025E60 | vftable CTriggerEntry<NCareerProfile::CCheckMedal>; 描述串 "Checks if the required medal is achieved and collected" |
| 0x140025F20 | vftable CTriggerEntry<NCareerProfile::CCheckPlaythroughValue>; 描述串 "Compares a playthrough value to a number" |
| 0x140025F80 | vftable CTriggerEntry<NCareerProfile::CCheckPoints>; 描述串 "Compares a career points value to a number" |
| 0x140026040 | vftable CTriggerEntry<NCareerProfile::CCheckRibbon>; 描述串 "Checks if the required ribbon is achieved and collected" |
| 0x1400260A0 | vftable CTriggerEntry<NCareerProfile::CCheckValue>; 描述串 "Compares a career profile value to a number" |
| 0x140026100 | vftable CTriggerEntry<NCareerProfile::CHasPlayerFlag>; 描述串 "Checks if the flag is set for the local player" |
| 0x140026220 | vftable CTriggerEntry<NCareerProfile::CNumOfPointsTrigger>; 描述串 "check amount of gained career points" |
| 0x140026400 | vftable CTriggerEntry<CHasAirLedger>; 描述串 "has_air_ledger = yes/no - Checks if the current character has an air l" |
| 0x140026520 | vftable CTriggerEntry<CHasIDTrigger>; 描述串 "check unit leader has specified ID. Don't localize this. Tooltip only " |
| 0x1400266A0 | vftable CTriggerEntry<CHasNavyLedger>; 描述串 "has_navy_ledger = yes/no - Checks if the current character has a navy " |
| 0x140026760 | vftable CTriggerEntry<CIsAdvisor>; 描述串 "is_advisor = yes/no - Checks if the current character is an advisor" |
| 0x1400267C0 | vftable CTriggerEntry<CIsAirChief>; 描述串 "_is_air_chief = yes/no - Checks if the character in scope is hired as " |
| 0x140026820 | vftable CTriggerEntry<CIsArmyChief>; 描述串 "is_army_chief = yes/no - Checks if the character in scope is hired as " |
| 0x140026880 | vftable CTriggerEntry<CIsArmyLeader>; 描述串 "is_army_leader = yes/no - Checks if the current character is a army le" |
| 0x140026940 | vftable CTriggerEntry<CIsCharacterTrigger>; 描述串 "Checks whether the character in scope matches the character in input" |
| 0x1400269A0 | vftable CTriggerEntry<CIsCharacterSlot>; 描述串 "alias of has_advisor_role" |
| 0x140026A00 | vftable CTriggerEntry<CIsCorpsCommander>; 描述串 "is_corps_commander = yes/no - Checks if the current character is a cor" |
| 0x140026AC0 | vftable CTriggerEntry<CIsExileLeader>; 描述串 "Checks if scope leader is from an exiled government. is_exiled_leader " |
| 0x140026B80 | vftable CTriggerEntry<CIsFemaleTrigger>; 描述串 "checks if scoped unit leader, ace or country is female" |
| 0x140026BE0 | vftable CTriggerEntry<CIsFieldMarshal>; 描述串 "is_field_marshal = yes/no - Checks if the current unit leader is a fie" |
| 0x140026EE0 | vftable CTriggerEntry<CIsNavyChief>; 描述串 "_is_navy_chief_ = yes/no - Checks if the character in scope is hired a" |
| 0x140026F40 | vftable CTriggerEntry<CIsNavyLeader>; 描述串 "is_navy_leader = yes/no - Checks if the current character is a navy le" |
| 0x140026FA0 | vftable CTriggerEntry<CIsOperative>; 描述串 "is_operative = yes/no - Checks if the current character is an operativ" |
| 0x140027000 | vftable CTriggerEntry<CIsOperativeCapturedTrigger>; 描述串 "Checks whether the operative has the matching captured status\n" |
| 0x140027120 | vftable CTriggerEntry<CIsTheorist>; 描述串 "is_theorist = yes/no - Checks if the character in scope is hired as a " |
| 0x140027180 | vftable CTriggerEntry<CIsUnitLeader>; 描述串 "is_unit_leader = yes/no - Checks if the current character is a unit le" |
| 0x140027240 | vftable CTriggerEntry<CCommandingAmountUnitsTrigger>; 描述串 "Check number of units commanded by the unit leader \n num_units > 2" |
| 0x140027E40 | vftable CTriggerEntry<NInternationalMarket::CBuyerTrigger>; 描述串 "Check the buyer country. Example: buyer = GER" |
| 0x140027FC0 | vftable CTriggerEntry<NInternationalMarket::CSellerTrigger>; 描述串 "Check the seller country. Example: seller = GER" |
| 0x1400280E0 | vftable CTriggerEntry<CArmyHasBattalionInTemplateTrigger>; 描述串 "checks if division template has the subunit type." |
| 0x140028140 | vftable CTriggerEntry<CArmyHasTemplateTrigger>; 描述串 "checks if division template has majority of subunit type." |
| 0x140028200 | vftable CTriggerEntry<CIsUnitReservesTrigger>; 描述串 "returns true if this unit's template has the reserves priority" |
| 0x1400282C0 | vftable CTriggerEntry<CHasUnitStrengthTrigger>; 描述串 "Check scope unit strength status 0-1: Example unit_strength < 1" |
| 0x140028500 | vftable CEffectEntry<CDestroyUnitEffect>; 描述串 "destroy currently scoped unit" |
| 0x140028A60 | vftable CTriggerEntry<CAllStateTrigger>; 描述串 "check if all states meets the trigger. tooltip=key can be defined to o" |
| 0x140028D60 | vftable CTriggerEntry<CAnyStateTrigger>; 描述串 "check if any state meets the trigger. tooltip=key can be defined to ov" |
| 0x140028E80 | vftable CTriggerEntry<CStrategicRegionIDTrigger>; 描述串 "check state's strategic area id" |
| 0x140029060 | vftable CTriggerEntry<CDistanceToTrigger>; 描述串 "check distance between two states" |
| 0x140029120 | vftable CTriggerEntry<CHasActiveResistance>; 描述串 "returns true if state has an active resistance (above zero)" |
| 0x140029180 | vftable CTriggerEntry<CHasResistance>; 描述串 "returns true if state has a resistance" |
| 0x1400291E0 | vftable CTriggerEntry<CHasStateCategoryTrigger>; 描述串 "Check if state has a specific state category" |
| 0x1400292A0 | vftable CTriggerEntry<CIsImpassableTrigger>; 描述串 "checks if a state is impassable" |
| 0x140029300 | vftable CTriggerEntry<CHasBorderConflictTrigger>; 描述串 "checks if a state is in border conflict" |
| 0x140029360 | vftable CTriggerEntry<CIsCapitalTrigger>; 描述串 "Is scope state a capital. 169 = { is_capital = yes }" |
| 0x1400293C0 | vftable CTriggerEntry<CIsClaimedByTrigger>; 描述串 "Checks if state is claimed by country" |
| 0x140029420 | vftable CTriggerEntry<CIsCoastalTrigger>; 描述串 "check if state is coastal" |
| 0x140029480 | vftable CTriggerEntry<CIsControlledByTrigger>; 描述串 "check if state is controlled by" |
| 0x1400294E0 | vftable CTriggerEntry<CIsCoreOfTrigger>; 描述串 "Checks if state is core of country" |
| 0x140029540 | vftable CTriggerEntry<CIsDemilitarizedTrigger>; 描述串 "checks if a state is a demilitarized zone" |
| 0x1400295A0 | vftable CTriggerEntry<CIsFullyControlledByTrigger>; 描述串 "Checks if state is fully controlled by specified tag" |
| 0x140029600 | vftable CTriggerEntry<CIsInHomeArea>; 描述串 "Checks if the first province in the state is connected to the capital " |
| 0x1400296C0 | vftable CTriggerEntry<CIsOnContinentTrigger>; 描述串 "is state located on continent" |
| 0x140029780 | vftable CTriggerEntry<CIsOwnedAndControlledByTrigger>; 描述串 "check if state is owned by" |
| 0x1400297E0 | vftable CTriggerEntry<CIsOwnedByTrigger>; 描述串 "check if state is owned by" |
| 0x140029A80 | vftable CTriggerEntry<COwnsAnyStateOfTrigger>; 描述串 "Check if the country owns any of the states in the list." |
| 0x140029AE0 | vftable CTriggerEntry<CStrategicRegionIDTrigger>; 描述串 "check state's strategic area id" |
| 0x140029C60 | vftable CTriggerEntry<CStateIDTrigger>; 描述串 "check state id" |
| 0x140029CC0 | vftable CTriggerEntry<CStateAndTerrainStrategicValueTrigger>; 描述串 "Checks for state strategic value" |
| 0x140029D20 | vftable CTriggerEntry<CStatePopulationTrigger>; 描述串 "check the population in the state" |
| 0x140029DE0 | vftable CTriggerEntry<CStateStrategicValueTrigger>; 描述串 "Checks for state strategic value" |
| 0x140029E40 | vftable CTriggerEntry<CArmorTrigger>; 描述串 "Check that average armor level of combatant is over a certain level" |
| 0x140029EA0 | vftable CTriggerEntry<CDiginTrigger>; 描述串 "check if we have digin level (lowest)" |
| 0x140029F00 | vftable CTriggerEntry<CFastestTrigger>; 描述串 "check if fastest unit of combatant is over this limit" |
| 0x140029F60 | vftable CTriggerEntry<CFrontageFullTrigger>; 描述串 "check if sides front is full or can get more reinforcements" |
| 0x140029FC0 | vftable CTriggerEntry<CHardnessTrigger>; 描述串 "check lowest/highest hardness level on combatant" |
| 0x14002A0E0 | vftable CTriggerEntry<CHasCarrierAirWingsOnMissionTrigger>; 描述串 "check if side has a career with air wings on a mission" |
| 0x14002A1A0 | vftable CTriggerEntry<CHasCombatModifierTrigger>; 描述串 "check if combatant has modifier" |
| 0x14002A200 | vftable CTriggerEntry<CHasFlankedOpponentTrigger>; 描述串 "check if side has flanked their opponent" |
| 0x14002A260 | vftable CTriggerEntry<CHasMaxPlanningTrigger>; 描述串 "check if side has maximal planning bonus" |
| 0x14002A2C0 | vftable CTriggerEntry<CHasReservesTrigger>; 描述串 "check if side has reserves waiting" |
| 0x14002A380 | vftable CTriggerEntry<CIsAmphibiousInvasionTrigger>; 描述串 "check if combat is at night" |
| 0x14002A3E0 | vftable CTriggerEntry<CIsAttackerTrigger>; 描述串 "check if attacker side in combat" |
| 0x14002A440 | vftable CTriggerEntry<CIsDefenderTrigger>; 描述串 "check if defender side in combat" |
| 0x14002A4A0 | vftable CTriggerEntry<CIsFightingAirUnitsTrigger>; 描述串 "check if side is fighting air units" |
| 0x14002A560 | vftable CTriggerEntry<CIsFightingInTerrainTrigger>; 描述串 "check what terrain is in combat" |
| 0x14002A620 | vftable CTriggerEntry<CIsWinningTrigger>; 描述串 "check if defender side in combat" |
| 0x14002A680 | vftable CTriggerEntry<CLessCombatWidthThanOpponentTrigger>; 描述串 "check if side has more combat width than their opponent" |
| 0x14002A6E0 | vftable CTriggerEntry<CMinPlanningTrigger>; 描述串 "check if side has maximal planning bonus" |
| 0x14002A740 | vftable CTriggerEntry<CNightTrigger>; 描述串 "check if combat is at night" |
| 0x14002A7A0 | vftable CTriggerEntry<CCombatPhaseTrigger>; 描述串 "check if we are in this combat phase" |
| 0x14002A860 | vftable CTriggerEntry<CReconAdvantageTrigger>; 描述串 "checks if side has an advantage in recon level" |
| 0x14002A8C0 | vftable CTriggerEntry<CReservesTrigger>; 描述串 "check amount of reserves" |
| 0x14002A920 | vftable CTriggerEntry<CSkillTrigger>; 描述串 "compare leader skill levels" |
| 0x14002A980 | vftable CTriggerEntry<CSkillAdvantageTrigger>; 描述串 "compare leader skill levels" |
| 0x14002A9E0 | vftable CTriggerEntry<CTemperatureTrigger>; 描述串 "check combat province temperature" |
| 0x14002BC50 | vftable CTriggerEntry<CPcCurrentTurnTrigger>; 描述串 "Checks turn number in PC.\nExample:\npc_turn > 20" |
| 0x14002BD70 | vftable CEffectEntry<`anonymous namespace'::CAddOffsiteBuildingEffect>; 描述串 "Add an offsite building to a country" |
| 0x14002C010 | vftable CEffectEntry<NProject::`anonymous namespace'::CClearProjectFlagEffect>; 描述串 "clear project flag" |
| 0x14002C370 | vftable CEffectEntry<NProject::`anonymous namespace'::CSetProjectFlagEffect>; 描述串 "set project flag" |
| 0x14002C5B0 | vftable CEffectEntry<CSendEquipmentEffect>; 描述串 "Sends to target scope specified amount of equipment." |
| 0x14002C670 | vftable CEffectEntry<CSetEquipmentFraction>; 描述串 "Modify all equipments by factor" |
| 0x14002CF10 | vftable CTriggerEntry<CNumNukesBeingDropped>; 描述串 "total number of nukes that are currently ready to be dropped" |
| 0x14002D4B0 | vftable CEffectEntry<CAddToFactionEffect>; 描述串 "adds specified country to faction" |
| 0x14002D5D0 | vftable CEffectEntry<CDismantleFactionEffect>; 描述串 "dismantle faction led by the current country" |
| 0x14002D690 | vftable CEffectEntry<CLeaveFactionEffect>; 描述串 "Country leaves the faction" |
| 0x14002D750 | vftable CEffectEntry<CRemoveFromFactionEffect>; 描述串 "removes specified country from faction" |
| 0x14002D7B0 | vftable CEffectEntry<CSetFactionLeaderEffect>; 描述串 "set current country as leader of its faction" |
| 0x14002DA50 | vftable CEffectEntry<CSetFactionSpyMasterEffect>; 描述串 "set current country as spy master of its faction" |
| 0x14002F6A0 | vftable CTriggerEntry<CAndTrigger>; 描述串 "all inside trigger must be true" |
| 0x14002F700 | vftable CTriggerEntry<CNotTrigger>; 描述串 "negates content of trigger" |
| 0x14002F760 | vftable CTriggerEntry<COrTrigger>; 描述串 "at least one entry inside trigger must be true" |
| 0x1400795C0 | vftable CEffectEntry<CEffectTooltipEffect>; 描述串 "Shows just tooltip of effects" |
| 0x140079680 | vftable CEffectEntry<CHiddenEffect>; 描述串 "Effect not shown in tooltips" |
| 0x1400796E0 | vftable CEffectEntry<CIfEffect>; 描述串 "a conditional effect" |
| 0x140079800 | vftable CEffectEntry<CRandomEffect>; 描述串 "a random effect" |
| 0x140079AD0 | vftable CTriggerEntry<CIfTrigger>; 描述串 "if_, CIfTrigger, A conditional trigger\nif = { limit = { <triggers> } " |
| 0x140079B30 | vftable CTriggerEntry<CLogScriptTrigger>; 描述串 "Print message to game.log - Can be localized" |
| 0x1403E8F50 | vftable CPlanningSkillLevelTrigger; 串 ['TRIGGER_PLANNING_LEVEL', 'planning_lev', 'el'] |
| 0x1404418B0 | triggers/career_profile_trigger_implementation:439 断言; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\triggers\\car" |
| 0x1404B8650 | triggers/triggerbase:822 断言; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\triggers\\tri" |

#### 4.29.31 mod 装载与虚拟文件系统函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141AF95A0 | 脚本令牌序列化器: 令牌 id switch (0x167/0xD/0xE/0xF 等) + 字面量 yes / has_dlc = |
