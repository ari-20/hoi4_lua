

### 4.1 CGameState (游戏状态单例)

**获取**: `gs = *(BASE + 0X332F260)` (单例指针, 无 vtable 校验必要)。派生类 CCurrentGameState 见 §4.1.3。

#### 4.1.1 管理器字段 (+152..+2232; gs+0..+239 = CPersistent 基类, ctor sub_140BC0880, 详 §4.1.2)

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +152 | hours | 日期#0 **载入快照** | CGameDate 尾 {hours@152, vt2@160}; CPersistent 基类成员。**只有读档路径写, 之后不随时钟推进** (新建局停在 ctor 哨兵 43808760; 当前日期在 +1128) | §4.1.2 |
| +168 | 容器 24B | player_countries | {d@168, cap@176, c@180, alloc@184}; 元素 160B, tag@元素+112 | writer 头块 13671 |
| +192 | — | 位域旗 | bit0 = checksum 门 / bit3 = tutorial; 前有垫 | §4.1.2 |
| +200 | 匿名结构 (NNB 形状)* | null-object 句柄 | | |
| +216 | 容器 24B | **启用 mod 名列表** (MSVC 串 32B/元; {d@216, cap@224, c@228, alloc@232}; 元素 cap>15 走堆, 否则内联) | 序 = mod 加载序 |  |
| +240 | — | 标志 | | |
| +248 | 匿名结构 (NNB 形状)* | scoped | | |
| +272 | CHuman (内嵌 160B) | 人类玩家槽 | 共用布局: 名串@+32 / 二名串@+64 / badge@+96 / country-link id@+112 (sub_1401DA7C0 "country link index") / CGameDate@+120 / 枚举@+148 / 入参@+152 | |
| +432 | CDedicatedServer (内嵌 156B) | 专用服务器槽 | 派生 CHuman 布局, 名串 "Dedicated server" | |
| +464 | MSVC 串 32B | CDedicatedServer 名串 | 数据堆上, buf 槽 = 堆指针 | |
| +468 | — | 名串指针高 dword | ⚠ 勿当独立字段读 (ASLR 假阳性源) | |
| +469..+599 | — | pad | → gs+600 | |
| +600 | CFlagManager (内嵌 32B) | 旗管理 | | |
| +608 | CCombatManager (内嵌) | 战斗管理 | | §4.22; vt 0X2950688 存于槽自身 (非指针; 探针) |
| +616 | CCombat* | 战斗明细宿主 | 容器数据 {count@+628}; 元素主 vt 分流: CLandCombat 0X29A83D8 / CNavalCombat 0X29DDB08 / CLandBorderWarCombat 0X29BC5F0 | §4.22 |
| +617..+627 | — | 战斗明细容器尾 | = pdx 容器@616 {d@616, cap@624, c@628 高位} 内部 | |
| +628 | u32 | 战斗明细容器计数 | 战斗日志管理 (logmgr) = +2176/+2188 容器, 元素 NCombatLog::CManager (vt 0X295D8D8) | §4.22 |
| +629..+647 | — | 容器尾 | = {alloc@632 = 哨兵} + CCombatHistory 内嵌头@648 | |
| +648 | CCombatHistory (内嵌) | 战斗历史 | | §4.22; vt 0X2950638 (= CCombatManager+40) |
| +649..+687 | — | CCombatHistory 体 | = {q@656, q@664, u32@672, u8@676, u8@680, pad→683} + pad@684..687 — CCombatManager 全长 76B (+608..+683) | ctor sub_140BB66F0 |
| +688 | CProvince** | 省指针数组 | 省数 = uint32@+700 | §4.14 |
| +689..+711 | — | 省数组尾 | = {cap@696, count@700 已知, alloc@704} | |
| +712 | CState** | 州指针数组 | state_id 直查 | §4.13 |
| +713..+783 | — | 州数组尾 | = {cap@720, count@724, alloc@728} (assert "states", 块 11835) + region 数组 {d@736, cap@744, c@748, alloc@752} (assert "region", 块 10827, 自 id=1) + pdx@760..783 (语义未决) | |
| +784 | CCountry** | 国家指针数组 | 槽 0 = 哨兵; 数量 = uint32@+796 | §4.3 |
| +785..+855 | — | 国数组尾 | = {cap@792, count@796, alloc@800} + CCountry* 子集数组 {d@808, cap@816, c@820, alloc@824} (探针 21 项, 元素 vt=CCountry; 推定 major 子集) + country-link 表 {d@832, cap@840, c@844, alloc@848} ("country index→link index" 解析源; 探针 338/474) | |
| +832 | 匿名结构 (元素待裁) 向量 | **original-tag 恒等表** (identity[tag] 归一化表; sub_140BB52F0 同原初国判定与 sub_140BB5490 索引向底表 = 同容器双向读) | 多批互证 → 定案; elevations: 互主端只读点缀与「country index→link index」同容器 | 高置信 |
| +856 | char** | 国家标签串表 | 每项 32 字节 cstr; `tag = 表[tag_id]`。**count@+868 = 合法 tag_id 上界** (≠ 国家数见下注) | |
| +857..+983 | — | tag 串表尾 | = {cap@864, c@868, alloc@872} (探针 474/339; **count@868 是 tag_id 上界, 比 country_count 大** — 实测 339 vs 333) + 按国家数组 pdx@880 = `_CountryControllersEnable` / @904 = 控制器计数 (探针均 333/333=country_count) + tech_sharing 尾 {cap@936, c@940, alloc@944} + **RH map@952..983 = 联合国策焦点 (joint national focus) × 国家 连接表** (键 = focus+88, 值 = CCountry\* 数组; 双向断言 gamestate.cpp:5057/5072) {残渣@0..7, buckets@8, 计数 u32@+16=62, mask@20=127, distmax@24=9, lf@28=0.9 (RH load factor)} | |
| +984 | CSupplySystem* | 补给系统 | vt0@+0 = 0X2973CC8 (RTTI); 序列化基 = obj+8 (vt1 0X2973CF0) | §4.21 |
| +992 | CRailwayManager* | 铁路管理 | | §4.23 rail_way |
| +1000 | NInternationalMarket::CEquipmentMarketSystem* | 全局装备市场系统 | 全局装备市场挂载 (定案); 国家侧建筑宿主 = cc+4944 CBuildingStatus (非本指针) | §4.13 |
| +1008 | CRaidSystem* | 突袭系统 | | §4.23 raid |
| +1016 | CFactionSystem* | 阵营系统 | | §4.5 |
| +1024 | CDoctrineSystem* | 学说系统 | | §4.6 |
| +1025..+1103 | — | 管理器间区 | = **@1032 区域→(国家link×省) 二维字节查询表** (无独立 RTTI 类 — 负定案, 对象首 qword 为内部数组指针非 vtable; InitGameState 尾 sub_1401E0610 就地构造; 访问器 sub_140E254B0 按 link 下标取 64B 元; 消费者 sub_140F35D80 gradientbordermanager.cpp / sub_140D73E30 taskforce.cpp; 前 6 管理器 = CSupplySystem/CRailwayManager/CEquipmentMarketSystem/CRaidSystem/CFactionSystem/CDoctrineSystem @+984..+1024) + u32 对列表 {d@1040, cap@1048, c@1052, alloc@1056} (块 12354, B240 元; 探针 2135) + difficulty_setting 数组 {d@1064, cap@1072, c@1076, alloc@1080} (块 13999 + assert "difficulty_setting"; ⚠ 与难度枚举 gs+1584 分家) + game_rules@1088 + entity@1096 + power_balance@1104 | |
| +1104 | CPowerBalanceSystem* | 力量平衡/国家角色 | power_balance 系统 vtable 0X296FCA0, 条目 vtable 0X296FC50 | §4.3 |
| +1105..+1191 | — | 力量平衡尾 | = i32 −1@1112 + CGameDate 存档 date@1120..1143 (头 writer 键 10314 经 a3+1136 代理) + **日期分量缓存@1144..1183** (gs hourly tick sub_1401DD370 每次填入: +1144 年 / +1148 月首累计日 / +1152 日 / +1156 年积日 / +1160 月索引) + CGameDate#2@1184..1207 = **start_date** (writer 键 10464 直名经 +1200 代理) | |
| +1192 | hours | **start_date** (日期#2 hours) | CGameDate#2@1184..1207: vt1@1184, hours@1192, vt2@1200; writer 键 10464 直名 + token 表 1241 行 + has_start_date 注册串 ("Compare the initial start date of current game.") | 定案 |
| +1193..+1247 | — | 日期#2 尾 | = CGameDate#2 vt2@1200 + **小时进度累积器 f32@1208** (时间推进调度器每帧 `+= 帧耗时/(速率×加成)`, 攒满 1.0 生成 CHourlyTickCommand 后重置; 详 §4.2.2) + speed u32@1212 (键 110; 探针=4) + u8@1216 (**hourly tick 进行中标志**: tick 首置 1 尾清 0, 兼一帧至多一小时的生成门, 详 §4.2.2) + to_be_deleted {d@1224, cap@1232, c@1236, alloc@1240} (块 19332 + assert; 元素 8B 双 u32; hourly tick 尾 sub_1401D6290 清扫, §4.2.6) + CPeaceConferenceManager 头@1248 (每 hourly tick 末被驱动, §4.2.4) | |
| +1248 | CPeaceConferenceManager (内嵌) | 和会管理器 | | §4.10.26; vt 0X2720E48 (RTTI+探针); 谍报网在国家侧 (§4.11) |
| +1249..+1311 | — | 和会管理器体 | = {vt@1248, q@1256, q@1264, off@1272} (块 12499) + MSVC 串@1280..1311 (SSO, 探针空串; 疑会话名, 语义未决) | |
| +1312 | u32 | playthrough 当前 id | 键 10805; 探针 121 | §4.1.2 |
| +1316 | u32 | playthrough 备用 id | | |
| +1320 | u32 | playthrough tag | 键 13913; 探针 9 | §4.1.2 |
| +1328 | 指针 (对象 +132 u8 门 / +352 子对象) | 运行时对象指针; 不序列化 (writer/loader 均不触; 消费形态 sub_14222BDC0(*(gs+1328)) 三证) | | |
| +1336 | — | fired_event_names 桶头 | {u32@1336, 桶数@1340=511, 桶 ptr@1344=malloc(0xFF8)} | |
| +1352 | token 对 向量 | **fired_events** (loader case 11003; 8B 元素, push 原语 sub_1401CBF60 1.5× 增长, 容器 {data@1352, cap@1360, count@1364, alloc@1368}) | | |
| +1376 | 匿名结构 (112B 形状) 向量 | pending_events | {d@1376, c@1388}; 元素 56B, 四子键 10993/11/10646/11585; 元素 scope 链 @e+16 逐层递归 (root@sc+24/from@+32/prev@+40, 自指即停), **每层**发 saved_event_target (块 0x33A1, 门 *(sc+160)≠0, 112B 元素 {state@+8/country tid@+12/character idpair@+16/name u16@+104}) | 块 13801 |
| +1400 | — | runtime-only 残渣 (无消费者、无 loader/writer — 负定案) | | |
| +1424 | 匿名结构 (0xA8 形状) 向量 | sunk_ship | {d@1424, c@1436} | |
| +1448 | 匿名结构 (24B 形状) 向量 | sunk_convoys | {d@1448, c@1460}; 元素 0x18 | |
| +1472 | CNavalCombatResults** | 海战结果主数组 (元素键 13564 = token `naval_combat_result`) | | |
| +1496 | 匿名结构 (72B 形状) | **CNavalCombatResults\* 按区域 id 索引的 RH 表** (键 = results+264; loader case 13564 = token `naval_combat_result`, 主数组在 +1472) | f32 1.0 + 环形哨兵 + 16 桶侵入哈希 | |
| +1560 | — | 未决区 | q@1560 + u32@1568 + u8@1572; 无消费者、不序列化 (负定案) | |
| +1576 | 内嵌 | gameplaysettings | ctor sub_140BBB0D0; 块 11102; 区内 +1584 = 难度枚举 | |
| +1584 | u32 | 难度枚举 | 键 10655 转串; 探针=2 | |
| +1585..+1623 | — | 枚举尾 | = CArmy* 向量 {d@1600, cap@1608, c@1612, alloc@1616} (探针 37 项, 元素 vt=CArmy) | |
| +1624 | CSelectionGroup** | 选择组 | 10 组 × 240B, 组内 10 槽 × 24B {data@+0, cap@+8, count@+12, alloc@+16}; loader case 10286 | §4.23 |
| +1625..+1671 | — | 选择组容器 | = selection-groups 容器 {d@1624, cap@1632, c@1636, alloc@1640} (探针 cap474/cnt333 — 每国一组 240B, 块 10286) + pdx@1648..1671 (空) | |
| +1672 | CWeatherManager* | 天气管理 | | §4.20; vt 0X2977810; loader case 12040 定案 |
| +1680 | CStrategicAirManager* | 战略空军管理 | | §4.15 |
| +1688 | CNavyManager* | 海军/生产项目/部署 HQ | | §4.16 / §4.8 / §4.18; 别名定名 (vt 0X29732E0, RTTI 无名); 元素 CStrategicNavy (vt 0X2973260, RTTI) |
| +1696 | CStrategicOperativeManager* | 谍报机构管理 | | §4.11 |
| +1704 | CCharacterManager* | 角色管理 | | §4.4 |
| +1705..+1775 | — | 管理器间区 | = CWorldThreat*@1712 (malloc 0x40; 键 0x2BBD=11261 + assert "threat"; 探针 vt RVA 0X2976738) + u32@1720 + saved_event_target {d@1728, cap@1736, c@1740, alloc@1744} (块 13217, 元素 112B 步进) + pdx@1752..1775 (空) | |
| +1776 | CReferencedDivisionTemplate** | 编制模板 | 编制模板容器数据 (元素 vt 0X294F5B0, RTTI); count@+1788 | §4.18 |
| +1777..+1787 | — | 编制模板容器尾 | = division_templates 容器 {d@1776, cap@1784, c@1788, alloc@1792} 内部 (块 13369, 元素键 12112) | |
| +1788 | u32 | division_templates 容器计数 | stockpile 共用区语义见 §4.23.2 | §4.23 |
| +1789..+1799 | — | 容器尾 | = division_templates alloc@1792 尾 + equipment 变体容器头 {d@1800} (块 12122) | |
| +1801..+1811 | — | equipment 容器内部 | = {cap@1808, c@1812, alloc@1816} | |
| +1813..+1831 | — | equipment 尾 | = alloc@1816 尾 + game_unique_seed u32@1824 (键 13737) + game_unique_id 串头@1832 前 pad | |
| +1833..+2167 | — | 唯一 id 区 | = game_unique_id 串体 {size@1848, cap@1856=15} + land_combat_id@1864 / navy_id@1868 + CNonstaticIdGenerator<74/79/86/83/87> 16B×5 @1872..1951 + CIdCounterStore@1952..2007 {vt, pdx 子容器@1960, pdx 子容器@1984; dtor sub_1401C37B0 = dtor(+8)+dtor(+32); 探针 4/4 与 2/0} + **CGameStateTimer@2008..2159** (源码锚 profiling/gamestatetimer.cpp; 写 `logs/gametimer_%Y%m%d_%H%M%S.tsv`, 不进存档; 使能门 = byte@+2016; 五档 hour/day/week/month/year 均值在 +2104..+2159; ctor sub_140BBB6D0) + 残渣@2160..2167 (探针非零) | |
| +2168 | u64 | average_major_ic | 键 13885; writer AE590 u64 通道 | |
| +2169..+2231 | — | 日志区 | = logmgr 容器 {d@2176, cap@2184, c@2188, alloc@2192} + _AllPlaythroughData RH map@2200..2231 {gate u32@2216=1, mask@2220=7, distmax@2224=5, lf@2228=0.9} | |
| +2232 | uint8 | **statistics_collection_enabled** (loader case 15933 → sub_1424C0C00) — 读即清的一次性请求旗 (4 处消费点读后置 0) | | |

#### 4.1.2 存档头部区界覆盖表 (top_meta 区界占位)

> 覆盖行（无独立残留）= 该偏移区无独立字段残留, 已由本册其他各节展开覆盖, 行仅作区界占位。

**获取**: gs 直接偏移。**语义**: 存档头部元数据, 大多为写档时生成。本表 = 区界覆盖索引 (逐字段权威布局见 §4.1.1)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +152 | — | = 顶格 # 元数据叶区界 + 日期#0 载入快照 | checksum/version/dlcs/save_version 等元数据叶 (键表 §4.1.6); 本偏移本身 = CGameDate hours (逐字段 §4.1.1) | 元数据叶不做值级对拍 (用户裁定) |
| +153..+191 | — | = **CPersistent 基类子对象中段** (ctor sub_140BC0880): 日期#0 {hours@152, vt2@160} 尾 + **player_countries {d@168, cap@176, c@180, alloc@184}** (块 13671, 元素 160B) — 该区即 CPersistent 基类成员中段 |  | |
| +192 | — | = 位域旗 | bit0 = checksum 门 / bit3 = tutorial (逐字段 §4.1.1) |  |
| +193..+467 | — | = CPersistent 尾段 {位域@192 (bit0=checksum 门 / bit3=tutorial), null-object 句柄@200, 容器B@216, 标志@240, scoped@248} + **CHuman@272 (160B)** + **CDedicatedServer@432 (156B, 名串 "Dedicated server")** |  | |
| +468 | — | = CDedicatedServer 名串 (gs+464, "Dedicated server") 堆指针的高 dword (随 ASLR 变); 存档真值 multiplayer_random_count 来自静态 dword_143452520 (键 11459) |  | |
| +469..+1191 | — | = CDedicatedServer 尾 + pad → gs+600; gs+600..+1191 中段全数定案见 §4.1.1 (CFlagManager@600 / CCombatManager@608..683 / 省州区国四数组 / tag 表 / 按国家数组 / RH map@952 / 第 7 管理器@1032 / u32 对列表@1040 / difficulty_setting@1064 / game_rules@1088 / entity@1096 / power_balance@1104 / date@1120 / CGameDate#2@1184)  |  | |
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

#### 4.1.3 CCurrentGameState 尾段 (+2536..+2618)

gs 单例实为派生类 CCurrentGameState; CGameState 本体 ≈ +0..+2535。

| 项 | 值 |
|---|---|
| RTTI 名 | CCurrentGameState (探针 vt RVA 0X2721158) |
| sizeof | 0xA40 = 2624 (创建点 malloc 0xA40 + "Trying to initialize gamestate twice" assert, gamestate.cpp:0x6A0) |
| vtable RVA | 双表: vt1@+0 / vt2@+8 (vt2 = 查询接口, provinces loader 经 vt2+8 取省) |
| writer | — |
| loader | sub_1401E59D0 (71 case 巨型 switch, 读档 token→槽直译; 主文件 §1.2 总表 = case→槽位直译 46 案 + ctor 直读 26 案) |
| 挂载点 | gs 单例 (§4.1 获取) |
| ctor | 链 sub_1401BF930 (CCurrentGameState) → sub_1401BFD30 (基) |

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +2536 | 匿名结构 (16B 形状) | **战略空军 region→兵力树** (pdx 容器; strategicair.cpp) | | |
| +2552 | — | 总线头 | | |
| +2560 | 指针 | 三容器对象 (ctor 零填; 复位调 `sub_140DC3B70` 逐容器清 {data@+0/count@+12/子对象@+16} 三组) — 语义待裁 | | |
| +2568 | u8 | 运行时旗 (全 dump 唯一引用 sub_141AF5D10 置 0, 无读方, 不序列化) | | |
| +2576 | — | 边界色高亮数组 | +2576..+2591; assert "BORDER_COLOR_CUSTOM_HIGHLIGHTS…"; 数量 = dword_143338A64/4 | |
| +2592 | 匿名结构 (NNB 形状)* | reload 总线头 | off_143085170 | |
| +2600 | CBookmark* | **TNullObject\<CBookmark,CBookmark\>\* 空对象句柄** (sub_1401DBBB0 返回全局 qword_14332F350, 创建于 CBookmarkDatabase ctor sub_14067C250) — 非回调 | | |
| +2608 | u32 | 键 13842 = **tutorial_chapter** | 置位时写 gs+2615=1 并置 gs+192 位域 bit3 = tutorial 旗 | |
| +2615..+2618 | — | 标志区 | | |
| +2615 | u8 | tutorial_chapter 门 | trigger is_tutorial 消费 (getter sub_1401E2A80 直读) | 定案 |
| +2617 | u8 | **会话/事件发射门** | 加载期置 0, 开局置 1; transfer_state 系 SetOwner/SetController 第三参极性与 add_to_faction 的 on_offer_join_faction 事件发射门御此位 (两批互证) | 高置信 |


#### 4.1.4 未决清单

| 项 | 结论 | 证据 |
|---|---|---|
| gs+1032 槽 | **区域→(国家link×省) 二维字节查询表** (非管理器) | 无独立 RTTI 类 (负定案); InitGameState 尾 sub_1401E0610 就地构造; 访问器 sub_140E254B0 |
| 双生子 A (+1496) | **CNavalCombatResults\* 按区域 id 索引的 RH 表** (主数组 +1472) | 键 = results+264; loader case 13564 = `naval_combat_result` |
| 双生子 B (+2280) | **cosmetic_tag 串 → CCountryColors\* 的 RH 映射** | `common/countries/cosmetic.txt` 解析器 sub_1401CCE90 填充; 消费 sub_1401DB180 |
| +2008..+2159 | **CGameStateTimer** (不进存档) | profiling/gamestatetimer.cpp; 写 logs/gametimer_*.tsv; 使能门 byte@+2016 |
| gs+952 RH map | **联合国策焦点 × 国家 连接表** (非 tech_sharing; tech_sharing = 紧邻前格 +928, writer token 14100) | 键 = focus+88, 值 = CCountry\* 数组; 断言 gamestate.cpp:5057/:5072; +980 f32 0.9 = RH load factor |
| +1144 域 | **日期分量缓存** (非预留) | gs hourly tick sub_1401DD370 填入 年/月首累计日/日/年积日/月索引 |
| CGameDate#2@1184 | **start_date** | writer 键 10464 直名 + token 表 1241 行 |
| +2536 | **战略空军 region→兵力树** | strategicair.cpp; pdx 容器 |
| +2600 | CBookmark* | sub_1401DBBB0 返回全局 qword_14332F350, 创建于 CBookmarkDatabase ctor sub_14067C250 |
| +2608 | 键 13842 = **tutorial_chapter** | 置位写 gs+2615=1 + gs+192 bit3 = tutorial 旗 |
| +2240 域 | **tag 工作列表** {d@2240, 计数@2252} (CPdxArray<CCountryTag,unsigned>) | hourly tick 步骤 9 遍历 (查 _AllPlaythroughData@2200, §4.1.8) + DoCareerProfile 族并行容器 (§4.2.6) |
| +2416 域 | **军队状态小时统计累计器族** (hourly) | TOTAL_IN_COMBAT_MAN_HOUR 等 14 键; CGameState::HourlyUpdate 首步累加 (§4.2.6; 类名待裁) |
| pdx 空位群 已名 12 项 | +760 region→country 表 / +880 `_CountryControllersEnable` / +904 控制器计数 / +1352 fired_event_names 实例数组 / +1400 指针集 / +1472 海战主数组 / +1648 **`MP_locked_countries`** / +1752 scope→saved event target / +2384 指针向量 / +2440 **`_CountriesForOriginalTags`** / +2464 战略空军表 | 逐个 ctor/消费者实证 (+2240/+2416 已升独立行) |
| gs+2352 | **负定案: gs 语境下查无此槽** — 基类 ctor 与 gs dtor 均不触及, 全部命中为同偏移异类 (旧登记疑误) | 基类 ctor + gs dtor 全扫 |
| CPersistent+216 (= gs+216) | 未决 — 仅基类 ctor 初始化, 无消费者 | — |
| gs+1280 串 | 未决 — CPeaceConferenceManager 内 SSO, 无写入点 | — |
| CPersistent 串1 (+16) / version 串 (+96) | 未决 — 无消费者与写入点 | — |

#### 4.1.5 全局顶层块补录 (sv2_sec_global_tails 审计)

| 块 | 挂载 | 布局要点 |
|---|---|---|
| flags | CFlagStore *(gs+600) | 全局旗标 store (布局见 sv2_sec_global_tails 段注) |
| pending_events | {d@gs+1376, c@gs+1388} | 元素 56B |
| difficulty_settings | {d@gs+1064, c@gs+1076} | 门 = multiplier@+208 > 0; writer 0X1409B9490 |
| game_rules | *(gs+1088) CGameRulesInstance | token 对向量 |
| to_be_deleted | {d@gs+1224, c@gs+1236} | 元素 8B = {type u32@+0, id u32@+4}; 键 11=id 写第二 u32 / 225=type 写第一 u32; 无条目门全队列发 (writer 元 sub_142220180); 条目类型 61 = 国家族 (id 对先例 CResourceOrigin spotter, §4.3 rs 行) = 死亡国家 id 残留 |

#### 4.1.6 顶格 # 叶 writer 族

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
| sub_1401F2DD0 | all_playthrough_data | 块 (§4.1.8) |
| sub_1401F2DD0 | statistics_collection_enabled | u8@gs+2232 |

值级对拍豁免:

| 键 | 豁免原因 |
|---|---|
| checksum / version / dlcs | 写盘时生成 |
| session / seconds_played | 墙钟秒 (用户裁定追加豁免) |

#### 4.1.7 #.id 叶

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

#### 4.1.8 all_playthrough_data (gs+2200)

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

#### 4.1.9 NCareerProfile::SPlaythroughCountryData (wrapper)

| 项 | 值 |
|---|---|
| 类名 | NCareerProfile::SPlaythroughCountryData |
| vtable RVA | 0x142721478 |
| 挂载 | all_playthrough_data RH map 桶值对象 |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | SProfileData (2056B) | data = {vt@+8, first SCareerProfileCountryData@+16 (1008B), second@+1024, tag MSVC-SSO@+2032} | tag **空串也写 `""`** (恒引号) |
| +9..+2063 | — | （覆盖行， 无独立残留） |  |
| +2064 | 384B | intermediate_statistics (writer 0X1406AA260) | §4.1.10 |
| +2065..+2447 | — | （覆盖行， 无独立残留） |  |
| +2448 | CFlagManager 内嵌 | flags | 块恒写 (count=0 空块无叶); §4.1.11 (布局 §4.13.3) |
| +2449..+2479 | — | （覆盖行， 无独立残留） |  |
| +2480 | uint8 | first_tag | → yes/no 恒写 |

#### 4.1.10 intermediate_statistics (wrapper+2064)

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

#### 4.1.11 CFlagManager (wrapper+2448 内嵌)

career profile 侧 CFlagManager 宿主 (块恒写 count=0 空块无叶); 键走 token_name
(`career_profile_overrun_*_flag` 16025/16028 实证; ⚠ 勿裸用 SL.tok 数字回退)。
**类布局 (vtable 0X14295BB98 / writer 0X140CBFFC0 / 条目 CScriptFlag 48B 全字段) = §4.13.3 (权威, 勿重述)**。

#### 4.1.12 SCareerProfileCountryData (blob 164 键)

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

#### 4.1.13 结构尾部字段 (writer 同函数, 非 k=v 族)

| 字段 | token | 形态 | 备注 |
|---|---|---|---|
| produced_combat_widths | 16091 | **u32×52 @ S+776..S+983** | writer `for i=+776; i!=+984; ++i`; 块; 提取器折成 `@.#1` 空格行 |
| average_air_superiority | 16144 | i64×2 @ S+760/S+768 | +760 和, +768 计数 (`197811 266` 形) |
| new_bests | 15902 | **i64×3 @ S+984/S+992/S+1000** | 位集 |

blob 单叶格式 = `k=v` 空格连接 164 对 + 尾部 ` produced_combat_widths={`
(开括号无闭, 闭合在 @.#1 行后)。

⚠ i64 读出经 double: >2^53 非 2 幂位型 (new_bests 位集) 理论精度风险;
实测值精确 (2^61/2^33), `%.0f` 出数。

#### 4.1.14 提取路径/序号契约 (提取器形态实证)

| 路径模式 | 说明 |
|---|---|
| `#K.#1.data.first.playthroughs` | first 侧 4 叶: playthroughs / `.@.#1` / `.average_air_superiority` / `.new_bests.#1` |
| `#K.#1.data.second.<叶>` | 同 first 4 叶 |
| `#K.#1.data.tag` | 恒引号, 空串写 "" |
| `#K.#1.intermediate_statistics.<name>.#1` | 9 条 (名见 §4.1.10) |
| `controlled_provinces` | 带 " }" 尾 |
| `#K.#1.first_tag` | yes/no |
| `#K` | 外层 key 叶, 引号 tag, 序在最后 |

#### 4.1.15 S 偏移锚点

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

#### 4.1.16 ships_built (造舰统计; gs+2520)

RB-tree (std::map 形态): head = *(gs+2520), 规模 = *(gs+2528) (≠0 门); 中序 = 写序; 0 值也写。
键 = 船型 token — 与 §4.1.8 all_playthrough_data 的 `designed_ships`(§4.1.10 第 10 键) 同族, 故不归海军战史 (§4.16.13/§4.16.14 收沉船总账与运输船月账)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | RB 节点* | l (left) |  |  |
| +8 | RB 节点* | p (parent) |  |  |
| +16 | RB 节点* | r (right) |  |  |
| +24 | uint8 | color |  | MSVC _Tree_node {left@0, parent@8, right@16, color u8@+24, isnil u8@+25} (定案) |
| +25 | uint8 | nil |  |  |
| +28 | uint32 | key |  | 船型 token |
| +32 | uint32 | value | 恒写 (0 值也写) |  |

⚠ gs+2520 与 session_meta #.id 同址撞车: gs+2520 实属本块, 见 §4.1.7。
