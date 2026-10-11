

### 4.1 CGameState (游戏状态单例)

**获取**: `gs = *(BASE + 0X332F260)` (单例指针, 无 vtable 校验必要)。派生类 CCurrentGameState 见 §4.1.3。

#### 4.1.1 管理器字段 (+152..+2232; gs+0..+15 = vtable1 (CPersistent@0 主vtable) + vtable2@8 (CProvinceProvider 查询接口), +16..+239 = 存档头元数据对象 224B (ctor sub_140BC0880, 详 §4.1.2)

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +152 | hours | 日期#0 **载入快照** | CGameDate 尾 {hours@152, vtable2@160}; CPersistent 基类成员。**只有读档路径写, 之后不随时钟推进** (新建局停在 ctor 哨兵 43808760; 当前日期在 +1128) | §4.1.2 |
| +168 | 匿名结构 (NNB 形状) 向量 24B | player_countries | {d@168, cap@176, c@180, alloc@184}; 元素 160B, tag@元素+112 | writer 头块 13671 |
| +192 | — | 位域旗 (u32) | bit0 = ironman/成就门 (存档名比对, 非 checksum) / bit1 = 多人局 / bit2 = cooperative_game / bit3 = tutorial | §4.1.2 |
| +200 | 匿名结构 (NNB 形状)* | null-object 句柄 | | |
| +216 | MSVC 串 向量 24B | **启用 mod 名列表** (MSVC 串 32B/元; {d@216, cap@224, c@228, alloc@232}; scanner 键 14185 载入, op= 拷贝; 元素 cap>15 走堆) | 序 = mod 加载序 |  |
| +240 | — | 标志 | | |
| +248 | 匿名结构 (NNB 形状)* | **人类玩家花名册数组** (CHuman 160B/项, 计数@+260; 项布局同 +272 槽: 名串@+32 / **+64 第二显示名串 (alert 53 tooltip 的 PLAYER 参数; 语义推定 = 国家/玩家显示名, 待裁)** / country-link id@+112 / +148 bit0 = 领导人资格 / +152 会话判别 / **+128 日期水位 (CGameDate 小时域; 掉队判定 = 当前小时 − 水位 > LAG_DAYS_FOR_LOWER_SPEED×24)**; 查 = sub_1401C9CD0 线性扫) | §4.33 CPromoteToCountryLeaderCommand / CSetCountryControllerCommand | |
| +272 | CHuman (内嵌 160B) | 人类玩家槽 | 共用布局: 名串@+32 / 二名串@+64 / badge@+96 / country-link id@+112 (sub_1401DA7C0 "country link index") / CGameDate@+120 / 枚举@+148 / 入参@+152 | |
| +432 | CDedicatedServer (内嵌 156B) | 专用服务器槽 | 派生 CHuman 布局, 名串 "Dedicated server" | |
| +464 | MSVC 串 32B | CDedicatedServer 名串 | 数据堆上, buf 槽 = 堆指针 | |
| +468 | — | 名串指针高 dword | ⚠ 勿当独立字段读 (ASLR 假阳性源) | |
| +469..+599 | — | pad | → gs+600 | |
| +600 | CFlagManager* | 旗管理（堆 32B 对象; gs ctor sub_1401BFD30 malloc(0x20) 写） | 布局 §4.13.3 | |
| +608 | CCombatManager (内嵌) | 战斗管理 | | §4.22; vtable 0X2950688 存于槽自身 (非指针; 探针) |
| +616 | CCombat* | 战斗明细宿主 | 容器数据 {count@+628}; 元素主 vtable 分流: CLandCombat 0X29A83D8 / CNavalCombat 0X29DDB08 / CLandBorderWarCombat 0X29BC5F0 | §4.22 |
| +617..+627 | — | 战斗明细容器尾 | = pdx 容器@616 {d@616, cap@624, c@628 高位} 内部 | |
| +628 | uint32 | 战斗明细容器计数 | 战斗日志管理 (logmgr) = +2176/+2188 容器, 元素 NCombatLog::CManager (vtable 0X295D8D8) | §4.22 |
| +629..+647 | — | 容器尾 | = {alloc@632 = 哨兵} + CCombatHistory 内嵌头@648 | |
| +648 | CCombatHistory (内嵌) | 战斗历史 | | §4.22; vtable 0X2950638 (= CCombatManager+40) |
| +649..+687 | — | CCombatHistory 体 | = {q@656, q@664, u32@672, u8@676, u8@680, pad→683} + pad@684..687 — CCombatManager 全长 76B (+608..+683) | ctor sub_140BB66F0 |
| +688 | CProvince** | 省指针数组 | 省数 = uint32@+700 | §4.14 |
| +689..+711 | — | 省数组尾 | = {cap@696, count@700 已知, alloc@704} | |
| +712 | CState** | 州指针数组 | state_id 直查 | §4.13 |
| +713..+783 | — | 州数组尾 | = {cap@720, count@724, alloc@728} (assert "states", 块 11835) + region 数组 {d@736, cap@744, c@748, alloc@752} (assert "region", 块 10827, 自 id=1) + **region 派生表** {d@760, cap@768, c@772, alloc@780} (runtime-only 不序列化; 元素 80B {u32@0, u32@4, qword 列表@+8, 56B 子对象@+24}; InitGameState 尾 sub_140BC3B20 自 region 表派生 — 遍历 region+160>1000 ∧ region+188>0 者的 +200 表 (96B/条, +0 旗位 &2) 逐条 append {region id, 邻居 id, 共省 id 列表}; 业务语义推定 = region 邻接/共省对缓存, +160>1000 门语义未决) | |
| +784 | CCountry** | 国家指针数组 | 槽 0 = 哨兵; 数量 = uint32@+796 | §4.3 |
| +785..+855 | — | 国数组尾 | = {cap@792, count@796, alloc@800} + **major 国排序集** {d@808, cap@816, c@820, alloc@824} (元素 CCountry*; tag 序二分有序插 sub_1401E2EC0; 成员 = cc+5210 major 旗 — MAJOR_MIN_FACTORIES ∧ ADDITIONAL_MAJOR_COUNTRIES_IC_RATIO×基准工厂 双 define 门, 和平期重算 sub_14070C1C0, annex/复位退组) + country-link 表 {d@832, cap@840, c@844, alloc@848} ("country index→link index" 解析源; 探针 338/474) | |
| +832 | uint32 平铺数组 (24B 描述符) | **original-tag 恒等表** (与「country index→link index」同容器双向读); **引擎名 `_CountryLinkIndices` (断言 7656 直证)** | identity[tag] = 归一化 tag, 元素 uint32 按 tag 直下标 (4×tag); sub_140BB52F0 同原初国判定与 sub_140BB5490 索引向底表 = 同容器两侧消费; **tag id 空间 = link index**: CCountryTag 构造 sub_140BB3E00 = index→link (经 sub_1401DA7C0, 表空恒等回退); 动态 tag 获取 (sub_1401DACD0) 起点 = 国家库 qword_143330D98+136, 回收判据 = cc+1156≤0 ∧ politics+424≤0 ∧ cc+5213==0, 获取即 cc+8 ← 新 link index | 定案 |
| +856 | char** | 国家标签串表 (**引擎名 `_CountryLinkTags`**) | 每项 32 字节 cstr; `tag = 表[tag_id]`。**count@+868 = 合法 tag_id 上界** (≠ 国家数见下注); tag→串 = gs+856[tag] 直下标 (sub_140BB4E70, 表空/无效 tag 回退国家库静态解析 sub_14071BDA0); 串→link = sub_1401DA870 (表空回退国家库 FNV-1a 解析 sub_14071BC80; 断言门 = byte_1435E1B51 轻量档, 与 byte_1435E1B52 全量档两档并存) | |
| +857..+983 | — | tag 串表尾 | = {cap@864, c@868, alloc@872} (探针 474/339; **count@868 是 tag_id 上界, 比 country_count 大** — 实测 339 vs 333) + 按国家数组 pdx@880 = `_CountryControllersEnable` / @904 = 控制器计数 (探针均 333/333=country_count) + tech_sharing 尾 {cap@936, c@940, alloc@944} + **RH map@952..983 = 联合国策焦点 (joint national focus) × 国家 连接表** (键 = focus+88 (murmur finalizer 0x45D9F3B), 值 = CCountry\* 数组; 双向断言 gamestate.cpp:5057/5072 — **5057 添加侧实体 = sub_1401CA250 (定案**, 已含断言; 5072 移除侧未定位); **桶 40B {hash u32@+0, dist u8@+4, key u32@+8, 值 16B 内联 qword 数组@+16}** (find-or-insert sub_1401B09C0, lf 门 @+28, rehash sub_1401DCC00), 与 _AllPlaythroughData 的 24B 桶为两种 RH 桶形) {残渣@0..7, buckets@8, 计数 u32@+16=62, mask@20=127, distmax@24=9, lf@28=0.9 (RH load factor)} | |
| +984 | CSupplySystem* | 补给系统 | vt0@+0 = 0X2973CC8 (RTTI); 序列化基 = obj+8 (vtable1 0X2973CF0) | §4.21 |
| +992 | CRailwayManager* | 铁路管理 | | §4.23 rail_way |
| +1000 | NInternationalMarket::CEquipmentMarketSystem* | 全局装备市场系统 | 全局装备市场挂载 (定案); 国家侧建筑宿主 = cc+4944 CBuildingStatus (非本指针) | §4.13 |
| +1008 | CRaidSystem* | 突袭系统 | 持海/陆 raid 寻路表 (海军 sub_140E86040 / 陆 sub_140E86000, §4.27.7) | §4.27 |
| +1016 | CFactionSystem* | 阵营系统 | | §4.5 |
| +1024 | CDoctrineSystem* | 学说系统 | | §4.6 |
| +1025..+1103 | — | 管理器间区 | = **@1032 区域→(国家link×省) 二维字节查询表** (无独立 RTTI 类 — 负定案, 对象首 qword 为内部数组指针非 vtable; InitGameState 尾 sub_1401E0610 就地构造; 访问器 sub_140E254B0 按 link 下标取 64B 元; 消费者 sub_140F35D80 gradientbordermanager.cpp / sub_140D73E30 taskforce.cpp; 前 6 管理器 = CSupplySystem/CRailwayManager/CEquipmentMarketSystem/CRaidSystem/CFactionSystem/CDoctrineSystem @+984..+1024) + u32 对列表 {d@1040, cap@1048, c@1052, alloc@1056} (块 12354, B240 元; 探针 2135) + difficulty_setting 数组 {d@1064, cap@1072, c@1076, alloc@1080} (块 13999 + assert "difficulty_setting"; ⚠ 与难度枚举 gs+1584 分家) + game_rules@1088 + entity@1096 + power_balance@1104 | |
| +1104 | CPowerBalanceSystem* | 力量平衡/国家角色 | power_balance 系统 vtable 0X296FCA0, 条目 vtable 0X296FC50 | §4.3 |
| +1105..+1191 | — | 力量平衡尾 | = i32 −1@1112 + CGameDate 存档 date@1120..1143 (头 writer 键 10314 经 a3+1136 代理) + **日期分量缓存@1144..1183** (gs hourly tick sub_1401DD370 每次填入: +1144 年 / +1148 月首累计日 / +1152 日 / +1156 年积日 / +1160 月索引) + CGameDate#2@1184..1207 = **start_date** (writer 键 10464 直名经 +1200 代理) | |
| +1192 | hours | **start_date** (日期#2 hours) | CGameDate#2@1184..1207: vtable1@1184, hours@1192, vtable2@1200; writer 键 10464 直名 + token 表 1241 行 + has_start_date 注册串 ("Compare the initial start date of current game.") | 定案 |
| +1193..+1247 | — | 日期#2 尾 | = CGameDate#2 vtable2@1200 + **小时进度累积器 f32@1208** (时间推进调度器每帧 `+= 帧耗时/(速率×加成)`, 攒满 1.0 生成 CHourlyTickCommand 后重置; 详 §4.2.2) + speed u32@1212 (键 110; 探针=4) + u8@1216 (**hourly tick 进行中标志**: tick 首置 1 尾清 0, 兼一帧至多一小时的生成门, 详 §4.2.2) + to_be_deleted {d@1224, cap@1232, c@1236, alloc@1240} (块 19332 + assert; 元素 8B 双 u32; hourly tick 尾 sub_1401D6290 清扫, §4.2.6) + CPeaceConferenceManager 头@1248 (每 hourly tick 末被驱动, §4.2.4) | |
| +1248 | CPeaceConferenceManager (内嵌) | 和会管理器 | | §4.10.26; vtable 0X2720E48 (RTTI+探针); 谍报网在国家侧 (§4.11) |
| +1249..+1311 | — | 和会管理器体 | = {vtable@1248, q@1256, q@1264, off@1272} (块 12499) + MSVC 串@1280..1311 (SSO; **runtime-only 不序列化** — writer/reader 仅 13632 会议容器, 本机 9 档 peace_conference 块全空互证; 运行期临时名, 写点未定位) | |
| +1312 | uint32 | **玩家国 id** (int>0 = 动态国 id, 否则 4 字符 tag 在 +1316) — 键 10805 = token "player" (旧标 "playthrough id" 系误读); 运行时十余处按玩家 tag 消费 (通知门∧!human_ai / AI 玩家国策略解析 / 焦点历史只写该国 / Focus.AutoComplete ×10); **读侧两形 (0x142 段 gamestate.h 族实证)**: ① **两段式值直取** `v = *(DWORD*)(gs+328); if (v <= 0) v = *(DWORD*)(gs+329);` (不经 sub_140BB48F0, 直接取 tag 值入比对/事件载荷, 3 函数互证); ② **指针参数直传** — gs+1312 作 tag 指针实参直传下游 (sub_140ABAD20 / sub_14053A610 事件 scope 载荷, 2 函数互证) | 探针 121 | §4.1.2; §4.3.15a |
| +1316 | uint32 | 玩家国 tag 半 (4 字符; +1312 ≤0 时有效) | | |
| +1320 | uint32 | **tension_scaling_base_country** (键 13913 = token 同名; 紧张度缩放基国) | 探针 9 | §4.1.2 |
| +1328 | 指针 (对象 +132 u8 门 / +352 子对象) | **首个写点已定位**: sub_140CECE50 (CSetCountryControllerCommand::Execute, controlcommands.cpp:115) 玩家转观察者 (cmd tag ≤ 0) 时写 `gs+1328 = 旧国 politics+656 = CFaction\*`, 随后 gs+1316 = 同阵营 fallback tag — **语义候选 = 观察者 fallback 阵营指针 (推定, 待运行时复核)**; 不序列化 (writer/loader 均不触; 消费形态 sub_14222BDC0(*(gs+1328)) 三证) | | |
| +1336 | — | fired_event_names 桶头 | {u32@1336, 桶数@1340=511, 桶 ptr@1344=malloc(0xFF8)} | |
| +1352 | token 对 向量 | **fired_events** (loader case 11003; 8B 元素, push 原语 sub_1401CBF60 1.5× 增长, 容器 {data@1352, cap@1360, count@1364, alloc@1368}) | | |
| +1376 | 匿名结构 (56B 形状) 向量 | pending_events | {d@1376, c@1388}; 元素 56B, 四子键 10993/11/10646/11585; 元素 scope 链 @e+16 逐层递归 (root@sc+24/from@+32/prev@+40, 自指即停), **每层**发 saved_event_target (块 0x33A1, 门 *(sc+160)≠0, 112B 元素 {state@+8/country tid@+12/character idpair@+16/name u16@+104}) | 块 13793 (13801 = show_major, 勿混) |
| +1400 | — | runtime-only 残渣 (无 loader/writer — 负定案; ⚠ 待裁: sub_140BBA690 实证存在按省驻单位评估的读侧消费, 「无消费者」结论需复核) | | |
| +1424 | 匿名结构 (0xA8 形状) 向量 | sunk_ship | {d@1424, c@1436} | |
| +1448 | 匿名结构 (24B 形状) 向量 | sunk_convoys | {d@1448, c@1460}; 元素 0x18 | |
| +1472 | CNavalCombatResults** | 海战结果主数组 (元素键 13564 = token `naval_combat_result`) | | |
| +1496 | 匿名结构 (72B 形状) | **CNavalCombatResults\* 按区域 id 索引的 RH 表** (键 = results+264; loader case 13564 = token `naval_combat_result`, 主数组在 +1472) | f32 1.0 + 环形哨兵 + 16 桶侵入哈希 | |
| +1560 | — | 未决区 | q@1560 + u32@1568 + u8@1572; 无消费者、不序列化 (负定案) | |
| +1576 | 内嵌 | gameplaysettings | ctor sub_140BBB0D0; 块 11102; 区内 +1584 = 难度枚举 | |
| +1584 | uint32 | 难度枚举 | 键 10655 转串; 探针=2 | |
| +1585..+1623 | — | 枚举尾 | = CArmy* 向量 {d@1600, cap@1608, c@1612, alloc@1616} (探针 37 项, 元素 vtable=CArmy) | |
| +1624 | CSelectionGroup** | 选择组 | 10 组 × 240B, 组内 10 槽 × 24B {data@+0, cap@+8, count@+12, alloc@+16}; loader case 10286 | §4.23 |
| +1625..+1671 | — | 选择组容器 | = selection-groups 容器 {d@1624, cap@1632, c@1636, alloc@1640} (探针 cap474/cnt333 — 每国一组 240B, 块 10286) + pdx@1648..1671 (空) | |
| +1672 | CWeatherManager* | 天气管理 | | §4.20; vtable 0X2977810; loader case 12040 定案 |
| +1680 | CStrategicAirManager* | 战略空军管理 | | §4.15 |
| +1688 | CNavyManager* | 海军/生产项目/部署 HQ | | §4.16 / §4.8 / §4.18; 别名定名 (vtable 0X29732E0, RTTI 无名); 元素 CStrategicNavy (vtable 0X2973260, RTTI) |
| +1696 | CStrategicOperativeManager* | 谍报机构管理 | | §4.11 |
| +1704 | CCharacterManager* | 角色管理 | | §4.4 |
| +1705..+1775 | — | 管理器间区 | = CWorldThreat*@1712 (malloc 0x40; 键 0x2BBD=11261 + assert "threat"; 探针 vtable RVA 0X2976738) + u32@1720 + saved_event_target {d@1728, cap@1736, c@1740, alloc@1744} (块 13217, 元素 112B 步进) + pdx@1752..1775 (空) | |
| +1776 | CReferencedDivisionTemplate** | 编制模板 | 编制模板容器数据 (元素 vtable 0X294F5B0, RTTI); count@+1788 | §4.18 |
| +1777..+1787 | — | 编制模板容器尾 | = division_templates 容器 {d@1776, cap@1784, c@1788, alloc@1792} 内部 (块 13369, 元素键 12112) | |
| +1788 | uint32 | division_templates 容器计数 | stockpile 共用区语义见 §4.23.2 | §4.23 |
| +1789..+1799 | — | 容器尾 | = division_templates alloc@1792 尾 + equipment 变体容器头 {d@1800} (块 12122) | |
| +1801..+1811 | — | equipment 容器内部 | = {cap@1808, c@1812, alloc@1816} | |
| +1813..+1831 | — | equipment 尾 | = alloc@1816 尾 + game_unique_seed u32@1824 (键 13737) + game_unique_id 串头@1832 前 pad | |
| +1833..+2167 | — | 唯一 id 区 | = game_unique_id 串体 {size@1848, cap@1856=15} + land_combat_id@1864 / navy_id@1868 + CNonstaticIdGenerator<74/79/86/83/87> 16B×5 @1872..1951 + CIdCounterStore@1952..2007 (生成函 0x140BBD0E0: idpair = {type u32@store+8, counter u32@store+12}, out[1] = ++counter; 双 B52 守门 — :79 主线程 (闩 byte_14333C88A) / :86 同步域 (闩 byte_14333C88B)) {vtable, pdx 子容器@1960, pdx 子容器@1984; dtor sub_1401C37B0 = dtor(+8)+dtor(+32); 探针 4/4 与 2/0} + **CGameStateTimer@2008..2159** (源码锚 profiling/gamestatetimer.cpp; 写 `logs/gametimer_%Y%m%d_%H%M%S.tsv`, 不进存档; 使能门 = byte@+2016; 五档 hour/day/week/month/year 均值在 +2104..+2159; ctor sub_140BBB6D0) + 残渣@2160..2167 (探针非零) | |
| +2168 | u64 | average_major_ic | 键 13885; writer AE590 u64 通道 | |
| +2169..+2231 | — | 日志区 | = logmgr 容器 {d@2176, cap@2184, c@2188, alloc@2192} + _AllPlaythroughData RH map@2200..2231 {gate u32@2216=1, mask@2220=7, distmax@2224=5, lf@2228=0.9} | |
| +2232 | uint8 | **statistics_collection_enabled** (loader case 15933 → sub_1424C0C00) — 读即清的一次性请求旗 (4 处消费点读后置 0) | | |

#### 4.1.2 存档头部区界覆盖表 (top_meta 区界占位)

> 覆盖行（无独立残留）= 该偏移区无独立字段残留, 已由本册其他各节展开覆盖, 行仅作区界占位。

**获取**: gs 直接偏移。**语义**: 存档头部元数据, 大多为写档时生成。本表 = 区界覆盖索引 (逐字段权威布局见 §4.1.1)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +152 | — | = 顶格 # 元数据叶区界 + 日期#0 载入快照 | checksum/version/dlcs/save_version 等元数据叶 (键表 §4.1.6); 本偏移本身 = CGameDate hours (逐字段 §4.1.1) | 元数据叶不做值级对拍 (用户裁定) |
| +153..+191 | — | = 元数据对象中段: 日期#0 24B {vtable1@144, hours@152, vtable2@160} 尾 + **player_countries {d@168, cap@176, c@180, alloc@184}** (块 13671, 元素 160B) |  | |
| +192 | — | = 位域旗 (u32) | bit0 = ironman/成就门 / bit1 = 多人 / bit2 = coop / bit3 = tutorial (逐字段 §4.1.1) |  |
| +193..+467 | — | = CPersistent 尾段 {位域@192 (bit0=checksum 门 / bit3=tutorial), null-object 句柄@200, 容器B@216, 标志@240, scoped@248} + **CHuman@272 (160B)** + **CDedicatedServer@432 (156B, 名串 "Dedicated server")** |  | |
| +468 | — | = CDedicatedServer 名串 (gs+464, "Dedicated server") 堆指针的高 dword (随 ASLR 变); 存档真值 multiplayer_random_count 来自静态 dword_143452520 (键 11459) |  | |
| +469..+1191 | — | = CDedicatedServer 尾 + pad → gs+600; gs+600..+1191 中段全数定案见 §4.1.1 (CFlagManager*@600 / CCombatManager@608..683 / 省州区国四数组 / tag 表 / 按国家数组 / RH map@952 / 第 7 管理器@1032 / u32 对列表@1040 / difficulty_setting@1064 / game_rules@1088 / entity@1096 / power_balance@1104 / date@1120 / CGameDate#2@1184)  |  | |
| +1192 | — | start_date hours (日期#2 三元组 {1184, 1192, 1200}; 键 10464 经 +1200 代理发射) | | |
| +1193..+1311 | — | = speed@1212 (键 110) + to_be_deleted@1224 (块 19332) + CPeaceConferenceManager@1248 (块 12499) + 串@1280 (runtime-only 不序列化, 语义未名)  |  | |
| +1312 | — | 玩家国 id (键 10805 "player", 详 §1.2 表行) | ||
| +1320 | — | tension_scaling_base_country (键 13913) | ||
| +1321..+1583 | — | = 玩家国 id@1312/1316 + tension_scaling_base_country@1320 (探针 121/0/9) + fired_event_names 桶头@1336..1351 (桶数@1340=511, ptr@1344=malloc(0xFF8)) + pdx@1352 + pending_events@1376 (块 13793, 元素 56B; 13801 = show_major 勿混) + pdx@1400 + sunk_ship@1424 + sunk_convoys@1448 + 指针数组@1472 (键 13564, = **海战结果主数组**) + **A@1496 = CNavalCombatResults\* 按区域 id 索引 RH 表** (72B; 键 = results+264)  |  | |
| +1584 | — | 难度枚举 (键 10655 转串; 同 +1584 主表行) | | |
| +1585..+1831 | — | = 难度枚举@1584 (键 10655; 探针=2; ⚠ 勿与 gs+1064 difficulty_settings 块 13999 混同) + gameplaysettings@1576 + CArmy* 数组@1600 (探针 37 项) + selection-groups 容器@1624 (每国 240B 组集, 块 10286) + pdx@1648 (空) + CWorldThreat@1712 (键 11261) + saved_event_target@1728 (元素 112B) + pdx@1752 + division_templates@1776 + equipment@1800 + game_unique_seed@1824  |  | |
| +1832 | — | game_unique_id SSO 串头 (键 15232) | | |
| +1833..+2167 | — | = game_unique_id 串体 {size@1848, cap@1856} + land/navy combat id@1864/1868 + CNonstaticIdGenerator 五连@1872..1951 + CIdCounterStore@1952 (双子容器@1960/@1984) + 未命名 152B@2008..2159 + 残渣@2160..2167  |  | |
| +2168 | — | average_major_ic u64 (键 13885) | | |
| +2169..+2231 | — | = average_major_ic u64@2168 (键 13885, AE590 通道) + logmgr@2176..2199 + all_playthrough_data RH map@2200 (门 u32@2216; 探针 gate=1/mask=7/dm=5/lf=0.9) + statistics byte@2232  |  | |
| +2232 | — | statistics_collection_enabled u8 (键 15933; writer sub_1401F2DD0) | | |

⚠ token 防混: threat@gs+1712 = 11261 / CVariables@gs+2432 = 10826 /
region 块 = 10827。

#### 4.1.3 CCurrentGameState 尾段 (+2536..+2618)

gs 单例实为派生类 CCurrentGameState; CGameState 本体 ≈ +0..+2535。

| 项 | 值 |
|---|---|
| RTTI 名 | CCurrentGameState (探针 vtable RVA 0X2721158) |
| sizeof | 0xA40 = 2624 (创建点 malloc 0xA40 + "Trying to initialize gamestate twice" assert, gamestate.cpp:0x6A0) |
| vtable RVA | 双表: vtable1@+0 / vtable2@+8 (vtable2 = 查询接口, provinces loader 经 vtable2+8 取省) |
| writer | — |
| loader | sub_1401E59D0 (**58 case 标签** ×12 段链式 switch(a3), 键空间 10192..19935; case 计数与 §1.2 总表口径差待复核; 双 default: 主链 goto 公共尾非错误 / pending_events 嵌套 default 报 "Error when reading pending event"; writer vtable[2] sub_1401F29A0 显式链式调用与 reader 不对称; 主文件 §1.2 总表 = case→槽位直译 46 案 + ctor 直读 26 案) |
| 挂载点 | gs 单例 (§4.1 获取) |
| ctor | 链 sub_1401BF930 (CCurrentGameState) → sub_1401BFD30 (基) |

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +2536 | 匿名结构 (16B 形状) | **战略空军 region→兵力树** (pdx 容器 {data@+0, 计数@+12 落 +2548}; strategicair.cpp); **元素 32B/项 按区域 id 索引** = {更新小时 int32@+0, 更新时刻 uint64@+8, 逐国 std::map 树头*@+16 (键 = 国 tag int32@节点+32; value+64 区域内空翼计数 / value+68 途经空翼计数 / value+84 有数据门), 在场判据 uint64@+24}; 消费 = 每小时翼解散清扫 (§4.2.10) + "Air missions in region" 调试视图 (sub_141AF81C0 → sub_141AF7460 逐国遍历, 子 toggle "country_selection") | | |
| +2552 | — | 总线头 | | |
| +2560 | 指针 | 三容器对象 (ctor 零填; 复位调 `sub_140DC3B70` 逐容器清 {data@+0/count@+12/子对象@+16} 三组) — 语义待裁 | | |
| +2568 | uint8 | 运行时旗 (全 dump 唯一引用 sub_141AF5D10 置 0, 无读方, 不序列化) | | |
| +2576 | — | 边界色高亮数组 | +2576..+2591; assert "BORDER_COLOR_CUSTOM_HIGHLIGHTS…"; 数量 = dword_143338A64/4 | |
| +2592 | 匿名结构 (NNB 形状)* | reload 总线头 | off_143085170 | |
| +2600 | CBookmark* | **TNullObject\<CBookmark,CBookmark\>\* 空对象句柄** (sub_1401DBBB0 返回全局 qword_14332F350, 创建于 CBookmarkDatabase ctor sub_14067C250) — 非回调 | | |
| +2608 | uint32 | 键 13842 = **tutorial_chapter** | 置位时写 gs+2615=1 并置 gs+192 位域 bit3 = tutorial 旗 | |
| +2615..+2618 | — | 标志区 | | |
| +2615 | uint8 | tutorial_chapter 门 | trigger is_tutorial 消费 (getter sub_1401E2A80 直读) | 定案 |
| +2617 | uint8 | **会话/事件发射门** | 加载期置 0, 开局置 1; transfer_state 系 SetOwner/SetController 第三参极性与 add_to_faction 的 on_offer_join_faction 事件发射门御此位 (两批互证) | 高置信 |


#### 4.1.4 未决清单

| 项 | 结论 | 证据 |
|---|---|---|
| gs+1032 槽 | **区域→(国家link×省) 二维字节查询表** (非管理器) | 无独立 RTTI 类 (负定案); InitGameState 尾 sub_1401E0610 就地构造; 访问器 sub_140E254B0 |
| 双生子 A (+1496) | **CNavalCombatResults\* 按区域 id 索引的 RH 表** (主数组 +1472) | 键 = results+264; loader case 13564 = `naval_combat_result` |
| 双生子 B (+2280) | **cosmetic_tag 串 → CCountryColors\* 的侵入式 unordered_map** (桶 16B {first,last}, mask@+48, FNV-1a 键, list head@+8 自环; 同 §1.2 该槽容器形) | `common/countries/cosmetic.txt` 解析器 sub_1401CCE90 填充; 消费 sub_1401DB180 |
| +2008..+2159 | **CGameStateTimer** (不进存档) | profiling/gamestatetimer.cpp; 写 logs/gametimer_*.tsv; 使能门 byte@+2016 |
| gs+952 RH map | **联合国策焦点 × 国家 连接表** (非 tech_sharing; tech_sharing = 紧邻前格 +928, writer token 14100) | 键 = focus+88, 值 = CCountry\* 数组; 断言 gamestate.cpp:5057/:5072; +980 f32 0.9 = RH load factor |
| +1144 域 | **日期分量缓存** (非预留) | gs hourly tick sub_1401DD370 填入 年/月首累计日/日/年积日/月索引 |
| CGameDate#2@1184 | **start_date** | writer 键 10464 直名 + token 表 1241 行 |
| +2536 | **战略空军 region→兵力树** | strategicair.cpp; pdx 容器 |
| +2600 | CBookmark* | sub_1401DBBB0 返回全局 qword_14332F350, 创建于 CBookmarkDatabase ctor sub_14067C250 |
| +2608 | 键 13842 = **tutorial_chapter** | 置位写 gs+2615=1 + gs+192 bit3 = tutorial 旗 |
| +2240 域 | **tag 工作列表** {d@2240, 计数@2252} (CPdxArray<CCountryTag,unsigned>) | hourly tick 步骤 9 遍历 (查 _AllPlaythroughData@2200, §4.1.8) + DoCareerProfile 族并行容器 (§4.2.6) |
| +2416 域 | **军队状态小时统计累计器族** (hourly) | TOTAL_IN_COMBAT_MAN_HOUR 等 13 键 (名表 builder sub_140F0EF20: 5 TOTAL_* + 3 AVG_* + 5 IS_*); CGameState::HourlyUpdate 首步累加 (§4.2.6); 断言成员名 `_pUnitMetricsCollector` (gamestate.cpp:2314, 对象 0xB8 = 184B) |
| pdx 空位群 已名 12 项 | +760 region 派生表 (region 邻接/共省对缓存, 推定) / +880 `_CountryControllersEnable` / +904 **i8 向量 `_HumanControllersCount`** (SetControllerEnabled 族维护: 接管 `++`/释放 `--`/清零/全清 memset; IsHumanControlled = +880[tag] && !+904[tag]; **双 mutator 实体**: ++ = sub_1401CACF0 (**SP 幂等门 / MP 无门**, server = idler F698 vtable+17 → session+88 RTTI 判 CNetworkServer/CProxyServer) / -- = sub_1401EB7D0 (断言 7746/7749/7755, **尺寸槽 gs+916**, 降 0 记 "AI will control %s"); **增减均经 LightRandomLog OOS 记账环** (sub_142234110 = random.cpp:329, §4.2.7 记录环新消费点)) / +1352 fired_events 向量 (loader case 11003) / +1400 **已删 unit id 集合** {d@1400, cap@1408, c@1412, alloc@1416} (DeleteUnit sub_1401D6690 append / to_be_deleted 登记侧 sub_1401D7460 先查重) / +1472 海战主数组 / +1648 **`MP_locked_countries`** / +1752 scope→saved event target / +2384 **起始日期 u64** (整 qword 写 — dump 唯一写点 = CFrontEndIdler::StartNewGame, gs ctor 不触 2376..2399 区, §4.2.10a) / +2440 **`_CountriesForOriginalTags`** / +2464 战略空军表 | 逐个 ctor/消费者实证 (+2240/+2416 已升独立行) |
| +2440 域 | **_CountriesForOriginalTags** = 按原初 tag 分桶的国家名册 (桶基 = \*(gs+2440) + 24\*tag 下标, 桶元素 24B) | 读 = sub_1401DBD80 (original_tag 触发器族, §4.32 册); 维护 = **sub_1401EE540 original-tag 重登记** (cc+4876 m_OriginalTag 回写 + 旧桶摘除/新桶挂入, Contains/Remove/Insert = sub_1401B0250/B3440/B33B0, 断言 gamestate.cpp:7569, 调用者 = 国管理器域 sub_1407103F0); 定案 (体读) |
| gs+2352 | **未名 pdx 容器数据指针** {d@2352, cap@2360, count@2368, alloc@2376} — 基类 ctor sub_1401BFD30 显式清零 2352/2360/2368 并 @2376 置分配器哨兵 &off_143085170; gs dtor 不触及; 消费者未名 | 基类 ctor + gs dtor 全扫 |
| CPersistent+216 (= gs+216) | 未决 — 仅基类 ctor 初始化, 无消费者 | — |
| gs+1280 串 | runtime-only 定案 — CPeaceConferenceManager 内 SSO, 不序列化 (writer/reader 仅 13632 会议容器; 探针空串互证); 运行期临时名, 写点未定位 | 定案 (性质) / 未决 (语义) |
| 串1 (+16) / "version" 串 (+96) | 串1 = 存档路径串 (sub_140BC07B0 ← 路径 join, 文件名组装消费); "version" 串实为 cosmetic_tag (scanner 键 14127) | 定案 |

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
| sub_1401F29A0 | 0X1401F29A0 | **顶格汇合 writer** (all_playthrough 块 + 15933 + logmgr + ships_built 汇合发射) |
| sub_1401F2E40 | 0X1401F2E40 | **CGameState::Save 主块 writer** (头部标量族键表见下; a3=1 = OOS checksum 模式 — sub_140DA5C80 bit0 路径调本函数全身进流, "Start/End of gamestate checksum" 标记经 LightRandomLog 通道落账, value = 存档流 running hash) |
| sub_1401F2DD0 | 0X1401F2DD0 | all_playthrough_data 块 + statistics_collection_enabled u8@gs+2232 |

覆盖键 (偏移相对其 a1/a3):

| writer | 键 | 挂载/来源 |
|---|---|---|
| sub_140BC2710 | player | — |
| sub_140BC2710 | ideology | 裸串 |
| sub_140BC2710 | date | a3+1136 (24B 对象基 = a3+1120 {vtable1@+1120, hours@+1128, vtable2@+1136 = 序列化指针}) |
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
| sub_1401F2E40 | order_index | 静态 dword_143087260 |
| sub_1401F2E40 | front_index | 静态 dword_143087264 |
| sub_1401F2E40 | theatre_index | 静态 dword_143087268 |
| sub_1401F2E40 | military_deployment_line_index | sub_140CE9540 |
| sub_1401F2E40 | military_deployment_conveyor_index | sub_140CE9530 |
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
| ① | RH map | BASE+54861232 (qword_143451DB0) |
| ② | RH map | BASE+54861240 (qword_143451DB8) |
| ③ | map 对象指针数组 — **8B 步进 ×100 槽** (dump 原文 `v17 += 2` dword 对; 终界 &dword_1434520E0 = debug_current_ref_id) | BASE+54861248 (qword_143451DC0) |

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

块门 = u32@(gs+2216) ≠ 0 (writer 0X1401F2DD0) — **+2216 = 元素计数 count** (读件 sub_1401E5150 drain 逐项递减 / insert 递增直证; 「门≠0」语义 = count≠0, 非独立门字段)。

RH map (gs 侧):

| gs 偏移 | 类型 | 内容 |
|---|---|---|
| +2208 | RH 桶数组* | buckets = rp(gs+2208) |
| +2209..+2219 | — | = RH map 内部 {计数 count@+2216, mask u32@+2220 = 7, distmax u8@+2224 = 5} — gate u32@2216 = 1, lf f32@2228 = 0.9  |
| +2220 | uint32 | mask = ru32(gs+2220) |
| +2224 | uint8 | distmax = ru8(gs+2224) |

桶 24B:

| 偏移 | 类型 | 内容 |
|---|---|---|
| +0 | uint32 | hash (= country 索引; insert 按 hash&mask 定位) |
| +4 | uint8 | dist (0=空; **0xFE=墓碑也须跳** — 残留墓碑桶误收会多发叶) |
| +8 | uint32 | key = tag id |
| +16 | 匿名结构 (NNB 形状) | value ptr |

**写序 = key (tag id) 升序** (writer sub_1401B3900 收集后经 sub_1401B6990
sort; key 写门 tid>0 → 引号三字串)。
> 读件 = sub_1401E5150 (pdx_unordered_map_parser「对象指针值」实例; 唯一调用方 =
> CGameState 块 reader sub_1401E59D0 case 16067); **find-or-insert = sub_1401B06E0**
> (§3.2 RH 机制的函数级落点; 重复键含同原初国等价判定 sub_140BB52F0, 销旧值装新值);
> 值工厂 = sub_1401B1790 (§4.1.9), 空值 = pair 元2 token 357 "none"。

#### 4.1.9 NCareerProfile::SPlaythroughCountryData (wrapper)

| 项 | 值 |
|---|---|
| 类名 | NCareerProfile::SPlaythroughCountryData |
| vtable RVA | 0x2721478 |
| 挂载 | all_playthrough_data RH map 桶值对象; **值工厂 = sub_1401B1790** (malloc 0x9B8 + memset + 双 vtable: SPlaythroughCountryData / SProfileData + 子对象 ctor 链); 加载经 `vt[3]` 多态读 (sub_1424C0AA0; pair 解析器 sub_1401E4B00) |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | SProfileData (2056B) | data = {vtable@+8, first SCareerProfileCountryData@+16 (1008B), second@+1024, tag MSVC-SSO@+2032} | tag **拒绝空串** (人类可读); 换算注: wrapper 相对系 +8/+16/+1024/+2032 ↔ 2056B 数组元素直读系 0/+8/+1016/+2024 (vtable@+0), 两坐标系勿混 |
| +9..+2063 | — | （覆盖行， 无独立残留） |  |
| +2064 | 384B | intermediate_statistics (writer 0X1406AA260) | §4.1.10 |
| +2065..+2447 | — | （覆盖行， 无独立残留） |  |
| +2448 | CFlagManager 内嵌 | flags | 块恒写 (count=0 空块无叶); 布局与同族宿主 §4.13.3 |
| +2449..+2479 | — | （覆盖行， 无独立残留） |  |
| +2480 | uint8 | first_tag | → yes/no 恒写 |

SCareerProfileCountryData 军事统计 max 记录 (偏移相对 SCareerProfileCountryData 基; 每小时写者 = sub_140715A10, 宿主链 = DoCareerProfileHourlyUpdate sub_1401B1C40 直调; 全部 CAS max 语义 — 仅更大才写):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +368 | uint32 | army 数 max | 推进码 4 |
| +372 | uint32 | 舰船总数 max | 推进码 5 |
| +392 | uint32 | 入外国控制省部队数 max | 推进码 46 |
| +544 | 未名 | 工时累计 | 定案 |

#### 4.1.10 intermediate_statistics (wrapper+2064)

**9 个 CTimeSeries** (vtable 0x1429ccb20) 连续内嵌 stride 40 (基址 interm =
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
| +0 | 8B | vtable |
| +8 | uint32 | cap |
| +16 | 元素指针数组* | elem-ptr 数组 ptr |
| +17..+27 | — | = elem-ptr 数组指针 (+16..+23, 8B) 后 7B + pad 4B, 无独立字段 (通用形 {vtable, cap@8, ptr@16, count@28}) |
| +28 | uint32 | count |

元素 = **u32 堆指针** (池化 int, kptr 校验后 deref; writer slot2
sub_1414E5840 逐 count 写)。尾部两标量 (各 malloc 4B 堆 int):

| 偏移 (interm) | 类型 | 名称 |
|---|---|---|
| +368 | uint32 | controlled_provinces = uint32@rp(interm+368) |
| +376 | uint32 | province_gaining_weeks_intermediate = uint32@rp(interm+376) |

#### 4.1.12 SCareerProfileCountryData (blob 164 键)

| 项 | 值 |
|---|---|
| 类名 | SCareerProfileCountryData |
| sizeof | 1008B {vtable@0, 字段@+8..} |
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

#### 4.1.12a 前端生涯档案视图刷新 (frontend_career_profile_view.cpp; 1 函 = 0x141CCBD40, 高置信)

会话已开始门 = idler qword_14332F698 **vtable+880 = GetGameLobby** → IsGameStarted() 真 → :49 断言 "!GetCurrentIdler()->GetGameLobby()->IsGameStarted()" (闩 byte_14338C529); 名源 = sub_140A31BB0 返回对象的 **vtable+104** (std::string 出参槽); 装填 sub_141EF7D30(a1+1400, 名) → 收尾 sub_141EF8100(a1+1400) (a1+1400 段语义 = 列表, 推定)。未决: 三管理器调用 sub_14061CD20/sub_140620EC0(v4,1)/sub_140620A60 语义与 sub_140A31BB0 返回对象类名。

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

#### 4.1.17 gamestate.h 巨簇形态学与未收槽抽查 (定案)

- **簇机理**: gamestate.h 簇 4538 函数 = 全游戏 gs 消费面并集 — 两访问器 debug 门 (断言 1125/1126 latch byte_14332ED00/ED01 + 1116/1117 latch EDF9/EDFA) 强制内联进消费函数, 4536/4538 (99.96%) 直引 gs 单例 qword_14332F260, 仅 2 例外 (引用计数独立助手 sub_1401AAA50/sub_140193F90)。分族: GA 3563 / GB 726 / MIX 239 / REF 守卫 7 / AI 禁入包装器 3; 实现本体 57 函数在 gamestate.cpp 簇 (重叠 17)。
- **方法学警示 (定案)**: 门内联 ≠ a1 是 gs — 0x140DC-0x140DE 区函数 (sub_140DC53C0 等) 带门但 a1 = tutorial 管理器 (+2400/+2412 数组按 gs+2608 tutorial_chapter 索引), 这些偏移不是 gs 槽。
- **簇内新增形态定案 (浅扫批次)**: ① 访问器**半开第三形态** — sub_1402CF070/sub_140A70820 仅剩 :1126 ForbidCount 门 (GA/GB 之外编译器裁剪形); ② gs+8 vtable2 (CProvinceProvider) **接口槽调用形态** = 巨簇第二高频消费面 (`(*(vtable***)(gs+8)+N)()` 内联省查询, 反编译呈现为 `qword_14332F260 + 8` 易误读为数据偏移); **槽语义首件 = vt[0] 按省 id 取 CProvince\*** (§4.34.36 邻省择优器 id→省 roundtrip 直证; **vt[1] 同形 id→CProvince\***, 铁路炮 presence BFS 邻接链直证 id→省→+184 描述符→desc+112 邻接全链通, 双槽同语义; **供应节点装载器 sub_140EB6340 第三消费者** — 实参 = `map/supply_nodes.txt` 次列省 id, 返回值立即被 +400 按 CProvince 内嵌 CBuildingStatus 消费 (§4.21.1a-4 静态数据源), 三路独立互证);**vt[+16] (第三槽) = 按容器 token 取容器数组** — 实参 **2144** = 省数组
{CProvince\*[] data@+0, cap@+8, count@+12} (渐变边框管理器簇直证: 温度地图模式缓存重建 0x140F3A0D0
case 14 与 0x140F3A680 case 9 均经此槽取省容器; 与 vt[0]/[1] 的 id→单对象语义正交); ③ **CGameState vtable1 槽[9] (+72) = 高频 count/查询方法** (全语料 97 调用点; 无参形作循环上界, 带参形返 count 供 scoped_buffer 分配 `4×count` / `(count+7)&~7` memset 0xFF 两形态 — 候选国家数/省数族 getter, 运行时经 vtable 槽[9] 函数指针 RVA 定名); ④ 高频 gs 偏移惯用式全部对上 §1.2 零未录 (玩家 tag 对 1312/1316 fallback / 州 712/724 / 省数 700 / 区域 736/748 / CArmy 计数 1612 / 日期 1128 / 补给 984); ⑤ gs 访问器 out-of-line 三件套 sub_140BB48F0 (tag→国) / sub_140BB5490 (tag→索引) / sub_140BB52F0 (同原初国; 2 参 = tag 指针 + tag **值** u32, 作 gs+832 表下标 — IDA 全调用点因 edx 寄存器复用丢第二参) 200+ 调用点; 第四形态 **sub_140BB4390** = `if (*tag) idx = sub_140BB5490(tag) else 0; return *(gs+784 国表 + 8*idx)` (gamestate.h:1116/1117 断言对, latch EDF9/EDFA; 体内即调 sub_140BB5490 = 三件套组合形非独立克隆); ⑥ gs+260 = 同步校验对象 (+248 对象+12) 运行时读者群 = peacetelemetry / CFrontEndGameSetupView / CHumanItem / sub_140CDFA60 / CCountryDiplomacyView::BuildTooltip (§4.30.64); **条目布局 = 160B {名串@+32, tag@+112}** (§4.30.64 直证; 语义推定 = 人类玩家描述符数组, USER_NAME 键直证)。
- **反编译偏移伪影与下标形 (方法学)**: ① `(int*)gs+328` = 字节偏移 1312 (类型化指针步进缩放, 读侧必须归一); ② `*(_QWORD*)gs + 72LL` 是 **vtable1 槽[9] 调用形** (+72 作用于解引用后的vtable指针), 裸读假报 gs+576; `**(gs+1)` 假报 gs+1 — 剥伪前扫描器必错; ③ gs 槽消费另一主形态 = **下标形** (`*(gs_dword+328)`=+1312 / `+181`=+724 / `+89q`=+712 / `+175`=+700 / `+123q`=+984 / `+126q`=+1008 / `+213q`=+1704 / `+127q`=+1016, 全部对上 §1.2); 残量片 gs 直引密度锐减, 主通道 = out-of-line 访问器三件套; ④ **vt[0] 调用第三种 IDA 呈现** = vtable*** 算术形 `v28 = (vt***)gs; (*v28[1])(v28+1, id)` (`v28[1]` = *(gs+8), 与 ② 的 `**(gs+1)` 同一调用, 勿当数据偏移); ⑤ **vt[0] 结果丢弃形** (sub_142018B20) — 门内联后编译器消除返回值, 仅留门副作用, 扫描器见此形勿判「调用无语义」; ⑥ **双门函数形** (sub_142013630) = gamestate.h:1125/1126 门 + gameitemdatabase.h:142 "Instance not created." 第二门 (闩 byte_14332FD81 / qword_14332EDC8); ⑦ **VA 段分布 (0x142 段族实证)**: gamestate.h 全簇 4538 = 2318×0x141 + 2173×0x140 + 47×0x142 (0x142 段占 1.04%, 全为 GUI 视图构建器 / AI 目标收集器域, 无 gamestate.cpp 实现本体); 0x142 段 47 个中 31 个未收 (航空联队重组 6 / 王牌选拔 1 / 国策焦点树 4 / 装备市场 8 / 科学家技能 2 / 海岸防御 2 / 省名解析 5 / AI 海军训练目标 1, 余 2 域未定域), **归一后零新 gs 槽** (全部读 +736/+748/+784/+796/+1128/+1312/+1316/gs+8, 对上 §4.1.1)。
- **未收槽抽查**: **gs+2528 = ships_built map 的 _Mysize** (16B map 形 {head@2520, size@2528}; 插入点 `0x666666666666666` 比对 = STL `_Xlength_error("map/set too long")` 通用守卫非业务语义; ships_built 节点 = {_Left/_Parent/_Right/NIL@25, key@28, value@32} 高置信); **gs+2504 未名 map = runtime-only** (无 loader case 无 writer, dtor sub_1401C2620 在基类 ctor unwind; 语义推定 trade route 相关, 待裁)。


**NCareerProfile 统计面增补**: 统计组选择器 = 0x140696180 (码 0 = 组A@+8 / 1 = mod 组线性查 a1+64 {96B/组: 名串@+8, 统计载荷@+40}, 计数 +76 / 其他 = 组B@+88); 全局 mod 键串 @0x143089120/130/138; mod 无组断言 "Requesting statistics for mod without a statistics group" (career_profile.cpp:1868)。统计读入双入口 = 0x14069DEB0 (SReadAdapterV1 包 SCareerProfileStatistics) / 0x14069DFB0 (SStatsReadingAdapterV2 三引用), Parse 驱动 = sub_1424C0AA0, CFileException 吞并恒返 1。逐国档案访问器三件 = 0x14068F480 (first@元素+8) / 0x14068F340 (second@元素+1016) / 0x140695E20 (tag 串直入 + a3 静默旗); 未命中一次性断言 "No data entry for the requested country." (:1356/:1384, 旗 byte_143330B82/B84) 后回退静态哑元 unk_143330780。

#### 4.1.18 gamestate.h 巨簇逐实例映射方法链 (定案)

1992 个无标签 gs 消费大函数 (§4.1.17 巨簇的未命名子集) 的逐实例归属判定方法链, 五切片全量跑通; 规则可对任何「断言站点内联簇」复用。

| 规则 | 判据 | 强度 |
|---|---|---|
| **R1** | 命名表 (`func_names_1193.tsv`, 键 = VA **十进制**) 的 slot/rtti 档名直取 | 最强, 定案级 |
| **R2** | PE vtable 成员扫描 (vtable 落 .rdata, `fileoff = RVA − 0x1A00` 该节成立) | 强, 但只作类级佐证 |
| **R3** | 具名直接 caller (caller 类前缀 = 宿主类) | 强 |
| **R4** | callgraph k-hop 祖先 (无具名 caller 时) | 中 |
| **R5** | 本地化键串 / 用法提示串 | 中 |
| **R6** | 地址邻域具名簇 (同段紧邻同族函数) | 弱, 佐证 |
| **R7** | 语料 + PE 双零引用 + `char* f(char* buf, ...)` 签名 + 用法提示串 ⇒ 控制台命令 functor | 特形 |

- **证据优先级 (含反例, 定案)**: 命名表 rtti/slot 名 > 自身 loc 键 > caller vtable > caller 串。caller 域证据可跨域错判 — `CLandBorderWarCombatant::[19]` / `CNavalMissionMapIcon::[21]` / `CSubUnitSimpleEntry::[0]` 三件被 caller 证据错判, 命名表名纠正。
- **caller 三形态 (判别力强)**: 语料零直接 caller 且仅经 vtable 间接 = 虚方法 (R1 名即类); 语料 + PE 双零引用 = 静态注册表/初始化器引用的 functor (控制台命令形, R7); 有具名直接 caller = 宿主属 caller 类或其共享助手 (R3)。
- **R2 陷阱**: region 步会把 vtable 命中错归相邻未录入 vtable (实测 7 例此类), 故 R2 只作类级佐证不作定名; vtable 扫描的偏移方向见上表注 (.rdata 专属, 余节 delta 不同 — .text 0xC00 / .data 0x1E00)。
- **门站点多寡分布 (语料全簇直证, 补 §4.1.17)**: 含 gamestate.h:1125 断言串的 **4502** 函数中, 单站点 **3497** / 双站点 **678** / 三站点 **188** / ≥4 站点 **139** (最高 26 站点) — 访问器按调用点逐次内联, 同宿主多个 gs 访问点各自内联一份门; 多站点宿主 = 一个函数内多次调 GetGameState() 的重入形态。
- **R7 捞出 11 个控制台命令 functor** (推定, 待 §4.33 命令注册表对拍定实名): 语料与 PE 双零引用, 签名 = `char* f(char* buf, args)` + 用法提示串; 代表 sub_140240620 (建筑血量增删, 串 "Please specify <building type> <state or prov id> <health to add>" / "Building type not found")。
- **工具链陷阱 (定案)**: ① 命名表键为 VA **十进制**, 按 `sub_` 名查零命中; ② 语料 `_fnoff.tsv` 非 VA 有序, `bisect` 查找会静默返回错误函数 (须建 `{VA: 偏移}` 字典直查); ③ `(int*)gs + N` 非 8 对齐下标形 = 类型化指针步进伪影, 字节偏移须归一 (同 §4.1.17 伪影条)。

#### 4.1.19 CGameState 派发族与门控函数补遗（389 函）

| VA | 语义/证据 |
|---|---|
| 0x1420902A0 | 结构体拷贝/序列化路径 24B 步长 std::string 逐成员拷贝+`SSubsystemReader` vtable 起手；同址含 `autosave_date_`/`mod/`/`.hoi4`/`Failed to write save file`（ingameidler.cpp）——ICF 合并体，见… |
| 0x141511CE0 | 流亡军抵消息构建 `EXILE_MESSAGE_ARRIVED`/`EXILES_ARRIVED_TITLE`/`SENDER`/`RECEIVER`/`COUNT`/`LOCATION`+`EXILE_MESSAGE_RETURNED`，loc 键拼装 |
| 0x141385C60 | GUI 窗口构建器 FNV-1a 名字哈希（初值 0x811C9DC5/乘 16777619）查表 + `focus_tree_alternate_icon_button_container`/`stats_grid`/`design_team_icon`/`NAVAL_DOMINANCE_TECH_TREE`；… |
| 0x1401CFE40 | CGameState 地图校验 `MAP_ERROR: State ... has provinces belonging to different strategic areas`+`MAP_ERROR: Definition for state id ... missing or invalid`（games… |
| 0x141919310 | MIO 装备头分区构建器 被以 `INDUSTRIAL_ORG_EQUIPMENT_HEADER_DESIGN_TEAM_BONUSES`/`..._MANUFACTURER_BONUSES` 为标题调用（分区索引 1/2 递归）；同址含 `CWeatherEntry`+CMapGenerator 串——ICF … |
| 0x14146B080 | CFactionTabSection `tabs`/`rules_tab_button`/`research_tab_button`/`army_tab_button`/`Intelligence_tab_button`/`goals_tab_button`+`CFactionTabSection` vtable |
| 0x1419A83F0 | CGameChat::[8] `CHAT_WHISPER`/`CHAT_GLOBAL`/`own_chat_indicator` 聊天渲染；同址含 country.cpp 网格/碰撞 `tock: %lli. Str Hash: %u.`——ICF 合并体，见第 4 节 |
| 0x140B278F0 | 理念组提醒 UI `alert_pick_new_idea_group_type`/`alert_pick_new_idea_delayed`/`ALERT_RIGHTCLICK`+`CIdeaGroupType` vtable |
| 0x141EFE000 | 科技统计差异 tooltip `STAT_TOOLTIP_DESIGNER_DIFF`/`technology_unit_stat_item`（pdx_scopedptr.h:119 断言带） |
| 0x140FB45C0 | 海军探测概率说明 `NAVAL_DETECTION_CHANCE_DETAILS_TRUE_VAL`/`..._DECRYPT`/`NAVAL_DETECTION_CHANCE`+`SUR`/`SUB` |
| 0x141116890 | CSendVolunteerAction::GetAiAcceptanceFactors `DR_THEM_PUPPET`/`DR_VOLUNTEER`/`DR_STRATEGIC_HOSTILITY`/`DR_OPINION` 评价因子表 |
| 0x141F65440 | CRailwayGunViewEntry `unit_name`/`unitlist_exiled_icon`/`low_supply`/`no_orders`+`CTooltipHandler`+`CRailwayGunViewEntry` vtable，列车炮单位列表条目 |
| 0x14145CEE0 | 特殊项目产出说明 + 地图纹理清单同址 `SPECIAL_PROJECT_RESEARCH_OUTPUT`/`SPECIAL_PROJECT_OUTPUT_MODULE` 与 `map/heightmap.bmp`/`map/terrain/*` 纹理路径表——ICF 合并体，见第 4 节 |
| 0x1420AB9F0 | CMapIdler 方法（CMapIdler::[17] 邻接） `Successfully loaded PdxMesh`/`Could not find Particle`/`previewer_spawn_particle_edito`+单位统计键 `TOTAL_IN_COMBAT_MAN_HOUR`/`P… |
| 0x141258010 | 地图箭头处理（maparrow.h:327 邻接） 被 CGraphicalMap 区段 0x140B58470 调用，__m128 返回，字符串构建 |
| 0x141B52240 | CDBNudger::[6] `RANDOM_AIR_ACCIDENT_CHANCE_HEADER`/`RANDOM_AIR_ACCIDENT_CHANCE_RELIABILITY`+`\nCoastal = `/`\nTerrain = ` 调参输出 |
| 0x141F4BED0 | 政治总览窗口 `pol_faction_icon`/`country_leader`/`government`/`party`/`elections`/`political_pie_chart`+`CColor` vtable |
| 0x1418F58A0 | 战斗地图图标 `COMBAT_MAP_ICON_CONVOY_DIVISIONS_ENTRY`/`COMBAT_MAP_ICON_CONVOY_FREIGHT_ENTRY`+`FLAG`/`COUNT` |
| 0x142046D80 | 国际市场 Draft/补贴说明 `INTERNATIONAL_MARKET_DRAFT_UNIT_DELIVERY_TITLE_TT`/`PURCHASE_CONTRACT_SUBSIDIES_CONSUMPTION`/`FULLY_CONSUMED_SUBSIDIES`+`CGregorianDate` vtable |
| 0x1419DD660 | 制海权说明 `NAVAL_DOMINANCE_CURRENT_VALUE`/`NAVAL_DOMINANCE_BASE`/`NAVAL_DOMINANCE_NAVALBASE_DESC`/`NAVAL_DOMINANCE_RADAR_DESC` |
| 0x141F76D70 | 装备模块条目 `equipment_module_entry`+`stat_icon_torpedo`/`stat_icon_light_gun`/`stat_icon_heavy_gun`/`stat_icon_anti_air`/`stat_icon_anti_sub`+`CEquipmentModuleEn… |
| 0x142054EE0 | CEventWindow `ActorTag.IsValid() &&`（eventwindow.cpp）+`CEventWindow`/`CTooltipHandler`/`CUpdateable`/`CGameDate` vtable |
| 0x141F58880 | 订阅/消息弹窗 `SUB_MESSAGE_`/`CAREER_PROFILE_SUBSCRIBE`/`message_title`/`message_content_image_` |
| 0x141FD2370 | CProductionLineRailwayGunItem `production_railway_gun_line_entry`+`unit_name`/`mission_state`/`air_mission_efficiency_strip`+`CProductionLineRailwayGunItem` … |
| 0x14154CE00 | 特工招募说明 `CANNOT_RECRUITE_OPERATIVE_NO_SLOT_DESC`/`CANNOT_RECRUITE_OPERATIVE_MAX_NUMBER`/`CREATE_AGENCY_BLOCKED`/`OPERATIVE_SLOT_UNLOCK_IN_DAYS` |
| 0x140B9EC40 | 师模板子单元校验 师模板子单元校验；断言 divisiontemplate.cpp:702 + "Invalid SubUnit in division" |
| 0x141916E60 | MIO 装备头说明 `INDUSTRIAL_ORG_EQUIPMENT_HEADER_NOT_MATCHING_CONTEXT`/`..._DESIGN_TEAM_BONUSES`/`..._MANUFACTURER_BONUSES`/`..._AFFECTED_EQUIPMENT` |
| 0x141381E20 | 国策树视图窗口槽 国策树视图窗口槽；断言 nationalfocusview.cpp:2482 + "nNextChildNode <= ChildNodes.GetSize()" |
| 0x140280E90 | 控制台命令（单位选择+loc 键检查） `Unit selected (`/`Unit cannot be selected because it belongs to`/`Missing loc keys found`+`EFFECT_SET_POLITICS`（ConsoleCmdImpl.cpp） |
| 0x141DBD370 | 生产线筛选窗口 `ship_filters`/`btn_role`/`role_icon_bg`/`production_MIOs`/`available_MI`+`CButtonObserverGlue` vtable |
| 0x14111A5C0 | CGuaranteeAction::GetAiAcceptance func_names 直名+gamestate.h:1125 断言带，外交保证 AI 接受度 |
| 0x141586760 | 流亡政府/合作者总览 流亡政府/合作者总览；串 GFX_icon_collaboration/MANAGE_EXILED_GOVERNMENTS/SHOW_COLLABORATIONS/SHOW_EXILED_STATUS_LEGITIMACY/MANAGE_EXILES_HEADER |
| 0x140BA5670 | 师模板人控判定 师模板人控判定；断言 divisiontemplate.cpp:2503 + "_Country.GetCountry().IsHumanControlled()" |
| 0x141121D20 | CStageCoupAction::[59] `DIPLOMACY_STAGE_GOUP_POLITICAL_POWER_NEED`/`DIPLOMACY_STAGE_COUP_EQUIPMENT_NEED`；同址含 TRIGGER/EFFECT/DYNAMIC VARIABLE 文档转储——ICF 合并体，见第… |
| 0x141E66770 | CTheaterGroupItem `theater_group_item`+`GetPtr() != 0`（ref.h:83）+`CTheaterGroupItem` vtable |
| 0x141EA6BF0 | CIntelLedgerAirPanelController::[0] `INTEL_LEDGER_DEPLOYED_AIR_MANPOWER_COUNT`/`LEDGER_TOTAL_PLANE_COUNT`/`NO_INTEL`/`RANGE` |
| 0x140B9F690 | 师模板名称/描述生成 `FOREIGN_TEMPLATE_DESC`/`COLONIAL_TEMPLATE_DESC`/`EXILE_TEMPLATE_DESC`/`COUNTRY_ADJ`/`COUNTRY_DEF`（divisiontemplate.cpp 邻接） |
| 0x140679A80 | 自治状态消息 `DIPLOMACY_MESSAGE_SUBJECT_AUTONOMY_LOWERED_TITLE`/`..._INCREASED_TITLE`/`..._LOWERED_BODY`+`OVERLORD`（autonomousstate.cpp 邻接） |
| 0x1417175E0 | 国家建造视图 国家建造视图；断言 countryconstructionsview.cpp:1080 + "pNewItem &&" 断言 |
| 0x141F13E00 | 自定义地图模式/规则窗口 `change_rule_item_container`/`Custom Map Mode #`+`CCustomMapMode`/`NFactions::NUi::CChangeRuleItem`/`CButtonWrapper` vtable（custom_map_mode.cpp） |
| 0x14152C780 | 装备/生产资源说明 `EQUIPMENT_MODULE_STAT_AVERAGED`/`PRODUCTION_RESOURCES_PER_FACTORY`/`PRODUCTION_MATERIAL_VAL` |
| 0x141F681F0 | CTraitAssignmentConfirmation::[14] `CONFIRMTRAITASSIGNMENT`/`CONFIRMTRAITASSIGNMENT_DESC`/`UNIT_LEADER_ASSIGN_TRAIT_COST_TOOLTIP`+`TITLE`/`LEADER`/`TRAIT` |
| 0x141A3C1A0 | AI 兵力集中评估 AI 兵力集中评估；断言 ai_force_concentration.cpp + pdx_scoped_buffer.h:54 + 串 "pContext" |
| 0x1406C4DE0 | CCountry 回调 `on_unit_leader_created`（country.cpp:8102）+eventscope 断言 |
| 0x140DB9A40 | 军官视图 `countryofficercorpview`/`divisioncommanderwindow`/`CShipCaptainWindow`+`NAVAL_INVASION_LACK_TRANSPORT`/`NAVAL_INVASION_PREPERATION_SPEED`+3 个 vtable |
| 0x141E8E5A0 | MIO UI 上下文 MIO UI 上下文；断言 industrial_org_ui_context.cpp + 串 INDUSTRIAL_ORG_PP_COST/VALUE + "Bad mode" |
| 0x141E60470 | 集团军框背景 GUI 集团军框背景 GUI；串 army_group_box_bottom_bg/army_group_box_middle_bg；断言 pdx_scopedptr.h:119 + "_pPtr" |
| 0x141E1F050 | 特遣舰队编辑器子单位选择窗口 `task_force_composition_editor_sub_unit_selection_window`/`sub_unit_list_window`/`sub_unit_box`+`CButtonObserverGlue` vtable |
| 0x1411966A0 | CEvolveShipImgui::[4]（func_names 名） func_names 名 + 串 "ship_hull_submarine"/"ship_hull_light"/"ship_hull_cruiser"/"ship_hull_heavy"/"carrier"：舰船演进 imgui |
| 0x140F701D0 | 生产维修/海军运输描述 生产维修/海军运输描述；串 PRODUCTION_REPAIRING_ETA_DATE/PRODUCTION_REPAIRING_PAUSED_NAVAL_TRANSFER/CONVOYS/NAVAL_TRANSPORT_MOVE_DESC(_ICON)/NAVAL_TRANSPORT_I… |
| 0x141685840 | CWindow 派生容器更新（12 子项，sub_1402A69E0 x12 作用于 a1+1/+49/+65…） CWindow 派生容器更新（12 子项，sub_1402A69E0 x12 作用于 a1+1/+49/+65…）；父容器直接调用（调用点传 a1+96/a1+1384），非 vtable 槽 |
| 0x141C2E7C0 | VT CSaveDesignToFilePopUp + 调 CSaveDesignToFilePopUp::OnSetupDerived + 串 "save_to_file_popup" VT CSaveDesignToFilePopUp + 调 CSaveDesignToFilePopUp::OnSetupDe… |
| 0x1424E8170 | 控制台命令执行器 控制台命令执行器；串 "Unknown command"/"Console not available in multiplayer or ironman mode."/"Console Error - command has missing action."/"Command availabl… |
| 0x140283B70 | 控制台命令参数解析/设值 控制台命令参数解析/设值；串 "Incorrect value"/"Incorrect number of arguments"/"Incorrect num days"/": Flag "/" set to " |
| 0x140165DE0 | 数据库装载查重 数据库装载查重；串 "Duplicate database id " |
| 0x140223C90 | 编辑器公式解析（指数/一元运算） 编辑器公式解析（指数/一元运算）；串 "arg^num : "/"args^"/"01234567890.+-"；邻域 HOI4EditorInterface::[4]/[8] |
| 0x141915C50 | MIO 修正 tooltip MIO 修正 tooltip；串 INDUSTRIAL_ORG_DETAIL_MIO_MODIFIERS_BASE/FROM_COUNTRY/FROM_TRAITS/TOTAL + VALUE |
| 0x1424B4D60 | 控制台命令分发/帮助 控制台命令分发/帮助；串 "Unknown command"/"Console Error - command has missing action."/"Command available only for developers."/"Console not available in mu… |
| 0x1405313B0 | character_formatter.cpp:162 断言 + 串 "country_leader_desc"/"Specified character:"/"does not have an ideology for scripted ideology group" character_formatter.c… |
| 0x140CB24E0 | 贸易视图资源产出明细 贸易视图资源产出明细；串 TRADEVIEW_RES_PRODUCED_DETAILS；邻域 CResourceExchange::[17]/CResourceOrigin::[17]/CCountryResources::[4] |
| 0x141B0BAA0 | AI 特质/ai_will_do 评估调试输出 AI 特质/ai_will_do 评估调试输出；串 "ai_will_do = "/"Traits (pre-computed)"；邻域 CEvolveTankImgui::[7]/[8] |
| 0x14133D5E0 | 多人聊天错误提示 多人聊天错误提示；串 CHAT_ERROR_KICK_MISSINGARG/CHAT_ERROR_KICK_NOTOPERATOR/CHAT_ERROR_KICK_NOTTHERE/CHAT_ERROR_UNKNOWNUSER；邻域 CChat::CChatItem::[7]/CChat::[5] |
| 0x141CDAFF0 | 前端剧本选择视图 前端剧本选择视图；串 GAMESETUP_SELECT_SCENARIO/interesting_countries_button/scenario_window/observer_button |
| 0x140121460 | 多人会话信息构建 多人会话信息构建；串 "client"/"server_name="/"player_name="/"num_clients=" |
| 0x140B2F770 | 特殊项目可用提醒 特殊项目可用提醒；串 SPECIAL_PROJECT_AVAILABLE_ALERT_TT/SPECIAL_PROJECT_AVAILABLE_ALERT_DELAYED_TT |
| 0x14006D340 | 串表 "Do, or do not, there is no try"/"Ross rifle, best rifle"/"The T34 is the best tank of the war" 等 串表 "Do, or do not, there is no try"/"Ross rifle, best ri… |
| 0x141CC47C0 | 学说文件夹视图 学说文件夹视图；断言 folder_view.cpp:292 + SUB_DOCTRINE_SELECTION_TITLE/"Invalid track index for sub-doctrine selection"/"Track item not found for sub-doctrine… |
| 0x141B462C0 | CBuildingsNudger::CollectReloadNames：CBuildingsNudger::CollectReloadNames CBuildingsNudger::CollectReloadNames；串 "Select Building type"/"Select state"/"Selec… |
| 0x141AE1270 | AI 政治部长 imgui 调试面板 AI 政治部长 imgui 调试面板；断言 ai_pp_spend_imgui.cpp:67 + "Become spymaster"/" Specialization: "/"Found no ID string for CAIPoliticalMinister::SWei… |
| 0x140E82E70 | NRaids 系统迭代器 NRaids 系统迭代器；串 "NRaids::IterateAir"/"NRaids::IterateArmy"；邻域 NRaids::CRaidSystem::[0] |
| 0x14112C7A0 | CRequestForeignManpowerAction::GetRequestDescText：CRequestForeignManpowerAction::GetRequestDescText |
| 0x140504720 | gamestate 门控 + 断言 script_collection_input_impl.h:184 + 串 "Failed to find state with id: %d" gamestate 门控 + 断言 script_collection_input_impl.h:184 + 串 "Failed … |
| 0x1413BB510 | 后勤库存状态判定 后勤库存状态判定；串 LOGISTICS_INSTOCK_BALANCED/LOGISTICS_INSTOCK_DEFICIT/LOGISTICS_INSTOCK_SURPLUS + EQUIPMENT/INSTOCK |
| 0x1421DBC20 | GUI 文本布局/对齐 GUI 文本布局/对齐；串 "%*s%.*s"/"CR-LF 前缀的 %*s%.*s 变体"/CLOSE/COLLAPSE |
| 0x141F1CC60 | 串 "TECH_NAME"/"INDUSTRIAL_ORG_DETAIL_TOOLTIP_FUNDS_PER_RESEARCH_SLOT"/"INDUSTRIAL_ORG_DETAIL_TOOLTIP_FUNDS_FROM_RESEARCHING" 串 "TECH_NAME"/"INDUSTRIAL_ORG_DE… |
| 0x1403864F0 | CPromoteCharacterToCountryLeader::GetDesc：CPromoteCharacterToCountryLeader::GetDesc CPromoteCharacterToCountryLeader::GetDesc；串 EFFECT_ADD_COUNTRY_LEADER_ROL… |
| 0x14235F540 | CProgressbarSpriteType::[9]（func_names 名） func_names 名 + 串 "Texture"：进度条精灵类型 |
| 0x141DF4440 | 默认确认弹窗构造 默认确认弹窗构造；串 "default_confirmation_popup"；断言 ref.h:83 + "Probably an error." |
| 0x140C16DB0 | 干员状态描述生成 干员状态描述生成；串 OPERATIVE_CAPTURED_BY/OPERATIVE_FORCED_INTO_HIDING/OPERATIVE_AVAILABLE_AGAIN_IN_DAYS/OPERATIVE_CAPTURED_DAYS_REMAINING + CAPTURER |
| 0x14055C210 | 修正条目窗口槽（12 参族） 修正条目窗口槽（12 参族）；串 "VALUE"；邻域 CTimedModifier::[0]/CPdxModifier::GetAllEntries?/CDynamicModifier::[7] |
| 0x1421DEA20 | 窗口/控件尺寸调整 窗口/控件尺寸调整；串 "#RESIZE"，浮点布局数学 |
| 0x14186F8F0 | gamestate 门控 + 串 "playerlobby_chat"/"chatlog_window"/"number_chatmessage"/"MULTIPLAYER_MESSAGES" gamestate 门控 + 串 "playerlobby_chat"/"chatlog_window"/"number… |
| 0x141EA81A0 | CIntelLedgerAirPanelController::CLedgerAirwingHeaderEntry::[0]：CIntelLedgerAirPanelController::CLedgerAirwingHeaderEntry::[0] CIntelLedgerAirPanelController:… |
| 0x1422337A0 | VT std::ostringstream + 串 "random_fixed: "/"random_float: "/"random_int: " + 调 CArchiveFile::[6]/[7] |
| 0x141F1C6C0 | 串 "EQUIPMENT_NAME"/"INDUSTRIAL_ORG_DETAIL_TOOLTIP_FUNDS_PER_PROD_LINE"/"INDUSTRIAL_ORG_DETAIL_TOOLTIP_FUNDS_FROM_PRODUCING" 串 "EQUIPMENT_NAME"/"INDUSTRIAL_OR… |
| 0x140276570 | 陆军师平均属性计算 陆军师平均属性计算；串 "avrg org = "/"avrg str = "/"no unit selected" |
| 0x141113D20 | CRequestForeignManpowerAction::GetAiAcceptanceFactors：CRequestForeignManpowerAction::GetAiAcceptanceFactors CRequestForeignManpowerAction::GetAiAcceptanceFac… |
| 0x140AC1F90 | 断言 strategic_resource_database.cpp:88 + 串 "Strategic resources loaded '" 断言 strategic_resource_database.cpp:88 + 串 "Strategic resources loaded '"：战略资源库装载 |
| 0x1404D06D0 | 脚本集合 ForEach 求值器 脚本集合 ForEach 求值器；断言 eventscope.h:193 + script_collection_evaluator.h:230 + 集合类型串 "country" |
| 0x140E30F50 | 断言 peaceconference.cpp:2724 + 串 "!CountriesBidding.empty() && \"This should not be empty\"" 断言 peaceconference.cpp:2724 + 串 "!CountriesBidding.empty() && \"T… |
| 0x141B0D2F0 | AI 评估调试输出 AI 评估调试输出；串 "Cic: "/", Condition: "/", For: "/", Targets: "/"Traits (pre-computed)"；邻域 CEvolveTankImgui::[7]/[8] |
| 0x140A02F50 | gameitemdatabase.h:142 断言 + 串 "Expected 'default', a continent name or a country tag" gameitemdatabase.h:142 断言 + 串 "Expected 'default', a continent name or … |
| 0x14207FC00 | VT std::ifstream + 串 "console_edit"/"console_list" VT std::ifstream + 串 "console_edit"/"console_list"：控制台编辑/列表命令 |
| 0x140E7C680 | 海军运输/护航描述 海军运输/护航描述；串 NAVAL_TRANSPORT_MOVE_DESC(_ICON)/NAVAL_TRANSPORT_INTERCEPT_WARNING/CONVOYS |
| 0x140B246C0 | 串 "alert_got_raided_instant"/"alert_got_raided_delayed_header"/"RAID_TYPE_NAME" + 调 CNavalBaseConvoyClient::[15] 串 "alert_got_raided_instant"/"alert_got_raid… |
| 0x141F2C9D0 | gamestate 门控 + pdx_scoped_buffer.h:54 断言 gamestate 门控 + pdx_scoped_buffer.h:54 断言：gamestate 门控的缓冲区写入（同 0x140C74400 形态） |
| 0x141767A30 | gamestate 门控 + 串 "reset_button"/"experience" gamestate 门控 + 串 "reset_button"/"experience"：经验重置按钮 GUI |
| 0x140BA4C50 | 断言 divisiontemplate.cpp:1837 + 串 "_Country.GetCountry().IsHumanControlled()" 断言 divisiontemplate.cpp:1837 + 串 "_Country.GetCountry().IsHumanControlled()"：师模板… |
| 0x141B59AC0 | gamestate.h:1116 门控 ×3，无其他串；vtable 调用 |
| 0x141866310 | gamestate 门控 + 串 "PEACE_END_TURN"/"PEACE_PASS"/"PEACE_END_TURN_EXPECTED_CONTEST"/"PEACE_END_TURN_UNRESOLVED_CONTEST" gamestate 门控 + 串 "PEACE_END_TURN"/"PEACE… |
| 0x1419AA9F0 | （未命名）gamestate.h:1125 + 缩进换行格式串 gamestate.h:1125 + 缩进换行格式串，弱线索 |
| 0x141870920 | CPlayerLobby::[3]：CPlayerLobby::[3] CPlayerLobby::[3]；串 SYSTEM_PLAYER_BANNED/SYSTEM_PLAYER_KICKED/SYSTEM_PLAYER_LEFT/SYSTEM_PLAYER_LOST |
| 0x141C505E0 | 串 "IDEA_WINDOW_TITLE"/"IDEA_WINDOW_SWITCH"/"IDEA_WINDOW_ADD" 串 "IDEA_WINDOW_TITLE"/"IDEA_WINDOW_SWITCH"/"IDEA_WINDOW_ADD"：idea 窗口 GUI |
| 0x141B0B560 | gamestate 门控 + 串 "Military Industrial Organisation Info"/"Organisations"/"Policies"/"Base value (precomputed): " gamestate 门控 + 串 "Military Industrial Organi… |
| 0x140A0B9F0 | 断言 gameitemdatabase.h:142（库单例访问），无其他串 |
| 0x14231BC30 | 匹配制作服务器浏览器过滤 匹配制作服务器浏览器过滤；串 filter_has_players/filter_not_full/MATCHMAKING_SERVERS_SEARCHING；邻域 CMatchmakingGui(Server/Friend)Item |
| 0x1418024A0 | VT CDefensiveStanceItem + 串 "defensive_stand_item"/"CARRIER_DEFENSIVE_STANCE_SELECTION_" VT CDefensiveStanceItem + 串 "defensive_stand_item"/"CARRIER_DEFENSIV… |
| 0x141B58A80 | gamestate 门控 + 串 "Province"/"belongs to multiple states! Select one it should belong to:" gamestate 门控 + 串 "Province"/"belongs to multiple states! Select one… |
| 0x1402AFA40 | 断言 gameitemdatabase.h:281/303/331/336 + 串 "Reloading Database:"/"Cant reload when not loaded" 断言 gameitemdatabase.h:281/303/331/336 + 串 "Reloading Database:"… |
| 0x141E1B070 | 串 "naval_equipment_info_entry"/"REFIT_DESCRIPTION" + 调 CCombatTactic::[9] 串 "naval_equipment_info_entry"/"REFIT_DESCRIPTION" + 调 CCombatTactic::[9]：海军装备改装信息条目 |
| 0x141192D30 | AI MIO 选择评估调试输出 AI MIO 选择评估调试输出；串 "AIWillDo : "/"MIO Tree total value: "/"Return: (Value x AIWillDo)"；邻域 CEvolveShipImgui::[0]/[3] |
| 0x141CC0DF0 | 舰载机联队状态条目 舰载机联队状态条目；串 AIR_WAREHOUSE_LABEL/AIRWING_MISSION_WING_STATUS_(MISSION/RAID/CARRIER_MISSION/IDLE)/AIRWING_TRANSFERRING/AIRWING_MISSION_TRANSFER_CANCE… |
| 0x1414102B0 | 脚本集合 ForEach 求值器 脚本集合 ForEach 求值器；断言 script_collection_evaluator.h:230 + 集合类型串 "combatant" |
| 0x14222CF70 | 以 ".asset" 扩展装载资产文件并逐项建路径 以 ".asset" 扩展装载资产文件并逐项建路径：资产数据库装载 |
| 0x140423F20 | CIsRunningOperation::GetDesc（func_names 名） func_names 名 + 串 "TRIGGER_IS_RUNNING_OPERATIONS"/"TRIGGER_IS_RUNNING_ANY_OPERATIONS"/"OPERATION"：情报行动运行触发器 |
| 0x1414175B0 | 脚本集合 ForEach 求值器 脚本集合 ForEach 求值器；断言 script_collection_evaluator.h:230 + 集合类型串 "operation_instance" |
| 0x141994810 | gamestate 门控 + 串 "CANNOT_REMOVE_FACTION_RULE" gamestate 门控 + 串 "CANNOT_REMOVE_FACTION_RULE"：移除派系规则 |
| 0x141AD2F60 | 串 "GFX_give_role_leader_strip"/"advisor_role_icon"/"advisor_role_traits_icon" 串 "GFX_give_role_leader_strip"/"advisor_role_icon"/"advisor_role_traits_icon"：顾… |
| 0x140F79E40 | 串 "MISSION_TYPE"/"WING_NAME"/"COMMAND_POWER_TOOLTIP_AIR_MISSION"/"COMMAND_POWER_TOOLTIP_AIR_MISSION_UNASSIGNED" 串 "MISSION_TYPE"/"WING_NAME"/"COMMAND_POWER_T… |
| 0x14111F930 | CGenerateWarGoalAction::[59]（func_names 名） func_names 名 + 串 "PROGRESS"/"DAILYCOST"/"MISSING_PP"：战争目标行动 UI |
| 0x14188D2B0 | 仅 gamestate.h:1125 门控断言（调 sub_140CDCC80/sub_141E6D930）；无其他自文档证据，vtable 调用 |
| 0x141D38D80 | 串 "leader_butto"/"strength_progressbar"/"organization_progressbar"/"mission_icon"/"unit_name" 串 "leader_butto"/"strength_progressbar"/"organization_progressb… |
| 0x1419DE470 | 串 "MODIFIER_SCALED_BY" ×2 串 "MODIFIER_SCALED_BY" ×2：修正量按系缩放的提示文本构建 |
| 0x140AE96C0 | 断言 eventscope.h:193 + 串 "TRAIT_PREREQUISITES" 断言 eventscope.h:193 + 串 "TRAIT_PREREQUISITES"：特质前置条件提示 |
| 0x1404D5F90 | 同上 + 类型串 "operation_instance" 同上 + 类型串 "operation_instance"：情报行动实例集合 ForEach 求值器 |
| 0x1404E9090 | 同上 + 类型串 "operation_instance"（与 0x1404D5F90 同型另一实例） |
| 0x1404CDD80 | 同上 + 类型串 "raid_instance" 同上 + 类型串 "raid_instance"：袭击实例集合 ForEach 求值器 |
| 0x1404E1020 | 同上 + 类型串 "raid_instance"（与 0x1404CDD80 同型另一实例） |
| 0x1421EDB20 | 渲染区调试直方图输出 渲染区调试直方图输出；串 "%d: %8.4g"/"%d: %8.4g %d: %8.4g" |
| 0x1404D94E0 | 同上 + 类型串 "character" 同上 + 类型串 "character"：角色集合 ForEach 求值器 |
| 0x1404D1F20 | 同上 + 类型串 "project" 同上 + 类型串 "project"：项目集合 ForEach 求值器 |
| 0x1404E5020 | 同上 + 类型串 "project"（与 0x1404D1F20 同型另一实例） |
| 0x1403C18C0 | 断言 script_collection_evaluator.h:230 ×6 + "Collection operator %s doesn't support [Parallel]ForEach" |
| 0x1404DD570 | 断言 script_collection_evaluator.h:230（无类型串，泛化分支） |
| 0x140E71760 | gamestate.h:1116 门控 ×2（调 sub_140BDC6F0/sub_140C97C90/sub_140BD5440）；无其他自文档证据 |
| 0x140EF34D0 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言） |
| 0x141B79270 | VT CTextBufferObserverGlue<CSubWndPair>/CScrollbarObserverGlue<CSubWndPair> + 串 "sub_wnd_pair"/"slider_m"/"value_mi"/"value_ma" VT CTextBufferObserverGlue<CS… |
| 0x141D757F0 | 串 "track_decision_checkbox"/"cost_and_timer_text"/"btn_progress_good"/"btn_progress_bad" 串 "track_decision_checkbox"/"cost_and_timer_text"/"btn_progress_good… |
| 0x141D169E0 | VT CAbilityListWindow/CButtonObserverGlue + 串 "abilitylist_window" VT CAbilityListWindow/CButtonObserverGlue + 串 "abilitylist_window"：能力列表窗口 |
| 0x1417D9610 | gamestate 门控 + 串 "TOTAL_COST_DEBUG: " gamestate 门控 + 串 "TOTAL_COST_DEBUG: "：成本调试输出（合同/市场成本路径） |
| 0x140B3E3A0 | byte_14332F610 门控下对 34 个桶（a1+824 步长 24）内对象做 vtable+24/+136/+16/+56 生命周期处理并收集 +165 标志对象 byte_14332F610 门控下对 34 个桶（a1+824 步长 24）内对象做 vtable+24/+136/+16/+56 生命周… |
| 0x14028CF80 | 串 "You need to specify a country tag to switch to!"/"has no provinces, switch would resign" 串 "You need to specify a country tag to switch to!"/"has no provi… |
| 0x141D9BA80 | 串 "delete_button"/"equipment_variant"/"LOGISTICS_EQUIPMENT_VALUE"/"LOGISTICS_IN_STOCK"/"weekly_production" 串 "delete_button"/"equipment_variant"/"LOGISTICS_E… |
| 0x1420B2560 | 串 "history.tx"/"previewer_editbox"/"Type 'help' to get instructions"/"Unkown type ... use \"mesh\", \"particle\" or \"entity\"" 串 "history.tx"/"previewer_edi… |
| 0x140CA0260 | 串 "Expected only %d elements" + 调库解析族（sub_14014B4E0/sub_1424C04A0/sub_140158B40/sub_1401516C0，与 ai_area 库装载同族） 串 "Expected only %d elements" + 调库解析族（sub_1401… |
| 0x141C16580 | gamestate 门控 ×3 + 串 "THEATER_ASSIGNED_COUNTRIES"/"THEATER_ASSIGNED_REGIONS" gamestate 门控 ×3 + 串 "THEATER_ASSIGNED_COUNTRIES"/"THEATER_ASSIGNED_REGIONS"：战区分配国… |
| 0x140E84C90 | 断言 raid_system.cpp:638 + VT CBuildingReference + 串 "pProvince && \"controlled province id has no province\"" 断言 raid_system.cpp:638 + VT CBuildingReference +… |
| 0x14133F290 | 按 a1+200 在 192 步长表内查索引，拼 "chat log".txt 路径读文件再逐条（+96/+104 区间）输出 按 a1+200 在 192 步长表内查索引，拼 "chat log".txt 路径读文件再逐条（+96/+104 区间）输出：聊天历史文件读写 |
| 0x141C374A0 | 串 "archetype_na"/"archetype_amount"/"EQUIPMENT_FILL2"/"CURRENT" 串 "archetype_na"/"archetype_amount"/"EQUIPMENT_FILL2"/"CURRENT"：装备原型填充 UI |
| 0x141A94000 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言），无其他线索 |
| 0x140224EF0 | 数据库项注册（gameitemdatabase.h:142 站点） 数据库项注册（gameitemdatabase.h:142 站点）：调 0x1406BC7A0 + 0x142244840 + 0x1401FF2C0 标准注册序列，pdx_scopedptr 内联 |
| 0x141EA9940 | （未命名）gamestate.h:1125 + "_mediu" gamestate.h:1125 + "_mediu"（medium 前缀截串），弱线索 |
| 0x1409BB430 | modifier 库装载 modifier 库装载：VT CPdxHybridInlineBufferAllocator<int,4,int>（混合内联缓冲），STR 'MODIFIER_DOCTRINE_PREFIX' |
| 0x1423E21D0 | 断言 pdx_matchmaking_steam.cpp:1370 + 串 "[MM] OnLobbyCreated: lobby="/"server id="/"join_phase"/"actual_password" 断言 pdx_matchmaking_steam.cpp:1370 + 串 "[MM] O… |
| 0x14144E560 | 构建 4 个 104 字节参数项（键 "PROVINCE"/"SUBJECT"/"TARGET_COUNTRY"/"DATE"）后调 sub_142245E60 带 4 参本地化 构建 4 个 104 字节参数项（键 "PROVINCE"/"SUBJECT"/"TARGET_COUNTRY"/"DATE"）后调 … |
| 0x1403BE9E0 | 断言 script_collection_evaluator.h:230 + 类型串 "faction" 断言 script_collection_evaluator.h:230 + 类型串 "faction"：派系集合 ForEach 求值器 |
| 0x1404E3E90 | 同上（类型串 "faction"，与 0x1403BE9E0 同型另一实例） |
| 0x141C2A750 | 断言 designerbattalionswindow.cpp:211 + 串 "designer_regiments_grid"/"No valid selected slot in division designer" 断言 designerbattalionswindow.cpp:211 + 串 "desi… |
| 0x141BC5E00 | 国策自动跳过 国策自动跳过：STR 'FOCUS_AUTOMATIC_BYPASS_DISABLED'/'AUTOMATIC_BYPASS_DISABLED'/'BYPASS_FOCUS_TRIGER' |
| 0x14204CF90 | 采购合同进度+国策 dump 采购合同进度+国策 dump：STR 'PURCHASE_CONTRACT_PROGRESS_EQUIPMENT_DELIVERED'/'SUNK'/'==== FOCUS IDs ====' + nationalfocus.cpp |
| 0x141BF27C0 | 断言 gameitemdatabase.h:142 + helper.h:22 Null Object + 串 "terrain_grid" 断言 gameitemdatabase.h:142 + helper.h:22 Null Object + 串 "terrain_grid"：地形表 Null Object… |
| 0x14201E3B0 | VT NCareerProfile::CProfilePictureItem + 串 "profile_picture_item"/"profile_picture"/"lock_overlay" VT NCareerProfile::CProfilePictureItem + 串 "profile_pictur… |
| 0x141CE66E0 | VT CFrontendMultiplayerView + 串 "frontendmultiplayerview" VT CFrontendMultiplayerView + 串 "frontendmultiplayerview"：前端多人视图 |
| 0x14192D740 | equipment_model_util.cpp:76 equipment_model_util.cpp:76：STR 'Equipment graphic database model entries for type'/'includes invalid entity'（装备图形模型条目校验） |
| 0x1410994D0 | 串 "NUCLEAR_BOMB"/"COUNTRY_NUCLEAR_PRODUCTION_INFO"/"NUCLEAR_PRODUCTION_NONE" 串 "NUCLEAR_BOMB"/"COUNTRY_NUCLEAR_PRODUCTION_INFO"/"NUCLEAR_PRODUCTION_NONE"：核弹生… |
| 0x1414998A0 | VT CButtonObserverGlue/CDesignerEquipmentRoleItem + 串 "tank_designer_role_entry" VT CButtonObserverGlue/CDesignerEquipmentRoleItem + 串 "tank_designer_role_en… |
| 0x141868FC0 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言） |
| 0x141D68590 | 串 "ongoing_contruction_anim"/"factories"/"CONSTRUCTION_USED_FACTORIES_NUM" 串 "ongoing_contruction_anim"/"factories"/"CONSTRUCTION_USED_FACTORIES_NUM"：在建建筑 GUI |
| 0x141660FA0 | （未命名）gamestate.h:1125 + vtable `CColor` gamestate.h:1125 + vtable `CColor`，颜色计算 |
| 0x1422B1E30 | 对 a1+4384/4432/5104 等 4 组子对象数组逐个调 vtable+280 对 a1+4384/4432/5104 等 4 组子对象数组逐个调 vtable+280：管理器广播/分发（超大对象 5104+） |
| 0x140527B20 | CSetStrategicProvinceLocationBuildingLevel::GetDesc（func_names 名） func_names 名 + gamestate 门控 + 串 "STRATEGIC_LOCATION_BUILDING_HEADER"/"LOCATION"：战略省份位置建筑等级效果 |
| 0x14012C3E0 | 断言 gameitemdatabase.h:882 + VT CAiFleetTemplate + 调 CDiplomaticAction::GetFirstCountryRef 断言 gameitemdatabase.h:882 + VT CAiFleetTemplate + 调 CDiplomaticActi… |
| 0x1419E6F80 | 串 "victory_points" 串 "victory_points"：胜利点 GUI/地图数据 |
| 0x14204B500 | 串 "equipment_icon" + 调 sub_140FCC870/sub_1401F6470 串 "equipment_icon" + 调 sub_140FCC870/sub_1401F6470：装备图标 GUI |
| 0x141476FE0 | gamestate 门控 + 串 "FACTION_THEATER_CREATE_BUTTON" gamestate 门控 + 串 "FACTION_THEATER_CREATE_BUTTON"：派系战区创建按钮 GUI |
| 0x141F54260 | 串 "game_rule_name"/"game_rule_options_dropdown"/"disallow_achievements"/"options_grid" 串 "game_rule_name"/"game_rule_options_dropdown"/"disallow_achievements… |
| 0x14016EA00 | 断言 pdx_scopedptr.h:134 + pdx_robin_hood_table.h:58 + VT CScientistTrait/CModifier 断言 pdx_scopedptr.h:134 + pdx_robin_hood_table.h:58 + VT CScientistTrait/CMo… |
| 0x141220E00 | 断言 country_supply.cpp:3214 + 串 "!_NonLocalNodes.Contains( _pCapital->GetProvinceID() )" 断言 country_supply.cpp:3214 + 串 "!_NonLocalNodes.Contains( _pCapital->… |
| 0x140BAE830 | 断言 gameitemdatabase.h:142 ×3（库单例访问），无其他串 |
| 0x1415F1BE0 | 调 vt+440 取 "ideas" 作用域、vt+432 取 token "id"（25705='id'） 调 vt+440 取 "ideas" 作用域、vt+432 取 token "id"（25705='id'）：idea 槽位脚本解析 |
| 0x1404D7D90 | 断言 script_collection_evaluator.h:230 ×4（无类型串，泛化分支，体积较小 7224） |
| 0x1409E5CE0 | 学说互斥信息（gameitemdatabase.h:142） 学说互斥信息（gameitemdatabase.h:142）：STR 'SUBDOCTRINE_EXCLUSIVE_INFO_TITLE'/'..._ENTRY'/'NAME' |
| 0x141767550 | 断言 gameitemdatabase.h:142 + helper.h:22 Null Object + 串 "terrain_grid"/"adjuster_sta"/"stats_grid" 断言 gameitemdatabase.h:142 + helper.h:22 Null Object + 串 "t… |
| 0x14066BE20 | AI 战略结构序列化 AI 战略结构序列化；邻域 CStrategicAI::SNavalInvasionEntry::Writer/SPortStrikeData::Writer/SRaidAttemptEntry::Writer；gameitemdatabase.h:142 断言 |
| 0x141124650 | CAddWarGoalAction::[21]（func_names 名） func_names 名 + 串 "DIPLOMACY_MESSAGE_ACTION_TITLE"/"DIPLOMACY_WARGOAL_ADDED"：添加战争目标行动 |
| 0x141C8D940 | CDiplomacyCountryAddWarGoalActionController::[4]（func_names 名） func_names 名 + 串 "wargoals_grid"/"additionals_grid"/"cancel_button"：国家添加战争目标控制器 |
| 0x1416250A0 | 串 "TOOLTIP_MAP_ICON_RAID_UNITS_HEADER"/"TOOLTIP_MAP_ICON_RAID_UNIT_ENTRY"/"TOOLTIP_MAP_ICON_RAID_UNITS_DELAYED" 串 "TOOLTIP_MAP_ICON_RAID_UNITS_HEADER"/"TOOLT… |
| 0x14019BD40 | 断言 gameitemdatabase.h:281/331/324/336 + VT NFactions::CFactionRuleGroup + 串 "Cant reload when not loaded" 断言 gameitemdatabase.h:281/331/324/336 + VT NFaction… |
| 0x141B39150 | 以 "nukes" 为键取 a1[7]，按 +1280/+1292 计数构表 以 "nukes" 为键取 a1[7]，按 +1280/+1292 计数构表：核弹列表构建 GUI |
| 0x14012F5A0 | MIO 装备图标项注册（gameitemdatabase.h:882） MIO 装备图标项注册（gameitemdatabase.h:882）：VT NIndustrialOrganisation::CEquipmentIconItem/CEquipmentGroup/CDynamicEquipmentGroup… |
| 0x141199210 | gamestate 门控 + 串 "Invalid arguments count."/"Second argument should be a valid archetype."/"Subsidy added."/"Country Tag is not valid" gamestate 门控 + 串 "Inva… |
| 0x14236F030 | CButtonType::[10] `NOTOOLTIP`/`Please add Text`/`Please add Text To the delayTooltip`，按钮延迟 tooltip |
| 0x140F37A40 | gamestate.h:1116 门控 ×2（调 sub_140E139B0/sub_141596D50）；无其他自文档证据 |
| 0x141001FF0 | 研究时间 tooltip 研究时间 tooltip：STR 'COST'/'VALUE'/'BASE'/'RESEARCH_TIME_TOOLTIP_WITH_XP_COST_FACTOR' |
| 0x141CA0B70 | gamestate 门控 + 串 "additionals_grid"（同 CDiplomacyCountryAddWarGoalActionController 键） gamestate 门控 + 串 "additionals_grid"（同 CDiplomacyCountryAddWarGoalActionC… |
| 0x14012BFC0 | 数据库项构造注册（gameitemdatabase.h:882） 数据库项构造注册（gameitemdatabase.h:882）：0x140147090/0x140134B70 + 1AD740/14B4E0 标准注册序列 |
| 0x14012E9C0 | 数据库项构造注册（gameitemdatabase.h:882） 数据库项构造注册（gameitemdatabase.h:882）：0x140147AE0/0x1401366F0 + 同一注册序列（与 0x14012BFC0 同源对，7019B） |
| 0x14144BE20 | 断言 pdx_scopedptr.h:134 ×2 + 串 "UNIT_MEDALS" 断言 pdx_scopedptr.h:134 ×2 + 串 "UNIT_MEDALS"：部队勋章 UI |
| 0x1415CD110 | VT CCombatantReserveEntry + 串 "reserve_combat_entry"/"unit_icon" VT CCombatantReserveEntry + 串 "reserve_combat_entry"/"unit_icon"：战斗预备队条目 UI |
| 0x14150CA00 | 串 "MANPOWER"/"REQUESTED_REINFORCEMENT_COLLECTING_ENTRY" 串 "MANPOWER"/"REQUESTED_REINFORCEMENT_COLLECTING_ENTRY"：增援请求征集条目 UI |
| 0x1401A2570 | 断言 gameitemdatabase.h:281/331/324/336 + 串 "Cant reload when not loaded" 断言 gameitemdatabase.h:281/331/324/336 + 串 "Cant reload when not loaded"：数据库重载 |
| 0x14027B470 | 串 " textures were reloaded." 串 " textures were reloaded."：控制台纹理重载命令 |
| 0x1413DE3D0 | 断言 gameitemdatabase.h:142 + gamestate 门控（库单例 + gamestate 访问路径） |
| 0x141529500 | 串 "DOCTRINE_ENABLE_TACTIC" 串 "DOCTRINE_ENABLE_TACTIC"：学说解锁战术 GUI |
| 0x140E25060 | sub_140E25060 gamestate.h:1125 断言 + a1+32 清零（gamestate 对象状态重置） |
| 0x141340060 | 串 "CHAT_ERROR_UNKNOWNUSER"/"CHAT_ERROR_MUTEUNMUTE_SELF"/"CHAT_ERROR_MUTE_MISSINGARGS" 串 "CHAT_ERROR_UNKNOWNUSER"/"CHAT_ERROR_MUTEUNMUTE_SELF"/"CHAT_ERROR_MUT… |
| 0x14047EA10 | CVariableEffectBuilder 槽3（variablescripthelper.cpp:141 内联） CVariableEffectBuilder 槽3（variablescripthelper.cpp:141 内联）：脚本变量绑定构造，STR 'at'/'Assigned' |
| 0x14201E9B0 | 生涯档案背景 tooltip 生涯档案背景 tooltip：STR 'CAREER_PROFILE_TOOLTIP_BACKGROUND_UNLOCKED'/'..._LOCKED'/'REQUIREMENT' + GFX_/ICON 键 |
| 0x14187C080 | 战略空军视图（strategicairview.cpp:1104） 战略空军视图（strategicairview.cpp:1104）：STR 'Wrong enum value'，调 0x141886310/0x1402DE9B0 |
| 0x140F43470 | 0x140F4 特工行动区 0x140F4 特工行动区：调 0x141036310/0x140BEF720/0x140CF43B0（gamestate.h:1125 内联） |
| 0x141130A80 | CCancelLicensedProductionAction::CanExecute CCancelLicensedProductionAction::CanExecute：STR 'CAN_CANCEL_ALL_AFTER'/'DIPLOMACY_NO_AT_WAR'/'DATE'（gamestate.h:1… |
| 0x140B1DF30 | 串 "ALERT_ENEMY_CRYPTO_IS_BROKEN_TOOLTIP"/"ALERT_ENEMY_CRYPTO_IS_BROKEN_TOOLTIP_DELAYED" 串 "ALERT_ENEMY_CRYPTO_IS_BROKEN_TOOLTIP"/"ALERT_ENEMY_CRYPTO_IS_BROKE… |
| 0x141FDB5A0 | 断言 air_wing_button_widget.cpp:30/43/58/67 + 串 "AIRWING_MISSION_DAY_NIGHT_SINGLE"/"AIR_REINFORCE_ONLY_SAME_SHORT"/"NICHE_INDEX_" 断言 air_wing_button_widget.cpp… |
| 0x141031380 | sub_141031380 _RTDynamicCast + gamestate.h:1125 派发，无域串 |
| 0x14149E030 | 断言 gameitemdatabase.h:142 + gameitemdatabasehelper.h:22 + 串 "Array should be at least 1 element, did you forget to add the Null Object as Array[0]?" 断言 gamei… |
| 0x1403C8BE0 | 事件域并行任务（eventscope.h:193） 事件域并行任务（eventscope.h:193）：VT tbb::interface9::internal::flag_task，调 0x1403BE430 回调 |
| 0x141C62B50 | 铁路 gfx（gfx_train.cpp:477） 铁路 gfx（gfx_train.cpp:477）：STR 'CachedInfo._pRailway'/'PrevProv'，铁路缓存前序省查找 |
| 0x141A495D0 | （未命名）gamestate.h:1125 + "_Position + NeededSize <= _BufferSize" gamestate.h:1125 + "_Position + NeededSize <= _BufferSize"，分配器断言站点 |
| 0x140225320 | sub_140225320 gameitemdatabase.h:142 断言 + string 比较（sub_142244840）+ 容器遍历，无域串 |
| 0x140E44D80 | 和会（peaceconference.cpp:3965） 和会（peaceconference.cpp:3965）：STR 'pBestProvince != nullptr'/'OutDistances.IsEmpty()'/'exit_to_menu' |
| 0x140EA4FB0 | sub_140EA4FB0 gamestate.h:1126 断言 + TlsIndex 懒初始化 + j_j__malloc_base/unknown_libname_10，无域串 |
| 0x141DF3DC0 | CMapModeMilitaryDeploymentToOrder::[5]（func_names 名） func_names 名 + gamestate.h:1116 门控：军事部署地图模式指令 |
| 0x1401F2090 | 联合国策连接（gamestate.cpp:5119） 联合国策连接（gamestate.cpp:5119）：STR 'No countries found connected to a joint focus'/'Trying to visit a joint focus on a country with no… |
| 0x1418E5D00 | 0x1418E UI 区（robin_hood 邻接，pdx_scopedptr.h:134 内联） 0x1418E UI 区（robin_hood 邻接，pdx_scopedptr.h:134 内联）：调 0x141E82050/0x141E81FB0/0x1418E7390 |
| 0x14231F580 | 串 "quick_refresh"/"refresh_internet" 串 "quick_refresh"/"refresh_internet"：服务器/大厅列表刷新按钮（多人前端） |
| 0x140E7A9F0 | sub_140E7A9F0 gamestate.h:1126 断言 + TlsIndex 懒初始化 + 对象操作，无域串 |
| 0x141002FE0 | 0x14100 研究区（RESEARCH_TIME tooltip 邻接） 0x14100 研究区（RESEARCH_TIME tooltip 邻接）：调 0x1409FBB70/0x1419DD1C0/0x141000980（gamestate.h:1125 内联） |
| 0x1418CB480 | 串 "bg_strat_btn"/"permission_wings_count"/"permission_wings_bg" 串 "bg_strat_btn"/"permission_wings_count"/"permission_wings_bg"：空军联队许可 UI |
| 0x14012EDE0 | 数据库项构造注册（gameitemdatabase.h:882） 数据库项构造注册（gameitemdatabase.h:882）：0x140A6C410/0x1401369B0 + 标准注册序列 |
| 0x1417019B0 | 0x14170 特工 bottom bar 区（operativesbottombar.cpp 邻接） 0x14170 特工 bottom bar 区（operativesbottombar.cpp 邻接）：调 0x140C341D0/0x140F039B0（gamestate.h:1125 内联） |
| 0x141C86500 | sub_141C86500 gamestate.h:1125 访问器 + 16B 元素数组遍历 + 0x7FFFFFFF 哨兵（游戏对象查找/遍历） |
| 0x1418FF950 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言） |
| 0x14171A540 | 静态合同支付条目 UI（gamestate.h:1125） 静态合同支付条目 UI（gamestate.h:1125）：STR 'static_contract_payment_entry'/'open_market_view_btn'/'factories'/'Invalid equipment category' |
| 0x141B6F7F0 | 0x141B6 UI 区（CStateNudger 邻接，gamestate.h:1116 内联） 0x141B6 UI 区（CStateNudger 邻接，gamestate.h:1116 内联）：调 0x140EC97A0/0x140E92AB0 |
| 0x14050BA00 | 事件域并行任务（eventscope.h:193） 事件域并行任务（eventscope.h:193）：VT tbb flag_task，调 0x1404D5470 回调 |
| 0x140513DF0 | 事件域并行任务（eventscope.h:193） 事件域并行任务（eventscope.h:193）：VT tbb flag_task，调 0x1404E3970 回调 |
| 0x14051A320 | 事件域并行任务（eventscope.h:193） 事件域并行任务（eventscope.h:193）：VT tbb flag_task + CArmy/CGameDate/CHeldOfficer/SUnitOfficerData，STR 'access gamestate' |
| 0x140B20B60 | 舰队警报条目（gamestate.h:1125） 舰队警报条目（gamestate.h:1125）：STR 'FLEET'/'alert_expensive_ships_low_str_entry'/'ALERT_RIGHTCLICK' |
| 0x141A49A20 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言） |
| 0x14050F000 | 事件域并行任务（eventscope.h:193） 事件域并行任务（eventscope.h:193）：VT tbb flag_task，调 0x1404D06D0 回调 |
| 0x140B86320 | 断言 scriptedwindowmanager.cpp:429/435/448 + 串 "ai for scripted windows that has parent guis with scopes is not enabled %s"/"Parent window for %s is not found.… |
| 0x141E6D160 | 0x141E6 UI 区（CNewTheaterGroupItem 邻接） 0x141E6 UI 区（CNewTheaterGroupItem 邻接）：调 0x141E65780/0x14013E15E0（gamestate.h:1125 内联） |
| 0x140EC8DC0 | gamestate 门控 ×3 + pdx_scopedptr.h:124 断言；无其他自文档证据 |
| 0x140B17B10 | 串 "global_alerticon_window" 串 "global_alerticon_window"：全局警报图标窗口 |
| 0x141C9D710 | 请求空军志愿兵复选框（gamestate.h:1125） 请求空军志愿兵复选框（gamestate.h:1125）：STR 'checkbox_ask_for_air'/'ask_for_air_volunteers' |
| 0x14202FBB0 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言） |
| 0x1411226D0 | CPeaceProposalAction 槽58 CPeaceProposalAction 槽58：STR 'DIPLOMACY_CONDITIONAL_SURRENDER_POINT_FRACTION'/'_ACTION_DESC'/'AMOUNT'/'VALUE' |
| 0x140346F20 | CResizeArrayEffectImp 槽13（effectimplementation.cpp:16533） CResizeArrayEffectImp 槽13（effectimplementation.cpp:16533）：VT CScopedVariable，STR 'Invalid size:' + 流构造 |
| 0x14019AA00 | 数据库 Load（gameitemdatabase.h:281） 数据库 Load（gameitemdatabase.h:281）：STR 'Can only add a progress between'（进度区间校验）+ '!_Paths.IsEmpty()' |
| 0x140CF1720 | COwnerArea 槽3（gamestate.h:1116 内联） COwnerArea 槽3（gamestate.h:1116 内联）：调 0x140E810E0/0x140E796B0/0x140CF21D0，所有者区域维护 |
| 0x1403019C0 | 战略空军损失原因统计（strategicair.cpp） 战略空军损失原因统计（strategicair.cpp）：STR 'REASON_NONE_TOTAL'/'REASON_AIR_COMBAT'/'REASON_LAND_COMBAT'/'REASON_ACCIDENT'/'REASON_BOMBED'/… |
| 0x140E85780 | sub_140E85780 gamestate.h:1116 断言 + byte_14332EDF9/EDFA 双缓存槽 + 对象操作，无域串 |
| 0x141858070 | 0x14185 UI 区（CDefensiveStanceItem 邻接） 0x14185 UI 区（CDefensiveStanceItem 邻接）：8 调用含 0x1419E8580/0x141E49AD0/0x141E50D80（gamestate.h:1125 内联） |
| 0x1406D1410 | （未命名）仅 gamestate.h:1125 仅 gamestate.h:1125（CGlobals 断言） |
| 0x140BC2040 | mod/DLC 缺失提示 mod/DLC 缺失提示：STR 'MODS_MISSING'/'DLC_MISSING_ITEM'/'NAME'，调 0x140BC1D80（DLC 族） |
| 0x141DC04E0 | CProvinceBuildingItem 槽0 CProvinceBuildingItem 槽0：STR 'building_picture'/'DAMAGED'/'CURRENT'/'BUILDING_DAMAGED' |
| 0x1409FDE80 | CEquipmentGraphicPoolTypeMap（gamestate.h:1125） CEquipmentGraphicPoolTypeMap（gamestate.h:1125）：装备图形池类型映射维护，VT 该类 |
| 0x141A04330 | 0x141A0 UI 区（gamestate.h:1125 内联） 0x141A0 UI 区（gamestate.h:1125 内联）：调 0x140E932C0/0x141A01EB0/0x140F6E340 |
| 0x1410EC180 | 科技/科学家管理（pdx_scopedptr.h:124 内联） 科技/科学家管理（pdx_scopedptr.h:124 内联）：a1+136/148 数组遍历 + 调 0x140FA47A0/0x140FA6170/0x140FA01A0/0x140FA38C0/0x140FA61E0/0x140FA3D00… |
| 0x141CB0630 | 核建筑突破加成 tooltip 核建筑突破加成 tooltip：STR 'PROGRESS'/'AMOUNT'/'BUILDING'/'BREAKTHROUGH_BONUS_FROM_NUCLEAR_BUILDING' |
| 0x141EFB800 | CDifficultySettingItem 构造 CDifficultySettingItem 构造：VT CDifficultySettingItem/CModifier，STR 'KEY'/'HEADER' |
| 0x1414A78E0 | 师设计器模板项 师设计器模板项：STR 'name'/'subunit_icon'/'can_paradrop_icon'/'special_forces_icon'/'DESIGNER_REMOVE' |
| 0x140CB3D90 | 贸易视图 贸易视图：STR 'TRADEVIEW_RES_TRANSFERRED_FROM_SUBJECT_DETAILS'/'TYPE'/'SUBJECT'/'FACTOR' + 'INDUSTRIAL_ORG_DETAIL_MIO_MODIFIERS'/'...EQUIPMENT_BONUSES' |
| 0x14221B7F0 | 串 "minimap" 串 "minimap"：小地图窗口 |
| 0x1404FBA40 | 脚本值解析（gamestate.h:1125） 脚本值解析（gamestate.h:1125）：STR 'Constant value is not a country tag or array of country tags' |
| 0x140AF2250 | CUnitNamesDatabase::GenerateNameForTaskForce（func_names 名） CUnitNamesDatabase::GenerateNameForTaskForce（func_names 名）：STR 'NAVY_NAME_DETACHMENT_POSTFIX'/'RES… |
| 0x140ADBB20 | CTimedWargoalActivity 槽14（gamestate.h:1125） CTimedWargoalActivity 槽14（gamestate.h:1125）：STR 'TYPE'/'TARGET'/'GENERATE_WAR_GOAL_CANCEL_THREAT' |
| 0x140199230 | 数据库 Load（gameitemdatabase.h:281） 数据库 Load（gameitemdatabase.h:281）：STR '!_Paths.IsEmpty()' + gamestate.h 访问门，调 0x14013FCE0/0x14119E390/0x141404A30 |
| 0x141D2F080 | sub_141D2F080 gamestate.h:1126 断言 + _dyn_tls_on_demand_init(TlsIndex, 2144)，无域串 |
| 0x140354480 | CDeleteTemplateAndItsUnits::Execute（effectimplementation.cpp:18887） CDeleteTemplateAndItsUnits::Execute（effectimplementation.cpp:18887）：STR 'HasBeenRemoved' … |
| 0x140C2D960 | CSunkShipInfo 构造/填充 CSunkShipInfo 构造/填充：VT CSunkShipInfo/CGameDate，STR 'convoy'/'SUNK_BY_MINES'/'TRAINING_ACCIDENT' |
| 0x1420106F0 | 0x14201 UI 区（gamestate.h:1125 内联） 0x14201 UI 区（gamestate.h:1125 内联）：调 0x1406F9760/0x140EA0000/0x14022B420/0x1401F6470 |
| 0x141AD2AB0 | 角色列表项 UI（pdx_scopedptr.h:124 内联） 角色列表项 UI（pdx_scopedptr.h:124 内联）：STR 'name'/'title'/'skill' + 调 0x141ABFD20/0x140C19CF0/0x141EDA430（角色族） |
| 0x1417970C0 | 串 "FACTION_THEATER_REMOVE_COUNTRY"/"FACTION_THEATER_ADD_COUNTRY"/"FACTION_THEATER_COUNTRY_ITEM_DESC" |
| 0x140400840 | GetDesc（自定义难度触发器） GetDesc（自定义难度触发器）：STR 'YES'/'NO'/'DIFFICULTY'/'TRIGGER_HAS_CUSTOM_DIFFICULTY_ON' |
| 0x14049E470 | CCreateProductionLicense::GetDesc CCreateProductionLicense::GetDesc：STR 'TARGET'/'NAME'/'EFFECT_CREATE_LICENSE_PRODUCTION' |
| 0x14143A0C0 | sub_14143A0C0 gamestate.h:1125 断言 + a1+456 数组去重重建（count a1+468）（gamestate 容器去重） |
| 0x140263010 | 决议准备/海上入侵（gamestate.h:1125） 决议准备/海上入侵（gamestate.h:1125）：VT IDecision/CDecision/CModifier，STR 'Finished preparation for selected groups'/'No groups with naval… |
| 0x1418BD6C0 | CAdjacencyRuleIcon 槽0（gamestate.h:1125） CAdjacencyRuleIcon 槽0（gamestate.h:1125）：STR 'KEY'/'HEADER'，邻接规则图标 |
| 0x141808DC0 | CDefensiveStanceItem 槽0 CDefensiveStanceItem 槽0：STR 'CARRIER_DEFENSIVE_STANCE_SELECTION_'/'OFFENSIVE'/'DEFENSIVE'/'CARRIER_DEFENSIVE_STANCE_SORTIE_VALUES' |
| 0x140E7A580 | 0x140E7 外交/和会区（gamestate.h:1125 内联） 0x140E7 外交/和会区（gamestate.h:1125 内联）：调 0x140E7D690/0x1409DB3E0/0x140D39270/0x140E7DE70（11 调用） |
| 0x141AB9C90 | VT CArmyLeaderWindow + 串 "armyleaderwindow" VT CArmyLeaderWindow + 串 "armyleaderwindow"：陆军将领窗口 |
| 0x14188DCF0 | 0x14188 UI 区（gamestate.h:1125 内联） 0x14188 UI 区（gamestate.h:1125 内联）：调 0x141DB8E0/0x141E6D860/0x141E65F20/0x1402DE9B0 |
| 0x140BAED10 | 0x140BA 脚本变量区（gamestate.h:1125 内联） 0x140BA 脚本变量区（gamestate.h:1125 内联）：调 0x1424CC360/0x1422F7EA0/0x1422F9D10/0x141B32E70 |
| 0x1410DCDF0 | 科技/科学家管理（gamestate.h:1116 内联） 科技/科学家管理（gamestate.h:1116 内联）：调 0x140FA45E0/0x1406B70B0/0x140FA38C0/0x1406B52B0/0x140FA61E0/0x140710AE0（与 0x1410EC180 共享 FA/6B 族） |
| 0x140238240 | 外交途中添加（gamestate.h:1116） 外交途中添加（gamestate.h:1116）：VT CGameDate，STR 'Added diplomatic enroute.' |
| 0x141CB60B0 | sub_141CB60B0 CGameDate vtable + (v28-43800000)/24 日期换算（CGameDate 日期数学） |
| 0x1408656C0 | CDefineRegistryHelper_NGraphics::RAID_ARROW_AIR_SLOPE_SOURCE_STEEPNESS（raid_defines.h:42） CDefineRegistryHelper_NGraphics::RAID_ARROW_AIR_SLOPE_SOURCE_STEEPN… |
| 0x1409B2F80 | CDefineRegistryHelper_NSupply::TRAIN_ANTI_AIR_HIT_ROLL_COUNT（defines_supply.h:112） CDefineRegistryHelper_NSupply::TRAIN_ANTI_AIR_HIT_ROLL_COUNT（defines_suppl… |
| 0x14109FCC0 | sub_14109FCC0 gamestate.h:1125/1126 访问器（sub_140BB5490）+ id 匹配循环（游戏对象查找） |
| 0x141EA2DB0 | 特工任务状态 + 国际市场调试 UI（gamestate.h:1125） 特工任务状态 + 国际市场调试 UI（gamestate.h:1125）：VT COperativeMissionData，STR 'Attempted to change operative state in an illegal way… |
| 0x141E6F610 | sub_141E6F610 gamestate.h:1126 断言 + TlsIndex 懒初始化 + j_j__malloc_base，无域串 |
| 0x1418D31D0 | CActiveAbilityItem 槽0 CActiveAbilityItem 槽0：STR 'ABILITY_TOOLTIP_NAME'/'MULT'/'CASUALTIES_GREATER_THEN'/'CASUALTIES_LESS_THEN'/'ABILITY_TOOLTIP_LATE_JOINER_M… |
| 0x14239CBD0 | 项目 tag 数据库（gamestate.h:1125 + gameitemdatabase.h） 项目 tag 数据库（gamestate.h:1125 + gameitemdatabase.h）：STR 'doesn't exist in project_tag database, ignoring'，调 0… |
| 0x14178FC90 | 部署训练校验（deployment.cpp） 部署训练校验（deployment.cpp）：STR 'DEPLOYMENT_CANNOT_TRAIN_HQ'/'DEPLOYMENT_CANNOT_TRAIN_SPECIAL_UNITS'/'Host country has access to exiled tem… |
| 0x141CA7AE0 | CActiveVolunteersStripView 槽19 CActiveVolunteersStripView 槽19：VT CLegacyButtonObserverGlue<CEquipmentUpgradeDesignerView>，STR '_extended_desc'/'COUNTRY1'/'CO… |
| 0x140FA28C0 | 0x140FA 科技/角色区 0x140FA 科技/角色区：调 0x140BC96D0/0x140325590/0x140FA2500（0x140FA 族与 0x1410EC180 共用 BC96D0） |
| 0x141B3A460 | 全部启动按钮 tooltip（gamestate.h:1116 内联） 全部启动按钮 tooltip（gamestate.h:1116 内联）：STR 'tooltip_launch_all_button_first'/'..._second' |
| 0x141958B30 | 海上补给（gamestate.h:1125） 海上补给（gamestate.h:1125）：STR 'UNDERWAY_REPLENISHMENT_RANGE_BONUS'/'UNDERWAY_REPLENISHMENT_CONVOY_SHORTAGE_IMPACT'/'FACTOR'/'RATIO' |
| 0x141FA2190 | 设施拆除进度条目 设施拆除进度条目：STR 'dismantle_facility'/'dismantle_facility_progress'/'DISMANTLE_FACILITY_TT'/'DISMANTLE_FACILITY_PROGRESS'/'PROGRESS'/'DAYS' |
| 0x14187BC30 | subunit/战斗区（gamestate.h:1125 内联） subunit/战斗区（gamestate.h:1125 内联）：密集调 0x140CE9xxx/0x140D0xxx（0x140CE9BA0 被 subunitstats 调用） |
| 0x140D8E560 | 建造区（gamestate.h:1116 内联） 建造区（gamestate.h:1116 内联）：13 调用含 0x140D8D090/0x140D44800/0x140737330/0x1406FF1F0（0x140D8 建造族） |
| 0x1413FA380 | 行动/情报 行动/情报：STR 'OPERATIONS'/'NS'/'FACTION_INTEL_HEAD_OF_' |
| 0x141B94320 | 突袭结果 UI 突袭结果 UI：STR 'raid_outcome_title'/'OUTCOME'/'raid_type_outcome_header_victim'/'raid_type_outcome_header_actor'/'RAID_TYPE'/'GFX_province_view_frame_su… |
| 0x141133910 | CImproveRelationAction::CanExecute CImproveRelationAction::CanExecute：STR 'IS_NOT_IMPROVE_RELATIONS'/'WHO'/'DIPLOMACY_NO_AT_WAR'/'IS_IMPROVE_RELATIONS' |
| 0x140B35D80 | 警报右键（gamestate.h:1125） 警报右键（gamestate.h:1125）：STR 'ALERT_RIGHTCLICK'，调 0x140674990/0x140676240 |
| 0x140514C30 | 占领明细 tooltip（VT tbb flag_task + CColor） 占领明细 tooltip（VT tbb flag_task + CColor）：STR 'OCCUPATION_BREAKDOWN'/'OCCUPATION_BREAKDOWN_ENTRY'/'COUNTRY'/'OCCUPATION… |
| 0x14028D490 | 国家颜色控制台命令 国家颜色控制台命令：VT CCountryColors，STR '4 more arguments needed: country tag, red, green, blue'/'Color applied to'/'Invalid country Tag' + 'CANCEL_AGENCY_… |
| 0x1411997B0 | 脚本库访问助手（gameitemdatabase.h:142） 脚本库访问助手（gameitemdatabase.h:142）：STR 'Invalid arguments count.'/'Subsidy added.'/'Scripted trigger name is invalid.'/'Second a… |
| 0x141B49A50 | CRandomAllConfirm::[14]（func_names 名） func_names 名 + 串 "Randomize in all unmarked states."/"All marked provinces will be ignored."：随机化确认对话框（建筑随机化） |
| 0x1418277A0 | 新阵营创建窗口（gamestate.h:1125） 新阵营创建窗口（gamestate.h:1125）：STR 'NEW_FACTION_WINDOW_RULES'/'NEW_FACTION_WINDOW_GOAL'/'NEW_FACTION_WINDOW_MANIFEST'/'NAME'/'VALUE' |
| 0x1415C6BD0 | 海战飞行联队受损 tooltip 海战飞行联队受损 tooltip：STR 'NAVAL_COMBAT_AIRWING_TOOLTIP_DAMAGED'/'..._ENTRY'/'..._LAST_HIT'/'PERC'/'NAVY' |
| 0x141AAF470 | 科技/科学家管理（pdx_scopedptr.h:124 内联） 科技/科学家管理（pdx_scopedptr.h:124 内联）：调 0x140FA47A0/0x140FA6170/0x140FA01A0/0x140FA38C0/0x140FA61E0/0x140FA3D00 + 0x141AB30D0（与 0… |
| 0x141F17620 | 特殊项目科学家雇佣 UI 特殊项目科学家雇佣 UI：STR 'FACTION_ASSIGN_SCIENTIST_COS'/'_CANNOT_AFFORD'/'VALUE' |
| 0x141F827A0 | sub_141F827A0 gamestate.h:1125 访问器（sub_140BB48F0）+ 对象 +3976/+656 字段比较（游戏对象排序比较器） |
| 0x1412053D0 | 特殊项目程序项（program_item.cpp） 特殊项目程序项（program_item.cpp）：STR 'PROGRAM_STATE_NAME'/'STATE'/'pFacility'/'pProgram' |
| 0x14111C840 | CSendExpeditionaryForceAction::GetAiAcceptance（gamestate.h:1125） CSendExpeditionaryForceAction::GetAiAcceptance（gamestate.h:1125）：调 0x1412F0320/0x1406EC810/0… |
| 0x140F98A00 | 占领顺从度（gamestate.h:1125） 占领顺从度（gamestate.h:1125）：STR 'TOT'/'COMPLIANCE_STRENGTH'/'COMPLIANCE_EFFECTS' |
| 0x140C6EC80 | sub_140C6EC80 dword_143337360 全局比较 + a1+1592 槽位 + sub_14144D790（gamestate.h:1125 访问器）条件注册，无域串 |
| 0x141A2A990 | 串 "#~ Invalid country tag"/"#~ Operative does not exist"/"OPERATION_OPERATIVE_ASSIGNMENT_NOT_YET"/"#~ Operative already assigned" 串 "#~ Invalid country tag"/… |
| 0x142180770 | 生产线启动 UI（gamestate.h:1125） 生产线启动 UI（gamestate.h:1125）：STR 'ui_production_line_start'/'ui_production_line_ship_start'/'_with_mio' |
| 0x141BBBDD0 | CMoveShipItem 槽0 CMoveShipItem 槽0：STR 'NAME'/'SHIP_IS_PRIDE_OF_FLEET'/'NAVY_CONTAINS_PRIDE_OF_FLEET'/'SHIP_IS_PRIDE_OF_FLEET_DESC' |
| 0x14019C210 | 数据库 Load（gameitemdatabase.h:281） 数据库 Load（gameitemdatabase.h:281）：STR '!_Paths.IsEmpty()' + 流构造，调 0x140174650 |
| 0x1401A3F70 | 数据库 Load（gameitemdatabase.h:281） 数据库 Load（gameitemdatabase.h:281）：STR '!_Paths.IsEmpty()' + 流构造，调 0x140174CB0/0x1414C30A0（与 0x14019C210 同源对，4080B） |
| 0x140FE8B30 | sub_140FE8B30 gamestate.h:1125 访问器 + 对象 +1832/+884/+496 字段比较（游戏对象比较） |
| 0x141F70B70 | CEquipmentUpgradeDesignerWindow 槽0 CEquipmentUpgradeDesignerWindow 槽0：STR 'DESIGNER_EXPENSIVE'/'DESIGNER_NO_CHANGES'，调 0x140C97430/0x140C97B90 |
| 0x141464970 | 科学家分配状态（namespacemanager.h） 科学家分配状态（namespacemanager.h）：STR 'STATE'/'SCIENTIST_ALREADY_ASSIGNED'/'Unexpected ID type. Got:'/'and expected:' + combat.cpp 'IsF… |
| 0x140947010 | CDefineRegistryHelper_NNavy::INTEL_LEVEL_LOW_HALF_RANGE_MIN_SHIPS（defines_military.h:899） CDefineRegistryHelper_NNavy::INTEL_LEVEL_LOW_HALF_RANGE_MIN_SHIPS（d… |
| 0x140904840 | CDefineRegistryHelper_NMilitary::COMBAT_MOVEMENT_SPEED（defines_military.h:86） CDefineRegistryHelper_NMilitary::COMBAT_MOVEMENT_SPEED（defines_military.h:86）：l… |
| 0x1423DFAB0 | Steam 匹配/大厅 Steam 匹配/大厅：VT CSteamMatchmakingContext/CCallback<...>/CMatchmakingCallResult/CMatchmakingServerListResponse + STR 'ACE_FULL_NAME'/'ACE_FULL_NAME… |
| 0x141109C20 | CStageCoupAction::[56] CStageCoupAction::[56]；串「_pInstance && "gamestate unitilialized"」 |
| 0x1418FCC60 | 特混舰队/护航突袭警告 特混舰队/护航突袭警告：STR 'CURRENT_ACTIVE_TASK_FORCE_FOR_DOMINANCE_WARNING'/'TOO_MANY_REGIONS_FOR_CONVOY_RAID_WARNING' |
| 0x1414715D0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141CBD4A0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x142011B10 | NAiNavalGoals::CInvasionDefenseObjective::[6] gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141CF0710 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x141065110 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x14202F9D0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140EAF100 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CC0120 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CC1120 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CC4590 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CC1940 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CC4BA0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140E97900 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CD0B80 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CD31D0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CD4EA0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CCE980 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CCF8D0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CD1720 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CD3D80 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140CD6800 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141681040 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140EA25C0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x1413DD040 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140248C00 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x1401DB6C0 | （无名） gamestate.cpp 实现（断言站点 gamestate.cpp:2182） |
| 0x14190CA70 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140AD7020 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141581A90 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x1413C3090 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140E9EBB0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141739C60 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141799DB0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140E7E270 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141C5F420 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141B544B0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x1418AB0A0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140C00010 | CUnit::[8] gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x140FED2F0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x1419A9170 | CGameChat::[10] gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141B09000 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x14136D5D0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x1406C3700 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x1419EDC40 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x14032E1D0 | （无名） vftable 类 CGregorianDate::（游戏状态/时间） |
| 0x1415B8220 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140E7E920 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x140F67360 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140FE67E0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141036000 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141D239A0 | _Func_impl_no_alloc<…>::[2] gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x140E88560 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x142014EF0 | NAiNavalGoals::CTrainingObjective::[1] gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140F02DC0 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1116） |
| 0x140464450 | CHasActiveResistance::Evaluate gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x140A8D120 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |
| 0x141401550 | （无名） gamestate 访问器（gamestate.h 线程/实例断言）（断言站点 gamestate.h:1125） |

#### 4.1.20 CGameState 派发族与门控函数补遗（96 函）

| VA | 语义/证据 |
|---|---|
| 0x1418E26A0 | （无名）gamestate.h:1125 访问门 + __eh34 + off_143085170 + qword_14338B4C0/1430B4190，无域识别串 gamestate.h:1125 访问门 + __eh34 + off_143085170 + qword_14338B4C0/1430B4190… |
| 0x1411F6990 | （无名）gamestate.h:1125 访问门 + TLS 惰性单例 + off_143085170 虚表分发，无域识别串 gamestate.h:1125 访问门 + TLS 惰性单例 + off_143085170 虚表分发，无域识别串 |
| 0x141E6B140 | （无名）gamestate.h:1125 访问门 + off_143085170 x16 + Init_thread 惰性初始化，无域识别串 gamestate.h:1125 访问门 + off_143085170 x16 + Init_thread 惰性初始化，无域识别串 |
| 0x140CBCE00 | （无名）gamestate.h:1125 访问门 + qword_14332F260 x9 + __debugbreak，无域识别串 gamestate.h:1125 访问门 + qword_14332F260 x9 + __debugbreak，无域识别串 |
| 0x141C517F0 | （无名）gamestate.h:1116 访问门 + off_143085170 + qword_14332EE10，无域识别串 gamestate.h:1116 访问门 + off_143085170 + qword_14332EE10，无域识别串 |
| 0x14102A6C0 | （无名）gamestate.h:1116 访问门 + __debugbreak，无域识别串 gamestate.h:1116 访问门 + __debugbreak，无域识别串 |
| 0x140F34850 | （无名）gamestate.h:1125 访问门 + malloc/free + __debugbreak，无域识别串 gamestate.h:1125 访问门 + malloc/free + __debugbreak，无域识别串 |
| 0x1412ED420 | （无名）gamestate.h:1125 访问门 + off_143085170 + qword_1433334C0，无域识别串 gamestate.h:1125 访问门 + off_143085170 + qword_1433334C0，无域识别串 |
| 0x141275F00 | sub_141275F00 vtable 间接调用 §待裁 |
| 0x140D99190 | sub_140D99190 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1411A3660 | sub_1411A3660 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141F9E730 | sub_141F9E730 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1419AF1E0 | sub_1419AF1E0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1423A4E20 | sub_1423A4E20 vtable 间接调用 §待裁 |
| 0x140E907A0 | sub_140E907A0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1418F5600 | sub_1418F5600 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1412F5550 | sub_1412F5550 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x14101D8F0 | sub_14101D8F0 vtable 间接调用 §待裁 |
| 0x14118B800 | sub_14118B800 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141E21C30 | sub_141E21C30 vtable 间接调用 §待裁 |
| 0x141B24080 | sub_141B24080 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x14223BC00 | sub_14223BC00 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1417BBF60 | sub_1417BBF60 vtable 间接调用 §待裁 |
| 0x141B6B7B0 | sub_141B6B7B0 vtable 间接调用 §待裁 |
| 0x14152B530 | sub_14152B530 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141EFD390 | sub_141EFD390 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x140A8BF80 | sub_140A8BF80 vtable 间接调用 §待裁 |
| 0x140155680 | sub_140155680 vtable 间接调用 §待裁 |
| 0x1413877D0 | sub_1413877D0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141C38200 | sub_141C38200 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1411DB190 | sub_1411DB190 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x14248C4B0 | sub_14248C4B0 vtable 间接调用 §待裁 |
| 0x1402A7820 | sub_1402A7820 vtable 间接调用 §待裁 |
| 0x140A367E0 | sub_140A367E0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1422F0000 | sub_1422F0000 vtable 间接调用 §待裁 |
| 0x141439EF0 | vtable/RTTI 类 CGameDate sub_141439EF0 + vtable/RTTI 类 CGameDate; 被调源码 hoi4; 被 CCancelLicensedProductionAction::[56] 等 1 命名函数调用 |
| 0x1410B4D30 | sub_1410B4D30 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x140D7B740 | sub_140D7B740 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141DE7DF0 | sub_141DE7DF0 vtable 间接调用 §待裁 |
| 0x1417DDB30 | sub_1417DDB30 vtable 间接调用 §待裁 |
| 0x140A349E0 | vtable/RTTI 类 CGameRule sub_140A349E0 + vtable/RTTI 类 CGameRule |
| 0x141BD0AC0 | sub_141BD0AC0 vtable 间接调用 §待裁 |
| 0x140FD7200 | sub_140FD7200 vtable 间接调用 §待裁 |
| 0x140A6BF10 | sub_140A6BF10 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x142358BF0 | sub_142358BF0 vtable 间接调用 §待裁 |
| 0x14102A320 | sub_14102A320 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x140C676C0 | sub_140C676C0 vtable 间接调用 §待裁 |
| 0x1410337A0 | sub_1410337A0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x14054A6B0 | sub_14054A6B0 vtable 间接调用 §待裁 |
| 0x140F09130 | vtable/RTTI 类 CGameDate sub_140F09130 + vtable/RTTI 类 CGameDate |
| 0x141EA60B0 | sub_141EA60B0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141C13FA0 | sub_141C13FA0 vtable 间接调用 §待裁 |
| 0x1416C89E0 | sub_1416C89E0 vtable 间接调用 §待裁 |
| 0x141AB5300 | sub_141AB5300 vtable 间接调用 §待裁 |
| 0x140B90CD0 | sub_140B90CD0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141830180 | sub_141830180 vtable 间接调用 §待裁 |
| 0x141033520 | sub_141033520 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1422B94B0 | sub_1422B94B0 vtable 间接调用 §待裁 |
| 0x141CF08F0 | sub_141CF08F0 vtable 间接调用 §待裁 |
| 0x1411CB4F0 | sub_1411CB4F0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1402C4C90 | sub_1402C4C90 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1402C4B50 | sub_1402C4B50 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x140AE1450 | sub_140AE1450 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x140B669A0 | sub_140B669A0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141209540 | sub_141209540 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x142282BE0 | sub_142282BE0 vtable 间接调用 §待裁 |
| 0x141E00B70 | sub_141E00B70 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1409C1090 | sub_1409C1090 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1410455C0 | sub_1410455C0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1401C0C50 | vtable/RTTI 类 CGameDate sub_1401C0C50 + vtable/RTTI 类 CGameDate |
| 0x1410C5C50 | sub_1410C5C50 vtable 间接调用 §待裁 |
| 0x142122150 | sub_142122150 vtable 间接调用 §待裁 |
| 0x1406C6710 | sub_1406C6710 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x14180C3D0 | sub_14180C3D0 vtable 间接调用 §待裁 |
| 0x14145B200 | sub_14145B200 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x1419A1CC0 | sub_1419A1CC0 vtable 间接调用 §待裁 |
| 0x1415DE380 | vtable/RTTI 类 CGameDate sub_1415DE380 + vtable/RTTI 类 CGameDate; 串 "_pInstance"; 源码路径 hoi4 |
| 0x140C0BE20 | vtable/RTTI 类 CGameDate sub_140C0BE20 + vtable/RTTI 类 CGameDate; 被调源码 hoi4; 被 CCountryCharacters::Reader 等 3 命名函数调用 |
| 0x14167D890 | sub_14167D890 vtable 间接调用 §待裁 |
| 0x140B89E60 | sub_140B89E60 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141674650 | sub_141674650 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x141883D20 | sub_141883D20 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x142416E90 | sub_142416E90 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x140CDFFF0 | vtable/RTTI 类 CGregorianDate sub_140CDFFF0 + vtable/RTTI 类 CGregorianDate; 被 CGameState::Writer 等 1 命名函数调用 |
| 0x1416FA9D0 | sub_1416FA9D0 vtable 间接调用 §待裁 |
| 0x141CFA8D0 | sub_141CFA8D0 vtable 间接调用 §待裁 |
| 0x1422A6AD0 | sub_1422A6AD0 float+xmm 寄存器 + vtable 间接调用 §待裁 |
| 0x14143A430 | vtable/RTTI 类 CGameDate sub_14143A430 + vtable/RTTI 类 CGameDate; 被调源码 hoi4; 被 CRequestLicensedProductionAction::[56] 等 1 命名函数调用 |
| 0x1410FB820 | vtable/RTTI 类 CGameDate sub_1410FB820 + vtable/RTTI 类 CGameDate; 被调源码 hoi4 |
| 0x1415DE1E0 | vtable/RTTI 类 CGameDate sub_1415DE1E0 + vtable/RTTI 类 CGameDate |
| 0x140FFD5C0 | vtable/RTTI 类 CGregorianDate sub_140FFD5C0 + vtable/RTTI 类 CGregorianDate |
| 0x1410FB8E0 | vtable/RTTI 类 CGameDate sub_1410FB8E0 + vtable/RTTI 类 CGameDate; 被调源码 hoi4 |
| 0x1410FB0E0 | vtable/RTTI 类 CGameDate sub_1410FB0E0 + vtable/RTTI 类 CGameDate; 被调源码 hoi4 |
| 0x1410FA860 | vtable/RTTI 类 CGameDate sub_1410FA860 + vtable/RTTI 类 CGameDate; 被调源码 hoi4 |
| 0x1410FAE80 | vtable/RTTI 类 CGameDate sub_1410FAE80 + vtable/RTTI 类 CGameDate; 被调源码 hoi4 |
| 0x1410FB440 | vtable/RTTI 类 CGameDate sub_1410FB440 + vtable/RTTI 类 CGameDate; 被调源码 hoi4 |

#### 4.1.21 CGameState 派发族与门控函数补遗（145 函）

| VA | 语义/证据 |
|---|---|
| 0x140E2D1A0 | 和会动作（Invalid state id 门） 串 `pGameState->GetState( pStateAction->GetStateId() ) && "Invalid state id"` + peaceconference.cpp |
| 0x140E3E270 | 和会分数剩余回合条目 串 PEACE_SCORE_REMAINING_TURNS_GIVING_SCORE / CURRENTTURN / NBTURN |
| 0x140C31300 | 燃料日需/收条目 串 FUEL_DAILY_REQUIRED_AND_RECEIVED / FUEL_DAILY_REQUIRED / REQUIRED / RECEIVED |
| 0x14133ABE0 | 聊天频道（CHANNEL / OP / CHAT_YOUWEREBANNED） 串 CHANNEL / OP / CHAT_YOUWEREBANNED |
| 0x140F90F20 | 占领合规 / 抵抗视图 串 LOCAL_COMPLIANCE / LOCAL_RESISTANCE |
| 0x14195B760 | 描述装配（_DESC / BASE / EFFECTS） 串 _DESC / BASE / EFFECTS |
| 0x14012F180 | 外交动作辅助（调 GetFirstCountryRef） gameitemdatabase.h:882 断言 + 调 CDiplomaticAction::GetFirstCountryRef |
| 0x141AC8220 | COperativeLeaderItem 槽 0（特工领袖项） 串 LEADER_SKILL_AT_CAP / UNIT_LEADER_SKILL_OPERATIVE_DESC |
| 0x141565A50 | 释放国家对话框 串 RELEASE_NATION_TITLE / RELEASE_NATION_DESC |
| 0x14145DC80 | 特殊项目资源用量 tooltip 串 SPECIAL_PROJECT_RESOURCE_USAGE_DESC_TOOLTIP / RESOURCES |
| 0x141009500 | （未具名） "GFX_ability_icon_default"/"INVALID_ABILITY" + CAbility/CModifier 类名（能力图标 GUI） |
| 0x14072BD70 | 事件域描述（_desc） eventscope.h:193 断言 + 串 `_desc` |
| 0x141DECE00 | （未具名） "playthrough_overview_window" + NCareerProfile::CPlaythroughOverviewWindow 类名 |
| 0x14201ABE0 | NCareerProfile::CRibbonDisplaySlot + "ca NCareerProfile::CRibbonDisplaySlot + "career_profile_ribbon_ §4.1 CGameState/gamestate |
| 0x14012C840 | 外交动作辅助（调 GetFirstCountryRef） gameitemdatabase.h:882 断言 + 调 CDiplomaticAction::GetFirstCountryRef |
| 0x141DC2EE0 | CStateStrategicResourceItem 槽 0 串 KEY / HEADER / COUNTRY / STATE_FOREIGN_RESOURCE_OWNER |
| 0x141D8DAD0 | 后勤燃料消耗视图 串 LOGISTICS_VIEW_FUEL_CONSUMPTION_VALUE |
| 0x140A0B5B0 | 数据库实例门 串 `Instance not created.` + gameitemdatabase.h:142 |
| 0x141E91890 | "RIBBON_POINTS/ACHIEVED_STATUS/CAREER_PR "RIBBON_POINTS/ACHIEVED_STATUS/CAREER_PROFILE_RIBBON_TOOLTIP §4.1 CGameState/gamestate |
| 0x14044C6B0 | CCharacterFlagTrigger 槽 23 串 TRIGGER_CHARACTER_FLAG_SET / TRIGGER_CHARACTER_FLAG_NOT_SET |
| 0x141D1E260 | CConfirmTrainingGroupDialog 槽 14 串 CONFIRM_START_TRAINING / CONFIRM_STOP_TRAINING / UNIT_LEVEL_%d |
| 0x140E3FA50 | 和会动作类型标签 串 `Unknown peace action type` + PEACE_DISMANTLE_INDUSTRY_LABEL 等 + peaceconference.cpp |
| 0x1403C9F20 | 事件域遍历模板实例 A eventscope.h:193 断言 |
| 0x14050F9E0 | 事件域遍历模板实例 C eventscope.h:193 断言 |
| 0x140514690 | 事件域遍历模板实例 D eventscope.h:193 断言 |
| 0x14051A750 | 事件域遍历模板实例 E eventscope.h:193 断言 |
| 0x14050BE30 | 事件域遍历模板实例 B eventscope.h:193 断言 |
| 0x141188EE0 | 派系剧院地图模式条目 串 FACTION_THEATER_MAP_MODE_REMOVE / FACTION_THEATER_REGION_COUNT_TOOLTIP |
| 0x141C49460 | 想法成本 UI（IDEA_COST_COMPACT_） 串 IDEA_COST_COMPACT_ / IDEA_NOT_AVAILABLE_ICON / VALUE |
| 0x140C879D0 | 人力 UI 项 串 CURRENT_MANPOWER |
| 0x1410EBDC0 | Steam 云文件句柄（CSteamCloudFile） pdx_scopedptr.h:124 断言 + 调 CSteamCloudFile::[13] |
| 0x141120400 | CPeaceProposalAction 槽 59（有条件投降分数） 串 DIPLOMACY_CONDITIONAL_SURRENDER_POINT_FRACTION / AMOUNT |
| 0x141D54820 | CProductionFactoryItem 槽 0（工厂分配项） 串 PRODUCTION_FACTORY_ASSIGN_DESC / PRODUCTION_DOCKYARD_ASSIGN_DESC |
| 0x1413D4FD0 | 数据库实例门 串 `Instance not created.` + gameitemdatabase.h:142 |
| 0x1403387C0 | CEveryArmyLeaderEffect 槽 25 eventscope.h:193 断言 `Infinite cycle in event FROM scope` |
| 0x141D2E370 | HQ 模板部署天数条目 串 HQ_TEMPLATE_DEPLOY_DAYS_SHORT / DAYS / EDIT / VIEW |
| 0x14143E540 | 地形战斗宽度表项 串 TERRAIN_COMBAT_WIDTH / TERRAIN_ADDITIONAL_WIDTH / KEY / HEADER / VALUE |
| 0x141129770 | 外国人力理由项 串 FOREIGN_MANPOWER_REASON_NO_NEED / NOT_ENOUGH / ALREADY_ENOUGH |
| 0x1402D1560 | 国策继续/绕过/取消/暂停提示 串 FOCUS_WILL_CONTINUE / FOCUS_WILL_BYPASS_IF_UNAVAILABLE / FOCUS_WILL_CANCEL / FOCUS_WILL_PAUSE |
| 0x1419343F0 | 生产线转换速度取值 串 PRODUCTION_LINE_CONVERT_SPEED_BASE |
| 0x140338BA0 | CEveryNavyLeaderEffect 槽 25 eventscope.h:193 断言 |
| 0x140FE23B0 | 特殊项目（project.cpp，DLC 派系目标） project.cpp:930 断言站点 |
| 0x1401BC6F0 | CGameState::DoCareerProfileHourlyUpdate? / CGameState::DoCareerProfileHourlyUpdate CGameState::DoCareerProfileHourlyUpdate §4.1 CGameState/gamestate |
| 0x141CE8A00 | CFrontendMultiplayerView 槽 4（版本号显示） 串 version_number / VERSION |
| 0x140371920 | CAddAutonomyRatio::GetDesc 串 ADD_AUTONOMY_SCORE_DESC / ADD_AUTONOMY_SCORE_DETAILED_DESC |
| 0x140F800F0 | 空中任务（airmission）作用域遍历 airmission.cpp:3229 + eventscope.h:193 断言 |
| 0x140222D90 | CGregorianDate/CGameDate vtable：日期处理 CGregorianDate/CGameDate vtable：日期处理 §4.1 CGameState/gamestate |
| 0x14145F720 | （未具名） "SCIENTIST_TOOLTIP_SKILL_LEVEL_HEADER" loc 键（科学家技能 tooltip） |
| 0x141F460A0 | （未具名） "start_button"/"game_name" + 邻域 CGameSetupMenuLoadWindow/CGameSetupIronmanSaveWindow（开局菜单） |
| 0x14119A850 | （未具名） "Invalid equipment type:" + CEquipmentVariantPool 类名 |
| 0x141D97960 | CLogisticsInfoEquipmentItem 槽 0 串 LOGISTICS_AMOUNT_PRODUCTION_LINES / AMOUNT / NUMBER |
| 0x141BCF310 | CGameDate/CGregorianDate vtable CGameDate/CGregorianDate vtable §4.1 CGameState/gamestate |
| 0x141DD26F0 | CDivisionEquipmentView 槽 0 串 ALLOW_FOREIGN_EQUIPMENT_TT / REINFORCE_WITH_RESEARCHED_EQUIPMENT |
| 0x141EEC8A0 | （未具名） "active_research" + NProject::NUi/CProgramOngoingProjectView 类名（进行中项目视图） |
| 0x140FCCA50 | （未具名） "POLITICAL_RESEARCH_BONUS_ENTRY"/"CATEGORY"/"FACTOR" loc 键（政治研究加成 GUI） |
| 0x1403F4380 | CCanBeCountryleader::GetDesc TRIGGER_CAN_BE_COUNTRY_LEADER / TRIGGER_CANT_BE_COUNTRY_LEADER loc 键 |
| 0x141704DE0 | （未具名） "air_view_plane_entry"/"highlight"/"icon"/"count" + CPlaneInfoEntry 类名（空军视图） |
| 0x141401A20 | COperationInstance::[2] ref.h:83 CReference 断言 + COperationInstance 类名（特工行动实例 vtable 槽 2） |
| 0x141837F90 | （未具名） ref.h:83 CReferenceObject 断言 + COrderAssignCommand 类名（命令分配序列化） |
| 0x14208C1A0 | （未具名） "tweaker_label" + "+"/"-" 调节器 GUI；邻域 CTweakableBoolManipulator/CTweakerListItem |
| 0x14201EDF0 | 生涯档案图片锁定/解锁 tooltip 串 CAREER_PROFILE_TOOLTIP_PICTURE_UNLOCKED / CAREER_PROFILE_TOOLTIP_PICTURE_LOCKED + 调 CChoice<CSmoothListboxItem>::[3] |
| 0x14186D7B0 | （未具名） "playerlobby_playerlist"/"multiplayer_list_window"/"multiplayer_list" GUI 名 |
| 0x14019C540 | 库重载门（Cant reload when not loaded） 串 `!_Paths.IsEmpty() && "Cant reload when not loaded"` + gameitemdatabase.h |
| 0x140C2D6B0 | （未具名） ref.h:83 断言 + CGameDate/CSunkShipInfo 类名（击沉舰船信息引用） |
| 0x1411F3790 | （未具名） "Operative to reassign in an unhandled state"/"Network based mission has no target state set!" + strategicoperative.cpp:2468 |
| 0x141C9D2F0 | （未具名） "Invalid Enum" + diplomacyviewcontrollers.cpp:1760（外交视图控制器） |
| 0x1419E0430 | （未具名） gameitemdatabase.h:142 断言 + "PEACE_CONFERENCE_PROVINCE_TOOLTIP_ITEM"/"NAME"/"VALUE" loc 键 |
| 0x141A7D110 | （未具名） ref.h:83 断言 + CAssignToTheaterGroupCommand 类名（分配战区集团命令序列化） |
| 0x141E68A60 | 剧院组分配按钮 tooltip 串 THEATER_GROUP_ASSIGN_CLICK_BUTTON_DESC 等 4 键 |
| 0x140D3D770 | （未具名） "DIPLOMACY_ESTIMATED_VALUE"/"DIPLOMACY_ESTIMATED_VALUE_ACCURATE" loc 键（外交估计值 GUI） |
| 0x140E3D120 | （未具名） "CAPITAL"/"PEACE_CONFERENCE_NAME" loc 键（和会界面） |
| 0x140436BE0 | CForEachTriggerImp<$00>::[6] "^num" 迭代变量串 + CForEachTriggerImp 类名（foreach 触发器槽 6） |
| 0x140DF10D0 | （未具名） "Expected opening brace" + pdx_parser.h:2222（对象块反序列化 Reader） |
| 0x14025A910 | （未具名） "No active Decision has been found with this ID"/"All decisions have been set to finish tomorrow"（决议管理） |
| 0x1420373F0 | （未具名） "equipment_ic"/"carrier_capable_icon"/"count"/"type"（装备列表 GUI） |
| 0x141B56CB0 | （未具名） "nudge_window_state_entry"/"select" + CStateEntry；邻域 CStateNudger::[0] |
| 0x141E7CA50 | （未具名） "air_wing_counter" + CAirWingMapStackItem 类名（空战联队堆叠 GUI） |
| 0x141EC6650 | （未具名） "ledger_ship_entry"/"ship_name" + CIntelLedgerNavyPanelController::CLedgerShipEntry 类名 |
| 0x141C79900 | （未具名） "diplomacy_action_entry" + CDiplomacyActionItem 类名 |
| 0x141EF9200 | （未具名） CAREER_PROFILE_STEAM_NOT_RUNNING / CAREER_PROFILE_PRIVATE 等 loc 键 + message_overlay GUI 名 |
| 0x141C7AF20 | （未具名） "diplomacy_trade_entry" + CDiplomacyTradeItem 类名（外交贸易条目） |
| 0x141420D40 | （未具名） "Invalid operator '" 比较运算符校验串（脚本解析错误） |
| 0x141F07BF0 | （未具名） "TECHNOLOGY_BATTALION_MODIFIERS_HEADER" + "support_category_multipliers_grid"（科技加成 GUI） |
| 0x14135FB30 | （未具名） ref.h:83 断言 + CCancelMovementCommand 类名（取消移动命令序列化） |
| 0x140DEF600 | （未具名） "Expected opening brace" + pdx_parser.h:2222（对象块反序列化 Reader） |
| 0x140730250 | CDecision::[8] "Decision scripted with modifier, but no days_remove duration"/"Cost for normal missions not implemented" + decision.cpp:488 |
| 0x14031BDD0 | CConstructBuildingInRandomProvince::ParseToken " does not match any provincial building"（随机省份建筑效果解析） |
| 0x14146AD70 | （未具名） "rule_container"/"rules_button" + CFactionRulesSection 类名（派系规则 GUI） |
| 0x142016E20 | （未具名） "equipment_bonus_reward_description" loc 键（事件/任务奖励描述） |
| 0x141940520 | （未具名） ref.h:83 断言 + CDetachAirWingFromArmyCommand 类名（联队脱离陆军命令序列化） |
| 0x1404FD0F0 | （未具名） "Infinite cycle in event FROM scope" + eventscope.h:193（事件作用域枚举三联 #1） |
| 0x1404FE3F0 | （未具名） "Infinite cycle in event FROM scope" + eventscope.h:193（三联 #2，同族 0x1404FD0F0） |
| 0x1404FF6F0 | （未具名） "Infinite cycle in event FROM scope" + eventscope.h:193（三联 #3，同族 0x1404FD0F0） |
| 0x1415202A0 | （未具名） CVolunteerForceTransfer 类名（志愿军转移）+ gamestate.h:1116 |
| 0x141DD6E10 | （未具名） gameitemdatabase.h:142 断言 + "DESIGNER_UNSAVED_CHANGES" loc 键（设计公司未保存更改 GUI） |
| 0x141D401E0 | （未具名） "name"/"amount"/"equipment_ic"/"_medium"（装备列表 GUI，同 158 模式） |
| 0x141EA5390 | （未具名） "intel_ledger_plane_count_detail" + CIntelLedgerAirPanelController::CPlaneTypeCountEntryItem 类名 |
| 0x140DF4D80 | （未具名） "COUNTRY"/"EFFECT_LIST_COUNTRY" loc 键（国家列表效果描述） |
| 0x140DEFEA0 | （未具名） "Expected opening brace" + pdx_parser.h:2222（对象块反序列化 Reader） |
| 0x141586160 | （未具名） "continuous_glow"/"drop_focus_button" GUI 串 |
| 0x140C0E5D0 | （未具名） gameitemdatabasehelper.h "Array should be at least 1 element... Null Object as Array[0]" 断言（数据库空对象哨兵） |
| 0x141AECED0 | （未具名） "Area %i: %.3f"/"Areas (%s): %.3f"/"No area covering province" = 地图区域面积统计 |
| 0x141592FC0 | （未具名） "WHAT"/"LOCATION"/"raid_source_desc" loc 键（突袭来源描述 GUI） |
| 0x140B6DE50 | （未具名） "error_log_button"/"errors"/"debug_dog_yelping"/"confirm_dog" GUI 名（错误日志弹窗） |
| 0x141EEF680 | （未具名） "PROGRAM_VIEW_RESEARCH_TIME"/"PROGRAM_VIEW_PROJECT_PROGRESS"/"INFINITY" loc 键（项目视图 GUI） |
| 0x141A32F40 | （未具名） "DOCTRINE_MONTHLY_MASTERY_GAIN_FACTION_SHARING"/"VALUE" loc 键（学说精通 GUI） |
| 0x1418CDA90 | （未具名） "bg_btn"/"bg_strat_btn" GUI 串（战略层背景按钮） |
| 0x141FBF5B0 | CSkillTreeBase<NIndustrialOrganisation::CTraitTreeItem>::[26] "mutually_exclusive_icon_" + CSkillTreeBase 类名（MIO 技能树 GUI 槽 26） |
| 0x1419D37A0 | （未具名） "TRIGGER_FULLFILLED_PREFIX" loc 键（触发器描述前缀生成） |
| 0x141E33400 | （未具名） "GFX_industrial_capacity_icon" + "GFX_"/"_medium"（工业容量图标 GUI） |
| 0x14149D630 | （未具名） "DESIGNER_DEPLOYED_LEADER_MODIFIERS" + CModifier 类名（设计公司部署领袖修正） |
| 0x140B45600 | （未具名） "pDesignCompanyBonus->GetIdea()->IsDesigner()" + "GFX_idea_unknown" + gamegui.cpp:753（设计公司构想图标） |
| 0x1412037A0 | （未具名） "Expected opening brace" + pdx_parser.h:2222（对象块反序列化 Reader） |
| 0x1415F56E0 | （未具名） "relations_info"/"diplomatic_actions"/"relations_tab_button" GUI 串（外交关系面板） |
| 0x140D37C60 | CGameDate vtable CGameDate vtable §4.1 CGameState/gamestate |
| 0x141E336C0 | （未具名） "resource_progress"/"resource_amount"/"resource_icon" 资源进度条 GUI |
| 0x140B1E780 | （未具名） gamestate.h:1125 断言 + "LIST"/"alert_decision_new_delayed"（决策提醒列表） |
| 0x1402783C0 | （未具名） "Province tooltip debug DISABLED/ENABLED" 调试开关（控制台命令族，同 16/449/450） |
| 0x141D3E080 | （未具名） "plane_archetype_header_entry" + CPlaneArchetypeHeaderItem 类名（飞机原型表头 GUI） |
| 0x1401DA110 | （未具名） gamestate.cpp:7716 + "Tag.IsValid() && TagIndex < _CountryControllersEnable.GetSize()" + "pConference != nullptr" 断言 |
| 0x141F3F300 | （未具名） "bookmark_entry" + CBookmarkEntry 类名（开局书签条目 GUI） |
| 0x14024FF90 | （未具名） "Water enabled"/"Water disabled" 调试开关（控制台命令族，同族 449/450/407） |
| 0x140DEFC00 | （未具名） "Expected opening brace" + pdx_parser.h:2222（对象块反序列化 Reader） |
| 0x1419D4E10 | （未具名） id_generator.h:28 + "_IdStoreIndex >= 0" + "ThreadIsMainThread()" 断言（ID 生成器） |
| 0x141D32DE0 | （未具名） "armyview_air_entry" + CAirMilitaryOverviewItem 类名（军队视图空军条目） |
| 0x140072820 | （未具名） "_design_cost_factor"/"Equipment cost factor."（装备设计成本因子） |
| 0x141A9E350 | CAirBaseAccessAction::CanExecute 类名（空军基地访问动作）+ "DIPLOMACY_NO_AT_WAR" loc 键 |
| 0x140DCB8C0 | （未具名） "mod/"/"save games/"/"/save games/" 路径串（存档/mod 目录处理） |
| 0x140372100 | CAddCivilWarTarget::GetDesc EFFECT_ADD_CIVIL_WAR_TARGET loc 键 |
| 0x14173BB00 | （未具名） "PRODUCTION_FILTER_CLICK_TO_SHOW/CLICK_TO_HIDE/SHIFTCLICK" loc 键（生产过滤器 GUI） |
| 0x141C1D120 | （未具名） "FACTION_RESEARCH_FACILITY_NOT_ENOUGH_INITIATIVE"/"FACTION_RESEARCH_FACILITY_MAX_REACHED" loc 键 |
| 0x141F08000 | （未具名） "FORTS"/"RAILWAY_GUN_BOMBARDMENT_FORT_MODIFIER_DELAYED" + CUnitAdjuster 类名 |
| 0x14155A450 | （未具名） "select_law_entry_container" + COccupationPolicySelectLawEntry 类名（占领政策选法条目） |
| 0x1417566F0 | （未具名） "global_alerticon_window" + CDiplomacyRequestIcon 类名（外交请求提醒图标） |
| 0x141DEE930 | （未具名） "CAREER_PROFILE_AWARDS_NOT_AVAILABLE_IN_MULTIPLAYER"/"CAREER_PROFILE_STEAM_NOT_RUNNING" + CServer/CNetworkServer/CProxyServer 类名 |
| 0x141E42C20 | （未具名） "OPERATIVE_FORCED_INTO_HIDING"/"OPERATIVE_HARMED_IN_MISSION"/"DURATION_DAYS" loc 键（特工状态） |
| 0x141DD68A0 | （未具名） "designer_stat_entry"/"STAT_NAVY_HIT_PROFILE" + "STAT_NAVY_HIT_PROFILE_VALUE"（海军设计器统计 GUI） |
| 0x14024E0B0 | （未具名） "Debugging tactics (tooltip combats) OFF/ON" 调试开关（控制台命令族） |
| 0x140293C50 | （未具名） "Showing player ships: OFF/ON" 调试开关（控制台命令族） |
| 0x140EDAEA0 | （未具名） "PROGRESS"/"RESEARCH_PROGRESS"/"DAYS"/"DAYS_SAVED" loc 键（科研进度 GUI） |
| 0x141FE4410 | （未具名） "CAREER_PROFILE_STAT_PLAIN_NUMBER"/"VALUE" loc 键（职业档案统计 GUI） |
| 0x140A1DDF0 | （未具名） "COLLECTION_OP_FACTION_MEMBERS"/"COLLECTION_OP_OWNED_STATES"/"COLLECTION_OP_CONTROLLED_STATES"/"COLLECTION_OP_COUNTRY_AND_ALL_SUBJECTS"（集合运算符） |
| 0x141D73AD0 | CDecisionViewTargetedDecisionItem（vtable 槽 [21]） CGameState 单例访问（gamestate.h 断言 _pInstance && / _ThreadForbidCount == 0） |
| 0x140C047E0 | CUnit（vtable 槽 [12]） CGameState 单例访问（gamestate.h 断言 _pInstance && / _ThreadForbidCount == 0） |
| 0x14138B200 | CNationalFocusView（vtable 槽 [6]） CGameState 单例访问（gamestate.h 断言 _pInstance && / _ThreadForbidCount == 0） |

#### 4.1.22 CGameState 派发族与门控函数补遗（2947 函）

| VA | 语义/证据 |
|---|---|
| 0x14134F730 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0）+ 键 default_confirmation_popup（CGameState 弹窗） |
| 0x141673610 | （无名，按证据定性） gamestate.h:1125 断言站点（CGameState 成员） |
| 0x14118B210 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x1422B2B70 | （无名，按证据定性） 多列表（a1+4396/4432/4444/4480/4492/4588）逐元素调 vtable+544（CGameState 批量更新分发） |
| 0x140B0F5A0 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x140CF0030 | （无名，按证据定性） gamestate.h:1116 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x141C9F550 | （无名，按证据定性） gamestate.h:1116 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x141B4DC00 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x1418964A0 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x140F36710 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x141FCD0F0 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x141DCB290 | （无名，按证据定性） gamestate.h:1125 断言站点（CGameState 成员） |
| 0x14105CDD0 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x141A1F630 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x141870310 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x140F362D0 | （无名，按证据定性） gamestate.h:1126 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x14123D430 | （无名，按证据定性） gamestate.h:1125 断言站点（CGameState 成员） |
| 0x141A945B0 | （无名，按证据定性） gamestate.h:1125 断言站点（_pInstance&&_ThreadForbidCount==0，CGameState 成员） |
| 0x1417A01C0 | （无名，按证据定性） gamestate.h:1125 断言站点（CGameState 成员） |
| 0x140A2C6B0 | （无名） 体设 CFactionRule::vftable（RTTI 名） |
| 0x140E9D7C0 | （无名） 体设 CTaskForceComposition::vftable（RTTI 名） |
| 0x14032CE70 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x140AB16F0 | CScriptedDiplomaticAction::[24] vtable 槽 CScriptedDiplomaticAction::[24]（func_names RTTI 名） |
| 0x1406CBAC0 | （无名） 体设 CConvoys::vftable（RTTI 名） |
| 0x141B790E0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14224F9B0 | CSession::[1] vtable 槽 CSession::[1]（func_names RTTI 名） |
| 0x142401DF0 | （无名） 体设 CSteamStoreContext::vftable（RTTI 名） |
| 0x140A11210 | （无名） 体设 CProgressSection::vftable（RTTI 名） |
| 0x140F6F700 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x142293C10 | CPdxParticleObject::[16] vtable 槽 CPdxParticleObject::[16]（func_names RTTI 名） |
| 0x141C8B9F0 | （无名） 体设 CDiplomacyCountryBaseWarGoalActionController::vftable（RTTI 名） |
| 0x140A51690 | （无名） 体设 CEquipmentGroup::vftable（RTTI 名） |
| 0x140C0BEF0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141102360 | CStageCoupAction::[24] vtable 槽 CStageCoupAction::[24]（func_names RTTI 名） |
| 0x1422A9E50 | CSmoothListbox::[20] vtable 槽 CSmoothListbox::[20]（func_names RTTI 名） |
| 0x140CE1A60 | （无名） 体设 CNavalCombatResultSide::vftable（RTTI 名） |
| 0x1414463A0 | （无名） 体设 CUnitMedalStore::vftable（RTTI 名） |
| 0x141100BC0 | CCancelForeignManpowerAction::[24] vtable 槽 CCancelForeignManpowerAction::[24]（func_names RTTI 名） |
| 0x140A34AF0 | （无名） 体设 CGameRuleOption::vftable（RTTI 名） |
| 0x1410FB280 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422AA310 | CStandardlistbox::[34] vtable 槽 CStandardlistbox::[34]（func_names RTTI 名） |
| 0x14208D160 | CTweakableCharArrayManipulator::[13] vtable 槽 CTweakableCharArrayManipulator::[13]（func_names RTTI 名） |
| 0x141100CB0 | CCancelLicensedProductionAction::[24] vtable 槽 CCancelLicensedProductionAction::[24]（func_names RTTI 名） |
| 0x1413E0500 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x141A9EE40 | COfferDockingRightsAction::[24] vtable 槽 COfferDockingRightsAction::[24]（func_names RTTI 名） |
| 0x1411013E0 | CIncreaseAutonomyAction::[24] vtable 槽 CIncreaseAutonomyAction::[24]（func_names RTTI 名） |
| 0x140ACAB90 | （无名） 体设 CTechnologyPath::vftable（RTTI 名） |
| 0x141101600 | CMilitaryAccessAction::[24] vtable 槽 CMilitaryAccessAction::[24]（func_names RTTI 名） |
| 0x1411019C0 | CReduceAutonomyAction::[24] vtable 槽 CReduceAutonomyAction::[24]（func_names RTTI 名） |
| 0x1412DD360 | CGfxTradeRouteConvoy::[1] vtable 槽 CGfxTradeRouteConvoy::[1]（func_names RTTI 名） |
| 0x140A35A20 | CGameRulesDatabase::[1] vtable 槽 CGameRulesDatabase::[1]（func_names RTTI 名） |
| 0x140A8B7F0 | （无名） 体设 CPowerBalanceSide::vftable（RTTI 名） |
| 0x14071DDA0 | CCountryLeaderDatabase::[1] vtable 槽 CCountryLeaderDatabase::[1]（func_names RTTI 名） |
| 0x140C307B0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1423E0C10 | CSteamMatchmakingContext::[15] vtable 槽 CSteamMatchmakingContext::[15]（func_names RTTI 名） |
| 0x140A00CE0 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x141FC4570 | （无名） 体设 CSavedGameRulesController::vftable（RTTI 名） |
| 0x1402DE370 | （无名） 体设 CSaveGameController::vftable（RTTI 名） |
| 0x140AC01D0 | CStrategicRegionDatabase::[1] vtable 槽 CStrategicRegionDatabase::[1]（func_names RTTI 名） |
| 0x141A34DB0 | （无名） 体设 CCapturedOperativeReference::vftable（RTTI 名） |
| 0x141AA3B60 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1410FB1B0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x142300FA0 | CSmoothListbox::[8] vtable 槽 CSmoothListbox::[8]（func_names RTTI 名） |
| 0x14201B520 | （无名） 体设 SCareerProfileRibbonData::vftable（RTTI 名） |
| 0x1416CB2E0 | CUnitLeaderTraitTree::[20] vtable 槽 CUnitLeaderTraitTree::[20]（func_names RTTI 名） |
| 0x141639C20 | CTheaterGroup::[0] vtable 槽 CTheaterGroup::[0]（func_names RTTI 名） |
| 0x14201B440 | （无名） 体设 SCareerProfileMedalData::vftable（RTTI 名） |
| 0x1416510C0 | （无名） 体设 SDistanceMesh::vftable（RTTI 名） |
| 0x141DFFBD0 | （无名） 体设 SCachedInfo::vftable（RTTI 名） |
| 0x1424043A0 | CSteamUGCContext::[12] vtable 槽 CSteamUGCContext::[12]（func_names RTTI 名） |
| 0x14201AF50 | （无名） 体设 SCareerProfileRibbonData::vftable（RTTI 名） |
| 0x1409C0FA0 | （无名） 体设 CNameGroupMember::vftable（RTTI 名） |
| 0x1411208E0 | CRequestAccessToLicenseProductionAction::[59] vtable 槽 CRequestAccessToLicenseProductionAction::[59]（func_names RTTI 名） |
| 0x140BBD520 | CIdCounterStore::SIdCounter::[4] vtable 槽 CIdCounterStore::SIdCounter::[4]（func_names RTTI 名） |
| 0x141285430 | （无名） 体设 SPostEffectVolumeReader::vftable（RTTI 名） |
| 0x1423DC920 | CSteamCloudFile::[8] vtable 槽 CSteamCloudFile::[8]（func_names RTTI 名） |
| 0x1401C0D80 | （无名） 体设 CHuman::vftable（RTTI 名） |
| 0x140E57450 | （无名） 体设 CPowerBalanceSideInfo::vftable（RTTI 名） |
| 0x1423011B0 | CSmoothListbox::[40] vtable 槽 CSmoothListbox::[40]（func_names RTTI 名） |
| 0x1423DDEB0 | CSteamCloudStorageContext::[3] vtable 槽 CSteamCloudStorageContext::[3]（func_names RTTI 名） |
| 0x14143C610 | CTerrainType::[0] vtable 槽 CTerrainType::[0]（func_names RTTI 名） |
| 0x140ABC380 | CStateDatabase::[1] vtable 槽 CStateDatabase::[1]（func_names RTTI 名） |
| 0x1415B9390 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x1415A40A0 | （无名） 体设 CStrategicRegionTemplate::vftable（RTTI 名） |
| 0x1422ED940 | （无名） 体设 CTextBuffer::vftable（RTTI 名） |
| 0x142363400 | CDummyServer::[0] vtable 槽 CDummyServer::[0]（func_names RTTI 名） |
| 0x141914C50 | CAutomaticPause::[0] vtable 槽 CAutomaticPause::[0]（func_names RTTI 名） |
| 0x14153E6A0 | CFriendsHandlerSteam::[7] vtable 槽 CFriendsHandlerSteam::[7]（func_names RTTI 名） |
| 0x140AAD690 | （无名） 体设 CScriptedMapModeDatabase::vftable（RTTI 名） |
| 0x1414FBA70 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x142089710 | CTweakableArrayCurveManipulator::[0] vtable 槽 CTweakableArrayCurveManipulator::[0]（func_names RTTI 名） |
| 0x1411486C0 | （无名） 体设 SAdvisorData::vftable（RTTI 名） |
| 0x142354D70 | CCorneredTileSprite::[40] vtable 槽 CCorneredTileSprite::[40]（func_names RTTI 名） |
| 0x14064CE80 | CAIFocusDatabase::[1] vtable 槽 CAIFocusDatabase::[1]（func_names RTTI 名） |
| 0x141982370 | （无名） 体设 CTowardsPlayersRedistributer::vftable（RTTI 名） |
| 0x140BBD470 | CIdCounterStore::[3] vtable 槽 CIdCounterStore::[3]（func_names RTTI 名） |
| 0x1411A3090 | （无名） 体设 CPoliticalParty::vftable（RTTI 名） |
| 0x14208D050 | CTweakableCategory::[13] vtable 槽 CTweakableCategory::[13]（func_names RTTI 名） |
| 0x140674140 | CAutonomousStateDatabase::[1] vtable 槽 CAutonomousStateDatabase::[1]（func_names RTTI 名） |
| 0x1406D0900 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140BBC720 | （无名） 体设 CHuman::vftable（RTTI 名） |
| 0x1415B9460 | CNavyTheaterGroup::[0] vtable 槽 CNavyTheaterGroup::[0]（func_names RTTI 名） |
| 0x14111F5C0 | CCancelForeignManpowerAction::[58] vtable 槽 CCancelForeignManpowerAction::[58]（func_names RTTI 名） |
| 0x14196DFD0 | CLendLeaseExchange::[11] vtable 槽 CLendLeaseExchange::[11]（func_names RTTI 名） |
| 0x1416561B0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x14031E8F0 | CAddDoctrineCostReduction::[0] vtable 槽 CAddDoctrineCostReduction::[0]（func_names RTTI 名） |
| 0x1402C7600 | （无名） 体设 SScriptedKey::vftable（RTTI 名） |
| 0x141871290 | CPlayerLobby::[4] vtable 槽 CPlayerLobby::[4]（func_names RTTI 名） |
| 0x141CA69F0 | （无名） 体设 CRelationStripViewBase::vftable（RTTI 名） |
| 0x140F9B540 | （无名） 体设 SAddedResistanceTarget::vftable（RTTI 名） |
| 0x1414543F0 | CConferenceLoserParticipant::[0] vtable 槽 CConferenceLoserParticipant::[0]（func_names RTTI 名） |
| 0x1415DDE40 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x141F61440 | （无名） 体设 CReinforcementPreferenceOption::vftable（RTTI 名） |
| 0x141F31600 | （无名） 体设 CUpdateable::vftable（RTTI 名） |
| 0x141B90A90 | CAiIndustrialOrganisation::COrganisationState::[1] vtable 槽 CAiIndustrialOrganisation::COrganisationState::[1]（func_names RTTI 名） |
| 0x1414EB810 | （无名） 体设 CAirTheatre::vftable（RTTI 名） |
| 0x14202B380 | （无名） 体设 CEquipmentVariantPool::vftable（RTTI 名） |
| 0x1404A3EA0 | CPartyLeaderTarget::[26] vtable 槽 CPartyLeaderTarget::[26]（func_names RTTI 名） |
| 0x141284E80 | （无名） 体设 SPostEffectHeightVolumeReader::vftable（RTTI 名） |
| 0x1422D4AF0 | CInstantSprite::[43] vtable 槽 CInstantSprite::[43]（func_names RTTI 名） |
| 0x141445D20 | （无名） 体设 CSunkShipInfo::vftable（RTTI 名） |
| 0x1417CED70 | CNavalMissionExtension::[2] vtable 槽 CNavalMissionExtension::[2]（func_names RTTI 名） |
| 0x141639B70 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x140F755E0 | （无名） 体设 CAirMission::vftable（RTTI 名） |
| 0x140D74A30 | CTaskForce::[1] vtable 槽 CTaskForce::[1]（func_names RTTI 名） |
| 0x1423E4D90 | CSteamMatchmakingContext::[44] vtable 槽 CSteamMatchmakingContext::[44]（func_names RTTI 名） |
| 0x140C0BA10 | （无名） 体设 CNameGroupMember::vftable（RTTI 名） |
| 0x141981790 | CDockingRightsRelation::[22] vtable 槽 CDockingRightsRelation::[22]（func_names RTTI 名） |
| 0x141C97770 | CDiplomacyStandardController::[12] vtable 槽 CDiplomacyStandardController::[12]（func_names RTTI 名） |
| 0x1410FA200 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141A9E810 | CAirBaseAccessAction::[57] vtable 槽 CAirBaseAccessAction::[57]（func_names RTTI 名） |
| 0x1413F8810 | （无名） 体设 CCountryDecryptionState::vftable（RTTI 名） |
| 0x14230FDD0 | CContainerWindowType::[10] vtable 槽 CContainerWindowType::[10]（func_names RTTI 名） |
| 0x140D7D350 | （无名） 体设 SMasteryFromUnitLeader::vftable（RTTI 名） |
| 0x140B881E0 | CScriptedWindowGUIUpdater::[0] vtable 槽 CScriptedWindowGUIUpdater::[0]（func_names RTTI 名） |
| 0x141982290 | （无名） 体设 CSmallScoresRedistributer::vftable（RTTI 名） |
| 0x14070FE70 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140FB7650 | CNavalMission::[8] vtable 槽 CNavalMission::[8]（func_names RTTI 名） |
| 0x1423DDA10 | CSteamCloudFile::[1] vtable 槽 CSteamCloudFile::[1]（func_names RTTI 名） |
| 0x1422AB030 | CStandardlistbox::[5] vtable 槽 CStandardlistbox::[5]（func_names RTTI 名） |
| 0x1423DDF50 | CSteamCloudStorageContext::[9] vtable 槽 CSteamCloudStorageContext::[9]（func_names RTTI 名） |
| 0x140222BA0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1414FB9B0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140C2DE70 | CSunkShipInfo::[0] vtable 槽 CSunkShipInfo::[0]（func_names RTTI 名） |
| 0x141516680 | （无名） 体设 CLoopHistoryContainer::vftable（RTTI 名） |
| 0x140E5CCE0 | CNamedEquipmentBonus::[0] vtable 槽 CNamedEquipmentBonus::[0]（func_names RTTI 名） |
| 0x140DDD990 | CInGameIdler::[76] vtable 槽 CInGameIdler::[76]（func_names RTTI 名） |
| 0x140E86B90 | （无名） 体设 CBuildingReference::vftable（RTTI 名） |
| 0x141B03FC0 | （无名） 体设 CEvolveEquipmentImgui::vftable（RTTI 名） |
| 0x140483870 | CSetPowerBalanceGfx::[0] vtable 槽 CSetPowerBalanceGfx::[0]（func_names RTTI 名） |
| 0x141871060 | CPlayerLobby::[9] vtable 槽 CPlayerLobby::[9]（func_names RTTI 名） |
| 0x140725690 | CDecisionCategory::CCustomIcon::[0] vtable 槽 CDecisionCategory::CCustomIcon::[0]（func_names RTTI 名） |
| 0x1411BD590 | （无名） 体设 CLocalIntelNetwork::vftable（RTTI 名） |
| 0x142296900 | CPdxParticleType::[9] vtable 槽 CPdxParticleType::[9]（func_names RTTI 名） |
| 0x1402CD3B0 | CTreeShortcut::[0] vtable 槽 CTreeShortcut::[0]（func_names RTTI 名） |
| 0x140FE29B0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14140BF00 | CScientist::[8] vtable 槽 CScientist::[8]（func_names RTTI 名） |
| 0x140BC2AC0 | （无名） 体设 CSelectable::vftable（RTTI 名） |
| 0x1423C3520 | CBrowserInstance::[12] vtable 槽 CBrowserInstance::[12]（func_names RTTI 名） |
| 0x1415DE480 | （无名） 体设 CWarGoal::vftable（RTTI 名） |
| 0x1413C4350 | CStateCategoryDatabase::[1] vtable 槽 CStateCategoryDatabase::[1]（func_names RTTI 名） |
| 0x14113A820 | CTransferSpyMasterAction::[57] vtable 槽 CTransferSpyMasterAction::[57]（func_names RTTI 名） |
| 0x14237F880 | （无名） 体设 StackWalker::vftable（RTTI 名） |
| 0x1424EABB0 | （无名） 体设 Node_end_group::vftable（RTTI 名） |
| 0x1413C0670 | （无名） 体设 CBuildingReference::vftable（RTTI 名） |
| 0x14014BCA0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1423AACF0 | PdxTextToSpeechWinSAPI::[5] vtable 槽 PdxTextToSpeechWinSAPI::[5]（func_names RTTI 名） |
| 0x140C12C60 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x140302770 | （无名） 体设 CScopedVariableWithPostValidate::vftable（RTTI 名） |
| 0x142089CE0 | CTweakableTextbox::[0] vtable 槽 CTweakableTextbox::[0]（func_names RTTI 名） |
| 0x14039DCD0 | CRandomCountryWithOriginalTag::[29] vtable 槽 CRandomCountryWithOriginalTag::[29]（func_names RTTI 名） |
| 0x142364F10 | CNetworkServer::[0] vtable 槽 CNetworkServer::[0]（func_names RTTI 名） |
| 0x140160040 | COccupationModifierDatabase::[1] vtable 槽 COccupationModifierDatabase::[1]（func_names RTTI 名） |
| 0x140FF35C0 | CResistanceActivityLog::[0] vtable 槽 CResistanceActivityLog::[0]（func_names RTTI 名） |
| 0x141339500 | （无名） 体设 CPdxSocialPlayerId::vftable（RTTI 名） |
| 0x140D45600 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x142402320 | CSteamStoreContext::[19] vtable 槽 CSteamStoreContext::[19]（func_names RTTI 名） |
| 0x14253E6CC | （无名） 体设 Node::vftable（RTTI 名） |
| 0x141DF9520 | CStandardMusicPlaylistController::[10] vtable 槽 CStandardMusicPlaylistController::[10]（func_names RTTI 名） |
| 0x142373760 | CExtendedScrollbarType::[0] vtable 槽 CExtendedScrollbarType::[0]（func_names RTTI 名） |
| 0x1417F61E0 | CNavalLossesOverview::[0] vtable 槽 CNavalLossesOverview::[0]（func_names RTTI 名） |
| 0x1410FBAE0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14031EC20 | CTechnologyTemplateVariable::[0] vtable 槽 CTechnologyTemplateVariable::[0]（func_names RTTI 名） |
| 0x140ABAAD0 | （无名） 体设 CSpecializationTemplate::vftable（RTTI 名） |
| 0x140F80CB0 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x140C2DDB0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140EB2DD0 | CStrategicOperativeManager::[0] vtable 槽 CStrategicOperativeManager::[0]（func_names RTTI 名） |
| 0x141981500 | CAirBaseAccessRelation::[21] vtable 槽 CAirBaseAccessRelation::[21]（func_names RTTI 名） |
| 0x140C1E460 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x1410FA770 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140688070 | （无名） 体设 CDatabaseObject::vftable（RTTI 名） |
| 0x1423E0B80 | CSteamMatchmakingContext::[14] vtable 槽 CSteamMatchmakingContext::[14]（func_names RTTI 名） |
| 0x1423AC360 | PdxSpeechToTextWinSAPI::[2] vtable 槽 PdxSpeechToTextWinSAPI::[2]（func_names RTTI 名） |
| 0x14014B6E0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x141097910 | （无名） 体设 CNuke::vftable（RTTI 名） |
| 0x14103B9D0 | （无名） 体设 SChildFrontData::vftable（RTTI 名） |
| 0x1401606B0 | CResistanceActivityDatabase::[1] vtable 槽 CResistanceActivityDatabase::[1]（func_names RTTI 名） |
| 0x1410FB750 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140CB6680 | CCountryResources::[1] vtable 槽 CCountryResources::[1]（func_names RTTI 名） |
| 0x140A6EF00 | STaskforceCompositionReader::[2] vtable 槽 STaskforceCompositionReader::[2]（func_names RTTI 名） |
| 0x140AB19A0 | CScriptedDiplomaticAction::[63] vtable 槽 CScriptedDiplomaticAction::[63]（func_names RTTI 名） |
| 0x14143C270 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141510B50 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x141F6B550 | CConfirmDeleteEquipmentProductionLine::[14] vtable 槽 CConfirmDeleteEquipmentProductionLine::[14]（func_names RTTI 名） |
| 0x1422AE600 | CSprite::[26] vtable 槽 CSprite::[26]（func_names RTTI 名） |
| 0x141370AB0 | CLogisticsStatus::[0] vtable 槽 CLogisticsStatus::[0]（func_names RTTI 名） |
| 0x1422AAB20 | CStandardlistbox::[60] vtable 槽 CStandardlistbox::[60]（func_names RTTI 名） |
| 0x1423001D0 | CSmoothListbox::[60] vtable 槽 CSmoothListbox::[60]（func_names RTTI 名） |
| 0x140AB2C30 | CScriptedDiplomaticAction::[43] vtable 槽 CScriptedDiplomaticAction::[43]（func_names RTTI 名） |
| 0x141017FE0 | （无名） 体设 CSubUnitCategory::vftable（RTTI 名） |
| 0x1422D5BF0 | CTextSprite::[2] vtable 槽 CTextSprite::[2]（func_names RTTI 名） |
| 0x1410F9810 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1423967F0 | CPdxCrashReportWindows::[2] vtable 槽 CPdxCrashReportWindows::[2]（func_names RTTI 名） |
| 0x1410FB370 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141600670 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140A03AB0 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x14143C1B0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1406CEEE0 | CCustomizableBuildingCollection::[0] vtable 槽 CCustomizableBuildingCollection::[0]（func_names RTTI 名） |
| 0x1423EA3F0 | CSteamNetContext::[23] vtable 槽 CSteamNetContext::[23]（func_names RTTI 名） |
| 0x1406C95D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140AB4820 | CScriptedDiplomaticAction::[32] vtable 槽 CScriptedDiplomaticAction::[32]（func_names RTTI 名） |
| 0x14015FF90 | COccupationLawDatabase::[1] vtable 槽 COccupationLawDatabase::[1]（func_names RTTI 名） |
| 0x1406C9650 | （无名） 体设 CNuke::vftable（RTTI 名） |
| 0x140681D60 | （无名） 体设 CFormattedLocalization::vftable（RTTI 名） |
| 0x1423713D0 | CDropDownBoxType::[10] vtable 槽 CDropDownBoxType::[10]（func_names RTTI 名） |
| 0x1417CA980 | CMapMode::[9] vtable 槽 CMapMode::[9]（func_names RTTI 名） |
| 0x141C8C280 | CDiplomacyGuaranteeActionController::[1] vtable 槽 CDiplomacyGuaranteeActionController::[1]（func_names RTTI 名） |
| 0x140146EE0 | （无名） 体设 CAiFactionTheater::vftable（RTTI 名） |
| 0x1409CF800 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141F60D80 | （无名） 体设 CDayNightCycleOptionSelections::vftable（RTTI 名） |
| 0x140A80840 | COpinionModifierDatabase::[1] vtable 槽 COpinionModifierDatabase::[1]（func_names RTTI 名） |
| 0x1410FAF50 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14208D410 | CTweakableEnumManipulator::[13] vtable 槽 CTweakableEnumManipulator::[13]（func_names RTTI 名） |
| 0x1422E59B0 | CSystemMessage::[10] vtable 槽 CSystemMessage::[10]（func_names RTTI 名） |
| 0x140F5A9E0 | CAirWingPool::[0] vtable 槽 CAirWingPool::[0]（func_names RTTI 名） |
| 0x1410FA9E0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1410FB4F0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1420AD510 | CMapIdler::[3] vtable 槽 CMapIdler::[3]（func_names RTTI 名） |
| 0x1423AB180 | PdxTextToSpeechWinSAPI::[8] vtable 槽 PdxTextToSpeechWinSAPI::[8]（func_names RTTI 名） |
| 0x1410055C0 | （无名） 体设 CDominanceValues::vftable（RTTI 名） |
| 0x1422D1640 | CButtonStandard::[109] vtable 槽 CButtonStandard::[109]（func_names RTTI 名） |
| 0x1410FC3E0 | （无名） 体设 CRequestLicensedProductionAction::vftable（RTTI 名） |
| 0x140F6EF40 | CNavalProductionLine::[12] vtable 槽 CNavalProductionLine::[12]（func_names RTTI 名） |
| 0x1413EFA40 | CLandBorderWarCombatant::[16] vtable 槽 CLandBorderWarCombatant::[16]（func_names RTTI 名） |
| 0x1401757B0 | CApplication::[2] vtable 槽 CApplication::[2]（func_names RTTI 名） |
| 0x1412D2780 | COption::[2] vtable 槽 COption::[2]（func_names RTTI 名） |
| 0x142231020 | CKeyBoard::[2] vtable 槽 CKeyBoard::[2]（func_names RTTI 名） |
| 0x1422310B0 | CKeyBoard::[2] vtable 槽 CKeyBoard::[2]（func_names RTTI 名） |
| 0x142231140 | CMouse::[2] vtable 槽 CMouse::[2]（func_names RTTI 名） |
| 0x1422311D0 | CMouse::[2] vtable 槽 CMouse::[2]（func_names RTTI 名） |
| 0x142231260 | CMouse::[2] vtable 槽 CMouse::[2]（func_names RTTI 名） |
| 0x1422312F0 | CMouse::[2] vtable 槽 CMouse::[2]（func_names RTTI 名） |
| 0x1410FAB60 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141B5BCD0 | CStateNudger::[2] vtable 槽 CStateNudger::[2]（func_names RTTI 名） |
| 0x14015FCC0 | CHistoricalAgencyDatabase::[1] vtable 槽 CHistoricalAgencyDatabase::[1]（func_names RTTI 名） |
| 0x140D7FB30 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x1415167D0 | CLoopHistoryContainer::[0] vtable 槽 CLoopHistoryContainer::[0]（func_names RTTI 名） |
| 0x1423DC850 | CSteamCloudStorageContext::[0] vtable 槽 CSteamCloudStorageContext::[0]（func_names RTTI 名） |
| 0x140222B20 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140641A40 | （无名） 体设 CSubUnitStatBonus::vftable（RTTI 名） |
| 0x1423DDAC0 | CSteamCloudStorageContext::[14] vtable 槽 CSteamCloudStorageContext::[14]（func_names RTTI 名） |
| 0x1423E1380 | CSteamMatchmakingContext::[1] vtable 槽 CSteamMatchmakingContext::[1]（func_names RTTI 名） |
| 0x1410FA440 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1412981F0 | （无名） 体设 CBuildingReference::vftable（RTTI 名） |
| 0x14143C560 | CTerrainGraphics::[0] vtable 槽 CTerrainGraphics::[0]（func_names RTTI 名） |
| 0x1422CEF00 | CBrowser::[24] vtable 槽 CBrowser::[24]（func_names RTTI 名） |
| 0x1410F9F50 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1423DC5F0 | （无名） 体设 CSteamCloudStorageContext::vftable（RTTI 名） |
| 0x141019920 | CSubUnitCategory::[0] vtable 槽 CSubUnitCategory::[0]（func_names RTTI 名） |
| 0x1417CEBD0 | （无名） 体设 CMissionExtension::vftable（RTTI 名） |
| 0x14068E520 | （无名） 体设 SCareerProfileModDataSet::vftable（RTTI 名） |
| 0x140AB0B90 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1412A62B0 | CCountryExperienceStatus::[0] vtable 槽 CCountryExperienceStatus::[0]（func_names RTTI 名） |
| 0x14237FA00 | StackWalker::[0] vtable 槽 StackWalker::[0]（func_names RTTI 名） |
| 0x140681E70 | （无名） 体设 SCountryModifier::vftable（RTTI 名） |
| 0x14230D520 | （无名） 体设 SMeshVariant::vftable（RTTI 名） |
| 0x1401E4190 | （无名） 体设 CScriptFlag::vftable（RTTI 名） |
| 0x14206DA80 | （无名） 体设 CAIModule::vftable（RTTI 名） |
| 0x1409C2830 | （无名） 体设 CNameGroupMember::vftable（RTTI 名） |
| 0x140A57B60 | （无名） 体设 System_error::vftable（RTTI 名） |
| 0x1416417D0 | （无名） 体设 CMaskedSpriteType::vftable（RTTI 名） |
| 0x141C906A0 | CDiplomacyGiveStateControlController::[0] vtable 槽 CDiplomacyGiveStateControlController::[0]（func_names RTTI 名） |
| 0x1422D17E0 | CButtonStandard::[116] vtable 槽 CButtonStandard::[116]（func_names RTTI 名） |
| 0x140F80C00 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x14206DB10 | CAIModule::[0] vtable 槽 CAIModule::[0]（func_names RTTI 名） |
| 0x140B64350 | CErrorLogIndicator::[0] vtable 槽 CErrorLogIndicator::[0]（func_names RTTI 名） |
| 0x140C1E520 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x1416002D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x142373AC0 | CExtendedScrollbarType::[10] vtable 槽 CExtendedScrollbarType::[10]（func_names RTTI 名） |
| 0x1411281B0 | CEmbargoAction::[36] vtable 槽 CEmbargoAction::[36]（func_names RTTI 名） |
| 0x140A34C70 | （无名） 体设 CGameRulesDatabase::vftable（RTTI 名） |
| 0x1411D0AC0 | CCountryIntelNetwork::[0] vtable 槽 CCountryIntelNetwork::[0]（func_names RTTI 名） |
| 0x14063B850 | （无名） 体设 CRuleDefinition::vftable（RTTI 名） |
| 0x140FCDB70 | （无名） 体设 CIdeaCategory::vftable（RTTI 名） |
| 0x1414DB730 | （无名） 体设 SBookmarkPlaythroughData::vftable（RTTI 名） |
| 0x1409C07A0 | CNameGroupTracker::[0] vtable 槽 CNameGroupTracker::[0]（func_names RTTI 名） |
| 0x142384360 | （无名） 体设 CKeyPressedObservable::vftable（RTTI 名） |
| 0x1405563A0 | （无名） 体设 CStaticModifier::vftable（RTTI 名） |
| 0x140F1F2E0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140A3BDA0 | （无名） 体设 CGraphicalCultureType::vftable（RTTI 名） |
| 0x1414E9AB0 | （无名） 体设 CRaidTargetCooldownStatus::vftable（RTTI 名） |
| 0x1415098A0 | （无名） 体设 CArmyReinforcementRequests::vftable（RTTI 名） |
| 0x140CDF6F0 | （无名） 体设 SCombatStats::vftable（RTTI 名） |
| 0x1423A96C0 | （无名） 体设 PdxTextToSpeechWinSAPI::vftable（RTTI 名） |
| 0x1415FFF00 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140F6E0D0 | CBuildingProductionLine::[8] vtable 槽 CBuildingProductionLine::[8]（func_names RTTI 名） |
| 0x1404985D0 | SIconReader::[0] vtable 槽 SIconReader::[0]（func_names RTTI 名） |
| 0x142356F40 | （无名） 体设 C2dCircularProgressBarType::vftable（RTTI 名） |
| 0x141620520 | CNavalCombatant::[11] vtable 槽 CNavalCombatant::[11]（func_names RTTI 名） |
| 0x142307D80 | CLineChart::[9] vtable 槽 CLineChart::[9]（func_names RTTI 名） |
| 0x1405365B0 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x140160900 | CScriptEnumDatabase::[1] vtable 槽 CScriptEnumDatabase::[1]（func_names RTTI 名） |
| 0x140AD7610 | （无名） 体设 CTimedActivityEquipmentDistributable::vftable（RTTI 名） |
| 0x1410D8F80 | COperativesAiAssignmentTextLogger::[1] vtable 槽 COperativesAiAssignmentTextLogger::[1]（func_names RTTI 名） |
| 0x14068EC10 | （无名） 体设 SGameModeStatistics::vftable（RTTI 名） |
| 0x14140CE20 | （无名） 体设 SSkillLevel::vftable（RTTI 名） |
| 0x141BA8C10 | （无名） 体设 CModifyFactionTheater::vftable（RTTI 名） |
| 0x14112D8E0 | CBoostPartyPopularityAction::[23] vtable 槽 CBoostPartyPopularityAction::[23]（func_names RTTI 名） |
| 0x1416465C0 | （无名） 体设 CAmbientObjectType::vftable（RTTI 名） |
| 0x1422ED0F0 | CInstantTextObject::[43] vtable 槽 CInstantTextObject::[43]（func_names RTTI 名） |
| 0x140A85F60 | （无名） 体设 CPortraitPool::vftable（RTTI 名） |
| 0x140A86000 | （无名） 体设 CPortraitPool::vftable（RTTI 名） |
| 0x140A83260 | CPeaceActionModifier::[0] vtable 槽 CPeaceActionModifier::[0]（func_names RTTI 名） |
| 0x140C18930 | CArmyLeader::[20] vtable 槽 CArmyLeader::[20]（func_names RTTI 名） |
| 0x1414DB680 | （无名） 体设 SBookmarkPlaythroughData::vftable（RTTI 名） |
| 0x141BA8990 | （无名） 体设 CCreateFactionTheater::vftable（RTTI 名） |
| 0x14208F640 | （无名） 体设 SForceReader::vftable（RTTI 名） |
| 0x140CEA410 | CMilitaryDeploymentConveyor::[8] vtable 槽 CMilitaryDeploymentConveyor::[8]（func_names RTTI 名） |
| 0x1412B8F30 | CLandCombat::[16] vtable 槽 CLandCombat::[16]（func_names RTTI 名） |
| 0x141517D30 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1406C1330 | CContinuousFocusPalette::[0] vtable 槽 CContinuousFocusPalette::[0]（func_names RTTI 名） |
| 0x141651990 | （无名） 体设 SDistanceMesh::vftable（RTTI 名） |
| 0x140D83B50 | CTechnologySharing::[8] vtable 槽 CTechnologySharing::[8]（func_names RTTI 名） |
| 0x140F80E00 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x140E866F0 | （无名） 体设 CBuildingReference::vftable（RTTI 名） |
| 0x141C321A0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141A37ED0 | （无名） 体设 CNarrative::vftable（RTTI 名） |
| 0x140497310 | （无名） 体设 CCompletePrototypeReward::vftable（RTTI 名） |
| 0x1410193F0 | （无名） 体设 CSubUnitCategory::vftable（RTTI 名） |
| 0x14112E5E0 | CStageCoupAction::[23] vtable 槽 CStageCoupAction::[23]（func_names RTTI 名） |
| 0x14143C3F0 | （无名） 体设 CTerrainGraphics::vftable（RTTI 名） |
| 0x140A85280 | CPeaceActionScriptedAiDesire::[7] vtable 槽 CPeaceActionScriptedAiDesire::[7]（func_names RTTI 名） |
| 0x1424B8AF0 | （无名） 体设 CTweakable::vftable（RTTI 名） |
| 0x142275F80 | CPdxMeshObject::[0] vtable 槽 CPdxMeshObject::[0]（func_names RTTI 名） |
| 0x140AB2670 | CScriptedDiplomaticAction::[42] vtable 槽 CScriptedDiplomaticAction::[42]（func_names RTTI 名） |
| 0x141A381F0 | （无名） 体设 SProjectHistory::vftable（RTTI 名） |
| 0x141471BB0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x14183FB90 | （无名） 体设 CAssignArmyToArmyGroupFront::vftable（RTTI 名） |
| 0x1410FB690 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1402A01D0 | CGameIdler::[8] vtable 槽 CGameIdler::[8]（func_names RTTI 名） |
| 0x141542A40 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x141646240 | （无名） 体设 CAmbientObject::vftable（RTTI 名） |
| 0x1422CEA70 | CBrowser::[7] vtable 槽 CBrowser::[7]（func_names RTTI 名） |
| 0x1423606E0 | CResizeableSpriteType::[9] vtable 槽 CResizeableSpriteType::[9]（func_names RTTI 名） |
| 0x1403C67A0 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x140D062E0 | CCountryIntel::[3] vtable 槽 CCountryIntel::[3]（func_names RTTI 名） |
| 0x142384030 | CPdxTouchDevice::[3] vtable 槽 CPdxTouchDevice::[3]（func_names RTTI 名） |
| 0x141BA7650 | （无名） 体设 CModifyFactionTheater::vftable（RTTI 名） |
| 0x142080500 | （无名） 体设 CTextBufferObserver::vftable（RTTI 名） |
| 0x140D7F8D0 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x140FDD690 | （无名） 体设 CCapturedOperativeReference::vftable（RTTI 名） |
| 0x14032CDD0 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x140C0B750 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x1412B3B00 | CLandCombatant::[27] vtable 槽 CLandCombatant::[27]（func_names RTTI 名） |
| 0x1415C0850 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x140F143B0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140120320 | CTbbThreadObserver::[2] vtable 槽 CTbbThreadObserver::[2]（func_names RTTI 名） |
| 0x141600530 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140CA5B80 | （无名） 体设 CResourceDeliveryRoute::vftable（RTTI 名） |
| 0x14061F840 | CAchievementMod::[11] vtable 槽 CAchievementMod::[11]（func_names RTTI 名） |
| 0x140B9E890 | （无名） 体设 CEquipmentVariantReference::vftable（RTTI 名） |
| 0x140C1E7C0 | CNavyLeader::[33] vtable 槽 CNavyLeader::[33]（func_names RTTI 名） |
| 0x140A11EE0 | CProgressSection::[9] vtable 槽 CProgressSection::[9]（func_names RTTI 名） |
| 0x1412AE7F0 | CLandCombat::[6] vtable 槽 CLandCombat::[6]（func_names RTTI 名） |
| 0x1413EBCD0 | CLandBorderWarCombat::[6] vtable 槽 CLandBorderWarCombat::[6]（func_names RTTI 名） |
| 0x1423E8AA0 | CSteamNetContext::[17] vtable 槽 CSteamNetContext::[17]（func_names RTTI 名） |
| 0x141DF95D0 | CStandardMusicPlaylistController::[9] vtable 槽 CStandardMusicPlaylistController::[9]（func_names RTTI 名） |
| 0x140DF6760 | CJointNationalFocus::[8] vtable 槽 CJointNationalFocus::[8]（func_names RTTI 名） |
| 0x140F14850 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141B7CCB0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1424FBA20 | CChecksumFile::[9] vtable 槽 CChecksumFile::[9]（func_names RTTI 名） |
| 0x1402CB9C0 | （无名） 体设 CNationalFocusProgress::vftable（RTTI 名） |
| 0x140535270 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x142231480 | CNullTouchDevice::[2] vtable 槽 CNullTouchDevice::[2]（func_names RTTI 名） |
| 0x142231500 | CNullTouchDevice::[3] vtable 槽 CNullTouchDevice::[3]（func_names RTTI 名） |
| 0x140C1E650 | CNavyLeader::[32] vtable 槽 CNavyLeader::[32]（func_names RTTI 名） |
| 0x142355E00 | CPdxSystem::[4] vtable 槽 CPdxSystem::[4]（func_names RTTI 名） |
| 0x140D890F0 | （无名） 体设 CTechnologySharing::vftable（RTTI 名） |
| 0x1413BB4B0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14022B7A0 | （无名） 体设 CCivilWarSetup::vftable（RTTI 名） |
| 0x14152C0B0 | （无名） 体设 CEquipmentModuleConversion::vftable（RTTI 名） |
| 0x141A2DC20 | CConfirmDeleteOrder::[0] vtable 槽 CConfirmDeleteOrder::[0]（func_names RTTI 名） |
| 0x141C95730 | CDiplomacyLendLeaseActionController::[5] vtable 槽 CDiplomacyLendLeaseActionController::[5]（func_names RTTI 名） |
| 0x1423E2EF0 | CSteamMatchmakingContext::[25] vtable 槽 CSteamMatchmakingContext::[25]（func_names RTTI 名） |
| 0x140631460 | （无名） 体设 CEquipmentBonus::vftable（RTTI 名） |
| 0x141E33DC0 | CMapModeOperationSelectTarget::[2] vtable 槽 CMapModeOperationSelectTarget::[2]（func_names RTTI 名） |
| 0x140C0CFC0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x14112E030 | CNonAggressionPactAction::[23] vtable 槽 CNonAggressionPactAction::[23]（func_names RTTI 名） |
| 0x14112DE40 | CImproveRelationAction::[23] vtable 槽 CImproveRelationAction::[23]（func_names RTTI 名） |
| 0x1422FC250 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1409DF3F0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1424FBDF0 | CChecksumFile::[6] vtable 槽 CChecksumFile::[6]（func_names RTTI 名） |
| 0x1401E3DC0 | （无名） 体设 SControlGroupData::vftable（RTTI 名） |
| 0x140535680 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x141548610 | CAdjacencyRule::[8] vtable 槽 CAdjacencyRule::[8]（func_names RTTI 名） |
| 0x1406CB420 | （无名） 体设 CNuke::vftable（RTTI 名） |
| 0x1413DF8C0 | （无名） 体设 SAdvisorBonus::vftable（RTTI 名） |
| 0x14065F920 | （无名） 体设 SForceConcentrationTargetInfo::vftable（RTTI 名） |
| 0x141EBEA50 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140535550 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x1413B1100 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1424BB360 | （无名） 体设 CLexer::vftable（RTTI 名） |
| 0x1415097F0 | （无名） 体设 CReinforcementStatus::vftable（RTTI 名） |
| 0x140DF8280 | （无名） 体设 CSeasonType::vftable（RTTI 名） |
| 0x1422AE390 | （无名） 体设 CGraphicalObject::vftable（RTTI 名） |
| 0x1414FB7D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14163CCA0 | （无名） 体设 CSetGamePlayOptions::vftable（RTTI 名） |
| 0x141453E80 | （无名） 体设 CConferenceBeneficiaryWithStackableParticipant::vftable（RTTI 名） |
| 0x1401C1260 | （无名） 体设 SPlaythroughCountryData::vftable（RTTI 名） |
| 0x141973D90 | （无名） 体设 SReceivedDamageData::vftable（RTTI 名） |
| 0x140674220 | CCurrentAutonomyStatus::[0] vtable 槽 CCurrentAutonomyStatus::[0]（func_names RTTI 名） |
| 0x140220700 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140AD6FB0 | （无名） 体设 CBaseTimedActivity::vftable（RTTI 名） |
| 0x1414FAAD0 | CCountryReportsManager::[0] vtable 槽 CCountryReportsManager::[0]（func_names RTTI 名） |
| 0x1419391F0 | CNavalProductionLine::[16] vtable 槽 CNavalProductionLine::[16]（func_names RTTI 名） |
| 0x14237F960 | （无名） 体设 StackWalker::vftable（RTTI 名） |
| 0x141B6E8B0 | CSupplyNudger::[2] vtable 槽 CSupplyNudger::[2]（func_names RTTI 名） |
| 0x1422E82D0 | （无名） 体设 CWriteToChatBuffer::vftable（RTTI 名） |
| 0x1422AC9D0 | CStandardlistbox::[9] vtable 槽 CStandardlistbox::[9]（func_names RTTI 名） |
| 0x1423E2F70 | CSteamMatchmakingContext::[24] vtable 槽 CSteamMatchmakingContext::[24]（func_names RTTI 名） |
| 0x1417CA7A0 | （无名） 体设 CMapMode::vftable（RTTI 名） |
| 0x141B3F070 | CAmbientObjectNudger::[2] vtable 槽 CAmbientObjectNudger::[2]（func_names RTTI 名） |
| 0x141B74800 | CUnitsNudger::[2] vtable 槽 CUnitsNudger::[2]（func_names RTTI 名） |
| 0x1423067B0 | CButtonDrag::[6] vtable 槽 CButtonDrag::[6]（func_names RTTI 名） |
| 0x14237F1C0 | CTrack::[6] vtable 槽 CTrack::[6]（func_names RTTI 名） |
| 0x140C98040 | （无名） 体设 SModifierStat::vftable（RTTI 名） |
| 0x140C0D230 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140A41BA0 | CIdeaDatabase::[2] vtable 槽 CIdeaDatabase::[2]（func_names RTTI 名） |
| 0x140535710 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x140CD7DD0 | （无名） 体设 CActivityInGroup::vftable（RTTI 名） |
| 0x141C8AF20 | （无名） 体设 CDiplomacyRequestExpeditionaryForcesController::vftable（RTTI 名） |
| 0x1422E54E0 | （无名） 体设 CChatMessage::vftable（RTTI 名） |
| 0x1423E29D0 | CSteamMatchmakingContext::[16] vtable 槽 CSteamMatchmakingContext::[16]（func_names RTTI 名） |
| 0x141600410 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140D40D40 | （无名） 体设 SLeadsToWarReader::vftable（RTTI 名） |
| 0x1422D49C0 | CInstantSprite::[9] vtable 槽 CInstantSprite::[9]（func_names RTTI 名） |
| 0x1422AE420 | CGraphicalObject::[9] vtable 槽 CGraphicalObject::[9]（func_names RTTI 名） |
| 0x140CD7EB0 | （无名） 体设 CLoss::vftable（RTTI 名） |
| 0x14235E750 | SGfxShaderPassReader::[4] vtable 槽 SGfxShaderPassReader::[4]（func_names RTTI 名） |
| 0x141BB7450 | （无名） 体设 CDarkFullscreenOverlayUpdateable::vftable（RTTI 名） |
| 0x1424BB3E0 | CLexer::[0] vtable 槽 CLexer::[0]（func_names RTTI 名） |
| 0x141333430 | CChat::CChatItem::[0] vtable 槽 CChat::CChatItem::[0]（func_names RTTI 名） |
| 0x140EFB5E0 | （无名） 体设 SPerCountrySection::vftable（RTTI 名） |
| 0x14136E210 | （无名） 体设 CTestLoggersArray::vftable（RTTI 名） |
| 0x141A38280 | （无名） 体设 SProjectHistory::vftable（RTTI 名） |
| 0x140704040 | （无名） 体设 CNuclearStrike::vftable（RTTI 名） |
| 0x1423E4850 | CSteamMatchmakingContext::[31] vtable 槽 CSteamMatchmakingContext::[31]（func_names RTTI 名） |
| 0x14112DC60 | CGenerateWarGoalAction::[23] vtable 槽 CGenerateWarGoalAction::[23]（func_names RTTI 名） |
| 0x141A9BAF0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141516750 | CLoopHistory::[0] vtable 槽 CLoopHistory::[0]（func_names RTTI 名） |
| 0x1418BC7F0 | CDecisionMapIconContainer::[4] vtable 槽 CDecisionMapIconContainer::[4]（func_names RTTI 名） |
| 0x142241160 | CSpriteType::[16] vtable 槽 CSpriteType::[16]（func_names RTTI 名） |
| 0x1413CCF20 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x140D40CD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140C04C00 | CUnit::[53] vtable 槽 CUnit::[53]（func_names RTTI 名） |
| 0x140147A40 | （无名） 体设 CFactionRuleGroup::vftable（RTTI 名） |
| 0x1403C8380 | （无名） 体设 SSupportCategoryStatMultiplier::vftable（RTTI 名） |
| 0x14229B430 | CBitmapFont::[34] vtable 槽 CBitmapFont::[34]（func_names RTTI 名） |
| 0x1418409A0 | （无名） 体设 COrderReplaceRootCommands::vftable（RTTI 名） |
| 0x141640150 | CMapIconLayer::[0] vtable 槽 CMapIconLayer::[0]（func_names RTTI 名） |
| 0x141DF3B60 | CMapModeMilitaryDeploymentToOrder::[8] vtable 槽 CMapModeMilitaryDeploymentToOrder::[8]（func_names RTTI 名） |
| 0x14224BFF0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1409CF880 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141A9BC20 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422CD750 | （无名） 体设 CRemoteFile::vftable（RTTI 名） |
| 0x14112E460 | CSendAttacheAction::[23] vtable 槽 CSendAttacheAction::[23]（func_names RTTI 名） |
| 0x140DB6D60 | （无名） 体设 SHistoryWithEquipment::vftable（RTTI 名） |
| 0x14112DD90 | CGuaranteeAction::[23] vtable 槽 CGuaranteeAction::[23]（func_names RTTI 名） |
| 0x141870FE0 | CPlayerLobby::[11] vtable 槽 CPlayerLobby::[11]（func_names RTTI 名） |
| 0x1422DF680 | PdxStackWalker::[3] vtable 槽 PdxStackWalker::[3]（func_names RTTI 名） |
| 0x1401D2BE0 | （无名） 体设 CScriptFlag::vftable（RTTI 名） |
| 0x14153FC20 | CCountryDecisionChange::[0] vtable 槽 CCountryDecisionChange::[0]（func_names RTTI 名） |
| 0x14014B0A0 | （无名） 体设 CSpecificEquipmentBonus::vftable（RTTI 名） |
| 0x140A54FE0 | （无名） 体设 CInsigniaTypeGraphics::vftable（RTTI 名） |
| 0x140DB27A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14159DE40 | CScriptedWindowTemplate::SPropertyInfo::[0] vtable 槽 CScriptedWindowTemplate::SPropertyInfo::[0]（func_names RTTI 名） |
| 0x141DF8EC0 | （无名） 体设 CStandardMusicPlaylistController::vftable（RTTI 名） |
| 0x140F80D70 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x142089C10 | CTweakableIntManipulator::[0] vtable 槽 CTweakableIntManipulator::[0]（func_names RTTI 名） |
| 0x1409B8C80 | CDifficultySetting::[8] vtable 槽 CDifficultySetting::[8]（func_names RTTI 名） |
| 0x140AD77D0 | CTimedActivityDatabase::[1] vtable 槽 CTimedActivityDatabase::[1]（func_names RTTI 名） |
| 0x140F80B70 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x1424FBD90 | CChecksumFile::[8] vtable 槽 CChecksumFile::[8]（func_names RTTI 名） |
| 0x1412E8820 | （无名） 体设 CDiplomaticAction::vftable（RTTI 名） |
| 0x142300680 | CSmoothListbox::[78] vtable 槽 CSmoothListbox::[78]（func_names RTTI 名） |
| 0x140C0D060 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x141C2E720 | （无名） 体设 CImportDesignPopUp::vftable（RTTI 名） |
| 0x14225D640 | CGui::[4] vtable 槽 CGui::[4]（func_names RTTI 名） |
| 0x1401C97D0 | CTechnologySharing::[0] vtable 槽 CTechnologySharing::[0]（func_names RTTI 名） |
| 0x140222C70 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1403CB720 | CCheckVariable::[0] vtable 槽 CCheckVariable::[0]（func_names RTTI 名） |
| 0x141C8CA40 | CDiplomacyStandardController::[1] vtable 槽 CDiplomacyStandardController::[1]（func_names RTTI 名） |
| 0x14121AFC0 | CNavalBaseConvoyClient::[0] vtable 槽 CNavalBaseConvoyClient::[0]（func_names RTTI 名） |
| 0x1416467F0 | CAmbientObject::[0] vtable 槽 CAmbientObject::[0]（func_names RTTI 名） |
| 0x141C8C840 | CDiplomacySendVolunteersController::[1] vtable 槽 CDiplomacySendVolunteersController::[1]（func_names RTTI 名） |
| 0x1422D7350 | （无名） 体设 CPdx3DObject::vftable（RTTI 名） |
| 0x1422D7520 | CPdx3DObject::[2] vtable 槽 CPdx3DObject::[2]（func_names RTTI 名） |
| 0x1402202D0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1406CB630 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140D334A0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140FF2DD0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14227C8A0 | CPdxMeshObject::[20] vtable 槽 CPdxMeshObject::[20]（func_names RTTI 名） |
| 0x142360520 | （无名） 体设 CResizeableSpriteType::vftable（RTTI 名） |
| 0x140535AC0 | CEventScope::[0] vtable 槽 CEventScope::[0]（func_names RTTI 名） |
| 0x141A38170 | （无名） 体设 SProjectHistory::vftable（RTTI 名） |
| 0x140A6F120 | CAiFleetTemplateDatabase::[2] vtable 槽 CAiFleetTemplateDatabase::[2]（func_names RTTI 名） |
| 0x140A6F190 | CAiTaskforceTemplateDatabase::[2] vtable 槽 CAiTaskforceTemplateDatabase::[2]（func_names RTTI 名） |
| 0x1424FB630 | （无名） 体设 CPdxLinearAllocator::vftable（RTTI 名） |
| 0x140F6F6A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422D1DB0 | CButtonStandard::[75] vtable 槽 CButtonStandard::[75]（func_names RTTI 名） |
| 0x140AAE1F0 | CScriptedMapModeDatabase::[1] vtable 槽 CScriptedMapModeDatabase::[1]（func_names RTTI 名） |
| 0x141BCDFD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141F6B7E0 | CMapModeMilitaryDeployment::[1] vtable 槽 CMapModeMilitaryDeployment::[1]（func_names RTTI 名） |
| 0x141840920 | （无名） 体设 COrderReplaceFallbackCommands::vftable（RTTI 名） |
| 0x141A0ECA0 | CWeatherChancePeriod::[7] vtable 槽 CWeatherChancePeriod::[7]（func_names RTTI 名） |
| 0x140C4AE00 | CCountryAirContainer::[0] vtable 槽 CCountryAirContainer::[0]（func_names RTTI 名） |
| 0x1418EAB60 | （无名） 体设 CRaidMapIconVariant::vftable（RTTI 名） |
| 0x140D83880 | CTechnologySharing::[16] vtable 槽 CTechnologySharing::[16]（func_names RTTI 名） |
| 0x141446450 | （无名） 体设 CUnitHistory::vftable（RTTI 名） |
| 0x1415168B0 | CLoopHistoryContainerQueue::[0] vtable 槽 CLoopHistoryContainerQueue::[0]（func_names RTTI 名） |
| 0x1419796E0 | CFEXAir::[8] vtable 槽 CFEXAir::[8]（func_names RTTI 名） |
| 0x14232C850 | SCurveAnimationReader::[7] vtable 槽 SCurveAnimationReader::[7]（func_names RTTI 名） |
| 0x1412AE860 | CLandCombat::[7] vtable 槽 CLandCombat::[7]（func_names RTTI 名） |
| 0x140E38060 | CPeaceBiddingTurn::[0] vtable 槽 CPeaceBiddingTurn::[0]（func_names RTTI 名） |
| 0x1413F4660 | CCountryCollaborationStatus::[0] vtable 槽 CCountryCollaborationStatus::[0]（func_names RTTI 名） |
| 0x14234D0C0 | SEntityAttachmentGroupReader::[0] vtable 槽 SEntityAttachmentGroupReader::[0]（func_names RTTI 名） |
| 0x140AB9390 | CScriptedWindowTemplate::SAIEffectInfo::[0] vtable 槽 CScriptedWindowTemplate::SAIEffectInfo::[0]（func_names RTTI 名） |
| 0x141337800 | CChat::[15] vtable 槽 CChat::[15]（func_names RTTI 名） |
| 0x14163C1C0 | CSetCustomDifficultyMultiplier::[0] vtable 槽 CSetCustomDifficultyMultiplier::[0]（func_names RTTI 名） |
| 0x1422D1380 | CButtonStandard::[14] vtable 槽 CButtonStandard::[14]（func_names RTTI 名） |
| 0x1422D1BD0 | CButtonStandard::[110] vtable 槽 CButtonStandard::[110]（func_names RTTI 名） |
| 0x1423573B0 | C2dCircularProgressBarType::[23] vtable 槽 C2dCircularProgressBarType::[23]（func_names RTTI 名） |
| 0x1422A2A30 | CBitmapFont::[28] vtable 槽 CBitmapFont::[28]（func_names RTTI 名） |
| 0x1423007C0 | CSmoothListbox::[14] vtable 槽 CSmoothListbox::[14]（func_names RTTI 名） |
| 0x142400A70 | PdxSocialPermissions::[0] vtable 槽 PdxSocialPermissions::[0]（func_names RTTI 名） |
| 0x140CF2D90 | COwnerArea::[7] vtable 槽 COwnerArea::[7]（func_names RTTI 名） |
| 0x140DDCA20 | CInGameIdler::[33] vtable 槽 CInGameIdler::[33]（func_names RTTI 名） |
| 0x14187AB70 | （无名） 体设 CAirViewDetails::vftable（RTTI 名） |
| 0x141B32690 | （无名） 体设 CSetRaidAutoLaunchOption::vftable（RTTI 名） |
| 0x141C8BE50 | CDiplomacyBoostPartyPopularityController::[1] vtable 槽 CDiplomacyBoostPartyPopularityController::[1]（func_names RTTI 名） |
| 0x140CE1FB0 | CNavalCombatResults::[0] vtable 槽 CNavalCombatResults::[0]（func_names RTTI 名） |
| 0x140DB2C60 | （无名） 体设 SHistoryWithEquipment::vftable（RTTI 名） |
| 0x140A31980 | （无名） 体设 CFriend::vftable（RTTI 名） |
| 0x1403074D0 | CEmbargoAction::[53] vtable 槽 CEmbargoAction::[53]（func_names RTTI 名） |
| 0x1406943B0 | （无名） 体设 SCareerProfileModDataSet::vftable（RTTI 名） |
| 0x14232BA50 | CCurveGraph::[77] vtable 槽 CCurveGraph::[77]（func_names RTTI 名） |
| 0x1422CBD30 | （无名） 体设 CDebugLineHelper::vftable（RTTI 名） |
| 0x1423013C0 | CSmoothListbox::[29] vtable 槽 CSmoothListbox::[29]（func_names RTTI 名） |
| 0x141149180 | CAddProductionLineName::[0] vtable 槽 CAddProductionLineName::[0]（func_names RTTI 名） |
| 0x14237F2C0 | CTrack::[85] vtable 槽 CTrack::[85]（func_names RTTI 名） |
| 0x1422D59D0 | CTextSprite::[87] vtable 槽 CTextSprite::[87]（func_names RTTI 名） |
| 0x140AAC530 | （无名） 体设 STriggerKeyPair::vftable（RTTI 名） |
| 0x140DB44A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1410C6180 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14061FAB0 | CAchievementMod::[10] vtable 槽 CAchievementMod::[10]（func_names RTTI 名） |
| 0x140C1E5A0 | CArmyLeader::[32] vtable 槽 CArmyLeader::[32]（func_names RTTI 名） |
| 0x1410FC470 | （无名） 体设 CSendExpeditionaryForceAction::vftable（RTTI 名） |
| 0x141681B50 | （无名） 体设 CStateGraphics::vftable（RTTI 名） |
| 0x1424FB9B0 | CChecksumFile::[1] vtable 槽 CChecksumFile::[1]（func_names RTTI 名） |
| 0x1424FBBF0 | CChecksumFile::[4] vtable 槽 CChecksumFile::[4]（func_names RTTI 名） |
| 0x1424FBC60 | CChecksumFile::[2] vtable 槽 CChecksumFile::[2]（func_names RTTI 名） |
| 0x1424FBCD0 | CChecksumFile::[5] vtable 槽 CChecksumFile::[5]（func_names RTTI 名） |
| 0x1401D7B30 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140DE6720 | CSetGameUniqueId::[0] vtable 槽 CSetGameUniqueId::[0]（func_names RTTI 名） |
| 0x141B7D5D0 | （无名） 体设 CScrollbarObserver::vftable（RTTI 名） |
| 0x142089810 | CTweakableBoolManipulator::[0] vtable 槽 CTweakableBoolManipulator::[0]（func_names RTTI 名） |
| 0x140617EA0 | CAceModifier::[0] vtable 槽 CAceModifier::[0]（func_names RTTI 名） |
| 0x140CA5010 | （无名） 体设 CResourceDeliveryRoute::vftable（RTTI 名） |
| 0x140ACAC70 | （无名） 体设 CTechnologyPath::vftable（RTTI 名） |
| 0x140EE5820 | CTechnologySharingGroup::[9] vtable 槽 CTechnologySharingGroup::[9]（func_names RTTI 名） |
| 0x14153FD60 | COOBChange::[0] vtable 槽 COOBChange::[0]（func_names RTTI 名） |
| 0x141DEFDE0 | （无名） 体设 CScrollbarObserver::vftable（RTTI 名） |
| 0x1422ECB70 | CInstantTextObject::[9] vtable 槽 CInstantTextObject::[9]（func_names RTTI 名） |
| 0x140C1E710 | CArmyLeader::[33] vtable 槽 CArmyLeader::[33]（func_names RTTI 名） |
| 0x140D0D440 | （无名） 体设 CSubunitBonusPersistent::vftable（RTTI 名） |
| 0x1410FC170 | （无名） 体设 CAskForStateControlAction::vftable（RTTI 名） |
| 0x142402AB0 | CStoreContext::[4] vtable 槽 CStoreContext::[4]（func_names RTTI 名） |
| 0x14208CFE0 | CTweakableBoolManipulator::[13] vtable 槽 CTweakableBoolManipulator::[13]（func_names RTTI 名） |
| 0x1422775A0 | CPdxMeshObject::[19] vtable 槽 CPdxMeshObject::[19]（func_names RTTI 名） |
| 0x140F714C0 | CRocketProductionLine::[8] vtable 槽 CRocketProductionLine::[8]（func_names RTTI 名） |
| 0x1410FC290 | （无名） 体设 CGenerateWarGoalAction::vftable（RTTI 名） |
| 0x141509770 | （无名） 体设 CReinforcementRequest::vftable（RTTI 名） |
| 0x1422E5880 | CCountryChatMessage::[10] vtable 槽 CCountryChatMessage::[10]（func_names RTTI 名） |
| 0x1423DC9E0 | CSteamCloudStorageContext::[8] vtable 槽 CSteamCloudStorageContext::[8]（func_names RTTI 名） |
| 0x1424D0020 | CThreadProfileObject::[0] vtable 槽 CThreadProfileObject::[0]（func_names RTTI 名） |
| 0x1415096C0 | （无名） 体设 CGarrisonStatus::vftable（RTTI 名） |
| 0x141B06E10 | CEvolveShipImgui::[7] vtable 槽 CEvolveShipImgui::[7]（func_names RTTI 名） |
| 0x1420B1640 | CTurnTableStrategy::[4] vtable 槽 CTurnTableStrategy::[4]（func_names RTTI 名） |
| 0x142320380 | CLineChartType::[0] vtable 槽 CLineChartType::[0]（func_names RTTI 名） |
| 0x140C11470 | CArmyLeader::[30] vtable 槽 CArmyLeader::[30]（func_names RTTI 名） |
| 0x141C2F650 | CDeleteDesignPopUp::[0] vtable 槽 CDeleteDesignPopUp::[0]（func_names RTTI 名） |
| 0x1423C3430 | CSteamBrowserInstance::[2] vtable 槽 CSteamBrowserInstance::[2]（func_names RTTI 名） |
| 0x1410F0DF0 | CCountryFuelStatus::[0] vtable 槽 CCountryFuelStatus::[0]（func_names RTTI 名） |
| 0x141540F30 | CHistoryAddEffectCountry::[1] vtable 槽 CHistoryAddEffectCountry::[1]（func_names RTTI 名） |
| 0x1424F1010 | （无名） 体设 CFile::vftable（RTTI 名） |
| 0x140CDD4D0 | （无名） 体设 SModifierHours::vftable（RTTI 名） |
| 0x1413FA0A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1417AD080 | （无名） 体设 CStandardInterface::vftable（RTTI 名） |
| 0x141B32620 | （无名） 体设 CSetRaidAutoComplete::vftable（RTTI 名） |
| 0x1422AC110 | CStandardlistbox::[33] vtable 槽 CStandardlistbox::[33]（func_names RTTI 名） |
| 0x142300AA0 | CSmoothListbox::[33] vtable 槽 CSmoothListbox::[33]（func_names RTTI 名） |
| 0x141509F70 | CUpgradeDelivery::[0] vtable 槽 CUpgradeDelivery::[0]（func_names RTTI 名） |
| 0x141F5B6C0 | CHostConfigurationPupup::[0] vtable 槽 CHostConfigurationPupup::[0]（func_names RTTI 名） |
| 0x1410FC1E0 | （无名） 体设 CCallAllyAction::vftable（RTTI 名） |
| 0x1410FC370 | （无名） 体设 CJoinAllyAction::vftable（RTTI 名） |
| 0x141427CE0 | CUnitLeaderTemplate::[0] vtable 槽 CUnitLeaderTemplate::[0]（func_names RTTI 名） |
| 0x141509DD0 | CGarrisonReinforcementRequests::[0] vtable 槽 CGarrisonReinforcementRequests::[0]（func_names RTTI 名） |
| 0x1422544D0 | HotkeyManager::[0] vtable 槽 HotkeyManager::[0]（func_names RTTI 名） |
| 0x1423E93A0 | CSteamNetContext::[1] vtable 槽 CSteamNetContext::[1]（func_names RTTI 名） |
| 0x1424B8D00 | （无名） 体设 CTweakable::vftable（RTTI 名） |
| 0x141268960 | CMapArrowDefinition::[7] vtable 槽 CMapArrowDefinition::[7]（func_names RTTI 名） |
| 0x140303130 | CEquipmentVariantPool::[0] vtable 槽 CEquipmentVariantPool::[0]（func_names RTTI 名） |
| 0x140C67D30 | CArmyManpower::[0] vtable 槽 CArmyManpower::[0]（func_names RTTI 名） |
| 0x140D02550 | CDynamicIntelSourcePool::[0] vtable 槽 CDynamicIntelSourcePool::[0]（func_names RTTI 名） |
| 0x141234250 | CUnitMoveAction::[0] vtable 槽 CUnitMoveAction::[0]（func_names RTTI 名） |
| 0x140ACE040 | （无名） 体设 CFolderPosition::vftable（RTTI 名） |
| 0x141B045B0 | CEvolveEquipmentImgui::[0] vtable 槽 CEvolveEquipmentImgui::[0]（func_names RTTI 名） |
| 0x141CADBD0 | CRelationStripViewBase::CStripFlagItem::[8] vtable 槽 CRelationStripViewBase::CStripFlagItem::[8]（func_names RTTI 名） |
| 0x1410FBC90 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1410FC7D0 | CAskForStateControlAction::[0] vtable 槽 CAskForStateControlAction::[0]（func_names RTTI 名） |
| 0x140C4FF20 | （无名） 体设 CAirRegionCombatData::vftable（RTTI 名） |
| 0x140CABDE0 | CResourceOrigin::[10] vtable 槽 CResourceOrigin::[10]（func_names RTTI 名） |
| 0x1410FC9D0 | CGiveStateControlAction::[0] vtable 槽 CGiveStateControlAction::[0]（func_names RTTI 名） |
| 0x1410FC940 | CGenerateWarGoalAction::[0] vtable 槽 CGenerateWarGoalAction::[0]（func_names RTTI 名） |
| 0x1424FB680 | CPdxLinearAllocator::[0] vtable 槽 CPdxLinearAllocator::[0]（func_names RTTI 名） |
| 0x1420899D0 | CTweakableCharArrayManipulator::[0] vtable 槽 CTweakableCharArrayManipulator::[0]（func_names RTTI 名） |
| 0x14237E380 | CPdxDummy3DObject::[10] vtable 槽 CPdxDummy3DObject::[10]（func_names RTTI 名） |
| 0x140D40DD0 | （无名） 体设 SRedistribution::vftable（RTTI 名） |
| 0x142011E00 | （无名） 体设 SOrderInstanceRef::vftable（RTTI 名） |
| 0x1406ABBD0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140A8C5D0 | CPowerBalanceDatabase::[1] vtable 槽 CPowerBalanceDatabase::[1]（func_names RTTI 名） |
| 0x1413E2C80 | CCombatant::[21] vtable 槽 CCombatant::[21]（func_names RTTI 名） |
| 0x141642920 | （无名） 体设 CShieldObject::vftable（RTTI 名） |
| 0x140E9C750 | （无名） 体设 SRegionalConvoyData::vftable（RTTI 名） |
| 0x1402CB3C0 | （无名） 体设 CFocusInlayWindowInstance::vftable（RTTI 名） |
| 0x1409DB410 | （无名） 体设 STemporaryResourceData::vftable（RTTI 名） |
| 0x14112E300 | CRequestLicensedProductionAction::[23] vtable 槽 CRequestLicensedProductionAction::[23]（func_names RTTI 名） |
| 0x141FA6250 | （无名） 体设 SCareerProfileMedalData::vftable（RTTI 名） |
| 0x140F03400 | CThreatSource::[0] vtable 槽 CThreatSource::[0]（func_names RTTI 名） |
| 0x1423C3180 | CSteamBrowserInstance::[3] vtable 槽 CSteamBrowserInstance::[3]（func_names RTTI 名） |
| 0x1423C33D0 | CSteamBrowserInstance::[19] vtable 槽 CSteamBrowserInstance::[19]（func_names RTTI 名） |
| 0x140FCDDD0 | CIdeaResearchBonus::[0] vtable 槽 CIdeaResearchBonus::[0]（func_names RTTI 名） |
| 0x14029ECF0 | CGameIdler::[30] vtable 槽 CGameIdler::[30]（func_names RTTI 名） |
| 0x1422AA550 | CStandardlistbox::[21] vtable 槽 CStandardlistbox::[21]（func_names RTTI 名） |
| 0x1422FFF10 | CSmoothListbox::[21] vtable 槽 CSmoothListbox::[21]（func_names RTTI 名） |
| 0x141401380 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1420B15E0 | CFirstPersonStrategy::[4] vtable 槽 CFirstPersonStrategy::[4]（func_names RTTI 名） |
| 0x140F032A0 | （无名） 体设 CThreatSource::vftable（RTTI 名） |
| 0x140A7B240 | COperationPhase::[8] vtable 槽 COperationPhase::[8]（func_names RTTI 名） |
| 0x141F751A0 | （无名） 体设 CConfirmRemoveBuildingLevel::vftable（RTTI 名） |
| 0x140194EF0 | （无名） 体设 CMilestoneTemplate::vftable（RTTI 名） |
| 0x140D7FAC0 | （无名） 体设 SMasteryFromUnitLeader::vftable（RTTI 名） |
| 0x1414B5840 | CProductionLine::[16] vtable 槽 CProductionLine::[16]（func_names RTTI 名） |
| 0x1409F0480 | （无名） 体设 CEquipmentFilter::vftable（RTTI 名） |
| 0x1422335D0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422E0490 | CStartFileTransfer::[0] vtable 槽 CStartFileTransfer::[0]（func_names RTTI 名） |
| 0x14163CBD0 | （无名） 体设 CSetCustomDifficultyMultiplier::vftable（RTTI 名） |
| 0x1416411B0 | CBitmapFont::[29] vtable 槽 CBitmapFont::[29]（func_names RTTI 名） |
| 0x14193EA80 | CHqDeploymentDistributable::[2] vtable 槽 CHqDeploymentDistributable::[2]（func_names RTTI 名） |
| 0x141E80790 | CIntelMapModeMapIconMore::[0] vtable 槽 CIntelMapModeMapIconMore::[0]（func_names RTTI 名） |
| 0x14229FF50 | CBitmapFont::[27] vtable 槽 CBitmapFont::[27]（func_names RTTI 名） |
| 0x1422E0C10 | （无名） 体设 CSendChunk::vftable（RTTI 名） |
| 0x140673E50 | （无名） 体设 CCurrentAutonomyStatus::vftable（RTTI 名） |
| 0x140725A10 | CDecisionCategory::SOnMapLocator::[0] vtable 槽 CDecisionCategory::SOnMapLocator::[0]（func_names RTTI 名） |
| 0x140E8ECE0 | （无名） 体设 CAssignRailwayGunToOrdersGroup::vftable（RTTI 名） |
| 0x142385CB0 | CResizeableSprite::[23] vtable 槽 CResizeableSprite::[23]（func_names RTTI 名） |
| 0x140BBD400 | （无名） 体设 SIdCounter::vftable（RTTI 名） |
| 0x140D0D8A0 | CSubunitBonusPersistent::[0] vtable 槽 CSubunitBonusPersistent::[0]（func_names RTTI 名） |
| 0x14134F030 | （无名） 体设 CRestructureShipsToTaskforceCompositions::vftable（RTTI 名） |
| 0x1424EE150 | CMemoryFile::[0] vtable 槽 CMemoryFile::[0]（func_names RTTI 名） |
| 0x1414FCDE0 | CIncomingLendLeaseAction::[24] vtable 槽 CIncomingLendLeaseAction::[24]（func_names RTTI 名） |
| 0x1414019C0 | COperationInstance::[1] vtable 槽 COperationInstance::[1]（func_names RTTI 名） |
| 0x14237E500 | CFont::[0] vtable 槽 CFont::[0]（func_names RTTI 名） |
| 0x1424F1110 | CFile::[0] vtable 槽 CFile::[0]（func_names RTTI 名） |
| 0x140A8B630 | （无名） 体设 CPowerBalanceRange::vftable（RTTI 名） |
| 0x140AD0E10 | CTechnologyTemplate::[8] vtable 槽 CTechnologyTemplate::[8]（func_names RTTI 名） |
| 0x142089DC0 | CTweakableTitle::[0] vtable 槽 CTweakableTitle::[0]（func_names RTTI 名） |
| 0x14229FEF0 | CBitmapFont::[26] vtable 槽 CBitmapFont::[26]（func_names RTTI 名） |
| 0x1422E5710 | CCountryChatMessage::[0] vtable 槽 CCountryChatMessage::[0]（func_names RTTI 名） |
| 0x14232B6C0 | CCurveGraphType::[0] vtable 槽 CCurveGraphType::[0]（func_names RTTI 名） |
| 0x14236DEA0 | CBrowserType::[0] vtable 槽 CBrowserType::[0]（func_names RTTI 名） |
| 0x1403CB880 | CCanFireAdvisor::[0] vtable 槽 CCanFireAdvisor::[0]（func_names RTTI 名） |
| 0x140A55310 | SInsigniaIconInfo::[0] vtable 槽 SInsigniaIconInfo::[0]（func_names RTTI 名） |
| 0x140E8EE20 | （无名） 体设 CUnassignRailwayGunFromOrdersGroup::vftable（RTTI 名） |
| 0x140F1F360 | （无名） 体设 CWeatherTerrainModifier::vftable（RTTI 名） |
| 0x1419C8830 | CTutAnnex::[0] vtable 槽 CTutAnnex::[0]（func_names RTTI 名） |
| 0x1414614E0 | SOptionalEquipmentAssets::[0] vtable 槽 SOptionalEquipmentAssets::[0]（func_names RTTI 名） |
| 0x1419155D0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x142398F30 | CSteamAchievementsContext::[2] vtable 槽 CSteamAchievementsContext::[2]（func_names RTTI 名） |
| 0x1423E1170 | CSteamMatchmakingContext::[41] vtable 槽 CSteamMatchmakingContext::[41]（func_names RTTI 名） |
| 0x140694430 | （无名） 体设 SProfileData::vftable（RTTI 名） |
| 0x14114E530 | （无名） 体设 CAddProductionLineName::vftable（RTTI 名） |
| 0x1423AAA20 | （无名） 体设 PdxTextToSpeechWinSAPI::vftable（RTTI 名） |
| 0x1401D2B90 | （无名） 体设 SControlGroupData::vftable（RTTI 名） |
| 0x1407040D0 | （无名） 体设 CTask::vftable（RTTI 名） |
| 0x142361510 | C2dPieChartType::[23] vtable 槽 C2dPieChartType::[23]（func_names RTTI 名） |
| 0x141019480 | （无名） 体设 CSubUnitDefinitionAssociatedModifiers::vftable（RTTI 名） |
| 0x141A2E7E0 | CConfirmAssignUnitsToFront::[0] vtable 槽 CConfirmAssignUnitsToFront::[0]（func_names RTTI 名） |
| 0x141C2F300 | CImportDesignPopUp::[0] vtable 槽 CImportDesignPopUp::[0]（func_names RTTI 名） |
| 0x1423AB4F0 | PdxTextToSpeechWinSAPI::[3] vtable 槽 PdxTextToSpeechWinSAPI::[3]（func_names RTTI 名） |
| 0x1423DD670 | CSteamCloudStorageContext::[1] vtable 槽 CSteamCloudStorageContext::[1]（func_names RTTI 名） |
| 0x141454240 | CConferenceBeneficiaryParticipant::[1] vtable 槽 CConferenceBeneficiaryParticipant::[1]（func_names RTTI 名） |
| 0x1414B4B20 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x141DF8F30 | CStandardMusicPlaylistController::[1] vtable 槽 CStandardMusicPlaylistController::[1]（func_names RTTI 名） |
| 0x142276E80 | CPdxMeshObject::[18] vtable 槽 CPdxMeshObject::[18]（func_names RTTI 名） |
| 0x1422ACCC0 | CStandardlistbox::[45] vtable 槽 CStandardlistbox::[45]（func_names RTTI 名） |
| 0x142301140 | CSmoothListbox::[45] vtable 槽 CSmoothListbox::[45]（func_names RTTI 名） |
| 0x142356300 | （无名） 体设 CAnimatedMapTextType::vftable（RTTI 名） |
| 0x1422D58F0 | CTextSprite::[44] vtable 槽 CTextSprite::[44]（func_names RTTI 名） |
| 0x14201B020 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x14134F6C0 | （无名） 体设 CSwitchNavalRepairDockyard::vftable（RTTI 名） |
| 0x1423C31E0 | CSteamBrowserInstance::[5] vtable 槽 CSteamBrowserInstance::[5]（func_names RTTI 名） |
| 0x140A27DB0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140CE7390 | CMilitaryDeploymentLine::[0] vtable 槽 CMilitaryDeploymentLine::[0]（func_names RTTI 名） |
| 0x140DE72B0 | （无名） 体设 CPauseGame::vftable（RTTI 名） |
| 0x1410FC4E0 | （无名） 体设 CDiplomaticAction::vftable（RTTI 名） |
| 0x14134EF50 | （无名） 体设 CReorderNavalRepairQueue::vftable（RTTI 名） |
| 0x1414D4DB0 | CPendingStratNavyTransfer::[5] vtable 槽 CPendingStratNavyTransfer::[5]（func_names RTTI 名） |
| 0x1422CE9C0 | （无名） 体设 CBrowser::vftable（RTTI 名） |
| 0x1424BB240 | （无名） 体设 CLexer::vftable（RTTI 名） |
| 0x140723EE0 | （无名） 体设 CTargetedDecision::vftable（RTTI 名） |
| 0x14101FE20 | CSubUnitDefinition::[1] vtable 槽 CSubUnitDefinition::[1]（func_names RTTI 名） |
| 0x142089BA0 | CTweakableGraphManipulator::[0] vtable 槽 CTweakableGraphManipulator::[0]（func_names RTTI 名） |
| 0x141DF4220 | CMapModeMilitaryDeploymentToOrder::[6] vtable 槽 CMapModeMilitaryDeploymentToOrder::[6]（func_names RTTI 名） |
| 0x1422ED070 | CInstantTextObject::[42] vtable 槽 CInstantTextObject::[42]（func_names RTTI 名） |
| 0x141B1F2F0 | （无名） 体设 CMapSymbolDefinition::vftable（RTTI 名） |
| 0x141D0E1D0 | CConfirmUnassignUnits::[0] vtable 槽 CConfirmUnassignUnits::[0]（func_names RTTI 名） |
| 0x140E5BF20 | （无名） 体设 CNamedEquipmentBonus::vftable（RTTI 名） |
| 0x140F6F850 | CRailwayGunRepairLine::[0] vtable 槽 CRailwayGunRepairLine::[0]（func_names RTTI 名） |
| 0x140D18DC0 | CBoostPartyPopularityRelation::[0] vtable 槽 CBoostPartyPopularityRelation::[0]（func_names RTTI 名） |
| 0x141840270 | （无名） 体设 COrderDeleteChildFront::vftable（RTTI 名） |
| 0x1423A9A10 | （无名） 体设 PdxTextToSpeechState::vftable（RTTI 名） |
| 0x1424DF750 | （无名） 体设 CVirtualFile::vftable（RTTI 名） |
| 0x1424031C0 | CSteamUGCContext::[15] vtable 槽 CSteamUGCContext::[15]（func_names RTTI 名） |
| 0x141F60380 | （无名） 体设 CCloseViewOption::vftable（RTTI 名） |
| 0x140E9EFA0 | CStrategicNavyManager::[1] vtable 槽 CStrategicNavyManager::[1]（func_names RTTI 名） |
| 0x14031E770 | （无名） 体设 CTechnologyTemplateVariable::vftable（RTTI 名） |
| 0x140D02630 | CStaticIntelSourcePool::[0] vtable 槽 CStaticIntelSourcePool::[0]（func_names RTTI 名） |
| 0x140FC6950 | （无名） 体设 CTrackStatus::vftable（RTTI 名） |
| 0x1423570D0 | C2dCircularProgressBarType::[10] vtable 槽 C2dCircularProgressBarType::[10]（func_names RTTI 名） |
| 0x140F91780 | CResistance::SAddedResistanceTarget::[0] vtable 槽 CResistance::SAddedResistanceTarget::[0]（func_names RTTI 名） |
| 0x1414E7FD0 | （无名） 体设 CMessage::vftable（RTTI 名） |
| 0x142309C30 | SMeshVariant::[0] vtable 槽 SMeshVariant::[0]（func_names RTTI 名） |
| 0x1422FD950 | CSprite::[4] vtable 槽 CSprite::[4]（func_names RTTI 名） |
| 0x140D8ACD0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141143600 | （无名） 体设 CAddProductionLineName::vftable（RTTI 名） |
| 0x14131AAF0 | （无名） 体设 CSetFactionPingExecutionType::vftable（RTTI 名） |
| 0x1415C0C30 | （无名） 体设 CNavyLeaderModule::vftable（RTTI 名） |
| 0x14232B9F0 | CCurveGraph::[78] vtable 槽 CCurveGraph::[78]（func_names RTTI 名） |
| 0x1410FCB70 | CSendVolunteerAction::[0] vtable 槽 CSendVolunteerAction::[0]（func_names RTTI 名） |
| 0x1423C3370 | CSteamBrowserInstance::[7] vtable 槽 CSteamBrowserInstance::[7]（func_names RTTI 名） |
| 0x1422D0AB0 | CButtonStandard::[111] vtable 槽 CButtonStandard::[111]（func_names RTTI 名） |
| 0x140A4FEB0 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x14134E470 | （无名） 体设 CAddToOrRemoveShipFromNavalRepairQueue::vftable（RTTI 名） |
| 0x1422770C0 | CPdxMeshObject::[15] vtable 槽 CPdxMeshObject::[15]（func_names RTTI 名） |
| 0x140CD82B0 | （无名） 体设 SCombatData::vftable（RTTI 名） |
| 0x140ED2C20 | （无名） 体设 CLimitedUseTechBonus::vftable（RTTI 名） |
| 0x1423E0620 | CSteamMatchmakingContext::[20] vtable 槽 CSteamMatchmakingContext::[20]（func_names RTTI 名） |
| 0x1425448EC | pcharNode::[3] vtable 槽 pcharNode::[3]（func_names RTTI 名） |
| 0x142360460 | CProgressbarSprite::[18] vtable 槽 CProgressbarSprite::[18]（func_names RTTI 名） |
| 0x141DF97B0 | （无名） 体设 CStandardMusicPlayerController::vftable（RTTI 名） |
| 0x140A889A0 | CCountryPortraits::[8] vtable 槽 CCountryPortraits::[8]（func_names RTTI 名） |
| 0x141509BE0 | （无名） 体设 CGarrisonReinforcementRequests::vftable（RTTI 名） |
| 0x1403C8620 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141BA8E50 | （无名） 体设 CSetFactionTheaterPinVisibility::vftable（RTTI 名） |
| 0x140149DD0 | （无名） 体设 COperationResources::vftable（RTTI 名） |
| 0x140ADA200 | CTimedActivityEquipmentDistributable::[4] vtable 槽 CTimedActivityEquipmentDistributable::[4]（func_names RTTI 名） |
| 0x1424DF980 | CArchiveFile::[1] vtable 槽 CArchiveFile::[1]（func_names RTTI 名） |
| 0x1401F72E0 | H::PEAVCCountry::IEAAXAEBV?$CPdxArray::CGameState::??DoCountryH鈥�::[1] func_names 名 H::PEAVCCountry::IEAAXAEBV?$CPdxArray::CGameState::??DoCountryH鈥�::[1] |
| 0x140C67000 | HH::QEAAXAEBV?$CPdxArray::CStrategicAirManager::??DailyUpdate::鈥�::[1] func_names 名 HH::QEAAXAEBV?$CPdxArray::CStrategicAirManager::??DailyUpdate::鈥�::[1] |
| 0x140F02C30 | H::VCCountryTag::YAXAEAV?$CPdxArray::NTheatreManager::AEBV3?2??鈥�::[1] func_names 名 H::VCCountryTag::YAXAEAV?$CPdxArray::NTheatreManager::AEBV3?2??鈥�::[1] |
| 0x141F62A80 | （无名） 体设 CSelectAllOption::vftable（RTTI 名） |
| 0x142293950 | （无名） 体设 CPdxParticleObject::vftable（RTTI 名） |
| 0x141695F70 | （无名） 体设 CTemplateChanger::vftable（RTTI 名） |
| 0x14183FB20 | （无名） 体设 CAssignAdmiralToNavyHeadquarter::vftable（RTTI 名） |
| 0x141E8D170 | CTinyUnitCounter::[0] vtable 槽 CTinyUnitCounter::[0]（func_names RTTI 名） |
| 0x1419D7C50 | CDebugMapModeConfig::CNormalizer::[0] vtable 槽 CDebugMapModeConfig::CNormalizer::[0]（func_names RTTI 名） |
| 0x141F61820 | （无名） 体设 CMergeGroupsOption::vftable（RTTI 名） |
| 0x14225BD20 | CGui::[11] vtable 槽 CGui::[11]（func_names RTTI 名） |
| 0x1422D1330 | CButtonStandard::[77] vtable 槽 CButtonStandard::[77]（func_names RTTI 名） |
| 0x140F6F630 | （无名） 体设 CRailwayGunProductionLine::vftable（RTTI 名） |
| 0x140F70B20 | CRailwayGunRepairLine::[8] vtable 槽 CRailwayGunRepairLine::[8]（func_names RTTI 名） |
| 0x1413652B0 | （无名） 体设 CSetArmyToConsolidateForUnit::vftable（RTTI 名） |
| 0x1420B0340 | （无名） 体设 CTurnTableStrategy::vftable（RTTI 名） |
| 0x140643410 | CSubUnitStatBonus::[1] vtable 槽 CSubUnitStatBonus::[1]（func_names RTTI 名） |
| 0x14223AD90 | （无名） 体设 CCollisionObject::vftable（RTTI 名） |
| 0x1412D4660 | CNudgeIdler::[55] vtable 槽 CNudgeIdler::[55]（func_names RTTI 名） |
| 0x141BA8930 | （无名） 体设 CClearFactionTheater::vftable（RTTI 名） |
| 0x1422AECB0 | CSprite::[57] vtable 槽 CSprite::[57]（func_names RTTI 名） |
| 0x1424FBD50 | CChecksumFile::[7] vtable 槽 CChecksumFile::[7]（func_names RTTI 名） |
| 0x1424EE490 | CRemoteFile::[4] vtable 槽 CRemoteFile::[4]（func_names RTTI 名） |
| 0x140223900 | HOI4EditorInterface::[0] vtable 槽 HOI4EditorInterface::[0]（func_names RTTI 名） |
| 0x140A21960 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141C8B330 | （无名） 体设 CDiplomacySendExpeditionaryForceController::vftable（RTTI 名） |
| 0x141FFA5B0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x1423488F0 | CPdxGameController::[0] vtable 槽 CPdxGameController::[0]（func_names RTTI 名） |
| 0x1423557B0 | （无名） 体设 CMouse::vftable（RTTI 名） |
| 0x140BB67B0 | （无名） 体设 CCombatHistory::vftable（RTTI 名） |
| 0x1411052B0 | CBoostPartyPopularityAction::[56] vtable 槽 CBoostPartyPopularityAction::[56]（func_names RTTI 名） |
| 0x14193EA00 | CHqDeploymentDistributable::[1] vtable 槽 CHqDeploymentDistributable::[1]（func_names RTTI 名） |
| 0x140A45ED0 | （无名） 体设 CIdeology::vftable（RTTI 名） |
| 0x1417AD000 | （无名） 体设 CStandardInterface::vftable（RTTI 名） |
| 0x14193E610 | （无名） 体设 CHqDeploymentDistributable::vftable（RTTI 名） |
| 0x140620250 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140BA1D20 | CReferencedDivisionTemplate::[7] vtable 槽 CReferencedDivisionTemplate::[7]（func_names RTTI 名） |
| 0x141BA7900 | （无名） 体设 CSetFactionTheaterPinVisibility::vftable（RTTI 名） |
| 0x141B1F8D0 | CMapSymbolDefinitionInstance::[0] vtable 槽 CMapSymbolDefinitionInstance::[0]（func_names RTTI 名） |
| 0x1422E8270 | （无名） 体设 CSendChatMessage::vftable（RTTI 名） |
| 0x1423E12E0 | CSteamMatchmakingContext::[9] vtable 槽 CSteamMatchmakingContext::[9]（func_names RTTI 名） |
| 0x141436F50 | CEquipmentProductionLicense::[0] vtable 槽 CEquipmentProductionLicense::[0]（func_names RTTI 名） |
| 0x142299070 | CBitmapFont::[33] vtable 槽 CBitmapFont::[33]（func_names RTTI 名） |
| 0x142402230 | CSteamStoreContext::[17] vtable 槽 CSteamStoreContext::[17]（func_names RTTI 名） |
| 0x142402280 | CSteamStoreContext::[16] vtable 槽 CSteamStoreContext::[16]（func_names RTTI 名） |
| 0x1424022D0 | CSteamStoreContext::[15] vtable 槽 CSteamStoreContext::[15]（func_names RTTI 名） |
| 0x1403C8400 | （无名） 体设 SSupportCategoryStatMultiplier::vftable（RTTI 名） |
| 0x141234C20 | CUnitStrategicMoveAction::[22] vtable 槽 CUnitStrategicMoveAction::[22]（func_names RTTI 名） |
| 0x141C94C40 | CDiplomacyGiveStateControlController::[6] vtable 槽 CDiplomacyGiveStateControlController::[6]（func_names RTTI 名） |
| 0x1406307E0 | CAIEquipmentRoleDatabase::[3] vtable 槽 CAIEquipmentRoleDatabase::[3]（func_names RTTI 名） |
| 0x140C13380 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x1423DDE70 | CSteamCloudFile::[4] vtable 槽 CSteamCloudFile::[4]（func_names RTTI 名） |
| 0x142402A60 | CSteamStoreContext::[11] vtable 槽 CSteamStoreContext::[11]（func_names RTTI 名） |
| 0x1405515E0 | （无名） 体设 CMeanTimeToHappen::vftable（RTTI 名） |
| 0x1422D73B0 | （无名） 体设 CPdx3DType::vftable（RTTI 名） |
| 0x141014780 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x142384730 | CPdxKeyBoard::[4] vtable 槽 CPdxKeyBoard::[4]（func_names RTTI 名） |
| 0x140E9D200 | （无名） 体设 CNavalAccidentReport::vftable（RTTI 名） |
| 0x141234BD0 | CUnitNavalMoveAction::[22] vtable 槽 CUnitNavalMoveAction::[22]（func_names RTTI 名） |
| 0x141BCFEC0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140A6D320 | SIconReader::[2] vtable 槽 SIconReader::[2]（func_names RTTI 名） |
| 0x141B1F9A0 | CMapSymbolDefinitionInstance::[2] vtable 槽 CMapSymbolDefinitionInstance::[2]（func_names RTTI 名） |
| 0x141C992C0 | CDiplomacyGiveStateControlController::[9] vtable 槽 CDiplomacyGiveStateControlController::[9]（func_names RTTI 名） |
| 0x142276FF0 | CPdxMeshObject::[13] vtable 槽 CPdxMeshObject::[13]（func_names RTTI 名） |
| 0x140A6D380 | SProgressbarReader::[2] vtable 槽 SProgressbarReader::[2]（func_names RTTI 名） |
| 0x141639B00 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14153DB80 | CFriendsHandlerSteam::[13] vtable 槽 CFriendsHandlerSteam::[13]（func_names RTTI 名） |
| 0x1418700F0 | CPlayerLobby::[15] vtable 槽 CPlayerLobby::[15]（func_names RTTI 名） |
| 0x1410FBE30 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14114E600 | （无名） 体设 CAddProductionLineUnorderedName::vftable（RTTI 名） |
| 0x1420B0300 | （无名） 体设 CCameraControlStrategy::vftable（RTTI 名） |
| 0x141265C20 | （无名） 体设 CMapArrowTextDefinition::vftable（RTTI 名） |
| 0x14134F350 | （无名） 体设 CSetMaxAllowedRepairDockyards::vftable（RTTI 名） |
| 0x1406CEE60 | CCountryPlayerSettings::[0] vtable 槽 CCountryPlayerSettings::[0]（func_names RTTI 名） |
| 0x14114E5A0 | （无名） 体设 CAddProductionLineOrderedName::vftable（RTTI 名） |
| 0x1413E2700 | CCombatant::[28] vtable 槽 CCombatant::[28]（func_names RTTI 名） |
| 0x14224BFB0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140AEEF90 | （无名） 体设 CUnitNamesPool::vftable（RTTI 名） |
| 0x14225B690 | CGui::[10] vtable 槽 CGui::[10]（func_names RTTI 名） |
| 0x14163C080 | （无名） 体设 CSetGamePlayOptions::vftable（RTTI 名） |
| 0x1416410A0 | CGameBitmapFont::[31] vtable 槽 CGameBitmapFont::[31]（func_names RTTI 名） |
| 0x1413EBAC0 | CLandBorderWarCombatant::[0] vtable 槽 CLandBorderWarCombatant::[0]（func_names RTTI 名） |
| 0x1411396A0 | CCancelAccessToLicenseProductionAction::[57] vtable 槽 CCancelAccessToLicenseProductionAction::[57]（func_names RTTI 名） |
| 0x14114F680 | （无名） 体设 CRemoveProductionLineName::vftable（RTTI 名） |
| 0x1413FB1F0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x142361C50 | （无名） 体设 CSdlEvents::vftable（RTTI 名） |
| 0x1413E2D60 | CCombatant::[11] vtable 槽 CCombatant::[11]（func_names RTTI 名） |
| 0x141AA6B90 | CIncomingDiplomaticAction::[0] vtable 槽 CIncomingDiplomaticAction::[0]（func_names RTTI 名） |
| 0x1416CC450 | CUnitLeaderTraitTree::[22] vtable 槽 CUnitLeaderTraitTree::[22]（func_names RTTI 名） |
| 0x1419968C0 | （无名） 体设 CProfileBadgeUpdateListener::vftable（RTTI 名） |
| 0x140E23980 | CStrategicRegion::[3] vtable 槽 CStrategicRegion::[3]（func_names RTTI 名） |
| 0x141446810 | CUnitMedalStore::[0] vtable 槽 CUnitMedalStore::[0]（func_names RTTI 名） |
| 0x1419C3A00 | CMapPingManager::[1] vtable 槽 CMapPingManager::[1]（func_names RTTI 名） |
| 0x141A04810 | （无名） 体设 CBreakthroughProgress::vftable（RTTI 名） |
| 0x1422ED5C0 | （无名） 体设 COption::vftable（RTTI 名） |
| 0x140CD7E40 | （无名） 体设 CLoss::vftable（RTTI 名） |
| 0x140EA5DD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14112DA10 | CCancelAccessToLicenseProductionAction::[23] vtable 槽 CCancelAccessToLicenseProductionAction::[23]（func_names RTTI 名） |
| 0x14225B140 | CGui::[9] vtable 槽 CGui::[9]（func_names RTTI 名） |
| 0x1422E55F0 | （无名） 体设 CChatMessage::vftable（RTTI 名） |
| 0x1424EE0E0 | （无名） 体设 CMemoryFile::vftable（RTTI 名） |
| 0x1413F6290 | CCryptology::[0] vtable 槽 CCryptology::[0]（func_names RTTI 名） |
| 0x141A9EA70 | COfferAirBaseAccessAction::[26] vtable 槽 COfferAirBaseAccessAction::[26]（func_names RTTI 名） |
| 0x142296640 | （无名） 体设 CPdx3DType::vftable（RTTI 名） |
| 0x14163CD60 | （无名） 体设 CSetMPDebugSettings::vftable（RTTI 名） |
| 0x141642230 | CMaskedSpriteType::[23] vtable 槽 CMaskedSpriteType::[23]（func_names RTTI 名） |
| 0x141857FC0 | IPEAVCSession::HHPEBVCOrdersGroup::H::VCID::AXAEBV?$CPdxArray::鈥�::[2] func_names 名 IPEAVCSession::HHPEBVCOrdersGroup::H::VCID::AXAEBV?$CPdxArray::鈥�::[2] |
| 0x1410FBD00 | （无名） 体设 CTransferHeadOfCounterIntelAction::vftable（RTTI 名） |
| 0x140C19BA0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x1414E90D0 | （无名） 体设 CCountryRaidStatus::vftable（RTTI 名） |
| 0x1423C29B0 | CSteamBrowserInstance::[8] vtable 槽 CSteamBrowserInstance::[8]（func_names RTTI 名） |
| 0x1423C2A70 | CSteamBrowserInstance::[10] vtable 槽 CSteamBrowserInstance::[10]（func_names RTTI 名） |
| 0x140D181A0 | （无名） 体设 CRelation::vftable（RTTI 名） |
| 0x141840DA0 | （无名） 体设 CRemoveAdmiralFromNavyHeadquarter::vftable（RTTI 名） |
| 0x14237E490 | （无名） 体设 CFont::vftable（RTTI 名） |
| 0x1423C3310 | CSteamBrowserInstance::[18] vtable 槽 CSteamBrowserInstance::[18]（func_names RTTI 名） |
| 0x1424F10A0 | （无名） 体设 CFile::vftable（RTTI 名） |
| 0x140D6D030 | CTaskForce::[27] vtable 槽 CTaskForce::[27]（func_names RTTI 名） |
| 0x1422E0BB0 | （无名） 体设 CChunkReceived::vftable（RTTI 名） |
| 0x140B3BBF0 | CFrontEndIdler::[55] vtable 槽 CFrontEndIdler::[55]（func_names RTTI 名） |
| 0x141B90260 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x140D18E30 | CRelation::[0] vtable 槽 CRelation::[0]（func_names RTTI 名） |
| 0x140D22450 | CLendLeaseRelation::[16] vtable 槽 CLendLeaseRelation::[16]（func_names RTTI 名） |
| 0x14100C800 | （无名） 体设 CEquipmentArcheTypePool::vftable（RTTI 名） |
| 0x1423E3E90 | CSteamMatchmakingContext::[30] vtable 槽 CSteamMatchmakingContext::[30]（func_names RTTI 名） |
| 0x14015F760 | CEquipmentGroupDatabase::[1] vtable 槽 CEquipmentGroupDatabase::[1]（func_names RTTI 名） |
| 0x1411397F0 | CEmbargoAction::[57] vtable 槽 CEmbargoAction::[57]（func_names RTTI 名） |
| 0x141B90760 | （无名） 体设 CAiIndustrialOrganisation::vftable（RTTI 名） |
| 0x1422CD170 | CDebugLineHelper::[2] vtable 槽 CDebugLineHelper::[2]（func_names RTTI 名） |
| 0x1422D12E0 | CButtonStandard::[78] vtable 槽 CButtonStandard::[78]（func_names RTTI 名） |
| 0x141A9E2F0 | COfferAirBaseAccessAction::[23] vtable 槽 COfferAirBaseAccessAction::[23]（func_names RTTI 名） |
| 0x141A9E9F0 | CAirBaseAccessAction::[26] vtable 槽 CAirBaseAccessAction::[26]（func_names RTTI 名） |
| 0x14134F130 | （无名） 体设 CSetCarrierDefensiveStance::vftable（RTTI 名） |
| 0x14142C270 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x140BBD7F0 | CIdCounterStore::[2] vtable 槽 CIdCounterStore::[2]（func_names RTTI 名） |
| 0x140C30C50 | CHeldOfficer::[0] vtable 槽 CHeldOfficer::[0]（func_names RTTI 名） |
| 0x141642A00 | CSprite::[72] vtable 槽 CSprite::[72]（func_names RTTI 名） |
| 0x141AA1230 | COfferDockingRightsAction::[23] vtable 槽 COfferDockingRightsAction::[23]（func_names RTTI 名） |
| 0x140C1D480 | CNavyLeader::[16] vtable 槽 CNavyLeader::[16]（func_names RTTI 名） |
| 0x140F8E780 | CEquipmentUpgradesInstance::[8] vtable 槽 CEquipmentUpgradesInstance::[8]（func_names RTTI 名） |
| 0x141840850 | （无名） 体设 COrderRemoveRootCommands::vftable（RTTI 名） |
| 0x140A08F00 | （无名） 体设 CEquipmentGroup::vftable（RTTI 名） |
| 0x14131AB50 | （无名） 体设 CUseFactionMemberManpower::vftable（RTTI 名） |
| 0x14126F200 | CFileWatcher::[0] vtable 槽 CFileWatcher::[0]（func_names RTTI 名） |
| 0x14163CDC0 | （无名） 体设 CSetReadyStatus::vftable（RTTI 名） |
| 0x140551770 | CAIMTTHChance::[0] vtable 槽 CAIMTTHChance::[0]（func_names RTTI 名） |
| 0x1412361F0 | CUnitStrategicMoveAction::[24] vtable 槽 CUnitStrategicMoveAction::[24]（func_names RTTI 名） |
| 0x14016A820 | COperationPhasesDatabase::[6] vtable 槽 COperationPhasesDatabase::[6]（func_names RTTI 名） |
| 0x141A26190 | （无名） 体设 CActivateActiveDecryptionBonuses::vftable（RTTI 名） |
| 0x141F63190 | （无名） 体设 CSplitWingOption::vftable（RTTI 名） |
| 0x14016A6D0 | CCountryTagAliasDatabase::[6] vtable 槽 CCountryTagAliasDatabase::[6]（func_names RTTI 名） |
| 0x14016A7B0 | CMTTHDatabase::[6] vtable 槽 CMTTHDatabase::[6]（func_names RTTI 名） |
| 0x14016A890 | COperationTokensDatabase::[6] vtable 槽 COperationTokensDatabase::[6]（func_names RTTI 名） |
| 0x14016A900 | COperationsDatabase::[6] vtable 槽 COperationsDatabase::[6]（func_names RTTI 名） |
| 0x14016AA50 | CScientistTraitDatabase::[6] vtable 槽 CScientistTraitDatabase::[6]（func_names RTTI 名） |
| 0x1422AAEF0 | CSmoothListbox::[43] vtable 槽 CSmoothListbox::[43]（func_names RTTI 名） |
| 0x141453A00 | （无名） 体设 CConferenceLiberatedParticipant::vftable（RTTI 名） |
| 0x141B3D330 | （无名） 体设 CNudgerStrategy::vftable（RTTI 名） |
| 0x141E7CD50 | （无名） 体设 CAirWingMapStack::vftable（RTTI 名） |
| 0x140F709A0 | CRailwayGunRepairLine::[11] vtable 槽 CRailwayGunRepairLine::[11]（func_names RTTI 名） |
| 0x1414FB850 | （无名） 体设 CLendLeaseAction::vftable（RTTI 名） |
| 0x141961640 | SAirUnitActivityData::[9] vtable 槽 SAirUnitActivityData::[9]（func_names RTTI 名） |
| 0x141961710 | SNavalUnitActivityData::[9] vtable 槽 SNavalUnitActivityData::[9]（func_names RTTI 名） |
| 0x141AA1A00 | COfferDockingRightsAction::[26] vtable 槽 COfferDockingRightsAction::[26]（func_names RTTI 名） |
| 0x141B90A00 | CAiIndustrialOrganisation::[1] vtable 槽 CAiIndustrialOrganisation::[1]（func_names RTTI 名） |
| 0x1422D0B20 | CButtonStandard::[29] vtable 槽 CButtonStandard::[29]（func_names RTTI 名） |
| 0x1413C4FA0 | （无名） 体设 CAIResearchNeed::vftable（RTTI 名） |
| 0x1419616B0 | SArmyUnitActivityData::[9] vtable 槽 SArmyUnitActivityData::[9]（func_names RTTI 名） |
| 0x141A75AE0 | CAIVolunteerGeneral::[0] vtable 槽 CAIVolunteerGeneral::[0]（func_names RTTI 名） |
| 0x1423E1200 | CSteamMatchmakingContext::[40] vtable 槽 CSteamMatchmakingContext::[40]（func_names RTTI 名） |
| 0x140F6EED0 | CNavalProductionLine::[0] vtable 槽 CNavalProductionLine::[0]（func_names RTTI 名） |
| 0x1413325D0 | （无名） 体设 SChannelInfo::vftable（RTTI 名） |
| 0x141AA11D0 | CDockingRightsAction::[23] vtable 槽 CDockingRightsAction::[23]（func_names RTTI 名） |
| 0x142384590 | CPdxMouse::[32] vtable 槽 CPdxMouse::[32]（func_names RTTI 名） |
| 0x141F60480 | （无名） 体设 CConsolidateWingsOption::vftable（RTTI 名） |
| 0x1422A93F0 | （无名） 体设 CScrollbarObserver::vftable（RTTI 名） |
| 0x1422CD6E0 | （无名） 体设 CRemoteFile::vftable（RTTI 名） |
| 0x1422FD9F0 | CSprite::[85] vtable 槽 CSprite::[85]（func_names RTTI 名） |
| 0x140646000 | CAIOperativeMissionStrategy::[0] vtable 槽 CAIOperativeMissionStrategy::[0]（func_names RTTI 名） |
| 0x141146420 | （无名） 体设 CRemoveProductionLineName::vftable（RTTI 名） |
| 0x1418CF2E0 | CDecisionMapIconContainer::[3] vtable 槽 CDecisionMapIconContainer::[3]（func_names RTTI 名） |
| 0x141A9E290 | CAirBaseAccessAction::[23] vtable 槽 CAirBaseAccessAction::[23]（func_names RTTI 名） |
| 0x140332C80 | CSetBorderWarCombatData::[0] vtable 槽 CSetBorderWarCombatData::[0]（func_names RTTI 名） |
| 0x1414FBB40 | CIncomingLendLeaseAction::[0] vtable 槽 CIncomingLendLeaseAction::[0]（func_names RTTI 名） |
| 0x1406463C0 | CFrontControlStrategyData::[0] vtable 槽 CFrontControlStrategyData::[0]（func_names RTTI 名） |
| 0x141A01E00 | CRailwayProductionLine::[0] vtable 槽 CRailwayProductionLine::[0]（func_names RTTI 名） |
| 0x14011E720 | （无名） 体设 System_error::vftable（RTTI 名） |
| 0x140B956C0 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14112E0F0 | COfferMilitaryAccessAction::[23] vtable 槽 COfferMilitaryAccessAction::[23]（func_names RTTI 名） |
| 0x1411436A0 | （无名） 体设 CAddProductionLineUnorderedName::vftable（RTTI 名） |
| 0x141F61610 | （无名） 体设 CHoldWingsOption::vftable（RTTI 名） |
| 0x142307770 | CButtonDrag::[22] vtable 槽 CButtonDrag::[22]（func_names RTTI 名） |
| 0x140B3BE00 | CFrontEndIdler::[84] vtable 槽 CFrontEndIdler::[84]（func_names RTTI 名） |
| 0x14153E4E0 | CFriendsHandlerSteam::[6] vtable 槽 CFriendsHandlerSteam::[6]（func_names RTTI 名） |
| 0x14163CD00 | （无名） 体设 CSetGameRuleOption::vftable（RTTI 名） |
| 0x1424EE510 | CRemoteFile::[2] vtable 槽 CRemoteFile::[2]（func_names RTTI 名） |
| 0x141143650 | （无名） 体设 CAddProductionLineOrderedName::vftable（RTTI 名） |
| 0x14163BFA0 | （无名） 体设 CSetCoopHotJoinOptions::vftable（RTTI 名） |
| 0x1423E76D0 | CSteamNetContext::[24] vtable 槽 CSteamNetContext::[24]（func_names RTTI 名） |
| 0x1409E7870 | （无名） 体设 CEquipmentFilter::vftable（RTTI 名） |
| 0x1414D65B0 | CPendingAddMovement::[4] vtable 槽 CPendingAddMovement::[4]（func_names RTTI 名） |
| 0x141E724E0 | CNavyTheaterGroupItemBase::[0] vtable 槽 CNavyTheaterGroupItemBase::[0]（func_names RTTI 名） |
| 0x141139D10 | CIncreaseAutonomyAction::[57] vtable 槽 CIncreaseAutonomyAction::[57]（func_names RTTI 名） |
| 0x14113A1A0 | CReduceAutonomyAction::[57] vtable 槽 CReduceAutonomyAction::[57]（func_names RTTI 名） |
| 0x141EFADC0 | X$$QEAUSDownloadProfileResult::Z::7::$$A6AXXZ::V?$function::std鈥�::[0] func_names 名 X$$QEAUSDownloadProfileResult::Z::7::$$A6AXXZ::V?$function::std鈥�::[0] |
| 0x1422DEDE0 | CGridBoxBase::[19] vtable 槽 CGridBoxBase::[19]（func_names RTTI 名） |
| 0x14011EA00 | （无名） 体设 System_error::vftable（RTTI 名） |
| 0x140E927F0 | CRailwayManager::[0] vtable 槽 CRailwayManager::[0]（func_names RTTI 名） |
| 0x14139DEC0 | （无名） 体设 CCharacterPortraits::vftable（RTTI 名） |
| 0x14163CC40 | （无名） 体设 CSetDifficulty::vftable（RTTI 名） |
| 0x140DE7610 | （无名） 体设 CSetRandomSeed::vftable（RTTI 名） |
| 0x141B7D660 | （无名） 体设 CTextBufferObserver::vftable（RTTI 名） |
| 0x141C993C0 | CDiplomacyCountryDeclareWarActionController::[9] vtable 槽 CDiplomacyCountryDeclareWarActionController::[9]（func_names RTTI 名） |
| 0x141C94B30 | CDiplomacyStageCoupController::[6] vtable 槽 CDiplomacyStageCoupController::[6]（func_names RTTI 名） |
| 0x141C98CF0 | CDiplomacySendExpeditionaryForceController::[2] vtable 槽 CDiplomacySendExpeditionaryForceController::[2]（func_names RTTI 名） |
| 0x140AD2A20 | CTechnologyTemplate::[3] vtable 槽 CTechnologyTemplate::[3]（func_names RTTI 名） |
| 0x140F718B0 | （无名） 体设 CShipRefitProductionLine::vftable（RTTI 名） |
| 0x141642CE0 | CSprite::[47] vtable 槽 CSprite::[47]（func_names RTTI 名） |
| 0x14112DFD0 | CMilitaryAccessAction::[23] vtable 槽 CMilitaryAccessAction::[23]（func_names RTTI 名） |
| 0x14150D9F0 | CReinforcementStatus::[1] vtable 槽 CReinforcementStatus::[1]（func_names RTTI 名） |
| 0x14163C150 | （无名） 体设 CSetReadyStatus::vftable（RTTI 名） |
| 0x14237F270 | CTrack::[14] vtable 槽 CTrack::[14]（func_names RTTI 名） |
| 0x141509F00 | CReinforcementStatus::[0] vtable 槽 CReinforcementStatus::[0]（func_names RTTI 名） |
| 0x1422FDAF0 | CSprite::[86] vtable 槽 CSprite::[86]（func_names RTTI 名） |
| 0x140D18EA0 | CImproveRelationsRelation::[0] vtable 槽 CImproveRelationsRelation::[0]（func_names RTTI 名） |
| 0x141E8D230 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x142233660 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422FE320 | CSprite::[9] vtable 槽 CSprite::[9]（func_names RTTI 名） |
| 0x14101A0B0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x141509D60 | CArmyUpgradesStatus::[0] vtable 槽 CArmyUpgradesStatus::[0]（func_names RTTI 名） |
| 0x1422E5550 | （无名） 体设 CChatMessage::vftable（RTTI 名） |
| 0x14163CB20 | （无名） 体设 CSetAchievementsOK::vftable（RTTI 名） |
| 0x1418C41A0 | CDecisionMapIconContainer::[7] vtable 槽 CDecisionMapIconContainer::[7]（func_names RTTI 名） |
| 0x141C99AE0 | CDiplomacyStageCoupController::[9] vtable 槽 CDiplomacyStageCoupController::[9]（func_names RTTI 名） |
| 0x14015FDE0 | CMeanTimeToHappen::[0] vtable 槽 CMeanTimeToHappen::[0]（func_names RTTI 名） |
| 0x1402CCE30 | CFocusInlayWindowInstance::[0] vtable 槽 CFocusInlayWindowInstance::[0]（func_names RTTI 名） |
| 0x140557310 | CDynamicModifierContainer::[0] vtable 槽 CDynamicModifierContainer::[0]（func_names RTTI 名） |
| 0x1406CEFD0 | CNuke::[0] vtable 槽 CNuke::[0]（func_names RTTI 名） |
| 0x141DF94B0 | CStandardMusicPlaylistController::[6] vtable 槽 CStandardMusicPlaylistController::[6]（func_names RTTI 名） |
| 0x1424FB8E0 | （无名） 体设 CChecksumFile::vftable（RTTI 名） |
| 0x140A467B0 | CIdeologyDatabase::[1] vtable 槽 CIdeologyDatabase::[1]（func_names RTTI 名） |
| 0x140BDD230 | CEquipmentVariant::[8] vtable 槽 CEquipmentVariant::[8]（func_names RTTI 名） |
| 0x141642C70 | CShieldObject::[73] vtable 槽 CShieldObject::[73]（func_names RTTI 名） |
| 0x141651720 | CCitySettings::SGroup::[0] vtable 槽 CCitySettings::SGroup::[0]（func_names RTTI 名） |
| 0x140A86B10 | CPoliticalPortraitPool::[0] vtable 槽 CPoliticalPortraitPool::[0]（func_names RTTI 名） |
| 0x140E55640 | CPowerBalanceSystem::[0] vtable 槽 CPowerBalanceSystem::[0]（func_names RTTI 名） |
| 0x140ED2C90 | （无名） 体设 CLimitedUseTechCostReduction::vftable（RTTI 名） |
| 0x14153D4A0 | CFriendsHandler::[0] vtable 槽 CFriendsHandler::[0]（func_names RTTI 名） |
| 0x141F52460 | （无名） 体设 CResetCustomDifficultyMultipliers::vftable（RTTI 名） |
| 0x1422D2160 | CButtonStandard::[112] vtable 槽 CButtonStandard::[112]（func_names RTTI 名） |
| 0x140CBF530 | （无名） 体设 CFlagManager::vftable（RTTI 名） |
| 0x141C2FBF0 | CDeleteOrRenameFolderPopUp::[16] vtable 槽 CDeleteOrRenameFolderPopUp::[16]（func_names RTTI 名） |
| 0x1416CB020 | CUnitLeaderTraitTree::[21] vtable 槽 CUnitLeaderTraitTree::[21]（func_names RTTI 名） |
| 0x1422ACF20 | CStandardlistbox::[35] vtable 槽 CStandardlistbox::[35]（func_names RTTI 名） |
| 0x1422ADB40 | CSmoothListbox::[27] vtable 槽 CSmoothListbox::[27]（func_names RTTI 名） |
| 0x142301350 | CSmoothListbox::[35] vtable 槽 CSmoothListbox::[35]（func_names RTTI 名） |
| 0x141F62570 | （无名） 体设 CRemoveFromGroupOption::vftable（RTTI 名） |
| 0x14237E320 | CPdxDummy3DType::[13] vtable 槽 CPdxDummy3DType::[13]（func_names RTTI 名） |
| 0x1407258C0 | CHighlightStates::[0] vtable 槽 CHighlightStates::[0]（func_names RTTI 名） |
| 0x142301600 | CSmoothListbox::[8] vtable 槽 CSmoothListbox::[8]（func_names RTTI 名） |
| 0x1412D46D0 | CNudgeIdler::[8] vtable 槽 CNudgeIdler::[8]（func_names RTTI 名） |
| 0x140DE7100 | （无名） 体设 CAutosave::vftable（RTTI 名） |
| 0x142268370 | SpeechInput::[3] vtable 槽 SpeechInput::[3]（func_names RTTI 名） |
| 0x1413E40F0 | CCombatant::[20] vtable 槽 CCombatant::[20]（func_names RTTI 名） |
| 0x142268000 | SpeechInput::[0] vtable 槽 SpeechInput::[0]（func_names RTTI 名） |
| 0x1423004A0 | CSmoothListbox::[7] vtable 槽 CSmoothListbox::[7]（func_names RTTI 名） |
| 0x142399940 | CSteamAchievementsContext::[6] vtable 槽 CSteamAchievementsContext::[6]（func_names RTTI 名） |
| 0x14015EC00 | COperationTokensDatabase::[1] vtable 槽 COperationTokensDatabase::[1]（func_names RTTI 名） |
| 0x14015EC70 | COperationsDatabase::[1] vtable 槽 COperationsDatabase::[1]（func_names RTTI 名） |
| 0x14015EDC0 | CScientistTraitDatabase::[1] vtable 槽 CScientistTraitDatabase::[1]（func_names RTTI 名） |
| 0x14015F410 | CCountryTagAliasDatabase::[1] vtable 槽 CCountryTagAliasDatabase::[1]（func_names RTTI 名） |
| 0x140333B60 | SInitialScientistSkillLevel::[0] vtable 槽 SInitialScientistSkillLevel::[0]（func_names RTTI 名） |
| 0x140A31CF0 | CFriendsHandler::[4] vtable 槽 CFriendsHandler::[4]（func_names RTTI 名） |
| 0x140A46820 | CIdeologyGroupDatabase::[1] vtable 槽 CIdeologyGroupDatabase::[1]（func_names RTTI 名） |
| 0x141C2FB90 | CDeleteDesignPopUp::[16] vtable 槽 CDeleteDesignPopUp::[16]（func_names RTTI 名） |
| 0x1423A9C20 | PdxSpeechToTextInterface::[0] vtable 槽 PdxSpeechToTextInterface::[0]（func_names RTTI 名） |
| 0x140C1D410 | CArmyLeader::[16] vtable 槽 CArmyLeader::[16]（func_names RTTI 名） |
| 0x1410FF170 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140B41040 | CGameGraphics::[1] vtable 槽 CGameGraphics::[1]（func_names RTTI 名） |
| 0x1412B93A0 | CLandCombat::[24] vtable 槽 CLandCombat::[24]（func_names RTTI 名） |
| 0x1422FE3A0 | CSprite::[11] vtable 槽 CSprite::[11]（func_names RTTI 名） |
| 0x14237AFF0 | CRadioScrollbarGroupType::[2] vtable 槽 CRadioScrollbarGroupType::[2]（func_names RTTI 名） |
| 0x140646490 | CScorchEarthPrioData::[0] vtable 槽 CScorchEarthPrioData::[0]（func_names RTTI 名） |
| 0x14163CB80 | （无名） 体设 CSetCoopHotJoinOptions::vftable（RTTI 名） |
| 0x1422FE2C0 | （无名） 体设 CSprite::vftable（RTTI 名） |
| 0x1423E2FE0 | CMatchmakingServerListResponse::[1] vtable 槽 CMatchmakingServerListResponse::[1]（func_names RTTI 名） |
| 0x1410FBEA0 | （无名） 体设 CTransferHeadOfOperationsAction::vftable（RTTI 名） |
| 0x141CEA890 | （无名） 体设 CRaidArrow::vftable（RTTI 名） |
| 0x140443CB0 | CIsPromotedFromUnit::[22] vtable 槽 CIsPromotedFromUnit::[22]（func_names RTTI 名） |
| 0x14163CA00 | （无名） 体设 CRequestReadyStatus::vftable（RTTI 名） |
| 0x141333700 | CChat::CUserItem::[0] vtable 槽 CChat::CUserItem::[0]（func_names RTTI 名） |
| 0x140BE9BC0 | （无名） 体设 CArmyGroup::vftable（RTTI 名） |
| 0x141E7CDA0 | CAirWingMapStack::[0] vtable 槽 CAirWingMapStack::[0]（func_names RTTI 名） |
| 0x1422231D0 | （无名） 体设 CFileLogger::vftable（RTTI 名） |
| 0x140551650 | （无名） 体设 CMTTHModifier::vftable（RTTI 名） |
| 0x140F6F440 | CNavalProductionLine::[8] vtable 槽 CNavalProductionLine::[8]（func_names RTTI 名） |
| 0x141B3D490 | CNudgerStrategy::[0] vtable 槽 CNudgerStrategy::[0]（func_names RTTI 名） |
| 0x141DF9760 | CStandardMusicPlaylistController::[12] vtable 槽 CStandardMusicPlaylistController::[12]（func_names RTTI 名） |
| 0x1414C3550 | CPendingAddMovement::[0] vtable 槽 CPendingAddMovement::[0]（func_names RTTI 名） |
| 0x141F524B0 | （无名） 体设 CResetGameRules::vftable（RTTI 名） |
| 0x1422ACE70 | CStandardlistbox::[24] vtable 槽 CStandardlistbox::[24]（func_names RTTI 名） |
| 0x1423012F0 | CSmoothListbox::[24] vtable 槽 CSmoothListbox::[24]（func_names RTTI 名） |
| 0x1402D75F0 | CNationalFocus::[3] vtable 槽 CNationalFocus::[3]（func_names RTTI 名） |
| 0x140F6ECA0 | CMilitaryProductionLine::[8] vtable 槽 CMilitaryProductionLine::[8]（func_names RTTI 名） |
| 0x140F70AD0 | CRailwayGunProductionLine::[8] vtable 槽 CRailwayGunProductionLine::[8]（func_names RTTI 名） |
| 0x140F71CF0 | CShipRefitProductionLine::[8] vtable 槽 CShipRefitProductionLine::[8]（func_names RTTI 名） |
| 0x141C978E0 | CDiplomacyCallAllyActionController::[2] vtable 槽 CDiplomacyCallAllyActionController::[2]（func_names RTTI 名） |
| 0x1402E0630 | CSaveGameController::[0] vtable 槽 CSaveGameController::[0]（func_names RTTI 名） |
| 0x142355C70 | CPdxTouchDevice::[0] vtable 槽 CPdxTouchDevice::[0]（func_names RTTI 名） |
| 0x140FC0D50 | （无名） 体设 COperativeMission::vftable（RTTI 名） |
| 0x140F912C0 | （无名） 体设 SActiveResistanceAction::vftable（RTTI 名） |
| 0x1410FBDD0 | （无名） 体设 CTransferHeadOfCryptologyAction::vftable（RTTI 名） |
| 0x1413F4590 | （无名） 体设 CCountryCollaborationStatus::vftable（RTTI 名） |
| 0x141C97950 | CDiplomacyBoostPartyPopularityController::[2] vtable 槽 CDiplomacyBoostPartyPopularityController::[2]（func_names RTTI 名） |
| 0x140C11610 | CArmyLeader::[22] vtable 槽 CArmyLeader::[22]（func_names RTTI 名） |
| 0x140C11680 | CNavyLeader::[22] vtable 槽 CNavyLeader::[22]（func_names RTTI 名） |
| 0x140556300 | （无名） 体设 CDynamicModifierContainer::vftable（RTTI 名） |
| 0x1409D7390 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x142361100 | CTextSpriteType::[23] vtable 槽 CTextSpriteType::[23]（func_names RTTI 名） |
| 0x140CBD990 | CConvoyClient::[14] vtable 槽 CConvoyClient::[14]（func_names RTTI 名） |
| 0x14163A0C0 | CTheaterGroup::[8] vtable 槽 CTheaterGroup::[8]（func_names RTTI 名） |
| 0x1409F0050 | （无名） 体设 CEquipmentFilter::vftable（RTTI 名） |
| 0x140AABC10 | CScriptableLocalizationDatabase::[1] vtable 槽 CScriptableLocalizationDatabase::[1]（func_names RTTI 名） |
| 0x142502B70 | （无名） 体设 CException::vftable（RTTI 名） |
| 0x140683570 | CBuildingTemplate::SCountryModifier::[0] vtable 槽 CBuildingTemplate::SCountryModifier::[0]（func_names RTTI 名） |
| 0x140BB6A60 | CCombatManager::[0] vtable 槽 CCombatManager::[0]（func_names RTTI 名） |
| 0x14163C9B0 | （无名） 体设 CQuit::vftable（RTTI 名） |
| 0x1419D7900 | （无名） 体设 CCallbacksWrapper::vftable（RTTI 名） |
| 0x1405562B0 | （无名） 体设 CDynamicModifierContainer::vftable（RTTI 名） |
| 0x140F6EB40 | CMilitaryProductionLine::[11] vtable 槽 CMilitaryProductionLine::[11]（func_names RTTI 名） |
| 0x141C98FB0 | CDiplomacyStandardController::[3] vtable 槽 CDiplomacyStandardController::[3]（func_names RTTI 名） |
| 0x14182AD10 | CMapModeOperationSelectTarget::[0] vtable 槽 CMapModeOperationSelectTarget::[0]（func_names RTTI 名） |
| 0x140BF93E0 | CSupplyConsumer::[0] vtable 槽 CSupplyConsumer::[0]（func_names RTTI 名） |
| 0x142355D60 | CPdxSystem::[3] vtable 槽 CPdxSystem::[3]（func_names RTTI 名） |
| 0x1415A0D10 | COwnerChange::[17] vtable 槽 COwnerChange::[17]（func_names RTTI 名） |
| 0x140DE5CD0 | （无名） 体设 CAutosave::vftable（RTTI 名） |
| 0x1419D79B0 | （无名） 体设 CFloatToHsv::vftable（RTTI 名） |
| 0x1419D7A10 | （无名） 体设 CNormalizer::vftable（RTTI 名） |
| 0x14122C690 | CCountrySupplySystem::[1] vtable 槽 CCountrySupplySystem::[1]（func_names RTTI 名） |
| 0x141484450 | （无名） 体设 CException::vftable（RTTI 名） |
| 0x141CFDD80 | CConfirmDeleteOrdersGroup::[0] vtable 槽 CConfirmDeleteOrdersGroup::[0]（func_names RTTI 名） |
| 0x140160A40 | CScriptedEffectTemplateDatabase::[1] vtable 槽 CScriptedEffectTemplateDatabase::[1]（func_names RTTI 名） |
| 0x1403327F0 | CReduceFocusCost::[0] vtable 槽 CReduceFocusCost::[0]（func_names RTTI 名） |
| 0x140527650 | CSetStrategicStateLocationBuildingLevel::[0] vtable 槽 CSetStrategicStateLocationBuildingLevel::[0]（func_names RTTI 名） |
| 0x140CBF590 | CFlagManager::[0] vtable 槽 CFlagManager::[0]（func_names RTTI 名） |
| 0x140D6CBF0 | CTaskForce::[38] vtable 槽 CTaskForce::[38]（func_names RTTI 名） |
| 0x141924FE0 | CPersistedMioQueues::[0] vtable 槽 CPersistedMioQueues::[0]（func_names RTTI 名） |
| 0x1422D7610 | CPdx3DObject::[4] vtable 槽 CPdx3DObject::[4]（func_names RTTI 名） |
| 0x140A3D1D0 | COOBChange::[19] vtable 槽 COOBChange::[19]（func_names RTTI 名） |
| 0x1423C2C80 | CSteamBrowserInstance::[15] vtable 槽 CSteamBrowserInstance::[15]（func_names RTTI 名） |
| 0x1423C2CD0 | CSteamBrowserInstance::[17] vtable 槽 CSteamBrowserInstance::[17]（func_names RTTI 名） |
| 0x1402DB480 | CNationalFocus::[12] vtable 槽 CNationalFocus::[12]（func_names RTTI 名） |
| 0x140FC0DA0 | （无名） 体设 COperativeMission::vftable（RTTI 名） |
| 0x14131A6E0 | CAIPoliticalMinister::[0] vtable 槽 CAIPoliticalMinister::[0]（func_names RTTI 名） |
| 0x141C989B0 | CDiplomacyRequestLicensedProductionController::[2] vtable 槽 CDiplomacyRequestLicensedProductionController::[2]（func_names RTTI 名） |
| 0x141F19360 | CDeleter::[0] vtable 槽 CDeleter::[0]（func_names RTTI 名） |
| 0x140DF8480 | CSeasons::[0] vtable 槽 CSeasons::[0]（func_names RTTI 名） |
| 0x141020490 | （无名） 体设 CConvoySubscriber::vftable（RTTI 名） |
| 0x141A38140 | （无名） 体设 SProjectContext::vftable（RTTI 名） |
| 0x141D13E00 | CUnitLeaderTraitTree::[30] vtable 槽 CUnitLeaderTraitTree::[30]（func_names RTTI 名） |
| 0x1424D44B0 | CTask::[0] vtable 槽 CTask::[0]（func_names RTTI 名） |
| 0x14113A130 | CPeaceProposalAction::[57] vtable 槽 CPeaceProposalAction::[57]（func_names RTTI 名） |
| 0x141F57470 | CFileIntegrityWatermark::[0] vtable 槽 CFileIntegrityWatermark::[0]（func_names RTTI 名） |
| 0x1422E7FA0 | CChatBuffer::CSendChatMessage::[0] vtable 槽 CChatBuffer::CSendChatMessage::[0]（func_names RTTI 名） |
| 0x1402A8190 | CAIStrategyStore::[0] vtable 槽 CAIStrategyStore::[0]（func_names RTTI 名） |
| 0x14064D0D0 | CStrategicAI::SNavalInvasionEntry::[0] vtable 槽 CStrategicAI::SNavalInvasionEntry::[0]（func_names RTTI 名） |
| 0x14112DB00 | CCancelLicensedProductionAction::[23] vtable 槽 CCancelLicensedProductionAction::[23]（func_names RTTI 名） |
| 0x14153DB40 | CFriendsHandlerSteam::[11] vtable 槽 CFriendsHandlerSteam::[11]（func_names RTTI 名） |
| 0x140ABC470 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x14112E290 | CRequestForeignManpowerAction::[23] vtable 槽 CRequestForeignManpowerAction::[23]（func_names RTTI 名） |
| 0x1416CB910 | CUnitLeaderTraitTree::[13] vtable 槽 CUnitLeaderTraitTree::[13]（func_names RTTI 名） |
| 0x141C93E90 | CDiplomacyStageCoupController::[20] vtable 槽 CDiplomacyStageCoupController::[20]（func_names RTTI 名） |
| 0x1422FE490 | CSprite::[43] vtable 槽 CSprite::[43]（func_names RTTI 名） |
| 0x142360690 | CResizeableSpriteType::[10] vtable 槽 CResizeableSpriteType::[10]（func_names RTTI 名） |
| 0x14112DA90 | CCancelForeignManpowerAction::[23] vtable 槽 CCancelForeignManpowerAction::[23]（func_names RTTI 名） |
| 0x141C8A090 | （无名） 体设 CDiplomacyGuaranteeActionController::vftable（RTTI 名） |
| 0x1423B9A10 | CAudioSoundSDL::[0] vtable 槽 CAudioSoundSDL::[0]（func_names RTTI 名） |
| 0x140C19BF0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x141229110 | CCountrySupplySystem::[4] vtable 槽 CCountrySupplySystem::[4]（func_names RTTI 名） |
| 0x1416CB980 | CUnitLeaderTraitTree::[15] vtable 槽 CUnitLeaderTraitTree::[15]（func_names RTTI 名） |
| 0x1422D1290 | CButtonStandard::[92] vtable 槽 CButtonStandard::[92]（func_names RTTI 名） |
| 0x142354F90 | CCorneredTileSprite::[54] vtable 槽 CCorneredTileSprite::[54]（func_names RTTI 名） |
| 0x1423E8A40 | CSteamNetContext::[14] vtable 槽 CSteamNetContext::[14]（func_names RTTI 名） |
| 0x140DD3720 | CInGameIdler::[42] vtable 槽 CInGameIdler::[42]（func_names RTTI 名） |
| 0x141234200 | （无名） 体设 CUnitStrategicMoveAction::vftable（RTTI 名） |
| 0x141709FC0 | CCountryMilitaryOverview::[5] vtable 槽 CCountryMilitaryOverview::[5]（func_names RTTI 名） |
| 0x14150C880 | CArmyUpgradesStatus::[4] vtable 槽 CArmyUpgradesStatus::[4]（func_names RTTI 名） |
| 0x14150C8E0 | CGarrisonStatus::[4] vtable 槽 CGarrisonStatus::[4]（func_names RTTI 名） |
| 0x14150C9C0 | CReinforcementStatus::[4] vtable 槽 CReinforcementStatus::[4]（func_names RTTI 名） |
| 0x1416CAF70 | CUnitLeaderTraitTree::[14] vtable 槽 CUnitLeaderTraitTree::[14]（func_names RTTI 名） |
| 0x141C99320 | CDiplomacyBoostPartyPopularityController::[9] vtable 槽 CDiplomacyBoostPartyPopularityController::[9]（func_names RTTI 名） |
| 0x141DE85B0 | （无名） 体设 CDarkFullscreenOverlay::vftable（RTTI 名） |
| 0x141DF9110 | CStandardMusicPlaylistController::[11] vtable 槽 CStandardMusicPlaylistController::[11]（func_names RTTI 名） |
| 0x1422CD670 | （无名） 体设 CRemoteFile::vftable（RTTI 名） |
| 0x142320420 | CLineChartType::[10] vtable 槽 CLineChartType::[10]（func_names RTTI 名） |
| 0x141502DD0 | CIncomingLendLeaseAction::[67] vtable 槽 CIncomingLendLeaseAction::[67]（func_names RTTI 名） |
| 0x1422D4A80 | CInstantSprite::[11] vtable 槽 CInstantSprite::[11]（func_names RTTI 名） |
| 0x140CA6180 | CResourceExchange::[0] vtable 槽 CResourceExchange::[0]（func_names RTTI 名） |
| 0x140CEA490 | CMilitaryDeploymentLine::[8] vtable 槽 CMilitaryDeploymentLine::[8]（func_names RTTI 名） |
| 0x140DF8400 | （无名） 体设 CTreeSeasonType::vftable（RTTI 名） |
| 0x14112E380 | CRequestPuppetForcesAction::[23] vtable 槽 CRequestPuppetForcesAction::[23]（func_names RTTI 名） |
| 0x14015FAE0 | CGFXReloader::[0] vtable 槽 CGFXReloader::[0]（func_names RTTI 名） |
| 0x140CB6750 | CConvoyClient::[11] vtable 槽 CConvoyClient::[11]（func_names RTTI 名） |
| 0x14112DD20 | CGiveStateControlAction::[23] vtable 槽 CGiveStateControlAction::[23]（func_names RTTI 名） |
| 0x14112DEF0 | CIncreaseAutonomyAction::[23] vtable 槽 CIncreaseAutonomyAction::[23]（func_names RTTI 名） |
| 0x14112E3F0 | CReturnAllExpeditionaryForcesAction::[23] vtable 槽 CReturnAllExpeditionaryForcesAction::[23]（func_names RTTI 名） |
| 0x141A042E0 | CRailwayProductionLine::[10] vtable 槽 CRailwayProductionLine::[10]（func_names RTTI 名） |
| 0x1401DB450 | CTechnologySharing::[18] vtable 槽 CTechnologySharing::[18]（func_names RTTI 名） |
| 0x140A4D1C0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x14112D870 | CAskForStateControlAction::[23] vtable 槽 CAskForStateControlAction::[23]（func_names RTTI 名） |
| 0x14112E570 | CSendVolunteerAction::[23] vtable 槽 CSendVolunteerAction::[23]（func_names RTTI 名） |
| 0x140AAE290 | CScriptedMapModeLayer::[0] vtable 槽 CScriptedMapModeLayer::[0]（func_names RTTI 名） |
| 0x14112E150 | CPeaceProposalAction::[23] vtable 槽 CPeaceProposalAction::[23]（func_names RTTI 名） |
| 0x14112E1B0 | CReduceAutonomyAction::[23] vtable 槽 CReduceAutonomyAction::[23]（func_names RTTI 名） |
| 0x14112E510 | CSendExpeditionaryForceAction::[23] vtable 槽 CSendExpeditionaryForceAction::[23]（func_names RTTI 名） |
| 0x141C99000 | CDiplomacyStandardController::[2] vtable 槽 CDiplomacyStandardController::[2]（func_names RTTI 名） |
| 0x1414C9EE0 | CPendingTransportUnit::[3] vtable 槽 CPendingTransportUnit::[3]（func_names RTTI 名） |
| 0x141642290 | CMaskedSpriteType::[16] vtable 槽 CMaskedSpriteType::[16]（func_names RTTI 名） |
| 0x1403031F0 | CScopedVariableWithPostValidate::[0] vtable 槽 CScopedVariableWithPostValidate::[0]（func_names RTTI 名） |
| 0x140C1EA60 | CNavyLeader::[1] vtable 槽 CNavyLeader::[1]（func_names RTTI 名） |
| 0x1423E0A00 | CSteamMatchmakingContext::[7] vtable 槽 CSteamMatchmakingContext::[7]（func_names RTTI 名） |
| 0x1423E1440 | CSteamMatchmakingContext::[5] vtable 槽 CSteamMatchmakingContext::[5]（func_names RTTI 名） |
| 0x1424BA1F0 | CTweakableFloat::[2] vtable 槽 CTweakableFloat::[2]（func_names RTTI 名） |
| 0x140DDCED0 | CInGameIdler::[31] vtable 槽 CInGameIdler::[31]（func_names RTTI 名） |
| 0x140DDCF20 | CInGameIdler::[32] vtable 槽 CInGameIdler::[32]（func_names RTTI 名） |
| 0x14112D810 | CAddWarGoalAction::[23] vtable 槽 CAddWarGoalAction::[23]（func_names RTTI 名） |
| 0x141CA6B10 | CRelationStripViewBase::CStripFlagItem::[0] vtable 槽 CRelationStripViewBase::CStripFlagItem::[0]（func_names RTTI 名） |
| 0x142295E50 | CCorneredTileSpriteType::[23] vtable 槽 CCorneredTileSpriteType::[23]（func_names RTTI 名） |
| 0x1423C34A0 | CSteamBrowserContext::[2] vtable 槽 CSteamBrowserContext::[2]（func_names RTTI 名） |
| 0x140D6FA00 | CTaskForce::[54] vtable 槽 CTaskForce::[54]（func_names RTTI 名） |
| 0x140FC0E80 | （无名） 体设 COperativeMission::vftable（RTTI 名） |
| 0x14163BF30 | （无名） 体设 CRequestReadyStatus::vftable（RTTI 名） |
| 0x141C89DF0 | （无名） 体设 CDiplomacyDefaultScriptedDiplomaticActionController::vftable（RTTI 名） |
| 0x141F60EF0 | （无名） 体设 CDisbandAllOption::vftable（RTTI 名） |
| 0x142330FF0 | SCurveAnimationReader::[0] vtable 槽 SCurveAnimationReader::[0]（func_names RTTI 名） |
| 0x14237E400 | CPdxDummy3DObject::[12] vtable 槽 CPdxDummy3DObject::[12]（func_names RTTI 名） |
| 0x142380E70 | StackWalker::[4] vtable 槽 StackWalker::[4]（func_names RTTI 名） |
| 0x14011E570 | （无名） 体设 System_error::vftable（RTTI 名） |
| 0x140D01B80 | （无名） 体设 CDynamicIntelSourcePool::vftable（RTTI 名） |
| 0x14112D9A0 | CCallAllyAction::[23] vtable 槽 CCallAllyAction::[23]（func_names RTTI 名） |
| 0x14112DF60 | CJoinAllyAction::[23] vtable 槽 CJoinAllyAction::[23]（func_names RTTI 名） |
| 0x1416CB270 | CUnitLeaderTraitTree::[17] vtable 槽 CUnitLeaderTraitTree::[17]（func_names RTTI 名） |
| 0x1414E5310 | CTimeSeries::[0] vtable 槽 CTimeSeries::[0]（func_names RTTI 名） |
| 0x141857F80 | IPEAVCSession::HHPEBVCOrdersGroup::H::VCID::AXAEBV?$CPdxArray::鈥�::[0] func_names 名 IPEAVCSession::HHPEBVCOrdersGroup::H::VCID::AXAEBV?$CPdxArray::鈥�::[0] |
| 0x14193E980 | CHqDeploymentDistributable::[8] vtable 槽 CHqDeploymentDistributable::[8]（func_names RTTI 名） |
| 0x141E722A0 | （无名） 体设 CNavyTheaterGroupItemBase::vftable（RTTI 名） |
| 0x140AB14A0 | CScriptedDiplomaticActionTemplateDatabase::[1] vtable 槽 CScriptedDiplomaticActionTemplateDatabase::[1]（func_names RTTI 名） |
| 0x1414B57C0 | CProductionLine::[15] vtable 槽 CProductionLine::[15]（func_names RTTI 名） |
| 0x1416CB210 | CUnitLeaderTraitTree::[12] vtable 槽 CUnitLeaderTraitTree::[12]（func_names RTTI 名） |
| 0x14198BB50 | （无名） 体设 CTaskForceCompositionRequirements::vftable（RTTI 名） |
| 0x14015F9C0 | CGarrisonStatus::[0] vtable 槽 CGarrisonStatus::[0]（func_names RTTI 名） |
| 0x1401FA580 | SCVAASettings::[0] vtable 槽 SCVAASettings::[0]（func_names RTTI 名） |
| 0x140D74C60 | CTaskForce::[2] vtable 槽 CTaskForce::[2]（func_names RTTI 名） |
| 0x140DD8330 | CInGameIdler::[77] vtable 槽 CInGameIdler::[77]（func_names RTTI 名） |
| 0x142230690 | CNullMouse::[0] vtable 槽 CNullMouse::[0]（func_names RTTI 名） |
| 0x14015F7E0 | CEquipmentStats::[0] vtable 槽 CEquipmentStats::[0]（func_names RTTI 名） |
| 0x140160B30 | CEquipmentFilter::[0] vtable 槽 CEquipmentFilter::[0]（func_names RTTI 名） |
| 0x1403CCBC0 | SSupportCategoryStatMultiplier::[0] vtable 槽 SSupportCategoryStatMultiplier::[0]（func_names RTTI 名） |
| 0x1406835E0 | CBuildingTemplate::SLevelMax::[0] vtable 槽 CBuildingTemplate::SLevelMax::[0]（func_names RTTI 名） |
| 0x140A35B10 | CGameRulesInstance::[0] vtable 槽 CGameRulesInstance::[0]（func_names RTTI 名） |
| 0x140BCB6D0 | CStrategicResourcePool::[0] vtable 槽 CStrategicResourcePool::[0]（func_names RTTI 名） |
| 0x140D025D0 | CIntelSource::[0] vtable 槽 CIntelSource::[0]（func_names RTTI 名） |
| 0x141DF86E0 | CStandardMusicPlaybackController::[5] vtable 槽 CStandardMusicPlaybackController::[5]（func_names RTTI 名） |
| 0x14061FA60 | CAchievement::[10] vtable 槽 CAchievement::[10]（func_names RTTI 名） |
| 0x140AD78E0 | CTimedStageCoupActivity::[0] vtable 槽 CTimedStageCoupActivity::[0]（func_names RTTI 名） |
| 0x140CB4770 | CCountryResources::[4] vtable 槽 CCountryResources::[4]（func_names RTTI 名） |
| 0x140F6F520 | CNavalProductionLine::[29] vtable 槽 CNavalProductionLine::[29]（func_names RTTI 名） |
| 0x14165F630 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1422FDA60 | CSprite::[42] vtable 槽 CSprite::[42]（func_names RTTI 名） |
| 0x14234BA40 | （无名） 体设 CAssetFactory::vftable（RTTI 名） |
| 0x142357600 | CFrameAnimatedSpriteType::[23] vtable 槽 CFrameAnimatedSpriteType::[23]（func_names RTTI 名） |
| 0x142360760 | CResizeableSpriteType::[23] vtable 槽 CResizeableSpriteType::[23]（func_names RTTI 名） |
| 0x140DDFCA0 | CInGameIdler::[40] vtable 槽 CInGameIdler::[40]（func_names RTTI 名） |
| 0x141C8AEF0 | （无名） 体设 CDiplomacyNavalBlockadeActionController::vftable（RTTI 名） |
| 0x142384520 | CPdxMouse::[0] vtable 槽 CPdxMouse::[0]（func_names RTTI 名） |
| 0x140AAD7E0 | （无名） 体设 CScriptedMapModeLayer::vftable（RTTI 名） |
| 0x14197ED30 | （无名） 体设 CStaticIntelSourceReference::vftable（RTTI 名） |
| 0x141C8A6A0 | （无名） 体设 CDiplomacyInviteFactionController::vftable（RTTI 名） |
| 0x141F7CE40 | CConfirmDisbandFleet::[0] vtable 槽 CConfirmDisbandFleet::[0]（func_names RTTI 名） |
| 0x1422F69D0 | CWindowType::[2] vtable 槽 CWindowType::[2]（func_names RTTI 名） |
| 0x14153E670 | CMatchmakingCallResult::[0] vtable 槽 CMatchmakingCallResult::[0]（func_names RTTI 名） |
| 0x141C8B300 | （无名） 体设 CDiplomacySendAttacheActionController::vftable（RTTI 名） |
| 0x141C94B80 | CDiplomacyBoostPartyPopularityController::[6] vtable 槽 CDiplomacyBoostPartyPopularityController::[6]（func_names RTTI 名） |
| 0x1422CDFD0 | （无名） 体设 CExcelParse::vftable（RTTI 名） |
| 0x1424BF100 | CWriter::[0] vtable 槽 CWriter::[0]（func_names RTTI 名） |
| 0x14150D4B0 | CArmyReinforcementRequests::[8] vtable 槽 CArmyReinforcementRequests::[8]（func_names RTTI 名） |
| 0x140F69DC0 | CBuildingProductionLine::[0] vtable 槽 CBuildingProductionLine::[0]（func_names RTTI 名） |
| 0x1415BB4F0 | CConfirmRemoveAllRegions::[0] vtable 槽 CConfirmRemoveAllRegions::[0]（func_names RTTI 名） |
| 0x141FF2630 | （无名） 体设 CMarketPanelController::vftable（RTTI 名） |
| 0x1406E91E0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1410FC770 | CAddWarGoalAction::[0] vtable 槽 CAddWarGoalAction::[0]（func_names RTTI 名） |
| 0x1423E1340 | CSteamMatchmakingContext::[12] vtable 槽 CSteamMatchmakingContext::[12]（func_names RTTI 名） |
| 0x14061F7F0 | CAchievement::[11] vtable 槽 CAchievement::[11]（func_names RTTI 名） |
| 0x1423C2C50 | CSteamBrowserInstance::[13] vtable 槽 CSteamBrowserInstance::[13]（func_names RTTI 名） |
| 0x141105950 | CCancelAccessToLicenseProductionAction::[56] vtable 槽 CCancelAccessToLicenseProductionAction::[56]（func_names RTTI 名） |
| 0x141A2DBC0 | CConfirmDeleteAllOrders::[0] vtable 槽 CConfirmDeleteAllOrders::[0]（func_names RTTI 名） |
| 0x141F6C350 | CConfirmDeleteEquipment::[0] vtable 槽 CConfirmDeleteEquipment::[0]（func_names RTTI 名） |
| 0x142306F60 | CButtonDrag::[85] vtable 槽 CButtonDrag::[85]（func_names RTTI 名） |
| 0x140681F30 | （无名） 体设 SLevelMax::vftable（RTTI 名） |
| 0x1406CF040 | CReducedFocusCost::[0] vtable 槽 CReducedFocusCost::[0]（func_names RTTI 名） |
| 0x140DD36C0 | CInGameIdler::[43] vtable 槽 CInGameIdler::[43]（func_names RTTI 名） |
| 0x1413FA1E0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141509660 | （无名） 体设 CGarrisonReinforcementRequests::vftable（RTTI 名） |
| 0x141A7AEA0 | CAIVolunteerGeneral::[19] vtable 槽 CAIVolunteerGeneral::[19]（func_names RTTI 名） |
| 0x1401A4C10 | CGameLevelAssetReloader::[1] vtable 槽 CGameLevelAssetReloader::[1]（func_names RTTI 名） |
| 0x140DC12E0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14167F290 | CRegionGraphics::[1] vtable 槽 CRegionGraphics::[1]（func_names RTTI 名） |
| 0x14194CC40 | CAIBaseGeneral::[22] vtable 槽 CAIBaseGeneral::[22]（func_names RTTI 名） |
| 0x141DE85F0 | CDarkFullscreenOverlay::[0] vtable 槽 CDarkFullscreenOverlay::[0]（func_names RTTI 名） |
| 0x1422DED90 | CGridBoxBase::[29] vtable 槽 CGridBoxBase::[29]（func_names RTTI 名） |
| 0x140DDA510 | CInGameIdler::[45] vtable 槽 CInGameIdler::[45]（func_names RTTI 名） |
| 0x14150E150 | CReinforcementStatus::[2] vtable 槽 CReinforcementStatus::[2]（func_names RTTI 名） |
| 0x141AA6B60 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14235FC20 | CProgressbarSpriteType::[16] vtable 槽 CProgressbarSpriteType::[16]（func_names RTTI 名） |
| 0x140A6EA10 | CAiTaskforceTemplate::[8] vtable 槽 CAiTaskforceTemplate::[8]（func_names RTTI 名） |
| 0x14194CCE0 | CAIBaseGeneral::[23] vtable 槽 CAIBaseGeneral::[23]（func_names RTTI 名） |
| 0x141F68120 | CTraitAssignmentConfirmation::[0] vtable 槽 CTraitAssignmentConfirmation::[0]（func_names RTTI 名） |
| 0x1422D75B0 | CPdx3DObject::[5] vtable 槽 CPdx3DObject::[5]（func_names RTTI 名） |
| 0x1414DF850 | CPersistedBookmarkPlaythroughDb::[5] vtable 槽 CPersistedBookmarkPlaythroughDb::[5]（func_names RTTI 名） |
| 0x1423563B0 | CAnimatedMapTextType::[13] vtable 槽 CAnimatedMapTextType::[13]（func_names RTTI 名） |
| 0x1422968C0 | CPdxParticleType::[13] vtable 槽 CPdxParticleType::[13]（func_names RTTI 名） |
| 0x1422E58F0 | CPersonalChatMessage::[10] vtable 槽 CPersonalChatMessage::[10]（func_names RTTI 名） |
| 0x1423568B0 | CArrowType::[13] vtable 槽 CArrowType::[13]（func_names RTTI 名） |
| 0x140DDFA00 | CInGameIdler::[60] vtable 槽 CInGameIdler::[60]（func_names RTTI 名） |
| 0x141F75230 | CConfirmRemoveBuildingLevel::[0] vtable 槽 CConfirmRemoveBuildingLevel::[0]（func_names RTTI 名） |
| 0x14225B770 | CGui::[16] vtable 槽 CGui::[16]（func_names RTTI 名） |
| 0x1422ADBC0 | CStandardlistbox::[36] vtable 槽 CStandardlistbox::[36]（func_names RTTI 名） |
| 0x1419CCAC0 | CTutorialHint::[2] vtable 槽 CTutorialHint::[2]（func_names RTTI 名） |
| 0x140FC10E0 | COperativeMission::[0] vtable 槽 COperativeMission::[0]（func_names RTTI 名） |
| 0x14015F180 | CAiFleetTemplate::[0] vtable 槽 CAiFleetTemplate::[0]（func_names RTTI 名） |
| 0x141139860 | CGenerateWarGoalAction::[57] vtable 槽 CGenerateWarGoalAction::[57]（func_names RTTI 名） |
| 0x142295EA0 | CCorneredTileSpriteType::[16] vtable 槽 CCorneredTileSpriteType::[16]（func_names RTTI 名） |
| 0x1423607B0 | CResizeableSpriteType::[16] vtable 槽 CResizeableSpriteType::[16]（func_names RTTI 名） |
| 0x141139710 | CCancelForeignManpowerAction::[57] vtable 槽 CCancelForeignManpowerAction::[57]（func_names RTTI 名） |
| 0x141B470B0 | CRandomAllConfirm::[16] vtable 槽 CRandomAllConfirm::[16]（func_names RTTI 名） |
| 0x140A66B80 | （无名） 体设 CMapModeDispatcher::vftable（RTTI 名） |
| 0x140E8C7A0 | CRailwayGun::[2] vtable 槽 CRailwayGun::[2]（func_names RTTI 名） |
| 0x1414FCD40 | CIncomingLendLeaseAction::[68] vtable 槽 CIncomingLendLeaseAction::[68]（func_names RTTI 名） |
| 0x14150D9A0 | CReinforcementRequest::[1] vtable 槽 CReinforcementRequest::[1]（func_names RTTI 名） |
| 0x1416468E0 | CAmbientObject::[1] vtable 槽 CAmbientObject::[1]（func_names RTTI 名） |
| 0x140BF1F70 | COrdersGroup::[12] vtable 槽 COrdersGroup::[12]（func_names RTTI 名） |
| 0x1414B4B80 | CProductionLine::[0] vtable 槽 CProductionLine::[0]（func_names RTTI 名） |
| 0x14232B8A0 | CCurveGraph::[29] vtable 槽 CCurveGraph::[29]（func_names RTTI 名） |
| 0x1423E1270 | CSteamMatchmakingContext::[45] vtable 槽 CSteamMatchmakingContext::[45]（func_names RTTI 名） |
| 0x141C93ED0 | CDiplomacyLendLeaseActionController::[11] vtable 槽 CDiplomacyLendLeaseActionController::[11]（func_names RTTI 名） |
| 0x1422ACE10 | CStandardlistbox::[16] vtable 槽 CStandardlistbox::[16]（func_names RTTI 名） |
| 0x1422CDFF0 | CExcelParse::[0] vtable 槽 CExcelParse::[0]（func_names RTTI 名） |
| 0x142301290 | CSmoothListbox::[16] vtable 槽 CSmoothListbox::[16]（func_names RTTI 名） |
| 0x141139790 | CCancelLicensedProductionAction::[57] vtable 槽 CCancelLicensedProductionAction::[57]（func_names RTTI 名） |
| 0x14153FD00 | CHistoryAddEffectCountry::[0] vtable 槽 CHistoryAddEffectCountry::[0]（func_names RTTI 名） |
| 0x1415BC980 | CConfirmRemoveAllRegions::[17] vtable 槽 CConfirmRemoveAllRegions::[17]（func_names RTTI 名） |
| 0x14232B8F0 | CCurveGraph::[6] vtable 槽 CCurveGraph::[6]（func_names RTTI 名） |
| 0x140E88B60 | CRailwayGun::[10] vtable 槽 CRailwayGun::[10]（func_names RTTI 名） |
| 0x1422D5980 | CTextSprite::[43] vtable 槽 CTextSprite::[43]（func_names RTTI 名） |
| 0x1401A8470 | CGameApplication::[18] vtable 槽 CGameApplication::[18]（func_names RTTI 名） |
| 0x141DF3A00 | CMapModeMilitaryDeploymentToOrder::[1] vtable 槽 CMapModeMilitaryDeploymentToOrder::[1]（func_names RTTI 名） |
| 0x1422CEB70 | CBrowser::[29] vtable 槽 CBrowser::[29]（func_names RTTI 名） |
| 0x1422CEE90 | CBrowser::[6] vtable 槽 CBrowser::[6]（func_names RTTI 名） |
| 0x1422D11D0 | CButtonStandard::[6] vtable 槽 CButtonStandard::[6]（func_names RTTI 名） |
| 0x1422D4E90 | CInstantSprite::[53] vtable 槽 CInstantSprite::[53]（func_names RTTI 名） |
| 0x1422FEA00 | CSprite::[53] vtable 槽 CSprite::[53]（func_names RTTI 名） |
| 0x140F6F490 | CNavalProductionLine::[23] vtable 槽 CNavalProductionLine::[23]（func_names RTTI 名） |
| 0x141E72740 | CNavyTheaterGroupItemBase::[20] vtable 槽 CNavyTheaterGroupItemBase::[20]（func_names RTTI 名） |
| 0x140CD7F50 | （无名） 体设 CManager::vftable（RTTI 名） |
| 0x1410DBBA0 | CBuilding::[7] vtable 槽 CBuilding::[7]（func_names RTTI 名） |
| 0x1415A0080 | CHistoryAddEffectState::[0] vtable 槽 CHistoryAddEffectState::[0]（func_names RTTI 名） |
| 0x140F70190 | CRailwayGunRepairLine::[23] vtable 槽 CRailwayGunRepairLine::[23]（func_names RTTI 名） |
| 0x1410ECBF0 | CCountryCharacters::[8] vtable 槽 CCountryCharacters::[8]（func_names RTTI 名） |
| 0x14143A7C0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1424B9080 | CTweakableFloat::[1] vtable 槽 CTweakableFloat::[1]（func_names RTTI 名） |
| 0x1403CB910 | CIntelLevelOver::[0] vtable 槽 CIntelLevelOver::[0]（func_names RTTI 名） |
| 0x142268330 | SpeechInput::[2] vtable 槽 SpeechInput::[2]（func_names RTTI 名） |
| 0x14230A1E0 | CPdxMeshType::[13] vtable 槽 CPdxMeshType::[13]（func_names RTTI 名） |
| 0x14237E440 | （无名） 体设 CFont::vftable（RTTI 名） |
| 0x1410D4470 | COperativesAiAssignmentTextLogger::[0] vtable 槽 COperativesAiAssignmentTextLogger::[0]（func_names RTTI 名） |
| 0x1422ED680 | COption::[5] vtable 槽 COption::[5]（func_names RTTI 名） |
| 0x140C01B20 | CUnit::[2] vtable 槽 CUnit::[2]（func_names RTTI 名） |
| 0x141F6B2B0 | CConfirmSwitchEquipment::[0] vtable 槽 CConfirmSwitchEquipment::[0]（func_names RTTI 名） |
| 0x1422682F0 | SpeechInput::[1] vtable 槽 SpeechInput::[1]（func_names RTTI 名） |
| 0x1422ED640 | COption::[4] vtable 槽 COption::[4]（func_names RTTI 名） |
| 0x140D25160 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422A90B0 | （无名） 体设 CException::vftable（RTTI 名） |
| 0x141518F40 | （无名） 体设 CLiberateCountryAction::vftable（RTTI 名） |
| 0x141C94C00 | CDiplomacyCountryGenerateWarGoalActionController::[6] vtable 槽 CDiplomacyCountryGenerateWarGoalActionController::[6]（func_names RTTI 名） |
| 0x142223360 | CFileLogger::[0] vtable 槽 CFileLogger::[0]（func_names RTTI 名） |
| 0x140D6EFB0 | CTaskForce::[28] vtable 槽 CTaskForce::[28]（func_names RTTI 名） |
| 0x14194CCA0 | CAIBaseGeneral::[20] vtable 槽 CAIBaseGeneral::[20]（func_names RTTI 名） |
| 0x1422FBE50 | （无名） 体设 CTextInputReceiver::vftable（RTTI 名） |
| 0x1402D7530 | CNationalFocusDatabase::[3] vtable 槽 CNationalFocusDatabase::[3]（func_names RTTI 名） |
| 0x1423AC3D0 | PdxSpeechToTextWinSAPI::[3] vtable 槽 PdxSpeechToTextWinSAPI::[3]（func_names RTTI 名） |
| 0x1423EA8D0 | CSteamNetContext::[9] vtable 槽 CSteamNetContext::[9]（func_names RTTI 名） |
| 0x141339690 | CChat::[1] vtable 槽 CChat::[1]（func_names RTTI 名） |
| 0x14153FF50 | CCountryStartingTruckChange::[17] vtable 槽 CCountryStartingTruckChange::[17]（func_names RTTI 名） |
| 0x141DF9890 | CStandardMusicPlayerController::[0] vtable 槽 CStandardMusicPlayerController::[0]（func_names RTTI 名） |
| 0x1422FE430 | CSprite::[34] vtable 槽 CSprite::[34]（func_names RTTI 名） |
| 0x142355D30 | CPdxSystem::[2] vtable 槽 CPdxSystem::[2]（func_names RTTI 名） |
| 0x14225B710 | CGui::[17] vtable 槽 CGui::[17]（func_names RTTI 名） |
| 0x140ACA200 | （无名） 体设 CFolderPosition::vftable（RTTI 名） |
| 0x1414844A0 | （无名） 体设 CException::vftable（RTTI 名） |
| 0x14194D850 | （无名） 体设 COperativeMissionData::vftable（RTTI 名） |
| 0x140C16CD0 | CArmyLeader::[14] vtable 槽 CArmyLeader::[14]（func_names RTTI 名） |
| 0x140D89150 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422760D0 | CPdxMeshObject::[8] vtable 槽 CPdxMeshObject::[8]（func_names RTTI 名） |
| 0x1414FCE90 | CLendLeaseAction::[24] vtable 槽 CLendLeaseAction::[24]（func_names RTTI 名） |
| 0x1422DF440 | CGridBoxBase::[68] vtable 槽 CGridBoxBase::[68]（func_names RTTI 名） |
| 0x1402B5A70 | nlohmann::detail::exception::[0] vtable 槽 nlohmann::detail::exception::[0]（func_names RTTI 名） |
| 0x140EE5BE0 | CTechnologySharingGroup::[8] vtable 槽 CTechnologySharingGroup::[8]（func_names RTTI 名） |
| 0x141B45320 | CRandomAllConfirm::[0] vtable 槽 CRandomAllConfirm::[0]（func_names RTTI 名） |
| 0x1422DF620 | CGridBoxBase::[69] vtable 槽 CGridBoxBase::[69]（func_names RTTI 名） |
| 0x14237C1A0 | CScrollbarType::[2] vtable 槽 CScrollbarType::[2]（func_names RTTI 名） |
| 0x141C99370 | CDiplomacyCallAllyActionController::[9] vtable 槽 CDiplomacyCallAllyActionController::[9]（func_names RTTI 名） |
| 0x141E4C9F0 | CPeaceBiddingQuickAccess::[1] vtable 槽 CPeaceBiddingQuickAccess::[1]（func_names RTTI 名） |
| 0x140DC7240 | CInGameIdler::[18] vtable 槽 CInGameIdler::[18]（func_names RTTI 名） |
| 0x141502E40 | CLendLeaseAction::[67] vtable 槽 CLendLeaseAction::[67]（func_names RTTI 名） |
| 0x141C99390 | CDiplomacyCountryAddWarGoalActionController::[9] vtable 槽 CDiplomacyCountryAddWarGoalActionController::[9]（func_names RTTI 名） |
| 0x142305E40 | CButtonDrag::[29] vtable 槽 CButtonDrag::[29]（func_names RTTI 名） |
| 0x1423E4D60 | CSteamMatchmakingContext::[43] vtable 槽 CSteamMatchmakingContext::[43]（func_names RTTI 名） |
| 0x140E8BFD0 | CRailwayGun::[23] vtable 槽 CRailwayGun::[23]（func_names RTTI 名） |
| 0x1411991D0 | （无名） 体设 CDiplomaticAction::vftable（RTTI 名） |
| 0x141337E10 | CChat::[6] vtable 槽 CChat::[6]（func_names RTTI 名） |
| 0x14153FEB0 | CCountryDecisionChange::[17] vtable 槽 CCountryDecisionChange::[17]（func_names RTTI 名） |
| 0x141DF9470 | CStandardMusicPlaylistController::[4] vtable 槽 CStandardMusicPlaylistController::[4]（func_names RTTI 名） |
| 0x1402238C0 | HOI4EditorInterface::[2] vtable 槽 HOI4EditorInterface::[2]（func_names RTTI 名） |
| 0x140223950 | HOI4EditorInterface::[3] vtable 槽 HOI4EditorInterface::[3]（func_names RTTI 名） |
| 0x140F6F5F0 | （无名） 体设 CRailwayGunProductionLine::vftable（RTTI 名） |
| 0x1422CF5D0 | CBrowser::[25] vtable 槽 CBrowser::[25]（func_names RTTI 名） |
| 0x1423E4D20 | CSteamMatchmakingContext::[4] vtable 槽 CSteamMatchmakingContext::[4]（func_names RTTI 名） |
| 0x1420B0FF0 | CTurnTableStrategy::[2] vtable 槽 CTurnTableStrategy::[2]（func_names RTTI 名） |
| 0x140AD6D90 | CTerrainDatabase::[3] vtable 槽 CTerrainDatabase::[3]（func_names RTTI 名） |
| 0x140CE4F10 | CNavalCombatResults::[8] vtable 槽 CNavalCombatResults::[8]（func_names RTTI 名） |
| 0x1422A2AA0 | CBitmapFont::[23] vtable 槽 CBitmapFont::[23]（func_names RTTI 名） |
| 0x1422D10F0 | CButtonStandard::[37] vtable 槽 CButtonStandard::[37]（func_names RTTI 名） |
| 0x142305C60 | （无名） 体设 CButtonDrag::vftable（RTTI 名） |
| 0x1401603F0 | CProgressSection::[0] vtable 槽 CProgressSection::[0]（func_names RTTI 名） |
| 0x141287190 | CPdxPostEffectHeightVolume::[1] vtable 槽 CPdxPostEffectHeightVolume::[1]（func_names RTTI 名） |
| 0x1419522C0 | （无名） 体设 CBoostIdeology::vftable（RTTI 名） |
| 0x1422E55B0 | （无名） 体设 CChatMessage::vftable（RTTI 名） |
| 0x140DE0390 | CInGameIdler::[27] vtable 槽 CInGameIdler::[27]（func_names RTTI 名） |
| 0x1411059A0 | CCancelForeignManpowerAction::[56] vtable 槽 CCancelForeignManpowerAction::[56]（func_names RTTI 名） |
| 0x141982240 | （无名） 体设 CFactionInfluenceRedistributer::vftable（RTTI 名） |
| 0x142255450 | HotkeyManager::[2] vtable 槽 HotkeyManager::[2]（func_names RTTI 名） |
| 0x1423BFFC0 | （无名） 体设 CAudioMusicInstance::vftable（RTTI 名） |
| 0x140ADA830 | CTimedActivityEquipmentDistributable::[1] vtable 槽 CTimedActivityEquipmentDistributable::[1]（func_names RTTI 名） |
| 0x140CE9E70 | CMilitaryDeployment::[4] vtable 槽 CMilitaryDeployment::[4]（func_names RTTI 名） |
| 0x140D0D3B0 | （无名） 体设 CRocketDeployment::vftable（RTTI 名） |
| 0x142356280 | C2dLineObject::[10] vtable 槽 C2dLineObject::[10]（func_names RTTI 名） |
| 0x142398C70 | CSteamAchievementsContext::[14] vtable 槽 CSteamAchievementsContext::[14]（func_names RTTI 名） |
| 0x142398CB0 | CSteamAchievementsContext::[13] vtable 槽 CSteamAchievementsContext::[13]（func_names RTTI 名） |
| 0x14196DC20 | CLendLeaseExchange::[8] vtable 槽 CLendLeaseExchange::[8]（func_names RTTI 名） |
| 0x141C94CA0 | CDiplomacyStandardController::[6] vtable 槽 CDiplomacyStandardController::[6]（func_names RTTI 名） |
| 0x14150C840 | CArmyReinforcementRequests::[4] vtable 槽 CArmyReinforcementRequests::[4]（func_names RTTI 名） |
| 0x14150C860 | CArmyUpgradesRequests::[4] vtable 槽 CArmyUpgradesRequests::[4]（func_names RTTI 名） |
| 0x141C99410 | CDiplomacyCountryGenerateWarGoalActionController::[9] vtable 槽 CDiplomacyCountryGenerateWarGoalActionController::[9]（func_names RTTI 名） |
| 0x140AABC80 | STriggerKeyPair::[0] vtable 槽 STriggerKeyPair::[0]（func_names RTTI 名） |
| 0x140EE5BB0 | CTechnologySharingGroup::[15] vtable 槽 CTechnologySharingGroup::[15]（func_names RTTI 名） |
| 0x1410FC540 | （无名） 体设 CDiplomaticAction::vftable（RTTI 名） |
| 0x1413EAE10 | （无名） 体设 CStateManpower::vftable（RTTI 名） |
| 0x14193E870 | CHqDeploymentDistributable::[3] vtable 槽 CHqDeploymentDistributable::[3]（func_names RTTI 名） |
| 0x1423C2D30 | CSteamBrowserContext::[1] vtable 槽 CSteamBrowserContext::[1]（func_names RTTI 名） |
| 0x1412E2CA0 | CCryptologyAI::[0] vtable 槽 CCryptologyAI::[0]（func_names RTTI 名） |
| 0x1422FD8B0 | CPositionType::[4] vtable 槽 CPositionType::[4]（func_names RTTI 名） |
| 0x141DCC100 | CEntitySprite::[1] vtable 槽 CEntitySprite::[1]（func_names RTTI 名） |
| 0x1423846A0 | CPdxKeyBoard::[6] vtable 槽 CPdxKeyBoard::[6]（func_names RTTI 名） |
| 0x1423846E0 | CPdxKeyBoard::[7] vtable 槽 CPdxKeyBoard::[7]（func_names RTTI 名） |
| 0x1423847A0 | CPdxKeyBoard::[8] vtable 槽 CPdxKeyBoard::[8]（func_names RTTI 名） |
| 0x142384810 | CPdxKeyBoard::[5] vtable 槽 CPdxKeyBoard::[5]（func_names RTTI 名） |
| 0x1422355B0 | （无名） 体设 C2dPositionObject::vftable（RTTI 名） |
| 0x1422DF410 | CGridBoxBase::[2] vtable 槽 CGridBoxBase::[2]（func_names RTTI 名） |
| 0x140CA6220 | CResourceExchange::[15] vtable 槽 CResourceExchange::[15]（func_names RTTI 名） |
| 0x140F70CF0 | CRailwayGunProductionLine::[29] vtable 槽 CRailwayGunProductionLine::[29]（func_names RTTI 名） |
| 0x141140380 | CTransferSpyMasterAction::[32] vtable 槽 CTransferSpyMasterAction::[32]（func_names RTTI 名） |
| 0x1422D1EF0 | CButtonStandard::[30] vtable 槽 CButtonStandard::[30]（func_names RTTI 名） |
| 0x1423077C0 | CButtonDrag::[30] vtable 槽 CButtonDrag::[30]（func_names RTTI 名） |
| 0x140D66340 | CTaskForce::[10] vtable 槽 CTaskForce::[10]（func_names RTTI 名） |
| 0x1422D1D80 | CButtonStandard::[2] vtable 槽 CButtonStandard::[2]（func_names RTTI 名） |
| 0x140C98720 | CEquipmentType::[3] vtable 槽 CEquipmentType::[3]（func_names RTTI 名） |
| 0x140D0D7C0 | CNavalDeployment::[0] vtable 槽 CNavalDeployment::[0]（func_names RTTI 名） |
| 0x14150C8C0 | CGarrisonReinforcementRequests::[4] vtable 槽 CGarrisonReinforcementRequests::[4]（func_names RTTI 名） |
| 0x1415A0CD0 | CControllerChange::[17] vtable 槽 CControllerChange::[17]（func_names RTTI 名） |
| 0x140149BB0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x140C0EA90 | CNavyLeader::[0] vtable 槽 CNavyLeader::[0]（func_names RTTI 名） |
| 0x1422D4D30 | CSprite::[66] vtable 槽 CSprite::[66]（func_names RTTI 名） |
| 0x1422D4E60 | CSprite::[3] vtable 槽 CSprite::[3]（func_names RTTI 名） |
| 0x140624C50 | CAgencyUpgrade::[8] vtable 槽 CAgencyUpgrade::[8]（func_names RTTI 名） |
| 0x140AB2EE0 | CScriptedDiplomaticAction::[23] vtable 槽 CScriptedDiplomaticAction::[23]（func_names RTTI 名） |
| 0x140BE9F30 | （无名） 体设 COrdersGroupMember::vftable（RTTI 名） |
| 0x14188D880 | CTheatreSelector::[9] vtable 槽 CTheatreSelector::[9]（func_names RTTI 名） |
| 0x141642200 | CMaskedSpriteType::[8] vtable 槽 CMaskedSpriteType::[8]（func_names RTTI 名） |
| 0x1422AD130 | CSmoothListbox::[26] vtable 槽 CSmoothListbox::[26]（func_names RTTI 名） |
| 0x14237A4F0 | CRadioButtonGroupType::[2] vtable 槽 CRadioButtonGroupType::[2]（func_names RTTI 名） |
| 0x142385D00 | CResizeableSprite::[10] vtable 槽 CResizeableSprite::[10]（func_names RTTI 名） |
| 0x1416FAF70 | CCountryMilitaryOverview::[6] vtable 槽 CCountryMilitaryOverview::[6]（func_names RTTI 名） |
| 0x1422D5BB0 | CTextSprite::[1] vtable 槽 CTextSprite::[1]（func_names RTTI 名） |
| 0x1424E0900 | CArchiveFile::[12] vtable 槽 CArchiveFile::[12]（func_names RTTI 名） |
| 0x1405516E0 | （无名） 体设 CMeanTimeToHappen::vftable（RTTI 名） |
| 0x140AD75F0 | （无名） 体设 CBaseTimedActivity::vftable（RTTI 名） |
| 0x140C596D0 | CCountryAirContainer::[8] vtable 槽 CCountryAirContainer::[8]（func_names RTTI 名） |
| 0x141338510 | CChat::[12] vtable 槽 CChat::[12]（func_names RTTI 名） |
| 0x141DF86A0 | CStandardMusicPlaybackController::[3] vtable 槽 CStandardMusicPlaybackController::[3]（func_names RTTI 名） |
| 0x141DF86C0 | CStandardMusicPlaybackController::[2] vtable 槽 CStandardMusicPlaybackController::[2]（func_names RTTI 名） |
| 0x1424DF7D0 | CArchiveFile::[0] vtable 槽 CArchiveFile::[0]（func_names RTTI 名） |
| 0x141B1FA00 | CMapSymbolDefinitionInstance::[1] vtable 槽 CMapSymbolDefinitionInstance::[1]（func_names RTTI 名） |
| 0x141C93F10 | CDiplomacyStandardController::[11] vtable 槽 CDiplomacyStandardController::[11]（func_names RTTI 名） |
| 0x141C99AC0 | CDiplomacyStandardController::[9] vtable 槽 CDiplomacyStandardController::[9]（func_names RTTI 名） |
| 0x141E8D1E0 | CTinyUnitCounter::[0] vtable 槽 CTinyUnitCounter::[0]（func_names RTTI 名） |
| 0x140F70B90 | CRailwayGunProductionLine::[23] vtable 槽 CRailwayGunProductionLine::[23]（func_names RTTI 名） |
| 0x141519270 | （无名） 体设 CTakeStateAction::vftable（RTTI 名） |
| 0x142293B90 | CPdxParticleObject::[0] vtable 槽 CPdxParticleObject::[0]（func_names RTTI 名） |
| 0x140CD9370 | SCombatDataPersistence::[0] vtable 槽 SCombatDataPersistence::[0]（func_names RTTI 名） |
| 0x140F6E770 | （无名） 体设 CMilitaryProductionLine::vftable（RTTI 名） |
| 0x141028290 | （无名） 体设 SOrderInstanceRef::vftable（RTTI 名） |
| 0x142397A40 | CAchievementsContext::[9] vtable 槽 CAchievementsContext::[9]（func_names RTTI 名） |
| 0x141A32670 | （无名） 体设 CCountryBased::vftable（RTTI 名） |
| 0x142255480 | HotkeyManager::[1] vtable 槽 HotkeyManager::[1]（func_names RTTI 名） |
| 0x140F6E730 | （无名） 体设 CMilitaryProductionLine::vftable（RTTI 名） |
| 0x1410FCBF0 | CStageCoupAction::[0] vtable 槽 CStageCoupAction::[0]（func_names RTTI 名） |
| 0x1422FFD80 | CSmoothListbox::[29] vtable 槽 CSmoothListbox::[29]（func_names RTTI 名） |
| 0x1407279E0 | CTimedDecision::[1] vtable 槽 CTimedDecision::[1]（func_names RTTI 名） |
| 0x140A91400 | （无名） 体设 SThreshold::vftable（RTTI 名） |
| 0x140F6E7C0 | CMilitaryProductionLine::[0] vtable 槽 CMilitaryProductionLine::[0]（func_names RTTI 名） |
| 0x14229C1A0 | CBitmapFont::[24] vtable 槽 CBitmapFont::[24]（func_names RTTI 名） |
| 0x140CF54C0 | COwnerArea::[1] vtable 槽 COwnerArea::[1]（func_names RTTI 名） |
| 0x1414B7DD0 | （无名） 体设 CConstructionSpeedFactor::vftable（RTTI 名） |
| 0x1415C4600 | CNavalCombat::[21] vtable 槽 CNavalCombat::[21]（func_names RTTI 名） |
| 0x1422A9AF0 | CStandardlistbox::[0] vtable 槽 CStandardlistbox::[0]（func_names RTTI 名） |
| 0x1422D1550 | CButtonStandard::[33] vtable 槽 CButtonStandard::[33]（func_names RTTI 名） |
| 0x1422D15B0 | CButtonStandard::[32] vtable 槽 CButtonStandard::[32]（func_names RTTI 名） |
| 0x1422F51B0 | SpeechInputTextboxHandler::[1] vtable 槽 SpeechInputTextboxHandler::[1]（func_names RTTI 名） |
| 0x140B970F0 | CReferencedDivisionTemplate::[0] vtable 槽 CReferencedDivisionTemplate::[0]（func_names RTTI 名） |
| 0x1422D1E70 | CButtonStandard::[38] vtable 槽 CButtonStandard::[38]（func_names RTTI 名） |
| 0x140D44FE0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140F09720 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422ED270 | CInstantTextObject::[40] vtable 槽 CInstantTextObject::[40]（func_names RTTI 名） |
| 0x140639C20 | CRule::[9] vtable 槽 CRule::[9]（func_names RTTI 名） |
| 0x140D2CE80 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1419D7EF0 | CDebugMapModeConfig::CFloatToHsv::[3] vtable 槽 CDebugMapModeConfig::CFloatToHsv::[3]（func_names RTTI 名） |
| 0x1420AD420 | CMapIdler::[1] vtable 槽 CMapIdler::[1]（func_names RTTI 名） |
| 0x1420AD440 | CMapIdler::[2] vtable 槽 CMapIdler::[2]（func_names RTTI 名） |
| 0x142403180 | CSteamUGCContext::[13] vtable 槽 CSteamUGCContext::[13]（func_names RTTI 名） |
| 0x1402CCEA0 | CJointNationalFocus::[0] vtable 槽 CJointNationalFocus::[0]（func_names RTTI 名） |
| 0x140BFD6A0 | CUnit::[6] vtable 槽 CUnit::[6]（func_names RTTI 名） |
| 0x140D66310 | CTaskForce::[11] vtable 槽 CTaskForce::[11]（func_names RTTI 名） |
| 0x1419D7D40 | CDebugMapModeConfig::CNormalizer::[3] vtable 槽 CDebugMapModeConfig::CNormalizer::[3]（func_names RTTI 名） |
| 0x1422305D0 | CKeyBoard::[0] vtable 槽 CKeyBoard::[0]（func_names RTTI 名） |
| 0x142230630 | CPdxKeyBoard::[0] vtable 槽 CPdxKeyBoard::[0]（func_names RTTI 名） |
| 0x1423574F0 | （无名） 体设 CFrameAnimatedSpriteType::vftable（RTTI 名） |
| 0x1422AAC40 | CStandardlistbox::[6] vtable 槽 CStandardlistbox::[6]（func_names RTTI 名） |
| 0x1422AD110 | CStandardlistbox::[26] vtable 槽 CStandardlistbox::[26]（func_names RTTI 名） |
| 0x1422DEE70 | CGridBoxBase::[6] vtable 槽 CGridBoxBase::[6]（func_names RTTI 名） |
| 0x1423002B0 | CSmoothListbox::[6] vtable 槽 CSmoothListbox::[6]（func_names RTTI 名） |
| 0x140C16D10 | CNavyLeader::[14] vtable 槽 CNavyLeader::[14]（func_names RTTI 名） |
| 0x140DD3A30 | CInGameIdler::[92] vtable 槽 CInGameIdler::[92]（func_names RTTI 名） |
| 0x1413EBA70 | CLandBorderWarCombat::[0] vtable 槽 CLandBorderWarCombat::[0]（func_names RTTI 名） |
| 0x1403CC900 | CNumCompletedOperations::[0] vtable 槽 CNumCompletedOperations::[0]（func_names RTTI 名） |
| 0x1410D8F60 | COperativesAiLoggerWrapper::[4] vtable 槽 COperativesAiLoggerWrapper::[4]（func_names RTTI 名） |
| 0x1410D9670 | COperativesAiLoggerWrapper::[3] vtable 槽 COperativesAiLoggerWrapper::[3]（func_names RTTI 名） |
| 0x1410D9810 | COperativesAiLoggerWrapper::[2] vtable 槽 COperativesAiLoggerWrapper::[2]（func_names RTTI 名） |
| 0x141C2FAF0 | CChangeDesignFolderPopUp::[16] vtable 槽 CChangeDesignFolderPopUp::[16]（func_names RTTI 名） |
| 0x141C95240 | CDiplomacyRequestExpeditionaryForcesController::[17] vtable 槽 CDiplomacyRequestExpeditionaryForcesController::[17]（func_names RTTI 名） |
| 0x1422DF200 | CGridBoxBase::[43] vtable 槽 CGridBoxBase::[43]（func_names RTTI 名） |
| 0x1422E5410 | （无名） 体设 CChatMessage::vftable（RTTI 名） |
| 0x142355CE0 | CPdxSystem::[1] vtable 槽 CPdxSystem::[1]（func_names RTTI 名） |
| 0x142360E60 | CTextSpriteType::[10] vtable 槽 CTextSpriteType::[10]（func_names RTTI 名） |
| 0x140332720 | CRandomScopeInArray::[0] vtable 槽 CRandomScopeInArray::[0]（func_names RTTI 名） |
| 0x1410D9060 | COperativesAiLoggerWrapper::[1] vtable 槽 COperativesAiLoggerWrapper::[1]（func_names RTTI 名） |
| 0x14139A580 | CRandomListEffectMember::[3] vtable 槽 CRandomListEffectMember::[3]（func_names RTTI 名） |
| 0x1422D1E40 | CButtonStandard::[105] vtable 槽 CButtonStandard::[105]（func_names RTTI 名） |
| 0x1424B90D0 | CTweakableInt::[1] vtable 槽 CTweakableInt::[1]（func_names RTTI 名） |
| 0x140AD78A0 | CTimedEffectActivity::[0] vtable 槽 CTimedEffectActivity::[0]（func_names RTTI 名） |
| 0x14153FF20 | CCountryStartingTrainChange::[17] vtable 槽 CCountryStartingTrainChange::[17]（func_names RTTI 名） |
| 0x142250130 | CSession::[7] vtable 槽 CSession::[7]（func_names RTTI 名） |
| 0x1403030B0 | CEmbargoAction::[0] vtable 槽 CEmbargoAction::[0]（func_names RTTI 名） |
| 0x1403031B0 | CScriptedDiplomaticAction::[0] vtable 槽 CScriptedDiplomaticAction::[0]（func_names RTTI 名） |
| 0x1410FC8A0 | CDeclareWarAction::[0] vtable 槽 CDeclareWarAction::[0]（func_names RTTI 名） |
| 0x141F6D1C0 | CProductionSubUnitDefFilter::[0] vtable 槽 CProductionSubUnitDefFilter::[0]（func_names RTTI 名） |
| 0x140DC69E0 | CInGameIdler::[115] vtable 槽 CInGameIdler::[115]（func_names RTTI 名） |
| 0x14113D2A0 | CRequestForeignManpowerAction::[28] vtable 槽 CRequestForeignManpowerAction::[28]（func_names RTTI 名） |
| 0x141180490 | CEvent::[3] vtable 槽 CEvent::[3]（func_names RTTI 名） |
| 0x1416403D0 | CMapIconGroup::[1] vtable 槽 CMapIconGroup::[1]（func_names RTTI 名） |
| 0x1422AED70 | CSprite::[38] vtable 槽 CSprite::[38]（func_names RTTI 名） |
| 0x14235BD60 | SGfxSamplerReader::[3] vtable 槽 SGfxSamplerReader::[3]（func_names RTTI 名） |
| 0x1422ED550 | CInstantTextObject::[52] vtable 槽 CInstantTextObject::[52]（func_names RTTI 名） |
| 0x142356360 | CAnimatedMapTextType::[0] vtable 槽 CAnimatedMapTextType::[0]（func_names RTTI 名） |
| 0x141E33D80 | CMapModeOperationSelectTarget::[10] vtable 槽 CMapModeOperationSelectTarget::[10]（func_names RTTI 名） |
| 0x141E33DA0 | CMapModeOperationSelectTarget::[11] vtable 槽 CMapModeOperationSelectTarget::[11]（func_names RTTI 名） |
| 0x141A31390 | （无名） 体设 CStateBased::vftable（RTTI 名） |
| 0x1422CD140 | CDebugLineHelper::[1] vtable 槽 CDebugLineHelper::[1]（func_names RTTI 名） |
| 0x14186CB60 | CPlayerLobby::CChatItem::[0] vtable 槽 CPlayerLobby::CChatItem::[0]（func_names RTTI 名） |
| 0x1422E4D60 | CBitmap::[4] vtable 槽 CBitmap::[4]（func_names RTTI 名） |
| 0x1422FDAC0 | C2dObject::[15] vtable 槽 C2dObject::[15]（func_names RTTI 名） |
| 0x140B3BDD0 | CInGameIdler::[70] vtable 槽 CInGameIdler::[70]（func_names RTTI 名） |
| 0x1412B9410 | CLandCombatant::[18] vtable 槽 CLandCombatant::[18]（func_names RTTI 名） |
| 0x1424E05D0 | CArchiveFile::[2] vtable 槽 CArchiveFile::[2]（func_names RTTI 名） |
| 0x141509CD0 | CArmyRequests::[0] vtable 槽 CArmyRequests::[0]（func_names RTTI 名） |
| 0x1412AAA50 | CLandCombat::[0] vtable 槽 CLandCombat::[0]（func_names RTTI 名） |
| 0x1422AA2B0 | CStandardlistbox::[29] vtable 槽 CStandardlistbox::[29]（func_names RTTI 名） |
| 0x1422DEC80 | （无名） 体设 CGridBoxBase::vftable（RTTI 名） |
| 0x14237F180 | CTrack::[29] vtable 槽 CTrack::[29]（func_names RTTI 名） |
| 0x140C0EA40 | CArmyLeader::[0] vtable 槽 CArmyLeader::[0]（func_names RTTI 名） |
| 0x140D74A00 | CTaskForce::[3] vtable 槽 CTaskForce::[3]（func_names RTTI 名） |
| 0x141C2FB40 | CCreateFolderPopUp::[16] vtable 槽 CCreateFolderPopUp::[16]（func_names RTTI 名） |
| 0x142379570 | CNullButtonDrag::[7] vtable 槽 CNullButtonDrag::[7]（func_names RTTI 名） |
| 0x141DF9850 | （无名） 体设 CStandardMusicPlayerController::vftable（RTTI 名） |
| 0x14224BE90 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x142355EC0 | CPdxSystem::[7] vtable 槽 CPdxSystem::[7]（func_names RTTI 名） |
| 0x1423575D0 | CFrameAnimatedSpriteType::[8] vtable 槽 CFrameAnimatedSpriteType::[8]（func_names RTTI 名） |
| 0x1415C4550 | CNavalCombat::[20] vtable 槽 CNavalCombat::[20]（func_names RTTI 名） |
| 0x1415C45A0 | CNavalCombat::[19] vtable 槽 CNavalCombat::[19]（func_names RTTI 名） |
| 0x1415C4650 | CNavalCombat::[22] vtable 槽 CNavalCombat::[22]（func_names RTTI 名） |
| 0x141956F10 | （无名） 体设 CCounterIntelligence::vftable（RTTI 名） |
| 0x1401C9670 | CIdCounterStore::[0] vtable 槽 CIdCounterStore::[0]（func_names RTTI 名） |
| 0x140A0B120 | CEquipmentGroupDatabase::[0] vtable 槽 CEquipmentGroupDatabase::[0]（func_names RTTI 名） |
| 0x140BEF620 | COrdersGroup::[11] vtable 槽 COrdersGroup::[11]（func_names RTTI 名） |
| 0x141401850 | COperationInstance::[4] vtable 槽 COperationInstance::[4]（func_names RTTI 名） |
| 0x14193E960 | CHqDeploymentDistributable::[4] vtable 槽 CHqDeploymentDistributable::[4]（func_names RTTI 名） |
| 0x141E33E40 | CMapModeOperationSelectTarget::[4] vtable 槽 CMapModeOperationSelectTarget::[4]（func_names RTTI 名） |
| 0x1423B9980 | CAudioMusicInstanceSDL::[0] vtable 槽 CAudioMusicInstanceSDL::[0]（func_names RTTI 名） |
| 0x140ADA4B0 | CTimedActivityEquipmentDistributable::[8] vtable 槽 CTimedActivityEquipmentDistributable::[8]（func_names RTTI 名） |
| 0x140D23120 | CBoostPartyPopularityRelation::[18] vtable 槽 CBoostPartyPopularityRelation::[18]（func_names RTTI 名） |
| 0x1413384E0 | CChat::[14] vtable 槽 CChat::[14]（func_names RTTI 名） |
| 0x141642C40 | CShieldObject::[74] vtable 槽 CShieldObject::[74]（func_names RTTI 名） |
| 0x141954100 | （无名） 体设 CBuildIntelNetwork::vftable（RTTI 名） |
| 0x1423E1140 | CSteamMatchmakingContext::[42] vtable 槽 CSteamMatchmakingContext::[42]（func_names RTTI 名） |
| 0x140E9EF20 | CNavalBase::[0] vtable 槽 CNavalBase::[0]（func_names RTTI 名） |
| 0x14153E650 | CMatchmakingCallResult::[1] vtable 槽 CMatchmakingCallResult::[1]（func_names RTTI 名） |
| 0x141C8C140 | CDiplomacyCountryGenerateWarGoalActionController::[1] vtable 槽 CDiplomacyCountryGenerateWarGoalActionController::[1]（func_names RTTI 名） |
| 0x1422E4640 | （无名） 体设 CBitmap::vftable（RTTI 名） |
| 0x1423612C0 | C2dPieChartType::[0] vtable 槽 C2dPieChartType::[0]（func_names RTTI 名） |
| 0x1423E8940 | CSteamNetContext::[20] vtable 槽 CSteamNetContext::[20]（func_names RTTI 名） |
| 0x142403FC0 | CSteamUGCContext::[16] vtable 槽 CSteamUGCContext::[16]（func_names RTTI 名） |
| 0x142404000 | CSteamUGCContext::[17] vtable 槽 CSteamUGCContext::[17]（func_names RTTI 名） |
| 0x142404040 | CSteamUGCContext::[18] vtable 槽 CSteamUGCContext::[18]（func_names RTTI 名） |
| 0x140B09710 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140D3D600 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1411A0E80 | CCountryOperationManager::[8] vtable 槽 CCountryOperationManager::[8]（func_names RTTI 名） |
| 0x14196C2D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422CDBC0 | CRemoteFile::[9] vtable 槽 CRemoteFile::[9]（func_names RTTI 名） |
| 0x142307E30 | CLineChart::[15] vtable 槽 CLineChart::[15]（func_names RTTI 名） |
| 0x140D230F0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140DDA5A0 | CInGameIdler::[2] vtable 槽 CInGameIdler::[2]（func_names RTTI 名） |
| 0x14113A300 | CRequestForeignManpowerAction::[57] vtable 槽 CRequestForeignManpowerAction::[57]（func_names RTTI 名） |
| 0x141A32690 | （无名） 体设 CCountryBased::vftable（RTTI 名） |
| 0x142306AB0 | CButtonDrag::[14] vtable 槽 CButtonDrag::[14]（func_names RTTI 名） |
| 0x140D0D390 | （无名） 体设 CRocketDeployment::vftable（RTTI 名） |
| 0x1410D3F60 | （无名） 体设 COperativesAiAssignmentTextLogger::vftable（RTTI 名） |
| 0x142068E30 | （无名） 体设 CCheckBoxObserver::vftable（RTTI 名） |
| 0x142403FA0 | CSteamUGCContext::[21] vtable 槽 CSteamUGCContext::[21]（func_names RTTI 名） |
| 0x142403FE0 | CSteamUGCContext::[19] vtable 槽 CSteamUGCContext::[19]（func_names RTTI 名） |
| 0x142404020 | CSteamUGCContext::[20] vtable 槽 CSteamUGCContext::[20]（func_names RTTI 名） |
| 0x1414FBBC0 | CLendLeaseBaseAction::[0] vtable 槽 CLendLeaseBaseAction::[0]（func_names RTTI 名） |
| 0x141955B90 | （无名） 体设 CControlTrade::vftable（RTTI 名） |
| 0x140CD86D0 | （无名） 体设 CLoss::vftable（RTTI 名） |
| 0x141B52220 | CDBNudger::[4] vtable 槽 CDBNudger::[4]（func_names RTTI 名） |
| 0x141C8C000 | CDiplomacyCountryAddWarGoalActionController::[1] vtable 槽 CDiplomacyCountryAddWarGoalActionController::[1]（func_names RTTI 名） |
| 0x1423795C0 | CNullButtonStandard::[7] vtable 槽 CNullButtonStandard::[7]（func_names RTTI 名） |
| 0x142384620 | CPdxMouse::[22] vtable 槽 CPdxMouse::[22]（func_names RTTI 名） |
| 0x1424DF8F0 | CArchiveFile::[13] vtable 槽 CArchiveFile::[13]（func_names RTTI 名） |
| 0x1419DEC00 | （无名） 体设 CPropaganda::vftable（RTTI 名） |
| 0x1401C9780 | CScriptedMapEntityManager::[0] vtable 槽 CScriptedMapEntityManager::[0]（func_names RTTI 名） |
| 0x1422CF190 | CBrowser::[77] vtable 槽 CBrowser::[77]（func_names RTTI 名） |
| 0x1423B98C0 | CAudioCategorySDL::[0] vtable 槽 CAudioCategorySDL::[0]（func_names RTTI 名） |
| 0x1406BDAB0 | CNullCombatTactic::[0] vtable 槽 CNullCombatTactic::[0]（func_names RTTI 名） |
| 0x141C2FFF0 | CSaveDesignToFilePopUp::[17] vtable 槽 CSaveDesignToFilePopUp::[17]（func_names RTTI 名） |
| 0x142401100 | PdxSocialPermissions::ChatBooleanPermission::[2] vtable 槽 PdxSocialPermissions::ChatBooleanPermission::[2]（func_names RTTI 名） |
| 0x140147220 | （无名） 体设 CDatabaseObject::vftable（RTTI 名） |
| 0x140C0D160 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x141C8C680 | CDiplomacyRequestExpeditionaryForcesController::[1] vtable 槽 CDiplomacyRequestExpeditionaryForcesController::[1]（func_names RTTI 名） |
| 0x142365AD0 | CNetworkServer::[22] vtable 槽 CNetworkServer::[22]（func_names RTTI 名） |
| 0x142384E00 | CPdxMouse::[13] vtable 槽 CPdxMouse::[13]（func_names RTTI 名） |
| 0x140A909B0 | （无名） 体设 SThreshold::vftable（RTTI 名） |
| 0x140BF9E90 | CUnit::[49] vtable 槽 CUnit::[49]（func_names RTTI 名） |
| 0x1411059D0 | CCancelLicensedProductionAction::[56] vtable 槽 CCancelLicensedProductionAction::[56]（func_names RTTI 名） |
| 0x141C89DC0 | （无名） 体设 CDiplomacyCountryGenerateWarGoalActionController::vftable（RTTI 名） |
| 0x1422E0440 | CSendChunk::[0] vtable 槽 CSendChunk::[0]（func_names RTTI 名） |
| 0x142384D80 | CPdxMouse::[20] vtable 槽 CPdxMouse::[20]（func_names RTTI 名） |
| 0x140645FB0 | CAIEquipmentMarketBuyStrategyData::[0] vtable 槽 CAIEquipmentMarketBuyStrategyData::[0]（func_names RTTI 名） |
| 0x140CBF570 | （无名） 体设 CScriptFlag::vftable（RTTI 名） |
| 0x14153FE40 | CCountryCapitalChange::[17] vtable 槽 CCountryCapitalChange::[17]（func_names RTTI 名） |
| 0x141B59AA0 | CStateNudger::[4] vtable 槽 CStateNudger::[4]（func_names RTTI 名） |
| 0x141B62BA0 | CStrategicRegionNudger::[4] vtable 槽 CStrategicRegionNudger::[4]（func_names RTTI 名） |
| 0x141C2FF70 | CChangeDesignFolderPopUp::[15] vtable 槽 CChangeDesignFolderPopUp::[15]（func_names RTTI 名） |
| 0x140B64460 | CNavalMissionExtension::[0] vtable 槽 CNavalMissionExtension::[0]（func_names RTTI 名） |
| 0x140D99120 | CLargefileHandlerInterface::[0] vtable 槽 CLargefileHandlerInterface::[0]（func_names RTTI 名） |
| 0x1413EBB50 | CLandBorderWarCombat::[26] vtable 槽 CLandBorderWarCombat::[26]（func_names RTTI 名） |
| 0x14229B630 | CBitmapFont::[22] vtable 槽 CBitmapFont::[22]（func_names RTTI 名） |
| 0x1422E7F60 | CChatMessageObservable::[0] vtable 槽 CChatMessageObservable::[0]（func_names RTTI 名） |
| 0x1422ED570 | CInstantTextObject::[48] vtable 槽 CInstantTextObject::[48]（func_names RTTI 名） |
| 0x142355EE0 | （无名） 体设 C2dCollisionObject::vftable（RTTI 名） |
| 0x142379520 | CNullBrowser::[7] vtable 槽 CNullBrowser::[7]（func_names RTTI 名） |
| 0x14030A8F0 | CCancelBorderWar::[0] vtable 槽 CCancelBorderWar::[0]（func_names RTTI 名） |
| 0x1403CB830 | CMTTHModifier::[0] vtable 槽 CMTTHModifier::[0]（func_names RTTI 名） |
| 0x1403CC680 | CIsRunningOperation::[0] vtable 槽 CIsRunningOperation::[0]（func_names RTTI 名） |
| 0x14153FE70 | CCountryConvoysChange::[17] vtable 槽 CCountryConvoysChange::[17]（func_names RTTI 名） |
| 0x1402239B0 | HOI4EditorInterface::[5] vtable 槽 HOI4EditorInterface::[5]（func_names RTTI 名） |
| 0x140BCB680 | CStrategicResource::[0] vtable 槽 CStrategicResource::[0]（func_names RTTI 名） |
| 0x14153FBE0 | CCountryNukesChange::[0] vtable 槽 CCountryNukesChange::[0]（func_names RTTI 名） |
| 0x142293BF0 | CPdxParticleObject::[8] vtable 槽 CPdxParticleObject::[8]（func_names RTTI 名） |
| 0x1422AD010 | CStandardlistbox::[33] vtable 槽 CStandardlistbox::[33]（func_names RTTI 名） |
| 0x142379980 | CNullTrack::[7] vtable 槽 CNullTrack::[7]（func_names RTTI 名） |
| 0x140223590 | （无名） 体设 HOI4EditorInterface::vftable（RTTI 名） |
| 0x1411078A0 | CIncreaseAutonomyAction::[56] vtable 槽 CIncreaseAutonomyAction::[56]（func_names RTTI 名） |
| 0x141108DC0 | CReduceAutonomyAction::[56] vtable 槽 CReduceAutonomyAction::[56]（func_names RTTI 名） |
| 0x1413E27C0 | CCombatant::[25] vtable 槽 CCombatant::[25]（func_names RTTI 名） |
| 0x1402E3C90 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x140F6A510 | CBuildingProductionLine::[27] vtable 槽 CBuildingProductionLine::[27]（func_names RTTI 名） |
| 0x14136E450 | CManpowerLogger::[9] vtable 槽 CManpowerLogger::[9]（func_names RTTI 名） |
| 0x1414FCDA0 | CLendLeaseAction::[68] vtable 槽 CLendLeaseAction::[68]（func_names RTTI 名） |
| 0x141C94BD0 | CDiplomacyCountryAddWarGoalActionController::[6] vtable 槽 CDiplomacyCountryAddWarGoalActionController::[6]（func_names RTTI 名） |
| 0x1403A21D0 | CTransferShip::[25] vtable 槽 CTransferShip::[25]（func_names RTTI 名） |
| 0x141EC38E0 | （无名） 体设 CIntelLedgerHeaderController::vftable（RTTI 名） |
| 0x142241110 | CSpriteType::[23] vtable 槽 CSpriteType::[23]（func_names RTTI 名） |
| 0x1422AF3C0 | CButtonObservable::[0] vtable 槽 CButtonObservable::[0]（func_names RTTI 名） |
| 0x140A3BF50 | CNullGraphicalCultureType::[0] vtable 槽 CNullGraphicalCultureType::[0]（func_names RTTI 名） |
| 0x141925820 | CPersistedMioQueueDb::[1] vtable 槽 CPersistedMioQueueDb::[1]（func_names RTTI 名） |
| 0x140C06520 | CUnit::[26] vtable 槽 CUnit::[26]（func_names RTTI 名） |
| 0x14112DB70 | CDeclareWarAction::[23] vtable 槽 CDeclareWarAction::[23]（func_names RTTI 名） |
| 0x142058A00 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x142357530 | CFrameAnimatedSpriteType::[0] vtable 槽 CFrameAnimatedSpriteType::[0]（func_names RTTI 名） |
| 0x142396DD0 | CPdxCrashReportWindows::[3] vtable 槽 CPdxCrashReportWindows::[3]（func_names RTTI 名） |
| 0x140CD7F10 | （无名） 体设 CManager::vftable（RTTI 名） |
| 0x14101CC50 | CSubUnitDefinition::[3] vtable 槽 CSubUnitDefinition::[3]（func_names RTTI 名） |
| 0x1412B8FB0 | CLandCombat::[8] vtable 槽 CLandCombat::[8]（func_names RTTI 名） |
| 0x141EA5A20 | （无名） 体设 CIntelLedgerPanelController::vftable（RTTI 名） |
| 0x142079C10 | CDLCDescriptor::[8] vtable 槽 CDLCDescriptor::[8]（func_names RTTI 名） |
| 0x1422D1F20 | CButtonStandard::[101] vtable 槽 CButtonStandard::[101]（func_names RTTI 名） |
| 0x1406253D0 | CAgencyUpgrade::[3] vtable 槽 CAgencyUpgrade::[3]（func_names RTTI 名） |
| 0x1424E0930 | CArchiveFile::[11] vtable 槽 CArchiveFile::[11]（func_names RTTI 名） |
| 0x14030A5C0 | CAddDemilitarizedZone::[0] vtable 槽 CAddDemilitarizedZone::[0]（func_names RTTI 名） |
| 0x1412362E0 | CInGameUpdateableInterface::[0] vtable 槽 CInGameUpdateableInterface::[0]（func_names RTTI 名） |
| 0x1412D9250 | CGfxTradeRouteConvoy::[0] vtable 槽 CGfxTradeRouteConvoy::[0]（func_names RTTI 名） |
| 0x141870140 | CPlayerLobby::[1] vtable 槽 CPlayerLobby::[1]（func_names RTTI 名） |
| 0x141C2FFB0 | CSaveDesignToFilePopUp::[15] vtable 槽 CSaveDesignToFilePopUp::[15]（func_names RTTI 名） |
| 0x1424EE580 | CRemoteFile::[11] vtable 槽 CRemoteFile::[11]（func_names RTTI 名） |
| 0x1402236B0 | （无名） 体设 HOI4EditorInterface::vftable（RTTI 名） |
| 0x1422D4D60 | CInstantSprite::[45] vtable 槽 CInstantSprite::[45]（func_names RTTI 名） |
| 0x14134B400 | CRestructureShipsToTaskforceCompositions::[0] vtable 槽 CRestructureShipsToTaskforceCompositions::[0]（func_names RTTI 名） |
| 0x141C898E0 | （无名） 体设 CDiplomacyCountryAddWarGoalActionController::vftable（RTTI 名） |
| 0x1422AFA50 | CTrack::[82] vtable 槽 CTrack::[82]（func_names RTTI 名） |
| 0x140DF8450 | CSeasonType::[0] vtable 槽 CSeasonType::[0]（func_names RTTI 名） |
| 0x140DF84F0 | CTreeSeasonType::[0] vtable 槽 CTreeSeasonType::[0]（func_names RTTI 名） |
| 0x141401900 | CAirGroup::[8] vtable 槽 CAirGroup::[8]（func_names RTTI 名） |
| 0x1415A0040 | COwnerChange::[0] vtable 槽 COwnerChange::[0]（func_names RTTI 名） |
| 0x1415A42C0 | CWeatherChancePeriod::[0] vtable 槽 CWeatherChancePeriod::[0]（func_names RTTI 名） |
| 0x1422D1EA0 | CButtonStandard::[39] vtable 槽 CButtonStandard::[39]（func_names RTTI 名） |
| 0x142307740 | CButtonDrag::[39] vtable 槽 CButtonDrag::[39]（func_names RTTI 名） |
| 0x140BBD500 | CIdCounterStore::[4] vtable 槽 CIdCounterStore::[4]（func_names RTTI 名） |
| 0x141515F70 | SInvasionReport::[0] vtable 槽 SInvasionReport::[0]（func_names RTTI 名） |
| 0x141981720 | CDockingRightsRelation::[0] vtable 槽 CDockingRightsRelation::[0]（func_names RTTI 名） |
| 0x14222BD30 | CApplicationObservable::[0] vtable 槽 CApplicationObservable::[0]（func_names RTTI 名） |
| 0x1422A9A80 | COptionObservable::[0] vtable 槽 COptionObservable::[0]（func_names RTTI 名） |
| 0x1422E4690 | CBitmap::[0] vtable 槽 CBitmap::[0]（func_names RTTI 名） |
| 0x1424EE5A0 | CRemoteFile::[10] vtable 槽 CRemoteFile::[10]（func_names RTTI 名） |
| 0x140BF9450 | CUnit::[0] vtable 槽 CUnit::[0]（func_names RTTI 名） |
| 0x140CA6040 | CConvoyClient::[0] vtable 槽 CConvoyClient::[0]（func_names RTTI 名） |
| 0x1412B8FE0 | CLandCombatant::[8] vtable 槽 CLandCombatant::[8]（func_names RTTI 名） |
| 0x141509C90 | CArmyReinforcementRequests::[0] vtable 槽 CArmyReinforcementRequests::[0]（func_names RTTI 名） |
| 0x1401CA1B0 | CGameState::[0] vtable 槽 CGameState::[0]（func_names RTTI 名） |
| 0x14113F6D0 | CGenerateWarGoalAction::[45] vtable 槽 CGenerateWarGoalAction::[45]（func_names RTTI 名） |
| 0x14153FCC0 | CCountryHistory::[0] vtable 槽 CCountryHistory::[0]（func_names RTTI 名） |
| 0x14153FE00 | CRevolutionaryTagChange::[0] vtable 槽 CRevolutionaryTagChange::[0]（func_names RTTI 名） |
| 0x14237E2E0 | CPdxDummy3DType::[0] vtable 槽 CPdxDummy3DType::[0]（func_names RTTI 名） |
| 0x1423E8860 | CSteamNetContext::[16] vtable 槽 CSteamNetContext::[16]（func_names RTTI 名） |
| 0x1424DF870 | CVirtualLogFile::[0] vtable 槽 CVirtualLogFile::[0]（func_names RTTI 名） |
| 0x140B8FA00 | CPersistedMioQueueDb::[0] vtable 槽 CPersistedMioQueueDb::[0]（func_names RTTI 名） |
| 0x1412353F0 | CUnitMoveAction::[11] vtable 槽 CUnitMoveAction::[11]（func_names RTTI 名） |
| 0x141BCE050 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140613F00 | CAbility::[1] vtable 槽 CAbility::[1]（func_names RTTI 名） |
| 0x14072DC70 | CDecision::[1] vtable 槽 CDecision::[1]（func_names RTTI 名） |
| 0x140D0D660 | （无名） 体设 CNavalDeploymentTarget::vftable（RTTI 名） |
| 0x141298870 | （无名） 体设 CSelectionListObserver::vftable（RTTI 名） |
| 0x1414E8040 | CDiplomaticMessage::[0] vtable 槽 CDiplomaticMessage::[0]（func_names RTTI 名） |
| 0x14150D4F0 | CArmyUpgradesRequests::[8] vtable 槽 CArmyUpgradesRequests::[8]（func_names RTTI 名） |
| 0x1415A0180 | CSetStateVictoryPoints::[0] vtable 槽 CSetStateVictoryPoints::[0]（func_names RTTI 名） |
| 0x1415A01C0 | CStateHistory::[0] vtable 槽 CStateHistory::[0]（func_names RTTI 名） |
| 0x141BB7410 | CDarkFullscreenOverlayUpdateable::[0] vtable 槽 CDarkFullscreenOverlayUpdateable::[0]（func_names RTTI 名） |
| 0x1422D6830 | CTextSprite::[19] vtable 槽 CTextSprite::[19]（func_names RTTI 名） |
| 0x1423561F0 | C2dLineObject::[9] vtable 槽 C2dLineObject::[9]（func_names RTTI 名） |
| 0x1402D2C00 | CNationalFocus::[1] vtable 槽 CNationalFocus::[1]（func_names RTTI 名） |
| 0x141EB85A0 | CIntelLedgerArmyPanelController::[2] vtable 槽 CIntelLedgerArmyPanelController::[2]（func_names RTTI 名） |
| 0x1422ED600 | COption::[0] vtable 槽 COption::[0]（func_names RTTI 名） |
| 0x1424B8ED0 | CAliasString::[0] vtable 槽 CAliasString::[0]（func_names RTTI 名） |
| 0x140645D80 | （无名） 体设 CStrategySpecificData::vftable（RTTI 名） |
| 0x141180100 | CEvent::[1] vtable 槽 CEvent::[1]（func_names RTTI 名） |
| 0x1412E8BB0 | CLendLeaseAction::[0] vtable 槽 CLendLeaseAction::[0]（func_names RTTI 名） |
| 0x141A04EA0 | （无名） 体设 CProgramConsumer::vftable（RTTI 名） |
| 0x1423DD210 | CSteamCloudFile::[10] vtable 槽 CSteamCloudFile::[10]（func_names RTTI 名） |
| 0x14241F650 | （无名） 体设 CPdxResourceCacheBase::vftable（RTTI 名） |
| 0x140331BB0 | CEveryCountryWithOriginalTag::[0] vtable 槽 CEveryCountryWithOriginalTag::[0]（func_names RTTI 名） |
| 0x140634130 | CNullAIAttitude::[0] vtable 槽 CNullAIAttitude::[0]（func_names RTTI 名） |
| 0x140647E90 | CIdea::[1] vtable 槽 CIdea::[1]（func_names RTTI 名） |
| 0x140A3CFB0 | COOBChange::[14] vtable 槽 COOBChange::[14]（func_names RTTI 名） |
| 0x140BEF1F0 | CUnit::[7] vtable 槽 CUnit::[7]（func_names RTTI 名） |
| 0x142233370 | CSystem::[0] vtable 槽 CSystem::[0]（func_names RTTI 名） |
| 0x1424B8F90 | CTweakableFloat::[0] vtable 槽 CTweakableFloat::[0]（func_names RTTI 名） |
| 0x1409E6FF0 | （无名） 体设 CLostDeviceInterface::vftable（RTTI 名） |
| 0x140C0D190 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x140D988B0 | （无名） 体设 CSessionInfoObserver::vftable（RTTI 名） |
| 0x1415781F0 | （无名） 体设 CMessageTypeSettings::vftable（RTTI 名） |
| 0x141A03A00 | CRailwayProductionLine::[11] vtable 槽 CRailwayProductionLine::[11]（func_names RTTI 名） |
| 0x142397F20 | （无名） 体设 CAchievementsContext::vftable（RTTI 名） |
| 0x1424B8F50 | CTweakableBool::[0] vtable 槽 CTweakableBool::[0]（func_names RTTI 名） |
| 0x140BB0840 | W4ModifierCategory::W4ModifierType::VCModifier::XAEBV?$CPdxModi鈥�::[2] func_names 名 W4ModifierCategory::W4ModifierType::VCModifier::XAEBV?$CPdxModi鈥�::[2] |
| 0x140DDA4F0 | CInGameIdler::[46] vtable 槽 CInGameIdler::[46]（func_names RTTI 名） |
| 0x1416429C0 | CShieldObject::[9] vtable 槽 CShieldObject::[9]（func_names RTTI 名） |
| 0x1423E3D30 | CSteamMatchmakingContext::[35] vtable 槽 CSteamMatchmakingContext::[35]（func_names RTTI 名） |
| 0x1424B8FD0 | CTweakableInt::[0] vtable 槽 CTweakableInt::[0]（func_names RTTI 名） |
| 0x1424FB960 | CChecksumFile::[0] vtable 槽 CChecksumFile::[0]（func_names RTTI 名） |
| 0x1415751F0 | CMapModesInterface::[8] vtable 槽 CMapModesInterface::[8]（func_names RTTI 名） |
| 0x1419D7FC0 | CDebugMapModeConfig::CFloatToHsv::[1] vtable 槽 CDebugMapModeConfig::CFloatToHsv::[1]（func_names RTTI 名） |
| 0x14222BCF0 | CApplication::[0] vtable 槽 CApplication::[0]（func_names RTTI 名） |
| 0x142395900 | （无名） 体设 CPdxCrashReportImpl::vftable（RTTI 名） |
| 0x1424E0950 | CArchiveFile::[10] vtable 槽 CArchiveFile::[10]（func_names RTTI 名） |
| 0x140623340 | CUpgradeLevel::[0] vtable 槽 CUpgradeLevel::[0]（func_names RTTI 名） |
| 0x140BFDE30 | CUnit::[1] vtable 槽 CUnit::[1]（func_names RTTI 名） |
| 0x141019270 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x141503270 | CIncomingLendLeaseAction::[57] vtable 槽 CIncomingLendLeaseAction::[57]（func_names RTTI 名） |
| 0x141546030 | CRomeBitmap::[0] vtable 槽 CRomeBitmap::[0]（func_names RTTI 名） |
| 0x1417CC980 | CMinimapInterface::[8] vtable 槽 CMinimapInterface::[8]（func_names RTTI 名） |
| 0x1419D7F90 | CDebugMapModeConfig::CNormalizer::[1] vtable 槽 CDebugMapModeConfig::CNormalizer::[1]（func_names RTTI 名） |
| 0x141BE46C0 | CConfirmResearchTechnology::[8] vtable 槽 CConfirmResearchTechnology::[8]（func_names RTTI 名） |
| 0x1422CF160 | CBrowser::[78] vtable 槽 CBrowser::[78]（func_names RTTI 名） |
| 0x140AABAC0 | CRandomLocListMember::[0] vtable 槽 CRandomLocListMember::[0]（func_names RTTI 名） |
| 0x140BEA600 | （无名） 体设 COrdersGroupMember::vftable（RTTI 名） |
| 0x141332EA0 | （无名） 体设 SpeechInputHandler::vftable（RTTI 名） |
| 0x141406470 | CCountryOperationTokenManager::[0] vtable 槽 CCountryOperationTokenManager::[0]（func_names RTTI 名） |
| 0x14186CD00 | CSystemMessage::[0] vtable 槽 CSystemMessage::[0]（func_names RTTI 名） |
| 0x14198BB90 | CTaskForceCompositionRequirements::[0] vtable 槽 CTaskForceCompositionRequirements::[0]（func_names RTTI 名） |
| 0x142300660 | CSmoothListbox::[0] vtable 槽 CSmoothListbox::[0]（func_names RTTI 名） |
| 0x142355C30 | CPdxSystem::[0] vtable 槽 CPdxSystem::[0]（func_names RTTI 名） |
| 0x142361CA0 | CSdlEvents::[0] vtable 槽 CSdlEvents::[0]（func_names RTTI 名） |
| 0x14049B170 | CCreateProductionLicense::[0] vtable 槽 CCreateProductionLicense::[0]（func_names RTTI 名） |
| 0x140C4ADB0 | CAirRegionCombatData::[0] vtable 槽 CAirRegionCombatData::[0]（func_names RTTI 名） |
| 0x140DE5340 | CInGameIdler::[59] vtable 槽 CInGameIdler::[59]（func_names RTTI 名） |
| 0x140E27490 | CNavalUnitTransfer::[8] vtable 槽 CNavalUnitTransfer::[8]（func_names RTTI 名） |
| 0x14188B210 | CTheatreSelector::[8] vtable 槽 CTheatreSelector::[8]（func_names RTTI 名） |
| 0x1422D4E40 | CInstantSprite::[46] vtable 槽 CInstantSprite::[46]（func_names RTTI 名） |
| 0x1422FA2C0 | CInstantTextBoxType::[10] vtable 槽 CInstantTextBoxType::[10]（func_names RTTI 名） |
| 0x1422FE780 | CSprite::[45] vtable 槽 CSprite::[45]（func_names RTTI 名） |
| 0x1422FE9B0 | CSprite::[46] vtable 槽 CSprite::[46]（func_names RTTI 名） |
| 0x14237DA70 | CTextBoxType::[10] vtable 槽 CTextBoxType::[10]（func_names RTTI 名） |
| 0x1401543D0 | （无名） 体设 CReloadDispatcher::vftable（RTTI 名） |
| 0x140164480 | CGameDate::[4] vtable 槽 CGameDate::[4]（func_names RTTI 名） |
| 0x140535880 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x140B8F970 | CPersistedBookmarkPlaythroughDb::[0] vtable 槽 CPersistedBookmarkPlaythroughDb::[0]（func_names RTTI 名） |
| 0x14235F4C0 | CProgressbarSprite::[43] vtable 槽 CProgressbarSprite::[43]（func_names RTTI 名） |
| 0x142384D60 | CPdxMouse::[19] vtable 槽 CPdxMouse::[19]（func_names RTTI 名） |
| 0x1424009A0 | PdxSocialPermissions::BooleanPermission::[0] vtable 槽 PdxSocialPermissions::BooleanPermission::[0]（func_names RTTI 名） |
| 0x140BFBFD0 | CUnit::[46] vtable 槽 CUnit::[46]（func_names RTTI 名） |
| 0x1424DF710 | （无名） 体设 CArchiveFile::vftable（RTTI 名） |
| 0x140164330 | CGameDate::[2] vtable 槽 CGameDate::[2]（func_names RTTI 名） |
| 0x14029DFD0 | （无名） 体设 CPdxEventHandler::vftable（RTTI 名） |
| 0x1403CBE10 | CHasCoreOccupationModifier::[0] vtable 槽 CHasCoreOccupationModifier::[0]（func_names RTTI 名） |
| 0x140F6F800 | CRailwayGunProductionLine::[0] vtable 槽 CRailwayGunProductionLine::[0]（func_names RTTI 名） |
| 0x141196FB0 | CEvolveShipImgui::[1] vtable 槽 CEvolveShipImgui::[1]（func_names RTTI 名） |
| 0x141961FB0 | CBuildingListener::[2] vtable 槽 CBuildingListener::[2]（func_names RTTI 名） |
| 0x14223A750 | CGraphics::[8] vtable 槽 CGraphics::[8]（func_names RTTI 名） |
| 0x1422403B0 | CSpriteType::[31] vtable 槽 CSpriteType::[31]（func_names RTTI 名） |
| 0x14232B930 | CCurveGraph::[28] vtable 槽 CCurveGraph::[28]（func_names RTTI 名） |
| 0x1403CB600 | CHasVariable::[0] vtable 槽 CHasVariable::[0]（func_names RTTI 名） |
| 0x1403CBC70 | CHasBuilt::[0] vtable 槽 CHasBuilt::[0]（func_names RTTI 名） |
| 0x1404A6F80 | CHasContestedOwner::[0] vtable 槽 CHasContestedOwner::[0]（func_names RTTI 名） |
| 0x1411BF7B0 | boost::xpressive::detail::actionable::[0] vtable 槽 boost::xpressive::detail::actionable::[0]（func_names RTTI 名） |
| 0x1414B4BC0 | CProductionLine::[18] vtable 槽 CProductionLine::[18]（func_names RTTI 名） |
| 0x141C95140 | CDiplomacyGiveStateControlController::[15] vtable 槽 CDiplomacyGiveStateControlController::[15]（func_names RTTI 名） |
| 0x141FA3050 | CIterationRewardOption::[0] vtable 槽 CIterationRewardOption::[0]（func_names RTTI 名） |
| 0x140DCA850 | CInGameIdler::[85] vtable 槽 CInGameIdler::[85]（func_names RTTI 名） |
| 0x141140330 | CRequestPuppetForcesAction::[32] vtable 槽 CRequestPuppetForcesAction::[32]（func_names RTTI 名） |
| 0x141F40ED0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x1422CEED0 | CBrowser::[28] vtable 槽 CBrowser::[28]（func_names RTTI 名） |
| 0x1422D1230 | CButtonStandard::[96] vtable 槽 CButtonStandard::[96]（func_names RTTI 名） |
| 0x14237F220 | CTrack::[96] vtable 槽 CTrack::[96]（func_names RTTI 名） |
| 0x141CABCF0 | CRelationStripViewBase::CStripFlagItem::[0] vtable 槽 CRelationStripViewBase::CStripFlagItem::[0]（func_names RTTI 名） |
| 0x1420A19F0 | CMapApplication::[9] vtable 槽 CMapApplication::[9]（func_names RTTI 名） |
| 0x14128AD30 | （无名） 体设 CMapIconClient::vftable（RTTI 名） |
| 0x1413EAE30 | （无名） 体设 CStateManpower::vftable（RTTI 名） |
| 0x1414C1EB0 | （无名） 体设 CPendingAction::vftable（RTTI 名） |
| 0x1414C7BB0 | CPendingAddMovement::[6] vtable 槽 CPendingAddMovement::[6]（func_names RTTI 名） |
| 0x14151B3A0 | CTakeStateAction::[24] vtable 槽 CTakeStateAction::[24]（func_names RTTI 名） |
| 0x14237E270 | （无名） 体设 CPdxDummy3DType::vftable（RTTI 名） |
| 0x1424D4380 | （无名） 体设 CPdxRefCounted::vftable（RTTI 名） |
| 0x140CD8A20 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14113F710 | CRequestLicensedProductionAction::[45] vtable 槽 CRequestLicensedProductionAction::[45]（func_names RTTI 名） |
| 0x140CD89E0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141A03A40 | CRailwayProductionLine::[8] vtable 槽 CRailwayProductionLine::[8]（func_names RTTI 名） |
| 0x142401ED0 | （无名） 体设 CStoreContext::vftable（RTTI 名） |
| 0x1417D1FB0 | CMusicPlaybackListener::[1] vtable 槽 CMusicPlaybackListener::[1]（func_names RTTI 名） |
| 0x1422ADBA0 | CStandardlistbox::[35] vtable 槽 CStandardlistbox::[35]（func_names RTTI 名） |
| 0x140D23790 | CImproveRelationsRelation::[15] vtable 槽 CImproveRelationsRelation::[15]（func_names RTTI 名） |
| 0x1415400C0 | CRevolutionaryTagChange::[17] vtable 槽 CRevolutionaryTagChange::[17]（func_names RTTI 名） |
| 0x142275D80 | （无名） 体设 CPdx3DObject::vftable（RTTI 名） |
| 0x140F76AE0 | CAirMission::STargetPriority::[0] vtable 槽 CAirMission::STargetPriority::[0]（func_names RTTI 名） |
| 0x140F76B10 | CAirMission::SLogisticsStrikeTarget::[0] vtable 槽 CAirMission::SLogisticsStrikeTarget::[0]（func_names RTTI 名） |
| 0x140F76B40 | CAirMission::SNavalTarget::[0] vtable 槽 CAirMission::SNavalTarget::[0]（func_names RTTI 名） |
| 0x140F76BA0 | CAirMission::STacticalTarget::[0] vtable 槽 CAirMission::STacticalTarget::[0]（func_names RTTI 名） |
| 0x141A00C30 | （无名） 体设 CProductionResourceCost::vftable（RTTI 名） |
| 0x141C8C180 | CDiplomacyViewActionSubController::[1] vtable 槽 CDiplomacyViewActionSubController::[1]（func_names RTTI 名） |
| 0x141DE8490 | CGameLobbyPlayerListener::[1] vtable 槽 CGameLobbyPlayerListener::[1]（func_names RTTI 名） |
| 0x142276D20 | CPdxMeshObject::[10] vtable 槽 CPdxMeshObject::[10]（func_names RTTI 名） |
| 0x142276E70 | CPdxMeshObject::[11] vtable 槽 CPdxMeshObject::[11]（func_names RTTI 名） |
| 0x142277590 | CPdxMeshObject::[14] vtable 槽 CPdxMeshObject::[14]（func_names RTTI 名） |
| 0x142355DD0 | CPdxSystem::[5] vtable 槽 CPdxSystem::[5]（func_names RTTI 名） |
| 0x140B7AF50 | （无名） 体设 CUpdateable::vftable（RTTI 名） |
| 0x1413A0E70 | CPartyLeaderTarget::[28] vtable 槽 CPartyLeaderTarget::[28]（func_names RTTI 名） |
| 0x1414E8480 | CProvinceListener::[1] vtable 槽 CProvinceListener::[1]（func_names RTTI 名） |
| 0x1422AC220 | CStandardlistbox::[32] vtable 槽 CStandardlistbox::[32]（func_names RTTI 名） |
| 0x142300B30 | CSmoothListbox::[32] vtable 槽 CSmoothListbox::[32]（func_names RTTI 名） |
| 0x1423845F0 | CPdxMouse::[24] vtable 槽 CPdxMouse::[24]（func_names RTTI 名） |
| 0x142402EB0 | （无名） 体设 CUGCContext::vftable（RTTI 名） |
| 0x14150BBA0 | CArmyUpgradesRequests::[3] vtable 槽 CArmyUpgradesRequests::[3]（func_names RTTI 名） |
| 0x140B95710 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x14224E0C0 | （无名） 体设 CPdxEvents::vftable（RTTI 名） |
| 0x142268070 | SpeechRecognitionListener::[0] vtable 槽 SpeechRecognitionListener::[0]（func_names RTTI 名） |
| 0x1423DC6A0 | （无名） 体设 CCloudFile::vftable（RTTI 名） |
| 0x142704780 | （无名） 体设 CPdxResourceCacheBase::vftable（RTTI 名） |
| 0x141A00F40 | CStateListener::[1] vtable 槽 CStateListener::[1]（func_names RTTI 名） |
| 0x14235B900 | SGfxShaderPassReader::[3] vtable 槽 SGfxShaderPassReader::[3]（func_names RTTI 名） |
| 0x1423A9510 | PdxTextToSpeechInterface::[0] vtable 槽 PdxTextToSpeechInterface::[0]（func_names RTTI 名） |
| 0x1412B9C70 | CLandCombat::[13] vtable 槽 CLandCombat::[13]（func_names RTTI 名） |
| 0x141C98FF0 | CDiplomacyStageCoupController::[3] vtable 槽 CDiplomacyStageCoupController::[3]（func_names RTTI 名） |
| 0x1424BB2D0 | （无名） 体设 CTextLexer::vftable（RTTI 名） |
| 0x140B3BDB0 | CFrontEndIdler::[18] vtable 槽 CFrontEndIdler::[18]（func_names RTTI 名） |
| 0x140B3C4A0 | CNudgeIdler::[17] vtable 槽 CNudgeIdler::[17]（func_names RTTI 名） |
| 0x140D0D870 | CShipRefitDeployment::[0] vtable 槽 CShipRefitDeployment::[0]（func_names RTTI 名） |
| 0x141298D10 | CSelectionListObserver::[0] vtable 槽 CSelectionListObserver::[0]（func_names RTTI 名） |
| 0x141EFAE70 | X$$QEAUSDownloadProfileResult::Z::7::$$A6AXXZ::V?$function::std鈥�::[3] func_names 名 X$$QEAUSDownloadProfileResult::Z::7::$$A6AXXZ::V?$function::std鈥�::[3] |
| 0x1420A6D70 | CFirstPersonStrategy::[0] vtable 槽 CFirstPersonStrategy::[0]（func_names RTTI 名） |
| 0x142251100 | CSession::[5] vtable 槽 CSession::[5]（func_names RTTI 名） |
| 0x1423E9410 | CSteamNetContext::[19] vtable 槽 CSteamNetContext::[19]（func_names RTTI 名） |
| 0x1424EE570 | CRemoteFile::[12] vtable 槽 CRemoteFile::[12]（func_names RTTI 名） |
| 0x1426F83D0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426F83E0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426F83F0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426F8400 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426FA0F0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426FC230 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426FC5B0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1426FE7B0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140646500 | CStrategySpecificData::[0] vtable 槽 CStrategySpecificData::[0]（func_names RTTI 名） |
| 0x141642A80 | CSprite::[69] vtable 槽 CSprite::[69]（func_names RTTI 名） |
| 0x1422A97C0 | （无名） 体设 CStandardlistbox::vftable（RTTI 名） |
| 0x1422D7180 | CTextSprite::[46] vtable 槽 CTextSprite::[46]（func_names RTTI 名） |
| 0x142384350 | （无名） 体设 CSysInfo::vftable（RTTI 名） |
| 0x14241F6B0 | CPdxResourceCacheBase::[0] vtable 槽 CPdxResourceCacheBase::[0]（func_names RTTI 名） |
| 0x1424BE3D0 | （无名） 体设 CFactory::vftable（RTTI 名） |
| 0x1409E7310 | CLostDeviceInterface::[0] vtable 槽 CLostDeviceInterface::[0]（func_names RTTI 名） |
| 0x140C0EB60 | CSubUnitDefinitionId::[0] vtable 槽 CSubUnitDefinitionId::[0]（func_names RTTI 名） |
| 0x140D99160 | CSessionInfoObserver::[0] vtable 槽 CSessionInfoObserver::[0]（func_names RTTI 名） |
| 0x141285B40 | CPdxPostEffectHeightVolume::[0] vtable 槽 CPdxPostEffectHeightVolume::[0]（func_names RTTI 名） |
| 0x141285B70 | CPdxPostEffectVolume::[0] vtable 槽 CPdxPostEffectVolume::[0]（func_names RTTI 名） |
| 0x141578340 | CMessageTypeSettings::[0] vtable 槽 CMessageTypeSettings::[0]（func_names RTTI 名） |
| 0x141858050 | IPEAVCSession::HHPEBVCOrdersGroup::H::VCID::AXAEBV?$CPdxArray::鈥�::[3] func_names 名 IPEAVCSession::HHPEBVCOrdersGroup::H::VCID::AXAEBV?$CPdxArray::鈥�::[3] |
| 0x14186CBB0 | CChatMessageObserver::[0] vtable 槽 CChatMessageObserver::[0]（func_names RTTI 名） |
| 0x1422D1120 | CButtonStandard::[23] vtable 槽 CButtonStandard::[23]（func_names RTTI 名） |
| 0x1422D1170 | CButtonStandard::[31] vtable 槽 CButtonStandard::[31]（func_names RTTI 名） |
| 0x1422D1F40 | CButtonStandard::[99] vtable 槽 CButtonStandard::[99]（func_names RTTI 名） |
| 0x1423060B0 | CButtonDrag::[23] vtable 槽 CButtonDrag::[23]（func_names RTTI 名） |
| 0x1423077E0 | CButtonDrag::[99] vtable 槽 CButtonDrag::[99]（func_names RTTI 名） |
| 0x1423DC6E0 | CCloudStorageContext::[0] vtable 槽 CCloudStorageContext::[0]（func_names RTTI 名） |
| 0x1413336D0 | CTextBufferObserver::[0] vtable 槽 CTextBufferObserver::[0]（func_names RTTI 名） |
| 0x141EA9930 | CIntelLedgerPanelController::[1] vtable 槽 CIntelLedgerPanelController::[1]（func_names RTTI 名） |
| 0x1422D10E0 | CButtonStandard::[98] vtable 槽 CButtonStandard::[98]（func_names RTTI 名） |
| 0x1422D67F0 | CTextSprite::[45] vtable 槽 CTextSprite::[45]（func_names RTTI 名） |
| 0x1423060A0 | CButtonDrag::[98] vtable 槽 CButtonDrag::[98]（func_names RTTI 名） |
| 0x142306A80 | CButtonDrag::[78] vtable 槽 CButtonDrag::[78]（func_names RTTI 名） |
| 0x142307020 | CButtonDrag::[0] vtable 槽 CButtonDrag::[0]（func_names RTTI 名） |
| 0x14237F250 | CTrack::[78] vtable 槽 CTrack::[78]（func_names RTTI 名） |
| 0x14237F260 | CTrack::[77] vtable 槽 CTrack::[77]（func_names RTTI 名） |
| 0x14237F3C0 | CTrack::[0] vtable 槽 CTrack::[0]（func_names RTTI 名） |
| 0x14237F400 | CTrack::[8] vtable 槽 CTrack::[8]（func_names RTTI 名） |
| 0x142395910 | CPdxCrashReportImpl::[0] vtable 槽 CPdxCrashReportImpl::[0]（func_names RTTI 名） |
| 0x1423E0330 | CMatchmakingContext::[0] vtable 槽 CMatchmakingContext::[0]（func_names RTTI 名） |
| 0x140A66AB0 | CMapModeDispatcher::[0] vtable 槽 CMapModeDispatcher::[0]（func_names RTTI 名） |
| 0x1413337C0 | SpeechInputHandler::[0] vtable 槽 SpeechInputHandler::[0]（func_names RTTI 名） |
| 0x1413337F0 | SpeechInputTextboxHandler::[0] vtable 槽 SpeechInputTextboxHandler::[0]（func_names RTTI 名） |
| 0x14146D510 | CScrollbarObserver::[0] vtable 槽 CScrollbarObserver::[0]（func_names RTTI 名） |
| 0x14153FEF0 | CCountryNukesChange::[17] vtable 槽 CCountryNukesChange::[17]（func_names RTTI 名） |
| 0x1418CB0A0 | CDecisionMapIconContainer::[8] vtable 槽 CDecisionMapIconContainer::[8]（func_names RTTI 名） |
| 0x14229BAD0 | CBitmapFont::[16] vtable 槽 CBitmapFont::[16]（func_names RTTI 名） |
| 0x142307730 | CButtonDrag::[97] vtable 槽 CButtonDrag::[97]（func_names RTTI 名） |
| 0x14012A2A0 | CTbbThreadObserver::[0] vtable 槽 CTbbThreadObserver::[0]（func_names RTTI 名） |
| 0x14015F3E0 | CMeshReloader::[0] vtable 槽 CMeshReloader::[0]（func_names RTTI 名） |
| 0x14015FBA0 | CGameLevelAssetReloader::[0] vtable 槽 CGameLevelAssetReloader::[0]（func_names RTTI 名） |
| 0x1402DE840 | CCheckBoxObserver::[0] vtable 槽 CCheckBoxObserver::[0]（func_names RTTI 名） |
| 0x1402F8B10 | CTriggerEntryBase::[0] vtable 槽 CTriggerEntryBase::[0]（func_names RTTI 名） |
| 0x140535B40 | CNullSavedEventTarget::[0] vtable 槽 CNullSavedEventTarget::[0]（func_names RTTI 名） |
| 0x140D23750 | CImproveRelationsRelation::[18] vtable 槽 CImproveRelationsRelation::[18]（func_names RTTI 名） |
| 0x140F6ECF0 | CMilitaryProductionLine::[23] vtable 槽 CMilitaryProductionLine::[23]（func_names RTTI 名） |
| 0x141285C50 | CPostEffectVolumeReloader::[0] vtable 槽 CPostEffectVolumeReloader::[0]（func_names RTTI 名） |
| 0x142236B20 | CGuiAnimationReloader::[0] vtable 槽 CGuiAnimationReloader::[0]（func_names RTTI 名） |
| 0x140160880 | CScientistTrait::[0] vtable 槽 CScientistTrait::[0]（func_names RTTI 名） |
| 0x14029E940 | CNullIdler::[0] vtable 槽 CNullIdler::[0]（func_names RTTI 名） |
| 0x1402E2FF0 | CEffectEntryBase::[0] vtable 槽 CEffectEntryBase::[0]（func_names RTTI 名） |
| 0x140331160 | CCountryLeader::[0] vtable 槽 CCountryLeader::[0]（func_names RTTI 名） |
| 0x140557380 | CTimedModifier::[0] vtable 槽 CTimedModifier::[0]（func_names RTTI 名） |
| 0x14064D0A0 | CStrategicAI::SExpeditionaryData::[0] vtable 槽 CStrategicAI::SExpeditionaryData::[0]（func_names RTTI 名） |
| 0x14064D140 | CStrategicAI::SRaidAttemptEntry::[0] vtable 槽 CStrategicAI::SRaidAttemptEntry::[0]（func_names RTTI 名） |
| 0x1409F1E30 | CEquipmentModule::[0] vtable 槽 CEquipmentModule::[0]（func_names RTTI 名） |
| 0x140A5CD80 | CMap::[0] vtable 槽 CMap::[0]（func_names RTTI 名） |
| 0x140A80900 | CTimedOpinionModifier::[0] vtable 槽 CTimedOpinionModifier::[0]（func_names RTTI 名） |
| 0x140B51C60 | CGraphicalMap::[0] vtable 槽 CGraphicalMap::[0]（func_names RTTI 名） |
| 0x140B860D0 | CScriptedWindowGUIUpdater::[1] vtable 槽 CScriptedWindowGUIUpdater::[1]（func_names RTTI 名） |
| 0x140B909E0 | CMusicPlayerSettings::[0] vtable 槽 CMusicPlayerSettings::[0]（func_names RTTI 名） |
| 0x140B970B0 | CDivisionTemplateData::[0] vtable 槽 CDivisionTemplateData::[0]（func_names RTTI 名） |
| 0x140BEA9A0 | COrdersGroup::[0] vtable 槽 COrdersGroup::[0]（func_names RTTI 名） |
| 0x140CD92A0 | CAirInLandCombat::[0] vtable 槽 CAirInLandCombat::[0]（func_names RTTI 名） |
| 0x140CE1F00 | CNavalAccidentReport::[0] vtable 槽 CNavalAccidentReport::[0]（func_names RTTI 名） |
| 0x140CE20A0 | CNavalMineReport::[0] vtable 槽 CNavalMineReport::[0]（func_names RTTI 名） |
| 0x140D0D780 | CDeploymentStatus::[0] vtable 槽 CDeploymentStatus::[0]（func_names RTTI 名） |
| 0x1410A3B20 | CRadarsPool::[1] vtable 槽 CRadarsPool::[1]（func_names RTTI 名） |
| 0x141149C50 | SAdvisorData::[0] vtable 槽 SAdvisorData::[0]（func_names RTTI 名） |
| 0x14150B1D0 | CArmyUpgradesStatus::[5] vtable 槽 CArmyUpgradesStatus::[5]（func_names RTTI 名） |
| 0x141681E60 | CStateGraphics::[0] vtable 槽 CStateGraphics::[0]（func_names RTTI 名） |
| 0x14188A560 | CTheatreSelector::[0] vtable 槽 CTheatreSelector::[0]（func_names RTTI 名） |
| 0x141C8E7D0 | CDiplomacySendExpeditionaryForceController::[4] vtable 槽 CDiplomacySendExpeditionaryForceController::[4]（func_names RTTI 名） |
| 0x141C8E7F0 | CDiplomacySendVolunteersController::[4] vtable 槽 CDiplomacySendVolunteersController::[4]（func_names RTTI 名） |
| 0x142236AF0 | CCollisionObject::[0] vtable 槽 CCollisionObject::[0]（func_names RTTI 名） |
| 0x1422CD7D0 | CRemoteFile::[0] vtable 槽 CRemoteFile::[0]（func_names RTTI 名） |
| 0x1422FD850 | CPositionType::[0] vtable 槽 CPositionType::[0]（func_names RTTI 名） |
| 0x142355F00 | C2dCollisionObject::[0] vtable 槽 C2dCollisionObject::[0]（func_names RTTI 名） |
| 0x142398C30 | CSteamAchievementsContext::[0] vtable 槽 CSteamAchievementsContext::[0]（func_names RTTI 名） |
| 0x1423A9C90 | PdxSpeechToTextWinSAPI::[0] vtable 槽 PdxSpeechToTextWinSAPI::[0]（func_names RTTI 名） |
| 0x1423C26B0 | CBrowserInstance::[0] vtable 槽 CBrowserInstance::[0]（func_names RTTI 名） |
| 0x140C10CA0 | CArmyLeader::[10] vtable 槽 CArmyLeader::[10]（func_names RTTI 名） |
| 0x140C10CF0 | CNavyLeader::[10] vtable 槽 CNavyLeader::[10]（func_names RTTI 名） |
| 0x140E8C760 | CRailwayGun::[3] vtable 槽 CRailwayGun::[3]（func_names RTTI 名） |
| 0x140EB37E0 | CSunkConvoyInfo::[0] vtable 槽 CSunkConvoyInfo::[0]（func_names RTTI 名） |
| 0x1414D4D80 | CPendingCancelMovement::[5] vtable 槽 CPendingCancelMovement::[5]（func_names RTTI 名） |
| 0x141EC3900 | CIntelLedgerHeaderController::[1] vtable 槽 CIntelLedgerHeaderController::[1]（func_names RTTI 名） |
| 0x1422A9AC0 | COptionObserver::[0] vtable 槽 COptionObserver::[0]（func_names RTTI 名） |
| 0x1423C2680 | CBrowserContext::[0] vtable 槽 CBrowserContext::[0]（func_names RTTI 名） |
| 0x14015FB70 | CGameDate::[0] vtable 槽 CGameDate::[0]（func_names RTTI 名） |
| 0x14015FC90 | CGregorianDate::[0] vtable 槽 CGregorianDate::[0]（func_names RTTI 名） |
| 0x14128B2F0 | CMapIconClient::[0] vtable 槽 CMapIconClient::[0]（func_names RTTI 名） |
| 0x1414C3520 | CPendingAction::[0] vtable 槽 CPendingAction::[0]（func_names RTTI 名） |
| 0x1414C35F0 | CPendingCancelMovement::[0] vtable 槽 CPendingCancelMovement::[0]（func_names RTTI 名） |
| 0x1423B9910 | CAudioInstance::[0] vtable 槽 CAudioInstance::[0]（func_names RTTI 名） |
| 0x1423B99E0 | CAudioSoundInstanceSDL::[0] vtable 槽 CAudioSoundInstanceSDL::[0]（func_names RTTI 名） |
| 0x1424D4480 | CPdxRefCounted::[0] vtable 槽 CPdxRefCounted::[0]（func_names RTTI 名） |
| 0x1413384C0 | CChat::[4] vtable 槽 CChat::[4]（func_names RTTI 名） |
| 0x141400AD0 | COperationInstance::[3] vtable 槽 COperationInstance::[3]（func_names RTTI 名） |
| 0x142402180 | CStoreContext::[0] vtable 槽 CStoreContext::[0]（func_names RTTI 名） |
| 0x14015FED0 | CModifier::[0] vtable 槽 CModifier::[0]（func_names RTTI 名） |
| 0x140160AB0 | CSpecificEquipmentBonus::[0] vtable 槽 CSpecificEquipmentBonus::[0]（func_names RTTI 名） |
| 0x1402CD370 | CPositionOverride::[0] vtable 槽 CPositionOverride::[0]（func_names RTTI 名） |
| 0x140618010 | CReferenceObject::[0] vtable 槽 CReferenceObject::[0]（func_names RTTI 名） |
| 0x140643160 | CSubUnitStatBonus::[3] vtable 槽 CSubUnitStatBonus::[3]（func_names RTTI 名） |
| 0x1406CEF90 | CDelayedEvent::[0] vtable 槽 CDelayedEvent::[0]（func_names RTTI 名） |
| 0x140723EB0 | （无名） 体设 CPersistentScriptTargets::vftable（RTTI 名） |
| 0x140A7B170 | COperationPhaseSelectionMember::[0] vtable 槽 COperationPhaseSelectionMember::[0]（func_names RTTI 名） |
| 0x140DC5360 | CPdxSocialPlayerId::[0] vtable 槽 CPdxSocialPlayerId::[0]（func_names RTTI 名） |
| 0x141AD7E50 | CConvoyShip::[0] vtable 槽 CConvoyShip::[0]（func_names RTTI 名） |
| 0x142230700 | CTouchDevice::[0] vtable 槽 CTouchDevice::[0]（func_names RTTI 名） |
| 0x142275F50 | CPdx3DObject::[0] vtable 槽 CPdx3DObject::[0]（func_names RTTI 名） |
| 0x1422E4660 | （无名） 体设 CBitmap::vftable（RTTI 名） |
| 0x14237E2B0 | CPdxDummy3DObject::[0] vtable 槽 CPdxDummy3DObject::[0]（func_names RTTI 名） |
| 0x1423E3CF0 | CSteamMatchmakingContext::[33] vtable 槽 CSteamMatchmakingContext::[33]（func_names RTTI 名） |
| 0x1423E3D10 | CSteamMatchmakingContext::[32] vtable 槽 CSteamMatchmakingContext::[32]（func_names RTTI 名） |
| 0x14015F6E0 | CEquipmentGraphicPoolTypeMap::[0] vtable 槽 CEquipmentGraphicPoolTypeMap::[0]（func_names RTTI 名） |
| 0x1406CEDD0 | CCountryFinishedOperations::[0] vtable 槽 CCountryFinishedOperations::[0]（func_names RTTI 名） |
| 0x140725940 | CPersistentScriptTargets::[0] vtable 槽 CPersistentScriptTargets::[0]（func_names RTTI 名） |
| 0x140A466B0 | CIdeology::[0] vtable 槽 CIdeology::[0]（func_names RTTI 名） |
| 0x140A69E70 | SAce::[0] vtable 槽 SAce::[0]（func_names RTTI 名） |
| 0x140A7BE60 | COperationPhaseSelection::[0] vtable 槽 COperationPhaseSelection::[0]（func_names RTTI 名） |
| 0x140B7BD90 | CUpdateable::[0] vtable 槽 CUpdateable::[0]（func_names RTTI 名） |
| 0x140DDA180 | CInGameIdler::[1] vtable 槽 CInGameIdler::[1]（func_names RTTI 名） |
| 0x140E5CCA0 | CCreateEquipmentVariantScheduler::[0] vtable 槽 CCreateEquipmentVariantScheduler::[0]（func_names RTTI 名） |
| 0x1412AA6C0 | （无名） 体设 CLandCombat::vftable（RTTI 名） |
| 0x14136E290 | CEquipmentInFieldLogger::[0] vtable 槽 CEquipmentInFieldLogger::[0]（func_names RTTI 名） |
| 0x14136E2C0 | CTestLogger::[0] vtable 槽 CTestLogger::[0]（func_names RTTI 名） |
| 0x141513B00 | CIncomingDiplomaticActionStatus::[0] vtable 槽 CIncomingDiplomaticActionStatus::[0]（func_names RTTI 名） |
| 0x14152C3B0 | CMissionStatsReadHelper::[0] vtable 槽 CMissionStatsReadHelper::[0]（func_names RTTI 名） |
| 0x141573CB0 | CMapModesInterface::[0] vtable 槽 CMapModesInterface::[0]（func_names RTTI 名） |
| 0x141DF7F30 | CStandardMusicPlaybackController::[1] vtable 槽 CStandardMusicPlaybackController::[1]（func_names RTTI 名） |
| 0x142230730 | CPdxProgram::[0] vtable 槽 CPdxProgram::[0]（func_names RTTI 名） |
| 0x1422E56D0 | CChatMessage::[0] vtable 槽 CChatMessage::[0]（func_names RTTI 名） |
| 0x142309BF0 | SMeshData::[0] vtable 槽 SMeshData::[0]（func_names RTTI 名） |
| 0x142349340 | SCategoryReader::[0] vtable 槽 SCategoryReader::[0]（func_names RTTI 名） |
| 0x142349380 | SSoundEffectReader::[0] vtable 槽 SSoundEffectReader::[0]（func_names RTTI 名） |
| 0x142356870 | CArrowType::[0] vtable 槽 CArrowType::[0]（func_names RTTI 名） |
| 0x142359240 | SGfxShaderPassReader::[0] vtable 槽 SGfxShaderPassReader::[0]（func_names RTTI 名） |
| 0x1423A9930 | PdxTextToSpeechState::[0] vtable 槽 PdxTextToSpeechState::[0]（func_names RTTI 名） |
| 0x1423E7580 | CNetContext::[0] vtable 槽 CNetContext::[0]（func_names RTTI 名） |
| 0x142403150 | CUGCContext::[0] vtable 槽 CUGCContext::[0]（func_names RTTI 名） |
| 0x140B410B0 | CGameGraphics::[2] vtable 槽 CGameGraphics::[2]（func_names RTTI 名） |
| 0x14159FF20 | （无名） 体设 CStateHistory::vftable（RTTI 名） |
| 0x141C952A0 | CDiplomacySendVolunteersController::[17] vtable 槽 CDiplomacySendVolunteersController::[17]（func_names RTTI 名） |
| 0x14224E0D0 | CPdxEvents::[0] vtable 槽 CPdxEvents::[0]（func_names RTTI 名） |
| 0x1423DC6B0 | CCloudFile::[0] vtable 槽 CCloudFile::[0]（func_names RTTI 名） |
| 0x1427042C0 | （无名） 体设 CSysInfo::vftable（RTTI 名） |
| 0x1401C9B40 | tbb::task::[0] vtable 槽 tbb::task::[0]（func_names RTTI 名） |
| 0x141959D60 | （无名） 体设 CQuietIntelNetwork::vftable（RTTI 名） |
| 0x141959D90 | （无名） 体设 CQuietIntelNetwork::vftable（RTTI 名） |
| 0x14195AB10 | （无名） 体设 CRootOutResistance::vftable（RTTI 名） |
| 0x14195AB40 | （无名） 体设 CRootOutResistance::vftable（RTTI 名） |
| 0x1422AFAF0 | CTrack::[81] vtable 槽 CTrack::[81]（func_names RTTI 名） |
| 0x14022D200 | CAutosave::[0] vtable 槽 CAutosave::[0]（func_names RTTI 名） |
| 0x1424E0380 | CArchiveFile::[4] vtable 槽 CArchiveFile::[4]（func_names RTTI 名） |
| 0x14015F260 | CAnonymousEquipmentGroup::[0] vtable 槽 CAnonymousEquipmentGroup::[0]（func_names RTTI 名） |
| 0x14015F720 | CEquipmentGroup::[0] vtable 槽 CEquipmentGroup::[0]（func_names RTTI 名） |
| 0x1401603B0 | CProfiledScopeObject::[0] vtable 槽 CProfiledScopeObject::[0]（func_names RTTI 名） |
| 0x140160840 | CRule::[0] vtable 槽 CRule::[0]（func_names RTTI 名） |
| 0x1401608C0 | CScopedVariable::[0] vtable 槽 CScopedVariable::[0]（func_names RTTI 名） |
| 0x140160AF0 | CStaticModifier::[0] vtable 槽 CStaticModifier::[0]（func_names RTTI 名） |
| 0x1401C9700 | CSavedEventTarget::[0] vtable 槽 CSavedEventTarget::[0]（func_names RTTI 名） |
| 0x1401C9740 | CScriptFlag::[0] vtable 槽 CScriptFlag::[0]（func_names RTTI 名） |
| 0x1402F8B40 | CIsAdvisor::[0] vtable 槽 CIsAdvisor::[0]（func_names RTTI 名） |
| 0x140330E10 | CAdvisor::[0] vtable 槽 CAdvisor::[0]（func_names RTTI 名） |
| 0x140330FB0 | CCharacterPortraits::[0] vtable 槽 CCharacterPortraits::[0]（func_names RTTI 名） |
| 0x140332B50 | CScientistTemplate::[0] vtable 槽 CScientistTemplate::[0]（func_names RTTI 名） |
| 0x140333CD0 | SUnitOfficerData::[0] vtable 槽 SUnitOfficerData::[0]（func_names RTTI 名） |
| 0x1403CBB20 | CEquipmentArcheTypePool::[0] vtable 槽 CEquipmentArcheTypePool::[0]（func_names RTTI 名） |
| 0x1403CCB40 | CSubUnitDefinition::[0] vtable 槽 CSubUnitDefinition::[0]（func_names RTTI 名） |
| 0x1403CCB80 | SSubUnitStats::[0] vtable 槽 SSubUnitStats::[0]（func_names RTTI 名） |
| 0x140441F80 | CIsPromotedFromUnit::[0] vtable 槽 CIsPromotedFromUnit::[0]（func_names RTTI 名） |
| 0x14049B1B0 | CEquipmentUpgradesInstance::[0] vtable 槽 CEquipmentUpgradesInstance::[0]（func_names RTTI 名） |
| 0x14064CFA0 | CAIResearchNeed::[0] vtable 槽 CAIResearchNeed::[0]（func_names RTTI 名） |
| 0x14064D020 | CScriptTargets::[0] vtable 槽 CScriptTargets::[0]（func_names RTTI 名） |
| 0x140683470 | CBuildingSpawnPoint::[0] vtable 槽 CBuildingSpawnPoint::[0]（func_names RTTI 名） |
| 0x1409C0760 | CNameGroupMember::[0] vtable 槽 CNameGroupMember::[0]（func_names RTTI 名） |
| 0x1409F1EF0 | CDuplicateArchetypeDefinition::[0] vtable 槽 CDuplicateArchetypeDefinition::[0]（func_names RTTI 名） |
| 0x1409F1F70 | CEquipmentStatsGroup::[0] vtable 槽 CEquipmentStatsGroup::[0]（func_names RTTI 名） |
| 0x140A3BE50 | CGraphicalCultureType::[0] vtable 槽 CGraphicalCultureType::[0]（func_names RTTI 名） |
| 0x140A69EB0 | SNamesPool::[0] vtable 槽 SNamesPool::[0]（func_names RTTI 名） |
| 0x140A73420 | SSpriteFramePair::[0] vtable 槽 SSpriteFramePair::[0]（func_names RTTI 名） |
| 0x140BD25C0 | CEquipmentVariant::[0] vtable 槽 CEquipmentVariant::[0]（func_names RTTI 名） |
| 0x140CA6080 | CConvoySubscriber::[0] vtable 槽 CConvoySubscriber::[0]（func_names RTTI 名） |
| 0x140CE1F70 | CNavalCombatResultSide::[0] vtable 槽 CNavalCombatResultSide::[0]（func_names RTTI 名） |
| 0x140D026B0 | CStaticIntelSourceReference::[0] vtable 槽 CStaticIntelSourceReference::[0]（func_names RTTI 名） |
| 0x140E9F030 | CTaskForceComposition::[0] vtable 槽 CTaskForceComposition::[0]（func_names RTTI 名） |
| 0x1410D4430 | COperativesAi::[0] vtable 槽 COperativesAi::[0]（func_names RTTI 名） |
| 0x1410FC860 | CCallAllyAction::[0] vtable 槽 CCallAllyAction::[0]（func_names RTTI 名） |
| 0x141109480 | CReturnAllExpeditionaryForcesAction::[56] vtable 槽 CReturnAllExpeditionaryForcesAction::[56]（func_names RTTI 名） |
| 0x141122A70 | CRequestForeignManpowerAction::[58] vtable 槽 CRequestForeignManpowerAction::[58]（func_names RTTI 名） |
| 0x1411282D0 | CEmbargoAction::[41] vtable 槽 CEmbargoAction::[41]（func_names RTTI 名） |
| 0x141232660 | CTaskForceIdentity::[0] vtable 槽 CTaskForceIdentity::[0]（func_names RTTI 名） |
| 0x1412353E0 | CUnitStrategicMoveAction::[9] vtable 槽 CUnitStrategicMoveAction::[9]（func_names RTTI 名） |
| 0x1412660C0 | CMapArrowButtonDefinition::[0] vtable 槽 CMapArrowButtonDefinition::[0]（func_names RTTI 名） |
| 0x141285C80 | SPostEffectHeightVolumeReader::[0] vtable 槽 SPostEffectHeightVolumeReader::[0]（func_names RTTI 名） |
| 0x141376FC0 | （无名） 体设 CPositionOverride::vftable（RTTI 名） |
| 0x141484510 | CException::[0] vtable 槽 CException::[0]（func_names RTTI 名） |
| 0x1415193F0 | CTakeNavyPeaceAction::[0] vtable 槽 CTakeNavyPeaceAction::[0]（func_names RTTI 名） |
| 0x141519430 | CPeaceAction::[0] vtable 槽 CPeaceAction::[0]（func_names RTTI 名） |
| 0x141519470 | CPuppetCountryAction::[0] vtable 槽 CPuppetCountryAction::[0]（func_names RTTI 名） |
| 0x1415194B0 | CTakeStateAction::[0] vtable 槽 CTakeStateAction::[0]（func_names RTTI 名） |
| 0x14153D510 | CFriendsHandlerFriendSteam::[0] vtable 槽 CFriendsHandlerFriendSteam::[0]（func_names RTTI 名） |
| 0x1415E4C50 | CDiplomacyCountryInfoController::[1] vtable 槽 CDiplomacyCountryInfoController::[1]（func_names RTTI 名） |
| 0x141642A40 | CSprite::[44] vtable 槽 CSprite::[44]（func_names RTTI 名） |
| 0x141752800 | CDiplomacyPopupWindowBase::[0] vtable 槽 CDiplomacyPopupWindowBase::[0]（func_names RTTI 名） |
| 0x141915B60 | CDynamicEquipmentGroup::[0] vtable 槽 CDynamicEquipmentGroup::[0]（func_names RTTI 名） |
| 0x141981130 | （无名） 体设 COfferAirBaseAccessRelation::vftable（RTTI 名） |
| 0x1419816F0 | （无名） 体设 COfferDockingRightsRelation::vftable（RTTI 名） |
| 0x1419C8660 | CUseMilFac::[0] vtable 槽 CUseMilFac::[0]（func_names RTTI 名） |
| 0x1419C87F0 | CTutAirbase::[0] vtable 槽 CTutAirbase::[0]（func_names RTTI 名） |
| 0x141D71800 | CDecisionViewDecisionItemBase::[0] vtable 槽 CDecisionViewDecisionItemBase::[0]（func_names RTTI 名） |
| 0x141DCBD70 | SGfxSettingsReader::[0] vtable 槽 SGfxSettingsReader::[0]（func_names RTTI 名） |
| 0x141F6B270 | CConfirmDeleteEquipmentProductionLine::[0] vtable 槽 CConfirmDeleteEquipmentProductionLine::[0]（func_names RTTI 名） |
| 0x142075E70 | CDLCDescriptor::[0] vtable 槽 CDLCDescriptor::[0]（func_names RTTI 名） |
| 0x142092EE0 | SSubsystemReader::[0] vtable 槽 SSubsystemReader::[0]（func_names RTTI 名） |
| 0x1420A1970 | CGraphics::[0] vtable 槽 CGraphics::[0]（func_names RTTI 名） |
| 0x142236AB0 | C2dObject::[9] vtable 槽 C2dObject::[9]（func_names RTTI 名） |
| 0x14223F890 | CSpriteType::[0] vtable 槽 CSpriteType::[0]（func_names RTTI 名） |
| 0x14225A420 | CFactory::[0] vtable 槽 CFactory::[0]（func_names RTTI 名） |
| 0x142331050 | SParticleSystemReader::[0] vtable 槽 SParticleSystemReader::[0]（func_names RTTI 名） |
| 0x142355910 | CMouseButtonPressedObservable::[0] vtable 槽 CMouseButtonPressedObservable::[0]（func_names RTTI 名） |
| 0x142359140 | SGfxBlendStateReader::[0] vtable 槽 SGfxBlendStateReader::[0]（func_names RTTI 名） |
| 0x142359180 | SGfxDepthStencilStateReader::[0] vtable 槽 SGfxDepthStencilStateReader::[0]（func_names RTTI 名） |
| 0x1423591C0 | SGfxRasterizerStateReader::[0] vtable 槽 SGfxRasterizerStateReader::[0]（func_names RTTI 名） |
| 0x142359200 | SGfxSamplerReader::[0] vtable 槽 SGfxSamplerReader::[0]（func_names RTTI 名） |
| 0x142360E20 | CTextSpriteType::[0] vtable 槽 CTextSpriteType::[0]（func_names RTTI 名） |
| 0x142361890 | CTileSpriteType::[0] vtable 槽 CTileSpriteType::[0]（func_names RTTI 名） |
| 0x142385C70 | CResizeableSprite::[9] vtable 槽 CResizeableSprite::[9]（func_names RTTI 名） |
| 0x1424BF0C0 | CReader::[0] vtable 槽 CReader::[0]（func_names RTTI 名） |
| 0x141641A80 | CMaskedSpriteType::[17] vtable 槽 CMaskedSpriteType::[17]（func_names RTTI 名） |
| 0x1422AAD80 | CSmoothListbox::[13] vtable 槽 CSmoothListbox::[13]（func_names RTTI 名） |
| 0x1422AD0E0 | CSmoothListbox::[14] vtable 槽 CSmoothListbox::[14]（func_names RTTI 名） |
| 0x142384670 | CPdxMouse::[23] vtable 槽 CPdxMouse::[23]（func_names RTTI 名） |
| 0x1423B36E0 | CAudio::[0] vtable 槽 CAudio::[0]（func_names RTTI 名） |
| 0x1423B3710 | CAudioMusic::[0] vtable 槽 CAudioMusic::[0]（func_names RTTI 名） |
| 0x1424BA230 | CTweakableInt::[2] vtable 槽 CTweakableInt::[2]（func_names RTTI 名） |
| 0x14113A490 | CSendAttacheAction::[57] vtable 槽 CSendAttacheAction::[57]（func_names RTTI 名） |
| 0x141641A40 | CMaskedSpriteType::[0] vtable 槽 CMaskedSpriteType::[0]（func_names RTTI 名） |
| 0x1422AAA60 | CSmoothListbox::[2] vtable 槽 CSmoothListbox::[2]（func_names RTTI 名） |
| 0x1422AAB00 | CSmoothListbox::[3] vtable 槽 CSmoothListbox::[3]（func_names RTTI 名） |
| 0x1422AABC0 | CSmoothListbox::[10] vtable 槽 CSmoothListbox::[10]（func_names RTTI 名） |
| 0x1422AABD0 | CSmoothListbox::[11] vtable 槽 CSmoothListbox::[11]（func_names RTTI 名） |
| 0x1422AABE0 | CSmoothListbox::[12] vtable 槽 CSmoothListbox::[12]（func_names RTTI 名） |
| 0x142398080 | SPrimeStat::[0] vtable 槽 SPrimeStat::[0]（func_names RTTI 名） |
| 0x1423980B0 | SStat::[0] vtable 槽 SStat::[0]（func_names RTTI 名） |
| 0x140AD9E90 | CTimedWargoalActivity::[9] vtable 槽 CTimedWargoalActivity::[9]（func_names RTTI 名） |
| 0x141196FE0 | CEvolveTankImgui::[1] vtable 槽 CEvolveTankImgui::[1]（func_names RTTI 名） |
| 0x14150E040 | CGarrisonStatus::[2] vtable 槽 CGarrisonStatus::[2]（func_names RTTI 名） |
| 0x141A31890 | （无名） 体设 CNetworkBased::vftable（RTTI 名） |
| 0x141A318C0 | （无名） 体设 CNetworkBased::vftable（RTTI 名） |
| 0x141C95280 | CDiplomacySendExpeditionaryForceController::[17] vtable 槽 CDiplomacySendExpeditionaryForceController::[17]（func_names RTTI 名） |
| 0x14229C570 | CBitmapFont::[1] vtable 槽 CBitmapFont::[1]（func_names RTTI 名） |
| 0x14229C580 | CBitmapFont::[2] vtable 槽 CBitmapFont::[2]（func_names RTTI 名） |
| 0x1424BB010 | （无名） 体设 CBinLexer::vftable（RTTI 名） |
| 0x140C01AE0 | CUnit::[44] vtable 槽 CUnit::[44]（func_names RTTI 名） |
| 0x140DD3710 | CInGameIdler::[41] vtable 槽 CInGameIdler::[41]（func_names RTTI 名） |
| 0x1416CAF30 | CUnitLeaderTraitTree::[27] vtable 槽 CUnitLeaderTraitTree::[27]（func_names RTTI 名） |
| 0x1416CAFE0 | CUnitLeaderTraitTree::[29] vtable 槽 CUnitLeaderTraitTree::[29]（func_names RTTI 名） |
| 0x1416CC410 | CUnitLeaderTraitTree::[28] vtable 槽 CUnitLeaderTraitTree::[28]（func_names RTTI 名） |
| 0x14015CBA0 | CAiFleetTemplateDatabase::[1] vtable 槽 CAiFleetTemplateDatabase::[1]（func_names RTTI 名） |
| 0x14015CBE0 | CAiTaskforceTemplateDatabase::[1] vtable 槽 CAiTaskforceTemplateDatabase::[1]（func_names RTTI 名） |
| 0x14015CE20 | CFocusInlayWindowDatabase::[1] vtable 槽 CFocusInlayWindowDatabase::[1]（func_names RTTI 名） |
| 0x14015CEA0 | CFrontEndBackgroundDatabase::[1] vtable 槽 CFrontEndBackgroundDatabase::[1]（func_names RTTI 名） |
| 0x14015D060 | CStrategicLocationDatabase::[1] vtable 槽 CStrategicLocationDatabase::[1]（func_names RTTI 名） |
| 0x14015F1E0 | CAiTaskforceTemplate::[0] vtable 槽 CAiTaskforceTemplate::[0]（func_names RTTI 名） |
| 0x140160110 | COperationPhase::[0] vtable 槽 COperationPhase::[0]（func_names RTTI 名） |
| 0x140160150 | COperationToken::[0] vtable 槽 COperationToken::[0]（func_names RTTI 名） |
| 0x1401C9630 | CGameState::[0] vtable 槽 CGameState::[0]（func_names RTTI 名） |
| 0x1401FA500 | CAutotestSettings::[0] vtable 槽 CAutotestSettings::[0]（func_names RTTI 名） |
| 0x1401FA540 | CSettings::[0] vtable 槽 CSettings::[0]（func_names RTTI 名） |
| 0x14022D1C0 | CCivilWarSetup::[0] vtable 槽 CCivilWarSetup::[0]（func_names RTTI 名） |
| 0x14029E900 | CGameIdler::[0] vtable 槽 CGameIdler::[0]（func_names RTTI 名） |
| 0x1402ADC20 | CTestLoggersArray::[0] vtable 槽 CTestLoggersArray::[0]（func_names RTTI 名） |
| 0x1402C4950 | nlohmann::detail::exception::[1] vtable 槽 nlohmann::detail::exception::[1]（func_names RTTI 名） |
| 0x1402CCF00 | CNationalFocus::[0] vtable 槽 CNationalFocus::[0]（func_names RTTI 名） |
| 0x1402CD0F0 | CNationalFocusPosition::[0] vtable 槽 CNationalFocusPosition::[0]（func_names RTTI 名） |
| 0x1402CD490 | SNationalFocusStyle::[0] vtable 槽 SNationalFocusStyle::[0]（func_names RTTI 名） |
| 0x140333980 | CUnitLeaderData::[0] vtable 槽 CUnitLeaderData::[0]（func_names RTTI 名） |
| 0x14049B130 | CCreateEquipmentVariantSpec::[0] vtable 槽 CCreateEquipmentVariantSpec::[0]（func_names RTTI 名） |
| 0x140613370 | CAbility::[0] vtable 槽 CAbility::[0]（func_names RTTI 名） |
| 0x14061C8F0 | CAchievement::[0] vtable 槽 CAchievement::[0]（func_names RTTI 名） |
| 0x14061C9D0 | CBaseAchievement::[0] vtable 槽 CBaseAchievement::[0]（func_names RTTI 名） |
| 0x1406231E0 | CAgencyUpgrade::[0] vtable 槽 CAgencyUpgrade::[0]（func_names RTTI 名） |
| 0x140623220 | CAgencyUpgradeBranch::[0] vtable 槽 CAgencyUpgradeBranch::[0]（func_names RTTI 名） |
| 0x14062D870 | CAIEquipmentRoleDatabase::[1] vtable 槽 CAIEquipmentRoleDatabase::[1]（func_names RTTI 名） |
| 0x140633F80 | CAIAttitude::[0] vtable 槽 CAIAttitude::[0]（func_names RTTI 名） |
| 0x140646530 | CTargetedStrategyData::[0] vtable 槽 CTargetedStrategyData::[0]（func_names RTTI 名） |
| 0x14067CBD0 | CBookmark::[0] vtable 槽 CBookmark::[0]（func_names RTTI 名） |
| 0x1406834B0 | CBuildingTemplate::[0] vtable 槽 CBuildingTemplate::[0]（func_names RTTI 名） |
| 0x1406834F0 | CBuildingDatabase::[1] vtable 槽 CBuildingDatabase::[1]（func_names RTTI 名） |
| 0x1406AD1A0 | SProfileMeta::[0] vtable 槽 SProfileMeta::[0]（func_names RTTI 名） |
| 0x1406BC0B0 | CAdvisorTemplate::[0] vtable 槽 CAdvisorTemplate::[0]（func_names RTTI 名） |
| 0x1406BC0F0 | CCharacterTemplate::[0] vtable 槽 CCharacterTemplate::[0]（func_names RTTI 名） |
| 0x1406BDA70 | CCombatTactic::[0] vtable 槽 CCombatTactic::[0]（func_names RTTI 名） |
| 0x1406C13E0 | CContinuousNationalFocus::[0] vtable 槽 CContinuousNationalFocus::[0]（func_names RTTI 名） |
| 0x1406CEC90 | CAirTheatre::[0] vtable 槽 CAirTheatre::[0]（func_names RTTI 名） |
| 0x1406CED10 | CConvoys::[0] vtable 槽 CConvoys::[0]（func_names RTTI 名） |
| 0x1406CED90 | CCountryCharacters::[0] vtable 槽 CCountryCharacters::[0]（func_names RTTI 名） |
| 0x14071DD60 | CCountryLeaderTrait::[0] vtable 槽 CCountryLeaderTrait::[0]（func_names RTTI 名） |
| 0x1407217B0 | CCustomMapMode::[0] vtable 槽 CCustomMapMode::[0]（func_names RTTI 名） |
| 0x140725650 | CDecisionCategory::[0] vtable 槽 CDecisionCategory::[0]（func_names RTTI 名） |
| 0x1409C05E0 | CNameGroup::[0] vtable 槽 CNameGroup::[0]（func_names RTTI 名） |
| 0x1409F1E70 | CEquipmentType::[0] vtable 槽 CEquipmentType::[0]（func_names RTTI 名） |
| 0x1409F1F30 | CEquipmentDatabase::[1] vtable 槽 CEquipmentDatabase::[1]（func_names RTTI 名） |
| 0x140A31B70 | CFriendsHandlerSteam::[0] vtable 槽 CFriendsHandlerSteam::[0]（func_names RTTI 名） |
| 0x140A359A0 | CGameRule::[0] vtable 槽 CGameRule::[0]（func_names RTTI 名） |
| 0x140A3A360 | CWarGoalType::[0] vtable 槽 CWarGoalType::[0]（func_names RTTI 名） |
| 0x140A408E0 | CIdea::[0] vtable 槽 CIdea::[0]（func_names RTTI 名） |
| 0x140A409A0 | CTechnologyTemplate::[0] vtable 槽 CTechnologyTemplate::[0]（func_names RTTI 名） |
| 0x140A466F0 | CIdeologyGroup::[0] vtable 槽 CIdeologyGroup::[0]（func_names RTTI 名） |
| 0x140A69D80 | CCountryNames::[0] vtable 槽 CCountryNames::[0]（func_names RTTI 名） |
| 0x140A733E0 | COccupationLaw::[0] vtable 槽 COccupationLaw::[0]（func_names RTTI 名） |
| 0x140A7BE20 | COperation::[0] vtable 槽 COperation::[0]（func_names RTTI 名） |
| 0x140A80800 | COpinionModifier::[0] vtable 槽 COpinionModifier::[0]（func_names RTTI 名） |
| 0x140A86AD0 | CCountryPortraits::[0] vtable 槽 CCountryPortraits::[0]（func_names RTTI 名） |
| 0x140A86C70 | CPortraitPool::[0] vtable 槽 CPortraitPool::[0]（func_names RTTI 名） |
| 0x140A8C510 | CPowerBalanceRange::[0] vtable 槽 CPowerBalanceRange::[0]（func_names RTTI 名） |
| 0x140A8C550 | CPowerBalanceSide::[0] vtable 槽 CPowerBalanceSide::[0]（func_names RTTI 名） |
| 0x140A8C590 | CPowerBalanceTemplate::[0] vtable 槽 CPowerBalanceTemplate::[0]（func_names RTTI 名） |
| 0x140AA04D0 | CResistanceActivity::[0] vtable 槽 CResistanceActivity::[0]（func_names RTTI 名） |
| 0x140AB1460 | CScriptedDiplomaticActionTemplate::[0] vtable 槽 CScriptedDiplomaticActionTemplate::[0]（func_names RTTI 名） |
| 0x140AB5D40 | CScriptedTriggerTemplate::[0] vtable 槽 CScriptedTriggerTemplate::[0]（func_names RTTI 名） |
| 0x140ABC340 | CStateTemplate::[0] vtable 槽 CStateTemplate::[0]（func_names RTTI 名） |
| 0x140AC30F0 | CSubUnitDatabase::[1] vtable 槽 CSubUnitDatabase::[1]（func_names RTTI 名） |
| 0x140ACBC90 | CTechnologyFolder::[0] vtable 槽 CTechnologyFolder::[0]（func_names RTTI 名） |
| 0x140ACBD50 | CTechnologyPath::[0] vtable 槽 CTechnologyPath::[0]（func_names RTTI 名） |
| 0x140AD7860 | CTimedActivityEquipmentDistributable::[0] vtable 槽 CTimedActivityEquipmentDistributable::[0]（func_names RTTI 名） |
| 0x140ADF1B0 | CTrainGfxDatabase::[1] vtable 槽 CTrainGfxDatabase::[1]（func_names RTTI 名） |
| 0x140AE4C30 | CUnitLeaderSkill::[0] vtable 槽 CUnitLeaderSkill::[0]（func_names RTTI 名） |
| 0x140AE4C70 | CUnitLeaderTrait::[0] vtable 槽 CUnitLeaderTrait::[0]（func_names RTTI 名） |
| 0x140AE4CB0 | CUnitLeaderDatabase::[1] vtable 槽 CUnitLeaderDatabase::[1]（func_names RTTI 名） |
| 0x140B51CA0 | CTextBlock::[0] vtable 槽 CTextBlock::[0]（func_names RTTI 名） |
| 0x140B8F9C0 | CPersistedDesignsDb::[0] vtable 槽 CPersistedDesignsDb::[0]（func_names RTTI 名） |
| 0x140BB69F0 | CCombatHistory::[0] vtable 槽 CCombatHistory::[0]（func_names RTTI 名） |
| 0x140BBE9D0 | CPeaceConference::[0] vtable 槽 CPeaceConference::[0]（func_names RTTI 名） |
| 0x140C01AF0 | CUnit::[0] vtable 槽 CUnit::[0]（func_names RTTI 名） |
| 0x140C0EB20 | CSubUnitDefinitionAssociatedModifiers::[0] vtable 槽 CSubUnitDefinitionAssociatedModifiers::[0]（func_names RTTI 名） |
| 0x140C4AED0 | CStrategicAirManager::[1] vtable 槽 CStrategicAirManager::[1]（func_names RTTI 名） |
| 0x140C93590 | SAnimationData::[0] vtable 槽 SAnimationData::[0]（func_names RTTI 名） |
| 0x140CA60C0 | CCountryResources::[0] vtable 槽 CCountryResources::[0]（func_names RTTI 名） |
| 0x140CA61E0 | CResourceOrigin::[0] vtable 槽 CResourceOrigin::[0]（func_names RTTI 名） |
| 0x140CF10F0 | CControllerArea::[0] vtable 槽 CControllerArea::[0]（func_names RTTI 名） |
| 0x140CF1130 | COwnerArea::[0] vtable 槽 COwnerArea::[0]（func_names RTTI 名） |
| 0x140CFA150 | CStateManpower::[0] vtable 槽 CStateManpower::[0]（func_names RTTI 名） |
| 0x140D02510 | CCountryIntel::[0] vtable 槽 CCountryIntel::[0]（func_names RTTI 名） |
| 0x140D18F10 | CRelationStatus::[0] vtable 槽 CRelationStatus::[0]（func_names RTTI 名） |
| 0x140D19030 | CWarRelation::[0] vtable 槽 CWarRelation::[0]（func_names RTTI 名） |
| 0x140D644C0 | CTaskForce::[0] vtable 槽 CTaskForce::[0]（func_names RTTI 名） |
| 0x140D99010 | CGameLobby::[0] vtable 槽 CGameLobby::[0]（func_names RTTI 名） |
| 0x140DC5320 | CInGameIdler::[0] vtable 槽 CInGameIdler::[0]（func_names RTTI 名） |
| 0x140E25990 | CNavalUnitTransfer::[0] vtable 槽 CNavalUnitTransfer::[0]（func_names RTTI 名） |
| 0x140E55530 | CPowerBalance::[0] vtable 槽 CPowerBalance::[0]（func_names RTTI 名） |
| 0x140ED4EB0 | CTechnology::[0] vtable 槽 CTechnology::[0]（func_names RTTI 名） |
| 0x140F15770 | SWeatherPerProvince::[0] vtable 槽 SWeatherPerProvince::[0]（func_names RTTI 名） |
| 0x140F157B0 | SWeatherPerRegion::[0] vtable 槽 SWeatherPerRegion::[0]（func_names RTTI 名） |
| 0x140F91740 | CResistance::[0] vtable 槽 CResistance::[0]（func_names RTTI 名） |
| 0x140FAA430 | CNavalMission::[0] vtable 槽 CNavalMission::[0]（func_names RTTI 名） |
| 0x140FD7440 | CIntelligenceAgency::[0] vtable 槽 CIntelligenceAgency::[0]（func_names RTTI 名） |
| 0x140FF3680 | CStateGarrisonData::[0] vtable 槽 CStateGarrisonData::[0]（func_names RTTI 名） |
| 0x141029200 | COrderInstance::[0] vtable 槽 COrderInstance::[0]（func_names RTTI 名） |
| 0x14107ADC0 | CAIGeneral::[0] vtable 槽 CAIGeneral::[0]（func_names RTTI 名） |
| 0x1410B4C40 | CAIMilitaryMinister::[0] vtable 槽 CAIMilitaryMinister::[0]（func_names RTTI 名） |
| 0x1410FCA60 | CJoinAllyAction::[0] vtable 槽 CJoinAllyAction::[0]（func_names RTTI 名） |
| 0x1410FCAA0 | CRequestLicensedProductionAction::[0] vtable 槽 CRequestLicensedProductionAction::[0]（func_names RTTI 名） |
| 0x14117F760 | CEvent::[0] vtable 槽 CEvent::[0]（func_names RTTI 名） |
| 0x141195EA0 | CEvolveShipImgui::[0] vtable 槽 CEvolveShipImgui::[0]（func_names RTTI 名） |
| 0x1411F2A90 | CStrategicOperative::[0] vtable 槽 CStrategicOperative::[0]（func_names RTTI 名） |
| 0x14121AF80 | CCountrySupplySystem::[0] vtable 槽 CCountrySupplySystem::[0]（func_names RTTI 名） |
| 0x141278420 | CPdxMap::[0] vtable 槽 CPdxMap::[0]（func_names RTTI 名） |
| 0x141285C10 | CPdxPostEffectVolumeManager::[0] vtable 槽 CPdxPostEffectVolumeManager::[0]（func_names RTTI 名） |
| 0x141285D00 | SPostEffectVolumeReader::[0] vtable 槽 SPostEffectVolumeReader::[0]（func_names RTTI 名） |
| 0x14128B320 | CProvinceGraphics::[0] vtable 槽 CProvinceGraphics::[0]（func_names RTTI 名） |
| 0x1412AAAA0 | CLandCombatant::[0] vtable 槽 CLandCombatant::[0]（func_names RTTI 名） |
| 0x141333310 | CChat::[0] vtable 槽 CChat::[0]（func_names RTTI 名） |
| 0x1413C4310 | CStateCategory::[0] vtable 槽 CStateCategory::[0]（func_names RTTI 名） |
| 0x1413FFE00 | COperationInstance::[0] vtable 槽 COperationInstance::[0]（func_names RTTI 名） |
| 0x1414542C0 | CConferenceBeneficiaryWithStackableParticipant::[1] vtable 槽 CConferenceBeneficiaryWithStackableParticipant::[1]（func_names RTTI 名） |
| 0x141493C40 | CAICompactDivisionTemplate::[0] vtable 槽 CAICompactDivisionTemplate::[0]（func_names RTTI 名） |
| 0x1414E8080 | CMessage::[0] vtable 槽 CMessage::[0]（func_names RTTI 名） |
| 0x141509D20 | CArmyUpgradesRequests::[0] vtable 槽 CArmyUpgradesRequests::[0]（func_names RTTI 名） |
| 0x14159DC70 | CScriptedWindowTemplate::[0] vtable 槽 CScriptedWindowTemplate::[0]（func_names RTTI 名） |
| 0x14161A990 | CNavalCombatant::[0] vtable 槽 CNavalCombatant::[0]（func_names RTTI 名） |
| 0x1416468A0 | CAmbientObjectType::[0] vtable 槽 CAmbientObjectType::[0]（func_names RTTI 名） |
| 0x1416516E0 | CCitySettings::[0] vtable 槽 CCitySettings::[0]（func_names RTTI 名） |
| 0x141661B00 | CShipCombatReader::[0] vtable 槽 CShipCombatReader::[0]（func_names RTTI 名） |
| 0x1416C8D50 | CUnitLeaderTraitTree::[0] vtable 槽 CUnitLeaderTraitTree::[0]（func_names RTTI 名） |
| 0x1416D9CF0 | CBattlePlansTools::[0] vtable 槽 CBattlePlansTools::[0]（func_names RTTI 名） |
| 0x141705930 | CCountryMilitaryOverview::[0] vtable 槽 CCountryMilitaryOverview::[0]（func_names RTTI 名） |
| 0x1417CA870 | CMapMode::[0] vtable 槽 CMapMode::[0]（func_names RTTI 名） |
| 0x1417CEC60 | CMissionExtension::[0] vtable 槽 CMissionExtension::[0]（func_names RTTI 名） |
| 0x14186CCC0 | CPlayerLobby::[0] vtable 槽 CPlayerLobby::[0]（func_names RTTI 名） |
| 0x14187AF20 | CAirViewDetails::[1] vtable 槽 CAirViewDetails::[1]（func_names RTTI 名） |
| 0x14191FCF0 | SPotentialDesign::[0] vtable 槽 SPotentialDesign::[0]（func_names RTTI 名） |
| 0x141962AA0 | SAirWingCombatData::[0] vtable 槽 SAirWingCombatData::[0]（func_names RTTI 名） |
| 0x14196ACF0 | CLendLeaseExchange::[0] vtable 槽 CLendLeaseExchange::[0]（func_names RTTI 名） |
| 0x14196F9C0 | CFEXMember::[0] vtable 槽 CFEXMember::[0]（func_names RTTI 名） |
| 0x14196FA00 | CFEXMember::SCachedInfo::[0] vtable 槽 CFEXMember::SCachedInfo::[0]（func_names RTTI 名） |
| 0x141976AA0 | CFEXAir::[0] vtable 槽 CFEXAir::[0]（func_names RTTI 名） |
| 0x141981100 | （无名） 体设 CAirBaseAccessRelation::vftable（RTTI 名） |
| 0x141981160 | CAirBaseAccessRelation::[0] vtable 槽 CAirBaseAccessRelation::[0]（func_names RTTI 名） |
| 0x1419816C0 | （无名） 体设 CDockingRightsRelation::vftable（RTTI 名） |
| 0x1419C88C0 | CTutorialChapter::[0] vtable 槽 CTutorialChapter::[0]（func_names RTTI 名） |
| 0x1419C8900 | CTutorialHint::[0] vtable 槽 CTutorialHint::[0]（func_names RTTI 名） |
| 0x141B45290 | CBuildingsNudger::[0] vtable 槽 CBuildingsNudger::[0]（func_names RTTI 名） |
| 0x141B51E20 | CDBNudger::[0] vtable 槽 CDBNudger::[0]（func_names RTTI 名） |
| 0x141B57DD0 | CStateNudger::[0] vtable 槽 CStateNudger::[0]（func_names RTTI 名） |
| 0x141B60F40 | CStrategicRegionNudger::[0] vtable 槽 CStrategicRegionNudger::[0]（func_names RTTI 名） |
| 0x141B6B960 | CSupplyNudger::[0] vtable 槽 CSupplyNudger::[0]（func_names RTTI 名） |
| 0x141B7D750 | CWeatherNudger::[0] vtable 槽 CWeatherNudger::[0]（func_names RTTI 名） |
| 0x141BE3510 | CConfirmResearchTechnology::[0] vtable 槽 CConfirmResearchTechnology::[0]（func_names RTTI 名） |
| 0x141C10E20 | CCountryCharacterSelector::[0] vtable 槽 CCountryCharacterSelector::[0]（func_names RTTI 名） |
| 0x141C2F9B0 | CSaveDesignToFilePopUp::[0] vtable 槽 CSaveDesignToFilePopUp::[0]（func_names RTTI 名） |
| 0x141C4F380 | CIdeaFolder::[1] vtable 槽 CIdeaFolder::[1]（func_names RTTI 名） |
| 0x141C69D80 | CFEXGroup::[0] vtable 槽 CFEXGroup::[0]（func_names RTTI 名） |
| 0x141D10DE0 | CHistoryEntryItemBase::[0] vtable 槽 CHistoryEntryItemBase::[0]（func_names RTTI 名） |
| 0x141D84A70 | CMapModeMilitaryDeployment::[0] vtable 槽 CMapModeMilitaryDeployment::[0]（func_names RTTI 名） |
| 0x141DCBD30 | CEntitySprite::[0] vtable 槽 CEntitySprite::[0]（func_names RTTI 名） |
| 0x141E0AE40 | CNavyTheaterNavyItemBase::[0] vtable 槽 CNavyTheaterNavyItemBase::[0]（func_names RTTI 名） |
| 0x141EA5C40 | CIntelLedgerAirPanelController::[0] vtable 槽 CIntelLedgerAirPanelController::[0]（func_names RTTI 名） |
| 0x141EB17E0 | CIntelLedgerArmyPanelController::[0] vtable 槽 CIntelLedgerArmyPanelController::[0]（func_names RTTI 名） |
| 0x141EC7310 | CIntelLedgerNavyPanelController::[0] vtable 槽 CIntelLedgerNavyPanelController::[0]（func_names RTTI 名） |
| 0x1420A19B0 | CMapApplication::[0] vtable 槽 CMapApplication::[0]（func_names RTTI 名） |
| 0x1420A6DA0 | CMapIdler::[0] vtable 槽 CMapIdler::[0]（func_names RTTI 名） |
| 0x142228010 | CGraphicsSettings::[0] vtable 槽 CGraphicsSettings::[0]（func_names RTTI 名） |
| 0x14222A060 | CSystemSettings::[0] vtable 槽 CSystemSettings::[0]（func_names RTTI 名） |
| 0x1422304F0 | CKeyPressedObservable::[0] vtable 槽 CKeyPressedObservable::[0]（func_names RTTI 名） |
| 0x142236C20 | SBitmapFontOverride::[0] vtable 槽 SBitmapFontOverride::[0]（func_names RTTI 名） |
| 0x14224F510 | CSession::[0] vtable 槽 CSession::[0]（func_names RTTI 名） |
| 0x14225A460 | CGui::[0] vtable 槽 CGui::[0]（func_names RTTI 名） |
| 0x142296860 | CPdxParticleType::[0] vtable 槽 CPdxParticleType::[0]（func_names RTTI 名） |
| 0x1422989F0 | CBitmapFont::[0] vtable 槽 CBitmapFont::[0]（func_names RTTI 名） |
| 0x1422B6D50 | CWindowObservable::[0] vtable 槽 CWindowObservable::[0]（func_names RTTI 名） |
| 0x1422CEB30 | CTextInputReceiver::[0] vtable 槽 CTextInputReceiver::[0]（func_names RTTI 名） |
| 0x1422D0A70 | CButtonStandard::[7] vtable 槽 CButtonStandard::[7]（func_names RTTI 名） |
| 0x1422D5730 | CTextSprite::[9] vtable 槽 CTextSprite::[9]（func_names RTTI 名） |
| 0x1422DF640 | PdxStackWalker::[0] vtable 槽 PdxStackWalker::[0]（func_names RTTI 名） |
| 0x1422E57B0 | CPersonalChatMessage::[0] vtable 槽 CPersonalChatMessage::[0]（func_names RTTI 名） |
| 0x1422F6990 | CWindowType::[0] vtable 槽 CWindowType::[0]（func_names RTTI 名） |
| 0x1422FA270 | CInstantTextBoxType::[0] vtable 槽 CInstantTextBoxType::[0]（func_names RTTI 名） |
| 0x142309B70 | CPdxMeshType::[0] vtable 槽 CPdxMeshType::[0]（func_names RTTI 名） |
| 0x14230F200 | CContainerWindowType::[0] vtable 槽 CContainerWindowType::[0]（func_names RTTI 名） |
| 0x1423163C0 | CMatchmakingGui::[0] vtable 槽 CMatchmakingGui::[0]（func_names RTTI 名） |
| 0x14234D080 | SAnimatedLightReader::[0] vtable 槽 SAnimatedLightReader::[0]（func_names RTTI 名） |
| 0x14234D150 | SEntityAttachmentReader::[0] vtable 槽 SEntityAttachmentReader::[0]（func_names RTTI 名） |
| 0x14234D1F0 | SEntityReader::[0] vtable 槽 SEntityReader::[0]（func_names RTTI 名） |
| 0x14234D230 | SEntityStateReader::[0] vtable 槽 SEntityStateReader::[0]（func_names RTTI 名） |
| 0x142355950 | CMouseButtonReleasedObservable::[0] vtable 槽 CMouseButtonReleasedObservable::[0]（func_names RTTI 名） |
| 0x142355990 | CMouseDoubleClickObservable::[0] vtable 槽 CMouseDoubleClickObservable::[0]（func_names RTTI 名） |
| 0x1423559D0 | CMouseMovedObservable::[0] vtable 槽 CMouseMovedObservable::[0]（func_names RTTI 名） |
| 0x142355B40 | CMouse::[0] vtable 槽 CMouse::[0]（func_names RTTI 名） |
| 0x142355BF0 | CSysInfo::[0] vtable 槽 CSysInfo::[0]（func_names RTTI 名） |
| 0x14235F170 | CProgressbarSprite::[9] vtable 槽 CProgressbarSprite::[9]（func_names RTTI 名） |
| 0x142369680 | CProxyServer::[0] vtable 槽 CProxyServer::[0]（func_names RTTI 名） |
| 0x14236EDD0 | CButtonType::[0] vtable 槽 CButtonType::[0]（func_names RTTI 名） |
| 0x142372190 | CDropDownMenuType::[0] vtable 槽 CDropDownMenuType::[0]（func_names RTTI 名） |
| 0x142376500 | CListboxType::[0] vtable 槽 CListboxType::[0]（func_names RTTI 名） |
| 0x14237A4B0 | CRadioButtonGroupType::[0] vtable 槽 CRadioButtonGroupType::[0]（func_names RTTI 名） |
| 0x14237AFB0 | CRadioScrollbarGroupType::[0] vtable 槽 CRadioScrollbarGroupType::[0]（func_names RTTI 名） |
| 0x14237C160 | CScrollbarType::[0] vtable 槽 CScrollbarType::[0]（func_names RTTI 名） |
| 0x14237DA30 | CTextBoxType::[0] vtable 槽 CTextBoxType::[0]（func_names RTTI 名） |
| 0x14237F410 | CNullGraphicalObject::[9] vtable 槽 CNullGraphicalObject::[9]（func_names RTTI 名） |
| 0x142392600 | CPdxCrashReportWindows::[0] vtable 槽 CPdxCrashReportWindows::[0]（func_names RTTI 名） |
| 0x142395AF0 | CCustomStackWalker::[0] vtable 槽 CCustomStackWalker::[0]（func_names RTTI 名） |
| 0x1423A9540 | PdxTextToSpeechWinSAPI::[0] vtable 槽 PdxTextToSpeechWinSAPI::[0]（func_names RTTI 名） |
| 0x1423B9880 | CAudioCategory::[0] vtable 槽 CAudioCategory::[0]（func_names RTTI 名） |
| 0x1423B9940 | CAudioMusicInstance::[0] vtable 槽 CAudioMusicInstance::[0]（func_names RTTI 名） |
| 0x1423C0530 | SAudioContext::[0] vtable 槽 SAudioContext::[0]（func_names RTTI 名） |
| 0x1423C26E0 | CSteamBrowserInstance::[0] vtable 槽 CSteamBrowserInstance::[0]（func_names RTTI 名） |
| 0x1423E1410 | CSteamMatchmakingContext::[6] vtable 槽 CSteamMatchmakingContext::[6]（func_names RTTI 名） |
| 0x1423E75B0 | CSteamNetContext::[0] vtable 槽 CSteamNetContext::[0]（func_names RTTI 名） |
| 0x1423E7B80 | CSteamNetContext::[10] vtable 槽 CSteamNetContext::[10]（func_names RTTI 名） |
| 0x1424B8F10 | CTweakable::[0] vtable 槽 CTweakable::[0]（func_names RTTI 名） |
| 0x1424C9190 | CLogger::[0] vtable 槽 CLogger::[0]（func_names RTTI 名） |
| 0x1423E7B70 | CSteamNetContext::[18] vtable 槽 CSteamNetContext::[18]（func_names RTTI 名） |
| 0x1402A0890 | CGameIdler::[5] vtable 槽 CGameIdler::[5]（func_names RTTI 名） |
| 0x1420A43E0 | CAnimViewerGraphics::[9] vtable 槽 CAnimViewerGraphics::[9]（func_names RTTI 名） |
| 0x142361860 | （无名） 体设 CTileSpriteType::vftable（RTTI 名） |
| 0x14224E0A0 | （无名） 体设 CPdxEvents::vftable（RTTI 名） |
| 0x140AD9E60 | CTimedStageCoupActivity::[9] vtable 槽 CTimedStageCoupActivity::[9]（func_names RTTI 名） |
| 0x140D985A0 | （无名） 体设 CLargefileHandlerInterface::vftable（RTTI 名） |
| 0x1411401A0 | CCancelForeignManpowerAction::[32] vtable 槽 CCancelForeignManpowerAction::[32]（func_names RTTI 名） |
| 0x1414E82A0 | CMessage::[1] vtable 槽 CMessage::[1]（func_names RTTI 名） |
| 0x14222BC30 | （无名） 体设 CApplicationObservable::vftable（RTTI 名） |
| 0x14237F460 | CNullGraphicalObject::[60] vtable 槽 CNullGraphicalObject::[60]（func_names RTTI 名） |
| 0x1423AAFE0 | PdxTextToSpeechWinSAPI::[2] vtable 槽 PdxTextToSpeechWinSAPI::[2]（func_names RTTI 名） |
| 0x1423C3360 | CSteamUGCContext::[5] vtable 槽 CSteamUGCContext::[5]（func_names RTTI 名） |
| 0x142404530 | CSteamUGCContext::[3] vtable 槽 CSteamUGCContext::[3]（func_names RTTI 名） |
| 0x142404540 | CSteamUGCContext::[4] vtable 槽 CSteamUGCContext::[4]（func_names RTTI 名） |
| 0x141DBFFF0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x1423958E0 | （无名） 体设 CPdxCrashReportImpl::vftable（RTTI 名） |
| 0x1423AB170 | PdxTextToSpeechWinSAPI::[9] vtable 槽 PdxTextToSpeechWinSAPI::[9]（func_names RTTI 名） |
| 0x142402B10 | CSteamStoreContext::[10] vtable 槽 CSteamStoreContext::[10]（func_names RTTI 名） |
| 0x140C67C30 | （无名） 体设 CArmyManpowerValues::vftable（RTTI 名） |
| 0x140F69DB0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14139DE90 | （无名） 体设 CCharacterPortraits::vftable（RTTI 名） |
| 0x1420AD320 | CMapIdler::[5] vtable 槽 CMapIdler::[5]（func_names RTTI 名） |
| 0x1424C9124 | CLogStream::[0] vtable 槽 CLogStream::[0]（func_names RTTI 名） |
| 0x1424DFA10 | CArchiveFile::[15] vtable 槽 CArchiveFile::[15]（func_names RTTI 名） |
| 0x1424DFAA0 | CArchiveFile::[14] vtable 槽 CArchiveFile::[14]（func_names RTTI 名） |
| 0x1424FB9A0 | CChecksumFile::[17] vtable 槽 CChecksumFile::[17]（func_names RTTI 名） |
| 0x141D3E4C8 | CPlanesOverview::[1] vtable 槽 CPlanesOverview::[1]（func_names RTTI 名） |
| 0x1422E6E70 | CSystemMessage::[12] vtable 槽 CSystemMessage::[12]（func_names RTTI 名） |
| 0x1414C7C70 | CPendingCancelMovement::[6] vtable 槽 CPendingCancelMovement::[6]（func_names RTTI 名） |
| 0x1406431A0 | CSubUnitStatBonus::[4] vtable 槽 CSubUnitStatBonus::[4]（func_names RTTI 名） |
| 0x140EE5AB0 | CTechnologySharingGroup::[14] vtable 槽 CTechnologySharingGroup::[14]（func_names RTTI 名） |
| 0x140F71D80 | CShipRefitProductionLine::[29] vtable 槽 CShipRefitProductionLine::[29]（func_names RTTI 名） |
| 0x141127DE0 | CEmbargoAction::[19] vtable 槽 CEmbargoAction::[19]（func_names RTTI 名） |
| 0x141540E90 | CCountryConvoysChange::[1] vtable 槽 CCountryConvoysChange::[1]（func_names RTTI 名） |
| 0x141642820 | CSpriteType::[18] vtable 槽 CSpriteType::[18]（func_names RTTI 名） |
| 0x142240490 | CSpriteType::[17] vtable 槽 CSpriteType::[17]（func_names RTTI 名） |
| 0x142241220 | CSpriteType::[13] vtable 槽 CSpriteType::[13]（func_names RTTI 名） |
| 0x142241230 | CSpriteType::[14] vtable 槽 CSpriteType::[14]（func_names RTTI 名） |
| 0x142360500 | CProgressbarSprite::[20] vtable 槽 CProgressbarSprite::[20]（func_names RTTI 名） |
| 0x141106960 | CEmbargoAction::[56] vtable 槽 CEmbargoAction::[56]（func_names RTTI 名） |
| 0x1412362D0 | （无名） 体设 CInGameUpdateableInterface::vftable（RTTI 名） |
| 0x141454210 | CConferenceSubjectParticipant::[0] vtable 槽 CConferenceSubjectParticipant::[0]（func_names RTTI 名） |
| 0x1414DE4E0 | CPersistedBookmarkPlaythroughDb::[1] vtable 槽 CPersistedBookmarkPlaythroughDb::[1]（func_names RTTI 名） |
| 0x141540ED0 | CCountryNukesChange::[1] vtable 槽 CCountryNukesChange::[1]（func_names RTTI 名） |
| 0x141C94B00 | CDiplomacyLendLeaseActionController::[18] vtable 槽 CDiplomacyLendLeaseActionController::[18]（func_names RTTI 名） |
| 0x141DF9510 | CPdx3DObject::[13] vtable 槽 CPdx3DObject::[13]（func_names RTTI 名） |
| 0x141F6B450 | CConfirmSwitchEquipment::[16] vtable 槽 CConfirmSwitchEquipment::[16]（func_names RTTI 名） |
| 0x142276E60 | CPdx3DObject::[11] vtable 槽 CPdx3DObject::[11]（func_names RTTI 名） |
| 0x140A5BE60 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140A8D840 | CPowerBalanceRange::[9] vtable 槽 CPowerBalanceRange::[9]（func_names RTTI 名） |
| 0x1422AEC70 | C2dObject::[34] vtable 槽 C2dObject::[34]（func_names RTTI 名） |
| 0x140BCB1F0 | （无名） 体设 CStrategicResource::vftable（RTTI 名） |
| 0x141540FB0 | CRevolutionaryTagChange::[1] vtable 槽 CRevolutionaryTagChange::[1]（func_names RTTI 名） |
| 0x1419B2730 | ChatSettingsProviderImpl::[3] vtable 槽 ChatSettingsProviderImpl::[3]（func_names RTTI 名） |
| 0x1423845E0 | CPdxMouse::[26] vtable 槽 CPdxMouse::[26]（func_names RTTI 名） |
| 0x142384660 | CPdxMouse::[27] vtable 槽 CPdxMouse::[27]（func_names RTTI 名） |
| 0x14150D970 | CGarrisonStatus::[1] vtable 槽 CGarrisonStatus::[1]（func_names RTTI 名） |
| 0x1423DE260 | （无名） 体设 CCloudFile::vftable（RTTI 名） |
| 0x1414B4B70 | （无名） 体设 CProductionLine::vftable（RTTI 名） |
| 0x1422E7DA0 | （无名） 体设 CChatMessageObservable::vftable（RTTI 名） |
| 0x141196180 | CEvolveTankImgui::[3] vtable 槽 CEvolveTankImgui::[3]（func_names RTTI 名） |
| 0x141540EF0 | CCountryStartingTrainChange::[1] vtable 槽 CCountryStartingTrainChange::[1]（func_names RTTI 名） |
| 0x141540F10 | CCountryStartingTruckChange::[1] vtable 槽 CCountryStartingTruckChange::[1]（func_names RTTI 名） |
| 0x14188B680 | CTheatreSelector::[1] vtable 槽 CTheatreSelector::[1]（func_names RTTI 名） |
| 0x1422431B0 | CSpriteType::[22] vtable 槽 CSpriteType::[22]（func_names RTTI 名） |
| 0x1422D6820 | CTextSprite::[54] vtable 槽 CTextSprite::[54]（func_names RTTI 名） |
| 0x142225400 | （无名） 体设 CFilterLogger::vftable（RTTI 名） |
| 0x1422D1610 | CButtonStandard::[17] vtable 槽 CButtonStandard::[17]（func_names RTTI 名） |
| 0x141196150 | CEvolveShipImgui::[3] vtable 槽 CEvolveShipImgui::[3]（func_names RTTI 名） |
| 0x141C95220 | CDiplomacyStageCoupController::[15] vtable 槽 CDiplomacyStageCoupController::[15]（func_names RTTI 名） |
| 0x1422A97B0 | （无名） 体设 COptionObservable::vftable（RTTI 名） |
| 0x140EE5A90 | CTechnologySharingGroup::[13] vtable 槽 CTechnologySharingGroup::[13]（func_names RTTI 名） |
| 0x140EE5AE0 | CTechnologySharingGroup::[12] vtable 槽 CTechnologySharingGroup::[12]（func_names RTTI 名） |
| 0x1412E88B0 | （无名） 体设 CLendLeaseAction::vftable（RTTI 名） |
| 0x142355BC0 | （无名） 体设 CPdxSystem::vftable（RTTI 名） |
| 0x142703C60 | （无名） 体设 CPdxDummy3DType::vftable（RTTI 名） |
| 0x1420A7A00 | CMapIdler::[18] vtable 槽 CMapIdler::[18]（func_names RTTI 名） |
| 0x142242E10 | CSpriteType::[29] vtable 槽 CSpriteType::[29]（func_names RTTI 名） |
| 0x14236F000 | CButtonType::[11] vtable 槽 CButtonType::[11]（func_names RTTI 名） |
| 0x142376700 | CListboxType::[11] vtable 槽 CListboxType::[11]（func_names RTTI 名） |
| 0x142377910 | COverlappingElementsBoxType::[11] vtable 槽 COverlappingElementsBoxType::[11]（func_names RTTI 名） |
| 0x14237C7B0 | CScrollbarType::[11] vtable 槽 CScrollbarType::[11]（func_names RTTI 名） |
| 0x141546020 | （无名） 体设 CRomeBitmap::vftable（RTTI 名） |
| 0x1415A7440 | CEquipmentDistributable::[2] vtable 槽 CEquipmentDistributable::[2]（func_names RTTI 名） |
| 0x1422E6E30 | CCountryChatMessage::[12] vtable 槽 CCountryChatMessage::[12]（func_names RTTI 名） |
| 0x1422E6E50 | CStandardChatMessage::[12] vtable 槽 CStandardChatMessage::[12]（func_names RTTI 名） |
| 0x1424FB950 | （无名） 体设 CChecksumFile::vftable（RTTI 名） |
| 0x141DE8460 | （无名） 体设 CGameLobbyHotJoinListener::vftable（RTTI 名） |
| 0x142307E50 | CLineChart::[10] vtable 槽 CLineChart::[10]（func_names RTTI 名） |
| 0x141DE8470 | （无名） 体设 CGameLobbyPlayerListener::vftable（RTTI 名） |
| 0x14203C9D0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x142379130 | CNullButtonStandard::[0] vtable 槽 CNullButtonStandard::[0]（func_names RTTI 名） |
| 0x142379244 | CNullTrack::[0] vtable 槽 CNullTrack::[0]（func_names RTTI 名） |
| 0x141B45270 | CRandomAllConfirm::[1] vtable 槽 CRandomAllConfirm::[1]（func_names RTTI 名） |
| 0x141C36678 | CEquipmentOverview::[1] vtable 槽 CEquipmentOverview::[1]（func_names RTTI 名） |
| 0x141F6B260 | CConfirmSwitchEquipment::[1] vtable 槽 CConfirmSwitchEquipment::[1]（func_names RTTI 名） |
| 0x141F75224 | CConfirmRemoveBuildingLevel::[1] vtable 槽 CConfirmRemoveBuildingLevel::[1]（func_names RTTI 名） |
| 0x1422E1240 | CLargefileHandler::[13] vtable 槽 CLargefileHandler::[13]（func_names RTTI 名） |
| 0x14015C770 | CUnitAdjuster::[0] vtable 槽 CUnitAdjuster::[0]（func_names RTTI 名） |
| 0x1401C94D0 | CCountryColors::[0] vtable 槽 CCountryColors::[0]（func_names RTTI 名） |
| 0x140223C80 | HOI4EditorInterface::[8] vtable 槽 HOI4EditorInterface::[8]（func_names RTTI 名） |
| 0x14068F310 | SStatsReadingAdapterV2::[0] vtable 槽 SStatsReadingAdapterV2::[0]（func_names RTTI 名） |
| 0x1406CEAB0 | CCapturedOperativeReference::[0] vtable 槽 CCapturedOperativeReference::[0]（func_names RTTI 名） |
| 0x140A88A20 | CPortraitPool::[8] vtable 槽 CPortraitPool::[8]（func_names RTTI 名） |
| 0x140D0D750 | SMusicReader::[0] vtable 槽 SMusicReader::[0]（func_names RTTI 名） |
| 0x141002C30 | CDominanceValues::[0] vtable 槽 CDominanceValues::[0]（func_names RTTI 名） |
| 0x14113A470 | CRequestPuppetForcesAction::[57] vtable 槽 CRequestPuppetForcesAction::[57]（func_names RTTI 名） |
| 0x141DF8F24 | CStandardMusicPlaylistController::[1] vtable 槽 CStandardMusicPlaylistController::[1]（func_names RTTI 名） |
| 0x141E8D160 | CTinyUnitCounter::[1] vtable 槽 CTinyUnitCounter::[1]（func_names RTTI 名） |
| 0x142044960 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x1422A2D10 | CBitmapFont::[21] vtable 槽 CBitmapFont::[21]（func_names RTTI 名） |
| 0x1422FD8F0 | （无名） 体设 C2dObject::vftable（RTTI 名） |
| 0x1423493C0 | SSoundReader::[0] vtable 槽 SSoundReader::[0]（func_names RTTI 名） |
| 0x14234D190 | SEntityEventReader::[0] vtable 槽 SEntityEventReader::[0]（func_names RTTI 名） |
| 0x14234D1C0 | SEntityLocatorReader::[0] vtable 槽 SEntityLocatorReader::[0]（func_names RTTI 名） |
| 0x140B3B9A8 | CFrontEndIdler::[0] vtable 槽 CFrontEndIdler::[0]（func_names RTTI 名） |
| 0x140F71C70 | CShipRefitProductionLine::[32] vtable 槽 CShipRefitProductionLine::[32]（func_names RTTI 名） |
| 0x141086850 | CAIGeneral::[7] vtable 槽 CAIGeneral::[7]（func_names RTTI 名） |
| 0x1411FB220 | CLineChart::[43] vtable 槽 CLineChart::[43]（func_names RTTI 名） |
| 0x1415C31D0 | CNavalCombat::[25] vtable 槽 CNavalCombat::[25]（func_names RTTI 名） |
| 0x1419B2770 | ChatSettingsProviderImpl::[2] vtable 槽 ChatSettingsProviderImpl::[2]（func_names RTTI 名） |
| 0x14222BC40 | CApplication::[0] vtable 槽 CApplication::[0]（func_names RTTI 名） |
| 0x142295C00 | CCorneredTileSpriteType::[17] vtable 槽 CCorneredTileSpriteType::[17]（func_names RTTI 名） |
| 0x1422A3F60 | CButtonStandard::[19] vtable 槽 CButtonStandard::[19]（func_names RTTI 名） |
| 0x1422AAC30 | CStandardlistbox::[19] vtable 槽 CStandardlistbox::[19]（func_names RTTI 名） |
| 0x142354BD0 | CCorneredTileSprite::[43] vtable 槽 CCorneredTileSprite::[43]（func_names RTTI 名） |
| 0x1423606D0 | CResizeableSpriteType::[17] vtable 槽 CResizeableSpriteType::[17]（func_names RTTI 名） |
| 0x142384650 | CPdxMouse::[28] vtable 槽 CPdxMouse::[28]（func_names RTTI 名） |
| 0x142385CD0 | CResizeableSprite::[43] vtable 槽 CResizeableSprite::[43]（func_names RTTI 名） |
| 0x1423E8A30 | CSteamNetContext::[12] vtable 槽 CSteamNetContext::[12]（func_names RTTI 名） |
| 0x140AB1800 | CScriptedDiplomaticAction::[49] vtable 槽 CScriptedDiplomaticAction::[49]（func_names RTTI 名） |
| 0x141458900 | CConferenceSubjectParticipant::[2] vtable 槽 CConferenceSubjectParticipant::[2]（func_names RTTI 名） |
| 0x14150DA50 | CArmyReinforcementRequests::[2] vtable 槽 CArmyReinforcementRequests::[2]（func_names RTTI 名） |
| 0x14151DD00 | CPuppetCountryAction::[16] vtable 槽 CPuppetCountryAction::[16]（func_names RTTI 名） |
| 0x14151DD10 | CPeaceAction::[17] vtable 槽 CPeaceAction::[17]（func_names RTTI 名） |
| 0x14151E9F0 | CPeaceAction::[16] vtable 槽 CPeaceAction::[16]（func_names RTTI 名） |
| 0x14232BB40 | CCurveGraph::[0] vtable 槽 CCurveGraph::[0]（func_names RTTI 名） |
| 0x14237A4A0 | CRadioButtonGroupType::[0] vtable 槽 CRadioButtonGroupType::[0]（func_names RTTI 名） |
| 0x14237AFA0 | CRadioScrollbarGroupType::[0] vtable 槽 CRadioScrollbarGroupType::[0]（func_names RTTI 名） |
| 0x142397E90 | （无名） 体设 CAchievementsContext::vftable（RTTI 名） |
| 0x1423C1E90 | （无名） 体设 CSteamBrowserContext::vftable（RTTI 名） |
| 0x1402D6B80 | CNationalFocus::[11] vtable 槽 CNationalFocus::[11]（func_names RTTI 名） |
| 0x1403072B0 | CEmbargoAction::[46] vtable 槽 CEmbargoAction::[46]（func_names RTTI 名） |
| 0x14117F748 | CEvent::[0] vtable 槽 CEvent::[0]（func_names RTTI 名） |
| 0x141752718 | CDiplomacyPopupWindowBase::[0] vtable 槽 CDiplomacyPopupWindowBase::[0]（func_names RTTI 名） |
| 0x141F6B23C | CConfirmDeleteEquipmentProductionLine::[0] vtable 槽 CConfirmDeleteEquipmentProductionLine::[0]（func_names RTTI 名） |
| 0x141FA3090 | CIterationRewardOption::[0] vtable 槽 CIterationRewardOption::[0]（func_names RTTI 名） |
| 0x1422E1230 | CLargefileHandler::[12] vtable 槽 CLargefileHandler::[12]（func_names RTTI 名） |
| 0x142300350 | CSmoothListbox::[28] vtable 槽 CSmoothListbox::[28]（func_names RTTI 名） |
| 0x142384A00 | CPdxMouse::[25] vtable 槽 CPdxMouse::[25]（func_names RTTI 名） |
| 0x1423E09D0 | CSteamMatchmakingContext::[8] vtable 槽 CSteamMatchmakingContext::[8]（func_names RTTI 名） |
| 0x140AB2CE0 | CScriptedDiplomaticAction::[51] vtable 槽 CScriptedDiplomaticAction::[51]（func_names RTTI 名） |
| 0x140AB2ED0 | CScriptedDiplomaticAction::[52] vtable 槽 CScriptedDiplomaticAction::[52]（func_names RTTI 名） |
| 0x140B3D490 | CFrontEndIdler::[1] vtable 槽 CFrontEndIdler::[1]（func_names RTTI 名） |
| 0x141914820 | CUnitsStackMapIconGroup::[20] vtable 槽 CUnitsStackMapIconGroup::[20]（func_names RTTI 名） |
| 0x1419C8640 | CTutorialChapter::[0] vtable 槽 CTutorialChapter::[0]（func_names RTTI 名） |
| 0x141F7CFE0 | CConfirmDisbandFleet::[17] vtable 槽 CConfirmDisbandFleet::[17]（func_names RTTI 名） |
| 0x1420AB180 | CMapIdler::[17] vtable 槽 CMapIdler::[17]（func_names RTTI 名） |
| 0x142233350 | （无名） 体设 CSystem::vftable（RTTI 名） |
| 0x142354BA0 | CCorneredTileSprite::[42] vtable 槽 CCorneredTileSprite::[42]（func_names RTTI 名） |
| 0x14236DF40 | CLayoutType::[11] vtable 槽 CLayoutType::[11]（func_names RTTI 名） |
| 0x140E573C0 | CPowerBalance::[8] vtable 槽 CPowerBalance::[8]（func_names RTTI 名） |
| 0x1414E8460 | （无名） 体设 CProvinceListener::vftable（RTTI 名） |
| 0x141961F90 | （无名） 体设 CBuildingListener::vftable（RTTI 名） |
| 0x14225C580 | CGui::[19] vtable 槽 CGui::[19]（func_names RTTI 名） |
| 0x14232BAC0 | CCurveGraph::[33] vtable 槽 CCurveGraph::[33]（func_names RTTI 名） |
| 0x14232BB00 | CCurveGraph::[32] vtable 槽 CCurveGraph::[32]（func_names RTTI 名） |
| 0x1423636D0 | CDummyServer::[2] vtable 槽 CDummyServer::[2]（func_names RTTI 名） |
| 0x1423AAD70 | PdxTextToSpeechWinSAPI::[6] vtable 槽 PdxTextToSpeechWinSAPI::[6]（func_names RTTI 名） |
| 0x14151B130 | CTakeNavyPeaceAction::[24] vtable 槽 CTakeNavyPeaceAction::[24]（func_names RTTI 名） |
| 0x141E33E70 | CMapModeOperationSelectTarget::[3] vtable 槽 CMapModeOperationSelectTarget::[3]（func_names RTTI 名） |
| 0x1422DEF50 | CGridBoxBase::[28] vtable 槽 CGridBoxBase::[28]（func_names RTTI 名） |
| 0x142306810 | CButtonDrag::[100] vtable 槽 CButtonDrag::[100]（func_names RTTI 名） |
| 0x142395B30 | CPdxCrashReportWindows::[7] vtable 槽 CPdxCrashReportWindows::[7]（func_names RTTI 名） |
| 0x1401DBCD0 | CSprite::[60] vtable 槽 CSprite::[60]（func_names RTTI 名） |
| 0x1423636F0 | CDummyServer::[3] vtable 槽 CDummyServer::[3]（func_names RTTI 名） |
| 0x14029ECE0 | CGameIdler::[15] vtable 槽 CGameIdler::[15]（func_names RTTI 名） |
| 0x140B3BBE0 | CFrontEndIdler::[88] vtable 槽 CFrontEndIdler::[88]（func_names RTTI 名） |
| 0x140B3CA10 | CFrontEndIdler::[106] vtable 槽 CFrontEndIdler::[106]（func_names RTTI 名） |
| 0x1411397D0 | CDeclareWarAction::[57] vtable 槽 CDeclareWarAction::[57]（func_names RTTI 名） |
| 0x1414C9DA0 | CPendingAddMovement::[3] vtable 槽 CPendingAddMovement::[3]（func_names RTTI 名） |
| 0x1422CF200 | CBrowser::[33] vtable 槽 CBrowser::[33]（func_names RTTI 名） |
| 0x1422CF240 | CBrowser::[32] vtable 槽 CBrowser::[32]（func_names RTTI 名） |
| 0x142306FA0 | CButtonDrag::[33] vtable 槽 CButtonDrag::[33]（func_names RTTI 名） |
| 0x142306FE0 | CButtonDrag::[32] vtable 槽 CButtonDrag::[32]（func_names RTTI 名） |
| 0x14237F340 | CTrack::[33] vtable 槽 CTrack::[33]（func_names RTTI 名） |
| 0x14237F380 | CTrack::[32] vtable 槽 CTrack::[32]（func_names RTTI 名） |
| 0x142384DF0 | CPdxMouse::[6] vtable 槽 CPdxMouse::[6]（func_names RTTI 名） |
| 0x142384E20 | CPdxMouse::[5] vtable 槽 CPdxMouse::[5]（func_names RTTI 名） |
| 0x1412AE7E0 | CLandCombat::[12] vtable 槽 CLandCombat::[12]（func_names RTTI 名） |
| 0x1415C28E0 | CNavalCombat::[12] vtable 槽 CNavalCombat::[12]（func_names RTTI 名） |
| 0x1422D4AE0 | CInstantSprite::[0] vtable 槽 CInstantSprite::[0]（func_names RTTI 名） |
| 0x1422D5970 | CTextSprite::[0] vtable 槽 CTextSprite::[0]（func_names RTTI 名） |
| 0x14232BB50 | CCurveGraph::[1] vtable 槽 CCurveGraph::[1]（func_names RTTI 名） |
| 0x1423833C0 | CFormat::[2] vtable 槽 CFormat::[2]（func_names RTTI 名） |
| 0x140223990 | HOI4EditorInterface::[9] vtable 槽 HOI4EditorInterface::[9]（func_names RTTI 名） |
| 0x1402239A0 | HOI4EditorInterface::[7] vtable 槽 HOI4EditorInterface::[7]（func_names RTTI 名） |
| 0x1402A0280 | CGameIdler::[0] vtable 槽 CGameIdler::[0]（func_names RTTI 名） |
| 0x1402A0290 | CGameIdler::[19] vtable 槽 CGameIdler::[19]（func_names RTTI 名） |
| 0x1424DF8B0 | CArchiveFile::[17] vtable 槽 CArchiveFile::[17]（func_names RTTI 名） |
| 0x14064CD64 | CStrategicAI::[0] vtable 槽 CStrategicAI::[0]（func_names RTTI 名） |
| 0x140DC5140 | CInGameIdler::[0] vtable 槽 CInGameIdler::[0]（func_names RTTI 名） |
| 0x140DC514C | CInGameIdler::[0] vtable 槽 CInGameIdler::[0]（func_names RTTI 名） |
| 0x1412D436C | CNudgeIdler::[0] vtable 槽 CNudgeIdler::[0]（func_names RTTI 名） |
| 0x141752730 | CDiplomacyPopupWindowBase::[0] vtable 槽 CDiplomacyPopupWindowBase::[0]（func_names RTTI 名） |
| 0x1424BE4E0 | CGui::[1] vtable 槽 CGui::[1]（func_names RTTI 名） |
| 0x14015BFB4 | CAnonymousEquipmentGroup::[1] vtable 槽 CAnonymousEquipmentGroup::[1]（func_names RTTI 名） |
| 0x141915B48 | CDynamicEquipmentGroup::[1] vtable 槽 CDynamicEquipmentGroup::[1]（func_names RTTI 名） |
| 0x1419391D0 | CNavalProductionLine::[15] vtable 槽 CNavalProductionLine::[15]（func_names RTTI 名） |
| 0x1422304D8 | CNullMouse::[0] vtable 槽 CNullMouse::[0]（func_names RTTI 名） |
| 0x1422304E4 | CNullMouse::[0] vtable 槽 CNullMouse::[0]（func_names RTTI 名） |
| 0x1422CEA5C | CBrowser::[0] vtable 槽 CBrowser::[0]（func_names RTTI 名） |
| 0x1422D0A5C | CButtonStandard::[0] vtable 槽 CButtonStandard::[0]（func_names RTTI 名） |
| 0x1422D571C | CTextSprite::[0] vtable 槽 CTextSprite::[0]（func_names RTTI 名） |
| 0x1422F6980 | CWindowType::[0] vtable 槽 CWindowType::[0]（func_names RTTI 名） |
| 0x142305CB0 | CButtonDrag::[0] vtable 槽 CButtonDrag::[0]（func_names RTTI 名） |
| 0x14232B544 | CCurveGraph::[0] vtable 槽 CCurveGraph::[0]（func_names RTTI 名） |
| 0x1423558F0 | CMouse::[0] vtable 槽 CMouse::[0]（func_names RTTI 名） |
| 0x1423558FC | CMouse::[0] vtable 槽 CMouse::[0]（func_names RTTI 名） |
| 0x14237217C | CDropDownMenuType::[0] vtable 槽 CDropDownMenuType::[0]（func_names RTTI 名） |
| 0x1423764F4 | CListboxType::[0] vtable 槽 CListboxType::[0]（func_names RTTI 名） |
| 0x1423790F4 | CNullBrowser::[0] vtable 槽 CNullBrowser::[0]（func_names RTTI 名） |
| 0x142379100 | CNullBrowser::[0] vtable 槽 CNullBrowser::[0]（func_names RTTI 名） |
| 0x14237910C | CNullButtonDrag::[0] vtable 槽 CNullButtonDrag::[0]（func_names RTTI 名） |
| 0x142379118 | CNullButtonDrag::[0] vtable 槽 CNullButtonDrag::[0]（func_names RTTI 名） |
| 0x142379238 | CNullTrack::[0] vtable 槽 CNullTrack::[0]（func_names RTTI 名） |
| 0x14237ED60 | CTrack::[0] vtable 槽 CTrack::[0]（func_names RTTI 名） |
| 0x1423844FC | CPdxMouse::[0] vtable 槽 CPdxMouse::[0]（func_names RTTI 名） |
| 0x142384508 | CPdxMouse::[0] vtable 槽 CPdxMouse::[0]（func_names RTTI 名） |
| 0x1402CCD28 | CJointNationalFocus::[0] vtable 槽 CJointNationalFocus::[0]（func_names RTTI 名） |
| 0x1402CCD34 | CNationalFocus::[0] vtable 槽 CNationalFocus::[0]（func_names RTTI 名） |
| 0x1402CCD40 | CNationalFocusDatabase::[0] vtable 槽 CNationalFocusDatabase::[0]（func_names RTTI 名） |
| 0x140673F74 | CAutonomousStateDatabase::[0] vtable 槽 CAutonomousStateDatabase::[0]（func_names RTTI 名） |
| 0x1406C1160 | CContinuousFocusDatabase::[0] vtable 槽 CContinuousFocusDatabase::[0]（func_names RTTI 名） |
| 0x140725554 | CDecision::[0] vtable 槽 CDecision::[0]（func_names RTTI 名） |
| 0x140AC66B4 | CTechnologySharingGroupDatabase::[0] vtable 槽 CTechnologySharingGroupDatabase::[0]（func_names RTTI 名） |
| 0x140AD7738 | CTimedActivityEquipmentDistributable::[0] vtable 槽 CTimedActivityEquipmentDistributable::[0]（func_names RTTI 名） |
| 0x140BF93C8 | CUnit::[0] vtable 槽 CUnit::[0]（func_names RTTI 名） |
| 0x140CE7110 | CMilitaryDeployment::[0] vtable 槽 CMilitaryDeployment::[0]（func_names RTTI 名） |
| 0x140D6445C | CTaskForce::[0] vtable 槽 CTaskForce::[0]（func_names RTTI 名） |
| 0x140E880F4 | CRailwayGun::[0] vtable 槽 CRailwayGun::[0]（func_names RTTI 名） |
| 0x140ED4CA0 | CTechnology::[1] vtable 槽 CTechnology::[1]（func_names RTTI 名） |
| 0x140F6E7A8 | CMilitaryProductionLine::[1] vtable 槽 CMilitaryProductionLine::[1]（func_names RTTI 名） |
| 0x140F6EEB8 | CNavalProductionLine::[1] vtable 槽 CNavalProductionLine::[1]（func_names RTTI 名） |
| 0x140F6F7F4 | CRailwayGunProductionLine::[1] vtable 槽 CRailwayGunProductionLine::[1]（func_names RTTI 名） |
| 0x140F71A40 | CShipRefitProductionLine::[1] vtable 槽 CShipRefitProductionLine::[1]（func_names RTTI 名） |
| 0x140FF3378 | CCountryOccupationStatus::[0] vtable 槽 CCountryOccupationStatus::[0]（func_names RTTI 名） |
| 0x1412AAA44 | CLandCombat::[0] vtable 槽 CLandCombat::[0]（func_names RTTI 名） |
| 0x1413331E0 | CChat::CChannelItem::[0] vtable 槽 CChat::CChannelItem::[0]（func_names RTTI 名） |
| 0x1413331EC | CChat::[0] vtable 槽 CChat::[0]（func_names RTTI 名） |
| 0x1413331F8 | CChat::CChatItem::[0] vtable 槽 CChat::CChatItem::[0]（func_names RTTI 名） |
| 0x141333204 | CChat::CUserItem::[0] vtable 槽 CChat::CUserItem::[0]（func_names RTTI 名） |
| 0x141333210 | CChat::CUserItem::[1] vtable 槽 CChat::CUserItem::[1]（func_names RTTI 名） |
| 0x1413EBA64 | CLandBorderWarCombat::[0] vtable 槽 CLandBorderWarCombat::[0]（func_names RTTI 名） |
| 0x14145421C | CConferenceLiberatedParticipant::[0] vtable 槽 CConferenceLiberatedParticipant::[0]（func_names RTTI 名） |
| 0x141454228 | CConferenceWinnerParticipant::[0] vtable 槽 CConferenceWinnerParticipant::[0]（func_names RTTI 名） |
| 0x141509C34 | CArmyReinforcementRequests::[0] vtable 槽 CArmyReinforcementRequests::[0]（func_names RTTI 名） |
| 0x141509C40 | CArmyUpgradesRequests::[0] vtable 槽 CArmyUpgradesRequests::[0]（func_names RTTI 名） |
| 0x141509C4C | CArmyUpgradesStatus::[0] vtable 槽 CArmyUpgradesStatus::[0]（func_names RTTI 名） |
| 0x141509C58 | CGarrisonReinforcementRequests::[0] vtable 槽 CGarrisonReinforcementRequests::[0]（func_names RTTI 名） |
| 0x141509C70 | CReinforcementRequest::[0] vtable 槽 CReinforcementRequest::[0]（func_names RTTI 名） |
| 0x141509C7C | CReinforcementStatus::[0] vtable 槽 CReinforcementStatus::[0]（func_names RTTI 名） |
| 0x14155C85C | COccupiedTerritoryStateEntryWithoutResistance::[1] vtable 槽 COccupiedTerritoryStateEntryWithoutResistance::[1]（func_names RTTI 名） |
| 0x141573BD0 | CMapModesInterface::[0] vtable 槽 CMapModesInterface::[0]（func_names RTTI 名） |
| 0x1415BB2B0 | CConfirmRemoveAllRegions::[1] vtable 槽 CConfirmRemoveAllRegions::[1]（func_names RTTI 名） |
| 0x1415C25A0 | CNavalCombat::[0] vtable 槽 CNavalCombat::[0]（func_names RTTI 名） |
| 0x141640D84 | CGameBitmapFont::[0] vtable 槽 CGameBitmapFont::[0]（func_names RTTI 名） |
| 0x1417058EC | CCountryMilitaryOverview::[1] vtable 槽 CCountryMilitaryOverview::[1]（func_names RTTI 名） |
| 0x1417058F8 | CCountryMilitaryOverview::[0] vtable 槽 CCountryMilitaryOverview::[0]（func_names RTTI 名） |
| 0x141752724 | CDiplomacyPopupWindowBase::[1] vtable 槽 CDiplomacyPopupWindowBase::[1]（func_names RTTI 名） |
| 0x1417CBE8C | CMinimapInterface::[1] vtable 槽 CMinimapInterface::[1]（func_names RTTI 名） |
| 0x1417CBE98 | CMinimapInterface::[0] vtable 槽 CMinimapInterface::[0]（func_names RTTI 名） |
| 0x1417F3D68 | CNavalLossesOverview::[1] vtable 槽 CNavalLossesOverview::[1]（func_names RTTI 名） |
| 0x14186CB0C | CPlayerLobby::[1] vtable 槽 CPlayerLobby::[1]（func_names RTTI 名） |
| 0x14186CB18 | CPlayerLobby::[1] vtable 槽 CPlayerLobby::[1]（func_names RTTI 名） |
| 0x14188A460 | CTheatreSelector::[0] vtable 槽 CTheatreSelector::[0]（func_names RTTI 名） |
| 0x141933FEC | CEquipmentProductionLine::[1] vtable 槽 CEquipmentProductionLine::[1]（func_names RTTI 名） |
| 0x14193E678 | CHqDeploymentDistributable::[0] vtable 槽 CHqDeploymentDistributable::[0]（func_names RTTI 名） |
| 0x141A2DB8C | CConfirmDeleteAllOrders::[0] vtable 槽 CConfirmDeleteAllOrders::[0]（func_names RTTI 名） |
| 0x141A2DB98 | CConfirmDeleteAllOrders::[1] vtable 槽 CConfirmDeleteAllOrders::[1]（func_names RTTI 名） |
| 0x141A2DBA4 | CConfirmDeleteOrder::[0] vtable 槽 CConfirmDeleteOrder::[0]（func_names RTTI 名） |
| 0x141A2E7C4 | CConfirmAssignUnitsToFront::[0] vtable 槽 CConfirmAssignUnitsToFront::[0]（func_names RTTI 名） |
| 0x141A2E7D0 | CConfirmAssignUnitsToFront::[1] vtable 槽 CConfirmAssignUnitsToFront::[1]（func_names RTTI 名） |
| 0x141B3D374 | CAmbientObjectNudger::[0] vtable 槽 CAmbientObjectNudger::[0]（func_names RTTI 名） |
| 0x141B4524C | CBuildingsNudger::[0] vtable 槽 CBuildingsNudger::[0]（func_names RTTI 名） |
| 0x141B45264 | CRandomAllConfirm::[0] vtable 槽 CRandomAllConfirm::[0]（func_names RTTI 名） |
| 0x141B57DC4 | CStateNudger::[0] vtable 槽 CStateNudger::[0]（func_names RTTI 名） |
| 0x141B60F2C | CStrategicRegionNudger::[0] vtable 槽 CStrategicRegionNudger::[0]（func_names RTTI 名） |
| 0x141B6B948 | CSupplyNudger::[0] vtable 槽 CSupplyNudger::[0]（func_names RTTI 名） |
| 0x141B71720 | CUnitsNudger::[0] vtable 槽 CUnitsNudger::[0]（func_names RTTI 名） |
| 0x141C10D00 | CCountryCharacterSelector::[1] vtable 槽 CCountryCharacterSelector::[1]（func_names RTTI 名） |
| 0x141C2F174 | CImportDesignPopUp::[1] vtable 槽 CImportDesignPopUp::[1]（func_names RTTI 名） |
| 0x141C2F180 | CChangeDesignFolderPopUp::[0] vtable 槽 CChangeDesignFolderPopUp::[0]（func_names RTTI 名） |
| 0x141C2F18C | CChangeDesignFolderPopUp::[1] vtable 槽 CChangeDesignFolderPopUp::[1]（func_names RTTI 名） |
| 0x141C2F198 | CCreateFolderPopUp::[0] vtable 槽 CCreateFolderPopUp::[0]（func_names RTTI 名） |
| 0x141C2F1A4 | CCreateFolderPopUp::[1] vtable 槽 CCreateFolderPopUp::[1]（func_names RTTI 名） |
| 0x141C2F1B0 | CDeleteDesignPopUp::[0] vtable 槽 CDeleteDesignPopUp::[0]（func_names RTTI 名） |
| 0x141C2F1BC | CDeleteDesignPopUp::[1] vtable 槽 CDeleteDesignPopUp::[1]（func_names RTTI 名） |
| 0x141C2F1D4 | CDeleteOrRenameFolderPopUp::[1] vtable 槽 CDeleteOrRenameFolderPopUp::[1]（func_names RTTI 名） |
| 0x141C2F1F8 | CSaveDesignToFilePopUp::[0] vtable 槽 CSaveDesignToFilePopUp::[0]（func_names RTTI 名） |
| 0x141C2F204 | CSaveDesignToFilePopUp::[1] vtable 槽 CSaveDesignToFilePopUp::[1]（func_names RTTI 名） |
| 0x141CA6AB8 | CRelationStripViewBase::CStripFlagItem::[0] vtable 槽 CRelationStripViewBase::CStripFlagItem::[0]（func_names RTTI 名） |
| 0x141CA6AC4 | CRelationStripViewBase::CStripFlagItem::[1] vtable 槽 CRelationStripViewBase::CStripFlagItem::[1]（func_names RTTI 名） |
| 0x141CFDD64 | CConfirmDeleteOrdersGroup::[0] vtable 槽 CConfirmDeleteOrdersGroup::[0]（func_names RTTI 名） |
| 0x141D08050 | CConfirmConsolidateUnits::[0] vtable 槽 CConfirmConsolidateUnits::[0]（func_names RTTI 名） |
| 0x141D0AEA8 | CConfirmDeleteUnits::[0] vtable 槽 CConfirmDeleteUnits::[0]（func_names RTTI 名） |
| 0x141D0AEB4 | CConfirmDeleteUnits::[1] vtable 槽 CConfirmDeleteUnits::[1]（func_names RTTI 名） |
| 0x141D0E1B4 | CConfirmUnassignUnits::[0] vtable 槽 CConfirmUnassignUnits::[0]（func_names RTTI 名） |
| 0x141D0E1C0 | CConfirmUnassignUnits::[1] vtable 槽 CConfirmUnassignUnits::[1]（func_names RTTI 名） |
| 0x141D10D70 | CHistoryEntryItemBase::[0] vtable 槽 CHistoryEntryItemBase::[0]（func_names RTTI 名） |
| 0x141DE9F4C | CConfirmSaveGame::[1] vtable 槽 CConfirmSaveGame::[1]（func_names RTTI 名） |
| 0x141E0ADA8 | CNavyTheaterNavyItemBase::[0] vtable 槽 CNavyTheaterNavyItemBase::[0]（func_names RTTI 名） |
| 0x141E0ADB4 | CNavyTheaterNavyItemBase::[1] vtable 槽 CNavyTheaterNavyItemBase::[1]（func_names RTTI 名） |
| 0x141E72374 | CNavyTheaterGroupItemBase::[1] vtable 槽 CNavyTheaterGroupItemBase::[1]（func_names RTTI 名） |
| 0x141E806B8 | CIntelMapModeMapIconMore::[0] vtable 槽 CIntelMapModeMapIconMore::[0]（func_names RTTI 名） |
| 0x141E806C4 | CIntelMapModeMapIconMore::[1] vtable 槽 CIntelMapModeMapIconMore::[1]（func_names RTTI 名） |
| 0x141EB16EC | CIntelLedgerArmyPanelController::[1] vtable 槽 CIntelLedgerArmyPanelController::[1]（func_names RTTI 名） |
| 0x141EBB258 | CIntelLedgerCivilianPanelController::[1] vtable 槽 CIntelLedgerCivilianPanelController::[1]（func_names RTTI 名） |
| 0x141EC71B4 | CIntelLedgerNavyPanelController::[1] vtable 槽 CIntelLedgerNavyPanelController::[1]（func_names RTTI 名） |
| 0x141F5B5CC | CHostConfigurationPupup::[1] vtable 槽 CHostConfigurationPupup::[1]（func_names RTTI 名） |
| 0x141F68104 | CTraitAssignmentConfirmation::[0] vtable 槽 CTraitAssignmentConfirmation::[0]（func_names RTTI 名） |
| 0x141F6B248 | CConfirmDeleteEquipmentProductionLine::[1] vtable 槽 CConfirmDeleteEquipmentProductionLine::[1]（func_names RTTI 名） |
| 0x141F6B254 | CConfirmSwitchEquipment::[0] vtable 槽 CConfirmSwitchEquipment::[0]（func_names RTTI 名） |
| 0x141F6C334 | CConfirmDeleteEquipment::[0] vtable 槽 CConfirmDeleteEquipment::[0]（func_names RTTI 名） |
| 0x141F6C340 | CConfirmDeleteEquipment::[1] vtable 槽 CConfirmDeleteEquipment::[1]（func_names RTTI 名） |
| 0x141F6D094 | CProductionSubUnitDefFilter::[1] vtable 槽 CProductionSubUnitDefFilter::[1]（func_names RTTI 名） |
| 0x141F75218 | CConfirmRemoveBuildingLevel::[0] vtable 槽 CConfirmRemoveBuildingLevel::[0]（func_names RTTI 名） |
| 0x141F7CE28 | CConfirmDisbandFleet::[0] vtable 槽 CConfirmDisbandFleet::[0]（func_names RTTI 名） |
| 0x1420895FC | CTweakableArrayCurveManipulator::[0] vtable 槽 CTweakableArrayCurveManipulator::[0]（func_names RTTI 名） |
| 0x142089608 | CTweakableBoolManipulator::[0] vtable 槽 CTweakableBoolManipulator::[0]（func_names RTTI 名） |
| 0x142089614 | CTweakableCategory::[0] vtable 槽 CTweakableCategory::[0]（func_names RTTI 名） |
| 0x142089620 | CTweakableCharArrayManipulator::[0] vtable 槽 CTweakableCharArrayManipulator::[0]（func_names RTTI 名） |
| 0x14208962C | CTweakableDropDown::[0] vtable 槽 CTweakableDropDown::[0]（func_names RTTI 名） |
| 0x142089638 | CTweakableEnumManipulator::[0] vtable 槽 CTweakableEnumManipulator::[0]（func_names RTTI 名） |
| 0x142089644 | CTweakableGraphManipulator::[0] vtable 槽 CTweakableGraphManipulator::[0]（func_names RTTI 名） |
| 0x142089668 | CTweakableTextbox::[0] vtable 槽 CTweakableTextbox::[0]（func_names RTTI 名） |
| 0x142089674 | CTweakableTitle::[0] vtable 槽 CTweakableTitle::[0]（func_names RTTI 名） |
| 0x1422304B4 | CPdxKeyBoard::[0] vtable 槽 CPdxKeyBoard::[0]（func_names RTTI 名） |
| 0x1422304C0 | CNullMouse::[0] vtable 槽 CNullMouse::[0]（func_names RTTI 名） |
| 0x1422304CC | CNullMouse::[0] vtable 槽 CNullMouse::[0]（func_names RTTI 名） |
| 0x1422989DC | CBitmapFont::[0] vtable 槽 CBitmapFont::[0]（func_names RTTI 名） |
| 0x1422E7DB8 | CChatBuffer::[0] vtable 槽 CChatBuffer::[0]（func_names RTTI 名） |
| 0x1423558D8 | CMouse::[0] vtable 槽 CMouse::[0]（func_names RTTI 名） |
| 0x1423558E4 | CMouse::[0] vtable 槽 CMouse::[0]（func_names RTTI 名） |
| 0x1423844E4 | CPdxMouse::[0] vtable 槽 CPdxMouse::[0]（func_names RTTI 名） |
| 0x1423844F0 | CPdxMouse::[0] vtable 槽 CPdxMouse::[0]（func_names RTTI 名） |
| 0x14015BFCC | CGameApplication::[0] vtable 槽 CGameApplication::[0]（func_names RTTI 名） |
| 0x1402AA2B0 | CStrategicAI::[6] vtable 槽 CStrategicAI::[6]（func_names RTTI 名） |
| 0x1406132D8 | CAbility::[0] vtable 槽 CAbility::[0]（func_names RTTI 名） |
| 0x1406CEA98 | CCustomizableBuildingCollection::[1] vtable 槽 CCustomizableBuildingCollection::[1]（func_names RTTI 名） |
| 0x140725548 | CDecision::[0] vtable 槽 CDecision::[0]（func_names RTTI 名） |
| 0x140725560 | CDecisionCategory::[0] vtable 槽 CDecisionCategory::[0]（func_names RTTI 名） |
| 0x14072556C | CTargetedDecision::[0] vtable 槽 CTargetedDecision::[0]（func_names RTTI 名） |
| 0x140A4085C | CTechnologyTemplate::[0] vtable 槽 CTechnologyTemplate::[0]（func_names RTTI 名） |
| 0x140B51AF4 | CGraphicalMap::[0] vtable 槽 CGraphicalMap::[0]（func_names RTTI 名） |
| 0x140C1D5A0 | CArmyLeader::[29] vtable 槽 CArmyLeader::[29]（func_names RTTI 名） |
| 0x140D98FF8 | CGameLobby::[0] vtable 槽 CGameLobby::[0]（func_names RTTI 名） |
| 0x140DD8320 | CInGameIdler::[98] vtable 槽 CInGameIdler::[98]（func_names RTTI 名） |
| 0x140DD8610 | CInGameIdler::[81] vtable 槽 CInGameIdler::[81]（func_names RTTI 名） |
| 0x140E1FFCC | CStrategicRegion::[0] vtable 槽 CStrategicRegion::[0]（func_names RTTI 名） |
| 0x1410A3A6C | CRadarsPool::[0] vtable 槽 CRadarsPool::[0]（func_names RTTI 名） |
| 0x14121AF14 | CCountrySupplySystem::[0] vtable 槽 CCountrySupplySystem::[0]（func_names RTTI 名） |
| 0x1416467D8 | CAmbientObject::[0] vtable 槽 CAmbientObject::[0]（func_names RTTI 名） |
| 0x1419C864C | CTutorialHint::[0] vtable 槽 CTutorialHint::[0]（func_names RTTI 名） |
| 0x141DF7F1C | CStandardMusicPlaybackController::[1] vtable 槽 CStandardMusicPlaybackController::[1]（func_names RTTI 名） |
| 0x1420A1960 | CMapApplication::[0] vtable 槽 CMapApplication::[0]（func_names RTTI 名） |
| 0x1420A6D58 | CMapIdler::[0] vtable 槽 CMapIdler::[0]（func_names RTTI 名） |
| 0x14225A388 | CGui::[0] vtable 槽 CGui::[0]（func_names RTTI 名） |
| 0x1422A987C | CStandardlistbox::[7] vtable 槽 CStandardlistbox::[7]（func_names RTTI 名） |
| 0x1422D1140 | CButtonStandard::[74] vtable 槽 CButtonStandard::[74]（func_names RTTI 名） |
| 0x1422FF70C | CSmoothListbox::[7] vtable 槽 CSmoothListbox::[7]（func_names RTTI 名） |
| 0x1401864C0 | CGameApplication::[16] vtable 槽 CGameApplication::[16]（func_names RTTI 名） |
| 0x140620240 | CAchievementMod::[12] vtable 槽 CAchievementMod::[12]（func_names RTTI 名） |
| 0x1416422D0 | CSpriteType::[27] vtable 槽 CSpriteType::[27]（func_names RTTI 名） |
| 0x14236AEF0 | CProxyServer::[12] vtable 槽 CProxyServer::[12]（func_names RTTI 名） |
| 0x142384720 | CPdxMouse::[30] vtable 槽 CPdxMouse::[30]（func_names RTTI 名） |
| 0x1423847E0 | CPdxMouse::[17] vtable 槽 CPdxMouse::[17]（func_names RTTI 名） |
| 0x1423847F0 | CPdxMouse::[18] vtable 槽 CPdxMouse::[18]（func_names RTTI 名） |
| 0x1423C2D20 | CSteamBrowserInstance::[1] vtable 槽 CSteamBrowserInstance::[1]（func_names RTTI 名） |
| 0x1423DD8D0 | CSteamCloudFile::[9] vtable 槽 CSteamCloudFile::[9]（func_names RTTI 名） |
| 0x140DDFA50 | CInGameIdler::[47] vtable 槽 CInGameIdler::[47]（func_names RTTI 名） |
| 0x140EE1670 | CTechnology::[2] vtable 槽 CTechnology::[2]（func_names RTTI 名） |
| 0x141129D30 | CRequestAccessToLicenseProductionAction::[46] vtable 槽 CRequestAccessToLicenseProductionAction::[46]（func_names RTTI 名） |
| 0x1413ED800 | CLandBorderWarCombat::[10] vtable 槽 CLandBorderWarCombat::[10]（func_names RTTI 名） |
| 0x1414D4CE0 | CPendingAddStrategicRedeploy::[1] vtable 槽 CPendingAddStrategicRedeploy::[1]（func_names RTTI 名） |
| 0x1415400F0 | CCountryCapitalChange::[13] vtable 槽 CCountryCapitalChange::[13]（func_names RTTI 名） |
| 0x141540100 | CCountryConvoysChange::[13] vtable 槽 CCountryConvoysChange::[13]（func_names RTTI 名） |
| 0x141540110 | CCountryDecisionChange::[13] vtable 槽 CCountryDecisionChange::[13]（func_names RTTI 名） |
| 0x141540130 | CCountryNukesChange::[13] vtable 槽 CCountryNukesChange::[13]（func_names RTTI 名） |
| 0x141540140 | CCountryStartingTrainChange::[13] vtable 槽 CCountryStartingTrainChange::[13]（func_names RTTI 名） |
| 0x141540150 | CCountryStartingTruckChange::[13] vtable 槽 CCountryStartingTruckChange::[13]（func_names RTTI 名） |
| 0x141540170 | COOBChange::[13] vtable 槽 COOBChange::[13]（func_names RTTI 名） |
| 0x141540180 | CRevolutionaryTagChange::[13] vtable 槽 CRevolutionaryTagChange::[13]（func_names RTTI 名） |
| 0x1415A14A0 | CControllerChange::[13] vtable 槽 CControllerChange::[13]（func_names RTTI 名） |
| 0x1415A14C0 | CSetStateBuildings::[13] vtable 槽 CSetStateBuildings::[13]（func_names RTTI 名） |
| 0x1415A14D0 | CSetStateVictoryPoints::[13] vtable 槽 CSetStateVictoryPoints::[13]（func_names RTTI 名） |
| 0x1415A14E0 | CStateHistory::[13] vtable 槽 CStateHistory::[13]（func_names RTTI 名） |
| 0x14161EEA0 | CNavalCombat::[10] vtable 槽 CNavalCombat::[10]（func_names RTTI 名） |
| 0x141642AB0 | CSprite::[70] vtable 槽 CSprite::[70]（func_names RTTI 名） |
| 0x1419D7FB0 | CDarkFullscreenOverlayUpdateable::[1] vtable 槽 CDarkFullscreenOverlayUpdateable::[1]（func_names RTTI 名） |
| 0x141EE2960 | CAiFrontImportanceMapModeConfig::[1] vtable 槽 CAiFrontImportanceMapModeConfig::[1]（func_names RTTI 名） |
| 0x1422ABE40 | CSprite::[59] vtable 槽 CSprite::[59]（func_names RTTI 名） |
| 0x142355EA0 | CPdxSystem::[6] vtable 槽 CPdxSystem::[6]（func_names RTTI 名） |
| 0x142355EB0 | CPdxSystem::[9] vtable 槽 CPdxSystem::[9]（func_names RTTI 名） |
| 0x142384DE0 | CPdxMouse::[8] vtable 槽 CPdxMouse::[8]（func_names RTTI 名） |
| 0x140A0B110 | CDynamicEquipmentGroup::[2] vtable 槽 CDynamicEquipmentGroup::[2]（func_names RTTI 名） |
| 0x1415DF010 | CWarGoal::[8] vtable 槽 CWarGoal::[8]（func_names RTTI 名） |
| 0x1422E1B50 | CLargefileHandler::[10] vtable 槽 CLargefileHandler::[10]（func_names RTTI 名） |
| 0x142380FF0 | StackWalker::[5] vtable 槽 StackWalker::[5]（func_names RTTI 名） |
| 0x1423ABFD0 | PdxSpeechToTextWinSAPI::[0] vtable 槽 PdxSpeechToTextWinSAPI::[0]（func_names RTTI 名） |
| 0x1401DB960 | CGameState::[9] vtable 槽 CGameState::[9]（func_names RTTI 名） |
| 0x140BEF610 | CArmyGroup::[11] vtable 槽 CArmyGroup::[11]（func_names RTTI 名） |
| 0x141A37050 | CSmoothListbox::[23] vtable 槽 CSmoothListbox::[23]（func_names RTTI 名） |
| 0x1422D4BB0 | CTextSprite::[22] vtable 槽 CTextSprite::[22]（func_names RTTI 名） |
| 0x1422FE4F0 | CSprite::[22] vtable 槽 CSprite::[22]（func_names RTTI 名） |
| 0x142360EA0 | CTextSpriteType::[21] vtable 槽 CTextSpriteType::[21]（func_names RTTI 名） |
| 0x142360EC0 | CTextSpriteType::[15] vtable 槽 CTextSpriteType::[15]（func_names RTTI 名） |
| 0x14236AA50 | CProxyServer::[28] vtable 槽 CProxyServer::[28]（func_names RTTI 名） |
| 0x14236AAA0 | CProxyServer::[22] vtable 槽 CProxyServer::[22]（func_names RTTI 名） |
| 0x142385CE0 | CResizeableSprite::[22] vtable 槽 CResizeableSprite::[22]（func_names RTTI 名） |
| 0x141427DB0 | CSteamStoreContext::[14] vtable 槽 CSteamStoreContext::[14]（func_names RTTI 名） |
| 0x141540160 | CHistoryAddEffectState::[13] vtable 槽 CHistoryAddEffectState::[13]（func_names RTTI 名） |
| 0x1418C24F0 | CDecisionMapIconContainer::[6] vtable 槽 CDecisionMapIconContainer::[6]（func_names RTTI 名） |
| 0x1422AEC80 | CSprite::[21] vtable 槽 CSprite::[21]（func_names RTTI 名） |
| 0x140DE0260 | CInGameIdler::[100] vtable 槽 CInGameIdler::[100]（func_names RTTI 名） |
| 0x1422D4D20 | CInstantSprite::[1] vtable 槽 CInstantSprite::[1]（func_names RTTI 名） |
| 0x1422FDF90 | CSprite::[28] vtable 槽 CSprite::[28]（func_names RTTI 名） |
| 0x1422FDFB0 | CSprite::[33] vtable 槽 CSprite::[33]（func_names RTTI 名） |
| 0x1422FE770 | CSprite::[1] vtable 槽 CSprite::[1]（func_names RTTI 名） |
| 0x1422FE8F0 | CSprite::[82] vtable 槽 CSprite::[82]（func_names RTTI 名） |
| 0x1422FE920 | CSprite::[16] vtable 槽 CSprite::[16]（func_names RTTI 名） |
| 0x142360440 | CProgressbarSprite::[28] vtable 槽 CProgressbarSprite::[28]（func_names RTTI 名） |
| 0x142385D70 | CResizeableSprite::[16] vtable 槽 CResizeableSprite::[16]（func_names RTTI 名） |
| 0x141642CC0 | CSprite::[13] vtable 槽 CSprite::[13]（func_names RTTI 名） |
| 0x1422ACE00 | CStandardlistbox::[27] vtable 槽 CStandardlistbox::[27]（func_names RTTI 名） |
| 0x1422B0C10 | CTrack::[80] vtable 槽 CTrack::[80]（func_names RTTI 名） |
| 0x1422D4E20 | CInstantSprite::[19] vtable 槽 CInstantSprite::[19]（func_names RTTI 名） |
| 0x1422D6810 | CTextSprite::[52] vtable 槽 CTextSprite::[52]（func_names RTTI 名） |
| 0x142360450 | CProgressbarSpriteType::[24] vtable 槽 CProgressbarSpriteType::[24]（func_names RTTI 名） |
| 0x142385D60 | CResizeableSprite::[19] vtable 槽 CResizeableSprite::[19]（func_names RTTI 名） |
| 0x140164340 | CGameDate::[1] vtable 槽 CGameDate::[1]（func_names RTTI 名） |
| 0x140C047D0 | CSupplyConsumer::[12] vtable 槽 CSupplyConsumer::[12]（func_names RTTI 名） |
| 0x140E8B210 | CRailwayGun::[47] vtable 槽 CRailwayGun::[47]（func_names RTTI 名） |
| 0x1412B7D70 | CLandCombatant::[26] vtable 槽 CLandCombatant::[26]（func_names RTTI 名） |
| 0x142306AA0 | CButtonDrag::[13] vtable 槽 CButtonDrag::[13]（func_names RTTI 名） |
| 0x14232BB60 | CCurveGraph::[2] vtable 槽 CCurveGraph::[2]（func_names RTTI 名） |
| 0x140153440 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14015BFD8 | CGameDate::[0] vtable 槽 CGameDate::[0]（func_names RTTI 名） |
| 0x140B3BAB0 | CFrontEndIdler::[37] vtable 槽 CFrontEndIdler::[37]（func_names RTTI 名） |
| 0x140B3C2E0 | CFrontEndIdler::[24] vtable 槽 CFrontEndIdler::[24]（func_names RTTI 名） |
| 0x140B3C2F0 | CFrontEndIdler::[110] vtable 槽 CFrontEndIdler::[110]（func_names RTTI 名） |
| 0x140D9E490 | CGameLobby::[12] vtable 槽 CGameLobby::[12]（func_names RTTI 名） |
| 0x140DC53B0 | CInGameIdler::[37] vtable 槽 CInGameIdler::[37]（func_names RTTI 名） |
| 0x140DC55F0 | CInGameIdler::[34] vtable 槽 CInGameIdler::[34]（func_names RTTI 名） |
| 0x140DC5720 | CInGameIdler::[25] vtable 槽 CInGameIdler::[25]（func_names RTTI 名） |
| 0x140DCCF30 | CInGameIdler::[23] vtable 槽 CInGameIdler::[23]（func_names RTTI 名） |
| 0x140DCCF60 | CInGameIdler::[109] vtable 槽 CInGameIdler::[109]（func_names RTTI 名） |
| 0x141100310 | CEmbargoAction::[44] vtable 槽 CEmbargoAction::[44]（func_names RTTI 名） |
| 0x1411403D0 | CEmbargoAction::[14] vtable 槽 CEmbargoAction::[14]（func_names RTTI 名） |
| 0x1412D44F0 | CNudgeIdler::[37] vtable 槽 CNudgeIdler::[37]（func_names RTTI 名） |
| 0x14186FF10 | CPlayerLobby::[10] vtable 槽 CPlayerLobby::[10]（func_names RTTI 名） |
| 0x1419B2750 | ChatSettingsProviderImpl::[5] vtable 槽 ChatSettingsProviderImpl::[5]（func_names RTTI 名） |
| 0x1419B2790 | ChatSettingsProviderImpl::[4] vtable 槽 ChatSettingsProviderImpl::[4]（func_names RTTI 名） |
| 0x1422FDFA0 | C2dObject::[1] vtable 槽 C2dObject::[1]（func_names RTTI 名） |
| 0x1423AAD90 | PdxTextToSpeechWinSAPI::[10] vtable 槽 PdxTextToSpeechWinSAPI::[10]（func_names RTTI 名） |
| 0x1401776E0 | CGameApplication::[17] vtable 槽 CGameApplication::[17]（func_names RTTI 名） |
| 0x140725578 | CTimedDecision::[0] vtable 槽 CTimedDecision::[0]（func_names RTTI 名） |
| 0x14072AA20 | CInstantSprite::[87] vtable 槽 CInstantSprite::[87]（func_names RTTI 名） |
| 0x140A631B0 | CArchiveFile::[9] vtable 槽 CArchiveFile::[9]（func_names RTTI 名） |
| 0x140B64570 | CButtonStandard::[87] vtable 槽 CButtonStandard::[87]（func_names RTTI 名） |
| 0x140C4B030 | CShieldObject::[87] vtable 槽 CShieldObject::[87]（func_names RTTI 名） |
| 0x141502DB0 | CIncomingLendLeaseAction::[66] vtable 槽 CIncomingLendLeaseAction::[66]（func_names RTTI 名） |
| 0x142236A98 | CGuiAnimationReloader::[0] vtable 槽 CGuiAnimationReloader::[0]（func_names RTTI 名） |
| 0x1422ACE60 | CStandardlistbox::[10] vtable 槽 CStandardlistbox::[10]（func_names RTTI 名） |
| 0x1422E14A0 | CSendChunk::[12] vtable 槽 CSendChunk::[12]（func_names RTTI 名） |
| 0x1422FE510 | CSprite::[87] vtable 槽 CSprite::[87]（func_names RTTI 名） |
| 0x142305D30 | CButtonDrag::[93] vtable 槽 CButtonDrag::[93]（func_names RTTI 名） |
| 0x14235F4F0 | CProgressbarSprite::[87] vtable 槽 CProgressbarSprite::[87]（func_names RTTI 名） |
| 0x1423799D0 | CTrack::[93] vtable 槽 CTrack::[93]（func_names RTTI 名） |
| 0x14029ECD0 | CGameIdler::[1] vtable 槽 CGameIdler::[1]（func_names RTTI 名） |
| 0x140CAACC0 | CCountryResources::[5] vtable 槽 CCountryResources::[5]（func_names RTTI 名） |
| 0x1411394D0 | CAskForStateControlAction::[57] vtable 槽 CAskForStateControlAction::[57]（func_names RTTI 名） |
| 0x141139BD0 | CGiveStateControlAction::[57] vtable 槽 CGiveStateControlAction::[57]（func_names RTTI 名） |
| 0x141642A60 | CSprite::[2] vtable 槽 CSprite::[2]（func_names RTTI 名） |
| 0x1422D1210 | CButtonStandard::[102] vtable 槽 CButtonStandard::[102]（func_names RTTI 名） |
| 0x1422D1220 | CButtonStandard::[100] vtable 槽 CButtonStandard::[100]（func_names RTTI 名） |
| 0x1422D4BC0 | CTextSprite::[17] vtable 槽 CTextSprite::[17]（func_names RTTI 名） |
| 0x142385CF0 | CResizeableSprite::[17] vtable 槽 CResizeableSprite::[17]（func_names RTTI 名） |
| 0x1422CD810 | CRemoteFile::[15] vtable 槽 CRemoteFile::[15]（func_names RTTI 名） |
| 0x1422FD940 | C2dObject::[2] vtable 槽 C2dObject::[2]（func_names RTTI 名） |
| 0x1422FE400 | CSprite::[12] vtable 槽 CSprite::[12]（func_names RTTI 名） |
| 0x142396D50 | CPdxCrashReportWindows::[9] vtable 槽 CPdxCrashReportWindows::[9]（func_names RTTI 名） |
| 0x142361310 | C2dPieChartType::[10] vtable 槽 C2dPieChartType::[10]（func_names RTTI 名） |
| 0x142396E00 | CPdxCrashReportWindows::[6] vtable 槽 CPdxCrashReportWindows::[6]（func_names RTTI 名） |
| 0x140B3D750 | CFrontEndIdler::[80] vtable 槽 CFrontEndIdler::[80]（func_names RTTI 名） |
| 0x140BF2C10 | CArmyGroup::[1] vtable 槽 CArmyGroup::[1]（func_names RTTI 名） |
| 0x140DCA840 | CInGameIdler::[84] vtable 槽 CInGameIdler::[84]（func_names RTTI 名） |
| 0x140DE4AD0 | CInGameIdler::[22] vtable 槽 CInGameIdler::[22]（func_names RTTI 名） |
| 0x14113F620 | CCallAllyAction::[45] vtable 槽 CCallAllyAction::[45]（func_names RTTI 名） |
| 0x14113F700 | CRequestForeignManpowerAction::[45] vtable 槽 CRequestForeignManpowerAction::[45]（func_names RTTI 名） |
| 0x141140360 | CSendAttacheAction::[32] vtable 槽 CSendAttacheAction::[32]（func_names RTTI 名） |
| 0x14232B960 | CCurveGraph::[24] vtable 槽 CCurveGraph::[24]（func_names RTTI 名） |
| 0x14232BF60 | CCurveGraph::[25] vtable 槽 CCurveGraph::[25]（func_names RTTI 名） |
| 0x140DC90D0 | CInGameIdler::[74] vtable 槽 CInGameIdler::[74]（func_names RTTI 名） |
| 0x140DD6920 | CInGameIdler::[73] vtable 槽 CInGameIdler::[73]（func_names RTTI 名） |
| 0x14113F720 | CSendVolunteerAction::[45] vtable 槽 CSendVolunteerAction::[45]（func_names RTTI 名） |
| 0x1415046D0 | CIncomingLendLeaseAction::[32] vtable 槽 CIncomingLendLeaseAction::[32]（func_names RTTI 名） |
| 0x141A02650 | CRailwayProductionLine::[27] vtable 槽 CRailwayProductionLine::[27]（func_names RTTI 名） |
| 0x1422AE4D0 | C2dObject::[11] vtable 槽 C2dObject::[11]（func_names RTTI 名） |
| 0x1422AE6D0 | C2dObject::[12] vtable 槽 C2dObject::[12]（func_names RTTI 名） |
| 0x1422FE9D0 | CSprite::[80] vtable 槽 CSprite::[80]（func_names RTTI 名） |
| 0x1422FE9E0 | CSprite::[81] vtable 槽 CSprite::[81]（func_names RTTI 名） |
| 0x1422FE9F0 | CSprite::[88] vtable 槽 CSprite::[88]（func_names RTTI 名） |
| 0x142384D50 | CPdxMouse::[21] vtable 槽 CPdxMouse::[21]（func_names RTTI 名） |
| 0x142384E30 | CPdxMouse::[15] vtable 槽 CPdxMouse::[15]（func_names RTTI 名） |
| 0x141B92CB0 | CAiIndustrialOrganisation::[2] vtable 槽 CAiIndustrialOrganisation::[2]（func_names RTTI 名） |
| 0x142361CE0 | CSdlEvents::[5] vtable 槽 CSdlEvents::[5]（func_names RTTI 名） |
| 0x142361E50 | CSdlEvents::[6] vtable 槽 CSdlEvents::[6]（func_names RTTI 名） |
| 0x14153D550 | CFriendsHandlerSteam::[3] vtable 槽 CFriendsHandlerSteam::[3]（func_names RTTI 名） |
| 0x140BF95D0 | CUnit::[4] vtable 槽 CUnit::[4]（func_names RTTI 名） |
| 0x140CAEAC0 | CResourceExchange::[17] vtable 槽 CResourceExchange::[17]（func_names RTTI 名） |
| 0x140CAEAD0 | CResourceOrigin::[17] vtable 槽 CResourceOrigin::[17]（func_names RTTI 名） |
| 0x140F70990 | CRailwayGunProductionLine::[11] vtable 槽 CRailwayGunProductionLine::[11]（func_names RTTI 名） |
| 0x140F71C80 | CShipRefitProductionLine::[28] vtable 槽 CShipRefitProductionLine::[28]（func_names RTTI 名） |
| 0x14153DB70 | CFriendsHandlerSteam::[12] vtable 槽 CFriendsHandlerSteam::[12]（func_names RTTI 名） |
| 0x1422D1280 | CButtonStandard::[18] vtable 槽 CButtonStandard::[18]（func_names RTTI 名） |
| 0x1412EF110 | CLendLeaseAction::[47] vtable 槽 CLendLeaseAction::[47]（func_names RTTI 名） |
| 0x1412EF120 | CLendLeaseAction::[48] vtable 槽 CLendLeaseAction::[48]（func_names RTTI 名） |
| 0x142396890 | CPdxCrashReportWindows::[5] vtable 槽 CPdxCrashReportWindows::[5]（func_names RTTI 名） |
| 0x1423AAD50 | PdxTextToSpeechWinSAPI::[1] vtable 槽 PdxTextToSpeechWinSAPI::[1]（func_names RTTI 名） |
| 0x141140310 | CRequestForeignManpowerAction::[32] vtable 槽 CRequestForeignManpowerAction::[32]（func_names RTTI 名） |
| 0x140DDA1A0 | CInGameIdler::[118] vtable 槽 CInGameIdler::[118]（func_names RTTI 名） |
| 0x1401772B0 | CApplication::[3] vtable 槽 CApplication::[3]（func_names RTTI 名） |
| 0x142231410 | CKeyBoard::[3] vtable 槽 CKeyBoard::[3]（func_names RTTI 名） |
| 0x142231420 | CKeyBoard::[3] vtable 槽 CKeyBoard::[3]（func_names RTTI 名） |
| 0x142231430 | CMouse::[3] vtable 槽 CMouse::[3]（func_names RTTI 名） |
| 0x142231460 | CMouse::[3] vtable 槽 CMouse::[3]（func_names RTTI 名） |
| 0x142231470 | CMouse::[3] vtable 槽 CMouse::[3]（func_names RTTI 名） |
| 0x142250280 | CSession::[3] vtable 槽 CSession::[3]（func_names RTTI 名） |
| 0x1422A3FB0 | CTrack::[31] vtable 槽 CTrack::[31]（func_names RTTI 名） |
| 0x14237F470 | CNullGraphicalObject::[58] vtable 槽 CNullGraphicalObject::[58]（func_names RTTI 名） |
| 0x142534344 | pDNameNode::[1] vtable 槽 pDNameNode::[1]（func_names RTTI 名） |
| 0x140177710 | CApplication::[15] vtable 槽 CApplication::[15]（func_names RTTI 名） |
| 0x140195410 | CGameApplication::[13] vtable 槽 CGameApplication::[13]（func_names RTTI 名） |
| 0x1422E6EC0 | CStandardChatMessage::[9] vtable 槽 CStandardChatMessage::[9]（func_names RTTI 名） |
| 0x1422E6ED0 | CSystemMessage::[9] vtable 槽 CSystemMessage::[9]（func_names RTTI 名） |
| 0x141129720 | CGiveStateControlAction::[43] vtable 槽 CGiveStateControlAction::[43]（func_names RTTI 名） |
| 0x141129760 | CTransferSpyMasterAction::[43] vtable 槽 CTransferSpyMasterAction::[43]（func_names RTTI 名） |
| 0x141A9E110 | CAirBaseAccessAction::[43] vtable 槽 CAirBaseAccessAction::[43]（func_names RTTI 名） |
| 0x1422AEC90 | CTrack::[102] vtable 槽 CTrack::[102]（func_names RTTI 名） |
| 0x1422AECA0 | CGraphicalObject::[15] vtable 槽 CGraphicalObject::[15]（func_names RTTI 名） |
| 0x1412EF100 | CLendLeaseAction::[43] vtable 槽 CLendLeaseAction::[43]（func_names RTTI 名） |

#### 4.1.23 CGameState 派发族与门控函数补遗（2947 函）

| VA | 语义/证据 |
|---|---|

#### 4.1.24 CGameState 派发族与门控函数补遗（3549 函）

| VA | 语义/证据 |
|---|---|
| 0x14231DA30 | CMatchmakingGui::[4] vtable 槽 CMatchmakingGui::[4]（func_names RTTI 名） |
| 0x141B6C760 | CSupplyNudger::[6] vtable 槽 CSupplyNudger::[6]（func_names RTTI 名） |
| 0x14038E6D0 | CSetBorderWarCombatData::GetDesc func_names 名 CSetBorderWarCombatData::GetDesc |
| 0x141A9BEA0 | CAirBaseAccessAction::GetAiAcceptanceFactors func_names 名 CAirBaseAccessAction::GetAiAcceptanceFactors |
| 0x141A9EF30 | CDockingRightsAction::GetAiAcceptanceFactors func_names 名 CDockingRightsAction::GetAiAcceptanceFactors |
| 0x140B5B250 | CGraphicalMap::UpdateProvinces? func_names 名 CGraphicalMap::UpdateProvinces? |
| 0x140397020 | CDbRefVariable::GetForTooltip? func_names 名 CDbRefVariable::GetForTooltip? |
| 0x14029EFF0 | CGameIdler::[114] vtable 槽 CGameIdler::[114]（func_names RTTI 名） |
| 0x14112B750 | CJoinAllyAction::GetRequestDescText func_names 名 CJoinAllyAction::GetRequestDescText |
| 0x141D0E740 | CConfirmUnassignUnits::[14] vtable 槽 CConfirmUnassignUnits::[14]（func_names RTTI 名） |
| 0x1411C48E0 | CLocalIntelNetwork::[3] vtable 槽 CLocalIntelNetwork::[3]（func_names RTTI 名） |
| 0x141115710 | CSendAttacheAction::GetAiAcceptanceFactors func_names 名 CSendAttacheAction::GetAiAcceptanceFactors |
| 0x141118DB0 | CGenerateWarGoalAction::GetAiAcceptance func_names 名 CGenerateWarGoalAction::GetAiAcceptance |
| 0x14159DEF0 | CScriptedWindowTemplate::[8] vtable 槽 CScriptedWindowTemplate::[8]（func_names RTTI 名） |
| 0x141111280 | CNonAggressionPactAction::GetAiAcceptanceFactors func_names 名 CNonAggressionPactAction::GetAiAcceptanceFactors |
| 0x141B60F80 | CStrategicRegionNudger::Update func_names 名 CStrategicRegionNudger::Update |
| 0x141C92240 | CDiplomacySendAttacheActionController::[0] vtable 槽 CDiplomacySendAttacheActionController::[0]（func_names RTTI 名） |
| 0x141136770 | CSendVolunteerAction::CanExecute func_names 名 CSendVolunteerAction::CanExecute |
| 0x141112EC0 | CPeaceProposalAction::GetAiAcceptanceFactors func_names 名 CPeaceProposalAction::GetAiAcceptanceFactors |
| 0x141112110 | COfferMilitaryAccessAction::GetAiAcceptanceFactors func_names 名 COfferMilitaryAccessAction::GetAiAcceptanceFactors |
| 0x14164E190 | CGfxIntelNetworkEdgeListBuilder::Build? func_names 名 CGfxIntelNetworkEdgeListBuilder::Build? |
| 0x141D0D030 | CConfirmDeleteUnits::[14] vtable 槽 CConfirmDeleteUnits::[14]（func_names RTTI 名） |
| 0x141A9D000 | COfferAirBaseAccessAction::GetAiAcceptanceFactors func_names 名 COfferAirBaseAccessAction::GetAiAcceptanceFactors |
| 0x1413EDAD0 | CLandBorderWarCombatant::[19] vtable 槽 CLandBorderWarCombatant::[19]（func_names RTTI 名） |
| 0x1414FD860 | CIncomingLendLeaseAction::GetAiAcceptanceFactors func_names 名 CIncomingLendLeaseAction::GetAiAcceptanceFactors |
| 0x140AD8D50 | CTimedWargoalActivity::[10] vtable 槽 CTimedWargoalActivity::[10]（func_names RTTI 名） |
| 0x141C90BD0 | CDiplomacyIncomingLendLeaseActionController::[0] vtable 槽 CDiplomacyIncomingLendLeaseActionController::[0]（func_names RTTI 名） |
| 0x141EB2C50 | CIntelLedgerArmyPanelController::[0] vtable 槽 CIntelLedgerArmyPanelController::[0]（func_names RTTI 名） |
| 0x14036E0D0 | CAddRemoveDynamicModifierEffect<$0A>::[7] func_names 名 CAddRemoveDynamicModifierEffect<$0A>::[7] |
| 0x141131FD0 | CGenerateWarGoalAction::CanExecute func_names 名 CGenerateWarGoalAction::CanExecute |
| 0x141EC79A0 | CIntelLedgerNavyPanelController::[0] vtable 槽 CIntelLedgerNavyPanelController::[0]（func_names RTTI 名） |
| 0x141ED6890 | CNavalLeaderModuleUi::[0] vtable 槽 CNavalLeaderModuleUi::[0]（func_names RTTI 名） |
| 0x141132C90 | CGuaranteeAction::CanExecute func_names 名 CGuaranteeAction::CanExecute |
| 0x141EC8610 | CIntelLedgerNavyPanelController::CLedgerShipEntry::[0] vtable 槽 CIntelLedgerNavyPanelController::CLedgerShipEntry::[0]（func_names RTTI 名） |
| 0x14036D5C0 | CAddRemoveDynamicModifierEffect<$00>::[7] func_names 名 CAddRemoveDynamicModifierEffect<$00>::[7] |
| 0x141133D50 | CJoinAllyAction::CanExecute func_names 名 CJoinAllyAction::CanExecute |
| 0x141B3E600 | CAmbientObjectNudger::CollectReloadNames func_names 名 CAmbientObjectNudger::CollectReloadNames |
| 0x141122AB0 | CDeclareWarAction::[61] vtable 槽 CDeclareWarAction::[61]（func_names RTTI 名） |
| 0x141AA0250 | COfferDockingRightsAction::GetAiAcceptanceFactors func_names 名 COfferDockingRightsAction::GetAiAcceptanceFactors |
| 0x141EA75B0 | CIntelLedgerAirPanelController::CLedgerAirwingEntry::[0] vtable 槽 CIntelLedgerAirPanelController::CLedgerAirwingEntry::[0]（func_names RTTI 名） |
| 0x141A2EAB0 | CConfirmAssignUnitsToFront::[14] vtable 槽 CConfirmAssignUnitsToFront::[14]（func_names RTTI 名） |
| 0x141B57E10 | CStateNudger::Update func_names 名 CStateNudger::Update |
| 0x141C91800 | CDiplomacyLendLeaseActionController::[0] vtable 槽 CDiplomacyLendLeaseActionController::[0]（func_names RTTI 名） |
| 0x140C00B90 | CUnit::[23] vtable 槽 CUnit::[23]（func_names RTTI 名） |
| 0x141574740 | CMapModesInterface::IsVisible func_names 名 CMapModesInterface::IsVisible |
| 0x140385B90 | CDbRefVariable::GetForTooltip? func_names 名 CDbRefVariable::GetForTooltip? |
| 0x1424BC9F0 | CTextLexer::[1] vtable 槽 CTextLexer::[1]（func_names RTTI 名） |
| 0x14112FFC0 | CCallAllyAction::CanExecute func_names 名 CCallAllyAction::CanExecute |
| 0x140AD82F0 | CTimedStageCoupActivity::[10] vtable 槽 CTimedStageCoupActivity::[10]（func_names RTTI 名） |
| 0x14068D5E0 | （无名） 体设 SCareerProfileAwards::vftable（RTTI 名） |
| 0x1420AF7C0 | CMapIdler::RestoreDeviceObjects func_names 名 CMapIdler::RestoreDeviceObjects |
| 0x14111D640 | CDiplomaticAction::GetAcceptMessageText func_names 名 CDiplomaticAction::GetAcceptMessageText |
| 0x141C92D60 | CDiplomacySendVolunteersController::[0] vtable 槽 CDiplomacySendVolunteersController::[0]（func_names RTTI 名） |
| 0x141C311D0 | CSaveDesignToFilePopUp::OnSetupDerived func_names 名 CSaveDesignToFilePopUp::OnSetupDerived |
| 0x141C9BB90 | CDiplomacySendExpeditionaryForceController::[7] vtable 槽 CDiplomacySendExpeditionaryForceController::[7]（func_names RTTI 名） |
| 0x141EC9260 | CIntelLedgerNavyPanelController::CLedgerShipHeaderEntry::[0] vtable 槽 CIntelLedgerNavyPanelController::CLedgerShipHeaderEntry::[0]（func_names RTTI 名） |
| 0x140425220 | CManpowerPerFactoryRatio::GetDesc func_names 名 CManpowerPerFactoryRatio::GetDesc |
| 0x1423E3210 | CSteamMatchmakingContext::[26] vtable 槽 CSteamMatchmakingContext::[26]（func_names RTTI 名） |
| 0x1420AE760 | CMapIdler::[7] vtable 槽 CMapIdler::[7]（func_names RTTI 名） |
| 0x140437120 | CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>::[6] func_names 名 CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>::[6] |
| 0x141EB39A0 | CIntelLedgerArmyPanelController::CLedgerArmyTemplateEntry::[0] vtable 槽 CIntelLedgerArmyPanelController::CLedgerArmyTemplateEntry::[0]（func_names RTTI 名） |
| 0x141135F30 | CSendExpeditionaryForceAction::CanExecute func_names 名 CSendExpeditionaryForceAction::CanExecute |
| 0x1415015D0 | CIncomingLendLeaseAction::GetRequestDescText func_names 名 CIncomingLendLeaseAction::GetRequestDescText |
| 0x141B62BC0 | CStrategicRegionNudger::CollectReloadNames func_names 名 CStrategicRegionNudger::CollectReloadNames |
| 0x1420AC8D0 | CMapIdler::[4] vtable 槽 CMapIdler::[4]（func_names RTTI 名） |
| 0x140A209A0 | CProgress::[0] vtable 槽 CProgress::[0]（func_names RTTI 名） |
| 0x14196BA10 | CLendLeaseExchange::[10] vtable 槽 CLendLeaseExchange::[10]（func_names RTTI 名） |
| 0x14036C050 | CRandomScopeInArray::BuildTooltip func_names 名 CRandomScopeInArray::BuildTooltip |
| 0x141641AF0 | CMaskedSpriteType::[9] vtable 槽 CMaskedSpriteType::[9]（func_names RTTI 名） |
| 0x141705A70 | CCountryMilitaryOverview::ClearContents func_names 名 CCountryMilitaryOverview::ClearContents |
| 0x141131770 | CEmbargoAction::CanExecute func_names 名 CEmbargoAction::CanExecute |
| 0x1414FE690 | CLendLeaseAction::GetAiAcceptanceFactors func_names 名 CLendLeaseAction::GetAiAcceptanceFactors |
| 0x1416F8080 | CCountryArmyOfficerCorpViewExtensions::AppointAdvisors func_names 名 CCountryArmyOfficerCorpViewExtensions::AppointAdvisors |
| 0x141C9C3E0 | CDiplomacySendVolunteersController::[7] vtable 槽 CDiplomacySendVolunteersController::[7]（func_names RTTI 名） |
| 0x1414287B0 | （无名） 体设 SSubUnitStats::vftable（RTTI 名） |
| 0x140356430 | CFinalizeBorderWar::Execute func_names 名 CFinalizeBorderWar::Execute |
| 0x14041CAA0 | CIntelLevelOver::GetDesc func_names 名 CIntelLevelOver::GetDesc |
| 0x141120FC0 | CSendAttacheAction::[59] vtable 槽 CSendAttacheAction::[59]（func_names RTTI 名） |
| 0x141137570 | CStageCoupAction::CanExecute func_names 名 CStageCoupAction::CanExecute |
| 0x141621A70 | CNavalCombatant::[32] vtable 槽 CNavalCombatant::[32]（func_names RTTI 名） |
| 0x14151CAE0 | CPuppetCountryAction::GetDisplayName func_names 名 CPuppetCountryAction::GetDisplayName |
| 0x14151C2A0 | CLiberateCountryAction::GetDisplayName func_names 名 CLiberateCountryAction::GetDisplayName |
| 0x141EA8900 | CIntelLedgerAirPanelController::CPlaneTypeCountEntryItem::[0] vtable 槽 CIntelLedgerAirPanelController::CPlaneTypeCountEntryItem::[0]（func_names RTTI 名） |
| 0x141117ED0 | CDeclareWarAction::GetAiAcceptance func_names 名 CDeclareWarAction::GetAiAcceptance |
| 0x141EC9A90 | CIntelLedgerNavyPanelController::CLedgerShipTypeEntry::[0] vtable 槽 CIntelLedgerNavyPanelController::CLedgerShipTypeEntry::[0]（func_names RTTI 名） |
| 0x141130EC0 | CDeclareWarAction::CanExecute func_names 名 CDeclareWarAction::CanExecute |
| 0x14034E630 | CCancelBorderWar::Execute func_names 名 CCancelBorderWar::Execute |
| 0x14111CBE0 | CSendVolunteerAction::GetAiAcceptance func_names 名 CSendVolunteerAction::GetAiAcceptance |
| 0x141FA63E0 | CAwardDisplay::Create func_names 名 CAwardDisplay::Create |
| 0x141127590 | CDiplomaticAction::GetDeclineMessageText func_names 名 CDiplomaticAction::GetDeclineMessageText |
| 0x141EB20F0 | CIntelLedgerArmyPanelController::CEquipmentTabTooltipHandler::[0] vtable 槽 CIntelLedgerArmyPanelController::CEquipmentTabTooltipHandler::[0]（func_names RTTI 名） |
| 0x141338760 | CChat::[9] vtable 槽 CChat::[9]（func_names RTTI 名） |
| 0x1423310F0 | SParticleSystemReader::[8] vtable 槽 SParticleSystemReader::[8]（func_names RTTI 名） |
| 0x1404B6FD0 | CFactionUpgradeLevel::GetDesc func_names 名 CFactionUpgradeLevel::GetDesc |
| 0x1404B5670 | CFactionGoalFulfillment::GetDesc func_names 名 CFactionGoalFulfillment::GetDesc |
| 0x1422E5DD0 | CCountryChatMessage::[11] vtable 槽 CCountryChatMessage::[11]（func_names RTTI 名） |
| 0x1414FEF80 | CLendLeaseAction::GetAiAcceptance func_names 名 CLendLeaseAction::GetAiAcceptance |
| 0x14046BC70 | CCanConstructBuilding::GetDesc func_names 名 CCanConstructBuilding::GetDesc |
| 0x1417CF210 | CNavalMissionExtension::[1] vtable 槽 CNavalMissionExtension::[1]（func_names RTTI 名） |
| 0x1412BC180 | CLandCombatant::[32] vtable 槽 CLandCombatant::[32]（func_names RTTI 名） |
| 0x1423E3EF0 | CMatchmakingServerListResponse::[0] vtable 槽 CMatchmakingServerListResponse::[0]（func_names RTTI 名） |
| 0x141EA61D0 | CIntelLedgerAirPanelController::CAirWingsTooltipHandler::[0] vtable 槽 CIntelLedgerAirPanelController::CAirWingsTooltipHandler::[0]（func_names RTTI 名） |
| 0x141C9B3D0 | CDiplomacyRequestExpeditionaryForcesController::[7] vtable 槽 CDiplomacyRequestExpeditionaryForcesController::[7]（func_names RTTI 名） |
| 0x141ECA1F0 | CIntelLedgerNavyPanelController::CShipDetailsMainTooltipHandler::[0] vtable 槽 CIntelLedgerNavyPanelController::CShipDetailsMainTooltipHandler::[0]（func_names… |
| 0x141EE2A90 | CAiFrontImportanceMapModeConfig::[2] vtable 槽 CAiFrontImportanceMapModeConfig::[2]（func_names RTTI 名） |
| 0x141CA2140 | CDiplomacySendVolunteersController::[0] vtable 槽 CDiplomacySendVolunteersController::[0]（func_names RTTI 名） |
| 0x14195A190 | CQuietIntelNetwork::GetProvincesInRangeOfState? func_names 名 CQuietIntelNetwork::GetProvincesInRangeOfState? |
| 0x141B079B0 | CEvolveShipImgui::[8] vtable 槽 CEvolveShipImgui::[8]（func_names RTTI 名） |
| 0x1423E7F80 | CSteamNetContext::[7] vtable 槽 CSteamNetContext::[7]（func_names RTTI 名） |
| 0x14014B7A0 | （无名） 体设 CTraitTemplate::vftable（RTTI 名） |
| 0x141124B60 | CDeclareWarAction::[21] vtable 槽 CDeclareWarAction::[21]（func_names RTTI 名） |
| 0x1417CE180 | CMinimapInterface::[9] vtable 槽 CMinimapInterface::[9]（func_names RTTI 名） |
| 0x140F59C00 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x142023450 | CSaveQueuePopUp::OnSetupDerived func_names 名 CSaveQueuePopUp::OnSetupDerived |
| 0x141EB1A20 | CIntelLedgerArmyPanelController::CArmyTabTooltipHandler::[0] vtable 槽 CIntelLedgerArmyPanelController::CArmyTabTooltipHandler::[0]（func_names RTTI 名） |
| 0x140AC4810 | CSubUnitDatabase::[2]（func_names 名） func_names 名：兵种子单元数据库访问 |
| 0x14188B6B0 | CTheatreSelector::[7] vtable 槽 CTheatreSelector::[7]（func_names RTTI 名） |
| 0x14151BE00 | CForceGovernmentAction::GetDisplayName func_names 名 CForceGovernmentAction::GetDisplayName |
| 0x141577400 | CMapModesInterface::[9] vtable 槽 CMapModesInterface::[9]（func_names RTTI 名） |
| 0x142277C30 | CPdxMeshObject::[3] vtable 槽 CPdxMeshObject::[3]（func_names RTTI 名） |
| 0x141D140A0 | CUnitLeaderTraitTreeItem 槽 4（将领特质树项） func_names 名 + 读 a1+44/+48、+2556 |
| 0x140400470 | CHasAnnexWarGoal::GetDesc func_names 名 CHasAnnexWarGoal::GetDesc |
| 0x142241AD0 | CSpriteType::[30] vtable 槽 CSpriteType::[30]（func_names RTTI 名） |
| 0x140BD0B50 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x140311AC0 | CStartResistance::Execute func_names 名 CStartResistance::Execute |
| 0x140DC6D30 | CInGameIdler::[56] vtable 槽 CInGameIdler::[56]（func_names RTTI 名） |
| 0x140BF8ED0 | （无名） 体设 CUnit::vftable（RTTI 名） |
| 0x142259EA0 | （无名） 体设 CGui::vftable（RTTI 名） |
| 0x1422FCB40 | C2dPieChartTemplate<SPieVertex>::[10] func_names 名 C2dPieChartTemplate<SPieVertex>::[10] |
| 0x140BBF580 | CProvinceSpatialCalculator::PrecalculateAdjacencyForRange? func_names 名 CProvinceSpatialCalculator::PrecalculateAdjacencyForRange? |
| 0x141B49EE0 | CBuildingsNudger 槽 5 func_names 名 + qword_14332F698 + vtbl+192 回调 |
| 0x1422D0CD0 | CButtonStandard 槽 91 func_names 名 + 读 a1+232/+240 vtbl+608 比较 |
| 0x14195D160 | CRaidTargetManager::EvaluateStateTargets? func_names 名 CRaidTargetManager::EvaluateStateTargets? |
| 0x14111DE90 | CRequestForeignManpowerAction::GetAcceptMessageText func_names 名 CRequestForeignManpowerAction::GetAcceptMessageText |
| 0x142371940 | （无名） 体设 CGuiType::vftable（RTTI 名） |
| 0x1411C62D0 | CLocalIntelNetwork::[2] vtable 槽 CLocalIntelNetwork::[2]（func_names RTTI 名） |
| 0x140AB2280 | CScriptedDiplomaticAction::[59] vtable 槽 CScriptedDiplomaticAction::[59]（func_names RTTI 名） |
| 0x140639200 | CRule::[11] vtable 槽 CRule::[11]（func_names RTTI 名） |
| 0x140A1F440 | SOperatorReader::[2] vtable 槽 SOperatorReader::[2]（func_names RTTI 名） |
| 0x1422DCF00 | （无名） 体设 CButtonWrapper::vftable（RTTI 名） |
| 0x1420B0820 | CTurnTableStrategy::[3] vtable 槽 CTurnTableStrategy::[3]（func_names RTTI 名） |
| 0x1404218A0 | CIsLeadingVolunteerGroup::GetDesc func_names 名 CIsLeadingVolunteerGroup::GetDesc |
| 0x141C93790 | CDiplomacyStageCoupController::[0] vtable 槽 CDiplomacyStageCoupController::[0]（func_names RTTI 名） |
| 0x14237A540 | CRadioButtonGroupType::[10] vtable 槽 CRadioButtonGroupType::[10]（func_names RTTI 名） |
| 0x141E86B90 | CRaidMapIconVariant::Reload? func_names 名 CRaidMapIconVariant::Reload? |
| 0x141127090 | CSendAttacheAction::GetCostText func_names 名 CSendAttacheAction::GetCostText |
| 0x141B73FF0 | CUnitsNudger 槽 5 func_names 名 + qword_14332F698 + vtbl+192 回调 |
| 0x14237B040 | CRadioScrollbarGroupType::[10] vtable 槽 CRadioScrollbarGroupType::[10]（func_names RTTI 名） |
| 0x140CF08D0 | （无名） 体设 CControllerArea::vftable（RTTI 名） |
| 0x140F59F70 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x1420157F0 | CTraitIconItem 槽0 CTraitIconItem 槽0：特质图标项构造/刷新（func_names 名），调 0x140BC9760 变量族 |
| 0x140D1F500 | CBoostPartyPopularityRelation::[19] vtable 槽 CBoostPartyPopularityRelation::[19]（func_names RTTI 名） |
| 0x141C8AF70 | （无名） 体设 CDiplomacyRequestLicensedProductionController::vftable（RTTI 名） |
| 0x141B08300 | CEvolveTankImgui::[8] vtable 槽 CEvolveTankImgui::[8]（func_names RTTI 名） |
| 0x14235D1D0 | SGfxDepthStencilStateReader::[4] vtable 槽 SGfxDepthStencilStateReader::[4]（func_names RTTI 名） |
| 0x141F23EF0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x141795C80 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x14153C530 | （无名） 体设 CFriendsHandler::vftable（RTTI 名） |
| 0x1404B0FF0 | CSetFactionMemberUpgradeMin::GetDesc func_names 名 CSetFactionMemberUpgradeMin::GetDesc |
| 0x140F5A1F0 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14235D7F0 | SGfxSamplerReader::[4] vtable 槽 SGfxSamplerReader::[4]（func_names RTTI 名） |
| 0x140A95A40 | SUniformReader<鈥�>::[2] func_names 名 SUniformReader<鈥�>::[2] |
| 0x141126CF0 | CImproveRelationAction::GetCostText func_names 名 CImproveRelationAction::GetCostText |
| 0x141C10930 | （无名） 体设 CCountryCharacterSelector::vftable（RTTI 名） |
| 0x1405284C0 | CSetStrategicStateLocationBuildingLevel::Parse func_names 名 CSetStrategicStateLocationBuildingLevel::Parse |
| 0x140448FC0 | CIsExileLeaderFrom::GetDesc func_names 名 CIsExileLeaderFrom::GetDesc |
| 0x142363870 | CDummyServer::[5] vtable 槽 CDummyServer::[5]（func_names RTTI 名） |
| 0x1402A2570 | CGameIdler::RestoreDeviceObjects（func_names 名） CGameIdler::RestoreDeviceObjects（func_names 名）：STR 'rightClickMenu' + 调 0x1422333C0/0x14207E1xx 渲染族 |
| 0x14196A620 | （无名） 体设 CLendLeaseExchange::vftable（RTTI 名） |
| 0x14035BB50 | CPromoteCharacterToCountryLeader::Execute func_names 名 CPromoteCharacterToCountryLeader::Execute |
| 0x141708490 | CCountryMilitaryOverview::[0] vtable 槽 CCountryMilitaryOverview::[0]（func_names RTTI 名） |
| 0x141933C10 | （无名） 体设 CEquipmentProductionLine::vftable（RTTI 名） |
| 0x1415DDF00 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x141C8D650 | CDiplomacyCallAllyActionController::[4] vtable 槽 CDiplomacyCallAllyActionController::[4]（func_names RTTI 名） |
| 0x141C8D320 | CDiplomacyBoostPartyPopularityController::[4] vtable 槽 CDiplomacyBoostPartyPopularityController::[4]（func_names RTTI 名） |
| 0x140389690 | CRemoveDecisionOnCooldown::GetDesc func_names 名 CRemoveDecisionOnCooldown::GetDesc |
| 0x14041BE50 | CHasWarWithWargoalAgainst::GetDesc func_names 名 CHasWarWithWargoalAgainst::GetDesc |
| 0x142234C60 | CGraphics::Init3DTypes? func_names 名 CGraphics::Init3DTypes? |
| 0x140480840 | CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[3] func_names 名 CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[3] |
| 0x1402F39C0 | CPartyLeaderTarget::[25] vtable 槽 CPartyLeaderTarget::[25]（func_names RTTI 名） |
| 0x142502C80 | CException::[1] vtable 槽 CException::[1]（func_names RTTI 名） |
| 0x141A2DF90 | CConfirmDeleteOrder::[14] vtable 槽 CConfirmDeleteOrder::[14]（func_names RTTI 名） |
| 0x141C8E810 | CDiplomacyStageCoupController::[4] vtable 槽 CDiplomacyStageCoupController::[4]（func_names RTTI 名） |
| 0x1420B03C0 | CFirstPersonStrategy::[3] vtable 槽 CFirstPersonStrategy::[3]（func_names RTTI 名） |
| 0x141B2A4E0 | CRaidFilter::Setup? func_names 名 CRaidFilter::Setup? |
| 0x1411262E0 | CEmbargoAction::GetCostText func_names 名 CEmbargoAction::GetCostText |
| 0x14208CC80 | CTweakableArrayCurveManipulator::[13] vtable 槽 CTweakableArrayCurveManipulator::[13]（func_names RTTI 名） |
| 0x140639950 | CRule::[10] vtable 槽 CRule::[10]（func_names RTTI 名） |
| 0x14049FE10 | CAddEquipmentBonus::ParseToken func_names 名 CAddEquipmentBonus::ParseToken |
| 0x140314380 | CAddDemilitarizedZone::GetDesc func_names 名 CAddDemilitarizedZone::GetDesc |
| 0x14151E140 | CTakeNavyPeaceAction::GetDescription func_names 名 CTakeNavyPeaceAction::GetDescription |
| 0x142058340 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x142400600 | （无名） 体设 CPdxSocialPlayerId::vftable（RTTI 名） |
| 0x140AF1A50 | CUnitNamesDatabase::GenerateNameForAirWing? func_names 名 CUnitNamesDatabase::GenerateNameForAirWing? |
| 0x141079630 | CAIGeneral::HandleAIMicroAttacks? func_names 名 CAIGeneral::HandleAIMicroAttacks? |
| 0x140FC9610 | SUniformDatabaseReader<鈥�>::[0] func_names 名 SUniformDatabaseReader<鈥�>::[0] |
| 0x1412197B0 | （无名） 体设 CCountrySupplySystem::vftable（RTTI 名） |
| 0x1403AE150 | CFindHighestLowestInArrayEffect<$00>::[4] func_names 名 CFindHighestLowestInArrayEffect<$00>::[4] |
| 0x1414DDEA0 | CPersistedBookmarkPlaythroughDb::[3] vtable 槽 CPersistedBookmarkPlaythroughDb::[3]（func_names RTTI 名） |
| 0x1422CE450 | SSpriteFramePair::[1] vtable 槽 SSpriteFramePair::[1]（func_names RTTI 名） |
| 0x1422AD160 | CStandardlistbox::[25] vtable 槽 CStandardlistbox::[25]（func_names RTTI 名） |
| 0x1401CA880 | CGameState::AddGlobalTokenArrayVariable func_names 名 CGameState::AddGlobalTokenArrayVariable |
| 0x140A316A0 | SUniformReader<鈥�>::[2] func_names 名 SUniformReader<鈥�>::[2] |
| 0x1422CE720 | （无名） 体设 CBrowser::vftable（RTTI 名） |
| 0x140D22130 | CBoostPartyPopularityRelation::[16] vtable 槽 CBoostPartyPopularityRelation::[16]（func_names RTTI 名） |
| 0x1423761A0 | （无名） 体设 CListboxType::vftable（RTTI 名） |
| 0x1422AD6F0 | CStandardlistbox::[31] vtable 槽 CStandardlistbox::[31]（func_names RTTI 名） |
| 0x140AC2AD0 | （无名） 体设 CSubUnitDatabase::vftable（RTTI 名） |
| 0x1419A95D0 | CGameChat::Reload func_names 名 CGameChat::Reload |
| 0x1409CB9B0 | CMetadata::ReadMember func_names 名 CMetadata::ReadMember |
| 0x1412B7EC0 | CLandCombatant::[14] vtable 槽 CLandCombatant::[14]（func_names RTTI 名） |
| 0x1419A98B0 | CGameChat::[5] vtable 槽 CGameChat::[5]（func_names RTTI 名） |
| 0x142315E20 | （无名） 体设 CMatchmakingGui::vftable（RTTI 名） |
| 0x1424D7180 | CChecksum::SetupVersionObject? func_names 名 CChecksum::SetupVersionObject? |
| 0x140BBD1D0 | CIdCounterStore::[8] vtable 槽 CIdCounterStore::[8]（func_names RTTI 名） |
| 0x14151A1E0 | CPuppetCountryAction::GetActionLabel func_names 名 CPuppetCountryAction::GetActionLabel |
| 0x141A46290 | CFactionAi::PickGoals? func_names 名 CFactionAi::PickGoals? |
| 0x140BD1680 | （无名） 体设 CEquipmentVariant::vftable（RTTI 名） |
| 0x14187F660 | CAirViewDetails::[0] vtable 槽 CAirViewDetails::[0]（func_names RTTI 名） |
| 0x141F6B860 | CMapModeMilitaryDeployment::[9] vtable 槽 CMapModeMilitaryDeployment::[9]（func_names RTTI 名） |
| 0x1402B2170 | CHistoryLogger::OnDailyUpdate? func_names 名 CHistoryLogger::OnDailyUpdate? |
| 0x141C98A10 | CDiplomacySendAttacheActionController::[2] vtable 槽 CDiplomacySendAttacheActionController::[2]（func_names RTTI 名） |
| 0x140436E80 | CForEachScopesTriggerImp<$00>::[6] func_names 名 CForEachScopesTriggerImp<$00>::[6] |
| 0x142300C90 | CSmoothListbox::[2] vtable 槽 CSmoothListbox::[2]（func_names RTTI 名） |
| 0x1412AAB40 | CLandCombatant::[15] vtable 槽 CLandCombatant::[15]（func_names RTTI 名） |
| 0x1422E6BC0 | CSystemMessage::[11] vtable 槽 CSystemMessage::[11]（func_names RTTI 名） |
| 0x1422CF290 | CBrowser::[2] vtable 槽 CBrowser::[2]（func_names RTTI 名） |
| 0x140AB1CD0 | CScriptedDiplomaticAction::GetAiAcceptanceFactors func_names 名 CScriptedDiplomaticAction::GetAiAcceptanceFactors |
| 0x14197E590 | CDynamicIntelSourcePool::AggregateAccumulators? func_names 名 CDynamicIntelSourcePool::AggregateAccumulators? |
| 0x1401C5210 | bae32ba7eca0dc5cb081c98540ff9dd6::.??::[1] func_names 名 bae32ba7eca0dc5cb081c98540ff9dd6::.??::[1] |
| 0x1401C59B0 | 647e1cc61573d698fb83dee56485f966::.??::[1] func_names 名 647e1cc61573d698fb83dee56485f966::.??::[1] |
| 0x140370510 | CActivateShineOnFocus::GetDesc func_names 名 CActivateShineOnFocus::GetDesc |
| 0x141FCEDD0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x1420B1140 | CTurnTableStrategy::[1] vtable 槽 CTurnTableStrategy::[1]（func_names RTTI 名） |
| 0x14151D9E0 | CTakeStateAction::GetDisplayName func_names 名 CTakeStateAction::GetDisplayName |
| 0x140F9EEA0 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14232C570 | CCurveGraph::[8] vtable 槽 CCurveGraph::[8]（func_names RTTI 名） |
| 0x1412D4750 | CNudgeIdler::[19] vtable 槽 CNudgeIdler::[19]（func_names RTTI 名） |
| 0x140A2BFD0 | SUniformReader<鈥�>::[0] func_names 名 SUniformReader<鈥�>::[0] |
| 0x1413F07F0 | （无名） 体设 CCharacterTemplate::vftable（RTTI 名） |
| 0x1422E6310 | CPersonalChatMessage::[11] vtable 槽 CPersonalChatMessage::[11]（func_names RTTI 名） |
| 0x140B3C060 | CFrontEndIdler::[19] vtable 槽 CFrontEndIdler::[19]（func_names RTTI 名） |
| 0x141C89910 | （无名） 体设 CDiplomacyCountryBaseWarGoalActionController::vftable（RTTI 名） |
| 0x140C45830 | CStrategicAirManager::UpdatePortStrikeLimitPerRegion? func_names 名 CStrategicAirManager::UpdatePortStrikeLimitPerRegion? |
| 0x141511840 | （无名） 体设 CExileDivisionsTransfer::vftable（RTTI 名） |
| 0x1419C2770 | （无名） 体设 CMapPingManager::vftable（RTTI 名） |
| 0x140A8B940 | （无名） 体设 CPowerBalanceTemplate::vftable（RTTI 名） |
| 0x1405339E0 | CGameDate::[3] vtable 槽 CGameDate::[3]（func_names RTTI 名） |
| 0x141F6C440 | CConfirmDeleteEquipment::[14] vtable 槽 CConfirmDeleteEquipment::[14]（func_names RTTI 名） |
| 0x140D813C0 | CTechnologySharing::GetFullTooltip? func_names 名 CTechnologySharing::GetFullTooltip? |
| 0x140186D90 | TReloadableGameItemDatabase::InitFromDirectory? func_names 名 TReloadableGameItemDatabase::InitFromDirectory? |
| 0x1419A9310 | CGameChat::[11] vtable 槽 CGameChat::[11]（func_names RTTI 名） |
| 0x14113A5C0 | CSendVolunteerAction::[57] vtable 槽 CSendVolunteerAction::[57]（func_names RTTI 名） |
| 0x14071D8B0 | （无名） 体设 CCountryLeaderTrait::vftable（RTTI 名） |
| 0x141E33B30 | CMapModeOperationSelectTarget::[9] vtable 槽 CMapModeOperationSelectTarget::[9]（func_names RTTI 名） |
| 0x141DD4790 | （无名） 体设 CEquipmentDesignerModelSelector::vftable（RTTI 名） |
| 0x14196F500 | （无名） 体设 CFEXMember::vftable（RTTI 名） |
| 0x1423AAA70 | PdxTextToSpeechWinSAPI::[4] vtable 槽 PdxTextToSpeechWinSAPI::[4]（func_names RTTI 名） |
| 0x140C10050 | CNavyLeader::[27] vtable 槽 CNavyLeader::[27]（func_names RTTI 名） |
| 0x140188C00 | TReloadableGameItemDatabase::InitFromDirectory? func_names 名 TReloadableGameItemDatabase::InitFromDirectory? |
| 0x140CF0C70 | （无名） 体设 COwnerArea::vftable（RTTI 名） |
| 0x14129E090 | （无名） 体设 CAdvisor::vftable（RTTI 名） |
| 0x1422AB970 | CStandardlistbox::[6] vtable 槽 CStandardlistbox::[6]（func_names RTTI 名） |
| 0x140E92510 | （无名） 体设 CRailwayManager::vftable（RTTI 名） |
| 0x140527760 | CSetStrategicProvinceLocationBuildingLevel::ExecuteChecked func_names 名 CSetStrategicProvinceLocationBuildingLevel::ExecuteChecked |
| 0x140A2DA00 | SUniformReader<鈥�>::[0] func_names 名 SUniformReader<鈥�>::[0] |
| 0x140A956C0 | SUniformReader<鈥�>::[0] func_names 名 SUniformReader<鈥�>::[0] |
| 0x140DDA5D0 | CInGameIdler::[111] vtable 槽 CInGameIdler::[111]（func_names RTTI 名） |
| 0x140FA9B00 | （无名） 体设 CNavalMission::vftable（RTTI 名） |
| 0x140D7C4A0 | （无名） 体设 CCountryDoctrineStatus::vftable（RTTI 名） |
| 0x140BCC460 | CStrategicResourcePool::[3] vtable 槽 CStrategicResourcePool::[3]（func_names RTTI 名） |
| 0x142225580 | CFilterLogger::[1] vtable 槽 CFilterLogger::[1]（func_names RTTI 名） |
| 0x141B60CD0 | （无名） 体设 CStrategicRegionNudger::vftable（RTTI 名） |
| 0x1422FDD10 | CSprite::[41] vtable 槽 CSprite::[41]（func_names RTTI 名） |
| 0x140411640 | CHasNonAggressionPactWith::GetDesc func_names 名 CHasNonAggressionPactWith::GetDesc |
| 0x140A39E80 | （无名） 体设 CWarGoalType::vftable（RTTI 名） |
| 0x141A9E5B0 | COfferAirBaseAccessAction::CanExecute func_names 名 COfferAirBaseAccessAction::CanExecute |
| 0x140C0FE20 | CArmyLeader::[27] vtable 槽 CArmyLeader::[27]（func_names RTTI 名） |
| 0x141976830 | （无名） 体设 CFEXAir::vftable（RTTI 名） |
| 0x14038BB80 | CRemoveResourceRights::GetDesc func_names 名 CRemoveResourceRights::GetDesc |
| 0x140C47940 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14145E810 | （无名） 体设 CScientistLevel::vftable（RTTI 名） |
| 0x14223CC00 | CTextureReloader::Reload func_names 名 CTextureReloader::Reload |
| 0x14186C820 | （无名） 体设 CPlayerLobby::vftable（RTTI 名） |
| 0x1414E7DB0 | （无名） 体设 CMessage::vftable（RTTI 名） |
| 0x141AA1290 | CDockingRightsAction::CanExecute func_names 名 CDockingRightsAction::CanExecute |
| 0x141EC6F80 | （无名） 体设 CIntelLedgerNavyPanelController::vftable（RTTI 名） |
| 0x14132DA30 | （无名） 体设 SChannelInfo::vftable（RTTI 名） |
| 0x140FF2F70 | （无名） 体设 CStateGarrisonData::vftable（RTTI 名） |
| 0x142357140 | C2dCircularProgressBarType::[9] vtable 槽 C2dCircularProgressBarType::[9]（func_names RTTI 名） |
| 0x141116660 | CSendExpeditionaryForceAction::GetAiAcceptanceFactors func_names 名 CSendExpeditionaryForceAction::GetAiAcceptanceFactors |
| 0x140344DD0 | CAddToArrayEffectImp<$00>::[13] func_names 名 CAddToArrayEffectImp<$00>::[13] |
| 0x140AB2030 | CScriptedDiplomaticAction::GetAcceptMessageText func_names 名 CScriptedDiplomaticAction::GetAcceptMessageText |
| 0x140AC2D70 | （无名） 体设 CSubUnitDatabase::vftable（RTTI 名） |
| 0x14133C610 | CChat::[5] vtable 槽 CChat::[5]（func_names RTTI 名） |
| 0x140622E30 | （无名） 体设 CAgencyUpgrade::vftable（RTTI 名） |
| 0x140DD8380 | CInGameIdler::[105] vtable 槽 CInGameIdler::[105]（func_names RTTI 名） |
| 0x141107260 | CGiveStateControlAction::[56] vtable 槽 CGiveStateControlAction::[56]（func_names RTTI 名） |
| 0x140A8BB30 | （无名） 体设 CPowerBalanceTemplate::vftable（RTTI 名） |
| 0x141641210 | CGameBitmapFont::[26] vtable 槽 CGameBitmapFont::[26]（func_names RTTI 名） |
| 0x14111F290 | CBoostPartyPopularityAction::[59] vtable 槽 CBoostPartyPopularityAction::[59]（func_names RTTI 名） |
| 0x141E28AD0 | （无名） 体设 SSpriteFramePair::vftable（RTTI 名） |
| 0x14068E030 | （无名） 体设 SCareerProfileCountryData::vftable（RTTI 名） |
| 0x141B5A210 | CStateNudger::[6] vtable 槽 CStateNudger::[6]（func_names RTTI 名） |
| 0x141AA14F0 | COfferDockingRightsAction::CanExecute func_names 名 COfferDockingRightsAction::CanExecute |
| 0x140F70EA0 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x140345000 | CAddToArrayEffectImp<$0A>::[13] func_names 名 CAddToArrayEffectImp<$0A>::[13] |
| 0x1401C0EA0 | （无名） 体设 SCareerProfileCountryData::vftable（RTTI 名） |
| 0x141105060 | CAskForStateControlAction::[56] vtable 槽 CAskForStateControlAction::[56]（func_names RTTI 名） |
| 0x140527270 | CDebugMathExpression::GetDesc func_names 名 CDebugMathExpression::GetDesc |
| 0x140720C50 | （无名） 体设 CScriptTargets::vftable（RTTI 名） |
| 0x140D6EC20 | CTaskForce::[1] vtable 槽 CTaskForce::[1]（func_names RTTI 名） |
| 0x1423C2180 | （无名） 体设 CSteamBrowserInstance::vftable（RTTI 名） |
| 0x140CD8320 | （无名） 体设 SCombatSideData::vftable（RTTI 名） |
| 0x14037F3A0 | CDeleteTemplateAndItsUnits::GetDesc func_names 名 CDeleteTemplateAndItsUnits::GetDesc |
| 0x1417CC620 | CMinimapInterface::IsVisible func_names 名 CMinimapInterface::IsVisible |
| 0x141120D90 | CReturnAllExpeditionaryForcesAction::[59] vtable 槽 CReturnAllExpeditionaryForcesAction::[59]（func_names RTTI 名） |
| 0x142402CC0 | （无名） 体设 CSteamUGCContext::vftable（RTTI 名） |
| 0x14041DB30 | CIsCryptologyDepartmentActive::GetDesc func_names 名 CIsCryptologyDepartmentActive::GetDesc |
| 0x140ABA8D0 | CScriptedWindowTemplate::SPropertyInfo::Reader func_names 名 CScriptedWindowTemplate::SPropertyInfo::Reader |
| 0x140345C30 | CRandomizeVariableEffect<CVariableResolver>::[13] func_names 名 CRandomizeVariableEffect<CVariableResolver>::[13] |
| 0x1402E9A70 | CSupplyUnits::Execute func_names 名 CSupplyUnits::Execute |
| 0x14067C4D0 | （无名） 体设 CBookmark::vftable（RTTI 名） |
| 0x1412D8C90 | （无名） 体设 CGfxTradeRoute::vftable（RTTI 名） |
| 0x14037EE40 | CDeactivateShineOnFocus::GetDesc func_names 名 CDeactivateShineOnFocus::GetDesc |
| 0x140A85D90 | （无名） 体设 CPortraitDatabase::vftable（RTTI 名） |
| 0x141577ED0 | （无名） 体设 CMessageType::vftable（RTTI 名） |
| 0x1422D1970 | CButtonStandard::[115] vtable 槽 CButtonStandard::[115]（func_names RTTI 名） |
| 0x141C8E5A0 | CDiplomacyRequestLicensedProductionController::[4] vtable 槽 CDiplomacyRequestLicensedProductionController::[4]（func_names RTTI 名） |
| 0x141C69BA0 | （无名） 体设 CFEXGroup::vftable（RTTI 名） |
| 0x141DF7CB0 | （无名） 体设 CStandardMusicPlaybackController::vftable（RTTI 名） |
| 0x1422387F0 | CTextureReloader::CollectReloadNames func_names 名 CTextureReloader::CollectReloadNames |
| 0x1409C54F0 | CNameGroup::[8] vtable 槽 CNameGroup::[8]（func_names RTTI 名） |
| 0x140CD86F0 | （无名） 体设 COrdersGroupLogs::vftable（RTTI 名） |
| 0x140EB16E0 | CStrategicNavyManager::UpdateNavalSupplyHubCache? func_names 名 CStrategicNavyManager::UpdateNavalSupplyHubCache? |
| 0x14153C3B0 | CFriendsHandlerSteam::DownloadProfileFromId func_names 名 CFriendsHandlerSteam::DownloadProfileFromId |
| 0x140A479E0 | CIdeologyGroupDatabase::[6] vtable 槽 CIdeologyGroupDatabase::[6]（func_names RTTI 名） |
| 0x140433BB0 | CForEachTriggerImp<$00>::[13] func_names 名 CForEachTriggerImp<$00>::[13] |
| 0x14141F3A0 | （无名） 体设 CScopedVariable::vftable（RTTI 名） |
| 0x140B8EEC0 | （无名） 体设 CPersistedDb::vftable（RTTI 名） |
| 0x140A2D720 | SUniformReader<鈥�>::[1] func_names 名 SUniformReader<鈥�>::[1] |
| 0x14018A2A0 | TReloadableGameItemDatabase::InitFromDirectory? func_names 名 TReloadableGameItemDatabase::InitFromDirectory? |
| 0x140189F70 | TReloadableGameItemDatabase::InitFromDirectory? func_names 名 TReloadableGameItemDatabase::InitFromDirectory? |
| 0x1419F42E0 | （无名） 体设 CPeaceBiddingTurn::vftable（RTTI 名） |
| 0x140A26460 | （无名） 体设 CFactionGoalStatus::vftable（RTTI 名） |
| 0x140187850 | TReloadableGameItemDatabase::InitFromDirectory? func_names 名 TReloadableGameItemDatabase::InitFromDirectory? |
| 0x142360BC0 | （无名） 体设 CTextSpriteType::vftable（RTTI 名） |
| 0x1412BAE50 | CLandCombatant::[16] vtable 槽 CLandCombatant::[16]（func_names RTTI 名） |
| 0x141ECCCA0 | CIntelLedgerNavyPanelController::[2] vtable 槽 CIntelLedgerNavyPanelController::[2]（func_names RTTI 名） |
| 0x14108F150 | CAIGeneral::[24] vtable 槽 CAIGeneral::[24]（func_names RTTI 名） |
| 0x140A28300 | CFactionGoalStatus::ReadMember func_names 名 CFactionGoalStatus::ReadMember |
| 0x140CE74B0 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x141B7F2C0 | CWeatherNudger::[4] vtable 槽 CWeatherNudger::[4]（func_names RTTI 名） |
| 0x1401B0070 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x1406BCC60 | CCharacterTemplateDatabase::InitFromDirectory? func_names 名 CCharacterTemplateDatabase::InitFromDirectory? |
| 0x141870720 | CPlayerLobby::[2] vtable 槽 CPlayerLobby::[2]（func_names RTTI 名） |
| 0x140174260 | （无名） 体设 CFactionUpgrade::vftable（RTTI 名） |
| 0x1423E7B90 | CSteamNetContext::[6] vtable 槽 CSteamNetContext::[6]（func_names RTTI 名） |
| 0x140DCB3F0 | CInGameIdler::[8] vtable 槽 CInGameIdler::[8]（func_names RTTI 名） |
| 0x141B44CD0 | （无名） 体设 CBuildingsNudger::vftable（RTTI 名） |
| 0x140C492C0 | （无名） 体设 CStrategicAirManager::vftable（RTTI 名） |
| 0x140A519F0 | （无名） 体设 CTraitTemplate::vftable（RTTI 名） |
| 0x142361320 | C2dPieChartType::[9] vtable 槽 C2dPieChartType::[9]（func_names RTTI 名） |
| 0x14112EB40 | CCallAllyAction::[53] vtable 槽 CCallAllyAction::[53]（func_names RTTI 名） |
| 0x141F6AEC0 | （无名） 体设 CConfirmDeleteEquipmentProductionLine::vftable（RTTI 名） |
| 0x141361440 | （无名） 体设 CSetArmyToConsolidateForUnit::vftable（RTTI 名） |
| 0x1423734F0 | （无名） 体设 CGuiType::vftable（RTTI 名） |
| 0x1422ED290 | CInstantTextObject::[10] vtable 槽 CInstantTextObject::[10]（func_names RTTI 名） |
| 0x140DE0500 | CInGameIdler::[113] vtable 槽 CInGameIdler::[113]（func_names RTTI 名） |
| 0x1411CF930 | （无名） 体设 CSubIntelNetwork::vftable（RTTI 名） |
| 0x1402DD700 | （无名） 体设 CSaveGameController::vftable（RTTI 名） |
| 0x14036F0B0 | CSetOrAddVictoryPointsEffect<$00>::[7] func_names 名 CSetOrAddVictoryPointsEffect<$00>::[7] |
| 0x142229EC0 | （无名） 体设 CSystemSettings::vftable（RTTI 名） |
| 0x140AB2960 | CScriptedDiplomaticAction::GetDeclineMessageText func_names 名 CScriptedDiplomaticAction::GetDeclineMessageText |
| 0x140DEDCF0 | CEquipmentMarketSystem::SetCallbacks? func_names 名 CEquipmentMarketSystem::SetCallbacks? |
| 0x140D82470 | CTechnologySharing::[17] vtable 槽 CTechnologySharing::[17]（func_names RTTI 名） |
| 0x140E257D0 | （无名） 体设 CNavalUnitTransfer::vftable（RTTI 名） |
| 0x140CF4CC0 | COwnerArea::[8] vtable 槽 COwnerArea::[8]（func_names RTTI 名） |
| 0x14112E850 | CStageCoupAction::[53] vtable 槽 CStageCoupAction::[53]（func_names RTTI 名） |
| 0x140CE1290 | （无名） 体设 CNavalAccidentReport::vftable（RTTI 名） |
| 0x1414FD360 | CLendLeaseAction::[56] vtable 槽 CLendLeaseAction::[56]（func_names RTTI 名） |
| 0x140C96D20 | CEquipmentType::[7] vtable 槽 CEquipmentType::[7]（func_names RTTI 名） |
| 0x140DF6870 | CJointNationalFocus::[12] vtable 槽 CJointNationalFocus::[12]（func_names RTTI 名） |
| 0x1404907B0 | CAddEquipmentProduction::[7] vtable 槽 CAddEquipmentProduction::[7]（func_names RTTI 名） |
| 0x14112D630 | CSendVolunteerAction::GetRequestDescText func_names 名 CSendVolunteerAction::GetRequestDescText |
| 0x140A6C6C0 | （无名） 体设 SProgressbar::vftable（RTTI 名） |
| 0x14153CCB0 | （无名） 体设 CFriendsHandlerSteam::vftable（RTTI 名） |
| 0x141B6E720 | CSupplyNudger::[5] vtable 槽 CSupplyNudger::[5]（func_names RTTI 名） |
| 0x140A31490 | SUniformReader<鈥�>::[0] func_names 名 SUniformReader<鈥�>::[0] |
| 0x1424EC190 | collate<char,std>::[4] func_names 名 collate<char,std>::[4] |
| 0x14237EF20 | CTrack::[111] vtable 槽 CTrack::[111]（func_names RTTI 名） |
| 0x140DE0BF0 | CInGameIdler::[50] vtable 槽 CInGameIdler::[50]（func_names RTTI 名） |
| 0x1422D7870 | CPdx3DObject::[6] vtable 槽 CPdx3DObject::[6]（func_names RTTI 名） |
| 0x141A2E880 | CConfirmAssignUnitsToFront::[16] vtable 槽 CConfirmAssignUnitsToFront::[16]（func_names RTTI 名） |
| 0x1406312D0 | （无名） 体设 CEquipmentBonus::vftable（RTTI 名） |
| 0x140AB2CF0 | CScriptedDiplomaticAction::GetRequestDescText func_names 名 CScriptedDiplomaticAction::GetRequestDescText |
| 0x1415C2980 | CNavalCombat::[7] vtable 槽 CNavalCombat::[7]（func_names RTTI 名） |
| 0x140725B00 | （无名） 体设 STargetedDecisionTarget::vftable（RTTI 名） |
| 0x1414E9000 | （无名） 体设 CCountryRaidStatus::vftable（RTTI 名） |
| 0x140A21150 | CRatioProgress::[0] vtable 槽 CRatioProgress::[0]（func_names RTTI 名） |
| 0x141C8E260 | CDiplomacyGuaranteeActionController::[4] vtable 槽 CDiplomacyGuaranteeActionController::[4]（func_names RTTI 名） |
| 0x140221120 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140443710 | CIsLeadingArmyInProvince::Evaluate func_names 名 CIsLeadingArmyInProvince::Evaluate |
| 0x1414FD1A0 | CIncomingLendLeaseAction::[56] vtable 槽 CIncomingLendLeaseAction::[56]（func_names RTTI 名） |
| 0x1422AB360 | CSimpleListbox<CStandardlistboxItem>::[7] func_names 名 CSimpleListbox<CStandardlistboxItem>::[7] |
| 0x1423C2D70 | CSteamBrowserInstance::[6] vtable 槽 CSteamBrowserInstance::[6]（func_names RTTI 名） |
| 0x14111C630 | CSendAttacheAction::GetAiAcceptance func_names 名 CSendAttacheAction::GetAiAcceptance |
| 0x142296060 | CCorneredTileSpriteType::[25] vtable 槽 CCorneredTileSpriteType::[25]（func_names RTTI 名） |
| 0x1414E5660 | CTimeSeries::[3] vtable 槽 CTimeSeries::[3]（func_names RTTI 名） |
| 0x14128AD40 | （无名） 体设 CProvinceGraphics::vftable（RTTI 名） |
| 0x142374690 | （无名） 体设 CGuiType::vftable（RTTI 名） |
| 0x14112FAB0 | CAskForStateControlAction::CanExecute func_names 名 CAskForStateControlAction::CanExecute |
| 0x1402E5680 | CSetCountryLeaderNamePortraitOrDescription<$00>::[13] func_names 名 CSetCountryLeaderNamePortraitOrDescription<$00>::[13] |
| 0x140AB9FD0 | CScriptedWindowTemplate::SDynamicListInfo::[8] vtable 槽 CScriptedWindowTemplate::SDynamicListInfo::[8]（func_names RTTI 名） |
| 0x141BE32F0 | （无名） 体设 CConfirmResearchTechnology::vftable（RTTI 名） |
| 0x141235A90 | CUnitMoveAction::[23] vtable 槽 CUnitMoveAction::[23]（func_names RTTI 名） |
| 0x140D11BD0 | CDeploymentStatus::[8] vtable 槽 CDeploymentStatus::[8]（func_names RTTI 名） |
| 0x141962680 | （无名） 体设 SAirWingCombatData::vftable（RTTI 名） |
| 0x140464140 | CCanConstructBuilding::Evaluate func_names 名 CCanConstructBuilding::Evaluate |
| 0x140D74770 | CTaskForce::[45] vtable 槽 CTaskForce::[45]（func_names RTTI 名） |
| 0x140644160 | （无名） 体设 CBufferUnitsAtStateData::vftable（RTTI 名） |
| 0x1402A06B0 | CGameIdler::[4] vtable 槽 CGameIdler::[4]（func_names RTTI 名） |
| 0x1411D4D50 | CCountryIntelNetwork::[8] vtable 槽 CCountryIntelNetwork::[8]（func_names RTTI 名） |
| 0x1402F75D0 | CPartyLeaderTarget::[27] vtable 槽 CPartyLeaderTarget::[27]（func_names RTTI 名） |
| 0x140347E30 | CActivateShineOnFocus::Execute func_names 名 CActivateShineOnFocus::Execute |
| 0x141120BE0 | CRequestPuppetForcesAction::[59] vtable 槽 CRequestPuppetForcesAction::[59]（func_names RTTI 名） |
| 0x141C95570 | CDiplomacyIncomingLendLeaseActionController::[5] vtable 槽 CDiplomacyIncomingLendLeaseActionController::[5]（func_names RTTI 名） |
| 0x14235D600 | SGfxRasterizerStateReader::[4] vtable 槽 SGfxRasterizerStateReader::[4]（func_names RTTI 名） |
| 0x1413DEE80 | （无名） 体设 CAdvisorTemplate::vftable（RTTI 名） |
| 0x1419D82F0 | CDebugMapModeConfig::CFloatToHsv::[2] vtable 槽 CDebugMapModeConfig::CFloatToHsv::[2]（func_names RTTI 名） |
| 0x140D033D0 | （无名） 体设 CStaticIntelSourcePool::vftable（RTTI 名） |
| 0x140681600 | （无名） 体设 CBuildingSpawnPoint::vftable（RTTI 名） |
| 0x140AB27D0 | CScriptedDiplomaticAction::[50] vtable 槽 CScriptedDiplomaticAction::[50]（func_names RTTI 名） |
| 0x141F6B070 | （无名） 体设 CConfirmSwitchEquipment::vftable（RTTI 名） |
| 0x1420A6B80 | （无名） 体设 CMapIdler::vftable（RTTI 名） |
| 0x141C2F380 | CChangeDesignFolderPopUp::[0] vtable 槽 CChangeDesignFolderPopUp::[0]（func_names RTTI 名） |
| 0x141232230 | （无名） 体设 CTaskForceIdentity::vftable（RTTI 名） |
| 0x1404B4330 | CTriggerEntry<CFactionGoalFulfillment>::[1] func_names 名 CTriggerEntry<CFactionGoalFulfillment>::[1] |
| 0x140FDCF70 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1422FDB60 | CSprite::[15] vtable 槽 CSprite::[15]（func_names RTTI 名） |
| 0x141C89B70 | （无名） 体设 CDiplomacyCountryDeclareWarActionController::vftable（RTTI 名） |
| 0x141DEC880 | CConfirmSaveGame::[9] vtable 槽 CConfirmSaveGame::[9]（func_names RTTI 名） |
| 0x140B99410 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x140B9A000 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x141C89480 | （无名） 体设 CDiplomacyBoostPartyPopularityController::vftable（RTTI 名） |
| 0x142301650 | CSmoothListbox::[73] vtable 槽 CSmoothListbox::[73]（func_names RTTI 名） |
| 0x140EFE820 | CFrontSection::SPerCountrySection::Reader func_names 名 CFrontSection::SPerCountrySection::Reader |
| 0x140AC6710 | CTechnologySharingGroupDatabase::[1] vtable 槽 CTechnologySharingGroupDatabase::[1]（func_names RTTI 名） |
| 0x14044B490 | COperativeHasNationality::GetDesc func_names 名 COperativeHasNationality::GetDesc |
| 0x141FEDBA0 | CStatTooltipHandler<鈥�>::[0] func_names 名 CStatTooltipHandler<鈥�>::[0] |
| 0x1412B7B60 | CLandCombatant::[13] vtable 槽 CLandCombatant::[13]（func_names RTTI 名） |
| 0x1420A17F0 | （无名） 体设 CMapApplication::vftable（RTTI 名） |
| 0x141C9F3A0 | CDiplomacySendVolunteersController::[1] vtable 槽 CDiplomacySendVolunteersController::[1]（func_names RTTI 名） |
| 0x14150D510 | CArmyReinforcementRequests::[1] vtable 槽 CArmyReinforcementRequests::[1]（func_names RTTI 名） |
| 0x14046EB70 | CLastStrategicBombingOnStateStrigger::GetDesc func_names 名 CLastStrategicBombingOnStateStrigger::GetDesc |
| 0x140E54DD0 | （无名） 体设 CPowerBalance::vftable（RTTI 名） |
| 0x1406334B0 | （无名） 体设 SScopeLocalizer::vftable（RTTI 名） |
| 0x142360F10 | CTextSpriteType::[9] vtable 槽 CTextSpriteType::[9]（func_names RTTI 名） |
| 0x1404901A0 | CAddEquipmentProduction::[13] vtable 槽 CAddEquipmentProduction::[13]（func_names RTTI 名） |
| 0x141CED8C0 | （无名） 体设 CMissionToolbarController::vftable（RTTI 名） |
| 0x141191350 | （无名） 体设 CIdeologyGroup::vftable（RTTI 名） |
| 0x14198AEB0 | （无名） 体设 CTaskForceComposition::vftable（RTTI 名） |
| 0x1423E14F0 | CSteamMatchmakingContext::[36] vtable 槽 CSteamMatchmakingContext::[36]（func_names RTTI 名） |
| 0x1423751E0 | （无名） 体设 CGuiType::vftable（RTTI 名） |
| 0x1415374C0 | （无名） 体设 CEquipmentUpgrade::vftable（RTTI 名） |
| 0x14112D470 | CSendExpeditionaryForceAction::GetRequestDescText func_names 名 CSendExpeditionaryForceAction::GetRequestDescText |
| 0x14143E980 | CTerrainType::[8] vtable 槽 CTerrainType::[8]（func_names RTTI 名） |
| 0x1410D94A0 | COperativesAiAssignmentTextLogger::[3] vtable 槽 COperativesAiAssignmentTextLogger::[3]（func_names RTTI 名） |
| 0x141208020 | （无名） 体设 CSubIntelNetwork::vftable（RTTI 名） |
| 0x141235E90 | CUnitStrategicMoveAction::[23] vtable 槽 CUnitStrategicMoveAction::[23]（func_names RTTI 名） |
| 0x14014A750 | （无名） 体设 CDatabaseObject::vftable（RTTI 名） |
| 0x14223E850 | CGraphics::InitSpriteTypes? func_names 名 CGraphics::InitSpriteTypes? |
| 0x141E295C0 | （无名） 体设 SSpriteFramePair::vftable（RTTI 名） |
| 0x140C0BFD0 | （无名） 体设 CSubUnitDefinitionAssociatedModifiers::vftable（RTTI 名） |
| 0x1422AD9C0 | CStandardlistbox::[32] vtable 槽 CStandardlistbox::[32]（func_names RTTI 名） |
| 0x1422E7A40 | （无名） 体设 CChatBuffer::vftable（RTTI 名） |
| 0x1422FE520 | CSprite::[10] vtable 槽 CSprite::[10]（func_names RTTI 名） |
| 0x140E86D80 | CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[9] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[9] |
| 0x141F64AA0 | （无名） 体设 CArmyManpowerValues::vftable（RTTI 名） |
| 0x140A69190 | （无名） 体设 SNamesPool::vftable（RTTI 名） |
| 0x14236DC90 | （无名） 体设 CGuiType::vftable（RTTI 名） |
| 0x1419CE330 | CHasSetNatFocus::[9] vtable 槽 CHasSetNatFocus::[9]（func_names RTTI 名） |
| 0x1419266B0 | UEAAXAEAVCReader::CPersistedMioQueues::Read::SEntryReader::[1] vtable 槽 UEAAXAEAVCReader::CPersistedMioQueues::Read::SEntryReader::[1]（func_names RTTI 名） |
| 0x141235920 | CUnitStrategicMoveAction::[10] vtable 槽 CUnitStrategicMoveAction::[10]（func_names RTTI 名） |
| 0x14197ED60 | （无名） 体设 CStaticIntelSourceReference::vftable（RTTI 名） |
| 0x142356670 | （无名） 体设 CArrowType::vftable（RTTI 名） |
| 0x1423977C0 | CDummyAchievementsContext::[11] vtable 槽 CDummyAchievementsContext::[11]（func_names RTTI 名） |
| 0x140F77090 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x142397900 | CDummyAchievementsContext::[12] vtable 槽 CDummyAchievementsContext::[12]（func_names RTTI 名） |
| 0x141016BB0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x1410A31F0 | （无名） 体设 CRadarsPool::vftable（RTTI 名） |
| 0x140A0A7A0 | CDynamicEquipmentGroup::[9] vtable 槽 CDynamicEquipmentGroup::[9]（func_names RTTI 名） |
| 0x140F140E0 | （无名） 体设 SWeatherPerProvince::vftable（RTTI 名） |
| 0x140E75510 | （无名） 体设 CProgramStatus::vftable（RTTI 名） |
| 0x1411092F0 | CRequestPuppetForcesAction::[56] vtable 槽 CRequestPuppetForcesAction::[56]（func_names RTTI 名） |
| 0x1418C4760 | CDecisionMapIconContainer::[10] vtable 槽 CDecisionMapIconContainer::[10]（func_names RTTI 名） |
| 0x14232B360 | （无名） 体设 CGuiType::vftable（RTTI 名） |
| 0x141D10B30 | （无名） 体设 CHistoryEntryItemBase::vftable（RTTI 名） |
| 0x140CA5BE0 | （无名） 体设 CResourceOrigin::vftable（RTTI 名） |
| 0x141EC2250 | CIntelLedgerCivilianPanelController::[2] vtable 槽 CIntelLedgerCivilianPanelController::[2]（func_names RTTI 名） |
| 0x140C92050 | （无名） 体设 CDuplicateArchetypeDefinition::vftable（RTTI 名） |
| 0x140AAB6F0 | （无名） 体设 CScriptableLocalizationDatabase::vftable（RTTI 名） |
| 0x1423694C0 | （无名） 体设 CProxyServer::vftable（RTTI 名） |
| 0x140DB7A50 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1403E8260 | CTriggerEntry<CLogisticsSkillLevelTrigger>::[1] func_names 名 CTriggerEntry<CLogisticsSkillLevelTrigger>::[1] |
| 0x140A03900 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x14151E8D0 | CTakeNavyPeaceAction::GetTargetName func_names 名 CTakeNavyPeaceAction::GetTargetName |
| 0x1422D6850 | CTextSprite::[48] vtable 槽 CTextSprite::[48]（func_names RTTI 名） |
| 0x14021EAC0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422AB700 | CFixedMaxSizeListbox<CStandardlistboxItem>::[6] func_names 名 CFixedMaxSizeListbox<CStandardlistboxItem>::[6] |
| 0x141FEDF80 | CStatTooltipHandler<鈥�>::[0] func_names 名 CStatTooltipHandler<鈥�>::[0] |
| 0x141BE5690 | CConfirmResearchTechnology::[9] vtable 槽 CConfirmResearchTechnology::[9]（func_names RTTI 名） |
| 0x1410D8DD0 | COperativesAiAssignmentTextLogger::[4] vtable 槽 COperativesAiAssignmentTextLogger::[4]（func_names RTTI 名） |
| 0x14153D720 | CFriendsHandlerSteam::[14] vtable 槽 CFriendsHandlerSteam::[14]（func_names RTTI 名） |
| 0x14237A310 | （无名） 体设 CRadioButtonGroupType::vftable（RTTI 名） |
| 0x141190C40 | （无名） 体设 CIdeology::vftable（RTTI 名） |
| 0x1403E38D0 | CTriggerEntry<CAttackSkillLevelTrigger>::[1] func_names 名 CTriggerEntry<CAttackSkillLevelTrigger>::[1] |
| 0x1403CD040 | CForEachScopesTriggerImp<$0A>::[22] func_names 名 CForEachScopesTriggerImp<$0A>::[22] |
| 0x1422D5530 | （无名） 体设 CTextSprite::vftable（RTTI 名） |
| 0x1403B2D30 | CEveryCountryWithOriginalTag::ParseToken func_names 名 CEveryCountryWithOriginalTag::ParseToken |
| 0x141DCBBA0 | （无名） 体设 CEntitySprite::vftable（RTTI 名） |
| 0x141D3FBA0 | CPlanesOverview::Reload func_names 名 CPlanesOverview::Reload |
| 0x1422AB4E0 | CStandardlistbox::[7] vtable 槽 CStandardlistbox::[7]（func_names RTTI 名） |
| 0x140643FE0 | （无名） 体设 CAIOperativeOperationStrategy::vftable（RTTI 名） |
| 0x14111C4F0 | CReturnAllExpeditionaryForcesAction::GetAiAcceptance func_names 名 CReturnAllExpeditionaryForcesAction::GetAiAcceptance |
| 0x141EBB270 | CIntelLedgerCivilianPanelController::[0] vtable 槽 CIntelLedgerCivilianPanelController::[0]（func_names RTTI 名） |
| 0x14030D670 | CAddDemilitarizedZone::Execute func_names 名 CAddDemilitarizedZone::Execute |
| 0x14139B3D0 | CRandomListEffectMember::[4] vtable 槽 CRandomListEffectMember::[4]（func_names RTTI 名） |
| 0x1423DD0C0 | CSteamCloudStorageContext::[12] vtable 槽 CSteamCloudStorageContext::[12]（func_names RTTI 名） |
| 0x141233DD0 | （无名） 体设 CUnitMoveAction::vftable（RTTI 名） |
| 0x141A0EB70 | （无名） 体设 CWeatherChancePeriod::vftable（RTTI 名） |
| 0x1423E0A50 | CSteamMatchmakingContext::[13] vtable 槽 CSteamMatchmakingContext::[13]（func_names RTTI 名） |
| 0x1409BF920 | （无名） 体设 CNameGroup::vftable（RTTI 名） |
| 0x142330E80 | （无名） 体设 SParticleSystemReader::vftable（RTTI 名） |
| 0x140AEEE50 | （无名） 体设 CUnitNamesDatabase::vftable（RTTI 名） |
| 0x1416CB4B0 | CSkillTreeBase<CUnitLeaderTraitTreeItem>::[30] func_names 名 CSkillTreeBase<CUnitLeaderTraitTreeItem>::[30] |
| 0x1422D1400 | CButtonStandard::[85] vtable 槽 CButtonStandard::[85]（func_names RTTI 名） |
| 0x140DC70E0 | CInGameIdler::[57] vtable 槽 CInGameIdler::[57]（func_names RTTI 名） |
| 0x14014AA30 | （无名） 体设 CProgress::vftable（RTTI 名） |
| 0x141141960 | （无名） 体设 SDecisionData::vftable（RTTI 名） |
| 0x140AC6560 | （无名） 体设 CTechnologySharingGroupDatabase::vftable（RTTI 名） |
| 0x1422AB1C0 | CChoice<CSmoothListboxItem>::[7] func_names 名 CChoice<CSmoothListboxItem>::[7] |
| 0x1403D7A00 | CHasOccupationModifier::Evaluate func_names 名 CHasOccupationModifier::Evaluate |
| 0x1415BDA10 | CConfirmRemoveAllRegions::[14] vtable 槽 CConfirmRemoveAllRegions::[14]（func_names RTTI 名） |
| 0x1419C84B0 | （无名） 体设 CTutorialHint::vftable（RTTI 名） |
| 0x142409690 | （无名） 体设 CEffectHandler::vftable（RTTI 名） |
| 0x14071DB70 | （无名） 体设 CCountryLeaderTrait::vftable（RTTI 名） |
| 0x1413DF740 | CAdvisorTemplate::[8] vtable 槽 CAdvisorTemplate::[8]（func_names RTTI 名） |
| 0x140464740 | CHasResistance::Evaluate func_names 名 CHasResistance::Evaluate |
| 0x141537680 | （无名） 体设 CEquipmentUpgrade::vftable（RTTI 名） |
| 0x141681D60 | CStateGraphics::UpdateIntelMapModeMapIcon? func_names 名 CStateGraphics::UpdateIntelMapModeMapIcon? |
| 0x140F62DD0 | CAirWingPool::[8] vtable 槽 CAirWingPool::[8]（func_names RTTI 名） |
| 0x140DB4C30 | （无名） 体设 SHistoryWithEquipment::vftable（RTTI 名） |
| 0x141DBFBD0 | （无名） 体设 CBuildingItemBase::vftable（RTTI 名） |
| 0x141C8C8F0 | CDiplomacyStageCoupController::[1] vtable 槽 CDiplomacyStageCoupController::[1]（func_names RTTI 名） |
| 0x141235D00 | CUnitNavalMoveAction::[23] vtable 槽 CUnitNavalMoveAction::[23]（func_names RTTI 名） |
| 0x140B51D00 | （无名） 体设 CTextBlock::vftable（RTTI 名） |
| 0x141F6FA50 | （无名） 体设 STickUpdater::vftable（RTTI 名） |
| 0x1401477E0 | （无名） 体设 CFactionUpgradeGroup::vftable（RTTI 名） |
| 0x1422AB850 | CSimpleListbox<CStandardlistboxItem>::[6] func_names 名 CSimpleListbox<CStandardlistboxItem>::[6] |
| 0x1422D7410 | CPdx3DObject::[1] vtable 槽 CPdx3DObject::[1]（func_names RTTI 名） |
| 0x141100F90 | CGenerateWarGoalAction::[24] vtable 槽 CGenerateWarGoalAction::[24]（func_names RTTI 名） |
| 0x140E8BD60 | CRailwayGun::[8] vtable 槽 CRailwayGun::[8]（func_names RTTI 名） |
| 0x142308A70 | （无名） 体设 SMeshVariant::vftable（RTTI 名） |
| 0x141A038C0 | CRailwayProductionLine::[23] vtable 槽 CRailwayProductionLine::[23]（func_names RTTI 名） |
| 0x141B45840 | CBuildingsNudger::Reload func_names 名 CBuildingsNudger::Reload |
| 0x141DFFA80 | （无名） 体设 SCachedInfo::vftable（RTTI 名） |
| 0x140D7C880 | （无名） 体设 CFolderStatus::vftable（RTTI 名） |
| 0x14234C6A0 | （无名） 体设 SAnimatedLightReader::vftable（RTTI 名） |
| 0x1403FF570 | CGameRulesAllowAchievements::GetDesc func_names 名 CGameRulesAllowAchievements::GetDesc |
| 0x141B453D0 | CBuildingsNudger::Update func_names 名 CBuildingsNudger::Update |
| 0x1403426E0 | CEffectEntry<CTransferUnitsFractionEffect>::[1] func_names 名 CEffectEntry<CTransferUnitsFractionEffect>::[1] |
| 0x140A92BC0 | （无名） 体设 CPrototypeReward::vftable（RTTI 名） |
| 0x141DF3A50 | CMapModeMilitaryDeploymentToOrder::[9] vtable 槽 CMapModeMilitaryDeploymentToOrder::[9]（func_names RTTI 名） |
| 0x142395B60 | CPdxCrashReportWindows::[8] vtable 槽 CPdxCrashReportWindows::[8]（func_names RTTI 名） |
| 0x14044AE90 | CIsPromotedFromUnit::[21] vtable 槽 CIsPromotedFromUnit::[21]（func_names RTTI 名） |
| 0x140448B50 | CIsCorpsCommander::GetDesc func_names 名 CIsCorpsCommander::GetDesc |
| 0x1404455A0 | CCanBeCaptured::GetDesc func_names 名 CCanBeCaptured::GetDesc |
| 0x140447620 | CHasNavyLedger::GetDesc func_names 名 CHasNavyLedger::GetDesc |
| 0x1404481E0 | CIsArmyLeader::GetDesc func_names 名 CIsArmyLeader::GetDesc |
| 0x14044A930 | CIsNavyLeader::GetDesc func_names 名 CIsNavyLeader::GetDesc |
| 0x14041D9A0 | CIsBorderWar::GetDesc func_names 名 CIsBorderWar::GetDesc |
| 0x14044A7A0 | CIsNavyChief::GetDesc func_names 名 CIsNavyChief::GetDesc |
| 0x141100990 | CCallAllyAction::[24] vtable 槽 CCallAllyAction::[24]（func_names RTTI 名） |
| 0x14033C340 | CEffectEntry<CAddScientistRoleEffect>::[1] func_names 名 CEffectEntry<CAddScientistRoleEffect>::[1] |
| 0x1402CD200 | CNationalFocusTree::[0] vtable 槽 CNationalFocusTree::[0]（func_names RTTI 名） |
| 0x1402EA830 | CAddMaxAssignableTrait::GetDesc func_names 名 CAddMaxAssignableTrait::GetDesc |
| 0x14068E410 | （无名） 体设 SCareerProfileModDataSet::vftable（RTTI 名） |
| 0x141436E60 | （无名） 体设 CLicensedProductionStatus::vftable（RTTI 名） |
| 0x1422D0B90 | CButtonStandard::[89] vtable 槽 CButtonStandard::[89]（func_names RTTI 名） |
| 0x1411394E0 | CCallAllyAction::[57] vtable 槽 CCallAllyAction::[57]（func_names RTTI 名） |
| 0x1411010D0 | CGiveStateControlAction::[24] vtable 槽 CGiveStateControlAction::[24]（func_names RTTI 名） |
| 0x1415739A0 | （无名） 体设 CMapModesInterface::vftable（RTTI 名） |
| 0x1411014D0 | CJoinAllyAction::[24] vtable 槽 CJoinAllyAction::[24]（func_names RTTI 名） |
| 0x14147BBC0 | （无名） 体设 SMasteryFromUnitLeader::vftable（RTTI 名） |
| 0x140EEC240 | （无名） 体设 SPerCountrySection::vftable（RTTI 名） |
| 0x1403A47B0 | CFinalizeBorderWar::[5] vtable 槽 CFinalizeBorderWar::[5]（func_names RTTI 名） |
| 0x14229BF50 | CBitmapFont::[18] vtable 槽 CBitmapFont::[18]（func_names RTTI 名） |
| 0x1413DF960 | SAdvisorBonus::[3] vtable 槽 SAdvisorBonus::[3]（func_names RTTI 名） |
| 0x140AEFFB0 | CUnitNamesPool::[0] vtable 槽 CUnitNamesPool::[0]（func_names RTTI 名） |
| 0x1413AB060 | （无名） 体设 CBoundLocalization::vftable（RTTI 名） |
| 0x140B3BAC0 | CInGameIdler::[21] vtable 槽 CInGameIdler::[21]（func_names RTTI 名） |
| 0x1422DDEB0 | CGuiType::[0] vtable 槽 CGuiType::[0]（func_names RTTI 名） |
| 0x141392570 | CRandomListEffectMember::[0] vtable 槽 CRandomListEffectMember::[0]（func_names RTTI 名） |
| 0x1419C86A0 | CHintOpener::[0] vtable 槽 CHintOpener::[0]（func_names RTTI 名） |
| 0x141C93D50 | CDiplomacyInviteFactionController::[20] vtable 槽 CDiplomacyInviteFactionController::[20]（func_names RTTI 名） |
| 0x1411202E0 | CIncreaseAutonomyAction::[59] vtable 槽 CIncreaseAutonomyAction::[59]（func_names RTTI 名） |
| 0x1414544C0 | CConferenceWinnerParticipant::[1] vtable 槽 CConferenceWinnerParticipant::[1]（func_names RTTI 名） |
| 0x141C9B060 | CDiplomacyIncomingLendLeaseActionController::[7] vtable 槽 CDiplomacyIncomingLendLeaseActionController::[7]（func_names RTTI 名） |
| 0x14014ADE0 | （无名） 体设 CDatabaseObject::vftable（RTTI 名） |
| 0x142353490 | CCorneredTileSprite::[9] vtable 槽 CCorneredTileSprite::[9]（func_names RTTI 名） |
| 0x14234BCC0 | （无名） 体设 SEntityAttachmentReader::vftable（RTTI 名） |
| 0x1406C0EA0 | （无名） 体设 CContinuousFocusDatabase::vftable（RTTI 名） |
| 0x1423A9E40 | （无名） 体设 PdxSpeechToTextInterface::vftable（RTTI 名） |
| 0x140E1FFE0 | CStrategicRegion::[0] vtable 槽 CStrategicRegion::[0]（func_names RTTI 名） |
| 0x1403C65D0 | （无名） 体设 SSupportCategoryStatMultiplier::vftable（RTTI 名） |
| 0x140484460 | CSetPowerBalanceGfx::Execute func_names 名 CSetPowerBalanceGfx::Execute |
| 0x1406C11F0 | CContinuousFocusDatabase::[1] vtable 槽 CContinuousFocusDatabase::[1]（func_names RTTI 名） |
| 0x1422ED6D0 | （无名） 体设 CTextBuffer::vftable（RTTI 名） |
| 0x141484300 | （无名） 体设 CSavedAchievementMod::vftable（RTTI 名） |
| 0x140535300 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x140535420 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x14111F6C0 | CEmbargoAction::[58] vtable 槽 CEmbargoAction::[58]（func_names RTTI 名） |
| 0x1412A3870 | CAdvisor::[8] vtable 槽 CAdvisor::[8]（func_names RTTI 名） |
| 0x141349430 | （无名） 体设 CReorderNavalRepairQueue::vftable（RTTI 名） |
| 0x1422D2030 | CButtonStandard::[86] vtable 槽 CButtonStandard::[86]（func_names RTTI 名） |
| 0x1423E0690 | CSteamMatchmakingContext::[21] vtable 槽 CSteamMatchmakingContext::[21]（func_names RTTI 名） |
| 0x14031F2E0 | CEffectEntry<CStealRandomTechBonusEffect>::[1] func_names 名 CEffectEntry<CStealRandomTechBonusEffect>::[1] |
| 0x1422AC8C0 | CChoice<CSmoothListboxItem>::[9] func_names 名 CChoice<CSmoothListboxItem>::[9] |
| 0x1422FE020 | CSprite::[5] vtable 槽 CSprite::[5]（func_names RTTI 名） |
| 0x1422FDE40 | CSprite::[40] vtable 槽 CSprite::[40]（func_names RTTI 名） |
| 0x141346190 | （无名） 体设 CAddToOrRemoveShipFromNavalRepairQueue::vftable（RTTI 名） |
| 0x141D3F770 | CPlanesOverview::[0] vtable 槽 CPlanesOverview::[0]（func_names RTTI 名） |
| 0x14016C940 | CApplication::[1] vtable 槽 CApplication::[1]（func_names RTTI 名） |
| 0x1412D2680 | COption::[1] vtable 槽 COption::[1]（func_names RTTI 名） |
| 0x14186D6B0 | CChatBuffer::[1] vtable 槽 CChatBuffer::[1]（func_names RTTI 名） |
| 0x142230780 | CKeyBoard::[1] vtable 槽 CKeyBoard::[1]（func_names RTTI 名） |
| 0x142230A80 | CMouse::[1] vtable 槽 CMouse::[1]（func_names RTTI 名） |
| 0x142230B80 | CMouse::[1] vtable 槽 CMouse::[1]（func_names RTTI 名） |
| 0x1422AA1B0 | CChoiceObservable<CStandardlistboxItem>::[1] func_names 名 CChoiceObservable<CStandardlistboxItem>::[1] |
| 0x1422FFC80 | CChoiceObservable<CSmoothListboxItem>::[1] func_names 名 CChoiceObservable<CSmoothListboxItem>::[1] |
| 0x1404A01D0 | CCreateProductionLicense::ParseToken func_names 名 CCreateProductionLicense::ParseToken |
| 0x140FC9C70 | （无名） 体设 CCountryLeader::vftable（RTTI 名） |
| 0x140FCBC80 | CCountryLeader::[8] vtable 槽 CCountryLeader::[8]（func_names RTTI 名） |
| 0x14167E5E0 | CRegionGraphics::[0] vtable 槽 CRegionGraphics::[0]（func_names RTTI 名） |
| 0x140A926D0 | ULexerToken::UEAAXAEAVCReader::NProject::SOutput::?3??ReadMembe鈥�::[2] func_names 名 ULexerToken::UEAAXAEAVCReader::NProject::SOutput::?3??ReadMembe鈥�::[2] |
| 0x14136E2F0 | CEquipmentInFieldLogger::[9] vtable 槽 CEquipmentInFieldLogger::[9]（func_names RTTI 名） |
| 0x14133BFF0 | CChat::CChatItem::[7] vtable 槽 CChat::CChatItem::[7]（func_names RTTI 名） |
| 0x14042D010 | CNumResearchedTechnologies::GetDesc func_names 名 CNumResearchedTechnologies::GetDesc |
| 0x141100DA0 | CDeclareWarAction::[24] vtable 槽 CDeclareWarAction::[24]（func_names RTTI 名） |
| 0x140DE0270 | CInGameIdler::[108] vtable 槽 CInGameIdler::[108]（func_names RTTI 名） |
| 0x141436FD0 | CLicensedProductionStatus::[0] vtable 槽 CLicensedProductionStatus::[0]（func_names RTTI 名） |
| 0x141B7D7A0 | CWeatherNudger::Update func_names 名 CWeatherNudger::Update |
| 0x140F6F8D0 | CRailwayGunProductionLine::[12] vtable 槽 CRailwayGunProductionLine::[12]（func_names RTTI 名） |
| 0x14030B680 | CEffectEntry<CAddResistanceTargetEffect>::[1] func_names 名 CEffectEntry<CAddResistanceTargetEffect>::[1] |
| 0x1423DCFD0 | CSteamCloudStorageContext::[13] vtable 槽 CSteamCloudStorageContext::[13]（func_names RTTI 名） |
| 0x140CE7120 | CMilitaryDeployment::[0] vtable 槽 CMilitaryDeployment::[0]（func_names RTTI 名） |
| 0x1414BAD50 | CBuildingTemplate::SCountryModifier::[7] vtable 槽 CBuildingTemplate::SCountryModifier::[7]（func_names RTTI 名） |
| 0x141D0F3C0 | CConfirmUnassignUnits::Update func_names 名 CConfirmUnassignUnits::Update |
| 0x141921270 | CPersistedDesignsDb::[1] vtable 槽 CPersistedDesignsDb::[1]（func_names RTTI 名） |
| 0x140AD5E60 | CTerrainDatabase::[1] vtable 槽 CTerrainDatabase::[1]（func_names RTTI 名） |
| 0x141976430 | CFEXMember::SCachedInfo::Writer func_names 名 CFEXMember::SCachedInfo::Writer |
| 0x1422D3100 | （无名） 体设 CArrowObject::vftable（RTTI 名） |
| 0x14194B750 | （无名） 体设 CAIBaseGeneral::vftable（RTTI 名） |
| 0x1403EE1A0 | CNumCompletedOperations::GetValue func_names 名 CNumCompletedOperations::GetValue |
| 0x14051D810 | CTriggerEntry<CCountInCollectionTrigger>::[1] func_names 名 CTriggerEntry<CCountInCollectionTrigger>::[1] |
| 0x141100670 | CAddWarGoalAction::[24] vtable 槽 CAddWarGoalAction::[24]（func_names RTTI 名） |
| 0x1422D3310 | CArrowObject::[16] vtable 槽 CArrowObject::[16]（func_names RTTI 名） |
| 0x1415780D0 | （无名） 体设 CMessageType::vftable（RTTI 名） |
| 0x141E0AC40 | （无名） 体设 CNavyTheaterNavyItemBase::vftable（RTTI 名） |
| 0x1409BFBF0 | （无名） 体设 CNameGroupMember::vftable（RTTI 名） |
| 0x142403DE0 | CSteamUGCContext::[11] vtable 槽 CSteamUGCContext::[11]（func_names RTTI 名） |
| 0x1417CBEB0 | CMinimapInterface::[0] vtable 槽 CMinimapInterface::[0]（func_names RTTI 名） |
| 0x1412D9130 | CGfxTradeRoute::[0] vtable 槽 CGfxTradeRoute::[0]（func_names RTTI 名） |
| 0x1406311D0 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x140B73BF0 | CMapIconManager<$0CC>::[2] func_names 名 CMapIconManager<$0CC>::[2] |
| 0x1403B4510 | CReduceFocusCost::ParseToken func_names 名 CReduceFocusCost::ParseToken |
| 0x1410A2E00 | （无名） 体设 CRadarsPool::vftable（RTTI 名） |
| 0x141C98D60 | CDiplomacySendVolunteersController::[2] vtable 槽 CDiplomacySendVolunteersController::[2]（func_names RTTI 名） |
| 0x141DD4A40 | CEquipmentDesignerModelSelector::[1] vtable 槽 CEquipmentDesignerModelSelector::[1]（func_names RTTI 名） |
| 0x141915A40 | （无名） 体设 CDynamicEquipmentGroup::vftable（RTTI 名） |
| 0x14229C320 | CBitmapFont::[15] vtable 槽 CBitmapFont::[15]（func_names RTTI 名） |
| 0x140342100 | CEffectEntry<CStartBorderWarEffect>::[1] func_names 名 CEffectEntry<CStartBorderWarEffect>::[1] |
| 0x1410F9550 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1419C8940 | CTutorialMinimized::[0] vtable 槽 CTutorialMinimized::[0]（func_names RTTI 名） |
| 0x1419D80B0 | CDebugMapModeConfig::CCallbacksWrapper::[2] vtable 槽 CDebugMapModeConfig::CCallbacksWrapper::[2]（func_names RTTI 名） |
| 0x1416CB3C0 | CSkillTreeBase<CUnitLeaderTraitTreeItem>::[24] func_names 名 CSkillTreeBase<CUnitLeaderTraitTreeItem>::[24] |
| 0x141FC09B0 | CSkillTreeBase<NIndustrialOrganisation::CTraitTreeItem>::[24] func_names 名 CSkillTreeBase<NIndustrialOrganisation::CTraitTreeItem>::[24] |
| 0x141D42D50 | （无名） 体设 CShipsOverview::vftable（RTTI 名） |
| 0x141101BA0 | CRequestForeignManpowerAction::[24] vtable 槽 CRequestForeignManpowerAction::[24]（func_names RTTI 名） |
| 0x1417E2CC0 | （无名） 体设 CCombatBoxGrids::vftable（RTTI 名） |
| 0x141101E10 | CRequestPuppetForcesAction::[24] vtable 槽 CRequestPuppetForcesAction::[24]（func_names RTTI 名） |
| 0x141FEE170 | CStatTooltipHandler<鈥�>::[0] func_names 名 CStatTooltipHandler<鈥�>::[0] |
| 0x1403015D0 | CMultipleTargetEffect<鈥�>::[4] func_names 名 CMultipleTargetEffect<鈥�>::[4] |
| 0x140147360 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x1409FB410 | （无名） 体设 CEquipmentFilter::vftable（RTTI 名） |
| 0x140A0A950 | CEquipmentGroup::[9] vtable 槽 CEquipmentGroup::[9]（func_names RTTI 名） |
| 0x141C98E80 | CDiplomacyStageCoupController::[2] vtable 槽 CDiplomacyStageCoupController::[2]（func_names RTTI 名） |
| 0x14151DE80 | CLiberateCountryAction::GetDescription func_names 名 CLiberateCountryAction::GetDescription |
| 0x14151DFE0 | CPuppetCountryAction::GetDescription func_names 名 CPuppetCountryAction::GetDescription |
| 0x1403CB200 | CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>::[0] func_names 名 CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>::[0] |
| 0x141234110 | （无名） 体设 CUnitStrategicMoveAction::vftable（RTTI 名） |
| 0x1403477A0 | CSetOrAddVictoryPointsEffect<$00>::[13] func_names 名 CSetOrAddVictoryPointsEffect<$00>::[13] |
| 0x140FC9D40 | （无名） 体设 CCountryLeader::vftable（RTTI 名） |
| 0x141101AB0 | CRequestAccessToLicenseProductionAction::[24] vtable 槽 CRequestAccessToLicenseProductionAction::[24]（func_names RTTI 名） |
| 0x140CABCA0 | CResourceExchange::[10] vtable 槽 CResourceExchange::[10]（func_names RTTI 名） |
| 0x141101F00 | CReturnAllExpeditionaryForcesAction::[24] vtable 槽 CReturnAllExpeditionaryForcesAction::[24]（func_names RTTI 名） |
| 0x141A9BDB0 | COfferAirBaseAccessAction::[24] vtable 槽 COfferAirBaseAccessAction::[24]（func_names RTTI 名） |
| 0x1411016F0 | CNonAggressionPactAction::[24] vtable 槽 CNonAggressionPactAction::[24]（func_names RTTI 名） |
| 0x14208D740 | CTweakableTextbox::[13] vtable 槽 CTweakableTextbox::[13]（func_names RTTI 名） |
| 0x140B86110 | CScriptedWindowManager::[0] vtable 槽 CScriptedWindowManager::[0]（func_names RTTI 名） |
| 0x141A9BCC0 | CAirBaseAccessAction::[24] vtable 槽 CAirBaseAccessAction::[24]（func_names RTTI 名） |
| 0x1410F8FF0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422D1C70 | CButtonStandard::[113] vtable 槽 CButtonStandard::[113]（func_names RTTI 名） |
| 0x141101200 | CGuaranteeAction::[24] vtable 槽 CGuaranteeAction::[24]（func_names RTTI 名） |
| 0x141127450 | CTransferSpyMasterAction::[50] vtable 槽 CTransferSpyMasterAction::[50]（func_names RTTI 名） |
| 0x141100EA0 | CEmbargoAction::[24] vtable 槽 CEmbargoAction::[24]（func_names RTTI 名） |
| 0x141269B80 | （无名） 体设 CMapArrowButtonDefinition::vftable（RTTI 名） |
| 0x14033C9B0 | CEffectEntry<CBuildRailwayEffect>::[1] func_names 名 CEffectEntry<CBuildRailwayEffect>::[1] |
| 0x140467D90 | CTriggerEntry<CAnyStateOfTrigger>::[1] func_names 名 CTriggerEntry<CAnyStateOfTrigger>::[1] |
| 0x141B1FB40 | CMapSymbolDefinition::STextDef::Reader func_names 名 CMapSymbolDefinition::STextDef::Reader |
| 0x140D7FCA0 | （无名） 体设 STemporaryMasteryGain::vftable（RTTI 名） |
| 0x1403478B0 | CSetOrAddVictoryPointsEffect<$0A>::[13] func_names 名 CSetOrAddVictoryPointsEffect<$0A>::[13] |
| 0x140D7CA00 | （无名） 体设 CTrackStatus::vftable（RTTI 名） |
| 0x141266290 | CMapArrowTextDefinition::[0] vtable 槽 CMapArrowTextDefinition::[0]（func_names RTTI 名） |
| 0x142236050 | （无名） 体设 SAnimationMapData::vftable（RTTI 名） |
| 0x1422737A0 | CLauncherSettings::[0] vtable 槽 CLauncherSettings::[0]（func_names RTTI 名） |
| 0x1411209F0 | CRequestForeignManpowerAction::[59] vtable 槽 CRequestForeignManpowerAction::[59]（func_names RTTI 名） |
| 0x14127D500 | CPdxMap::[1] vtable 槽 CPdxMap::[1]（func_names RTTI 名） |
| 0x1409BFD10 | （无名） 体设 CNameGroupMember::vftable（RTTI 名） |
| 0x141FEDA60 | CStatTooltipHandler<鈥�>::[0] func_names 名 CStatTooltipHandler<鈥�>::[0] |
| 0x1422D4BD0 | CInstantSprite::[10] vtable 槽 CInstantSprite::[10]（func_names RTTI 名） |
| 0x141236070 | CUnitMoveAction::[24] vtable 槽 CUnitMoveAction::[24]（func_names RTTI 名） |
| 0x1420898A0 | CTweakableCategory::[0] vtable 槽 CTweakableCategory::[0]（func_names RTTI 名） |
| 0x140303680 | CEffectEntry<NInternationalMarket::CAddEquipmentSubsidyEffect>::[1] func_names 名 CEffectEntry<NInternationalMarket::CAddEquipmentSubsidyEffect>::[1] |
| 0x1414E6400 | （无名） 体设 SAdvisorData::vftable（RTTI 名） |
| 0x1422AC6D0 | CStandardlistbox::[8] vtable 槽 CStandardlistbox::[8]（func_names RTTI 名） |
| 0x14033D610 | CEffectEntry<CDamageUnitsEffect>::[1] func_names 名 CEffectEntry<CDamageUnitsEffect>::[1] |
| 0x14046CE70 | CHasResistance::GetDesc func_names 名 CHasResistance::GetDesc |
| 0x1424B8DC0 | （无名） 体设 CTweakable::vftable（RTTI 名） |
| 0x140B88DC0 | CScriptedWindowManager::PreSetup func_names 名 CScriptedWindowManager::PreSetup |
| 0x14049AF20 | CAddEquipmentBonus::[0] vtable 槽 CAddEquipmentBonus::[0]（func_names RTTI 名） |
| 0x14153D630 | CFriendsHandlerSteam::[16] vtable 槽 CFriendsHandlerSteam::[16]（func_names RTTI 名） |
| 0x1413D1EF0 | （无名） 体设 CTechnologySharingGroupTemplate::vftable（RTTI 名） |
| 0x140D01F40 | （无名） 体设 CStaticIntelSourcePool::vftable（RTTI 名） |
| 0x14033E650 | CEffectEntry<CGenerateScientistRoleEffect>::[1] func_names 名 CEffectEntry<CGenerateScientistRoleEffect>::[1] |
| 0x14134D0C0 | CRestructureShipsToTaskforceCompositions::Clone func_names 名 CRestructureShipsToTaskforceCompositions::Clone |
| 0x141DF8700 | CStandardMusicPlaybackController::[6] vtable 槽 CStandardMusicPlaybackController::[6]（func_names RTTI 名） |
| 0x1422E7B70 | （无名） 体设 CSendChatMessage::vftable（RTTI 名） |
| 0x141DE9F70 | CConfirmSaveGame::[0] vtable 槽 CConfirmSaveGame::[0]（func_names RTTI 名） |
| 0x1401E40A0 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x1409B8360 | （无名） 体设 CDifficultySetting::vftable（RTTI 名） |
| 0x1422D7060 | CTextSprite::[50] vtable 槽 CTextSprite::[50]（func_names RTTI 名） |
| 0x1401C36D0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140301730 | CSingleTargetEffect<鈥�>::[4] func_names 名 CSingleTargetEffect<鈥�>::[4] |
| 0x14033EC90 | CEffectEntry<CLegacyCreateCountryLeaderEffect>::[1] func_names 名 CEffectEntry<CLegacyCreateCountryLeaderEffect>::[1] |
| 0x1424EE7E0 | CRemoteFile::[6] vtable 槽 CRemoteFile::[6]（func_names RTTI 名） |
| 0x1403AEE60 | CSingleTargetEffect<$01::CState>::[4] func_names 名 CSingleTargetEffect<$01::CState>::[4] |
| 0x1413392A0 | （无名） 体设 CPdxSocialPlayerId::vftable（RTTI 名） |
| 0x141502950 | CLendLeaseAction::[23] vtable 槽 CLendLeaseAction::[23]（func_names RTTI 名） |
| 0x142401990 | PdxSocialPermissions::ChatBooleanPermission::[3] vtable 槽 PdxSocialPermissions::ChatBooleanPermission::[3]（func_names RTTI 名） |
| 0x1411348E0 | CMilitaryAccessAction::CanExecute func_names 名 CMilitaryAccessAction::CanExecute |
| 0x140309E40 | （无名） 体设 CBoundLocalization::vftable（RTTI 名） |
| 0x140A85C60 | （无名） 体设 CCountryPortraits::vftable（RTTI 名） |
| 0x1410FA120 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14183E840 | COrderReplaceRootCommands::Clone func_names 名 COrderReplaceRootCommands::Clone |
| 0x140334D20 | CRandomizeVariableEffect<CVariableResolver>::[6] func_names 名 CRandomizeVariableEffect<CVariableResolver>::[6] |
| 0x140439980 | CHasBuilt::ParseToken func_names 名 CHasBuilt::ParseToken |
| 0x14033E300 | CEffectEntry<CForEffect>::[1] func_names 名 CEffectEntry<CForEffect>::[1] |
| 0x1411357E0 | CRequestLicensedProductionAction::CanExecute func_names 名 CRequestLicensedProductionAction::CanExecute |
| 0x1413FFE40 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141C99B30 | CDiplomacyAskForStateControlController::[7] vtable 槽 CDiplomacyAskForStateControlController::[7]（func_names RTTI 名） |
| 0x141502810 | CIncomingLendLeaseAction::[23] vtable 槽 CIncomingLendLeaseAction::[23]（func_names RTTI 名） |
| 0x14183B6D0 | （无名） 体设 CRemoveAdmiralFromNavyHeadquarter::vftable（RTTI 名） |
| 0x140D032F0 | （无名） 体设 CDynamicIntelSourcePool::vftable（RTTI 名） |
| 0x1424FB550 | （无名） 体设 CPdxLinearAllocator::vftable（RTTI 名） |
| 0x140EA5AA0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x14183A330 | （无名） 体设 COrderRemoveRootCommands::vftable（RTTI 名） |
| 0x14201AB10 | （无名） 体设 SCareerProfileMedalData::vftable（RTTI 名） |
| 0x141504430 | CIncomingLendLeaseAction::[45] vtable 槽 CIncomingLendLeaseAction::[45]（func_names RTTI 名） |
| 0x14151AD80 | CForceGovernmentAction::[24] vtable 槽 CForceGovernmentAction::[24]（func_names RTTI 名） |
| 0x1422ABCC0 | CStandardlistbox::[77] vtable 槽 CStandardlistbox::[77]（func_names RTTI 名） |
| 0x14152C130 | （无名） 体设 CEquipmentStatsGroup::vftable（RTTI 名） |
| 0x141463670 | （无名） 体设 SOptionalEquipmentAssets::vftable（RTTI 名） |
| 0x14183E740 | COrderReplaceFallbackCommands::Clone func_names 名 COrderReplaceFallbackCommands::Clone |
| 0x14223C750 | CMeshReloader::Reload func_names 名 CMeshReloader::Reload |
| 0x1422DC5E0 | （无名） 体设 CButtonWrapper::vftable（RTTI 名） |
| 0x1419D7100 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141B3D380 | CAmbientObjectNudger::[0] vtable 槽 CAmbientObjectNudger::[0]（func_names RTTI 名） |
| 0x14159D200 | （无名） 体设 CPersistentScriptTargets::vftable（RTTI 名） |
| 0x14127D630 | CPdxMap::[2] vtable 槽 CPdxMap::[2]（func_names RTTI 名） |
| 0x1410F9660 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1414BC490 | CBuildingTemplate::SCountryModifier::Reader func_names 名 CBuildingTemplate::SCountryModifier::Reader |
| 0x142276F00 | CPdxMeshObject::[12] vtable 槽 CPdxMeshObject::[12]（func_names RTTI 名） |
| 0x1422E0AF0 | CStartFileTransfer::Clone func_names 名 CStartFileTransfer::Clone |
| 0x140149E60 | （无名） 体设 COperationToken::vftable（RTTI 名） |
| 0x140FE39B0 | （无名） 体设 SProjectHistory::vftable（RTTI 名） |
| 0x1423AB0A0 | PdxTextToSpeechWinSAPI::[7] vtable 槽 PdxTextToSpeechWinSAPI::[7]（func_names RTTI 名） |
| 0x1422ACD30 | CStandardlistbox::[40] vtable 槽 CStandardlistbox::[40]（func_names RTTI 名） |
| 0x141FDFB40 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0740 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0D40 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1340 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1940 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0140 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1F40 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x1415C25B0 | CNavalCombat::[0] vtable 槽 CNavalCombat::[0]（func_names RTTI 名） |
| 0x141AA1870 | COfferDockingRightsAction::[57] vtable 槽 COfferDockingRightsAction::[57]（func_names RTTI 名） |
| 0x1422E81B0 | CChatBuffer::CWriteToChatBuffer::Clone func_names 名 CChatBuffer::CWriteToChatBuffer::Clone |
| 0x141D11300 | CHistoryEntryItemBase::[0] vtable 槽 CHistoryEntryItemBase::[0]（func_names RTTI 名） |
| 0x1410F91F0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14143C480 | （无名） 体设 CTerrainType::vftable（RTTI 名） |
| 0x1422D16F0 | CCallbackButtonStandard::[109] vtable 槽 CCallbackButtonStandard::[109]（func_names RTTI 名） |
| 0x140640DC0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x1422D5770 | CTextSprite::[11] vtable 槽 CTextSprite::[11]（func_names RTTI 名） |
| 0x1423E07B0 | CSteamMatchmakingContext::[17] vtable 槽 CSteamMatchmakingContext::[17]（func_names RTTI 名） |
| 0x140AB90D0 | （无名） 体设 CScriptedWindowDatabase::vftable（RTTI 名） |
| 0x1422E80F0 | CChatBuffer::CSendChatMessage::Clone func_names 名 CChatBuffer::CSendChatMessage::Clone |
| 0x140FCD5E0 | （无名） 体设 CIdeaCategory::vftable（RTTI 名） |
| 0x141113C40 | CRequestAccessToLicenseProductionAction::GetAiAcceptanceFactors func_names 名 CRequestAccessToLicenseProductionAction::GetAiAcceptanceFactors |
| 0x1422E7E40 | CChatBuffer::[0] vtable 槽 CChatBuffer::[0]（func_names RTTI 名） |
| 0x141914B90 | （无名） 体设 CAutomaticPause::vftable（RTTI 名） |
| 0x142308680 | CFrameAnimatedSprite::[9] vtable 槽 CFrameAnimatedSprite::[9]（func_names RTTI 名） |
| 0x140C980D0 | （无名） 体设 CUpgradeWindowOverride::vftable（RTTI 名） |
| 0x142354E50 | CCorneredTileSprite::[10] vtable 槽 CCorneredTileSprite::[10]（func_names RTTI 名） |
| 0x142295880 | （无名） 体设 CCorneredTileSpriteType::vftable（RTTI 名） |
| 0x14030C470 | CEffectEntry<CTeleportArmiesEffect>::[1] func_names 名 CEffectEntry<CTeleportArmiesEffect>::[1] |
| 0x141CC81C0 | CFrontEndBackgroundManager::Reload func_names 名 CFrontEndBackgroundManager::Reload |
| 0x14113A340 | CRequestLicensedProductionAction::[57] vtable 槽 CRequestLicensedProductionAction::[57]（func_names RTTI 名） |
| 0x141AA1750 | CDockingRightsAction::[57] vtable 槽 CDockingRightsAction::[57]（func_names RTTI 名） |
| 0x141653790 | CCitySettings::SGroup::Reader func_names 名 CCitySettings::SGroup::Reader |
| 0x141FDF780 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0380 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0980 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0F80 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1580 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1B80 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDFD80 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x140BA2920 | （无名） 体设 CEquipmentVariantReference::vftable（RTTI 名） |
| 0x141377400 | SCaseReader::[2] vtable 槽 SCaseReader::[2]（func_names RTTI 名） |
| 0x141FDF840 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDF900 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDF9C0 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDFA80 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDFC00 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDFE40 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDFF00 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FDFFC0 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0080 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0200 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0500 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE05C0 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0680 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0800 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0A40 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0B00 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0BC0 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0E00 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1040 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1100 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE11C0 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1280 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1400 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1640 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1700 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE17C0 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1880 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1A00 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1C40 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141134F10 | COfferMilitaryAccessAction::CanExecute func_names 名 COfferMilitaryAccessAction::CanExecute |
| 0x14150B1F0 | CGarrisonStatus::[5] vtable 槽 CGarrisonStatus::[5]（func_names RTTI 名） |
| 0x141C36700 | CEquipmentOverview::[0] vtable 槽 CEquipmentOverview::[0]（func_names RTTI 名） |
| 0x141FE0440 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE0C80 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1D00 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE1E80 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x141FE2000 | CCareerProfilePages::CreateTooltipHandlers? func_names 名 CCareerProfilePages::CreateTooltipHandlers? |
| 0x1403B2ED0 | CFinalizeBorderWar::ParseToken func_names 名 CFinalizeBorderWar::ParseToken |
| 0x140557200 | CDynamicModifier::[0] vtable 槽 CDynamicModifier::[0]（func_names RTTI 名） |
| 0x1403CCD60 | CFindHighestOrLowestElementTrigger<$0A>::[22] func_names 名 CFindHighestOrLowestElementTrigger<$0A>::[22] |
| 0x140630720 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x1423E8790 | CSteamNetContext::[13] vtable 槽 CSteamNetContext::[13]（func_names RTTI 名） |
| 0x140ACB960 | （无名） 体设 CTechnologyFolder::vftable（RTTI 名） |
| 0x140DF51E0 | CJointNationalFocus::[9] vtable 槽 CJointNationalFocus::[9]（func_names RTTI 名） |
| 0x141139D70 | CJoinAllyAction::[57] vtable 槽 CJoinAllyAction::[57]（func_names RTTI 名） |
| 0x140492C70 | CEffectEntry<NProject::CCompleteProjectEffect>::[1] func_names 名 CEffectEntry<NProject::CCompleteProjectEffect>::[1] |
| 0x140A4B260 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x140C127E0 | CNavyLeader::[11] vtable 槽 CNavyLeader::[11]（func_names RTTI 名） |
| 0x1414464C0 | （无名） 体设 CUnitMedal::vftable（RTTI 名） |
| 0x1410F9BD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1410FBBB0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1413FA140 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1413F34F0 | CCountryLeaderTemplate::[0] vtable 槽 CCountryLeaderTemplate::[0]（func_names RTTI 名） |
| 0x140FCD710 | （无名） 体设 CIdeaGroupType::vftable（RTTI 名） |
| 0x1402ADA20 | CTestBundle::[0] vtable 槽 CTestBundle::[0]（func_names RTTI 名） |
| 0x140FF3390 | CCountryOccupationData::[0] vtable 槽 CCountryOccupationData::[0]（func_names RTTI 名） |
| 0x14035DAC0 | CRemoveDecisionOnCooldown::Execute func_names 名 CRemoveDecisionOnCooldown::Execute |
| 0x140D74950 | CTaskForce::[3] vtable 槽 CTaskForce::[3]（func_names RTTI 名） |
| 0x141600050 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1405362C0 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x14143FBC0 | ULexerToken::UEAAXAEAVCReader::CTerrainType::?3??ReadMember::V<鈥�>::[2] func_names 名 ULexerToken::UEAAXAEAVCReader::CTerrainType::?3??ReadMember::V<鈥�>::[2] |
| 0x141A9E900 | COfferAirBaseAccessAction::[57] vtable 槽 COfferAirBaseAccessAction::[57]（func_names RTTI 名） |
| 0x1422CDF20 | （无名） 体设 CExcelParse::vftable（RTTI 名） |
| 0x141233CF0 | （无名） 体设 CUnitMoveAction::vftable（RTTI 名） |
| 0x141981880 | COfferDockingRightsRelation::[22] vtable 槽 COfferDockingRightsRelation::[22]（func_names RTTI 名） |
| 0x140A3A3A0 | CWarGoalDatabase::[1] vtable 槽 CWarGoalDatabase::[1]（func_names RTTI 名） |
| 0x140149A90 | （无名） 体设 CMeanTimeToHappen::vftable（RTTI 名） |
| 0x140D74AD0 | CTaskForce::[0] vtable 槽 CTaskForce::[0]（func_names RTTI 名） |
| 0x14229C470 | CBitmapFont::[8] vtable 槽 CBitmapFont::[8]（func_names RTTI 名） |
| 0x141B596B0 | CStateNudger::Reload func_names 名 CStateNudger::Reload |
| 0x1423AB930 | （无名） 体设 PdxSpeechToTextWinSAPI::vftable（RTTI 名） |
| 0x140675EE0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422FC950 | C2dPieChartTemplate<SPieVertex>::[15] func_names 名 C2dPieChartTemplate<SPieVertex>::[15] |
| 0x140617F30 | CAcesDatabase::[1] vtable 槽 CAcesDatabase::[1]（func_names RTTI 名） |
| 0x1410F98D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1403E6030 | CTriggerEntry<CHasLicenseTrigger>::[1] func_names 名 CTriggerEntry<CHasLicenseTrigger>::[1] |
| 0x1422FC420 | C2dPieChartTemplate<STexturedPieVertex>::[9] func_names 名 C2dPieChartTemplate<STexturedPieVertex>::[9] |
| 0x141139F70 | CNonAggressionPactAction::[57] vtable 槽 CNonAggressionPactAction::[57]（func_names RTTI 名） |
| 0x142397F90 | CPrimeAchievement::[0] vtable 槽 CPrimeAchievement::[0]（func_names RTTI 名） |
| 0x142356FE0 | C2dCircularProgressBarType::[0] vtable 槽 C2dCircularProgressBarType::[0]（func_names RTTI 名） |
| 0x140ED4CE0 | CLimitedUseTechBonus::[0] vtable 槽 CLimitedUseTechBonus::[0]（func_names RTTI 名） |
| 0x141393110 | CEffectEntry<CModifyGlobalFlagEffect>::[1] func_names 名 CEffectEntry<CModifyGlobalFlagEffect>::[1] |
| 0x14208D4B0 | CTweakableGraphManipulator::[13] vtable 槽 CTweakableGraphManipulator::[13]（func_names RTTI 名） |
| 0x1413C4E40 | ULexerToken::UEAAXAEAVCReader::CStateCategory::?3??ReadMember::鈥�::[2] func_names 名 ULexerToken::UEAAXAEAVCReader::CStateCategory::?3??ReadMember::鈥�::[2] |
| 0x141B625C0 | CStrategicRegionNudger::Reload func_names 名 CStrategicRegionNudger::Reload |
| 0x1411BF6E0 | CLocalIntelNetwork::[0] vtable 槽 CLocalIntelNetwork::[0]（func_names RTTI 名） |
| 0x141CF7570 | CDivisionNamesContainer::[1] vtable 槽 CDivisionNamesContainer::[1]（func_names RTTI 名） |
| 0x1403CD310 | CForEachTriggerImp<$0A>::[22] func_names 名 CForEachTriggerImp<$0A>::[22] |
| 0x141002C60 | CNavalRegionDominance::[0] vtable 槽 CNavalRegionDominance::[0]（func_names RTTI 名） |
| 0x14194CD40 | CAIGeneral::[19] vtable 槽 CAIGeneral::[19]（func_names RTTI 名） |
| 0x14033AC40 | CEffectEntry<CRandomizeVariableEffect<CTempVariableResolver>>::[1] func_names 名 CEffectEntry<CRandomizeVariableEffect<CTempVariableResolver>>::[1] |
| 0x1410FA5D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1417A1E70 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x1410F9740 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1417CCCE0 | CMinimapInterface::Reload func_names 名 CMinimapInterface::Reload |
| 0x1406133B0 | CAbilityDatabase::[1] vtable 槽 CAbilityDatabase::[1]（func_names RTTI 名） |
| 0x140AB1F80 | CScriptedDiplomaticAction::GetAiAcceptance func_names 名 CScriptedDiplomaticAction::GetAiAcceptance |
| 0x1417B8770 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1403E8430 | CTriggerEntry<CMetaTrigger>::[1] func_names 名 CTriggerEntry<CMetaTrigger>::[1] |
| 0x141F60110 | （无名） 体设 CAggressivenessOptionSelections::vftable（RTTI 名） |
| 0x1424BB150 | （无名） 体设 CLexer::vftable（RTTI 名） |
| 0x140A94730 | SUniformReader<鈥�>::[1] func_names 名 SUniformReader<鈥�>::[1] |
| 0x1410199D0 | SCriticalPart::[0] vtable 槽 SCriticalPart::[0]（func_names RTTI 名） |
| 0x140E8EC10 | CUnassignRailwayGunFromOrdersGroup::Clone func_names 名 CUnassignRailwayGunFromOrdersGroup::Clone |
| 0x1413F3420 | （无名） 体设 CCountryLeaderTemplate::vftable（RTTI 名） |
| 0x140E8E9C0 | CAssignRailwayGunToOrdersGroup::Clone func_names 名 CAssignRailwayGunToOrdersGroup::Clone |
| 0x141C8B900 | （无名） 体设 CDiplomacyStandardController::vftable（RTTI 名） |
| 0x140DB37E0 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x1402CD130 | CNationalFocusProgress::[0] vtable 槽 CNationalFocusProgress::[0]（func_names RTTI 名） |
| 0x141D13CF0 | CUnitLeaderTraitTree::[24] vtable 槽 CUnitLeaderTraitTree::[24]（func_names RTTI 名） |
| 0x140CD8490 | （无名） 体设 SCombatSideData::vftable（RTTI 名） |
| 0x14234D9B0 | SEntityLocatorReader::[8] vtable 槽 SEntityLocatorReader::[8]（func_names RTTI 名） |
| 0x1404B7A50 | CHasFactionMilitaryUnlocked::GetDesc func_names 名 CHasFactionMilitaryUnlocked::GetDesc |
| 0x140AC25C0 | CStrategicResourceDatabase::[2] vtable 槽 CStrategicResourceDatabase::[2]（func_names RTTI 名） |
| 0x14100ADD0 | CAbility::[8] vtable 槽 CAbility::[8]（func_names RTTI 名） |
| 0x1415791E0 | COperativeRecruitment::[0] vtable 槽 COperativeRecruitment::[0]（func_names RTTI 名） |
| 0x1414DB7E0 | （无名） 体设 SBookmarkPlaythroughData::vftable（RTTI 名） |
| 0x14194CB70 | CAIBaseGeneral::[21] vtable 槽 CAIBaseGeneral::[21]（func_names RTTI 名） |
| 0x1402AD950 | CTest::[0] vtable 槽 CTest::[0]（func_names RTTI 名） |
| 0x141BE4800 | CConfirmResearchTechnology::Reload func_names 名 CConfirmResearchTechnology::Reload |
| 0x140C0B540 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x14044CB90 | CCanFireAdvisor::Parse func_names 名 CCanFireAdvisor::Parse |
| 0x1410542A0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14113A050 | COfferMilitaryAccessAction::[57] vtable 槽 COfferMilitaryAccessAction::[57]（func_names RTTI 名） |
| 0x140ABC200 | （无名） 体设 CStateTemplate::vftable（RTTI 名） |
| 0x14032CB00 | （无名） 体设 CCharacterPortraits::vftable（RTTI 名） |
| 0x140A07CC0 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x14183D110 | CAssignArmyToArmyGroupFront::Clone func_names 名 CAssignArmyToArmyGroupFront::Clone |
| 0x1410041A0 | （无名） 体设 CDominanceValues::vftable（RTTI 名） |
| 0x141135700 | CRequestForeignManpowerAction::CanExecute func_names 名 CRequestForeignManpowerAction::CanExecute |
| 0x1417B0510 | CInGameClock::[0] vtable 槽 CInGameClock::[0]（func_names RTTI 名） |
| 0x141139E90 | CMilitaryAccessAction::[57] vtable 槽 CMilitaryAccessAction::[57]（func_names RTTI 名） |
| 0x141CF74A0 | （无名） 体设 CDivisionNamesContainer::vftable（RTTI 名） |
| 0x141DEBAB0 | CConfirmSaveGame::Reload func_names 名 CConfirmSaveGame::Reload |
| 0x140DB6890 | CUnlockIndustrialOrganisationTrait::Clone func_names 名 CUnlockIndustrialOrganisationTrait::Clone |
| 0x142300700 | CSmoothListbox::[77] vtable 槽 CSmoothListbox::[77]（func_names RTTI 名） |
| 0x141B6BDD0 | CSupplyNudger::Reload func_names 名 CSupplyNudger::Reload |
| 0x1403D08F0 | CCanSelectTrait::Evaluate func_names 名 CCanSelectTrait::Evaluate |
| 0x14151B760 | CTakeNavyPeaceAction::Clone func_names 名 CTakeNavyPeaceAction::Clone |
| 0x14033D360 | CEffectEntry<CCreateShipEffect>::[1] func_names 名 CEffectEntry<CCreateShipEffect>::[1] |
| 0x140A00C20 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x140E55570 | CPowerBalanceSideInfo::[0] vtable 槽 CPowerBalanceSideInfo::[0]（func_names RTTI 名） |
| 0x142236B50 | SAnimationMapData::[0] vtable 槽 SAnimationMapData::[0]（func_names RTTI 名） |
| 0x14033E7F0 | CEffectEntry<CGiveResourceRightsEffect>::[1] func_names 名 CEffectEntry<CGiveResourceRightsEffect>::[1] |
| 0x14068E5D0 | （无名） 体设 SCareerProfileStatistics::vftable（RTTI 名） |
| 0x141168B20 | （无名） 体设 SDecisionData::vftable（RTTI 名） |
| 0x140E9D8B0 | （无名） 体设 CTaskForceComposition::vftable（RTTI 名） |
| 0x142381000 | StackWalker::[1] vtable 槽 StackWalker::[1]（func_names RTTI 名） |
| 0x1407216F0 | （无名） 体设 CCustomMapMode::vftable（RTTI 名） |
| 0x14111C430 | CRequestForeignManpowerAction::GetAiAcceptance func_names 名 CRequestForeignManpowerAction::GetAiAcceptance |
| 0x1424023D0 | CSteamStoreContext::[18] vtable 槽 CSteamStoreContext::[18]（func_names RTTI 名） |
| 0x1410F92C0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14234BF50 | （无名） 体设 SEntityLocatorReader::vftable（RTTI 名） |
| 0x140AC1E00 | CStrategicResourceDatabase::[1] vtable 槽 CStrategicResourceDatabase::[1]（func_names RTTI 名） |
| 0x14208F580 | （无名） 体设 SForceReader::vftable（RTTI 名） |
| 0x140CF38C0 | CMilAccessAreaCostCallback::[0] vtable 槽 CMilAccessAreaCostCallback::[0]（func_names RTTI 名） |
| 0x140DE6FD0 | CSetGameUniqueId::Clone func_names 名 CSetGameUniqueId::Clone |
| 0x141288090 | CPdxPostEffectVolumeManager::[2] vtable 槽 CPdxPostEffectVolumeManager::[2]（func_names RTTI 名） |
| 0x14049B400 | CEffectEntry<CAddEquipmentToStockpileEffect>::[1] func_names 名 CEffectEntry<CAddEquipmentToStockpileEffect>::[1] |
| 0x140D7FBE0 | （无名） 体设 STemporaryCostReduction::vftable（RTTI 名） |
| 0x141B3E0C0 | CAmbientObjectNudger::Reload func_names 名 CAmbientObjectNudger::Reload |
| 0x1403E5EC0 | CTriggerEntry<CHasIdeaTrigger>::[1] func_names 名 CTriggerEntry<CHasIdeaTrigger>::[1] |
| 0x141141170 | COfferMilitaryAccessAction::[26] vtable 槽 COfferMilitaryAccessAction::[26]（func_names RTTI 名） |
| 0x14163C6E0 | CSetGamePlayOptions::Clone func_names 名 CSetGamePlayOptions::Clone |
| 0x142363550 | CDummyServer::[13] vtable 槽 CDummyServer::[13]（func_names RTTI 名） |
| 0x141981340 | CAirBaseAccessRelation::[22] vtable 槽 CAirBaseAccessRelation::[22]（func_names RTTI 名） |
| 0x141ED6790 | CNavalLeaderModuleUi::[1] vtable 槽 CNavalLeaderModuleUi::[1]（func_names RTTI 名） |
| 0x141332530 | （无名） 体设 SChannelInfo::vftable（RTTI 名） |
| 0x14033D020 | CEffectEntry<CCreateEntityEffect>::[1] func_names 名 CEffectEntry<CCreateEntityEffect>::[1] |
| 0x14151BB90 | CStatePeaceAction::IsTargetingAnyState func_names 名 CStatePeaceAction::IsTargetingAnyState |
| 0x14134BBA0 | CAddToOrRemoveShipFromNavalRepairQueue::Clone func_names 名 CAddToOrRemoveShipFromNavalRepairQueue::Clone |
| 0x140A54F10 | （无名） 体设 CInsigniaGraphicsDatabase::vftable（RTTI 名） |
| 0x1422AC630 | CChoice<CSmoothListboxItem>::[8] func_names 名 CChoice<CSmoothListboxItem>::[8] |
| 0x140A806F0 | （无名） 体设 COpinionModifier::vftable（RTTI 名） |
| 0x140341A70 | CEffectEntry<CSetPoliticsEffect>::[1] func_names 名 CEffectEntry<CSetPoliticsEffect>::[1] |
| 0x141C22900 | CScientistRoster::OnRecruitScientist func_names 名 CScientistRoster::OnRecruitScientist |
| 0x1423E8980 | CSteamNetContext::[21] vtable 槽 CSteamNetContext::[21]（func_names RTTI 名） |
| 0x140F6EDE0 | （无名） 体设 CNavalProductionLine::vftable（RTTI 名） |
| 0x14134DB60 | CSwitchNavalRepairDockyard::Clone func_names 名 CSwitchNavalRepairDockyard::Clone |
| 0x14049FA90 | CSetEquipmentVersionNumber::ResolveReferences func_names 名 CSetEquipmentVersionNumber::ResolveReferences |
| 0x140E239B0 | CStrategicRegion::[2] vtable 槽 CStrategicRegion::[2]（func_names RTTI 名） |
| 0x1413BBFE0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14134CF30 | CReorderNavalRepairQueue::Clone func_names 名 CReorderNavalRepairQueue::Clone |
| 0x1422D5470 | （无名） 体设 CTextBlock::vftable（RTTI 名） |
| 0x140A6EE70 | USCompositionReader::?$ReadCustomUniformSimpleStatement::SCusto鈥�::[2] func_names 名 USCompositionReader::?$ReadCustomUniformSimpleStatement::SCusto鈥�::[2] |
| 0x141B3D500 | CAmbientObjectNudger::Update func_names 名 CAmbientObjectNudger::Update |
| 0x140467CF0 | CTriggerEntry<CAnyStateInTrigger>::[1] func_names 名 CTriggerEntry<CAnyStateInTrigger>::[1] |
| 0x1413FA000 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422AD050 | CChoice<CSmoothListboxItem>::[14] func_names 名 CChoice<CSmoothListboxItem>::[14] |
| 0x142502BC0 | （无名） 体设 CException::vftable（RTTI 名） |
| 0x1402F9CA0 | CEffectEntry<NIndustrialOrganisation::CEveryIndustrialOrgEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CEveryIndustrialOrgEffect>::[1] |
| 0x141A001E0 | （无名） 体设 SOptionalEquipmentAssets::vftable（RTTI 名） |
| 0x1423003D0 | CSmoothListbox::[5] vtable 槽 CSmoothListbox::[5]（func_names RTTI 名） |
| 0x14033B530 | CEffectEntry<CAddAceEffect>::[1] func_names 名 CEffectEntry<CAddAceEffect>::[1] |
| 0x140342420 | CEffectEntry<CSwapIdeasEffect>::[1] func_names 名 CEffectEntry<CSwapIdeasEffect>::[1] |
| 0x1410FA2C0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141640D90 | CGameBitmapFont::[0] vtable 槽 CGameBitmapFont::[0]（func_names RTTI 名） |
| 0x140A86B80 | CPortraitDatabase::[1] vtable 槽 CPortraitDatabase::[1]（func_names RTTI 名） |
| 0x1422D9C90 | CWrapWorldShadowMap::[0] vtable 槽 CWrapWorldShadowMap::[0]（func_names RTTI 名） |
| 0x1410FC0A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1410FA6A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422E09A0 | CChunkReceived::Clone func_names 名 CChunkReceived::Clone |
| 0x14033F500 | CEffectEntry<CRandomControlledStateEffect>::[1] func_names 名 CEffectEntry<CRandomControlledStateEffect>::[1] |
| 0x140620E10 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1422DF6E0 | PdxStackWalker::[5] vtable 槽 PdxStackWalker::[5]（func_names RTTI 名） |
| 0x14230D450 | （无名） 体设 SAnimationLookup::vftable（RTTI 名） |
| 0x140A27800 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1410FB5C0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1415DE2D0 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x140442680 | CIsArmyChief::Evaluate func_names 名 CIsArmyChief::Evaluate |
| 0x142250A00 | CSession::[6] vtable 槽 CSession::[6]（func_names RTTI 名） |
| 0x140442590 | CIsAirChief::Evaluate func_names 名 CIsAirChief::Evaluate |
| 0x14049F460 | CAddEquipmentBonus::ResolveReferences func_names 名 CAddEquipmentBonus::ResolveReferences |
| 0x140E92750 | CProvinceRailwayInfo::[0] vtable 槽 CProvinceRailwayInfo::[0]（func_names RTTI 名） |
| 0x141020EB0 | CConvoys::CalcRequiredConvoysForLendLeaseEquipment func_names 名 CConvoys::CalcRequiredConvoysForLendLeaseEquipment |
| 0x14196B950 | CLendLeaseExchange::[12] vtable 槽 CLendLeaseExchange::[12]（func_names RTTI 名） |
| 0x1422A9D90 | CSimpleListbox<CStandardlistboxItem>::[4] func_names 名 CSimpleListbox<CStandardlistboxItem>::[4] |
| 0x1403E7C00 | CTriggerEntry<CIsLicensingToTrigger>::[1] func_names 名 CTriggerEntry<CIsLicensingToTrigger>::[1] |
| 0x1413A32D0 | CTriggerEntry<CCustomOverrideTooltipTrigger>::[1] func_names 名 CTriggerEntry<CCustomOverrideTooltipTrigger>::[1] |
| 0x1422AB100 | CSimpleListbox<CStandardlistboxItem>::[5] func_names 名 CSimpleListbox<CStandardlistboxItem>::[5] |
| 0x141135630 | CReduceAutonomyAction::CanExecute func_names 名 CReduceAutonomyAction::CanExecute |
| 0x141696F80 | （无名） 体设 CTemplateChanger::vftable（RTTI 名） |
| 0x1412D5090 | CNudgeIdler::CollectReloadNames func_names 名 CNudgeIdler::CollectReloadNames |
| 0x14150D790 | CArmyUpgradesStatus::[1] vtable 槽 CArmyUpgradesStatus::[1]（func_names RTTI 名） |
| 0x1422E5440 | （无名） 体设 CChatMessage::vftable（RTTI 名） |
| 0x14183DC30 | COrderDeleteChildFront::Clone func_names 名 COrderDeleteChildFront::Clone |
| 0x1406C9340 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140AD7690 | （无名） 体设 CTimedWargoalActivity::vftable（RTTI 名） |
| 0x140DB2CC0 | （无名） 体设 SHistoryWithEquipment::vftable（RTTI 名） |
| 0x141197C70 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1409BFE10 | （无名） 体设 CNameGroupMember::vftable（RTTI 名） |
| 0x140C0C160 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x1402EE0C0 | CSupplyUnits::GetDesc func_names 名 CSupplyUnits::GetDesc |
| 0x1410FADB0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1422E0A40 | CSendChunk::Clone func_names 名 CSendChunk::Clone |
| 0x1413E1C00 | CCombatant::[27] vtable 槽 CCombatant::[27]（func_names RTTI 名） |
| 0x1410FACE0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x142396730 | （无名） 体设 CCustomStackWalker::vftable（RTTI 名） |
| 0x14186DB00 | CChatBuffer::[2] vtable 槽 CChatBuffer::[2]（func_names RTTI 名） |
| 0x142231380 | CMouse::[2] vtable 槽 CMouse::[2]（func_names RTTI 名） |
| 0x1422501E0 | CSession::[2] vtable 槽 CSession::[2]（func_names RTTI 名） |
| 0x1422AAA70 | CChoiceObservable<CStandardlistboxItem>::[2] func_names 名 CChoiceObservable<CStandardlistboxItem>::[2] |
| 0x142300100 | CChoiceObservable<CSmoothListboxItem>::[2] func_names 名 CChoiceObservable<CSmoothListboxItem>::[2] |
| 0x14043F270 | CTriggerEntry<NCareerProfile::CHasPlayerFlag>::[1] func_names 名 CTriggerEntry<NCareerProfile::CHasPlayerFlag>::[1] |
| 0x14047C3D0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140443D50 | CIsTheorist::Evaluate func_names 名 CIsTheorist::Evaluate |
| 0x14196F780 | （无名） 体设 SCachedInfo::vftable（RTTI 名） |
| 0x140673DA0 | （无名） 体设 CAutonomousStateDatabase::vftable（RTTI 名） |
| 0x140D063A0 | CCountryIntel::[4] vtable 槽 CCountryIntel::[4]（func_names RTTI 名） |
| 0x1412E8B00 | CAIForeignMinister::[0] vtable 槽 CAIForeignMinister::[0]（func_names RTTI 名） |
| 0x141F68BF0 | CTraitAssignmentConfirmation::Update func_names 名 CTraitAssignmentConfirmation::Update |
| 0x1424E1760 | CArchiveFile::[7] vtable 槽 CArchiveFile::[7]（func_names RTTI 名） |
| 0x1404A88F0 | CTriggerEntry<CAllCountryOfTrigger>::[1] func_names 名 CTriggerEntry<CAllCountryOfTrigger>::[1] |
| 0x140E5BE60 | （无名） 体设 CNamedEquipmentBonus::vftable（RTTI 名） |
| 0x1413E2AE0 | CCombatant::[31] vtable 槽 CCombatant::[31]（func_names RTTI 名） |
| 0x1406AC170 | （无名） 体设 CTierColors::vftable（RTTI 名） |
| 0x1423202D0 | （无名） 体设 CLineChartType::vftable（RTTI 名） |
| 0x140A55220 | CInsigniaGraphicsDatabase::[1] vtable 槽 CInsigniaGraphicsDatabase::[1]（func_names RTTI 名） |
| 0x141871D00 | CPlayerLobby::Reload func_names 名 CPlayerLobby::Reload |
| 0x141453960 | （无名） 体设 CConferenceBeneficiaryWithStackableParticipant::vftable（RTTI 名） |
| 0x14033E150 | CEffectEntry<CForEachEffect>::[1] func_names 名 CEffectEntry<CForEachEffect>::[1] |
| 0x140147750 | （无名） 体设 CFactionUpgrade::vftable（RTTI 名） |
| 0x1403E2F10 | CTriggerEntry<CAllCountryWithOriginalTagTrigger>::[1] func_names 名 CTriggerEntry<CAllCountryWithOriginalTagTrigger>::[1] |
| 0x140F03490 | CWorldThreat::[0] vtable 槽 CWorldThreat::[0]（func_names RTTI 名） |
| 0x14150C920 | CReinforcementRequest::[4] vtable 槽 CReinforcementRequest::[4]（func_names RTTI 名） |
| 0x14195F780 | CRaidTargetManager::FixupLists func_names 名 CRaidTargetManager::FixupLists |
| 0x1418689E0 | （无名） 体设 CSystemMessage::vftable（RTTI 名） |
| 0x141F62030 | （无名） 体设 CNicheSelectionOptionSelections::vftable（RTTI 名） |
| 0x141B791C0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140BD15E0 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x141A25840 | CActivateActiveDecryptionBonuses::Clone func_names 名 CActivateActiveDecryptionBonuses::Clone |
| 0x14114AA20 | CAddProductionLineUnorderedName::Clone func_names 名 CAddProductionLineUnorderedName::Clone |
| 0x14134D600 | CSetMaxAllowedRepairDockyards::Clone func_names 名 CSetMaxAllowedRepairDockyards::Clone |
| 0x14183D080 | CAssignAdmiralToNavyHeadquarter::Clone func_names 名 CAssignAdmiralToNavyHeadquarter::Clone |
| 0x14114A990 | CAddProductionLineOrderedName::Clone func_names 名 CAddProductionLineOrderedName::Clone |
| 0x1424BA130 | CTweakableBool::[2] vtable 槽 CTweakableBool::[2]（func_names RTTI 名） |
| 0x140AB92D0 | CScriptedWindowDatabase::[1] vtable 槽 CScriptedWindowDatabase::[1]（func_names RTTI 名） |
| 0x14033F6A0 | CEffectEntry<CRandomCountryWithOriginalTag>::[1] func_names 名 CEffectEntry<CRandomCountryWithOriginalTag>::[1] |
| 0x14047C2E0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x141363590 | CSetArmyToConsolidateForUnit::Clone func_names 名 CSetArmyToConsolidateForUnit::Clone |
| 0x140F80EB0 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x14134D2B0 | CSetCarrierDefensiveStance::Clone func_names 名 CSetCarrierDefensiveStance::Clone |
| 0x1415117A0 | （无名） 体设 CExileDivisionsTransfer::vftable（RTTI 名） |
| 0x14114C500 | CRemoveProductionLineName::Clone func_names 名 CRemoveProductionLineName::Clone |
| 0x1406B0EA0 | CCharacterAdvisorGenerationDatabase::[1] vtable 槽 CCharacterAdvisorGenerationDatabase::[1]（func_names RTTI 名） |
| 0x140FCDD10 | CIdeaCategory::[0] vtable 槽 CIdeaCategory::[0]（func_names RTTI 名） |
| 0x1415194F0 | CLiberateCountryAction::IsOverlappingAction func_names 名 CLiberateCountryAction::IsOverlappingAction |
| 0x14163C510 | CSetCoopHotJoinOptions::Clone func_names 名 CSetCoopHotJoinOptions::Clone |
| 0x1411400E0 | CGiveStateControlAction::[32] vtable 槽 CGiveStateControlAction::[32]（func_names RTTI 名） |
| 0x140E87010 | CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[8] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[8] |
| 0x140E870A0 | CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[10] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BJ::NRaids::CRaidTarget>::[10] |
| 0x1419815E0 | COfferAirBaseAccessRelation::[21] vtable 槽 COfferAirBaseAccessRelation::[21]（func_names RTTI 名） |
| 0x14163C780 | CSetGameRuleOption::Clone func_names 名 CSetGameRuleOption::Clone |
| 0x14163C810 | CSetMPDebugSettings::Clone func_names 名 CSetMPDebugSettings::Clone |
| 0x1423C2A00 | CSteamBrowserInstance::[9] vtable 槽 CSteamBrowserInstance::[9]（func_names RTTI 名） |
| 0x14253E764 | （无名） 体设 Node::vftable（RTTI 名） |
| 0x1403D2770 | CHasAnnexWarGoal::Evaluate func_names 名 CHasAnnexWarGoal::Evaluate |
| 0x1412661F0 | CMapArrowDefinitionInstance::[0] vtable 槽 CMapArrowDefinitionInstance::[0]（func_names RTTI 名） |
| 0x141120B10 | CRequestLicensedProductionAction::[59] vtable 槽 CRequestLicensedProductionAction::[59]（func_names RTTI 名） |
| 0x140A34BF0 | （无名） 体设 CGameRuleOption::vftable（RTTI 名） |
| 0x1403422D0 | CEffectEntry<CStartPeaceConferenceEffect>::[1] func_names 名 CEffectEntry<CStartPeaceConferenceEffect>::[1] |
| 0x140CDF780 | （无名） 体设 SModifierHours::vftable（RTTI 名） |
| 0x141453F20 | （无名） 体设 CConferenceBeneficiaryWithStackableParticipant::vftable（RTTI 名） |
| 0x140A95980 | SUniformReader<鈥�>::[0] func_names 名 SUniformReader<鈥�>::[0] |
| 0x140A27E30 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1403E5C20 | CTriggerEntry<CHasEquipmentTrigger>::[1] func_names 名 CTriggerEntry<CHasEquipmentTrigger>::[1] |
| 0x14051D520 | CTriggerEntry<CAllCollectionElementsTrigger>::[1] func_names 名 CTriggerEntry<CAllCollectionElementsTrigger>::[1] |
| 0x1402231B0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140FFE140 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14163C8A0 | CSetReadyStatus::Clone func_names 名 CSetReadyStatus::Clone |
| 0x1402E4EE0 | CEffectEntry<CAddTraitEffect>::[1] func_names 名 CEffectEntry<CAddTraitEffect>::[1] |
| 0x14033FBD0 | CEffectEntry<CRandomScopeInArray>::[1] func_names 名 CEffectEntry<CRandomScopeInArray>::[1] |
| 0x140D45030 | （无名） 体设 SRedistribution::vftable（RTTI 名） |
| 0x140FCDC10 | （无名） 体设 CIdeaGroupType::vftable（RTTI 名） |
| 0x142229470 | CGraphicsSettings::[8] vtable 槽 CGraphicsSettings::[8]（func_names RTTI 名） |
| 0x14067CC50 | CBookmarkDatabase::[1] vtable 槽 CBookmarkDatabase::[1]（func_names RTTI 名） |
| 0x1409FB4F0 | CEquipmentDatabase::CheckEquipmentTypeSanity? func_names 名 CEquipmentDatabase::CheckEquipmentTypeSanity? |
| 0x140A83330 | CPeaceActionScriptedAiDesire::[0] vtable 槽 CPeaceActionScriptedAiDesire::[0]（func_names RTTI 名） |
| 0x14032D560 | （无名） 体设 SUnitOfficerData::vftable（RTTI 名） |
| 0x140617820 | （无名） 体设 CAcesDatabase::vftable（RTTI 名） |
| 0x1406B09F0 | （无名） 体设 CCharacterAdvisorGenerationDatabase::vftable（RTTI 名） |
| 0x1419D7D80 | CDebugMapModeConfig::CCallbacksWrapper::[3] vtable 槽 CDebugMapModeConfig::CCallbacksWrapper::[3]（func_names RTTI 名） |
| 0x1424009D0 | PdxSocialPermissions::ChatBooleanPermission::[0] vtable 槽 PdxSocialPermissions::ChatBooleanPermission::[0]（func_names RTTI 名） |
| 0x1424C88B0 | （无名） 体设 CLogger::vftable（RTTI 名） |
| 0x140342A10 | CEffectEntry<CWhileEffect>::[1] func_names 名 CEffectEntry<CWhileEffect>::[1] |
| 0x1422A91A0 | （无名） 体设 CStandardlistbox::vftable（RTTI 名） |
| 0x141B6EB30 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1416512B0 | （无名） 体设 SGroup::vftable（RTTI 名） |
| 0x14183EF80 | CRemoveAdmiralFromNavyHeadquarter::Clone func_names 名 CRemoveAdmiralFromNavyHeadquarter::Clone |
| 0x1404A6C40 | CStateAndCountryEffect<CAddContestedOwner>::[7] func_names 名 CStateAndCountryEffect<CAddContestedOwner>::[7] |
| 0x140BBD6F0 | （无名） 体设 SIdCounter::vftable（RTTI 名） |
| 0x141AED1A0 | CDebugMapModeConfig::Z::YAX01::??23::?BI::V<鈥�>::[1] func_names 名 CDebugMapModeConfig::Z::YAX01::??23::?BI::V<鈥�>::[1] |
| 0x140A6C620 | （无名） 体设 SScriptedKey::vftable（RTTI 名） |
| 0x1406230D0 | （无名） 体设 CAgencyUpgradeBranch::vftable（RTTI 名） |
| 0x140F6ED40 | （无名） 体设 CNavalProductionLine::vftable（RTTI 名） |
| 0x140482D60 | CVariableEffectBuilder<CSetToRandomValue<CVariableResolver>>::[4] func_names 名 CVariableEffectBuilder<CSetToRandomValue<CVariableResolver>>::[4] |
| 0x1411CF870 | （无名） 体设 CCountryIntelNetwork::vftable（RTTI 名） |
| 0x1402F42D0 | CEffectEntry<CPartyLeaderTarget>::[1] func_names 名 CEffectEntry<CPartyLeaderTarget>::[1] |
| 0x140D23E90 | CBoostPartyPopularityRelation::GetDesc func_names 名 CBoostPartyPopularityRelation::GetDesc |
| 0x14183E610 | COrderRemoveRootCommands::Clone func_names 名 COrderRemoveRootCommands::Clone |
| 0x141D0AEC0 | CConfirmDeleteUnits::[0] vtable 槽 CConfirmDeleteUnits::[0]（func_names RTTI 名） |
| 0x140CD8140 | （无名） 体设 SCombatData::vftable（RTTI 名） |
| 0x141454340 | CConferenceLiberatedParticipant::[1] vtable 槽 CConferenceLiberatedParticipant::[1]（func_names RTTI 名） |
| 0x140483B70 | CEffectEntry<CSetPowerBalanceEffect>::[1] func_names 名 CEffectEntry<CSetPowerBalanceEffect>::[1] |
| 0x1416D4D30 | CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[2] func_names 名 CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[2] |
| 0x1416FB120 | CTacticsListView<CSelectCountryPreferredTacticsEntry>::[2] func_names 名 CTacticsListView<CSelectCountryPreferredTacticsEntry>::[2] |
| 0x14153DA70 | CFriendsHandlerSteam::[17] vtable 槽 CFriendsHandlerSteam::[17]（func_names RTTI 名） |
| 0x1401C9500 | CCurrentGameState::[0] vtable 槽 CCurrentGameState::[0]（func_names RTTI 名） |
| 0x140CDD430 | （无名） 体设 SDamageDone::vftable（RTTI 名） |
| 0x141509E50 | CReinforcementRequest::[0] vtable 槽 CReinforcementRequest::[0]（func_names RTTI 名） |
| 0x1404571B0 | CTriggerEntry<NIndustrialOrganisation::CAllIndustrialOrgTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CAllIndustrialOrgTrigger>::[1] |
| 0x1404ABC20 | CSetFactionMemberUpgradeMin::Execute func_names 名 CSetFactionMemberUpgradeMin::Execute |
| 0x14061C640 | （无名） 体设 CBaseAchievement::vftable（RTTI 名） |
| 0x140B3D760 | CFrontEndIdler::[3] vtable 槽 CFrontEndIdler::[3]（func_names RTTI 名） |
| 0x140D889E0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1413931F0 | CEffectEntry<CRandomListEffect>::[1] func_names 名 CEffectEntry<CRandomListEffect>::[1] |
| 0x1402D7290 | （无名） 体设 CPositionOverride::vftable（RTTI 名） |
| 0x14033AAE0 | CEffectEntry<CFindHighestLowestInArrayEffect<$00>>::[1] func_names 名 CEffectEntry<CFindHighestLowestInArrayEffect<$00>>::[1] |
| 0x14151F4A0 | CTakeNavyPeaceAction::IsSameTarget func_names 名 CTakeNavyPeaceAction::IsSameTarget |
| 0x14163C650 | CSetDifficulty::Clone func_names 名 CSetDifficulty::Clone |
| 0x1410B27E0 | （无名） 体设 CEquipmentUpgradesInstance::vftable（RTTI 名） |
| 0x14047C480 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1403A4BC0 | CReduceFocusCost::[5] vtable 槽 CReduceFocusCost::[5]（func_names RTTI 名） |
| 0x140B644A0 | CSlowInterfaceIndicator::[0] vtable 槽 CSlowInterfaceIndicator::[0]（func_names RTTI 名） |
| 0x141DF8DF0 | （无名） 体设 CStandardMusicPlaylistController::vftable（RTTI 名） |
| 0x1424E89A0 | （无名） 体设 Node_capture::vftable（RTTI 名） |
| 0x1404B3B90 | CFactionUpgradeLevel::Evaluate func_names 名 CFactionUpgradeLevel::Evaluate |
| 0x140D7F980 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x140F71070 | CRocketProductionLine::[0] vtable 槽 CRocketProductionLine::[0]（func_names RTTI 名） |
| 0x1410FB020 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141EE1B20 | CAiFrontImportanceMapModeConfig::[0] vtable 槽 CAiFrontImportanceMapModeConfig::[0]（func_names RTTI 名） |
| 0x1424B8B80 | （无名） 体设 CTweakable::vftable（RTTI 名） |
| 0x14043EF00 | CTriggerEntry<NCareerProfile::CCheckMedal>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckMedal>::[1] |
| 0x14049D370 | CAddEquipmentBonus::GetDesc func_names 名 CAddEquipmentBonus::GetDesc |
| 0x140F71B90 | CShipRefitProductionLine::[30] vtable 槽 CShipRefitProductionLine::[30]（func_names RTTI 名） |
| 0x1424B8A50 | （无名） 体设 CTweakable::vftable（RTTI 名） |
| 0x1404689B0 | CTriggerEntry<CStateFlagTrigger>::[1] func_names 名 CTriggerEntry<CStateFlagTrigger>::[1] |
| 0x1415195A0 | CTakeStateAction::IsOverlappingAction func_names 名 CTakeStateAction::IsOverlappingAction |
| 0x14163C480 | CSetAchievementsOK::Clone func_names 名 CSetAchievementsOK::Clone |
| 0x1422AB660 | CChoice<CSmoothListboxItem>::[6] func_names 名 CChoice<CSmoothListboxItem>::[6] |
| 0x1402E5400 | CEffectEntry<CReplaceUnitLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CReplaceUnitLeaderTraitEffect>::[1] |
| 0x140639120 | （无名） 体设 CRuleDefinition::vftable（RTTI 名） |
| 0x14163C5A0 | CSetCustomDifficultyMultiplier::Clone func_names 名 CSetCustomDifficultyMultiplier::Clone |
| 0x1405351E0 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x141519670 | CTakeNavyPeaceAction::GetBaseValue func_names 名 CTakeNavyPeaceAction::GetBaseValue |
| 0x140E88B90 | CRailwayGun::IsValid func_names 名 CRailwayGun::IsValid |
| 0x14065FA80 | （无名） 体设 CAIStrategyReader::vftable（RTTI 名） |
| 0x140DE67C0 | CAutosave::Clone func_names 名 CAutosave::Clone |
| 0x141C37410 | CEquipmentOverview::Reload func_names 名 CEquipmentOverview::Reload |
| 0x1424EB650 | （无名） 体设 Node_base::vftable（RTTI 名） |
| 0x141C8E4E0 | CDiplomacyLendLeaseActionController::[4] vtable 槽 CDiplomacyLendLeaseActionController::[4]（func_names RTTI 名） |
| 0x14031F230 | CEffectEntry<CSetTechnologyEffect>::[1] func_names 名 CEffectEntry<CSetTechnologyEffect>::[1] |
| 0x140341B30 | CEffectEntry<CSetPopularitiesEffect>::[1] func_names 名 CEffectEntry<CSetPopularitiesEffect>::[1] |
| 0x1402E4D50 | CEffectEntry<CAddRandomTraitEffect>::[1] func_names 名 CEffectEntry<CAddRandomTraitEffect>::[1] |
| 0x1404575A0 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x141D0CA50 | CConfirmDeleteUnits::[0] vtable 槽 CConfirmDeleteUnits::[0]（func_names RTTI 名） |
| 0x14033F330 | CEffectEntry<CPrintVariablesEffect>::[1] func_names 名 CEffectEntry<CPrintVariablesEffect>::[1] |
| 0x1403B11E0 | CCancelBorderWar::ParseToken func_names 名 CCancelBorderWar::ParseToken |
| 0x140DE6AB0 | CPauseGame::Clone func_names 名 CPauseGame::Clone |
| 0x140A50C50 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x140A851F0 | CPeaceActionModifier::[7] vtable 槽 CPeaceActionModifier::[7]（func_names RTTI 名） |
| 0x141020E20 | CConvoys::CalcRequiredConvoysForInternationalMarketEquipment? func_names 名 CConvoys::CalcRequiredConvoysForInternationalMarketEquipment? |
| 0x14114A8E0 | CAddProductionLineName::Clone func_names 名 CAddProductionLineName::Clone |
| 0x141333250 | CChat::CChannelItem::[0] vtable 槽 CChat::CChannelItem::[0]（func_names RTTI 名） |
| 0x14033EC10 | CEffectEntry<CLegacyCreateCorpsCommanderEffect>::[1] func_names 名 CEffectEntry<CLegacyCreateCorpsCommanderEffect>::[1] |
| 0x141F52360 | CResetCustomDifficultyMultipliers::Clone func_names 名 CResetCustomDifficultyMultipliers::Clone |
| 0x14186F860 | CPlayerLobby::BanPlayer func_names 名 CPlayerLobby::BanPlayer |
| 0x141DD4DD0 | CEquipmentDesignerModelSelector::[0] vtable 槽 CEquipmentDesignerModelSelector::[0]（func_names RTTI 名） |
| 0x141DD4F70 | CEquipmentDesignerModelSelector::[0] vtable 槽 CEquipmentDesignerModelSelector::[0]（func_names RTTI 名） |
| 0x14033EDA0 | CEffectEntry<CLegacyCreateFieldMarshalEffect>::[1] func_names 名 CEffectEntry<CLegacyCreateFieldMarshalEffect>::[1] |
| 0x140482CB0 | CVariableEffectBuilder<鈥�>::[4] func_names 名 CVariableEffectBuilder<鈥�>::[4] |
| 0x1404A6480 | CStateAndCountryEffect<CAddContestedOwner>::[6] func_names 名 CStateAndCountryEffect<CAddContestedOwner>::[6] |
| 0x1404A7320 | CHasContestedOwner::[4] vtable 槽 CHasContestedOwner::[4]（func_names RTTI 名） |
| 0x1404AA440 | CEffectEntry<CCreateFactionFromTemplateEffect>::[1] func_names 名 CEffectEntry<CCreateFactionFromTemplateEffect>::[1] |
| 0x140C11C10 | CArmyLeader::[19] vtable 槽 CArmyLeader::[19]（func_names RTTI 名） |
| 0x1424EE290 | CRemoteFile::[1] vtable 槽 CRemoteFile::[1]（func_names RTTI 名） |
| 0x1404A2370 | CTriggerEntry<NProject::CHasProjectFlagTrigger>::[1] func_names 名 CTriggerEntry<NProject::CHasProjectFlagTrigger>::[1] |
| 0x1422CBDB0 | CDebugLineHelper::[0] vtable 槽 CDebugLineHelper::[0]（func_names RTTI 名） |
| 0x1416001A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140475FF0 | CTriggerEntry<CIsFightingInWeatherTrigger>::[1] func_names 名 CTriggerEntry<CIsFightingInWeatherTrigger>::[1] |
| 0x1402CD060 | CNationalFocusDependency::[0] vtable 槽 CNationalFocusDependency::[0]（func_names RTTI 名） |
| 0x140342A90 | CEffectEntry<CWhitePeaceEffect>::[1] func_names 名 CEffectEntry<CWhitePeaceEffect>::[1] |
| 0x14033BBF0 | CEffectEntry<CAddFieldMarshallRoleEffect>::[1] func_names 名 CEffectEntry<CAddFieldMarshallRoleEffect>::[1] |
| 0x1402E4010 | CSetCountryLeaderNamePortraitOrDescription<$00>::[0] func_names 名 CSetCountryLeaderNamePortraitOrDescription<$00>::[0] |
| 0x140BEADF0 | CPdxMonotonicBufferAllocator<HH>::[1] func_names 名 CPdxMonotonicBufferAllocator<HH>::[1] |
| 0x140E9F950 | CPdxMonotonicBufferAllocator<鈥�>::[1] func_names 名 CPdxMonotonicBufferAllocator<鈥�>::[1] |
| 0x141F523E0 | CResetGameRules::Clone func_names 名 CResetGameRules::Clone |
| 0x14014E870 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140529210 | CEffectEntry<NDoctrines::CAddDailyMasteryEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CAddDailyMasteryEffect>::[1] |
| 0x1405292B0 | CEffectEntry<NDoctrines::CAddMasteryBonusEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CAddMasteryBonusEffect>::[1] |
| 0x14151FC90 | CStatePeaceAction::UpdateCachedCost func_names 名 CStatePeaceAction::UpdateCachedCost |
| 0x140433B10 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x140444670 | CTriggerEntry<CCharacterFlagTrigger>::[1] func_names 名 CTriggerEntry<CCharacterFlagTrigger>::[1] |
| 0x140B4B340 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1422E86B0 | CChatBuffer::CSendChatMessage::PayloadReader func_names 名 CChatBuffer::CSendChatMessage::PayloadReader |
| 0x14033C770 | CEffectEntry<CAddUnitsToDivisionTemplateEffect>::[1] func_names 名 CEffectEntry<CAddUnitsToDivisionTemplateEffect>::[1] |
| 0x141681FE0 | CStateGraphics::[1] vtable 槽 CStateGraphics::[1]（func_names RTTI 名） |
| 0x1403E2E30 | CTriggerEntry<CAllAlliedCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllAlliedCountryTrigger>::[1] |
| 0x14049B4E0 | CEffectEntry<CCreateProductionLicense>::[1] func_names 名 CEffectEntry<CCreateProductionLicense>::[1] |
| 0x1405355E0 | （无名） 体设 CSavedEventTarget::vftable（RTTI 名） |
| 0x141870170 | CPlayerLobby::KickPlayer func_names 名 CPlayerLobby::KickPlayer |
| 0x141EE7A70 | CGoal::GetPrioritizedObjectives func_names 名 CGoal::GetPrioritizedObjectives |
| 0x141B54730 | CDBNudger::[2] vtable 槽 CDBNudger::[2]（func_names RTTI 名） |
| 0x14033B980 | CEffectEntry<CAddCountryLeaderRoleEffect>::[1] func_names 名 CEffectEntry<CAddCountryLeaderRoleEffect>::[1] |
| 0x140AD2820 | （无名） 体设 CFolderPosition::vftable（RTTI 名） |
| 0x142301090 | CSmoothListbox::[9] vtable 槽 CSmoothListbox::[9]（func_names RTTI 名） |
| 0x140C12D00 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x140CB68E0 | CResourceOrigin::[11] vtable 槽 CResourceOrigin::[11]（func_names RTTI 名） |
| 0x1401ADF70 | CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[12] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[12] |
| 0x14030B7B0 | CEffectEntry<CAddStateModifierEffect>::[1] func_names 名 CEffectEntry<CAddStateModifierEffect>::[1] |
| 0x14030B830 | CEffectEntry<CAddStateResistanceComplianceModifierEffect>::[1] func_names 名 CEffectEntry<CAddStateResistanceComplianceModifierEffect>::[1] |
| 0x141B4BE20 | CBuildingsNudger::[2] vtable 槽 CBuildingsNudger::[2]（func_names RTTI 名） |
| 0x141B63DB0 | CStrategicRegionNudger::[2] vtable 槽 CStrategicRegionNudger::[2]（func_names RTTI 名） |
| 0x141B8A020 | CWeatherNudger::[2] vtable 槽 CWeatherNudger::[2]（func_names RTTI 名） |
| 0x140340C60 | CEffectEntry<CSetAirOobEffect>::[1] func_names 名 CEffectEntry<CSetAirOobEffect>::[1] |
| 0x140146F50 | （无名） 体设 CAiTaskforceTemplate::vftable（RTTI 名） |
| 0x14047C580 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140FC63E0 | COperativeMission::CalcOperativesToReassignIfAssignedToQuietNet鈥� func_names 名 COperativeMission::CalcOperativesToReassignIfAssignedToQuietNet鈥� |
| 0x1411CFAA0 | （无名） 体设 CSubIntelNetwork::vftable（RTTI 名） |
| 0x1422AC340 | CChoice<CSmoothListboxItem>::[1] func_names 名 CChoice<CSmoothListboxItem>::[1] |
| 0x1401AE080 | CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[8] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[8] |
| 0x140F5A480 | （无名） 体设 CReferenceObject::vftable（RTTI 名） |
| 0x14222E620 | CAssetsReloader::Update func_names 名 CAssetsReloader::Update |
| 0x140EE5B00 | CTechnologySharingGroup::[16] vtable 槽 CTechnologySharingGroup::[16]（func_names RTTI 名） |
| 0x14163EA30 | CFrontEndInterfaceHandler::[0] vtable 槽 CFrontEndInterfaceHandler::[0]（func_names RTTI 名） |
| 0x1422A9110 | （无名） 体设 CChoiceException::vftable（RTTI 名） |
| 0x140A6D290 | SButtonReader::[2] vtable 槽 SButtonReader::[2]（func_names RTTI 名） |
| 0x1403AE100 | CAddRemoveDynamicModifierEffect<$00>::[4] func_names 名 CAddRemoveDynamicModifierEffect<$00>::[4] |
| 0x140D7FA30 | （无名） 体设 SDoctrineEquipmentBonusHandle::vftable（RTTI 名） |
| 0x140AB1A40 | CScriptedDiplomaticAction::[62] vtable 槽 CScriptedDiplomaticAction::[62]（func_names RTTI 名） |
| 0x14048FC90 | CAddEquipmentProduction::[0] vtable 槽 CAddEquipmentProduction::[0]（func_names RTTI 名） |
| 0x141484C80 | （无名） 体设 CSavedAchievementMod::vftable（RTTI 名） |
| 0x14170AC90 | CCountryMilitaryOverview::[7] vtable 槽 CCountryMilitaryOverview::[7]（func_names RTTI 名） |
| 0x14033B5F0 | CEffectEntry<CAddAdvisorRoleEffect>::[1] func_names 名 CEffectEntry<CAddAdvisorRoleEffect>::[1] |
| 0x140FC63C0 | COperativeMission::CalcOperativesToReassignIfAssignedToNetworkI鈥� func_names 名 COperativeMission::CalcOperativesToReassignIfAssignedToNetworkI鈥� |
| 0x1423E7610 | CSteamNetContext::[22] vtable 槽 CSteamNetContext::[22]（func_names RTTI 名） |
| 0x140483C50 | CEffectEntry<CSetPowerBalanceGfx>::[1] func_names 名 CEffectEntry<CSetPowerBalanceGfx>::[1] |
| 0x14049B580 | CEffectEntry<CSendEquipmentEffect>::[1] func_names 名 CEffectEntry<CSendEquipmentEffect>::[1] |
| 0x140DEDC80 | CEquipmentMarketSystem::SetCallbacks? func_names 名 CEquipmentMarketSystem::SetCallbacks? |
| 0x141503130 | CIncomingLendLeaseAction::[27] vtable 槽 CIncomingLendLeaseAction::[27]（func_names RTTI 名） |
| 0x14151F170 | CTakeNavyPeaceAction::IsValid func_names 名 CTakeNavyPeaceAction::IsValid |
| 0x1403DB750 | CIsLeadingVolunteerGroup::Evaluate func_names 名 CIsLeadingVolunteerGroup::Evaluate |
| 0x1403DB7E0 | CIsLeadingVolunteerGroupWithOriginalCountry::Evaluate func_names 名 CIsLeadingVolunteerGroupWithOriginalCountry::Evaluate |
| 0x141513A60 | （无名） 体设 CIncomingDiplomaticActionStatus::vftable（RTTI 名） |
| 0x140C0B6B0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1422ACA80 | CSimpleListbox<CStandardlistboxItem>::[9] func_names 名 CSimpleListbox<CStandardlistboxItem>::[9] |
| 0x140F9D2B0 | CResistance::SAddedResistanceTarget::Writer func_names 名 CResistance::SAddedResistanceTarget::Writer |
| 0x1419399D0 | （无名） 体设 CProductionResourceCost::vftable（RTTI 名） |
| 0x14049CF90 | CSetEquipmentFraction::Execute func_names 名 CSetEquipmentFraction::Execute |
| 0x140442CD0 | CIsCountryLeader::Evaluate func_names 名 CIsCountryLeader::Evaluate |
| 0x141A9ECB0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1402F7E30 | CEffectEntry<CCaptureGeneralEffect>::[1] func_names 名 CEffectEntry<CCaptureGeneralEffect>::[1] |
| 0x140341980 | CEffectEntry<CSetPartyRuleEffect>::[1] func_names 名 CEffectEntry<CSetPartyRuleEffect>::[1] |
| 0x140CA6100 | CResourceDeliveryRoute::[0] vtable 槽 CResourceDeliveryRoute::[0]（func_names RTTI 名） |
| 0x14030C280 | CEffectEntry<CSetStateProvincesControllerEffect>::[1] func_names 名 CEffectEntry<CSetStateProvincesControllerEffect>::[1] |
| 0x1415095B0 | （无名） 体设 CArmyUpgradesStatus::vftable（RTTI 名） |
| 0x141A9EB80 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14112DBC0 | CEmbargoAction::[23] vtable 槽 CEmbargoAction::[23]（func_names RTTI 名） |
| 0x1413CA380 | （无名） 体设 STemporaryMasteryGain::vftable（RTTI 名） |
| 0x140455F20 | CTriggerEntry<CAllOperativeLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAllOperativeLeaderTrigger>::[1] |
| 0x142089A50 | CTweakableDropDown::[0] vtable 槽 CTweakableDropDown::[0]（func_names RTTI 名） |
| 0x1402E5510 | CEffectEntry<CSetPortraitEffect>::[1] func_names 名 CEffectEntry<CSetPortraitEffect>::[1] |
| 0x140646340 | CBufferUnitsAtStateData::[0] vtable 槽 CBufferUnitsAtStateData::[0]（func_names RTTI 名） |
| 0x140D01C10 | （无名） 体设 CStaticIntelSourcePool::vftable（RTTI 名） |
| 0x140D649D0 | CPdxLinearAllocator::[1] vtable 槽 CPdxLinearAllocator::[1]（func_names RTTI 名） |
| 0x1422ABBE0 | CStandardlistbox::[78] vtable 槽 CStandardlistbox::[78]（func_names RTTI 名） |
| 0x14033B380 | CEffectEntry<CActivateMissionTooltipEffect>::[1] func_names 名 CEffectEntry<CActivateMissionTooltipEffect>::[1] |
| 0x1403E5770 | CTriggerEntry<CHasCountryLeaderTrigger>::[1] func_names 名 CTriggerEntry<CHasCountryLeaderTrigger>::[1] |
| 0x14030B9E0 | CEffectEntry<CDamageBuildingEffect>::[1] func_names 名 CEffectEntry<CDamageBuildingEffect>::[1] |
| 0x1410DAC60 | CBuilding::[0] vtable 槽 CBuilding::[0]（func_names RTTI 名） |
| 0x1401C9850 | CTechnologySharingGroup::[0] vtable 槽 CTechnologySharingGroup::[0]（func_names RTTI 名） |
| 0x1406D3800 | CPdxStaticInlineBufferAllocator<$00H::CCountryTag>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$00H::CCountryTag>::[1] |
| 0x140A02EE0 | CPdxStaticInlineBufferAllocator<$02H::CFixedPoint>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$02H::CFixedPoint>::[1] |
| 0x140A26F20 | CPdxStaticInlineBufferAllocator<H$02H>::[1] func_names 名 CPdxStaticInlineBufferAllocator<H$02H>::[1] |
| 0x140A26F90 | CPdxStaticInlineBufferAllocator<H$03H>::[1] func_names 名 CPdxStaticInlineBufferAllocator<H$03H>::[1] |
| 0x140A27070 | CPdxStaticInlineBufferAllocator<$02H::CGameDate>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$02H::CGameDate>::[1] |
| 0x140B98E30 | CPdxStaticInlineBufferAllocator<鈥�>::[1] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[1] |
| 0x140CA6CB0 | CPdxStaticInlineBufferAllocator<$00H::EBVCState*>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$00H::EBVCState*>::[1] |
| 0x140E884F0 | CPdxStaticInlineBufferAllocator<$00H::EBVCProvince*>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$00H::EBVCProvince*>::[1] |
| 0x140F31C40 | CPdxStaticInlineBufferAllocator<鈥�>::[1] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[1] |
| 0x140F31CB0 | H::$0BH::CPdxStaticInlineBufferAllocator<bool>::[1] func_names 名 H::$0BH::CPdxStaticInlineBufferAllocator<bool>::[1] |
| 0x140FAA5B0 | CPdxStaticInlineBufferAllocator<$00H::EBVCStrategicRegion*>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$00H::EBVCStrategicRegion*>::[1] |
| 0x1413D53F0 | CPdxStaticInlineBufferAllocator<$02H::CString>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$02H::CString>::[1] |
| 0x14146D6C0 | CPdxStaticInlineBufferAllocator<$04H::CFixedPoint>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$04H::CFixedPoint>::[1] |
| 0x1416D9D30 | CPdxStaticInlineBufferAllocator<$04H::SProximityLoc>::[1] func_names 名 CPdxStaticInlineBufferAllocator<$04H::SProximityLoc>::[1] |
| 0x14192AC10 | CPdxStaticInlineBufferAllocator<鈥�>::[1] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[1] |
| 0x141A46BC0 | CPdxStaticInlineBufferAllocator<鈥�>::[1] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[1] |
| 0x14200F240 | CPdxStaticInlineBufferAllocator<鈥�>::[1] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[1] |
| 0x14200FDC0 | CPdxStaticInlineBufferAllocator<鈥�>::[1] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[1] |
| 0x1424C5A60 | CPdxStaticInlineBufferAllocator<I$01H>::[1] func_names 名 CPdxStaticInlineBufferAllocator<I$01H>::[1] |
| 0x14205BB00 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[0] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[0] |
| 0x140220260 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14031EFA0 | CEffectEntry<CAddTechBonusEffect>::[1] func_names 名 CEffectEntry<CAddTechBonusEffect>::[1] |
| 0x1422AAFA0 | CChoice<CSmoothListboxItem>::[5] func_names 名 CChoice<CSmoothListboxItem>::[5] |
| 0x1423711D0 | CDropDownBoxType::[0] vtable 槽 CDropDownBoxType::[0]（func_names RTTI 名） |
| 0x14015F500 | CEquipmentGraphicDatabase::[1] vtable 槽 CEquipmentGraphicDatabase::[1]（func_names RTTI 名） |
| 0x14033C6F0 | CEffectEntry<CAddUnitBonusEffect>::[1] func_names 名 CEffectEntry<CAddUnitBonusEffect>::[1] |
| 0x14033C8D0 | CEffectEntry<CBecomeExiledGovernmentEffect>::[1] func_names 名 CEffectEntry<CBecomeExiledGovernmentEffect>::[1] |
| 0x140E5C760 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x1422A9BF0 | CChoice<CSmoothListboxItem>::[4] func_names 名 CChoice<CSmoothListboxItem>::[4] |
| 0x14033D570 | CEffectEntry<CCreateWargoalEffect>::[1] func_names 名 CEffectEntry<CCreateWargoalEffect>::[1] |
| 0x140A27000 | CPdxStaticInlineBufferAllocator<CPdxArray<$02H::H::LexerToken>>::[1] func_names 名 CPdxStaticInlineBufferAllocator<CPdxArray<$02H::H::LexerToken>>::[1] |
| 0x140DDCE30 | CInGameIdler::CollectReloadNames func_names 名 CInGameIdler::CollectReloadNames |
| 0x1422E0C80 | （无名） 体设 CStartFileTransfer::vftable（RTTI 名） |
| 0x140A69DC0 | CNameDatabase::[1] vtable 槽 CNameDatabase::[1]（func_names RTTI 名） |
| 0x1402FA420 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14015D7A0 | TGameItemDatabase<NFactions::CFactionRuleGroupDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionRuleGroupDatabase>::[1] |
| 0x140CD8200 | （无名） 体设 SCombatData::vftable（RTTI 名） |
| 0x1422E8770 | CChatBuffer::CWriteToChatBuffer::PayloadReader func_names 名 CChatBuffer::CWriteToChatBuffer::PayloadReader |
| 0x1402E4840 | CEffectEntry<CSetCountryLeaderNamePortraitOrDescription<$00>>::[1] func_names 名 CEffectEntry<CSetCountryLeaderNamePortraitOrDescription<$00>>::[1] |
| 0x14030BC20 | CEffectEntry<CRemoveBuildingEffect>::[1] func_names 名 CEffectEntry<CRemoveBuildingEffect>::[1] |
| 0x140D6B280 | CTaskForce::[37] vtable 槽 CTaskForce::[37]（func_names RTTI 名） |
| 0x1419750A0 | CFEXMember::SReceivedDamageData::Reader func_names 名 CFEXMember::SReceivedDamageData::Reader |
| 0x14206A420 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[0] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[0] |
| 0x140AB5CC0 | TGameItemDatabase<CScriptedTriggerTemplateDatabase>::[1] func_names 名 TGameItemDatabase<CScriptedTriggerTemplateDatabase>::[1] |
| 0x1415A00E0 | CSetStateBuildings::[0] vtable 槽 CSetStateBuildings::[0]（func_names RTTI 名） |
| 0x1403E6B30 | CTriggerEntry<CHasTechBonusTrigger>::[1] func_names 名 CTriggerEntry<CHasTechBonusTrigger>::[1] |
| 0x1415031D0 | CLendLeaseAction::[27] vtable 槽 CLendLeaseAction::[27]（func_names RTTI 名） |
| 0x14188BFA0 | CTheatreSelector::Reload func_names 名 CTheatreSelector::Reload |
| 0x1422E5930 | CStandardChatMessage::[10] vtable 槽 CStandardChatMessage::[10]（func_names RTTI 名） |
| 0x14015D3A0 | TGameItemDatabase<CCountryTagAliasDatabase>::[1] func_names 名 TGameItemDatabase<CCountryTagAliasDatabase>::[1] |
| 0x14015DFA0 | TGameItemDatabase<CPeaceConferenceDatabase>::[1] func_names 名 TGameItemDatabase<CPeaceConferenceDatabase>::[1] |
| 0x140319470 | CStartResistance::GetDesc func_names 名 CStartResistance::GetDesc |
| 0x14049D050 | CSetEquipmentVersionNumber::Execute func_names 名 CSetEquipmentVersionNumber::Execute |
| 0x1422ABE60 | CStandardlistbox::[14] vtable 槽 CStandardlistbox::[14]（func_names RTTI 名） |
| 0x140330020 | CAddRemoveDynamicModifierEffect<$00>::[0] func_names 名 CAddRemoveDynamicModifierEffect<$00>::[0] |
| 0x14035CF80 | CRemoveCivilWarTarget::Execute func_names 名 CRemoveCivilWarTarget::Execute |
| 0x1422A2B70 | CBitmapFont::[20] vtable 槽 CBitmapFont::[20]（func_names RTTI 名） |
| 0x14015E3A0 | TGameItemDatabase<CScriptEnumDatabase>::[1] func_names 名 TGameItemDatabase<CScriptEnumDatabase>::[1] |
| 0x14033B460 | CEffectEntry<CActivateTargetedDecisionEffect>::[1] func_names 名 CEffectEntry<CActivateTargetedDecisionEffect>::[1] |
| 0x140AEFDB0 | TGameItemDatabase<CUnitNamesDatabase>::[1] func_names 名 TGameItemDatabase<CUnitNamesDatabase>::[1] |
| 0x140D18D40 | CAttacheRelation::[0] vtable 槽 CAttacheRelation::[0]（func_names RTTI 名） |
| 0x140DB6CF0 | （无名） 体设 CUnlockIndustrialOrganisationTrait::vftable（RTTI 名） |
| 0x1406132F0 | TGameItemDatabase<CAbilityDatabase>::[1] func_names 名 TGameItemDatabase<CAbilityDatabase>::[1] |
| 0x142377860 | COverlappingElementsBoxType::[0] vtable 槽 COverlappingElementsBoxType::[0]（func_names RTTI 名） |
| 0x1422ACF90 | CStandardlistbox::[28] vtable 槽 CStandardlistbox::[28]（func_names RTTI 名） |
| 0x14015DBA0 | TGameItemDatabase<CMTTHDatabase>::[1] func_names 名 TGameItemDatabase<CMTTHDatabase>::[1] |
| 0x14033BCB0 | CEffectEntry<CAddIntelEffect>::[1] func_names 名 CEffectEntry<CAddIntelEffect>::[1] |
| 0x140A69D00 | TGameItemDatabase<CNameDatabase>::[1] func_names 名 TGameItemDatabase<CNameDatabase>::[1] |
| 0x14033C660 | CEffectEntry<CAddToWarEffect>::[1] func_names 名 CEffectEntry<CAddToWarEffect>::[1] |
| 0x1404839B0 | CEffectEntry<CAddPowerBalanceValueEffect>::[1] func_names 名 CEffectEntry<CAddPowerBalanceValueEffect>::[1] |
| 0x140482D00 | CVariableEffectBuilder<CGetSupplyVehicles<CVariableResolver>>::[4] func_names 名 CVariableEffectBuilder<CGetSupplyVehicles<CVariableResolver>>::[4] |
| 0x140BFF770 | CUnit::HasLowSupply func_names 名 CUnit::HasLowSupply |
| 0x1401AE000 | CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[10] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[10] |
| 0x1414D66D0 | CPendingTransportUnit::[4] vtable 槽 CPendingTransportUnit::[4]（func_names RTTI 名） |
| 0x14033D7B0 | CEffectEntry<CDeclareWarEffect>::[1] func_names 名 CEffectEntry<CDeclareWarEffect>::[1] |
| 0x142360590 | CResizeableSpriteType::[0] vtable 槽 CResizeableSpriteType::[0]（func_names RTTI 名） |
| 0x14033E240 | CEffectEntry<CForEachScopeEffect>::[1] func_names 名 CEffectEntry<CForEachScopeEffect>::[1] |
| 0x1410FC300 | （无名） 体设 CGiveStateControlAction::vftable（RTTI 名） |
| 0x140DE63B0 | CPauseGame::[0] vtable 槽 CPauseGame::[0]（func_names RTTI 名） |
| 0x140FC6410 | COperativeMission::CalcOperativesToReassignIfAssignedToQuietNet鈥� func_names 名 COperativeMission::CalcOperativesToReassignIfAssignedToQuietNet鈥� |
| 0x14114E100 | （无名） 体设 SDecisionData::vftable（RTTI 名） |
| 0x140C11540 | CNavyLeader::[30] vtable 槽 CNavyLeader::[30]（func_names RTTI 名） |
| 0x140ADA520 | CTimedStageCoupActivity::[12] vtable 槽 CTimedStageCoupActivity::[12]（func_names RTTI 名） |
| 0x1422DB370 | CWrapWorldShadowMap::[1] vtable 槽 CWrapWorldShadowMap::[1]（func_names RTTI 名） |
| 0x14203E010 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[0] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[0] |
| 0x1424B8C30 | （无名） 体设 CTweakable::vftable（RTTI 名） |
| 0x140B6B670 | CSlowInterfaceIndicator::Reload func_names 名 CSlowInterfaceIndicator::Reload |
| 0x14151B6F0 | CPuppetCountryAction::Clone func_names 名 CPuppetCountryAction::Clone |
| 0x14033FB40 | CEffectEntry<CRandomOwnedStateEffect>::[1] func_names 名 CEffectEntry<CRandomOwnedStateEffect>::[1] |
| 0x1410FCAE0 | CSendExpeditionaryForceAction::[0] vtable 槽 CSendExpeditionaryForceAction::[0]（func_names RTTI 名） |
| 0x140331F00 | CForceUpdateMapMode::[0] vtable 槽 CForceUpdateMapMode::[0]（func_names RTTI 名） |
| 0x140641CA0 | CSubUnitStatBonus::[0] vtable 槽 CSubUnitStatBonus::[0]（func_names RTTI 名） |
| 0x140FC6400 | COperativeMission::CalcOperativesToReassignIfAssignedToNetworkI鈥� func_names 名 COperativeMission::CalcOperativesToReassignIfAssignedToNetworkI鈥� |
| 0x140330620 | CAddAutonomyRatio::[0] vtable 槽 CAddAutonomyRatio::[0]（func_names RTTI 名） |
| 0x140340520 | CEffectEntry<CRemoveRelationRuleOverrideEffect>::[1] func_names 名 CEffectEntry<CRemoveRelationRuleOverrideEffect>::[1] |
| 0x1403E7640 | CTriggerEntry<CIsFinishedCollectingForAnOperation>::[1] func_names 名 CTriggerEntry<CIsFinishedCollectingForAnOperation>::[1] |
| 0x140B744F0 | CSong::[0] vtable 槽 CSong::[0]（func_names RTTI 名） |
| 0x14061C930 | CAchievementMod::[0] vtable 槽 CAchievementMod::[0]（func_names RTTI 名） |
| 0x140C04E90 | CUnit::TakeDamageImmediate func_names 名 CUnit::TakeDamageImmediate |
| 0x1413932B0 | CEffectEntry<CWithTooltipOverrideEffect>::[1] func_names 名 CEffectEntry<CWithTooltipOverrideEffect>::[1] |
| 0x14014C370 | （无名） 体设 SGameModeStatistics::vftable（RTTI 名） |
| 0x14033CAF0 | CEffectEntry<CCaptureOperativeEffect>::[1] func_names 名 CEffectEntry<CCaptureOperativeEffect>::[1] |
| 0x1403E28D0 | CTriggerEntry<CForEachScopesTriggerImp<$00>>::[1] func_names 名 CTriggerEntry<CForEachScopesTriggerImp<$00>>::[1] |
| 0x1404890B0 | CTriggerEntry<CIsPowerBalanceSideActiveTrigger>::[1] func_names 名 CTriggerEntry<CIsPowerBalanceSideActiveTrigger>::[1] |
| 0x14064B190 | （无名） 体设 CAIFocus::vftable（RTTI 名） |
| 0x1403E7E20 | CTriggerEntry<CIsPreparingOperation>::[1] func_names 名 CTriggerEntry<CIsPreparingOperation>::[1] |
| 0x1403E8930 | CTriggerEntry<CNumCompletedOperations>::[1] func_names 名 CTriggerEntry<CNumCompletedOperations>::[1] |
| 0x140341080 | CEffectEntry<CSetCountryNationalFocusTreeEffect>::[1] func_names 名 CEffectEntry<CSetCountryNationalFocusTreeEffect>::[1] |
| 0x14047C290 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14151A0D0 | CForceGovernmentAction::GetActionLabel func_names 名 CForceGovernmentAction::GetActionLabel |
| 0x140341900 | CEffectEntry<CSetPartyNameEffect>::[1] func_names 名 CEffectEntry<CSetPartyNameEffect>::[1] |
| 0x140C04E30 | CUnit::TakeDamage func_names 名 CUnit::TakeDamage |
| 0x14015D120 | TGameItemDatabase<鈥�>::[1] func_names 名 TGameItemDatabase<鈥�>::[1] |
| 0x140442F40 | CIsFieldMarshal::Evaluate func_names 名 CIsFieldMarshal::Evaluate |
| 0x140D0D3D0 | （无名） 体设 CNavalDeploymentTarget::vftable（RTTI 名） |
| 0x141236580 | CInGameUpdateableInterface::IsVisible func_names 名 CInGameUpdateableInterface::IsVisible |
| 0x141236700 | CInGameUpdateableInterface::PreSetup func_names 名 CInGameUpdateableInterface::PreSetup |
| 0x142356160 | （无名） 体设 C2dLineObject::vftable（RTTI 名） |
| 0x14015DF20 | TGameItemDatabase<鈥�>::[1] func_names 名 TGameItemDatabase<鈥�>::[1] |
| 0x1403412E0 | CEffectEntry<CSetEntityPositionEffect>::[1] func_names 名 CEffectEntry<CSetEntityPositionEffect>::[1] |
| 0x140341740 | CEffectEntry<CSetNavalOobEffect>::[1] func_names 名 CEffectEntry<CSetNavalOobEffect>::[1] |
| 0x14066E2E0 | TGameItemDatabase<CAmbientSoundDatabase>::[1] func_names 名 TGameItemDatabase<CAmbientSoundDatabase>::[1] |
| 0x140C043C0 | CUnit::ReturnFromExile func_names 名 CUnit::ReturnFromExile |
| 0x142365AF0 | CNetworkServer::[24] vtable 槽 CNetworkServer::[24]（func_names RTTI 名） |
| 0x1402FA2F0 | CEffectEntry<NIndustrialOrganisation::CShowIndustrialOrgTooltip>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CShowIndustrialOrgTooltip>::[1] |
| 0x1403E7FC0 | CTriggerEntry<CIsRunningOperation>::[1] func_names 名 CTriggerEntry<CIsRunningOperation>::[1] |
| 0x14047C380 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x141407380 | ULexerToken::UEAAXAEAVCReader::CCountryOperationTokenManager::?鈥�::[2] func_names 名 ULexerToken::UEAAXAEAVCReader::CCountryOperationTokenManager::?鈥�::[2] |
| 0x14033CEC0 | CEffectEntry<CCompleteNationalFocusEffect>::[1] func_names 名 CEffectEntry<CCompleteNationalFocusEffect>::[1] |
| 0x14015D1A0 | TGameItemDatabase<NFactions::NAi::CAiFactionTheaterDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::NAi::CAiFactionTheaterDatabase>::[1] |
| 0x14015E120 | TGameItemDatabase<NProject::CProjectDynamicModifierDatabase>::[1] func_names 名 TGameItemDatabase<NProject::CProjectDynamicModifierDatabase>::[1] |
| 0x140ADA870 | CTimedActivityEquipmentDistributable::[2] vtable 槽 CTimedActivityEquipmentDistributable::[2]（func_names RTTI 名） |
| 0x14015D620 | TGameItemDatabase<NFactions::CFactionMemberUpgradeDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionMemberUpgradeDatabase>::[1] |
| 0x14015E020 | TGameItemDatabase<NIndustrialOrganisation::CPolicyDatabase>::[1] func_names 名 TGameItemDatabase<NIndustrialOrganisation::CPolicyDatabase>::[1] |
| 0x1413DF0C0 | SAdvisorBonus::[0] vtable 槽 SAdvisorBonus::[0]（func_names RTTI 名） |
| 0x141B6D610 | CSupplyNudger::CollectReloadNames func_names 名 CSupplyNudger::CollectReloadNames |
| 0x141C8C7B0 | CDiplomacySendExpeditionaryForceController::[1] vtable 槽 CDiplomacySendExpeditionaryForceController::[1]（func_names RTTI 名） |
| 0x14030BB00 | CEffectEntry<CForceDisableResistanceEffect>::[1] func_names 名 CEffectEntry<CForceDisableResistanceEffect>::[1] |
| 0x14015D820 | TGameItemDatabase<NFactions::CFactionTemplateDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionTemplateDatabase>::[1] |
| 0x14033AB90 | CEffectEntry<CFindHighestLowestInArrayEffect<$0A>>::[1] func_names 名 CEffectEntry<CFindHighestLowestInArrayEffect<$0A>>::[1] |
| 0x14015E1A0 | TGameItemDatabase<NProject::CPrototypeRewardDatabase>::[1] func_names 名 TGameItemDatabase<NProject::CPrototypeRewardDatabase>::[1] |
| 0x14047C680 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140488EF0 | CTriggerEntry<CHasPowerBalanceModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasPowerBalanceModifierTrigger>::[1] |
| 0x14014C2E0 | （无名） 体设 SCareerProfileStatistics::vftable（RTTI 名） |
| 0x14015DC20 | TGameItemDatabase<NScript::CNamedCollectionDatabase>::[1] func_names 名 TGameItemDatabase<NScript::CNamedCollectionDatabase>::[1] |
| 0x14015E4A0 | TGameItemDatabase<NProject::CSpecializationDatabase>::[1] func_names 名 TGameItemDatabase<NProject::CSpecializationDatabase>::[1] |
| 0x141651240 | （无名） 体设 SDistanceMesh::vftable（RTTI 名） |
| 0x141FFA540 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x14015D5A0 | TGameItemDatabase<NFactions::CFactionIconsDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionIconsDatabase>::[1] |
| 0x14015E5A0 | TGameItemDatabase<NDoctrines::CSubDoctrineDatabase>::[1] func_names 名 TGameItemDatabase<NDoctrines::CSubDoctrineDatabase>::[1] |
| 0x140C04440 | CUnit::Exile func_names 名 CUnit::Exile |
| 0x1422AC080 | CSimpleListbox<CStandardlistboxItem>::[18] func_names 名 CSimpleListbox<CStandardlistboxItem>::[18] |
| 0x14015D520 | TGameItemDatabase<NFactions::CFactionGoalDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionGoalDatabase>::[1] |
| 0x14015D720 | TGameItemDatabase<NFactions::CFactionRuleDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionRuleDatabase>::[1] |
| 0x14015E420 | TGameItemDatabase<CScriptedEffectTemplateDatabase>::[1] func_names 名 TGameItemDatabase<CScriptedEffectTemplateDatabase>::[1] |
| 0x142273600 | （无名） 体设 CLauncherSettings::vftable（RTTI 名） |
| 0x14236D620 | CIconType::[0] vtable 槽 CIconType::[0]（func_names RTTI 名） |
| 0x140332000 | CGenerateCharacter::[0] vtable 槽 CGenerateCharacter::[0]（func_names RTTI 名） |
| 0x140734E10 | CDecisionCategory::SOnMapLocator::Reader func_names 名 CDecisionCategory::SOnMapLocator::Reader |
| 0x14012A150 | CPdxHybridInlineBufferAllocator<H::$0CA::CString>::[8] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CString>::[8] |
| 0x14015DA20 | TGameItemDatabase<NAiNavalGoals::CGoalDatabase>::[1] func_names 名 TGameItemDatabase<NAiNavalGoals::CGoalDatabase>::[1] |
| 0x1403E7F40 | CTriggerEntry<CIsResearchingTechnologyTrigger>::[1] func_names 名 CTriggerEntry<CIsResearchingTechnologyTrigger>::[1] |
| 0x141446650 | CUnitHistory::[0] vtable 槽 CUnitHistory::[0]（func_names RTTI 名） |
| 0x14015D920 | TGameItemDatabase<NDoctrines::CFolderDatabase>::[1] func_names 名 TGameItemDatabase<NDoctrines::CFolderDatabase>::[1] |
| 0x14015D9A0 | TGameItemDatabase<CFrontEndBackgroundDatabase>::[1] func_names 名 TGameItemDatabase<CFrontEndBackgroundDatabase>::[1] |
| 0x14015DD20 | TGameItemDatabase<COccupationModifierDatabase>::[1] func_names 名 TGameItemDatabase<COccupationModifierDatabase>::[1] |
| 0x140BAD180 | （无名） 体设 CTimedIdea::vftable（RTTI 名） |
| 0x14015D320 | TGameItemDatabase<NScript::CConstantDatabase>::[1] func_names 名 TGameItemDatabase<NScript::CConstantDatabase>::[1] |
| 0x14015E0A0 | TGameItemDatabase<NProject::CProjectDatabase>::[1] func_names 名 TGameItemDatabase<NProject::CProjectDatabase>::[1] |
| 0x14015E520 | TGameItemDatabase<CStrategicLocationDatabase>::[1] func_names 名 TGameItemDatabase<CStrategicLocationDatabase>::[1] |
| 0x14015E620 | TGameItemDatabase<NDoctrines::CTrackDatabase>::[1] func_names 名 TGameItemDatabase<NDoctrines::CTrackDatabase>::[1] |
| 0x1403E6710 | CTriggerEntry<CHasRailwayLevelTrigger>::[1] func_names 名 CTriggerEntry<CHasRailwayLevelTrigger>::[1] |
| 0x1422E57F0 | CStandardChatMessage::[0] vtable 槽 CStandardChatMessage::[0]（func_names RTTI 名） |
| 0x14015D420 | TGameItemDatabase<CEquipmentGraphicDatabase>::[1] func_names 名 TGameItemDatabase<CEquipmentGraphicDatabase>::[1] |
| 0x14015D8A0 | TGameItemDatabase<CFocusInlayWindowDatabase>::[1] func_names 名 TGameItemDatabase<CFocusInlayWindowDatabase>::[1] |
| 0x14015DB20 | TGameItemDatabase<CHistoricalAgencyDatabase>::[1] func_names 名 TGameItemDatabase<CHistoricalAgencyDatabase>::[1] |
| 0x1423E0950 | CSteamMatchmakingContext::[19] vtable 槽 CSteamMatchmakingContext::[19]（func_names RTTI 名） |
| 0x14015D220 | TGameItemDatabase<CAiFleetTemplateDatabase>::[1] func_names 名 TGameItemDatabase<CAiFleetTemplateDatabase>::[1] |
| 0x14015DDA0 | TGameItemDatabase<COperationPhasesDatabase>::[1] func_names 名 TGameItemDatabase<COperationPhasesDatabase>::[1] |
| 0x14015DE20 | TGameItemDatabase<COperationTokensDatabase>::[1] func_names 名 TGameItemDatabase<COperationTokensDatabase>::[1] |
| 0x14062D7F0 | TGameItemDatabase<CAIEquipmentRoleDatabase>::[1] func_names 名 TGameItemDatabase<CAIEquipmentRoleDatabase>::[1] |
| 0x140673F80 | TGameItemDatabase<CAutonomousStateDatabase>::[1] func_names 名 TGameItemDatabase<CAutonomousStateDatabase>::[1] |
| 0x1406C1170 | TGameItemDatabase<CContinuousFocusDatabase>::[1] func_names 名 TGameItemDatabase<CContinuousFocusDatabase>::[1] |
| 0x140AAE070 | TGameItemDatabase<CScriptedMapModeDatabase>::[1] func_names 名 TGameItemDatabase<CScriptedMapModeDatabase>::[1] |
| 0x140AC0110 | TGameItemDatabase<CStrategicRegionDatabase>::[1] func_names 名 TGameItemDatabase<CStrategicRegionDatabase>::[1] |
| 0x14015D4A0 | TGameItemDatabase<CEquipmentGroupDatabase>::[1] func_names 名 TGameItemDatabase<CEquipmentGroupDatabase>::[1] |
| 0x14015E320 | TGameItemDatabase<CScientistTraitDatabase>::[1] func_names 名 TGameItemDatabase<CScientistTraitDatabase>::[1] |
| 0x14033A860 | CEffectEntry<CAddToArrayEffectImp<$00>>::[1] func_names 名 CEffectEntry<CAddToArrayEffectImp<$00>>::[1] |
| 0x140492E20 | CEffectEntry<NProject::CEveryScientistEffect>::[1] func_names 名 CEffectEntry<NProject::CEveryScientistEffect>::[1] |
| 0x140645EF0 | TGameItemDatabase<CAIStrategyPlanDatabase>::[1] func_names 名 TGameItemDatabase<CAIStrategyPlanDatabase>::[1] |
| 0x140AB2720 | CScriptedDiplomaticAction::GetCostText func_names 名 CScriptedDiplomaticAction::GetCostText |
| 0x140AB9250 | TGameItemDatabase<CScriptedWindowDatabase>::[1] func_names 名 TGameItemDatabase<CScriptedWindowDatabase>::[1] |
| 0x1422D3270 | CArrowObject::[0] vtable 槽 CArrowObject::[0]（func_names RTTI 名） |
| 0x14015DCA0 | TGameItemDatabase<COccupationLawDatabase>::[1] func_names 名 TGameItemDatabase<COccupationLawDatabase>::[1] |
| 0x1402CCDB0 | TGameItemDatabase<CNationalFocusDatabase>::[1] func_names 名 TGameItemDatabase<CNationalFocusDatabase>::[1] |
| 0x140623160 | TGameItemDatabase<CAgencyUpgradeDatabase>::[1] func_names 名 TGameItemDatabase<CAgencyUpgradeDatabase>::[1] |
| 0x14071DCE0 | TGameItemDatabase<CCountryLeaderDatabase>::[1] func_names 名 TGameItemDatabase<CCountryLeaderDatabase>::[1] |
| 0x140A46630 | TGameItemDatabase<CIdeologyGroupDatabase>::[1] func_names 名 TGameItemDatabase<CIdeologyGroupDatabase>::[1] |
| 0x140A5F420 | CMap::[10] vtable 槽 CMap::[10]（func_names RTTI 名） |
| 0x140AD7750 | TGameItemDatabase<CTimedActivityDatabase>::[1] func_names 名 TGameItemDatabase<CTimedActivityDatabase>::[1] |
| 0x14015E220 | TGameItemDatabase<NRaids::CRaidDatabase>::[1] func_names 名 TGameItemDatabase<NRaids::CRaidDatabase>::[1] |
| 0x14033FAB0 | CEffectEntry<CRandomOwnedControlledStateEffect>::[1] func_names 名 CEffectEntry<CRandomOwnedControlledStateEffect>::[1] |
| 0x140A8C490 | TGameItemDatabase<CPowerBalanceDatabase>::[1] func_names 名 TGameItemDatabase<CPowerBalanceDatabase>::[1] |
| 0x14033D130 | CEffectEntry<CCreateImportEffect>::[1] func_names 名 CEffectEntry<CCreateImportEffect>::[1] |
| 0x14033D2E0 | CEffectEntry<CCreateRailwayGunEffect>::[1] func_names 名 CEffectEntry<CCreateRailwayGunEffect>::[1] |
| 0x1403E7D60 | CTriggerEntry<CIsOperationTypeTrigger>::[1] func_names 名 CTriggerEntry<CIsOperationTypeTrigger>::[1] |
| 0x1404452E0 | CTriggerEntry<COperativeLeaderOperationTrigger>::[1] func_names 名 CTriggerEntry<COperativeLeaderOperationTrigger>::[1] |
| 0x14064CDF0 | CAIFocus::[0] vtable 槽 CAIFocus::[0]（func_names RTTI 名） |
| 0x140633F00 | TGameItemDatabase<CAIAttitudeDatabase>::[1] func_names 名 TGameItemDatabase<CAIAttitudeDatabase>::[1] |
| 0x140ACBC10 | TGameItemDatabase<CTechnologyDatabase>::[1] func_names 名 TGameItemDatabase<CTechnologyDatabase>::[1] |
| 0x140AE4BB0 | TGameItemDatabase<CUnitLeaderDatabase>::[1] func_names 名 TGameItemDatabase<CUnitLeaderDatabase>::[1] |
| 0x1409C0560 | TGameItemDatabase<CNameGroupDatabase>::[1] func_names 名 TGameItemDatabase<CNameGroupDatabase>::[1] |
| 0x140A35920 | TGameItemDatabase<CGameRulesDatabase>::[1] func_names 名 TGameItemDatabase<CGameRulesDatabase>::[1] |
| 0x140AE4530 | （无名） 体设 CUnitLeaderSkill::vftable（RTTI 名） |
| 0x14067CB50 | TGameItemDatabase<CBookmarkDatabase>::[1] func_names 名 TGameItemDatabase<CBookmarkDatabase>::[1] |
| 0x140725590 | TGameItemDatabase<CDecisionDatabase>::[1] func_names 名 TGameItemDatabase<CDecisionDatabase>::[1] |
| 0x140A465B0 | TGameItemDatabase<CIdeologyDatabase>::[1] func_names 名 TGameItemDatabase<CIdeologyDatabase>::[1] |
| 0x140A75F20 | TGameItemDatabase<COnActionDataBase>::[1] func_names 名 TGameItemDatabase<COnActionDataBase>::[1] |
| 0x140A86A50 | TGameItemDatabase<CPortraitDatabase>::[1] func_names 名 TGameItemDatabase<CPortraitDatabase>::[1] |
| 0x140ADF130 | TGameItemDatabase<CTrainGfxDatabase>::[1] func_names 名 TGameItemDatabase<CTrainGfxDatabase>::[1] |
| 0x14033F8A0 | CEffectEntry<CRandomNeighborStateEffect>::[1] func_names 名 CEffectEntry<CRandomNeighborStateEffect>::[1] |
| 0x1403E3C60 | CTriggerEntry<CCanResearchTrigger>::[1] func_names 名 CTriggerEntry<CCanResearchTrigger>::[1] |
| 0x1403E4950 | CTriggerEntry<CDivisionsInStateTrigger>::[1] func_names 名 CTriggerEntry<CDivisionsInStateTrigger>::[1] |
| 0x14064CD70 | TGameItemDatabase<CAIFocusDatabase>::[1] func_names 名 TGameItemDatabase<CAIFocusDatabase>::[1] |
| 0x140A3A2E0 | TGameItemDatabase<CWarGoalDatabase>::[1] func_names 名 TGameItemDatabase<CWarGoalDatabase>::[1] |
| 0x14014B220 | （无名） 体设 CStrategicLocationTemplate::vftable（RTTI 名） |
| 0x14015D6A0 | TGameItemDatabase<NFactions::CFactionMemberUpgradeGroupDatabase>::[1] func_names 名 TGameItemDatabase<NFactions::CFactionMemberUpgradeGroupDatabase>::[1] |
| 0x140626320 | TGameItemDatabase<CAIAreaDatabase>::[1] func_names 名 TGameItemDatabase<CAIAreaDatabase>::[1] |
| 0x140A67DA0 | TGameItemDatabase<CMessageHandler>::[1] func_names 名 TGameItemDatabase<CMessageHandler>::[1] |
| 0x1422AA5F0 | CSimpleListbox<CStandardlistboxItem>::[21] func_names 名 CSimpleListbox<CStandardlistboxItem>::[21] |
| 0x1424EE050 | （无名） 体设 CMemoryFile::vftable（RTTI 名） |
| 0x140617CC0 | TGameItemDatabase<CAcesDatabase>::[1] func_names 名 TGameItemDatabase<CAcesDatabase>::[1] |
| 0x14151B610 | CForceGovernmentAction::Clone func_names 名 CForceGovernmentAction::Clone |
| 0x1403E6BC0 | CTriggerEntry<CHasTechTrigger>::[1] func_names 名 CTriggerEntry<CHasTechTrigger>::[1] |
| 0x1403E9520 | CTriggerEntry<CStockpileRatioTrigger>::[1] func_names 名 CTriggerEntry<CStockpileRatioTrigger>::[1] |
| 0x1404435F0 | CIsLeadingArmy::Evaluate func_names 名 CIsLeadingArmy::Evaluate |
| 0x1414D4E30 | CPendingTransportUnit::[5] vtable 槽 CPendingTransportUnit::[5]（func_names RTTI 名） |
| 0x14033C260 | CEffectEntry<CAddResourceEffect>::[1] func_names 名 CEffectEntry<CAddResourceEffect>::[1] |
| 0x140443680 | CIsLeadingArmyGroup::Evaluate func_names 名 CIsLeadingArmyGroup::Evaluate |
| 0x1404A7610 | CNumNukesBeingDropped::GetValue func_names 名 CNumNukesBeingDropped::GetValue |
| 0x1404A7680 | CNumNukesLeftToDrop::GetValue func_names 名 CNumNukesLeftToDrop::GetValue |
| 0x141117E50 | CCancelForeignManpowerAction::GetAiAcceptance func_names 名 CCancelForeignManpowerAction::GetAiAcceptance |
| 0x1423AA110 | （无名） 体设 PdxSpeechToTextState::vftable（RTTI 名） |
| 0x1402E4990 | CEffectEntry<CSetLeaderNamePortraitOrDescription<$00>>::[1] func_names 名 CEffectEntry<CSetLeaderNamePortraitOrDescription<$00>>::[1] |
| 0x1406B0E20 | TGameItemDatabase<CCharacterAdvisorGenerationDatabase>::[1] func_names 名 TGameItemDatabase<CCharacterAdvisorGenerationDatabase>::[1] |
| 0x14015DAA0 | TGameItemDatabase<NDoctrines::CGrandDoctrineDatabase>::[1] func_names 名 TGameItemDatabase<NDoctrines::CGrandDoctrineDatabase>::[1] |
| 0x140303940 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1403425E0 | CEffectEntry<CTransferShip>::[1] func_names 名 CEffectEntry<CTransferShip>::[1] |
| 0x1422ABEE0 | CSimpleListbox<CStandardlistboxItem>::[14] func_names 名 CSimpleListbox<CStandardlistboxItem>::[14] |
| 0x14033F590 | CEffectEntry<CRandomCoreStateEffect>::[1] func_names 名 CEffectEntry<CRandomCoreStateEffect>::[1] |
| 0x14015D2A0 | TGameItemDatabase<CAiTaskforceTemplateDatabase>::[1] func_names 名 TGameItemDatabase<CAiTaskforceTemplateDatabase>::[1] |
| 0x14033D230 | CEffectEntry<CCreateOperativeLeaderEffect>::[1] func_names 名 CEffectEntry<CCreateOperativeLeaderEffect>::[1] |
| 0x140340900 | CEffectEntry<CRetireCharacterEffect>::[1] func_names 名 CEffectEntry<CRetireCharacterEffect>::[1] |
| 0x14015E2A0 | TGameItemDatabase<CResistanceActivityDatabase>::[1] func_names 名 TGameItemDatabase<CResistanceActivityDatabase>::[1] |
| 0x1403E67C0 | CTriggerEntry<CHasResourcesInCollectionTrigger>::[1] func_names 名 CTriggerEntry<CHasResourcesInCollectionTrigger>::[1] |
| 0x140A551A0 | TGameItemDatabase<CInsigniaGraphicsDatabase>::[1] func_names 名 TGameItemDatabase<CInsigniaGraphicsDatabase>::[1] |
| 0x14101CBF0 | CSubUnitDefinitionAssociatedModifiers::MergeAdjustersWith func_names 名 CSubUnitDefinitionAssociatedModifiers::MergeAdjustersWith |
| 0x14068ECA0 | （无名） 体设 SProfileData::vftable（RTTI 名） |
| 0x14030BDE0 | CEffectEntry<CRemoveStateResistanceComplianceModifierEffect>::[1] func_names 名 CEffectEntry<CRemoveStateResistanceComplianceModifierEffect>::[1] |
| 0x140AA2760 | TGameItemDatabase<CCountryScorerDatabase>::[1] func_names 名 TGameItemDatabase<CCountryScorerDatabase>::[1] |
| 0x140DE75A0 | （无名） 体设 CSetGameUniqueId::vftable（RTTI 名） |
| 0x14033FC40 | CEffectEntry<CRandomStateEffect>::[1] func_names 名 CEffectEntry<CRandomStateEffect>::[1] |
| 0x14195A900 | CQuietIntelNetwork::GetProvincesInRangeOfState? func_names 名 CQuietIntelNetwork::GetProvincesInRangeOfState? |
| 0x141F60760 | （无名） 体设 CCreateAirGroupOption::vftable（RTTI 名） |
| 0x14015DEA0 | TGameItemDatabase<COperationsDatabase>::[1] func_names 名 TGameItemDatabase<COperationsDatabase>::[1] |
| 0x140442DB0 | CIsExileLeaderFrom::Evaluate func_names 名 CIsExileLeaderFrom::Evaluate |
| 0x140645E70 | TGameItemDatabase<CAIStrategyDatabase>::[1] func_names 名 TGameItemDatabase<CAIStrategyDatabase>::[1] |
| 0x140E88100 | CRailwayGun::[0] vtable 槽 CRailwayGun::[0]（func_names RTTI 名） |
| 0x14039BBA0 | CRandomScopeInArray::GetDescWrapper func_names 名 CRandomScopeInArray::GetDescWrapper |
| 0x1423252C0 | CTernary<鈥�>::[0] func_names 名 CTernary<鈥�>::[0] |
| 0x1412B2AB0 | CLandCombatant::[24] vtable 槽 CLandCombatant::[24]（func_names RTTI 名） |
| 0x1413A3340 | CTriggerEntry<CIfTrigger>::[1] func_names 名 CTriggerEntry<CIfTrigger>::[1] |
| 0x140F02C80 | H::VCCountryTag::PEBV?$CPdxArray::NTheatreManager::YAXW4EReason鈥�::[1] func_names 名 H::VCCountryTag::PEBV?$CPdxArray::NTheatreManager::YAXW4EReason鈥�::[1] |
| 0x140F02CD0 | H::VCCountryTag::PEBV?$CPdxArray::NTheatreManager::YAXW4EReason鈥�::[1] func_names 名 H::VCCountryTag::PEBV?$CPdxArray::NTheatreManager::YAXW4EReason鈥�::[1] |
| 0x140F02D70 | H::PEBVCProvince::V?$CPdxArray::PEAVCOrderInstance::U?$pair::YA鈥�::[1] func_names 名 H::PEBVCProvince::V?$CPdxArray::PEAVCOrderInstance::U?$pair::YA鈥�::[1] |
| 0x140F23120 | $0A::AEBV?$CProvinceWeatherUpdateThreaded::YAXHHW4EJobType::sta鈥�::[1] func_names 名 $0A::AEBV?$CProvinceWeatherUpdateThreaded::YAXHHW4EJobType::sta鈥�::[1] |
| 0x140F2FF50 | SAXAEAUSBufferedOperations::CCountryIntelligenceAgencyView::??C鈥�::[1] func_names 名 SAXAEAUSBufferedOperations::CCountryIntelligenceAgencyView::??C鈥�::[1] |
| 0x141393050 | CEffectEntry<CIfEffect>::[1] func_names 名 CEffectEntry<CIfEffect>::[1] |
| 0x141A4B150 | AEBVCCountryTag::8::AEBAXAEAVCFaction::NFactions::NAi::CFaction鈥�::[1] func_names 名 AEBVCCountryTag::8::AEBAXAEAVCFaction::NFactions::NAi::CFaction鈥�::[1] |
| 0x14039D850 | CAlliedCountryEffectBase<CSingleCountryTargetEffect>::[31] func_names 名 CAlliedCountryEffectBase<CSingleCountryTargetEffect>::[31] |
| 0x14101CC20 | CSubUnitDefinitionAssociatedModifiers::MergeModifiersWith func_names 名 CSubUnitDefinitionAssociatedModifiers::MergeModifiersWith |
| 0x1422AC250 | CSimpleListbox<CStandardlistboxItem>::[32] func_names 名 CSimpleListbox<CStandardlistboxItem>::[32] |
| 0x1402AD8D0 | TGameItemDatabase<CTestDatabase>::[1] func_names 名 TGameItemDatabase<CTestDatabase>::[1] |
| 0x1402E4FA0 | CEffectEntry<CAddUnitLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CAddUnitLeaderTraitEffect>::[1] |
| 0x1410146B0 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x142325240 | CTernary<鈥�>::[0] func_names 名 CTernary<鈥�>::[0] |
| 0x1423753E0 | CTernary<PEAVCPositionType::U?$STernaryTrait::EAVCPositionType*>::[0] func_names 名 CTernary<PEAVCPositionType::U?$STernaryTrait::EAVCPositionType*>::[0] |
| 0x141D11120 | CHistoryEntryItemBase::[14] vtable 槽 CHistoryEntryItemBase::[14]（func_names RTTI 名） |
| 0x1423DD600 | CSteamCloudStorageContext::[4] vtable 槽 CSteamCloudStorageContext::[4]（func_names RTTI 名） |
| 0x140340D00 | CEffectEntry<CSetAutonomyEffect>::[1] func_names 名 CEffectEntry<CSetAutonomyEffect>::[1] |
| 0x140ABA160 | CScriptedWindowTemplate::SAIEffectInfo::Reader func_names 名 CScriptedWindowTemplate::SAIEffectInfo::Reader |
| 0x14033CDB0 | CEffectEntry<CClearRuleEffect>::[1] func_names 名 CEffectEntry<CClearRuleEffect>::[1] |
| 0x14049B250 | CEffectEntry<CAddDesignTemplateBonusEffect>::[1] func_names 名 CEffectEntry<CAddDesignTemplateBonusEffect>::[1] |
| 0x1402F9D70 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1423B9A70 | SSDLAudioContext::[0] vtable 槽 SSDLAudioContext::[0]（func_names RTTI 名） |
| 0x140F71A50 | CShipRefitProductionLine::[0] vtable 槽 CShipRefitProductionLine::[0]（func_names RTTI 名） |
| 0x14043F010 | CTriggerEntry<NCareerProfile::CCheckPlaythroughValue>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckPlaythroughValue>::[1] |
| 0x140492DA0 | CEffectEntry<NProject::CEveryActiveScientistEffect>::[1] func_names 名 CEffectEntry<NProject::CEveryActiveScientistEffect>::[1] |
| 0x141519130 | （无名） 体设 CPeaceAction::vftable（RTTI 名） |
| 0x14151B800 | CTakeStateAction::Clone func_names 名 CTakeStateAction::Clone |
| 0x14015BFF0 | CDatabaseReloader<CAIEquipmentRoleDatabase>::[0] func_names 名 CDatabaseReloader<CAIEquipmentRoleDatabase>::[0] |
| 0x14033C110 | CEffectEntry<CAddPopularityEffect>::[1] func_names 名 CEffectEntry<CAddPopularityEffect>::[1] |
| 0x1419D7CC0 | CDebugMapModeConfig::CFloatToHsv::[0] vtable 槽 CDebugMapModeConfig::CFloatToHsv::[0]（func_names RTTI 名） |
| 0x141AA1980 | CDockingRightsAction::[26] vtable 槽 CDockingRightsAction::[26]（func_names RTTI 名） |
| 0x14205C0F0 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[3] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[3] |
| 0x14225A3A0 | CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[0] func_names 名 CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[0] |
| 0x1402E48B0 | CEffectEntry<CSetCountryLeaderNamePortraitOrDescription<$01>>::[1] func_names 名 CEffectEntry<CSetCountryLeaderNamePortraitOrDescription<$01>>::[1] |
| 0x1402E4920 | CEffectEntry<CSetCountryLeaderNamePortraitOrDescription<$0A>>::[1] func_names 名 CEffectEntry<CSetCountryLeaderNamePortraitOrDescription<$0A>>::[1] |
| 0x1417AD170 | CStandardInterface::Reload func_names 名 CStandardInterface::Reload |
| 0x1402E5100 | CEffectEntry<CGainXpEffect>::[1] func_names 名 CEffectEntry<CGainXpEffect>::[1] |
| 0x1404AC090 | CSetFactionUpgrade::Execute func_names 名 CSetFactionUpgrade::Execute |
| 0x1403A44B0 | CRandomizeVariableEffect<CVariableResolver>::[5] func_names 名 CRandomizeVariableEffect<CVariableResolver>::[5] |
| 0x14045D010 | CEffectEntry<CAddHistoryEntryEffect>::[1] func_names 名 CEffectEntry<CAddHistoryEntryEffect>::[1] |
| 0x141EB1700 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x14225C4F0 | CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[2] func_names 名 CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[2] |
| 0x141DF42A0 | CMapModeMilitaryDeploymentToOrder::HandleVariousMapClicks? func_names 名 CMapModeMilitaryDeploymentToOrder::HandleVariousMapClicks? |
| 0x1402E55D0 | CEffectEntry<CSwapCountryLeaderTraitsEffect>::[1] func_names 名 CEffectEntry<CSwapCountryLeaderTraitsEffect>::[1] |
| 0x141EC7230 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x1403039C0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14033FA30 | CEffectEntry<CRandomOtherCountryEffect>::[1] func_names 名 CEffectEntry<CRandomOtherCountryEffect>::[1] |
| 0x140FC6450 | XAEBUSIntelNetworkNodeDesc::Z::Z::01::SA?AV3::COperativeMission鈥�::[3] func_names 名 XAEBUSIntelNetworkNodeDesc::Z::Z::01::SA?AV3::COperativeMission鈥�::[3] |
| 0x141EB1770 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x14033B200 | CEffectEntry<CAIMessageEffect>::[1] func_names 名 CEffectEntry<CAIMessageEffect>::[1] |
| 0x1403E3380 | CTriggerEntry<CAmountTakenIdeasTrigger>::[1] func_names 名 CTriggerEntry<CAmountTakenIdeasTrigger>::[1] |
| 0x14043F3A0 | CTriggerEntry<NCareerProfile::CSetPlaythroughVariableTrigger>::[1] func_names 名 CTriggerEntry<NCareerProfile::CSetPlaythroughVariableTrigger>::[1] |
| 0x141137D10 | CTransferSpyMasterAction::CanExecute func_names 名 CTransferSpyMasterAction::CanExecute |
| 0x141EC72A0 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x14033BB30 | CEffectEntry<CAddDecryptionEffect>::[1] func_names 名 CEffectEntry<CAddDecryptionEffect>::[1] |
| 0x140AE4B30 | SParentKeyReader<CUnitLeaderTrait::SParentKey>::[0] func_names 名 SParentKeyReader<CUnitLeaderTrait::SParentKey>::[0] |
| 0x14202B8A0 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x14047C820 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x140CB4D60 | CConvoyClient::[8] vtable 槽 CConvoyClient::[8]（func_names RTTI 名） |
| 0x140E8C7E0 | CRailwayGun::[4] vtable 槽 CRailwayGun::[4]（func_names RTTI 名） |
| 0x141EA5B90 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x14045D340 | CEffectEntry<CRandomStateArmyEffect>::[1] func_names 名 CEffectEntry<CRandomStateArmyEffect>::[1] |
| 0x14206A500 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[3] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[3] |
| 0x140D17F70 | （无名） 体设 CWarScoreBreakdown::vftable（RTTI 名） |
| 0x141EC71C0 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x1403E5590 | CTriggerEntry<CHasCompletedCustomAchievementTrigger>::[1] func_names 名 CTriggerEntry<CHasCompletedCustomAchievementTrigger>::[1] |
| 0x14043F1E0 | CTriggerEntry<NCareerProfile::CCheckValue>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckValue>::[1] |
| 0x141832900 | CEmptyEntryListBase<COperativesBottomBarEmptySlotItem>::[0] func_names 名 CEmptyEntryListBase<COperativesBottomBarEmptySlotItem>::[0] |
| 0x1403E3510 | CTriggerEntry<CAnyCountryWithOriginalTagTrigger>::[1] func_names 名 CTriggerEntry<CAnyCountryWithOriginalTagTrigger>::[1] |
| 0x14047C500 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140638C20 | （无名） 体设 CRuleDefinition::vftable（RTTI 名） |
| 0x140ACB710 | （无名） 体设 CFolderPosition::vftable（RTTI 名） |
| 0x141909E20 | CEmptyEntryListBase<CResistanceComplianceMapIconModifierEntry>::[0] func_names 名 CEmptyEntryListBase<CResistanceComplianceMapIconModifierEntry>::[0] |
| 0x1423B9720 | （无名） 体设 CAudioCategory::vftable（RTTI 名） |
| 0x140FC6440 | XAEBUSIntelNetworkNodeDesc::Z::Z::01::SA?AV3::COperativeMission鈥�::[3] func_names 名 XAEBUSIntelNetworkNodeDesc::Z::Z::01::SA?AV3::COperativeMission鈥�::[3] |
| 0x14112E210 | CRequestAccessToLicenseProductionAction::[23] vtable 槽 CRequestAccessToLicenseProductionAction::[23]（func_names RTTI 名） |
| 0x14177C9B0 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x1410FBD60 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14177C940 | CEmptyEntryListBase<NEquipmentDesigner::CEquipmentNameGroupItem>::[0] func_names 名 CEmptyEntryListBase<NEquipmentDesigner::CEquipmentNameGroupItem>::[0] |
| 0x14177CA90 | CEmptyEntryListBase<NEquipmentDesigner::CNicheIconListItem>::[0] func_names 名 CEmptyEntryListBase<NEquipmentDesigner::CNicheIconListItem>::[0] |
| 0x142026990 | CEmptyEntryListBase<NIndustrialOrganisation::CBonusTypeIconItem>::[0] func_names 名 CEmptyEntryListBase<NIndustrialOrganisation::CBonusTypeIconItem>::[0] |
| 0x14030B990 | CEffectEntry<CConstructBuildingInRandomProvinceEffect>::[1] func_names 名 CEffectEntry<CConstructBuildingInRandomProvinceEffect>::[1] |
| 0x14033D1B0 | CEffectEntry<CCreateIntelligenceAgencyEffect>::[1] func_names 名 CEffectEntry<CCreateIntelligenceAgencyEffect>::[1] |
| 0x14043F420 | CTriggerEntry<NCareerProfile::CSetVariableTrigger>::[1] func_names 名 CTriggerEntry<NCareerProfile::CSetVariableTrigger>::[1] |
| 0x1417B0920 | CInGameClock::Reload func_names 名 CInGameClock::Reload |
| 0x14151A150 | CLiberateCountryAction::GetActionLabel func_names 名 CLiberateCountryAction::GetActionLabel |
| 0x14175A8F0 | CEmptyEntryListBase<NDivisionDesigner::CNicheSelectionItem>::[0] func_names 名 CEmptyEntryListBase<NDivisionDesigner::CNicheSelectionItem>::[0] |
| 0x141832890 | CEmptyEntryListBase<COperativeBottomBarItem>::[0] func_names 名 CEmptyEntryListBase<COperativeBottomBarItem>::[0] |
| 0x140340240 | CEffectEntry<CRemoveDecisionOnCooldown>::[1] func_names 名 CEffectEntry<CRemoveDecisionOnCooldown>::[1] |
| 0x1409B84D0 | CDifficultySettingsDatabase::[1] vtable 槽 CDifficultySettingsDatabase::[1]（func_names RTTI 名） |
| 0x140D18FC0 | CSubjectRelation::[0] vtable 槽 CSubjectRelation::[0]（func_names RTTI 名） |
| 0x142089B10 | CTweakableEnumManipulator::[0] vtable 槽 CTweakableEnumManipulator::[0]（func_names RTTI 名） |
| 0x140195620 | CDatabaseReloader<CAIEquipmentRoleDatabase>::[2] func_names 名 CDatabaseReloader<CAIEquipmentRoleDatabase>::[2] |
| 0x140489250 | CTriggerEntry<CPowerBalanceWeeklyChangeTrigger>::[1] func_names 名 CTriggerEntry<CPowerBalanceWeeklyChangeTrigger>::[1] |
| 0x140492FA0 | CEffectEntry<NProject::CRandomScientistEffect>::[1] func_names 名 CEffectEntry<NProject::CRandomScientistEffect>::[1] |
| 0x140489150 | CTriggerEntry<CPowerBalanceDailyChangeTrigger>::[1] func_names 名 CTriggerEntry<CPowerBalanceDailyChangeTrigger>::[1] |
| 0x1402E4AB0 | CEffectEntry<CAddAttackSkillEffect>::[1] func_names 名 CEffectEntry<CAddAttackSkillEffect>::[1] |
| 0x14033EE20 | CEffectEntry<CLegacyCreateNavyLeaderEffect>::[1] func_names 名 CEffectEntry<CLegacyCreateNavyLeaderEffect>::[1] |
| 0x1404573F0 | CTriggerEntry<NIndustrialOrganisation::CHasPolicyActiveTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CHasPolicyActiveTrigger>::[1] |
| 0x140492F20 | CEffectEntry<NProject::CRandomActiveScientistEffect>::[1] func_names 名 CEffectEntry<NProject::CRandomActiveScientistEffect>::[1] |
| 0x14182AB20 | CEmptyEntryListBase<COperationOverviewOperativeEntry>::[0] func_names 名 CEmptyEntryListBase<COperationOverviewOperativeEntry>::[0] |
| 0x141745D40 | CEmptyEntryListBase<CProvinceStrategicLocationEntry>::[0] func_names 名 CEmptyEntryListBase<CProvinceStrategicLocationEntry>::[0] |
| 0x14051D620 | CTriggerEntry<CCollectionContainsTrigger>::[1] func_names 名 CTriggerEntry<CCollectionContainsTrigger>::[1] |
| 0x1413D4730 | CEmptyEntryListBase<CTechnologyTreeLineSegmentItem>::[0] func_names 名 CEmptyEntryListBase<CTechnologyTreeLineSegmentItem>::[0] |
| 0x14155C8B0 | CEmptyEntryListBase<COccupiedTerritoryCountryEntry>::[0] func_names 名 CEmptyEntryListBase<COccupiedTerritoryCountryEntry>::[0] |
| 0x141805290 | CEmptyEntryListBase<CNavyTheaterTaskForceItem>::[0] func_names 名 CEmptyEntryListBase<CNavyTheaterTaskForceItem>::[0] |
| 0x14182AB90 | CEmptyEntryListBase<COperationPhaseTitlesViewEntry>::[0] func_names 名 CEmptyEntryListBase<COperationPhaseTitlesViewEntry>::[0] |
| 0x140341540 | CEffectEntry<CSetKeyedOobEffect>::[1] func_names 名 CEffectEntry<CSetKeyedOobEffect>::[1] |
| 0x14177C7F0 | CEmptyEntryListBase<CDesignerEquipmentCreatorItem>::[0] func_names 名 CEmptyEntryListBase<CDesignerEquipmentCreatorItem>::[0] |
| 0x14177C8D0 | CEmptyEntryListBase<CDesignerEquipmentVariantItem>::[0] func_names 名 CEmptyEntryListBase<CDesignerEquipmentVariantItem>::[0] |
| 0x141DDAAD0 | CEmptyEntryListBase<CEquipmentModuleCategoryEntry>::[0] func_names 名 CEmptyEntryListBase<CEquipmentModuleCategoryEntry>::[0] |
| 0x1403D79A0 | CHasNonAggressionPactWith::Evaluate func_names 名 CHasNonAggressionPactWith::Evaluate |
| 0x1404891D0 | CTriggerEntry<CPowerBalanceValueTrigger>::[1] func_names 名 CTriggerEntry<CPowerBalanceValueTrigger>::[1] |
| 0x14182AC70 | CEmptyEntryListBase<COperationResourcesViewEntry>::[0] func_names 名 CEmptyEntryListBase<COperationResourcesViewEntry>::[0] |
| 0x1418C29A0 | CDecisionMapIconContainer::[2] vtable 槽 CDecisionMapIconContainer::[2]（func_names RTTI 名） |
| 0x1422ABC60 | CSimpleListbox<CStandardlistboxItem>::[78] func_names 名 CSimpleListbox<CStandardlistboxItem>::[78] |
| 0x1422ABDC0 | CSimpleListbox<CStandardlistboxItem>::[77] func_names 名 CSimpleListbox<CStandardlistboxItem>::[77] |
| 0x14033AA20 | CEffectEntry<CClearArrayEffectImp<$00>>::[1] func_names 名 CEffectEntry<CClearArrayEffectImp<$00>>::[1] |
| 0x1403DB6F0 | CIsJustifyingWargoalAgainst::Evaluate func_names 名 CIsJustifyingWargoalAgainst::Evaluate |
| 0x140483A50 | CEffectEntry<CRemoveAllPowerBalanceModifiersEffect>::[1] func_names 名 CEffectEntry<CRemoveAllPowerBalanceModifiersEffect>::[1] |
| 0x140F58C30 | VCOperativeLeader::V?$CConstRef::AEBV?$CPdxArray::AXAEBVCCountr鈥�::[0] func_names 名 VCOperativeLeader::V?$CConstRef::AEBV?$CPdxArray::AXAEBVCCountr鈥�::[0] |
| 0x14151E400 | CTakeStateAction::GetDescription func_names 名 CTakeStateAction::GetDescription |
| 0x141EA5B20 | CEmptyEntryListBase<CIntelLedgerTechnologyEntry>::[0] func_names 名 CEmptyEntryListBase<CIntelLedgerTechnologyEntry>::[0] |
| 0x140457460 | CTriggerEntry<NIndustrialOrganisation::CHasPolicyTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CHasPolicyTrigger>::[1] |
| 0x140529350 | CEffectEntry<NDoctrines::CAddMasteryEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CAddMasteryEffect>::[1] |
| 0x14177C860 | CEmptyEntryListBase<CDesignerEquipmentRoleItem>::[0] func_names 名 CEmptyEntryListBase<CDesignerEquipmentRoleItem>::[0] |
| 0x141C2F210 | CEmptyEntryListBase<CDesignFolderListItem>::[0] func_names 名 CEmptyEntryListBase<CDesignFolderListItem>::[0] |
| 0x141745DB0 | CEmptyEntryListBase<CStateDynamicModifierItem>::[0] func_names 名 CEmptyEntryListBase<CStateDynamicModifierItem>::[0] |
| 0x14182AC00 | CEmptyEntryListBase<COperationPhasesViewEntry>::[0] func_names 名 CEmptyEntryListBase<COperationPhasesViewEntry>::[0] |
| 0x141905070 | CEmptyEntryListBase<CNegotiatorFlagEntry>::[0] func_names 名 CEmptyEntryListBase<CNegotiatorFlagEntry>::[0] |
| 0x141EA5A40 | CEmptyEntryListBase<CIntelLedgerDoctrineEntry>::[0] func_names 名 CEmptyEntryListBase<CIntelLedgerDoctrineEntry>::[0] |
| 0x1422D5880 | CTextSprite::[12] vtable 槽 CTextSprite::[12]（func_names RTTI 名） |
| 0x140341880 | CEffectEntry<CSetOobEffect>::[1] func_names 名 CEffectEntry<CSetOobEffect>::[1] |
| 0x1414E9140 | （无名） 体设 CCountryRaidStatus::vftable（RTTI 名） |
| 0x14175A880 | CEmptyEntryListBase<CEquipmentModelListItem>::[0] func_names 名 CEmptyEntryListBase<CEquipmentModelListItem>::[0] |
| 0x1417F3EF0 | CEmptyEntryListBase<CShipOverviewHeaderItem>::[0] func_names 名 CEmptyEntryListBase<CShipOverviewHeaderItem>::[0] |
| 0x141DAFEF0 | CEmptyEntryListBase<CProductionNameListItem>::[0] func_names 名 CEmptyEntryListBase<CProductionNameListItem>::[0] |
| 0x140340710 | CEffectEntry<CRemoveTargetedDecisionEffect>::[1] func_names 名 CEffectEntry<CRemoveTargetedDecisionEffect>::[1] |
| 0x140492A80 | CEffectEntry<NProject::CAddBreakthroughProgress>::[1] func_names 名 CEffectEntry<NProject::CAddBreakthroughProgress>::[1] |
| 0x1404AA520 | CEffectEntry<CEveryFactionMember>::[1] func_names 名 CEffectEntry<CEveryFactionMember>::[1] |
| 0x14047C8A0 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x140A47900 | CIdeologyDatabase::[6] vtable 槽 CIdeologyDatabase::[6]（func_names RTTI 名） |
| 0x140A47970 | TReloadableGameItemDatabaseSpecific<鈥�>::[6] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[6] |
| 0x14177CA20 | CEmptyEntryListBase<CHistoricalDesignItem>::[0] func_names 名 CEmptyEntryListBase<CHistoricalDesignItem>::[0] |
| 0x1417F3E10 | CEmptyEntryListBase<CCountryOrFactionItem>::[0] func_names 名 CEmptyEntryListBase<CCountryOrFactionItem>::[0] |
| 0x1418AA7F0 | CEmptyEntryListBase<CWarOverViewWarButton>::[0] func_names 名 CEmptyEntryListBase<CWarOverViewWarButton>::[0] |
| 0x1418FA8E0 | CEmptyEntryListBase<CNavalMissionUnitItem>::[0] func_names 名 CEmptyEntryListBase<CNavalMissionUnitItem>::[0] |
| 0x141DDAB40 | CEmptyEntryListBase<CEquipmentModuleEntry>::[0] func_names 名 CEmptyEntryListBase<CEquipmentModuleEntry>::[0] |
| 0x141DF3BE0 | CMapModeMilitaryDeploymentToOrder::HandleVariousMapClicks? func_names 名 CMapModeMilitaryDeploymentToOrder::HandleVariousMapClicks? |
| 0x141EA5AB0 | CEmptyEntryListBase<CIntelLedgerIdeaEntry>::[0] func_names 名 CEmptyEntryListBase<CIntelLedgerIdeaEntry>::[0] |
| 0x141ED9AE0 | CEmptyEntryListBase<CNationalitiesBoxItem>::[0] func_names 名 CEmptyEntryListBase<CNationalitiesBoxItem>::[0] |
| 0x1417A56B0 | CEmptyEntryListBase<CFleetsBottomBarItem>::[0] func_names 名 CEmptyEntryListBase<CFleetsBottomBarItem>::[0] |
| 0x1402F9E70 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140DDD910 | CInGameIdler::[2] vtable 槽 CInGameIdler::[2]（func_names RTTI 名） |
| 0x140F28D80 | CEmptyEntryListBase<COperationViewEntry>::[0] func_names 名 CEmptyEntryListBase<COperationViewEntry>::[0] |
| 0x1417F3E80 | CEmptyEntryListBase<CShipArchetypeItem>::[0] func_names 名 CEmptyEntryListBase<CShipArchetypeItem>::[0] |
| 0x141E56F90 | CEmptyEntryListBase<CBiddingsPopupItem>::[0] func_names 名 CEmptyEntryListBase<CBiddingsPopupItem>::[0] |
| 0x14033F9B0 | CEffectEntry<CRandomOperativeLeaderEffect>::[1] func_names 名 CEffectEntry<CRandomOperativeLeaderEffect>::[1] |
| 0x14177C780 | CEmptyEntryListBase<CDesignFolderItem>::[0] func_names 名 CEmptyEntryListBase<CDesignFolderItem>::[0] |
| 0x1403E40E0 | CTriggerEntry<CCompareIntelWithTrigger>::[1] func_names 名 CTriggerEntry<CCompareIntelWithTrigger>::[1] |
| 0x1403E7210 | CTriggerEntry<CIntelLevelOver>::[1] func_names 名 CTriggerEntry<CIntelLevelOver>::[1] |
| 0x14047C600 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1418F4970 | CEmptyEntryListBase<CTinyUnitCounter>::[0] func_names 名 CEmptyEntryListBase<CTinyUnitCounter>::[0] |
| 0x14203E080 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[3] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[3] |
| 0x14033ACD0 | CEffectEntry<CRandomizeVariableEffect<CVariableResolver>>::[1] func_names 名 CEffectEntry<CRandomizeVariableEffect<CVariableResolver>>::[1] |
| 0x140483AC0 | CEffectEntry<CRemovePowerBalanceEffect>::[1] func_names 名 CEffectEntry<CRemovePowerBalanceEffect>::[1] |
| 0x14151BDA0 | CTakeNavyPeaceAction::IsSameAction func_names 名 CTakeNavyPeaceAction::IsSameAction |
| 0x1418AA780 | CEmptyEntryListBase<CWarFactionItem>::[0] func_names 名 CEmptyEntryListBase<CWarFactionItem>::[0] |
| 0x1402F9800 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402F9DF0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140488F90 | CTriggerEntry<CHasPowerBalanceTrigger>::[1] func_names 名 CTriggerEntry<CHasPowerBalanceTrigger>::[1] |
| 0x140D01E40 | （无名） 体设 CDynamicIntelSourcePool::vftable（RTTI 名） |
| 0x1417F3F60 | CEmptyEntryListBase<CSunkShipEntry>::[0] func_names 名 CEmptyEntryListBase<CSunkShipEntry>::[0] |
| 0x1419050E0 | CEmptyEntryListBase<CResourceEntry>::[0] func_names 名 CEmptyEntryListBase<CResourceEntry>::[0] |
| 0x1417E3280 | CEmptyEntryListBase<CSunkShipIcon>::[0] func_names 名 CEmptyEntryListBase<CSunkShipIcon>::[0] |
| 0x1417F3DA0 | CEmptyEntryListBase<CAccidentItem>::[0] func_names 名 CEmptyEntryListBase<CAccidentItem>::[0] |
| 0x1417E3210 | CEmptyEntryListBase<CFexShipIcon>::[0] func_names 名 CEmptyEntryListBase<CFexShipIcon>::[0] |
| 0x1418AA710 | CEmptyEntryListBase<CWarAllyItem>::[0] func_names 名 CEmptyEntryListBase<CWarAllyItem>::[0] |
| 0x1424EC150 | collate<char,std>::[5] func_names 名 collate<char,std>::[5] |
| 0x1402F9880 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14033A9A0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14033F480 | CEffectEntry<CRandomArmyLeaderEffect>::[1] func_names 名 CEffectEntry<CRandomArmyLeaderEffect>::[1] |
| 0x14033FD50 | CEffectEntry<CRandomUnitLeaderEffect>::[1] func_names 名 CEffectEntry<CRandomUnitLeaderEffect>::[1] |
| 0x1403E2AB0 | CTriggerEntry<CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>>::[1] func_names 名 CTriggerEntry<CHasAvailableOrAllowedIdeaWithTraitsTrigger<$00>>::[1] |
| 0x1404B35B0 | CMultipleCompareTrigger<CCollectionSizeTrigger>::[0] func_names 名 CMultipleCompareTrigger<CCollectionSizeTrigger>::[0] |
| 0x1404B36A0 | CFactionGoalFulfillment::[0] vtable 槽 CFactionGoalFulfillment::[0]（func_names RTTI 名） |
| 0x140BEA910 | CArmyGroup::[0] vtable 槽 CArmyGroup::[0]（func_names RTTI 名） |
| 0x1401C5870 | 81d4e4719ddbe51da8dab0fd2fe5df54::.??::[1] func_names 名 81d4e4719ddbe51da8dab0fd2fe5df54::.??::[1] |
| 0x1402E4E70 | CEffectEntry<CAddTimedUnitLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CAddTimedUnitLeaderTraitEffect>::[1] |
| 0x14030B8B0 | CEffectEntry<CAddStaticProvinceModifierEffect>::[1] func_names 名 CEffectEntry<CAddStaticProvinceModifierEffect>::[1] |
| 0x1403E3E10 | CTriggerEntry<CCheckVariable>::[1] func_names 名 CTriggerEntry<CCheckVariable>::[1] |
| 0x14051D5A0 | CTriggerEntry<CAnyCollectionElementTrigger>::[1] func_names 名 CTriggerEntry<CAnyCollectionElementTrigger>::[1] |
| 0x1402FA360 | CEffectEntry<NIndustrialOrganisation::CTraitTooltipEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CTraitTooltipEffect>::[1] |
| 0x14033F820 | CEffectEntry<CRandomNeighborCountryEffect>::[1] func_names 名 CEffectEntry<CRandomNeighborCountryEffect>::[1] |
| 0x14155CEB0 | COccupiedTerritoryStateEntryWithoutResistance::[0] vtable 槽 COccupiedTerritoryStateEntryWithoutResistance::[0]（func_names RTTI 名） |
| 0x1402FA490 | CEffectEntry<NIndustrialOrganisation::CUnlockTraitEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CUnlockTraitEffect>::[1] |
| 0x14033B4D0 | CEffectEntry<CAddAIStrategyEffect>::[1] func_names 名 CEffectEntry<CAddAIStrategyEffect>::[1] |
| 0x140345EF0 | CReleaseNationEffect<$00>::[13] func_names 名 CReleaseNationEffect<$00>::[13] |
| 0x1404C70B0 | CEffectEntry<CEveryCollectionElementEffect>::[1] func_names 名 CEffectEntry<CEveryCollectionElementEffect>::[1] |
| 0x14033DD80 | CEffectEntry<CEveryCountryWithOriginalTag>::[1] func_names 名 CEffectEntry<CEveryCountryWithOriginalTag>::[1] |
| 0x1406ACFC0 | TGameItemDatabase<NCareerProfile::CProfileBackgroundDatabase>::[1] func_names 名 TGameItemDatabase<NCareerProfile::CProfileBackgroundDatabase>::[1] |
| 0x1402F4350 | CEffectEntry<CRandomCharacterEffect>::[1] func_names 名 CEffectEntry<CRandomCharacterEffect>::[1] |
| 0x14101FFE0 | CSubUnitDefinitionAssociatedModifiers::MergeAdjustersWith::lamb鈥� func_names 名 CSubUnitDefinitionAssociatedModifiers::MergeAdjustersWith::lamb鈥� |
| 0x1402E3060 | CEffectEntry<NCareerProfile::CStepMissiolinis>::[1] func_names 名 CEffectEntry<NCareerProfile::CStepMissiolinis>::[1] |
| 0x140345F40 | CReleaseNationEffect<$0A>::[13] func_names 名 CReleaseNationEffect<$0A>::[13] |
| 0x1403E2B30 | CTriggerEntry<CHasAvailableOrAllowedIdeaWithTraitsTrigger<$0A>>::[1] func_names 名 CTriggerEntry<CHasAvailableOrAllowedIdeaWithTraitsTrigger<$0A>>::[1] |
| 0x1406AD030 | TGameItemDatabase<NCareerProfile::CProfilePictureDatabase>::[1] func_names 名 TGameItemDatabase<NCareerProfile::CProfilePictureDatabase>::[1] |
| 0x140457220 | CTriggerEntry<NIndustrialOrganisation::CAnyIndustrialOrgTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CAnyIndustrialOrgTrigger>::[1] |
| 0x140E96F40 | CScriptedMapEntity::[8] vtable 槽 CScriptedMapEntity::[8]（func_names RTTI 名） |
| 0x14033D8A0 | CEffectEntry<CDeleteUnitEffect>::[1] func_names 名 CEffectEntry<CDeleteUnitEffect>::[1] |
| 0x14033F930 | CEffectEntry<CRandomOccupiedCountryEffect>::[1] func_names 名 CEffectEntry<CRandomOccupiedCountryEffect>::[1] |
| 0x140457310 | CTriggerEntry<NIndustrialOrganisation::CHasEquipmentTypeTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CHasEquipmentTypeTrigger>::[1] |
| 0x141236180 | CUnitNavalMoveAction::[24] vtable 槽 CUnitNavalMoveAction::[24]（func_names RTTI 名） |
| 0x14043F0A0 | CTriggerEntry<NCareerProfile::CCheckPoints>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckPoints>::[1] |
| 0x140456000 | CTriggerEntry<CAnyArmyLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAnyArmyLeaderTrigger>::[1] |
| 0x14033F720 | CEffectEntry<CRandomEnemyCountryEffect>::[1] func_names 名 CEffectEntry<CRandomEnemyCountryEffect>::[1] |
| 0x140442C20 | CIsCorpsCommander::Evaluate func_names 名 CIsCorpsCommander::Evaluate |
| 0x14151BD00 | CPeaceAction::IsSameAction func_names 名 CPeaceAction::IsSameAction |
| 0x1403E2950 | CTriggerEntry<CForEachScopesTriggerImp<$0A>>::[1] func_names 名 CTriggerEntry<CForEachScopesTriggerImp<$0A>>::[1] |
| 0x1406AFBB0 | TGameItemDatabase<NCareerProfile::CRibbonDatabase>::[1] func_names 名 TGameItemDatabase<NCareerProfile::CRibbonDatabase>::[1] |
| 0x140AA2820 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14033A7E0 | CEffectEntry<CAddRemoveDynamicModifierEffect<$0A>>::[1] func_names 名 CEffectEntry<CAddRemoveDynamicModifierEffect<$0A>>::[1] |
| 0x140340020 | CEffectEntry<CRemoveAdvisorRoleEffect>::[1] func_names 名 CEffectEntry<CRemoveAdvisorRoleEffect>::[1] |
| 0x1403E56B0 | CTriggerEntry<CHasCoreOccupationModifier>::[1] func_names 名 CTriggerEntry<CHasCoreOccupationModifier>::[1] |
| 0x1406AB380 | TGameItemDatabase<NCareerProfile::CMedalDatabase>::[1] func_names 名 TGameItemDatabase<NCareerProfile::CMedalDatabase>::[1] |
| 0x1404574D0 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x141799FA0 | CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[6] func_names 名 CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[6] |
| 0x14101FFF0 | CSubUnitDefinitionAssociatedModifiers::MergeModifiersWith::lamb鈥� func_names 名 CSubUnitDefinitionAssociatedModifiers::MergeModifiersWith::lamb鈥� |
| 0x14033F620 | CEffectEntry<CRandomCountryEffect>::[1] func_names 名 CEffectEntry<CRandomCountryEffect>::[1] |
| 0x140457380 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x1404A2140 | CTriggerEntry<NProject::CAllScientistsTrigger>::[1] func_names 名 CTriggerEntry<NProject::CAllScientistsTrigger>::[1] |
| 0x141798D60 | CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[1] func_names 名 CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[1] |
| 0x141799270 | CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[2] func_names 名 CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[2] |
| 0x141799660 | CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[5] func_names 名 CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[5] |
| 0x141799A60 | CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[4] func_names 名 CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[4] |
| 0x141799F60 | CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[3] func_names 名 CCheckBoxObserverGlue<NFactions::NUi::CFactionPingWindow>::[3] |
| 0x1422AB2F0 | CFixedMaxSizeListbox<CStandardlistboxItem>::[7] func_names 名 CFixedMaxSizeListbox<CStandardlistboxItem>::[7] |
| 0x1402F8D60 | CTriggerEntry<CHasAnyGeneralCapturedByTrigger>::[1] func_names 名 CTriggerEntry<CHasAnyGeneralCapturedByTrigger>::[1] |
| 0x1404A8A20 | CTriggerEntry<CAnyOtherCountryWithOriginalTagOfTrigger>::[1] func_names 名 CTriggerEntry<CAnyOtherCountryWithOriginalTagOfTrigger>::[1] |
| 0x140AC1D50 | TGameItemDatabase<CStrategicResourceDatabase>::[1] func_names 名 TGameItemDatabase<CStrategicResourceDatabase>::[1] |
| 0x140D19070 | CWarScoreBreakdown::[0] vtable 槽 CWarScoreBreakdown::[0]（func_names RTTI 名） |
| 0x14030B410 | CEffectEntry<CAddBuildingConstructionEffect>::[1] func_names 名 CEffectEntry<CAddBuildingConstructionEffect>::[1] |
| 0x14054CDB0 | CTriggerEntry<CAndTrigger>::[1] func_names 名 CTriggerEntry<CAndTrigger>::[1] |
| 0x14031FCE0 | CSelectTechTreeIconOrigin::Execute func_names 名 CSelectTechTreeIconOrigin::Execute |
| 0x1403E3000 | CTriggerEntry<CAllGuaranteedCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllGuaranteedCountryTrigger>::[1] |
| 0x1403E3600 | CTriggerEntry<CAnyGuaranteedCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyGuaranteedCountryTrigger>::[1] |
| 0x1404A40A0 | CEffectEntry<NRaids::CDamageRaidUnitEffect>::[1] func_names 名 CEffectEntry<NRaids::CDamageRaidUnitEffect>::[1] |
| 0x14033FCD0 | CEffectEntry<CRandomSubjectCountryEffect>::[1] func_names 名 CEffectEntry<CRandomSubjectCountryEffect>::[1] |
| 0x14043BA20 | CIntelLevelOver::ParseToken func_names 名 CIntelLevelOver::ParseToken |
| 0x14045D2C0 | CEffectEntry<CRandomArmyEffect>::[1] func_names 名 CEffectEntry<CRandomArmyEffect>::[1] |
| 0x14015E9D0 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14015EA40 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14015EAB0 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14015EB20 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14015EB90 | COperationPhasesDatabase::[1] vtable 槽 COperationPhasesDatabase::[1]（func_names RTTI 名） |
| 0x14015ECE0 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14015ED50 | TReloadableGameItemDatabaseSpecific<鈥�>::[1] func_names 名 TReloadableGameItemDatabaseSpecific<鈥�>::[1] |
| 0x14015FD70 | CMTTHDatabase::[1] vtable 槽 CMTTHDatabase::[1]（func_names RTTI 名） |
| 0x140527120 | CCheckExpression::[0] vtable 槽 CCheckExpression::[0]（func_names RTTI 名） |
| 0x1413C42A0 | TGameItemDatabase<CStateCategoryDatabase>::[1] func_names 名 TGameItemDatabase<CStateCategoryDatabase>::[1] |
| 0x14033A760 | CEffectEntry<CAddRemoveDynamicModifierEffect<$00>>::[1] func_names 名 CEffectEntry<CAddRemoveDynamicModifierEffect<$00>>::[1] |
| 0x14043C260 | CNumCompletedOperations::ParseToken func_names 名 CNumCompletedOperations::ParseToken |
| 0x1403E85A0 | CTriggerEntry<CNationalFocusProgressTrigger>::[1] func_names 名 CTriggerEntry<CNationalFocusProgressTrigger>::[1] |
| 0x1404577A0 | CTriggerEntry<NIndustrialOrganisation::CIsTraitAvailableTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CIsTraitAvailableTrigger>::[1] |
| 0x140467BA0 | CTriggerEntry<CAnyNeighborStateTrigger>::[1] func_names 名 CTriggerEntry<CAnyNeighborStateTrigger>::[1] |
| 0x140340E60 | CEffectEntry<CSetCanBeFiredToAdvisorRole>::[1] func_names 名 CEffectEntry<CSetCanBeFiredToAdvisorRole>::[1] |
| 0x140B6B150 | CErrorLogIndicator::Reload func_names 名 CErrorLogIndicator::Reload |
| 0x1422FCA70 | C2dPieChartTemplate<SPieVertex>::[1] func_names 名 C2dPieChartTemplate<SPieVertex>::[1] |
| 0x14033E5E0 | CEffectEntry<CGenerateCharacter>::[1] func_names 名 CEffectEntry<CGenerateCharacter>::[1] |
| 0x1404A76F0 | CNumNukesBeingDropped::GetDesc func_names 名 CNumNukesBeingDropped::GetDesc |
| 0x1409F1DC0 | TGameItemDatabase<CEquipmentDatabase>::[1] func_names 名 TGameItemDatabase<CEquipmentDatabase>::[1] |
| 0x140AE1AC0 | TGameItemDatabase<CUnitMedalDatabase>::[1] func_names 名 TGameItemDatabase<CUnitMedalDatabase>::[1] |
| 0x140342890 | CEffectEntry<CUnlockDecisionCategoryTooltipEffect>::[1] func_names 名 CEffectEntry<CUnlockDecisionCategoryTooltipEffect>::[1] |
| 0x140683400 | TGameItemDatabase<CBuildingDatabase>::[1] func_names 名 TGameItemDatabase<CBuildingDatabase>::[1] |
| 0x140467820 | CTriggerEntry<CAllCoreStateTrigger>::[1] func_names 名 CTriggerEntry<CAllCoreStateTrigger>::[1] |
| 0x140AC3040 | TGameItemDatabase<CSubUnitDatabase>::[1] func_names 名 TGameItemDatabase<CSubUnitDatabase>::[1] |
| 0x142004920 | CActiveContractsUiController::OpenCancelConfirmationPopup::lamb鈥� func_names 名 CActiveContractsUiController::OpenCancelConfirmationPopup::lamb鈥� |
| 0x140637E00 | TGameItemDatabase<CAIRoleDatabase>::[1] func_names 名 TGameItemDatabase<CAIRoleDatabase>::[1] |
| 0x1403E66D0 | CTriggerEntry<CHasRailwayConnectionTrigger>::[1] func_names 名 CTriggerEntry<CHasRailwayConnectionTrigger>::[1] |
| 0x140ABC2D0 | TGameItemDatabase<CStateDatabase>::[1] func_names 名 TGameItemDatabase<CStateDatabase>::[1] |
| 0x1402E51A0 | CEffectEntry<COperativeLeaderEventEffect>::[1] func_names 名 CEffectEntry<COperativeLeaderEventEffect>::[1] |
| 0x14043F320 | CTriggerEntry<NCareerProfile::CNumOfPointsTrigger>::[1] func_names 名 CTriggerEntry<NCareerProfile::CNumOfPointsTrigger>::[1] |
| 0x140A40870 | TGameItemDatabase<CIdeaDatabase>::[1] func_names 名 TGameItemDatabase<CIdeaDatabase>::[1] |
| 0x1402F4250 | CEffectEntry<CCharacterListTooltipEffect>::[1] func_names 名 CEffectEntry<CCharacterListTooltipEffect>::[1] |
| 0x1402E5070 | CEffectEntry<CClearCharacterFlagEffect>::[1] func_names 名 CEffectEntry<CClearCharacterFlagEffect>::[1] |
| 0x1401956C0 | CDatabaseReloader<CAIStrategyDatabase>::[2] func_names 名 CDatabaseReloader<CAIStrategyDatabase>::[2] |
| 0x140195D40 | CDatabaseReloader<CTrainGfxDatabase>::[2] func_names 名 CDatabaseReloader<CTrainGfxDatabase>::[2] |
| 0x14033B060 | CEffectEntry<CResizeArrayEffectImp<$0A>>::[1] func_names 名 CEffectEntry<CResizeArrayEffectImp<$0A>>::[1] |
| 0x14033C060 | CEffectEntry<CAddOpinionModifierEffect>::[1] func_names 名 CEffectEntry<CAddOpinionModifierEffect>::[1] |
| 0x14033F410 | CEffectEntry<CPromoteCharacterToCountryLeader>::[1] func_names 名 CEffectEntry<CPromoteCharacterToCountryLeader>::[1] |
| 0x1403E9300 | CTriggerEntry<CResizeTempArrayTrigger>::[1] func_names 名 CTriggerEntry<CResizeTempArrayTrigger>::[1] |
| 0x14033B250 | CEffectEntry<CActivateAdvisorEffect>::[1] func_names 名 CEffectEntry<CActivateAdvisorEffect>::[1] |
| 0x1420048D0 | CActiveContractsUiController::OpenCancelConfirmationPopup? func_names 名 CActiveContractsUiController::OpenCancelConfirmationPopup? |
| 0x14033DCC0 | CEffectEntry<CEveryArmyLeaderEffect>::[1] func_names 名 CEffectEntry<CEveryArmyLeaderEffect>::[1] |
| 0x140340100 | CEffectEntry<CRemoveCountryLeaderRoleEffect>::[1] func_names 名 CEffectEntry<CRemoveCountryLeaderRoleEffect>::[1] |
| 0x140340A10 | CEffectEntry<CReverseAddOpinionModifierEffect>::[1] func_names 名 CEffectEntry<CReverseAddOpinionModifierEffect>::[1] |
| 0x140341C40 | CEffectEntry<CSetRelationRuleEffect>::[1] func_names 名 CEffectEntry<CSetRelationRuleEffect>::[1] |
| 0x14030BB70 | CEffectEntry<CForceEnableResistanceEffect>::[1] func_names 名 CEffectEntry<CForceEnableResistanceEffect>::[1] |
| 0x1403427B0 | CEffectEntry<CTurnOperativeLeaderEffect>::[1] func_names 名 CEffectEntry<CTurnOperativeLeaderEffect>::[1] |
| 0x1403E4D40 | CTriggerEntry<CHasActiveTimedDecisionTrigger>::[1] func_names 名 CTriggerEntry<CHasActiveTimedDecisionTrigger>::[1] |
| 0x140456120 | CTriggerEntry<CAnyOperativeLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAnyOperativeLeaderTrigger>::[1] |
| 0x140468030 | CTriggerEntry<CFreeBuildingSlotsTrigger>::[1] func_names 名 CTriggerEntry<CFreeBuildingSlotsTrigger>::[1] |
| 0x140D01ED0 | （无名） 体设 CIntelSource::vftable（RTTI 名） |
| 0x141E80720 | CIntelMapModeMapIconMore::[0] vtable 槽 CIntelMapModeMapIconMore::[0]（func_names RTTI 名） |
| 0x14033C5A0 | CEffectEntry<CAddTimedIdeaEffect>::[1] func_names 名 CEffectEntry<CAddTimedIdeaEffect>::[1] |
| 0x140341E30 | CEffectEntry<CSetTemplateDivisionCapEffect>::[1] func_names 名 CEffectEntry<CSetTemplateDivisionCapEffect>::[1] |
| 0x140342820 | CEffectEntry<CUncompleteNationalFocusEffect>::[1] func_names 名 CEffectEntry<CUncompleteNationalFocusEffect>::[1] |
| 0x140467C80 | CTriggerEntry<CAnyProvinceBuildingLevelTrigger>::[1] func_names 名 CTriggerEntry<CAnyProvinceBuildingLevelTrigger>::[1] |
| 0x14033AEE0 | CEffectEntry<CRemoveFromArrayEffectImp<$00>>::[1] func_names 名 CEffectEntry<CRemoveFromArrayEffectImp<$00>>::[1] |
| 0x14033AF60 | CEffectEntry<CRemoveFromArrayEffectImp<$0A>>::[1] func_names 名 CEffectEntry<CRemoveFromArrayEffectImp<$0A>>::[1] |
| 0x14033BA50 | CEffectEntry<CAddDaysMissionTimeoutEffect>::[1] func_names 名 CEffectEntry<CAddDaysMissionTimeoutEffect>::[1] |
| 0x14033BAC0 | CEffectEntry<CAddDaysRemoveDecisionEffect>::[1] func_names 名 CEffectEntry<CAddDaysRemoveDecisionEffect>::[1] |
| 0x140341EA0 | CEffectEntry<CSetTemplateDivisionForceRecruitingEffect>::[1] func_names 名 CEffectEntry<CSetTemplateDivisionForceRecruitingEffect>::[1] |
| 0x1403E5960 | CTriggerEntry<CHasDecisionTrigger>::[1] func_names 名 CTriggerEntry<CHasDecisionTrigger>::[1] |
| 0x1403E9280 | CTriggerEntry<CRemoveFromTempArrayTrigger>::[1] func_names 名 CTriggerEntry<CRemoveFromTempArrayTrigger>::[1] |
| 0x1404B3DF0 | CHasFactionMilitaryUnlocked::Evaluate func_names 名 CHasFactionMilitaryUnlocked::Evaluate |
| 0x1404B3E60 | CHasFactionResearchUnlocked::Evaluate func_names 名 CHasFactionResearchUnlocked::Evaluate |
| 0x140342900 | CEffectEntry<CUnlockDecisionTooltipEffect>::[1] func_names 名 CEffectEntry<CUnlockDecisionTooltipEffect>::[1] |
| 0x1415BFAE0 | CConfirmRemoveAllRegions::Update func_names 名 CConfirmRemoveAllRegions::Update |
| 0x1402FA170 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140341100 | CEffectEntry<CSetDivisionTemplateLockEffect>::[1] func_names 名 CEffectEntry<CSetDivisionTemplateLockEffect>::[1] |
| 0x140341160 | CEffectEntry<CSetEntityAnimationEffect>::[1] func_names 名 CEffectEntry<CSetEntityAnimationEffect>::[1] |
| 0x14031B9F0 | CTargetedEffect<$0EKHK::$0DNLB>::[4] func_names 名 CTargetedEffect<$0EKHK::$0DNLB>::[4] |
| 0x14033D6E0 | CEffectEntry<CDeactivateAdvisorEffect>::[1] func_names 名 CEffectEntry<CDeactivateAdvisorEffect>::[1] |
| 0x1403B35F0 | CForceUpdateMapMode::ParseToken func_names 名 CForceUpdateMapMode::ParseToken |
| 0x1403E6960 | CTriggerEntry<CHasResourcesTrigger>::[1] func_names 名 CTriggerEntry<CHasResourcesTrigger>::[1] |
| 0x14015C590 | CDatabaseReloader<CScriptedDiplomaticActionTemplateDatabase>::[0] func_names 名 CDatabaseReloader<CScriptedDiplomaticActionTemplateDatabase>::[0] |
| 0x14033AFE0 | CEffectEntry<CResizeArrayEffectImp<$00>>::[1] func_names 名 CEffectEntry<CResizeArrayEffectImp<$00>>::[1] |
| 0x14033E520 | CEffectEntry<CFreeOperativeEffect>::[1] func_names 名 CEffectEntry<CFreeOperativeEffect>::[1] |
| 0x14033EB20 | CEffectEntry<CKillOperativeEffect>::[1] func_names 名 CEffectEntry<CKillOperativeEffect>::[1] |
| 0x140468180 | CTriggerEntry<CHasStateCategoryTrigger>::[1] func_names 名 CTriggerEntry<CHasStateCategoryTrigger>::[1] |
| 0x1402FA110 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14030C0B0 | CEffectEntry<CSetStateCategoryEffect>::[1] func_names 名 CEffectEntry<CSetStateCategoryEffect>::[1] |
| 0x14033A8E0 | CEffectEntry<CAddToArrayEffectImp<$0A>>::[1] func_names 名 CEffectEntry<CAddToArrayEffectImp<$0A>>::[1] |
| 0x14033B780 | CEffectEntry<CAddAutonomyScoreEffect>::[1] func_names 名 CEffectEntry<CAddAutonomyScoreEffect>::[1] |
| 0x1403E2D30 | CTriggerEntry<CAddToTempArrayTrigger>::[1] func_names 名 CTriggerEntry<CAddToTempArrayTrigger>::[1] |
| 0x14045A4D0 | CTriggerEntry<NInternationalMarket::CAnyPurchaseContractTrigger>::[1] func_names 名 CTriggerEntry<NInternationalMarket::CAnyPurchaseContractTrigger>::[1] |
| 0x1422AC2D0 | CChoice<CSmoothListboxItem>::[2] func_names 名 CChoice<CSmoothListboxItem>::[2] |
| 0x14033BE10 | CEffectEntry<CAddNamedThreatEffect>::[1] func_names 名 CEffectEntry<CAddNamedThreatEffect>::[1] |
| 0x1403E6440 | CTriggerEntry<CHasOccupationModifier>::[1] func_names 名 CTriggerEntry<CHasOccupationModifier>::[1] |
| 0x140492A20 | CEffectEntry<NProject::CAddBreakthroughPoints>::[1] func_names 名 CEffectEntry<NProject::CAddBreakthroughPoints>::[1] |
| 0x140D18F50 | CRuleOverrides::[0] vtable 槽 CRuleOverrides::[0]（func_names RTTI 名） |
| 0x1404687B0 | CTriggerEntry<COccupationLawTrigger>::[1] func_names 名 CTriggerEntry<COccupationLawTrigger>::[1] |
| 0x140A28510 | ULexerToken::UEAAXAEAVCReader::NFactions::CFactionGoalStatus::?鈥�::[2] func_names 名 ULexerToken::UEAAXAEAVCReader::NFactions::CFactionGoalStatus::?鈥�::[2] |
| 0x1412BBD30 | CLandCombat::[18] vtable 槽 CLandCombat::[18]（func_names RTTI 名） |
| 0x1403E2C90 | CTriggerEntry<CAILiberateDesireTrigger>::[1] func_names 名 CTriggerEntry<CAILiberateDesireTrigger>::[1] |
| 0x1403E4070 | CTriggerEntry<CCompareAutonomyTrigger>::[1] func_names 名 CTriggerEntry<CCompareAutonomyTrigger>::[1] |
| 0x140439950 | CHasBorderWarBetween::ParseToken func_names 名 CHasBorderWarBetween::ParseToken |
| 0x140475DA0 | CTriggerEntry<CHasUnitTypeTrigger>::[1] func_names 名 CTriggerEntry<CHasUnitTypeTrigger>::[1] |
| 0x140195670 | CDatabaseReloader<CAIRoleDatabase>::[2] func_names 名 CDatabaseReloader<CAIRoleDatabase>::[2] |
| 0x1403E78C0 | CTriggerEntry<CIsInArrayTrigger>::[1] func_names 名 CTriggerEntry<CIsInArrayTrigger>::[1] |
| 0x14033B710 | CEffectEntry<CAddAutonomyRatio>::[1] func_names 名 CEffectEntry<CAddAutonomyRatio>::[1] |
| 0x1403407E0 | CEffectEntry<CRenameProvinceEffect>::[1] func_names 名 CEffectEntry<CRenameProvinceEffect>::[1] |
| 0x1403E73E0 | CTriggerEntry<CIsDateTrigger>::[1] func_names 名 CTriggerEntry<CIsDateTrigger>::[1] |
| 0x1403E8650 | CTriggerEntry<CNavalStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CNavalStrengthRatioTrigger>::[1] |
| 0x140D94370 | CFactionSystem::WriteMembers func_names 名 CFactionSystem::WriteMembers |
| 0x140457540 | CTriggerEntry<NIndustrialOrganisation::CHasTraitTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CHasTraitTrigger>::[1] |
| 0x140341670 | CEffectEntry<CSetNameEffect>::[1] func_names 名 CEffectEntry<CSetNameEffect>::[1] |
| 0x1403E4AA0 | CTriggerEntry<CEstimatedMaxPiercingTrigger>::[1] func_names 名 CTriggerEntry<CEstimatedMaxPiercingTrigger>::[1] |
| 0x14015C5E0 | CDatabaseReloader<CScriptedEffectTemplateDatabase>::[0] func_names 名 CDatabaseReloader<CScriptedEffectTemplateDatabase>::[0] |
| 0x14033FFA0 | CEffectEntry<CReleaseAutonomyEffect>::[1] func_names 名 CEffectEntry<CReleaseAutonomyEffect>::[1] |
| 0x140457810 | CTriggerEntry<NIndustrialOrganisation::CIsTraitUnlockedTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CIsTraitUnlockedTrigger>::[1] |
| 0x140C04990 | CUnit::SetName func_names 名 CUnit::SetName |
| 0x14033D840 | CEffectEntry<CDeleteTemplateAndItsUnits>::[1] func_names 名 CEffectEntry<CDeleteTemplateAndItsUnits>::[1] |
| 0x14035EE30 | CRemoveResourceRights::Execute func_names 名 CRemoveResourceRights::Execute |
| 0x1403E4A40 | CTriggerEntry<CEstimatedMaxArmorTrigger>::[1] func_names 名 CTriggerEntry<CEstimatedMaxArmorTrigger>::[1] |
| 0x1403E95B0 | CTriggerEntry<CStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CStrengthRatioTrigger>::[1] |
| 0x14045A460 | CTriggerEntry<NInternationalMarket::CAllPurchaseContractTrigger>::[1] func_names 名 CTriggerEntry<NInternationalMarket::CAllPurchaseContractTrigger>::[1] |
| 0x140B52590 | CGraphicalMap::[2] vtable 槽 CGraphicalMap::[2]（func_names RTTI 名） |
| 0x140340480 | CEffectEntry<CRemoveOpinionModifierEffect>::[1] func_names 名 CEffectEntry<CRemoveOpinionModifierEffect>::[1] |
| 0x1403E5B10 | CTriggerEntry<CHasDynamicModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasDynamicModifierTrigger>::[1] |
| 0x14015C540 | CDatabaseReloader<CResistanceActivityDatabase>::[0] func_names 名 CDatabaseReloader<CResistanceActivityDatabase>::[0] |
| 0x1402E49F0 | CEffectEntry<CSetLeaderNamePortraitOrDescription<$01>>::[1] func_names 名 CEffectEntry<CSetLeaderNamePortraitOrDescription<$01>>::[1] |
| 0x1402E4A50 | CEffectEntry<CSetLeaderNamePortraitOrDescription<$0A>>::[1] func_names 名 CEffectEntry<CSetLeaderNamePortraitOrDescription<$0A>>::[1] |
| 0x1403E4560 | CTriggerEntry<CCountryHasCosmeticTagTrigger>::[1] func_names 名 CTriggerEntry<CCountryHasCosmeticTagTrigger>::[1] |
| 0x1403E6770 | CTriggerEntry<CHasRelationModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasRelationModifierTrigger>::[1] |
| 0x140E5C5F0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x14015C270 | CDatabaseReloader<CEquipmentGraphicDatabase>::[0] func_names 名 CDatabaseReloader<CEquipmentGraphicDatabase>::[0] |
| 0x14015C2C0 | CDatabaseReloader<CHistoricalAgencyDatabase>::[0] func_names 名 CDatabaseReloader<CHistoricalAgencyDatabase>::[0] |
| 0x14031EDF0 | CSelectTechTreeIconOrigin::ParseTargetToken func_names 名 CSelectTechTreeIconOrigin::ParseTargetToken |
| 0x140455E00 | CTriggerEntry<CAllArmyLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAllArmyLeaderTrigger>::[1] |
| 0x140455EC0 | CTriggerEntry<CAllNavyLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAllNavyLeaderTrigger>::[1] |
| 0x140455FA0 | CTriggerEntry<CAllUnitLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAllUnitLeaderTrigger>::[1] |
| 0x1404560C0 | CTriggerEntry<CAnyNavyLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAnyNavyLeaderTrigger>::[1] |
| 0x1404561A0 | CTriggerEntry<CAnyUnitLeaderTrigger>::[1] func_names 名 CTriggerEntry<CAnyUnitLeaderTrigger>::[1] |
| 0x140468670 | CTriggerEntry<CNumBattalionsInStatesTrigger>::[1] func_names 名 CTriggerEntry<CNumBattalionsInStatesTrigger>::[1] |
| 0x141392F70 | CEffectEntry<CEffectShowDependentTooltip>::[1] func_names 名 CEffectEntry<CEffectShowDependentTooltip>::[1] |
| 0x142383350 | CFormat::[0] vtable 槽 CFormat::[0]（func_names RTTI 名） |
| 0x14015C4A0 | CDatabaseReloader<CPeaceConferenceDatabase>::[0] func_names 名 CDatabaseReloader<CPeaceConferenceDatabase>::[0] |
| 0x14015C630 | CDatabaseReloader<CScriptedMapModeDatabase>::[0] func_names 名 CDatabaseReloader<CScriptedMapModeDatabase>::[0] |
| 0x1404686E0 | CTriggerEntry<CNumDivisionsInStatesTrigger>::[1] func_names 名 CTriggerEntry<CNumDivisionsInStatesTrigger>::[1] |
| 0x14015C0E0 | CDatabaseReloader<CAIStrategyPlanDatabase>::[0] func_names 名 CDatabaseReloader<CAIStrategyPlanDatabase>::[0] |
| 0x1403E3670 | CTriggerEntry<CAnyHomeAreaNeighborCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyHomeAreaNeighborCountryTrigger>::[1] |
| 0x1403E71B0 | CTriggerEntry<CICRatioTrigger>::[1] func_names 名 CTriggerEntry<CICRatioTrigger>::[1] |
| 0x1404882C0 | CSetPowerBalanceGfx::ParseToken func_names 名 CSetPowerBalanceGfx::ParseToken |
| 0x14015C360 | CDatabaseReloader<CNationalFocusDatabase>::[0] func_names 名 CDatabaseReloader<CNationalFocusDatabase>::[0] |
| 0x14015C3B0 | CDatabaseReloader<COccupationLawDatabase>::[0] func_names 名 CDatabaseReloader<COccupationLawDatabase>::[0] |
| 0x14033D920 | CEffectEntry<CDeleteUnitsEffect>::[1] func_names 名 CEffectEntry<CDeleteUnitsEffect>::[1] |
| 0x1403E5610 | CTriggerEntry<CHasCompletedNationalFocusTrigger>::[1] func_names 名 CTriggerEntry<CHasCompletedNationalFocusTrigger>::[1] |
| 0x1403E6630 | CTriggerEntry<CHasOpinionTrigger>::[1] func_names 名 CTriggerEntry<CHasOpinionTrigger>::[1] |
| 0x1404B4220 | CTriggerEntry<CCompareIdeologyWithFactionTrigger>::[1] func_names 名 CTriggerEntry<CCompareIdeologyWithFactionTrigger>::[1] |
| 0x1411D6360 | CCountryIntelNetwork::SetStrengthInAllStates func_names 名 CCountryIntelNetwork::SetStrengthInAllStates |
| 0x14015C4F0 | CDatabaseReloader<CPowerBalanceDatabase>::[0] func_names 名 CDatabaseReloader<CPowerBalanceDatabase>::[0] |
| 0x14033C2D0 | CEffectEntry<CAddScaledPoliticalPowerEffect>::[1] func_names 名 CEffectEntry<CAddScaledPoliticalPowerEffect>::[1] |
| 0x14033CE00 | CEffectEntry<CClearTemplateDivisionCapEffect>::[1] func_names 名 CEffectEntry<CClearTemplateDivisionCapEffect>::[1] |
| 0x1403E27F0 | CTriggerEntry<CFindHighestOrLowestElementTrigger<$00>>::[1] func_names 名 CTriggerEntry<CFindHighestOrLowestElementTrigger<$00>>::[1] |
| 0x1403E2860 | CTriggerEntry<CFindHighestOrLowestElementTrigger<$0A>>::[1] func_names 名 CTriggerEntry<CFindHighestOrLowestElementTrigger<$0A>>::[1] |
| 0x140DFDCF0 | CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[2] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[2] |
| 0x14015C090 | CDatabaseReloader<CAIStrategyDatabase>::[0] func_names 名 CDatabaseReloader<CAIStrategyDatabase>::[0] |
| 0x140340F90 | CEffectEntry<CSetCosmeticTagEffect>::[1] func_names 名 CEffectEntry<CSetCosmeticTagEffect>::[1] |
| 0x140120CB0 | CPdxHybridInlineBufferAllocator<H$09H>::[2] func_names 名 CPdxHybridInlineBufferAllocator<H$09H>::[2] |
| 0x1402D0B80 | CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[2] func_names 名 CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[2] |
| 0x1403E5800 | CTriggerEntry<CHasCountryLeaderWithTraitTrigger>::[1] func_names 名 CTriggerEntry<CHasCountryLeaderWithTraitTrigger>::[1] |
| 0x1403E6A10 | CTriggerEntry<CHasShineEffectOnFocusTrigger>::[1] func_names 名 CTriggerEntry<CHasShineEffectOnFocusTrigger>::[1] |
| 0x140492D50 | CEffectEntry<NProject::CCompletePrototypeReward>::[1] func_names 名 CEffectEntry<NProject::CCompletePrototypeReward>::[1] |
| 0x14151B680 | CLiberateCountryAction::Clone func_names 名 CLiberateCountryAction::Clone |
| 0x14225D9A0 | CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[7] func_names 名 CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[7] |
| 0x14015C220 | CDatabaseReloader<CDecisionDatabase>::[0] func_names 名 CDatabaseReloader<CDecisionDatabase>::[0] |
| 0x14015C720 | CDatabaseReloader<CTrainGfxDatabase>::[0] func_names 名 CDatabaseReloader<CTrainGfxDatabase>::[0] |
| 0x14030C1C0 | CEffectEntry<CSetStateNameEffect>::[1] func_names 名 CEffectEntry<CSetStateNameEffect>::[1] |
| 0x140445360 | CTriggerEntry<CUnitLeaderHasAbilityTrigger>::[1] func_names 名 CTriggerEntry<CUnitLeaderHasAbilityTrigger>::[1] |
| 0x14015C130 | CDatabaseReloader<CAbilityDatabase>::[0] func_names 名 CDatabaseReloader<CAbilityDatabase>::[0] |
| 0x140340320 | CEffectEntry<CRemoveIdeasWithTraitEffect>::[1] func_names 名 CEffectEntry<CRemoveIdeasWithTraitEffect>::[1] |
| 0x1403E58B0 | CTriggerEntry<CHasCustomDifficultyTrigger>::[1] func_names 名 CTriggerEntry<CHasCustomDifficultyTrigger>::[1] |
| 0x14015C040 | CDatabaseReloader<CAIRoleDatabase>::[0] func_names 名 CDatabaseReloader<CAIRoleDatabase>::[0] |
| 0x140342970 | CEffectEntry<CUnlockNationalFocusEffect>::[1] func_names 名 CEffectEntry<CUnlockNationalFocusEffect>::[1] |
| 0x1403E6DE0 | CTriggerEntry<CHasTraitTrigger>::[1] func_names 名 CTriggerEntry<CHasTraitTrigger>::[1] |
| 0x1403E88C0 | CTriggerEntry<CNetworkStrengthTrigger>::[1] func_names 名 CTriggerEntry<CNetworkStrengthTrigger>::[1] |
| 0x14045D140 | CEffectEntry<CArmyChangeTemplateEffect>::[1] func_names 名 CEffectEntry<CArmyChangeTemplateEffect>::[1] |
| 0x1404A20D0 | CTriggerEntry<NProject::CAllActiveScientistsTrigger>::[1] func_names 名 CTriggerEntry<NProject::CAllActiveScientistsTrigger>::[1] |
| 0x14015C310 | CDatabaseReloader<CIdeaDatabase>::[0] func_names 名 CDatabaseReloader<CIdeaDatabase>::[0] |
| 0x1403E37B0 | CTriggerEntry<CAnySubjectCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnySubjectCountryTrigger>::[1] |
| 0x1403E5F90 | CTriggerEntry<CHasIdeaWithTraitTrigger>::[1] func_names 名 CTriggerEntry<CHasIdeaWithTraitTrigger>::[1] |
| 0x14043F180 | CTriggerEntry<NCareerProfile::CCheckRibbon>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckRibbon>::[1] |
| 0x1404A21B0 | CTriggerEntry<NProject::CAnyActiveScientistTrigger>::[1] func_names 名 CTriggerEntry<NProject::CAnyActiveScientistTrigger>::[1] |
| 0x14033B2C0 | CEffectEntry<CActivateDecisionEffect>::[1] func_names 名 CEffectEntry<CActivateDecisionEffect>::[1] |
| 0x14033B9E0 | CEffectEntry<CAddCountryLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CAddCountryLeaderTraitEffect>::[1] |
| 0x14033D750 | CEffectEntry<CDeactivateShineOnFocus>::[1] func_names 名 CEffectEntry<CDeactivateShineOnFocus>::[1] |
| 0x14033EEA0 | CEffectEntry<CLoadOOBEffect>::[1] func_names 名 CEffectEntry<CLoadOOBEffect>::[1] |
| 0x1403D4CD0 | CHasBuilt::Evaluate func_names 名 CHasBuilt::Evaluate |
| 0x140444610 | CTriggerEntry<CCanFireAdvisor>::[1] func_names 名 CTriggerEntry<CCanFireAdvisor>::[1] |
| 0x1404A7760 | CNumNukesLeftToDrop::GetDesc func_names 名 CNumNukesLeftToDrop::GetDesc |
| 0x140195930 | CDatabaseReloader<CIdeaDatabase>::[2] func_names 名 CDatabaseReloader<CIdeaDatabase>::[2] |
| 0x14033B320 | CEffectEntry<CActivateMissionEffect>::[1] func_names 名 CEffectEntry<CActivateMissionEffect>::[1] |
| 0x1403E3150 | CTriggerEntry<CAllOtherCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllOtherCountryTrigger>::[1] |
| 0x1403E9460 | CTriggerEntry<CShipsInAreaTrigger>::[1] func_names 名 CTriggerEntry<CShipsInAreaTrigger>::[1] |
| 0x14045BC90 | CTriggerEntry<CArmyHasOfficerNameTrigger>::[1] func_names 名 CTriggerEntry<CArmyHasOfficerNameTrigger>::[1] |
| 0x140492AE0 | CEffectEntry<NProject::CAddProjectProgressRatioEffect>::[1] func_names 名 CEffectEntry<NProject::CAddProjectProgressRatioEffect>::[1] |
| 0x14030BEA0 | CEffectEntry<CResetStateNameEffect>::[1] func_names 名 CEffectEntry<CResetStateNameEffect>::[1] |
| 0x14033B400 | CEffectEntry<CActivateShineOnFocus>::[1] func_names 名 CEffectEntry<CActivateShineOnFocus>::[1] |
| 0x1403401E0 | CEffectEntry<CRemoveDecisionEffect>::[1] func_names 名 CEffectEntry<CRemoveDecisionEffect>::[1] |
| 0x140340BA0 | CEffectEntry<CScopedPlaySongEffect>::[1] func_names 名 CEffectEntry<CScopedPlaySongEffect>::[1] |
| 0x1403EDFD0 | CManpowerPerFactoryRatio::GetValue func_names 名 CManpowerPerFactoryRatio::GetValue |
| 0x1404AA7E0 | CEffectEntry<CSetFactionNameEffect>::[1] func_names 名 CEffectEntry<CSetFactionNameEffect>::[1] |
| 0x142092E70 | SForceReader::[0] vtable 槽 SForceReader::[0]（func_names RTTI 名） |
| 0x1403403D0 | CEffectEntry<CRemoveMissionEffect>::[1] func_names 名 CEffectEntry<CRemoveMissionEffect>::[1] |
| 0x1403E5D00 | CTriggerEntry<CHasFocusTreeTrigger>::[1] func_names 名 CTriggerEntry<CHasFocusTreeTrigger>::[1] |
| 0x140455E60 | CTriggerEntry<CAllCharacterTrigger>::[1] func_names 名 CTriggerEntry<CAllCharacterTrigger>::[1] |
| 0x140456060 | CTriggerEntry<CAnyCharacterTrigger>::[1] func_names 名 CTriggerEntry<CAnyCharacterTrigger>::[1] |
| 0x1404AA3E0 | CEffectEntry<CCreateFactionEffect>::[1] func_names 名 CEffectEntry<CCreateFactionEffect>::[1] |
| 0x1403E6C90 | CTriggerEntry<CHasTemplateTrigger>::[1] func_names 名 CTriggerEntry<CHasTemplateTrigger>::[1] |
| 0x14045D0E0 | CEffectEntry<CAddUnitMedalEffect>::[1] func_names 名 CEffectEntry<CAddUnitMedalEffect>::[1] |
| 0x140467AC0 | CTriggerEntry<CAnyCountryWithCoreStateTrigger>::[1] func_names 名 CTriggerEntry<CAnyCountryWithCoreStateTrigger>::[1] |
| 0x140E777B0 | COnDelay<H::12::USOnDismantleCompleted::NProject::EAVCProgram*>::Reader func_names 名 COnDelay<H::12::USOnDismantleCompleted::NProject::EAVCProgram*>::Reader |
| 0x14033EF00 | CEffectEntry<CLockAllTemplateEffect>::[1] func_names 名 CEffectEntry<CLockAllTemplateEffect>::[1] |
| 0x140340C00 | CEffectEntry<CScopedSoundEffect>::[1] func_names 名 CEffectEntry<CScopedSoundEffect>::[1] |
| 0x1404A2220 | CTriggerEntry<NProject::CAnyScientistTrigger>::[1] func_names 名 CTriggerEntry<NProject::CAnyScientistTrigger>::[1] |
| 0x1404A4180 | CEffectEntry<NRaids::CRaidReduceProjectProgressRatioEffect>::[1] func_names 名 CEffectEntry<NRaids::CRaidReduceProjectProgressRatioEffect>::[1] |
| 0x1402F9A80 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402F9BA0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402FA070 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402FA230 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140340170 | CEffectEntry<CRemoveCountryLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CRemoveCountryLeaderTraitEffect>::[1] |
| 0x1403E48E0 | CTriggerEntry<CDivisionsInStateBorderTrigger>::[1] func_names 名 CTriggerEntry<CDivisionsInStateBorderTrigger>::[1] |
| 0x140468750 | CTriggerEntry<CNumOwnedNeighbourStatesTrigger>::[1] func_names 名 CTriggerEntry<CNumOwnedNeighbourStatesTrigger>::[1] |
| 0x1413A33A0 | CTriggerEntry<CLogScriptTrigger>::[1] func_names 名 CTriggerEntry<CLogScriptTrigger>::[1] |
| 0x1403E4F80 | CTriggerEntry<CHasArmyExperienceTrigger>::[1] func_names 名 CTriggerEntry<CHasArmyExperienceTrigger>::[1] |
| 0x1403E62B0 | CTriggerEntry<CHasNavyExperienceTrigger>::[1] func_names 名 CTriggerEntry<CHasNavyExperienceTrigger>::[1] |
| 0x1403E6820 | CTriggerEntry<CHasResourcesInCountryTrigger>::[1] func_names 名 CTriggerEntry<CHasResourcesInCountryTrigger>::[1] |
| 0x1403E94B0 | CTriggerEntry<CShipsInStatePortTrigger>::[1] func_names 名 CTriggerEntry<CShipsInStatePortTrigger>::[1] |
| 0x140444AD0 | CTriggerEntry<CIsCharacterSlot>::[1] func_names 名 CTriggerEntry<CIsCharacterSlot>::[1] |
| 0x1404451F0 | CTriggerEntry<CNotAlreadyHired>::[1] func_names 名 CTriggerEntry<CNotAlreadyHired>::[1] |
| 0x1413930B0 | CEffectEntry<CLogScriptEffect>::[1] func_names 名 CEffectEntry<CLogScriptEffect>::[1] |
| 0x14033F2D0 | CEffectEntry<CPlaySongEffect>::[1] func_names 名 CEffectEntry<CPlaySongEffect>::[1] |
| 0x1403E29D0 | CTriggerEntry<CForEachTriggerImp<$00>>::[1] func_names 名 CTriggerEntry<CForEachTriggerImp<$00>>::[1] |
| 0x1403E2A40 | CTriggerEntry<CForEachTriggerImp<$0A>>::[1] func_names 名 CTriggerEntry<CForEachTriggerImp<$0A>>::[1] |
| 0x1403E4DF0 | CTriggerEntry<CHasAirExperienceTrigger>::[1] func_names 名 CTriggerEntry<CHasAirExperienceTrigger>::[1] |
| 0x140467970 | CTriggerEntry<CAllStateTrigger>::[1] func_names 名 CTriggerEntry<CAllStateTrigger>::[1] |
| 0x14049B630 | CEffectEntry<CSendEquipmentFractionEffect>::[1] func_names 名 CEffectEntry<CSendEquipmentFractionEffect>::[1] |
| 0x1402E5390 | CEffectEntry<CRemoveUnitLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CRemoveUnitLeaderTraitEffect>::[1] |
| 0x14031F1D0 | CEffectEntry<CSetResearchSlotsEffect>::[1] func_names 名 CEffectEntry<CSetResearchSlotsEffect>::[1] |
| 0x1403E3070 | CTriggerEntry<CAllNeighborCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllNeighborCountryTrigger>::[1] |
| 0x1403E30E0 | CTriggerEntry<CAllOccupiedCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllOccupiedCountryTrigger>::[1] |
| 0x1403E36D0 | CTriggerEntry<CAnyOccupiedCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyOccupiedCountryTrigger>::[1] |
| 0x1404677B0 | CTriggerEntry<CAllControlledStateTrigger>::[1] func_names 名 CTriggerEntry<CAllControlledStateTrigger>::[1] |
| 0x1404679E0 | CTriggerEntry<CAnyControlledStateTrigger>::[1] func_names 名 CTriggerEntry<CAnyControlledStateTrigger>::[1] |
| 0x140467B30 | CTriggerEntry<CAnyNeighborCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyNeighborCountryTrigger>::[1] |
| 0x140195800 | CDatabaseReloader<CContinuousFocusDatabase>::[2] func_names 名 CDatabaseReloader<CContinuousFocusDatabase>::[2] |
| 0x140195850 | CDatabaseReloader<CDecisionDatabase>::[2] func_names 名 CDatabaseReloader<CDecisionDatabase>::[2] |
| 0x140195980 | CDatabaseReloader<CNationalFocusDatabase>::[2] func_names 名 CDatabaseReloader<CNationalFocusDatabase>::[2] |
| 0x1401959D0 | CDatabaseReloader<COccupationLawDatabase>::[2] func_names 名 CDatabaseReloader<COccupationLawDatabase>::[2] |
| 0x140195A20 | CDatabaseReloader<COccupationModifierDatabase>::[2] func_names 名 CDatabaseReloader<COccupationModifierDatabase>::[2] |
| 0x140195AC0 | CDatabaseReloader<CPeaceConferenceDatabase>::[2] func_names 名 CDatabaseReloader<CPeaceConferenceDatabase>::[2] |
| 0x140195B10 | CDatabaseReloader<CPowerBalanceDatabase>::[2] func_names 名 CDatabaseReloader<CPowerBalanceDatabase>::[2] |
| 0x140195C00 | CDatabaseReloader<CScriptedEffectTemplateDatabase>::[2] func_names 名 CDatabaseReloader<CScriptedEffectTemplateDatabase>::[2] |
| 0x140195CA0 | CDatabaseReloader<CScriptedTriggerTemplateDatabase>::[2] func_names 名 CDatabaseReloader<CScriptedTriggerTemplateDatabase>::[2] |
| 0x140195CF0 | CDatabaseReloader<CScriptedWindowDatabase>::[2] func_names 名 CDatabaseReloader<CScriptedWindowDatabase>::[2] |
| 0x14033E3F0 | CEffectEntry<CForceOperativeLeaderIntoHiding>::[1] func_names 名 CEffectEntry<CForceOperativeLeaderIntoHiding>::[1] |
| 0x1403E31C0 | CTriggerEntry<CAllSubjectCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllSubjectCountryTrigger>::[1] |
| 0x1404576F0 | CTriggerEntry<NIndustrialOrganisation::CIsOrganisationTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CIsOrganisationTrigger>::[1] |
| 0x14151BD40 | CStatePeaceAction::IsSameAction func_names 名 CStatePeaceAction::IsSameAction |
| 0x1423748C0 | CGridBoxType::[0] vtable 槽 CGridBoxType::[0]（func_names RTTI 名） |
| 0x1403420A0 | CEffectEntry<CSoundEffect>::[1] func_names 名 CEffectEntry<CSoundEffect>::[1] |
| 0x1403E33E0 | CTriggerEntry<CAnyAlliedCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyAlliedCountryTrigger>::[1] |
| 0x14045BB70 | CTriggerEntry<CAnyCountryArmyTrigger>::[1] func_names 名 CTriggerEntry<CAnyCountryArmyTrigger>::[1] |
| 0x140467890 | CTriggerEntry<CAllNeighborStateTrigger>::[1] func_names 名 CTriggerEntry<CAllNeighborStateTrigger>::[1] |
| 0x14015C1D0 | CDatabaseReloader<CContinuousFocusDatabase>::[0] func_names 名 CDatabaseReloader<CContinuousFocusDatabase>::[0] |
| 0x14030BD80 | CEffectEntry<CRemoveResistanceTargetEffect>::[1] func_names 名 CEffectEntry<CRemoveResistanceTargetEffect>::[1] |
| 0x140334F10 | CRemoveDecisionOnCooldown::ParseTargetToken func_names 名 CRemoveDecisionOnCooldown::ParseTargetToken |
| 0x14033BEE0 | CEffectEntry<CAddNavalRoleEffect>::[1] func_names 名 CEffectEntry<CAddNavalRoleEffect>::[1] |
| 0x14033E0E0 | CEffectEntry<CFinalizeBorderWar>::[1] func_names 名 CEffectEntry<CFinalizeBorderWar>::[1] |
| 0x1403408A0 | CEffectEntry<CResetProvinceEffect>::[1] func_names 名 CEffectEntry<CResetProvinceEffect>::[1] |
| 0x1403E2F90 | CTriggerEntry<CAllEnemyCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllEnemyCountryTrigger>::[1] |
| 0x1403E3590 | CTriggerEntry<CAnyEnemyCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyEnemyCountryTrigger>::[1] |
| 0x1403E3740 | CTriggerEntry<CAnyOtherCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyOtherCountryTrigger>::[1] |
| 0x14015C6D0 | CDatabaseReloader<CScriptedWindowDatabase>::[0] func_names 名 CDatabaseReloader<CScriptedWindowDatabase>::[0] |
| 0x1401958E0 | CDatabaseReloader<CHistoricalAgencyDatabase>::[2] func_names 名 CDatabaseReloader<CHistoricalAgencyDatabase>::[2] |
| 0x140195B60 | CDatabaseReloader<CResistanceActivityDatabase>::[2] func_names 名 CDatabaseReloader<CResistanceActivityDatabase>::[2] |
| 0x140340780 | CEffectEntry<CRemoveWargoalEffect>::[1] func_names 名 CEffectEntry<CRemoveWargoalEffect>::[1] |
| 0x140341BE0 | CEffectEntry<CSetProvinceControllerEffect>::[1] func_names 名 CEffectEntry<CSetProvinceControllerEffect>::[1] |
| 0x1403E3860 | CTriggerEntry<CArmyManpowerInStateTrigger>::[1] func_names 名 CTriggerEntry<CArmyManpowerInStateTrigger>::[1] |
| 0x1403E5140 | CTriggerEntry<CHasAutonomyStateTrigger>::[1] func_names 名 CTriggerEntry<CHasAutonomyStateTrigger>::[1] |
| 0x14045BBE0 | CTriggerEntry<CAnyStateArmyTrigger>::[1] func_names 名 CTriggerEntry<CAnyStateArmyTrigger>::[1] |
| 0x14033DA60 | CEffectEntry<CDiplomaticRelationEffect>::[1] func_names 名 CEffectEntry<CDiplomaticRelationEffect>::[1] |
| 0x1403B1830 | CCreateDynamicCountry::ParseToken func_names 名 CCreateDynamicCountry::ParseToken |
| 0x140467900 | CTriggerEntry<CAllOwnedStateTrigger>::[1] func_names 名 CTriggerEntry<CAllOwnedStateTrigger>::[1] |
| 0x140467C10 | CTriggerEntry<CAnyOwnedStateTrigger>::[1] func_names 名 CTriggerEntry<CAnyOwnedStateTrigger>::[1] |
| 0x1404A4120 | CEffectEntry<NRaids::CRaidAddUnitExperienceEffect>::[1] func_names 名 CEffectEntry<NRaids::CRaidAddUnitExperienceEffect>::[1] |
| 0x14151A4B0 | CTakeStateAction::GetActionLabel func_names 名 CTakeStateAction::GetActionLabel |
| 0x14161F790 | CNavalCombatant::[14] vtable 槽 CNavalCombatant::[14]（func_names RTTI 名） |
| 0x14033FEF0 | CEffectEntry<CRecruitCharacterEffect>::[1] func_names 名 CEffectEntry<CRecruitCharacterEffect>::[1] |
| 0x140467A50 | CTriggerEntry<CAnyCoreStateTrigger>::[1] func_names 名 CTriggerEntry<CAnyCoreStateTrigger>::[1] |
| 0x1403AED00 | CSetOrAddVictoryPointsEffect<$00>::[4] func_names 名 CSetOrAddVictoryPointsEffect<$00>::[4] |
| 0x140439AC0 | CHasCoreOccupationModifier::ParseToken func_names 名 CHasCoreOccupationModifier::ParseToken |
| 0x140467740 | CTriggerEntry<CAllClaimantTrigger>::[1] func_names 名 CTriggerEntry<CAllClaimantTrigger>::[1] |
| 0x1404A6570 | CEffectEntry<CStateAndCountryEffect<CRemoveContestedOwner>>::[1] func_names 名 CEffectEntry<CStateAndCountryEffect<CRemoveContestedOwner>>::[1] |
| 0x1403E2EA0 | CTriggerEntry<CAllCountryTrigger>::[1] func_names 名 CTriggerEntry<CAllCountryTrigger>::[1] |
| 0x1403E34A0 | CTriggerEntry<CAnyCountryTrigger>::[1] func_names 名 CTriggerEntry<CAnyCountryTrigger>::[1] |
| 0x1402F9900 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402F9960 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402F9EF0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1402F9F50 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14033FDD0 | CEffectEntry<CRandomizeWeatherEffect>::[1] func_names 名 CEffectEntry<CRandomizeWeatherEffect>::[1] |
| 0x14015C450 | CDatabaseReloader<COnActionDataBase>::[0] func_names 名 CDatabaseReloader<COnActionDataBase>::[0] |
| 0x14031EF40 | CEffectEntry<CAddResearchSlotEffect>::[1] func_names 名 CEffectEntry<CAddResearchSlotEffect>::[1] |
| 0x140467EA0 | CTriggerEntry<CAnyStateTrigger>::[1] func_names 名 CTriggerEntry<CAnyStateTrigger>::[1] |
| 0x1404A6520 | CEffectEntry<CStateAndCountryEffect<CAddContestedOwner>>::[1] func_names 名 CEffectEntry<CStateAndCountryEffect<CAddContestedOwner>>::[1] |
| 0x14033EF60 | CEffectEntry<CMakePuppetEffect>::[1] func_names 名 CEffectEntry<CMakePuppetEffect>::[1] |
| 0x140341C80 | CEffectEntry<CSetRuleEffect>::[1] func_names 名 CEffectEntry<CSetRuleEffect>::[1] |
| 0x1401AC880 | numpunct<char,std>::[6] func_names 名 numpunct<char,std>::[6] |
| 0x1401AC8C0 | numpunct<char,std>::[5] func_names 名 numpunct<char,std>::[5] |
| 0x1401AD6A0 | numpunct<char,std>::[7] func_names 名 numpunct<char,std>::[7] |
| 0x14033E9C0 | CEffectEntry<CHarmOperativeEffect>::[1] func_names 名 CEffectEntry<CHarmOperativeEffect>::[1] |
| 0x14034B700 | CAddRegionEfficiency::Execute func_names 名 CAddRegionEfficiency::Execute |
| 0x14033E900 | CEffectEntry<CGoToProvinceEffect>::[1] func_names 名 CEffectEntry<CGoToProvinceEffect>::[1] |
| 0x1403E4B50 | CTriggerEntry<CFightingArmyStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CFightingArmyStrengthRatioTrigger>::[1] |
| 0x1402F9A20 | CEffectEntry<NIndustrialOrganisation::CAddFundsGainFactorEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CAddFundsGainFactorEffect>::[1] |
| 0x1402FA010 | CEffectEntry<NIndustrialOrganisation::CSetFundsGainFactorEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CSetFundsGainFactorEffect>::[1] |
| 0x14045A580 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x1403E5530 | CTriggerEntry<CHasCompletedAgencyUpgradeTrigger>::[1] func_names 名 CTriggerEntry<CHasCompletedAgencyUpgradeTrigger>::[1] |
| 0x1402F9AE0 | CEffectEntry<NIndustrialOrganisation::CAddResearchBonusEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CAddResearchBonusEffect>::[1] |
| 0x1402FA1D0 | CEffectEntry<NIndustrialOrganisation::CSetResearchBonusEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CSetResearchBonusEffect>::[1] |
| 0x14033C540 | CEffectEntry<CAddThreatEffect>::[1] func_names 名 CEffectEntry<CAddThreatEffect>::[1] |
| 0x14033E960 | CEffectEntry<CGoToStateEffect>::[1] func_names 名 CEffectEntry<CGoToStateEffect>::[1] |
| 0x1402F9C00 | CEffectEntry<NIndustrialOrganisation::CAddTaskCapacityEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CAddTaskCapacityEffect>::[1] |
| 0x1402FA290 | CEffectEntry<NIndustrialOrganisation::CSetTaskCapacityEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CSetTaskCapacityEffect>::[1] |
| 0x1403038E0 | CEffectEntry<NInternationalMarket::CGiveMarketAccessEffect>::[1] func_names 名 CEffectEntry<NInternationalMarket::CGiveMarketAccessEffect>::[1] |
| 0x1403E8860 | CTriggerEntry<CNetworkNationalCoverageTrigger>::[1] func_names 名 CTriggerEntry<CNetworkNationalCoverageTrigger>::[1] |
| 0x1404A2420 | CTriggerEntry<NProject::CHasScientistLevelTrigger>::[1] func_names 名 CTriggerEntry<NProject::CHasScientistLevelTrigger>::[1] |
| 0x1403E5A60 | CTriggerEntry<CHasDeployedAirForceSizeTrigger>::[1] func_names 名 CTriggerEntry<CHasDeployedAirForceSizeTrigger>::[1] |
| 0x140342520 | CEffectEntry<CTeleportRailwayGunsToDeployProvinceEffect>::[1] func_names 名 CEffectEntry<CTeleportRailwayGunsToDeployProvinceEffect>::[1] |
| 0x1403E43B0 | CTriggerEntry<CCountPlanesStationedInRegionTrigger>::[1] func_names 名 CTriggerEntry<CCountPlanesStationedInRegionTrigger>::[1] |
| 0x1403E5040 | CTriggerEntry<CHasArmySizeTrigger>::[1] func_names 名 CTriggerEntry<CHasArmySizeTrigger>::[1] |
| 0x1422E8A50 | CChatBuffer::CSendChatMessage::PayloadWriter func_names 名 CChatBuffer::CSendChatMessage::PayloadWriter |
| 0x14033CBC0 | CEffectEntry<CClampTempVariableEffect>::[1] func_names 名 CEffectEntry<CClampTempVariableEffect>::[1] |
| 0x1402F99C0 | CEffectEntry<NIndustrialOrganisation::CAddFundsEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CAddFundsEffect>::[1] |
| 0x1402F9FB0 | CEffectEntry<NIndustrialOrganisation::CSetFundsEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CSetFundsEffect>::[1] |
| 0x1403E54D0 | CTriggerEntry<CHasCollaborationTrigger>::[1] func_names 名 CTriggerEntry<CHasCollaborationTrigger>::[1] |
| 0x1401958A0 | CDatabaseReloader<CEquipmentGraphicDatabase>::[2] func_names 名 CDatabaseReloader<CEquipmentGraphicDatabase>::[2] |
| 0x1402F9B40 | CEffectEntry<NIndustrialOrganisation::CAddSizeEffect>::[1] func_names 名 CEffectEntry<NIndustrialOrganisation::CAddSizeEffect>::[1] |
| 0x1403E3EE0 | CTriggerEntry<CClampVariableTrigger>::[1] func_names 名 CTriggerEntry<CClampVariableTrigger>::[1] |
| 0x1403E4690 | CTriggerEntry<CDecryptionRatioTrigger>::[1] func_names 名 CTriggerEntry<CDecryptionRatioTrigger>::[1] |
| 0x14047C7D0 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x14015C680 | CDatabaseReloader<CScriptedTriggerTemplateDatabase>::[0] func_names 名 CDatabaseReloader<CScriptedTriggerTemplateDatabase>::[0] |
| 0x14033C870 | CEffectEntry<CAnnexCountryEffect>::[1] func_names 名 CEffectEntry<CAnnexCountryEffect>::[1] |
| 0x14033CC30 | CEffectEntry<CClampVariableEffect>::[1] func_names 名 CEffectEntry<CClampVariableEffect>::[1] |
| 0x140342580 | CEffectEntry<CTransferNavyEffect>::[1] func_names 名 CEffectEntry<CTransferNavyEffect>::[1] |
| 0x14047C780 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x1402E4B10 | CEffectEntry<CAddCoordinationSkillEffect>::[1] func_names 名 CEffectEntry<CAddCoordinationSkillEffect>::[1] |
| 0x1402F7E90 | CEffectEntry<CReleaseCapturedGeneralsEffect>::[1] func_names 名 CEffectEntry<CReleaseCapturedGeneralsEffect>::[1] |
| 0x14033CA90 | CEffectEntry<CCancelBorderWar>::[1] func_names 名 CEffectEntry<CCancelBorderWar>::[1] |
| 0x14033E790 | CEffectEntry<CGiveMilitaryAccessEffect>::[1] func_names 名 CEffectEntry<CGiveMilitaryAccessEffect>::[1] |
| 0x14048FDA0 | CEffectEntry<CAddCICEffect>::[1] func_names 名 CEffectEntry<CAddCICEffect>::[1] |
| 0x1422AC1A0 | CSimpleListbox<CStandardlistboxItem>::[33] func_names 名 CSimpleListbox<CStandardlistboxItem>::[33] |
| 0x14030B5C0 | CEffectEntry<CAddExtraSharedBuildingSlotsEffect>::[1] func_names 名 CEffectEntry<CAddExtraSharedBuildingSlotsEffect>::[1] |
| 0x14033BE80 | CEffectEntry<CAddNationalityToOperativeEffect>::[1] func_names 名 CEffectEntry<CAddNationalityToOperativeEffect>::[1] |
| 0x140341D30 | CEffectEntry<CSetStateControllerEffect>::[1] func_names 名 CEffectEntry<CSetStateControllerEffect>::[1] |
| 0x14015C400 | CDatabaseReloader<COccupationModifierDatabase>::[0] func_names 名 CDatabaseReloader<COccupationModifierDatabase>::[0] |
| 0x14030C4F0 | CEffectEntry<CTransferStateToEffect>::[1] func_names 名 CEffectEntry<CTransferStateToEffect>::[1] |
| 0x140341F00 | CEffectEntry<CSetTruceEffect>::[1] func_names 名 CEffectEntry<CSetTruceEffect>::[1] |
| 0x1403E3D70 | CTriggerEntry<CCasualtiesInflictedByInThousandsTrigger>::[1] func_names 名 CTriggerEntry<CCasualtiesInflictedByInThousandsTrigger>::[1] |
| 0x14043EFB0 | CTriggerEntry<NCareerProfile::CCheckPlaythroughRatio>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckPlaythroughRatio>::[1] |
| 0x1404AA320 | CEffectEntry<CAddFactionPowerProjectionEffect>::[1] func_names 名 CEffectEntry<CAddFactionPowerProjectionEffect>::[1] |
| 0x14030BCC0 | CEffectEntry<CRemoveClaimByEffect>::[1] func_names 名 CEffectEntry<CRemoveClaimByEffect>::[1] |
| 0x1403406B0 | CEffectEntry<CRemoveStateCoreEffect>::[1] func_names 名 CEffectEntry<CRemoveStateCoreEffect>::[1] |
| 0x1403E6EE0 | CTriggerEntry<CHasVolunteersFromTrigger>::[1] func_names 名 CTriggerEntry<CHasVolunteersFromTrigger>::[1] |
| 0x14045CFB0 | CEffectEntry<CAddDivisionalCommanderXpEffect>::[1] func_names 名 CEffectEntry<CAddDivisionalCommanderXpEffect>::[1] |
| 0x14047C920 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x1404AA200 | CEffectEntry<CAddFactionInfluenceRatioEffect>::[1] func_names 名 CEffectEntry<CAddFactionInfluenceRatioEffect>::[1] |
| 0x1404AA260 | CEffectEntry<CAddFactionInfluenceScoreEffect>::[1] func_names 名 CEffectEntry<CAddFactionInfluenceScoreEffect>::[1] |
| 0x140E77800 | COnDelay<鈥�>::Reader func_names 名 COnDelay<鈥�>::Reader |
| 0x140129EA0 | ctype<char,std>::[3] func_names 名 ctype<char,std>::[3] |
| 0x140129F00 | ctype<char,std>::[5] func_names 名 ctype<char,std>::[5] |
| 0x14033C950 | CEffectEntry<CBreakEmbargoEffect>::[1] func_names 名 CEffectEntry<CBreakEmbargoEffect>::[1] |
| 0x1404AA380 | CEffectEntry<CAddToFactionEffect>::[1] func_names 名 CEffectEntry<CAddToFactionEffect>::[1] |
| 0x14203CB30 | CListWidget<鈥�>::[0] func_names 名 CListWidget<鈥�>::[0] |
| 0x142058EA0 | CListWidget<鈥�>::[0] func_names 名 CListWidget<鈥�>::[0] |
| 0x14030C120 | CEffectEntry<CSetStateControllerToEffect>::[1] func_names 名 CEffectEntry<CSetStateControllerToEffect>::[1] |
| 0x14033FE90 | CEffectEntry<CRecallVolunteersFromEffect>::[1] func_names 名 CEffectEntry<CRecallVolunteersFromEffect>::[1] |
| 0x1403E4FE0 | CTriggerEntry<CHasArmyManpowerTrigger>::[1] func_names 名 CTriggerEntry<CHasArmyManpowerTrigger>::[1] |
| 0x14047DBC0 | CVariableEffectBuilder<鈥�>::[7] func_names 名 CVariableEffectBuilder<鈥�>::[7] |
| 0x14047DC10 | CVariableEffectBuilder<鈥�>::[7] func_names 名 CVariableEffectBuilder<鈥�>::[7] |
| 0x14047DC60 | CVariableEffectBuilder<CModuloVariable<CTempVariableResolver>>::[7] func_names 名 CVariableEffectBuilder<CModuloVariable<CTempVariableResolver>>::[7] |
| 0x14047DCB0 | CVariableEffectBuilder<CSetToRandomValue<CTempVariableResolver>>::[7] func_names 名 CVariableEffectBuilder<CSetToRandomValue<CTempVariableResolver>>::[7] |
| 0x140529410 | CEffectEntry<NDoctrines::CSetSubDoctrineEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CSetSubDoctrineEffect>::[1] |
| 0x14015C180 | CDatabaseReloader<CAgencyUpgradeDatabase>::[0] func_names 名 CDatabaseReloader<CAgencyUpgradeDatabase>::[0] |
| 0x14031F0E0 | CEffectEntry<CModifyTechnologySharingBonusEffect>::[1] func_names 名 CEffectEntry<CModifyTechnologySharingBonusEffect>::[1] |
| 0x1403E70A0 | CTriggerEntry<CHasWarWithWargoalAgainst>::[1] func_names 名 CTriggerEntry<CHasWarWithWargoalAgainst>::[1] |
| 0x14108F440 | CAIGeneral::[22] vtable 槽 CAIGeneral::[22]（func_names RTTI 名） |
| 0x141500570 | CLendLeaseAction::GetEnableTrigger func_names 名 CLendLeaseAction::GetEnableTrigger |
| 0x1403E9220 | CTriggerEntry<CReceivedExpeditionaryForcesTrigger>::[1] func_names 名 CTriggerEntry<CReceivedExpeditionaryForcesTrigger>::[1] |
| 0x1403E9790 | CTriggerEntry<CWarLengthWithTrigger>::[1] func_names 名 CTriggerEntry<CWarLengthWithTrigger>::[1] |
| 0x1404AA2C0 | CEffectEntry<CAddFactionInitiativeEffect>::[1] func_names 名 CEffectEntry<CAddFactionInitiativeEffect>::[1] |
| 0x141A2E2F0 | CConfirmDeleteOrder::Update func_names 名 CConfirmDeleteOrder::Update |
| 0x14030BFF0 | CEffectEntry<CSetGarrisonStrengthEffect>::[1] func_names 名 CEffectEntry<CSetGarrisonStrengthEffect>::[1] |
| 0x14031F080 | CEffectEntry<CInheritTechnologyEffect>::[1] func_names 名 CEffectEntry<CInheritTechnologyEffect>::[1] |
| 0x140492B90 | CEffectEntry<NProject::CAddScientistTraitEffect>::[1] func_names 名 CEffectEntry<NProject::CAddScientistTraitEffect>::[1] |
| 0x1404AA640 | CEffectEntry<CRemoveFromFactionEffect>::[1] func_names 名 CEffectEntry<CRemoveFromFactionEffect>::[1] |
| 0x14052C720 | CTriggerEntry<NDoctrines::CHasMasteryLevelTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CHasMasteryLevelTrigger>::[1] |
| 0x14033AD60 | CEffectEntry<CReleaseNationEffect<$00>>::[1] func_names 名 CEffectEntry<CReleaseNationEffect<$00>>::[1] |
| 0x14033ADC0 | CEffectEntry<CReleaseNationEffect<$0A>>::[1] func_names 名 CEffectEntry<CReleaseNationEffect<$0A>>::[1] |
| 0x14033AE20 | CEffectEntry<CReleasePuppetEffect<$00>>::[1] func_names 名 CEffectEntry<CReleasePuppetEffect<$00>>::[1] |
| 0x14033AE80 | CEffectEntry<CReleasePuppetEffect<$0A>>::[1] func_names 名 CEffectEntry<CReleasePuppetEffect<$0A>>::[1] |
| 0x1402E4BD0 | CEffectEntry<CAddLogisticsSkillEffect>::[1] func_names 名 CEffectEntry<CAddLogisticsSkillEffect>::[1] |
| 0x1402FA3D0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x14030C220 | CEffectEntry<CSetStateOwnerToEffect>::[1] func_names 名 CEffectEntry<CSetStateOwnerToEffect>::[1] |
| 0x14033B6B0 | CEffectEntry<CAddArmyExperienceEffect>::[1] func_names 名 CEffectEntry<CAddArmyExperienceEffect>::[1] |
| 0x14033B850 | CEffectEntry<CAddCollaborationEffect>::[1] func_names 名 CEffectEntry<CAddCollaborationEffect>::[1] |
| 0x14033BF50 | CEffectEntry<CAddNavyExperienceEffect>::[1] func_names 名 CEffectEntry<CAddNavyExperienceEffect>::[1] |
| 0x14033C0B0 | CEffectEntry<CAddPoliticalPowerEffect>::[1] func_names 名 CEffectEntry<CAddPoliticalPowerEffect>::[1] |
| 0x140340A60 | CEffectEntry<CRoundTempVariableEffect>::[1] func_names 名 CEffectEntry<CRoundTempVariableEffect>::[1] |
| 0x140341A10 | CEffectEntry<CSetPoliticalPowerEffect>::[1] func_names 名 CEffectEntry<CSetPoliticalPowerEffect>::[1] |
| 0x1404AA1A0 | CEffectEntry<CAddFactionGoalSlotEffect>::[1] func_names 名 CEffectEntry<CAddFactionGoalSlotEffect>::[1] |
| 0x14151F450 | CStatePeaceAction::IsSameTarget func_names 名 CStatePeaceAction::IsSameTarget |
| 0x14252F57C | collate<unsigned short,std>::[3] func_names 名 collate<unsigned short,std>::[3] |
| 0x1402E4C30 | CEffectEntry<CAddManeuverSkillEffect>::[1] func_names 名 CEffectEntry<CAddManeuverSkillEffect>::[1] |
| 0x1402E4CF0 | CEffectEntry<CAddPlanningSkillEffect>::[1] func_names 名 CEffectEntry<CAddPlanningSkillEffect>::[1] |
| 0x14033B0E0 | CEffectEntry<CSetOrAddVictoryPointsEffect<$00>>::[1] func_names 名 CEffectEntry<CSetOrAddVictoryPointsEffect<$00>>::[1] |
| 0x14033B140 | CEffectEntry<CSetOrAddVictoryPointsEffect<$0A>>::[1] func_names 名 CEffectEntry<CSetOrAddVictoryPointsEffect<$0A>>::[1] |
| 0x14033B650 | CEffectEntry<CAddAirExperienceEffect>::[1] func_names 名 CEffectEntry<CAddAirExperienceEffect>::[1] |
| 0x14033BFB0 | CEffectEntry<CAddNukeEffect>::[1] func_names 名 CEffectEntry<CAddNukeEffect>::[1] |
| 0x1403400A0 | CEffectEntry<CRemoveCivilWarTarget>::[1] func_names 名 CEffectEntry<CRemoveCivilWarTarget>::[1] |
| 0x140340650 | CEffectEntry<CRemoveStateClaimEffect>::[1] func_names 名 CEffectEntry<CRemoveStateClaimEffect>::[1] |
| 0x140492B40 | CEffectEntry<NProject::CAddScientistLevelEffect>::[1] func_names 名 CEffectEntry<NProject::CAddScientistLevelEffect>::[1] |
| 0x1402E08A0 | CTextBufferObserverGlue<CConsole>::[2] func_names 名 CTextBufferObserverGlue<CConsole>::[2] |
| 0x1402E0C60 | CTextBufferObserverGlue<CConsole>::[4] func_names 名 CTextBufferObserverGlue<CConsole>::[4] |
| 0x1402E0EE0 | CTextBufferObserverGlue<CConsole>::[1] func_names 名 CTextBufferObserverGlue<CConsole>::[1] |
| 0x1402E0F70 | CTextBufferObserverGlue<CConsole>::[8] func_names 名 CTextBufferObserverGlue<CConsole>::[8] |
| 0x1402E1020 | CTextBufferObserverGlue<CConsole>::[6] func_names 名 CTextBufferObserverGlue<CConsole>::[6] |
| 0x1402E10B0 | CTextBufferObserverGlue<CConsole>::[3] func_names 名 CTextBufferObserverGlue<CConsole>::[3] |
| 0x1402E4B70 | CEffectEntry<CAddDefenseSkillEffect>::[1] func_names 名 CEffectEntry<CAddDefenseSkillEffect>::[1] |
| 0x1402E4C90 | CEffectEntry<CAddMaxAssignableTrait>::[1] func_names 名 CEffectEntry<CAddMaxAssignableTrait>::[1] |
| 0x1402F13F0 | CSetCountryLeaderNamePortraitOrDescription<$00>::[4] func_names 名 CSetCountryLeaderNamePortraitOrDescription<$00>::[4] |
| 0x14033B1A0 | CEffectEntry<AddFuelEffect>::[1] func_names 名 CEffectEntry<AddFuelEffect>::[1] |
| 0x14033B8B0 | CEffectEntry<CAddCommandPowerEffect>::[1] func_names 名 CEffectEntry<CAddCommandPowerEffect>::[1] |
| 0x14033E730 | CEffectEntry<CGiveGuaranteeEffect>::[1] func_names 名 CEffectEntry<CGiveGuaranteeEffect>::[1] |
| 0x14033FE30 | CEffectEntry<CRecallAttacheEffect>::[1] func_names 名 CEffectEntry<CRecallAttacheEffect>::[1] |
| 0x1403419E0 | CEffectEntry<CSetPoliticalPartyEffect>::[1] func_names 名 CEffectEntry<CSetPoliticalPartyEffect>::[1] |
| 0x1403E3BF0 | CTriggerEntry<CCanBuildRailwayTrigger>::[1] func_names 名 CTriggerEntry<CCanBuildRailwayTrigger>::[1] |
| 0x14049B4B0 | CEffectEntry<CCreateEquipmentVariantEffect>::[1] func_names 名 CEffectEntry<CCreateEquipmentVariantEffect>::[1] |
| 0x1404A8980 | CTriggerEntry<CAnyCountryOfTrigger>::[1] func_names 名 CTriggerEntry<CAnyCountryOfTrigger>::[1] |
| 0x1404A89B0 | CTriggerEntry<CAnyCountryWithOriginalTagOfTrigger>::[1] func_names 名 CTriggerEntry<CAnyCountryWithOriginalTagOfTrigger>::[1] |
| 0x1416ACB10 | CTextBufferObserverGlue<CConsole>::[5] func_names 名 CTextBufferObserverGlue<CConsole>::[5] |
| 0x1416ACB30 | CTextBufferObserverGlue<CConsole>::[7] func_names 名 CTextBufferObserverGlue<CConsole>::[7] |
| 0x1416ACD60 | CTextBufferObserverGlue<CConsole>::[9] func_names 名 CTextBufferObserverGlue<CConsole>::[9] |
| 0x1402E5570 | CEffectEntry<CSupplyUnits>::[1] func_names 名 CEffectEntry<CSupplyUnits>::[1] |
| 0x14030BD20 | CEffectEntry<CRemoveCoreOfEffect>::[1] func_names 名 CEffectEntry<CRemoveCoreOfEffect>::[1] |
| 0x14033C230 | CEffectEntry<CAddRelationRuleOverrideEffect>::[1] func_names 名 CEffectEntry<CAddRelationRuleOverrideEffect>::[1] |
| 0x14033EA20 | CEffectEntry<CHoldElectionEffect>::[1] func_names 名 CEffectEntry<CHoldElectionEffect>::[1] |
| 0x1403405A0 | CEffectEntry<CRemoveResourceRights>::[1] func_names 名 CEffectEntry<CRemoveResourceRights>::[1] |
| 0x1403E53A0 | CTriggerEntry<CHasCapturedOperativeTrigger>::[1] func_names 名 CTriggerEntry<CHasCapturedOperativeTrigger>::[1] |
| 0x14043F120 | CTriggerEntry<NCareerProfile::CCheckRatio>::[1] func_names 名 CTriggerEntry<NCareerProfile::CCheckRatio>::[1] |
| 0x14049B690 | CEffectEntry<CSetEquipmentFraction>::[1] func_names 名 CEffectEntry<CSetEquipmentFraction>::[1] |
| 0x1404B4650 | CTriggerEntry<CFactionUpgradeLevel>::[1] func_names 名 CTriggerEntry<CFactionUpgradeLevel>::[1] |
| 0x1402E4E10 | CEffectEntry<CAddSkillLevelEffect>::[1] func_names 名 CEffectEntry<CAddSkillLevelEffect>::[1] |
| 0x14030B4B0 | CEffectEntry<CAddComplianceEffect>::[1] func_names 名 CEffectEntry<CAddComplianceEffect>::[1] |
| 0x14030B620 | CEffectEntry<CAddResistanceEffect>::[1] func_names 名 CEffectEntry<CAddResistanceEffect>::[1] |
| 0x14030BF90 | CEffectEntry<CSetComplianceEffect>::[1] func_names 名 CEffectEntry<CSetComplianceEffect>::[1] |
| 0x14030C050 | CEffectEntry<CSetResistanceEffect>::[1] func_names 名 CEffectEntry<CSetResistanceEffect>::[1] |
| 0x14033B7F0 | CEffectEntry<CAddCivilWarTarget>::[1] func_names 名 CEffectEntry<CAddCivilWarTarget>::[1] |
| 0x14033BD50 | CEffectEntry<CAddLegitimacyEffect>::[1] func_names 名 CEffectEntry<CAddLegitimacyEffect>::[1] |
| 0x14033C180 | CEffectEntry<CAddRegionEfficiency>::[1] func_names 名 CEffectEntry<CAddRegionEfficiency>::[1] |
| 0x14033C480 | CEffectEntry<CAddStateClaimEffect>::[1] func_names 名 CEffectEntry<CAddStateClaimEffect>::[1] |
| 0x14033C810 | CEffectEntry<CAddWarSupportEffect>::[1] func_names 名 CEffectEntry<CAddWarSupportEffect>::[1] |
| 0x14033CE60 | CEffectEntry<CClearVariableEffect>::[1] func_names 名 CEffectEntry<CClearVariableEffect>::[1] |
| 0x14033D980 | CEffectEntry<CDestroyEntityEffect>::[1] func_names 名 CEffectEntry<CDestroyEntityEffect>::[1] |
| 0x1403404D0 | CEffectEntry<CRemoveRelationModifierEffect>::[1] func_names 名 CEffectEntry<CRemoveRelationModifierEffect>::[1] |
| 0x140340AC0 | CEffectEntry<CRoundVariableEffect>::[1] func_names 名 CEffectEntry<CRoundVariableEffect>::[1] |
| 0x1403415C0 | CEffectEntry<CSetLegitimacyEffect>::[1] func_names 名 CEffectEntry<CSetLegitimacyEffect>::[1] |
| 0x140341D90 | CEffectEntry<CSetStateOwnerEffect>::[1] func_names 名 CEffectEntry<CSetStateOwnerEffect>::[1] |
| 0x140341FA0 | CEffectEntry<CSetWarSupportEffect>::[1] func_names 名 CEffectEntry<CSetWarSupportEffect>::[1] |
| 0x140342680 | CEffectEntry<CTransferStateEffect>::[1] func_names 名 CEffectEntry<CTransferStateEffect>::[1] |
| 0x1403BC9A0 | CEffectEntry<CMarkFocusTreeLayoutDirtyEffect>::[1] func_names 名 CEffectEntry<CMarkFocusTreeLayoutDirtyEffect>::[1] |
| 0x14045D400 | CEffectEntry<CSetUnitOrganization>::[1] func_names 名 CEffectEntry<CSetUnitOrganization>::[1] |
| 0x140492BE0 | CEffectEntry<NProject::CAddScientistXpEffect>::[1] func_names 名 CEffectEntry<NProject::CAddScientistXpEffect>::[1] |
| 0x1404A2290 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x14030B450 | CEffectEntry<CAddClaimByEffect>::[1] func_names 名 CEffectEntry<CAddClaimByEffect>::[1] |
| 0x14033C420 | CEffectEntry<CAddStabilityEffect>::[1] func_names 名 CEffectEntry<CAddStabilityEffect>::[1] |
| 0x14033C4E0 | CEffectEntry<CAddStateCoreEffect>::[1] func_names 名 CEffectEntry<CAddStateCoreEffect>::[1] |
| 0x1403414A0 | CEffectEntry<CSetFuelRatioEffect>::[1] func_names 名 CEffectEntry<CSetFuelRatioEffect>::[1] |
| 0x140341CD0 | CEffectEntry<CSetStabilityEffect>::[1] func_names 名 CEffectEntry<CSetStabilityEffect>::[1] |
| 0x14030B510 | CEffectEntry<CAddCoreOfEffect>::[1] func_names 名 CEffectEntry<CAddCoreOfEffect>::[1] |
| 0x14030C2E0 | CEffectEntry<CStartResistance>::[1] func_names 名 CEffectEntry<CStartResistance>::[1] |
| 0x14033CB60 | CEffectEntry<CChangeTagEffect>::[1] func_names 名 CEffectEntry<CChangeTagEffect>::[1] |
| 0x14033CF70 | CEffectEntry<CCreateColonialDivisionTemplateEffect>::[1] func_names 名 CEffectEntry<CCreateColonialDivisionTemplateEffect>::[1] |
| 0x14033DC60 | CEffectEntry<CEndPuppetEffect>::[1] func_names 名 CEffectEntry<CEndPuppetEffect>::[1] |
| 0x14033EFC0 | CEffectEntry<CManpowerAddEffect>::[1] func_names 名 CEffectEntry<CManpowerAddEffect>::[1] |
| 0x142004960 | CActiveContractsUiController::OpenCancelConfirmationPopup::lamb鈥� func_names 名 CActiveContractsUiController::OpenCancelConfirmationPopup::lamb鈥� |
| 0x14033C1E0 | CEffectEntry<CAddRelationModifierEffect>::[1] func_names 名 CEffectEntry<CAddRelationModifierEffect>::[1] |
| 0x14033DC00 | CEffectEntry<CEndExileEffect>::[1] func_names 名 CEffectEntry<CEndExileEffect>::[1] |
| 0x14033E590 | CEffectEntry<CFreeRandomOperativeEfect>::[1] func_names 名 CEffectEntry<CFreeRandomOperativeEfect>::[1] |
| 0x1403E61E0 | CTriggerEntry<CHasMinesTrigger>::[1] func_names 名 CTriggerEntry<CHasMinesTrigger>::[1] |
| 0x1404A24C0 | CTriggerEntry<NProject::CIsProjectBeingResearchedTrigger>::[1] func_names 名 CTriggerEntry<NProject::CIsProjectBeingResearchedTrigger>::[1] |
| 0x14033DBA0 | CEffectEntry<CEmbargoEffect>::[1] func_names 名 CEffectEntry<CEmbargoEffect>::[1] |
| 0x140341380 | CEffectEntry<CSetEntityRotationEffect>::[1] func_names 名 CEffectEntry<CSetEntityRotationEffect>::[1] |
| 0x1404576A0 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x14033AA80 | CEffectEntry<CClearArrayEffectImp<$0A>>::[1] func_names 名 CEffectEntry<CClearArrayEffectImp<$0A>>::[1] |
| 0x140340F30 | CEffectEntry<CSetCollaborationEffect>::[1] func_names 名 CEffectEntry<CSetCollaborationEffect>::[1] |
| 0x1403E6580 | CTriggerEntry<CHasOperationTokenTrigger>::[1] func_names 名 CTriggerEntry<CHasOperationTokenTrigger>::[1] |
| 0x1402E5010 | CEffectEntry<CBoostPlanning>::[1] func_names 名 CEffectEntry<CBoostPlanning>::[1] |
| 0x140341440 | CEffectEntry<CSetFuelEffect>::[1] func_names 名 CEffectEntry<CSetFuelEffect>::[1] |
| 0x1403E3F50 | CTriggerEntry<CClearTempArrayTrigger>::[1] func_names 名 CTriggerEntry<CClearTempArrayTrigger>::[1] |
| 0x140444F20 | CTriggerEntry<CIsLeadingArmyInProvince>::[1] func_names 名 CTriggerEntry<CIsLeadingArmyInProvince>::[1] |
| 0x140457750 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x141022D20 | CConvoys::CalcRequiredConvoysForInternationalMarketEquipment::l鈥� func_names 名 CConvoys::CalcRequiredConvoysForInternationalMarketEquipment::l鈥� |
| 0x14033CFC0 | CEffectEntry<CCreateDynamicCountry>::[1] func_names 名 CEffectEntry<CCreateDynamicCountry>::[1] |
| 0x1403413E0 | CEffectEntry<CSetEntityScaleEffect>::[1] func_names 名 CEffectEntry<CSetEntityScaleEffect>::[1] |
| 0x1403416E0 | CEffectEntry<CSetNationalityEffect>::[1] func_names 名 CEffectEntry<CSetNationalityEffect>::[1] |
| 0x141339650 | CTextBufferObserverGlue<CChat>::[5] func_names 名 CTextBufferObserverGlue<CChat>::[5] |
| 0x141339670 | CTextBufferObserverGlue<CChat>::[7] func_names 名 CTextBufferObserverGlue<CChat>::[7] |
| 0x140120560 | CPdxHybridInlineBufferAllocator<H$09H>::[1] func_names 名 CPdxHybridInlineBufferAllocator<H$09H>::[1] |
| 0x1402CDE90 | CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[1] func_names 名 CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[1] |
| 0x1403E5240 | CTriggerEntry<CHasBorderWarBetween>::[1] func_names 名 CTriggerEntry<CHasBorderWarBetween>::[1] |
| 0x1403E7100 | CTriggerEntry<CHasWargoalAgainst>::[1] func_names 名 CTriggerEntry<CHasWargoalAgainst>::[1] |
| 0x1412D4FD0 | CTextBufferObserverGlue<CChat>::[2] func_names 名 CTextBufferObserverGlue<CChat>::[2] |
| 0x1412D4FF0 | CTextBufferObserverGlue<CChat>::[4] func_names 名 CTextBufferObserverGlue<CChat>::[4] |
| 0x1412D5050 | CTextBufferObserverGlue<CChat>::[6] func_names 名 CTextBufferObserverGlue<CChat>::[6] |
| 0x1412D5070 | CTextBufferObserverGlue<CChat>::[3] func_names 名 CTextBufferObserverGlue<CChat>::[3] |
| 0x1403037C0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140476140 | CTriggerEntry<CMinPlanningTrigger>::[1] func_names 名 CTriggerEntry<CMinPlanningTrigger>::[1] |
| 0x1412D5010 | CTextBufferObserverGlue<CChat>::[1] func_names 名 CTextBufferObserverGlue<CChat>::[1] |
| 0x1412D5030 | CTextBufferObserverGlue<CChat>::[8] func_names 名 CTextBufferObserverGlue<CChat>::[8] |
| 0x141754060 | CScrollbarObserverGlue<CSmoothListbox>::[4] func_names 名 CScrollbarObserverGlue<CSmoothListbox>::[4] |
| 0x141754080 | CScrollbarObserverGlue<CSmoothListbox>::[3] func_names 名 CScrollbarObserverGlue<CSmoothListbox>::[3] |
| 0x1417540A0 | CScrollbarObserverGlue<CSmoothListbox>::[2] func_names 名 CScrollbarObserverGlue<CSmoothListbox>::[2] |
| 0x141870700 | CChatMessageObserverGlue<CPlayerLobby>::[1] func_names 名 CChatMessageObserverGlue<CPlayerLobby>::[1] |
| 0x140340EE0 | CEffectEntry<CSetCapitalEffect>::[1] func_names 名 CEffectEntry<CSetCapitalEffect>::[1] |
| 0x1404439D0 | CIsNavyLeader::Evaluate func_names 名 CIsNavyLeader::Evaluate |
| 0x140443A50 | CIsOperative::Evaluate func_names 名 CIsOperative::Evaluate |
| 0x1403302F0 | CRandomizeVariableEffect<CVariableResolver>::[0] func_names 名 CRandomizeVariableEffect<CVariableResolver>::[0] |
| 0x14035BE70 | CRandomScopeInArray::Execute func_names 名 CRandomScopeInArray::Execute |
| 0x140442770 | CIsArmyLeader::Evaluate func_names 名 CIsArmyLeader::Evaluate |
| 0x140457650 | CTriggerEntry<NIndustrialOrganisation::CIsAssignedToTaskTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CIsAssignedToTaskTrigger>::[1] |
| 0x1403B3640 | CFreeRandomOperativeEfect::ParseToken func_names 名 CFreeRandomOperativeEfect::ParseToken |
| 0x1403E6180 | CTriggerEntry<CHasMinedTrigger>::[1] func_names 名 CTriggerEntry<CHasMinedTrigger>::[1] |
| 0x1403E7A20 | CTriggerEntry<CIsInTechnologySharingGroupTrigger>::[1] func_names 名 CTriggerEntry<CIsInTechnologySharingGroupTrigger>::[1] |
| 0x142527E38 | numpunct<unsigned short,std>::[0] func_names 名 numpunct<unsigned short,std>::[0] |
| 0x14033BDB0 | CEffectEntry<CAddMinesEffect>::[1] func_names 名 CEffectEntry<CAddMinesEffect>::[1] |
| 0x14049B6F0 | CEffectEntry<CSetEquipmentVersionNumber>::[1] func_names 名 CEffectEntry<CSetEquipmentVersionNumber>::[1] |
| 0x1404A73C0 | CTriggerEntry<CHasContestedOwner>::[1] func_names 名 CTriggerEntry<CHasContestedOwner>::[1] |
| 0x1405276C0 | CEffectEntry<CSetStrategicProvinceLocationBuildingLevel>::[1] func_names 名 CEffectEntry<CSetStrategicProvinceLocationBuildingLevel>::[1] |
| 0x140F029F0 | CFrontSection::SPerCountrySection::Writer func_names 名 CFrontSection::SPerCountrySection::Writer |
| 0x141DF4320 | CMapModeMilitaryDeploymentToOrder::HandleVariousMapClicks::lamb鈥� func_names 名 CMapModeMilitaryDeploymentToOrder::HandleVariousMapClicks::lamb鈥� |
| 0x142398A50 | CCallback<鈥�>::[3] func_names 名 CCallback<鈥�>::[3] |
| 0x142398BE0 | CCallbackImpl<$0JI>::[3] func_names 名 CCallbackImpl<$0JI>::[3] |
| 0x1424BA260 | CCallbackImpl<$0BAI>::[3] func_names 名 CCallbackImpl<$0BAI>::[3] |
| 0x140492C30 | CEffectEntry<NProject::CClearProjectFlagEffect>::[1] func_names 名 CEffectEntry<NProject::CClearProjectFlagEffect>::[1] |
| 0x1419765D0 | CFEXMember::SReceivedDamageData::Writer func_names 名 CFEXMember::SReceivedDamageData::Writer |
| 0x142398B40 | CCallbackImpl<$0BA>::[3] func_names 名 CCallbackImpl<$0BA>::[3] |
| 0x142398B90 | CCallbackImpl<$0BI>::[3] func_names 名 CCallbackImpl<$0BI>::[3] |
| 0x1423C25E0 | CCallbackImpl<$0CI>::[3] func_names 名 CCallbackImpl<$0CI>::[3] |
| 0x1423C2630 | CCallbackImpl<$0DI>::[3] func_names 名 CCallbackImpl<$0DI>::[3] |
| 0x1423E02E0 | CCallbackImpl<$0BE>::[3] func_names 名 CCallbackImpl<$0BE>::[3] |
| 0x14031F130 | CEffectEntry<CRemoveFromTechnologySharingGroupEffect>::[1] func_names 名 CEffectEntry<CRemoveFromTechnologySharingGroupEffect>::[1] |
| 0x140527710 | CEffectEntry<CSetStrategicStateLocationBuildingLevel>::[1] func_names 名 CEffectEntry<CSetStrategicStateLocationBuildingLevel>::[1] |
| 0x14052C590 | CTriggerEntry<NDoctrines::CDoctrineTrackCompletedTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CDoctrineTrackCompletedTrigger>::[1] |
| 0x1423C2540 | CCallbackImpl<$03>::[3] func_names 名 CCallbackImpl<$03>::[3] |
| 0x1423C2590 | CCallbackImpl<$07>::[3] func_names 名 CCallbackImpl<$07>::[3] |
| 0x1423E74B0 | CCallbackImpl<$00>::[3] func_names 名 CCallbackImpl<$00>::[3] |
| 0x1423E7500 | CCallbackImpl<$08>::[3] func_names 名 CCallbackImpl<$08>::[3] |
| 0x14048CC40 | CTriggerEntry<CPcDoesStateStackDismantledTrigger>::[1] func_names 名 CTriggerEntry<CPcDoesStateStackDismantledTrigger>::[1] |
| 0x140340430 | CEffectEntry<CRemoveOperationTokenEffect>::[1] func_names 名 CEffectEntry<CRemoveOperationTokenEffect>::[1] |
| 0x140445100 | CTriggerEntry<CIsPromotedFromUnit>::[1] func_names 名 CTriggerEntry<CIsPromotedFromUnit>::[1] |
| 0x14045D090 | CEffectEntry<CAddRandomValidUnitLeaderTraitEffect>::[1] func_names 名 CEffectEntry<CAddRandomValidUnitLeaderTraitEffect>::[1] |
| 0x1404A2510 | CTriggerEntry<NProject::CIsProjectCompletedTrigger>::[1] func_names 名 CTriggerEntry<NProject::CIsProjectCompletedTrigger>::[1] |
| 0x140529470 | CEffectEntry<NDoctrines::CUnlockCombatTacticEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CUnlockCombatTacticEffect>::[1] |
| 0x1415B9720 | CNavyTheaterGroup::CreateNewId func_names 名 CNavyTheaterGroup::CreateNewId |
| 0x14033EAD0 | CEffectEntry<CKillIdeologyLeaderEffect>::[1] func_names 名 CEffectEntry<CKillIdeologyLeaderEffect>::[1] |
| 0x140467FE0 | CTriggerEntry<CDistanceToTrigger>::[1] func_names 名 CTriggerEntry<CDistanceToTrigger>::[1] |
| 0x1404AA740 | CEffectEntry<CSetFactionMemberUpgradeMin>::[1] func_names 名 CEffectEntry<CSetFactionMemberUpgradeMin>::[1] |
| 0x1404AA840 | CEffectEntry<CSetFactionResearhUnlockedEffect>::[1] func_names 名 CEffectEntry<CSetFactionResearhUnlockedEffect>::[1] |
| 0x140DDA560 | CInGameIdler::Update func_names 名 CInGameIdler::Update |
| 0x14033E090 | CEffectEntry<CExecuteOperationCoordinatedStrike>::[1] func_names 名 CEffectEntry<CExecuteOperationCoordinatedStrike>::[1] |
| 0x140341830 | CEffectEntry<CSetOccupationLawWhereAvailableEffect>::[1] func_names 名 CEffectEntry<CSetOccupationLawWhereAvailableEffect>::[1] |
| 0x140457290 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x14052C5E0 | CTriggerEntry<NDoctrines::CHasCombatTacticTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CHasCombatTacticTrigger>::[1] |
| 0x14031F030 | CEffectEntry<CAddToTechnologySharingGroupEffect>::[1] func_names 名 CEffectEntry<CAddToTechnologySharingGroupEffect>::[1] |
| 0x14033CD20 | CEffectEntry<CClearGlobalEventTargetsEffect>::[1] func_names 名 CEffectEntry<CClearGlobalEventTargetsEffect>::[1] |
| 0x1403E52F0 | CTriggerEntry<CHasBuilt>::[1] func_names 名 CTriggerEntry<CHasBuilt>::[1] |
| 0x1404B46A0 | CTriggerEntry<CHasEnoughInfluenceForLeadershipTrigger>::[1] func_names 名 CTriggerEntry<CHasEnoughInfluenceForLeadershipTrigger>::[1] |
| 0x141130A40 | CCancelForeignManpowerAction::CanExecute func_names 名 CCancelForeignManpowerAction::CanExecute |
| 0x14015EED0 | numpunct<char,std>::[0] func_names 名 numpunct<char,std>::[0] |
| 0x1402F8D10 | CTriggerEntry<CHasAnyCapturedGeneralTrigger>::[1] func_names 名 CTriggerEntry<CHasAnyCapturedGeneralTrigger>::[1] |
| 0x140475F50 | CTriggerEntry<CIsFightingInStrategicRegionTrigger>::[1] func_names 名 CTriggerEntry<CIsFightingInStrategicRegionTrigger>::[1] |
| 0x14052C680 | CTriggerEntry<NDoctrines::CHasDoctrineTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CHasDoctrineTrigger>::[1] |
| 0x1403E4E90 | CTriggerEntry<CHasAnyCountryCustomDifficultyTrigger>::[1] func_names 名 CTriggerEntry<CHasAnyCountryCustomDifficultyTrigger>::[1] |
| 0x1403EE2C0 | CNumFactionMembers::GetValue func_names 名 CNumFactionMembers::GetValue |
| 0x140475B70 | CTriggerEntry<CHasCarrierAirWingsInOwnCombatTrigger>::[1] func_names 名 CTriggerEntry<CHasCarrierAirWingsInOwnCombatTrigger>::[1] |
| 0x14048CBF0 | CTriggerEntry<CPcDoesStateStackDemilitarizedTrigger>::[1] func_names 名 CTriggerEntry<CPcDoesStateStackDemilitarizedTrigger>::[1] |
| 0x140492EE0 | CEffectEntry<NProject::CModifyProjectFlagEffect>::[1] func_names 名 CEffectEntry<NProject::CModifyProjectFlagEffect>::[1] |
| 0x1405294C0 | CEffectEntry<NDoctrines::CUnlockSubUnitEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CUnlockSubUnitEffect>::[1] |
| 0x14052C6D0 | CTriggerEntry<NDoctrines::CHasGrandDoctrineInFolderTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CHasGrandDoctrineInFolderTrigger>::[1] |
| 0x1422DECF0 | CGridBoxBase::[7] vtable 槽 CGridBoxBase::[7]（func_names RTTI 名） |
| 0x1404A22E0 | CTriggerEntry<NProject::CHasBreakthroughPointsTrigger>::[1] func_names 名 CTriggerEntry<NProject::CHasBreakthroughPointsTrigger>::[1] |
| 0x14052C630 | CTriggerEntry<NDoctrines::CHasCompletedSubdoctrineTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CHasCompletedSubdoctrineTrigger>::[1] |
| 0x141127400 | CTransferSpyMasterAction::GetCostText func_names 名 CTransferSpyMasterAction::GetCostText |
| 0x1402F9D30 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1403417E0 | CEffectEntry<CSetOccupationLawEffect>::[1] func_names 名 CEffectEntry<CSetOccupationLawEffect>::[1] |
| 0x1403E5860 | CTriggerEntry<CHasCreateIntelligenceAgencyTrigger>::[1] func_names 名 CTriggerEntry<CHasCreateIntelligenceAgencyTrigger>::[1] |
| 0x140475BC0 | CTriggerEntry<CHasCarrierAirWingsOnMissionTrigger>::[1] func_names 名 CTriggerEntry<CHasCarrierAirWingsOnMissionTrigger>::[1] |
| 0x1404760F0 | CTriggerEntry<CLessCombatWidthThanOpponentTrigger>::[1] func_names 名 CTriggerEntry<CLessCombatWidthThanOpponentTrigger>::[1] |
| 0x1404A2560 | CTriggerEntry<NProject::CIsScientistActiveTrigger>::[1] func_names 名 CTriggerEntry<NProject::CIsScientistActiveTrigger>::[1] |
| 0x1402F9C60 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x1403409C0 | CEffectEntry<CRetireIdeologyLeaderEffect>::[1] func_names 名 CEffectEntry<CRetireIdeologyLeaderEffect>::[1] |
| 0x140342050 | CEffectEntry<CShowUnitLeadersTooltipEffect>::[1] func_names 名 CEffectEntry<CShowUnitLeadersTooltipEffect>::[1] |
| 0x1403E5BD0 | CTriggerEntry<CHasEnoughManpowerForRecruitChangeTrigger>::[1] func_names 名 CTriggerEntry<CHasEnoughManpowerForRecruitChangeTrigger>::[1] |
| 0x1403E7870 | CTriggerEntry<CIsHostingGovernmentInExileTrigger>::[1] func_names 名 CTriggerEntry<CIsHostingGovernmentInExileTrigger>::[1] |
| 0x1404680E0 | CTriggerEntry<CHasBorderConflictTrigger>::[1] func_names 名 CTriggerEntry<CHasBorderConflictTrigger>::[1] |
| 0x140492EA0 | CEffectEntry<NProject::CInjureScientistEffect>::[1] func_names 名 CEffectEntry<NProject::CInjureScientistEffect>::[1] |
| 0x140493020 | CEffectEntry<NProject::CSetProjectFlagEffect>::[1] func_names 名 CEffectEntry<NProject::CSetProjectFlagEffect>::[1] |
| 0x14052C770 | CTriggerEntry<NDoctrines::CHasSubdoctrineInTrackTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CHasSubdoctrineInTrackTrigger>::[1] |
| 0x14052C7C0 | CTriggerEntry<NDoctrines::CMasteryTrigger>::[1] func_names 名 CTriggerEntry<NDoctrines::CMasteryTrigger>::[1] |
| 0x14033A960 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140445290 | CTriggerEntry<COperativeLeaderMissionTrigger>::[1] func_names 名 CTriggerEntry<COperativeLeaderMissionTrigger>::[1] |
| 0x140468510 | CTriggerEntry<CIsOneStateIslandTrigger>::[1] func_names 名 CTriggerEntry<CIsOneStateIslandTrigger>::[1] |
| 0x1404AA790 | CEffectEntry<CSetFactionMilitaryUnlockedEffect>::[1] func_names 名 CEffectEntry<CSetFactionMilitaryUnlockedEffect>::[1] |
| 0x1404B4830 | CTriggerEntry<CHasIndustryToBecomeLeaderTrigger>::[1] func_names 名 CTriggerEntry<CHasIndustryToBecomeLeaderTrigger>::[1] |
| 0x1404B4880 | CTriggerEntry<CHasManpowerToBecomeLeaderTrigger>::[1] func_names 名 CTriggerEntry<CHasManpowerToBecomeLeaderTrigger>::[1] |
| 0x1404B9080 | CTriggerEntry<CIsOnSameContinentAsTrigger>::[1] func_names 名 CTriggerEntry<CIsOnSameContinentAsTrigger>::[1] |
| 0x1402FA0D0 | CEffectEntry<鈥�>::[1] func_names 名 CEffectEntry<鈥�>::[1] |
| 0x140340600 | CEffectEntry<CRemoveScientistRoleEffect>::[1] func_names 名 CEffectEntry<CRemoveScientistRoleEffect>::[1] |
| 0x1403E52A0 | CTriggerEntry<CHasBorderWarWith>::[1] func_names 名 CTriggerEntry<CHasBorderWarWith>::[1] |
| 0x1403E64B0 | CTriggerEntry<CHasOffensiveWarTrigger>::[1] func_names 名 CTriggerEntry<CHasOffensiveWarTrigger>::[1] |
| 0x1403E75F0 | CTriggerEntry<CIsFactionLeaderTrigger>::[1] func_names 名 CTriggerEntry<CIsFactionLeaderTrigger>::[1] |
| 0x14033DAC0 | CEffectEntry<CDivideTempVariableEffect>::[1] func_names 名 CEffectEntry<CDivideTempVariableEffect>::[1] |
| 0x140340380 | CEffectEntry<CRemoveMilitaryRoleEffect>::[1] func_names 名 CEffectEntry<CRemoveMilitaryRoleEffect>::[1] |
| 0x1403E9380 | CTriggerEntry<CRoundTempVariableTrigger>::[1] func_names 名 CTriggerEntry<CRoundTempVariableTrigger>::[1] |
| 0x140475B20 | CTriggerEntry<CHasArtilleryRatioTrigger>::[1] func_names 名 CTriggerEntry<CHasArtilleryRatioTrigger>::[1] |
| 0x1404B47E0 | CTriggerEntry<CHasFactionTemplateTrigger>::[1] func_names 名 CTriggerEntry<CHasFactionTemplateTrigger>::[1] |
| 0x141022D10 | CConvoys::CalcRequiredConvoysForInternationalMarketEquipment::l鈥� func_names 名 CConvoys::CalcRequiredConvoysForInternationalMarketEquipment::l鈥� |
| 0x141392F20 | CEffectEntry<CCustomEffectTooltipEffect>::[1] func_names 名 CEffectEntry<CCustomEffectTooltipEffect>::[1] |
| 0x142386B90 | TOverlappingElementsBox<CStandardlistboxItem>::[7] func_names 名 TOverlappingElementsBox<CStandardlistboxItem>::[7] |
| 0x14033C010 | CEffectEntry<CAddOperationTokenEffect>::[1] func_names 名 CEffectEntry<CAddOperationTokenEffect>::[1] |
| 0x1403E41C0 | CTriggerEntry<CControlsProvinceTrigger>::[1] func_names 名 CTriggerEntry<CControlsProvinceTrigger>::[1] |
| 0x1403E4EE0 | CTriggerEntry<CHasAnyCustomDifficultyTrigger>::[1] func_names 名 CTriggerEntry<CHasAnyCustomDifficultyTrigger>::[1] |
| 0x1403E4F30 | CTriggerEntry<CHasAnyLicenseTrigger>::[1] func_names 名 CTriggerEntry<CHasAnyLicenseTrigger>::[1] |
| 0x1403E6CF0 | CTriggerEntry<CHasTemplateWithAIMajorityUnitTrigger>::[1] func_names 名 CTriggerEntry<CHasTemplateWithAIMajorityUnitTrigger>::[1] |
| 0x1403E8B10 | CTriggerEntry<鈥�>::[1] func_names 名 CTriggerEntry<鈥�>::[1] |
| 0x140C1B050 | CNavyLeader::UpdateLocalizedName func_names 名 CNavyLeader::UpdateLocalizedName |
| 0x1403424D0 | CEffectEntry<CSwapRulerTraitsEffect>::[1] func_names 名 CEffectEntry<CSwapRulerTraitsEffect>::[1] |
| 0x1403E7390 | CTriggerEntry<CIsCryptologyDepartmentActive>::[1] func_names 名 CTriggerEntry<CIsCryptologyDepartmentActive>::[1] |
| 0x14045A610 | CTriggerEntry<NInternationalMarket::CHasMarketAccessWithTrigger>::[1] func_names 名 CTriggerEntry<NInternationalMarket::CHasMarketAccessWithTrigger>::[1] |
| 0x140475C10 | CTriggerEntry<CHasCavalryRatioTrigger>::[1] func_names 名 CTriggerEntry<CHasCavalryRatioTrigger>::[1] |
| 0x140475C60 | CTriggerEntry<CHasCombatModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasCombatModifierTrigger>::[1] |
| 0x1404A25B0 | CTriggerEntry<NProject::CIsScientistInjured>::[1] func_names 名 CTriggerEntry<NProject::CIsScientistInjured>::[1] |
| 0x14031F180 | CEffectEntry<CSelectTechTreeIconOrigin>::[1] func_names 名 CEffectEntry<CSelectTechTreeIconOrigin>::[1] |
| 0x140340850 | CEffectEntry<CReserveDynamicCountryEffect>::[1] func_names 名 CEffectEntry<CReserveDynamicCountryEffect>::[1] |
| 0x140342000 | CEffectEntry<CShowIdeasTooltipEffect>::[1] func_names 名 CEffectEntry<CShowIdeasTooltipEffect>::[1] |
| 0x1403E2BB0 | CTriggerEntry<CAIHasRoleDivisionTrigger>::[1] func_names 名 CTriggerEntry<CAIHasRoleDivisionTrigger>::[1] |
| 0x1403E2C00 | CTriggerEntry<CAIHasRoleTemplateTrigger>::[1] func_names 名 CTriggerEntry<CAIHasRoleTemplateTrigger>::[1] |
| 0x1403E4290 | CTriggerEntry<CCoreComplianceTrigger>::[1] func_names 名 CTriggerEntry<CCoreComplianceTrigger>::[1] |
| 0x1403E42E0 | CTriggerEntry<CCoreResistanceTrigger>::[1] func_names 名 CTriggerEntry<CCoreResistanceTrigger>::[1] |
| 0x1403E5E30 | CTriggerEntry<CHasGovernmentTrigger>::[1] func_names 名 CTriggerEntry<CHasGovernmentTrigger>::[1] |
| 0x1403E6D40 | CTriggerEntry<CHasTemplateWithMajorityUnitTrigger>::[1] func_names 名 CTriggerEntry<CHasTemplateWithMajorityUnitTrigger>::[1] |
| 0x140444ED0 | CTriggerEntry<CIsLeadingArmyGroup>::[1] func_names 名 CTriggerEntry<CIsLeadingArmyGroup>::[1] |
| 0x140475E10 | CTriggerEntry<CIsAmphibiousInvasionTrigger>::[1] func_names 名 CTriggerEntry<CIsAmphibiousInvasionTrigger>::[1] |
| 0x14048CD20 | CTriggerEntry<CPcIsForcedGovernmentTrigger>::[1] func_names 名 CTriggerEntry<CPcIsForcedGovernmentTrigger>::[1] |
| 0x1405293C0 | CEffectEntry<NDoctrines::CSetGrandDoctrineEffect>::[1] func_names 名 CEffectEntry<NDoctrines::CSetGrandDoctrineEffect>::[1] |
| 0x140AEB9F0 | SParentKeyReader<CUnitLeaderTrait::SParentKey>::Reader func_names 名 SParentKeyReader<CUnitLeaderTrait::SParentKey>::Reader |
| 0x1401ADA90 | boost::signals2::23::Vmutex::3::Z::signal<鈥�>::[1] func_names 名 boost::signals2::23::Vmutex::3::Z::signal<鈥�>::[1] |
| 0x1402F7EF0 | CEffectEntry<CReleaseFromCaptivityEffect>::[1] func_names 名 CEffectEntry<CReleaseFromCaptivityEffect>::[1] |
| 0x14033E450 | CEffectEntry<CForceRecalcModifiersEffect>::[1] func_names 名 CEffectEntry<CForceRecalcModifiersEffect>::[1] |
| 0x1403E4C30 | CTriggerEntry<CGameRulesAllowAchievements>::[1] func_names 名 CTriggerEntry<CGameRulesAllowAchievements>::[1] |
| 0x1403E7750 | CTriggerEntry<CIsGovernmentInExileTrigger>::[1] func_names 名 CTriggerEntry<CIsGovernmentInExileTrigger>::[1] |
| 0x1403E79D0 | CTriggerEntry<CIsInPeaceConferenceTrigger>::[1] func_names 名 CTriggerEntry<CIsInPeaceConferenceTrigger>::[1] |
| 0x140445060 | CTriggerEntry<CIsOperativeCapturedTrigger>::[1] func_names 名 CTriggerEntry<CIsOperativeCapturedTrigger>::[1] |
| 0x140468860 | CTriggerEntry<COwnsAnyStateOfTrigger>::[1] func_names 名 CTriggerEntry<COwnsAnyStateOfTrigger>::[1] |
| 0x140475E60 | CTriggerEntry<CIsAttackerTrigger>::[1] func_names 名 CTriggerEntry<CIsAttackerTrigger>::[1] |
| 0x1404AA6F0 | CEffectEntry<CSetFactionManifestEffect>::[1] func_names 名 CEffectEntry<CSetFactionManifestEffect>::[1] |
| 0x1404B4740 | CTriggerEntry<CHasFactionMilitaryUnlocked>::[1] func_names 名 CTriggerEntry<CHasFactionMilitaryUnlocked>::[1] |
| 0x1404B4790 | CTriggerEntry<CHasFactionResearchUnlocked>::[1] func_names 名 CTriggerEntry<CHasFactionResearchUnlocked>::[1] |
| 0x141755A40 | CDiplomacyPopupWindowBase::Update func_names 名 CDiplomacyPopupWindowBase::Update |
| 0x1402E5340 | CEffectEntry<CRemoveUnitLeaderEffect>::[1] func_names 名 CEffectEntry<CRemoveUnitLeaderEffect>::[1] |
| 0x140340970 | CEffectEntry<CRetireCountryLeaderEffect>::[1] func_names 名 CEffectEntry<CRetireCountryLeaderEffect>::[1] |
| 0x1403DA800 | CIsCryptologyDepartmentActive::Evaluate func_names 名 CIsCryptologyDepartmentActive::Evaluate |
| 0x1403E5430 | CTriggerEntry<CHasCharacterTrigger>::[1] func_names 名 CTriggerEntry<CHasCharacterTrigger>::[1] |
| 0x1403E6C40 | CTriggerEntry<CHasTemplateContainingUnitTrigger>::[1] func_names 名 CTriggerEntry<CHasTemplateContainingUnitTrigger>::[1] |
| 0x140444B80 | CTriggerEntry<CIsCorpsCommander>::[1] func_names 名 CTriggerEntry<CIsCorpsCommander>::[1] |
| 0x140475CB0 | CTriggerEntry<CHasFlankedOpponentTrigger>::[1] func_names 名 CTriggerEntry<CHasFlankedOpponentTrigger>::[1] |
| 0x140475F00 | CTriggerEntry<CIsFightingAirUnitsTrigger>::[1] func_names 名 CTriggerEntry<CIsFightingAirUnitsTrigger>::[1] |
| 0x140488EA0 | CTriggerEntry<CHasAnyPowerBalanceTrigger>::[1] func_names 名 CTriggerEntry<CHasAnyPowerBalanceTrigger>::[1] |
| 0x1404AA890 | CEffectEntry<CSetFactionRuleEffect>::[1] func_names 名 CEffectEntry<CSetFactionRuleEffect>::[1] |
| 0x1404AA8E0 | CEffectEntry<CSetFactionSpyMasterEffect>::[1] func_names 名 CEffectEntry<CSetFactionSpyMasterEffect>::[1] |
| 0x1404B8C30 | CFactionGoalFulfillment::ParseToken func_names 名 CFactionGoalFulfillment::ParseToken |
| 0x141538D20 | CEquipmentUpgrade::CUpgradeCost::Reader func_names 名 CEquipmentUpgrade::CUpgradeCost::Reader |
| 0x1402F8DA0 | CTriggerEntry<CIsGeneralCapturedTrigger>::[1] func_names 名 CTriggerEntry<CIsGeneralCapturedTrigger>::[1] |
| 0x1402F8DF0 | CTriggerEntry<CIsGeneralDeployedTrigger>::[1] func_names 名 CTriggerEntry<CIsGeneralDeployedTrigger>::[1] |
| 0x1403E3BA0 | CTriggerEntry<CCanBeCountryleader>::[1] func_names 名 CTriggerEntry<CCanBeCountryleader>::[1] |
| 0x1403E7EF0 | CTriggerEntry<CIsPuppetTrigger>::[1] func_names 名 CTriggerEntry<CIsPuppetTrigger>::[1] |
| 0x140442D70 | CIsExileLeader::Evaluate func_names 名 CIsExileLeader::Evaluate |
| 0x140444B30 | CTriggerEntry<CIsCharacterTrigger>::[1] func_names 名 CTriggerEntry<CIsCharacterTrigger>::[1] |
| 0x140468620 | CTriggerEntry<CNonDamagedBuildingLevelTrigger>::[1] func_names 名 CTriggerEntry<CNonDamagedBuildingLevelTrigger>::[1] |
| 0x14048CE50 | CTriggerEntry<CPcIsOnWinningSideTrigger>::[1] func_names 名 CTriggerEntry<CPcIsOnWinningSideTrigger>::[1] |
| 0x141974D50 | CFEXMember::CLastTargetInfo::Reader func_names 名 CFEXMember::CLastTargetInfo::Reader |
| 0x141F7D220 | CConfirmDisbandFleet::Update func_names 名 CConfirmDisbandFleet::Update |
| 0x14033EA80 | CEffectEntry<CKillCountryLeaderEffect>::[1] func_names 名 CEffectEntry<CKillCountryLeaderEffect>::[1] |
| 0x140341030 | CEffectEntry<CSetCountryLeaderIdeologyEffect>::[1] func_names 名 CEffectEntry<CSetCountryLeaderIdeologyEffect>::[1] |
| 0x1403AF260 | CAddAutonomyRatio::ParseToken func_names 名 CAddAutonomyRatio::ParseToken |
| 0x1403E4490 | CTriggerEntry<CCountTriggersTrigger>::[1] func_names 名 CTriggerEntry<CCountTriggersTrigger>::[1] |
| 0x1403E4600 | CTriggerEntry<CDamagedBuildingsTrigger>::[1] func_names 名 CTriggerEntry<CDamagedBuildingsTrigger>::[1] |
| 0x1403E6E40 | CTriggerEntry<CHasUnitLeaderTrigger>::[1] func_names 名 CTriggerEntry<CHasUnitLeaderTrigger>::[1] |
| 0x1403E74E0 | CTriggerEntry<CIsDynamicCountryTrigger>::[1] func_names 名 CTriggerEntry<CIsDynamicCountryTrigger>::[1] |
| 0x14045A540 | CTriggerEntry<NInternationalMarket::CBuyerTrigger>::[1] func_names 名 CTriggerEntry<NInternationalMarket::CBuyerTrigger>::[1] |
| 0x14045A5D0 | CTriggerEntry<NInternationalMarket::CDealCompletionTrigger>::[1] func_names 名 CTriggerEntry<NInternationalMarket::CDealCompletionTrigger>::[1] |
| 0x14045D270 | CEffectEntry<CPromoteOfficerToGeneral>::[1] func_names 名 CEffectEntry<CPromoteOfficerToGeneral>::[1] |
| 0x14048CFB0 | CTriggerEntry<CPcIsStateClaimedTrigger>::[1] func_names 名 CTriggerEntry<CPcIsStateClaimedTrigger>::[1] |
| 0x1404B4290 | CTriggerEntry<CCountryHasCompletedGoalTrigger>::[1] func_names 名 CTriggerEntry<CCountryHasCompletedGoalTrigger>::[1] |
| 0x14103F6D0 | COrderInstance::SOrderInstanceRef::Reader func_names 名 COrderInstance::SOrderInstanceRef::Reader |
| 0x1403402D0 | CEffectEntry<CRemoveIdeasEffect>::[1] func_names 名 CEffectEntry<CRemoveIdeasEffect>::[1] |
| 0x1403E59D0 | CTriggerEntry<CHasDefensiveWarTrigger>::[1] func_names 名 CTriggerEntry<CHasDefensiveWarTrigger>::[1] |
| 0x1403E7010 | CTriggerEntry<CHasWarWithMajorTrigger>::[1] func_names 名 CTriggerEntry<CHasWarWithMajorTrigger>::[1] |
| 0x1403E7B40 | CTriggerEntry<CIsLeadingVolunteerGroupWithOriginalCountry>::[1] func_names 名 CTriggerEntry<CIsLeadingVolunteerGroupWithOriginalCountry>::[1] |
| 0x140468350 | CTriggerEntry<CIsDemilitarizedTrigger>::[1] func_names 名 CTriggerEntry<CIsDemilitarizedTrigger>::[1] |
| 0x1404759C0 | CTriggerEntry<CCombatPhaseTrigger>::[1] func_names 名 CTriggerEntry<CCombatPhaseTrigger>::[1] |
| 0x14048CCD0 | CTriggerEntry<CPcIsForcedGovernmentToTrigger>::[1] func_names 名 CTriggerEntry<CPcIsForcedGovernmentToTrigger>::[1] |
| 0x1404A2480 | CTriggerEntry<NProject::CHasScientistSpecializationTrigger>::[1] func_names 名 CTriggerEntry<NProject::CHasScientistSpecializationTrigger>::[1] |
| 0x1404AA4D0 | CEffectEntry<CDismantleFactionEffect>::[1] func_names 名 CEffectEntry<CDismantleFactionEffect>::[1] |
| 0x1404AA6A0 | CEffectEntry<CSetFactionLeaderEffect>::[1] func_names 名 CEffectEntry<CSetFactionLeaderEffect>::[1] |
| 0x14151BC30 | CStatePeaceAction::IsTargetingState func_names 名 CStatePeaceAction::IsTargetingState |
| 0x14033DB50 | CEffectEntry<CDropCosmeticTagEffect>::[1] func_names 名 CEffectEntry<CDropCosmeticTagEffect>::[1] |
| 0x1403E5350 | CTriggerEntry<CHasCapitulatedTrigger>::[1] func_names 名 CTriggerEntry<CHasCapitulatedTrigger>::[1] |
| 0x1403E5DE0 | CTriggerEntry<CHasGameRuleTrigger>::[1] func_names 名 CTriggerEntry<CHasGameRuleTrigger>::[1] |
| 0x1403E8180 | CTriggerEntry<CIsTargetOfCoupTrigger>::[1] func_names 名 CTriggerEntry<CIsTargetOfCoupTrigger>::[1] |
| 0x140444760 | CTriggerEntry<CHasAirLedger>::[1] func_names 名 CTriggerEntry<CHasAirLedger>::[1] |
| 0x140444E30 | CTriggerEntry<CIsLeaderVisible>::[1] func_names 名 CTriggerEntry<CIsLeaderVisible>::[1] |
| 0x1404451A0 | CTriggerEntry<CIsUnitLeader>::[1] func_names 名 CTriggerEntry<CIsUnitLeader>::[1] |
| 0x1404572D0 | CTriggerEntry<NIndustrialOrganisation::CCheckSizeTrigger>::[1] func_names 名 CTriggerEntry<NIndustrialOrganisation::CCheckSizeTrigger>::[1] |
| 0x14045BDB0 | CTriggerEntry<CIsUnitReservesTrigger>::[1] func_names 名 CTriggerEntry<CIsUnitReservesTrigger>::[1] |
| 0x140475D00 | CTriggerEntry<CHasMaxPlanningTrigger>::[1] func_names 名 CTriggerEntry<CHasMaxPlanningTrigger>::[1] |
| 0x14048D000 | CTriggerEntry<CPcIsStateOutsideInfluenceForWinnerTrigger>::[1] func_names 名 CTriggerEntry<CPcIsStateOutsideInfluenceForWinnerTrigger>::[1] |
| 0x1404A2330 | CTriggerEntry<NProject::CHasFacilitySpecializationTrigger>::[1] func_names 名 CTriggerEntry<NProject::CHasFacilitySpecializationTrigger>::[1] |
| 0x1411BF570 | matchable<鈥�>::[0] func_names 名 matchable<鈥�>::[0] |
| 0x141A2E290 | CConfirmDeleteAllOrders::Update func_names 名 CConfirmDeleteAllOrders::Update |
| 0x141CFE110 | CConfirmDeleteOrdersGroup::Update func_names 名 CConfirmDeleteOrdersGroup::Update |
| 0x1402E5230 | CEffectEntry<CRemoveExileTagEffect>::[1] func_names 名 CEffectEntry<CRemoveExileTagEffect>::[1] |
| 0x14030B570 | CEffectEntry<CAddDemilitarizedZone>::[1] func_names 名 CEffectEntry<CAddDemilitarizedZone>::[1] |
| 0x14033FF50 | CEffectEntry<CReduceFocusCost>::[1] func_names 名 CEffectEntry<CReduceFocusCost>::[1] |
| 0x1403E80A0 | CTriggerEntry<CIsStagingCoupTrigger>::[1] func_names 名 CTriggerEntry<CIsStagingCoupTrigger>::[1] |
| 0x140468480 | CTriggerEntry<CIsIslandStateTrigger>::[1] func_names 名 CTriggerEntry<CIsIslandStateTrigger>::[1] |
| 0x140483B30 | CEffectEntry<CRemovePowerBalanceModifierEffect>::[1] func_names 名 CEffectEntry<CRemovePowerBalanceModifierEffect>::[1] |
| 0x14048CD70 | CTriggerEntry<CPcIsLiberatedTrigger>::[1] func_names 名 CTriggerEntry<CPcIsLiberatedTrigger>::[1] |
| 0x1404B42E0 | CTriggerEntry<CFactionGoalCompletedTrigger>::[1] func_names 名 CTriggerEntry<CFactionGoalCompletedTrigger>::[1] |
| 0x1404B44C0 | CTriggerEntry<CFactionHasActiveRuleTrigger>::[1] func_names 名 CTriggerEntry<CFactionHasActiveRuleTrigger>::[1] |
| 0x1402E51E0 | CEffectEntry<CPromoteLeaderEffect>::[1] func_names 名 CEffectEntry<CPromoteLeaderEffect>::[1] |
| 0x14033BC60 | CEffectEntry<CAddIdeasEffect>::[1] func_names 名 CEffectEntry<CAddIdeasEffect>::[1] |
| 0x1403E5B80 | CTriggerEntry<CHasElectionsTrigger>::[1] func_names 名 CTriggerEntry<CHasElectionsTrigger>::[1] |
| 0x1403E7300 | CTriggerEntry<CIsActiveDecryptionBonusesEnabledTrigger>::[1] func_names 名 CTriggerEntry<CIsActiveDecryptionBonusesEnabledTrigger>::[1] |
| 0x140468090 | CTriggerEntry<CHasActiveResistance>::[1] func_names 名 CTriggerEntry<CHasActiveResistance>::[1] |
| 0x1404683E0 | CTriggerEntry<CIsImpassableTrigger>::[1] func_names 名 CTriggerEntry<CIsImpassableTrigger>::[1] |
| 0x140475A90 | CTriggerEntry<CFrontageFullTrigger>::[1] func_names 名 CTriggerEntry<CFrontageFullTrigger>::[1] |
| 0x140475FA0 | CTriggerEntry<CIsFightingInTerrainTrigger>::[1] func_names 名 CTriggerEntry<CIsFightingInTerrainTrigger>::[1] |
| 0x14048CEE0 | CTriggerEntry<CPcIsPuppetedTrigger>::[1] func_names 名 CTriggerEntry<CPcIsPuppetedTrigger>::[1] |
| 0x1402E50B0 | CEffectEntry<CDemoteLeaderEffect>::[1] func_names 名 CEffectEntry<CDemoteLeaderEffect>::[1] |
| 0x14030BF00 | CEffectEntry<CSetBorderWarEffect>::[1] func_names 名 CEffectEntry<CSetBorderWarEffect>::[1] |
| 0x14033BBA0 | CEffectEntry<CAddDivisionTemplateEffect>::[1] func_names 名 CEffectEntry<CAddDivisionTemplateEffect>::[1] |
| 0x1403E3300 | CTriggerEntry<CAmountManpowerInDeploymentQueueTrigger>::[1] func_names 名 CTriggerEntry<CAmountManpowerInDeploymentQueueTrigger>::[1] |
| 0x1403E53F0 | CTriggerEntry<CHasCasualtiesWarSupportModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasCasualtiesWarSupportModifierTrigger>::[1] |
| 0x1403E5480 | CTriggerEntry<CHasCivilWarTrigger>::[1] func_names 名 CTriggerEntry<CHasCivilWarTrigger>::[1] |
| 0x1403E65E0 | CTriggerEntry<CHasOpinionModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasOpinionModifierTrigger>::[1] |
| 0x1403E7940 | CTriggerEntry<CIsInFactionTrigger>::[1] func_names 名 CTriggerEntry<CIsInFactionTrigger>::[1] |
| 0x1403E8050 | CTriggerEntry<CIsSpyMasterTrigger>::[1] func_names 名 CTriggerEntry<CIsSpyMasterTrigger>::[1] |
| 0x1403E8A50 | CTriggerEntry<CNumOfAvailableCivilianFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfAvailableCivilianFactoriesTrigger>::[1] |
| 0x1403E8A90 | CTriggerEntry<CNumOfAvailableMilitaryFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfAvailableMilitaryFactoriesTrigger>::[1] |
| 0x1404450B0 | CTriggerEntry<CIsPoliticalAdvisor>::[1] func_names 名 CTriggerEntry<CIsPoliticalAdvisor>::[1] |
| 0x140475D50 | CTriggerEntry<CHasReservesTrigger>::[1] func_names 名 CTriggerEntry<CHasReservesTrigger>::[1] |
| 0x1404AA5A0 | CEffectEntry<CLeaveFactionEffect>::[1] func_names 名 CEffectEntry<CLeaveFactionEffect>::[1] |
| 0x1411BF4E0 | finder<鈥�>::[0] func_names 名 finder<鈥�>::[0] |
| 0x1413931A0 | CEffectEntry<CRandomEffect>::[1] func_names 名 CEffectEntry<CRandomEffect>::[1] |
| 0x1403E4CC0 | CTriggerEntry<CGivesMilitaryAccessToTrigger>::[1] func_names 名 CTriggerEntry<CGivesMilitaryAccessToTrigger>::[1] |
| 0x1403E50F0 | CTriggerEntry<CHasAttacheTrigger>::[1] func_names 名 CTriggerEntry<CHasAttacheTrigger>::[1] |
| 0x1403E6E90 | CTriggerEntry<CHasVariable>::[1] func_names 名 CTriggerEntry<CHasVariable>::[1] |
| 0x1403E77E0 | CTriggerEntry<CIsHistoricalFocus>::[1] func_names 名 CTriggerEntry<CIsHistoricalFocus>::[1] |
| 0x1403E93D0 | CTriggerEntry<CScopeExistTrigger>::[1] func_names 名 CTriggerEntry<CScopeExistTrigger>::[1] |
| 0x14045D1A0 | CEffectEntry<CDestroyUnitEffect>::[1] func_names 名 CEffectEntry<CDestroyUnitEffect>::[1] |
| 0x140475EB0 | CTriggerEntry<CIsDefenderTrigger>::[1] func_names 名 CTriggerEntry<CIsDefenderTrigger>::[1] |
| 0x14048D040 | CTriggerEntry<CPcIsWinnerTrigger>::[1] func_names 名 CTriggerEntry<CPcIsWinnerTrigger>::[1] |
| 0x14030B900 | CEffectEntry<CCancelResistance>::[1] func_names 名 CEffectEntry<CCancelResistance>::[1] |
| 0x14033CCE0 | CEffectEntry<CClearGlobalEventTargetEffect>::[1] func_names 名 CEffectEntry<CClearGlobalEventTargetEffect>::[1] |
| 0x1403E5910 | CTriggerEntry<CHasDLCTrigger>::[1] func_names 名 CTriggerEntry<CHasDLCTrigger>::[1] |
| 0x1403E5AC0 | CTriggerEntry<CHasDesignBasedOnTrigger>::[1] func_names 名 CTriggerEntry<CHasDesignBasedOnTrigger>::[1] |
| 0x1403E7160 | CTriggerEntry<CHiddenTrigger>::[1] func_names 名 CTriggerEntry<CHiddenTrigger>::[1] |
| 0x1403E7A70 | CTriggerEntry<CIsIronmanTrigger>::[1] func_names 名 CTriggerEntry<CIsIronmanTrigger>::[1] |
| 0x1403E8130 | CTriggerEntry<CIsSubjectTrigger>::[1] func_names 名 CTriggerEntry<CIsSubjectTrigger>::[1] |
| 0x1403E9610 | CTriggerEntry<CSubtractFromVariableTrigger>::[1] func_names 名 CTriggerEntry<CSubtractFromVariableTrigger>::[1] |
| 0x140444DA0 | CTriggerEntry<CIsHiredAsAdvisor>::[1] func_names 名 CTriggerEntry<CIsHiredAsAdvisor>::[1] |
| 0x1404681F0 | CTriggerEntry<CIsCapitalTrigger>::[1] func_names 名 CTriggerEntry<CIsCapitalTrigger>::[1] |
| 0x140468280 | CTriggerEntry<CIsCoastalTrigger>::[1] func_names 名 CTriggerEntry<CIsCoastalTrigger>::[1] |
| 0x140468970 | CTriggerEntry<CStateAndTerrainStrategicValueTrigger>::[1] func_names 名 CTriggerEntry<CStateAndTerrainStrategicValueTrigger>::[1] |
| 0x1404760A0 | CTriggerEntry<CIsWinningTrigger>::[1] func_names 名 CTriggerEntry<CIsWinningTrigger>::[1] |
| 0x14048CDC0 | CTriggerEntry<CPcIsLoserTrigger>::[1] func_names 名 CTriggerEntry<CPcIsLoserTrigger>::[1] |
| 0x1404AA5F0 | CEffectEntry<CRemoveFactionGoalEffect>::[1] func_names 名 CEffectEntry<CRemoveFactionGoalEffect>::[1] |
| 0x140E78790 | COnDelay<H::12::USOnDismantleCompleted::NProject::EAVCProgram*>::Writer func_names 名 COnDelay<H::12::USOnDismantleCompleted::NProject::EAVCProgram*>::Writer |
| 0x14033F210 | CEffectEntry<CMultiplyTempVariableEffect>::[1] func_names 名 CEffectEntry<CMultiplyTempVariableEffect>::[1] |
| 0x1403E3450 | CTriggerEntry<CAnyClaimTrigger>::[1] func_names 名 CTriggerEntry<CAnyClaimTrigger>::[1] |
| 0x1403E4030 | CTriggerEntry<CCompareAutonomyProgressRatioTrigger>::[1] func_names 名 CTriggerEntry<CCompareAutonomyProgressRatioTrigger>::[1] |
| 0x1403E4450 | CTriggerEntry<CCountTechnologySharingGroupsTrigger>::[1] func_names 名 CTriggerEntry<CCountTechnologySharingGroupsTrigger>::[1] |
| 0x1403E51B0 | CTriggerEntry<CHasBombingWarSupportModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasBombingWarSupportModifierTrigger>::[1] |
| 0x1403E5670 | CTriggerEntry<CHasConvoysWarSupportModifierTrigger>::[1] func_names 名 CTriggerEntry<CHasConvoysWarSupportModifierTrigger>::[1] |
| 0x1403E5A20 | CTriggerEntry<CHasDefensiveWarWithTrigger>::[1] func_names 名 CTriggerEntry<CHasDefensiveWarWithTrigger>::[1] |
| 0x1403E6540 | CTriggerEntry<CHasOffensiveWarWithoutFriendTrigger>::[1] func_names 名 CTriggerEntry<CHasOffensiveWarWithoutFriendTrigger>::[1] |
| 0x1403E8AD0 | CTriggerEntry<CNumOfAvailableNavalFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfAvailableNavalFactoriesTrigger>::[1] |
| 0x140444800 | CTriggerEntry<CHasIDTrigger>::[1] func_names 名 CTriggerEntry<CHasIDTrigger>::[1] |
| 0x140444940 | CTriggerEntry<CHasUnitsTrigger>::[1] func_names 名 CTriggerEntry<CHasUnitsTrigger>::[1] |
| 0x140444BD0 | CTriggerEntry<CIsCountryLeader>::[1] func_names 名 CTriggerEntry<CIsCountryLeader>::[1] |
| 0x140444CB0 | CTriggerEntry<CIsFemaleTrigger>::[1] func_names 名 CTriggerEntry<CIsFemaleTrigger>::[1] |
| 0x14045A650 | CTriggerEntry<NInternationalMarket::CSellerTrigger>::[1] func_names 名 CTriggerEntry<NInternationalMarket::CSellerTrigger>::[1] |
| 0x1404685E0 | CTriggerEntry<CLastStrategicBombingOnStateStrigger>::[1] func_names 名 CTriggerEntry<CLastStrategicBombingOnStateStrigger>::[1] |
| 0x14054CE50 | CTriggerEntry<COrTrigger>::[1] func_names 名 CTriggerEntry<COrTrigger>::[1] |
| 0x14030BE60 | CEffectEntry<CRemoveStaticProvinceModifierEffect>::[1] func_names 名 CEffectEntry<CRemoveStaticProvinceModifierEffect>::[1] |
| 0x140341620 | CEffectEntry<CSetMajorEffect>::[1] func_names 名 CEffectEntry<CSetMajorEffect>::[1] |
| 0x1403E7450 | CTriggerEntry<CIsDebugTrigger>::[1] func_names 名 CTriggerEntry<CIsDebugTrigger>::[1] |
| 0x1403E7CD0 | CTriggerEntry<CIsMajorTrigger>::[1] func_names 名 CTriggerEntry<CIsMajorTrigger>::[1] |
| 0x140444D00 | CTriggerEntry<CIsFieldMarshal>::[1] func_names 名 CTriggerEntry<CIsFieldMarshal>::[1] |
| 0x1404B46F0 | CTriggerEntry<CHasFactionGoalTrigger>::[1] func_names 名 CTriggerEntry<CHasFactionGoalTrigger>::[1] |
| 0x14033E010 | CEffectEntry<CEverySubjectCountryEffect>::[1] func_names 名 CEffectEntry<CEverySubjectCountryEffect>::[1] |
| 0x1403E3230 | CTriggerEntry<CAllianceNavalStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CAllianceNavalStrengthRatioTrigger>::[1] |
| 0x1403E32B0 | CTriggerEntry<CAlwaysTrigger>::[1] func_names 名 CTriggerEntry<CAlwaysTrigger>::[1] |
| 0x1403E4B00 | CTriggerEntry<CExistsTrigger>::[1] func_names 名 CTriggerEntry<CExistsTrigger>::[1] |
| 0x1403E6400 | CTriggerEntry<CHasNonAggressionPactWith>::[1] func_names 名 CTriggerEntry<CHasNonAggressionPactWith>::[1] |
| 0x1403E6FC0 | CTriggerEntry<CHasWarTrigger>::[1] func_names 名 CTriggerEntry<CHasWarTrigger>::[1] |
| 0x1404445C0 | CTriggerEntry<CCanBeCaptured>::[1] func_names 名 CTriggerEntry<CCanBeCaptured>::[1] |
| 0x1404447B0 | CTriggerEntry<CHasArmyLedger>::[1] func_names 名 CTriggerEntry<CHasArmyLedger>::[1] |
| 0x140444850 | CTriggerEntry<CHasIdeology>::[1] func_names 名 CTriggerEntry<CHasIdeology>::[1] |
| 0x1404448F0 | CTriggerEntry<CHasNavyLedger>::[1] func_names 名 CTriggerEntry<CHasNavyLedger>::[1] |
| 0x140444C20 | CTriggerEntry<CIsExileLeader>::[1] func_names 名 CTriggerEntry<CIsExileLeader>::[1] |
| 0x140444D50 | CTriggerEntry<CIsHighCommand>::[1] func_names 名 CTriggerEntry<CIsHighCommand>::[1] |
| 0x140444E80 | CTriggerEntry<CIsLeadingArmy>::[1] func_names 名 CTriggerEntry<CIsLeadingArmy>::[1] |
| 0x140467F10 | CTriggerEntry<CCanConstructBuilding>::[1] func_names 名 CTriggerEntry<CCanConstructBuilding>::[1] |
| 0x140468130 | CTriggerEntry<CHasResistance>::[1] func_names 名 CTriggerEntry<CHasResistance>::[1] |
| 0x140468AA0 | CTriggerEntry<CStatePopulationInThousandsTrigger>::[1] func_names 名 CTriggerEntry<CStatePopulationInThousandsTrigger>::[1] |
| 0x14048CF30 | CTriggerEntry<CPcIsStateClaimedAndTakenByTrigger>::[1] func_names 名 CTriggerEntry<CPcIsStateClaimedAndTakenByTrigger>::[1] |
| 0x1404AA150 | CEffectEntry<CAddFactionGoalEffect>::[1] func_names 名 CEffectEntry<CAddFactionGoalEffect>::[1] |
| 0x1404B45D0 | CTriggerEntry<CFactionManifestFulfillmentTrigger>::[1] func_names 名 CTriggerEntry<CFactionManifestFulfillmentTrigger>::[1] |
| 0x140AB1410 | TGameItemDatabase<CScriptedDiplomaticActionTemplateDatabase>::[1] func_names 名 TGameItemDatabase<CScriptedDiplomaticActionTemplateDatabase>::[1] |
| 0x140BEA9E0 | CPdxMonotonicBufferAllocator<HH>::[4] func_names 名 CPdxMonotonicBufferAllocator<HH>::[4] |
| 0x140E9F070 | CPdxMonotonicBufferAllocator<鈥�>::[4] func_names 名 CPdxMonotonicBufferAllocator<鈥�>::[4] |
| 0x1413396D0 | CTextBufferObserverGlue<CChat>::[9] func_names 名 CTextBufferObserverGlue<CChat>::[9] |
| 0x1402E5480 | CEffectEntry<CRetireEffect>::[1] func_names 名 CEffectEntry<CRetireEffect>::[1] |
| 0x1403E45C0 | CTriggerEntry<CCurrentConscriptionAmountTrigger>::[1] func_names 名 CTriggerEntry<CCurrentConscriptionAmountTrigger>::[1] |
| 0x1403E51F0 | CTriggerEntry<CHasBorderWar>::[1] func_names 名 CTriggerEntry<CHasBorderWar>::[1] |
| 0x140444A80 | CTriggerEntry<CIsArmyLeader>::[1] func_names 名 CTriggerEntry<CIsArmyLeader>::[1] |
| 0x140444FC0 | CTriggerEntry<CIsNavyLeader>::[1] func_names 名 CTriggerEntry<CIsNavyLeader>::[1] |
| 0x14044CC90 | CIsLeadingArmyInProvince::Parse func_names 名 CIsLeadingArmyInProvince::Parse |
| 0x14045BC50 | CTriggerEntry<CArmyHasBattalionInTemplateTrigger>::[1] func_names 名 CTriggerEntry<CArmyHasBattalionInTemplateTrigger>::[1] |
| 0x140468430 | CTriggerEntry<CIsInHomeArea>::[1] func_names 名 CTriggerEntry<CIsInHomeArea>::[1] |
| 0x140476190 | CTriggerEntry<CNightTrigger>::[1] func_names 名 CTriggerEntry<CNightTrigger>::[1] |
| 0x1403A90F0 | CRandomizeVariableEffect<CVariableResolver>::[3] func_names 名 CRandomizeVariableEffect<CVariableResolver>::[3] |
| 0x1403E72B0 | CTriggerEntry<CIsAITrigger>::[1] func_names 名 CTriggerEntry<CIsAITrigger>::[1] |
| 0x1403E7340 | CTriggerEntry<CIsBorderWar>::[1] func_names 名 CTriggerEntry<CIsBorderWar>::[1] |
| 0x1403E8B90 | CTriggerEntry<CNumOfControlledFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfControlledFactoriesTrigger>::[1] |
| 0x1403E96D0 | CTriggerEntry<CTargetConscriptionAmountTrigger>::[1] func_names 名 CTriggerEntry<CTargetConscriptionAmountTrigger>::[1] |
| 0x1404423D0 | CHasIdeology::Evaluate func_names 名 CHasIdeology::Evaluate |
| 0x140442430 | CHasIdeologyGroup::Evaluate func_names 名 CHasIdeologyGroup::Evaluate |
| 0x140444A30 | CTriggerEntry<CIsArmyChief>::[1] func_names 名 CTriggerEntry<CIsArmyChief>::[1] |
| 0x140444F70 | CTriggerEntry<CIsNavyChief>::[1] func_names 名 CTriggerEntry<CIsNavyChief>::[1] |
| 0x140445010 | CTriggerEntry<CIsOperative>::[1] func_names 名 CTriggerEntry<CIsOperative>::[1] |
| 0x140341DF0 | CEffectEntry<CSetTempVariableEffect>::[1] func_names 名 CEffectEntry<CSetTempVariableEffect>::[1] |
| 0x1403423A0 | CEffectEntry<CSubtractFromTempVariableEffect>::[1] func_names 名 CEffectEntry<CSubtractFromTempVariableEffect>::[1] |
| 0x1403429D0 | CEffectEntry<CUpgradeIntelligenceAgencyEffect>::[1] func_names 名 CEffectEntry<CUpgradeIntelligenceAgencyEffect>::[1] |
| 0x1403E49C0 | CTriggerEntry<CEnemyNavalStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CEnemyNavalStrengthRatioTrigger>::[1] |
| 0x1403E6D90 | CTriggerEntry<CHasTerrainTrigger>::[1] func_names 名 CTriggerEntry<CHasTerrainTrigger>::[1] |
| 0x1403E81D0 | CTriggerEntry<CIsTutorial>::[1] func_names 名 CTriggerEntry<CIsTutorial>::[1] |
| 0x1404449E0 | CTriggerEntry<CIsAirChief>::[1] func_names 名 CTriggerEntry<CIsAirChief>::[1] |
| 0x140445150 | CTriggerEntry<CIsTheorist>::[1] func_names 名 CTriggerEntry<CIsTheorist>::[1] |
| 0x14048CEA0 | CTriggerEntry<CPcIsPuppetedByTrigger>::[1] func_names 名 CTriggerEntry<CPcIsPuppetedByTrigger>::[1] |
| 0x1404AA930 | CEffectEntry<CSetFactionUpgrade>::[1] func_names 名 CEffectEntry<CSetFactionUpgrade>::[1] |
| 0x142069030 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x142527D44 | collate<unsigned short,std>::[0] func_names 名 collate<unsigned short,std>::[0] |
| 0x14030BF50 | CEffectEntry<CSetBuildingConstructionEffect>::[1] func_names 名 CEffectEntry<CSetBuildingConstructionEffect>::[1] |
| 0x14033DE10 | CEffectEntry<CEveryNavyLeaderEffect>::[1] func_names 名 CEffectEntry<CEveryNavyLeaderEffect>::[1] |
| 0x1403E5CC0 | CTriggerEntry<CHasEventTargetTrigger>::[1] func_names 名 CTriggerEntry<CHasEventTargetTrigger>::[1] |
| 0x1403E69C0 | CTriggerEntry<CHasRuleTrigger>::[1] func_names 名 CTriggerEntry<CHasRuleTrigger>::[1] |
| 0x1403E7B80 | CTriggerEntry<CIsLendLeasingTrigger>::[1] func_names 名 CTriggerEntry<CIsLendLeasingTrigger>::[1] |
| 0x1403E8B50 | CTriggerEntry<CNumOfCivilianFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfCivilianFactoriesTrigger>::[1] |
| 0x1403E8C50 | CTriggerEntry<CNumOfMilitaryFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfMilitaryFactoriesTrigger>::[1] |
| 0x1404448A0 | CTriggerEntry<CHasIdeologyGroup>::[1] func_names 名 CTriggerEntry<CHasIdeologyGroup>::[1] |
| 0x140444990 | CTriggerEntry<CIsAdvisor>::[1] func_names 名 CTriggerEntry<CIsAdvisor>::[1] |
| 0x140468560 | CTriggerEntry<CIsOwnedAndControlledByTrigger>::[1] func_names 名 CTriggerEntry<CIsOwnedAndControlledByTrigger>::[1] |
| 0x14048CC90 | CTriggerEntry<CPcIsForcedGovernmentByTrigger>::[1] func_names 名 CTriggerEntry<CPcIsForcedGovernmentByTrigger>::[1] |
| 0x1404B4610 | CTriggerEntry<CFactionPowerProjectionTrigger>::[1] func_names 名 CTriggerEntry<CFactionPowerProjectionTrigger>::[1] |
| 0x1422E8AA0 | CChatBuffer::CWriteToChatBuffer::PayloadWriter func_names 名 CChatBuffer::CWriteToChatBuffer::PayloadWriter |
| 0x14033C620 | CEffectEntry<CAddToVariableEffect>::[1] func_names 名 CEffectEntry<CAddToVariableEffect>::[1] |
| 0x140340B60 | CEffectEntry<CSaveGlobalEventTargetAsEffect>::[1] func_names 名 CEffectEntry<CSaveGlobalEventTargetAsEffect>::[1] |
| 0x1403E3270 | CTriggerEntry<CAllianceStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CAllianceStrengthRatioTrigger>::[1] |
| 0x1403E3D30 | CTriggerEntry<CCasualtiesInThousandsTrigger>::[1] func_names 名 CTriggerEntry<CCasualtiesInThousandsTrigger>::[1] |
| 0x1403E4DB0 | CTriggerEntry<CHasAddedTensionAmountTrigger>::[1] func_names 名 CTriggerEntry<CHasAddedTensionAmountTrigger>::[1] |
| 0x1403E8BD0 | CTriggerEntry<CNumOfControlledStatesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfControlledStatesTrigger>::[1] |
| 0x1403E8E90 | CTriggerEntry<COriginalResearchSlotsTrigger>::[1] func_names 名 CTriggerEntry<COriginalResearchSlotsTrigger>::[1] |
| 0x140444720 | CTriggerEntry<CCommandingAmountUnitsTrigger>::[1] func_names 名 CTriggerEntry<CCommandingAmountUnitsTrigger>::[1] |
| 0x14045D3C0 | CEffectEntry<CReseedDivisionCommanderEffect>::[1] func_names 名 CEffectEntry<CReseedDivisionCommanderEffect>::[1] |
| 0x140483970 | CEffectEntry<CAddPowerBalanceModifierEffect>::[1] func_names 名 CEffectEntry<CAddPowerBalanceModifierEffect>::[1] |
| 0x1404B4550 | CTriggerEntry<CFactionInfluenceRatioTrigger>::[1] func_names 名 CTriggerEntry<CFactionInfluenceRatioTrigger>::[1] |
| 0x1404B4590 | CTriggerEntry<CFactionInfluenceScoreTrigger>::[1] func_names 名 CTriggerEntry<CFactionInfluenceScoreTrigger>::[1] |
| 0x14225A4B0 | CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[6] func_names 名 CTernary<PEAVCGuiType::U?$STernaryTrait::EAVCGuiType*>::[6] |
| 0x1422A9A20 | TListbox<CStandardlistboxItem>::[0] func_names 名 TListbox<CStandardlistboxItem>::[0] |
| 0x142375570 | CTernary<PEAVCPositionType::U?$STernaryTrait::EAVCPositionType*>::[6] func_names 名 CTernary<PEAVCPositionType::U?$STernaryTrait::EAVCPositionType*>::[6] |
| 0x1403DE9A0 | CCanSelectTrait::ParseValueKeys func_names 名 CCanSelectTrait::ParseValueKeys |
| 0x1403E3CE0 | CTriggerEntry<CCanSelectTrait>::[1] func_names 名 CTriggerEntry<CCanSelectTrait>::[1] |
| 0x1403E4650 | CTriggerEntry<CDaysSinceCapitulatedTrigger>::[1] func_names 名 CTriggerEntry<CDaysSinceCapitulatedTrigger>::[1] |
| 0x1403E4C80 | CTriggerEntry<CGarrisonManpowerNeedTrigger>::[1] func_names 名 CTriggerEntry<CGarrisonManpowerNeedTrigger>::[1] |
| 0x1403E6AB0 | CTriggerEntry<CHasStartDateTrigger>::[1] func_names 名 CTriggerEntry<CHasStartDateTrigger>::[1] |
| 0x1403E9100 | CTriggerEntry<CPoliticalPowerGrowthTrigger>::[1] func_names 名 CTriggerEntry<CPoliticalPowerGrowthTrigger>::[1] |
| 0x1404B4510 | CTriggerEntry<CFactionInfluenceRankTrigger>::[1] func_names 名 CTriggerEntry<CFactionInfluenceRankTrigger>::[1] |
| 0x140528AC0 | CTriggerEntry<CHasEnemyNavalControlTrigger>::[1] func_names 名 CTriggerEntry<CHasEnemyNavalControlTrigger>::[1] |
| 0x141392FD0 | CEffectEntry<CEffectTooltipEffect>::[1] func_names 名 CEffectEntry<CEffectTooltipEffect>::[1] |
| 0x14033E8C0 | CEffectEntry<CGlobalEveryArmyLeaderEffect>::[1] func_names 名 CEffectEntry<CGlobalEveryArmyLeaderEffect>::[1] |
| 0x1403423E0 | CEffectEntry<CSubtractFromVariableEffect>::[1] func_names 名 CEffectEntry<CSubtractFromVariableEffect>::[1] |
| 0x1403E2DF0 | CTriggerEntry<CAgencyUpgradeNumberTrigger>::[1] func_names 名 CTriggerEntry<CAgencyUpgradeNumberTrigger>::[1] |
| 0x1403E3340 | CTriggerEntry<CAmountResearchSlotsTrigger>::[1] func_names 名 CTriggerEntry<CAmountResearchSlotsTrigger>::[1] |
| 0x1403E6140 | CTriggerEntry<CHasMilitaryAccessToTrigger>::[1] func_names 名 CTriggerEntry<CHasMilitaryAccessToTrigger>::[1] |
| 0x1403E6500 | CTriggerEntry<CHasOffensiveWarWithTrigger>::[1] func_names 名 CTriggerEntry<CHasOffensiveWarWithTrigger>::[1] |
| 0x1403E7AC0 | CTriggerEntry<CIsJustifyingWargoalAgainst>::[1] func_names 名 CTriggerEntry<CIsJustifyingWargoalAgainst>::[1] |
| 0x1403E8C90 | CTriggerEntry<CNumOfNavalFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfNavalFactoriesTrigger>::[1] |
| 0x1403E8D50 | CTriggerEntry<CNumOfOwnedFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfOwnedFactoriesTrigger>::[1] |
| 0x1403E90C0 | CTriggerEntry<CPoliticalPowerDailyTrigger>::[1] func_names 名 CTriggerEntry<CPoliticalPowerDailyTrigger>::[1] |
| 0x14045BD30 | CTriggerEntry<CHasUnitOrganizationTrigger>::[1] func_names 名 CTriggerEntry<CHasUnitOrganizationTrigger>::[1] |
| 0x1404683A0 | CTriggerEntry<CIsFullyControlledByTrigger>::[1] func_names 名 CTriggerEntry<CIsFullyControlledByTrigger>::[1] |
| 0x140468B20 | CTriggerEntry<CStateStrategicValueTrigger>::[1] func_names 名 CTriggerEntry<CStateStrategicValueTrigger>::[1] |
| 0x1402E5160 | CEffectEntry<CModifyCharacterFlagEffect>::[1] func_names 名 CEffectEntry<CModifyCharacterFlagEffect>::[1] |
| 0x14030BA80 | CEffectEntry<CEveryControlledStateEffect>::[1] func_names 名 CEffectEntry<CEveryControlledStateEffect>::[1] |
| 0x14033DE50 | CEffectEntry<CEveryNeighborCountryEffect>::[1] func_names 名 CEffectEntry<CEveryNeighborCountryEffect>::[1] |
| 0x14033DE90 | CEffectEntry<CEveryOccupiedCountryEffect>::[1] func_names 名 CEffectEntry<CEveryOccupiedCountryEffect>::[1] |
| 0x14033DED0 | CEffectEntry<CEveryOperativeLeaderEffect>::[1] func_names 名 CEffectEntry<CEveryOperativeLeaderEffect>::[1] |
| 0x14033DF90 | CEffectEntry<CEveryPossibleCountryEffect>::[1] func_names 名 CEffectEntry<CEveryPossibleCountryEffect>::[1] |
| 0x1403E4370 | CTriggerEntry<CCountFakeDivisionsTrigger>::[1] func_names 名 CTriggerEntry<CCountFakeDivisionsTrigger>::[1] |
| 0x1403E4A00 | CTriggerEntry<CEnemyStrengthRatioTrigger>::[1] func_names 名 CTriggerEntry<CEnemyStrengthRatioTrigger>::[1] |
| 0x1403E8E10 | CTriggerEntry<CNumResearchedTechnologies>::[1] func_names 名 CTriggerEntry<CNumResearchedTechnologies>::[1] |
| 0x14048CF70 | CTriggerEntry<CPcIsStateClaimedByTrigger>::[1] func_names 名 CTriggerEntry<CPcIsStateClaimedByTrigger>::[1] |
| 0x1403E3FB0 | CTriggerEntry<CCommandPowerDailyTrigger>::[1] func_names 名 CTriggerEntry<CCommandPowerDailyTrigger>::[1] |
| 0x1403E4180 | CTriggerEntry<CConscriptionRatioTrigger>::[1] func_names 名 CTriggerEntry<CConscriptionRatioTrigger>::[1] |
| 0x1403E4BF0 | CTriggerEntry<CFullControlsStateTrigger>::[1] func_names 名 CTriggerEntry<CFullControlsStateTrigger>::[1] |
| 0x1403E6690 | CTriggerEntry<CHasPoliticalPowerTrigger>::[1] func_names 名 CTriggerEntry<CHasPoliticalPowerTrigger>::[1] |
| 0x1403E76D0 | CTriggerEntry<CIsFriendTrigger>::[1] func_names 名 CTriggerEntry<CIsFriendTrigger>::[1] |
| 0x1403E7DE0 | CTriggerEntry<CIsOwnerNeighborOfTrigger>::[1] func_names 名 CTriggerEntry<CIsOwnerNeighborOfTrigger>::[1] |
| 0x1403E8220 | CTriggerEntry<CLandDoctrineLevelTrigger>::[1] func_names 名 CTriggerEntry<CLandDoctrineLevelTrigger>::[1] |
| 0x1403E8DD0 | CTriggerEntry<CNumOperativeSlotsTrigger>::[1] func_names 名 CTriggerEntry<CNumOperativeSlotsTrigger>::[1] |
| 0x1403E9650 | CTriggerEntry<CSurrenderProgressTrigger>::[1] func_names 名 CTriggerEntry<CSurrenderProgressTrigger>::[1] |
| 0x140468310 | CTriggerEntry<CIsCoreOfTrigger>::[1] func_names 名 CTriggerEntry<CIsCoreOfTrigger>::[1] |
| 0x140468B60 | CTriggerEntry<CStrategicRegionIDTrigger>::[1] func_names 名 CTriggerEntry<CStrategicRegionIDTrigger>::[1] |
| 0x1404A89E0 | CTriggerEntry<CAnyOtherCountryOfTrigger>::[1] func_names 名 CTriggerEntry<CAnyOtherCountryOfTrigger>::[1] |
| 0x1404A8A60 | CTriggerEntry<CEnergyFullfilmentTrigger>::[1] func_names 名 CTriggerEntry<CEnergyFullfilmentTrigger>::[1] |
| 0x1422FF7F0 | TListbox<CSmoothListboxItem>::[0] func_names 名 TListbox<CSmoothListboxItem>::[0] |
| 0x14030BAC0 | CEffectEntry<CEveryNeighborStateEffect>::[1] func_names 名 CEffectEntry<CEveryNeighborStateEffect>::[1] |
| 0x14033C5E0 | CEffectEntry<CAddToTempVariableEffect>::[1] func_names 名 CEffectEntry<CAddToTempVariableEffect>::[1] |
| 0x14033F190 | CEffectEntry<CModifyCountryFlagEffect>::[1] func_names 名 CEffectEntry<CModifyCountryFlagEffect>::[1] |
| 0x1403E2CF0 | CTriggerEntry<CAIWantsDivisionsTrigger>::[1] func_names 名 CTriggerEntry<CAIWantsDivisionsTrigger>::[1] |
| 0x1403E7710 | CTriggerEntry<CIsFullyDecryptedTrigger>::[1] func_names 名 CTriggerEntry<CIsFullyDecryptedTrigger>::[1] |
| 0x1403E7B00 | CTriggerEntry<CIsLeadingVolunteerGroup>::[1] func_names 名 CTriggerEntry<CIsLeadingVolunteerGroup>::[1] |
| 0x1403E7BC0 | CTriggerEntry<CIsLicensingAnyToTrigger>::[1] func_names 名 CTriggerEntry<CIsLicensingAnyToTrigger>::[1] |
| 0x1403E83F0 | CTriggerEntry<CManpowerPerFactoryRatio>::[1] func_names 名 CTriggerEntry<CManpowerPerFactoryRatio>::[1] |
| 0x1403E8560 | CTriggerEntry<CMultiplyVariableTrigger>::[1] func_names 名 CTriggerEntry<CMultiplyVariableTrigger>::[1] |
| 0x1403E8D90 | CTriggerEntry<CNumOfSupplyNodesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfSupplyNodesTrigger>::[1] |
| 0x140445250 | CTriggerEntry<COperativeHasNationality>::[1] func_names 名 CTriggerEntry<COperativeHasNationality>::[1] |
| 0x1404688F0 | CTriggerEntry<CResistanceTargetTrigger>::[1] func_names 名 CTriggerEntry<CResistanceTargetTrigger>::[1] |
| 0x14048CE10 | CTriggerEntry<CPcIsOnSameSideAsTrigger>::[1] func_names 名 CTriggerEntry<CPcIsOnSameSideAsTrigger>::[1] |
| 0x140AABA20 | TGameItemDatabase<CScriptableLocalizationDatabase>::[1] func_names 名 TGameItemDatabase<CScriptableLocalizationDatabase>::[1] |
| 0x140AC66C0 | TGameItemDatabase<CTechnologySharingGroupDatabase>::[1] func_names 名 TGameItemDatabase<CTechnologySharingGroupDatabase>::[1] |
| 0x1402E54D0 | CEffectEntry<CSetCharacterFlagEffect>::[1] func_names 名 CEffectEntry<CSetCharacterFlagEffect>::[1] |
| 0x14033CCA0 | CEffectEntry<CClearCountryFlagEffect>::[1] func_names 名 CEffectEntry<CClearCountryFlagEffect>::[1] |
| 0x14033DDD0 | CEffectEntry<CEveryEnemyCountryEffect>::[1] func_names 名 CEffectEntry<CEveryEnemyCountryEffect>::[1] |
| 0x14033DF10 | CEffectEntry<CEveryOtherCountryEffect>::[1] func_names 名 CEffectEntry<CEveryOtherCountryEffect>::[1] |
| 0x14033F250 | CEffectEntry<CMultiplyVariableEffect>::[1] func_names 名 CEffectEntry<CMultiplyVariableEffect>::[1] |
| 0x140340B20 | CEffectEntry<CSaveEventTargetAsEffect>::[1] func_names 名 CEffectEntry<CSaveEventTargetAsEffect>::[1] |
| 0x1403B2930 | CDeleteTemplateAndItsUnits::ParseToken func_names 名 CDeleteTemplateAndItsUnits::ParseToken |
| 0x1403E2C50 | CTriggerEntry<CAIIrrationalityTrigger>::[1] func_names 名 CTriggerEntry<CAIIrrationalityTrigger>::[1] |
| 0x1403E3C20 | CTriggerEntry<CCanDeclareWarOnTrigger>::[1] func_names 名 CTriggerEntry<CCanDeclareWarOnTrigger>::[1] |
| 0x1403E4BB0 | CTriggerEntry<CForeignManpowerTrigger>::[1] func_names 名 CTriggerEntry<CForeignManpowerTrigger>::[1] |
| 0x1403E7990 | CTriggerEntry<CIsInFactionWithTrigger>::[1] func_names 名 CTriggerEntry<CIsInFactionWithTrigger>::[1] |
| 0x1403E8610 | CTriggerEntry<CNavalMineDangerTrigger>::[1] func_names 名 CTriggerEntry<CNavalMineDangerTrigger>::[1] |
| 0x1403E8D10 | CTriggerEntry<CNumOfOperativesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfOperativesTrigger>::[1] |
| 0x14045BD70 | CTriggerEntry<CHasUnitStrengthTrigger>::[1] func_names 名 CTriggerEntry<CHasUnitStrengthTrigger>::[1] |
| 0x140467F60 | CTriggerEntry<CComplianceSpeedTrigger>::[1] func_names 名 CTriggerEntry<CComplianceSpeedTrigger>::[1] |
| 0x1404688B0 | CTriggerEntry<CResistanceSpeedTrigger>::[1] func_names 名 CTriggerEntry<CResistanceSpeedTrigger>::[1] |
| 0x140468AE0 | CTriggerEntry<CStatePopulationTrigger>::[1] func_names 名 CTriggerEntry<CStatePopulationTrigger>::[1] |
| 0x140528B00 | CTriggerEntry<CHasNavalControlTrigger>::[1] func_names 名 CTriggerEntry<CHasNavalControlTrigger>::[1] |
| 0x140F58C50 | VCOperativeLeader::V?$CConstRef::AEBV?$CPdxArray::AXAEBVCCountr鈥�::[2] func_names 名 VCOperativeLeader::V?$CConstRef::AEBV?$CPdxArray::AXAEBVCCountr鈥�::[2] |
| 0x141639FF0 | CTheaterGroup::CreateNewId func_names 名 CTheaterGroup::CreateNewId |
| 0x1402E5640 | CEffectEntry<CUnitLeaderEventEffect>::[1] func_names 名 CEffectEntry<CUnitLeaderEventEffect>::[1] |
| 0x14030BBE0 | CEffectEntry<CModifyStateFlagEffect>::[1] func_names 名 CEffectEntry<CModifyStateFlagEffect>::[1] |
| 0x14033CD70 | CEffectEntry<CClearGlobalFlagEffect>::[1] func_names 名 CEffectEntry<CClearGlobalFlagEffect>::[1] |
| 0x14033F1D0 | CEffectEntry<CModifyTimedIdeaEffect>::[1] func_names 名 CEffectEntry<CModifyTimedIdeaEffect>::[1] |
| 0x1403E3EA0 | CTriggerEntry<CCivilwarTargetTrigger>::[1] func_names 名 CTriggerEntry<CCivilwarTargetTrigger>::[1] |
| 0x1403E4330 | CTriggerEntry<CCountDivisionsTrigger>::[1] func_names 名 CTriggerEntry<CCountDivisionsTrigger>::[1] |
| 0x1403E48A0 | CTriggerEntry<CDivideVariableTrigger>::[1] func_names 名 CTriggerEntry<CDivideVariableTrigger>::[1] |
| 0x1403E50B0 | CTriggerEntry<CHasAttacheFromTrigger>::[1] func_names 名 CTriggerEntry<CHasAttacheFromTrigger>::[1] |
| 0x1403E6F80 | CTriggerEntry<CHasWarTogetherTrigger>::[1] func_names 名 CTriggerEntry<CHasWarTogetherTrigger>::[1] |
| 0x1403E77A0 | CTriggerEntry<CIsGuaranteedByTrigger>::[1] func_names 名 CTriggerEntry<CIsGuaranteedByTrigger>::[1] |
| 0x1403E7830 | CTriggerEntry<CIsHostingExileTrigger>::[1] func_names 名 CTriggerEntry<CIsHostingExileTrigger>::[1] |
| 0x1403E8A10 | CTriggerEntry<CNumFreeOperativeSlots>::[1] func_names 名 CTriggerEntry<CNumFreeOperativeSlots>::[1] |
| 0x1403E8C10 | CTriggerEntry<CNumOfFactoriesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfFactoriesTrigger>::[1] |
| 0x1403E8E50 | CTriggerEntry<COccupiedStatesTrigger>::[1] func_names 名 CTriggerEntry<COccupiedStatesTrigger>::[1] |
| 0x140459BC0 | CTargetTriggerBase<$0CAA>::[6] func_names 名 CTargetTriggerBase<$0CAA>::[6] |
| 0x14045BCF0 | CTriggerEntry<CArmyHasTemplateTrigger>::[1] func_names 名 CTriggerEntry<CArmyHasTemplateTrigger>::[1] |
| 0x1404682D0 | CTriggerEntry<CIsControlledByTrigger>::[1] func_names 名 CTriggerEntry<CIsControlledByTrigger>::[1] |
| 0x140476220 | CTriggerEntry<CReconAdvantageTrigger>::[1] func_names 名 CTriggerEntry<CReconAdvantageTrigger>::[1] |
| 0x1404762A0 | CTriggerEntry<CSkillAdvantageTrigger>::[1] func_names 名 CTriggerEntry<CSkillAdvantageTrigger>::[1] |
| 0x14048CB70 | CTriggerEntry<CPcCurrentScoreTrigger>::[1] func_names 名 CTriggerEntry<CPcCurrentScoreTrigger>::[1] |
| 0x1405211C0 | CTargetTriggerBase<$0A>::[6] func_names 名 CTargetTriggerBase<$0A>::[6] |
| 0x140727990 | CDecision::GetName func_names 名 CDecision::GetName |
| 0x1410EDDF0 | CCountryCharacters::SAdvisorSlotInfo::Reader func_names 名 CCountryCharacters::SAdvisorSlotInfo::Reader |
| 0x14030B950 | CEffectEntry<CClearStateFlagEffect>::[1] func_names 名 CEffectEntry<CClearStateFlagEffect>::[1] |
| 0x14033DB10 | CEffectEntry<CDivideVariableEffect>::[1] func_names 名 CEffectEntry<CDivideVariableEffect>::[1] |
| 0x14033DF50 | CEffectEntry<CEveryOwnedStateEffect>::[1] func_names 名 CEffectEntry<CEveryOwnedStateEffect>::[1] |
| 0x14033E050 | CEffectEntry<CEveryUnitLeaderEffect>::[1] func_names 名 CEffectEntry<CEveryUnitLeaderEffect>::[1] |
| 0x140340FF0 | CEffectEntry<CSetCountryFlagEffect>::[1] func_names 名 CEffectEntry<CSetCountryFlagEffect>::[1] |
| 0x1403B2EB0 | CExecuteOperationCoordinatedStrike::ParseToken func_names 名 CExecuteOperationCoordinatedStrike::ParseToken |
| 0x1403E2DB0 | CTriggerEntry<CAddToVariableTrigger>::[1] func_names 名 CTriggerEntry<CAddToVariableTrigger>::[1] |
| 0x1403E4210 | CTriggerEntry<CControlsStateTrigger>::[1] func_names 名 CTriggerEntry<CControlsStateTrigger>::[1] |
| 0x1403E4410 | CTriggerEntry<CCountSubjectsTrigger>::[1] func_names 名 CTriggerEntry<CCountSubjectsTrigger>::[1] |
| 0x1403E44E0 | CTriggerEntry<CCountryExistsTrigger>::[1] func_names 名 CTriggerEntry<CCountryExistsTrigger>::[1] |
| 0x1403E5E80 | CTriggerEntry<CHasGuaranteedTrigger>::[1] func_names 名 CTriggerEntry<CHasGuaranteedTrigger>::[1] |
| 0x1403E5FF0 | CTriggerEntry<CHasLegitimacyTrigger>::[1] func_names 名 CTriggerEntry<CHasLegitimacyTrigger>::[1] |
| 0x1403E6F40 | CTriggerEntry<CHasWarSupportTrigger>::[1] func_names 名 CTriggerEntry<CHasWarSupportTrigger>::[1] |
| 0x1403E7530 | CTriggerEntry<CIsEmbargoedByTrigger>::[1] func_names 名 CTriggerEntry<CIsEmbargoedByTrigger>::[1] |
| 0x140442520 | CIsAdvisor::Evaluate func_names 名 CIsAdvisor::Evaluate |
| 0x14048CBB0 | CTriggerEntry<CPcCurrentTurnTrigger>::[1] func_names 名 CTriggerEntry<CPcCurrentTurnTrigger>::[1] |
| 0x1404A7590 | CTriggerEntry<CNumNukesBeingDropped>::[1] func_names 名 CTriggerEntry<CNumNukesBeingDropped>::[1] |
| 0x1424E69C0 | collate<char,std>::[0] func_names 名 collate<char,std>::[0] |
| 0x1402F4290 | CEffectEntry<CEveryCharacterEffect>::[1] func_names 名 CEffectEntry<CEveryCharacterEffect>::[1] |
| 0x14033DD00 | CEffectEntry<CEveryCoreStateEffect>::[1] func_names 名 CEffectEntry<CEveryCoreStateEffect>::[1] |
| 0x14033F150 | CEffectEntry<CModifyBuildingEffect>::[1] func_names 名 CEffectEntry<CModifyBuildingEffect>::[1] |
| 0x140341500 | CEffectEntry<CSetGlobalFlagEffect>::[1] func_names 名 CEffectEntry<CSetGlobalFlagEffect>::[1] |
| 0x1403E3FF0 | CTriggerEntry<CCommandPowerTrigger>::[1] func_names 名 CTriggerEntry<CCommandPowerTrigger>::[1] |
| 0x1403E4250 | CTriggerEntry<CConvoyThreatTrigger>::[1] func_names 名 CTriggerEntry<CConvoyThreatTrigger>::[1] |
| 0x1403E5D60 | CTriggerEntry<CHasFuelRatioTrigger>::[1] func_names 名 CTriggerEntry<CHasFuelRatioTrigger>::[1] |
| 0x1403E6A70 | CTriggerEntry<CHasStabilityTrigger>::[1] func_names 名 CTriggerEntry<CHasStabilityTrigger>::[1] |
| 0x1403E74A0 | CTriggerEntry<CIsDecryptingTrigger>::[1] func_names 名 CTriggerEntry<CIsDecryptingTrigger>::[1] |
| 0x1403E7570 | CTriggerEntry<CIsEmbargoingTrigger>::[1] func_names 名 CTriggerEntry<CIsEmbargoingTrigger>::[1] |
| 0x1403E7D20 | CTriggerEntry<CIsNeighborOfTrigger>::[1] func_names 名 CTriggerEntry<CIsNeighborOfTrigger>::[1] |
| 0x14045D230 | CEffectEntry<CEveryStateArmyEffect>::[1] func_names 名 CEffectEntry<CEveryStateArmyEffect>::[1] |
| 0x1404684D0 | CTriggerEntry<CIsOnContinentTrigger>::[1] func_names 名 CTriggerEntry<CIsOnContinentTrigger>::[1] |
| 0x14048D090 | CTriggerEntry<CPcTotalScoreTrigger>::[1] func_names 名 CTriggerEntry<CPcTotalScoreTrigger>::[1] |
| 0x1404A8AA0 | CTriggerEntry<CHasTruceWithTrigger>::[1] func_names 名 CTriggerEntry<CHasTruceWithTrigger>::[1] |
| 0x140720620 | TGameItemDatabase<NCountry::CMetadataDatabase>::[1] func_names 名 TGameItemDatabase<NCountry::CMetadataDatabase>::[1] |
| 0x1409B8440 | TGameItemDatabase<CDifficultySettingsDatabase>::[1] func_names 名 TGameItemDatabase<CDifficultySettingsDatabase>::[1] |
| 0x14030C180 | CEffectEntry<CSetStateFlagEffect>::[1] func_names 名 CEffectEntry<CSetStateFlagEffect>::[1] |
| 0x14033CF30 | CEffectEntry<CCountryEventEffect>::[1] func_names 名 CEffectEntry<CCountryEventEffect>::[1] |
| 0x1403E3820 | CTriggerEntry<CAnyWarScoreTrigger>::[1] func_names 名 CTriggerEntry<CAnyWarScoreTrigger>::[1] |
| 0x1403E6100 | CTriggerEntry<CHasManpowerTrigger>::[1] func_names 名 CTriggerEntry<CHasManpowerTrigger>::[1] |
| 0x1403E80F0 | CTriggerEntry<CIsSubjectOfTrigger>::[1] func_names 名 CTriggerEntry<CIsSubjectOfTrigger>::[1] |
| 0x1403E8ED0 | CTriggerEntry<COriginalTagTrigger>::[1] func_names 名 CTriggerEntry<COriginalTagTrigger>::[1] |
| 0x1403E9420 | CTriggerEntry<CSetVariableTrigger>::[1] func_names 名 CTriggerEntry<CSetVariableTrigger>::[1] |
| 0x140468240 | CTriggerEntry<CIsClaimedByTrigger>::[1] func_names 名 CTriggerEntry<CIsClaimedByTrigger>::[1] |
| 0x140468820 | CTriggerEntry<COccupiedTagTrigger>::[1] func_names 名 CTriggerEntry<COccupiedTagTrigger>::[1] |
| 0x140476320 | CTriggerEntry<CTemperatureTrigger>::[1] func_names 名 CTriggerEntry<CTemperatureTrigger>::[1] |
| 0x1404A75D0 | CTriggerEntry<CNumNukesLeftToDrop>::[1] func_names 名 CTriggerEntry<CNumNukesLeftToDrop>::[1] |
| 0x1406BC060 | TGameItemDatabase<CCharacterTemplateDatabase>::[1] func_names 名 TGameItemDatabase<CCharacterTemplateDatabase>::[1] |
| 0x1402A0900 | CNudgeIdler::Update func_names 名 CNudgeIdler::Update |
| 0x14033DD40 | CEffectEntry<CEveryCountryEffect>::[1] func_names 名 CEffectEntry<CEveryCountryEffect>::[1] |
| 0x140341F60 | CEffectEntry<CSetVariableEffect>::[1] func_names 名 CEffectEntry<CSetVariableEffect>::[1] |
| 0x1403E3DD0 | CTriggerEntry<CCasualtiesTrigger>::[1] func_names 名 CTriggerEntry<CCasualtiesTrigger>::[1] |
| 0x1403E4520 | CTriggerEntry<CCountryFlagTrigger>::[1] func_names 名 CTriggerEntry<CCountryFlagTrigger>::[1] |
| 0x1403E4860 | CTriggerEntry<CDifficultyTrigger>::[1] func_names 名 CTriggerEntry<CDifficultyTrigger>::[1] |
| 0x1403E6AF0 | CTriggerEntry<CHasSubjectTrigger>::[1] func_names 名 CTriggerEntry<CHasSubjectTrigger>::[1] |
| 0x1403E7060 | CTriggerEntry<CHasWarWithTrigger>::[1] func_names 名 CTriggerEntry<CHasWarWithTrigger>::[1] |
| 0x1403E75B0 | CTriggerEntry<CIsExiledInTrigger>::[1] func_names 名 CTriggerEntry<CIsExiledInTrigger>::[1] |
| 0x1403E7EB0 | CTriggerEntry<CIsPuppetOfTrigger>::[1] func_names 名 CTriggerEntry<CIsPuppetOfTrigger>::[1] |
| 0x1403E89D0 | CTriggerEntry<CNumFactionMembers>::[1] func_names 名 CTriggerEntry<CNumFactionMembers>::[1] |
| 0x1403E8CD0 | CTriggerEntry<CNumOfNukesTrigger>::[1] func_names 名 CTriggerEntry<CNumOfNukesTrigger>::[1] |
| 0x140444C70 | CTriggerEntry<CIsExileLeaderFrom>::[1] func_names 名 CTriggerEntry<CIsExileLeaderFrom>::[1] |
| 0x140467FA0 | CTriggerEntry<CComplianceTrigger>::[1] func_names 名 CTriggerEntry<CComplianceTrigger>::[1] |
| 0x140468930 | CTriggerEntry<CResistanceTrigger>::[1] func_names 名 CTriggerEntry<CResistanceTrigger>::[1] |
| 0x1404761E0 | CTriggerEntry<CProvinceVpTrigger>::[1] func_names 名 CTriggerEntry<CProvinceVpTrigger>::[1] |
| 0x141460540 | CScientistLevel::SSkillLevel::Reader func_names 名 CScientistLevel::SSkillLevel::Reader |
| 0x1403E4D00 | CTriggerEntry<CGlobalFlagTrigger>::[1] func_names 名 CTriggerEntry<CGlobalFlagTrigger>::[1] |
| 0x1403E8F10 | CTriggerEntry<COwnsStateTrigger>::[1] func_names 名 CTriggerEntry<COwnsStateTrigger>::[1] |
| 0x1403E9750 | CTriggerEntry<CWarLengthTrigger>::[1] func_names 名 CTriggerEntry<CWarLengthTrigger>::[1] |
| 0x140444DF0 | CTriggerEntry<CIsInStateTrigger>::[1] func_names 名 CTriggerEntry<CIsInStateTrigger>::[1] |
| 0x1404685A0 | CTriggerEntry<CIsOwnedByTrigger>::[1] func_names 名 CTriggerEntry<CIsOwnedByTrigger>::[1] |
| 0x140A807B0 | TGameItemDatabase<COpinionModifierDatabase>::[1] func_names 名 TGameItemDatabase<COpinionModifierDatabase>::[1] |
| 0x14033DFD0 | CEffectEntry<CEveryStateEffect>::[1] func_names 名 CEffectEntry<CEveryStateEffect>::[1] |
| 0x14033F290 | CEffectEntry<CNewsEventEffect>::[1] func_names 名 CEffectEntry<CNewsEventEffect>::[1] |
| 0x1403E4E50 | CTriggerEntry<CHasAnnexWarGoal>::[1] func_names 名 CTriggerEntry<CHasAnnexWarGoal>::[1] |
| 0x140475AE0 | CTriggerEntry<CHardnessTrigger>::[1] func_names 名 CTriggerEntry<CHardnessTrigger>::[1] |
| 0x140476260 | CTriggerEntry<CReservesTrigger>::[1] func_names 名 CTriggerEntry<CReservesTrigger>::[1] |
| 0x1409CAE40 | TGameItemDatabase<NDLC::CMetadataDatabase>::[1] func_names 名 TGameItemDatabase<NDLC::CMetadataDatabase>::[1] |
| 0x140BD7EB0 | CEquipmentVariant::CreateNewId func_names 名 CEquipmentVariant::CreateNewId |
| 0x140CE8740 | CMilitaryDeploymentConveyor::CreateNewId func_names 名 CMilitaryDeploymentConveyor::CreateNewId |
| 0x140CE8780 | CMilitaryDeploymentLine::CreateNewId func_names 名 CMilitaryDeploymentLine::CreateNewId |
| 0x140E8D2F0 | CRailwayGun::Exile func_names 名 CRailwayGun::Exile |
| 0x1403E5DA0 | CTriggerEntry<CHasFuelTrigger>::[1] func_names 名 CTriggerEntry<CHasFuelTrigger>::[1] |
| 0x14045D1F0 | CEffectEntry<CEveryArmyEffect>::[1] func_names 名 CEffectEntry<CEveryArmyEffect>::[1] |
| 0x140468A60 | CTriggerEntry<CStateIDTrigger>::[1] func_names 名 CTriggerEntry<CStateIDTrigger>::[1] |
| 0x140475A50 | CTriggerEntry<CFastestTrigger>::[1] func_names 名 CTriggerEntry<CFastestTrigger>::[1] |
| 0x14203CAE0 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x142058E50 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x1403E9710 | CTriggerEntry<CThreatTrigger>::[1] func_names 名 CTriggerEntry<CThreatTrigger>::[1] |
| 0x140442300 | CHasAirLedger::Evaluate func_names 名 CHasAirLedger::Evaluate |
| 0x140442350 | CHasArmyLedger::Evaluate func_names 名 CHasArmyLedger::Evaluate |
| 0x140442490 | CHasNavyLedger::Evaluate func_names 名 CHasNavyLedger::Evaluate |
| 0x140475980 | CTriggerEntry<CArmorTrigger>::[1] func_names 名 CTriggerEntry<CArmorTrigger>::[1] |
| 0x140475A10 | CTriggerEntry<CDiginTrigger>::[1] func_names 名 CTriggerEntry<CDiginTrigger>::[1] |
| 0x1404762E0 | CTriggerEntry<CSkillTrigger>::[1] func_names 名 CTriggerEntry<CSkillTrigger>::[1] |
| 0x141393010 | CEffectEntry<CHiddenEffect>::[1] func_names 名 CEffectEntry<CHiddenEffect>::[1] |
| 0x1403E9690 | CTriggerEntry<CTagTrigger>::[1] func_names 名 CTriggerEntry<CTagTrigger>::[1] |
| 0x140443E30 | CIsUnitLeader::Evaluate func_names 名 CIsUnitLeader::Evaluate |
| 0x142355A80 | TObservable<鈥�>::[0] func_names 名 TObservable<鈥�>::[0] |
| 0x140441FC0 | CCanBeCaptured::Evaluate func_names 名 CCanBeCaptured::Evaluate |
| 0x140AD5D90 | TGameItemDatabase<CTerrainDatabase>::[1] func_names 名 TGameItemDatabase<CTerrainDatabase>::[1] |
| 0x142355A50 | TObservable<鈥�>::[0] func_names 名 TObservable<鈥�>::[0] |
| 0x1412739B0 | CFileWatcher::Reload func_names 名 CFileWatcher::Reload |
| 0x140E787E0 | COnDelay<鈥�>::Writer func_names 名 COnDelay<鈥�>::Writer |
| 0x1412B9010 | CLandCombat::CreateNewId func_names 名 CLandCombat::CreateNewId |
| 0x14241F660 | CPdxResourceCache<VCString::CTextureResource>::[0] func_names 名 CPdxResourceCache<VCString::CTextureResource>::[0] |
| 0x141CF0420 | TListenerTrait<鈥�>::[1] func_names 名 TListenerTrait<鈥�>::[1] |
| 0x142355AB0 | TObservable<鈥�>::[0] func_names 名 TObservable<鈥�>::[0] |
| 0x1401ADA50 | CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[9] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[9] |
| 0x140F58C90 | VCOperativeLeader::V?$CConstRef::AEBV?$CPdxArray::AXAEBVCCountr鈥�::[3] func_names 名 VCOperativeLeader::V?$CConstRef::AEBV?$CPdxArray::AXAEBVCCountr鈥�::[3] |
| 0x141CCEBA0 | CLegacyButtonObserverGlue<CFrontEndFriendsFriendEntry>::[0] func_names 名 CLegacyButtonObserverGlue<CFrontEndFriendsFriendEntry>::[0] |
| 0x14151E8A0 | CStatePeaceAction::GetTargetName func_names 名 CStatePeaceAction::GetTargetName |
| 0x14222BCC0 | TObservable<VCApplicationClassObservable::CApplicationObserver>::[0] func_names 名 TObservable<VCApplicationClassObservable::CApplicationObserver>::[0] |
| 0x1422305A0 | TObservable<VCKeyReleasedClassObservable::CKeyReleasedObserver>::[0] func_names 名 TObservable<VCKeyReleasedClassObservable::CKeyReleasedObserver>::[0] |
| 0x14224F4E0 | TObservable<VCSessionInfoClassObservable::CSessionInfoObserver>::[0] func_names 名 TObservable<VCSessionInfoClassObservable::CSessionInfoObserver>::[0] |
| 0x1422E7E10 | TObservable<VCChatMessageClassObservable::CChatMessageObserver>::[0] func_names 名 TObservable<VCChatMessageClassObservable::CChatMessageObserver>::[0] |
| 0x142230570 | TObservable<VCKeyPressedClassObservable::CKeyPressedObserver>::[0] func_names 名 TObservable<VCKeyPressedClassObservable::CKeyPressedObserver>::[0] |
| 0x1422EDA70 | TObservable<VCTextBufferClassObservable::CTextBufferObserver>::[0] func_names 名 TObservable<VCTextBufferClassObservable::CTextBufferObserver>::[0] |
| 0x142355AE0 | TObservable<VCMouseMovedClassObservable::CMouseMovedObserver>::[0] func_names 名 TObservable<VCMouseMovedClassObservable::CMouseMovedObserver>::[0] |
| 0x142355B10 | TObservable<VCMouseWheelClassObservable::CMouseWheelObserver>::[0] func_names 名 TObservable<VCMouseWheelClassObservable::CMouseWheelObserver>::[0] |
| 0x14029E8D0 | TObservable<V1::CSelectionListObserver>::[0] func_names 名 TObservable<V1::CSelectionListObserver>::[0] |
| 0x1422AF280 | TObservable<VCButtonClassObservable::CButtonEventDispatcher>::[0] func_names 名 TObservable<VCButtonClassObservable::CButtonEventDispatcher>::[0] |
| 0x1422A5CD0 | TObservable<VCScrollbarClassObservable::CScrollbarObserver>::[0] func_names 名 TObservable<VCScrollbarClassObservable::CScrollbarObserver>::[0] |
| 0x141934000 | TListenerTrait<$0A::NIndustrialOrganisation::COrganisation>::[1] func_names 名 TListenerTrait<$0A::NIndustrialOrganisation::COrganisation>::[1] |
| 0x141FFB7A0 | TListenerTrait<$0A::NInternationalMarket::CMarketStockpile>::[1] func_names 名 TListenerTrait<$0A::NInternationalMarket::CMarketStockpile>::[1] |
| 0x1422C8E20 | TObservable<VCCheckBoxClassObservable::CCheckBoxObserver>::[0] func_names 名 TObservable<VCCheckBoxClassObservable::CCheckBoxObserver>::[0] |
| 0x141709D50 | CCountryMilitaryOverview::PreSetup func_names 名 CCountryMilitaryOverview::PreSetup |
| 0x1422A9A50 | TObservable<VCOptionClassObservable::COptionObserver>::[0] func_names 名 TObservable<VCOptionClassObservable::COptionObserver>::[0] |
| 0x1422B6D90 | TObservable<VCWindowClassObservable::CWindowObserver>::[0] func_names 名 TObservable<VCWindowClassObservable::CWindowObserver>::[0] |
| 0x141127FC0 | CGuaranteeAction::GetEnableTriggerOverridesGame func_names 名 CGuaranteeAction::GetEnableTriggerOverridesGame |
| 0x141128100 | CEmbargoAction::GetEnableTrigger func_names 名 CEmbargoAction::GetEnableTrigger |
| 0x141128130 | CGenerateWarGoalAction::GetEnableTrigger func_names 名 CGenerateWarGoalAction::GetEnableTrigger |
| 0x141128160 | CGuaranteeAction::GetEnableTrigger func_names 名 CGuaranteeAction::GetEnableTrigger |
| 0x1422FCAC0 | C2dPieChartTemplate<SPieVertex>::[2] func_names 名 C2dPieChartTemplate<SPieVertex>::[2] |
| 0x1422FCB00 | C2dPieChartTemplate<STexturedPieVertex>::[2] func_names 名 C2dPieChartTemplate<STexturedPieVertex>::[2] |
| 0x142379430 | TNullGuiObjectTrait<CNullOverlappingElementsBox>::[0] func_names 名 TNullGuiObjectTrait<CNullOverlappingElementsBox>::[0] |
| 0x1419763F0 | CFEXMember::CLastTargetInfo::Writer func_names 名 CFEXMember::CLastTargetInfo::Writer |
| 0x14047BFB0 | CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[0] func_names 名 CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[0] |
| 0x14047C130 | CVariableTriggerBuilder<鈥�>::[0] func_names 名 CVariableTriggerBuilder<鈥�>::[0] |
| 0x14186C740 | （无名） 体设 CChatMessageObserver::vftable（RTTI 名） |
| 0x1422B6C70 | SGuiObjectFunctorWrapper<SCollidableFunctor>::[0] func_names 名 SGuiObjectFunctorWrapper<SCollidableFunctor>::[0] |
| 0x140C0EA10 | TListenerTrait<$00::CCustomizableBuildingItem>::[2] func_names 名 TListenerTrait<$00::CCustomizableBuildingItem>::[2] |
| 0x140F6E810 | CMilitaryProductionLine::CreateNewId func_names 名 CMilitaryProductionLine::CreateNewId |
| 0x141332810 | （无名） 体设 CTextBufferObserver::vftable（RTTI 名） |
| 0x1423793A0 | TNullGuiObjectTrait<CNullExtendedScrollbar>::[0] func_names 名 TNullGuiObjectTrait<CNullExtendedScrollbar>::[0] |
| 0x1416CCD80 | CUnitLeaderTraitTree::PreSetup func_names 名 CUnitLeaderTraitTree::PreSetup |
| 0x14015E6A0 | TListenerTrait<$0A::CEquipmentGroupDatabase>::[1] func_names 名 TListenerTrait<$0A::CEquipmentGroupDatabase>::[1] |
| 0x1416EAC60 | （无名） 体设 CScrollbarObserver::vftable（RTTI 名） |
| 0x142379310 | TNullGuiObjectTrait<CNullContainerWindow>::[0] func_names 名 TNullGuiObjectTrait<CNullContainerWindow>::[0] |
| 0x142379490 | TNullGuiObjectTrait<CNullStandardGridBox>::[0] func_names 名 TNullGuiObjectTrait<CNullStandardGridBox>::[0] |
| 0x1423794C0 | TNullGuiObjectTrait<CNullStandardListBox>::[0] func_names 名 TNullGuiObjectTrait<CNullStandardListBox>::[0] |
| 0x1401C5460 | 7d6384c0f2a3ae6bfeb60f8cebe04338::.??::[1] func_names 名 7d6384c0f2a3ae6bfeb60f8cebe04338::.??::[1] |
| 0x1401C5980 | 5eb711553f2f6b3473bab6d06caba33d::.??::[1] func_names 名 5eb711553f2f6b3473bab6d06caba33d::.??::[1] |
| 0x1423792B0 | TNullGuiObjectTrait<CNullButtonStandard>::[0] func_names 名 TNullGuiObjectTrait<CNullButtonStandard>::[0] |
| 0x142379400 | TNullGuiObjectTrait<CNullInstantTextBox>::[0] func_names 名 TNullGuiObjectTrait<CNullInstantTextBox>::[0] |
| 0x142379460 | TNullGuiObjectTrait<CNullSmoothListBox>::[0] func_names 名 TNullGuiObjectTrait<CNullSmoothListBox>::[0] |
| 0x1411BF5A0 | traits<char,boost::xpressive::detail>::[0] func_names 名 traits<char,boost::xpressive::detail>::[0] |
| 0x141CFF650 | TListenerTrait<$0A::CRailwayGunViewEntry>::[1] func_names 名 TListenerTrait<$0A::CRailwayGunViewEntry>::[1] |
| 0x14011F8C0 | （无名） 体设 Facet_base::vftable（RTTI 名） |
| 0x14044CCC0 | CCanFireAdvisor::ParseToken func_names 名 CCanFireAdvisor::ParseToken |
| 0x142379340 | TNullGuiObjectTrait<CNullDropDownBox>::[0] func_names 名 TNullGuiObjectTrait<CNullDropDownBox>::[0] |
| 0x14047BEF0 | CVariableEffectBuilder<鈥�>::[0] func_names 名 CVariableEffectBuilder<鈥�>::[0] |
| 0x14047BF30 | CVariableEffectBuilder<鈥�>::[0] func_names 名 CVariableEffectBuilder<鈥�>::[0] |
| 0x14047BF70 | CVariableEffectBuilder<CGetSupplyVehicles<CVariableResolver>>::[0] func_names 名 CVariableEffectBuilder<CGetSupplyVehicles<CVariableResolver>>::[0] |
| 0x14047BFF0 | CVariableEffectBuilder<CSetToRandomValue<CVariableResolver>>::[0] func_names 名 CVariableEffectBuilder<CSetToRandomValue<CVariableResolver>>::[0] |
| 0x14047C030 | CVariableTriggerBuilder<鈥�>::[0] func_names 名 CVariableTriggerBuilder<鈥�>::[0] |
| 0x14047C070 | CVariableTriggerBuilder<鈥�>::[0] func_names 名 CVariableTriggerBuilder<鈥�>::[0] |
| 0x14047C0B0 | CVariableTriggerBuilder<鈥�>::[0] func_names 名 CVariableTriggerBuilder<鈥�>::[0] |
| 0x14047C0F0 | CVariableTriggerBuilder<CModuloVariable<CTempVariableResolver>>::[0] func_names 名 CVariableTriggerBuilder<CModuloVariable<CTempVariableResolver>>::[0] |
| 0x142379280 | TNullGuiObjectTrait<CNullButtonDrag>::[0] func_names 名 TNullGuiObjectTrait<CNullButtonDrag>::[0] |
| 0x141B909D0 | TListenerTrait<$0A::CProductionStatus>::[1] func_names 名 TListenerTrait<$0A::CProductionStatus>::[1] |
| 0x1422B6CA0 | SGuiObjectFunctorWrapper<SSetScopeFunctor>::[0] func_names 名 SGuiObjectFunctorWrapper<SSetScopeFunctor>::[0] |
| 0x1422B6CC0 | SGuiObjectFunctorWrapper<SSetTooltipHandler>::[0] func_names 名 SGuiObjectFunctorWrapper<SSetTooltipHandler>::[0] |
| 0x1423E75F0 | CPdxHybridInlineBufferAllocator<H::E$0CAAA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::E$0CAAA>::[4] |
| 0x1404B3120 | CSetFactionMemberUpgradeMin::ParseToken func_names 名 CSetFactionMemberUpgradeMin::ParseToken |
| 0x1412663B0 | CPdxHybridInlineBufferAllocator<H::$0CAA::SMapArrowVertex>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CAA::SMapArrowVertex>::[4] |
| 0x1423792E0 | TNullGuiObjectTrait<CNullCheckBox>::[0] func_names 名 TNullGuiObjectTrait<CNullCheckBox>::[0] |
| 0x1401611D0 | CPdxHybridInlineBufferAllocator<H::D$0EAA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::D$0EAA>::[4] |
| 0x1403EEB70 | CNumResearchedTechnologies::GetValue func_names 名 CNumResearchedTechnologies::GetValue |
| 0x140A31080 | SUniformReader<鈥�>::[1] func_names 名 SUniformReader<鈥�>::[1] |
| 0x140A94810 | SUniformReader<鈥�>::[1] func_names 名 SUniformReader<鈥�>::[1] |
| 0x140DFD520 | CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[4] |
| 0x14187B060 | CPdxHybridInlineBufferAllocator<H::$0BF::SRenderParticle>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BF::SRenderParticle>::[4] |
| 0x141996910 | TListenerTrait<$0A::CFriendsHandler>::[1] func_names 名 TListenerTrait<$0A::CFriendsHandler>::[1] |
| 0x14200F150 | TListenerTrait<$0A::CControllerArea>::[1] func_names 名 TListenerTrait<$0A::CControllerArea>::[1] |
| 0x1420A6DE0 | CPdxHybridInlineBufferAllocator<H::$0BA::SParticleRenderData>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BA::SParticleRenderData>::[4] |
| 0x142379250 | TNullGuiObjectTrait<CNullBrowser>::[0] func_names 名 TNullGuiObjectTrait<CNullBrowser>::[0] |
| 0x142379370 | TNullGuiObjectTrait<CNullEditBox>::[0] func_names 名 TNullGuiObjectTrait<CNullEditBox>::[0] |
| 0x1401611E0 | CPdxHybridInlineBufferAllocator<H::H$0BAA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0BAA>::[4] |
| 0x1401611F0 | CPdxHybridInlineBufferAllocator<H::H$0IA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0IA>::[4] |
| 0x1401FFAF0 | CPdxHybridInlineBufferAllocator<H::H$0GE>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0GE>::[4] |
| 0x140EC48E0 | CPdxHybridInlineBufferAllocator<H::F$0CAA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::F$0CAA>::[4] |
| 0x141C31DF0 | CChangeDesignFolderPopUp::Update func_names 名 CChangeDesignFolderPopUp::Update |
| 0x141C31E20 | CCreateFolderPopUp::Update func_names 名 CCreateFolderPopUp::Update |
| 0x141C31E50 | CDeleteDesignPopUp::Update func_names 名 CDeleteDesignPopUp::Update |
| 0x141C31E80 | CDeleteOrRenameFolderPopUp::Update func_names 名 CDeleteOrRenameFolderPopUp::Update |
| 0x141C31ED0 | CSaveDesignToFilePopUp::Update func_names 名 CSaveDesignToFilePopUp::Update |
| 0x141F6C6B0 | CConfirmDeleteEquipment::Update func_names 名 CConfirmDeleteEquipment::Update |
| 0x14222BD70 | CPdxHybridInlineBufferAllocator<CMatrix<$03H::M$03$03>>::[4] func_names 名 CPdxHybridInlineBufferAllocator<CMatrix<$03H::M$03$03>>::[4] |
| 0x1423EFCB0 | CPdxHybridInlineBufferAllocator<$08H::SParticle>::[4] func_names 名 CPdxHybridInlineBufferAllocator<$08H::SParticle>::[4] |
| 0x140120520 | CPdxHybridInlineBufferAllocator<H::H$0CA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0CA>::[4] |
| 0x1401611C0 | CPdxHybridInlineBufferAllocator<H::D$0BF>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::D$0BF>::[4] |
| 0x140161200 | CPdxHybridInlineBufferAllocator<H::$0CK::SDamageEntry>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CK::SDamageEntry>::[4] |
| 0x140161220 | CPdxHybridInlineBufferAllocator<H::H$0EA>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0EA>::[4] |
| 0x140161250 | CPdxHybridInlineBufferAllocator<H::$0BJ::CIntelSource>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BJ::CIntelSource>::[4] |
| 0x1402CD550 | CPdxHybridInlineBufferAllocator<H::$0BE::EBVCCombatTactic*>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BE::EBVCCombatTactic*>::[4] |
| 0x140638DA0 | CPdxHybridInlineBufferAllocator<H::H$0BC>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0BC>::[4] |
| 0x140683640 | CPdxHybridInlineBufferAllocator<鈥�>::[4] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[4] |
| 0x140A26810 | CPdxHybridInlineBufferAllocator<H$09H>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H$09H>::[4] |
| 0x140A9BAD0 | CPdxHybridInlineBufferAllocator<H::$0DD::CBitmapFont::SVertex>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0DD::CBitmapFont::SVertex>::[4] |
| 0x140B64560 | CPdxHybridInlineBufferAllocator<H::$0O::SYmlRow>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0O::SYmlRow>::[4] |
| 0x140CD9410 | CPdxHybridInlineBufferAllocator<H::H$0BO>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0BO>::[4] |
| 0x140D7DAB0 | CPdxHybridInlineBufferAllocator<H::$0M::EAVCArmy*>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0M::EAVCArmy*>::[4] |
| 0x140DC53A0 | CPdxHybridInlineBufferAllocator<H::$0N::CString>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0N::CString>::[4] |
| 0x140F31510 | H::$0BH::CPdxStaticInlineBufferAllocator<bool>::[4] func_names 名 H::$0BH::CPdxStaticInlineBufferAllocator<bool>::[4] |
| 0x1411D0C80 | CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[4] |
| 0x1415AF690 | CPdxHybridInlineBufferAllocator<H::$0BI::EBVCArmy*>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BI::EBVCArmy*>::[4] |
| 0x142092F20 | CPdxHybridInlineBufferAllocator<H::$0P::SCurveValue>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H::$0P::SCurveValue>::[4] |
| 0x1423794F0 | TNullGuiObjectTrait<CNullTrack>::[0] func_names 名 TNullGuiObjectTrait<CNullTrack>::[0] |
| 0x140161210 | CPdxStaticInlineBufferAllocator<$00H::EBVCState*>::[4] func_names 名 CPdxStaticInlineBufferAllocator<$00H::EBVCState*>::[4] |
| 0x140161240 | CPdxHybridInlineBufferAllocator<$06H::LexerToken>::[4] func_names 名 CPdxHybridInlineBufferAllocator<$06H::LexerToken>::[4] |
| 0x140161260 | CPdxStaticInlineBufferAllocator<I$01H>::[4] func_names 名 CPdxStaticInlineBufferAllocator<I$01H>::[4] |
| 0x140161280 | CPdxHybridInlineBufferAllocator<H$07H>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H$07H>::[4] |
| 0x1402CD560 | CPdxHybridInlineBufferAllocator<H$08H>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H$08H>::[4] |
| 0x14054AB20 | CPdxHybridInlineBufferAllocator<H$04H>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H$04H>::[4] |
| 0x140A02EC0 | CPdxStaticInlineBufferAllocator<H$02H>::[4] func_names 名 CPdxStaticInlineBufferAllocator<H$02H>::[4] |
| 0x140A35B70 | CPdxHybridInlineBufferAllocator<H$05H>::[4] func_names 名 CPdxHybridInlineBufferAllocator<H$05H>::[4] |
| 0x1423793D0 | TNullGuiObjectTrait<CNullIcon>::[0] func_names 名 TNullGuiObjectTrait<CNullIcon>::[0] |
| 0x140ED4CB0 | TListenerTrait<$0A::CTechnology>::[1] func_names 名 TListenerTrait<$0A::CTechnology>::[1] |
| 0x141F6B7B0 | CConfirmDeleteEquipmentProductionLine::Update func_names 名 CConfirmDeleteEquipmentProductionLine::Update |
| 0x140B9E920 | CReferencedDivisionTemplate::CreateNewId func_names 名 CReferencedDivisionTemplate::CreateNewId |
| 0x140F6F020 | CNavalProductionLine::CreateNewId func_names 名 CNavalProductionLine::CreateNewId |
| 0x140F6FA60 | CRailwayGunProductionLine::CreateNewId func_names 名 CRailwayGunProductionLine::CreateNewId |
| 0x140F6FA90 | CRailwayGunRepairLine::CreateNewId func_names 名 CRailwayGunRepairLine::CreateNewId |
| 0x140F712A0 | CRocketProductionLine::CreateNewId func_names 名 CRocketProductionLine::CreateNewId |
| 0x140F71B60 | CShipRefitProductionLine::CreateNewId func_names 名 CShipRefitProductionLine::CreateNewId |
| 0x14104C560 | COrderInstance::SOrderInstanceRef::Writer func_names 名 COrderInstance::SOrderInstanceRef::Writer |
| 0x1405271A0 | CCheckExpression::Evaluate func_names 名 CCheckExpression::Evaluate |
| 0x141333220 | CTextBufferObserverGlue<CChat>::[0] func_names 名 CTextBufferObserverGlue<CChat>::[0] |
| 0x141697B50 | CTextBufferObserverGlue<CConsole>::[0] func_names 名 CTextBufferObserverGlue<CConsole>::[0] |
| 0x142306A90 | CButtonDrag::[77] vtable 槽 CButtonDrag::[77]（func_names RTTI 名） |
| 0x14146CC60 | CScrollbarObserverGlue<CSubWndPair>::[0] func_names 名 CScrollbarObserverGlue<CSubWndPair>::[0] |
| 0x141519640 | CStatePeaceAction::GetBaseValue func_names 名 CStatePeaceAction::GetBaseValue |
| 0x1417527D0 | CScrollbarObserverGlue<CSmoothListbox>::[0] func_names 名 CScrollbarObserverGlue<CSmoothListbox>::[0] |
| 0x1422D1E30 | CButtonStandard::[97] vtable 槽 CButtonStandard::[97]（func_names RTTI 名） |
| 0x140441F50 | CTriggerEntry<CHasContestedOwner>::[0] func_names 名 CTriggerEntry<CHasContestedOwner>::[0] |
| 0x1412D4380 | CCheckBoxObserverGlue<CNudgeIdler>::[0] func_names 名 CCheckBoxObserverGlue<CNudgeIdler>::[0] |
| 0x14015EEA0 | messages<unsigned short,std>::[0] func_names 名 messages<unsigned short,std>::[0] |
| 0x14048FC20 | CEffectEntry<CAddCICEffect>::[0] func_names 名 CEffectEntry<CAddCICEffect>::[0] |
| 0x140AD5E20 | TNullObject<V1::CTerrainType>::[0] func_names 名 TNullObject<V1::CTerrainType>::[0] |
| 0x140D64480 | CPdxTypedInlineLinearAllocator<$0IA::EBVCStrategicRegion*>::[0] func_names 名 CPdxTypedInlineLinearAllocator<$0IA::EBVCStrategicRegion*>::[0] |
| 0x1422A9920 | CFixedMaxSizeListbox<CStandardlistboxItem>::[0] func_names 名 CFixedMaxSizeListbox<CStandardlistboxItem>::[0] |
| 0x14203E050 | AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[2] func_names 名 AEBUSListItemConfig::AEBUSListConfig::AEAVCContainerWindow::QEA鈥�::[2] |
| 0x140BB0850 | W4ModifierCategory::W4ModifierType::VCModifier::XAEBV?$CPdxModi鈥�::[3] func_names 名 W4ModifierCategory::W4ModifierType::VCModifier::XAEBV?$CPdxModi鈥�::[3] |
| 0x1416E3D50 | CClickableStandardGridBoxItem<CBoostIdeologyMissionItem>::[0] func_names 名 CClickableStandardGridBoxItem<CBoostIdeologyMissionItem>::[0] |
| 0x141E21E40 | CClickableStandardGridBoxItem<鈥�>::[0] func_names 名 CClickableStandardGridBoxItem<鈥�>::[0] |
| 0x14231C2E0 | CMatchmakingGui::Reload func_names 名 CMatchmakingGui::Reload |
| 0x14131A6B0 | spawner<鈥�>::[0] func_names 名 spawner<鈥�>::[0] |
| 0x14015EF30 | boost::signals2::23::Vmutex::3::Z::signal<鈥�>::[0] func_names 名 boost::signals2::23::Vmutex::3::Z::signal<鈥�>::[0] |
| 0x1401ADA30 | CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[13] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[13] |
| 0x14149BB90 | CClickableStandardGridBoxItem<CDesignFolderListItem>::[0] func_names 名 CClickableStandardGridBoxItem<CDesignFolderListItem>::[0] |
| 0x14149BC90 | CClickableStandardGridBoxItem<CHistoricalDesignItem>::[0] func_names 名 CClickableStandardGridBoxItem<CHistoricalDesignItem>::[0] |
| 0x14155C920 | CEmptyEntryListBase<COccupiedTerritoryStateEntry>::[0] func_names 名 CEmptyEntryListBase<COccupiedTerritoryStateEntry>::[0] |
| 0x14167D9C0 | TReloadListener<$0A>::[0] func_names 名 TReloadListener<$0A>::[0] |
| 0x141E46BC0 | CEmptyEntryListBase<CPeaceAvailableActionItem>::[0] func_names 名 CEmptyEntryListBase<CPeaceAvailableActionItem>::[0] |
| 0x141FB5520 | CClickableStandardGridBoxItem<鈥�>::[0] func_names 名 CClickableStandardGridBoxItem<鈥�>::[0] |
| 0x14222BC50 | CObservable<VCApplicationClassObservable::CApplicationObserver>::[0] func_names 名 CObservable<VCApplicationClassObservable::CApplicationObserver>::[0] |
| 0x1422A99E0 | CSimpleListbox<CStandardlistboxItem>::[0] func_names 名 CSimpleListbox<CStandardlistboxItem>::[0] |
| 0x1422AF240 | CObservable<VCButtonClassObservable::CButtonEventDispatcher>::[0] func_names 名 CObservable<VCButtonClassObservable::CButtonEventDispatcher>::[0] |
| 0x1422ABE50 | CSmoothListbox::[15] vtable 槽 CSmoothListbox::[15]（func_names RTTI 名） |
| 0x1422AA1A0 | CSmoothListbox::[1] vtable 槽 CSmoothListbox::[1]（func_names RTTI 名） |
| 0x1422B6C60 | SGuiObjectFunctorWrapper<HideFunctor>::[0] func_names 名 SGuiObjectFunctorWrapper<HideFunctor>::[0] |
| 0x1422B6C90 | SGuiObjectFunctorWrapper<SRelocalizeFunctor>::[0] func_names 名 SGuiObjectFunctorWrapper<SRelocalizeFunctor>::[0] |
| 0x1422B6CE0 | SGuiObjectFunctorWrapper<ShowFunctor>::[0] func_names 名 SGuiObjectFunctorWrapper<ShowFunctor>::[0] |
| 0x1406AF400 | CChoice<CSmoothListboxItem>::[3] func_names 名 CChoice<CSmoothListboxItem>::[3] |
| 0x14151A530 | CStatePeaceAction::AddStackableType func_names 名 CStatePeaceAction::AddStackableType |
| 0x141981BA0 | CNavalBlockadeRelation::GetDesc func_names 名 CNavalBlockadeRelation::GetDesc |
| 0x1422AAA50 | CChoice<CSmoothListboxItem>::[2] func_names 名 CChoice<CSmoothListboxItem>::[2] |
| 0x14015D020 | CPersistentReloadableGameItemDatabase<鈥�>::[1] func_names 名 CPersistentReloadableGameItemDatabase<鈥�>::[1] |
| 0x14029E890 | CObservable<V1::CSelectionListObserver>::[0] func_names 名 CObservable<V1::CSelectionListObserver>::[0] |
| 0x1406BC130 | TNullObject<V1::CCountryLeaderTemplate>::[0] func_names 名 TNullObject<V1::CCountryLeaderTemplate>::[0] |
| 0x1409F1EB0 | TNullObject<V1::CEquipmentUpgrade>::[0] func_names 名 TNullObject<V1::CEquipmentUpgrade>::[0] |
| 0x140A40920 | TNullObject<V1::CIdeaCategory>::[0] func_names 名 TNullObject<V1::CIdeaCategory>::[0] |
| 0x140A67E20 | TNullObject<V1::CMessageType>::[0] func_names 名 TNullObject<V1::CMessageType>::[0] |
| 0x140A67E60 | TNullObject<V1::CMessageTypeSettings>::[0] func_names 名 TNullObject<V1::CMessageTypeSettings>::[0] |
| 0x140AC0190 | TNullObject<V1::CStrategicRegionTemplate>::[0] func_names 名 TNullObject<V1::CStrategicRegionTemplate>::[0] |
| 0x140AC1DC0 | TNullObject<V1::CStrategicResource>::[0] func_names 名 TNullObject<V1::CStrategicResource>::[0] |
| 0x140AC30B0 | TNullObject<V1::CSubUnitCategory>::[0] func_names 名 TNullObject<V1::CSubUnitCategory>::[0] |
| 0x140AD5DE0 | TNullObject<V1::CTerrainGraphics>::[0] func_names 名 TNullObject<V1::CTerrainGraphics>::[0] |
| 0x140AE1B30 | TNullObject<V1::CUnitMedal>::[0] func_names 名 TNullObject<V1::CUnitMedal>::[0] |
| 0x140B71670 | CMapIconManager<$0CC>::[0] func_names 名 CMapIconManager<$0CC>::[0] |
| 0x140E85660 | TReloadListener<$00>::[0] func_names 名 TReloadListener<$00>::[0] |
| 0x1413D47A0 | CEmptyEntryListBase<CTechnologyTreeTechItem>::[0] func_names 名 CEmptyEntryListBase<CTechnologyTreeTechItem>::[0] |
| 0x14149BB50 | CClickableStandardGridBoxItem<CDesignFolderItem>::[0] func_names 名 CClickableStandardGridBoxItem<CDesignFolderItem>::[0] |
| 0x14149BBD0 | CClickableStandardGridBoxItem<CDesignerEquipmentCreatorItem>::[0] func_names 名 CClickableStandardGridBoxItem<CDesignerEquipmentCreatorItem>::[0] |
| 0x14149BC10 | CClickableStandardGridBoxItem<CDesignerEquipmentRoleItem>::[0] func_names 名 CClickableStandardGridBoxItem<CDesignerEquipmentRoleItem>::[0] |
| 0x14149BC50 | CClickableStandardGridBoxItem<CDesignerEquipmentVariantItem>::[0] func_names 名 CClickableStandardGridBoxItem<CDesignerEquipmentVariantItem>::[0] |
| 0x14155C870 | CEmptyEntryListBase<COccupationModifierEntry>::[0] func_names 名 CEmptyEntryListBase<COccupationModifierEntry>::[0] |
| 0x14155C960 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x1415CE0A0 | CTacticsListView<CTacticsListEntry>::[0] func_names 名 CTacticsListView<CTacticsListEntry>::[0] |
| 0x1416D24A0 | CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[0] func_names 名 CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[0] |
| 0x1416F7E30 | CTacticsListView<CSelectCountryPreferredTacticsEntry>::[0] func_names 名 CTacticsListView<CSelectCountryPreferredTacticsEntry>::[0] |
| 0x141A1F3A0 | CEmptyEntryListBase<CCryptologyViewCountryEntry>::[0] func_names 名 CEmptyEntryListBase<CCryptologyViewCountryEntry>::[0] |
| 0x141DB9700 | CEmptyEntryListBase<CProductionSubUnitDefFilter>::[0] func_names 名 CEmptyEntryListBase<CProductionSubUnitDefFilter>::[0] |
| 0x141DD66A0 | CEmptyEntryListBase<CDesignerStatItem>::[0] func_names 名 CEmptyEntryListBase<CDesignerStatItem>::[0] |
| 0x141E11920 | CEmptyEntryListBase<CCompactShipEntry>::[0] func_names 名 CEmptyEntryListBase<CCompactShipEntry>::[0] |
| 0x141E21E00 | CClickableStandardGridBoxItem<鈥�>::[0] func_names 名 CClickableStandardGridBoxItem<鈥�>::[0] |
| 0x141E21EF0 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x141E46C00 | CEmptyEntryListBase<CPeaceClickAllEntry>::[0] func_names 名 CEmptyEntryListBase<CPeaceClickAllEntry>::[0] |
| 0x141E46C40 | CEmptyEntryListBase<CPeaceExpandableSeparatorEntry>::[0] func_names 名 CEmptyEntryListBase<CPeaceExpandableSeparatorEntry>::[0] |
| 0x141E4C7E0 | CEmptyEntryListBase<CPeaceBiddingItem>::[0] func_names 名 CEmptyEntryListBase<CPeaceBiddingItem>::[0] |
| 0x141E72380 | CEmptyEntryListBase<CNavyTheaterFleetRowItem>::[0] func_names 名 CEmptyEntryListBase<CNavyTheaterFleetRowItem>::[0] |
| 0x141EA5C00 | CEmptyEntryListBase<鈥�>::[0] func_names 名 CEmptyEntryListBase<鈥�>::[0] |
| 0x141F6DDE0 | CClickableStandardGridBoxItem<CEquipmentRoleIconEntry>::[0] func_names 名 CClickableStandardGridBoxItem<CEquipmentRoleIconEntry>::[0] |
| 0x141F78BD0 | CClickableStandardGridBoxItem<CEquipmentModuleCategoryEntry>::[0] func_names 名 CClickableStandardGridBoxItem<CEquipmentModuleCategoryEntry>::[0] |
| 0x141F78C10 | CClickableStandardGridBoxItem<CEquipmentModuleEntry>::[0] func_names 名 CClickableStandardGridBoxItem<CEquipmentModuleEntry>::[0] |
| 0x141F78C50 | CClickableStandardGridBoxItem<CEquipmentModuleRemovalEntry>::[0] func_names 名 CClickableStandardGridBoxItem<CEquipmentModuleRemovalEntry>::[0] |
| 0x142230530 | CObservable<VCKeyReleasedClassObservable::CKeyReleasedObserver>::[0] func_names 名 CObservable<VCKeyReleasedClassObservable::CKeyReleasedObserver>::[0] |
| 0x14224F4A0 | CObservable<VCSessionInfoClassObservable::CSessionInfoObserver>::[0] func_names 名 CObservable<VCSessionInfoClassObservable::CSessionInfoObserver>::[0] |
| 0x1422A5C90 | CObservable<VCScrollbarClassObservable::CScrollbarObserver>::[0] func_names 名 CObservable<VCScrollbarClassObservable::CScrollbarObserver>::[0] |
| 0x1422A98E0 | CChoiceObservable<CStandardlistboxItem>::[0] func_names 名 CChoiceObservable<CStandardlistboxItem>::[0] |
| 0x1422A99A0 | CObservable<VCOptionClassObservable::COptionObserver>::[0] func_names 名 CObservable<VCOptionClassObservable::COptionObserver>::[0] |
| 0x1422AA190 | CChoice<CSmoothListboxItem>::[1] func_names 名 CChoice<CSmoothListboxItem>::[1] |
| 0x1422C8DE0 | CObservable<VCCheckBoxClassObservable::CCheckBoxObserver>::[0] func_names 名 CObservable<VCCheckBoxClassObservable::CCheckBoxObserver>::[0] |
| 0x1422E7DD0 | CObservable<VCChatMessageClassObservable::CChatMessageObserver>::[0] func_names 名 CObservable<VCChatMessageClassObservable::CChatMessageObserver>::[0] |
| 0x1422EDA30 | CObservable<VCTextBufferClassObservable::CTextBufferObserver>::[0] func_names 名 CObservable<VCTextBufferClassObservable::CTextBufferObserver>::[0] |
| 0x1422FF770 | CChoiceObservable<CSmoothListboxItem>::[0] func_names 名 CChoiceObservable<CSmoothListboxItem>::[0] |
| 0x142355A10 | CObservable<VCMouseWheelClassObservable::CMouseWheelObserver>::[0] func_names 名 CObservable<VCMouseWheelClassObservable::CMouseWheelObserver>::[0] |
| 0x1424FBD40 | CChecksumFile::[12] vtable 槽 CChecksumFile::[12]（func_names RTTI 名） |
| 0x140D24000 | CNonAggressionPactRelation::GetDesc func_names 名 CNonAggressionPactRelation::GetDesc |
| 0x140D23F40 | CGuaranteeRelation::GetDesc func_names 名 CGuaranteeRelation::GetDesc |
| 0x140D23F70 | CImproveRelationsRelation::GetDesc func_names 名 CImproveRelationsRelation::GetDesc |
| 0x141981310 | CAirBaseAccessRelation::GetDesc func_names 名 CAirBaseAccessRelation::GetDesc |
| 0x140316450 | CCancelResistance::GetDesc func_names 名 CCancelResistance::GetDesc |
| 0x141981760 | CDockingRightsRelation::GetDesc func_names 名 CDockingRightsRelation::GetDesc |
| 0x141FB93E0 | AEBVCPersistedMioQueue::AEBVCPersistedMioQueueId::QEBA::AEAAXXZ鈥�::[3] func_names 名 AEBVCPersistedMioQueue::AEBVCPersistedMioQueueId::QEBA::AEAAXXZ鈥�::[3] |
| 0x140D23F10 | CEmbargoRelation::GetDesc func_names 名 CEmbargoRelation::GetDesc |
| 0x140D23E60 | CAttacheRelation::GetDesc func_names 名 CAttacheRelation::GetDesc |
| 0x14203CE30 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x142059A90 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x142069700 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x140AB2660 | CScriptedDiplomaticAction::GetActionTitleText func_names 名 CScriptedDiplomaticAction::GetActionTitleText |
| 0x141125000 | CEmbargoAction::[21] vtable 槽 CEmbargoAction::[21]（func_names RTTI 名） |
| 0x141519590 | CPeaceAction::IsOverlappingAction func_names 名 CPeaceAction::IsOverlappingAction |
| 0x1415D6F90 | CTacticsListView<CTacticsListEntry>::[5] func_names 名 CTacticsListView<CTacticsListEntry>::[5] |
| 0x1422A984C | CChoice<CStandardlistboxItem>::[0] func_names 名 CChoice<CStandardlistboxItem>::[0] |
| 0x1422FF6F4 | CChoice<CSmoothListboxItem>::[0] func_names 名 CChoice<CSmoothListboxItem>::[0] |
| 0x142399990 | CCallbackImpl<$03>::[0] func_names 名 CCallbackImpl<$03>::[0] |
| 0x140D23FA0 | CLicenceProductionAccessRelation::GetDesc func_names 名 CLicenceProductionAccessRelation::GetDesc |
| 0x140D23FD0 | CMilitaryAccessRelation::GetDesc func_names 名 CMilitaryAccessRelation::GetDesc |
| 0x140D24030 | CWarRelation::GetDesc func_names 名 CWarRelation::GetDesc |
| 0x1401ADA40 | CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[11] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CCountryTag>::[11] |
| 0x141FB9330 | AEBVCPersistedMioQueue::AEBVCPersistedMioQueueId::QEBA::AEAAXXZ鈥�::[2] func_names 名 AEBVCPersistedMioQueue::AEBVCPersistedMioQueueId::QEBA::AEAAXXZ鈥�::[2] |
| 0x14047D780 | CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[13] func_names 名 CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[13] |
| 0x142222390 | ctype<unsigned short,std>::[8] func_names 名 ctype<unsigned short,std>::[8] |
| 0x1422223F0 | ctype<unsigned short,std>::[10] func_names 名 ctype<unsigned short,std>::[10] |
| 0x14224F860 | CSession::[4] vtable 槽 CSession::[4]（func_names RTTI 名） |
| 0x142354FC0 | CCorneredTileSprite::[19] vtable 槽 CCorneredTileSprite::[19]（func_names RTTI 名） |
| 0x140129950 | ctype<char,std>::[1] func_names 名 ctype<char,std>::[1] |
| 0x141573BC4 | CMapModesInterface::[1] vtable 槽 CMapModesInterface::[1]（func_names RTTI 名） |
| 0x140120200 | CPdxHybridInlineBufferAllocator<H::D$0EAA>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::D$0EAA>::[0] |
| 0x140129E90 | ctype<char,std>::[4] func_names 名 ctype<char,std>::[4] |
| 0x140129EF0 | ctype<char,std>::[6] func_names 名 ctype<char,std>::[6] |
| 0x14015C7A0 | CPdxHybridInlineBufferAllocator<H::$0O::SYmlRow>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0O::SYmlRow>::[0] |
| 0x14015C7D0 | CPdxHybridInlineBufferAllocator<H::H$0IA>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0IA>::[0] |
| 0x14015C800 | CPdxHybridInlineBufferAllocator<H::$0BAA::CPixel>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CPixel>::[0] |
| 0x14015C830 | $07H::CPdxHybridInlineBufferAllocator<unsigned long long>::[0] func_names 名 $07H::CPdxHybridInlineBufferAllocator<unsigned long long>::[0] |
| 0x14015C860 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14015C890 | CPdxHybridInlineBufferAllocator<H::$0BJ::CIntelSource>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BJ::CIntelSource>::[0] |
| 0x14015C8C0 | CPdxHybridInlineBufferAllocator<H::$0GE::EBVCCountry*>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0GE::EBVCCountry*>::[0] |
| 0x14015C8F0 | CPdxHybridInlineBufferAllocator<H::H$0EA>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0EA>::[0] |
| 0x14015C920 | CPdxHybridInlineBufferAllocator<$00H::CProgressSection>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$00H::CProgressSection>::[0] |
| 0x14015C950 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14015C980 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14015C9B0 | CPdxHybridInlineBufferAllocator<$03H::CScopedVariable>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$03H::CScopedVariable>::[0] |
| 0x14015C9E0 | CPdxHybridInlineBufferAllocator<$05H::CGameRuleOption>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$05H::CGameRuleOption>::[0] |
| 0x14015CA10 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x1401FFAC0 | CPdxHybridInlineBufferAllocator<H::H$0GE>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0GE>::[0] |
| 0x1402CCD80 | CPdxHybridInlineBufferAllocator<$08H::CPositionOverride>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$08H::CPositionOverride>::[0] |
| 0x140330250 | CPdxHybridInlineBufferAllocator<H::H$0CA>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0CA>::[0] |
| 0x1404B3620 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14066E2B0 | CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0FF::SEdge>::[0] |
| 0x1406833D0 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14068F260 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x1406CEAE0 | CPdxHybridInlineBufferAllocator<$04H::SWarBlobT<$0A>>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$04H::SWarBlobT<$0A>>::[0] |
| 0x1406CEB10 | CPdxHybridInlineBufferAllocator<H::$0BA::SNavalBaseRepairData>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BA::SNavalBaseRepairData>::[0] |
| 0x140A02E60 | CPdxHybridInlineBufferAllocator<H::$0EA::SPoolMatch>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0EA::SPoolMatch>::[0] |
| 0x140A02E90 | CPdxHybridInlineBufferAllocator<$02H::CEquipmentGraphicPool>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$02H::CEquipmentGraphicPool>::[0] |
| 0x140A8C430 | CPdxHybridInlineBufferAllocator<$00H::CPowerBalanceRange>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$00H::CPowerBalanceRange>::[0] |
| 0x140A8C460 | CPdxHybridInlineBufferAllocator<$02H::CPowerBalanceSide>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$02H::CPowerBalanceSide>::[0] |
| 0x140AE4B00 | CPdxHybridInlineBufferAllocator<$09H::CString>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$09H::CString>::[0] |
| 0x140B01740 | CPdxHybridInlineBufferAllocator<H::$0CK::STraitChance>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CK::STraitChance>::[0] |
| 0x140BEA8B0 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x140BEA8E0 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x140CD8FC0 | CPdxHybridInlineBufferAllocator<H::H$0BO>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0BO>::[0] |
| 0x140D89460 | CPdxHybridInlineBufferAllocator<SWarBlobT<H::$0BA::$00>>::[0] func_names 名 CPdxHybridInlineBufferAllocator<SWarBlobT<H::$0BA::$00>>::[0] |
| 0x140DC5160 | CPdxHybridInlineBufferAllocator<H::$0GE::SControlGroupData>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0GE::SControlGroupData>::[0] |
| 0x140DC5190 | CPdxHybridInlineBufferAllocator<H::$0N::CString>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0N::CString>::[0] |
| 0x140DFD4F0 | CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[0] |
| 0x140EC46E0 | CPdxHybridInlineBufferAllocator<$03H::SSupplyNodeData>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$03H::SSupplyNodeData>::[0] |
| 0x140EEB560 | $04H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 $04H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x140F31420 | CPdxStaticInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[0] |
| 0x141182720 | CPdxHybridInlineBufferAllocator<H::H$0BC>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0BC>::[0] |
| 0x1411F2A60 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14121AF20 | $07H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 $07H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14121AF50 | CPdxHybridInlineBufferAllocator<H::$0BA::SNodeConnection>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BA::SNodeConnection>::[0] |
| 0x141266090 | CPdxHybridInlineBufferAllocator<H::$0CAA::SMapArrowVertex>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CAA::SMapArrowVertex>::[0] |
| 0x14128B2C0 | CPdxHybridInlineBufferAllocator<$03H::SEntityInstanceTextureSet>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$03H::SEntityInstanceTextureSet>::[0] |
| 0x14131A680 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x1413D47E0 | CPdxStaticInlineBufferAllocator<$02H::CString>::[0] func_names 名 CPdxStaticInlineBufferAllocator<$02H::CString>::[0] |
| 0x1414E0430 | CPdxHybridInlineBufferAllocator<CPdxArray<H::$0BA::HH>>::[0] func_names 名 CPdxHybridInlineBufferAllocator<CPdxArray<H::$0BA::HH>>::[0] |
| 0x141532DC0 | $07H::CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 $07H::CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x1415A0010 | CPdxHybridInlineBufferAllocator<$06H::SGfxVariable>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$06H::SGfxVariable>::[0] |
| 0x1415AF630 | CPdxHybridInlineBufferAllocator<H::$0BI::EBVCArmy*>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BI::EBVCArmy*>::[0] |
| 0x1415AF660 | CPdxHybridInlineBufferAllocator<H::$0CA::SSearchNode>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::SSearchNode>::[0] |
| 0x141600730 | CPdxHybridInlineBufferAllocator<H::$0M::CDiploChance>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::$0M::CDiploChance>::[0] |
| 0x1416D9CC0 | CPdxStaticInlineBufferAllocator<$04H::SProximityLoc>::[0] func_names 名 CPdxStaticInlineBufferAllocator<$04H::SProximityLoc>::[0] |
| 0x14190CA00 | $01H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 $01H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x14192A960 | CPdxStaticInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxStaticInlineBufferAllocator<鈥�>::[0] |
| 0x141B7D5A0 | CPdxHybridInlineBufferAllocator<$03H::CWeatherChancePeriod>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$03H::CWeatherChancePeriod>::[0] |
| 0x141CEAA60 | CPdxHybridInlineBufferAllocator<CVector<H::$0BAA::M$02>>::[0] func_names 名 CPdxHybridInlineBufferAllocator<CVector<H::$0BAA::M$02>>::[0] |
| 0x141FE4B5C | CStatTooltipHandler<鈥�>::[1] func_names 名 CStatTooltipHandler<鈥�>::[1] |
| 0x142092E00 | CPdxHybridInlineBufferAllocator<$00H::SSubsystemReader>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$00H::SSubsystemReader>::[0] |
| 0x14222BC90 | CPdxHybridInlineBufferAllocator<CMatrix<$03H::M$03$03>>::[0] func_names 名 CPdxHybridInlineBufferAllocator<CMatrix<$03H::M$03$03>>::[0] |
| 0x142282A70 | CPdxHybridInlineBufferAllocator<$00H::CEntityEvent>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$00H::CEntityEvent>::[0] |
| 0x142309B40 | CPdxHybridInlineBufferAllocator<$02H::SPdxAssetMesh>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$02H::SPdxAssetMesh>::[0] |
| 0x14234D020 | CPdxHybridInlineBufferAllocator<$02H::SEntityAttachmentDesc>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$02H::SEntityAttachmentDesc>::[0] |
| 0x14234D050 | CPdxHybridInlineBufferAllocator<$01H::SEntityAttachmentReader>::[0] func_names 名 CPdxHybridInlineBufferAllocator<$01H::SEntityAttachmentReader>::[0] |
| 0x1423A55A0 | CPdxHybridInlineBufferAllocator<鈥�>::[0] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[0] |
| 0x1423E7550 | CPdxHybridInlineBufferAllocator<H::E$0CAAA>::[0] func_names 名 CPdxHybridInlineBufferAllocator<H::E$0CAAA>::[0] |
| 0x14151A1C0 | CPeaceAction::GetActionLabel func_names 名 CPeaceAction::GetActionLabel |
| 0x14237C150 | CScrollbarType::[0] vtable 槽 CScrollbarType::[0]（func_names RTTI 名） |
| 0x1413FFDF0 | COperationInstance::[0] vtable 槽 COperationInstance::[0]（func_names RTTI 名） |
| 0x1416D9CAC | CBattlePlansTools::[1] vtable 槽 CBattlePlansTools::[1]（func_names RTTI 名） |
| 0x141B7D588 | CWeatherNudger::[0] vtable 槽 CWeatherNudger::[0]（func_names RTTI 名） |
| 0x141A00F20 | （无名） 体设 CStateListener::vftable（RTTI 名） |
| 0x140B3FFD0 | CGameGraphics::[0] vtable 槽 CGameGraphics::[0]（func_names RTTI 名） |
| 0x140F6F430 | CNavalProductionLine::[11] vtable 槽 CNavalProductionLine::[11]（func_names RTTI 名） |
| 0x1422FE480 | CSprite::[0] vtable 槽 CSprite::[0]（func_names RTTI 名） |
| 0x142355D20 | CPdxSystem::[8] vtable 槽 CPdxSystem::[8]（func_names RTTI 名） |
| 0x140620230 | CAchievement::[12] vtable 槽 CAchievement::[12]（func_names RTTI 名） |
| 0x1401C5490 | 7d6384c0f2a3ae6bfeb60f8cebe04338::.??::[0] func_names 名 7d6384c0f2a3ae6bfeb60f8cebe04338::.??::[0] |
| 0x1401C5E00 | 6121b5708fe62f23bbee403519dbcacc::.??::[0] func_names 名 6121b5708fe62f23bbee403519dbcacc::.??::[0] |
| 0x1409CBCA0 | ULexerToken::UEAAXAEAVCReader::NDLC::CMetadata::?8??ReadMember:鈥�::[2] func_names 名 ULexerToken::UEAAXAEAVCReader::NDLC::CMetadata::?8??ReadMember:鈥�::[2] |
| 0x140A21670 | USReadProgressSections::?$ReadCustomUniformSimpleStatement::SCu鈥�::[2] func_names 名 USReadProgressSections::?$ReadCustomUniformSimpleStatement::SCu鈥�::[2] |
| 0x140C0E9EC | CNavyLeader::[2] vtable 槽 CNavyLeader::[2]（func_names RTTI 名） |
| 0x141289970 | CPostEffectVolumeReloader::Reload func_names 名 CPostEffectVolumeReloader::Reload |
| 0x141EFAE20 | X$$QEAUSDownloadProfileResult::Z::7::$$A6AXXZ::V?$function::std鈥�::[2] func_names 名 X$$QEAUSDownloadProfileResult::Z::7::$$A6AXXZ::V?$function::std鈥�::[2] |
| 0x14064CD58 | CStrategicAI::[0] vtable 槽 CStrategicAI::[0]（func_names RTTI 名） |
| 0x140D64468 | CTaskForce::[2] vtable 槽 CTaskForce::[2]（func_names RTTI 名） |
| 0x1422FC2F0 | C2dPieChartTemplate<SPieVertex>::[0] func_names 名 C2dPieChartTemplate<SPieVertex>::[0] |
| 0x1422FC2FC | C2dPieChartTemplate<STexturedPieVertex>::[0] func_names 名 C2dPieChartTemplate<STexturedPieVertex>::[0] |
| 0x142379124 | CNullButtonStandard::[0] vtable 槽 CNullButtonStandard::[0]（func_names RTTI 名） |
| 0x14047E9F0 | CVariableTriggerBuilder<鈥�>::[13] func_names 名 CVariableTriggerBuilder<鈥�>::[13] |
| 0x140A40850 | CIdea::[0] vtable 槽 CIdea::[0]（func_names RTTI 名） |
| 0x140CA6028 | CCountryResources::[0] vtable 槽 CCountryResources::[0]（func_names RTTI 名） |
| 0x141509C64 | CGarrisonStatus::[0] vtable 槽 CGarrisonStatus::[0]（func_names RTTI 名） |
| 0x1415BB2A4 | CConfirmRemoveAllRegions::[0] vtable 槽 CConfirmRemoveAllRegions::[0]（func_names RTTI 名） |
| 0x1415CE054 | CTacticsListView<CTacticsListEntry>::[1] func_names 名 CTacticsListView<CTacticsListEntry>::[1] |
| 0x1415CE060 | CTacticsListView<CTacticsListEntry>::[0] func_names 名 CTacticsListView<CTacticsListEntry>::[0] |
| 0x1416D2464 | CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[1] func_names 名 CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[1] |
| 0x1416D2470 | CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[0] func_names 名 CTacticsListView<CSelectArmyLeaderPreferredTacticsEntry>::[0] |
| 0x1416F7DE8 | CTacticsListView<CSelectCountryPreferredTacticsEntry>::[1] func_names 名 CTacticsListView<CSelectCountryPreferredTacticsEntry>::[1] |
| 0x1416F7DF4 | CTacticsListView<CSelectCountryPreferredTacticsEntry>::[0] func_names 名 CTacticsListView<CSelectCountryPreferredTacticsEntry>::[0] |
| 0x1417B04B0 | CInGameClock::IsVisible func_names 名 CInGameClock::IsVisible |
| 0x14186CB24 | CPlayerLobby::[0] vtable 槽 CPlayerLobby::[0]（func_names RTTI 名） |
| 0x14188A454 | CTheatreSelector::[1] vtable 槽 CTheatreSelector::[1]（func_names RTTI 名） |
| 0x141A2DBB0 | CConfirmDeleteOrder::[1] vtable 槽 CConfirmDeleteOrder::[1]（func_names RTTI 名） |
| 0x141B51DB4 | CDBNudger::[0] vtable 槽 CDBNudger::[0]（func_names RTTI 名） |
| 0x141BB73F8 | CDarkFullscreenOverlayUpdateable::Refresh func_names 名 CDarkFullscreenOverlayUpdateable::Refresh |
| 0x141BE34E4 | CConfirmResearchTechnology::IsVisible func_names 名 CConfirmResearchTechnology::IsVisible |
| 0x141BE34F0 | CConfirmResearchTechnology::[1] vtable 槽 CConfirmResearchTechnology::[1]（func_names RTTI 名） |
| 0x141C2F168 | CImportDesignPopUp::[0] vtable 槽 CImportDesignPopUp::[0]（func_names RTTI 名） |
| 0x141C2F1C8 | CDeleteOrRenameFolderPopUp::[0] vtable 槽 CDeleteOrRenameFolderPopUp::[0]（func_names RTTI 名） |
| 0x141CFDD70 | CConfirmDeleteOrdersGroup::[1] vtable 槽 CConfirmDeleteOrdersGroup::[1]（func_names RTTI 名） |
| 0x141D0805C | CConfirmConsolidateUnits::[1] vtable 槽 CConfirmConsolidateUnits::[1]（func_names RTTI 名） |
| 0x141D10D7C | CHistoryEntryItemBase::[1] vtable 槽 CHistoryEntryItemBase::[1]（func_names RTTI 名） |
| 0x141D42EF4 | CShipsOverview::[1] vtable 槽 CShipsOverview::[1]（func_names RTTI 名） |
| 0x141DE9F40 | CConfirmSaveGame::IsVisible func_names 名 CConfirmSaveGame::IsVisible |
| 0x141EA5A2C | CIntelLedgerAirPanelController::[1] vtable 槽 CIntelLedgerAirPanelController::[1]（func_names RTTI 名） |
| 0x141F68110 | CTraitAssignmentConfirmation::[1] vtable 槽 CTraitAssignmentConfirmation::[1]（func_names RTTI 名） |
| 0x141F7CE34 | CConfirmDisbandFleet::[1] vtable 槽 CConfirmDisbandFleet::[1]（func_names RTTI 名） |
| 0x14203CAC0 | CListItem<鈥�>::[1] func_names 名 CListItem<鈥�>::[1] |
| 0x142058E18 | CListItem<鈥�>::[1] func_names 名 CListItem<鈥�>::[1] |
| 0x14206900C | CListItem<鈥�>::[1] func_names 名 CListItem<鈥�>::[1] |
| 0x142069018 | CListItem<鈥�>::[0] func_names 名 CListItem<鈥�>::[0] |
| 0x142089650 | CTweakableIntManipulator::[0] vtable 槽 CTweakableIntManipulator::[0]（func_names RTTI 名） |
| 0x1422304A8 | CKeyBoard::[0] vtable 槽 CKeyBoard::[0]（func_names RTTI 名） |
| 0x140B42D9C | CGameGui::[0] vtable 槽 CGameGui::[0]（func_names RTTI 名） |
| 0x141285B34 | CPdxPostEffectVolumeManager::[0] vtable 槽 CPdxPostEffectVolumeManager::[0]（func_names RTTI 名） |
| 0x14151A480 | CTakeNavyPeaceAction::GetActionLabel func_names 名 CTakeNavyPeaceAction::GetActionLabel |
| 0x14151E6F0 | CStatePeaceAction::GetStackedWithDescription func_names 名 CStatePeaceAction::GetStackedWithDescription |
| 0x142233340 | （无名） 体设 CSystem::vftable（RTTI 名） |
| 0x1422A9858 | CFixedMaxSizeListbox<CStandardlistboxItem>::[7] func_names 名 CFixedMaxSizeListbox<CStandardlistboxItem>::[7] |
| 0x1422A9870 | CSimpleListbox<CStandardlistboxItem>::[7] func_names 名 CSimpleListbox<CStandardlistboxItem>::[7] |
| 0x1416422E0 | CSpriteType::[28] vtable 槽 CSpriteType::[28]（func_names RTTI 名） |
| 0x142360510 | CProgressbarSpriteType::[18] vtable 槽 CProgressbarSpriteType::[18]（func_names RTTI 名） |
| 0x142384800 | CPdxMouse::[16] vtable 槽 CPdxMouse::[16]（func_names RTTI 名） |
| 0x142384850 | CPdxMouse::[29] vtable 槽 CPdxMouse::[29]（func_names RTTI 名） |
| 0x1423C2990 | CSteamBrowserInstance::[14] vtable 槽 CSteamBrowserInstance::[14]（func_names RTTI 名） |
| 0x1423C29A0 | CSteamBrowserInstance::[16] vtable 槽 CSteamBrowserInstance::[16]（func_names RTTI 名） |
| 0x1401AD690 | numpunct<char,std>::[4] func_names 名 numpunct<char,std>::[4] |
| 0x140DB9950 | CUnlockIndustrialOrganisationTrait::GetTypeId func_names 名 CUnlockIndustrialOrganisationTrait::GetTypeId |
| 0x140DE9D50 | CAutosave::GetTypeId func_names 名 CAutosave::GetTypeId |
| 0x140DE9D90 | CPauseGame::GetTypeId func_names 名 CPauseGame::GetTypeId |
| 0x140DE9E00 | CSetGameUniqueId::GetTypeId func_names 名 CSetGameUniqueId::GetTypeId |
| 0x140DE9E10 | CSetRandomSeed::GetTypeId func_names 名 CSetRandomSeed::GetTypeId |
| 0x140E8F300 | CAssignRailwayGunToOrdersGroup::GetTypeId func_names 名 CAssignRailwayGunToOrdersGroup::GetTypeId |
| 0x140E8F330 | CUnassignRailwayGunFromOrdersGroup::GetTypeId func_names 名 CUnassignRailwayGunFromOrdersGroup::GetTypeId |
| 0x141160850 | CAddProductionLineName::GetTypeId func_names 名 CAddProductionLineName::GetTypeId |
| 0x141160860 | CAddProductionLineOrderedName::GetTypeId func_names 名 CAddProductionLineOrderedName::GetTypeId |
| 0x141160870 | CAddProductionLineUnorderedName::GetTypeId func_names 名 CAddProductionLineUnorderedName::GetTypeId |
| 0x141160AD0 | CRemoveProductionLineName::GetTypeId func_names 名 CRemoveProductionLineName::GetTypeId |
| 0x1412B6BF0 | CLandCombat::[10] vtable 槽 CLandCombat::[10]（func_names RTTI 名） |
| 0x141357170 | CAddToOrRemoveShipFromNavalRepairQueue::GetTypeId func_names 名 CAddToOrRemoveShipFromNavalRepairQueue::GetTypeId |
| 0x141357300 | CReorderNavalRepairQueue::GetTypeId func_names 名 CReorderNavalRepairQueue::GetTypeId |
| 0x141357320 | CRestructureShipsToTaskforceCompositions::GetTypeId func_names 名 CRestructureShipsToTaskforceCompositions::GetTypeId |
| 0x141357340 | CSetCarrierDefensiveStance::GetTypeId func_names 名 CSetCarrierDefensiveStance::GetTypeId |
| 0x141357390 | CSetMaxAllowedRepairDockyards::GetTypeId func_names 名 CSetMaxAllowedRepairDockyards::GetTypeId |
| 0x141357410 | CSwitchNavalRepairDockyard::GetTypeId func_names 名 CSwitchNavalRepairDockyard::GetTypeId |
| 0x141368420 | CSetArmyToConsolidateForUnit::GetTypeId func_names 名 CSetArmyToConsolidateForUnit::GetTypeId |
| 0x141540120 | CCountryHistory::[13] vtable 槽 CCountryHistory::[13]（func_names RTTI 名） |
| 0x1415A14B0 | COwnerChange::[13] vtable 槽 COwnerChange::[13]（func_names RTTI 名） |
| 0x14163DD10 | CSetAchievementsOK::GetTypeId func_names 名 CSetAchievementsOK::GetTypeId |
| 0x14163DD20 | CSetCoopHotJoinOptions::GetTypeId func_names 名 CSetCoopHotJoinOptions::GetTypeId |
| 0x14163DD30 | CSetCustomDifficultyMultiplier::GetTypeId func_names 名 CSetCustomDifficultyMultiplier::GetTypeId |
| 0x14163DD40 | CSetDifficulty::GetTypeId func_names 名 CSetDifficulty::GetTypeId |
| 0x14163DD50 | CSetGamePlayOptions::GetTypeId func_names 名 CSetGamePlayOptions::GetTypeId |
| 0x14163DD60 | CSetGameRuleOption::GetTypeId func_names 名 CSetGameRuleOption::GetTypeId |
| 0x14163DD70 | CSetMPDebugSettings::GetTypeId func_names 名 CSetMPDebugSettings::GetTypeId |
| 0x14163DD80 | CSetReadyStatus::GetTypeId func_names 名 CSetReadyStatus::GetTypeId |
| 0x14184C9F0 | CAssignAdmiralToNavyHeadquarter::GetTypeId func_names 名 CAssignAdmiralToNavyHeadquarter::GetTypeId |
| 0x14184CA00 | CAssignArmyToArmyGroupFront::GetTypeId func_names 名 CAssignArmyToArmyGroupFront::GetTypeId |
| 0x14184CAF0 | COrderDeleteChildFront::GetTypeId func_names 名 COrderDeleteChildFront::GetTypeId |
| 0x14184CBB0 | COrderRemoveRootCommands::GetTypeId func_names 名 COrderRemoveRootCommands::GetTypeId |
| 0x14184CBD0 | COrderReplaceFallbackCommands::GetTypeId func_names 名 COrderReplaceFallbackCommands::GetTypeId |
| 0x14184CBE0 | COrderReplaceRootCommands::GetTypeId func_names 名 COrderReplaceRootCommands::GetTypeId |
| 0x14184CC70 | CRemoveAdmiralFromNavyHeadquarter::GetTypeId func_names 名 CRemoveAdmiralFromNavyHeadquarter::GetTypeId |
| 0x14184CD50 | CSetSelectedArmyGroupFallback::GetTypeId func_names 名 CSetSelectedArmyGroupFallback::GetTypeId |
| 0x141A28E20 | CActivateActiveDecryptionBonuses::GetTypeId func_names 名 CActivateActiveDecryptionBonuses::GetTypeId |
| 0x141F52900 | CResetCustomDifficultyMultipliers::GetTypeId func_names 名 CResetCustomDifficultyMultipliers::GetTypeId |
| 0x141F52910 | CResetGameRules::GetTypeId func_names 名 CResetGameRules::GetTypeId |
| 0x14047D730 | CVariableEffectBuilder<鈥�>::[13] func_names 名 CVariableEffectBuilder<鈥�>::[13] |
| 0x14047D740 | CVariableEffectBuilder<鈥�>::[13] func_names 名 CVariableEffectBuilder<鈥�>::[13] |
| 0x1422FD100 | C2dPieChartTemplate<SPieVertex>::[54] func_names 名 C2dPieChartTemplate<SPieVertex>::[54] |
| 0x142308520 | CLineChart::[54] vtable 槽 CLineChart::[54]（func_names RTTI 名） |
| 0x141642A70 | CShieldObject::[75] vtable 槽 CShieldObject::[75]（func_names RTTI 名） |
| 0x141642AA0 | CSprite::[14] vtable 槽 CSprite::[14]（func_names RTTI 名） |
| 0x1422403E0 | CSpriteType::[15] vtable 槽 CSpriteType::[15]（func_names RTTI 名） |
| 0x1422E1200 | CChunkReceived::GetTypeId func_names 名 CChunkReceived::GetTypeId |
| 0x1422E1210 | CSendChunk::GetTypeId func_names 名 CSendChunk::GetTypeId |
| 0x1422E1220 | CStartFileTransfer::GetTypeId func_names 名 CStartFileTransfer::GetTypeId |
| 0x1422E8620 | CChatBuffer::CSendChatMessage::GetTypeId func_names 名 CChatBuffer::CSendChatMessage::GetTypeId |
| 0x1422E8630 | CChatBuffer::CWriteToChatBuffer::GetTypeId func_names 名 CChatBuffer::CWriteToChatBuffer::GetTypeId |
| 0x142354BE0 | CCorneredTileSprite::[22] vtable 槽 CCorneredTileSprite::[22]（func_names RTTI 名） |
| 0x14235F4E0 | CProgressbarSprite::[22] vtable 槽 CProgressbarSprite::[22]（func_names RTTI 名） |
| 0x1423E8A90 | CSteamNetContext::[15] vtable 槽 CSteamNetContext::[15]（func_names RTTI 名） |
| 0x140676230 | CSteamStoreContext::[12] vtable 槽 CSteamStoreContext::[12]（func_names RTTI 名） |
| 0x140F0ECF0 | CPdxTouchDevice::[1] vtable 槽 CPdxTouchDevice::[1]（func_names RTTI 名） |
| 0x142402480 | CSteamStoreContext::[13] vtable 槽 CSteamStoreContext::[13]（func_names RTTI 名） |
| 0x140DC5BF0 | CInGameIdler::[97] vtable 槽 CInGameIdler::[97]（func_names RTTI 名） |
| 0x1422D4E30 | CTextSprite::[16] vtable 槽 CTextSprite::[16]（func_names RTTI 名） |
| 0x14047C170 | CVariableTriggerBuilder<鈥�>::[22] func_names 名 CVariableTriggerBuilder<鈥�>::[22] |
| 0x14047C190 | CVariableTriggerBuilder<鈥�>::[22] func_names 名 CVariableTriggerBuilder<鈥�>::[22] |
| 0x14047C1B0 | CVariableTriggerBuilder<鈥�>::[22] func_names 名 CVariableTriggerBuilder<鈥�>::[22] |
| 0x14047C1D0 | CVariableTriggerBuilder<CModuloVariable<CTempVariableResolver>>::[22] func_names 名 CVariableTriggerBuilder<CModuloVariable<CTempVariableResolver>>::[22] |
| 0x14047C1F0 | CVariableTriggerBuilder<鈥�>::[22] func_names 名 CVariableTriggerBuilder<鈥�>::[22] |
| 0x14153E690 | CFriendsHandlerSteam::[9] vtable 槽 CFriendsHandlerSteam::[9]（func_names RTTI 名） |
| 0x14153E770 | CFriendsHandlerSteam::[8] vtable 槽 CFriendsHandlerSteam::[8]（func_names RTTI 名） |
| 0x142242AD0 | CSpriteType::[24] vtable 槽 CSpriteType::[24]（func_names RTTI 名） |
| 0x1422D71A0 | CTextSprite::[83] vtable 槽 CTextSprite::[83]（func_names RTTI 名） |
| 0x142301280 | CSmoothListbox::[28] vtable 槽 CSmoothListbox::[28]（func_names RTTI 名） |
| 0x142384DD0 | CPdxMouse::[31] vtable 槽 CPdxMouse::[31]（func_names RTTI 名） |
| 0x142384E10 | CPdxMouse::[14] vtable 槽 CPdxMouse::[14]（func_names RTTI 名） |
| 0x1423BDF80 | CAudioInstance::[2] vtable 槽 CAudioInstance::[2]（func_names RTTI 名） |
| 0x1412663C0 | CPdxHybridInlineBufferAllocator<H::$0CAA::SMapArrowVertex>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CAA::SMapArrowVertex>::[6] |
| 0x141642CB0 | CSprite::[71] vtable 槽 CSprite::[71]（func_names RTTI 名） |
| 0x141642CD0 | CSprite::[20] vtable 槽 CSprite::[20]（func_names RTTI 名） |
| 0x141DC4030 | COption::[7] vtable 槽 COption::[7]（func_names RTTI 名） |
| 0x140120530 | CPdxHybridInlineBufferAllocator<H::D$0EAA>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::D$0EAA>::[6] |
| 0x140129E60 | ctype<char,std>::[8] func_names 名 ctype<char,std>::[8] |
| 0x1401613C0 | CPdxHybridInlineBufferAllocator<H::$0O::SYmlRow>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0O::SYmlRow>::[6] |
| 0x1401613E0 | CPdxHybridInlineBufferAllocator<H::$0BAA::CPixel>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BAA::CPixel>::[6] |
| 0x140161410 | CPdxHybridInlineBufferAllocator<H::$0BJ::CIntelSource>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BJ::CIntelSource>::[6] |
| 0x140161440 | CPdxHybridInlineBufferAllocator<$00H::CProgressSection>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$00H::CProgressSection>::[6] |
| 0x14047D710 | CVariableEffectBuilder<鈥�>::[13] func_names 名 CVariableEffectBuilder<鈥�>::[13] |
| 0x14047D720 | CVariableEffectBuilder<鈥�>::[13] func_names 名 CVariableEffectBuilder<鈥�>::[13] |
| 0x14047D750 | CVariableEffectBuilder<鈥�>::[13] func_names 名 CVariableEffectBuilder<鈥�>::[13] |
| 0x14047D760 | CVariableEffectBuilder<CGetSupplyVehicles<CVariableResolver>>::[13] func_names 名 CVariableEffectBuilder<CGetSupplyVehicles<CVariableResolver>>::[13] |
| 0x14047D770 | CVariableEffectBuilder<CModuloVariable<CTempVariableResolver>>::[13] func_names 名 CVariableEffectBuilder<CModuloVariable<CTempVariableResolver>>::[13] |
| 0x14047D790 | CVariableEffectBuilder<CSetToRandomValue<CTempVariableResolver>>::[13] func_names 名 CVariableEffectBuilder<CSetToRandomValue<CTempVariableResolver>>::[13] |
| 0x14047D7A0 | CVariableEffectBuilder<CSetToRandomValue<CVariableResolver>>::[13] func_names 名 CVariableEffectBuilder<CSetToRandomValue<CVariableResolver>>::[13] |
| 0x14047E9E0 | CVariableTriggerBuilder<鈥�>::[13] func_names 名 CVariableTriggerBuilder<鈥�>::[13] |
| 0x14047EA00 | CVariableTriggerBuilder<鈥�>::[13] func_names 名 CVariableTriggerBuilder<鈥�>::[13] |
| 0x140482D50 | CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[4] func_names 名 CVariableEffectBuilder<CModuloVariable<CVariableResolver>>::[4] |
| 0x14068F860 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x140A02ED0 | CPdxHybridInlineBufferAllocator<H::$0EA::SPoolMatch>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0EA::SPoolMatch>::[6] |
| 0x140A8C660 | CPdxHybridInlineBufferAllocator<$00H::CPowerBalanceRange>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$00H::CPowerBalanceRange>::[6] |
| 0x140D89640 | CPdxHybridInlineBufferAllocator<SWarBlobT<H::$0BA::$00>>::[6] func_names 名 CPdxHybridInlineBufferAllocator<SWarBlobT<H::$0BA::$00>>::[6] |
| 0x140DC5600 | CPdxHybridInlineBufferAllocator<H::$0GE::SControlGroupData>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0GE::SControlGroupData>::[6] |
| 0x140DFD530 | CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[6] |
| 0x140E139A0 | CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[3] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CColor>::[3] |
| 0x14121B070 | CPdxHybridInlineBufferAllocator<H::$0BA::SNodeConnection>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BA::SNodeConnection>::[6] |
| 0x14187B070 | CPdxHybridInlineBufferAllocator<$08H::SParticle>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$08H::SParticle>::[6] |
| 0x141CEAA90 | CPdxHybridInlineBufferAllocator<CVector<H::$0BAA::M$02>>::[6] func_names 名 CPdxHybridInlineBufferAllocator<CVector<H::$0BAA::M$02>>::[6] |
| 0x142092F30 | CPdxHybridInlineBufferAllocator<$00H::SSubsystemReader>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$00H::SSubsystemReader>::[6] |
| 0x1420A6DF0 | CPdxHybridInlineBufferAllocator<H::$0BA::SParticleRenderData>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0BA::SParticleRenderData>::[6] |
| 0x142282AA0 | CPdxHybridInlineBufferAllocator<$00H::CEntityEvent>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$00H::CEntityEvent>::[6] |
| 0x1423A55D0 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x1423E7600 | CPdxHybridInlineBufferAllocator<H::E$0CAAA>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::E$0CAAA>::[6] |
| 0x1401246B0 | CPdxHybridInlineBufferAllocator<H$09H>::[3] func_names 名 CPdxHybridInlineBufferAllocator<H$09H>::[3] |
| 0x140161400 | CSteamCloudFile::[14] vtable 槽 CSteamCloudFile::[14]（func_names RTTI 名） |
| 0x140161420 | CPdxHybridInlineBufferAllocator<H::$0GE::EBVCCountry*>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0GE::EBVCCountry*>::[6] |
| 0x140161430 | CPdxHybridInlineBufferAllocator<H::H$0EA>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0EA>::[6] |
| 0x140161450 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x140161460 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x140161470 | CPdxHybridInlineBufferAllocator<$03H::CScopedVariable>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$03H::CScopedVariable>::[6] |
| 0x140161480 | CPdxHybridInlineBufferAllocator<$05H::CGameRuleOption>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$05H::CGameRuleOption>::[6] |
| 0x140161490 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x1401C9C20 | CPdxHybridInlineBufferAllocator<$04H::CString>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$04H::CString>::[6] |
| 0x1401FFB00 | CPdxHybridInlineBufferAllocator<H::H$0GE>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0GE>::[6] |
| 0x1402CD580 | CPdxHybridInlineBufferAllocator<$08H::CPositionOverride>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$08H::CPositionOverride>::[6] |
| 0x1404B3710 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x140683860 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x1406CF6B0 | CPdxHybridInlineBufferAllocator<$04H::SWarBlobT<$0A>>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$04H::SWarBlobT<$0A>>::[6] |
| 0x140A8C670 | CPdxHybridInlineBufferAllocator<$02H::CPowerBalanceSide>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$02H::CPowerBalanceSide>::[6] |
| 0x140AD9EC0 | CPdxHybridInlineBufferAllocator<H::H$0BO>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::H$0BO>::[6] |
| 0x140ADA310 | CPdxHybridInlineBufferAllocator<H::$0M::EAVCArmy*>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0M::EAVCArmy*>::[6] |
| 0x140AE4CF0 | CPdxHybridInlineBufferAllocator<$09H::CString>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$09H::CString>::[6] |
| 0x140B64550 | CPdxHybridInlineBufferAllocator<$01H::SEntityAttachmentReader>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$01H::SEntityAttachmentReader>::[6] |
| 0x140BEAA20 | CPdxHybridInlineBufferAllocator<CPdxArray<H::$0BA::HH>>::[6] func_names 名 CPdxHybridInlineBufferAllocator<CPdxArray<H::$0BA::HH>>::[6] |
| 0x140BFEF80 | CPdxHybridInlineBufferAllocator<$02H::SPdxAssetMesh>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$02H::SPdxAssetMesh>::[6] |
| 0x140EC48F0 | CPdxHybridInlineBufferAllocator<$03H::SSupplyNodeData>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$03H::SSupplyNodeData>::[6] |
| 0x140EEB6C0 | $04H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 $04H::Z::CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x140FC6420 | XAEBUSIntelNetworkNodeDesc::Z::Z::01::SA?AV3::COperativeMission鈥�::[2] func_names 名 XAEBUSIntelNetworkNodeDesc::Z::Z::01::SA?AV3::COperativeMission鈥�::[2] |
| 0x14131A750 | CPdxHybridInlineBufferAllocator<鈥�>::[6] func_names 名 CPdxHybridInlineBufferAllocator<鈥�>::[6] |
| 0x1415A0200 | CPdxHybridInlineBufferAllocator<$06H::SGfxVariable>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$06H::SGfxVariable>::[6] |
| 0x141600810 | CPdxHybridInlineBufferAllocator<H::$0M::CDiploChance>::[6] func_names 名 CPdxHybridInlineBufferAllocator<H::$0M::CDiploChance>::[6] |
| 0x141B7D790 | CPdxHybridInlineBufferAllocator<$03H::CWeatherChancePeriod>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$03H::CWeatherChancePeriod>::[6] |
| 0x14222BD80 | CPdxHybridInlineBufferAllocator<CMatrix<$03H::M$03$03>>::[6] func_names 名 CPdxHybridInlineBufferAllocator<CMatrix<$03H::M$03$03>>::[6] |
| 0x1423012E0 | CSmoothListbox::[10] vtable 槽 CSmoothListbox::[10]（func_names RTTI 名） |
| 0x14234D270 | CPdxHybridInlineBufferAllocator<$02H::SEntityAttachmentDesc>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$02H::SEntityAttachmentDesc>::[6] |
| 0x140AC02B0 | CPdxHybridInlineBufferAllocator<$09H::EBVCOccupationModifier*>::[6] func_names 名 CPdxHybridInlineBufferAllocator<$09H::EBVCOccupationModifier*>::[6] |
| 0x140F71C60 | CShipRefitProductionLine::[13] vtable 槽 CShipRefitProductionLine::[13]（func_names RTTI 名） |
| 0x1422FE500 | CSprite::[17] vtable 槽 CSprite::[17]（func_names RTTI 名） |
| 0x142542BC0 | charNode::[2] vtable 槽 charNode::[2]（func_names RTTI 名） |
| 0x141939A60 | CNavalProductionLine::[3] vtable 槽 CNavalProductionLine::[3]（func_names RTTI 名） |
| 0x141C8E590 | CDiplomacyStandardController::[4] vtable 槽 CDiplomacyStandardController::[4]（func_names RTTI 名） |
| 0x141127FF0 | CCancelForeignManpowerAction::GetEnableTrigger func_names 名 CCancelForeignManpowerAction::GetEnableTrigger |
| 0x141128190 | CSendVolunteerAction::GetEnableTrigger func_names 名 CSendVolunteerAction::GetEnableTrigger |
| 0x1415A7430 | COperationInstance::[5] vtable 槽 COperationInstance::[5]（func_names RTTI 名） |
| 0x1415C44E0 | CNavalCombat::CreateNewId func_names 名 CNavalCombat::CreateNewId |
| 0x140C187B0 | CNudgeIdler::[20] vtable 槽 CNudgeIdler::[20]（func_names RTTI 名） |
| 0x140BFD3E0 | CUnit::GetName func_names 名 CUnit::GetName |
| 0x141229100 | CNavalBaseConvoyClient::[17] vtable 槽 CNavalBaseConvoyClient::[17]（func_names RTTI 名） |
| 0x14196DBE0 | CLendLeaseExchange::[17] vtable 槽 CLendLeaseExchange::[17]（func_names RTTI 名） |
| 0x14237F450 | CNullGraphicalObject::[85] vtable 槽 CNullGraphicalObject::[85]（func_names RTTI 名） |
| 0x1412D2810 | COption::[3] vtable 槽 COption::[3]（func_names RTTI 名） |
| 0x142231440 | CMouse::[3] vtable 槽 CMouse::[3]（func_names RTTI 名） |
| 0x142231450 | CMouse::[3] vtable 槽 CMouse::[3]（func_names RTTI 名） |
| 0x1422AAB10 | CChoiceObservable<CStandardlistboxItem>::[3] func_names 名 CChoiceObservable<CStandardlistboxItem>::[3] |
| 0x1422E8610 | CChatBuffer::[3] vtable 槽 CChatBuffer::[3]（func_names RTTI 名） |
| 0x1423001C0 | CChoiceObservable<CSmoothListboxItem>::[3] func_names 名 CChoiceObservable<CSmoothListboxItem>::[3] |
| 0x1401776C0 | CProfiledScopeObject::GetName func_names 名 CProfiledScopeObject::GetName |
| 0x142397A30 | CDummyAchievementsContext::[10] vtable 槽 CDummyAchievementsContext::[10]（func_names RTTI 名） |
| 0x1403A1D70 | CExecuteOperationCoordinatedStrike::GetSupportedScopeMask func_names 名 CExecuteOperationCoordinatedStrike::GetSupportedScopeMask |
| 0x14111C4E0 | CRequestLicensedProductionAction::GetAiAcceptance func_names 名 CRequestLicensedProductionAction::GetAiAcceptance |
| 0x14153DB20 | CCallResult<鈥�>::[2] func_names 名 CCallResult<鈥�>::[2] |
| 0x1422E6EA0 | CCountryChatMessage::[9] vtable 槽 CCountryChatMessage::[9]（func_names RTTI 名） |
| 0x1422E6EB0 | CPersonalChatMessage::[9] vtable 槽 CPersonalChatMessage::[9]（func_names RTTI 名） |
| 0x142398F20 | CCallbackImpl<$0JI>::[2] func_names 名 CCallbackImpl<$0JI>::[2] |
| 0x1424BA2B0 | CCallbackImpl<$0BAI>::[2] func_names 名 CCallbackImpl<$0BAI>::[2] |
| 0x1403A1D50 | CAddRegionEfficiency::GetSupportedScopeMask func_names 名 CAddRegionEfficiency::GetSupportedScopeMask |
| 0x141129740 | CSendExpeditionaryForceAction::[43] vtable 槽 CSendExpeditionaryForceAction::[43]（func_names RTTI 名） |
| 0x1423C2C30 | CCallbackImpl<$0CI>::[2] func_names 名 CCallbackImpl<$0CI>::[2] |
| 0x1423C2C40 | CCallbackImpl<$0DI>::[2] func_names 名 CCallbackImpl<$0DI>::[2] |
| 0x14012A120 | CPdxHybridInlineBufferAllocator<H::$0CA::CString>::[9] func_names 名 CPdxHybridInlineBufferAllocator<H::$0CA::CString>::[9] |

#### 4.1.25 CGameState 派发族与门控函数补遗（3549 函）

| VA | 语义/证据 |
|---|---|

#### 4.1.26 CGameState 派发族与门控函数补遗（297 函）

| VA | 语义/证据 |
|---|---|
| 0x14208F710 | （无名） 体设 SSubsystemReader::vftable（RTTI 名） |
| 0x141F94810 | （无名） 体设 CShipEntryDetailed::vftable（RTTI 名） |
| 0x141651A30 | （无名） 体设 CCitySettings::vftable（RTTI 名） |
| 0x14191EBC0 | （无名） 体设 SPotentialDesign::vftable（RTTI 名） |
| 0x141B42660 | （无名） 体设 CNudgerStrategy::vftable（RTTI 名） |
| 0x141AFD1D0 | （无名） 体设 CCharacterPortraits::vftable（RTTI 名） |
| 0x141382C80 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141ED55E0 | （无名） 体设 CNavalLeaderModuleUi::vftable（RTTI 名） |
| 0x140B22040 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141F98E10 | （无名） 体设 SSpriteFramePair::vftable（RTTI 名） |
| 0x1406EE8F0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1418D8110 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140F0ABD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1417E5910 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141B3FCC0 | （无名） 体设 CAmbientObjectType::vftable（RTTI 名） |
| 0x142044E40 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141B5FEF0 | （无名） 体设 CNudgerStrategy::vftable（RTTI 名） |
| 0x140CDBF40 | （无名） 体设 SCombatData::vftable（RTTI 名） |
| 0x1417EF0C0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1415D6FF0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141E69840 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1412D3AD0 | （无名） 体设 CNudgeIdler::vftable（RTTI 名） |
| 0x141601460 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141C403B0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141B70A00 | （无名） 体设 CNudgerStrategy::vftable（RTTI 名） |
| 0x141ADC680 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141992170 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1401665A0 | （无名） 体设 COperationPhase::vftable（RTTI 名） |
| 0x1416F3260 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14204FBF0 | （无名） 体设 CEquipmentVariantPool::vftable（RTTI 名） |
| 0x1401C29A0 | （无名） 体设 CGameState::vftable（RTTI 名） |
| 0x141B6A670 | （无名） 体设 CNudgerStrategy::vftable（RTTI 名） |
| 0x141252E60 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140D96060 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140166FB0 | （无名） 体设 COperationToken::vftable（RTTI 名） |
| 0x140169410 | （无名） 体设 CScientistTrait::vftable（RTTI 名） |
| 0x1402F4650 | BuildTooltip 体设 SScopeLocalizer::vftable（RTTI 名） |
| 0x14118E020 | VCFixedPoint::U?$SDefaultSetSize::NPdx::NImpl::SSparseArrayRead鈥�::[3] func_names 名 VCFixedPoint::U?$SDefaultSetSize::NPdx::NImpl::SSparseArrayRead鈥�::[3] |
| 0x1416CE360 | （无名） 体设 SAdvisorData::vftable（RTTI 名） |
| 0x1412EADC0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141468F20 | （无名） 体设 CFactionArmySection::vftable（RTTI 名） |
| 0x141614520 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141587060 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141E85B80 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1418297A0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x14166C670 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140D1B800 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140F32640 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1403A2210 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141BBD630 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x142020670 | （无名） 体设 CLoadQueuePopUp::vftable（RTTI 名） |
| 0x1402F4FF0 | BuildTooltip 体设 SScopeLocalizer::vftable（RTTI 名） |
| 0x140B232F0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141879B60 | （无名） 体设 CAirViewDetails::vftable（RTTI 名） |
| 0x1422FEA60 | （无名） 体设 CSmoothListbox::vftable（RTTI 名） |
| 0x1420482C0 | （无名） 体设 CEquipmentVariantPool::vftable（RTTI 名） |
| 0x14191C3E0 | （无名） 体设 CEquipmentGroup::vftable（RTTI 名） |
| 0x1402874B0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14039CBF0 | （无名） 体设 CEquipmentStats::vftable（RTTI 名） |
| 0x142085FE0 | （无名） 体设 CTweakableArrayCurveManipulator::vftable（RTTI 名） |
| 0x1406AFDD0 | （无名） 体设 CCareerProfileRibbon::vftable（RTTI 名） |
| 0x141F677A0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141528E70 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1416E92E0 | （无名） 体设 CGroupBtn::vftable（RTTI 名） |
| 0x142005430 | （无名） 体设 CCancelMarketAccessPoup::vftable（RTTI 名） |
| 0x141484FC0 | （无名） 体设 CSavedAchievementMod::vftable（RTTI 名） |
| 0x141F42F10 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1424E5090 | （无名） 体设 Root_node::vftable（RTTI 名） |
| 0x141E7F0C0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1416C8280 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x14036B190 | BuildTooltip 体设 SScopeLocalizer::vftable（RTTI 名） |
| 0x141EB09D0 | （无名） 体设 CIntelLedgerArmyPanelController::vftable（RTTI 名） |
| 0x140B50B20 | （无名） 体设 CGraphicalMap::vftable（RTTI 名） |
| 0x141F21190 | （无名） 体设 CDynamicEquipmentGroup::vftable（RTTI 名） |
| 0x140F041C0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141C10160 | （无名） 体设 CCountryCharacterSelector::vftable（RTTI 名） |
| 0x141F27830 | （无名） 体设 CDiplomaticAction::vftable（RTTI 名） |
| 0x141475540 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141E43180 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14016D700 | （无名） 体设 COperationPhase::vftable（RTTI 名） |
| 0x14127C310 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14146A070 | （无名） 体设 CFactionHeaderSection::vftable（RTTI 名） |
| 0x140234CF0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141E922B0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141DE78E0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140AED2C0 | （无名） 体设 CUnitLeaderSkill::vftable（RTTI 名） |
| 0x1412D1830 | （无名） 体设 CRightClickItemInterface::vftable（RTTI 名） |
| 0x14237E7F0 | （无名） 体设 CTrack::vftable（RTTI 名） |
| 0x141E928D0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141F9AB40 | （无名） 体设 CEquipmentPriorityOption::vftable（RTTI 名） |
| 0x140F7DDD0 | （无名） 体设 STargetPriority::vftable（RTTI 名） |
| 0x141A10600 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x140F4B860 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1403E0940 | GetTooltipText 体设 SScopeLocalizer::vftable（RTTI 名） |
| 0x14016DB50 | （无名） 体设 COperationToken::vftable（RTTI 名） |
| 0x140130DE0 | （无名） 体设 CScriptedEffectTemplate::vftable（RTTI 名） |
| 0x1416408A0 | （无名） 体设 CMapIconGroup::vftable（RTTI 名） |
| 0x14153CFF0 | （无名） 体设 CDownloadProfileRequestSteam::vftable（RTTI 名） |
| 0x1401FD030 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1409FDA00 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x141233270 | （无名） 体设 CTaskForceIdentity::vftable（RTTI 名） |
| 0x141084CB0 | （无名） 体设 CVerySafeAreaCostCallback::vftable（RTTI 名） |
| 0x14061D790 | （无名） 体设 CBaseAchievement::vftable（RTTI 名） |
| 0x14153E980 | （无名） 体设 CFriendsHandlerFriendSteam::vftable（RTTI 名） |
| 0x1414DACD0 | （无名） 体设 SBookmarkPlaythroughData::vftable（RTTI 名） |
| 0x14201D860 | （无名） 体设 CCountryItemBaseGame::vftable（RTTI 名） |
| 0x140B401B0 | （无名） 断言站点 gamegraphics.cpp:321 |
| 0x140E40DB0 | （无名） 体设 CPeaceBiddingTurn::vftable（RTTI 名） |
| 0x1402CC030 | （无名） 体设 CNationalFocus::vftable（RTTI 名） |
| 0x141B772F0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1414DB090 | （无名） 体设 SBookmarkPlaythroughData::vftable（RTTI 名） |
| 0x1412A5D60 | （无名） 体设 SNavalUnitActivityData::vftable（RTTI 名） |
| 0x1420871D0 | （无名） 体设 CTweakableCharArrayManipulator::vftable（RTTI 名） |
| 0x1401B2600 | （无名） 体设 SControlGroupData::vftable（RTTI 名） |
| 0x1409F1260 | （无名） 体设 CEquipmentType::vftable（RTTI 名） |
| 0x141253BC0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1422F6450 | （无名） 体设 CWindowType::vftable（RTTI 名） |
| 0x141CAF090 | （无名） 体设 CProjectSimpleRoster::vftable（RTTI 名） |
| 0x141F5ACF0 | （无名） 体设 CHostConfigurationPupup::vftable（RTTI 名） |
| 0x140F76CC0 | （无名） 体设 SStrategicTarget::vftable（RTTI 名） |
| 0x140A48E70 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x140BBCA70 | （无名） 体设 SIdCounter::vftable（RTTI 名） |
| 0x1409FC280 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x141284230 | （无名） 体设 SPostEffectHeightVolumeReader::vftable（RTTI 名） |
| 0x141002610 | （无名） 体设 CDominanceValues::vftable（RTTI 名） |
| 0x1410E33D0 | （无名） 体设 SScopeLocalizer::vftable（RTTI 名） |
| 0x141D0A070 | （无名） 体设 CConfirmDeleteUnits::vftable（RTTI 名） |
| 0x141D0A950 | （无名） 体设 CConfirmDeleteUnits::vftable（RTTI 名） |
| 0x142384F90 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140AE45C0 | （无名） 体设 CUnitLeaderTrait::vftable（RTTI 名） |
| 0x142020DA0 | （无名） 体设 CSaveQueuePopUp::vftable（RTTI 名） |
| 0x141C2E1C0 | （无名） 体设 CDeleteOrRenameFolderPopUp::vftable（RTTI 名） |
| 0x141C2DA10 | （无名） 体设 CChangeDesignFolderPopUp::vftable（RTTI 名） |
| 0x140A8B3C0 | （无名） 体设 CPowerBalanceDatabase::vftable（RTTI 名） |
| 0x142047880 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140A47CA0 | （无名） 体设 CIdeology::vftable（RTTI 名） |
| 0x1417ABF60 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140737F60 | （无名） 体设 CDecisionCooldown::vftable（RTTI 名） |
| 0x140AF4730 | （无名） 体设 CUnitNamesPool::vftable（RTTI 名） |
| 0x1419639F0 | （无名） 体设 SAirWingCombatData::vftable（RTTI 名） |
| 0x140FCAC70 | （无名） 体设 CCountryLeader::vftable（RTTI 名） |
| 0x1418EB1F0 | （无名） 体设 CRaidMapIconVariant::vftable（RTTI 名） |
| 0x140FF3CD0 | （无名） 体设 CCountryOccupationData::vftable（RTTI 名） |
| 0x140A30D50 | （无名） 体设 CFactionTemplate::vftable（RTTI 名） |
| 0x14068FB70 | （无名） 体设 SProfileData::vftable（RTTI 名） |
| 0x1413CE5A0 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x141E7F660 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140A4F710 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x140F4B510 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1406C8CD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141FBF290 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141DDEC00 | （无名） 体设 CEquipmentUpgradesInstance::vftable（RTTI 名） |
| 0x140B10DD0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140DB2100 | （无名） 体设 SHistoryWithEquipment::vftable（RTTI 名） |
| 0x1401F14A0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14063B4D0 | （无名） 体设 CRuleDefinition::vftable（RTTI 名） |
| 0x141516180 | （无名） 体设 SInvasionReport::vftable（RTTI 名） |
| 0x1410B5EC0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141DBF580 | （无名） 体设 CBuildingItemBase::vftable（RTTI 名） |
| 0x1413CE880 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x141EFAFC0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x1409FBFD0 | （无名） 体设 CEquipmentGraphicPoolTypeMap::vftable（RTTI 名） |
| 0x140DBF140 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140DB1E70 | （无名） 体设 SHistoryWithEquipment::vftable（RTTI 名） |
| 0x1401E17C0 | （无名） 体设 SControlGroupData::vftable（RTTI 名） |
| 0x140DBAE10 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x140A885A0 | （无名） 体设 CPortraitPool::vftable（RTTI 名） |
| 0x141282D60 | （无名） 体设 SPostEffectHeightVolumeReader::vftable（RTTI 名） |
| 0x1413CD860 | （无名） 体设 SNavalUnitActivityData::vftable（RTTI 名） |
| 0x1406779F0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1424D45E0 | （无名） 体设 CTask::vftable（RTTI 名） |
| 0x140678AC0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140B903E0 | （无名） 体设 CMusicPlayerSettings::vftable（RTTI 名） |
| 0x141513E00 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140CDD0E0 | （无名） 体设 SModifierHours::vftable（RTTI 名） |
| 0x140AD1AA0 | （无名） 体设 CFolderPosition::vftable（RTTI 名） |
| 0x141A139D0 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x141882FF0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1414EA780 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1411ADC30 | （无名） 体设 CIntelSource::vftable（RTTI 名） |
| 0x140A491E0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x141C2DD20 | （无名） 体设 CCreateFolderPopUp::vftable（RTTI 名） |
| 0x141017780 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x14165D730 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140FCA190 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x14204A7D0 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x14055A610 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x1409CEB50 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141E80480 | （无名） 体设 CIntelMapModeMapIconMore::vftable（RTTI 名） |
| 0x141262290 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1419837A0 | （无名） 体设 CTowardsOverlordRedistributer::vftable（RTTI 名） |
| 0x142088490 | （无名） 体设 CTweakableGraphManipulator::vftable（RTTI 名） |
| 0x140221300 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140DC7500 | （无名） 体设 SControlGroupData::vftable（RTTI 名） |
| 0x141DCBDB0 | （无名） 断言站点 entity_sprite.cpp:215 |
| 0x14183A570 | （无名） 体设 COrderReplaceFallbackCommands::vftable（RTTI 名） |
| 0x14155BD00 | （无名） 体设 COccupiedTerritoryStateEntryWithoutResistance::vftable（RTTI 名） |
| 0x141271FF0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1424E9910 | （无名） 体设 Node_endif::vftable（RTTI 名） |
| 0x141F4D0C0 | （无名） 体设 CNationalSpiritItemBig::vftable（RTTI 名） |
| 0x141B91890 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x141FE48A0 | （无名） 体设 CCareerProfilePageDot::vftable（RTTI 名） |
| 0x141925050 | （无名） 体设 CPersistedMioQueues::vftable（RTTI 名） |
| 0x140A6C090 | （无名） 体设 SScriptedKey::vftable（RTTI 名） |
| 0x141D0ACB0 | （无名） 体设 CConfirmDeleteUnits::vftable（RTTI 名） |
| 0x1406D1C20 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141915410 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x1411F58A0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x141AEC9D0 | （无名） 体设 CCallbacksWrapper::vftable（RTTI 名） |
| 0x141298030 | （无名） 体设 CBuildingReference::vftable（RTTI 名） |
| 0x140AA2200 | （无名） 体设 CCountryScorerDatabase::vftable（RTTI 名） |
| 0x140FDF610 | （无名） 体设 SProjectHistory::vftable（RTTI 名） |
| 0x140C3BDE0 | （无名） 体设 SNavalUnitActivityData::vftable（RTTI 名） |
| 0x140D47240 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140CFEEA0 | （无名） 体设 CStaticIntelSourcePool::vftable（RTTI 名） |
| 0x14208A050 | （无名） 体设 CTweakableTitle::vftable（RTTI 名） |
| 0x140EF39B0 | （无名） 体设 SPerCountrySection::vftable（RTTI 名） |
| 0x14070D220 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141EBB3F0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x140D1FB80 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141A2D9B0 | （无名） 体设 CConfirmDeleteOrder::vftable（RTTI 名） |
| 0x140C1BA20 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x140E537A0 | （无名） 体设 CPowerBalanceSideInfo::vftable（RTTI 名） |
| 0x140324F50 | （无名） 体设 SUnitOfficerData::vftable（RTTI 名） |
| 0x140223250 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x140170EC0 | （无名） 体设 CFactionMemberUpgradeGroupDatabase::vftable（RTTI 名） |
| 0x140A21490 | （无名） 体设 SCustomUniformReaderSimpleStatement::vftable（RTTI 名） |
| 0x14182ADC0 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x140D2CAE0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x140638880 | （无名） 体设 CRuleDefinition::vftable（RTTI 名） |
| 0x14203D960 | （无名） 体设 CListController::vftable（RTTI 名） |
| 0x140A6C260 | （无名） 体设 SProgressbar::vftable（RTTI 名） |
| 0x140172720 | （无名） 体设 COperationTokensDatabase::vftable（RTTI 名） |
| 0x140170A40 | （无名） 体设 CFactionGoalDatabase::vftable（RTTI 名） |
| 0x140171040 | （无名） 体设 CFactionRuleDatabase::vftable（RTTI 名） |
| 0x141EFAEA0 | （无名） 体设 CTraitBonus::vftable（RTTI 名） |
| 0x1413FED00 | （无名） 体设 CGregorianDate::vftable（RTTI 名） |
| 0x141455D80 | （无名） 体设 SRedistribution::vftable（RTTI 名） |
| 0x141CFDBA0 | （无名） 体设 CConfirmDeleteOrdersGroup::vftable（RTTI 名） |
| 0x1401714C0 | （无名） 体设 CFocusInlayWindowDatabase::vftable（RTTI 名） |
| 0x140F8F980 | （无名） 体设 SActiveResistanceAction::vftable（RTTI 名） |
| 0x141650F30 | （无名） 体设 SDistanceMesh::vftable（RTTI 名） |
| 0x140A21A10 | （无名） 体设 SEnvironmentLocalizer::vftable（RTTI 名） |
| 0x1406C6570 | （无名） 体设 CNuke::vftable（RTTI 名） |
| 0x141DF0990 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1402C49D0 | （无名） 体设 CFocusInlayWindowInstance::vftable（RTTI 名） |
| 0x1414E84B0 | （无名） 体设 CRaidTargetCooldownStatus::vftable（RTTI 名） |
| 0x1412A8C80 | （无名） 体设 SUnitActivityData::vftable（RTTI 名） |
| 0x1422CECB0 | （无名） 断言站点 browserui.cpp:237 |
| 0x140FD6B30 | （无名） 体设 CCapturedOperativeReference::vftable（RTTI 名） |
| 0x1413ACE10 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x1406AA8A0 | （无名） 体设 CTierColors::vftable（RTTI 名） |
| 0x141022DD0 | （无名） 体设 SChildFrontData::vftable（RTTI 名） |
| 0x141C8B380 | （无名） 体设 CDiplomacySendVolunteersController::vftable（RTTI 名） |
| 0x1411ACA60 | （无名） 体设 CIntelSource::vftable（RTTI 名） |
| 0x140D07660 | （无名） 体设 CSubunitBonusPersistent::vftable（RTTI 名） |
| 0x1414607A0 | （无名） 体设 SOptionalEquipmentAssets::vftable（RTTI 名） |
| 0x14145F3A0 | （无名） 体设 SSkillLevel::vftable（RTTI 名） |
| 0x1422D06A0 | （无名） 体设 CCallbackButtonStandard::vftable（RTTI 名） |
| 0x1406898D0 | （无名） 体设 SProfileData::vftable（RTTI 名） |
| 0x140689BE0 | （无名） 体设 SCareerProfileModDataSet::vftable（RTTI 名） |
| 0x140B99000 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x1401706D0 | （无名） 体设 CEquipmentGraphicDatabase::vftable（RTTI 名） |
| 0x1412E88C0 | （无名） 体设 CDiplomaticAction::vftable（RTTI 名） |
| 0x140B4B1F0 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x14011E780 | （无名） 体设 System_error::vftable（RTTI 名） |
| 0x140F73210 | （无名） 体设 SLogisticsStrikeTarget::vftable（RTTI 名） |
| 0x1407102D0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1413CA740 | （无名） 体设 STemporaryCostReduction::vftable（RTTI 名） |
| 0x140FF9EC0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141FBA990 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x140A4C510 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x140B71540 | （无名） 体设 CReloadDispatcher::vftable（RTTI 名） |
| 0x14177A880 | （无名） 体设 CTooltipHandler::vftable（RTTI 名） |
| 0x140EAF300 | （无名） 体设 SRegionalConvoyData::vftable（RTTI 名） |
| 0x142294170 | （无名） 断言站点 pdxparticleobject.cpp:145 |
| 0x1410080B0 | （无名） 断言站点 gamerendering.cpp:701 |
| 0x1409F85F0 | （无名） 体设 CEquipmentFilter::vftable（RTTI 名） |
| 0x140E6F820 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x1418CE100 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141983AA0 | （无名） 体设 SRedistribution::vftable（RTTI 名） |
| 0x140DBBDB0 | （无名） 体设 CGameDate::vftable（RTTI 名） |
| 0x141517980 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x141542970 | （无名） 体设 STraitId::vftable（RTTI 名） |
| 0x141F6C210 | （无名） 体设 CConfirmDeleteEquipment::vftable（RTTI 名） |
| 0x140645D90 | （无名） 体设 CStrategySpecificData::vftable（RTTI 名） |
| 0x140FDFC00 | （无名） 体设 CScriptFlag::vftable（RTTI 名） |
| 0x140A26110 | （无名） 体设 CModifier::vftable（RTTI 名） |
| 0x14138F580 | （无名） 体设 CColor::vftable（RTTI 名） |
| 0x1422FC630 | （无名） 断言站点 piechart.cpp:46 |
| 0x1422FC530 | （无名） 断言站点 piechart.cpp:46 |
| 0x1422A9340 | （无名） 体设 COptionObserver::vftable（RTTI 名） |
| 0x1422FF2D0 | （无名） 体设 COptionObserver::vftable（RTTI 名） |
| 0x14101B5E0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x140C0B600 | （无名） 体设 CUnitAdjuster::vftable（RTTI 名） |
| 0x14101AFC0 | （无名） 体设 CSubUnitDefinitionId::vftable（RTTI 名） |
| 0x142277630 | （无名） 断言站点 pdxmeshobject.cpp:814 |

#### 4.1.27 CGameState 派发族与门控函数补遗（180 函）

| VA | 语义/证据 |
|---|---|
| 0x141025340 | （无名） 调用图传播: 34 锚点投 §4.1（53%） |
| 0x14118CD10 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x1402C7A60 | （无名） 调用图传播: 17 锚点投 §4.1（53%） |
| 0x1411DBED0 | （无名） 调用图传播: 15 锚点投 §4.1（60%） |
| 0x140E53AB0 | （无名） 调用图传播: 17 锚点投 §4.1（53%） |
| 0x1401AE6C0 | （无名） 调用图传播: 20 锚点投 §4.1（90%） |
| 0x141A24930 | （无名） 调用图传播: 15 锚点投 §4.1（60%） |
| 0x140E912C0 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x1404A7EA0 | （无名） 调用图传播: 17 锚点投 §4.1（53%） |
| 0x1410E7520 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x1419327B0 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x140E99F40 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x14068A320 | （无名） 调用图传播: 15 锚点投 §4.1（60%） |
| 0x141592210 | （无名） 调用图传播: 15 锚点投 §4.1（60%） |
| 0x140611140 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x1414B6480 | （无名） 调用图传播: 17 锚点投 §4.1（53%） |
| 0x1401B30C0 | （无名） 调用图传播: 16 锚点投 §4.1（56%） |
| 0x140E99540 | （无名） 调用图传播: 15 锚点投 §4.1（60%） |
| 0x1411CD260 | （无名） 调用图传播: 16 锚点投 §4.1（62%） |
| 0x14067ACF0 | （无名） 调用图传播: 15 锚点投 §4.1（60%） |
| 0x140518F70 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141529F90 | （无名） 调用图传播: 12 锚点投 §4.1（58%） |
| 0x1410D0C20 | （无名） 调用图传播: 8 锚点投 None（100%） None |
| 0x142349590 | （无名） 调用图传播: 3 锚点投 None（100%） None |
| 0x140D55AD0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140713AD0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140BD5B40 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1414AB7A0 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x1417190D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1401EB480 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140D4F2F0 | （无名） 调用图传播: 11 锚点投 §4.1（55%） |
| 0x141985570 | （无名） 调用图传播: 8 锚点投 §4.1（50%） |
| 0x1411244B0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140EC4900 | （无名） 调用图传播: 4 锚点投 None（50%） None |
| 0x141984D10 | （无名） 调用图传播: 8 锚点投 §4.1（50%） |
| 0x140F8BED0 | （无名） 调用图传播: 3 锚点投 None（100%） None |
| 0x1415464B0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1401E3040 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140FE27E0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140AF1000 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140B9D140 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1419851B0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140D43280 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CF9A50 | （无名） 调用图传播: 4 锚点投 None（50%） None |
| 0x14154B8A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1415FB500 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141441FD0 | （无名） 调用图传播: 2 锚点投 None（50%） None |
| 0x140EFF270 | （无名） 调用图传播: 2 锚点投 None（50%） None |
| 0x141102B40 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1406921C0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1412C7200 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141401D00 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1401B37D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140D45490 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140D2CC90 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1418AD330 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141003830 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141491200 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CA9E20 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140E79700 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140DED8C0 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x141D26A60 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140A48DC0 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x1412B92B0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140CB4B50 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1414FC980 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CE7420 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141D28510 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140FC9940 | （无名） 调用图传播: 2 锚点投 None（100%） None |
| 0x140CEB930 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424BEE30 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141491430 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1401F84B0 | （无名） 调用图传播: 4 锚点投 §4.1（75%） |
| 0x140CB6BD0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C4EB80 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1410A25B0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140CFBFF0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1414AC730 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140A82000 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140A82730 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14196B740 | （无名） 调用图传播: 2 锚点投 None（100%） None |
| 0x1424C3EC0 | （无名） 调用图传播: 6 锚点投 None（50%） None |
| 0x1406773F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1413CECD0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140FC8050 | （无名） 调用图传播: 5 锚点投 None（100%） None |
| 0x140D43AA0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140CAC830 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x141512D10 | （无名） 调用图传播: 4 锚点投 §4.1（75%） |
| 0x140FE9870 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141987BF0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141960FF0 | （无名） 调用图传播: 7 锚点投 None（57%） None |
| 0x140D3E450 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141985A60 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1419872A0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1401F8400 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x14113F730 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x141D2D770 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140BA2730 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140D112E0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140F60B20 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1413A11A0 | （无名） 调用图传播: 2 锚点投 None（50%） None |
| 0x1410FD5D0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1410FDDA0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1405264E0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CFE6D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14196E0D0 | （无名） 调用图传播: 3 锚点投 None（67%） None |
| 0x1413251A0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141E00B00 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x14152E670 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140F60A80 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1410FFA90 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141137DB0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1413BB1B0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C88050 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140D67310 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1412B4B90 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x1412B4C20 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x1424C4480 | （无名） 调用图传播: 4 锚点投 None（50%） None |
| 0x141857300 | PayloadWriter 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140D70270 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140E55960 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1413E2770 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CCF480 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424C4290 | （无名） 调用图传播: 4 锚点投 None（50%） None |
| 0x140CC3F40 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140E88A70 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424C3A90 | （无名） 调用图传播: 4 锚点投 None（50%） None |
| 0x140E88AF0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CD0950 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1412C9AA0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CFDF60 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1414AE130 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140CC4FE0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140E27420 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CD4140 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CD4180 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CD5830 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1411FB1B0 | （无名） 调用图传播: 2 锚点投 None（100%） None |
| 0x1419536D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141F168E0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140F661A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141442140 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1414428D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140EFAE00 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140FACD00 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140FABB10 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140D0E6E0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1418AC110 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1418ABB10 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140E6FD80 | （无名） 调用图传播: 2 锚点投 None（50%） None |
| 0x140C3D8A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14116EE40 | PayloadWriter 调用图传播: 4 锚点投 None（50%） None |
| 0x140CFE5C0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1418572A0 | PayloadWriter 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140DBBB20 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C24D50 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CDF0A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1413A06A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1411FB120 | （无名） 调用图传播: 2 锚点投 None（50%） None |
| 0x1411D6BE0 | （无名） 调用图传播: 5 锚点投 None（60%） None |
| 0x1414941D0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1411FB180 | （无名） 调用图传播: 2 锚点投 None（100%） None |
| 0x1414013D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CEF1A0 | PayloadWriter 调用图传播: 3 锚点投 None（67%） None |
| 0x14116F320 | PayloadWriter 调用图传播: 3 锚点投 None（67%） None |
| 0x141170F00 | PayloadWriter 调用图传播: 3 锚点投 None（67%） None |
| 0x140CEF210 | PayloadWriter 调用图传播: 3 锚点投 None（67%） None |
| 0x14135D860 | PayloadWriter 调用图传播: 3 锚点投 None（67%） None |
| 0x14147FD00 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140A6D970 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141170720 | PayloadWriter 调用图传播: 3 锚点投 None（67%） None |
| 0x140D11950 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14147DE10 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141723940 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141343390 | PayloadWriter 调用图传播: 2 锚点投 None（100%） None |
| 0x140DEA330 | PayloadWriter 调用图传播: 2 锚点投 None（100%） None |
| 0x141037D90 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1418DC5F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141BAECA0 | PayloadWriter 调用图传播: 2 锚点投 None（50%） None |
| 0x14178CC30 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |

#### 4.1.28 CGameState 派发族与门控函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x141681230 | CGlobals "gamestate unitilialized" 守卫后操作（同 0x140C596F0 同形） |
| 0x140C596F0 | CGlobals "gamestate unitilialized" 守卫后操作（同 0x141681230 同形） |

#### 4.1.29 CGameState 派发族与门控函数补遗（159 函）

| VA | 语义/证据 |
|---|---|
| 0x140669310 | gamestate 门控（调 sub_1406F0390/sub_140E7F530/sub_140E7F3F0）；无其他自文档证据 |
| 0x141E59E60 | 向 std::string 追加 '\n' + 以 0x11/0x52('R')/0x47('G') 分隔符调 sub_1401C0E70 格式化 向 std::string 追加 '\n' + 以 0x11/0x52('R')/0x47('G') 分隔符调 sub_1401C0E70 格式化：文本拼接/格式化（… |
| 0x1424B79F0 | 由 a1 构串后调 sub_1424B8380 分派（与 0x1424B6BA0/0x1424B7540 同簇） 由 a1 构串后调 sub_1424B8380 分派（与 0x1424B6BA0/0x1424B7540 同簇）：控制台命令处理 |
| 0x1424B6BA0 | 由 a1 构串后调 sub_1424B8380 分派（同 0x1424B79F0 簇） 由 a1 构串后调 sub_1424B8380 分派（同 0x1424B79F0 簇）：控制台命令处理 |
| 0x1424B7540 | 由 a1 构串后调 sub_1424B8380 分派（同 0x1424B79F0 簇） 由 a1 构串后调 sub_1424B8380 分派（同 0x1424B79F0 簇）：控制台命令处理 |
| 0x1413DA380 | 读 sub_140322EE0()+84 计数并按 1.5× 扩容数组，调 GUI 名查询 sub_1402DE9B0 读 sub_140322EE0()+84 计数并按 1.5× 扩容数组，调 GUI 名查询 sub_1402DE9B0：GUI 列表条目构建 |
| 0x141DA7C40 | gamestate 门控（调 sub_140BB48F0/sub_140BB52F0/sub_141DA1C60）；无其他自文档证据 |
| 0x140F31D50 | gamestate 门控 ×2（调 sub_141435950/sub_1406F9600/sub_1418E2590）；无其他自文档证据 |
| 0x142492CE0 | 状态机轮询 状态机轮询：a1+348 计数、a1+592 对象 +52/+56 标志、a1+464/536 计数交叉判定 + 调 sub_142493AF0 |
| 0x14071E8B0 | 由 a2+16 的 std::string 经 sub_142245E60 查 loc 键（0x5911 标记）再格式化 由 a2+16 的 std::string 经 sub_142245E60 查 loc 键（0x5911 标记）再格式化：本地化文本查找+格式化 |
| 0x1418E2EC0 | sub_1418E2EC0 gamestate 派发（gs+1312/1316，sub_14142F9E0 + a3+96），无域串/RTTI |
| 0x140C4A2F0 | sub_140C4A2F0 遍历 +296/+308 数组 + +224/+154 标志判定（gamestate 对象迭代），无域串 |
| 0x1409BD210 | CGameState 访问器（调用 CGameState::[2]，遍历 +984 偏移成员） sub_1409BD210 调 CGameState::[2] 后读 `*v7+984` |
| 0x14154B390 | gamestate 门控（调 sub_1401FA5E0/sub_1401FAE70/sub_14154A4A0）；无其他自文档证据 |
| 0x142491E00 | 同 0x142492CE0 形态（调 sub_142493AF0/sub_1424932F0/sub_142493440 同簇） 同 0x142492CE0 形态（调 sub_142493AF0/sub_1424932F0/sub_142493440 同簇）：状态机轮询 |
| 0x14124EB30 | sub_14124EB30 gamestate 单例方法派发（(*(gs+1))(gs+8, v9)），无域串/无 RTTI |
| 0x141B71B80 | gamestate 门控 ×2（调 sub_140A60F10/sub_141B75960）；无其他自文档证据 |
| 0x141D96C30 | 经 sub_1424EF6F0/sub_140129C10 构建本地化字符串（a3<a4 区间条件） 经 sub_1424EF6F0/sub_140129C10 构建本地化字符串（a3<a4 区间条件）：loc 文本构建 |
| 0x1418C8E90 | sub_1418C8E90 gamestate 派发（gs+1312/1316，sub_140C57400），无域串/RTTI |
| 0x141063D10 | 对列表元素按 100000 缩放求和、再做 100000*v16/v6 比值并 +10000 钳位（与 CHostileAttitude::GetScore 共用 sub_1406CF0F0） 对列表元素按 100000 缩放求和、再做 100000*v16/v6 比值并 +10000 钳位（与 CHostile… |
| 0x14192AE40 | 调 sub_142291330（实体族）+ 向 a1+5256 字符串追加 '_' 再格式化 调 sub_142291330（实体族）+ 向 a1+5256 字符串追加 '_' 再格式化：实体名构建 |
| 0x1424EA480 | 存档分块接收（largefile chunk） head：sub_1424E62A0(&v33, a1) + (a1+5) 遍历 |
| 0x141FB60E0 | 数据库索引取值（+84 计数 / +72 数组 / 56B 步长） head：`v4 = sub_140300560(); v8 = v6 + 56 * (...)` |
| 0x142343C20 | 按 a1+12 计数把 0x550（1360）字节条目 memcpy 到 a2+1360*idx 并对 10 对子区调 sub_14232C820 修正 按 a1+12 计数把 0x550（1360）字节条目 memcpy 到 a2+1360*idx 并对 10 对子区调 sub_14232C820 修正：定长块… |
| 0x1421EF350 | 存档流读取回调 head：`(char *a1, u64 a2, u64 a3, fn a4)` + sub_1420FFED0(a3) |
| 0x1417711F0 | sub_1417711F0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x142063800 | sub_142063800 gamestate 派发（gs+1312/1316，byte_14332ED01 缓存），无域串 |
| 0x14053CBF0 | sub_14053CBF0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140F32240 | sub_140F32240 gamestate 子对象（sub_140161D30()+640）+ 本地化字符串构建 + 数组遍历，无域串 |
| 0x141E70A00 | sub_141E70A00 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x1420F0BD0 | 调试覆盖层开关簇 head：dword_143450C78 / dword_143450CC8 门 + sub_142109F20(…, 1.0f) |
| 0x141242DB0 | sub_141242DB0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141670240 | sub_141670240 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140C30D30 | sub_140C30D30 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141B83970 | sub_141B83970 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140F40750 | sub_140F40750 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140F40A60 | sub_140F40A60 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140B14730 | sub_140B14730 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141078AB0 | sub_141078AB0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140248910 | sub_140248910 gamestate 作用域访问（断言 gamestate unitilialized） |
| 0x1420F0830 | 调试覆盖层开关簇 head：dword_143450C80 / qword_143450C88 + sub_1420FFF10 |
| 0x140DD3780 | sub_140DD3780 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140BFC4C0 | sub_140BFC4C0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141BE6560 | sub_141BE6560 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140D25990 | sub_140D25990 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x1409D0720 | sub_1409D0720 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140F09EA0 | sub_140F09EA0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141B6EBC0 | sub_141B6EBC0 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140EF6700 | sub_140EF6700 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141E53090 | sub_141E53090 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141E6BD80 | sub_141E6BD80 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x141A03F40 | sub_141A03F40 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140A33080 | sub_140A33080 容器节点插入式重排（sub_140A387C0/AD + sub_1401EB230）（gamestate 容器维护） |
| 0x1401DAF40 | sub_1401DAF40 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141A08F20 | sub_141A08F20 gamestate 作用域访问（断言「gamestate unitilialized」+「ThreadForbidCount == 0」） |
| 0x140E1DB10 | 无名领域函数 sub_140E1DB10 调用 gamestate id→索引查询 sub_140BB5490/48F0（1 次，校准定案：调它的函数属 §4.1） |
| 0x140C0E360 | sub_140C0E360 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141454910 | sub_141454910 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140B11640 | sub_140B11640 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1414B3360 | 无名领域函数 sub_1414B3360 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x141E6D580 | sub_141E6D580 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x14065FD40 | sub_14065FD40 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140736150 | 无名领域函数 sub_140736150 调用 gamestate id→索引查询 sub_140BB5490/48F0（1 次，校准定案：调它的函数属 §4.1） |
| 0x1411EE4C0 | 无名领域函数 sub_1411EE4C0 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CCF0A0 | sub_140CCF0A0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1411E1F50 | 无名领域函数 sub_1411E1F50 调用 gamestate id→索引查询 sub_140BB5490/48F0（4 次，校准定案：调它的函数属 §4.1） |
| 0x140CC0720 | sub_140CC0720 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CC3740 | sub_140CC3740 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CC5A30 | sub_140CC5A30 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CC1520 | 无名领域函数 sub_140CC1520 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CC1F40 | sub_140CC1F40 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CC3140 | sub_140CC3140 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CC4790 | 无名领域函数 sub_140CC4790 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CC5430 | sub_140CC5430 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CCF290 | sub_140CCF290 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CD0990 | 无名领域函数 sub_140CD0990 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CD2FE0 | 无名领域函数 sub_140CD2FE0 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CD4CB0 | 无名领域函数 sub_140CD4CB0 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CD5870 | sub_140CD5870 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CCF4D0 | 无名领域函数 sub_140CCF4D0 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CD2310 | sub_140CD2310 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CD5090 | sub_140CD5090 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140F74400 | 无名领域函数 sub_140F74400 调用 gamestate id→索引查询 sub_140BB5490/48F0（1 次，校准定案：调它的函数属 §4.1） |
| 0x140CCE010 | sub_140CCE010 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CCFE70 | sub_140CCFE70 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CD2130 | sub_140CD2130 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CD3BA0 | 无名领域函数 sub_140CD3BA0 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140CD6620 | 无名领域函数 sub_140CD6620 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x1414B1990 | sub_1414B1990 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x1401EE0B0 | sub_1401EE0B0 CGameState 游玩数据/单例查询（_AllPlaythroughData） |
| 0x141CBF560 | 无名领域函数 sub_141CBF560 调用 gamestate id→索引查询 sub_140BB5490/48F0（1 次，校准定案：调它的函数属 §4.1） |
| 0x1418C39E0 | sub_1418C39E0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141BE1D40 | sub_141BE1D40 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1407363B0 | 无名领域函数 sub_1407363B0 调用 gamestate id→索引查询 sub_140BB5490/48F0（1 次，校准定案：调它的函数属 §4.1） |
| 0x140CE1710 | sub_140CE1710 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1418C22D0 | 无名领域函数 sub_1418C22D0 调用 gamestate id→索引查询 sub_140BB5490/48F0（3 次，校准定案：调它的函数属 §4.1） |
| 0x140EC4A90 | sub_140EC4A90 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140FD3B10 | sub_140FD3B10 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1401C9D40 | 无名领域函数 sub_1401C9D40 断言站点 \hoi4\\source\\gamestate.cpp（游戏状态） |
| 0x141433440 | 无名领域函数 sub_141433440 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140E94500 | sub_140E94500 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x142539178 | sub_142539178 串:$+xv §待裁 |
| 0x141E05B00 | sub_141E05B00 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x14162EB70 | 无名领域函数 sub_14162EB70 调用 gamestate id→索引查询 sub_140BB5490/48F0（4 次，校准定案：调它的函数属 §4.1） |
| 0x140D3D300 | sub_140D3D300 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x14149B8E0 | sub_14149B8E0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1419004C0 | sub_1419004C0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140F32E00 | sub_140F32E00 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x142037070 | sub_142037070 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141E78E80 | sub_141E78E80 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140CFBE70 | sub_140CFBE70 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x141555030 | 无名领域函数 sub_141555030 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x141C0CE90 | 无名领域函数 sub_141C0CE90 调用 gamestate id→索引查询 sub_140BB5490/48F0（1 次，校准定案：调它的函数属 §4.1） |
| 0x141BB5C90 | sub_141BB5C90 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x14162ED60 | sub_14162ED60 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x140B53D20 | sub_140B53D20 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140535E30 | sub_140535E30 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141B738D0 | sub_141B738D0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141C70760 | sub_141C70760 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141F28120 | sub_141F28120 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140D224D0 | 无名领域函数 sub_140D224D0 调用 gamestate id→索引查询 sub_140BB5490/48F0（3 次，校准定案：调它的函数属 §4.1） |
| 0x141A04D40 | sub_141A04D40 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1411E8E00 | 无名领域函数 sub_1411E8E00 调用 gamestate id→索引查询 sub_140BB5490/48F0（2 次，校准定案：调它的函数属 §4.1） |
| 0x140D89650 | sub_140D89650 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141DD7820 | sub_141DD7820 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140E358E0 | 无名领域函数 sub_140E358E0 调用 gamestate id→索引查询 sub_140BB5490/48F0（4 次，校准定案：调它的函数属 §4.1） |
| 0x140E94B40 | sub_140E94B40 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1406FD3A0 | 无名领域函数 sub_1406FD3A0 调用 gamestate id→索引查询 sub_140BB5490/48F0（5 次，校准定案：调它的函数属 §4.1） |
| 0x140E34C30 | sub_140E34C30 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x141963860 | sub_141963860 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x140A27EF0 | sub_140A27EF0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1401E2940 | sub_1401E2940 串:ThreadIsMainThread() |
| 0x1402AB620 | sub_1402AB620 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141A91980 | sub_141A91980 串:Unit ; Scope §待裁 |
| 0x141A915C0 | sub_141A915C0 串:Scope §待裁 |
| 0x141A93500 | sub_141A93500 串:Root ; Scope §待裁 |
| 0x140A8CF60 | sub_140A8CF60 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141A93340 | sub_141A93340 串:This ; Scope §待裁 |
| 0x1418BB780 | sub_1418BB780 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x1401C8530 | 同区段近邻 sub_1401C0C50(距 0x78E0)属 4.1 族 sub_1401C8530 + 同区段近邻 sub_1401C0C50(距 0x78E0)属 4.1 族 |
| 0x140C4CC90 | sub_140C4CC90 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x140FB7740 | sub_140FB7740 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x1414B38F0 | sub_1414B38F0 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x140CBB480 | sub_140CBB480 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x141434100 | sub_141434100 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x141433FB0 | sub_141433FB0 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x140FF85C0 | sub_140FF85C0 经 CCurrentGameState 单例读游戏态（gamestate.h 线程禁令断言） |
| 0x141433280 | sub_141433280 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x140D02980 | sub_140D02980 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x141F76130 | sub_141F76130 串:_mediu §待裁 |
| 0x141465860 | sub_141465860 串:_mediu §待裁 |
| 0x141434C30 | sub_141434C30 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x142462CE0 | sub_142462CE0 串:Orientation §待裁 |
| 0x140C5C780 | sub_140C5C780 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x1406F6F20 | sub_1406F6F20 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x141435F70 | sub_141435F70 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x1414353C0 | sub_1414353C0 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |
| 0x1401C61E0 | 同区段近邻 sub_1401C0C50(距 0x5590)属 4.1 族 sub_1401C61E0 + 同区段近邻 sub_1401C0C50(距 0x5590)属 4.1 族 |
| 0x1406EB310 | sub_1406EB310 调用 id 查询 sub_140BB5490（读 *(gs+104)+4*id） |

#### 4.1.30 CGameState 派发族与门控函数补遗（95 函）

| VA | 语义/证据 |
|---|---|
| 0x1419BF580 | （无名） 调用图传播: 67 锚点投 §4.1（66%） |
| 0x141309D80 | （无名） 调用图传播: 52 锚点投 §4.1（50%） |
| 0x14242AB20 | （无名） 调用图传播: 13 锚点投 §4.1（54%） |
| 0x1412B4CB0 | （无名） 调用图传播: 29 锚点投 §4.1（52%） |
| 0x1412798D0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1420F5970 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141888010 | （无名） 调用图传播: 8 锚点投 §4.1（50%） |
| 0x1410AB130 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140249360 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x141EE3150 | gamestate.h:1116 _pInstance/主线程断言 |
| 0x14024DA90 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1403C4E20 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x14187B980 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x1420D3620 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140DFBCB0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140A58FA0 | （无名） 调用图传播: 8 锚点投 §4.1（62%） |
| 0x140EB84C0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1424E32A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140A36390 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14113A9A0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x141556460 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1422495D0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14024EBD0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x14072E140 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1420E6E70 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140E32240 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x141F6A450 | （无名） 调用图传播: 4 锚点投 §4.1（75%） |
| 0x1424CC7B0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140F7AFC0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x14072A5B0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1418710F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CE9270 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x142103530 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14072A8B0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1406664F0 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140E2BC40 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x141DFEE60 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140A8D4A0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x14109E4B0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140A2CEA0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140D36700 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140548FB0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1415579F0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1413BC8B0 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x140D3C0D0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1414306B0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x14224B4A0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140E41190 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140D30EB0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1401B4A50 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140E37900 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1414316F0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1420D0180 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1415759A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C5D0F0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1420D5CF0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140D2D780 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x141CB77B0 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1410A2C40 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140C311F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140CFA720 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x140CFA3C0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x142109820 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14240BD70 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14127D790 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x14106ACC0 | （无名） 调用图传播: 10 锚点投 §4.1（50%） |
| 0x14072ED60 | 无名 · 元素比较经 sub_140BB5490（gamestate id→索 元素比较经 sub_140BB5490（gamestate id→索引查询） |
| 0x1420C2710 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14211F5D0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1420C3760 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140CFC240 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x142124E20 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1420F2FA0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x14127E9D0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1420E6000 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x142063CF0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1414B7E10 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141553DB0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1420F20E0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141577320 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x14024AB00 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140A60B10 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424E0BE0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x14011FF60 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140A35410 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14024C110 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14024C540 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1415772A0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x1415773C0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x1415772E0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x141D744F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141BCDEB0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141D74520 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141D74550 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1409D80E0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |

#### 4.1.31 CGameState 派发族与门控函数补遗（15 函）

| VA | 语义/证据 |
|---|---|
| 0x141F9F390 | 业务逻辑（见证据锚） 调 sub_140BB5490（id→索引）+ CGlobals 断言（按校准属业务/§4.1） |
| 0x140BDAEC0 | 业务逻辑（见证据锚） id→串构造：sub_140BB4E70(a3) + '_'(95) 分隔追加 + sub_14011FF60 串合并 |
| 0x14025A2B0 | 业务逻辑（见证据锚） 控制台命令："Please specify amount of days"/"Fast Forwarded N Days (s)" |
| 0x140B66FA0 | 业务逻辑（见证据锚） sub_140BB48F0(gs+1312/1316) + 嵌套遍历 v9+384/v15+64 双层数组（CGlobals 对象族） |
| 0x140265CE0 | 业务逻辑（见证据锚） CGlobals 断言 + " ( … )\n" 串（括号数值显示），证据偏弱 |
| 0x1406698B0 | 业务逻辑（见证据锚） 时差 lerp 更新：sub_1405339D0(gs+1120) 时基 + 10000000000*v14/72000000 时长换算 + qword_143333368/420 插值写回 *(i+24) |
| 0x140BF7D00 | 业务逻辑（见证据锚） 调 sub_140BB5490（id→索引）+ 遍历 a1+424（count a1+436）按 sub_140CE7410 令牌匹配（按校准属业务/§4.1） |
| 0x1406FC510 | 业务逻辑（见证据锚） 时差遍历：sub_1405339D0(gs+1120) 时基 + 遍历 a1+5560（count a1+5572）按条目时间差处理 + sub_14053A610(…, a1+8) |
| 0x140234870 | 业务逻辑（见证据锚） 控制台命令："Please specify a number"/"Time: …"（时间设定） |
| 0x140E60F60 | CGameDate 游戏日期 (vtable类名 CGameDate) vtable引用 CGameDate vftable |
| 0x141B83C70 | CGameDate 游戏日期 (vtable类名 CGameDate) vtable引用 CGameDate vftable |
| 0x140FF1590 | CGameDate 游戏日期 (vtable类名 CGameDate) vtable引用 CGameDate vftable |
| 0x140D183C0 | CGregorianDate 公历日期 (vtable类名 CGregorianDate) vtable引用 CGregorianDate vftable |
| 0x1406C89E0 | CGregorianDate 公历日期 (vtable类名 CGregorianDate) vtable引用 CGregorianDate vftable |
| 0x14215D550 | CGameDate 游戏日期 (vtable类名 CGameDate) vtable引用 CGameDate vftable |

#### 4.1.32 CGameState 派发族与门控函数补遗（150 函）

| VA | 语义/证据 |
|---|---|
| 0x142219F30 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14252C7CC | （无名） 调用图传播: 5 锚点投 §4.1（80%） |
| 0x142540E6C | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1413101D0 | （无名） 调用图传播: 20 锚点投 §4.1（80%） |
| 0x141C630C0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1421E66F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424F98D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141578B20 | （无名） 调用图传播: 20 锚点投 §4.1（50%） |
| 0x140225C90 | （无名） 调用图传播: 19 锚点投 §4.1（53%） |
| 0x1418E5950 | （无名） 调用图传播: 12 锚点投 §4.1（50%） |
| 0x1422A87E0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x1416CA9F0 | （无名） 调用图传播: 8 锚点投 §4.1（50%） |
| 0x140226020 | （无名） 调用图传播: 19 锚点投 §4.1（53%） |
| 0x142165720 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140A8AC60 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x14123CC30 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140EA27C0 | （无名） 调用图传播: 5 锚点投 §4.1（80%） |
| 0x142127520 | （无名） 调用图传播: 7 锚点投 §4.1（86%） |
| 0x140538260 | （无名） 调用图传播: 5 锚点投 §4.1（100%） |
| 0x1420F3E20 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141C1C160 | （无名） 调用图传播: 8 锚点投 §4.1（100%） |
| 0x141B76AA0 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140FB4180 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141651790 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140D7E310 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x141B3E3D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140DBF600 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140DF7820 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x140D02750 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141357CE0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140DFD870 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140A4D520 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140C939D0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140D7DB60 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x14068D370 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140D7EA10 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14062DF70 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141C1BD20 | （无名） 调用图传播: 8 锚点投 §4.1（100%） |
| 0x1405152B0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x141652DA0 | （无名） 调用图传播: 7 锚点投 §4.1（100%） |
| 0x141E03A50 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1420F6670 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14209C310 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141E14310 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140D7E530 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x14070CEB0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1420C63B0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141283000 | （无名） 调用图传播: 7 锚点投 §4.1（57%） |
| 0x14130E690 | （无名） 调用图传播: 5 锚点投 §4.1（100%） |
| 0x141C1C760 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x141AED2B0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140C329D0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x141A004D0 | （无名） 调用图传播: 5 锚点投 §4.1（100%） |
| 0x140D60390 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1420F17E0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140535890 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1413FC800 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x140A51300 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x14068D240 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14069C460 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x140A88DE0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C0F2B0 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x140A35B80 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x142093560 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140CB5580 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140CAA0A0 | （无名） 调用图传播: 7 锚点投 §4.1（71%） |
| 0x140D30A30 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140687F00 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424BDB90 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x141039200 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x1415F9100 | （无名） 调用图传播: 7 锚点投 §4.1（57%） |
| 0x141E147E0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140A8B260 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141F2FC10 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141A1B2F0 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x141800F20 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141039300 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140DF74D0 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x140DC0F40 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141B3F110 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141511C30 | （无名） 调用图传播: 4 锚点投 §4.1（75%） |
| 0x140F49340 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140FCF4F0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1422A9460 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141539BA0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1422FF380 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x142119EA0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141282AA0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14177EC80 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14196B850 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141E148D0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1426EA330 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141DBB330 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C4BBE0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1426EA290 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x1426EA3D0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141205DF0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14208A930 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14012A6A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14012AA20 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14012A720 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14012AAA0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C4BEE0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141AB4450 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x140EA0570 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14191C340 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141B8A240 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1417A3EE0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x1416F8B00 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1415572F0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x14012A8A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x142126A40 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14068E8C0 | （无名） 调用图传播: 4 锚点投 §4.1（100%） |
| 0x140526320 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140C19EF0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x141800A70 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x141915BA0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x142237520 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x142098090 | （无名） 调用图传播: 6 锚点投 §4.1（50%） |
| 0x14212D330 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1401D3190 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141309C20 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140D03CB0 | （无名） 调用图传播: 5 锚点投 §4.1（80%） |
| 0x1422333D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1410FF4C0 | （无名） 调用图传播: 4 锚点投 §4.1（50%） |
| 0x140BEC340 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141984960 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1401D3220 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140EF1310 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141E7F050 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1420F1030 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x14208AC10 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1418BB970 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140EAFE40 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141BBFF10 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1410A9160 | （无名） 调用图传播: 5 锚点投 §4.1（60%） |
| 0x1417863D0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14148F5A0 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x14196B800 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140DB80B0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140DB8160 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141D9B870 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141E6C000 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x141E6C390 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140A67180 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14196B900 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x142386B10 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x1424EA430 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1419EDC00 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1419EDDD0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |

#### 4.1.33 CGameState 派发族与门控函数补遗（16 函）

| VA | 语义/证据 |
|---|---|
| 0x1422139F0 | （无名） 调用图传播: 9 锚点投 §4.1（56%） |
| 0x14211A2B0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x1402689A0 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x14211A1B0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x14211A0D0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x1412840D0 | （无名） 调用图传播: 3 锚点投 §4.1（100%） |
| 0x141E058B0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141B779B0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140DFD370 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140D7D130 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140D7D440 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140A4D140 | （无名） 调用图传播: 3 锚点投 §4.1（67%） |
| 0x140C92D20 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x141A09400 | （无名） 调用图传播: 2 锚点投 §4.1（50%） |
| 0x140A4D2A0 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |
| 0x140DFD300 | （无名） 调用图传播: 2 锚点投 §4.1（100%） |

#### 4.1.34 CGameState 派发族与门控函数补遗（366 函）

| VA | 语义/证据 |
|---|---|
| 0x141B64480 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1402516E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141F87E40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B326E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141175A90 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141CABD10 | 无名 sub_（断言站点/串定位） 断言站点 relation.h:177 |
| 0x1402A91F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14129F820 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14192C7B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1419BD4F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1413847B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1420987E0 | 无名 sub_（断言站点/串定位） 断言站点 particle_editor.cpp:144 |
| 0x141797550 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141F2FFF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141895650 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x14028AD60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140297720 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141322730 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141866C60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140288470 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140B09740 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141B86F50 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141A538F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1415706D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140237350 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141874910 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141628AA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1419B8FB0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141046630 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140289BA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140241DF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140282600 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141DA65B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14027EB90 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14111E230 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141EB7A00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141669620 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14027F7A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B1FA40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14152D4F0 | 无名 sub_（断言站点/串定位） 断言站点 pdx_bitmask_utils.h:255 |
| 0x1415AABA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1418647F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141A35960 | 无名 sub_（断言站点/串定位） 断言站点 project_state.cpp:240 |
| 0x1414E1D40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140EED780 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141D2D810 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141903210 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141B473A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141462A20 | 无名 sub_（断言站点/串定位） 断言站点 pdx_bitmask_utils.h:255 |
| 0x141E68E10 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1417369D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141B091A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141E0F010 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1412A2CF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141BE4BF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14023A710 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140DE21A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14154C470 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1420645B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141DD3A50 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141DA71F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140279330 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141DC5A80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141A04F40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140FD0680 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141BD7A00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140AB7210 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1126 |
| 0x141A02DC0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141EC29A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140263FD0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140F7B540 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140F5FC80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14026E180 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1418C5140 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14027CD50 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x14023B130 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141566F50 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140239590 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x14025EE60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141D0BA00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1411A7840 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x14027BC90 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141DC65C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14222C1E0 | 无名 sub_（断言站点/串定位） 断言站点 application.cpp:828 |
| 0x141689F60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14156CE80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14198EBA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141DC5150 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140D2ED90 | 无名 sub_（断言站点/串定位） 断言站点 relation.h:177 |
| 0x141CC9EA0 | 无名 sub_（断言站点/串定位） 断言站点 gridbox.h:654 |
| 0x1424C9360 | 无名 sub_（断言站点/串定位） 断言站点 log.cpp:180 |
| 0x141DB5790 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14023FE70 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140266170 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141B4B6A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14187CDA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14150BC30 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141175060 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B36830 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14113B700 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1402842E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x14187B270 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14105C2B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141A12990 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140216AB0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1419E0D00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1418DD7C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141E514D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1416D2780 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1414A47A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B2D690 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1415AB570 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14020FC80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14028C2E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140BC7880 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1401FF330 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141E834B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141E8DA90 | 无名 sub_（断言站点/串定位） 断言站点 industrial_org_ui_context.cpp:295 |
| 0x141199BF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1415DA300 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1415B6A40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141520730 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1402313A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141F7A5F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1414AE940 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140B1B870 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141CB0A10 | 无名 sub_（断言站点/串定位） 断言站点 pdxspan.h:77 |
| 0x140B2BAB0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141DE4A80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141129D60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1416800E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140DE3F00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14179C160 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141C6FC10 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140D3B170 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141ECC1C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140C6AE20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14023B8A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1402982E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1410641E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14222A4C0 | 无名 sub_（断言站点/串定位） 断言站点 systemsettings.cpp:273 |
| 0x141ECC740 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14168CAA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141475B30 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14179FA80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1416F7870 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140259740 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141C59850 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141C07FB0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1418C92E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140283350 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1418C6370 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B02230 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1411A83A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140FE6150 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1423DDB60 | 无名 sub_（断言站点/串定位） 断言站点 pdx_cloudstorage_steam.cpp:351 |
| 0x141F14AE0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140BF24B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141BD5780 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141C23DC0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1406517E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x142018120 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC6630 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1415F5030 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1415F9C70 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141194E20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1411398B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14124CDC0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1414C5290 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1411391C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140EF0B20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140BBB360 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1140 |
| 0x141CD5B30 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x142015C20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14143B0D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1424DEF10 | 无名 sub_（断言站点/串定位） 断言站点 virtualfilesystem.cpp:258 |
| 0x14121FBF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1412B9050 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141EB8FC0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141B14CE0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1410DFEF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x1419AD5C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140260EE0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140230860 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141DCA150 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140735D00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1410E01E0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140DB7DF0 | 无名 sub_（断言站点/串定位） 断言站点 oduction_bonus.h:53 |
| 0x14179C770 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140676FE0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141C83580 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140736560 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B104F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B119A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141861C70 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14065F150 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1402503C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141767FF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140C2E0A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1415A74A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141575230 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1418DEC10 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1424F04F0 | 无名 sub_（断言站点/串定位） 断言站点 weightedrandom.cpp:79 |
| 0x14028E250 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141D224F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141083220 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141C24F40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140BF7270 | 无名 sub_（断言站点/串定位） 断言站点 ordersgroup.cpp:579 |
| 0x141476B30 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1413816D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140287C20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140CC4DA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x14128B080 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD35B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC1720 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCD790 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141420FF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x141457780 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B04C30 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC4990 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140E94100 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141682950 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140F33320 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140C865D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC0320 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC0920 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC0D20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC0F20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC3940 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC4190 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC4390 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC5630 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC5C30 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC2540 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC3340 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC5030 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC1320 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC1B40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC2D40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC3D40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC6030 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC6430 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD0D70 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD33C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD5450 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD5A60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD6070 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCEB70 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCFAB0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD0050 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD0230 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD0610 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD1140 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD2500 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD4590 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD4970 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC7CA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC8300 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC8520 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC8DA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC9400 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCBD90 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCBFB0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCC750 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCCCF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCD350 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCDDF0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC7860 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC8960 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCAA20 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCB080 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCB730 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCD9B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC98B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CC9F80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCA3C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCAC40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCE1F0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CCE7A0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD1900 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD3F60 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD5270 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140CD39C0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140B04A10 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1418C2E80 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x140E1CBA0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1418EA490 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141E70850 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141370FD0 | 无名 sub_（断言站点/串定位） 断言站点 logistics.cpp:1158 |
| 0x141999F00 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1116 |
| 0x140E948B0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141A058D0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x141F28330 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1125 |
| 0x1401B7A40 | CGameState::DoCountryHourlyUpdates 的 oneAPI 并行封装 反编译 delegating lambda 名含 `DoCountryHourlyUpdates_CGameState`、`CPdxArray<CCountry*>`、`pattern_walk1`；tbb::iso… |
| 0x140E23430 | 无名 sub_（断言站点/串定位） 断言站点 strategicregion.cpp:432 |
| 0x142096480 | 无名 sub_（断言站点/串定位） 断言站点 particle_editor.cpp:129 |
| 0x141047CF0 | 无名 sub_（断言站点/串定位） 断言站点 orderinstance.cpp:2446 |
| 0x142508C10 | 无名 sub_（断言站点/串定位） 断言站点 pdx_pinned_array.h:170 |
| 0x1423C1D10 | 无名 sub_（断言站点/串定位） 断言站点 pdx_browser.cpp:77 |
| 0x141A957B0 | 无名 sub_（断言站点/串定位） 断言站点 industrial_org_text.cpp:72 |
| 0x14054A140 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.h:1126 |
| 0x14226AB10 | 无名 sub_（断言站点/串定位） 断言站点 oos_checks.cpp:146 |
| 0x140F3BA20 | 无名 sub_（断言站点/串定位） 断言站点 gradientbordermanager.cpp:2409 |
| 0x141515DA0 | 无名 sub_（断言站点/串定位） 断言站点 ntract_delivery_state.h:30 |
| 0x1401D1E70 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.cpp:1724 |
| 0x1401D2CD0 | 无名 sub_（断言站点/串定位） 串字面量 "Trying to initialize gamestate twice" |
| 0x141A3DFC0 | 无名 sub_（断言站点/串定位） 断言站点 concentration.cpp:672 |
| 0x140E88430 | 无名 sub_（断言站点/串定位） 断言站点 railway_gun.cpp:725 |
| 0x142590C40 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.cpp:1498 |
| 0x142590AE0 | 无名 sub_（断言站点/串定位） 断言站点 gamestate.cpp:1587 |
| 0x140B67810 | 无名 sub_（断言站点/串定位） 断言站点 ingameinterfacehandler.cpp:2371 |
| 0x140B678D0 | 无名 sub_（断言站点/串定位） 断言站点 ingameinterfacehandler.cpp:2381 |
| 0x140BE26C0 | 子表条件批量置位 sub_14152ED50 命中置 v6+1065=1 推定 |
| 0x14193CDF0 | 无名 sub_（断言站点/串定位） 断言站点 stat_helper.cpp:157 |
| 0x140B6D270 | 无名 sub_（断言站点/串定位） 断言站点 ingameinterfacehandler.cpp:2391 |
| 0x140B6D3B0 | 无名 sub_（断言站点/串定位） 断言站点 ingameinterfacehandler.cpp:2421 |
| 0x1406414F0 | 无名 sub_（断言站点/串定位） 断言站点 industrial_org_trait_bonus.cpp:182 |
| 0x141CF7DA0 | 门控回调执行 a1+1400/1404 门 + a1+1408 回调 + sub_1423032B0 推定 |
| 0x1425A1FA0 | 无名 sub_（断言站点/串定位） 断言站点 historylogger.cpp:172 |
| 0x140D7EFE0 | 无名 sub_（断言站点/串定位） 断言站点 doctrine_system.cpp:80 |
| 0x14232B800 | 无名 sub_（断言站点/串定位） 断言站点 curvegraph.cpp:86 |
| 0x140BF62D0 | 无名 sub_（断言站点/串定位） 断言站点 ordersgroup.cpp:2760 |
| 0x141A960D0 | 无名 sub_（断言站点/串定位） 断言站点 purchase_contract_text.cpp:47 |
| 0x14194B430 | 无名 sub_（断言站点/串定位） 断言站点 move_priority.cpp:39 |
| 0x140B6E330 | 无名 sub_（断言站点/串定位） 断言站点 ingameinterfacehandler.cpp:1828 |
| 0x142013C00 | 无名 sub_（断言站点/串定位） 断言站点 ion_support_objective.cpp:36 |
| 0x1406B0420 | 无名 sub_（断言站点/串定位） 断言站点 career_profile_ribbon.cpp:71 |
| 0x142507FB0 | 无名 sub_（断言站点/串定位） 断言站点 pdx_thread_tbb.cpp:91 |
| 0x141A96AB0 | 无名 sub_（断言站点/串定位） 断言站点 localization_environment_text.cpp:88 |
| 0x1409D0070 | 无名 sub_（断言站点/串定位） 断言站点 modifier.h:1191 |
| 0x140C0CE80 | 无名 sub_（断言站点/串定位） 断言站点 modifier.h:1191 |
| 0x142011290 | 无名 sub_（断言站点/串定位） 断言站点 fense_objective.cpp:38 |
| 0x1406AC0C0 | 无名 sub_（断言站点/串定位） 断言站点 career_profile_medal.cpp:128 |
| 0x1406AC000 | 无名 sub_（断言站点/串定位） 断言站点 career_profile_medal.cpp:147 |
| 0x141054340 | 无名 sub_（断言站点/串定位） 断言站点 array2d.h:154 |
| 0x1410543E0 | 无名 sub_（断言站点/串定位） 断言站点 array2d.h:165 |
| 0x142092F40 | 无名 sub_（断言站点/串定位） 断言站点 particle_editor.cpp:144 |
| 0x1413BF1C0 | 无名 sub_（断言站点/串定位） 断言站点 iption_utils.cpp:215 |
| 0x1417840D0 | 按 key 选择并置位掩码 a1+58240 查找 + a1+22836=1<<idx + sub_141492AA0 |
| 0x140E8D810 | 无名 sub_（断言站点/串定位） 断言站点 railway_gun.cpp:1333 |
| 0x142402B60 | 无名 sub_（断言站点/串定位） 断言站点 pdx_ugc.cpp:45 |
| 0x140BBCE30 | 无名 sub_（断言站点/串定位） 断言站点 id_counter_store.cpp:123 |
| 0x141D12DD0 | 无名 sub_（断言站点/串定位） 断言站点 skill_tree.cpp:30 |
| 0x1414E5190 | 无名 sub_（断言站点/串定位） 断言站点 career_profile_types.cpp:29 |
| 0x1426EA470 | 无名 sub_（断言站点/串定位） 断言站点 savegamehelper.cpp:521 |
| 0x14146D540 | 无名 sub_（断言站点/串定位） 断言站点 gridbox.h:654 |
| 0x1425A1EE0 | 无名 sub_（断言站点/串定位） 断言站点 historylogger.cpp:594 |
| 0x141B72C70 | 无名 sub_（断言站点/串定位） 断言站点 nudgestacks.h:85 |
| 0x1425A1A40 | 无名 sub_（断言站点/串定位） 断言站点 historylogger.cpp:1357 |
| 0x1410300E0 | 无名 sub_（断言站点/串定位） 断言站点 orderinstance.cpp:424 |
| 0x142401D70 | 无名 sub_（断言站点/串定位） 断言站点 pdx_store.cpp:38 |
| 0x1422686D0 | 无名 sub_（断言站点/串定位） 断言站点 pdxkeys.cpp:165 |
| 0x142276040 | 无名 sub_（断言站点/串定位） 断言站点 pdxmeshobject.cpp:782 |
| 0x142277500 | 无名 sub_（断言站点/串定位） 断言站点 pdxmeshobject.cpp:776 |
| 0x1425F2360 | 无名 sub_（断言站点/串定位） 断言站点 career_profile.cpp:2318 |
| 0x1425A1940 | 无名 sub_（断言站点/串定位） 断言站点 historylogger.cpp:1315 |
| 0x14139F7D0 | 无名 sub_（断言站点/串定位） 断言站点 pdx_pinned_array.h:170 |
| 0x1426EA150 | 无名 sub_（断言站点/串定位） 断言站点 savegamehelper.cpp:576 |
| 0x1419C8F00 | 无名 sub_（断言站点/串定位） 断言站点 tutorial.cpp:112 |
| 0x14145A9B0 | 无名 sub_（断言站点/串定位） 断言站点 cic_bank.cpp:40 |
| 0x1423DC270 | 无名 sub_（断言站点/串定位） 断言站点 pdx_cloudstorage.cpp:41 |
| 0x1425A1840 | 无名 sub_（断言站点/串定位） 断言站点 historylogger.cpp:1220 |
| 0x1426E6D50 | 无名 sub_（断言站点/串定位） 断言站点 dlc.cpp:1394 |
| 0x140AE9400 | 脚本数值定义求值 sub_14055AB90(100000) + sub_140C15D30 推定 |
| 0x141584FF0 | 条件性完整刷新 a1[3910] 门 + sub_141C57EE0 分路 8 子例程 推定 |
| 0x140F67DB0 | 条件检查返回原因码 6/7 a1+2604 id 对 + sub_140C53790/sub_140C57400 推定 |

#### 4.1.35 CGameState 派发族与门控函数补遗（246 函）

| VA | 语义/证据 |
|---|---|
| 0x1420C3820 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1424EB010 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140F4A200 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1418E4FF0 | 无名 sub_（调用图定位） 调用图传播: 12/22 锚点投 §4.1 |
| 0x1420DFBF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420DB690 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A57750 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401AB910 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142102820 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14207F7A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1412F56F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140132C30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140134530 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140510F00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140507D80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140508080 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140510C30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14050D240 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1409EEC10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211B7E0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x1424CA070 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140534430 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1409FB010 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1418E55B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1410551B0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x1405417D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1417A7120 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140AF0680 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1419C5F30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140E1A1A0 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.1 |
| 0x140D80890 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.1 |
| 0x14187AD00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141684EE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142153E90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142122260 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211ABD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141324FF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141B94170 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140E53490 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1424D9AD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14154C360 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420FDF70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14022C390 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14168C060 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420E8330 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14109CEC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141962E80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142122040 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420E8450 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1409F1C30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141668AE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1422C60C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140FE5250 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142528FF4 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420CE290 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x14248C660 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140B39E40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1411E6D40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140EAA4C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1406308F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1419A73B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420C4F50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1416DDBD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140CBB8E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141055440 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x1420C4E60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A897C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140201A80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140B3A110 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140CBB7E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1423A68B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A50D00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141AF2A70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140525F10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141B94B20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1403A6110 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420D7500 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14253E7FC | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142537BEC | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211CD30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140F095F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14012A480 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140713340 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140CCCC40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1421287C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7F810 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140BE2620 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1422A9630 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141DF8920 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140B67CA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401EDD90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14043D7F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140523460 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1405235C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1405239E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142104D30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140630850 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141939B20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1414DF8D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14202DBA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14212E600 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140DFD410 | 经 gamestate 索引的对象状态判定 sub_140BB5490(a1) 做 id→索引 → gs+3976 指针表项 → 查 v9+744/+73、v9+608 后回写 *(a1+8) |
| 0x140C91D70 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.1 |
| 0x1401F0110 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141400B80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1413259D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401A83D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140550BF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14105BCD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211DAB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211BC70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1409C8FE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14223E250 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141233C60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1406A4FA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A8F1A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142098370 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401A8340 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401EE450 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A8F240 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D139E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7FEB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140E86AF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140F209F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1411D62C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1419643F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420982D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142352520 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14043D8A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140523510 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140523A90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140526DB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1403B8CF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1406A4F10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7FF50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7FFE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14043CF80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1407125E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D06970 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D06A00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D06A90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14133BF60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1416538F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14011AD20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A4FF20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420CE1E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140523670 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1417B17A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141CF7D30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14212DFB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140675B60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141535030 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141F22890 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1411EF990 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A44AB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401F6C80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140CCC970 | 无名 sub_（调用图定位） 调用图传播: 2/4 锚点投 §4.1 |
| 0x1416E5480 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1422731D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141E39380 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x142273060 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141C2B7D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1410A2280 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420D3310 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1422730E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140681DE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141969330 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14062C990 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E14D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E1650 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E17D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141C17D60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E12D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E1450 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E1550 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E15D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E16D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E1750 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1414A5C60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1414A5CE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1414A5D60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1416AE550 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402E13D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1424F0930 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420D75D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420D7450 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14128BB50 | 计算并打包发送 sub_140A60CA0(qword_143339D28) + sub_14128B9F0 推定 |
| 0x142393730 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14209CD50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141AECB80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140E16B10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140EA59C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14208E380 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14032B870 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140E16C90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7F4A0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x142127EA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420EFC00 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.1 |
| 0x140EF8330 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141296090 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140526400 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7D4D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140228B90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1401EC8F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141515920 | 完成度比率计算 (a2+480−a2+560)/sub_1413BADC0 ×1e-5 推定 |
| 0x1406CD570 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7D1C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7D250 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1402CCAD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D7D560 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14062CA30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140638C90 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140E554A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14139FB40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14043DED0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140526390 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140526470 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140526550 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1405265C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141FFA200 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14102AED0 | 条件写入并通知 sub_140BB48F0 + sub_14104B3A0 |
| 0x140DBE020 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420C1430 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141CD7860 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14240BEC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141C944A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140C9FC40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140B69110 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141E23360 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141012E80 | fixed 数值计算（含百分比修正） 100000*a3 + sub_140F78500(a2+144)/100000 推定 |
| 0x141442740 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141442AC0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141B77C50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420E5F60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14212F6C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1423DF770 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1420DFA00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14236DF70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1405226D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211E670 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A8CB00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14014FDA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140A8C150 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1411A57E0 | 数组移除并通知 sub_1411A5880 移除 + sub_140BB4390 通知 |
| 0x1413BCA60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141A37BD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |

#### 4.1.36 CGameState 派发族与门控函数补遗（39 函）

| VA | 语义/证据 |
|---|---|
| 0x14104F100 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.1 |
| 0x141AEBFC0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.1 |
| 0x14211B1E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141050540 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.1 |
| 0x141050A60 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.1 |
| 0x142093DD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140D80BD0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x140D7E130 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x1403BA4C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1411E4EA0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.1 |
| 0x1413CF260 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211A670 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1425274D8 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140DBE2B0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x1420C9460 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14104EA00 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x142157340 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1419B2D10 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211BD80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14248C740 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1409FA690 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140687E30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141051A90 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.1 |
| 0x141EF6690 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x141297D00 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x141CD6980 | UI 窗口链式更新/关闭 a1+14424 门 + sub_141F49870/45C30/3BEB0 推定 |
| 0x1418E69D0 | 无名 sub_（调用图定位） 调用图传播: 3/3 锚点投 §4.1 |
| 0x1411DC580 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1409FAA30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x141B94EA0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x140129B00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14053D330 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1417A55A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1418E4F00 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x141B93EA0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.1 |
| 0x141F45EE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14230F430 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14211A960 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x14102AF70 | 无名 sub_（调用图定位） 调用图传播: 2/3 锚点投 §4.1 |

#### 4.1.37 CGameState 派发族与门控函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x14112F1C0 | （无名） 调 sub_140BB48F0/sub_140BB52F0（gamestate id→索引） |
| 0x1416CC680 | （无名） 无领域线索（仅自族调用 sub_1416CC680 + 浮点比较） |

#### 4.1.38 CGameState 派发族与门控函数补遗（10 函）

| VA | 语义/证据 |
|---|---|
| 0x1413F3B20 | 无名 sub_（人工读体裁定） 调 sub_140BB48F0（gamestate 辅助族，邻 sub_140BB5490）+ sub_1406CF810，遍历 v4+96 项表（计数 v4+108）收集入向量 |
| 0x1412A0AF0 | 无名 sub_（人工读体裁定） 遍历 a1+200（计数 a1+212）累加 *(v7+440)；sub_140A6AF60→sub_140BB48F0（gamestate 辅助族）+ sub_14055E360(v9+1464) + 1e5 定点换算 |
| 0x1414349F0 | 无名 sub_（人工读体裁定） 双 sub_140BB5490（gamestate id→索引）取 a1/a2 索引 + sub_140BB47D0 + 阈值 qword_143333D98<=100000 |
| 0x1406D5CC0 | 无名 sub_（人工读体裁定） 重置/更新序列：sub_1406CF250→sub_1410E9E60→sub_1406DADE0→sub_1406DD0C0→sub_1406FF1F0(a1,8)→sub_140D42BD0(*(a1+3976))→sub_140E6C810(*(a1+3944))，收尾用 s… |
| 0x141DA9B20 | 无名 sub_（人工读体裁定） 取 qword_14332F698+1288 的 vtable+40/+56 两值，对 a2 做 /200000 缩放定点换算（带 1e5 整除对齐回正） |
| 0x1417C2AB0 | 无名 sub_（人工读体裁定） 选中态判定：查 a1+10616→+184 下标对应的 +64 数组项是否为自身，是则记 qword_14332F698+1280 vtable+192 结果到 a1+14976 并置 a1+14973 |
| 0x140D3F190 | 无名 sub_（人工读体裁定） 国家集合判定：sub_140BB5490（id→索引）+ 两次 sub_140BB48F0 解析，交叉查 a1+152 数组与 v11+176 / v8+152 两容器 |
| 0x1409D81B0 | 无名 sub_（人工读体裁定） 百分比加总：遍历 v5+544 容器，每项取 (v8+66) 整数与 sub_1414B97D0(v8+480) 值，按 1e10/1e5 定点商累加进 *a2 |
| 0x142122800 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.1 |
| 0x1418C3910 | 无名 sub_（人工读体裁定） 引用解析注册：a1+1424 对经 sub_14221F310 校验后 sub_140CE7410 转换，取 qword_14332F6A0+161 双值写入 +1336 表 |

#### 4.1.39 CGameState 派发族与门控函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x142200490 | 累加位移到 a1+16/+20，每步写 14B 记录（x/y word+标志）到 a1+40 数组，首项直写否则 sub_142202FE0 累加位移到 a1+16/+20，每步写 14B 记录（x/y word+标志）到 a1+40 数组，首项直写否则 sub_142202FE0 推定 |
| 0x141AC93C0 | byte_14332EC69 脚本旗 + qword_14332F698 vtable+48/+56 判定分脚本/默认两路求值 byte_14332EC69 脚本旗 + qword_14332F698 vtable+48/+56 判定分脚本/默认两路求值 推定 |
| 0x141CD3D50 | a1+14470 门 a1+14470 门：推进 a1+14464 索引（a1+14292 上界、a1+14280 数组）+ vtable+32 通知 + 清双标志 推定 |
| 0x1418BD500 | 管理器查找取值 管理器查找取值：qword_14332F698 vtable+120 → sub_140B541E0 按 id，失败取全局默认 |
| 0x14100C9C0 | 定点加法钳位 定点加法钳位：sub_141010360 查找后 +8 累加，钳位 ±92233720200000 - |

#### 4.1.40 CGameState 派发族与门控函数补遗（12 函）

| VA | 语义/证据 |
|---|---|
| 0x1414E3D60 | 无名 sub_（人工读体裁定） 调 sub_140BB5490（gamestate id→索引）+ sub_140BB48F0，按 id 查表 |
| 0x141906440 | 无名 sub_（人工读体裁定） 状态判定（a1+184 掩码 0xFFFFFFFB 早退 + sub_140E47890(a1+144) + gamestate 族 sub_140BB52F0 + 浮点输出） |
| 0x140CAEC50 | 无名 sub_（人工读体裁定） 双 gamestate 索引（sub_140BB48F0 + sub_140BB5490 + sub_140D23780） |
| 0x141179AC0 | 无名 sub_（人工读体裁定） gamestate 族查表（sub_140BB4390 + sub_1406CF4E0/sub_140D40F30） |
| 0x141458650 | 无名 sub_（人工读体裁定） 双 gamestate 索引（sub_140BB48F0 + sub_140BB5490 + sub_1409DDA40） |
| 0x140C864D0 | 无名 sub_（人工读体裁定） 三 gamestate 索引（sub_140BB52F0 + sub_140BB48F0 + sub_140BB5490） |
| 0x140E7E850 | 无名 sub_（人工读体裁定） 双 gamestate 索引（sub_140BB48F0 + sub_140BB5490 + sub_140700570） |
| 0x1406F9B40 | 无名 sub_（人工读体裁定） 双 gamestate 索引（sub_140BB52F0 + sub_140BB5490 + sub_140D23780） |
| 0x1409DB340 | 无名 sub_（人工读体裁定） gamestate 族查表（sub_140BB52F0 + sub_140319D60/sub_141175A30） |
| 0x140BDA760 | 无名 sub_（人工读体裁定） gamestate 族查表（sub_140BB48F0 + sub_140BB5440 + sub_1406EC3E0） |
| 0x140D3F100 | 无名 sub_（人工读体裁定） 双 gamestate 索引（sub_140BB48F0 + sub_140BB5490 + sub_140700570） |
| 0x141A312B0 | 无名 sub_（人工读体裁定） 双 gamestate 索引（sub_140BB48F0 + sub_140BB5490 + sub_140700570） |

#### 4.1.41 CGameState 派发族与门控函数补遗（20 函）

| VA | 语义/证据 |
|---|---|
| 0x141CE7540 | 管理器委托 管理器委托：a1+1368 对象 vtable+136 取值 + sub_1422509F0 校验 + vtable+880 两次（sub_140D9F5D0/sub_140DA3A40 前后处理） 推定 |
| 0x14192DB60 | 双分支构造 双分支构造：a2+1008 对象（+1228 旗 / +1216 数组）或 a2+1088 回退，OWORD 拷出 a1，sub_14192DC30 处理 推定 |
| 0x142418B30 | 结构构造 结构构造：malloc 0x58 + 多 token 解析（sub_142427130/sub_142425FC0）+ OWORD 拷贝 推定 |
| 0x141773790 | 对象重绑 对象重绑：旧对象释放（+136 观察者链清理 + vtable+552）+ a2 vtable+104 新建 + +128 观察者注册 推定 |
| 0x141299E90 | 条件累加 条件累加：a1+8 数组（计数 a1+20）每元素 vtable+656 取值 + 三段条件加项（sub_141B3ACC0/AC90/A9B0） 推定 |
| 0x1421B5520 | 位旗取值 位旗属性取值：a2+10 位 (1<<a4) 已置则返 0 + a1+32 表 296+8*a4 索引经 sub_1421B78F0 校验 推定 |
| 0x140D6B590 | 求和聚合 求和聚合：a1+840 数组（计数 a1+852）每元素 *(元素+136) 经 sub_14143E4A0 查 +24 值累加 推定 |
| 0x140CF6730 | id 匹配 国家 id 匹配：vtable+8 取 id → sub_140BB48F0 索引，a1[18] 链表遍历逐元素 vtable+8 + sub_140BB5490 比对 |
| 0x1418F7190 | 哈希取值 哈希查 a1+136（sub_14221F310）→ 偏移 -16 对象 vtable+88==2 类型校验 + sub_140CE7410 取值 推定 |
| 0x140F7B1A0 | 存在性判定 存在性判定：a1+48 对象 +160/>0 短路 + +104 数组（计数 +116）逐项 sub_140F860E0(a1, 元素+204) 校验 推定 |
| 0x1414B4CC0 | 进度计算 进度计算：vtable+112 取上限 v6 + a1+40 /100000 定点 → (v4/100000)*(a1+72-1) 级别索引 推定 |
| 0x14130B640 | 定点变换 定点变换：vtable+32(a2+104, 58, a3) 取值 + 100000 定点归一 + 魔数 0x29F16B11C6D1E109 缩放 推定 |
| 0x140B926C0 | 父级挂载 父对象设置：a1+232 挂 a2 + 子数组逐项 vtable+48(元素, a1) 传播（a2+84 位 2 短路） 推定 |
| 0x140C1A780 | 条件判定 国家条件判定：a1+3912 哈希查 + sub_140FA4820 校验 + a1+3528 数组（计数 +3540）扫描累加 |
| 0x141989FE0 | 比例计算 双向比例计算：正反两向 sub_141989C60 → 100000 * v11 / max(v10, 10000) 定点比 + 1000000 上限 推定 |
| 0x142277050 | 索引扫描 索引扫描：sub_1423AFED0(*(a1+112)) 类型判定 + a1+88+216 数组（计数 +228）逐项 + 10 行 推定 |
| 0x140A3DBA0 | 层级解析 层级值解析：vtable+144 直接判定（a2+8 → a1+16），否则 a1+32 链表逐项回溯 + 11 行 推定 |
| 0x140C04DA0 | 复合条件判定 复合条件判定：a1[2] 门控 + sub_1401AEB50(57) 参数校验 + vtable+64 取上下文 + v2+192 链 + sub_140BEF2A0/BEF990 双查 推定 |
| 0x140EF6FD0 | 归属判定 gamestate 归属判定：sub_140BB48F0(a1+72) 解析 + +360 自引用判定 + a1+272 回退分支 + 13 行 |
| 0x140EF8260 | 旗位更新 旗位更新：a2+164 偏移定位字节 + &0x18 掩码 + sub_140E7DD90(a2, a1+24, a1+36) 判定后置位/清位 + 7 行 推定 |

#### 4.1.42 CGameState 派发族与门控函数补遗（1 函）

| VA | 语义/证据 |
|---|---|
| 0x141C831C0 | 变量设置 strcpy "name" + **(a1+16) 容器 + 40 字节缓冲：脚本变量设置 |

#### 4.1.43 CGameState 派发族与门控函数补遗（3 函）

| VA | 语义/证据 |
|---|---|
| 0x141E9C2F0 | gamestate过滤 gamestate 查找链（sub_140BB48F0→sub_1406ECF70→sub_1402D1550）+ sub_14072E350 位掩码（& a3）过滤收集至 a1 向量 |
| 0x1410DBBD0 | gamestate判定 调 sub_140BB5490（gamestate id→索引）+ sub_140BB48F0 + tag 比较（sub_140BB52F0），遍历 a1+16 数组判定参战关系 |
| 0x141372B50 | 日期计算 日期计算：sub_141372C20/E80/16B0 链 + *v6+v10 与 92233720200000 日期哨兵比较 |

#### 4.1.44 CGameState 派发族与门控函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x140F9AB00 | 未决窗口函数 · 缓存数组+gamestate 回退查找 两路缓存数组（+552/+564、+528/+540）查 dword(a2+8)，未命中回退 sub_140BB48F0(gamestate 包装)+sub_1406CF810+sub_140FF9D60 |
| 0x1419E0080 | 未决窗口函数 · gamestate 域查询链 sub_140BB48F0(gamestate 包装) → sub_1406F98C0 → sub_1411FB040 → qword_143331500 上界比较 |
| 0x1418344F0 | 未决窗口函数 · gamestate 包装链+范围计算 *(a1+48) vt+160 取数组，>0 时经 sub_140BB48F0(gamestate 包装)/sub_1406CF7F0/sub_140F9F9F0/sub_140FDCB00 链算范围，byte(a1+184)=0 |
| 0x140BA7C00 | 未决窗口函数 · 共享对象引用计数比较（+2720 标识） v3=*(a2+2720)；计数 a1+80 数组中引用同对象项数，与 sub_14072DE90(v3) 比较 |
