

### 4.28 会话与身份注册块 (player / mods / id 注册 / 生涯档案 / settings)

> **本册边界** (§4.25/§4.28 同为 gs 顶层块, 切分按语义非地址): 本册 = 会话/身份/注册类块
> + 跨局持久件 + 设置族。
> 顶层块分驻: variables/region/threat/选择组/游戏规则 → §4.25; power_balance → §4.3.21;
> 海军战史 → §4.16.13/§4.16.14; 事件状态 (saved_event_target / fired_event_names) → §4.12; factions → §4.5。
> **设置族三条随宿主就地 (非本局存档数据, 与 §4.25 纯 gameplay 全局不同源)**: §4.28.11 CSettings/CSystemSettings
> (settings.txt) / §4.28.12 CLauncherSettings / §4.28.14 CInGameIdler (会话 idler: 暂停域 + 家族虚表 + 实例布局 + 驱动契约 + 六节拍槽) — 时序链契约在 §4.2, 本节 = 布局所有权册。
> 块族元 writer = sub_1401F2E40 (gamestate.cpp); 根 writer = sub_1401F29A0;
> 头部 writer = sub_140BC2710 (跨块元信息)。

#### 4.28.1 CHuman (160B, player_countries)

头 writer a1 = gs+16 → {data@gs+168, count@gs+180}; 160B 元素 = CHuman
(vt 0x142720da8; ctor 0X140BBC720 / copy ctor 0X1401C0D80; 注册
sub_140BC2640(gs+16, human) 按 id@+152 有序插入); writer 0X140BBC970。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CHuman | 不序列化 | |
| +8 | 匿名结构 (NNB 形状) 向量 24B | pinned_strategic_regions | 未实现 | {data@+8, cap@+16, count@+20, alloc@+24}; u32 列表; writer 块 12506 (有 writer 无提取) |
| +20 | uint32 | pinned_strategic_regions 计数 | 未实现 | |
| +32 | MSVC SSO 32B | user | | 引号 (账号名); size@+48 |
| +64 | MSVC SSO 32B | name 玩家显示名 | | "X controls Y" 通告构建器读 +64: sub_140CEEA30 与 sub_141153210 两处同构; **定案** (CAddHuman/CAddPlayer 两命令经 CHuman 6 参 ctor 0x140BBC630 传参互锁: arg1=+32 user / arg2=+64 name) |
| +96 | SProfileBadge (内嵌 16B) | 档案徽章 | | {vt@+96, u32@+104, u32@+108}; CAddPlayerCommand 复制源同位; 定案 |
| +112 | uint32 | tag | | = 国 idx |
| +120 | CGameDate (内嵌 24B) | 最后 ping 上报日期 | 恒写 | {vt1@+120, hours@+128, vt2@+136}; ctor 装哨兵 43808760 ("1.1.1.1"); 运行期 hours@+128 = CClientPingCommand::Execute 直写上报日期 (cmd+48) = 掉队扫描水位 (§4.2.3 步骤 3); 「MP 加入/就绪时刻」候选否决 (探针值即哨兵) |
| +144 | uint32 | 上报连接信息 | — | CClientPingCommand::Execute 写 (载荷 cmd+68 = server 槽[28] 值); ctor 置 0 |
| +148 | uint8 | 标志位 | 恒写 | bit0 = country_leader (writer `&1 → yes/no`); slot4 sub_140BBC7F0 `^= &1` 翻转 |
| +152 | int32 | id | ≠-1/0xFFFFFFFF 才写 | |

注: ⚠ +136 是 +120 同一日期的 vt2, 非第二日期。
注: +148 ctor 值 = 9 = 0b1001 (bit0 = country_leader 默认 1 + bit3 = 1); ctor2 在 a6≠0 时置 11 = 0b1011 (再置 bit1)。**序列化只走 bit0** (writer `*(a1+148) & 1`; reader 只 XOR bit0 保留其余位) → **bit1 = hotjoin 旗** (运行时置位: CAddPlayerCommand hotjoin 路径经 ctor2 a6 写 11; 9→11 系位组合非状态枚举), bit3 写侧无独立锚 (未决)。

#### 4.28.2 gameplaysettings

对象 @ gs+1576 = **CGamePlaySettings** (RTTI 实名, vt 0x142950990, serfam writer 0x140BBB630 / reader 0x140BBB1F0 指纹对位); ironman/historical 写 int 0/1 非 yes/no; reader 兼容旧键 setgameplayoptions (11100) 三值列表。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | — | 不序列化 | |
| +8 | uint32 | difficulty | | = gs+1584; 枚举 → 引号串; 与 top_meta difficulty 同址互证 |
| +12 | uint32 | ironman | | 写 int 0/1 非 yes/no |
| +16 | uint32 | historical | | 写 int 0/1 非 yes/no |

difficulty 枚举表 (sub_1401FAC70 → 引号串):

| 值 | 名称 | 语义 |
|---|---|---|
| 0 | very_easy | |
| 1 | easy | |
| 2 | normal | |
| 3 | hard | |
| 4 | very_hard | |

#### 4.28.3 mods

mgr = ***(BASE+54728200)***; 匹配 (writer 0X1420787E0): 播放集路径末两段拼
"a/b" 与节点 path 全等 → 收 name; 写序 = 注册表 RB 中序。

| 项 | 值 |
|---|---|
| 注册表 | RB-tree head = *(mgr+176); 节点 {name MSVC@+72, path MSVC@+136 (size@+152)} |
| 播放集 | {data@mgr+104, count@mgr+116}; 32B MSVC 路径串 |

#### 4.28.4 index 计数器块 (5×1 叶)

元 writer `ADEC0(tok, a1+1872+16k)` — 内联对象 {vt@0, id u32@+8}
(entity writer 0X140E97CD0 / id_counter_store 同构互证)。

| gs 偏移 | dim | token |
|---|---|---|
| +1872 | railway_gun_index | 19733 |
| +1873..+1887 | — | = railway_gun_index 对象内部 (16B 内联对象 {vt@+1872..+1879, id u32@+1880, pad@+1884..+1887}) |
| +1888 | industry_organisation_index | 14492 |
| +1889..+1903 | — | = industry_organisation_index 对象内部 (16B 内联对象 {vt@+1888..+1895, id u32@+1896, pad@+1900..+1903}) |
| +1904 | special_project_index | 16401 |
| +1905..+1919 | — | = special_project_index 对象内部 (16B 内联对象 {vt@+1904..+1911, id u32@+1912, pad@+1916..+1919}) |
| +1920 | program | 16392 |
| +1921..+1935 | — | = program 对象内部 (16B 内联对象 {vt@+1920..+1927, id u32@+1928, pad@+1932..+1935}) |
| +1936 | program_supply_consumer | 12849 |

#### 4.28.5 id_counter_store

对象 @gs+1952 {vt@0, 表指针@+8 = gs+1960}; 同 vt 终止; 值形 `type=T id=N`
(type 在前); 条目 0x10B。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | — | 不序列化 | |
| +8 | uint32 | type | | |
| +12 | uint32 | id | | |

第二容器 {data@+32, count@+44, 64B 条} (内层发射键 13120 id_counter)。

#### 4.28.6 entity

对象 = ***(gs+1096)***; writer 0X140E97CD0。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | entity.id | | u32 无符号 |
| +16 | 匿名结构 (16B) | 嵌套子表数据指针 | 未实现 | entity 子表 {d, c} 16B 元 {token, obj}; 容器四元组 {data@+16, cap@+24, count@+28} |
| +28 | uint32 | 嵌套子表计数 | 未实现 | |

#### 4.28.7 明确不发射族

writer 有、提取器不落的键族 (默认原因 = 提取器选择):

| 键 | 所属块 | 不发射原因 |
|---|---|---|
| rule_status | faction | 提取器选择 |
| manpower_pool (×2 重名块) | faction | 提取器选择 |
| faction_programs | faction | 提取器选择 |
| pings | faction | 提取器选择 |
| completed_goals | faction | 提取器选择 |
| canceled_goals | faction | 提取器选择 |
| member_upgrades | faction | 提取器选择 |
| upgrades.doctrine | faction | 提取器选择 |
| member_upgrades | facsys | 提取器选择 |
| completed_faction_goals | facsys | 提取器选择 |
| combatant | saved_event_target (SET) | 引擎断言永不持久化 (cannot persist CCombatant) |
| pinned_strategic_regions | player_countries | writer 块 12506, 有 writer 无提取 |
| 嵌套子表 | entity | 未实现 |
| assist | sunk_ship | 仅真写 yes; 提取器选择 (token 13552) |

注: faction name 键不在本族 — name = +24 SSO, 写门 size≠0, 见 §4.5 CFaction 表。

#### 4.28.8 NCareerProfile 生涯档案簇 (medal / ribbon; RTTI 真名带 NCareerProfile:: 前缀)

career def 布局 (CCareerProfileMedal / CCareerProfileRibbon 同型 getter 族):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint32 | 硬编码 id (非 token; 与 §4.26 规格表同款双证) |
| +24 | MSVC 串 | 名 key 串 (tooltip 走 DB+40 loc 表) |
| +56 | uint32 | **非序列化 config 字段** (真名未决) — **非 tier 数**: tier 槽为固定 3 个内嵌 88B 对象 @+296/+384/+472 (medal def 560B 专用; ribbon def 无 tier 槽; reader 由 bronze/silver/gold 三键直写), tier 数 = 编译期 3, 不依赖 +56; def reader 无 +56 case, 值由 def ctor 从 token 流读入 |
| +72 | MSVC 串 | 显示名 loc 串 (sub_1406ABD30 直读) |
| +104 | MSVC 串 | 描述 loc 串 (sub_1406ABCA0) |
| +136 | MSVC 串 | quote loc 串 (仅绶带; sub_1406B03F0) |

data 结构 (语义推定):

| 结构 | 布局 |
|---|---|
| SCareerProfileMedalData | {u32@+8, u32@+12, qword@+16} |
| SCareerProfileRibbonData | {u8 tier@+8, qword@+16} |

六类:

| 类 | 窗/交互 | 语义/消费点 |
|---|---|---|
| CMedalItem / CRibbonItem | 窗 medal_item / ribbon_item | 创建点 = CAwardsView 族 populate sub_141F7F060; +104 = 已收集标记 → "collect_button" lambda 签名含 NGameTelemetry::SAwardCollectedData |
| CMedalPickerItem / CRibbonPickerItem | CAwardDisplay::ToggleMedalPicker / ToggleRibbonPicker → sub_141FA7560 / sub_141FA7E70 | a4 = SCareerProfileMedalData (u32@a4+8 = tier; CTierColors = def+160 数组, 图标函数内部经 sub_1406ABC90 取); 图标 sub_141E92E70 / sub_141E931B0 按 tier 着色 |
| CMedalPopupWindow / CRibbonPopupWindow | 基 = NCareerProfile::CBasePopupWindow (0x5E0B) | **win+1496/+1500 = {成就 id, tier}** 工厂一次性 qword 写入 (ribbon 工厂只写 +1496 id, +1500 不写 — tier 恒 1 音效硬编码); [6]SetupContent sub_1419C4580 / sub_1419C4DE0 → **CMedalDatabase 0x14332EE30 / CRibbonDatabase 0x14332EE48** = career_medal / career_ribbon DB 运行时址; **win+112 = Show 时间戳**, Update 超时两级 define = **dword_1433374B8 隐内容 / dword_1433373FC 关窗**; 源断言 career_profile\medal_and_ribbon_popup_window.cpp |

弹窗队列管理器 = CInGameIdler+2560 (80B malloc 对象; Idle=vt[4] 消费链, ctor/dtor 挂卸); 帧消费 sub_140DD3A50 → sub_1419C5390 三分支:

| 偏移 | 名称/语义 |
|---|---|
| +0 | medal 队列 (对偶字段@+0/+12; 条目 8B = {id, tier}) |
| +24 | ribbon 队列 (对偶字段@+24/+36; 条目 4B = id) |
| +48 | achievement 队列 (对偶字段@+48/+60) |
| +72 | busy |

#### 4.28.9 跨局持久件族 (session_persistence; CPersistedDb 系 — 非本局存档, 用户目录持久化)

**CPersistedDb** (抽象接口, 无基类; vt 0x14294E9F0): [1] = 文件/节名 getter (纯虚) / [4] = Load (纯虚) / [5] = Save (纯虚) / [2] = 可用性谓词 (默认 return 0)。源域 = session_persistence/。

**CPersistedDesignsDb** (跨局装备设计库; vt 0x14294EA60, 基 CPersistedDb@0 + CPdxScopedSingleton@8): [1] = 名 **"equipment_designs"**; [4] Load 0x1419216F0 (392B 帧 ctx 0x1419214F0, magic 0xDF8077FFFD); [5] Save 0x141923C20。文件格式: `version = 0` 打头 + tank_designs(12933)/ship_designs(12934)/plane_designs(12935) 各块。布局: +24 designs 数组 {d@24, count@36, 元素 = [2] 自写设计件} / +72 u32 version。

**CPersistedMioQueue** (MIO trait 队列模板, 72B; vt 0x142A1B868; CPersistent 标准槽; writer 0x141927240 / reader 0x141926980): +16 name SSO (27) / **+48 queued_trait 16B 条数组** {d@48, count@60, 元素 = 自带 vtable 的微型 CPersistent trait 条 (载荷类名待裁)}。落盘形 `name = "…"` + `queued_trait(16391) = { <trait> ×N }`。

**CPersistedMioQueueDb** (跨局队列库; vt 0x14294EA98): [1] = 文件名 **"mio_queues.txt"**; [4] Load 0x1419260F0; [5] Save 0x141927030。文件格式: version 打头 + 逐条 `<queue 键 token> = { CPersistedMioQueue 块 }`。布局: **+16 RH 表 24B 头** {d@16, count@28, sentinel@32}, 24B 条 {hash u32@0, dist u8@4, key u32@8, CPersistedMioQueue*@16}。

**CPersistedMioQueues** (队列集合容器; vt 0x142A1B8B8; **自有 wrapper 类 (serfam 盲区)**): [1] writer 0x141927140 / [3] reader 0x141926650 (persisted_mio_queue.cpp:57 收尾校验); +8..+23 头部附加 (待裁) / **+24 RH 表** {d@24, count@36, sentinel@40} 同 24B 条 schema (与 Db 的 +16 表同形两种宿主)。

**CPersistedBookmarkPlaythroughDb** (跨局书签游玩记录库, 40B; vt 0x14294EA28 7 槽; 基 CPersistedDb + CPdxScopedSingleton): [1] = 文件名 **"bookmark_playthrough.txt"** (用户目录); [4] Load / [5] Save; 内容 = +8 内嵌 RH 表 {count@+24}, 桶条目 stride 64 {串键@+8, u32@+40, SBookmarkPlaythroughData 子对象@+48}; 落盘形 `version = 1` + `data = { <匿名块 key,u32> ×N }` (版本不符报 "Bookmark playthrough data version mismatch")。

**CSavedAchievementMod** (mod 成就持久条; writer 0x141485B40 / reader 0x141485530): 元素 56B {+8 name 串, +40 u64 date, +48 版本 dword}, 键 name/date; **去向 = 云档生涯档案** — 写入经 CCloudStorageContext (取 context 失败抛 "Could not obtain cloud storage context."), 挂载段 career_profile_mod_achievements_section, 按 mod 拼名 `<modkey>_achievements` 生成云档文件; 读入顶层识别 token 377 checksum。归 NCareerProfile 簇邻域 (§4.28.8), **非 savegame**。

#### 4.28.10 消息设置族 (CMessageType / CMessageTypeSettings; 存档实写)

**CMessageType** (消息类型注册项, 144B; vt 0x1429D8F90; writer 0x1415788F0 / reader 0x141578470): +8 token (357 none 哨兵) / +16 u8=1 / +24 name / +56 i32=-1 / +64 msg_icontype (11411, 默认 "combat") / **+96/+104/+112/+120 = to_me (11408) / from_me (11407) / interesting (11406) / other (10724) 四槽 CMessageTypeSettings\*** (非空门 = 各槽 +8) / +128 priority (141) / +132 type 枚举 (225: 10521→1/10522→2/11933→3/11405→0) / +136 category 枚举 (702: 默认 8, 10 值映射 writer 逆映射) / +140 option 布尔 (10598)。

**CMessageTypeSettings** (消息开关寄存器, 16B; vt 0x1429D8F40; writer 0x141578A80 / reader 0x141578810; 无独立单例 — 四实例内嵌于各 CMessageType +96..+127 槽, reader 内四处 vftable 写点直证; 勘误: 曾挂于本行的「单例 0x332EF60」实为 **message_handler 库单例 = CMessageHandler, 120B (vt 0x14293E0E8, 5 槽主表无 Save/Load = 库壳不入档; 名→条目 map + 条目登记向量 +112 消费门**)): +8 u8=1 / **+12 u32 五路开关位掩码: bit0=onmap(10677) / bit1=log(10676) / bit2=popup(10678) / bit3=pausepopup(11064) / bit4=icon(181)** (writer 逐位 unmask, reader OR 逐位置位)。玩家消息路由被持久化 (存档实写)。

**聊天/大厅持久件族 (MP 会话元数据域)**: **CChatMessage** 基 (vt 0x142B498B0; slot[2] writer 0x1422E77D0; +8 message CString) → CStandardChatMessage (0x142B49920, slot[2] 0x1422E7930, +48 user) / CPersonalChatMessage (0x142B49990, slot[2] 0x1422E78A0, +48 alluserlist (u8 布尔) / +56 user / +88 userslist 链) / CCountryChatMessage (0x142B49A00, slot[2] 0x1422E77F0, 再 +112 id / +120 name) / CSystemMessage (0x142A0E8D0, slot[2] 0x1422E7980, +48 key_value_pairs 串对向量 stride 64)。**CChatMessageObservable** (持久槽异位: [6]=Save / [7]=writer 0x14226A110 / [8]=Load / [9]=reader 0x142269E60 — serfam [2]/[4] 指纹盲区实例): 写 default_state (499) 打包记录 {+12 u32 / +22 u16 / +24 u8 / +28 u32 / +32 u32} + object (65) 历史块; ⚠ [7]/[9] 与 §4.00.7 CCommand 家族共享 writer/reader **同址** — 数据语义按 chat 上下文读, 非命令对象。**CGameLobby / CLargefileHandler / CLargefileHandlerInterface** (三类共享 writer 0x142220340 / reader 0x14221FC10): 本体 = CID 对 {+8 u32 type(225), +12 u32 id(11)}, 落 `id = { … }` 块 (大厅/会话元数据, 高置信)。**CPdxSocialPlayerId** (vt 0x142969418; writer 0x142401C80 / reader 0x142401250): +8 u32 id / +24 平台→u64 RH 表 (stride 40), 键 765 pops_id / 767 msgr_id / 374 steam_id。

**多人社交权限运行时单例 (PdxSocialPermissions 簇; bootstrap 构造, 不入存档)**: 管理器 56B (vt 0x142b6ef00 单槽 dtor; 全局 **qword_1435DA858**; TBB 装配后 bootstrap sub_140126E50 → 构造 sub_142400C10: malloc(0x38), +8 u8=0, **+16 = ChatBooleanPermission\***, +24 u32=0, +32 16B 容器清零; getter sub_142400B10 / Release sub_142400CD0)。**BooleanPermission** 抽象基 8B (vt 0x142b6eeb0, 4 槽 [1][2][3] purecall)。**ChatBooleanPermission** 64B (vt 0x142b6eed8): +8 u8 enabled (ctor 1; 槽[1] 直读) / +16..+39 列表 A 头 / +40..+63 列表 B 头 (双 {data, …, count@+12} 48B 条目黑名单; 条目命中 = entry+8 dword == arg+8 dword 或三侧字段比较, **屏蔽单语义**); 槽[2] evaluate = `enabled && !match(A) && !match(B)`。权限键串紧邻 vtable (0x142b6ef08, 16B 定长): `social_debuginfo` / `social_joinroom` / `social_sendmessage` / `social_addfriend`。runtime-only (全 dump 无 writer/reader/存档键)。

#### 4.28.11 CSettings / CSystemSettings (settings.txt 总表; 双向往返)

**CSystemSettings** (基类子对象 @CSettings+0; vt 0x142B3B9A0; writer 0x14222B100 / reader 0x14222AE20; Reset 0x14222A440; f32 写原语 0x1424C3100 值走 xmm0):

| 偏移 | 类型 | 键 (token) / 语义 | 默认 |
|---|---|---|---|
| +152 | CGraphicsSettings* | graphics (193; refreshRate 在此类内, 与本类分开取) | — |
| +160 | 串 32B | language (187) | — |
| +192 | float | master_volume (237) | 100.0 |
| +196 | float | dev_master_volume (586) | 50.0 |
| +200 | float | sound_fx_volume (231) | — |
| +204 | float | music_volume (232) | 75.0 |
| +208 | float | ambient_volume (322) | 50.0 |
| +212 | float | voice_volume (740) | — |
| +216 | float | scroll_speed (233; CSettings::Reset 覆盖 22.0) | 50.0 |
| +220 | uint8 | corner_scrolling (800) | — |
| +224 | float | camera_rotation_speed (234) | — |
| +228 | float | zoom_speed (235) | — |
| +232 | float | mouse_speed (236) | — |
| +237 | uint8 | graceful_exit (736, 仅真值落盘) | — |
| +238 | uint8 | minimap_visible (741) | — |
| +304 | 串 32B | last_game_version (747) | — |

**CSettings** (≥968B; vt 0x142724468; writer 0x1401FC6F0 / reader 0x1401FB010; Reset 0x1401FA720; 未知 token 回退 CSystemSettings reader 同函数):

| 偏移 | 类型 | 键 (token) / 语义 |
|---|---|---|
| +376 | 匿名结构 (NNB 形状) | mapRenderingOptions (10247) |
| +416 | 串 32B | lastplayer (10254) |
| +448 | 串 32B | lasthost (10255) |
| +480 | 串 32B | editor (12154) |
| +512 | 串 32B | editor_postfix (13654) |
| +548 | u32 枚 | debug_saves (11591) |
| +552 | u32 枚 | **autosave (10784): 0=NEVER 1=DAILY 2=WEEKLY 3=MONTHLY 4=HALFYEAR 5=YEARLY** |
| +560 | float | windowmovetime (10277) |
| +564 | float | radialstaytime (10278; **reader 有 writer 不写 = 只读残留**) |
| +568 | uint8 | hints (10282) |
| +572 | float | camera_speed (669, 钳 [5.0,95.0]) |
| +576 | float | camera_tilt (671, 钳 [5.0,100.0]) |
| +580 | uint8 | centered_zoom_in (670) |
| +588 | uint8 | outliner_open (10276) |
| +589 | uint8 | autosave_tocloud (11574) |
| +590 | uint8 | save_career_to_cloud (15954) |
| +591 | uint8 | skip_setup (12627) |
| +592 | uint8 | force_pow2_textures (11029; 读入触发纹理重载) |
| +594 | uint8 | hide_daynight_cycle (13731, 仅真值落盘) |
| +596 | uint8 | show_allied_plans (13732, 仅真值落盘) |
| +597 | uint8 | use_ingame_browser (13779) |
| +598 | uint8 | default_offline_wiki (13892) |
| +599 | uint8 | save_as_binary (13827) |
| +600 | uint8 | pause_on_popups (13917) |
| +601 | uint8 | popup_news (14387) |
| +602 | uint8 | popup_events (14388) |
| +603 | uint8 | popup_minor_events (12940) |
| +606 | uint8 | show_game_status (15427) |
| +607 | uint8 | awards_message_seen (16003) |
| +608 | uint8 | use_silhouette_portraits (19533) |
| +609 | uint8 | strategic_regions (12013) |
| +610 | uint8 | lockable (285) |
| +611 | uint8 | telemetry_enabled (10324) |
| +612 | uint8 | event_sounds (12840) |
| +616 | uint32 | combat_sound_random (11051) |
| +620 | uint32 | max_players (11053) |
| +624 | uint8 | show_doctrine_details (16746) |
| +632 | 匿名结构 (32B 形状) 向量 | save_date 历史 {d@632, c@644}, 32B 条, 逐条 token 13503 |
| +656 | 匿名结构 (元素待裁) 向量 | shown_legal_documents (15236) |
| +680 | uint32 | counter_color_mode (13446, 钳 [0,1]) |
| +684 | uint32 | template_counter (13549, 钳 [0,1]) |
| +688 | uint32 向量 | custom_mapmodes {d@688, c@700}, u32 条 |
| +712 | 匿名结构 (元素待裁) 向量 | sub_messages_seen (15929) |
| +736 | int64 | time_last_sub_message (15930) |
| +744 | 匿名结构 (NNB 形状) 向量 | 键 593 (名与语义不符, 待裁) |
| +768 | 匿名结构 (NNB 形状) 向量 | 键 156 (同上待裁) |
| +792 | uint8 | is_always_aprils_fools (15029, 仅真值落盘) |
| +800 | scoped_ptr<匿名结构 (8B 形状)> | **game_rules 数据对象 (15202 块)**, 元素 8B {u32,u32} 对; +808 = 已载入旗; 相关全局 qword_14332EF20 |
| +896 | SCVAASettings 56B 内嵌 | cvaa_settings (19674; ctor sub_1401F9E60: {vt@0, dword@8, word@12, 子对象@16 sub_142271DE0}; 下写点 +952 界定跨度 56B; VAA 渲染设置块, 展开待裁) |
| +904..+909 | u8 位旗区 ×6 | 运行期旗 (Reset `dword@904 = 0` 清 +904..+907 + `word@908 = 0` 清 +908/+909; writer/reader 均不触及 = **runtime-only**, settings.txt 与 savegame 均不落盘)。+904 = chat 域旗 (getter sub_1419B27B0; ChatSettingsProviderImpl 薄 getter 委托); +905 / +908 = 语音无障碍族读 (SpeechInputTextboxHandler ctor 拷入自身)。高置信 (复位/读点直证, 各旗位语义未逐位定名) |
| +912 | 匿名结构 (NNB 形状) | 16B 头 + u32 数组容器 — chat/大厅设置块 (**runtime-only**; Reset 经 sub_1401FA480 拷贝默认; getter sub_1419B2710 返址; ChatSettingsProviderImpl 6 薄 getter 全委托本域)。推定 (chat 域归属) |
| +952 | double | hotkey_activation_delay (19681; Reset 默认 0.1) |
| +960 | double | hotkey_actualization_delay (19682; Reset 默认 0.1) |

读侧忽略残留: 10259 outliner / 10535 interval / 10655 difficulty / 11537 last_dlcs / 11540 last_mods / 15944 playthrough_stats_highlights。安全区事故排查: autosave 在 +552 (枚举 int); refreshRate 在 CGraphicsSettings (vt 0x142B3B700, CSystemSettings+152 指针, writer 0x142229D60) — 两处分开取。

**CMapRenderingOptions** (mapRenderingOptions 块本体 = CSettings+376 内嵌子对象, 32B; vt 0x1427243C8 9 槽; 基 CPersistent; writer 0x1401FC580 / reader 0x1401FAE80; **settings.txt 域, 不入 savegame** — savefull 导出 draw_*/texture_quality 零命中负证): 落盘序 = 偏移升序。布局:

| 偏移 | 类型 | 键 (token) | 容器 ctor 默认 |
|---|---|---|---|
| +8 | uint8 | draw_terrain (10262) | 1 |
| +9 | uint8 | draw_water (10263) | 1 |
| +10 | uint8 | draw_borders (10264) | 1 |
| +11 | uint8 | draw_trees (10265) | 1 |
| +12 | uint8 | draw_rivers (10266) | 1 |
| +13 | uint8 | draw_postfx (10267) | 1 |
| +14 | uint8 | draw_sky (10268) | 1 |
| +15 | uint8 | draw_bloom (10269) | 1 |
| +16 | uint8 | draw_tooltips (10270) | 1 |
| +17 | uint8 | draw_hires_terrain (10271) | 0 |
| +18 | uint8 | draw_citysprawl (10272) | 1 |
| +19 | uint8 | draw_shadows (10273) | 1 |
| +20 | uint8 | draw_weather_effects (13972) | 1 |
| +21 | uint8 | draw_water_reflections (13973) | 1 |
| +22 | uint8 | draw_units (13975) | 1 |
| +23 | uint8 | draw_buildings (13976) | 1 |
| +24 | uint8 | high_gfx_shaders (13977) | 1 |
| +25 | uint8 | draw_map_full_res (13978) | 1 |
| +28 | uint32 | texture_quality (13974) | 0 |

#### 4.28.12 CLauncherSettings 与存档弹窗胶水

**CLauncherSettings** (~40B; vt 0x142B406F8; writer=CFG (**游戏进程从不写该文件**, launcher 侧自写); reader 0x1422744C0 通用分节解析): +16 sections 容器 {d@16, c@28}, 56B 元 = {节名 SSO 32B, 设置表 {条 = SPdxSetting\*}}; 伴生 **SPdxSetting** (112B, vt 0x142B40748): +8 name SSO / +40 value SSO / +72 value2 SSO (语义待裁)。三级回退的路径解析属 launcher 侧, 本类只持内容容器。

**CDLCDescriptor** (mod/DLC 描述件解析回写器; vt 0x142AF85C0; writer 0x14207D230 / reader 0x14207AE90; **解析/回写 descriptor.mod 域, 不入 savegame**): 12 键字段映射 = name@+8 / path@+104 / archive@+136 / dependencies@+168 / replace_path@+192 / user_dir@+216 / tags@+312 / picture@+336 / supported_version@+368 / category@+456 / version@+488 / remote_file_id@+520 / description_file@+552。

**CSaveGameController / CSavedGameRulesController** (名录; 各 ~264B; vt 0x14273AD18 / 0x142AA6360; 均非 CPersistent, [1..3]=_purecall 0x14253C3B8 未覆写): **= 存档弹窗复选框胶水** (CCheckBoxObserverGlue 内嵌 ×2 + 状态字 +256), **不是 resave/存档写入引擎** — sv2_export 重存不经过; 存档游戏规则真实数据 = CSettings+800 game_rules 对象 (15202, settings.txt 通道)。同族窗 = §4.31 savedgamerules/delete-save 族。

#### 4.28.13 CRandom 计数器随机流 (multiplayer_random_seed/count; 无独立 RTTI 类)

**CRandom** (无独立 RTTI 类 — 负定案, 纯数据流类无虚表; 名称取 PDB 源 clausewitzlib/random.cpp)。流状态 = {count, seed} 双 u32, 取值 = **计数器型纯函数** (非 MT 状态机): `v4 = 1255572915*count++; v5 = ((seed-v4) ^ (seed-v4)>>8) + 1759714724; v6 = (458671337*(v5 ^ v5<<8)) ^ (... >>8); 返回 ((-1831433054*v6) ^ (...>>8)) & 0x7FFFFFFF`。存档只需 {count seed} 两数即完全复现未来序列 = 存档 `random={a b}` 形态契约的根据。同函数带断言「Calling random inside forbidden area! This will cause OUT OF SYNC!」(random.cpp:181) = 联机确定性核心。

| 项 | 值 | 语义 |
|---|---|---|
| 全局 count | RVA 3452520 (VA 143452520) | 每抽 +1; 落盘 = 顶层 multiplayer_random_count (读档逐位吻合定案) |
| 全局 seed | RVA 3452524 (VA 143452524) | 落盘 = 顶层 multiplayer_random_seed |
| SetSeed(int) | 0x142234550 | 单 int 哈希派生 seed+count 双字段 (公式闭环验证: 传 123456 → 运行时 seed/count 逐位吻合; 双哈希混拌常数 2126043716/282605150/1831007003 → seed, 542824007/947560250 → count = 上注链 A/B 十进制同值, 控制台批独立重读互证); 调用者 = 控制台 **`random_seed <int>`** 命令 (ConsoleCmdImpl.cpp, 回显 "Random set to: N"; **无 debug 门, 无 debug 会话实测可用**; 命令 argc==0 无参路径 = seed 取随机值重播同路径) + 会话启动随机化分支 (0x141CD9D80, 新开局播种); ⚠ 同族不存在名为 `random` 的命令 |
| SetRandomCount(int) | 0x1422345C0 | **count 直写** (`dword_143452520 = count`), 控制台 `SetRandomCount <n>` 命令 (回显 "RandomCount set to <n>"); multiplayer_random_count 的控制台写通道 (此前书内只有读侧 sub_1401F2E40) |
| 全局流入口 | 0x142233FA0 | random_int(file, line) — file/line 仅调试记账; 191 调用点 / 55 源文件: country 28 / airmission 13 / navalmission 10 / peaceconference 8 / state 8 / combatland 7 / nuke 5 / diplomacy 5 / army 4 / politics 3 / civilwar 1 … |
| 作用域流 | 同 hash 内联 200+ 函数 | 实例版 CRandom (对象内嵌 {count seed}) |

每作用域流 = 各对象 variables 块内 `random={count seed}` (单档 14,828 对: character 13,259 + 国家 GER 421 / ITA 207 … + 州): **作用域隔离的确定性流**, 本作用域抽随机不推进其他作用域的序列。改全局 seed/count = 重掷全部全局流后续抽取 (weather 每省每小时最先受影响, AI 判定/战斗/和会/核弹路径全部重掷, 实测与重放微扰同型且随时长混沌放大); 改某作用域对 = 只重掷该作用域。

| 停表对拍窗口 | 全量导出 DIFF+MISS | 结论 |
|---|---|---|
| +0h (同刻暂停态) | 0 / 2,833,399 MATCH | 读档+导出管线位级确定 |
| +48h 重放 vs 改种子 | ≈8.3 万 ≈ 8.5 万叶, 同型分布 | 改种子 = 与重放微扰同量级的流重掷 |
| +480h | ≈21 万叶 | 散布随时长混沌放大 |

算法术语澄清: 本流实为**计数器哈希流** (seed − 1255572915×count 三轮移位乘混合, 无 LCG 状态、无 stream/output 双变换结构), 非 O'Neill PCG — 书内他处「random_fixed 全局 pcg」称呼按此理解, 公式描述本身正确。抽取四常数 {0x4AD685B3, 0x68E31DA4, 0x1B56C4E9, 0x92D68CA2} 与播种双链 exe 立即数逐位核验; **链A {0x7EB8DA44, 0x10D8365E, 0x6D22F31B}→seed / 链B {0x205AD647, 0xB4F3C315, 0x387A9F3A}→count 与 §4.32.16a CVariables 重哈希 murmur3 变体常数链同源** (双向印证)。

补全定案 (random.cpp 族 17 函数 + random.h 守卫 25 落点):

| 项 | 定案 |
|---|---|
| 播种双链 | SetSeed sub_142234550 = 链A→seed + 链B→count; **SetSeedOnly sub_1422345D0** (只写 seed); 读档恢复 = gs 键分发器 sub_1401E59D0: token 11458 → SetSeedOnly / token 11459 → SetRandomCount (原值直写) |
| OOS 调试域 | 入口三: 命令行 sub_14222F630 (-random_log / -light_random_log) / 控制 台 toggle sub_140279040 / 配置串 sub_140125090; 三门分工 = byte_143452529 每抽日志 / byte_14345252A weathermanager SetValue 日志 / byte_14345252B 入环 |
| 记录环 | **72 槽 × 40B 日期滚动窗** (OOS 对账域): gs 日 tick/时 tick 推进换槽, gs ctor/读档清场 (sub_142233720); random_state 双变体 (LightRandomLog) 检查点挂点 = character_manager / navaltransfer / aces / countryleader; **记账函数 = sub_142234110(value, file, line, tag)** (random.cpp:325/329; 非主线程断言 latch byte_14345307A); **环条目 40B 布局 = {+0 u32 kind(=0), +8 file 串指针, +16 line, +20 value, +24 tag 串}**, 游标 dword_143452530 (记账函数不自增, 环推进在槽切换处); sub_142233FA0 用同布局写环 (无 tag); CGameState::Save 主块 writer 的 "Start/End of gamestate checksum" 标记亦经记账函数入环 (value = 存档流 running hash, line=3319), 控制器重置族以 (0/1, "gamestate.cpp", line, 0) 打确定性变更追踪标记 |
| 禁场守卫 | 旗 byte_143452528 = **诊断绊线非阻塞门** (抽全局流只触发 random.cpp:181/187 OOS 断言不拒绝); 守卫可嵌套 (save/restore 旧值), 唯一实测嵌套 = 每帧一步 sub_14222EEB0 (全帧禁场 + app+64 条件子区解禁); 解禁子区惯用式 `sub_1422345B0(0)→子区→restore` (InitData 逐国 init 段实测); 禁区两大目的地 = tbb 并行相位 与 自持 RNG 子系统 (天气/CAce/脚本作用域)。⚠ **三条断言各自独立 latch 勿混**: random.h:74 主线程断言 latch = byte_14332EDF8 / random.cpp:181 禁场抽取断言 latch = **byte_143453078** / random.cpp:325 LightRandomLog 线程断言 latch = **byte_14345307A**; gamestate.h 访问断言 :1116/:1117 latch = byte_14332EDF9/EDFA, :1125/:1126 第二组 = byte_14332ED00/ED01 |
| 并行相位种子注入 | **串行相抽一次 → 实参传入 tbb pass, 相位内禁场** (gamestate.cpp:6227/6310 日更、5216 小时更三点连线, 抽取值进 functor 实参逐字节直证); 战区带 tbb lambda 符号直证 = sub_140EF18B0 DispatchBundle(InterpolatedFrontBundle) / InitSectionsForCountries 与 InitializeTheatresForEveryone 两符号实在 sub_140EE8160 体内; **sub_140EFAC10 = TheatreManager 全员初始化分发包装 (InitializeTheatresForEveryone 形, (bool,bool) 签名 → sub_140EE6970(1, count, jobType=3))** — 旧「战区事件分发」名废; sub_140EF88B0 = 按国遍历 +360/+372 分桶重建 (名称归属待核); sub_140EFAB20 = DispatchConquer 内步 (按省增量派发) |
| 实例版 CRandom | CAce 创建 sub_140618860 逐指令直证: 头部内联 SetSeed 双哈希链造局部 {seed,count} 私流抽取, 不耗全局流 |
| random.h:150 RandomElement | 均匀随机取元素模板 `(Get & 0x7FFFFFFF) % n`, 三消费者: sub_1412ABD80 陆战/岸轰附带伤害受击目标 (crit 门 = SHORE_BOMBARDMENT_COLLATERAL_DAMAGE_CRIT_CHANCE_FACTOR) / sub_14144CC20 勋章随机授勋 (概率门 unit_medals.cpp:1038, 修正值 + qword_143337718) / sub_140FDC3A0 反谍捕获执行 (**加权变体**: 同国/同原初国双权 dword_1433342B8/143334448 — 非 define loader 槽, 名未取) |
| 天气守卫入口 | sub_140147D20 = 守卫 enter 非内联提取版, 唯一调用者 = CWeatherManager::HourlyUpdate — 天气先 mgr+776 += random_int 再禁场跑内部模拟 (§4.20 互证) |

random.h 簇增补 (定案/高置信批): **byte_143452529 双语义** = ① 每抽日志门 (random.cpp:258/329) ② **StartAllAI 串行回退开关** (sub_1401EF500: 门开 → 逐国串行启动; 关 → tbb parallel_for CStartAIThreaded — 保证日志序 = 抽取序; ingameidler.cpp:4941 日志亦挂此门, 按串锚定域排查时命中 ≠ 业务常开日志)。**CEventScope 随机对 = +12 count / +16 seed** (与 gs 全局对同链同构异位; 效果文档导出 sub_14053F460 出口对 scope 种子对**无条件重哈希**: 链A→+16 seed / 链B→+12 count, 常数与 §4.28.13 链A/B 逐位同源; 嵌套计数 dword_143330008 = 效果文档库深度计数)。**空军基地共享实例流** = ProcessAirBasesHourly 尾相 (strategicair.cpp:7144 全局抽 r) → 栈上对 {count=r, seed=1587985055−r} 全体基地顺序共享 → sub_140C60290: 10% 门 (draw%100000<10000) + 均匀索引 (次抽 % 基地+196 计数, 取 +184 数组元素 — 数组语义待裁)。**"All theatres rebuilt" 调试命令执行器 = sub_1402792C0** (sub_140CF59A0 + sub_140EF9150 全局重置连跑; 重置复位清单全落 NTheatreManager 三组静态范围)。并行作业域开闭对 sub_1402200E0(槽,type)/sub_1402203F0(槽) (daily=2/hourly=0/ai_update=5, type 语义待裁)。

#### 4.28.14 CInGameIdler (会话 idler; 暂停域 / 驱动契约 / 实例布局)

对象身份 (全局槽 `BASE+0x332F698` = DLL 侧 APP_MGR_PTR, vt RVA 0x2968FF0)、
暂停旗位 (+1729 / +1731 / +1680 / +1681)、三写槽 ([82] 设值 / [91] 自动存档 /
[94] toggle) 与引擎调用链 —— 全表收主文件 §1.1b 与 §1.1b.1。
时序链中的行为契约 (Idle/生成门/六节拍) 归 §4.2.1/§4.2.4; 本节收家族与实例布局。

**家族虚表** (COL→RTTI 定案): 基 CGameIdler 主表 0x142736280 (槽[4] = Idle,
槽[11] = OnEnter, 槽[17] = 读 +896 = CSession*); CFrontEndIdler 基表 0x142949D50
(117 槽, 覆写集中 0-63 与 64-69; 前端态槽[64..69] 全为 return-0 桩 — 菜单态
节拍空操根源); CInGameIdler 主表 **0x142968FF0** + 三子表 (+8 = 0x1429693B0 /
+1512 = 0x1429693D0 / +1520 = 0x1429693F0)。调试支族 CMapIdler/CNudgeIdler/
CNullIdler 归 §4.00.9。

**实例布局补全** (ctor sub_140DC1B30, 0xB30B; dtor sub_140DC3C00; 与 §1.1b.1
暂停域互补):

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +36 | f32 (推定) | 帧时长 EMA (槽[29] 帧尾: 0.95×旧 + 0.05×新) | 槽[29] |
| +64 | u64 (QPC tick) | 本帧耗时 (sub_1401F7F80 前后掐表) | 槽[29] |
| +1264 | 指针 | **渲染管理器** (槽[28] 就绪门实参 / 槽[29] 段 2/5/9 消费) | §1.1b.1 家族槽 |
| +1328 | 指针 | **idler 管理器 = CApplication 本体** (字段: +56 current / +112 待入 / +120 旧 / +64 切换请求旗 / +128 保留旗) | SetIdler = sub_14222EA60 |
| +1457 | uint8 | 遮罩/输入联动边沿缓存 (槽[28] 段 1) | 槽[28] |
| +1512 | vptr | 子对象 C 表 (0x1429693D0) | |
| +1520 | vptr | 子对象 D 表 (0x1429693F0) | ctor 装 "interface/main.gui" 串 |
| +1713 | uint8 | 框选态 (槽[29] 段 4 门) | 槽[29] |
| +1720 | 指针 | **iface = CInGameInterface\*** (§4.30 主视图; s4_17 定案同址) | 其内含六节拍注册表 (年/5月/月/周/日/时 分档, 查询槽[64] 过滤 → 分档执行槽驱动窗口刷新) |
| +1728 | uint8 | toggle 置位旗 (slot[94] 体写 1) | §1.1b.1 |
| +1729 | uint8 | 暂停权威位 (1=冻结) | §1.1b.1 全表 |
| +1731 | uint8 | 连按 pending 伴随位 | §1.1b.1 全表 |
| +1732 | uint8 | Idle 内第二暂停门 (CInGameIdler::Idle 0x140DD3A50 体: `帧耗时 && !+1729 && !+1732` 才调时间调度器) | 与 +1731 (toggle pending) 并存勿混 |
| +1764 | u32 (推定) | 框选点 1 (槽[29] 段 4 五顶点绘制) | 槽[29] |
| +1768 | u32 (推定) | 框选点 2 | 槽[29] |
| +2073 | uint8 | 截图完成一次性旗 (横幅发射后帧尾清) | dword_14333CF70 = 保显倒计数 |
| +2080 | uint8 | 存图完成一次性旗 (同上) | dword_14333CF74 = 保显倒计数 |
| +2216 | uint32 | **GUI 小时脉冲倒计时** (节拍槽[64] 用) | |
| +2396 | uint32 | **加速脉冲计数** (时间加成 min(2.0, 1+0.2×计数); 每 tick 生成后 sub_140DE4DE0 减 1, clamp 0) | §4.2.2 |
| +2400 | 匿名结构 (NNB 形状) 向量 | 教程章向量 (§4.28.15 族) | |
| +2424 | 匿名结构 (NNB 形状) 向量 | hint 向量 (§4.28.15 族) | |
| +2448 | 内嵌 | CTutorialMinimized (§4.28.15 族) | |
| +2560 | 弹窗队列管理器 (80B 无虚表, malloc) | 生涯勋章/绶带弹窗队列宿主 (帧消费 sub_140DD3A50 → sub_1419C5390 三分支; ctor/dtor 挂卸, §4.28.8) | |

**驱动契约** (定案): Idle = 0x140DD3A50 (基类 CGameIdler 槽[4] 覆写; 每帧经
管理器派发, §4.2.1); **OnEnter = 0x140DE0150 (jmp thunk → setterB sub_1402A2A30:
qword_14332F698 = qword_14332F6A0 = this)** — 前端 CFrontEndIdler::OnEnter
(sub_140B3E1F0) 只写 F698, F6A0=0 → 时间调度器空操 = 「在游戏中」判据根源;
构造 = malloc 0xB30 (游戏开局 sub_140B3E9A0 尾) / 前端 = malloc 0x640
(InitGame sub_1401835A0); 前端 ctor sub_140B3B290。

**帧渲染槽对** (定案): 槽[28] (基 CGameIdler 0x142736280; 语料 thunk 0x1402A1700 +
体 [0x2A1716,0x2A1898)) = **每帧渲染驱动** (与 interface.tick 中央 tick
sub_140B68600 并列 — 后者归 §4.00.4 CInGameUpdateableInterface, 不经渲染链) — 加载遮罩/输入联动 (byte_14332F6A8 门 +
idler+1457 边沿, 枚举 ≤8 项启停, 联动对语义待裁) → 渲染就绪门 sub_1422370E0
(graphics.cpp:2440) → 过门 `vt+232` 间接调槽[29] → 帧时长 EMA idler+28/32/40/44
(0.95/0.05)。槽[29] (CInGameIdler 0x140DDDDF0 / CFrontEndIdler 0x140B3D860) =
**帧渲染 + 瞬态状态横幅**: 段 5 渲染 (全局跳渲染旗 byte_14332F6A9 门 →
sub_14223D2C0 渲染帧入口 → sub_14223D3F0 **CGraphics::Render2dTree (定案**, tbb lambda 符号直证; 双 2D 树 +496/+864 与派发链详 §4.35.4) 2D 元素树
tbb 并行遍历, 渲染队列 qword_1434530A0 — 真名高置信) + 段 8 四条横幅 (门 = idler+1681
自动存档伴随位 / idler+2073 ∨ dword_14333CF70 倒计数 / idler+2080 ∨ dword_14333CF74 /
byte_14333CF38 "Running Test..."; 发射 = 串构造 sub_142245E60 → sub_140B411B0 顶栏) +
**ImGui 观察窗旗表刷新** (idler+2608 = 观察窗 28 槽对象, sub_141198E70 在全局旗门下调; 旧「教程帧更」误标 — 教程帧更的门在 gs+2615/gs+2608, 走 §4.28.18 教程链, 异类勿混) + 帧尾 EMA idler+36 / 本帧耗时 idler+64 + 旗清扫。观察窗工具族 = 内嵌 Dear ImGui ("Debug##Default" 串直证, 上下文槽 qword_143451C80)。
**每帧对象/动画分发泵** sub_14029EEF0: 双 idler Idle (0x140DD3A50 / 0x140B3CA20) 每帧直调
(xref 全集), 双缓冲轮选 + 半程相位判定 → sub_14222EB50 = **地图 Idler 每帧对象更新分发**
(CMapIdler::[4] 亦调; 高置信): 矩阵作用域缓冲 → 逐实例 64B 世界矩阵快照 → 分发
(byte_1430BDDF2 → tbb 动画推进 / 表+40 → 142291D40 批量实体提交 → 逐实例 2283E70 /
byte_1430BDDF1 → 效果更新 / 表+0 → 矩阵上载) → 14225D540 死对象清扫; 体内零文件 IO, 与 .scache 无关 —
".scache" 串全语料唯一落点 = 0x240EEE0
(shader cache 读/写, 调用者 0x142410B70/0x142417B40)。
**实体动画时间线更新器 sub_142283E70** (pdx_entity.cpp:1524, 定案; 采样 4.3% 大叶):
4 平面 SSE 剔除门 → 四叉树递归 → 每实例动画时间推进 → 1096B/条事件表扫描 (附件点名/
子原型/效果/音效) → 到时生成音效与附挂实例 + 骨骼 4×4 SSE 复合 (14228AF80 — ⚠ 收窄: 该函数实为**实例逐帧动画/附件更新器递归全链** (时间归一/TTL/特效/动态子实体/播完销毁), 4×4 SSE 复合仅其 mode 3 变换段, pdx_entity.cpp 簇定性; §4.35.17) →
播完不循环则销毁。渲染路径其余锚 (高置信): 2D 树分拣递归 223BB10/BB69/BB95 →
绘制循环 223DB98 (剪裁推栈); 子区间更新 223EC5B → 22AE800 (节点布局+命中测试);
桶化 draw 分发器 2279674/2279DE3; CBitmapFont 字形批 229B020/查找 229B4D0;
GridBox 族 22C6F0D/6FA5/7E50; 地图渐变边框 CGradientBorder::Update
sub_140159BBE0 + 层重算 sub_1401599270 (脏矩形 + CClearBufferThreaded/CFillBufferThreaded
并行填充, 高置信)。
**开局初始链** sub_140DD6A30 = 槽[6] (ingameidler.cpp:4888): Hourly + Daily + Weekly +
Monthly 各一遍 (§4.2.7)。Idle 另链 sub_140A67810 → sub_140E1A890 (更新) +
sub_140E1DAA0 (应用) 每帧国家级双管理器 → 写 cc+1696/cc+1700 → 触发 sub_140B59200
重算 — 链路高置信; **sub_140B59200 (8264B) 定案 = 按 8 通道重建分组条目表**
(逐国遍历 gs+700 / case2 派系 gs+712 / 32B 条目去重键 obj+164; B58430/B58440 写
+1700/+1696 后尾跳入)。
**三 idler 公共帧更新体 sub_140B58470** (定案, 两窗 11.7%): CFrontEndIdler (0x140B3CA20) /
CInGameIdler (0x140DD3A50) / CNudgeIdler (0x1412D49D0) 三者 vt[4]=Idle 共同直调 —
延迟对象队列 + 子系统表 a1+1776..1840 分发 + gs 容器 vt[16] 三连复位 + 计数清零;
其 a1+1840 子系统 = **战略地图路线/箭头绘制总控 sub_14165FB20** (5 个 CPdxMap
线对象池 → sub_140165D050 待绘条目物化 → sub_14012664D0 折线加点器 (1e-5 定点,
缩放自适应重采样, 8192 点 flush) → sub_140126AE10 地形贴合缎带网格构建;
高度采样原语 sub_140A60F10, u8 高度图双线性 ×0.1)。

**CFrontEndIdler 帧侧契约** (主表 0x142949D50; 菜单/载入屏帧循环):
Idle = 槽[4] **sub_140B3CA20** (frontend.cpp:177 帧循环; 内嵌右键菜单路径与
事件泵)。**StartNewGame = sub_140B3E9A0** (帧尾状态机拍, 首行门
`u8(this+1591)` 启动请求): 日志 "[[ Launching SINGLEPLAYER-game ]]" /
MULTIPLAYER; 构造 CInGameIdler (malloc 0xB30 → ctor sub_140DC1B30) 后调
SetIdler 切入游戏。回主菜单对称路径 = Idle (0x140DD3A50) 内嵌序列 (调用点
RVA 0xDD6668, 日志串 "EXITING_TO_FRONTEND"): SetGameStarted
(qword_14332F260, 0) → 构造 CFrontEndIdler (malloc 0x640 → ctor
sub_140B3B290) → SetIdler。读档/新局世界构建在 FE 帧上推进 (装载器
sub_141DEA910 与 CGameLobby 状态机 sub_140DA3F20), 完成后才切 InGameIdler —
**世界构建期引擎仍跑在 FE 帧循环内** (崩溃定案, 见 archive/t93_crash/)。
退出点火器 = **sub_14027E060** (读全局 F6A0 当前 idler → 置 idler+1913=1,
Idle 退出序列的唯一放行门; UI 确认按钮与程序化退出同用此点火, 实测置位
2 秒内完成 FE 构造 + SetIdler)。

FE 旗族与载入回调槽 (实例布局增量):

| 槽/偏移 | 值/类型 | 语义 | 备注 |
|---|---|---|---|
| 槽[4] (+32) | 0xB3CA20 | Idle 帧循环 | 前端态唯一帧驱动拍 |
| 槽[14] (+112) | 0xB3D400 | IsLoadingComplete | `return u8(this+1590)` |
| 槽[55] (+440) | 0xB3D410 | RequestStart | 置 u8(this+1591)=1 + "start_game_02" 音效 |
| 槽[80] (+640) | 0xB3D750 | SetLoadingComplete | 置 u8(this+1590)=1; CStartGameCommand::Execute (sub_14163DA10) 尾部落此 |
| 槽[84] (+672) | 0xB3BE00 | QuitToDesktop 序列 | 置 u8(this+1593)=1 |
| 槽[111] (+888) | 0xB3D4B0 | **OnSaveGameLoadBegin** | 读档开始回调; 派发点 = sub_140DA04F0 (vt[+888]) |
| 槽[112] (+896) | 0xB3D6C0 | **OnSaveGameLoaded** | 读档完成回调; 派发点 = sub_140DA04F0 (vt[+896]); 后接槽[58] 相机定位 |
| +1568 | CGameLobby* | 读档/新局大厅宿主 | ctor sub_140D975E0 (三 vtable 实名, 双基同表), owner 反指 +1168; 模式 state@+1204; Update = sub_140DA3F20; 全布局与开局链见 §4.28.18 |
| +1590 | uint8 | 载入完成旗 | 槽[80] 置 / 槽[14] 读 |
| +1591 | uint8 | 启动请求旗 | 槽[55] 置 / StartNewGame 消费 (消费时清 0 再置回 1) |
| +1593 | uint8 | 退出中旗 | 槽[84] 置 / Idle 尾部事件泵门 |
| +1904 | CGameLobby* | 第二大厅槽 (InGame 侧; ctor 亦 malloc(0x4C8)+sub_140D975E0 独立构造, 与 +1568 不同槽) | |

**六节拍槽 64-69** (主表 0x142968FF0; GUI 侧脉冲, 详行为注记 §4.2.4 步骤 15):

| 槽 | 字节偏移 | 函数 | 语义 |
|---|---|---|---|
| [64] | +512 | 0x140DDA020 | 每小时: GUI 日期脉冲 + idler+2216 倒计时 / idler+1680 旗 |
| [65] | +520 | 0x140DD9740 | 日: gs 四连到期清扫 + GUI 日刷 + 游戏条目日期激活 |
| [66] | +528 | 0x140DDAC60 | 周: GUI 周脉冲 + 超 100MiB 日志轮转 (filelogger.cpp:256, 备份 6) |
| [67] | +536 | 0x140DDA1B0 | 月: 月脉冲 + GUI 大刷新 |
| [68] | +544 | 0x140DD9FF0 | 每年 5 月 (month==5) |
| [69] | +552 | 0x140DDACC0 | 年 |

ingameidler.cpp worker 层补全 (定案):

| 项 | 定案 |
|---|---|
| 槽[7] RestoreDeviceObjects | sub_140DDE8A0 ("Start/End RestoreDeviceObjects" 日志直证) — 全量重建 (警报 mgr +1944 / 72B +1952 / 2648B +1968 (ctor sub_1419B4EA0) / 808B +2568 (ctor sub_140F3EDE0, 实参渲染管理器+1744)) + **强置暂停 +1729 = 1** + 相机跳玩家首都 (+1872 相机/地图对象) + idler+1816 CGameDate 重置 43808760 哨兵 — 原「警报管理器构造期装配」说法精化: 构造期首激活只是其触发面之一 |
| 槽[80] 会话开局初始化 | sub_140DD9B20 (簇外父入口 sub_140DDC350 = OnGameStarted 类: 教程复位 sub_1419B2B20(+2536)→装载→开局 init→MP 分支): **触发 on_start on_action** (qword_14332EFA0 条目库查名, onaction.cpp 断言直证; 确定性 RNG 锚 src 5446) + gs+712 派系逐项激活 (count@+724) + **暂停位裁决式** `!dword_14332EC58 ∨ (sub_1401E2930(gs) ∧ 无启动参) ∨ byte_14332EC57 → +1729` (EC58 = settings historical 链) |
| massconquer | 本体 = 独立函数 sub_140DE1040 (Idle 唯一直调); 两轮制/N 公式主文件 §1.1b.2 已载, 本批印证; 补全局 = dword_14333CF3C 每轮省数 / dword_14333CF54 受害 tag 数 |
| 启动参应用 | sub_140DCD9F0: settings "historical" → **gs+1592 = !v6 (取反写入定案)** — 启动参存在/为真 → 旗 0 (语义 = 「非 historical」开关, 缺省 = historical); "auto_start_game_rules" 逗号/冒号切分 → FNV-1a 小写哈希查规则注册表 off_1430C6DE0 (48B 桶, 哨兵 token 19479 双断言 :5378/:5379) 后应用 (断言 :5368 格式提示) |
| 存档族 | 本地自动存档 writer sub_140DD0980 (轮换数 dword_14332EC6C, ≤0 回退 **settings 表 +556 autosave 轮换 define**; meta 链经 **主表槽[110] 存档元管理器** sub_140DCCF20 → sub_140D9AA30/DA3530) / 日期序列存档 sub_140DD1320 (队列 +1688 {24B 元, +8 到期日}/count+1700, "autosave_date_\<日期\>"; 体内含 "mod/" 存档头路径规范化) / 落盘 writer sub_140DC9500 (返回码 0/1/2/4 = 成功/无效/磁盘不足/写败; **磁盘空间门** = CApplication+856 域 +856/+848/+856 取 free 量与现有+待写大小比较; 存档目录串对 = **CApplication+840/+848**) / **异步存档失败 lambda (宿主拆写定案)**: sub_1426182C0 ← 本地 autosave (断言 :4436) / sub_142618560 ← 日期序列存档 (断言 :4255); 日志后经 sub_14222BDC0(\*(idler+1328)) 取当前 idler **vt[+32] = Idle(0) 踢一帧保窗活** — §4.2.1「一帧 a2=0」的实测消费点 |
| 其它 | 省份颜色纹理构建 sub_140DCA860 (24bpp, CColor×255 截断, Knuth 哈希颜色→索引; 第二消费者 sub_1402B6A00 以 a5 区分两路径) / MP 聊天同步 sub_140DD2080 (单例 qword_14338A140, CSession 取用 = **主表槽[17]**; 本体仅消费 idler+4512 (float) 传 sub_141341460 → chat_mgr+468 累加 — 勘误: 旧注「idler+940 消息链/+2256 句柄, 成员表 88B/条」中 +940/+2256 未现于本体, 出处待裁, 或属聊天管理器对象自身偏移) / OOS 报告窗 sub_140DD8D60 (CODE/LONG + "GAME_IS_OOS" + "No_Gamestate" 占位; 调用者 = MP 消息 thunk **sub_140DE8340** (msg+40/+48/+80 转发)) / **OOS dump 生成器 sub_140DC7790** (1,402 行, 展开: 名 = **"OOS_\<TAG\|OBS\>_<日期>"** (观战 TAG = "OBS"; 「哈希」分量未见, 待裁可能在 zip 内容命名); 归档 12 系统条目 cached_random/random/error/game/system/setup/code_revisions/random_1/executed_commands/posted_commands/received_commands/sent_commands; **未压缩上限 2097152000 字节硬编码** 超限跳过并日志 :4067; 前置断言 "Unexpected missing system…" :3935; 手动触发器 sub_14024CBA0 返回 dump 名) / 选中省链槽[54]/[55] sub_140DC6B00/6CA0 (相机居中 sub_141262730; 断言 :817/:827) / FindHintByWindowName sub_140DC5610 (hint 向量 +2424; 窗名重复检测 "Duplicate name of hint window" :978; 消费者 = 教程 hint 打开执行器 sub_1419CA170) |

实例偏移增量: **+940** 聊天消息链表头 / **+1458** long-op 忙旗 (sub_14029EED0 置 / sub_1402A01B0 清; 联动 qword_143453230+585) / **+1688/+1700** 日期存档队列 {data, count} / **+1816** CGameDate restore 哨兵 / **+1872** 相机地图对象 / **+1968/+2568** restore 重建对象 / **+2256** 聊天句柄 / 教程 +2408/+2416 槽补全; hint 容器 = {data @+2424, count @+2436} (count = data+12, 引擎自定义向量形态, FindHintByWindowName 实读定案; +2432/+2440 未在该函数消费, 旧「cap/alloc 槽」注出处待裁) (+1272/+1304/+1312/+1320/+1936/+2074/+2536 = restore 期与开局脚手架, 推定档)。gs 增量: **+1592** historical 模式旗 (sub_140DCD9F0 写, 取反语义见上表) / **+724** 派系 count / +2615/+2617/+2618 on-action 门旗。记法澄清: s4_30「CInGameIdler vt[120]」= 主表基址 +960 起第二子表 (0x1429693B0, 对象 vptr@+8 所指) 首槽, **非主表第 121 成员槽** (主表实测 0..118 共 119 槽, slot[119] = COL)。

idler 家族基类与键查询面增补 (定案/高置信批):

- **CGameIdler 基类** (RTTI 名直证): ctor = sub_14029D800 / dtor = sub_14029DD00 (CInGameIdler ctor 首行调用, unwind 路径析构); **实例计数器 dword_14332F6C0** (ctor 自增)。基类布局全表 (ctor 清零 + 实参直证): +0/+8 双 vptr / +120 串 / +152 子对象 / +1152..1216 串×3 / **+1264 指针 (槽[104] 重置器消费)** / **+1268 指针** / **+1268+8 = +1272 渲染管理器 (ctor a2)** / +1280 / **+1288 = 内嵌 CButtonEventDispatcher 族键查询面** (赋值写点 = `a1[161] = &CButtonEventDispatcher::vftable'` 全语料 1262 处形态; 消费 = vt[+32] 键按下查询 (token 0x40000002/3/4 虚拟段 — **token 0x40000002 分支 = 全局跳渲染旗 byte_14332F6A9 的 toggle 写点**; vt[+48]/[+56] 修饰查询); **idler+2576 嵌套第二层同族分发器**, 槽[80] 开头消费) / +1304..1320 链表 / **+1328 = CApplication (ctor a4, idler 管理器)** / +1336 内嵌 CSelectionList (两步构造 CObservable→CSelectionList) / +1424..1496 串与链表域。
- **主表槽[104] = ResetGamestate sub_140DDE4A0** (新挂载定案, 虚表实读; 语料零静态调用点 = 虚调面, 触发者未决): "Resetting gamestate" 日志 :6691 → 释放 +1536 指针数组 {data@+1536, count@+1548} → +1256 对象 vt 槽[16] 重置 → sub_140DDE3B0(&byte_14332F5A0) 清理 → **+1733 (0x6C5) 守卫旗 = 1 → sub_1401A5630(\*(+1328) CApplication) 书签级世界重建 → 清 0** (与 +1729 暂停/+1731/+1732 并列的重置独占旗, 高置信) → "Gamestate successfully resetted" :6714。
- **InitData (槽[6]) 非 historical 分支** (行 4941 域, 高置信): 逐国循环 (国+8>0) → 守卫态 sub_1422345B0(0/1) → 状态位序列 sub_1406FF1F0 → debug 门日志 "Calling GenerateNonHistoricalAttributes for %s" → **sub_1406EB150 = 本体候选** → 属性容器重建族 → 国+808 域清。**进度上报 API = sub_14222E270(app, 步, n, 总, 0)**: InitData = 步 54 共 12 段 / RestoreDeviceObjects (槽[7]) = 步 59 共 10 段 + "LOAD_GFX" GUI 事件。
- 槽[80] 实现体补: 启动参全局对 qword_143085070/090 (消费后清零 + byte_14345244C 有参旗) / "on_start" 串直证 (查 qword_14332EFA0 条目库执行) / 派系循环 (gs+728 data +724 count) / **暂停位 +1729 写入后通知器 sub_140DE0160** (OnEnter thunk 邻位, dword_14332EC58 消费后清零) / 尾链 sub_140193F90 → sub_1401E43E0 → define 25 门 sub_140F2D910。

ingameidler.cpp 簇对账增补 (19 函数闭环; 簇界定 = 函数体内含 ingameidler.cpp 锚, Idle 0x140DD3A50 与六节拍槽 [64..69] 锚数 = 0 不在本簇, 归因方法差异非矛盾):

- **InitData (槽[6])** 深读新定案: ① **+2216 自动存档倒计时初始化点 = 尾段 `(gs+192 bit0) ? 168 : -1`** (铁人 168h = 7 游戏日, 非 -1 禁用; 与槽[64] 递减→+1680 闭环); ② **gs+1312/1316 两个读者侧消费点** — InitData 步 11 与槽[80] 非 historical 分支同选择式 `off = 1316; if (*(int*)(gs+1312) > 0) off = 1312;` (候选语义 = 开局焦点/起始国 id 对, 高置信; 写者未决); ③ 步 6 虚调 `vt+560` (=槽[70]) / 步 10 尾 `vt+128` (=槽[16]), 两槽语义待裁; ④ 尾段全局门 byte_14332F6FA → "ai_test_startup_effect" 串哈希查效果库逐国执行 (调试用开局效果广播, 高置信); ⑤ 函数身份 tbb lambda 符号 `CInGameIdler::InitData` 直证; 步 8 historical 分支调 sub_1401EF500 = StartAllAI (§4.28 增补条互证)。a2 参数语义待裁 (a2 = 0 分支多做焦点选择与 gamestate.h 簇辅助, 非 0 跳过)。
- **槽[7] RestoreDeviceObjects**: 重建对象尺寸/ctor 补全 — +1944 = malloc 100776B ctor sub_140AFDB60 / +1952 = 72B ctor sub_141756990 / +1968 = 2648B ctor sub_1419B4EA0 / +2568 = 808B ctor sub_140F3EDE0(idler, 渲染 mgr+1744); 两处 +1729 = 1 写点精化 = seg4 与 seg7 (seg7 门 = session 经 vt+136→+88 RTDynamicCast CNetworkServer ∨ CProxyServer; 单机分支走 sub_140DA1020 第二大厅槽)。
- **槽[80] 精化**: sub_140DE0160 通知器仅在 dword_14332EC58 ≠ 0 时调, 两分支共用 `dword_14332EC58 = 0` 消费清零; 启动参对 qword_143085070/090 两个分支都清 (sub_140129CA0 ×2), 有参门 = xmmword_143085080/0A0 任一非零。
- **槽[104] ResetGamestate**: +1733 守卫旗序列直证升级定案 — `+1733 = 1 → sub_1401A5630(*(a1+1328), a2) → +1733 = 0` 单线程窗口无分支; 增证: 重置中发 "100%" 进度串。
- **落盘 writer sub_140DC9500 返回码定案**: a2 无效 → 1 (:6586); 磁盘门 = `(free − 现有占用 + 新档大小) < 0` → 2 (free 量 = sub_1423DC2E0 经 app+856 对象); 写成功 → 0; 失败/CFileException → 4 (:6654)。目录串对 = app+840/+848。
- **FindHintByWindowName 容器形态定案**: {data @+2424, count @+2436} 元素 = CTutorialHint* (步进 8), 窗名 MSVC 串 @元素+2648 (size@+2664); 未命中日志 "Cannot find hint window to open named: %s" :6784 (新锚); 唯一调用者 = 教程 hint 打开执行器 sub_1419CA170。
- **异步存档失败 lambda** (0x1426182C0 / 0x142618560, 宿主 idler 槽 @+768/+1248): "Failed to write save file" → 尾 sub_14222BDC0 → vt[+32] = Idle(0) 踢一帧保窗活。
- 增证: OOS dump 生成过程发 "AUTOSAVING_OOS_DUMP" GUI 事件; OOS 报告窗唯一调用点 = MP 消息 thunk sub_140DE8340 (msg+40/+48/+80 转发); 槽[54] 内 assert 前置 gs 未初始化检查, [54]→[55] 链算术 (vt+440 = 槽[55]) 自洽。
- 未决: 主表槽[70] / 槽[16] 语义; gs+1312/1316 写者; byte_14332F6FA 置位者; InitData a2 语义; OOS dump 名「哈希」分量 (维持待裁); 全单元 ≈ 40+ 函数中无锚家族 (Idle/六节拍/暂停槽) 的簇归属。

#### 4.28.15 教程目标族 (CTutorialObjective 系; 非 trigger/effect, 会话级不入档)

基 = **CTutorialObjective** (抽象基, 无自身实测虚表, 88B 骨架; 工厂 0x1419CA5C0 按名串构造): +8 宿主教程管理器反指 / +16 textbox 键的串值 (7 字串逐字比对 "text"+"bo"+"x", 非 lexer token) / +48 loc 显示文本 / **+80 done 旗** (达成置 1 并广播 "tutorial_objective_done" 经 qword_14332F6A0 槽[31])。公共槽: [3] = 文本 Load 0x1419CA2D0 / [9] = **逐类判定函数** (唯一行为差异点)。

| 类 | vt | 工厂名 | [9] 判定 | loc 键 |
|---|---|---|---|---|
| CUseMilFac | 0x142A27BC8 | use_mil_fac | 0x1419D2CF0: 剩余可用军工 = (*(cc+3944 体 +888)/100000 − +944 − +920) == 0 → done | TUT_MIL_FAC |
| CUseCivFac | 0x142A27C28 | use_civ_fac | 0x1419D2780: 同构 (民用厂域量) | TUT_CIV_FAC |
| CUseNavDock | 0x142A27C88 | use_nav_dock | 0x1419D3260: 同构 (船坞域量) | TUT_NAV_DOCK |
| CIsQueueDiv | 0x142A27D48 | is_queue_div | 0x1419CE4A0: 建造/训练队列有 division → done | (无文本) |
| CIsResearchingTech | 0x142A27DA8 | is_researching_tech | 0x1419CE610: 遍历科技槽表 {d@+160, c@+172} (§4.7.6 ts+172 同容器 ✓) 全槽在研 → done | TUT_RESEARCH |
| CHasSetNatFocus | 0x142A27CE8 | has_set_nat_focus | (玩家已设国策 → done) | TUT_NAT_FOC |

> 兄弟类已见: CTutMoveCameraTo / CTutSelectAllDivsIn / CTutCommandGroup / CTutFrontline / CTutOffensiveOrder / CTutAirbase 等 (0x58/0x60 两档, 同工厂)。注意与 §4.32 `is_researching_technology` (CIsResearchingTechnologyTrigger) **只是名字相近的不同类** (那个是真 trigger)。
>
> **家族槽数契约 (定案)**: 主虚表**恰好 11 槽 (0..10)** — vt+88 处的字是**下一类 vtable 的 COL 指针**, 非第 12 槽。公共槽 [1] = CPersistent Save wrapper 0x1424BEC50 / [2] = CFG 空桩 writer / [3] = 文本 Load 0x1419CA2D0 / [4] = 基 reader 0x1424BEC40 / [5] 0x14011D220 / [6][7][8] = CFG 桩 / [9] = 逐类完成判定 / [10] = 逐类参数解析。
>
> **11 类补全表** (sizeof 由工厂内联 malloc 与 ctor 最大写偏移双证):

| 类 | vt | ctor | sizeof | 判定 [9] | 解析 [10] |
|---|---|---|---|---|---|
| CTutAirwingsAssigned | 0x142A28048 | 0x1419C6B20 | 96 | 0x1419CEE10 | 0x1419C9270 |
| CTutAirwingsMissions | 0x142A280A8 | 0x1419C6B70 | 96 | 0x1419CF690 | 0x1419C9270 |
| CTutAnnex | 0x142A28348 | 0x1419C6BC0 | 120 | 0x1419CFEB0 | 0x1419C9290 |
| CTutBattleplanExecuted | 0x142A28228 | 0x1419C6D10 | 88 | 0x1419D0020 | 0x1419C92E0 |
| CTutCommandGroupSelected | 0x142A28168 | 0x1419C6E50 | 96 | 0x1419D07D0 | 0x1419C92F0 |
| CTutCommander | 0x142A281C8 | 0x1419C6EA0 | 96 | 0x1419D0860 | 0x1419C95B0 |
| CTutDefaultMapmode | 0x142A28108 | 0x1419C6EF0 | 88 | 0x1419D0900 | 0x1419C92E0 |
| CTutSurrender | 0x142A282E8 | 0x1419C7030 | 120 | 0x1419D13E0 | 0x1419C9290 |
| CTutTroopsInPort | 0x142A283A8 | 0x1419C7090 | 96 | 0x1419D1620 | 0x1419CA0D0 |
| CTutTroopsInTransit | 0x142A28408 | 0x1419C70E0 | 96 | 0x1419D1D90 | 0x1419CA110 |
| CTutUnpaused | 0x142A28288 | 0x1419C7130 | 88 | 0x1419D2350 | 0x1419C92E0 |

> sizeof 证据 (定案): 工厂 (内联于章节 reader 0x1419CA5C0) 逐类 malloc 后立即调 ctor — 0x60(96) → AirwingsAssigned / AirwingsMissions / CommandGroupSelected / Commander / TroopsInPort / TroopsInTransit; 0x58(88) → DefaultMapmode / BattleplanExecuted / Unpaused; 0x78(120) → Surrender / Annex。
> 判定语义抽样: **CTutUnpaused** [9] 调管理器 `qword_14332F6A0` vt+744 取「是否暂停」, 未暂停且 +80==0 → 置 +80 并广播字面串 `tutorial_objective_done`; **CTutAnnex** [9] 走 gamestate 断言链 (`qword_14332F260`, gamestate.h:1125/1126 — 与 §4.32 同锚, 二次互证 gs 单例地址) 后按事件参数取值; **CTutTroopsInPort** [9] 多容器遍历型 (语义按类名, 推定)。
> 另 6 类 (CTutMoveCameraTo 0x142A27E08 / CTutSelectAllDivsIn 0x142A27E68 / CTutCommandGroup 0x142A27EC8 / CTutFrontline 0x142A27F28 / CTutOffensiveOrder 0x142A27F88 / CTutAirbase 0x142A27FE8) **无独立 ctor 符号** (创建内联于 0x1419CA5C0), sizeof 待裁; 其 [9]/[10] 依次 = 0x1419D0A90/0x1419C9B30、0x1419D0C30/0x1419C9270、0x1419D0400/0x1419C9270、0x1419D0950/0x1419C9870、0x1419D0AF0/0x1419C9DF0、0x1419CEB50/0x1419C8FB0。

教程族补全 (宿主与装载): 定义宿主 = **CInGameIdler** (ingameidler.cpp): loader 0x140DD7D20 读 tutorial/tutorial.txt, token tutorial (11768) → **CTutorialChapter** (4160B; writer 空桩, reader 0x1419CA5C0) 进 idler+2400 向量, token hint (10274) → **CTutorialHint** (2768B; reader 0x1419CBB00; +2648 提示窗名 / +2688 CHintOpener 向量) 进 +2424 向量; **CTutorialMinimized** (非 CPersistent, 内嵌 idler+2448, Reload 0x1419CCB10 重建句柄, 窗口名 "tutorial_minimized")。CTutorialChapter: +3960 = objective 指针向量 / +4056 末章旗 / +4104 CHintOpener 向量 (键 highlight_provinces/regions/states/open_hint)。CTutorialObjective 主虚表 11 槽: [9] = 完成判定 (单参轮询 / 双参事件处理两型) / [10] = 定义参数解析 (state=int / target=TAG 串 / 无参三组); CTutMoveCameraTo 判定 0x1419D0A90 = 查管理器+124 bool → 防重置 +80 → 发 GUI 事件 "tutorial_objective_done" 字面值 (qword_14332F6A0 槽[31] 广播链 ✓)。全族 17 个 CTut* + 2 库件 writer 全空桩 = 教程纯 UI 引导、零存档面。

**CTutorialChapter 字段补全** (§4.18.17/§4.24 定案旁证; 基址 = chapter):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +3912 | uint32 | 目标国 tag (tutorial_step 脚本事件的 tag 实参) |
| +3920 | SSO 32B | .gui 窗口名 (键 11769 window) |
| +3952 | 窗口对象* | **章节提示窗** (懒创建; +165 bit3(0x8) = 窗打开态) — ⚠ 与 CCountry+3952 (CDeploymentStatus, §4.18.10) 同号异类勿混 |
| +3960 | 对象* 向量 | objective 指针向量 (元素 +80 = done 旗) |
| +3984 | 匿名结构 (NNB 形状) 向量 | reader case 写入三列表之一 (键名映射待裁) |
| +4008 | 匿名结构 (NNB 形状) 向量 | 同上第二列表 |
| +4032 | 匿名结构 (NNB 形状) 向量 | 同上第三列表 |
| +4056 | uint8 | 末章旗 |
| +4057 | uint8 | **用户关闭旗** (置 1 = sub_140DD8720 教程激活时; 清 0 = 最小化条重开链 sub_140DE08C0; 置 1 后 Idle 不自动重开) |
| +4064 | SSO 32B | 章节文本模板 (键 143 text; 含 $STATE$/$THEATRE$/$DAYS_OF_PLANNING$/$PLANNING_MAX$ 占位符) |
| +4096 | int32 | state 键 tag (−1 = 无国语境; ≥1 经 gs+712 数组 [计数 gs+724] 解国) |
| +4104 | CHintOpener* 向量 (1384B 元, ctor sub_1419C6970) | open_hint 逐条 push; 元素 +1328 按钮名 SSO / +1360/+1368 缓存命中元件与宿主窗; 绑定失败报 "Cannot find button named: %s On hint window named: %s" (tutorial.cpp:988) |
| +4128 | int32 | direction_pointer 键 tag (10220; >−1 才驱动指针) |
| +4136 | 匿名结构 (NNB 形状) 向量 64B | show_in_window 表 (13764; 串 → 窗型库查名须 containerWindowType 612; 13765 show_objects_in_window / 18986 show_object_if_visible 依序追加) |

**章节提示窗创建/打开链 sub_1419CD070** (三调用点: Idle 每帧教程段 [门 = gs+2615 教程激活旗 ∧ gs+2608 当前章节序 ∈ 界 ∧ 窗未开 ∧ +4057 = 0] / 最小化条重开链 sub_1419CA160→sub_140DE08C0 / 销窗重建 sub_1419CC710): ①懒建窗 (工厂 = idler+1272 宿主 vt[12], 窗名 = +3920); ②正文 = +4064 模板按变量表格式化 (tag −1 支 2 变量 / ≥1 支前插 STATE=国名 sub_1409D91D0 + THEATRE=战区名) → FindChild "text_1" (父槽[15]) 写入; ③逐 CHintOpener 绑定按钮; ④三按钮 minimize (chapter+48) / **countinue** (+1336, 引擎原样拼错) / exit_to_menu (+2624) 绑 chapter 数据; ⑤尾段 show_in_window 表驱动高亮 (视图名直比 "countryconstructionview" 额外写构造进度) + direction_pointer > −1 时经 idler vt[34] 懒建指针 → 摄像机/指针矩阵对准目标国。姊妹拍 sub_1419D23B0 = objective 逐个 vt[9] 求值, 全达成广播 "tutorial_step" (+last_step) / 未达成 "tutorial_step" (0) + 指针熄灭。

**define 共享辨析**: DAYS_OF_PLANNING / PLANNING_MAX 在本链只是教程文本变量 — `100000×PLANNING_MAX/PLANNING_GAIN` (qword_143332648/qword_143332448, 原版 0.3/0.02 → 15 天展示值); 与 §4.18.17 真实计划链共享同对 define 全局但**零控制流交集**, 勿据串锚误判本族为作战计划机制 (原流程审计「作战计划」定域说废)。

**gs 新锚**: +2608 u32 = 当前教程章节序 / +2615 u8 = 教程激活旗 (⚠ idler 侧同号 +2608 = idler 字段, 异类勿混)。

**CTriggeredText** (条件触发文本, 128B; vt 0x142999B98; writer=CFG 不入档; reader 0x141180E60): +8 文本键 (143 text / 220 key) / +40 CAndTrigger 内嵌 88B (10595)。

#### 4.28.16 CSession (clausewitz 会话对象; 时序通道与状态机)

CSession = clausewitzlib session.cpp 会话对象 (单机实例 = CDummyServer 挂 CServer
基 0x142B52AC8, 派生 0x142B52C28; 联机 CNetworkServer 0x142B53020 / CProxyServer
0x142B53598)。实例获取通道 = idler 虚表槽[17] 读对象+896 (§4.2.1)。命令管线
(发送 sub_142250B00 / 派发循环 sub_142252D00) 与 CHourlyTickCommand::Execute 的
状态门行为契约归 §4.2.3; 本节收布局与状态域。

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +72 | uint32 | **联机状态机** (SetState session.cpp:269; 读者 sub_140CE9520) | 定案 |
| +76 | uint32 | 会话类别 (Init sub_142250890 直写 type 枚举; 三型表 §4.36.1) | 定案 |
| +80 | uint32 | 网络角色枚举 (Init a4 直写; 执行期广播门 {2,4,5}; SESSION_TYPE(17) 消息下发; **迁移契约 = SetNetworkRole sub_14224FBD0: 现值 2 → {4,5} 才写 / 5 → 4 才写 / 其余断言 "Unhandled Type Switch!" :936; 调用点 = 槽[7] server Cast 门置 4 + 前端开局链置 5; bootstrap 第 3 参 666 落此 = 永不入广播门占位; 值名 2=客户端/4=联机局内/5=主机准备段 仍属推定, 全枚举未决**) | 定案 |
| +84 | uint8 | **时间生成权旗 (本地权威门)**: Init 唯一写点 `= (type−1)<=1` (type∈{1,2} 主机/单机为真, proxy 客户端恒 0); 读者 = tick 生成门 (§4.2.2 步骤 5) / 调速命令发送侧 sub_140DD6930 / 掉队遍历。⚠ 旧记「server+84 允许位」无独立字段——系 server+80 QWORD 反指高 4 字节 | 定案 |
| +88 | CServer* | server 对象挂载点 (工厂三型分配; server+80 反指回 session) | 定案 |
| +96 | uint8 | **继承者旗** (收 NAMED_SUCCESSOR(7) 且值==本地 tag 置 1; 重连机主机重建路门; Init 清 0) | 定案 |
| +128 | uint32 | **命令流批号 (lockstep 计数器, 非游戏小时)** — 发送侧 `min(session+128, 0x7FFF)` 盖命令 cmd+22; 主机每批自增 + SERVER_TICK(5) 脉冲广播, 客户端锁步 ++/硬追 (§4.36.3) | 定案 |
| +164 | uint32 | 本机 machine id — 发送侧写命令 cmd+12 ("Machine id %d assigned") | 定案 |
| +400 | uint64 | GAME_STATE(18) 载荷流指针 (热加入/重连收到的 gamestate+命令日志流, 空 = 无; RequestSynch 反序列化消费) | 定案 |
| +1056 | uint8 | 重连机总门 (==0 只广播无动作; **全语料无置 1 写者**——Init 与 sub_142252660 均清 0, 负发现) | 定案写读点/语义待裁 |
| +1852 | uint8 | 命令派发重入门 ("Update within execution. Skipping." session.cpp:600/629) | 定案 |
| +1854 | uint8 | 热加入当前态旗 (与 +1855 同地址 WORD 写 257 双置 1; 独立 setter = SetHotjoin sub_142252520) | 定案 |
| +1855 | uint8 | 粘滞「曾开热加入」旗 (SetHotjoin a2 真时置 1) | 定案 |
| +1856 | uint8 | 热加入拒绝码 (0=declined/1=busy/2=nameconflict/3=disabled; 仅客户端写) | 定案 |
| +1940 | uint8 | 热加入等待旗 (态 13 置 1 / 拒绝置 0) | 定案 |
| +1941 | uint8 | 入队即时/本地门之一 (sub_142250B00 四条件) | 定案 |
| +1968 | uint8 | 派发循环状态辅助旗 (置 0 触发观察者广播 3; 另一写者 = "Server lost!" 断线链与玩家加入处理器) | 定案 |
| +1969 | uint8 | 派发循环分支判定旗 | 定案 |

状态枚举全表 (session.cpp:269 SetState switch; 定案):

| 值 | 状态名 | 值 | 状态名 | 值 | 状态名 |
|---|---|---|---|---|---|
| 0 | DISCONNECTED | 7 | REFUSED | 14 | HOTJOIN_IN_LOBBY |
| 1 | CONNECTING | 8 | KICKED | 15 | HOTJOIN_REFUSED |
| 2 | RECONNECTING | 9 | IS_BANNED | 16 | BAD_VERSION |
| 3 | RECONNECTING_FAILED | 10 | STATE_NAME_TAKEN | 17 | BAD_PASSWORD |
| 4 | CONNECTED | 11 | STATE_NAME_INVALID | 18 | STATE_JOIN_DISABLED |
| 5 | WAITING_FOR_GAMESTATE | 12 | HOTJOIN_ASKING_FOR_JOIN | | |
| 6 | ASYNCHRONOUSLY_CONNECTED | 13 | HOTJOIN_WAITING_FOR_SAVE | | |

> 备注: 13 = HOTJOIN_WAITING_FOR_SAVE — CHourlyTickCommand::Execute 的 `≠13` 门 =
> 「热加入等待存档的客户端不推进时间」; 单机热加入 toggle (sub_1418AD500) 在
> 12↔13 间翻转。单机正常态 = 4 (CONNECTED)。

#### 4.28.17 读档装载链与 PostLoad 次序

**核心结论 (定案)**: 不存在「载入完成后集中批量调用 PostLoad」的全局排序 pass。
PostLoad = CPersistent 主虚表槽 [8] (§4.00.1), 由共享 Load wrapper sub_1424BE690
在**每个对象自己的块读完时**立即调用 — 全局次序 = 存档文档深度优先序
(先子后父、同层按落盘键序)。跨对象修复分三波收尾: ① 根块尾
CGameState::PostLoad; ② 驱动尾 humans 同步; ③ 装载 lambda 第 9 步读后全局重挂波。

主链步骤表:

| 步 | 函数 (VA) | 语义 | 置信 |
|---|---|---|---|
| 1 | sub_141DEA910 | FE 帧装载器 (读档屏推进, 5 步进度) | 定案 |
| 2 | sub_140DA04F0 | 读档分派壳: idler vt+888 OnSaveGameLoadBegin → 取 session → 按存档头选驱动 → 成功后 idler vt+896 OnSaveGameLoaded → MP lobby humans 就绪循环 | 定案 |
| 3 | sub_140D9FF80 | 文本档驱动 (save-info+680==0 分支): 头读取 sub_140D9BEA0 → 流构造 sub_1422CD430 → gs+16 元数据写 sub_1401C4B00 → 主装载 sub_1401E2AC0 → humans 修补 sub_1401EE700 → 校验和 sub_1424EE1E0(0xFFFFFFFF) | 定案 |
| 3' | sub_140D9F9C0 | 二进制档驱动 (save-info+680≠0 分支): 流构造走 sub_1424DF2C0/sub_142231850, 校验和经流 vt+136; 其余同构 (gamelobby.cpp:2367) | 定案 |
| 4 | sub_1401E2AC0 | CCurrentGameState::Load: 日志 "CCurrentGameState::Load_START" (gamestate.cpp:1611) → gs+2613 (构建期门) 置 1 → gs+2612 (HasGameStarted) 置 1 → dword_14332F284 = 0 → gs+2600 = 默认书签 sub_1401DBBB0() → tbb parallel_invoke { CSessionUpdateThreaded, CGameStateLoadThreaded } → "Load_END" (gamestate.cpp:1640, 尾清 gs+2613) | 定案 |
| 5 | sub_1401C8A60 | CGameStateLoadThreaded lambda 体 (根装载编排器, 十步进度 62/N/10, gamestate.cpp:1587): ① appmgr vt+200 → sub_140F41B30(x,1) ② sub_1401EA1B0(gs) 世界重置/预清场 (自带 13 步进度: 州重建/settings 载入等) ③ sub_1401E13E0(gs,1) 重建 gs+1680 容器 (264B 对象 sub_140C48180) ④ sub_140A3CF40/sub_140A3D210 ⑤ sub_140CF31E0/sub_140CF33A0/sub_140CF2E40(1) ⑥ [appmgr vt+720 && humans>0] sub_1401EE7F0(gs,humans) ⑦ sub_1406212F0(rng,stream) 读档随机流播种 ⑧ sub_142232930(stream,gs,回调 sub_1401F1430) 根读入 ⑨ sub_1401DA490(gs) 读后全局重挂波 ⑩ dword_14332F284=1 (装载完成事件旗) | 定案 |
| 6 | sub_142232930 | 读引擎: 流 vt+80 复位 → magic/codec 判定 (0x6E6962="bin" 二进制等三形态) → 构造 parser (栈 336B) → sub_1424C0AA0(parser, gs) | 定案 |
| 7 | sub_1424C0AA0 | `return obj->vt[3](obj, parser)` — 根对象与一切嵌套对象进共享 wrapper 的统一入口 thunk | 定案 |
| 8 | sub_1424BE690 | 共享 CPersistent Load wrapper (PostLoad 唯一派发点; 调用序见 §4.00.1) | 定案 |
| 9 | sub_1401E0520 | CGameState::PostLoad (根块尾触发, gamestate.cpp:4352): ① 遍历 gs+784 国家数组 (count gs+796): sub_1406FE1C0(cc) = sub_140FFE6D0(cc+4048 占领状态, 1) ② 遍历 gs+1800 装备变体数组 (count gs+1812): sub_140BE2450(variant) (MIO trait bonus 重建, 尾挂 NIndustrialOrganisation::CTraitBonus); 调用者 = 语料零直调, 疑 CCurrentGameState vtable 槽目标 (待裁) | 定案 |
| 10 | sub_1401EE700 | 驱动尾: gs+248 humans 数组 (160B 元素) 与 gs+16 元数据对象的同步修补 | 定案 |
| 11 | sub_1401DA490 | 读后全局重挂波 (lambda 步 9): 逐国 sub_140BB5490(cc+4876) / 逐 gs+1776 表 sub_140BA49D0(+24) / gs+1704 → sub_1406B96A0 / 逐国 sub_140704D20+sub_1406EAB50 / gs+1688 → sub_140EAB300+sub_140EA3C20 / gs+984 → sub_140ECA270 / gs+1000 → sub_1401C67B0 / gs+1008 → sub_140E85FA0 / sub_140ED5A20 (逐国经 sub_140BB4390+sub_1406CFCB0) / sub_140E139B0+sub_140F3AC50 / 尾 sub_140F218A0(gs+1672) | 定案 |
| 12 | idler vt+896 | OnSaveGameLoaded 派发 (CFrontEndIdler 槽[112]=0xB3D6C0), 后接槽[58] 相机定位 | 定案 |
| 13 | sub_1401F0FD0 / sub_1401F0E10 | humans "selected" 玩家选择回填 (gamestate.cpp:7258/7288 "Human '%s' has selected %s") | 定案 |
| 14 | 装载器尾 | 校验和对比 + sub_1401DB330(gs)=gs+1832 getter → 三条命令发送 (sub_140DE6160/sub_140DE61B0/sub_14163C190) + sub_1417B32C0 + sub_140B6CCD0 (GUI 终步) | 高置信 |

字段与判别位:

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| gs+2612 | u8 | **HasGameStarted** (getter sub_1401E2930; sub_1401E2AC0 开头置 1) | 定案 |
| gs+2613 | u8 | **世界构建进行中门** (sub_1401E2AC0 开头置 1 / 尾清 0; 多系统读者以 `!+2613` 作跳过门) | 定案 |
| (全局) dword_14332F284 | u32 | 装载互斥旗 (0=构建运行中 / 1=完成·空闲; sub_1401E2AC0 头置 0, sub_1401C8A60 尾与存档路径尾置 1) | 定案 |
| 存档 save-info+680 | u8 | 文本/二进制档判别位 (≠0 → 二进制驱动) | 定案 |
| CGameLobby+1200 | u32 | 校验和存槽 | 定案 |
| CGameLobby+1204 | u32 | 模式状态机 (0=大厅/新局待启, 1=MP gamesetup 文件传输, 2=重开中; §4.28.18) | 定案 |

静态资源 DB 族 (TGameItemDatabase 模板族) 对照 — 与存档读档**无关**:

| 项 | 值 | 语义 | 置信 |
|---|---|---|---|
| DB 族 PostLoad 槽 | 基类主虚表槽 [2] (+16) | 全部内容文件读完后连调 vt[2]/vt[3]/vt[4]; COnActionDataBase [2]=sub_140A774B0 (缓存通用 on_daily/on_weekly/on_monthly 于 +144/+152/+160) / [1]=sub_140A75FE0 (clear) / [3][4]=CFG | 定案 |
| 驱动器 | sub_1401A0000 | LoadFiles (gameitemdatabase.h:281-331): 枚举目录 → 逐目录 sub_140A79930 → 逐文件 parser → 尾 vt[2]+vt[3]+vt[4] 三连虚调 | 定案 |
| 触发时机 | boot (InitGame sub_1401835A0) + 文件 watcher 热重载 | gameapplication.cpp:1597 日志串定位 | 定案 |
| 事件域双通道 | CEventManager 非 CPersistent (无槽[8]) | boot 载入 (sub_140A0C190 并行, a4=0) 事件直接 append 进消费数组 mgr+0(国)/mgr+24(州); watcher 重载 (a4=1) 走 +160 桶 + mgr+48 staging — 无集中归并点 (sub_140A0E770) | 定案 |
| CEvent 逐事件 | sub_140A0E770 LABEL_85 | 每事件经 `ev->vt[3](ev, parser)` 同一共享 wrapper 读入, CEvent 自身槽[8] 逐事件触发 | 定案 |

> per-class PostLoad 实装类全表 (178 类: 类/主虚表/槽[8] VA/预载钩/后验钩)
> = `ref/postload_classes_1193.txt`; 代表性语义样例: CState 0x1409DADD0
> (州→省链重建 + ledger 默认补) / CProvince 0x140E7E190 (ledger 默认补) /
> CCharacter 0x140FA43C0 (随机流恢复 + 显示名重建 + 单位/角色重挂) /
> CAirWing 0x140F62BC0 (随机流恢复 + 翼名惰性初始化 + ace 补链, 缺 ace 报
> "Airwing %s has Ace that does not exist.") / CAce 0x14061AD90 (CRandom 流恢复)。

#### 4.28.18 新局生成链 (CGameLobby / 两路世界构建 / HistoryDatabase / 就绪旗)

> 本节收口「开局生成全链」: 入口三通道 → 命令级联 → 世界构建两路分流 → 实体批产
> → 首帧可玩。宿主 = idler+1568 **CGameLobby** (ctor sub_140D975E0 依次装
> CSessionInfoObserver::vftable (+0) / CLargefileHandlerInterface::vftable (+8) 后
> 统一覆写为 CGameLobby::vftable — 双基同表; 源域 gamelobby.cpp)。读档装载链
> 细节见 §4.28.17; 存读档双轨并行见 §3.11.4。

**CGameLobby 字段表** (增量; FE 侧宿主行见 §4.28.14):

| 偏移 | 类型 | 语义 | 置信 |
|---|---|---|---|
| +88 | 串向量 data | 热加入待加入玩家名单 {data@+88, count@+100} | 高置信 |
| +100 | uint32 | 名单计数 | 高置信 |
| +168 | SSO 串 | 存档名槽 A (sub_140D9D4F0 构造) | 高置信 |
| +200 | SSO 串 | 存档名槽 B (sub_140D9BEA0 拼接目标) | 高置信 |
| +1152 | uint64 | 重开/转移请求 (非零 → 交棒: sub_140D99A90 自退 + sub_140D9F630 置 +1204=2 + 转 sub_140DA3A40) | 定案 |
| +1160 | double | 上次 checksync 墙钟 (10s 节流) | 定案 |
| +1176 | CSession* | 会话 (+84 门与 §4.28.16 互证) | 高置信 |
| +1184 | 指针 | 墙钟 getter (sub_14224DBD0 实参) | 高置信 |
| +1192 | 指针 | 服务器/大厅句柄对象 (vt+96 可派发谓词 / +112 人类列表 / +120 通知; 身份推定) | 推定 |
| +1200 | uint32 | 存档/传输句柄 (sub_1424EE1E0 等写入) | 高置信 |
| +1204 | uint32 | **模式状态机: 0=大厅/新局待启, 1=MP gamesetup 文件传输, 2=重开中** (写者全量 = sub_141CE2090=0 / sub_141CE1D10=0 / sub_140D9F630=2 / sub_140DA3A40 读+转移; 常量写点穷举无 3..N) | 定案 |
| +1212 | uint8 | 文件传输开始旗 | 定案 |
| +1213 | uint8 | 文件传输完成旗 (gamelobby.cpp:653 日志配对) | 定案 |
| +1214 | uint8 | 传输+复位完成旗 | 定案 |
| +1217 | uint8 | 读档局旗 (门控读档局自动写出对: 本地 sub_140DA25E0 / 云端 sub_140DA2E80, 选择器 = gs+101 u8; 调用门 = sub_140DA04F0 内 `+1217 && gs+192&1` — 勘误: 旧注「ironman 元数据恢复」失实, 两函数是存档写出器非恢复器) | 定案 |
| +1218 | uint8 | 离开旗 | 定案 |

> **Update 裁定**: sub_140DA3F20 (FE Idle sub_140B3CA20 每帧调) 是 **MP gamesetup
> 状态机** (checksync 10s 节流 → CCheckSyncCommand / 文件传输完成 → 命令派发循环 +
> 按 nNumOfHotjoins 分派 CPostHotJoin 或 CSetGameUniqueId + 主机读档序列 / 热加入
> 扫描), **不含**新局/读档世界构建分流 — 单机新局路径它近空转 (+1204 停 0)。
> **唯一分流点 = sub_140DA04F0** (FE vt[111] OnSaveGameLoadBegin → 88B 会话描述符
> v24 拷贝 sub_1402DDD00, tag@+88 分流旗@+85 → **v24[85]≠0 读档 sub_140D9FF80 /
> ==0 新局 sub_140D9F9C0** → vt[112] OnSaveGameLoaded 仅成功路径发射)。

**入口三通道与命令级联** (汇合点 = sub_141CD7100):

| 通道 | 链 |
|---|---|
| UI 新局 | setup Play (vt+440 → FE+1591=1) → sub_141CE2090 应用设置级联 (CSelectBookmarkCommand 首发 + CSetDifficulty + CSetCountryController + CSetGameUniqueId + CSetRandomSeed + 设置串持久化) |
| -start_tag | argv "start_tag=" → qword_143085070 (串对象对 xmmword_143085080; **串非空即 auto-start 旗**; 串空且 scenario_test 强制 "GER") → FE 菜单 sub_141CE5080 程序化点 Play → setup 选国 sub_141F49750 (tag→国 sub_14071BC80, qword_143330D98) → setup 帧循环 sub_141CD8CD0 auto → sub_141CD7100 |
| -start_save | argv → qword_143085090 (串对象对 xmmword_1430850A0) → sub_141CE5080 → sub_141CE2730 可续局检查 → sub_140DA3A40 + sub_140DA04F0 (读档分支) |

开始执行器 = **sub_141CD7100**: 玩家 tag 兜底 (gs+1316≤0 → 从国家/人类槽挑) →
**lobby+1204==0 (新局条件)** → sub_141CD9D80 命令级联 (可选 SetSeed →
CSetGameUniqueId (id = gs 侧 sub_1401DB330 生成) → CSetRandomSeed
(dword_143452524/520) → CSetGamePlayOptions (gs+1576 整块) → CStartGameCommand) —
全 session_post; UI 通道与 -start_tag 通道**汇合于此** (UI 的书签切换同样走
CSelectBookmarkCommand; -start_tag 路径书签保持默认, 世界已由 FE OnEnter 按当前
书签建好)。

**新局世界构建步序** (sub_1401A5630 "Resetting game", **主线程同步** — 命令 Execute /
FE OnEnter 时各可跑一次; zone 计时 sub_14222E270; 全序定案):

| 步 | 内容 | 证据 |
|---|---|---|
| 49.1 | 日志 "Resetting game" | gameapplication.cpp |
| 49.2 | gs 重建 = sub_1401EA1B0 (ctor sub_1401D0E30 清全部容器/管理器 + 默认初始化链: game_rules / 省 VP / 市场 / 突袭 / 阵营 / 学说 / 海军 / 角色 mgr ctor / 难度条目 sub_1401E0EE0) — **13 步内部分解见下表** | "Resetting gamestate. Total time:" |
| — | HistoryDatabase 销毁 (惰性单例 qword_143339CC0) | sub_140A3CF40 + sub_140A3D210 (49.3) |
| 49.4 | 重置 ID 分配器 sub_140175130; **角色批产 sub_1406B97D0 (gs+1704)** — 重置 ID 后、历史应用前 | "Reseting IDs. Time:" |
| — | start_date 落位: gs+1192 = 书签+376; SetCurrentDate (纪元 dword_143089AD8) | — |
| — | HistoryDatabase 装载 sub_140A3D640(histdb, 1) → **两段日期区间应用** sub_140A3D2A0 (第一段纪元→界; SetCurrentDate(start_date) 后第二段→start_date); 条目执行 = CHistoryEntry 族 vt[17] (§4.13.7: COwnerChange → SetOwner/SetController / CSetStateBuildings / CSetStateVictoryPoints / CHistoryAddEffectState → effect 重放) | history.cpp:165 |
| — | gs+2600 = 所选书签; 渐变边界生成 (sub_1406D9040 逐国 + sub_140B70B30); 49.5 sub_1401E2230 (语义未决); 49.6 情报知识刷新; 49.7 CGraphicalMap ResetGame (sub_140B58360); 49.8 stateDef 侧收尾 sub_140A64600 | — |

**sub_1401EA1B0 世界重置 13 步内部分解** (221 行薄编排层, 进度类 48; 行序 = 执行序
即契约序; 步号 (48,N,13) = zone 计数):

| 步 | 进度 | 动作 |
|---|---|---|
| 头 | — | sub_1401AAA50() gs 访问计数 ++ (Count ≤ 2 断言, gamestate.h:1140); 尾配对递减 = sub_140193F90 (Count ≥ 0, gamestate.h:1146) |
| 1 | (48,1) | sub_1401D0E30(gs) = gs ctor (清全部容器/管理器) |
| 2 | (48,2) | 逐州 sub_1409D6BF0 + sub_1409DED70 (清州) |
| 3 | (48,3) | sub_1401E0EE0(gs) = 难度条目 |
| 4 | (48,4) | malloc(56) + ctor sub_140A34D20 → **CGameRulesInstance** 挂 gs+1088 → sub_140A355F0 重灌选项表 (§4.25.4a) |
| 5 | (48,5) | **sub_1401E1580** = CWeatherManager (1424B) 重建 + init + 以 gs+1128 当前日期重置, 挂 gs+1672 |
| 6 | (48,6) | 逐州 **sub_1409DD000** = 州 CBuildingStatus (st+288) / 省 CBuildingStatus (prov+400) 实例清 + 从建筑库重建 |
| 7 | (48,7) | **sub_1401E0E30** = 逐国默认重置 (country.cpp:2409 trade influence 缓存断言族, 进度类 46) + 两全局单例重置 |
| 8 | (48,8) | malloc(640) + ctor sub_140E83B80 → 突袭管理器挂 gs+1008 → **sub_140E86420** 全量重建 176B/条目目标表 + 二遍筛 |
| 9 | (48,9) | malloc(232) + **sub_140D91410** = NFactions::CFactionSystem 挂 gs+1016 |
| 10 | (48,10) | malloc(32) + **sub_140D7C660** = NDoctrines::CDoctrineSystem 挂 gs+1024 (CPdxArray 逐国 push 160B 条目); init 波 = sub_140D7F1D0 (条目 → sub_1413CE1D0 清容器 + 按国数 ×1.5 扩容) |
| 11 | (48,11) | **sub_1401E0C60** = gs+2176 {data/cap@2184/count@2188} 逐国 malloc(40) 建 NCombatLog::CManager (元素 +32 = 国 tag; count 非 0 懒建跳过) |
| 12a | — | gs+1688 已存 → **sub_140EAB8B0** 复用重置 (逐国 navy 重置 sub_140EAB6A0 + 清 24B/条目观察表, 活计数 @mgr+48); 否则 malloc(64) + **sub_140E9D710** 新建 (ctor +60 f32 = 0.9 比例常数, 消费点待裁) → **sub_140EA8100** 逐国 malloc(464) 建 CStrategicNavy (sub_140E9D320 + init sub_140EA7C70) 入 mgr+8 数组 (进度类 50) |
| 12b | — | **sub_1401F0980** = 规则位 25 (sub_1401AEB50(25)) 为真 → 建 CStrategicOperativeManager (104B, ctor sub_140EB2D00) 挂 gs+1696; 为假 → 销毁置空 |
| 尾 | (48,12→13) | malloc(160) + ctor sub_1406B4B20 = **CCharacterManager** 挂 gs+1704 → sub_140193F90 计数 −− |

要点: ① 步 12a 二选一 = **读档路复用已加载管理器 / 开局路新建** (与「初灌 vs 读档
loader 分工」互证); ② 步 4/9/10/12a/尾 的 malloc 尺寸 (56/232/32/64/160) = 五管理器
对象大小首次精确化; ③ 所有槽挂载均走 pdx::scoped_ptr 裸指针形态。

**sub_1401D0E30 (gs ctor) 内部 17 步进度表** (进度类 47, 权 17 — 「清全部」的内部
展开, 与外层 13 步 (类 48) 编排层不同层不冲突; 读档路复用重置发生在 ctor 内部:
步 8/9 的 gs+1680/+1688 非空门即外层 12a「已存 → 复用」分支的实体):

| 步 | 动作 (定案件加粗) |
|---|---|
| 前 | gs+2408/2618/1168/1176/1328/1316 清; **gs+212 = 系统启用位图快照** (sub_1401AE6A0); gs+16 子对象重建 (sub_140BC0880 → sub_1401C4B00; **对偶 dtor sub_140BC0960**, 240B 临时件); gs+212/2216/2264/2272 清; **sub_1401EB060(gs+1376) pending_events 清** (56B/条目, +32 CGregorianDate 复位) |
| 1 | **sub_1401EAFB0(gs+1336) fired_event_names 哈希桶清** (桶数为运行时值非 511 常数); gs+1208/1364/2576/1624 区清; 补给 sys 重建 (sub_1401EC950, §4.21.1d) |
| 2–3 | sub_1401D6290(gs) |
| 3 后 | 逐国 [1, gs+796): **sub_1406E3DB0** (cc+656 数组/cc+632 列表成员重置, vt[44] 槽 — 语义待裁) → sub_1406E2DE0; major 断言 (gamestate.cpp:3129); gs+820 = 0 |
| 4 | 逐州 [1, gs+724) 非空 → sub_1409D7330 (州 CBuildingStatus@+288 + 辖省 CProvince+400 成对销毁包装 — §4.13「成对销毁」调用壳) |
| 5 | gs+2176 combat log manager 数组全释放清零 + sub_140CDAF60 (**SCombatDataPersistence 全局条目表清场**, 1096B/条) |
| 6 | 逐省 [1, gs+700): **sub_140E7A910** (CProvince 重置: +24/+208/+216/+368 数组/5 计数器/+400/+64/+56/+160) |
| 7 | 逐州 [1, gs+724): sub_1409D6BF0 (外层 13 步表步 2 同件) |
| 8 | gs+1680 非空 → **sub_140C4EF30 CStrategicAirManager 复用重置** (清计数 +24/+40、4 组指针数组 +48/+144/+168/+192、3 张 32B 元表 +72/+96/+120) — 海军 12a 的对称件 |
| 9 | gs+1688 非空 → **sub_140EAB8B0** 海军复用重置 (外层 12a 同件) |
| 10 | malloc(64) + ctor sub_140F03310 → gs+1712 (旧槽释放; 归属名待裁); sub_140BB7BB0(gs+608); sub_140CBF670(gs+600) |
| 11 | gs+1128 = dword_143086B38; gs+1144/1152/1160 清; **sub_140BBEA60(gs+1248) CPeaceConferenceManager 数组清**; **sub_140D91D90 阵营成员数组清 (fac+32)** |
| 12 | gs+928 数组 (c@940) 全释放 |
| 13 | gs+1424/1448/1472 三数组全释放; gs+1496 map 清 (std::map RB-tree) |
| 14 | 10 个 dword 全局统计槽清零 (dword_14333CA00/D590/D5CC/D5D4/D5F0/D5C0/C77C/D5DC/D5E0/D5E8) + sub_140710AB0/CEB3E0/CEB3F0/BE00D0 |
| 15 | gs+1568 = 0; sub_140CBF670(gs+600) 二遍 |
| 16 | gs+1728/1752 两张 112B 元表清; 进度系统 72 槽重置 (sub_142233720 = random 调用记录环清场); idler 别名 vt[+16] → **sub_140B52130 突袭 GFX 管理器懒建** (56B, ctor sub_14167D7F0; graphicalmap.cpp:3732 断言); gs+1864..1944 清; **sub_140BBD600(gs+1952) CIdCounterStore 重置 pass** (释放 +56 引用对象清 +44); **sub_1401D61F0(gs+1064) difficulty_setting 数组清**; gs+1088 game_rules 释放; gs+1800/1776/2440/2615/1824/1236 区清 |
| 17 | **sub_1401EC5C0 = game_unique_id 生成** (boost uuid v4 + BCryptRandom, 存 gs+1832 — 书有槽与读侧, 此为生成侧); **sub_1401D1D60 = unit-leader CID 注册表压空哨兵** (gs+1040 追加全局空 idpair qword_14333D528 — 与「idx0 = null 哨兵不写」定案互证); **sub_1401C3C50 = gs+2618 重置进行旗清零** (ctor 入口置 1 / 出口清 0); gs+2168/1320 清; 表外尾 sub_140BB2B90(gs+2536) 容器清 + gs+2492 = 0 |

书签应用包装 = sub_14067EEE0 (门 `gs+2600 != 目标书签` 才重建); FE OnEnter 进前端
时对当前书签先建一次 = **主菜单存在完整 gs 的根因** (§1.1b 互证)。
CStartGameCommand::Execute = sub_14163DA10: 玩家 tag 兜底 + lobby+148 bit2 +
FE 槽[80] SetLoadingComplete (FE+1590=1); 副产 sub_140DE2C00: gs+2216 = −1
(禁首轮自动存档)。两路汇合后 = FE 帧 StartNewGame sub_140B3E9A0 (门 FE+1591) →
构造 CInGameIdler (ctor sub_140DC1B30 内 **sub_140DD6A30 = CInGameIdler::InitData(bool)**
开局补算, 门 HasGameStarted) → SetIdler → 首帧。

**InitData 定案** (profiler 域串直证, ingameidler.cpp:4888→5119; 唯一调用点 = ctor
传 a2=0; 进度类 54/12 步, 为 ctor 类 53/19 步的第 8 步; 头部 = idler+1535 置位 +
random 调用记录环重置)。主分叉 = gs+2612 HasGameStarted:

| 路 | 序列 (定案件加粗) |
|---|---|
| 读档完成路 (≠0) | fired_events 哈希重建 (§4.12) → **sub_140EF9280 theatre/fronts 修复** ("Theaters or fronts has been fixed…") → 短版逐国四连 (**sub_140D46170 附属列表重建** token 12497 置脏 cc+298 / **sub_140705950 逐舰队位置重算** / **sub_140715370 贸易影响缓存重建** (cc+252 对表 +264 缓存旗) / **sub_140718B60 首都校验选都迁都** (country.cpp:7071)) → 逐州 **sub_140F9AE60+sub_140F9ADB0 CResistance 驻军/占领修复** (state+616, resistance.cpp:426/103) → 逐国 Decision.UpdateTargetedDecisions (调用点补) → **sub_1401EF500 "Starting ALL AI (In parallel)" tbb 并行 AI 全量启动** |
| 新局路 (=0) | gs+1192 ← 日期快照 → 战略海军并行 sub_140EAB300 / 战略空军建 sub_1401E13E0 / **补给+铁路 init 对 sub_1401E1540** → **sub_140EF9150 theatre 全局重置** (~12 全局清 + 6 子重置) → **sub_140DD7A60 阵营×附属关系网置脏** → 长版逐国 pass (名称组 tracker 清 sub_1406FF150 → OOB 装载 → **GenerateNonHistoricalAttributes sub_1406EB150** 随机理念/特质 → 政治 → 附属 → rs 控制州重算 sub_1406FF1E0 → **人力重算 sub_140CFE420** (cc+808, 修正键 73/74, 定点式待 PE 验算) → 舰队 init **sub_1406FEF10** (country.cpp:8824 构建期门) → 战略空军缺失重建 sub_1406FE910 → **生产线 init sub_1406FEE10** (+160/+172/+256) → **landlocked_start 推导 sub_140716520** (cc+5619) → 舰队重算 → 贸易影响 → 首都) → 国家颜色刷新 → **Hourly → Weekly → Daily → Monthly 各一遍** (顺序 = dump 行序 L7065010-13 直证; 四调度期间 gs+1672+841 与 gs+984+384 置 1 后回 0; 旧「Hourly+Daily+Weekly+Monthly」字面序废) → 逐国 rs 资源池重算三连 (**sub_140CB51D0 extracted 池全量重算** +40/+48/+568 三槽 / calc_modifier / sub_14070C890) → tbb 并行逐国段 |
| 合流段 (进度 4–12) | sub_140BBAE50 (gs+608 容器清旗, 语义待裁) → idler vt[+560] → **sub_1401F18B0 三段全局一致性校验** (owner/controller 占领 gamestate.cpp:6845 / 州建筑超限 :6875 / 战时宗主附庸 :6900) → 读档路补 AI 启动 → 补给重建 (sub_140ECA270) + rs 租借条目重算 **sub_140705930** (+984 回写) → 铁路逐国 **sub_140B51FF0** (gs+992 +68 旗门) → !a2 玩家档案同步对 **sub_140DC5F30 (按名线性) + sub_140DC5D00 (按键二分)** (gs+248 ↔ gs+16 两张 160B 命名条目表; a2 语义推定「跳过玩家档案同步」, 待裁) → idler+2216 = 168/−1 (gs+192 bit0 门) → error.log 刷新 (idler+1328) |

InitData 伴随新识槽位: cc+252/264 (贸易影响缓存) / cc+298 (关系置脏) / cc+368/380/392
(附属列表) / cc+3944 内 +160/+172/+256 (生产线) / cc+5619 写者 / mp+16 / gs+1192/1824/608 /
idler+1535/2216/1328 / state+616 内 4 槽 / 管理器槽 +5979。

**history/ 装载两层次** (boot 静态 DB 与新局 HistoryDatabase):

| 层次 | 时机 | 内容 |
|---|---|---|
| boot 静态 DB | 主菜单前 (gameapplication sub_14018BB20) | stateDef "history/states" (sub_140A64AA0, 断言 "DB already loaded when loading"); tag 表 → CCountry 批建 sub_14071C5C0 (ctor sub_1406C9CC0); history/countries 逐国装载 sub_140A3DC80; history/units/<TAG>.txt OOB sub_140702F80 (先国家重置 sub_1406E8ED0) |
| 新局 HistoryDatabase | sub_1401A5630 内 (上表) | 装载 + 两段日期区间应用; **读档局只销毁不应用** (zone 62.3; 历史已物化进存档) |

> mod 覆盖: 两层装载枚举全经 PHYSFS VFS (§4.29.1), replace_path 目录级独占
> (§4.29.5) 在**枚举层**生效; 被独占时静默缺文件, 链上无额外告警点 (§4.29.7)。

**实体批产表** (生成者 × 时机):

| 实体 | 生成者 | 时机 |
|---|---|---|
| CCountry 本体 | boot tag 表装载 sub_14071C5C0 → ctor sub_1406C9CC0 | 进程启动 (先于任何会话) |
| 国家数组 gs+784 槽位 | gs ctor 逐国复位 (自 idx 1 起) | 每会话 ctor |
| 州归属/建筑/胜利点 | 历史条目 vt[17] (§4.13.7) | 两段日期区间应用 |
| 角色 (领导人/顾问/将领) | 批产 sub_1406B97D0 (来源 = common/characters 模板 DB, boot 期已载) | 重置 ID 后、历史应用前 |
| 单位 (师/翼/舰) | OOB history/units/<TAG>.txt (sub_140702F80) + CHistoryAddEffectState effect 重放 (重放全集未决) | HistoryDatabase 应用期 |
| 派生数据 (补给/组织/AI 初始态) | **开局补算** sub_140DD6A30 | StartNewGame 构造 idler 时 (首帧前) |

**初灌 vs 读档 loader 分工** (两路共用 gs ctor + 默认初始化 sub_1401EA1B0, 此后
一路独占填充):

| gs 项 | 新局 | 读档 |
|---|---|---|
| 州/省骨架 | ctor 分配 + 历史条目填 owner/building/VP | ctor 分配 + loader case 填全量 |
| 国家属性 (颜色等) | boot 模板解析值留存 (**模板字面量**) | loader 逐字段回读 (存档文本整数往返) |
| 角色 RH 反查表 #1/#3 | 仅新局批产填充 | 恒空 (§4.4.9) |
| gs+152 CGameDate#0 | **零写点** (ctor 哨兵 43808760 恒留) | loader 落 hours |
| gs+2600 | 写所选书签指针 | 重置默认书签 (sub_1401DBBB0) |
| id 计数器族 (gs+1872..1952 等) | ctor 零态 (个别历史 effect 抬升) | loader case 回读 |

> **颜色 f32 分歧根因** (新建档 = 模板字面量 / 读档 = k/255 往返): 两路写源不同 —
> 新局颜色自 boot 期 common/ 模板解析直存 (不经归一化); 读档经 writer 文本输出
> `(int)(v*255)` 截断 → loader 按整数还原 k/255。分歧是**写源拓扑**, 无公共归一化
> 步骤 (§4.24.10 CColor 截断定案闭合); gs+152 新局零写点 = 结构性必然。

**就绪旗族** (世界构建期到首帧可玩):

| 标志 | 语义 |
|---|---|
| gs+2613 | 世界构建进行中门 (sub_1401E2AC0 开头置 1 / 结尾清 0; 多系统读者以 `!+2613` 跳过) |
| gs+2612 | HasGameStarted (getter sub_1401E2930; sub_1401E2AC0 开头置 1) |
| dword_14332F284 | 装载互斥旗 (0 = 构建运行中, 1 = 完成/空闲) |
| FE+1590 / FE+1591 | SetLoadingComplete / RequestStart (§4.28.14 槽表) |
| 首帧可玩 | CInGameIdler ctor 开局补算 (sub_140DD6A30) + SetIdler 后首个 InGame Idle 帧 |

> 桥时序相容: `session_start` 事件触发于 gs ctor 写点 (构建早期, gs+2613=1);
> `in_game=true` = 首个游戏内帧, 严格晚于 sub_1401E2AC0 收尾与 InGameIdler 切换 —
> 「持久化状态恢复只许在 in_game=true 做」与引擎时序严格相容; 构建期窗口内的早期
> 读数会撞零态。
>
> 待裁收敛: 单机新局经新局分支 sub_140D9F9C0 **已按静态证据定案 = 是** — 该函数全语料
> 唯一调用点 = 分流点 sub_140DA04F0 (描述符 +85==0 即走它), 单机/联机同路, 无第二路径;
> 运行期探针 (新局启动产生新 .hoi4 + logs 顺序) 仍可作最终佐证。GUI 回调 sub_141F46870
> 携描述符直调 sub_140DA04F0, 与分流结构相容。

> **开局设置 UI 面 (frontendgamesetupview)**: 主视图 0x141CD2950 连装四窗 — CGameSetupScenarioWindow (真 ctor 0x141F40A20) / CGameSetupCountryDetailsWindow (0x141F3FB30) / CGameSetupMultiplayerSettingsWindow / CGameSetupGameplaySettingsWindow, 四窗全 glue 观察者壳 (零序列化, 零 gameplay 直读; 选项真值走命令通道 §4.28.18 已载链)。

#### 4.28.21 进程启动 bootstrap 链 (main → CGameApplication ctor → Init 14 步)

五段地图 (定案): ① **进程引导段** (main.cpp, WinMain 后): 图形硬件检查 (Shader Model 3.0
弹窗) → 日志 "Creating application..." (main.cpp:2136) → malloc(0x4F8) → **sub_140147EE0
= CGameApplication ctor**。② **构造段** (无 IO 纯注册): 基类 CApplication 单实例互斥 →
预建 **CSession("localhost", type=2, 666, 32)** (9 参重载 sub_14224E870; 666/32 参数语义
待裁) → **~28 对热重载注册** (门 = **byte_14332EC69 = `-debug`/`crash_data_log` 命令行门** — 关闭则只建对象不挂目录监听; 控制台 toggle 件 = sub_14024C670; 与 launcher 默认不带 -debug 的现役约定互证; 统一形态 new CDatabaseReloader<T>
→ 组名 → sub_1422564C0; 组名表: define / countrycolors / ideas / focus / cfocus / decision
(递归) / ability / scriptedgui / scripteddiplomaticaction / scriptedmapmodes / onaction /
scripted_triggers / scripted_effects / ai_strategy / ai_strategy_plans / ai_equipment /
ai_templates / occupation_modifiers / occupation_laws / **occupation_laws 组名被
common/resistance_activity 目录复用 (引擎怪癖)** / intelligence_agency_upgrades /
intelligence_agencies / bop / peace_conference (递归) / equipment_graphic_database /
assets / gfx (目录 = interface, CGFXReloader sub_140147E50) / train_gfx_database; 各落点
= CGameApplication +936..+1176 reloader 指针区) → 加载条组 65 start/end 回调注册
(sub_142257B00; 单例 qword_1434531C0, +56/+64 双槽) → main 填启动参数 (sub_1401A7B70 →
+1192 40B 结构) + 窗口图标。③ **Init 前置段** (vt[+72] 虚调后): **synchronized_dynamic_tokens
token 预装载 sub_140176F30** (common/synchronized_dynamic_tokens/*.txt 枚举 → token 预注册;
完成旗 byte_1435E1AB1 — **mod token id 空间的 boot 期填充点, 印证「离线 token 表 ≠ 运行时
lexer」**) → HotkeyManager 单例 → CSettings 触碰 → 语音无障碍族单例群 → qword_1433304E0
全局重建 (0x78, 语义待裁)。④ **Init 主体段** (= **CGameApplication::Init = sub_140180BC0**,
虚表槽[9]/+72, gameapplication.cpp:812-866 自报行号; 步序): 内存水位日志 (812) →
InitTextureLookup(gfx/models) (825) → InitBase sub_140181110 (832) → _pGraphics->Init3DTypes
sub_142238FD0 (840, "Long Task") → LoadAssets sub_140B39270 (849; ⚠ 名不符实 = 注册菜单 web_link 解析器回调, 非图形资产装载 — §4.35.6 勘误) → **InitGame
sub_1401835A0** (853; mod·DLC 与数据库装载宿主 = §4.29 领地, 本链只到调用点) 。⑤ **收尾段**:
好友处理器预接 + InitFriendsHandler (CGameApplication 具名 lambda) → loc key 冲突告警
(byte_1434530F0) → error.log 检查/弹出 (sub_1401758A0 ShowErrorLog, 大小门 dword_14332ED60,
CreateProcessA; 失败日志 gameapplication.cpp:922) → main 进 Run/主循环前置。

ctor 成员初始化要部: +864 = CGameGraphics* / +888 = 引擎单例槽 / +896 = CSession* (1976B) /
+904 = 日期定时器容器 (80B CGregorianDate 元; 0.85f 常数待 PE 验算) / **+912 = scopedptr 槽 →
NCareerProfile 生涯档案管理器堆目标 (约 2024B; 奖项 SCareerProfileAwards 内嵌@+288, 槽区
+296..+1952; getter sub_140161290 带 pdx_scopedptr.h:119 `_pPtr` 断言; 布局全形 = §4.28.22)** /
+920 = scoped singleton 槽 (CPersistedMioQueueDb) / **+936 = CDefinesReloader** / **+1184 = localisation watcher 看柄** /
+1192 = 启动参数 40B 结构 / +1232 = SSO 串。伴生定案: HotkeyManager 单例 qword_1434531A8 首启
于 Init 前置段; clausewitz clock.cpp 时钟启动; CSettings +952/+960 = hotkey 双 delay 默认 0.1 (§4.28.11 表)。
加载条 start 回调 = sub_140A59850 (按 phase 0..3 填步骤 id); end 回调 = sub_140A59E80
("Loading bar group: N is missing chunk M", loadprogressimpl.cpp:117)。

#### 4.28.21a CGameApplication 主表与热重载家族 (1.19.3 实测)

**主虚表 = 0x1427182E0 (19 槽, exe 直读; slot[8]=StartUp/slot[9]=Init/slot[12] 三槽与书互证锁定表基; **1.19.2 与 1.19.3 同址未迁移**, ref/vt_rtti.json 键 0x1427182e0 → "CGameApplication" 双侧独立证据)。⚠ 0x1427168E0 处 = 字符串数据 ("…s gamestate" 断言串尾 + SteamUtils009 等), 非虚表, 勿作表基。槽表:

| 槽 | 语义 |
|---|---|
| [0] | sub_14015FB30 标量删除析构 (thunk → 完整析构 sub_140151EC0, 体内重装 CGameApplication vftable 直证) |
| [3]/[4] | Load wrapper 0x1424BE690 (CPersistent 共享) / reader sub_14222E600 (token==27 读应用名至 +72; 应用族只载不存) |
| [5] | **ret0 桩 sub_14011D220** (定案) |
| [8] | **StartUp** sub_14222DCB0 (单例写 qword_143452450 + FindWindowExA 互斥, application.cpp:1006 断言) — ⚠ **游戏进程内为死虚槽**: 实际单例写入与互斥由 **CApplication 基类 ctor sub_14222B420 的内联 StartUp 副本**完成 (`&CApplication::vftable'` 符号直证); 书 §4.2.1「StartUp 槽[10]」系 **CMapApplication 表** (主进程实际应用类), 两表槽位不同非冲突 |
| [9] | Init sub_140180BC0 (+72) |
| [10] | **CFG 空桩 0x14012A2C0** — Run 的 vt+80 调用 (参 = 选核结果) 在游戏表落空 = 无操作 (定案) |
| [11] | **Shutdown flush sub_140195110** (定案, 原「语义推定」升档; 唯一调用点 = Run 退栈 vt+88; 全序见 §4.28.23) |
| [12] | **加载屏节流刷新** sub_140195420 (5 参: progress/total/mode/force; 50ms 节流 qword_14332ED40 double 秒戳; a2≥a3 完成态强刷; 尾断言 gameapplication.cpp:2091 主线程 + CSdlEvents 单例 qword_143453168 vt[+16] = SDL 事件泵 — 加载期次级消息泵) |
| [13] | 清节流戳 (qword_14332ED40 = 0) |
| [14] | **cheatcode_used 遥测上报 sub_140194FE0** (定案: 事件名 "cheatcode_used", 属性 "command" = 命令串; 虚表挂槽 = 控制作弊执行路径经 app→ReportCheatUsed 调用, 文本内无直调点) |
| [15] | 最小帧时长 getter = 1/60 s (0.016666668f) |
| [16] | checksum 有效旗 getter (读 +929) |
| [17]/[18] | GetSession/SetSession (+896; Set 旧 session 先 vt[0](old,1) 删除再写) |

新偏移 (CGameApplication 本体): **+872 = 加载屏对象** (0xCC8, ctor sub_140B429A0; InitLoadScreen sub_140184B30 建并装 load_screen.gui — 三 .gfx 存在性检查缺一告警 :1075; InitBase reinit=0 时与 +864 CGameGraphics 一起销毁重建; **reinit=1 分支语料全文本 0 调用点 = 负定案高置信**, 唯一调用 = Init 传 0) / **+929 u8 = checksum 与出厂期望一致旗** (CreateChecksum 步 sub_14016F1C0: **+348 = 已算旗**; sub_14222BDE0 首调时把 checksum_manifest.txt 计算写入 **+352 = 版本指纹串 32 hex 位** (定案 — :1503 "Version: " 日志直证, InitMap 的 manifest 校验同读此串), +352 比对硬编码 "92f2d45a861ba7599f5b05e849e05632" → 写旗 + checksum 结果单例 qword_143330460 (0xA8B) +162) / +880 CGraphicalMap\* 懒建门 (InitMap sub_140185170, 调用者 = frontend.cpp 图形初始化链 sub_140B3D9B0, 不在 Init 直调链) / **CGameGraphics 尺寸 = 0x32A00 (定案**, InitBase reinit=0 malloc)。**ShowErrorLog sub_1401758A0 门 = error.log 增量判定** (非绝对尺寸: dword_14332ED60 = 上次已弹尺寸, 增长才弹并更新); 调用点 = Init 尾段且整段在 byte_14332EC69 (-debug) 门内。**LoadAssets 热重载 = sub_14222DDC0(app, mode 0/1, flush=1, path) 双遍通道** (watcher 回调 sub_14222E6A0/E620 对每路径跑 mode=0 + mode=1 两遍)。**TGameItemDatabase 通用 DB 装载包装 sub_14018B0E0** (+20 已载旗 / +16 名字 / vt[+48] 逐文件解析槽; 单例守卫断言 gameitemdatabase.h:127/142/**149**/179 — :149 "_pInstance && \"Instance not created.\"" 为补列)。**InitBase sub_140181110 全形 (新定形, reinit 形参)**: 17 步 = 基类 CApplication::InitBase → 30 项硬编码光标表 (sub_14222BDC0 vt[+80]) → 销毁重建 +872 加载屏/+864 CGameGraphics (先 872 后 864) → InitLoadScreen → **+856 = 渲染器句柄槽 (双重解引, 四连初始化)** + 主菜单音乐 maintheme → **byte_143085000 = 装载异步门** (LoadAssets 异步/同步形态 + .gfx 等待 + 第二 Long Task; LoadAssets 双函数名 = Init :849 处 sub_140B39270 vs InitBase :1438 处 sub_14222E1B0(app, mode 1 先行遍/0 后遍), 两处日志均 "LoadAssets takes") → LOADING_GUI → InitGUI → LOADING_MAP_SPRITES → .gfx 逐文件装载 (进度组 7) → AddMapShaderDefines → **CGraphicalCultureTypeDataBase** (common/graphicalculturetype.txt, malloc 336+104)。**主虚表槽[12] sub_140195420 节流判式 (定案)**: force ∥ 完成态 ∥ 50ms 戳差 (double 秒戳 qword_14332ED40) → 走 CGameGraphics(+864) 两分支 (mode 1 具名串/0 刷新); 尾断言 = "ThreadIsMainThread()" (gameapplication.cpp:2091); 兜底 = CSdlEvents vt[+16] 次级消息泵。**ShowErrorLog 第二道门 byte_14332ED48 = suppress_error_log 设置键旗** (assertsdialog=no 同路置位; 邻键 debug_smooth/render_thread)。**gs 访问前置断言对 (原文)**: gamestate.h:1116 `_pInstance && "gamestate unitilialized"` (引擎 typo) / :1117 `_ThreadForbidCount == 0 && "Current thread is forbidden to access gamestate"`; gs 单例 = qword_14332F260。⚠ `xmmword_1427179A0` = MSVC 空 std::string 常量 {0,15} 非真串 (语料百处级, 防误读)。

**InitGame (sub_1401835A0) 16 子步步序全图** (bar 组 40): LoadDatabases → LOAD_EVENTS → stateDef → achievements/event/onactions → INIT_GAMESTATE (gs 创建 ×3) → AI 省份查找表 ×2 → LOAD_FLAGS → 地图图标管理器 → **步 12: malloc 0x640 CFrontEndIdler ctor sub_140B3B290(idler, \*(+864) gfx, \*(+872) 加载屏, app) + SetIdler — 帧→tick 唯一衔接点** → 步 13 CREATING_CHKSUM (byte_143085000 时 "Long Task" 异步) → CButtonMenu/DumpMissing → **步 15 InitFileWatchers (门 = byte_14332EC69 即 -debug)** → 收尾。**本簇负定案: 不含帧循环/暂停位/速度档** — tick 通电仍按 §4.2.1 (CInGameIdler::OnEnter 填 qword_14332F6A0)。

热重载家族 (定案): watcher 注册原语 sub_14224D3B0 (目录, 递归, callback, ctx), 五目录 = common/defines (回调 **sub_1401750F0** = defines 重载核心 sub_14074A9E0(1) + "defines reloaded!" 日志 :3144 — mod 侧 define 表更新须重挂载的坑的引擎侧通道) / common/units/equipment (递归) / common/units / interface (递归) / gfx (递归), 句柄组 = **dword_14332ED64..ED74 连续 u32**; gfx/FX 另挂 CGameGraphics 内部 watcher (+864 对象 +1336 处)。重载分发骨架 (三件同源 :416): idler (qword_14332F6A0) 非空 → sub_140B17450(\*(idler+1944)) 对警报管理器 82 组 × 1128B 元广播事件码 1 → log "reload %s" → 路径=="gfx" 时 qword_143453090 (图形单例, 类名未决) vt[+24] 资源重载。单文件版 sub_140175DA0 = **CGFXReloader (ctor sub_140147E50, 匿名命名空间类名直证)** 的 interface watcher 回调 (书 §4.28.21 互证); 批量版 sub_1401A4A40 无文本调用者 (虚方法); defines 重载 thunk sub_1401A4A20 (无日志版)。重载接口表族 = 0x14271A070/098/0C0/0E8 四张 4 槽小表 ([0] dtor / 工作方法 / ret0 / nop; CReloadDispatcher dtor 直证锁定首表基, 类归属推定, 无 RTTI COL)。LoadDatabases 的 EH funclet 两件 (sub_14258F570 "File exception:" / sub_14258F630 "Unknown error while loading files!", 转译重抛 — 装载期异常不静默)。

#### 4.28.19 新开局世界构建链 (进程骨架与历史装配细节)

> 与 §4.28.18 分工: 该节 = 命令级联/两路分流/实体批产总览; 本节 = 层 0 进程
> 骨架 + Resetting game 八步内部 + 历史 Change 工厂与两段快进细节。

**核心结论 (定案)**: 新开局的世界构建在书签选择时同步完成, 不在点 Play
之后 — 玩家选书签 (或启动流程/MP 大厅) → CSelectBookmarkCommand
(ctor sub_14163BF60 → sub_142250B00 入队) → **Execute sub_14163D250** →
书签应用器 **sub_14067EEE0** (门 = force ∨ gs+2600 ≠ 书签) → **sub_1401A5630
"Resetting game" 八步世界重建** + 书签 effect (书签+264 vt+96) + gs 日期 =
书签+376。点 Play 只剩 **StartNewGame sub_140B3E9A0** (frontend.cpp:672/682):
玩家 tag/human 绑定 session (sub_1401F01B0) → malloc 0xB30 + CInGameIdler ctor
sub_140DC1B30 → SetIdler — **体内零世界构建**。

**新局/读档分叉位 = CBookmark+8** (真/空书签旗): 真书签 ctor 置 1 → 历史
装载+执行全链; TNullObject 空书签置 0 → 只存 gs+2600 由 §4.28.17 读档链覆盖。
CSelectBookmarkCommand::IsValid sub_14163DDA0 同判此位。

Resetting game (sub_1401A5630, gameapplication.cpp:2968) 八步: ① gs+2617=0
(setter = sub_1401EDFF0, gs+2617 直写 + 联动); ② **CGraphicalMap(app+880) 前置清理对
sub_140B52350/523A0** (门 \*(app+880) 非空; sub_140B52350 遍历对象 +104/+116 数族调
sub_14128C250 — 原记「FE 场景清理」系对象误认, 两调实参与 ⑧ ResetGame 同宿主); ③
**sub_1401EA1B0 世界重置 (13 步: 难度/天气/game_rules/派系/
补给/突袭/战略空海军管理器族 — 与读档链 §4.28.17 步骤 5-② 共享)**; ④
Destroying HistoryDatabase (sub_140A3CF40 单例获取 qword_143339CC0 48B →
sub_140A3D210; 与读档链同对); ⑤ Reseting IDs + 政治系统复位 (sub_140175130 实参 =
application 非 gs); ⑥ **`if
(书签+8)` 新局分支** (下段; 读档态 else 只存 gs+2600); ⑦ **sub_1401E2230 =
CGameState::InstantRefresh (掩码 0xFFFFFFF)** 逐国按位即时重算 — 函数自报
"InstantRefresh" (gamestate.cpp:6723), 掩码位图: bit1 CalcMod (supply_factor 误用告警
country.cpp:8863) / bit3 人力 / bit4+5 资源池 / bit7 附属列表缓存重建 / bit9 池重算
(全为重算目标无清零语义 — 原「CGameState::Reset 逐国全子系统复位」命名弃用; 调用点
三处 = 本簇 0xFFFFFFF / 读档 InitData 链 0xFFFFFFF / 行 4253471 传 1); ⑧ CGraphicalMap
ResetGame + sub_140A64600(qword_143339D28, current idler) 收尾; 附加: HistoryDatabase
Load 后进度串 "60%" / 两段 ExecuteHistory 哨兵 off_143086B18/B30 / 渐变边界上界 =
gs+796 计数 / 地图模式重置 = CMapModeDispatcher::OnMapModeChange(disp,0,0)。

R6 新局分支 — 历史装配与执行: **CHistoryDatabase::Load sub_140A3D640**
(history.cpp:279): 逐国 malloc 0x48 + CCountryHistory ctor sub_14153FB90
(+64 = 国 tag) → VFS 枚举 history/countries/*.txt → tbb 并行装配
(sub_140A3C760); 缺历史文件告警 "<TAG> - is missing a history file."。
**CCountryHistory::Load sub_141540190** (dated 块 reader): `1936.1.1 = {…}`
→ CCountryHistoryEntry → **Change 工厂 sub_1415403C0** ("Unknown History
Command ==>'…' for Country" countryhistory.cpp:171): 八专键 = capital
(10315→CCountryCapitalChange) / decision (11142) / oob (12137→COOBChange,
载荷 +72 串) / set_convoys (12384) / add_nuclear_bombs (12677) /
revolutionary_tag (13312) / starting_truck_buffer (19699) /
starting_train_buffer — **其余一切键编译成 CHistoryAddEffectCountry**
(336B: +72 CScriptEffect + +160 CExecutionContext scope=本国)。
**ExecuteHistory sub_140A3D2A0** (history.cpp:165 "Executing History from
<D1> to <D2>"): 州史链 (statedef+208) / 国史链 (ch+32) / general 链三循环,
区间 (from,to] 命中 → `(entry) vt+136` 槽 17 执行; **两段调用** =
① (负无穷哨兵 43791240 "-1.1.1", 默认 43817520] 执行全部初始态 ② (默认,
书签日期] **快进重放** (1939 书签 = 从 1936 重放)。OOB: `oob = <名>` 键 →
COOBChange::Execute sub_14035AF40 → **sub_140702F80 拼 "history/units/<名>.txt"
建军** (重建模式先清旧军)。

进程启动骨架 (一次): **InitGame sub_1401835A0** → LoadDatabases
sub_14018BB20 (进度 37/x/102; 含州 DB 三源装载 sub_140A64AA0 =
common/state_category + history/states + map/) → **InitGameState
sub_1401E0610** (gamestate.cpp:917): 战略区域数组 gs+736 (malloc 0x148/元,
断言 "Strategic regions already assigned." :2946) + 州骨架 gs+712 (malloc
0x928/元, 断言 "States already assigned." :2568) + **国家数组 gs+784 =
CCountryDataBase::ReadCountryFiles sub_14071C5C0** (countrydatabase.cpp:148/
155/197: malloc 0x1610 → CCountry ctor sub_1406C9CC0 (idx 0 哨兵 + 逐国) +
tag↔idx 映射 + **逐国读 common/country_history/<tag>.txt** (cc+5212=1 →
槽[3] Load wrapper) + 尾逐国槽[8] PostLoad)。

完成钩子 (定案): 新开局无 OnSaveGameLoaded 对应物 — 完成通知 =
StartNewGame → **CInGameIdler ctor 尾部 sub_140DD6A30 开局初始链**
(Hourly+Daily+Weekly+Monthly 各一遍, §4.28.14) + OnEnter 激活时间调度器;
命令侧终点 = CStartGameCommand::Execute sub_14163DA10 → FE 槽[80]
SetLoadingComplete。

#### 4.28.20 存档写出编排链 (§4.28.17 读档链的姊妹链)

主链与读档链逐级镜像 (定案):

| 步 | 函数 (VA) | 语义 | 置信 |
|---|---|---|---|
| T1 | sub_1402806A0 / sub_140280230 | UI 存档确认 (CConfirmSaveGame 系) / 控制台 `savegame` 命令 Execute (无参默认 "Test_01.hoi4"; **sv2_export 重存即此通道**) → 漏斗 | 定案 (T1' 高置信) |
| T2 | sub_140DA3530(lobby, meta, a3) | **保存分派壳** (读档分派壳 sub_140DA04F0 镜像): !meta+85 ∨ a3==1 → sub_140DA25E0 (新档写出); else → sub_140DA2E80 (续档重写) | 定案 |
| T3 | sub_140DA25E0 (gamelobby.cpp:2400/2416) | **新档写出器**: 文件名构造 sub_140D9BEA0 (与读链步 3 同函数) → 拼 **"_temp" 后缀** → 开流 sub_1424DF2C0 → sub_1401ECC50 → 关流 → exists→delete 旧 → **rename `_temp`→名 (sub_1424E14B0, virtualfilesystem_physfs.cpp:778)** = 原子落盘 | 定案 |
| T3' | sub_140DA2E80 | **续档同名重写器** (meta+85=续局旗): 同名截断重写 (流 sub_1422CD210), 无 _temp 中转 — 铁人档被持续覆写的根因 | 定案 |
| T4 | **sub_1401ECC50** | **CCurrentGameState::Save** (Load sub_1401E2AC0 镜像): ① [idler+1508 门] 逐国 pre-save 钩 sub_140713040+sub_140713090 (areas.cpp:437 战略区域表排序 "Sorting list %i.") ② dword_14332F284=0 (互斥旗) ③ tbb parallel_invoke { CSessionUpdateThreaded, **CGameStateSaveThreaded** } 同步阻塞 | 定案 |
| T6 | **sub_1401C8C70** (gamestate.cpp:1498) | **保存 lambda**: ① 取校验盐 sub_14061CD20 → sub_14061FBF0 ② humans 写前同步 (gs+248 数组 × 160B 循环, 读链步 10 镜像) ③ **sub_142232D10(stream, gs, 盐, 盐长)** ④ 刷浏览器条目 sub_1422330F0 (title=玩家名+ctime) ⑤ 异常 → "Failed to load save file " + 互斥旗=1; 尾旗=1 | 定案 |
| T7 | **sub_142232D10** (savegamehelper.cpp:348/363/386) | **保存引擎** (读引擎 sub_142232930 镜像): ① 写 "HOI4" (boot 全局 qword_1430BDE30) ② 三字节魔法: binary → "bin" / 否则 "txt" (binary 分支多写 token 16) ③ **sub_1424C4880 = 根保存** (thunk: 流+8=−1 → gs->vt[1]) ④ token 377 空值 + token 1 **校验和占位** ⑤ **sub_142231AF0 计 MD5** ⑥ **sub_1424C44F0 回填** ⑦ flush | 定案 |
| T9 | **sub_1401F29A0** (gs vt1 槽[2] CGameState writer) | 根块落盘序: **sub_140BC2710 (gs+16 元数据 writer: player/ideology/date/difficulty/version/tutorial/player_countries/save_version/minor_save_version/dlcs/mods) → sub_1401F27F0 (随机域 + session) → 全 gs 管理器键序**; gs+2216≠0 才写 token 16067 (all_playthrough_data 门); 读侧对应件 = sub_140D9B3B0 (键集 = player/ideology/ironman/dlcs/tutorial/players_countries/save_version/minor_save_version/cooperative_game/cosmetic_tag/mods; launcher `-start_save` 头解析同源) | 定案 |

读/存对称对照: 分派壳/驱动/gs 入口/tbb 并臂/引擎/根 thunk/wrapper **全镜像**;
**不对称点 = 保存无尾波** (读侧 PostLoad 三波 + 重挂波, 保存只读现态 +
pre-save 排序钩) (定案)。Save wrapper sub_1424BEC50 = 块开 sub_1424C4410 →
槽[2] writer → 块闭 sub_1424C3A20 — **写侧无 PreSave/PostSave 对称钩**
(钩族全是读侧专用, 定案)。

autosave 调度与轮换 (定案):

| 步 | 函数 | 语义 |
|---|---|---|
| A1 置位源 | CAutosave::Execute 0x140DE7C40 → 槽[728] / +2216 倒计数 / 日历边界 (**日节拍 sub_140DD9740 + 月节拍 sub_140DDA1B0 调用**) | §1.1b.1 在册 + 本轮补两调用者 |
| A2 分派器 | **sub_140DCE470** (Idle 每帧) | 两相位 (+1680 请求 → +1681 横幅 "AUTOSAVING" → 清双旗) → 三路: gs+192 bit0 铁人 → **sub_140DD07B0** (周期 +2216=168h = 7 游戏日) / 云 (设置+589) → **sub_140DCE810** / 否则本地 **sub_140DD0980** (ingameidler.cpp:4436; 编号候选名逐个 exists→delete 轮换 + 读现有 autosave 头灌 meta sub_140D9AA30); 随后 idler+1700 队列非空且非铁人 → **sub_140DD1320 日期序列** |
| A6 日期序列 | sub_140DD1320 | idler+1688 24B CGameDate 队列 (计数 +1700) 对照 gs+1128, 到期 → 存 **"autosave_date_<游戏日期>"** — 实测 "autosave_<ts>.hoi4" 消失/改名 = **编号轮换删旧 + 日期序列另立名 + 云路三机制合流**, 非 rename 单点 (定案) |

#checksum / #version / #dlcs / #session 生成点 (EXEMPT 四项闭环, 定案):

| 叶 | 生成式 |
|---|---|
| **checksum** (token 377 占位) | **MD5(文件字节 + 盐)** 32 hex 小写 (sub_142231AF0: init/update(盐)/update(全文)/finalize); 盐 = **"I_am_such_a_cheater"** 19 字节常量, 成就/铁人条件 (+163 ∨ +161∧+162∧旗) → 云对象 8 字节盐 (sub_14061FBF0); 两阶段写入 (占位长度恒定故可回填 sub_1424C44F0); 读侧比对 sub_142231720 (在读链随机流播种同站) |
| **version** (238) | 写盘时现取 app 版本串 (sub_1424D86B0(*(idler+1328)+352)) |
| save_version / minor | 宏常量 SAVE_VERSION=33 / MINOR (dword_143335FEC / dword_143336080) |
| **dlcs** (11546) | boot 位掩码全局 dword_14332F248 写盘时读现值 |
| **session** (13954) | **time(nullptr) − Time2 (会话起点) + qword_14332F428 基数** = 墙钟秒 (sub_140202190) |

二进制/文本分叉 (写入侧, 定案): 文件头 "HOI4" + "txt"/"bin"; OOS 转储
(a3=1) 或 byte_143452529/2B 强制二进制, 否则 CSettings+599 文本选项决定。


#### 4.28.21b CSession 实现层 / 控制台命令条目 / DLC/大厅增补 (loader 侧定案)

**CSession 布局增补** (§4.28.16 姊妹): 虚表 0x142B3E9D8 仅 8 槽 (本族全非虚直调); ctor = 0x14224E3E0 / Init = 0x142250890 (server 三型构造 + server+80 反指); 全局单例槽 **qword_143451DA8**; **命令日志链表 +312/+320/+328** (热加入重放源; RequestSynch 0x142251420 反序列化 session+400 命令日志流 → 重放, 每 5 条插帧保活, identity(+28) 严格递增校验); 批命令缓冲 +104 族; **断线重连机 sub_1422502F0** (+1968 路径; 三分岔 = 无动作 / 主机重建 / 客户端重连, 总门 +1056 无置 1 写者待裁; 全链 §4.36.5); SetState 0x142252680 (观察者广播码映射全表; **7 个终态**广播后状态回置 0 = {7 REFUSED, 8 KICKED, 9 IS_BANNED, 10 NAME_TAKEN, 11 NAME_INVALID, 16 BAD_VERSION, 17 BAD_PASSWORD} — 勘误: 原「6 个」计数差 1, switch 逐 case 直证); 命令发送门实为**四条件** (a3 ∨ +1941 ∨ cmd vt[16] ∨ vt[12]; 勘误: 原三条件; ctor 默认 1); **+164 = machine id** (勘误: 原「玩家 id」; "Machine id %d assigned"); Update 命令派发主泵 0x142252D00 (状态路由主派发位集 {2,4,13,14}; 逐条 IsValid→Execute (+1852 包夹); 就绪命令 Clone 进 +312 日志); RequestHotjoin 0x142251120 (`*(WORD*)(+1854) = 257` 一次写 +1854/+1855 双旗, +1855 粘滞独立 setter = SetHotjoin sub_142252520; 消息 14 REQUEST_HOTJOIN 键 11/27/226)。

**CGameLobby 增补** (§4.28.18 姊妹): ConnectToGame sub_140D99F10 (找局→版本核对→starting/lobby/running 三态门→CSession(1976B) 安装→热加入起步 SetState(12)); Update 六块状态机 sub_140DA3F20 (+1218 = **接入触发旗** — 勘误: 原「离开旗」只记前半, 后半跑 ConnectToGame); **+1214 = WORD 写 257** (连带 +1215); Update 驱动不止 FE Idle — **sub_140DD3A50 (InGame 回菜单 Idle) 也驱动 +1904 第二大厅**; +88 热加入名单 (32B 串元素, 匹配键 = CHuman+64 name); 云端存档/rules 预设四件套 (rules 固定临时名 "_temp.txt" 原子换名); 文件分块传输 Ack sub_140D9F2C0 (this = 第二基 lobby+8 视图 — 双基偏移规则); 热加入收尾 sub_140DA1020 ("HOTJOIN_ENDING!" + SetState(4) + net "running"); 11 个 EH catch funclet 负定案勿入书。

**控制台命令条目 456B 布局增补** (§4.28 命令表 383 条姊妹): 条目 +0 = **available_in_release_build** (勘误: 原「dev 旗字节」; 0 = dev-only, JSON 仅 0 时写 false 键); **+40 别名计数 / +48 别名 char\*\* 数组 (null 结尾) / +72 描述串 / +112 参数补全支持旗 / +128 参数说明计数 / +136 参数说明串数组 (32B 跨距)**; 注册双轨 = 4 张 .rdata 静态表 (取值器 sub_14119A840/0x141194820/0x1411A8820/0x14117B270) → 合并容器 qword_14332F4F8/count dword_14332F504 → 去重 bulk-register sub_1424B4920 注入管理器 (主注册点 = 启动序 sub_140126E50); 新式单命令走独立注册器 (crash 例 sub_1423927F0)。**控制台随机 = Random::Get(file,line) (sub_142233FA0) 独立流, 不动存档种子流 — 对拍安全**; random_seed 无参 = 状态×地址哈希重播种 (handler 0x14027D780); SetRandomCount = sub_1422345C0; `oos` 命令 = Random::Get(file,8657) 仅本端调用 → RNG 流单侧偏移失步机制直证; 新全局: qword_14332F540[3] 舰队行动区三色槽 / qword_143330000 效果文档库 / qword_143330050 触发器文档库 / qword_14332F5A8+F5C0 两组 fired 计数器 (debug_dumpevents/debug_dumpdiploactions)。

#### 4.28.22 NCareerProfile 生涯档案管理器 (持久化/同步/奖项核心层; career_profile.cpp)

单例指针链 (定案): `qword_143452450` (CApplication 单例, §4.28.21) → **+912 scopedptr** → 本管理器 (约 2024B; 获取包装 sub_14068F870)。总尺寸推定 2024B (布局止于 +2017, ctor 逐成员核验未决)。

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | SGameModeStatistics (144B) | 单人模式统计组 | merge 目标; Save mode0 |
| +144 | SGameModeStatistics (144B) | 多人模式统计组 | keyed 15988 "multiplayer" 写此; mode1 |
| +288 | SCareerProfileAwards + SCareerProfileStatistics 混合块 | 奖项槽 +296..+1952 (69 × 24B) 与 achievement 数据共存 | keyed 10890 "achievement" 整块写 |
| +1960 | 串 | 最近提交时间戳 (墙钟秒串) | |
| +1976 | 指针 | 云目录句柄/路径 (非空才跑 .pr 保存链) | |
| +1992 | 集合容器 | 已成功打开的 .pr 文件名集合 | |
| +2016 | uint8 | 云目录已载一次性旗 | |
| +2017 | uint8 | 上传抑制旗 | |

SGameModeStatistics (144B) 宿主: +8 = 当前组 2056B 国条目容器 {arr@+16, count@+28} / +40 辅容器 / +52 计数旗 / **+64 = mod 统计组注册表 {arr@+64, count@+76} 96B/项** (项 = {+8 组名串, +40 容器挂 2056B 条目}; 组名 = MOD_STATISTICS_GROUP, 长度上限 30 超限告警 career_profile.cpp:650) / +88 回退组容器 {arr@+96, count@+108}。

国条目 (2056B/项, 定案): +8..+1008 = 现跑统计镜像区 (u32 +8..+564 步 4 / u64 +568..+752 步 8 / +760 大槽) / **+1016..+2016 = best 记录区 (与 live 区同构同偏移)** / +2000..+2016 = best-in-career 位集镜像 / +2024 = 条目名串。live 统计区 = sub_1401C9FC0(gs, tag)+8 (运行时国对象内, 形状同构约 1008B)。条目查找失败哑接收器 = unk_143330780 (三 finder + 对账共用; 一次性断言行 1336/1356/1370/1384/1868)。

奖项槽 24B (定案): {+0..+11 保留含成就名 key, +12 int tier (0 未获/1 铜/2 银/3 金, 只升不降), +16 u64 获得时刻 (Windows epoch 秒)}。槽表 = **33 勋章槽 +296..+1064 (token 15960..17334) + 36 绶带槽 +1088..+1928 (token 15961..17629)**; 授予 = sub_1406932A0 (AwardMedal: 按名查 **CMedalDatabase qword_14332EE30**, def+16 启用旗假 → "Missing medal metadata"; tier 判定三原语 sub_1406ABF50/C000/C0B0) / sub_1406935B0 (AwardRibbon: **CRibbonDatabase qword_14332EE48**, tier 恒 1); 遥测 + push {名, tier} 入弹窗向量。判定入口链: CGameState::HourlyUpdate sub_1401DF400 (gs+2617 门) → sub_140692B10 (门 = 可用 ∧ Steam context ∧ 非 CNetworkServer/CProxyServer ∧ 玩家 tag>0) → 逐槽授予 → **CInGameIdler+2560 弹窗队列** (§4.28.14, 勋章 vec@+0 / 绶带 vec@+24)。

可用门族: IsAchievementsOk = `ach[163] || (ach[161] && ach[162] && !byte_1434530D4 && !byte_14332EC69)` (成就管理器单例 qword_143330460, 0xA8B, get-or-create sub_14061CD20); 完整门 sub_14069A160 = gs 断言 ∧ gs+2232 ∧ 上式 ∧ !sub_1401DF030 ∧ scopedptr+1088 槽。

持久层 (全部引擎自有流, 无直接 WriteFile):

| 通道 | 格式 |
|---|---|
| 云目录 `career_profile/v2/statistics/*.pr` (LoadFromCloudDir sub_14069E010 / SaveToCloudDir sub_1406A4510) | 每文件 = 可选 238 头 int + 版本化负载 (v1 = 单 SCareerProfileStatistics, **读后即弃**仅验证; v2/3 = {SGS, SGS, 1720B SCP} + 尾部校验和, 失败 "will be ignored" 行 2551); 写 = 238 头 (模式 3) + 虚槽[2] Save + keyed 15988→+144 / 10890→+288 |
| 本地单文件 (LoadFromLocalStorage sub_14069E9B0 / SaveToLocalStorage sub_1406A4840) | 版本 1..3 依次探测, 无 238 头; 校验和失败 "will be replaced" 行 2374 不合并继续下一版本 |
| 混淆 blob (字段 10462/10463 载荷) | u32 对数组 `plain = stored[i] ^ MurmurHash3_x86_32(i, seed 0)` (sub_1424F0F40; c1 0xCC9E2D51/c2 0x1B873593); 自校验 hash(123) == 0x3817E176 否则 fatal "The hash function has changed…" 行 722; 读侧 sub_1406A1AC0 (key 分发写 u32 槽) / **写侧孪生 sub_14069F630**; field 分发 sub_1406A1940 (10462→条目+1016 / 10463→条目+8 / 10754→条目+2024 串) |

CommitAndUpload 总入口 sub_1406A40E0 (10 步, 定案): 时间戳串 → SGS reset 双组 → 本地载入合并 → (!+2016 ∧ settings+590 save_career_to_cloud (15954)) 云目录载入 → +2016=1 → 按 mod 注册表逐组重算派生槽 → 本地保存 → 路由 (控制台旗 delete_cloud_career_profile_files → 云删除; 否则云开关 ∧ 成功 ∧ !+2017 → 上传) → 清脏 → 组名长度告警。调用者 = InitGame sub_1401835A0 / 前端 idler ctor sub_140B3B290 / InGame idler 建立路径 sub_140DC1B30。5 个 0x1425F 冷段函数 = 上述 I/O 函数的 catch funclet (自报行号 286/337/2569/2448/2318 一一对应), 非独立函数。

best-in-career 位集机制 (定案): live 区 +984..+1000 ≤192 位标记; SetBestInCareerBitset sub_14069DCD0 拷外部位集 (>3 qword 告警截断 行 771); 对账 sub_1406A5DB0 (859 行): 联网/CProxyServer 托管整体跳过 → live[off] >= 条目+1016[off] 逐槽纯比较 (三原语 sub_140699630/640/650, **不写值**), 失配清位 (约 190 对映射编译期展开; 尾部强制清位 88/位 125); 调用者 sub_141F89B80。

GUI 取数族: 前端统计视图 141FACA40→sub_140695F50 (拷 1000B 记录) / 141FAD0E0→{sub_140696380 三分区 +8/+152/+296, sub_140696180 mod 组} / 1414DDEA0→{sub_140695E20 静默 finder, sub_140696300 二分区}; 现跑镜像写点 sub_140CC9AD0/140CC80E0 (+68/+552)。人机门耦合: sub_140DC1B30 `!IsAchievementsOk || byte_14332F639 (human_ai)` 门后走 gs 分支。

#### 4.28.23 CGameApplication Run 主循环与退出链 / LoadDatabases 102 步骨架 (定案)

**Run = sub_14222E7E0** (noreturn, §4.2.1 互证): UpdateWindow → **主线程钉核** = GetProcessAffinityMask 数逻辑核 n, n>1 时目标 = n/2+1 (后半段第一个置位核) → SetThreadAffinityMask → vt+80 槽[10] (游戏表 = 空桩无操作) → while(!+132): ① byte_14345244C 高亮请求 → CPdxWindow vt[+16] 判 "highlight_window_when_ready" → FlashWindowEx 任务栏闪烁 ② +776 置位 break ③ HCURSOR 槽非空 SetCursor 逐帧重贴 ④ **每帧一步 sub_14222EEB0** ⑤ +131 → +132 → 退栈 = vt+88 槽[11] Shutdown flush → idler 容器收尾 → SteamAPI_Shutdown → exit(0)。**退出三旗** (定案): +131 = 请求退出 (setter sub_14222CAC0 单行体; 全语料唯一调用 = main docs 模式 dump "script_documentation.json" 后) / +776 = 本帧事件泵判定退出 (CSdlEvents vt[+8] 返回值, 循环顶 break) / +132 = 退出进行中 (循环条件)。**进程内重启链不存在** (exit(0) 一去不返; "Resetting game" 是书签级世界重建非进程重启; 控制台 quit 落点未决)。

**每帧一步 sub_14222EEB0(app, a2)** 全序 (§4.2.1 骨架互证 + 细化, 定案): 主线程断言 (random.h:74) → **帧号发布 dword_143481264 = app+816 / byte_143481268 = 1** → idler 指针解析: **SDL 事件泵的 idler 形参被 HotkeyManager 单例 qword_1434531A8 顶替** (热键优先吃事件; Idle 派发仍用 app+56 原值) → 事件泵 sub_142231680 → CSdlEvents vt[+8] (泵尾对 idler 调 vt[+120]/[+96]/[+104], 参 = settings 桶×0.01×4+1); 返真 → +776/+132 置位本帧余下全跳过 → 图形忙检 → dt = 首帧槽[15] (1/60s) 否则 now−+792 → **设置亮度/对比/伽马三通道** (settings 浮点 ×0.01, 48/49 平方合成/50/51) 变化检测 → 渲染器 sub_1423B5C10/20/30 下发 → **Idle 派发 app+56 vt[+32] 槽[4]** → idler 切换段 (+64 请求旗: 旧 current → +120 (原住者 vt[0] 删除), OnSuspend/OnLeave 族 → +112 待入 → +56, 新 current OnEnter 槽[11] → 槽[5] (线程名+jumpbuf) → 槽[7] → 槽[9]) → app+816++ → 限帧 (**帧率设置整型 @settings+220**, 目标 = 1.0/值, 欠额 sub_1401BA490 睡眠)。

**Shutdown flush (槽[11] sub_140195110) 全序** (定案): gs 存活且 +2617 → 生涯档案收尾保存 sub_1406A4A30 (delete_cloud_career_profile_files 旗 → 云删除; 否则云开关 ∧ 保存成功 ∧ !+2017 → 上传, §4.28.22 同款路由) → 单例 qword_143339C70 (0x2A8) flush → career 中间统计落盘族 → **TGameItemDatabase 全库中序遍历逐项 +296 旗置位者 flush** → 管理器单例 flush 长队 (HotkeyManager 等 11 个「getter→flush」对, 类名未决) → **设置落盘** (settings 单例 +237 脏旗 → sub_14222B040 序列化; 失败 "Could not write settings file … (read-only?)" systemsettings.cpp:142)。

**LoadDatabases (sub_14018BB20) 102 步骨架** (定案): 进度契约 = sub_14222E270(app, **组 37**, N, **总 102**, 0); 每步统一形态 = DB 单例守卫断言 (gameitemdatabase.h:127/142/179 "Instance already created.") → 失败 "DB already loaded when loading <名>" 告警 → 通用包装 sub_14018B0E0 (DB +20 已载旗 / vt[+48] 逐文件解析 + VFS 目录枚举) → 进度 +1。全步→目录绑定表 (高置信, 目录串实测):

| 步 | 内容 | 步 | 内容 |
|---|---|---|---|
| 1 | sound/combat_sounds | 52 | technology_sharing |
| 2 | strategic_locations | 53/54 | operation_tokens / operation_phases |
| 3 | country_tags | 55 | operations |
| 4 | script_constants + script_enums + scripted_triggers | 56 | unit_leader + combat_tactics + ideas |
| 5 | idea_tags + scripted_effects + special_projects/projects | 57/58 | country_leader / unit_medals |
| 6 | frontend/backgrounds | 59 | unit_leader (二次) |
| 7/8 | DB 建槽 (malloc 0x80 件, 无目录串) | 60 | intelligence_agency_upgrades |
| 9 | special_projects/{projects, project_tags, specialization} | 61-67 | factions/{member_upgrades(+groups), rules(+groups), goals, templates, icons} |
| 10 | units/unit_modifiers + terrain | 68/69 | ai_faction_theaters / intelligence_agencies |
| 11 | country_tag_aliases | 70 | decisions |
| 12 | mtth + ideologies | 71-76 | focus_inlay_windows / national_focus / continuous_focus / bookmarks / bop / peace_conference |
| 13 | scientist_traits | 77 | map_modes + custom_map_modes |
| 14 | characters | 78 | **LOADING_HISTORY** (HistoryDatabase 单例 → Load, §4.28.19 互证) |
| 15 | modifiers + resources | 79-80 | ai_areas / ai_strategy |
| 16 | units/equipment | 81/82 | 文件路径列表预留 helper / 加载屏对象方法 |
| 17 | unit_tags + units | 83-85 | ai_focuses / ai_templates / ai_equipment |
| 18 | buildings | 86/87 | dynamic_modifiers / scripted_localisation |
| 19-23 | opinion_modifiers / generation / wargoals / difficulty_settings / game_rules | 88/89 | 无串两步 (helper) |
| 24-27 | medals / ribbons / profile_pictures / profile_backgrounds | 90 | abilities |
| 28 | scorers/country + equipment_groups | 91 | ai_strategy_plans |
| 29/30 | MIO ai_bonus_weights / organizations | 92 | gfx/army_icons |
| 31-34 | doctrines/{folders, tracks, grand_doctrines, subdoctrines} | 93 | scripted_guis + resistance_compliance_modifiers |
| 35 | special_projects/prototype_rewards | 94-96 | occupation_laws / resistance_activity / scripted_diplomatic_actions |
| 37 | MIO policies | 97 | dlc_metadata/dlc_info |
| 38 | collections | 98/99 | 无串两步 |
| 39 | ai_navy/{goals, taskforce, fleet} + acclimatation (重扫步) | 100/101 | 仅进度针 |
| 40 | messagetypes_custom.txt (版本旧/损毁两分支) | 41 | **INIT_MAP_LOGIC**: CMap ThreadedPostRead (byte_143085000 时挂 "Long Task" 异步) |
| 42 | raids + categories (LOADING_DATABASES 相名复位) | 43 | equipmentdesigner/graphic_db |
| 44-51 | units 四 names + timed_activities + names + aces + technology_tags+technologies + autonomous_states | 102 | 收尾: gfx/train_gfx_database + CMap ThreadedPostPostRead (**源行 :2779** — 原 :4691 语料零命中系误植) |

异常骨架: 整函数 try/catch 双 funclet (sub_14258F570 "File exception!" / sub_14258F630 "Unknown exception!", 转译重抛不静默)。无目录串步 (7/36/48/88/89/98/99) 具体 DB 名未决 (需逐 loader 实参反解)。

#### 4.28.24 gamelobby.cpp 簇对账增补 (23 函数闭环; 云端持久件四件套函数级收口)

**云端列表装载器双子** (定案): sub_140D9D9D0 = 云端 **rules 预设**列表装载 (条目 168B:
+32 文件名 SSO / +64 u64 时间戳 / +85 存在旗 / +86 属性旗, 其余由解析器 sub_140A38000 填);
sub_140D9D600 = 云端**存档**列表装载 (条目 224B: 同头部 + **+80 u32 文件大小**; 内容
sub_140D9B3B0 直解)。共享骨架: 云对象 = `*(*(CGameApplication 单例 +856)+56)` →
sub_1423DC320 会话开 → sub_1423DC240 两遍枚举 (第一遍数量, 第二遍填指针数组) → 逐项拷入;
目录名经 sub_140D9D4F0 构造 (rules = "game rules" 串; 存档 = lobby+168 桶名槽作实参,
+168 由此精化为云桶名参与者); 失败断言 "failed to read cloud save somehow" (2065/1779 两族)。

**rules 预设写出双路** (定案): sub_140DA1FA0 = 本地写出 ("game rules" 拼 .txt → 5 字符
临时名 (同域 "_temp" 直证推定) → 开流 → CGameRulesInstance ← gs 灌注 → 序列化 → 关流 →
exists→delete → rename sub_1424E14B0 原子落盘; catch 2232/2248); sub_140DA2A90 = 写
**lobby+232 内存缓冲**经云端流 sub_1422CD210 → 同款灌注序列化 → sub_1422CDBF0 取成功旗。

**存档写出孪生对与选择门** (定案): sub_140DA25E0 (本地 _temp 原子落盘, §4.28.20 T3) 与
sub_140DA2E80 (云端) 同构 — 目标名 = sub_140D9BEA0(a1, 远端名, a2, lobby+168 桶) 拼
lobby+136 后缀, 核心写 sub_1401ECC50(gs, 流, 本地名)。云端失败 → 日志 +
**REMOTE_STORAGE_WARNING_TITLE/DESC** 两本地化键 → malloc(2792) 对话框挂
qword_14332F698+1272 队列。分派包装 sub_140DA3530: 描述符 +85==0 (新局) ∨ a3==1 → 本地,
否则 (读档局) → 云端; sub_140DA04F0 内细门 = `lobby+1217 && gs+192&1` 才写, 选择器 =
**gs+101 (u8)** (非 0 云端/0 本地; 语义待裁, 推定云端存档旗); 写后调生涯档案管理器标记脏。

**CSession 布局增补** (高置信): ConnectToGame join 收下路 (三态门 "lobby" 分支) 把
lobby+304 / +336 两 SSO 串拷入 **session+1864 / +1896**, 并 `session+1936 (u32) =
sub_140B54190(session)`, 后才 SetState(12); 三槽 §4.28.16 表此前未载, 串内容待裁
(推定玩家名/密码)。ConnectToGame 日志家族全录: "Net: ConnectToGame …" 六串 + 状态名串
19 个 (SetState 广播码映射就地嵌入); 三态门 = memcmp 长度校验 starting(8)/running(7)/lobby(5)。

**EH funclet 配对法** (定案, 可复用): 簇内 11 个 catch funclet 经行号指纹法全配对 —
funclet 体内 sub_1424C9AE0 断言自报 gamelobby.cpp 行 ↔ 主函数 catch 行 (±1); §4.28.21b
「11 个 funclet 勿入书」数量逐个坐实, 维持勿入书。

其余增补: 第二大厅 (+1904) 驱动点扩充 = 热加入收尾 sub_140DA1020 另有 sub_140DDC350
(InGame idler 域) 与设备恢复槽 sub_140DDE8A0 两驱动者 (设备重建/读档完成路径也对第二厅
跑收尾); Update 云上传半边 (推定): +1204==1 分支非热加入客户端门 →
sub_1424E17E0(流, lobby+232, +244) 把 rules 内存缓冲整块写入分发流 (与 +200/+232/+244
记载互证); rules 条目 >32 时压缩重排 (sub_140D94460 + sub_140D971A0, 语义待裁, 疑 UI
分页/去重)。

未决: gs+101 语义; lobby+304/+336 串内容; session+1936 语义 (sub_140B54190 未读);
rules 重排与 sub_140D94640 后处理; lobby+1192 句柄身份 (维持推定); Update +268/+280
容器语义。

#### 4.28.25 session.cpp 簇对账增补 (11 函数闭环; 命令泵与新字段)

**ExecuteLocalOrders = sub_142250D00** (新定形, 高置信): server slot20 (+160) 取**本地即时
命令链表** (驻 server 对象, 节点 {cmd, +8, next}) 逐条泵 — 断言 `GetIdentity() == 0`
(:663) = 此链命令**不入日志不广播的本地单发命令**; IsValid (vt slot9) → +1852 包夹
Execute → **+1848 (u32) 自增** → GetDesc; 每条后调回调对 `*(+1960)(*(+1952))` (fn ptr +
ctx, 装填者未决) → delete → 链表清空。消费点 = Update 主派发尾与态 6 路。发送侧四条件门
中走「立即本地执行」支的命令落点即此 (呼应 +1941 即时/本地门)。

**Update 状态路由全表** (定案): 态 ∈ {2,4,13,14} (位掩码 0x6014 直证) = 主派发; 12 = server
slot6 后返 1 / 15 返 1 / {8,9} 返 0 / {3,7} 广播返 0; 其余态唯 6 (ASYNCHRONOUSLY_CONNECTED)
达 +1968 检查与 orders 泵。主派发逐条三过滤 (cmd slot12 ∨ !+1854 ∨ cmd slot15; 不过滤 =
"Command NOT executed due to ongoing hotjoin" :563/:569) → IsValid 双形态 → 执行期广播门
(+80 ∈ {2,4,5}) → +1852 包夹 Execute → +1848++ → Clone (slot13) 头插命令日志链表; 重入路
(+1852 ∨ +1969) 断言 :599 + 双日志 :600/:629。⚠ 热加入态批内命令不 delete (计数仍清),
疑依赖会话重建兜底, 待裁。

**CSession 字段增量** (定案): 批命令缓冲 {data@+104, cap@+112, count@+116} + **+120 分配器
对象** (虚表 slot1 分配/slot3 释放, 扩容 max(count+1, 1.5×cap)); 命令日志链表角色 =
**+312 尾(最旧) / +320 头(最新) / +328 计数** (头插序); **+1848 已执行命令计数** (读者未决);
**+1952 回调 ctx / +1960 回调 fn ptr**; **+136..+152 已分配 machine id 链表** {尾@+136,
头@+144, 计数@+152} (Init a3==1 时自身 id=1 入表); +160 (Init 写 2, 推定下一 machine id,
簇内零消费待裁) / +360 (Init 写 −1, 待裁)。

**Init sub_142250890 全量写点** (簇外互证补全): WORD 清 +1968/+1969 / +1852=0 / +1056=0 /
+400=0 / +72=0 / +84=(a3−1)≤1 / +128=0 / +96=0 / +76=a3 (server 型 0=proxy/1=network/
2=dummy) / **+80=a4** / +164=1 / +160=2 / +88=server (server+80 反指); a3==1 → +72=4 +
自身 machine id 入 +136 链表; +84 真 → 观察者广播码 0。

**CServer 虚表槽消费图** (session 视角, 字节偏移): +32 slot4 发送/flush (RequestHotjoin ·
接受热加入) / +40 slot5 命令入队 / +48 slot6 每帧 server 钩 / +64 slot8 命令队列取出 /
+96 slot12 / +152 slot19 before-sync 命令表 / +160 slot20 本地即时命令链表 — 实现侧归
§4.36 域。**CCommand 虚表消费图印证**: +72 slot9 IsValid (双形态 (cmd,0)/(cmd,&串)) /
+80 slot10 Execute / +88 slot11 GetDesc / +96 slot12 就绪谓词 (发送门 ∨ 执行门 ∨ 日志
Clone 门三处) / +104 slot13 Clone / +128 slot16 发送门第二谓词; cmd+8 已 Clone 旗 /
cmd+22 stamp (min(+128, 0x7FFF)) / cmd+24 延迟旗 / cmd+28 identity。

**RequestSynch 全量精化** (定案): 仅态 6 动作; +400 GAME_STATE 流一次性消费 →
sub_142269C60 反序列化命令日志入 +312 链表 → 从尾(最旧)顺序重放 (identity 严格递增校验
:735 + 每 5 条 Update 保活) → **before-sync 命令去重** (identity ≤ 上次先扫 +312 日志查同
identity, 命中 = 已重放的重复静默跳过; 未命中 :782) → Execute → 头插并入永久日志 → 内联
SetState(4) 带广播码 0。

其余定形: **SetMachineId sub_142252480** (`+164 = a2` + "Machine id %d assigned" :354) /
**接受热加入 sub_14224F550** (:1283 日志直证; 调用点 = CGameLobby 玩家条目 swap-pop 移除
路径, 出队方向待裁) / **catch funclet sub_1426EB280** (session.cpp:844/845 CFileException
体; 零静态调用点 = 纯 EH 表引用; 闩 byte_14345319F 与 RequestHotjoin 内联 catch 共享 =
同源静态 COMDAT 合并) / **请求加入分流器 sub_1422513F0** (簇外: 态 12 → RequestHotjoin
(+1864/+1896/+1936), 否则 → RequestSynch, 与 §4.28.24 三槽互证)。RequestHotjoin 尾 = 内联
SetState(12) (态 12 本无广播 case, 语义等价) + 立即 Update 泵一帧。观察者协议: 链表头
session+8 (32B 节点), 观察者 slot[1] 收单码; 码域与状态域不同构 (全映射: 0=connected 类 /
1=connecting / 2=refused / 3=reconnect-pending / 7=disconnected / 8=async / 9=KICKED /
10=BANNED / 11=NAME_TAKEN / 12=NAME_INVALID / 15=HOTJOIN_REFUSED / 16=BAD_PASSWORD /
17=JOIN_DISABLED / 18=BAD_VERSION)。

未决: +80 全枚举值域 (0/1/3 语义); +160/+360 消费者; +1848 读者; +1952/+1960 装填者;
热加入批尾不 delete; byte_1435E1B51 vs B52 断言门分工 (B51 = catch/类型切换路, B52 =
identity/有效性路 — 本簇分布如此); 日志原语 sub_1424C9AE0 末参类别码枚举名。

#### 4.28.26 ConsoleCmdImpl.cpp 簇对账增补 (控制台命令处理器实现侧; 20 函数闭环)

簇 = 命令表 383 条中落 ConsoleCmdImpl.cpp 的 **17 个注册命令处理器** + 3 个内部件
(loc 键检查核心 sub_140232CD0 — 七个校验命令族共享 / 命令条目 JSON 序列化器 sub_14022F1F0 /
写盘失败回显 lambda sub_1425A0010)。注册命令名: add_fleet_arrow / dump_garrison_templates /
spawn / docs [trigger_docs·effect_docs·scripting_docs] / event / damage_units /
log_advisor_trait_errors / debug_orders_tree [dot] / random_seed / SetRandomCount / helplog /
debug_dumpevents / debug_dumpdiploactions / debug_textures / error / oos。

**注册机制** (定案, 方法学): 17 个 handler 的代码引用集中于**单一巨型注册函数**
0x1400036F0-0x140013D0A (约 64KB, 单条 RUNTIME_FUNCTION, 反编译器未产出) — 每命令在**栈上
memset 288B 临时条目** (串 assign + `lea rip-rel` 存 handler + 标志立即数), 故**二进制静态
镜像零 handler 指针表**; 找命令注册名须对 handler VA 做 .text 全段 rip-rel disp32 扫描后回读
命中点邻域串引用 (8B/4B 指针扫描恒阴性, 4B 命中全为 .pdata 自身记录)。串池 = .rdata
0x14272xxxx 区连续铺排。命令管理器惰性 ctor = sub_1424B4C40 (0xE0 分配 + 3 个 lambda 槽),
ctor 本身不注册命令 (与 §1.4 互证)。

**handler ABI** (多处独立重现): result 40B {+0 u8 状态, +8 回显串}; args 24B {元素数组@+0,
**计数@+12**, 元素跨距 32}; 整参解析 sub_1424CC210 (string→atoi), fixed 解析 sub_1424CBFB0;
17 个处理器全部经引擎 API 施效, 无一处直接写内存。

命令机理要点 (深读定案): **oos** = 无条件在确定性流外掷引擎随机一次 (ConsoleCmdImpl.cpp:8657)
+ 回显 "This player will go out of synch." — 故意制造 desync, 与 RNG 禁区断言同机理面。
**docs** 双模: text → game.log (拼 TRIGGER/EFFECT/DYNAMIC VARIABLE 三大节, 后者六子类);
**触发器/效果注册表全局锚 = qword_143330050 / qword_143330000** (惰性 ctor sub_14054CEA0 /
sub_14053D840); json → sub_140299AD0 写 script_documentation.json (11 节: script_concepts/
loc_formatter/script_collection_input/script_collection_operator/script_math_functions/
loc_objects/effects/triggers/modifiers/dynamic_variables/console_commands), 同一写盘核心被
启动旗 `-dump_script_doc` (主启动函数 0x140126E50) 复用。**event**: arg0 按 id 或名查 →
RTDynamicCast CEvent (失败 "There is no event with ID #N"); scope 优先级 = arg 国 → 选中
对象 (类型判据 +3708==3 取 +288) → 当前国; 发射 = `vt[+104][+96]`。**spawn** `<类型> <省>
<量>`: 量钳位 1..100; 省缺省 = 当前国随机 owned 省; 当前国解析 = `gs+1312 > 0 ? [gs+1312] :
[gs+1316]` (§4.24.16 候选语义的第二消费者独立重现); 模板查 qword_14332F090 编制库, 查无回落
"infantry"。**damage_units** `<org%> [strength%] [count]`: fixed×1e5, **负值 = 增量语义**;
count ≥ 0 时 Fisher-Yates 部分洗牌抽样; 数据源 = 选中单位 + 鼠标下单位两容器合并。
**add_fleet_arrow** `<red|green|blue> [max]`: 从选中战略区沿海省洪泛收集, 三色缓存槽
qword_14332F540[0..2], 未建则经 qword_14332F698 → +1744 → sub_14126F380 创建名为
"fleet_area_of_operation" 的战略区 (命令**建的战略区名** ≠ 命令名, 检索勿混)。

**新引擎全局锚清单** (定案, 书内此前无记录): qword_14332F260 = CGameState 单例
(`_pInstance`); qword_14332F090 / qword_14332F0D0 = 两个 TGameItemDatabase 族单例 (前者
编制模板库 / 后者顾问·角色库, 后者消费式 = `db + 112 + 24*(country+3708)` 槽表); 
qword_14332F698 = 引擎管理器单例 (+1264 → +368 纹理库, +1744 战略区管理); qword_14332F6A0 =
输入/order 管理器单例 (vt+200 = 鼠标悬停 order, order+464 = 链头); qword_14332F5A8+F5B4 =
已发射事件史 {data, count@+12}; qword_14332F5C0+F5CC = 外交行动史同构。

未决: 注册器 383 条完整表抽取 (全名+别名+描述+dev 旗) 留后续任务 (方法已验证, 脚本
archive/m14_decomp/df135_namemap.py / df135_registrar.py); 1425A0010 间接调用通道;
damage_units 第二单位容器军种分工; 140232CD0 七调用命令注册名; 命令条目栈临时 (288B) 与
运行时条目 (456B 跨距) 拷贝通路。
