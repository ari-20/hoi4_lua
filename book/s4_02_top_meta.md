
> 覆盖行（无独立残留）= 该偏移区无独立字段残留, 已由本册其他各节展开覆盖, 行仅作区界占位。

### 4.2 会话元数据簇 (top_meta)

**获取**: gs 直接偏移。**语义**: 存档头部元数据, 大多为写档时生成。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +152 | 混合 | 存档元数据 | checksum/version/dlcs/save_version 等 | 不做值级对拍 (用户裁定) |
| +153..+191 | — | = **CPersistent 基类子对象中段** (ctor sub_140BC0880): 日期#0 {hours@152, vt2@160} 尾 + **player_countries {d@168, cap@176, c@180, alloc@184}** (块 13671, 元素 160B) — 该区即 CPersistent 基类成员中段 |  | |
| +192 | 混合 | 难度/玩家 | | |
| +193..+467 | — | = CPersistent 尾段 {位域@192 (bit0=checksum 门 / bit3=tutorial), null-object 句柄@200, 容器B@216, 标志@240, scoped@248} + **CHuman@272 (160B)** + **CDedicatedServer@432 (156B, 名串 "Dedicated server")** |  | |
| +468 | — | = CDedicatedServer 名串 (gs+464, "Dedicated server") 堆指针的高 dword (随 ASLR 变); 存档真值 multiplayer_random_count 来自静态 dword_143452520 (键 11459) |  | |
| +469..+1191 | — | = CDedicatedServer 尾 + pad → gs+600; gs+600..+1191 中段全数定案见 §4.1 (CFlagManager@600 / CCombatManager@608..683 / 省州区国四数组 / tag 表 / 按国家数组 / RH map@952 / 第 7 管理器@1032 / u32 对列表@1040 / difficulty_setting@1064 / game_rules@1088 / entity@1096 / power_balance@1104 / date@1120 / CGameDate#2@1184)  |  | |
| +1192 | — | 玩家相关 | | |
| +1193..+1311 | — | = speed@1212 (键 110) + to_be_deleted@1224 (块 19332) + CPeaceConferenceManager@1248 (块 12499) + 串@1280 (探针空, 语义未名)  |  | |
| +1312 | — | playthrough 统计 字段 1 | ||
| +1320 | — | playthrough 统计 字段 2 | ||
| +1321..+1583 | — | = playthrough 三元组@1312/1316/1320 (键 10805/13913; 探针 121/0/9) + fired_event_names 桶头@1336..1351 (桶数@1340=511, ptr@1344=malloc(0xFF8)) + pdx@1352 + pending_events@1376 (块 13801, 元素 56B) + pdx@1400 + sunk_ship@1424 + sunk_convoys@1448 + 指针数组@1472 (键 13564, = **海战结果主数组**) + **A@1496 = CNavalCombatResults\* 按区域 id 索引 RH 表** (72B; 键 = results+264)  |  | |
| +1584 | — | 会话计数 字段 1 | ||
| +1585..+1831 | — | = 难度枚举@1584 (键 10655; 探针=2; ⚠ 勿与 gs+1064 difficulty_settings 块 13999 混同) + gameplaysettings@1576 + CArmy* 数组@1600 (探针 37 项) + selection-groups 容器@1624 (每国 240B 组集, 块 10286) + pdx@1648 (空) + CWorldThreat@1712 (键 11261) + saved_event_target@1728 (元素 112B) + pdx@1752 + division_templates@1776 + equipment@1800 + game_unique_seed@1824  |  | |
| +1832 | — | 会话计数 字段 2 | ||
| +1833..+2167 | — | = game_unique_id 串体 {size@1848, cap@1856} + land/navy combat id@1864/1868 + CNonstaticIdGenerator 五连@1872..1951 + CIdCounterStore@1952 (双子容器@1960/@1984) + 未命名 152B@2008..2159 + 残渣@2160..2167  |  | |
| +2168 | — | 会话计数 字段 3 | ||
| +2169..+2231 | — | = average_major_ic u64@2168 (键 13885, AE590 通道) + logmgr@2176..2199 + all_playthrough_data RH map@2200 (门 u32@2216; 探针 gate=1/mask=7/dm=5/lf=0.9) + statistics byte@2232  |  | |
| +2232 | — | 会话计数 字段 4 | ||

⚠ token 防混: threat@gs+1712 = 11261 / CVariables@gs+2432 = 10826 /
region 块 = 10827。

#### 4.2.1 顶格 # 叶 writer 族

| writer | VA | 覆盖范围 |
|---|---|---|
| sub_140BC2710 | 0X140BC2710 | 存档头元数据族 (键表见下) |
| sub_1401F2E40 | 0X1401F2E40 | 会话计数 / id / 静态计数族 (键表见下) |
| sub_1401F2DD0 | 0X1401F2DD0 | all_playthrough_data 块 + statistics_collection_enabled u8@gs+2232 |

覆盖键 (偏移相对其 a1/a3):

| writer | 键 | 挂载/来源 |
|---|---|---|
| sub_140BC2710 | player | — |
| sub_140BC2710 | ideology | 裸串 |
| sub_140BC2710 | date | a3+1136 (24B 对象基 = a3+1120 {vt1@+1120, hours@+1128, vt2@+1136 = 序列化指针}) |
| sub_140BC2710 | difficulty (enum) | a3+1584 |
| sub_140BC2710 | version | — |
| sub_140BC2710 | tutorial | bit3@a1+176 |
| sub_140BC2710 | dlcs | 块 |
| sub_140BC2710 | save_version | dword_143335FEC |
| sub_140BC2710 | minor | dword_143336080 |
| sub_1401F2E40 | next_trade_route_update_country_idx | a1+2496 |
| sub_1401F2E40 | cached_active_trade_route_count | a1+2492 |
| sub_1401F2E40 | speed | a1+1212 |
| sub_1401F2E40 | game_unique_seed | a1+1824 |
| sub_1401F2E40 | game_unique_id | SSO@a1+1832 |
| sub_1401F2E40 | navy_id | u32@a1+1868 |
| sub_1401F2E40 | land_combat_id | u32@a1+1864 |
| sub_1401F2E40 | multiplayer_random_seed | 静态 dword_143452524 |
| sub_1401F2E40 | multiplayer_random_count (有符号) | 静态 dword_143452520 |
| sub_1401F2E40 | debug_current_ref_id | 静态 dword_1434520E0 |
| sub_1401F2E40 | unit | 静态 dword_14308725C |
| sub_1401F2E40 | theater_group_index | sub_1406EE850 |
| sub_1401F2E40 | military_deployment_line_index | sub_140CE9540 |
| sub_1401F2E40 | conveyor_index | sub_140BD9220 |
| sub_1401F2E40 | equipment_variant_index | sub_140BD9220 |
| sub_1401F2E40 | country_leader_index | dword_1430B12D0 |
| sub_1401F2DD0 | all_playthrough_data | 块 (§4.2.3) |
| sub_1401F2DD0 | statistics_collection_enabled | u8@gs+2232 |

值级对拍豁免:

| 键 | 豁免原因 |
|---|---|
| checksum / version / dlcs | 写盘时生成 |
| session / seconds_played | 墙钟秒 (用户裁定追加豁免) |

#### 4.2.2 #.id 叶

writer sub_1401F2E40 中段填充 4711 项缓冲 (type = 4712+i):

| 步 | 操作 |
|---|---|
| 1 | 经 sub_14221EF70 填充 4711 项缓冲 (type = 4712+i) |
| 2 | 缓冲 = **三注册表源逐桶 max(HIDWORD(value)) 合并** (纯 max, 无 +1) |
| 3 | `id≠0` 才写 (sub_142220260) |
| 4 | 写序 = type 升序, 仅 max≠0 出叶 |

三注册表源:

| 源 | 形态 | 基址 |
|---|---|---|
| ① | RH map | BASE+54758992 |
| ② | RH map | BASE+54759000 |
| ③ | map 对象指针数组 — **8B 步进 ×100 槽** (dump 原文 `v17 += 2` dword 对; 终界 &dword_1434520E0 = debug_current_ref_id) | BASE+54759008 |

RH map 布局:

| 偏移 | 类型 | 内容 |
|---|---|---|
| +8 | RH 桶数组* | buckets |
| +9..+19 | — | = {残渣@+9..+15, **计数/写出门 u32@+16**} — RH map 头 32B 全形 = {残渣@0..7, buckets@8, **计数@16**, mask@20, distmax@24, 残渣@25..27, **lf f32@28=0.9**} (实例探针: gs+952 计数 62/128 桶; gs+2200 gate=1/7 桶) |
| +20 | uint32 | **mask** (⚠ +40 处为 hash seed, 非门) |
| +24 | uint8 | distmax |

桶 24B:

| 偏移 | 类型 | 内容 |
|---|---|---|
| +4 | uint8 | dist |
| +16 | 匿名结构 (NNB 形状) | value ptr (vp) → value = u64@vp+8 = (id<<32)\|type (读法拆双 u32: lo=type@vp+8, hi=id@vp+12) |

⚠ 同址易混: gs+1960 = 另组计数器 (type=84 id=447), 非本表; gs+2520 =
ships_built RB-tree 同址 (节点 {船型 token@+28, 数 u32@+32}), 非本表;
+40 处 dword = hash seed, 非计数门。

#### 4.2.3 all_playthrough_data (gs+2200)

块门 = u32@(gs+2216) ≠ 0 (writer 0X1401F2DD0)。

RH map (gs 侧):

| gs 偏移 | 类型 | 内容 |
|---|---|---|
| +2208 | RH 桶数组* | buckets = rp(gs+2208) |
| +2209..+2219 | — | = RH map 内部 {计数尾, mask u32@+2220 = 7, distmax u8@+2224 = 5} — gate u32@2216 = 1, lf f32@2228 = 0.9  |
| +2220 | uint32 | mask = ru32(gs+2220) |
| +2224 | uint8 | distmax = ru8(gs+2224) |

桶 24B:

| 偏移 | 类型 | 内容 |
|---|---|---|
| +4 | uint8 | dist (0=空; **0xFE=墓碑也须跳** — 残留墓碑桶误收会多发叶) |
| +8 | uint32 | key = tag id |
| +16 | 匿名结构 (NNB 形状) | value ptr |

**写序 = key (tag id) 升序** (writer sub_1401B3900 收集后经 sub_1401B6990
sort; key 写门 tid>0 → 引号三字串)。

#### 4.2.4 NCareerProfile::SPlaythroughCountryData (wrapper)

| 项 | 值 |
|---|---|
| 类名 | NCareerProfile::SPlaythroughCountryData |
| vtable RVA | 0x142721478 |
| 挂载 | all_playthrough_data RH map 桶值对象 |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | SProfileData (2056B) | data = {vt@+8, first SCareerProfileCountryData@+16 (1008B), second@+1024, tag MSVC-SSO@+2032} | tag **空串也写 `""`** (恒引号) |
| +9..+2063 | — | （覆盖行， 无独立残留） |  |
| +2064 | 384B | intermediate_statistics (writer 0X1406AA260) | §4.2.5 |
| +2065..+2447 | — | （覆盖行， 无独立残留） |  |
| +2448 | CFlagManager 内嵌 | flags | 块恒写 (count=0 空块无叶); §4.2.6 (布局 §4.13.3) |
| +2449..+2479 | — | （覆盖行， 无独立残留） |  |
| +2480 | uint8 | first_tag | → yes/no 恒写 |

#### 4.2.5 intermediate_statistics (wrapper+2064)

**9 个 CTimeSeries** (vt 0x1429ccb20) 连续内嵌 stride 40 (基址 interm =
wrapper+2064):

| 偏移 (interm) | 名称 |
|---|---|
| +8 | recent_offensive_battles |
| +48 | recent_defensive_battles |
| +88 | recent_spawned_divisions |
| +128 | recent_dropped_nukes |
| +168 | recent_provinces_gained |
| +208 | recent_provinces_lost |
| +248 | recent_shot_down_airplanes |
| +288 | recent_naval_invasion_divisions_transferred |
| +328 | last_month_convoys_sunk |

CTimeSeries 布局 (ctor sub_1414E5230, cap 24/24/48/12/48/48/48/96/30 —
条数以 count 为准):

| 偏移 | 类型 | 内容 |
|---|---|---|
| +0 | 8B | vt |
| +8 | uint32 | cap |
| +16 | 元素指针数组* | elem-ptr 数组 ptr |
| +17..+27 | — | = elem-ptr 数组指针 (+16..+23, 8B) 后 7B + pad 4B, 无独立字段 (通用形 {vt, cap@8, ptr@16, count@28}) |
| +28 | uint32 | count |

元素 = **u32 堆指针** (池化 int, kptr 校验后 deref; writer slot2
sub_1414E5840 逐 count 写)。尾部两标量 (各 malloc 4B 堆 int):

| 偏移 (interm) | 类型 | 名称 |
|---|---|---|
| +368 | uint32 | controlled_provinces = u32@rp(interm+368) |
| +376 | uint32 | province_gaining_weeks_intermediate = u32@rp(interm+376) |

#### 4.2.6 CFlagManager (wrapper+2448 内嵌)

career profile 侧 CFlagManager 宿主 (块恒写 count=0 空块无叶); 键走 token_name
(`career_profile_overrun_*_flag` 16025/16028 实证; ⚠ 勿裸用 SL.tok 数字回退)。
**类布局 (vtable 0X14295BB98 / writer 0X140CBFFC0 / 条目 CScriptFlag 48B 全字段) = §4.13.3 (权威, 勿重述)**。

#### 4.2.7 SCareerProfileCountryData (blob 164 键)

| 项 | 值 |
|---|---|
| 类名 | SCareerProfileCountryData |
| sizeof | 1008B {vt@0, 字段@+8..} |
| writer | sub_1406A8DC0 — 硬编码 164 键序逐字段 (u32 = sub_1424C2A70 / i64 = sub_1424C3960) |
| parse | sub_14069F630 (144 对 token→偏移交叉一致) |
| 挂载 | wrapper data.first / data.second (blob) |

**164 键全表** (表序 = writer 硬编码键序 = 存档 blob 键序; 偏移相对 S,
u32 = ru32(S+偏移), i64 = rp_i64(S+偏移)):

  | # | 键 | token | 偏移 | 型 |
  |---|---|---|---|---|
  | 1 | playthroughs | 15915 | +8 | u32 |
  | 2 | most_factories_built | 15922 | +12 | u32 |
  | 3 | successful_coups | 15920 | +16 | u32 |
  | 4 | liberated_nations | 15919 | +20 | u32 |
  | 5 | sunk_pride_of_the_fleet | 15917 | +24 | u32 |
  | 6 | shot_aces | 15916 | +28 | u32 |
  | 7 | successful_operations | 15910 | +32 | u32 |
  | 8 | recruited_operatives | 15908 | +36 | u32 |
  | 9 | captured_operatives | 15907 | +40 | u32 |
  | 10 | designed_ships | 15901 | +44 | u32 |
  | 11 | sunk_convoys | 12418 | +48 | u32 |
  | 12 | hosted_governments | 15949 | +52 | u32 |
  | 13 | admiral_traits_unlocked | 15952 | +56 | u32 |
  | 14 | puppeted_countries | 15939 | +60 | u32 |
  | 15 | licensed_foreign_military_tech | 15940 | +64 | u32 |
  | 16 | fought_civil_wars | 15941 | +68 | u32 |
  | 17 | general_traits_unlocked | 15945 | +72 | u32 |
  | 18 | designed_tanks | 15911 | +76 | u32 |
  | 19 | battles_against_encircled | 15979 | +80 | u32 |
  | 20 | battles_with_air_support | 15980 | +84 | u32 |
  | 21 | provinces_gained | 16034 | +88 | u32 |
  | 22 | provinces_lost | 16035 | +92 | u32 |
  | 23 | defensive_victories | 15958 | +96 | u32 |
  | 24 | forts_with_max_defense_defeated | 15976 | +100 | u32 |
  | 25 | destroyed_encircled_divisions | 15971 | +104 | u32 |
  | 26 | designed_planes | 16061 | +108 | u32 |
  | 27 | mussolini_missions | 16062 | +112 | u32 |
  | 28 | field_officers_promoted | 16060 | +116 | u32 |
  | 29 | ships_sunk_by_maritime | 16064 | +120 | u32 |
  | 30 | decrypted_ciphers | 16094 | +124 | u32 |
  | 31 | civilian_factories_built_1936 | 16068 | +128 | u32 |
  | 32 | civilian_factories_built_1940 | 16069 | +132 | u32 |
  | 33 | civilian_factories_built_1945 | 16070 | +136 | u32 |
  | 34 | military_factories_built_1936 | 16071 | +140 | u32 |
  | 35 | military_factories_built_1940 | 16072 | +144 | u32 |
  | 36 | military_factories_built_1945 | 16073 | +148 | u32 |
  | 37 | dockyards_built_1936 | 16074 | +152 | u32 |
  | 38 | dockyards_built_1940 | 16075 | +156 | u32 |
  | 39 | dockyards_built_1945 | 16076 | +160 | u32 |
  | 40 | rocket_sites_built_1936 | 16077 | +164 | u32 |
  | 41 | rocket_sites_built_1940 | 16078 | +168 | u32 |
  | 42 | rocket_sites_built_1945 | 16079 | +172 | u32 |
  | 43 | embargoed_countries | 16082 | +176 | u32 |
  | 44 | special_force_doctrines | 16406 | +180 | u32 |
  | 45 | sp_finished_before_1946 | 11174 | +184 | u32 |
  | 46 | sp_completed | 16365 | +188 | u32 |
  | 47 | nuclear_raid_before_1944 | 13626 | +192 | u32 |
  | 48 | nuclear_raid_before_1945 | 13627 | +196 | u32 |
  | 49 | nuclear_raid_before_1946 | 11186 | +200 | u32 |
  | 50 | launched_raids | 16366 | +204 | u32 |
  | 51 | sp_techs_finished | 11194 | +208 | u32 |
  | 52 | plan_landlocked_naval_projects_finished | 11195 | +212 | u32 |
  | 53 | scientist_level_ups | 16367 | +216 | u32 |
  | 54 | faction_goals_completed | 16751 | +220 | u32 |
  | 55 | naval_headquarters_built | 16757 | +224 | u32 |
  | 56 | subdoctrines_mastered | 16758 | +228 | u32 |
  | 57 | faction_long_term_goals_completed | 16763 | +232 | u32 |
  | 58 | controlled_strategic_locations | 16760 | +236 | u32 |
  | 59 | special_forces_subdoctrines_mastered | 17350 | +240 | u32 |
  | 60 | captured_commanders | 17746 | +244 | u32 |
  | 61 | rescued_commanders | 17747 | +248 | u32 |
  | 62 | ship_captains_promoted | 19382 | +252 | u32 |
  | 63 | built_tanks | 15913 | +256 | u32 |
  | 64 | built_ships | 15912 | +260 | u32 |
  | 65 | vehicles_received_by_lease | 15937 | +264 | u32 |
  | 66 | vehicles_sent_by_lease | 15938 | +268 | u32 |
  | 67 | planes_sent_as_volunteer_force | 15946 | +272 | u32 |
  | 68 | built_railway_guns | 15948 | +276 | u32 |
  | 69 | converted_vehicles | 15950 | +280 | u32 |
  | 70 | captured_equipment | 15951 | +284 | u32 |
  | 71 | deployed_cavalry_battalions | 16106 | +288 | u32 |
  | 72 | mio_size_ups | 16200 | +292 | u32 |
  | 73 | special_forces_deployed | 16214 | +296 | u32 |
  | 74 | equipment_sold | 16222 | +300 | u32 |
  | 75 | economic_capacity_exchanged | 16240 | +304 | u32 |
  | 76 | mobile_warfare_xp | 16096 | +308 | u32 |
  | 77 | superior_firepower_xp | 16097 | +312 | u32 |
  | 78 | grand_battleplan_xp | 16098 | +316 | u32 |
  | 79 | mass_assault_xp | 16099 | +320 | u32 |
  | 80 | fleet_in_being_xp | 16100 | +324 | u32 |
  | 81 | trade_interdiction_xp | 16101 | +328 | u32 |
  | 82 | base_strike_xp | 16102 | +332 | u32 |
  | 83 | strategic_destruction_xp | 16103 | +336 | u32 |
  | 84 | battlefield_support_xp | 16104 | +340 | u32 |
  | 85 | operational_integrity_xp | 16105 | +344 | u32 |
  | 86 | mastery_gained | 16756 | +348 | u32 |
  | 87 | captured_generals_levels_counter | 17168 | +352 | u32 |
  | 88 | longest_battle_duration | 15934 | +356 | u32 |
  | 89 | largest_manpower_battle | 15935 | +360 | u32 |
  | 90 | largest_tanks_battle | 15928 | +364 | u32 |
  | 91 | largest_army | 15925 | +368 | u32 |
  | 92 | largest_navy | 15926 | +372 | u32 |
  | 93 | largest_airforce | 15927 | +376 | u32 |
  | 94 | highest_casualty_war | 15923 | +380 | u32 |
  | 95 | highest_enemy_casualty_war | 15909 | +384 | u32 |
  | 96 | paratrooper_divisions | 16015 | +388 | u32 |
  | 97 | naval_invasions | 16023 | +392 | u32 |
  | 98 | aircrafts_in_region | 16029 | +396 | u32 |
  | 99 | aces_in_airbase | 16033 | +400 | u32 |
  | 100 | defensive_bonus_achieved | 15964 | +404 | u32 |
  | 101 | planning_bonus_achieved | 15967 | +408 | u32 |
  | 102 | encircled_divisions | 15970 | +412 | u32 |
  | 103 | battle_affecting_modifiers | 15974 | +416 | u32 |
  | 104 | totally_controlled_naval_regions | 15981 | +420 | u32 |
  | 105 | veteran_units | 15983 | +424 | u32 |
  | 106 | max_air_supply_to_region | 15989 | +428 | u32 |
  | 107 | railway_gun_supported_combats | 15994 | +432 | u32 |
  | 108 | level_up_skills | 15996 | +436 | u32 |
  | 109 | mined_sea_regions | 16089 | +440 | u32 |
  | 110 | province_gaining_weeks | 16138 | +444 | u32 |
  | 111 | decrypting_days_saved | 16143 | +448 | u32 |
  | 112 | deployed_airplanes_with_air_defense_bronze | 16005 | +452 | u32 |
  | 113 | deployed_airplanes_with_air_defense_silver | 16007 | +456 | u32 |
  | 114 | deployed_airplanes_with_air_defense_gold | 16153 | +460 | u32 |
  | 115 | deployed_high_speed_tanks | 16010 | +464 | u32 |
  | 116 | deployed_tanks_with_armor_rating_bronze | 16149 | +468 | u32 |
  | 117 | deployed_tanks_with_armor_rating_silver | 16150 | +472 | u32 |
  | 118 | deployed_tanks_with_armor_rating_gold | 16151 | +476 | u32 |
  | 119 | sp_scientist_level_3 | 11189 | +480 | u32 |
  | 120 | sp_scientist_level_4 | 11190 | +484 | u32 |
  | 121 | sp_scientist_level_5 | 11191 | +488 | u32 |
  | 122 | plan_landlocked_light_hulls | 11196 | +492 | u32 |
  | 123 | plan_landlocked_cruiser | 11201 | +496 | u32 |
  | 124 | plan_landlocked_battleship | 11202 | +500 | u32 |
  | 125 | plan_landlocked_carrier | 11203 | +504 | u32 |
  | 126 | your_officers_leading_faction_theaters | 16759 | +508 | u32 |
  | 127 | faction_manifesto_fulfillment | 16761 | +512 | u32 |
  | 128 | ship_captain_skill_level | 17870 | +516 | u32 |
  | 129 | deployed_division_hq_ic_cost | 17285 | +520 | u32 |
  | 130 | game_months | 15932 | +524 | u32 |
  | 131 | seconds_played (**墙钟, 豁免**) | 15914 | +528 | u32 |
  | 132 | offensive_battles | 15956 | +532 | u32 |
  | 133 | defensive_battles | 15957 | +536 | u32 |
  | 134 | total_battles | 15969 | +540 | u32 |
  | 135 | hours_at_war | 16031 | +544 | u32 |
  | 136 | highest_casualty_civil_war | 15942 | +548 | u32 |
  | 137 | highest_enemy_casualty_civil_war | 15943 | +552 | u32 |
  | 138 | own_unknown_casualties | 16058 | +556 | u32 |
  | 139 | total_own_casualties | 16059 | +568 | i64 |
  | 140 | own_casualties | 16055 | +576 | i64 |
  | 141 | enemy_casualties | 16056 | +584 | i64 |
  | 142 | military_production_equipment | 16109 | +592 | i64 |
  | 143 | military_production_vehicles | 16110 | +600 | i64 |
  | 144 | military_production_air | 16111 | +608 | i64 |
  | 145 | air_production_fighter | 16112 | +616 | i64 |
  | 146 | air_production_interceptor | 16113 | +624 | i64 |
  | 147 | air_production_tactical_bomber | 16114 | +632 | i64 |
  | 148 | air_production_strategic_bomber | 16115 | +640 | i64 |
  | 149 | air_production_cas | 16116 | +648 | i64 |
  | 150 | air_production_naval_bomber | 16117 | +656 | i64 |
  | 151 | air_production_suicide | 16119 | +664 | i64 |
  | 152 | air_production_scout_plane | 16120 | +672 | i64 |
  | 153 | air_production_maritime_patrol_plane | 16121 | +680 | i64 |
  | 154 | tank_production_light | 16122 | +688 | i64 |
  | 155 | tank_production_medium | 16123 | +696 | i64 |
  | 156 | tank_production_heavy | 16124 | +704 | i64 |
  | 157 | tank_production_super_heavy | 16125 | +712 | i64 |
  | 158 | tank_production_modern | 16126 | +720 | i64 |
  | 159 | naval_production_submarine | 16127 | +728 | i64 |
  | 160 | naval_production_screen | 16128 | +736 | i64 |
  | 161 | naval_production_capital_ship | 16129 | +744 | i64 |
  | 162 | naval_production_carrier | 16130 | +752 | i64 |
  | 163 | bombed_trains | 15947 | +560 | u32 |
  | 164 | conquered_percentage | 15918 | +564 | u32 |

#### 4.2.8 结构尾部字段 (writer 同函数, 非 k=v 族)

| 字段 | token | 形态 | 备注 |
|---|---|---|---|
| produced_combat_widths | 16091 | **u32×52 @ S+776..S+983** | writer `for i=+776; i!=+984; ++i`; 块; 提取器折成 `@.#1` 空格行 |
| average_air_superiority | 16144 | i64×2 @ S+760/S+768 | +760 和, +768 计数 (`197811 266` 形) |
| new_bests | 15902 | **i64×3 @ S+984/S+992/S+1000** | 位集 |

blob 单叶格式 = `k=v` 空格连接 164 对 + 尾部 ` produced_combat_widths={`
(开括号无闭, 闭合在 @.#1 行后)。

⚠ i64 读出经 double: >2^53 非 2 幂位型 (new_bests 位集) 理论精度风险;
实测值精确 (2^61/2^33), `%.0f` 出数。

#### 4.2.9 提取路径/序号契约 (提取器形态实证)

| 路径模式 | 说明 |
|---|---|
| `#K.#1.data.first.playthroughs` | first 侧 4 叶: playthroughs / `.@.#1` / `.average_air_superiority` / `.new_bests.#1` |
| `#K.#1.data.second.<叶>` | 同 first 4 叶 |
| `#K.#1.data.tag` | 恒引号, 空串写 "" |
| `#K.#1.intermediate_statistics.<name>.#1` | 9 条 (名见 §4.2.5) |
| `controlled_provinces` | 带 " }" 尾 |
| `#K.#1.first_tag` | yes/no |
| `#K` | 外层 key 叶, 引号 tag, 序在最后 |

#### 4.2.10 S 偏移锚点

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | uint32 | playthroughs | 164 键首锚 (u32@+8 …) |
| +9..+527 | — | （覆盖行， 无独立残留） |  |
| +528 | uint32 | seconds_played | 墙钟豁免 |
| +529..+559 | — | （覆盖行， 无独立残留） |  |
| +560 | uint32 | bombed_trains |  |
| +561..+563 | — | （覆盖行， 无独立残留） |  |
| +564 | uint32 | conquered_percentage |  |
| +565..+567 | — | （覆盖行， 无独立残留） |  |
| +568..+752 | int64 | own_casualties 系 |  |
| +753..+759 | — | （覆盖行， 无独立残留） |  |
| +760 | int64 | average_air_superiority 和 | 结构尾部 |
| +768 | int64 | average_air_superiority 计数 | 结构尾部 |
| +769..+775 | — | （覆盖行， 无独立残留） |  |
| +776..+983 | uint32×52 | produced_combat_widths | 结构尾部 (writer 循环界 i≠+984) |
| +984 | int64 | new_bests 位 1 (位集) | 结构尾部 |
| +992 | int64 | new_bests 位 2 (位集) | 结构尾部 |
| +1000 | int64 | new_bests 位 3 (位集) | 结构尾部 |

#### 4.2.11 ships_built (造舰统计; gs+2520)

RB-tree (std::map 形态): head = *(gs+2520), 规模 = *(gs+2528) (≠0 门); 中序 = 写序; 0 值也写。
键 = 船型 token — 与 §4.2.3 all_playthrough_data 的 `designed_ships`(§4.2.5 第 10 键) 同族, 故不归海军战史 (§4.16.13/§4.16.15 收沉船总账与运输船月账)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | RB 节点* | l (left) |  |  |
| +8 | RB 节点* | p (parent) |  |  |
| +16 | RB 节点* | r (right) |  |  |
| +24 | uint8 | color |  | MSVC _Tree_node {left@0, parent@8, right@16, color u8@+24, isnil u8@+25} (定案) |
| +25 | uint8 | nil |  |  |
| +28 | uint32 | key |  | 船型 token |
| +32 | uint32 | value | 恒写 (0 值也写) |  |

⚠ gs+2520 与 session_meta #.id 同址撞车: gs+2520 实属本块, 见 §4.2.2。

#### 4.2.12 语义未决项

| 项 | 结论 | 证据 |
|---|---|---|
| gs+1032 槽 | **区域→(国家link×省) 二维字节查询表** (非管理器) | 无独立 RTTI 类 (负定案); InitGameState 尾 sub_1401E0610 就地构造; 访问器 sub_140E254B0 |
| 双生子 A (+1496) / B (+2280) | A = **CNavalCombatResults\* 按区域 id 索引 RH 表** (键 results+264; loader case 13564 `naval_combat_result`) / B = **cosmetic_tag 串 → CCountryColors\* 映射** (cosmetic.txt 解析器 sub_1401CCE90 填充) | 两对象同构 72B 但语义无关 |
| gs+952 RH map | **联合国策焦点 × 国家 连接表** (非 tech_sharing) | 键 = focus+88, 值 = CCountry\* 数组; 断言 gamestate.cpp:5057/:5072 |
| pdx 语义空位群 | 已名 12 项 (见 §4.1.3 表); **+2352 负定案 (gs 语境查无此槽)** | 逐个 ctor/消费者实证 |
| CPersistent 串1 (+16) / version 串 (+96) | 未决 — 无消费者与写入点 | — |
