

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
| +0 | vt | CProvince 主虚表 | — | 定案 |
| +8 | CSelectable 内嵌 16B | 选择态基件 (type id = 4; ctor sub_140BC2AA0(a1+8, 4); §4.00.13) | — | 不序列化 |
| +16 | uint32 | CSelectable type id 半 (与 +20 旗) | — | 定案 |
| +24 | 内嵌 | 监听器列表头 (TListenableTrait) | SetController 通知 sub_140E788B0(a1+24,…) | 不序列化 |
| +56 | uint32 | victory_points | 胜利点 (token 12156, ≠0 才写; SetVictoryPoints sub_140E810F0 断言 `_pState`, 尾调 CState BestVP 重算) | **GUI: 胜利点文本** (≠0 显隐; sub_14174DD50 → STATE_VIEW_WICTORY_POINTS/VALUE) |
| +64 | MSVC SSO 32B | 动态名 {SSO/ptr@+64, size@+80 (门≠0), cap@+88} | CRenameProvinceEffect 写 / CResetProvinceEffect 清; loader case 27 | |
| +96 | 匿名结构 (NNB 形状) 向量 24B | **CFront 反查缓存 · fronts 指针表** {data@+96, cap@+104, count@+108, alloc@+112} | 一体结构 {自旋锁@+120, front id 排序缓存@+128, sorted_valid u8@+152}; 写入口 = CFront loader (case 10288 provinces 双向链接); 查询 sub_141A066F0 带锁 | 不序列化 |
| +120 | uint32 | 上块自旋锁 (InterlockedCompareExchange) | | 不序列化 |
| +128 | 匿名结构 (NNB 形状) 向量 24B | CFront 反查缓存 · front id 排序缓存 {data@+128, cap@+136, count@+140, alloc@+144} | Q1 (bit8/16) = front id 集相交, Q2 (bit2/4) = 成员查 | 不序列化 |
| +152 | uint8 | sorted_valid (remove 时清 0) | | 不序列化 |
| +160 | uint32 | occupation | 占领标量 (token 0x3563=13667 "occupation", ≠0 才写; **loader 丢弃键** sub_1424C08D0 skip-parse) | |
| +164 | uint32 | id | 省 id (ctor = *(descriptor+196)) | **GUI: 冬季图标查询键** (gs+1672 天气表 sub_140F19EE0, 对象+64>0 → temperature_icons) |
| +168 | std::set\<u64\> | **前线构建暂态集** (第二消费者 = CArmy::[52] 谓词 Dijkstra sub_140C6B530 读 size==0 找空置省 {head@+168, size@+176} (0x28 哨兵节点, 键 u64@node+32; 两省树交集 → 错误码 8 (邻省对), 树空 = 放置条件; 运行时 13906 省全空; **写入口 = sub_1409D1290** — 对 prov+168 树逐节点 u64 键红黑插入 (键 = 第二实参), 并同步 st+2208 `_SubAreas` std::map; 调用者 sub_1413EBB90 = CLandBorderWarCombat 族边境战争对象创建后; 删除侧 sub_1409DD140 区间擦除 → 只有边境战争对象存在时才登记, 与 CFront 反查缓存 +96/+128 无关) | ctor malloc 0x28 哨兵 `word@+24=257`; dtor 逐节点擦除 | 不序列化 |
| +184 | 省静态描述符* | 静态描述符桥 | → CMap+616 省静态描述符 (见 4.14.3) | |
| +192 | CState* | **_pState 州回指** (断言原文 `_pState`; writer 以 *(X+200) 作 tag 比较 (CState+200=owner) + CState::SetOwner 链 + GetName 州名回退 + StateView SetTarget +1416 直存此值 + Refresh 比对链 *(prov+192) 解引用, 多源互证) | 默认控制者 = 其 +200 owner | |
| +200 | CStrategicRegion* | **无州省名源对象 = 战略区指针** (GetName: 无州且 +200≠0 → 其内嵌串, 为空 → "PROV<id>"); **其 +88/+96 双存区数字 id** (探针全 276 区逐一对值恒相同; writer 写 +96, 消费端 +88/+96 双读皆通; 旧「当前天气 id」误 — 天气链实为 **区 id → gs+1672 天气管理器查键**) | 探针 vt 0X296D558 直证; GUI: 天气修正 tooltip | |
| +208 | CControllerArea* | **面/战区节点 = 前线控制区回指** (CControllerArea 洪水分组键 = 省+392 controller, 注册 CCountry+1352; 兼 theatre 隶属查询键与面级寻路 A* sub_140CF3B20 消费 (+40 = 面首省); 完整布局 §4.24.2) | | 不序列化 (定案) |
| +216 | COwnerArea* | **owner area 回指** (所有者区双类体系: COwnerArea 洪水分组键 = 州+200 owner, 注册 CCountry+1376; setter sub_140E810E0; 完整布局 §4.24.2) | | 不序列化 (定案) |
| +224 | 匿名结构 (8B 形状) 向量 24B | **在场单位本体数组** {data@+224, cap@+232, count@+236, alloc@+240} — 8B 元全类型 (AddUnit sub_140E79B10 首支恒插; combatmanager 遍历建战斗) | | 不序列化 |
| +248 | 匿名结构 (NNB 形状) 向量 24B | type==1 (海军) 单位子对象数组 {data@+248, cap@+256, count@+260, alloc@+264} (陆省无港断言 "Trying to move navy to land province with no port!"); 删除摘除 = CProvince::RemoveUnit sub_140E7FA10 (§4.18.20) | | 不序列化 |
| +272 | 匿名结构 (NNB 形状) 向量 24B | type==0 (陆军) 单位位置对象数组 {data@+272, cap@+280, count@+284, alloc@+288} (tooltip 在场单位显示消费); 删除摘除同 sub_140E7FA10 | | 不序列化 |
| +296 | 匿名结构 (NNB 形状) 向量 24B | type==13 单位子对象数组 {data@+296, cap@+304, count@+308, alloc@+312} (**type13 = CRailwayGun 铁路炮** — sub_140E87E70 写 `&CRailwayGun::vftable` 且 sub_140BF8B50(a1,13,a2); 类型号分派 sub_141A949B0 case 13 → sub_1410E6290; 增删 sub_140E79B10 case 13 push 本数组; 删除摘除同 sub_140E7FA10) | | 不序列化 (定案) |
| +320 | uint32 向量 24B | strategic_province_location u32 token 数组 {data@+320, **cap@+328**, count@+332, **alloc@+336**} | **块键 = 10230 (定案)**; AddStrategicLocation 断言 "…already exist in province: %d" + 置 mapdata+5984=1 | **GUI: 省侧战略位置行** (sub_1417507F0 → strategic_locations_grid) |
| +344..+367 | — | **保留区 (负定案)** — 24B 无写者无消费者: 1.19.3 province.cpp 方法群内零读写, ctor (sub_140E78EC0/sub_140E79050) 在 +336 与 +368 之间整段跳过 (非「填 0」) | | 定案 (负) |
| +368 | CCombat* 向量 24B | **在场战斗数组** {data@+368, cap@+376, count@+380, alloc@+384} — 8B CCombat* 元 add-unique (combatmanager sub_140BB77E0 建战斗后 sub_140E797F0 插入) | | 不序列化 |
| +392 | tag_id | controller | 控制国, 写门 (writer 0x140E81390) = `*(p+392) > 0 && tid != dctl && (!tid \|\| !dctl \|\| !同国(tid,dctl))`; dctl = rp(p+192) 有则 +200 否则 sub_140BB3E00 默认槽, 同国 = sub_140BB52F0 → **gs+832**(=qword 索引 104) 映射表 [tid]==[dctl] (tag 别名对, KR 傀儡 D04 两槽实证); 0x283F; loader case 10303 → **SetController sub_140E801A0** 对接 country 族 Add/RemoveControlledProvince; 两效果类 Execute 直调 | **GUI: 省名占领着色/+TAG 后缀** (sub_14174C8E0 → STATE_PROVINCE_NAME_OCCUPIED_COLOR/STATE_PROVINCE_PLUS_TAG) **+ 外交/密码 SetTarget 转发键** (DiplomacyView[11] / AgencyView[11] / OccupationView[11] 同链) |
| +400 | CBuildingStatus 内嵌 112B | buildings (+400..+511, 见 4.14.1) | vtable 0X2999050; dtor sub_141171C10(a1+400) | **GUI: 省建筑行** (可见性门 def+8==19649 rail_way / +802 / +824 / +883·+885 DLC; sub_14174DD50 → province_building_entries) |
| +504 | uint8 | prov+504 类别旗 (= CBuildingStatus+104 门位; ctor 默认 5) | — | 定案 |
| +512..+519 | — | **纯尾部填充 8B (负定案)** — 双 ctor + reader + 方法群三路零写点 | — | 定案(负) |

> SetController (sub_140801A0 级联 — 定案链, province.cpp:394 "Call NotifyControllerChanged"):
> 门 = `*(prov+392) == 新tag` → 近空转; a4=0 轻路径仅对旧/新两国置 `cc+4320 |= 0x40` 脏位;
> a4≠0 重路径 (进省登记热路径实测走此支) 全级联: 旧国 controlled_provinces 摘除 / 新国加入 →
> 受影响国集 (州+112 表 48B/条构建, 旧+新+相关 tag 去重) 逐国 sub_14070AF30 → 省+24 监听派发 →
> 五处虚槽广播 → **区域连通维护 sub_140CF6FA0** (areas.cpp:909/967 Join/AddProvince) **→ 标脏
> sub_140CF7AC0 → 脏集同步冲刷 sub_140CF81C0** (脏国 <4 串行 / ≥4 起 tbb 并行 sub_140CEFEC0,
> functor = CInitEnemiesAreaThreaded: 每国敌区派生缓存 失效 sub_140CF36A0 - 重建
> sub_140CF6140/sub_140CF4580 - 回注册 sub_140CF6D70) → 战区/前线通知 sub_14132C0F0 →
> 驻军档位 / 命中该省的行军师处置 / 占领 bundle 包夹 (sub_140EED690/sub_140EF2F30) →
> a3 门州级刷新 sub_1409DFC20 → a4 门州+184 国表逐国前线刷新 sub_140E7FCA0。

#### 4.14.1 CBuildingStatus (内嵌 112B, prov+400 相对)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | vt | 0X2999050 (CBuildingStatus::vftable, dtor 直读) | |
| +8 | CBuildingListener 向量 | 32B 条数组 {data@+8, cap@+16, count@+20, alloc@+24} (**元素 = 建筑监听者登记条目, 类族 CBuildingListener** — RTTI 直证 vt 0x142A206C0; 元素 ctor sub_141171A60, +16 挂 `CPdxHybridInlineBufferAllocator<CBuildingListener*,128,int>` (sub_141171D70); push sub_141179150; 销毁 sub_141171BA0) | 定案 |
| +32 | uint32 向量 24B | **def→槽 index 重映射** {data@+32, cap@+40, count@+44, alloc@+48} — u32 槽号或 −1, 按 building def+736 索引 | find-or-add sub_141172EB0 |
| +56 | 匿名结构 (NNB 形状) 向量 24B | **CBuilding\* 元素数组** {data@+56, cap@+64, count@+68, alloc@+72} | |
| +80 | 匿名结构 (NNB 形状) 向量 24B | **建筑修正来源数组** {data@+80, cap@+88, count@+92, alloc@+96} — 8B CBuilding\* 元 (= prov+480/+492; 州修正重建 sub_1409D54A0 逐元取 CBuilding+88 CModifier 入州 +1544 块) | 定案; **GUI: 建筑修正图标来源** (sub_14174C6F0 省侧分支 → building_modifiers_ico) |
| +104 | uint32 | **类别旗位掩码** (= prov+504; ctor 置 5 = bit0\|bit2) | 位语义见下二表; 定案 (探针 50 样本 + 三函数直读) |
| +108 | uint32 | **所属 id 副本**: bit0=1 → **省 id** (探针 25/25 逐个等于 prov+164) / bit0=0 → **州 id** (探针 12/12 等于 st+88; 消费 = sub_141177080/450 按 id 查省/州) | 定案 |
| +112 | int32 | **内联控制器 tag 槽**: ≤0 = 无 → sub_141176D70 回落查省+392/州+204 的 controller; >0 = 直接返回 &+112 作为「有效控制器 tag 指针」。本档 50 样本全 0 | 定案 (代码语义) / 推定 (业务名) |

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
| +72 | int64 | partial_health | 键 0x487F | |
| +80 | int64 | repair_speed_factor | **≠100000 (1.0) 才写** (键 0x3D2E; ctor 默认 100000) | |
| +88 | CModifier 内嵌 192B | 建筑修正子对象 (州修正重建 sub_1409D54A0 消费它) | ctor vt 直读 | 定案 |
| +176 | MSVC 串 | 建筑名副本 (拷自 def+528) | | 定案形态 |
| +280 | CModifier 内嵌 | 第二内嵌修正 (+296 容器) | | 高置信 |
| +368 | MSVC 串 | 第二串 (同拷 def+528) | | 高置信 |
| +472 | CBuildingStatus* | CBuildingStatus 容器回指 | AddBuildings 查 *(elem+472) | 定案 |
| +480 | CProvinceBuildingItem* | building def 回指 (ctor a3) | | 定案 |
| +488 | uint16 | 待加等级计数 (AddBuildings `+= WORD2(条)`) | | 高置信 |

SetLevel = sub_1410DC4E0 (CBuilding::SetLevel, 中央级变通知器, 定案):
building.cpp:138 负值/145 超上限/151 陆锁港三断言; 写 +64, healthy 调整 (升
+Δ; 降 min(healthy,new), 相等清 +72 partial_health) → sub_1410DC1C0 重建双
CModifier (pairs +104/+296 ← def+288/def+96 × healthy) → sub_14195F510 (gs 槽[126]
数组+8 监听) → sub_141178A10 (status 通知) → flag=1 再加 def+868 旗 →
sub_1410A8A40(cc+4344 CRadarsPool 按州登记条目, §4.3; 条目 112B, 门 = 州
控制者==本国 ∨ 同盟) → sub_1407042D0(国, building, 旧级) (cc+4952
逐建筑型等级计数 += Δ + cc+4320 |= 2 修正重算脏位) → 州侧 sub_1409DB480
(门 = 建筑类别旗 sub_14060CF80(building+104) 假 → sub_1409D54A0 州生效修正重建
st+1544 块 + sub_1409E02C0)。施工推进链与触发时序见 §4.8.5a; 修理恢复
sub_1410DAFD0: healthy<level 时 partial(+72) += amount 钳 1e7, 满 → partial=0、
healthy+1、**+80 repair_speed_factor 复位 1e5**、通知 kind=4 (定案)。

**州建筑容器 (州对象同构)**: 容器 vtable 0X2999050 同布局 (state_buildings API 用)。州建筑元素
与省建筑元素同类同 writer (元素 vt 0x14298A7B8 slot[2] = 0X1410DCCA0; 容器链
CState 0X1409E0E90 → 0X141179440; 块键 = 建筑 token@元素+8); repair_speed_factor
行 (i64@+80, ≠100000 才写) 州侧同样适用 (实测 489 州炼油 0.69188 / 116 基建 0.5)。
⚠ 对象层 state_buildings reader 含 +80 读取 (与 province_buildings 镜像)。

#### 4.14.3 省静态描述符 (CMap+616 元素指向的对象)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +20 | uint8 | 脏/待重建旗 (CProvince vt 槽[12] sub_140E7EE30 置 1) | 高置信 |
| +112 | 匿名结构 (48B 形状) 向量 | **邻接表** {data@+112, count@+124} — 48B 条 (元素布局见下表), 邻省 id u32@条+8 (断言 "…over 256 neighbors", 界 255; 湖泊自动控制者 sub_140E7FCA0 遍历; 省级寻路 A* sub_140E2BDF0 消费; 海峡封锁判定 sub_140E2B7D0) | 定案 |
| +152 | 匿名结构* | **必需规则对象** (≠0 → GUI province_required_rule 图标显示; 消费 sub_14174C500) | 高置信 |
| +168 | CTerrainType* | **地形 def 指针** (§4.26.7; 唯一写点 = 装载期 map.cpp:1373 区描述符构造循环, definition.csv Terrain 列按名查 terrainDB; 运行期零写点 — 53 读点全量核验均为读形态, `reload terrain` 只重建位图不重指描述符; 换控制权不动地形) | 定案 |
| +192 | uint32 | **海军/贸易代价底价** (A* 代价 = 100000×(v+1); 海军运输与贸易省图两实例共用; 像素权重归一上界亦取 max(+192)) | 定案 |
| +196 | uint32 | 省 id (prov+164 = *(desc+196) 互证) | |
| +200 | uint32 | **陆海配对省 id** (贸易陆↔海上岸配对 + 边评估核对比; 沿海省才非 0) | 定案 |
| +208 | uint16 | **陆块编号** (land mass BFS sub_140A5E3A0; 海省 0; impassable 边断开; "Calculated N land masses") | 定案 |
| +210 | uint8 | **旗字节**: bit0 = 脚本 is_land (海军移动断言链; ⚠ 与 CMap+568 数组**语义不同**: 湖泊/内陆水域在此为 0, CMap 侧为 1 — 13,494 省全量双读 111 例差异全属此类, 非缺陷); **bit1 = 湖泊/内陆水域旗** (高置信; 海峡封锁仅 bit0∧bit1 双 0 的海省可被舰队封锁); **bit2 = 岛屿旗** (定案; setter sub_1414089A0: 陆省且邻接表无非-sea 型边通向陆邻 → 置位, 装载尾遍历); **bit3/bit4 = coastal 双面旗** (定案; 陆侧/海侧由 bit0/1 分派, bitmap 邻接与 definition.csv 海岸分歧时以 bitmap 为准) | bit0/2/3/4 定案 / bit1 高置信 |

邻接表 48B 条目布局 (装载 = **位图邻接计算真体 sub_140A5DDC0** (4-邻接双向建边 + X 交叉检测 + 岛屿旗尾遍历; 勘误: 原记 sub_140A653D0 系 ThreadedPostPostRead **总编排器** — 五 pass: bbox→邻接→沿海调和(bitmap 优先, setter sub_14140A6A0)→像素重对齐→像素权重) → adjacencies.csv 增补进 CMap+16 12B 表 (仅非自然邻接对, 边型 sea=1/river=2/river_large=3/impassable=4) → 逐边 sub_14140A5D0 回填; 陆块编号 BFS sub_140A5E3A0 写 **desc+208 u16**; 运行期不可变, 唯一重建 = `reload straits`):

| 条目+N | 类型 | 名称/语义 |
|---|---|---|
| +0 | CAdjacencyRule* | 边挂规则指针 (0 = 无规则; §4.14.8) |
| +8 | uint32 | 邻省 id (查找键) |
| +12 | uint32 | through 省 id (海峡/运河水域名) |
| +16 | uint8 | 边型: 0=canal/默认 · 1=sea · 2=river · 3=river_large · 4=impassable (≠4 可通; 补给 Dijkstra 对 2/3 型加罚 qword_143336970) |
| +17 | uint8 | 画线禁用旗 (GUI 连线生成跳过) |
| +24 | u64 | 边基础通行代价 (A* g-cost 累加源, 战略部署时 ÷ 速度; = 0 边不可用; 写点未逐行定位) |
| +32 | int32×2 | 第二坐标对 (连线另一端, −1 = 无) |
| +40 | int32×2 | 第一坐标对 (start/stop 按方向; adjacencies.csv 六坐标列) |

#### 4.14.4 CMap 边界 (map.cpp 方法群 0x140A4D000 起; 断言族 0x140A5DDC0–0x140A66750; 单例 qword_143339D28, sizeof 0x840 = 2112B; ctor sub_140A5AEC0 / 清理 sub_140A5B5A0 / 定义装载 sub_140A64720; CMap this 相对)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | 匿名结构 (12B 形状) 向量 24B | **海峡/邻接追加表** {data@+16, cap@+24, count@+28, alloc@+32} — **12B 条 {from, to, through} u32×3** (straits loader "no straits will be loaded" / "Adj between … is not adjacent with THROUGH ="; 仅非自然邻接对入此表, 与 desc+112 全量邻接表分属两层) | 定案 |
| +536 | uint32 向量 24B | **CAdjacencyRule\* 注册表** {data@+536, cap@+544, count@+548, alloc@+552} — loader sub_140A61970 解析 adjacency_rules.txt (查重双处: **1130/1132 = required 省侧 → 挂 desc+152; 1148/1150 = icon 省侧 → 挂 desc+160**; icon 省 id 存于 CAdjacencyRule+40); 规则布局见 §4.14.8 | 定案 |
| +560 | uint32 | 省表界 (= gs+700 互证) | |
| +564 | uint32 | 非海省数 (land+lake+unknown; 类型旗 land=2/sea=4/lake=8/unknown=1) | |
| +568 | u32 数组 | 省号→紧凑 id 重映射 (4B×省数, 初值 −1; 构建器 sub_140A5F1F0) | |
| +592 | u32 向量 | 非海省省号列表 {d@592, cap@600, c@604, alloc@608} (+564 = 其计数) | |
| +616 | 匿名结构 (NNB 形状) 向量 24B | **省静态描述符 8B 指针数组** {data@+616, **cap@+624, count@+628**, alloc@+632} — ⚠ 元素是指针 (增长码 `8LL*count` memcpy 铁证) | 定案 |

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
0X140E922A0; dtor 0X140E92750): +8 = 省静态描述符* (§4.14.3 +184 描述符桥; 省 id 取 desc+196) / +16 = 指回省体内 +400 块
back-ref / +24 = railway 模板 def (断言 "_pStatus->IsValidTemplateInLocation(RailwayTemplate)"
railway_manager.cpp:0x1)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +24 | CBuilding* | 铁路建筑 (i16 level@+64 > 0 = 已建运营; sub_140E29CA0 双省连通谓词, 前置门 = prov+184 描述符 desc+210 bit0 可通铁路位) | — |
| +32 | uint32 向量 24B | rail_way 等级数组 {d@32, cap@40, c@44, alloc@48} — 等级 u32 数组按邻接表序 (多线并存每线一级; SSE max = 省有效等级 → 州面板铁路行 row+1336; row+40 = rail_way def, row+1340 = dword_1433349D8) | c>0 → 单行 |
| +44 | uint32 | 上行数组计数 | c>0 → 单行 |
| +56 | uint32 向量 24B | 邻接边二分查找表 {d@56, cap@64, c@68, alloc@72} — 8B 对 {province u32@0, level u32@4} 按省 id 排序 (runtime cache; sub_140E92D00 二分, 断言 MAX_RAILWAY_LEVEL = dword_1433349D8) | 不序列化 |
| +68 | uint32 | 上行边表计数 | 不序列化 |
| +80 | 匿名结构 (16B 形状) 向量 24B | rail_way_construction {d@80, cap@88, c@92, alloc@96} — 16B 条 {邻省 u32@0, 进度 fixed×1e-5 i64@8}; **非空 = 施工中 (阻断语义由此表达, 非 +104)** | c>0 |
| +92 | uint32 | 上行 construction 容器计数 | c>0 |
| +104 | uint32 | **cooldown** (tok 14622; writer sub_140E95DD0) — 单标量**无位段** (阻断由 +80 非空表达); **消费 = 铁路炮省图 A\* 路径阻断位** (sub_140E87390 族: cooldown==0 才可通行) | >0 |
| (无此槽) | — | 悬停链 sub_1410DB850 的 a1 = **CBuilding** (+472 = CBuildingStatus\* 回指, §4.14.2), 经其 +104 门/+108 省 id 还原省/州 — 本类 112B 无 +472 | — |

#### 4.14.7 CRailwayManager (gs+992)

| 项 | 值 | 语义 |
|---|---|---|
| 管理器 | `M = *(gs + 992)` (vtable 0X2972CD0 guard; manager writer 0X140E95EF0) | |
| 槽数组 | {data@M+8, slots u32@M+20} | 元素 = CProvinceRailwayInfo* (0x70 字节, vtable 0X2972C80 guard); 非空槽才写省号块 |
| 顶格 cooldown | u32 数组 {d@M+32, c@M+44} | c>0 才写 (0X1401B3D80 单行) |
| 省反查 | 省静态描述符指针@info+8 → 省 id = ru32(desc+196) (CProvince+164 才是 id; §4.14.6 +8 同判) | |

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

#### 4.14.8 CAdjacencyRule (邻接规则对象; 注册于 CMap+536)

ctor sub_141546970; 源 adjacencyrule.cpp (断言串 :160/:219 直证); 规则名 (如 SUEZ_CANAL) 来自 adjacency_rules.txt。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8..+11 | uint8×4 | **四态权限位掩码**: [0] contested / [1] enemy / [2] friend / [3] neutral; 每字节 4 位 = army(&1)/navy(&2)/submarine(&4)/trade(&8) (ctor 全 0xF) |
| +16 | uint32 向量 24B | required_provinces u32 数组 {data@+16, cap@+24, count@+28} (SUEZ = 12049 1155 4073 9947) |
| +40 | uint32 | ctor = −1 |
| +56 | MSVC 串 32B | 规则名 (straits loader 名匹配) |
| +88 | CCustomOverrideTooltipTrigger 内嵌 | **is_disabled 触发器** (命中 → 状态码 −1 全禁 + tooltip 自定义文案 PERMISSION_BLOCKED_DUE_TO) |
| +108 | uint32 | adjacency_check 调试门 (>0 才开评估日志) |
| +248 | 88B 组 | enemy 触发器组 (定义旗@+268) |
| +336 | 88B 组 | friend 触发器组 (定义旗@+356) |
| +424 | 88B 组 | neutral 触发器组 (定义旗@+444) |

**评估核 sub_141547440(rule, countryHandle, REASON\*) → 状态码**: ① is_disabled 触发器 (槽[3] Evaluate) 命中 → **−1** (全禁, REASON = 触发器 tooltip); ② contested 判定 sub_141548680 — required_provinces 两两控制者 (province+392, 别名归一 sub_140BB5490) 处于战争 → **0**; ③ enemy 组命中 → **1** / friend 组命中 → **2**; ④ 三选二消歧: enemy∧friend 定义未命中 → 3 (neutral) / enemy∧neutral 未命中 → 2 / friend∧neutral 未命中 → 1; ⑤ 兜底 sub_1415478F0 = required_provinces 控制者 vs 过路国关系 (交战 → enemy, 盟友/军通 → friend, 否则 neutral; 已定义组未命中时降 neutral/enemy)。**位掩码取值 sub_141548590 = &rule[8+code]**, code=−1 → 静态字节 byte_14338A8AE (低 4 位清 0) = 全禁 — 「关海峡/运河」唯一机制 = is_disabled 触发器。

| 谓词门 | 掩码 | 语义 |
|---|---|---|
| sub_141546B40 | &1 | army 可通行 |
| sub_141546CC0 | &2 | navy 可通行 (海军寻路 0x140D65D60/0x140D67AA0/0x140D51360/0x140D539A0; 补给海军可达性 0x140FB3520/0x140FB7950) |
| sub_141546C90 | &4 | submarine 可通行 (同上族) |
| sub_141546CF0 | &8 | trade 可通行 (0x140CAA1B0 海路节点 / 0x140CB47B0 adjacency.tick 每日巡检 / 0x1412D9890 双端校验) |
| sub_141546B70 | 参数分派 | EAdjacencyRuleSubject 0=army/1=navy/2=sub/3=trade (未识别枚举告警 + 放行) |
| sub_141546D20 | 单位自适应 | type 0/13 (陆/铁路炮) → &1; type 1 (海) → 潜艇判定 sub_140D74180 真 → &4 否则 &2; A* 逐边门 sub_140E2B980 与 CUnit[16] 移动校验核 0x140BFA300 均经此 |
| sub_141547EF0 | 全量 | GUI 描述版 (评估 + REASON + 四行权限表, CAdjacencyRuleIcon 族 tooltip) |

调度: 规则集 = 静态数据, 每次判定全量跑触发器组 (无缓存); 宣战不重建邻接结构, 只改触发器求值结果与 required_provinces 控制者; 运行期唯一重建 = 控制台 `reload straits`。

**海峡舰队封锁 sub_140E2B7D0** (unit, 48B 邻接条目, 严格旗) = (码==2) ∥ (严格旗 ∧ 码==3), 码 = sub_140E2A110(国家句柄 unit+480, 条目): ① 非 sea 型边 (条+16≠1) 或无 through 省 → 1 不适用; ② through 省陆地/湖泊 (desc+210&3≠0) 或无单位 → 4 通行; ③ 扫描省上海军 (type 1, 属主交战, 有船 ∧ 非撤退 (+524≤0) ∧ 非驻港 (+884==0) ∧ 非潜艇) → ④ 敌舰队对过路国情报级 0 (country_intel 无条目) → **3 软封锁** / 有情报 → **2 硬封锁**。三个调用点全部严格旗=0 (只认硬封锁): 移动推进 sub_140C01DC0 (封锁 → sub_140BFB4A0 取消移动, "Cancel movement: strait blocked." unit.cpp:2710) / 海域加权选址 0x140BFD700 / 0x140DFDEA0。A* 路径缓存 sub_140E29E90 记硬封锁位 (a2[4]=1) 与规则位并列双门。**舰队封锁不进补给段** — 补给海军可达性只用规则位 &2/&4; 规则 is_disabled (码 −1) 同时砍补给与贸易通道。


#### 4.14.8a 寻路系统 (省图 A* 家族与 pathfind.h 模板族)

**CPathFind 请求结构** (pathfind.cpp 主省图 A* sub_140E2BDF0 消费, 16 字段) 与**省图 A* 三件套数据结构**: 24B 节点 / 位图 / 16B 堆元; 无 decrease-key (惰性重推); 输出不含起点 (sub_140E29990 重建序)。启发式 = 欧氏 ×(0.5 战略部署 / 1.25 常规); 环绕宽 = CMap+64。**own 州跳过** = 请求国有效且当前省默认控制者 (州 owner)==请求国 → 不展开 (主移动链传中立 tag 故常关; 启用面未穷举)。战略部署代价 = 100000×边价/(LAND_SPEED_MODIFIER×两省速度/100000), 溢出钳 0xFFFFFFFF。型 5 过境倍率 dword_1430B1654 = 静态 4; 敌境 ×2。**边评估全局缓存**: 键 = 省 id 对异或散列 (sub_140E29540, 常数 73244475), 开关 byte_1430B1650 (setter sub_140E2CBF0)。**单位路径总分派器 sub_1412342D0**: type13→铁路 A* sub_140E89760; 令旗 81..85 → 型 1/3/2→0/2/缺省; 恒传中立 tag。

**pathfind.h 模板族** (三图源 × 谓词-代价-完成三回调契约) 18 实例业务表:

| 函数 | 图源 | 业务 |
|---|---|---|
| sub_140E2BDF0 | 省图 | 主移动 A* (型 0..5 边检查) |
| sub_140E2CC50 | — | CPathFind 请求校验器 |
| sub_140C6B530 | 省图 | CArmy::[52] 谓词目标 Dijkstra (own 领地内找 CanEnterProvince ∧ prov+168 set 空) |
| sub_140C9DBD0 | 州图 | 多源 A* (贸易快检 sub_140CA7990 内芯) |
| sub_140E87390 | 省图 | 铁路炮 A* (铁路边 = CProvinceRailwayInfo 等级>0 ∧ cooldown==0 ∧ 已建) |
| sub_140E8F890 | 省图 | 海军运输航路 (全回调版) |
| sub_141024800 | 战略区图 | 海军令区路径 (代价 = 区+224+1) |
| sub_141023E30 | 省图 | 海况代价版 (基价 = desc+192+1, 位图 bit2 ×8/其他 ×2) |
| sub_1410235F0 | 省图 | 位图门版 (bit3 = 海军可行) |
| sub_1412D7C90 | 省图 | 贸易 A* (陆↔海只经 desc+200 配对省) |
| sub_140FA6AE0 | 战略区图 | 补给海军可达 (谓词 sub_140FB3520 — 同函数兼区图 A* 边谓词) |
| sub_140F3BEE0 | 省图 | 无过滤版 (跳价 1.0, 途径点分段拼接) |
| sub_1414AA600 | 省图 | AI 前线令 (敌威胁三档分母 8e6/5e6/2e6) |
| sub_1419ADFF0 | 省图 | 空军任务路径 (基价 100.0, 敌控 ×2/×10, 补给节点 ×0.75) |
| sub_141B68700 | 区图 | CStrategicRegionNudger 编辑路径 |
| sub_141A75000 | 省图 | AI 志愿军令 |
| sub_141A076C0 / sub_141A07F70 | 省图 | AI 前线纯陆 / 陆→海目标 (登陆路径) |

CStrategicRegion 增补: +176 邻区指针数组 / +188 计数 / +224 代价权重 / +240 位置 qword 对。
