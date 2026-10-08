

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
| 8 | lexerhelper (sub_1415A2BF0 族) | token 流后处理助手 (与词法表无关): `id = <值>` 赋值捕获 walker (重复捕获 assert; 驱动 sub_1415A2590; 典型消费 = 存档/配置块 id 提取) |

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

#### 4.26.11a 地图建筑装载域 (mapbuildings.cpp 5 函; map/buildings.txt 与 72B 实例)

清册 (5/5 函体内含 mapbuildings.cpp 路径锚): LoadBuildings sub_141671C10 (1409, 全 throw 组) /
SaveBuildings sub_1416748D0 (818, `;` CSV 写回) / LoadMeshHandles sub_141675750 (569) /
UpdateInstanceEntity sub_141676450 (302) / SetOrder sub_1416756C0 (28)。

**map/buildings.txt 行格式** (定案, 解析器断言 + 原盘逐列对拍双证): `州id;建筑名;x;y;z;rotation;海域id`
7 字段分号 CSV; 像素坐标对 = (x, z)。is_port 行 f6 = 海域 id → 省图形记录+200; 湖泊 = 同记录+210
bit1; 特例行 f6 = 输出省 id 存实例+52 (SaveBuildings 写回前解析)。

**72B 建筑地图实例** (书内此前无此对象; 定案):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | u32 | def id (spawn def +88 自身 id, 1-based) |
| +4 | u32 | 群组 id (357 = null 哨兵, 与 SLevelMax group_by 同源) |
| +8 | 句柄 | 网格缓存 |
| +16 | 实体 | 3D 实体句柄 |
| +24 | u8 | 特例旗 (floating_harbor) |
| +28 | u8 | Order = 同州/省同 def 堆叠序号 (装载计数直写; :513 上限断言) |
| +32..+44 | f32×5 | xyz + rotation |
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
(1=省建/0=州建) / +40 MSVC 串名称 / +88 自身 id。

未决: SaveBuildings 写回行列序 (asm 级) / 网格变体打分与 mgr+24/db+40 双句柄表关系 /
E2 双容器活体对拍 / aEntity_0 串本体。

#### 4.26.11b buildingdb.cpp 派生类别面 (CBuildingDatabase vtable[2] 重建器; 3 巨函闭环)

清册 (3/3 函体内含 buildingdb.cpp 路径锚): 派生类别表全量重建器 0x140684870 (1249,
**CBuildingDatabase vtable = 0x1427E4190 5 槽, 槽[2] = 本函**) / spawn point 生成与登记
0x140686280 (328) / sp 链桶索引构建 0x140687110 (167, assert :394 "AllSpawnPoints.GetSize()
>= AllBuildings.GetSize()")。

**类别面全景** (定案): 25 张内联类别表 (谓词→偏移逐项成表, §4.34.21 AI 八表全在其内) +
6 wrapper 表 (PE 机器码单谓词直证, 5 张与内联镜像) + +904 未裁 + +40 链桶。**六特名槽**:
+928 supply_node (token 0x4CBE) / +936 rail_way (0x4CC1) / +944 infrastructure (0x2FAB) /
+952 naval_base (0x31F6) 按 token; +960 arms_factory / +968 industrial_complex 按 stricmp。
缺省告警 (:584-:609) + null 模板兜底 (null_object.h 单例 sub_140686BF0; dockyard/bunker/
coastal_bunker/synthetic_refinery 串锚)。

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
