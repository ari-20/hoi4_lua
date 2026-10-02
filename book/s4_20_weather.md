

### 4.20 天气族 (CWeatherManager → 省天气 / 区域天气)

#### 4.20.1 CWeatherManager (管理器, ≥1424B)

mgr = *(gs + 1672); vtable RVA 0X2977810; 尺寸 ≥1424。
「weather」顶层键 = CWeatherManager 整块多态序列化 (gamestate writer
`ADEC0(a2, 0x2F08=12040 weather, *(gs+1672))`; gs+1672 持 CWeatherManager 指针)。
writer 0X140F22A70 / loader 0X140F1F780 (12066/12067/10647 读后即弃)。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | CGameState* | gs 回指 | 不序列化 | HourlyUpdate/DoUpdatePasses/区换档均以 mgr+8 取 gs |
| +16 | 匿名结构 (NNB 形状) 向量 24B | provinces | | {data@+16, cap@+24 (1.5x), count@+28, alloc@+32}; 元素内联 384B = 0x180 (SWeatherPerProvince, §4.20.2) |
| +40 | 匿名结构 (NNB 形状) 向量 24B | 含活跃自定义修正的省份指针表 | | {data@+40, cap@+48, count@+52, alloc@+56}; 8B 条 = SWeatherPerProvince*; vt slot8: custom_modifiers 有 param>0 者入表, 随后 +840=1 并调 HourlyUpdate |
| +64 | 匿名结构 (NNB 形状) 向量 24B | regions | | {data@+64, cap@+72, count@+76, alloc@+80}; 元素内联 352B = 0x160 (SWeatherPerRegion, §4.20.3) |
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
| +504 | fixed | snow_gain_max | | 雪视觉分母; post-load 雪总量钳位; 运行期下限 = max(0, min_snow_level)×本值 |
| +512 | fixed | snow_gain_to_cm | | |
| +520 | fixed×2 | snow_melt_temperature | | 区间 {+520/+528} |
| +536 | fixed×2 | snow_melt_multiplier | | 区间 {+536/+544} |
| +552 | fixed×2 | snowing.temperature | | 区间 {+552/**hi**, +560/**lo**} (⚠ E1 定案: 区间序反 — hi@+552/lo@+560, 与 +608 arctic 同族反序; 暖温抑制雪) |
| +568 | uint32 | snow_visual_min | | 雪视觉下限钳位; 公式: level = 255×snow/mgr+504, 非零且 <128 → 钳 128 (脏链 0x140F1F3D0) |
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
| +880 | 匿名结构 (NNB 形状) 向量 24B | 每省 DayNight 数组 | | {data, cap@+888, count@+892, alloc@+896}; 条 816B: +0..+575 = 24 小时槽×24B{3 fixed}, DayNight fixed@+576, GmtOffset fixed@+584, +592/+600 qword, Hour u32@+608, prev DayNight@+616, 内嵌 CModifier@+624 |
| +904 | u8 缓冲 | 雪贴图前缓冲 | | (mapW/4)×(mapH/4); +920 后缓冲, 泥 +912/+928 (双缓冲) |
| +936 | 匿名结构 (NNB 形状) 向量 24B | 脏天气瓦片表 | | u32 瓦片 id; {data, cap@+944, count@+948, alloc@+952} |
| +960 | u8 数组 | 每省脏旗 | | |
| +968 | 内嵌 | weather_effects[9] | | +968..+1399; 9×48B; u32@+12, u32@+36; 解析器 case 12654 经 SWeatherEffectsReader{vt, data=a1+968} |
| +1400 | 匿名结构 (NNB 形状) 向量 24B | visual_mud_effects | | {data, cap@+1408, count@+1412, alloc@+1416}; 8B 条 = modifier 定义指针; 省更新判省 custom modifier ∈ 此表 → +312=1 |

演化函数族 (调度 = 每小时主调度序位 7 → CWeatherManager::HourlyUpdate):

| 环节 | 函数 | 要点 |
|---|---|---|
| HourlyUpdate | 0x140F1C6E0 | (mgr, bAdvanceSeed): a2=1 → mgr+776 种子 += 全局 RNG sub_142233FA0; DayNight 头 0x140F18800 (tbb 并行, 季节插值 sub_140F15EB0 唯一调用点) → passes = mgr+840 ? nInitPasses : 1 → 主演化 → init 尾 0x140F218A0 雪/泥贴图全刷 (mgr+960 每省脏) + 清 +840; 调用者仅 3: hourly (bAdvanceSeed=1) / randomize_weather 效果 sub_140F1F710 / vt slot8 post-load |
| DoUpdatePasses | 0x140F18AD0 | (mgr, nPasses) 省/区双游标轮转 (+752/+756 区段) + tbb 并行 |
| 省并行体 | 0x140F10D60 | 逐省调核心 0x140F11820 + 邻居温度平滑 (邻省表累积 +280/+296 → 平均 → +352/+368 按 mgr+328/+336 收敛) |
| 省核心 | 0x140F11820 | prev 缓存刷新 → period 选取 0x140F191F0 (strategic region 静态定义 224B 表, 断言 "No weather period found for region") → 地形温度增量 (terrain_modifiers 槽1) → 随机游走 `+368 += 2×(mgr+312×(rand%1e5−50000)/1e5)` 钳 ±mgr+320 → 温度合成出带钳位 → 雪 (区旗 snow/blizzard 增益 / 消融 0x140F21B70, **融雪半数转 water +56**) → 非水域省 water 0x140F22730 + mud 掷判 0x140F22420; 变化检测 (prev_snow/mud/visual_mud) → 脏链 0x140F1F3D0 |
| 区换档 | 0x140F20EF0 | gs+1128 < region+336 未到期 return; period==null fallback → 读 region def+48 触发器容器 {data@+312, count@+324} 80B 条逐条 Eval 写 region+48; 否则: 区温 = 区内活跃省平均 → 极寒抑制 (snow/blizzard 概率 ×(1−插值)/1e5; **区温 <1.0°C 时 rain_light/rain_heavy 概率直接置零**) → arctic_water (旗已开用 end 带) → 现象概率 = chance[k] × terrain_modifiers 地形乘数 0x140F15B40 (槽 2..5 = rain_light/rain_heavy/snow/blizzard, sandstorm = 槽 7) → 持续期抽样 0x140F15C50 (双掷取小加权: 24×min + (24×max−24×min)×min(双掷)/1e5 小时; min>max 报脚本错) → 到期重排 `region+336 = gs+1128 + 持续期`; 六旗变化 → 重估触发器 + 修正块重建 0x140F220D0 |
| 哈希 RNG | 0x140F19F00 | (mgr, out, salt): `salt + mgr+776` → 固定常量族混淆 → [0,1e5); 全天气域掷点同款内联 — 并行安全 (无共享 RNG 状态) 且同 seed 同 salt 确定性可重放 |
| 修正块重建 | 0x140F220D0 | 清 region+88 pairs → 六现象静态定义 modifier ×1.0 + active_modifiers[i] 非零条目 ×1.0 并入; 断言 "Null weather modifier for region." |
| post-load | 0x140F1CA40 (vt slot8) | 重建 mgr+40 活跃省表 → +840=1 → 立即 HourlyUpdate(0) init 全量轮; loader 0x140F1F780 case 12065 区条逐区立即重建修正块 — 读档后第一帧前已是完整重算态 (落盘弃读值仅作 writer 对拍参照) |

#### 4.20.2 SWeatherPerProvince (384B, 省天气)

vt 0X2977770 (RTTI 真名); stride 384 = 0x180 内联; load handler vt slot4
0X140F20330 — mud/custom_modifiers 实载; province/temperature/snow/water/
temperature_offset 全部读后弃 → post-load 重算。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | uint32 | province_id | | writer 键 10304; loader 弃读 |
| +16 | 匿名结构 (NNB 形状) 向量 24B | 邻省表 | 不序列化 | vector\<SWeatherPerProvince*\> {data, cap@+24, count@+28, alloc@+32}; RTTI CPdxHybridInlineBufferAllocator\<SWeatherPerProvince*,128\>; 温度邻居平滑用 |
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
| +328 | 匿名结构 (NNB 形状) 向量 24B | custom_modifiers | | {data, cap@+336, count≤16@+340, alloc@+344}; 16B 条 {名对象指针 (名 cstr@+424), param uint32@+8}; loader case 15409 实载 |
| +352 | fixed | 生效温度 (核心单写) | | mud 判据用; +280 为解析基值 (脏链 0x140F1F3D0 先清后置时序) |
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
| +16 | 匿名结构 (NNB 形状) 向量 24B | 区地形直方图 | | 按 terrain id 索引的 u16; {data, cap@+24, count@+28, alloc@+32}; 构建点 mgr init 0X140F1CB90; 消费点 0X140F15B40 现象持续期乘数; 与 +40 互锁; 定案 |
| +40 | uint64 | 归一化除数 | | = 有效地形省数×1e5; 定案 |
| +48 | 匿名结构 (NNB 形状) 向量 24B | active_modifiers | | u16 数组 {data@+48, cap@+56, count@+60, alloc@+64}; writer 15264 块, 仅 cnt>0; u16 逐条匿名 #N; **= 脚本条件天气修正开关缓存** — 触发器定义在 region def+48 → {data@+312, count@+324} 80B 条 (vt+24 = Eval), 每次换档六旗变化或 period 缺失时重估, 置位者以 ×1.0 并入 +72 修正块 (sub_140F220D0); 落盘值 = 上次求值结果, 加载后首轮换档即重估 |
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
注册表; 枚举表 = sub_141A0F550 (.rdata 0x142A2C550), 由 weather.txt 解析器
0X140F1DB00 调用。

| token 值 | 名称 | 语义 |
|---|---|---|
| 10737 | clear | UI 写者键 (非状态机键) |
| 12034 | rain_light | |
| 12035 | rain_heavy | |
| 12036 | snow | |
| 12037 | blizzard | |
| 12054 | snowing | 补充键 (+snowing) |

注: 区 weather period 定义不在运行时元素上 — 在 strategic region 静态定义的 **+48 子对象** (`*(区定义+48)`) 的 {data@+176, count@+188}, 224B 条 (CWeatherChancePeriod 族); period 选取 0x140F191F0 先把日期归整到当日 0 点 (/24) 再线性扫。

**CWeatherEntry / CWeatherPositionEntry (CWeatherNudger 行件, GUI)**: CWeatherEntry = CWeatherNudger 的 **104B 数据库周期行** (模板 nudge_window_database_period_entry): from/to 日期编辑框 + apply (回写 **period+8/+32 hours** 并横扫 **224B CWeatherChancePeriod 子表 ✓**) /delete/select 三钮; Update 0X141B89380 管 apply 显隐与 select 帧。CWeatherPositionEntry = 位置行 ("Position N"): **obj+1376/1380 = 位置 id/序号对**; select 点击写 **nudger+1236/+1240 当前位置**, Update 按当前位置匹配切显隐。

#### 4.20.5 季节与天气元素族 (CSeasonType / CSeasons / CWeatherElementChance / CWeatherElementRange / CWeatherChancePeriod)

**CSeasonType** (单季定义, 176B; vt 0x14296BBA8; writer=CFG; reader 0x140DF9570): +8/+32 起止 CGameDate 24B ×2 / +64..+144 六组 CColor 12B (hsv_north 10936 / hsv_center 10937 / hsv_south 10938 / colorbalance_north 10939 / colorbalance_center 10940 / colorbalance_south 10941) / +160 u32 季节序号 (宿主写 0..3)。

**CSeasons** (季节总表, 1352B; vt 0x14296BC48; writer=CFG; reader 0x140DF97F0): +16 CSeasonType[4] 内联 ×176B (winter 10783 / spring 10933 / summer 10934 / autumn 10935) / +720 **CTreeSeasonType[8]** 内联 ×64B (tree_winter/spring/summer/autumn 各 ×2, 10970-10977); 元素 CTreeSeasonType (64B, vt 0x14296BBF8, serfam 在册): 起止 CGameDate×2 + +56 序号。

**CWeatherChancePeriod** (天气时段定义, 224B; vt 0x1429DBE00; writer 0x141A0FA10 / reader 0x141A0EE80; serfam 在册): +8/+32 起止 CGameDate ×2 / **+56 CWeatherElementRange (温度带, ctor 默认 lo=-1000000 (-10.0) / hi=3500000 (35.0))** / **+80..+224 = CWeatherElementChance[9] × 16B** — **现象枚举真表** (sub_141A0F550, .rdata 0x142A2C550): 0 no_phenomenon / 1 temperature / 2 rain_light / 3 rain_heavy / 4 snow / 5 blizzard / 6 mud / 7 sandstorm / 8 arctic_water (与 §4.20.1 terrain_modifiers[9] 同序); **chance[9] 自身另成一套序** (reader 0x141A0EE80): 槽 5 = arctic_water / 6 = mud / 7 = sandstorm / 8 = min_snow_level, 与 terrain_modifiers 不同序; chance[k] 值 @ +88+16k — **区换档抽样权重表即此 chance[9]**, 槽 0 = 无现象权重; duration 表 (§4.20.1 +656..+744) = no_phenomenon/rain_light/rain_heavy/snow/blizzard/sandstorm 六键。

**CWeatherElementRange** (数值区间, 24B; vt 0x1429DBD60; **自定义 Save/Load 0x141A0F5E0/0x141A0ED30 → 不在 serfam 但确实落档**): +8 lo / +16 hi (fixed×1e-5)。

**CWeatherElementChance** (单现象概率, 16B; vt 0x1429DBDB0; **自定义 Save/Load 0x141A0F5B0/0x141A0ED00, 同漏网**): +8 chance fixed。

#### 4.20.6 消费者矩阵 (系统 × 字段 × 函数)

访问器四件套 (全消费者经此): 省条 GetProvinceWeather 0x140F19EE0 (mgr+16+384×id) / 省修正块 0x140F19EB0 (省条+72) / 区条 GetRegionWeather 0x140F1A000 (mgr+64+352×id) / 区修正块 0x140F19FD0 (区条+72)。修正块消费模式 = 块+16 pairs → sub_14055E360 (按 modifier id 取值; id 空间 = modifier idmap, 勿混 gfx token 表)。

| 系统 | 读取源 | modifier id | 修正名 | 函数 |
|---|---|---|---|---|
| 空中·侦察 | 区修正块 | 1 | AIR_DETECTION | 0x140F77730 |
| 空中·轰炸 | 区修正块 | 10 | STRATEGIC_BOMBER_BOMBING_FACTOR | 0x140F622B0 (翼修正合成器) |
| 空中·任务效率 | 区修正块 | 17 | AIR_MISSION_EFFICIENCY | 0x140F78500 |
| 空中·对舰攻击/命中/敏捷 | 区修正块 | 22/23/24 | NAVAL_STRIKE_*_FACTOR | 0x140F60F10 / 0x140F61280 / 0x140F60BC0 |
| 空中·海侦 | 区修正块 | 42 | NAVAL_DETECTION | 0x140FACD70 / 0x140FABB80 |
| 空中·燃料 | 区修正块 | 414 | AIR_FUEL_CONSUMPTION_FACTOR | 0x140F5F880 |
| 陆军·堑壕 | 省修正块 | 258 | MAX_DIG_IN_FACTOR | 0x140C73820 |
| 陆军·移动组织损耗 | 省+区修正块 | 77 | ORG_LOSS_WHEN_MOVING | 0x140C82C10 (§4.18.15) |
| 陆军·统计合成 | 省+区修正块 | 97 | SUPPLY_CONSUMPTION_FACTOR | 0x140C6F960 → 收集器 0x140C6E580 |
| 陆军·移动速度 | 省+区修正块 | 43 | ARMY_SPEED_FACTOR | 0x140C7FDB0 (vt[28]) → 收集器 0x140C6E340 |
| 陆军·对地攻击 | 省修正块 | 227 | GROUND_ATTACK_FACTOR | 0x140E10340 |
| 陆军·attrition | 省修正块 | — | (§4.18.15 恢复链) | 0x140C75500 (+1080 缓存重算) |
| 海军·速度 | 区修正块 | 41 | NAVAL_SPEED_FACTOR | 0x141969820 |
| 补给·流量/消耗 | 省+区修正块 | 566/97 | SUPPLY_FACTOR / SUPPLY_CONSUMPTION_FACTOR | 0x140EBF5C0 / 0x140ED1550 / 0x140EB5E40 |
| 通用·参数化查询 | 省/区修正块 | a3 形参 | (按调用点) | 0x140C38760 / 0x140C38DF0 |
| 通用·整块收集 | 修正块指针 | — | (消费方自遍历 `累加器 += v×权重/1e5`) | 0x140C6E580 / 0x140C6E340 |

标量直读者 (非修正块): 雪判定 0x140BDE4C0 / 0x140E00590 / 0x1412B82E0 (省条+64>0); 触发器域雪量 0x140F1A610 = min(snow + 省条+48 地面雪累积, mgr+504); getter 族 0x140DBB1D0 温度 / 0x140D98090 offset / 0x140BCC3A0 雪 / 0x140C3ACC0 水; 战斗快照 snow 写入链 (定案): 陆战每小时步进头 sub_1412B82E0 判省雪量 (GetProvinceWeather +64>0) → sub_140CDF0F0 置 lb+744 bit0 → 结算 consolidation sub_140CDB850 快照 snow(+1093) = 防守侧 lb+744 bit0 / defensive_victory(+1092) = 防守 win 位 / overrun(+1094) 结算清零 / player_is_attacker(+1095) = attacker+584 vs gs+原初国 → sub_140CD9660 入池 (init 0x140CDD810)。**负结论**: 战斗攻防合成链无直接天气 token 读取 — 战斗的天气影响通道 = 修正块合成 + CCombat+1093 快照。海战侧另有**三快照通道** (§4.22.5 CNavalCombat c+152 现象枚举 / c+160 区修正块指针 / c+168 昼夜值, sub_1415C5820 每小时刷新)。昼夜联动: air 族全配 sub_140F19660 (DayNight 值 vs define DAY_NIGHT_COVERAGE_FACTOR) — air 修正 = 天气修正 × 昼夜档。

UI 面: 现象图标档位 0x1415C5820 (区旗直读, 无 arctic/sandstorm 档) / 省修正 tooltip 0x141880500 ("weather_mud" 键族) / 温度 tooltip 0x1415D9A20 / 天气 map mode 0x141D9F360 (区条+active_modifiers) / 雪渲染双带 0x140476810 (POSTEFFECT_*_SNOW defines 归一混合) / 州天气摘要 0x140DA5C80 / 0x140DA8A40 (区条+320 使能旗); 渲染缓存族 (mgr+784/+808/+904..+928/+936/+960/+768/+832) 为渲染层自有缓存, 演化后经脏链惰性重绘, UI 数据每帧重取无独立定时器。

#### 4.20.7 实现层增补 (loader 侧与并行拓扑)

| 项 | 定案 |
|---|---|
| 省初始化核 | sub_140F11390 (书未记): 与演化核同骨架但温度 = 时段带**中点**直写 +280/+352; HourlyUpdate init 相专用 tbb 重载 (sub_140F1C6E0 先直启 PdxParallelFor 全量跑初始化核再进 passes) |
| P2 相温度提交 | 省 modifiers 相 tbb 叶 (sub_140F12F10/0x140F23370): **+280←+352 / +296←+368** (脏门 +360) — 两个存档字段的运行时写者; 提交后 sub_140F21C60(prov,mgr,0) 修正块重建 |
| DayNight 每时计算 | sub_140F20C50: 日弧分数+GmtOffset → 24 小时槽·太阳向量点积 → Feather 归一钳 [0,1e5]; feather 全局派生链 = FeatherMax=DAY_NIGHT_FEATHER/2、Diff=1e10/带宽; 变化时重建条内 pairs (静态表第 7 定义 +88) |
| PdxParallelFor 拓扑 | grain 计算器 sub_1401DB390(jobtype, count): 0→max(1,count/threads); 1→max(1,count/(3×threads)); 2→1; **3→−1 = 串行执行** (调用方 `if (grain==-1)` 落内联串行循环); 天气省相用 jobtype 1, init/区相用 0; 同函子串行/tbb 两路收敛到同一核, 无确定性问题 |
| 静态 modifier 定义表 | 区修正块重建 sub_140F220D0: 单例 +40..+80 六现象定义指针 (雪/暴雪/雨轻/雨重/沙暴/mud) ×1.0 并入; active_modifiers 条目 (80B {+64 触发器, +72 modifier 定义}) 非零 ×1.0 并入; +88 = day_night (第 7 定义) |
| mud 掷判除数 | sub_140F22420 完整公式 = chance[6] × 水量分数(÷mgr+424 值, 经 sub_140F22730 出参槽) × 省附加 × 干湿滞回带(+640/+648) × 地形槽 6 乘数 < 单掷; 脏+温度下限双门 |
| randomize_weather | sub_140F1F710: 写 seed → 置 init 旗 → HourlyUpdate(0) |
| HourlyUpdate 尾 | 地图模式 33 (= 天气模式) → 缓存脏位 +86 |
