

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
| +0 | vtable | CProvince 主vtable | — | 定案 |
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
| +200 | CStrategicRegion* | **无州省名源对象 = 战略区指针** (GetName: 无州且 +200≠0 → 其内嵌串, 为空 → "PROV<id>"); **其 +88/+96 双存区数字 id** (探针全 276 区逐一对值恒相同; writer 写 +96, 消费端 +88/+96 双读皆通; 旧「当前天气 id」误 — 天气链实为 **区 id → gs+1672 天气管理器查键**) | 探针 vtable 0X296D558 直证; GUI: 天气修正 tooltip | |
| +208 | CControllerArea* | **面/战区节点 = 前线控制区回指** (CControllerArea 洪水分组键 = 省+392 controller, 注册 CCountry+1352; 兼 theatre 隶属查询键与面级寻路 A* sub_140CF3B20 消费 (+40 = 面首省); 完整布局 §4.24.2) | | 不序列化 (定案) |
| +216 | COwnerArea* | **owner area 回指** (所有者区双类体系: COwnerArea 洪水分组键 = 州+200 owner, 注册 CCountry+1376; setter sub_140E810E0; 完整布局 §4.24.2) | | 不序列化 (定案) |
| +224 | 匿名结构 (8B 形状) 向量 24B | **在场单位本体数组** {data@+224, cap@+232, count@+236, alloc@+240} — 8B 元全类型 (AddUnit sub_140E79B10 首支恒插; combatmanager 遍历建战斗) | ⚠ AI 前线窗口按 count(+236)−1 作该省接收预算消费 (ai_general 战区巨函; 消费形态定案, 字段语义待裁) | 不序列化 |
| +248 | 匿名结构 (NNB 形状) 向量 24B | type==1 (海军) 单位子对象数组 {data@+248, cap@+256, count@+260, alloc@+264} (陆省无港断言 "Trying to move navy to land province with no port!"); 删除摘除 = CProvince::RemoveUnit sub_140E7FA10 (§4.18.20) | | 不序列化 |
| +272 | 匿名结构 (NNB 形状) 向量 24B | type==0 (陆军) 单位位置对象数组 {data@+272, cap@+280, count@+284, alloc@+288} (tooltip 在场单位显示消费); 删除摘除同 sub_140E7FA10 | | 不序列化 |
| +296 | 匿名结构 (NNB 形状) 向量 24B | type==13 单位子对象数组 {data@+296, cap@+304, count@+308, alloc@+312} (**type13 = CRailwayGun 铁路炮** — sub_140E87E70 写 `&CRailwayGun::vftable` 且 sub_140BF8B50(a1,13,a2); 类型号分派 sub_141A949B0 case 13 → sub_1410E6290; 增删 sub_140E79B10 case 13 push 本数组; 删除摘除同 sub_140E7FA10) | | 不序列化 (定案) |

**铁路炮分配者** (railway_gun_assignee.cpp 两函, 0x14193E130 Assign / 0x14193E380 Unassign; 真类名待裁 — RTTI 未证, 名取自源文件): 容器 {数据 (qword 元 = 铁路炮指针) +8 / 容量 +16 / 计数 +20 / 分配器 +24, 1.5 倍增长}。Assign 前置断言 railway_gun_assignee.cpp:13 "IsRailwayGunAssigned( pRailwayGun ) == false" → 追加 + 尾调**本类 vtable[1] 通知钩子**; Unassign 前置断言 :20 "IsRailwayGunAssigned( pRailwayGun )" → 线性查找前移压缩删除 + 尾调 vtable[2] 通知钩子。挂接契约 = **派生类覆写槽 [1]/[2]** (零引擎调用零存档面)。**挂接拓扑**: 子对象**内嵌于 CArmyGroup/COrdersGroup 族宿主 +24**; 三调用点 (sub_140E8EE90 入组 Assign / sub_140E8EF60 解挂 + sub_140E8F1F0 = CUnassignRailwayGunFromOrdersGroup::Execute Unassign, §4.33) 均传「宿主+24」; §4.18.2 CRailwayGun+1088 即指向该子对象, 与 +1080 id 对 fallback 双路径互证。Unassign 压缩循环对尾部区间内**所有**匹配元素去重 (不只删首个), 且逐次重读 count@+20。vtable[1]/[2] 的派生类覆写仍未定位 (vtable 数据不在语料)。
| +320 | uint32 向量 24B | strategic_province_location u32 token 数组 {data@+320, **cap@+328**, count@+332, **alloc@+336**} | **块键 = 10230 (定案)**; AddStrategicLocation 错误报告 (非断言, sub_1424C8950/C8E60 格式化 — 措辞精化) "…already exist in province: %d" + 置 mapdata+5984=1; 尾调 AddBuildings = 战略位置 token 与附带建筑组一体落地 (locdef buildings 数组直送) | **GUI: 省侧战略位置行** (sub_1417507F0 → strategic_locations_grid) |
| +344..+367 | — | **保留区 (负定案)** — 24B 无写者无消费者: 1.19.3 province.cpp 方法群内零读写, ctor (sub_140E78EC0/sub_140E79050) 在 +336 与 +368 之间整段跳过 (非「填 0」) | | 定案 (负) |
| +368 | CCombat* 向量 24B | **在场战斗数组** {data@+368, cap@+376, count@+380, alloc@+384} — 8B CCombat* 元 add-unique (combatmanager sub_140BB77E0 建战斗后 sub_140E797F0 插入) | | 不序列化 |
| +392 | tag_id | controller | 控制国, 写门 (writer 0x140E81390) = `*(p+392) > 0 && tid != dctl && (!tid \|\| !dctl \|\| !同国(tid,dctl))`; dctl = rp(p+192) 有则 +200 否则 sub_140BB3E00 默认槽, 同国 = sub_140BB52F0 → **gs+832**(=qword 索引 104) 映射表 [tid]==[dctl] (tag 别名对, KR 傀儡 D04 两槽实证); 0x283F; loader case 10303 → **SetController sub_140E801A0** 对接 country 族 Add/RemoveControlledProvince; 两效果类 Execute 直调 | **GUI: 省名占领着色/+TAG 后缀** (sub_14174C8E0 → STATE_PROVINCE_NAME_OCCUPIED_COLOR/STATE_PROVINCE_PLUS_TAG) **+ 外交/密码 SetTarget 转发键** (DiplomacyView[11] / AgencyView[11] / OccupationView[11] 同链) |
| +400 | CBuildingStatus 内嵌 112B | buildings (+400..+511, 见 4.14.1) | vtable 0X2999050; dtor sub_141171C10(a1+400) | **GUI: 省建筑行** (可见性门 def+8==19649 rail_way / +802 / +824 / +883·+885 DLC; sub_14174DD50 → province_building_entries) |
| +504 | uint8 | prov+504 类别旗 (= CBuildingStatus+104 门位; ctor 默认 5) | — | 定案 |
| +512..+519 | — | **纯尾部填充 8B (负定案)** — 双 ctor + reader + 方法群三路零写点 | — | 定案(负) |

> SetController (sub_140E801A0 级联 — 定案链, province.cpp:394 "Call NotifyControllerChanged"):
> 门 = `*(prov+392) == 新tag` → 近空转; a4=0 轻路径仅对旧/新两国置 `cc+4320 |= 0x40` 脏位;
> a4≠0 重路径 (进省登记热路径实测走此支) 全级联: 旧国 controlled_provinces 摘除 / 新国加入 →
> 受影响国集 (州+112 表 48B/条构建, 旧+新+相关 tag 去重) 逐国 sub_14070AF30 → 省+24 监听派发 →
> 五处虚槽广播 → **区域连通维护 sub_140CF6FA0** (areas.cpp:909/967 Join/AddProvince) **→ 标脏
> sub_140CF7AC0 → 脏集同步冲刷 sub_140CF81C0** (脏国 <4 串行 / ≥4 起 tbb 并行 sub_140CEFEC0,
> functor = CInitEnemiesAreaThreaded: 每国敌区派生缓存 失效 sub_140CF36A0 - 重建
> sub_140CF6140/sub_140CF4580 - 回注册 sub_140CF6D70) → 战区/前线通知 sub_14132C0F0 →
> 驻军档位 / 命中该省的行军师处置 / 占领 bundle 包夹 (sub_140EED690/sub_140EF2F30) →
> a3 门州级刷新 sub_1409DFC20 → a4 门 (prov+192 存在) 遍历 desc+112 邻接表逐邻省调 sub_140E7FCA0 自动控制者重选 — 分派 = 湖泊邻省 (desc+210 bit1) 全票 (a2=0) / impassable 邻省 (stateDef+348) 同国票 (a2=1)。

#### 4.14.1 CBuildingStatus (内嵌 112B, prov+400 相对)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | vtable | 0X2999050 (CBuildingStatus::vftable, dtor 直读) | |
| +8 | CBuildingListener 向量 | 32B 条数组 {data@+8, cap@+16, count@+20, alloc@+24} (**元素 = 建筑监听者登记条目, 类族 CBuildingListener** — RTTI 直证 vtable 0x142A206C0; 元素 ctor sub_141171A60, +16 挂 `CPdxHybridInlineBufferAllocator<CBuildingListener*,128,int>` (sub_141171D70); push sub_141179150; 销毁 sub_141171BA0) | 定案 |
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
| +88 | CModifier 内嵌 192B | 建筑修正子对象 (州修正重建 sub_1409D54A0 消费它) | ctor vtable 直读 | 定案 |
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
与省建筑元素同类同 writer (元素 vtable 0x14298A7B8 slot[2] = 0X1410DCCA0; 容器链
CState 0X1409E0E90 → 0X141179440; 块键 = 建筑 token@元素+8); repair_speed_factor
行 (i64@+80, ≠100000 才写) 州侧同样适用 (实测 489 州炼油 0.69188 / 116 基建 0.5)。
⚠ 对象层 state_buildings reader 含 +80 读取 (与 province_buildings 镜像)。

#### 4.14.3 省静态描述符 (CMap+616 元素指向的对象)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +20 | uint8 | 脏/待重建旗 (CProvince vtable 槽[12] sub_140E7EE30 置 1) | 高置信 |
| +88 | RLERun* | **行程表数组** (元 6B {x u16, y u16, len u16}; 展开得省边界像素集 — §4.14.11 几何回填 pass 与 §4.14.9 装载期两处同读法; RLE 由 bbox pass GenerateBoundingBoxes sub_140A5F7B0 生成) | 定案 |
| +88 | uint32 | 所属战略区模板 id (IsPointInRegion sub_1415A5A90 尾 region_id == *(desc+88) 唯一语义消费; §4.25.9) | ⚠ 与上行同偏移读法冲突, 待裁 |
| +100 | i32 | 行程表条目数 (几何回填 pass 循环界, 与 +88 配对) | 定案 |
| +112 | 匿名结构 (48B 形状) 向量 | **邻接表** {data@+112, count@+124} — 48B 条 (元素布局见下表), 邻省 id u32@条+8 (断言 "…over 256 neighbors", 界 255; 湖泊自动控制者 sub_140E7FCA0 遍历; 省级寻路 A* sub_140E2BDF0 消费; 海峡封锁判定 sub_140E2B7D0) | 定案 |
| +136..+148 | i32×4 | **bbox {min_x, min_y, w, h}** (x_max = +136 + +144; 中心计算 sub_1415A4770 与点测 sub_1415A6420 消费 — §4.25.9; 与邻接装载 bbox pass 呼应; 点测算式 = x≥+136 ∧ y≥+140 ∧ x≤(+136++144) ∧ y≤(+140++148); 省号 1 基直索引 CMap+616 数组, 越界/0 号回退元素 0, count@+628 为界) | 高置信 |
| +152 | 匿名结构* | **必需规则对象** (≠0 → GUI province_required_rule 图标显示; 消费 sub_14174C500; 州面板 tooltip #16 支第二消费 = 名 (rule+56 SSO, cap@+80) + 双描述 sub_141546FA0 主 / sub_141546FC0 副, dg032) | 定案 |
| +168 | CTerrainType* | **地形 def 指针** (§4.26.7; 唯一写点 = 装载期 map.cpp:1373 区描述符构造循环, definition.csv Terrain 列按名查 terrainDB; 运行期零写点 — 53 读点全量核验均为读形态, `reload terrain` 只重建位图不重指描述符; 换控制权不动地形) | 定案 |
| +184 | i32×2 | **省位置 {x, y}** (寻路启发式欧氏距离消费点; 邻省择优中心坐标源 (§4.34.36, ×1e5); x 环绕修整宽 = CMap+64) | 定案 (pathfind.h 访问器族) |
| +192 | uint32 | **海军/贸易代价底价** (省级寻路 A* 代价 = 100000×(v+1); 海军寻路 sub_14134FCC0 以本值原样作每跳附加累加 — 两读侧形态并存; 海军运输与贸易省图两实例共用 — ⚠ 「海军运输」实例归属待复核 (§4.14.8a 表 140E8F890 行现判铁路建造), 两实例具体指向待裁; 像素权重归一上界亦取 max(+192)) | 定案 |
| +196 | uint32 | 省 id (prov+164 = *(desc+196) 互证) | |
| +200 | uint32 | **陆海配对省 id** (贸易陆↔海上岸配对 + 边评估核对比; 沿海省才非 0) | 定案 |
| +208 | uint16 | **陆块编号** (land mass BFS sub_140A5E3A0; 海省 0; impassable 边断开; "Calculated N land masses") | 定案 |
| +210 | uint8 | **旗字节**: bit0 = 脚本 is_land (海军移动断言链; ⚠ 与 CMap+568 数组**语义不同**: 湖泊/内陆水域在此为 0, CMap 侧为 1 — 13,494 省全量双读 111 例差异全属此类, 非缺陷); **bit1 = 湖泊/内陆水域旗** (定案; 海峡封锁仅 bit0∧bit1 双 0 的海省可被舰队封锁); **bit2 = 岛屿旗** (定案; setter sub_1414089A0: 陆省且位图 4-邻接 (含 X 交叉补链) 无任何陆邻 → 置位, 纯拓扑判定无面积阈值; 装载尾遍历, `!=1` 边型判据装载时恒真属防御代码, impassable 陆-陆手工边因 straits 回填时序不参与); **bit3 = 沿海陆侧旗** (land 与 lake 共用) / **bit4 = 沿海海侧旗** (sea 专用) (定案; setter sub_14140A6A0 分派键 = `(u210 & 3)`, bitmap 邻接与 definition.csv 海岸分歧时以 bitmap 为准, 仅陆省调和; 湖/海省直采 csv); bit5..7 未用 | bit0/1/2/3/4 定案; 邻省择优罚则门 (§4.34.36: bit1 置位 ∨ bit0+bit1 全清 → 罚 −25000) |
| +211 | uint8 | **大洲 id (定案)** = CStateDatabase (qword_14332F070) +88 条目数组下标 (1-based, 槽 0 Null; 条目 0x50B: 名串@+0 / 有效旗@+40 / token 主键@+44; continent.txt 7 大洲按文件序编 id 1–7, definition.csv continent 列直拷); 第一消费点 = CAIAreaDatabase::BuildProvinceAreaLookup sub_140626B90 (函数名经 gameapplication.cpp:1637 计时日志直证, 原文 "Databasee" 拼写笔误): 陆省 (desc+210 bit0) ∧ 有战略区回指 (prov+200→+88) → desc+211 ∈ 列表A ∨ 区 id ∈ 列表B; 第二消费点 = 州 category 推导 sub_140ABD860 (statetemplate.cpp:242, 同函数顺带定案州沿海旗 CStateTemplate+349) | 定案 |

邻接表 48B 条目布局 (装载 = **位图邻接计算真体 sub_140A5DDC0** (4-邻接双向建边 + X 交叉检测 + 岛屿旗尾遍历; sub_140A653D0 = ThreadedPostPostRead **总编排器** — 五 pass: bbox→邻接→沿海调和(bitmap 优先, setter sub_14140A6A0)→像素重对齐→像素权重) → adjacencies.csv 增补: **自然邻接对 = sub_14140A5D0 覆盖既有 48B 条四字段** (+12 through / +16 边型 / +40 坐标 / +0 rule, **不改 cost@+24**; vanilla 实测 101 条) / **非自然邻接对 = 双 push 新 48B 手工边 (第二坐标对 {0,0}) + CMap+16 12B 表登记** {from, to, through} (vanilla 实测 150 条) — 非自然对才登记 +16 表 (海/运河类边参与陆块连通) → 陆块编号 BFS sub_140A5E3A0 写 **desc+208 u16**; 运行期不可变, 唯一重建 = `reload straits`):

| 条目+N | 类型 | 名称/语义 |
|---|---|---|
| +0 | CAdjacencyRule* | 边挂规则指针 (0 = 无规则; §4.14.8) |
| +8 | uint32 | 邻省 id (查找键) |
| +12 | uint32 | through 省 id (海峡/运河水域名) |
| +16 | uint8 | 边型: 0=canal/默认 · 1=sea · 2=river · 3=river_large · 4=impassable (≠4 可通; 补给 Dijkstra 对 2/3 型加罚 qword_143336970) |
| +17 | uint8 | 画线禁用旗 (GUI 连线生成跳过) |
| +24 | u64 | 边基础通行代价 (A* g-cost 累加源, 战略部署时 ÷ 速度); **写点 = 装载三路径初写 0** (位图自然边 / straits 手工边 / 对角补链), **地图装载收尾 provincetemplate 几何回填 pass 再覆写为逐像素地形代价之和 ÷3 并双向镜像** (§4.14.11 — 定案); 「= 0 边不可用」读法存疑待裁 (若 0=不可用则全图边不可通, 矛盾); **0 值语义 = 默认价, 定案** (海军 A* sub_14134FCC0 读侧直证: g 增量 = ceil1e5(边成本)/1e5 + desc+192 附加 + 1, 0 成本边照常累加正 g 路径照通; §4.16.20) |
| +32 | int32×2 | 第二坐标对 (连线另一端, −1 = 无; 自然边模板 {−1,−1} vs straits 手工边 {0,0} — −1 哨兵语义并读) |
| +40 | int32×2 | 第一坐标对 (start/stop 按方向; adjacencies.csv 六坐标列) |

#### 4.14.4 CMap 边界 (map.cpp 方法群 0x140A4D000 起; 断言族 0x140A5DDC0–0x140A66750; 单例 qword_143339D28, sizeof 0x840 = 2112B; ctor sub_140A5AEC0 / 清理 sub_140A5B5A0 / 定义装载 sub_140A64720; CMap this 相对)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +16 | 匿名结构 (12B 形状) 向量 24B | **海峡/邻接追加表** {data@+16, cap@+24, count@+28, alloc@+32} — **12B 条 {from, to, through} u32×3** (straits loader "no straits will be loaded" / "Adj between … is not adjacent with THROUGH ="; 仅非自然邻接对入此表, 与 desc+112 全量邻接表分属两层) | 定案 |
| +536 | uint32 向量 24B | **CAdjacencyRule\* 注册表** {data@+536, cap@+544, count@+548, alloc@+552} — loader sub_140A61970 解析 adjacency_rules.txt (查重双处: **1130/1132 = required 省侧 → 挂 desc+152; 1148/1150 = icon 省侧 → 挂 desc+160**; icon 省 id 存于 CAdjacencyRule+40); 规则布局见 §4.14.8 | 定案 |
| +560 | uint32 | 省表界 (= gs+700 互证) | |
| +564 | uint32 | 非海省数 (land+lake+unknown; 类型旗 land=2/sea=4/lake=8/unknown=1) | |
| +568 | u32 数组 | 省号→紧凑 id 重映射 (4B×省数, 初值 −1; 构建器 sub_140A5F1F0 = **地图初始化复合**: 聚合对象构造链 sub_140A5F1F0 → sub_141543C00 → sub_1415446A0 + 装载编排 + 紧凑映射) | |
| +592 | u32 向量 | 非海省省号列表 {d@592, cap@600, c@604, alloc@608} (+564 = 其计数) | |
| +616 | 匿名结构 (NNB 形状) 向量 24B | **省静态描述符 8B 指针数组** {data@+616, **cap@+624, count@+628**, alloc@+632} — ⚠ 元素是指针 (增长码 `8LL*count` memcpy 直证) | 定案 |

#### 4.14.5 CProvinceBuildingItem 定义对象侧字段 (def 相对)

| 偏移 | 名称/语义 |
|---|---|
| +676 | 设施旗 |
| +700 | 省级等级上限 (≤0 → 双 status 规则走州 +288; >0 → 走省 +400) |
| +740 | 图标帧 |
| +808 | 自定义图标 GFX (与 +824 门槛分槽 — 点击 lambda → sub_14174AB30 开设施 program 窗; countrystateview.cpp:1624 断言; 建筑容器 = view+1416 {d@+24, c@+36}; program 查找链 sub_140BB48F0(state)+4008 → sub_140E76AE0) |
| +824 | 自定义图标门槛 (与 +808 GFX 分槽) |

省 loc 装配 = CAPACITY{level,max} + BUILDING_DAMAGED{DAMAGED,CURRENT} + 满级特殊字形。

CProvinceStrategicLocationEntry:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | CProvince* | target 省 |
| +40 | token | location token |

GFX 名 = `GFX_strategic_location_<lexer名>` 拼名; tooltip 双名 getter 再证
**CState+2048 第二 u32 = prov_id** (§4.13)。

**脚本子句 setter sub_140ABFAA0** (strategic_locations_database.cpp, 184 行, 高置信): strategic_locations 脚本数据库的子句求值入口 — 按名查建筑类型 (查表对象 +32 有效旗, 无效 → strategic_locations_database.cpp:11 "Invalid building type %s" 抛出), 右值须整数 (子句类型 id 12, 非 → :18 "Right hand side must be an integer"), 追加 `(int,int)` 8B 对到目标数组 {数据 +16 / 容量 +24 / 计数 +28 / 分配器 +32, 1.5 倍增长}; 子句描述侧: 名串 +56 (门旗 +68) / int 值 +48 (推定槽位, 待裁) / 类型 id +192。子句上下文解析 = sub_140319D60 (joker 词法域, 真名待裁)。

#### 4.14.6 CProvinceRailwayInfo (铁路/补给图节点)

**gs+992 = 铁路图容器** (定案; assert "Failed to find CProvinceRailwayInfo for
province" supply_system_utils.cpp:0x31C 直证); `*(gs+992)` 容器 +8 =
**CProvinceRailwayInfo\*[] 按省 id 直索引**。

**CProvinceRailwayInfo** (0x70 = 112B; vtable 0X2972C80; writer 0X140E95DD0; reader vtable[4] 0X140E95200; ctor
0X140E922A0; dtor 0X140E92750): +8 = 省静态描述符* (§4.14.3 +184 描述符桥; 省 id 取 desc+196) / +16 = 指回省体内 +400 块
back-ref / +24 = railway 模板 def (断言 "_pStatus->IsValidTemplateInLocation(RailwayTemplate)"
railway_manager.cpp:0x1; ctor 补: +8 ← prov vtable[+8](省id)+184 / +16 ← 省+400 / +24 ← sub_141175A30(省建筑槽, \*(CBuildingDatabase+936)) 定位或建 / +32 resize 到 desc+124 邻接数)。

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

reader token 语义 (vtable[4] sub_140E95200, 定案; 通用 Load wrapper 0X1424BE690 逐 token 分派):

| token | 名 | 行为 |
|---|---|---|
| 10765 | neighbour | **读入即弃** (块 → 平衡跳; 旧档兼容键, 无落点) |
| 14622 | cooldown | 标量直读 +104 |
| 19649 | rail_way | 读等级 u32 数组入 +32; 断言 size == 邻接数 (:48, `+44 == \*(desc+124)`) 后重建 +56 边缓存 — 来源 = **desc+112 邻接数组 (48B/条, 邻省 id @条+8), 计数 desc+124**, 仅 level>0 的边以 {邻省id, level} 8B 对插入有序表 |
| 19881 | rail_way_construction | 读 16B 对表 → 归并排序 (≤32 直插) → 整表赋值 +80 |

SetRailway 族 (定案; 断言串 :80/:94/:102/:109/:120 直证):

| 函数 | 语义 |
|---|---|
| sub_140E95870 (邻省, 新级) | 全量设级: 邻接序号查找 (sub_14140A320, 线性扫 desc+112) → `levels[idx] = max(现值, 新级)` → 越 MAX_RAILWAY_LEVEL (dword_1433349D8) 先告警 + 断言再钳位 → 同步 +56 边表 (二分改级/插入) → 首条 level>0 边确保铁路建筑存在 (+24 空时建 CBuilding, 经 sub_1410DC4E0 设级) |
| sub_140E928E0 (邻省, delta, clearProgress) | 增量变体: clamp(delta+现值, ≤MAX) 后调上行; clearProgress ≠0 时移除 +80 对应条目 (**升级完成即清施工进度**) |
| sub_140E92D00 (邻省, 进度增量, 国家) | AddRailwaysInConstruction: +80 进度累加 → 完工判 `进度 ≥ 100000×(\*(def+744) + \*(def+756)×(lv+1)) + 国家修正值` (def = \*(CBuildingDatabase+936); 修正 = sub_14055E360(cc+1464, …, \*(def+912))) → 完工则增量设级 +1 并清进度 + CSupplySystem vtable[+24](desc+196) 刷补给节点, 返 1 |

配套定案: 双省对称入口 sub_140E93090 UpgradeRailwayPair (两侧各 AddRailwaysInConstruction; 对称断言 :532/:533; 消费者 = 生产线日推进 sub_141A02660); 造价 helper sub_140E932C0 (**汇编核验**: `imul def+756 → add def+744 → imul 100000` 转定点); 运行期取 info 入口 sub_140E92860 (M+8 槽按省 id 直索引, 槽空懒建)。

#### 4.14.7 CRailwayManager (gs+992)

| 项 | 值 | 语义 |
|---|---|---|
| 管理器 | `M = *(gs + 992)` (vtable 0X2972CD0 guard; manager writer 0X140E95EF0; **[0] dtor 0X140E927F0; [3] Load wrapper 0X1424BE690; [4] reader 0X140E954B0** — 序列化槽模型同 §4.00.1) | |
| 槽数组 | {data@M+8, slots u32@M+20} | 元素 = CProvinceRailwayInfo* (0x70 字节, vtable 0X2972C80 guard); 非空槽才写省号块 |
| 顶格 cooldown | u32 数组 {d@M+32, c@M+44} | c>0 才写 (0X1401B3D80 单行) |
| 省反查 | 省静态描述符指针@info+8 → 省 id = ru32(desc+196) (CProvince+164 才是 id; §4.14.6 +8 同判) | |
| reader (vtable[4]) token 语义 | 14622 cooldown → M+32; 19649 rail_way → 逐省块循环 (读省 id, 断言 >0, 槽空 malloc(0x70)+ctor 后交 info vtable[3] Load wrapper); 其余 → 基类 0X1424BEC40 | 定案 |
| 冷却日更 | gs 日更串行 sub_1401D4810 → thunk sub_1401C6AB0(M) → sub_140E942F0: 倒序扫冷却表, info+104 递减, 归零 → CSupplySystem vtable[+24](省 id) 刷节点 + swap-remove (**+104 即 IsOnCooldown 判据**, :544; 表内条目保证 info 已建且在冷却中 — 违者即断言非静默跳过; swap-remove 拷贝用递减前计数) | 定案 |
| 开局铁路网 | map/railways.txt 装载器 sub_140E90D50 → sub_140E95B70 SetRailwaysAlongPath (省序列逐相邻对双向 SetRailway + 逐省刷节点; PathLength>1 断言) | 定案 (路径串直证) |
| 铁路网导出 | railway_persistence.h:33 (0x141B69B70, 158 行) = 装载器**对偶侧**: 逐 Railway 节点断言 "Railway._Provinces.GetSize() > 1" (闩 byte_14338C194) → 行 = `sprintf("%d %d ")` 头部两 int (实参经寄存器 IDA 不可见, 推定 type/level, 待装载侧消费比对) + 逐省 `"%d "` (节点 +8 = _Provinces dword 数组 / 计数 +20) + "\r\n" → 写 **map/railways.txt** (流 +64 byte 失败旗 = 0 跳过); Railway 节点侵入式单链 (next@+40) | 定案 (写侧; 行首对语义待裁) |
| build_railway effect | Execute = sub_14034DE00 (invalid level 报错 + 寻路 sub_140E936F0) → sub_140E92AB0 AddRailwayLevelAlongPath (逐相邻对增量设级 + 刷节点); 其余 92AB0 调用者 = 两省段升级 sub_140E61760 (建造完成侧) + GUI 侧 3 处 (推定); 签名 (M, 路径向量, delta u32, clearProgress u8) — 与全量版 0x140E95B70 同构 (:594 PathLength>1 断言, 全量版 :615; 尾同款 gamestate.h:1116/1117 守卫 + 逐省刷节点), 逐对经增量变体 sub_140E928E0; 返回值 = 寄存器残留勿消费 | 定案/推定 |

> CRailwayManager ctor 0X140E92510 {slots cap@M+16, alloc@M+24}; 实例对象 = §4.14.6
> CProvinceRailwayInfo; 轨道升级图标侧 (CRailwayMapIcon + 五 define) 见 §4.30.16。

每省情报/可见度纹理 (访问链定案 / 管理器与包装对象类名未决 — 均无 RTTI; CGameGraphics 已排除):

| 项 | 值 |
|---|---|
| 挂载 | 管理器对象 +1776 = 每省情报/可见度字节纹理 (0–100%); 访问链 = qword_14332F698 vtable 字节偏移 +120 (槽 15, 有效性门) 真 → +128 (槽 16) 取省地图对象, sub_140B53EE0(对象, 省 id) 按省 id 索引 (两槽并用, 双点同构) (槽 16) |
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

**型 5 目标区簇收集器 sub_140E2A3A0 (df361 本体定案)**: 自目标省 prov+208 CControllerArea 起 **99 层上限 BFS** (seen 线性查重链 + 队列双 32B 哨兵链), 收集「现控制者对请求国军通放行」的连续区簇入引擎向量 {count@+12}; 起点无条件入选 / 同控不入选 (req.id ≠ 控制者.id 前置)。**军通判定 sub_140700570 本体** = req.id ≠ 控制者.id ∧ (一方 id==0 ∨ req.index ≠ sub_140BB5490(控制者+8)) ∧ 控制者 id>0 ∧ 控制者国+3976 → +8 表 [req.index] → **+744 关系对象非空 ∧ +73 旗 == 0** → 返 1 (+744/+73 旗持位直证; launch_nuke 候选过滤同判定, §4.3.10a)。CControllerArea: +40 = 主省对象指针 (省+392 = 控制者 idpair) / +144 = 邻接侵入单链 {邻区@+0, next@+16}; 省 +208 = 所属 CControllerArea 回指。

**pathfind.h 模板族** (三图源 × 谓词-代价-完成三回调契约) 18 实例业务表 (⚠ **表内业务公式全部住在调用方注入的 pred/cost 回调, 实例函数体 = 纯骨架** — 体内判别 grep 仅见 100000 基准与 INF 哨兵, 按 VA 反查业务常数会扑空; 唯一可靠身份判据 = 调用者, 全簇调用面 1:1~2 已普查):

| 函数 | 图源 | 业务 |
|---|---|---|
| sub_140E2BDF0 | 省图 | 主移动 A* (型 0..5 边检查) |
| sub_140E2CC50 | — | CPathFind 请求校验器 |
| sub_140C6B530 | 省图 | CArmy::[52] 谓词目标 Dijkstra (own 领地内找 CanEnterProvince ∧ prov+168 set 空) |
| sub_140C9DBD0 | 州图 | 多源 A* (贸易快检 sub_140CA7990 内芯) |
| sub_140E87390 | 省图 | 铁路炮 A* (铁路边 = CProvinceRailwayInfo 等级>0 ∧ cooldown==0 ∧ 已建) |
| sub_140E8F890 | 省图 | **铁路建造/路径请求寻路** (全回调版; 唯一调用者 = sub_140E936F0 build_railway wrapper, pred sub_140E94AB0 第一门 = desc+210 bit0 可通铁路位 — 真身待裁: 候选 = 主省图 A* 海军边模式或 1410 海军令域 PC 实例之一) |
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

CPathFind 请求校验器 sub_140E2CC50 参数结构 (定案, pathfind.cpp:999/:1006 断言串):

| a2 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | int32 | 路径类型枚举（2 = 海军路径，走 sub_140E2B830 分支） |
| +8 | 对象指针 | 源对象（vt[14] 偏移 112 可通行性询问：`(src, 目标, +41, +42, 0, 1)`） |
| +16 | 对象指针 | 起点（+184 → +208 word 与 +210 byte&1 作区域/通行判据） |
| +24 | 对象指针 | 终点（同起点判据） |
| +40 | bool | 附加通行旗（参与 vt[14] 询问前置门，命名推定） |
| +41 | bool | `_bBlockTransfer` |
| +42 | bool | `_bForceTransfer` |
| +43 | bool | `_bForceTransferThroughNavalBase`（与 +41/+42 互斥） |
| +46 | bool | 附加通行旗（同上，命名推定） |
| +47 | bool | 附加通行旗（同上，命名推定） |
校验序：非空三重门（+16/+24/+8）→ :999 → +43 与 (+42 ∨ +41) 互斥门 → :1006 → vt[14] 询问 + 区域一致性（+208 word 相等 ∨ +210&1 ∈ {端点}）→ 类型 2 另走 sub_140E2B830；返回 1 = 可建路。

CStrategicRegion 增补: +176 邻区指针数组 / +188 计数 / +224 代价权重 / +240 位置 qword 对 (+88 区 id 见省 +200 行)。

**pathfind.h 模板骨架契约 (16 实例全读, 新定案)**: 10 参签名 `(mgr, from_vec, to, out, nodeCount, maxHops, ctx, pred, cost, done)` (回调裁剪得 PC/P/N 变体); 入口 scoped buffer 一次分配 **visited 位图 (n 位) + 40B×n 节点表** {f@0, g@8, 节点指针@16, **父 = 节点表项地址@24**, hop 数@32}; **INF 哨兵 = 92233720200000 (0x53E2D620FB40)** (≠ int64max/1e5); 16B 堆元 {key, 节点下标} 最小堆无 decrease-key (惰性重推); **启发式 = basis (恒初值 100000, cost 回调按引用可改写 — 读侧定案/写侧推定) × 牛顿 isqrt(欧氏距离, x 环绕 CMap+64)**, h 缓存 = f−g 复用仅首触算 isqrt; maxHops ≤0 = 不限; pred = 边剪枝 / cost 负值 = 边弃。**双重建器分写**: 模板族重建器 sub_140CA7650 **输出含起点** vs 主 A* 重建序 sub_140E29990 不含起点 — 两序勿互并。CArmy::[52] 变体 (sub_140C6B530) = 32B 节点 + key = 纯 g (无启发式 Dijkstra) 确认。**海军寻路互证**: CheckNavalPath sub_140EA9120 与修理母港打分寻路 sub_140D67AA0 均不调用本簇 = 独立实现; 「省对距离表 qword_143339D28」与「CMap 单例」系同一对象不同字段域, 两锚不冲突 (本簇只读 +64 环绕宽)。raid_pathfind.cpp 2 函数 (sub_141A09E00 门包装 / sub_141A0A130 raid 令陆目的地 wrapper, 高置信) 书未收 — 轻扫留待。**raid 寻路运行时入口已定位** = CRaidSystem (gs+1008) 的 sub_140E86040 (海军) / sub_140E86000 (陆), 经 CRaidSource::CalculateDistance + CRaidArrow::UpdateArrow 双调用方互证 (§4.27.7); 与 sub_141A09E00/A0A130 的关系未决。⚠ raid 直接距离 (sub_140E7C150) 哨兵 = INT64_MAX, **≠ 本簇 INF 92233720200000**。

#### 4.14.9 map.cpp 簇对账增补 (地图静态装载 11 函数闭环)

**装载管线** (调用者面全量反查): 世界静态资源总装载 sub_14018BB20 = 河流复合
sub_140A65800 → 定义复合 sub_140A5F4C0 (CMap+76 ← 1, 推定定义已载旗) → **ThreadedPostPostRead
sub_140A653D0 异步排队**; wrap 检查在世界装载另一段 sub_1401835A0; nudger 无港检查在 InitMap
sub_140185170。**五 pass 实录** (全串行内联): ① GenerateBoundingBoxes sub_140A5F7B0
(provinces.bmp 像素归属扫描 → bbox + 行程表 RLE) ② 位图邻接 sub_140A5DDC0 ③ 内联沿海调和
(bitmap 与 definition 分歧以 bitmap 为准, :1963) ④ tbb **CRealignPixels** (符号直证,
grain = count/16) ⑤ InitPerPixelWeights sub_140A61F80 (**CInitMapPerPixelWeightsThreaded**;
:622 日志标签 "CProvinceTemplate" 与 pass 内容错位 = 引擎串粘贴痕迹)。

**reload 分发器** (sub_14027A670, 分支键 postfx/flags/arrows/terrain/straits):
`reload straits` = bbox → adjacency_rules → straits → 陆块 BFS 四函序列 + 图形通知
("Straits reloaded") — **不含位图邻接重建**, desc+112 底表不重建, 重复 reload 靠
sub_14140A360 查重免复制; `reload terrain` = sub_140A644C0 (位图重建, 非簇)。

**GenerateBoundingBoxes 要点**: 像素源 = CMap+2096 聚合 +24 (u16/像素, 行主序; ⚠ **值域待裁**: §4.35 军令线总入口 sub_141258D30 单省支直接把该表值与**省 id** 比较 (== a5 首省 id), 与本处「权重表 + 经 CMap+616 二次取省」两读法冲突 — 两读法兼容当且仅当表值即省 id; 若为紧凑权重下标则军令线读法需改述为先转省, 待裁), 宽高
@+48/+52; 行程表 desc+88 6B 元 {x,y,len} u16×3 (1.5× 增长); X 环绕修正落 bbox。诊断三级
(门 = byte_14332EC69 = 启动选项 debug/crash_data_log): :1820 无像素 / :1830 bbox 宽或高
≥ ⅛ 地图 (环绕疑似) / :1842 Σrun ≤ MINIMUM_PROVINCE_SIZE_IN_PIXELS (dword_143331798)
且非湖。

**straits.txt 装载 sub_140A62270**: 记录 `<from> <type串> <through> <x1> <y1> <x2> <y2>
[rule]`; type 串映射 sea→1 / river→2 / river_large→3 / impassable→4 / 其余→0; 非自然邻接
对才登记 +16 表 12B {from, to, through}; rule 名未命中注册表 → :1660/:1661; 手工边 = 48B
条 (第二坐标对 = {0,0}, 第一坐标对 = 对侧端点) 双向追加; 尾验 :1208 THROUGH 不相邻。

**rivers.bmp 装载 sub_140A63B80**: 56B 位图对象存 CMap+384; 断言位深 8 (:657) 与调色板
色数 0 (:662); +392 u16 洪泛数组 grow 到宽×高; 河像素 = **RIVER_SMALL_START_INDEX
(dword_143336570) < color ≤ RIVER_LARGE_STOP_INDEX (dword_1433366BC)**; 连通分量自 id=2
起号, 8-连通显式栈; +416 河对象表 resize 到末段号 (24B 元)。

**位图邻接 sub_140A5DDC0 精化**: 4-邻横向环绕纵向钳位; 自然边 48B 模板全字段 = {rule=0,
邻省@+8, through@+12=0, type@+16=0, 画线禁@+17=0, cost@+24=0, 第二坐标对@+32={−1,−1},
第一坐标对@+40={0,0}} 双向追加; **X 交叉非致死** = 2×2 块四像素四省两两相异 (六次比较) →
sub_140A631C0 **只补主对角 (NW-SE)** 强制双向补链 (同款 48B 模板), 锚点 = 2×2 块左上像素,
末行不检测, :1932 报错 (y 翻转 = height−y); 尾遍历岛屿旗 sub_1414089A0。
**wrap 检查 sub_140A5EBA0**: tbb **CCheckWrappedProvincesThreaded** (符号直证) 填旗 →
:587 告警列省清单 (作战计划错误分裂风险)。**陆块 BFS sub_140A5E3A0**: 显式栈 DFS, 种子循环
自省 id 1 升序 (跳槽 0 null 对象), 块号自 1 起 = 种子发现序; 扩展三条件 = 邻接边 type ≠ 4
(impassable) ∧ 对端陆省 (desc+210 bit0) ∧ 对端 +208 未分配——sea 型手工海峡边参与连通;
海省块号 0, :1319 "Calculated N land masses" (vanilla 1.19.3 = 132)。尾验 :1208 = 双端陆省
∧ **双侧邻接表都无** through 才报错 (单侧有即不报)。

**definition.csv 装载 sub_140A64720**: 空槽填 null 对象指针 qword_143339E30 (216B,
null_object.h 断言族, 非零); 描述符 ctor sub_1414084F0 置 +196 = id; 行 40B: +5 旗 bit1 =
land → desc+210 bit0 / bit3 = lake → desc+210 bit1 (**湖旗定案: 直接源 = definition.csv
lake 列**) / +6 大洲 → desc+211 (陆省零大洲 :1373) / +7 → 沿海调和 sub_14140A6A0(desc,1)
/ +8 Terrain 串 → terrainDB 查 → desc+168 (唯一写点)。**行表布局定案** (40B/行, 三处消费互证):

| 行内偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | uint16 | 省 id |
| +2..+4 | uint8×3 | 调色 RGB (LUT 键 = R<<16\|G<<8\|B) |
| +5 | uint8 | 类型旗: bit1 = land (2) / bit2 = sea (4) / bit3 = lake (8) |
| +6 | uint8 | 大洲 id |
| +7 | uint8 | coastal |
| +8..+39 | char[32] | terrain 串 |
**CMap+2096 聚合构建链定案** (收口旧未决「构建者」): sub_140A5F1F0 → sub_141543C00 →
sub_1415446A0 — 终函数以 **32MB 直寻址 LUT** (`LUT[R<<16|G<<8|B] = 省 id u16`) 逐像素
精确匹配 definition.csv 行 (无最近色近似), 未匹配像素装载期留 0 (无省); +2096 聚合对象
120B 含 +24 像素表 (u16/像素, 行主序) / +48 宽 / +52 高。
**InitPerPixelWeights**: 断言 _pPerPixelWeights == 0 (:2423) 后 malloc 宽×高 u8 存 CMap+8;
归一上界 = max desc+192; **quickstart 旗 byte_14332EC5C** = 权重全 1 捷径跳过并行。
**nudger 无港检查 sub_140A66750**: (desc+210 & 9)==9 ∧ +200==0 → :1679 崩溃预警。

未决: bbox pass 尾两对 item-DB 消费语义; CMap+336/+240 两文件身份; CMap+76/+2104;
权重 functor 归一公式; 簇外近邻 sub_140A64AA0/140A64430/140A65010/140A644C0。

#### 4.14.10 province.cpp 簇对账增补 (CProvince 运行期行为层; 9 函数闭环 — 与装载侧互斥)

**SetController 级联五广播槽补全** (书原未列槽): ① gs 槽 123 (gs+984 CSupplySystem)
vtable[+16] / ② ③ 新旧国 cc+4344 vtable[+16] / ④ gs 槽 210 (gs+1680) vtable[+16] / ⑤ gs 槽 211
(gs+1688 CNavyManager) vtable[+16] — 均 (对象, prov, &old_tag); 另有第 6 路 CMap 单例族通知
(sub_140A66B70+sub_140A67560)。受影响国集 = 旧+新+邻省 controller 去重。行军师处置 =
cc+3976 容器 (count@+1012) 迭代, 元素 +4192 == prov 者 → 敌对判定 sub_140700570 →
sub_140C22F80 可见性 + 可见时 sub_140C11D60 捕获 (元素业务身份待裁)。

**入口三重门 (无主省保护, 定案)**: 默认控制者 > 0 ∨ 新 tag ≤ 0 → 直入改写块; 否则
(无主省+有效新 tag) 仅限加载期 (gs+2617 = 0) 或世界构建期 (gs+2613 = 1), **运行期静默拒绝
(连 prov+392 都不写)** — 与湖泊自动控制者开局建链、AddUnit 构建期免无港错三处互洽。
**控制权变更 → 铁路冷却三档 define** (定案): 敌对转移时 sub_140700450 (内战判定, 高置信)
→ RAILWAY_CONVERSION_COOLDOWN_CIVILWAR / 旧 tag ∈ st+176 cores → _CORE / 否则
RAILWAY_CONVERSION_COOLDOWN (defines_map 3/3 命中); 落地 = railway_info+104 = define 值 +
管理器 +32 顶格冷却数组 + CSupplySystem vtable[+24] 刷节点 — 玩家可见「占领后铁路中断 N 天」。

**湖泊/不可通行省自动控制者 sub_140E7FCA0 = 邻票选举** (定案): 邻接表 48B 步进逐邻省,
门 = 邻省 controller > 0; **票权 = 4×!(邻省州 stateDef+348 impassable) + 1** (非 impassable
邻省 5 票 / impassable 邻省 1 票); 记票按归一化 tag, 平票偏向默认控制者/同国别名; 胜者经
SetController(邻省, tag, only_same_country, 1) 重路径落位 (:542 "auto-controller of the
lake" 业务名直证)。

**省域敌我强度比 sub_140E7AFE0** (定案, 业务名推定 GetOdds 族): 签名 (prov, out*, 
CCountry*); 三环 BFS — 本省单位 (def stat+24 槽, token 174) / 直接邻省 (+16 槽, token
173) / 二环位置对象 (同 +16, 权重 = 二跳省与主省直接相邻 ? 1.0 : 0.5, impassable 边跳过);
每单位敌我二选一: friendly = controller 同国 ‖ cc+3976 白名单 ‖ sub_140C01960 远征军判定
(owner≠controller) ∧ idpair ∈ cc+784 volunteers_sent; hostile = sub_140700570 敌对关系
(cc+3976 槽对象 +744 → +73 旗); 计分 = (def_stat + 100000 + Σ st+1928 动态修正
[token 173/174]) × vtable[+240] / 100000; 输出 = clamp(1e5×我/敌, 0, 1e8), 敌 0/溢出 → 1e8;
地形 stat 表 = sub_14101BC50(def, terrain) = def+1016 + 40×(terrain+136 − 1); 唯一调用者
= AI 巨函 sub_1414C7E80。

**CalcRailwayPercentage sub_140E7A340** (定案): `(prov, out*, neighbor)`; 门 = info 存在 ∧
cooldown@+104 ≤ 0 ∧ +56 边表非空; **+56 边表线性扫消费形态** (与 §4.14.6 二分形态并存); 输出 = 1e5 × (铁路建筑完好度 sub_1410DB320 × 边等级) / (1e5 ×
MAX_RAILWAY_LEVEL), 饱和钳 0xFFFFFFFF。

**AddUnit 类型分派键 = 单体+8 u32** (定案): 0 陆军 → vtable[+56] 位置对象插 prov+272 /
1 海军 → vtable[+72] 插 prov+248 (无港致命错三重门 = desc+210 bit0 ∧ !HasPort ∧ 非世界构建期)
/ 13 铁路炮 → vtable[+88] 插 prov+296。**HasPort sub_140E7DE70** = gs+1688 CNavyManager 内
省id→港 RH 表 {data@+40, mask@+52, extra@+56}, 24B 桶, 哈希常数 73244475。
**空降通知+事件 sub_140E7EE70** (定案): on_units_paradropped_in_state 事件 = STATE scope
(州 id = st+88) + FROM = COUNTRY scope (空降国); 地图浮字类别 "siegeinfo"; 可见性门 =
sub_140700600 ‖ (mapdata+1776 纹理字节 ≠ 0 ∧ FOW 门)。

#### 4.14.11 provincetemplate.cpp 邻接边几何回填 pass (0x141408A30 1336 行)

地图装载收尾 pass (上游 = FinalizeMapLoading gameapplication.cpp:1559 经地图装载编排器调入; 位于 §4.14.9 五 pass 之后、§4.14.10 运行期层之前), 为每条陆-陆邻接边回填边型 / 边界有效旗 / 通行代价 / 第二坐标对四字段。

CMap (单例 qword_143339D28, §4.14.4) 本 pass 读写槽:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +64 | i32 | 地图宽 WIDTH (与 rivers.bmp 宽比对, 断言 provincetemplate.cpp:142) |
| +68 | i32 | 地图高 HEIGHT |
| +368 | CBitmap* | 省地形类别位图宿主 (像素字节 = `*(宿主+16)·x + *(宿主+28)·y + *(宿主+40)`) |
| +384 | CBitmap* | 河流位图 rivers.bmp (:358 校验缓冲指针 == AccessRiverDefinition()->GetBuffer()) |
| +392 | u16* | 河段洪泛标记数组 (线性下标 x + 宽·y; river_id 取自此数组) |
| +404 | i32 | 河数 (本 pass 河段对向量容量) |
| +416 | 河对象表* | 每河 24B 向量 {data, cap, count, alloc} (sub_1414087E0 追加省 id) |
| +616 | CProvinceStaticDesc** | 省静态描述符指针数组 data (cap@+624, count@+628) |
| +2096 | CPerPixelWeights* | 像素权重聚合对象 (u16 权重表 data@+24, 宽@+48, 高@+52) |

省静态描述符本 pass 读写字段 (基表 §4.14.3):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +40 | i32 向量 24B | 河流穿越去重表 {data@+40, cap@+48, count@+52, alloc@+56} (本 pass 首写; i32 河 id 元) |
| +88 | RLERun* | 行程表数组 (边界像素展开源) |
| +100 | i32 | 行程表条目数 |
| +112 | AdjEntry* | 邻接表 data (条目步距 48) |
| +124 | i32 | 邻接条目数 |
| +176 | i32 | 边界线端点 x (光栅化线段起点; 横向回绕时 ±WIDTH) |
| +180 | i32 | 边界线端点 y |
| +184 | i32 | 省位置 x (无边界像素时的回退中点用) |
| +188 | i32 | 省位置 y |
| +196 | i32 | 省 id |
| +210 | u8 | 旗字节 bit0 = 陆省 (双陆省门) |

邻接条目本 pass 写字段:

| 条目+N | 类型 | 名称/语义 |
|---|---|---|
| +16 | u8 | 边型: 河穿越 → `(color > dword_14333660C) + 2` = 2 river / 3 river_large; 未穿越保持原值 |
| +17 | u8 | 边界有效旗: 光栅化线段全程归属本省或邻省 = 1, 穿越第三方省 = 0; 两省陆性不同时强制 1 |
| +24 | i64 | 边通行代价 fixed×1e-5 = 逐边界像素地形代价之和的 1/3 (见流程步 10) |
| +32 | i32×2 | 第二坐标对 = 边界像素质心 (无边界像素时 = 两省 +184/+188 位置中点) |

CTerrainDatabase (单例 qword_14332F0A8, §4.26.8) 本 pass 读侧:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | CTerrainCategoryEntry** | 图形地形类别第二数组 data |
| +124 | i32 | 第二数组 count (idx < 1 或 ≥ count → 取 *(db+112) 槽 0 的 Null Object, gameitemdatabasehelper.h:22 门) |
| +136 | i32* | 类别 LUT (位图字节 → 第二数组下标) |
| +148 | i32 | LUT count (= 本 pass 代价表长度) |

执行流程 (定案, 全部有函数体内证据):

| 步 | 动作 | 门 |
|---|---|---|
| 1 | 河流位图宽高 ≠ 地图宽高 → 断言 :142 (B52) + 通道 65540 `MAP_ERROR` 一行式日志, 后续仍按位图几何继续 | 前置校验 |
| 2 | 遍历 CTerrainDatabase 的 LUT (count@db+148), 每项经第二数组条目 +88 一跳取游戏性地形 +96 movement_cost, 填入 qword 代价表 (scoped buffer, 界 dword_1435E3ECC) | 代价表构建 |
| 3 | 遍历 *(CMap+616) 每个省描述符, 进度条 phase 15 (`sub_14222E270(handle, 15, cur, total, 0)`); 读 desc+196 id 与 desc+210 bit0 陆性 | 外层循环 |
| 4 | 遍历 desc+112 邻接表, 仅处理邻省 id < 本省 id 的对 (每对一次); 两省均陆且条目 +16 == 0 (未分类) 才进入几何计算 | 内层循环 |
| 5 | 以两省 desc+176/+180 为端点调光栅化器 `sub_1422EC290(x0, y0, x1, y1, outBuf, maxCount, 0)` (像素存为 qword {x lo32, y hi32}); 端点横向间距 > HALF_WIDTH 时 ±WIDTH 回绕; 像素数上限断言 :205 / :350 (`< WIDTH + HEIGHT - 1`); 折返续写护栏断言 :295 `abs(pPixels[nTestPixel].first - nX) < HALF_WIDTH` (latch byte_14338A466); 河位图尺寸断言 :142 + :145 MAP_ERROR (通道 65540) | 边几何 |
| 6 | 每个光栅像素经 `x = (WIDTH + px.x) % WIDTH` 归一, 查 *(CMap+2096) 权重图 (宽@+48 / 高@+52 边界判, u16 权重 = data + 2·(x + y·宽)), 得省 = *(CMap+616)[权重]; 任一像素不属本省或邻省 → 边界有效旗置 0 并跳出 | 归属校验 |
| 7 | 从 desc+88 行程表 (6B 元 {x, y, len}) 展开边界像素, 4 邻域扩张连通 (偏移表 xmmword_1429BF010 / xmmword_1429BF020); 质心 = 逐像素 `10000000000·coord / (100000·n)` 累加后经 sub_1424ED730 取整 = fixed×1e-5 均值 (被乘数落在 ±INT64 边界三值时钳 4294967295) | 边界像素收集 |
| 8 | 边界像素在河流位图的颜色满足 `color >= dword_143336570 && color <= dword_1433366BC` → 条目 +16 = `(color > dword_14333660C) + 2`, 并双向登记 `sub_1414087E0(本desc, river_id, 邻id)` + `sub_1414087E0(邻desc, river_id, 本id)`; 河段对累计入每河 24B 子向量 (容量 = *(CMap+404)), 装载尾整批交 `sub_140A65910(CMap, &vec)` 构建河数据 | 河流穿越 |
| 9 | 河流穿越登记子 `sub_1414087E0(desc, river_id, nbr_id)`: ① river_id 去重插入 desc+40 向量 (满则 cap×1.5, min count+1); ② 把 desc+196 追加到 `*(CMap+416) + 24·river_id` 的每河省 id 向量 — desc 记穿越自己的河, 河对象记穿越的省 | 双向登记 |
| 10 | 每个边界像素查省地形类别位图 (经 *(CMap+368)) 得类别字节, 代价表[类别] 累加入条目 +24; 位图越界像素按类别 0 计费; 像素走完后条目 +24 = `100000·累加值 / 300000` (算术等价 floor(累加值/3), 同 ±INT64 边界钳位) | 代价累加 |
| 11 | 条目 +32 = 质心, +17 = 边界有效旗; 四字段 (+16 / +17 / +24 / +32) 全部镜像到反向边 (在邻省 desc+112 表中按本省 id 查得条目) | 回写与镜像 |

> 本 pass 是邻接条目 +16 / +17 / +24 / +32 的**第四处写点** (前三处 = 位图自然边 / straits 手工边 / 对角补链, §4.14.3 邻接装载链); 其中 +24 写的是计算值而非 0。

#### 4.14.xb 友方控制省图 BFS 距离查询 (1 函 = 0x140BE4370, 高置信)

0x140BE4370: gs+700 省数铺 visited; gs+8 vtable2 槽[1] 取省; 邻接 {data@+112, 48B/条: 邻 id@+8 (书已名)、类型 u8@+16 ≠4 过滤} (省静态描述符 §4.3:227 挂点); 通行谓词 = controller(+392) → sub_140700600 (tag/索引同源); 返回 {省id<<32 | 深度}, 未达 {−1, dword_143332E24 (= COMMS_MAX_DISTANCE 复用)}; 唯一调用者 sub_140BEB640 取距离写宿主 +460。
