

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
| +8 | 容器 24B | pinned_strategic_regions | 未实现 | {data@+8, cap@+16, count@+20, alloc@+24}; u32 列表; writer 块 12506 (有 writer 无提取) |
| +20 | uint32 | pinned_strategic_regions 计数 | 未实现 | |
| +32 | MSVC SSO 32B | user | | 引号 (账号名); size@+48 |
| +64 | MSVC SSO 32B | 玩家显示名 | | "X controls Y" 通告构建器读 +64: sub_140CEEA30 与 gs 同步点 5231331 两处同构; 高置信 |
| +96 | SProfileBadge (内嵌 16B) | 档案徽章 | | {vt@+96, u32@+104, u32@+108}; CAddPlayerCommand 复制源同位; 定案 |
| +112 | uint32 | tag | | = 国 idx |
| +120 | CGameDate (内嵌 24B) | 日期 | | {vt1@+120, hours@+128, vt2@+136}; ctor/copy ctor 三元组; 高置信: MP 加入/就绪时刻候选 (探针: 本档 hours=43808760 未设哨兵, 相容候选; 单机无法终验) |
| +144 | uint32 | — | | **死字段** (保留/对齐槽): 三个 ctor 全置 0, copy ctor 逐值拷贝, 全 dump 零非零写者 + 零读者; 与邻 +148/+152 无联合语义 |
| +148 | uint8 | 标志位 | 恒写 | bit0 = country_leader (writer `&1 → yes/no`); slot4 sub_140BBC7F0 `^= &1` 翻转 |
| +152 | int32 | id | ≠-1/0xFFFFFFFF 才写 | |

注: ⚠ +136 是 +120 同一日期的 vt2, 非第二日期。
注: +148 ctor 值 = 9 = 0b1001 (bit0 = country_leader 默认 1 + bit3 = 1); ctor2 在 a6≠0 时置 11 = 0b1011 (再置 bit1)。**序列化只走 bit0** (writer `*(a1+148) & 1`; reader 只 XOR bit0 保留其余位) → **bit1/bit3 为无消费者的运行时保留旗** (全 dump 零掩码读; 业务名无锚 — 未决)。

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
| +8 | u32 | 硬编码 id (非 token; 与 §4.26 规格表同款双证) |
| +24 | MSVC 串 | 名 key 串 (tooltip 走 DB+40 loc 表) |
| +56 | u32 | **非序列化 config 字段** (真名未决) — **非 tier 数**: tier 槽为固定 3 个内嵌 88B 对象 @+296/+384/+472 (reader 由 bronze/silver/gold 三键直写), tier 数 = 编译期 3, 不依赖 +56; def reader 无 +56 case, 值由 def ctor 从 token 流读入 |
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
| CMedalPickerItem / CRibbonPickerItem | CAwardDisplay::ToggleMedalPicker / ToggleRibbonPicker → sub_141FA7560 / 141F92ED0 | a4 = CCareerProfileMedal::CTierColors (u32@a4+8 = tier); 图标 sub_141E92E70 / 141E7E210 按 tier 着色 |
| CMedalPopupWindow / CRibbonPopupWindow | 基 = NCareerProfile::CBasePopupWindow (0x5E0B) | **win+1496/+1500 = {成就 id, tier}** 工厂一次性 qword 写入 (ribbon 仅 id/tier 恒 1); [6]SetupContent sub_1419C4580 / 1419B1620 → **CMedalDatabase 0x14332EE30 / CRibbonDatabase 0x14332EE48** = career_medal / career_ribbon DB 运行时址; **win+112 = Show 时间戳**, Update 超时两级 define = **dword_1433374B8 隐内容 / dword_1433373FC 关窗**; 源断言 career_profile\medal_and_ribbon_popup_window.cpp |

弹窗队列管理器 = CGameGui+2560; 帧消费 sub_140DD3A50 → sub_1419C5390 三分支:

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

**CMessageTypeSettings** (消息开关寄存器, 16B; vt 0x1429D8F40; writer 0x141578A80 / reader 0x141578810; 单例 0x332EF60): +8 u8=1 / **+12 u32 五路开关位掩码: bit0=onmap(10677) / bit1=log(10676) / bit2=popup(10678) / bit3=pausepopup(11064) / bit4=icon(181)** (writer 逐位 unmask, reader OR 逐位置位)。玩家消息路由被持久化 (存档实写)。

**聊天/大厅持久件族 (MP 会话元数据域)**: **CChatMessage** 基 (vt 0x1422E77D0; +8 message CString) → CStandardChatMessage (0x1422E7930, +48 user) / CPersonalChatMessage (0x1422E78A0, +48 alluserlist / +56 user / +88 userslist 链) / CCountryChatMessage (0x1422E77F0, 再 +112 id / +120 name) / CSystemMessage (0x1422E7980, +48 key_value_pairs 串对向量 stride 64)。**CChatMessageObservable** (持久槽异位: [6]=Save / [7]=writer 0x14226A110 / [8]=Load / [9]=reader 0x142269E60 — serfam [2]/[4] 指纹盲区实例): 写 default_state (499) 打包记录 {+12 u32 / +22 u16 / +24 u8 / +28 u32 / +32 u32} + object (65) 历史块; ⚠ [7]/[9] 与 §4.00.7 CCommand 家族共享 writer/reader **同址** — 数据语义按 chat 上下文读, 非命令对象。**CGameLobby / CLargefileHandler / CLargefileHandlerInterface** (三类共享 writer 0x142220340 / reader 0x14221FC10): 本体 = CID 对 {+8 u32 type(225), +12 u32 id(11)}, 落 `id = { … }` 块 (大厅/会话元数据, 高置信)。**CPdxSocialPlayerId** (vt 0x142969418; writer 0x142401C80 / reader 0x142401250): +8 u32 id / +24 平台→u64 RH 表 (stride 40), 键 765 pops_id / 767 msgr_id / 374 steam_id。

#### 4.28.11 CSettings / CSystemSettings (settings.txt 总表; 双向往返)

**CSystemSettings** (基类子对象 @CSettings+0; vt 0x142B3B9A0; writer 0x14222B100 / reader 0x14222AE20; Reset 0x14222A440): +152 graphics → CGraphicsSettings\* (193; refreshRate 在此类内, 与本类分开取) / +160 language (187) / +192 master_volume (237, 100.0) / +196 dev_master_volume (586, 50.0) / +200 sound_fx_volume (231) / +204 music_volume (232, 75.0) / +208 ambient_volume (322, 50.0) / +212 voice_volume (740) / +216 scroll_speed (233, 50.0; CSettings::Reset 覆盖 22.0) / +220 corner_scrolling (800) / +224 camera_rotation_speed (234) / +228 zoom_speed (235) / +232 mouse_speed (236) / +237 graceful_exit (736, 仅真值落盘) / +238 minimap_visible (741) / +304 last_game_version (747)。f32 写原语 0x1424C3100 (值走 xmm0)。

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
| +560 | f32 | windowmovetime (10277) |
| +564 | f32 | radialstaytime (10278; **reader 有 writer 不写 = 只读残留**) |
| +568 | u8 | hints (10282) |
| +572 | f32 | camera_speed (669, 钳 [5.0,95.0]) |
| +576 | f32 | camera_tilt (671, 钳 [5.0,100.0]) |
| +580 | u8 | centered_zoom_in (670) |
| +588 | u8 | outliner_open (10276) |
| +589 | u8 | autosave_tocloud (11574) |
| +590 | u8 | save_career_to_cloud (15954) |
| +591 | u8 | skip_setup (12627) |
| +592 | u8 | force_pow2_textures (11029; 读入触发纹理重载) |
| +594 | u8 | hide_daynight_cycle (13731, 仅真值落盘) |
| +596 | u8 | show_allied_plans (13732, 仅真值落盘) |
| +597 | u8 | use_ingame_browser (13779) |
| +598 | u8 | default_offline_wiki (13892) |
| +599 | u8 | save_as_binary (13827) |
| +600 | u8 | pause_on_popups (13917) |
| +601 | u8 | popup_news (14387) |
| +602 | u8 | popup_events (14388) |
| +603 | u8 | popup_minor_events (12940) |
| +606 | u8 | show_game_status (15427) |
| +607 | u8 | awards_message_seen (16003) |
| +608 | u8 | use_silhouette_portraits (19533) |
| +609 | u8 | strategic_regions (12013) |
| +610 | u8 | lockable (285) |
| +611 | u8 | telemetry_enabled (10324) |
| +612 | u8 | event_sounds (12840) |
| +616 | u32 | combat_sound_random (11051) |
| +620 | u32 | max_players (11053) |
| +624 | u8 | show_doctrine_details (16746) |
| +632 | 匿名结构 (32B 形状) 向量 | save_date 历史 {d@632, c@644}, 32B 条, 逐条 token 13503 |
| +656 | 匿名结构 (元素待裁) 向量 | shown_legal_documents (15236) |
| +680 | u32 | counter_color_mode (13446, 钳 [0,1]) |
| +684 | u32 | template_counter (13549, 钳 [0,1]) |
| +688 | uint32 向量 | custom_mapmodes {d@688, c@700}, u32 条 |
| +712 | 匿名结构 (元素待裁) 向量 | sub_messages_seen (15929) |
| +736 | i64 | time_last_sub_message (15930) |
| +744 | u8 列表容器 | 键 593 (名与语义不符, 待裁) |
| +768 | 串块容器 | 键 156 (同上待裁) |
| +792 | u8 | is_always_aprils_fools (15029, 仅真值落盘) |
| +800 | scoped_ptr<匿名结构 (8B 形状)> | **game_rules 数据对象 (15202 块)**, 元素 8B {u32,u32} 对; +808 = 已载入旗; 相关全局 qword_14332EF20 |
| +896 | 匿名结构 (NNB 形状) | cvaa_settings (19674) |
| +952 | f64 | hotkey_activation_delay (19681) |
| +960 | f64 | hotkey_actualization_delay (19682) |

读侧忽略残留: 10259 outliner / 10535 interval / 10655 difficulty / 11537 last_dlcs / 11540 last_mods / 15944 playthrough_stats_highlights。安全区事故排查: autosave 在 +552 (枚举 int); refreshRate 在 CGraphicsSettings (vt 0x142B3B700, CSystemSettings+152 指针, writer 0x142229D60) — 两处分开取。

**CMapRenderingOptions** (mapRenderingOptions 块本体 = CSettings+376 内嵌子对象, 32B; vt 0x1427243C8 9 槽; 基 CPersistent; writer 0x1401FC580 / reader 0x1401FAE80; **settings.txt 域, 不入 savegame** — savefull 导出 draw_*/texture_quality 零命中负证): 落盘序 = 偏移升序。布局:

| 偏移 | 类型 | 键 (token) | 容器 ctor 默认 |
|---|---|---|---|
| +8 | u8 | draw_terrain (10262) | 1 |
| +9 | u8 | draw_water (10263) | 1 |
| +10 | u8 | draw_borders (10264) | 1 |
| +11 | u8 | draw_trees (10265) | 1 |
| +12 | u8 | draw_rivers (10266) | 1 |
| +13 | u8 | draw_postfx (10267) | 1 |
| +14 | u8 | draw_sky (10268) | 1 |
| +15 | u8 | draw_bloom (10269) | 1 |
| +16 | u8 | draw_tooltips (10270) | 1 |
| +17 | u8 | draw_hires_terrain (10271) | 1 |
| +18 | u8 | draw_citysprawl (10272) | 0 |
| +19 | u8 | draw_shadows (10273) | 1 |
| +20 | u8 | draw_weather_effects (13972) | 1 |
| +21 | u8 | draw_water_reflections (13973) | 1 |
| +22 | u8 | draw_units (13975) | 1 |
| +23 | u8 | draw_buildings (13976) | 1 |
| +24 | u8 | high_gfx_shaders (13977) | 1 |
| +25 | u8 | draw_map_full_res (13978) | 1 |
| +28 | u32 | texture_quality (13974) | 0 |

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
| SetSeed(int) | 0x142234550 | 单 int 哈希派生 seed+count 双字段 (公式闭环验证: 传 123456 → 运行时 seed/count 逐位吻合); 调用者 = 控制台 **`random_seed <int>`** 命令 (ConsoleCmdImpl.cpp, 回显 "Random set to: N"; **无 debug 门, 无 debug 会话实测可用**) + 会话启动随机化分支 (0x141CD9D80, 新开局播种); ⚠ 同族不存在名为 `random` 的命令 |
| 全局流入口 | 0x142233FA0 | random_int(file, line) — file/line 仅调试记账; 191 调用点 / 55 源文件: country 28 / airmission 13 / navalmission 10 / peaceconference 8 / state 8 / combatland 7 / nuke 5 / diplomacy 5 / army 4 / politics 3 / civilwar 1 … |
| 作用域流 | 同 hash 内联 200+ 函数 | 实例版 CRandom (对象内嵌 {count seed}) |

每作用域流 = 各对象 variables 块内 `random={count seed}` (单档 14,828 对: character 13,259 + 国家 GER 421 / ITA 207 … + 州): **作用域隔离的确定性流**, 本作用域抽随机不推进其他作用域的序列。改全局 seed/count = 重掷全部全局流后续抽取 (weather 每省每小时最先受影响, AI 判定/战斗/和会/核弹路径全部重掷, 实测与重放微扰同型且随时长混沌放大); 改某作用域对 = 只重掷该作用域。

| 停表对拍窗口 | 全量导出 DIFF+MISS | 结论 |
|---|---|---|
| +0h (同刻暂停态) | 0 / 2,833,399 MATCH | 读档+导出管线位级确定 |
| +48h 重放 vs 改种子 | ≈8.3 万 ≈ 8.5 万叶, 同型分布 | 改种子 = 与重放微扰同量级的流重掷 |
| +480h | ≈21 万叶 | 散布随时长混沌放大 |


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
| +1328 | 指针 | **idler 管理器 = CApplication 本体** (字段: +56 current / +112 待入 / +120 旧 / +64 切换请求旗 / +128 保留旗) | SetIdler = sub_14222EA60 |
| +1512 | vptr | 子对象 C 表 (0x1429693D0) | |
| +1520 | vptr | 子对象 D 表 (0x1429693F0) | ctor 装 "interface/main.gui" 串 |
| +1720 | 指针 | **iface = CInGameInterface\*** (§4.30 主视图; s4_17 定案同址) | 其内含六节拍注册表 (年/5月/月/周/日/时 分档, 查询槽[64] 过滤 → 分档执行槽驱动窗口刷新) |
| +1728 | u8 | toggle 置位旗 (slot[94] 体写 1) | §1.1b.1 |
| +1729 | u8 | 暂停权威位 (1=冻结) | §1.1b.1 全表 |
| +1731 | u8 | 连按 pending 伴随位 | §1.1b.1 全表 |
| +1732 | u8 | Idle 内第二暂停门 (CInGameIdler::Idle 0x140DD3A50 体: `帧耗时 && !+1729 && !+1732` 才调时间调度器) | 与 +1731 (toggle pending) 并存勿混 |
| +2216 | u32 | **GUI 小时脉冲倒计时** (节拍槽[64] 用) | |
| +2396 | u32 | **加速脉冲计数** (时间加成 min(2.0, 1+0.2×计数); 每 tick 生成后 sub_140DE4DE0 减 1, clamp 0) | §4.2.2 |
| +2400 | 容器 | 教程章向量 (§4.28.15 族) | |
| +2424 | 容器 | hint 向量 (§4.28.15 族) | |
| +2448 | 内嵌 | CTutorialMinimized (§4.28.15 族) | |

**驱动契约** (定案): Idle = 0x140DD3A50 (基类 CGameIdler 槽[4] 覆写; 每帧经
管理器派发, §4.2.1); **OnEnter = 0x140DE0150 (jmp thunk → setterB sub_1402A2A30:
qword_14332F698 = qword_14332F6A0 = this)** — 前端 CFrontEndIdler::OnEnter
(sub_140B3E1F0) 只写 F698, F6A0=0 → 时间调度器空操 = 「在游戏中」判据根源;
构造 = malloc 0xB30 (游戏开局 sub_140B3E9A0 尾) / 前端 = malloc 0x640
(InitGame sub_1401835A0); 前端 ctor sub_140B3B290。

**六节拍槽 64-69** (主表 0x142968FF0; GUI 侧脉冲, 详行为注记 §4.2.4 步骤 15):

| 槽 | 字节偏移 | 函数 | 语义 |
|---|---|---|---|
| [64] | +512 | 0x140DDA020 | 每小时: GUI 日期脉冲 + idler+2216 倒计时 / idler+1680 旗 |
| [65] | +520 | 0x140DD9740 | 日: gs 四连到期清扫 + GUI 日刷 + 游戏条目日期激活 |
| [66] | +528 | 0x140DDAC60 | 周: GUI 周脉冲 + 超 100MiB 日志轮转 (filelogger.cpp:256, 备份 6) |
| [67] | +536 | 0x140DDA1B0 | 月: 月脉冲 + GUI 大刷新 |
| [68] | +544 | 0x140DD9FF0 | 每年 5 月 (month==5) |
| [69] | +552 | 0x140DDACC0 | 年 |

#### 4.28.15 教程目标族 (CTutorialObjective 系; 非 trigger/effect, 会话级不入档)

基 = **CTutorialObjective** (抽象基, 无自身实测虚表, 88B 骨架; 工厂 0x1419CA5C0 按名串构造): +8 宿主教程管理器反指 / +16 textbox 键的串值 (7 字串逐字比对 "text"+"bo"+"x", 非 lexer token) / +48 loc 显示文本 / **+80 done 旗** (达成置 1 并广播 "tutorial_objective_done" 经 qword_14332F6A0 槽[31])。公共槽: [3] = 文本 Load 0x1419CA2D0 / [9] = **逐类判定函数** (唯一行为差异点)。

| 类 | vt | 工厂名 | [9] 判定 | loc 键 |
|---|---|---|---|---|
| CUseMilFac | 0x142A27BC8 | use_mil_fac | 0x1419D2CF0: 剩余可用军工 = (*(cc+3944 体 +888)/100000 − +944 − +920) == 0 → done | TUT_MIL_FAC |
| CUseCivFac | 0x142A27C28 | use_civ_fac | 0x1419D2780: 同构 (民用厂域量) | TUT_CIV_FAC |
| CUseNavDock | 0x142A27CE8 | use_nav_dock | 0x1419D3260: 同构 (船坞域量) | TUT_NAV_DOCK |
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

**CTriggeredText** (条件触发文本, 128B; vt 0x142999B98; writer=CFG 不入档; reader 0x141180E60): +8 文本键 (143 text / 220 key) / +40 CAndTrigger 内嵌 88B (10595)。

#### 4.28.11 CSession (clausewitz 会话对象; 时序通道与状态机)

CSession = clausewitzlib session.cpp 会话对象 (单机实例 = CDummyServer 挂 CServer
基 0x142B52AC8, 派生 0x142B52C28; 联机 CNetworkServer 0x142B53020 / CProxyServer
0x142B53598)。实例获取通道 = idler 虚表槽[17] 读对象+896 (§4.2.1)。命令管线
(发送 sub_142250B00 / 派发循环 sub_142252D00) 与 CHourlyTickCommand::Execute 的
状态门行为契约归 §4.2.3; 本节收布局与状态域。

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +72 | u32 | **联机状态机** (SetState session.cpp:269; 读者 sub_140CE9520) | 定案 |
| +84 | u8 | **游戏已开始门** (Execute 侧过滤; 非零才做掉线遍历) | 定案 |
| +128 | u32 | **会话 tick 号** — 发送侧 `min(session+128, 0x7FFF)` 盖命令 cmd+22 | 定案 |
| +164 | u32 | 玩家 id — 发送侧写命令 cmd+12 | 定案 |
| +1852 | u8 | 命令派发重入门 ("Update within execution. Skipping." session.cpp:600/629) | 定案 |
| +1941 | u8 | 入队即时/本地门之一 (sub_142250B00 三条件) | 定案 |
| +1968 | u8 | 派发循环状态辅助旗 (置 0 触发观察者广播 3) | 定案 |
| +1969 | u8 | 派发循环分支判定旗 | 定案 |

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
