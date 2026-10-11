

### 4.26 静态资源访问层 (idb 库规格 / 访问器 API / 防御界 / 离线资产 / 验证体系)

#### 4.26.0 总览与纪律

- **实现位置**: `resource.lua` (自 hoi4_layout 拆出; hoi4_layout 经 `MOD_LUA_DIR`
  dofile 挂载并 attach 到 `GAME.layout`, 段侧调用不变), 段侧包装在 `SV2.lib`。
- ⚠ **分层纪律**: 静态资源一律调统一访问器 —— 段内散写内联曾致 modobj 修饰
  定义表 0x3169C0 掉位事故 (少一个 3)。
- **库家族规模**: TGameItemDatabase 模板实例 103 个 → **81 key 入规格表**
  (§4.26.4) + 22 形态外 (布局已定案, 需专写 reader, §4.26.4)。

#### 4.26.1 replace_path 与 mod 加载语义

- mod 声明 `replace_path="X"` 后，路径 X **只从声明 replace 的 mod 读取**
  ——vanilla 与其它非替换 mod 的文件全部跳过（KR 主 mod 替换 74 路径 /
  BlackICE 65；technology 下 19 个 vanilla tech 来自非替换 mod 却未入 DB
  实证）。
- `dlc_load.json` enabled_mods 数组序 = 加载序；同 relpath 文件后者覆盖。

引擎行为补充:

| 项 | 结论 | 证据 |
|---|---|---|
| original_* 副本 | 被 mod 覆盖的定义在库内保留 `original_*` 前缀副本 | faction_rule / rule_group / template 共 7 个 |
| FNV-1a 大小写不敏感 | country_tag_alias 的 int/INT 同库同义 | — |
| building cnt/lookup 分歧 | 库 cnt(78) 与 lookup.size(85) 数据级分歧 | GetItem 数组语义为准，roundtrip 全过 |
| building lookup 元布局 | 形态定案 : 非 40B 名录 — 85 桶×24B 哈希桶/链 {alloc, 节点链头, (1,1)}, 节点 {next, hash64, …}; 「仅 1 项可读名」系 40B 错位巧合; 条目名以 arr 侧 GetItem 为准 | 定案 |

#### 4.26.2 基础访问器 (token / 反查 / FNV)

| # | 项 | 语义 |
|---|---|---|
| 1 | lexer token 表 | **1.19.3 落位**: 表指针 `*(BASE+56498912)`（0x35E1AE0; std::string 数组 stride 0x20; ），上限 id `u32@(BASE+56498868)`（0x35E1AB4; **含端最大已命名 id**; 容量另在 0x35E1AEC 两界勿混）; 装载/注入机制见 §4.26.2a |
| 2 | `GAME.layout.token_name(id)` | 热重载重建缓存，悬垂安全；越界/0 → nil |
| 3 | `SV2.lib.tok(t)` | 段侧包装；取不到兜底原值 |
| 4 | ⚠ 运行时 ≠ 离线 token 表 | 运行时表含 mod token，id 空间整体重排 ≠ 离线 `ref/token_table_1193.txt`（原版 exe 提取）。实例：离线 20002=`arms_factory` / 游戏内 20002=`authoritarian_democrat`。**禁止用离线表按 id 取名，一律走游戏内 `token_name`** |
| 5 | name→token 反查 | `GAME.layout.name_to_token(name)`：全表扫建 {name→id} 索引，每进程一次（与 get_flag 共缓存） |
| 6 | FNV-1a 哈希 | 串版 `GAME.layout.fnv1a(s)`（variables RH 表键）；指针版（8 字节逐字节 h=0x811C9DC5 起，h^=b; h*=0x01000193）见 §4.3.12 |

#### 4.26.2a lexer 装载与注入机制 (loader 侧定案)

| # | 项 | 语义 |
|---|---|---|
| 1 | InitLexer (sub_1424BD740) | 写锁 (_LexerLock, RVA 0x35E1AD8, 写计数 +4) 下幂等初始化 (旗 byte_1435E1AB0); 静态 token 宇宙 = unk_14338D170 起的 72B×**10765** 条注册表 {id u32@+0, name char*@+8, len u32@+20} (10765 与离线 token_map_1193.txt 行数精确相等) 逐条大小写不敏感 FNV-1a 灌入 _TokenTree (`!_TokenTree.Contains(Key)` 断言, pdx_parser/lexer.cpp; editor 键 ×1); 收尾置静态最大 id (dword_1435E1ABC = 动态编号基) 并调 RebuildLookup |
| 2 | RebuildLookup (sub_1424BDC80) | 名字表容量 = max(旧容量, 静态最大 id) + **4000** 步进, 全表销毁重建 (写锁内); mod token 数超余量即再触发 (大 mod 会多次重建); 重灌后 dword_1435E1AB4 = max(静态最大 id, 各动态 id) |
| 3 | **add_dynamic_token (sub_1424BB500, 包装 sub_1424BB460)** | **mod token 注入主路径**: 动态 id = 静态最大 id + 动态计数 + 1; 名禁数字/`-` 开头; 同名 (大小写不敏感 FNV) 返回既有 id; 形参 = 16B string_view {ptr@0, len@8} 非 MSVC 串 |
| 4 | 注入第二路径 | 二进制 token 流 GetToken (sub_1424BC310) 遇 **id 23 = 动态关键词现场注册**; get_dynamic_token (sub_1424BBF50) 只查不建 |
| 5 | GetLexerString (sub_1424BC260) | 有效判据 = id ≤ dword_1435E1AB4 (**含端最大已命名 id** — §4.26.2 #1 上限语义精确化, 与容量槽 dword_1435E1AEC 是两个界); 越界 assert + 返全局空串 (RVA 0x30C71F8) |
| 6 | _TokenTree (unk_1430C6DD8) | 关键词→token 反查 RH 表 {data@+8, mask@+20}; 桶元 48B {链计数 u8@+4, MSVC string 键@+8, token u32@+40}; 查找/插入 = sub_1424BAE40/sub_1424BA400 |
| 7 | 保留 token id | 单字符/操作符名硬写: 1"=" / 2"\\"" / 3"{" / 4"}" / 5"(" / 6")" / 9"#" / 16"\n" / 17"\t" / 18" " / 467">" / 468"<" / 792"?="; 二进制流载荷 id 359=long_float / 668=unum64 / 791=num64 |
| 8 | lexerhelper (sub_1415A2BF0 族) | token 流后处理助手 (与词法表无关): `id = <值>` 赋值捕获 walker (重复捕获 assert; 驱动 sub_1415A2590; 典型消费 = 存档/配置块 id 提取; walker 构造 sub_1415A21D0 三令牌参数定案 = (块令牌 10293 history / 键令牌 11 id / 外块令牌 439 state), 驱动器匹配形 = 令牌 + 类型1 + 类型3 (`state = {`), 捕获记录 40B {令牌@0, 值@8, 段表@16, 分配器@32} — §4.00.59) |

> 其余全局槽位 (断言门/锁/动态数组容量等) 不影响访问器语义, 不逐项列。

#### 4.26.2b PDX 内嵌 Lua C API 包装映射 (桥侧写 chunk 受益)

引擎内嵌 lua 定案 = **Lua 5.1 基底** (三证: luaL_ref 走 FREELIST_REF=0 空闲链 rawgeti(t,0); lua_gettable 结果**原位覆写 key 槽** (5.1 lapi 形态, top 不变); lua_objlen 在场)。栈槽 TValue = **16 字节** {value 8B, tt 4B+pad}; lua_State: +16 top / +24 base / +32 global_State\*; `lua_gettop = (top−base)>>4`。协议常量: `LUA_REGISTRYINDEX = −10000` (0xFFFFD8F0); 伪索引判定 `idx ≥ −9999 || idx == 0 → abs = gettop + idx + 1`; 类型码 0=nil / 1=boolean / 3=number / 4=string / 5=table / 6=function; lua 层「空 ref」哨兵 = **−2** (区别于 LUA_REFNIL=−1, ref 槽传递全程带 `!= −2` guard)。

包装映射 (24 个, 逐个读体定案; 全为薄包装):

| 包装 | 等价标准 API | 要点 |
|---|---|---|
| sub_1421ABA10 | lua_gettop | `(top−base)>>4` |
| sub_1421AB370 | index2addr | 伪索引换算内联; 无效索引 → 哨兵常量 0x142B32A30 |
| sub_1421ACA40 | lua_type | 无效 → −1; 否则 tt@TValue+8 |
| sub_1421ABB60 | lua_isstring | tt==3 或 4 |
| sub_1421AC890 | lua_tolstring | 数字可串化; TString {len@+16, data@+24} |
| sub_1421AC860 | lua_tointeger | `(int)double` 截断; 串可转 |
| sub_1421AC930 | lua_tonumber | 串可转; 失败 0.0 |
| sub_1421AC800 | lua_toboolean | truthy 判定 |
| sub_1421ABD30 | lua_objlen | tt3→串化长 / tt4→TString len / tt5→luaH 取长 |
| sub_1421AC060 | lua_pushstring | strlen; NULL → push nil |
| sub_1421AC020 | lua_pushnil | — |
| sub_1421ABF70 | lua_pushinteger | — |
| sub_1421AC130 | lua_pushvalue | — |
| sub_1421AC240 | lua_rawgeti | 整数键直取 (无 metamethod) |
| sub_1421AB9E0 | lua_gettable | 核心 sub_1421B74A0 (luaV_gettable): __index 链深 ≤100 (超限 "loop in gettable"); 值 tt==6 (function) → 调用之 |
| sub_1421AC380 | lua_remove | 自 idx 起下移覆写 + top−16 |
| sub_1421AC6B0 | lua_settop | 负 idx → `top += 16*(idx+1)` (即 pop −idx−1); 非负 → nil 填充 |
| sub_1421ABCF0 | lua_next | 核心子 sub_1421B3A90; 有下一对 top+16, 无则 top−16 返 0 |
| sub_1421AC300 | lua_rawseti | 带 GC barrier (sub_1421B1F00) |
| sub_1421ADFC0 | luaL_ref | nil → −1; 空闲链头 = rawgeti(t, 0); 无空槽则 `lua_objlen(t)+1` |
| sub_1421AE1D0 | luaL_unref | ref<0 no-op |
| sub_1421ADA90 | luaL_loadbuffer | — |
| sub_1421ABDB0 | lua_pcall | — |
| sub_1421B3920 族 12 个 | luaH 层/内部 | rawget / next / rawseti / luaV_gettable / 串化 / 串转数 / __index 元表取 / GC barrier / 栈扩容 / typeerror / "loop in gettable" / __index 函数调用 |
| sub_1421B5A70 | **luaV_execute** | 主解释循环 (1278 行; for 循环 initial value/limit/step 断言串直证) |

脚本文件装载执行通道 (defines 装载 §4.26.13 与 mod 脚本共用):

| 函数 | 语义 |
|---|---|
| sub_14206FEF0 | 装载执行: 读文件 (上限 1 MB = 0x100000) → luaL_loadbuffer (chunkname=文件名) → lua_pcall(0,0,0); 任一步非 0 → sub_142070000 上报; CFileException → 返回 −1000; 否则透传 pcall 结果 |
| sub_142070000 | 错误上报: lua_isstring 门 (失败 = 断言串 "must be error message at top of stack") → 取消息 → traceback 组装 → "\nLUA Error: \<msg\>\n\<traceback\>" 日志流 (消息空则缀 " - no script source to reload"); debug 断言门下追加一次性 "…\n See error.log for details." |
| sub_142072B90 | mod 脚本通道: "script/" 前缀 + ".lua" 后缀定位后经 sub_14206FEF0 执行 |

#### 4.26.2c Lua 5.1 核心层完整面 (0x1421A-0x1421D 区; 621 函数)

**Lua 5.1 原版静态链接 + luabind 0.9** (token 空间 257-287 与 stock 5.1 逐项吻合: 21 关键词 257..277, 287 = TK_EOS, 无 PDX 自定义 token; luaX_init sub_1421B8360, token2str 表 off_142B32F40)。

**luaU_undump 整体剥除 (定案)**: f_parser sub_1421B0610 无签名分支直调 luaY_parser, 全 dump 无 lundump 报错串族 → **lua_load 只收源文本, mod 无法预编译字节码**。

编译管线 (源文本 → Closure): lua_load = sub_1421ABBF0 (luaZ_init sub_1421B0350; chunkname NULL→"?") → luaD_protectedparser sub_1421B0E20 (rawrunprotected sub_1421B0F50) → f_parser sub_1421B0610 → luaY_parser sub_1421C3520 (嵌套 >200 报 "chunk has too many syntax levels"; 收尾须 TK_EOS) → luaX_setinput sub_1421B85A0 / llex sub_1421B7CB0 → statement sub_1421C3FF0 → luaF_newLclosure sub_1421B1950 / luaF_newupval sub_1421B1A50; reallocstack sub_1421B10C0 (16B 槽) / reallocCI sub_1421B1000 (40B/条) / luaC_step sub_1421B24C0 (增量 GC 0-4 态, step 预算 = 10×gcstepmul)。

结构行: lua_State **616B** {+16 top, +24 base, +32 l_G, +40 ci, +48 savedpc, +56 stack_last, +64 stack, +72 end_ci, +80 base_ci, +88 stacksize, +92 size_ci, +96 nCcalls u16, +99 hookmask, +120 l_gt TValue, +152 openupval, +168 errorJmp}; global_State @L+184 {+16 frealloc, +24 ud, +112 GCthreshold, +120 totalbytes, +144 gcpause, +148 gcstepmul, +160 registry TValue, +208 rootgc, +368 GC 哨兵}; CallInfo 40B {+0 base, +8 func, +16 top, +24 savedpc, +32 nresults, +36 tailcalls}; **LUA_GLOBALSINDEX = −10002** (0xFFFFD8EE, 与 REGISTRY −10000 并存); lua_newstate sub_1421AE6C0; panic sub_1421AE2E0。

库行: 6 库 open (base/coroutine/package/table/string/math/debug) + luaL_openlibs sub_1421AFB90 + luaL_register sub_1421AE090 (lib open 通用注册口); **io/os 库代码在场但未注册 = 死码**; lua_debug REPL sub_1421C0470 ("lua_debug> " stdin 行) **零调用方 = 悬空残留**。

宿主通道 (luaL_loadbuffer sub_1421ADA90 全映像仅 3 调用方 / lua_pcall sub_1421ABDB0 仅 4):

| 通道 | 链 |
|---|---|
| defines 系统 | 重载总入口 sub_14074A9E0 (defines.cpp:237, "common/defines" 目录, SRW stru_14344A520) → env 工厂 sub_14206F530 (close→newstate→openlibs→luabind::open) → 装载器 sub_14206FEF0 (1MB 上限; **首错整批放弃**) |
| mod 脚本 script/*.lua | watcher ("*.lua" → sub_142072B90, 包装 sub_14206FEF0; "script/" 前缀 ".lua" 后缀) 挂 sub_1422566E0; **L 池 = qword_14344A530** |
| luabind 层 | C++↔Lua 绑定 (经自家 call_function 封装, 不直打 loadbuffer/pcall 符号) |

⚠ gfx/FX/*.lua (bloom.lua 等) 是渲染管线 shader 文本 (sub_1410066C0 经 sub_142409E20 文件读取), **不进内嵌 Lua VM**。

#### 4.26.3 非 DB 静态注册表

| 表 | 挂载 | 布局 | 访问器 |
|---|---|---|---|
| modifier 定义表 | `rp(BASE+53669264) (= qword_14332ED90)` | stride 120, token u32@def+112, cnt@BASE+53669276 (= dword_14332ED9C) (BHU 4,486 / kr2 5,285); **id 空间两段定案: 静态宇宙 = 0..665 稠密 666 槽 (注册点全解 100%, 离线 id→名全表数据件 `ref/modifier_idmap.txt`), 动态段 = 脚本动态 modifier 自 666 起编号** (wrapper sub_14060C290 内 index = 计数器+666, 随 mod 变, 离线不可枚举; 旧「712 项」含错位窗假阳证伪, 以 666 全表为准) | `modifier_token(idx)` / `modifier_count` / `modifier_category_mask`（掩码 u32@0x332f248） |
| modifier tooltip 格式化器 | `sub_14055A0C0(修正块, out, def_idx, lambda, …)` → `sub_1410E46D0(值串, 国名, 件)` | 越界门: `a3 > dword_14332ED9C`（=cnt 槽）→ 越界返空串 | loc 模板 `$MODIFIER$: $VALUE$` 渲染入口 |
| modifier tooltip 取数 | — | 越界过 → 查定义表 `qword_14332ED90 + 120*a3`; 类别掩码 `u32@def+104` 经 `qword_1433300A0(修正块)` 谓词门滤 | GUI `Get*Tooltip` 族逐修正名 + 值组装多行串。⚠ **def+100 与 def+104 双旗字并存 (待裁)**: 建筑校验器两函 (sub_1414BAB90/BAD50) 读 **def+100 bit3 = country / bit4 = state** 类别位, 与本行 def+104 类别掩码为两个独立旗字 — 非矛盾, 语义分工待裁 |
| external_rules 定义 | `rp(BASE+53575920)` | `M.dim.EXTERNAL_RULES`=28 槽, 键 token u32@defs+56*i+40（[0]="none" 哨兵+27 规则键） | `rule_key(i)` / `rule_def_flags(i)`（字节@+48/49/50） |
| SET 名串表 | `rp(BASE+53626272)` | **指针全局须先解引用**，条目 32B MSVC; count 实时@0x333d53c; idx=0 无名 | `set_name(idx)` / `set_count` |
| CSavedEventTarget | scope 内联@事件+16; 触发 = from==自指 且 \*(sc+160)≠0 | 容器 \*(sc+160) = {data@0, cap@8, count@12}; 元素 112B (布局见下表); 叶序 state→country→name, 第 2+ 目标编 [N]; writer sub_14053BDA0 + 元素 sub_14053C090 | 段内 emit_scope |
| id 注册表 (#.id) | BASE+54758992/58/60 | 三源 RH (buckets@+8, mask@+20, +40 是 hash seed), value=u64@vp+8=(id<<32)\|type, 逐型 max; 源③ 8B×100 槽 | `idreg_unit_resolve` / `idreg_maxima`（§4.26.5） |
| grand doctrine 定义库 | `qword_14332EEA8` | 定义库 {data@+56, mask@+68, extra@+72}; 推定 | — |
| sub doctrine 定义库 | `qword_14332EEB0` | 定义库; 推定 | getter sub_14052AE00 |
| rule def 表 | `qword_1433304C0` | 56B/条; 直证 (relation_rule 两类 GetDesc 同式消费 + Execute 条目 +49 合并旗直读) | has_rule GetDesc 名来源; 关系规则覆写白名单 unk_142771098 = {7, 26} (详 §4.3) |
| 事件目标名表 | `qword_14333D530` | 32B/条; 推定 | has_event_target GetDesc 名来源 |
| 原 tag → 国 id 展开表库 | `qword_14332F260` | 表对象 {data, count@+12}; ⚠ 地址与 gs 单例全局同名址, 宿主归属未裁; 推定 | getter sub_1401DBD80 |
| 歌曲库 | `unk_14333C610` | —; 高置信 | — |
| 内容启用位掩码 | `dword_14332F248` | u32; 亦经 modifier 类别掩码出口读 (同址两名); 推定 | — |
| 循环迭代上限 | `dword_1433368E0` | u32 (值未取); 推定 | — |
| ironman 前置强制旗 | `byte_14332F646` | u8; 推定 | — |
| 调试模式全局 | `byte_14332EC69` | u8; is_debug / debug 警告开关; 高置信 | — |
| 动态国判定阈值 | `qword_143330D98 + 136` | u32; 推定 = 静态国家计数 (该全局 = **国家库/tag 管理器**, s4_01:37 与 s4_12:271 定案读法; 原括注「事件目标注册表」与其冲突, 待裁); 推定 | — |

CSavedEventTarget 元素布局 (112B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | vtable | — |
| +8 | uint32 | state | ≠0 写 .state |
| +12 | int32 | country tid | >0 写 .country |
| +104 | uint16 | 名字索引 | ≠0 → set_name(idx) |

#### 4.26.4 idb 库规格 (102 key)

⚠ **"家族统一 arr@64/cnt@76/token@+8" 不成立** — 仅 4 库标准族，其余
arr/cnt/名字段随派生类漂移（cnt 漂移实例 52/60/76/84/92/100/108/132/
148/188/212）。扩新库必须逐库 ctor 定案后落同款规格表。本表由
`resource.lua M.rva.idb` 生成，规格以代码注释为准。

| key | 单例 RVA | arr@ | cnt@ | def 名 | nonull | 备注 |
|---|---|---|---|---|---|---|
| state_category | 0x332f968 | +64 | +76 | tok8 | 否 | CStateCategoryDatabase 14 (13+none) tok8; STATE 段 (kr2 事故族) |
| building | 0x332ee28 | +64 | +76 | tok8 | 否 | CBuildingDatabase 56 (55+none) tok8; states buildings (取代 legacy BLD2_NAMES); **+232/+244 与 +832/+844 = 两类别 def 子集容器** (高置信, 填充点未找; GUI = 海军 HQ 站点匹配链, §4.16.14); **\*(库+936) = rail_way 建筑模板 def 缓存** (定案三证: 铁路 info ctor RailwayTemplate 断言 / 指针等同比较 / 生产线读取; 消费 = 铁路造价公式, §4.14.6) |
| equipment | 0x332eec0 | +104 | +116 | tok8 | 否 | CEquipmentDatabase 457 tok8 (变体+原型合并; upgrades@176/38, modules@224/313 另有) |
| technology | 0x332f0a0 | +72 | +84 | "sso16" | 否 | 553 (arr[0]=null 空名) sso@def+16; folders@168/17 (folders 子表元素类 = **CTechnologyFolder**, 208B, ctor sub_140ACC080); 条目类 = CTechnologyTemplate (见下「条目类」表) |
| focus | 0x332ef70 | +88 | +100 | tok8 | 否 | CNationalFocusDatabase 10888 tok8; arr@64/22 = focus styles (名 sso@+8) |
| idea | 0x332ef30 | +104 | +116 | tok8 | 否 | CIdeaDatabase 5797 tok8 (口径待裁: CIdea 条目实为 3344B malloc 0xD10, 5797 非条目尺寸); **+216 = CIdeaGroupType 组表** (25 tok8) / **+160 = CIdeaCategory 类别表** (15 sso16) — 详见 §4.10.12b |
| decision | 0x332ee80 | +40 | +52 | "tok16" | 否 | CDecisionDatabase 4128 tok16; lookup@64 (40B 元, 非指针数组); 分类@88/594 (名 sso@def+24) |
| strategic_resource | 0x332f088 | +40 | +52 | tok8 | 否 | 8 (7+none) tok8; db+64 是字符串另物 |
| autonomous_state | 0x332ee18 | +64 | +76 | "msvc8" | 否 | ⚠ 特例: 无 arr/cnt — defs=内联指针数组@db+48, 名 MSVC@def+8, count 扫描; puppet 名也可直接读 def 对象 sso@+8 (§4.10) |
| ideology_group | 0x332ef38 | +96 | +108 | tok8 | 是 | 4 tok8 (democratic/communism/fascism/neutrality); nonull=true = arr[0] 是真实条目 (democratic), ≠ 库无 Null Object — group db+120 仍挂 TNullObject<CIdeologyGroup> (0x143330690, ctor sub_14067D410) |
| sub_unit | 0x332f090 | +64 | +76 | tok8 | 否 | CSubUnitDatabase 158 (157+none) tok8 (charmgr sub_unit_modifiers 键); 磁盘解析加载器 = sub_140AC3130 |
| wargoal | 0x332ef28 | +64 | +76 | tok8 | 否 | CWarGoalDatabase 11 (10+none) tok8 |
| gamerules | 0x332ef20 | +40 | +52 | tok8 | 否 | ⚠ 稀疏: 86 槽大半脏指针 (BHU 仅 4 槽可命名), 枚举须逐槽 kptr+名过滤; 规则实例侧用 rule_key |
| terrain | 0x332f0a8 | +64 | +76 | "sso24" | 否 | CTerrainDatabase A 族; sso@def+24 (+8 非 token) |
| opinion_modifier | 0x332efc0 | +40 | +52 | tok8 | 否 | B 族 tok8; **db 另有 +64 _TargetModifiers 向量 (target 条) 与 +88 名索引向量 {32B 名串, u32 序号@+32}**; 装载 0x140A80B20 (块键 12406; 装载期 value 钳位 [min_trust, max_trust]) + target 顶替后处理 0x140A829C0 (见 §下 COpinionModifier 行) |
| strategic_region | 0x332f080 | +40 | +52 | "sso32" | 否 | "%s (%i)" 直证 |
| state | 0x332f070 | +40 | +52 | "none" | 否 | 按 id 无名 |
| country_leader | 0x332ee68 | +64 | +76 | tok8 | 否 | A 族标准 |
| continuous_focus | 0x332ee60 | +48 | +60 | "sso24" | 是 | miss 返 0, arr[0] 真实元素 (hash@+16 不参与取名; def 名直写 sso24 —— 泛化 sso24h16 别名会丢名致断名) |
| agency_upgrade | 0x332edc0 | +64 | +76 | tok8 | 否 | 标准 tok8; TNullObject@0x3330480 |
| ai_focus | 0x332ee08 | +64 | +76 | tok8 | 否 | 标准 tok8; CNullAIFocusDatabaseEntry |
| ai_equipment_role | 0x332edd8 | +64 | +76 | "msvc8" | 否 | CNull…Entry |
| ai_role | 0x332edf0 | +64 | +76 | "sso16" | 否 | CNullAIRoleDatabaseEntry |
| ai_strategy_plan | 0x332ee10 | +72 | +84 | "sso24" | 否 | ⚠ cnt 漂移 84 (B 族 72 起步实例) |
| bookmark | 0x332ee20 | +40 | +52 | "sso16" | 否 | TNullObject@0x332f350 |
| unit_leader | 0x332f0d0 | +88 | +100 | "sso16" | 否 | TNullObject@0x333a2a8 |
| aces | 0x332edb0 | +40 | +52 | "msvc8" | 是 | miss→0 无 Null Object |
| scripted_window | 0x332f060 | +40 | +52 | "msvc8" | 是 | miss→0 |
| ability | 0x332eda8 | +40 | +52 | "none" | 否 | 定案: nm = MSVC 串@def+112 (探针: 14 条全读出, force_attack…rotating_reserves) |
| ai_area | 0x332edc8 | +40 | +52 | "none" | 否 |  |
| ai_attitude | 0x332ede8 | +64 | +76 | "none" | 否 |  |
| country_scorer | 0x332f018 | +136 | +148 | "none" | 否 | TReloadable 样板 (内联 null@db+160); **库布局 (sub_140AA36F0 定案)**: RH 表 {buckets@+72, mask@+84, extra@+88} 条目 56B {dist+1 u8@+4, 键 u32@+8 = 32 位哈希全值, 值@+16}, 末哨兵 = buckets + 56×(mask+extra+1); **+128 = ai_decryption_target_scorer 槽** (装载查名未中 → :99 "non existing country scorer %s" 落 null); +136/{cap@+144, count@+148} = **固定 9 槽义务 scorer 指针向量** (枚举 0..8 名表与 §4.3:187 全表一致); 哈希 = FNV 折叠变体 73244475 双轮 `(h^HIWORD(h))` / `(h^(h>>16))` — §4.8 MIO loader 同族定案; GetScorer (sub_140AA3BA0) = a2 非零返 a2 否则内联 null, 空参 debug 断言 :81 "pScorer" |
| timed_activity | 0x332f0b8 | +48 | +60 | "none" | 否 | 内联 16B 元 |
| career_medal | 0x332ee30 | +40 | +52 | "sso72" | 否 | 库类 `NCareerProfile::CMedalDatabase` (TGameItemDatabase 族, 96B; ctor 0x1406AAE10; 条目类 `NCareerProfile::CCareerProfileMedal`); A 族; 条目 u32@+8 是硬编码 id 非 token, 显示串@+72 = loc 串 sub_1406ABD30; +104=描述, +136=quote 仅绶带; 布局全回收见 §4.3 |
| career_picture | 0x332ee38 | +40 | +52 | "none" | 否 | 库类 `NCareerProfile::CProfilePictureDatabase` (64B; ctor 0x1406AC6E0); GUI-only |
| career_background | 0x332ee40 | +40 | +52 | "none" | 否 | 库类 `NCareerProfile::CProfileBackgroundDatabase` (64B; ctor 0x1406AC470; def 去向 `common/profile_backgrounds`) |
| career_ribbon | 0x332ee48 | +40 | +52 | "none" | 否 | 库类 `NCareerProfile::CRibbonDatabase` (96B; ctor 0x1406AF690; 条目类 `NCareerProfile::CCareerProfileRibbon`); medal 同型 getter 族 (+72 名/+104 描述/+136 quote) |
| ai_fleet_template | 0x332ef88 | +80 | +92 | tok8 | 是 | PersistentReloadable; tok8 (FNV@+8) |
| ai_taskforce_template | 0x332ef80 | +80 | +92 | tok8 | 是 | fleet 同构 (nm 推定) |
| focus_inlay_window | 0x332efd0 | +80 | +92 | "none" | 是 |  |
| frontend_background | 0x332ef18 | +80 | +92 | "none" | 是 |  |
| strategic_location | 0x332f078 | +80 | +92 | "none" | 是 | nm 推定 |
| scripted_trigger_template | 0x332f058 | +64 | +76 | "sso96" | 否 | null=TNullObject@0x33121140; 条目基类 CAndTrigger (基 ctor sub_140549F40); 同名 = 首登静默跳过 (查 sub_140AB56D0 命中有效条目即 advance, 不追加不覆盖无日志; 与 on_actions 追加语义相反) |
| scripted_diplomatic_action | 0x332f048 | +40 | +52 | "none" | 否 | 定案: nm = MSVC 串@def+16 (探针: 2 条) |
| scripted_map_mode | 0x332f040 | +40 | +52 | "none" | 否 | **def 名串在 +232** (MSVC 32B: 缓冲@+232 / size@+248 / cap@+256) — 探针按 sso 族偏移取不到故误判无串; def 类 = `CScriptedMapMode` (vtable 0x142942720), 库 = `CScriptedMapModeDatabase` (vtable 0x1429427A0) ← TGameItemDatabase 模板, 单例 qword_14332F040; 匹配直证 = boot 加载器 sub_140AAF740 按 `def+232` 串 memcmp; def 其余键: 602 top→+8 / 603 bottom→+120 / 19186 failure→+264 / 19187 limited_success→+268 / 19188 critical_success→+272 |
| equipment_group | 0x3330480 | +96 | +108 | tok8 | 是 | A 族变体 GetByToken vec@96/tok8@+8 |
| character_advisor_generation | 0x332ee50 | +40 | +52 | "none" | 否 | 同族推定 |
| ideology | 0x332f528 | +96 | +108 | tok8 | 否 | miss 回退 +120 默认槽 (TNullObject<CIdeology>@0x3339d00) |
| country_tag_alias | 0x332ee78 | +96 | +108 | "tok264" | 否 | ⚠ token 在元素+264 非 +8 (防呆) |
| mtth | 0x332ef58 | +96 | +108 | tok8 | 否 | tok8; byte@128 = 内容解析开关 (1=只登名/0=全解析; 条目布局 §4.26.11) |
| historical_agency | 0x332edb8 | +40 | +52 | "none" | 是 | 库类 `CHistoricalAgencyDatabase` (64B; ctor 0x140171B60); **本库 def 无名键** — reader 0x140621F70 四键: `picture`(464)→+40 SSO / `names`(12767)→+16 串列 / `default`(11405)→+160 子块 / `available`(12264)→+72 子块; resource.lua 键源应改 `nm="none"` |
| scientist_trait | 0x332f010 | +96 | +108 | tok8 | 是 | tok8 |
| difficulty_settings | 0x332ee88 | +40 | +52 | "sso56" | 否 | getter = sub_140170630 单例 creator (`qword_14332EE88`, `_pInstance && "Instance already created."` gameitemdatabase.h:127 断言链; 并列的 sub_140170120 在 1.19.3 不存在) |
| operations | 0x332efa8 | +96 | +108 | tok8 | 是 | TReloadable 三连 |
| operation_phases | 0x332efb0 | +96 | +108 | tok8 | 是 |  |
| operation_tokens | 0x332efb8 | +96 | +108 | tok8 | 是 |  |
| on_action_data | 0x332efa0 | +64 | +76 | "none" | 否 | A 族; arr[0]=COnActionList null@0x3339e80 |
| unit_medal | 0x332f0c8 | +64 | +76 | "none" | 否 | 库类 `CUnitMedalDatabase` (TGameItemDatabase<CUnitMedalDatabase>, 88B; ctor 0x140AE1830; creator 0x140173F00; boot 载 `common/unit_medals` via loader 0x14018B960); A 族; arr[0]=TNullObject@0x333a278; def GUI 锚: +152 图标 gfx 基名串/+1068 frame/+760 基础花费/+184·+568 双 modifier 文本源, 详见 §4.18 |
| test_db | 0x332f0b0 | +40 | +52 | "none" | 否 | 测试桩 (无 parse 路径, 常态空) |
| faction_goal | 0x332eee0 | +80 | +92 | tok8 | 是 |  |
| faction_icons | 0x332eee8 | +80 | +92 | tok8 | 是 |  |
| faction_member_upgrade | 0x332eef0 | +80 | +92 | tok8 | 是 |  |
| faction_member_upgrade_group | 0x332eef8 | +80 | +92 | tok8 | 是 |  |
| faction_rule | 0x332ef00 | +80 | +92 | tok8 | 是 |  |
| faction_rule_group | 0x332ef08 | +80 | +92 | tok8 | 是 |  |
| faction_template | 0x332ef10 | +80 | +92 | tok8 | 是 |  |
| ai_faction_theater | 0x3330c60 | +80 | +92 | tok8 | 是 |  |
| doctrine_folder | 0x332eea0 | +80 | +92 | tok8 | 是 |  |
| grand_doctrine | 0x332eea8 | +80 | +92 | tok8 | 是 |  |
| sub_doctrine | 0x332eeb0 | +80 | +92 | tok8 | 是 |  |
| doctrine_track | 0x332eeb8 | +80 | +92 | tok8 | 是 |  |
| ai_bonus_weight | 0x332edd0 | +96 | +108 | tok8 | 是 | TRS |
| mio_organisation | 0x332ef48 | +96 | +108 | tok8 | 是 | TRS (Add 直证 sub_140168160; 副表@160) |
| mio_policy | 0x332ef40 | +96 | +108 | tok8 | 是 | TRS; **条目类 = NIndustrialOrganisation::CPolicyTemplate (808B 全布局 §4.26.26)**; 按名 RH 表头 @+64 (data@+72 空表哨兵页 unk_143085C90 / count@+80 / mask@+84 / extra@+88 / lf@+92) |
| project | 0x332efe8 | +80 | +92 | tok8 | 是 |  |
| prototype_reward | 0x332eff8 | +80 | +92 | tok8 | 是 |  |
| specialization | 0x332f068 | +96 | +108 | tok8 | 是 | TRS |
| raid_category | 0x332f000 | +120 | +132 | tok8 | 是 | 库类 `NRaids::CRaidDatabase` (vtable 0x14271B3A8, TReloadableGameItemDatabase); 双仓之 categories 仓 (types 仓 vec@176/cnt@188 需专读); 条目类 = CRaidCategory (224B, 工厂 sub_140A9D170 → db+88) / CRaidType (3064B, 工厂 sub_140A9D2D0 → db+144); 详见 §4.27.2 |
| script_constant | 0x332f020 | +80 | +92 | tok8 | 是 | 库类 `NScript::CConstantDatabase` (128B, 3 基含 TGameItemDatabase; ctor 内联于 sub_14018BB20); 条目 = `NScript::CConstant` (64B, vtable 0x14271B5D0); 目录 `common/script_constants`; **首条必须是 `schema` (18061)**; 详见 §4.19.5 |
| script_named_collection | 0x332eed8 | +80 | +92 | tok8 | 是 | 库类 `NScript::CNamedCollectionDatabase` (128B, ctor sub_1401720E0); 条目 = `NScript::CNamedCollection` (408B, vtable 0x1427198D8); 目录 `common/collections`; 详见 §4.19.6 |
| ai_naval_goal | 0x332ef78 | +80 | +92 | tok8 | 是 |  |

跨库通用定案:

| # | 定案 |
|---|---|
| 1 | **标准族** = {arr T**@64, cnt i32@76, def token u32@+8}; GetItem sub_140AE2E50: idx<1 或 ≥cnt 回退 arr[0]（多数库 arr[0]="none"） |
| 2 | **A 族** = 名索引 vector@40（40B 条目 {sso 串@0, FNV hash@32}）+ 元素数组 {arr@64, cap@72, cnt@76}（terrain/country_leader/sub_unit） |
| 3 | **B 族** = pdx vector {T** data@X, cap@X+8, cnt i32@X+12, alloc@X+16}（X=40/48/72/88/104 随库漂移） |
| 4 | **PR 族** (PersistentReloadable) = {vec@8 基类(=_Paths 文件路径表非条目), 表@48 (size@64/mask@68), 条目 vec@80/cnt@92, token vec@104}，无 null 回退 |
| 5 | **TRS 族** (TReloadableGameItemDatabaseSpecific) = {条目 vec@96/cnt@108, 按名 RH 表头 @64 (32B 内嵌形: data@+72 / count@+80 / mask@+84 / extra@+88 / lf 0.9@+92; 空表 data = 静态哨兵页), 56B 桶 {hash u32@0, dist u8@4, token@8, 值@16, 名 sso 32B@24}}；@128 起 32B = boost::signals2 信号（vtable off_1427028E0）非数据; 全例 = CPolicyDatabase (§4.26.26) |
| 6 | **TReloadable 0x80/0x88 骨架** = {vec24@40, RH-map@64 (73244475 乘法 hash, stride 56, 静态默认条目@72), 条目 vec@96/cnt@108, 默认槽@120, byte@128} |
| 7 | token = FNV-1a 大小写不敏感 hash；`sub_140AC4C70`（arr@88/cnt@100/token@+84）是 sub_unit 第二数组的 GetItem，勿误配 strategic_region |
| 8 | **索引语义通则**: 存档引用静态定义一律写 def 名（token/内嵌串），**无任何字段写 idb 下标**; 唯一例外 = charmgr sub_unit_modifiers 容器 B key |
| 9 | **两套命名空间判别**: 值是小整数且 ≤ idb_count → 查表确认; 数千~数万 → lexer token; ⚠ 绝不可混用互喂 (BLD2 事故) |

形态外 22 库（完整布局定案; reader = `M.idb_find(key, name)` 形态分发）:

哈希族基元 (全族共有):

| 项 | 语义 |
|---|---|
| pdx RH 表头 (32B 内联) | {**+0 桶数组指针 (ctor 置 `.data` 静态空缓冲**, 非 0 亦非 NULL: sub_1411F1AE0 置 `&unk_1430B2A10/2A40/2A90` 族; 收缩路径 sub_1411F7F30 count 归零时 free 后回退 `&unk_1430B2A40`), +8 桶指针 (空态 = .data 静态缓冲), +16 count u32, +20 mask u32, +24 extra u8, +28 满载 f32 0.9}; **nbuckets = mask+1+extra**; 桶 {+0 hash u32, +4 探测步数 u8 (1-based, 起始槽 = 1), +8 键/值} |
| 键哈希两族 | **cs/ci-FNV-1a32** (seed 0x811C9DC5, 素数 0x01000193; ci 版折 A-Z, 配 stricmp) 与 **wang 混洗** (0x45D9F3B 双乘, 特形类用); 键名与存值哈希可不同层 (db10 存名哈希) |
| MSVC unordered_map | 哨兵节点@head, +8 size, +16/+24 桶对; 节点 = {链@0/+8, 键串@16, 值@48} |
| std::map | 头@40 {_Left@8 推定 (按 _Myhead 形)}; 节点 {键串@32, 值@node_val} |
| token 键库 | 键 = u32 lexer token 而非名哈希 → `idb_find` 走有界线性扫 (keytok) |
| **空槽判据 (活体定案)** | **hash 槽 == 0**。桶 +4 的探测步数在**已填充槽上也可为 0** (equipment_graphic 起始槽即 0), 0xFF 本族未用 —— 早期按"步数==0 即空"读, 致探测链越过链中途填充槽即断 |
| **探测回绕模数 (活体定案)** | **nb = mask+1+extra**, 非 mask+1。表增长后尾部槽 (idx ≥ mask+1) 仍持条目 (power_balance nb=22/mask=15: 槽16-21 有键), 用 `& mask` 回绕永不可达 → 位移键全灭 |
| **探测起点** | `hash & mask` (u32 与 mask 按位与), 逐槽 +1 以 **%nb** 回绕; 命中后须键串复核 (防碰撞误配) |

| key | 单例 RVA | 形态 | 布局要点 | 回退 |
|---|---|---|---|---|
| name | 0x332ef68 | umap | 哨兵@48/size@56/桶@64; 节点 0x428 {键串@16, 值 CCountryNames 1016B@48}; 键 cs-FNV | miss → 内嵌 default@db+104 (token 11405) |
| name_group | 0x332ee90 | chain4 | **4 链式表按型分库** {db+40 army / +56 ship / +72 codename / +88 railway_gun, 各 {@+16t count, 模数 **511**, 桶阵}}; 节点 16B {entry@0, next@8} 头插; 键 ci-FNV%511; **CNameGroup 368B** (E_NAME_GROUP_TYPE 枚举与 tracker mode 同域; 104B 名条目; +280 link_numbering_with 双向互链); 磁盘四目录 = common/units/names_divisions / names_ships / codenames_operatives / names_railway_guns (旧 units_names 不存在); 取名管线 = 8B90 占用检查 → 5A80/5D90 → 0850 → 1B30 显示名; tracker 小时级更新 = division_names.update | miss → 0 (无 Null) |
| unit_names | 0x332f0d8 | inline | vec@64 stride **120**, cnt@76 = 国家数; 元素 {str@0/32/64, 容器@96}; +40 = "(generic)" 存根 | — |
| portrait | 0x332efd8 | umap | 文化组→条目 (48B 头 + CCountryPortraits 载荷 400B, 节点 448B); 运行期键 = cosmetic_tag/original_tag/tag; 大洲索引 vec@104/cnt@116 (token 10572) | miss → **函数级静态空对象 0x143339ED0** (非 db 内嵌) |
| power_balance | 0x332efe0 | rh | stride **456** {hash@0, dist@4, 键串@8, 值 CPowerBalanceTemplate 408B 内嵌@48}; 键 ci-FNV | miss → TNullObject 0x14333A068 |
| occupation_modifier | 0x332ef90 | rh | stride 48 {键串@8, COccupationModifier*@40}; 键 **cs**-FNV+memcmp; 值 +176 修饰器类型 (4=invalid 拒收) | miss → 0 |
| occupation_law | 0x332ef98 | rh | 同族 stride 48; 值 COccupationLaw 0x340; +96 有序法序列 (空则造 dummy_law); **COccupationLaw 增补**: +304 抵抗侧 CModifier / +496 有顺从块旗 / +504 顺从侧 CModifier (+16 = 修正 map); **lawdb 单例 +72 = GetOccupationLaw 兜底法指针, +80 = 驻军缩放混合兜底法指针** (与 ctor 装填槽 +88 三槽并列; 消费 = 抵抗驻军/渗透公式 §4.13.1a) | miss → 0 (⚠ 与上库挂载槽仅差 8) |
| resistance_activity | 0x332f008 | rh | 同族 stride 48; 值 CResistanceActivity 0x390 | miss → 0 |
| ai_strategy | 0x332ee00 | vec3 | 三向量: 名注册表@40 (40B {string, ci-hash}), 条目指针@64/@88, _StrategySpecificData*@112 (cnt@124); 条目 0xD50 {名@3336, hash@3368, id@3376} | miss → TNullObject 0x1433304E8 (3408B) |
| character_template | 0x332ee58 | rh (token 键) | 双表 @64/@96, stride 24 {dist@4, **token u32@8**, 值 T*@16}; 值有效性门 value+16 u8; 表A=角色模板 (表B=顾问模板 推定) | miss → TNullObject 0x143330C60 (0x248) |
| insignia_graphics | 0X332D9A0 | kind8 | **内联固定 8×64B @+40**, 访问器 = db+40+kind*64 (无越界检查); 元素 {名串@8, SInsigniaIconInfo* 向量@40} | 无 Null |
| scriptable_localization | 0x332f038 | umap | 同 name 形 (哨兵@48/size@56); 键 cs-FNV; common/scripted_localisation 定义对象 | miss → 空串 |
| equipment_graphic | 0x332eec8 | rh4 | 接口 vtable@40 + **4 张内联 RH 表 @48/80/112/144**, **stride 72** {hash@0, 步数@4, 键串@8, 值 40B@16}; 键 = **字符串 FNV-1a32** (非 token; 活体直证 armored_car_chassis_5 → hash db11bfe7); 首表 30/39 槽有效 | miss → 空图形@0x143330C78 (48B 壳) |
| ncountry_metadata | 0x332ee70 | stdmap | 节点 120B {键 8B@32, 值 CMetadata 80B@40} | miss → 内嵌默认@db+56 + Null 0x143330DB8 |
| dlc_metadata | 0x332ee98 | stdmap | 节点 304B {键 = DLC id 串@32, 值 CMetadata 240B@64}; **装载流 (sub_1409CB420, 定案)** = magic static dword_14332ECF0 门 → 目录 *.txt 枚举 (64B 串元) → 逐文件 parse 出 336B 中间体 (sub_1424BEC90) → sub_1409CAF40 注册 → 尾遍历 std::map 逐值: 名@节点+112 查已注册 DLC 描述符, 命中 → 节点+288 (CMetadata+224) = 描述符指针, 节点+296 (CMetadata+232) = ru8(描述符+664); 未命中 → :102 "DLC metadata name matches no known DLC descriptor." 断言 (闩 byte_143339B48)。**CMetadata 240B 布局 (sub_1409CB210 直证)**: 名 MSVC SSO @+16 (size@+40) / **web links RH 表 @+184** {buckets@+192, mask@+204, extra@+208}, 条目 72B {dist+1 u8@+4, 键 SSO@+8, 值 SSO@+40}, 末哨兵 = buckets + 72×(mask+extra+1) / +224 描述符槽 / +232 字节旗; 取 web link = 语言键 (sub_14239E1F0 读 qword_1435BA038 与 "l_" 前缀互动, 推定当前语言名派生) FNV-1a 32 → RH 探测 → 未中经 sub_1409CA2E0 兜底 "default"; "default" 缺失 → :63 `DLC metadata for "%s" is missing a "default" web link!` 错误日志 (非断言) | miss → TNullObject 0x143339B40 "INVALID_DLC" |
| train_gfx | 0x332f0c0 | slots | 内嵌记录@40 (名 sso + entity@72) + 指针 vec@104 + 双槽位阵 vec@176/@200 (元素 = 内联 24B 嵌套 vec) | — |
| technology_sharing_group | 0x332f098 | rh (token 键) | 接口 vtable@40 + RH 表@48, stride 24 {token@8, T*@16}; +80 = 默认模板 CTechnologySharingGroupTemplate* (160B) | 回退默认模板 (推定) |
| script_enum | 0x332f028 | rh (token 键) | RH@64, stride 40 {name token@8, 值 = 内联 pdx vec\<u32\>@16 (枚举成员 token 列)} | miss → 空 vec@40 兜底 |
| scripted_effect_template | 0x332f050 | PR 族 | 扩展 ".txt"@40 / RH map@48 stride24 / 条目 vec@80 (cnt@92) / token vec@104 / reload vec@128; 条目 CScriptedEffectTemplate 128B, 名 sso@+96; 同名 = 首登静默跳过 (FindOrInsert worker sub_14012B940 命中有效条目即 advance, 不追加不覆盖无日志; 与 on_actions 追加语义相反) | 无 Null (nonull) |
| peace_conference | 0x332efc8 | inline-vecs | 三内联 vec @184/@208/@232; vec@208 元素 192B {id@8, 有效标志@+140} | — |
| project_dynamic_modifier | 0x332eff0 | 标准 | vec@40/cnt@52, 元素即 u32 token (线性扫) | — |
| message_handler | 0x332ef60 | 非内容库 | **消息类型注册表 + 设置处理器** (剧证实证): 类型 vec@64/cnt@76 ([0]=Null), 设置 vec@40, 使能 u8@112 | Null 0x143339E60 / 0x143339E58 |

> 全 22 库共享 `TGameItemDatabase` 骨架 (+0 vtable / +8 基类 24B 容器 / +32 dword);
> 挂载槽存指针须先解引用。`idb_count` 对 rh/rh4/umap/chain4 形态按表头取真 count,
> stdmap/vec3/slots/kind8 无单值 count 返 0 (按名 idb_find 取)。

簇级增补 (gameitemdatabase.h 全量切片定案):

- **断言行号 → 头文件方法布局** (源结构重建, 定案): 127 = Create (`!_pInstance && "Instance already created."`; 104 站/80 函数, 5 站行号 hex 0x7F) / 134 = GetChecked (10 站/2 函数, 1 站 hex 0x86; 全簇最稀有方法) / 142 = 内联 Get (`_pInstance && "Instance not created."`, **757 站/680 个消费函数** 100% 内联此断言 = 全语料最大簇成因; 9 站行号 hex 0x8E) / 149 = Get 独立实例 (**232 站/215 个**, 13 站行号 hex 0x95; 182 = 不含 hex 折算的早前口径, 消费侧 state/character_template/strategic_resource/sub_unit/equipment/strategic_region/mio_organisation/idea/technology/building) / 160 = LoadDB-plain / 179 = InitFromDirectory (与 160 为双源方法同检查) / **198/201/203 = 路径向量装载第二重载三段式** (已载门无路径后缀 / 逐路径打印 / 换行; 各 3 站 3 实例) / **226/229/231 = 路径向量装载重载** (入参 vector\<path\>, T=difficulty_settings) / **259 = LoadDB 第三重载** (单路径 + 枚举器 sub_1424DC020) / 281 = LoadFiles boot 驱动 (**303** = "Reloading Database: \<path\>" 逐路径进度日志 (12 实例; 其余 6 实例整循环外包共享 worker sub_140174060) / **324** = "\<N\> errors." / **331** = "no errors." / **336** = 分隔线; 错误计数 = CLogger 全局 0x35E1BA8 vtable[3](4096) 前后差 — 挂 logger vtable非库vtable) / 349 = Reload (`"Cant reload when not loaded"`; 尾调仅 vtable[3]/vtable[4] 无 PostLoad) / 759 = ReadContent 二阶段填充 (先登记名后逐名派发全量解析, `_AliveEntries.IsEmpty()` 断言) / **882 = deferred 错误排水位** (消息 `Error: "TOKEN" in file: "F" near line: N`; PR 族库装载核心 = 惰性求值协议, 错误码 19 终止)。⚠ 行号 hex 编码 4 种 (0x7F=127/0x86=134/0x8E=142/0x95=149), 十进制 grep 漏 28 站。
- **Save writer 族 = 0 (负定案)**: 全簇无序列化写者 (静态库条目不入档三处互证); 逐键 reader 亦不在本簇。
- **装载协议**: LoadDB-plain (58 函数/68 站) = **_Paths.count@+20 已载门** (「已载旗」本质 = 路径计数非独立布尔) → 路径存 +8 → vtable+16 清备 → vtable+32 parse 主入口; **InitFromDirectory (26 函数/28 站, TReloadableGameItemDatabase\<T\>)** = 目录枚举 (元素 64B) → 逐文件 vtable+48 解析 (书已收) → **计数 ≤0 时自注册 watcher 回调存 +40 (TRS 族热重载入路 = InitFromDirectory lambda 回调, 非 TRS 库走 watcher 总线头)**; lambda RTTI 名直证 14 TRS 库类名 (CCountryScorer/CCountryTagAlias/CEquipmentGroup/CIdeologyGroup/CMTTH/COperationPhases/COperationTokens/COperations/CScientistTrait/MIO 三库/NProject::CSpecialization/NRaids::CRaid)。
- **⚠ 按名 RH 索引两族空槽判据分列**: 本簇 F13 FindOrInsert 形 (56 实例, 0x14012BC00 段聚集) 桶 stride 24 {hash@0, **探测步数@4**, token@8, 值@16}, **空槽判据 = 步数字节 0**; 而上表形态外族判据 = **hash 槽 == 0** — 两族勿混用 (wang 0x45D9F3B 双乘哈希同式互证; 表头 map@+56 {buckets, mask@+12}; 本族无可见 rehash 路径, 容量 ctor 期定, 待裁)。
- **boot 链锚点**: sub_140180BC0 = boot 最上环 (唯一调用 InitGame sub_1401835A0) → LOADING_DATABASES 总控 sub_14018BB20 (80 个 loader 实例); **0x14332ED50/ED58 = 后台长任务 shared_ptr 句柄槽非库** (防按「master 内引用即库槽」误收); InitGame 内联创建 0x14332F260 (gs 单例) / 0x143330000/50 (effects/triggers 注册表) / 0x143339D28 (CMap 单例)。
- **80 loader 目录映射要点**: `common/medals` 与 `common/unit_medals` 系两库; power_balance 装载目录名 = `common/bop`; 三名字库/gfx 三库分装; **scripted_guis 与 dynamic_modifiers 两库有 loader 未入书 103 key 表 (idb 扩容候选, 待裁)**。消费方普查 Top: equipment 49 / strategic_resource 39 / building 31 / sub_unit 30 / terrain 30 / technology 29 (消费函数数)。
- **库对象布局统一式 (定案 + 模式定性批精化)**: paths 向量@+8 (_Paths {data@8, cap@16, **count@20 = 「已载旗」非独立布尔**, allocator@24}) / **+40 双语义随族漂移 (原「过滤器对象」系 plain-T 侧)**: plain-T = 扩展名串指针 char\* (LoadDatabases 内联 `db+40 = ".txt"`, ReadContent 作枚举第 3 参) / TReloadable = watcher 句柄 vec / 按名 RH 索引@+48 (桶 24B {步数@4, 键 FNV/token@8, 值@16}, lf 0.9@+68) / 条目数组 _AliveEntries @+80..+96 {data@80, cap@88, count@92, allocator@96}; **db+96 (PR 族) = reload 总线头 off_143085170 兼任条目数组分配器** (vtable[1]=alloc/[2]=free, 条目数组与 watcher vec 增长都走它); **db+32 = 装载重入计数器** (++进入/回减退出; InitFromDirectory 以 ≤0 门决定自注册 watcher); 模板基 ctor 四步 = vtable←模板 → paths init → +32=0 → 派生覆写 (派生 vtable 再覆写)。
- **λ RTTI 全名族**: `CPersistentReloadableGameItemDatabase<DB,Entry,Config>::InitFromDirectory<0|1>` 三参 + bool 尾参 19 实例全名直证 (含 entry sizeof 九档); FindOrInsert worker (0x14012B-15B 段 ×11, A 形 this=db / B 形 this=db**) 键名走 **add_dynamic_token** (模板层与 lexer mod-token 注入链的接点 — ⚠ PR 族 +104 槽侧证 = watcher 句柄 vec (u32 push, 1.5× 增长), 与「token vec」旧标冲突待裁) → 雪崩哈希 → RH 查 → miss 建 entry (malloc+ctor+token@+8) → entry vtable[3] Load → 数组 1.5× 扩容; 查重三分支 = 新建/skip/**原位重载** (⚠ 原位重载支在 <0>/<1> 两形 worker 体内均未见, 待裁); **worker 两形 = 模板布尔参 <0|1> 运行期分支差 (定案)**: <1> 延迟形只建空条目 (全量解析延后 ReadContent; :882 逐条排水非攒批) / <0> 立即形 entry vtable[3] Parse + 数组 1.5× 扩容; λ RTTI 计数 <0>×69 / <1>×9; country_leader file_version≥10 门。
- **基类vtable槽语义修正 (104B 基 vtable 全查)**: 槽 0 = **OnReloaded 钩子空桩** (全引擎仅 2 覆写: focus → 级联重载 bookmark / decision → gamestate 刷新), 槽 1 = **deleting dtor** (非槽 0); +24 = reload 总线头指针 (TRS 族), **:349 Reload 尾调仅 vtable[3]/vtable[4]** 与 :281/:759 尾三连 (vtable[2]/[3]/[4]) 不同。
- **reload 总线复用为跨线程文件读写锁**: sub_14224B640 fopen "rb"/"wb" 读改写文件, 前后经总线头 off_143085170 的 vtable[1]/vtable[2] 槽加解锁 — CReloadDispatcher 总线被当互斥量的新用法。
- **热重载拓扑三通道**: ① CReloadDispatcher ← CDatabaseReloader\<T\>{db*@+8} watcher 表; ② loc-validator → LoadFiles → effects/triggers 重建 → OnReloaded 校验族; ③ equipment 独立 Reload (sub_1401765B0, 尾 gamestate 双通知 + 0x332F698 vtable[23] 收尾链; 控制台回显 "Equipment/SubUnit database updated.")。**watcher thunk 全形 (定案, 17 个)**: 锁 sub_1423A7000 → Get(149) 现取单例 → LoadFiles(mode 0) → 共享后处理 sub_140538B50 → **db vtable[0] OnReloaded 钩子** → 解锁 — **单文件事件触发整库重载** (thunk 无路径参, LoadFiles 遍历 _Paths 全部); 已证 on_action_data (195A70→1A0000) / agency_upgrade (1957B0→197F50); Reload 4 实例 = equipment 1765B0 / 1A8B20 / 296C60 / 2970B0 (后三者库属未决)。
- **装载协议九步 (helper 装载器 16 实例)**: 顶层包裹 token 门 → ci-FNV → **:64 键名可移植性警告** (sub_140625B10, debug 门 byte_14332EC69 — assert 第八行号之外的第九行) → 查重三分支 → add_dynamic_token 写 entry+8 → vtable[3] Parse → 双推 (条目数组 + Lookup); 实例化库补: ability / wargoal / country_leader / scripted_trigger_template / unit_leader / difficulty_settings / timed_activity / peace_conference×2 (peace_action_modifiers + peace_ai_desires)。
- **分桶变体第二形**: unit_leader 装载器 leader_*_skills 五桶 → db+568/688/808/928 (+592/712/832/952 成对), 间距 176 — 技能桶非 24B 步进 (与 category 分桶元素+144 → db+24×cat+{64,72,76,80} 并列两形)。

idb helper 子对象层 (gameitemdatabasehelper.h 簇全量切片定案):

- **helper 子对象布局** = {data (元素指针数组)@0, cap i32@8, **count i32@12** (含 arr[0] Null), allocator 对象指针@16 (vtable[+8] = alloc(bytes,align) / vtable[+16] = free)} — **B 族 vector 就是 helper 子对象**, 嵌入偏移随库漂移 (40/48/52/64/72/76/80/88/96/104/112/120/136/160 等) = 上表「cnt 漂移」现象的模板层根源 (Clear 实例直证)。
- **方法族五件**: G1 GetByIndex ×25 (`idx<1` 恒回退 arr[0] Null Object) / G2 GetByKeyInt ×25 (键偏移默认 +8, 变体 +44/+52/+60/+84/+116; **idea AddWithDupCheck = G2 同语义键 (+8 token) 内联线性查重** (PE 无 G2 共享调用), "Duplicate idea." idea_database.cpp:311) / G3 GetByName ×24 (A 族 40B 名索引遍历 + hash 预过滤 + stricmp, 命中 = 表序+1) / G4 RH 查找 ×3 (56B entry {dist@4, 串@8, hash@40, idx@48}, 桶数 mask+1+extra; 反查形显式拒绝下标 0) / G5 Clear ×18 (deleting dtor 与 intrusive_ptr 两形态, count 复位 1)。簇内零互调, 实例被簇外 277 函数消费。
- **assert 八行号语义**: 22/120/137 = Array 空检查三断言位 / 35 = Array==Lookup+1 同步校验 / 69/98 = RH 查得下标界检查 / 149/163 = 解析错误报告位 (非 assert)。
- **加载器 35 实例公共骨架** (清表→逐文件 parse→Lookup 同步插): 覆盖 AI 系/bookmark/terrain/idea/career 系/unit_medal/opinion_modifier/strategic_resource/decision_category 等 (串锚定); category 分桶二次插入变体 (元素 +144 category id → db + 24×cat + {64,72,76,80} 每类一个 helper 子对象)。

边界语义:

| 项 | 结论 | 证据 |
|---|---|---|
| 越界回退 | idx<1 或 ≥cnt 回退 arr[0] Null Object（多数库="none"） | BHU probe 实拍 |
| nonull 库返回 | nonull 库与 technology[0] 返回 nil | BHU probe 实拍 |
| def 名 token | def 名 token 全为 lexer token; **technology / autonomous_state 两库例外**（名即串） | — |
| item_token 兼容壳 | 仅适用标准族; 现无外部调用者, 建议迁 `idb_token` | — |

#### 4.26.5 补全访问器 API

| 访问器 | 语义 | 备注 |
|---|---|---|
| `idb_token(key, idx)` / `idb_count(key)` | 103 库规格表 (§4.26.4) 统一访问: 库内 idx→def 名 / 真 count (形态感知: rh/umap/chain4 按表头取, stdmap/vec3/slots/kind8 返 0) | 主消费: 定义 cap→真 count 六库 (technology/sub_unit/equipment/building/project/idea) 与对象层; 越界回退 arr[0] Null Object 语义见 §4.26.4 末 |
| `idb_index_of_token(key, tok)` | token→库内 idx 线性反查 (sub_140AC4FA0 同构), 仅 tokN 库 | 命中含 0 (Null Object 槽); 未命中 nil; sso/msvc 系库 nil; 现仅 L1 不变量电池消费 |
| `idreg_unit_resolve(ty, id)` | (type,id)→对象 三源分域: ty>4712→源① 0x3451db0 / ty∈[100,4712]→源② 0x3451db8 / ty<100→源③ 0x3451dc0+8*ty | RH 桶 24B {dist@+4, type@+8, id@+12, obj@+16}; 对象 = raw+16 调整指针 (= CPersistent 子对象, §3.9 谱系定案) |
| `idreg_maxima` | 三源合并 {[type]=max 已分配 id}, 门 type≥4712 且 <9423 且 id>0 | writer sub_14221EF70 填充语义; 消费 session_meta #.id; kr2 实拍 {4713=35724} |
| `mods_registry` / `mods_playset_tails` | mods 管理器 rp(0x344a568): RB 中序 {{name,path}} (head@+176, 名@+72/路径@+136) + 播放集末两段 "a/b" 集 {d@+104, c@+116} | 写序=中序; kr2 实拍 72 注册/5 播放集; 消费 global_tails sec_mods |
| `cde_table` | combat_data_entry 静态表 {data=0x333cb70 (1096B 元), refs=0x333cb88 (u16), count=0x333cbb8} | writer 0X140CDFFF0; kr2 实拍 count=47 |
| `rule_def_flags(i)` | rules 实例槽 i 字节 @+48/+49/+50 | sub_140638A10 拷入 state+64+slot; 值级对拍备用 |
| `M.rb_inorder(head)` | MSVC RB 中序 walker | {_Left@0,_Parent@8,_Right@16,_Isnil@25}; 防御界 1e5 帧 |
| `define(name)` / `define_f(name)` | CDefines 运行时读取（**地址来源 = DLL 侧镜像扫描**, 见 §4.26.5a） | define 返原始 qword; 未知名 nil。**值编码八族** (活体全表对拍定案): fx1e-5 (2110) / 裸 i32 (805) / 裸 i64 (692) / f32 位型 (382) / **fx32k = 定点×32768** (70) / **u8 低字节 bool** (30) / u16 (7) / f64 位型 (1); 同名多命名空间 217 名 (返首个命中)。活体: OUT_OF_SUPPLY_SPEED=-80000 |
| `define_at(name, i)` / `define_targets(name)` | 多命名空间寻址: 第 i 个 (1 起) 存储 / 全部地址数组 | 同 name 注册进多 namespace 时各槽**独立且都有效** (如 FUEL_COST_MULT 双址 0x3332F60=0.35 / 0x3334550=0.10); 按值域选槽 |
| `modifier_category(idx)` | modifier 定义表类属掩码 u32@def+104 | 引擎谓词 sub_14055F700 左操作数, charmgr 块门精确式 `cat==0 or (modifier_category_mask&cat)~=0` 消费 |
| `map_ptr` / `province_state(pid)` / `province_is_land(pid)` | CMap 单例三访问器 | kr2 探针定案; 布局见 §4.26.8 CMap 行; 现无段侧消费 |
| `idb_find(key, name)` | 哈希/内联形态库统一按名取条目 (22 形态外库): 支持 rh / rh4 / umap / stdmap / chain4 / inline / kind8 / 标准指针数组 / **msvc8 (内联@db+48 + 扫描计数)**; token 键库传 token id (keytok) | kr2 活体验收: name(BOL)/name_group(BLR_MAR_01)/power_balance(真实键)/technology_sharing_group(nee_research)/character_template(27139)/occupation_law/scriptable_localization 全中, 负例 nil; 102 key 全量 idb_count+idb_find 无异常 |
| `loc_text(key)` | 本地化文本直查 (当前语言), 未命中 nil | 布局 §4.26.8 本地化行; kr2 活体验收: GER→德意志 / FRA→法兰西 / RECRUIT_OPERATIVE_TITLE→选择招募一名特工 / CANNOT_CHANGE_LEADER_WAR→R-军队正处于边境冲突!, 不存在的 key (SOV@KR 环境) 正确返 nil |
| 库能力分级 (活体) | 102 库三级 | **A 双通 60**（枚举 idb_token + 按名 idb_find, 全 std 族）/ **C 按名型 31**（名在哈希键或值对象内, 不可枚举但按名可取: character_template/scriptable_localization/name/portrait/state/unit_names 等）/ **D 计数 0 11**（aces/ai_strategy/dlc_metadata 等需专读或空库）; 条目计数总和 29,377 |
| `terrain_lut(byte)` / `province_terrain_name(pid)` | terrain 库 LUT 与省地形双读 | 布局 §4.26.8 CTerrainDatabase 扩展行 / §4.14.3 省静态描述符; 无参 terrain_lut()=LUT count; 三侧对账 (`terrain_l2.py`) 四项全 MATCH: 落盘序≡运行时序 25/25 / 第二数组⊆磁盘 / **LUT↔color 同余 25/25** / type 回链⊆categories; 活体 32 类, 省 1=lakes 22=mountain 3953=plains |

段侧消费普查（全文 grep mod lua）—— 段/reader 实际调用面:

| 访问器 | 消费点 |
|---|---|
| `token_name` | 17 处全段面（段内经 `SV2.lib.tok` 兜底包装） |
| `idb_count` / `idb_token` | 对象层 + 角色管理器 |
| `modifier_token` | 4 处（含 global_tails） |
| `modifier_count` / `modifier_category` / `modifier_category_mask` | 角色管理器 charmgr 门 |
| `idreg_unit_resolve` | global_tails 3 处 |
| `idreg_maxima` | session_meta |
| `mods_registry` / `mods_playset_tails` | global_tails sec_mods |
| `cde_table` | combat_data_entry |
| `rule_key` / `set_name` / `rb_inorder` / `rh_iter` | 各 1-3 处 |

> 现无段侧消费（探针/验证备用，删前须再普查）: `map_ptr`/`province_state`/
> `province_is_land`、`define`/`define_f`、`rule_def_flags`、`idb_index_of_token`
> (仅 verify)、`item_token` (兼容壳, §4.26.4 末)、`set_count`。

#### 4.26.5a CDefines 地址复原: DLL 侧镜像扫描

`M.define` 的 name→地址表**不来自任何数据文件**, 而是进程内一次性扫像复原: 引擎注册每个 define 时发射固定四指令序列, 名字与目标地址都是编译期常量, 故该表烙在 `.text` 字节里。

| 项 | 内容 |
|---|---|
| 扫描签名 | `lea r8,[目标全局]` `lea rdx,[名字串]` `lea rcx,[rsp+n]` `call 装载器` = 字节 `4c 8d 05 <d32> 48 8d 15 <d32> 48 8d 4c 24 <n> e8 <rel32>` |
| 名字取值 | `lea rdx` 的 disp32 指向 `.rdata` 内**裸名字串** (NUL 结尾) |
| 目标取值 | `lea r8` 的 disp32 指向 `.data` 内该 define 的存储槽 (RVA = 返回值; 调用方加 `hoi4.base()`) |
| 护栏 (关键) | 仅当名字出现在装载器诊断串 `Error reading "NAME"` 的**引号内**才收。该串整条形如 `Error reading "NAME": no lua object named NAI\n` — **必须读到闭引号为止**, 读整条 C 串会因尾部 `: ...\n` 不可打印而全军覆没 (guard 集空 → 拒绝猜) |
| 扫描范围 | 仅 `.text` (1.19.3 = 39 MB); 实测命中区间仅 ~2.25 MB / 36 页, 全扫 ~0.07 s |
| 跨版本 | 地址随版本变, 但**签名与护栏不变** → 无需任何重生成步骤; 这正是取代离线表的原因 |

> 扫描结果 (1.19.3): **4,422 名**, 与离线基线 `ref/defines_map_1193.txt` 比对 miss=0 (基线 4,424 名中 2 名未复现), 15 处地址差**全部**是多命名空间取槽不同 (两址都有效, 值域可判), 另 18 个 name 为离线扫描器漏收的真 define。

#### 4.26.5b define 装载器族与读者家族 (loader 侧定案)

defines 全部 14 个头文件簇 4,375 个单键函数定性完毕 (ai/game/military/supply/intel/diplomacy/project/raid_defines/mapmode/industrial_organisation/faction/doctrines/graphics + defines.cpp 骨架另计 6 函数): **每函数 = 恰载 1 个 define 的装载器** (C++ 模板实例化), 非 getter、非业务函数 (多 define 组合/条件取值/误聚类均为 0, 负定案)。define 存储 = `.data/.bss` 散置独立全局 (主区 **0x3330E10..0x3339AE0** (窗口 0x330E18..0x33A9E0 内 0 个 define 槽, 勿用); 全域极值 = 0x3089120 (MOD_STATISTICS_GROUP)..0x3339AE0; **0x308-0x309 离散区不止日期槽** — 含 19 个串/音效/图标/统计名等目标 + 0x3089AD0/AF0 两日期槽), **无 CDefines 巨对象** — `this` 形参全程未用, 不存在 this+偏移访问器族。defines_game 簇 (540 函数) 对账: 538/540 KEY↔槽双向零错配, 缺名仅 2 = NGame.START_DATE/END_DATE (§4.26.7 date 槽); 1 函数 = 1 源码行 = 1 define (源行 8..604, 可作 loader↔头文件对账锚); 特例 = GAME_SPEED_SECONDS (簇内唯一 vec\<f32\> define, 5 元素双向钳); 其补零/截断规范化面全语料仅 2 例, 另一例 = NInterface.FIXED_TOOLTIP_POSITION (vec\<i32\> 2 元, 装载后元素数规范化至期望值 — 跨簇机制非孤例) + 7 串槽 (MSVC string 本体) + 11 动态槽集中 0x1433386C0..B0; 补名 3 键 = NOperatives.INTEL_NETWORK_BASE_STRENGTH_TARGET_COUNTERINTELLIGENCE_FACTOR / NResistance.RESISTANCE_COOLDOWN_WHEN_DISABLED / max=0 组第三键 (均 max=0 直证)。装载器骨架:

```
取命名空间表 → type==5 (LUA_TTABLE) 门      ← 取表 = pushstring("NS", sub_1421AC060)
                                              + lua_rawgeti(REGISTRY, 根表ref) + lua_gettable + lua_remove 四连
                                              (NS 表经 luaL_ref 以 registry ref 形态传读者)
  → 读者(&栈, "KEY", &存储全局)      ← 唯一职责点
  → [可选钳位] 读回全局, 越界记 Warning + 写回边界字面量
else → 日志 "Error reading \"KEY\": no lua object named NS" (读者不调, 全局保持原值)
值类型不符 → 日志 "\nLUA Error: incorrect lua value: KEY" + 存槽保持读者入口清的 0
```

⚠ 负定案: 无默认值替换语义 (错误 = 记日志 + 存 0)。⚠ 头文件 ≠ 命名空间: defines_game.h 实住 12 个 ns (NCountry 178 / NOperatives 124 / NProduction 70 / NResistance 60 / NGame 26 / …), defines_military.h 覆盖 NMilitary/NAir/NNavy/NRailwayGun/NDeployment 五 ns — 离线 map 的 ns 归属不能按头文件推; 同名多 ns 键不仅槽独立, **钳位策略也各自独立** (NRailwayGun.OUT_OF_SUPPLY_SPEED 钳 [-1,0] 而 NMilitary 同键无钳)。

读者家族 (三参 `读者(&游标, "KEY", &槽)`; 0x142070C50/0x142070C60/0x142071190 为 jmp 跳板, 真身 0x14206E1D0/0x14206E750/0x14206EC90):

| 读者 | 值编码 | lua 类型门 | 语义 |
|---|---|---|---|
| sub_142072500 | fx1e-5 | 3 (number) | `round_half_away_from_zero(x×100000)`; 入口先清 0 |
| sub_142070630 | i32 零扩 | 3 | `(u32)(int)double` 直存 (负值 = 补码位型) |
| sub_142070980 | f32 位型 | 3 | double→float 直存 |
| sub_142072200 | fx32k | 3 | `round_half_away_from_zero(x×32768)` |
| sub_142072840 | u8 低字节 bool | 1 (boolean) | 槽 = lua 真值 |
| sub_1420720F0 | f32×4 裸数组 @+0..+15 | 5 (table) | 恰 4 元校验 (少/多/型错三诊断) |
| sub_14074B2C0 | CColor 对象 | 5 | HSV(3 元)→RGB + a=1.0f 或 RGBA(4 元); 写 r@+16/g@+20/b@+24/a@+28; 否则报 "expected 3 parameters (hsv) or 4 parameters (rgba)"; defines 侧消费 69 键 (mapmode 7 + faction 5 + graphics 57 = 全家族最大 CColor 消费簇; 含 AMBIENT_LIGHT_ 六向光 — CColor-as-float4 特型, r/g/b 位放方向分量; 槽 32B 相邻连排三簇互证, graphics 五连排段 52 个相邻 gap 恰 32) |
| sub_142071190 | 变长数组 (堆) | 5 | 槽 = begin 指针, 元素 round(x×1e5); 消费侧 `*(槽 + 8*i)`; 元素 8B/元素 (拷贝循环 qword 索引直证; fx1e-5 定点 vs f64 位型待消费侧定案); graphics 簇用户 = NInterface.COUNTERINTELLIGENCE_ACTIVITY_LEVEL_THRESHOLD_VALUES (与 COLORS 键成对) |
| sub_142070C50 | vec\<i32\> (堆) | 5 | 槽 = begin 指针, 消费侧 `*(int*)(槽 + 4*i)` |
| sub_142070C60 | table(f32) 向量 | 5 | 堆向量; 扩容 cap×1.5 取整至少 +1 |
| sub_142070C70 | vec\<float4\> (堆, 16B/元素) | 5 | 每元素恰 4 float (少 1/多/型错 0/1/2/3 三档, 经 sub_142072E10 诊断); defines 侧唯一用户 = NInterface.COUNTERINTELLIGENCE_ACTIVITY_LEVEL_THRESHOLD_COLORS (槽 qword_143338E50), 消费 = xmm 16B/元素整读直证 |
| sub_1420711A0 | vec\<string\> | 5 | 先清空旧向量; 非串元素静默跳过 |
| sub_142071C30 | vec3f @+0..+11 | 5 | 恰 3 元, 错则 "expected 3 parameters" |
| sub_14074B130 | 定长 4 元数组 guard | 5 | sub_142071190 读后 count@+12==4 门, 拷 4×qword; 否则 "expected an array of 4 intel values" (defines.cpp:107) (intel 四类数组专用, 全库其余 defines 簇零使用); 槽宽 32B (消费侧双 xmm 直证: ENCRYPTION_DECRYPTION_INTEL_FACTORS 消费函 sub_1401D3420 连读两 16B, 邻键间距 +32 互证) |
| sub_142072800 | string | — | 拷入 0x143090xxx 串区 |
| sub_14074BA30 | CGameDate | 4 (string) | `sscanf("%d.%d.%d.%d")` 解析入日期对象 (年.月.日.时); 错误三站 defines.cpp:45 (解析失败 "Invalid value for define: KEY") / :50 (断言 !"incorrect define", latch byte_143339B10) / :51; 唯一用户 = NDiplomacy.TENSION_TIME_SCALE_START_DATE, 槽对象真身 = CGregorianDate 多态对象 (首 8B = vtable, 初始化路径直写 &CGregorianDate::vftable) |
| sub_142071770 | vec2f @+0..+7 | 5 | 恰 2 元 (错则 "expected 2 parameters" 记日志非抛); 消费 = NMapIcons.COARSE_RAILWAY_GUN_POSITION_OFFSET 铁路炮粗定位偏移 (槽 dword_1433325B8, 槽名前缀不承载语义又一例) / NMapIcons.INTEL_MAP_MODE_MAP_ICON_OFFSET 地图图标 2D 偏移 |
| sub_1424EF6F0 | 取负构造器 | — | `*dst = −src`; 仅钳位负界使用 |

⚠ **颜色 define 五编码并存 (定案, 全 defines 家族)**: ① f32×4 裸数组 RGBA (sub_1420720F0; graphics 箭头/条纹 ×27 + mapmode ×44) ② CColor 对象 {vtable@+0, r@+16..a@+28} (sub_14074B2C0, 支持 HSV 3 参; graphics ×57 + mapmode ×7 + faction ×5; AMBIENT_LIGHT_ 六向光为 CColor-as-float4 特型 — CColor 槽 ≠ 一定是颜色) ③ vec3f RGB 三元 (sub_142071C30; ×15, 名带 COLOR 实为 3 元 + 少量真 3D 位移) ④ vec\<f32\> 变长 (sub_142070C60; 调色板 ×20) ⑤ **逐通道标量拆分** (f32 标量读者; BORDER_COLOR_* ×9 组 R/G/B/A 四独立 define = 36 键, graphics 簇新证) — `define(name)` 读颜色键须按键区分, 不能一律按裸 4 字节读; 另有 vec\<float4\> 单例与标量色修饰 6 键。⚠ 数组型 define (变长数组 + vec\<i32\> 族) 槽值 = **堆 begin 指针**, `define()` 返回原始 qword 对这些键是指针非值。

⚠ **错误语义两级 (定案)**: vec 族内**元素级**型错 = throw luabind::cast_failed (进程级异常, 携目标类型 RTTI Type Descriptor; 装载链 functor 每键单独 catch 续跑, §4.26.13); **顶层**键缺失/型错 = "\nLUA Error: incorrect lua value: KEY" 日志 + 槽保持入口清的 0 (不抛)。定长元组计数错只记 "expected N parameters" 日志 (读完即返非抛)。读者族 = PDX 引擎 lua 值抽取公共层 (pdx_lua.cpp 编译单元), 调用者普查: 标量读者被 defines loader 族独占 (fx1e-5 ×2305 / i32 ×1467 / f32 ×687 / fx32k ×74 / bool ×43; graphics 簇 +fx1e-5 47 / +i32 111 / +f32 280 / +bool 1), 定长/动态向量族消费 mapmode/raid/intel 等 13 簇 define 的颜色/偏移/标签键 — 运行时业务/GUI/存档路径直呼为零。

取整式汇编核验 (勿按伪码直抄): fx1e-5 (sub_142072500) = `comiss x,0 取符号 → mulss ×100000.0 (常量池 0x271FC68 实读) → ±0.5 (0x271FC54/0x2724298/0x27242B0) → cvttss2si`, 即 x≥0 取 `trunc(x·1e5+0.5)`、x<0 取 `trunc(x·1e5−0.5)` = **半值远离零** (0.35→35000 / −0.8→−80000; 非银行家舍入; vanilla 注释 0.9 ↔ MAX 常量 90000 闭环)。fx32k (sub_142072200) 同款 (×32768.0, 常量 0x27242A4; MAX_AIR_EXPERIENCE=500→16384000)。

装载期钳位 (loader 尾一次性, 非每次读取): 13 簇合计 **832/3,823 函数带钳位** (**ai 179 / game 175 含 veclen 1 例** — veclen 另计则 174+179=353 为原普查口径; military+supply+intel 321 / 其余 158; supply 簇高达 85.4%); 越界 → `Warning for define "NS.KEY": Value V is too (large|small); clamping to …` + 写回边界值 (i32 经 sub_14015AB70 / f32 经 sub_14015AF90 / fx1e-5 经 sub_1424ED3A0 格式化)。界限以**存储单位**表示: fx1e-5 槽 100000=1.0 / 1000=0.01 / 10000000=100.0; i32 槽字面; f32 槽**位型** 1065353216=0x3F800000=1.0f (比较与落值都是位型存取)。方向分布以仅下界为主 — **仅上界例外 2 例**: NMilitary.DAMAGE_SPLIT_ON_FIRST_TARGET ≤0.9 (槽 qword_143332C50, 界走 f32 formatter 寄存器传参故脚本正则漏数) / COHESION_IMMOBILE_PLANNING_SPEED_MULTIPLIER ≤1.0 (qword_143333CC0)。非常规界 (易错点, 全定案):

| define | 编码 | 界 | 备注 |
|---|---|---|---|
| NOperatives.INTEL_NETWORK_MIN_STRENGTH_TO_LINK_SUBNETWORKS | fx1e-5 | [−1.0, +100.0] 非对称 | min 经取负构造器 sub_1424EF6F0 |
| NCountry.GIE_LIBERATED_NATION_DAILY_LEGITIMACY_CHANGE | fx1e-5 | [−100, +100] | 同上 |
| NOperatives.INTEL_NETWORK_STRENGTH_DECAY_WHEN_ABOVE_TARGET 等 3 键 | fx1e-5 | max = 0 (衰减/冷却类必须 ≤0) | 全库仅有的 max-only 组 |
| NAI.AIR_DESIGN_CUTOFF_AS_PERCENTAGE_OF_MAX / LAND_DESIGN_… | fx32k | [0, 0x8000] = [0%, 100%] | `cmp rax, 0x8000` 直证 |

NIntel 簇细目 (defines_intel.h, 223 函数全量对账): 223/223 = 纯单键装载器 (NS 全 `NIntel`,
错误串计数 = 簇计数互证), 全表 ↔ 00_defines.lua NIntel 块 223 键双向零差 / defines_map_1193.txt
223/223 零错配; 槽 RVA 0x3330E18..0x33393A0 全落主区, **vector 尾块 0x33390A0..0x33393A0 =
33 槽 ×24B 紧排零隙 (768B) 唯一成块段**, 标量区与其余簇交错混布; 读者直方图 = fx1e-5 标量
184 / vector\<fx1e-5\> 33 / fx1e-5[4] 定长 5 (错误串 "expected an array of 4 intel values"; 用户 = RADAR_BASE_INTEL_VALUES_FOR_COVERED_LAND/SEA_PROVINCES + _FOR_COUNTRY_COVERAGE_PERCENTAGE + ENCRYPTION_DECRYPTION_INTEL_FACTORS + CAPTURED_OPERATIVE_INTEL_YIELD, 四槽各有业务消费者见下表) /
i32 1 (OLD_TECH_COUNT_NUM_DAYS = 180); 钳位 64/223 (61 仅下界 min=0 + 3 双侧 [0, 1.0] =
RAID_MIN_INTEL_FOR_WARNING_ 三件, 本簇仅有的 max 钳)。⚠ 「1 函数 = 1 源行」口径细化:
DYNAMIC_INTEL_SOURCE_ 六宏族 36 键 (6 源 × 6 键 = MULT_DECAY / FLAT_DECAY / AGGREGAT_LOG_FACTOR / AGGREGAT_DIVISOR / MAXIMUMS / ABSOLUTE_MAXIMUMS 六件套衰减模型) 共享 6 源行 (每源行 = 6 函) 且簇内 RVA 序≠源行序 —
源行对账锚仅适用无宏族簇。**define 槽默认值 = .bss 零初始化无编译期字面量** (槽区全在
.data raw 覆盖 0x3085000..0x332EE00 之外; vector 33 槽动态 ctor/dtor 置零), vanilla 真值全部
来自 defines.lua, 「默认值」仅缺键时可见。

NDiplomacy 簇细目 (defines_diplomacy.h, 217 函数全量对账): 217/217 恰载 1 define (模式零违例);
reader 六族 = fx1e-5 ×145 / i32 ×63 / fx2^15 ×3 / bool ×2 / vec ×3 / 串 ×1; 槽区主段
0x3330E80..0x3338650 (216 件全落主区) + 1 离群日期件 TENSION_TIME_SCALE_START_DATE 0x3089568
(.data 有初值区, §4.26.5b 补名 7 键之一; 槽对象真身 = CGregorianDate 多态对象, 首 8B = vtable 指针, 读者 type==4 串→sub_140533D60 解析, 消费 sub_141897AB0 日期比较 — off_ 命名系 IDA 类型重建观感, 非串非 char\*); 特型件 5 (bool 双槽相邻 0x143330F46/F47 / vec 三槽
相邻各 24B); 钳位 56/217 (48 仅下界 min=0 + 8 双侧 = 7 × [0,+1.0] + TENSION_DECAY_DAILY [0,+100.0] 本簇唯一 1e7 界; 非零下界 14 键全在本簇 = INFLUENCE 族 ×9 / PEACE_COST_FACTOR_MAX ×2 / PEACE_TIMED_EFFECT_LENGTH ×3, 全为正立即数直写); 默认值同 NIntel 结论 = 二进制全零
无启动期写初值, 真值唯一来源 = defines.lua NDiplomacy 块; s4_05/s4_10 互证零冲突
(PEACE_SCORE 族 7 处 + NAVAL_BLOCKADE_BASE_COST 全符)。

NIntel / NDiplomacy 抽样键消费面 (装载器侧反查, 7 点定案):

| 槽 | 消费函 | 语义 |
|---|---|---|
| qword_143335398 (RAID_MIN_INTEL_FOR_WARNING_ON_LAUNCH) | sub_140FEF770 | 齐射预警门: `10000000×define/100000` 把 1e-5 基重标到 1e-7 基; a1+56 类型==2 → 门限 + (100000−情报系数)×(10000000−门限)/100000 插值; 类型 3/4 直接 ≥ 比较; 结果锁存 a1+400; 次消费 sub_141E98CB0 (HALFWAY_TO_LAUNCH / EARLY_PREPARATION 同族, 消费点未逐函反查) |
| dword_1433376D8 (OLD_TECH_COUNT_NUM_DAYS) | sub_141EA0FD0 | 旧科技计数日检: (当前时刻 − 43800000)/24 − v37 ≥ define (43800000 = 时基哨兵, /24 转天) |
| dword_143334988 (ARMY_UNIT_LEADER_ICON_SPRITE_ID) | sub_141D1F900 | 陆军将领图标帧 (leader_type ≤1 时 SetFrame(+1504), §4.31.86a) |
| dword_143334A30 (NAVY_UNIT_LEADER_ICON_SPRITE_ID) | sub_141D1F900 | 海军将领图标帧 (leader_type ==2 时 SetFrame) |
| dword_143334AD4 (POLITICAL_UNIT_LEADER_ICON_SPRITE_ID) | sub_141D1F900 | 政治领袖图标帧 (+1408 旗门时 SetFrame) |
| xmmword_1433356E0 (ENCRYPTION_DECRYPTION_INTEL_FACTORS) | sub_1401D3420 | 加解密情报因子 32B 四元组整读 (双 xmm) |
| off_143089568 (TENSION_TIME_SCALE_START_DATE) | sub_141897AB0 | 紧张度时间缩放起点 (sub_140533660 日期比较) |
| byte_143330F46 (PEACE_PLAY_SOUND_ON_NEW_TURN) | sub_140E4AA10 | 和谈回合音效开关门 (`if (!槽)`) |
| qword_143338638 (PEACE_SCORE_DISTRIBUTION) | sub_140E3F820 | 向量头 {begin@+0, count@+12} 24B 读法消费侧直证 |
| qword_1433393A0 (DYNAMIC_INTEL_SOURCE_CAPTURED_OPERATIVE_ABSOLUTE_MAXIMUMS) | sub_140D04D70 | 取址传入逐源上限; vec4 其余 RADAR 消费 = sub_1410A5810 (SEA) / sub_1410A99A0 (LAND + COUNTRY_COVERAGE 同函双读) / sub_140FDAAE0 (CAPTURED_OPERATIVE_INTEL_YIELD) |

注: TENSION_DECAY_DAILY (qword_143335EC0) **业务直引消费函已定案 = sub_140F05380 CWorldThreat::UpdateThreatSource** (threat.cpp:379 域; 日变更负向兜底替换 — §4.25.3); 衰减体消费 sub_140F04EE0 §4.2.6 相位 18 已载 (原「暂无业务消费函」未决注废)。PEACE_SCORE_DISTRIBUTION 同款向量头另有会话清理析构对。

NRaids/NGraphics 簇细目 (raid_defines.h, 59 函数全量对账): 59/59 恰载 1 define 零违例;
**命名空间双分 = NGraphics ×22 (RAID_ARROW_*/RAID_MAP_ICON_*/RAID_UNIT_ENTITY_*) + NRaids ×37**
(又一「头文件 ≠ 命名空间」实例); 59 键 = 59 互异源行 (raid_defines.h:5..72, 无宏族共享 —
非 NIntel DYNAMIC_INTEL_SOURCE_ 形态); 58 槽全落主区 .bss 零默认, 唯一离群 = 串槽
NUCLEAR_RAID_CATEGORY_NAME 0x1430900F8 (.data 串区); 读者直方图 = fx1e-5 ×26 (全 NRaids) /
f32 位型 ×15 (全 NGraphics) / i32 ×12 / bool ×4 / vec3f ×1 (RAID_UNIT_ENTITY_OFFSET) /
串 ×1; defines_map 59/59 零错配; s4_27 raid 册六风险槽写入者与四键用法全符零冲突。
⚠ RAIDS_ENABLE_AI / RAIDS_CREATE_FREQUENCY_DAYS 两键**不属本簇** (defines_ai.h NAI ns,
见 §4.34 raid AI 段)。
| NMarket.CONTRACT_ESTIMATE_*_ALPHA 两键 | fx32k | min=0 经域换算 sub_1424ED3F0 | `(v/100000)<<15 + ((v%100000)<<30)/3276800000` (fx1e-5→fx32k 整数分解) |
| NAI.AIFC_PATH_COST_* 16 键 + CALL_ALLY_LOSING_WAR_THRESHOLD + THEORIST_SCALING_WEIGHT_FACTOR_PER_NON_POLITICAL_ADVISORS + AI_WANTED_{LAND,CARRIER}_BASED_PLANES_FACTOR 恰 20 键 | fx1e-5 | min = 1000 (0.01) | CALL_ALLY_LOSING_WAR_THRESHOLD 唯一双侧 [0.01,1.0], 其余 min-only; ⚠ AIFC_ACTIVATE_AVG_ORG_RATIO_THRESHOLD 不在本组 (全文复读 = 双侧 [0,100000] min=0, 与 AIFC_UNIT_RATIO_BASE 等 30 键同族) |
| NMilitary.DAMAGE_SPLIT_ON_FIRST_TARGET / COHESION_IMMOBILE_PLANNING_SPEED_MULTIPLIER | fx1e-5 | 仅上界 ≤0.9 / ≤1.0 | 全库仅有的仅上界组 (槽 qword_143332C50 / 143333CC0); 前者界走 f32 formatter 寄存器传参, 扫描正则易漏 |

defines_military 簇增补 (994 函数全量对账定案): 994/994 纯单键装载器结构性例外 0; NS 分布 NMilitary 382 / NNavy 414 / NAir 173 / NRailwayGun 24 / NDeployment 1; 读者集恰 6 种 (fx1e-5 729 / i32 176 / varlen 数组 48 / fx32k 27 / bool 7 / vec\<i32\> 7 — 无 f32/CColor/日期/vec2f/串读者); 994 (KEY,槽) 对全中零缺名; **全库 define 名 25 个多 NS 多义名 100% 源自本簇** (NS↔槽归属全表在 findings); **同名跨 NS 键值编码可不同** (UNIT_EXPERIENCE_PER_COMBAT_HOUR 等 3 键 fx32k↔fx1e-5 — define() 消费须按 NS 判编码); **数组 define 槽 = 24B 结构 {begin@0, ?@8 推定 cap, count dword@12}** (跨距 24, PostLoadValidate 三对计数直证 — 书「槽 = begin 指针」系装载器可见视图, 消费/对账时 count 读槽+12); bool 槽 7 枚聚低端; 994 函数语料内零文本调用点 (经 functor 注册表数据段调用, §4.26.13 相容)。
| NDiplomacy.INFLUENCE_DISTANCE_DIVISOR / INFLUENCE_MAJOR_FACTOR | fx1e-5 | ≥ 1.0 / ≥ 0.01 | 六 INFLUENCE 槽与装载校验互证 (§4.26.13) |
| NSupply.SUPPLY_FLOW_DIST_LOGISTICS_FALLOFF_SCALAR / FLOATING_HARBOR_MIN_DECAY | fx1e-5 | ≥ 0.05 / ≥ 0.1 | 补给参数下界 (§4.21 交叉) |

#### 4.26.6 具名防御界与结构维度 (M.lim / M.dim)

| 表 | 内容 | 证据口径 |
|---|---|---|
| M.lim | PTR_SANE=4096 / PTR_HUGE=65536 / FIXED_SMALL=64 | 防御惯例（内容列表防垃圾指针; 64 级仅 writer 明文有界或固定槽） |
| M.dim | EXTERNAL_RULES=28 / RULE_OVERRIDES=28 / LOGISTICS_SLOTS=19 / HISTORY_QUEUES=3 / AI_STRATEGY_SLOTS=112 / MODIFIER_HOURS=30 | **只收定案**，逐项标 [二进制]/[惯例] 出处 |

核验范例:

| 案例 | 结论 | 证据 |
|---|---|---|
| RULE_OVERRIDES=28 | writer 明文常量 | sub_1406386B0 字面枚举 28 flag + 28 容器（进入 0x14063C690; ⚠ sub_140D2DB40 = CRelationStatus writer）; 运行期覆盖块 (非 CRule 类, §4.3.7a) 定长 [+808,+2496) 无 count |
| PORTRAITS 上限 | 结构上限 = 6 分支×2 尺寸 = 12（插入按键去重覆盖）; 16 纯防御 | 0X14139E9C0 |
| NTT unit 列表行数 | 真值 = 容器 count@T+68 | writer 0X140E28F40 无明文常量 |

> 队列行数等运行时真值一律读对象自身字段，勿造字面量。

#### 4.26.7 离线 dump 资产 (python/agent 侧, 非运行时)

| 资产 | 内容 | 状态 |
|---|---|---|
| `ref/token_table_1193.txt` | 静态 token 全表 10,765 条 (id 11..19998) | 现役 (离线, exe 提取) |
| `ref/token_map_1193.txt` | 10,765 条, 提取注册函数 sub_1400831C0 (含 entry/idglob/caller 溯源列) | session_meta 数据源 |
| `ref/defines_map_1193.txt` | **4,424 名 / 4,452 目** / 25 多义名（全 loader 族扫描; 形态含 `(float *)&`/`(bool *)&` cast 与无 `&` 全局; 护栏 = 调用点后 1.5KB 内有 `Error reading "NAME"` 诊断串; loader 侧 3,823 函数函数级对账全中零错配, 另证 7 漏收名: NAI.BUILDING_TARGETS_BUILDING_PRIORITIES 0x33384A0 (vec-string) / NGame.START_DATE 0x3089AD0 与 END_DATE 0x3089AF0 (date 槽) / NDiplomacy.TENSION_TIME_SCALE_START_DATE 0x3089568 (date) / NMapIcons.INTEL_MAP_MODE_MAP_ICON_OFFSET 0x3332520 (vec2f, 2×f32) / NMapMode.SUPPLY_COUNTRY_BORDER_FRIEND_COLOR 0x3339460 与 NGraphics.FACTION_PING_MAP_AVAILABLE_COLOR 0x3339A80 (CColor 对象) — date/CColor 形态是离线扫描器 cast 白名单漏收主因) | **冻结基线**（1.19.3 离线快照, 无再生配方; 运行时数据源已改为镜像扫描, 见 §4.26.5a） |
| `ref/serfam_1193.txt` | 1,153 行 CPersistent 族指纹表 (slot1=Save wrapper 判定; 盲区见 §4.00.1/方法论) | 现役 (可序列化性速查) |
| `ref/boot_registry.tsv` | 320 槽 boot 注册表 (槽位/ctor 签名/库分级; §4.26.8 数据源) | 现役 |
| `ref/vt_rtti.json` | 9,254 vtable→RTTI 类名 | 版本变更需重扫 |
| `ref/postload_classes_1193.txt` | CPersistent 家族主vtable槽[8] PostLoad 实装类全表 178 条 (类/主vtable RVA/PostLoad VA/预载钩/后验钩; 槽契约见 §4.00.1, 装载次序见 §4.28.17) | 现役 |
| `ref/hoi4_runtime_classes_map.json` | 8,755 类 → 运行时信息合并视图 (实 vftable 地址 + COL 层 vtable/mdisp + CPersistent 族 writer/reader/slots); 8,634 类有 vftable, 1,148 类带 writer/reader | 合并产物 (派生自上述三表; 版本变更需重生成) |
| `ref/hoi4_runtime_vt2class.json` | 9,259 条 vtable 地址 → 类名 (按地址排序) | 探针逆向替换表 (读对象首 qword 直查类名) |

TGameItemDatabase 模板族重载方法族 (定案精化): **sub_1401A0000 只是 on_action_data 库的 LoadFiles 实例** — 全语料唯一调用者 = 其 watcher thunk sub_140195A70 (纯热重载); **全族共 51 个 per-DB LoadFiles 实例** (25 带逐路径日志 "Reloading Database:" + 26 静默变体; mode 1 = 静默, 仅 errors>0 打错误行)。LoadFiles (gameitemdatabase.h:281-331) 枚举 _Paths 已存路径 → 逐文件 parser → 尾部连调 **vtable[2]+[3]+[4]** (ReadContent 759 同三连; LoadDB-plain/InitFromDirectory/路径向量族 = [2]+[4] 无 [3]; Reload 349 = [3]+[4] 无 PostLoad; PR 遍历 helper 本体无尾调) — **boot 装载不走 LoadFiles** (走 LoadDB/InitFromDirectory/ReadContent; InitGame 直接调用 LoadFiles 实例未穷证), 与存档读档无关 (存档侧 PostLoad 走 CPersistent 槽[8], §4.28.17)。281/349 断言同文本 `!_Paths.IsEmpty() && "Cant reload when not loaded"` — 281 守 LoadFiles / 349 守 Reload。错误计数 = CLogger 后前差 − 本方法自产行数 (+2 = 摘要行+分隔线)。COnActionDataBase 实测 [2]=sub_140A774B0
(缓存通用 on_daily/on_weekly/on_monthly 于 +144/+152/+160) / [1]=sub_140A75FE0 (clear)
/ [3][4]=CFG 桩。

#### 4.26.8 普查登记补遗 (未入 idb 规格表的注册表)

| 项 | 挂载 | 要点 |
|---|---|---|
| CFactionIconsDatabase | qword_14332EEE8 | 阵营图标库 {data@+80, count@+92}; GUI 消费 = CFactionIconItem 图标行 (§4.31.31) |
| CMap (省→州/海陆/描述符) | `rp(BASE+53714216)` (0x840B) | +40 省→州 **i16 数组指针** (0=海/无州); +568 省非海序 **u32 数组指针** (0xFFFFFFFF=海); +616 省静态描述符 **8B 指针数组** {data@+616, cap@+624, cnt@+628} (元素 = 描述符*; id@desc+196, bbox@desc+136..148 = **{x0@136, y0@140, 宽@144, 高@148}** — bbox 更新语义 +144 = max(运行 x−x0) 宽 / +148 = max(运行 y−y0+1) 高 (GenerateBoundingBoxes 直证)); +560=省表界 (=gs+700=max 省 id+1), +564=陆省数 (kr2 13907/10771 三读互证); **装载链增补**: +8 = 逐像素权重表 _pPerPixelWeights (tbb CInitMapPerPixelWeightsThreaded, 归一上界 = max desc+192) / +64/+68/+72 = 宽高对角线 / +80 straits.txt / +112 adjacency_rules.txt / +240 位图#2 (→+376 对象) / +272 rivers.bmp / +336 文件 (经 +736 对象 Parse) — 五个文件名槽 / +384 = 河流位图 (rivers.bmp, 断言名 _pRiverDefinition) / +392 = u16 河段洪泛标记 (**8-连通** [3×3 邻域], 河 id 从 2 起; 颜色带 = RIVER_SMALL_START_INDEX < color ≤ RIVER_LARGE_STOP_INDEX; provincetemplate 几何回填 pass (§4.14.11) 的比较为 color ≥ RIVER_SMALL_START_INDEX 下界含, 两处是否同一带定义待裁) / +416 = 河对象表 / +2096 = provinces+definition 聚合对象 120B / +2104 = 半分辨率网格 (推定战略层降采样); desc 增补: +0 有效旗 / +8 省名串 / +88 行程表 (RLE, 元 3×u16 {x,y,len}) / +152 required 规则挂接 / +160 icon 规则挂接 / +200 port (沿海无港校验 desc+210&9==9 且 +200==0 → 崩溃预警) / +208 陆块号 u16 / +211 大洲; 装载编排 = sub_140A653D0 ThreadedPostPostRead 五 pass; 访问器 `M.map_ptr`/`province_state`/`province_is_land`/`province_terrain_name` |
| 本地化运行时管理器 | `rp(BASE+56336440)` | **定案** (sub_14239ED90/sub_14239C290 + 活体双证): **mgr+0 = 当前语言 texts 对象** {+32 = 有序 16B 索引 {u64 fnv1_64(key)@0, i32 值偏移@+8} 二分查找, cnt u32@+44 (kr2 英 280,475)}; **mgr+32 = 全局串 blob 数据指针** (blob+0 直指串数据; cap u32@mgr+40 / used u32@mgr+44, 量级数十 MB), 内容 = "key\0value\0" 紧邻对, 索引值偏移指向值 (key 在值前 -#key-1 处, 冲突确认用); mgr+8 = 10 语言注册条目向量 (cnt@+20, 104B 元 {名 SSO@0, 三容器}) 为装载侧脚手架非运行时查询路径; FNV-1 64 (seed 0xCBF29CE484222325, 素数 0x100000001B3); 访问器 `M.loc_text(key)` (命中级; ⚠ 文本须 read_cstr — read_str 对 UTF-8 长串返 nil) |
| CEventDatabase | 0x3339c20 (0xE0) | events/ 递归装载; namespace 无独立表（串字段+解析侧） |
| CTerrainDatabase 扩展 | 0x332f0a8 | **第二数组 {arr@+112, cnt@+124} = 图形地形类别** (名 `terrain_N`/`desert_hills`/`forest_13`/`mountain_variation_*`, 与 A 族 arr@64/cnt@76 的**游戏性**地形 `mountain`/`forest`/`plains` 分属两套); **类别→DB LUT int[]@+136 / cnt@+148** (位图字节 → 第二数组下标; <1 或 ≥cnt@+124 → Null Object); 省地形位图 obj+368 {宽@+8, 高@+12, 步长@+16, 行距@+28, data@+40} byte=类别; 消费 sub_141652F90 (地图渲染/混合, a2=GAMESTATE, 位图宿主 = 渲染对象 `*(a1+40)`); 访问器 `M.terrain_lut(byte)`/`M.province_terrain_name(pid)` (desc+168 → def 名 SSO@+24, 游戏性名空间); **磁盘侧链路直证** (`common/terrain/*.txt` terrain 块每条 = `{ type = <游戏性名>, color = { <位图字节> }, texture = N }`): 位图字节 → LUT → 第二数组 idx → 条目 → type = 游戏性 terrain, 全链四段活体对拍 MATCH; ⚠ 同游戏性类型多色变体 = 同名多条目 (desert×3 / jungle_blend_18×2), 解析须保落盘序不折叠; **CTerrain def 侧**: def+16 = 有效旗 u8, def+140 = 位掩码位 u32 (has_terrain 载荷消费; 推定); **def+136 = A 族下标** (CEquipmentBonus attrition reader 实证, equipmentbonus.cpp:274); **def+8 = 存档 lexer token** (attrition 发射键, 与 +24 sso 名并行两通道) |
| 成就单例 | `rp(BASE+53575824)` (0xA8B) | 门 = qword@sing+8 非零; RB 树@sing+0; 节点键 MSVC@+32; 条目 vector {begin@+64, count@+76}; 解锁门 u8@+33, 名 MSVC@+40; 块 writer 0X1401F27F0; 复原流程 sub_14061DCB0 |
| ai_focus 静态枚举 | token 13447-13454 (+13820) | 8+1 固定 focus 非表; country.ai 合法性门 |
| unit_leader 特质库 | 0x332f0d0 | trait NullObject 0xA90 全字段 |
| 勋章库 | 0x332f0c8 | medal 名串 def+24（writer 同源, 免 token 反查）; 单例槽 = **BSS 零初始化堆指针槽** (boot_registry: 88B / ctor sub_140AE1830 / creator sub_140173F00), 载 `common/unit_medals` (loader 0x14018B960, 调用点 = 内容注册总入口 sub_14018BB20); 运行期由 creator 建堆单例 |
| MIO org 名解析闭环 | 0x332ef48 | token@+56 创建时拷 org+64（运行时读 +96/+128 不变） |
| 内容注册总入口 | sub_14018BB20 | 登记三元组 = malloc(size)→ctor→store 0x1433xxxxx 槽; 离线产线产 `ref/boot_registry.tsv` (320 槽, boot 链内 169 = 全库宇宙, 带 ctor 54; 103 key 规格表命中 101, 未中 2 = `name` 库 store 形态为 `*(_QWORD *)&slot =` 不匹配扫描正则 (19 引用手证槽在) + `entry` 伪槽 RVA 0x170 非库地址); 创建习语三形态 (内联/独立 creator/工厂·shared_ptr·自登记), 版本迁移按槽位+ctor 签名 join |
| Null Object 哨兵 | 38 个 | arr[0] 身份校验锚; gs 双 vtable@+0/+8, ctor 0X1401BF930; reload 总线头 off_143085170 = gs+2592 与新库壳+96 共用 |
| CEquipmentGroupDatabase | qword_14332EED0 | 装备组库 (vtable RTTI 直证, TReloadableGameItemDatabaseSpecific 链): 条目 vec@+96 / cnt@+108 / 项 token@+8; = bonus_type 值域第四数据源 — 合法值 = 装备 type ∪ archetype ∪ category ∪ equipment_group 四源并集 (CSpecificEquipmentBonus Load 校验消费, 缺项报错由 token 10987 给出); raids 装备名判定第三站 (依次查 CEquipmentDatabase 单例 0x332EEC0 → 类别注册表 → 本库, 全 miss 报 "is neither a type, an archetype, a category nor an equipment group"); ⚠ 与 §4.26.4 equipment_group 行所记单例 0x3330480 冲突 (该址 = CAgencyUpgrade TNullObject, §4.26.8a), 真身槽待裁 |
| COnActionDataBase | TGameItemDatabase 形态 (ctor 直证: 桶@+8/+16, count@+32, hash 向量@+40) | on_action 静态库; **非 CPersistent** 无 serfam 指纹, savegame 负定案定案 |
| CMapArrowManager 定义库 (地图箭头/符号) | `LoadDefinitions<CMapArrowManager>` 链 (与 §4.00 CFileWatcher 行同源) | 4 成员定义件均为 CPersistent 9 槽标准壳、**writer = CFG 空桩 (只装不存)**: CMapArrowDefinition (vtable 0x1429A6348, reader 0x14126A800; loader 组合 Button/Text 子件) / CMapArrowButtonDefinition (vtable 0x1429A62F8, reader 0x14126A680; tok 27/76/225/13075/15784 → 串入 +8/+40/+80/+84) / CMapArrowTextDefinition (vtable 0x1429A62A8, reader 0x14126AD90; tok 30/89/11861 三串) / CMapSymbolDefinition (vtable 0x142A3FD28, reader 0x141B1FA40; tok 27/47/143/415/11861 + +112 内嵌 STextDef 子类) |
| graphical_culture 库 Null 哨兵 | CNullGraphicalCultureType (vtable 0x14293C058 11 槽) | CPersistent 族但 writer 空桩、reader 复用基 0x1424BEC40; 槽[9] 0x14067D3E0 只回吐内嵌名串 — 与 CNullAI*DatabaseEntry 同形态 |

**CNull\* 空对象族机制 (定案)**: `CNull<真类>` = **外壳对象 (Null vtable) + 内部真实控件对象 (独立 malloc, 尺寸 = 真类 ctor 尺寸)**, 并把 `TNullGuiObjectTrait<CNull<真类>>` 作为**尾基子对象**挂进外壳 (RTTI mdisp 即 trait 偏移)。ctor 统一形: `v = malloc(真类尺寸); v = 真类 ctor(v, …); 外壳初始化(内层 v); 外壳 vtable ← CNull<真类>; 外壳 vftable 双写 (+0/+…); 外壳[trait_mdisp] = &TNullGuiObjectTrait<…>;` → **语义 = 「接口非空但行为全空」的兜底控件**, 由 GUI 查型失败路径返回; 无独立状态、无 RTTI 新族、非 CPersistent。**负定案**: 该族**不需要逐类字段表** — 状态全在真类对象内, Null 外壳仅换表 + 挂 trait; 族级信息即下表。

| 类 | 主 vtable | ctor | 内层 malloc | trait mdisp |
|---|---|---|---|---|
| CNullButtonStandard | 0x142B54788 (+次 0x142B54B38) | 0x142377F10 | 0x378 (888) | 528 |
| CNullCheckBox | 0x142B55320 (+次 0x142B555B0) | 0x142378120 | 0x378 (888) | 472 |
| CNullDropDownBox | 0x142B57588 | 0x1423783A0 | 0x150 (336) | 2848 |
| CNullEditBox | 0x142B558B0 (+次 0x142B55B40) | 0x142378440 | 0x180 (384) | 632 |
| CNullExtendedScrollbar | 0x142B571F0 (+次 0x142B57470 / 0x142B57500) | 0x142378500 | 0x1F8 (504) | 5664 |
| CNullButtonDrag | 0x142B54B80 (+次 0x142B54F08) | 0x142377D50 | 0x378 (888) | — |
| CNullBrowser | 0x142B555F8 | 0x142377CA0 | 0x130 (304) | — |
| CNullInstantTextBox | 0x142B55BD8 | 0x142378750 | 0x1D0 (464) | — |
| CNullIcon | 0x142B55EA0 (+次 0x142B56258) | 0x1423785B0 | 0x140 (320) | — |
| CNullContainerWindow | 0x142B562A0 (+次 0x142B56518) | 0x142378300 | 0x598 (1432) | — |
| CNullSmoothListBox | 0x142B56E48 (+次 0x142B56F40) | 0x142378A50 | 0x268 (616) | — |
| CNullStandardGridBox | 0x142B567B8 | 0x142378C70 | 0x1D0 (464) | — |
| CNullStandardListBox | 0x142B56A78 (+次 0x142B56BA8) | 0x142378D10 | 0x268 (616) | — |
| CNullTrack | 0x142B54F50 (+次 0x142B552D8) | 0x142378F20 | 0x378 (888) | — |
| CNullOverlappingElementsBox | 0x142B57828 | 0x142378940 | 0x130 (304) | — |
| CNullGraphicalObject | 0x142B58358 | 0x14011A310 (静态初始化) | — | — |
| CNullKeyBoard | 0x142B3C978 (+次 0x142B3C9C8) | 0x142230E80 | (共用基 ctor) | — |
| CNullTouchDevice | 0x142B3C798 | 0x142230E80 | — | — |
| CNullIdler | 0x142B41808 | 0x142297F70 | — | — |

> 非 GUI 同族旁证 (同 TNullObject 模式): `CNullSavedEventTarget` (0x1427BDF68, 基 `CSavedEventTarget`+`CPersistent`) / `CNullAIEquipmentRoleDatabaseEntry` (0x1427DFA70, 448B) / `CNullAIAttitude` (0x1427E0768) / `CNullAIRoleDatabaseEntry` (0x1427E0A40) / `CNullAIStrategyPlanDatabaseEntry` (0x1427E1A00) / `CNullAIFocusDatabaseEntry` (0x1427E21D8) / `CNullCombatTactic` (0x1427E6588) / `CNullCustomMapMode` (0x1427EAA78) / `CNullAIEquipmentDesignEntry` (0x1429C71F0) / `CNullAITemplateEntry` (0x1429C7A38) / `CNullSysInfo` (0x142B51610) / `CNullMouse` (0x142B3C9F0 等 5 表) / `CNullLogger` (0x142B91D40)。

负结论（停止寻找）:

| 项 | 结论 | 证据 |
|---|---|---|
| 军衔名 | 无注册表 | 无 ranks 目录/RankDatabase, 走 localization |
| 天气 | 无独立运行时注册表 | 编译期 enum |
| 补给 | 无独立省注册表 | hub=省建筑 supply_node, 摩托化等级 50000/100000 内联 0X14194D5F0, 基数 = define SUPPLY_HUB_FULL_MOTORIZATION_TRUCK_COST |

#### 4.26.8a 数据库 TNullObject\<T\> 空对象族 (null_object.h 定案)

与上 GUI `CNull\<X\>` 外壳族**同模式不同机制的平行族**: `TNullObject<T,T>` (RTTI 双参恒同) = **真类布局单层对象** (无外壳/内层双层、无 TNullGuiObjectTrait 尾基), 创建 = **覆写形四步 50/50 (CNullCustomMapMode 为单槽简化变体: 仅覆写 +0、无尾旗清 0 步、对象无有效旗字段 — 176B 全字段定性)**: `malloc(真类尺寸) → 真类 ctor 完整构造 → TNullObject vftable 覆写 +0[+8/+16] → 尾部有效旗清 0`。**创建期字段完备性 (定案)**: 步骤②与③之间 Null 对象已具**真类全字段** — MSVC string SSO 三元组 (cap 15@+48 / size 0@+24 / 数据清零) + id −1@+56 + 名串 ctor@+64 (CAgencyUpgradeBranch 创建点直证) — 「空」仅由步骤④有效旗清 0 + vtable 换装表达 (「空在状态不在方法」的字段层直证)。**vtable复制律 (定案)**: Null vtable = 真类vtable的**函数槽级复制, 仅 RTTI COL 换名** — 50 类中 38 类槽 100% 全同 / 11 类仅 [0] dtor 换轻量版 / **次vtable全覆写 ≥3 类** (CAIStrategyDatabaseEntry / CTechnologyTemplate +8 槽 / CIdea +16 槽 — 多继承双 vptr 布局, ctor 直证); CPersistent 系 9 函数槽对齐 §4.00.1 ([2] writer = CFG 空桩 = 不落盘, 静态库条目本就不存盘)。**方法桩三形态**: 全空桩全语料仅 CNullCombatTactic [10] 一例 (`return 1`→`return 0`, 空战术不可被选); 回默认值桩 = 轻量 dtor + 共享空桩槽; 其余全部有逻辑 — **本族「空」在状态不在方法** (有效旗 0 / id −1 / 空名 token, 消费端靠旗位短路); 「行为全空」表述仅适用 GUI 壳形族。断言: 全局门 byte_1435E1B52 + 帮手 sub_1424C8080 (六参 `(name, file, line, flag, &out_byte, &per_site_flag_byte)`, 先过全局回调门 qword_1435E1B58 再入 sub_1424C8160 四态机 — 四态语义未展开); 行 140 = 创建后非空断言 (22/22 创建宿主全用 140) 并被部分纯 getter 复用 / 行 133 = 纯非创建断言; 行号不区分 getter/回退/消费者角色 (72 个 only-140 函数中 50 个不创建); 具名锚 = **`CNullDifficultySetting::Get()`** sub_1409B8900。规模: **50 模板实例落 51 全局单例** (CTechnologyTemplate 双例 0x590/0x58 同vtable不同内层), 126 函数角色矩阵 = P 工厂宿主 22 / G 纯 getter 48 / F 回退访问器 12 (含索引回退形 sub_14071F2B0: `idx∈[0,cnt)` 越界才走空对象) / C 消费者 44 (G/F/C 计数系语义判据; 可复现启发式 = 体长 ≤45 + 签名实参, 得 G 38 / F 13 / C 53 — P=22 精确吻合, G/F/C 差异 = 判据口径, 未决); 消费语义 = **各数据库 arr[0] 越界/缺省回退哨兵的实体** (§4.26.4 末同源); 消费形态三类 (定案) = **a 默认字段嵌入** (null 单例写新对象字段作缺省后再虚调用, 例 CIdeologyGroup null @ 关系工厂 sub_140D1EE80 新对象 +80) / **b 调用实参传递** (例 CBookmark null 作 ingame 右键调试菜单 idler sub_140DD3A50 的 vtable[104] 实参) / **c 局部默认 + 库装配** (例 sub_140FCA410)。arr[0] 哨兵守卫断言原文 = gameitemdatabasehelper.h:22 "Array should be at least 1 element, did you forget to add the Null Object as Array[0]?" (GetItem sub_140AE2E50: idx <1 ∨ ≥count@+12 → arr[0])。

**簇级新律 (全量切片定案)**: ① **工厂宿主律** — Null 单例创建点内联在各库 ctor 内 (P 形宿主 **22**, 全表见下; 懒建 `if (!qword)` 守卫; 「20 库映射」= TGameItemDatabase 派生库口径, 与 22 的差 = 判据含/不含无该 vtable 直证宿主 — CSubUnitDatabase 仅 TNullObject 直证, 口径对齐未决); 同一 Null 可**多宿主懒建** (CTechnologyTemplate 主例由 CIdeaDatabase ctor sub_140A3F6E0 与 CTechnologyDatabase ctor sub_140ACA4A0 两处建, 先到先得; 簇内 **32/50** 槽被 ≥2 函数断言, 峰值 qword_14333A210 CSubUnitDefinition **11** 宿主 / CIdea 与无名 48B 件各 7)。② **全簇断言律** — 126/126 函数全内联 null_object.h 断言, **136 站点**分布 = 118 函数 ×1 / 6 函数 ×2 / 2 函数 ×3 (多站点 = 多 null 库 ctor); 每函数只用一个行号 (0 混用, 无第三行号): 函数级 only-133 ×54 / only-140 ×72, 站点级 133 ×54 / 140 ×82 (⚠ 4 站点行号被 IDA 作 `0x8Cu`/`0x85u` hex 编码, 十进制 grep 漏计)。③ **多副本旗字节律** — 同一单例指针共享而断言旗字节 per-instantiation: 簇内口径 = 50 个被断言单例中 **26** 个可见 ≥2 旗字节 (簇内 76 旗字节, 1.52/槽); 全语料口径为 43 单例中 18 个 ≥2 — 两口径未统一, 全量值应更大 (待全语料复核); 近旗 0x14333xxxx 主副本 / 远旗 0x14338xxxx~Dxxxx 其他 TU 副本; **旗字节非布局字段, 禁当对象偏移消费**。④ **断言名参数化三态** — `_pInstance` ×136 / `_pTerrainType` ×1 (CTerrainType) / `_spirit` ×1 (country spirit 域)。⑤ **vtable 清零伴件第二例 = 0x14333A0C0** (336B, sub_140ABB910 内建: vptr 写 0 + MSVC 串 cap15@+48 + int −1@+32 + 旗 +40 + 357 哨兵@+44 + 名串 ctor@+56; 两例各配访问器 sub_140BD90B0 / sub_140ABD5A0); 伴件同样纳入断言协议 — 0x14332F990 亦带行 140 创建断言 (flag byte_14333A234, 断言覆盖 ⊃ TNullObject 实例)。⑦ **P 宿主断言挂载点律** — 行 140 断言只挂被推入宿主库条目数组 arr[0] 的那个 null; 同 ctor 创建但**不推入**的伴生 null 不带在宿主断言, 其断言落专属 getter (直证 = CMessageHandler ctor sub_140A67A20: CMessageTypeSettings 0x10 (+8 旗清 0, 不推入, 无在宿主断言) / CMessageType 0x90 (+16, 推入 arr[0], flag byte_143339E68); 前者断言在 sub_1415783F0)。⑥ sz 补齐六项: CStateCategory 336 / CTechnologyFolder 208 / CUnitLeaderSkill 456 / CCountryLeaderTrait 512 / CCareerProfileRibbon 328 / CCareerProfileMedal 560; **CTechnologyFolder 系 TNullObject 模板实例** (208B, 覆写 +0)。

实例台账 (50 实例 + 伴随件; 槽/尺寸 hex; 访问器括注断言行):

| 槽 | T (真类) | sz | 真类 ctor | 访问器 |
|---|---|---|---|---|
| 0x14332F350 | CBookmark | 0x190 | sub_14067BE30 | sub_1401DBBB0(140) |
| 0x14332F990 | CTechnologyTemplate (小例) | 0x58 | sub_140ACACF0 | sub_1403202C0(133) — **非 TNullObject 模板实例 (定案)**: vptr 槽写 0 纯数据记录 (MSVC 串 +32/−1 双 int + 旗 +48) 推入 folder-entry 向量, 归 vtable 清零伴件形第三例; 创建断言 = ctor sub_140ACA4A0 行 140 (flag byte_14333A234) — 断言协议覆盖 ⊃ TNullObject 实例 |
| 0x14332FB10 | CIdea | 0xD10 | sub_140FCCEA0 | sub_1403697C0(140)/sub_140A429F0(140) |
| 0x143330368 | CStaticModifier | 0x220 | sub_140556430 | sub_140559230(133) |
| 0x143330440 | CAbility | 0x550 | sub_140612DC0 | sub_140613470(133, 消费者) |
| 0x143330478 | CAgencyUpgradeBranch | 0x58 | — | 内联消费 |
| 0x143330480 | CAgencyUpgrade | 0x270 | sub_140622760 | 内联消费 |
| 0x1433304E8 | CAIStrategyDatabaseEntry | 0xD50 | sub_14064B640 | sub_140647EA0(133) |
| 0x143330690 | CIdeologyGroup | 0x650 | sub_1424BE3C0+内联 | sub_141191580(133)/sub_14067D410(140) |
| 0x1433306A0 | CBuildingTemplate | 0x510 | sub_1406817A0 | sub_140686BF0(133)/sub_140687470(140) |
| 0x1433306A8 | CBuildingSpawnPoint | 0x60 | — | sub_1416733F0(140)/sub_1406873F0(140) |
| 0x143330B88 | NCareerProfile::CCareerProfileMedal | — | sub_1406AB120 | sub_14201B100(133) |
| 0x143330BA0 | NCareerProfile::CCareerProfileRibbon | — | sub_1401C1640 | sub_14201B180(140) |
| 0x143330C60 | CCharacterTemplate | 0x248 | sub_1413F0A00 | sub_1406BC7D0(133) |
| 0x143330C68 | CAdvisorTemplate | 0x438 | sub_1413DECC0 | 内联消费 |
| 0x143330C70 | CCountryLeaderTemplate | 0x90 | sub_1406BB370 | — |
| 0x143330C78 | 无名 48B 件 (vtable 清零, 非模板实例) | 0x30 | sub_14139CBD0 | sub_140BD90B0(140) |
| 0x14333A0C0 | 无名 336B 件 (vtable 清零, 非 TNullObject 实例) | 0x150 | 内联于 CStateDatabase ctor sub_140ABB910 | sub_140ABD5A0(140) |
| 0x143330DA8 | CCountryLeaderTrait | 0x200 | sub_1401511B0 (宿主 CCountryLeaderDatabase ctor sub_14071D4F0 内联全字段构造: 名 SSO@+24 / id −1@+56 / script@+64 / 内嵌 CModifier@+152 / 向量 @344/368/392 / −1@+420 / 4 桶 modifier@+456) | sub_14071F2B0 (索引回退形 133) |
| 0x143330DB8 | NCountry::CMetadata | 0x50 | sub_140720410 | — |
| 0x143330DD8 | CDecisionCategory | 0x3F8 | sub_1407235F0 | sub_14072DCA0(140) |
| 0x143330DE8 | CPowerBalance | 0x190 | sub_140E54EE0 | sub_140E56730(133)/sub_14072DD20(140) |
| 0x143330DF8 | CDecision | 0xD38 | sub_140722F50 | 内联消费 |
| 0x143339B18 | CDifficultySetting (具名 CNullDifficultySetting) | 0x78 | sub_1409B7F30 | sub_1409B8900(133) |
| 0x143339B40 | NDLC::CMetadata | — | sub_1409CA7E0 | — |
| 0x143339BA0 | CStateTemplate | 0x1D0 | sub_140ABBEE0 | 内联消费 |
| 0x143339BA8 | CStateCategory | 0x150 | sub_1424BE3C0 + 内联于 CStateCategoryDatabase ctor sub_1413C3EA0 | sub_1409D9200(133) |
| 0x143339BE8 | CEquipmentType | 0x5C8 | sub_140C922A0 | sub_1409F8570(140)/sub_141490900(140) |
| 0x143339BF0 | CEquipmentUpgrade | 0x160 | sub_1415373A0 | 内联消费 |
| 0x143339BF8 | CEquipmentModule | 0x2D8 | sub_1409F00C0 | sub_140C95660(133) |
| 0x143339CA0 | CWarGoalType | 0x338 | sub_140A39D10 | sub_141C8F9E0(140)/sub_140A3B3E0(133) |
| 0x143339CD8 | CTechnologyTemplate (主例) | 0x590 | sub_140ACACF0 | sub_140AD0A80(140) |
| 0x143339CE0 | CIdeaCategory | 0x88 | sub_140FCD560 | sub_140A420D0(140) |
| 0x143339CE8 | CIdeaGroupType | 0x78 | sub_140FCD690 | sub_140A42A70(133) |
| 0x143339D00 | CIdeology | 0x140 | sub_141190B80 | sub_140A48480(133) |
| 0x143339E30 | CUnitLeaderTrait 域伴随件 | 0xD8 | sub_141408430 | — |
| 0x143339E58 | CMessageTypeSettings | 0x10 | sub_1415780B0 | sub_1415783F0(140) |
| 0x143339E60 | CMessageType | 0x90 | sub_141577E30 | 内联消费 |
| 0x143339E80 | COnActionList | 0xD8 | sub_1424CFAD0 | 内联消费 |
| 0x143339EB8 | COpinionModifier | — | — | sub_140A81F60(133) |
| 0x14333A068 | CPowerBalanceTemplate | 0x198 | sub_140E54EE0 系 (内联) | — |
| 0x14333A070 | CPowerBalanceSide | 0x120 | sub_140A8B8C0 | sub_140E57000(140) |
| 0x14333A078 | CPowerBalanceRange | 0x740 | sub_140A8B6D0 | sub_140A8D660(140)/sub_140E56F80(140) |
| 0x14333A0B0 | CScriptedTriggerTemplate | 0x88 | sub_140549F40 | 内联消费 |
| 0x14333A0D8 | CStrategicRegionTemplate | 0x150 | sub_1415A3DF0 | 内联消费 |
| 0x14333A0E8 | CStrategicResource | 0x110 | sub_140BCA520 | sub_140AC26A0(133) |
| 0x14333A208 | CSubUnitCategory | 0x70 | sub_141017F70 | 内联消费 |
| 0x14333A210 | CSubUnitDefinition | 0x678 | sub_141018F60 | sub_140AC4DD0(140)/sub_140B9E9C0(133) |
| 0x14333A228 | CTechnologyFolder (非 CPersistent 2 虚槽小类) | — | sub_1424CFAD0 | 内联消费 |
| 0x14333A248 | CTerrainType | 0x200 | sub_14143BB90 | sub_140AD6B30(133) |
| 0x14333A250 | CTerrainGraphics | 0x70 | sub_14143BA60 | 内联消费 |
| 0x14333A278 | CUnitMedal | 0x430 | sub_141446280 | 内联消费 |
| 0x14333A288 | CUnitLeaderSkill | 0x1C8 | 内联于 CUnitLeaderDatabase ctor sub_140AE3250 | sub_140AE9C50(140) |
| 0x14333A2A8 | CUnitLeaderTrait | 0xA90 | sub_140AE3980 | sub_140AE9CD0(140) |
| 0x14333D528 | idpair 哨兵 (数据槽非对象, 2567 处读引用零写者) | — | — | — |

> CTechnologyTemplate 双例语义已定案: 主例 0x590 = 模板实例, 小例 0x14332F990 = vtable 清零伴件 (非模板实例, 见台账行注)。sub_1405566B0 = __unwind 析构位清理函数 (CModifier 系), 曾误记为两类 ctor — 已改。消费域代表: 书签 UI (CBookmark) / 外交关系视图 (CIdeologyGroup/COpinionModifier) / 装备 MIO (CEquipmentType/Module) / 科技理念 (CTechnologyTemplate/CIdea 族) / 难度设置 (CDifficultySetting) / 州模板校验 (CStateTemplate 族) / 聊天设置 (CMessageType)。

工厂宿主全表 (22 P 形 ctor, 创建点内联处; P 宿主统一尾部协议 = null 创建后推入库条目数组 arr[0], `count==cap → cap×1.5+1` 扩容, 再行 140 断言 — 断言只挂推入者, 见律⑦):

| 宿主库 ctor | 创建的 null (槽 / 尺寸 / 尾旗) |
|---|---|
| CAgencyUpgradeDatabase sub_140622A00 | 0x143330478 CAgencyUpgradeBranch 0x58(+16) + 0x143330480 CAgencyUpgrade 0x270(+16) |
| CBuildingDatabase sub_140681090 | 0x1433306A0 CBuildingTemplate 0x510 + 0x1433306A8 CBuildingSpawnPoint 0x60 |
| NCareerProfile::CMedalDatabase sub_1406AAE10 | 0x143330B88 CCareerProfileMedal 0x230 |
| NCareerProfile::CRibbonDatabase sub_1406AF690 | 0x143330BA0 CCareerProfileRibbon 0x148 |
| CCountryLeaderDatabase sub_14071D4F0 | 0x143330DA8 CCountryLeaderTrait 0x200 |
| CDecisionDatabase sub_1407238C0 | 0x143330DD8 CDecisionCategory 0x3F8 + 0x143330DF8 CDecision 0xD38 |
| CDifficultySettingsDatabase sub_1409B8140 | 0x143339B18 CDifficultySetting 0x78(+8) |
| CEquipmentDatabase sub_1409EF930 | 0x143339BE8 CEquipmentType 0x5C8 + 0x143339BF0 CEquipmentUpgrade 0x160 + 0x143339BF8 CEquipmentModule 0x2D8 |
| CWarGoalDatabase sub_140A39A70 | 0x143339CA0 CWarGoalType 0x338 |
| CIdeaDatabase sub_140A3F6E0 | 0x14332FB10 CIdea 0xD10 + 0x143339CD8 CTechnologyTemplate(主例) 0x590 + 0x143339CE0 CIdeaCategory 0x88 + 0x143339CE8 CIdeaGroupType 0x78 |
| CMessageHandler sub_140A67A20 | 0x143339E58 CMessageTypeSettings 0x10(+8, 不推入) + 0x143339E60 CMessageType 0x90(+16) |
| COnActionDataBase sub_140A75A40 | 0x143339E80 COnActionList 0xD8 |
| CScriptedTriggerTemplateDatabase sub_140AB5880 | 0x14333A0B0 CScriptedTriggerTemplate 0x88 |
| CStateDatabase sub_140ABB910 | 0x143339BA0 CStateTemplate 0x1D0(+168) + 0x14333A0C0 伴件 0x150(非 TNullObject) |
| CStrategicRegionDatabase sub_140ABFD90 | 0x14333A0D8 CStrategicRegionTemplate 0x150 |
| CStrategicResourceDatabase sub_140AC1AB0 | 0x14333A0E8 CStrategicResource 0x110 |
| CSubUnitDatabase sub_140AC4570 | 0x14333A208 CSubUnitCategory 0x70 + 0x14333A210 CSubUnitDefinition 0x678 (无 TGameItemDatabase vtable 直证, TNullObject 直证) |
| CTechnologyDatabase sub_140ACA4A0 | 0x143339CD8 CTechnologyTemplate(主例) 0x590 + 0x14332F990 小例伴件 0x58 + 0x14333A228 CTechnologyFolder |
| CTerrainDatabase sub_140AD5920 | 0x14333A248 CTerrainType 0x200 + 0x14333A250 CTerrainGraphics 0x70 |
| CUnitMedalDatabase sub_140AE1830 | 0x14333A278 CUnitMedal 0x430 |
| CUnitLeaderDatabase sub_140AE3250 | 0x14333A288 CUnitLeaderSkill 0x1C8 + 0x14333A2A8 CUnitLeaderTrait 0xA90 |
| CStateCategoryDatabase sub_1413C3EA0 | 0x143339BA8 CStateCategory 0x150 |

字段事实增补 (创建点直证): ① vptr 覆写位随多基而变 — 单基 +0; CDecisionCategory/COnActionList 双写 (+0/+8 与 +0/+16); CDecision 三写 (+0/+8/+24)。② 尾部有效旗偏移逐类非恒尾: CSubUnitCategory/CDifficultySetting/CMessageTypeSettings +8 / 多数 +16 / COnActionList +24 / CBuildingTemplate +32 / CScriptedTriggerTemplate +88 / CStateTemplate +168 / CDecision +280。③ CBuildingSpawnPoint null 携带 357 哨兵 @+84 (qword)/+92 (dword), 消费端 `*(v+4)!=357` 才走真解析 (357 = "无 spawn point" token 哨兵)。④ 消费者 UI 缺省选中槽 = 条目 +1328 (wargoal/subunit 两类 GUI 项同偏移, 可作型别锚); 查名落空回退形例 = power_balance 库 (RH stride 456, miss→null)。⑤ idpair 哨兵槽 0x14333D528 具名消费者之一 = sub_1414D8F00。

#### 4.26.8b 静态修正库双视图与动态修正查重清扫器 (modifier.cpp; 3 函 — 新收)

静态修正库 qword_143330098 双视图 (定案):

| 视图 | 函 | 库 getter | 布局读法 | 未命中 |
|---|---|---|---|---|
| 哈希 | 0x14055D480 | sub_1405574B0 = sub_140558710() **懒初始化**后返库 | 桶数 u32@+4 / 桶数组@+8, 分离链节点 {value ptr@+0, next@+8}; 值对象名串 @+424 (size@+440 / cap@+448, MSVC 32B 串) | modifier.cpp:2455 "missing static modifier definition: %s" → 兜底单例 |
| 平坦数组 | 0x14055D580 | sub_14055B160 **直读** (无懒初始化) | data@+16 (元素 = 指针) / count i32@+28 线性扫; 元素名串 @+88 (size@+104 / cap@+112) | modifier.cpp:2474 "invalid modifier %s" → 同一兜底单例 |

> 两视图共用同一库对象 qword_143330098, 未命中**共回退同一** TNullObject\<CStaticModifier\> 单例 0x143330368 (sub_140559230, §4.26.8a 行 133 访问器)。⚠ 两视图值对象名串偏移不同 (+424 vs +88) ⇒ 至少两类对象共存于同一库, 哪个是 544B CStaticModifier 未验 (待裁)。**GUI 单行消费点 (直证): mode 3 operatives 州情报网 tooltip** 两段 EFFECTS_FOR_COUNTRY 各以 +272/+280 视图构 120B 描述符 (sub_14055B010, 默认值槽 +56 = 1e5), 值槽覆写为覆盖率 (strength×1e5÷1e7), sub_140A75780 写自定义文本 + 置 +96 旗, sub_140A73300 → sub_14055AB90 渲染。书既有引用 (§4.3 def 字段桥 / §4.32 has_relation_modifier 与 power_balance 校验槽) 均为哈希视图 0x14055D480。

**动态修正查重清扫器 0x14060C6B0 (高置信; 管理器类名待裁)**: a1 管理器布局 = {+264 已登记集合 (sub_14055F740 contains 查询) / +440 216B 条目数组 (count i32@+452, 步距 54 dword; 元素 dword[0] = 修正 id) / +472 RH 表 (键 = dword[0] 双轮雪崩哈希, P = 73244475, §4.16 RH 表同族; sub_140553120 探测, out = 既有条目 + 命中旗) / +488 条目总计数}。流程: 逐条目哈希探测 → 命中 ∨ 在 +264 集合 → modifier.cpp:2668 "Modifier set twice for the same dynamic modifier: %s line %d - %d" → **224B 块移位擦除** (块 {dword@0, u8 计数@4, dword@8, 子对象@16}; 拷贝 ctor sub_14015A370 / 析构 sub_1401545F0; 循环条件 = 下一块计数 byte > 1, 每块计数 −1) → 末块析构 + 计数 byte 清 0 → `--*(a1+488)`。

#### 4.26.9 验证体系

| 层 | 工具 | 覆盖 | 基线 (KR2) |
|---|---|---|---|
| L1 不变量电池 (实现侧校验脚本, 非本节数据) | 逐库不变量 | 81 key 逐库: count 恒等式（cnt@76==lookup.size@52+1, 显式标准族）/名字净度（控制字节）/token 有效域/双向 roundtrip/Null 语义 | 80 绿 + gamerules 特形豁免; building 恒等式分歧=信息级 |
| L2 内容文件对账 | `staticres_l2.py`（replace_path 感知层叠） | 32 库映射: 25 名字级 + 4 计数级（ability/ai_area/focus_inlay_window/scripted_diplomatic_action）+ 3 跨库名白名单 | **29 MATCH / 3 SKIP / 0 DIFF**（SKIP: ai_strategy 无访问器 / country_scorer 引擎按需注册 9/19 / gamerules 选项值库） |
| L2c 顺序对账 | 探针（可升格） | 引擎保留文件定义序（文件字母序×文件内序）: state_category 18 名逐位一致; building/opinion_modifier 序一致仅差 *_spawn 伪条目 | 可行，未自动化 |
| L2d lookup 哈希自洽 | `staticres_lookup_probe.lua` | lookup{MSVC@+0, hash u32@+32} 逐条 fnv(lower(name))==hash + lookup↔arr 名集 | 5 库全绿（含 country_leader 2222 条） |

- **必跑时机**: 游戏版本变更、resource.lua 规格表改动、新库挂 key。
- 报告/枚举输出至 mod 侧 tools 目录。
- 对账深化方向（未决）: L2e 字段级值对账（需逐库 def 对象布局 RE，建议只对
  有消费者库做）；存档引用对账（save 引用 token ⊆ 库名集）。

#### 4.26.10 CTweakable 调试值控件族 (引擎活体调参系统)

**引擎内嵌 Dear ImGui 调试面板族** (与 CTweakable 并列的调试基建): 上下文全局 = qword_143451C80; 函数区 0x1421C-0x1421F/0x14213/0x14214/0x14228 (AI weights tuner sub_1421ED790 数值动画 tick / fronts visualizer / AI Templates / CEvolveTankImgui / tweaker window ×2, 字符串键注册 sub_1421CBE30); 调试视口状态含坐标钳位 ±256000 (@+76/+77 当前坐标 float, +304 镜像, +2044/+2045 取整缓存 — sub_1421DDEC0)。非 gameplay 操作面 (release 面板可见性未验)。

> **qword_143451C80 身份裁定 (定案, 高置信): = ImGui 上下文全局 ImGuiContext\*** — 四证据: ① input_touch.cpp 两函零引用该单例 (否定证据); ② 全语料 1458 处引用按函数分桶, **1454 处集中 ImGui 函数区 0x1421C-0x1421F**, SDL 泵 0x1420B 系 / 触屏层 0x14238 系 / 后端初始化 0x14208 系均零引用 (决定性); ③ 0x1422095C0/0x14220D530 两例为深层 ctx 子结构导航形态 (ctx+6768→+128 写 / +6432 读; **确名已收 = ctx+6432 = g.Font / +6440 = g.FontSize / +6768 = g.CurrentWindow (+128 = WriteAccessed 推定, +131 = SkipItems) — dg036 InputTextEx 本体定名**); ④ §4.00.25 实测偏移按「ctx+8 = ImGuiIO」换算与 imgui.h 输入段成员序逐项自洽 (MouseDown→Wheel→WheelH→KeyCtrl..Super→KeysDown)。§4.00.25 原「触屏输入后端单例」命名废, 该节偏移保留、语义改写为 ImGuiIO 喂入; +920/+921 丢事件旗在 ImGuiContext 布局下重锚未决 (PDX 扩展态候选)。

管理器双单例 (定案):

| 项 | 值 |
|---|---|
| 名桶注册表 | 懒建单例 qword_1435E1A90 (0x40B: +8 桶数组基址, +48 mask 初值 7 = 8 桶起步, +0 float 1.0); getter sub_1424B84D0 |
| 插序向量 | 懒建单例 qword_1435E1A88 (24B Pdx 向量); getter sub_1424B8620 |
| 注册入口 | sub_1424B6990(obj): +40 键名 FNV-1 (basis 0x811C9DC5, prime 0x01000193) → hash&mask 入桶链 (节点 {+8 next, +16 名串 32B, +48 值串}); **重名调新对象槽[2] SetValue(旧值) = 热迁移**; 再 push 插序向量 |

**CTweakable** 基类 (152B, vtable 0x142B911B0 4 槽; 槽 [1] 值串化 / [2] SetValue / [3] GetType):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | fn ptr | apply/format 回调 (out, input, self) | Bool/Float/Int/Alias 各有具名变体 |
| +16 | uint64 | 附加上下文 1 | 保留槽 (ctor 置零, 无第二写点 — 负定案) |
| +24 | CClass* | 回调上下文 = **引擎变量指针** | 回调内解引用写值 |
| +32 | uint64 | 附加上下文 2 | 保留槽 (ctor 置零, 无第二写点 — 负定案) |
| +40 | string | 注册键名 | FNV-1 输入 |
| +72 | string | 显示名 | |
| +104 | string | 描述串 | 推定 |
| +136 | int | **注册期类别 id** (ctor 形参直落, 非运行期计算; **全库 113 构造站点枚举 = 双值 {0,1}**: 0 = 44 站渲染/音频调试桶, 1 = 69 站玩法调试 + pe_ 编辑器桶, 语义推定; 4 typed ctor Bool/Float/Int 第 5 参 + Alias 第 3 参) | 定案 (取值) / 推定 (语义) |
| +144 | CClass* | **SetValue 读写目标 = 引擎变量指针** | |

typed 派生 (布局同基类, 只覆写三值槽):

| 类 | vtable | SetValue 语义 | GetType | sizeof |
|---|---|---|---|---|
| CTweakableBool | 0x142B91228 | "0"/"false"/"no"=假, 其余=真, 写 +144; 回调空输入=翻转 | 0 | 152 |
| CTweakableFloat | 0x142B91200 | atof 写 +144; **+152/+156 = min/max (推定)** | 1 | 160 |
| CTweakableInt | 0x142B91250 | atoi 写 +144 | 2 | 160 |
| CAliasString | 0x142B911D8 | 串值型 tweak | 3 | 152 |

行控件 11 类 (CTweakerListItem 主表@0 + TListboxItem 次表@56, 各 14 槽, [13]=业务槽):

| 类 | vtable | GUI 工厂名 | 自有字段 (+152 起) | sizeof |
|---|---|---|---|---|
| CTweakableTitle | 0x142AF9C48 | tweaker_titlecomponent | +152 标题串 | 184 |
| CTweakableLabel | 0x142AF9D88 | tweaker_labelcomponent | +152 标签子件 | 168 |
| CTweakableCategory | 0x142AFA0D8 | tweaker_collapsable | +152 类目名 / +232 展开旗 / +256 折叠钮 glue | — |
| CTweakableBoolManipulator | 0x142AFAA78 | tweaker_boolcomponent | +168 勾选钮 glue | — |
| CTweakableIntManipulator | 0x142AFA8D0 | tweaker_slidercomponent | +152 滑条 / +160 回写 glue / +272 目标 | — |
| CTweakableDropDown | 0x142AF9F30 | tweaker_dropdown | +184 目标 / +240 下拉列表 / +248 变量指针副本 | ≫1.5K |
| CTweakableEnumManipulator | 0x142AFA558 | tweaker_listcomponent | +168 目标 / +176 索引哨兵 -1 / +184 选项向量 | — |
| CTweakableGraphManipulator | 0x142AFA3B0 | tweaker_graphcomponent | +152 图子件 / +160 目标 | — |
| CTweakableArrayCurveManipulator | 0x142AFA758 | tweaker_curvearraycomponent | +152 目标 / +392/+400 变量指针与上下文副本 | — |
| CTweakableTextbox | 0x142AFADB8 | tweaker_textboxcomponent | +168 目标缓冲 / +176 编辑串 | — |
| CTweakableCharArrayManipulator | 0x142AFA270 | tweaker_textboxcomponent_long | +152 定长 / +336 目标 | — |

> **活体验证（test1 会话实测）**: 双单例遍历走通、节点名 MSVC 读法逐字命中；侧发现该注册表实为**引擎级通用名值表**，launcher 参数名（http/auto_run/start_save）与脚本 tweak 共表注册。
> **对象句柄路径（清偿定案）**: 节点存值不存对象 = 设计事实；**插序向量 qword_1435E1A88 元素即 CTweakable\***（静态 v20[count]=a1 直证; 运行时 61 对象 = 60 Bool+1 Int, +144 引擎变量指针全非空）；名→对象 = sub_1424B8380 对向量线性名扫（不经桶）；round-trip = 文件值→桶节点值串→按名扫向量→SetValue（载入向闭合, 活体 SetValue FLIP/RESTORE 实测）; **SetValue 只写引擎变量 (obj+144 所指), 不创建不刷新桶节点 = 单向镜像**（写出走遍历插序向量的持久化 writer, 与 SetValue 无关）。
> **桶链细勘（定案）**: 桶数组 16B/槽存首/末节点对; 空桶槽存**外部堆哨兵**地址; 链经哨兵成环（朴素遍历无哨兵判等会无限计数）; **权威节点数 = 表+16 count 字段**; 桶节点唯一写入源 = argv `name=value` 参数注册循环（sub_14207DB70 → sub_14207D560, call site 0x14209E610/0x140126E50）。
> ⚠ **桶节点数与对象数不可比（口径纪律）**: 桶 = 会话期被设值过的参数名值镜像（实测仅 3 个 launcher 参数, 无一对应活对象）; 61 = 编译期固化注册对象数; 「134 vs 61」类样本 = 双表口径差 + 链走过计数叠加（样本本体不可复现, 待裁）。

> GUI 工厂注册锚: ArrayCurve→0x142071040 / DropDown→0x142072650 /
> EnumManipulator→0x142072DC0, 挂全局 0x143316920 名→工厂槽。

#### 4.26.11 建筑/州类目/自治档/占领修正/抵抗活动 def 布局 (元素类实名绑定)

idb 四库 + building 库的元素 def 布局 (全部 vtable[2]=空桩 = 只读 def 不入档; 库挂载状态 = §4.26.4 已挂)。

**CBuildingTemplate** (buildings.txt 建筑 def, ≥1216B; vtable 0x1427E4260; reader 0x1414BB530 ~80 键; 校验器 vtable[7]=0x1414BAB90; 元素库 = building key 0x332EE28 — ⚠ 该 db 内**并存两容器形态** (book 探针的 +64/+76 tok8 表 vs mapbuildings 簇消费的 +112 索引数组/+136 名查表), 两族 def 各居其容器 (模板在 tok8 表、spawn def 在索引数组), 「元素库 =」一句勿按单一形状读; spawn def 形状见 §4.26.11a):

| 偏移 | 类型 | 键 (token) | 备注 |
|---|---|---|---|
| +8 | uint32 | — | db 注册 id (dword; 名另见 +528 loc 串) |
| +40 | 匿名结构 (16B 形状) 向量 | tags (463) — {d@40, c@52}; **元素 = 4B token 值** (活体定案: naval_base → token **31210 `naval_buildings_tag`**; supply_node 同 c=1) | 块 |
| +64 | 匿名结构 (NNB 形状) | country_modifiers (11577) — **校验收集域 @+48** (sub_140559650 收集, 16B 条 [0] = modifier def id; 逐 id 查 qword_14332ED90 表 (stride 120, 名 32B SSO @def+24), def+100 **bit3** 未置 → buildingtemplate.cpp:786 "%s:%i %s is not country modifier!") | 块 |
| +288 | 匿名结构 (NNB 形状) | state_modifiers (16619) — **校验收集域 @+304** (同型; def+100 **bit4** 未置 → :327 "%s:%i %s is not state modifier!"); **modifier def 类别位 u32@def+100: bit3 = country / bit4 = state (两函合证定案)** | 块 (校验: 项须州修正) |
| +504 | 匿名结构 (16B 形状) 向量 | local_resources_* 前缀 | {d@504,c@516} 16B 元 {资源 def id u32, i64 量} |
| +528 | MSVC 串 | — | 本地化键 |
| +560 | MSVC 串 | — | 大写 loc |
| +592 | 匿名结构 (NNB 形状) | missing_tech_loc (18024) | 块 |
| +664 | 匿名结构 (NNB 形状) | specialization (10012) | 块 |
| +688 | SLevelMax 内嵌 (嵌套类 vtable 0x1427E41C0) | level_cap (10768) 块全表: +696 state_max (10769) / +700 province_max (10771) / **+704 shares_slots (13602)** / +708 group_by (13022, 默认 357) / +712 exclusive_with (10120) 容器 {data@+712, count@+724, alloc@+728}; reader = 减法链派发 sub_1414BC5A0 (token 字面量检索对本族失效, 须 vtable[4] 直取) | 共享槽建筑行池排除门 = SetupDerived sub_14174AF00 读 +704 |

**校验器 vtable[7] (sub_1414BAB90, 100 行) 与 SLevelMax 校验器 (sub_1414BAE50, 54 行) 内容补全 (df306, 定案)**: 主校验三门 = ① +988 ≠ 0 (省伤害修正旗) 而 +700 ≤ 0 → :318 `_LevelLimit._ProvinceLimit > 0 && "Error in building script. Building has province damage modifiers but is not a province building."` (成员名 _LevelLimit._ProvinceLimit 与嵌套类名 SLevelMax 为成员/类型两名); ② 州修正收集域逐 id 类别位核 (见 +288 行); ③ need_supply 州建筑门 (见 +882 行)。**SLevelMax 校验 (相对布局 +8 state_max / +12 province_max / +20 group_by, 与绝对 +696/+700/+708 互证)**: group_by == 0 → :669 "Invalid building template group!" **并就地写 357 (默认值直证)**; state_max < 0 / province_max < 0 / province_max > state_max > 0 三门各报错后**就地归零** — 装载容错改写非纯报错。CBuildingTemplate 另增: +528 名 SSO (size@+552) / +48 国家修正收集域 / +304 州修正收集域 (16B 条, [0] = modifier def id) / +988 省伤害修正旗。
| +740 | int64 | icon_frame (12120) | |
| +744 | int64 | base_cost (12094) | |
| +748 | int64 | base_cost_conversion (13606) | |
| +756 | int64 | per_level_extra_cost (14126) | |
| +760 | int64 | naval_production (12123) | |
| +764 | int64 | military_production (12124) | |
| +768 | int64 | general_production (12125) | |
| +772 | int64 | naval_fort (12553) | |
| +776 | int64 | land_fort (12554) | |
| +780 | int64 | rocket_production (12979) | |
| +784 | int64 | rocket_launch_capacity (13298) | |
| +788 | int64 | air_defence (11958) | |
| +796 | uint32 | show_on_map_meshes (12182) | 默认 1 |
| +800 | uint8/uint16 | has_destroyed_mesh (13752) | |
| +801 | uint8 | disable_grow_animation (10046) | |
| +802 | uint8 | only_display_if_exists (16642) | |
| +808 | MSVC 串 | special_icon (16643) | |
| +840 | int64 fixed | damage_factor (13163) | 默认 100000 |
| +848 | int64 fixed | repair_speed_factor (15662) | 默认 100000 |
| +856 | int64 | value (776) | |
| +864 | uint8 | is_buildable (11938) | 默认 1 |
| +865 | uint8 | is_port (12113) | |
| +866 | uint8 | infrastructure (12203) | |
| +867 | uint8 | air_base (12214) | |
| +868 | uint8 | radar (12237) | |
| +869 | uint8 | anti_air (12166) | |
| +870 | uint8 | only_costal (12096) | |
| +871 | uint8 | **`refinery` (12978)** — 磁盘直证 `common/buildings/00_buildings.txt` 的 `synthetic_refinery = { refinery = yes }` | 定案 |
| +872 | uint8 | nuclear_reactor (12980) | |
| +873 | uint8 | disabled_in_dmz (13354) | |
| +874 | uint8 | always_shown (13566) | |
| +875 | uint8 | disable_auto_nudging (17431) | |
| +876 | uint8 | infrastructure_construction_effect (14249) | |
| +877 | uint8 | show_modifier (15314) | |
| +878 | uint8 | fuel_silo (15503) | |
| +879 | uint8 | centered (19886) | |
| +880 | uint8 | supply_node (19646) | |
| +881 | uint8 | allied_build (10187) | |
| +882 | uint8 | need_supply (10578) | 校验: +700 ≤ 0 且 +882 ≠ 0 → :334 "%s:%i %s is state building, but need_supply parameter can be used only with provincial buildings!" |
| +883 | uint8 | (10071 inherit) | |
| +884 | uint8 | need_detection (19201) | |
| +885 | uint8 | naval_headquarter (10193) | |
| +886 | uint8 | naval_supply_hub (10194) | |
| +887 | uint8 | (10352 键 = drawn_at_distance, 原版表有名) | |
| +888 | uint8 | affects_energy (16533) | |
| +892 | uint32 | detecting_intel_type (19532) | |
| +916 | uint32 | 国家映射修正键 (+1464 表查询键; 脚本键名未反查, §4.26.17) | buildingstatus.cpp GetMaxLevel 直证 |
| +920 | uint32 | 州档位表修正键 (档位对象 +16 表查询键; 同上) | 同上 |
| +976 | 匿名结构 (元素待裁) 向量 | state_damage_modifier (10031) 族之一 (province_damage_modifiers 10029→+976 静态修正表); 活体: 仅 dam/dam_mountain/cataract_dam_mountain 三 def 各 1 条, 元素 = 三者**共享**的带 vtable 对象 (vtable RVA 0x2608640 未录 RTTI, +8 = u32 165) | "Could not find static modifier" 直证 |
| +1000 | 匿名结构 (元素待裁) 向量 | state_damage_modifier (10031); 活体: 仅 canal_kiel/canal_panama 各 1 条, 元素 = **32B MSVC 串** ("kiel_canal_damage…" / "panama_canal_d…") | |
| +1048 | 匿名结构 (元素待裁) 向量 | modules (15211); 活体: 仅 naval_headquarters 1 条, 元素 = 16B 全零 | |
| +1088 | 内嵌 CConstructionSpeedFactor | construction_speed_factor (16385) | ≥108B: +8 factor(10603) / +16 trigger(10595) 子对象 / +36 trigger 存在旗 (mandatory); vtable 0x1429CB628 |
| +1204 | uint8 | hide_if_missing_tech (17942) | |
| +1208 | CModifier | dlc_allowed (17943) | CModifier 族名单 |

> 建筑 def 脚本键 `per_controlled_building_extra_cost` 偏移未定, 待裁。
**构建速度因子解析告警** `sub_1419D8D70` (construction_speed_factor.cpp:28, 日志旗 4096): 格式 `<a1>:<a2>-<a3> '<a4>'` (a1 = 建筑类名/上下文串, a2/a3 = 因子 id/触发器 id, a4 = 串细节; 四参语义推定), 推定为 CConstructionSpeedFactor 定义解析侧的重复/非法条目诊断出口。

**CStateCategory** (state_category def; vtable 0x1429BA8D0; reader 0x1413C4D50; 库单例 0x332F968): +8 名 token hash / +24 MSVC 名串 / +64 CColor 子对象 (color 86; 注册进 CState 库色池, **+324 = 色池索引**) / +96 内嵌 CModifier (其余键如 local_building_slots 全落此) / +184 本地化名 / +316 float 0.9。

**CAutonomousState** (自治档 def; vtable 0x1427E3770; reader 0x140678D40): +8 名 MSVC 串 / +40 FNV-1a32 hash / +424 loc 描述串 (三字段唯一写者 = 虚方法 **0x140677F90** (autonomousstate.cpp:97): FNV-1a32 (基 0x811C9DC5 / 素 16777619) 写 +40 → sub_142244840 loc 键存在性校验, 失败 :97 告警 "There is no localization for the autonomous state name: %s" (不中断) → sub_142245E60 格式化经 sub_140129CA0 赋 +424; 与 §4.4 CCharacter vtable[8] sub_140FA43C0 名→hash→loc→缓存三件套同构); 脚本键: default(11405)→+45 / is_puppet(13416)→+46 / use_overlord_color(19107)→+44 / allowed(12263)→+48 块 / modifier(10597)→+336 块 / rule(10876)→+528 块 / can_take_level(14118)→+136 / can_lose_level(14119)→+224 / min_freedom_level(14058)→+193 / cost(10323)→+195 / manpower_influence(15148)→+194 / peace_conference_initial_freedom(15406)→+196 / ai_subject_wants_higher(14121)→+197 块 / ai_overlord_wants_lower(14122)→+204 块 / ai_overlord_wants_garrison(14188)→+1688 / allowed_levels_filter(15403)→+312 名单 / use_for_peace_conference_weight(15407)→+1776 i64 (×100000 缩放)。

**COccupationModifier** (占领修正 def, 0x340 级; vtable 0x1429BA640; reader 0x1413C3290): +8 def id / +16 名 / +48 tooltip(146) / +80 icon(181) / +128 small_icon(19032) / +176 type(225) 枚 (**0/1 = RESISTANCE 档 / 2/3 = COMPLIANCE 档** — tooltip 装配器直证, 各侧两值分档语义待裁; 4 = invalid → 断言 occupation_modifier.cpp:116) / +184 threshold(695) (TO_ENABLE = 值/100 百分点) / +192 margin(630) (TO_DISABLE = (threshold−margin)/100) / +200 alert_level(19364) 三档枚 / +208 alert_margin(19369) 默认 1000000 / +216 visible(11562) 块 / +304 enabled(705) 块 / +392 on_enable(15738) 块 / +480 on_disable(15739) 块 / +568 内嵌 CModifier state_modifier(15741) ({data@584, count@596} 修正 id 清单; +620/+704 内旗作「有节」门) / +760 is_dynamic(10445)。**四 88B 块 (+216/+304/+392/+480) 等距结构**: {vtable@+0, 旗 int@+20 (块内 +20 = +324/+412/+500 非空门)}; 触发器块 (visible/enabled) 走 vtable[12] 触发条件文本发射, 效果块 (on_enable/on_disable) 走 vtable[8] — tooltip 装配器 0x1413C2100 (§4.26.15) 直证。

**CResistanceActivity** (抵抗活动 def, 912B; vtable 0x142941280; reader 0x140AA1060): +8 名 / +40 available(12264) 触发器块 88B / +128 weight(593) 数值提供子 56B / +184 effect(89) 块 / +272 内嵌 CModifier state_modifier(15741) / +360 本地化串 / +464 max_amount(409) 208B / +672 duration(109) 208B / +880 alert_text(19039)。

**CBuildingSpawnPoint** (建筑地图生成锚点, 名录; vtable 0x1427E42C0; reader 0x1414DF9B0): +17 is_port(12113) / +18 only_costal(12096) / +19 centered(19886) / **+20 max (676, i32)** / **+24 show_on_map_meshes (12182, i32)** / +28 type(225) 枚 1=province/0=state / +32 disable_auto_nudging(17431)。**无 x/y 字段** (旧「推定 x/y」系误读, 撤销)。

**国策/理念 def 周边 (1.19.3 实名)**: CNationalFocusDependency (国策依赖条, 72B, vtable 0x142739AC8, 键 or/focus 均落 +32 名串; writer 桩不落盘) / CNationalFocusStyleDatabase (focus style 双 RH 名表 = 内嵌 CNationalFocusDatabase+48 起 160B, 骨架不合 idb 不可挂) — 详 §4.8.12。


**CScriptedDiplomaticActionTemplate** (scripted_diplomatic_actions/*.txt def, ~1888B; vtable 0x142942828; writer = CFG 空桩不入档; parser 0x140AB3F60; idb scripted_diplomatic_action 已挂 0x332F048, 实例侧 CScriptedDiplomaticAction def@+120 指向本类): +8 名 token / +16 名 MSVC 串 / +48 requires_acceptance (15456) / +56 visible (11562) 触发块 / +144 allowed (12263) / +232 can_be_sent (15465) / +320 can_be_accepted (15464) / +408 selectable (15474) / +496 send_scripted_gui (15452) / +504 receive_scripted_gui (15451) / +512 ai_desire (15455) / +568 ai_acceptance 表 (15454) / +592 icon (181) 内嵌 208B / +800 cost (10323) 同形 / +1008 command_power (14467) 同形 / +1216 cost_string (15453) / +1248 show_acceptance_on_action_button (15462) / +1256 reset_send_effect (15463) / +1344 reset_receive_effect (15450) / +1432 complete_effect (14341) / +1520 reject_effect (15604) / +1608 on_sent_effect (15605) / +1696 send_description (15449) / +1728 receive_description (15448) / +1760 accept_title (15444) / +1792 accept_description (15445) / +1824 reject_title (15446) / +1856 reject_description (15447)。**88B 块类名定案**: 5 个条件块 (+56/+144/+232/+320/+408) = 内联 **`CAndTrigger`** (ctor 0x140549F40); 4 个效果块 (+1256/+1432/+1520/+1608) = 内联 **`CEffect`** (ctor 0x14053CFD0); 模板 ctor 0x140AB0C40 逐槽调, reader 0x140AB3F60 对应 case 走 `(*(vtable+40))` CTrigger Load wrapper / `(*(vtable+24))` CEffect Load wrapper。


**COpinionModifier** (common/opinion_modifiers/*.txt 静态定义条, 128B; vtable 0x14293F6D8; writer = CFG 空桩不入档; reader 0x140A822B0; ctor 0x140A801F0; idb opinion_modifier 已挂 0x332EFC0): +8 条名 token / +16 u8 THasNullObject 有效旗 (真条=1/Null=0) / +24 名串 32B (target=1 时 reader 改写 "<名>_target") / +56 名串副本 / +88 db 键 u32 / +96 db 序号 / **+104 i64 decay / +112 i16 value / +114 i16 min_trust / +116 i16 max_trust / +118 i16 存续天数** (10604 months×30 / 10605 days / 10606 years×365 三键汇入; 默认 -1 永久) / +120 u8 target 旗 / +121 u8 trade 旗。TNullObject 单例 qword_143339EB8。**装载与 target 顶替 (定案)**: 装载 0x140A80B20 逐条名小写化 → malloc 0x80 → ctor → vtable[3] ParseBody → **value 立即钳位 [min_trust, max_trust]**; target 旗分流 (+64 _TargetModifiers / +40 _Items 且后者并入 +88 名索引)。**`<名>_target` = 同名 token (+8) 顶替覆盖** (后处理 0x140A829C0: _Items 整体并入 _TargetModifiers 后按 +8 token 相等用 target 条顶替基条, 消耗制; 孤儿 target 报 :491 "…has no original modifier to build upon" 并丢弃); 装配后消费面 = +64 全表; 装载计数日志只数非 target (:455)。存档 `opinion_modifier={...}` 块真身 = CTimedOpinionModifier (§4.10)。



**名字/头像库族 (1.19.3 实名与值对象)**: CUnitNamesPool (单国名字池, 120B; vtable 0x1429461B8; writer 桩; reader 0x140AF4230): +8 prefix (12536) / +40 generic 名集 (12537, 读入去重合并; 引擎自定义向量 data@+40/count@+52) / +64 unique 名集 (12538; data@+64/count@+76) / +88 **generic_pattern (13246) = std::string 命名模板** (df396 勘误三错一处: 键名非 select_effect / token 非 13244 — 13244 真身 = select_effect / 类型非 token 整数; 占位符解析 = sub_140AEF0E0, 输出 40B {posNR i32@+0, posNAME i32@+4, 中段文本 string@+8}) — 即 unit_names key (0x332F0D8) 的元素类型 (120B×国数 vector@+64/cnt@+76)。CNameGroupDatabase (4 范畴链式表: +40 names_divisions / +56 names_ships / +72 codenames_operatives / +88 names_railway_guns; [2]=0x1409C28D0 PostFinalize 引用缝合, 全库族唯一非桩 [2]) 与 CUnitNamesDatabase (common/units/names; 120B 池向量@+64/cnt@+76 = 国数)**归属易互换已钉死**: 4 目录装载者 = 0x140162D30/qword_14332EE90 (name_group key), "common/units/names" 装载者 = 0x1401642B0/qword_14332F0D8 (unit_names key)。CPortraitPool (单性别加权池, 72B; vtable 0x14293FC70; reader 0x140A891C0): +8 male **池向量头** (12775; 引擎自定义布局 {data@+8, count@+20}, 40B 元 {weight u64@+0, MSVC SSO 名串@+8, size@+24, cap@+32}) / +32 female 池向量头 (10773; {data@+32, count@+44}) / +56 性别已设旗 (weight 须先于 male/female, 否则告警 "weight is set after male & female entries") / +64 u64 weight (593, 默认 100000)。CPoliticalPortraitPool (名字→池映射, 元素 112B = {名串 32B, FNV@+32, CPortraitPool 内嵌 72B}; vtable 0x14293FCC0; reader 0x140A88F70) = CCountryPortraits+224 槽。**CCountryPortraits** (portrait idb 条目的 **400B 载荷**; 条目值对象 = 48B 头 + 本载荷, 取像与装载均经 value+48 取载荷, 详 §4.26.18) = vtable + 5×CPortraitPool (+8 = type 2 / +80 = type 1 / +152 = type 4 / +256 = type 3 [推定] / +328 = type 5) + CPoliticalPortraitPool (+224, 名→池映射); type 0 与 type 3 在取像路径未实现 (portraitdatabase.cpp "Not implemented" 断言三连)。**CPortraitDatabase** (portrait idb 本体, vtable 0x14293FD90, 基 VCPortraitDatabase::?$TGameItemDatabase, 单例 qword_14332EFD8; reader 0x140A86E70 / 取像器 0x140A877B0 / GetPortraitsForCountry 0x140A87600) = db+40 名→条目 RH 映射 (运行期键 = cosmetic_tag/original_tag/tag) + db+104 大陆载荷数组 (400B 步距) + db+136/+208/+280/+456 四库默认池 + 取像三级回退, 全表见 §4.26.18。CCharacterTemplateDatabase (角色模板库, 184B; 双 RH 表 @+64/@+96, miss → TNullObject 0x143330C60; 单例 qword_14332EE58, 载 "common/characters"); **注册件 sub_1406BC330** (库+32×(表序+2) 选表, a4∈{0,1} → +64/+96; 73244475 两轮乘混 + xor-fold 哈希; 24B 桶槽+16 = 值; 重复 tag 报 "Multiple character have the tag %s" character_template_database.cpp:242) / **PostFinalize 派生遍历件 sub_1406BCE20** (模板数组 {d@+128, c@+140} 元步距 64; 三重前置门 库+140≠0 ∧ +52>1 ∧ +168≠0, 失败断言 "This database was not loaded!" :159 latch byte_143330C80; lambda 实名 CCharacterTemplateDatabase::PostFinalize'::'19'::_lambda_1_ 钉死所属域; 两表语义未决) 与 CNameDatabase (common/names; RH map 16 桶起 {mask@+88=7/extra@+96=8}, 节点 0x428, 单例 qword_14332EF68) 均已在 idb 规格内。



**AI 数据库族 ctor 级复核 (8 库全在 idb 规格内)**: ai_area (0x332EDC8, CAIAreaDatabase 112B, arr@40/cnt@52; 条目 CAIArea 104B {名@8, continents@56, strategic_regions@80}) / ai_attitude (0x332EDE8, 96B, arr@64/cnt@76; **+88 = NullObject 默认条目指针 qword_1433304A8, ctor push 成 arr[0]**) / ai_equipment_role (0x332EDD8, 112B; Null 条目 = CNullAIEquipmentRoleDatabaseEntry 448B, ctor 0x141488530) / ai_role (0x332EDF0, 88B, sso16 名表) / ai_strategy (0x332EE00, 136B vec3: 名注册表@40 {40B 元 {string, ci-hash}} / 条目@64/@88 / _StrategySpecificData@112 cnt@124) / ai_strategy_plan (0x332EE10, 96B; **+48 = 默认缓冲 &aFff_0[4]**; arr@72/cnt@84) / ai_fleet_template + ai_taskforce_template (0x332EF88/0x332EF80, PR 族 128B 同构; **默认桶缓冲不同**: fleet = &unk_143085E50 / taskforce = &unk_143085E20; 条目 CAiFleetTemplate 80B {token=FNV@8, 双 32B 组 {串, 权重}} / CAiTaskforceTemplate 264B {CAndTrigger@+72 allowed, +160 min_composition / +192 optimal_composition 双 32B RH 编成表, +224 EMissionType; 全字段表与 mission token 映射见 §4.34.13a (「i32 编成上限 10」未复见, 待裁))。


库值对象/条目布局 (idb 已挂, ctor 级复核零冲突):

| 类 | 关键布局 |
|---|---|
| CStrategicLocationTemplate (要冲定义, 40B; vtable 0x14271B960) | +8 token 哨兵 357 none / +16 vec<{building u32, level u32}> (data@16/cap@24/cnt@28); reader 每键解 building type (miss → "Invalid building type", strategic_locations_database.cpp:11), RHS 必整数; 形 `suez_canal = { suez_canal = 2 }` |
| CStrategicRegionTemplate (战略区定义, 336B; vtable 0x1429DBE50) | +8 provinces (10288) / +32 名规范化 sso32 / +64 名原文 (27) / +128 dominance 阈值 / +160 id (181, ctor -1) / +168 u8=1 (有效旗; 世界装载按此门建区) / +176 weather (12040, 元素 224B, 内 period=12042) / **+200 天气表现点向量 {data@+200, cap@+208, count@+212, alloc@+216}, 16B 元 {f32 x@0, y@4, z@8, u8 small@12}** (唯一写者 = map/weatherpositions.txt 解析器 0x140AC0AB0 逐行 `region_id;x;y;z;small` 装载, §4.25.8; 与 +176 定义内 weather 块并存, ctor 双初始化, 非序列化) / +224/+228 锚点 {x i32, y i32} (region+100 锚点省 / +240 坐标副本 / 邻接锚距² 三者源) / +272 naval_terrain (15147) / +312 static_modifiers (15136, 元素 80B); **writer 0x1415A6F40 = nudge/调试回写通道** (非存档, 存档侧 = CStrategicRegion 实例 §4.3) |
| CDifficultySetting (自定义难度项, 120B; vtable 0x142935978) | +8 HasNullObject 活位 / +16 multiplier 对象 (10912, 默认 null 单例 qword_143330368) / +24 countries 国名哈希列 (11593) / +48 modifier 文本 (10597) / +56 key 名 (220) / +88 icon (181); **def ↔ 存档实例 CDifficultySettingItem (0xD8, gs+1064) 分工对** |
| CBookmark (主菜单书签, 400B; vtable 0x1427E3E08; writer=CFG) | +16 name (27) / +48 desc (10644) / +112 picture (464) / +160 filters (10669) / +240 default → CBookmarkCountryEntry* 列 (11405, 每块 344B) / +368 date (10314) 内嵌 CGameDate 24B {hours u32@+376; +384 = 第二 vtable 装载代理位 (reader 经该处对象 Load wrapper 槽)} — ctor 0x14067BE30 四行赋值直证, 执行链读数位 = +376; 消费只在前端; **PostLoad = 主虚表槽[8] 0x14067D680 (TNullObject VCBookmark 同槽共享, postload 清单直证)**: 两段校验 = byte@+208 门内 label_order 完整性 (排序拷贝+二分, 缺失日志 :228) 与 default_country 落位 (扫 +240 列表比对 entry+8 == tag, :244, 日志级非断言); **+208 = 校验门字节 (置位者未决)**; label_order(+184) / id 收集(+216) / default 列表(+240) 三容器 = {data, cap@+8, count@+12} 引擎自定义族 |
| CCountryTagAliasEntry (~800B; vtable 0x1427EA8D0) | **+264 u32 别名 token** (resource.lua tok264 ✓); 键表 = 12048 variable / 13272 fallback / 13649 original_tag / 15763 country_score / 15764 global_event_target / 15765 event_target; ctor 端验 "invalid alias tag %s" (countrytagalias.cpp:15; 转名后类型域 ==3 才合法) / "alias is already existing tag %s" (:22, 全局 tag 注册表单例 qword_143330D98 按名查 sub_14071BC80 ≠ −1 即存在); ctor 布局: 基 **CScriptTargets@+8** (vtable 符号直证) / +24+112 双容器 / +200+224 双串 / +248+256 双旗 / +272+504+600(4B 元素)+656 容器组 / **+480「查全部国家」降级旗** (装载后校验 sub_140721400, :82: +488 变量/事件目标空 ∧ +16 原始 tag 旗假 ∧ +280 targets 旗假 → 置 +480=1 + 警告 "%s has no original tag, no targets or any variable/event target to map. it will check all countries"; 门 = sub_14039DF40 单例 +128 byte) |
| CMTTHDatabaseEntry (MTTH 条目 = `mtth:` scoped var 目标, 56B; vtable 0x14271A658 9 槽; 谱系 CMeanTimeToHappen→CPersistentWithToken; writer = CFG 空桩) | +8 u32 db 名 token / +16 u32 内嵌上下文 token (db 条目 = 16382) / +24 i64 base (fixed×1e-5, ctor 默认 100000) / +32 CMTTHModifier** 向量 {cap@+40, count@+44, alloc@+48}; reader token 分派: base 11398 / factor 10603 / months 10604 (×30e5) / days 10605 (×1e5) / years 10606 (×365e5) / modifier 10597 (new CMTTHModifier 0x1F8); 未知名 fatal "unknown command '%s' for MTTH in file … line …" |
| CScriptEnumDatabase 深读 | +40 空 vec = **miss 兜底仓** (键不在 → 返空 vec); RH@64 stride 40 {name token@8, 值 = 内联 vec<u32>@16}; 喂件 = common/script_enums.txt |
| CTechnologySharingGroupDatabase 深读 | **唯一 CPersistent 族 db** (次表 @+40, mdisp=40); +48 RH 表头 {cnt@64, extra@72, mlf@76} / +80 默认模板 160B; reader = token 14094 technology_sharing_group |


**库类名录** (key → 类 → 槽): 下表给出 idb 规格表各行 key 的**库类实名与槽地址** (补全「key → 类」映射):

| book key | 库类 | 槽 |
|---|---|---|
| aces | CAcesDatabase | 0x14332EDB0 |
| ability | CAbilityDatabase | 0x14332EDA8 |
| agency_upgrade | CAgencyUpgradeDatabase | 0x14332EDC0 |
| ai_fleet_template | CAiFleetTemplateDatabase | 0x14332EF88 |
| ai_bonus_weight | NIndustrialOrganisation::CAiBonusWeightDatabase | 0x14332EDD0 |
| ai_faction_theater | NFactions::NAi::CAiFactionTheaterDatabase | 0x14332EDE0 |
| autonomous_state | CAutonomousStateDatabase | 0x14332EE18 |
| continuous_focus | CContinuousFocusDatabase | 0x14332EE60 |
| country_leader | CCountryLeaderDatabase | 0x14332EE68 |
| country_metadata | NCountry::CMetadataDatabase | 0x14332EE70 |
| country_tag_alias | CCountryTagAliasDatabase | 0x14332EE78 |
| difficulty_settings | CDifficultySettingsDatabase | 0x14332EE88 |
| dlc_metadata | NDLC::CMetadataDatabase | 0x14332EE98 |
| doctrine_folder | NDoctrines::CFolderDatabase | 0x14332EEA0 |
| grand_doctrine | NDoctrines::CGrandDoctrineDatabase | 0x14332EEA8 |
| sub_doctrine | NDoctrines::CSubDoctrineDatabase | 0x14332EEB0 |
| doctrine_track | NDoctrines::CTrackDatabase | 0x14332EEB8 |
| faction_goal | NFactions::CFactionGoalDatabase | 0x14332EEE0 |
| faction_member_upgrade | NFactions::CFactionMemberUpgradeDatabase | 0x14332EEF0 |
| faction_rule | NFactions::CFactionRuleDatabase | 0x14332EF00 |
| faction_rule_group | NFactions::CFactionRuleGroupDatabase | 0x14332EF08 |
| ideology | CIdeologyDatabase | 0x14332F528 (与 ideology_group 库 0x14332EF38 = CIdeologyGroupDatabase 同一 creator sub_140A459B0 顺建 — 多宿主懒建律又一例) |
| mio_organisation | NIndustrialOrganisation::COrganisationDatabase | 0x14332EF48 |
| focus_inlay_window | CFocusInlayWindowDatabase | 0x14332EFD0 |
| historical_agency | CHistoricalAgencyDatabase | 0x14332EDB8 |
| occupation_modifier | COccupationModifierDatabase | 0x14332EF90 (creator sub_140172450 直证; 装载闭环 §4.26.19) |
| bookmark | CBookmarkDatabase | 0x14332EE20 (ctor sub_14067C250 RTTI 直证; creator sub_140170310; LoadFiles 0x1402DA2B0 = §4.00.51 第 10 实例) |
| operations | COperationsDatabase | 0x14332EFA8 |
| operation_phases | COperationPhasesDatabase | 0x14332EFB0 |
| operation_tokens | COperationTokensDatabase | 0x14332EFB8 |
| opinion_modifier | COpinionModifierDatabase | 0x14332EFC0 |
| portrait | CPortraitDatabase | 0x14332EFD8 |
| project | NProject::CProjectDatabase | 0x14332EFE8 |
| project_dynamic_modifier | NProject::CProjectDynamicModifierDatabase | 0x14332EFF0 |
| prototype_reward | NProject::CPrototypeRewardDatabase | 0x14332EFF8 |
| resistance_activity | CResistanceActivityDatabase | 0x14332F008 |
| scientist_trait | CScientistTraitDatabase | 0x14332F010 |
| script_constant | NScript::CConstantDatabase | 0x14332F020 |
| script_named_collection | NScript::CNamedCollectionDatabase | 0x14332EED8 |
| scripted_diplomatic_action | CScriptedDiplomaticActionTemplateDatabase | 0x14332F048 |
| strategic_location | CStrategicLocationDatabase | 0x14332F078 |
| strategic_region | CStrategicRegionDatabase | 0x14332F080 |
| strategic_resource | CStrategicResourceDatabase | 0x14332F088 |
| technology | CTechnologyDatabase | 0x14332F0A0 |
| unit_leader | CUnitLeaderDatabase | 0x14332F0D0 |
| unit_medal | CUnitMedalDatabase | 0x14332F0C8 |
| career_picture | NCareerProfile::CProfilePictureDatabase | 0x14332EE38 |
| career_background | NCareerProfile::CProfileBackgroundDatabase | 0x14332EE40 |
| career_medal | NCareerProfile::CMedalDatabase | 0x14332EE30 |
| career_ribbon | NCareerProfile::CRibbonDatabase | 0x14332EE48 |

**条目类 ≠ 「库名去 Database」的 5 处** (按库名推条目类会取到运行时件) 见下表:

| 库 | 条目类 | 说明 |
|---|---|---|
| CContinuousFocusDatabase | **CContinuousFocusPalette** | reader sub_1406C2C80 直证 `malloc 0x90` → `&CContinuousFocusPalette::vftable'` |
| CAcesDatabase | **CAce** | AddItem sub_140618600 / sub_140618860 `malloc 0x178` → ctor sub_1406176C0; CAceModifier (0xF8) 是其内嵌子件 (aces.cpp:207) |
| CStrategicLocationDatabase | **CStrategicLocationTemplate** | 模板实参直证 |
| CTechnologyDatabase | **CTechnologyTemplate** | 0x590 为定义条目; CTechnology (0x1F8) 是运行时科技件 |
| CUnitLeaderDatabase | **CUnitLeaderTemplate** | 0xC0 为定义条目; CUnitLeader (0x10B8 / 0xFC8) 是运行时将领 |

**无独立 RTTI 条目类** (2 库, 条目为内联 POD):

| 库 | 条目形态 | 证据 |
|---|---|---|
| CCharacterAdvisorGenerationDatabase | 56B 内联元素 (含 name sso), 无 vftable | 装载器 sub_1406B1C80 → sub_1406B1050; vector 增长助手 sub_1406B0880 按 `56*count` 分配, 逐字段 `+24 = 15` (sso cap) 初始化 |
| ?A0x9ca8863a::CAmbientSoundDatabase | 200B 内联元素, 无 vftable | dtor sub_14066E360 里 `v5 += 200` 步进释放 |

**派生族统计** (49 库) 见下表:

| 族 | 数 | 类 |
|---|---|---|
| PR (`CPersistentReloadableGameItemDatabase<DB,Entry,Cfg>`) | 16 | CAiFleetTemplate / CFocusInlayWindow / CStrategicLocation / NDoctrines::{CFolder, CGrandDoctrine, CSubDoctrine, CTrack} / NFactions::{CFactionGoal, CFactionMemberUpgrade, CFactionRule, CFactionRuleGroup, NAi::CAiFactionTheater} / NProject::{CProject, CPrototypeReward} / NScript::{CConstant, CNamedCollection} |
| TRS (`TReloadableGameItemDatabaseSpecific<DB,Entry>`) | 8 | CCountryTagAlias / CIdeology / COperationPhases / COperationTokens / COperations / CScientistTrait / NIndustrialOrganisation::{CAiBonusWeight, COrganisation} |
| 裸 T (仅 `TGameItemDatabase<T>`, 非 CPersistentReloadable 派生) | 23 | 其余 |
| T + CPersistent 多基 (**双vtable**) | 2 | CAutonomousStateDatabase / CContinuousFocusDatabase |
| 合计 | 49 | — |

> 族口径与 idb 规格表吻合: PR 族 = `{vec@8 基类(=_Paths), 表@48, 条目 vec@80/cnt@92, token vec@104}`;
> TRS 族 = `{条目 vec@96/cnt@108, 宽名表@64 stride 56}`。
> **PR 族模板第三参 = 条目名取法编译期开关**: `NDatabaseConfig::SDefaultLexerTokenConfig<Entry>` /
> `SDefaultConfig` / `SDefaultDelayedLexerTokenConfig` / 各库自有 `SXxxDatabaseConfig`。
> ⚠ **T + CPersistent 双vtable库** (CAutonomousStateDatabase / CContinuousFocusDatabase) —
> `resource.lua` 若按单 vtable 取类名会落空。

**目录 ↔ 类名不一致 (3 处 + 1)** — 按类名推目录会静默不加载:

| 库类 | 实际脚本目录 | 按类名推得的目录 (错误) |
|---|---|---|
| COccupationModifierDatabase | `common/resistance_compliance_modifiers` | common/occupation_modifiers |
| CStrategicRegionDatabase | `map/strategicregions` (无下划线, 带 map/ 前缀) | common/strategic_regions |
| CStrategicResourceDatabase | `common/resources` | common/strategic_resources |
| CCharacterAdvisorGenerationDatabase | `common/generation` | common/character_advisor_generation |

**非 qword_14332Exxx 段的库槽** (3 库):

| 库 | 情况 |
|---|---|
| CCharacterAdvisorGenerationDatabase | 无独立 .data 槽; DB 对象由 qword_14332EE50 承载 (内联在总入口) |
| COpinionModifierDatabase | 库槽 = qword_14332EFC0 (正常段内); ⚠ 其 TNullObject 哨兵 **0x143339EB8** 易被误当库槽 |
| ?A0x9ca8863a::CAmbientSoundDatabase | 槽 = qword_143330540 (不在 0x14332Exxx 段) |

**无 gameplay 消费的库** (负定案, 不参与存档面):

| 库 | 负结论 |
|---|---|
| NCareerProfile::CProfilePictureDatabase / CProfileBackgroundDatabase | 纯前端生涯档案图库 (`common/profile_pictures` / `common/profile_backgrounds`); **条目 160B (0xA0) 全布局 (定案, 原记「仅 32B 句柄包装」系槽侧视角)**: 槽 = pdx::scoped_ptr 8B; 条目 = {+0 u8 在册旗 (代码注册=1/null 条目=0), +4 u32 id = **条目名 token id**, +8/+40 双 MSVC 串 (SProfileMeta 回填), +72 CAndTrigger 内嵌 88B}; 64B 库 {vptr, +8 向量 24B, +32 int, +40 条目向量 (下限 64, 1.5×)}; ctor 尾建 null 条目 (+4 id=−1, +0 旗=0) + **硬编码注册器 sub_1406AE830 (71 次 sub_1406ACEC0, IDA 丢实参逐条 id 未决)** — 解锁触发器三味 = CCheckPoints (336B, vt 0x1427A1E70: career points 门槛, 内嵌 CScopedVariable + token 14581 greater_than_or_equals + 100000×点数 + loc CAREER_PROFILE_TOOLTIP_POINTS) / CCheckMedal (vt 0x1427A1F80) / CCheckRibbon (vt 0x1427A2040); **元数据装载孪生对 0x1406AD1E0/0x1406AD6A0** (顶层键 15987/16044) = 仅回填: 条目名 token 查库命中 → SProfileMeta (72B 双串) 拷入 +8/+40, 未命null → 错误日志继续。与 §4.26.18 CPortraitDatabase 两套独立体系 |
| ?A0x9ca8863a::CAmbientSoundDatabase | 匿名命名空间音效库 (`sound/combat_sounds`), 条目 200B 内联; 纯音频播放侧 |
| CDifficultySettingsDatabase | 难度设置静态库; 条目 120B; 只在开局难度选择/GUI 侧消费 |
| NCountry::CMetadataDatabase / NDLC::CMetadataDatabase | stdmap 形态元数据库 (`country_metadata` / `dlc_metadata/dlc_info`); DLC 归属与国别元信息 |

**库形态补注**: ① `mtth` (**库类 CMTTHDatabase**, 136B) **byte@128 = 内容解析开关**（定案）: boot 双通道装载 — ctor/boot 首遍置 1 并 sub_140188F30 只登记名（内容被 brace-skip 0x1424C2100）→ 次遍 sub_140192E80 首句清零后逐名全量解析（0x140552390 CMeanTimeToHappen reader）; 活体实证 byte=0 且 59 条目已含解析值（base≠ctor 默认）；CCountryTagAliasEntry reader 同机制; ② `ability` 名 MSVC@def+112 由「定案」改注**高置信** (resource.lua nm="none 暂计数" 对拍分歧); ③ `difficulty_settings` getter = **sub_140170630** (单例 creator, 槽 0x14332EE88, `_pInstance && "Instance already created."` gameitemdatabase.h:127 断言链); 并列的 sub_140170120 在 1.19.3 **不存在** (dump 无该函数头); ④ `message_handler` = 非内容库 (注册表+设置处理器, 未入 idb 规格表, 其值类 CMessageType/CMessageTypeSettings 见 §4.28.10); ⑤ `country_tag_alias` 单例 0x332EE78 ✓ / `mtth` 0x332EF58 ✓ / `technology_sharing_group` 0x332F098 (C 按名) / `script_enum` 0x332F028; 14 库分级切片: A 10 / C 2 / D 1 (aces) / 非内容库 1。

**CAceModifier** (王牌修正 def; vtable 0x1427DE3A0; writer = CFG 空桩 = 解析件; reader 0x14061B390): +40 type 枚举 / **+48 chance 定点整数槽** (%lli 解析 + 5 位小数定点化; 8B 整数加权累计双证) / +56 effect 嵌套子对象。⚠ 与 CContextLocalizationText vtable相邻 (0x1427DE358 vs …3A0), 归属勿混。

**CTechnologyPath** (科技树路径 def; idb 项, 基 THashedKeyValueTrait mdisp=8; writer = CFG 空桩 = 解析件): +8 leads_to_tech 串 (FNV-1a 入 +40) / +48 research_cost_coeff f32 / +144 ignore_for_layout u8。

**成就定义族** (def 去向两路 (定案): **原版 = 单文件 `common/achievements.txt`** 装多成就 (装载器 sub_1406207E0, 逐条按名查平台 Steam 上下文 (app+856 对象 +48 槽, vt+88) 得数值 id); **mod = `common/achievements/*.txt` 一文件一成就** (装载器 sub_140620B40, 由 6207E0 尾直调; 文件级 token 12458 `unique_id` 强制, 缺失即日志丢弃整文件); 重载 sub_140249F50 "Custom achievements completion cleared…"; writer 全空桩 = 只载不存): **CBaseAchievement** (vtable 0x1427DECC0 基, reader 0x140620960 共用回退): possible(10886)→+16 CBaseTrigger\* (malloc 0x58) / happened(10887)→+24 第二触发器 / hidden(11404)→+32 u8; **CAchievement** (0x1427DED30, reader 0x140620920 先查自身 Miss 回退基): +80 id (11) 整型短码 (装载初值 −1) / **+72 = 平台成就数值 id (按名查平台上下文, 查无即跳过该条)**; **CAchievementMod** (0x1427DEDF0, reader 0x140620940): +72 = unique_id 串 (回填 + 管理器 map 键) / +120 ribbon (16053) 块读 = **SRibbonForAchievement 内嵌 (类型名 vtable 符号直证)** / +128/+152 双 24B 引擎向量 (用途未决) — mod 成就与生涯 ribbon 体系挂钩 (token 区 16001+ career/awards 系, 与 §4.28.8 medal/ribbon 族同邻域); 运行时实现层 CAchievementsContext 抽象 ← CSteam (§4.00.9) / CDummyAchievementsContext 单机空实现。

**成就运行时族** (与上列定义族**同名不同物、无继承关系、无共同vtable**; 平台成就状态机, 非 CPersistent):

| 类 | vtable | ctor | 布局要点 |
|---|---|---|---|
| CAchievementBase | 0x142B5BA98 | 0x142397F30 (dtor) | 抽象基: 8 槽 = [0] dtor + [1..7] = `_purecall` (0x14253C3B8) → 7 纯虚 |
| CPrimeAchievement | 0x142B5BAE0 | 0x142397EA0 | 96B: +8 qword (ctor a3) / **+16 = `CAchievementsContext*`** (vtable[1][2] 内以 `**(a1+16)+112` 虚调上下文) / +24 SSO / +56 SSO / **+88 u8 = 达成旗** |
| CAchievementsContext | 0x142B5BB28 | 0x142397F60 (dtor) | 抽象 (多数槽 `_purecall`); 实现 = CSteam / CDummyAchievementsContext |

> CPrimeAchievement 行为槽: [1] sub_142398600 = 达成置位 (+88==0 → +88=1 → 通知上下文) / [2] sub_1423982C0 = 复位 (+88==1 → +88=0 → 通知) / [5] sub_1403CFD80 = `return *(u8*)(a1+88)` 查询。
> ⚠ 定义族 (`CBaseAchievement` / `CAchievement`) 是成就定义数据 (id/触发器/ribbon), 运行时族是平台成就状态 (键/描述/达成旗) — 两族**勿互指**。

**书签定义族** (def 去向 `common/bookmarks`; writer 空桩; 库 = **CBookmarkDatabase** TGameItemDatabase 模板 (vtable 0x1427E3E88; **逐文件加载器 0x14067CCF0**: 键 13210 bookmarks / 10249 bookmark, 条目 malloc 0x190 → ctor 0x14067BE30 → vtable[3] Parse; 库数组 {data@+40, cap@+48, count@+52, 分配器@+56}, 增长 max(n+1, cap×1.5); 日志 :362 "Bookmarks loaded"; 纯追加无 Lookup 插入), 附 Null 变体 VCBookmark TNullObject 0x1427E3FF0): **CBookmark** (vtable 0x1427E3E08, 基 CPersistent + THasNullObject; reader 0x14067DB80) 14 键: name(27)→+16 / picture(464)→+112 / desc(10644)→+48 串 / effect(89)→+264 触发器槽 / filters(10669)→+160 列表 / label_order(19089)→+184 追加合并 / default_country(13212)→+144 CCountryTag 校验读 / date(10314)→+368 内嵌 CGameDate 块读 (hours u32@+376; +384 = 第二 vtable 装载代理位, reader 装载入口; 执行链读 +376) / default(11405)→+392 / sort_unplayed_first(11473)→+393 / include_majors_in_minor_list(18242)→+394 / apply_filter_to_majors(18953)→+395 / apply_filter_to_other_country(18646)→+396 / scrollable_country_list(18923)→+397 u8 系; 匿名国家子块 → +240 向量追加 (= CBookmarkCountryEntry, ctor 0x14067BFC0) + +216 id 收集 + +356/+360 已玩/未玩计数。**CBookmarkCountryEntry** (reader 0x14067E210; **+8 int 国家 tag — 运行期 default_country 落位校验键 (PostLoad 比对项), 书 9 键表原缺行**) 9 键: history(10293)→+24 / label(519)→+128 列表 / ideology(11838)→+152 组指针校验读 / required_dlc(15200)→+0 本对象解析 / available(12264)→+184 触发器槽 / minor(11242)→+272 / assume_not_played_if_missing_data(12791)→+273 / version(238)→+280 / override_leader_portrait(12792)→+312。**CCountryScorerDatabase** (打分器库, def 去向 `common/scorers/country`; TReloadableGameItemDatabase 模板; vtable 0x142941570 7 槽, null 项 "null_country_scorer"): 条目 reader 0x140AA4060 唯一键 targets(15733) → malloc 0x140 (320B) **SSingleScorerEntry** (内嵌 CScriptTargets@+8 + 双 CBaseTrigger + 双串 + flags@+248/+256) 追加 +24 指针向量 {cap@+32, count@+36}。

**CTreeShortcut** (国策树快捷键 def; vtable 0x142739B18 9 槽; writer 空桩 = 解析件; reader 0x1402D9470): target(107)→+16 串 / name(27)→+48 串 / scroll_wheel_factor(626)→+176 / trigger(10595)→+88 子对象 vtable+40; 未知键抛 "Error in focus tree shortcut"。

**CUpgradeWindowOverride** (升级窗口覆盖 def; vtable 0x14295B7D8 9 槽 + 后接两组内嵌子对象vtable; writer 空桩 = 解析件; **三组 = 内嵌子对象定案** — RTTI CHD 层级各自仅 {自身, CPersistent}, 三 COL this_off 全 0, 非多基): 外壳 reader 0x140C9B3D0 键 upgrade(15356)→+8 串 / override(14561)→+40 串; 内嵌 **USModifierStat** (第二vtable, reader 0x140C9B410) 键 type(225)→+20 / value(776)→+16 / modifier(10597)→+8 查表; 内嵌匿名 ns **CModuleCountLimit** (第三vtable, reader 0x140C9B340) 键 category(702)→+40 / title(10643)→+8 / count(10730)→+48+52 / module(15222)→+44。

**CFrontEndBackgroundDatabase** (主菜单背景项库; vtable 0x14271A2C0 5 槽; 基 CPersistentReloadableGameItemDatabase; 启动初始化 sub_1401835A0): def 去向 common/profile_backgrounds; 条目类邻位 = CFrontEndBackgroundDatabaseItem。**CFrontEndBackgroundManager** (vtable 0x142A62D08; 前端初始化 sub_14163E810): 背景选择/切换管理器。



**CTerrainType** (terrain 库 A 族游戏性地形 def, **512B** (0x200 — 装载 reader malloc 直证, 与 Null 单例表互证); vtable 0x1429C0EA0; writer=CFG; reader 0x14143F460; ctor 0x14143BB90 = Null 单例创建点, **装载期 reader new 另用 ctor 对 0x14143BCF0(512B)/0x14143BAE0(112B, CTerrainGraphics) — 两对 ctor 并存** (行为差异未展开)): +8 i32 = **def 名 token** (基类 ctor sub_1424BE3C0 直写 357 = `none` 哨兵, 装载后由 reader 覆写) / +16 u8 有效旗 / +24 名 SSO 32B / +56 库内序号 / +64 CColor 内联 32B (86) / +96 movement_cost (10331, <1000 强抬并告警 terrain.cpp:181) / +104 combat_width (11471) / +112 combat_support_width (19635) / +120 ai_terrain_importance_factor (13826) / +128 minimum_seazone_dominance (10173) / **+140 u32 位掩码: bit0=inland_sea (10761) / bit1=is_water (10418), parse 期按 yes 置位** / +148 worth (13287) / +152 match_value (14014) / +160 u32 = **`sound_type` (11052) 枚举: 0=plains / 1=sea / 2=forest / 3=desert** (reader 0x14143F460 case 11052 以 memcmp 四串; 磁盘互证 `common/terrain/00_terrain.txt` 每条 `sound_type = forest` 等) / +168 CModifier 内嵌 ~192B (未知键兜底) / +360 CUnitAdjuster 内嵌 40B (12202 units) / +408 逐单位类型地形加成子块表 {d@408, c@420}, 元素 272B / +496 supply_flow_penalty_factor (19650)。**has_terrain 负定案**: 该 trigger (sub_1404365C0) 只按 **def+8 token** 在 terrain 库内匹配条目、命中后读 **def+16 有效旗**, **不读 +140 两位**。

**CInsigniaTypeGraphics** (insignia_graphics 库 kind8 元素, 64B; vtable 0x14293D378; writer=CFG; reader 0x140A56120): +8 gfx 名 SSO (12472) / +40 SInsigniaIconInfo* 向量 {d@40, c@52} (181 icon 逐条 malloc 136B 构造)。

**CSubUnitCategory** (单位类目定义, ≥108B; vtable 0x142985DC0; 名录): +16 类目名 SSO / +48 序号 (-1) / +56 容器 {d@56, c@68} / +84 i64=357 = **def 名 token** (ctor 0x141017F70 直写 357 = `none` 哨兵)。**CGraphicalCultureType** (graphicalculturetype 裸名定义; vtable 0x14293BFF8; 名录): +8 FNV 名哈希 / +16 名 SSO / +48 库内序号 / +96 固定 800B 表 (推定层/肖像映射)。**CTrainGfxDatabase** (train gfx 库; vtable 0x1429453B8, 5 槽非 CPersistent; 名录): idb train_gfx 已挂 (0x332F0C0, 内嵌记录@40 + 指针 vec@104 + 双槽位阵@176/@200), dtor 0x140ADED40 容器群直证 +152 第三 vec 亦存在。


**脚本化值/文本/模板族 (三库已挂, 布局全录)**: CScriptableValue (脚本值求值对象, 248B; vtable 0x1429DAFC8; writer=CFG; reader 0x1415945D0): +8 CScopedVariable 208B 基值 (base 11398) / +216 CPdxArray<CScriptableValueModifier*> modifier 表 (10597, 逐条 504B) / +240 上下文 id; **CScriptableValueModifier** (504B; vtable 0x1429DAF08; CAndTrigger 后代): +88 CScopedVariable factor (种子 1.0) / +296 CScopedVariable add (种子 0) + 基条件表全 AND。**SModifierDefinitonReader** (modifier_definitions 行解析器, 32B 栈件; vtable 0x1427DDA50; reader 0x140610B80): +8 precision (19052) / +12 显示格式位包 (color_type 19042: good→bit1 / neutral→bit2; value_type 19043: percentage→bit0 / yes_no→bit5 / percentage_in_hundred→bit7) / +16 postfix 枚 (19049: 1 days / 2 hours / 4 daily) / **+24 category 位掩** (state=0x10 / country=0x8 / army=0x20 / ai=0x100 / naval=0x1 / air=0x2 / politics=0x80 / unit_leader=0x4 / intelligence_agency=0x10000 / scientist=0x40000 / peace=0x40 / defensive=0x200 / aggressive=0x400 / war_production=0x800 / military_advancements=0x1000 / military_equipment=0x2000 / autonomy=0x4000 / government_in_exile=0x8000; all=0xFFFFFF)。**CScriptableLocalization** (defined_text 条目, 64B; vtable 0x142942470; writer = 死断言 "Should not happen!" 永不写盘; reader 0x140AAC7A0): +8 name / +40 STriggerKeyPair 数组 (元素 24B {vtable@0, loc 载荷*@8 (localization_key 799 或 random_list 10172 二选一, 同文件互斥), CAndTrigger*@16})。**CScriptableLocalizationDatabase** = umap 哨兵@48/size@56/cs-FNV/node+48 值槽 + reload 钩 (dword_14333A0A0) — 「链表走反」修复族的第三例代码级证据。**CScriptedTriggerTemplate** (模板 and-trigger 树, 136B; vtable 0x142942C50; 基类 CAndTrigger — 基 ctor sub_140549F40): THasNullObject@88 + 名 sso@+96 + idx@+128; [1] GetName 覆写 0x1401776D0。**CScriptedTriggerTemplateDatabase**: vec@64/cnt@76 (槽 0 = TNullObject 0x88B) + 双 RH 表 (LF 0.9)。**CScriptedEffectTemplateDatabase**: 条目 vec@80/cnt@92 (条目 128B, 名 sso@+96) + **[2] = "d_" 前缀依赖收集器** (0x140AB4AC0) → +128 reload vec。

#### 4.26.11a 地图建筑装载域 (mapbuildings.cpp 5+6 函; map/buildings.txt 与 72B 实例)

清册 (5/5 函体内含 mapbuildings.cpp 路径锚): LoadBuildings sub_141671C10 (1409, 全 throw 组) /
SaveBuildings sub_1416748D0 (818, `;` CSV 写回) / LoadMeshHandles sub_141675750 (569) /
UpdateInstanceEntity sub_141676450 (302) / SetOrder sub_1416756C0 (28)。**运行时创建域另 6 函** (df400: 均零路径锚/零业务串, 域归属按地址紧邻 + 行为链推定) = **实例创建器 sub_14166FBA0** / 浮动港口支 sub_14166F7B0 / 校验门 sub_1416717C0 / 位置选择三支 sub_141670A80 (哈希随机) + sub_141670890 (省建) + sub_141671220 (州建) — 见下「运行时创建域」。

**map/buildings.txt 行格式** (定案, 解析器断言 + 原盘逐列对拍双证): `州id;建筑名;x;y;z;rotation;海域id`
7 字段分号 CSV; 像素坐标对 = (x, z)。is_port 行 f6 = 海域 id → 省图形记录+200; 湖泊 = 同记录+210
bit1; 特例行 f6 = 输出省 id 存实例+52 (SaveBuildings 写回前解析)。

**72B 建筑地图实例** (书内此前无此对象; 定案):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | u32 | def id (spawn def +88 qword 对低半, 1-based; 创建器一次 qword 读同填 +4, df400) |
| +4 | u32 | 群组 id (357 = null 哨兵, 与 SLevelMax group_by 同源; 源 = spawn def +92 高半, df400) |
| +8 | 句柄 | 网格缓存 |
| +16 | 实体 | 3D 实体句柄 |
| +24 | u32 | **特例种类索引** (0 = 普通 / 1 = floating_harbor; 创建器 dword 写, a2 作 1-based 索引入管理器+72 特例表 — df400 精化: 非 u8 旗) |
| +28 | u8 | Order = 同州/省同 def 堆叠序号 (装载计数直写; :513 上限断言) |
| +32..+44 | f32×4 | x / **y = CMap+376 高度场双线性采样值 (sub_140A60F10, 非脚本/存档给定, df400 新)** / z / rotation |
| +48 | u32 | 所属省 id |
| +52 | u32 | 特例输出省 id (SaveBuildings 写回前解析) |
| +56 | u16 | 州 id |
| +58 | 缓存 | 毁坏态缓存 |
| +59 | u8 | 动画态 |
| +64 | f32 | 弹出进度 |

**实体命名四式** (.gfx 实证): `building_<名>[_N]` / `_destroyed` 变体 / 特例
`floating_harbor_entity`; 网格句柄按 def 装入 mgr。**defines**: dword_143334DF8 =
MAX_MESHES_LOADED_PER_FRAME (87470 泵帧界清零 + 高水位, 与省图形 3 创建点共享) /
dword_143334EB8 = MESH_POPUP_SCALE_UP_SPEED / def+801 = disable_grow_animation。

**建筑 db 容器族精化** (0x332EE28; 双容器注见 §4.26.11): +112 索引数组 (null@[0]) /
+136 名查表 (40B, hash+stricmp) / +148/+1000 群组旗; 群组记录 {+8 group, +88 defid};
群组解析 group==357 → null 对象, 群组模式线性扫 +112。**spawn def 形状** (消费点定案):
+16 有地图网格旗 / +17 is_port / +20 max 实例上限 / +24 show_on_map_meshes / +28 type
(1=省建/0=州建) / +40 MSVC 串名称 / **+18 水域/港口旗 (置位 → 校验门走 (省图形记录+210 & 9)==9 水位校验 + 创建器朝向走面朝相邻水域省支, df400 新)** / **+19 位置模式旗 (0 = 哈希随机扫描州内省 / 1 = 定位, df400 新)** / **+88 = {id u32, 群组 id u32} qword 对 (df400 精化: 创建器一次 qword 读同填实例 +0/+4)**。

**运行时创建域** (df400; 6 函零路径锚零业务串, 域归属按地址紧邻 + 行为链推定):

| VA | 定性 | 档 |
|---|---|---|
| 0x14166FBA0 | **建筑地图实例创建器** (推定 CMapBuildingManager::CreateInstance; a1 = 管理器 = 省地图对象+1760, 调用方经 idler qword_14332F698 vtable+128 (槽 16) 取省地图对象后取 +1760, §4.14.4) | 定案 (行为链: malloc 72B → 逐字段初始化 → SetOrder → 三链注册 → 返回实例) |
| 0x14166F7B0 | 浮动港口 (种类 1) 专用创建器: 扫州容器找 (省图形记录+210 & 9)==9 的省 → per-省表查种类==1 实例 → 复用/创建 | 高置信 |
| 0x1416717C0 | 创建校验门 (与 LoadBuildings 同款双门) | 高置信 |
| 0x141670A80 | 位置选择 A (def+19==0 哈希随机扫描州内省) | 高置信 |
| 0x141670890 | 位置选择 B (省建: 省图形记录+184 + per-省表+24×prov) | 高置信 |
| 0x141671220 | 位置选择 C (州建: CState+48→+328 位置 qword + 高度图边界校验) | 高置信 |

创建器主流程 (定案): 门禁 (a2≠0 → a1+72 特例表 (a2−1) 项空即拒创; a2==1 转发 0x14166F7B0; a2==0 → a1+36 门 ∧ per-def 计数门双关) → 哈希种子 = 州 id + 实例序号 a5 (6 步 mul-xor-shift 确定性链, 同种子同位置) → 三支选位 (def+19 位置模式旗: 0 → sub_141670A80; 1 → 省建 (def+28==1) 走州省列表 + sub_141670890, 州建走 sub_141671220) → sub_140A60F10(CMap+376 高度场, x, z) 采 y → 朝向: def+18 水域旗置位 = atan2(省中心 − 槽位) − π/2 (面朝相邻水域省), 否则哈希随机朝向 → qword 读 def+88 同填实例 +0/+4 → SetOrder(inst, 0) → 注册管理器总表 + per-省链 (省 id≠0 时) + per-州链。三调用方 = sub_141B47E30 (单创建) / sub_141B4E460 (批创建循环, 1.5× vector) / sub_141B44FD0 (计数门后循环)。

**建筑实例管理器布局** (省地图对象 +1760; 新档):

| 偏移 | 类型 | 语义 | 档 |
|---|---|---|---|
| +24 | 结构指针 | per-def 记录数组基 (24B 步按 def id 索引; 元素 +12 = 计数门, 0 即拒创) | 定案 |
| +36 | u32 | 创建可用性门 (a2==0 支首关; 语义推定 = 建筑系统已注册) | 推定 |
| +72 | 指针数组 | 特例 def 表 (8B 步, **1-based**: a2−1 下标; a2==1 项 = floating_harbor; 空指针拒创) | 定案 |
| +96 | 表头数组 | per-州 实例链 (24B {data@+0, cap@+8, count@+12, alloc@+16}, 按 state id 索引) | 定案 |
| +120 | 表头数组 | per-省 实例链 (24B 表头, 按省 id 索引) | 定案 |

另: 省图形记录 +112 = 槽位数组 (经 sub_14140A320 线性查找, +112 data / +124 count / 12B 步比 u32 key; 条内 +8 int / +32 位置 qword, 跨距矛盾待裁); sub_1416760F0 = 水域省/槽位解析 (4 参 = mgr, prov_id, x, z); sub_1401205A0 = 1.5× 扩容 vector 追加器 (8B 元, 三链共用)。

未决: SaveBuildings 写回行列序 (asm 级) / 网格变体打分与 mgr+24/db+40 双句柄表关系 /
E2 双容器活体对拍 / aEntity_0 串本体。

#### 4.26.11b buildingdb.cpp 派生类别面 (CBuildingDatabase vtable[2] 重建器; 3 巨函闭环)

清册 (3/3 函体内含 buildingdb.cpp 路径锚): 派生类别表全量重建器 0x140684870 (1249,
**CBuildingDatabase vtable = 0x1427E4190 5 槽, 槽[2] = 本函**) / spawn point 生成与登记
0x140686280 (328) / sp 链桶索引构建 0x140687110 (167, assert :394 "AllSpawnPoints.GetSize()
>= AllBuildings.GetSize()")。

**类别面全景** (定案): 25 张内联类别表 (谓词→偏移逐项成表, §4.34.21 AI 八表全在其内) +
6 wrapper 表 (PE 机器码单谓词直证, 5 张与内联镜像) + +904 未裁 + +40 链桶。**六特名槽**:
+928 supply_node (token 0x4CBE; **装载期用途定案** = `map/supply_nodes.txt` 节点建筑类型硬编码取本槽模板作 def, 不经脚本解析, §4.21.1a-4) / +936 rail_way (0x4CC1) / +944 infrastructure (0x2FAB) /
+952 naval_base (0x31F6) 按 token; +960 arms_factory / +968 industrial_complex 按 stricmp。
缺省告警 (:584-:609) + null 模板兜底 (null_object.h 单例 sub_140686BF0; dockyard/bunker/
coastal_bunker/synthetic_refinery 串锚)。

**同构第二例 (CTechnologyDatabase, §4.7.17)**: vtable 0x142944150 同为 TGameItemDatabase 5 槽族表, 槽[2] = 装载尾重建器 sub_140ACE570 (科技库 parent 继承合并 + 反向索引登记 + XOR 路径树坐标 + root-key 传播); 调用者同为家族 Load 包装 sub_14018B330 的 `(*vt+16)(a1)` (boot sub_14018BB20 → sub_140163E30 → "common/technologies"), 无直接调用者 — 纯虚表驱动模式跨库一致。

**spawn point 合成链** (定案): null sp 占 index 0 → 逐有效模板生成自动 sp (assert :294 钉死
GetIndex 对位) → 命名 sp 撞 token 则销毁 (:312, 建筑赢) → CIBTD 回填模板+1200/+80 (具名覆盖
自动) → 合成表回写 **db+112**; 链桶沿 +80/+84(357) 把 template[i] 推入桶[节点+88], 产物挂
db+40。**GetIndex = 模板+736 (1 起顺序索引, 0 = null)** — §4.34 三处 +736 引用的值域以此为准
(「类别 token」→ def 顺序索引; 「主数组 +736/+748」→ 类别表, 主数组在 +64/+76)。

**增补定案**: ctor sub_140681090 双 vtable 写 (先 TGameItemDatabase<CBuildingDatabase>::vftable 再覆写 CBuildingDatabase::vftable) = **TGameItemDatabase 模板直系实例 PE 级直证**; 布局 init 序 +8 paths / +32 重入计数 / +40 链桶产物 / **+64 主表 {data@+64, cap@+72, count@+76, alloc@+80 = off_143085170}** / +112 合成表 / +136 40B sp 记录表 / +160 {data@+160, cap@+168, count@+172} 48B 元素表; boot 建 qword_14332EE28 单例后 push "common/buildings"; 重建器 = 家族装载尾三连 [2]+[3]+[4] 的 [2] (无直接调用者 = 纯虚表驱动)。**执行序**: ① 特化唯一性检查 (模板+664 数组/+676 计数排序相邻重复 → :437 "Duplicated specialization '%s' in building database.") → ② sp 合成 → ③ 链桶挂 db+40 → ④ 六 wrapper 表 (+184←sub_14067F410 / +208←FC70 / +232←800A0 / +256←F840 / +280←804D0 / +304←80900, 各 = 谓词过滤列表拷贝) → ⑤ +904 ← sub_1406869C0 → ⑥ 25 张内联类别表 → ⑦ 六特名槽 (缺省均落 null 模板 sub_140686BF0 兜底, +944/+968 有显式 "no infrastructure/industrial complex building template defined" 告警)。**sp 合成前 db+160 表清空律** = 逐 48B 元素 vtable[0](elem, 0) 析构 + count@+172 = 0 (重建前销毁上一轮产物)。

**+904 谓词定案** (sub_1406869C0): 5 桶模板分区表 (24B/桶, 桶 0 恒空); 桶 1/2 按 模板+700 > 0 二分; 桶 3/4 = 同判据再按 模板+870 旗为假细分 (+700/+870 语义与读侧消费待裁, 谓词结构定案)。

未决: 五对镜像表消费方差异 / vtable[1] 语义 / sp 工厂与回填助手内部 / 模板旗族
+865..+885 脚本键名 (需 reader 0x1414BB530 侧反查)。

#### 4.26.12 GUI/渲染模板 Type 族 (指针)

精灵 (CSpriteType 族) 与 GUI 控件 (CGuiType 族) 模板 Type 全表 = 模板解析件族 (writer = CFG 空桩, 不入存档), 已移至 GUI 域 §4.30.31 / §4.30.32。

#### 4.26.13 CDefines 装载链 (defines.cpp 骨架)

装载流程 (sub_14074A9E0 `CDefines::Load(bool)`):

| 步 | 函数/槽 | 语义 |
|---|---|---|
| 1 | sub_1424DC600 | 枚举 common/defines/*.lua |
| 2 | sub_14206FEF0 | 逐文件装载执行 (loadbuffer+pcall, 机制见 §4.26.2b); 失败 → 日志 "An error occured when loading defines in %s. Defines won't be reloaded." 且**整批放弃** |
| 3 | functor 注册表 | qword_143338428 {data@0x338428, count@dword_143338434} — 每键一个 CRT 静态初始化小函数 push (vtable off_143087EA8 族); 依序跑全量, 每 functor 的 luabind::cast_failed **单独 catch 续跑不中断** ("Define cast failed" / "Unable to load a define: %s"; 计数桩 sub_1425F8030 `++*(u32*)(ctx+576)`) |
| 4 | — | 日志 "%d defines loaded" |
| 5 | sub_14074BDC0 | PostLoadValidate (下表) |
| 6 | a1=真 | sub_140D05BE0 补 INTEL_COUNTRY_LEVEL_MAXIMUMS 4 元 + 遍历监听器数组 qword_143339AF8 {count@dword_143339B04} 逐个 vtable[1](self, 0) — (D05BE0 本体无参, 只做归一 4 元 + 静态缓存刷新 qword_1433390B8 → xmmword_14333CC58/68; 监听器遍历在本 dispatch 调用方体内) |

调用点 5: InitGame 主初始化 sub_140147EE0(0) / gameapplication 重载 sub_1401750F0(a1) / 文件监视器 sub_140223750("common/defines/", 0) / 控制台 "Map reloaded" sub_14027A670 / 转发壳 sub_1401A4A20。

NDefines 全局表与 mod 覆盖双轨 (定案):

| 项 | 语义 |
|---|---|
| 引擎消费入口 | 合并后单一全局表 `NDefines` — CDefines::Load 内 lua_getglobal("NDefines") 后取 registry ref, 全部装载器 functor 从此表寻址 |
| mod 覆盖轨道 ① | 同名 defines 文件整文件替换 (PHYSFS 挂载优先级) |
| mod 覆盖轨道 ② | 异名文件追加装载, 写法决定合并粒度: 平铺赋值 `NDefines.NGroup.KEY = v` = 按键合并; 重建外壳表 + `for k,v in pairs()` 回填 = 组级合并 |

PostLoadValidate 修复表 (sub_14074BDC0; 「动作」列 = 计数不足/非法时的自动修复):

| 检查 | 槽 | 动作 |
|---|---|---|
| OPERATIVE_SLOTS_FROM_FACTION_MEMBERS_FOR_SPY_MASTER 表不存在或计数为奇 (dword_143338714) | qword_143338708 | 报错 + 编译期默认对 (xmmword_142935960, 2 元) 重建 |
| PLAN_EXECUTE_SUPPLY_CHECK 计数≠5 (dword_143339524) | qword_143339518 | 报错 + sub_140611B00 填 5×100000 (=1.0) |
| PLAN_COHESION_WEIGHTS 计数≠4 (dword_14333953C) | qword_143339530 | 报错 + 填 4×100000 |
| GENERAL_PROXIMITY_DEFAULT ∉ {CLOSE, MEDIUM, FAR} | dword_143333900 | 仅报错 |
| 13× NAI.AREA_DEFENSE_*_WEIGHT 计数≠3 (0x3384B8..0x3385CC 十三槽) | qword_1433384B8.. | 报错 + sub_1409B7DC0 填 3×0 |
| INFLUENCE_NEUTRAL_DIST_CAPITAL ≥ MAX_DIST_CAPITAL | qword_143333220 vs 143333320 | 仅告警 (六 INFLUENCE 槽与 §4.26.5b diplomacy 簇钳位互证) |
| INFLUENCE_NEUTRAL_DIST_CORE ≥ MAX_DIST_CORE | qword_143333438 vs 143333548 | 仅告警 |
| INFLUENCE_NEUTRAL_DIST_CONTROLLED ≥ MAX_DIST_CONTROLLED | qword_143333650 vs 143333730 | 仅告警 |

#### 4.26.14 train_gfx_database.cpp 火车 GFX 运行期 (2 函闭环 — gfx_train 解析 / wagon list 三级回退)

簇清册 (体内 cpp 锚 2/2; §4.26.10 系原仅类名录/容器远证):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_140AE0310 | 935 | train_gfx_database.cpp :321 (①) / :327 (②) + gameitemdatabase.h:142 | gfx_train 定义块解析器 (五键 → 64B 记录) |
| sub_140ADFC20 | 69 | :102 (②) | wagon list 三级回退解析器 (国家键 → graphical culture → default) |

**CTrainGfxDatabase 布局增补** (vtable 0x1429453B8; +152/+176/+200 三 vec 书已录, 本批加列): +128 指针 vec = **wagon 实体对象池** (64B/实体; wagon_data 块建, +40 f32 = 1.0f / +48 f32 = 2.0f 默认缩放, 推定) / +152 = default wagon list (token 11405) / +176 = 按 graphical culture 库内序号索引 (CGraphicalCultureType +48 互证) / +200 = 按国家侧键索引 (键 = gs[104]+4×值 重映射序, 推定二序 graphical culture)。

**64B wagon 记录** (三 vec 共用元素形态; 定案):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | int32 | 键 = 火车装备 token (升序, 二分查找域) |
| +8 | 指针 vec {d@8, c@16, n@20, alloc@24} | wagons 列表 (实体指针数组) |
| +32 | 指针 | wagon_0 (token 19720; **有效门: 非空才可命中**) |
| +40 | 指针 | wagon_1 (token 19787) |
| +48 | 指针 | wagon_2 (token 19788) |
| +56 | 指针 | wagon_last (token 19817) |

**解析器** (sub_140AE0310; (db, 目标 24B vec, 解析器, 实体名表)): 五键全认领 — 19700 wagons = 块键 (名串列 → FNV-1a 查实名哈希表 (48B 桶 {state u8@+4, SSO 串@+8, int id@+40}, robin-hood 形) → *(db+128)+8×id 取实体指针 → push 记录 +8 vec); 19720/19787/19788/19817 = 单实体名 → 写 +32/+40/+48/+56。`@` 前缀值走 sub_1424C04A0 引用解析。装载前置门 = token 已载旗 (sub_1409F8840/sub_1409F7F60 +16); 未载 → "invalid equipment:" 跳过。校验: wagons 空 ‖ (wagon_2 有而 wagon_1 无) → ②:327 "Invalid gfx_train configuration at: %s"; wagon_0 名解析失败 → "invalid wagon_0"; 实体名未中 → "invalid entity name"; 未知键 → ①:321 "Failed to read gfx_train data." (B52, 闩 byte_14333A273)。上游驱动 0x140ADF1F0: 顶层 11405 default → 解析 db+152; 19696 wagon_data → 实体入池; 具名 graphical culture 块 → culture+48 序号 → 解析 *(db+176)+24×序号。

**三级回退** (sub_140ADFC20; (unit) → wagon list vec 头): 国 = sub_140BB48F0(unit+28) → 一级 *(国+4876) > 0 → gs[104]+4×值 重映射序 → db+200 vec (24B 步长条目, hash = sub_140BB5490(键)); 二级 *(国+4128) (graphical culture 对, +48 序号) → db+176; 三级 db+152 default; 全败 → ②:102 "couldnt find wagon list for %s" → 返 0。二分器 sub_140ADFDB0 = 按装备 token 与回退 token 两轮 (键 = 记录 +0), 命中门 = wagon_0 (+32) 非空 → 返记录 +8。唯一调用方 = gfx_train.cpp 首函 sub_141C64130 (442 行件, 火车编组装配消费侧, 高置信)。**运行期实体开关 sub_141C65520** (:443): a1+0 = 实例槽 / 类型 def = *(*(a1+8)+4); a2=1 ∧ 实例空 → 创建 sub_14228CD30(def, 7, 6, 0) + "idle" 动画 (sub_1422908E0) + sub_1422902D0(ent, 1) (幂等惰性); a2=0 ∧ 实例非空 → sub_14228D700(ent) + 置 0; 创建后空守门 :443「_EntityInstance」B52 (闩 byte_14338C495)。

未决: +200 键来源精确定义 / 实名哈希表在 db 内挂点 / 上游驱动具名块分发全表 / gfx_train.cpp 首函本体。

#### 4.26.15 terrain 库装载 reader 与占领修正 tooltip 装配器 (terrain_database.cpp + occupation_modifier.cpp + terrain_text.cpp; 3 函闭环)

簇清册 (体内 cpp 锚 2/2):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_140AD5F70 | 687 | terrain_database.cpp :77/:93 (CLogStream 65540) + gameitemdatabasehelper.h:149 尾锚 | terrain 库逐文件装载 reader (terrain/categories 双分支) |
| sub_1413C2100 | 815 | occupation_modifier.cpp:116 (断言 B52, 闩 byte_14338A2E8) | COccupationModifier tooltip 装配器 |
| sub_141A98B30 | 46 | terrain_text.cpp:41 (CLog 错误) | 地形本地化单属性文本源 GetPropertyText |

**terrain reader 双分支** (sub_140AD5F70 调用者唯一 = TGameItemDatabase 装载遍历 0x140AD6BB0): 偷看 token (lexer 槽 vtable[1], 0 → 错误码 19) → 按块键分派:

| 块键 | 行为 |
|---|---|
| 10329 = terrain | 循环读条目至右括界/EOF; 条目名 = 当前文本 + mod 目录串前缀 (sub_140BC96D0) + sub_140625B10 修饰 (@ 命名机制 书已载); malloc 512 → ctor sub_14143BCF0(obj, 全名, A 族 count) (第三参 = 库内自索引) → vtable[3] Parse → 入 A 族数组 + 名索引 (元素 +32 = 块键 token) |
| 11352 = categories | 同形循环; malloc 112 → ctor sub_14143BAE0 → Parse 后: 对象 +76 = 颜色索引数, = 0 → :77 "has no colors assigned to it." (后续 vtable[0](obj,1) 语义待裁); > 0 → 遍历对象 +64 位图字节数组: LUT 容量不足扩到 idx+1 (memset 0 补洞); LUT[idx] 已非零 → :93 "attempts to use index (N), which is already used."; **LUT[idx] = 对象+96 (ctor 写入的第二数组自索引; 0 = 未用哨兵)** — 「位图字节→第二数组下标」直证 (书已载) |

库对象布局细化: +40 名索引 (40B 元 {名 SSO@0, 块键 token@32}) / +64 A 族指针数组 / +88 categories 名索引 / +112 第二数组 / +136 LUT (4B int); 数组增长统一 ×1.5 经分配器 vtable[1]/vtable[2]。条目收尾消费 @ 尾注 (首字节 0x40 → sub_1424C04A0 解析 {int, byte, 串} 存 lexer+0/+4/+8, 语义待裁)。

**地形本地化文本源** (sub_141A98B30; (out std::string*, terrain def, property 序号)): **仅支持属性序号 0** — 取 terrain+24 名 SSO (32B std::string, 堆/SSO 判据 = cap@def+48 > 15) 经通用取值器 sub_140623700 (任意对象 +24 std::string → out) 输出; 序号 ≠ 0 → terrain_text.cpp:41 CLog "Unknown localization property for terrain" + out 赋常量 "UNKNOWN_PROPERTY" (len 16, sub_140129CA0)。所属类继承链无 RTTI 直证 (推定 CLocalizationTextSource 派生, 待裁)。

**占领修正 tooltip 装配器** (sub_1413C2100; (def, out 串, ctx, is_active, show_threshold)): 头行 = def+16 名本地化; 类型标签 = def+176 枚举 (0/1 → "RESISTANCE" / 2/3 → "COMPLIANCE" / 其余断言 :116 "invalid modifier type"); is_active 分支 → TO_DISABLE = (threshold − margin)/100 (u64 溢出门 → 0xFFFFFFFF 哨兵) + "OCCUPATION_MODIFIER_ACTIVE[_WITH_TRIGGER]" 键 (def+324 非零 = 有触发条件旗); 非激活 → TO_ENABLE = threshold/100。四 88B 块发射: enabled (+304) 走 vtable[12] 触发条件文本 / on_enable (+392) 与 on_disable (+480) 走 vtable[8] 效果文本 (非空旗 +20)。state_modifier 节 = def+704 > 0 或 def+620 门 → 扫 +584 修正 id 数组 (sub_14055F700 可见性位掩码门: def+104 与 qword_1433300A0() 相与) → "OCCUPATION_MODIFIERS_TOOLTIP" 节 + 共享修正清单格式化器 sub_14055AB90。尾行 = def+48 tooltip 本地化。修正 def 数组基址 = qword_14332ED90 (120B 步距, 与 modifierentry 同表)。


作用域本地化单属性文本源同族四件 (**province_text.cpp 0x141A97130** = 第四件, 仅属性 0 合法, 取名经 sub_140E7C230 (名空走 fallback sub_140E7D730); 非法处置 = CLog flags=0 无闩 + 常量 "UNKNOWN_PROPERTY" (:75), 与 terrain 同档; special_project_text.cpp 0x141A976C0 / purchase_contract_text.cpp 0x141A95F20; 四件同签名 `(a1, std::string* out, 属性序号)`, 仅支持序号 0):

| 项 | special_project | purchase_contract |
|---|---|---|
| 正常路取值 | sub_140FE30A0(a1, &v9) 取 def，写 **def+64** 串 | 由交付态子对象 a1+472 计算进度文本（+32 已缓存旗，!1 → sub_141445800 计算 + 置 1，惰性缓存；+40 当前进度；sub_1414452F0 起点迭代器；sub_1413B9FA0 由 (a1+24 基数, 终点−起点区间长度) 生成） |
| 非法序号处置 | **断言闩** flags=1（:69，闩 byte_14338BF59） | **CLog flags=0 无闩**（:84，闩 byte_14338BEA9） |
| 前置校验 | — | contract_delivery_state.h:30 `IsValid()` 断言（闩 byte_14332FD01；对象 = a1+474 指针域） |

非法属性处置三档不一：terrain = CLog + 常量 "UNKNOWN_PROPERTY" / special_project = 断言 / purchase_contract = 无闩 CLog。〈定案〉
未决: +176 两档枚举各侧两值语义 / categories 无颜色路径 vtable[0] 调用语义 / @ 尾注块语义 / LUT 0 号边界 / 建筑健康因子 clamp 形态 (§4.7.11)。

#### 4.26.16 script_enum_database.cpp 通用脚本枚举库 (2 函闭环 — §4.23.15 装载期对账的通用底座)

簇清册 (体内 cpp 锚 2/2; 全部新定性):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_140AAA160 | 605 | :22 / :28 "duplicate script enum definition" / :35 "Script Enum file invalid syntax!" | LoadFromFile (枚举文件 → 哈希表) |
| sub_140AA9BA0 | 86 | :63 "non existing script enum %s" | robin-hood 查找 (键 → 值向量) |

单例 qword_14332F028 (gameitemdatabase.h:142 断言族)。表: +72 条目数组 / +84 桶掩码 / +88 越界溢出槽数 / +40 空值哨兵。条目 40B {距离 u8@+4 (0xFF = 空), 键 = 枚举名 token id u32@+8, 值向量 data@+16 / cap@+24 / count@+28, 分配器@+32}; 哈希 = 0x45D9F3B 双轮终混作用于 (键 ^ HIWORD(键))。文件格式 = `<名> = { 值… }` (值 = 裸整数或串 token 经串→整数); 读取器 = CReader (§4.00.17), @var 替换内联五处。**§4.23.15 的 script_enum_equipment_category ↔ EQUIPMENT_CATEGORY_META 对账即消费本通用件** (查找返回条目+16 值向量, 消费方 sub_140632BF0 按 {数据, 计数@+12 相对} 遍历 int32 值数组 = 成员 token id 序列) — 三表对账机制上游底座定位。

消费全集 (六个枚举全数以硬编码 token id 被代码按名查询, 无空挂; 定案):

| token id | 枚举名 | 值域 | 消费点 |
|---|---|---|---|
| 10986 | script_enum_advisor_slot_type | 开放 (原版 6 值) | sub_1412A3C70 (CAdvisor 装载, characters advisor 块 slot = 值校验) |
| 10987 | script_enum_equipment_bonus_type | 开放 (原版 495 值) | sub_140632130 (CSpecificEquipmentBonus Load, 存档恢复期) / sub_1409F5FC0 (CEquipmentDatabase::CheckEquipmentTypeSanity 启动自检) |
| 11056 | script_enum_operative_mission_type | 开放 (原版 5 值) | sub_140660520 (CAIOperativeMissionStrategy 装载) |
| 16223 | script_enum_equipment_stat | 闭 — ↔ EQUIPMENT_STATS_META (原版 78 值) | sub_1413E4AC0 (MIO equipment_bonus 键域值集) |
| 16224 | script_enum_production_stat | 闭 — META 对账推定 (原版 7 值) | sub_1414957D0 (MIO production_bonus 键域值集) |
| 16225 | script_enum_equipment_category | 闭 — §4.23.15 双向对账 (原版 38 值) | sub_140F87B00 (equipment_category 值集) |

- 枚举名在引擎代码中不以字符串出现 (`"script_enum_` 前缀全 dump 零命中), 均编译期 token 常量直传; 六名之外的枚举名无消费点 (= 死数据)。
- 值校验仅报错不拒值: 单值成员判定 sub_140632BF0 miss → "Value does not belong to designated Script EnumType: %s not in %s" (4096 日志流), 值照常入对象。
- 值级重复静默容忍: 装载器报错串仅枚举名级 ("duplicate script enum definition") 与语法级两类, 无值级查重; 成员判定 = 线性扫描, 重复无害。
- 闭集三枚举与代码 META 表装载期双向对账 (改 vanilla 镜像值必触发启动报错); 开放三枚举无代码闭集, mod 可增删 (删 vanilla 值 = 该值退出对应键域, 仅影响脚本合法性不影响引擎运行)。

#### 4.26.17 CBuildingStatus::GetMaxLevel (buildingstatus.cpp; 1 函 — 省建筑可建等级四源钳位)

sub_141177310 (768 行; 锚 :702 断言 "IsProvince() && Trying to get a province building level on state building status" B52 + :745 格式化错误日志 "Missing localization key for state category: %s"): `i64(status, CBuildingTemplate*, tooltip 串*)` → max_level。

**四源钳位计算** (省模式, 断言 :702): base = sub_1414B97D0(def); 现有等级 = 省建筑实例表 (*(status+56)[def+736 模板顺序索引] — 与书「GetIndex = 模板+736」互证); v74 = **地形上限** sub_14143D0C0(州地形, def) + **州档位表两项** (档位容器 = AsProvince+192, 按 def+920 与 0x1414BA6B0(def, 地形) 键各查一项) + **国家映射两项** (国 +1464 表, 按 def+916 与 0x1414B9860(def, 州) 键; fixed 1e5 取整带负数 floor 修正); 结果 = min(base, 现有+v74) 再对 base 修正钳一次 (status+112 ≤0 回退 AsProvince+392 / AsState+204; AsState+2200 +16 旗置位经 sub_1413C4A80 重算)。def+700 ≤ 0 (非省建) = 简化分支: min(base, 现有+修正) 直返 (SLevelMax.province_max 10771 互证)。

**tooltip 五段** (a3 非零): BUILDING_CURRENT_MAX_LEVEL → BUILDING_TERRAIN_MAX_LEVEL → BUILDING_TERRAIN_BASE_MAX_LEVEL → 州类目 (STATE_CATEGORY_<名> 存在性检查, 缺失 :745 日志) → 四修正键逐条 (共享现值格式化器) → 现有等级行。

**CBuildingStatus 布局补**: +32 省建筑索引宿主 / +44 省模式旗 / +56 CBuilding* 数组 (prov+344 互证) / +104 bit0 IsProvince / +112 加成缓存; AsProvince() = sub_141177080 (+104 校验) / AsState() = sub_1411771B0 (gamestate 门); AsProvince+184/+168 州地形 / +192 档位修正表 / +392 州级回退; AsState+204 回退 / +2200 base 修正宿主。**CBuildingTemplate +916/+920 两修正映射键已补入 §4.26.11 表** (+892 与 +976 间空档)。

未决: +916/+920 对应 reader 脚本键名。


#### 4.26.18 CPortraitDatabase 取像链 (portraitdatabase.cpp; reader 0x140A86E70 / 校验器 0x140A89BD0 / 取像器 0x140A877B0 三函闭环)

CPortraitDatabase (vtable 0x14293FD90; 基 VCPortraitDatabase::?$TGameItemDatabase; 单例 qword 0x14332EFD8):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +16 | 匿名结构 (块对象) | `default` 块解析目标 (token 11405 → 递归解析入此) | reader |
| +40 | RH 映射 (名→条目) | 装载期键 = 组名串; 运行期键 = cosmetic_tag / original_tag / tag | reader + GetPortraitsForCountry |
| +48 | 条目指针 | 空对象哨兵 (查无时回落值; ≠ 哨兵 → 取 value+48 为载荷) | GetPortraitsForCountry |
| +64 | 条目指针[] | 映射桶数组 | reader (`16*(hash & mask) + 8` 桶头) |
| +88 | uint32 | 桶 mask | reader |
| +104 | CCountryPortraits 载荷[] | 大陆载荷数组基址 (元素 400B, 下标 = 大陆索引) | reader + 取像器 (`400*v38 + db+104`) |
| +116 | uint32 | 大陆数 (人口加权缓冲维度) | 取像器 |
| +136 | CPortraitPool 内嵌 (72B) | 库默认池 type 2 | 取像器回落 |
| +208 | CPortraitPool 内嵌 | 库默认池 type 1 | 取像器回落 |
| +280 | CPortraitPool 内嵌 | 库默认池 type 4 | 取像器回落 |
| +456 | CPortraitPool 内嵌 | 库默认池 type 5 | 取像器回落 |

> +280..+456 间 176B 未由本批函数消费 (推定含 type 3 默认池 @+352 与另一成员, 未证)。

idb 条目值对象:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0..+47 | 匿名结构 (48B 头) | idb 条目头 (名/FNV 等; 内部逐字段布局未决) |
| +48 | CCountryPortraits 载荷 (400B) | 5 池 + 政治池 (布局 §4.26 名字/头像库族段) |

portrait 类型枚举 (取像器第五参 a5):

| 值 | 语义 | 状态 |
|---|---|---|
| 0 | 推定 civilian | 未实现 ("Not implemented" 断言) |
| 1 | 推定 army | 已实现 → 载荷 +80 |
| 2 | 推定 navy | 已实现 → 载荷 +8 |
| 3 | 推定 air | 未实现 ("Not implemented" 断言) |
| 4 | operative | 已实现 → 载荷 +152 |
| 5 | scientist | 已实现 → 载荷 +328 |

> 本枚举与 §4.4.10 EPortraitType 同一值集 (TokenToPortraitType 直证 0 = civilian / 1 = army / 2 = navy / 3 = air / 4 = operative / 5 = scientist, 高置信); 池序 +8/+80/+152/+256/+328 与类型序 2/1/4/3/5 的错位关系仍待解。性别 (第六参 a6): 1 = male → 池头 @+8 (count@+20); 2 = female → 池头 @+32 (count@+44)。

取像三级回退 (GetPortrait 主流程):

| 级 | 行为 |
|---|---|
| 1 国家条目 | GetPortraitsForCountry: 键优先序 cosmetic_tag (country+5256 SSO 串, §4.3.8) → original_tag (country+4876 tid>0 时) → tag (country+8); FNV-1a 查 db+40, 命中 → value+48; miss → 全局默认 unk_143339ED0 (懒构造 + atexit 注册) |
| 2 大陆回退 | 国家池男女两 count 皆空 → 遍历 country+1120 controlled_states, 每州人口/1024 累入大陆桶 (下标 = stateDef+320 CContinent* → +48 大陆索引); 本国所在大陆权重 × 本国加权 define; 随机量 % 总人口落大陆下标; 国家池部分非空 → 直接取本国大陆 (不走人口加权) |
| 3 库默认池 | 拷入本地 CPortraitPool 后, a6 对应性别头 count 为 0 → 回落 db+136/+208/+280/+456 |
| 4 池内抽取 | 权重 = 元素 weight u64@+0; 前缀和结构 (Fenwick 形二分); 随机量 % 100000, 按性别池非空双路缩放 (总权重×随机量 或 总权重×随机量²/100000); 落点项名串 (元素+8) 拷入出参 |

PRNG (第二参 = int32[2] 种子对, 每次调用 a2[0] += 2): 两条 hash 链 (常量 1255572915 / 1759714724 / 458671337 / -1831433054); 输出 1 = 链 A & 0x7FFFFFFF (大陆加权抽取), 输出 2 = 链 B % 100000 (池内抽取); 链 B 输入 = 链 A 输入计数 +1 形 (两次伪独立抽样)。

装载解析 token 表:

| token id | 名 | 语义 |
|---|---|---|
| 11405 | default | 默认块键 → 解析入 db+16 |
| 10572 | continent | 大陆块键 → 期望名串 (token 27) → 大陆库匹配 |
| 27 | name | 串字面量 |
| 12775 / 10773 / 593 | male / female / weight | CPortraitPool 三键 |

错误处理: reader 大陆名不匹配 = CLogStream 一行式 (通道 65540, 无中断; 串全文 = "<组名> - expected continent name, got <值>" 与 "<组名> - unknown continent <名>"); 校验器纹理缺失 = 同形 (通道 4096, "Missing portrait texture in group %s: \"%s\""); 取像器 = 断言形态, 布点精化 (定案): 首分派 switch case {1,2,4,5} → 载荷 {+80,+8,+152,+328}, **default (0,3) 静默 return 0** — type 3 载荷 +256 无证据; "Not implemented" 三连实在后续三 switch 的 case 0:/case 3: (布点 :431 大陆回退选池 latch byte_143339EC6 / :470 库默认池回落 byte_143339EC7 / :527 尾段 byte_143339EC8); "Invalid enum value" (byte_143339EC5) 门 = 分派后池指针 0 (GetPortraitsForCountry 回落值空) 非"类型未知"; "nRandomPortrait >= 0" (byte_143339EC9) 维持原记。

#### 4.26.19 occupation_modifier 库装载闭环 (occupation_modifier_database.cpp; LoadFromDirectory 0x140A70FC0 503 行)

#### 4.26.20 建筑本地化属性取值器 (building_text.cpp; 1 函 = sub_141A83D40, 定案/宿主类待裁)

#### 4.26.21 scripted_localisation 运行时求值 (scriptable_localization.cpp; 1 函 = sub_140AABCE0 + 求值器 sub_140AABE30, 定案)

sub_140AABCE0 (脚本本地化定义 `common/scripted_localisation` 的运行时求值入口; 库布局 §4.26 umap @0x332f038 键 cs-FNV): 条目数组 {data@+40, count@+52, 元素 24B {+8 选项文本对象, +16 匹配器对象}} 顺序遍历 — 元素 +8 空 → :210「Empty scripted loc」(flags=0, 闩 byte_14333A09E) 跳过; 匹配器非空 ∧ `(*(匹配器 vtable+24))(匹配器, a2)` (CTrigger Evaluate 同形槽) 命中 → 退出。命中 → sub_140AABE30(文本对象, a2) 求值: 快路径 `*(a1+20) == 1` → sub_140AAB9A0(data[0]) + 256 (单选项直取); 否则 off_143085170 分配器建 `4×count` 临时数组排序后查找 (TLS 懒初始化 dword_14332ECF0 + atexit)。未命中 (遍尽) → 返 **&off_1430B0448 空哨兵表** (调用方须判空); 命中后二次校验 pdx_scopedptr.h:134「_pPtr」(闩 byte_14333A0A4)。

sub_141A83D40: a3 == 0 → 拷出 *(*(a1+480)+528) 的 MSVC 32B 串 (SSO: cap@+552 > 0xF 取间接); a3 ≠ 0 → CLog 4096 :46「Unknown localization property for building」+ 出参写 `UNKNOWN_PROPERTY` (sub_140129CA0, 16B 定长)。⚠ a1+480 所指对象的 +528 名串与 §4.26 building 库「tok8@+8」名位不一致 — 推定 a1+480 指向建筑实例或本地化上下文而非 def, 待裁。

**COccupationModifierDatabase** (264B = malloc 0x108; 单例槽 qword_14332EF90; creator sub_140172450 先写 TGameItemDatabase 模板vtable再覆写本类vtable):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | COccupationModifierDatabase::vftable* | vtable | |
| +32 | i32 | 旗 (creator 置 0) | 语义未决 |
| +40 | RH 表头 32B | 名表头 (子表见下) | 定案 |
| +72 | vector\<COccupationModifier*\>[4] 96B | 非 dynamic 分区向量 (type = 条目 +176 选向量) | 定案 |
| +168 | vector\<COccupationModifier*\>[4] 96B | is_dynamic 分区向量 | 定案 |

名表头 (相对 db+40; §0.2 RH 表头同形):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 桶数组* | creator 初始化 &unk_1430852A0; 桶 stride 48 {键 SSO@+8, 值 COccupationModifier*@+40} |
| +16 | i32 | count (creator 置 0) |
| +20 | i32 | mask (插入器探测起点 = hash & mask) |
| +24 | u8 | extra (creator 置 0) |
| +28 | f32 | 负载因子 (creator 置 1063675494 = 0.9) |

分区向量 24B (两区同形): data@+0 / cap@+8 / count@+12 / alloc@+16 (满则 cap×1.5 且 min count+1; 重配经 alloc vtable[+8], 旧块经 alloc vtable[+16] 释放)。

**COccupationModifier** (768B = malloc 0x300; ctor sub_1413C15D0; 字段与 §4.26.11 行 807 逐项一致, 本表补未载三行):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | i32 | def id = 名 FNV 哈希 (ctor 由 sub_1424BB460 算得写入) | |
| +16 | SSO 32B | 名 (由装载名串构造) | |
| +48 | SSO 32B | tooltip | |
| +80 | SSpriteFramePair 40B | icon (名 "GFX_occupation_modifier_strip") | |
| +120 | i32 | 值 1 (ctor 写入) | 语义未决 |
| +128 | SSpriteFramePair 40B | small_icon (名 "GFX_occupation_modifier_small_strip") | |
| +168 | i32 | 值 1 (ctor 写入) | 语义未决 |
| +176 | i32 | type 枚举 (ctor 默认 4 = invalid) | |
| +184 | i64 | threshold (默认 0) | |
| +192 | i64 | margin (默认 0) | |
| +200 | i32 | alert_level (默认 −1) | |
| +208 | i64 | alert_margin (默认 1000000) | |
| +216 | CBlock 88B | visible 块 | |
| +304 | CBlock 88B | enabled 块 | |
| +392 | COnAction 88B | on_enable | |
| +480 | COnAction 88B | on_disable | |
| +568 | CModifier 192B | state_modifier (ctor 基构造后覆写 CModifier::vftable; 名写入 CModifier+16) | |
| +656 | SSO 32B | 名第二份拷贝 (ctor 写入) | 用途未决 |
| +760 | u8 | is_dynamic (默认 0) | |

LoadFromDirectory 执行流程 (定案):

| 步 | 动作 | 门 |
|---|---|---|
| 1 | `sub_1424DC380(path, &outVec, ".txt", 0, 0)` 枚举目录 → 结果向量 {data, cap, count} (条目步距 64); 尾部逐 64B 调 sub_140160E00 清理 | — |
| 2 | 逐文件: lexer 取条目名 (token-ready 旗, `+24 dword == 19` = EOF 判终) → malloc(0x300) → ctor → **vtable槽 [3] (+24) Parse** | — |
| 3 | `*(obj+176) == 4` (invalid) → :40 `INVALID MOIDIFIER %s` (通道 4096, 引擎拼写错误原文) → 析构跳过 | 类型门 |
| 4 | 名串 FNV-1a32 (seed −2128831035 / prime 16777619) → `sub_140A6F200(db+40, &bucket, hash, &name, &flag)` RH 插入 (桶 stride 48, 探测 hash & mask) | — |
| 5 | bucket+40 已有值 → :49 `duplicate modifier %s` (通道 4096) → 从 db+72 与 db+168 两区各 4 向量线性删除旧值指针 → 析构旧对象; 新对象入桶 | 重名门 |
| 6 | `*(obj+760)` 真 → db+168+24·type 向量; 假 → db+72+24·type 向量 | 分区入库 |
| 7 | 装载尾对两区各 4 向量调 sub_140A6FBD0 排序 (≤32 元插入排 sub_140A70630, 否则归并 sub_140A70710) | — |
| 8 | gamestate.h:1126 断言 (B52 门, latch byte_14332ED01) 确认线程可访问 gamestate; `*(gs+2617)` (ingame 旗) → 取 idler (qword_14332F6A0) +1720 handler → `sub_140B674F0(handler, 11)` 与 `sub_140B674F0(handler, 0)` 取 per-country 视图槽 `*(handler + 8·idx + 200)` 各调vtable槽 [+16] | UI 刷新通知 |

> 本函数所有 `a1[N]` 形态访问的 a1 是 `_DWORD*`, 故 `a1 + 18` = 字节 72、`a1 + 42` = 字节 168、`a1[6·type + 45]` = 字节 180+24·type; 插入器入参 `(_DWORD)a1 + 40` = 字节 40 (伪码 dword 强转隐藏 ×4 缩放, 与 creator 表头初始化逐项对方才定案)。

#### 4.26.22 键名可移植性校验本体 (装载协议九步第 3 步; 1 函 = 0x140624D30, 定案)

0x140624D30 (key std::string*, 出参串) -> bool: 逐字节扫 key (sub_1424CB4D0 下标访问), 收集 `>=0x80` 字节 (1.5x 增长数组, 分配器 = off_143085170 vtable[1]/[2]); 收集空 -> 返 1 (全 ASCII 合法); 非空 -> 出参追加 `dword_14272DA98` 6 字节前缀 (内容待 PE 取证) + 收集字节原串 + " extended ascii or partial UTF* character(s) " + 首字节单字符 + 循环 ", "+每字节 + " found in key", 返 0。宿主 sub_140625B10 (debug 门 byte_14332EC69, 见 4.26 装载协议段已收职能句) 失败路发「Warning: Possible portability issue with key」。

#### 4.26.23 禁运 AI 权重 define 配对与评分结构 (1 函 = 0x141118740, 功能域定案/符号名未决; 函数详情待 AI 域批)

**8 项 define ↔ 数据槽配对 (5 项本批新配, 全部定案)**: dword_143331F38 = **EMBARGO_SAME_IDEOLOGY_AI_WEIGHT** (同意识形态基重) / dword_143331FD8 = **EMBARGO_DIFFERENT_IDEOLOGY_AI_WEIGHT** / dword_1433320A0 = **EMBARGO_DIFFERENT_IDEOLOGY_AT_OFFENSIVE_WAR_AI_WEIGHT** (进攻战加成, 谓词 sub_140700510) / dword_143332148 = **EMBARGO_RECIPIENT_IS_MAJOR_AI_WEIGHT** (目标 cc+5210 major 旗加成) / dword_1433321D8 = **EMBARGO_NEIGHBOUR_AI_WEIGHT** (邻国谓词 sub_140433670 加成) / qword_143334140 = NUM_RESOURCES_TO_ALLOW_MINOR_EMBARGO (minor 资格资源门槛) / qword_143332858 = EMBARGO_WORLD_TENSION_THREAT_DIVISOR (张力贡献除数, 除零护栏 = 贡献 0) / dword_143337AC0 = DIPLOMATIC_ACTION_BREAK_SCORE (中止臂返回基)。**评分结构** (外交行动对象, vt+296 前置校验): 非 major 发起方先过资格门 (遍历 CStrategicResourceDatabase qword_14332F088 条目, 逐资源对 dip+368/{count@+380} 属国 tag 表逐国取 rs(cc+4600) 求和 ÷1e5, 全 ≤ 门槛 → 返 0); abort 臂 7 路 OR (同国/136 计数/关系旗 +744∧!+73/计数控/sub_140700870/sub_140D25880) → 返 BREAK_SCORE−1 或 0 (关系条目判定 sub_140D258E0); 否则基重 (dip+208+24 两容器 data 指针相等 → SAME 否则 DIFF [+进攻战]) + (min(计数, **15 硬编码 cap**) − 关系查表 sub_1406EC770 ÷1e5 ÷**3 定数**) + major + 张力 + 邻国 → max(…,0)。**+28 = 目标国 (recipient) 定案** / +20 = 发起方推定; cc+208 = 意识形态组容器推定。调用通道 = 函数表/指针 (语料无直 call)。

#### 4.26.24 「AI Theatre」ImGui 调试窗 (1 函 = 0x141AF5360, 定案/宿主类未决)

§4.26 调试面板族成员, 渲染槽 = 包装器 sub_141AF5330 (失败经 sub_141EE3020(a1+8) 收尾返 0), 由**调试窗分派管理器 sub_141198E70 条目 7** 经槽调用 (条目形 = {u8 使能, 8B 对象指针, 渲染槽}; 同表兄弟条目 = +0/+32 sub_141AE3CD0 / +1/+40 sub_141AE5FF0 / +2/+48 sub_141AE2FC0 / +3/+56 sub_141AEA730 / +4/+64 sub_141AE8710 / +5/+72 sub_141AE2240 / +6/+80 sub_141AEE060 / +13/+136 sub_141B163F0 / +18/+168 sub_141B1AFA0)。宿主类语料无 RTTI, 推定与 §4.26:709 AI weights tuner / fronts visualizer 同列。

对象布局:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | int32 | 当前显示国 tag id; 初值 = CInGameIdler 单例 qword_14332F698 虚表+160 返回的当前上下文 id |
| +8 | 对象 | gs 派生访问器 (sub_141EE2FC0 以 gs+1120 构造, sub_141EE33F0 收尾) |
| +24 | ptr | 战区行渲染器 sub_141AF2D50 上下文槽 |
| +56 | u8 | 「Enable Map View」旗 |
| +57 | u8 | 「Enable TheatreSystem」旗 (初值 sub_14132C0A0()) |
| +58 | u8 | 地图视图已上锁状态 (1 = 已切 AI 视图, 待复位) |

**控件链**: ① ImGui Begin `"AI Theatre"` (断言总门 byte_1435E1B52 开时走 gs 访问器断言链 gamestate.h:1125/1126, 闩 byte_14332ED00/ED01); ② Checkbox `"Enable AI View"` ↔ **byte_14332F63D = ai_view 旗** (§4.30:3038 外交 tooltip AI DEBUG 覆盖层消费面的互补写入面; 紧邻控制台 `ai` 总闸 byte_14332F63C); ③ Checkbox `"Enable TheatreSystem"` ↔ +57, 生效链 = sub_140BB48F0(tag→国) → sub_1406CF0E0(cc, AI 控制器) → sub_1402A8220(战区系统); 存在则 sub_141AF5BD0(解除全部分配) + 开/关 sub_14132BC50/BC40 + sub_1402A8C50, 不存在 → 文本 `"No AI "`; ④ Checkbox `"Enable Map View"` ↔ +56 → 调度器 sub_140A66B70 → **OnMapModeChange(mgr, 31, 0)** (mapmodedispatcher.cpp:238, 31 = AI 视图图层掩码, 位定义待裁) 或复位 (mgr, 0, 0); ⑤ 按钮 `"Regenerate Ai Theatres"` → sub_14132C4B0(重建); ⑥ InputText `"Tag"` (3 字截取 + sub_140BB41B0 建标签 → sub_140BB5470 校验 → sub_140BB5110 解析 → 写 +0; 非法 → `"Invalid tag"`, 合法 → `"Showing theatres of %s"`)。

**FlowUnits 预统计结构** (CollapsingHeader `"FlowUnits Prepass Stats"`, 统计对象 = sub_141AF52F0 → 同 AI 链取战区系统):

| 偏移 | 类型 | 输出语义 |
|---|---|---|
| +80 | int32 | Unit Pool total |
| +84 | int32 | Skipped — In Combat |
| +88 | int32 | Skipped — Naval Transfer |
| +92 | int32 | Skipped — Understaffed Front |
| +96 | int32 | active (scored); skipped = +80−+96 打印时现算 |
| +100 | int32 | Fronts |
| +104 | int32 | Score Evaluations |
| +108 | int32 | saved (评估缓存命中) |

**战区行枚举**: 容器 = sub_1402A8220(ai), 区间 {begin@+16, end@+24}, **步长 112**; 逐元 `sub_14136E9B0(元素+24) > 0` 门 → sub_141AF2D50 渲染单战区行 — 与 §4.34 NAITheatre 分划库 (112B 元素, 元素内嵌 LandTheatre@+24) **跨域同形互证** (同 112 步长 + 同 +24 内嵌, 运行时枚举侧与 AI 分划侧同一容器形)。


#### 4.26.25 ImGui::InputTextEx 本体 (PDX imgui ≈1.72; 1 巨函 = 0x1421EAA30, 2087 行, 定案; dg036)

ImGui::InputTextEx 输入框总入口 (原书 S11「文本流格式化」系误归, dg036 改判 ImGui 域)。签名 (label, hint, buf, buf_size, size_arg ImVec2\*, flags, callback, user_data) → char; a2 hint 槽 = InputTextWithHint 特征 (buf 空时以 TextDisabled 色绘制); 返回 = EnterReturnsTrue (1<<5) ? Enter 已接受旗 : buf 已写回旗。调用方 3 宿主: sub_1421EA9E0 (InputText 薄包装) / sub_1421EA280 ×2 (InputScalar/InputInt 形) / sub_1421F2390 (tweakergui 调试控制台输入框)。身份锚 = ImGuiInputTextCallbackData 12 字段 + stb undo 常量 99/999 + CursorAnim −0.30f + KeyMap 22 键 (含 KeyPadEnter@15 = 1.72 特征)。

**ImGuiContext 消费面 (定名锚)**: g.Font = ctx+6432 / g.FontSize = ctx+6440 / g.CurrentWindow = ctx+6768 (书原「确名未决」收口) / g.ActiveId = ctx+6840 / **g.KeyMods = ctx+968** (ImGuiKeyModFlags 1/2/4/8) / 剪贴板 fnptr 对 = ctx+256/264 (+272 userdata) / KeyMap 22 键表 = ctx+60 (4B×enum) / **输入字符队列 (UTF-16) = ctx+5464 count / +5472 data** / Style.Colors = ctx+5660 (16B/项, alpha × Style.Alpha@+5480) / **InputTextState = ctx+8184** (≥3722B: +0 ID / +4 CurLenW / +8 CurLenA / +16..+56 TextW/TextA/InitialTextA 三 ImVector / +68 BufSize 缓存 / +72 ScrollX / +76..+88 stb cursor/select_start/select_end/insert_mode / +100 行列表 / +3682..+3692 stb undo 四指针 (undo/redo_point, undo/redo_char_point) / +3696 CursorAnim (−0.30f 复位) / +3704..+3720 flags/callback/user_data 每帧暂存)。io 侧: DeltaTime@+24 / KeyRepeatDelay@+148 / KeyRepeatRate@+152 / ConfigInputTextCursorBlink@+194 / MouseWheel@+312 / **KeyCtrl..Super@+328..331 (本函经验读 — ⚠ 与 §4.00.22 泵喂 +320..323 错位 8 字节, 待收口)**。

flags 位表 (ImGuiInputTextFlags 1.72 命名, 18 位全实锚): 1<<4 AutoSelectAll / 1<<5 EnterReturnsTrue / 1<<6 CallbackCompletion / 1<<7 CallbackHistory / 1<<8 CallbackAlways / 1<<9 CallbackCharFilter / 1<<10 AllowTabInput / 1<<11 CtrlEnterForNewLine / 1<<12 NoHorizontalScroll / 1<<13 AlwaysOverwrite / 1<<14 ReadOnly / 1<<15 Password (字形 42 '*') / 1<<16 NoUndoRedo / 1<<17 CharsScientific / 1<<18 CallbackResize / 1<<20 Multiline / **1<<21 = PDX 扩展旗** (抑制变更标记 sub_1421D4990, vanilla 无)。

编辑键派发 (sub_1421F4480 = stb_textedit 执行器 1155 行; 键码族 0x200000 + K_SHIFT 0x400000): 方向/词移/行首尾 (wordmove 键 Win=Ctrl / OSX=Alt; shortcut 键 = ConfigMacOSXBehaviors@ctx+201 切换 Ctrl/Super) / Delete/Backspace (删词/删行首变体) / undo (Z)/redo (Y) / 全选 (A) / 复制 (C/Ctrl+Ins) / 剪切 (X/Shift+Del) / 粘贴 (V/Shift+Ins, 经 sub_1421ED220 过滤器 = CharsDecimal/Hex/Sci/Upper/NoBlank 位掩码 + PUA 0xE000-0xF8FF 拒绝)。回调事件 (栈上 0x38B = ImGuiInputTextCallbackData): {EventFlag@0 (64/128/256/512/0x40000), Flags@4, UserData@8, EventChar@12, EventKey@14 (0=Tab/3=Up/4=Down), Buf@16, BufTextLen@24, BufSize@28, BufDirty@32, CursorPos@36, SelectionStart/End@40/44}。⚠ IDA 失真: a7 伪签名 void(int*) (真 = void(ImGuiInputTextCallbackData\*)); sub_1421DD050 丢浮点参; 绘制长度硬上界 len < 0x200000。配套定名: sub_1421D3130 = ImTextStrFromUtf8 / sub_1421D33E0 = ImTextStrToUtf8 / sub_1421D2C90 = ImStrncpy / sub_1421D3B30 = IsKeyPressed / sub_1421CF500 = ClearActiveID / sub_1421D1990+DCA00 = Get/SetClipboardText / sub_1421D1B50 = GetColorU32 / sub_1421F8B10 = ImFont 字形查找 (ImFont PDX 布局: glyph 跨距 40B, IndexLookup 0xFFFF = 缺字)。

#### 4.26.26 MIO 政策库按名表后处理 pass 与条目类布局 (gameitemdatabase.h 族 + pdx_core; 1 函 = 0x14016E580, 287 行 — 新收)

sub_14016E580 = **CPolicyDatabase (mio_policy 库, 单例 qword_14332EF40) 按名 RH 表后处理 pass**。唯一调用方 = 装载槽方法 sub_14016A9E0 (虚表驱动, 无直调; 0x14016A660..0x14016AAC0 八同构兄弟 = 各 TRS 库同槽实例化, 槽位归属待裁); 前置 = 解析 pass sub_140168A60 (逐名 find-or-insert + 名 token id 去重入 CPdxArray\<LexerToken,128\> + vtable[3] Load + 入 +96 条目数组)。本函机制 = 以 a2 (块解析器, +40 惰性 token 读出器) 当前 token 名串**全表线性查表** (无哈希 — 与插入/查表侧 token id 哈希定位并存的第二条查表路径; 长度预比 + memcmp, 空串短路); 命中条目的名 token id 若**不在本趟 a3 收集集中** → 栈建默认 CPolicyTemplate 逐字段拷入, **原位重置为默认构造态** (+8 id 保留)。两断言经 sub_1424C8080 a4=1 形: pdx_scopedptr.h:134 值指针空值守卫 (闩 byte_14332F20A) / pdx_robin_hood_table.h:58 迭代哨兵解引用检查 (闩 byte_14332F1FF)。返回值 = 末次赋值残值 (memcmp 结果 / 串析构返回 / 断言返回), 无业务语义, 推定真签名 void。触发场景推定 = 同名重定义或装载回滚 (a3 只记本趟解析过的 id, 时序未实证 — 待裁)。

CPolicyDatabase 160B 全布局 (ctor 0x14014A140 四重 vtable 链 TGameItemDatabase → TReloadableGameItemDatabase → TReloadableGameItemDatabaseSpecific\<CPolicyDatabase,CPolicyTemplate\> → CPolicyDatabase; creator sub_140172D20 malloc 0xA0):

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +8 | CPdxArray 头 24B | _Paths 路径向量 {data@+8, cap@+16, count@+20, alloc@+24} | 高置信 (§4.26.4 统一式) |
| +32 | u32 | 装载重入计数器 (ctor 置 0) | 高置信 (§4.26.4) |
| +40 | CPdxArray 头 24B | watcher 句柄向量 (TRS 族 +40 漂移语义) | 高置信 (§4.26.4) |
| +64 | CPdxRobinHoodTable 32B 内嵌 | 按名 RH 表头 (+0 首槽未用, §3.2 32B 内嵌形) | 定案 |
| +72 | 56B 桶数组指针 | RH data; 空表 = 静态哨兵页 unk_143085C90 (§3.2 家族 56B 档) | 定案 |
| +80 | u32 | RH count (ctor 置 0) | 定案 |
| +84 | u32 | RH mask (hash & mask 定位) | 定案 |
| +88 | u8 | RH extra | 定案 |
| +92 | f32 | RH max_load_factor = 0.9 (ctor 常数 1063675494) | 定案 |
| +96 | CPolicyTemplate*[] | 条目数组 _AliveEntries {data@+96, cap@+104, count@+108, alloc@+112}; 增长 max(n+1, cap×1.5), 8B 步距, alloc = 全局纯堆单例 off_143085170 | 定案 |
| +128 | 不明对象指针 | ctor 直写 &off_142718900 | 待裁 |
| +144 | 不明对象指针 | malloc 0x28 对象 (sub_1401469E0) | 待裁 |

> 与 §4.26.4 TRS 族统一式逐项咬合: 条目数组 @+96/count@+108、按名表 @+64、宽名桶 56B 三式全对。

> +128 / +144 两指针语义未定案 (@128 起 32B boost::signals2 信号段即 +128 对象所属)。

按名 RH 桶 56B 形 (本库实例; §3.2 56B 档键形):

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +0 | u32 | 缓存哈希 (名 token id 经 0x045D9F3B 双轮雪崩; 插入/迁移写, 本 pass 不读) | 高置信 |
| +4 | u8 | _DistancePlus1 (0 = 空槽, 0xFF = 迭代哨兵) | 定案 |
| +8 | u32 | 键 = 名 token id (与模板 +8 同值) | 定案 |
| +16 | CPolicyTemplate* | 值指针 (scoped_ptr 语义; 空触 pdx_scopedptr.h:134 断言) | 定案 |
| +24 | std::string 32B | 名串 (buf@+24, size@+40, cap@+48; cap>15 时 data 指向 +24 槽内) | 定案 |

> 桶 = §3.2 通用 24B 形 {hash/dist/键/值} 的 56B 扩展: 首 24B 与「按名 RH 索引桶 24B {步数@+4, 键@+8, 值@+16}」逐项吻合, +24..+56 尾挂 32B 名串。

NIndustrialOrganisation::CPolicyTemplate 808B 全布局 (ctor 0x14014A2F0, 形参 2 = 名 token id; 勘误: 原书 §4.31.10 标条目类为 CPolicy 系误 — TReloadableGameItemDatabaseSpecific 第二模板参 + vtable 符号双直证, CPolicy 为另一运行时类非本库条目):

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +0 | vtable | NIndustrialOrganisation::CPolicyTemplate::vftable | 定案 |
| +8 | u32 | 名 token id (ctor 形参 a2; = 桶键) | 定案 |
| +16 | std::string 32B | 名串 (buf@+16, size@+32, cap@+40; ctor cap=15) | 定案 |
| +48 | std::string 32B | 第二串 (buf@+48, size@+64, cap@+72; ctor cap=15; 语义待裁) | 定案 |
| +80 | 循环链表头节点指针 | malloc 0x68; 节点 {self,self,self}, word@节点+24 = 0x0101 | 定案 |
| +88 | qword | 链表尾 (ctor 0) | 定案 |
| +96 | CModifier 192B 内嵌 | 修正块 (§4.3.8: 基 ctor sub_1424BE3C0 置 +8=357, body ctor sub_140555FB0 于 +16; 拷贝 sub_140556F80) | 定案 |
| +288 | qword | 自有字段 (原位重置时整写; 语义待裁) | 定案 (语义待裁) |
| +296 | u32 | 自有字段 (ctor 清 0; 语义待裁) | 定案 (语义待裁) |
| +304 | CAndTrigger 88B | 触发器槽 1 (ctor sub_140549F40 / 拷贝 sub_14054A800 / 析构 sub_1401511B0+sub_1401558F0) | 定案 |
| +392 | CAndTrigger 88B | 触发器槽 2 | 定案 |
| +480 | CAndTrigger 88B | 触发器槽 3 | 定案 |
| +568 | CEffect 块 88B | 效果槽 1 (ctor sub_14053CFD0 / 拷贝 sub_14053D3B0 / 析构 sub_14053D190) | 定案 |
| +656 | CEffect 块 88B | 效果槽 2 | 定案 |
| +744 | 公式块 56B | CMeanTimeToHappen/ai_will_do 同族 (ctor sub_1405516A0(…, 512), §4.27.2; 第二参 = 作用域位掩码, 他例 0/4, 512 值域待裁) | 定案 |
| +800 | u32 | DEFAULT_INITIAL_POLICY_ATTACH_COST (define dword_143334860 直填) | 定案 |
| +804 | u32 | DEFAULT_INITIAL_ATTACH_POLICY_COOLDOWN (define dword_143334918 直填; §4.8 tooltip 基准枚 623) | 定案 |

公式块 56B 内部 (本批仅取原位重置写入路径字段, 其余待裁):

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| 元素+8 | u32 | 公式块字段 (原位重置时整写) | 待裁 |
| 元素+16 | u32 | 公式块字段 | 待裁 |
| 元素+24 | qword | 公式块字段 | 待裁 |
| 元素+32 | 24B 子件 | 拷贝 sub_1401575C0 | 待裁 |

> 3×CAndTrigger (+304/+392/+480) / 2×CEffect (+568/+656) / 公式块 (+744) 各对应哪个 MIO 政策脚本键 (allowed / visible / complete_effect / ai_will_do …) 未定案 (待裁)。

> +96 的 CModifier 是内嵌成员还是多继承基类未定案 (ctor 构造序倾向成员; 两形布局同)。

#### 4.26.27 静态资源访问层函数补遗（33 函）

| VA | 语义/证据 |
|---|---|
| 0x140AE73D0 | （未命名）NAME / DETAILS / ABILITY_DESC + gameitemdatabase.h:142 断言 NAME / DETAILS / ABILITY_DESC + gameitemdatabase.h:142 断言，能力描述查询 |
| 0x141ECF280 | （未命名）仅 gameitemdatabase.h:142 单例断言 仅 gameitemdatabase.h:142 单例断言；TGameItemDatabase 查询型函数 |
| 0x141EABE10 | （未命名）仅 gameitemdatabase.h:142 单例断言 仅 gameitemdatabase.h:142 单例断言，TGameItemDatabase 查询型 |
| 0x140AC5CB0 | （未命名）subunit_definition_database.cpp:58 subunit_definition_database.cpp:58；"Invalid sub unit/category in modifier:"，子单位定义数据库校验 |
| 0x1401A10B0 | sub_1401A10B0 gameitemdatabase.h:281 "!_Paths.IsEmpty() && \"Cant reload when not loaded\""（数据库重载门 + "=====" 分隔日志） |
| 0x140F15390 | sub_140F15390 gameitemdatabasehelper.h "Array should be at least 1 element ... Null Object as Array[0]?" + SIMD（数据库数组空对象保护） |
| 0x1409C8510 | sub_1409C8510 "Error reading division names tracker - unknown division names group tag:"（静态库装载：师名 tracker） |
| 0x141BB8560 | sub_141BB8560 TGameItemDatabase 条目查找（gameitemdatabase.h:142+robin hood 迭代断言） |
| 0x140A6E150 | sub_140A6E150 脚本块解析（「Expected opening brace」，pdx_parser.h:2222 站点） |
| 0x1409750D0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_MIN_ST…::[0] NDefines::CDefineRegistryHelper_NOperatives... + "is not a lua table" / "clamping to ma… |
| 0x141441560 | sub_141441560 脚本块解析（「Expected opening brace」，pdx_parser.h:2222 站点） |
| 0x140073980 | （未命名）modifier 注册文档串 "_cost_factor"/"Idea grou modifier 注册文档串 "_cost_factor"/"Idea group cost factor." |
| 0x1406470E0 | （未命名）gameitemdatabasehelper.h:22 断言 "forget t gameitemdatabasehelper.h:22 断言 "forget to add the Null Object as Array[0]?"（库 Null Object 约定） |
| 0x1409C9080 | sub_1409C9080 体内构造/操作 vtable 类 CNameGroupMember（&CNameGroupMember::vftable）→ 名称组/单位名/AI 态度数据库 |
| 0x141FA6050 | （无名） vftable 类 NCareerProfile::SCareerProfileMedalData::（静态资源/库装载） |
| 0x141E95AC0 | （未命名）串 "gfx/loadingscreens"/".dds" 串 "gfx/loadingscreens"/".dds"（载入图资源枚举） |
| 0x140192FC0 | （无名） GameItemDatabase 单例（断言站点 gameitemdatabase.h:226） |
| 0x140187600 | TReloadableGameItemDatabase::InitFromDirectory? TReloadableGameItemDatabase::InitFromDirectory? 克隆体，gameitemdatabase.h:179 + "DB already loaded when loading" |
| 0x140AAFF40 | CScriptedMapMode::Reader CScriptedMapMode::Reader，串 "invalid map text type" |
| 0x140A8DC00 | （未命名）null_object.h:133 断言 "_pInstance" null_object.h:133 断言 "_pInstance"（Null Object 门控包装） |
| 0x1400745F0 | （无名） 脚本资源/修正器注册（自文档串 "_mission_factor"） |
| 0x14007AC00 | （无名） 脚本资源/修正器注册（自文档串 "state_production_speed_"） |
| 0x14007B9D0 | （未命名）modifier 注册文档串 "_max_level_terrain_limit modifier 注册文档串 "_max_level_terrain_limit"/"Maximum allowed building level for terrain." |
| 0x14006E730 | （未命名）modifier 注册文档串 "state_resources_"/"State modifier 注册文档串 "state_resources_"/"State resource factor." |
| 0x14007B000 | （未命名）modifier 注册文档串 "repair_speed_"/"Country modifier 注册文档串 "repair_speed_"/"Country building repair speed factor." |
| 0x14006C900 | （无名） 脚本资源/修正器注册（自文档串 "_xp_gain_factor"） |
| 0x1401711C0 | （无名） GameItemDatabase 单例（断言站点 gameitemdatabase.h:127） |
| 0x14062A300 | sub_14062A300 数据库空对象数组断言（gameitemdatabasehelper.h "Array should be at least 1 element"） |
| 0x141FA5650 | （无名） vftable 类 NCareerProfile::SCareerProfileMedalData::（静态资源/库装载） |
| 0x1409CA620 | （无名） vftable 类 NDLC::CMetadata::（静态资源/库装载） |
| 0x14068F9B0 | （无名） vftable 类 NCareerProfile::SProfileData::（静态资源/库装载） |
| 0x14206F620 | sub_14206F620 构造 "script\…\.lua" 路径并读取脚本文件（扩展名 .lua） |
| 0x14088B490 | 467431（合计） NDefines::CDefineRegistryHelper 读取器族（205 个模板实例，逐 define 从 Lua 表读值；错误路径含 std::ios_base vftable） sub_14088B490 体含串 "NIntel"+"CIVILIAN_SUPPLY_INTEL_R… |

> **define 注册 functor 族的登记口径（d 批次定案）**：`NDefines::CDefineRegistryHelper_<NS><KEY>::[0]`
> 是**静态资源装载机制**，不是业务域方法——尽管其内层命名空间（NAI/Navy/NMilitary…）
> 与业务域同名。一律收 §4.26 单节，**不按内层命名空间散到各业务节**；
> 同模板实例按族级单行登记（VA 区间 + 分域计数表），逐 VA 留在
> `findings/cov_full/_book_inbook.tsv`。判据：装载器 functor 从
> `NDefines` 全局表逐 define 读值，体签名由 define 类型（DWORD/QWORD/float/bool/颜色）
> 决定，与域逻辑无关。

#### 4.26.28 静态资源访问层函数补遗（29 函）

| VA | 语义/证据 |
|---|---|
| 0x142262F00 | （无名，按上游/loc 定性） loc "material\ shader" |
| 0x14148B760 | （无名）gameitemdatabase.h:142 + Invalid module name for module slot specification. gameitemdatabase.h:142 + Invalid module name for module slot specification. |
| 0x140B4C3A0 | （无名，按上游/loc 定性） loc "GFX_*" |
| 0x14019EBC0 | （无名，按上游/loc 定性） 断言 "!_Paths.IsEmpty() && Cant reload when not loaded" |
| 0x141B9C180 | （无名）gameitemdatabase.h:149 + infantry_equipment（默认装备查询） gameitemdatabase.h:149 + infantry_equipment（默认装备查询） |
| 0x141B86650 | （无名，按上游/loc 定性） gameitemdatabase.h:149 断言 + byte_14332F1C6/qword_14332F080 单例初始化 |
| 0x140170D40 | sub_140170D40 模块标签 gameitemdatabase.h:127 |
| 0x1401728B0 | sub_1401728B0 模块标签 gameitemdatabase.h:127 |
| 0x140637890 | sub_140637890 模块标签 gameitemdatabasehelper.h:137 |
| 0x140AC79B0 | sub_140AC79B0 模块标签 gameitemdatabasehelper.h:137 |
| 0x140172300 | sub_140172300 模块标签 gameitemdatabase.h:127 |
| 0x14178EC30 | 无名大函数 0x14178EC30 令牌 MODIFIER_NONE（修正系统表） |
| 0x140628DC0 | 域关键词匹配 sub_140628DC0 + 域关键词匹配; 源码路径 hoi4; 断言站点 gameitemdatabase.h:149 |
| 0x1409BFB00 | vtable/RTTI 类 CNameGroupDatabase sub_1409BFB00 + vtable/RTTI 类 CNameGroupDatabase |
| 0x140D73B00 | sub_140D73B00 模块标签 gameitemdatabase.h:149 |
| 0x14014F7A0 | vtable/RTTI 类 NDatabaseConfig::SDefaultLexerTokenConfig<NScript::CNamedCollectio sub_14014F7A0 + vtable/RTTI 类 NDatabaseConfig::SDefaultLexerTokenConfig<NScr… |
| 0x14067F310 | 域关键词匹配 sub_14067F310 + 域关键词匹配; 源码路径 hoi4; 断言站点 gameitemdatabasehelper.h:35 |
| 0x140AC28B0 | 域关键词匹配 sub_140AC28B0 + 域关键词匹配; 源码路径 hoi4; 断言站点 gameitemdatabasehelper.h:35 |
| 0x14014F120 | vtable/RTTI 类 NDatabaseConfig::SDefaultLexerTokenConfig<NFactions::CFactionRule> sub_14014F120 + vtable/RTTI 类 NDatabaseConfig::SDefaultLexerTokenConfig<NFac… |
| 0x1402ADB20 | CTestDatabase::[1] CTestDatabase::[1] + 名字角色规则(CTestDatabase::[1]); vtable/RTTI 含 CGregorianDate; 被 CTestDatabase::[1] 等 1 命名函数调用 |
| 0x140A690D0 | vtable/RTTI 类 CNameDatabase sub_140A690D0 + vtable/RTTI 类 CNameDatabase |
| 0x140A47BD0 | CIdeologyGroupDatabase::[5] CIdeologyGroupDatabase::[5] + 名字角色规则(CIdeologyGroupDatabase::[5]); 串 "_pInstance && \"; 源码路径 hoi4 |
| 0x14065A1F0 | 域关键词匹配 sub_14065A1F0 + 域关键词匹配; 源码路径 hoi4; 断言站点 gameitemdatabasehelper.h:120 |
| 0x140F13E60 | vtable/RTTI 类 CModifier sub_140F13E60 + vtable/RTTI 类 CModifier |
| 0x140637E70 | CAIRoleDatabase::[1] CAIRoleDatabase::[1] + 名字角色规则(CAIRoleDatabase::[1]); vtable/RTTI 含 CAIRoleDatabase; 被 CAIRoleDatabase::[1] 等 1 命名函数调用 |
| 0x140AE1B70 | CUnitMedalDatabase::[1] CUnitMedalDatabase::[1] + 名字角色规则(CUnitMedalDatabase::[1]); vtable/RTTI 含 TGameItemDatabase<CUnitMedalDatabase>; 被 CUnitMedalDatabase:… |
| 0x140646250 | CAIStrategyPlanDatabase::[1] CAIStrategyPlanDatabase::[1] + 名字角色规则(CAIStrategyPlanDatabase::[1]); vtable/RTTI 含 CAIStrategyPlanDatabase; 被 CAIStrategyPlanDat… |
| 0x1409BFF60 | vtable/RTTI 类 CNameGroupTracker sub_1409BFF60 + vtable/RTTI 类 CNameGroupTracker |
| 0x140160220 | CPeaceConferenceDatabase::[1] CPeaceConferenceDatabase::[1] + 名字角色规则(CPeaceConferenceDatabase::[1]); vtable/RTTI 含 TGameItemDatabase<CPeaceConferenceDatabase… |

#### 4.26.29 静态资源访问层函数补遗（44 函）

| VA | 语义/证据 |
|---|---|
| 0x14178D300 | 数据库空对象数组守卫 数据库空对象数组守卫；断言 \"Array should be at least 1 element, did you forget to add the Null Object as Array[0]?\"（gameitemdatabasehelper.h），被调 gameitemdata… |
| 0x1413C4410 | 州分类数据库装载 州分类数据库装载；断言 \"Array should be 1 element bigger than Lookup, did you forget to add the Null Object as Array[0]?\"（state_categories.cpp）+串 \"State cat… |
| 0x140A47170 | 意识形态数据库装载 意识形态数据库装载；串 \"Duplicate database id \"，被调 lexer.cpp:241/381+parser.cpp:1087，邻 CIdeologyDatabase::[1](-2496B)/CIdeologyGroupDatabase::[1]/CIdeologyD… |
| 0x142383860 | 资源/格式装载 资源/格式装载；串 \".asset\" 扩展，邻 CFormat::[0](-1296B)/[2]/CPdxTouchDevice |
| 0x140AB5E70 | 脚本模板数据库装载 脚本模板数据库装载；被调 gameitemdatabasehelper.h:35/149/163+parser.cpp:1087+CDiplomaticAction::GetFirstCountryRef，邻 CScriptedTriggerTemplate::[0](-304B)/CScri… |
| 0x141460BE0 | 装备模块定义校验 装备模块定义校验；串 \"Assigning module '\"+\"' which is not present on type '\"，被调 lexer.cpp:381 |
| 0x14029AAC0 | 数据库热重载（同族） 数据库热重载（同族）；同上断言+串，被调 gameitemdatabase.h:281 |
| 0x14019F280 | 数据库热重载 数据库热重载；断言 \"!_Paths.IsEmpty() && \\\"Cant reload when not loaded\\\"\"+串 \"Reloading Database:\"（gameitemdatabase.h:281），被调 occupationlawdatabase.cpp:186 |
| 0x140AED730 | 单位领袖类别令牌解析 单位领袖类别令牌解析；串 \"Invalid token for Unit leader Category\"/\"Empty list for Unit leader Category\"/\"Invalid List token for Unit leader Category\"，被调… |
| 0x14140D1F0 | CScientistTemplate::[7] / "Invalid scientist trait/does not exist "Invalid scientist trait/does not exist in scientist trait D §4.26 静态资源/库装载 |
| 0x1401315F0 | gameitemdatabase.h:882 + CDiplomaticActi gameitemdatabase.h:882 + CDiplomaticAction::GetFirstCountryR §4.26 静态资源/库装载 |
| 0x14012D940 | gameitemdatabase.h:882 + CDiplomaticActi gameitemdatabase.h:882 + CDiplomaticAction::GetFirstCountryR §4.26 静态资源/库装载 |
| 0x1409B8540 | CDifficultySetting vtable + gameitemdata CDifficultySetting vtable + gameitemdatabasehelper 查询 §4.26 静态资源/库装载 |
| 0x140A83EA0 | gameitemdatabasehelper.h:149 + GetFirstC gameitemdatabasehelper.h:149 + GetFirstCountryRef：库查询 §4.26 静态资源/库装载 |
| 0x14083F6E0 | NDefines::CDefineRegistryHelper_NGameGAME_SPEED_SECONDS::[0] / define 注册表读取：NGame/GAME_SPEED_SECONDS + define 注册表读取：NGame/GAME_SPEED_SECONDS + "is not a lua … |
| 0x140615EF0 | "Error reading the acclimatization file "Error reading the acclimatization file - there is no such s §4.26 静态资源/库装载 |
| 0x140198610 | sub_140198610（无名） gameitemdatabase.h:281 站点 "!_Paths.IsEmpty() && Cant reload when not loaded" + "=====" 分隔日志，夹于 CDatabaseReloader<CTrainGfxDatabase>::[2] 与 … |
| 0x1401A0D80 | sub_1401A0D80（无名） gameitemdatabase.h:281 站点同上（CDatabaseReloader 另一实例化，d=45120） |
| 0x1407CAA50 | NDefines::CDefineRegistryHelper_NAITheatreAI_THEATRE_DISTRIBUTI…::[0] / define 注册表：NAITheatre/AI_THEATRE_DISTRIB define 注册表：NAITheatre/AI_THEATRE_DISTRIBUTIO… |
| 0x1408FFC10 | NDefines::CDefineRegistryHelper_NMilitaryARMY_HQ_REQUISITION_MI…::[0] / define 注册表：NMilitary/ARMY_HQ_REQUISITION define 注册表：NMilitary/ARMY_HQ_REQUISITION_MIN… |
| 0x14098D830 | NDefines::CDefineRegistryHelper_NProjectMINIMUM_PROJECT_SPEED_F…::[0] / define 注册表：NProject/MINIMUM_PROJECT_SPEE define 注册表：NProject/MINIMUM_PROJECT_SPEED_FA… |
| 0x140825200 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_SCORE_TRANSFERR…::[0] / define 注册表：NDiplomacy/PEACE_SCORE_TRANSF define 注册表：NDiplomacy/PEACE_SCORE_TRANSFERRE… |
| 0x140939BC0 | NDefines::CDefineRegistryHelper_NNavyCHANCE_TO_DAMAGE_PART_ON_C…::[0] / define 注册表：NNavy/CHANCE_TO_DAMAGE_PART_O define 注册表：NNavy/CHANCE_TO_DAMAGE_PART_ON_CR… |
| 0x1409479D0 | NDefines::CDefineRegistryHelper_NNavyINTEL_LEVEL_MEDIUM_HALF_RA…::[0] / define 注册表：NNavy/INTEL_LEVEL_MEDIUM_HALF define 注册表：NNavy/INTEL_LEVEL_MEDIUM_HALF_RAN… |
| 0x1408A13A0 | NDefines::CDefineRegistryHelper_NInterfaceCONVOY_ESCORT_PRESENC…::[0] / define 注册表：NInterface/CONVOY_ESCORT_PRES define 注册表：NInterface/CONVOY_ESCORT_PRESENCE… |
| 0x140758EF0 | NDefines::CDefineRegistryHelper_NAIAI_FRACTION_OF_FIGHTERS_RESE…::[0] / define 注册表：NAI/AI_FRACTION_OF_FIGHTERS_R define 注册表：NAI/AI_FRACTION_OF_FIGHTERS_RESER… |
| 0x1408F4500 | NDefines::CDefineRegistryHelper_NMapModeOCCUPATION_MAP_MODE_COU…::[0] / define 注册表读取：NMapMode/OCCUPATION_MAP_MOD define 注册表读取：NMapMode/OCCUPATION_MAP_MODE_CO… |
| 0x140984B90 | NDefines::CDefineRegistryHelper_NProductionENERGY_SCALE_PER_TRA…::[0] / define 注册表：NProduction/ENERGY_SCALE_PER_ define 注册表：NProduction/ENERGY_SCALE_PER_TRAD… |
| 0x1408050C0 | NDefines::CDefineRegistryHelper_NCountryMAX_INTELLIGENCE_MANPOW…::[0] / define 注册表：NCountry/MAX_INTELLIGENCE_MAN define 注册表：NCountry/MAX_INTELLIGENCE_MANPOWE… |
| 0x1407FC410 | NDefines::CDefineRegistryHelper_NCountryGIE_CAPITULATE_MIN_LEGI…::[0] / define 注册表：NCountry/GIE_CAPITULATE_MIN_L define 注册表：NCountry/GIE_CAPITULATE_MIN_LEGIT… |
| 0x1409648F0 | NDefines::CDefineRegistryHelper_NNavySUBMARINE_BASE_TORPEDO_REV…::[0] / define 注册表：NNavy/SUBMARINE_BASE_TORPEDO_ define 注册表：NNavy/SUBMARINE_BASE_TORPEDO_REVE… |
| 0x140785AE0 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_WANTED_CONV…::[0] / define 注册表：NAI/EQUIPMENT_MARKET_WANTED_C define 注册表：NAI/EQUIPMENT_MARKET_WANTED_CONVO… |
| 0x1409AB580 | NDefines::CDefineRegistryHelper_NSupplyMIN_TRAIN_SUPPLY_FACTOR::[0] / define 注册表：NSupply/MIN_TRAIN_SUPPLY_FACT define 注册表：NSupply/MIN_TRAIN_SUPPLY_FACTOR §4.… |
| 0x14094CBE0 | NDefines::CDefineRegistryHelper_NNavyMIN_ORG_ON_MANUAL_MOVE::[0] / define 注册表：NNavy/MIN_ORG_ON_MANUAL_MOVE define 注册表：NNavy/MIN_ORG_ON_MANUAL_MOVE §4.26 静态资源… |
| 0x1407B49F0 | NDefines::CDefineRegistryHelper_NAIPEACE_TIME_NAVY_FUEL_FACTOR::[0] / define 注册表：NAI/PEACE_TIME_NAVY_FUEL_FACT define 注册表：NAI/PEACE_TIME_NAVY_FUEL_FACTOR §4.… |
| 0x140176230 | "array of objects in ... database" 库装载校验 "array of objects in ... database" 库装载校验 §4.26 静态资源/库装载 |
| 0x1412A0990 | 未命名业务函数 define/本地化键（串 CHARACTER_ADVISOR_CANT_BE_FIRED） |
| 0x140D450E0 | 未命名业务函数 define/本地化键（串 DONATIONS_FROM_EXILE） |
| 0x141A17790 | 未命名业务函数 define/本地化键（串 AGENCY_UPGRADES_DURATION） |
| 0x142156AF0 | 未命名业务函数 define/本地化键（串 EGL_SUCCESS） |
| 0x141C92120 | CDiplomacyRequestLicensedProductionController（vtable 槽 [0]） define/本地化键（串 DIPLOMACY_SEND） |
| 0x1420EB0C0 | 未命名业务函数 define/本地化键（串 SDL_DISPLAY_USABLE_BOUNDS） |
| 0x14211D0A0 | 未命名业务函数 define/本地化键（串 DISP_CHANGE_BADPARAM） |
| 0x142271300 | 未命名业务函数 define/本地化键（串 DURATION_HOURS） |

#### 4.26.30 静态资源访问层函数补遗（17 函）

| VA | 语义/证据 |
|---|---|
| 0x140AA96B0 | （无名，按证据定性） gameitemdatabase.h:142 断言 _pInstance（数据库条目读取） |
| 0x140613580 | （无名，按证据定性） gameitemdatabasehelper.h:149 断言（数据库条目 helper） |
| 0x14012D0E0 | （无名，按证据定性） gameitemdatabase.h:882 断言站点（数据库条目装载） |
| 0x14012FE10 | （无名，按证据定性） gameitemdatabase.h:882 断言站点（数据库条目装载） |
| 0x140CB9810 | （无名，按证据定性） gameitemdatabase.h:149 断言 + 串 'Unknown building when reading modify_building_resources'（建筑资源修正读取） |
| 0x14019C8D0 | （无名，按证据定性） gameitemdatabase.h:281 断言 !_Paths.IsEmpty()（数据库模板路径校验，同族 0x1401A3AC0/0x140198DB0） |
| 0x140198DB0 | （无名，按证据定性） gameitemdatabase.h:281 断言 !_Paths.IsEmpty()（数据库模板路径校验同族） |
| 0x14175AA70 | TGameItemDatabase 库访问 gameitemdatabase.h:142 + pdx_core 单例断言 |
| 0x140193370 | TReloadableGameItemDatabase::InitFromDirectory? TReloadableGameItemDatabase::InitFromDirectory，gameitemdatabase.h:226 |
| 0x140B91660 | 音乐播放器轨道索引校验 musicplayer.cpp:226 + "Invalid enum"，a1+108 索引 vs a1+336 计数 |
| 0x14015B810 | TGameItemDatabase gameitemdatabase.h:780 + 源路径串 |
| 0x1401EA7A0 | TGameItemDatabase 库访问 gameitemdatabase.h:142 + pdx_core 单例断言 ×3 |
| 0x1413D9200 | TGameItemDatabase gameitemdatabase.h:142 + "_tab" 表访问 + 单例断言 |
| 0x1416BC430 | TGameItemDatabase 库访问 gameitemdatabase.h:142 + "( Array.GetSize() > 0 )" 断言 |
| 0x1422D2930 | GUI FX 定义文件装载 "gfx/FX/text.lua" ×2 |
| 0x1401A45D0 | TGameItemDatabase 路径装载 gameitemdatabase.h:281 + "!_Paths.IsEmpty()" + 分隔线串 |
| 0x140175EB0 | 库解析错误输出 "array of objects in ... database"，数据库装载族 |
#### 4.26.32 静态资源访问层函数补遗（22 函）

| VA | 语义/证据 |
|---|---|
| 0x141C668B0 | （无名） 断言站点 gfx_railway.cpp:194 |
| 0x1415ECD70 | 游戏物品数据库成员方法 gameitemdatabase.h:142 断言 |
| 0x141461C00 | 游戏物品数据库成员方法 gameitemdatabase.h:142 断言 |
| 0x14079A8B0 | NDefines::CDefineRegistryHelper_NAIMAX_AIR_REGIONS_TO_CARE_ABOUT::[0] MAX_AIR_REGIONS_TO_CARE_ABOUT；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\defines_ai… |
| 0x140768B50 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_LOSING_WAR_THRESHO…::[0] CALL_ALLY_LOSING_WAR_THRESHOLD；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\defines_a… |
| 0x140989080 | NDefines::CDefineRegistryHelper_NProductionMIN_NAVAL_EQUIPMENT_…::[0] NProduction；MIN_NAVAL_EQUIPMENT_CONVERSION_RESOURCE_COST_FACTOR；C:\\mnt\\gsg\\hoi4\\hoi… |
| 0x1408FAC10 | NDefines::CDefineRegistryHelper_NMarketCONTRACT_ESTIMATE_AVERAG…::[0] NMarket；CONTRACT_ESTIMATE_AVERAGE_CONVOY_SUNK_MULTIPLIER_ALPHA；C:\\mnt\\gsg\\hoi4\\hoi4… |
| 0x140838D10 | NDefines::CDefineRegistryHelper_NFactionsPEACE_CONFERENCE_MINIM…::[0] NFactions；PEACE_CONFERENCE_MINIMAL_REQUIREMENT；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\s… |
| 0x140815630 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_LEADERSHIP_CH…::[0] NDiplomacy；FACTION_LEADERSHIP_CHANGE_ALERT_THRESHOLD；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\h… |
| 0x140946CD0 | NDefines::CDefineRegistryHelper_NNavyINTEL_LEVEL_LOW_HALF_RANGE…::[0] NNavy；INTEL_LEVEL_LOW_HALF_RANGE_MIN_CAPITALS；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\so… |
| 0x14096FBD0 | NDefines::CDefineRegistryHelper_NOperativesCOUNTER_INTELLIGENCE…::[0] NOperatives；COUNTER_INTELLIGENCE_STACKING_FACTOR；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\… |
| 0x140760F00 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_DONT_STEA…::[0] ARMY_LEADER_ASSIGN_DONT_STEAL_OTHER_FACTOR；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\sourc… |
| 0x140804170 | NDefines::CDefineRegistryHelper_NCountryMAX_INTELLIGENCE_CONVOY…::[0] NCountry；MAX_INTELLIGENCE_CONVOY_DATA_DEVIATION；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\… |
| 0x1407A3B90 | NDefines::CDefineRegistryHelper_NAIMIN_CONVOY_EFFICIENCY_TO_CAN…::[0] MIN_CONVOY_EFFICIENCY_TO_CANCEL_TRADES；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\d… |
| 0x140956A30 | NDefines::CDefineRegistryHelper_NNavyNAVAL_HEADQUARTER_ADJACENCY::[0] NNavy；NAVAL_HEADQUARTER_ADJACENCY；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\define… |
| 0x14098EAF0 | NDefines::CDefineRegistryHelper_NProjectPROJECT_LOSS_FACTOR_ON_…::[0] NProject；PROJECT_LOSS_FACTOR_ON_CAPTURE；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\… |
| 0x1407C15A0 | NDefines::CDefineRegistryHelper_NAIRESEARCH_WEIGHT_TRUNCATION_T…::[0] RESEARCH_WEIGHT_TRUNCATION_THRESHOLD；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\def… |
| 0x1409370F0 | NDefines::CDefineRegistryHelper_NNavyBASE_SPOTTING_FROM_DECRYPT…::[0] NNavy；BASE_SPOTTING_FROM_DECRYPTION；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\defi… |
| 0x14099C6C0 | NDefines::CDefineRegistryHelper_NResistanceINITIAL_STATE_RESIST…::[0] NResistance；INITIAL_STATE_RESISTANCE；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\def… |
| 0x140942AF0 | NDefines::CDefineRegistryHelper_NNavyDOMINANCE_DAILY_LOSS_FACTOR::[0] NNavy；DOMINANCE_DAILY_LOSS_FACTOR；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\define… |
| 0x140962030 | NDefines::CDefineRegistryHelper_NNavySHIP_SUPPORT_NEED_FACTOR::[0] NNavy；SHIP_SUPPORT_NEED_FACTOR；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\defines_mili… |
| 0x1407E75C0 | NDefines::CDefineRegistryHelper_NAirINTERCEPTION_DAMAGE_SCALE::[0] INTERCEPTION_DAMAGE_SCALE；C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\defines_military.… |

#### 4.26.33 静态资源访问层函数补遗（129 函）

| VA | 语义/证据 |
|---|---|
| 0x141AF1E10 | （无名） 调用图传播: 55 锚点投 §4.26（60%） |
| 0x141AE60A0 | （无名） 调用图传播: 30 锚点投 §4.26（60%） |
| 0x141AF6280 | （无名） 调用图传播: 34 锚点投 §4.26（94%） |
| 0x141B18100 | （无名） 调用图传播: 25 锚点投 §4.26（64%） |
| 0x140E72FE0 | （无名） 调用图传播: 9 锚点投 §4.26（56%） |
| 0x141B72000 | （无名） 调用图传播: 10 锚点投 §4.26（50%） |
| 0x1421F2C60 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421D72D0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421E7650 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x141C65120 | （无名） 调用图传播: 7 锚点投 §4.26（57%） |
| 0x140CCC1D0 | （无名） 调用图传播: 5 锚点投 §4.26（80%） |
| 0x140612F90 | （无名） 调用图传播: 9 锚点投 §4.26（56%） |
| 0x1421D6F70 | （无名） 调用图传播: 6 锚点投 §4.26（100%） |
| 0x141AF7970 | （无名） 调用图传播: 12 锚点投 §4.26（83%） |
| 0x1421BEE50 | （无名） 调用图传播: 6 锚点投 §4.26（100%） |
| 0x141BB43D0 | （无名） 调用图传播: 4 锚点投 §4.26（50%） |
| 0x141267670 | （无名） 调用图传播: 4 锚点投 §4.26（75%） |
| 0x1401A9780 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1412659D0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x141C2B890 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421E8230 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421E8480 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1401596D0 | （无名） 调用图传播: 13 锚点投 §4.26（92%） |
| 0x140174440 | （无名） 调用图传播: 10 锚点投 §4.26（90%） |
| 0x1421BE0F0 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x141BB4180 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140194930 | （无名） 调用图传播: 7 锚点投 §4.26（71%） |
| 0x1421C0D30 | （无名） 调用图传播: 14 锚点投 §4.26（100%） |
| 0x14071FAC0 | （无名） 调用图传播: 4 锚点投 §4.26（50%） |
| 0x140ADA320 | （无名） 调用图传播: 4 锚点投 §4.26（50%） |
| 0x1406AE190 | （无名） 调用图传播: 4 锚点投 §4.26（50%） |
| 0x1409B8AF0 | （无名） 调用图传播: 4 锚点投 §4.26（50%） |
| 0x140AB7080 | （无名） 调用图传播: 4 锚点投 §4.26（50%） |
| 0x140155320 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421C0F80 | （无名） 调用图传播: 14 锚点投 §4.26（100%） |
| 0x140AAC1A0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x14139E8A0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1415AA990 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140A8EA30 | （无名） 调用图传播: 8 锚点投 §4.26（62%） |
| 0x141243630 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421CE550 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C9930 | （无名） 调用图传播: 14 锚点投 §4.26（100%） |
| 0x14128C150 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140738F70 | （无名） 调用图传播: 11 锚点投 §4.26（100%） |
| 0x14128FC00 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140A8BE80 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140739090 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x1406BC700 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x14015A4F0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140C95760 | （无名） 调用图传播: 5 锚点投 §4.26（60%） |
| 0x1413F1A10 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x14206F480 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x1406BCB70 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B0950 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140A75E60 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x14060C5D0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1421AC5C0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x141B04BD0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x141664F90 | （无名） 调用图传播: 5 锚点投 §4.26（80%） |
| 0x1409B8980 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140BABC00 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140159450 | （无名） 调用图传播: 5 锚点投 §4.26（60%） |
| 0x1421B9080 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x140AA9B10 | （无名） 调用图传播: 5 锚点投 §4.26（80%） |
| 0x1421BAA50 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x1421BB530 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x14154A4A0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421AC280 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1410E10C0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1421AD300 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BB630 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1405541D0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x14128C430 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140154D10 | （无名） 调用图传播: 10 锚点投 §4.26（60%） |
| 0x1421BC010 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x14167E710 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140A8BDD0 | （无名） 调用图传播: 3 锚点投 §4.26（67%） |
| 0x1416623B0 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x1421BBD80 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421ACAF0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B9490 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140611ED0 | （无名） 调用图传播: 3 锚点投 §4.26（67%） |
| 0x140A9A940 | （无名） 调用图传播: 4 锚点投 §4.26（75%） |
| 0x1421AD0D0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421ACF70 | （无名） 调用图传播: 6 锚点投 §4.26（100%） |
| 0x141BB5A70 | （无名） 调用图传播: 3 锚点投 §4.26（67%） |
| 0x1421BA860 | （无名） 调用图传播: 8 锚点投 §4.26（100%） |
| 0x1421C9680 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x1407391E0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C0960 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x1421BE2D0 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x1421ADE90 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BA3D0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C0C90 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BAB20 | （无名） 调用图传播: 6 锚点投 §4.26（100%） |
| 0x141BB1930 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1421BB730 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C8C40 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x1421C08D0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421C0A30 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BB250 | （无名） 调用图传播: 6 锚点投 §4.26（100%） |
| 0x1421BA930 | （无名） 调用图传播: 5 锚点投 §4.26（100%） |
| 0x1421AB690 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C98B0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x14015A630 | （无名） 调用图传播: 4 锚点投 §4.26（75%） |
| 0x1421AD5C0 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x1421B92C0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421B97F0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C7A50 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421BCF60 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1422DE010 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1422DE040 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421ACB90 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421ADCD0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421C11D0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B98D0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421C1510 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B9970 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BAD50 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421B9C10 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421BA360 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421B9BB0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421ADDA0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B9750 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BD680 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B9790 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421BA460 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421BA5B0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421BA9D0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |

#### 4.26.34 静态资源访问层函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140672320 | CGameItemDatabase 表操作 pdx_robin_hood_table.h:58 + gameitemdatabase.h:142 双断言 → CGameItemDatabase 表操作 |
| 0x141CC8880 | 资源库查询 gameitemdatabase.h:142 + 串 "gfx/loadingscreens/"/"GFX_frontend_bg" → 资源库查询 |
| 0x142256880 | 控制台 reload 命令 串 "' reloaded!"/"Failed to reload '"/"No such reload target that takes arguments" → 控制台 reload 命令 |
| 0x140AA5ED0 | 类型化数组常量解析 串 "expects an array of "/"Unsupported array data type for constants" → 类型化数组常量解析 |
| 0x140DE5490 | 脚本解析错误信息 串 "Expected '=' after"/"Expected a number after '/'"/"Expected block" → 脚本解析错误信息 |

#### 4.26.35 静态资源访问层函数补遗（54 函）

| VA | 语义/证据 |
|---|---|
| 0x140A92E30 | sub_140A92E30 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x141932B40 | sub_141932B40 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x141992FF0 | sub_141992FF0 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x140EE22F0 | sub_140EE22F0 TGameItemDatabase 条目查找（断言「Instance not created.」） |
| 0x141915740 | sub_141915740 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x14118CA50 | sub_14118CA50 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x14101DA90 | sub_14101DA90 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x14068A050 | sub_14068A050 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x140DF1A50 | sub_140DF1A50 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x141025D30 | sub_141025D30 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x1413C95F0 | sub_1413C95F0 pdx_parser 读循环调用族（sub_14014B4E0/sub_1401516C0/sub_140158B40/sub_1424C04A0），脚本数据库 Reader::Parse |
| 0x140A8F620 | sub_140A8F620 数据库条目缺失（Entry doesn't exist in database:） |
| 0x14060D320 | sub_14060D320 动态修正脚本加载（.txt 文件读取+CDynamicModifierContainer 邻域） |
| 0x14206F210 | sub_14206F210 lua 表读取调用族+luabind 调用族，define 注册邻域 |
| 0x14011A4B0 | sub_14011A4B0 可绑定本地化文档/解析（Bindable localization） |
| 0x141B66A60 | 无名领域函数 sub_141B66A60 调用传播: 9 个窗口内 callee 多数属 §4.26（权重 1.00） |
| 0x1419DCC40 | sub_1419DCC40 游戏物品数据库单例访问（gameitemdatabase.h 断言） |
| 0x141EC0260 | 无名领域函数 sub_141EC0260 断言站点 \hoi4\\source\\gameitemdatabase.h（物品数据库） |
| 0x140D83920 | sub_140D83920 游戏物品数据库单例访问（gameitemdatabase.h 断言） |
| 0x140172590 | sub_140172590 游戏物品数据库单例访问（gameitemdatabase.h 断言） |
| 0x1402DCBE0 | 同区段近邻 CTestDatabase::[1](距 0x2F0C0)属 4.26 族 sub_1402DCBE0 + 同区段近邻 CTestDatabase::[1](距 0x2F0C0)属 4.26 族 |
| 0x141B61E30 | 无名领域函数 sub_141B61E30 断言站点 \hoi4\\source\\gameitemdatabase.h（物品数据库） |
| 0x141ED0010 | sub_141ED0010 游戏物品数据库单例访问（gameitemdatabase.h 断言） |
| 0x140AC76C0 | 无名领域函数 sub_140AC76C0 断言站点 \hoi4\\source\\gameitemdatabasehelper.h（物品数据库） |
| 0x140644470 | 无名领域函数 sub_140644470 断言站点 \hoi4\\source\\gameitemdatabasehelper.h（物品数据库） |
| 0x140AE2CF0 | 无名领域函数 sub_140AE2CF0 断言站点 \hoi4\\source\\gameitemdatabasehelper.h（物品数据库） |
| 0x1410EEA30 | 域关键词匹配 sub_1410EEA30 + 域关键词匹配; 源码路径 hoi4; 被调源码 hoi4 |
| 0x141DBFE50 | sub_141DBFE50 串:state_resource_entry |
| 0x141A3ACD0 | 无名领域函数 sub_141A3ACD0 断言站点 \hoi4\\source\\gameitemdatabase.h（物品数据库） |
| 0x141FDD9B0 | 域关键词匹配 sub_141FDD9B0 + 域关键词匹配; 源码路径 hoi4; 被调源码 clausewitz |
| 0x140ADF910 | sub_140ADF910 列车 gfx 数据库装载（train_gfx_database） |
| 0x141CF4A10 | sub_141CF4A10 游戏物品数据库单例访问（gameitemdatabase.h 断言） |
| 0x1406485A0 | sub_1406485A0 特征串:.txt |
| 0x140A6B1E0 | sub_140A6B1E0 特征串:.txt |
| 0x140E89FE0 | 无名领域函数 sub_140E89FE0 断言站点 \hoi4\\source\\gameitemdatabase.h（物品数据库） |
| 0x141B48830 | sub_141B48830 特征串:buildings_nudger_markers.txt |
| 0x140301EC0 | 同区段近邻 CTestDatabase::[1](距 0x543A0)属 4.26 族 sub_140301EC0 + 同区段近邻 CTestDatabase::[1](距 0x543A0)属 4.26 族 |
| 0x1402B2A40 | 同区段近邻 CTestDatabase::[1](距 0x4F20)属 4.26 族 sub_1402B2A40 + 同区段近邻 CTestDatabase::[1](距 0x4F20)属 4.26 族 |
| 0x141D68CB0 | 域关键词匹配 sub_141D68CB0 + 域关键词匹配; 源码路径 hoi4; 被调源码 hoi4 |
| 0x140ACA030 | 调用图上游传播(占 100%, 1 票) sub_140ACA030 + 调用图上游传播(占 100%, 1 票) |
| 0x140A82F70 | 域关键词匹配 sub_140A82F70 + 域关键词匹配; 被调源码 clausewitz |
| 0x1402F2FD0 | 调用图上游传播(占 67%, 7 票) sub_1402F2FD0 + 调用图上游传播(占 67%, 7 票) |
| 0x140AC99B0 | 调用图上游传播(占 100%, 1 票) sub_140AC99B0 + 调用图上游传播(占 100%, 1 票) |
| 0x1409F8880 | 域关键词匹配 sub_1409F8880 + 域关键词匹配; 源码路径 hoi4; 被 CEquipmentType::[4] 等 1 命名函数调用 |
| 0x1401576A0 | 调用图上游传播(占 100%, 1 票) sub_1401576A0 + 调用图上游传播(占 100%, 1 票) |
| 0x140143250 | 调用图上游传播(占 100%, 1 票) sub_140143250 + 调用图上游传播(占 100%, 1 票) |
| 0x140A45830 | 调用图上游传播(占 50%, 2 票) sub_140A45830 + 调用图上游传播(占 50%, 2 票) |
| 0x140A02D20 | 调用图上游传播(占 100%, 1 票) sub_140A02D20 + 调用图上游传播(占 100%, 1 票) |
| 0x1409C01A0 | 域关键词匹配 sub_1409C01A0 + 域关键词匹配 |
| 0x140A3FFC0 | 域关键词匹配 sub_140A3FFC0 + 域关键词匹配 |
| 0x1401F91C0 | 调用图上游传播(占 33%, 3 票) sub_1401F91C0 + 调用图上游传播(占 33%, 3 票) |
| 0x1409CA550 | 域关键词匹配 sub_1409CA550 + 域关键词匹配 |
| 0x140A25A60 | 调用图上游传播(占 38%, 3 票) sub_140A25A60 + 调用图上游传播(占 38%, 3 票) |
| 0x1402CAD70 | 调用图上游传播(占 100%, 1 票) sub_1402CAD70 + 调用图上游传播(占 100%, 1 票) |

#### 4.26.36 静态资源访问层函数补遗（12 函）

| VA | 语义/证据 |
|---|---|
| 0x140232A10 | 串 "localisation/ignored_loc_keys.txt" 串 "localisation/ignored_loc_keys.txt"，本地化加载 |
| 0x14027B1B0 | 断言 "Technology database reloaded." 断言 "Technology database reloaded."，科技数据库重载 |
| 0x140073BD0 | 串 "_category_type_cost_factor"/"IdeaCategory" 串 "_category_type_cost_factor"/"IdeaCategory"，idea 类别因子注册 |
| 0x140CFC490 | GUI：EXILE_COUNTRY_NORMAL_MANPOWER_DAILY_GROWTH loc 键 EXILE_COUNTRY_NORMAL_MANPOWER_DAILY_GROWTH/AMOUNT，define 注册 |
| 0x140A1D6C0 | 断言 "Named collection not found" 断言 "Named collection not found"，script_collection_input_impl.h |
| 0x140A98F30 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x141F493D0 | 无名 · gameitemdatabase.h "Instance not c gameitemdatabase.h "Instance not created." + idb 项查找 |
| 0x140A99990 | （无名） 调用图传播: 6 锚点投 §4.26（100%） |
| 0x140193A50 | 无名 · gameitemdatabase.h "DB already loa gameitemdatabase.h "DB already loaded when loading" |
| 0x140193880 | 无名 · gameitemdatabase.h "DB already loa gameitemdatabase.h "DB already loaded when loading" |
| 0x14167F210 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140ACDDD0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |

#### 4.26.37 静态资源访问层函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x14066F600 | 业务逻辑（见证据锚） 路径拼接 + '/'(47) 分隔 + sub_1424DC600(…, ".txt", 0, 0)（.txt 文件清单载入） |
| 0x140A94840 | 业务逻辑（见证据锚） "Special project is not allowed to have Oil as a resource cost"（idb 特殊项目资源成本校验） |
| 0x1409F0C30 | TGameItemDatabase 游戏物品库模板(析构清理链) (vtable类名 TGameItemDatabase<CEquipmentDatabase>) vtable引用 TGameItemDatabase<CEquipmentDatabase> vftable |
| 0x1409C0250 | CNameGroup 名称组静态库 (vtable类名 CNameGroup) vtable引用 CNameGroup vftable |
| 0x140A347F0 | CGameRule 游戏规则 (vtable类名 CGameRule) vtable引用 CGameRule vftable |

#### 4.26.38 静态资源访问层函数补遗（24 函）

| VA | 语义/证据 |
|---|---|
| 0x1421D7B70 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x140A32AD0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x141AF5970 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1421AD1C0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BD020 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x141661A10 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1416615E0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x14012A9A0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1401590F0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x141B17E40 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140B565E0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x141B73A80 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1421ADE10 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x14209CDF0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1417842E0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |
| 0x1421C0B30 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421C0AD0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BC7F0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421BB4D0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BC8C0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BC7A0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421B95F0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140A9AA10 | （无名） 调用图传播: 4 锚点投 §4.26（100%） |
| 0x1421BCFF0 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |

#### 4.26.39 静态资源访问层函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x141B74780 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BCED0 | （无名） 调用图传播: 3 锚点投 §4.26（100%） |
| 0x1421B9870 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x1421BC760 | （无名） 调用图传播: 2 锚点投 §4.26（100%） |
| 0x140E72FA0 | （无名） 调用图传播: 2 锚点投 §4.26（50%） |

#### 4.26.40 静态资源访问层函数补遗（223 函）

| VA | 语义/证据 |
|---|---|
| 0x1413150B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1419FA600 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1415DFA30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141AF0ED0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1419E3ED0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1402949E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140C9B9B0 | 无名 sub_（断言站点/串定位） 串字面量 "Module slot name alreadly defined" |
| 0x14147AB70 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141BDCE50 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1406E0AE0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14148AF10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141E16620 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14242B320 | 无名 sub_（断言站点/串定位） 断言站点 gfx_glsl_builder.cpp:415 |
| 0x141EE12C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x141CC0190 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1401ECE70 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140BA6630 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140193C30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:259 |
| 0x141C057E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1409FA3D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140BCBA10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140725310 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1401931A0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:198 |
| 0x141683790 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140E77C60 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140AC5AF0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14006E530 | 无名 sub_（断言站点/串定位） 串字面量 "local_resources_" |
| 0x140AC7520 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:137 |
| 0x140ABB540 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:137 |
| 0x140644310 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:137 |
| 0x140A3E280 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:137 |
| 0x140AE2B90 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:137 |
| 0x1407225C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:137 |
| 0x1401936A0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:198 |
| 0x141D61A00 | 无名 sub_（断言站点/串定位） 串字面量 "resource_icon" |
| 0x141C0C9D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140683A50 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140633AF0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x1406AF590 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x140722DC0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x1409E92E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x140A67920 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x140A80020 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x140AC7FE0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x140AE1730 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x140AE2EF0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x1413C3C10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35 |
| 0x141B54000 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x141097BD0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141C8FD00 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140172A40 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:127 |
| 0x140173DC0 | CTrainGfxDatabase 单例创建器（0xE0B，槽 qword_14332F0C0） 构造器 sub_140ADE8C0 装 `TGameItemDatabase<CTrainGfxDatabase>::vftable`；gameitemdatabase.h:127 |
| 0x140186FE0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x1401864D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x141D9B760 | 无名 sub_（断言站点/串定位） 串字面量 "resources_grid" |
| 0x140150630 | CSpecializationDatabase（NProject）可重载数据库构造 vtable `TReloadableGameItemDatabase<NProject::CSpecializationDatabase>::vftable` |
| 0x1409E93E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:69 |
| 0x140A423C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x140AD0370 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x140AD0930 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x1403F00E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x140A79350 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x140AA2530 | CCountryScorerDatabase 可重载数据库构造 vtable `TReloadableGameItemDatabase<CCountryScorerDatabase>::vftable` |
| 0x140A80120 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x140AC19E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x140AE2FF0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120 |
| 0x1401871A0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x140188870 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x140188150 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x14018A790 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140188230 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x1401886A0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140186850 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140187440 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140188E50 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018A1C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018B880 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140186BD0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140187C60 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140188070 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x140189420 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018A870 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x14018B410 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018A6B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x1401883F0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x1401885B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x1401884D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:179 |
| 0x140683970 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140A42170 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140A425C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140A42710 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140186AF0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140187B80 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140189260 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140189340 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14072B9F0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140ABD440 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140186770 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140187360 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018AD60 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x1402319E0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x14067D280 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x1409B8A30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140A3B510 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140AC4F00 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x140186A10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140187AA0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018A5D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018B000 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018B6B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140186690 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140187280 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x140188A40 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x1401896C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018AA30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x14018B5D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:160 |
| 0x141D9B9D0 | 无名 sub_（断言站点/串定位） 串字面量 "resources_grid" |
| 0x140644F90 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:98 |
| 0x140172260 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:127 |
| 0x140644EF0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22 |
| 0x1415A8290 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141D9B6B0 | 无名 sub_（断言站点/串定位） 串字面量 "resources_grid" |
| 0x140F9C850 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1421089F0 | 无名 sub_（断言站点/串定位） 串字面量 "Not enough resources to create thread" |
| 0x142260990 | GFX/FX 脚本资源懒加载 strcpy "gfx/FX/pdxmesh.lua" + sub_14011D740 |
| 0x140162CB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1406B8AE0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140161530 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161630 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401616B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161730 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401617B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161830 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401618B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161930 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161A30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161B30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161BB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161CB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161DB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161F30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140161FB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162030 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401620B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162130 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401621B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162230 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162330 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401623B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162430 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401624B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162530 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401625B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162630 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401627B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162830 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401628B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401629B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162A30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162BB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162C30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162DB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140162E30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163030 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401630B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163130 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401631B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163230 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163330 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401633B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163430 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401634B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163530 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163630 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401637B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401638B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163B30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163D30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163DB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163F30 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140163FB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401640B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401641B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140164230 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x1401774C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14022F890 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14022FC10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14022FD10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140319E60 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14039DE40 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14039DFC0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14039E140 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14039E1C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14043F4C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14043F540 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140462050 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140487790 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1404B2EE0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14052AD80 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140631F10 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14065A8C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14065A940 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1406B8B60 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140A2A580 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140A46890 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:149 |
| 0x140A7B1C0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140AB2BB0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140B3C300 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140B4B170 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140D55DC0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140DB8C50 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x140F99C70 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141128250 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1414E61D0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x1414E6250 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14169C590 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141C640B0 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141F89A90 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x141F57A60 | 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142 |
| 0x14001EF60 | 无名 sub_（断言站点/串定位） 串字面量 "ey can be defined to override title" |
| 0x140028AC0 | 无名 sub_（断言站点/串定位） 串字面量 "be defined to override title" |
| 0x14001F5C0 | 无名 sub_（断言站点/串定位） 串字面量 "y can be defined to override title" |
| 0x1400288E0 | 无名 sub_（断言站点/串定位） 串字面量 "be defined to override title" |

#### 4.26.41 静态资源访问层函数补遗（75 函）

| VA | 语义/证据 |
|---|---|
| 0x1421E2BE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421E8CF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421E6FA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421D1500 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x141FA5430 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B0430 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BC0E0 | 无名 sub_（调用图定位） 调用图传播: 8/8 锚点投 §4.26 |
| 0x1421CE0A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1401461D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x140ABD290 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x140082160 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B0800 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B3CA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421C1570 | 无名 sub_（调用图定位） 调用图传播: 8/8 锚点投 §4.26 |
| 0x1421AC3D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421ABA20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B37C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421C0340 | 无名 sub_（调用图定位） 调用图传播: 5/7 锚点投 §4.26 |
| 0x1421ABE60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B9F80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x14032E680 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AB890 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x14148E9E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421C9340 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.26 |
| 0x1421B1490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BFE40 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.26 |
| 0x1421C2070 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1423A5D00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1406874F0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.26 |
| 0x1421C9420 | 无名 sub_（调用图定位） 调用图传播: 7/7 锚点投 §4.26 |
| 0x1421BA4B0 | 无名 sub_（调用图定位） 调用图传播: 8/8 锚点投 §4.26 |
| 0x1421BC5F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AC4C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BBB80 | 无名 sub_（调用图定位） 调用图传播: 6/6 锚点投 §4.26 |
| 0x140A05C10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BD0E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x14124A980 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BECF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BA270 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.26 |
| 0x1421B1530 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BD270 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421CE480 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B0750 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.26 |
| 0x141C65080 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AE450 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BC520 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421F3720 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AB910 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421ACCF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AC550 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1415AAAB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x14186C750 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BC3F0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.26 |
| 0x140A400A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1424D7990 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421ABAB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AB980 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B9B00 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.26 |
| 0x141FA4FD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x141290490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421C1420 | 无名 sub_（调用图定位） 调用图传播: 5/5 锚点投 §4.26 |
| 0x1421AC970 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AB540 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BBE50 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.26 |
| 0x1402D7090 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1424E0B30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B9DB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x14102A650 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x140A34610 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x142154E40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421ABC80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x142156CE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x14032E3A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BB300 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421BA1B0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.26 |

#### 4.26.42 静态资源访问层函数补遗（19 函）

| VA | 语义/证据 |
|---|---|
| 0x1421DE250 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421EFF70 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.26 |
| 0x1421C4D60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AF0E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B1AA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B0A50 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.26 |
| 0x1423A3990 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.26 |
| 0x141C628E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421D1440 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.26 |
| 0x1421CF770 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421C4C50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421B5340 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1415AA3B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421CE3F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x141FA5F40 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.26 |
| 0x1421AEFE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421CDFF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421DD8E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |
| 0x1421AD3C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.26 |

#### 4.26.43 静态资源访问层函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x14012E5A0 | （无名） gameitemdatabase.h:882 断言（静态资源库成员） |
| 0x141D636F0 | （无名） gameitemdatabase.h:142 + pdx_scopedptr.h 断言（静态资源库成员） |

#### 4.26.44 静态资源访问层函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x140531C30 | 无名 sub_（人工读体裁定） 本地化格式化器（formatter.cpp "country_culture" + "Formatter %s requires a localization context"） |
| 0x140BE1470 | 无名 sub_（人工读体裁定） 数据库条目遍历（null_object.h "_pInstance" 断言 + a2+12 计数数组） |

#### 4.26.45 静态资源访问层函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x14014F870 | 数据库析构 数据库析构：vtable 名 CPersistentReloadableGameItemDatabase<NProject::CProjectDatabase,CProjectTemplate> 标识项目模板库 |
| 0x1414528B0 | 描述串读写 描述串写入：按 "_DESC" 键查表（sub_14011FFD0）并写入 a2，含 std::string SSO 释放模式 |
| 0x14190D600 | 键解析 定义解析：strcpy "modifiers_list" 经 sub_1422BDA50(a1[2], 键, 1, 1) 解析，结果存 a1[17] |
| 0x140AB5C00 | 数据库析构 TGameItemDatabase<CScriptedTriggerTemplateDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放 |
| 0x1406459B0 | 数据库析构 TGameItemDatabase<CAIStrategyPlanDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放 |
| 0x140AEF740 | 数据库析构 TGameItemDatabase<CUnitNamesDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放 |
| 0x140A3A020 | 数据库析构 TGameItemDatabase<CWarGoalDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放 |

#### 4.26.46 静态资源访问层函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x14014FF50 | TAG别名数据库 TReloadableGameItemDatabase<CCountryTagAliasDatabase> 析构：表项释放 + 基类 vtable 回退 |
| 0x140150210 | 行动令牌数据库 TReloadableGameItemDatabase<COperationTokensDatabase> 析构：表项释放 + 基类 vtable 回退 |

#### 4.26.47 静态资源访问层函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x14002F120 | 本地化 本地化格式器文档（"country_culture formatter" / "custom_effect_tooltip = country_culture&#124;generic_tank_organisation"） |
| 0x142248E40 | 本地化 "localisation" / "localisation_import" 串 + do 计数循环（0x100000 上限） |
| 0x140533570 | 日期格式化 日期格式化：sub_142269220/1772C0 + sub_140534F0(Buffer, "%d %s %d") + SSO 串 |

#### 4.26.48 静态资源访问层函数补遗（8 函）

| VA | 语义/证据 |
|---|---|
| 0x14071BBA0 | 未决窗口函数 · 静态库管理器析构 qword_143330D98 全局库析构：三组 vector（vt+16/sub_140120CE0）+ sub_1401C1F90 |
| 0x141E54280 | 未决窗口函数 · 静态库名称解析 a3==12518 分支取 a2+200 串 → 哈希 → qword_143330D98 库 sub_14071BC80/BD10 查值写 +40 |
| 0x1424DC970 | 未决窗口函数 · 脚本名注册表装载 遍历 qword_1435E3E70 链表，逐串哈希（sub_14011D970）后 sub_14011D740 注册 |
| 0x1403DE9E0 | 未决窗口函数 · 查表+本地化串构造 sub_14054AE70(a1,a2) 查表后经 sub_140545D50(a1+88, a2, &v7) 构造 SSO 串并释放 |
| 0x14167D820 | 未决窗口函数 · 重载监听器注销（TReloadListener<0>） TReloadListener<0> vtable + 从全局 qword_143339AF8 数组移除自身并修正 dword_143339B04 计数 |
| 0x14072B950 | 未决窗口函数 · 串键插入查找表 由 a2 构 SSO 串视图，sub_140BC96D0 转换，sub_140722DC0 插入 a1+88..a1+112 容器 |
| 0x142422440 | 未决窗口函数 · 查表+缺省 60 回退写入 sub_1420BD660(*(a1+384)) + sub_1420BD5A0(v5, a2, v7) → 写 a3 双字与结果，缺省回退 60 |
| 0x140E56F00 | 未决窗口函数 · 400B 记录按索引取拷 sub_140E56690 取索引 → 400B 步长表项(*(a1+8)+80) 按双字计数 memcpy 拷出 |

#### 4.26.49 静态资源访问层函数补遗（50 函）

| VA | 语义/证据 |
|---|---|
| 0x140460CD0 | （无名）Could not find constant category + doesn't match an entry entry（常量类别查找） Could not find constant category + doesn't match an entry entry（常量类别查找） |
| 0x14158F350 | 突袭数据库容器构建 突袭数据库容器构建；memcpy 8B 指针数组+链表遍历，邻 NRaids::CRaidSuccessChanceCustomModifier::[10](-2736B)/CBattalionTypeRequirements::[7]/CEquipmentRequirements::[7]/… |
| 0x1406820B0 | （无名，按上游/loc 定性） 上游 CBuildingDatabase::[1] |
| 0x140AE50F0 | （无名，按证据定性） gameitemdatabase.h 断言站点（数据库条目装载/校验） |
| 0x140A3A460 | （无名，按证据定性） gameitemdatabase.h 断言站点（数据库条目装载/校验） |
| 0x141AFC840 | 脚本目录装载 common/ideas + history/countries + character_export/characters 路径枚举 |
| 0x140639660 | CRule::[12] CRule 规则类槽 12，规则定义族，无域内串佐证 |
| 0x140678FB0 | CAutonomousStateDatabase::Reader CAutonomousStateDatabase::Reader（自治状态库读取器） |
| 0x140AF1C70 | CUnitNamesDatabase::GenerateNameForFleet |
| 0x1422383C0 | CMeshReloader::CollectReloadNames CMeshReloader::CollectReloadNames 网格资源重载 |
| 0x140AAC2F0 | （未命名）CScriptableLocalization 类名引用 CScriptableLocalization 类名引用（脚本化本地化） |
| 0x140AF1E60 | CUnitNamesDatabase::GenerateNameForNavyTheater |
| 0x1401AE230 | （无名，按证据定性） DLC 名单串 'Poland: United and Ready'/'La Resistance'/'No Step Back'/'By Blood Alone' 等（DLC 枚举） |
| 0x140AF1840 | CUnitNamesDatabase::GenerateNameForAirTheatre 静态数据库（单位名称/能力/AI 态度）方法（CUnitNamesDatabase::GenerateNameForAirTheatre） |
| 0x140630070 | CAIEquipmentRoleDatabase::[2] CAIEquipmentRoleDatabase 静态装备角色数据库槽[2] |
| 0x1409CAC60 | （无名） 被 ULexerToken::UEAAXAEAVCReader::NDLC::CMe 调用（静态资源/库装载） |
| 0x141DCC2E0 | SGfxSettingsReader::Reader |
| 0x140613CE0 | CAbilityDatabase::[2] 静态数据库（单位名称/能力/AI 态度）方法（CAbilityDatabase::[2]） |
| 0x140189D20 | TReloadableGameItemDatabase::InitFromDirectory? TReloadableGameItemDatabase::InitFromDirectory 静态库目录装载（名带?） |
| 0x140187D40 | TReloadableGameItemDatabase::InitFromDirectory? 同上（InitFromDirectory 克隆体之另一实例） |
| 0x14018AB10 | TReloadableGameItemDatabase::InitFromDirectory? 同上（InitFromDirectory 克隆体之第三实例） |
| 0x141A04AF0 | 无名 · gameitemdatabase.h 源码路径 \hoi4\\source\\gameitemdatabase.h（gameitemdatabase.h 断言站点（idb 访问门）） |
| 0x141EF6800 | （无名） VA 邻近 NCareerProfile::CCareerProfileViewUpdateable(±80)（静态资源/库装载） |
| 0x140171340 | 未命名业务函数 游戏物件库（gameitemdatabase.h 断言） |
| 0x141B99E20 | 无名 · gameitemdatabase.h 源码路径 \hoi4\\source\\gameitemdatabase.h（gameitemdatabase.h 断言站点（idb 访问门）） |
| 0x140A51B50 | 无名 · gameitemdatabase.h 断言 + idb 项查找链 gameitemdatabase.h 断言 + idb 项查找链 |
| 0x14067AB90 | 无名 · gameitemdatabasehelper.h 空对象数组断言 gameitemdatabasehelper.h 空对象数组断言 |
| 0x140633FC0 | CAIAttitudeDatabase::[1] 静态数据库（单位名称/能力/AI 态度）方法（CAIAttitudeDatabase::[1]） |
| 0x1418EDDF0 | 未命名业务函数 游戏物件库（gameitemdatabase.h 断言） |
| 0x140686E80 | 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言） |
| 0x140AEFE30 | CUnitNamesDatabase::[1] 静态数据库（单位名称/能力/AI 态度）方法（CUnitNamesDatabase::[1]） |
| 0x140BDC0D0 | 无名 · gameitemdatabase.h + null_object.h gameitemdatabase.h + null_object.h 断言 |
| 0x142420020 | CPdxResourceCache<VCString::CTextureResource>::[1] pdx 资源缓存（纹理资源） |
| 0x140BE0B80 | 无名 · gameitemdatabase.h + null_object.h gameitemdatabase.h + null_object.h 断言 |
| 0x1415186E0 | 未命名业务函数 游戏物件库（gameitemdatabase.h 断言） |
| 0x140A3F240 | 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言） |
| 0x14067D0B0 | CBookmarkDatabase::[2] 名:CBookmarkDatabase::[2] |
| 0x140A409E0 | CIdeaDatabase::[1] 名:CIdeaDatabase::[1] |
| 0x140AA3280 | CCountryScorerDatabase::[6] 名:CCountryScorerDatabase::[6] |
| 0x1406AAA40 | 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言） |
| 0x140A39970 | 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言） |
| 0x140AC7DE0 | 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言） |
| 0x140646130 | CAIStrategyDatabase::[1] 名:CAIStrategyDatabase::[1] |
| 0x140A810F0 | COpinionModifierDatabase::[2] 好感修正数据库 |
| 0x1402CCF40 | CNationalFocusDatabase::[1] 国策数据库 |
| 0x140725770 | CDecisionDatabase::[1] 名:CDecisionDatabase::[1] |
| 0x140BAC990 | 未命名业务函数 游戏物件库（gameitemdatabase.h 断言） |
| 0x140623260 | CAgencyUpgradeDatabase::[1] 情报局升级数据库 |
| 0x140AA2890 | CCountryScorerDatabase::[1] CCountryScorerDatabase::[1] + 名字角色规则(CCountryScorerDatabase::[1]); 被 CCountryScorerDatabase::[1] 等 1 命名函数调用 |
| 0x1406BC170 | CCharacterTemplateDatabase::[1] 角色模板数据库 |

#### 4.26.50 静态资源访问层函数补遗（424 函）

| VA | 语义/证据 |
|---|---|
| 0x140A46910 | sub_140A46910 业务 Duplicate database id（库装载重复键检查） |
| 0x140165570 | sub_140165570 业务 数据库异步加载（"Duplicate database id" + 异步任务轮询骨架：完成旗 +100、vtable+8 取状态写 +16、失败置 19） |
| 0x140164CB0 | 业务 串字面量 "Duplicate database id " §4.26 静态资源 |
| 0x140164490 | sub_140164490 业务 Duplicate database id（库装载重复键检查） |
| 0x1406AB5D0 | （无名） 业务 career_profile_medal.cpp:227 + gameitemdatabasehelper.h:149 + 串 "Career profile medals loaded '" |
| 0x140A09E80 | （无名） 业务 std::string 列表构建 + Init_thread 静态；0x140A0A 邻域 equipment_group.cpp/CEquipmentGroup::Reader/CEquipmentGroupDatabase（近邻传播） |
| 0x140A83400 | （无名） 业务 peace_conference_database.cpp:296 + 串 "%s: Multiple peace_action_categories are set as default" |
| 0x1401A3400 | （无名） 业务 同上断言；上游 CDatabaseReloader<CScriptedWindowDatabase>::[2] → 脚本窗口数据库重载 §4.26 静态资源/库装载 |
| 0x140A97330 | （无名） 业务 串 "Expected a list"/"Duplicate ID" + DB 装载形态（CDiplomaticAction::GetFirstCountryRef + gameitemdatabasehelper 断言族） |
| 0x1414DF280 | CPersistedBookmarkPlaythroughDb::[4] 业务 存档书签游玩数据库 vtable 槽 4 |
| 0x141FC5A60 | （无名） 业务 串 "cloud_file"/"missing_dlc_sign"/".txt"：DLC/云文件校验 |
| 0x140C981B0 | （无名） 业务 std_pair_parser.h:71 + "Expected start of list for pair of element"；紧邻 CDuplicateArchetypeDefinition::Reader（0x140C98DD0）同库（近邻传播） |
| 0x1401311E0 | gameitemdatabase.h:882 业务 TGameItemDatabase 模板实例（0x14012D-0x140131 区段同簇，gameitemdatabase.h:882 统一断言，相互调用） |
| 0x14012DD60 | gameitemdatabase.h:882 业务 同上簇，含自递归（数据库分层加载/解析） |
| 0x140131A10 | gameitemdatabase.h:882 业务 同上簇，另一 TGameItemDatabase 模板方法 |
| 0x14019B590 | （无名） 业务 gameitemdatabase.h:281 + 断言 "!_Paths.IsEmpty() && \"Cant reload when not loaded\"" |
| 0x14143EE40 | sub_14143EE40 业务 terrain.cpp 建筑模板/地形 max level 断言 |
| 0x140CB6C80 | （无名） 业务 std_pair_parser.h:71 同上；紧邻 CResourceOrigin::Reader（0x140CB9360）同库（近邻传播） |
| 0x1411FD6D0 | （无名） 业务 std_pair_parser.h:71 同上；0x1411FD 区段为数据库对读取器（近邻传播） |
| 0x14123F350 | 业务 贴图路径处理：2× strcpy ".tga" 扩展名拼接（纹理名解析） |
| 0x14178CEF0 | 业务 GFX 资源查询：构造串 "GFX_default…"（0x616665645F584647 立即数）+ vt+152 数据库查找 + a1+1352 状态 |
| 0x1414DA580 | 业务 `SBookmarkPlaythroughData` vftable ×3（书签游玩数据构造/拷贝，与 CPersistedBookmarkPlaythroughDb 同族） |
| 0x14006CF00 | 业务 名言/加载提示初始化：大量作者串 "\n- Pocahontas"/"\n- Dan Lind"/"\n- Twitch chat"/"\n- Lieutenant Glitterhoof" 等写入静态缓冲 |
| 0x140BB55A0 | 业务 脚本解析：错误串 "Expected start of list of tag"（tag 列表解析器） |
| 0x141CEF460 | — 业务 gameitemdatabase.h:149 "Instance not created." 断言；调用 sub_140683700（0x14068 战略 AI 区段） |
| 0x1408A2400 | NDefines::CDefineRegistryHelper_NInterfaceEQUIPMENT_DESIGNER_SH…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_graphics.h（站点 defines_graphics… |
| 0x1409CB6B0 | 业务 "fff?" 串 + 调 CPersistent::Load，夹于 NDLC::CMetadataDatabase::[1] 与 CMetadata::ReadMember，DLC 元数据持久化装载 |
| 0x142074FC0 | sub_142074FC0 业务 类方法（CDLCDescriptor::vtable） |
| 0x142234F50 | CGraphics::InitSpriteTypes? 业务 func_names 名 CGraphics::InitSpriteTypes?（精灵类型表初始化） |
| 0x1418CE1F0 | — 业务 gameitemdatabase.h:149 "Instance not created." 断言（数据库访问器），无其他线索 |
| 0x140A44ED0 | — 业务 邻域 TGameItemDatabase<CIdeologyDatabase>::[1]（0x140A465B0）= 静态数据库区段 |
| 0x141EC34D0 | 业务 gameitemdatabase.h:142 站点 "Instance not created."，夹于 CIntelLedgerCivilianPanelController::[2](d=4736)，情报台账民用面板数据库条目 |
| 0x14021F6F0 | — 业务 调用解析器原语族（sub_1401AD740/sub_1401516C0/sub_1401A84B0），0x14021 区段 |
| 0x140A8FC00 | 业务 gameitemdatabase.h:142 站点，"Entry doesn't exist in database"/"Duplicate entry in list" 条目校验，数据库（qword_14332F090）条目装载 |
| 0x140988300 | NDefines::CDefineRegistryHelper_NProductionMINIMUM_NUMBER_OF_FA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:257） |
| 0x140BC1A70 | sub_140BC1A70 业务 串 "DLC_MISSING"/"DLC_TO_DISABLE"（DLC 缺失提示） |
| 0x1407D7900 | NDefines::CDefineRegistryHelper_NAirAIR_WING_XP_LOSS_REDUCTION_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1408A7750 | NDefines::CDefineRegistryHelper_NInterfaceNAVAL_STRIKE_FORCE_AT…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_graphics.h（站点 defines_graphics… |
| 0x1408A8AF0 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_MISSION_EFF…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_graphics.h（站点 defines_graphics… |
| 0x14019BA10 | sub_14019BA10 业务 gameitemdatabase.h "!_Paths.IsEmpty()" + "=====" 分隔行 |
| 0x1401A30D0 | sub_1401A30D0 业务 gameitemdatabase.h "!_Paths.IsEmpty()" + "=====" 分隔行 |
| 0x140948050 | NDefines::CDefineRegistryHelper_NNavyINTEL_LEVEL_MEDIUM_HALF_RA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140966F10 | NDefines::CDefineRegistryHelper_NNavySUPPORT_SHIP_RECOVERY_BASE…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140952240 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_SUB_DETEC…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1407915A0 | NDefines::CDefineRegistryHelper_NAIINVASION_TARGET_TRUNCATION_S…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:771） |
| 0x14074E4E0 | NDefines::CDefineRegistryHelper_NAIAIFC_ACTIVATE_IN_POSITION_RA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1011） |
| 0x140942450 | NDefines::CDefineRegistryHelper_NNavyDOMINANCE_CONTROLLED_THRES…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x14098E450 | NDefines::CDefineRegistryHelper_NProjectPROJECT_CAPTURE_DIMINIS…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_project.h（站点 defines_project.h… |
| 0x140805760 | NDefines::CDefineRegistryHelper_NCountryMAX_INTELLIGENCE_NAVY_D…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:84） |
| 0x140EE47E0 | — 业务 gameitemdatabase.h:142 断言 + 调用 sub_140ACBF40（0x140AC 数据库邻域） |
| 0x140827A50 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_DECAY_DAILY::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_diplomacy.h（站点 defines_diplomacy.… |
| 0x140996750 | NDefines::CDefineRegistryHelper_NRailwayGunBASE_CAPTURE_CHANCE::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military.h… |
| 0x140801DF0 | NDefines::CDefineRegistryHelper_NCountryINTEL_FROM_ALLIANCE_FAC…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:81） |
| 0x1407BB9C0 | NDefines::CDefineRegistryHelper_NAIRAIDS_MIN_SUCCESS_FOR_LAUNCH::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1060） |
| 0x14075A770 | NDefines::CDefineRegistryHelper_NAIAI_SURFACE_COMBAT_FUEL_RATIO::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:717） |
| 0x141CC9390 | sub_141CC9390 业务 串 "GFX_frontend_bg_basic_small"（前端背景精灵引用） |
| 0x140936420 | NDefines::CDefineRegistryHelper_NNavyBASE_SPOTTING::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military.h:909） |
| 0x1423056C0 | — 业务 调用解析器原语族（sub_1401AD740/sub_1401516C0/sub_1424C1E40）；0x14230 区段 |
| 0x1415A2650 | — 业务 调用解析器原语族（sub_1401AD740/sub_14014B4E0）；0x1415A 区段 |
| 0x140677CF0 | 业务 ".txt" 串 + Init_thread 静态初始化，夹于 NInternationalMarket::CMarketEquipmentItem::[23](d=2128) 与 CAutonomousState::[8](d=672)，txt 数据文件装载 |
| 0x1414931D0 | — 业务 调用解析器原语族（sub_1401AD740/sub_1424C1540）；0x14149 设计公司邻域 |
| 0x140974540 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_MAX_IN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:392） |
| 0x140979390 | NDefines::CDefineRegistryHelper_NOperativesON_CAPTURE_COUNTERIN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:472） |
| 0x1408373A0 | NDefines::CDefineRegistryHelper_NFactionsFACTION_THEATER_COMMAN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 faction_defines.h（站点 faction_defines.h… |
| 0x1408EF680 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_SECONDARY_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_mapmode.h（站点 defines_mapmode.h… |
| 0x140973FC0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_INTELL…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:390） |
| 0x1408A9690 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_ROOT_OUT_RE…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_graphics.h（站点 defines_graphics… |
| 0x1409A7A80 | NDefines::CDefineRegistryHelper_NSupplyDAYS_TO_START_GIVING_FUL…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:81） |
| 0x140972180 | NDefines::CDefineRegistryHelper_NOperativesDIPLOMATIC_PRESSURE_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:440） |
| 0x1408FB2B0 | NDefines::CDefineRegistryHelper_NMarketCONTRACT_ESTIMATE_AVERAG…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:273） |
| 0x140A8F910 | 业务 "Duplicate entry in list: " / "Entry doesn't exist in database: " 校验串，夹于 Reader(d=2880) 与 NProject::CHasFloatingHarborTrigger::[0]，数据库条目去重校验 |
| 0x140895990 | NDefines::CDefineRegistryHelper_NIntelLAND_COMBAT_ARMY_INTEL_OV…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:6） |
| 0x1408973B0 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_ARMY_INTEL_O…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:26） |
| 0x14095DB70 | NDefines::CDefineRegistryHelper_NNavyPOSITIONING_PENALTY_HOURLY…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140976630 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_NATION…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:382） |
| 0x140977C30 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_STRENG…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:370） |
| 0x14087DE10 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationDEFAULT_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_industrial_organisation.h（站点 d… |
| 0x1408989B0 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_NAVY_INTEL_O…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:18） |
| 0x140891B00 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_NAVA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:270） |
| 0x14088DE80 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_AIR_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:272） |
| 0x141950AC0 | — 业务 gameitemdatabase.h:142 断言 + 调用 0x1414A 设计公司邻域（DESIGNER_DEPLOYED_LEADER_MODIFIERS 0x14149D630） |
| 0x1408161C0 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_LEADERSHIP_CH…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_diplomacy.h（站点 defines_diploma… |
| 0x1408177C0 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_POWER_NAVAL_C…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_diplomacy.h（站点 defines_diploma… |
| 0x1407622D0 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_KEEP_CURR…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:910） |
| 0x14097D640 | NDefines::CDefineRegistryHelper_NOperativesPROPAGANDA_SUB_NETWO…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:423） |
| 0x1408A6BC0 | NDefines::CDefineRegistryHelper_NInterfaceMISSION_PATROL_SOFT_R…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_graphics.h（站点 defines_graphics… |
| 0x140951110 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_MAX_SPEED…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140969620 | NDefines::CDefineRegistryHelper_NNavyUNDERWAY_REPLENISHMENT_CON…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1407FCFA0 | NDefines::CDefineRegistryHelper_NCountryGIE_DIVISION_ATTACK_BON…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:512） |
| 0x14088FCC0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_EVEN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:268） |
| 0x1409A8790 | NDefines::CDefineRegistryHelper_NSupplyFLOATING_HARBOR_ADDED_PE…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:40） |
| 0x1409A5140 | NDefines::CDefineRegistryHelper_NSupplyBASE_SUPPLY_MULT_FOR_TRU…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:62） |
| 0x14076B5D0 | NDefines::CDefineRegistryHelper_NAICASUALTY_RATIO_TO_PULL_EXPED…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:607） |
| 0x1408230B0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_COST_FACTOR_UNC…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_diplomacy.h（站点 defines_diploma… |
| 0x14082DB00 | NDefines::CDefineRegistryHelper_NDoctrinesMASTERY_BANK_CONVERSI…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_doctrines.h（站点 defines_doctrin… |
| 0x14082F310 | NDefines::CDefineRegistryHelper_NDoctrinesTRAINING_MASTERY_GAIN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_doctrines.h（站点 defines_doctrin… |
| 0x1409CEE00 | — 业务 CModifier 类名；0x1409C-E 区段修正定义数据库邻域 |
| 0x1407F4D60 | NDefines::CDefineRegistryHelper_NCharacterPOLITICAL_ADVISOR_SLO…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_character.h（站点 defines_charact… |
| 0x1408FC9E0 | NDefines::CDefineRegistryHelper_NMarketPURCHASE_CONTRACT_DELIVE…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:261） |
| 0x1409841F0 | NDefines::CDefineRegistryHelper_NProductionCONVOY_MAX_NAV_FACTO…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:192） |
| 0x14098F660 | NDefines::CDefineRegistryHelper_NProjectSCIENTIST_BASIC_RESEARC…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_project.h（站点 defines_project.h… |
| 0x14098BC20 | NDefines::CDefineRegistryHelper_NProjectBREAKTHROUGH_DAILY_TECH…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_project.h（站点 defines_project.h… |
| 0x1407E9C00 | NDefines::CDefineRegistryHelper_NAirNAVAL_MINES_PLANTING_SPEED_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1408A3200 | NDefines::CDefineRegistryHelper_NInterfaceFLEET_BOTTOM_BAR_PADD…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_graphics.h（站点 defines_graphics… |
| 0x140949540 | NDefines::CDefineRegistryHelper_NNavyMAX_ADMIRAL_HEADQUARTER_AS…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140783A20 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_EXTRA_CONVO…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:91） |
| 0x140784640 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_NR_DELIVERI…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:90） |
| 0x1409A3290 | NDefines::CDefineRegistryHelper_NSupplyAI_FRONT_MAX_UNITS_ENEMY…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:125） |
| 0x140757010 | NDefines::CDefineRegistryHelper_NAIAIR_DESIGN_ALTERNATIVE_OF_GR…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:128） |
| 0x140790470 | NDefines::CDefineRegistryHelper_NAIINDUSTRIAL_ORG_TRAIT_UNLOCK_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:994） |
| 0x14081A050 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_NEUTRAL_DIS…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_diplomacy.h（站点 defines_diploma… |
| 0x1407ECEE0 | NDefines::CDefineRegistryHelper_NAirSTRATEGIC_BOMBING_STATE_BUI…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140953090 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_SUB_DETEC…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1409AB8D0 | NDefines::CDefineRegistryHelper_NSupplyNAVAL_BASE_ADDED_PENALTY…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:30） |
| 0x140864F20 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_AIR_MAX_SEG…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 raid_defines.h（站点 raid_defines.h:47） |
| 0x140893520 | NDefines::CDefineRegistryHelper_NIntelINTEL_NETWORK_NATIONAL_CO…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:43） |
| 0x14097D900 | NDefines::CDefineRegistryHelper_NOperativesQUIET_INTEL_NETWORK_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:399） |
| 0x140934320 | NDefines::CDefineRegistryHelper_NNavyANTI_AIR_POW_ON_INCOMING_A…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140943310 | NDefines::CDefineRegistryHelper_NNavyDOMINANCE_PER_SHIP_PER_CAR…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140953F00 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_MEDAL_MIN_DUR…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1409093C0 | NDefines::CDefineRegistryHelper_NMilitaryENGAGEMENT_WIDTH_PER_W…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1409B1630 | NDefines::CDefineRegistryHelper_NSupplySUPPLY_HUB_FULL_MOTORIZA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:85） |
| 0x140798700 | NDefines::CDefineRegistryHelper_NAILAND_DESIGN_DEMAND_FIELD_DIV…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:119） |
| 0x1407AD6B0 | NDefines::CDefineRegistryHelper_NAINAVAL_PATROL_PLANES_PER_SHIP…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:455） |
| 0x1407C5620 | NDefines::CDefineRegistryHelper_NAISTRIKE_FORCE_TARGET_RECALC_D…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1072） |
| 0x1408808B0 | NDefines::CDefineRegistryHelper_NIntelAIR_COMBAT_AIR_INTEL_PER_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_intel.h（站点 defines_intel.h:39） |
| 0x14096D1F0 | NDefines::CDefineRegistryHelper_NOperativesBOOST_IDEOLOGY_DAILY…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:417） |
| 0x140970FA0 | NDefines::CDefineRegistryHelper_NOperativesDANGER_LEVEL_INTEGRA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:469） |
| 0x1409AEF20 | NDefines::CDefineRegistryHelper_NSupplyRAILWAY_FLOW_PENALTY_PER…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:7） |
| 0x14076D4C0 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_FACTOR_OWN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:671） |
| 0x1409ACED0 | NDefines::CDefineRegistryHelper_NSupplyNODE_ADDED_PENALTY_PER_P…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:26） |
| 0x14090D910 | NDefines::CDefineRegistryHelper_NMilitaryGENERAL_PROXIMITY_CLOSE::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1407FE860 | NDefines::CDefineRegistryHelper_NCountryGIE_EXILE_AIR_START_EXP…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:503） |
| 0x14091CDD0 | NDefines::CDefineRegistryHelper_NMilitaryPLANNING_CAP_NO_HQ_SCA…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x14096EE10 | NDefines::CDefineRegistryHelper_NOperativesCONTROL_TRADE_MAX_IN…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:434） |
| 0x1407DC9E0 | NDefines::CDefineRegistryHelper_NAirCOMBAT_DAMAGE_STATS_MULTILP…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x140800A00 | NDefines::CDefineRegistryHelper_NCountryGIE_MANPOWER_TOTAL_MAX_…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:499） |
| 0x14074FB70 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_ADJ_RIVER_LAR…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1042） |
| 0x1409B32D0 | NDefines::CDefineRegistryHelper_NSupplyTRAIN_ARMOR_TARGETING_WE…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:110） |
| 0x140949280 | NDefines::CDefineRegistryHelper_NNavyMANPOWER_LOSS_RATIO_ON_SUNK::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military… |
| 0x1409A6740 | NDefines::CDefineRegistryHelper_NSupplyCAPITAL_NODE_BASE_SUPPLY…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_supply.h（站点 defines_supply.h:69） |
| 0x1407BB4F0 | NDefines::CDefineRegistryHelper_NAIRAIDS_CREATE_FREQUENCY_DAYS::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1057） |
| 0x1407EBC50 | NDefines::CDefineRegistryHelper_NAirPORT_STRIKE_DAMAGE_FACTOR::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military.h:… |
| 0x1407DA570 | NDefines::CDefineRegistryHelper_NAirBIGGEST_AGILITY_FACTOR_DIFF::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_military.h（站点 defines_military.… |
| 0x1407718D0 | NDefines::CDefineRegistryHelper_NAIDANGEROUS_ENEMY_ARMY_SIZE::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1074） |
| 0x14081B0D0 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_RATIO_CORE::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_diplomacy.h（站点 defines_diplomacy… |
| 0x14076EAC0 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_UNSPECIFIED::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:668） |
| 0x1408670E0 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_NAVAL_SHARP…::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 raid_defines.h（站点 raid_defines.h:49） |
| 0x1407C1BB0 | NDefines::CDefineRegistryHelper_NAIRESEARCH_YEARS_BEHIND_FACTOR::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:39） |
| 0x140751170 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_TRN_HILLS::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:1046） |
| 0x14075ED50 | NDefines::CDefineRegistryHelper_NAIARMY_CHIEF_SCORE_MULTIPLIER::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_ai.h（站点 defines_ai.h:569） |
| 0x14098C460 | NDefines::CDefineRegistryHelper_NProjectDEFAULT_COMPLEXITY::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_project.h（站点 defines_project.h:4） |
| 0x1409B5950 | NDefines::CDefineRegistryHelper_NTechnologyMIN_RESEARCH_SPEED::[0] 业务 NDefines::CDefineRegistryHelper 模板实例，define 组 defines_game.h（站点 defines_game.h:290） |
| 0x1416CD2E0 | (无名) 业务 调用窗口内命名函数 sub_1422431C0 |
| 0x1419662A0 | sub_1419662A0 业务 串：_pInstance && \ 、 C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi4\\source\\gamei |
| 0x1410023F0 | sub_1410023F0 业务 串：Invalid enum. 、 C:\\mnt\\gsg\\hoi4\\hoi4_merged\\clausewitz\\clausewit |
| 0x140189880 | TReloadableGameItemDatabase::InitFromDirectory? 业务 TReloadableGameItemDatabase::InitFromDirectory，可重载库目录装载（"DB already loaded when loading " + gameitemdataba… |
| 0x141FA9800 | sub_141FA9800 业务 串：_pPtr 、 C:\\mnt\\gsg\\hoi4\\hoi4_merged\\clausewitz\\pdx_core\\pdx_sco |
| 0x140899B90 | NDefines::CDefineRegistryHelper_NIntelNAVY_DEPLOYED_MANPOWER_CO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14088EB90 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_CAPT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408A16F0 | NDefines::CDefineRegistryHelper_NInterfaceCOUNTERINTELLIGENCE_A…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140963D60 | NDefines::CDefineRegistryHelper_NNavySPOTTING_SPEED_EFFECT_FOR_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F4E80 | NDefines::CDefineRegistryHelper_NMapModePEACE_CONFERENCE_CHANGE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14092B790 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_LEADER_MODIFIER_C…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140918390 | NDefines::CDefineRegistryHelper_NMilitaryNEW_COMMANDER_RANDOM_P…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F0300 | NDefines::CDefineRegistryHelper_NMapModeDEPLOYED_GENERAL_UNIT_L…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14090D0D0 | NDefines::CDefineRegistryHelper_NMilitaryFUEL_FLOW_PENALTY_FOR_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140914190 | NDefines::CDefineRegistryHelper_NMilitaryMAX_ESTIMATED_PLAN_UNI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409687B0 | NDefines::CDefineRegistryHelper_NNavyTRAINING_DAILY_COUNTRY_EXP…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14089CD10 | NDefines::CDefineRegistryHelper_NIntelNAVY_TASKFORCE_COUNT_INTE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408EDC60 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_MAP_MODE_B…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409952B0 | NDefines::CDefineRegistryHelper_NRaidsTARGET_INTEL_PER_CIVILIAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140957DF0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINES_ACCIDENT_CRITI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14091DB90 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_AREA_DEFENSE_COAS…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140930CD0 | NDefines::CDefineRegistryHelper_NNavyAGGRESSION_LEVEL_BY_MISSIO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14093D6C0 | NDefines::CDefineRegistryHelper_NNavyCONVOY_DEFENSE_MAX_REGION_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140931D50 | NDefines::CDefineRegistryHelper_NNavyAGGRESSION_TORPEDO_EFFICIE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409984C0 | NDefines::CDefineRegistryHelper_NRailwayGunDISTRIBUTION_OUR_UNI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408ECBE0 | NDefines::CDefineRegistryHelper_NMapModeAIR_RANGE_CAN_ASSIGN_MI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140902270 | NDefines::CDefineRegistryHelper_NMilitaryBASE_FEMALE_DIVISIONAL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140921D90 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_PROVINCE_LOW_VP_D…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140941C10 | NDefines::CDefineRegistryHelper_NNavyDETECTION_CHANCE_MULT_AIR_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14094E250 | NDefines::CDefineRegistryHelper_NNavyMISSION_DAILY_COUNTRY_EXP_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F2400 | NDefines::CDefineRegistryHelper_NMapModeMAP_MODE_INTEL_NETWORK_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F7240 | NDefines::CDefineRegistryHelper_NMapModeSELECTED_COUNTRY_HIGHLI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409293D0 | NDefines::CDefineRegistryHelper_NMilitarySURPLUS_SUPPLY_RATIO_F…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140973BA0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_GAIN_R…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409A08A0 | NDefines::CDefineRegistryHelper_NResistanceRESISTANCE_TARGET_MO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14088C510 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_TRUCKS_INTEL_RAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140980030 | NDefines::CDefineRegistryHelper_NPoliticsMIN_OVERTHROWN_GOVERNM…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140987070 | NDefines::CDefineRegistryHelper_NProductionLICENSE_EQUIPMENT_TE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409998C0 | NDefines::CDefineRegistryHelper_NResistanceCOMPLIANCE_DECAY_PER…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408AA920 | NDefines::CDefineRegistryHelper_NInterfacePRODUCTION_SHIP_FILTE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408FDD20 | NDefines::CDefineRegistryHelper_NMilitaryACCLIMATIZATION_IN_COM…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140933610 | NDefines::CDefineRegistryHelper_NNavyAMPHIBIOUS_INVADE_LANDING_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140946AC0 | NDefines::CDefineRegistryHelper_NNavyINITIAL_ALLOWED_DOCKYARD_R…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14093E740 | NDefines::CDefineRegistryHelper_NNavyCONVOY_RAID_MAX_REGION_TO_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409939F0 | NDefines::CDefineRegistryHelper_NRaidsRAID_SUCCESS_MODIFIER_THR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14093B5C0 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_EVASION_TO_HIT_CHAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B92E0 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_FABRICATE_CL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C16E0 | NDefines::CDefineRegistryHelper_NMapIconsHOME_BASE_MAP_ICON_SCA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14099F820 | NDefines::CDefineRegistryHelper_NResistanceRESISTANCE_TARGET_MO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140922E10 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_PROVINCE_PRIO_DIS…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408BB3E0 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_FABRICATE_CL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14090FCD0 | NDefines::CDefineRegistryHelper_NMilitaryLAND_AIR_COMBAT_ORG_DA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409A9600 | NDefines::CDefineRegistryHelper_NSupplyFLOATING_HARBOR_DECAY_MA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140905A00 | NDefines::CDefineRegistryHelper_NMilitaryCOMBAT_SUPPLY_LACK_DEF…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140920D10 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_PORVINCE_PORT_BAS…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F3480 | NDefines::CDefineRegistryHelper_NMapModeNAVAL_DOMINANCE_TREND_B…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409508D0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_CARRIER_T…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14095B230 | NDefines::CDefineRegistryHelper_NNavyNAVY_PIERCING_THRESHOLD_DA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140926250 | NDefines::CDefineRegistryHelper_NMilitaryRIVER_CROSSING_SPEED_P…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140965480 | NDefines::CDefineRegistryHelper_NNavySUBMARINE_REVEAL_DETECTION…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409402C0 | NDefines::CDefineRegistryHelper_NNavyCOORDINATION_EFFECT_ON_MIN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14098A920 | NDefines::CDefineRegistryHelper_NProductionSHIP_REFIT_MAX_PROGR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14099ACC0 | NDefines::CDefineRegistryHelper_NResistanceGARRISON_EQUIPMENT_D…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408BA360 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_FABRICATE_CL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140900170 | NDefines::CDefineRegistryHelper_NMilitaryARMY_INITIATIVE_REINFO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140916290 | NDefines::CDefineRegistryHelper_NMilitaryMEDAL_AWARD_CONFIRM_PP…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14092C810 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_LEADER_TRAIT_SLOT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140956D70 | NDefines::CDefineRegistryHelper_NNavyNAVAL_HOMEBASE_BUILDING_SC…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B2FE0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_MILITARY_PR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14090EC50 | NDefines::CDefineRegistryHelper_NMilitaryHISTORICAL_ORDER_NAME_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408A4B70 | NDefines::CDefineRegistryHelper_NInterfaceMID_NON_SUCCESSFUL_CO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408A5BF0 | NDefines::CDefineRegistryHelper_NInterfaceMIN_NON_SUCCESSFUL_CO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140985720 | NDefines::CDefineRegistryHelper_NProductionEQUIPMENT_MODULE_CON…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14089AC10 | NDefines::CDefineRegistryHelper_NIntelNAVY_MAPICON_MISSION_COUN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14095A1B0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_TRANSFER_BASE_NAVAL_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140969AF0 | NDefines::CDefineRegistryHelper_NNavyUNDERWAY_REPLENISHMENT_RAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140982130 | NDefines::CDefineRegistryHelper_NProductionBASE_FACTORY_EFFICIE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140892810 | NDefines::CDefineRegistryHelper_NIntelENCRYPTION_DECRYPTION_INT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14093C640 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_RESULT_PRIORITY_DAY…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14096BBF0 | NDefines::CDefineRegistryHelper_NOperativesAGENCY_AI_PER_UPGRAD…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14099D460 | NDefines::CDefineRegistryHelper_NResistanceNO_COMPLIANCE_GAIN_E…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B4060 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_MILITARY_PR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B0EE0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_AIR_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E47E0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_NAVY_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E68E0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_REGIONS_PRIO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140953560 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_SUB_TARGE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140997440 | NDefines::CDefineRegistryHelper_NRailwayGunDISTRIBUTION_DISTANC…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14091B510 | NDefines::CDefineRegistryHelper_NMilitaryPARACHUTE_FAILED_EQUIP…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F8840 | NDefines::CDefineRegistryHelper_NMapModeSTRATEGIC_MODE_OUR_STRI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14095F430 | NDefines::CDefineRegistryHelper_NNavyREPAIR_AND_RETURN_PRIO_LOW…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140979D30 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_BASE_BOOST…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409B6F50 | NDefines::CDefineRegistryHelper_NTradeNAVAL_ROUTE_ACCESS_AVOID_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14092D890 | NDefines::CDefineRegistryHelper_NMilitaryWAR_SCORE_LAND_DAMAGE_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140954E20 | NDefines::CDefineRegistryHelper_NNavyNAVAL_CONVOY_DANGER_TRIGGE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C79E0 | NDefines::CDefineRegistryHelper_NMapIconsINTERPOLATION_SNAP_DIS…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F9E40 | NDefines::CDefineRegistryHelper_NMapModeSUPPLY_MAP_MODE_STATUS_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140983B10 | NDefines::CDefineRegistryHelper_NProductionCAPITULATE_STOCKPILE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409385E0 | NDefines::CDefineRegistryHelper_NNavyBEST_CAPITALS_TO_SCREENS_R…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14095C570 | NDefines::CDefineRegistryHelper_NNavyNEW_NAVY_LEADER_LEVEL_CHAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409032F0 | NDefines::CDefineRegistryHelper_NMilitaryBORDER_WAR_WIN_DAYS_AG…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14092F990 | NDefines::CDefineRegistryHelper_NMilitaryZERO_ORG_MOVEMENT_MODI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408FEDA0 | NDefines::CDefineRegistryHelper_NMilitaryANTI_AIR_ATTACK_TO_AMO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140928350 | NDefines::CDefineRegistryHelper_NMilitarySTRATEGIC_SPEED_INFRA_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408DB360 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION_PRI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408CED60 | NDefines::CDefineRegistryHelper_NMapIconsPEACE_CONFERENCE_PRIOR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14092E910 | NDefines::CDefineRegistryHelper_NMilitaryWAR_SCORE_PROVINCE_FAC…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14095DE30 | NDefines::CDefineRegistryHelper_NNavyPRIDE_OF_THE_FLEET_LOST_TE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14099BD40 | NDefines::CDefineRegistryHelper_NResistanceINITIAL_GARRISON_STR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14089ED00 | NDefines::CDefineRegistryHelper_NIntelRECON_PLANE_LAND_DISTRIBU…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B1F60 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_AIR_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B71E0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_NAVY_PRIORI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B8260 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_NAVY_PRIORI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408DA2E0 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION_PRI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E5860 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_NAVY_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E7960 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_REGIONS_PRIO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409704A0 | NDefines::CDefineRegistryHelper_NOperativesCRYPTO_BASE_CRYPTO_L…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14090A700 | NDefines::CDefineRegistryHelper_NMilitaryFASTER_ORG_REGAIN_LEVEL::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140944440 | NDefines::CDefineRegistryHelper_NNavyESCAPE_SPEED_PER_COMBAT_DAY::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409906C0 | NDefines::CDefineRegistryHelper_NRaidsARMY_TRANSFER_AVOID_ENEMY::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408CFDE0 | NDefines::CDefineRegistryHelper_NMapIconsPEACE_CONFERENCE_PRIOR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409A1920 | NDefines::CDefineRegistryHelper_NSoundBATTLE_SOUND_FALLOFF_DEFA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409272D0 | NDefines::CDefineRegistryHelper_NMilitarySLOWER_ORG_REGAIN_MULT::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B50E0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_MILITARY_PR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408CCC60 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORITY_NA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409251D0 | NDefines::CDefineRegistryHelper_NMilitaryRELIABILITY_ORG_MOVING::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409810B0 | NDefines::CDefineRegistryHelper_NProductionANNEX_STOCKPILES_RAT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14099E7A0 | NDefines::CDefineRegistryHelper_NResistanceRESISTANCE_GROWTH_BA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140919410 | NDefines::CDefineRegistryHelper_NMilitaryNON_CORE_SUPPLY_SPEED::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140967730 | NDefines::CDefineRegistryHelper_NNavyTRAINING_ACCIDENT_CHANCES::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C58E0 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408EAAE0 | NDefines::CDefineRegistryHelper_NMapIconsSUPPLY_AREAS_PRIORITY_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408EBB60 | NDefines::CDefineRegistryHelper_NMapIconsSUPPLY_AREAS_PRIORITY_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140910D50 | NDefines::CDefineRegistryHelper_NMilitaryLAND_COMBAT_ORG_ARMOR_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409895E0 | NDefines::CDefineRegistryHelper_NProductionPOWERED_FACTORY_SPEED::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14089BC90 | NDefines::CDefineRegistryHelper_NIntelNAVY_SHIP_COUNT_INTEL_MAX::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14091A490 | NDefines::CDefineRegistryHelper_NMilitaryOUT_OF_SUPPLY_MORALE::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140959130 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINE_DANGER_RATIOS::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409011F0 | NDefines::CDefineRegistryHelper_NMilitaryATTRITION_DAMAGE_ORG::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1413AEE50 | sub_1413AEE50 业务 串：GFX_idea_unknown |
| 0x14091EC10 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_BLITZ_OPTIMISM::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14093A540 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_BASE_HIT_CHANCE::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409454C0 | NDefines::CDefineRegistryHelper_NNavyFIELD_EXPERIENCE_SCALE::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140913110 | NDefines::CDefineRegistryHelper_NMilitaryMAX_AIR_EXPERIENCE::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14097EFB0 | NDefines::CDefineRegistryHelper_NPoliticsARMY_LEADER_MAX_COST::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140962640 | NDefines::CDefineRegistryHelper_NNavySHORE_BOMBARDMENT_CAP::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409A29A0 | NDefines::CDefineRegistryHelper_NSoundHEIGHT_SOUND_MIN_VOLUME::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14092A710 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_DIGIN_SPEED::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140934C10 | NDefines::CDefineRegistryHelper_NNavyATTRITION_DAMAGE_STR::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140A86390 | 业务 断言站点 orderinstance.cpp:11; 串 "!\"Battleplans - trying to do invali"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1408F1380 | NDefines::CDefineRegistryHelper_NMapModeFACTION_THEATER_COLOR_I…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408F61C0 | NDefines::CDefineRegistryHelper_NMapModeRADAR_RANGE_COLOR::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14091C590 | NDefines::CDefineRegistryHelper_NMilitaryPEN_VS_AVERAGE::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14094BCE0 | NDefines::CDefineRegistryHelper_NNavyMINIMUM_SHIP_SPEED::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C4860 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408CDCE0 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORITY_ST…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408DC3E0 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION_PRI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E89E0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_REGIONS_PRIO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409B4090 | NDefines::CDefineRegistryHelper_NSupplyVP_TO_SUPPLY_BASE::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409B5ED0 | NDefines::CDefineRegistryHelper_NTradeALLOW_TRADE_CUT_OFF::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D0E60 | NDefines::CDefineRegistryHelper_NMapIconsPEACE_CONFERENCE_PRIOR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140936210 | NDefines::CDefineRegistryHelper_NNavyBASE_POSITIONING::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140924150 | NDefines::CDefineRegistryHelper_NMilitaryPREFERRED_TACTIC_COMMA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D5060 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORITY_GU…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E1660 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_AIR_PRIORITY…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C6960 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D2F60 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_NAVAL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D3FE0 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_UNITS…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D7160 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORITY_VI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E05E0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_AIR_PRIORITY…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E26E0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_AIR_PRIORITY…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140895F10 | NDefines::CDefineRegistryHelper_NIntelLAND_SPOT_DECAY::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408BF5E0 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_NAVA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408B6160 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_NAVY_PRIORI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408ABC60 | NDefines::CDefineRegistryHelper_NInterfaceTOOLTIP_SCREEN_BOTTOM…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408BD4E0 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY_NAV…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408BE560 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_ADJA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D9260 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY_NAV…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408AFE60 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_AIR_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C37E0 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_NAVA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C9AE0 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_NAVA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D60E0 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORITY_NA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E3760 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_NAVY_PRIORIT…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140909680 | NDefines::CDefineRegistryHelper_NMilitaryENTRIES_TO_CHECK_FOR_D…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408E9A60 | NDefines::CDefineRegistryHelper_NMapIconsSUPPLY_AREAS_PRIORITY_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408BC460 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY_LAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D81E0 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY_LAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408A0320 | NDefines::CDefineRegistryHelper_NInterfaceARMY_GROUP_PORTRAIT_S…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408A3AF0 | NDefines::CDefineRegistryHelper_NInterfaceFUEL_STOCKPILE_DURATI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408ADD60 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_NAVAL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C2760 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_LAND…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C8A60 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_LAND…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140907000 | NDefines::CDefineRegistryHelper_NMilitaryCORPS_COMMANDER_DIVISI…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408CAB60 | NDefines::CDefineRegistryHelper_NMapIconsOPERATION_PRIORITY_CAN…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408ACCE0 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_AIR_M…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408AEDE0 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_ROCKE…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408C0660 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_PEAC…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408CBBE0 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORITY_CA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14090B780 | NDefines::CDefineRegistryHelper_NMilitaryFIELD_MARSHAL_DIVISION…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408DE4E0 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_NAVAL_…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140917310 | NDefines::CDefineRegistryHelper_NMilitaryNAVAL_EQUIPMENT_BASE_C…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14097BE30 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_MIN_DAYS_H…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408D1EE0 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_FACIL…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140911DD0 | NDefines::CDefineRegistryHelper_NMilitaryLAND_EQUIPMENT_RAMP_CO…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408DD460 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_AIR_BA…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1408DF560 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_RESOUR…::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x1409604B0 | NDefines::CDefineRegistryHelper_NNavyRESOURCE_PURCHASE_PRIORITY::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140915210 | NDefines::CDefineRegistryHelper_NMilitaryMAX_LEADERS_TO_SHOW::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140908340 | NDefines::CDefineRegistryHelper_NMilitaryDIVISION_SIZE_FOR_XP::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x140904630 | NDefines::CDefineRegistryHelper_NMilitaryCOMBAT_MINIMUM_TIME::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14091FC90 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_EXECUTE_RUSH::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14094F2D0 | NDefines::CDefineRegistryHelper_NNavyMISSION_MAX_REGIONS::[0] 业务 NDefines::CDefineRegistryHelper 读取器（define 族，自文档 define 名） |
| 0x14124F1A0 | (无名) 业务 调用窗口内命名函数 sub_1422383C0 |
| 0x1421072F0 | 业务 断言站点 gameitemdatabase.h:79 ->§4.26; 断言站点 orderinstance.cpp:46; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1422EBDB0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1420CEC70 | 业务 断言站点 checksumfile.cpp:33 ->§4.1; 断言站点 checksumfile.cpp:23 ->§4.1; 断言站点 gameitemdatabase.h:42 ->§4.26 |
| 0x141E0D720 | 业务 断言站点 gameitemdatabasehelper.h:35 ->§4.26; 串 ") { if ( v3 ) "; 串 "; do ++v4; " |
| 0x140BE71A0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x14011B210 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 CPrintVariablesEffect ->§4.32; 串 "Clausewitz Error" |
| 0x142445740 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 NCombatLog ->§4.25; 串 "_pInstance && \"Instance not created" |
| 0x140AF4E80 | 业务 串 "Math program must start with value ="; 串 "diplo_repl"; 串 "REPLY_NOT_NEEDED" |
| 0x140A25230 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1424E8CE0 | 业务 断言站点 gameitemdatabase.h:60 ->§4.26; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"; 串 "DB already loaded when loading" |
| 0x142243F30 | 业务 断言站点 gameitemdatabasehelper.h:20 ->§4.26; 串 "( Array.GetSize() > 0 ) && \"Array s"; 串 "add the Null Object as Array[0]?\"" |
| 0x142298780 | 业务 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 串 "( Array.GetSize() > 0 ) && \"Array s"; 串 "o add the Null Object as Array[0]?\"" |
| 0x142186FD0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 CFixedWindow ->§4.30; 类路由 NFactions ->§4.25 |
| 0x1421FE3A0 | 业务 断言站点 gameitemdatabase.h:79 ->§4.26; 断言站点 null_object.h:33; 类路由 CRemoveAllProductionLineCommand ->§4.33 |
| 0x142426280 | 业务 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 断言站点 array2d.h:54 ->§4.1; 串 "( Array.GetSize() > 0 ) && \"Array s" |
| 0x141A0E820 | 业务 断言站点 id.cpp:22; 断言站点 id.cpp:90; 断言站点 gameitemdatabasehelper.h:20 ->§4.26 |
| 0x142460630 | 业务 断言站点 gameitemdatabase.h:60 ->§4.26; 类路由 NIndustrialOrganisation ->§4.25; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x140F8B3B0 | 业务 断言站点 gameitemdatabasehelper.h:98 ->§4.26; 类路由 CBuildingRosterItem ->§4.31; 串 "There are %d joysticks available" |
| 0x140BAE4A0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1421DC930 | 业务 断言站点 pdx_bindable_loc_validator.cpp:16; 串 "You are trying to create a second in"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x140AE3F90 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x1410C7840 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x141E2F360 | 业务 断言站点 gameitemdatabase.h:27 ->§4.26; 串 "!_pInstance && \"Instance already cr"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x14231A400 | 业务 断言站点 gameitemdatabase.h:27 ->§4.26; 类路由 NProject ->§4.25; 串 "!_pInstance && \"Instance already cr" |
| 0x14248AE80 | 业务 断言站点 gameitemdatabase.h:27 ->§4.26; 串 "EnumSystemLocalesEx"; 串 "EnumSystemLocalesEx" |
| 0x140A3FF00 | 业务 类路由 NPdx ->§4.25; 类路由 CAgencyUpgradesWindow ->§4.30; 调用图 IDF top §4.1 frac 1.00 |
| 0x140B89520 | 业务 断言站点 gameitemdatabase.h:49 ->§4.26; 断言站点 market_stockpile.cpp:87; 类路由 CNavalRepairQueueShipEntry ->§4.31 |
| 0x14240B650 | 业务 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 类路由 CStrategicAir ->§4.15; 类路由 CTechnologySharing ->§4.7 |
| 0x140D5F4D0 | 业务 断言站点 diplomaticaction.cpp:10; 断言站点 equipmentvariantbuilder.cpp:59; 断言站点 gameitemdatabase.h:42 ->§4.26 |
| 0x1423A8020 | 业务 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 串 "( Array.GetSize() > 0 ) && \"Array s"; 串 "o add the Null Object as Array[0]?\"" |
| 0x14209CCB0 | 业务 遍历 a1+16 数组按 SSO 串（+2624 指针/+2648 长度>0xF）逐字节比较 a2，命中返元素 按名线性查找（SSO 串比较） |
| 0x1402C2060 | 业务 断言站点 gameitemdatabasehelper.h:35 ->§4.26; 串 "( Array.GetSize() == Lookup.GetSize("; 串 "than Lookup, did you forget to add t" |
| 0x1421B11F0 | 业务 串 "error in error handling"; 串 "not enough memory"; 调用图 IDF top §4.1 frac 0.77 |
| 0x14143D340 | 业务 73244475 乘性哈希查 a1+440 桶表（掩码 a1+452），链走比较 dword，返 a1+408 表中 272B 元素或 a1+168 哨兵 哈希按 id 查找 |
| 0x1421C32C0 | 业务 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 串 "Visual C++ CRT: Not enough memory to"; 串 "Visual C++ CRT: Not enough memory to" |
| 0x1411F1810 | 业务 断言站点 effectimplementation.cpp:35 ->§4.32; 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 类路由 SAirUnitActivityData ->§4.28 |
| 0x142400FA0 | 业务 73244475 哈希查 a1+24 桶表（掩码 a1+36，40B 桶），链走比较 dword，返 byte != 0xFF 哈希包含判定 |
| 0x1415ABDA0 | 业务 73244475 乘性哈希查 a1+56 桶表（掩码 a1+68，24B 桶），链走比较 dword 返回 *(桶+16) 哈希按 id 查找 |
| 0x1421C1FB0 | 业务 断言站点 gameitemdatabasehelper.h:20 ->§4.26; 串 "'%s' expected"; 串 "'%s' expected (to close '%s' at line" |
| 0x140AC69E0 | 业务 73244475 乘性哈希查 a1+56 桶表（掩码 a1+68），链走比较 dword 返回 *(桶+16) 哈希按 id 查找 |
| 0x1420DBDF0 | 业务 断言站点 gameitemdatabase.h:27 ->§4.26; 类路由 NCareerProfile ->§4.25; 串 "%02x" |
| 0x14165E840 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 NFactions ->§4.25; 串 "_pInstance && \"Instance not created" |
| 0x1420EEA20 | 业务 断言站点 savegamehelper.cpp:86 ->§4.1; 断言站点 gameitemdatabase.h:27 ->§4.26; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\cla" |
| 0x1401DB2A0 | 业务 dword_1433386CC 计数 + qword_1433386C0 浮点数组按 a2 索引（钳位）取值，缺省回退 xmmword_142724360 五浮点常量表 按索引取浮点表项（钳位） |
| 0x14228FE00 | 业务 FNV-1a 串哈希 + 在 a1+64→+312 数组（计数 +324）内按 632B 步长线性匹配 静态库按名哈希查找（632B 记录） |
| 0x140A55080 | 业务 类名证据「TGameItemDatabase<CInsigniaGraphicsDatabase>」 §4.26 静态资源 |
| 0x14062B340 | 业务 类名证据「TGameItemDatabase<CAIEquipmentRoleDatabase>」 §4.26 静态资源 |
| 0x140AD75A0 | 业务 类名证据「TGameItemDatabase<CTimedActivityDatabase>」 §4.26 静态资源 |
| 0x140612F40 | 业务 类名证据「TGameItemDatabase<CAbilityDatabase>」 §4.26 静态资源 |
| 0x141C070C0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x140A692F0 | 业务 类名证据「TGameItemDatabase<CNameDatabase>」 §4.26 静态资源 |
| 0x140E4CDC0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 CPeaceAvailableActionItem ->§4.31; 串 "_pInstance && \"Instance not created" |
| 0x1419D7880 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x14022B520 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi" |
| 0x14117F6B0 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 断言站点 industrial_org_ui_context.cpp:22; 类路由 NProject ->§4.25 |
| 0x14254F940 | 业务 unknown_libname_419(a1) 取对象 + +144/+136 回调挂载 + +936 旗置 bit2 + byte(a1+40)=2 资源对象绑定（+936 旗 bit2） |
| 0x1411CA200 | 业务 断言站点 tutorial.cpp:12; 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "!_HighlightTargets.IsEmpty()" |
| 0x140159390 | 业务 断言站点 gameitemdatabasehelper.h:20 ->§4.26; 类路由 CCollectionSizeTrigger ->§4.32; 类路由 COOSPopUpWindow ->§4.30 |
| 0x1410E2660 | 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 NFactions ->§4.25; 串 "_pInstance && \"Instance not created" |

#### 4.26.51 静态资源访问层函数命名空间补遗（17 函）

| VA | 语义/证据 |
|---|---|
| 0x1408A2A80 | NDefines::CDefineRegistryHelper_NInterfaceFIXED_TOOLTIP_POSITION::[0]（func_names 名） func_names 名 + 断言 defines_graphics.h:534 ×4 + 串 "Error reading \"FIXED_TO… |
| 0x140974D80 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_MIN_ST… NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_MIN_ST…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x14098AD40 | NDefines::CDefineRegistryHelper_NProjectBASIC_RESEARCH_TECHNOLO… NDefines::CDefineRegistryHelper_NProjectBASIC_RESEARCH_TECHNOLO…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1408FAF60 | NDefines::CDefineRegistryHelper_NMarketCONTRACT_ESTIMATE_AVERAG… NDefines::CDefineRegistryHelper_NMarketCONTRACT_ESTIMATE_AVERAG…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1408243F0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_SCORE_RESET_LOW… NDefines::CDefineRegistryHelper_NDiplomacyPEACE_SCORE_RESET_LOW…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x140949800 | NDefines::CDefineRegistryHelper_NNavyMAX_ANTI_AIR_REDUCTION_EFF… NDefines::CDefineRegistryHelper_NNavyMAX_ANTI_AIR_REDUCTION_EFF…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x14089DEF0 | NDefines::CDefineRegistryHelper_NIntelRAID_MIN_INTEL_FOR_WARNIN… NDefines::CDefineRegistryHelper_NIntelRAID_MIN_INTEL_FOR_WARNIN…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x140962C70 | NDefines::CDefineRegistryHelper_NNavySPOTTING_MISSION_DETECTION… NDefines::CDefineRegistryHelper_NNavySPOTTING_MISSION_DETECTION…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1407C82D0 | NDefines::CDefineRegistryHelper_NAISURRENDER_LEVEL_TO_NOT_SEND_… NDefines::CDefineRegistryHelper_NAISURRENDER_LEVEL_TO_NOT_SEND_…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x14098F310 | NDefines::CDefineRegistryHelper_NProjectRECRUIT_SCIENTIST_ONE_T… NDefines::CDefineRegistryHelper_NProjectRECRUIT_SCIENTIST_ONE_T…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1407A3EE0 | NDefines::CDefineRegistryHelper_NAIMIN_CONVOY_EFFICIENCY_TO_STA… NDefines::CDefineRegistryHelper_NAIMIN_CONVOY_EFFICIENCY_TO_STA…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1408044C0 | NDefines::CDefineRegistryHelper_NCountryMAX_INTELLIGENCE_DATA_D… NDefines::CDefineRegistryHelper_NCountryMAX_INTELLIGENCE_DATA_D…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1407E7DE0 | NDefines::CDefineRegistryHelper_NAirMANPOWER_LOSS_RATIO_PLANE_S… NDefines::CDefineRegistryHelper_NAirMANPOWER_LOSS_RATIO_PLANE_S…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x1407808C0 | NDefines::CDefineRegistryHelper_NAIDIVISION_SUPPLY_RATIO_TO_MOT… NDefines::CDefineRegistryHelper_NAIDIVISION_SUPPLY_RATIO_TO_MOT…：lua 表读取+最大/最小钳位（STR 'is not… |
| 0x140937440 | NDefines::CDefineRegistryHelper_NNavyBASE_SPOTTING_FROM_NAVY NDefines::CDefineRegistryHelper_NNavyBASE_SPOTTING_FROM_NAVY：lua 表读取+最大/最小钳位（STR 'is not a lua t… |
| 0x1409A3810 | NDefines::CDefineRegistryHelper_NSupplyALERT_LOW_SUPPLY_LEVEL NDefines::CDefineRegistryHelper_NSupplyALERT_LOW_SUPPLY_LEVEL：lua 表读取+最大/最小钳位（STR 'is not a lua… |
| 0x140755840 | NDefines::CDefineRegistryHelper_NAIAIFC_UNIT_RATIO_BASE NDefines::CDefineRegistryHelper_NAIAIFC_UNIT_RATIO_BASE：lua 表读取+最大/最小钳位（STR 'is not a lua table'/'cla… |

#### 4.26.52 静态资源访问层函数补遗（33 函）

| VA | 语义/证据 |
|---|---|
| 0x140C0C2A0 | 业务 命名数据库物品构造：名称串 + 1×CUnitAdjuster + 16×CModifier（步长 192）+ 4×CGameDate vtable CUnitAdjuster(a1+584)/CModifier×16(a1+624..3696)/CGameDate×4(a1+3696..3736)；断言 … |
| 0x142249940 | 业务 ".csv" 串 + callee @virtualfilesystem.cpp:417 + @pdx_localize.cpp:884（loc CSV 装载） |
| 0x140AB9950 | - 业务 脚本 .txt 文件数据库装载（遍历目录条目逐文件解析，gamestate 访问） sub_1424DC380(a2, &v44, ".txt", 0, 0) 构造 .txt 路径；64 字节步长遍历 v44..v10；gamestate.h 断言 `_ThreadForbidCount == 0`；o… |
| 0x1409CCCA0 | - 业务 脚本 .txt 数据库装载（与 sub_140AB9950 同族：目录遍历 + 逐条目解析） sub_1424DC380(a2, &v44, ".txt", 0, 0)；`SHIDWORD(v45) << 6` 64 字节步长；off_143085170 单例 + Init_thread 守卫；调 su… |
| 0x1410A47F0 | - 业务 defines 表访问器（在 robin_hood defines 映射上查找/提取，空表短路） qword_143336A30 = defines 映射（同量被 "RADAR_LEVEL_INTEL_FACTOR" + "Warning for define \"NIntel..." 使用）；`_pE… |
| 0x14065B630 | 业务 调用图 h1mod:gameitemdatabase.h [h1mod:gameitemdatabase.h×1,h2mod:gameitemdatabase.h×1] |
| 0x140FC9F80 | 业务 调用图 h1mod:gameitemdatabase.h [h1mod:gameitemdatabase.h×1,h2mod:gameitemdatabasehelper.h×1] |
| 0x141AF2B20 | 业务 调用图 h1mod:gameitemdatabase.h [h1mod:gameitemdatabase.h×1,h1mod:gameitemdatabasehelper.h×1] |
| 0x142444950 | 业务 反向调用图 1/2 调用者投 §4.26 |
| 0x14014EF80 | 业务 TGameItemDatabase 模板实例<NFactions> |
| 0x14014EEB0 | 业务 TGameItemDatabase 模板实例<NFactions> |
| 0x14014F530 | 业务 TGameItemDatabase 模板实例<CFrontEndBackgroundDatabase> |
| 0x14014F600 | 业务 TGameItemDatabase 模板实例<NAiNavalGoals> |
| 0x14014FBB0 | 业务 TGameItemDatabase 模板实例<NDoctrines> |
| 0x1403BAEF0 | 业务 反调用图传播 2.0 权重锚点投 §4.26（top 占比 0.50） |
| 0x14014FC80 | 业务 TGameItemDatabase 模板实例<NDoctrines> |
| 0x140D18000 | 业务 类名 CPdxHybridInlineBufferAllocator,CPdxHybridInlineBufferAllocator1,CTimedOpinionModifier → §4.26（投票 1） |
| 0x140527550 | 业务 类名 CBAC0,CBAC02,CPdxHybridInlineBufferAllocator → §4.26（投票 1） |
| 0x14014FEA0 | 业务 TGameItemDatabase 模板实例<NIndustrialOrganisation> |
| 0x140150160 | 业务 TGameItemDatabase 模板实例<COperationPhasesDatabase> |
| 0x1401A7EA0 | 业务 反调用图传播 2.5 权重锚点投 §4.26（top 占比 0.60） |
| 0x140ADFB70 | 业务 反向调用图 1/2 调用者投 §4.26 |
| 0x1409CB180 | 业务 反调用图传播 1.0 权重锚点投 §4.26（top 占比 1.00） |
| 0x1401A7F40 | 业务 反调用图传播 3.2 权重锚点投 §4.26（top 占比 0.84） |
| 0x140151700 | 业务 反调用图传播 1.0 权重锚点投 §4.26（top 占比 1.00） |
| 0x140A86520 | 业务 反调用图传播 2.0 权重锚点投 §4.26（top 占比 0.50） |
| 0x14014CE30 | 业务 反调用图传播 2.8 权重锚点投 §4.26（top 占比 0.88） |
| 0x140A8BD80 | 业务 反向调用图 1/2 调用者投 §4.26; 唯一被调用者在书内 §4.1 |
| 0x1421E0010 | 业务 反向调用图 3/5 调用者投 §4.26 |
| 0x1406C1850 | 业务 反调用图传播 1.0 权重锚点投 §4.26（top 占比 1.00） |
| 0x1425071D0 | 业务 反向调用图 1/2 调用者投 §4.26 |
| 0x1409C0150 | 业务 反向调用图 1/2 调用者投 §4.26; 唯一被调用者在书内 §4.1 |
| 0x140ADECF0 | 业务 反向调用图 1/2 调用者投 §4.26; 唯一被调用者在书内 §4.1 |

#### 4.26.53 常量串 getter 结构定案（454 函）

| VA | 语义/证据 |
|---|---|
| 0x140740C80 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_NAVY_REGION_COLOR_WITH_MISSION_AND_TASKFORCES_IN_REGION"（高置信） |
| 0x140740990 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_DIPLOMACY_ON_INTEL_LEDGER"（高置信） |
| 0x1407409F0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_STRATEGIC_REGIONS"（高置信） |
| 0x1407409C0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_PEACE_CONFERENCE"（高置信） |
| 0x140740AA0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_DIPLOMACY_ON_INTEL_LEDGER"（高置信） |
| 0x140741510 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_BOTTLENECK_MAXLEVEL"（高置信） |
| 0x1407409B0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_INTEL_LEDGER"（高置信） |
| 0x140740A00 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_SUPPLY_AREA"（高置信） |
| 0x140741D00 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_MAX_VICTORY_POINTS_FOR_PERCENT"（高置信） |
| 0x1407409D0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_RESISTANCE"（高置信） |
| 0x140740B60 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_DIPLOMACY_ON_INTEL_LEDGER"（高置信） |
| 0x140740DD0 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_COARSE_COUNTRY_GROUPING_DISTANCE_STRATEGIC"（高置信） |
| 0x140740FE0 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_MISSION_TASK_FORCES_GROUP_BY_ALLEGIANCE_CUTOFF"（高置信） |
| 0x140740980 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_DIPLOMACY"（高置信） |
| 0x1407409A0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_FACTIONS"（高置信） |
| 0x140740970 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_COUNTRY"（高置信） |
| 0x140740A10 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_TERRAIN"（高置信） |
| 0x140740B00 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_STRATEGIC_REGIONS"（高置信） |
| 0x140740AD0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_PEACE_CONFERENCE"（高置信） |
| 0x140741360 | 常量串 getter: 返回常量串 "NGraphics::RAID_MAP_ICON_MAX_DRAW_DISTANCE_IN_RAID_MAP_MODE"（高置信） |
| 0x140741520 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_CONSTRUCTION"（高置信） |
| 0x1407409E0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_STATE"（高置信） |
| 0x140740A60 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_ONE_COLOR_FOR_PEACE_CONFERENCE"（高置信） |
| 0x140740C90 | 常量串 getter: 返回常量串 "NGraphics::INTEL_NETWORK_VALID_COUNTRY_TARGET_STRIPE_COLOR"（高置信） |
| 0x140740960 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_ACTIVATE_FOR_PEACE_CONFERENCE"（高置信） |
| 0x140741500 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_BOTTLENECK"（高置信） |
| 0x140741540 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_ONCOOLDOWN"（高置信） |
| 0x140740B80 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_PEACE_CONFERENCE_A"（高置信） |
| 0x140740B90 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_PEACE_CONFERENCE_B"（高置信） |
| 0x1407415F0 | 常量串 getter: 返回常量串 "NGraphics::RESISTANCE_MAP_ICON_MODIFIERS_DISTANCE_CUTOFF"（高置信） |
| 0x140741B80 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_REGIONAL_BAD_EFFICIENCY_THRESHOLD"（高置信） |
| 0x140740380 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_ADJACENCY_RULE_AREA_A"（高置信） |
| 0x140740390 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_ADJACENCY_RULE_AREA_B"（高置信） |
| 0x1407403A0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_ADJACENCY_RULE_AREA_G"（高置信） |
| 0x1407403B0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_ADJACENCY_RULE_AREA_R"（高置信） |
| 0x140740AC0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_INTEL_LEDGER"（高置信） |
| 0x140740BC0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_STRATEGIC_REGIONS"（高置信） |
| 0x1407414B0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_CONSTRUCTION_INVALID"（高置信） |
| 0x140740B10 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_SUPPLY_AREA"（高置信） |
| 0x140740C70 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_NAVY_REGION_COLOR_WITH_MISSION"（高置信） |
| 0x140741070 | 常量串 getter: 返回常量串 "NGraphics::OCCUPATION_RESISTANCE_NON_INITIALIZED_COLOR"（高置信） |
| 0x140741530 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_DAMAGED"（高置信） |
| 0x140740AE0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_RESISTANCE"（高置信） |
| 0x140740DC0 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_COARSE_COUNTRY_GROUPING_DISTANCE"（高置信） |
| 0x1407414C0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_CONSTRUCTION_VALID"（高置信） |
| 0x1407419D0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_TO_CONSUMERS_MAP_ARROW_TRANSPARENCY"（高置信） |
| 0x1407405D0 | 常量串 getter: 返回常量串 "NGraphics::CONSTRUCTION_CONVERSION_IN_PROGRESS_COLOR"（高置信） |
| 0x140740A20 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_COUNTRY_CENTER_THICKNESS"（高置信） |
| 0x140740A90 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_DIPLOMACY"（高置信） |
| 0x140740F20 | 常量串 getter: 返回常量串 "NGraphics::MOVE_ORDERS_MOUSE_INTERSECT_DISTANCE_MULT"（高置信） |
| 0x1407410F0 | 常量串 getter: 返回常量串 "NGraphics::PEACE_CONFERENCE_MAP_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x140741CD0 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_CAPITAL_CUTOFF_MAX"（高置信） |
| 0x1407401B0 | 常量串 getter: 返回常量串 "NGraphics::ALLIED_BATTLEPLANS_FACTION_THEATER_COLOR"（高置信） |
| 0x140740810 | 常量串 getter: 返回常量串 "NGraphics::DIVISION_NAMES_GROUP_MAX_TOOLTIP_ENTRIES"（高置信） |
| 0x140740AB0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_FACTIONS"（高置信） |
| 0x140740BD0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_SUPPLY_AREA_A"（高置信） |
| 0x140740BE0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_SUPPLY_AREA_B"（高置信） |
| 0x140740C20 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_CIVILIAN_ICON_REGION_CUTOFF"（高置信） |
| 0x140741560 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_MEDIUM_LEVEL_THRESHOLD"（高置信） |
| 0x140741800 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_NAVY_COLOR_NEUTRAL_HIGHLIGHTED"（高置信） |
| 0x140741820 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_NAVY_COLOR_ON_HOLD_HIGHLIGHTED"（高置信） |
| 0x140741840 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_REGION_COLOR_NAVAL_HEADQUARTER"（高置信） |
| 0x140741A90 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_BAD_EFFICIENCY_HOTSPOT_COLOR"（高置信） |
| 0x140740170 | 常量串 getter: 返回常量串 "NGraphics::ACCLIMATIZATION_CAMO_SHOW_WHEN_IN_STATE"（高置信） |
| 0x1407402F0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_A"（高置信） |
| 0x140740300 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_B"（高置信） |
| 0x140740310 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_G"（高置信） |
| 0x140740320 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_R"（高置信） |
| 0x1407408C0 | 常量串 getter: 返回常量串 "NGraphics::FACTION_PING_MAP_ALREADY_ASSIGNED_COLOR"（高置信） |
| 0x140740A80 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_COUNTRY"（高置信） |
| 0x140740B30 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_COUNTRY_HIGH"（高置信） |
| 0x140740B70 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_INTEL_LEDGER"（高置信） |
| 0x140740C30 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_CIVILIAN_ICON_STATE_CUTOFF"（高置信） |
| 0x140740CA0 | 常量串 getter: 返回常量串 "NGraphics::INTEL_NETWORK_VALID_TARGET_STRIPE_COLOR"（高置信） |
| 0x1407412C0 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_BALLISTIC_MAX_SEGMENT_LENGTH"（高置信） |
| 0x140741460 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_GUN_ASSIGNMENTS_MAP_MODE_COLORS"（高置信） |
| 0x140741570 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_THICK_LEVEL_THRESHOLD"（高置信） |
| 0x140741640 | 常量串 getter: 返回常量串 "NGraphics::ROOT_FRONT_MAX_INTERSECTION_TESTS_FRONT"（高置信） |
| 0x140741650 | 常量串 getter: 返回常量串 "NGraphics::ROOT_FRONT_MAX_INTERSECTION_TESTS_ORDER"（高置信） |
| 0x1407417A0 | 常量串 getter: 返回常量串 "NGraphics::STATE_CONSTRUCTION_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x1407403C0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_BUILDING_AREA_A"（高置信） |
| 0x1407403D0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_BUILDING_AREA_B"（高置信） |
| 0x1407403E0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_BUILDING_AREA_G"（高置信） |
| 0x1407403F0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_BUILDING_AREA_R"（高置信） |
| 0x140740A50 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_FIELD_COUNTRY_REFRESH"（高置信） |
| 0x140740B40 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_COUNTRY_LOW"（高置信） |
| 0x140740E30 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_STRATEGIC_GROUP_CAM_DISTANCE"（高置信） |
| 0x140741210 | 常量串 getter: 返回常量串 "NGraphics::PROV_CONSTRUCTION_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x140741310 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_NAVAL_SHARP_TURN_SMOOTHNESS"（高置信） |
| 0x140741580 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_THIN_LEVEL_THRESHOLD"（高置信） |
| 0x140741A00 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_UNIT_COUNTER_VERY_LOW_THRESHOLD"（高置信） |
| 0x140741AA0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_BAD_EFFICIENCY_ROUTE_COLOR"（高置信） |
| 0x140741AF0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_INTERNATIONAL_MARKET_COLOR"（高置信） |
| 0x140741D10 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_TEXT_CUTOFF_MAX"（高置信） |
| 0x140741D20 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_TEXT_CUTOFF_MIN"（高置信） |
| 0x140740230 | 常量串 getter: 返回常量串 "NGraphics::ARMY_GROUP_DEFENSIVE_LINE_BUTTON_SIZE"（高置信） |
| 0x1407407C0 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_INTERPOLATION_SPEED"（高置信） |
| 0x140740AF0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OUTLINE_CUTOFF_STATE"（高置信） |
| 0x140740BA0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_RESISTANCE"（高置信） |
| 0x140741050 | 常量串 getter: 返回常量串 "NGraphics::OCCUPATION_COMPLIANCE_MAP_MODE_COLORS"（高置信） |
| 0x140741060 | 常量串 getter: 返回常量串 "NGraphics::OCCUPATION_RESISTANCE_MAP_MODE_COLORS"（高置信） |
| 0x140741270 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_SLOPE_SOURCE_STEEPNESS"（高置信） |
| 0x140741290 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_SLOPE_TARGET_STEEPNESS"（高置信） |
| 0x1407412E0 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_LAND_SHARP_TURN_SMOOTHNESS"（高置信） |
| 0x140741380 | 常量串 getter: 返回常量串 "NGraphics::RAID_SOURCE_MAP_STRIPES_HOVERED_COLOR"（高置信） |
| 0x140741830 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_NAVY_NO_TASKFORCES_ASSIGNED"（高置信） |
| 0x140741B70 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_PRODUCTION_TRANSFER_COLOR"（高置信） |
| 0x140741CE0 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_DOT_CUTOFF_MAX"（高置信） |
| 0x140741CF0 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_DOT_CUTOFF_MIN"（高置信） |
| 0x140740480 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_SUPPLY_AREA_A"（高置信） |
| 0x140740490 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_SUPPLY_AREA_B"（高置信） |
| 0x1407404A0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_SUPPLY_AREA_G"（高置信） |
| 0x1407404B0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_SUPPLY_AREA_R"（高置信） |
| 0x1407406E0 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_UI_COLOR_BRIGHTNESS_MODIFIER"（高置信） |
| 0x140740700 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_UI_COLOR_SATURATION_MODIFIER"（高置信） |
| 0x140740920 | 常量串 getter: 返回常量串 "NGraphics::FLOWING_RIVER_SUPPLY_MAP_ARROW_COLOR"（高置信） |
| 0x140740940 | 常量串 getter: 返回常量串 "NGraphics::FRONTS_MOUSE_INTERSECT_DISTANCE_MULT"（高置信） |
| 0x140740B50 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_DIPLOMACY"（高置信） |
| 0x140740C60 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_NAVAL_FORT_LEVEL_COLORS"（高置信） |
| 0x140740DF0 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_GROUP_SPLIT_SELECTED_LIMIT"（高置信） |
| 0x140741090 | 常量串 getter: 返回常量串 "NGraphics::ORDERS_MOUSE_INTERSECT_DISTANCE_MULT"（高置信） |
| 0x1407414A0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_CONSTRUCTION"（高置信） |
| 0x140741AB0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_BAD_EFFICIENCY_THRESHOLD"（高置信） |
| 0x140741B60 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_NUM_CONVOYS_SCALE_FACTOR"（高置信） |
| 0x1407402B0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_EDGE_A"（高置信） |
| 0x1407402C0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_EDGE_B"（高置信） |
| 0x1407402D0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_EDGE_G"（高置信） |
| 0x1407402E0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_BORDER_CONFLICT_EDGE_R"（高置信） |
| 0x140740730 | 常量串 getter: 返回常量串 "NGraphics::CRYPTOLOGY_MAP_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x140740A30 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_FIELD_COUNTRY_HIGH"（高置信） |
| 0x140740A70 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_OPTIMIZATION_RANGE"（高置信） |
| 0x140740C10 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_ARMY_FORT_LEVEL_COLORS"（高置信） |
| 0x140740F60 | 常量串 getter: 返回常量串 "NGraphics::NATIONAL_FOCUS_SHINE_DISTANCE_SCALE"（高置信） |
| 0x140740FD0 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_MISSION_ICONS_DISTANCE_CUTOFF"（高置信） |
| 0x1407414F0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED"（高置信） |
| 0x1407415E0 | 常量串 getter: 返回常量串 "NGraphics::RESISTANCE_MAP_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x140741900 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_CONSUMER_ARROW_HEIGHT_TO_LEN"（高置信） |
| 0x1407419C0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_TO_CONSUMERS_MAP_ARROW_COLOR"（高置信） |
| 0x140741B00 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_INTERSECT_DISTANCE_MULT"（高置信） |
| 0x140741B10 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_LEND_LEASE_EXPORT_COLOR"（高置信） |
| 0x140741B20 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_LEND_LEASE_IMPORT_COLOR"（高置信） |
| 0x140741BB0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_SUPPLIES_TRANSFER_COLOR"（高置信） |
| 0x140740520 | 常量串 getter: 返回常量串 "NGraphics::CAMERA_OUTSIDE_MAP_DISTANCE_BOTTOM"（高置信） |
| 0x140740780 | 常量串 getter: 返回常量串 "NGraphics::DEFAULT_NUDGE_FLOATING_HARBOR_DIST"（高置信） |
| 0x140740900 | 常量串 getter: 返回常量串 "NGraphics::FACTION_PING_MAP_NONE_SELECT_COLOR"（高置信） |
| 0x140740910 | 常量串 getter: 返回常量串 "NGraphics::FACTION_PING_MAP_UNAVAILABLE_COLOR"（高置信） |
| 0x140740A40 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_FIELD_COUNTRY_LOW"（高置信） |
| 0x140740E00 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_STATE_GROUP_CAM_DISTANCE"（高置信） |
| 0x140740FB0 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_MINES_COUNT_TO_VISUAL_ASPECT"（高置信） |
| 0x1407411D0 | 常量串 getter: 返回常量串 "NGraphics::PROVINCE_ANIM_TEXT_DISTANCE_CUTOFF"（高置信） |
| 0x140741260 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_SLOPE_SOURCE_LENGTH"（高置信） |
| 0x140741280 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_SLOPE_TARGET_LENGTH"（高置信） |
| 0x140741550 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_ONCOOLDOWN"（高置信） |
| 0x1407419F0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_UNIT_COUNTER_SHOW_THRESHOLD"（高置信） |
| 0x140741C00 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_INVALID_FOR_ASSIGNMENT_COLOR"（高置信） |
| 0x140740400 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_PROVINCE_A"（高置信） |
| 0x140740410 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_PROVINCE_B"（高置信） |
| 0x140740420 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_PROVINCE_G"（高置信） |
| 0x140740430 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_PROVINCE_R"（高置信） |
| 0x1407404C0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_TUTORIAL_HIGHLIGHT_A"（高置信） |
| 0x1407404D0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_TUTORIAL_HIGHLIGHT_B"（高置信） |
| 0x1407404E0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_TUTORIAL_HIGHLIGHT_G"（高置信） |
| 0x1407404F0 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_TUTORIAL_HIGHLIGHT_R"（高置信） |
| 0x140740620 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_COLOR_BRIGHTNESS_MODIFIER"（高置信） |
| 0x140740640 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_COLOR_SATURATION_MODIFIER"（高置信） |
| 0x140740770 | 常量串 getter: 返回常量串 "NGraphics::DECISION_MAP_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x1407407D0 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_SCREEN_AREA_MAX"（高置信） |
| 0x1407407E0 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_SCREEN_AREA_MIN"（高置信） |
| 0x140740D90 | 常量串 getter: 返回常量串 "NGraphics::MAP_BUILDINGS_DESTROYED_DEAD_ZONE"（高置信） |
| 0x140740F30 | 常量串 getter: 返回常量串 "NGraphics::NAMES_GROUP_MAX_NAME_LIST_ENTRIES"（高置信） |
| 0x140741250 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_MAX_SEGMENT_LENGTH"（高置信） |
| 0x1407412B0 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_BALLISTIC_MAX_SEGMENTS"（高置信） |
| 0x140741750 | 常量串 getter: 返回常量串 "NGraphics::SNAPPED_OFF_FRONT_SMOOTHEN_PASSES"（高置信） |
| 0x1407419E0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_UNIT_COUNTER_LOW_THRESHOLD"（高置信） |
| 0x140741B90 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_RESOURCE_EXPORT_COLOR"（高置信） |
| 0x140741BA0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_RESOURCE_IMPORT_COLOR"（高置信） |
| 0x140740660 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_MEDIUM_TEX_MAX_SIZE"（高置信） |
| 0x140740760 | 常量串 getter: 返回常量串 "NGraphics::DECISION_MAP_ICON_DEPTH_PRIORITY"（高置信） |
| 0x1407408D0 | 常量串 getter: 返回常量串 "NGraphics::FACTION_PING_MAP_AVAILABLE_COLOR"（高置信） |
| 0x140740BB0 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_THICKNESS_STATE"（高置信） |
| 0x140740FA0 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_MINES_CLUMP_NEAR_TERRITORY"（高置信） |
| 0x140741010 | 常量串 getter: 返回常量串 "NGraphics::NODE_FLOW_IN_CURRENT_RANGE_COLOR"（高置信） |
| 0x140741180 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_PER_PROVINCE_MAX_SNOW"（高置信） |
| 0x140741190 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_PER_PROVINCE_MIN_SNOW"（高置信） |
| 0x1407418F0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_CONSUMER_ARROW_HEIGHT_MAX"（高置信） |
| 0x140740220 | 常量串 getter: 返回常量串 "NGraphics::ARMY_DEFENSIVE_LINE_BUTTON_SIZE"（高置信） |
| 0x140740530 | 常量串 getter: 返回常量串 "NGraphics::CAMERA_OUTSIDE_MAP_DISTANCE_TOP"（高置信） |
| 0x140740560 | 常量串 getter: 返回常量串 "NGraphics::CAMERA_ZOOM_SPEED_DISTANCE_MULT"（高置信） |
| 0x140740690 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_SMALL_TEX_MAX_SIZE"（高置信） |
| 0x1407407A0 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_DRAW_DISTANCE"（高置信） |
| 0x1407407B0 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_GROUND_OFFSET"（高置信） |
| 0x140740D80 | 常量串 getter: 返回常量串 "NGraphics::MAP_BUILDINGS_DAMAGED_THRESHOLD"（高置信） |
| 0x140740EA0 | 常量串 getter: 返回常量串 "NGraphics::MINIMUM_PROVINCE_SIZE_IN_PIXELS"（高置信） |
| 0x140741160 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_FEATHER_MAX_DISTANCE"（高置信） |
| 0x140741170 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_FEATHER_MIN_DISTANCE"（高置信） |
| 0x1407412A0 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_BALLISTIC_MAX_HEIGHT"（高置信） |
| 0x140741340 | 常量串 getter: 返回常量串 "NGraphics::RAID_MAP_ICON_DRAW_DISTANCE_MAX"（高置信） |
| 0x140741350 | 常量串 getter: 返回常量串 "NGraphics::RAID_MAP_ICON_DRAW_DISTANCE_MIN"（高置信） |
| 0x140741490 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_INTERSECT_DISTANCE_MULT"（高置信） |
| 0x1407414D0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_DAMAGED"（高置信） |
| 0x1407414E0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_MAP_ARROW_COLOR_DEFAULT"（高置信） |
| 0x140741920 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_DISCONNECTED_CUTOFF"（高置信） |
| 0x140741AC0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_CONVOY_ROUTE_OFFSET"（高置信） |
| 0x140740180 | 常量串 getter: 返回常量串 "NGraphics::ADJACENCY_RULE_DISTANCE_CUTOFF"（高置信） |
| 0x140740330 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_CUSTOM_HIGHLIGHTS"（高置信） |
| 0x140740440 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_STATE_A"（高置信） |
| 0x140740450 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_STATE_B"（高置信） |
| 0x140740460 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_STATE_G"（高置信） |
| 0x140740470 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_SELECTION_STATE_R"（高置信） |
| 0x1407405B0 | 常量串 getter: 返回常量串 "NGraphics::COMMANDGROUP_PRESET_COLORS_HSV"（高置信） |
| 0x1407405E0 | 常量串 getter: 返回常量串 "NGraphics::COUNTER_MODE_ALLEGIANCE_ALLIED"（高置信） |
| 0x140740650 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_MEDIUM_TEX_HEIGHT"（高置信） |
| 0x140740DA0 | 常量串 getter: 返回常量串 "NGraphics::MAP_BUILDINGS_DESTROYED_STATUS"（高置信） |
| 0x140740F70 | 常量串 getter: 返回常量串 "NGraphics::NAVALBASE_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x140741100 | 常量串 getter: 返回常量串 "NGraphics::POLITICAL_GRID_SMALL_BOX_LIMIT"（高置信） |
| 0x140741330 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_NAVAL_USE_MIDPOINTS"（高置信） |
| 0x1407413E0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_GAP_LARGE_WIDTH"（高置信） |
| 0x1407405C0 | 常量串 getter: 返回常量串 "NGraphics::CONSTRUCTION_CONVERSION_COLOR"（高置信） |
| 0x1407405F0 | 常量串 getter: 返回常量串 "NGraphics::COUNTER_MODE_ALLEGIANCE_ENEMY"（高置信） |
| 0x140740600 | 常量串 getter: 返回常量串 "NGraphics::COUNTER_MODE_ALLEGIANCE_OTHER"（高置信） |
| 0x140740670 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_MEDIUM_TEX_WIDTH"（高置信） |
| 0x140740680 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_SMALL_TEX_HEIGHT"（高置信） |
| 0x1407406F0 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_UI_COLOR_HUE_MODIFIER"（高置信） |
| 0x140740B20 | 常量串 getter: 返回常量串 "NGraphics::GRADIENT_BORDERS_REFRESH_FREQ"（高置信） |
| 0x140740C00 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_AIR_REGION_COLOR"（高置信） |
| 0x140740DB0 | 常量串 getter: 返回常量串 "NGraphics::MAP_BUILDINGS_SHRINK_DISTANCE"（高置信） |
| 0x140740E20 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_STRATEGIC_AREA_HUGE"（高置信） |
| 0x140741020 | 常量串 getter: 返回常量串 "NGraphics::NODE_FLOW_IN_FULL_RANGE_COLOR"（高置信） |
| 0x140741030 | 常量串 getter: 返回常量串 "NGraphics::NODE_FLOW_IN_HALF_RANGE_COLOR"（高置信） |
| 0x140741300 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_LAND_USE_MIDPOINTS"（高置信） |
| 0x140741320 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_NAVAL_SUBDIVISIONS"（高置信） |
| 0x140741370 | 常量串 getter: 返回常量串 "NGraphics::RAID_SOURCE_MAP_STRIPES_COLOR"（高置信） |
| 0x140741600 | 常量串 getter: 返回常量串 "NGraphics::RESOURCE_MAP_ICON_TEXT_CUTOFF"（高置信） |
| 0x140741AD0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_CONVOY_SLEEP_TIME"（高置信） |
| 0x140741C30 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_LINE_NON_ASSIGNED_COLOR"（高置信） |
| 0x140740160 | 常量串 getter: 返回常量串 "NGraphics::ACCLIMATIZATION_CAMO_SHOW_AT"（高置信） |
| 0x140740190 | 常量串 getter: 返回常量串 "NGraphics::AIRBASE_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x140740280 | 常量串 getter: 返回常量串 "NGraphics::ARROW_PARADROP_HEIGHT_TO_LEN"（高置信） |
| 0x140740340 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_DEMILITARIZED_A"（高置信） |
| 0x140740350 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_DEMILITARIZED_B"（高置信） |
| 0x140740360 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_DEMILITARIZED_G"（高置信） |
| 0x140740370 | 常量串 getter: 返回常量串 "NGraphics::BORDER_COLOR_DEMILITARIZED_R"（高置信） |
| 0x140740610 | 常量串 getter: 返回常量串 "NGraphics::COUNTER_MODE_ALLEGIANCE_OURS"（高置信） |
| 0x1407406A0 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_SMALL_TEX_WIDTH"（高置信） |
| 0x140740DE0 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_GROUP_CAM_DISTANCE"（高置信） |
| 0x140740F80 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_COMBAT_DISTANCE_CUTOFF"（高置信） |
| 0x1407412F0 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_LAND_SUBDIVISIONS"（高置信） |
| 0x140741630 | 常量串 getter: 返回常量串 "NGraphics::RIVER_SUPPLY_MAP_ARROW_COLOR"（高置信） |
| 0x140741760 | 常量串 getter: 返回常量串 "NGraphics::SNAPPED_OFF_FRONT_SMOOTHNESS"（高置信） |
| 0x1407417F0 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_NAVY_COLOR_NEUTRAL"（高置信） |
| 0x140741810 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_NAVY_COLOR_ON_HOLD"（高置信） |
| 0x140741850 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_REGION_ZOOM_HEIGHT"（高置信） |
| 0x140741CC0 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_MAP_ICON_AFTER"（高置信） |
| 0x140741D50 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_DISTANCE_FADE_LENGTH"（高置信） |
| 0x140741D70 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_PLAYBACK_RATE_CUTOFF"（高置信） |
| 0x140741D80 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_PLAYBACK_RATE_LENGTH"（高置信） |
| 0x140740240 | 常量串 getter: 返回常量串 "NGraphics::ARROW_EXT_TEXT_POINTS_LIMIT"（高置信） |
| 0x140740250 | 常量串 getter: 返回常量串 "NGraphics::ARROW_MIN_TEXT_POINTS_LIMIT"（高置信） |
| 0x1407405A0 | 常量串 getter: 返回常量串 "NGraphics::CITY_SPRAWL_SHRINK_DISTANCE"（高置信） |
| 0x140740790 | 常量串 getter: 返回常量串 "NGraphics::DEFENSIVE_PING_CIRCLE_COLOR"（高置信） |
| 0x140740CC0 | 常量串 getter: 返回常量串 "NGraphics::LAND_COMBAT_DISTANCE_CUTOFF"（高置信） |
| 0x140740E50 | 常量串 getter: 返回常量串 "NGraphics::MAX_MESHES_LOADED_PER_FRAME"（高置信） |
| 0x140740E80 | 常量串 getter: 返回常量串 "NGraphics::MESH_POPUP_SCALE_DOWN_SPEED"（高置信） |
| 0x140740F50 | 常量串 getter: 返回常量串 "NGraphics::NATIONAL_FOCUS_PULSE_RANDOM"（高置信） |
| 0x140740FC0 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_MINES_DISTANCE_CUTOFF"（高置信） |
| 0x140741080 | 常量串 getter: 返回常量串 "NGraphics::OFFENSIVE_PING_CIRCLE_COLOR"（高置信） |
| 0x1407410B0 | 常量串 getter: 返回常量串 "NGraphics::ORDER_FRONT_SMOOTHEN_PASSES"（高置信） |
| 0x1407411C0 | 常量串 getter: 返回常量串 "NGraphics::PRIDE_OF_THE_FLEET_MODULATE"（高置信） |
| 0x140741200 | 常量串 getter: 返回常量串 "NGraphics::PROVINCE_NAME_DRAW_DISTANCE"（高置信） |
| 0x140741240 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_MAX_SEGMENTS"（高置信） |
| 0x1407413A0 | 常量串 getter: 返回常量串 "NGraphics::RAID_UNIT_ENTITY_BASE_SCALE"（高置信） |
| 0x140741400 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_LARGE_ENTITY"（高置信） |
| 0x140741450 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_CAMERA_CUTOFF_SPEED"（高置信） |
| 0x1407416B0 | 常量串 getter: 返回常量串 "NGraphics::SETUP_SPIRIT_GRID_BOX_LIMIT"（高置信） |
| 0x1407416F0 | 常量串 getter: 返回常量串 "NGraphics::SHIP_IN_MISSION_TARGET_SIZE"（高置信） |
| 0x140741700 | 常量串 getter: 返回常量串 "NGraphics::SHIP_IN_MISSION_TURN_RADIUS"（高置信） |
| 0x140741720 | 常量串 getter: 返回常量串 "NGraphics::SHIP_POPUP_SCALE_DOWN_SPEED"（高置信） |
| 0x1407417B0 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_AIR_COLOR_AVERAGE"（高置信） |
| 0x1407417E0 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_AIR_COLOR_NEUTRAL"（高置信） |
| 0x140741A10 | 常量串 getter: 返回常量串 "NGraphics::TEMPERATURE_MAP_MODE_COLORS"（高置信） |
| 0x140741B50 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_MAX_NUM_CONVOYS"（高置信） |
| 0x140741C80 | 常量串 getter: 返回常量串 "NGraphics::UNITS_ICONS_DISTANCE_CUTOFF"（高置信） |
| 0x140741DA0 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_ZOOM_IN_FADE_FACTOR"（高置信） |
| 0x140741DB0 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_ZOOM_IN_FADE_LENGTH"（高置信） |
| 0x140740630 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_COLOR_HUE_MODIFIER"（高置信） |
| 0x1407407F0 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_SIZE_MAX"（高置信） |
| 0x140740800 | 常量串 getter: 返回常量串 "NGraphics::DIRECTION_POINTER_SIZE_MIN"（高置信） |
| 0x140740CB0 | 常量串 getter: 返回常量串 "NGraphics::LAND_COMBAT_BALANCED_COLOR"（高置信） |
| 0x1407410D0 | 常量串 getter: 返回常量串 "NGraphics::ORDER_MOVE_SMOOTHEN_PASSES"（高置信） |
| 0x140741220 | 常量串 getter: 返回常量串 "NGraphics::RADAR_ICON_DISTANCE_CUTOFF"（高置信） |
| 0x1407412D0 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_BALLISTIC_SHAPE"（高置信） |
| 0x140741410 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_LARGE_WIDTH"（高置信） |
| 0x140741670 | 常量串 getter: 返回常量串 "NGraphics::ROOT_FRONT_SMOOTHEN_PASSES"（高置信） |
| 0x1407418C0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLYFLOW_SMOOTHEN_PASSES"（高置信） |
| 0x140741940 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_NUMBERS_CUTOFF"（高置信） |
| 0x1407419B0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_SELECTED_NODE_COLOR"（高置信） |
| 0x140741A70 | 常量串 getter: 返回常量串 "NGraphics::TRADEROUTE_SMOOTHEN_PASSES"（高置信） |
| 0x140741C20 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_LINE_HIGHLIGHT_COLOR"（高置信） |
| 0x140741C90 | 常量串 getter: 返回常量串 "NGraphics::UNIT_ARROW_DISTANCE_CUTOFF"（高置信） |
| 0x140740270 | 常量串 getter: 返回常量串 "NGraphics::ARROW_PARADROP_HEIGHT_MAX"（高置信） |
| 0x1407406C0 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_TEX_MAX_SIZE"（高置信） |
| 0x140740820 | 常量串 getter: 返回常量串 "NGraphics::DRAW_COUNTRY_NAMES_CUTOFF"（高置信） |
| 0x1407408F0 | 常量串 getter: 返回常量串 "NGraphics::FACTION_PING_MAP_GRADIENT"（高置信） |
| 0x140740CE0 | 常量串 getter: 返回常量串 "NGraphics::LAND_COMBAT_WINNING_COLOR"（高置信） |
| 0x140740E90 | 常量串 getter: 返回常量串 "NGraphics::MESH_POPUP_SCALE_UP_SPEED"（高置信） |
| 0x140740F40 | 常量串 getter: 返回常量串 "NGraphics::NATIONAL_FOCUS_PULSE_BASE"（高置信） |
| 0x140740FF0 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_UNIT_MOVEMENT_SPEED"（高置信） |
| 0x140741140 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_FEATHER_AT_MAX"（高置信） |
| 0x140741150 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_FEATHER_AT_MIN"（高置信） |
| 0x1407411A0 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_TOTAL_MAX_SNOW"（高置信） |
| 0x1407411B0 | 常量串 getter: 返回常量串 "NGraphics::POSTEFFECT_TOTAL_MIN_SNOW"（高置信） |
| 0x1407411F0 | 常量串 getter: 返回常量串 "NGraphics::PROVINCE_BORDER_FADE_NEAR"（高置信） |
| 0x140741730 | 常量串 getter: 返回常量串 "NGraphics::SHOW_FOREIGN_SUPPLY_BELOW"（高置信） |
| 0x140741980 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_UNUSED_CUTOFF"（高置信） |
| 0x140741C10 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_LINE_ASSIGNED_COLOR"（高置信） |
| 0x140741D30 | 常量串 getter: 返回常量串 "NGraphics::VIRTUAL_BATTLEPLANS_COLOR"（高置信） |
| 0x1407401A0 | 常量串 getter: 返回常量串 "NGraphics::ALLIED_BATTLEPLANS_COLOR"（高置信） |
| 0x140740590 | 常量串 getter: 返回常量串 "NGraphics::CITY_DESTROYED_THRESHOLD"（高置信） |
| 0x140740880 | 常量串 getter: 返回常量串 "NGraphics::DRAW_SHADOWS_FADE_LENGTH"（高置信） |
| 0x1407408B0 | 常量串 getter: 返回常量串 "NGraphics::FACILITY_DISTANCE_CUTOFF"（高置信） |
| 0x140740C40 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_GRAPH_GREEN"（高置信） |
| 0x140740CD0 | 常量串 getter: 返回常量串 "NGraphics::LAND_COMBAT_LOSING_COLOR"（高置信） |
| 0x140740CF0 | 常量串 getter: 返回常量串 "NGraphics::LAND_UNIT_MOVEMENT_SPEED"（高置信） |
| 0x140740D40 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_SHADOW_DIRECTION_X"（高置信） |
| 0x140740D50 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_SHADOW_DIRECTION_Y"（高置信） |
| 0x140740D60 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_SHADOW_DIRECTION_Z"（高置信） |
| 0x1407411E0 | 常量串 getter: 返回常量串 "NGraphics::PROVINCE_BORDER_FADE_FAR"（高置信） |
| 0x1407413F0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_GAP_WIDTH"（高置信） |
| 0x1407415A0 | 常量串 getter: 返回常量串 "NGraphics::RESISTANCE_COLOR_AVERAGE"（高置信） |
| 0x1407417D0 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_AIR_COLOR_GOOD"（高置信） |
| 0x140741A20 | 常量串 getter: 返回常量串 "NGraphics::TONE_MAP_LUMINANCE_WHITE"（高置信） |
| 0x140741AE0 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_CONVOY_SPEED"（高置信） |
| 0x140741BD0 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_GRID_COLUMN_OFFSET"（高置信） |
| 0x1407406B0 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_TEX_HEIGHT"（高置信） |
| 0x140740850 | 常量串 getter: 返回常量串 "NGraphics::DRAW_MAP_OBJECTS_CUTOFF"（高置信） |
| 0x140740860 | 常量串 getter: 返回常量串 "NGraphics::DRAW_REFRACTIONS_CUTOFF"（高置信） |
| 0x140740890 | 常量串 getter: 返回常量串 "NGraphics::EMISSIVE_BLOOM_STRENGTH"（高置信） |
| 0x1407410A0 | 常量串 getter: 返回常量串 "NGraphics::ORDER_FRONT_MAX_OFFSETS"（高置信） |
| 0x140741390 | 常量串 getter: 返回常量串 "NGraphics::RAID_TARGET_ZOOM_HEIGHT"（高置信） |
| 0x1407413B0 | 常量串 getter: 返回常量串 "NGraphics::RAID_UNIT_ENTITY_OFFSET"（高置信） |
| 0x140741430 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_Y_OFFSET"（高置信） |
| 0x1407417C0 | 常量串 getter: 返回常量串 "NGraphics::STRATEGIC_AIR_COLOR_BAD"（高置信） |
| 0x1407419A0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_NAVAL_NODE_COLOR"（高置信） |
| 0x140741B30 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_LINE_OFFSET"（高置信） |
| 0x140741BE0 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_GRID_COLUMN_WIDTH"（高置信） |
| 0x140741D40 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_DISTANCE_CUTOFF"（高置信） |
| 0x140740580 | 常量串 getter: 返回常量串 "NGraphics::CITY_DAMAGED_THRESHOLD"（高置信） |
| 0x1407406D0 | 常量串 getter: 返回常量串 "NGraphics::COUNTRY_FLAG_TEX_WIDTH"（高置信） |
| 0x1407408E0 | 常量串 getter: 返回常量串 "NGraphics::FACTION_PING_MAP_COLOR"（高置信） |
| 0x140740C50 | 常量串 getter: 返回常量串 "NGraphics::INTEL_LEDGER_GRAPH_RED"（高置信） |
| 0x140740E60 | 常量串 getter: 返回常量串 "NGraphics::MAX_NUMBER_OF_TEXTURES"（高置信） |
| 0x1407410C0 | 常量串 getter: 返回常量串 "NGraphics::ORDER_FRONT_SMOOTHNESS"（高置信） |
| 0x140741120 | 常量串 getter: 返回常量串 "NGraphics::POLITICAL_PULSE_RANDOM"（高置信） |
| 0x140741790 | 常量串 getter: 返回常量串 "NGraphics::STATE_BORDER_FADE_NEAR"（高置信） |
| 0x1407418B0 | 常量串 getter: 返回常量串 "NGraphics::SUN_SPECULAR_INTENSITY"（高置信） |
| 0x140741930 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_END_CUTOFF"（高置信） |
| 0x140741990 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_LAND_NODE_COLOR"（高置信） |
| 0x140741D90 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_ZOOM_IN_CUTOFF"（高置信） |
| 0x140740540 | 常量串 getter: 返回常量串 "NGraphics::CAMERA_ZOOM_KEY_SCALE"（高置信） |
| 0x140740E70 | 常量串 getter: 返回常量串 "NGraphics::MAX_TRAIN_WAGON_COUNT"（高置信） |
| 0x140740EC0 | 常量串 getter: 返回常量串 "NGraphics::MIN_TRAIN_WAGON_COUNT"（高置信） |
| 0x1407410E0 | 常量串 getter: 返回常量串 "NGraphics::ORDER_MOVE_SMOOTHNESS"（高置信） |
| 0x140741230 | 常量串 getter: 返回常量串 "NGraphics::RAID_ARROW_AIR_HEIGHT"（高置信） |
| 0x1407413C0 | 常量串 getter: 返回常量串 "NGraphics::RAID_UNIT_ZOOM_HEIGHT"（高置信） |
| 0x1407413D0 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_ENTITY"（高置信） |
| 0x140741440 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_CAMERA_CUTOFF"（高置信） |
| 0x1407415C0 | 常量串 getter: 返回常量串 "NGraphics::RESISTANCE_COLOR_GOOD"（高置信） |
| 0x1407415D0 | 常量串 getter: 返回常量串 "NGraphics::RESISTANCE_COLOR_NONE"（高置信） |
| 0x140741680 | 常量串 getter: 返回常量串 "NGraphics::ROOT_FRONT_SMOOTHNESS"（高置信） |
| 0x1407416C0 | 常量串 getter: 返回常量串 "NGraphics::SHIPS_DISTANCE_CUTOFF"（高置信） |
| 0x1407416D0 | 常量串 getter: 返回常量串 "NGraphics::SHIP_IN_MISSION_SCALE"（高置信） |
| 0x1407416E0 | 常量串 getter: 返回常量串 "NGraphics::SHIP_IN_MISSION_SPEED"（高置信） |
| 0x140741780 | 常量串 getter: 返回常量串 "NGraphics::STATE_BORDER_FADE_FAR"（高置信） |
| 0x1407418D0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLYFLOW_SMOOTHNESS"（高置信） |
| 0x140741950 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_OK_CUTOFF"（高置信） |
| 0x140741A40 | 常量串 getter: 返回常量串 "NGraphics::TOOLTIP_DELAYED_DELAY"（高置信） |
| 0x140741A80 | 常量串 getter: 返回常量串 "NGraphics::TRADEROUTE_SMOOTHNESS"（高置信） |
| 0x140741B40 | 常量串 getter: 返回常量串 "NGraphics::TRADE_ROUTE_MAX_LINES"（高置信） |
| 0x140741C70 | 常量串 getter: 返回常量串 "NGraphics::UNITS_DISTANCE_CUTOFF"（高置信） |
| 0x140741D60 | 常量串 getter: 返回常量串 "NGraphics::WEATHER_PLAYBACK_RATE"（高置信） |
| 0x140740260 | 常量串 getter: 返回常量串 "NGraphics::ARROW_MOVEMENT_SPEED"（高置信） |
| 0x140740840 | 常量串 getter: 返回常量串 "NGraphics::DRAW_FOW_FADE_LENGTH"（高置信） |
| 0x140740BF0 | 常量串 getter: 返回常量串 "NGraphics::HDR_ADJUSTMENT_SPEED"（高置信） |
| 0x140740D70 | 常量串 getter: 返回常量串 "NGraphics::MAPICON_GROUP_PASSES"（高置信） |
| 0x140740E10 | 常量串 getter: 返回常量串 "NGraphics::MAP_ICONS_STATE_HUGE"（高置信） |
| 0x140740F90 | 常量串 getter: 返回常量串 "NGraphics::NAVAL_MINES_CLUMPING"（高置信） |
| 0x140741110 | 常量串 getter: 返回常量串 "NGraphics::POLITICAL_PULSE_BASE"（高置信） |
| 0x140741420 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_BRIDGE_WIDTH"（高置信） |
| 0x1407415B0 | 常量串 getter: 返回常量串 "NGraphics::RESISTANCE_COLOR_BAD"（高置信） |
| 0x140741690 | 常量串 getter: 返回常量串 "NGraphics::SECOND_MOON_LATITUDE"（高置信） |
| 0x140741740 | 常量串 getter: 返回常量串 "NGraphics::SHOW_ONLY_PATH_ABOVE"（高置信） |
| 0x1407418E0 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_CAPITAL_COLOR"（高置信） |
| 0x140741A30 | 常量串 getter: 返回常量串 "NGraphics::TONE_MAP_MIDDLE_GREY"（高置信） |
| 0x140741BF0 | 常量串 getter: 返回常量串 "NGraphics::TRAIT_GRID_ROW_SHIFT"（高置信） |
| 0x140741C60 | 常量串 getter: 返回常量串 "NGraphics::TUNNELBANA_TIMETABLE"（高置信） |
| 0x140741CB0 | 常量串 getter: 返回常量串 "NGraphics::VICTORY_POINT_LEVELS"（高置信） |
| 0x1407401C0 | 常量串 getter: 返回常量串 "NGraphics::AMBIENT_LIGHT_NEG_X"（高置信） |
| 0x1407401D0 | 常量串 getter: 返回常量串 "NGraphics::AMBIENT_LIGHT_NEG_Y"（高置信） |
| 0x1407401E0 | 常量串 getter: 返回常量串 "NGraphics::AMBIENT_LIGHT_NEG_Z"（高置信） |
| 0x1407401F0 | 常量串 getter: 返回常量串 "NGraphics::AMBIENT_LIGHT_POS_X"（高置信） |
| 0x140740200 | 常量串 getter: 返回常量串 "NGraphics::AMBIENT_LIGHT_POS_Y"（高置信） |
| 0x140740210 | 常量串 getter: 返回常量串 "NGraphics::AMBIENT_LIGHT_POS_Z"（高置信） |
| 0x140740570 | 常量串 getter: 返回常量串 "NGraphics::CAPITAL_ICON_CUTOFF"（高置信） |
| 0x140740870 | 常量串 getter: 返回常量串 "NGraphics::DRAW_SHADOWS_CUTOFF"（高置信） |
| 0x140741470 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_ICON_CUTOFF"（高置信） |
| 0x1407416A0 | 常量串 getter: 返回常量串 "NGraphics::SECOND_SUN_LATITUDE"（高置信） |
| 0x140740E40 | 常量串 getter: 返回常量串 "NGraphics::MAX_HDR_ADJUSTMENT"（高置信） |
| 0x140740EB0 | 常量串 getter: 返回常量串 "NGraphics::MIN_HDR_ADJUSTMENT"（高置信） |
| 0x140740ED0 | 常量串 getter: 返回常量串 "NGraphics::MOON_DIFFUSE_COLOR"（高置信） |
| 0x140741480 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_ICON_SHIFT"（高置信） |
| 0x140741710 | 常量串 getter: 返回常量串 "NGraphics::SHIP_IN_PORT_SCALE"（高置信） |
| 0x140741910 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_CUTOFF"（高置信） |
| 0x140741970 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_SWITCH"（高置信） |
| 0x140741A50 | 常量串 getter: 返回常量串 "NGraphics::TOOLTIP_HIDE_DELAY"（高置信） |
| 0x140741A60 | 常量串 getter: 返回常量串 "NGraphics::TOOLTIP_SHOW_DELAY"（高置信） |
| 0x140740550 | 常量串 getter: 返回常量串 "NGraphics::CAMERA_ZOOM_SPEED"（高置信） |
| 0x140740740 | 常量串 getter: 返回常量串 "NGraphics::CUBEMAP_INTENSITY"（高置信） |
| 0x140740750 | 常量串 getter: 返回常量串 "NGraphics::DAY_NIGHT_FEATHER"（高置信） |
| 0x140740D00 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_DIRECTION_X"（高置信） |
| 0x140740D10 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_DIRECTION_Y"（高置信） |
| 0x140740D20 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_DIRECTION_Z"（高置信） |
| 0x140740EF0 | 常量串 getter: 返回常量串 "NGraphics::MOON_HEIGHT_WATER"（高置信） |
| 0x140741040 | 常量串 getter: 返回常量串 "NGraphics::NORTH_POLE_OFFSET"（高置信） |
| 0x140741660 | 常量串 getter: 返回常量串 "NGraphics::ROOT_FRONT_OFFSET"（高置信） |
| 0x140741770 | 常量串 getter: 返回常量串 "NGraphics::SOUTH_POLE_OFFSET"（高置信） |
| 0x140741860 | 常量串 getter: 返回常量串 "NGraphics::SUN_DIFFUSE_COLOR"（高置信） |
| 0x140741960 | 常量串 getter: 返回常量串 "NGraphics::SUPPLY_ICON_SHIFT"（高置信） |
| 0x140740510 | 常量串 getter: 返回常量串 "NGraphics::BRIGHT_THRESHOLD"（高置信） |
| 0x140741130 | 常量串 getter: 返回常量串 "NGraphics::PORT_SHIP_OFFSET"（高置信） |
| 0x140741590 | 常量串 getter: 返回常量串 "NGraphics::RAILWAY_Y_OFFSET"（高置信） |
| 0x140741880 | 常量串 getter: 返回常量串 "NGraphics::SUN_HEIGHT_WATER"（高置信） |
| 0x140740830 | 常量串 getter: 返回常量串 "NGraphics::DRAW_FOW_CUTOFF"（高置信） |
| 0x140740D30 | 常量串 getter: 返回常量串 "NGraphics::LIGHT_HDR_RANGE"（高置信） |
| 0x140741610 | 常量串 getter: 返回常量串 "NGraphics::RIVER_FADE_FROM"（高置信） |
| 0x140741BC0 | 常量串 getter: 返回常量串 "NGraphics::TRAIN_MAP_SPEED"（高置信） |
| 0x140741CA0 | 常量串 getter: 返回常量串 "NGraphics::UNIT_TURN_SPEED"（高置信） |
| 0x140740F00 | 常量串 getter: 返回常量串 "NGraphics::MOON_INTENSITY"（高置信） |
| 0x140741C50 | 常量串 getter: 返回常量串 "NGraphics::TREE_FADE_NEAR"（高置信） |
| 0x140740F10 | 常量串 getter: 返回常量串 "NGraphics::MOON_LATITUDE"（高置信） |
| 0x140741000 | 常量串 getter: 返回常量串 "NGraphics::NEUTRAL_COLOR"（高置信） |
| 0x140741620 | 常量串 getter: 返回常量串 "NGraphics::RIVER_FADE_TO"（高置信） |
| 0x140741890 | 常量串 getter: 返回常量串 "NGraphics::SUN_INTENSITY"（高置信） |
| 0x140741C40 | 常量串 getter: 返回常量串 "NGraphics::TREE_FADE_FAR"（高置信） |
| 0x140740500 | 常量串 getter: 返回常量串 "NGraphics::BORDER_WIDTH"（高置信） |
| 0x140740930 | 常量串 getter: 返回常量串 "NGraphics::FRIEND_COLOR"（高置信） |
| 0x1407418A0 | 常量串 getter: 返回常量串 "NGraphics::SUN_LATITUDE"（高置信） |
| 0x140740290 | 常量串 getter: 返回常量串 "NGraphics::BLOOM_SCALE"（高置信） |
| 0x1407402A0 | 常量串 getter: 返回常量串 "NGraphics::BLOOM_WIDTH"（高置信） |
| 0x1407408A0 | 常量串 getter: 返回常量串 "NGraphics::ENEMY_COLOR"（高置信） |
| 0x140740EE0 | 常量串 getter: 返回常量串 "NGraphics::MOON_HEIGHT"（高置信） |
| 0x140740710 | 常量串 getter: 返回常量串 "NGraphics::COUP_GREEN"（高置信） |
| 0x140740950 | 常量串 getter: 返回常量串 "NGraphics::GMT_OFFSET"（高置信） |
| 0x140741870 | 常量串 getter: 返回常量串 "NGraphics::SUN_HEIGHT"（高置信） |
| 0x140740720 | 常量串 getter: 返回常量串 "NGraphics::COUP_RED"（高置信） |

#### 4.26.54 单调用转发桩结构定案（70 函）

| VA | 语义/证据 |
|---|---|
| 0x14254F8CC | 转发桩: 转发至 业务 unknown_libname_419(a1) 取对象 + +144/+136 回调挂载 + +936 旗置 bit2 + byte(a1+40)=2 资源对象绑定（+936 旗 bit2）（推定） |
| 0x140A44900 | 转发桩: 转发至 域关键词匹配 sub_1409C01A0 + 域关键词匹配（推定） |
| 0x140ADEC20 | 转发桩: 转发至 业务 反向调用图 1/2 调用者投 §4.26（推定） |
| 0x141461570 | 转发桩: 转发至 装备模块定义校验 装备模块定义校验；串 \"Assigning module '\"+\"' which is not present on type '\"，被调 lexer.cpp:381（推定） |
| 0x1422EB230 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x14015E990 | 转发桩: 转发至 CSpecializationDatabase（NProject）可重载数据库构造 vtable `TReloadableGameItemDatabase<NProject::CSpecializationDatabase>::vftable`（推定） |
| 0x141664140 | 转发桩: 转发至 业务 FNV-1a 串哈希 + 在 a1+64→+312 数组（计数 +324）内按 632B 步长线性匹配 静态库按名哈希查找（632B 记录）（推定） |
| 0x14015E7D0 | 转发桩: 转发至 业务 TGameItemDatabase 模板实例<COperationPhasesDatabase>（推定） |
| 0x14015E810 | 转发桩: 转发至 行动令牌数据库 TReloadableGameItemDatabase<COperationTokensDatabase> 析构：表项释放 + 基类 vtable 回退（推定） |
| 0x140AA27E0 | 转发桩: 转发至 CCountryScorerDatabase 可重载数据库构造 vtable `TReloadableGameItemDatabase<CCountryScorerDatabase>::vftable`（推定） |
| 0x140ACB5F0 | 转发桩: 被调者 0x140A44900 -> §4.26 (E:单调用转发(被调者入书))（推定） |
| 0x1416565D0 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 类路由 NFactions ->§4.25; 串 "_pInstance && \"Instance not created"（推定） |
| 0x14015E710 | 转发桩: 转发至 TAG别名数据库 TReloadableGameItemDatabase<CCountryTagAliasDatabase> 析构：表项释放 + 基类 vtable 回退（推定） |
| 0x14015E6D0 | 转发桩: 转发至 业务 TGameItemDatabase 模板实例<NIndustrialOrganisation>（推定） |
| 0x1407152C0 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabase.h:142（推定） |
| 0x1418CE4F0 | 转发桩: 转发至 — 业务 gameitemdatabase.h:149 "Instance not created." 断言（数据库访问器），无其他线索（推定） |
| 0x142606870 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1425EF730 | 转发桩: 转发至 业务 类名证据「TGameItemDatabase<CAIEquipmentRoleDatabase>」 §4.26 静态资源（推定） |
| 0x1425EFFD0 | 转发桩: 转发至 数据库析构 TGameItemDatabase<CAIStrategyPlanDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放（推定） |
| 0x140A92670 | 转发桩: 转发至 sub_140A8F620 数据库条目缺失（Entry doesn't exist in database:）（推定） |
| 0x140A92690 | 转发桩: 转发至 业务 "Duplicate entry in list: " / "Entry doesn't exist in database: " 校验串，夹于 Reader(d=2880) 与 NProject::CHasFloatingHarborTrigger::[0]，数据库条目去重校验（推定） |
| 0x140A926B0 | 转发桩: 转发至 业务 gameitemdatabase.h:142 站点，"Entry doesn't exist in database"/"Duplicate entry in list" 条目校验，数据库（qword_14332F090）条目装载（推定） |
| 0x140A4F480 | 转发桩: 转发至 sub_1413AEE50 业务 串：GFX_idea_unknown（推定） |
| 0x141A17B70 | 转发桩: 转发至 未命名业务函数 define/本地化键（串 AGENCY_UPGRADES_DURATION）（推定） |
| 0x140672D80 | 转发桩: 转发至 CGameItemDatabase 表操作 pdx_robin_hood_table.h:58 + gameitemdatabase.h:142 双断言 → CGameItemDatabase 表操作（推定） |
| 0x141E2FED0 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:27 ->§4.26; 串 "!_pInstance && \"Instance already cr"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1401AB4F0 | 转发桩: 转发至 （无名，按证据定性） gameitemdatabase.h:281 断言 !_Paths.IsEmpty()（数据库模板路径校验同族）（推定） |
| 0x14207E5F0 | 转发桩: 转发至 业务 遍历 a1+16 数组按 SSO 串（+2624 指针/+2648 长度>0xF）逐字节比较 a2，命中返元素 按名线性查找（SSO 串比较）（推定） |
| 0x1401AB4A0 | 转发桩: 转发至 sub_1401A10B0 gameitemdatabase.h:281 "!_Paths.IsEmpty() && \"Cant reload when not loaded\""（数据库重载门 + "=====" 分隔日志）（推定） |
| 0x14072B940 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35（推定） |
| 0x140AC4E50 | 转发桩: 转发至 域关键词匹配 sub_140AC28B0 + 域关键词匹配; 源码路径 hoi4; 断言站点 gameitemdatabasehelper.h:35（推定） |
| 0x142602160 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x142602520 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1425FEA30 | 转发桩: 转发至 业务 断言站点 orderinstance.cpp:11; 串 "!\"Battleplans - trying to do invali"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x142601AD0 | 转发桩: 被调者 0x140ADEC20 -> §4.26 (E:单调用转发(被调者入书))（推定） |
| 0x142601AF0 | 转发桩: 被调者 0x140ADEC20 -> §4.26 (E:单调用转发(被调者入书))（推定） |
| 0x14262EDF0 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 断言站点 industrial_org_ui_context.cpp:22; 类路由 NProject ->§4.25（推定） |
| 0x1425F8610 | 转发桩: 被调者 0x1409CAA00 -> §4.26 (E:单调用转发(被调者入书))（推定） |
| 0x140687090 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22（推定） |
| 0x1409F81D0 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35（推定） |
| 0x140ACBDA0 | 转发桩: 转发至 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言）（推定） |
| 0x140ACBDC0 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35（推定） |
| 0x1406AB520 | 转发桩: 转发至 未命名业务函数 游戏物件库助手（gameitemdatabasehelper.h 断言）（推定） |
| 0x1406AFD20 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35（推定） |
| 0x1409CAA00 | 转发桩: 转发至 域关键词匹配 sub_1409CA550 + 域关键词匹配（推定） |
| 0x140AEA640 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:35（推定） |
| 0x1425EE5B0 | 转发桩: 转发至 业务 类名证据「TGameItemDatabase<CAbilityDatabase>」 §4.26 静态资源（推定） |
| 0x1425F81E0 | 转发桩: 转发至 业务 反向调用图 1/2 调用者投 §4.26; 唯一被调用者在书内 §4.1（推定） |
| 0x1425FB740 | 转发桩: 转发至 数据库析构 TGameItemDatabase<CWarGoalDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放（推定） |
| 0x1425FD780 | 转发桩: 转发至 业务 类名证据「TGameItemDatabase<CNameDatabase>」 §4.26 静态资源（推定） |
| 0x1425FECD0 | 转发桩: 转发至 业务 反向调用图 1/2 调用者投 §4.26; 唯一被调用者在书内 §4.1（推定） |
| 0x142600450 | 转发桩: 转发至 数据库析构 TGameItemDatabase<CScriptedTriggerTemplateDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放（推定） |
| 0x142601770 | 转发桩: 转发至 业务 类名证据「TGameItemDatabase<CTimedActivityDatabase>」 §4.26 静态资源（推定） |
| 0x142601A80 | 转发桩: 转发至 业务 反向调用图 1/2 调用者投 §4.26; 唯一被调用者在书内 §4.1（推定） |
| 0x142602AB0 | 转发桩: 转发至 数据库析构 TGameItemDatabase<CUnitNamesDatabase> 析构：+8 表 sub_140120CE0 清空 + 分配器 vtable+16 释放（推定） |
| 0x1425FC8C0 | 转发桩: 转发至 业务 类名证据「TGameItemDatabase<CInsigniaGraphicsDatabase>」 §4.26 静态资源（推定） |
| 0x1401AB4D0 | 转发桩: 转发至 sub_140198610（无名） gameitemdatabase.h:281 站点 "!_Paths.IsEmpty() && Cant reload when not loaded" + "=====" 分隔日志，夹于 CDatabaseReloader<CTrainGfxDatabas…（推定） |
| 0x1401AB540 | 转发桩: 转发至 （无名） 业务 gameitemdatabase.h:281 + 断言 "!_Paths.IsEmpty() && \"Cant reload when not loaded\""（推定） |
| 0x1401AB550 | 转发桩: 转发至 sub_14019BA10 业务 gameitemdatabase.h "!_Paths.IsEmpty()" + "=====" 分隔行（推定） |
| 0x1401AB590 | 转发桩: 转发至 （无名，按证据定性） gameitemdatabase.h:281 断言 !_Paths.IsEmpty()（数据库模板路径校验，同族 0x1401A3AC0/0x140198DB0）（推定） |
| 0x1425FEA90 | 转发桩: 转发至 业务 断言站点 orderinstance.cpp:11; 串 "!\"Battleplans - trying to do invali"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x142601690 | 转发桩: 被调者 0x140ACB5F0 -> §4.26 (E:单调用转发(链内))（推定） |
| 0x14264D470 | 转发桩: 被调者 0x1416565D0 -> §4.26 (E:单调用转发(被调者入书))（推定） |
| 0x1426F5C80 | 转发桩: 转发至 域关键词匹配 sub_1409C01A0 + 域关键词匹配（推定） |
| 0x142593A90 | 转发桩: 转发至 业务 断言站点 gameitemdatabase.h:42 ->§4.26; 串 "_pInstance && \"Instance not created"; 串 "C:\\mnt\\gsg\\hoi4\\hoi4_merged\\hoi"（推定） |
| 0x1426EC610 | 转发桩: 转发至 业务 断言站点 gameitemdatabasehelper.h:22 ->§4.26; 串 "( Array.GetSize() > 0 ) && \"Array s"; 串 "o add the Null Object as Array[0]?\""（推定） |
| 0x1426F5500 | 转发桩: 转发至 域关键词匹配 sub_1409C01A0 + 域关键词匹配（推定） |
| 0x140647CE0 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22（推定） |
| 0x140647CF0 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:22（推定） |
| 0x140AEA6F0 | 转发桩: 转发至 无名 sub_（断言站点/串定位） 断言站点 gameitemdatabasehelper.h:120（推定） |

#### 4.26.55 静态资源访问层函数补遗（24 函）

| VA | 语义/证据 |
|---|---|
| 0x140AE1350 | 反调用图单链锚点（0.5）投 §4.26；锚点 `sub_140ADEED0` |
| 0x140889390 | 625/625 同族：首个非自身被调用者恒为 `sub_1421AB9E0`；断言串 `Error reading "<KEY>", "<NS>" is not a lua table`；15 个 defines_*.h + faction_defines.h/raid_defines.h 源文件:行号锚；读取器… |
| 0x140157240 | caller 140158C80(gameitemdatabase.h:780) |
| 0x140B3A840 | caller 140B3B180/140B3A440(gameitemdatabase.h:142 邻域) |
| 0x1415E5AC0 | caller 1415F3230(gameitemdatabase.h:142) |
| 0x141BB7F70 | gameitemdatabase.h:142 断言 `_pInstance && "Instance not created."` + qword_14332EF88 表拷贝；caller 141A618D0 |
| 0x14067F840 | 调用图传播 1 跳：CBuildingDatabase::[2]（1 个） |
| 0x1406800A0 | 调用图传播 1 跳：CBuildingDatabase::[2]（1 个） |
| 0x1406804D0 | 调用图传播 1 跳：CBuildingDatabase::[2]（1 个） |
| 0x140680900 | 调用图传播 1 跳：CBuildingDatabase::[2]（1 个） |
| 0x140A00560 | 调用图传播 1 跳：CEquipmentGraphicPool::Reader（1 个） |
| 0x140A5E820 | 断言 pdx_scoped_buffer.h:54 写门 |
| 0x140A7B700 | 断言 gameitemdatabase.h:142 "_pInstance && \"Instance not created.\"" / gameitemdatabase.h |
| 0x140A803A0 | VTNAME TGameItemDatabase\ COpinionModifierDatabase\ COpinionModifierDatabase |
| 0x140D925E0 | SRC gameitemdatabase.h + 串 "_pInstance && " |
| 0x140F11020 | 调用图传播 1 跳：SWeatherPerRegion::Reader（1 个） |
| 0x140F8AD40 | 调用图传播 1 跳：CAceModifier::Reader（5 个） |
| 0x140FC6610 | 调用图传播 1 跳：NDoctrines::CFolderStatus::Reader（1 个） |
| 0x140FF0470 | 调用图传播 1 跳：CCountryOccupationData::Reader（1 个） |
| 0x140FF1090 | 调用图传播 2 跳：CCountryOccupationData::Reader（1 个） |
| 0x1412649A0 | 调用图传播 1 跳：CMapArrowButtonDefinition::Reader（5 个） |
| 0x141300A10 | SRC gameitemdatabase.h + 串 "_pInstance && " |
| 0x141576CF0 | 断言 gameitemdatabase.h:142 "_pInstance && \"Instance not created.\"" / gameitemdatabase.h |
| 0x1419244C0 | 调用图传播 1 跳：UEAAXAEAVCReader::CPersistedMioQueues::Read::SEntryReader::[1]（1 个） |

#### 4.26.56 静态资源访问层define 注册 functor 族（1 函）

| VA | 语义/证据 |
|---|---|
| 0x1407538A0..0x1409A93F0 | NDefines::CDefineRegistryHelper 读取器族（704 个模板实例, 逐 define 从 Lua 表读值; 逐 VA 见 findings/cov_full/_book_inbook.tsv） |

#### 4.26.57 静态资源访问层函数补遗（1451 函）

| VA | 语义/证据 |
|---|---|
| 0x141CC97A0 | 业务 邻域 systemsettings.cpp:142 + a1+1552 数组（9*qword 步长条目）+ a1+1564/a1+1588 |
| 0x142246180 | 业务 "Language" 头 + "%d (%x) ｜ %c ｜ (Count: %d)" 条目转储 + virtualfilesystem.cpp:437 + qword_143453118/dword_143453124 |
| 0x1409790D0 | NDefines::CDefineRegistryHelper_NOperativesON_CAPTURE_COUNTERIN…::[0] 业务 defines 注册/读取族 |
| 0x140977EF0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_SUB_NE…::[0] 业务 defines 注册/读取族 |
| 0x1408A6900 | NDefines::CDefineRegistryHelper_NInterfaceMISSION_NAVAL_INVASIO…::[0] 业务 defines 注册/读取族 |
| 0x14074F5F0 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_ADJ_NORMAL::[0] 业务 defines 注册/读取族 |
| 0x14087F570 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationFUNDS_FR…::[0] 业务 defines 注册/读取族 |
| 0x1408EF3C0 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_SECONDARY_…::[0] 业务 defines 注册/读取族 |
| 0x14087FA40 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationMAX_FUND…::[0] 业务 defines 注册/读取族 |
| 0x14082F050 | NDefines::CDefineRegistryHelper_NDoctrinesTHEATER_COMMANDER_UNI…::[0] 业务 defines 注册/读取族 |
| 0x14087DB50 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationDEFAULT_…::[0] 业务 defines 注册/读取族 |
| 0x1408EEE40 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_PRIMARY_VA…::[0] 业务 defines 注册/读取族 |
| 0x140974280 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_INTELL…::[0] 业务 defines 注册/读取族 |
| 0x140972F40 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_BASE_S…::[0] 业务 defines 注册/读取族 |
| 0x1408A6380 | NDefines::CDefineRegistryHelper_NInterfaceMISSION_CONVOY_ESCORT…::[0] 业务 defines 注册/读取族 |
| 0x1409768F0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_NATION…::[0] 业务 defines 注册/读取族 |
| 0x1407D5540 | NDefines::CDefineRegistryHelper_NAirAIR_WING_ATTACK_LOGISTICS_T…::[0] 业务 defines 注册/读取族 |
| 0x1409A3550 | NDefines::CDefineRegistryHelper_NSupplyAI_FRONT_MINIMUM_UNITS_P…::[0] 业务 defines 注册/读取族 |
| 0x140836320 | NDefines::CDefineRegistryHelper_NFactionsFACTION_THEATER_COMMAN…::[0] 业务 defines 注册/读取族 |
| 0x140895C50 | NDefines::CDefineRegistryHelper_NIntelLAND_COMBAT_ARMY_INTEL_OV…::[0] 业务 defines 注册/读取族 |
| 0x14096F0D0 | NDefines::CDefineRegistryHelper_NOperativesCONTROL_TRADE_NETWOR…::[0] 业务 defines 注册/读取族 |
| 0x1407D5280 | NDefines::CDefineRegistryHelper_NAirAIR_WING_ATTACK_LOGISTICS_T…::[0] 业务 defines 注册/读取族 |
| 0x14095D8B0 | NDefines::CDefineRegistryHelper_NNavyPOSITIONING_PENALTY_FOR_SH…::[0] 业务 defines 注册/读取族 |
| 0x140971EC0 | NDefines::CDefineRegistryHelper_NOperativesDIPLOMATIC_PRESSURE_…::[0] 业务 defines 注册/读取族 |
| 0x14088F060 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_CAPT…::[0] 业务 defines 注册/读取族 |
| 0x1408A6E80 | NDefines::CDefineRegistryHelper_NInterfaceMISSION_PATROL_SOFT_R…::[0] 业务 defines 注册/读取族 |
| 0x1408A8E50 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_NETWORK_STR…::[0] 业务 defines 注册/读取族 |
| 0x14096E5D0 | NDefines::CDefineRegistryHelper_NOperativesBUILD_INTEL_NETWORK_…::[0] 业务 defines 注册/读取族 |
| 0x1408370E0 | NDefines::CDefineRegistryHelper_NFactionsFACTION_THEATER_COMMAN…::[0] 业务 defines 注册/读取族 |
| 0x140816480 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_LEADERSHIP_CH…::[0] 业务 defines 注册/读取族 |
| 0x1408986F0 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_NAVY_INTEL_O…::[0] 业务 defines 注册/读取族 |
| 0x140975BE0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_MIN_SU…::[0] 业务 defines 注册/读取族 |
| 0x14097D0C0 | NDefines::CDefineRegistryHelper_NOperativesPROPAGANDA_NETWORK_M…::[0] 业务 defines 注册/读取族 |
| 0x140896B70 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_AIR_INTEL_OV…::[0] 业务 defines 注册/读取族 |
| 0x140891DC0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_NAVA…::[0] 业务 defines 注册/读取族 |
| 0x140976370 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_NATION…::[0] 业务 defines 注册/读取族 |
| 0x140972700 | NDefines::CDefineRegistryHelper_NOperativesDIPLOMATIC_PRESSURE_…::[0] 业务 defines 注册/读取族 |
| 0x1408238F0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_INCREASE_COST_F…::[0] 业务 defines 注册/读取族 |
| 0x140898170 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_NAVY_INTEL_O…::[0] 业务 defines 注册/读取族 |
| 0x1408A93D0 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_PROPAGANDA_…::[0] 业务 defines 注册/读取族 |
| 0x1409B0710 | NDefines::CDefineRegistryHelper_NSupplySUPPLY_FLOW_DIST_LOGISTI…::[0] 业务 defines 注册/读取族 |
| 0x14087EFF0 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationFUNDS_FO…::[0] 业务 defines 注册/读取族 |
| 0x140890EA0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_LAND…::[0] 业务 defines 注册/读取族 |
| 0x140898C70 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_NAVY_INTEL_O…::[0] 业务 defines 注册/读取族 |
| 0x14088E140 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_AIR_…::[0] 业务 defines 注册/读取族 |
| 0x1409773F0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_STATE_…::[0] 业务 defines 注册/读取族 |
| 0x14088D220 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_AIR_…::[0] 业务 defines 注册/读取族 |
| 0x1407FA960 | NDefines::CDefineRegistryHelper_NCountryCOUNTRY_MANPOWER_CAPITU…::[0] 业务 defines 注册/读取族 |
| 0x140977970 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_STRENG…::[0] 业务 defines 注册/读取族 |
| 0x14088F7F0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_CAPT…::[0] 业务 defines 注册/读取族 |
| 0x1408EEB80 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_PRIMARY_IN…::[0] 业务 defines 注册/读取族 |
| 0x14097A4C0 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_BASE_DIPLO…::[0] 业务 defines 注册/读取族 |
| 0x1408970F0 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_ARMY_INTEL_O…::[0] 业务 defines 注册/读取族 |
| 0x14097ADB0 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_BASE_ROOT_…::[0] 业务 defines 注册/读取族 |
| 0x14087FD00 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationUNLOCKED…::[0] 业务 defines 注册/读取族 |
| 0x1408A84D0 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_COUNTER_INT…::[0] 业务 defines 注册/读取族 |
| 0x140972C80 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_BASE_S…::[0] 业务 defines 注册/读取族 |
| 0x140975660 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_MIN_SU…::[0] 业务 defines 注册/读取族 |
| 0x140988650 | NDefines::CDefineRegistryHelper_NProductionMINIMUM_NUMBER_OF_FA…::[0] 业务 defines 注册/读取族 |
| 0x1408A60C0 | NDefines::CDefineRegistryHelper_NInterfaceMISSION_CONVOY_ESCORT…::[0] 业务 defines 注册/读取族 |
| 0x1408A9950 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_TENSION_DRI…::[0] 业务 defines 注册/读取族 |
| 0x14082E8C0 | NDefines::CDefineRegistryHelper_NDoctrinesMILITARY_ATTACHE_MAST…::[0] 业务 defines 注册/读取族 |
| 0x140815F00 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_LEADERSHIP_CH…::[0] 业务 defines 注册/读取族 |
| 0x1408937E0 | NDefines::CDefineRegistryHelper_NIntelINTEL_NETWORK_NATIONAL_CO…::[0] 业务 defines 注册/读取族 |
| 0x140904370 | NDefines::CDefineRegistryHelper_NMilitaryCOHESION_IMMOBILE_PLAN…::[0] 业务 defines 注册/读取族 |
| 0x1409AEC60 | NDefines::CDefineRegistryHelper_NSupplyRAILWAY_DISTANCE_FACTOR_…::[0] 业务 defines 注册/读取族 |
| 0x1408956D0 | NDefines::CDefineRegistryHelper_NIntelLAND_COMBAT_ARMY_INTEL_OV…::[0] 业务 defines 注册/读取族 |
| 0x140938A00 | NDefines::CDefineRegistryHelper_NNavyCAPITAL_RATIO_FOR_FULL_SCR…::[0] 业务 defines 注册/读取族 |
| 0x1408EFE20 | NDefines::CDefineRegistryHelper_NMapModeDEPLOYED_GENERAL_FRONT_…::[0] 业务 defines 注册/读取族 |
| 0x1409A7D40 | NDefines::CDefineRegistryHelper_NSupplyDAYS_TO_START_GIVING_SUP…::[0] 业务 defines 注册/读取族 |
| 0x1407F4AA0 | NDefines::CDefineRegistryHelper_NCharacterOFFICER_CORP_HIGH_COM…::[0] 业务 defines 注册/读取族 |
| 0x1409513D0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_PLANE_COU…::[0] 业务 defines 注册/读取族 |
| 0x140815980 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_LEADERSHIP_CH…::[0] 业务 defines 注册/读取族 |
| 0x14088FF80 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_EVEN…::[0] 业务 defines 注册/读取族 |
| 0x140960E50 | NDefines::CDefineRegistryHelper_NNavySCREEN_RATIO_FOR_FULL_SCRE…::[0] 业务 defines 注册/读取族 |
| 0x1407C8ED0 | NDefines::CDefineRegistryHelper_NAITHEORIST_SCALING_WEIGHT_FACT…::[0] 业务 defines 注册/读取族 |
| 0x140773B30 | NDefines::CDefineRegistryHelper_NAIDEFAULT_MODULE_VARIANT_CREAT…::[0] 业务 defines 注册/读取族 |
| 0x1407B3E80 | NDefines::CDefineRegistryHelper_NAIPEACE_BID_CONTEST_TIE_BREAKE…::[0] 业务 defines 注册/读取族 |
| 0x14088EDA0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_CAPT…::[0] 业务 defines 注册/读取族 |
| 0x140949E10 | NDefines::CDefineRegistryHelper_NNavyMAX_CARRIER_RATIO_POSITION…::[0] 业务 defines 注册/读取族 |
| 0x140995F10 | NDefines::CDefineRegistryHelper_NRailwayGunATTACK_TO_BOMBARDMEN…::[0] 业务 defines 注册/读取族 |
| 0x14093F5B0 | NDefines::CDefineRegistryHelper_NNavyCONVOY_SPOTTING_COOLDOWN_M…::[0] 业务 defines 注册/读取族 |
| 0x140967260 | NDefines::CDefineRegistryHelper_NNavySURFACE_DETECTION_STAT_FOR…::[0] 业务 defines 注册/读取族 |
| 0x140823370 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_COST_FACTOR_UNC…::[0] 业务 defines 注册/读取族 |
| 0x1408FCCA0 | NDefines::CDefineRegistryHelper_NMarketPURCHASE_CONTRACT_SUBSID…::[0] 业务 defines 注册/读取族 |
| 0x1409A77C0 | NDefines::CDefineRegistryHelper_NSupplyCOOLDOWN_DAYS_AFTER_MOVI…::[0] 业务 defines 注册/读取族 |
| 0x140822870 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_COST_FACTOR_STA…::[0] 业务 defines 注册/读取族 |
| 0x140945FC0 | NDefines::CDefineRegistryHelper_NNavyHIGHER_SHIP_RATIO_POSITION…::[0] 业务 defines 注册/读取族 |
| 0x140941950 | NDefines::CDefineRegistryHelper_NNavyDEPTH_CHARGE_STAT_FOR_SHIP…::[0] 业务 defines 注册/读取族 |
| 0x1407B3900 | NDefines::CDefineRegistryHelper_NAIPEACE_BID_CONTEST_TIE_BREAKE…::[0] 业务 defines 注册/读取族 |
| 0x1407FCA20 | NDefines::CDefineRegistryHelper_NCountryGIE_CAPITULATION_LEGITI…::[0] 业务 defines 注册/读取族 |
| 0x14087EA70 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationFUNDS_FO…::[0] 业务 defines 注册/读取族 |
| 0x1408FB580 | NDefines::CDefineRegistryHelper_NMarketCONTRACT_ESTIMATE_AVERAG…::[0] 业务 defines 注册/读取族 |
| 0x14096FF20 | NDefines::CDefineRegistryHelper_NOperativesCOUNTER_INTELLIGENCE…::[0] 业务 defines 注册/读取族 |
| 0x140891630 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_LAND…::[0] 业务 defines 注册/读取族 |
| 0x1407831E0 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_CONTRACT_EF…::[0] 业务 defines 注册/读取族 |
| 0x14088D9B0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_AIR_…::[0] 业务 defines 注册/读取族 |
| 0x14098DB80 | NDefines::CDefineRegistryHelper_NProjectMINIMUM_PROJECT_SPEED_F…::[0] 业务 defines 注册/读取族 |
| 0x140783CE0 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_MAX_CIVS_FO…::[0] 业务 defines 注册/读取族 |
| 0x1409734C0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_DETECT…::[0] 业务 defines 注册/读取族 |
| 0x14098B3E0 | NDefines::CDefineRegistryHelper_NProjectBREAKTHROUGH_DAILY_NUCL…::[0] 业务 defines 注册/读取族 |
| 0x14098B960 | NDefines::CDefineRegistryHelper_NProjectBREAKTHROUGH_DAILY_SCIE…::[0] 业务 defines 注册/读取族 |
| 0x14094C920 | NDefines::CDefineRegistryHelper_NNavyMIN_MINE_CAPABLE_RATIO_FOR…::[0] 业务 defines 注册/读取族 |
| 0x14087E0D0 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationDESIGN_T…::[0] 业务 defines 注册/读取族 |
| 0x14094D140 | NDefines::CDefineRegistryHelper_NNavyMIN_SHIPS_FOR_HIGHER_SHIP_…::[0] 业务 defines 注册/读取族 |
| 0x14078FA20 | NDefines::CDefineRegistryHelper_NAIINDUSTRIAL_ORG_PRODUCTION_AS…::[0] 业务 defines 注册/读取族 |
| 0x14097D380 | NDefines::CDefineRegistryHelper_NOperativesPROPAGANDA_OPERATIVE…::[0] 业务 defines 注册/读取族 |
| 0x140822DF0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_COST_FACTOR_UNC…::[0] 业务 defines 注册/读取族 |
| 0x14094FFE0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_AGILITY_T…::[0] 业务 defines 注册/读取族 |
| 0x14081A310 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_NEUTRAL_DIS…::[0] 业务 defines 注册/读取族 |
| 0x140939190 | NDefines::CDefineRegistryHelper_NNavyCARRIER_OFFENSIVE_STANCE_D…::[0] 业务 defines 注册/读取族 |
| 0x140785E30 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_UPGRADE_VARIANT_MA…::[0] 业务 defines 注册/读取族 |
| 0x1408260E0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_TRIGGER_AI_MAX_…::[0] 业务 defines 注册/读取族 |
| 0x1409435D0 | NDefines::CDefineRegistryHelper_NNavyDOMINANCE_PER_SHIP_PER_HEA…::[0] 业务 defines 注册/读取族 |
| 0x140866940 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_LAND_SHARP_…::[0] 业务 defines 注册/读取族 |
| 0x1408F9080 | NDefines::CDefineRegistryHelper_NMapModeSUPPLY_HOVERED_PROVINCE…::[0] 业务 defines 注册/读取族 |
| 0x1409ADBE0 | NDefines::CDefineRegistryHelper_NSupplyNUMBER_OF_SHOWN_SUPPLY_S…::[0] 业务 defines 注册/读取族 |
| 0x14097C880 | NDefines::CDefineRegistryHelper_NOperativesPROPAGANDA_COUNTRY_S…::[0] 业务 defines 注册/读取族 |
| 0x1409AE6E0 | NDefines::CDefineRegistryHelper_NSupplyRAILWAY_CONVERSION_COOLD…::[0] 业务 defines 注册/读取族 |
| 0x1409B18F0 | NDefines::CDefineRegistryHelper_NSupplySUPPLY_HUB_FULL_MOTORIZA…::[0] 业务 defines 注册/读取族 |
| 0x1407EA0D0 | NDefines::CDefineRegistryHelper_NAirNAVAL_MINES_SWEEPING_SPEED_…::[0] 业务 defines 注册/读取族 |
| 0x14096C900 | NDefines::CDefineRegistryHelper_NOperativesAGENCY_UPGRADE_PER_O…::[0] 业务 defines 注册/读取族 |
| 0x140759B30 | NDefines::CDefineRegistryHelper_NAIAI_OBJECTIVE_DEFAULT_TARGET_…::[0] 业务 defines 注册/读取族 |
| 0x1407ECC20 | NDefines::CDefineRegistryHelper_NAirSTRATEGIC_BOMBING_RAILWAY_P…::[0] 业务 defines 注册/读取族 |
| 0x140965690 | NDefines::CDefineRegistryHelper_NNavySUBMARINE_REVEAL_ON_MINIMU…::[0] 业务 defines 注册/读取族 |
| 0x14076D200 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_FACTOR_OCC…::[0] 业务 defines 注册/读取族 |
| 0x140953C40 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_MEDAL_LAST_ME…::[0] 业务 defines 注册/读取族 |
| 0x14098BEE0 | NDefines::CDefineRegistryHelper_NProjectBREAKTHROUGH_GAIN_ANIMA…::[0] 业务 defines 注册/读取族 |
| 0x140797B40 | NDefines::CDefineRegistryHelper_NAILAND_DESIGN_ALTERNATIVE_OF_G…::[0] 业务 defines 注册/读取族 |
| 0x140800F80 | NDefines::CDefineRegistryHelper_NCountryGIE_VETERAN_MANPOWER_CO…::[0] 业务 defines 注册/读取族 |
| 0x140880B70 | NDefines::CDefineRegistryHelper_NIntelAIR_COMBAT_AIR_INTEL_PER_…::[0] 业务 defines 注册/读取族 |
| 0x1407FDD60 | NDefines::CDefineRegistryHelper_NCountryGIE_ESCAPING_DIVISIONS_…::[0] 业务 defines 注册/读取族 |
| 0x1407FFAF0 | NDefines::CDefineRegistryHelper_NCountryGIE_HOST_DOCKYARDS_FROM…::[0] 业务 defines 注册/读取族 |
| 0x14096EB50 | NDefines::CDefineRegistryHelper_NOperativesCONTROL_TRADE_INFLUE…::[0] 业务 defines 注册/读取族 |
| 0x140993520 | NDefines::CDefineRegistryHelper_NRaidsRAID_OUTCOME_REPORT_DAYS_…::[0] 业务 defines 注册/读取族 |
| 0x1409A5400 | NDefines::CDefineRegistryHelper_NSupplyBASE_SUPPLY_MULT_FOR_TRU…::[0] 业务 defines 注册/读取族 |
| 0x1409A6A00 | NDefines::CDefineRegistryHelper_NSupplyCAPITAL_STARTING_PENALTY…::[0] 业务 defines 注册/读取族 |
| 0x140841B60 | NDefines::CDefineRegistryHelper_NGameTRADE_ROUTE_RECALCULATE_FR…::[0] 业务 defines 注册/读取族 |
| 0x1408653F0 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_AIR_SLOPE_S…::[0] 业务 defines 注册/读取族 |
| 0x140952850 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_SUB_DETEC…::[0] 业务 defines 注册/读取族 |
| 0x1409A4E80 | NDefines::CDefineRegistryHelper_NSupplyBASE_NAVY_SUPPLY_MULT_FO…::[0] 业务 defines 注册/读取族 |
| 0x140912820 | NDefines::CDefineRegistryHelper_NMilitaryLEADER_MOD_NO_HQ_SCALI…::[0] 业务 defines 注册/读取族 |
| 0x14097DFE0 | NDefines::CDefineRegistryHelper_NOperativesROOT_OUT_RESISTANCE_…::[0] 业务 defines 注册/读取族 |
| 0x14090BFC0 | NDefines::CDefineRegistryHelper_NMilitaryFIGHTING_STRENGTH_DEAT…::[0] 业务 defines 注册/读取族 |
| 0x14076A550 | NDefines::CDefineRegistryHelper_NAICANCEL_INVASION_COMBAT_DISAD…::[0] 业务 defines 注册/读取族 |
| 0x140934060 | NDefines::CDefineRegistryHelper_NNavyANTI_AIR_MULT_ON_INCOMING_…::[0] 业务 defines 注册/读取族 |
| 0x1409A4900 | NDefines::CDefineRegistryHelper_NSupplyBASE_AIR_SUPPLY_MULT_FOR…::[0] 业务 defines 注册/读取族 |
| 0x1407AFBD0 | NDefines::CDefineRegistryHelper_NAINUM_DAYS_TO_PULL_EXPEDITIONA…::[0] 业务 defines 注册/读取族 |
| 0x140819290 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_MAX_DIST_CO…::[0] 业务 defines 注册/读取族 |
| 0x14087E7B0 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationFUNDS_FO…::[0] 业务 defines 注册/读取族 |
| 0x140890BE0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_LAND…::[0] 业务 defines 注册/读取族 |
| 0x140971260 | NDefines::CDefineRegistryHelper_NOperativesDANGER_LEVEL_PROPORT…::[0] 业务 defines 注册/读取族 |
| 0x1407FE5A0 | NDefines::CDefineRegistryHelper_NCountryGIE_EXILE_AIR_RECRUITME…::[0] 业务 defines 注册/读取族 |
| 0x1408EE8C0 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_PRIMARY_FO…::[0] 业务 defines 注册/读取族 |
| 0x1408968B0 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_AIR_INTEL_OV…::[0] 业务 defines 注册/读取族 |
| 0x140977130 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_OPERAT…::[0] 业务 defines 注册/读取族 |
| 0x1409A2FD0 | NDefines::CDefineRegistryHelper_NSupplyAI_FRONT_DIVISIONS_PER_S…::[0] 业务 defines 注册/读取族 |
| 0x140756D50 | NDefines::CDefineRegistryHelper_NAIAIR_DESIGN_ALTERNATIVE_OF_EQ…::[0] 业务 defines 注册/读取族 |
| 0x14088CF60 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_AIR_…::[0] 业务 defines 注册/读取族 |
| 0x14076D780 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_FACTOR_OWN…::[0] 业务 defines 注册/读取族 |
| 0x1407AD3F0 | NDefines::CDefineRegistryHelper_NAINAVAL_PATROL_PLANES_PER_SHIP…::[0] 业务 defines 注册/读取族 |
| 0x140817500 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_POWER_INDUSTR…::[0] 业务 defines 注册/读取族 |
| 0x140952DD0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_SUB_DETEC…::[0] 业务 defines 注册/读取族 |
| 0x1409B0F50 | NDefines::CDefineRegistryHelper_NSupplySUPPLY_FLOW_PENALTY_CROS…::[0] 业务 defines 注册/读取族 |
| 0x14082D840 | NDefines::CDefineRegistryHelper_NDoctrinesDEFAULT_REWARD_MASTERY::[0] 业务 defines 注册/读取族 |
| 0x14097A200 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_BASE_DIPLO…::[0] 业务 defines 注册/读取族 |
| 0x140786930 | NDefines::CDefineRegistryHelper_NAIEXPEDITIONARY_CASUALTY_DECAY…::[0] 业务 defines 注册/读取族 |
| 0x1407FD260 | NDefines::CDefineRegistryHelper_NCountryGIE_DIVISION_ATTACK_BON…::[0] 业务 defines 注册/读取族 |
| 0x1407DC1A0 | NDefines::CDefineRegistryHelper_NAirCOMBAT_BETTER_SPEED_DAMAGE_…::[0] 业务 defines 注册/读取族 |
| 0x1408F7710 | NDefines::CDefineRegistryHelper_NMapModeSELECTION_HOVERED_STATE…::[0] 业务 defines 注册/读取族 |
| 0x1409B4AE0 | NDefines::CDefineRegistryHelper_NTechnologyDEFAULT_XP_BOOST_RES…::[0] 业务 defines 注册/读取族 |
| 0x1409B5060 | NDefines::CDefineRegistryHelper_NTechnologyDEFAULT_XP_UNLOCK_RE…::[0] 业务 defines 注册/读取族 |
| 0x140825AD0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_TIMED_EFFECT_LE…::[0] 业务 defines 注册/读取族 |
| 0x14077D7F0 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_REJECTED_WAIT_MONT…::[0] 业务 defines 注册/读取族 |
| 0x1407FA6A0 | NDefines::CDefineRegistryHelper_NCountryCOUNTRY_MANPOWER_CAPITU…::[0] 业务 defines 注册/读取族 |
| 0x140897670 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_CIVILIAN_INT…::[0] 业务 defines 注册/读取族 |
| 0x14091D8D0 | NDefines::CDefineRegistryHelper_NMilitaryPLANNING_SPEED_NO_HQ_S…::[0] 业务 defines 注册/读取族 |
| 0x14096D4B0 | NDefines::CDefineRegistryHelper_NOperativesBOOST_IDEOLOGY_DEFEN…::[0] 业务 defines 注册/读取族 |
| 0x14076F880 | NDefines::CDefineRegistryHelper_NAICONVOY_RAIDING_TARGET_RECALC…::[0] 业务 defines 注册/读取族 |
| 0x140817A80 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_POWER_NAVAL_W…::[0] 业务 defines 注册/读取族 |
| 0x14096B460 | NDefines::CDefineRegistryHelper_NOperativesACTIVITY_LEVEL_INTEG…::[0] 业务 defines 注册/读取族 |
| 0x140970CE0 | NDefines::CDefineRegistryHelper_NOperativesDANGER_LEVEL_DERIVAT…::[0] 业务 defines 注册/读取族 |
| 0x140780600 | NDefines::CDefineRegistryHelper_NAIDIVISION_MATCH_ROLE_BOOST_FA…::[0] 业务 defines 注册/读取族 |
| 0x140841270 | NDefines::CDefineRegistryHelper_NGameMUSIC_PLAYER_RECENTLY_PLAY…::[0] 业务 defines 注册/读取族 |
| 0x1409A7500 | NDefines::CDefineRegistryHelper_NSupplyCAPITAL_SUPPLY_MILITARY_…::[0] 业务 defines 注册/读取族 |
| 0x1409ACC10 | NDefines::CDefineRegistryHelper_NSupplyNAVAL_SUPPLY_HUB_REDUCTI…::[0] 业务 defines 注册/读取族 |
| 0x1408FC3D0 | NDefines::CDefineRegistryHelper_NMarketMAX_CIV_FACTORIES_PER_CO…::[0] 业务 defines 注册/读取族 |
| 0x140987B70 | NDefines::CDefineRegistryHelper_NProductionMAX_MIL_FACTORIES_PE…::[0] 业务 defines 注册/读取族 |
| 0x1408225B0 | NDefines::CDefineRegistryHelper_NDiplomacyPEACE_COST_FACTOR_STA…::[0] 业务 defines 注册/读取族 |
| 0x140945D00 | NDefines::CDefineRegistryHelper_NNavyHIGHER_CARRIER_RATIO_POSIT…::[0] 业务 defines 注册/读取族 |
| 0x140972440 | NDefines::CDefineRegistryHelper_NOperativesDIPLOMATIC_PRESSURE_…::[0] 业务 defines 注册/读取族 |
| 0x1409781B0 | NDefines::CDefineRegistryHelper_NOperativesINTEL_NETWORK_SUB_NE…::[0] 业务 defines 注册/读取族 |
| 0x14098EE40 | NDefines::CDefineRegistryHelper_NProjectPROTOTYPE_PHASE_MAX_PRO…::[0] 业务 defines 注册/读取族 |
| 0x14075B2E0 | NDefines::CDefineRegistryHelper_NAIAI_WANTED_LAND_BASED_PLANES_…::[0] 业务 defines 注册/读取族 |
| 0x140820090 | NDefines::CDefineRegistryHelper_NDiplomacyNAVAL_BLOCKADE_DAILY_…::[0] 业务 defines 注册/读取族 |
| 0x1408684E0 | NDefines::CDefineRegistryHelper_NGraphicsRAID_UNIT_ENTITY_BASE_…::[0] 业务 defines 注册/读取族 |
| 0x140952590 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_SUB_DETEC…::[0] 业务 defines 注册/读取族 |
| 0x14096A750 | NDefines::CDefineRegistryHelper_NNavyWAR_SCORE_GAIN_FOR_SUNK_CO…::[0] 业务 defines 注册/读取族 |
| 0x140750930 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_RAILWAY_CONNE…::[0] 业务 defines 注册/读取族 |
| 0x140943050 | NDefines::CDefineRegistryHelper_NNavyDOMINANCE_EFFECT_ON_POSITI…::[0] 业务 defines 注册/读取族 |
| 0x140948FC0 | NDefines::CDefineRegistryHelper_NNavyMANPOWER_LOSS_RATIO_ON_STR…::[0] 业务 defines 注册/读取族 |
| 0x1408A2F40 | NDefines::CDefineRegistryHelper_NInterfaceFLEET_BOTTOM_BAR_HEIG…::[0] 业务 defines 注册/读取族 |
| 0x1407AAF80 | NDefines::CDefineRegistryHelper_NAINAVAL_INVADED_AREA_PRIO_DURA…::[0] 业务 defines 注册/读取族 |
| 0x140938320 | NDefines::CDefineRegistryHelper_NNavyBEST_CAPITALS_TO_CARRIER_R…::[0] 业务 defines 注册/读取族 |
| 0x14094B080 | NDefines::CDefineRegistryHelper_NNavyMAX_POSITIONING_PENALTY_FR…::[0] 业务 defines 注册/读取族 |
| 0x140993C00 | NDefines::CDefineRegistryHelper_NRaidsRAID_TARGET_ITEM_POOL_SIZE::[0] 业务 defines 注册/读取族 |
| 0x14081AE10 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_RATIO_CONTR…::[0] 业务 defines 注册/读取族 |
| 0x1409AD190 | NDefines::CDefineRegistryHelper_NSupplyNODE_FLOW_BONUS_PER_RAIL…::[0] 业务 defines 注册/读取族 |
| 0x140816F80 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_POWER_ARMY_WE…::[0] 业务 defines 注册/读取族 |
| 0x140978470 | NDefines::CDefineRegistryHelper_NOperativesMAX_OPERATIVE_SLOT_F…::[0] 业务 defines 注册/读取族 |
| 0x14082DDC0 | NDefines::CDefineRegistryHelper_NDoctrinesMASTERY_BANK_MAX::[0] 业务 defines 注册/读取族 |
| 0x140978730 | NDefines::CDefineRegistryHelper_NOperativesMAX_RECRUITED_OPERAT…::[0] 业务 defines 注册/读取族 |
| 0x140753AB0 | NDefines::CDefineRegistryHelper_NAIAIFC_UNIT_NUDGE_FREQUENCY_DA…::[0] 业务 defines 注册/读取族 |
| 0x140983D20 | NDefines::CDefineRegistryHelper_NProductionCIC_BANK_SPEED_BOOST…::[0] 业务 defines 注册/读取族 |
| 0x1409AC3D0 | NDefines::CDefineRegistryHelper_NSupplyNAVAL_DISTANCE_FACTOR_FO…::[0] 业务 defines 注册/读取族 |
| 0x14076ED80 | NDefines::CDefineRegistryHelper_NAICONVOY_DANGER_FOR_MAX_IMPORT…::[0] 业务 defines 注册/读取族 |
| 0x140773030 | NDefines::CDefineRegistryHelper_NAIDEFAULT_LEGACY_VARIANT_CREAT…::[0] 业务 defines 注册/读取族 |
| 0x140773870 | NDefines::CDefineRegistryHelper_NAIDEFAULT_MODULE_VARIANT_CREAT…::[0] 业务 defines 注册/读取族 |
| 0x1407BB230 | NDefines::CDefineRegistryHelper_NAIRAIDS_COMMAND_POWER_CAP_TO_C…::[0] 业务 defines 注册/读取族 |
| 0x140819AD0 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_MINOR_FACTOR::[0] 业务 defines 注册/读取族 |
| 0x14087ED30 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationFUNDS_FO…::[0] 业务 defines 注册/读取族 |
| 0x14096F910 | NDefines::CDefineRegistryHelper_NOperativesCOUNTER_INTELLIGENCE…::[0] 业务 defines 注册/读取族 |
| 0x1408003F0 | NDefines::CDefineRegistryHelper_NCountryGIE_MANPOWER_GAIN_PENAL…::[0] 业务 defines 注册/读取族 |
| 0x14095C0A0 | NDefines::CDefineRegistryHelper_NNavyNAVY_SPOTTER_DETECTION_FAC…::[0] 业务 defines 注册/读取族 |
| 0x14098C720 | NDefines::CDefineRegistryHelper_NProjectDEFAULT_EMPTY_REWARD_WE…::[0] 业务 defines 注册/读取族 |
| 0x1409AA030 | NDefines::CDefineRegistryHelper_NSupplyFLOATING_HARBOR_MIN_DECAY::[0] 业务 defines 注册/读取族 |
| 0x14076E800 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_SUPPLY_BUI…::[0] 业务 defines 注册/读取族 |
| 0x140958840 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINES_IN_REGION_MAX::[0] 业务 defines 注册/读取族 |
| 0x14085DAF0 | NDefines::CDefineRegistryHelper_NGraphicsMIN_TRAIN_WAGON_COUNT::[0] 业务 defines 注册/读取族 |
| 0x1409B5C10 | NDefines::CDefineRegistryHelper_NTechnologyUSE_BONUS_REGRET_TIM…::[0] 业务 defines 注册/读取族 |
| 0x1407E8A20 | NDefines::CDefineRegistryHelper_NAirMISSILE_LAUNCHER_CAPACITY::[0] 业务 defines 注册/读取族 |
| 0x140894E90 | NDefines::CDefineRegistryHelper_NIntelLAND_COMBAT_AIR_INTEL_OVE…::[0] 业务 defines 注册/读取族 |
| 0x14081A890 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_PER_ADJACEN…::[0] 业务 defines 注册/读取族 |
| 0x140932430 | NDefines::CDefineRegistryHelper_NNavyAIR_SPOTTER_DETECTION_FACT…::[0] 业务 defines 注册/读取族 |
| 0x1409A8D10 | NDefines::CDefineRegistryHelper_NSupplyFLOATING_HARBOR_BASE_SUP…::[0] 业务 defines 注册/读取族 |
| 0x1407901B0 | NDefines::CDefineRegistryHelper_NAIINDUSTRIAL_ORG_TRAIT_RANK_FA…::[0] 业务 defines 注册/读取族 |
| 0x140996D60 | NDefines::CDefineRegistryHelper_NRailwayGunDISBAND_MANPOWER_LOSS::[0] 业务 defines 注册/读取族 |
| 0x1409A82C0 | NDefines::CDefineRegistryHelper_NSupplyDEFAULT_STARTING_TRUCK_R…::[0] 业务 defines 注册/读取族 |
| 0x14096E050 | NDefines::CDefineRegistryHelper_NOperativesBOOST_IDEOLOGY_NETWO…::[0] 业务 defines 注册/读取族 |
| 0x140791020 | NDefines::CDefineRegistryHelper_NAIINVASION_TARGET_NO_PORT_FACT…::[0] 业务 defines 注册/读取族 |
| 0x1407CEA00 | NDefines::CDefineRegistryHelper_NAIWANTED_CARRIER_PLANES_PER_CA…::[0] 业务 defines 注册/读取族 |
| 0x1407C18F0 | NDefines::CDefineRegistryHelper_NAIRESEARCH_WITH_XP_AI_WEIGHT_M…::[0] 业务 defines 注册/读取族 |
| 0x1407CEF80 | NDefines::CDefineRegistryHelper_NAIWANTED_LAND_PLANES_PER_DIVIS…::[0] 业务 defines 注册/读取族 |
| 0x1409A6480 | NDefines::CDefineRegistryHelper_NSupplyCAPITAL_INITIAL_SUPPLY_F…::[0] 业务 defines 注册/读取族 |
| 0x1407BACB0 | NDefines::CDefineRegistryHelper_NAIRAIDS_AVOID_SAME_TARGET_FACT…::[0] 业务 defines 注册/读取族 |
| 0x1407E8340 | NDefines::CDefineRegistryHelper_NAirMAX_QUICK_WING_SELECTION::[0] 业务 defines 注册/读取族 |
| 0x140895150 | NDefines::CDefineRegistryHelper_NIntelLAND_COMBAT_ARMY_INTEL_FA…::[0] 业务 defines 注册/读取族 |
| 0x140755B90 | NDefines::CDefineRegistryHelper_NAIAIFC_UPDATE_FREQUENCY_DAYS::[0] 业务 defines 注册/读取族 |
| 0x1407DC720 | NDefines::CDefineRegistryHelper_NAirCOMBAT_DAMAGE_SCALE_CARRIER::[0] 业务 defines 注册/读取族 |
| 0x140892CE0 | NDefines::CDefineRegistryHelper_NIntelINTEL_NETWORK_MAX_ARMY_IN…::[0] 业务 defines 注册/读取族 |
| 0x140893260 | NDefines::CDefineRegistryHelper_NIntelINTEL_NETWORK_MAX_NAVY_IN…::[0] 业务 defines 注册/读取族 |
| 0x140837D40 | NDefines::CDefineRegistryHelper_NFactionsMAX_NUM_LONG_TERM_GOALS::[0] 业务 defines 注册/读取族 |
| 0x1409A5F00 | NDefines::CDefineRegistryHelper_NSupplyBUILT_NODE_BASE_SUPPLY_A…::[0] 业务 defines 注册/读取族 |
| 0x1408A5E00 | NDefines::CDefineRegistryHelper_NInterfaceMIO_CENTRAL_TREE_HORI…::[0] 业务 defines 注册/读取族 |
| 0x140906920 | NDefines::CDefineRegistryHelper_NMilitaryCOMMS_MAX_DISTANCE::[0] 业务 defines 注册/读取族 |
| 0x140935A80 | NDefines::CDefineRegistryHelper_NNavyBASE_JOIN_COMBAT_HOURS::[0] 业务 defines 注册/读取族 |
| 0x1409B2CC0 | NDefines::CDefineRegistryHelper_NSupplyTRAIN_ANTI_AIR_HIT_CHANCE::[0] 业务 defines 注册/读取族 |
| 0x1407DA830 | NDefines::CDefineRegistryHelper_NAirBIGGEST_SPEED_FACTOR_DIFF::[0] 业务 defines 注册/读取族 |
| 0x1407FEFF0 | NDefines::CDefineRegistryHelper_NCountryGIE_EXILE_TRANSFER_ON_L…::[0] 业务 defines 注册/读取族 |
| 0x1408A7140 | NDefines::CDefineRegistryHelper_NInterfaceMISSION_PATROL_SOFT_R…::[0] 业务 defines 注册/读取族 |
| 0x1408A9C10 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_TRADE_INFLU…::[0] 业务 defines 注册/读取族 |
| 0x14074FE30 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_ADJ_STRAIT::[0] 业务 defines 注册/读取族 |
| 0x140751430 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_TRN_JUNGLE::[0] 业务 defines 注册/读取族 |
| 0x1408805F0 | NDefines::CDefineRegistryHelper_NIntelAIR_COMBAT_AIR_INTEL_FACT…::[0] 业务 defines 注册/读取族 |
| 0x14097EAE0 | NDefines::CDefineRegistryHelper_NOperativesTECH_STEAL_YEAR_FACT…::[0] 业务 defines 注册/读取族 |
| 0x1409ADEA0 | NDefines::CDefineRegistryHelper_NSupplyNUM_RAILWAYS_TRAIN_FACTOR::[0] 业务 defines 注册/读取族 |
| 0x140798440 | NDefines::CDefineRegistryHelper_NAILAND_DESIGN_DEMAND_ABSENT::[0] 业务 defines 注册/读取族 |
| 0x140897BF0 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_CIVILIAN_INT…::[0] 业务 defines 注册/读取族 |
| 0x1408A8210 | NDefines::CDefineRegistryHelper_NInterfaceOPERATIVE_BOOST_IDEOL…::[0] 业务 defines 注册/读取族 |
| 0x1407AE9F0 | NDefines::CDefineRegistryHelper_NAINAVY_CHIEF_SCORE_MULTIPLIER::[0] 业务 defines 注册/读取族 |
| 0x14095E250 | NDefines::CDefineRegistryHelper_NNavyRADAR_DOMINANCE_FACTOR::[0] 业务 defines 注册/读取族 |
| 0x14082EB80 | NDefines::CDefineRegistryHelper_NDoctrinesMIN_MASTERY_GAIN_PER_…::[0] 业务 defines 注册器 NDoctrines.MIN_MASTERY_GAIN_PER_DAY |
| 0x140783760 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_EQUIPMENT_S…::[0] 业务 defines 注册器 NAI.EQUIPMENT_MARKET_EQUIPMENT_SUNK_TO_CANCEL |
| 0x14099DA90 | NDefines::CDefineRegistryHelper_NResistanceRESISTANCE_COOLDOWN_…::[0] 业务 defines 注册器 NResistance.RESISTANCE_COOLDOWN_WHEN_DISABLED |
| 0x14075B020 | NDefines::CDefineRegistryHelper_NAIAI_WANTED_CARRIER_BASED_PLAN…::[0] 业务 defines 注册器 NAI.AI_WANTED_CARRIER_BASED_PLANES_FACTOR |
| 0x1407AD130 | NDefines::CDefineRegistryHelper_NAINAVAL_PATROL_PLANES_PER_SHIP…::[0] 业务 defines 注册器 NAI.NAVAL_PATROL_PLANES_PER_SHIP_ESCORTING |
| 0x140817240 | NDefines::CDefineRegistryHelper_NDiplomacyFACTION_POWER_EFFECTS…::[0] 业务 defines 注册器 NDiplomacy.FACTION_POWER_EFFECTS_WEIGHT |
| 0x1409A61C0 | NDefines::CDefineRegistryHelper_NSupplyCAPITAL_ADDED_PENALTY_PE…::[0] 业务 defines 注册器 NSupply.CAPITAL_ADDED_PENALTY_PER_PROVINCE |
| 0x1409B4DA0 | NDefines::CDefineRegistryHelper_NTechnologyDEFAULT_XP_BOOST_RES…::[0] 业务 defines 注册器 NTechnology.DEFAULT_XP_BOOST_RESEARCH_COST |
| 0x1407FFDB0 | NDefines::CDefineRegistryHelper_NCountryGIE_HOST_MIC_FROM_LEGIT…::[0] 业务 defines 注册器 NCountry.GIE_HOST_MIC_FROM_LEGITIMACY_MAX |
| 0x14076E540 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_RAILWAY_GU…::[0] 业务 defines 注册器 NAI.CONSTRUCTION_PRIO_RAILWAY_GUN_REPAIR |
| 0x1409B2A00 | NDefines::CDefineRegistryHelper_NSupplyTRAIN_ANTI_AIR_ATTACK_TO…::[0] 业务 defines 注册器 NSupply.TRAIN_ANTI_AIR_ATTACK_TO_AMOUNT |
| 0x14097CE00 | NDefines::CDefineRegistryHelper_NOperativesPROPAGANDA_DEFENSE_F…::[0] 业务 defines 注册器 NOperatives.PROPAGANDA_DEFENSE_FACTOR |
| 0x1407FE2E0 | NDefines::CDefineRegistryHelper_NCountryGIE_ESCAPING_DIVISIONS_…::[0] 业务 defines 注册器 NCountry.GIE_ESCAPING_DIVISIONS_XP_BOOST |
| 0x140819550 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_MAX_DIST_CO…::[0] 业务 defines 注册器 NDiplomacy.INFLUENCE_MAX_DIST_CORE |
| 0x140892FA0 | NDefines::CDefineRegistryHelper_NIntelINTEL_NETWORK_MAX_CIVILIA…::[0] 业务 defines 注册器 NIntel.INTEL_NETWORK_MAX_CIVILIAN_INTEL |
| 0x14096E890 | NDefines::CDefineRegistryHelper_NOperativesCONTROL_TRADE_DAILY_…::[0] 业务 defines 注册器 NOperatives.CONTROL_TRADE_DAILY_XP_GAIN |
| 0x14081AB50 | NDefines::CDefineRegistryHelper_NDiplomacyINFLUENCE_RATIO_CAPIT…::[0] 业务 defines 注册器 NDiplomacy.INFLUENCE_RATIO_CAPITAL |
| 0x140896E30 | NDefines::CDefineRegistryHelper_NIntelNAVAL_COMBAT_ARMY_INTEL_F…::[0] 业务 defines 注册器 NIntel.NAVAL_COMBAT_ARMY_INTEL_FACTOR |
| 0x14094FD20 | NDefines::CDefineRegistryHelper_NNavyNAVAL_BASE_DOMINANCE_FACTOR::[0] 业务 defines 注册器 NNavy.NAVAL_BASE_DOMINANCE_FACTOR |
| 0x1409A8000 | NDefines::CDefineRegistryHelper_NSupplyDEFAULT_STARTING_TRAIN_R…::[0] 业务 defines 注册器 NSupply.DEFAULT_STARTING_TRAIN_RATIO |
| 0x14097CB40 | NDefines::CDefineRegistryHelper_NOperativesPROPAGANDA_DAILY_XP_…::[0] 业务 defines 注册器 NOperatives.PROPAGANDA_DAILY_XP_GAIN |
| 0x1408FBB00 | NDefines::CDefineRegistryHelper_NMarketHIGH_PRICE_LEVEL_FACTOR::[0] 业务 defines 注册器 NMarket.HIGH_PRICE_LEVEL_FACTOR |
| 0x1409AC950 | NDefines::CDefineRegistryHelper_NSupplyNAVAL_NODE_BASE_SUPPLY_A…::[0] 业务 defines 注册器 NSupply.NAVAL_NODE_BASE_SUPPLY_ADD |
| 0x14076CF40 | NDefines::CDefineRegistryHelper_NAICONSTRUCTION_PRIO_CIV_FACTORY::[0] 业务 defines 注册器 NAI.CONSTRUCTION_PRIO_CIV_FACTORY |
| 0x140750BF0 | NDefines::CDefineRegistryHelper_NAIAIFC_PATH_COST_TRN_DESERT::[0] 业务 defines 注册器 NAI.AIFC_PATH_COST_TRN_DESERT |
| 0x1407567D0 | NDefines::CDefineRegistryHelper_NAIAIR_CHIEF_SCORE_MULTIPLIER::[0] 业务 defines 注册器 NAI.AIR_CHIEF_SCORE_MULTIPLIER |
| 0x1407DC460 | NDefines::CDefineRegistryHelper_NAirCOMBAT_DAMAGE_SCALE::[0] 业务 defines 注册器 NAir.COMBAT_DAMAGE_SCALE |
| 0x1407C10D0 | NDefines::CDefineRegistryHelper_NAIRESEARCH_NEEDS_FACTOR::[0] 业务 defines 注册器 NAI.RESEARCH_NEEDS_FACTOR |
| 0x1409AE160 | NDefines::CDefineRegistryHelper_NSupplyRAILWAY_BASE_FLOW::[0] 业务 defines 注册器 NSupply.RAILWAY_BASE_FLOW |
| 0x1408FBDC0 | NDefines::CDefineRegistryHelper_NMarketIC_TO_CIC_FACTOR::[0] 业务 defines 注册器 NMarket.IC_TO_CIC_FACTOR |
| 0x14074C4B0 | NDefines::CDefineRegistryHelper_NAIACCESS_SCORE_FOR_DEMOCRATIC_…::[0] 业务 defines 注册器 NAI.ACCESS_SCORE_FOR_DEMOCRATIC_COUNTRIES |
| 0x14075CE60 | NDefines::CDefineRegistryHelper_NAIAREA_DEFENSE_MINCAP_DESI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:966 |
| 0x14075F220 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_ARMOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:947 |
| 0x140768310 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_DEMOCRATIC_DES… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:156 |
| 0x1407690B0 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_OVERLORD_INVIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:161 |
| 0x140770BC0 | NDefines::CDefineRegistryHelper_NAICRYPTO_ACTIVATION_SCORE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:852 |
| 0x140770FE0 | NDefines::CDefineRegistryHelper_NAICRYPTO_ACTIVATION_THRESH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:845 |
| 0x140784F30 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_SCORE_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:104 |
| 0x1407937E0 | NDefines::CDefineRegistryHelper_NAILAND_COMBAT_CAS_PLANES_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:498 |
| 0x1407B8B00 | NDefines::CDefineRegistryHelper_NAIPORT_STRIKE_PLANES_PER_S… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:462 |
| 0x1407BCF80 | NDefines::CDefineRegistryHelper_NAIRAILWAY_GUN_PRODUCTION_B… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:381 |
| 0x1407BE630 | NDefines::CDefineRegistryHelper_NAIREGION_CONVOY_DANGER_DAI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:348 |
| 0x1407BF970 | NDefines::CDefineRegistryHelper_NAIREQUEST_LEND_LEASE_PROTE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:435 |
| 0x1407C2EF0 | NDefines::CDefineRegistryHelper_NAISCARY_LEVEL_AVERAGE_DEFE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:410 |
| 0x1407C9BE0 | NDefines::CDefineRegistryHelper_NAITRANSPORTS_PER_PARATROOP… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:360 |
| 0x1407D3390 | NDefines::CDefineRegistryHelper_NAirAIR_COMBAT_FINAL_DAMAGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:542 |
| 0x1407DB3E0 | NDefines::CDefineRegistryHelper_NAirCARRIER_PERCENTAGE_DEFE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:484 |
| 0x1407DE820 | NDefines::CDefineRegistryHelper_NAirDISRUPTION_AGILITY_FACT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:580 |
| 0x140844130 | NDefines::CDefineRegistryHelper_NGraphicsARROW_MOVEMENT_SPE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:119 |
| 0x140846650 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_SELEC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:165 |
| 0x140848120 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_SELEC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:156 |
| 0x14084C320 | NDefines::CDefineRegistryHelper_NGraphicsCOUNTRY_FLAG_MEDIU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:233 |
| 0x140852410 | NDefines::CDefineRegistryHelper_NGraphicsFRONTS_MOUSE_INTER… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:447 |
| 0x14085F670 | NDefines::CDefineRegistryHelper_NGraphicsNAVAL_MINES_CLUMPI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:271 |
| 0x1408625E0 | NDefines::CDefineRegistryHelper_NGraphicsPOLITICAL_GRID_SMA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:456 |
| 0x1408627F0 | NDefines::CDefineRegistryHelper_NGraphicsPOLITICAL_PULSE_BA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:458 |
| 0x140866ED0 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_LAND_US… 业务 NDefines 定义注册表读取（vtable 槽0）· raid_defines.h:53 |
| 0x140888520 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_FUEL_INTEL_R… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:102 |
| 0x14088A620 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_MIN_INTEL_TO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:123 |
| 0x140894700 | NDefines::CDefineRegistryHelper_NIntelINTEL_TO_SHOW_TECH_CO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:75 |
| 0x1408A4120 | NDefines::CDefineRegistryHelper_NInterfaceLOGISTICS_PAST_WE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:472 |
| 0x1408AC080 | NDefines::CDefineRegistryHelper_NInterfaceTOOLTIP_SCREEN_RI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:484 |
| 0x1408ADF70 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_N… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:166 |
| 0x1408B31F0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_MILITAR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:178 |
| 0x1408CBDF0 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:186 |
| 0x1408DBDB0 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:184 |
| 0x1408DCE30 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:184 |
| 0x140913530 | NDefines::CDefineRegistryHelper_NMilitaryMAX_CAPTAIN_EXPERI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:340 |
| 0x14091A8B0 | NDefines::CDefineRegistryHelper_NMilitaryOVERSEAS_LOSE_EQUI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:191 |
| 0x14093AB70 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_DAMAGE_RANDOMNE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:662 |
| 0x140958210 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINES_ACCIDENT_S… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:804 |
| 0x14095B440 | NDefines::CDefineRegistryHelper_NNavyNAVY_REPAIR_BASE_PRIOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:797 |
| 0x1409A9810 | NDefines::CDefineRegistryHelper_NSupplyFLOATING_HARBOR_DECA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_supply.h:47 |
| 0x1407ADB80 | NDefines::CDefineRegistryHelper_NAINAVAL_SHIP_AIR_IMPORTANC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:443 |
| 0x1407F1920 | NDefines::CDefineRegistryHelper_NCareerProfileGUIAWARD_POPU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_career_profile.h:7 |
| 0x14080FD80 | NDefines::CDefineRegistryHelper_NDiplomacyAUTONOMY_LEVEL_CH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:158 |
| 0x140812AE0 | NDefines::CDefineRegistryHelper_NDiplomacyBASE_TRUCE_PERIOD… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:12 |
| 0x14081E0F0 | NDefines::CDefineRegistryHelper_NDiplomacyMAX_OPINION_VALUE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:10 |
| 0x140827000 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_ANNEX_COR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:106 |
| 0x140828C10 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_NO_CB_WAR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:97 |
| 0x140829030 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_PEACE_FAC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:113 |
| 0x140830440 | NDefines::CDefineRegistryHelper_NFactionsAI_PICK_FROM_TOP_A… 业务 NDefines 定义注册表读取（vtable 槽0）· faction_defines.h:94 |
| 0x1408314C0 | NDefines::CDefineRegistryHelper_NFactionsAI_PING_NAVAL_DOMI… 业务 NDefines 定义注册表读取（vtable 槽0）· faction_defines.h:36 |
| 0x14083DE20 | NDefines::CDefineRegistryHelper_NFrontendSOCIALVIEW_CONTEXT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_frontend.h:35 |
| 0x140840400 | NDefines::CDefineRegistryHelper_NGameMAJOR_PARTICIPANTS_FOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:16 |
| 0x14086A280 | NDefines::CDefineRegistryHelper_NGraphicsRAILWAY_ICON_SHIFT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:635 |
| 0x1408E9C70 | NDefines::CDefineRegistryHelper_NMapIconsSUPPLY_AREAS_PRIOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:168 |
| 0x1409030E0 | NDefines::CDefineRegistryHelper_NMilitaryBORDER_WAR_VICTORY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:188 |
| 0x140932BC0 | NDefines::CDefineRegistryHelper_NNavyALL_SHIPS_ACTIVATE_TIM… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1110 |
| 0x140980660 | NDefines::CDefineRegistryHelper_NPoliticsNUM_OCCUPATION_POL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:304 |
| 0x14079F990 | NDefines::CDefineRegistryHelper_NAIMAX_SCREEN_TASKFORCES_FO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:655 |
| 0x1407F83B0 | NDefines::CDefineRegistryHelper_NCountryBOMBING_WAR_SUPPORT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:135 |
| 0x14086FD40 | NDefines::CDefineRegistryHelper_NGraphicsSHOW_ONLY_PATH_ABO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:316 |
| 0x140981B00 | NDefines::CDefineRegistryHelper_NProductionBASE_FACTORY_EFF… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:213 |
| 0x140984770 | NDefines::CDefineRegistryHelper_NProductionEFFICIENCY_LOSS_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:199 |
| 0x140761EB0 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_INVAS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:923 |
| 0x140764F80 | NDefines::CDefineRegistryHelper_NAIASSIGN_DEFENSE_TERRAIN_A… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:541 |
| 0x140766000 | NDefines::CDefineRegistryHelper_NAIASSIGN_FRONT_TERRAIN_MOV… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:540 |
| 0x1407694D0 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_RELATIVE_ARMY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:165 |
| 0x14076FF60 | NDefines::CDefineRegistryHelper_NAICRITICAL_DECISION_PRIORI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:565 |
| 0x140775130 | NDefines::CDefineRegistryHelper_NAIDEMOCRACIES_BEFRIEND_COM… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:260 |
| 0x14077FBB0 | NDefines::CDefineRegistryHelper_NAIDIPLO_DISTANCE_BETWEEN_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:285 |
| 0x1407884B0 | NDefines::CDefineRegistryHelper_NAIFASCISTS_ANTAGONIZE_DEMO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:256 |
| 0x14078BA50 | NDefines::CDefineRegistryHelper_NAIFUEL_RATIO_TO_EXIST_FUEL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:702 |
| 0x1407A1A90 | NDefines::CDefineRegistryHelper_NAIMINES_PLANTING_PLANES_PE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:464 |
| 0x1407D70C0 | NDefines::CDefineRegistryHelper_NAirAIR_WING_MAX_STATS_SPEE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:467 |
| 0x1407D8070 | NDefines::CDefineRegistryHelper_NAirAIR_WING_XP_RECON_MISSI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:572 |
| 0x1407ED1A0 | NDefines::CDefineRegistryHelper_NAirSTRATEGIC_BOMBING_STATE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:618 |
| 0x140844D90 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_BORDE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:181 |
| 0x14085DDB0 | NDefines::CDefineRegistryHelper_NGraphicsMOON_DIFFUSE_COLOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:351 |
| 0x140883140 | NDefines::CDefineRegistryHelper_NIntelARMY_AVG_ARMOR_INTEL_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:221 |
| 0x1408BFA00 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:174 |
| 0x1408D3380 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_N… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:185 |
| 0x1408D6500 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:171 |
| 0x1408DA4F0 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:184 |
| 0x1408DC5F0 | NDefines::CDefineRegistryHelper_NMapIconsSTART_CONSTRUCTION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:184 |
| 0x1408F0D50 | NDefines::CDefineRegistryHelper_NMapModeFABRICATE_CLAIM_TAR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:57 |
| 0x140904DA0 | NDefines::CDefineRegistryHelper_NMilitaryCOMBAT_OVER_WIDTH_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:275 |
| 0x1409164A0 | NDefines::CDefineRegistryHelper_NMilitaryMIN_BALANCE_SCORE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:324 |
| 0x14091F240 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_CONSIDERED_BA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:196 |
| 0x140923020 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_PROVINCE_PRIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:232 |
| 0x140942030 | NDefines::CDefineRegistryHelper_NNavyDETECTION_CHANCE_MULT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:667 |
| 0x1409573A0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_INVASION_PLAN_CA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:751 |
| 0x14095A7E0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_TRANSFER_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:642 |
| 0x1409B7BB0 | NDefines::CDefineRegistryHelper_NWikiFORUM_URL::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:350 |
| 0x140768EA0 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_NEUTRAL_DESIRE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:157 |
| 0x1407793E0 | NDefines::CDefineRegistryHelper_NAIDIFFERENT_FACTION_THREAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:191 |
| 0x14081E510 | NDefines::CDefineRegistryHelper_NDiplomacyMAX_SCORE_DIFF_TO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:161 |
| 0x14082AD10 | NDefines::CDefineRegistryHelper_NDiplomacyVERY_BAD_OPINION:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:85 |
| 0x14083E030 | NDefines::CDefineRegistryHelper_NFrontendSOCIALVIEW_CONTEXT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_frontend.h:34 |
| 0x140840A30 | NDefines::CDefineRegistryHelper_NGameMAX_SCRIPTED_LOC_RECUR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:26 |
| 0x14086A6A0 | NDefines::CDefineRegistryHelper_NGraphicsRAILWAY_MAP_ARROW_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:56 |
| 0x1408A38E0 | NDefines::CDefineRegistryHelper_NInterfaceFUEL_GRAPH_COLOR:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:532 |
| 0x1408B73F0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_NAVY_PR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:177 |
| 0x1408EBD70 | NDefines::CDefineRegistryHelper_NMapIconsSUPPLY_AREAS_PRIOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:168 |
| 0x1408F38A0 | NDefines::CDefineRegistryHelper_NMapModeNAVAL_REGION_ACCESS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:101 |
| 0x140938110 | NDefines::CDefineRegistryHelper_NNavyBATTLE_NAME_VP_FACTOR:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:736 |
| 0x14077E0E0 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_SEND_MAX_FACTI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:26 |
| 0x1407E2600 | NDefines::CDefineRegistryHelper_NAirGfxAIRPLANES_1_FIGHTER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:25 |
| 0x1407F7540 | NDefines::CDefineRegistryHelper_NCountryBASE_MAX_COMMAND_PO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:169 |
| 0x14080B990 | NDefines::CDefineRegistryHelper_NCountrySTARTING_COMMAND_PO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:168 |
| 0x1408430B0 | NDefines::CDefineRegistryHelper_NGraphicsAMBIENT_LIGHT_NEG_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:347 |
| 0x140875800 | NDefines::CDefineRegistryHelper_NGraphicsSUPPLY_UNIT_COUNTE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:642 |
| 0x140877D20 | NDefines::CDefineRegistryHelper_NGraphicsTRADE_ROUTE_LEND_L… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:383 |
| 0x14087BDC0 | NDefines::CDefineRegistryHelper_NGraphicsVICTORY_POINT_MAP_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:241 |
| 0x140901610 | NDefines::CDefineRegistryHelper_NMilitaryATTRITION_WHILE_MO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:78 |
| 0x140925800 | NDefines::CDefineRegistryHelper_NMilitaryRELIABILTY_RECOVER… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:83 |
| 0x1409706B0 | NDefines::CDefineRegistryHelper_NOperativesCRYPTO_CRYPTO_AC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:453 |
| 0x14097A780 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_BASE_I… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:418 |
| 0x140987280 | NDefines::CDefineRegistryHelper_NProductionLICENSE_EQUIPMEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:242 |
| 0x140987490 | NDefines::CDefineRegistryHelper_NProductionLICENSE_IC_COST_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:237 |
| 0x140777910 | NDefines::CDefineRegistryHelper_NAIDESIRE_USE_XP_TO_UNLOCK_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:136 |
| 0x14079E5C0 | NDefines::CDefineRegistryHelper_NAIMAX_PORT_STRIKE_HISTORY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:809 |
| 0x1407A3980 | NDefines::CDefineRegistryHelper_NAIMIN_CONVOY_EFFICIENCY_PE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:818 |
| 0x1407B1960 | NDefines::CDefineRegistryHelper_NAIOIL_WANT_PER_POTENTIAL_N… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:734 |
| 0x1407BEA50 | NDefines::CDefineRegistryHelper_NAIREGION_THREAT_LEVEL_TO_B… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:347 |
| 0x1407DF8A0 | NDefines::CDefineRegistryHelper_NAirDISRUPTION_SPEED_FACTOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:579 |
| 0x1407E19A0 | NDefines::CDefineRegistryHelper_NAirFIELD_EXPERIENCE_FACTOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:457 |
| 0x14081E930 | NDefines::CDefineRegistryHelper_NDiplomacyMIN_OPINION_VALUE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:11 |
| 0x140846020 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_DEMIL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:177 |
| 0x14084CF80 | NDefines::CDefineRegistryHelper_NGraphicsCOUNTRY_FLAG_TEX_H… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:230 |
| 0x140854510 | NDefines::CDefineRegistryHelper_NGraphicsGRADIENT_BORDERS_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:198 |
| 0x14085F460 | NDefines::CDefineRegistryHelper_NGraphicsNAVAL_COMBAT_DISTA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:258 |
| 0x140881CA0 | NDefines::CDefineRegistryHelper_NIntelAIR_MAPICON_MISSION_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:208 |
| 0x1408897B0 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_MANPOWER_RAN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:119 |
| 0x14089EAF0 | NDefines::CDefineRegistryHelper_NIntelRECON_PLANE_INTEL_BAS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:63 |
| 0x1408AEFF0 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_S… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:166 |
| 0x1408B2170 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_AIR_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:176 |
| 0x1408BC880 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:173 |
| 0x1408BE980 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:174 |
| 0x1408C0A80 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:174 |
| 0x1408D8600 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:172 |
| 0x1408E5A70 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_NAVY_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:170 |
| 0x1408E6AF0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_REGIONS_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:175 |
| 0x1408FD170 | NDefines::CDefineRegistryHelper_NMarketREQUEST_AUTOMATION_A… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:271 |
| 0x140905C10 | NDefines::CDefineRegistryHelper_NMilitaryCOMBAT_SUPPLY_LACK… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:269 |
| 0x14090AB20 | NDefines::CDefineRegistryHelper_NMilitaryFIELD_EXPERIENCE_M… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:133 |
| 0x140919830 | NDefines::CDefineRegistryHelper_NMilitaryNUM_DAYS_FOR_OPERA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:329 |
| 0x140923230 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_PROVINCE_VP_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:217 |
| 0x1409276F0 | NDefines::CDefineRegistryHelper_NMilitarySOFT_ATTACK_TARGET… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:346 |
| 0x140938F80 | NDefines::CDefineRegistryHelper_NNavyCAPITAL_SHIP_COMBAT_RE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:712 |
| 0x140967940 | NDefines::CDefineRegistryHelper_NNavyTRAINING_ACCIDENT_CRIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:821 |
| 0x140809470 | NDefines::CDefineRegistryHelper_NCountryREINFORCEMENT_AIRBA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:46 |
| 0x1408CCE70 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:186 |
| 0x1408F67F0 | NDefines::CDefineRegistryHelper_NMapModeRADAR_ROTATION_SPEE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:91 |
| 0x14091C380 | NDefines::CDefineRegistryHelper_NMilitaryPARADROP_PENALTY::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:264 |
| 0x140924FC0 | NDefines::CDefineRegistryHelper_NMilitaryREINFORCE_CHANCE::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:189 |
| 0x140934A00 | NDefines::CDefineRegistryHelper_NNavyATTRITION_DAMAGE_ORG::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:832 |
| 0x14095A5D0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_TRANSFER_DAMAGE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1107 |
| 0x14075EB40 | NDefines::CDefineRegistryHelper_NAIAREA_DEFENSE_SETTING_VP:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:956 |
| 0x1407B9970 | NDefines::CDefineRegistryHelper_NAIPRODUCTION_EQUIPMENT_SUR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:50 |
| 0x1407C1390 | NDefines::CDefineRegistryHelper_NAIRESEARCH_NEW_DOCTRINE_RA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:36 |
| 0x1407E5BA0 | NDefines::CDefineRegistryHelper_NAirGfxMAX_PATROL_SCENARIOS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:44 |
| 0x1407F3C30 | NDefines::CDefineRegistryHelper_NCharacterDEFAULT_CP_COST_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_character.h:8 |
| 0x1407F60A0 | NDefines::CDefineRegistryHelper_NCountryARMY_COUNT_DAILY_LE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:186 |
| 0x14080C490 | NDefines::CDefineRegistryHelper_NCountrySUPPLY_CONVOY_FACTO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:64 |
| 0x140834E80 | NDefines::CDefineRegistryHelper_NFactionsFACTION_INTELLIGEN… 业务 NDefines 定义注册表读取（vtable 槽0）· faction_defines.h:77 |
| 0x14083A2F0 | NDefines::CDefineRegistryHelper_NFriendGUIONLINE_COLOR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_friends_handler.h:7 |
| 0x140857270 | NDefines::CDefineRegistryHelper_NGraphicsGRADIENT_BORDERS_T… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:597 |
| 0x14092EB20 | NDefines::CDefineRegistryHelper_NMilitaryWAR_SCORE_STRATEGI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:23 |
| 0x140982340 | NDefines::CDefineRegistryHelper_NProductionBASE_FACTORY_MAX… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:208 |
| 0x140778780 | NDefines::CDefineRegistryHelper_NAIDESIRE_USE_XP_TO_UPGRADE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:141 |
| 0x140778990 | NDefines::CDefineRegistryHelper_NAIDESPERATE_AI_MIN_ORG_BEF… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:602 |
| 0x1407824D0 | NDefines::CDefineRegistryHelper_NAIENEMY_PASSING_THROUGH_PL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:803 |
| 0x140796960 | NDefines::CDefineRegistryHelper_NAILAND_DEFENSE_MILITARY_FA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:472 |
| 0x14079D490 | NDefines::CDefineRegistryHelper_NAIMAX_INVASION_FRONT_SCORE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:789 |
| 0x1407B56C0 | NDefines::CDefineRegistryHelper_NAIPLAN_ATTACK_DEPTH_FACTOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:199 |
| 0x1407C9190 | NDefines::CDefineRegistryHelper_NAITOO_INSIGNIFICANT_ARMY_R… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:726 |
| 0x1407CFF50 | NDefines::CDefineRegistryHelper_NAIWANTED_UNITS_MANPOWER_DI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:305 |
| 0x1407D0580 | NDefines::CDefineRegistryHelper_NAIWANTED_UNITS_THREAT_BASE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:301 |
| 0x1407F2160 | NDefines::CDefineRegistryHelper_NCareerProfileGUIPROFILE_PI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_career_profile.h:12 |
| 0x1407FA1D0 | NDefines::CDefineRegistryHelper_NCountryCONVOY_RANGE_FACTOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:112 |
| 0x140809680 | NDefines::CDefineRegistryHelper_NCountryREINFORCEMENT_DELIV… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:47 |
| 0x140848F90 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_TUTOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:174 |
| 0x14084C110 | NDefines::CDefineRegistryHelper_NGraphicsCOUNTRY_COLOR_SATU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:431 |
| 0x14086EAB0 | NDefines::CDefineRegistryHelper_NGraphicsSETUP_SPIRIT_GRID_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:457 |
| 0x1408AF200 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_U… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:166 |
| 0x1408C2B80 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:183 |
| 0x1408C5AF0 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:180 |
| 0x1408C8E80 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:182 |
| 0x1408CC000 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:186 |
| 0x1408CEF70 | NDefines::CDefineRegistryHelper_NMapIconsPEACE_CONFERENCE_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:179 |
| 0x1408D2300 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_L… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:185 |
| 0x1408FDF30 | NDefines::CDefineRegistryHelper_NMilitaryACCLIMATIZATION_LO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:323 |
| 0x140908970 | NDefines::CDefineRegistryHelper_NMilitaryENCIRCLED_PENALTY:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:112 |
| 0x140909AA0 | NDefines::CDefineRegistryHelper_NMilitaryEQUIPMENT_REPLACEM… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:262 |
| 0x14093DAE0 | NDefines::CDefineRegistryHelper_NNavyCONVOY_EFFICIENCY_LOSS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:715 |
| 0x140942240 | NDefines::CDefineRegistryHelper_NNavyDISBAND_MANPOWER_LOSS:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:781 |
| 0x1407F64C0 | NDefines::CDefineRegistryHelper_NCountryARMY_SCORE_MULTIPLI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:53 |
| 0x14080E0A0 | NDefines::CDefineRegistryHelper_NCountryWEEKLY_STABILITY_GA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:62 |
| 0x1408BC670 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:173 |
| 0x1408D83F0 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:172 |
| 0x1407E5990 | NDefines::CDefineRegistryHelper_NAirGfxMAX_MISSILE_BOMBING_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:43 |
| 0x14080B360 | NDefines::CDefineRegistryHelper_NCountrySCORCHED_EARTH_STAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:184 |
| 0x14083CC30 | NDefines::CDefineRegistryHelper_NFrontendMP_OPTIONS_LOOK_X:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_frontend.h:28 |
| 0x140843F20 | NDefines::CDefineRegistryHelper_NGraphicsARROW_MIN_TEXT_POI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:310 |
| 0x140848B70 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_SELEC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:159 |
| 0x14085CB20 | NDefines::CDefineRegistryHelper_NGraphicsMAX_MESHES_LOADED_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:83 |
| 0x140861560 | NDefines::CDefineRegistryHelper_NGraphicsOFFENSIVE_PING_CIR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:190 |
| 0x1408646E0 | NDefines::CDefineRegistryHelper_NGraphicsPROVINCE_NAME_DRAW… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:97 |
| 0x14086B930 | NDefines::CDefineRegistryHelper_NGraphicsRAILWAY_MAP_ARROW_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:63 |
| 0x140870BB0 | NDefines::CDefineRegistryHelper_NGraphicsSTRATEGIC_AIR_COLO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:401 |
| 0x140878DA0 | NDefines::CDefineRegistryHelper_NGraphicsTRADE_ROUTE_RESOUR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:381 |
| 0x140905E20 | NDefines::CDefineRegistryHelper_NMilitaryCOMBAT_VALUE_ORG_I… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:13 |
| 0x1409166B0 | NDefines::CDefineRegistryHelper_NMilitaryMIN_DIVISION_BRIGA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:36 |
| 0x14097F3D0 | NDefines::CDefineRegistryHelper_NPoliticsBASE_POLITICAL_POW… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:296 |
| 0x14097FE20 | NDefines::CDefineRegistryHelper_NPoliticsMAX_RANDOM_LEADERS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:295 |
| 0x140980EA0 | NDefines::CDefineRegistryHelper_NProductionANNEX_FUEL_RATIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:227 |
| 0x14099A060 | NDefines::CDefineRegistryHelper_NResistanceCOMPLIANCE_GROWT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:565 |
| 0x14075BDE0 | NDefines::CDefineRegistryHelper_NAIAREA_DEFENSE_CAPITAL_PEA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:971 |
| 0x14078B840 | NDefines::CDefineRegistryHelper_NAIFUEL_CONSUMPTION_MULT_RE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:694 |
| 0x1407B54B0 | NDefines::CDefineRegistryHelper_NAIPLAN_ACTIVATION_SUPERIOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:557 |
| 0x1407B75B0 | NDefines::CDefineRegistryHelper_NAIPLAN_VALUE_BONUS_FOR_MOV… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:749 |
| 0x1407C4DE0 | NDefines::CDefineRegistryHelper_NAISTOP_TRAINING_ACTIVE_COM… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:326 |
| 0x1407C7E00 | NDefines::CDefineRegistryHelper_NAISUB_TASKFORCE_MAX_SHIP_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:622 |
| 0x14080A700 | NDefines::CDefineRegistryHelper_NCountryRESISTANCE_DECAY_WH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:40 |
| 0x14088B8B0 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_SUPPLY_RANGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:115 |
| 0x14088C930 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_TRUCKS_RANGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:107 |
| 0x1408A7DF0 | NDefines::CDefineRegistryHelper_NInterfaceNAVY_UNIT_LEADER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:469 |
| 0x1408BB5F0 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:173 |
| 0x1408BB800 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:173 |
| 0x1408BD900 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:173 |
| 0x1408D62F0 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:171 |
| 0x1408D7370 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:172 |
| 0x1408D7580 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:172 |
| 0x1408D9680 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:172 |
| 0x1408FE140 | NDefines::CDefineRegistryHelper_NMilitaryACCLIMATIZATION_SP… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:322 |
| 0x1409143A0 | NDefines::CDefineRegistryHelper_NMilitaryMAX_FIELD_EXPERIEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:337 |
| 0x14093CA60 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_RETREAT_DECISIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:695 |
| 0x140944860 | NDefines::CDefineRegistryHelper_NNavyEXPERIENCE_FACTOR_CARR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:779 |
| 0x140957190 | NDefines::CDefineRegistryHelper_NNavyNAVAL_HOMEBASE_OWNERSH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:685 |
| 0x140958000 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINES_ACCIDENT_O… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:805 |
| 0x140753D70 | NDefines::CDefineRegistryHelper_NAIAIFC_UNIT_OFFENSIVE_SCOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:1018 |
| 0x1407BE420 | NDefines::CDefineRegistryHelper_NAIREFIT_SHIP_RELUCTANCE::[… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:334 |
| 0x1407C0EC0 | NDefines::CDefineRegistryHelper_NAIRESEARCH_NAVAL_DOCTRINE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:34 |
| 0x1407E1160 | NDefines::CDefineRegistryHelper_NAirESCORT_SPEED_FACTOR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:584 |
| 0x1407F5440 | NDefines::CDefineRegistryHelper_NCountryAIR_SCORE_MULTIPLIE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:55 |
| 0x14080A4F0 | NDefines::CDefineRegistryHelper_NCountryREINFORCEMENT_THEAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:44 |
| 0x140812F00 | NDefines::CDefineRegistryHelper_NDiplomacyCAPITAL_CAPITULAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:177 |
| 0x1408C2970 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:183 |
| 0x1408C8C70 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:182 |
| 0x1408EACF0 | NDefines::CDefineRegistryHelper_NMapIconsSUPPLY_AREAS_PRIOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:168 |
| 0x1408F8A50 | NDefines::CDefineRegistryHelper_NMapModeSUPPLY_COUNTRY_BORD… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:144 |
| 0x14092A500 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_DIGIN_CAP::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:141 |
| 0x140950AE0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_COMBAT_AIR_CONVO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1081 |
| 0x14099AED0 | NDefines::CDefineRegistryHelper_NResistanceGARRISON_EQUIPME… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:591 |
| 0x14077B900 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_FACTION_GLOBAL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:74 |
| 0x1407AC6E0 | NDefines::CDefineRegistryHelper_NAINAVAL_MISSION_MINES_PLAN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:405 |
| 0x1407D35A0 | NDefines::CDefineRegistryHelper_NAirAIR_COMBAT_FINAL_DAMAGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:543 |
| 0x1407DE610 | NDefines::CDefineRegistryHelper_NAirDETECT_EFFICIENCY_RANDO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:492 |
| 0x1407EE9B0 | NDefines::CDefineRegistryHelper_NBuildingsDESTRUCTION_COOLD… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:325 |
| 0x14083EA80 | NDefines::CDefineRegistryHelper_NGameCOMBAT_LOG_MAX_MONTHS:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:18 |
| 0x14085FEB0 | NDefines::CDefineRegistryHelper_NGraphicsNAVAL_MISSION_ICON… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:264 |
| 0x140873700 | NDefines::CDefineRegistryHelper_NGraphicsSUPPLY_CONSUMER_AR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:637 |
| 0x140877900 | NDefines::CDefineRegistryHelper_NGraphicsTRADE_ROUTE_INTERS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:449 |
| 0x1408CAF80 | NDefines::CDefineRegistryHelper_NMapIconsOPERATION_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:194 |
| 0x14090F070 | NDefines::CDefineRegistryHelper_NMilitaryHOURLY_ORG_MOVEMEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:16 |
| 0x14099C160 | NDefines::CDefineRegistryHelper_NResistanceINITIAL_HISTORY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:600 |
| 0x1409B44B0 | NDefines::CDefineRegistryHelper_NTechnologyBASE_RESEARCH_PO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:282 |
| 0x1409B6500 | NDefines::CDefineRegistryHelper_NTradeBASE_LAND_TRADE_RANGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:338 |
| 0x14077CB90 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_FACTION_WAR_WA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:277 |
| 0x140787A60 | NDefines::CDefineRegistryHelper_NAIFALLBACK_LOSING_FACTOR::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:362 |
| 0x14078CAD0 | NDefines::CDefineRegistryHelper_NAIGENERATE_WARGOAL_THREAT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:218 |
| 0x1407918F0 | NDefines::CDefineRegistryHelper_NAIINVASION_UNITS_READY_AT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:786 |
| 0x1407A1880 | NDefines::CDefineRegistryHelper_NAIMINES_PLANTING_DESIRE_PE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:467 |
| 0x1407A92A0 | NDefines::CDefineRegistryHelper_NAINAVAL_BASE_RATIO_ALLOCAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:710 |
| 0x1407CE530 | NDefines::CDefineRegistryHelper_NAIWAIT_YEARS_BEFORE_FREER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:558 |
| 0x1407D18C0 | NDefines::CDefineRegistryHelper_NAirACCIDENT_CHANCE_BASE::[… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:507 |
| 0x1407D4830 | NDefines::CDefineRegistryHelper_NAirAIR_NAVAL_KAMIKAZE_LOSS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:519 |
| 0x1407EA5A0 | NDefines::CDefineRegistryHelper_NAirNAVAL_RECON_DETECTION_B… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:593 |
| 0x140863450 | NDefines::CDefineRegistryHelper_NGraphicsPOSTEFFECT_FEATHER… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:304 |
| 0x140873B20 | NDefines::CDefineRegistryHelper_NGraphicsSUPPLY_ICON_DISCON… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:630 |
| 0x1408791C0 | NDefines::CDefineRegistryHelper_NGraphicsTRAIN_MAP_SPEED::[… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:124 |
| 0x140881EB0 | NDefines::CDefineRegistryHelper_NIntelAIR_MAPICON_SHOW_ALL_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:210 |
| 0x14089AE20 | NDefines::CDefineRegistryHelper_NIntelNAVY_MAPICON_MISSION_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:200 |
| 0x1408C18F0 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:183 |
| 0x1408C1B00 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:183 |
| 0x1408C3C00 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:183 |
| 0x1408C4A70 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:180 |
| 0x1408C6B70 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:180 |
| 0x1408C7BF0 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:182 |
| 0x1408C7E00 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:182 |
| 0x1408C9F00 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:182 |
| 0x1408D20F0 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_G… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:185 |
| 0x140902690 | NDefines::CDefineRegistryHelper_NMilitaryBASE_LEADER_TRAIT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:106 |
| 0x140903500 | NDefines::CDefineRegistryHelper_NMilitaryCAPTAIN_EXPERIENCE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:338 |
| 0x140909CB0 | NDefines::CDefineRegistryHelper_NMilitaryEXILE_EQUIPMENT::[… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:156 |
| 0x1409200B0 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_MAX_PROGRESS_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:246 |
| 0x140920F20 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_PORVINCE_PORT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:216 |
| 0x140929AB0 | NDefines::CDefineRegistryHelper_NMilitaryTRAINING_EXPERIENC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:135 |
| 0x14092A920 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_EXPERIENCE_PE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:114 |
| 0x140935030 | NDefines::CDefineRegistryHelper_NNavyATTRITION_WHILE_MOVING… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:831 |
| 0x140959550 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINE_DANGER_TRIG… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:863 |
| 0x140963F70 | NDefines::CDefineRegistryHelper_NNavySPOTTING_SPEED_MULT_FO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:876 |
| 0x14097EDA0 | NDefines::CDefineRegistryHelper_NPoliticsARMY_LEADER_COST::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:297 |
| 0x140752980 | NDefines::CDefineRegistryHelper_NAIAIFC_TARGET_CAPITAL_SCOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:1034 |
| 0x140806F50 | NDefines::CDefineRegistryHelper_NCountryMIN_MANPOWER_RATIO:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:90 |
| 0x14082C3C0 | NDefines::CDefineRegistryHelper_NDiplomacyWARGOAL_COST_VOLU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:182 |
| 0x14083EC90 | NDefines::CDefineRegistryHelper_NGameDECISION_ALERT_TIMEOUT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:24 |
| 0x14094F6F0 | NDefines::CDefineRegistryHelper_NNavyNAVAL_ACCIDENTS_DAYS_T… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1091 |
| 0x1407765D0 | NDefines::CDefineRegistryHelper_NAIDEPLOY_MIN_TRAINING_PEAC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:61 |
| 0x14077AA90 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_ACCEPT_VOLUNTE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:27 |
| 0x14077DED0 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_SEND_ATTACHE_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:82 |
| 0x1407DD0C0 | NDefines::CDefineRegistryHelper_NAirCOMBAT_MAX_WINGS_AT_ONC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:531 |
| 0x140839AB0 | NDefines::CDefineRegistryHelper_NFocusFOCUS_PROGRESS_PEACE:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:345 |
| 0x140849BF0 | NDefines::CDefineRegistryHelper_NGraphicsCAMERA_OUTSIDE_MAP… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:440 |
| 0x1408687B0 | NDefines::CDefineRegistryHelper_NGraphicsRAID_UNIT_ENTITY_O… 业务 NDefines 定义注册表读取（vtable 槽0）· raid_defines.h:55 |
| 0x14086FB30 | NDefines::CDefineRegistryHelper_NGraphicsSHOW_FOREIGN_SUPPL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:315 |
| 0x140901400 | NDefines::CDefineRegistryHelper_NMilitaryATTRITION_EQUIPMEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:77 |
| 0x140910F60 | NDefines::CDefineRegistryHelper_NMilitaryLAND_COMBAT_ORG_DA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:69 |
| 0x140911170 | NDefines::CDefineRegistryHelper_NMilitaryLAND_COMBAT_ORG_DI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:60 |
| 0x14096C010 | NDefines::CDefineRegistryHelper_NOperativesAGENCY_CREATION_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:355 |
| 0x140984980 | NDefines::CDefineRegistryHelper_NProductionENERGY_COST_CAP:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:218 |
| 0x140989A00 | NDefines::CDefineRegistryHelper_NProductionPOWERED_FACTORY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:205 |
| 0x140794A70 | NDefines::CDefineRegistryHelper_NAILAND_COMBAT_INTERCEPT_PE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:504 |
| 0x1407958E0 | NDefines::CDefineRegistryHelper_NAILAND_DEFENSE_CIVIL_FACTO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:471 |
| 0x1407B6530 | NDefines::CDefineRegistryHelper_NAIPLAN_AVG_PREPARATION_TO_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:245 |
| 0x1407C71A0 | NDefines::CDefineRegistryHelper_NAISTR_BOMB_PLANES_PER_NAV_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:520 |
| 0x1407D0370 | NDefines::CDefineRegistryHelper_NAIWANTED_UNITS_MIN_DEFENCE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:309 |
| 0x1407E8810 | NDefines::CDefineRegistryHelper_NAirMIN_PLANE_COUNT_PARADRO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:609 |
| 0x14082A0B0 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_TIME_SCAL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:101 |
| 0x140847F10 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_SELEC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:157 |
| 0x14085AA20 | NDefines::CDefineRegistryHelper_NGraphicsLIGHT_SHADOW_DIREC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:109 |
| 0x14085F250 | NDefines::CDefineRegistryHelper_NGraphicsNAVALBASE_ICON_DIS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:248 |
| 0x14087A500 | NDefines::CDefineRegistryHelper_NGraphicsTREE_FADE_NEAR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:359 |
| 0x140888730 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_FUEL_RANGE_I… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:101 |
| 0x1408A3D00 | NDefines::CDefineRegistryHelper_NInterfaceGARRISON_STRENGTH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:567 |
| 0x1408CDEF0 | NDefines::CDefineRegistryHelper_NMapIconsOPERATIVES_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:186 |
| 0x1408D41F0 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_V… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:185 |
| 0x1408D5270 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:171 |
| 0x1408ECDF0 | NDefines::CDefineRegistryHelper_NMapModeAIR_RANGE_INDICATOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:94 |
| 0x140907210 | NDefines::CDefineRegistryHelper_NMilitaryCOST_INCREASE_PER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:318 |
| 0x140915840 | NDefines::CDefineRegistryHelper_NMilitaryMAX_NUM_TRAITS::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:107 |
| 0x140928770 | NDefines::CDefineRegistryHelper_NMilitarySTRATEGIC_SPEED_RA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:282 |
| 0x140930EE0 | NDefines::CDefineRegistryHelper_NNavyAGGRESSION_LEVEL_BY_MI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:924 |
| 0x140933A30 | NDefines::CDefineRegistryHelper_NNavyAMPHIBIOUS_INVADE_SPEE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:739 |
| 0x14075E0F0 | NDefines::CDefineRegistryHelper_NAIAREA_DEFENSE_SETTING_COA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:961 |
| 0x1407DCEB0 | NDefines::CDefineRegistryHelper_NAirCOMBAT_MAX_WINGS_AT_ONC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:530 |
| 0x14083F2C0 | NDefines::CDefineRegistryHelper_NGameEVENT_TIMEOUT_DEFAULT:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:22 |
| 0x1409387F0 | NDefines::CDefineRegistryHelper_NNavyCAPITAL_ONLY_COMBAT_AC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1109 |
| 0x14093C850 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_RESULT_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1094 |
| 0x140985930 | NDefines::CDefineRegistryHelper_NProductionEQUIPMENT_MODULE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:248 |
| 0x1407D37B0 | NDefines::CDefineRegistryHelper_NAirAIR_COMBAT_FINAL_DAMAGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:541 |
| 0x1407E3890 | NDefines::CDefineRegistryHelper_NAirGfxAIRPLANES_BANK_ANGLE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:17 |
| 0x1407E5570 | NDefines::CDefineRegistryHelper_NAirGfxMAX_BOMBING_SCENARIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:45 |
| 0x1407EFC40 | NDefines::CDefineRegistryHelper_NBuildingsRADAR_RANGE_MAX::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:317 |
| 0x140847AF0 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_SELEC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:151 |
| 0x14084BCF0 | NDefines::CDefineRegistryHelper_NGraphicsCOUNTRY_COLOR_BRIG… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:432 |
| 0x140893EC0 | NDefines::CDefineRegistryHelper_NIntelINTEL_TO_SHOW_IDEAS::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:83 |
| 0x1408FA050 | NDefines::CDefineRegistryHelper_NMapModeSUPPLY_STATUS_DISPL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:150 |
| 0x1408FA260 | NDefines::CDefineRegistryHelper_NMapModeUI_CONFIGURABLE_SLO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:109 |
| 0x14091B930 | NDefines::CDefineRegistryHelper_NMilitaryPARACHUTE_FAILED_S… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:145 |
| 0x14097C460 | NDefines::CDefineRegistryHelper_NOperativesOUTCOME_LEVELS::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:479 |
| 0x1409812C0 | NDefines::CDefineRegistryHelper_NProductionBASE_COUNTRY_ENE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:216 |
| 0x1409B46C0 | NDefines::CDefineRegistryHelper_NTechnologyBASE_TECH_COST::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:284 |
| 0x1409B6D40 | NDefines::CDefineRegistryHelper_NTradeMONTH_TRADE_FACTOR::[… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:335 |
| 0x1409B7580 | NDefines::CDefineRegistryHelper_NTradePUPPET_TRADE_FACTOR::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:333 |
| 0x14076C910 | NDefines::CDefineRegistryHelper_NAICOMMUNISTS_BEFRIEND_COMM… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:269 |
| 0x14078A9D0 | NDefines::CDefineRegistryHelper_NAIFRONT_EVAL_UNIT_AIR_SUP_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:759 |
| 0x14078EF20 | NDefines::CDefineRegistryHelper_NAIHIGH_PRIO_NAVAL_MISSION_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:642 |
| 0x140795AF0 | NDefines::CDefineRegistryHelper_NAILAND_DEFENSE_FIGHERS_PER… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:484 |
| 0x1407A2900 | NDefines::CDefineRegistryHelper_NAIMINIMUM_MONTHLY_LEND_LEA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:179 |
| 0x1407AA320 | NDefines::CDefineRegistryHelper_NAINAVAL_COMBAT_TRANSFER_AI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:447 |
| 0x1407B52A0 | NDefines::CDefineRegistryHelper_NAIPLAN_ACTIVATION_PLAYER_W… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:351 |
| 0x1407D16B0 | NDefines::CDefineRegistryHelper_NAirACCIDENT_CHANCE_BALANCE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:509 |
| 0x1407E93C0 | NDefines::CDefineRegistryHelper_NAirMISSION_FUEL_COSTS::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:612 |
| 0x140812090 | NDefines::CDefineRegistryHelper_NDiplomacyBASE_SEND_ATTACHE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:65 |
| 0x14082AF20 | NDefines::CDefineRegistryHelper_NDiplomacyVERY_GOOD_OPINION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:84 |
| 0x1408515A0 | NDefines::CDefineRegistryHelper_NGraphicsFACTION_PING_MAP_A… 业务 NDefines 定义注册表读取（vtable 槽0）· faction_defines.h:64 |
| 0x140869830 | NDefines::CDefineRegistryHelper_NGraphicsRAILWAY_BRIDGE_Y_O… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:128 |
| 0x140877F30 | NDefines::CDefineRegistryHelper_NGraphicsTRADE_ROUTE_LINE_O… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:372 |
| 0x14087A0E0 | NDefines::CDefineRegistryHelper_NGraphicsTRAIT_LINE_NON_ASS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:394 |
| 0x14087C3F0 | NDefines::CDefineRegistryHelper_NGraphicsWEATHER_DISTANCE_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:292 |
| 0x14088F5E0 | NDefines::CDefineRegistryHelper_NIntelDYNAMIC_INTEL_SOURCE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:273 |
| 0x1408ABE70 | NDefines::CDefineRegistryHelper_NInterfaceTOOLTIP_SCREEN_LE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:483 |
| 0x1408E07F0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_AIR_PRIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:169 |
| 0x1408FEFB0 | NDefines::CDefineRegistryHelper_NMilitaryANTI_AIR_TARGETTIN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:110 |
| 0x140900590 | NDefines::CDefineRegistryHelper_NMilitaryARMY_MAX_FUEL_FLOW… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:397 |
| 0x140926670 | NDefines::CDefineRegistryHelper_NMilitaryRIVER_SMALL_START_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:100 |
| 0x14093A960 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_CRITICAL_DAMAGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:699 |
| 0x14094E670 | NDefines::CDefineRegistryHelper_NNavyMISSION_DEFAULT_SPREAD… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:774 |
| 0x140760AE0 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_DEFEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:920 |
| 0x1407A03E0 | NDefines::CDefineRegistryHelper_NAIMAX_SUPPLY_DIVISOR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:358 |
| 0x1407B2EB0 | NDefines::CDefineRegistryHelper_NAIPEACE_AI_EVALUATE_FOR_SU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:901 |
| 0x1407E42E0 | NDefines::CDefineRegistryHelper_NAirGfxAIRPLANES_GROUND_COL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:19 |
| 0x1407FB250 | NDefines::CDefineRegistryHelper_NCountryDEFAULT_STABILITY::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:67 |
| 0x140813F80 | NDefines::CDefineRegistryHelper_NDiplomacyEMBARGO_NEIGHBOUR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:197 |
| 0x14083BBB0 | NDefines::CDefineRegistryHelper_NFrontendCAMERA_START_Y::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_frontend.h:7 |
| 0x140850F70 | NDefines::CDefineRegistryHelper_NGraphicsENEMY_COLOR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:424 |
| 0x140866050 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_BALLIST… 业务 NDefines 定义注册表读取（vtable 槽0）· raid_defines.h:38 |
| 0x1408B8CB0 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_FABRICAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:181 |
| 0x14092C1E0 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_LEADER_MODIFI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:124 |
| 0x14098AB30 | NDefines::CDefineRegistryHelper_NProjectAMOUNT_OF_SUPPORTIV… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_project.h:34 |
| 0x1407CA840 | NDefines::CDefineRegistryHelper_NAITheatreAI_THEATRE_DISTRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai_theatre.h:12 |
| 0x1407ED880 | NDefines::CDefineRegistryHelper_NAirSUPPLY_PRIO_FACTOR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:539 |
| 0x1407F81A0 | NDefines::CDefineRegistryHelper_NCountryBASE_TENSION_MAJOR_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:105 |
| 0x1408401F0 | NDefines::CDefineRegistryHelper_NGameLAG_DAYS_FOR_PAUSE::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:15 |
| 0x14084B090 | NDefines::CDefineRegistryHelper_NGraphicsCONSTRUCTION_CONVE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:419 |
| 0x140850520 | NDefines::CDefineRegistryHelper_NGraphicsDRAW_MAP_OBJECTS_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:95 |
| 0x14085E5F0 | NDefines::CDefineRegistryHelper_NGraphicsMOON_LATITUDE::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:339 |
| 0x140893CB0 | NDefines::CDefineRegistryHelper_NIntelINTEL_TO_SHOW_GRAND_D… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:79 |
| 0x14090FEE0 | NDefines::CDefineRegistryHelper_NMilitaryLAND_AIR_COMBAT_OR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:63 |
| 0x1409121F0 | NDefines::CDefineRegistryHelper_NMilitaryLEADER_EXPERIENCE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:137 |
| 0x14091B720 | NDefines::CDefineRegistryHelper_NMilitaryPARACHUTE_FAILED_M… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:144 |
| 0x14092DAA0 | NDefines::CDefineRegistryHelper_NMilitaryWAR_SCORE_LAND_IC_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:28 |
| 0x14099B0E0 | NDefines::CDefineRegistryHelper_NResistanceGARRISON_LOG_MAX… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:578 |
| 0x14075A350 | NDefines::CDefineRegistryHelper_NAIAI_SHIP_SWAP_DAMAGE_THRE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:714 |
| 0x140764D70 | NDefines::CDefineRegistryHelper_NAIASSIGN_DEFENSE_TEMPLATE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:532 |
| 0x140765DF0 | NDefines::CDefineRegistryHelper_NAIASSIGN_FRONT_TERRAIN_DEF… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:539 |
| 0x140775550 | NDefines::CDefineRegistryHelper_NAIDEMOCRACIES_BEFRIEND_FAS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:258 |
| 0x1407828F0 | NDefines::CDefineRegistryHelper_NAIENTRENCHMENT_WEIGHT::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:231 |
| 0x14078DC90 | NDefines::CDefineRegistryHelper_NAIGIVE_STATE_CONTROL_MIN_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:207 |
| 0x140792550 | NDefines::CDefineRegistryHelper_NAIJOIN_ALLY_FASCIST_DESIRE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:174 |
| 0x1407A8640 | NDefines::CDefineRegistryHelper_NAIMISSION_FLEET_ICONS::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:796 |
| 0x1407B6320 | NDefines::CDefineRegistryHelper_NAIPLAN_ATTACK_MIN_STRENGTH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:196 |
| 0x1407BE840 | NDefines::CDefineRegistryHelper_NAIREGION_THREAT_LEVEL_TO_A… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:346 |
| 0x1407CC660 | NDefines::CDefineRegistryHelper_NAIUNLOCK_SPIRIT_MODIFIER_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:148 |
| 0x1407F5020 | NDefines::CDefineRegistryHelper_NCharacterSPECIALIST_ADVISO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_character.h:18 |
| 0x140845E10 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_DEMIL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:178 |
| 0x14084D3A0 | NDefines::CDefineRegistryHelper_NGraphicsCOUNTRY_FLAG_TEX_W… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:229 |
| 0x140851BD0 | NDefines::CDefineRegistryHelper_NGraphicsFACTION_PING_MAP_N… 业务 NDefines 定义注册表读取（vtable 槽0）· faction_defines.h:62 |
| 0x140872CB0 | NDefines::CDefineRegistryHelper_NGraphicsSUN_SPECULAR_INTEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:350 |
| 0x140873D30 | NDefines::CDefineRegistryHelper_NGraphicsSUPPLY_ICON_END_CU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:631 |
| 0x1408895A0 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_MANPOWER_RAN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:120 |
| 0x1408BD6F0 | NDefines::CDefineRegistryHelper_NMapIconsDIPLOMACY_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:173 |
| 0x1408D9470 | NDefines::CDefineRegistryHelper_NMapIconsRESOURCES_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:172 |
| 0x1408DD880 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_CA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:167 |
| 0x1408EE6B0 | NDefines::CDefineRegistryHelper_NMapModeCONSTRUCTION_MAP_MO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:73 |
| 0x1408F65E0 | NDefines::CDefineRegistryHelper_NMapModeRADAR_RANGE_STRIPES… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:87 |
| 0x1408F6C10 | NDefines::CDefineRegistryHelper_NMapModeRAILWAY_GUN_RANGE_I… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:119 |
| 0x140908550 | NDefines::CDefineRegistryHelper_NMilitaryDYNAMIC_MODIFIER_A… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:325 |
| 0x140909890 | NDefines::CDefineRegistryHelper_NMilitaryEQUIPMENT_COMBAT_L… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:159 |
| 0x14090BBA0 | NDefines::CDefineRegistryHelper_NMilitaryFIELD_MARSHAL_XP_R… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:382 |
| 0x14090EE60 | NDefines::CDefineRegistryHelper_NMilitaryHISTORY_OPERATION_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:341 |
| 0x1409145B0 | NDefines::CDefineRegistryHelper_NMilitaryMAX_HQ_BATTALION_H… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:42 |
| 0x140928980 | NDefines::CDefineRegistryHelper_NMilitarySUPPLY_GRACE::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:162 |
| 0x14095E040 | NDefines::CDefineRegistryHelper_NNavyPRIDE_OF_THE_FLEET_UNA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:782 |
| 0x140968BD0 | NDefines::CDefineRegistryHelper_NNavyTRAINING_EXPERIENCE_FA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:814 |
| 0x14080DE90 | NDefines::CDefineRegistryHelper_NCountryWAR_SUPPORT_TENSION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:76 |
| 0x140827FB0 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_DISMANTLE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:119 |
| 0x1408281C0 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_FACTION_J… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:111 |
| 0x14082B130 | NDefines::CDefineRegistryHelper_NDiplomacyVICTORY_POINT_WOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:167 |
| 0x1408C14D0 | NDefines::CDefineRegistryHelper_NMapIconsHOME_BASE_MAP_ICON… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:200 |
| 0x1408C6330 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:180 |
| 0x1408C73B0 | NDefines::CDefineRegistryHelper_NMapIconsINFRASTRUCTURE_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:180 |
| 0x140912F00 | NDefines::CDefineRegistryHelper_NMilitaryLOW_SUPPLY::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:174 |
| 0x14076B100 | NDefines::CDefineRegistryHelper_NAICARRIER_TASKFORCE_MAX_CA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:619 |
| 0x140786E00 | NDefines::CDefineRegistryHelper_NAIEXTRA_NAVY_INTEL_FOR_CON… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:374 |
| 0x14079CC50 | NDefines::CDefineRegistryHelper_NAIMAX_FACTORY_TO_TRADE_FOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:680 |
| 0x1407BFD90 | NDefines::CDefineRegistryHelper_NAIRESEARCH_AHEAD_OF_TIME_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:43 |
| 0x140802770 | NDefines::CDefineRegistryHelper_NCountryINVASION_REPORT_EXP… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:121 |
| 0x140807790 | NDefines::CDefineRegistryHelper_NCountryMIN_WAR_SUPPORT::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:109 |
| 0x140866730 | NDefines::CDefineRegistryHelper_NGraphicsRAID_ARROW_BALLIST… 业务 NDefines 定义注册表读取（vtable 槽0）· raid_defines.h:37 |
| 0x1408CAD70 | NDefines::CDefineRegistryHelper_NMapIconsOPERATION_PRIORITY… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:191 |
| 0x1409A1D40 | NDefines::CDefineRegistryHelper_NSoundBATTLE_SOUND_MIN_UNIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_sound.h:12 |
| 0x140777700 | NDefines::CDefineRegistryHelper_NAIDESIRE_USE_XP_TO_UNLOCK_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:138 |
| 0x1407888D0 | NDefines::CDefineRegistryHelper_NAIFASCISTS_BEFRIEND_COMMUN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:251 |
| 0x1407A0A10 | NDefines::CDefineRegistryHelper_NAIMAX_UNITS_FACTOR_FRONT_O… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:420 |
| 0x1407A8430 | NDefines::CDefineRegistryHelper_NAIMISSING_CONVOYS_BOOST_FA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:359 |
| 0x1407AE1B0 | NDefines::CDefineRegistryHelper_NAINAVAL_STRIKE_PLANES_PER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:458 |
| 0x1407BDBE0 | NDefines::CDefineRegistryHelper_NAIRECON_PLANES_NAVAL::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:523 |
| 0x1407C8970 | NDefines::CDefineRegistryHelper_NAITENSION_MIN_FOR_GUARANTE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:559 |
| 0x1407D6EB0 | NDefines::CDefineRegistryHelper_NAirAIR_WING_MAX_STATS_DEFE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:464 |
| 0x140810E00 | NDefines::CDefineRegistryHelper_NDiplomacyBASE_IMPROVE_RELA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:62 |
| 0x140843D10 | NDefines::CDefineRegistryHelper_NGraphicsARROW_EXT_TEXT_POI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:311 |
| 0x140859790 | NDefines::CDefineRegistryHelper_NGraphicsLAND_COMBAT_DISTAN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:256 |
| 0x14086BF60 | NDefines::CDefineRegistryHelper_NGraphicsRAILWAY_MAP_ARROW_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:52 |
| 0x14087D260 | NDefines::CDefineRegistryHelper_NGraphicsWEATHER_ZOOM_IN_FA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:295 |
| 0x140899FB0 | NDefines::CDefineRegistryHelper_NIntelNAVY_FLEET_COUNT_INTE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:166 |
| 0x1408BF7F0 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:174 |
| 0x1408C39F0 | NDefines::CDefineRegistryHelper_NMapIconsIDEOLOGY_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:183 |
| 0x1408C9CF0 | NDefines::CDefineRegistryHelper_NMapIconsMANPOWER_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:182 |
| 0x1408DE6F0 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_NA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:167 |
| 0x14091F030 | NDefines::CDefineRegistryHelper_NMilitaryPLAN_COHESION_WEIG… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:243 |
| 0x14092CC30 | NDefines::CDefineRegistryHelper_NMilitaryUNIT_UPKEEP_ATTRIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:259 |
| 0x14092FE60 | NDefines::CDefineRegistryHelper_NNavyACCIDENTS_CHANCE_BALAN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:829 |
| 0x140969D00 | NDefines::CDefineRegistryHelper_NNavyUNIT_EXPERIENCE_PER_CO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:730 |
| 0x140775B80 | NDefines::CDefineRegistryHelper_NAIDEPLOYED_UNIT_MANPOWER_R… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:592 |
| 0x1407FBCA0 | NDefines::CDefineRegistryHelper_NCountryFRONT_PROVINCE_SCOR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:78 |
| 0x140808600 | NDefines::CDefineRegistryHelper_NCountryPOLITICAL_POWER_LOW… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:98 |
| 0x14080CE10 | NDefines::CDefineRegistryHelper_NCountryTERRAIN_IMPORTANCE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:92 |
| 0x140826DF0 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_ANNEX_CLA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:105 |
| 0x1408455D0 | NDefines::CDefineRegistryHelper_NGraphicsBORDER_COLOR_BORDE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:185 |
| 0x14084EE70 | NDefines::CDefineRegistryHelper_NGraphicsDIRECTION_POINTER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:98 |
| 0x140854D50 | NDefines::CDefineRegistryHelper_NGraphicsGRADIENT_BORDERS_O… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:207 |
| 0x140869E60 | NDefines::CDefineRegistryHelper_NGraphicsRAILWAY_GUN_ASSIGN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:613 |
| 0x1408D3170 | NDefines::CDefineRegistryHelper_NMapIconsPLAYERS_PRIORITY_N… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:185 |
| 0x1408D5AB0 | NDefines::CDefineRegistryHelper_NMapIconsRESISTANCE_PRIORIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:171 |
| 0x14093EB60 | NDefines::CDefineRegistryHelper_NNavyCONVOY_SINKING_SPILLOV… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1029 |
| 0x1409A1F50 | NDefines::CDefineRegistryHelper_NSoundBATTLE_SOUND_NAME::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_sound.h:9 |
| 0x14077DCC0 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_SEND_ATTACHE_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:81 |
| 0x1407A4230 | NDefines::CDefineRegistryHelper_NAIMIN_DELIVERED_TRADE_FRAC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:69 |
| 0x1407C28C0 | NDefines::CDefineRegistryHelper_NAIROCKET_MIN_ASSIGN_SCORE:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:53 |
| 0x1408083F0 | NDefines::CDefineRegistryHelper_NCountryPARADROP_AIR_SUPERI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:111 |
| 0x140833E00 | NDefines::CDefineRegistryHelper_NFactionsFACTION_INFLUENCE_… 业务 NDefines 定义注册表读取（vtable 槽0）· faction_defines.h:29 |
| 0x14086F920 | NDefines::CDefineRegistryHelper_NGraphicsSHIP_POPUP_SCALE_D… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:86 |
| 0x14090E620 | NDefines::CDefineRegistryHelper_NMilitaryGENERATE_AI_DIV_CO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:332 |
| 0x140933820 | NDefines::CDefineRegistryHelper_NNavyAMPHIBIOUS_INVADE_MOVE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:740 |
| 0x14094E460 | NDefines::CDefineRegistryHelper_NNavyMISSION_DAILY_EXP_GAIN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:807 |
| 0x14099EBC0 | NDefines::CDefineRegistryHelper_NResistanceRESISTANCE_GROWT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:557 |
| 0x1409B7370 | NDefines::CDefineRegistryHelper_NTradePUPPET_MASTER_TRADE_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:332 |
| 0x1407742C0 | NDefines::CDefineRegistryHelper_NAIDEFAULT_SUPPLY_TRUCK_BUF… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:869 |
| 0x1407744D0 | NDefines::CDefineRegistryHelper_NAIDEMOCRACIES_ALLY_COMMUNI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:263 |
| 0x140787010 | NDefines::CDefineRegistryHelper_NAIFACTION_UNSTABLE_ACCEPTA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:279 |
| 0x14078C8C0 | NDefines::CDefineRegistryHelper_NAIGENERATE_WARGOAL_ANTAGON… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:219 |
| 0x1407C3B50 | NDefines::CDefineRegistryHelper_NAISEND_VOLUNTEER_EVAL_BASE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:203 |
| 0x1407DD590 | NDefines::CDefineRegistryHelper_NAirDAY_NIGHT_COVERAGE_FACT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:493 |
| 0x1407DF690 | NDefines::CDefineRegistryHelper_NAirDISRUPTION_FACTOR_CARRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:578 |
| 0x1407EB620 | NDefines::CDefineRegistryHelper_NAirNO_SEARCH_MISSION_DETEC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:537 |
| 0x1407EB830 | NDefines::CDefineRegistryHelper_NAirPARADROP_EXPERIENCE_SCA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:524 |
| 0x14081F590 | NDefines::CDefineRegistryHelper_NDiplomacyNAP_BREAK_FORCE_B… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:83 |
| 0x140852200 | NDefines::CDefineRegistryHelper_NGraphicsFRIEND_COLOR::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:423 |
| 0x140875E30 | NDefines::CDefineRegistryHelper_NGraphicsTONE_MAP_MIDDLE_GR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:332 |
| 0x140882D20 | NDefines::CDefineRegistryHelper_NIntelARMY_ARMY_COUNT_RANGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:131 |
| 0x14088B6A0 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_SUPPLY_RANGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:116 |
| 0x14088C720 | NDefines::CDefineRegistryHelper_NIntelCIVILIAN_TRUCKS_RANGE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:108 |
| 0x140898F30 | NDefines::CDefineRegistryHelper_NIntelNAVAL_DOMINANCE_INTEL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:162 |
| 0x1408DD670 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_AI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:167 |
| 0x1408DF770 | NDefines::CDefineRegistryHelper_NMapIconsSTATES_PRIORITY_RO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:167 |
| 0x14093A750 | NDefines::CDefineRegistryHelper_NNavyCOMBAT_CHASE_RESIGNATI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:694 |
| 0x14093E950 | NDefines::CDefineRegistryHelper_NNavyCONVOY_ROUTE_SIZE_CONV… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:697 |
| 0x140802B90 | NDefines::CDefineRegistryHelper_NCountryMAJOR_IC_RATIO::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:79 |
| 0x14085B470 | NDefines::CDefineRegistryHelper_NGraphicsMAP_BUILDINGS_DEST… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:90 |
| 0x1408B3A30 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_MILITAR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:178 |
| 0x1408C77D0 | NDefines::CDefineRegistryHelper_NMapIconsINTEL_MAP_MODE_MAP… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:197 |
| 0x1408F42F0 | NDefines::CDefineRegistryHelper_NMapModeNAVAL_REGION_TRANSP… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:105 |
| 0x14098F100 | NDefines::CDefineRegistryHelper_NProjectRECRUIT_SCIENTIST_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_project.h:27 |
| 0x1409B42A0 | NDefines::CDefineRegistryHelper_NSupplyVP_TO_SUPPLY_BONUS_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_supply.h:132 |
| 0x140767AD0 | NDefines::CDefineRegistryHelper_NAIBUILDING_TARGETS_BUILDIN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:855 |
| 0x1407A6330 | NDefines::CDefineRegistryHelper_NAIMIN_MANPOWER_TO_BUILD_UN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:429 |
| 0x1407E4700 | NDefines::CDefineRegistryHelper_NAirGfxAIRPLANES_SCALE_LAND… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:14 |
| 0x1407F08A0 | NDefines::CDefineRegistryHelper_NBuildingsSUPPLY_ROUTE_RESO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:327 |
| 0x1408561F0 | NDefines::CDefineRegistryHelper_NGraphicsGRADIENT_BORDERS_R… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:223 |
| 0x14086C9B0 | NDefines::CDefineRegistryHelper_NGraphicsRESISTANCE_COLOR_B… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:416 |
| 0x1408B08B0 | NDefines::CDefineRegistryHelper_NMapIconsDEPLOYMENT_AIR_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:176 |
| 0x1408E41B0 | NDefines::CDefineRegistryHelper_NMapIconsSTRATEGIC_NAVY_PRI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:170 |
| 0x14099BF50 | NDefines::CDefineRegistryHelper_NResistanceINITIAL_HISTORY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:601 |
| 0x140768100 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_COMMUNIST_DESI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:159 |
| 0x1407692C0 | NDefines::CDefineRegistryHelper_NAICALL_ALLY_PUPPET_INVITE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:160 |
| 0x1407721C0 | NDefines::CDefineRegistryHelper_NAIDAYS_BETWEEN_CHECK_BEST_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:144 |
| 0x140775340 | NDefines::CDefineRegistryHelper_NAIDEMOCRACIES_BEFRIEND_DEM… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:259 |
| 0x14077FDC0 | NDefines::CDefineRegistryHelper_NAIDIPLO_MAX_CONTAINMENT_AC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:288 |
| 0x14077FFD0 | NDefines::CDefineRegistryHelper_NAIDIPLO_PREFER_OTHER_FACTI… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:283 |
| 0x140782FD0 | NDefines::CDefineRegistryHelper_NAIEQUIPMENT_MARKET_CONTRAC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:93 |
| 0x140789740 | NDefines::CDefineRegistryHelper_NAIFORCE_FACTOR_AGAINST_EXT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:367 |
| 0x14078ED10 | NDefines::CDefineRegistryHelper_NAIHIGH_COMMAND_ADDED_WEIGH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:888 |
| 0x140790B50 | NDefines::CDefineRegistryHelper_NAIINVASION_COASTAL_PROVS_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:341 |
| 0x1407AF4F0 | NDefines::CDefineRegistryHelper_NAINEW_LEADER_EXTRA_CP_FACT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:409 |
| 0x1407B08E0 | NDefines::CDefineRegistryHelper_NAINUM_SILOS_PER_MILITARY_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:743 |
| 0x1407D4620 | NDefines::CDefineRegistryHelper_NAirAIR_NAVAL_KAMIKAZE_DAMA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:518 |
| 0x1407D8280 | NDefines::CDefineRegistryHelper_NAirAIR_WING_XP_TRAINING_MA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:567 |
| 0x14084D190 | NDefines::CDefineRegistryHelper_NGraphicsCOUNTRY_FLAG_TEX_M… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:231 |
| 0x14084DDF0 | NDefines::CDefineRegistryHelper_NGraphicsCOUP_RED::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:645 |
| 0x1408602D0 | NDefines::CDefineRegistryHelper_NGraphicsNAVAL_UNIT_MOVEMEN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:118 |
| 0x1408644D0 | NDefines::CDefineRegistryHelper_NGraphicsPROVINCE_BORDER_FA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:113 |
| 0x14087E5A0 | NDefines::CDefineRegistryHelper_NIndustrialOrganisationENAB… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_industrial_organisation.h:15 |
| 0x140885030 | NDefines::CDefineRegistryHelper_NIntelARMY_MAX_ARMOR_INTEL_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:224 |
| 0x140886F20 | NDefines::CDefineRegistryHelper_NIntelARMY_STOCKPILE_COUNT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_intel.h:149 |
| 0x1408A0530 | NDefines::CDefineRegistryHelper_NInterfaceARMY_LIST_BOTTOM_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:511 |
| 0x1408A1B10 | NDefines::CDefineRegistryHelper_NInterfaceDEFAULT_FLEET_ICO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:530 |
| 0x1408A4D80 | NDefines::CDefineRegistryHelper_NInterfaceMILITARY_FACTORIE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:514 |
| 0x1408BE770 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:174 |
| 0x1408C0870 | NDefines::CDefineRegistryHelper_NMapIconsFACTIONS_PRIORITY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:174 |
| 0x140904B90 | NDefines::CDefineRegistryHelper_NMilitaryCOMBAT_OVER_WIDTH_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:274 |
| 0x140917520 | NDefines::CDefineRegistryHelper_NMilitaryNAVAL_EQUIPMENT_RA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:292 |
| 0x140928560 | NDefines::CDefineRegistryHelper_NMilitarySTRATEGIC_SPEED_RA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:281 |
| 0x1409488E0 | NDefines::CDefineRegistryHelper_NNavyLEADER_EXPERIENCE_SCAL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:734 |
| 0x140959340 | NDefines::CDefineRegistryHelper_NNavyNAVAL_MINE_DANGER_TRIG… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:864 |
| 0x14095F640 | NDefines::CDefineRegistryHelper_NNavyREPAIR_AND_RETURN_PRIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:703 |
| 0x140799830 | NDefines::CDefineRegistryHelper_NAILOCATION_BALANCE_TO_ADVA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:84 |
| 0x14081B390 | NDefines::CDefineRegistryHelper_NDiplomacyJOINING_NAP_WAR_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:126 |
| 0x14082C1B0 | NDefines::CDefineRegistryHelper_NDiplomacyWARGOAL_COST_LEND… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:180 |
| 0x14077C980 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_FACTION_WAR_RE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:75 |
| 0x1407E6AC0 | NDefines::CDefineRegistryHelper_NAirGfxSCOUT_PLANE_DIVISION… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:42 |
| 0x1407F7330 | NDefines::CDefineRegistryHelper_NCountryBASE_FUEL_GAIN_PER_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:181 |
| 0x1407FAE30 | NDefines::CDefineRegistryHelper_NCountryDAYS_OF_WAR_BEFORE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:175 |
| 0x14080B780 | NDefines::CDefineRegistryHelper_NCountrySPECIAL_FORCES_CAP_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:176 |
| 0x14087C1E0 | NDefines::CDefineRegistryHelper_NGraphicsVIRTUAL_BATTLEPLAN… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:189 |
| 0x1409255F0 | NDefines::CDefineRegistryHelper_NMilitaryRELIABILITY_WEATHE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:82 |
| 0x1409897F0 | NDefines::CDefineRegistryHelper_NProductionPOWERED_FACTORY_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:206 |
| 0x140994180 | NDefines::CDefineRegistryHelper_NRaidsRAID_UNIT_SPEED_MULTI… 业务 NDefines 定义注册表读取（vtable 槽0）· raid_defines.h:15 |
| 0x14074D320 | NDefines::CDefineRegistryHelper_NAIAGGRESSIVENESS_CHECK_BAS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:751 |
| 0x1407629B0 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_MAX_P… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:940 |
| 0x140763A30 | NDefines::CDefineRegistryHelper_NAIARMY_LEADER_ASSIGN_RECON… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:941 |
| 0x14076B890 | NDefines::CDefineRegistryHelper_NAICHIEF_ADDED_WEIGHT_FACTO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:889 |
| 0x140799620 | NDefines::CDefineRegistryHelper_NAILENDLEASE_FRACTION_OF_ST… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:178 |
| 0x1407AF700 | NDefines::CDefineRegistryHelper_NAINUM_AI_MESSAGES::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:276 |
| 0x1407B7190 | NDefines::CDefineRegistryHelper_NAIPLAN_STEP_COST_LIMIT::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:200 |
| 0x1407C6120 | NDefines::CDefineRegistryHelper_NAISTR_BOMB_IMPORTANCE_SCAL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:515 |
| 0x1407C6F90 | NDefines::CDefineRegistryHelper_NAISTR_BOMB_PLANES_PER_MIL_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:519 |
| 0x1407CC450 | NDefines::CDefineRegistryHelper_NAIUNLOCK_SPIRIT_AI_WILL_DO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:147 |
| 0x1407D14A0 | NDefines::CDefineRegistryHelper_NAirAA_INDUSTRY_AIR_DAMAGE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:591 |
| 0x1407D9910 | NDefines::CDefineRegistryHelper_NAirBASE_KAMIKAZE_TARGETING… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:522 |
| 0x14081F7A0 | NDefines::CDefineRegistryHelper_NDiplomacyNAP_EXPIRY_MONTHS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:78 |
| 0x14085A810 | NDefines::CDefineRegistryHelper_NGraphicsLIGHT_SHADOW_DIREC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:108 |
| 0x140875C20 | NDefines::CDefineRegistryHelper_NGraphicsTONE_MAP_LUMINANCE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:333 |
| 0x14090D2E0 | NDefines::CDefineRegistryHelper_NMilitaryFUEL_PENALTY_START… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:391 |
| 0x140915630 | NDefines::CDefineRegistryHelper_NMilitaryMAX_NUM_AUTOMEDALS… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:334 |
| 0x14093D8D0 | NDefines::CDefineRegistryHelper_NNavyCONVOY_DETECTION_CHANC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:670 |
| 0x1407B25C0 | NDefines::CDefineRegistryHelper_NAIORG_UNIT_WEAK::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:239 |
| 0x1407C7BF0 | NDefines::CDefineRegistryHelper_NAISTR_UNIT_WEAK::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:238 |
| 0x1407EE7A0 | NDefines::CDefineRegistryHelper_NBuildingsBASE_FACTORY_REPA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:321 |
| 0x1407F62B0 | NDefines::CDefineRegistryHelper_NCountryARMY_IMPORTANCE_FAC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:91 |
| 0x1408F3270 | NDefines::CDefineRegistryHelper_NMapModeMAP_MODE_TERRAIN_TR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:111 |
| 0x140930070 | NDefines::CDefineRegistryHelper_NNavyADMIRAL_TASKFORCE_CAP:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1096 |
| 0x140960980 | NDefines::CDefineRegistryHelper_NNavySCREEN_CAP_REDUCTION_F… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:1071 |
| 0x1407763C0 | NDefines::CDefineRegistryHelper_NAIDEPLOY_MIN_EQUIPMENT_WAR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:64 |
| 0x140858710 | NDefines::CDefineRegistryHelper_NGraphicsINTEL_LEDGER_GRAPH… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:618 |
| 0x14085EE30 | NDefines::CDefineRegistryHelper_NGraphicsNATIONAL_FOCUS_PUL… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:454 |
| 0x14086C7A0 | NDefines::CDefineRegistryHelper_NGraphicsRESISTANCE_COLOR_A… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:418 |
| 0x14086F500 | NDefines::CDefineRegistryHelper_NGraphicsSHIP_IN_MISSION_TU… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:368 |
| 0x140924570 | NDefines::CDefineRegistryHelper_NMilitaryRECON_SKILL_IMPACT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:12 |
| 0x140980450 | NDefines::CDefineRegistryHelper_NPoliticsNAVY_LEADER_MAX_CO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:300 |
| 0x140982550 | NDefines::CDefineRegistryHelper_NProductionBASE_FACTORY_SPE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:201 |
| 0x14076C700 | NDefines::CDefineRegistryHelper_NAICOMMUNISTS_ANTAGONIZE_FA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:273 |
| 0x140792970 | NDefines::CDefineRegistryHelper_NAIJOIN_FACTION_BOTH_LOSING… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:176 |
| 0x1407B73A0 | NDefines::CDefineRegistryHelper_NAIPLAN_STEP_COST_LIMIT_RED… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:201 |
| 0x1407BD9D0 | NDefines::CDefineRegistryHelper_NAIRECON_PLANES_LAND_COMBAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:524 |
| 0x1407C2CE0 | NDefines::CDefineRegistryHelper_NAIROCKET_PRIORITIZE_BARRAG… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:55 |
| 0x1407C4BD0 | NDefines::CDefineRegistryHelper_NAISTATE_CONTROL_FOR_AREA_D… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:366 |
| 0x1407D2520 | NDefines::CDefineRegistryHelper_NAirACE_DEATH_CHANCE_PLANES… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:513 |
| 0x14084A220 | NDefines::CDefineRegistryHelper_NGraphicsCAMERA_ZOOM_SPEED:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:442 |
| 0x14084E420 | NDefines::CDefineRegistryHelper_NGraphicsDAY_NIGHT_FEATHER:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:226 |
| 0x1408682D0 | NDefines::CDefineRegistryHelper_NGraphicsRAID_TARGET_ZOOM_H… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:649 |
| 0x1408ACEF0 | NDefines::CDefineRegistryHelper_NMapIconsDEFAULT_PRIORITY_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:166 |
| 0x1408F63D0 | NDefines::CDefineRegistryHelper_NMapModeRADAR_RANGE_SELECTE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:90 |
| 0x140934E20 | NDefines::CDefineRegistryHelper_NNavyATTRITION_STR_DAMAGE_C… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:833 |
| 0x14095C990 | NDefines::CDefineRegistryHelper_NNavyORG_COST_WHILE_MOVING:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:856 |
| 0x140969F10 | NDefines::CDefineRegistryHelper_NNavyUNIT_EXPERIENCE_SCALE:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:731 |
| 0x140806500 | NDefines::CDefineRegistryHelper_NCountryMIN_AIR_RESERVE_RAT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:97 |
| 0x140826BE0 | NDefines::CDefineRegistryHelper_NDiplomacyREVOKE_GUARANTEE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:123 |
| 0x14084AC70 | NDefines::CDefineRegistryHelper_NGraphicsCITY_SPRAWL_SHRINK… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:96 |
| 0x14079AC00 | NDefines::CDefineRegistryHelper_NAIMAX_ALLOWED_NAVAL_DANGER… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:561 |
| 0x1407DE400 | NDefines::CDefineRegistryHelper_NAirDETECT_EFFICIENCY_FROM_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:491 |
| 0x1407E4910 | NDefines::CDefineRegistryHelper_NAirGfxAIRPLANES_SCALE_MIN:… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:13 |
| 0x140841530 | NDefines::CDefineRegistryHelper_NGameOIL_RESOURCE::[0] 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:27 |
| 0x140874BA0 | NDefines::CDefineRegistryHelper_NGraphicsSUPPLY_NAVAL_NODE_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:622 |
| 0x14087AD40 | NDefines::CDefineRegistryHelper_NGraphicsUNIT_ARROW_DISTANC… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:252 |
| 0x1408F3690 | NDefines::CDefineRegistryHelper_NMapModeNAVAL_HEADQUARTER_O… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:134 |
| 0x14075A140 | NDefines::CDefineRegistryHelper_NAIAI_REPAIR_CANCEL_MIN_STR… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:715 |
| 0x140766E70 | NDefines::CDefineRegistryHelper_NAIATTACK_HEAVILY_DEFENDED_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:411 |
| 0x1407D5E30 | NDefines::CDefineRegistryHelper_NAirAIR_WING_AVERAGE_SIZE::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:469 |
| 0x1408F1170 | NDefines::CDefineRegistryHelper_NMapModeFACTIONS_MEMBER_TRA… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_mapmode.h:80 |
| 0x1408FF1C0 | NDefines::CDefineRegistryHelper_NMilitaryARMOR_VS_AVERAGE::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:286 |
| 0x14090A910 | NDefines::CDefineRegistryHelper_NMilitaryFASTER_ORG_REGAIN_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:301 |
| 0x140924360 | NDefines::CDefineRegistryHelper_NMilitaryPROMOTE_LEADER_CP_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:352 |
| 0x140926460 | NDefines::CDefineRegistryHelper_NMilitaryRIVER_LARGE_STOP_I… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:102 |
| 0x140941E20 | NDefines::CDefineRegistryHelper_NNavyDETECTION_CHANCE_MULT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:650 |
| 0x14097C040 | NDefines::CDefineRegistryHelper_NOperativesOPERATIVE_MISSIO… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:400 |
| 0x1407B9340 | NDefines::CDefineRegistryHelper_NAIPRIO_FUEL_REQUEST_RATIO_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:685 |
| 0x140829240 | NDefines::CDefineRegistryHelper_NDiplomacyTENSION_PUPPET::[… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:107 |
| 0x140926CA0 | NDefines::CDefineRegistryHelper_NMilitarySHORE_BOMBARDMENT_… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:298 |
| 0x140779800 | NDefines::CDefineRegistryHelper_NAIDIPLOMACY_ACCEPT_ATTACHE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_ai.h:28 |
| 0x140807580 | NDefines::CDefineRegistryHelper_NCountryMIN_SURRENDER_LIMIT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:128 |
| 0x14081E720 | NDefines::CDefineRegistryHelper_NDiplomacyMAX_TRUST_VALUE::… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_diplomacy.h:8 |
| 0x140863030 | NDefines::CDefineRegistryHelper_NGraphicsPOSTEFFECT_FEATHER… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:306 |
| 0x140874780 | NDefines::CDefineRegistryHelper_NGraphicsSUPPLY_ICON_UNUSED… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_graphics.h:627 |
| 0x1409253E0 | NDefines::CDefineRegistryHelper_NMilitaryRELIABILITY_ORG_RE… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_military.h:80 |
| 0x1409814D0 | NDefines::CDefineRegistryHelper_NProductionBASE_ENERGY_COST… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:219 |
| 0x140983FE0 | NDefines::CDefineRegistryHelper_NProductionCONVERSION_SPEED… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:244 |
| 0x140999E50 | NDefines::CDefineRegistryHelper_NResistanceCOMPLIANCE_GROWT… 业务 NDefines 定义注册表读取（vtable 槽0）· defines_game.h:560 |
| 0x14074C6C0 | defines_ai.h:837 断言; 读 define "ACCESS_SCORE_PENALTY_PER_EXISTING_ACCESS" 自 "NAI" lua 表 |
| 0x14074CAE0 | defines_ai.h:392 断言; 读 define "ADVISOR_SCORE_CHEAPER_IS_BETTER_FACTOR" 自 "NAI" lua 表 |
| 0x14074CCF0 | defines_ai.h:393 断言; 读 define "ADVISOR_SCORE_CHEAPER_IS_BETTER_MIN" 自 "NAI" lua 表 |
| 0x14074CF00 | defines_ai.h:391 断言; 读 define "ADVISOR_SCORE_TRAIT_MODIFIER_FACTOR" 自 "NAI" lua 表 |
| 0x14074D110 | defines_ai.h:750 断言; 读 define "AGGRESSIVENESS_BONUS_FOR_FRONTS_THAT_ARE_ON_HIGH_AGGRESSIVENESS" 自 "NAI" lua 表 |
| 0x14074D530 | defines_ai.h:753 断言; 读 define "AGGRESSIVENESS_CHECK_CAREFUL" 自 "NAI" lua 表 |
| 0x14074D950 | defines_ai.h:756 断言; 读 define "AGGRESSIVENESS_CHECK_FULLY_FORTIFIED" 自 "NAI" lua 表 |
| 0x14074DB60 | defines_ai.h:757 断言; 读 define "AGGRESSIVENESS_CHECK_FULLY_FORTIFIED_POCKET" 自 "NAI" lua 表 |
| 0x14074DD70 | defines_ai.h:754 断言; 读 define "AGGRESSIVENESS_CHECK_PARTLY_FORTIFIED" 自 "NAI" lua 表 |
| 0x14074DF80 | defines_ai.h:755 断言; 读 define "AGGRESSIVENESS_CHECK_PARTLY_FORTIFIED_WEAK_POINTS" 自 "NAI" lua 表 |
| 0x14074E830 | defines_ai.h:1009 断言; 读 define "AIFC_CA_DIVISIONS_PER_PROVINCE" 自 "NAI" lua 表 |
| 0x14074F070 | defines_ai.h:1008 断言; 读 define "AIFC_MAX_NR_FRONTS" 自 "NAI" lua 表 |
| 0x14074F330 | defines_ai.h:1012 断言; 读 define "AIFC_OFFENSIVE_DEACTIVATION_DAYS_THRESHOLD" 自 "NAI" lua 表 |
| 0x14074F8B0 | defines_ai.h:1041 断言; 读 define "AIFC_PATH_COST_ADJ_RIVER" 自 "NAI" lua 表 |
| 0x1407500F0 | defines_ai.h:1053 断言; 读 define "AIFC_PATH_COST_HAS_NAVAL_BASE" 自 "NAI" lua 表 |
| 0x1407503B0 | defines_ai.h:1052 断言; 读 define "AIFC_PATH_COST_HAS_SUPPLY_HUB" 自 "NAI" lua 表 |
| 0x140750670 | defines_ai.h:1051 断言; 读 define "AIFC_PATH_COST_PER_FORT_LEVEL" 自 "NAI" lua 表 |
| 0x140750EB0 | defines_ai.h:1044 断言; 读 define "AIFC_PATH_COST_TRN_FOREST" 自 "NAI" lua 表 |
| 0x1407516F0 | defines_ai.h:1050 断言; 读 define "AIFC_PATH_COST_TRN_MARSH" 自 "NAI" lua 表 |
| 0x1407519B0 | defines_ai.h:1043 断言; 读 define "AIFC_PATH_COST_TRN_MOUNTAINS" 自 "NAI" lua 表 |
| 0x140751C70 | defines_ai.h:1048 断言; 读 define "AIFC_PATH_COST_TRN_PLAINS" 自 "NAI" lua 表 |
| 0x140751F30 | defines_ai.h:1049 断言; 读 define "AIFC_PATH_COST_TRN_URBAN" 自 "NAI" lua 表 |
| 0x1407521F0 | defines_ai.h:1038 断言; 读 define "AIFC_PATH_MAX_COST" 自 "NAI" lua 表 |
| 0x140752B90 | defines_ai.h:1029 断言; 读 define "AIFC_TARGET_IGNORE_VP_THRESHOLD" 自 "NAI" lua 表 |
| 0x140752E50 | defines_ai.h:1031 断言; 读 define "AIFC_TARGET_NAVAL_BASE_BASE_SCORE" 自 "NAI" lua 表 |
| 0x140753060 | defines_ai.h:1032 断言; 读 define "AIFC_TARGET_NAVAL_BASE_SCORE_PER_LEVEL" 自 "NAI" lua 表 |
| 0x140753270 | defines_ai.h:1036 断言; 读 define "AIFC_TARGET_PERSISTED_FACTOR" 自 "NAI" lua 表 |
| 0x140753480 | defines_ai.h:1035 断言; 读 define "AIFC_TARGET_SHORT_PATH_PENALTY_FACTOR" 自 "NAI" lua 表 |
| 0x140753690 | defines_ai.h:1030 断言; 读 define "AIFC_TARGET_SUPPLY_HUB_BASE_SCORE" 自 "NAI" lua 表 |
| 0x1407543A0 | defines_ai.h:1026 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_ENTRENCHMENT" 自 "NAI" lua 表 |
| 0x1407545B0 | defines_ai.h:1027 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_EXPERIENCE" 自 "NAI" lua 表 |
| 0x1407547C0 | defines_ai.h:1020 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_HARDNESS" 自 "NAI" lua 表 |
| 0x140754BE0 | defines_ai.h:1024 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_HITPOINTS" 自 "NAI" lua 表 |
| 0x140754DF0 | defines_ai.h:1022 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_INITIATIVE" 自 "NAI" lua 表 |
| 0x140755420 | defines_ai.h:1016 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_SOFT_ATTACK" 自 "NAI" lua 表 |
| 0x140755630 | defines_ai.h:1021 断言; 读 define "AIFC_UNIT_OFFENSIVE_SCORE_FACTOR_SPEED" 自 "NAI" lua 表 |
| 0x140755E50 | defines_ai.h:688 断言; 读 define "AIR_ACTUAL_FUEL_USAGE_WEIGHT_ON_OIL_REQUEST" 自 "NAI" lua 表 |
| 0x140756060 | defines_ai.h:794 断言; 读 define "AIR_AI_ENEMY_PROV_RATIO_FOR_COMBAT_REGION" 自 "NAI" lua 表 |
| 0x1407563B0 | defines_ai.h:843 断言; 读 define "AIR_BASE_ACCESS_SCORE_PENALTY_PER_EXISTING_ACCESS" 自 "NAI" lua 表 |
| 0x1407565C0 | defines_ai.h:842 断言; 读 define "AIR_BASE_ACCESS_SCORE_PENALTY_PER_EXISTING_ACCESS_AT_WAR" 自 "NAI" lua 表 |
| 0x140756A90 | defines_ai.h:125 断言; 读 define "AIR_DESIGN_ALTERNATIVE_ABSENT" 自 "NAI" lua 表 |
| 0x1407572D0 | defines_ai.h:126 断言; 读 define "AIR_DESIGN_ALTERNATIVE_OF_LESSER_TECH" 自 "NAI" lua 表 |
| 0x140757910 | defines_ai.h:131 断言; 读 define "AIR_DESIGN_DEMAND_ABSENT" 自 "NAI" lua 表 |
| 0x140757BD0 | defines_ai.h:129 断言; 读 define "AIR_DESIGN_DEMAND_MAX" 自 "NAI" lua 表 |
| 0x140757E90 | defines_ai.h:130 断言; 读 define "AIR_DESIGN_DEMAND_MIN" 自 "NAI" lua 表 |
| 0x140758150 | defines_ai.h:440 断言; 读 define "AIR_SCORE_DISTANCE_IMPACT" 自 "NAI" lua 表 |
| 0x140758360 | defines_ai.h:52 断言; 读 define "AIR_SUPERIORITY_FACTOR" 自 "NAI" lua 表 |
| 0x140758570 | defines_ai.h:293 断言; 读 define "AIR_SUPERIORITY_FOR_FRIENDLY_CAS_RATIO" 自 "NAI" lua 表 |
| 0x140758990 | defines_ai.h:886 断言; 读 define "AI_CHAIN_CALLS_ALLIES" 自 "NAI" lua 表 |
| 0x140758BA0 | defines_ai.h:718 断言; 读 define "AI_CONVOY_DEFENSE_FUEL_RATIO" 自 "NAI" lua 表 |
| 0x140759660 | defines_ai.h:1068 断言; 读 define "AI_MIN_DOMINANCE_MARGIN" 自 "NAI" lua 表 |
| 0x140759920 | defines_ai.h:879 断言; 读 define "AI_NAVAL_GOALS_UPDATE_FREQUENCY_DAYS" 自 "NAI" lua 表 |
| 0x140759DF0 | defines_ai.h:908 断言; 读 define "AI_PREFERRED_TACTIC_WEEKLY_CHANGE_CHANCE" 自 "NAI" lua 表 |
| 0x14075A560 | defines_ai.h:713 断言; 读 define "AI_SHIP_SWAP_MIN_DAMAGED_SHIPS" 自 "NAI" lua 表 |
| 0x14075AAC0 | defines_ai.h:7 断言; 读 define "AI_TASKFORCE_REQUIRED_RESERVE_RATIO" 自 "NAI" lua 表 |
| 0x14075B5A0 | defines_ai.h:352 断言; 读 define "AREA_DEFENSE_BASE_IMPORTANCE" 自 "NAI" lua 表 |
| 0x14075B9C0 | defines_ai.h:974 断言; 读 define "AREA_DEFENSE_CAPITAL_COAST_WEIGHT" 自 "NAI" lua 表 |
| 0x14075BBD0 | defines_ai.h:972 断言; 读 define "AREA_DEFENSE_CAPITAL_PEACE_BASE_WEIGHT" 自 "NAI" lua 表 |
| 0x14075BFF0 | defines_ai.h:970 断言; 读 define "AREA_DEFENSE_CAPITAL_PEACE_VP_WEIGHT" 自 "NAI" lua 表 |
| 0x14075C200 | defines_ai.h:973 断言; 读 define "AREA_DEFENSE_CAPITAL_VP_WEIGHT" 自 "NAI" lua 表 |
| 0x14075C620 | defines_ai.h:978 断言; 读 define "AREA_DEFENSE_HOME_BASE_WEIGHT" 自 "NAI" lua 表 |
| 0x14075CA40 | defines_ai.h:976 断言; 读 define "AREA_DEFENSE_HOME_VP_WEIGHT" 自 "NAI" lua 表 |
| 0x14075D070 | defines_ai.h:968 断言; 读 define "AREA_DEFENSE_MINCAP_DESIRED_HOME_AREA" 自 "NAI" lua 表 |
| 0x14075D280 | defines_ai.h:965 断言; 读 define "AREA_DEFENSE_MINCAP_MAX_CAPITAL_DEFENSE" 自 "NAI" lua 表 |
| 0x14075D6A0 | defines_ai.h:981 断言; 读 define "AREA_DEFENSE_OTHER_BASE_WEIGHT" 自 "NAI" lua 表 |
| 0x14075DAC0 | defines_ai.h:979 断言; 读 define "AREA_DEFENSE_OTHER_VP_WEIGHT" 自 "NAI" lua 表 |
| 0x14075DEE0 | defines_ai.h:959 断言; 读 define "AREA_DEFENSE_SETTING_BORDERS" 自 "NAI" lua 表 |
| 0x14075E300 | defines_ai.h:963 断言; 读 define "AREA_DEFENSE_SETTING_FACILITY" 自 "NAI" lua 表 |
| 0x14075E720 | defines_ai.h:957 断言; 读 define "AREA_DEFENSE_SETTING_PORTS" 自 "NAI" lua 表 |
| 0x14075F010 | defines_ai.h:948 断言; 读 define "ARMY_LEADER_ASSIGN_AMPHIBIOUS_INVASION" 自 "NAI" lua 表 |
| 0x14075F430 | defines_ai.h:945 断言; 读 define "ARMY_LEADER_ASSIGN_ARMY_ARMOR_ATTACK_FACTOR" 自 "NAI" lua 表 |
| 0x14075F850 | defines_ai.h:953 断言; 读 define "ARMY_LEADER_ASSIGN_ARMY_MORALE_FACTOR" 自 "NAI" lua 表 |
| 0x14075FA60 | defines_ai.h:925 断言; 读 define "ARMY_LEADER_ASSIGN_ATTACK_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x14075FC70 | defines_ai.h:946 断言; 读 define "ARMY_LEADER_ASSIGN_BOOST_ARMOR_SKILL" 自 "NAI" lua 表 |
| 0x14075FE80 | defines_ai.h:938 断言; 读 define "ARMY_LEADER_ASSIGN_DEFENSE_ARMY_ARMOR_DEFENCE_FACTOR" 自 "NAI" lua 表 |
| 0x1407602A0 | defines_ai.h:918 断言; 读 define "ARMY_LEADER_ASSIGN_DEFENSE_DEFENSE_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x1407608D0 | defines_ai.h:916 断言; 读 define "ARMY_LEADER_ASSIGN_DEFENSE_OVERALL_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x140760CF0 | defines_ai.h:926 断言; 读 define "ARMY_LEADER_ASSIGN_DEFENSE_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x140761250 | defines_ai.h:913 断言; 读 define "ARMY_LEADER_ASSIGN_EMPTYNESS_MALUS" 自 "NAI" lua 表 |
| 0x140761670 | defines_ai.h:931 断言; 读 define "ARMY_LEADER_ASSIGN_EXILED_LEADS_OWN_EXILED_TROOPS" 自 "NAI" lua 表 |
| 0x140761880 | defines_ai.h:912 断言; 读 define "ARMY_LEADER_ASSIGN_FIELD_MARSHAL_TO_ARMY" 自 "NAI" lua 表 |
| 0x140761A90 | defines_ai.h:921 断言; 读 define "ARMY_LEADER_ASSIGN_INVASION_ATTACK_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x140761CA0 | defines_ai.h:922 断言; 读 define "ARMY_LEADER_ASSIGN_INVASION_DEFENSE_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x1407620C0 | defines_ai.h:924 断言; 读 define "ARMY_LEADER_ASSIGN_INVASION_PLANNING_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x140762590 | defines_ai.h:952 断言; 读 define "ARMY_LEADER_ASSIGN_LAND_REINFORCE_RATE" 自 "NAI" lua 表 |
| 0x1407627A0 | defines_ai.h:927 断言; 读 define "ARMY_LEADER_ASSIGN_LOGISTICS_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x140762DD0 | defines_ai.h:929 断言; 读 define "ARMY_LEADER_ASSIGN_NR_TRAITS" 自 "NAI" lua 表 |
| 0x140762FE0 | defines_ai.h:942 断言; 读 define "ARMY_LEADER_ASSIGN_OUT_OF_SUPPLY_FACTOR" 自 "NAI" lua 表 |
| 0x1407631F0 | defines_ai.h:915 断言; 读 define "ARMY_LEADER_ASSIGN_OVERALL_SKILL_FACTOR" 自 "NAI" lua 表 |
| 0x140763C40 | defines_ai.h:951 断言; 读 define "ARMY_LEADER_ASSIGN_SUPPLY_CONSUMPTION_FACTOR" 自 "NAI" lua 表 |
| 0x140763E50 | defines_ai.h:954 断言; 读 define "ARMY_LEADER_ASSIGN_TERRAIN_FACTOR" 自 "NAI" lua 表 |
| 0x140764060 | defines_ai.h:943 断言; 读 define "ARMY_LEADER_ASSIGN_WINTER_ATTRITION_FACTOR" 自 "NAI" lua 表 |
| 0x140764270 | defines_ai.h:932 断言; 读 define "ARMY_LEADER_ASSIGN_WITHDRAW_DAYS" 自 "NAI" lua 表 |
| 0x140764690 | defines_ai.h:933 断言; 读 define "ARMY_LEADER_MIN_DIVISIONS_FOR_HQ" 自 "NAI" lua 表 |
| 0x140764950 | defines_ai.h:530 断言; 读 define "ASSIGN_DEFENSE_ARMY_DEFENSE_FACTOR" 自 "NAI" lua 表 |
| 0x140764B60 | defines_ai.h:531 断言; 读 define "ASSIGN_DEFENSE_ARMY_ENTRENCHMENT_FACTOR" 自 "NAI" lua 表 |
| 0x140765190 | defines_ai.h:542 断言; 读 define "ASSIGN_DEFENSE_TERRAIN_DEFENSE_FACTOR" 自 "NAI" lua 表 |
| 0x1407653A0 | defines_ai.h:543 断言; 读 define "ASSIGN_DEFENSE_TERRAIN_MOVEMENT_FACTOR" 自 "NAI" lua 表 |
| 0x1407655B0 | defines_ai.h:529 断言; 读 define "ASSIGN_FRONT_ARMY_BREAKTHROUGH_FACTOR" 自 "NAI" lua 表 |
| 0x1407657C0 | defines_ai.h:528 断言; 读 define "ASSIGN_FRONT_ARMY_HARD_ATTACK_FACTOR" 自 "NAI" lua 表 |
| 0x1407659D0 | defines_ai.h:527 断言; 读 define "ASSIGN_FRONT_ARMY_SOFT_ATTACK_FACTOR" 自 "NAI" lua 表 |
| 0x140765BE0 | defines_ai.h:538 断言; 读 define "ASSIGN_FRONT_TERRAIN_ATTACK_FACTOR" 自 "NAI" lua 表 |
| 0x140766630 | defines_ai.h:546 断言; 读 define "ASSIGN_TANKS_TO_JUNGLE" 自 "NAI" lua 表 |
| 0x140766A50 | defines_ai.h:550 断言; 读 define "ASSIGN_TANKS_TO_NON_WAR_FRONT" 自 "NAI" lua 表 |
| 0x140767080 | defines_ai.h:186 断言; 读 define "AT_WAR_THREAT_FACTOR" 自 "NAI" lua 表 |
| 0x140767290 | defines_ai.h:430 断言; 读 define "AVERAGE_SUPPLY_USE_PESSIMISM" 自 "NAI" lua 表 |
| 0x1407674A0 | defines_ai.h:234 断言; 读 define "BASE_DISTANCE_TO_CARE" 自 "NAI" lua 表 |
| 0x1407676B0 | defines_ai.h:10 断言; 读 define "BASE_RELUCTANCE" 自 "NAI" lua 表 |
| 0x1407678C0 | defines_ai.h:582 断言; 读 define "BEFRIEND_FACTOR_FOR_KICKING_COUNTRIES" 自 "NAI" lua 表 |
| 0x140767CE0 | defines_ai.h:327 断言; 读 define "BUILD_REFINERY_LACK_OF_RESOURCE_MODIFIER" 自 "NAI" lua 表 |
| 0x140767EF0 | defines_ai.h:155 断言; 读 define "CALL_ALLY_BASE_DESIRE" 自 "NAI" lua 表 |
| 0x140768730 | defines_ai.h:169 断言; 读 define "CALL_ALLY_JOINER_HAS_ENEMY_NEIGHBOR" 自 "NAI" lua 表 |
| 0x1407696E0 | defines_ai.h:163 断言; 读 define "CALL_ALLY_RELATIVE_ARMY_STRENGTH_THRESHOLD" 自 "NAI" lua 表 |
| 0x140769BB0 | defines_ai.h:162 断言; 读 define "CALL_ALLY_RELATIVE_INDUSTRY_STRENGTH_THRESHOLD" 自 "NAI" lua 表 |
| 0x14076A080 | defines_ai.h:412 断言; 读 define "CANCEL_COMBAT_DISADVANTAGE_RATIO" 自 "NAI" lua 表 |
| 0x14076A340 | defines_ai.h:413 断言; 读 define "CANCEL_COMBAT_MIN_DURATION_HOURS" 自 "NAI" lua 表 |
| 0x14076A810 | defines_ai.h:415 断言; 读 define "CANCEL_INVASION_COMBAT_MIN_DURATION_HOURS" 自 "NAI" lua 表 |
| 0x14076AA20 | defines_ai.h:625 断言; 读 define "CAPITALS_TO_CARRIER_RATIO" 自 "NAI" lua 表 |
| 0x14076AC30 | defines_ai.h:620 断言; 读 define "CAPITAL_TASKFORCE_MAX_CAPITAL_COUNT" 自 "NAI" lua 表 |
| 0x14076AE40 | defines_ai.h:319 断言; 读 define "CARRIER_CAPACITY_IN_PRODUCTION_MAX_DAYS_LEFT_TO_INCLUDE_FACTOR" 自 "NAI" lua 表 |
| 0x14076B310 | defines_ai.h:608 断言; 读 define "CASUALTY_RATIO_TO_NOT_SEND_EXPEDITIONARIES" 自 "NAI" lua 表 |
| 0x14076BAA0 | defines_ai.h:891 断言; 读 define "COMMAND_POWER_BEFORE_SPEND_ON_TRAITS" 自 "NAI" lua 表 |
| 0x14076BEC0 | defines_ai.h:271 断言; 读 define "COMMUNISTS_ALLY_DEMOCRACIES" 自 "NAI" lua 表 |
| 0x14076C2E0 | defines_ai.h:275 断言; 读 define "COMMUNISTS_ANTAGONIZE_COMMUNISTS" 自 "NAI" lua 表 |
| 0x14076C4F0 | defines_ai.h:274 断言; 读 define "COMMUNISTS_ANTAGONIZE_DEMOCRACIES" 自 "NAI" lua 表 |
| 0x14076CB20 | defines_ai.h:268 断言; 读 define "COMMUNISTS_BEFRIEND_DEMOCRACIES" 自 "NAI" lua 表 |
| 0x14076DA40 | defines_ai.h:672 断言; 读 define "CONSTRUCTION_PRIO_FACTOR_REPAIRING" 自 "NAI" lua 表 |
| 0x14076DD00 | defines_ai.h:662 断言; 读 define "CONSTRUCTION_PRIO_INFRASTRUCTURE" 自 "NAI" lua 表 |
| 0x14076DFC0 | defines_ai.h:664 断言; 读 define "CONSTRUCTION_PRIO_MIL_FACTORY" 自 "NAI" lua 表 |
| 0x14076E280 | defines_ai.h:666 断言; 读 define "CONSTRUCTION_PRIO_RAILWAY" 自 "NAI" lua 表 |
| 0x14076F040 | defines_ai.h:344 断言; 读 define "CONVOY_DEFICIT_BUILD_BOOST_MAX" 自 "NAI" lua 表 |
| 0x14076F460 | defines_ai.h:377 断言; 读 define "CONVOY_ESCORT_SCORE_FROM_CONVOYS" 自 "NAI" lua 表 |
| 0x14076FB40 | defines_ai.h:379 断言; 读 define "CONVOY_RAID_MIN_ENEMY_THREAT" 自 "NAI" lua 表 |
| 0x14076FD50 | defines_ai.h:376 断言; 读 define "CONVOY_RAID_SCORE_FROM_CONVOY_INTELLIGENCE" 自 "NAI" lua 表 |
| 0x140770170 | defines_ai.h:566 断言; 读 define "CRITICAL_IDEA_PRIORITY" 自 "NAI" lua 表 |
| 0x140770380 | defines_ai.h:848 断言; 读 define "CRYPTO_ACTIVATE_NUM_ACTIVATED_DROP_OFF" 自 "NAI" lua 表 |
| 0x1407707A0 | defines_ai.h:846 断言; 读 define "CRYPTO_ACTIVATE_NUM_DAYS_DROP_OFF" 自 "NAI" lua 表 |
| 0x1407709B0 | defines_ai.h:853 断言; 读 define "CRYPTO_ACTIVATION_SCORE_ARMIES_IN_COMBAT_BONUS" 自 "NAI" lua 表 |
| 0x140770DD0 | defines_ai.h:851 断言; 读 define "CRYPTO_ACTIVATION_SCORE_OUR_CAPITAL_BONUS" 自 "NAI" lua 表 |
| 0x1407711F0 | defines_ai.h:850 断言; 读 define "CRYPTO_AFTER_SCORE_INVASION_FRONT_BONUS" 自 "NAI" lua 表 |
| 0x140771400 | defines_ai.h:729 断言; 读 define "CURRENT_LAW_SCORE_BONUS" 自 "NAI" lua 表 |
| 0x140771610 | defines_ai.h:1075 断言; 读 define "DANGEROUS_DISTANCE_TO_CAPITAL" 自 "NAI" lua 表 |
| 0x140771DA0 | defines_ai.h:143 断言; 读 define "DAYS_BETWEEN_CHECK_BEST_DOCTRINE" 自 "NAI" lua 表 |
| 0x140771FB0 | defines_ai.h:145 断言; 读 define "DAYS_BETWEEN_CHECK_BEST_EQUIPMENT" 自 "NAI" lua 表 |
| 0x1407725E0 | defines_ai.h:700 断言; 读 define "DAYS_FUEL_REMAINING_TO_ENTER_FUEL_SAVING_MODE_FUEL_RATIO" 自 "NAI" lua 表 |
| 0x140772A00 | defines_ai.h:227 断言; 读 define "DECLARE_WAR_MIN_FRONT_SIZE_TO_CONSIDER_FOR_NOT_READY" 自 "NAI" lua 表 |
| 0x140772E20 | defines_ai.h:45 断言; 读 define "DECLARE_WAR_RELATIVE_FORCE_FACTOR" 自 "NAI" lua 表 |
| 0x1407732F0 | defines_ai.h:109 断言; 读 define "DEFAULT_LEGACY_VARIANT_CREATION_XP_CUTOFF_LAND" 自 "NAI" lua 表 |
| 0x1407735B0 | defines_ai.h:110 断言; 读 define "DEFAULT_LEGACY_VARIANT_CREATION_XP_CUTOFF_NAVY" 自 "NAI" lua 表 |
| 0x140773DF0 | defines_ai.h:107 断言; 读 define "DEFAULT_MODULE_VARIANT_CREATION_XP_CUTOFF_NAVY" 自 "NAI" lua 表 |
| 0x1407746E0 | defines_ai.h:262 断言; 读 define "DEMOCRACIES_ALLY_DEMOCRACIES" 自 "NAI" lua 表 |
| 0x140774B00 | defines_ai.h:266 断言; 读 define "DEMOCRACIES_ANTAGONIZE_COMMUNISTS" 自 "NAI" lua 表 |
| 0x140774F20 | defines_ai.h:264 断言; 读 define "DEMOCRACIES_ANTAGONIZE_FASCISTS" 自 "NAI" lua 表 |
| 0x140775760 | defines_ai.h:468 断言; 读 define "DEMOCRATIC_AI_FACTION_KICKING_PLAYER_THREAT_DIFFERENCE" 自 "NAI" lua 表 |
| 0x140775970 | defines_ai.h:593 断言; 读 define "DEPLOYED_UNIT_MANPOWER_RATIO_TO_BUFFER_PEACETIME" 自 "NAI" lua 表 |
| 0x140775D90 | defines_ai.h:65 断言; 读 define "DEPLOY_MIN_EQUIPMENT_CAP_DEPLOY_FACTOR" 自 "NAI" lua 表 |
| 0x140775FA0 | defines_ai.h:63 断言; 读 define "DEPLOY_MIN_EQUIPMENT_PEACE_FACTOR" 自 "NAI" lua 表 |
| 0x1407761B0 | defines_ai.h:67 断言; 读 define "DEPLOY_MIN_EQUIPMENT_SURRENDER_FACTOR" 自 "NAI" lua 表 |
| 0x1407767E0 | defines_ai.h:66 断言; 读 define "DEPLOY_MIN_TRAINING_SURRENDER_FACTOR" 自 "NAI" lua 表 |
| 0x140776C00 | defines_ai.h:568 断言; 读 define "DESIGN_COMPANY_SCORE_MULTIPLIER" 自 "NAI" lua 表 |
| 0x140776EC0 | defines_ai.h:418 断言; 读 define "DESIRED_UNITS_FACTOR_AREA_ORDER" 自 "NAI" lua 表 |
| 0x1407772E0 | defines_ai.h:424 断言; 读 define "DESIRED_UNITS_FACTOR_INVASION_ORDER" 自 "NAI" lua 表 |
| 0x1407774F0 | defines_ai.h:135 断言; 读 define "DESIRE_USE_XP_TO_UNLOCK_AIR_DOCTRINE" 自 "NAI" lua 表 |
| 0x140777B20 | defines_ai.h:133 断言; 读 define "DESIRE_USE_XP_TO_UNLOCK_LAND_DOCTRINE" 自 "NAI" lua 表 |
| 0x140777D30 | defines_ai.h:134 断言; 读 define "DESIRE_USE_XP_TO_UNLOCK_NAVAL_DOCTRINE" 自 "NAI" lua 表 |
| 0x140777F40 | defines_ai.h:137 断言; 读 define "DESIRE_USE_XP_TO_UNLOCK_NAVY_SPIRIT" 自 "NAI" lua 表 |
| 0x140778150 | defines_ai.h:139 断言; 读 define "DESIRE_USE_XP_TO_UPDATE_LAND_TEMPLATE" 自 "NAI" lua 表 |
| 0x140778570 | defines_ai.h:140 断言; 读 define "DESIRE_USE_XP_TO_UPGRADE_LAND_EQUIPMENT" 自 "NAI" lua 表 |
| 0x140778BA0 | defines_ai.h:603 断言; 读 define "DESPERATE_AI_MIN_ORG_BEFORE_MOVE" 自 "NAI" lua 表 |
| 0x140778DB0 | defines_ai.h:507 断言; 读 define "DESPERATE_AI_MIN_UNIT_ASSIGN_TO_ESCAPE" 自 "NAI" lua 表 |
| 0x140778FC0 | defines_ai.h:601 断言; 读 define "DESPERATE_AI_WEAK_UNIT_STR_LIMIT" 自 "NAI" lua 表 |
| 0x1407791D0 | defines_ai.h:604 断言; 读 define "DESPERATE_ATTACK_WITHOUT_ORG_WHEN_NO_ORG_GAIN" 自 "NAI" lua 表 |
| 0x1407795F0 | defines_ai.h:12 断言; 读 define "DILPOMATIC_ACTION_DECLARE_WAR_WARGOAL_BASE" 自 "NAI" lua 表 |
| 0x140779A10 | defines_ai.h:30 断言; 读 define "DIPLOMACY_ACCEPT_ATTACHE_OPINION_PENALTY" 自 "NAI" lua 表 |
| 0x140779E30 | defines_ai.h:988 断言; 读 define "DIPLOMACY_ACCEPT_CONDITIONAL_SURRENDER_EMBARGO" 自 "NAI" lua 表 |
| 0x14077A040 | defines_ai.h:986 断言; 读 define "DIPLOMACY_ACCEPT_CONDITIONAL_SURRENDER_GLOBAL_TENSION" 自 "NAI" lua 表 |
| 0x14077A250 | defines_ai.h:985 断言; 读 define "DIPLOMACY_ACCEPT_CONDITIONAL_SURRENDER_MANPOWER_IN_FIELD" 自 "NAI" lua 表 |
| 0x14077A460 | defines_ai.h:990 断言; 读 define "DIPLOMACY_ACCEPT_CONDITIONAL_SURRENDER_MINOR_WAR" 自 "NAI" lua 表 |
| 0x14077A670 | defines_ai.h:989 断言; 读 define "DIPLOMACY_ACCEPT_CONDITIONAL_SURRENDER_OWN_SURRENDER_LIMIT" 自 "NAI" lua 表 |
| 0x14077ACA0 | defines_ai.h:338 断言; 读 define "DIPLOMACY_AT_WAR_WITH_ALLY_RELUCTANCE" 自 "NAI" lua 表 |
| 0x14077B0C0 | defines_ai.h:24 断言; 读 define "DIPLOMACY_CALL_ALLY_VALIDITY_DURATION" 自 "NAI" lua 表 |
| 0x14077B4E0 | defines_ai.h:70 断言; 读 define "DIPLOMACY_CREATE_FACTION_FACTOR" 自 "NAI" lua 表 |
| 0x14077B6F0 | defines_ai.h:278 断言; 读 define "DIPLOMACY_FACTION_CIVILWAR_WANTS_HELP" 自 "NAI" lua 表 |
| 0x14077BB10 | defines_ai.h:339 断言; 读 define "DIPLOMACY_FACTION_JOIN_COUP_INITIATOR_BONUS" 自 "NAI" lua 表 |
| 0x14077BD20 | defines_ai.h:284 断言; 读 define "DIPLOMACY_FACTION_MAJOR_AT_WAR" 自 "NAI" lua 表 |
| 0x14077C140 | defines_ai.h:78 断言; 读 define "DIPLOMACY_FACTION_PLAYER_JOIN" 自 "NAI" lua 表 |
| 0x14077C350 | defines_ai.h:72 断言; 读 define "DIPLOMACY_FACTION_SAME_IDEOLOGY_MAJOR" 自 "NAI" lua 表 |
| 0x14077C560 | defines_ai.h:282 断言; 读 define "DIPLOMACY_FACTION_SURRENDER_LEVEL" 自 "NAI" lua 表 |
| 0x14077C770 | defines_ai.h:76 断言; 读 define "DIPLOMACY_FACTION_TAKE_OVER_RELUCTANCE_VERSUS_HUMAN" 自 "NAI" lua 表 |
| 0x14077CDA0 | defines_ai.h:71 断言; 读 define "DIPLOMACY_FACTION_WRONG_IDEOLOGY_PENALTY" 自 "NAI" lua 表 |
| 0x14077CFB0 | defines_ai.h:79 断言; 读 define "DIPLOMACY_IMPROVE_RELATION_COST_FACTOR" 自 "NAI" lua 表 |
| 0x14077D1C0 | defines_ai.h:80 断言; 读 define "DIPLOMACY_IMPROVE_RELATION_PP_FACTOR" 自 "NAI" lua 表 |
| 0x14077D3D0 | defines_ai.h:23 断言; 读 define "DIPLOMACY_LEND_LEASE_MONTHS_TO_CANCEL" 自 "NAI" lua 表 |
| 0x14077D5E0 | defines_ai.h:25 断言; 读 define "DIPLOMACY_PURCHASE_EQUIPMENT_MONTHS" 自 "NAI" lua 表 |
| 0x14077DAB0 | defines_ai.h:77 断言; 读 define "DIPLOMACY_SCARED_MINOR_EXTRA_RELUCTANCE" 自 "NAI" lua 表 |
| 0x14077E500 | defines_ai.h:9 断言; 读 define "DIPLOMATIC_ACTION_GOOD_BAD_RATIO_THRESHOLD" 自 "NAI" lua 表 |
| 0x14077E710 | defines_ai.h:14 断言; 读 define "DIPLOMATIC_ACTION_NAVAL_BLOCKADE_BASE_SCORE" 自 "NAI" lua 表 |
| 0x14077E920 | defines_ai.h:18 断言; 读 define "DIPLOMATIC_ACTION_NAVAL_BLOCKADE_DECREMENT_SAME_IDEOLOGY" 自 "NAI" lua 表 |
| 0x14077EB30 | defines_ai.h:15 断言; 读 define "DIPLOMATIC_ACTION_NAVAL_BLOCKADE_DECREMENT_SCORE_PER_EXISTING_BLOCKADE" 自 "NAI" lua 表 |
| 0x14077EF50 | defines_ai.h:19 断言; 读 define "DIPLOMATIC_ACTION_NAVAL_BLOCKADE_FLEET_SIZE_THRESHOLD" 自 "NAI" lua 表 |
| 0x14077F160 | defines_ai.h:16 断言; 读 define "DIPLOMATIC_ACTION_NAVAL_BLOCKADE_OPINION_SCALING" 自 "NAI" lua 表 |
| 0x14077F370 | defines_ai.h:17 断言; 读 define "DIPLOMATIC_ACTION_NAVAL_BLOCKADE_TENSION_FACTOR" 自 "NAI" lua 表 |
| 0x14077F580 | defines_ai.h:11 断言; 读 define "DIPLOMATIC_ACTION_PROPOSE_SCORE" 自 "NAI" lua 表 |
| 0x140780C10 | defines_ai.h:560 断言; 读 define "DOCKYARDS_PER_NAVAL_DESIRE_EFFECT" 自 "NAI" lua 表 |
| 0x140781030 | defines_ai.h:223 断言; 读 define "EASY_TARGET_FRONT_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140781240 | defines_ai.h:586 断言; 读 define "EMBARGO_WORLD_TENSION_THREAT_DIVISOR" 自 "NAI" lua 表 |
| 0x140781450 | defines_ai.h:798 断言; 读 define "ENEMY_FORTIFICATION_FACTOR_FOR_FRONT_REQUESTS" 自 "NAI" lua 表 |
| 0x140781C90 | defines_ai.h:801 断言; 读 define "ENEMY_PASSING_THROUGH_PLANES_PER_BOMBER" 自 "NAI" lua 表 |
| 0x140781EA0 | defines_ai.h:805 断言; 读 define "ENEMY_PASSING_THROUGH_PLANES_PER_BOMBER_NAVAL_REGION" 自 "NAI" lua 表 |
| 0x1407822C0 | defines_ai.h:806 断言; 读 define "ENEMY_PASSING_THROUGH_PLANES_PER_FIGHTER_NAVAL_REGION" 自 "NAI" lua 表 |
| 0x1407826E0 | defines_ai.h:807 断言; 读 define "ENEMY_PASSING_THROUGH_PLANES_PER_SUPPORT_NAVAL_REGION" 自 "NAI" lua 表 |
| 0x140782D10 | defines_ai.h:88 断言; 读 define "EQUIPMENT_MARKET_BASE_MARKET_RATIO" 自 "NAI" lua 表 |
| 0x1407834A0 | defines_ai.h:89 断言; 读 define "EQUIPMENT_MARKET_DEFAULT_CIC_CHUNK_FOR_SALE" 自 "NAI" lua 表 |
| 0x140783FA0 | defines_ai.h:97 断言; 读 define "EQUIPMENT_MARKET_MAX_CONVOY_RATIO_FOR_MARKET_PEACE" 自 "NAI" lua 表 |
| 0x1407842F0 | defines_ai.h:98 断言; 读 define "EQUIPMENT_MARKET_MAX_CONVOY_RATIO_FOR_MARKET_WAR" 自 "NAI" lua 表 |
| 0x140784900 | defines_ai.h:103 断言; 读 define "EQUIPMENT_MARKET_SCORE_FACTOR_AI_STRAT_WEIGHT" 自 "NAI" lua 表 |
| 0x140784B10 | defines_ai.h:100 断言; 读 define "EQUIPMENT_MARKET_SCORE_FACTOR_CIC_VALUE_NEEDED" 自 "NAI" lua 表 |
| 0x140784D20 | defines_ai.h:102 断言; 读 define "EQUIPMENT_MARKET_SCORE_FACTOR_COST_PER_UNIT" 自 "NAI" lua 表 |
| 0x140785140 | defines_ai.h:101 断言; 读 define "EQUIPMENT_MARKET_SCORE_FACTOR_SUBSIDY_VALUE" 自 "NAI" lua 表 |
| 0x140785560 | defines_ai.h:96 断言; 读 define "EQUIPMENT_MARKET_SHORTAGE_DAYS_TO_CANCEL" 自 "NAI" lua 表 |
| 0x140785820 | defines_ai.h:86 断言; 读 define "EQUIPMENT_MARKET_UPDATE_FREQUENCY_DAYS" 自 "NAI" lua 表 |
| 0x140786300 | defines_ai.h:397 断言; 读 define "EVAL_MODIFIER_MAX_COMMAND_POWER_FACTOR" 自 "NAI" lua 表 |
| 0x140786BF0 | defines_ai.h:704 断言; 读 define "EXPORT_RESOURCE_TRADE_NEED_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140787220 | defines_ai.h:774 断言; 读 define "FAILED_INVASION_AREA_PRIO_FACTOR" 自 "NAI" lua 表 |
| 0x1407874E0 | defines_ai.h:773 断言; 读 define "FAILED_INVASION_AVOID_DURATION" 自 "NAI" lua 表 |
| 0x1407877A0 | defines_ai.h:775 断言; 读 define "FAILED_INVASION_PORT_PRIO_FACTOR" 自 "NAI" lua 表 |
| 0x140787E80 | defines_ai.h:253 断言; 读 define "FASCISTS_ALLY_DEMOCRACIES" 自 "NAI" lua 表 |
| 0x140788090 | defines_ai.h:252 断言; 读 define "FASCISTS_ALLY_FASCISTS" 自 "NAI" lua 表 |
| 0x1407882A0 | defines_ai.h:257 断言; 读 define "FASCISTS_ANTAGONIZE_COMMUNISTS" 自 "NAI" lua 表 |
| 0x140788AE0 | defines_ai.h:250 断言; 读 define "FASCISTS_BEFRIEND_DEMOCRACIES" 自 "NAI" lua 表 |
| 0x140788F00 | defines_ai.h:857 断言; 读 define "FIELDED_EQUIPMENT_BUFFER_RATIO_FOR_OCCUPATION_AI" 自 "NAI" lua 表 |
| 0x140789110 | defines_ai.h:858 断言; 读 define "FIELDED_MANPOWER_BUFFER_RATIO_FOR_OCCUPATION_AI" 自 "NAI" lua 表 |
| 0x140789950 | defines_ai.h:590 断言; 读 define "FORTIFIED_MIN_ORG_FACTOR_TO_CONSIDER_A_FRONT_FORTIFIED" 自 "NAI" lua 表 |
| 0x140789D70 | defines_ai.h:831 断言; 读 define "FORT_LEVEL_TO_CONSIDER_HIGHLY_FORTIFIED" 自 "NAI" lua 表 |
| 0x140789F80 | defines_ai.h:438 断言; 读 define "FRONT_BULGE_RATIO_LOWER_CUTOFF" 自 "NAI" lua 表 |
| 0x14078A3A0 | defines_ai.h:439 断言; 读 define "FRONT_CUTOFF_MIN_EDGE_PROXIMITY" 自 "NAI" lua 表 |
| 0x14078A5B0 | defines_ai.h:761 断言; 读 define "FRONT_EVAL_PERCENT_TO_ASSIST_ALLY_FRONT" 自 "NAI" lua 表 |
| 0x14078A7C0 | defines_ai.h:758 断言; 读 define "FRONT_EVAL_UNIT_ACCURACY" 自 "NAI" lua 表 |
| 0x14078B000 | defines_ai.h:232 断言; 读 define "FRONT_TERRAIN_DEFENSE_FACTOR" 自 "NAI" lua 表 |
| 0x14078B210 | defines_ai.h:426 断言; 读 define "FRONT_UNITS_CAP_FACTOR" 自 "NAI" lua 表 |
| 0x14078B630 | defines_ai.h:693 断言; 读 define "FUEL_CONSUMPTION_MULT_FOR_FUEL_SAVING_MODE" 自 "NAI" lua 表 |
| 0x14078BC60 | defines_ai.h:682 断言; 读 define "FUEL_REQUEST_RATIO_FOR_COMBATS" 自 "NAI" lua 表 |
| 0x14078C080 | defines_ai.h:708 断言; 读 define "FUEL_TRADE_PRIO_FOR_CONVOY_DEFENSE" 自 "NAI" lua 表 |
| 0x14078C290 | defines_ai.h:8 断言; 读 define "GARRISON_FRACTION" 自 "NAI" lua 表 |
| 0x14078C4A0 | defines_ai.h:388 断言; 读 define "GARRISON_TEMPLATE_SCORE_IC_FACTOR" 自 "NAI" lua 表 |
| 0x14078C6B0 | defines_ai.h:389 断言; 读 define "GARRISON_TEMPLATE_SCORE_MANPOWER_FACTOR" 自 "NAI" lua 表 |
| 0x14078CCE0 | defines_ai.h:617 断言; 读 define "GIE_EXILE_AIR_MANPOWER_USAGE_RATIO" 自 "NAI" lua 表 |
| 0x14078D450 | defines_ai.h:211 断言; 读 define "GIVE_STATE_CONTROL_DIFF_FACTOR" 自 "NAI" lua 表 |
| 0x14078D870 | defines_ai.h:215 断言; 读 define "GIVE_STATE_CONTROL_MAX_SCORE_DIST" 自 "NAI" lua 表 |
| 0x14078DA80 | defines_ai.h:206 断言; 读 define "GIVE_STATE_CONTROL_MIN_CONTROLLED" 自 "NAI" lua 表 |
| 0x14078DEA0 | defines_ai.h:213 断言; 读 define "GIVE_STATE_CONTROL_NEIGHBOR_ACTOR_SCORE" 自 "NAI" lua 表 |
| 0x14078E0B0 | defines_ai.h:214 断言; 读 define "GIVE_STATE_CONTROL_NEIGHBOR_OTHER_SCORE" 自 "NAI" lua 表 |
| 0x14078E4D0 | defines_ai.h:59 断言; 读 define "GUN_EMPLACEMENT_ASSIGN_SCORE_REDUCTION_PER_ASSIGNMENT" 自 "NAI" lua 表 |
| 0x14078E8F0 | defines_ai.h:58 断言; 读 define "GUN_EMPLACEMENT_MIN_PRIO_ASSIGN_SCORE" 自 "NAI" lua 表 |
| 0x14078EB00 | defines_ai.h:589 断言; 读 define "HEAVILY_FORTIFIED_RATIO_TO_CONSIDER_A_FRONT_FORTIFIED" 自 "NAI" lua 表 |
| 0x14078F130 | defines_ai.h:337 断言; 读 define "HOURS_BETWEEN_ENCIRCLEMENT_DISCOVERY" 自 "NAI" lua 表 |
| 0x14078F550 | defines_ai.h:995 断言; 读 define "INDUSTRIAL_ORG_POLICY_CHANGE_RANDOMNESS" 自 "NAI" lua 表 |
| 0x14078F810 | defines_ai.h:998 断言; 读 define "INDUSTRIAL_ORG_POLICY_CHANGE_SCALE" 自 "NAI" lua 表 |
| 0x14078FCE0 | defines_ai.h:996 断言; 读 define "INDUSTRIAL_ORG_RESEARCH_ASSIGN_RANDOMNESS" 自 "NAI" lua 表 |
| 0x14078FFA0 | defines_ai.h:1000 断言; 读 define "INDUSTRIAL_ORG_RESEARCH_BONUS_FACTOR" 自 "NAI" lua 表 |
| 0x140790730 | defines_ai.h:825 断言; 读 define "INFRASTRUCTURE_PERCENTAGE_AT_WHICH_TO_BUILD_INFRA_CAP_BUILDING" 自 "NAI" lua 表 |
| 0x140790940 | defines_ai.h:375 断言; 读 define "INTEL_NEEDED_TO_NEGATVE_CONVOY_COUNT_REDUCTION" 自 "NAI" lua 表 |
| 0x140790D60 | defines_ai.h:769 断言; 读 define "INVASION_TARGET_DISTANCE_DENOMINATOR" 自 "NAI" lua 表 |
| 0x1407912E0 | defines_ai.h:772 断言; 读 define "INVASION_TARGET_PRIO_NOT_ENEMY_FACTOR" 自 "NAI" lua 表 |
| 0x140791B00 | defines_ai.h:785 断言; 读 define "INVASION_UNITS_READY_AT_MIN_PLAN" 自 "NAI" lua 表 |
| 0x140791D10 | defines_ai.h:217 断言; 读 define "IRRATIONALITY_LAMBDA" 自 "NAI" lua 表 |
| 0x140791F20 | defines_ai.h:171 断言; 读 define "JOIN_ALLY_BASE_DESIRE" 自 "NAI" lua 表 |
| 0x140792340 | defines_ai.h:172 断言; 读 define "JOIN_ALLY_DEMOCRATIC_DESIRE" 自 "NAI" lua 表 |
| 0x140792760 | defines_ai.h:173 断言; 读 define "JOIN_ALLY_NEUTRAL_DESIRE" 自 "NAI" lua 表 |
| 0x140792B80 | defines_ai.h:488 断言; 读 define "LAND_COMBAT_AIR_SUPERIORITY_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140792D90 | defines_ai.h:500 断言; 读 define "LAND_COMBAT_ANTI_LOGISTICS_PER_ENEMY_ARMY" 自 "NAI" lua 表 |
| 0x140792FA0 | defines_ai.h:503 断言; 读 define "LAND_COMBAT_BOMBERS_PER_COASTAL_FORT_LEVEL" 自 "NAI" lua 表 |
| 0x1407931B0 | defines_ai.h:502 断言; 读 define "LAND_COMBAT_BOMBERS_PER_LAND_FORT_LEVEL" 自 "NAI" lua 表 |
| 0x1407933C0 | defines_ai.h:501 断言; 读 define "LAND_COMBAT_CAS_PER_COMBAT" 自 "NAI" lua 表 |
| 0x1407939F0 | defines_ai.h:493 断言; 读 define "LAND_COMBAT_ENEMY_ARMIES_AIR_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140793E10 | defines_ai.h:494 断言; 读 define "LAND_COMBAT_ENEMY_LAND_FORTS_AIR_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140794020 | defines_ai.h:497 断言; 读 define "LAND_COMBAT_FIGHTERS_PER_PLANE" 自 "NAI" lua 表 |
| 0x140794230 | defines_ai.h:491 断言; 读 define "LAND_COMBAT_FRIEND_ARMIES_AIR_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140794860 | defines_ai.h:496 断言; 读 define "LAND_COMBAT_IMPORTANCE_SCALE" 自 "NAI" lua 表 |
| 0x140794C80 | defines_ai.h:505 断言; 读 define "LAND_COMBAT_MIN_EXCORT_PLANES" 自 "NAI" lua 表 |
| 0x140794E90 | defines_ai.h:506 断言; 读 define "LAND_COMBAT_MISSILE_IMPORTANCE_FACTOR" 自 "NAI" lua 表 |
| 0x1407950A0 | defines_ai.h:489 断言; 读 define "LAND_COMBAT_OUR_ARMIES_AIR_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407952B0 | defines_ai.h:490 断言; 读 define "LAND_COMBAT_OUR_COMBATS_AIR_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407954C0 | defines_ai.h:475 断言; 读 define "LAND_DEFENSE_AA_IMPORTANCE_FACTOR" 自 "NAI" lua 表 |
| 0x1407956D0 | defines_ai.h:470 断言; 读 define "LAND_DEFENSE_AIR_SUPERIORITY_IMPORTANCE" 自 "NAI" lua 表 |
| 0x140795D00 | defines_ai.h:481 断言; 读 define "LAND_DEFENSE_FIGHERS_PER_RAID" 自 "NAI" lua 表 |
| 0x140796120 | defines_ai.h:476 断言; 读 define "LAND_DEFENSE_INFRA_IMPORTANCE_FACTOR" 自 "NAI" lua 表 |
| 0x140796330 | defines_ai.h:485 断言; 读 define "LAND_DEFENSE_INTERCEPTORS_PER_BOMBERS" 自 "NAI" lua 表 |
| 0x140796540 | defines_ai.h:486 断言; 读 define "LAND_DEFENSE_INTERCEPTORS_PER_PLANE" 自 "NAI" lua 表 |
| 0x140796750 | defines_ai.h:482 断言; 读 define "LAND_DEFENSE_INTERCEPTORS_PER_RAID" 自 "NAI" lua 表 |
| 0x140796D80 | defines_ai.h:474 断言; 读 define "LAND_DEFENSE_NAVAL_FACTORY_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407971A0 | defines_ai.h:487 断言; 读 define "LAND_DEFENSE_SAM_MISSILE_IMPORTANCE_FACTOR" 自 "NAI" lua 表 |
| 0x1407975C0 | defines_ai.h:115 断言; 读 define "LAND_DESIGN_ALTERNATIVE_ABSENT" 自 "NAI" lua 表 |
| 0x140797880 | defines_ai.h:117 断言; 读 define "LAND_DESIGN_ALTERNATIVE_OF_EQUAL_TECH" 自 "NAI" lua 表 |
| 0x140797E00 | defines_ai.h:116 断言; 读 define "LAND_DESIGN_ALTERNATIVE_OF_LESSER_TECH" 自 "NAI" lua 表 |
| 0x1407980C0 | defines_ai.h:124 断言; 读 define "LAND_DESIGN_CUTOFF_AS_PERCENTAGE_OF_MAX" 自 "NAI" lua 表 |
| 0x1407989C0 | defines_ai.h:121 断言; 读 define "LAND_DESIGN_DEMAND_GARRISON_DIVISION" 自 "NAI" lua 表 |
| 0x140798C80 | defines_ai.h:120 断言; 读 define "LAND_DESIGN_DEMAND_TRAINING_DIVISION" 自 "NAI" lua 表 |
| 0x140798F40 | defines_ai.h:122 断言; 读 define "LAND_DESIGN_DEMAND_UNUSED_TEMPLATE" 自 "NAI" lua 表 |
| 0x140799A40 | defines_ai.h:579 断言; 读 define "LOW_PRIO_TEMPLATE_BONUS_FOR_GARRISONS" 自 "NAI" lua 表 |
| 0x140799C50 | defines_ai.h:580 断言; 读 define "LOW_PRIO_TEMPLATE_PENALTY_FOR_FRONTS" 自 "NAI" lua 表 |
| 0x140799E60 | defines_ai.h:222 断言; 读 define "MAIN_ENEMY_FRONT_IMPORTANCE" 自 "NAI" lua 表 |
| 0x14079A280 | defines_ai.h:555 断言; 读 define "MANPOWER_RATIO_CAREFULNESS_THRESHOLD" 自 "NAI" lua 表 |
| 0x14079A490 | defines_ai.h:597 断言; 读 define "MANPOWER_RATIO_REQUIRED_TO_PRIO_MOBILIZATION_LAW" 自 "NAI" lua 表 |
| 0x14079A6A0 | defines_ai.h:42 断言; 读 define "MAX_AHEAD_RESEARCH_PENALTY" 自 "NAI" lua 表 |
| 0x14079AE10 | defines_ai.h:595 断言; 读 define "MAX_AVAILABLE_MANPOWER_RATIO_TO_BUFFER_PEACETIME" 自 "NAI" lua 表 |
| 0x14079B020 | defines_ai.h:594 断言; 读 define "MAX_AVAILABLE_MANPOWER_RATIO_TO_BUFFER_WARTIME" 自 "NAI" lua 表 |
| 0x14079B230 | defines_ai.h:658 断言; 读 define "MAX_CAPITAL_FORCES_FOR_INVASION_SUPPORT" 自 "NAI" lua 表 |
| 0x14079B440 | defines_ai.h:935 断言; 读 define "MAX_CAPTURED_GENERALS_TO_STOP_HQ_DEPLOY" 自 "NAI" lua 表 |
| 0x14079B700 | defines_ai.h:563 断言; 读 define "MAX_CARRIER_OVERFILL" 自 "NAI" lua 表 |
| 0x14079B910 | defines_ai.h:934 断言; 读 define "MAX_DEPLOYED_ARMY_HQS" 自 "NAI" lua 表 |
| 0x14079BBD0 | defines_ai.h:355 断言; 读 define "MAX_DISTANCE_NAVAL_INVASION" 自 "NAI" lua 表 |
| 0x14079BDE0 | defines_ai.h:427 断言; 读 define "MAX_DIST_PORT_RUSH" 自 "NAI" lua 表 |
| 0x14079BFF0 | defines_ai.h:368 断言; 读 define "MAX_EXTRA_WARGOAL_GENERATION" 自 "NAI" lua 表 |
| 0x14079C410 | defines_ai.h:679 断言; 读 define "MAX_FACTORY_TO_SPARE_FOR_CRITICAL_MISSION_FUEL_TRADE_IN_PEACE" 自 "NAI" lua 表 |
| 0x14079C620 | defines_ai.h:674 断言; 读 define "MAX_FACTORY_TO_SPARE_FOR_MISSION_FUEL_TRADE" 自 "NAI" lua 表 |
| 0x14079C830 | defines_ai.h:678 断言; 读 define "MAX_FACTORY_TO_SPARE_FOR_MISSION_FUEL_TRADE_IN_PEACE" 自 "NAI" lua 表 |
| 0x14079CE60 | defines_ai.h:721 断言; 读 define "MAX_FUEL_CONSUMPTION_RATIO_FOR_AIR_TRAINING" 自 "NAI" lua 表 |
| 0x14079D070 | defines_ai.h:722 断言; 读 define "MAX_FUEL_CONSUMPTION_RATIO_FOR_NAVY_TRAINING" 自 "NAI" lua 表 |
| 0x14079D280 | defines_ai.h:724 断言; 读 define "MAX_FULLY_TRAINED_SHIP_RATIO_FOR_TRAINING" 自 "NAI" lua 表 |
| 0x14079D6A0 | defines_ai.h:787 断言; 读 define "MAX_INVASION_SIZE" 自 "NAI" lua 表 |
| 0x14079DB70 | defines_ai.h:361 断言; 读 define "MAX_MICRO_ATTACKS_PER_ORDER" 自 "NAI" lua 表 |
| 0x14079DF90 | defines_ai.h:875 断言; 读 define "MAX_MODULAR_EQUIPMENT_EQUIPMENT_UPGRADE_COUNT_PER_PASS" 自 "NAI" lua 表 |
| 0x14079E3B0 | defines_ai.h:812 断言; 读 define "MAX_PORT_RATIO_TO_DISABLE" 自 "NAI" lua 表 |
| 0x14079E7D0 | defines_ai.h:577 断言; 读 define "MAX_PP_TO_SPEND_ON_LOWER_PRIO_TASKS" 自 "NAI" lua 表 |
| 0x14079E9E0 | defines_ai.h:606 断言; 读 define "MAX_REQUEST_EXPEDITIONARIES_ARMY_RATIO" 自 "NAI" lua 表 |
| 0x14079ED30 | defines_ai.h:576 断言; 读 define "MAX_SCALED_IDEA_WEIGHT_TO_COMPARE_WITH_DECISIONS" 自 "NAI" lua 表 |
| 0x14079EF40 | defines_ai.h:657 断言; 读 define "MAX_SCREEN_FORCES_FOR_INVASION_SUPPORT" 自 "NAI" lua 表 |
| 0x14079F150 | defines_ai.h:645 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_CONVOY_DEFENSE_MAX" 自 "NAI" lua 表 |
| 0x14079F360 | defines_ai.h:648 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_CONVOY_DEFENSE_MAX_CONVOY_THREAT" 自 "NAI" lua 表 |
| 0x14079F570 | defines_ai.h:644 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_CONVOY_DEFENSE_MIN" 自 "NAI" lua 表 |
| 0x14079FBA0 | defines_ai.h:650 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_MINE_SWEEPING" 自 "NAI" lua 表 |
| 0x14079FDB0 | defines_ai.h:651 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_MINE_SWEEPING_PRIO" 自 "NAI" lua 表 |
| 0x14079FFC0 | defines_ai.h:653 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_MINE_SWEEPING_PRIO_MAX_MINES" 自 "NAI" lua 表 |
| 0x1407A01D0 | defines_ai.h:652 断言; 读 define "MAX_SCREEN_TASKFORCES_FOR_MINE_SWEEPING_PRIO_MIN_MINES" 自 "NAI" lua 表 |
| 0x1407A05F0 | defines_ai.h:599 断言; 读 define "MAX_THREAT_FOR_FIRST_YEAR_CIVILIAN_MODE" 自 "NAI" lua 表 |
| 0x1407A0800 | defines_ai.h:417 断言; 读 define "MAX_UNITS_FACTOR_AREA_ORDER" 自 "NAI" lua 表 |
| 0x1407A0C20 | defines_ai.h:423 断言; 读 define "MAX_UNITS_FACTOR_INVASION_ORDER" 自 "NAI" lua 表 |
| 0x1407A1040 | defines_ai.h:60 断言; 读 define "MAX_VOLUNTEER_ARMY_FRACTION" 自 "NAI" lua 表 |
| 0x1407A1250 | defines_ai.h:225 断言; 读 define "MICRO_POCKET_SIZE" 自 "NAI" lua 表 |
| 0x1407A1460 | defines_ai.h:466 断言; 读 define "MINES_PLANTING_DESIRE_PER_ENEMY_STATE" 自 "NAI" lua 表 |
| 0x1407A1670 | defines_ai.h:465 断言; 读 define "MINES_PLANTING_DESIRE_PER_HOME_STATE" 自 "NAI" lua 表 |
| 0x1407A1CA0 | defines_ai.h:463 断言; 读 define "MINES_SWEEPING_PLANES_PER_MAX_MINES" 自 "NAI" lua 表 |
| 0x1407A20C0 | defines_ai.h:180 断言; 读 define "MINIMUM_EQUIPMENT_TO_ASK_LEND_LEASE" 自 "NAI" lua 表 |
| 0x1407A22D0 | defines_ai.h:183 断言; 读 define "MINIMUM_FUEL_DAYS_TO_ACCEPT_LEND_LEASE" 自 "NAI" lua 表 |
| 0x1407A24E0 | defines_ai.h:182 断言; 读 define "MINIMUM_FUEL_DAYS_TO_ASK_LEND_LEASE" 自 "NAI" lua 表 |
| 0x1407A2D20 | defines_ai.h:863 断言; 读 define "MIN_AI_SCORE_TO_ECONOMY_LAW_OVERRIDE_HARD_CODED_SCORE" 自 "NAI" lua 表 |
| 0x1407A2F30 | defines_ai.h:862 断言; 读 define "MIN_AI_SCORE_TO_MOBILIZATION_LAW_OVERRIDE_HARD_CODED_SCORE" 自 "NAI" lua 表 |
| 0x1407A3140 | defines_ai.h:864 断言; 读 define "MIN_AI_SCORE_TO_TRADE_LAW_OVERRIDE_HARD_CODED_SCORE" 自 "NAI" lua 表 |
| 0x1407A3350 | defines_ai.h:872 断言; 读 define "MIN_AI_UNITS_PER_TILE_FOR_STANDARD_COHESION" 自 "NAI" lua 表 |
| 0x1407A3770 | defines_ai.h:624 断言; 读 define "MIN_CAPITALS_FOR_CARRIER_TASKFORCE" 自 "NAI" lua 表 |
| 0x1407A4440 | defines_ai.h:1078 断言; 读 define "MIN_FACTORIES_TO_WANT_TO_IMPORT" 自 "NAI" lua 表 |
| 0x1407A4860 | defines_ai.h:235 断言; 读 define "MIN_FORCE_RATIO_TO_PROTECT" 自 "NAI" lua 表 |
| 0x1407A4A70 | defines_ai.h:790 断言; 读 define "MIN_FRONT_SCORE_FOR_AFTER_INVASION_AREAS" 自 "NAI" lua 表 |
| 0x1407A4E90 | defines_ai.h:639 断言; 读 define "MIN_FUEL_RATIO_TO_NOT_IGNORE_INVASION_SUPPORT_COST" 自 "NAI" lua 表 |
| 0x1407A50A0 | defines_ai.h:638 断言; 读 define "MIN_FUEL_RATIO_TO_NOT_IGNORE_STRIKE_FORCE_COST" 自 "NAI" lua 表 |
| 0x1407A52B0 | defines_ai.h:342 断言; 读 define "MIN_INVASION_AREA_SIZE_FOR_FLOATING_HARBORS" 自 "NAI" lua 表 |
| 0x1407A54C0 | defines_ai.h:783 断言; 读 define "MIN_INVASION_ORG_FACTOR_TO_EXECUTE" 自 "NAI" lua 表 |
| 0x1407A58E0 | defines_ai.h:784 断言; 读 define "MIN_INVASION_UNITS_READY_TO_EXECUTE" 自 "NAI" lua 表 |
| 0x1407A5AF0 | defines_ai.h:628 断言; 读 define "MIN_MAIN_SHIP_RATIO" 自 "NAI" lua 表 |
| 0x1407A5D00 | defines_ai.h:634 断言; 读 define "MIN_MAIN_SHIP_RATIO_TO_MERGE" 自 "NAI" lua 表 |
| 0x1407A6120 | defines_ai.h:632 断言; 读 define "MIN_MAIN_SHIP_TO_SPARE" 自 "NAI" lua 表 |
| 0x1407A6540 | defines_ai.h:641 断言; 读 define "MIN_NAVAL_MISSION_PRIO_TO_ASSIGN" 自 "NAI" lua 表 |
| 0x1407A6750 | defines_ai.h:767 断言; 读 define "MIN_NUM_CONQUERED_PROVINCES_TO_DEPRIO_NAVAL_INVADED_FRONTS" 自 "NAI" lua 表 |
| 0x1407A6B70 | defines_ai.h:828 断言; 读 define "MIN_POLITICAL_POWER_MONTHLY_GAIN_FOR_IMPROVE_RELATIONS" 自 "NAI" lua 表 |
| 0x1407A6D80 | defines_ai.h:575 断言; 读 define "MIN_SCALED_IDEA_WEIGHT_TO_COMPARE_WITH_DECISIONS" 自 "NAI" lua 表 |
| 0x1407A71A0 | defines_ai.h:357 断言; 读 define "MIN_SUPPLY_USE_SANITY_CAP" 自 "NAI" lua 表 |
| 0x1407A73B0 | defines_ai.h:629 断言; 读 define "MIN_SUPPORT_SHIP_RATIO" 自 "NAI" lua 表 |
| 0x1407A75C0 | defines_ai.h:631 断言; 读 define "MIN_SUPPORT_SHIP_RATIO_TO_REINFORCE" 自 "NAI" lua 表 |
| 0x1407A79E0 | defines_ai.h:419 断言; 读 define "MIN_UNITS_FACTOR_AREA_ORDER" 自 "NAI" lua 表 |
| 0x1407A7E00 | defines_ai.h:425 断言; 读 define "MIN_UNITS_FACTOR_INVASION_ORDER" 自 "NAI" lua 表 |
| 0x1407A8220 | defines_ai.h:780 断言; 读 define "MIN_WANTED_MAX_FUEL" 自 "NAI" lua 表 |
| 0x1407A8850 | defines_ai.h:690 断言; 读 define "MONTHS_TO_FILL_FUEL_BUFFER_WITH_OIL_REQUESTS" 自 "NAI" lua 表 |
| 0x1407A8A60 | defines_ai.h:691 断言; 读 define "MONTHS_TO_FILL_FUEL_BUFFER_WITH_OIL_REQUESTS_IN_PEACE_TIME" 自 "NAI" lua 表 |
| 0x1407A8C70 | defines_ai.h:840 断言; 读 define "NAVAL_ACCESS_SCORE_PENALTY_PER_EXISTING_ACCESS" 自 "NAI" lua 表 |
| 0x1407A8E80 | defines_ai.h:839 断言; 读 define "NAVAL_ACCESS_SCORE_PENALTY_PER_EXISTING_ACCESS_AT_WAR" 自 "NAI" lua 表 |
| 0x1407A96C0 | defines_ai.h:461 断言; 读 define "NAVAL_COAST_DEFENSE_TENSION_THRESHOLD" 自 "NAI" lua 表 |
| 0x1407A9AE0 | defines_ai.h:449 断言; 读 define "NAVAL_COMBAT_ALLY_NAVY_MULT_ON_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407A9CF0 | defines_ai.h:451 断言; 读 define "NAVAL_COMBAT_MAX_OUR_NAVY_MULT_ON_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407AA110 | defines_ai.h:448 断言; 读 define "NAVAL_COMBAT_OUR_NAVY_MULT_ON_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407AA530 | defines_ai.h:373 断言; 读 define "NAVAL_CONVOY_COUNT_INTEL_DROPOFF_DUE_TO_LOW_DECYPTION" 自 "NAI" lua 表 |
| 0x1407AAB60 | defines_ai.h:457 断言; 读 define "NAVAL_FIGHTERS_PER_PLANE" 自 "NAI" lua 表 |
| 0x1407AAD70 | defines_ai.h:453 断言; 读 define "NAVAL_IMPORTANCE_SCALE" 自 "NAI" lua 表 |
| 0x1407AB240 | defines_ai.h:766 断言; 读 define "NAVAL_INVADED_AREA_PRIO_MULT" 自 "NAI" lua 表 |
| 0x1407AB450 | defines_ai.h:372 断言; 读 define "NAVAL_MAX_CONVOY_TO_INTEL_FOR_CONVOY_RAIDS" 自 "NAI" lua 表 |
| 0x1407AB660 | defines_ai.h:469 断言; 读 define "NAVAL_MIN_EXCORT_PLANES" 自 "NAI" lua 表 |
| 0x1407AB870 | defines_ai.h:400 断言; 读 define "NAVAL_MISSION_AGGRESSIVE_ESCORT_DIVISOR" 自 "NAI" lua 表 |
| 0x1407ABA80 | defines_ai.h:399 断言; 读 define "NAVAL_MISSION_AGGRESSIVE_PATROL_DIVISOR" 自 "NAI" lua 表 |
| 0x1407ABEA0 | defines_ai.h:404 断言; 读 define "NAVAL_MISSION_ESCORT_NEAR_CONTROLLED" 自 "NAI" lua 表 |
| 0x1407AC2C0 | defines_ai.h:370 断言; 读 define "NAVAL_MISSION_INVASION_BASE" 自 "NAI" lua 表 |
| 0x1407AC4D0 | defines_ai.h:406 断言; 读 define "NAVAL_MISSION_MINES_PLANTING_NEAR_CONTROLLED" 自 "NAI" lua 表 |
| 0x1407AC8F0 | defines_ai.h:408 断言; 读 define "NAVAL_MISSION_MINES_SWEEPING_NEAR_CONTROLLED" 自 "NAI" lua 表 |
| 0x1407ACB00 | defines_ai.h:407 断言; 读 define "NAVAL_MISSION_MINES_SWEEPING_NEAR_OWNED" 自 "NAI" lua 表 |
| 0x1407ACF20 | defines_ai.h:401 断言; 读 define "NAVAL_MISSION_PATROL_NEAR_OWNED" 自 "NAI" lua 表 |
| 0x1407AD970 | defines_ai.h:460 断言; 读 define "NAVAL_RANGE_FOR_DOCKING_RIGHTS_CHECK" 自 "NAI" lua 表 |
| 0x1407ADFA0 | defines_ai.h:1076 断言; 读 define "NAVAL_STRIKE_FORCE_OBJECTIVE_IMPORTANCE" 自 "NAI" lua 表 |
| 0x1407AE3C0 | defines_ai.h:459 断言; 读 define "NAVAL_STRIKE_PLANES_PER_SHIP" 自 "NAI" lua 表 |
| 0x1407AE7E0 | defines_ai.h:687 断言; 读 define "NAVY_ACTUAL_FUEL_USAGE_WEIGHT_ON_OIL_REQUEST" 自 "NAI" lua 表 |
| 0x1407AECB0 | defines_ai.h:340 断言; 读 define "NAVY_PREFERED_MAX_SIZE" 自 "NAI" lua 表 |
| 0x1407AF2E0 | defines_ai.h:190 断言; 读 define "NEUTRAL_THREAT_PARANOIA" 自 "NAI" lua 表 |
| 0x1407AF910 | defines_ai.h:1070 断言; 读 define "NUM_CONVOYS_FOR_MAX_PROTECTION" 自 "NAI" lua 表 |
| 0x1407AFE90 | defines_ai.h:829 断言; 读 define "NUM_FACTORIES_IN_STATE_TO_WANT_ENERGY_REDUCTION" 自 "NAI" lua 表 |
| 0x1407B00A0 | defines_ai.h:584 断言; 读 define "NUM_HOURS_SINCE_LAST_COMBAT_TO_SUPPORT_UNITS_VIA_AIR" 自 "NAI" lua 表 |
| 0x1407B02B0 | defines_ai.h:834 断言; 读 define "NUM_RESOURCES_TO_ALLOW_MINOR_EMBARGO" 自 "NAI" lua 表 |
| 0x1407B04C0 | defines_ai.h:742 断言; 读 define "NUM_SILOS_PER_CIVILIAN_FACTORIES" 自 "NAI" lua 表 |
| 0x1407B0D00 | defines_ai.h:738 断言; 读 define "OIL_WANT_AT_PEACE_PER_POTENTIAL_LAND_CONSUMPTION_K" 自 "NAI" lua 表 |
| 0x1407B0F10 | defines_ai.h:740 断言; 读 define "OIL_WANT_AT_PEACE_PER_POTENTIAL_MISC_CONSUMPTION_K" 自 "NAI" lua 表 |
| 0x1407B1120 | defines_ai.h:739 断言; 读 define "OIL_WANT_AT_PEACE_PER_POTENTIAL_NAVY_CONSUMPTION_K" 自 "NAI" lua 表 |
| 0x1407B1330 | defines_ai.h:732 断言; 读 define "OIL_WANT_PER_POTENTIAL_AIR_CONSUMPTION_K" 自 "NAI" lua 表 |
| 0x1407B1750 | defines_ai.h:735 断言; 读 define "OIL_WANT_PER_POTENTIAL_MISC_CONSUMPTION_K" 自 "NAI" lua 表 |
| 0x1407B1B70 | defines_ai.h:860 断言; 读 define "OPERATION_EQUIPMENT_NEED_PRODUCTION_MULT" 自 "NAI" lua 表 |
| 0x1407B1D80 | defines_ai.h:983 断言; 读 define "OPINION_CUTOFF_FOR_IMPROVE_RELATIONS" 自 "NAI" lua 表 |
| 0x1407B21A0 | defines_ai.h:241 断言; 读 define "ORG_UNIT_NORMAL" 自 "NAI" lua 表 |
| 0x1407B23B0 | defines_ai.h:236 断言; 读 define "ORG_UNIT_STRONG" 自 "NAI" lua 表 |
| 0x1407B27D0 | defines_ai.h:1081 断言; 读 define "PATROL_FLEETS_PER_INVASION_REGION_ON_PATH" 自 "NAI" lua 表 |
| 0x1407B2CA0 | defines_ai.h:903 断言; 读 define "PEACE_AI_EVALUATE_FOR_NON_ALLIES" 自 "NAI" lua 表 |
| 0x1407B30C0 | defines_ai.h:906 断言; 读 define "PEACE_AI_EVALUATE_OTHER_ALWAYS" 自 "NAI" lua 表 |
| 0x1407B34E0 | defines_ai.h:904 断言; 读 define "PEACE_AI_EVALUATE_OTHER_IF_CORE" 自 "NAI" lua 表 |
| 0x1407B3BC0 | defines_ai.h:896 断言; 读 define "PEACE_BID_CONTEST_TIE_BREAKER_COUNTRY_SCORE" 自 "NAI" lua 表 |
| 0x1407B4140 | defines_ai.h:898 断言; 读 define "PEACE_BID_FOLD_AGAINST_LIBERATE_CONTEST" 自 "NAI" lua 表 |
| 0x1407B4490 | defines_ai.h:897 断言; 读 define "PEACE_BID_FOLD_AGAINST_PLAYER_CHANCE" 自 "NAI" lua 表 |
| 0x1407B47E0 | defines_ai.h:893 断言; 读 define "PEACE_BID_FOLD_TURNS_AGAINST_OTHER_AI" 自 "NAI" lua 表 |
| 0x1407B4D40 | defines_ai.h:6 断言; 读 define "PEACE_TIME_NAVY_FUEL_LIMIT" 自 "NAI" lua 表 |
| 0x1407B5090 | defines_ai.h:350 断言; 读 define "PLAN_ACTIVATION_MAJOR_WEIGHT_FACTOR" 自 "NAI" lua 表 |
| 0x1407B5AE0 | defines_ai.h:192 断言; 读 define "PLAN_ATTACK_MIN_ORG_FACTOR_LOW" 自 "NAI" lua 表 |
| 0x1407B5F00 | defines_ai.h:197 断言; 读 define "PLAN_ATTACK_MIN_STRENGTH_FACTOR_HIGH" 自 "NAI" lua 表 |
| 0x1407B6110 | defines_ai.h:195 断言; 读 define "PLAN_ATTACK_MIN_STRENGTH_FACTOR_LOW" 自 "NAI" lua 表 |
| 0x1407B6740 | defines_ai.h:243 断言; 读 define "PLAN_FACTION_NORMAL_TO_EXECUTE" 自 "NAI" lua 表 |
| 0x1407B6B60 | defines_ai.h:244 断言; 读 define "PLAN_FACTION_WEAK_TO_ABORT" 自 "NAI" lua 表 |
| 0x1407B6F80 | defines_ai.h:202 断言; 读 define "PLAN_MIN_SIZE_FOR_FALLBACK" 自 "NAI" lua 表 |
| 0x1407B79D0 | defines_ai.h:153 断言; 读 define "PLAN_VALUE_TO_EXECUTE" 自 "NAI" lua 表 |
| 0x1407B7BE0 | defines_ai.h:226 断言; 读 define "POCKET_DISTANCE_MAX" 自 "NAI" lua 表 |
| 0x1407B7DF0 | defines_ai.h:572 断言; 读 define "POLITICAL_ADVISOR_SCORE_MULTIPLIER" 自 "NAI" lua 表 |
| 0x1407B82C0 | defines_ai.h:811 断言; 读 define "PORT_STRIKE_HISTORY_DECAY_MAX" 自 "NAI" lua 表 |
| 0x1407B86E0 | defines_ai.h:813 断言; 读 define "PORT_STRIKE_HISTORY_VALUE_TO_DISABLE_REPAIRS" 自 "NAI" lua 表 |
| 0x1407B8F20 | defines_ai.h:189 断言; 读 define "POTENTIAL_FUTURE_ENEMY_FACTOR" 自 "NAI" lua 表 |
| 0x1407B9550 | defines_ai.h:247 断言; 读 define "PRODUCTION_CARRIER_PLANE_BUFFER_RATIO" 自 "NAI" lua 表 |
| 0x1407B9D90 | defines_ai.h:349 断言; 读 define "PRODUCTION_LINE_SWITCH_SURPLUS_NEEDED_MODIFIER" 自 "NAI" lua 表 |
| 0x1407B9FA0 | defines_ai.h:363 断言; 读 define "PRODUCTION_MAX_PROGRESS_TO_SWITCH_NAVAL" 自 "NAI" lua 表 |
| 0x1407BA3C0 | defines_ai.h:364 断言; 读 define "PRODUCTION_WAIT_TO_FINISH_IF_EXPENSIVE" 自 "NAI" lua 表 |
| 0x1407BA5D0 | defines_ai.h:431 断言; 读 define "PROPOSE_LEND_LEASE_AIDESIRE_SAME_IDEOLOGY" 自 "NAI" lua 表 |
| 0x1407BA9F0 | defines_ai.h:1065 断言; 读 define "RAIDS_AVOID_SAME_TARGET_DURATION_DAYS" 自 "NAI" lua 表 |
| 0x1407BAF70 | defines_ai.h:1061 断言; 读 define "RAIDS_CANCEL_AFTER_DAYS_LAUNCHABLE" 自 "NAI" lua 表 |
| 0x1407BB7B0 | defines_ai.h:1056 断言; 读 define "RAIDS_ENABLE_AI" 自 "NAI" lua 表 |
| 0x1407BBD10 | defines_ai.h:1062 断言; 读 define "RAIDS_NUKE_TARGET_CUT_OFF" 自 "NAI" lua 表 |
| 0x1407BBFD0 | defines_ai.h:1058 断言; 读 define "RAIDS_SCORE_DIFF_TO_CANCEL" 自 "NAI" lua 表 |
| 0x1407BC320 | defines_ai.h:1064 断言; 读 define "RAIDS_UNIT_SCORE_DISTANCE_KM_FACTOR" 自 "NAI" lua 表 |
| 0x1407BC5E0 | defines_ai.h:1063 断言; 读 define "RAIDS_UNIT_SCORE_SUCCESS_CHANCE_FACTOR" 自 "NAI" lua 表 |
| 0x1407BC8A0 | defines_ai.h:386 断言; 读 define "RAILWAY_GUN_ASSIGNMENT_SCORE_HOLD" 自 "NAI" lua 表 |
| 0x1407BCAB0 | defines_ai.h:385 断言; 读 define "RAILWAY_GUN_ASSIGNMENT_SCORE_UNITCOUNT_MULTIPLIER" 自 "NAI" lua 表 |
| 0x1407BCCC0 | defines_ai.h:384 断言; 读 define "RAILWAY_GUN_PER_ARMY_CAP" 自 "NAI" lua 表 |
| 0x14074C8D0 | RTTI 类名 NDefines::CDefineRegistryHelper_<DEFINE>::[0]（func_names rtti 级）；671/671 含串 "Error reading \"<DEFINE>\", \"N<组>\" is not a lua table" + 源路径 defines_*… |
| 0x1407886C0 | 473/473 同族：`NDefines::CDefineRegistryHelper_<NS><KEY>::[0]`；断言串 `Error reading "<KEY>", "<NS>" is not a lua table`；行号锚 `defines_ai.h:368` 等 13 个 defines_*.h；… |
| 0x1408F8630 | 700/700 同族：共享 15 个核心原语（`sub_1421AB9E0`…`sub_14251C47C`）；断言串 `Error reading "<KEY>", "<NS>" is not a lua table`；源文件:行号锚 `defines_ai.h:952` 等 17 个 defines_*.h；… |
| 0x140170BC0 | gameitemdatabase.h:127 断言 + vftable CPersistentReloadableGameItemDatabase<NFactions::CFactionIconsDatabase,NFactions::CFactionIconPool,NDatabaseConfig::SDefa… |
| 0x140173060 | gameitemdatabase.h:127 断言 + vftable CPersistentReloadableGameItemDatabase<NProject::CPrototypeRewardDatabase,NProject::CPrototypeReward,NProject::NDetails::S… |
| 0x1401865B0 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x140186930 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x140186CB0 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x1401870C0 | gameitemdatabase.h:179 断言 "DB already loaded when loading" |
| 0x140187520 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x140187F90 | gameitemdatabase.h:179 断言 "DB already loaded when loading" |
| 0x140188310 | gameitemdatabase.h:179 断言 "DB already loaded when loading" |
| 0x140188790 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x140189180 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x1401895E0 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x14018A4F0 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x14018AF20 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x14018B4F0 | gameitemdatabase.h:160 断言 "DB already loaded when loading" |
| 0x14074E190 | VTABLE slot0 + SRC defines_ai.h + 串 "AIFC_ACTIVATE_AVG_ORG_RATIO_THRESHOLD"/"is not a lua table"/"no lua object named NAI" |
| 0x140757590 | VTABLE RTTI .?AVCDefineRegistryHelper_NAIAIR_DESIGN_CUTOFF_AS_PERCENTAGE_OF_MAX@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x140825D90 | VTABLE RTTI .?AVCDefineRegistryHelper_NDiplomacyPEACE_TIMED_EFFECT_RATIO_CIVILIAN_FACTORY_WAR_REPARATION@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x1408A2740 | VTABLE RTTI .?AVCDefineRegistryHelper_NInterfaceEQUIPMENT_DESIGNER_SHOW_MODULE_FORBIDS_SPECIALIZED_ROLE_ICON@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x1408A7AA0 | VTABLE RTTI .?AVCDefineRegistryHelper_NInterfaceNAVAL_STRIKE_FORCE_ATTACK_LIKELYHOOD_THR_VERY_LIKELY@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x140947690 | VTABLE RTTI .?AVCDefineRegistryHelper_NNavyINTEL_LEVEL_LOW_STRENGTH_ESTIMATE_HALF_RANGE_PERCENTAGE@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x140948390 | VTABLE RTTI .?AVCDefineRegistryHelper_NNavyINTEL_LEVEL_MEDIUM_STRENGTH_ESTIMATE_HALF_RANGE_PERCENTAGE@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x140999AD0 | VTABLE RTTI .?AVCDefineRegistryHelper_NResistanceCOMPLIANCE_FACTOR_ON_STATE_CONTROLLER_CHANGE@NDefines@@[slot0] + SRC defines_*.h + define 名串 |
| 0x140CD6BB0 | 调用图传播：NCombatLog::CManpowerLoss::Reader + 串 "Expected only %d elements" |
| 0x14232C8E0 | func_names 符号名 SCurveAnimationReader::Reader + VTABLE RTTI .?AUSCurveAnimationReader@@[slot4] |

#### 4.26.58 静态资源访问层define 注册 functor 族（1 函）

| VA | 语义/证据 |
|---|---|
| 0x14074D740..0x1409B1210 | NDefines::CDefineRegistryHelper 读取器族（704 个模板实例, 逐 define 从 Lua 表读值; 逐 VA 见 findings/cov_full/_book_inbook.tsv） |

#### 4.26.59 静态资源访问层函数补遗（1267 函）

| VA | 语义/证据 |
|---|---|
| 0x1408F4BC0 | sub_1408F4BC0 业务 define 读取器 · defines_mapmode.h:154 · NMapMode.PEACE_CLAIMED_STATE_COLOR_INDEX · dword 未细分 · ->dword_143334428 |
| 0x1408A6640 | sub_1408A6640 业务 define 读取器 · defines_graphics.h:550 · NInterface.MISSION_CONVOY_ESCORT_SOFT_REQ_THRESHOLD_SUB_DETECTION · qword 未细分 · ->qword_143337370 |
| 0x140895410 | sub_140895410 业务 define 读取器 · defines_intel.h:5 · NIntel.LAND_COMBAT_ARMY_INTEL_OVER_OPPONENT_PER_COMITTED_DIVISIONS · qword 未细分 · ->qword_143334B90 |
| 0x14088F320 | sub_14088F320 业务 define 读取器 · defines_intel.h:273 · NIntel.DYNAMIC_INTEL_SOURCE_CAPTURED_OPERATIVE_FLAT_DECAY · qword 未细分 · ->qword_143337450 |
| 0x140898430 | sub_140898430 业务 define 读取器 · defines_intel.h:16 · NIntel.NAVAL_COMBAT_NAVY_INTEL_OVER_OPPONENT_PER_INSTANCE · qword 未细分 · ->qword_1433352D0 |
| 0x14087F2B0 | sub_14087F2B0 业务 define 读取器 · defines_industrial_organisation.h:7 · NIndustrialOrganisation.FUNDS_FOR_SIZE_UP_LEVEL_POW · qword 未细分 · ->qword_143334080 |
| 0x1408A9110 | sub_1408A9110 业务 define 读取器 · defines_graphics.h:564 · NInterface.OPERATIVE_OPINION_DRIFT_TO_EFFICIENCY_FACTOR · qword 未细分 · ->qword_143337E28 |
| 0x140891160 | sub_140891160 业务 define 读取器 · defines_intel.h:269 · NIntel.DYNAMIC_INTEL_SOURCE_LAND_COMBAT_FLAT_DECAY · qword 未细分 · ->qword_1433360F0 |
| 0x14088D4E0 | sub_14088D4E0 业务 define 读取器 · defines_intel.h:271 · NIntel.DYNAMIC_INTEL_SOURCE_AIR_COMBAT_FLAT_DECAY · qword 未细分 · ->qword_143336A48 |
| 0x140885EA0 | sub_140885EA0 业务 define 读取器 · defines_intel.h:155 · NIntel.ARMY_MIN_INTEL_RATIO_NEEDED_FOR_DISPLAYING_FAKE_ENEMY_INTEL_IN_LEDGER · qword 未细分 · ->qword_143332958 |
| 0x140879ED0 | sub_140879ED0 业务 define 读取器 · defines_graphics.h:395 · NGraphics.TRAIT_LINE_HIGHLIGHT_COLOR · dword 未细分 · ->dword_143332688 |
| 0x1408A1900 | sub_1408A1900 业务 define 读取器 · defines_graphics.h:572 · NInterface.COUNTERINTELLIGENCE_ACTIVITY_LEVEL_THRESHOLD_VALUES · qword 未细分 · ->qword_143338E38 |
| 0x14087CE40 | sub_14087CE40 业务 define 读取器 · defines_graphics.h:294 · NGraphics.WEATHER_ZOOM_IN_CUTOFF · dword 未细分 · ->dword_143335F70 |
| 0x1408ABA50 | sub_1408ABA50 业务 define 读取器 · defines_graphics.h:503 · NInterface.TIMED_MESSAGE_TIMEOUT · dword 未细分 · ->dword_143335BF4 |
| 0x140870580 | sub_140870580 业务 define 读取器 · defines_graphics.h:116 · NGraphics.STATE_BORDER_FADE_FAR · dword 未细分 · ->dword_1433361DC |
| 0x1408A1190 | sub_1408A1190 业务 define 读取器 · defines_graphics.h:473 · NInterface.COMBAT_SOME_PIERCING · dword 未细分 · ->dword_143334CE4 |
| 0x1408A59E0 | sub_1408A59E0 业务 define 读取器 · defines_graphics.h:478 · NInterface.MIN_FOCUS_TREE_ZOOM · dword 未细分 · ->dword_143334F88 |
| 0x140887760 | sub_140887760 业务 define 读取器 · defines_intel.h:146 · NIntel.ARMY_TEMPLATE_UNIT_COUNT_INTEL_RANGE_AT_LOWEST_INTEL · qword 未细分 · ->qword_143332518 |
| 0x140872680 | sub_140872680 业务 define 读取器 · defines_graphics.h:337 · NGraphics.SUN_HEIGHT_WATER · dword 未细分 · ->dword_143337688 |
| 0x14089A5E0 | sub_14089A5E0 业务 define 读取器 · defines_intel.h:33 · NIntel.NAVY_INTEL_BASE_SPOTTING_BONUS_MIN_INTEL_FOR_BONUS · qword 未细分 · ->qword_143336038 |
| 0x14089C6E0 | sub_14089C6E0 业务 define 读取器 · defines_intel.h:160 · NIntel.NAVY_SHIP_TYPE_COUNT_INTEL_RANGE_AT_LOWEST_INTEL · qword 未细分 · ->qword_143332C28 |
| 0x14087B370 | sub_14087B370 业务 define 读取器 · defines_graphics.h:239 · NGraphics.VICTORY_POINT_MAP_ICON_AFTER · qword 未细分 · ->qword_143338A70 |
| 0x1408F79D0 | sub_1408F79D0 业务 define 读取器 · defines_mapmode.h:129 · NMapMode.SHOW_DEPLOYED_GENERAL_BASE_PLATES · bool/int8 · ->byte_143330EBC |
| 0x140889DE0 | sub_140889DE0 业务 define 读取器 · defines_intel.h:95 · NIntel.CIVILIAN_MIN_INTEL_FOR_RESOURCE_ROUTES_TOOLTIPS · qword 未细分 · ->qword_1433382E8 |
| 0x14088AE60 | sub_14088AE60 业务 define 读取器 · defines_intel.h:72 · NIntel.CIVILIAN_PRODUCTION_INTEL_RANGE_AT_LOWEST_INTEL · qword 未细分 · ->qword_143337630 |
| 0x140893AA0 | sub_140893AA0 业务 define 读取器 · defines_intel.h:77 · NIntel.INTEL_TO_SHOW_CURRENTLY_RESEARCHED · qword 未细分 · ->qword_143339130 |
| 0x14089B660 | sub_14089B660 业务 define 读取器 · defines_intel.h:182 · NIntel.NAVY_MIN_INTEL_TO_SHOW_EXISTING_CATEGORY_TYPES · qword 未细分 · ->qword_143333688 |
| 0x14088BEE0 | sub_14088BEE0 业务 define 读取器 · defines_intel.h:113 · NIntel.CIVILIAN_TRAINS_INTEL_RANGE_AT_LOWEST_INTEL · qword 未细分 · ->qword_143331510 |
| 0x140888D60 | sub_140888D60 业务 define 读取器 · defines_intel.h:85 · NIntel.CIVILIAN_INTEL_NEEDED_TO_SHOW_CURRENT_FOCUS · qword 未细分 · ->qword_143337D10 |
| 0x140881460 | sub_140881460 业务 define 读取器 · defines_intel.h:212 · NIntel.AIR_MAPICON_AIR_PORT_PLANE_FUZZY_THRESHOLD · qword 未细分 · ->qword_143334570 |
| 0x140896120 | sub_140896120 业务 define 读取器 · defines_intel.h:248 · NIntel.MAP_INTEL_VISIBILITY_CUTOFFS · qword 未细分 · ->qword_143339220 |
| 0x14089EF10 | sub_14089EF10 业务 define 读取器 · defines_intel.h:65 · NIntel.RECON_PLANE_SEA_DISTRIBUTION · qword 未细分 · ->qword_1433390E8 |
| 0x140902CC0 | sub_140902CC0 业务 define 读取器 · defines_military.h:284 · NMilitary.BATALION_NOT_CHANGED_EXPERIENCE_DROP · qword 未细分 · ->qword_143335D50 |
| 0x140900BC0 | sub_140900BC0 业务 define 读取器 · defines_military.h:400 · NMilitary.ARMY_STRATEGIC_DEPLOYMENT_FUEL_MULT · qword 未细分 · ->qword_143332228 |
| 0x14085FA90 | sub_14085FA90 业务 define 读取器 · defines_graphics.h:273 · NGraphics.NAVAL_MINES_COUNT_TO_VISUAL_ASPECT · qword 未细分 · ->qword_143335400 |
| 0x1408845E0 | sub_1408845E0 业务 define 读取器 · defines_intel.h:238 · NIntel.ARMY_INTEL_COMBAT_BONUS_FACTOR_DEFENSE · qword 未细分 · ->qword_1433351B0 |
| 0x1408866E0 | sub_1408866E0 业务 define 读取器 · defines_intel.h:141 · NIntel.ARMY_MIN_INTEL_TO_SHOW_EQUIPMENT_RATIO · qword 未细分 · ->qword_143332290 |
| 0x140901C40 | sub_140901C40 业务 define 读取器 · defines_military.h:50 · NMilitary.BASE_DIVISION_BRIGADE_CHANGE_COST · qword 未细分 · ->qword_1433345F0 |
| 0x140883560 | sub_140883560 业务 define 读取器 · defines_intel.h:222 · NIntel.ARMY_AVG_ARMOR_RANGE_AT_LOWEST_INTEL · qword 未细分 · ->qword_1433349C0 |
| 0x140870160 | sub_140870160 业务 define 读取器 · defines_graphics.h:139 · NGraphics.SNAPPED_OFF_FRONT_SMOOTHNESS · qword 未细分 · ->qword_1433370D8 |
| 0x1408824E0 | sub_1408824E0 业务 define 读取器 · defines_intel.h:189 · NIntel.AIR_WING_TYPE_COUNT_INTEL_MAX · qword 未细分 · ->qword_143333A18 |
| 0x140885660 | sub_140885660 业务 define 读取器 · defines_intel.h:232 · NIntel.ARMY_MAX_PIERCING_INTEL_MIN · qword 未细分 · ->qword_143334E88 |
| 0x140907D10 | sub_140907D10 业务 define 读取器 · defines_military.h:304 · NMilitary.DISBAND_MANPOWER_LOSS · qword 未细分 · ->qword_1433367E0 |
| 0x1408FF7F0 | sub_1408FF7F0 业务 define 读取器 · defines_military.h:395 · NMilitary.ARMY_FUEL_COST_MULT · qword 未细分 · ->qword_143331FA8 |
| 0x14086E060 | sub_14086E060 业务 define 读取器 · defines_graphics.h:141 · NGraphics.ROOT_FRONT_OFFSET · qword 未细分 · ->qword_143337230 |
| 0x1408FE770 | sub_1408FE770 业务 define 读取器 · defines_military.h:173 · NMilitary.AIR_SUPPORT_BASE · qword 未细分 · ->qword_143331D90 |
| 0x140899560 | sub_140899560 业务 define 读取器 · defines_intel.h:68 · NIntel.NAVAL_SPOT_DECAY · qword 未细分 · ->qword_143337488 |
| 0x1407BD3A0 | defines 读取器；`source\defines_ai.h:383`；lua 表 `NAI` 键 `RAILWAY_GUN_PRODUCTION_MIN_FACTORIES`；sink `sub_142070630`；define 槽 `dword_143332190` |
| 0x1407BD7C0 | defines 读取器；`source\defines_ai.h:553`；lua 表 `NAI` 键 `REASSIGN_TO_ANOTHER_FRONT_IF_IN_COMBAT_FACTOR`；sink `sub_142072500`；define 槽 `qword_143331418` |
| 0x1407BDDF0 | defines 读取器；`source\defines_ai.h:525`；lua 表 `NAI` 键 `RECON_PLANES_STRATEGIC`；sink `sub_142072500`；define 槽 `qword_143337A20` |
| 0x1407BE000 | defines 读取器；`source\defines_ai.h:246`；lua 表 `NAI` 键 `REDEPLOY_DISTANCE_VS_ORDER_SIZE`；sink `sub_142072500`；define 槽 `qword_143334138` |
| 0x1407BEC60 | defines 读取器；`source\defines_ai.h:345`；lua 表 `NAI` 键 `REGION_THREAT_PER_SUNK_CONVOY`；sink `sub_142070630`；define 槽 `dword_143337F70` |
| 0x1407BF080 | defines 读取器；`source\defines_ai.h:209`；lua 表 `NAI` 键 `RELATIVE_STRENGTH_TO_INVADE_DEFENSIVE`；sink `sub_142072500`；define 槽 `qword_143332788` |
| 0x1407BF4A0 | defines 读取器；`source\defines_ai.h:820`；lua 表 `NAI` 键 `REPAIR_TASKFORCE_SIZE`；sink `sub_142070630`；define 槽 `dword_143333A60` |
| 0x1407BF760 | defines 读取器；`source\defines_ai.h:436`；lua 表 `NAI` 键 `REQUEST_LEND_LEASE_CONTAINS_VALUE`；sink `sub_142070630`；define 槽 `dword_143334368` |
| 0x1407BFB80 | defines 读取器；`source\defines_ai.h:37`；lua 表 `NAI` 键 `RESEARCH_AHEAD_BONUS_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332000` |
| 0x1407BFFA0 | defines 读取器；`source\defines_ai.h:35`；lua 表 `NAI` 键 `RESEARCH_AIR_DOCTRINE_NEED_GAIN_FACTOR`；sink `sub_142072500`；define 槽 `unk_143331E90` |
| 0x1407C01B0 | defines 读取器；`source\defines_ai.h:44`；lua 表 `NAI` 键 `RESEARCH_BASE_DAYS`；sink `sub_142072500`；define 槽 `qword_1433327D0` |
| 0x1407C03C0 | defines 读取器；`source\defines_ai.h:38`；lua 表 `NAI` 键 `RESEARCH_BONUS_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433320A8` |
| 0x1407C07E0 | defines 读取器；`source\defines_ai.h:33`；lua 表 `NAI` 键 `RESEARCH_LAND_DOCTRINE_NEED_GAIN_FACTOR`；sink `sub_142072500`；define 槽 `unk_143331CA0` |
| 0x1407C09F0 | defines 读取器；`source\defines_ai.h:41`；lua 表 `NAI` 键 `RESEARCH_LENGTH_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332490` |
| 0x1407C1E70 | defines 读取器；`source\defines_ai.h:220`；lua 表 `NAI` 键 `RESERVE_TO_COMMITTED_BALANCE`；sink `sub_142072500`；define 槽 `qword_143332F18` |
| 0x1407C2290 | defines 读取器；`source\defines_ai.h:730`；lua 表 `NAI` 键 `RESOURCE_WANT_PER_MISSING_BALANCE`；sink `sub_142072500`；define 槽 `qword_143337A80` |
| 0x1407C2AD0 | defines 读取器；`source\defines_ai.h:54`；lua 表 `NAI` 键 `ROCKET_MIN_PRIO_ASSIGN_SCORE`；sink `sub_142070630`；define 槽 `dword_143333000` |
| 0x1407C3310 | defines 读取器；`source\defines_ai.h:621`；lua 表 `NAI` 键 `SCREEN_TASKFORCE_MAX_SHIP_COUNT`；sink `sub_142070630`；define 槽 `unk_143333E48` |
| 0x1407C3730 | defines 读取器；`source\defines_ai.h:433`；lua 表 `NAI` 键 `SEND_VOLUNTEER_AIDESIRE_SAME_IDEOLOGY`；sink `sub_142070630`；define 槽 `dword_1433341A0` |
| 0x1407C3D60 | defines 读取器；`source\defines_ai.h:205`；lua 表 `NAI` 键 `SEND_VOLUNTEER_EVAL_CONTAINMENT_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433324B0` |
| 0x1407C3F70 | defines 读取器；`source\defines_ai.h:204`；lua 表 `NAI` 键 `SEND_VOLUNTEER_EVAL_MAJOER_POWER`；sink `sub_142072500`；define 槽 `qword_143332418` |
| 0x1407C4390 | defines 读取器；`source\defines_ai.h:747`；lua 表 `NAI` 键 `SHIP_STR_RATIO_EXIT_REPAIRS`；sink `sub_142072500`；define 槽 `qword_143330E30` |
| 0x1407C47B0 | defines 读取器；`source\defines_ai.h:321`；lua 表 `NAI` 键 `START_TRAINING_EQUIPMENT_LEVEL`；sink `sub_142072500`；define 槽 `qword_143336F48` |
| 0x1407C4FF0 | defines 读取器；`source\defines_ai.h:322`；lua 表 `NAI` 键 `STOP_TRAINING_EQUIPMENT_LEVEL`；sink `sub_142072500`；define 槽 `qword_143336FF8` |
| 0x1407C5410 | defines 读取器；`source\defines_ai.h:324`；lua 表 `NAI` 键 `STOP_TRAINING_SUPPLY_LEVEL`；sink `sub_142072500`；define 槽 `qword_143337168` |
| 0x1407C5AF0 | defines 读取器；`source\defines_ai.h:508`；lua 表 `NAI` 键 `STR_BOMB_AIR_SUPERIORITY_IMPORTANCE`；sink `sub_142072500`；define 槽 `qword_143336F40` |
| 0x1407C5F10 | defines 读取器；`source\defines_ai.h:517`；lua 表 `NAI` 键 `STR_BOMB_FIGHTERS_PER_PLANE`；sink `sub_142072500`；define 槽 `qword_1433374C8` |
| 0x1407C6330 | defines 读取器；`source\defines_ai.h:514`；lua 表 `NAI` 键 `STR_BOMB_INFRA_IMPORTANCE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143337318` |
| 0x1407C6540 | defines 读取器；`source\defines_ai.h:510`；lua 表 `NAI` 键 `STR_BOMB_MILITARY_FACTORY_IMPORTANCE`；sink `sub_142072500`；define 槽 `qword_143337080` |
| 0x1407C6750 | defines 读取器；`source\defines_ai.h:516`；lua 表 `NAI` 键 `STR_BOMB_MIN_ENEMY_FIGHTERS_IN_AREA`；sink `sub_142070630`；define 槽 `dword_143337428` |
| 0x1407C6B70 | defines 读取器；`source\defines_ai.h:511`；lua 表 `NAI` 键 `STR_BOMB_NAVAL_FACTORY_IMPORTANCE`；sink `sub_142072500`；define 槽 `qword_143337150` |
| 0x1407C73B0 | defines 读取器；`source\defines_ai.h:521`；lua 表 `NAI` 键 `STR_BOMB_PLANES_PER_SUPPLY_HUB`；sink `sub_142072500`；define 槽 `qword_143337750` |
| 0x1407C77D0 | defines 读取器；`source\defines_ai.h:240`；lua 表 `NAI` 键 `STR_UNIT_NORMAL`；sink `sub_142072500`；define 槽 `qword_143333D80` |
| 0x1407C79E0 | defines 读取器；`source\defines_ai.h:237`；lua 表 `NAI` 键 `STR_UNIT_STRONG`；sink `sub_142072500`；define 槽 `qword_143333B78` |
| 0x1407C8010 | defines 读取器；`source\defines_ai.h:1080`；lua 表 `NAI` 键 `SUGGESTED_NUM_MAX_CARRIERS`；sink `sub_142070630`；define 槽 `dword_1433364F0` |
| 0x1407C8620 | defines 读取器；`source\defines_ai.h:609`；lua 表 `NAI` 键 `SURRENDER_LEVEL_TO_PULL_EXPEDITIONARIES_BACK`；sink `sub_142072500`；define 槽 `qword_143333528` |
| 0x1407C8B80 | defines 读取器；`source\defines_ai.h:573`；lua 表 `NAI` 键 `THEORIST_ACCEPTANCE_MULTIPLIER`；sink `sub_142072500`；define 槽 `qword_143332140` |
| 0x1407C93A0 | defines 读取器；`source\defines_ai.h:727`；lua 表 `NAI` 键 `TOO_INSIGNIFICANT_MAX_PENALTY`；sink `sub_142072500`；define 槽 `qword_143337918` |
| 0x1407C95B0 | defines 读取器；`source\defines_ai.h:826`；lua 表 `NAI` 键 `TOTAL_STATE_EXTRACTED_RESOURCES_FOR_BUILDING_RESOURCE_CAP_BUILDING`；sink `sub_142072500`；define 槽 `qword… |
| 0x1407C97C0 | defines 读取器；`source\defines_ai.h:46`；lua 表 `NAI` 键 `TRADEABLE_FACTORIES_FRACTION`；sink `sub_142072500`；define 槽 `qword_1433329C8` |
| 0x1407C9DF0 | defines 读取器；`source\defines_ai_theatre.h:22`；lua 表 `NAITheatre` 键 `AI_THEATRE_AI_FRONT_MIN_DESIRED_RATIO`；sink `sub_142072500`；define 槽 `qword_143337220` |
| 0x1407CA210 | defines 读取器；`source\defines_ai_theatre.h:17`；lua 表 `NAITheatre` 键 `AI_THEATRE_BREAKDOWN_MIN_STATE_COUNT`；sink `sub_142070630`；define 槽 `dword_143336F54` |
| 0x1407CA420 | defines 读取器；`source\defines_ai_theatre.h:13`；lua 表 `NAITheatre` 键 `AI_THEATRE_DISTRIBUTION_MAX_PERCENT_UNMET_DEMAND_PER_FRONT`；sink `sub_142072500`；define 槽 … |
| 0x1407CA630 | defines 读取器；`source\defines_ai_theatre.h:11`；lua 表 `NAITheatre` 键 `AI_THEATRE_DISTRIBUTION_MAX_SCORE`；sink `sub_142070630`；define 槽 `dword_143336C6C` |
| 0x1407CADA0 | defines 读取器；`source\defines_ai_theatre.h:4`；lua 表 `NAITheatre` 键 `AI_THEATRE_GENERATION_BORDER_SIZE_RESTRICTION`；sink `sub_142070630`；define 槽 `dword_1433367B4` |
| 0x1407CAFB0 | defines 读取器；`source\defines_ai_theatre.h:5`；lua 表 `NAITheatre` 键 `AI_THEATRE_GENERATION_DEPTH_TO_START_CONSIDERING_BORDERSTATES`；sink `sub_142070630`；define … |
| 0x1407CB1C0 | defines 读取器；`source\defines_ai_theatre.h:3`；lua 表 `NAITheatre` 键 `AI_THEATRE_GENERATION_HOME_THEATRE_DEPTH_RESTRICTION`；sink `sub_142070630`；define 槽 `dword_… |
| 0x1407CB7F0 | defines 读取器；`source\defines_ai_theatre.h:6`；lua 表 `NAITheatre` 键 `AI_THEATRE_GENERATION_MINIMUM_STATE_COUNT`；sink `sub_142070630`；define 槽 `dword_143336980` |
| 0x1407CBA00 | defines 读取器；`source\defines_ai_theatre.h:20`；lua 表 `NAITheatre` 键 `AI_THEATRE_SEARCH_SUPPLY_NODE_MAX_DEPTH`；sink `sub_142072500`；define 槽 `qword_1433370C8` |
| 0x1407CBC10 | defines 读取器；`source\defines_ai_theatre.h:15`；lua 表 `NAITheatre` 键 `AI_THEATRE_STATE_UPDATE_MAX_STATE_COUNT_TO_EXPAND`；sink `sub_142070630`；define 槽 `dword_14… |
| 0x1407CBE20 | defines 读取器；`source\defines_ai_theatre.h:21`；lua 表 `NAITheatre` 键 `AI_THEATRE_SUPPLY_CRISIS_LIMIT`；sink `sub_142072500`；define 槽 `qword_143337180` |
| 0x1407CC030 | defines 读取器；`source\defines_ai.h:536`；lua 表 `NAI` 键 `UNIT_ASSIGNMENT_STATS_IMPORTANCE`；sink `sub_142072500`；define 槽 `qword_143338120` |
| 0x1407CC240 | defines 读取器；`source\defines_ai.h:547`；lua 表 `NAI` 键 `UNIT_ASSIGNMENT_TERRAIN_IMPORTANCE`；sink `sub_142072500`；define 槽 `qword_143331188` |
| 0x1407CC870 | defines 读取器；`source\defines_ai.h:150`；lua 表 `NAI` 键 `UNLOCK_SPIRIT_TRUNCATION_SELECT_THRESHOLD`；sink `sub_142072500`；define 槽 `qword_143337578` |
| 0x1407CCBC0 | defines 读取器；`source\defines_ai.h:149`；lua 表 `NAI` 键 `UNLOCK_SPIRIT_USE_TRUNCATION_SELECT`；sink `sub_142072840`；define 槽 `byte_143330F7C` |
| 0x1407CCDD0 | defines 读取器；`source\defines_ai.h:881`；lua 表 `NAI` 键 `UPDATE_SUPPLY_BOTTLENECKS_FREQUENCY_HOURS`；sink `sub_142070630`；define 槽 `dword_1433355D4` |
| 0x1407CCFE0 | defines 读取器；`source\defines_ai.h:884`；lua 表 `NAI` 键 `UPDATE_SUPPLY_MOTORIZATION_FREQUENCY_HOURS`；sink `sub_142070630`；define 槽 `dword_143335710` |
| 0x1407CD400 | defines 读取器；`source\defines_ai.h:331`；lua 表 `NAI` 键 `UPGRADE_DIVISION_RELUCTANCE`；sink `sub_142070630`；define 槽 `dword_1433375A8` |
| 0x1407CD820 | defines 读取器；`source\defines_ai.h:114`；lua 表 `NAI` 键 `VARIANT_CREATION_XP_RESERVE_AIR`；sink `sub_142070630`；define 槽 `dword_143335C08` |
| 0x1407CDAE0 | defines 读取器；`source\defines_ai.h:112`；lua 表 `NAI` 键 `VARIANT_CREATION_XP_RESERVE_LAND`；sink `sub_142070630`；define 槽 `dword_143335A90` |
| 0x1407CDDA0 | defines 读取器；`source\defines_ai.h:113`；lua 表 `NAI` 键 `VARIANT_CREATION_XP_RESERVE_NAVY`；sink `sub_142070630`；define 槽 `dword_143335B50` |
| 0x1407CE060 | defines 读取器；`source\defines_ai.h:229`；lua 表 `NAI` 键 `VP_LEVEL_IMPORTANCE_MEDIUM`；sink `sub_142070630`；define 槽 `dword_1433335C0` |
| 0x1407CE270 | defines 读取器；`source\defines_ai.h:228`；lua 表 `NAI` 键 `VP_MAX_PROVINCE_WORTH`；sink `sub_142072500`；define 槽 `qword_1433334B0` |
| 0x1407CE740 | defines 读取器；`source\defines_ai.h:317`；lua 表 `NAI` 键 `WANTED_CARRIER_PLANES_PER_CARRIER_CAPACITY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143336B00` |
| 0x1407CECC0 | defines 读取器；`source\defines_ai.h:313`；lua 表 `NAI` 键 `WANTED_LAND_PLANES_PER_BASE_CAPACITY_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433368D8` |
| 0x1407CF240 | defines 读取器；`source\defines_ai.h:315`；lua 表 `NAI` 键 `WANTED_LAND_PLANES_TOTAL_MAX_PER_DIVISION`；sink `sub_142072500`；define 槽 `qword_143336A38` |
| 0x1407CF500 | defines 读取器；`source\defines_ai.h:777`；lua 表 `NAI` 键 `WANTED_MAX_FUEL_BUFFER_IN_DAYS_FOR_AIR_MAX_CONSUMPTION`；sink `sub_142070630`；define 槽 `dword_14333214C` |
| 0x1407CF710 | defines 读取器；`source\defines_ai.h:779`；lua 表 `NAI` 键 `WANTED_MAX_FUEL_BUFFER_IN_DAYS_FOR_ARMY_MAX_CONSUMPTION`；sink `sub_142070630`；define 槽 `dword_14333227C` |
| 0x1407CF920 | defines 读取器；`source\defines_ai.h:778`；lua 表 `NAI` 键 `WANTED_MAX_FUEL_BUFFER_IN_DAYS_FOR_NAVY_MAX_CONSUMPTION`；sink `sub_142070630`；define 槽 `dword_1433321E8` |
| 0x1407CFB30 | defines 读取器；`source\defines_ai.h:304`；lua 表 `NAI` 键 `WANTED_UNITS_DANGEROUS_NEIGHBOR_FACTOR`；sink `sub_142072500`；define 槽 `qword_143336498` |
| 0x1407CFD40 | defines 读取器；`source\defines_ai.h:300`；lua 表 `NAI` 键 `WANTED_UNITS_INDUSTRY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143336228` |
| 0x1407D0160 | defines 读取器；`source\defines_ai.h:311`；lua 表 `NAI` 键 `WANTED_UNITS_MAX_WANTED_CAP`；sink `sub_142070630`；define 槽 `dword_143336854` |
| 0x1407D0790 | defines 读取器；`source\defines_ai.h:302`；lua 表 `NAI` 键 `WANTED_UNITS_THREAT_MAX`；sink `sub_142072500`；define 槽 `qword_143336368` |
| 0x1407D09A0 | defines 读取器；`source\defines_ai.h:303`；lua 表 `NAI` 键 `WANTED_UNITS_WAR_THREAT_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433363F8` |
| 0x1407D0DC0 | defines 读取器；`source\defines_ai.h:306`；lua 表 `NAI` 键 `WANTED_UNITS_WEIGHT_FRONTS_WANT`；sink `sub_142072500`；define 槽 `qword_1433365E0` |
| 0x1407D11E0 | defines 读取器；`source\defines_ai.h:614`；lua 表 `NAI` 键 `XP_RATIO_REQUIRED_TO_RESEARCH_WITH_XP`；sink `sub_142072500`；define 槽 `qword_1433339C8` |
| 0x1407F1B30 | defines 读取器；`source\defines_career_profile.h:6`；lua 表 `NCareerProfileGUI` 键 `AWARD_POPUP_DURATION`；sink `sub_142070630`；define 槽 `dword_1433373FC` |
| 0x1407F1F50 | defines 读取器；`source\defines_career_profile.h:10`；lua 表 `NCareerProfileGUI` 键 `CAREER_POINTS_ANIMATION_DURATION`；sink `sub_142070630`；define 槽 `dword_1433375C8` |
| 0x14083A500 | defines 读取器；`source\defines_frontend.h:9`；lua 表 `NFrontend` 键 `CAMERA_END_X`；sink `sub_142070980`；define 槽 `dword_143334E78` |
| 0x14083A710 | defines 读取器；`source\defines_frontend.h:10`；lua 表 `NFrontend` 键 `CAMERA_END_Y`；sink `sub_142070980`；define 槽 `dword_143334F14` |
| 0x14083A920 | defines 读取器；`source\defines_frontend.h:11`；lua 表 `NFrontend` 键 `CAMERA_END_Z`；sink `sub_142070980`；define 槽 `dword_143334FB8` |
| 0x14083AB30 | defines 读取器；`source\defines_frontend.h:15`；lua 表 `NFrontend` 键 `CAMERA_INTERPOLATION_SPEED`；sink `sub_142070980`；define 槽 `dword_143335240` |
| 0x14083AD40 | defines 读取器；`source\defines_frontend.h:3`；lua 表 `NFrontend` 键 `CAMERA_LOOKAT_X`；sink `sub_142070980`；define 槽 `dword_143334A48` |
| 0x14083AF50 | defines 读取器；`source\defines_frontend.h:4`；lua 表 `NFrontend` 键 `CAMERA_LOOKAT_Y`；sink `sub_142070980`；define 槽 `dword_143334B08` |
| 0x14083B160 | defines 读取器；`source\defines_frontend.h:5`；lua 表 `NFrontend` 键 `CAMERA_LOOKAT_Z`；sink `sub_142070980`；define 槽 `dword_143334BA4` |
| 0x14083B370 | defines 读取器；`source\defines_frontend.h:13`；lua 表 `NFrontend` 键 `CAMERA_MAX_HEIGHT`；sink `sub_142070980`；define 槽 `dword_1433350F8` |
| 0x14083B790 | defines 读取器；`source\defines_frontend.h:14`；lua 表 `NFrontend` 键 `CAMERA_SPEED_IN_MENUS`；sink `sub_142070980`；define 槽 `dword_1433351A0` |
| 0x14083B9A0 | defines 读取器；`source\defines_frontend.h:6`；lua 表 `NFrontend` 键 `CAMERA_START_X`；sink `sub_142070980`；define 槽 `dword_143334C44` |
| 0x14083BDC0 | defines 读取器；`source\defines_frontend.h:8`；lua 表 `NFrontend` 键 `CAMERA_START_Z`；sink `sub_142070980`；define 槽 `dword_143334DC0` |
| 0x14083BFD0 | defines 读取器；`source\defines_frontend.h:20`；lua 表 `NFrontend` 键 `FRONTEND_LOOK_X`；sink `sub_142070980`；define 槽 `dword_1433354BC` |
| 0x14083C1E0 | defines 读取器；`source\defines_frontend.h:21`；lua 表 `NFrontend` 键 `FRONTEND_LOOK_Y`；sink `sub_142070980`；define 槽 `dword_143335544` |
| 0x14083C3F0 | defines 读取器；`source\defines_frontend.h:22`；lua 表 `NFrontend` 键 `FRONTEND_LOOK_Z`；sink `sub_142070980`；define 槽 `dword_1433355D8` |
| 0x14083C600 | defines 读取器；`source\defines_frontend.h:17`；lua 表 `NFrontend` 键 `FRONTEND_POS_X`；sink `sub_142070980`；define 槽 `dword_1433352E8` |
| 0x14083C810 | defines 读取器；`source\defines_frontend.h:18`；lua 表 `NFrontend` 键 `FRONTEND_POS_Y`；sink `sub_142070980`；define 槽 `dword_143335378` |
| 0x14083CA20 | defines 读取器；`source\defines_frontend.h:19`；lua 表 `NFrontend` 键 `FRONTEND_POS_Z`；sink `sub_142070980`；define 槽 `dword_143335424` |
| 0x14083D050 | defines 读取器；`source\defines_frontend.h:30`；lua 表 `NFrontend` 键 `MP_OPTIONS_LOOK_Z`；sink `sub_142070980`；define 槽 `dword_143335970` |
| 0x14083D260 | defines 读取器；`source\defines_frontend.h:25`；lua 表 `NFrontend` 键 `MP_OPTIONS_POS_X`；sink `sub_142070980`；define 槽 `dword_143335668` |
| 0x14083D470 | defines 读取器；`source\defines_frontend.h:26`；lua 表 `NFrontend` 键 `MP_OPTIONS_POS_Y`；sink `sub_142070980`；define 槽 `dword_143335714` |
| 0x14083D890 | defines 读取器；`source\defines_frontend.h:37`；lua 表 `NFrontend` 键 `NEW_BACKGROUND_DURATION`；sink `sub_142070630`；define 槽 `dword_143335CEC` |
| 0x14083DB50 | defines 读取器；`source\defines_frontend.h:32`；lua 表 `NFrontend` 键 `NEW_GAME_BUTTON_DISABLE_DELAY_ON_INVALID_MAP_DATA`；sink `sub_142070980`；define 槽 `dword_14333… |
| 0x14083E240 | defines 读取器；`source\defines_frontend.h:36`；lua 表 `NFrontend` 键 `TIME_TO_SWAP_BACKGROUNDS`；sink `sub_142070980`；define 槽 `dword_143335C5C` |
| 0x14089F960 | define 读取器; 源锚 `defines_graphics.h:570`; lua 表 `NInterface` · define `AIR_WING_NICHE_ICON_SCALE`; 存储助手 sub_142070980（float）; 全局槽 dword_1433382F8 |
| 0x14089FC30 | define 读取器; 源锚 `defines_graphics.h:569`; lua 表 `NInterface` · define `AIR_WING_REINFORCEMENT_ICON_SCALE`; 存储助手 sub_142070980（float）; 全局槽 dword_143338218 |
| 0x14089FF00 | define 读取器; 源锚 `defines_graphics.h:509`; lua 表 `NInterface` · define `ARMY_GROUP_COLLAPSE_EXTRA_SPACING`; 存储助手 sub_142070630（int32）; 全局槽 dword_143335F00 |
| 0x1408A0740 | define 读取器; 源锚 `defines_graphics.h:512`; lua 表 `NInterface` · define `ARMY_LIST_BOTTOM_PADDING_WITH_EXPEDITIONARIES`; 存储助手 sub_142070630（int32）; 全局槽 dword_14… |
| 0x1408A0950 | define 读取器; 源锚 `defines_graphics.h:468`; lua 表 `NInterface` · define `ARMY_UNIT_LEADER_ICON_SPRITE_ID`; 存储助手 sub_142070630（int32）; 全局槽 dword_143334988 |
| 0x1408A0D70 | define 读取器; 源锚 `defines_graphics.h:474`; lua 表 `NInterface` · define `COMBAT_GOOD_PIERCING`; 存储助手 sub_142070980（float）; 全局槽 dword_143334D90 |
| 0x1408A1D20 | define 读取器; 源锚 `defines_graphics.h:531`; lua 表 `NInterface` · define `DEFAULT_NAVAL_EQUIPMENT_ROLE_ICON`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433367EC |
| 0x1408A1FE0 | define 读取器; 源锚 `defines_graphics.h:529`; lua 表 `NInterface` · define `DEFAULT_TASKFORCE_ICON`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433366B4 |
| 0x1408A21F0 | define 读取器; 源锚 `defines_graphics.h:505`; lua 表 `NInterface` · define `DRAG_AND_DROP_SCROLLING_SENSITIVITY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335CA8 |
| 0x1408A34C0 | define 读取器; 源锚 `defines_graphics.h:481`; lua 表 `NInterface` · define `FOCUS_TREE_ZOOM_FACTOR`; 存储助手 sub_142070980（float）; 全局槽 dword_143335178 |
| 0x1408A3F10 | define 读取器; 源锚 `defines_graphics.h:506`; lua 表 `NInterface` · define `GRIDBOX_ELEMENTS_INTERPOLATION_SPEED`; 存储助手 sub_142070980（float）; 全局槽 dword_143335D40 |
| 0x1408A4330 | define 读取器; 源锚 `defines_graphics.h:575`; lua 表 `NInterface` · define `MAX_DECISIONS_IN_DECISION_ALERT_TOOLTIP`; 存储助手 sub_142070630（int32）; 全局槽 dword_143331598 |
| 0x1408A4540 | define 读取器; 源锚 `defines_graphics.h:479`; lua 表 `NInterface` · define `MAX_FOCUS_TREE_ZOOM`; 存储助手 sub_142070980（float）; 全局槽 dword_143335034 |
| 0x1408A4750 | define 读取器; 源锚 `defines_graphics.h:492`; lua 表 `NInterface` · define `MAX_NON_SUCCESSFUL_COMBAT_COLOR` |
| 0x1408A4960 | define 读取器; 源锚 `defines_graphics.h:471`; lua 表 `NInterface` · define `MAX_NO_FACTION_FILTER_BUTTONS`; 存储助手 sub_142070630（int32）; 全局槽 dword_143334B78 |
| 0x1408A4F90 | define 读取器; 源锚 `defines_graphics.h:499`; lua 表 `NInterface` · define `MINIMAP_PING_DELAY_BETWEEN_PINGS`; 存储助手 sub_142070980（float）; 全局槽 dword_143335A2C |
| 0x1408A51A0 | define 读取器; 源锚 `defines_graphics.h:497`; lua 表 `NInterface` · define `MINIMAP_PING_DURATION`; 存储助手 sub_142070980（float）; 全局槽 dword_143335908 |
| 0x1408A53B0 | define 读取器; 源锚 `defines_graphics.h:498`; lua 表 `NInterface` · define `MINIMAP_PING_SPEEDUP_ON_SCREEN`; 存储助手 sub_142070980（float）; 全局槽 dword_1433359A8 |
| 0x1408A55C0 | define 读取器; 源锚 `defines_graphics.h:501`; lua 表 `NInterface` · define `MINIMAP_TOGGLE_DURATION`; 存储助手 sub_142070980（float）; 全局槽 dword_143335AD0 |
| 0x1408A7400 | define 读取器; 源锚 `defines_graphics.h:542`; lua 表 `NInterface` · define `NAVAL_STRIKE_FORCE_ATTACK_LIKELYHOOD_THR_LIKELY`; 存储助手 sub_142072500（int64）; 全局槽 qword_… |
| 0x1408A8000 | define 读取器; 源锚 `defines_graphics.h:488`; lua 表 `NInterface` · define `NO_COMBATS_COLOR` |
| 0x1408A8790 | define 读取器; 源锚 `defines_graphics.h:557`; lua 表 `NInterface` · define `OPERATIVE_MISSION_EFFICIENCY_ANIMATION_TIME_MAX`; 存储助手 sub_142070980（float）; 全局槽 dword_… |
| 0x1408A9ED0 | define 读取器; 源锚 `defines_graphics.h:519`; lua 表 `NInterface` · define `PICKED_UP_NAVY_OFFSET_X`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433362DC |
| 0x1408AA2F0 | define 读取器; 源锚 `defines_graphics.h:467`; lua 表 `NInterface` · define `PIXEL_OFFSET` |
| 0x1408AA500 | define 读取器; 源锚 `defines_graphics.h:470`; lua 表 `NInterface` · define `POLITICAL_LEADER_ICON_SPRITE_ID`; 存储助手 sub_142070630（int32）; 全局槽 dword_143334AD4 |
| 0x1408AA710 | define 读取器; 源锚 `defines_graphics.h:536`; lua 表 `NInterface` · define `PRODUCTION_SHIP_FILTERS_ROLE_SELECTION_WINDOW_OFFSET_X`; 存储助手 sub_142070630（int32）; 全局槽… |
| 0x1408AAB30 | define 读取器; 源锚 `defines_graphics.h:539`; lua 表 `NInterface` · define `SHIP_FUEL_EFFICIENCY_WARNING_THRESHOLD`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336B60 |
| 0x1408AAD40 | define 读取器; 源锚 `defines_graphics.h:527`; lua 表 `NInterface` · define `SHIP_REFIT_TOOLTIP_MAX_DIFF_LINES`; 存储助手 sub_142070630（int32）; 全局槽 dword_143336608 |
| 0x1408AAF50 | define 读取器; 源锚 `defines_graphics.h:495`; lua 表 `NInterface` · define `SHIP_SELECT_DOUBLE_CLICK_TIME`; 存储助手 sub_142070980（float）; 全局槽 dword_14333585C |
| 0x1408AB160 | define 读取器; 源锚 `defines_graphics.h:582`; lua 表 `NInterface` · define `SLOW_INTERFACE_THRESHOLD`; 存储助手 sub_142070630（int32）; 全局槽 dword_143331940 |
| 0x1408AB630 | define 读取器; 源锚 `defines_graphics.h:523`; lua 表 `NInterface` · define `TASK_FORCE_COMPOSITION_EDITOR_PADDING_TO_NAVIES_VIEW`; 存储助手 sub_142070630（int32）; 全局槽 d… |
| 0x1408AC290 | define 读取器; 源锚 `defines_graphics.h:485`; lua 表 `NInterface` · define `TOOLTIP_SCREEN_TOP_OFFSET_Y`; 存储助手 sub_142070630（int32）; 全局槽 dword_143335358 |
| 0x1408AC4A0 | define 读取器; 源锚 `defines_graphics.h:494`; lua 表 `NInterface` · define `UNIT_SELECT_DOUBLE_CLICK_TIME`; 存储助手 sub_142070980（float）; 全局槽 dword_1433357B0 |
| 0x1408398A0 | defines 读取器；`source\defines_game.h:344`；lua 表 `NFocus` 键 `FOCUS_POINT_DAYS`；sink `sub_142072500`；define 槽 `qword_143335188` |
| 0x140839CC0 | defines 读取器；`source\defines_game.h:346`；lua 表 `NFocus` 键 `FOCUS_PROGRESS_WAR`；sink `sub_142072500`；define 槽 `qword_1433352D8` |
| 0x140839ED0 | defines 读取器；`source\defines_game.h:347`；lua 表 `NFocus` 键 `MAX_SAVED_FOCUS_PROGRESS`；sink `sub_142072500`；define 槽 `qword_143335368` |
| 0x14080E8E0 | defines 读取器；`source\defines_military.h:3`；lua 表 `NDeployment` 键 `BASE_DEPLOYMENT_TRAINING`；sink `sub_142072500`；define 槽 `qword_143332808` |
| 0x1408FD850 | define 读取器; 源锚 `defines_military.h:431`; lua 表 `NMilitary` · define `ABILITY_COMMS_SCALING`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339710 |
| 0x1408FDA60 | define 读取器; 源锚 `defines_military.h:432`; lua 表 `NMilitary` · define `ABILITY_NO_HQ_SCALING`; 存储助手 sub_142072500（int64）; 全局槽 qword_143333500 |
| 0x1408FE350 | define 读取器; 源锚 `defines_military.h:293`; lua 表 `NMilitary` · define `AIR_EQUIPMENT_BASE_COST`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433361D8 |
| 0x1408FEB90 | define 读取器; 源锚 `defines_military.h:94`; lua 表 `NMilitary` · define `AMPHIBIOUS_INVADE_MOVEMENT_COST`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433361B8 |
| 0x1408FF3D0 | define 读取器; 源锚 `defines_military.h:398`; lua 表 `NMilitary` · define `ARMY_COMBAT_FUEL_MULT`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433320F0 |
| 0x1408FFA00 | define 读取器; 源锚 `defines_military.h:90`; lua 表 `NMilitary` · define `ARMY_GENERAL_PREFERRED_TACTIC_WEIGHT_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335F68 |
| 0x1408FFF60 | define 读取器; 源锚 `defines_military.h:401`; lua 表 `NMilitary` · define `ARMY_IDLE_FUEL_MULT`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433322B0 |
| 0x140900380 | define 读取器; 源锚 `defines_military.h:386`; lua 表 `NMilitary` · define `ARMY_LEADER_XP_GAIN_PER_UNIT_IN_COMBAT`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331B48 |
| 0x1409007A0 | define 读取器; 源锚 `defines_military.h:403`; lua 表 `NMilitary` · define `ARMY_MOVEMENT_FUEL_MULT`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433323F8 |
| 0x1409009B0 | define 读取器; 源锚 `defines_military.h:399`; lua 表 `NMilitary` · define `ARMY_NAVAL_TRANSFER_FUEL_MULT`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332188 |
| 0x140901820 | define 读取器; 源锚 `defines_military.h:316`; lua 表 `NMilitary` · define `BASE_CAPTURE_EQUIPMENT_RATIO`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336E60 |
| 0x140901E50 | define 读取器; 源锚 `defines_military.h:49`; lua 表 `NMilitary` · define `BASE_DIVISION_BRIGADE_GROUP_COST`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334540 |
| 0x140902060 | define 读取器; 源锚 `defines_military.h:52`; lua 表 `NMilitary` · define `BASE_DIVISION_SUPPORT_SLOT_COST`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334700 |
| 0x140902480 | define 读取器; 源锚 `defines_military.h:103`; lua 表 `NMilitary` · define `BASE_FORT_PENALTY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336760 |
| 0x1409028A0 | define 读取器; 源锚 `defines_military.h:155`; lua 表 `NMilitary` · define `BASE_NIGHT_ATTACK_PENALTY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331178 |
| 0x140902AB0 | define 读取器; 源锚 `defines_military.h:285`; lua 表 `NMilitary` · define `BATALION_CHANGED_EXPERIENCE_DROP`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335DE8 |
| 0x140903920 | define 读取器; 源锚 `defines_military.h:131`; lua 表 `NMilitary` · define `CASUALTIES_WS_A_PENALTY_DIVISOR` |
| 0x140903B30 | define 读取器; 源锚 `defines_military.h:130`; lua 表 `NMilitary` · define `CASUALTIES_WS_P_PENALTY_DIVISOR` |
| 0x140903D40 | define 读取器; 源锚 `defines_military.h:342`; lua 表 `NMilitary` · define `CASUALTY_COUNT_FOR_HISTORY_ENTRY`; 存储助手 sub_142070630（int32）; 全局槽 dword_143337D48 |
| 0x140903F50 | define 读取器; 源锚 `defines_military.h:85`; lua 表 `NMilitary` · define `CHANCE_TO_AVOID_HIT_AT_NO_DEF`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335BD8 |
| 0x140904160 | define 读取器; 源锚 `defines_military.h:194`; lua 表 `NMilitary` · define `CIVILWAR_ORGANIZATION_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332C10 |
| 0x140904FB0 | define 读取器; 源锚 `defines_military.h:271`; lua 表 `NMilitary` · define `COMBAT_STACKING_EXTRA`; 存储助手 sub_142070630（int32）; 全局槽 dword_14333569C |
| 0x1409053D0 | define 读取器; 源锚 `defines_military.h:270`; lua 表 `NMilitary` · define `COMBAT_STACKING_START`; 存储助手 sub_142070630（int32）; 全局槽 dword_143335608 |
| 0x1409055E0 | define 读取器; 源锚 `defines_military.h:266`; lua 表 `NMilitary` · define `COMBAT_SUPPLY_LACK_ATTACKER_ATTACK`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433353B0 |
| 0x140906030 | define 读取器; 源锚 `defines_military.h:14`; lua 表 `NMilitary` · define `COMBAT_VALUE_STR_IMPORTANCE`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332E50 |
| 0x140906240 | define 读取器; 源锚 `defines_military.h:422`; lua 表 `NMilitary` · define `COMMANDER_ABILITY_BASE_RANGE`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332D38 |
| 0x140906500 | define 读取器; 源锚 `defines_military.h:369`; lua 表 `NMilitary` · define `COMMANDER_LEVEL_UP_STAT_COUNT`; 存储助手 sub_142070630（int32）; 全局槽 dword_143331430 |
| 0x140906710 | define 读取器; 源锚 `defines_military.h:368`; lua 表 `NMilitary` · define `COMMANDER_LEVEL_UP_STAT_WEIGHTS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339650 |
| 0x140906BE0 | define 读取器; 源锚 `defines_military.h:387`; lua 表 `NMilitary` · define `CONSTANT_XP_RATIO_FOR_MULTIPLE_LEADERS_IN_SAME_COMBAT`; 存储助手 sub_142072500（int64）; 全局槽 q… |
| 0x140906DF0 | define 读取器; 源锚 `defines_military.h:6`; lua 表 `NMilitary` · define `CORPS_COMMANDER_ARMIES_CAP`; 存储助手 sub_142070630（int32）; 全局槽 dword_14333297C |
| 0x140907420 | define 读取器; 源锚 `defines_military.h:89`; lua 表 `NMilitary` · define `COUNTRY_PREFERRED_TACTIC_WEIGHT_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335EE0 |
| 0x140907630 | define 读取器; 源锚 `defines_military.h:421`; lua 表 `NMilitary` · define `DAMAGE_SPLIT_ON_FIRST_TARGET`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332C50 |
| 0x1409078F0 | define 读取器; 源锚 `defines_military.h:180`; lua 表 `NMilitary` · define `DEPLOY_TRAINING_MAX_LEVEL`; 存储助手 sub_142070630（int32）; 全局槽 dword_14333226C |
| 0x140907B00 | define 读取器; 源锚 `defines_military.h:105`; lua 表 `NMilitary` · define `DIG_IN_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336880 |
| 0x140907F20 | define 读取器; 源锚 `defines_military.h:312`; lua 表 `NMilitary` · define `DIVISIONAL_COMMANDER_RANK_XP_THRESHOLD`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339548 |
| 0x140908130 | define 读取器; 源锚 `defines_military.h:311`; lua 表 `NMilitary` · define `DIVISIONAL_COMMANDER_TRAIT_XP_REQUIREMENT`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336BA8 |
| 0x140908760 | define 读取器; 源锚 `defines_military.h:193`; lua 表 `NMilitary` · define `ENCIRCLED_DISBAND_MANPOWER_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332B58 |
| 0x1407F5230 | defines 读取器；`source\defines_game.h:103`；lua 表 `NCountry` 键 `ADDITIONAL_MAJOR_COUNTRIES_IC_RATIO`；sink `sub_142072500`；define 槽 `qword_143332C00` |
| 0x1407F5860 | defines 读取器；`source\defines_game.h:167`；lua 表 `NCountry` 键 `AIR_SUPPLY_DROP_EXPIRATION_HOURS`；sink `sub_142070630`；define 槽 `unk_14333508C` |
| 0x1407F5A70 | defines 读取器；`source\defines_game.h:172`；lua 表 `NCountry` 键 `AIR_VOLUNTEER_BASES_CAPACITY_LIMIT`；sink `sub_142072500`；define 槽 `qword_1433353B8` |
| 0x1407F5C80 | defines 读取器；`source\defines_game.h:171`；lua 表 `NCountry` 键 `AIR_VOLUNTEER_PLANES_RATIO`；sink `sub_142072500`；define 槽 `qword_143335318` |
| 0x1407F5E90 | defines 读取器；`source\defines_game.h:187`；lua 表 `NCountry` 键 `ARMY_COUNT_DAILY_DECREASE_FOR_TRAINING_XP`；sink `sub_142072200`；define 槽 `qword_143335AE8` |
| 0x1407F66D0 | defines 读取器；`source\defines_game.h:173`；lua 表 `NCountry` 键 `ATTACHE_XP_SHARE`；sink `sub_142072200`；define 槽 `qword_143335450` |
| 0x1407F68E0 | defines 读取器；`source\defines_game.h:124`；lua 表 `NCountry` 键 `AUTONOMOUS_SPILLOVER`；sink `sub_142072500`；define 槽 `qword_143333AC0` |
| 0x1407F6D00 | defines 读取器；`source\defines_game.h:170`；lua 表 `NCountry` 键 `BASE_COMMAND_POWER_GAIN`；sink `sub_142072500`；define 槽 `qword_143335288` |
| 0x1407F7120 | defines 读取器；`source\defines_game.h:180`；lua 表 `NCountry` 键 `BASE_FUEL_GAIN`；sink `sub_142072500`；define 槽 `qword_1433357D8` |
| 0x1407F7960 | defines 读取器；`source\defines_game.h:36`；lua 表 `NCountry` 键 `BASE_RESEARCH_SLOTS`；sink `sub_142070630`；define 槽 `dword_14333701C` |
| 0x1407F7B70 | defines 读取器；`source\defines_game.h:69`；lua 表 `NCountry` 键 `BASE_STABILITY_PARTY_POPULARITY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143330FC8` |
| 0x1407F7D80 | defines 读取器；`source\defines_game.h:68`；lua 表 `NCountry` 键 `BASE_STABILITY_WAR_FACTOR`；sink `sub_142072500`；define 槽 `qword_143330F30` |
| 0x1407F89E0 | defines 读取器；`source\defines_game.h:125`；lua 表 `NCountry` 键 `CIVIL_WAR_INVOLVEMENT_MIN_TENSION`；sink `sub_142072500`；define 槽 `qword_143333B68` |
| 0x1407F8E00 | defines 读取器；`source\defines_game.h:151`；lua 表 `NCountry` 键 `CONVOYS_BEING_RAIDED_DAILY_WAR_SUPPORT_IMPACT`；sink `sub_142072500`；define 槽 `qword_1433348A0` |
| 0x1407F9010 | defines 读取器；`source\defines_game.h:153`；lua 表 `NCountry` 键 `CONVOYS_BEING_RAIDED_DAILY_WAR_SUPPORT_IMPACT_FROM_OVERSEA_STATES`；sink `sub_142072500`；define 槽 … |
| 0x1407F9430 | defines 读取器；`source\defines_game.h:146`；lua 表 `NCountry` 键 `CONVOYS_BEING_RAIDED_WEEKLY_WAR_SUPPORT_PENALTY_DECAY`；sink `sub_142072200`；define 槽 `qword_14333… |
| 0x1407F9850 | defines 读取器；`source\defines_game.h:152`；lua 表 `NCountry` 键 `CONVOYS_SUNK_MULTIPLIER_FOR_WAR_SUPPORT_FROM_OVERSEA_STATES`；sink `sub_142072500`；define 槽 `qword… |
| 0x1407F9A60 | defines 读取器；`source\defines_game.h:116`；lua 表 `NCountry` 键 `CONVOY_CONTROLLED_ROUTE_COST_REDUCTION_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433334D0` |
| 0x1407F9DB0 | defines 读取器；`source\defines_game.h:114`；lua 表 `NCountry` 键 `CONVOY_INTERNATIONAL_MARKET_RANGE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143333360` |
| 0x1407FA3E0 | defines 读取器；`source\defines_game.h:487`；lua 表 `NCountry` 键 `COUNTRY_MANPOWER_CAPITULATED_CORE_GAIN_FACTOR`；sink `sub_142072500`；define 槽 `qword_143334C48` |
| 0x1407FB040 | defines 读取器；`source\defines_game.h:70`；lua 表 `NCountry` 键 `DEFAULT_COASTAL_PROTECTION_STABILITY`；sink `sub_142072500`；define 槽 `qword_143331078` |
| 0x1407FB460 | defines 读取器；`source\defines_game.h:77`；lua 表 `NCountry` 键 `DEFAULT_WAR_SUPPORT`；sink `sub_142072500`；define 槽 `qword_1433314F8` |
| 0x1407FB670 | defines 读取器；`source\defines_game.h:51`；lua 表 `NCountry` 键 `EQUIPMENT_UPGRADE_CHUNK_MAX_SIZE`；sink `sub_142070630`；define 槽 `dword_1433379A4` |
| 0x1407FB880 | defines 读取器；`source\defines_game.h:35`；lua 表 `NCountry` 键 `EVENT_PROCESS_OFFSET`；sink `sub_142070630`；define 槽 `dword_143336F50` |
| 0x1407FBA90 | defines 读取器；`source\defines_game.h:163`；lua 表 `NCountry` 键 `FEMALE_UNIT_LEADER_BASE_CHANCE`；sink `sub_142071190`；define 槽 `qword_1433386D8` |
| 0x1407FBEB0 | defines 读取器；`source\defines_game.h:178`；lua 表 `NCountry` 键 `FUEL_LEASE_CONVOY_RATIO`；sink `sub_142072200`；define 槽 `qword_1433356A0` |
| 0x1407FC0C0 | defines 读取器；`source\defines_game.h:489`；lua 表 `NCountry` 键 `GIE_CAPITULATE_MAX_STOCKPILE_TRANSFER`；sink `sub_142072500`；define 槽 `qword_143334E58` |
| 0x1407FC760 | defines 读取器；`source\defines_game.h:492`；lua 表 `NCountry` 键 `GIE_CAPITULATION_LEGITIMACY_WARLENGTH_FACTOR`；sink `sub_142072500`；define 槽 `qword_143335198` |
| 0x1407FCCE0 | defines 读取器；`source\defines_game.h:519`；lua 表 `NCountry` 键 `GIE_CONVOY_ON_CREATION`；sink `sub_142070630`；define 槽 `dword_14333687C` |
| 0x1407FD520 | defines 读取器；`source\defines_game.h:513`；lua 表 `NCountry` 键 `GIE_DIVISION_DEFENSE_BONUS_AGAINST_OCCUPIER`；sink `sub_142072500`；define 槽 `qword_143336310` |
| 0x1407FD7E0 | defines 读取器；`source\defines_game.h:515`；lua 表 `NCountry` 键 `GIE_DIVISION_DEFENSE_BONUS_ON_CORE`；sink `sub_142072500`；define 槽 `qword_1433364D8` |
| 0x1407FDAA0 | defines 读取器；`source\defines_game.h:516`；lua 表 `NCountry` 键 `GIE_ESCAPING_DIVISIONS_AMOUNT_RATIO`；sink `sub_142072500`；define 槽 `qword_143336590` |
| 0x1407FE020 | defines 读取器；`source\defines_game.h:509`；lua 表 `NCountry` 键 `GIE_ESCAPING_DIVISIONS_TRANSFER_DAYS`；sink `sub_142070630`；define 槽 `dword_143335FF0` |
| 0x1407FEB20 | defines 读取器；`source\defines_game.h:507`；lua 表 `NCountry` 键 `GIE_EXILE_ARMY_LEADER_LEGITIMACY_LEVELS`；sink `sub_142071190`；define 槽 `qword_143338780` |
| 0x1407FED30 | defines 读取器；`source\defines_game.h:508`；lua 表 `NCountry` 键 `GIE_EXILE_ARMY_LEADER_START_LEVEL`；sink `sub_142070630`；define 槽 `dword_143335F48` |
| 0x1407FF2B0 | defines 读取器；`source\defines_game.h:505`；lua 表 `NCountry` 键 `GIE_EXILE_TROOPS_DEPLOY_TRAINING_MAX_LEVEL`；sink `sub_142070630`；define 槽 `dword_143335D10` |
| 0x1407FF570 | defines 读取器；`source\defines_game.h:504`；lua 表 `NCountry` 键 `GIE_EXILE_TROOP_RECRUITMENT_LEGITIMACY`；sink `sub_142072500`；define 槽 `qword_143335C28` |
| 0x1407FF830 | defines 读取器；`source\defines_game.h:494`；lua 表 `NCountry` 键 `GIE_HOST_CIC_FROM_LEGITIMACY_MAX`；sink `sub_142072500`；define 槽 `qword_143335360` |
| 0x140800070 | defines 读取器；`source\defines_game.h:517`；lua 表 `NCountry` 键 `GIE_LIBERATED_NATION_DAILY_LEGITIMACY_CHANGE`；sink `sub_142072500`；define 槽 `qword_143336688` |
| 0x1408006B0 | defines 读取器；`source\defines_game.h:500`；lua 表 `NCountry` 键 `GIE_MANPOWER_RATO_OF_MAX_START_PENALTY`；sink `sub_142072500`；define 槽 `qword_143335860` |
| 0x140800CC0 | defines 读取器；`source\defines_game.h:506`；lua 表 `NCountry` 键 `GIE_MAX_LEGITIMACY`；sink `sub_142072500`；define 槽 `qword_143335DC0` |
| 0x140801240 | defines 读取器；`source\defines_game.h:498`；lua 表 `NCountry` 键 `GIE_VETERAN_MANPOWER_NON_CORE_GAIN_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433356A8` |
| 0x140801500 | defines 读取器；`source\defines_game.h:493`；lua 表 `NCountry` 键 `GIE_WARSCORE_GAIN_LEGITIMACY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143335278` |
| 0x1408017C0 | defines 读取器；`source\defines_game.h:140`；lua 表 `NCountry` 键 `HEROES_BEING_KILLED_WAR_SUPPORT_PENALTY_SCALE`；sink `sub_142072200`；define 槽 `qword_143334300` |
| 0x1408019D0 | defines 读取器；`source\defines_game.h:141`；lua 表 `NCountry` 键 `HEROES_BEING_KILLED_WEEKLY_WAR_SUPPORT_PENALTY_DECAY`；sink `sub_142072200`；define 槽 `qword_143334… |
| 0x140801BE0 | defines 读取器；`source\defines_game.h:56`；lua 表 `NCountry` 键 `INDUSTRY_SCORE_MULTIPLIER`；sink `sub_142072500`；define 槽 `qword_143337D00` |
| 0x140802140 | defines 读取器；`source\defines_game.h:161`；lua 表 `NCountry` 键 `INTERCEPTION_BOMBING_WAR_SUPPORT_IMPACT`；sink `sub_142072500`；define 槽 `qword_143334DE0` |
| 0x140802350 | defines 读取器；`source\defines_game.h:160`；lua 表 `NCountry` 键 `INTERCEPTION_WAR_SUPPORT_SCALE`；sink `sub_142072200`；define 槽 `qword_143334D08` |
| 0x140802560 | defines 读取器；`source\defines_game.h:96`；lua 表 `NCountry` 键 `INTERPOLATED_FRONT_STEPS_SHORT`；sink `sub_142070630`；define 槽 `dword_1433326E8` |
| 0x140802980 | defines 读取器；`source\defines_game.h:65`；lua 表 `NCountry` 键 `LOCAL_MANPOWER_ACCESSIBLE_NON_CORE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143338378` |
| 0x140802DA0 | defines 读取器；`source\defines_game.h:104`；lua 表 `NCountry` 键 `MAJOR_MIN_FACTORIES`；sink `sub_142070630`；define 槽 `dword_143332C94` |
| 0x140802FB0 | defines 读取器；`source\defines_game.h:137`；lua 表 `NCountry` 键 `MAX_BOMBING_WAR_SUPPORT_IMPACT`；sink `sub_142072200`；define 槽 `qword_1433341C8` |
| 0x1408031C0 | defines 读取器；`source\defines_game.h:138`；lua 表 `NCountry` 键 `MAX_BOMBING_WEEKLY_WAR_SUPPORT_PENALTY`；sink `sub_142072200`；define 槽 `qword_143334268` |
| 0x1408033D0 | defines 读取器；`source\defines_game.h:147`；lua 表 `NCountry` 键 `MAX_CONVOYS_BEING_RAIDED_WAR_SUPPORT_IMPACT`；sink `sub_142072200`；define 槽 `qword_1433346B0` |
| 0x1408035E0 | defines 读取器；`source\defines_game.h:148`；lua 表 `NCountry` 键 `MAX_CONVOYS_BEING_RAIDED_WEEKLY_WAR_SUPPORT_PENALTY`；sink `sub_142072200`；define 槽 `qword_143334748` |
| 0x1408037F0 | defines 读取器；`source\defines_game.h:72`；lua 表 `NCountry` 键 `MAX_COUP_STABILITY_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433311D0` |
| 0x140803C10 | defines 读取器；`source\defines_game.h:143`；lua 表 `NCountry` 键 `MAX_HEROES_BEING_KILLED_WEEKLY_WAR_SUPPORT_PENALTY`；sink `sub_142072200`；define 槽 `qword_1433344E0` |
| 0x140803E20 | defines 读取器；`source\defines_game.h:85`；lua 表 `NCountry` 键 `MAX_INTELLIGENCE_AIR_DATA_DEVIATION`；sink `sub_142072500`；define 槽 `qword_143331CB8` |
| 0x140804A20 | defines 读取器；`source\defines_game.h:89`；lua 表 `NCountry` 键 `MAX_INTELLIGENCE_FIELDED_MANPOWER_DATA_DEVIATION`；sink `sub_142072500`；define 槽 `qword_1433321E0` |
| 0x140804D70 | defines 读取器；`source\defines_game.h:86`；lua 表 `NCountry` 键 `MAX_INTELLIGENCE_INDUSTRY_DATA_DEVIATION`；sink `sub_142072500`；define 槽 `qword_143331E20` |
| 0x140805410 | defines 读取器；`source\defines_game.h:83`；lua 表 `NCountry` 键 `MAX_INTELLIGENCE_MILITARY_DATA_DEVIATION`；sink `sub_142072500`；define 槽 `qword_143331A20` |
| 0x140805AB0 | defines 读取器；`source\defines_game.h:66`；lua 表 `NCountry` 键 `MAX_NON_CORE_MANPOWER_FACTOR`；sink `sub_142072500`；define 槽 `qword_143338418` |
| 0x140805ED0 | defines 读取器；`source\defines_game.h:156`；lua 表 `NCountry` 键 `MAX_PROPAGANDA_WAR_SUPPORT_IMPACT`；sink `sub_142072200`；define 槽 `qword_143334B18` |
| 0x1408060E0 | defines 读取器；`source\defines_game.h:106`；lua 表 `NCountry` 键 `MAX_STABILITY`；sink `sub_142072500`；define 槽 `qword_143332DF8` |
| 0x1408062F0 | defines 读取器；`source\defines_game.h:108`；lua 表 `NCountry` 键 `MAX_WAR_SUPPORT`；sink `sub_142072500`；define 槽 `qword_143332F38` |
| 0x140806710 | defines 读取器；`source\defines_game.h:71`；lua 表 `NCountry` 键 `MIN_COUP_STABILITY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143331128` |
| 0x140806B30 | defines 读取器；`source\defines_game.h:122`；lua 表 `NCountry` 键 `MIN_FOCUSES_FOR_CONTINUOUS`；sink `sub_142070630`；define 槽 `dword_143333940` |
| 0x140806D40 | defines 读取器；`source\defines_game.h:102`；lua 表 `NCountry` 键 `MIN_MAJOR_COUNTRIES`；sink `sub_142070630`；define 槽 `dword_143332B38` |
| 0x140807370 | defines 读取器；`source\defines_game.h:107`；lua 表 `NCountry` 键 `MIN_STABILITY`；sink `sub_142072500`；define 槽 `qword_143332E98` |
| 0x140807BB0 | defines 读取器；`source\defines_game.h:115`；lua 表 `NCountry` 键 `NAVY_USE_HOME_BASE_FOR_RANGE`；sink `sub_142072840`；define 槽 `byte_143330E97` |
| 0x140807DC0 | defines 读取器；`source\defines_game.h:58`；lua 表 `NCountry` 键 `NUCLEAR_BOMB_DROP_WAR_SUPPORT_EFFECT_MAX_INFRA`；sink `sub_142072500`；define 槽 `qword_143337E78` |
| 0x140807FD0 | defines 读取器；`source\defines_game.h:59`；lua 表 `NCountry` 键 `NUCLEAR_BOMB_DROP_WAR_SUPPORT_EFFECT_MAX_VP`；sink `sub_142070630`；define 槽 `dword_143337F3C` |
| 0x1408081E0 | defines 读取器；`source\defines_game.h:165`；lua 表 `NCountry` 键 `NUM_DAYS_TO_FULLY_DELETE_STOCKPILED_EQUIPMENT`；sink `sub_142070630`；define 槽 `dword_143334F38` |
| 0x140808810 | defines 读取器；`source\defines_game.h:99`；lua 表 `NCountry` 键 `POLITICAL_POWER_UPPER_CAP`；sink `sub_142072500`；define 槽 `qword_143332918` |
| 0x140808C30 | defines 读取器；`source\defines_game.h:157`；lua 表 `NCountry` 键 `PROPAGANDA_STABILITY_DAILY_DECAY`；sink `sub_142072200`；define 槽 `qword_143334BC0` |
| 0x140808E40 | defines 读取器；`source\defines_game.h:158`；lua 表 `NCountry` 键 `PROPAGANDA_WAR_SUPPORT_DAILY_DECAY`；sink `sub_142072200`；define 槽 `qword_143334C68` |
| 0x140809050 | defines 读取器；`source\defines_game.h:57`；lua 表 `NCountry` 键 `PROVINCE_SCORE_MULTIPLIER`；sink `sub_142072500`；define 槽 `qword_143337DC8` |
| 0x140809260 | defines 读取器；`source\defines_game.h:45`；lua 表 `NCountry` 键 `REINFORCEMENT_AIRBASE_PRIORITY_COUNT`；sink `sub_142070630`；define 槽 `dword_143337588` |
| 0x140809AA0 | defines 读取器；`source\defines_game.h:42`；lua 表 `NCountry` 键 `REINFORCEMENT_DIVISION_PRIORITY_DEFAULT`；sink `sub_142070630`；define 槽 `dword_1433373CC` |
| 0x140809CB0 | defines 读取器；`source\defines_game.h:48`；lua 表 `NCountry` 键 `REINFORCEMENT_EQUIPMENT_DELIVERY_SPEED`；sink `sub_142072500`；define 槽 `qword_143337770` |
| 0x14080A910 | defines 读取器；`source\defines_game.h:101`；lua 表 `NCountry` 键 `RESISTANCE_IMPORTANT_COUNTRY_LEVEL`；sink `sub_142072500`；define 槽 `qword_143332A70` |
| 0x14080AD30 | defines 读取器；`source\defines_game.h:39`；lua 表 `NCountry` 键 `RESISTANCE_STRENGTH_FROM_NEIGHBORS`；sink `sub_142072500`；define 槽 `qword_143337238` |
| 0x14080B150 | defines 读取器；`source\defines_game.h:95`；lua 表 `NCountry` 键 `RESOURCE_IMPORTANCE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332630` |
| 0x14080B570 | defines 读取器；`source\defines_game.h:174`；lua 表 `NCountry` 键 `SPECIAL_FORCES_CAP_BASE`；sink `sub_142072500`；define 槽 `qword_1433354E8` |
| 0x14080BBA0 | defines 读取器；`source\defines_game.h:179`；lua 表 `NCountry` 键 `STARTING_FUEL_RATIO`；sink `sub_142072500`；define 槽 `unk_143335740` |
| 0x14080BDB0 | defines 读取器；`source\defines_game.h:118`；lua 表 `NCountry` 键 `STATE_VALUE_BASE`；sink `sub_142072500`；define 槽 `qword_143333620` |
| 0x14080C070 | defines 读取器；`source\defines_game.h:119`；lua 表 `NCountry` 键 `STATE_VALUE_BUILDING_SLOTS_MULT`；sink `sub_142072500`；define 槽 `qword_143333710` |
| 0x14080C6A0 | defines 读取器；`source\defines_game.h:520`；lua 表 `NCountry` 键 `SURRENDER_LIMIT_MULT_FOR_COUNTRIES_WITH_NO_CORES`；sink `sub_142072500`；define 槽 `qword_143336920` |
| 0x14080C9F0 | defines 读取器；`source\defines_game.h:131`；lua 表 `NCountry` 键 `SURRENDER_LIMIT_REDUCTION_PER_COLLABORATION`；sink `sub_142072500`；define 槽 `qword_143333EA8` |
| 0x14080CC00 | defines 读取器；`source\defines_game.h:132`；lua 表 `NCountry` 键 `SURRENDER_RECIPIENT_SCORE_PER_COLLABORATION`；sink `sub_142072500`；define 槽 `qword_143333F50` |
| 0x14080D020 | defines 读取器；`source\defines_game.h:60`；lua 表 `NCountry` 键 `THERMONUCLEAR_BOMB_DROP_WAR_SUPPORT_EFFECT_MAX_INFRA`；sink `sub_142072500`；define 槽 `qword_143337FF0` |
| 0x14080D230 | defines 读取器；`source\defines_game.h:61`；lua 表 `NCountry` 键 `THERMONUCLEAR_BOMB_DROP_WAR_SUPPORT_EFFECT_MAX_VP`；sink `sub_142070630`；define 槽 `dword_1433380A8` |
| 0x14080D440 | defines 读取器；`source\defines_game.h:126`；lua 表 `NCountry` 键 `UNCAPITULATE_LEVEL`；sink `sub_142072500`；define 槽 `qword_143333C18` |
| 0x14080D860 | defines 读取器；`source\defines_game.h:75`；lua 表 `NCountry` 键 `WAR_SUPPORT_DEFENSIVE_WAR`；sink `sub_142072500`；define 槽 `qword_1433313B8` |
| 0x14080DC80 | defines 读取器；`source\defines_game.h:74`；lua 表 `NCountry` 键 `WAR_SUPPORT_OFFNSIVE_WAR`；sink `sub_142072500`；define 槽 `qword_143331310` |
| 0x14080E4C0 | defines 读取器；`source\defines_game.h:524`；lua 表 `NCountry` 键 `WILL_LEAD_TO_WAR_DECISION_PERSISTENCE`；sink `sub_142070630`；define 槽 `dword_143336B58` |
| 0x14080E6D0 | defines 读取器；`source\defines_game.h:523`；lua 表 `NCountry` 键 `WILL_LEAD_TO_WAR_FOCUS_PERSISTENCE`；sink `sub_142070630`；define 槽 `dword_143336AC0` |
| 0x140841E20 | defines 读取器；`source\geography\defines_geography.h:4`；lua 表 `NGeography` 键 `MEDITERRANEAN_SEA_REGIONS`；sink `sub_142070C50`；define 槽 `qword_1433387C8` |
| 0x1408AC6B0 | define 读取器; 源锚 `defines_mapmode.h:198`; lua 表 `NMapIcons` · define `COARSE_RAILWAY_GUN_POSITION_OFFSET`; 存储助手 sub_142071770（dword 未细分）; 全局槽 dword_1433325B8 |
| 0x1408AC8C0 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335634 |
| 0x1408ACAD0 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334EF4 |
| 0x1408AD100 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334E3C |
| 0x1408AD310 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433350C8 |
| 0x1408AD520 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335020 |
| 0x1408AD730 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333534C |
| 0x1408AD940 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408ADB50 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335170 |
| 0x1408AE180 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408AE7B0 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433353F8 |
| 0x1408AEBD0 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334D7C |
| 0x1408AF620 | define 读取器; 源锚 `defines_mapmode.h:166`; lua 表 `NMapIcons` · define `DEFAULT_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334CD0 |
| 0x1408AF830 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337340 |
| 0x1408AFA40 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336BA0 |
| 0x1408B0070 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408B0280 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336DBC |
| 0x1408B06A0 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337024 |
| 0x1408B0AC0 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336E58 |
| 0x1408B10F0 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408B1720 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433370EC |
| 0x1408B1930 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433372D8 |
| 0x1408B1B40 | define 读取器; 源锚 `defines_mapmode.h:176`; lua 表 `NMapIcons` · define `DEPLOYMENT_AIR_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336A70 |
| 0x1408B27A0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408B29B0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433313E0 |
| 0x1408B2BC0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433319D4 |
| 0x1408B3820 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408B3C40 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408B3E50 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 by… |
| 0x1408B4690 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433… |
| 0x1408B48A0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331B40 |
| 0x1408B4AB0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331288 |
| 0x1408B4CC0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331468 |
| 0x1408B4ED0 | define 读取器; 源锚 `defines_mapmode.h:178`; lua 表 `NMapIcons` · define `DEPLOYMENT_MILITARY_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte… |
| 0x1408B5920 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337A74 |
| 0x1408B5B30 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433380CC |
| 0x1408B5D40 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_CAPITAL`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143338184 |
| 0x1408B5F50 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433… |
| 0x1408B6370 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337BCC |
| 0x1408B6580 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337F5C |
| 0x1408B69A0 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337D1C |
| 0x1408B6BB0 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337DE4 |
| 0x1408B6DC0 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1… |
| 0x1408B6FD0 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408B7600 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333800C |
| 0x1408B7A20 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337904 |
| 0x1408B7C30 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337B1C |
| 0x1408B7E40 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408B8470 | define 读取器; 源锚 `defines_mapmode.h:177`; lua 表 `NMapIcons` · define `DEPLOYMENT_NAVY_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333783C |
| 0x1408B8680 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 by… |
| 0x1408B8890 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408B8AA0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_… |
| 0x1408B8EC0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽… |
| 0x1408B90D0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408B9700 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408B9910 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1… |
| 0x1408B9B20 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte… |
| 0x1408B9D30 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; … |
| 0x1408B9F40 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408BA150 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽… |
| 0x1408BA990 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408BABA0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_… |
| 0x1408BADB0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局… |
| 0x1408BAFC0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_… |
| 0x1408BB1D0 | define 读取器; 源锚 `defines_mapmode.h:181`; lua 表 `NMapIcons` · define `DIPLOMACY_FABRICATE_CLAIM_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽… |
| 0x1408BBA10 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433346E0 |
| 0x1408BBE30 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433340BC |
| 0x1408BCA90 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334478 |
| 0x1408BCCA0 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334514 |
| 0x1408BCEB0 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408BD0C0 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334B6C |
| 0x1408BD2D0 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_NAVAL_MINES` |
| 0x1408BDB10 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334210 |
| 0x1408BDD20 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334C1C |
| 0x1408BDF30 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333E4C |
| 0x1408BE140 | define 读取器; 源锚 `defines_mapmode.h:173`; lua 表 `NMapIcons` · define `DIPLOMACY_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333EE8 |
| 0x1408BEB90 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_CAPITAL`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335630 |
| 0x1408BEDA0 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334F6C |
| 0x1408BEFB0 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333520C |
| 0x1408BF1C0 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333516C |
| 0x1408BF3D0 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335478 |
| 0x1408BFE20 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408C0030 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433359E0 |
| 0x1408C0450 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335504 |
| 0x1408C10B0 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334D78 |
| 0x1408C12C0 | define 读取器; 源锚 `defines_mapmode.h:174`; lua 表 `NMapIcons` · define `FACTIONS_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334E38 |
| 0x1408C1D10 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336470 |
| 0x1408C2130 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335E98 |
| 0x1408C2D90 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433361F8 |
| 0x1408C2FA0 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433362A0 |
| 0x1408C31B0 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408C33C0 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433368B8 |
| 0x1408C35D0 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_NAVAL_MINES` |
| 0x1408C3E10 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335FB8 |
| 0x1408C4020 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336948 |
| 0x1408C4230 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335C50 |
| 0x1408C4440 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335CE0 |
| 0x1408C4650 | define 读取器; 源锚 `defines_mapmode.h:183`; lua 表 `NMapIcons` · define `IDEOLOGY_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335D78 |
| 0x1408C4C80 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333974 |
| 0x1408C4E90 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_CAPITAL`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333A24 |
| 0x1408C50A0 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408C52B0 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333351C |
| 0x1408C54C0 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333480 |
| 0x1408C5D00 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333369C |
| 0x1408C5F10 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14… |
| 0x1408C6120 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408C6540 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_NAVAL_MINES` |
| 0x1408C6D80 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433333B8 |
| 0x1408C6F90 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433… |
| 0x1408C71A0 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332F84 |
| 0x1408C75C0 | define 读取器; 源锚 `defines_mapmode.h:180`; lua 表 `NMapIcons` · define `INFRASTRUCTURE_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433330F8 |
| 0x1408C8010 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433356B4 |
| 0x1408C8430 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433350B0 |
| 0x1408C9090 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335464 |
| 0x1408C92A0 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433354F4 |
| 0x1408C94B0 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408C96C0 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335AFC |
| 0x1408C98D0 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_NAVAL_MINES` |
| 0x1408CA110 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433351F8 |
| 0x1408CA320 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335BA0 |
| 0x1408CA530 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334E20 |
| 0x1408CA740 | define 读取器; 源锚 `defines_mapmode.h:182`; lua 表 `NMapIcons` · define `MANPOWER_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143334ED8 |
| 0x1408CB190 | define 读取器; 源锚 `defines_mapmode.h:192`; lua 表 `NMapIcons` · define `OPERATION_PRIORITY_IN_PROGRESS`; 存储助手 sub_142070630（int32）; 全局槽 dword_143332298 |
| 0x1408CB5B0 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331D48 |
| 0x1408CB9D0 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331AD8 |
| 0x1408CC420 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433319C0 |
| 0x1408CC630 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408CC840 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433317C4 |
| 0x1408CCA50 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333187C |
| 0x1408CD080 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332028 |
| 0x1408CD290 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_NAVAL_MINES` |
| 0x1408CD4A0 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331A28 |
| 0x1408CD6B0 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331C78 |
| 0x1408CDAD0 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433315B8 |
| 0x1408CE100 | define 读取器; 源锚 `defines_mapmode.h:186`; lua 表 `NMapIcons` · define `OPERATIVES_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331280 |
| 0x1408CE520 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332B90 |
| 0x1408CE730 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332350 |
| 0x1408CE940 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332970 |
| 0x1408CF5A0 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408CF7B0 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433325D4 |
| 0x1408CF9C0 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332694 |
| 0x1408CFBD0 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_… |
| 0x1408CFFF0 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408D0200 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_NAVAL_MINES` |
| 0x1408D0620 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332AD8 |
| 0x1408D0830 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332210 |
| 0x1408D0A40 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433323E8 |
| 0x1408D0C50 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14… |
| 0x1408D1070 | define 读取器; 源锚 `defines_mapmode.h:179`; lua 表 `NMapIcons` · define `PEACE_CONFERENCE_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408D1490 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143330E20 |
| 0x1408D18B0 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143338238 |
| 0x1408D2510 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408D2930 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337F58 |
| 0x1408D2B40 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143338008 |
| 0x1408D2D50 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408D3590 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143338398 |
| 0x1408D39B0 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337C68 |
| 0x1408D3BC0 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331140 |
| 0x1408D3DD0 | define 读取器; 源锚 `defines_mapmode.h:185`; lua 表 `NMapIcons` · define `PLAYERS_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337838 |
| 0x1408D4400 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332A34 |
| 0x1408D4610 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332220 |
| 0x1408D4820 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332810 |
| 0x1408D4A30 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_CAPITAL`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433328B8 |
| 0x1408D4C40 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332184 |
| 0x1408D4E50 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433323F0 |
| 0x1408D5480 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408D5690 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332484 |
| 0x1408D58A0 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332540 |
| 0x1408D5CC0 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408D6710 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433320EC |
| 0x1408D6920 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433322AC |
| 0x1408D6B30 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332D98 |
| 0x1408D6D40 | define 读取器; 源锚 `defines_mapmode.h:171`; lua 表 `NMapIcons` · define `RESISTANCE_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331ED8 |
| 0x1408D7790 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333824 |
| 0x1408D7BB0 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433330FC |
| 0x1408D8810 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333530 |
| 0x1408D8A20 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433335F8 |
| 0x1408D8C30 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408D8E40 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333D04 |
| 0x1408D9050 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_NAVAL_MINES` |
| 0x1408D9890 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333268 |
| 0x1408D9AA0 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143333DB4 |
| 0x1408D9CB0 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332E38 |
| 0x1408D9EC0 | define 读取器; 源锚 `defines_mapmode.h:172`; lua 表 `NMapIcons` · define `RESOURCES_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143332ED8 |
| 0x1408DAB20 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1… |
| 0x1408DAD30 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336EE0 |
| 0x1408DAF40 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408DB150 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433371A0 |
| 0x1408DB570 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336F80 |
| 0x1408DB990 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byt… |
| 0x1408DBBA0 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408DBFC0 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_NAVAL_MINES` |
| 0x1408DC1D0 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408DCA10 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_… |
| 0x1408DCC20 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433369C4 |
| 0x1408DD040 | define 读取器; 源锚 `defines_mapmode.h:184`; lua 表 `NMapIcons` · define `START_CONSTRUCTION_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433… |
| 0x1408DD250 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433363F0 |
| 0x1408DDA90 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335C68 |
| 0x1408DDEB0 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335E24 |
| 0x1408DE2D0 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408DE900 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336064 |
| 0x1408DEB10 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408DED20 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_NAVAL_HEADQUARTER`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336668 |
| 0x1408DEF30 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_NAVAL_MINES` |
| 0x1408DF350 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336360 |
| 0x1408DF980 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336710 |
| 0x1408DFB90 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433359E4 |
| 0x1408DFDA0 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_UNITS_STACK_GROUP`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335A7C |
| 0x1408DFFB0 | define 读取器; 源锚 `defines_mapmode.h:167`; lua 表 `NMapIcons` · define `STATES_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335B10 |
| 0x1408E01C0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143338188 |
| 0x1408E03D0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337908 |
| 0x1408E0C10 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337B20 |
| 0x1408E0E20 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_GUN_EMPLACEMENT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337A78 |
| 0x1408E1030 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337DE8 |
| 0x1408E1240 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408E1870 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143… |
| 0x1408E1A80 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408E1EA0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_NAVAL_MINES` |
| 0x1408E20B0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337EA0 |
| 0x1408E22C0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433380D0 |
| 0x1408E24D0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143337780 |
| 0x1408E28F0 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408E2B00 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_UNITS_STACK`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333759C |
| 0x1408E2F20 | define 读取器; 源锚 `defines_mapmode.h:169`; lua 表 `NMapIcons` · define `STRATEGIC_AIR_PRIORITY_VICTORY_POINTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433376E0 |
| 0x1408E3130 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331A84 |
| 0x1408E3340 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333128C |
| 0x1408E3970 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_CONSTRUCTION_INFO`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408E3B80 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_FACILITY`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331478 |
| 0x1408E3FA0 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_LAND_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331728 |
| 0x1408E43C0 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331524 |
| 0x1408E49F0 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_NAVAL_DOMINANCE` |
| 0x1408E5020 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_NAVAL_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433317D8 |
| 0x1408E5230 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433319D8 |
| 0x1408E5440 | define 读取器; 源锚 `defines_mapmode.h:170`; lua 表 `NMapIcons` · define `STRATEGIC_NAVY_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143331158 |
| 0x1408E60A0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_ADJACENCY_RULE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333… |
| 0x1408E62B0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_AIR_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335E20 |
| 0x1408E64C0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_AIR_MISSION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333635C |
| 0x1408E7120 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_NAVAL_ACCIDENTS` |
| 0x1408E7330 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_NAVAL_BASE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336060 |
| 0x1408E7540 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_NAVAL_COMBAT`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143336100 |
| 0x1408E7750 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_NAVAL_COMBAT_RESULTS`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte… |
| 0x1408E7D80 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_NAVAL_MINES` |
| 0x1408E81A0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_PEACE_COST`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_14333648C |
| 0x1408E83B0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_RESOURCE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335CE8 |
| 0x1408E85C0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_ROCKET_SITE`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_143335EA8 |
| 0x1408E87D0 | define 读取器; 源锚 `defines_mapmode.h:175`; lua 表 `NMapIcons` · define `STRATEGIC_REGIONS_PRIORITY_STRATEGIC_LOCATION`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1… |
| 0x1408E9220 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_AIR_BASE` |
| 0x1408E9430 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_AIR_MISSION` |
| 0x1408E9E80 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_LAND_COMBAT` |
| 0x1408EA2A0 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_NAVAL_BASE` |
| 0x1408EA4B0 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_NAVAL_COMBAT` |
| 0x1408EA6C0 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_NAVAL_COMBAT_RESULTS` |
| 0x1408EAF00 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_NAVAL_MISSION` |
| 0x1408EB110 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_PEACE_COST` |
| 0x1408EB320 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_RESOURCE` |
| 0x1408EB530 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_ROCKET_SITE` |
| 0x1408EB740 | define 读取器; 源锚 `defines_mapmode.h:168`; lua 表 `NMapIcons` · define `SUPPLY_AREAS_PRIORITY_STRATEGIC_LOCATION` |
| 0x1408EC190 | define 读取器; 源锚 `defines_mapmode.h:138`; lua 表 `NMapMode` · define `ACTIVE_RAID_ARROW_COLOR` |
| 0x1408EC5B0 | define 读取器; 源锚 `defines_mapmode.h:98`; lua 表 `NMapMode` · define `AIR_MISSION_ARROW_NONACTIVE_COLOR` |
| 0x1408EC7C0 | define 读取器; 源锚 `defines_mapmode.h:99`; lua 表 `NMapMode` · define `AIR_MISSION_ARROW_SELECTED_COLOR` |
| 0x1408EC9D0 | define 读取器; 源锚 `defines_mapmode.h:93`; lua 表 `NMapMode` · define `AIR_RANGE_CANNOT_ASSIGN_MISSION_STRIPES_COLOR` |
| 0x1408ED000 | define 读取器; 源锚 `defines_mapmode.h:95`; lua 表 `NMapMode` · define `AIR_RANGE_INDICATOR_NO_WINGS_COLOR` |
| 0x1408ED210 | define 读取器; 源锚 `defines_mapmode.h:96`; lua 表 `NMapMode` · define `AIR_RANGE_INDICATOR_ROTATION_SPEED`; 存储助手 sub_142070980（float）; 全局槽 dword_143331CF8 |
| 0x1408ED420 | define 读取器; 源锚 `defines_mapmode.h:108`; lua 表 `NMapMode` · define `AIR_REGION_FADE_WHEN_WING_SELECTED`; 存储助手 sub_142070980（float）; 全局槽 dword_1433324D8 |
| 0x1408ED630 | define 读取器; 源锚 `defines_mapmode.h:100`; lua 表 `NMapMode` · define `AIR_TRANSFER_ARROW_COLOR` |
| 0x1408EDA50 | define 读取器; 源锚 `defines_mapmode.h:61`; lua 表 `NMapMode` · define `CONSTRUCTION_MAP_MODE_BUILDING_DEFAULT_COLOR` |
| 0x1408EE080 | define 读取器; 源锚 `defines_mapmode.h:65`; lua 表 `NMapMode` · define `CONSTRUCTION_MAP_MODE_BUILDING_MAX_AMOUNT_QUEUED_COLOR` |
| 0x1408EE290 | define 读取器; 源锚 `defines_mapmode.h:62`; lua 表 `NMapMode` · define `CONSTRUCTION_MAP_MODE_BUILDING_MAX_LEVEL_COLOR` |
| 0x1408EE4A0 | define 读取器; 源锚 `defines_mapmode.h:66`; lua 表 `NMapMode` · define `CONSTRUCTION_MAP_MODE_BUILDING_QUEUED_COLOR` |
| 0x1408EF100 | define 读取器; 源锚 `defines_mapmode.h:163`; lua 表 `NMapMode` · define `CONSTRUCTION_SECONDARY_FOREIGN_BUILD_TARGET_PROVINCE_COLOR_INDEX`; 存储助手 sub_142070630（int3… |
| 0x1408EF940 | define 读取器; 源锚 `defines_mapmode.h:131`; lua 表 `NMapMode` · define `DEPLOYED_GENERAL_BASE_PLATE_COLOR` |
| 0x1408EFB50 | define 读取器; 源锚 `defines_mapmode.h:130`; lua 表 `NMapMode` · define `DEPLOYED_GENERAL_BASE_PLATE_RADIUS`; 存储助手 sub_142070980（float）; 全局槽 dword_143333598 |
| 0x1408F00F0 | define 读取器; 源锚 `defines_mapmode.h:123`; lua 表 `NMapMode` · define `DEPLOYED_GENERAL_UNIT_LINE_COLOR` |
| 0x1408F0930 | define 读取器; 源锚 `defines_mapmode.h:58`; lua 表 `NMapMode` · define `FABRICATE_CLAIM_NON_TARGET_COUNTRY_SECONDARY_COLOR` |
| 0x1408F0B40 | define 读取器; 源锚 `defines_mapmode.h:56`; lua 表 `NMapMode` · define `FABRICATE_CLAIM_SELECTED_SECONDARY_COLOR` |
| 0x1408F17A0 | define 读取器; 源锚 `defines_mapmode.h:145`; lua 表 `NMapMode` · define `GRADIENT_BORDERS_THICKNESS_SUPPLY_COUNTRY_BORDER`; 存储助手 sub_142070980（float）; 全局槽 dword_14… |
| 0x1408F1DD0 | define 读取器; 源锚 `defines_mapmode.h:71`; lua 表 `NMapMode` · define `MAP_MODE_INFRA_RANGE_COLOR_TO` |
| 0x1408F1FE0 | define 读取器; 源锚 `defines_mapmode.h:117`; lua 表 `NMapMode` · define `MAP_MODE_INTEL_MAX_HORIZONTAL_STACK`; 存储助手 sub_142070630（int32）; 全局槽 dword_143332B50 |
| 0x1408F21F0 | define 读取器; 源锚 `defines_mapmode.h:114`; lua 表 `NMapMode` · define `MAP_MODE_INTEL_NETWORK_STRENGTH_COLOR_HIGH` |
| 0x1408F2A30 | define 读取器; 源锚 `defines_mapmode.h:68`; lua 表 `NMapMode` · define `MAP_MODE_MANPOWER_RANGE_COLOR_FROM` |
| 0x1408F2C40 | define 读取器; 源锚 `defines_mapmode.h:69`; lua 表 `NMapMode` · define `MAP_MODE_MANPOWER_RANGE_COLOR_TO` |
| 0x1408F2E50 | define 读取器; 源锚 `defines_mapmode.h:67`; lua 表 `NMapMode` · define `MAP_MODE_MANPOWER_RANGE_MAX`; 存储助手 sub_142070980（float）; 全局槽 dword_143337FD8 |
| 0x1408F3060 | define 读取器; 源锚 `defines_mapmode.h:112`; lua 表 `NMapMode` · define `MAP_MODE_NAVAL_TERRAIN_TRANSPARENCY`; 存储助手 sub_142070980（float）; 全局槽 dword_1433327B0 |
| 0x1408F3AB0 | define 读取器; 源锚 `defines_mapmode.h:102`; lua 表 `NMapMode` · define `NAVAL_REGION_ACCESS_BLOCK_COLOR` |
| 0x1408F3CC0 | define 读取器; 源锚 `defines_mapmode.h:103`; lua 表 `NMapMode` · define `NAVAL_REGION_FADE_WHEN_FLEET_SELECTED`; 存储助手 sub_142070980（float）; 全局槽 dword_1433321C0 |
| 0x1408F3ED0 | define 读取器; 源锚 `defines_mapmode.h:106`; lua 表 `NMapMode` · define `NAVAL_REGION_TRANSPARENCY_RANGE` |
| 0x1408F40E0 | define 读取器; 源锚 `defines_mapmode.h:104`; lua 表 `NMapMode` · define `NAVAL_REGION_TRANSPARENCY_RATIO_MAX` |
| 0x1408F4860 | define 读取器; 源锚 `defines_mapmode.h:122`; lua 表 `NMapMode` · define `OPERATIVE_MAP_MODE_INVALID_COUNTRY_TARGET_TRANSPARENCY`; 存储助手 sub_142070980（float）; 全局槽 dw… |
| 0x1408F5090 | define 读取器; 源锚 `defines_mapmode.h:76`; lua 表 `NMapMode` · define `PEACE_CONFERENCE_CONTESTED_SECONDARY_COLOR` |
| 0x1408F52A0 | define 读取器; 源锚 `defines_mapmode.h:74`; lua 表 `NMapMode` · define `PEACE_CONFERENCE_CURRENT_SELECTED_SECONDARY_COLOR` |
| 0x1408F54B0 | define 读取器; 源锚 `defines_mapmode.h:78`; lua 表 `NMapMode` · define `PEACE_CONFERENCE_DIFFERENT_STACKABLE_SECONDARY_COLOR` |
| 0x1408F56C0 | define 读取器; 源锚 `defines_mapmode.h:75`; lua 表 `NMapMode` · define `PEACE_CONFERENCE_SELECTABLE_SECONDARY_COLOR` |
| 0x1408F58D0 | define 读取器; 源锚 `defines_mapmode.h:153`; lua 表 `NMapMode` · define `PEACE_HOVERED_STATE_COLOR_INDEX`; 存储助手 sub_142070630（int32）; 全局槽 dword_143334358 |
| 0x1408F5B90 | define 读取器; 源锚 `defines_mapmode.h:81`; lua 表 `NMapMode` · define `PLAYER_MAPMODE_NOT_SELECTED_COUNTRY_TRANSPARENCY`; 存储助手 sub_142070980（float）; 全局槽 dword_143… |
| 0x1408F5FB0 | define 读取器; 源锚 `defines_mapmode.h:89`; lua 表 `NMapMode` · define `RADAR_RANGE_ALLIED_COLOR` |
| 0x1408F6A00 | define 读取器; 源锚 `defines_mapmode.h:118`; lua 表 `NMapMode` · define `RAILWAY_GUN_RANGE_INDICATOR_DEFAULT_COLOR` |
| 0x1408F6E20 | define 读取器; 源锚 `defines_mapmode.h:120`; lua 表 `NMapMode` · define `RAILWAY_GUN_RANGE_STRIPES_COLOR` |
| 0x1408F7030 | define 读取器; 源锚 `defines_mapmode.h:137`; lua 表 `NMapMode` · define `READY_RAID_ARROW_COLOR` |
| 0x1408F7450 | define 读取器; 源锚 `defines_mapmode.h:155`; lua 表 `NMapMode` · define `SELECTION_HOVERED_STATE_COLOR_INDEX_CONTROLLED`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433… |
| 0x1408F7DF0 | define 读取器; 源锚 `defines_mapmode.h:127`; lua 表 `NMapMode` · define `SHOW_DEPLOYED_GENERAL_FRONT_LINES`; 存储助手 sub_142072840（bool/int8）; 全局槽 byte_143330E96 |
| 0x1408F8000 | define 读取器; 源锚 `defines_mapmode.h:126`; lua 表 `NMapMode` · define `SHOW_DEPLOYED_GENERAL_NO_COMMUNICATION_LINES`; 存储助手 sub_142072840（bool/int8）; 全局槽 byte_143… |
| 0x1408F8210 | define 读取器; 源锚 `defines_mapmode.h:86`; lua 表 `NMapMode` · define `STRATEGIC_MODE_ALLY_STRIPES_COLOR` |
| 0x1408F8420 | define 读取器; 源锚 `defines_mapmode.h:83`; lua 表 `NMapMode` · define `STRATEGIC_MODE_COUNTRY_COLOR_STRIPES_TRANSP`; 存储助手 sub_142070980（float）; 全局槽 dword_143331420 |
| 0x1408F8C60 | define 读取器; 源锚 `defines_mapmode.h:143`; lua 表 `NMapMode` · define `SUPPLY_COUNTRY_BORDER_FRIEND_COLOR` |
| 0x1408F8E70 | define 读取器; 源锚 `defines_mapmode.h:142`; lua 表 `NMapMode` · define `SUPPLY_COUNTRY_BORDER_PLAYER_COLOR` |
| 0x1408F9340 | define 读取器; 源锚 `defines_mapmode.h:151`; lua 表 `NMapMode` · define `SUPPLY_HOVERED_STATE_COLOR_INDEX`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433341C0 |
| 0x1408F9600 | define 读取器; 源锚 `defines_mapmode.h:148`; lua 表 `NMapMode` · define `SUPPLY_MAP_MODE_BEST_FLOW_DISPLAY`; 存储助手 sub_142070980（float）; 全局槽 dword_143333FD8 |
| 0x1408F9810 | define 读取器; 源锚 `defines_mapmode.h:140`; lua 表 `NMapMode` · define `SUPPLY_MAP_MODE_COUNTRY_BORDER_CAMERA_DISTANCE`; 存储助手 sub_142070980（float）; 全局槽 dword_1433… |
| 0x1408F9A20 | define 读取器; 源锚 `defines_mapmode.h:141`; lua 表 `NMapMode` · define `SUPPLY_MAP_MODE_COUNTRY_BORDER_OUTLINE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_14333… |
| 0x1408F9C30 | define 读取器; 源锚 `defines_mapmode.h:147`; lua 表 `NMapMode` · define `SUPPLY_MAP_MODE_REACH_COLOR`; 存储助手 sub_142070C60（qword 未细分）; 全局槽 qword_1433394A0 |
| 0x1408FA470 | define 读取器; 源锚 `defines_mapmode.h:110`; lua 表 `NMapMode` · define `UI_CONFIGURABLE_SLOT_TO`; 存储助手 sub_142070630（int32）; 全局槽 dword_143332640 |
| 0x14080EF10 | defines 读取器；`source\defines_diplomacy.h:185`；lua 表 `NDiplomacy` 键 `ASSUME_FACTION_LEADERSHIP_MIN_MANPOWER_RATIO`；sink `sub_142072500`；define 槽 `qword_143331A48` |
| 0x14080F330 | defines 读取器；`source\defines_diplomacy.h:188`；lua 表 `NDiplomacy` 键 `ASSUME_FACTION_SPYMASTER_COOLDOWN_DAYS`；sink `sub_142070630`；define 槽 `dword_143331C58` |
| 0x14080F540 | defines 读取器；`source\defines_diplomacy.h:164`；lua 表 `NDiplomacy` 键 `ATTACHE_TO_OVERLORD_EFFECT`；sink `sub_142072500`；define 槽 `qword_143330E80` |
| 0x14080FB70 | defines 读取器；`source\defines_diplomacy.h:159`；lua 表 `NDiplomacy` 键 `AUTONOMY_LEVEL_CHANGE_PP_ANNEX`；sink `sub_142072500`；define 槽 `qword_143338150` |
| 0x14080FF90 | defines 读取器；`source\defines_diplomacy.h:160`；lua 表 `NDiplomacy` 键 `AUTONOMY_LEVEL_CHANGE_PP_FREE`；sink `sub_142072500`；define 槽 `qword_143338208` |
| 0x1408101A0 | defines 读取器；`source\defines_diplomacy.h:157`；lua 表 `NDiplomacy` 键 `AUTONOMY_LEVEL_CHANGE_SANCTUARY`；sink `sub_142070630`；define 槽 `dword_143337FDC` |
| 0x1408103B0 | defines 读取器；`source\defines_diplomacy.h:75`；lua 表 `NDiplomacy` 键 `BASE_BOOST_PARTY_POPULARITY_DAILY_DRIFT`；sink `sub_142072500`；define 槽 `qword_143334970` |
| 0x1408105C0 | defines 读取器；`source\defines_diplomacy.h:74`；lua 表 `NDiplomacy` 键 `BASE_BOOST_PARTY_POPULARITY_DAILY_PP`；sink `sub_142072500`；define 槽 `qword_1433348D8` |
| 0x1408107D0 | defines 读取器；`source\defines_diplomacy.h:125`；lua 表 `NDiplomacy` 键 `BASE_CONDITIONAL_PEACE_MONTHS`；sink `sub_142070630`；define 槽 `dword_1433368C8` |
| 0x1408109E0 | defines 读取器；`source\defines_diplomacy.h:124`；lua 表 `NDiplomacy` 键 `BASE_CONDITIONAL_PEACE_WARESCORE_RATIO`；sink `sub_142072500`；define 槽 `unk_143336840` |
| 0x140810BF0 | defines 读取器；`source\defines_diplomacy.h:67`；lua 表 `NDiplomacy` 键 `BASE_GENERATE_WARGOAL_DAILY_PP`；sink `sub_142072500`；define 槽 `qword_1433343F0` |
| 0x140811010 | defines 读取器；`source\defines_diplomacy.h:64`；lua 表 `NDiplomacy` 键 `BASE_IMPROVE_RELATION_DIFFERENT_IDEOLOGY_GROUP_MAINTAIN_COST`；sink `sub_142072500`；define 槽… |
| 0x140811220 | defines 读取器；`source\defines_diplomacy.h:63`；lua 表 `NDiplomacy` 键 `BASE_IMPROVE_RELATION_SAME_IDEOLOGY_GROUP_MAINTAIN_COST`；sink `sub_142072500`；define 槽 `qwo… |
| 0x140811430 | defines 读取器；`source\defines_diplomacy.h:16`；lua 表 `NDiplomacy` 键 `BASE_NEGATIVE_OPINION_AFTER_BEING_KICKED`；sink `sub_142070630`；define 槽 `dword_143331AB0` |
| 0x140811640 | defines 读取器；`source\defines_diplomacy.h:23`；lua 表 `NDiplomacy` 键 `BASE_PEACE_FORCE_GOVERNMENT_COST`；sink `sub_142070630`；define 槽 `unk_143331FB4` |
| 0x140811A60 | defines 读取器；`source\defines_diplomacy.h:19`；lua 表 `NDiplomacy` 键 `BASE_PEACE_PUPPET_FACTOR`；sink `sub_142070630`；define 槽 `unk_143331CC0` |
| 0x140811C70 | defines 读取器；`source\defines_diplomacy.h:22`；lua 表 `NDiplomacy` 键 `BASE_PEACE_TAKE_FACTION_CONTROLLED_STATE_FACTOR`；sink `sub_142072500`；define 槽 `unk_143331EF8` |
| 0x140811E80 | defines 读取器；`source\defines_diplomacy.h:21`；lua 表 `NDiplomacy` 键 `BASE_PEACE_TAKE_UNCONTROLLED_STATE_FACTOR`；sink `sub_142072500`；define 槽 `unk_143331E38` |
| 0x1408122A0 | defines 读取器；`source\defines_diplomacy.h:66`；lua 表 `NDiplomacy` 键 `BASE_SEND_ATTACHE_CP_COST`；sink `sub_142072500`；define 槽 `qword_143334350` |
| 0x1408126C0 | defines 读取器；`source\defines_diplomacy.h:77`；lua 表 `NDiplomacy` 键 `BASE_STAGE_COUP_TOTAL_COST`；sink `sub_142072500`；define 槽 `qword_143334AB8` |
| 0x140812CF0 | defines 读取器；`source\defines_diplomacy.h:127`；lua 表 `NDiplomacy` 键 `BREAKING_GUARANTEE_PENALTY`；sink `sub_142072500`；define 槽 `qword_1433369D0` |
| 0x140813110 | defines 读取器；`source\defines_diplomacy.h:178`；lua 表 `NDiplomacy` 键 `CAPITAL_CAPITULATE_BONUS_SCORE_MUL`；sink `sub_142072500`；define 槽 `qword_1433316E0` |
| 0x140813320 | defines 读取器；`source\defines_diplomacy.h:17`；lua 表 `NDiplomacy` 键 `DECAY_RATE_OF_NEGATIVE_OPINION_AFTER_BEING_KICKED`；sink `sub_142070630`；define 槽 `dword_143… |
| 0x140813530 | defines 读取器；`source\defines_diplomacy.h:86`；lua 表 `NDiplomacy` 键 `DIPLOMACY_HOURS_BETWEEN_REQUESTS`；sink `sub_142070630`；define 槽 `dword_1433350C0` |
| 0x140813740 | defines 读取器；`source\defines_diplomacy.h:6`；lua 表 `NDiplomacy` 键 `DIPLOMACY_REQUEST_EXPIRY_DAYS`；sink `sub_142070630`；define 槽 `dword_1433313F4` |
| 0x140813950 | defines 读取器；`source\defines_diplomacy.h:191`；lua 表 `NDiplomacy` 键 `EMBARGO_COST`；sink `sub_142072500`；define 槽 `qword_143331DC8` |
| 0x140813D70 | defines 读取器；`source\defines_diplomacy.h:195`；lua 表 `NDiplomacy` 键 `EMBARGO_DIFFERENT_IDEOLOGY_AT_OFFENSIVE_WAR_AI_WEIGHT`；sink `sub_142070630`；define 槽 `dwor… |
| 0x140814190 | defines 读取器；`source\defines_diplomacy.h:196`；lua 表 `NDiplomacy` 键 `EMBARGO_RECIPIENT_IS_MAJOR_AI_WEIGHT`；sink `sub_142070630`；define 槽 `dword_143332148` |
| 0x1408147C0 | defines 读取器；`source\defines_diplomacy.h:207`；lua 表 `NDiplomacy` 键 `EQUIPMENT_PURCHASE_ACCEPTANCE_COMPETING_FACTIONS`；sink `sub_142070630`；define 槽 `dword_143… |
| 0x1408149D0 | defines 读取器；`source\defines_diplomacy.h:208`；lua 表 `NDiplomacy` 键 `EQUIPMENT_PURCHASE_ACCEPTANCE_EMBARGO`；sink `sub_142070630`；define 槽 `dword_143332838` |
| 0x140814BE0 | defines 读取器；`source\defines_diplomacy.h:209`；lua 表 `NDiplomacy` 键 `EQUIPMENT_PURCHASE_ACCEPTANCE_NON_AGGRESSION_PACT`；sink `sub_142070630`；define 槽 `dword_14… |
| 0x140814DF0 | defines 读取器；`source\defines_diplomacy.h:203`；lua 表 `NDiplomacy` 键 `EQUIPMENT_PURCHASE_ACCEPTANCE_OPINION`；sink `sub_142072500`；define 槽 `qword_1433324A0` |
| 0x140815210 | defines 读取器；`source\defines_diplomacy.h:205`；lua 表 `NDiplomacy` 键 `EQUIPMENT_PURCHASE_ACCEPTANCE_SCRIPTED_IDEOLOGY_ACCEPTANCE`；sink `sub_142072500`；define 槽 … |
| 0x140815420 | defines 读取器；`source\defines_diplomacy.h:206`；lua 表 `NDiplomacy` 键 `EQUIPMENT_PURCHASE_ACCEPTANCE_TRADE_INFLUENCE`；sink `sub_142072500`；define 槽 `qword_143332… |
| 0x140815C40 | defines 读取器；`source\defines_diplomacy.h:226`；lua 表 `NDiplomacy` 键 `FACTION_LEADERSHIP_CHANGE_FACTORY_WEIGHT`；sink `sub_142072500`；define 槽 `qword_143333560` |
| 0x140816740 | defines 读取器；`source\defines_diplomacy.h:221`；lua 表 `NDiplomacy` 键 `FACTION_LEADERSHIP_CHANGE_NOT_SUBJECT_WEIGHT`；sink `sub_142072500`；define 槽 `qword_143333050` |
| 0x140816A00 | defines 读取器；`source\defines_diplomacy.h:231`；lua 表 `NDiplomacy` 键 `FACTION_POWER_AIR_BOMBER_WEIGHT`；sink `sub_142072500`；define 槽 `qword_143333960` |
| 0x140816CC0 | defines 读取器；`source\defines_diplomacy.h:232`；lua 表 `NDiplomacy` 键 `FACTION_POWER_AIR_WEIGHT`；sink `sub_142072500`；define 槽 `qword_143333A88` |
| 0x140817D40 | defines 读取器；`source\defines_diplomacy.h:228`；lua 表 `NDiplomacy` 键 `FACTION_POWER_RESOURCE_WEIGHT`；sink `sub_142072500`；define 槽 `qword_143333660` |
| 0x140818000 | defines 读取器；`source\defines_diplomacy.h:88`；lua 表 `NDiplomacy` 键 `FLEET_FEAR`；sink `sub_142070630`；define 槽 `dword_143335208` |
| 0x140818210 | defines 读取器；`source\defines_diplomacy.h:146`；lua 表 `NDiplomacy` 键 `FRONT_IS_DANGEROUS`；sink `sub_142070630`；define 槽 `dword_143337810` |
| 0x140818420 | defines 读取器；`source\defines_diplomacy.h:122`；lua 表 `NDiplomacy` 键 `GUARANTEE_COST`；sink `sub_142072500`；define 槽 `qword_1433366F8` |
| 0x140818630 | defines 读取器；`source\defines_diplomacy.h:89`；lua 表 `NDiplomacy` 键 `IC_TO_EQUIPMENT_COUP_RATIO`；sink `sub_142072500`；define 槽 `qword_1433352A8` |
| 0x140818840 | defines 读取器；`source\defines_diplomacy.h:170`；lua 表 `NDiplomacy` 键 `IDEOLOGY_JOIN_FACTION_MIN_LEVEL`；sink `sub_142072500`；define 槽 `qword_1433311A8` |
| 0x140818A50 | defines 读取器；`source\defines_diplomacy.h:56`；lua 表 `NDiplomacy` 键 `INFLUENCE_DISTANCE_DIVISOR`；sink `sub_142072500`；define 槽 `qword_143333D40` |
| 0x140818D10 | defines 读取器；`source\defines_diplomacy.h:59`；lua 表 `NDiplomacy` 键 `INFLUENCE_MAJOR_FACTOR`；sink `sub_142072500`；define 槽 `qword_143333F20` |
| 0x140818FD0 | defines 读取器；`source\defines_diplomacy.h:46`；lua 表 `NDiplomacy` 键 `INFLUENCE_MAX_DIST_CAPITAL`；sink `sub_142072500`；define 槽 `qword_143333320` |
| 0x140819810 | defines 读取器；`source\defines_diplomacy.h:52`；lua 表 `NDiplomacy` 键 `INFLUENCE_MAX_DIST_COST_MODIFIER`；sink `sub_142072500`；define 槽 `qword_143333950` |
| 0x140819D90 | defines 读取器；`source\defines_diplomacy.h:51`；lua 表 `NDiplomacy` 键 `INFLUENCE_MIN_DIST_COST_MODIFIER`；sink `sub_142072500`；define 槽 `qword_143333868` |
| 0x14081A5D0 | defines 读取器；`source\defines_diplomacy.h:47`；lua 表 `NDiplomacy` 键 `INFLUENCE_NEUTRAL_DIST_CORE`；sink `sub_142072500`；define 槽 `qword_143333438` |
| 0x14081B5A0 | defines 读取器；`source\defines_diplomacy.h:171`；lua 表 `NDiplomacy` 键 `JOIN_FACTION_LIMIT_CHANGE_AT_WAR`；sink `sub_142072500`；define 槽 `qword_143331248` |
| 0x14081B9C0 | defines 读取器；`source\defines_diplomacy.h:173`；lua 表 `NDiplomacy` 键 `LICENSE_ACCEPTANCE_PUPPET_BASE`；sink `sub_142070630`；define 槽 `dword_143331398` |
| 0x14081BBD0 | defines 读取器；`source\defines_diplomacy.h:176`；lua 表 `NDiplomacy` 键 `LICENSE_ACCEPTANCE_SAME_FACTION`；sink `sub_142070630`；define 槽 `dword_143331590` |
| 0x14081BDE0 | defines 读取器；`source\defines_diplomacy.h:174`；lua 表 `NDiplomacy` 键 `LICENSE_ACCEPTANCE_TECH_DIFFERENCE`；sink `sub_142070630`；define 槽 `dword_143331424` |
| 0x14081BFF0 | defines 读取器；`source\defines_diplomacy.h:175`；lua 表 `NDiplomacy` 键 `LICENSE_ACCEPTANCE_TECH_DIFFERENCE_BASE`；sink `sub_142070630`；define 槽 `dword_1433314E0` |
| 0x14081C200 | defines 读取器；`source\defines_diplomacy.h:153`；lua 表 `NDiplomacy` 键 `LL_TO_OVERLORD_AUTONOMY_DAILY_BASE`；sink `sub_142072500`；define 槽 `qword_143337CF0` |
| 0x14081C410 | defines 读取器；`source\defines_diplomacy.h:154`；lua 表 `NDiplomacy` 键 `LL_TO_OVERLORD_AUTONOMY_DAILY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143337DA0` |
| 0x14081C620 | defines 读取器；`source\defines_diplomacy.h:155`；lua 表 `NDiplomacy` 键 `LL_TO_PUPPET_AUTONOMY_DAILY_BASE`；sink `sub_142072500`；define 槽 `qword_143337E58` |
| 0x14081CA40 | defines 读取器；`source\defines_diplomacy.h:215`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_COMPETING_FACTIONS`；sink `sub_142070630`；define 槽 `dword_143332C78` |
| 0x14081CC50 | defines 读取器；`source\defines_diplomacy.h:216`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_EMBARGO`；sink `sub_142070630`；define 槽 `dword_143332D24` |
| 0x14081CE60 | defines 读取器；`source\defines_diplomacy.h:218`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_NON_AGGRESSION_PACT`；sink `sub_142070630`；define 槽 `dword_143332E78` |
| 0x14081D070 | defines 读取器；`source\defines_diplomacy.h:217`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_NO_TRADE_ROUTE`；sink `sub_142070630`；define 槽 `dword_143332DD8` |
| 0x14081D280 | defines 读取器；`source\defines_diplomacy.h:211`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_OPINION`；sink `sub_142072500`；define 槽 `qword_143332998` |
| 0x14081D490 | defines 读取器；`source\defines_diplomacy.h:212`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_SAME_IDEOLOGY`；sink `sub_142070630`；define 槽 `dword_143332A54` |
| 0x14081D6A0 | defines 读取器；`source\defines_diplomacy.h:213`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_SCRIPTED_IDEOLOGY_ACCEPTANCE`；sink `sub_142072500`；define 槽 `qwor… |
| 0x14081D8B0 | defines 读取器；`source\defines_diplomacy.h:214`；lua 表 `NDiplomacy` 键 `MARKET_ACCESS_ACCEPTANCE_TRADE_INFLUENCE`；sink `sub_142072500`；define 槽 `qword_143332BD0` |
| 0x14081DAC0 | defines 读取器；`source\defines_diplomacy.h:166`；lua 表 `NDiplomacy` 键 `MASTER_BUILD_AUTONOMY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143330F20` |
| 0x14081DCD0 | defines 读取器；`source\defines_diplomacy.h:140`；lua 表 `NDiplomacy` 键 `MAX_OPINION_FOR_LEASED_IC`；sink `sub_142070630`；define 槽 `dword_14333742C` |
| 0x14081DEE0 | defines 读取器；`source\defines_diplomacy.h:143`；lua 表 `NDiplomacy` 键 `MAX_OPINION_FROM_VOLUNTEERS`；sink `sub_142070630`；define 槽 `dword_143337600` |
| 0x14081E300 | defines 读取器；`source\defines_diplomacy.h:139`；lua 表 `NDiplomacy` 键 `MAX_REMEMBERED_LEASED_IC`；sink `sub_142070630`；define 槽 `dword_1433373A8` |
| 0x14081EB40 | defines 读取器；`source\defines_diplomacy.h:9`；lua 表 `NDiplomacy` 键 `MIN_TRUST_VALUE`；sink `sub_142070630`；define 槽 `word_1433315F0` |
| 0x14081ED50 | defines 读取器；`source\defines_diplomacy.h:73`；lua 表 `NDiplomacy` 键 `MIN_WARGOAL_JUSTIFY_COST`；sink `sub_142072500`；define 槽 `qword_143334828` |
| 0x14081F170 | defines 读取器；`source\defines_diplomacy.h:81`；lua 表 `NDiplomacy` 键 `NAP_BREAK_FORCE_BALANCE_1`；sink `sub_142072500`；define 槽 `qword_143334D70` |
| 0x14081F9B0 | defines 读取器；`source\defines_diplomacy.h:80`；lua 表 `NDiplomacy` 键 `NAP_FORCE_BALANCE_RULE_MONTHS`；sink `sub_142070630`；define 槽 `dword_143334CC0` |
| 0x14081FDD0 | defines 读取器；`source\defines_diplomacy.h:200`；lua 表 `NDiplomacy` 键 `NAVAL_BLOCKADE_BASE_COST`；sink `sub_142070630`；define 槽 `dword_143332318` |
| 0x140820350 | defines 读取器；`source\defines_diplomacy.h:199`；lua 表 `NDiplomacy` 键 `NAVAL_BLOCKADE_THREAT_THRESHOLD`；sink `sub_142070630`；define 槽 `dword_143332278` |
| 0x140820770 | defines 读取器；`source\defines_diplomacy.h:147`；lua 表 `NDiplomacy` 键 `NOT_READY_FOR_WAR_VAL_PER_DAY_SINCE_CALL`；sink `sub_142070630`；define 槽 `dword_1433378B8` |
| 0x140820980 | defines 读取器；`source\defines_diplomacy.h:13`；lua 表 `NDiplomacy` 键 `NUM_DAYS_TO_ENABLE_KICKING_NEW_MEMBERS_OF_FACTION`；sink `sub_142070630`；define 槽 `dword_143… |
| 0x140820B90 | defines 读取器；`source\defines_diplomacy.h:14`；lua 表 `NDiplomacy` 键 `NUM_DAYS_TO_ENABLE_REINVITE_KICKED_NATIONS`；sink `sub_142070630`；define 槽 `dword_143331948` |
| 0x140820DA0 | defines 读取器；`source\defines_diplomacy.h:144`；lua 表 `NDiplomacy` 键 `OPINION_FOR_DEMO_FROM_WT_GENERATION`；sink `sub_142072500`；define 槽 `qword_143337698` |
| 0x140820FB0 | defines 读取器；`source\defines_diplomacy.h:142`；lua 表 `NDiplomacy` 键 `OPINION_PER_VOLUNTEER`；sink `sub_142072500`；define 槽 `qword_143337568` |
| 0x1408213D0 | defines 读取器；`source\defines_diplomacy.h:136`；lua 表 `NDiplomacy` 键 `PEACE_CONTEST_REFUND_FACTOR`；sink `sub_142071190`；define 槽 `qword_143338650` |
| 0x1408215E0 | defines 读取器；`source\defines_diplomacy.h:30`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_CAPITAL_SHIP_IC`；sink `sub_142072200`；define 槽 `qword_1433325A0` |
| 0x1408218A0 | defines 读取器；`source\defines_diplomacy.h:42`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_COMPLIANCE_STEPS`；sink `sub_142071190`；define 槽 `qword_143338620` |
| 0x140821AB0 | defines 读取器；`source\defines_diplomacy.h:26`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_CONTESTED_BID`；sink `sub_142072500`；define 槽 `qword_143332238` |
| 0x140821D70 | defines 读取器；`source\defines_diplomacy.h:24`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_CONTESTED_MAX`；sink `sub_142072500`；define 槽 `qword_143332058` |
| 0x140822030 | defines 读取器；`source\defines_diplomacy.h:31`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_SCREENING_SHIP_IC`；sink `sub_142072200`；define 槽 `qword_1433326A8` |
| 0x1408222F0 | defines 读取器；`source\defines_diplomacy.h:32`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_STACK_DEMILITARIZED_ZONE`；sink `sub_142072500`；define 槽 `qword_1433327A8` |
| 0x140822B30 | defines 读取器；`source\defines_diplomacy.h:33`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_STACK_WAR_REPARATION`；sink `sub_142072500`；define 槽 `qword_1433328A8` |
| 0x140823630 | defines 读取器；`source\defines_diplomacy.h:25`；lua 表 `NDiplomacy` 键 `PEACE_COST_FACTOR_UNCONTESTED_MAX`；sink `sub_142072500`；define 槽 `qword_143332150` |
| 0x140823BB0 | defines 读取器；`source\defines_diplomacy.h:138`；lua 表 `NDiplomacy` 键 `PEACE_PLAY_NEW_TURN_SOUND_ONLY_IF_NOT_ALREADY_PLAYING`；sink `sub_142072840`；define 槽 `byte… |
| 0x140823DC0 | defines 读取器；`source\defines_diplomacy.h:137`；lua 表 `NDiplomacy` 键 `PEACE_PLAY_SOUND_ON_NEW_TURN`；sink `sub_142072840`；define 槽 `byte_143330F46` |
| 0x140823FD0 | defines 读取器；`source\defines_diplomacy.h:135`；lua 表 `NDiplomacy` 键 `PEACE_SCORE_DISTRIBUTION`；sink `sub_142071190`；define 槽 `qword_143338638` |
| 0x1408241E0 | defines 读取器；`source\defines_diplomacy.h:134`；lua 表 `NDiplomacy` 键 `PEACE_SCORE_MINOR_BOOST_FRACTION`；sink `sub_142072500`；define 槽 `qword_143337058` |
| 0x140824740 | defines 读取器；`source\defines_diplomacy.h:129`；lua 表 `NDiplomacy` 键 `PEACE_SCORE_RESET_LOW_SCORE_THRESHOLD`；sink `sub_142072500`；define 槽 `qword_143336B68` |
| 0x140824A90 | defines 读取器；`source\defines_diplomacy.h:133`；lua 表 `NDiplomacy` 键 `PEACE_SCORE_SCALE_FACTOR`；sink `sub_142072500`；define 槽 `unk_143336FC0` |
| 0x140824CA0 | defines 读取器；`source\defines_diplomacy.h:132`；lua 表 `NDiplomacy` 键 `PEACE_SCORE_TOP_FACTION_INFLUENCE_AMOUNT`；sink `sub_142070630`；define 槽 `dword_143336F10` |
| 0x140824EB0 | defines 读取器；`source\defines_diplomacy.h:131`；lua 表 `NDiplomacy` 键 `PEACE_SCORE_TRANSFERRED_FROM_FACTION_INFLUENCE`；sink `sub_142072500`；define 槽 `qword_14333… |
| 0x140825550 | defines 读取器；`source\defines_diplomacy.h:36`；lua 表 `NDiplomacy` 键 `PEACE_TIMED_EFFECT_LENGTH_DEMILITARIZED_ZONE`；sink `sub_142070630`；define 槽 `dword_143332BB8` |
| 0x140825810 | defines 读取器；`source\defines_diplomacy.h:38`；lua 表 `NDiplomacy` 键 `PEACE_TIMED_EFFECT_LENGTH_RESOURCE_RIGHTS`；sink `sub_142070630`；define 槽 `dword_143332D80` |
| 0x1408263A0 | defines 读取器；`source\defines_diplomacy.h:169`；lua 表 `NDiplomacy` 键 `PROVINCE_WORTH_FROM_STATE_VALUE_FACTOR_WARSCORE`；sink `sub_142072500`；define 槽 `qword_1433… |
| 0x1408265B0 | defines 读取器；`source\defines_diplomacy.h:149`；lua 表 `NDiplomacy` 键 `RESOURCE_SENT_AUTONOMY_DAILY_BASE`；sink `sub_142072500`；define 槽 `qword_143337A40` |
| 0x140827420 | defines 读取器；`source\defines_diplomacy.h:121`；lua 表 `NDiplomacy` 键 `TENSION_CAPITULATE`；sink `sub_142072500`；define 槽 `qword_143336650` |
| 0x140827630 | defines 读取器；`source\defines_diplomacy.h:99`；lua 表 `NDiplomacy` 键 `TENSION_CB_WAR`；sink `sub_142072500`；define 槽 `qword_143335898` |
| 0x140827840 | defines 读取器；`source\defines_diplomacy.h:96`；lua 表 `NDiplomacy` 键 `TENSION_CIVIL_WAR_IMPACT`；sink `sub_142072500`；define 槽 `qword_1433356C0` |
| 0x1408283D0 | defines 读取器；`source\defines_diplomacy.h:108`；lua 表 `NDiplomacy` 键 `TENSION_FORCE_GOVERNMENT`；sink `sub_142072500`；define 槽 `qword_143335E28` |
| 0x1408287F0 | defines 读取器；`source\defines_diplomacy.h:120`；lua 表 `NDiplomacy` 键 `TENSION_JOIN_ATTACKER`；sink `sub_142072500`；define 槽 `qword_1433365C8` |
| 0x140829450 | defines 读取器；`source\defines_diplomacy.h:118`；lua 表 `NDiplomacy` 键 `TENSION_RESOURCE_RIGHTS`；sink `sub_142072500`；define 槽 `qword_143336480` |
| 0x140829870 | defines 读取器；`source\defines_diplomacy.h:95`；lua 表 `NDiplomacy` 键 `TENSION_STATE_VALUE`；sink `sub_142072500`；define 槽 `qword_143335628` |
| 0x140829A80 | defines 读取器；`source\defines_diplomacy.h:115`；lua 表 `NDiplomacy` 键 `TENSION_TAKE_ONE_CAPITAL_SHIP`；sink `sub_142072500`；define 槽 `qword_1433362B0` |
| 0x140829C90 | defines 读取器；`source\defines_diplomacy.h:103`；lua 表 `NDiplomacy` 键 `TENSION_TIME_SCALE_MIN`；sink `sub_142072500`；define 槽 `qword_143335B20` |
| 0x140829EA0 | defines 读取器；`source\defines_diplomacy.h:102`；lua 表 `NDiplomacy` 键 `TENSION_TIME_SCALE_MONTHLY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143335A88` |
| 0x14082A2C0 | defines 读取器；`source\defines_diplomacy.h:98`；lua 表 `NDiplomacy` 键 `TENSION_VOLUNTEER_FORCE_DIVISION`；sink `sub_142072500`；define 槽 `qword_1433357F8` |
| 0x14082A4D0 | defines 读取器；`source\defines_diplomacy.h:117`；lua 表 `NDiplomacy` 键 `TENSION_WAR_REPARATION`；sink `sub_142072500`；define 槽 `qword_1433363E0` |
| 0x14082A6E0 | defines 读取器；`source\defines_diplomacy.h:87`；lua 表 `NDiplomacy` 键 `TROOP_FEAR`；sink `sub_142070630`；define 槽 `dword_143335168` |
| 0x14082A8F0 | defines 读取器；`source\defines_diplomacy.h:18`；lua 表 `NDiplomacy` 键 `TRUCE_BREAK_COST_PP`；sink `sub_142070630`；define 槽 `dword_143331C10` |
| 0x14082AB00 | defines 读取器；`source\defines_diplomacy.h:15`；lua 表 `NDiplomacy` 键 `TRUCE_PERIOD_AFTER_KICKING_FROM_FACTION`；sink `sub_142070630`；define 槽 `dword_1433319EC` |
| 0x14082B340 | defines 读取器；`source\defines_diplomacy.h:168`；lua 表 `NDiplomacy` 键 `VICTORY_POINT_WORTH_FACTOR_WARSCORE`；sink `sub_142072500`；define 槽 `qword_143331060` |
| 0x14082B550 | defines 读取器；`source\defines_diplomacy.h:94`；lua 表 `NDiplomacy` 键 `VOLUNTEERS_DIVISIONS_REQUIRED`；sink `sub_142072500`；define 槽 `qword_143335598` |
| 0x14082B970 | defines 读取器；`source\defines_diplomacy.h:90`；lua 表 `NDiplomacy` 键 `VOLUNTEERS_PER_TARGET_PROVINCE`；sink `sub_142072500`；define 槽 `qword_143335340` |
| 0x14082BD90 | defines 读取器；`source\defines_diplomacy.h:93`；lua 表 `NDiplomacy` 键 `VOLUNTEERS_TRANSFER_SPEED`；sink `sub_142070630`；define 槽 `dword_143335500` |
| 0x14082BFA0 | defines 读取器；`source\defines_diplomacy.h:181`；lua 表 `NDiplomacy` 键 `WARGOAL_COST_DOCKING_RIGHTS`；sink `sub_142072500`；define 槽 `qword_143331850` |
| 0x14082C5D0 | defines 读取器；`source\defines_diplomacy.h:72`；lua 表 `NDiplomacy` 键 `WARGOAL_JUSTIFY_TENSION_FROM_PRODUCTION`；sink `sub_142072500`；define 槽 `qword_143334790` |
| 0x14082C7E0 | defines 读取器；`source\defines_diplomacy.h:70`；lua 表 `NDiplomacy` 键 `WARGOAL_PER_JUSTIFY_AND_WAR_COST_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433345C8` |
| 0x14082C9F0 | defines 读取器；`source\defines_diplomacy.h:71`；lua 表 `NDiplomacy` 键 `WARGOAL_THREAT_MAX_TIME_RATIO`；sink `sub_142072500`；define 槽 `qword_143334670` |
| 0x14082CD40 | defines 读取器；`source\defines_diplomacy.h:68`；lua 表 `NDiplomacy` 键 `WARGOAL_VERSUS_MAJOR_AT_WAR_REDUCTION`；sink `sub_142072500`；define 槽 `qword_143334498` |
| 0x14082CF50 | defines 读取器；`source\defines_diplomacy.h:69`；lua 表 `NDiplomacy` 键 `WARGOAL_WORLD_TENSION_REDUCTION`；sink `sub_142072500`；define 槽 `qword_143334528` |
| 0x14082D160 | defines 读取器；`source\defines_diplomacy.h:151`；lua 表 `NDiplomacy` 键 `WAR_SCORE_AUTONOMY_BASE`；sink `sub_142072500`；define 槽 `qword_143337BA0` |
| 0x14082D370 | defines 读取器；`source\defines_diplomacy.h:152`；lua 表 `NDiplomacy` 键 `WAR_SCORE_AUTONOMY_FACTOR`；sink `sub_142072500`；define 槽 `qword_143337C48` |
| 0x14082D580 | defines 读取器；`source\doctrines\defines_doctrines.h:4`；lua 表 `NDoctrines` 键 `BASE_MASTERY_GAIN_TARGET_MANPOWER`；sink `sub_142072500`；define 槽 `qword_143333F48` |
| 0x14082E080 | defines 读取器；`source\doctrines\defines_doctrines.h:8`；lua 表 `NDoctrines` 键 `MASTERY_BAR_ANIMATION_SPEED_PER_DAILY_MASTERY`；sink `sub_142072500`；define 槽 `qwor… |
| 0x14082E340 | defines 读取器；`source\doctrines\defines_doctrines.h:9`；lua 表 `NDoctrines` 键 `MASTERY_BAR_MAX_ANIMATION_SPEED`；sink `sub_142072500`；define 槽 `qword_143334398` |
| 0x14082E600 | defines 读取器；`source\doctrines\defines_doctrines.h:6`；lua 表 `NDoctrines` 键 `MAX_MONTHLY_MASTERY_GAIN`；sink `sub_142072500`；define 槽 `qword_143334110` |
| 0x14082EE40 | defines 读取器；`source\doctrines\defines_doctrines.h:14`；lua 表 `NDoctrines` 键 `NAVAL_MISSION_MASTERY_GAIN_FACTORS`；sink `sub_142071190`；define 槽 `qword_143338668` |
| 0x1408FA680 | define 读取器; 源锚 `defines_game.h:272`; lua 表 `NMarket` · define `CONTRACT_ESTIMATE_AVERAGE_CONVOY_COUNT_ALPHA`; 存储助手 sub_142072200（qword 未细分）; 全局槽 qword_143332240 |
| 0x1408FA950 | define 读取器; 源锚 `defines_game.h:274`; lua 表 `NMarket` · define `CONTRACT_ESTIMATE_AVERAGE_CONVOY_COUNT_SNAP_LIMIT`; 存储助手 sub_142072500（int64）; 全局槽 qword_14333… |
| 0x1408FB840 | define 读取器; 源锚 `defines_game.h:268`; lua 表 `NMarket` · define `CONVOY_WEIGHT_OVERRIDE`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331F58 |
| 0x1408FC080 | define 读取器; 源锚 `defines_game.h:265`; lua 表 `NMarket` · define `LOW_PRICE_LEVEL_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331BA8 |
| 0x1408FC690 | define 读取器; 源锚 `defines_game.h:267`; lua 表 `NMarket` · define `MIN_DELIVERY_LIMIT_WARNING_UI`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331E00 |
| 0x1408FCF60 | define 读取器; 源锚 `defines_game.h:269`; lua 表 `NMarket` · define `REQUEST_AUTOMATION_AUTO_ACCEPT_MARKET_ACCESS_DEFAULT`; 存储助手 sub_142072840（bool/int8）; 全局槽 byte… |
| 0x1408FD380 | define 读取器; 源锚 `defines_game.h:270`; lua 表 `NMarket` · define `REQUEST_AUTOMATION_AUTO_SEND_MARKET_ACCESS_DEFAULT`; 存储助手 sub_142072840（bool/int8）; 全局槽 byte_1… |
| 0x1408FD590 | define 读取器; 源锚 `defines_game.h:279`; lua 表 `NMarket` · define `WARNING_CONVOYS_SUNK_MAX_DAYS`; 存储助手 sub_142070630（int32）; 全局槽 dword_143332890 |
| 0x1407EE380 | defines 读取器；`source\defines_game.h:309`；lua 表 `NBuildings` 键 `ANTI_AIR_SUPERIORITY_MULT`；sink `sub_142072500`；define 槽 `qword_143333C68` |
| 0x1407EEBC0 | defines 读取器；`source\defines_game.h:328`；lua 表 `NBuildings` 键 `INFRASTRUCTURE_MUD_EFFECT`；sink `sub_142072500`；define 槽 `qword_143334848` |
| 0x1407EEFE0 | defines 读取器；`source\defines_game.h:311`；lua 表 `NBuildings` 键 `MAX_BUILDING_LEVELS`；sink `sub_142070630`；define 槽 `dword_143333DC8` |
| 0x1407EF1F0 | defines 读取器；`source\defines_game.h:323`；lua 表 `NBuildings` 键 `MAX_SHARED_SLOTS`；sink `sub_142070630`；define 槽 `dword_143334520` |
| 0x1407EF400 | defines 读取器；`source\defines_game.h:314`；lua 表 `NBuildings` 键 `NAVALBASE_REPAIR_MULT`；sink `sub_142072500`；define 槽 `qword_143333F90` |
| 0x1407EF610 | defines 读取器；`source\defines_game.h:324`；lua 表 `NBuildings` 键 `OWNER_CHANGE_EXTRA_SHARED_SLOTS_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433345B8` |
| 0x1407EF820 | defines 读取器；`source\defines_game.h:318`；lua 表 `NBuildings` 键 `RADAR_INTEL_EFFECT`；sink `sub_142070630`；define 槽 `dword_14333421C` |
| 0x1407EFA30 | defines 读取器；`source\defines_game.h:315`；lua 表 `NBuildings` 键 `RADAR_RANGE_BASE`；sink `sub_142072500`；define 槽 `qword_143334040` |
| 0x1407EFE50 | defines 读取器；`source\defines_game.h:316`；lua 表 `NBuildings` 键 `RADAR_RANGE_MIN`；sink `sub_142072500`；define 槽 `qword_1433340C8` |
| 0x1407F0060 | defines 读取器；`source\defines_game.h:313`；lua 表 `NBuildings` 键 `ROCKETSITE_CAPACITY_MULT`；sink `sub_142070630`；define 槽 `dword_143333EF4` |
| 0x1407F0480 | defines 读取器；`source\defines_game.h:310`；lua 表 `NBuildings` 键 `SAM_MISSION_SUPERIORITY`；sink `sub_142072500`；define 槽 `qword_143333D10` |
| 0x14087FFC0 | define 读取器; 源锚 `defines_intel.h:193`; lua 表 `NIntel` · define `AIR_AIRWING_COUNT_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143333C30 |
| 0x1408803E0 | define 读取器; 源锚 `defines_intel.h:194`; lua 表 `NIntel` · define `AIR_AIRWING_COUNT_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143333CE8 |
| 0x140881250 | define 读取器; 源锚 `defines_intel.h:218`; lua 表 `NIntel` · define `AIR_DEPLOYED_MANPOWER_COUNT_RANGE_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽… |
| 0x140881670 | define 读取器; 源锚 `defines_intel.h:211`; lua 表 `NIntel` · define `AIR_MAPICON_AIR_PORT_VISIBILITY_DETAIL_THRESHOLDS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1… |
| 0x140881880 | define 读取器; 源锚 `defines_intel.h:207`; lua 表 `NIntel` · define `AIR_MAPICON_MISSION_COUNT_INTEL_MAX`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1433391D8 |
| 0x140881A90 | define 读取器; 源锚 `defines_intel.h:206`; lua 表 `NIntel` · define `AIR_MAPICON_MISSION_COUNT_INTEL_MIN`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1433391C0 |
| 0x1408820C0 | define 读取器; 源锚 `defines_intel.h:196`; lua 表 `NIntel` · define `AIR_MIN_INTEL_TO_SHOW_AIRWING_CLASSES`; 存储助手 sub_142072500（int64）; 全局槽 qword_143333D98 |
| 0x1408822D0 | define 读取器; 源锚 `defines_intel.h:214`; lua 表 `NIntel` · define `AIR_MIN_INTEL_TO_SHOW_EQUIPMENT_DESIGN_DETAILS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334608 |
| 0x140882900 | define 读取器; 源锚 `defines_intel.h:190`; lua 表 `NIntel` · define `AIR_WING_TYPE_COUNT_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143333AE0 |
| 0x140883980 | define 读取器; 源锚 `defines_intel.h:228`; lua 表 `NIntel` · define `ARMY_AVG_PIERCING_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334C50 |
| 0x140883B90 | define 读取器; 源锚 `defines_intel.h:230`; lua 表 `NIntel` · define `ARMY_AVG_PIERCING_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334DD8 |
| 0x140883DA0 | define 读取器; 源锚 `defines_intel.h:138`; lua 表 `NIntel` · define `ARMY_DEPLOYED_MANPOWER_COUNT_RANGE_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332170 |
| 0x1408841C0 | define 读取器; 源锚 `defines_intel.h:139`; lua 表 `NIntel` · define `ARMY_DEPLOYED_MANPOWER_COUNT_RANGE_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局… |
| 0x1408843D0 | define 读取器; 源锚 `defines_intel.h:237`; lua 表 `NIntel` · define `ARMY_INTEL_COMBAT_BONUS_FACTOR_ATTACK`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335110 |
| 0x140884A00 | define 读取器; 源锚 `defines_intel.h:240`; lua 表 `NIntel` · define `ARMY_INTEL_COMBAT_BONUS_MAX_INTEL_FOR_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335308 |
| 0x140884C10 | define 读取器; 源锚 `defines_intel.h:239`; lua 表 `NIntel` · define `ARMY_INTEL_COMBAT_BONUS_MIN_INTEL_FOR_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335260 |
| 0x140884E20 | define 读取器; 源锚 `defines_intel.h:225`; lua 表 `NIntel` · define `ARMY_MAX_ARMOR_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334B10 |
| 0x140885240 | define 读取器; 源锚 `defines_intel.h:226`; lua 表 `NIntel` · define `ARMY_MAX_ARMOR_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334BB0 |
| 0x140885870 | define 读取器; 源锚 `defines_intel.h:234`; lua 表 `NIntel` · define `ARMY_MAX_PIERCING_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334FC8 |
| 0x140885A80 | define 读取器; 源锚 `defines_intel.h:92`; lua 表 `NIntel` · define `ARMY_MIN_INTEL_FOR_SUPPLY_ROUTES`; 存储助手 sub_142072500（int64）; 全局槽 qword_143338178 |
| 0x140885C90 | define 读取器; 源锚 `defines_intel.h:96`; lua 表 `NIntel` · define `ARMY_MIN_INTEL_FOR_SUPPLY_ROUTES_TOOLTIPS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143338390 |
| 0x1408860B0 | define 读取器; 源锚 `defines_intel.h:156`; lua 表 `NIntel` · define `ARMY_MIN_INTEL_RATIO_NEEDED_FOR_REVEALING_FAKE_ENEMY_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qw… |
| 0x1408864D0 | define 读取器; 源锚 `defines_intel.h:153`; lua 表 `NIntel` · define `ARMY_MIN_INTEL_TO_SHOW_EQUIPMENT_DESIGN_DETAILS`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433328A0 |
| 0x1408868F0 | define 读取器; 源锚 `defines_intel.h:147`; lua 表 `NIntel` · define `ARMY_MIN_INTEL_TO_SHOW_EXACT_TEMPLATE_INFO`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433325B0 |
| 0x140886B00 | define 读取器; 源锚 `defines_intel.h:135`; lua 表 `NIntel` · define `ARMY_SPECIAL_FORCES_COUNT_RANGE_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 q… |
| 0x140887340 | define 读取器; 源锚 `defines_intel.h:145`; lua 表 `NIntel` · define `ARMY_TEMPLATE_UNIT_COUNT_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332468 |
| 0x140887550 | define 读取器; 源锚 `defines_intel.h:144`; lua 表 `NIntel` · define `ARMY_TEMPLATE_UNIT_COUNT_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433323D0 |
| 0x140887B80 | define 读取器; 源锚 `defines_intel.h:57`; lua 表 `NIntel` · define `CAPTURED_OPERATIVE_MAX_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336EB0 |
| 0x140887E40 | define 读取器; 源锚 `defines_intel.h:58`; lua 表 `NIntel` · define `CAPTURED_OPERATIVE_MIN_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336F90 |
| 0x140888100 | define 读取器; 源锚 `defines_intel.h:105`; lua 表 `NIntel` · define `CIVILIAN_CONVOYS_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331138 |
| 0x140888310 | define 读取器; 源锚 `defines_intel.h:104`; lua 表 `NIntel` · define `CIVILIAN_CONVOYS_RANGE_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331088 |
| 0x140888940 | define 读取器; 源锚 `defines_intel.h:100`; lua 表 `NIntel` · define `CIVILIAN_FUEL_RANGE_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_143330EA8 |
| 0x140888B50 | define 读取器; 源锚 `defines_intel.h:98`; lua 表 `NIntel` · define `CIVILIAN_INTEL_NEEDED_TO_SHOW_ANTI_AIR_REDUCTION`; 存储助手 sub_142072500（int64）; 全局槽 qword_143330E18 |
| 0x140888F70 | define 读取器; 源锚 `defines_intel.h:86`; lua 表 `NIntel` · define `CIVILIAN_INTEL_NEEDED_TO_SHOW_CURRENT_FOCUS_PROGRESS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143… |
| 0x1408899C0 | define 读取器; 源锚 `defines_intel.h:198`; lua 表 `NIntel` · define `CIVILIAN_MAPICON_INDUSTRY_COUNT_INTEL_RANGE_AT_LOWEST_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 q… |
| 0x140889BD0 | define 读取器; 源锚 `defines_intel.h:93`; lua 表 `NIntel` · define `CIVILIAN_MIN_INTEL_FOR_RESOURCE_ORIGIN_ROUTES`; 存储助手 sub_142072500（int64）; 全局槽 qword_143338230 |
| 0x140889FF0 | define 读取器; 源锚 `defines_intel.h:91`; lua 表 `NIntel` · define `CIVILIAN_MIN_INTEL_FOR_TRADE_ROUTES`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433380B8 |
| 0x14088A410 | define 读取器; 源锚 `defines_intel.h:124`; lua 表 `NIntel` · define `CIVILIAN_MIN_INTEL_TO_SHOW_CONVOYS_GRAPH`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331A68 |
| 0x14088A830 | define 读取器; 源锚 `defines_intel.h:128`; lua 表 `NIntel` · define `CIVILIAN_MIN_INTEL_TO_SHOW_RAIL_STAUS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331D40 |
| 0x14088AC50 | define 读取器; 源锚 `defines_intel.h:126`; lua 表 `NIntel` · define `CIVILIAN_MIN_INTEL_TO_SHOW_TRUCKS_GRAPH`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331BC8 |
| 0x14088B070 | define 读取器; 源锚 `defines_intel.h:71`; lua 表 `NIntel` · define `CIVILIAN_PRODUCTION_RANGE_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143337590 |
| 0x14088B280 | define 读取器; 源锚 `defines_intel.h:70`; lua 表 `NIntel` · define `CIVILIAN_PRODUCTION_RANGE_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433374E8 |
| 0x14088BAC0 | define 读取器; 源锚 `defines_intel.h:89`; lua 表 `NIntel` · define `CIVILIAN_TRADE_SHOW_TRADE_AMOUNTS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143337F50 |
| 0x14088C300 | define 读取器; 源锚 `defines_intel.h:111`; lua 表 `NIntel` · define `CIVILIAN_TRAINS_RANGE_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433313D0 |
| 0x14088CB40 | define 读取器; 源锚 `defines_intel.h:61`; lua 表 `NIntel` · define `COUNTRY_LEVEL_INTEL_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1433390B8 |
| 0x14088CD50 | define 读取器; 源锚 `defines_intel.h:271`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_AIR_COMBAT_ABSOLUTE_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1… |
| 0x14088D7A0 | define 读取器; 源锚 `defines_intel.h:271`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_AIR_COMBAT_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339328 |
| 0x14088DC70 | define 读取器; 源锚 `defines_intel.h:272`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_AIR_RECON_ABSOLUTE_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_14… |
| 0x14088E400 | define 读取器; 源锚 `defines_intel.h:272`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_AIR_RECON_FLAT_DECAY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336F68 |
| 0x14088E8D0 | define 读取器; 源锚 `defines_intel.h:272`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_AIR_RECON_MULT_DECAY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143337040 |
| 0x140890240 | define 读取器; 源锚 `defines_intel.h:268`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_EVENT_FLAT_DECAY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335C60 |
| 0x140890500 | define 读取器; 源锚 `defines_intel.h:268`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_EVENT_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339298 |
| 0x140890710 | define 读取器; 源锚 `defines_intel.h:268`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_EVENT_MULT_DECAY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335D18 |
| 0x1408909D0 | define 读取器; 源锚 `defines_intel.h:269`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_LAND_COMBAT_ABSOLUTE_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_… |
| 0x140891420 | define 读取器; 源锚 `defines_intel.h:269`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_LAND_COMBAT_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1433392C8 |
| 0x1408918F0 | define 读取器; 源锚 `defines_intel.h:270`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_NAVAL_COMBAT_ABSOLUTE_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword… |
| 0x140892080 | define 读取器; 源锚 `defines_intel.h:270`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_NAVAL_COMBAT_FLAT_DECAY`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336598 |
| 0x140892550 | define 读取器; 源锚 `defines_intel.h:270`; lua 表 `NIntel` · define `DYNAMIC_INTEL_SOURCE_NAVAL_COMBAT_MULT_DECAY`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433366A8 |
| 0x140892A20 | define 读取器; 源锚 `defines_intel.h:48`; lua 表 `NIntel` · define `INTEL_NETWORK_MAX_AIRFORCE_INTEL`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336978 |
| 0x1408940D0 | define 读取器; 源锚 `defines_intel.h:81`; lua 表 `NIntel` · define `INTEL_TO_SHOW_MASTERY`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339178 |
| 0x1408942E0 | define 读取器; 源锚 `defines_intel.h:76`; lua 表 `NIntel` · define `INTEL_TO_SHOW_PREVIOUSLY_RESEARCHED`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339118 |
| 0x140894910 | define 读取器; 源锚 `defines_intel.h:14`; lua 表 `NIntel` · define `LAND_COMBAT_AIR_INTEL_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433351C0 |
| 0x140894BD0 | define 读取器; 源锚 `defines_intel.h:12`; lua 表 `NIntel` · define `LAND_COMBAT_AIR_INTEL_OVER_OPPONENT_PER_INSTANCE`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334FF8 |
| 0x140896330 | define 读取器; 源锚 `defines_intel.h:31`; lua 表 `NIntel` · define `NAVAL_COMBAT_AIR_INTEL_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335F90 |
| 0x1408965F0 | define 读取器; 源锚 `defines_intel.h:30`; lua 表 `NIntel` · define `NAVAL_COMBAT_AIR_INTEL_OVER_OPPONENT_PER_EXTERNAL_PLANES`; 存储助手 sub_142072500（int64）; 全局槽 qword… |
| 0x140897930 | define 读取器; 源锚 `defines_intel.h:22`; lua 表 `NIntel` · define `NAVAL_COMBAT_CIVILIAN_INTEL_OVER_OPPONENT_PER_INSTANCE`; 存储助手 sub_142072500（int64）; 全局槽 qword_1… |
| 0x140897EB0 | define 读取器; 源锚 `defines_intel.h:21`; lua 表 `NIntel` · define `NAVAL_COMBAT_NAVY_INTEL_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335700 |
| 0x140899140 | define 读取器; 源锚 `defines_intel.h:164`; lua 表 `NIntel` · define `NAVAL_DOMINANCE_INTEL_LOW_DOMINANCE_MIN_PENALTY` |
| 0x140899350 | define 读取器; 源锚 `defines_intel.h:163`; lua 表 `NIntel` · define `NAVAL_DOMINANCE_INTEL_LOW_DOMINANCE_PENALTY_START` |
| 0x140899770 | define 读取器; 源锚 `defines_intel.h:185`; lua 表 `NIntel` · define `NAVY_DEPLOYED_MANPOWER_COUNT_RANGE_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433337F0 |
| 0x140899980 | define 读取器; 源锚 `defines_intel.h:184`; lua 表 `NIntel` · define `NAVY_DEPLOYED_MANPOWER_COUNT_RANGE_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_143333728 |
| 0x140899DA0 | define 读取器; 源锚 `defines_intel.h:167`; lua 表 `NIntel` · define `NAVY_FLEET_COUNT_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332F70 |
| 0x14089A3D0 | define 读取器; 源锚 `defines_intel.h:34`; lua 表 `NIntel` · define `NAVY_INTEL_BASE_SPOTTING_BONUS_MAX_INTEL_FOR_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 qword_14333… |
| 0x14089A7F0 | define 读取器; 源锚 `defines_intel.h:37`; lua 表 `NIntel` · define `NAVY_INTEL_MINE_DAMAGE_REDUCTION_FACTOR_MAX_INTEL_FOR_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 qw… |
| 0x14089AA00 | define 读取器; 源锚 `defines_intel.h:36`; lua 表 `NIntel` · define `NAVY_INTEL_MINE_DAMAGE_REDUCTION_FACTOR_MIN_INTEL_FOR_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 qw… |
| 0x14089B240 | define 读取器; 源锚 `defines_intel.h:203`; lua 表 `NIntel` · define `NAVY_MAPICON_NAVAL_PORT_VISIBILITY_DETAIL_THRESHOLDS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qwor… |
| 0x14089B870 | define 读取器; 源锚 `defines_intel.h:178`; lua 表 `NIntel` · define `NAVY_MIN_INTEL_TO_SHOW_SHIP_CLASSES`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433334F8 |
| 0x14089BEA0 | define 读取器; 源锚 `defines_intel.h:174`; lua 表 `NIntel` · define `NAVY_SHIP_COUNT_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433332D0 |
| 0x14089C2C0 | define 读取器; 源锚 `defines_intel.h:159`; lua 表 `NIntel` · define `NAVY_SHIP_TYPE_COUNT_INTEL_MAX`; 存储助手 sub_142072500（int64）; 全局槽 qword_143332B70 |
| 0x14089CB00 | define 读取器; 源锚 `defines_intel.h:170`; lua 表 `NIntel` · define `NAVY_TASKFORCE_COUNT_INTEL_MIN`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433330D0 |
| 0x14089CF20 | define 读取器; 源锚 `defines_intel.h:74`; lua 表 `NIntel` · define `OLD_TECH_COUNT_NUM_DAYS`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433376D8 |
| 0x14089D130 | define 读取器; 源锚 `defines_intel.h:52`; lua 表 `NIntel` · define `RADAR_BASE_INTEL_VALUES_FOR_COUNTRY_COVERAGE_PERCENTAGE` |
| 0x14089D340 | define 读取器; 源锚 `defines_intel.h:53`; lua 表 `NIntel` · define `RADAR_BASE_INTEL_VALUES_FOR_COVERED_LAND_PROVINCES` |
| 0x14089D550 | define 读取器; 源锚 `defines_intel.h:54`; lua 表 `NIntel` · define `RADAR_BASE_INTEL_VALUES_FOR_COVERED_SEA_PROVINCES` |
| 0x14089D760 | define 读取器; 源锚 `defines_intel.h:51`; lua 表 `NIntel` · define `RADAR_INTEL_STACKING_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336B08 |
| 0x14089DA20 | define 读取器; 源锚 `defines_intel.h:50`; lua 表 `NIntel` · define `RADAR_LEVEL_INTEL_FACTOR`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336A30 |
| 0x14089DCE0 | define 读取器; 源锚 `defines_intel.h:55`; lua 表 `NIntel` · define `RADAR_NAVY_INTEL_FACTOR_PER_SHIP_TYPE`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_1433390A0 |
| 0x14089E240 | define 读取器; 源锚 `defines_intel.h:243`; lua 表 `NIntel` · define `RAID_MIN_INTEL_FOR_WARNING_HALFWAY_TO_LAUNCH`; 存储助手 sub_142072500（int64）; 全局槽 qword_1433354C0 |
| 0x14089E590 | define 读取器; 源锚 `defines_intel.h:242`; lua 表 `NIntel` · define `RAID_MIN_INTEL_FOR_WARNING_ON_LAUNCH`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335398 |
| 0x14089E8E0 | define 读取器; 源锚 `defines_intel.h:10`; lua 表 `NIntel` · define `RECON_INTEL_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143334F40 |
| 0x14089F540 | define 读取器; 源锚 `defines_intel.h:253`; lua 表 `NIntel` · define `STATIC_INTEL_SOURCE_OPERATION_TOKENS_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_14333… |
| 0x14089F750 | define 读取器; 源锚 `defines_intel.h:255`; lua 表 `NIntel` · define `STATIC_INTEL_SOURCE_RADAR_MAXIMUMS`; 存储助手 sub_142071190（qword 未细分）; 全局槽 qword_143339268 |
| 0x1407F3600 | defines 读取器；`source\defines_character.h:12`；lua 表 `NCharacter` 键 `ADVISOR_PROMOTION_COST`；sink `sub_142072500`；define 槽 `qword_143330F08` |
| 0x1407F4050 | defines 读取器；`source\defines_character.h:6`；lua 表 `NCharacter` 键 `DEFAULT_PP_COST_FOR_MILITARY_ADVISOR`；sink `sub_142072500`；define 槽 `qword_143338118` |
| 0x1407F4260 | defines 读取器；`source\defines_character.h:7`；lua 表 `NCharacter` 键 `DEFAULT_PP_COST_FOR_POLITICAL_ADVISOR`；sink `sub_142072500`；define 槽 `qword_1433381E0` |
| 0x1407F4680 | defines 读取器；`source\defines_character.h:20`；lua 表 `NCharacter` 键 `GENIUS_ADVISOR_MIN_RANK`；sink `sub_142070630`；define 槽 `dword_143331354` |
| 0x1407F4890 | defines 读取器；`source\defines_character.h:14`；lua 表 `NCharacter` 键 `OFFICER_CORP_ADVISOR_ENTRIES_IN_MENU`；sink `sub_1420711A0`；define 槽 `qword_143338608` |
| 0x1407E21E0 | defines 读取器；`source\defines_graphics.h:23`；lua 表 `NAirGfx` 键 `AIRPLANES_1_BOMBER_BOMBING_ANIM`；sink `sub_142070630`；define 槽 `dword_143332B28` |
| 0x1407E23F0 | defines 读取器；`source\defines_graphics.h:21`；lua 表 `NAirGfx` 键 `AIRPLANES_1_FIGHTER_PATROL_ANIM`；sink `sub_142070630`；define 槽 `dword_1433329A0` |
| 0x1407E2810 | defines 读取器；`source\defines_graphics.h:29`；lua 表 `NAirGfx` 键 `AIRPLANES_1_SCOUT_PLANE_PATROL_ANIM`；sink `sub_142070630`；define 槽 `dword_143332F10` |
| 0x1407E2A20 | defines 读取器；`source\defines_graphics.h:27`；lua 表 `NAirGfx` 键 `AIRPLANES_1_TRANSPORT_SUPPLY_ANIM`；sink `sub_142070630`；define 槽 `dword_143332DDC` |
| 0x1407E2C30 | defines 读取器；`source\defines_graphics.h:24`；lua 表 `NAirGfx` 键 `AIRPLANES_3_BOMBER_BOMBING_ANIM`；sink `sub_142070630`；define 槽 `dword_143332BD8` |
| 0x1407E2E40 | defines 读取器；`source\defines_graphics.h:22`；lua 表 `NAirGfx` 键 `AIRPLANES_3_FIGHTER_PATROL_ANIM`；sink `sub_142070630`；define 槽 `dword_143332A58` |
| 0x1407E3050 | defines 读取器；`source\defines_graphics.h:26`；lua 表 `NAirGfx` 键 `AIRPLANES_3_FIGHTER_VS_3_FIGHTER_ANIM`；sink `sub_142070630`；define 槽 `dword_143332D28` |
| 0x1407E3470 | defines 读取器；`source\defines_graphics.h:28`；lua 表 `NAirGfx` 键 `AIRPLANES_3_TRANSPORT_SUPPLY_ANIM`；sink `sub_142070630`；define 槽 `dword_143332E7C` |
| 0x1407E3AA0 | defines 读取器；`source\defines_graphics.h:18`；lua 表 `NAirGfx` 键 `AIRPLANES_BANK_STRENGTH`；sink `sub_142070980`；define 槽 `dword_143332784` |
| 0x1407E3CB0 | defines 读取器；`source\defines_graphics.h:10`；lua 表 `NAirGfx` 键 `AIRPLANES_CURVE_MAX_EXTRAPOLATION`；sink `sub_142070980`；define 槽 `dword_143332248` |
| 0x1407E3EC0 | defines 读取器；`source\defines_graphics.h:11`；lua 表 `NAirGfx` 键 `AIRPLANES_CURVE_MIN_ELEVATION`；sink `sub_142070980`；define 槽 `dword_1433322C8` |
| 0x1407E44F0 | defines 读取器；`source\defines_graphics.h:20`；lua 表 `NAirGfx` 键 `AIRPLANES_GROUND_EXPLOSION_TIME_DELAY`；sink `sub_142070980`；define 槽 `dword_1433328F8` |
| 0x1407E4B20 | defines 读取器；`source\defines_graphics.h:12`；lua 表 `NAirGfx` 键 `AIRPLANES_SCALE_TAKEOFF_DIST`；sink `sub_142070980`；define 槽 `dword_143332370` |
| 0x1407E4D30 | defines 读取器；`source\defines_graphics.h:15`；lua 表 `NAirGfx` 键 `AIRPLANES_SMOOTH_INTERPOLATION_MOVE`；sink `sub_142070980`；define 槽 `dword_143332558` |
| 0x1407E4F40 | defines 读取器；`source\defines_graphics.h:16`；lua 表 `NAirGfx` 键 `AIRPLANES_SMOOTH_INTERPOLATION_TURN`；sink `sub_142070980`；define 槽 `dword_143332618` |
| 0x1407E5360 | defines 读取器；`source\defines_graphics.h:40`；lua 表 `NAirGfx` 键 `FIGHTERS_DIVISION_FACTOR`；sink `sub_142070630`；define 槽 `dword_1433334F4` |
| 0x1407E5780 | defines 读取器；`source\defines_graphics.h:46`；lua 表 `NAirGfx` 键 `MAX_DOGFIGHTS_SCENARIOS`；sink `sub_142070630`；define 槽 `dword_143333944` |
| 0x1407E5FC0 | defines 读取器；`source\defines_graphics.h:48`；lua 表 `NAirGfx` 键 `MAX_TRAINING_SCENARIOS`；sink `sub_142070630`；define 槽 `dword_143333AD0` |
| 0x1407E63E0 | defines 读取器；`source\defines_graphics.h:39`；lua 表 `NAirGfx` 键 `MISSILES_DIVISION_FACTOR`；sink `sub_142070630`；define 槽 `dword_143333440` |
| 0x1407E65F0 | defines 读取器；`source\defines_graphics.h:32`；lua 表 `NAirGfx` 键 `RANDOM_SCENARIO_ANIMATION_MAX_DELAY`；sink `sub_142072500`；define 槽 `qword_143333078` |
| 0x1407E68B0 | defines 读取器；`source\defines_graphics.h:37`；lua 表 `NAirGfx` 键 `ROCKET_SPEED`；sink `sub_142070980`；define 槽 `dword_1433332C4` |
| 0x1407E6CD0 | defines 读取器；`source\defines_graphics.h:35`；lua 表 `NAirGfx` 键 `STRAT_BOMBER_CARPETBOMB_THRESHOLD`；sink `sub_142070980`；define 槽 `dword_143333218` |
| 0x1407E6EE0 | defines 读取器；`source\defines_graphics.h:34`；lua 表 `NAirGfx` 键 `STRAT_BOMBER_FIREBOMB_THRESHOLD`；sink `sub_142070980`；define 槽 `dword_14333316C` |
| 0x140842030 | defines 读取器；`source\defines_graphics.h:318`；lua 表 `NGraphics` 键 `ACCLIMATIZATION_CAMO_SHOW_AT`；sink `sub_142072500`；define 槽 `qword_143336C90` |
| 0x140842240 | defines 读取器；`source\defines_graphics.h:319`；lua 表 `NGraphics` 键 `ACCLIMATIZATION_CAMO_SHOW_WHEN_IN_STATE`；sink `sub_142072500`；define 槽 `qword_143336D50` |
| 0x140842450 | defines 读取器；`source\defines_graphics.h:265`；lua 表 `NGraphics` 键 `ADJACENCY_RULE_DISTANCE_CUTOFF`；sink `sub_142070980`；define 槽 `dword_143334EF8` |
| 0x140842870 | defines 读取器；`source\defines_graphics.h:187`；lua 表 `NGraphics` 键 `ALLIED_BATTLEPLANS_COLOR`；sink `sub_1420720F0`；define 槽 `unk_143331A70` |
| 0x140842A80 | defines 读取器；`source\defines_graphics.h:188`；lua 表 `NGraphics` 键 `ALLIED_BATTLEPLANS_FACTION_THEATER_COLOR`；sink `sub_1420720F0`；define 槽 `unk_143331B30` |
| 0x140842C90 | defines 读取器；`source\defines_graphics.h:343`；lua 表 `NGraphics` 键 `AMBIENT_LIGHT_NEG_X`；sink `sub_14074B2C0`；define 槽 `unk_143338AD0` |
| 0x140842EA0 | defines 读取器；`source\defines_graphics.h:345`；lua 表 `NGraphics` 键 `AMBIENT_LIGHT_NEG_Y`；sink `sub_14074B2C0`；define 槽 `unk_143338B10` |
| 0x1408434D0 | defines 读取器；`source\defines_graphics.h:344`；lua 表 `NGraphics` 键 `AMBIENT_LIGHT_POS_Y`；sink `sub_14074B2C0`；define 槽 `unk_143338AF0` |
| 0x1408438F0 | defines 读取器；`source\defines_graphics.h:312`；lua 表 `NGraphics` 键 `ARMY_DEFENSIVE_LINE_BUTTON_SIZE`；sink `sub_142072500`；define 槽 `unk_143336A08` |
| 0x140843B00 | defines 读取器；`source\defines_graphics.h:313`；lua 表 `NGraphics` 键 `ARMY_GROUP_DEFENSIVE_LINE_BUTTON_SIZE`；sink `sub_142072500`；define 槽 `unk_143336AB0` |
| 0x140844550 | defines 读取器；`source\defines_graphics.h:308`；lua 表 `NGraphics` 键 `ARROW_PARADROP_HEIGHT_TO_LEN`；sink `sub_142070980`；define 槽 `dword_143336800` |
| 0x140844760 | defines 读取器；`source\defines_graphics.h:326`；lua 表 `NGraphics` 键 `BLOOM_SCALE`；sink `sub_142070980`；define 槽 `dword_143336FD8` |
| 0x140844970 | defines 读取器；`source\defines_graphics.h:325`；lua 表 `NGraphics` 键 `BLOOM_WIDTH`；sink `sub_142070980`；define 槽 `dword_143336F38` |
| 0x140844B80 | defines 读取器；`source\defines_graphics.h:182`；lua 表 `NGraphics` 键 `BORDER_COLOR_BORDER_CONFLICT_EDGE_A`；sink `sub_142070980`；define 槽 `dword_143331714` |
| 0x140844FA0 | defines 读取器；`source\defines_graphics.h:180`；lua 表 `NGraphics` 键 `BORDER_COLOR_BORDER_CONFLICT_EDGE_G`；sink `sub_142070980`；define 槽 `dword_1433315BC` |
| 0x1408453C0 | defines 读取器；`source\defines_graphics.h:186`；lua 表 `NGraphics` 键 `BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_A`；sink `sub_142070980`；define 槽 `dword_1433319D0` |
| 0x1408457E0 | defines 读取器；`source\defines_graphics.h:184`；lua 表 `NGraphics` 键 `BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_G`；sink `sub_142070980`；define 槽 `dword_143331880` |
| 0x1408459F0 | defines 读取器；`source\defines_graphics.h:183`；lua 表 `NGraphics` 键 `BORDER_COLOR_BORDER_CONFLICT_NON_EDGE_R`；sink `sub_142070980`；define 槽 `dword_1433317C8` |
| 0x140845C00 | defines 读取器；`source\defines_graphics.h:170`；lua 表 `NGraphics` 键 `BORDER_COLOR_CUSTOM_HIGHLIGHTS`；sink `sub_142070C60`；define 槽 `qword_143338A58` |
| 0x140846230 | defines 读取器；`source\defines_graphics.h:176`；lua 表 `NGraphics` 键 `BORDER_COLOR_DEMILITARIZED_G`；sink `sub_142070980`；define 槽 `dword_143331334` |
| 0x140846860 | defines 读取器；`source\defines_graphics.h:164`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_ADJACENCY_RULE_AREA_B`；sink `sub_142070980`；define 槽 `dword_143338138` |
| 0x140846C80 | defines 读取器；`source\defines_graphics.h:162`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_ADJACENCY_RULE_AREA_R`；sink `sub_142070980`；define 槽 `dword_143337FE8` |
| 0x140846E90 | defines 读取器；`source\defines_graphics.h:169`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_BUILDING_AREA_A`；sink `sub_142070980`；define 槽 `dword_143330E90` |
| 0x1408470A0 | defines 读取器；`source\defines_graphics.h:168`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_BUILDING_AREA_B`；sink `sub_142070980`；define 槽 `dword_143338410` |
| 0x1408474C0 | defines 读取器；`source\defines_graphics.h:166`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_BUILDING_AREA_R`；sink `sub_142070980`；define 槽 `dword_1433382A8` |
| 0x1408476D0 | defines 读取器；`source\defines_graphics.h:153`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_PROVINCE_A`；sink `sub_142070980`；define 槽 `dword_1433379A0` |
| 0x1408478E0 | defines 读取器；`source\defines_graphics.h:152`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_PROVINCE_B`；sink `sub_142070980`；define 槽 `dword_1433378E8` |
| 0x140847D00 | defines 读取器；`source\defines_graphics.h:150`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_PROVINCE_R`；sink `sub_142070980`；define 槽 `dword_14333776C` |
| 0x140848330 | defines 读取器；`source\defines_graphics.h:155`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_STATE_G`；sink `sub_142070980`；define 槽 `dword_143337B08` |
| 0x140848540 | defines 读取器；`source\defines_graphics.h:154`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_STATE_R`；sink `sub_142070980`；define 槽 `dword_143337A60` |
| 0x140848750 | defines 读取器；`source\defines_graphics.h:161`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_SUPPLY_AREA_A`；sink `sub_142070980`；define 槽 `dword_143337F38` |
| 0x140848960 | defines 读取器；`source\defines_graphics.h:160`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_SUPPLY_AREA_B`；sink `sub_142070980`；define 槽 `dword_143337E70` |
| 0x140848D80 | defines 读取器；`source\defines_graphics.h:158`；lua 表 `NGraphics` 键 `BORDER_COLOR_SELECTION_SUPPLY_AREA_R`；sink `sub_142070980`；define 槽 `dword_143337CFC` |
| 0x1408491A0 | defines 读取器；`source\defines_graphics.h:173`；lua 表 `NGraphics` 键 `BORDER_COLOR_TUTORIAL_HIGHLIGHT_B`；sink `sub_142070980`；define 槽 `dword_143331144` |
| 0x1408495C0 | defines 读取器；`source\defines_graphics.h:171`；lua 表 `NGraphics` 键 `BORDER_COLOR_TUTORIAL_HIGHLIGHT_R`；sink `sub_142070980`；define 槽 `dword_143330FE4` |
| 0x1408497D0 | defines 读取器；`source\defines_graphics.h:112`；lua 表 `NGraphics` 键 `BORDER_WIDTH`；sink `sub_142070980`；define 槽 `dword_143335FAC` |
| 0x140849E00 | defines 读取器；`source\defines_graphics.h:439`；lua 表 `NGraphics` 键 `CAMERA_OUTSIDE_MAP_DISTANCE_TOP`；sink `sub_142070980`；define 槽 `dword_143333C70` |
| 0x14084A010 | defines 读取器；`source\defines_graphics.h:443`；lua 表 `NGraphics` 键 `CAMERA_ZOOM_KEY_SCALE`；sink `sub_142070980`；define 槽 `dword_143333E6C` |
| 0x14084A430 | defines 读取器；`source\defines_graphics.h:444`；lua 表 `NGraphics` 键 `CAMERA_ZOOM_SPEED_DISTANCE_MULT`；sink `sub_142070980`；define 槽 `dword_143333EF8` |
| 0x14084A850 | defines 读取器；`source\defines_graphics.h:93`；lua 表 `NGraphics` 键 `CITY_DAMAGED_THRESHOLD`；sink `sub_142070980`；define 槽 `dword_143335460` |
| 0x14084AE80 | defines 读取器；`source\defines_graphics.h:437`；lua 表 `NGraphics` 键 `COMMANDGROUP_PRESET_COLORS_HSV`；sink `sub_142070C60`；define 槽 `qword_143338D30` |
| 0x14084B4B0 | defines 读取器；`source\defines_graphics.h:80`；lua 表 `NGraphics` 键 `COUNTER_MODE_ALLEGIANCE_ALLIED`；sink `sub_1420720F0`；define 槽 `unk_143334BE0` |
| 0x14084B8D0 | defines 读取器；`source\defines_graphics.h:82`；lua 表 `NGraphics` 键 `COUNTER_MODE_ALLEGIANCE_OTHER`；sink `sub_1420720F0`；define 槽 `unk_143334D30` |
| 0x14084C530 | defines 读取器；`source\defines_graphics.h:234`；lua 表 `NGraphics` 键 `COUNTRY_FLAG_MEDIUM_TEX_MAX_SIZE`；sink `sub_142070630`；define 槽 `dword_143333AE8` |
| 0x14084C740 | defines 读取器；`source\defines_graphics.h:232`；lua 表 `NGraphics` 键 `COUNTRY_FLAG_MEDIUM_TEX_WIDTH`；sink `sub_142070630`；define 槽 `dword_143333970` |
| 0x14084C950 | defines 读取器；`source\defines_graphics.h:236`；lua 表 `NGraphics` 键 `COUNTRY_FLAG_SMALL_TEX_HEIGHT`；sink `sub_142070630`；define 槽 `dword_143333C38` |
| 0x14084CB60 | defines 读取器；`source\defines_graphics.h:237`；lua 表 `NGraphics` 键 `COUNTRY_FLAG_SMALL_TEX_MAX_SIZE`；sink `sub_142070630`；define 槽 `dword_143333CF0` |
| 0x14084CD70 | defines 读取器；`source\defines_graphics.h:235`；lua 表 `NGraphics` 键 `COUNTRY_FLAG_SMALL_TEX_WIDTH`；sink `sub_142070630`；define 槽 `dword_143333BA0` |
| 0x14084D7C0 | defines 读取器；`source\defines_graphics.h:433`；lua 表 `NGraphics` 键 `COUNTRY_UI_COLOR_HUE_MODIFIER`；sink `sub_142070980`；define 槽 `dword_143333980` |
| 0x14084D9D0 | defines 读取器；`source\defines_graphics.h:434`；lua 表 `NGraphics` 键 `COUNTRY_UI_COLOR_SATURATION_MODIFIER`；sink `sub_142070980`；define 槽 `dword_143333A30` |
| 0x14084DBE0 | defines 读取器；`source\defines_graphics.h:644`；lua 表 `NGraphics` 键 `COUP_GREEN`；sink `sub_14074B2C0`；define 槽 `unk_143339060` |
| 0x14084E000 | defines 读取器；`source\defines_graphics.h:269`；lua 表 `NGraphics` 键 `CRYPTOLOGY_MAP_ICON_DISTANCE_CUTOFF`；sink `sub_142070980`；define 槽 `dword_143335174` |
| 0x14084E210 | defines 读取器；`source\defines_graphics.h:353`；lua 表 `NGraphics` 键 `CUBEMAP_INTENSITY`；sink `sub_142070980`；define 槽 `dword_143338270` |
| 0x14084E630 | defines 读取器；`source\defines_graphics.h:262`；lua 表 `NGraphics` 键 `DECISION_MAP_ICON_DEPTH_PRIORITY`；sink `sub_142070630`；define 槽 `dword_143334CE0` |
| 0x14084E840 | defines 读取器；`source\defines_graphics.h:259`；lua 表 `NGraphics` 键 `DECISION_MAP_ICON_DISTANCE_CUTOFF`；sink `sub_142070980`；define 槽 `dword_143334AD0` |
| 0x14084EA50 | defines 读取器；`source\defines_graphics.h:647`；lua 表 `NGraphics` 键 `DEFAULT_NUDGE_FLOATING_HARBOR_DIST`；sink `sub_142070980`；define 槽 `dword_143333B60` |
| 0x14084F080 | defines 读取器；`source\defines_graphics.h:104`；lua 表 `NGraphics` 键 `DIRECTION_POINTER_GROUND_OFFSET`；sink `sub_142070980`；define 槽 `dword_143335AF8` |
| 0x14084F290 | defines 读取器；`source\defines_graphics.h:99`；lua 表 `NGraphics` 键 `DIRECTION_POINTER_INTERPOLATION_SPEED`；sink `sub_142070980`；define 槽 `dword_1433357E0` |
| 0x14084F4A0 | defines 读取器；`source\defines_graphics.h:101`；lua 表 `NGraphics` 键 `DIRECTION_POINTER_SCREEN_AREA_MAX`；sink `sub_142070980`；define 槽 `dword_143335930` |
| 0x14084FAD0 | defines 读取器；`source\defines_graphics.h:102`；lua 表 `NGraphics` 键 `DIRECTION_POINTER_SIZE_MIN`；sink `sub_142070980`；define 槽 `dword_1433359CC` |
| 0x14084FCE0 | defines 读取器；`source\defines_graphics.h:354`；lua 表 `NGraphics` 键 `DIVISION_NAMES_GROUP_MAX_TOOLTIP_ENTRIES`；sink `sub_142070630`；define 槽 `dword_143338320` |
| 0x14084FEF0 | defines 读取器；`source\defines_graphics.h:120`；lua 表 `NGraphics` 键 `DRAW_COUNTRY_NAMES_CUTOFF`；sink `sub_142070630`；define 槽 `dword_14333645C` |
| 0x140850310 | defines 读取器；`source\defines_graphics.h:196`；lua 表 `NGraphics` 键 `DRAW_FOW_FADE_LENGTH`；sink `sub_142070980`；define 槽 `dword_1433320E4` |
| 0x140850730 | defines 读取器；`source\defines_graphics.h:192`；lua 表 `NGraphics` 键 `DRAW_REFRACTIONS_CUTOFF`；sink `sub_142070630`；define 槽 `dword_143331E0C` |
| 0x140850B50 | defines 读取器；`source\defines_graphics.h:194`；lua 表 `NGraphics` 键 `DRAW_SHADOWS_FADE_LENGTH`；sink `sub_142070980`；define 槽 `dword_143331F94` |
| 0x140852620 | defines 读取器；`source\defines_graphics.h:225`；lua 表 `NGraphics` 键 `GMT_OFFSET`；sink `sub_142070630`；define 槽 `dword_143333468` |
| 0x140852830 | defines 读取器；`source\defines_graphics.h:603`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_ACTIVATE_FOR_PEACE_CONFERENCE`；sink `sub_142072840`；define 槽 `byte_143330E69` |
| 0x140852A40 | defines 读取器；`source\defines_graphics.h:213`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_COUNTRY`；sink `sub_142070980`；define 槽 `dword_1433… |
| 0x140852C50 | defines 读取器；`source\defines_graphics.h:214`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_DIPLOMACY`；sink `sub_142070980`；define 槽 `dword_14… |
| 0x140852E60 | defines 读取器；`source\defines_graphics.h:215`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_DIPLOMACY_ON_INTEL_LEDGER`；sink `sub_142070980`；de… |
| 0x140853280 | defines 读取器；`source\defines_graphics.h:594`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_INTEL_LEDGER`；sink `sub_142070980`；define 槽 `dword… |
| 0x140853490 | defines 读取器；`source\defines_graphics.h:602`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_PEACE_CONFERENCE`；sink `sub_142070980`；define 槽 `d… |
| 0x1408536A0 | defines 读取器；`source\defines_graphics.h:219`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_RESISTANCE`；sink `sub_142070980`；define 槽 `unk_143… |
| 0x1408538B0 | defines 读取器；`source\defines_graphics.h:216`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_STATE`；sink `sub_142070980`；define 槽 `dword_143332… |
| 0x140853AC0 | defines 读取器；`source\defines_graphics.h:218`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_STRATEGIC_REGIONS`；sink `sub_142070980`；define 槽 `… |
| 0x140853CD0 | defines 读取器；`source\defines_graphics.h:217`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_SUPPLY_AREA`；sink `sub_142070980`；define 槽 `unk_14… |
| 0x140853EE0 | defines 读取器；`source\defines_graphics.h:221`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_TERRAIN`；sink `sub_142070980`；define 槽 `dword_1433… |
| 0x1408540F0 | defines 读取器；`source\defines_graphics.h:224`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_COUNTRY_CENTER_THICKNESS`；sink `sub_142070980`；define 槽 `dword_143333398` |
| 0x140854300 | defines 读取器；`source\defines_graphics.h:199`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_FIELD_COUNTRY_HIGH`；sink `sub_142070980`；define 槽 `dword_14333229C` |
| 0x140854720 | defines 读取器；`source\defines_graphics.h:197`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_FIELD_COUNTRY_REFRESH`；sink `sub_142070630`；define 槽 `dword_14333217C` |
| 0x140854930 | defines 读取器；`source\defines_graphics.h:604`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_ONE_COLOR_FOR_PEACE_CONFERENCE`；sink `sub_14074B2C0`；define 槽 `unk_143338EC0` |
| 0x140854B40 | defines 读取器；`source\defines_graphics.h:222`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OPTIMIZATION_RANGE`；sink `sub_142070980`；define 槽 `dword_143333238` |
| 0x140854F60 | defines 读取器；`source\defines_graphics.h:588`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_DIPLOMACY`；sink `sub_142070980`；define 槽 `dword_143331C5C` |
| 0x140855170 | defines 读取器；`source\defines_graphics.h:589`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_DIPLOMACY_ON_INTEL_LEDGER`；sink `sub_142070980`；define 槽 `dw… |
| 0x140855380 | defines 读取器；`source\defines_graphics.h:212`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_FACTIONS`；sink `sub_142070980`；define 槽 `dword_143332B78` |
| 0x1408557A0 | defines 读取器；`source\defines_graphics.h:601`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_PEACE_CONFERENCE`；sink `sub_142070980`；define 槽 `dword_14333… |
| 0x1408559B0 | defines 读取器；`source\defines_graphics.h:211`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_RESISTANCE`；sink `sub_142070980`；define 槽 `dword_143332A88` |
| 0x140855BC0 | defines 读取器；`source\defines_graphics.h:208`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_STATE`；sink `sub_142070980`；define 槽 `dword_1433328B0` |
| 0x140855DD0 | defines 读取器；`source\defines_graphics.h:210`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_STRATEGIC_REGIONS`；sink `sub_142070980`；define 槽 `dword_1433… |
| 0x140855FE0 | defines 读取器；`source\defines_graphics.h:209`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_OUTLINE_CUTOFF_SUPPLY_AREA`；sink `sub_142070980`；define 槽 `unk_143332928` |
| 0x140856400 | defines 读取器；`source\defines_graphics.h:201`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_COUNTRY_HIGH`；sink `sub_142070980`；define 槽 `dword_1433323DC` |
| 0x140856610 | defines 读取器；`source\defines_graphics.h:200`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_COUNTRY_LOW`；sink `sub_142070980`；define 槽 `dword_14333234C` |
| 0x140856820 | defines 读取器；`source\defines_graphics.h:206`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_DIPLOMACY`；sink `sub_142070980`；define 槽 `dword_143332748` |
| 0x140856A30 | defines 读取器；`source\defines_graphics.h:592`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_DIPLOMACY_ON_INTEL_LEDGER`；sink `sub_142070980`；define 槽 `unk_143… |
| 0x140856C40 | defines 读取器；`source\defines_graphics.h:591`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_INTEL_LEDGER`；sink `sub_142070980`；define 槽 `dword_143331DA8` |
| 0x140856E50 | defines 读取器；`source\defines_graphics.h:599`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_PEACE_CONFERENCE_A`；sink `sub_142070980`；define 槽 `dword_14333215C` |
| 0x140857060 | defines 读取器；`source\defines_graphics.h:600`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_PEACE_CONFERENCE_B`；sink `sub_142070980`；define 槽 `dword_1433321F0` |
| 0x140857480 | defines 读取器；`source\defines_graphics.h:202`；lua 表 `NGraphics` 键 `GRADIENT_BORDERS_THICKNESS_STATE`；sink `sub_142070980`；define 槽 `dword_143332478` |
| 0x140857ED0 | defines 读取器；`source\defines_graphics.h:615`；lua 表 `NGraphics` 键 `INTEL_LEDGER_AIR_REGION_COLOR`；sink `sub_14074B2C0`；define 槽 `unk_143338F80` |
| 0x1408580E0 | defines 读取器；`source\defines_graphics.h:609`；lua 表 `NGraphics` 键 `INTEL_LEDGER_ARMY_FORT_LEVEL_COLORS`；sink `sub_142070C60`；define 槽 `qword_143338F20` |
| 0x1408582F0 | defines 读取器；`source\defines_graphics.h:386`；lua 表 `NGraphics` 键 `INTEL_LEDGER_CIVILIAN_ICON_REGION_CUTOFF`；sink `sub_142070980`；define 槽 `dword_1433321EC` |
| 0x140858500 | defines 读取器；`source\defines_graphics.h:387`；lua 表 `NGraphics` 键 `INTEL_LEDGER_CIVILIAN_ICON_STATE_CUTOFF`；sink `sub_142070980`；define 槽 `dword_143332288` |
| 0x140858920 | defines 读取器；`source\defines_graphics.h:617`；lua 表 `NGraphics` 键 `INTEL_LEDGER_GRAPH_RED`；sink `sub_14074B2C0`；define 槽 `unk_143338FA0` |
| 0x140858D40 | defines 读取器；`source\defines_graphics.h:606`；lua 表 `NGraphics` 键 `INTEL_LEDGER_NAVY_REGION_COLOR_WITH_MISSION`；sink `sub_14074B2C0`；define 槽 `unk_143338EE0` |
| 0x140858F50 | defines 读取器；`source\defines_graphics.h:607`；lua 表 `NGraphics` 键 `INTEL_LEDGER_NAVY_REGION_COLOR_WITH_MISSION_AND_TASKFORCES_IN_REGION`；sink `sub_14074B2C0`；d… |
| 0x140859160 | defines 读取器；`source\defines_graphics.h:464`；lua 表 `NGraphics` 键 `INTEL_NETWORK_VALID_COUNTRY_TARGET_STRIPE_COLOR`；sink `sub_1420720F0`；define 槽 `unk_143334850` |
| 0x140859370 | defines 读取器；`source\defines_graphics.h:463`；lua 表 `NGraphics` 键 `INTEL_NETWORK_VALID_TARGET_STRIPE_COLOR`；sink `sub_1420720F0`；define 槽 `unk_1433347B0` |
| 0x1408599A0 | defines 读取器；`source\defines_graphics.h:357`；lua 表 `NGraphics` 键 `LAND_COMBAT_LOSING_COLOR`；sink `sub_14074B2C0`；define 槽 `unk_143338BD0` |
| 0x140859BB0 | defines 读取器；`source\defines_graphics.h:358`；lua 表 `NGraphics` 键 `LAND_COMBAT_WINNING_COLOR`；sink `sub_14074B2C0`；define 槽 `unk_143338BF0` |
| 0x140859FD0 | defines 读取器；`source\defines_graphics.h:105`；lua 表 `NGraphics` 键 `LIGHT_DIRECTION_X`；sink `sub_142070980`；define 槽 `dword_143335B94` |
| 0x14085A3F0 | defines 读取器；`source\defines_graphics.h:107`；lua 表 `NGraphics` 键 `LIGHT_DIRECTION_Z`；sink `sub_142070980`；define 槽 `dword_143335CC4` |
| 0x14085AC30 | defines 读取器；`source\defines_graphics.h:110`；lua 表 `NGraphics` 键 `LIGHT_SHADOW_DIRECTION_Z`；sink `sub_142070980`；define 槽 `dword_143335E88` |
| 0x14085B050 | defines 读取器；`source\defines_graphics.h:92`；lua 表 `NGraphics` 键 `MAP_BUILDINGS_DAMAGED_THRESHOLD`；sink `sub_142070980`；define 槽 `dword_1433353C8` |
| 0x14085B260 | defines 读取器；`source\defines_graphics.h:91`；lua 表 `NGraphics` 键 `MAP_BUILDINGS_DESTROYED_DEAD_ZONE`；sink `sub_142070980`；define 槽 `dword_143335328` |
| 0x14085B680 | defines 读取器；`source\defines_graphics.h:89`；lua 表 `NGraphics` 键 `MAP_BUILDINGS_SHRINK_DISTANCE`；sink `sub_142070980`；define 槽 `dword_1433351E8` |
| 0x14085B890 | defines 读取器；`source\defines_graphics.h:285`；lua 表 `NGraphics` 键 `MAP_ICONS_COARSE_COUNTRY_GROUPING_DISTANCE`；sink `sub_142070630`；define 槽 `dword_143335A10` |
| 0x14085BAA0 | defines 读取器；`source\defines_graphics.h:286`；lua 表 `NGraphics` 键 `MAP_ICONS_COARSE_COUNTRY_GROUPING_DISTANCE_STRATEGIC`；sink `sub_142070630`；define 槽 `dword_1… |
| 0x14085BCB0 | defines 读取器；`source\defines_graphics.h:274`；lua 表 `NGraphics` 键 `MAP_ICONS_GROUP_CAM_DISTANCE`；sink `sub_142072500`；define 槽 `qword_143335490` |
| 0x14085BEC0 | defines 读取器；`source\defines_graphics.h:284`；lua 表 `NGraphics` 键 `MAP_ICONS_GROUP_SPLIT_SELECTED_LIMIT`；sink `sub_142070630`；define 槽 `dword_143335974` |
| 0x14085C0D0 | defines 读取器；`source\defines_graphics.h:275`；lua 表 `NGraphics` 键 `MAP_ICONS_STATE_GROUP_CAM_DISTANCE`；sink `sub_142072500`；define 槽 `qword_143335518` |
| 0x14085C4F0 | defines 读取器；`source\defines_graphics.h:277`；lua 表 `NGraphics` 键 `MAP_ICONS_STRATEGIC_AREA_HUGE`；sink `sub_142070630`；define 槽 `dword_143335638` |
| 0x14085C700 | defines 读取器；`source\defines_graphics.h:276`；lua 表 `NGraphics` 键 `MAP_ICONS_STRATEGIC_GROUP_CAM_DISTANCE`；sink `sub_142072500`；define 槽 `qword_1433355A8` |
| 0x14085C910 | defines 读取器；`source\defines_graphics.h:330`；lua 表 `NGraphics` 键 `MAX_HDR_ADJUSTMENT`；sink `sub_142070980`；define 槽 `dword_14333728C` |
| 0x14085CD30 | defines 读取器；`source\defines_graphics.h:281`；lua 表 `NGraphics` 键 `MAX_NUMBER_OF_TEXTURES`；sink `sub_142070630`；define 槽 `dword_143335810` |
| 0x14085CFF0 | defines 读取器；`source\defines_graphics.h:122`；lua 表 `NGraphics` 键 `MAX_TRAIN_WAGON_COUNT`；sink `sub_142070630`；define 槽 `dword_1433365F0` |
| 0x14085D2B0 | defines 读取器；`source\defines_graphics.h:85`；lua 表 `NGraphics` 键 `MESH_POPUP_SCALE_DOWN_SPEED`；sink `sub_142070980`；define 槽 `dword_143334F3C` |
| 0x14085D6D0 | defines 读取器；`source\defines_graphics.h:371`；lua 表 `NGraphics` 键 `MINIMUM_PROVINCE_SIZE_IN_PIXELS`；sink `sub_142070630`；define 槽 `dword_143331798` |
| 0x14085DFC0 | define 读取器; 源锚 `defines_graphics.h:338`; lua 表 `NGraphics` · define `MOON_HEIGHT`; 存储助手 sub_142070980（float）; 全局槽 dword_143337748 |
| 0x14085E1D0 | define 读取器; 源锚 `defines_graphics.h:341`; lua 表 `NGraphics` · define `MOON_HEIGHT_WATER`; 存储助手 sub_142070980（float）; 全局槽 dword_143337968 |
| 0x14085E3E0 | define 读取器; 源锚 `defines_graphics.h:352`; lua 表 `NGraphics` · define `MOON_INTENSITY`; 存储助手 sub_142070980（float）; 全局槽 dword_1433381C0 |
| 0x14085E800 | define 读取器; 源锚 `defines_graphics.h:448`; lua 表 `NGraphics` · define `MOVE_ORDERS_MOUSE_INTERSECT_DISTANCE_MULT`; 存储助手 sub_142070980（float）; 全局槽 dword_1433340D0 |
| 0x14085EA10 | define 读取器; 源锚 `defines_graphics.h:355`; lua 表 `NGraphics` · define `NAMES_GROUP_MAX_NAME_LIST_ENTRIES`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433383C0 |
| 0x14085F040 | define 读取器; 源锚 `defines_graphics.h:452`; lua 表 `NGraphics` · define `NATIONAL_FOCUS_SHINE_DISTANCE_SCALE`; 存储助手 sub_142070980（float）; 全局槽 dword_1433342B0 |
| 0x14085F880 | define 读取器; 源锚 `defines_graphics.h:272`; lua 表 `NGraphics` · define `NAVAL_MINES_CLUMP_NEAR_TERRITORY`; 存储助手 sub_142070630（int32）; 全局槽 dword_143335350 |
| 0x1408600C0 | define 读取器; 源锚 `defines_graphics.h:263`; lua 表 `NGraphics` · define `NAVAL_MISSION_TASK_FORCES_GROUP_BY_ALLEGIANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dw… |
| 0x1408604E0 | define 读取器; 源锚 `defines_graphics.h:425`; lua 表 `NGraphics` · define `NEUTRAL_COLOR`; 存储助手 sub_142071C30（dword 未细分）; 全局槽 dword_1433335D8 |
| 0x1408606F0 | define 读取器; 源锚 `defines_graphics.h:75`; lua 表 `NGraphics` · define `NODE_FLOW_IN_CURRENT_RANGE_COLOR` |
| 0x140860B10 | define 读取器; 源锚 `defines_graphics.h:76`; lua 表 `NGraphics` · define `NODE_FLOW_IN_HALF_RANGE_COLOR` |
| 0x140861140 | define 读取器; 源锚 `defines_graphics.h:584`; lua 表 `NGraphics` · define `OCCUPATION_RESISTANCE_MAP_MODE_COLORS`; 存储助手 sub_142070C60（qword 未细分）; 全局槽 qword_143338E68 |
| 0x140861350 | define 读取器; 源锚 `defines_graphics.h:586`; lua 表 `NGraphics` · define `OCCUPATION_RESISTANCE_NON_INITIALIZED_COLOR` |
| 0x140861B90 | define 读取器; 源锚 `defines_graphics.h:146`; lua 表 `NGraphics` · define `ORDER_FRONT_SMOOTHEN_PASSES`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433374D4 |
| 0x140861FB0 | define 读取器; 源锚 `defines_graphics.h:148`; lua 表 `NGraphics` · define `ORDER_MOVE_SMOOTHEN_PASSES`; 存储助手 sub_142070630（int32）; 全局槽 dword_143337620 |
| 0x1408623D0 | define 读取器; 源锚 `defines_graphics.h:270`; lua 表 `NGraphics` · define `PEACE_CONFERENCE_MAP_ICON_DISTANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_14333521C |
| 0x140862C10 | define 读取器; 源锚 `defines_graphics.h:87`; lua 表 `NGraphics` · define `PORT_SHIP_OFFSET` |
| 0x140863240 | define 读取器; 源锚 `defines_graphics.h:305`; lua 表 `NGraphics` · define `POSTEFFECT_FEATHER_MAX_DISTANCE`; 存储助手 sub_142070980（float）; 全局槽 dword_143336610 |
| 0x140863660 | define 读取器; 源锚 `defines_graphics.h:301`; lua 表 `NGraphics` · define `POSTEFFECT_PER_PROVINCE_MAX_SNOW`; 存储助手 sub_142070980（float）; 全局槽 dword_143336398 |
| 0x140863870 | define 读取器; 源锚 `defines_graphics.h:300`; lua 表 `NGraphics` · define `POSTEFFECT_PER_PROVINCE_MIN_SNOW`; 存储助手 sub_142070980（float）; 全局槽 dword_1433362E8 |
| 0x140863C90 | define 读取器; 源锚 `defines_graphics.h:302`; lua 表 `NGraphics` · define `POSTEFFECT_TOTAL_MIN_SNOW`; 存储助手 sub_142070980（float）; 全局槽 dword_143336430 |
| 0x140867EB0 | define 读取器; 源锚 `defines_graphics.h:412`; lua 表 `NGraphics` · define `RAID_SOURCE_MAP_STRIPES_COLOR` |
| 0x1408680C0 | define 读取器; 源锚 `defines_graphics.h:413`; lua 表 `NGraphics` · define `RAID_SOURCE_MAP_STRIPES_HOVERED_COLOR` |
| 0x1408689C0 | define 读取器; 源锚 `defines_graphics.h:651`; lua 表 `NGraphics` · define `RAID_UNIT_ZOOM_HEIGHT`; 存储助手 sub_142070980（float）; 全局槽 dword_143333CC8 |
| 0x140868DE0 | define 读取器; 源锚 `defines_graphics.h:132`; lua 表 `NGraphics` · define `RAILWAY_BRIDGE_GAP_LARGE_WIDTH`; 存储助手 sub_142070980（float）; 全局槽 dword_143336C28 |
| 0x140869200 | define 读取器; 源锚 `defines_graphics.h:126`; lua 表 `NGraphics` · define `RAILWAY_BRIDGE_LARGE_ENTITY`; 存储助手 sub_142072800 |
| 0x140869620 | define 读取器; 源锚 `defines_graphics.h:129`; lua 表 `NGraphics` · define `RAILWAY_BRIDGE_WIDTH`; 存储助手 sub_142070980（float）; 全局槽 dword_143336A40 |
| 0x140869A40 | define 读取器; 源锚 `defines_graphics.h:321`; lua 表 `NGraphics` · define `RAILWAY_CAMERA_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_143336E04 |
| 0x14086A490 | define 读取器; 源锚 `defines_graphics.h:450`; lua 表 `NGraphics` · define `RAILWAY_INTERSECT_DISTANCE_MULT`; 存储助手 sub_142070980（float）; 全局槽 dword_143334220 |
| 0x14086A8B0 | define 读取器; 源锚 `defines_graphics.h:58`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_CONSTRUCTION_INVALID` |
| 0x14086AAC0 | define 读取器; 源锚 `defines_graphics.h:57`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_CONSTRUCTION_VALID` |
| 0x14086ACD0 | define 读取器; 源锚 `defines_graphics.h:59`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_DAMAGED` |
| 0x14086AEE0 | define 读取器; 源锚 `defines_graphics.h:55`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_DEFAULT` |
| 0x14086B0F0 | define 读取器; 源锚 `defines_graphics.h:61`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED` |
| 0x14086B300 | define 读取器; 源锚 `defines_graphics.h:65`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_BOTTLENECK` |
| 0x14086B510 | define 读取器; 源锚 `defines_graphics.h:66`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_BOTTLENECK_MAXLEVEL` |
| 0x14086BB40 | define 读取器; 源锚 `defines_graphics.h:64`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_HIGHLIGHTED_ONCOOLDOWN` |
| 0x14086BD50 | define 读取器; 源锚 `defines_graphics.h:60`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_COLOR_ONCOOLDOWN` |
| 0x14086C170 | define 读取器; 源锚 `defines_graphics.h:53`; lua 表 `NGraphics` · define `RAILWAY_MAP_ARROW_THICK_LEVEL_THRESHOLD` |
| 0x14086CBC0 | define 读取器; 源锚 `defines_graphics.h:417`; lua 表 `NGraphics` · define `RESISTANCE_COLOR_GOOD` |
| 0x14086CFE0 | define 读取器; 源锚 `defines_graphics.h:260`; lua 表 `NGraphics` · define `RESISTANCE_MAP_ICON_DISTANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_143334B74 |
| 0x14086D1F0 | define 读取器; 源锚 `defines_graphics.h:261`; lua 表 `NGraphics` · define `RESISTANCE_MAP_ICON_MODIFIERS_DISTANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_143… |
| 0x14086D400 | define 读取器; 源锚 `defines_graphics.h:246`; lua 表 `NGraphics` · define `RESOURCE_MAP_ICON_TEXT_CUTOFF`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433342A0 |
| 0x14086D820 | define 读取器; 源锚 `defines_graphics.h:288`; lua 表 `NGraphics` · define `RIVER_FADE_TO`; 存储助手 sub_142072500（int64）; 全局槽 qword_143335BE0 |
| 0x14086DA30 | define 读取器; 源锚 `defines_graphics.h:69`; lua 表 `NGraphics` · define `RIVER_SUPPLY_MAP_ARROW_COLOR` |
| 0x14086DE50 | define 读取器; 源锚 `defines_graphics.h:143`; lua 表 `NGraphics` · define `ROOT_FRONT_MAX_INTERSECTION_TESTS_ORDER`; 存储助手 sub_142070630（int32）; 全局槽 dword_143337334 |
| 0x14086E480 | define 读取器; 源锚 `defines_graphics.h:137`; lua 表 `NGraphics` · define `ROOT_FRONT_SMOOTHNESS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336F60 |
| 0x14086E8A0 | define 读取器; 源锚 `defines_graphics.h:336`; lua 表 `NGraphics` · define `SECOND_SUN_LATITUDE`; 存储助手 sub_142070980（float）; 全局槽 dword_1433375E0 |
| 0x14086ECC0 | define 读取器; 源锚 `defines_graphics.h:251`; lua 表 `NGraphics` · define `SHIPS_DISTANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_1433345B4 |
| 0x14086F0E0 | define 读取器; 源锚 `defines_graphics.h:367`; lua 表 `NGraphics` · define `SHIP_IN_MISSION_SPEED`; 存储助手 sub_142070980（float）; 全局槽 dword_1433314F0 |
| 0x14086FF50 | define 读取器; 源锚 `defines_graphics.h:140`; lua 表 `NGraphics` · define `SNAPPED_OFF_FRONT_SMOOTHEN_PASSES`; 存储助手 sub_142070630（int32）; 全局槽 dword_143337190 |
| 0x1408709A0 | define 读取器; 源锚 `defines_graphics.h:267`; lua 表 `NGraphics` · define `STATE_CONSTRUCTION_ICON_DISTANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_143335030 |
| 0x140870DC0 | define 读取器; 源锚 `defines_graphics.h:399`; lua 表 `NGraphics` · define `STRATEGIC_AIR_COLOR_BAD` |
| 0x1408711E0 | define 读取器; 源锚 `defines_graphics.h:402`; lua 表 `NGraphics` · define `STRATEGIC_AIR_COLOR_NEUTRAL` |
| 0x140871600 | define 读取器; 源锚 `defines_graphics.h:407`; lua 表 `NGraphics` · define `STRATEGIC_NAVY_COLOR_NEUTRAL_HIGHLIGHTED` |
| 0x140871810 | define 读取器; 源锚 `defines_graphics.h:408`; lua 表 `NGraphics` · define `STRATEGIC_NAVY_COLOR_ON_HOLD` |
| 0x140871A20 | define 读取器; 源锚 `defines_graphics.h:409`; lua 表 `NGraphics` · define `STRATEGIC_NAVY_COLOR_ON_HOLD_HIGHLIGHTED` |
| 0x140871C30 | define 读取器; 源锚 `defines_graphics.h:404`; lua 表 `NGraphics` · define `STRATEGIC_NAVY_NO_TASKFORCES_ASSIGNED` |
| 0x140871E40 | define 读取器; 源锚 `defines_graphics.h:410`; lua 表 `NGraphics` · define `STRATEGIC_REGION_COLOR_NAVAL_HEADQUARTER` |
| 0x140872260 | define 读取器; 源锚 `defines_graphics.h:348`; lua 表 `NGraphics` · define `SUN_DIFFUSE_COLOR` |
| 0x140872470 | define 读取器; 源锚 `defines_graphics.h:334`; lua 表 `NGraphics` · define `SUN_HEIGHT`; 存储助手 sub_142070980（float）; 全局槽 dword_1433374C0 |
| 0x140872890 | define 读取器; 源锚 `defines_graphics.h:349`; lua 表 `NGraphics` · define `SUN_INTENSITY`; 存储助手 sub_142070980（float）; 全局槽 dword_143337F88 |
| 0x140872AA0 | define 读取器; 源锚 `defines_graphics.h:335`; lua 表 `NGraphics` · define `SUN_LATITUDE`; 存储助手 sub_142070980（float）; 全局槽 dword_143337550 |
| 0x140872EC0 | define 读取器; 源锚 `defines_graphics.h:136`; lua 表 `NGraphics` · define `SUPPLYFLOW_SMOOTHEN_PASSES` |
| 0x1408732E0 | define 读取器; 源锚 `defines_graphics.h:621`; lua 表 `NGraphics` · define `SUPPLY_CAPITAL_COLOR` |
| 0x1408734F0 | define 读取器; 源锚 `defines_graphics.h:638`; lua 表 `NGraphics` · define `SUPPLY_CONSUMER_ARROW_HEIGHT_MAX`; 存储助手 sub_142070980（float）; 全局槽 dword_1433336F0 |
| 0x140873F40 | define 读取器; 源锚 `defines_graphics.h:628`; lua 表 `NGraphics` · define `SUPPLY_ICON_NUMBERS_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_143333138 |
| 0x140874360 | define 读取器; 源锚 `defines_graphics.h:633`; lua 表 `NGraphics` · define `SUPPLY_ICON_SHIFT`; 存储助手 sub_142071C30（dword 未细分）; 全局槽 dword_143333410 |
| 0x140874DB0 | define 读取器; 源锚 `defines_graphics.h:624`; lua 表 `NGraphics` · define `SUPPLY_SELECTED_NODE_COLOR` |
| 0x1408751D0 | define 读取器; 源锚 `defines_graphics.h:73`; lua 表 `NGraphics` · define `SUPPLY_TO_CONSUMERS_MAP_ARROW_TRANSPARENCY`; 存储助手 sub_142070980（float）; 全局槽 dword_143334888 |
| 0x1408753E0 | define 读取器; 源锚 `defines_graphics.h:641`; lua 表 `NGraphics` · define `SUPPLY_UNIT_COUNTER_LOW_THRESHOLD`; 存储助手 sub_142070980（float）; 全局槽 dword_143333878 |
| 0x1408755F0 | define 读取器; 源锚 `defines_graphics.h:640`; lua 表 `NGraphics` · define `SUPPLY_UNIT_COUNTER_SHOW_THRESHOLD`; 存储助手 sub_142070980（float）; 全局槽 dword_1433337B0 |
| 0x140875A10 | define 读取器; 源锚 `defines_graphics.h:612`; lua 表 `NGraphics` · define `TEMPERATURE_MAP_MODE_COLORS`; 存储助手 sub_142070C60（qword 未细分）; 全局槽 qword_143338F50 |
| 0x140876040 | define 读取器; 源锚 `defines_graphics.h:289`; lua 表 `NGraphics` · define `TOOLTIP_DELAYED_DELAY`; 存储助手 sub_142070980（float）; 全局槽 dword_143335C94 |
| 0x140876460 | define 读取器; 源锚 `defines_graphics.h:290`; lua 表 `NGraphics` · define `TOOLTIP_SHOW_DELAY`; 存储助手 sub_142070980（float）; 全局槽 dword_143335D20 |
| 0x140876880 | define 读取器; 源锚 `defines_graphics.h:133`; lua 表 `NGraphics` · define `TRADEROUTE_SMOOTHNESS`; 存储助手 sub_142072500（int64）; 全局槽 qword_143336CD8 |
| 0x140876A90 | define 读取器; 源锚 `defines_graphics.h:377`; lua 表 `NGraphics` · define `TRADE_ROUTE_BAD_EFFICIENCY_HOTSPOT_COLOR` |
| 0x140876CA0 | define 读取器; 源锚 `defines_graphics.h:376`; lua 表 `NGraphics` · define `TRADE_ROUTE_BAD_EFFICIENCY_ROUTE_COLOR` |
| 0x140876EB0 | define 读取器; 源锚 `defines_graphics.h:374`; lua 表 `NGraphics` · define `TRADE_ROUTE_BAD_EFFICIENCY_THRESHOLD`; 存储助手 sub_142072500（int64）; 全局槽 qword_143331990 |
| 0x1408770C0 | define 读取器; 源锚 `defines_graphics.h:366`; lua 表 `NGraphics` · define `TRADE_ROUTE_CONVOY_ROUTE_OFFSET`; 存储助手 sub_142070980（float）; 全局槽 dword_143331434 |
| 0x1408772D0 | define 读取器; 源锚 `defines_graphics.h:365`; lua 表 `NGraphics` · define `TRADE_ROUTE_CONVOY_SLEEP_TIME`; 存储助手 sub_142070980（float）; 全局槽 dword_1433313A8 |
| 0x1408774E0 | define 读取器; 源锚 `defines_graphics.h:364`; lua 表 `NGraphics` · define `TRADE_ROUTE_CONVOY_SPEED`; 存储助手 sub_142070980（float）; 全局槽 dword_143331308 |
| 0x1408776F0 | define 读取器; 源锚 `defines_graphics.h:384`; lua 表 `NGraphics` · define `TRADE_ROUTE_INTERNATIONAL_MARKET_COLOR` |
| 0x140877B10 | define 读取器; 源锚 `defines_graphics.h:382`; lua 表 `NGraphics` · define `TRADE_ROUTE_LEND_LEASE_EXPORT_COLOR` |
| 0x140878140 | define 读取器; 源锚 `defines_graphics.h:373`; lua 表 `NGraphics` · define `TRADE_ROUTE_MAX_LINES`; 存储助手 sub_142070630（bool/int8）; 全局槽 byte_1433318D8 |
| 0x140878560 | define 读取器; 源锚 `defines_graphics.h:362`; lua 表 `NGraphics` · define `TRADE_ROUTE_NUM_CONVOYS_SCALE_FACTOR`; 存储助手 sub_142070980（float）; 全局槽 dword_1433311C0 |
| 0x140878770 | define 读取器; 源锚 `defines_graphics.h:378`; lua 表 `NGraphics` · define `TRADE_ROUTE_PRODUCTION_TRANSFER_COLOR` |
| 0x140878980 | define 读取器; 源锚 `defines_graphics.h:375`; lua 表 `NGraphics` · define `TRADE_ROUTE_REGIONAL_BAD_EFFICIENCY_THRESHOLD`; 存储助手 sub_142072500（int64）; 全局槽 qword_143… |
| 0x140878B90 | define 读取器; 源锚 `defines_graphics.h:380`; lua 表 `NGraphics` · define `TRADE_ROUTE_RESOURCE_EXPORT_COLOR` |
| 0x140878FB0 | define 读取器; 源锚 `defines_graphics.h:379`; lua 表 `NGraphics` · define `TRADE_ROUTE_SUPPLIES_TRANSFER_COLOR` |
| 0x1408795E0 | define 读取器; 源锚 `defines_graphics.h:390`; lua 表 `NGraphics` · define `TRAIT_GRID_COLUMN_WIDTH`; 存储助手 sub_142070630（int32）; 全局槽 dword_1433323C4 |
| 0x1408798A0 | define 读取器; 源锚 `defines_graphics.h:391`; lua 表 `NGraphics` · define `TRAIT_GRID_ROW_SHIFT` |
| 0x140879AB0 | define 读取器; 源锚 `defines_graphics.h:396`; lua 表 `NGraphics` · define `TRAIT_INVALID_FOR_ASSIGNMENT_COLOR` |
| 0x140879CC0 | define 读取器; 源锚 `defines_graphics.h:393`; lua 表 `NGraphics` · define `TRAIT_LINE_ASSIGNED_COLOR`; 存储助手 sub_142071C30（dword 未细分）; 全局槽 dword_143332530 |
| 0x14087A2F0 | define 读取器; 源锚 `defines_graphics.h:360`; lua 表 `NGraphics` · define `TREE_FADE_FAR`; 存储助手 sub_142070980（float）; 全局槽 dword_143331118 |
| 0x14087A920 | define 读取器; 源锚 `defines_graphics.h:254`; lua 表 `NGraphics` · define `UNITS_DISTANCE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_14333479C |
| 0x14087B160 | define 读取器; 源锚 `defines_graphics.h:238`; lua 表 `NGraphics` · define `VICTORY_POINT_LEVELS`; 存储助手 sub_142070630（int32）; 全局槽 dword_143333DA0 |
| 0x14087B580 | define 读取器; 源锚 `defines_graphics.h:245`; lua 表 `NGraphics` · define `VICTORY_POINT_MAP_ICON_CAPITAL_CUTOFF_MAX`; 存储助手 sub_142070980（float）; 全局槽 dword_143334218 |
| 0x14087B790 | define 读取器; 源锚 `defines_graphics.h:243`; lua 表 `NGraphics` · define `VICTORY_POINT_MAP_ICON_DOT_CUTOFF_MAX`; 存储助手 sub_142070980（float）; 全局槽 dword_1433340C4 |
| 0x14087B9A0 | define 读取器; 源锚 `defines_graphics.h:242`; lua 表 `NGraphics` · define `VICTORY_POINT_MAP_ICON_DOT_CUTOFF_MIN`; 存储助手 sub_142070980（float）; 全局槽 dword_14333403C |
| 0x14087BBB0 | define 读取器; 源锚 `defines_graphics.h:244`; lua 表 `NGraphics` · define `VICTORY_POINT_MAP_ICON_MAX_VICTORY_POINTS_FOR_PERCENT`; 存储助手 sub_142070980（float）; 全局槽 d… |
| 0x14087BFD0 | define 读取器; 源锚 `defines_graphics.h:240`; lua 表 `NGraphics` · define `VICTORY_POINT_MAP_ICON_TEXT_CUTOFF_MIN`; 存储助手 sub_142070980（float）; 全局槽 dword_143333EF0 |
| 0x14087C600 | define 读取器; 源锚 `defines_graphics.h:293`; lua 表 `NGraphics` · define `WEATHER_DISTANCE_FADE_LENGTH`; 存储助手 sub_142070980（float）; 全局槽 dword_143335EE8 |
| 0x14087CA20 | define 读取器; 源锚 `defines_graphics.h:298`; lua 表 `NGraphics` · define `WEATHER_PLAYBACK_RATE_CUTOFF`; 存储助手 sub_142070980（float）; 全局槽 dword_1433361C0 |
| 0x14087D050 | define 读取器; 源锚 `defines_graphics.h:296`; lua 表 `NGraphics` · define `WEATHER_ZOOM_IN_FADE_FACTOR`; 存储助手 sub_142070980（float）; 全局槽 dword_143336094 |
| 0x1408EBF80 | define 读取器; 源锚 `defines_graphics.h:427`; lua 表 `NMapIcons` · define `TOP_MAP_ICON`; 存储助手 sub_142070630（int32）; 全局槽 dword_143333698 |
| 0x14087D470 | define 读取器; 源锚 `defines_industrial_organisation.h:3`; lua 表 `NIndustrialOrganisation` · define `ASSIGN_DESIGN_TEAM_PP_COST_PER_DAY`; 存储助手 sub_142072500（int64… |
| 0x14087D680 | define 读取器; 源锚 `defines_industrial_organisation.h:4`; lua 表 `NIndustrialOrganisation` · define `ASSIGN_INDUSTRIAL_MANUFACTURER_PP_COST_PER_DAY`; 存储助手 sub_142… |
| 0x14087D890 | define 读取器; 源锚 `defines_industrial_organisation.h:18`; lua 表 `NIndustrialOrganisation` · define `DEFAULT_INITIAL_ATTACH_POLICY_COOLDOWN`; 存储助手 sub_142070630（… |
| 0x14087E390 | define 读取器; 源锚 `defines_industrial_organisation.h:14`; lua 表 `NIndustrialOrganisation` · define `DESIGN_TEAM_RESEARCH_BONUS`; 存储助手 sub_142072500（int64）; 全局槽 … |
| 0x14087F830 | define 读取器; 源锚 `defines_industrial_organisation.h:19`; lua 表 `NIndustrialOrganisation` · define `LEGACY_COST_FACTOR_SCALE`; 存储助手 sub_142072500（int64）; 全局槽 qw… |
| 0x1407D1CE0 | defines 读取器；`source\defines_military.h:510`；lua 表 `NAir` 键 `ACCIDENT_CHANCE_RELIABILITY_MULT`；sink `sub_142072500`；define 槽 `qword_143336630` |
| 0x1407D1EF0 | defines 读取器；`source\defines_military.h:511`；lua 表 `NAir` 键 `ACCIDENT_EFFECT_MULT`；sink `sub_142072500`；define 槽 `qword_1433366D8` |
| 0x1407D2100 | defines 读取器；`source\defines_military.h:514`；lua 表 `NAir` 键 `ACE_DEATH_BY_OTHER_ACE_CHANCE`；sink `sub_142072500`；define 槽 `qword_1433368A8` |
| 0x1407D2730 | defines 读取器；`source\defines_military.h:515`；lua 表 `NAir` 键 `ACE_EARN_CHANCE_BASE`；sink `sub_142072500`；define 槽 `qword_143336938` |
| 0x1407D2940 | defines 读取器；`source\defines_military.h:516`；lua 表 `NAir` 键 `ACE_EARN_CHANCE_PLANES_MULT`；sink `sub_142072500`；define 槽 `qword_1433369B8` |
| 0x1407D2B50 | defines 读取器；`source\defines_military.h:535`；lua 表 `NAir` 键 `ACE_WING_SIZE`；sink `sub_142072500`；define 槽 `qword_1433375D0` |
| 0x1407D2D60 | defines 读取器；`source\defines_military.h:536`；lua 表 `NAir` 键 `ACE_WING_SIZE_MAX_BONUS`；sink `sub_142072500`；define 槽 `qword_143337678` |
| 0x1407D2F70 | defines 读取器；`source\defines_military.h:534`；lua 表 `NAir` 键 `AGGRESSION_THRESHOLD`；sink `sub_142071190`；define 槽 `qword_143339728` |
| 0x1407D3180 | defines 读取器；`source\defines_military.h:517`；lua 表 `NAir` 键 `AIR_AGILITY_TO_NAVAL_STRIKE_AGILITY`；sink `sub_142072500`；define 槽 `qword_143336A50` |
| 0x1407D39C0 | defines 读取器；`source\defines_military.h:471`；lua 表 `NAir` 键 `AIR_DAMAGE_TO_DIVISION_LOSSES`；sink `sub_142072500`；define 槽 `qword_143334CB0` |
| 0x1407D3BD0 | defines 读取器；`source\defines_military.h:599`；lua 表 `NAir` 键 `AIR_DEPLOYMENT_DAYS`；sink `sub_142072500`；define 槽 `qword_143332708` |
| 0x1407D3DE0 | defines 读取器；`source\defines_military.h:639`；lua 表 `NAir` 键 `AIR_INVASION_PLAN_CAP`；sink `sub_142070630`；define 槽 `dword_143333F70` |
| 0x1407D4200 | defines 读取器；`source\defines_military.h:545`；lua 表 `NAir` 键 `AIR_MORE_GROUND_CREWS_BOOST`；sink `sub_142072500`；define 槽 `qword_143337CC0` |
| 0x1407D4A40 | defines 读取器；`source\defines_military.h:533`；lua 表 `NAir` 键 `AIR_REGION_SUPERIORITY_PIXEL_SCALE`；sink `sub_142072200`；define 槽 `qword_1433374A8` |
| 0x1407D4C50 | defines 读取器；`source\defines_military.h:447`；lua 表 `NAir` 键 `AIR_WING_ATTACK_LOGISTICS_INFRA_DAMAGE_SPILL_FACTOR`；sink `sub_142072500`；define 槽 `qword_143333F00` |
| 0x1407D4E60 | defines 读取器；`source\defines_military.h:445`；lua 表 `NAir` 键 `AIR_WING_ATTACK_LOGISTICS_NO_TRUCK_DISRUPTION_FACTOR`；sink `sub_142072500`；define 槽 `qword_143333… |
| 0x1407D5070 | defines 读取器；`source\defines_military.h:451`；lua 表 `NAir` 键 `AIR_WING_ATTACK_LOGISTICS_RAILWAY_DAMAGE_SPILL_FACTOR`；sink `sub_142072500`；define 槽 `qword_14333… |
| 0x1407D5800 | defines 读取器；`source\defines_military.h:448`；lua 表 `NAir` 键 `AIR_WING_ATTACK_LOGISTICS_TRAIN_DAMAGE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143333FA0` |
| 0x1407D5A10 | defines 读取器；`source\defines_military.h:446`；lua 表 `NAir` 键 `AIR_WING_ATTACK_LOGISTICS_TRUCK_DAMAGE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143333E70` |
| 0x1407D5C20 | defines 读取器；`source\defines_military.h:452`；lua 表 `NAir` 键 `AIR_WING_ATTACK_LOGISTICS_TRUCK_MAX_FACTOR`；sink `sub_142072500`；define 槽 `qword_143334288` |
| 0x1407D6040 | defines 读取器；`source\defines_military.h:470`；lua 表 `NAir` 键 `AIR_WING_BOMB_DAMAGE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143334C08` |
| 0x1407D6250 | defines 读取器；`source\defines_military.h:615`；lua 表 `NAir` 键 `AIR_WING_COUNTRY_XP_FROM_TRAINING_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433330C8` |
| 0x1407D6460 | defines 读取器；`source\defines_military.h:462`；lua 表 `NAir` 键 `AIR_WING_FLIGHT_SPEED_MULT`；sink `sub_142072500`；define 槽 `qword_1433346D0` |
| 0x1407D6670 | defines 读取器；`source\defines_military.h:468`；lua 表 `NAir` 键 `AIR_WING_MAX_SIZE`；sink `sub_142070630`；define 槽 `dword_143334AAC` |
| 0x1407D6880 | defines 读取器；`source\defines_military.h:465`；lua 表 `NAir` 键 `AIR_WING_MAX_STATS_AGILITY`；sink `sub_142072500`；define 槽 `qword_1433348C8` |
| 0x1407D6CA0 | defines 读取器；`source\defines_military.h:466`；lua 表 `NAir` 键 `AIR_WING_MAX_STATS_BOMBING`；sink `sub_142072500`；define 槽 `unk_143334960` |
| 0x1407D72D0 | defines 读取器；`source\defines_military.h:573`；lua 表 `NAir` 键 `AIR_WING_XP_AIR_VS_AIR_COMBAT_GAIN`；sink `sub_142072500`；define 槽 `qword_143331770` |
| 0x1407D74E0 | defines 读取器；`source\defines_military.h:571`；lua 表 `NAir` 键 `AIR_WING_XP_GROUND_MISSION_COMPLETED_GAIN`；sink `sub_142072500`；define 槽 `qword_143331608` |
| 0x1407D76F0 | defines 读取器；`source\defines_military.h:574`；lua 表 `NAir` 键 `AIR_WING_XP_LEVELS`；sink `sub_142071190`；define 槽 `qword_143339740` |
| 0x1407D7C50 | defines 读取器；`source\defines_military.h:566`；lua 表 `NAir` 键 `AIR_WING_XP_LOSS_WHEN_KILLED`；sink `sub_142072500`；define 槽 `qword_143331250` |
| 0x1407D7E60 | defines 读取器；`source\defines_military.h:565`；lua 表 `NAir` 键 `AIR_WING_XP_MAX`；sink `sub_142072500`；define 槽 `qword_1433311B0` |
| 0x1407D86A0 | defines 读取器；`source\defines_military.h:568`；lua 表 `NAir` 键 `AIR_WING_XP_TRAINING_MISSION_GAIN_DAILY`；sink `sub_142072500`；define 槽 `qword_1433313A0` |
| 0x1407D88B0 | defines 读取器；`source\defines_military.h:636`；lua 表 `NAir` 键 `AI_ALLOWED_PLANES_KEPT_IN_RESERVE`；sink `sub_142072500`；define 槽 `qword_143333DD0` |
| 0x1407D8C00 | defines 读取器；`source\defines_military.h:597`；lua 表 `NAir` 键 `ANTI_AIR_ATTACK_TO_DAMAGE_REDUCTION_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332588` |
| 0x1407D8E10 | defines 读取器；`source\defines_military.h:598`；lua 表 `NAir` 键 `ANTI_AIR_MAXIMUM_DAMAGE_REDUCTION_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332650` |
| 0x1407D9020 | defines 读取器；`source\defines_military.h:596`；lua 表 `NAir` 键 `ANTI_AIR_PLANE_DAMAGE_CHANCE`；sink `sub_142072500`；define 槽 `qword_1433324E8` |
| 0x1407D9440 | defines 读取器；`source\defines_military.h:520`；lua 表 `NAir` 键 `BASE_AIR_INVASION_DIVISION_CAP`；sink `sub_142070630`；define 槽 `dword_143336C38` |
| 0x1407D9700 | defines 读取器；`source\defines_military.h:521`；lua 表 `NAir` 键 `BASE_KAMIKAZE_DAMAGE`；sink `sub_142072500`；define 槽 `qword_143336D18` |
| 0x1407D9D30 | defines 读取器；`source\defines_military.h:529`；lua 表 `NAir` 键 `BASE_STRATEGIC_BOMBING_HIT_PLANE_DAMAGE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143337270` |
| 0x1407D9F40 | defines 读取器；`source\defines_military.h:526`；lua 表 `NAir` 键 `BASE_STRATEGIC_BOMBING_HIT_SHIP_CHANCE`；sink `sub_142072500`；define 槽 `qword_143337038` |
| 0x1407DA150 | defines 读取器；`source\defines_military.h:527`；lua 表 `NAir` 键 `BASE_STRATEGIC_BOMBING_HIT_SHIP_DAMAGE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143337110` |
| 0x1407DA360 | defines 读取器；`source\defines_military.h:548`；lua 表 `NAir` 键 `BASE_UNIT_WEIGHT_IN_TRANSPORT_PLANES`；sink `sub_142072500`；define 槽 `qword_143337E68` |
| 0x1407DAD00 | defines 读取器；`source\defines_military.h:540`；lua 表 `NAir` 键 `CAPACITY_PENALTY`；sink `sub_142072500`；define 槽 `qword_143337958` |
| 0x1407DAF10 | defines 读取器；`source\defines_military.h:478`；lua 表 `NAir` 键 `CARRIER_COMBAT_DAMAGE_STATS_MULTIPLIER`；sink `sub_142072500`；define 槽 `qword_143335108` |
| 0x1407DB1D0 | defines 读取器；`source\defines_military.h:496`；lua 表 `NAir` 键 `CARRIER_HOURS_DELAY_AFTER_EACH_COMBAT`；sink `sub_142070630`；define 槽 `dword_143335D60` |
| 0x1407DB5F0 | defines 读取器；`source\defines_military.h:606`；lua 表 `NAir` 键 `CARRIER_PLANES_AMOUNT_FOR_POSITIONING`；sink `sub_142072500`；define 槽 `qword_143332B60` |
| 0x1407DB800 | defines 读取器；`source\defines_military.h:497`；lua 表 `NAir` 键 `CARRIER_SIZE_STAT_INCREMENT`；sink `sub_142070630`；define 槽 `dword_143335DF0` |
| 0x1407DBAC0 | defines 读取器；`source\defines_military.h:604`；lua 表 `NAir` 键 `CAS_NIGHT_ATTACK_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332AA8` |
| 0x1407DBCD0 | defines 读取器；`source\defines_military.h:523`；lua 表 `NAir` 键 `CLOSE_AIR_SUPPORT_EXPERIENCE_SCALE`；sink `sub_142072500`；define 槽 `qword_143336E68` |
| 0x1407DBEE0 | defines 读取器；`source\defines_military.h:479`；lua 表 `NAir` 键 `COMBAT_BETTER_AGILITY_DAMAGE_REDUCTION`；sink `sub_142072500`；define 槽 `qword_1433351C8` |
| 0x1407DCCA0 | defines 读取器；`source\defines_military.h:532`；lua 表 `NAir` 键 `COMBAT_MAX_WINGS_AT_GROUND_ATTACK`；sink `sub_142070630`；define 槽 `unk_143337400` |
| 0x1407DD2D0 | defines 读取器；`source\defines_military.h:481`；lua 表 `NAir` 键 `COMBAT_MULTIPLANE_CAP`；sink `sub_142072500`；define 槽 `qword_143335380` |
| 0x1407DD7A0 | defines 读取器；`source\defines_military.h:488`；lua 表 `NAir` 键 `DETECT_CHANCE_FROM_AIRCRAFTS`；sink `sub_142072500`；define 槽 `qword_143335848` |
| 0x1407DD9B0 | defines 读取器；`source\defines_military.h:487`；lua 表 `NAir` 键 `DETECT_CHANCE_FROM_AIRCRAFTS_EFFECTIVE_COUNT`；sink `sub_142070630`；define 槽 `dword_1433357A0` |
| 0x1407DDBC0 | defines 读取器；`source\defines_military.h:489`；lua 表 `NAir` 键 `DETECT_CHANCE_FROM_NIGHT`；sink `sub_142072500`；define 槽 `qword_1433358E8` |
| 0x1407DDFE0 | defines 读取器；`source\defines_military.h:486`；lua 表 `NAir` 键 `DETECT_CHANCE_FROM_RADARS`；sink `sub_142072500`；define 槽 `qword_143335720` |
| 0x1407DEC40 | defines 读取器；`source\defines_military.h:589`；lua 表 `NAir` 键 `DISRUPTION_DEFENCE_ATTACK_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332138` |
| 0x1407DF060 | defines 读取器；`source\defines_military.h:588`；lua 表 `NAir` 键 `DISRUPTION_DEFENCE_SPEED_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332098` |
| 0x1407DF480 | defines 读取器；`source\defines_military.h:577`；lua 表 `NAir` 键 `DISRUPTION_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433318F0` |
| 0x1407DFAB0 | defines 读取器；`source\defines_military.h:558`；lua 表 `NAir` 键 `EFFICIENCY_REGION_CHANGE_DAILY_GAIN_CAS`；sink `sub_142072500`；define 槽 `qword_143338400` |
| 0x1407DFCC0 | defines 读取器；`source\defines_military.h:557`；lua 表 `NAir` 键 `EFFICIENCY_REGION_CHANGE_DAILY_GAIN_DEFAULT`；sink `sub_142072500`；define 槽 `qword_143338368` |
| 0x1407DFED0 | defines 读取器；`source\defines_military.h:561`；lua 表 `NAir` 键 `EFFICIENCY_REGION_CHANGE_DAILY_GAIN_FIGHTER`；sink `sub_142072500`；define 槽 `qword_143330FB8` |
| 0x1407E00E0 | defines 读取器；`source\defines_military.h:563`；lua 表 `NAir` 键 `EFFICIENCY_REGION_CHANGE_DAILY_GAIN_MARITIME_PATROL_PLANE`；sink `sub_142072500`；define 槽 `qword_1… |
| 0x1407E02F0 | defines 读取器；`source\defines_military.h:559`；lua 表 `NAir` 键 `EFFICIENCY_REGION_CHANGE_DAILY_GAIN_NAVAL_BOMBER`；sink `sub_142072500`；define 槽 `qword_143330E88` |
| 0x1407E0710 | defines 读取器；`source\defines_military.h:560`；lua 表 `NAir` 键 `EFFICIENCY_REGION_CHANGE_DAILY_GAIN_TACTICAL_BOMBER`；sink `sub_142072500`；define 槽 `qword_143330F28` |
| 0x1407E0D40 | defines 读取器；`source\defines_military.h:586`；lua 表 `NAir` 键 `ESCORT_ATTACK_FACTOR`；sink `sub_142072500`；define 槽 `qword_143331F30` |
| 0x1407E0F50 | defines 读取器；`source\defines_military.h:583`；lua 表 `NAir` 键 `ESCORT_FACTOR`；sink `sub_142072500`；define 槽 `qword_143331D00` |
| 0x1407E1370 | defines 读取器；`source\defines_military.h:554`；lua 表 `NAir` 键 `EXPERIENCE_SCALE_ATTACK_LOGISTICS_NODE_AND_TRAINS`；sink `sub_142072500`；define 槽 `qword_143338210` |
| 0x1407E1790 | defines 读取器；`source\defines_military.h:553`；lua 表 `NAir` 键 `EXPERIENCE_SCALE_ATTACK_LOGISTICS_TRUCKS`；sink `sub_142072500`；define 槽 `qword_143338158` |
| 0x1407E1DC0 | defines 读取器；`source\defines_military.h:505`；lua 表 `NAir` 键 `FIELD_EXPERIENCE_SCALE`；sink `sub_142072500`；define 槽 `qword_143336350` |
| 0x1407E1FD0 | defines 读取器；`source\defines_military.h:613`；lua 表 `NAir` 键 `FUEL_COST_MULT`；sink `sub_142072500`；define 槽 `qword_143332F60` |
| 0x1407E7300 | defines 读取器；`source\defines_military.h:494`；lua 表 `NAir` 键 `HOURS_DELAY_AFTER_EACH_COMBAT`；sink `sub_142070630`；define 槽 `dword_143335BF0` |
| 0x1407E7910 | defines 读取器；`source\defines_military.h:459`；lua 表 `NAir` 键 `INTERCEPTION_DISTANCE_SCALE`；sink `sub_142070630`；define 槽 `dword_143334504` |
| 0x1407E7BD0 | defines 读取器；`source\defines_military.h:594`；lua 表 `NAir` 键 `LEND_LEASED_EQUIPMENT_EXPERIENCE_GAIN`；sink `sub_142072500`；define 槽 `qword_1433323A8` |
| 0x1407E8130 | defines 读取器；`source\defines_military.h:608`；lua 表 `NAir` 键 `MAX_FUEL_FLOW_MULT`；sink `sub_142072500`；define 槽 `qword_143332C18` |
| 0x1407E8600 | defines 读取器；`source\defines_military.h:610`；lua 表 `NAir` 键 `MIN_PLANE_COUNT_AIR_SUPPLY`；sink `sub_142070630`；define 槽 `dword_143332D68` |
| 0x1407E8CE0 | defines 读取器；`source\defines_military.h:499`；lua 表 `NAir` 键 `MISSILE_LAUNCHER_SLOTS`；sink `sub_142070630`；define 槽 `dword_143335F58` |
| 0x1407E8FA0 | defines 读取器；`source\defines_military.h:611`；lua 表 `NAir` 键 `MISSION_COMMAND_POWER_COSTS`；sink `sub_142071190`；define 槽 `qword_143339758` |
| 0x1407E91B0 | defines 读取器；`source\defines_military.h:614`；lua 表 `NAir` 键 `MISSION_EFFICIENCY_MULT_AT_LACK_OF_FUEL`；sink `sub_142072500`；define 槽 `qword_143333008` |
| 0x1407E95D0 | defines 读取器；`source\defines_military.h:601`；lua 表 `NAir` 键 `NAVAL_COMBAT_EXTERNAL_PLANES_JOIN_RATIO`；sink `sub_142072500`；define 槽 `qword_143332888` |
| 0x1407E97E0 | defines 读取器；`source\defines_military.h:602`；lua 表 `NAir` 键 `NAVAL_COMBAT_EXTERNAL_PLANES_JOIN_RATIO_PER_DAY`；sink `sub_142072500`；define 槽 `qword_143332948` |
| 0x1407E99F0 | defines 读取器；`source\defines_military.h:603`；lua 表 `NAir` 键 `NAVAL_COMBAT_EXTERNAL_PLANES_MIN_CAP`；sink `sub_142070630`；define 槽 `dword_1433329D8` |
| 0x1407E9EC0 | defines 读取器；`source\defines_military.h:622`；lua 表 `NAir` 键 `NAVAL_MINES_PLANTING_SPEED_MULT`；sink `sub_142072500`；define 槽 `qword_1433335A8` |
| 0x1407EA7B0 | defines 读取器；`source\defines_military.h:600`；lua 表 `NAir` 键 `NAVAL_STRIKE_BASE_STR_TO_PLANES_RATIO`；sink `sub_142072500`；define 槽 `qword_1433327C0` |
| 0x1407EA9C0 | defines 读取器；`source\defines_military.h:504`；lua 表 `NAir` 键 `NAVAL_STRIKE_CARRIER_MULTIPLIER`；sink `sub_142072500`；define 槽 `qword_1433362B8` |
| 0x1407EADE0 | defines 读取器；`source\defines_military.h:502`；lua 表 `NAir` 键 `NAVAL_STRIKE_DAMAGE_TO_STR`；sink `sub_142072500`；define 槽 `qword_143336190` |
| 0x1407EAFF0 | defines 读取器；`source\defines_military.h:592`；lua 表 `NAir` 键 `NAVAL_STRIKE_DETECTION_BALANCE_FACTOR`；sink `sub_142072500`；define 槽 `qword_143332270` |
| 0x1407EB200 | defines 读取器；`source\defines_military.h:501`；lua 表 `NAir` 键 `NAVAL_STRIKE_TARGETTING_TO_AMOUNT`；sink `sub_142072500`；define 槽 `qword_1433360F8` |
| 0x1407EBA40 | defines 读取器；`source\defines_military.h:495`；lua 表 `NAir` 键 `PORT_STRIKES_DELAY_MULTIPLIER`；sink `sub_142070630`；define 槽 `unk_143335CC0` |
| 0x1407EC120 | defines 读取器；`source\defines_military.h:629`；lua 表 `NAir` 键 `REINFORCEMENT_DISABLING_DURATION_IN_LAND_CARRIER_TRANSFER`；sink `sub_142070630`；define 槽 `dword_1… |
| 0x1407EC3E0 | defines 读取器；`source\defines_military.h:454`；lua 表 `NAir` 键 `SECONDARY_DAMAGE_LOGISTICS`；sink `sub_142072500`；define 槽 `qword_143334320` |
| 0x1407EC800 | defines 读取器；`source\defines_military.h:619`；lua 表 `NAir` 键 `STRATEGIC_BOMBING_INFRA_PRIO_SCALE`；sink `sub_142072500`；define 槽 `qword_1433332C8` |
| 0x1407ECA10 | defines 读取器；`source\defines_military.h:617`；lua 表 `NAir` 键 `STRATEGIC_BOMBING_PROV_BUILD_PRIO_SCALE`；sink `sub_142072500`；define 槽 `qword_143333178` |
| 0x1407ED3B0 | defines 读取器；`source\defines_military.h:498`；lua 表 `NAir` 键 `SUBMARINE_CARRIER_SIZE_STAT_INCREMENT`；sink `sub_142070630`；define 槽 `dword_143335EC8` |
| 0x1407ED670 | defines 读取器；`source\defines_military.h:538`；lua 表 `NAir` 键 `SUPPLY_NEED_FACTOR`；sink `sub_142072500`；define 槽 `qword_1433377D8` |
| 0x1407EDCA0 | defines 读取器；`source\defines_military.h:476`；lua 表 `NAir` 键 `TOP_SPEED_DAMAGE_BONUS_FACTOR`；sink `sub_142072500`；define 槽 `qword_143334F20` |
| 0x1407EDF60 | defines 读取器；`source\defines_military.h:634`；lua 表 `NAir` 键 `USE_SINGLE_NAVAL_ARMAMENT_CATEGORY`；sink `sub_142072840`；define 槽 `byte_143330EBF` |
| 0x1407F0AB0 | defines 读取器；`source\defines_career_profile.h:22`；lua 表 `NCareerProfile` 键 `BLITZ_THIS_TACTIC_NAME`；sink `sub_142072800`；define 槽 `qword_1430891D0` |
| 0x1407F0CC0 | defines 读取器；`source\defines_career_profile.h:26`；lua 表 `NCareerProfile` 键 `CASTLES_IN_THE_AIR_MEDAL_AIR_DEFENSE_BRONZE`；sink `sub_142070630`；define 槽 `dword_… |
| 0x1407F0ED0 | defines 读取器；`source\defines_career_profile.h:28`；lua 表 `NCareerProfile` 键 `CASTLES_IN_THE_AIR_MEDAL_AIR_DEFENSE_GOLD`；sink `sub_142070630`；define 槽 `dword_14… |
| 0x1407F10E0 | defines 读取器；`source\defines_career_profile.h:27`；lua 表 `NCareerProfile` 键 `CASTLES_IN_THE_AIR_MEDAL_AIR_DEFENSE_SILVER`；sink `sub_142070630`；define 槽 `dword_… |
| 0x1407F12F0 | defines 读取器；`source\defines_career_profile.h:23`；lua 表 `NCareerProfile` 键 `ENGINEERING_BEHEMOTH_MEDAL_ARMOR_RATING_BRONZE`；sink `sub_142070630`；define 槽 `dwo… |
| 0x1407F1500 | defines 读取器；`source\defines_career_profile.h:25`；lua 表 `NCareerProfile` 键 `ENGINEERING_BEHEMOTH_MEDAL_ARMOR_RATING_GOLD`；sink `sub_142070630`；define 槽 `dword… |
| 0x1407F1710 | defines 读取器；`source\defines_career_profile.h:24`；lua 表 `NCareerProfile` 键 `ENGINEERING_BEHEMOTH_MEDAL_ARMOR_RATING_SILVER`；sink `sub_142070630`；define 槽 `dwo… |
| 0x1407F2790 | defines 读取器；`source\defines_career_profile.h:16`；lua 表 `NCareerProfile` 键 `NAVAL_INVASION_MEDAL_DIVISION_MIN_BATTALION_COUNT`；sink `sub_142070630`；define 槽 `… |
| 0x1407F29A0 | defines 读取器；`source\defines_career_profile.h:14`；lua 表 `NCareerProfile` 键 `NAVAL_INVASION_MEDAL_MAX_DURATION`；sink `sub_142070630`；define 槽 `dword_143337730` |
| 0x1407F2BB0 | defines 读取器；`source\defines_career_profile.h:20`；lua 表 `NCareerProfile` 键 `NEVERMINE_ME_MEDAL_MIN_RATIO`；sink `sub_142072500`；define 槽 `qword_143337B60` |
| 0x1407F2DC0 | defines 读取器；`source\defines_career_profile.h:19`；lua 表 `NCareerProfile` 键 `ORCHESTRA_OF_BOOM_RIBBON_SPECIAL_BATTALION_COUNT`；sink `sub_142070630`；define 槽 `d… |
| 0x1407F2FD0 | defines 读取器；`source\defines_career_profile.h:15`；lua 表 `NCareerProfile` 键 `PARADROP_AWARD_DIVISION_MIN_BATTALION_COUNT`；sink `sub_142070630`；define 槽 `dword_… |
| 0x1407F31E0 | defines 读取器；`source\defines_career_profile.h:18`；lua 表 `NCareerProfile` 键 `STEEL_AT_HIGH_SPEED_RIBBON_TANK_SPEED`；sink `sub_142072500`；define 槽 `qword_143337… |
| 0x1407F33F0 | defines 读取器；`source\defines_career_profile.h:17`；lua 表 `NCareerProfile` 键 `TURNING_TIDE_MEDAL_DIVISION_MIN_BATTALION_COUNT`；sink `sub_142070630`；define 槽 `dw… |
| 0x14083E450 | defines 读取器；`source\defines_game.h:21`；lua 表 `NGame` 键 `AIR_LOG_TIMEOUT_HOURS`；sink `sub_142070630`；define 槽 `dword_143336678` |
| 0x14083E660 | defines 读取器；`source\defines_game.h:32`；lua 表 `NGame` 键 `ALERT_SFX_COOLDOWN_DAYS`；sink `sub_142070630`；define 槽 `dword_143336E00` |
| 0x14083E870 | defines 读取器；`source\defines_game.h:13`；lua 表 `NGame` 键 `CHECKSUM_SALT`；sink `sub_142072800`；define 槽 `qword_143089B28` |
| 0x14083EEA0 | defines 读取器；`source\defines_game.h:9`；lua 表 `NGame` 键 `END_DATE`；sink `sub_14074BA30`；define 槽 `off_143089AF0` |
| 0x14083F0B0 | defines 读取器；`source\defines_game.h:29`；lua 表 `NGame` 键 `ENERGY_RESOURCE`；sink `sub_142072800`；define 槽 `qword_143089C08` |
| 0x14083F4D0 | defines 读取器；`source\defines_game.h:28`；lua 表 `NGame` 键 `FUEL_RESOURCE`；sink `sub_142072800`；define 槽 `qword_143089BE0` |
| 0x14083FB10 | defines 读取器；`source\defines_game.h:31`；lua 表 `NGame` 键 `HANDS_OFF_START_TAG`；sink `sub_142072800`；define 槽 `qword_143089C38` |
| 0x140840610 | defines 读取器；`source\defines_game.h:10`；lua 表 `NGame` 键 `MAP_SCALE_PIXEL_TO_KM`；sink `sub_142072500`；define 槽 `qword_143335F50` |
| 0x140840820 | defines 读取器；`source\defines_game.h:25`；lua 表 `NGame` 键 `MAX_EFFECT_ITERATION`；sink `sub_142070630`；define 槽 `dword_1433368E0` |
| 0x140840C40 | defines 读取器；`source\defines_game.h:19`；lua 表 `NGame` 键 `MESSAGE_TIMEOUT_DAYS`；sink `sub_142070630`；define 槽 `dword_1433364F4` |
| 0x140840E50 | defines 读取器；`source\defines_game.h:12`；lua 表 `NGame` 键 `MINOR_SAVE_VERSION`；sink `sub_142070630`；define 槽 `dword_143336080` |
| 0x140841060 | defines 读取器；`source\defines_game.h:23`；lua 表 `NGame` 键 `MISSION_REMOVE_FROM_INTERFACE_DEFAULT`；sink `sub_142070630`；define 槽 `dword_1433367C8` |
| 0x140841740 | defines 读取器；`source\defines_game.h:11`；lua 表 `NGame` 键 `SAVE_VERSION`；sink `sub_142070630`；define 槽 `dword_143335FEC` |
| 0x140841950 | defines 读取器；`source\defines_game.h:8`；lua 表 `NGame` 键 `START_DATE`；sink `sub_14074BA30`；define 槽 `off_143089AD0` |

#### 4.26.60 静态资源访问层define 注册 functor 族（1 函）

| VA | 语义/证据 |
|---|---|
| 0x140753F80..0x1409A2580 | NDefines::CDefineRegistryHelper 读取器族（702 个模板实例, 逐 define 从 Lua 表读值; 逐 VA 见 findings/cov_full/_book_inbook.tsv） |

#### 4.26.61 静态资源访问层函数补遗（585 函）

| VA | 语义/证据 |
|---|---|
| 0x140908B80 | defines 读取器 defines_military.h 表 NMilitary 键 ENEMY_AIR_SUPERIORITY_DEFENSE |
| 0x140908D90 | defines 读取器 defines_military.h 表 NMilitary 键 ENEMY_AIR_SUPERIORITY_DEFENSE_STEEPNESS |
| 0x140909EC0 | defines 读取器 defines_military.h 表 NMilitary 键 EXILE_ORG |
| 0x14090A0D0 | defines 读取器 defines_military.h 表 NMilitary 键 EXPEDITIONARY_FIELD_EXPERIENCE_SCALE |
| 0x14090A4F0 | defines 读取器 defines_military.h 表 NMilitary 键 EXPERIENCE_LOSS_FACTOR |
| 0x14090AF40 | defines 读取器 defines_military.h 表 NMilitary 键 FIELD_EXPERIENCE_ON_DIVISION_PER_MEDAL_MULT |
| 0x14090B150 | defines 读取器 defines_military.h 表 NMilitary 键 FIELD_EXPERIENCE_SCALE |
| 0x14090B570 | defines 读取器 defines_military.h 表 NMilitary 键 FIELD_MARSHAL_ARMY_BONUS_RATIO |
| 0x14090BDB0 | defines 读取器 defines_military.h 表 NMilitary 键 FIELD_OFFICER_PROMOTION_PENALTY |
| 0x14090C280 | defines 读取器 defines_military.h 表 NMilitary 键 FIGHTING_STRENGTH_HQ_ALERT_THRESHOLD |
| 0x14090C750 | defines 读取器 defines_military.h 表 NMilitary 键 FRONTLINE_EXPANSION_FACTOR |
| 0x14090CAA0 | defines 读取器 defines_military.h 表 NMilitary 键 FRONT_MIN_PATH_TO_REDEPLOY |
| 0x14090CEC0 | defines 读取器 defines_military.h 表 NMilitary 键 FUEL_EFFICIENCY_RAID_MULTIPLIER |
| 0x14090D4F0 | defines 读取器 defines_military.h 表 NMilitary 键 FUEL_PENALTY_START_RATIO_BUFFER |
| 0x14090D700 | defines 读取器 defines_military.h 表 NMilitary 键 GARRISON_ORDER_ARMY_CAP_FACTOR |
| 0x14090DBD0 | defines 读取器 defines_military.h 表 NMilitary 键 GENERAL_PROXIMITY_DEFAULT |
| 0x14090DE90 | defines 读取器 defines_military.h 表 NMilitary 键 GENERAL_PROXIMITY_FAR |
| 0x14090E150 | defines 读取器 defines_military.h 表 NMilitary 键 GENERAL_PROXIMITY_MEDIUM |
| 0x14090E410 | defines 读取器 defines_military.h 表 NMilitary 键 GENERAL_RANK_TO_ARMY_HQ_EXP_LEVEL_FACTOR |
| 0x14090E830 | defines 读取器 defines_military.h 表 NMilitary 键 GENERATE_AI_DIV_COMMAND_MEDALS |
| 0x14090EA40 | defines 读取器 defines_military.h 表 NMilitary 键 HARD_ATTACK_TARGETING_FACTOR |
| 0x14090F280 | defines 读取器 defines_military.h 表 NMilitary 键 HOURS_REQ_REJOIN_BORDER_WAR_FOR_INJURED_UNITS |
| 0x14090F490 | defines 读取器 defines_military.h 表 NMilitary 键 INFRASTRUCTURE_MOVEMENT_SPEED_IMPACT |
| 0x14090F6A0 | defines 读取器 defines_military.h 表 NMilitary 键 INFRA_ORG_IMPACT |
| 0x14090F8B0 | defines 读取器 defines_military.h 表 NMilitary 键 INITIATIVE_PICK_COUNTER_ADVANTAGE_FACTOR |
| 0x14090FAC0 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_AIR_COMBAT_MAX_PLANES_PER_ENEMY_WIDTH |
| 0x1409100F0 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_AIR_COMBAT_STR_DAMAGE_MODIFIER |
| 0x140910300 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_AIR_COMBAT_STR_DICE_SIZE |
| 0x140910510 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_COMBAT_COLLATERAL_FORT_FACTOR |
| 0x140910720 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_COMBAT_COLLATERAL_INFRA_FACTOR |
| 0x140910930 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_COMBAT_FORT_DAMAGE_CHANCE |
| 0x140910B40 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_COMBAT_ORG_ARMOR_DEFLECTION_FACTOR |
| 0x140911590 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_COMBAT_STR_ARMOR_ON_SOFT_DICE_SIZE |
| 0x1409117A0 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_COMBAT_STR_DAMAGE_MODIFIER |
| 0x140911BC0 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_EQUIPMENT_BASE_COST |
| 0x140911FE0 | defines 读取器 defines_military.h 表 NMilitary 键 LAND_SPEED_MODIFIER |
| 0x140912400 | defines 读取器 defines_military.h 表 NMilitary 键 LEADER_GROUP_MAX_SIZE |
| 0x140912AE0 | defines 读取器 defines_military.h 表 NMilitary 键 LEND_LEASE_FIELD_EXPERIENCE_SCALE |
| 0x140913320 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_ARMY_EXPERIENCE |
| 0x140913740 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_DIVISION_BRIGADE_HEIGHT |
| 0x140913B60 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_DIVISION_SUPPORT_HEIGHT |
| 0x140913F80 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_ENTRY_ELISION_COUNT |
| 0x1409147C0 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_HQ_BATTALION_WIDTH |
| 0x1409149D0 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_HQ_REGIMENTAL_SUPPORT_HEIGHT |
| 0x140914BE0 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_HQ_REGIMENTAL_SUPPORT_WIDTH |
| 0x140915000 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_HQ_SUPPORT_WIDTH |
| 0x140915420 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_NAVY_EXPERIENCE |
| 0x140915C60 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_REGIMENTAL_SUPPORT_HEIGHT |
| 0x140916080 | defines 读取器 defines_military.h 表 NMilitary 键 MAX_RELATIVE_COMBAT_DAMAGE_TO_MODIFY_XP |
| 0x1409168C0 | defines 读取器 defines_military.h 表 NMilitary 键 MIN_DIVISION_DEPLOYMENT_TRAINING |
| 0x140916CE0 | defines 读取器 defines_military.h 表 NMilitary 键 MIN_VP_NEEDED_FOR_DEFENSE_ORDER_ASSIGNMENTS |
| 0x140917100 | defines 读取器 defines_military.h 表 NMilitary 键 MULTIPLE_COMBATS_PENALTY |
| 0x140917730 | defines 读取器 defines_military.h 表 NMilitary 键 NAVAL_INVASION_PLANNING_BONUS_GAIN |
| 0x140917B50 | defines 读取器 defines_military.h 表 NMilitary 键 NAVAL_TRANSFER_DISBAND_MANPOWER_FACTOR |
| 0x140917D60 | defines 读取器 defines_military.h 表 NMilitary 键 NAVY_LEADER_LEVEL_UP_STAT_WEIGHTS |
| 0x140917F70 | defines 读取器 defines_military.h 表 NMilitary 键 NEW_ARMY_LEADER_LEVEL_CHANCES |
| 0x140918180 | defines 读取器 defines_military.h 表 NMilitary 键 NEW_COMMANDER_RANDOM_BASIC_TRAIT_CHANCES |
| 0x1409185A0 | defines 读取器 defines_military.h 表 NMilitary 键 NEW_COMMANDER_RANDOM_SKILL_CHANCES |
| 0x140918BD0 | defines 读取器 defines_military.h 表 NMilitary 键 NEW_OPERATIVE_RANDOM_BASIC_TRAIT_CHANCES |
| 0x140918DE0 | defines 读取器 defines_military.h 表 NMilitary 键 NEW_OPERATIVE_RANDOM_PERSONALITY_TRAIT_CHANCES |
| 0x140918FF0 | defines 读取器 defines_military.h 表 NMilitary 键 NEW_OPERATIVE_RANDOM_STATUS_TRAIT_CHANCES |
| 0x140919200 | defines 读取器 defines_military.h 表 NMilitary 键 NON_CORE_SUPPLY_AIR_SPEED |
| 0x140919620 | defines 读取器 defines_military.h 表 NMilitary 键 NUKE_DELAY_HOURS |
| 0x140919A40 | defines 读取器 defines_military.h 表 NMilitary 键 ORG_LOSS_FACTOR_ON_CONQUER |
| 0x140919E60 | defines 读取器 defines_military.h 表 NMilitary 键 OUT_OF_FUEL_SPEED_MULT |
| 0x14091A070 | defines 读取器 defines_military.h 表 NMilitary 键 OUT_OF_FUEL_TRAINING_XP_GAIN_MULT |
| 0x14091A280 | defines 读取器 defines_military.h 表 NMilitary 键 OUT_OF_SUPPLY_ATTRITION |
| 0x14091A6A0 | defines 读取器 defines_military.h 表 NMilitary 键 OUT_OF_SUPPLY_SPEED |
| 0x14091AAC0 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_COMPLETE_ORG |
| 0x14091ACD0 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_DISRUPTED_AA_PENALTY |
| 0x14091AEE0 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_DISRUPTED_EQUIPMENT_DIV |
| 0x14091B0F0 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_DISRUPTED_MANPOWER_DIV |
| 0x14091B300 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_DISRUPTED_STR_DIV |
| 0x14091BD50 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_ORG_REGAIN_PENALTY_MULT |
| 0x14091BF60 | defines 读取器 defines_military.h 表 NMilitary 键 PARACHUTE_PENALTY_RANDOMNESS |
| 0x14091C170 | defines 读取器 defines_military.h 表 NMilitary 键 PARADROP_HOURS |
| 0x14091C7A0 | defines 读取器 defines_military.h 表 NMilitary 键 PIERCING_THRESHOLDS |
| 0x14091C9B0 | defines 读取器 defines_military.h 表 NMilitary 键 PIERCING_THRESHOLD_DAMAGE_VALUES |
| 0x14091CBC0 | defines 读取器 defines_military.h 表 NMilitary 键 PLANNING_CAP_COMMS_SCALING |
| 0x14091D090 | defines 读取器 defines_military.h 表 NMilitary 键 PLANNING_DECAY |
| 0x14091D2A0 | defines 读取器 defines_military.h 表 NMilitary 键 PLANNING_GAIN |
| 0x14091D4B0 | defines 读取器 defines_military.h 表 NMilitary 键 PLANNING_MAX |
| 0x14091D6C0 | defines 读取器 defines_military.h 表 NMilitary 键 PLANNING_SPEED_COMMS_SCALING |
| 0x14091DDA0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_AREA_DEFENSE_COAST_NO_FORT_IMPORTANCE |
| 0x14091E5E0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_AREA_DEFENSE_FORT_IMPORTANCE |
| 0x14091E7F0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_AREA_DEFENSE_HAS_RAIL_IMPORTANCE |
| 0x14091EE20 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_COHESION_DISTANCE_MAX_WHEN_LEFT_BEHIND |
| 0x14091F660 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_EXECUTE_BALANCED_LIMIT |
| 0x14091FA80 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_EXECUTE_CAREFUL_MAX_FORT |
| 0x14091FEA0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_EXECUTE_SUPPLY_CHECK |
| 0x1409204D0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_NEIGHBORING_ENEMY_PROVINCE_FACTOR |
| 0x1409206E0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PORVINCE_AIRFIELD_BASE_IMPORTANCE |
| 0x1409208F0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PORVINCE_AIRFIELD_LEVEL_FACTOR |
| 0x140920B00 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PORVINCE_AIRFIELD_POPULATED_FACTOR |
| 0x140921340 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_BASE_IMPORTANCE |
| 0x140921550 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_CAPITAL_DEFENSE_IMPORTANCE |
| 0x140921760 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_HIGH_VP_DEFENSE_IMPORTANCE |
| 0x140921970 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_HIGH_VP_DEFENSE_THRESHOLD |
| 0x140921FA0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_LOW_VP_DEFENSE_THRESHOLD |
| 0x1409221B0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_LOW_VP_IMPORTANCE_FRONT |
| 0x1409223C0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_MEDIUM_VP_DEFENSE_IMPORTANCE |
| 0x1409225D0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_MEDIUM_VP_DEFENSE_THRESHOLD |
| 0x1409227E0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_MEDIUM_VP_IMPORTANCE_FRONT |
| 0x1409229F0 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_PRIO_DISTRIBUTION_DPP_HIGH |
| 0x140922C00 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_PROVINCE_PRIO_DISTRIBUTION_DPP_LOW |
| 0x140923440 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_SHARED_FRONT_PROV_IMPORTANCE_FACTOR |
| 0x140923860 | defines 读取器 defines_military.h 表 NMilitary 键 PLAN_STICKINESS_FACTOR |
| 0x140923C80 | defines 读取器 defines_military.h 表 NMilitary 键 PREFERRED_PRISON_VP |
| 0x140923F40 | defines 读取器 defines_military.h 表 NMilitary 键 PREFERRED_TACTIC_CHARACTER_SKILL_LEVEL_REQUIRED |
| 0x140924990 | defines 读取器 defines_military.h 表 NMilitary 键 REGIMENTAL_SUPPORT_SLOT_COST_MULTIPLIER |
| 0x140924BA0 | defines 读取器 defines_military.h 表 NMilitary 键 REINFORCEMENT_REQUEST_DAYS_FREQUENCY |
| 0x140924DB0 | defines 读取器 defines_military.h 表 NMilitary 键 REINFORCEMENT_REQUEST_MAX_WAITING_DAYS |
| 0x140925C20 | defines 读取器 defines_military.h 表 NMilitary 键 RIVER_CROSSING_PENALTY |
| 0x140926040 | defines 读取器 defines_military.h 表 NMilitary 键 RIVER_CROSSING_SPEED_PENALTY |
| 0x140926880 | defines 读取器 defines_military.h 表 NMilitary 键 RIVER_SMALL_STOP_INDEX |
| 0x140926A90 | defines 读取器 defines_military.h 表 NMilitary 键 SHIP_MORALE_TO_ORG_REGAIN_BASE |
| 0x140926EB0 | defines 读取器 defines_military.h 表 NMilitary 键 SHORE_BOMBARDMENT_COLLATERAL_DAMAGE_MULTIPLIER |
| 0x1409270C0 | defines 读取器 defines_military.h 表 NMilitary 键 SLOWER_ORG_REGAIN_LEVEL |
| 0x1409274E0 | defines 读取器 defines_military.h 表 NMilitary 键 SLOWEST_SPEED |
| 0x140927900 | defines 读取器 defines_military.h 表 NMilitary 键 SPEED_REINFORCEMENT_BONUS |
| 0x140927D20 | defines 读取器 defines_military.h 表 NMilitary 键 SPOTTING_QUALITY_NAVAL_RECON_DROP_HOURS |
| 0x140928140 | defines 读取器 defines_military.h 表 NMilitary 键 STRATEGIC_SPEED_INFRA_BASE |
| 0x140928B90 | defines 读取器 defines_military.h 表 NMilitary 键 SUPPLY_GRACE_MAX_REDUCE_PER_HOUR |
| 0x140928DA0 | defines 读取器 defines_military.h 表 NMilitary 键 SUPPLY_ORG_MAX_CAP |
| 0x1409291C0 | defines 读取器 defines_military.h 表 NMilitary 键 SUPPLY_USE_FACTOR_MOVING |
| 0x1409295E0 | defines 读取器 defines_military.h 表 NMilitary 键 TACTIC_SWAP_FREQUENCEY |
| 0x1409298A0 | defines 读取器 defines_military.h 表 NMilitary 键 TRAINING_ATTRITION |
| 0x140929CC0 | defines 读取器 defines_military.h 表 NMilitary 键 TRAINING_MAX_DAILY_COUNTRY_EXP |
| 0x14092A0E0 | defines 读取器 defines_military.h 表 NMilitary 键 TRAINING_MIN_STRENGTH |
| 0x14092A2F0 | defines 读取器 defines_military.h 表 NMilitary 键 TRAINING_ORG |
| 0x14092AB30 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_EXPERIENCE_PER_TRAINING_DAY |
| 0x14092AD40 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_EXPERIENCE_SCALE |
| 0x14092AF50 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_EXP_LEVELS |
| 0x14092B160 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_ASSIGN_TRAIT_COST |
| 0x14092B370 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_GENERATION_CAPITAL_CONTINENT_FACTOR |
| 0x14092B580 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_INITIAL_TRAIT_SLOT |
| 0x14092B9A0 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_MODIFIER_COOLDOWN_ON_DEPLOY |
| 0x14092BDC0 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_MODIFIER_COOLDOWN_ON_GROUP_CHANGE |
| 0x14092BFD0 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_MODIFIER_COOLDOWN_ON_REDEPLOY |
| 0x14092C3F0 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_MODIFIER_COOLDOWN_ON_WITHDRAW_MIN |
| 0x14092C600 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_MODIFIER_COOLDOWN_REFERENCE_MANPOWER |
| 0x14092CA20 | defines 读取器 defines_military.h 表 NMilitary 键 UNIT_LEADER_USE_NONLINEAR_XP_GAIN |
| 0x14092D260 | defines 读取器 defines_military.h 表 NMilitary 键 VPS_FOR_HISTORY_ENTRY |
| 0x14092DCB0 | defines 读取器 defines_military.h 表 NMilitary 键 WAR_SCORE_LEND_LEASE_GIVEN_FUEL_FACTOR |
| 0x14092E0D0 | defines 读取器 defines_military.h 表 NMilitary 键 WAR_SCORE_LEND_LEASE_RECEIVED_FUEL_FACTOR |
| 0x14092E2E0 | defines 读取器 defines_military.h 表 NMilitary 键 WAR_SCORE_LEND_LEASE_RECEIVED_IC_FACTOR |
| 0x14092E4F0 | defines 读取器 defines_military.h 表 NMilitary 键 WAR_SCORE_LOSSES_MULT_IF_CAPITULATED |
| 0x14092E700 | defines 读取器 defines_military.h 表 NMilitary 键 WAR_SCORE_LOSSES_RATIO |
| 0x14092ED30 | defines 读取器 defines_military.h 表 NMilitary 键 WAR_SCORE_STRAT_BOMBING_DECAY_PER_CIVILIAN_FACTORY |
| 0x14092EF40 | defines 读取器 defines_military.h 表 NMilitary 键 WITHDRAWING_SPEED_FACTOR |
| 0x14092F150 | defines 读取器 defines_military.h 表 NMilitary 键 XP_DECAY_RATE_PER_HOUR_IN_COMBAT |
| 0x14092F360 | defines 读取器 defines_military.h 表 NMilitary 键 XP_GAIN_FACTOR_FOR_MAX_RELATIVE_COMBAT_DAMAGE |
| 0x14092F780 | defines 读取器 defines_military.h 表 NMilitary 键 XP_GAIN_PER_OVERRUN_UNIT |
| 0x1409961D0 | defines 读取器 defines_military.h 表 NRailwayGun 键 ATTACK_TO_ENTRENCHMENT_MODIFIER_FACTOR |
| 0x140996490 | defines 读取器 defines_military.h 表 NRailwayGun 键 ATTACK_TO_FORTS_MODIFIER_FACTOR |
| 0x140996AA0 | defines 读取器 defines_military.h 表 NRailwayGun 键 DAILY_MANPOWER_GAIN_RATIO |
| 0x140997020 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_COMBATS_INRANGE_SCORE |
| 0x140997C80 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_HOSTILE_UNITS_INRANGE_SCORE |
| 0x140997E90 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_HOSTILE_UNITS_PRESENCE_SCORE |
| 0x1409980A0 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_NO_RAILWAY_SCORE |
| 0x1409986D0 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_PROVINCES_CONTROLLED_BY_ENEMY_INRANGE_SCORE |
| 0x1409988E0 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_PROVINCE_CONTROLLED_BY_ENEMY_SCORE |
| 0x140998AF0 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_RAILWAY_GUN_PRESENCE_SCORE |
| 0x140998D00 | defines 读取器 defines_military.h 表 NRailwayGun 键 DISTRIBUTION_SUPPLY_DEFICIT_SCORE |
| 0x140998F10 | defines 读取器 defines_military.h 表 NRailwayGun 键 ENCIRCLED_DISBAND_MANPOWER_FACTOR |
| 0x140999120 | defines 读取器 defines_military.h 表 NRailwayGun 键 OUT_OF_SUPPLY_SPEED |
| 0x1409994A0 | defines 读取器 defines_military.h 表 NRailwayGun 键 RAILWAY_GUN_POSSIBLE_RANGES |
| 0x14099A270 | defines 读取器 defines_game.h 表 NResistance 键 COMPLIANCE_GROWTH_IS_AT_PEACE |
| 0x14099A690 | defines 读取器 defines_game.h 表 NResistance 键 COMPLIANCE_GROWTH_MIN |
| 0x14099A8A0 | defines 读取器 defines_game.h 表 NResistance 键 FOREIGN_MANPOWER_AI_COOLDOWN_DAYS |
| 0x14099AAB0 | defines 读取器 defines_game.h 表 NResistance 键 FOREIGN_MANPOWER_MIN_THRESHOLD |
| 0x14099B2F0 | defines 读取器 defines_game.h 表 NResistance 键 GARRISON_MANPOWER_LOST_BY_ATTACK |
| 0x14099B500 | defines 读取器 defines_game.h 表 NResistance 键 GARRISON_MANPOWER_MIN_DELIVERY_SPEED |
| 0x14099B710 | defines 读取器 defines_game.h 表 NResistance 键 GARRISON_MANPOWER_REINFORCEMENT_SPEED |
| 0x14099BB30 | defines 读取器 defines_game.h 表 NResistance 键 GARRISON_STR_POW_MANPOWER |
| 0x14099C370 | defines 读取器 defines_game.h 表 NResistance 键 INITIAL_STATE_COMPLIANCE |
| 0x14099CA10 | defines 读取器 defines_game.h 表 NResistance 键 MANPOWER_BUFFER_TO_NOT_GIVE_MAJOR |
| 0x14099CC20 | defines 读取器 defines_game.h 表 NResistance 键 MANPOWER_BUFFER_TO_NOT_GIVE_MINOR |
| 0x14099CE30 | defines 读取器 defines_game.h 表 NResistance 键 MAXIMUM_GARRISON_HARDNESS_WHEN_ATTACKED |
| 0x14099D040 | defines 读取器 defines_game.h 表 NResistance 键 MAX_GARRISON_RATIO_WE_AGREE_TO_SUPPORT |
| 0x14099D880 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_ACTIVITY_MIN_GARRISON_PENETRATE_CHANCE |
| 0x14099DD50 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_DECAY_BASE |
| 0x14099E170 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_DECAY_MIN |
| 0x14099E380 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_DECAY_MODIFIER_FACTORS |
| 0x14099E9B0 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_GROWTH_MAX |
| 0x14099EDD0 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_POP_LOW_CUTOFF |
| 0x14099EFE0 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_POP_VERY_LOW_CUTOFF |
| 0x14099F1F0 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_RATIO_DIFF_TO_SPREAD |
| 0x14099F610 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MIN_CAP_FOR_NON_COMPLIANCE |
| 0x14099FA30 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_IS_AT_PEACE |
| 0x14099FC40 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_OCCUPIED_CAPITULATED |
| 0x14099FE50 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_OCCUPIED_IS_EXILE_MAX |
| 0x1409A0060 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_OCCUPIED_IS_EXILE_MIN |
| 0x1409A0270 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_PER_COMPLIANCE |
| 0x1409A0480 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_PER_STABILITY_LOSS |
| 0x1409A0AB0 | defines 读取器 defines_game.h 表 NResistance 键 RESISTANCE_TARGET_MODIFIER_STATE_VP |
| 0x1409A10E0 | defines 读取器 defines_game.h 表 NResistance 键 SUPPRESSION_NEEDED_BY_RESISTANCE_POINT |
| 0x1409A12F0 | defines 读取器 defines_game.h 表 NResistance 键 SUPPRESSION_NEEDED_LOWER_CAP |
| 0x1409B60E0 | defines 读取器 defines_game.h 表 NTrade 键 ANTI_MONOPOLY_TRADE_FACTOR |
| 0x1409B62F0 | defines 读取器 defines_game.h 表 NTrade 键 ANTI_MONOPOLY_TRADE_FACTOR_THRESHOLD |
| 0x1409B6710 | defines 读取器 defines_game.h 表 NTrade 键 BASE_TRADE_FACTOR |
| 0x1409B6920 | defines 读取器 defines_game.h 表 NTrade 键 DISTANCE_TRADE_FACTOR |
| 0x1409B6B30 | defines 读取器 defines_game.h 表 NTrade 键 MAX_MONTH_TRADE_FACTOR |
| 0x1409B7160 | defines 读取器 defines_game.h 表 NTrade 键 PARTY_SUPPORT_TRADE_FACTOR |
| 0x1409B7790 | defines 读取器 defines_game.h 表 NTrade 键 RELATION_TRADE_FACTOR |
| 0x14096B1A0 | defines 读取器 defines_game.h 表 NOperatives 键 ACTIVITY_LEVEL_DERIVATIVE_FACTOR |
| 0x14096B720 | defines 读取器 defines_game.h 表 NOperatives 键 ACTIVITY_LEVEL_PROPORTIONAL_FACTOR |
| 0x14096B9E0 | defines 读取器 defines_game.h 表 NOperatives 键 AGENCY_AI_BASE_NUM_FACTORIES |
| 0x14096BE00 | defines 读取器 defines_game.h 表 NOperatives 键 AGENCY_CREATION_DAYS |
| 0x14096C220 | defines 读取器 defines_game.h 表 NOperatives 键 AGENCY_DEFENSE_EFFECT_ON_HOSTILE_ACTION_COST |
| 0x14096C430 | defines 读取器 defines_game.h 表 NOperatives 键 AGENCY_OPERATIVE_RECRUITMENT_TIME |
| 0x14096CBC0 | defines 读取器 defines_game.h 表 NOperatives 键 BASE_COUNTER_INTELLIGENCE_RATING |
| 0x14096CFE0 | defines 读取器 defines_game.h 表 NOperatives 键 BECOME_SPYMASTER_PP_COST |
| 0x14096D770 | defines 读取器 defines_game.h 表 NOperatives 键 BOOST_IDEOLOGY_DRIFT_STACKING_FACTOR |
| 0x14096DAC0 | defines 读取器 defines_game.h 表 NOperatives 键 BOOST_IDEOLOGY_MAX_DRIFT_BY_OPERATIVE |
| 0x14096DD90 | defines 读取器 defines_game.h 表 NOperatives 键 BOOST_IDEOLOGY_NATIONAL_COVERAGE_FACTOR |
| 0x14096E310 | defines 读取器 defines_game.h 表 NOperatives 键 BUILD_INTEL_NETWORK_DAILY_XP_GAIN |
| 0x14096F390 | defines 读取器 defines_game.h 表 NOperatives 键 CONTROL_TRADE_STACKING_FACTOR |
| 0x14096F650 | defines 读取器 defines_game.h 表 NOperatives 键 COUNTER_INTELLIGENCE_DAILY_XP_GAIN |
| 0x1409701E0 | defines 读取器 defines_game.h 表 NOperatives 键 COUNTER_INTELLIGENCE_TO_DEFENSE_LOG_FACTOR |
| 0x140970AD0 | defines 读取器 defines_game.h 表 NOperatives 键 CYRPTO_ACTIVE_BONUS_ACTIVATION_PROGRESS_RATIO |
| 0x140971520 | defines 读取器 defines_game.h 表 NOperatives 键 DEFAULT_OPERATION_COST_MULTIPLIER |
| 0x140971730 | defines 读取器 defines_game.h 表 NOperatives 键 DEFAULT_OPERATION_TIME_MULTIPLIER |
| 0x140971940 | defines 读取器 defines_game.h 表 NOperatives 键 DIPLOMATIC_PRESSURE_AI_ACCEPTANCE_SCORE_DECAY |
| 0x140971C00 | defines 读取器 defines_game.h 表 NOperatives 键 DIPLOMATIC_PRESSURE_DAILY_XP_GAIN |
| 0x1409729C0 | defines 读取器 defines_game.h 表 NOperatives 键 DIPLOMATIC_PRESSURE_TENSION_REQUIREMENTS_DECAY |
| 0x140973200 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_COVERAGE_ACTIVITY_FACTOR |
| 0x140973780 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_GAIN_DECAY_PER_STEP_FACTOR |
| 0x140973990 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_GAIN_FROM_ADJACENCY_FACTOR |
| 0x140974800 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_MIN_DEFAULT_FOR_SHOWING |
| 0x140974AC0 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_MIN_NATIONAL_COVERAGE_FOR_DETECTION |
| 0x140975450 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_MIN_STRENGTH_TO_TARGET |
| 0x140975920 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_MIN_SUB_NETWORK_SIZE_FOR_DETECTION |
| 0x140975EA0 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_MIN_VP_TO_TARGET |
| 0x1409760B0 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_NATIONAL_COVERAGE_CONTROLLED_STATES_WEIGHT |
| 0x140976BB0 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_OCCUPIED_TAG_STATES_WEIGHT |
| 0x140976E70 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_OCCUPIED_TAG_WORTH_WEIGHT |
| 0x1409776B0 | defines 读取器 defines_game.h 表 NOperatives 键 INTEL_NETWORK_STRENGTH_DANGER_FACTOR |
| 0x1409789F0 | defines 读取器 defines_game.h 表 NOperatives 键 MIN_NATIONAL_COVERAGE_FOR_BOOST_IDEOLOGY |
| 0x140978C00 | defines 读取器 defines_game.h 表 NOperatives 键 MIN_NATIONAL_COVERAGE_FOR_PROPAGANDA |
| 0x140978E10 | defines 读取器 defines_game.h 表 NOperatives 键 NUM_DAYS_BEFORE_REMOVING_PREPARED_OPERATIONS |
| 0x140979650 | defines 读取器 defines_game.h 表 NOperatives 键 ON_CAPTURE_COUNTERINTELLIGENCE_OPERATIVE_XP_GAIN |
| 0x140979B20 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATION_COMPLETION_XP |
| 0x140979F40 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_BASE_CONTROL_TRADE_DRIFT |
| 0x14097A990 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_BASE_INTEL_NETWORK_GAIN |
| 0x14097ABA0 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_BASE_PROPAGANDA_POWER |
| 0x14097B070 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_CAPTURE_DURATION_IN_DAYS |
| 0x14097B330 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_MAX_DAYS_FORCED_INTO_HIDING |
| 0x14097B540 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_MAX_DAYS_HARMED |
| 0x14097B750 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_MAX_DAYS_TO_AUTO_RESUME_MISSION |
| 0x14097BA10 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_MAX_INTEL_NETWORK_GAIN |
| 0x14097C250 | defines 读取器 defines_game.h 表 NOperatives 键 OPERATIVE_SLOTS_FROM_FACTION_MEMBERS_FOR_SPY_MASTER |
| 0x14097DBC0 | defines 读取器 defines_game.h 表 NOperatives 键 RISK_LEVELS |
| 0x14097E2A0 | defines 读取器 defines_game.h 表 NOperatives 键 ROOT_OUT_RESISTANCE_RANGE_STEP_FACTOR |
| 0x14097E560 | defines 读取器 defines_game.h 表 NOperatives 键 ROOT_OUT_RESISTANCE_STACKING_FACTOR |
| 0x14097E820 | defines 读取器 defines_game.h 表 NOperatives 键 TECH_STEAL_EQUIPMENT_FACTOR |
| 0x14097F1C0 | defines 读取器 defines_game.h 表 NPolitics 键 BASE_LEADER_TRAITS |
| 0x14097F5E0 | defines 读取器 defines_game.h 表 NPolitics 键 DEFAULT_OCCUPATION_POLICY |
| 0x14097FA00 | defines 读取器 defines_game.h 表 NPolitics 键 INSTANT_WIN_REVOLTER_POPULARITY_RATIO |
| 0x140980240 | defines 读取器 defines_game.h 表 NPolitics 键 NAVY_LEADER_COST |
| 0x1409B79A0 | defines 读取器 defines_game.h 表 NWiki 键 BASE_URL |
| 0x14092FBA0 | defines 读取器 defines_military.h 表 NNavy 键 AA_EFFICIENCY_PENALTY_ON_MINIMUM_POSITIONING |
| 0x140930280 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESION_MULTIPLIER_FOR_COMBAT |
| 0x140930490 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_ARMOR_EFFICIENCY_MULTIPLIER |
| 0x1409306A0 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_CONVOY_STRENGTH_FACTOR |
| 0x1409308B0 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_HEAVY_GUN_EFFICIENCY_ON_HEAVY_SHIPS |
| 0x140930AC0 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_HEAVY_GUN_EFFICIENCY_ON_LIGHT_SHIPS |
| 0x140931300 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_LIGHT_GUN_EFFICIENCY_ON_LIGHT_SHIPS |
| 0x140931720 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_MIN_ARMOR_EFFICIENCY |
| 0x140931B40 | defines 读取器 defines_military.h 表 NNavy 键 AGGRESSION_TORPEDO_EFFICIENCY_ON_HEAVY_SHIPS |
| 0x140931F60 | defines 读取器 defines_military.h 表 NNavy 键 AIR_BASE_DOMINANCE_FACTOR |
| 0x140932220 | defines 读取器 defines_military.h 表 NNavy 键 AIR_MISSION_SPOTTING_FACTORS |
| 0x1409326F0 | defines 读取器 defines_military.h 表 NNavy 键 AIR_SPOTTER_NORMALIZED_AIRWING_SIZE |
| 0x1409329B0 | defines 读取器 defines_military.h 表 NNavy 键 AI_MAX_TASKFORCES_PER_TRAINING_OBJECTIVE |
| 0x140932FE0 | defines 读取器 defines_military.h 表 NNavy 键 AMPHIBIOUS_INVADE_ATTACK_LOW |
| 0x140933400 | defines 读取器 defines_military.h 表 NNavy 键 AMPHIBIOUS_INVADE_DEFEND_LOW |
| 0x140933C40 | defines 读取器 defines_military.h 表 NNavy 键 AMPHIBIOUS_LANDING_PENALTY |
| 0x1409345E0 | defines 读取器 defines_military.h 表 NNavy 键 ANTI_AIR_TARGETING |
| 0x140935240 | defines 读取器 defines_military.h 表 NNavy 键 BASE_CARRIER_SORTIE_EFFICIENCY |
| 0x140935660 | defines 读取器 defines_military.h 表 NNavy 键 BASE_ESCAPE_SPEED |
| 0x140935870 | defines 读取器 defines_military.h 表 NNavy 键 BASE_GUN_COOLDOWNS |
| 0x140935D40 | defines 读取器 defines_military.h 表 NNavy 键 BASE_NAVAL_INVASION_DIVISION_CAP |
| 0x140936000 | defines 读取器 defines_military.h 表 NNavy 键 BASE_NAVAL_INVASION_SPOTTING_SPEED |
| 0x140936980 | defines 读取器 defines_military.h 表 NNavy 键 BASE_SPOTTING_EFFECT_FOR_INITIAL_NAVAL_INVASION_SPOTTING |
| 0x140936B90 | defines 读取器 defines_military.h 表 NNavy 键 BASE_SPOTTING_EFFECT_FOR_INITIAL_UNIT_TRANSFER_SPOTTING |
| 0x140936DA0 | defines 读取器 defines_military.h 表 NNavy 键 BASE_SPOTTING_FROM_AIR |
| 0x140937790 | defines 读取器 defines_military.h 表 NNavy 键 BASE_SPOTTING_FROM_RADAR |
| 0x140937AE0 | defines 读取器 defines_military.h 表 NNavy 键 BASE_SPOTTING_SPEED |
| 0x140937CF0 | defines 读取器 defines_military.h 表 NNavy 键 BASE_UNIT_TRANSFER_SPOTTING_SPEED |
| 0x140938CC0 | defines 读取器 defines_military.h 表 NNavy 键 CAPITAL_RATIO_FOR_FULL_SCREENING_FOR_CONVOYS |
| 0x140939660 | defines 读取器 defines_military.h 表 NNavy 键 CARRIER_ONLY_COMBAT_ACTIVATE_TIME |
| 0x140939870 | defines 读取器 defines_military.h 表 NNavy 键 CHANCE_TO_DAMAGE_PART_ON_CRITICAL_HIT |
| 0x140939F10 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_ARMOR_PIERCING_CRITICAL_BONUS |
| 0x14093A120 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_ARMOR_PIERCING_DAMAGE_REDUCTION |
| 0x14093A330 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_BASE_CRITICAL_CHANCE |
| 0x14093AF90 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_DAMAGE_TO_STR_FACTOR |
| 0x14093B1A0 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_DETECTED_CONVOYS_FROM_SURFACE_DETECTION_STAT |
| 0x14093B3B0 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_EVASION_TO_HIT_CHANCE |
| 0x14093B7D0 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_INITIAL_DURATION |
| 0x14093B9E0 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_LOW_MANPOWER_HIT_CHANCE_PENALTY |
| 0x14093BBF0 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_LOW_ORG_HIT_CHANCE_PENALTY |
| 0x14093BE00 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_MAX_GROUPS |
| 0x14093C010 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_MIN_DURATION |
| 0x14093CC70 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_TORPEDO_CRITICAL_CHANCE |
| 0x14093CE80 | defines 读取器 defines_military.h 表 NNavy 键 COMBAT_TORPEDO_CRITICAL_DAMAGE_MULT |
| 0x14093D090 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_ATTACK_BASE_FACTOR |
| 0x14093D2A0 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_BLOCKED_BY_ENEMY_CONTROLLED_REGION |
| 0x14093DCF0 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_EFFICIENCY_MIN_VALUE |
| 0x14093DF00 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_EFFICIENCY_REGAIN_AFTER_DAYS |
| 0x14093E110 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_EFFICIENCY_REGAIN_BASE_SPEED |
| 0x14093E320 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_HIT_PROFILE |
| 0x14093E530 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_LOSS_HISTORY_TIMEOUT_MONTHS |
| 0x14093ED70 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_SPOTTING_COOLDOWN |
| 0x14093F030 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_SPOTTING_COOLDOWN_MAX |
| 0x14093F2F0 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_SPOTTING_COOLDOWN_MIN |
| 0x14093F870 | defines 读取器 defines_military.h 表 NNavy 键 CONVOY_SPOTTING_SPEED_MULT |
| 0x14093FA80 | defines 读取器 defines_military.h 表 NNavy 键 COORDINATION_EFFECT_ON_CONVOY_DEFENSE_EFFICIENCY |
| 0x14093FC90 | defines 读取器 defines_military.h 表 NNavy 键 COORDINATION_EFFECT_ON_CONVOY_RAID_EFFICIENCY |
| 0x14093FEA0 | defines 读取器 defines_military.h 表 NNavy 键 COORDINATION_EFFECT_ON_MINE_LAYING_SPEED |
| 0x1409404D0 | defines 读取器 defines_military.h 表 NNavy 键 COORDINATION_EFFECT_ON_MINE_SWEEPING_SPEED |
| 0x1409406E0 | defines 读取器 defines_military.h 表 NNavy 键 COORDINATION_EFFECT_ON_PATROL_SPOTTING |
| 0x140940B00 | defines 读取器 defines_military.h 表 NNavy 键 DAILY_MANPOWER_GAIN_RATIO |
| 0x140940E50 | defines 读取器 defines_military.h 表 NNavy 键 DAMAGE_PENALTY_ON_MINIMUM_POSITIONING |
| 0x140941320 | defines 读取器 defines_military.h 表 NNavy 键 DEPTH_CHARGES_DAMAGE_MULT |
| 0x140941740 | defines 读取器 defines_military.h 表 NNavy 键 DEPTH_CHARGES_HIT_PROFILE |
| 0x1409427A0 | defines 读取器 defines_military.h 表 NNavy 键 DOMINANCE_DAILY_GAIN_FACTOR |
| 0x140942E40 | defines 读取器 defines_military.h 表 NNavy 键 DOMINANCE_EFFECT_ON_POSITIONING_FOR_CONVOY_ESCORT |
| 0x140943890 | defines 读取器 defines_military.h 表 NNavy 键 DOMINANCE_PER_SHIP_PER_RANGE_NEUTRAL |
| 0x140943B50 | defines 读取器 defines_military.h 表 NNavy 键 DOMINANCE_PER_SHIP_PER_SPEED_NEUTRAL |
| 0x140943E10 | defines 读取器 defines_military.h 表 NNavy 键 EFFICIENCY_TO_JOIN_COMBAT_RATIO_PENALTY |
| 0x140944020 | defines 读取器 defines_military.h 表 NNavy 键 EFFICIENCY_TO_TIME_TO_JOIN_COMBAT_PENALTY |
| 0x140944230 | defines 读取器 defines_military.h 表 NNavy 键 ESCAPE_SPEED_HIDDEN_SUB |
| 0x140944650 | defines 读取器 defines_military.h 表 NNavy 键 ESCAPE_SPEED_SUB_BASE |
| 0x140944A70 | defines 读取器 defines_military.h 表 NNavy 键 EXPERIENCE_FACTOR_CONVOY_ATTACK |
| 0x140944C80 | defines 读取器 defines_military.h 表 NNavy 键 EXPERIENCE_FACTOR_NON_CARRIER_GAIN |
| 0x140944E90 | defines 读取器 defines_military.h 表 NNavy 键 EXPERIENCE_LOSS_FACTOR |
| 0x1409452B0 | defines 读取器 defines_military.h 表 NNavy 键 FIELD_EXPERIENCE_MAX_PER_DAY |
| 0x1409456D0 | defines 读取器 defines_military.h 表 NNavy 键 FUEL_COST_MULT |
| 0x1409458E0 | defines 读取器 defines_military.h 表 NNavy 键 GUN_HIT_PROFILES |
| 0x140946280 | defines 读取器 defines_military.h 表 NNavy 键 HIT_PROFILE_MULT |
| 0x140946490 | defines 读取器 defines_military.h 表 NNavy 键 HIT_PROFILE_SPEED_BASE |
| 0x1409468B0 | defines 读取器 defines_military.h 表 NNavy 键 HOLD_MISSION_MOVEMENT_COST |
| 0x140947350 | defines 读取器 defines_military.h 表 NNavy 键 INTEL_LEVEL_LOW_HALF_RANGE_PERCENTAGE |
| 0x140947D10 | defines 读取器 defines_military.h 表 NNavy 键 INTEL_LEVEL_MEDIUM_HALF_RANGE_MIN_SHIPS |
| 0x1409486D0 | defines 读取器 defines_military.h 表 NNavy 键 IN_COMBAT_FUEL_COST |
| 0x140948D00 | defines 读取器 defines_military.h 表 NNavy 键 LOW_ORG_FACTOR_ON_JOIN_COMBAT_DURATION |
| 0x140949B50 | defines 读取器 defines_military.h 表 NNavy 键 MAX_CAPITALS_PER_AUTO_TASK_FORCE |
| 0x14094A0D0 | defines 读取器 defines_military.h 表 NNavy 键 MAX_ESCAPE_SPEED_FROM_COMBAT_DURATION |
| 0x14094A2E0 | defines 读取器 defines_military.h 表 NNavy 键 MAX_FUEL_FLOW_MULT |
| 0x14094A4F0 | defines 读取器 defines_military.h 表 NNavy 键 MAX_NUM_HOURS_TO_WAIT_AT_ALLY_DOCKYARDS_FOR_REPAIRS |
| 0x14094A7B0 | defines 读取器 defines_military.h 表 NNavy 键 MAX_ORG_ON_MANUAL_MOVE |
| 0x14094AB00 | defines 读取器 defines_military.h 表 NNavy 键 MAX_POSITIONING_BONUS_FROM_SURFACE_DETECTION |
| 0x14094ADC0 | defines 读取器 defines_military.h 表 NNavy 键 MAX_POSITIONING_PENALTY_FOR_NEWLY_JOINED_SHIPS |
| 0x14094B340 | defines 读取器 defines_military.h 表 NNavy 键 MAX_SHIP_COUNT_FOR_DOMINANCE_PATROL_ROLE_ASSIGNMENT |
| 0x14094B600 | defines 读取器 defines_military.h 表 NNavy 键 MAX_SUBMARINES_PER_AUTO_TASK_FORCE |
| 0x14094B8C0 | defines 读取器 defines_military.h 表 NNavy 键 MINE_PLANTING_REGION_TO_TASKFORCE_RATIO |
| 0x14094BEF0 | defines 读取器 defines_military.h 表 NNavy 键 MIN_GUN_COOLDOWN |
| 0x14094C1B0 | defines 读取器 defines_military.h 表 NNavy 键 MIN_HIT_PROFILE_MULT |
| 0x14094C5D0 | defines 读取器 defines_military.h 表 NNavy 键 MIN_MANPOWER_RATIO_TO_DROP |
| 0x14094CF30 | defines 读取器 defines_military.h 表 NNavy 键 MIN_REPAIR_FOR_JOINING_COMBATS |
| 0x14094D400 | defines 读取器 defines_military.h 表 NNavy 键 MIN_SHIP_COUNT_FOR_TASK_FORCE_ROLE_ASSIGNMENT |
| 0x14094D6C0 | defines 读取器 defines_military.h 表 NNavy 键 MIN_SPOTTING_PROGRESS |
| 0x14094DC20 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_DAILY_COUNTRY_EXP_FACTOR |
| 0x14094DE30 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_DAILY_COUNTRY_EXP_MANPOWER_FACTOR |
| 0x14094E040 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_DAILY_COUNTRY_EXP_MANPOWER_RATIO_FACTOR |
| 0x14094E880 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_DOMINANCE_RATIOS |
| 0x14094ECA0 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_EXP_RATIOS |
| 0x14094EEB0 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_FUEL_COSTS |
| 0x14094F0C0 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_FUEL_COSTS_PRIO_FACTOR |
| 0x14094F4E0 | defines 读取器 defines_military.h 表 NNavy 键 MISSION_SPREADS |
| 0x14094FB10 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_ACCIDENT_CRITICAL_HIT_CHANCE_REDUCTION_POTF |
| 0x1409502A0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_CAPITAL_TARGET_BASE |
| 0x1409504B0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_CAPITAL_TARGET_SCALE |
| 0x140950CF0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_CONVOY_TARGET_SCALE |
| 0x140951690 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_SCREEN_TARGET_BASE |
| 0x1409518A0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_SCREEN_TARGET_SCALE |
| 0x140951AB0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_STRENGTH_TARGET_SCORE |
| 0x140951CC0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_STRIKE_ATTACK_TO_SUB_DETECTION |
| 0x140951F80 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_STRIKE_TARGETING_TO_SUB_DETECTION |
| 0x140952B10 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_SUB_DETECTION_INTERNAL_EFFICIENCY_FACTOR |
| 0x140953350 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_AIR_SUB_TARGET_BASE |
| 0x140953770 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_MEDAL_ALLOW_CONVOY |
| 0x140953980 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_MEDAL_CHANCE |
| 0x1409541C0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_PLANE_MIN_STACKING_PENALTY |
| 0x1409545E0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_RESULT_TIMEOUT_YEARS |
| 0x1409547F0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_COMBAT_SUB_DETECTION_FACTOR |
| 0x140954C10 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_CONVOY_DANGER_TRIGGER_MAX |
| 0x140955030 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_CHANCE_OF_ACCIDENT_REDUCTION |
| 0x140955240 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_MINES_PLANTING_BONUS |
| 0x140955450 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_MINES_SWEEPING_BONUS |
| 0x140955660 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_ORG_RECOVERY |
| 0x140955920 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_SHIP_RECOVERY_CHANCE |
| 0x140955BE0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_SPOTTING_BONUS |
| 0x140955EA0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_STRIKE_FORCE_FRACTION |
| 0x1409560B0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_DOMINANCE_STRIKE_FORCE_MULTIREGION_DECAY |
| 0x140956400 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_HEADQUARTERS_EXPERIENCE_SCALE |
| 0x140956610 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_HEADQUARTERS_FIRST_ADJACENT_FACTOR |
| 0x140956F80 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_HOMEBASE_CALCULATION_DISTANCE_CUTOFF |
| 0x1409577C0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_INVASION_PRIORITY |
| 0x1409579D0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_INVASION_SPOTTING_SPEED_MULT |
| 0x140958420 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_MINES_DECAY_AT_PEACE_TIME |
| 0x140958B00 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_MINES_PLANTING_SPEED_MULT |
| 0x140958D10 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_MINES_SWEEPERS_REDUCTION_ON_PENALTY_EFFECT |
| 0x140958F20 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_MINES_SWEEPING_SPEED_MULT |
| 0x140959760 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_MISSION_AI_CONVOY_NORMALIZATION_TARGET |
| 0x140959970 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_MISSION_AI_RANGE_THRESHOLD_EPSILON |
| 0x140959B80 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_RANGE_TO_INGAME_DISTANCE |
| 0x140959D90 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_SPEED_MODIFIER |
| 0x140959FA0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_TRANSFER_BASE_NAVAL_DIST_ADD |
| 0x14095A3C0 | defines 读取器 defines_military.h 表 NNavy 键 NAVAL_TRANSFER_BASE_SPEED |
| 0x14095A9F0 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_EXPENSIVE_IC |
| 0x14095AC00 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_MAX_XP |
| 0x14095B650 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_REPAIR_BASE_PRIORITY_THRESHOLD_LOW |
| 0x14095B860 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_REPAIR_BASE_SEARCH_BOOST_FOR_SAME_COUNTRY |
| 0x14095BA70 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_REPAIR_BASE_SEARCH_NON_OPERATIONAL_STR |
| 0x14095BC80 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_REPAIR_BASE_SEARCH_SCORE_PER_SHIP_WAITING_EXTRA_SHIP |
| 0x14095BE90 | defines 读取器 defines_military.h 表 NNavy 键 NAVY_REPAIR_BASE_SEARCH_SCORE_PER_SLOT |
| 0x14095C780 | defines 读取器 defines_military.h 表 NNavy 键 ON_BASE_FUEL_COST |
| 0x14095CFC0 | defines 读取器 defines_military.h 表 NNavy 键 OUT_OF_FUEL_RANGE_FACTOR |
| 0x14095D3E0 | defines 读取器 defines_military.h 表 NNavy 键 OUT_OF_FUEL_TORPEDO_FACTOR |
| 0x14095D5F0 | defines 读取器 defines_military.h 表 NNavy 键 PEACE_ACTION_TRANSFER_NAVY_EXPERIENCE_RETAINED |
| 0x14095E510 | defines 读取器 defines_military.h 表 NNavy 键 RELATIVE_SURFACE_DETECTION_TO_POSITIONING_FACTOR |
| 0x14095E7D0 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_AMOUNT_SHIPS_HIGH |
| 0x14095E9E0 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_AMOUNT_SHIPS_LOW |
| 0x14095EBF0 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_AMOUNT_SHIPS_MEDIUM |
| 0x14095EE00 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_PRIO_HIGH |
| 0x14095F010 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_PRIO_HIGH_COMBAT |
| 0x14095F220 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_PRIO_LOW |
| 0x14095F850 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_PRIO_MEDIUM_COMBAT |
| 0x14095FA60 | defines 读取器 defines_military.h 表 NNavy 键 REPAIR_AND_RETURN_UNIT_DYING_STR |
| 0x14095FE80 | defines 读取器 defines_military.h 表 NNavy 键 RESOURCE_EXPORT_PRIORITY |
| 0x1409602A0 | defines 读取器 defines_military.h 表 NNavy 键 RESOURCE_ORIGIN_PRIORITY |
| 0x1409606C0 | defines 读取器 defines_military.h 表 NNavy 键 SCREENING_EFFICIENCY_PENALTY_ON_MINIMUM_POSITIONING |
| 0x140960B90 | defines 读取器 defines_military.h 表 NNavy 键 SCREEN_RATIO_FOR_FULL_SCREENING_FOR_CAPITALS |
| 0x140961110 | defines 读取器 defines_military.h 表 NNavy 键 SELECTED_SORTIE_INITIAL_TIME |
| 0x1409613D0 | defines 读取器 defines_military.h 表 NNavy 键 SHIP_SILHOUETTE_VALUE_PLANES_CAPITAL |
| 0x1409617F0 | defines 读取器 defines_military.h 表 NNavy 键 SHIP_SILHOUETTE_VALUE_PLANES_CONVOY |
| 0x140961A00 | defines 读取器 defines_military.h 表 NNavy 键 SHIP_SILHOUETTE_VALUE_PLANES_SCREEN |
| 0x140961C10 | defines 读取器 defines_military.h 表 NNavy 键 SHIP_SILHOUETTE_VALUE_PLANES_SUBMARINE |
| 0x140962380 | defines 读取器 defines_military.h 表 NNavy 键 SHIP_TO_FLEET_ANTI_AIR_RATIO |
| 0x140962850 | defines 读取器 defines_military.h 表 NNavy 键 SPEED_TO_ESCAPE_SPEED |
| 0x140962A60 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_ENEMY_SPOTTING_MULTIPLIER_FOR_RUNNING_AWAY |
| 0x140962FC0 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_MISSION_DETECTION_THRESHOLD_MEDIUM |
| 0x140963310 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_MOD_FOR_CONVOY_COUNT |
| 0x140963730 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_MULTIPLIER_FOR_SURFACE |
| 0x140963940 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_SPEED_EFFECT_FOR_INITIAL_CONVOY_SPOTTING |
| 0x140963B50 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_SPEED_EFFECT_FOR_INITIAL_NAVAL_INVASION_SPOTTING |
| 0x140964180 | defines 读取器 defines_military.h 表 NNavy 键 SPOTTING_SPEED_MULT_FOR_RUNNING_AWAY |
| 0x140964390 | defines 读取器 defines_military.h 表 NNavy 键 STRIKE_FORCE_ON_BASE_FUEL_COST_FACTOR |
| 0x1409646E0 | defines 读取器 defines_military.h 表 NNavy 键 SUBMARINE_BASE_STEALTH_VALUE |
| 0x140964E50 | defines 读取器 defines_military.h 表 NNavy 键 SUBMARINE_HIDE_TIMEOUT |
| 0x140965270 | defines 读取器 defines_military.h 表 NNavy 键 SUBMARINE_REVEAL_BASE_CHANCE |
| 0x140965950 | defines 读取器 defines_military.h 表 NNavy 键 SUBMARINE_REVEAL_POW |
| 0x140965B60 | defines 读取器 defines_military.h 表 NNavy 键 SUBMARINE_REVEAL_TORPEDO_FIRING_DETECTION_MULTIPLIER |
| 0x140965D70 | defines 读取器 defines_military.h 表 NNavy 键 SUB_DETECTION_CHANCE_BASE |
| 0x1409662D0 | defines 读取器 defines_military.h 表 NNavy 键 SUB_DETECTION_CHANCE_BASE_SPOTTING_POW_EFFECT |
| 0x140966620 | defines 读取器 defines_military.h 表 NNavy 键 SUB_DETECTION_CHANCE_SPOTTING_SPEED_EFFECT |
| 0x140966830 | defines 读取器 defines_military.h 表 NNavy 键 SUB_DETECTION_STAT_FOR_SHIP_TO_BE_SUB_HUNTER |
| 0x140966AF0 | defines 读取器 defines_military.h 表 NNavy 键 SUPPLY_NEED_FACTOR |
| 0x140966D00 | defines 读取器 defines_military.h 表 NNavy 键 SUPPLY_PRIORITY |
| 0x140967520 | defines 读取器 defines_military.h 表 NNavy 键 TASK_FORCE_ROLE_TO_INSIGNIA |
| 0x140967D60 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_ACCIDENT_ORG_LOSS_FACTOR |
| 0x140968180 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_ACCIDENT_STRENGTH_LOSS_FACTOR |
| 0x140968390 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_DAILY_COUNTRY_EXP_FACTOR |
| 0x1409689C0 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_DAILY_COUNTRY_EXP_SHIP_RATIO_FACTOR |
| 0x140968DE0 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_FUEL_COST_FOR_ESCORT_SHIPS |
| 0x140969200 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_MIN_STRENGTH |
| 0x140969410 | defines 读取器 defines_military.h 表 NNavy 键 TRAINING_ORG |
| 0x1409698E0 | defines 读取器 defines_military.h 表 NNavy 键 UNDERWAY_REPLENISHMENT_PRIORITY |
| 0x14096A120 | defines 读取器 defines_military.h 表 NNavy 键 UNIT_TRANSFER_DETECTION_CHANCE_BASE |
| 0x14096A330 | defines 读取器 defines_military.h 表 NNavy 键 UNIT_TRANSFER_SPOTTING_SPEED_MULT |
| 0x14096A540 | defines 读取器 defines_military.h 表 NNavy 键 VISIBILITY_MULTIPLIER_FOR_SPOTTING |
| 0x14096AA10 | defines 读取器 defines_military.h 表 NNavy 键 WAR_SCORE_GAIN_FOR_SUNK_SHIP_MANPOWER_FACTOR |
| 0x14096ACD0 | defines 读取器 defines_military.h 表 NNavy 键 WAR_SCORE_GAIN_FOR_SUNK_SHIP_PRODUCTION_COST_FACTOR |
| 0x14096AF90 | defines 读取器 defines_military.h 表 NNavy 键 XP_GAIN_FACTOR |
| 0x140980A80 | defines 读取器 defines_game.h 表 NProduction 键 ANNEX_CONVOYS_RATIO |
| 0x1409816E0 | defines 读取器 defines_game.h 表 NProduction 键 BASE_FACTORY_EFFICIENCY_ARCHETYPE_CHANGE_FACTOR |
| 0x1409818F0 | defines 读取器 defines_game.h 表 NProduction 键 BASE_FACTORY_EFFICIENCY_BALANCE_FACTOR |
| 0x140981F20 | defines 读取器 defines_game.h 表 NProduction 键 BASE_FACTORY_EFFICIENCY_PARENT_CHANGE_FACTOR |
| 0x140982760 | defines 读取器 defines_game.h 表 NProduction 键 BASE_FACTORY_SPEED_MIL |
| 0x140982B80 | defines 读取器 defines_game.h 表 NProduction 键 BASE_FACTORY_START_EFFICIENCY_FACTOR |
| 0x140982D90 | defines 读取器 defines_game.h 表 NProduction 键 BASE_LAND_EQUIPMENT_CONVERSION_IC_COST_FACTOR |
| 0x1409832F0 | defines 读取器 defines_game.h 表 NProduction 键 BASE_NAVAL_EQUIPMENT_CONVERSION_IC_COST_FACTOR |
| 0x140983640 | defines 读取器 defines_game.h 表 NProduction 键 CAPITAL_SHIP_MAX_NAV_FACTORIES_PER_LINE |
| 0x140983900 | defines 读取器 defines_game.h 表 NProduction 键 CAPITULATE_FUEL_RATIO |
| 0x1409844B0 | defines 读取器 defines_game.h 表 NProduction 键 DEFAULT_MAX_NAV_FACTORIES_PER_LINE |
| 0x140984EE0 | defines 读取器 defines_game.h 表 NProduction 键 ENERGY_SCALING_COST_BY_FACTORY_COUNT |
| 0x1409850F0 | defines 读取器 defines_game.h 表 NProduction 键 EQUIPMENT_BASE_LEND_LEASE_WEIGHT |
| 0x140985300 | defines 读取器 defines_game.h 表 NProduction 键 EQUIPMENT_LEND_LEASE_WEIGHT_FACTOR |
| 0x140985510 | defines 读取器 defines_game.h 表 NProduction 键 EQUIPMENT_MODULE_ADD_XP_COST |
| 0x140985B40 | defines 读取器 defines_game.h 表 NProduction 键 EQUIPMENT_MODULE_REPLACE_XP_COST |
| 0x140985D50 | defines 读取器 defines_game.h 表 NProduction 键 FLOATING_HARBOR_MAX_NAV_FACTORIES_PER_LINE |
| 0x140986220 | defines 读取器 defines_game.h 表 NProduction 键 INITIAL_ALLOWED_FACTORY_RATIO_FOR_REPAIRS |
| 0x140986570 | defines 读取器 defines_game.h 表 NProduction 键 LEND_LEASE_DELIVERY_TOTAL_DAYS |
| 0x140986A40 | defines 读取器 defines_game.h 表 NProduction 键 LICENSE_EQUIPMENT_SPEED_NOT_FACTION |
| 0x140986C50 | defines 读取器 defines_game.h 表 NProduction 键 LICENSE_EQUIPMENT_SPEED_NO_LICENSE |
| 0x1409876A0 | defines 读取器 defines_game.h 表 NProduction 键 MAX_CIV_FACTORIES_PER_LINE |
| 0x140987960 | defines 读取器 defines_game.h 表 NProduction 键 MAX_EQUIPMENT_RESOURCES_NEED |
| 0x140987E30 | defines 读取器 defines_game.h 表 NProduction 键 MAX_MIL_FACTORIES_VISIBLE_FOR_MIL_EQUIPMENT_LINE |
| 0x140988040 | defines 读取器 defines_game.h 表 NProduction 键 MILITARY_FACTORY_COHERENCY_BONUS |
| 0x140988910 | defines 读取器 defines_game.h 表 NProduction 键 MIN_FIELD_TO_TRAINING_MANPOWER_RATIO |
| 0x140988B20 | defines 读取器 defines_game.h 表 NProduction 键 MIN_LAND_EQUIPMENT_CONVERSION_RESOURCE_COST_FACTOR |
| 0x1409893D0 | defines 读取器 defines_game.h 表 NProduction 键 MIN_POSSIBLE_TRAINING_MANPOWER |
| 0x140989C10 | defines 读取器 defines_game.h 表 NProduction 键 PRODUCTION_RESOURCE_LACK_PENALTY |
| 0x140989E20 | defines 读取器 defines_game.h 表 NProduction 键 RAILWAY_GUN_MAX_MIL_FACTORIES_PER_LINE |
| 0x14098A2F0 | defines 读取器 defines_game.h 表 NProduction 键 RESOURCE_PENALTY_WARNING_CRITICAL_RATIO |
| 0x14098A500 | defines 读取器 defines_game.h 表 NProduction 键 RESOURCE_TO_ENERGY_COEFFICIENT |
| 0x14098B090 | defines 读取器 defines_project.h 表 NProject 键 BASIC_RESEARCH_TECHNOLOGY_BONUS_FACTOR |
| 0x14098B6A0 | defines 读取器 defines_project.h 表 NProject 键 BREAKTHROUGH_DAILY_ROCKET_SITE_GAIN |
| 0x14098C1A0 | defines 读取器 defines_project.h 表 NProject 键 DAYS_TO_REMOVE_SCIENTIST |
| 0x14098C9E0 | defines 读取器 defines_project.h 表 NProject 键 DEFAULT_PROJECT_COMPLETION_SCIENTIST_EXPERIENCE_GAIN |
| 0x14098CCA0 | defines 读取器 defines_project.h 表 NProject 键 DEFAULT_STOP_PROJECT_DAYS |
| 0x14098CF60 | defines 读取器 defines_project.h 表 NProject 键 DISMANTLE_FACILITY_DAYS |
| 0x14098D220 | defines 读取器 defines_project.h 表 NProject 键 FACILITY_SUPPLY_WARNING_RED_RATIO |
| 0x14098D570 | defines 读取器 defines_project.h 表 NProject 键 ITERATION_REWARD_DEFAULT_WEIGHT |
| 0x14098DE40 | defines 读取器 defines_project.h 表 NProject 键 NEEDED_SUPPLY_FOR_FULL_SPEED_PROJECT |
| 0x14098E100 | defines 读取器 defines_project.h 表 NProject 键 PROJECT_CAPTURE_BREAKTHROUGH_PROGRESS |
| 0x14098E7A0 | defines 读取器 defines_project.h 表 NProject 键 PROJECT_CAPTURE_GAIN_RATIO |
| 0x14098F920 | defines 读取器 defines_project.h 表 NProject 键 SCIENTIST_INJURED_FACTOR |
| 0x14098FE80 | defines 读取器 defines_project.h 表 NProject 键 SCIENTIST_SKILL_LEVEL_THRESHOLDS |
| 0x140990090 | defines 读取器 defines_project.h 表 NProject 键 SUPPORTIVE_SCIENITST_PROGRESS_BONUS |
| 0x1409B48D0 | defines 读取器 defines_game.h 表 NTechnology 键 BASE_YEAR_AHEAD_PENALTY_FACTOR |
| 0x1409B5320 | defines 读取器 defines_game.h 表 NTechnology 键 LICENSE_PRODUCTION_TECH_BONUS |
| 0x1409B5530 | defines 读取器 defines_game.h 表 NTechnology 键 MAX_SUBTECHS |
| 0x1409B5740 | defines 读取器 defines_game.h 表 NTechnology 键 MAX_TECH_SHARING_BONUS |
| 0x1409A3B60 | defines 读取器 defines_supply.h 表 NSupply 键 ALERT_VERY_LOW_SUPPLY_LEVEL |
| 0x1409A3EB0 | defines 读取器 defines_supply.h 表 NSupply 键 ARMY_MAX_SUPPLY_RATIO_GAIN_PER_HOUR |
| 0x1409A4170 | defines 读取器 defines_supply.h 表 NSupply 键 ARMY_SUPPLY_RATIO_SPEED_GAIN_PER_HOUR |
| 0x1409A4430 | defines 读取器 defines_supply.h 表 NSupply 键 ARMY_SUPPLY_RATIO_STARTING_GAIN |
| 0x1409A46F0 | defines 读取器 defines_supply.h 表 NSupply 键 AVAILABLE_MANPOWER_STATE_SUPPLY |
| 0x1409A4BC0 | defines 读取器 defines_supply.h 表 NSupply 键 BASE_ARMY_SUPPLY_MULT_FOR_TRUCK_BUFFER |
| 0x1409A56C0 | defines 读取器 defines_supply.h 表 NSupply 键 BASE_SUPPLY_MULT_FOR_TRUCK_MIN_BUFFER |
| 0x1409A5980 | defines 读取器 defines_supply.h 表 NSupply 键 BASE_TRAIN_HP |
| 0x1409A5C40 | defines 读取器 defines_supply.h 表 NSupply 键 BASE_TRUCK_HP |
| 0x1409A6CC0 | defines 读取器 defines_supply.h 表 NSupply 键 CAPITAL_SUPPLY_BASE |
| 0x1409A6F80 | defines 读取器 defines_supply.h 表 NSupply 键 CAPITAL_SUPPLY_CIVILIAN_FACTORIES |
| 0x1409A7240 | defines 读取器 defines_supply.h 表 NSupply 键 CAPITAL_SUPPLY_DOCKYARDS |
| 0x1409A8580 | defines 读取器 defines_supply.h 表 NSupply 键 ESTIMATED_DIVISION_WEIGHT_FOR_SUPPLY_ESTIMATIONS_GUI |
| 0x1409A8A50 | defines 读取器 defines_supply.h 表 NSupply 键 FLOATING_HARBOR_BASE_DURATION |
| 0x1409A8FD0 | defines 读取器 defines_supply.h 表 NSupply 键 FLOATING_HARBOR_DECAY_MAX_AIR_BONUS |
| 0x1409A91E0 | defines 读取器 defines_supply.h 表 NSupply 键 FLOATING_HARBOR_DECAY_MAX_AIR_PENALTY |
| 0x1409A9A20 | defines 读取器 defines_supply.h 表 NSupply 键 FLOATING_HARBOR_DURATION_RATIO_AT_MIN_HP |
| 0x1409A9D70 | defines 读取器 defines_supply.h 表 NSupply 键 FLOATING_HARBOR_INITIAL_SUPPLY_FLOW |
| 0x1409AA2F0 | defines 读取器 defines_supply.h 表 NSupply 键 FLOATING_HARBOR_STARTING_PENALTY_PER_PROVINCE |
| 0x1409AA5B0 | defines 读取器 defines_supply.h 表 NSupply 键 INFRA_TO_SUPPLY |
| 0x1409AA7C0 | defines 读取器 defines_supply.h 表 NSupply 键 LOCAL_NODE_BASE_SUPPLY_ADD |
| 0x1409AAD40 | defines 读取器 defines_supply.h 表 NSupply 键 MIN_DIFF_FOR_AUTO_UPDATING_EXISTING_RAILWAYS |
| 0x1409AB000 | defines 读取器 defines_supply.h 表 NSupply 键 MIN_SURRENDER_LIMIT_TO_MOVE_SUPPLY_CAPITAL |
| 0x1409AB2C0 | defines 读取器 defines_supply.h 表 NSupply 键 MIN_TRAIN_REQUIREMENT |
| 0x1409ABB90 | defines 读取器 defines_supply.h 表 NSupply 键 NAVAL_BASE_FLOW |
| 0x1409ABE50 | defines 读取器 defines_supply.h 表 NSupply 键 NAVAL_BASE_INITIAL_SUPPLY_FLOW |
| 0x1409AC110 | defines 读取器 defines_supply.h 表 NSupply 键 NAVAL_BASE_STARTING_PENALTY_PER_PROVINCE |
| 0x1409AC690 | defines 读取器 defines_supply.h 表 NSupply 键 NAVAL_FLOW_PER_LEVEL |
| 0x1409AD450 | defines 读取器 defines_supply.h 表 NSupply 键 NODE_INITIAL_SUPPLY_FLOW |
| 0x1409AD710 | defines 读取器 defines_supply.h 表 NSupply 键 NODE_STARTING_PENALTY_PER_PROVINCE |
| 0x1409AD9D0 | defines 读取器 defines_supply.h 表 NSupply 键 NON_CORE_MANPOWER_STATE_SUPPLY |
| 0x1409AE420 | defines 读取器 defines_supply.h 表 NSupply 键 RAILWAY_CONVERSION_COOLDOWN |
| 0x1409AE9A0 | defines 读取器 defines_supply.h 表 NSupply 键 RAILWAY_CONVERSION_COOLDOWN_CORE |
| 0x1409AF1E0 | defines 读取器 defines_supply.h 表 NSupply 键 RAILWAY_FLOW_PER_LEVEL |
| 0x1409AF4A0 | defines 读取器 defines_supply.h 表 NSupply 键 RAILWAY_MIN_FLOW |
| 0x1409AF760 | defines 读取器 defines_supply.h 表 NSupply 键 RIVER_RAILWAY_LEVEL |
| 0x1409AFA20 | defines 读取器 defines_supply.h 表 NSupply 键 STORED_SUPPLY_CONSUMPTION_RATE_FACTOR |
| 0x1409AFCE0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_BASE_MULT |
| 0x1409AFEF0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_DISRUPTION_DAILY_RECOVERY |
| 0x1409B0100 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_FLOW_DIST_LOGISTICS_FALLOFF_K |
| 0x1409B03C0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_FLOW_DIST_LOGISTICS_FALLOFF_MIDPOINT |
| 0x1409B09D0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_FLOW_DIST_LOGISTICS_FALLOFF_SCALAR |
| 0x1409B0C90 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_FLOW_DROP_REDUCTION_AT_MAX_INFRA |
| 0x1409B1420 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_FROM_DAMAGED_INFRA |
| 0x1409B1BB0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_HUB_MOTORIZATION_MARGINAL_EFFECT_DECAY |
| 0x1409B1E70 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_NODE_MIN_SUPPLY_THRESHOLD |
| 0x1409B2130 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_PATH_MAX_DISTANCE |
| 0x1409B23F0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_POINTS_PER_TRAIN |
| 0x1409B26B0 | defines 读取器 defines_supply.h 表 NSupply 键 SUPPLY_THRESHOLD_FOR_ARMY_ATTRITION |
| 0x1409B3590 | defines 读取器 defines_supply.h 表 NSupply 键 TRUCK_ATTRITION |
| 0x1409B3850 | defines 读取器 defines_supply.h 表 NSupply 键 TRUCK_ATTRITION_FACTOR |
| 0x1409B3B10 | defines 读取器 defines_supply.h 表 NSupply 键 TRUCK_DISTANCE_FACTOR_FOR_REINFORCEMENT_SPEED |
| 0x1409B3DD0 | defines 读取器 defines_supply.h 表 NSupply 键 TRUCK_HP_PER_ARMOR |
| 0x1409A1710 | defines 读取器 defines_sound.h 表 NSound 键 ABILITY_GENERIC_SOUND_NAME |
| 0x1409A1B30 | defines 读取器 defines_sound.h 表 NSound 键 BATTLE_SOUND_INIT_RADIUS |
| 0x1409A2160 | defines 读取器 defines_sound.h 表 NSound 键 HEIGHT_SOUND_CATEGORY |
| 0x1409A2370 | defines 读取器 defines_sound.h 表 NSound 键 HEIGHT_SOUND_MAX_ALTITUDE |
| 0x1409A2790 | defines 读取器 defines_sound.h 表 NSound 键 HEIGHT_SOUND_MIN_ALTITUDE |
| 0x1409A2BB0 | defines 读取器 defines_sound.h 表 NSound 键 VOICE_OVER_CATEGORY |
| 0x1409A2DC0 | defines 读取器 defines_sound.h 表 NSound 键 VOICE_OVER_COOL_DOWN |

#### 4.26.62 静态资源访问层define 注册 functor 族（1 函）

| VA | 语义/证据 |
|---|---|
| 0x140754190..0x1409A1500 | NDefines::CDefineRegistryHelper 读取器族（700 个模板实例, 逐 define 从 Lua 表读值; 逐 VA 见 findings/cov_full/_book_inbook.tsv） |
