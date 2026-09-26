### 4.29 mod 装载与虚拟文件系统 (descriptor 解析 / 启用清单 / PHYSFS 挂载)

> **定位**: 启动阶段的 mod 装载全链 —— `.mod`/`.dlc` 文件解析 (`descriptor` key 派发)、
> `dlc_load.json` 启用清单读取、mod 注册表、启用集合的依赖排序与优先级、以及
> 引擎虚拟文件系统 (PhysicsFS) 的挂载封装。
> 关键结论: **引擎全文件 I/O 走 PHYSFS**; mod 内容能否被解析, 取决于该 mod 目录
> 是否被挂进 PHYSFS 搜索路径, 而非其文件是否存在。mod 间优先级 = 权重 (依赖降权)
> + registry id (`.mod` 文件名) 字典序, 见 §4.29.4。

#### 4.29.1 PHYSFS 虚拟文件系统层 (virtualfilesystem_physfs.cpp)

引擎静态链入 **PhysicsFS** (90 个 `?PHYSFS_*` 导出符号, 见 §4.29.6)。

引擎封装层 (`clausewitz/pdx_core/virtualfilesystem_physfs.cpp`) 关键函数:

| 函数 | 语义 | 要点 |
|---|---|---|
| sub_1424DD3E0 | VFS 初始化 | `PHYSFS_init` → `PHYSFS_permitSymbolicLinks(1)` → 设写目录 (`PHYSFS_setWriteDir`) 或回落 `PHYSFS_mount(PHYSFS_getBaseDir, 0, 0)` |
| sub_1424DD6B0 | **批量挂载** | 逐路径 `PHYSFS_mount(path, 0, 0)` (三参 appendToPath=0) → `PHYSFS_getSearchPath()` 重建路径表, 缓存于 `qword_1435E3E70`, 同时反斜杠→正斜杠归一化 |
| sub_1424DD760 | 单次挂载 (带挂点) | `PHYSFS_mount(path, mountpoint, 0)`; 失败报 `"Failed to mount '%s' on '%s': %d (%s)"` (virtualfilesystem_physfs.cpp:522) |
| sub_1424DD7F0 | 挂载 + 设写目录 | `PHYSFS_mount` + `PHYSFS_setWriteDir`; 失败断言 `"Cannot set write dir."` (:687) |
| sub_1424DB5F0 | 挂载后刷新 | 被上述各挂载路径在成功后统一调用 |

> 备注: `PHYSFS_mount` 第三参 `appendToPath` 恒为 0 — 挂载顺序 (而非 append 语义)
> 决定同名文件的优先级: **后挂载者优先** (PHYSFS 搜索路径前插)。

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
| 374 | steam_id | +624 | uint64 | 写入 sub_1424C08D0 |
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
| 3 | sub_142074270 | 插入注册表 (`a1+176`): 有序 map, 节点 `malloc(0x2E0)` = 树头 32 + 键串 32 (`sub_1401FF2C0` 比较) + CDLCDescriptor 672 (sub_142074CF0 拷贝); 键 = registry id (与记录 +72 同串, 同比较器) |
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
| +80 | MSVC 串容器 | disabled_dlcs | count@+92 |
| +104 | MSVC 串容器 | enabled_mods | count@+116 |

| 函数 | 语义 | 要点 |
|---|---|---|
| sub_142079C40 | 装载对象构造 | 先调 sub_14207BCA0 / sub_14207B540 扫描目录, 后调 sub_142075540 读清单 |
| sub_14207B540 | `.dlc` 扫描 | 同 §4.29.2 模式 |
| sub_14207BCA0 | `.mod` 扫描 | 同上 |
| sub_142075540 | 读 `dlc_load.json` | 打开文件 → 解析 JSON → `disabled_dlcs` 填 +80 容器、`enabled_mods` 填 +104 容器; 读失败报 `"Failed to read '%s'."` (dlc.cpp:78), 超限报 `"'%s' is bigger than %llu, will not read."` (:68) |
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
| 挂载 | sub_14207AB80 | 正序逐条: 记录 +152 非零 = archive 形态 (+136 串, fopen 失败报 `"Could not find archive for mod"` dlc.cpp:647) 否则 folder 形态 (+104 串, 缺失报 `"Folder not found for Mod %s path: %s"` :665); 两形态均以记录 +280 挂载根前缀拼接 (sub_14207C000) → `PHYSFS_mount` 前插; 记录 +584 dword ≠ 1 时挂载循环 break |

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

#### 4.29.6 PHYSFS 导出符号清单 (90)

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
