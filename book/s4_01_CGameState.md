> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.1 CGameState (游戏状态单例)

**获取**: `gs = *(BASE + 0X332F260)` (单例指针, 无 vtable 校验必要)。派生类 CCurrentGameState 见 §4.1.2。

#### 4.1.1 管理器字段 (+152..+2232; gs+0..+239 = CPersistent 基类, ctor sub_140BC0880, 详 §4.2)

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +152 | hours | 日期#0 **载入快照** | CGameDate 尾 {hours@152, vt2@160}; CPersistent 基类成员。**只有读档路径写, 之后不随时钟推进** (新建局停在 ctor 哨兵 43808760; 当前日期在 +1128) | §4.2 |
| +168 | 容器 24B | player_countries | {d@168, cap@176, c@180, alloc@184}; 元素 160B, tag@元素+112 | writer 头块 13671 |
| +192 | — | 位域旗 | bit0 = checksum 门 / bit3 = tutorial; 前有垫 | §4.2 |
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
| +1193..+1247 | — | 日期#2 尾 | = CGameDate#2 vt2@1200 + speed u32@1212 (键 110; 探针=4) + u8@1216 + to_be_deleted {d@1224, cap@1232, c@1236, alloc@1240} (块 19332 + assert; 元素 8B 双 u32) + CPeaceConferenceManager 头@1248 | |
| +1248 | CPeaceConferenceManager (内嵌) | 和会管理器 | | §4.10.26; vt 0X2720E48 (RTTI+探针); 谍报网在国家侧 (§4.11) |
| +1249..+1311 | — | 和会管理器体 | = {vt@1248, q@1256, q@1264, off@1272} (块 12499) + MSVC 串@1280..1311 (SSO, 探针空串; 疑会话名, 语义未决) | |
| +1312 | u32 | playthrough 当前 id | 键 10805; 探针 121 | §4.2 |
| +1316 | u32 | playthrough 备用 id | | |
| +1320 | u32 | playthrough tag | 键 13913; 探针 9 | §4.2 |
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
| +1688 | CNavyManager* | 海军/生产项目/部署 HQ | | §4.16 / §4.8 / §4.9; 别名定名 (vt 0X29732E0, RTTI 无名); 元素 CStrategicNavy (vt 0X2973260, RTTI) |
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

#### 4.1.2 CCurrentGameState 尾段 (+2536..+2618)

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


#### 4.1.3 未决清单

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
| pdx 空位群 已名 12 项 | +760 region→country 表 / +880 `_CountryControllersEnable` / +904 控制器计数 / +1352 fired_event_names 实例数组 / +1400 指针集 / +1472 海战主数组 / +1648 **`MP_locked_countries`** / +1752 scope→saved event target / +2240 tag 工作列表 / +2384 指针向量 / +2440 **`_CountriesForOriginalTags`** / +2464 战略空军表 | 逐个 ctor/消费者实证 |
| gs+2352 | **负定案: gs 语境下查无此槽** — 基类 ctor 与 gs dtor 均不触及, 全部命中为同偏移异类 (旧登记疑误) | 基类 ctor + gs dtor 全扫 |
| CPersistent+216 (= gs+216) | 未决 — 仅基类 ctor 初始化, 无消费者 | — |
| gs+1280 串 | 未决 — CPeaceConferenceManager 内 SSO, 无写入点 | — |

#### 4.1.4 全局顶层块补录 (sv2_sec_global_tails 审计)

| 块 | 挂载 | 布局要点 |
|---|---|---|
| flags | CFlagStore *(gs+600) | 全局旗标 store (布局见 sv2_sec_global_tails 段注) |
| pending_events | {d@gs+1376, c@gs+1388} | 元素 56B |
| difficulty_settings | {d@gs+1064, c@gs+1076} | 门 = multiplier@+208 > 0; writer 0X1409B9490 |
| game_rules | *(gs+1088) CGameRulesInstance | token 对向量 |
| to_be_deleted | {d@gs+1224, c@gs+1236} | 元素 8B = {type u32@+0, id u32@+4}; 键 11=id 写第二 u32 / 225=type 写第一 u32; 无条目门全队列发 (writer 元 sub_142220180); 条目类型 61 = 国家族 (id 对先例 CResourceOrigin spotter, §4.3 rs 行) = 死亡国家 id 残留 |
