

### 4.24 战区族 (CTheatre / CFront / CFrontSection / CTheaterGroup / hq_deploy)

#### 4.24.1 类身份与 RTTI 谱系

writer 绑定总表:

| 类 | sizeof | vtable | writer (slot2) | ctor | reader (slot4) |
|---|---|---|---|---|---|
| CTheatre | 0x1D0=464 | 0x142975A48 | 0X140F025C0 | 0X140EE9E50 | 0X140EFE2B0 |
| CTheaterGroup | 0x60=96 | 0x1429E5C50 | 0X14163AA40 | 0X141639B00 | 0X14163A850 |
| CArmyGroup | 0x250=592 | 0x142952348 | 0X140BF75A0 | 0X140BE9BC0 | 0x140BF2ED0 |
| COrdersGroup | 0x230=560 | 0x1429522B0 | 0X140BF7630 | 0X140BE9C10 | 0x140BF30A0 |
| COrderInstance | 0x3C8=968 | 0x142986718 | 0X14104B570 | 0X141027A10 | 0X14103E110 |
| CFront | 0x88=136 | 0x142975B40 | 0X140F01A60 | (内联于 reader) | 0X140EFCF10 |

**RTTI 谱系定案表** (本族 + 关联类):

| 类 | RTTI/谱系定案 |
|---|---|
| CArmyGroup | 直继 COrdersGroup (mdisp 0; 双 vtable 形态承自基类) |
| COrdersGroup | 基含 CRailwayGunAssignee@+24 (ctor 双 vptr +0/+24 来源) |
| COrdersGroupMember | CUnit 谱系成员 @ unit+184 (vt 0x142953320 = 子对象视口, 本体 vt 0x142952268 — member 元素 = unit+184 视口的 RTTI 级实证) |
| CHqDeploymentDistributable | 双 vtable: CEquipmentDistributable@0 (vt 0x142A1CE18) / CPersistent@+24 (vt 0x142A1CE50; writer 0X14193EED0 挂 +24 视口) |
| CGameDate (内嵌) | 三层 {vt@0, hours@+8, vt@+16}; 与 oi 内嵌日期对象一致 (writer 转发 +16 视口) |

挂载: CTheatre 挂于 CCountry writer 0X1407191B0 壳 — `if (*(cc+372))` 计数>0 才整块写 theatres; 容器 {d@cc+360, c@cc+372}, 元素 CTheatre*。

**pdx 容器空态** (本册「容器内部」未定段的判定钥匙):

| 项 | 值 |
|---|---|
| 空态 ctor | sub_14011DF40 |
| data | 0 |
| cap + count | 0 |
| alloc | &off_143085170 (静态空分配器哨兵) |

注: 释放走 alloc->vt[2] (CFront dtor 0X140EEA470 直证)。

#### 4.24.2 CTheatre (464B, writer 0X140F025C0)

**CControllerArea / COwnerArea (area 块元素双类; 280B = 0x118 同布局; 原「vt 0x14295e818」实为两张相邻 vtable — CControllerArea 7 槽 0x14295E818 + COwnerArea 9 槽 0x14295E858, RTTI COL 直证; COwnerArea 无独立 ctor, 调用点内联 sub_140CF05C0 → 换 vptr; **序列化负定案: 本类零落盘** — reader case 11157 只把锚省 id 读入 theatre+48, post-load 链 sub_1401DA490 → sub_140704D20 → sub_140EFC6D0 (CTheatre::UpdateMainProvince, theatre.cpp:2557) 经 prov+208 重建 theatre+24, sub_140EFC390 重建 front+112):

| 类 | 洪水分组键 | 省侧回指槽 | 注册容器 |
|---|---|---|---|
| CControllerArea (前线区) | 省+392 controller (别名归一 sub_140BB52F0) + 同 region 组 | CProvince+208 | CCountry+1352 |
| COwnerArea (所有者区) | 州+200 owner tag (sub_140E796B0) + 同 region 组 | CProvince+216 | CCountry+1376 |

两类共用 vt[1] GetTag = +40 优先省的 controller tag。成员布局 (+0..+279 全覆盖):

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vptr | CControllerArea 0x14295E818 (7 槽); COwnerArea 实例 ctor 后改写 0x14295E858 | 定案 |
| +8 | 匿名结构 (NNB 形状) 向量 24B | {data@8, cap@16, count@+20, alloc@24}; 元 = 多态自有子对象 (dtor 虚调) | 定案 |
| +32 | uint64 | 裸槽 ctor 清零 (区内无任何读写点) | 定案(负) |
| +40 | CProvince* | **优先陆省锚** (晋升规则见 vt[4] AddProvince); 发射两跳 ru32(rp(+40)+164); GetTag 源 | 定案 (原锚吻合) |
| +48 | 匿名结构 (NNB 形状) 向量 24B | **本区省表** (有序, 按省 +164 id 二分插查); {data@48, cap@56, count@+60} — oi+168 门吻合 | 定案 (原锚吻合) |
| +64 | — | +48 容器 alloc 槽 (共占) | 定案 |
| +72 | uint32 向量 64B | **边界段记录表** {d@72, cap@80, count@+84, alloc@88}; 元 64B {外方 tag, 双侧边界省容器, 均值对@+56} | 定案 |
| +96 | 匿名结构 (NNB 形状) 向量 24B | **边境省表** (有外控邻接的省) {d@96, cap@104, count@+108, alloc@112} | 定案 |
| +120 | 匿名结构 (NNB 形状) 向量 24B | flag&4 省表 (静态描述符 +210 位 2 置位的省; 位义待裁) {d@120, cap@128, count@+132, alloc@136} | 形定案 |
| +144 | 侵入式双链表 | **邻接区观察链** {head@144, tail@152, count@+160}; 外节点 0x20 {内节点*@0, prev/next}; 内节点 {邻区*, refcount i32@+8} (活体 refcnt 102/32) | 定案 |
| +164 | uint8 | 邻接链迟删除模式旗 (置 1 时摘除走「标记外节点 byte@+24=1」路径不摘链 — 迭代保护) | 定案 |
| +168 | uint8 | ctor 清零, 族内无读写点 | 定案(存在) |
| +176 | 匿名结构 (NNB 形状) 向量 24B | 位条件省表 (`(flags&8)≠0 ∨ (flags&2)==0 ∨ 无陆邻省(flags&3)==0` 的省; 位义待裁) {d@176, cap@184, count@+188, alloc@192} | 形定案 |
| +200 | 匿名结构 (NNB 形状) 向量 24B | **国家×区域交互记录表** {d@200, cap@208, count@+212, alloc@216}; 仅前线区有数据 (活体 429/411/435) | 定案 |
| +224 | 匿名结构 (NNB 形状) 向量 24B | **per-country 下标数组** {d@224, cap@232, count@+236, alloc@240}; count = 国家总数 (活体 440); 元 −1 哨兵 | 定案 |
| +248 | 匿名结构 (NNB 形状) 向量 24B | **关联战略区表** {d@248, cap@256, count@+260, alloc@264}; 来源 = +176 条件省表; 活体元 vt 0x296D558 与 §4.25.2 同址 | 定案 |
| +272 | uint32 | 全局实例序号 (ctor 参 dword_14333CC38++) | 定案 |

全链路: 载局三连 sub_140CF55F0/5D80/59A0 (sub_140DC1B30 三连调 + 效果分支 case 19687) → SetController 增量 sub_140CF6FA0/7AC0 (延迟冲洗 sub_140CF81C0) → 合并 sub_140CF67D0 / TrySplit sub_140CF87C0 (areas.cpp:594) / owner 分裂 sub_140CF8F20。加省/删省 = 两类共用 vt[4]/vt[5] ("Adding/Removing province %i to %i." areas.cpp:444/467; +48 容器按省 id 有序插)。

**全字段表** (发射序 = 表序; id 对锚 {id=1, type=67}):

**全字段表** (发射序 = 表序; id 对锚 {id=1, type=67}):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | id 对.type (B400 壳) | 恒写 |
| +12 | uint32 | id 对.id | 恒写 |
| +24 | CControllerArea* 向量 | area 数组数据 (vt 0x14295e818, areas.cpp; 发射值 = 锚点省份 id — area+40 为优先陆省的 CProvince* 锚点, 发射两跳 ru32(rp(rp(elem)+40)+164)); 块呈单行叶 `area.#1` (tok 11157) | 门 计数@+36>0 (cap@+32 推定); 逐值 ADAB0 |
| +36 | uint32 | area 容器计数 | |
| +80 | CFront* | front — 逐元 ADEC0 整块 | 门 计数@+92>0; tok 10720/0x29E0 |
| +92 | uint32 | front 容器计数 | |
| +104 | CUnit* 向量 | unit 数组数据 — 元素 = CUnit 本体指针 (AddUnit sub_140EEBE90 维护); 逐元 B320(10403, elem+24) 单行叶 | 门 计数@+116>0; tok 10403/0x28A3 |
| +116 | uint32 | unit 容器计数 | AI 战区巨函亦以之为 per-front wanted 数组长度源 (>0 门; 消费定案/语义待裁) |
| +128 | COrdersGroup* | orders_group — 逐元 ADEC0 | 门 计数@+140>0; tok 12462/0x30AE |
| +140 | uint32 | orders_group 容器计数 | |
| +152 | CArmyGroup* | field_marshal_group — 逐元 ADEC0 | 门 计数@+164>0; tok 14337/0x3801 |
| +164 | uint32 | field_marshal_group 容器计数 | |
| +200 | CTheaterGroup* | theater_group — 逐元 ADEC0 | 门 计数@+212>0; tok 13777/0x35D1 |
| +212 | uint32 | theater_group 容器计数 | |
| +272 | tag_id | volunteers_theatre 借驻国 — sub_140BB4E70 引号 tag 串 | 门 >0 才写; tok 13421/0x346D |

**writer 不落盘区表** (全部不序列化):

| 偏移 | 形态 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +48 | uint32 向量 | area 锚省 id 读侧容器 — reader case 11157 直入 (与 +24 发射容器成对分离; post-load sub_140EFC6D0 重建) | 不序列化 |
| +72 | — | owner country tag (ctor 第二参; CArmyGroup ctor 以 (theatre+72, theatre) 构造互证) | 不序列化 |
| +144 | 侵入式链表 | {对象@节点+0, next@节点+16}; 元素虚槽[1] → dword 指针 (推定 = 邻国 tag) | 不序列化; 推定 |
| +176 | COrdersGroup\* 向量 (多态含 CArmyGroup\*) | 双挂镜像容器 — reader 12462/14337 双 push, 纯运行时索引; 消费 863B0 按 og+152/164 契约读 | 不序列化 |
| +240..+271 | 内嵌 CColor | 默认白 | 不序列化 |
| +280..+407 | 匿名结构 (128B 形状) | **互斥量保护的待处理条目队列** (ctor sub_140EEA130 / dtor sub_140E9E3D0: +16/+40 = 静态空分配器哨兵; +24 容器 {d@24, cap@32, c@36, alloc@40} 元素 stride 40; +48 = std::mutex (dtor 经 sub_14251DC00 加锁, 尾 Mtx_unlock(+48)); +120 = −1 哨兵; +124 = mutex 递归计数 (== 0x7FFFFFFF → _Throw_Cpp_error(6)); 条目 40B: +16 = 裸指针数组 d, +28 = count, 数组元素逐个 j_free) | 不序列化; **AI 海运转移规划缓存** (ai_strategy.cpp "The AI is attempting to naval transfer a unit"): 容器#1 (+280) 48B 条 {u32 键对 + 内嵌容器 + u32}; 容器#2 (+304) 40B 条 {qword 键对 + 24B 记录指针数组}; AI 工作线程写 (gamestate 断言直证), CTheatre::Update 每帧首步清空 (sub_140EA2340) — 故须 mutex; 查询/入队族 sub_140E9F9C0/140EA40A0/140E9FC80/140EA5320 |
| +408 | AreaAndFrontProvinces 向量 (192B 元素) | **「Fronts per enemy area」字典** (theatre.cpp:416/435 断言直证) {d@408, cap@416, c@420, alloc@424}; 元素 = {己方区域 CControllerArea*@+0, 敌方区域@+8, CFront*@+16 (认领/新建的前线), 省份累积器容器@+24..+47}; 每帧 tbb 并行通道 (sub_140EF97A0→140EED730 清重建→140EECA10 旧前线认领→140EEB190 逐条目: 空则新建 CFront (type=66, area 存 front+112)); 段构建体 = **sub_140EEE090** (省对配对, "Failed to build a front against enemy…" 断言) | 不序列化 |
| +432 | CArmyGroup* 向量 | pdx 容器 {d@432, cap@440, c@444, alloc@448} (dtor sub_1401A4F70 逐元 deleting + alloc 释放) — **本帧被移出/解散的 CArmyGroup 引用登记表 (keep-alive)**: CTheatre::Update sub_140EF8470 对 +152 中 ag->vt[12] (sub_140BF1F20 递归「子 og 全部可回收」) 真者 push → sub_140F00410 摘除 (+152/+176 双摘) → sub_140BF3D70 Disband | 不序列化 |
> **CTheatre::Update (sub_140EF8470) 运行侧** (定案): 唯二调用点 = sub_1401BB280
> (DoCountryHourlyUpdates hourly_parallel 执行器, §4.2.6 相位 2) → **跑在 tbb worker
> 线程** (两窗主线程仅 0.6%, 全线程 3.3%); 伴生 0xEE 区 = NTheatreManager 分发族
> (InitSectionsForCountries / DispatchBundle / DispatchConquer 符号直证) +
> 战区区块重算分发 sub_140EED730 (+408 192B 表)。

#### 4.24.3 COrdersGroup (560B, writer 0X140BF7630)

**全字段表** (id 对锚 {id=13, type=53}; 发射序 = 表序):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | id 对.type (B400 壳) | 恒写 |
| +12 | uint32 | id 对.id | 恒写 |
| +56 | uint8 | motorization_level — **writer 按 u8 读** (零扩展打印) | 恒写; tok 19943/0x4DE7 |
| +57 | uint8 | field_marshal_group bool | **恒写无门** (false 也写 no; 锚 no); tok 14337/0x3801 |
| +80 | CUnit* 向量 | member 数组数据 — 元素 = CUnit+184 COrdersGroupMember 视口 (vt 0x142953320); 每元独立块 `member.#N.unit={id,type}` (ref = (elem-184)+24 {type@+24, id@+28}; thunk 定案见 §4.24.9); 空门触发断言 ordersgroup.cpp "Member doesn't have a unit..." | 门 计数@+92>0 **且逐元指针非零、vt[32](elem)=0X140BF95D0 (`return a1-184`) 真**; tok 11025/0x2B11 |
| +92 | uint32 | member 容器计数 | |
| +104 | 匿名结构 (NNB 形状)* | leader_unit 载体 — unit+184 视口 (reader 0X140BF30A0); 非零才写 B320(16831, vt[32](p)+24) → ref = (p-184)+24 | 门 指针≠0; tok 16831/0x41BF |
| +136 | CArmyLeader* | leader 载体 — CArmyLeader 本体 (CUnit 派生); 非零才写 B320(10423, p+8) → `id=ru32(p+12) type=ru32(p+8)` (锚 `leader={ id=401 type=4713 }`) | 门 指针≠0; tok 10423/0x28B7 |
| +144 | uint32 | pending_incoming_leader.type (0X142220180 块形 AF2C0+B240) | 门 双 dword 非零 **且 A3D0(+144) 校验过**; tok 10306/0x2842 |
| +148 | uint32 | pending_incoming_leader.id | 同上 |
| +152 | 匿名结构 (元素待裁) 向量 | order_instance 数组数据 — 家族树展开后逐元 (展开步骤见 §4.24.9; 收集器 0X141033520/0X141033660); 收集后逐元 ADEC0 | 门 计数@+164>0; tok 13815/0x35F7 |
| +164 | uint32 | order_instance 容器计数 | |
| +176 | COrderInstance* 向量 | fallback 数组数据 — 元素同为 COrderInstance (reader malloc 0x3C8 + ctor 0X141027A10 实证); 逐元 ADEC0 | 门 计数@+188>0; tok 13272/0x33D8 |
| +188 | uint32 | fallback 容器计数 | |
| +200 | COrderInstance* 向量 | virtual_fallback 数组数据 — 元素同为 COrderInstance (reader 13811 → malloc 0x3C8 + ctor 0X141027A10; og+176/+200/+224 三容器均为 COrderInstance*) | 门 计数@+212>0; tok 13811/0x35F3 |
| +212 | uint32 | virtual_fallback 容器计数 | |
| +256 | CColor 内嵌 | color (基@+256, 分量@+272..+284) | !readonly 才整块写 (ADEC0; tok 86/0x56); 子表见 §4.00.10 |
| +288 | uint32 | icon | 恒写 (锚 1); tok 181/0xB5 |
| +292 | uint32 | split_from.type | 门 qword@+292 ≠ 哨兵 qword_14333D528; B320; tok 13156/0x3364 |
| +296 | uint32 | split_from.id | 同上 |
| +304 | fixed×1e-5 (int64) | plan_value (ctor 初值 100000=1.0; 锚 0.7→70000) | 恒写; tok 13628/0x353C |
| +312 | fixed×1e-5 (int64) | our_power (锚 1937.35→193735000) | 恒写; tok 13629/0x353D |
| +320 | fixed×1e-5 (int64) | enemy_power | 恒写; tok 13630/0x353E |
| +352 | SSO 串 | name {buf@+352, size/cap 区@+368} (锚 "第1集团军") | **双门**: !AAFD0 且 qword@+368≠0; tok 27 |
| +392 | CHqDeploymentDistributable* | hq_deploy_distributable — 对象 +24 视口 (vt 0x142A1CE50); ADEC0(16908, p+24) | 门 指针≠0; tok 16908/0x420C; 子表见 §4.24.10 |
| +400 | uint32 | target_template.type | 门 双 dword 非零且 A3D0(+400) 校验; B320; tok 13959/0x3687 |
| +404 | uint32 | target_template.id | 同上 |
| +408 | uint8 | expeditionaries | 真才写 yes; tok 13730/0x35A2 |
| +409 | uint8 | deployed | 真才写; tok 16839/0x41C7 |
| +410 | uint8 | deploy_queued | 真才写; tok 10751/0x29FF |
| +411 | uint8 | withdrawing | 真才写; tok 16843/0x41CB |
| +412 | uint8 | unassign_on_withdraw | 真才写; tok 10752/0x2A00 |
| +413 | uint8 | training | 真才写; tok 12218/0x2FBA |
| +414 | uint8 | members_has_changed | 真才写; tok 13755/0x35BB |
| +416 | uint8 | stop_training_at_max_xp | 真才写; tok 19076/0x4A84 |
| +420 | uint32 | execution_type | 恒写 (锚 1); tok 13994/0x36AA |
| +424 | uint32 | cohesion_type | 恒写 (锚 0); tok 12187/0x2F9B |
| +428 | uint32 | proximity_type (ctor 默认 = define 派生, sub_1415B0F50(dword_143333900)) | 恒写 (锚 1); tok 16841/0x41C9 |
| +452 | int32 | distance | 门 ≥0; tok 11738/0x2DDA |
| +456 | int32 | hq_nearest_front_province_id | 门 ≥0; tok 16845/0x41CD |
| +460 | int32 | hq_distance_to_naval_invasion_source | 门 ≥0; tok 17728/0x4540 |
| +464 | int32 | cached_hq_naval_invasion_source_province_id | 门 ≥0; tok 15836/0x3DDC |
| +468 | int32 | timeout_days | 门 >0; tok 14389/0x3835 |

注 (GUI): Badge 判型键 — badge+504 idpair resolve → og+57 旗判 COrdersGroup(军) ∥ CArmyGroup(集团军); 工厂 sub_141BCB490。
注 (GUI): 剧场组行 member 数求和读 og+92 (CTheaterGroupItem)。

**writer 不落盘区表** (全部不序列化; ctor 0X140BE9C10 证据):

| 偏移 | 形态 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +24 | vptr | 第二 vptr = CRailwayGunAssignee 基视口 | 不序列化 |
| +32 | CRailwayGunAssignee* 向量 | RailwayGuns (CRailwayGunAssignee@+24 成员; GUI 双断言 "RailwayGuns.GetSize>0") | 不序列化 |
| +48 | — | 哨兵直存单槽 (非容器) | 不序列化 |
| +60 | — | country idx | 不序列化 |
| +64 | CTheatre* | owner theatre (ctor 参数) | 不序列化 |
| +72 | 匿名结构 (408B 形状) | **og 运行时索引器对象** (malloc 0x198; ctor 0x1414C1B10: +0 = og 回指 (**零 vftable 写, 无独立 RTTI 类 — 负定案**) / +8 = 0x50 子对象 (sub_140E29930: +16/+48 = 双静态空分配器哨兵, +36/+68 = 0.9f, +72 = 1, +76 = `*(qword_143339D28+64)`) / +24..+248 = 10 个 pdx 容器 / +320/+400 = alloc 哨兵 / +328 = pdx 容器 / +352 = 2×sub_140BB5490(og+60) / +356 = 256; dtor sub_1414C1EC0 逐项析构; 访问器 sub_140BEA830 (pdx_scopedptr 断言 "_pPtr")) — 不序列化 | 不序列化; 类名负定案 |
| +112 | CAirWing* 向量 | attached wings — 元素 = CAirWing* 本体指针 (视口−16 口径, ref 对 @本体+24/+28); attach = sub_140BEB3C0(og, 翼) (断言 GetAttachWingStatus, ordersgroup.cpp:3410; og+57 旗跳过; 翼侧回写 sub_140F5DD60/sub_140F67100 后 push); 填充者 = CAirWing reader 键 army(10397) + assign 命令载入侧 sub_141944CD0 | 不序列化 |
| +224 | COrderInstance* 向量 | 本 og 全部订单实例收集容器 {d@224, cap@232, c@236} — vt[8] sub_140BF1970 post-load 以此为名单跑子实例引用 resolve (sub_14102B680: +752/+776 暂存 id 按 elem+580 匹配 → sub_14102F010 双向 attach) | 不序列化 |
| +328 | 匿名结构 (NNB 形状) 向量 | plan_value 重算 qword scratch (vt[10]→sub_140BEC940 消费; 输入来自 +528 B 区镜像经 sub_1401EFE30 提交) | 不序列化 |
| +384 | 匿名结构 (NNB 形状)* | _pTheaterGroup 回指 (GUI 锚, assert 直证) | 不序列化 |
| +415 | uint8 | **plan_value 重算脏旗** — 30+ 处 og mutator 置 1; 唯一消费者 COrdersGroup vt[10] sub_140BF1660 体 `if(og+415){ og+415=0; og+304 = sub_140BEC940(og, &v, og+312, og+320, og+328, 0); }` ⇒ 重算 plan_value (+304) 及伴随 +312/+320/+328 | 不序列化 |
| +432 | CBorderWar* | **当前边境冲突 (border war) 对象** (单指针非容器; ctor 0X140BE9C10 清零; GUI 三消费: CArmyItem 边境冲突图标 `orders_group_item_border_conflict` 非零门 / CanChangeLeader sub_140BEBAA0 → CANNOT_CHANGE_LEADER_WAR / 进度百分比 sub_140BDC260 读 obj+40/+48 子对象选边 +1232 阈值) | 不序列化 |
| +440 | CArmyGroup* | **所属 CArmyGroup 回指 (父军集团)** — CArmyGroup reader 键 12462: 旧 ag 摘除 (sub_140BF4370(og+440, og), 旧 ag +572 空 → 删除) 后置 og+440 = 本 ag; sub_140BF3C20 三档传播 = 本 leader → 父 ag leader → ag+560 兄弟群 | 不序列化 |
| +472 | COrderInstance* 向量 | **leader 根 order 实例 path 数组缓存镜像** — vt[10] 与 leader 根 OI+112 (COrderInstance.path) 逐元素 memcmp, 不等则 sub_1401A8550 重容 + memcpy; count@+484 / cap@+488 | 不序列化 |
| +496 | idpair (缓存 key) | **缓存 key 对 type@+496 / id@+500** — 与 +472 缓存体成对: vt[10] 以 sub_1410361A0(leader 根 OI, &v, og) 产出对比较, 不等才重拷 +472; 不适用时写 qword −1 (两 dword 全 0xFFFFFFFF) | 不序列化 |
| +528 | 匿名结构 (24B 形状) 向量 | B 区镜像容器 = +328 计算输入容器的暂存 (ctor 空态; tick 经 sub_1401EFE30(+528→+328) 提交; sub_140BEC940 消费 +312/+320 输出 / +328 输入); 前邻 +504..+527 = {qword×3} B 区镜像三元组 (+304 plan_value/+312/+320 暂存, ctor 清零; og 周期更新 sub_140BEC460 开头 B→A 拷贝) | 不序列化 |
| +552..+559 | — | 尾 8B 不初始化 | 不序列化 |

注: A3D0 = 0X14221F310 ref 对有效性校验原语; 段以「双 dword 非零」近似。
注: 铁路炮挂载条目上下文 = COrdersGroup 基视口 (非 CArmy=师; CArmyGroup 派生同布局; RTTI 链 + ctor 0X140BE9C10 + unitcontroller.cpp 断言 `!_pOrdersGroup->GetAssignedRailwayGuns.IsEmpty` 直名) — 定案。
注: attached wings 过滤链 = 槽掩码 LUT qword_1430B3FC8[item+1352] ∧ 翼+56(_pPool) → pool+32(def) → def+1448 = _Category 镜像#2 三环对书全平 (§4.23 +1032 行互证)。
注: +392 以外其余 qword 杂项 writer 零触, 语义未决。
注: 每帧 `sub_1414D40E0` **不是** og+72 对象的虚槽 — 它由 COrdersGroup vt[10] = `sub_140BF1660` 经 `sub_140BEA830(og+72)` 取对象后调用; og+72 对象自身无虚表 (ctor 零 vftable 写)。
> vt[10] 体三增量 (定案): 前导两列表 tick (sub_141036640) / 块A 变体对缓存 (+472 数组,
> +484 计数, +496..+500 对, memcmp 全等跳过重算) / +417 门 + +448 倒计时到期重挂。
> sub_140BF4760 = og+415 置脏实证位点 (caller 持 "sGroup()==_pOrdersGroup" 断言)。
> 采样伪影: +BF1678/+BF18A8 = vt[10] 体后半 pdata 块 (非独立函数)。

#### 4.24.4 CArmyGroup (592B, writer 0X140BF75A0)

vt 0x142952348 直继 COrdersGroup; 自有键写在基类全键**之前**; 偏移 +0..+559 与 COrdersGroup 同布局:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +560 | COrdersGroup* 向量 | orders_group 数组数据 — 元素 = COrdersGroup* 直存, ref 对 = og 自身 id 对 (elem+8); 逐元 B320(12462, elem+8) 单行叶 | 门 计数@+572>0; tok 12462/0x30AE |
| +561..+571 | — | = orders_group 容器 data 尾 (+561..+567) + **cap u32@+568** (容器 {d@560, cap@568, c@572, alloc@576}; ctor 0X140BE9BC0) |  |
| +572 | uint32 | orders_group 容器计数 | |
| +573..+583 | — | = count 尾 (+573..+575) + **alloc@+576 = &off_143085170 静态空分配器哨兵** + 垫 (+580..+583)  |  |
| +584 | uint8 | collapse | 真才写 yes; tok 14894/0x3A2E |
| +585..+591 | — | **尾垫** (ctor 末写止于 +584; sizeof 0x250 由剧院 reader 与多处 malloc(0x250) 直证闭合) | |

注: 随后**尾调基类 writer 0X140BF7630(a1, a2)** → COrdersGroup 全部键照发 (ctor 另将 +57 预置 1, 故 CArmyGroup 的 field_marshal_group bool 恒 yes) — 派生尾调基形态。
注 (GUI): Badge 名字聚合 tooltip — +560 容器逐元 +80 = 含军名清单 (军→单名 +80); 0X14169D860 → UNASSIGN_ARMY(_GROUP)。

#### 4.24.5 COrderInstance (968B, writer 0X14104B570 / **reader 0x14103E110** / postload 0x141037300; vtable 0x142986718 — reader 三件套 serfam+内证双源)

> root_front (oi+600) 解析访问器 = sub_141035650: CID → sub_14221F310 → RTDynamicCast → CFront → 返 CFront+112 = CControllerArea\* (§4.24.6 +112); root_front 空 (哨兵) 时按 type 兜底 — 3 (入侵)/4 (空降) 取 path[0], 1 (移动) 沿 path (+112/+124) 逐省 → gs vt2[1] 省查询 → 省+208 区域指针。29 调用点全上溯证实宿主 = COrderInstance (§1.2 gs+600 无涉)。

> 归一化子步 = **sub_1410489E0** (child_front_ratios oi+896 SChildFrontData; 断言精确串 = "NumNonEmpty == 0 || WeightSoFar == 100_fixed" :7360, 末非空元收余量定标)。

> **SChildFrontData 补全 (定案)**: 四界值实名 pair/path_section_start/path_section_end (token 15777-15780) + **+48..+71 control 块 = 6 锚省 id** (起/中/止三对; token 10896; 产自 sub_141049F40 尾段沿 sorted_pairs); reader = sub_14103F4E0 (token 63→+8 group / 47→+24 size / 15777-80→+32..44)。⚠ +56/+888 两字段系 **COrderInstance 本体字段** (原备注误挂本段): +56 = _pOrdersGroup (:558 断言, 5 消费点) / +888 = _pAttachedChildGroup (:1906 reader 键)。**GenerateOrderName sub_141029490** = 按战略区键哈希查国家名字池 + 确定性种子 (sorted_pairs 计数@+148 + instance_id@+580) 写 +288/+320/+352/+416/+448 (勘误: §4.33.15 12730 行原「准备流水线」实为名字生成)。小时 tick sub_141036640: route_is_ok + 空入侵/空降单**自动投删除令** + 入侵准备进度 +216 (MODIFIER_NAVAL_INVASION_PREPARATION_SPEED 386) + 空降执行; 前线重建巨核 sub_14103F710 (逐成员定槽 {省, 权重钳 [1,255]}); 前线推进箭头连接几何核 sub_141039F80 (删除/路径/配对三核共用)。

**orderinstance.cpp 簇对账增补 (33 函数全定名, 20 项此前未收)**: **新字段行** — oi+56 = COrdersGroup\* _pOrdersGroup 回指 (writer/reader 不序列化) / **oi+960 = u64 faction_theaters 总和缓存** (sub_14104B4D0 SIMD 求 +936..+948 写 +960) / +180 = 运行期 path 采信旗 (单消费点, 语义推定) / **+752{c@+764} 实边与 +776{c@+788} 虚边 = 载入侧树边 id 双暂存** (消费者 sub_14102B680: 按 +580 查 id → 实连 0x14102F010 / 内联虚连, 尾双清零; og 侧驱动 = og post-load 0x140BF1970); **oi post-load 0x141037300** (postload_classes 直证): type3 → 刷新 + convoys 块重挂 og+60 链 → faction 求和写 +960。**关系链闭合**: og tick 0x140BF1660 → oi tick 0x141036640 (尾递归子树); AddMember 全量版 sub_14103D720 (fallback 旗 → og+440 HQ + og+560..572 全军群通报; 正常沿父链自顶向下分发, :557/:558 断言直证); Connect 实边 sub_14102F010 第三效果 = **清子 +880 manage_child_sections**; dtor sub_141028340 (floating_harbor 清算: hp 满额 → 还港, 否则日期比较到期清零或扣减; "COrderInstance tree is deleted incorrectly! Use COrderDeleteCommand instead!" :188); 插值前线省序列重建 sub_141044480 (type2 取 path 区间 / type3 整 path / type4 path[0]) → 重建巨核; 订单类型 assert 锚: 1 = ORDER_MOVE / 3 = ORDER_INVASION / 4 = 空降 / 2 = 前线推进族 / 5 = 防区族 (后两者消费面反推待裁)。**+528 = scheduled_member 容器** (元素 COrdersGroupMember 视口, writer 键 12465 元素经 vt[32] thunk → unit — 与 §4.34 AI 域增补段的 CFront 误配同批裁定修正)。

**全字段表** (sizeof 0x3C8=968 reader malloc 定案; ⚠ 勘误: 「发射序 = 表序」不成立 — **writer 实际发射序** = 12386(型3)→225→372→11835→12463→13812→13813→14339→16018→13814→12059→12538→10462/10463→12536→19049→19713/19714→13121/14680/14681→13717→12466/12465→13138→16016→12467→13810→12662→14028/14036→14572/14770→13118 族(+13119/10639/10640/13156)→13222→13272→424(+216 time)→14073→14373→14647(+282)→15776→338→15783(+880)→19766; time/route_is_ok/manage_child_sections/attach/floating_harbor 位置均与偏移升序不符 — 表行仍按偏移升序排, 供字段查阅):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | CConvoySubscriber 内嵌视口 | convoys 块 (tok 12386/0x3062) | **type==3 (海军入侵) 才整块写**, 先于 type 键; ADEC0(0x3062, oi+8); 块说明见下 |
| +48 | uint32 | type 订单类型枚举 | 恒写 (锚 5/2); tok 225/0xE1 |
| +64 | 内嵌 CGameDate (24B {vt@+64, hours@+72, vt@+80}) | creation_date | 门 hours u32@+72≠0; ADEC0 转发 +16 视口 (oi+80); 引号 "Y.M.D.H" (锚 "1936.1.1.14"); tok 14339/0x3803 |
| +88 | 内嵌 CGameDate ({vt@+88, hours@+96, vt@+104}) | starting_date | 门 hours@+96≠0 (锚 "1.1.1.1" 合法非哨兵语境); tok 16018/0x3E92 |
| +112 | uint32 向量 | path 数组数据 (_Path; 断言 orderinstance.cpp:1792) — 省份 id 直存 (发射器 4B stride 直读; reader 372 → sub_1401F95D0 直入, 无 resolve) | 门 计数@+124>0; tok 372 |
| +124 | uint32 | path 容器计数 | |
| +136 | 匿名结构 (16B 形状) 向量 | sorted_pairs 数组数据 — 16B 元 {ptr, ptr}, 值 = ru32(ptr+164) 平铺 (路径图边省对; 锚 32 对); AF2C0+AF520 单行叶 | 门 计数@+148≠0 (from/to 同门); tok 13121/0x3341 |
| +148 | uint32 | sorted_pairs 容器计数 | |
| +160 | uint32 | sorted_pairs_from | 同 sorted_pairs 门; ADFE0 (锚 0); tok 14680/0x3958 |
| +164 | uint32 | sorted_pairs_to (锚 32) | 同上; tok 14681/0x3959 |
| +168 | 匿名结构 (NNB 形状)* | enemy_controller_area 链 (**实名 _pCachedEnemyArea** :1559) — ca = *(oi+168), 值 = ru32(rp(rp(ca+40)+164)) 两跳 (锚 445); 断言串 orderinstance.cpp; **载入链 = +176 暂存省 id → post-load sub_14103BCA0 → 省+208 区 → +168 区指针并清 +176** (失败日志 :1986) | 门 = 指针非零 且 计数@ca+60>0 且 (ru8(rp(rp(ca+40)+184)+210)&1)==1 (陆省旗); tok 13717/0x3595 |
| +176 | uint32 | **敌区锚省 id 载入暂存** (reader 13717 读入; post-load sub_14103BCA0 消费后清 0) | 运行期归零 |
| +184 | uint32 | invasion_source | 门 ≠0; tok 12662/0x3176 |
| +216 | fixed×1e-5 (int64) | time | 门 i64≠0; tok 424/0x1A8 |
| +224 | uint32 向量 | **states** (_AreaDefenseStates; 断言 orderinstance.cpp:1800) — 州 id 直存 (同 path 形态, reader 11835 直入) | 门 计数@+236>0; tok 11835/0x2E3B |
| +248 | uint32 | area_defense_settings 枚举 (锚 68) | 门 ≠0; tok 14073/0x36F9 |
| +256 | 匿名结构 (32B 形状) 向量 | area_defense_state_assignment 数组数据 — stride 32 元 {state_id u32@+0, 内层数据指针@+8, 内层计数 u32@+20}; 行 = state_id + 内层 8B 对 {type, id} 逐对平铺 (重复不编号; 锚 `{55}` / `{56 51 22}`); 每元独立一行 | 门 计数@+268>0; tok 14373/0x3825 |
| +268 | uint32 | area_defense_state_assignment 容器计数 | |
| +280 | uint8 | blitz — 真时附加 blitz_provinces (下方 +800) | 门 u8 真 → AE850; tok 14028/0x36CC |
| +281 | uint8 | withdraw — 真时附加 withdraw_lines (下方 +856) | 门 u8 真; tok 14572/0x38EC |
| +282 | uint8 | route_is_ok — 每 update 由 sub_141036640 计算: type3 海军入侵 sub_141037DE0 (错误键 NO_UNITS_ASSIGNED_TO_ORDER / NAVAL_INVASION_NOT_REACHED_START → 通用 sub_14103CA80) / **type4 = 空降** sub_141038200 (战略区兼空域 prov+200 航线 sub_141024800 + 逐成员制空比 ≥ NAir.PARADROP_AIR_SUPERIORITY_RATIO, 消费面 AIR_INVASION_PLAN_CAP_REACHED) / 其他恒 1; 断言 "Updated == false" orderinstance.cpp:3270 | 真才写; tok 14647 |
| +288 | SSO 串 | operation {buf@+288, size 区@+304} (锚 "o_fall_rot") | 门 qword@+304≠0 (**无 readonly 门**); tok 12059/0x2F1B |
| +320 | SSO 串 | first | 门 qword@+336≠0; tok 10462/0x28DE |
| +352 | SSO 串 | second | 门 qword@+368≠0; tok 10463/0x28DF |
| +384 | SSO 串 | unique | **双门**: !AAFD0 且 qword@+400≠0; tok 12538/0x30FA |
| +416 | SSO 串 | prefix | 门 qword@+432≠0; tok 12536/0x30F8 |
| +448 | SSO 串 | postfix | 门 qword@+464≠0; tok 19049/0x4A69 |
| +504 | COrderInstance* 向量 | order_children 数组数据 — 值 = 子实例 instance_id ru32(elem+580); 载入侧 id 暂存 +752 (c@764), og vt[8] post-load resolve (sub_14102F010 双向 attach: 父+504 ↔ 子+480) | 门 计数@+516>0; tok 12467/0x30B3 |
| +516 | uint32 | order_children 容器计数 | |
| +528 | 匿名结构 (元素待裁) 向量 | scheduled_member 数组数据 — 元素 = CUnit+184 视口 (COrdersGroupMember); 载入 resolve 链 = idpair→CReferenceObject(unit+16)→−16→+184; 断言 orderinstance.cpp:1825同 member; 逐元 vt[32] 门 → B320(12465, ret+24) 单行叶; 断言 "Invalid scheduled member" | 门 计数@+540>0; tok 12465 |
| +540 | uint32 | scheduled_member 容器计数 | |
| +552 | 匿名结构 (元素待裁) 向量 | transported_member 数组数据 — 同 scheduled 形态; 断言 orderinstance.cpp:1840; 断言串 | 门 计数@+564>0; tok 13138 |
| +564 | uint32 | transported_member 容器计数 | |
| +576 | uint32 | all_transported_members | 门 ≠0; tok 16016/0x3E90 |
| +580 | uint32 | instance_id — 家族树父引用目标键 (锚 7) | 恒写 (AE0C0 无门); tok 12463 |
| +584 | uint8 | can_execute (值域 {0,1}) | 真才写 ADFE0(char); tok 12466/0x30B2 |
| +592 | 匿名结构 (NNB 形状)* | **withdraw_lines 源对象** — malloc 0x40 {pdx 容器@+0 (d@0, c@8, alloc@16), pdx 容器@+24 (d@24, c@32, alloc@40), qword@+48, qword@+56}; 分配点 sub_14102B8E0 (门 +281 withdraw 旗 且 +584 can_execute); 消费 sub_1410478B0 (链重建) / sub_141036410 (逐元索引) | 不序列化; 高置信 |
| +600 | uint32 | root_front.type — B320(13118, oi+600) (锚 {id=5 type=66}) | 门 qword@+600 ≠ 哨兵 qword_14333D528; **root_section/from/to/split_from 均在此门内** |
| +604 | uint32 | root_front.id | 同上 |
| +608 | uint32 | root_section | 门 ≠0 (随 root_front 门); tok 13119/0x333F |
| +616 | fixed×1e-5 (int64) | from | 门 i64@+616≠0 ∨ +624≠100000 → 双写; tok 10639/0x298F |
| +624 | fixed×1e-5 (int64) | to (⚠ 键 token 0x2990, 非 token "to") | 同门; tok 10640/0x2990 |
| +632 | uint32 | split_from (与 og+292 同 token 异物) | 门 ≠0 (随 root_front 门); tok 13156/0x3364 |
| +640 | uint32 向量 | midpoints 数组数据 (u32 省 id 直存, 同 path 发射型) | 门 计数@+652≠0; tok 13222/0x33A6 |
| +652 | uint32 | midpoints 容器计数 | |
| +664 | uint8 | fallback bool (⚠ 与 og 容器键同 token 异物) | 真才写 yes; tok 13272/0x33D8 |
| +665 | uint8 | virtual_order bool | 真才写 yes; tok 13812/0x35F4 |
| +668 | uint32 | virtual_creator | 门 ≠0; tok 13813/0x35F5 |
| +672 | uint32 向量 | virtually_created 数组数据 — 实例 id 直存 (非指针); 发射 sub_141026000; 析构时把自己 id 从 creator 实例的本容器 swap-remove | 门 计数@+684≠0; tok 13814 |
| +684 | uint32 | virtually_created 容器计数 | |
| +800 | uint32 向量 | blitz_provinces 数组数据 (_BlitzProvinces; 断言 orderinstance.cpp:1796; 省 id 直存) | 门 = blitz u8 真; tok 14036 |
| +848 | uint32 | **withdraw_lines 当前游标/索引** (24B stride 数组下标) | 不序列化 |
| +856 | 匿名结构 (24B 形状) 向量 | withdraw_lines 外层数组数据 — stride 24, 每元内嵌 u32 数组 {data@+0, 计数@+12} → 每元一个子行 (AF2C0+AF4B0 双层块) | 门 = withdraw u8 真 且 计数@+868≠0; tok 14770/0x39B2 |
| +868 | uint32 | withdraw_lines 容器计数 | |
| +880 | uint8 | manage_child_sections | **恒写无门** (yes/no 必现); tok 15783/0x3DA7 |
| +888 | 匿名结构 (NNB 形状)* | attach 载体 — 附加子集团; ref 对在 p+8; 非零才写 B320(338, p+8) | 门 指针≠0; tok 338/0x152 |
| +896 | COrderInstance::SChildFrontData** 向量 | child_front_ratios 数组数据 — 元素 = **`COrderInstance::SChildFrontData`** (RTTI 直读 `.?AUSChildFrontData@COrderInstance`; sizeof 72, vt 0x1429866C8, writer 0x14104C450 / reader 0x14103F4E0); 写点 sub_1424C24F0 = `arg2->vt[1](arg2, arg1)` (slot[1] = 0x1424BEC50 = CPersistent 家族共享 Save wrapper); 元素内 +8 = group / +16 ratio / +24 size / +32..+44 四 section 界值 | 门 计数@+908≠0 且 >0; tok 15776/0x3DA0 |
| +908 | uint32 | child_front_ratios 容器计数 | |
| +920 | uint32 | floating_harbor.type — 块 = 0X142220180(+920) + floating_harbor_hp | 门 (type\|id) ≠0; tok 19713/0x4D01; 仅 type=3 两栖入侵实例实证 (ENG id=6284 hp=100) |
| +924 | uint32 | floating_harbor.id | 同上 |
| +928 | fixed×1e-5 (int64) | floating_harbor_hp | **入门即恒写 (无 ≠0 门)** — 块门 = idpair 双 dword 非零 ∧ ref 可解析 (SetFloatingHarbor 恒写 10000000; 勘误: 原记「≠0 才写」); tok 19714/0x4D02 |
| +936 | fixed×1e-5 (i64) 向量 | faction_theaters 数组数据 — 阵营成员份额表 (每元素 = 该国单位数/总数 fixed×1e-5, 计数 0 → 0xFFFFFFFF); 填充 sub_14104AA40(oi, 国, faction+2552); 刷新 sub_14102FB30 (og tick 逐实例; 无阵营清空); 逐元 sub_1424C3900 单行叶 | 门 计数@+948≠0 且 >0; tok 19766/0x4D36 |
| +948 | uint32 | faction_theaters 容器计数 | |

注: 运行时容器 order_virtual_children {d@oi+720, c@oi+732} — 树展开消费 (writer 不发射独立键), 见 §4.24.9。
注: 树边模型 = order_children(+504) ↔ 父引用容器(+480, 元素 COrderInstance*, c@+492, d[0] 主父, sub_141034010 按类型找父; 树删除判 +492≤1) 双向实边; order_virtual_children(+720, 键 13810) ↔ 虚父引用(+696, c@+708) 双向虚边 (取根 sub_1410317D0 按 +665 旗选边); 载入侧配 +752/+776 id 暂存; +824 = 省 id 区间对数组 {lo,hi} u32×2 (查询 sub_141037DB0)。
注: oi+592 / +848 成对 — withdraw_lines (+856 外层 24B stride 数组) 由 +592 源对象拷贝生成, +848 为遍历游标 (sub_141036410 返回 `+856 + 24*+848`); 生成门 = +281 withdraw 旗 且 +584 can_execute。
注 (convoys 块): CConvoySubscriber 内嵌@oi+8, 对象 vt 0x14295c0f0, writer 0X141022CB0; writer 首行 `if (*(oi+48)==3) ADEC0(12386, oi+8)` — convoys 块先于 type 键; `convoys = u32@(oi+16)` / `total = u32@(oi+20)` (⚠ 合同族语境下块仅在 total≠0 时写, 见 §4.23.2)。

#### 4.24.6 CFront (136B, writer 0X140F01A60)

reader 0X140EFCF10; front 块全字段落盘 (writer 键集 = {id 壳, 13444, 10288 provinces 数组形, 13544, 13120, 13093 section 块, 11157}; +56 provinces ptr 数组发射键 10288 / +88 section ptr 数组块键 13093 — 元素类 CFrontSection reader malloc 0x60 + ctor sub_140EE9E00 互证)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | id 对.type — B400 壳 → `id={ id=N type=66 }` | 恒写 |
| +12 | uint32 | id 对.id — B400 壳 | 恒写 |
| +13..+31 | — | = id 尾 (+13..+15) + **u8@16 = CReferenceObject 基类 IsStored 旗** (ctor 置 0, 注册成功由 vt[9] 置 1) + 垫 + **owner CTheatre*@+24** (新建时回指所属战区)  | CFront ctor = CTheatre reader case 10720 内联块 |
| +32 | 匿名结构 (NNB 形状) | provinces 容器数据指针 — ptr 数组, 值 = ru32(elem+164) (一跳) | c>0 |
| +33..+43 | — | = provinces 容器 data 尾 + cap@+40  |  |
| +44 | uint32 | provinces 容器计数 | c>0 |
| +45..+55 | — | = count 尾 + alloc@+48 (哨兵) + 垫  |  |
| +56 | tag_id | enemies 容器数据指针 — u32 tag_id 数组 (4B 元素) → 引号 tag 串, 每元独立行 | c>0 |
| +57..+67 | — | = enemies 容器 data 尾 + cap@+64  |  |
| +68 | uint32 | enemies 容器计数 | c>0 |
| +69..+79 | — | = count 尾 + alloc@+72 (哨兵) + 垫  |  |
| +80 | uint32 | id_counter | 恒写 |
| +88 | CFrontSection* | section 容器数据指针 — ptr 数组 → CFrontSection | c>0 |
| +89..+99 | — | = section 容器 data 尾 + cap@+96  |  |
| +100 | uint32 | section 容器计数 | c>0 |
| +101..+111 | — | = count 尾 + alloc@+104 (哨兵) + 垫  |  |
| +112 | CControllerArea\* | 区对象指针 (勘误: 原「CFrontSection\*」系类名误标 — 错误串 "Front refers to invalid controller area…" theatre.cpp:3685/3688 + EFBED0 以 prov+208 区指针直接赋值 + EEB190 建造存区对象三函数闭环; AI 口袋追击 sub_14108C290 经 vt[1] 取控制方 tag; area 标量 = ru32(rp(rp(fr+112)+40)+164); +124 u8 = 区锚省验证位) | 恒写 |
| +113..+124 | — | 拆分见 +120/+124 两行 | case 10720 word 写 0x0100 (低半 = +124 配对标记, 高半 = 1) |
| +125 | uint8 | dirty — ctor 初值 = 1 (新建 front 默认脏; reader 13444 经 sub_1424C0C00 双参形态**载入** +125) | 恒写 → yes/no |

**reader 补键表** (writer 无对应键):

| reader 键 | 语义 |
|---|---|
| 11157 area | 载入 +120 锚省 id (post-load 重建 +112) |
| 13120 id_counter | 载入 +80 |
| 13444 dirty | 载入 +125 (writer 恒发, 首键) |
| 10983 | enemies 单串形读侧键 — 与 13544 数组形同目标 front+56; 断言 "Front refers to invalid country tag" 同串 |

注: +16 u8 = **CReferenceObject 基类 IsStored 旗** (定案, 非本族语义字段); +120 u32 / +128 qword 两槽 ctor 置 0、dtor 不触、writer 不触 ⇒ +120 = area 锚省 id (读写异位: writer 从 +112 两跳取值; post-load sub_140EFC6D0 → sub_140EFC390 以 +120 取省 → 省+208 = CArea → 回填 +112, 消费即清 +120 = 0; 失败两级: 省 id 无效 → 静默返回 (+112 保持 0, 调用方 swap-remove 删前线); 区空 (:3685) ∨ enemies 不含该省 controller tag (:3688, 校验 = sub_1401B0250 逐 u32 + 别名归一) → terminate 级 fatal, 不走删前线); +128 qword = ctor 清零后全库无访问者 (负定案: 保留槽)。

theatre.cpp worker 补全 (定案): 未收 9 函数定性 — **sub_140EF5AE0** = CFront::FloodPath (:3043 无限循环日志) / **sub_140EFBED0** = CTheatre::FixFrontsAfterAreaReplaced (区替换时前线重定位/删除, :1415) / **sub_140EFD790** = CFrontSection reader vt[4] (元素类实名 **CFrontSection::SPerCountrySection**) / **sub_140F00F50** = CFrontSection::TakeProvincesAndPairs / **sub_140EEA6A0** = ~CTheatre (vt[0]) / **sub_140F00580** = RemoveOrdersGroupFromTheaterGroup (:1745 "come to me, Ilya") / **sub_140F018F0** = SetMainProvince (CTheatre+232 主省槽) / **sub_140EF8630** = CFront vt[8] RegisterWithNewId (type = 66, sections > 128 fatal)。结构性新定案: **NTheatreManager 三组静态** = g_OccupationBundleConquer/Relation (0x14333D2C0/330, 各 0x70B, _IsActive@+96, 断言串实名) + SInterpolatedFrontBundle 派发队列 (0x14333D398, 16B 条目 {og idpair, instance_id, u8}, <4 串行/≥4 tbb); **CFront/CTheatre vt[8] = RegisterWithNewId** (id 高水位 dword_143087264/268); **managerobj+1941 = 战区脏旗双写点** (sub_140EF1EE0 入 1 / 出 (gs+1312>0) — 主文件 CSession+1941 待裁条由此消解); CFront reader 补键 141(priority)/10288(丢弃); AddUnit 补 empty-og 清理链与重校验差异旗置位; 收口 "theatremanager.endbundle" profiler 域。调用主干: 读档完成 sub_140DD6A30 → sub_140EF9280; 前线重建 sub_140EE9560(tbb) → sub_140EF9710 (脏门 front+125) → sub_140EEE090 BuildSections → FloodPath/TakeProvincesAndPairs; 区替换 sub_140CF7E10 → sub_140EFBED0; bundle 窗 EED690 → EFCA60 入队 → EF2F30 → EF1EE0×2 → EF18B0。

#### 4.24.7 CFrontSection (96B, writer 0X140F01FD0)

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | id (**裸整数非 id 对**) | 恒写 |
| +9..+23 | — | = id 尾 + 垫 + **owner CFront*@+16** (ctor 第二参直存; 与 CFront+24 对称)  | ctor 0X140EE9E00 |
| +24 | 匿名结构 (24B) | per_country_section 容器数据指针 — 24B 内嵌元素数组 (非指针): country tag_id@+8 → 引号串 / index u32@+12 / count u32@+16 (均恒写; 元素 writer 0X140F029F0) | c>0 |
| +25..+35 | — | = per_country 容器 data 尾 + cap@+32  |  |
| +36 | uint32 | per_country_section 容器计数 | c>0 |
| +37..+47 | — | = count 尾 + alloc@+40 (哨兵) + 垫  |  |
| +48 | 匿名结构 (NNB 形状) | provinces 容器数据指针 — ptr 数组, 值 = ru32(elem+164) | c>0 |
| +49..+59 | — | = provinces 容器 data 尾 + cap@+56  |  |
| +60 | uint32 | provinces 容器计数 | c>0 |
| +61..+71 | — | = count 尾 + alloc@+64 (哨兵) + 垫  |  |
| +72 | 匿名结构 (16B 指针对) | sorted_pairs 容器数据指针 — 16B 指针对数组, 每对两 ptr, 值 = ru32(ptr+164) 平铺 | c>0 |
| +73..+83 | — | = sorted_pairs 容器 data 尾 + cap@+80 (sizeof 0x60 malloc 直证) |  |
| +84 | uint32 | sorted_pairs 容器计数 | c>0 |

#### 4.24.8 CTheaterGroup (96B, writer 0X14163AA40)

ctor 0X141639B00; vt 0x1429E5C50。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | id 对.type — B400 壳 → `id={ id=44 type=68 }` (ref 槽 = qword_14333D528 哨兵) | 恒写 |
| +12 | uint32 | id 对.id — B400 壳 | 恒写 |
| +13..+31 | — | = id 尾 (+13..+15) + **u8@16 = CReferenceObject 基类 IsStored 旗** (ctor 置 0, 注册成功由 vt[9] 置 1) + 垫 + **owner CTheatre*@+24** (ctor 第二参)  | ctor 0X141639B00 |
| +32 | uint32 | priority | 恒写; GUI: 剧场组行重编号 |
| +40 | SSO | name (24B {buf@+40, size@+56, cap@+64}) | **恒写 (!readonly, 无空串守卫)**; GUI: 改名命令 |
| +41..+71 | — | = name SSO 32B 内部 (buf 尾 + size@+56 + cap@+64=15; 标准 MSVC 空态)  |  |
| +72 | COrdersGroup* | orders_group 容器数据指针 — ptr 数组, B320 视角 elem+8: `id=ru32(e+12) type=ru32(e+8)` 单行叶 | c>0; GUI: 剧场组行命中 |
| +73..+83 | — | = orders_group 容器 data 尾 + cap@+80 (sizeof 0x60 闭合) |  |
| +84 | uint32 | orders_group 容器计数 | c>0 |

注 (GUI): 剧场组行消费四键 = CTheaterGroup +32 / +40 / +72 与 COrdersGroup +92 (定案)。
注 (GUI): +32 重编号 = CTheaterGroupItem populate sub_141E6F9A0 命中; SettingsView [4] Refresh 行重编号同键。
注 (GUI): +40 改名命令 = CSetTheaterGroupNameCommand (RTTI 直证)。

#### 4.24.9 member/scheduled_member vt[32] thunk 与 order_instance 树展开

**成员元素载体表** (og member / oi scheduled_member 同规则):

| 载体 | 存储 | 读法 |
|---|---|---|
| og+80 member 元素 / oi+528 scheduled_member 元素 | CUnit+184 子对象视口 (非裸 unit 指针; vt 0x142953320 = CUnit 三 vtable 之一) | vt[32] = 0X140BF95D0 = `return a1-184` (标准 owner thunk) → unit 本体, ref 对在 unit+24; 读侧终式 `base = elem − 184; type = ru32(base+24); id = ru32(base+28)` |
| og+104 leader_unit | unit+184 视口 (同 member) | 同上 |
| og+136 leader | CArmyLeader 本体 | B320(p+8) → `id=ru32(p+12) type=ru32(p+8)` (标准 CReferenceObject 位) |

注: 元素类型动态双态 (type=51 师 / type=4713 将官 — CArmyLeader 亦 CUnit 派生); 无需按类分支, −184 统一适用。

**order_instance 树展开步骤表** (og+152 只存根实例):

| 步 | 动作 |
|---|---|
| 1 | 根 = og+152 容器全体 |
| 2 | 每根: 根实例 → order_children {d@oi+504, c@oi+516} 先序递归 |
| 3 | 再 order_virtual_children {d@oi+720, c@oi+732} 先序递归 |
| 4 | 去重 = 列表级: append 前扫当前列表, 已在列则不追加但仍递归防环 |
| 5 | 收集后逐元 ADEC0 |

#### 4.24.10 hq_deploy_distributable (og+392 对象; writer 0X14193EED0)

对象 *(og+392), 记 0x98B; vt 0x142A1CE50 = CPersistent@+24 视口 (CEquipmentDistributable@0, §4.24.1); ctor 0X14193E610 (基 ctor 0X1415A7410); writer 收 obj+24。

**全字段表** (obj 相对):

| obj 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | priority | **≠1 才写** (默认抑制) |
| +9..+31 | — | = priority 尾 (+9..+15) + **qword@+16 (属 CEquipmentDistributable 基类域)** — 基 ctor 0X1415A7410 只做三事 (`*(a1+8)=1` priority 默认 / `*a1 = &CEquipmentDistributable::vftable` / `*(a1+16)=0`); vt 0x1429DC100 实为 6 槽 5 实 (RTTI 证 CEquipmentDistributable 无基类); CPersistent 视口住派生类主表 0x142A1CE18 [7..15] 与 0x142A1CE50; 该域及派生域逐扫均无 +16 消费 ⇒ 保留槽死字段 (负定案)  | 基 ctor 0X1415A7410 |
| +32 | uint32 | country tag_id → 引号串 | 门 tag>0 (sub_140BB59C0 体; ctor 清零) |
| +40 | 内嵌 | hq_assembled_equipment = CEquipmentVariantPool (writer 0X141012DB0): 数组 {d@obj+72, c@obj+84} stride 16 {variant ptr, amount i64 fix5}; **元素写门 amount≠0 或零旗 u8@obj+96**; id 对 = {type@variant+8, id@variant+12}; allow_zero_entries = u8@obj+96 **恒写** | 恒写块 |
| +41..+103 | — | = **池1 CEquipmentVariantPool 64B** (ctor 0X14100C710): vt@40 + 容器1@48 {d@48, cap@56, c@60, alloc@64} stride 24B 预扩容 max(1, defines/10) — **容量预置但恒空的保留容器** (writer 0x141012DB0 只遍历容器2 并写零旗 +56, 容器1 零触) + **容器2@72 = hq_assembled_equipment 数组本体** (stride 16) + 零旗 u8@96  | 0X14100C710 |
| +104 | 内嵌 | hq_requested_equipment = CEquipmentArcheTypePool (writer 0X141012D40): 数组 {d@obj+112, c@obj+124} stride 16 {archetype ptr, amount i64 fix5}; **键名动态** = token_name(ru32(archetype+8)) | amount≠0 |
| +105..+135 | — | = **池2 CEquipmentArcheTypePool 32B** (ctor 0X14100C630): vt@104 + 垫@108..111 + 容器@112 = **hq_requested_equipment 数组本体** (stride 16, 预扩容同式)  | 0X14100C630 |
| +136 | uint32 | hq_assembled_manpower | 恒写 |
| +140 | uint32 | hq_requested_manpower | 恒写 |
| +144 | uint32 | hq_deploy_order | 恒写 |
| +148 | uint8 | hq_requisitioned_from_army → yes/no | 恒写 |

#### 4.24.11 CNavyTheater (40B, cc+352; writer 0X141518C70)

身份表:

| 项 | 值 |
|---|---|
| RTTI 名 | CNavyTheater |
| sizeof | 0x28 = 40 |
| vtable RVA | 0x1429D2B88 (RTTI 仅继 CPersistent) |
| writer (vt slot2) | 0X141518C70 — 逐元 ADEC0 token 13777 theater_group |
| ctor / dtor | 0x1415182D0 / vt[0]=0x1415183E0 deleting (vt[1]=0x1424BEC50 系家族共享 Save wrapper, §4.00.1) |
| loader (vt slot4) | 0X1415189D0 — 收 13777 建 CNavyTheaterGroup |
| 挂载点 | CCountry writer 0X1407191B0 以 token 15159 navy_theater 整块发射 cc+352 (段侧已实现) |

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | country tag (运行时; 不序列化 — writer 零读 +8, loader 仅 case 13777) |  |
| +16 | CNavyTheaterGroup* 向量 | theater_group 数组 (CPdxScopedPtr 独占; loader sub_14031ECD0 直证) {d@+16, cap@+24, c@+28, alloc@+32} | 逐元 ADEC0 tok 13777 |

#### 4.24.12 CNavyTheaterGroup (96B; vtable 0x1429DCCE0; writer 0X1415B9B20 / reader 0X1415B97E0 / ctor 0X1415B9390 / dtor 0X1415B9460; navytheatergroup.cpp)

ctor 0X1415B9390; sizeof 0x60 = 96; owner CNavyTheater 回指@+24。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | — | refid |  |
| +24 | CNavyTheater* | owner 回指 |  |
| +32 | CFleet* 向量 | fleet 容器 {d@+32, cap@+40, c@+44, alloc@+48}; 元素回指 CFleet+208 = 本组 (setter/getter 对 sub_140D5A620/sub_140D50F00) | 逐元 tok 15156 |
| +56 | SSO | name — tok 27 (默认 "NEW_THEATER_GROUP"; ⚠ 与陆军 CTheaterGroup+40 异构) |  |
| +72 | — | SSO size 字段 (非 idpair); GUI 链 = item+72 ← grp+8 refid (SetTarget sub_141E73010) |  |
| +88 | uint8 | is_important (tok 15575) |  |

注 (GUI): 命令族 RTTI 实名 = CSetNavyTheaterGroupForCommand / CSetNavyTheaterGroupImportantCommand / CSetNavyTheaterGroupNameCommand。
注 (GUI): CNavyTheaterGroupItem (sizeof 0xB70) target = item+72 ← grp+8 refid; 基 CNavyTheaterGroupItemBase = CStandardGridBoxItem@0 + CTooltipHandler@24, 新添槽 [19] SetupDerived / [20] Reset。

本节未决:

- CTheatre +432/+280/+408 三项已定案 (+432 = CArmyGroup* 回收登记向量 / +280 = AI 海运规划缓存 / +408 = Fronts per enemy area 字典 — 见 §4.24.2 表)。
- COrdersGroup +72 内嵌 0x198 对象类名 = **负定案 (无独立 RTTI 类)**; +415/+496 槽语义已定案 (§4.24.3 表)。
- hq_deploy 池1 容器1@48 = **预扩容零填充保留容器 (定案)** — ctor sub_14100C710 按 24B stride 预扩容 `max(1, sub_14022FA10()+140)/10`, writer sub_141012DB0 只遍历容器2 (obj+72) 并恒写零旗 (obj+96, 键 10208), 容器1 全生命周期零触。
- +16 u8 家族旗 (CTheatre / COrdersGroup / CFront / CTheaterGroup / CNavyTheaterGroup 同位) = **CReferenceObject 基类「ID 已注册」旗 (IsStored)**: ctor 一律置 0; 注册成功由 CReferenceObject vt[9] sub_14221E990→sub_14221E700 尾 `*(a1+16)=1` (id.cpp:130); 反注册 sub_14221EA60 首行 `if(!*(a1+16)) return 0` (id.cpp:210, 失败路径 "Failed to delete ref object … double free") 据此短路 — **非本族语义字段** (定案)。

#### 4.24.13 CFrontControlStrategyData (前线控制策略数据)

| 项 | 值 |
|---|---|
| RTTI 名 | CFrontControlStrategyData |
| sizeof | 312 (0x138) — malloc 实参 |
| 继承 | CStrategySpecificData 派生 (RTDynamicCast 双证) |
| 基 ctor / 工厂 | sub_140645740 / sub_140647750 case 'O' (策略槽 id = 79) |
| 宿主 | AI 策略库 qword_14332EE00 (CAIStrategyDatabase) 的 `_StrategySpecificData` 容器 {data@+112, count@+124} — 独立堆对象, **非** CAIFront+536 内嵌块 |
| 取法 | 遍历国家策略项 (`(cai+104)->vt[48](79)`) → 项 +4 得 index → 容器[index] → RTTI cast; 有效性门 sub_14065E860(pData) ∧ !pData+310 |
| 消费点 | sub_1410863B0 (ai_general) / sub_1414AEF30 (ai_front_helper) / sub_141A4BB40 (ai_operation); 微操并行入口 sub_141088820 第 5 参 = `CPdxArray<CFrontControlStrategyData const*>` |

- ctor 初始化: +288 dword=0 / +292 u8=0xAA / +296 / +300 u8=0xAA / +304 / +308 word=0xAA / +310 u8=1。

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +288 | int32 | **策略优先级/评分** — 越大越优先; 消费者「≥ 当前最优才替换」 | 定案 |
| +292 | int32 | optional<int32> #1 值 | 推定 |
| +296 | uint8 | optional<int32> #1 has_value | 推定 |
| +300 | int32 | optional<int32> #2 值 | 推定 |
| +304 | uint8 | optional<int32> #2 has_value | 推定 |
| +308 | uint8 | optional<uint8> #3 值 | 推定 |
| +309 | uint8 | optional<uint8> #3 has_value | 推定 |
| +310 | uint8 | **有效性门位** (ctor = 1) | 定案 |

> 结构定案 = 1 评分 + 3 optional; 语义高置信 = 三个可选阈值/开关, 与 +288 评分共同驱动前线控制策略选择。
> 消费点 (ai_front_helper `sub_1414AEF30` 的 `0x1414B0530` 区块): 先 `sub_14065E860(rbx)` 有效性门 →
> `if (*(int*)(rbx+288) < 最优值) skip` → `sub_14065F0E0(rbx, 前方线)` 匹配门 → 取 +300/+304 optional
> (has_value 假则取默认) → 取 +308/+309 optional。

> **本域 GUI 类布局**: 见 4.31.36。
- **ApplyCombatXpGains tbb 族** (符号串直证, 定案): 合并核 sub_140BB5AC0 / 发射体
  sub_140BB60F0 / 分裂体 sub_140BB6260 — 战斗经验入账的并行三件套。
- **COrdersGroup 小时执行步** (定案): 驱动 = hourly 相位 2 tbb parallel_for →
  每国 sub_1406FDBA0 → CTheatre::Update sub_140EF8470 (首步清 AI 海运缓存
  +280) → 逐 og/ag 虚调 **og vt[10] Update sub_140BF1660** → 索引器主执行
  sub_14014D40E0 (详 §4.24.14) — 非每帧 (高速档多 tick 叠加的采样表象);
  worker 侧采样 7.5%。

#### 4.24.14 COrdersGroup 小时执行链 (unitcontroller)

驱动 = hourly 相位 2 tbb → 每国 sub_1406FDBA0 → CTheatre::Update
sub_140EF8470 (①清 AI 海运缓存 +280 ②逐 og (theatre+128/140) 调 vt[10] ③逐 ag
(theatre+152/164): ag vt[12]() 真者回收解散, 否则同调 vt[10])。og vt[10] =
**sub_140BF1660 八步序**: ① og+152 order_instance + og+176 fallback 逐实例
sub_141036640 route_is_ok tick ② leader 根 OI 路径镜像缓存 (+472/+484/+496)
③ type3 时 oi+184 invasion_source 变化 → sub_140BEB640 重算 og+460/+464 ④
og+136 leader 非零 → **sub_140C21BC0 距离通讯衰减** (type2 取 og+452 / type3 取
og+460 / 否则 100000; 钳 [0, dword_143339704) 后查 qword_1433396F8 =
LEADER_MOD_COMMS_SCALING 表, 对 leader+2096/+2480 两对象各应用一次
sub_14060FBD0) ⑤ +415 脏旗 → plan_value 重算 ⑥ +417 → sub_140BF3C20 leader
三档传播 ⑦ **sub_1414D40E0(*(og+72)) 索引器主执行** ⑧ og+44 铁路炮计数非零 →
og+448 倒计时递减, 到 0 → sub_1414C55D0 重挂 + 重置 (定案)。

索引器主执行 **sub_1414D40E0** (og+72 对象, 408B): ①gamestate TLS 门 ②国别门
(gs+2408) ③begin sub_140E2CC00(*(indexer+8),1) 置旗清两脏数组 ④--indexer+352
包围圈倒计时 ⑤逐根 OI: 先逐 scheduled_member (oi+528/540) `member->vt[5]()` →
sub_1414DA4E0 补位航点维护 (unit+524 ≤0 清 unit+736; 航点数≠1 ∨ 末条 +12 省
id 失效 ∨ 与当前目的地不符 → 清重灌), 再按 oi+48 switch:

| oi+48 类型 | 分派函数 | 语义 |
|---|---|---|
| 2 前线 | (内联) + sub_1414D1F90 | 72h 到期 ∧ sub_1410362A0 解析 CFrontSection (oi+600 root_front → sub_140EF8020(front, oi+608)) ∧ sub_1406FFDB0 (战争 ∨ human_ai 旗) → sub_140EEFFB0/fsC40 采样的省对平铺 indexer+328 包围圈对表; oi+56 父 og 为 field_marshal_group (+57) ∧ oi+908 child_front_ratios>0 → 逐子 og sub_1414D1F90(indexer,oi,child), 否则 (…,0) |
| 3 海军入侵 | sub_1414D02C0 | 按 oi+124 路径省建 per-省登岸槽位 (8B/省); "pUnit->IsNavalInvasionUnit()" 断言 |
| 4 空降 | sub_1414D3B40 | 成员 +1461 运输机就绪门; sub_140E2AD40 战略区寻路成 → sub_1414BCA10 航点 + sub_1414C3A50 入队; 败 → sub_140E2A320 次选 → sub_1414C38F0 |
| 5 地区防御 | sub_1414CA270 | (根实例下标 + 流逝小时) % 4 == 0 才跑; 逐 scheduled_member + oi+224/236 states + oi+256/268 派驻表重算; 评分核 = **sub_1414D6AB0** (547 行, 定案结构): 逐防御州逐省评分 — 省+392 CGameDate 转日索引查侵入式 map 缓存 (未命中才调 sub_140700570 日期已过判定, gs+3976 per-day 表 entry+744 的 +73 旗取反), 资格门 = 控制者敌对 (sub_141036600) ∨ gate 旗 ∨ 缓存值, ∧ 州+2148 旗==0 ∧ 省+176==0; 不合格写 **−100000 哨兵**; 评分表 ≤32 插入排序 >32 并行归并; 16B 条目 {i64 分值, 堆对象{+0 省 id, +4 计分旗, +12 0}}; **同核复用 = 驻防订单 UI**: 簇外 sub_1414C44F0 (← orders 域 sub_140B68600 链) 以 oi+568 视角调 D6AB0, 分值>0 计数 = 可行省数 → "garrison_order_headline" / GARRISON_ORDER_CONF / REQ_DIVS (需求师数文案)【高置信】 |

逐军执行 **sub_1414D1F90** (indexer, oi, child_og): 门 = !oi+908 ∨ 子军份额非零
(sub_141036490, oi+896 72B 条目 +8=group/+24=size); child 时 sub_141033B80 取
子军 section 界值对存 indexer+376/+380; 逐 scheduled_member 谓词链筛选入列
(下表) → sub_141029470 虚父 (oi+668 → sub_140BEAA30) 路径 → sub_1414D75F0
目标计算 → **sub_140BEBDA0(og) 读清 og+414 members_has_changed** → 四拍门 →
**sub_1414CCF10** 核心分配 → sub_1414D3120 战斗中推进恒跑 → sub_1414CFBB0
成员→位下发 (og+424 cohesion_type==3 跳过; 有路径者按 v2 % 槽数 indexer+36
轮转消费 indexer+24 位置槽表) → sub_1414CC9C0 靠拢/集结 (og+428
proximity_type==4 跳过; 期望距离 sub_1415B0EB0 == og+452 跳过; 否则
sub_1415B0320 重定位) → AI 钩 sub_1410ABCA0 + sub_1410AC860 逐位发 token 14927
"province_weight" 消息 (定案)。

unitcontroller 层补全 (定案): **sub_1414D75F0 前线槽 wanted 规划** — DPP
(PLAN_PROVINCE_PRIO_DISTRIBUTION_*) 四点插值分支在 1.19.3 现态**死亡** (权重和恒 0 →
每槽 wanted 恒 1, 高置信体读; 四 define 名经 loader 反查定名)。**前线槽记录字段**
(sub_1414C2740 访问, 双函数交叉 = metrics 转储 sub_1414C7700 "AI FRONT DUMP" 门
indexer+356 打印 + 评分消费 sub_1414C87B0): +8 wanted / +28 AtLoc / +52 OnWay /
+88 前线数; C87B0 消费 define 反查全录 (DISTANCE_FACTOR / COHESION_WEIGHTS /
TERRAIN_DEFENSE / ATTACK / STICKINESS), 插入排序阈值 170。**CPendingStratNavyTransfer
补全**: 56B 布局 +8/+40/+48 语义定案 (分组工厂 sub_1414D5A70, :393 断言), 32B 派单条目
布局, 新读点 oi+580。**case 3 海军入侵批量补位** (sub_1414D02C0): 槽位轮转 = 成员序号 %
槽数; **每轮批量上限 = dword_1430B3860 = 3** (exe .data 静态实读, 非 define); 与 s4_34
拒动协议条的 case 3 = **同函数两阶段**, 非两函数。case 4 空降 (sub_1414D3B40):
scheduled_member 存**指入式指针 unit+184** (−184 还原单位; 与 §4.24.9 owner thunk 同规),
indexer+368 进口清零。**sub_1414D9280** = AI「把师送到前线」移动总校验 (:4270 断言; 行号
表 4270/4397/4410/4446/4499/4526/4555), 海军登岸拆分 = sub_1419690B0 → TransportUnit/再寻路,
FRONT_MIN_PATH_TO_REDEPLOY 路径长门; **sub_1414D5030** = 海军入侵单单位目标省选择
(1.1 容差兵力比; PLAN_MAX_PROGRESS_TO_JOIN / RESERVE_TO_COMMITTED_BALANCE 双 define 门;
CCommand 直执行路径 sub_141361B30 vt[9]/[10], :4140 断言; 调用者 = 战斗推进 sub_1414D3120);
**sub_1414CC9C0** 靠拢拒因 6 写法 = +590=1 / +680=6 / +592=0, 下发统一走退避门 sub_1414C9D10。
**sub_1414C55D0** 铁路炮分配重挂: ProvincesInRange 半径 = 2×聚集宽度; AI 日志通道键 =
NAVAL_TRANSFER_PRIORITY; 炮跨海也走 TransportUnit 工厂。单位类型判据 = **unit+8 非 0 =
IsNavalInvasionUnit (:1939) ∧ ≠ 13 = IsNavalTransferUnit (:236)**。

unitcontroller 层补全二 (定案/高置信): **sub_1414CC540 = 战斗推进 (D3120) 的移动下发底座**
(231 行, 调用者 = D3120 选定目标省后): 路径非空且末省 == 目标 (+164) → 逐省调 unit vt 槽[14]
(+112) 通行性校验, 全可达免发返 0; 否则按日期旗二选一重寻路 (真 → sub_140E2A320 10 参变体 /
假 → sub_140E2ADE0 9 参变体) → 写 unit+736 航点容器 → CPendingAddMovement 工厂 sub_1414C38F0
入队; 成功后调用方做**拒动三清** +590=0/+680=0/+592=−1 (与 CCF10 放行三清同款); 返 1 = 已尝试重发
(寻路失败也算)。**C55D0 尾段拒动码 5** = 铁路炮重挂无路径: +590=1/+680=5/+592=0; 且在途
(+524>0) 时先 malloc 24B 构造 **CPendingCancelMovement** (+0 vtable/+8 CUnit*/+16 u8 旗) 经
统一入口 sub_1414D4B50 入待办容器再拒动三写 (字段布局补全, 书原仅记 24B)。**D75F0 槽位人员数
收敛段** (高置信): target = round(wanted × 0.5) (50000/100000 取整式); AtLoc>0 → 把 OnWay 容器
逐条摘入 indexer+80 工作列清 +52; AtLoc+OnWay+76 超 target 走裁撤 (裁空断言 :5473 "Could not
find unit to unassign from orderslocation"); 包围点必须非海省 (:5271)。**文本 dump 家族单旗门控**:
indexer+356 一旗同控三处 ofstream 写盘 — CCF10 (:3025 "Find best unit for: " 逐省+槽明细,
CFileException 处理 = EH funclet sub_1426409C0 :3125) / C87B0 (:3970 逐员定分单行) / D75F0
逐轮调 C7700 (调用者补边: 书原仅记 C7700 单处); C7700 正文消费槽记录 +28 AtLoc/+52 OnWay。
**退避门 sub_1414C9D10 = D9280 的直接包装调用者** (书调用带补边, dump :7829621 实证):
+696≤0 → 调 D9280, 成功清 +696=0; 失败步长 +700 按 (≥3 ? min(×2,24) : 3) 回写双槽; 冷却中
+696 = min(−1, 24) 递减。

谓词链 (逐单位, 定案):

| # | 函数/字段 | 语义 |
|---|---|---|
| P0 | sub_140C891E0 | unit+952 CDivisionTemplate* 非零 → template+564 旗 (attrition 豁免旗同字段) 真者整段跳过 = 特殊模板单位不参与前线调度 |
| P0b | unit+588/+589 | 撤退 / 脱离 |
| P1 | sub_1414D4CF0 | 已有目的地: unit+748 航点数>0 → 末条航点 +12 省 id ≠0; 否则回落 unit+524 path count > 0 |
| P2 | sub_140BFFF10 | 在活战斗中 (逐 combat unit+424/436, 对侧 +72 ≥1) |
| P5 | sub_1414D8EA0 | 可单独调度: 假 ⟺ unit+8==0 ∧ unit+1584 有 leader ∧ 根 OI type2 ∧ og+428 proximity_type==0 (有将官+前线单+非贴近编组者不在此层单独排程) |

入列判定: `(¬P1 ∨ (P2 ∧ ¬unit+589) ∨ unit+584<1) ∧ (¬P2 ∨ 撤退模式) ∧ P5` →
++indexer+72, 插 indexer+104 候选列 (槽数 indexer+116 非零 → sub_1401B14F0
(i×成员数 + oi+124 路径数) % N 轮转插位摊匀先后); 循环尾 unit+488 目的地省
失效 (省 +368 容器无 vt[11]==1 元素) → sub_140C04C60(unit,0,0,0) 清目的地
(清 unit+687 战略部署旗经 vt[53]、写 unit+488、单省路径 sub_14012B520)。

**双层节流 (定案)**: ① 四拍 = `(og+12 id + 流逝小时) & 3 == 0` (流逝小时 =
sub_1405339D0(gs+1120) = *(gs+1128)−43800000, 与 §4.2.6 相位 11 错峰同式);
og+414 members_has_changed 读清真者**旁路**立即重算。② 72h = indexer+352
倒计时每小时 −1, ≤0 触发前线省对采样后重置 max(HOURS_BETWEEN_ENCIRCLEMENT_
DISCOVERY, 1) = define 72 (00_defines.lua:2697 包围圈发现刷新周期); ctor 以
2×sub_140BB5490(og+60) 种子错峰 (推定)。

**sub_1414CCF10** = "Find best unit" 核心分配巨函 (~2300 行, 算法定案):
**贪心双层** — 外层 **sub_1414C9690 加权择位** (每轮选「槽优先级 int64 × 缺口」
最大的位; 无人认领冷启动 ×10, 超配边际递减; 满位表 indexer+176 / 空派表 +200
双排除), 内层 **sub_1414C87B0 逐员定分** (候选按距离²升序 ≤32 插入 / >32 并行
归并, 逐个整数定分取最优)。评分公式 (定案): 预算 = 1000 ×
PLAN_FRONTUNIT_DISTANCE_FACTOR (10.0); 距离惩罚 = D × min(dist²,1e8)/1e5 ×
**PLAN_COHESION_WEIGHTS[og+424] {1,40,80,100}** (cohesion 3 整员硬排除);
常量奖罚 = 在位 +1e7 / 在途 +2e7 / 他往 −2e7 / ETA 出窗再 −4e7; 段防
FRONT_TERRAIN_DEFENSE_FACTOR (3.75) / 段攻 FRONT_TERRAIN_ATTACK_FACTOR (5.0);
粘滞 PLAN_STICKINESS_FACTOR (100.0) 原位 ×S/100 他位 ×100/S (unit+692 粘滞
键); 距离 = 两省 +176 坐标差平方和 (欧氏直线², 非寻路)。分配输出三写:
sub_1414D6520 从工作列 indexer+80 摘除 / 槽对象 +40 在途表追加 / v122 门
(战斗中 ∨ 已在本省 ∨ sub_1414C9D10 指数退避门, unit+696/+700 封顶 24) 放行时
清 unit+590=0/+592=−1/+680=0, 真指令由 sub_1414CFBB0 下发。metrics 8 列 =
Front Count | Order | Priority | Min.W | Wanted | At Loc | On Way | Leave
("Wanted" exe .rdata 实证), 仅玩家国 og 落盘。新字段: 索引器 +80/+92 工作候选
列 (书 +104 候选列之外第二列) / +176 满位表 / +200 空派表 / +248 排除集 /
+360 metrics 容器; COrderInstance +504/+516 兄弟实例数组 (§4.24.14 早出门
= 实例数 ≤1) / +136 前线位槽表; CUnit +692 粘滞键 / +696/+700 退避计数 /
+312 军段缓存。

叶点入队 = **sub_1414C3A50**: malloc 32B CPendingAddStrategicRedeploy →
sub_1414D4B50 即时校验 (vt[1] IsValid → vt[3]) + 追加 indexer+272 待办容器
(worker 安全延迟命令, §4.00 待命指令族); Execute 走 CUnit 移动校验与拒动协议
(unit+590/+680 写者即此族, §4.18)。

新字段 (全部不序列化): COrderInstance+56 = 所属 og 回指 (定案); CUnit+216 =
缓存根订单实例 (sub_140BEF990 写验, 失效串 "deleted_or_unknown", 定案);
CUnit+224 = 成员订单脏旗 (定案存在); CUnit+488 = 当前移动目的地省指针
(sub_140C04C60 写清, +164 = 省 id, 高置信); og 索引器 (og+72 对象, 408B):
+16 逐军 scratch 计数 / +24 位置槽表 (16B 条, CFBB0 轮转消费) / +36 槽数 /
+72 可调度成员计数 / +104 候选列 (轮转插位) / +116 槽数 / +128 全成员镜像 /
+152 无路径成员列 / +272 CPending 待办列 / +328 包围圈省对表 / +352 72h 倒计时
/ +356 AI 日志旗 (→ logs/ai.log) / +368 当前 child og / +376/+380 子军 section
界值对 (定案)。gs+2408 = 当前处理国 tag 槽 (唯一读点 = 国别门, ≤0 无国语境
全放行, 推定; **探针: 常规单机小时链 ~10 游戏日 0 写点** — 写者不在单机周期
链, 更可能 MP/观察者域槽)。

#### 4.24.15 theatre.daily_serial 与 og 日更

**theatre.daily_serial = sub_140EF1410** (sub_140718850 后逐 CTheatre, 定案):
orders_group (+128) + field_marshal_group (+152) 逐 og **sub_140BEC460 = og
日更** — B→A 快照 (512/528 → 312/328) + 逐实例 faction_theaters 份额刷新 +
旗清理 + hq_deploy 分发 (§4.24.10 域)。division_names.update =
sub_1409C9680 (divisionnamesdatabase.cpp:447 断言): 每国**四个命名库
(cc+112/120/128/136)** × 两步 (步 1 = 可用性降级扫描 [自 tracker+64 恒可用前缀之后
正扫 available_groups, 求值假者 swap-remove 出 _AllAvailableGroups 批量回不可用表,
前缀豁免]; 步 2 = 可用性升级扫描 [不可用表求值真者搬回] — 勘误: 原「回收步」措辞
易误读, 实为双向可用性搬迁) (定案)。按命名库种类分派件 = sub_1409C62C0
(a1+96 ∈ 0..3): mode 2 分支内联单位遍历赋名 + +169 已赋名旗, mode 3 走
sub_1409BCF50 外包铁路炮族。

#### 4.24.16 theatre.cpp 簇对账增补 (前线条三主干与 BuildSections)

**链 A 每帧前线通道** (sub_140EF97A0, tbb): ① 逐国 cc+360 {d} / cc+372 {c} 收集全战区
→ CPdxArray; ② parallel_for → sub_140EED730 (簇外, +408 字典清重建); ③ 串行逐战区
`sub_140EECA10(theatre+80, &key, theatre+408)` 认领旧前线, key = theatre+272
(volunteers_theatre tag) > 0 ?: theatre+72 (owner tag); 逐 +408 条目 (192B) →
**sub_140EEB190**; 清扫 theatre+80: front+44 (enemies count) == 0 → vt[0] 删 +
swap-remove。条目 192B = {己区 CControllerArea* @+0, 敌区 @+8, CFront* @+16, 省累积器
{d @+24, c @+36}}; 三断言 :92/:98/:416, 己区空以敌区 +32 容器首控制区代替。front 空 →
malloc 136 内联构造 (type = 66, id = InterlockedExchangeAdd(dword_143087264, 1),
+24 = theatre, +112 = 区, +124/+125 = 0x0100 即 dirty) 后 **push 进 theatre+80
(序列化 fronts 容器, 定案)**; enemies 重建 = 敌区 controller tag (sub_140CF43B0 优先,
否则区 vt[1] GetTag; 容器 +56, alloc = +72); 尾 front+124 == 0 ∧
sub_140E7E0E0(己区+40 锚省, theatre) 真 → +124 = 1 (:435 门 = 敌区空)。

**BuildSections = sub_140EEE090, 宿主 CFront** (tbb lambda 符号
`CFront::BuildSections(NTheatreManager::EReason, …, bool, const CProvince*)` 直证, char
返回 1 = 成功; §4.24.6 调用主干原按 CTheatre 通道旁注收录, 宿主以符号定案)。双路径:

- **镜像模式** (第 3 参非 0 ∧ sub_140EF4B00 非 0): **sub_140EF4B00 =
  CFront::FindMirroredFront** (定案) — 前提 owner theatre+272 > 0 → 解析借驻国 → 取其
  cc+360 第一战区 (+272 > 0 则放弃) → 遍历其 fronts 三条件找镜像: 省数相等 (∧+44) ∧
  sub_140CF6650(本 +112, 候选 +112, key) 区对区匹配 ∧ 候选省集与本前线省集完全不相交
  (栈上省 id 位图)。命中 → 本前线 sections 全移暂存 → 逐镜像 section 复用/新建
  (ctor sub_140EE9E00) + 省表 (sub_140BD1CD0) 与 sorted_pairs (sub_140B95D60) 拷贝 →
  push +88。语义 = **志愿军借驻前线段划分 1:1 镜像借出国对同一敌方的段划分** (高置信)。
- **自算模式**: 512 轮上限逐省循环 — 前线省表 (+32/+44) pop-swap 尾取 →
  sub_140EF64D0 找对位敌省 → sub_140EF3B70 算敌区键 (0 → 断言 :3200 "Failed to build a
  front against enemy that doesn't have a front against us!") → sub_140EF50C0 产该区
  wanted 省对表 (空跳过) → 省对排序 (>32 归并 sub_140EE7C00 / ≤32 插入 sub_140EE7AD0)
  → 逐对 **FloodPath sub_140EF5AE0** 洪泛 (真返回 = 构建中止 break; 各对取最长) → 覆盖
  < wanted 断言 :3276 "Building front section failed" → section 复用 (sub_140EF81C0
  匹配, 标记字节数组防本轮重用) 或新建 → **TakeProvincesAndPairs sub_140F00F50**
  (reversed = 段首末省路径先后, sub_140EF44D0 后处理 ×2) → 覆盖对账 :3419
  "nWantedPairs == nCoveredPairs", 超 wanted 省打回工作列重处理 → 清扫未触及/空段
  (+60 省数 == 0 ∨ +84 对数 == 0) vt[0] 删 + swap-remove。

**载入修复对全流程**: sub_140EFC6D0 = CTheatre::UpdateMainProvince 五步 (debug 门
byte_143452529, log :2557): ① +36 area 计数清 0, +60 锚省数 > +32 cap → 1.5 倍增 +24;
② 逐 +48 锚省 id → 省+208 区非零 → sub_140EEB9D0 (theatre+24 area 表线性查重后去重追加,
新定性); ③ +48 计数 = 0, +224 = 0 → SetMainProvince sub_140F018F0(theatre, 1) (新锚串
"New main province for theater %s…" :1302); ④ 逐 +80 前线 → sub_140EFC390 (分支见
§4.24.6 +120 注), 返后 +112 仍 0 → swap-remove 删; ⑤ 逐 +128/+152 og → sub_140BF28E0
(og post-load — 逐 OI 三容器 og+152/+164, og+176/+188, og+200/+212 调 sub_14103BCA0
敌区缓存 resolve, 与 §4.24.5 +168 载入链闭合)。

**读档修复入口 sub_140EF9280 四步** (§4.24.6 主干补内幕): ① 重置两占领 bundle 静态 +
byte_14333D398 = 1; ② managerobj+1854 (经 qword_14332F698 vt[+136]) 为 0 才跑重校验
五件套 (byte_14333D2B0 = 1 → sub_140EFAC10(0,1) → sub_140EF9F40 → sub_140EF88B0(0,0) →
sub_140F000E0 → sub_140EED100 → 旗清 0), 差异旗 byte_14333D2B1 置位 → log "Theaters or
fronts has been fixed…" :4833 后**继续执行 (非 fatal)**; ③ 逐国逐战区逐 og (theatre+176
/+188 双挂镜像容器) 逐根 OI → sub_14104B470: oi+48 == 1 (ORDER_MOVE) →
sub_14104B3A0(oi, 1); 递归 oi+504/+516; ④ 尾 DispatchBundle sub_140EF18B0 → 队列清零。

**RevalidateTheatres = sub_140EEC180 返回契约** (char): 1 = 一致 / 0 = 差异 (差异时 log
"Revalidating theatres indicates differences…" :5634)。调用点恰两处 = massconquer 帧测
试器 sub_140DE1040 + 控制台探针 sub_14023E860 (返 1 → "No errors found." / 0 → "Errors
found.", 手工触发) — 主文件 §4.24 对应待裁条由此闭合。

**DispatchBundle sub_140EF18B0** (§4.28 通道实名 tbb 符号直证): 队列条目 16B {og idpair,
instance_id, u8 @+12}; 逐条目 idpair 校验 → COrdersGroup* → sub_140BEAA30 找 OI → 消费
门 = 条目+12 真 ∨ oi+592 (withdraw_lines 源对象) == 0; 分派 <4 串行逐 og
sub_14102B8E0(og, 1, 0) / ≥4 主线程播种 + tbb parallel_for (grain = max(1, n /
(3 × 硬件线程))); debug 门 (byte_143452529) log "Front bundle: %i (%s), ai: %i (%s)"
:5729 — 本函数即 sub_14102B8E0 的驱动入口之一 (§4.24.5 +592 行闭环)。

**g_OccupationBundle 静态内布局** (基址 0x14333D2C0 / 0x14333D330, 各 1803B; 基址与
_IsActive@+96 书已收): +12 / +36 / +60 = 三个 dword 计数槽 (收口清零); +72 = 动态数组
data / +84 = count (收口按 count memset)。bundle+100 (活动模式) / +101 (rebuild scope
锁) 协议: EF1EE0 冲洗入口 — +101 已置 → FATAL "Theatre rebuild scope is locked!"
(:5532/:5533) → terminate; 否则 +101 = 1 → +100 真 ∧ +12 非零 → sub_140EFAB20(0,1) →
sub_140EF97A0 (链 A) → sub_140EF88B0 (分桶重建) → sub_140F00040; 否则 +36 ∧ +12 →
sub_140EF2180; 尾 +101 = 0 解锁 + 战区脏旗 (managerobj+1941, 经 qword_14332F698
vt[+136] 槽 17 取对象) = (gs+1312 > 0)。

未决: 重校验五件套中 sub_140EF9F40 / sub_140F000E0 / sub_140EED100 分工 (簇外无特征串);
sub_140EF44D0 (section 后处理) 精确语义; sub_140CF43B0 返回对象 +8/+20 字段; 路径一步的
sub_140EF64D0 / sub_140EF3B70 内部 (对位敌省查找与敌区键计算, 建议独立小批); 同 tsv 相邻
单元 airtheatre.cpp 3 函数已定性 = 空军剧场族运行期所有权操作层, 非 theatre 族成员
(§4.31.61 增补段)。

#### 4.24.17 areas.cpp 双类运行期增补 (CControllerArea/COwnerArea 维护与面级寻路; 8 函闭环)

清册 (8/8 函体内含 areas.cpp 路径锚): 控制器变更区域维护 0x140CF6FA0 (603) / **区域邻接图
Dijkstra 面级寻路 0x140CF3B20 (490)** / CControllerArea::TrySplit 0x140CF87C0 (386, vt[6]) /
COwnerArea 邻接链重建 0x140CF1ED0 (115, vt[2], 零直接调用点) / RemoveProvince 0x140CF84C0
(92, 两类共用 vt[5]) / 区省表排序 0x140CF8640 (81, 调用者 = 国家级批量 sub_140713040(+1352)/
sub_140713090(+1376)) / AddProvince 0x140CF1170 (78, 共用 vt[4]) / Merge 0x140CF67D0 (69)。

**虚表全 16 槽 VA 补齐** (PE 直证): CControllerArea vt 0x14295E818 7 槽 [4]Add/[5]Remove/
[6]TrySplit vs COwnerArea vt 0x14295E858 9 槽 ([2] = 邻接链重建 0x140CF1ED0 / [6] = owner
分裂 0x140CF8F20 / [4][5] 共用实现)。

**控制器变更维护链** (定案): 旧区摘省 (vt[5]+vt[6] TrySplit, 空区销毁含国注册摘除/链清理/
delete) → 新控制器侧邻区同别名组 Join/新建 → AddProvince (锚省选择 = desc+210 bit0 陆省位,
按省 id 二分有序插入, 幂等门) → 邻接链双向加 refcount; 唯一调用点 = SetController 级联
(province.cpp:394 后)。**TrySplit** = 回指清零 → 首省洪泛保连 (owner tag 同别名组键, DFS 栈 =
pdx scoped buffer 容量 gs+700) → 断离分量逐个成新区 + front 引用迁移 (sub_140CF7E10) + 国注册。

**Dijkstra 面级寻路** (定案): 图边 = 区+144 观察链, 代价函子注入 (<0 不可通行, 目标区零代价),
堆键 {代价, 锚省 id}, 双 TLS 工作池, visited 键 = 锚省 NonSeaIndex (**CMap+568 重映射表消费**,
-1 = 海省; 池容量源 = gs+1720, 业务名待裁), 输出逆序路径链表或纯可达性 (11 调用点, 已归属 1 =
sub_140663A20 国对可达性查询)。

> 方法论注: sub_140BB52F0 IDA 单参显示 = 调用点参数截断伪影 (实 2 参, gs+832 别名表互证) —
> 与 §4.19.9 失真清单并读, 实参级结论需汇编复核。

未决: 区主重算 sub_140CF21D0 (632 行非本簇) 逐字段 / 0x140CF1ED0 运行期调用者 / gs+1720
量纲 / front 侧广播落点 sub_140EFB9A0/BED0 与两虚表余下 7 槽语义。
