> 本文件 = 类结构全书 §4 分册 (自 hoi4_runtime_classes.md 拆分)。规范 = 主文件 §0.1。

### 4.29 特务专项 (COperativeLeader 全字段 / mission 分发 / operation 块)

#### 4.29.1 COperativeLeader 特有区全字段表

身份表:

| 项 | 值 |
|---|---|
| RTTI 名 | COperativeLeader |
| sizeof | 0x10A8 (4264) — 两处独立 malloc_base(0x10A8) + ctor 旁证 |
| vtable RVA | vt0 0X142954730 / vt1 0X142954848 (+3928 CSelectable 子对象视口) |
| writer (vt slot2) | 0X140C28550 = 基链 0X140C1CE70 (前缀 [0,3928), 基类全表见 §4.4 CUnitLeader) + 特有区 |
| loader | — |
| 挂载点 | retired 池 {d@ch+200, c@ch+212} (CCharacter) 与现役 CIntelligenceAgency recruitment/agency 池 (§4.29.4), 同经 ADEC0 |
| ctor | 0X140C0BE20 (经 0X140C0C200 基类链) |
| dtor | 0X140C0D1B0 (触 +3928/+4232/+3944) |

ADEC0 备查: 写键 token 后调内嵌对象 vt 槽1 trampoline 自序列化, 传参 = &vt = 对象基址+8 (§3.7a 族 A, payload 在 ptr−8)。

**特有区全字段表** (writer 0X140C28550 调完基链后的发射序: nationalities →
captured + capture_date → codename → mission → state; 发射序 = 表序; 偏移 = leader 绝对):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +3928 | CSelectable | — | 不序列化 |
| +3929..+3943 | — | = CSelectable 子对象本体 (+3928..+3943) |  |
| +3944 | uint32 向量 | nationalities 数组数据 — u32 国家 tag 数组 (writer 0X140BB5A10); 提取器单行 `nationalities.#1` 空格连裸 tag | 门 计数@+3956≠0 开块, 逐元素 tag 名串 (5C20); tok 15634 (0x3D12) |
| +3945..+3955 | — | = nationalities 容器内部 {data 尾 +3945..+3951, cap u32@+3952}  |  |
| +3956 | uint32 | nationalities 容器计数 | |
| +3957..+3967 | — | = nationalities 容器内部 {alloc@+3960, pad}  |  |
| +3968 | uint32 | operation 对.type — 8B idpair; ctor 写哨兵 qword_14333D528 | 门 type≠0 ∨ id≠0; 0X142220180 (**写序先 id 后 type**); tok 12059 (0x2F1B); 叶序 codename 之后 state 之前 |
| +3972 | uint32 | operation 对.id | 同上 |
| +3976 | `std::optional<NOperativeMissions::COperativeMissionData>` | **32B value 存储 @+3976, `_Has_value` u8 @+4008** — MSVC optional 标准形 (拷贝 ctor sub_140C0BC10: poison 0xAA → present=0 → 条件逐字段拷贝 + present=1; 析构 sub_140C0D0D0 = reset; move-assign sub_140C0D820)。填充 = operationinstance.cpp:385 (sub_141400170, leader+4224==3 active 时取 op 实例快照); 清空 = sub_1413FFFB0 (operationinstance.cpp:677) | 不序列化 |
| +3977..+4007 | — | = +3976 匿名 32B 对象本体 (+3976..+4007) |  |
| +4008 | uint8 | (ctor 置 0) | 不序列化 |
| +4016 | tag_id (u32) | captured 俘虏国 tag — 与 +4024 capture_date 各自独立 (capture_date = 24B, 见 +4024 行) | 门 (i32)>0; writer 0X140BB59C0 → 提取形 `captured="TAG"`; tok 15636 (0x3D14) |
| +4017..+4023 | — | pad (capture_date vt1@+4024 前置对齐) |  |
| +4024 | CGameDate 24B {vt1@+4024, hours@+4032, vt2@+4040} | capture_date (ctor = 43808760 "1.1.1.1" 哨兵; 24B 占 +4024..+4047, 布局闭合) | 门 = captured>0 (**同一 if 块配对** — 无 captured 则 date 也不写); ADEC0 (ptr=vt2=+4040, hours=ptr−8=+4032); 提取形 `capture_date="Y.M.D.H"`; tok 19297 (0x4B61) |
| +4048 | CNameGroupMember 内嵌 (184B, 4048..4231; vt 0x142935b18) | codename | **恒写** (ADEC0 委托 → writer 0X1409C9AC0); tok 15639 (0x3D17); 子表见下 |
| +4049..+4223 | — | = CNameGroupMember 内嵌本体 (+4048..+4231; 内部布局见 §4.3 名字组表) |  |
| +4224 | uint32 枚举 | state — 枚举表见下 | 块键 439 (0x1B7), 0X1401F4F00 写枚举原子; 非法值 → assert("Invalid enum value", unitleader.cpp) 后仍写 14668 |
| +4232 | COperativeMission 内嵌 (32B, 4232..4263 = sizeof 闭合) | mission | 门 0X140FC4080 = (type@+4256 ≠ 0) (⚠ 0X141FC3D70 非函数, 勿用); ADEC0 委托 (writer 0X140FC6240); 子表见下 |

**state 枚举表** (0X1401F4F00 写枚举原子):

| 值 | 名称 | 语义 (存档原子 token) |
|---|---|---|
| 0 | on_capture | 19025 |
| 1 | on_cooldown | 19026; **GUI 显示态 = enroute** (COperativeMapIconEntry [19] 分支 1→leader+3976 optional, 显示 leader_enroute) |
| 2 | on_disband | 19027 |
| 3 | on_mission | 14668 (ctor 默认 3); GUI 分支 3→mission impl vt+72 (§4.29.3 互证) |
| 4 | on_operation | 19024; GUI 显示态 = on_operation (PortraitView 四态双处互证) |

GUI 显示态分组: 0/2/5 = idle, 1 = enroute, 3 = on_mission, 4 = on_operation (§4.31.43 视图族互证)。
| 5 | killed | 13164 |

**mission 句柄 (COperativeMission@+4232) 子表** (偏移 = leader 绝对, 括号内 = 对象内):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +4232 (+0) | vt | vtable | 不序列化 |
| +4240 (+8) | — | pad | 不序列化 |
| +4248 (+16) | 匿名结构 (NNB 形状)* | impl — mission 槽 ptr 位 (分发表见上) | 不序列化 |
| +4256 (+24) | uint32 | type — mission 槽 id 位; writer 门字段 | 不序列化 |
| +4260..+4263 (+28..+31) | — | pad (sizeof 闭合 4264) | 不序列化 |

注: mission 槽 = {ptr@+16, id@+24}; +4224 状态枚举 ==3 (on_mission) = active 互证; 全部 Set* 置 handle+24 = type (§4.29.3)。

**codename (CNameGroupMember@+4048) 子表** (writer 0X1409C9AC0; 偏移 =
leader 绝对, 括号内 = 对象内):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +4056 (+8) | uint32 | codename.type (ctor 默认 2) | **恒写** (ADFE0); tok 225 (0xE1) |
| +4064 (+16) | MSVC SSO | (ctor 预置; cap@+4088 (+40)) | 不序列化 |
| +4104 (+56) | uint32 | (ctor = −1) | 不序列化 |
| +4128 (+80) | 匿名结构 (idpair 宿主)* | **equipment** (idpair 宿主指针 → {type@+8, id@+12}) | q≠0 → 0X142220260; tok 12110 = `equipment` |
| +4136 (+88) | 匿名结构 (NNB 形状)* | (ctor = qword_14333D528 哨兵) | 不序列化 |
| +4144 (+96) | MSVC SSO | (ctor 预置; cap@+4168 (+112)) | 不序列化 |
| +4176 (+128) | uint32 | codename.name_order | 门 ≠0; tok 14563 (0x38E3) |
| +4184 (+136) | MSVC SSO (size@+4200) | **override** | 门 size@+152≠0 且 !AAFD0; tok 14561 = `override` |
| +4216 (+168) | uint8 | codename.is_name_ordered | **==0 才写恒值 no** (≠0 不写; 与 deployment division_name 同函数同规则 — CNameGroupMember 两处复用); tok 14562 (0x38E2) |
| +4217 (+169) | uint8 | **override_set_programmatically** | 门 ≠0; tok 14646 |

注: sizeof(CNameGroupMember) = 0xB8 (4048+184 = 4232 = mission 起点, 布局闭合)。

**mission (COperativeMission@+4232) 分发表** (writer 0X140FC6240: assert
impl 非空 → switch(type) 取 mission 名 token → ADEC0(token, impl) 委托
impl 自己的序列化器):

| type | 存档名 | 名 token | impl 类 (vt) | impl writer (vt slot2) |
|---|---|---|---|---|
| 0 | (CNoMission, 门挡住不落盘) | 12789 | CNoMission 0x142980430 | 0X14012A2C0 (空) |
| 1 | build_intel_network | 15642 | CBuildIntelNetwork 0x142a1f878 | 0X141A31840 (state/network 族共用) |
| 2 | quiet_network | 19232 | CQuietIntelNetwork 0x142A1FFC8 | 0X141A31840 |
| 3 | counter_intelligence | 15643 | CCounterIntelligence 0x142A1FCA0 | 0X141A328B0 (country 族共用) |
| 4 | root_out_resistance | 19233 | CRootOutResistance 0x142A201B8 | 0X141A31840 |
| 5 | boost_ideology | 19228 | CBoostIdeology 0x142A1F5E8 | 0X141953D00 |
| 6 | control_trade | 19229 | CControlTrade 0x142a1fb00 | 0X141A328B0 |
| 7 | diplomatic_pressure | 19230 | CDiplomaticPressure 0x142A1FE00 | 0X141A328B0 |
| 8 | propaganda | 19231 | CPropaganda 0x142A295A8 | 0X141A31840 |

注: 中间基类与 impl 全布局见 §4.29.3; default → assert("Token not defined for mission type!", operativemission.cpp)。
存档消费形态: `mission.<名>.target` = tag u32@impl+16 (引号 tag); `mission.<名>.state` = u32@(*(impl+24))+88 (≠0 才写)。

本节不确定点:

- +3976 = `std::optional<COperativeMissionData>` (定案, 见上表)。
- CNameGroupMember 三未名字段定名 (高置信): +136 = override / +169 = override_set_programmatically / +80 = equipment (idpair; 铁路炮 +824 装备对呼应); tok 14561 / 14646 / 12110 对应 above。
- 基链 traits 循环 (块 12278) 每元素发两原子: trait token + 字面原子 18 — 定案: 纯文本层格式原子 (sub_1401F4F00(stream,N) = 写 (N, 词元串) 文本原子; 16 = 空串、18 = 单空格), 提取器丢弃正确。
- 原子 16 的文本形态: nationalities 块尾与 origin_type 块尾各写一个 0X1401F4F00(16) — 同上定案 (空串文本原子)。
- effect Parse token 12112 = `division_template` (离线表 + 运行时表双证; parse 现场 case 12112 → `sub_1424C0AA0(a2, a1+40)` 于 0x141BA0900)。

#### 4.29.2 operation 块 (存档块名, 非 RTTI 类名)

**operation 块子键表** (op 相对):

| 存档键 | 块数据 | 写门/格式 |
|---|---|---|
| civilian_factories / total (代价) | civ i64×1e-5@op+48, total i64×1e-5@op+56 | 门 civ≠0; writer 0X141404B00 |
| resources | 容器 {d@op+344, c@op+356}, 元素子表见下 | 门 count≠0 |
| return_on_complete (tok 19426/0x4BE2) | 容器 {d@op+368, c@op+380}, 元素子表见下 | 门 count≠0; writer 0X141404B00; 存档形态 = 半行匿名对象 `{ {id=X type=Y}` ␍ `amount}` → 提取器折 `return_on_complete.@.#N` = amount/1e5 (id 对被提取器丢弃; USA 锚 0x1AEAA→1.1025) |

ops 容器 (sub_14022FFF0 实例表) 形态补记: {data@+16, count@+28}, 8B 指针元 (推定)。

**resources 元素子表** (32B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | i64 | amount | flag≠0 → 块值 = C 截断 raw/1e5 + days |
| +8 | uint32 | days | |
| +16 | 匿名结构 (NNB 形状)* | def | |
| +24 | uint8 | flag | 分支门见下注 |

注 (resources 分支): flag≠0 → 发 `civilian_factories` 块 (tok 0x4BDD/19421); flag=0 → 键名 = token@*(e+16)+8, 单叶 fixed5。

**return_on_complete 元素子表** (16B):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | uint32 | type | id 对被提取器丢弃 |
| +4 | uint32 | id | 同上 |
| +8 | i64×1e-5 | amount | 提取值 = amount/1e5 |

civilian_factories 条适配器 (非 GUI 类, 匿名 ns 函子 parse/serialize 适配器; 三证):

| 项 | 值 |
|---|---|
| writer | 0X140A7B070 |
| parser | 0X140A7AB40 |
| token | 19421 |

**COperationInstance 行级字段** (与本节 op 同族):

| 偏移 | 名称/语义 |
|---|---|
| +8 | self ref |
| +64 | auto_commence |
| +65 | auto_repeat |
| +66 | completed |
| +72 | COperation* def |
| +80 | owner cc |
| +88 | 目标 tag |
| +96 | 目标对象 |
| +112 | 开工 hours |
| +128 | 工期 days |
| +160 | 完成文本 |
| +192 | 双旗 (一) |
| +193 | 双旗 (二) |
| +224 | 特工快照表 (56B 快照, §4.29 同族) |
| +248 | 名 |
| +336 | 资源区 |

**关联消费点表** (COperation def / COperationPhase):

| 类 | 偏移 | 语义 |
|---|---|---|
| COperation (def) | +8 | def 消费点 |
| COperation (def) | +376 | def 消费点 |
| COperation (def) | +472 | def 消费点 |
| COperation (def) | +1168 | def 消费点; **GUI: 底栏小图标 gfx** (COperativeBottomBar 消费; 与 +1200 成双 = 大小图标, 推定待裁) |
| COperation (def) | +1200 | **GUI: 肖像视图大图标 gfx** (COperativePortraitView SetPortrait operation SetGfx 消费) |
| COperationPhase | +144 | 名 |
| COperationPhase | +176 | icon |
| COperationPhase | +240 | 标题 |
| COperationPhase | +368 | icon (两条目类分别消费) |

#### 4.29.3 mission impl 基类与 per-impl 全布局

谱系 (RTTI 全扫 12 类全齐): NOperativeMissions::IOperativeMission 纯接口 (无自身 typeinfo) → CNoMission 8B / CStateBased 32B → {CNetworkBased 32B (零新增字段) → CBuildIntelNetwork 64B / CQuietIntelNetwork 32B / CBoostIdeology 72B / CPropaganda 64B; CRootOutResistance 32B 直承 CStateBased} / CCountryBased 24B → CControlTrade / CCounterIntelligence / CDiplomaticPressure 各 56B。COperativeMissionData 32B = 任务快照非任务对象 (见下); COperativeMission 句柄 32B = leader+4232 内嵌。清偿补注: **mission+88 = 州对象缓存**（州+204 = 控制国比对, 书定案）、**mission+96 = 意识形态指针**（kind5 "#~ No ideology" 门）——CSetOperativeMission 旧推定废。命名空间多出的 2 条 RTTI = CQuietIntelNetwork::GetProvincesInRangeOfState lambda 载体 (vt 0x142A20148 / 0x142A20180)。

**中间基类表** (RTTI 定案):

| 类 | sizeof | vtable | 共用 writer (vt slot2) | 派生 |
|---|---|---|---|---|
| CStateBased | 32 | 0x142A1F538 | — | CNetworkBased / CRootOutResistance |
| CNetworkBased | 32 | 0x142a1f538 | 0X141A31840 | CBuildIntelNetwork / CQuietIntelNetwork / CBoostIdeology / CPropaganda (零新增字段, 仅覆 vtable) |
| CCountryBased | 24 | 0x142a1fa50 | 0X141A328B0 (只发 target) | CControlTrade / CCounterIntelligence / CDiplomaticPressure |

**全族虚表槽表** (12 类):

| 槽 | 函数 | 语义 |
|---|---|---|
| slot1 | 各类 dtor | — |
| slot2 | 各类 writer | 见 per-impl 表 |
| slot3 | 0X1424BE690 (共享) | — |
| slot10 | 0X141A314F0 (共享; CNoMission 单用 0X140FC37F0) | 名 token getter |
| slot17 | 各 impl 独立实现 (基类 purecall 0X14253C3B8) | 填 COperativeMissionData 快照 |

**CStateBased (32B) 字段表** (ctor 0X141A31390 默认 / 0X141A313B0 全参):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vt | vtable | 不序列化 |
| +8 | COperativeMission* | owner — 所属 mission 句柄 | 不序列化 |
| +16 | tag_id | target country — 0X140BB59C0 引号串 | 门 >0 |
| +20 | — | pad | 不序列化 |
| +24 | CState* | pState; 快照 fill 0X141A313D0 (assert "pState not set", operative_mission_state_based.cpp:0x50) | writer ADFE0 — tok 439, 发 *(pState+88) |

**CCountryBased (24B) 字段表** (ctor 0X141A32670 / 0X141A32690):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vt | vtable | 不序列化 |
| +8 | COperativeMission* | owner — 所属 mission 句柄 | 不序列化 |
| +16 | tag_id | target country | writer 0X141A328B0 (country 族共用) 只发此字段 |
| +20 | — | pad | 不序列化 |

注: CNetworkBased 无新增字段, 仅覆 vtable (ctor 0X141A31890 / 0X141A318C0)。

**COperativeMissionRegistrationHandler (32B) 注册器** (运行时注册器, 不序列化; init 0X141E8FF70 / register 0X141E90170 / teardown 0X141E903B0 + 0X141E8FF90):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | 匿名结构 (NNB 形状)* | owner — 所属 mission 句柄 | 不序列化 |
| +8 | 函数指针 | do | 不序列化 |
| +16 | 函数指针 | undo | 不序列化 |
| +24 | uint32 | 已注册国 id | 不序列化 |

register 流程: 国 id>0 → gs+1696 operatives mgr per-country 项 (sub_140EB2E80 查) → do(项, handle) → 记 id。
⚠ assert "Invalid registartion country"〔原文拼写〕 operative_mission_registration_handler.cpp:0x26。

**do/undo 对表** (6 对):

| mission (type) | do (索引数组基址) | undo |
|---|---|---|
| CBuildIntelNetwork (1) | 0x1411FF040 (a1+64) | 0x141200A80 |
| CBoostIdeology (5) | 0x1411FEF90 (a1+88) | 0x1412009D0 |
| CControlTrade (6) | 0x1411FF0F0 (a1+136) | 0x141200B30 |
| CCounterIntelligence (3) | 0x1411FF1B0 (a1+40) | 0x141200BE0 |
| CDiplomaticPressure (7) | 0x1411FF260 (a1+160) | 0x141200C90 |
| CPropaganda (8) | 0x1411FF320 (a1+112) | 0x141200D40 |

> 六对均由 `sub_141E8FF70(handler, owner, do, undo)` 注册，注册点各自 vftable 实名直证
> (sub_141954150 = CBuildIntelNetwork / sub_141952310 = CBoostIdeology / sub_141955BE0 =
> CControlTrade / sub_141956F60 = CCounterIntelligence / sub_1419585D0 = CDiplomaticPressure /
> sub_1419DEC50 = CPropaganda)。**副作用 = 有序数组的插入/删除 (mission 索引登记)**: do 端
> sub_1411FCFC0 对 8B 元素 {tag u32@0, idx u32@4} 有序数组二分查找，未命中则 sub_1401B1640 插入;
> undo 端 sub_1411DC2B0 同型二分删除。do/undo 体形完全同构 (唯索引数组基址不同): do 以空 ref 哨兵
> qword_14333D528 起步 + 断言 ref.h:83 → sub_1411FCFC0; undo 同前段 → sub_1411DC2B0。

**per-impl 表** (sizeof 双证 = Set* 创建 malloc + clone 工厂 malloc; 全闭合):

| type | impl | sizeof | 基类 | handler | writer | Set* 创建 | clone |
|---|---|---|---|---|---|---|---|
| 0 | CNoMission | 8 | — | 无 | 0X14012A2C0 (空) | 0X140FC5A90 | — |
| 1 | CBuildIntelNetwork | 64 (0x40) | CNetworkBased | @+32 | 0X141A31840 | 0X140FC5390(h,tag*,pState) | 0X141954650 |
| 2 | CQuietIntelNetwork | 32 | CNetworkBased | 无 | 0X141A31840 | 0X140FC5DF0 | 0X141959E10 |
| 3 | CCounterIntelligence | 56 (0x38) | CCountryBased | @+24 | 0X141A328B0 | 0X140FC5710(h,tag*) | 0X141957860 |
| 4 | CRootOutResistance | 32 | CStateBased 直系 | 无 | 0X141A31840 | 0X140FC5FB0 | 0X14195AE90 |
| 5 | CBoostIdeology | 72 (0x48) | CNetworkBased | @+32 | 0X141953D00 (+ideology) | 0X140FC51B0(h,tag*,pState,ideo*) | 0X1419528D0 |
| 6 | CControlTrade | 56 (0x38) | CCountryBased | @+24 | 0X141A328B0 | 0X140FC5550(h,tag*) | 0x141942BD0 |
| 7 | CDiplomaticPressure | 56 (0x38) | CCountryBased | @+24 | 0X141A328B0 | 0X140FC58D0(h,tag*) | 0X141958EB0 |
| 8 | CPropaganda | 64 (0x40) | CNetworkBased | @+32 | 0X141A31840 (**无 ideology**) | 0X140FC5C30 | 0X1419DEFB0 |

注: 全部 Set* 置 handle+24 = type。CBoostIdeology +64 = CIdeology* (ctor a1[8]=a5); writer 0X141953D00 = 0X141A31840 + ADCE0(0x2E3E, *(ideo+20)) → `ideology = <名>`, 门 pState 与 ideology 皆非空。

**COperativeMissionData (32B) 快照字段表** (vt 0x142955b40; writer 0X14194E520; ctor 0X14194D810 5参 / 0X14194D880 4参 / 0X14194D850 3参):

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +0 | vt | vtable | 不序列化 |
| +8 | uint32 | mission type — ADCE0 tok 11450; 值域 = 0X140FC4150 type→名 switch (与分发表同表) |  |
| +12 | tag_id | target_country — tok 14964 | 门 >0 |
| +16 | CState* | pState — tok 14965 → 发 *(pState+88) | 门 非空 |
| +24 | 匿名结构 (NNB 形状)* | ideology 定义 ptr — tok 11838, deref+24 = MSVC 串 (ADF40) | ADF40 |

注: optional 包装 move-assign 0X140C0D820, present u8@+32 (对象尾后)。消费 = operationinstance.cpp:385 (0X141400170): leader+4224==3 (active) 时经 0X140FC1130 (handle+16 → impl slot17) 取 op 实例 56B 元素内快照。

**op 实例 56B 快照元素** (operationinstance.cpp:385 消费形态):

| 元素+N | 内容 |
|---|---|
| +0 | vt |
| +24 | type |
| +28 | tag |
| +32 | ptr |
| +40 | ptr |
| +48 | present |

**token 键名表** (lexer 在线直证):

| token | 键名 |
|---|---|
| 107 | target |
| 439 | state |
| 11450 | mission |
| 14964 | target_country |
| 14965 | target_state |
| 11838 | ideology |

注: 9 个 mission 名 token 与 §4.29.1 分发表全一致。

本册未决:

- handler 6 对 do/undo 具体副作用 = **有序数组的插入/删除 (mission 索引登记)** (定案) — 详见表下注 (do/undo 地址与索引数组基址全定)。
- handler+24 读回消费点 = **unregister 路径** (定案): register sub_141E90170 调 do 后记国 id; unregister sub_141E903B0/sub_141E8FF90 用记下的 id 反查 per-country 项 → 调 undo → 清 0。
- CState 侧 mission 反向引用维护者 (**未决维持**): 全 dump 未找到 CState 持有 COperativeMission*/COperativeMissionData 的写点; mission 侧仅单向 pState (COperativeMissionData+16)。
- CPropaganda ideology 不落盘 — 定案 (以 writer 为准): 共享 impl writer 只发 target(107)/state(439), 无 11838 — 读侧接受写侧不落盘的非对称 (mod 注入兼容), 非漏发。
- COperativeMissionData **从不落盘** (负定案): writer sub_14194E520 全 dump 引用数 = 1 (仅定义行), 其 vt 0x142955B40 不被任何 Save wrapper 入口调用 ⇒ 纯运行时快照。

#### 4.29.4 CIntelligenceAgency (ag = rp(cc+4032), vt 0X2981F68, writer 0X140FDF3A0)

| 字段 | 偏移 (ag) | 布局/写门 |
|---|---|---|
| recruitment 内嵌 (vt 0X29D8FF0, writer 0X14157BE20) | +8 | 三容器族 (下表) |
| upgrades {d, c@+108} 16B {tok*, u32} | +96 | count>0; **GUI: 分支升级格** (CBranchUpgradeButtonEntry sub_141A230F0; DB qword_14332EDC0 {count@+124, items@+112} → upgrade_button; `agency_branches` 格) |
| name SSO | +128 | 恒写; **GUI: 机构名** (Repopulate 0X140F2F3A0 → win+1448; agency_name) |
| icon SSO | +160 | 恒写 (icon 空串写 ""); **GUI: 机构徽标** (→ win+1672 (vt+728); name_logo) |
| is_created (b) | +192 | 仅真写 |
| in_creation (b) | +193 | 仅真写 |
| upgrade_progress i64×1e-5 | +200 | 仅 ≠0; **GUI: 分支升级进度** (CBranchUpgradeButtonEntry 消费, 同 +96 链) |
| operative | +216 | {d@+216, c@+228} 8B operative 指针; = root_out_resistance (mission 4) 列表 (注册回调反查定名) |
| own_operative_death u32 (0x4B60=19296) | +252 | >0 才写 |
| max_operative_count | +240 | 恒写含 0 |
| usable_operative_slots | +244 | 恒写含 0 |
| elapsed_days_for_next_slot | +248 | 恒写含 0 |
| building | +256 | 恒写含 0 |
| captured | +264 | {d@+264, c@+276} 56B 元; count>0 开块 |
| cryptology | +288 | = *(ag+288) → intel_source 内嵌@+16 (vt 0X295F138): country idx@+8 / pool@+12 / id@+16 / discriminant@+20; 开键 idx>0 且 pool≠0 (0X14197F040), 4 叶恒写 — 归 sv2_sec_c_intel 段管辖; **GUI: CCryptology 入口** (密码头部 LEVEL = mdef 528 crypto_strength @*(crypt+8)+1464 / STRENGTH sub_1413F7C60 + cryptology_country_entry 国别行; 全链 §4.11) |
| defense i64×1e-5 | +296 | 恒写含 0 |

recruitment 三容器 (容器 writer 0X141579010 count>0 才开块; 8B 指针元):

| 字段 | 偏移 (recruitment) | 键 | 备注 |
|---|---|---|---|
| generated_operatives | {d@+16, c@+28} | 0x4B44=19268 |  |
| recruitable_operatives | {d@+40, c@+52} | 0x4B45 |  |
| recruitable_operatives_not_to_spy_master | {d@+64, c@+76} | 0x4B54 | ctor 0x141579120 双子容器 |

COperativeLeader writer 链 (基 0X140C1CE70 + 0X140C28550):

| 字段 | 偏移 (e) | 写门 |
|---|---|---|
| id | {id@+12, type@+8} | 恒写 |
| name | MSVC@+32 | 恒写 |
| gfx | MSVC@+256 | size≠0 (运行时清空 → 不写) |
| female | b@+3712 | 仅 b@+3713≠0 写 |
| skill | u32@(*(e+3680))+440 | 恒写 |
| experience | i64×1e-5@+3688 | ≠0 |
| script_id | u32@+3924 | ≠0 |

#### 4.29.5 country.operations (ops = *(cc+5544))

| 块 | writer | 布局 |
|---|---|---|
| priority | 0X1411A2690 (ADFE0(0x8D), 挂载 ADEC0(0x4A38)) | u32@ops+88 恒写 (默认 1 照写 — 439 叶全量实证; 与 supply priority 默认不落盘规则不同) |
| finished (ops+40 子对象, vt 0X27E7528) | 0X1411A19A0 | 外 RH {data@+16, mask@+28, extra@+32} 48B 桶 {dist@+4, op token id@+8, 内表 ptr@+24, 内 mask@+36, 内 extra@+40}; 内表 12B 桶 {dist@0, tagidx@+4, count@+8}; 发射 = 外桶逐有效键一块 (op token 名), 内 tag 按 tagidx 升序 "TAG count" 空格连接 |
| running (gate count@ops+28≠0; {data@ops+16}) | 0X141404B00 (块名 = token@*(op+72)+8 op def) | id 对 {type@op+8, id@op+12}; duration u32@op+128 ≠0 才写 date+duration (date hours@op+112, CGameDate 代理 vt@+120 hours 在 vt−8 — raids 同构); equipment 块恒写 (ADEC0(0x2F4E, op+272), allow_zero_entries@op+272+56); target = 国 idx@op+88 → 引号 tag 恒写; target_provinces = ptr@op+96 → u32@ptr+164 (指针门); operative_slots 门 count@op+236≠0: {data@op+224} 56B 元 (0X141BE6A40): operative id 对 {type@0, id@+4} 非零门 / resume_mission u32@+8 ≠0 写 yes / mission 块门 b@+48≠0 对象@el+16 (0X14194E520): mission 枚举@+8 → sub_140FC4150 switch 0..8 裸名 / target_country 国 idx@+12 >0 / target_state ptr@+16 → u32@ptr+88; phases 门 count@op+260≠0: {data@op+248} 8B 指针 → token 名 u32@*(el)+8 引号空格单行; prepared: hours@op+208 ≠ 43808760 才写 (vt 代理@+216) |

#### 4.29.6 情报机构事务族 (资源/令牌/阶段/升级/历史机构/转移动作)

**COperationResources** (行动资源清单容器; vt 0x14271AB70; writer 0x140A7B070 / reader 0x140A7AB40; 入档): 容器 {d@8, c@20} 32B 元 = {i64 amount@0 (civilian 元 = raw/1e5 整写, 装备元 = fixed), u32 days@8, def 指针@16 (civilian → civilian_factories(19421) 块 / 装备 → def+8 token 名), u8 civilian 旗@24}; 挂载 = op+344 resources 块。

**COperationToken** (行动奖励令牌定义, ~184B; vt 0x14271ADF0; writer=CFG; reader 0x140A7FC30; idb operation_tokens 已挂): +16 desc (10644) / +48 icon (181) / +80 name (27) / +112 text_icon (19424) / +144 i64 intel_gain (19022) / +152 {dword intel 来源种类, u8 旗@156} (19252) / +160 targeted_modifier 容器 (14623, 8B 修饰 def 指针, 去重报错)。

**COperationPhaseSelection** (phases 选择列表容器, 32B; vt 0x14293F288; writer=CFG; reader 0x140A7B420): op def 的 phases(19005) 块挂 **op+1936** {d@1936, c@1948} 本类实例, 内容 = 8B 指针元 → COperationPhaseSelectionMember; 无效 phase 名剔除并日志 (operationphase.cpp:68)。**COperationPhaseSelectionMember** (288B; vt 0x14293F148; writer=CFG; reader 0x140A7B6F0 = 直通 +16 槽[4]): +8 u32 phase 名 token / +16 CAIMTTHChance 内嵌 272B (该 phase 的 AI 选中权重)。

**CAgencyUpgradeBranch** (机构升级分支定义; vt 0x1427DF190; writer=CFG; reader 0x140625780): +40/+64/+88/+112 四容器 (+64 = 分支内升级清单 {d@64, c@76}, 元 = CAgencyUpgrade 624B {SSO 名@+24, FNV@+56}, 重复报错 agencyupgrade.cpp:262); +40/+88/+112 三容器语义未决 (reader sub_140625780 只显式用 +64 做同名合并, 其余三容器无键分派分支; writer = CFG 空桩 ⇒ 无 token 锚)。idb agency_upgrade 已挂 (0x332EDC0)。

**CHistoricalAgency** (历史机构名簿; vt 0x1427DF060; writer=CFG; reader 0x140621F70): **+16 names 串列表容器** (12767, SSO 32B 元) / +40 picture (464) / +72 available (12264) 子对象 / +160 default (11405) 子对象 — random_historical_agency 取名的数据底 (与 §4.33.10 CSetIntelligenceAgencyRandomHistoricalNameCommand 互证)。

**CCapturedOperativeReference** (被捕干员引用, 56B; vt 0x142981FB8; writer 0x141A34FF0 / reader 0x141A34F40; 入档): +8 country tag (10394) / +12 operative idpair (15635) / +24 intel 四象限 (12524) — ag+264 captured 列表元素。

**CTransferSpyMasterAction / CTransferHeadOfCounterIntelAction / CTransferHeadOfCryptologyAction / CTransferHeadOfOperationsAction** (情报机构首长转移四动作; CDiplomaticAction 120B 零新增薄派生, writer/reader 同址直挂基类真体 0x141141470/0x14113E7A0):

| 类 | vt | [23] 名产出 | [24] Clone |
|---|---|---|---|
| CTransferSpyMasterAction | 0x14298F3E8 | 0x14112E7E0 → DIPLOMACY_SPYMASTER | 0x141102550 |
| CTransferHeadOfCounterIntelAction | 0x14298F610 | 0x14112E690 → DIPLOMACY_HEAD_OF_COUNTERINTEL | 0x141102460 |
| CTransferHeadOfCryptologyAction | 0x14298F838 | 0x14112E700 → DIPLOMACY_HEAD_OF_CRYPTOLOGY | 0x1411024B0 |
| CTransferHeadOfOperationsAction | 0x14298FA60 | 0x14112E770 → DIPLOMACY_HEAD_OF_OPERATIONS | 0x141102500 |

> +104 type = 首长槽别 (枚举值待裁); 落点 = fac+2104 间谍首脑槽表 (§4.33.10)。

**AI 四驱动 (CAIModule 基, 名录; 无存档字段; 共性 +64 = owner 上下文; 门控读 CStrategicAI+8765 (csa+5965) 战略首轮就绪旗, §4.34.11)**: COperationsAI (vt 0x1429AC6B0; [14] 周期启动门 → post CLaunchOperationCommand; [15] 周优先级) / COperativesAi (0x14298A2E8; [14] 干员招募+任务分派; 无周更) / CIntelligenceAgencyAI (0x1429AB938; **[15] 建局主逻辑**, DLC 门 25; [14] 仅 metrics 日志) / CCryptologyAI (0x1429AB130; +72 = cryptology 对象指针 (宿主 = agency+288 推定); [14] 日补位 + [15] 周重评估; **密码部门激活门 = 日/周共用前置门**)。四家 AI 行为全链见 §4.34.14。

#### 4.29.7 行动令牌管理器与情报 defines 全局映射

**CCountryOperationTokenManager** (国别行动令牌管理器, 72B; cc+5552 tokens scopedptr 本体; ctor 0x141405CF0(cc); **入 savegame 国家块**): writer 0x141407F90 / reader 0x141406F20; 落键 = intel_source (19252, +16 内嵌子对象) + operation_assets (16245, RH 表 40B 条目 {+48/+56/+60/+64}, 排序后落盘), reader 兼容旧键 tokens (19016); 与相邻 cc+5544 CCountryOperationManager (内含 CCountryFinishedOperations@+40) 配对 — 干员令牌 def 见 §4.31.43 COperationToken, 本类持运行态令牌清单。

| 全局地址 | define 全名 | 定义件值 | 注册点 | 消费者 |
|---|---|---|---|---|
| dword_143335730 | NOperatives::AGENCY_CREATION_FACTORIES | 5 | dump L5566522 | CIA 建局门槛 IsValid 0x141A298E0 (可用民工厂 ≥ N) |
| dword_143335C90 | NOperatives::BECOME_SPYMASTER_PP_COST | 50 | L2489973 | CBecomeSpyMaster Execute 0x141A27370 (非 DLC 通道政治力) |
| dword_143335D14 | NOperatives::BECOME_SPYMASTER_MIN_UPGRADES | 3 | L1473366 | IsValid 0x140FD8F60 (所需情报局升级数) |
| dword_1433357C8 | NFactions::FACTION_INTELLIGENCE_UNLOCK_COST | 1 | L4524049 | CBecomeSpyMaster DLC 通道 (100000×值 扣 ms+72; 同 §4.31.21/§4.31.2 解锁费) |

> 名证 = 注册调用点与全名串返回函数双证 (映射表六地址均唯一), 值级与 common/defines/00_defines.lua 对拍一致。

> **本域 GUI 类布局**: 见 4.31.43。
