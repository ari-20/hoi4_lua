

### 4.4 CCharacterManager / CCharacter / CUnitLeader 派生族 (角色族)

#### 4.4.1 类身份与 writer 绑定

RTTI 定案。

| 类 | vtable RVA | slot2 (=Save 本体) | 说明 |
|---|---|---|---|
| CCharacter | 0X297EA60 | 0X140FA6520 | 基类 CReferenceObject(+0) ← CPersistent; 非多用 |
| CUnitLeader | 0X2955B90 | _purecall (0X14253C3B8) | **抽象**: SerializeBody 纯虚, 无直接实例 writer |
| CArmyLeader | 0X2955CA8 | 0X140C28200 | 首行调基 writer 0X140C1CE70 |
| CNavyLeader | 0X2955DC0 | 0X140C283F0 | 同上 |
| COperativeLeader | 0X2955F00 | 0X140C28550 | 特有区全字段表见 §4.11 |

谱系 (RTTI 直读):

| 类 | RTTI 基对象布局 |
|---|---|
| CUnitLeader | CUnitLeaderBase@mdisp24 + CReferenceObject@0 + CPersistent@0 + CUnitLeader::TNamespacedTrait@3808 |
| CNavyLeader | 上行 + CCustomizableBuildingListener@3928 |
| COperativeLeader | 上行 + CSelectable@3928 + COperativeLeaderBase@3944 |

CCommander 负定案: 1.19.2 RTTI 全谱无此类; char+168 leader 指向对象 = CArmyLeader/CNavyLeader/COperativeLeader 三选一, 由 leader_type u32@+3708 判别 (character.cpp writer switch):

| 形态 | 判别 (leader_type u32@+3708) | writer 行为 |
|---|---|---|
| CArmyLeader (FM) | 0 | 块键 field_marshal |
| CArmyLeader (corps commander) | 1 | 块键 corps_commander |
| CNavyLeader | 2 | 块键 navy_leader |
| 其它值 | ∉ {0,1,2} | assert "Unexpected leader type" 且整块跳写 |

#### 4.4.2 CUnitLeader 全字段表 (writer 0X140C1CE70)

army/navy/operative 三派生共用; 偏移 = leader 绝对字节; 引擎落盘序 ≠ 偏移序 — 派生 writer 首行调基 writer, 基块在前派生尾段在后; 多重集对拍无序无害。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | CID.type (type=4713 引用类) | 恒写; `id = { id type }` 块 (0X142220340) |
| +12 | uint32 | CID.id | 恒写 (同上) |
| +13..+31 | 匿名结构 (19B 形状) | = CID.id 尾 (+13..+15) + CReferenceObject 簿记 (+16..+23, ctor 清首字节) + **CUnitLeaderBase 子对象 vptr (+24..+31; mdisp24 实体化)** | ⚠ 基类参数化 ctor 0X140C0C2A0 的 a1 = leader+24, 其内偏移须 +24 才是 leader 绝对值; dtor 链 0X140C0D340(a1+24); ctor 0X140C0C200 |
| +16 | qword | CReferenceObject 基类簿记 (引用计数/池链接族) | char dtor 收尾链实锤 |
| +32 | SSO 串 | name | 门 qword@+48≠0 且文本模式; 引号串; tok 27 |
| +33..+63 | SSO 串本体 (31B) | = name SSO 32B 本体 (+32..+63; ctor 8 连 SSO 初始化 / dtor 8 连 free) |  |
| +64 | SSO 串 (32B) | **本地化显示名缓存** (定案: 实读「乔治·卡特利特·马歇尔」与 name token 严格对应; RebuildModifiers 复制进全部 15 个修正块的 name@+72 — sub_140C21FC0 链式 assign) | GUI 消费见表后注① |
| +65..+95 | SSO 串本体 (31B) | = 显示名缓存 SSO 本体 (+64..+95) |  |
| +96 | SSO 串 (32B) | **指挥官角色 loc 键名** (add_*_commander_role 尾 sub_140C257E0 写, +128 desc 串配对) | 高置信 (消费者命中) |
| +97..+127 | SSO 串本体 (31B) | = 隐藏串#3 SSO 本体 (+96..+127) |  |
| +128 | SSO 串 | desc | 门 qword@+144≠0 且文本模式; tok 10644 |
| +129..+159 | SSO 串本体 (31B) | = desc SSO 本体 (+128..+159) |  |
| +160 | SSO 串 | custom_cost_text | 门 qword@+176≠0 且文本模式; tok 14877 |
| +161..+191 | SSO 串本体 (31B) | = custom_cost_text SSO 本体 (+160..+191) |  |
| +192 | SSO 串 | portrait_path | 门 qword@+208≠0 且文本模式; tok 13051 |
| +193..+223 | SSO 串本体 (31B) | = portrait_path SSO 本体 (+192..+223) |  |
| +224 | SSO 串 | picture | 门 qword@+240≠0 且文本模式; tok 464 |
| +225..+255 | SSO 串本体 (31B) | = picture SSO 本体 (+224..+255) |  |
| +256 | SSO 串 | gfx | 门 qword@+272≠0 且文本模式; tok 12472 (引擎落盘序 gfx→picture→portrait_path, 段按偏移升序发射, 无害); ⚠ 堆模式实例 size@+272 可恒 0 而堆 buffer 残留完整串 (NUL 扫描可还原; 按 size 判空会丢行) |
| +257..+295 | 匿名结构 (39B 形状) | = gfx SSO 体尾 (+257..+287) + **tag_id i32@+288** (ctor 参数3 落点, 门>0; ApplyModifiers 链经 sub_140BB48F0/sub_140C07580 对该国施策 — 推定「将领修正归属国/原籍国」缓存, 精确语义未名 [未决], writer 不触) + pad@+292..+295 | ctor a3; 0X140C20FA0 |
| +296 | CSubUnitDefinitionAssociatedModifiers 内嵌块 (288B) | sub_unit_modifiers | 门 = u32@+316 与 u32@+340 不全 0 (IsEmpty sub_140643140); tok 15459; 全表见 §4.4.12 |
| +297..+583 | 匿名结构 (287B 形状) | = sub_unit_modifiers 288B 块体 (见 §4.4.12) |  |
| +584 | 容器数据 | **per-skill CUnitAdjuster 数组** (40B 元, 下标 = CUnitLeaderSkill 库内索引) | RecalcSkillBonuses sub_140C21280 重建 |
| +596 | uint32 | +584 数组 count | 定案 |
| +600 | uint32 | +584 数组 alloc (= &off_143085170 静态哨兵初值) | pdx 24B {data@584, cap@592, count@596, alloc@600} (ctor 增长码) |
| +608 | CUnitAdjuster | **CUnitAdjuster 总计器** (全 trait×skill 加成总和) {vt@608, q@624/632/640 ctor 清零}; 与 +648 阵列无缝 | sub_140C0FB70 聚合; ctor 0X140C0C2A0 |
| +648..+3527 | CModifier* | **命名修正块阵 b0..b14** — 物理基址 = leader+648 (ctor 0X140C0C2A0 直写 CModifier vtable×15 @subobj+624+192i; dtor 对成员@+640+192i 清理 15 次; RebuildModifiers 0X140C21FC0 名 assign 目标 928/1120/…/3424 = 648+192i+88 全命中); 块内 name SSO = CModifier+88; 阵列终于 +3527 与 traits@+3528 无缝; 块分工见 §4.4.3, 通用布局见 §4.3.8 | ctor + dtor + RebuildModifiers 三证 |
| +3528 | CUnitLeaderTrait* 容器数据 | traits — 元素 8B 指针, 叶名 = token u32@(trait+8); 裸列表 (无花括号, 分隔 token 18 空格); trait 对象内: +56 有效门 (replace 显式旧特质分支读) / +1740 事件门 / +2680 修正引用清单 {data, count@+2692, 16B 元, add/remove 聚合扣账} (均推定) | 门 计数@+3540≠0; tok 12278 |
| +3529..+3539 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3540 | u32 | traits 容器计数 |  |
| +3541..+3551 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3544..+3615 | 匿名结构 (72B 形状) | = traits 容器 alloc (+3544..+3551) + traits_to_remove 容器全体 (+3552..+3575) + in_progress 容器全体 (+3576..+3599) + trait_xp_factor 容器头 (+3600..+3615) | ctor/dtor 5 连容器 |
| +3552 | 16B 元容器数据 | traits_to_remove — 元 {trait 指针@0, u32@+8}; `{ }` 块 | 门 计数@+3564≠0; tok 14697 |
| +3553..+3563 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3564 | u32 | traits_to_remove 容器计数 |  |
| +3565..+3575 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3576 | 16B 元容器数据 | in_progress — 元 {trait 指针@0, i64×1e-5@+8}; 键 = trait token; **逐条恒写含 0 值** | 门 计数@+3588≠0; tok 12359 |
| +3577..+3587 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3588 | u32 | in_progress 容器计数 |  |
| +3589..+3599 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3600 | 16B 元容器数据 | trait_xp_factor — 元 {trait 指针@0, i64×1e-5@+8}; 运行时兼作特质修正聚合表 (16B 元增减; 推定) | 门 计数@+3612≠0; tok 14791 |
| +3601..+3611 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3612 | u32 | trait_xp_factor 容器计数 |  |
| +3613..+3647 | 匿名结构 (35B 形状) | = trait_xp_factor {cap 尾@3613..3615, alloc@3616..3623} + **第 5 个 24B pdx 容器 (raw+3624..+3647, 死字段)** |  |
| +3616 | CPdxNewDeleteAllocator* | trait_xp_factor 容器 allocator | dtor 释放 |
| +3624 | 容器数据 | **第 5 个 24B pdx 容器 {data@3624, cap@3632, count@3636, alloc@3640} — 真死字段 (负定案, 定案)**: ctor/copy ctor/dtor 三段闭环 (ctor 连调 5 次 sub_14011DF40 → raw+3528/3552/3576/3600/3624; dtor 逆序释放; copy ctor sub_140C1B810 整容器拷贝), 但 writer 只发射 4 容器 (+3540/+3564/+3588/+3612) 且全 dump 零写入点/零消费者 | 不序列化 |
| +3641..+3695 | 匿名结构 (55B 形状) | (**覆盖行**, 定案: 与 +3613..+3647 及 +3648/+3680/+3688 单列行逐字节重合, 无独立信息) |  |
| +3648 | SSO 串 | link | 门 qword@+3664≠0; tok 14790 |
| +3649..+3679 | SSO 串本体 (31B) | = link SSO 32B 本体 (+3648..+3679; ctor 清空 / dtor free) |  |
| +3680 | CUnitLeaderSkill* | skill 对象指针 — 叶值 = u32@(*ptr+440) (军衔等级) | **恒写, 指针无判空门** (直接解引用); tok 10453 |
| +3688 | fixed×1e-5 (i64) | experience 经验 | 门 ≠0; tok 11930 |
| +3689..+3711 | 匿名结构 (23B 形状) | = experience 尾 + **max_traits 缓存①②** (+3696 i32 ctor=0 / +3700 i32 ctor=−1 未算哨兵) + **海战计数@+3704** + **leader_type@+3708** (ctor 参数2; 3 = operative (推定); **dtor 置 4** = destructed 哨兵勿入合法域; **GUI: 将领类型判别显示** — CNavyLeaderItem/TraitWindow 命中, 2=navy_leader) + female 哨兵对 (+3712/3713) |  |
| +3696 | int32 | **max_traits 缓存①** (corps/FM define 基值 + 修正 0x15F) | sub_140C21D30 写, getter sub_140C18790 |
| +3700 | int32 | **max_traits 缓存②** (基值 + 修正 0x160; HQ 条件下再缩放) | getter sub_140C186D0 |
| +3704 | u32 | **将领进行中海战计数** (定案: CNavalCombatant 参战将领数组选拔链读取) |  |
| +3708..+3767 | 匿名结构 (60B 形状) | = **leader_type u32@+3708** (ctor 参数2; dtor 置 4 哨兵) + **female 0xAA 哨兵对** {u8@3712 = 0xAA, 写门 u8@3713} (ctor WORD@3712=0x00AA; 门开才落盘; dtor 门@3713≠0 复位 0x00AA) + cooldown 组总门@3716 + 冷却起始日期对 {vt@3720, hours@3728, 视图@3736} + 修正启用日期对 {vt@3744, hours@3752, 视图@3760}; 与 +3712/+3713/+3716 单列行重叠 | ctor/dtor 复位闭环 |
| +3712 | uint8 | female 值 | 门 byte@+3713≠0 → yes/no; 文本模式门; tok 10773 |
| +3713 | uint8 | female 写门 |  |
| +3716 | uint32 | cooldown 组总门 — ① cooldown_reason = 枚举→引号串 sub_140C12910 (0=no_cooldown / 1=reassigned / 2=harmed / 3=forced_into_hiding / 4=deployed / 5=withdrawing; tok 19226); ② leader_modifier_enable_date (tok 14723, 日期对@+3744/+3752, 视图 vptr@+3760); ③ leader_cooldown_start_date (tok 19458, 日期对@+3720/+3728, 视图 vptr@+3736) | 门 u32@+3716≠0; 日期对布局见 §4.4.4 |
| +3717..+3775 | 匿名结构 (59B 形状) | (**覆盖行** 与 +3708..+3767 行重合, 且其 +3768 划入日期区与脏标记实证冲突) |  |
| +3768 | uint8 | **修正重建脏标记** (RebuildModifiers 尾清 0; SetLeaderType/FM 刷新/勋章流均清) | 13 处清零命中 |
| +3769..+3787 | 匿名结构 (19B 形状) | = 修正重建脏标记区尾 + ctor 清零 pad (含 **+3784 u8 = loader trait 列表「免排序」开关**: 真=追加去重 sub_140C0EC40 / 假=二分有序插入 sub_1401B14F0; ctor 清零为族内唯一写点, copy ctor 恰跳过 → **永不置位残留旗**); 与 +3776 行重叠 |  |
| +3776 | fixed×1e-5 (i64) | max_traits | 门 ≠0; tok 14576 |
| +3777..+3795 | 匿名结构 (19B 形状) | = max_traits 尾 + ctor 清零 pad (含 +3784 u8 免排序开关, 见上行); 与 +3788 行重叠 |  |
| +3788 | qword | 隐藏遗留字段 (ctor 零, clone 拷 u32, 全 dump 无读者; 形态定案, 遗留推定) |  |
| +3789..+3795 | 匿名结构 (7B 形状) | = +3788 遗留 qword 尾 (+3789..+3795) + pad |  |
| +3796 | tag_id (i32) | government_in_exile_tag | 门 >0 引号 tag; tok 15034 |
| +3800 | int32 | legacy_id | 门 ≠-1 (0xFFFFFFFF); tok 19498; **有符号域** — 存档实证负值 -2/-3412 (PB:LOM), 读取须 i32 还原 (同 CCountryLeader+328 id 族); mem 恒 0 (reader 推定不回填 — 存档值仅存档侧可见) |
| +3804 | uint8 | promoted_from_unit | 门 ≠0 → yes/no; tok 17869 |
| +3805..+3839 | 匿名结构 (35B 形状) | = pad (+3805..+3807) + **CUnitLeader::TNamespacedTrait 本体 = 32B std::string (SSO) 死成员** (+3808..+3839; buf@3808 / size@3824 / cap@3832=15; ctor 建空串 + dtor 完整 SSO 析构闭环, **全 dump 零赋值点 → 负定案**; RTTI 谱系列基类@3808 见 §4.4.1) |  |
| +3840 | CDynamicModifierContainer 内嵌 (72B) | dynamic_modifier | 门 u32@+3892≠0 (sub_14060D020); tok 15361; 块体展开见下方子表 |
| +3841..+3911 | 匿名结构 (71B 形状) | = dynamic_modifier 72B 块体 (+3840..+3911, 见下方子表); dtor sub_140549F40 |  |
| +3912 | uint32 | **owner CCharacter 回指 CID.type** (leader→character; loader tok 10697 转发 CCharacter loader) | SetOwnerCharacter sub_140C24C70; **GUI: 将领条目 owner 显示链** (CNavyLeaderItem 命中) |
| +3916 | uint32 | owner CCharacter 回指 CID.id | 同上 |
| +3920 | uint8 | character template 存在缓存 (= *(char+32)!=0) | sub_140C24C70 |
| +3921..+3923 | 匿名结构 (3B 形状) | = +3920 u8 尾 pad (ctor 清零) |  |
| +3924 | uint32 | script_id | 门 ≠0; tok 19349 |

表后注① GUI 消费 (leader+64 显示名缓存): Badge 将领技能/名 + ListView 部署 tooltip — sub_140C15500 攻击技能; loc 键 LEADER_SKILL_DESC / UNIT_LEADER_NO_LEADER / LEADER_DEPLOY_* / LEADER_COMING / LEADER_WITHDRAWING; 部署三态字节 = **COrdersGroup+409 deployed / +410 deploy_queued / +411 withdrawing** (⚠ 本组字节曾按 leader 基址登记, 实为 COrdersGroup 基址 — 读取点对象为 COrdersGroup; 见 §4.4.8); vt[26] = 将领冷却剩余天数 `(23 − 今日 + enable_date)/24`。

dynamic_modifier 块体展开 (+3840..+3911, CDynamicModifierContainer 72B; 定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +3840 | vtable | vtable |
| +3856 | 匿名结构 (NNB 形状)* | owner 回指 |
| +3868 | idpair | CID 对 (nullCID 默认) |
| +3880 | SDynamicModifierEntry* | entries 64B 元数组 data |
| +3888 | uint32 | entries cap |
| +3892 | uint32 | entries count (= 块门) |
| +3900 | uint32 | entries alloc |
| +3904 | uint8 | 脏旗 |

条目 SDynamicModifierEntry (64B) 元素子表:

| 元素+N | 类型 | 名称 |
|---|---|---|
| +0 | vtable | vtable |
| +8 | tag_id | scope_country_tag |
| +12 | uint32 | scope_state_id |
| +16 | token | modifier token |
| +24 | 匿名结构 (NNB 形状)* | modifier def |
| +32 | uint8 | enabled |
| +40 | 容器数据 | values {data@+40, cap@+48, count@+52 = def+452} |

序列化形 `modifier/value[.#N]/enabled` (锚件 1826 叶实证; 效果类锚 CAddRemoveDynamicModifierEffect::Execute 0x1403efa30)。

#### 4.4.3 CUnitLeader 命名修正阵 b0..b14

trait 四类修正源 = modifier (trait+864) / non_shared_modifier (trait+1056) / corps_commander_modifier (trait+1248) / field_marshal_modifier (trait+1440) (tok 10597/14886/14690/14691); 归并链 = trait loader sub_140AEBC20 token switch + RebuildModifiers sub_140C21FC0 归并 + ApplyModifiers sub_140C21570 输出 (定案)。

| 块 | 块锚 (= CModifier+16 成员基; 对象物理基 = 锚−16) | 来源/用途 |
|---|---|---|
| b0 | +664 | **最终输出 A**: += b5 快照 + b7.data + (有 HQ? b11 FM-mod : b9 non_shared) + FM 分享(b9,b5) |
| b1 | +856 | **最终输出 B**: += b6 trait.modifier + b8 non_shared + (有 HQ? b12 corps-mod : b10 FM-mod) + FM 分享(b10,b6) + 勋章修正 (char+208 store+32) |
| b2 | +1048 | b1 的缩放副本 (权重@+1220, 系数 v4) |
| b3 | +1240 | b1 的缩放副本 (权重@+1412, 系数 qword_143333338) |
| b4 | +1432 | 快照块 (b4 ← +648 总计器) |
| b5 | +1624 | 快照块 (b5 ← b0.data) |
| b6 | +1816 | ← 每 trait **modifier** (trait+864) |
| b7 | +2008 | ← 每 trait **modifier** (trait+864); 另 += skill(+3680)+16 |
| b8 | +2200 | ← 每 trait **non_shared_modifier** (trait+1056) |
| b9 | +2392 | ← 每 trait **non_shared_modifier** (trait+1056) |
| b10 | +2584 | ← 每 trait **field_marshal_modifier** (trait+1440) |
| b11 | +2776 | ← 每 trait **field_marshal_modifier** (trait+1440) |
| b12 | +2968 | ← 每 trait **corps_commander_modifier** (trait+1248) |
| b13 | +3160 | ← 每 trait **corps_commander_modifier** (trait+1248) |
| b14 | +3352 | b0 输出快照 (name SSO@+3424; RebuildModifiers 名链最后一站) |

表内块锚 = CModifier+16 成员锚, 对象物理基 = 锚−16; 15 块对象阵实际 **+648..+3527** (ctor 0X140C0C2A0 直写 vtable×15), 与 traits@+3528 无缝; 块内「name SSO@+72」即 CModifier+88 (绝对地址两算等价)。army 有 HQ 时 b12/b13 另 += HQ 主将 skill 修正。

#### 4.4.4 FM→general 修正分享与冷却日期组

| 项 | 值 |
|---|---|
| 触发条件 | general 无 cooldown 且 FM (经 HQ obj+440→leader) 无 cooldown |
| general b1 增量 | += FM.b10 / FM.b6 (缩放 qword_143338288 = FM 分享 define) |
| general b0 增量 | += FM.b9 / FM.b5 |

冷却日期物理布局 (组门 u32@+3716≠0 下两对 CGregorianDate):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +3720 | vtable | leader_cooldown_start_date 数据对象 vptr (CGregorianDate) |
| +3728 | uint32 (hours) | leader_cooldown_start_date 叶值 (serializer 0X140533F70 读 hours@this−8) |
| +3736 | vtable | leader_cooldown_start_date 保存视图 vptr (writer/loader 官方寻址点) |
| +3744 | vtable | leader_modifier_enable_date 数据对象 vptr (CGregorianDate) |
| +3752 | uint32 (hours) | leader_modifier_enable_date 叶值 |
| +3760 | vtable | leader_modifier_enable_date 保存视图 vptr (writer/loader 官方寻址点) |

ctor 0X140C0C2A0 写哨兵 43808760 入 +3728/+3752。

#### 4.4.5 CArmyLeader 尾段全字段表 (writer 0X140C28200, vt 0X2955CA8 slot2)

首行调基 writer, 以下为派生尾段。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +3928 | uint32 | attack_skill | 门 ≠0; tok 14537; 实为 16B 元 {skill, pad4, **qword 伴随@+3936 = CUnitLeaderSkill def 指针缓存** (四 setter SetAttack/Defense/Planning/LogisticsSkill — unitleader.cpp assert 实名 — 钳位写技能后缓存 def 指针; 探针 12 对技能值与 def+440 军衔等级全等互证)}; ⚠ COperativeLeader 同偏移是 CSelectable 内 CID 对, 跨类勿混; **GUI: 四技能显示** (CNavyLeaderItem +3944/+3960/+3976/+3992 = attack/defense/planning/logistics 四行, 填充器 sub_141AD21D0; **def+444 = 下级 XP 阈值**; 技能 def DB = qword_14332F0D0, 等级+1, leader_type 查下级技能 def; SKILL_NAVY_LEADER_LEVEL_* loc 族); 技能值存档 = 显示值直存 (无 +1 偏移; writer 0X140C18CA0) |
| +3929..+3943 | 匿名结构 (15B 形状) | = attack 16B 元内部 {pad4@+3932, def 指针@+3936} | SetAttack 0X140C24740 |
| +3944 | uint32 | defense_skill | 门 ≠0; tok 14538; 实为 16B 元 {skill, pad4, qword 伴随@+3952 (伴随 qword = **CUnitLeaderSkill* def 指针缓存** — 六 setter assert 实名)} |
| +3945..+3959 | 匿名结构 (15B 形状) | = defense 16B 元 {pad4, def 指针@+3952} | SetDefense 0X140C25580 |
| +3960 | uint32 | planning_skill | 门 ≠0; tok 14539; 实为 16B 元 {skill, pad4, qword 伴随@+3968 (伴随 qword = **CUnitLeaderSkill* def 指针缓存** — 六 setter assert 实名)} |
| +3961..+3975 | 匿名结构 (15B 形状) | = planning 16B 元 {pad4, def 指针@+3968} | SetPlanning 0X140C26C50 |
| +3976 | uint32 | logistics_skill | 门 ≠0; tok 14540; 实为 16B 元 {skill, pad4, qword 伴随@+3984 (伴随 qword = **CUnitLeaderSkill* def 指针缓存** — 六 setter assert 实名)} |
| +3977..+3991 | 匿名结构 (15B 形状) | = logistics 16B 元 {pad4, def 指针@+3984} | SetLogistics 0X140C260D0 |
| +3992 | int32 | attack_skill_temp_deficit | 门 ≠0; **有符号打印** (锚件 -1/-2 实证); tok 10558 |
| +3996 | int32 | defense_skill_temp_deficit | 门 ≠0; tok 10559 |
| +4000 | int32 | planning_skill_temp_deficit | 门 ≠0; tok 10560 |
| +4004 | int32 | logistics_skill_temp_deficit | 门 ≠0; tok 10561 |
| +4005..+4007 | uint8[3] | (**覆盖行**) = +4004 logistics_skill_temp_deficit i32 的 3 个尾字节, 非独立字段 |  |
| +4008 | CUnitAdjuster 内嵌 (40B) | **attack_skill 修正缓存** (vt 0x142789CD0) | clone 摆 vt |
| +4048 | CUnitAdjuster 内嵌 (40B) | defense_skill 修正缓存 | 同上 |
| +4088 | CUnitAdjuster 内嵌 (40B) | planning_skill 修正缓存 | 同上 |
| +4128 | CUnitAdjuster 内嵌 (40B) | logistics_skill 修正缓存 | 同上 |
| +4168 | uint32 | **Army HQ 引用 CID.type** (FM = 所辖 HQ / general = 所属 HQ, 同字段双向) | Rebuild/Apply 经 sub_14221F310 校验取 HQ 修正 |
| +4172 | uint32 | Army HQ 引用 CID.id | 同上 |
| +4176 | uint32 | pending_reassign_target.type — id 对 (0X142220180, 写序先 id 后 type) | 门 type≠0 ∨ id≠0 **且注册表校验 sub_14221F310 过**; 块键 tok 10301 |
| +4180 | uint32 | pending_reassign_target.id | 同上 |
| +4184 | uint8 | **deploy_army_hq** | 门 ≠0 → yes/no; tok 10283; **语义定案: reassign 请求「部署到 Army HQ」标志** (SetPendingReassignTarget sub_140C26B70 第三参; 与 pending_reassign_target 同写同清; loc LEADER_DEPLOY_PROMPT 锚定) — 非静态驻防态; 现档锚全零仍属潜叶 |
| +4185 | uint8 | captured 组总门 — ① captured yes/no (tok 15636); ② captured_by = tag_id@+4188 >0 引号 tag (tok 15638); ③ location = u32@(*(指针@+4192))+164 (tok 10349, 指针判空) | 门 byte@+4185≠0 |
| +4188 | tag_id (i32) | captured_by | 门 >0 (随组门) |
| +4192 | 匿名结构 (NNB 形状)* | location 载体 — 值 = u32@(*ptr+164) | 随组门, 指针判空 |
| +4200 | uint8 | deployed | 门 byte@+4200≠0 → yes/no (tok 16839) + deployment_cost 同门 |
| +4208 | fixed×1e-5 (i64) | deployment_cost | 门 = +4200 组门; tok 16840 |
| +4209..+4215 | uint8[7] | (**覆盖行**) = +4208 deployment_cost i64 的 7 个尾字节 |  |
| +4216 | CCommandPowerAllocator 内嵌 (56B) | 指挥点分配器 {vt@4216, qword@4224/+4232, 容器@4240..+4271} | clone 实锤 (形态定案) |
| +4272 | 匿名结构 (NNB 形状)* | preferred_tactic 载体 — 值 = u32@(*ptr+152) (getter sub_1406C00D0) | 门仅指针 ≠0 (**0 值也写**); tok 19912 |

#### 4.4.6 CNavyLeader 尾段全字段表 (writer 0X140C283F0, vt 0X2955DC0 slot2)

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +3944 | uint32 | attack_skill | 门 ≠0; tok 14537 |
| +3945..+3959 | 匿名结构 (15B 形状) | = attack 16B 元 {pad4, def 指针@+3952} (navy 伴随指针按 army 同构 setter + dtor 推定, 四 assert 直证 setter 同型) |  |
| +3960 | uint32 | defense_skill | 门 ≠0; tok 14538 |
| +3961..+3975 | 匿名结构 (15B 形状) | = defense 16B 元 {pad4, def 指针@+3968} (同构 army) |  |
| +3976 | uint32 | maneuvering_skill | 门 ≠0; tok 15150 |
| +3977..+3991 | 匿名结构 (15B 形状) | = maneuvering 16B 元 {pad4, def 指针@+3984} | SetManeuvering 0X140C26200 |
| +3992 | uint32 | coordination_skill | 门 ≠0; tok 15151 |
| +3993..+4007 | 匿名结构 (15B 形状) | = coordination 16B 元 {pad4, def 指针@+4000} | SetCoordination 0X140C253B0 |
| +4008 | uint32 | naval_headquarter.type — id 对 (0X142220180) | 门 type≠0 ∨ id≠0 且 sub_14221F310 过; 块键 tok 10193; id≠0 才有叶 (段侧 hqid 门等价) |
| +4012 | uint32 | naval_headquarter.id | 同上 |
| +4016 | int32 | attack_skill_temp_deficit | 门 ≠0; tok 10558 |
| +4020 | int32 | defense_skill_temp_deficit | 门 ≠0; tok 10559 |
| +4024 | int32 | maneuvering_skill_temp_deficit | 门 ≠0; tok 10653 |
| +4028 | int32 | coordination_skill_temp_deficit | 门 ≠0; tok 10709 |
| +4032 | fixed×1e-5 (i64) | penalty — 值 = sub_140C19FA0(leader) 同帧计算, cooldown≠0 时钳 0 | 门 **i64≠-100000 (= fix5 -1.0)**: sub_1424EF6F0 构 -100000 比较后写出; tok 15572; ⚠ 段侧若按恒写复刻, penalty 恰 = -1.0 的将领会多发射 (现档未触发) |

army/navy 互斥由 character.cpp 分派保证 (leader_type 0/1→army writer, 2→navy writer; 段侧以 `lt == 2` 复刻)。captured/deployed/pending_reassign_target/preferred_tactic/deploy_army_hq 仅 army writer 有; penalty/naval_headquarter 仅 navy writer 有。

#### 4.4.7 writer 协议与对象生命周期

| 机制 | 地址 | 说明 |
|---|---|---|
| 共享壳 (vt slot1) | 0X1424BEC50 | 写 `{` → slot2 字段 writer → 写 `}` |
| 多态内嵌块 | 0X1424C2E20 | 加载对偶 0X1424C0AA0 |
| id 对块 (`id = { id type }`) | 0X142220340 | CID 双字段 |
| id 对块 (无键) | 0X142220180 | 写序先 id 后 type |
| id 对块 (带键) | 0X142220260 | 如 `operative = { id type }` |
| u32 通道 | 0X1424C2F40 | 负值按有符号打印 |
| tag 写 | sub_140BB59C0 | 门 *p>0 |
| 加载侧字段分发器 | sub_140C1BEA0 | token switch 与 writer 逐字段互证 |

| 项 | 值 |
|---|---|
| CUnitLeaderBase 子对象 | leader+24; 默认 ctor 0X140C0C2A0; dtor 链 0X140C0D2A0 → 0X140C0D340(a1+24); ctor 形参 = leader_type 初值落 +3708 |
| 文本模式门 | sub_1424BFF30 (CChecksumFile 检查) 支配 name + 五枚条件 SSO + female + portraits 整块; 二进制/checksum 档这些叶不落盘 (文本档不受影响) |

#### 4.4.8 未决项

| 项 | 状态 | 描述 |
|---|---|---|
| pending_reassign_target / naval_headquarter 段侧门 | 定案 (不等价) | writer 门 = 非零 ∧ 三层注册表可解析 (type>4712 / 100..4712 / <100, sub_14221F310; 悬空 id 反例成立); 段仅判非零 → 悬空 id 时段侧多发射; 现档 0-diff 未触发, 遇 MISS_MEM 先查此二处 |
| leader+96 指挥官角色 loc 键名 | 高置信 (已裁) | add_*_commander_role 写 (+128 desc 配对); 见 §4.4.2 +96 行 |
| leader+288 tag_id (ctor 参数3) | 定案 (tag_id 身份; 语义未名) | 「将领修正归属国/原籍国」缓存, writer 不触; 四证 = ctor 参3 / SetPreferredTactic Execute 校验 / 国籍旗 / 特质 tooltip tag 串 (§4.31.43) |
| leader+3624 隐藏引擎容器 | 未决 | 恒空 CPdxArray (探针全量 count 恒 0), 触发条件未知 |
| leader+3784 u8 | 未决 | 独立字节, 语义未名, writer 不触 |
| leader+3808 TNamespacedTrait | 未决 | 推定命名空间键缓存 (纯运行时, writer 全函数不触), 填充时机未采样 |
| leader+409/+410/+411 部署三态字节 | 定案 (基址勘误) | 实为 **COrdersGroup** 的 deployed / deploy_queued / withdrawing — GUI 读取点 sub_14169F350 的对象 v38 = resolve(a1+228) 其 +80/+92/+136/+392 全中 §4.24.3 COrdersGroup; COrdersGroup writer case 16839/10751/16843 三键对偶; vt[26] = 将领冷却天数 |
| char+40 隐藏 SSO #2 | 定案 | 本地化显示名缓存 — 填充点 CCharacter vt[8] sub_140FA43C0 (char+72 name → sub_142245E60 本地化 → char+40); name setter sub_140FA61E0 同步刷新; 与 leader+32→+64 完全同构 (见 §4.4.8 +40 行) |

writer 不触盲区已清 (详见 §4.4.2 对应行): +3616..+3647 = trait_xp_factor alloc + 隐藏引擎容器 / +3696..+3715 = max_traits 双缓存 (+3704..+3707 pad) / +3780..+3807 = +3788 遗留 qword + padding (负定案)。

#### 4.4.9 CCharacterManager 全字段表

`mgr = *(gs + 1704)`。

| 偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +0 | 匿名结构 (元素待裁) 向量 | 恒空容器 {data@+0, count@+12; 8B 元} | 探针 1942.11 档 data=静态哨兵/count=0; 批称 scientist 列表 — 身份待裁 |
| +8 | uint32 | next_id | 角色 id 分配器 (ctor 初值 = 1) |
| +16 | CCharacter* | historical 容器数据指针 |  |
| +17..+27 | 匿名结构 (11B 形状) | = historical 容器 data 尾 (+17..+23) + cap u32@+24 (pdx 24B) | ctor 0X1406B4B20 |
| +28 | u32 | historical 容器计数 |  |
| +29..+39 | 匿名结构 (11B 形状) | = count 尾 (+29..+31) + alloc@+32 (哨兵初值) |  |
| +40 | CCharacter* | dynamic 容器数据指针 |  |
| +41..+51 | 匿名结构 (11B 形状) | = dynamic 容器 data 尾 (+41..+47) + cap u32@+48 |  |
| +52 | u32 | dynamic 容器计数 |  |
| +56..+63 | uint8[8] | ctor 未初始化空洞 | 形态定案, 语义未名 (未决) |
| +64..+159 | 匿名结构 (96B 形状) | = 3 组 [空洞 8B@+64/+96/+128 + MSVC 串组×3 {静态空指针@0, size@+8, u8@+16} + u32@+20 = 常量 1063675494 (位型 ≈0.85f, 与 CVariables+260 同源)]; 运行时命名/索引缓冲, 推定动态角色命名管线 — manager 本体不直接落盘, 角色经国家 characters 块序列化 | ctor 0X1406B4B20 / dtor 0X1406B4DE0; 语义未名 (未决) |

两容器元素均为 CCharacter 指针 (8 字节/项); 合并遍历 = 全部角色 (~1.25 万)。

#### 4.4.10 CCharacter 关键挂载

| 挂载 | 位置 | 布局 | 备注 |
|---|---|---|---|
| portraits | 内嵌@char+120; 容器 {d@char+128, c@char+140} | 元素 56B: ptype u32@0 (0-5 = civilian/army/navy/air/operative/scientist), size u32@4 (0=small 1=large), 路径 MSVC@+16 | **path 空串也写 `""`** (锚件 1,464 叶实证; SL.Q 滤空会整族蒸发) |
| variables | **内嵌@char+216** (CVariables) | 空判 = BB9830 同构 (`u32@+224==1 && u32@+248==0` → 空); RH 桶 0x30 {dist@+4, 名 MSVC@+8, value i64×1e-5@+40} | ⚠ 与 char_extras 同源; 内嵌对象非指针 — 误按 +216 指针解引用且无判空门 = 海量假叶; `^num` 非纯数字后缀键 → `.#N` 序号叶 (与 country.variables 同款) |

#### 4.4.11 CCharacter 全字段表 (304B, vt 0X297EA60, writer 0X140FA6520)

偏移绝对; 引擎落盘序 ≠ 偏移序。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | CID.type (type=73) | 恒写; `id = { id type }` 块 (0X142220340) |
| +12 | uint32 | CID.id | 恒写 (同上) |
| +13..+23 | 匿名结构 (11B 形状) | = CID.id 尾 (+13..+15) + CReferenceObject 簿记首字节 (+16, ctor 清 0; +17..+23 基类余量, writer 不触; 高置信) |  |
| +24 | uint32 | token 角色唯一名 (如 GER_albert_kesselring) | 恒写, 引号 token 名 (sub_1424BC260 + ADF40); tok 19015 |
| +32 | 匿名结构 (NNB 形状) | template — 名 = token u32@(*ptr+8) | 门 ptr≠0; 引号串; tok 19482 |
| +33..+71 | 匿名结构 (39B 形状) | = template 指针尾 (+33..+39) + 显示名缓存 SSO#2 本体 (+40..+71) (ctor 0X140F9EEA0 / writer 0X140FA6520 尺寸直证 **304B**) |  |
| +40 | SSO 串 (32B) | **本地化显示名缓存 #2** (定案: 与 leader+64 同族, 实读显示名与 name token 对应; writer 不序列化) | dtor 完整析构实锤 (存在性定案) |
| +72 | SSO 串 | name | 门 qword@+88≠0 且文本模式; tok 27 |
| +73..+103 | SSO 串本体 (31B) | = name SSO 本体 (+72..+103) |  |
| +104 | tag_id (i32) | country 所属国 | 门 >0 引号 tag (sub_140BB59C0); tok 10394 |
| +108 | tag_id (i32) | nationality 国籍 | 门 >0; tok 19480 (现档零叶) |
| +112 | uint32 枚举 | gender — 0=undefined / 1=male (tok 12775) / 2=female (tok 10773) | **恒写**; 枚举→串 sub_1413F04A0 (其它值 assert "Invalid enum value"); 块键 tok 19481 |
| +120 | CCharacterPortraits 内嵌 | portraits — 容器/元素表见 §4.4.10 | **仅文本模式**整块 (0X1424C2E20); 块键 tok 19497 |
| +121..+151 | 匿名结构 (31B 形状) | = portraits {vt@120 尾 + pdx 24B 容器@128 {d@128, cap@136, c@140, alloc@144}} — 元素 56B 同 §4.4.10 (0X14139DE90 ctor 直证) |  |
| +152 | std::map 头指针 | country_leaders — 节点 {_Left@0, _Parent@8, _Right@16, isnil@+25}, 载荷 CCountryLeader* @node+40; 空载荷写常量 357 (none) | 门 qword@+160≠0; 块键 tok 19973; 后继 sub_1401FF1F0 (中序) |
| +153..+167 | 匿名结构 (15B 形状) | = country_leaders std::map {head@152 尾 + size u64@+160} — ctor malloc 0x30 头哨兵; writer 门 = qword@+160 |  |
| +168 | CUnitLeader* | leader — CArmyLeader/CNavyLeader/COperativeLeader 三选一 (leader_type 判别) | 门 ptr≠0 且 u32@(leader+3708)∈{0,1,2}; 块键 = field_marshal (13538) / corps_commander (13511) / navy_leader (12471); 块体 = 对应派生 writer (§4.4.5 / §4.4.6) |
| +176 | std::map 头指针 | advisors — 载荷 CAdvisor* @node+72 | 门 qword@+184≠0; 块键 tok 19484; 后继同上 |
| +177..+191 | 匿名结构 (15B 形状) | = advisors std::map {head@176, size@184} 同款 |  |
| +192 | CScientist* | scientist (堆) | 门 ptr≠0; 块键 tok 16389 |
| +200 | uint32 | operative 对.type | 任一≠0 才写; `operative = { id type }` (0X142220260); tok 15635 |
| +204 | uint32 | operative 对.id | 同上 |
| +208 | CUnitMedalStore* | unit_medals | 门 = **store≠0 且 (u32@store+12≠0 或 u32@store+608≠0)** (定案); 块键 tok 15870; store 布局见表后注② |
| +216 | CVariables 内嵌 | variables — RH 桶布局见 §4.4.10 | 门 = 非 (u32@+224==1 且 u32@+248==0) (sub_140BC8D50); 块键 tok 10826 |
| +217..+271 | 匿名结构 (55B 形状) | = **CVariables 56B 全形** {vt@216, u32@224 = random 种子#1 (ctor=1; §4.13.2 random 对写形反序 = 存档 `<+228> <+224>`), u32@228 = random 种子#2 ctor 常量 1587985054 (float 位型, 语义未名), pad, 静态空串指针@240, 桶数据指针@248 (ctor=0), u8@256, u32@260=常量 1063675494, 回指指针@264} — 空判 (u32@224==1 && u32@248==0) 与 ctor 初值完全互证 (0X140BC5BD0) |  |
| +272 | CFlagManager | flags — {vt@272, data@280, {cap u32@288, count u32@292}, 静态指针@296}; 元素 48B {key token@+8, date hours u32@+24, value i16@+40, days i16@+42}; 叶 = flags.<名>.value/.date/.days | 门 = i32 计数@+292 >0; 块键 tok 10697 |

表后注② CUnitMedalStore 布局: history 容器 {data@+8, count@+20}, 元 = CUnitMedal*, 叶 `history = { history_queue = <medal ref> }` (tok 10293/12340); +32 勋章修正块 (并入将领 b1, §4.4.3); amount u32@+608, 叶 `amount = N` (tok 417)。

表后注③ writer 0X140FA6520 全函数不触 +456 (该处无字段行)。

⚠ 按 id 查角色需缓存 id→地址 (代际缓存)。

⚠ 每次访问前必须重校验 vtable (引擎会回收复用角色对象)。

char 对象 304B (ctor 直证), 终于 flags 块尾 +303; +320..+328 为对象外 (负定案)。

#### 4.4.12 CSubUnitDefinitionAssociatedModifiers (navy_leader.sub_unit_modifiers)

内嵌@leader+296 (vt 0x142955af0, 288B; 归并 writer 0X141016D10; IsEmpty 0X140643140 = 两容器 count 全 0 则整块不写)。

| 偏移 (leader 绝对) | 类型 | 名称/语义 |
|---|---|---|
| +304 | 匿名结构 (56B) | 容器 A data — stride 56 "units" 数组: {vt(CSubUnitDefinitionId)@0, **key u32@8**, CUnitAdjuster vt@16, dword@24, qword@32/40/48} |
| +305..+315 | 匿名结构 (11B 形状) | = 容器 A {data@304, **cap@312**, count@316, alloc@320} 内部 (pdx 24B; ctor sub_141019140) |
| +316 | u32 | 容器 A count |
| +317..+327 | 匿名结构 (11B 形状) | = 容器 A count 尾 + **alloc@320** |
| +328 | 匿名结构 (208B, 内嵌 CModifier) | 容器 B data — stride 208 修正数组: {pad@0, **key u32@8**, **CModifier 内嵌@+16 (192B)**} |
| +329..+339 | 匿名结构 (11B 形状) | = 容器 B {data@328, **cap@336**, count@340, alloc@344} 内部 (stride 208) |
| +340 | u32 | 容器 B count |

key 解析:

| 项 | 值 |
|---|---|
| key 含义 | sub-unit 定义索引 |
| idx==0 | 键名 "null" |
| idx>0 | db = rp(BASE+53570752) (CGameItemDatabase 单例); arr = rp(db+64); cnt = i32@(db+76); def = rp(arr+8*idx) (越界回退 arr[0]); **token = u32@def+8** → token_name ("destroyer" 等) |
| 归并序 | 两容器按 key 升序归并 (key 相等先 units 后 CModifier; 仅 B 只写 CModifier; 仅 A 只写 units) |

#### 4.4.13 CAdvisorTemplate (advisors.advisor.dynamic_template)

| 项 | 值 |
|---|---|
| 挂载 | advisors.advisor.dynamic_template = **堆指针 rp(adv+32) → CAdvisorTemplate** (非内嵌对象) |
| 判别 | 与 template ref@adv+24 互斥, ref 优先 |
| vtable RVA / sizeof | 0x1429BBA98 / **0x438=1080** (loader/factory malloc 实证) |
| 本体 writer | 0X1413E0350 — **全部叶恒写无 ≠0 门** (obj = rp(adv+32)) |
| ctor | 0X14129DE10 置 0 |
| 堆指针实证 | writer 0X1412A5390 反汇编 `mov r8,[rbx+20h]` |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint8 | 标志 (ctor=1; 语义未名) | 存在性定案 |
| +16 | 匿名结构 (NNB 形状)* | 属主/库回挂 (ctor 置 0; 未名) |  |
| +24 | u32 | ledger | 枚举映射 sub_141528240 (**2=civilian 也写行** — 锚件 2 例落盘; 0xFFFF 规整为 0xFFFFFFFF); PostLoad 按 slot 串补默认 |
| +32 | SSO | idea_token | PostLoad 与 name 互补拷贝 |
| +64 | i32 | idea_token 伴随 hash/缓存 (-1 哨兵) | PostLoad 连带复制 |
| +72 | SSO 串 | **name** | loader tok 27 (定案) |
| +104 | i32 | name 伴随 hash/缓存 (-1) | 高置信 |
| +112 | SSO | slot | loader tok 13378 |
| +144 | i32 | slot 伴随 hash/缓存 (-1) | 高置信 |
| +152 | SSO 串 | **picture** | loader tok 464 (定案) |
| +184 | fixed×1e-5 | cost (ctor=define qword_143338118; PostLoad 默认价覆盖门) | **write-only 镜像** (loader 读弃, 运行时 = 模板重建) |
| +192 | uint8 | **cost 键存在旗** (loader tok 10323 读值即弃后置 1; PostLoad 以此门控 slot=="political_advisor" 默认价覆盖) | 定案 |
| +200 | fixed×1e-5 | removal_cost | write-only 镜像 |
| +208 | uint8 | can_be_fired → yes/no (恒写正逻辑) | write-only 镜像; factory `*(tpl+208)` → advisor+184 直证 |
| +216 | fixed×1e-5 | command_power (ctor=define qword_143338298) | write-only 镜像 |
| +224 | 匿名结构 (40B) | traits 名串数组 {data, cap@232, count@236, alloc@240}, stride 40, 名 SSO@elem+0 | loader tok 12278 增长码 40B 步进直读 |
| +248 | CModifier (192B) | **modifier** (vt@248 内嵌@264) | ctor 实锤; loader tok 10597 → ABB40(+248) |
| +440 | CAndTrigger (88B) | **allowed** | ctor 装 CAndTrigger vt + loader tok 12263 |
| +528 | CAndTrigger (88B) | **available** | tok 12264 |
| +616 | CAndTrigger (88B) | **visible** | tok 11562 |
| +704 | 匿名结构 (64B 形状) | research_bonus 多态元数组 {data@704, count@716} (64B 元工厂 sub_1413DE990; 本档 0 叶) | loader tok 12641 |
| +728 | CMeanTimeToHappen (56B) | **ai_will_do** (ctor 基值 4 天/100000@+24) | tok 10819 |
| +784 | CEffect (88B) | **on_add** | ctor 装 CEffect vt + loader tok 12356 |
| +872 | CEffect (88B) | **on_remove** | tok 14710 |
| +960 | CAndTrigger (88B) | **do_effect** (loader 参 4) | tok 13321 |
| +1048 | SSO | desc | **恒写, 空串也写 `""`** (tok 10644) |

script-only 键 (loader 有案不入存档; dynamic_template 存档叶仅上表恒写族): name / picture / allowed / available / visible / do_effect / on_add / on_remove / ai_will_do。

兼容键 always_show_on_actions_tooltip (10753): loader 读弃, 无字段。

#### 4.4.14 CAdvisor 修正块 (+224 块门三选一与 +416 孪生块)

CModifier 内嵌@**adv+224** (vt 0x1427185f0); 块门 writer 三选一:

| 门分支 | 判别 | 读法 |
|---|---|---|
| ① | i32[adv+360] > 0 (= CModifier+136) | 块写 |
| ② | i32[adv+276] ≠ 0 (= CModifier+52 = 数组B count) | 块写 |
| ③ | 数组A {data@adv+240, count@adv+252, stride 16} 任一条目 def 过类属检查 sub_14055F700 | **引擎精确谓词**: cat = u32[def+104]; 过 = cat==0 或 `(类属掩码 & cat)≠0`; 掩码 = u32@BASE+53571192 = 回调 fnptr@0x33300a0 恒返值 = `M.modifier_category_mask`; 访问器 `M.modifier_category(idx)` |

孪生块注: advisor+416 = **运行时生效修正** (CModifier 192B, writer 盲区; ctor vt@+416 内嵌@+432); 存档序列化块 = +224, 运行时生效 = +416。

RebuildModifiers sub_1412A5030 清 +432 归并 traits (trait+152 修正块), slot8 尾 +432 += +224。

#### 4.4.15 CAdvisor 全字段表 (792B=0x318, vt 0x1429A7D60, writer 0X1412A5390, loader sub_1412A3C70, factory sub_14129ED90)

writer 0X1412A5390 (dump 缺失, vtable slot2 直证)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | slot 名 token 化 id (基类簿记槽) | factory token 化 |
| +16 | CCharacter* | owner 角色回指 | ctor a2 |
| +24 | ref | **advisor 角色条目引用** (→ character template+544 map 条目载荷; 与 +32 互斥, ref 优先) | loader tok 19482 → sub_1413F1AF0(tpl, +128) |
| +32 | ScopedPtr | dynamic_template (CAdvisorTemplate* 0x438) | loader tok 19596 malloc 注入 |
| +40 | uint32 枚举 | ledger | ctor 0; loader tok 10354 |
| +48 | SSO 串 | idea_token {size@64, cap@72} | loader tok 19483 |
| +80 | i32 | idea_token 伴随 hash/缓存 (-1) | 高置信 |
| +88 | SSO 串 | **name** {size@104, cap@112} | factory ← 模板 name getter (定案) |
| +120 | i32 | name 伴随 hash/缓存 (-1) | 高置信 |
| +128 | SSO 串 | slot {size@144, cap@152} | loader tok 13378 |
| +160 | i32 | slot 伴随 hash/缓存 (-1) | 高置信 |
| +168 | fixed×1e-5 | political_power (聘用 PP 基价) | **write-only 镜像** |
| +176 | fixed×1e-5 | removal_cost | write-only 镜像 |
| +184 | uint8 | can_be_fired (默认 1) | write-only 镜像; SetCanBeFired sub_1412A4CD0 |
| +192 | fixed×1e-5 | command_power | write-only 镜像 |
| +200 | 匿名结构 (元素待裁) 向量 | traits 指针数组 {data, cap@208, count@212, alloc@216} (8B 元) | loader tok 12278 去重插入 |
| +224 | CModifier (192B) | **modifier#1 = 脚本/模板修正** (存档序列化块 = 此块) | ctor vt@224 内嵌@240; loader tok 10597 |
| +416 | CModifier (192B) | **modifier#2 = 运行时生效修正** (writer 盲区) | ctor vt@416 内嵌@432; Rebuild sub_1412A5030 归并 traits(trait+152) |
| +608 | 匿名结构 (元素待裁) 向量 | **trait 子对象指针收集器** {data, cap@616, count@620, alloc@624} (8B 元 ← trait+344 的 544B 元数组) | 形态定案, 语义推定 |
| +632 | uint32 | **slot 成本修正 def 索引** (db qword_14333D6E8) | assert "has not generated cost modifier." |
| +640 | SSO 串 | portrait {size@656, cap@664; 仅动态角色序列化} | loader tok 12773 |
| +672 | CCommandPowerAllocator (56B) | 指挥权分配器 {vt@672, 占用标@680, amount@688, name SSO@696} | sub_1412A4E70 写 amount=Σ(trait+424−trait+432); vt 与 CArmyLeader+4216 同型 |
| +728 | SSO 串 | desc loc 键 {size@744, cap@752} | loader tok 10644 |
| +760 | SSO 串 | **desc 解析文本缓存** (writer 盲区) | +728 经 loc 校验解析入 |

#### 4.4.16 CCountryLeader 全字段表 (336B=0x150, vt 0X14297F6C0, writer 0X140FCC690, loader sub_140FCBDA0, factory sub_140FCAF30)

country_leaders map 载荷 @node+40。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CCharacter* | owner 角色回指 | assert "country leader not attached to a character" |
| +16 | SSO 串 | **desc 解析文本缓存** (writer 盲区; size@32, cap@40) | slot8 loc 解析 |
| +48 | SSO 串 | desc loc 键 {size@64, cap@72; tok 10644, 文本模式门} | 定案 |
| +80 | token 向量 | traits 指针数组 {data, cap@88, count@92, alloc@96} (8B 元; tok 12278, token@elem+8) | 定案 |
| +104 | CModifier (192B) | **运行时生效修正块** (writer 盲区; traits(trait+152) 归并; name SSO@+192 ← char 名) | Rebuild sub_140FCC200 |
| +296 | CGameDate vt | expire 日期数据对象 (hours@+304, 哨兵 43808760) | writer 门 +304 ≠ dword_143086B50 |
| +304 | u32 (hours) | expire (tok 12277) | factory ← 模板日期 |
| +312 | CGameDate vt | expire 保存视图 (writer/loader 官方寻址, hours = 视图−8) | §3.7a 视图规则互证 |
| +320 | CIdeology* | ideology def obj (tok 11838 写 idx@obj+8) | loader 校验 *(obj+56); **GUI: ideology_ico 有领袖分支** (party+112/+124 门 → CCountryLeader+320 → +16 SSO 名拼 `GFX_ideology_<名>[_<TAG>]`; sub_140B48C70 复核闭合) |
| +328 | i32 | id (tok 11, ≠-1 门) | **write-only 镜像** (loader AB970 读弃); **有符号域** — 存档实证负值 -2 (黄粱 historical.character[1804]), 读取须 i32 还原 (旧按 u32 直读印 4294967294) |

#### 4.4.17 CScientist 全字段表 (312B=0x138, vt 0x14297EAB8, writer 0X14140CF50, loader sub_14140C3D0)

ctor 内联于 CCharacter loader tok 16389 分支。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CCharacter* | owner 角色回指 | slot8 经它取 char+24 token |
| +16 | SSO 串 | desc loc 键 {size@32, cap@40; tok 10644} | 定案 |
| +48 | token 向量 | traits 指针数组 {data, cap@56, count@60, alloc@64} (8B 元; tok 12278, token@elem+8; 不在库报错 scientist.cpp:86) | 定案 |
| +72 | CModifier (192B) | **运行时生效修正块** (writer 盲区; traits(trait+72) 归并) | Rebuild sub_14140CA30 |
| +264 | 内嵌块 | **skills** {vt@264, data@272, cap@280, count@284, alloc@288}; 32B 元 {spec tok@0, exp i64×1e-5@+16, level i32@+24} | tok 16431 ADEC0 块; AddRole sub_14140CDD0 |
| +296 | 匿名结构 (NNB 形状)* | **模板派生指针** (slot8: 按 char+24 token 查 character template db, *(tpl+16)≠0 则 +296 = *(tpl+568)) | 形态定案, 语义推定 (推定默认 GFX/数据) |
| +304 | uint8 | is_assigned (tok 14427, 仅真才写) | **write-only 镜像** |
| +308 | u32 | is_scientist_injured (tok 10124, >0 门) | write-only 镜像 |

#### 4.4.18 write-only 叶族群

行为定案: loader 单参只读丢弃壳 (ABB10 定点 / ABCA0 布尔 / AB970 整数) 实证下列存档叶**写出不回读**, 加载时由模板/factory 重建。

| 类 | write-only 叶 |
|---|---|
| CAdvisor | political_power / removal_cost / command_power / can_be_fired |
| CAdvisorTemplate | cost / removal_cost / command_power / can_be_fired |
| CCountryLeader | id |
| CScientist | is_assigned / is_scientist_injured |

⚠ 段/export 必须继续发射 (writer 实写), 但 reader 不得据存档值推断运行时值。

#### 4.4.19 CModifier (角色侧内嵌点)

角色侧内嵌点 = advisor.modifier / sub_unit_modifiers 容器B / faction upgrades spymaster+modifier / CUnitLeader 命名修正块阵 b0..b14 (物理基址 leader+648, ctor 0X140C0C2A0 直写 CModifier vtable×15 @subobj+624+192i)。
**CModifier 192B 全布局 + 定义表寻址 + 写门 = §4.3.8 (权威, 勿重述)**。
本侧附加读数: (a) children 容器在本档恒 0 叶; (b) ctor 在本侧 +184 写 **i32 = −1 哨兵** (非类别掩码) → 见 §4.3.8 +184 待裁注。

#### 4.4.20 角色模板族 (CCharacterTemplate / CScientistTemplate / CUnitLeaderTemplate / CUnitLeaderData)

**CCharacterTemplate** (common/characters/*.txt 角色模板, ~584B; vt 0x1429BC9A0; TNullObject vt 0x1427E6258; [2]=CFG 空桩 不入档, [3]=0x1413F1E90 非标准 Load wrapper 变体, [4]=0x1413F1EF0 键值 reader; ctor 0x1413F06A0):

| 偏移 | 类型 | 键/语义 |
|---|---|---|
| +8 | u32 | idb 库配发 id (基 tag 357 被覆盖) |
| +16 | u8 | 有效门 =1 (idb character_template 行「值有效性门 +16」ctor 实证) |
| +24 | std::string 32B | 内部串 (推定调试名) |
| +56 | i32 | 未名 (-1) |
| +64 | std::string | name (27) |
| +96 | std::string | country_leader 槽名暂存 (哈希作 map 键) |
| +128 | u32 | nationality = 国 tag FNV (19480) |
| +132 | i32 | gender (19481: 0/1/2; female=10773→2 / male=12775→1) |
| +136 | bool | generic (12537) |
| +137 | bool | can_be_captured (10665, 默认 1) |
| +144 | 匿名结构 (32B 形状) | portraits (19497) |
| +176 | CTrigger 88B | available (12264) |
| +264 | CTrigger 88B | remove (14530) |
| +352 | CTrigger 88B | allowed_civil_war (13948) |
| +440 | CTrigger 88B | 未名触发器 (推定 allowed 回落) |
| +528 | std::map 节点 0x30 | country_leader 映射 (12341) |
| +544 | std::map 节点 0x50 | advisor 映射 (10454) |
| +560 | CUnitLeaderTemplate* 192B | 角色槽: navy_leader (12471) 追加 / corps_commander (13511) 与 field_marshal (13538) 替换 (ctor 型参 1/2) |
| +568 | CScientistTemplate* 184B | scientist 槽 (16389) |

**CScientistTemplate** (科学家子模板, 184B; vt 0x142765DA0; writer 桩; reader 0x14140D610): +8 bool 有效旗 / +16 traits 容器 (12278) / +40 desc 串 (10644) / +72 skills 子对象 (16431, CPersistent: +80 map) / +96 CTrigger visible 88B (11562)。

**CUnitLeaderTemplate** (将领角色模板, 192B; vt 0x1429C0138; writer 桩; reader 0x141427DC0; ctor 0x141427B90, 断言 ≤2): +8 traits 容器 (12278) / **+32 u32 EUnitLeaderType (0=CorpsCommander/1=FieldMarshal/2=Navy)** / **+36 skill (10453) / +40 attack_skill (14537) / +44 defense_skill (14538) / +48 planning_skill (14539) / +52 logistics_skill (14540) / +56 maneuvering_skill (15150) / +60 coordination_skill (15151)** / +64 legacy_id (19498) / +72 CTrigger visible 88B (11562) / +160 desc 串 (10644)。

**CUnitLeaderData** (内嵌领袖定义块, ~376B; vt 0x14276A620; writer 桩; reader 0x1403B6C70; ctor 0x14032D180; 宿主 = legacy create_*_leader 效果实例 5 工厂 0x14033B910 系, 第二实参 0/1/2 转发): +8 CUnitLeaderTemplate 内嵌 192B / +200 picture (464) / +232 portrait_path (13051) / +264 gfx (12472) / +296 name (27) / +328 desc (10644) / +360 token (19015) / +364 bool female (10773) / +368 i32 id (11)。

> 与运行时 CUnitLeader (§4.4.2, 巨型存档对象) 是不同类: 本族 = 效果定义侧模板数据; 运行时领袖由 CArmyLeader/CNavyLeader/COperativeLeader 承载 (leader_type u32@char+3708 判别)。

#### 4.4.21 特质与科学家等级 (CScientistTrait / CCountryLeaderTrait / CScientistLevel)

**CScientistTrait** (common/scientist_traits 特质条目, ~448B; vt 0x14271B480; writer 桩; reader 0x140AA19F0): +8 id / +32 库键名串 (推定) / +64 i32 (-1) / **+72 CModifier 内嵌 192B (10597)** / +264 name (27) / +296 icon (181) / +328 specialization 集合 (10012) / +352 CTrigger available 88B (12264)。

**CCountryLeaderTrait** (顾问/高指挥特质定义, ~472B; vt 0x1427EA648; writer 桩; reader 0x14071FC50 巨 reader): +8 id / +24 特质名串 / +64 CTrigger available / +168 未名容器 / **+344 targeted_modifier 向量 (14623, 544B 元)** / **+368 equipment_bonus 指针向量 (12647, 元素 CTraitEquipmentBonus 0xA0)** / **+392 ai_strategy 指针向量 (12544, 元素 CAIStrategyReader 0x20)** / +420 sprite token (61) / +424 command_cap_cost (16408) / +432 command_cap_increase (16375) / +440 command_power (14467) / +448 bool random (10171) / +456 ai_will_do 子对象 (10819)。GUI 消费 = §4.31 CCountryLeaderTraitItem 数据源。

**CScientistLevel** (科学家按专长技能等级容器, 32B; vt 0x1429BF088; **唯一实现写槽的类**: writer 0x1414606F0 / reader 0x1414603E0, 入档): 容器 {d@8, cap@16, count@20, alloc@24}, 元素 32B = {spec id u32@0 (= specialization idb def+8), 内嵌 SSkillLevel 24B {vt@+8, u32@+16, u32@+24 推定 = 等级/进度}}; ctor 按 specialization 库 (0x332F068) 全量预填; reader 按 id find-or-append, id 不在库抛 "specialization %s in save file does not match any in DB." (scientist_skill_levels.cpp:120)。

> **本域 GUI 类布局**: 见 4.31.21 / 4.31.36 / 4.31.52 / 4.31.57。
