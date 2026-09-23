> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.14 CProvince (省)

**获取**: `pv = 省表[province_id]` (省表 = `*(gs+688)`, `M.province_array`)。
省计数 = **u32@(gs+700)** = max 省 id+1 (= CMap+560 = 省表 [0x2BC] 处 null 终止界;
探针三读互证, kr2=13,907 / BHU=13,414)。⚠ 州计数真值 = gs+724 (§4.13), 勿与省计数混;
gs+1864 = **region 数组计数** (BHU 3,789), 非省数 (定案)。

| 项 | 值 |
|---|---|
| RTTI 名 | CProvince |
| sizeof | 0x208 (520B; malloc 直证) |
| vtable RVA | 0X2971B18 (vptr +0) / 0X2971B68 (vptr +8, 双 vtable) |
| writer | 0X140E81390 (槽[2]) |
| loader | 0X140E7F720 (槽[4]) |
| 挂载点 | 省表 `*(gs+688)` (`M.province_array`) |
| 方法群 | 0x140e78900–0x140e84590 (province.cpp) |

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +24 | 内嵌 | 监听器列表头 (TListenableTrait) | SetController 通知 sub_140E788B0(a1+24,…) | 不序列化 |
| +56 | uint32 | victory_points | 胜利点 (token 12156, ≠0 才写; SetVictoryPoints sub_140E810F0 断言 `_pState`, 尾调 CState BestVP 重算) | **GUI: 胜利点文本** (≠0 显隐; sub_14174DD50 → STATE_VIEW_WICTORY_POINTS/VALUE) |
| +64 | MSVC SSO 32B | 动态名 {SSO/ptr@+64, size@+80 (门≠0), cap@+88} | CRenameProvinceEffect 写 / CResetProvinceEffect 清; loader case 27 | |
| +96 | 容器 24B | **CFront 反查缓存 · fronts 指针表** {data@+96, cap@+104, count@+108, alloc@+112} | 一体结构 {自旋锁@+120, front id 排序缓存@+128, sorted_valid u8@+152}; 写入口 = CFront loader (case 10288 provinces 双向链接); 查询 sub_141A066F0 带锁 | 不序列化 |
| +120 | u32 | 上块自旋锁 (InterlockedCompareExchange) | | 不序列化 |
| +128 | 容器 24B | CFront 反查缓存 · front id 排序缓存 {data@+128, cap@+136, count@+140, alloc@+144} | Q1 (bit8/16) = front id 集相交, Q2 (bit2/4) = 成员查 | 不序列化 |
| +152 | u8 | sorted_valid (remove 时清 0) | | 不序列化 |
| +160 | uint32 | occupation | 占领标量 (token 0x3563=13667 "occupation", ≠0 才写; **loader 丢弃键** sub_1424C08D0 skip-parse) | |
| +164 | uint32 | id | 省 id (ctor = *(descriptor+196)) | **GUI: 冬季图标查询键** (gs+1672 天气表 sub_140F19EE0, 对象+64>0 → temperature_icons) |
| +168 | std::set\<u64\> | **前线构建暂态集** {head@+168, size@+176} (0x28 哨兵节点, 键 u64@node+32; 两省树交集 → 错误码 8 (邻省对), 树空 = 放置条件; 运行时 13906 省全空; **写入口 = sub_1409D1290** — 对 prov+168 树逐节点 u64 键红黑插入 (键 = 第二实参), 并同步 st+2208 `_SubAreas` std::map; 调用者 sub_1413EBB90 = CLandBorderWarCombat 族边境战争对象创建后; 删除侧 sub_1409DD140 区间擦除 → 只有边境战争对象存在时才登记, 与 CFront 反查缓存 +96/+128 无关) | ctor malloc 0x28 哨兵 `word@+24=257`; dtor 逐节点擦除 | 不序列化 |
| +184 | 省静态描述符* | 静态描述符桥 | → CMap+616 省静态描述符 (见 4.14.3) | |
| +192 | CState* | **_pState 州回指** (断言原文 `_pState`; writer 以 *(X+200) 作 tag 比较 (CState+200=owner) + CState::SetOwner 链 + GetName 州名回退 + StateView SetTarget +1416 直存此值 + Refresh 比对链 *(prov+192) 解引用, 多源互证) | 默认控制者 = 其 +200 owner | |
| +200 | CStrategicRegion* | **无州省名源对象 = 战略区指针** (GetName: 无州且 +200≠0 → 其内嵌串, 为空 → "PROV<id>"); **其 +88/+96 双存区数字 id** (探针全 276 区逐一对值恒相同; writer 写 +96, 消费端 +88/+96 双读皆通; 旧「当前天气 id」误 — 天气链实为 **区 id → gs+1672 天气管理器查键**) | 探针 vt 0X296D558 直证; GUI: 天气修正 tooltip | |
| +208 | 匿名结构* | theatre 隶属查询键 (值即 country+360 theatres 各 theatre+24 数组元素; sub_140E7D690 比对找回所属 theatre; theatre 对象 +60 = 排序键 int, is_in_home_area 按 +60 最大选首都 theatre — 推定) | | 不序列化 (高置信/推定) |
| +216 | COwnerArea* | owner area 回指 (supply 系统; setter sub_140E810E0, 写入对象带 `&COwnerArea::vftable` RTTI 直读) | | 不序列化 |
| +224 | 容器 24B | **在场单位本体数组** {data@+224, cap@+232, count@+236, alloc@+240} — 8B 元全类型 (AddUnit sub_140E79B10 首支恒插; combatmanager 遍历建战斗) | | 不序列化 |
| +248 | 容器 24B | type==1 (海军) 单位子对象数组 {data@+248, cap@+256, count@+260, alloc@+264} (陆省无港断言 "Trying to move navy to land province with no port!") | | 不序列化 |
| +272 | 容器 24B | type==0 (陆军) 单位位置对象数组 {data@+272, cap@+280, count@+284, alloc@+288} (tooltip 在场单位显示消费) | | 不序列化 |
| +296 | 容器 24B | type==13 单位子对象数组 {data@+296, cap@+304, count@+308, alloc@+312} (**type13 = CRailwayGun 铁路炮** — sub_140E87E70 写 `&CRailwayGun::vftable` 且 sub_140BF8B50(a1,13,a2); 类型号分派 sub_141A949B0 case 13 → sub_1410E6290; 增删 sub_140E79B10 case 13 push 本数组) | | 不序列化 (定案) |
| +320 | 容器 24B | strategic_province_location u32 token 数组 {data@+320, **cap@+328**, count@+332, **alloc@+336**} | **块键 = 10230 (定案)**; AddStrategicLocation 断言 "…already exist in province: %d" + 置 mapdata+5984=1 | **GUI: 省侧战略位置行** (sub_1417507F0 → strategic_locations_grid) |
| +344..+367 | — | **保留区 (负定案)** — 24B 无写者无消费者: 1.19.3 与 1.19.2 **双版** province.cpp 方法群内零读写, ctor (sub_140E78EC0/sub_140E79050) 在 +336 与 +368 之间整段跳过 (非「填 0」) | | 定案 (负) |
| +368 | 容器 24B | **在场战斗数组** {data@+368, cap@+376, count@+380, alloc@+384} — 8B CCombat* 元 add-unique (combatmanager sub_140BB77E0 建战斗后 sub_140E797F0 插入) | | 不序列化 |
| +392 | tag_id | controller | 控制国, 写门 (writer 0x140E81390) = `*(p+392) > 0 && tid != dctl && (!tid \|\| !dctl \|\| !同国(tid,dctl))`; dctl = rp(p+192) 有则 +200 否则 sub_140BB3E00 默认槽, 同国 = sub_140BB52F0 → **gs+832**(=qword 索引 104) 映射表 [tid]==[dctl] (tag 别名对, KR 傀儡 D04 两槽实证); 0x283F; loader case 10303 → **SetController sub_140E801A0** 对接 country 族 Add/RemoveControlledProvince; 两效果类 Execute 直调 | **GUI: 省名占领着色/+TAG 后缀** (sub_14174C8E0 → STATE_PROVINCE_NAME_OCCUPIED_COLOR/STATE_PROVINCE_PLUS_TAG) **+ 外交/密码 SetTarget 转发键** (DiplomacyView[11] / AgencyView[11] / OccupationView[11] 同链) |
| +400 | CBuildingStatus 内嵌 112B | buildings (+400..+511, 见 4.14.1) | vtable 0X2999050; dtor sub_141171C10(a1+400) | **GUI: 省建筑行** (可见性门 def+8==19649 rail_way / +802 / +824 / +883·+885 DLC; sub_14174DD50 → province_building_entries) |

#### 4.14.1 CBuildingStatus (内嵌 112B, prov+400 相对)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | vt | 0X2999050 (CBuildingStatus::vftable, dtor 直读) | |
| +8 | CBuildingListener 向量 | 32B 条数组 {data@+8, cap@+16, count@+20, alloc@+24} (**元素 = 建筑监听者登记条目, 类族 CBuildingListener** — RTTI 直证 vt 0x142A206C0; 元素 ctor sub_141171A60, +16 挂 `CPdxHybridInlineBufferAllocator<CBuildingListener*,128,int>` (sub_141171D70); push sub_141179150; 销毁 sub_141171BA0) | 定案 |
| +32 | 容器 24B | **def→槽 index 重映射** {data@+32, cap@+40, count@+44, alloc@+48} — u32 槽号或 −1, 按 building def+736 索引 | find-or-add sub_141172EB0 |
| +56 | 容器 24B | **CBuilding\* 元素数组** {data@+56, cap@+64, count@+68, alloc@+72} | |
| +80 | 容器 24B | **建筑修正来源数组** {data@+80, cap@+88, count@+92, alloc@+96} — 8B CBuilding\* 元 (= prov+480/+492; 州修正重建 sub_1409D54A0 逐元取 CBuilding+88 CModifier 入州 +1544 块) | 定案; **GUI: 建筑修正图标来源** (sub_14174C6F0 省侧分支 → building_modifiers_ico) |
| +104 | u32 | **类别旗位掩码** (= prov+504; ctor 置 5 = bit0\|bit2) | 位语义见下二表; 定案 (探针 50 样本 + 三函数直读) |
| +108 | u32 | **所属 id 副本**: bit0=1 → **省 id** (探针 25/25 逐个等于 prov+164) / bit0=0 → **州 id** (探针 12/12 等于 st+88; 消费 = sub_141177080/450 按 id 查省/州) | 定案 |
| +112 | i32 | **内联控制器 tag 槽**: ≤0 = 无 → sub_141176D70 回落查省+392/州+204 的 controller; >0 = 直接返回 &+112 作为「有效控制器 tag 指针」。本档 50 样本全 0 | 定案 (代码语义) / 推定 (业务名) |

类别旗位语义:

| 位 | 语义 |
|---|---|
| bit0 = 1 | 省类 — sub_141177080 查省要求 bit0=1 (探针省侧全奇 {1,5}) |
| bit1 = 1 | 州类 — sub_1411771B0 查州要求 bit0=0 (探针州侧全偶 {2,6}) |
| bit2 = 1 | 第二类旗 |

整值经 sub_1406870A0 → 建筑 DB+904 类别行表 (24B 5 行):

| 位组合 | 类别行 |
|---|---|
| bit0 置位 | 行1/行3 |
| bit1 置位 | 行2/行4 |
| bit0/bit1 双清 | 行0 |
| bit2 置位 | 取大号行 |

#### 4.14.2 CBuilding (省建筑元素, 0x1F0 = 496B)

ctor sub_1410DAB40; writer 0X1410DCCA0 (修速块 + 主 writer)。

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +8 | token | 建筑类型 | token 转名 (= def+8) | |
| +64 | i16 | level | **writer 按 i16 直读** (键 0x286C) | |
| +66 | i16 | healthy_levels | 键 0x4880 | |
| +72 | i64 | partial_health | 键 0x487F | |
| +80 | i64 | repair_speed_factor | **≠100000 (1.0) 才写** (键 0x3D2E; ctor 默认 100000) | |
| +88 | CModifier 内嵌 192B | 建筑修正子对象 (州修正重建 sub_1409D54A0 消费它) | ctor vt 直读 | 定案 |
| +176 | MSVC 串 | 建筑名副本 (拷自 def+528) | | 定案形态 |
| +280 | CModifier 内嵌 | 第二内嵌修正 (+296 容器) | | 高置信 |
| +368 | MSVC 串 | 第二串 (同拷 def+528) | | 高置信 |
| +472 | CBuildingStatus* | CBuildingStatus 容器回指 | AddBuildings 查 *(elem+472) | 定案 |
| +480 | CProvinceBuildingItem* | building def 回指 (ctor a3) | | 定案 |
| +488 | u16 | 待加等级计数 (AddBuildings `+= WORD2(条)`) | | 高置信 |

**州建筑容器 (州对象同构)**: 容器 vtable 0X2999050 同布局 (state_buildings API 用)。州建筑元素
与省建筑元素同类同 writer (元素 vt 0X142988B28 slot[2] = 0X1410DCCA0; 容器链
CState 0X1409E0E90 → 0X141179440; 块键 = 建筑 token@元素+8); repair_speed_factor
行 (i64@+80, ≠100000 才写) 州侧同样适用 (实测 489 州炼油 0.69188 / 116 基建 0.5)。
⚠ 对象层 state_buildings reader 含 +80 读取 (与 province_buildings 镜像)。

#### 4.14.3 省静态描述符 (CMap+616 元素指向的对象)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +20 | u8 | 脏/待重建旗 (CProvince vt 槽[12] sub_140E7EE30 置 1) | 高置信 |
| +112 | 匿名结构 (48B 形状) 向量 | **邻接表** {data@+112, count@+124} — 48B 条, 邻省 id u32@条+8 (断言 "…over 256 neighbors", 界 255; 湖泊自动控制者 sub_140E7FCA0 遍历) | 定案 |
| +152 | 匿名结构* | **必需规则对象** (≠0 → GUI province_required_rule 图标显示; 消费 sub_14174C500) | 高置信 |
| +168 | 匿名结构* | **地形 def 指针** (名 SSO@def+24; 两处独立读法拼 terrain_picture/取 TYPE) | 定案 (消费形态) / 推定 (正名) |
| +196 | u32 | 省 id (prov+164 = *(desc+196) 互证) | |
| +210 | u8 | **旗字节: bit0 = 脚本 is_land** (海军移动断言链; ⚠ 与 CMap+568 数组**语义不同**: 湖泊/内陆水域在此为 0, CMap 侧为 1 — 13,494 省全量双读 111 例差异全属此类, 非缺陷); **bit2 (0x4)** = 岛屿旗 (推定); **bit3** = 门 (清 0 时 CBuildingStatus+104 置 5) | bit0 定案 / bit2 推定 / bit3 高置信 |

#### 4.14.4 CMap 边界 (map.cpp 方法群 0x140A4D000–0XUNRESOLVED, CMap this 相对)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | 容器 24B | **海峡/邻接规则表** {data@+16, cap@+24, count@+28, alloc@+32} — **12B 条 {from, to, through} u32×3** (straits loader "no straits will be loaded" / "Adj between … is not adjacent with THROUGH =") | 定案 |
| +536 | 容器 24B | 8B 指针容器 {data@+536, cap@+544, count@+548, alloc@+552} (map mode 规则族: "Province … added twice to the same or different rules") | 高置信 |
| +560 | u32 | 省表界 (= gs+700 互证) | |
| +564 | u32 | 陆省数 | |
| +616 | 容器 24B | **省静态描述符 8B 指针数组** {data@+616, **cap@+624, count@+628**, alloc@+632} — ⚠ 元素是指针 (增长码 `8LL*count` memcpy 铁证) | 定案 |

#### 4.14.5 CProvinceBuildingItem 定义对象侧字段 (def 相对)

| 偏移 | 名称/语义 |
|---|---|
| +676 | 设施旗 |
| +700 | 省级等级上限 (≤0 → 双 status 规则走州 +288; >0 → 走省 +400) |
| +740 | 图标帧 |
| +808 | 自定义图标 GFX (与 +824 门槛分槽 — 点击 lambda → sub_14174AB30 开设施 program 窗; countrystateview.cpp:0x658 断言铁证) |
| +824 | 自定义图标门槛 (与 +808 GFX 分槽) |

省 loc 装配 = CAPACITY{level,max} + BUILDING_DAMAGED{DAMAGED,CURRENT} + 满级特殊字形。

CProvinceStrategicLocationEntry:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | CProvince* | target 省 |
| +40 | token | location token |

GFX 名 = `GFX_strategic_location_<lexer名>` 拼名; tooltip 双名 getter 再证
**CState+2048 第二 u32 = prov_id** (§4.13)。

#### 4.14.6 CProvinceRailwayInfo (铁路/补给图节点)

**gs+992 = 铁路图容器** (定案; assert "Failed to find CProvinceRailwayInfo for
province" supply_system_utils.cpp:0x31C 铁证); `*(gs+992)` 容器 +8 =
**CProvinceRailwayInfo\*[] 按省 id 直索引**。

**CProvinceRailwayInfo** (0x70 = 112B; vtable 0X2972C80; writer 0X140E95DD0; ctor
0X140E922A0; dtor 0X140E92750): +8 = CProvince* 省反查 / +16 = 指回省体内 +400 块
back-ref / +24 = railway 模板 def (断言 "_pStatus->IsValidTemplateInLocation(RailwayTemplate)"
railway_manager.cpp:0x1)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +24 | CBuilding* | 铁路建筑 (i16 level@+64 > 0 = 已建运营; sub_140E29CA0 双省连通谓词, 前置门 = prov+184 描述符 desc+210 bit0 可通铁路位) | — |
| +32 | 容器 24B | rail_way 等级数组 {d@32, cap@40, c@44, alloc@48} — 等级 u32 数组按邻接表序 (多线并存每线一级; SSE max = 省有效等级 → 州面板铁路行 row+1336; row+40 = rail_way def, row+1340 = dword_1433349D8) | c>0 → 单行 |
| +44 | uint32 | 上行数组计数 | c>0 → 单行 |
| +56 | 容器 24B | 邻接边二分查找表 {d@56, cap@64, c@68, alloc@72} — 8B 对 {province u32@0, level u32@4} 按省 id 排序 (runtime cache; sub_140E92D00 二分, 断言 MAX_RAILWAY_LEVEL = dword_1433349D8) | 不序列化 |
| +68 | uint32 | 上行边表计数 | 不序列化 |
| +80 | 容器 24B | rail_way_construction {d@80, cap@88, c@92, alloc@96} — 16B 条 {邻省 u32@0, 进度 fixed×1e-5 i64@8}; **非空 = 施工中 (阻断语义由此表达, 非 +104)** | c>0 |
| +92 | uint32 | 上行 construction 容器计数 | c>0 |
| +104 | u32 | **cooldown** (tok 14622; writer sub_140E95DD0) — 单标量**无位段** (旧记「阻断旗」已翻案: 阻断由 +80 非空表达) | >0 |
| +472 | 内嵌状态块 | 与 CBuildingStatus +104 门 byte / +108 省 id 同构; 地图悬停链 sub_1410DB850/6520 经其还原省/州 | — |

#### 4.14.7 CRailwayManager (gs+992)

| 项 | 值 | 语义 |
|---|---|---|
| 管理器 | `M = *(gs + 992)` (vtable 0X2972CD0 guard; manager writer 0X140E95EF0) | |
| 槽数组 | {data@M+8, slots u32@M+20} | 元素 = CProvinceRailwayInfo* (0x70 字节, vtable 0X2972C80 guard); 非空槽才写省号块 |
| 顶格 cooldown | u32 数组 {d@M+32, c@M+44} | c>0 才写 (0X1401B3D80 单行) |
| 省反查 | 省指针@info+8 → 省 id = ru32(CProvince+196) | |

> CRailwayManager ctor 0X140E92510 {slots cap@M+16, alloc@M+24}; 实例对象 = §4.14.6
> CProvinceRailwayInfo; 轨道升级图标侧 (CRailwayMapIcon + 五 define) 见 §4.30.16。

每省情报/可见度纹理 (访问链定案 / 管理器与包装对象类名未决 — 均无 RTTI; CGameGraphics 已排除):

| 项 | 值 |
|---|---|
| 挂载 | 管理器 vt[120] 对象 +1776 = 每省情报/可见度字节纹理 (0–100%) |
| 隐藏门 | <50 = 自定义建筑图标隐藏 (def+874 豁免) |
| 第二消费点 | pdxmaptexturegeneration.cpp:244/254 喂地图纹理 {+0 字节基址, +56 纹理对象} |
| 战争迷雾总开关 | byte_14332F63A (**定案**: debug_fow 控制台命令 handler sub_1402589F0, 打印 "Fog of War is now ON/OFF"; §4.34.7) |

**省 map_obj 扩展区锚点 (GUI 图标族)**: **+4796 = 默认锚点 / +5448 = 建筑图标锚点数组** (CNavalBaseMapIcon populate 双消费; 与既有 +4568/+4688/+5984 并列同区)。
