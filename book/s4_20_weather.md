

### 4.20 天气族 (CWeatherManager → 省天气 / 区域天气)

#### 4.20.1 CWeatherManager (管理器, ≥1424B)

mgr = *(gs + 1672); vtable RVA 0X2977810; 尺寸 ≥1424。
「weather」顶层键 = CWeatherManager 整块多态序列化 (gamestate writer
`ADEC0(a2, 0x2F08=12040 weather, *(gs+1672))`; gs+1672 持 CWeatherManager 指针)。
writer 0X140F22A70 / loader 0X140F1F780 (12066/12067/10647 读后即弃)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +16 | 容器 24B | provinces | | {data@+16, cap@+24 (1.5x), count@+28, alloc@+32}; 元素内联 384B = 0x180 (SWeatherPerProvince, §4.20.2) |
| +40 | 容器 24B | 含活跃自定义修正的省份指针表 | | {data@+40, cap@+48, count@+52, alloc@+56}; 8B 条 = SWeatherPerProvince*; vt slot8: custom_modifiers 有 param>0 者入表, 随后 +840=1 并调 HourlyUpdate |
| +64 | 容器 24B | regions | | {data@+64, cap@+72, count@+76, alloc@+80}; 元素内联 352B = 0x160 (SWeatherPerRegion, §4.20.3) |
| +88 | uint32 | current_province | | 轮转游标 (DoUpdatePasses 自增回绕); 键 0x2F22; loader 弃读 |
| +92 | uint32 | current_region | | 轮转游标; 键 0x2F23; loader 弃读 |
| +96 | 内嵌 | terrain_modifiers[9] | | +96..+311: 按天气现象枚举 (0..8) 的容器数组, 槽 = 24B {data, cap@+8, count@+12, alloc@+16}; 条 = CWeatherTerrainModifier {vt@0, terrain id u32@+8, value i64 fixed@+16}; 消费: 省温度更新以省 +44 terrain id 查 slot1 得温度增量, mud 掷判查 slot6 |
| +312 | fixed | temperature_variation | | 随机游走增量 `2*(+312*(rand%100000-50000)/1e5)` |
| +320 | fixed | max_temperature_change | | +368 累积器钳位 ±此值 |
| +328 | fixed | temperature_neighbor_smoothing | | |
| +336 | fixed | temperature_change_neighbor_smoothing | | |
| +344 | fixed×2 | weather_extreme_cold | | 区间 {lo@+344, hi@+352}; post-load 对省温判带选 modifier; GUI tooltip 读四带 |
| +360 | fixed×2 | weather_very_cold | | 区间 {+360/+368} |
| +376 | fixed×2 | weather_very_hot | | 区间 {+376/+384} |
| +392 | fixed×2 | weather_extreme_hot | | 区间 {+392/+400} |
| +408 | fixed | water_gain_on_rain_light | | water 更新 `prov+56 += mgr+408` |
| +416 | fixed | water_gain_on_rain_heavy | | |
| +424 | fixed | water_gain_max | | 钳位 |
| +432 | fixed | water_gain_min | | mud 判据 `prov+56 < mgr+432` |
| +440 | fixed | water_gain_to_cm | | GUI tooltip 读 |
| +448 | fixed×2 | water_dryout_temperature | | 区间 {+448/+456} |
| +464 | fixed×2 | water_dryout_multiplier | | 区间 {+464/+472} |
| +480 | fixed | min_temperature | | mud 生成温度下限: `prov+352 <= mgr+480` 不生泥 |
| +488 | fixed | snow_gain_on_snowing | | `prov+64 += mgr+488` |
| +496 | fixed | snow_gain_on_blizzard | | |
| +504 | fixed | snow_gain_max | | 雪视觉分母; post-load 雪总量钳位 |
| +512 | fixed | snow_gain_to_cm | | |
| +520 | fixed×2 | snow_melt_temperature | | 区间 {+520/+528} |
| +536 | fixed×2 | snow_melt_multiplier | | 区间 {+536/+544} |
| +552 | fixed×2 | snowing.temperature | | 区间 {+552/+560} |
| +568 | uint32 | snow_visual_min | | 雪视觉下限钳位 |
| +576 | fixed×2 | weather_ground_snow_medium | | 区间 {+576/+584}; post-load 选 ground-snow modifier |
| +592 | fixed×2 | weather_ground_snow_high | | 区间 {+592/+600} |
| +608 | fixed×2 | arctic_water_temperature | | 区间 {+608/+616}; ⚠ 解析器传参 min/max 槽位与常规相反 |
| +624 | fixed×2 | arctic_water_end_temperature | | 区间 {+624/+632} |
| +640 | fixed×2 | chance_increase.mud | | 区间 {+640/+648} |
| +656 | fixed×2 | duration.no_phenomenon | | 区间 {+656/+664} |
| +672 | fixed×2 | duration.rain_light | | 区间 {+672/+680} |
| +688 | fixed×2 | duration.rain_heavy | | 区间 {+688/+696} |
| +704 | fixed×2 | duration.snow | | 区间 {+704/+712} |
| +720 | fixed×2 | duration.blizzard | | 区间 {+720/+728} |
| +736 | fixed×2 | duration.sandstorm | | 区间 {+736/+744} |
| +752 | uint32 | provinces_per_update | | performance 块; 非初始化帧每帧处理数 |
| +756 | uint32 | regions_per_update | | |
| +760 | uint32 | init_run_passes | | = HourlyUpdate "nInitPasses" |
| +768 | fixed | texture_refresh_freq | | 雪泥贴图更新间隔阈 |
| +776 | uint32 | _nRandomSeed | | writer 键 10647 (seed 无符号, save=4131449602>2^31); loader 弃读 |
| +784 | u8 数组 | 每省雪视觉等级 | | 0-255, 省 id 索引; {data, cap@+792, count@+796, alloc@+800} |
| +808 | u8 数组 | 每省泥/视觉天气旗 | | 0/-1; {data, cap@+816, count@+820, alloc@+824} |
| +832 | double | 上次雪泥贴图更新时间戳 | | |
| +840 | uint8 | init-pending / 首小时旗 | | reset 置 1, 首轮 HourlyUpdate 尾清 0 |
| +841 | uint8 | _bDisabled | | "HourlyUpdate skipping (_bDisabled=%d)" |
| +842 | uint8 | 第二跳过旗 | | 与 +841 并联门控 |
| +848 | fixed×3 | 当前太阳方向单位向量 | | +848/+856/+864; fixed 1e5; +848 恒 0, 在 Y-Z 平面逐时旋转; 旋转公式与 DayNight 点积消费链全解; 定案 |
| +872 | fixed | 季节插值因子 (命名不可证) | | 计算定案 = 当前游戏日期在两至点/年界之间的插值百分比 (fixed 1e5 量纲; 0X140F15EB0 唯一计算, 另 3 处清零); **零读者定案** (全 dump 0 读点) → 未消费的计算残值 |
| +880 | 容器 24B | 每省 DayNight 数组 | | {data, cap@+888, count@+892, alloc@+896}; 条 816B: +0..+575 = 24 小时槽×24B{3 fixed}, DayNight fixed@+576, GmtOffset fixed@+584, +592/+600 qword, Hour u32@+608, prev DayNight@+616, 内嵌 CModifier@+624 |
| +904 | u8 缓冲 | 雪贴图前缓冲 | | (mapW/4)×(mapH/4); +920 后缓冲, 泥 +912/+928 (双缓冲) |
| +936 | 容器 24B | 脏天气瓦片表 | | u32 瓦片 id; {data, cap@+944, count@+948, alloc@+952} |
| +960 | u8 数组 | 每省脏旗 | | |
| +968 | 内嵌 | weather_effects[9] | | +968..+1399; 9×48B; u32@+12, u32@+36; 解析器 case 12654 经 SWeatherEffectsReader{vt, data=a1+968} |
| +1400 | 容器 24B | visual_mud_effects | | {data, cap@+1408, count@+1412, alloc@+1416}; 8B 条 = modifier 定义指针; 省更新判省 custom modifier ∈ 此表 → +312=1 |

#### 4.20.2 SWeatherPerProvince (384B, 省天气)

vt 0X2977770 (RTTI 真名); stride 384 = 0x180 内联; load handler vt slot4
0X140F20330 — mud/custom_modifiers 实载; province/temperature/snow/water/
temperature_offset 全部读后弃 → post-load 重算。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | province_id | | writer 键 10304; loader 弃读 |
| +16 | 容器 24B | 邻省表 | 不序列化 | vector\<SWeatherPerProvince*\> {data, cap@+24, count@+28, alloc@+32}; RTTI CPdxHybridInlineBufferAllocator\<SWeatherPerProvince*,128\>; 温度邻居平滑用 |
| +40 | uint8 | weather_active | | 初始化器 0X140F1D750: 省 def+0 非零且 def+192 像素数>0 才置 1; 定案 |
| +44 | uint32 | terrain id | | −1=无; 查 mgr terrain_modifiers 槽得温度增量 |
| +48 | fixed | 地面雪累积量 | | post-load 对 ground_snow 带选 modifier; 高置信 |
| +56 | fixed×1e-5 | water | | writer 12068; loader 弃读 → 重算 |
| +64 | fixed×1e-5 | snow | | writer 12036; loader 弃读 |
| +72 | CModifier (内嵌) | 省动态天气修正块 | | {vt@+72, dword@+80, pairs 容器@+88}; post-load 重建: mud 100000 + 温度带 + ground-snow + custom 合并 |
| +96..+263 | — | 死区/对齐填充 (168B) | 不序列化 | 拷贝构造整体跳过; 定案 |
| +264 | fixed | prev_temperature | | 带变迁检测缓存 |
| +272 | uint8 | prev_mud | | |
| +273 | uint8 | prev_visual_mud | | |
| +280 | fixed×1e-5 | temperature | | writer 12033; loader 弃读 |
| +288 | uint64 | — | | **结构性死字段**: 仅作 +280 temperature 所在 16B OWORD 的尾部被 copy ctor 整体复制 (0X140F140E0 `*(_OWORD*)(a1+280) = *(_OWORD*)(a2+280)`); 全 dump 零独立写者 + 零读者 (⚠ 同号偏移 SWeatherPerRegion+288 = blizzard 旗, 勿混) |
| +296 | fixed×1e-5 | temperature_offset | | writer 19806; loader 弃读 |
| +304 | uint8 | mud | | writer 12038; loader 实载 |
| +312 | uint8 | visual_mud_active | | 省 custom modifier ∈ mgr visual_mud_effects 时置 1 |
| +320 | fixed | prev_snow | | `+320 = +64` |
| +328 | 容器 24B | custom_modifiers | | {data, cap@+336, count≤16@+340, alloc@+344}; 16B 条 {名对象指针 (名 cstr@+424), param uint32@+8}; loader case 15409 实载 |
| +352 | fixed | 生效温度副本 | | mud 判据用; 与 +280 同步写; 高置信 |
| +360 | uint8 | temperature dirty 旗 | | 高置信 |
| +368 | fixed | 温度变化累积器 | | 随机游走, 钳 ±mgr+320 |
| +376 | — | ground-snow 缓存 | | 缓存的 ground-snow modifier 定义指针; post-load 写入 |

#### 4.20.3 SWeatherPerRegion (352B, 区天气)

vt 0X29777C0 (RTTI 真名); stride 352 = 0x160 内联; writer 0X140F22F50;
load handler 0X140F20640 六现象旗实载 + temperature 弃读; 区 post-load 对
id≠0 调 sub_140F220D0 重建 +72 修正块。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | region_id | | writer 10827; loader 弃读 |
| +16 | 容器 24B | 区地形直方图 | | 按 terrain id 索引的 u16; {data, cap@+24, count@+28, alloc@+32}; 构建点 mgr init 0X140F1CB90; 消费点 0X140F15B40 现象持续期乘数; 与 +40 互锁; 定案 |
| +40 | uint64 | 归一化除数 | | = 有效地形省数×1e5; 定案 |
| +48 | 容器 24B | active_modifiers | | u16 数组 {data@+48, cap@+56, count@+60, alloc@+64}; writer 15264 块, 仅 cnt>0; u16 逐条匿名 #N |
| +72 | CModifier (内嵌) | 区动态天气修正块 | | {vt@+72, dword@+80, pairs@+88}; post-load 按六现象旗重建; "Null weather modifier for region." 断言 |
| +96..+263 | — | 死区/对齐填充 (168B) | 不序列化 | 拷贝构造跳过 |
| +264 | uint8 | rain_light | | |
| +272 | uint8 | rain_heavy | | |
| +280 | uint8 | snow | | |
| +288 | uint8 | blizzard | | |
| +296 | uint8 | sandstorm | | |
| +304 | uint8 | arctic_water | | |
| +312 | fixed×1e-5 | temperature | | writer 12033; loader 弃读 → post-load 重算 |
| +320 | uint8 | has_weather 更新使能旗 | | DoUpdatePasses `if (*(region+320))` 为使能判定 |
| +328 | CGameDate (内联 24B) | next_weather_change | | 内联非指针; {vt1@+328, hours u32@+336, vt2@+344 = ADEC0 代理}; writer ADEC0(a2, 19804, a1+344); loader ABB40(a2, a1+344); 拷贝构造双 vt+hours 互证; 通则 §3.7a |

序列化: writer 0X140F22F50 (WXR 行, 11 列管 cp[10] = next_weather_change,
rl, rh, snow, bliz, sand, aw, nact, act)。
温度/事件旗为运行时演化族 (next_weather_change 后引擎重算 — 跨轮漂移)。

#### 4.20.4 全局当前天气 (token 枚举)

根对象 +1672 = CWeatherManager* (§4.20.1)。天气状态集为编译期 enum 非运行时
注册表; token→enum 转换在 dispatcher 0X140F1DB00。

| token 值 | 名称 | 语义 |
|---|---|---|
| 10737 | clear | |
| 12034 | rain_light | |
| 12035 | rain_heavy | |
| 12036 | snow | |
| 12037 | blizzard | |
| 12054 | snowing | 补充键 (+snowing) |

注: 区 weather period 定义不在运行时元素上 — 在 strategic region 静态定义
{data@+176, count@+188}, 224B 条 (CWeatherChancePeriod 族)。

**CWeatherEntry / CWeatherPositionEntry (CWeatherNudger 行件, GUI)**: CWeatherEntry = CWeatherNudger 的 **104B 数据库周期行** (模板 nudge_window_database_period_entry): from/to 日期编辑框 + apply (回写 **period+8/+32 hours** 并横扫 **224B CWeatherChancePeriod 子表 ✓**) /delete/select 三钮; Update 0X141B89380 管 apply 显隐与 select 帧。CWeatherPositionEntry = 位置行 ("Position N"): **obj+1376/1380 = 位置 id/序号对**; select 点击写 **nudger+1236/+1240 当前位置**, Update 按当前位置匹配切显隐。

#### 4.20.5 季节与天气元素族 (CSeasonType / CSeasons / CWeatherElementChance / CWeatherElementRange / CWeatherChancePeriod)

**CSeasonType** (单季定义, 176B; vt 0x14296BBA8; writer=CFG; reader 0x140DF9570): +8/+32 起止 CGameDate 24B ×2 / +64..+144 六组 CColor 12B (hsv_north 10936 / hsv_center 10937 / hsv_south 10938 / colorbalance_north 10939 / colorbalance_center 10940 / colorbalance_south 10941) / +160 u32 季节序号 (宿主写 0..3)。

**CSeasons** (季节总表, 1352B; vt 0x14296BC48; writer=CFG; reader 0x140DF97F0): +16 CSeasonType[4] 内联 ×176B (winter 10783 / spring 10933 / summer 10934 / autumn 10935) / +720 **CTreeSeasonType[8]** 内联 ×64B (tree_winter/spring/summer/autumn 各 ×2, 10970-10977); 元素 CTreeSeasonType (64B, vt 0x14296BBF8, serfam 在册): 起止 CGameDate×2 + +56 序号。

**CWeatherChancePeriod** (天气时段定义, 224B; vt 0x1429DBE00; writer 0x141A0FA10 / reader 0x141A0EE80; serfam 在册): +8/+32 起止 CGameDate ×2 / **+56 CWeatherElementRange (温度带, ctor 默认 lo=-1000000 (-10.0) / hi=3500000 (35.0))** / **+80 CWeatherElementChance[9]** (槽序 = 天气现象枚举 0..8, 与 §4.20.1 terrain_modifiers[9] 同枚举序)。

**CWeatherElementRange** (数值区间, 24B; vt 0x1429DBD60; **自定义 Save/Load 0x141A0F5E0/0x141A0ED30 → 不在 serfam 但确实落档**): +8 lo / +16 hi (fixed×1e-5)。

**CWeatherElementChance** (单现象概率, 16B; vt 0x1429DBDB0; **自定义 Save/Load 0x141A0F5B0/0x141A0ED00, 同漏网**): +8 chance fixed。
