

### 4.24 战区族 (CTheatre / CFront / CFrontSection / CTheaterGroup / hq_deploy)

#### 4.24.1 类身份与 RTTI 谱系

writer 绑定总表:

| 类 | sizeof | vtable | writer (slot2) | ctor | reader (slot4) |
|---|---|---|---|---|---|
| CTheatre | 0x1D0=464 | 0x142975A48 | 0X140F025C0 | 0X140EE9E50 | 0X140EFE2B0 |
| CTheaterGroup | 0x60=96 | 0x1429E5C50 | 0X14163AA40 | 0X141639B00 | — |
| CArmyGroup | 0x250=592 | 0x142952348 | 0X140BF75A0 | 0X140BE9BC0 | — |
| COrdersGroup | 0x230=560 | 0x1429522B0 | 0X140BF7630 | 0X140BE9C10 | — |
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

**全字段表** (发射序 = 表序; id 对锚 {id=1, type=67}):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | id 对.type (B400 壳) | 恒写 |
| +12 | uint32 | id 对.id | 恒写 |
| +24 | 匿名结构 (元素待裁) 向量 | area 数组数据 — 元素指针, 值 = ru32(rp(rp(elem)+40)+164) 两跳 (state/area id); 块呈单行叶 `area.#1` (tok 11157/0x2B95; GER 锚 `area={ 266 563 }`) | 门 计数@+36>0 (cap@+32 推定); 逐值 ADAB0 |
| +36 | uint32 | area 容器计数 | |
| +80 | CFront* 容器数据 | front — 逐元 ADEC0 整块 | 门 计数@+92>0; tok 10720/0x29E0 |
| +92 | uint32 | front 容器计数 | |
| +104 | 匿名结构 (元素待裁) 向量 | unit 数组数据 — 逐元 B320(10403, elem+24) 单行叶 (ref 对在 elem+24) | 门 计数@+116>0; tok 10403/0x28A3 |
| +116 | uint32 | unit 容器计数 | |
| +128 | COrdersGroup* 容器数据 | orders_group — 逐元 ADEC0 | 门 计数@+140>0; tok 12462/0x30AE |
| +140 | uint32 | orders_group 容器计数 | |
| +152 | CArmyGroup* 容器数据 | field_marshal_group — 逐元 ADEC0 | 门 计数@+164>0; tok 14337/0x3801 |
| +164 | uint32 | field_marshal_group 容器计数 | |
| +200 | CTheaterGroup* 容器数据 | theater_group — 逐元 ADEC0 | 门 计数@+212>0; tok 13777/0x35D1 |
| +212 | uint32 | theater_group 容器计数 | |
| +272 | tag_id | volunteers_theatre 借驻国 — sub_140BB4E70 引号 tag 串 | 门 >0 才写; tok 13421/0x346D |

**writer 不落盘区表** (全部不序列化):

| 偏移 | 形态 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +48 | 匿名结构 (元素待裁) 向量 | area 读侧加载容器 — reader case 11157 直入, 与 +24 发射容器分离 | 不序列化 |
| +72 | — | owner country tag (ctor 第二参; CArmyGroup ctor 以 (theatre+72, theatre) 构造互证) | 不序列化 |
| +144 | 侵入式链表 | {对象@节点+0, next@节点+16}; 元素虚槽[1] → dword 指针 (推定 = 邻国 tag) | 不序列化; 推定 |
| +176 | 匿名结构 (元素待裁) 向量 | 双挂镜像容器 — reader 12462/14337 双 push, 纯运行时索引 | 不序列化 |
| +240..+271 | 内嵌 CColor | 默认白 | 不序列化 |
| +280..+407 | 匿名结构 (128B 形状) | **互斥量保护的待处理条目队列** (ctor sub_140EEA130 / dtor sub_140E9E3D0: +16/+40 = 静态空分配器哨兵; +24 容器 {d@24, cap@32, c@36, alloc@40} 元素 stride 40; +48 = std::mutex (dtor 经 sub_14251DC00 加锁, 尾 Mtx_unlock(+48)); +120 = −1 哨兵; +124 = mutex 递归计数 (== 0x7FFFFFFF → _Throw_Cpp_error(6)); 条目 40B: +16 = 裸指针数组 d, +28 = count, 数组元素逐个 j_free) | 不序列化; 载荷类型待裁 |
| +408 | 匿名结构 (192B 元素) 向量 | **192B 元素数组** {d@408, c@416, cap@420, alloc@424} (dtor sub_140F00370 逐 192B 元素释放; 元素内嵌 pdx 容器 {d@+24, c@+32, alloc@+40}); writer 0x140F025C0 零触 = 不序列化; 业务语义待裁 (writer/reader 双向零触, 访问者未定位) | 不序列化 |
| +432 | std::map (RB 树) | **RB 树容器** (dtor 经 sub_1401A4F70 RB 树析构 + alloc@448 释放 + count@440 清 0; ctor 空态); **键/语义未决** | 不序列化 |

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
| +200 | 匿名结构 (元素待裁) 向量 | virtual_fallback 数组数据 — 同 fallback 形态 | 门 计数@+212>0; tok 13811/0x35F3 |
| +212 | uint32 | virtual_fallback 容器计数 | |
| +256 | CColor 内嵌 | color (基@+256, 分量@+272..+284) | !readonly 才整块写 (ADEC0; tok 86/0x56); 子表见 §4.00.10 |
| +288 | uint32 | icon | 恒写 (锚 1); tok 181/0xB5 |
| +292 | uint32 | split_from.type | 门 qword@+292 ≠ 哨兵 qword_14333D528; B320; tok 13156/0x3364 |
| +296 | uint32 | split_from.id | 同上 |
| +304 | fixed×1e-5 (i64) | plan_value (ctor 初值 100000=1.0; 锚 0.7→70000) | 恒写; tok 13628/0x353C |
| +312 | fixed×1e-5 (i64) | our_power (锚 1937.35→193735000) | 恒写; tok 13629/0x353D |
| +320 | fixed×1e-5 (i64) | enemy_power | 恒写; tok 13630/0x353E |
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
| +112 | 匿名结构 (元素待裁) 向量 | attached wings, 元素 = 翼指针 (ordersgroup.cpp:0xD4C sub_140BEB3C0 断言 `GetAttachWingStatus(pAirWing)`) | 不序列化 |
| +224 | 匿名结构 (元素待裁) 向量 | writer 零触, 语义未决 (无 og 专属访问器) | 不序列化 |
| +328 | 匿名结构 (元素待裁) 向量 | writer 零触, 语义未决 (无 og 专属访问器) | 不序列化 |
| +384 | 匿名结构 (NNB 形状)* | _pTheaterGroup 回指 (GUI 锚, assert 直证) | 不序列化 |
| +415 | uint8 | **plan_value 重算脏旗** — 30+ 处 og mutator 置 1; 唯一消费者 COrdersGroup vt[10] sub_140BF1660 体 `if(og+415){ og+415=0; og+304 = sub_140BEC940(og, &v, og+312, og+320, og+328, 0); }` ⇒ 重算 plan_value (+304) 及伴随 +312/+320/+328 | 不序列化 |
| +432 | CBorderWar* | **当前边境冲突 (border war) 对象** (单指针非容器; ctor 0X140BE9C10 清零; GUI 三消费: CArmyItem 边境冲突图标 `orders_group_item_border_conflict` 非零门 / CanChangeLeader sub_140BEBAA0 → CANNOT_CHANGE_LEADER_WAR / 进度百分比 sub_140BDC260 读 obj+40/+48 子对象选边 +1232 阈值) | 不序列化 |
| +440 | CArmyGroup* | **备用/前任 leader 载体** (sub_140BF3C20 先读 og+440 取 +136 调 sub_140C20F70, 再读 og+136 现 leader 同调, 尾遍历 CArmyGroup+560 子群 — 三档同族将领/力量传播) | 不序列化 |
| +472 | COrderInstance* 向量 | **leader 根 order 实例 path 数组缓存镜像** — vt[10] 与 leader 根 OI+112 (COrderInstance.path) 逐元素 memcmp, 不等则 sub_1401A8550 重容 + memcpy; count@+484 / cap@+488 | 不序列化 |
| +496 | idpair (缓存 key) | **缓存 key 对 type@+496 / id@+500** — 与 +472 缓存体成对: vt[10] 以 sub_1410361A0(leader 根 OI, &v, og) 产出对比较, 不等才重拷 +472; 不适用时写 qword −1 (两 dword 全 0xFFFFFFFF) | 不序列化 |
| +528 | 匿名结构 (24B 形状) | writer 零触, 语义未决 (无 og 专属访问器) | 不序列化 |
| +552..+559 | — | 尾 8B 不初始化 | 不序列化 |

注: A3D0 = 0X14221F310 ref 对有效性校验原语; 段以「双 dword 非零」近似。
注: 铁路炮挂载条目上下文 = COrdersGroup 基视口 (非 CArmy=师; CArmyGroup 派生同布局; RTTI 链 + ctor 0X140BE9C10 + unitcontroller.cpp 断言 `!_pOrdersGroup->GetAssignedRailwayGuns.IsEmpty` 直名) — 定案。
注: attached wings 过滤链 = 槽掩码 LUT qword_1430B3FC8[item+1352] ∧ 翼+56(_pPool) → pool+32(def) → def+1448 = _Category 镜像#2 三环对书全平 (§4.23 +1032 行互证)。
注: +392 以外其余 qword 杂项 writer 零触, 语义未决。
注: 每帧 `sub_1414D40E0` **不是** og+72 对象的虚槽 — 它由 COrdersGroup vt[10] = `sub_140BF1660` 经 `sub_140BEA830(og+72)` 取对象后调用; og+72 对象自身无虚表 (ctor 零 vftable 写)。

#### 4.24.4 CArmyGroup (592B, writer 0X140BF75A0)

vt 0x142952348 直继 COrdersGroup; 自有键写在基类全键**之前**; 偏移 +0..+559 与 COrdersGroup 同布局:

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +560 | 匿名结构 (元素待裁) 向量 | orders_group 数组数据 — 子集团引用; 元素为包装对象, ref 对在 elem+8 {type@+8, id@+12}; 逐元 B320(12462, elem+8) 单行叶 | 门 计数@+572>0; tok 12462/0x30AE |
| +561..+571 | — | = orders_group 容器 data 尾 (+561..+567) + **cap u32@+568** (容器 {d@560, cap@568, c@572, alloc@576}; ctor 0X140BE9BC0) |  |
| +572 | uint32 | orders_group 容器计数 | |
| +573..+583 | — | = count 尾 (+573..+575) + **alloc@+576 = &off_143085170 静态空分配器哨兵** + 垫 (+580..+583)  |  |
| +584 | uint8 | collapse | 真才写 yes; tok 14894/0x3A2E |
| +585..+591 | — | **尾垫** (ctor 末写止于 +584; sizeof 0x250 由剧院 reader 与多处 malloc(0x250) 直证闭合) | |

注: 随后**尾调基类 writer 0X140BF7630(a1, a2)** → COrdersGroup 全部键照发 (ctor 另将 +57 预置 1, 故 CArmyGroup 的 field_marshal_group bool 恒 yes) — 派生尾调基形态。
注 (GUI): Badge 名字聚合 tooltip — +560 容器逐元 +80 = 含军名清单 (军→单名 +80); 0X14169D860 → UNASSIGN_ARMY(_GROUP)。

#### 4.24.5 COrderInstance (968B, writer 0X14104B570)

**全字段表** (sizeof 0x3C8=968 reader malloc 定案; 发射序 = 表序, 与 GER 存档键序逐行对齐):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | CConvoySubscriber 内嵌视口 | convoys 块 (tok 12386/0x3062) | **type==3 (海军入侵) 才整块写**, 先于 type 键; ADEC0(0x3062, oi+8); 块说明见下 |
| +48 | uint32 | type 订单类型枚举 | 恒写 (锚 5/2); tok 225/0xE1 |
| +64 | 内嵌 CGameDate (24B {vt@+64, hours@+72, vt@+80}) | creation_date | 门 hours u32@+72≠0; ADEC0 转发 +16 视口 (oi+80); 引号 "Y.M.D.H" (锚 "1936.1.1.14"); tok 14339/0x3803 |
| +88 | 内嵌 CGameDate ({vt@+88, hours@+96, vt@+104}) | starting_date | 门 hours@+96≠0 (锚 "1.1.1.1" 合法非哨兵语境); tok 16018/0x3E92 |
| +112 | 匿名结构 (元素待裁) 向量 | path 数组数据 — 省份 id 序列; 0X140CA0FB0 单行叶 | 门 计数@+124>0; tok 372 |
| +124 | uint32 | path 容器计数 | |
| +136 | 匿名结构 (16B 形状) 向量 | sorted_pairs 数组数据 — 16B 元 {ptr, ptr}, 值 = ru32(ptr+164) 平铺 (路径图边省对; 锚 32 对); AF2C0+AF520 单行叶 | 门 计数@+148≠0 (from/to 同门); tok 13121/0x3341 |
| +148 | uint32 | sorted_pairs 容器计数 | |
| +160 | uint32 | sorted_pairs_from | 同 sorted_pairs 门; ADFE0 (锚 0); tok 14680/0x3958 |
| +164 | uint32 | sorted_pairs_to (锚 32) | 同上; tok 14681/0x3959 |
| +168 | 匿名结构 (NNB 形状)* | enemy_controller_area 链 — ca = *(oi+168), 值 = ru32(rp(rp(ca+40)+164)) 两跳 (锚 445); 断言串 orderinstance.cpp | 门 = 指针非零 且 计数@ca+60>0 且 (ru8(rp(rp(ca+40)+184)+210)&1)==1 (陆省旗); tok 13717/0x3595 |
| +184 | uint32 | invasion_source | 门 ≠0; tok 12662/0x3176 |
| +216 | fixed×1e-5 (i64) | time | 门 i64≠0; tok 424/0x1A8 |
| +224 | 匿名结构 (元素待裁) 向量 | **states** — 省份 id 序列 (与 +112 path 同形态同发射器) | 门 计数@+236>0; tok 11835/0x2E3B |
| +248 | uint32 | area_defense_settings 枚举 (锚 68) | 门 ≠0; tok 14073/0x36F9 |
| +256 | 匿名结构 (32B 形状) 向量 | area_defense_state_assignment 数组数据 — stride 32 元 {state_id u32@+0, 内层数据指针@+8, 内层计数 u32@+20}; 行 = state_id + 内层 8B 对 {type, id} 逐对平铺 (重复不编号; 锚 `{55}` / `{56 51 22}`); 每元独立一行 | 门 计数@+268>0; tok 14373/0x3825 |
| +268 | uint32 | area_defense_state_assignment 容器计数 | |
| +280 | uint8 | blitz — 真时附加 blitz_provinces (下方 +800) | 门 u8 真 → AE850; tok 14028/0x36CC |
| +281 | uint8 | withdraw — 真时附加 withdraw_lines (下方 +856) | 门 u8 真; tok 14572/0x38EC |
| +288 | SSO 串 | operation {buf@+288, size 区@+304} (锚 "o_fall_rot") | 门 qword@+304≠0 (**无 readonly 门**); tok 12059/0x2F1B |
| +320 | SSO 串 | first | 门 qword@+336≠0; tok 10462/0x28DE |
| +352 | SSO 串 | second | 门 qword@+368≠0; tok 10463/0x28DF |
| +384 | SSO 串 | unique | **双门**: !AAFD0 且 qword@+400≠0; tok 12538/0x30FA |
| +416 | SSO 串 | prefix | 门 qword@+432≠0; tok 12536/0x30F8 |
| +448 | SSO 串 | postfix | 门 qword@+464≠0; tok 19049/0x4A69 |
| +504 | 匿名结构 (元素待裁) 向量 | order_children 数组数据 — 值 = 子实例 instance_id ru32(elem+580); 逐元一行 AE0C0 | 门 计数@+516>0; tok 12467/0x30B3 |
| +516 | uint32 | order_children 容器计数 | |
| +528 | 匿名结构 (元素待裁) 向量 | scheduled_member 数组数据 — 元素 unit+184 视口同 member; 逐元 vt[32] 门 → B320(12465, ret+24) 单行叶; 断言 "Invalid scheduled member" | 门 计数@+540>0; tok 12465 |
| +540 | uint32 | scheduled_member 容器计数 | |
| +552 | 匿名结构 (元素待裁) 向量 | transported_member 数组数据 — 同上形态; 断言串 | 门 计数@+564>0; tok 13138 |
| +564 | uint32 | transported_member 容器计数 | |
| +576 | uint32 | all_transported_members | 门 ≠0; tok 16016/0x3E90 |
| +580 | uint32 | instance_id — 家族树父引用目标键 (锚 7) | 恒写 (AE0C0 无门); tok 12463 |
| +584 | uint8 | can_execute (值域 {0,1}) | 真才写 ADFE0(char); tok 12466/0x30B2 |
| +592 | 匿名结构 (NNB 形状)* | **withdraw_lines 源对象** — malloc 0x40 {pdx 容器@+0 (d@0, c@8, alloc@16), pdx 容器@+24 (d@24, c@32, alloc@40), qword@+48, qword@+56}; 分配点 sub_14102B8E0 (门 +281 withdraw 旗 且 +584 can_execute); 消费 sub_1410478B0 (链重建) / sub_141036410 (逐元索引) | 不序列化; 高置信 |
| +600 | uint32 | root_front.type — B320(13118, oi+600) (锚 {id=5 type=66}) | 门 qword@+600 ≠ 哨兵 qword_14333D528; **root_section/from/to/split_from 均在此门内** |
| +604 | uint32 | root_front.id | 同上 |
| +608 | uint32 | root_section | 门 ≠0 (随 root_front 门); tok 13119/0x333F |
| +616 | fixed×1e-5 (i64) | from | 门 i64@+616≠0 ∨ +624≠100000 → 双写; tok 10639/0x298F |
| +624 | fixed×1e-5 (i64) | to (⚠ 键 token 0x2990, 非 token "to") | 同门; tok 10640/0x2990 |
| +632 | uint32 | split_from (与 og+292 同 token 异物) | 门 ≠0 (随 root_front 门); tok 13156/0x3364 |
| +640 | 匿名结构 (元素待裁) 向量 | midpoints 数组数据; 单行叶 | 门 计数@+652≠0; tok 13222/0x33A6 |
| +652 | uint32 | midpoints 容器计数 | |
| +664 | uint8 | fallback bool (⚠ 与 og 容器键同 token 异物) | 真才写 yes; tok 13272/0x33D8 |
| +665 | uint8 | virtual_order bool | 真才写 yes; tok 13812/0x35F4 |
| +668 | uint32 | virtual_creator | 门 ≠0; tok 13813/0x35F5 |
| +672 | 匿名结构 (元素待裁) 向量 | virtually_created 数组数据 — 经 sub_141026000 转发; 单行叶 | 门 计数@+684≠0; tok 13814 |
| +684 | uint32 | virtually_created 容器计数 | |
| +800 | 匿名结构 (元素待裁) 向量 | blitz_provinces 数组数据; 单行叶 | 门 = blitz u8 真; tok 14036 |
| +848 | uint32 | **withdraw_lines 当前游标/索引** (24B stride 数组下标) | 不序列化 |
| +856 | 匿名结构 (24B 形状) 向量 | withdraw_lines 外层数组数据 — stride 24, 每元内嵌 u32 数组 {data@+0, 计数@+12} → 每元一个子行 (AF2C0+AF4B0 双层块) | 门 = withdraw u8 真 且 计数@+868≠0; tok 14770/0x39B2 |
| +868 | uint32 | withdraw_lines 容器计数 | |
| +880 | uint8 | manage_child_sections | **恒写无门** (yes/no 必现); tok 15783/0x3DA7 |
| +888 | 匿名结构 (NNB 形状)* | attach 载体 — 附加子集团; ref 对在 p+8; 非零才写 B320(338, p+8) | 门 指针≠0; tok 338/0x152 |
| +896 | COrderInstance::SChildFrontData** 向量 | child_front_ratios 数组数据 — 元素 = **`COrderInstance::SChildFrontData`** (RTTI 直读 `.?AUSChildFrontData@COrderInstance`; sizeof 72, vt 0x1429866C8, writer 0x14104C450 / reader 0x14103F4E0); 写点 sub_1424C24F0 = `arg2->vt[1](arg2, arg1)` (slot[1] = 0x1424BEC50 = CPersistent 家族共享 Save wrapper); 元素内 +8 = group / +16 ratio / +24 size / +32..+44 四 section 界值 | 门 计数@+908≠0 且 >0; tok 15776/0x3DA0 |
| +908 | uint32 | child_front_ratios 容器计数 | |
| +920 | uint32 | floating_harbor.type — 块 = 0X142220180(+920) + floating_harbor_hp | 门 (type\|id) ≠0; tok 19713/0x4D01; 仅 type=3 两栖入侵实例实证 (ENG id=6284 hp=100) |
| +924 | uint32 | floating_harbor.id | 同上 |
| +928 | fixed×1e-5 (i64) | floating_harbor_hp | ≠0 才写; tok 19714/0x4D02 |
| +936 | 匿名结构 (元素待裁) 向量 | faction_theaters 数组数据 — 定点值数组; 逐元 AE9A0 单行叶 | 门 计数@+948≠0 且 >0; tok 19766/0x4D36 |
| +948 | uint32 | faction_theaters 容器计数 | |

注: 运行时容器 order_virtual_children {d@oi+720, c@oi+732} — 树展开消费 (writer 不发射独立键), 见 §4.24.9。
注: oi+592 / +848 成对 — withdraw_lines (+856 外层 24B stride 数组) 由 +592 源对象拷贝生成, +848 为遍历游标 (sub_141036410 返回 `+856 + 24*+848`); 生成门 = +281 withdraw 旗 且 +584 can_execute。
注 (convoys 块): CConvoySubscriber 内嵌@oi+8, 对象 vt 0x14295c0f0, writer 0X141022CB0; writer 首行 `if (*(oi+48)==3) ADEC0(12386, oi+8)` — convoys 块先于 type 键; `convoys = u32@(oi+16)` / `total = u32@(oi+20)` (⚠ 合同族语境下块仅在 total≠0 时写, 见 §4.23.2)。

#### 4.24.6 CFront (136B, writer 0X140F01A60)

reader 0X140EFCF10; front 块全字段落盘。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | u32 | id 对.type — B400 壳 → `id={ id=N type=66 }` | 恒写 |
| +12 | u32 | id 对.id — B400 壳 | 恒写 |
| +13..+31 | — | = id 尾 (+13..+15) + **u8@16 = CReferenceObject 基类 IsStored 旗** (ctor 置 0, 注册成功由 vt[9] 置 1) + 垫 + **owner CTheatre*@+24** (新建时回指所属战区)  | CFront ctor = CTheatre reader case 10720 内联块 |
| +32 | 匿名结构 (NNB 形状) | provinces 容器数据指针 — ptr 数组, 值 = ru32(elem+164) (一跳) | c>0 |
| +33..+43 | — | = provinces 容器 data 尾 + cap@+40  |  |
| +44 | u32 | provinces 容器计数 | c>0 |
| +45..+55 | — | = count 尾 + alloc@+48 (哨兵) + 垫  |  |
| +56 | tag_id | enemies 容器数据指针 — u32 tag_id 数组 (4B 元素) → 引号 tag 串, 每元独立行 | c>0 |
| +57..+67 | — | = enemies 容器 data 尾 + cap@+64  |  |
| +68 | u32 | enemies 容器计数 | c>0 |
| +69..+79 | — | = count 尾 + alloc@+72 (哨兵) + 垫  |  |
| +80 | uint32 | id_counter | 恒写 |
| +88 | CFrontSection* | section 容器数据指针 — ptr 数组 → CFrontSection | c>0 |
| +89..+99 | — | = section 容器 data 尾 + cap@+96  |  |
| +100 | u32 | section 容器计数 | c>0 |
| +101..+111 | — | = count 尾 + alloc@+104 (哨兵) + 垫  |  |
| +112 | uint32 | area 标量 = ru32(rp(rp(fr+112)+40)+164) | 恒写 |
| +113..+124 | — | = area 指针尾 (+113..+119) + u32@120 置零 (语义未决) + u8@124=0 | case 10720 word 写 0x0100 高半=1 |
| +125 | uint8 | dirty — ctor 初值 = 1 (新建 front 默认脏; reader 13444 skip) | 恒写 → yes/no |

**reader 补键表** (writer 无对应键):

| reader 键 | 语义 |
|---|---|
| 11157 / 13120 / 13444 | 三键读后即弃 |
| 10983 | enemies 单串形读侧键 — 与 13544 数组形同目标 front+56; 断言 "Front refers to invalid country tag" 同串 |

注: +16 u8 = **CReferenceObject 基类 IsStored 旗** (定案, 非本族语义字段); +120 u32 / +128 qword 两槽 ctor 置 0、dtor 不触、writer 不触 ⇒ 纯运行时缓存候选, **写入者未定位 (未决)**。

#### 4.24.7 CFrontSection (96B, writer 0X140F01FD0)

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | id (**裸整数非 id 对**) | 恒写 |
| +9..+23 | — | = id 尾 + 垫 + **owner CFront*@+16** (ctor 第二参直存; 与 CFront+24 对称)  | ctor 0X140EE9E00 |
| +24 | 匿名结构 (24B) | per_country_section 容器数据指针 — 24B 内嵌元素数组 (非指针): country tag_id@+8 → 引号串 / index u32@+12 / count u32@+16 (均恒写; 元素 writer 0X140F029F0) | c>0 |
| +25..+35 | — | = per_country 容器 data 尾 + cap@+32  |  |
| +36 | u32 | per_country_section 容器计数 | c>0 |
| +37..+47 | — | = count 尾 + alloc@+40 (哨兵) + 垫  |  |
| +48 | 匿名结构 (NNB 形状) | provinces 容器数据指针 — ptr 数组, 值 = ru32(elem+164) | c>0 |
| +49..+59 | — | = provinces 容器 data 尾 + cap@+56  |  |
| +60 | u32 | provinces 容器计数 | c>0 |
| +61..+71 | — | = count 尾 + alloc@+64 (哨兵) + 垫  |  |
| +72 | 匿名结构 (16B 指针对) | sorted_pairs 容器数据指针 — 16B 指针对数组, 每对两 ptr, 值 = ru32(ptr+164) 平铺 | c>0 |
| +73..+83 | — | = sorted_pairs 容器 data 尾 + cap@+80 (sizeof 0x60 malloc 直证) |  |
| +84 | u32 | sorted_pairs 容器计数 | c>0 |

#### 4.24.8 CTheaterGroup (96B, writer 0X14163AA40)

ctor 0X141639B00; vt 0x1429E5C50。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | u32 | id 对.type — B400 壳 → `id={ id=44 type=68 }` (ref 槽 = qword_14333D528 哨兵) | 恒写 |
| +12 | u32 | id 对.id — B400 壳 | 恒写 |
| +13..+31 | — | = id 尾 (+13..+15) + **u8@16 = CReferenceObject 基类 IsStored 旗** (ctor 置 0, 注册成功由 vt[9] 置 1) + 垫 + **owner CTheatre*@+24** (ctor 第二参)  | ctor 0X141639B00 |
| +32 | uint32 | priority | 恒写; GUI: 剧场组行重编号 |
| +40 | SSO | name (24B {buf@+40, size@+56, cap@+64}) | **恒写 (!readonly, 无空串守卫)**; GUI: 改名命令 |
| +41..+71 | — | = name SSO 32B 内部 (buf 尾 + size@+56 + cap@+64=15; 标准 MSVC 空态)  |  |
| +72 | COrdersGroup* | orders_group 容器数据指针 — ptr 数组, B320 视角 elem+8: `id=ru32(e+12) type=ru32(e+8)` 单行叶 | c>0; GUI: 剧场组行命中 |
| +73..+83 | — | = orders_group 容器 data 尾 + cap@+80 (sizeof 0x60 闭合) |  |
| +84 | u32 | orders_group 容器计数 | c>0 |

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
| +9..+31 | — | = priority 尾 (+9..+15) + **qword@+16 (属 CEquipmentDistributable 基类域)** — 基 ctor 0X1415A7410 只做三事 (`*(a1+8)=1` priority 默认 / `*a1 = &CEquipmentDistributable::vftable` / `*(a1+16)=0`); 该 vt 0x1429DC100 全槽无 +16 消费 ⇒ 语义未决 + **vt2@+24 = CPersistent 视口**  | 基 ctor 0X1415A7410 |
| +32 | uint32 | country tag_id → 引号串 | 恒写 |
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
| vtable RVA | 0X1429D0F38 (RTTI 仅继 CPersistent) |
| writer (vt slot2) | 0X141518C70 — 逐元 ADEC0 token 13777 theater_group |
| loader (vt slot4) | 0X1415189D0 — 收 13777 建 CNavyTheaterGroup |
| 挂载点 | CCountry writer 0X1407191B0 以 token 15159 navy_theater 整块发射 cc+352 (段侧已实现) |

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | country tag → 引号串 |  |
| +16 | CTheaterGroup* 向量 | theater_group 数组 — CTheaterGroup scoped | 逐元 ADEC0 tok 13777 |

#### 4.24.12 CNavyTheaterGroup (96B, writer 未查)

ctor 0X1415B9390; sizeof 0x60 = 96; owner CNavyTheater 回指@+24。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | — | refid |  |
| +24 | CNavyTheater* | owner 回指 |  |
| +32 | 匿名结构 (元素待裁) 向量 | fleet — tok 15156 |  |
| +56 | SSO | name — tok 27 (⚠ 与陆军 CTheaterGroup+40 异构) |  |
| +72 | idpair | GUI target — CNavyTheaterGroupItem SetTarget sub_141E73010 直拷 |  |
| +88 | uint8 | is_important |  |

注 (GUI): 命令族 RTTI 实名 = CSetNavyTheaterGroupForCommand / CSetNavyTheaterGroupImportantCommand / CSetNavyTheaterGroupNameCommand。
注 (GUI): CNavyTheaterGroupItem (sizeof 0xB70) target = 本对象 +72 idpair; 基 CNavyTheaterGroupItemBase = CStandardGridBoxItem@0 + CTooltipHandler@24, 新添槽 [19] SetupDerived / [20] Reset。

本节未决:

- CTheatre +432 RB 树键/语义 (未决); +280 队列载荷类型待裁; +408 192B 元素业务语义待裁。
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
