

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

主vtable 0x1427DE358 (8 槽):

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
> D 数组 slot 0/5/9 = guard_nop, 其余为取值实现 (部分与 C 的 getter 成对); **D[3] = sub_141A8E6B0 = Country 59 命令取值实现** (switch 命令 id 分支出串, 全表 §4.19.2a)。
> **每 scope 类型一套 (表 getter, 提升回调, 命令 getter, 取值实现) 四元组** — 这是引擎
> 「scope 类型 → 可用 loc 命令/promotion」的**唯一真源**。

**求值入口链** (sub_1412CED60, 递归):

| 步骤 | 动作 |
|---|---|
| ① | `strchr '[' … strchr ']'` 切出 `[...]` 段 |
| ② | 段内按 `.` 切分 → 16B 组件数组 {ptr, len} |
| ③ | 组件 > 1 → 逐组件调 `(*(vtable+8))(this, comp)` (slot [1] scope 提升解析), 再 `(**vtable)(this, out, comp)` (slot [0] 命令分派) |
| ④ | 段形如 `(xxx)` → sub_1412CE980 (函数/带参形式) |
| ⑤ | 段形如 `?xxx` → sub_1412CF2B0 (条件/变量形式; 报 "invalid scope for var. Key %s") |
| ⑥ | 递归 sub_1412CED60(this, out, tmp, depth+1, 0) — 嵌套 `[...]` |

**描述符格式 (定案)**: 单元 = 16B `{const char* name; int32 id; int32 pad}` —
`.rdata` 从 `0x1430B4B30` 起连续排布, 16B/项, 首字段是指向裸 C 串的指针 (非 MSVC string 对象)。

| 段 | 内容 |
|---|---|
| 0x1430B4B30 起 | **scope 类型名 15 项** ("Player" id=0 / "This" id=1 / "Root" id=2 / "From" id=3 / "Prev" id=4 / "State" id=5 / "Country" id=6 / "Character" id=7 / "Combatant" id=8 / "Ace" id=9 / "Operation" id=10 / "Unit" id=11 / "IndustrialOrganisation" id=12 / "PurchaseContract" id=13 / "SpecialProject" id=14) — PE 直读 (§4.19.2a) |
| 紧接 | 日期命令表 (GetDateText / GetDate / GetYear / GetMonth) 与 Leader / GetName / Owner 等 promotion 描述符 |
| (.data) 0x14338B8F0 | **Country 命令描述符 59 条** — 运行期由注册器 sub_14007FE80 填充, 静态 PE 不可读 (命令名经 59 个注册函数内联 SSO 串取, §4.19.2a) |

**运行期表**: `.data` **28 张** (0x14338B680 … 0x14338BFF0 / 0x14338A3F0 / 0x14338A450);
注册器组 4 群已定位 (`sub_14007FE80` 59 条 Country 命令 / `sub_1400802A0` 4 条 /
`sub_1400802F0` 15 条 / `sub_1400804D0` 4 条), 其余 24 张注册器组待裁;
注册表本体 `unk_1430B26C0` 两级 map (104B 单元, 子表在 entry+72 / entry+40)。

**loc formatter 注册表**: `unk_1430BEF60` (64B 桶), 插入 `sub_1423A9030` / 查表 `sub_1423A8920`,
描述符 {fn, fn, fn}, 静态初始化约束; formatter 全集未数完 (至少 9 个注册点 — 未决)。

#### 4.19.2a Country scope 59 条 loc 命令取值实现 (sub_141A8E6B0 = D[3]; 定案)

sub_141A8E6B0 = CContextLocalizationText 的 **D[3]** (ctor sub_1410E2160 写 `*(a1+768) = &本函`; 768 = D 基址 744 + 8·3), 签名 `void (CCountry* a1, std::string* out, int cmd_id)`: 单一 switch(cmd_id) 分支出串, id 空间 = C[3] 的 59 条 (0..58), ≥59 静默空返。唯一调用点 = textbase.cpp var 求值分支 (tag → 国 (sub_140BB48F0) → 本函); 帧级频度 (决议栏 / tooltip / 事件文本每帧重算)。59 条命令由注册器 sub_14007FE80 逐槽注册 (59 个注册函数把 {命令名 SSO, 文档串} 写入 0x14338B8F0 + 16·i); 注册序 = 命令 id = case 序 (注册顺序 / case 语义 / 英文 loc 文件三重互证)。⚠ 命令名按二进制原文: **"GetLeader" / "GetAgency"** (非 wiki 通行名 GetLeaderName / GetAgencyName)。

**59 case 全表** (a1 = CCountry*; ps = *(cc+3984) CPolitics; party = *(ps+208) 执政党):

| id | 命令名 | 实现链 | 置信 |
|---|---|---|---|
| 0 | GetName | cc+16 name SSO (访问器伪名 get_srw_lock, §4.2) | 定案 |
| 1 | GetNameDef | cc+80 definite name (sub_1406F2F20) | 定案 |
| 2 | GetNameDefCap | 同 1 → sub_1424CBF40 首字母大写 | 定案 |
| 3 | GetAdjective | tag → 国 → cc+48 adjective (sub_140BB47B0) | 定案 |
| 4 | GetAdjectiveCap | 同 3 → 首字母大写 | 定案 |
| 5 | GetOldName | cc+144 prev_name (sub_1406F3910); 空 (size@cc+160 == 0) 回落 cc+16 | 定案 |
| 6 | GetOldNameDef | cc+208 prev_definite (sub_1406F3920); 空回 cc+80 | 定案 |
| 7 | GetOldNameDefCap | 同 6 → 首字母大写 | 定案 |
| 8 | GetOldAdjective | cc+176 prev_adjective (sub_1406F3900); 空回 cc+48 (sub_1406C00E0) | 定案 |
| 9 | GetOldAdjectiveCap | 同 8 → 首字母大写 | 定案 |
| 10 | GetLeader | cc+3984 → party+208 → party+124 计数门 → 首领袖 (sub_1411A3300) → sub_140FCB280 出名 | 定案 |
| 11 | GetRulingParty | sub_1411A45C0: party+104 default_flag 真 → 动态名 (party+32 属主 idx / party+24 组); 否则 party+40 静态名 | 定案 |
| 12 | GetRulingPartyLong | sub_1411A4570: 同 11 取 party+72 long_name | 定案 |
| 13 | GetRulingIdeology | party+24 CIdeologyGroup → group+24 名 (sub_140623700) → sub_1424CD6F0 全串小写 | 定案 |
| 14 | GetRulingIdeologyNoun | sub_141191630 名词形 (sub_140120040 推导) → 小写 | 高置信 |
| 15 | GetPartySupport | 遍历 ps+32 政党容器累加 party+136 popularity → sub_1424CB030 格式化 | 待裁 (求和条件) |
| 16 | GetLastElection | ps+152 CGregorianDate → sub_140533460, 格式串 " %d:00, %d %s, %d" | 定案 |
| 17 | GetManpower | sub_140CFC300 = cc+820 current + Σ州+2120 (§4.3.8 三口径之一) → sub_1424CA600 itoa | 定案 |
| 18 | GetFactionName | dip = cc+3976 → dip+656 CFaction → sub_140D8BB80 = fac+24 名; 空 → 局化 "NO_FACTION" | 定案 |
| 19 | GetFlag | tag 名 (sub_140BB4E70) + 0x12 标记字节构造旗标串 | 待裁 (字节序) |
| 20 | GetNameWithFlag | sub_140BB4C30(tag) = 「名带旗」串 | 定案 |
| 21 | GetCommunistParty | "communism" → sub_141A90ED0 查党 → 党 long_name | 定案 |
| 22 | GetDemocraticParty | "democratic" → 同 21 | 定案 |
| 23 | GetFascistParty | "fascism" → 同 21 | 定案 |
| 24 | GetNeutralParty | "neutrality" → 同 21 | 定案 |
| 25 | GetAgencyName | ag = *(cc+4032); *(ag+192) 真 → ag+128 名 SSO; 否则局化 "AGENCY_NAME" | 定案 |
| 26 | GetTag | sub_140BB4E70(cc+8) = gs+856 tag 表取 4 字符串 | 定案 |
| 27 | GetSheHe | 领袖 female → "EV_SHE" 否则 "EV_HE" | 定案 |
| 28 | GetSheHeCap | 同 27 → 首字母大写 | 定案 |
| 29 | GetHerHim | → "EV_HER" / "EV_HIM" | 定案 |
| 30 | GetHerHimCap | 同 29 → 首字母大写 | 定案 |
| 31 | GetHerHis | → "EV_HER" / "EV_HIS" | 定案 |
| 32 | GetHerHisCap | 同 31 → 首字母大写 | 定案 |
| 33 | GetHersHis | → "EV_HERS" / "EV_HIS" | 定案 |
| 34 | GetHersHisCap | 同 33 → 首字母大写 | 定案 |
| 35 | GetHerselfHimself | → "EV_HERSELF" / "EV_HIMSELF" | 定案 |
| 36 | GetHerselfHimselfCap | 同 35 → 首字母大写 | 定案 |
| 37 | GetNonIdeologyName | tag 名局化; 等价原名 (无 loc 覆盖) → 回落 cc+16 | 定案 |
| 38 | GetNonIdeologyNameDef | 同 37 → 回落 cc+80 | 定案 |
| 39 | GetNonIdeologyNameDefCap | 同 38 → 首字母大写 | 定案 |
| 40 | GetNonIdeologyAdjective | 同 37 → 回落 cc+48 | 定案 |
| 41 | GetNonIdeologyAdjectiveCap | 同 40 → 首字母大写 | 定案 |
| 42 | GetCommunistLeader | sub_141A90BF0 查组库 qword_14332EF38 → 党 → 领袖名 | 高置信 |
| 43 | GetDemocraticLeader | 同 42, "democratic" | 高置信 |
| 44 | GetFascistLeader | 同 42, "fascism" | 高置信 |
| 45 | GetNeutralLeader | 同 42, "neutrality" | 高置信 |
| 46 | GetPowerBalanceName | pb = sub_140E56DF0(*(gs+1104), tag) → sub_140A8D870(*(pb+16) template) | 定案 |
| 47 | GetPowerBalanceModDesc | sub_140E56BE0(pb, out) | 高置信 |
| 48 | GetLeftSideName | sub_140A8D870(*(pb+24) left_side) | 定案 |
| 49 | GetRightSideName | sub_140A8D870(*(pb+32) right_side) | 定案 |
| 50 | GetActiveSideName | *(pb+48) value >= 0 → 右侧 (+32) 否则左侧 (+24) → sub_140A8D870 | 定案 |
| 51 | GetTrendingSideName | sub_140A8D870(*(pb+40) trending_side) | 定案 |
| 52 | GetActiveRangeName | 建 CEventScope + SetCountry(cc+8) → *(pb+176) range 虚调 vtable+72 (slot 9) | 高置信 |
| 53 | GetActiveRangeModDesc | 同 52 → sub_140A11BF0(*(pb+176)) | 高置信 |
| 54 | GetActiveRangeRuleDesc | 同 52 → sub_140A11F80 | 高置信 |
| 55 | GetActiveRangeActivationEffect | 同 52 → sub_140A11350 | 高置信 |
| 56 | GetActiveRangeDeactivationEffect | 同 52 → sub_140A11610 | 高置信 |
| 57 | GetChangeRateDesc | sub_140E569B0(pb, out) | 高置信 |
| 58 | GetBopTrendTextIcon | sub_140E55D30 趋势值 > 0 → "BoP_right_texticon" / < 0 → "BoP_left_texticon" / == 0 空串; 非空名 + 0x13 标记字节 | 定案 (分支) / 待裁 (字节序) |

> 领袖性别 (case 27-36 共用, 函数头一次) = party 首领袖 CCharacter+112 gender == 2 (female, §4.4); 首字母大写 = sub_1424CBF40, 全串小写 = sub_1424CD6F0。case 46/48/49/51 的 sub_140A8D870 内部自建 CEventScope 但不设国; case 52-56 显式 SetCountry — 推定侧名/模板名不含国家级脚本变量, range 描述含。

**消费侧新字段** (本函首次读出, 既有表未列):

| 类 | 偏移 | 语义 | 档 |
|---|---|---|---|
| 情报机构 (*(cc+4032)) | +192 | 「有自定义机构名」旗 — 真 → 用 +128 实名, 假 → 局化 AGENCY_NAME (case 25) | 推定 |
| CIdeologyGroup | +56 | 组 id 候选 — case 15 比对键 (§4.10.12 已补行) | 待裁 |

> 未决: case 15 求和条件 (伪码无条件累加全部党 popularity, 与「执政党支持度」docstring 矛盾, 疑块合并失真, 需反汇编核对); case 19/58 的 0x12/0x13 标记字节序 (IDA 丢弃 sub_140BB4E70 返回值与追加实参); case 52 range vtable slot 9 定名 (CPowerBalanceRange vtable 0x14293FFA8); sub_140A8D870 / sub_1402C7570 参数链; D 数组其余 17 槽 (D[7] = Character 等) 需同法逐槽定案。

#### 4.19.3 CBoundLocalization (32B) / CFormattedLocalization (48B)

**CBoundLocalization 字段表** (32B):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPdxInlineBufArray\<SLocEntry,14\> {data@8, cap@16, count@20, alloc@24} | **SLocEntry 数组** (条目 72B, 内联缓冲 14 项) | sub_1423A5380 / sub_1423A5880 逐 72B 拷贝; 分配器 `CPdxHybridInlineBufferAllocator<SLocEntry,14,int>` vtable 0x142B5CA38 |
| +24 | 分配器对象* | &off_143085170 (全局默认分配器) | sub_140147000 尾部 |

**SLocEntry (72B, 非独立 RTTI 类)** = 48B 内嵌 CFormattedLocalization + 24B 子容器:

| 条目内偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +0 | CFormattedLocalization vtable | 0x1427E4068 | sub_14067EF90 写 vftable |
| +8 | MSVC 串 (SSO 32B, cap@+24) | 字面量 / 格式串 / 值 | sub_14067EF90: `*(_OWORD *)(v7+8)=0` + cap=15 哨兵 |
| +40 | uint8 | 变体 tag (0=串 / 1=二值 / 2=u32 / −1=空) | 同 CFormattedLocalization |
| +48 | CPdxInlineBufArray\<SArgument,11\> {data@48, cap@56, count@60, alloc@64} | **SArgument 数组** (元素 88B, 内联 11 项) | sub_14067EF90 尾 `sub_14011DF40((void*)(v7+48))`; 分配器 vtable 0x142B40B8 |

> 48 + 24 = 72 ✓。**"Missing localization key" 判据 (定案)**: `entry+40 == 0 && entry+24 == 0`
> — 即 tag 为「串」变体且串 cap 为 0 (空串)。

**SArgument (88B, 非独立 RTTI 类)** = 32B 名字串 + 48B CFormattedLocalization + 8B 尾:

| 条目内偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +0 | MSVC 串 (SSO 32B, cap@+16) | **参数名 / 键名** | sub_1423A51C0 从 a2 移入 |
| +32 | CFormattedLocalization vtable | 0x1427E4068 | `*(_QWORD *)(a1+32) = &…vftable'` |
| +40 | MSVC 串 (SSO 32B, cap@+56) | 值串 | sub_1423A51C0 |
| +72 | uint8 | tag (同 §4.19.3 CFormattedLocalization) | — |
| +80 | uint8 | 旗 | — |

> 32 + 48 = 80, 再 +8 = 88 ✓。**CBoundLocalization +8 装 SLocEntry (72B); SLocEntry +48 装
> SArgument (88B) = {键名, 值}** — 两个内联分配器名 (`SLocEntry,14` / `SArgument,11`)
> 与两个 stride 精确对应。

**ctor sub_1423A7EA0 两门 (定案)**: 前置 pdx_loc_formatter.cpp:36 CApplication::HasFinishedStaticInitialization() (闩 byte_1435BA06C) / 后置 :38 "Error when parsing code specified format specification" (闩 byte_1435BA06D, 读栈串错误旗位)。

**CFormattedLocalization 字段表** (48B):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | std::variant (index = tag@+40) | 载荷: tag=0 → MSVC 串 (SSO 32B, cap@+32) / tag=1 → {callable obj ptr@+8 (其+16 = fn ptr), u32 参数 id@+16} / tag=2 → u32 formatter id | 拷贝 ctor sub_1423A50D0 按 `*(a2+32)` 分三档; 访问器 0x1423A92C0 (出参 33B = MSVC 串 32B + u8 旗@+32): tag∉{0,1,2} 抛 std::bad_variant_access (sub_1403BAAF0, §4.32 定案 = std::get<I> 桩); tag=1 且 obj 空 → :136 "Invalid formatter" (level 4096); tag=2 → 旗=1 (= 是 id) |
| +40 | uint8 | **变体 tag**: 0=串 / 1=二值 / 2=u32 / −1=空 | sub_1423A50D0 / sub_1423A37A0 |
| +8 (tag=0) | MSVC 串 (SSO, cap@+32) | 字面量 / 格式串 | sub_1423A7EA0 → sub_1423A8920 |
| +8 (tag=2) | uint32 | **formatter id** (见 §4.19.2 loc formatter 注册表) | sub_1423A8920 写 `*(u32*)(a1+8) = v49` |
| +8 (tag=1) | 16B 值对 | formatter 返回值 (两 qword) | sub_1423A37A0 |
| +24 (tag=1) | 16B 值对 | formatter 返回值 (两 qword) | sub_1423A37A0 |

**拷贝/移动族**: 拷贝 sub_1423A4FE0 / 移动 sub_1423A5050 / dtor sub_1423A52E0 (CBoundLocalization);
拷贝 sub_1423A50D0 / 内联构 sub_1423A51C0 (CFormattedLocalization)。验证器单例 = 0x1435BA060。

#### 4.19.4 NScript::NMath::CExpression (56B) 与表达式 trigger

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPdxArray\<SOperand\> {data@8, cap@16, count@20, alloc@24} | **操作数数组** (216B/项) | sub_14141D1B0 遍历 `*v2 + 216*idx` |
| +24 | 分配器对象* | &off_143085170 ×2 之一 | sub_140324DE0 |
| +32 | 匿名结构 (NNB 形状) 向量 | 第二容器 {d@32, cap@40, count@44, alloc@48} — 第二段 (指令/常量池), 由 sub_14141C0D0 填 | sub_14141D1B0 读 a1+32 |
| +48 | 分配器对象* | &off_143085170 ×2 之一 | sub_140324DE0 |
| +208 | i8 | **表达式状态 tag** (−1 = 未初始化 / 1 = 已解析) | sub_14032BA40 三步: 旧 tag≠−1 → 调 vtable[0]; 置 −1; 调 ctor; 置 1 |

**SOperand 字段表** (216B, 非独立 RTTI 类):

| 操作数内偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +0 | uint32 | **名字 token id** (FNV 输入) | sub_14141F030 |
| +8 | CNamedCollection* | **命名集合指针** (解析结果) | sub_14141F030 写回 |
| +208 | uint8 | **操作数种类 tag**: 2 = 命名集合引用 (其余 = 字面量/变量) | sub_14141F030 跳过非 2 |

> 216 = 208 + 8, 与 CPdxArray 元素 stride 一致; 216B 内其余字段未展开 (未决)。

**表达式引用命名集合的求值链** (定案):

| 步 | 动作 |
|---|---|
| ① | `CExpression::reader sub_14141D1B0` (trigger 的 value/var 键解析时调用): 解析操作数 + 指令段; 扫操作数 (216B/项), 若 `byte@+208 == 2` → `sub_140AAB2E0(CExpression*)` |
| ② | `sub_140AAB2E0(a1)` = CNamedCollection 求值: `qword_14332F030` (RH 16B 桶) 存在 → `sub_140AAAB70(表, out, 哈希(a1), &a1)`; 否则 → `sub_14141F030(a1)` 名字解析兜底 |
| ③ | `sub_14141F030(expr)`: 遍历操作数 (216B, +8 data / +20 count), 跳过 `byte@+208 != 2` 者, **哈希(操作数+0) = 0x45d9f3b (73244475) 两轮乘加 xor-fold 雪崩终化, 非 FNV** (`x^=x>>16; x*=0x45d9f3b` ×2; 伪码 `v5 ^ HIWORD(*v4)` 形) 查 `qword_14332EED8` (CNamedCollectionDatabase) RH (**条目 24B = {+0 预留, +4 PSL 字节 0=空位, +8 key u32, +16 value 指针}; 线性探测 `++probe > *(entry+4)` 判失配; 哨兵界 = base + 24×(mask+1+哨兵字节)**) → 命中取 `entry+16` = CNamedCollection*, 写回操作数+8; 未命中 → 报 `"Failed to resolve named collection in math expression, defaulting to 0"` (script_math.cpp:383) + `sub_1403B80F0` + `sub_14140DDE0` + `+44 = 0` + `sub_14141C0D0(expr+32, 0, 0, −1)` 置空表达式 |

**script_math VM (定案, 5 函闭环)**: 指令 = **3 字节定长 [opcode u8][operandA i8][operandB i8]** (扩容步距 3×count; 回填寻址 base+3×pos+1/+2; 与 math_instructions.h:54 operandA int8 断言互证; 操作数上限 127)。opcode 全表: 0=清零默认 [0][0][−1] / 2=every_collection 全链折叠 (体后首指令 ∈ {29,30} 且整条表达式被该短路链覆盖时 op32 重写) / 9=clamp (token 18933; [9][−1][−1], min/max 双操作数隐式取) / 3=multiply (token 10499) / 21=root (11412) / 23=log (10676) / 24=单目 [24][−1] (语义未决) / 28=atan2 (11689) / 29=and (10600) / 30=or (10601) / 31=if 条件跳转 (**B1=TrueBranchSize / B2=TotalBodySize 双 i8 回填**, 断言 :250/:251) / 32=every_collection 迭代 (A=集合操作数 idx, B=体长; 断言 :306)。token 全表: 10179=if / 14573=else_if / 14035=else / 10762=limit / 11067=every_collection / 11556=named_collection; id 19 = 词法失败兜底值。**四编译器**: if 链 0x14141D850 (else_if 循环 + else 收尾; "if block must start with limit =" 错误) / and-or 短路链 0x14141E140 (双遍回填: B1=BodySize :193, B2=链内下一记录位越 i8 界顺延或总长) / every_collection 0x14141D2B0 (peek 须 named_collection; 追加 216B 操作数 {+0=*(u32*)(token+192) 集合名 token, +208=2 种类 tag}; "Too many constants and/or variables in math expression" 127 上界) / **clamp 参数块 0x14141AA70** (期望表 unk_1429BFB00 = {token 675 min, 676 max}, 两参数顺序固定, 各委派单表达式编译 sub_14141DCE0; 键不匹配挂错误节点 + 置 ctx+16=1)。协函: 语句分发器 sub_14141E5A0 (token switch) / 块体解析 sub_14141EDF0 (and/or 挂点) / 首个 if 块 sub_14141D680 / 单表达式编译 sub_14141DCE0 / 3B 指令发射 sub_14141C0D0。解析器 ctx = {+0 = CExpression.operand_array*, +8 = instr_container*, +16 u8 错误旗}; reader 出错报 "Errors occurred while reading math expression defaulting to 0" (:350)。`'@'` 注解代换 sub_1424C04A0 内部 (精化): token 槽旗@+4 非 0 → 整拷缓存返回; 串[1]=='(' → 报 parser.cpp:1087 "not yet implemented" + 空结果; 否则 **FNV-1a 32 (basis 0x811C9DC5) 哈希串[1:] (跳 '@') → 线性查 reader+304 符号表** (112B 条目, count@+316; 条目 {哈希@+32, id@+40, 旗@+44, 串@+48, len@+60}), 命中拷 {id, 旗, 串, len} 回 token 槽, 未命中/空表 → 拷 token 槽原值。
| ④ | `sub_14141C0D0(a1, op, a, b)` = 指令发射 (math_instructions.h:54 断言 `OperandA >= numeric_limits<int8>::min() && …`) |

**表达式 trigger 类**: `CCheckExpression` (vtable 0x1427CF258) / `CDebugMathExpression` (vtable 0x1427CF318),
均 CTrigger 后代 (5 基, 144B, 内联 CExpression@+88); 工厂 = `sub_1405271D0` / `sub_140527220`
(malloc 0x90 → sub_14054A090 → 写 vtable → sub_14032CBD0(v1+11)); 注册入口 =
`CTriggerEntry<CCheckExpression>` (sub_14002E470) / `CTriggerEntry<CDebugMathExpression>` (sub_14002E4D0)。

| 键 | token | 落点 |
|---|---|---|
| tooltip | 146 | a1+512 串 |
| value | 776 | **sub_14032BA40()** = 重置内嵌 CExpression 并置 tag=1 (或对象块 → `(*(expr vtable[3]))(expr, node)` = CExpression reader) |
| var | 14582 | 先 `(*(a1+88 vtable[3]))` 再判 a1+97/98/99 三旗, 报 `"invalid left side variable"` |

> **sub_14032BA40** = CExpression 重用入口 (定案): 旧 tag ≠ −1 → 调 vtable[0] 清理; 置 tag = −1;
> 调 ctor; 置 tag = 1。

#### 4.19.5 NScript::CConstant (64B) / CConstantDatabase (128B)

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +8 | CPdxInlineBufArray\<SSchema::SEntry,25\> {data@8, cap@16, count@20, alloc@24} | schema 表 (元素 40B) | sub_140AA7EA0 逐 40B 拷贝; 分配器 vtable 0x142942208 |
| +32 | MSVC 串 (SSO) | **常量名** (def 键名) | sub_14012CC60 |
| +48 | uint32 | **值类型 tag / 序号** | sub_140AA76C0 = `*(uint32*)(a1+48) = a2` |
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
| +8 | uint32 / 16B 输入描述符 | **输入描述符** `{type, payload}` (正典解析器 sub_140A1EC00, `input = <ns:value>` 冒号语法: game:/collection:/constant: → type 1-6, 全表与协议见 §4.32.19) — 原「元素计数」读法废 | sub_140A1EC00 直证 |
| +16 | uint64 | 预留 (清零) | ctor |
| +24 | CPdxInlineBufArray\<NCollection::COperator,16\> {data@24, cap@32, count@36, alloc@40} | **算子/元素数组** (内联 16 项) | ctor 置 `*(a1+24) = a1+56` (内联路径, 当分配器 vtable[4] == sub_140161270 时) |
| +48 | 分配器对象 (264B) | `CPdxHybridInlineBufferAllocator<COperator,16,int>` vtable 0x142719840; 尾 +312 = &off_143085170 | 48 + 264 = 312 ✓ |
| +320 | uint64 | 第二容器 data | ctor 置 0 |
| +328 | uint64 | 第二容器 cap | ctor 置 0 |
| +332 | uint32 | 第二容器 count (推定, ctor 未显式置) | 容器四字段惯例 |
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
| +16 | uint32 | 名 token 副本 | sub_140130230 |
| +24 | uint8 | 有效旗 | ctor 置 0 |
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
| CRandomLocList | — (19 槽 vtable, 含 CPersistent 槽 [1]/[3]) | 由 reader sub_140AAC5B0 建: +8 = 成员容器 (sub_14031ECD0 追加) / +32 = 另一对象 (键 10647 `seed` → `(*(a1+32) vtable[3])()`) |
| CRandomLocListMember | 288 | +8 = **CScriptableValue 内联体 248B** (经 `sub_141594360(v10+1, 0, 100000*v6)` 构) / +32+256 = CBoundLocalization 内联体 |

> reader `sub_140AAC5B0`: 键 `localization_key` (799) → `sub_1424C0AA0(a2, v22)` 读串;
> 否则把当前节点串作为**根 loc key** 存入 `sub_1423A51C0` (CFormattedLocalization 内联构),
> 再递归 `sub_1423A6200`。`v6 = sub_1424C4FE0(a2+48)` = 权重 (整数),
> `sub_141594360(v10+1, 0, 100000*v6)` = CScriptableValue(seed=0, base=权重×100000)。
> ⚠ 与 §4.31 已载的 `CRandomLocList` (0x1429423D0) 同族 — 该族此前只登记容器件, 成员件为本节补。

#### 4.19.8 脚本可引用 formatter 注册系统 (formatted_localization / character_formatter)

本地化文本中可被脚本引用的 formatter 子域: 注册表 = `unk_143086A50` (FNV-1a 32 位键哈希表; 注册仅限**静态初始化期**, 断言 formatted_localization.cpp:24 "It's not allowed to register a formatter after static initialization." / :30 "Duplicated formatter entry"; 注册原语 sub_14052ED00)。运行期 wrapper 统一入口 sub_14052FDA0: ctx 类型校验 (type_info vs qword_1430CC270) 失败 → 输出 "NULL" (formatted_localization.h:96); 参数数组按 104B 元素 (CParamsVariant) 传实现体。

**country_leader_desc** (列出角色在某意识形态下作为领袖的全部特质; 注册 sub_1405303D0; 求值本体 sub_140530800): 使用协议 = `custom_effect_tooltip = country_leader_desc|hjalmar_schacht` (管道后 = 角色 id); 块形态参数 `IDEOLOGY = token:fascism` (必填, 意识形态**组** token; 缺省 19479 = undefined) 与 `INDENT` (可选, loc 键格式化成缩进串)。无 scope — 直接按角色 id 查库。求值链:

| 步 | 操作 | 函数/依赖 |
|---|---|---|
| 1 | 解析参数 (INDENT/IDEOLOGY 按 strncmp 全长匹配键; token 取元素+96) | 参数元素 104B {type u32@+0 (1 = 串 / 11 = PDXLOCALIZE_TOKEN), 键串对象起点 +8 (堆指针@+8, SSO buf@+16, size@+32, cap@+40), 值串对象@+48, token u32@+96}; INDENT 值即缩进串 (本地化后整体替换结果缓冲, 非前缀拼接); 每轮特质 append 后缓冲非空且末字节 != 换行则补换行 |
| 2 | 角色 = CCharacterTemplateDatabase (qword_14332EE58) 按 id 两级查找 (+64 表 → +104 RH 24B 桶) | sub_1406BD460 |
| 3 | 领袖角色 = 遍历角色+528 std::map, 逐节点键查 CIdeologyDatabase (qword_14332F528) 56B 桶表, 验 `*(ideology+288 指针 +8) == 组token` → 返回该意识形态领袖角色 | sub_1413F1B90 |
| 4 | 遍历角色 SRW 保护特质向量 {begin@+0, count@+12}, 元素 40B {名 SSO 32B, id u32@+32} | get_srw_lock 族 |
| 5 | 逐特质查 CCountryLeaderDatabase (qword_14332EE68) idb 标准查找 (40B 元素 id@+32 相等且 stricmp 名相等双匹配; [0] = Null Object) | sub_14071F950 → sub_14071CE30 |
| 6 | 每特质 NAME = def+24 串作 loc 键 / DESC = def+168 描述域 ("\n  - " 前缀) → `sub_142245E60(out, "COUNTRY_LEADER_FORMATTER_TRAIT", {NAME,DESC}, 2)` 累计 append | sub_142245E60 = localize.cpp 格式化原语 (键+参数数组+count → 串; 6144B 缓冲 = **tbb ETS 每线程 scratch** (vtable 符号直证类型名 LocalizeAndReplaceBuffer — 精化: 原「栈缓冲」), 断言 localize.cpp:641) — 本子域公共出口 |

查不到角色/意识形态 → 空串 (断言 character_formatter.cpp:140 "The validate function should have caught this")。

**character_formatter 角色解析三函** (均经 gs+1704 角色管理器槽 + sub_1406B8A50 按 token 查角色; gamestate.h:1125/1126 守卫组): character_name **容错版** sub_14052FBE0 — 命中取名赋出参串, 查无 → 空串回落不报错 (mgr 空 → 断言 :24 "No character manager available", 闩 byte_14332FF98); character_name **严格版** sub_140531210 — 查无 → "Invalid token for character_name" :39 抛异常, 命中返角色指针; **advisor_desc 解析步** sub_140531070 — 查无 → "Invalid character token for advisor_desc" :77 抛异常, 返角色指针。同名双版分工 = 严格版供 formatter 求值 / 容错版供显示路径 (注册名对应关系待裁)。

#### 4.19.9 localize.cpp 运行期流水线 (10 函闭环; 格式规格语法全集)

清册 (10/10 函体内含 clausewitzlib\localize.cpp 路径锚, 无 pdx_ 误命中): 公共入口
sub_142245E60 (52, :641 "pStr" 断言; 空键→空串) / **LocalizeAndReplace 扫描引擎
sub_142245880 (235)** / 变量解析步 sub_142248C20 (109) / **格式化值发射器 sub_1422479F0
(694)** / 文件夹加载器 sub_142246E10 (491) / 单文件加载 sub_142246CC0 (47) / 主语言文件
加载 sub_14224AF90 (91) / 溢出检测 sub_142244B30 (66) / 重复键告警 sub_142245D00 (77,
零直接调用; **非死代码** — sub_14224B1F0 尾有函数指针回调注册 sub_14239E880(sub_142245D00, 0), 真则 sub_14239EBB0() + byte_1434530F0 = 1; 三平行数组形态 keys/values/files, 消息 "Duplicate localization found" :658) / 多语言一致性校验器 sub_142244C50 (653, **死代码** 全镜像零引用)。

**主链流水线** (定案): E60 → 880 (FNV-1 64 查表 → 分段拷贝 → `$var$` 两路 = 参数表命中/
按 loc key 递归 depth+1, `$$` 转义, 深度 32 上限, 未闭合 `$` 告警) → 8C20 (`$NAME|spec$`
名段对 104B 参数表 strncmp 精确匹配; 三一次性断言, :504 自证类型名 **CPdxLocalizeKeyValuePair**)
→ 79F0 (spec 发射)。**104B 参数对布局**: +80 i64 / +88 2^15 定点 / +96 联合, _Type 1-11
全枚举 (11 = token → lexer.cpp:381 串)。

**格式规格语法全集** (79F0 定案): `%` ×100 / `%%` ×1 / `*` `^` 两拼写族 / `+` `−` 红绿 /
数字小数位默认 2 / `=` 强制加号 / `U` `l` 大小写 / `_` 零隐藏 / 字母固定色; 色逃逸
`0x11+字母`、复位 `0x11+'!'`、± 缺省 'Y'; **引擎 u16 实证 = 18449 (0x4811 → 字节 0x11 'H', 色码开) 与 8465 (0x2111 → 字节 0x11 '!', 复位)** (STAT_ADJUSTER 组合器 sub_141015080 内嵌字面, §4.19.13)。

**加载链** (定案): 文件夹加载器枚举 *.yml (a3=0 按语言名过滤), "/replace/" 路径延后最后载;
主语言文件加载 = 语言全局态三写 (off_1430BDED8 / byte_1430BDEE0 / qword_1435BA038 换表);
D980 真实签名 `(buf, size, 文件名, 0, a5, a6)` — **capstone 汇编核对** (伪码调用点 3 参形态
系 IDA 失真, 后续引用以汇编为准)。

**断言总门来源定案**: byte_1435E1B51/52 = 控制台开关 "Asserts(and smoothing)" + ai_testing
置位 (四形态辨析的门来源, 全书各处引用此二门处同源)。

**IDA 伪码四类失真** (后续批次防复发): ① 调用点参数截断 ② 浮点 xmm 不可见 ③ wchar_t 误标
④ **64 位常量乘法压成低 32 位字面量** — 伪码 `435 * (c ^ h)` 实为 `movabs r8, 0x100000001B3;
imul rcx, r8` 的 FNV-1a 64 (435 = 0x100000001B3 低 32 截断); 凡裸小常数乘 hash 先怀疑此形态
(汇编复核曾险些据此产出「双 hash 混用同表」谬案)。

**std::string 通用串层助手四件** (全语料高频内联级, 形态定案, df391 + df387):
sub_14011FC50 = **move-assign** (释目标旧缓冲 → 32B 整体搬运 → 源置空态 SSO cap 15) /
sub_14011DBC0 = **grow+append** (容量满时重分配 — 1.5× 上取整 16 对齐, ≥0x1000 走对齐头
+ 回填长度指针 — 并追加单字节; 伪码常丢参, 真签名 4 参 = Dst, count, src, size) /
sub_1402DE330 = 数组析构助手 (eh vector destructor iterator 通道) / **sub_1401200A0 = cstr+std::string
拼接** (真签名 3 参 = Dst, cstr, 串; 清空 Dst → strlen(cstr) 经 sub_14011D970 赋值 → append 串.数据/串.size;
⚠ **IDA 全语料 10+ 调用点一律丢后两参** — 见单参形态调用时按 3 参解读, 原始字节定案, df387); 四件均非
业务函数, 全书各处按此语义引用。另 **xmmword_1427179A0 = std::string
空态常量** (16B = {size = 0, cap = 15} 小端对, 即 SSO 阈空串; 析构后重置 / move-assign 源置空经
_mm_load 搬此常量; df387 原始字节定案 + df397 独立复见)。

未决: D980 a4/a5/a6 精确语义与 56B 解析上下文 / 文件读取器 0x100000 参数 / `~` 旗 (Type 9)
与数值格式化助手族 / Type 10 打印缩放侧证。

#### 4.19.10 textbase.cpp 求值引擎 (CTextBase 三巨函; [...] 与 (...) 与 ?Name 全语义)

清册 (3/3 函体内含 localization_objects	extbase.cpp 路径锚, 均无中断格式化错误日志;
§4.19.2 ①-⑥ 全互证): **ProcessString 0x1412CED60 (300)** / 条件形式
0x1412CE980 (221) / 数值/属性形式 0x1412CF2B0 (1121)。

**ProcessString = `[...]` 求值唯一入口** (27 个外部调用点, 定案): 深度帽 = NGame define
**MAX_SCRIPTED_LOC_RECURSION (现值 30**; 日志里 4096 系严重级数值), 超帽原样透传; 组件数组
住 pdx_scoped_buffer; slot[6] 保存现场仅 depth=0/reset, slot[7] 每个普通段前+收尾恢复;
未闭合 `[` 丢弃余文; slot[0] 命令输出递归重过。

**`(...)` 条件函数形式** (定案): `(PromotionChain?TRUE:FALSE)` — slot[2] IsEmpty 选支、
单支惰性求值、`'…'` 字面量经 slot[3]、FALSE 支空 scope 报 textbase.cpp:455 并复位;
纯 `(Chain)` 无 `?` = 仅 scope 提升零输出; 恒返回越 `)` 指针。

**`?Name` 四层解析序** (定案): ① 属性 7 命令表 (C3/C4/C7/C8/C11/C12/C13, 按 scope 槽梯度
取值; C[4] = State 4 条 GetName/GetID/GetCapitalVP/GetContinent 配 gs+712 州表; C[7] =
UnitLeader 12; C[8] = Character 13) → ② **qword_14332F038 = CScriptableLocalizationDatabase**
(`common/scripted_localisation`, FNV-1a) → 新造 CContextLocalizationText 绑 scope 递归 →
③ 6 个 named provider lambda (GetDateString 系 4 + GetTokenKey + GetTokenLocalizedKey) →
④ slot[4] 数值 + clausewitz 格式引擎。识别属性形式时 `|` 部整体忽略; `|` 后 =
localize.cpp 格式说明符 (`%*.+0-9=`, §4.19.9), 空输出落 **fixed×1e5 定点默认渲染** (÷100000
去尾零 = 脚本变量内部表示)。**打包 id bit28-31 空间判别** + sub_14221F310; slot[4] = 名字→
打包 id/数值解析器 (快路径 `:days`/`:days_left`) — 书 vtable [3][4][5] 三槽空缺由此获消费
语义 (精化)。

未决: C[11]/C[12]/C[13] 属性名与 +120/+128/+144 槽类型 / CEventScope +8/+168 双 id 槽 /
qword_143330D98 身份 / 畸形 `(A:B)` 前缀循环伪码疑死循环 (待汇编) / 运行期 .data 表
(0x14338Bxxx) PE 直读无效须读注册器 strcpy 字面量 (工具注)。

#### 4.19.11 pdx_localize.cpp yml 真解析层 (2 巨函; §4.19.9 加载链的下游终点)

#### 4.19.12 可绑定本地化值设置器 (pdx_bindable_loc.cpp; 1 函 = sub_1423A3EE0, 定案)

sub_1423A3EE0 (pdx_localize 可绑定值容器填充): 描述符 type 字节 @a3+32 — 0 → 串支 (容器头 type 标签 = 1 @+0, 绑定源指针 @+8, std::string 24B @+48 由 sub_14011E010 从 a3 拷入); 1 → 数支 (头 type = 11, i32 @+96 = *a3); 其他 → B52 :25「Unhandled type returned from localize function」(闩 byte_1435BA05A)。type 枚举 = **1 = 串 / 11 = 数**。

清册 (2/2 函体内含 pdx_localize.cpp 路径锚): yml 逐行解析器 0x1423A2620 (1015) / 语言表键值
批量装载 0x14239D170 (524, 七参 = 语言名/键数组/值数组/数量/模式/fallback 语言/显式既有值;
模式分派精化 (定案): **0 = 丢弃** + :884 "Discarded duplicate key" 日志 (通道 4096) / **{1,2,3} 同走 CBD0 有序插入路** (goto 穿落共置 v79) — 1 = 原位处理无覆盖旗, 2 = 恒覆盖 (v80 初值 1), 3 = 旧值 FNV-1a64 + 逐字节比对门 (值同退插示 −1) / **4 = 独走 C290 原位替换路** (无日志静默替换)。函数内 FNV 伪码两处 `435*(x^v)` = FNV-1a 64 低 32 截断失真 (同函并存全形 0x100000001B3 + offset basis 0xCBF29CE484222325 直证), 键 hash 全线 FNV-1a 64; 脏旗双语义 (CBD0 路 |= / C290 路直置 1) 尾调 sub_1423A1A30 重整)。

**层界定案**: §4.19.9 localize.cpp 三加载函 (46E10/6CC0/AF90) 全是 IO 壳, 全部汇入
sub_14239D980 → A2620 解析 → 写语言表 — 加载链自此有下游终点。**语言对象 104B 七字段**:
+0 名 string / +32 FNV 有序表 / +44 计数 / +56 键条目表 24B×5 字段 / +68 计数 / +80 值串池 /
+92 计数; **DB qword_1435BA038 六字段**: +0 当前语言 / +8 语言数组 / +32 全局串堆 / +40 容量 /
+44 水位 / +48 分配器 (PE + capstone 双证)。键 hash **全线 FNV-1a 64** (双索引同 hash);
yml 行语法全集与空白集 (含 U+00A0/U+2007/U+202F/0x1C-1F)。错误分流: :1031/:1091/:1100/:1150 =
日志+弃整文件; :1202 转义错误 = 容错收录继续; 两函体内零 _CxxThrowException (尾块 = CLogStream
析构链)。**州名程序化灌入闭环 (定案, §4.00.59)**: 141B5C0C0/141B64480 = E1C0 当前语言 → E1F0 "l_" 归一 → 9D170 (模式 3, 键 = 模板+64 脚本名, 值 = 州显示名) → 9F140 注册 "state_names_" 前缀 loc 文件 writer 回调 0x141B5F0A0。

未决: "1" 版本行悖论 (纯数字行按语法应触发 :1100 弃整文件与现实矛盾 — 候选 = 壳层剥头行或
:1100 后非 return, 需汇编) / 行记录 72B 内 +8 写入点 / 键条目 +12 精义 / 9D170 a5=4 调用点实参截断 (a5=3 完整七参见 §4.00.59: a7 = 构造的 yml 路径串, 与「显式既有值」语义不符, 真义待汇编) / qword_1435BA040 文件记录读取侧。


**localize.cpp 50-99 行簇增补**: 主语言/单文件加载 sub_14224AF90 — 存在检查 → 整读 → **BOM 校验** (非 EF BB BF 告警 "Localization file '%s' should be in in utf-8-bom encoding" :1639, "in in" 源串原样) → 解析落点 sub_14239D980; 双全局槽 = byte_1430BDEE0 模式旗 / off_1430BDED8 路径槽。溢出检测 sub_142244B30 — "Reached max localization string length" (:524, 闩 byte_14345313F), **返回值 0=正常 / 1=溢出 (告警不拦)**。公共入口 sub_142245E60 (全语料 9458 处, 最热点) — 6144 tbb ETS 缓冲容量以 buf+6144 上界实参显式传扫描引擎 sub_142245880。

#### 4.19.13 STAT_ADJUSTER 统计增减文案构建器簇 (1 主函 = 0x141014920 + 组合器 sub_141015080 + thunk 族, 高置信 (簇业务身份待裁))

sub_141014920(out, stat_name [move 消费], value i64, is_diff bool): 键1 = "STAT_ADJUSTER_" + stat 名 → 无参本地化写 out; is_diff → 键2 = 前缀 + "_DIFF", 104B 参数 {_Type=9, "VALUE", value@+80} (与 §4.19:352 104B 参数对同构) 单参本地化追加; 否则键2 = 前缀 + "_VALUE", **value' = value + 100000** (i64 整数加, 推定 = PDX「+1e5 = 正/绿着色值编码」惯例, 精确发射语义待汇编, 挂 §4.19 数值格式化助手族未决) → **sub_14043E0D0 (新定案, 书无) = 单数值参数本地化格式化包装** (out, 键, 参数名, i64\* 值) 固定构 {_Type=9, 名, \*值} 104B 单元素表 → sub_142245E60。尾 out += '\n'。**0x141014 thunk 族**: sub_141014FB0 / sub_141015010 / sub_141015C80 = 6 行 jmp 转发壳 (真签名 4 参, IDA 只显 1 参 = 寄存器透传失真) + 组合器 **sub_141015080** = 三旗驱动 (a1[2] ATTACK / a1[3] DEFEND / a1[4] MOVEMENT 字面 SSO 直证), 每真旗构空串调 thunk (stat 名 = 字面串) + 缩进 (空格×a6) 逐段 append; a5 路径头部内嵌 **u16 字面 18449 (0x4811 色码开) / 8465 (0x2111 复位)** = §4.19:357 色逃逸方案引擎实例。消费面 9 站跨科技条目区与军队 GUI 区 (0x141FAEAE0 邻 CTechnologyTechnologyStatEntry ctor); 簇业务身份 (将领技能/装备改型/科技统计对比 tooltip) 待裁。

#### 4.19.14 本地化绑定与表达式系统函数补遗（184 函）

| VA | 语义/证据 |
|---|---|
| 0x141B4C240 | （无名） 调用图传播: 24 锚点投 §4.19（62%） |
| 0x141876420 | （无名） 调用图传播: 20 锚点投 §4.19（60%） |
| 0x14228F010 | （无名） 调用图传播: 14 锚点投 §4.19（57%） |
| 0x1419BB1E0 | （无名） 调用图传播: 17 锚点投 §4.19（82%） |
| 0x1417EAB40 | （无名） 调用图传播: 19 锚点投 §4.19（68%） |
| 0x141C58520 | （无名） 调用图传播: 14 锚点投 §4.19（57%） |
| 0x141B3D590 | （无名） 调用图传播: 28 锚点投 §4.19（50%） |
| 0x141B3F2D0 | （无名） 调用图传播: 9 锚点投 §4.19（89%） |
| 0x1418E1BF0 | （无名） 调用图传播: 7 锚点投 §4.19（86%） |
| 0x1419BE7E0 | （无名） 调用图传播: 9 锚点投 §4.19（78%） |
| 0x1419BC740 | （无名） 调用图传播: 12 锚点投 §4.19（75%） |
| 0x141DC98F0 | （无名） 调用图传播: 7 锚点投 §4.19（57%） |
| 0x141D2BC50 | （无名） 调用图传播: 11 锚点投 §4.19（55%） |
| 0x141B6EE50 | （无名） 调用图传播: 6 锚点投 §4.19（83%） |
| 0x1418CC3B0 | （无名） 调用图传播: 5 锚点投 §4.19（60%） |
| 0x1419BBFD0 | （无名） 调用图传播: 6 锚点投 §4.19（67%） |
| 0x141D76950 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1424D65D0 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x14244C320 | （无名） 调用图传播: 4 锚点投 §4.19（100%） |
| 0x141E85370 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1423A7710 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140B8FBD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140A383C0 | （无名） 调用图传播: 4 锚点投 §4.19（75%） |
| 0x14244B020 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141AFFE80 | （无名） 调用图传播: 8 锚点投 §4.19（50%） |
| 0x140F894C0 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x1406D2A20 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1409D2010 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1409EE9F0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140F08660 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x14193C600 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140A857A0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x141CCD250 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x14244BD20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141CCD780 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x141F09660 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x141666A50 | （无名） 调用图传播: 5 锚点投 §4.19（80%） |
| 0x1410C5770 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x141663BF0 | （无名） 调用图传播: 4 锚点投 §4.19（75%） |
| 0x140D03690 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x14028CD00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1402573D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140287E40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140289470 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140263390 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14023E0B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1424FE000 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1419F4800 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14237DAA0 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x140F9EAB0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140B83D40 | （无名） 调用图传播: 14 锚点投 §4.19（57%） |
| 0x140AD0E70 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x142409C10 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x14149F7D0 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x142393540 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x141542AD0 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x140ABB6D0 | （无名） 调用图传播: 12 锚点投 §4.19（67%） |
| 0x140532700 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x14225E650 | （无名） 调用图传播: 9 锚点投 §4.19（67%） |
| 0x1403280B0 | （无名） 调用图传播: 7 锚点投 §4.19（57%） |
| 0x1422FA0D0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140D97490 | （无名） 调用图传播: 9 锚点投 §4.19（56%） |
| 0x1424EC530 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140689AA0 | （无名） 调用图传播: 5 锚点投 §4.19（80%） |
| 0x1417D3280 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x1423AA570 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x141739B40 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x14124D410 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14124D2D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x142405730 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140DFA590 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x140D149F0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1424C9F80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14022E780 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x14230A3F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1403C3340 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x142449E20 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x14148ECC0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140CF9FE0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1402B2420 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140073F80 | （无名） 调用图传播: 9 锚点投 §4.19（56%） |
| 0x1416FAE40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14031E3F0 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1402E3710 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x14022AD20 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1403C3460 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x140AEE140 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x141688EC0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140F9F7B0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x14226EBB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141D92EB0 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1423A55E0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140C9F7B0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1402E3430 | （无名） 调用图传播: 4 锚点投 §4.19（75%） |
| 0x14141F4F0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140AEED90 | （无名） 调用图传播: 6 锚点投 §4.19（50%） |
| 0x1416D9FA0 | （无名） 调用图传播: 7 锚点投 §4.19（57%） |
| 0x140234120 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x140B71A30 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140BC4B20 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x141D44C40 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1402E3610 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1410E47E0 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x1417742E0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x14207E530 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x141B00E60 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1424BAF70 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x142246700 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140A6FB20 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140BC4A70 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140B65ED0 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1411C8C10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14163ECA0 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x14188EE70 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1419A0420 | （无名） 调用图传播: 5 锚点投 §4.19（60%） |
| 0x1403C3160 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1402F9330 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x140151B50 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x14143FDD0 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x140FE2FB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x142081070 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141D82740 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x142283CB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14240BF40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1406451B0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140151290 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1423A7E10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x142271960 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141B52100 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140151A90 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x140B9E800 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1402B0A10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14022AEF0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x141CA6420 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x14033A6D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1424CE610 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1402C8760 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140B90280 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140AFFEB0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1423A5150 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x141AF84C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140A3F370 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140ADE4E0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1411B79E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1419F4790 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141A9B070 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x141A9B100 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x141A9B190 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x1413378B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141336630 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x1424DD290 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140ACDEC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140ACDFC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140ACDF40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140EBFE60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140309680 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1404A3F50 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1402B4870 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14022E820 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1422447D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1424DD200 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140A09E10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140F10590 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140EC0DC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x140B87E20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14226ECA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14011FBC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141343DC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14239FC40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x142283C40 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x14208C4B0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x14050B080 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x140120680 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x140339CD0 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1406CB4B0 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x142392C60 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x140A90940 | （无名） 调用图传播: 4 锚点投 §4.19（50%） |
| 0x1402CB260 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1402D2600 | （无名） 调用图传播: 2 锚点投 §4.19（100%） |
| 0x1406F2F30 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |
| 0x1414A5B30 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1414A5C30 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x141A11290 | （无名） 调用图传播: 2 锚点投 §4.19（50%） |
| 0x1413A1A50 | （无名） 调用图传播: 3 锚点投 §4.19（67%） |

#### 4.19.15 本地化绑定与表达式系统函数补遗（16 函）

| VA | 语义/证据 |
|---|---|
| 0x1424647F0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x1410E7DE0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.19 |
| 0x1422878E0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x1416DCA70 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x141160DB0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x1402B3C00 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x142454CC0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x1424640C0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x141CCC4C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1410E8460 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1410E8650 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x140B92490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x14025B410 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x141774230 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.19 |
| 0x1410EC8F0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.19 |
| 0x140154330 | 无名 sub_（调用图定位） 调用图传播: 4/7 锚点投 §4.19 |
