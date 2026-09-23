> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.19 本地化绑定 / 表达式系统族

> 四个**互相独立**、共同构成 loc 运行时的子系统。全部**非 idb 路线** (loc 文本装载走
> 语言管理器 `qword_14332EC80` + `sub_14224A4E0`)。
>
> ⚠ **`[...]` 内嵌表达式 ≠ `CExpression`**: 前者 (子系统 A) 住
> `localization_objects/textbase.cpp`; 后者 (子系统 C) 是 trigger `value`/`var` 的
> 脚本数学表达式, 住 `script_math.cpp`。二者无任何调用关系 — 最易混淆点。

| # | 子系统 | 根类 | 全局槽 | 一句话 |
|---|---|---|---|---|
| A | loc 文本求值 / `[...]` 内嵌表达式 | CContextLocalizationText | 无单例 (每文本一份) | 扫 `[` `]`, 按 `.` 分段, 逐段查 scope promotion 表与 loc command 表, 产出串 |
| B | bindable localization | CBoundLocalization + CFormattedLocalization | 验证器 0x1435BA060 | 解析 `localization_key = {...}` 块树, 参数 `$ARG$` 递归求值 |
| C | 脚本数学表达式 | NScript::NMath::CExpression | 无 (嵌 trigger) | 216B/操作数 数组; 操作数可引用命名集合 |
| D | 脚本常量 / 命名集合 | NScript::CConstant / CNamedCollection (+ 各自 Database) | qword_14332F020 / qword_14332EED8 | `common/script_constants` / `common/collections` / `common/script_enums.txt` 的运行时形态 |

**族指纹 (定案)**: 本族 6 类 CPersistent 但 **[2] writer 全为 guard_nop 空桩 (全族不入存档)**,
且把 **[3] 从标准 Load wrapper (sub_1424BE690) 换成自定解析器、[4] 退化为
sub_1424BEC40 (= `return sub_1424C2060(a2)`, "Unexpected token" 报错桩)** —
即 §4.00.1 所记「wrapper 自定类」形态的第三群实例 (与 CAssetFactoryParticle /
CBrowserType 同族)。

| 类 | [1] | [2] | [3] | [4] |
|---|---|---|---|---|
| CBoundLocalization | 0x1424BEC50 | 0x14012A2C0 | 0x1423A5DA0 | 0x1424BEC40 |
| CFormattedLocalization | 0x1424BEC50 | 0x14012A2C0 | 0x1423A8DF0 | 0x1424BEC40 |
| NScript::NMath::CExpression | 0x1424BEC50 | 0x14012A2C0 | 0x14141D1B0 | 0x1424BEC40 |
| NScript::CConstant | 0x1424BEC50 | 0x14012A2C0 | 0x140AA7200 | 0x1424BEC40 |
| NScript::CCollection | 0x1424BEC50 | 0x14012A2C0 | 0x140A1E050 | 0x1424BEC40 |
| NScript::CNamedCollection | 0x1424BEC50 | 0x14012A2C0 | 0x1424BE620 (CDatabaseObject 变体) | 0x1424BEC40 |
| CConstantDatabase | 0x14015CC20 | 0x14012A2C0 | 0x14012A2C0 | 0x14012A2C0 |
| CNamedCollectionDatabase | 0x14015CF60 | 0x14012A2C0 | 0x14012A2C0 | 0x14012A2C0 |
| CRandomLocList (对照, 标准形态) | 0x1424BEC50 | 0x14012A2C0 | 0x1424BE690 | 0x140AAC5B0 |

> ⚠ **serfam 指纹盲区**: `ref/serfam_1193.txt` 的判据 = `[1]==0x1424BEC50 && [3]==0x1424BE690`,
> 本族 [3] 被覆写故**全族不命中** (CRandomLocList* 是唯一标准形态故入表) —
> **serfam 对「[3] 自定 Load」族结构性失明**。
> 两个 Database 类的 [1] 由 TGameItemDatabase 层拥有 (0x14015CC20 / 0x14015CF60 = 各自 dtor),
> 不参与 CPersistent 指纹。

#### 4.19.1 族类清单

| RTTI 名 | vtable | 基链 | sizeof | ctor | [3] 自定 Load | 全局单例 |
|---|---|---|---|---|---|---|
| NPdxLoc::CBoundLocalization | 0x142718230 | CBoundLocalization@0 + CPersistent@0 (2 基, mdisp 0) | 32 | sub_140147000 | sub_1423A5DA0 | 无 |
| NPdxLoc::CFormattedLocalization | 0x1427E4068 | 同上 | 48 | sub_1423A7EA0 | sub_1423A8DF0 | 无 |
| CContextLocalizationText | 0x1427DE358 | CContextLocalizationText@0 + CTextBase@0 | 912 | sub_1410E2160 | — (非 CPersistent) | 无 |
| NScript::NMath::CExpression | 0x142765DF0 | CExpression@0 + CPersistent@0 | 56 | sub_140324DE0 | sub_14141D1B0 | 无 |
| CCheckExpression | 0x1427CF258 | CCheckExpression@0 + CTrigger@0 + CPdxArray@8 + CTriggerDataMembers@32 + CProfiledScopeObject@0 (5 基) | 144 | sub_1405271D0 | — (trigger 族) | — |
| CDebugMathExpression | 0x1427CF318 | 同上 | 144 | sub_140527220 | — | — |
| NScript::CConstant | 0x14271B5D0 | CConstant@0 + CPersistent@0 | 64 | 见 [3] | sub_140AA7200 | 无 (库内条目) |
| NScript::CConstantDatabase | 0x14271B680 | + CPersistentReloadableGameItemDatabase + TGameItemDatabase (3 基) | 128 | 内联于 sub_14018BB20 | — | **qword_14332F020** |
| NScript::CCollection | 0x142719888 | CCollection@0 + CPersistent@0 | 376 | sub_140147090 | sub_140A1E050 | 无 (基类) |
| NScript::CNamedCollection | 0x1427198D8 | + CDatabaseObject + CPersistentWithToken + CPersistent (4 基) | 408 | sub_140130230 | sub_1424BE620 | 无 (库内条目) |
| NScript::CNamedCollectionDatabase | 0x142719998 | + CPersistentReloadableGameItemDatabase + TGameItemDatabase (3 基) | 128 | sub_1401720E0 | — | **qword_14332EED8** |
| CRandomLocList | 0x1429423D0 | CRandomLocList@0 + CPersistent@0 | — | — | 标准 0x1424BE690 | 无 |
| CRandomLocListMember | 0x142942380 | CRandomLocListMember@0 + CPersistent@0 | 288 | — | 标准 | 无 |

> 登记链 (定案): 主内容注册函数 `sub_14018BB20` 内 `sub_14011D970(&v405, "common/script_constants", 23)`
> 与 `common/script_enums.txt`; `CNamedCollectionDatabase` 由 `sub_1401720E0()` 建、目录 `common/collections`
> (经 `sub_14011E130(v494, "common/collections")` → `sub_140189500(db, dir, ".txt")`); 每步后
> `sub_14222E270(a1, 37, <step>, 102, 0)` 进度上报。

#### 4.19.2 CContextLocalizationText (912B) — `[A.B.C]` 求值

主虚表 0x1427DE358 (8 槽):

| 槽 | 地址 | 语义 |
|---|---|---|
| [0] | 0x1410E2C40 | **命令分派器** |
| [1] | 0x1410E4A50 | **promotion (scope 提升) 解析器** |
| [2] | 0x14061AF60 | IsEmpty (`return *(a1+8*type+16) == 0`) |
| [3] | 0x1410E44B0 | — |
| [4] | 0x1410E37E0 | — |
| [5] | 0x1410E4430 | — |
| [6] | 0x1410E4960 | **保存现场** (把 +8..+152 与 +888 拷到 +160..+304 与 +896) |
| [7] | 0x1410E5C40 | **恢复现场** (反向) |

**4 条平行的 18 槽函数指针数组** (ctor sub_1410E2160 的实体; `+888 − +312 = 576 = 4 × 144 = 4 × 18 × 8`),
索引 = **scope 类型 id**:

| 数组 | 基址 | 槽语义 |
|---|---|---|
| A | +312 + 8·i | promotion 表 getter → 返回 `{int count; const 描述符* table}` |
| B | +456 + 8·i | 应用 promotion 回调 `fn(scopeObj, this, id)` |
| C | +600 + 8·i | 命令集 getter → 同 `{count, table}` 形 |
| D | +744 + 8·i | `?var` / 属性取值实现 (guard_nop = 该类型无) |

**A / C 数组全表** (实测; `ret0` = 该类型无此表):

| i | A[i] (+312+8i) promotion | C[i] (+600+8i) 命令 |
|---|---|---|
| 0 | sub_141A969B0 {4, 0x14338BEB0} | sub_141A83D30 (ret 0) |
| 1 | sub_141A93FF0 {5, 0x14338BD90} | sub_141A94590 {4, 0x14338BDE0} |
| 2 | sub_141A945A0 {15, 0x14338BCA0} | sub_141A94590 {4, 0x14338BDE0} |
| **3** | sub_141A8E6A0 {4, 0x14338B8B0} | **sub_141A90BE0 {59, 0x14338B8F0} = Country 命令全表** |
| 4 | sub_141A98620 {3, 0x14338BF60} | sub_141A988D0 {4, 0x14338BF90} |
| 5 | sub_141A83D30 (ret 0) | sub_141A83D30 (ret 0) |
| 6 | sub_141A82ED0 {1, 0x14338B680} | sub_141A83B30 {18, 0x14338B690} |
| 7 | sub_141A9A600 {1, 0x14338BFE0} | sub_141A9B030 {12, 0x14338BFF0} |
| 8 | sub_141A85C50 {1, 0x14338B7C0} | sub_141A86600 {13, 0x14338B7D0} |
| 9 | sub_141A83D30 (ret 0) | sub_141A83D30 (ret 0) |
| 10 | sub_141401400 {6, 0x14338A3F0} | sub_141401480 {1, 0x14338A450} |
| 11 | sub_141A957A0 {1, 0x14338BE50} | sub_141A95880 {1, 0x14338BE60} |
| 12 | sub_141A95F10 {2, 0x14338BE78} | sub_141A960C0 {1, 0x14338BE98} |
| 13 | sub_141A976B0 {1, 0x14338BF38} | sub_141A97840 {1, 0x14338BF48} |
| 14 | sub_141A83D30 (ret 0) | sub_141A83E70 {1, 0x14338B7B0} |
| 15 | sub_141A97120 {2, 0x14338BF08} | sub_141A97250 {1, 0x14338BF28} |
| 16 | sub_141A83D30 (ret 0) | sub_141A98CC0 {1, 0x14338BFD0} |
| 17 | sub_141A95230 {1, 0x14338BE20} | sub_141A95320 {1, 0x14338BE30} |

> **slot 3 = Country scope 类型 (定案)**: C[3] = 59 条 `Get*` Country 命令全表, A[3] = 4 条 promotion;
> slot 1/2 共用同一 4 命令表 (0x14338BDE0)。
> B 数组 slot 5/9/14/16 = guard_nop (无提升), 与 A/C 同槽的 `ret 0` 一一对应 ⇒ 三处一致 = 该 scope 类型无 promotion 也无命令。
> D 数组 slot 0/5/9 = guard_nop, 其余为取值实现 (部分与 C 的 getter 成对)。
> **每 scope 类型一套 (表 getter, 提升回调, 命令 getter, 取值实现) 四元组** — 这是引擎
> 「scope 类型 → 可用 loc 命令/promotion」的**唯一真源**。

**求值入口链** (sub_1412CED60, 递归):

| 步骤 | 动作 |
|---|---|
| ① | `strchr '[' … strchr ']'` 切出 `[...]` 段 |
| ② | 段内按 `.` 切分 → 16B 组件数组 {ptr, len} |
| ③ | 组件 > 1 → 逐组件调 `(*(vtbl+8))(this, comp)` (slot [1] scope 提升解析), 再 `(**vtbl)(this, out, comp)` (slot [0] 命令分派) |
| ④ | 段形如 `(xxx)` → sub_1412CE980 (函数/带参形式) |
| ⑤ | 段形如 `?xxx` → sub_1412CF2B0 (条件/变量形式; 报 "invalid scope for var. Key %s") |
| ⑥ | 递归 sub_1412CED60(this, out, tmp, depth+1, 0) — 嵌套 `[...]` |

**描述符格式 (定案)**: 单元 = 16B `{const char* name; int32 id; int32 pad}` —
`.rdata` 从 `0x1430B4B30` 起连续排布, 16B/项, 首字段是指向裸 C 串的指针 (非 MSVC string 对象)。

| 段 | 内容 |
|---|---|
| 0x1430B4B30 起 | Country 命令名 59 条 ("GetName" id=0 … id=58 "GetBopTrendTextIcon") |
| 紧接 | scope 类型名: "Player" id=0 / "This" id=1 / "Root" id=2 / "From" id=3 / "Prev" id=4 / "State" id=5 / "Country" id=6 / "Character" id=7 / "Combatant" id=8 / "Ace" id=9 / "Operation" id=10 … |

**运行期表**: `.data` **28 张** (0x14338B680 … 0x14338BFF0 / 0x14338A3F0 / 0x14338A450);
注册器组 4 群已定位 (`sub_14007FE80` 59 条 Country 命令 / `sub_1400802A0` 4 条 /
`sub_1400802F0` 15 条 / `sub_1400804D0` 4 条), 其余 24 张注册器组待裁;
注册表本体 `unk_1430B26C0` 两级 map (104B 单元, 子表在 entry+72 / entry+40)。

**loc formatter 注册表**: `unk_1430BEF60` (64B 桶), 插入 `sub_1423A9030` / 查表 `sub_1423A8920`,
描述符 {fn, fn, fn}, 静态初始化约束; formatter 全集未数完 (至少 9 个注册点 — 未决)。

#### 4.19.3 CBoundLocalization (32B) / CFormattedLocalization (48B)

**CBoundLocalization 字段表** (32B):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPdxInlineBufArray\<SLocEntry,14\> {data@8, cap@16, count@20, alloc@24} | **SLocEntry 数组** (条目 72B, 内联缓冲 14 项) | sub_1423A5380 / sub_1423A5880 逐 72B 拷贝; 分配器 `CPdxHybridInlineBufferAllocator<SLocEntry,14,int>` vt 0x142B5CA38 |
| +24 | 分配器对象* | &off_143085170 (全局默认分配器) | sub_140147000 尾部 |

**SLocEntry (72B, 非独立 RTTI 类)** = 48B 内嵌 CFormattedLocalization + 24B 子容器:

| 条目内偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +0 | CFormattedLocalization vt | 0x1427E4068 | sub_14067EF90 写 vftable |
| +8 | MSVC 串 (SSO 32B, cap@+24) | 字面量 / 格式串 / 值 | sub_14067EF90: `*(_OWORD *)(v7+8)=0` + cap=15 哨兵 |
| +40 | u8 | 变体 tag (0=串 / 1=二值 / 2=u32 / −1=空) | 同 CFormattedLocalization |
| +48 | CPdxInlineBufArray\<SArgument,11\> {data@48, cap@56, count@60, alloc@64} | **SArgument 数组** (元素 88B, 内联 11 项) | sub_14067EF90 尾 `sub_14011DF40((void*)(v7+48))`; 分配器 vt 0x142B40B8 |

> 48 + 24 = 72 ✓。**"Missing localization key" 判据 (定案)**: `entry+40 == 0 && entry+24 == 0`
> — 即 tag 为「串」变体且串 cap 为 0 (空串)。

**SArgument (88B, 非独立 RTTI 类)** = 32B 名字串 + 48B CFormattedLocalization + 8B 尾:

| 条目内偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +0 | MSVC 串 (SSO 32B, cap@+16) | **参数名 / 键名** | sub_1423A51C0 从 a2 移入 |
| +32 | CFormattedLocalization vt | 0x1427E4068 | `*(_QWORD *)(a1+32) = &…vftable'` |
| +40 | MSVC 串 (SSO 32B, cap@+56) | 值串 | sub_1423A51C0 |
| +72 | u8 | tag (同 §4.19.3 CFormattedLocalization) | — |
| +80 | u8 | 旗 | — |

> 32 + 48 = 80, 再 +8 = 88 ✓。**CBoundLocalization +8 装 SLocEntry (72B); SLocEntry +48 装
> SArgument (88B) = {键名, 值}** — 两个内联分配器名 (`SLocEntry,14` / `SArgument,11`)
> 与两个 stride 精确对应。

**CFormattedLocalization 字段表** (48B):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | 联合体 (tag@+40) | 载荷: tag=0 → MSVC 串 (SSO 32B, cap@+32) / tag=1 → 16B 值对 / tag=2 → u32 | 拷贝 ctor sub_1423A50D0 按 `*(a2+32)` 分三档 |
| +40 | u8 | **变体 tag**: 0=串 / 1=二值 / 2=u32 / −1=空 | sub_1423A50D0 / sub_1423A37A0 |
| +8 (tag=0) | MSVC 串 (SSO, cap@+32) | 字面量 / 格式串 | sub_1423A7EA0 → sub_1423A8920 |
| +8 (tag=2) | u32 | **formatter id** (见 §4.19.2 loc formatter 注册表) | sub_1423A8920 写 `*(u32*)(a1+8) = v49` |
| +8 (tag=1) | 16B 值对 | formatter 返回值 (两 qword) | sub_1423A37A0 |
| +24 (tag=1) | 16B 值对 | formatter 返回值 (两 qword) | sub_1423A37A0 |

**拷贝/移动族**: 拷贝 sub_1423A4FE0 / 移动 sub_1423A5050 / dtor sub_1423A52E0 (CBoundLocalization);
拷贝 sub_1423A50D0 / 内联构 sub_1423A51C0 (CFormattedLocalization)。验证器单例 = 0x1435BA060。

#### 4.19.4 NScript::NMath::CExpression (56B) 与表达式 trigger

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPdxArray\<SOperand\> {data@8, cap@16, count@20, alloc@24} | **操作数数组** (216B/项) | sub_14141D1B0 遍历 `*v2 + 216*idx` |
| +24 | 分配器对象* | &off_143085170 ×2 之一 | sub_140324DE0 |
| +32 | 第二容器 {…@32, cap@40, count@44, alloc@48} | 第二段 (指令/常量池), 由 sub_14141C0D0 填 | sub_14141D1B0 读 a1+32 |
| +48 | 分配器对象* | &off_143085170 ×2 之一 | sub_140324DE0 |
| +208 | i8 | **表达式状态 tag** (−1 = 未初始化 / 1 = 已解析) | sub_14032BA40 三步: 旧 tag≠−1 → 调 vt[0]; 置 −1; 调 ctor; 置 1 |

**SOperand 字段表** (216B, 非独立 RTTI 类):

| 操作数内偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +0 | u32 | **名字 token id** (FNV 输入) | sub_14141F030 |
| +8 | CNamedCollection* | **命名集合指针** (解析结果) | sub_14141F030 写回 |
| +208 | u8 | **操作数种类 tag**: 2 = 命名集合引用 (其余 = 字面量/变量) | sub_14141F030 跳过非 2 |

> 216 = 208 + 8, 与 CPdxArray 元素 stride 一致; 216B 内其余字段未展开 (未决)。

**表达式引用命名集合的求值链** (定案):

| 步 | 动作 |
|---|---|
| ① | `CExpression::reader sub_14141D1B0` (trigger 的 value/var 键解析时调用): 解析操作数 + 指令段; 扫操作数 (216B/项), 若 `byte@+208 == 2` → `sub_140AAB2E0(CExpression*)` |
| ② | `sub_140AAB2E0(a1)` = CNamedCollection 求值: `qword_14332F030` (RH 16B 桶) 存在 → `sub_140AAAB70(表, out, FNV(a1), &a1)`; 否则 → `sub_14141F030(a1)` 名字解析兜底 |
| ③ | `sub_14141F030(expr)`: 遍历操作数 (216B, +8 data / +20 count), 跳过 `byte@+208 != 2` 者, FNV(操作数+0) 查 `qword_14332EED8` (CNamedCollectionDatabase) RH (buckets@+56 / mask@+68 / 哨兵@+72) → 命中取 `entry+16` = CNamedCollection*, 写回操作数+8; 未命中 → 报 `"Failed to resolve named collection in math expression, defaulting to 0"` (script_math.cpp:383) + `sub_1403B80F0` + `sub_14140DDE0` + `+44 = 0` + `sub_14141C0D0(expr+32, 0, 0, −1)` 置空表达式 |
| ④ | `sub_14141C0D0(a1, op, a, b)` = 指令发射 (math_instructions.h:54 断言 `OperandA >= numeric_limits<int8>::min() && …`) |

**表达式 trigger 类**: `CCheckExpression` (vt 0x1427CF258) / `CDebugMathExpression` (vt 0x1427CF318),
均 CTrigger 后代 (5 基, 144B, 内联 CExpression@+88); 工厂 = `sub_1405271D0` / `sub_140527220`
(malloc 0x90 → sub_14054A090 → 写 vt → sub_14032CBD0(v1+11)); 注册入口 =
`CTriggerEntry<CCheckExpression>` (sub_14002E470) / `CTriggerEntry<CDebugMathExpression>` (sub_14002E4D0)。

| 键 | token | 落点 |
|---|---|---|
| tooltip | 146 | a1+512 串 |
| value | 776 | **sub_14032BA40()** = 重置内嵌 CExpression 并置 tag=1 (或对象块 → `(*(expr vt[3]))(expr, node)` = CExpression reader) |
| var | 14582 | 先 `(*(a1+88 vt[3]))` 再判 a1+97/98/99 三旗, 报 `"invalid left side variable"` |

> **sub_14032BA40** = CExpression 重用入口 (定案): 旧 tag ≠ −1 → 调 vt[0] 清理; 置 tag = −1;
> 调 ctor; 置 tag = 1。

#### 4.19.5 NScript::CConstant (64B) / CConstantDatabase (128B)

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPdxInlineBufArray\<SSchema::SEntry,25\> {data@8, cap@16, count@20, alloc@24} | schema 表 (元素 40B) | sub_140AA7EA0 逐 40B 拷贝; 分配器 vt 0x142942208 |
| +32 | MSVC 串 (SSO) | **常量名** (def 键名) | sub_14012CC60 |
| +48 | u32 | **值类型 tag / 序号** | sub_140AA76C0 = `*(u32*)(a1+48) = a2` |
| +56 | — | 预留 (ctor 清零, reader 未写) | — |

**SSchema::SEntry (40B)**: `+36` = 名 token (FNV, 键 `key`=220) / `+32`、`+33` = 旗
(键 `array`=15270) / `+0` = 内联子容器 (元素 40B, 递归)。
**常量文件首条必须是 `schema` (token 18061)**, 否则报
`"A constant must define a schema as first entry"` (script_constants.cpp)。

**CConstantDatabase (128B)**: TGameItemDatabase 标准形 {内联 RH 表 @+8/+16/+20/+24, +32 = 0, +40 串表}
+ CPersistentReloadableGameItemDatabase 层 {+56 = RH buckets*, +64 = 0, +68 = mask, +72 = 哨兵字节,
+76 = 1.06f 装填因子, +80/+88 = 0, +96 = 分配器 &off_143085170, +104 内联缓冲};
**+40 = 扩展名串 ".txt"** (定案)。条目解析 reader `sub_140AA7200`; 实际值由
`sub_140AA7EA0` (schema 表) + `sub_140AA81D0` (逐 SEntry) + `sub_140AA76C0` (`*(u32*)(a1+48) = 值类型`) 完成。
消费点 (全走 `qword_14332F020 + 56` RH 表 + mask `+68` + 哨兵 `+72`):
`sub_140546530` / `sub_140A1C4A0` / `sub_140326500` / `sub_14039DEC0`。
**CConstant ≠ defines** (两套独立系统)。

#### 4.19.6 NScript::CCollection (376B) / CNamedCollection (408B) / CNamedCollectionDatabase

**CCollection (376B)** — ctor sub_140147090 触达偏移全集 = {8, 16, 24, 32, 36, 40, 48, 312, 320, 328, 336, 344}:

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | u32 | 元素计数 | ctor 置 0 |
| +16 | qword | 预留 (清零) | ctor |
| +24 | CPdxInlineBufArray\<NCollection::COperator,16\> {data@24, cap@32, count@36, alloc@40} | **算子/元素数组** (内联 16 项) | ctor 置 `*(a1+24) = a1+49` (内联路径, 当分配器 vt[4] == sub_140161270 时) |
| +48 | 分配器对象 (264B) | `CPdxHybridInlineBufferAllocator<COperator,16,int>` vt 0x142719840; 尾 +312 = &off_143085170 | 48 + 264 = 312 ✓ |
| +320 | qword | 第二容器 data | ctor 置 0 |
| +328 | qword | 第二容器 cap | ctor 置 0 |
| +332 | u32 | 第二容器 count (推定, ctor 未显式置) | 容器四字段惯例 |
| +336 | 分配器对象* | &off_143085170 | ctor |
| +344 | 内嵌 NPdxLoc::CBoundLocalization (32B) | 集合的「绑定文本」伴随体 | sub_140147000(a1+344) |

> **sizeof = 344 + 32 = 376 (定案)** — 与 CNamedCollection 的 408 自洽
> (自有字段 +0..+31 + CCollection 376 = 408 = 0x198 = sub_140130230 的 malloc 尺寸)。
> 元素 = `NCollection::COperator`; 运算符体系含 `NCollection::VCOperator` /
> `VCOperatorPayloadStorage` 与键大小写策略 `USKeyCase`。

**CNamedCollection 字段表** (408B):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPersistentWithToken 基 (u32 token) | 名 token | 基类 mdisp 0 |
| +16 | u32 | 名 token 副本 | sub_140130230 |
| +24 | u8 | 有效旗 | ctor 置 0 |
| +32 | NScript::CCollection 内联体 (376B) | 集合本体 | sub_140147090(v14+32) |
| +80 | CPdxArray\<CNamedCollection*\> {data@80, cap@88, count@92, alloc@96} | **元素列表** (子集合指针数组) | ctor 尾 `*(*(a1+80) + 8*(*(a1+92))++) = v12` |

> **命名集合 = 名字 + 一个 CCollection (算子数组) + 一个子集合指针数组** (定案)。
> 名 token: FNV(名) → `*((u32*)v14 + 2)`。

**CNamedCollectionDatabase (128B)**: ctor sub_1401720E0; 单例 qword_14332EED8; 目录 `common/collections`;
RH 表 {buckets@+56, mask@+68, 哨兵@+72}, 命中取 `entry+16` = CNamedCollection*。

**集合 trigger/effect 族 (仅列名, 未深挖)**: `CCollectionContainsTrigger` / `CCollectionSizeTrigger` /
`CCountInCollectionTrigger` / `CAnyCollectionElementTrigger` / `CAllCollectionElementsTrigger` /
`CEveryCollectionElementEffect`。

#### 4.19.7 CRandomLocList / CRandomLocListMember

| 类 | sizeof | 字段 |
|---|---|---|
| CRandomLocList | — (19 槽 vt, 含 CPersistent 槽 [1]/[3]) | 由 reader sub_140AAC5B0 建: +8 = 成员容器 (sub_14031ECD0 追加) / +32 = 另一对象 (键 10647 `seed` → `(*(a1+32) vt[3])()`) |
| CRandomLocListMember | 288 | +8 = **CScriptableValue 内联体 248B** (经 `sub_141594360(v10+1, 0, 100000*v6)` 构) / +32+256 = CBoundLocalization 内联体 |

> reader `sub_140AAC5B0`: 键 `localization_key` (799) → `sub_1424C0AA0(a2, v22)` 读串;
> 否则把当前节点串作为**根 loc key** 存入 `sub_1423A51C0` (CFormattedLocalization 内联构),
> 再递归 `sub_1423A6200`。`v6 = sub_1424C4FE0(a2+48)` = 权重 (整数),
> `sub_141594360(v10+1, 0, 100000*v6)` = CScriptableValue(seed=0, base=权重×100000)。
> ⚠ 与 §4.31 已载的 `CRandomLocList` (0x1429423D0) 同族 — 该族此前只登记容器件, 成员件为本节补。
