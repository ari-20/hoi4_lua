

### 4.4 CCharacterManager / CCharacter / CUnitLeader 派生族 (角色族)

#### 4.4.1 类身份与 writer 绑定

RTTI 定案。

| 类 | vtable RVA | slot2 (=Save 本体) | 说明 |
|---|---|---|---|
| CCharacter | 0X297EA60 | 0X140FA6520 | 基类 CReferenceObject(+0) ← CPersistent; 非多用 |
| CUnitLeader | 0X2955B90 | _purecall (0X14253C3B8) | **抽象**: SerializeBody 纯虚, 无直接实例 writer |
| CArmyLeader | 0X2955CA8 | 0X140C28200 | 首行调基 writer 0X140C1CE70 |
| CNavyLeader | 0X2955DC0 | 0X140C283F0 | 同上 |
| COperativeLeader | 0X2955F00 | 0X140C28550 | 特有区字段表 = §4.11 |

谱系 (RTTI 直读):

| 类 | RTTI 基对象布局 |
|---|---|
| CUnitLeader | CUnitLeaderBase@mdisp24 + CReferenceObject@0 + CPersistent@0 + CUnitLeader::TNamespacedTrait@3808 |
| CNavyLeader | 上行 + CCustomizableBuildingListener@3928 |
| COperativeLeader | 上行 + CSelectable@3928 + COperativeLeaderBase@3944 |

char+168 leader 指向对象 = CArmyLeader/CNavyLeader/COperativeLeader 三选一, 由 leader_type u32@+3708 判别 (character.cpp writer switch):

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
| +13..+31 | 匿名结构 (19B 形状) | = CID.id 尾 (+13..+15) + CReferenceObject 簿记 (+16..+23, ctor 清首字节) + **CUnitLeaderTemplate\* 模板回指 (+24..+31)** | ⚠ 定案: +24 非 vptr — 基 ctor 清 0 / 领袖工厂 sub_140C14160 步3 写模板指针 / army 单 vftable@+0、navy 双 vftable@+0,+3928 三证; CUnitLeaderBase 子对象基 ctor 0X140C0C2A0 的 a1 = leader+24, 其内偏移须 +24 才是 leader 绝对值; dtor 链 0X140C0D340(a1+24); ctor 0X140C0C200 |
| +16 | uint64 | CReferenceObject 基类簿记 (引用计数/池链接族) | char dtor 收尾链直证 |
| +32 | SSO 串 | name | 门 qword@+48≠0 且文本模式; 引号串; tok 27 |
| +33..+63 | SSO 串本体 (31B) | = name SSO 32B 本体 (+32..+63; ctor 8 连 SSO 初始化 / dtor 8 连 free) |  |
| +64 | SSO 串 (32B) | **本地化显示名缓存** (定案: 实读「乔治·卡特利特·马歇尔」与 name token 严格对应; RebuildModifiers 复制进全部 15 个修正块的 name@+72 — sub_140C21FC0 链式 assign) | GUI 消费见表后注① |
| +65..+95 | SSO 串本体 (31B) | = 显示名缓存 SSO 本体 (+64..+95) |  |
| +96 | SSO 串 (32B) | **desc 键 (+128) 的本地化解析缓存** (sub_140C257E0: 载荷串先拷 +128 (tok 10644), 过 loc 键校验则本地化结果写 +96, 不过清空) | 定案 |
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
| +584 | CUnitAdjuster 向量 | **per-skill 数组** (40B 元; 引擎名 **_TerrainAdjusters** assert 实名; 下标域待裁: 聚合器 sub_140C0FB70 键空间联动判 sub-unit 定义索引 (高置信) vs CUnitLeaderSkill 库内索引, 两说并陈) | RecalcSkillBonuses sub_140C21280 重建; getter sub_140C19C40 (越界回 0 号) |
| +596 | uint32 | +584 数组 count | 定案 |
| +600 | uint32 | +584 数组 alloc (= &off_143085170 静态哨兵初值) | pdx 24B {data@584, cap@592, count@596, alloc@600} (ctor 增长码) |
| +608 | CUnitAdjuster | **CUnitAdjuster 总计器** (全 trait×skill 加成总和) {vtable@608, q@624/632/640 ctor 清零}; 与 +648 阵列无缝 | sub_140C0FB70 聚合; ctor 0X140C0C2A0 |
| +648..+3527 | CModifier* | **命名修正块阵 b0..b14** — 物理基址 = leader+648 (ctor 0X140C0C2A0 直写 CModifier vtable×15 @subobj+624+192i; dtor 对成员@+640+192i 清理 15 次; RebuildModifiers 0X140C21FC0 名 assign 目标 928/1120/…/3424 = 648+192i+88 全命中); 块内 name SSO = CModifier+88; 阵列终于 +3527 与 traits@+3528 无缝; 块分工见 §4.4.3, 通用布局见 §4.3.8 | ctor + dtor + RebuildModifiers 三证 |
| +3528 | CUnitLeaderTrait* | traits — 元素 8B 指针, 叶名 = token u32@(trait+8); 裸列表 (无花括号, 分隔 token 18 空格); trait 对象内: +56 有效门 (replace 显式旧特质分支读) / +1740 事件门 / +2680 修正引用清单 {data, count@+2692, 16B 元, add/remove 聚合扣账} (均推定) | 门 计数@+3540≠0; tok 12278 |
| +3529..+3539 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3540 | uint32 | traits 容器计数 |  |
| +3541..+3551 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3544..+3615 | 匿名结构 (72B 形状) | = traits 容器 alloc (+3544..+3551) + traits_to_remove 容器全体 (+3552..+3575) + in_progress 容器全体 (+3576..+3599) + trait_xp_factor 容器头 (+3600..+3615) | ctor/dtor 5 连容器 |
| +3552 | 匿名结构 (16B 形状)* | traits_to_remove — 元 {trait 指针@0, **剩余天数 u32@+8** (timed trait 移除时钟; leaders.daily 倒计时收割)}; `{ }` 块 | 门 计数@+3564≠0; tok 14697 |
| +3553..+3563 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3564 | uint32 | traits_to_remove 容器计数 |  |
| +3565..+3575 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3576 | 匿名结构 (16B 形状)* | in_progress — 元 {trait 指针@0, i64×1e-5@+8}; 键 = trait token; **逐条恒写含 0 值**; 累进 = GainXpForTraits sub_140C14BD0 (§4.4.22), 阈值 = 100000×trait+2208 (cost) | 门 计数@+3588≠0; tok 12359 |
| +3577..+3587 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3588 | uint32 | in_progress 容器计数 |  |
| +3589..+3599 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3600 | 匿名结构 (16B 形状)* | trait_xp_factor — 元 {trait 指针@0, i64×1e-5@+8}; **特质修正聚合表 (定案)** — XP 增益读者 sub_140C14BD0 对 in_progress (+3576) 逐特质查值累进, 另按 leader+288 国的 country+1464 修正表取系数 | 门 计数@+3612≠0; tok 14791 |
| +3601..+3611 | 匿名结构 (11B 形状) | 所在 pdx 24B 容器内部 (data 尾/cap@+8 或 count 尾/alloc@+16 = &off_143085170 哨兵初值; ctor 5 连 sub_14011DF40 + dtor 5 连关闭) |  |
| +3612 | uint32 | trait_xp_factor 容器计数 |  |
| +3613..+3647 | 匿名结构 (35B 形状) | = trait_xp_factor {cap 尾@3613..3615, alloc@3616..3623} + **第 5 个 24B pdx 容器 (raw+3624..+3647, 死字段)** |  |
| +3616 | CPdxNewDeleteAllocator* | trait_xp_factor 容器 allocator | dtor 释放 |
| +3624 | 匿名结构 (NNB 形状) 向量 24B | **第 5 个 pdx 容器 {data@3624, cap@3632, count@3636, alloc@3640} — 真死字段 (负定案, 定案)**: ctor/copy ctor/dtor 三段闭环 (ctor 连调 5 次 sub_14011DF40 → raw+3528/3552/3576/3600/3624; dtor 逆序释放; copy ctor sub_140C1B810 整容器拷贝), 但 writer 只发射 4 容器 (+3540/+3564/+3588/+3612) 且全 dump 零写入点/零消费者 | 不序列化 |
| +3641..+3695 | 匿名结构 (55B 形状) | (**覆盖行**, 定案: 与 +3613..+3647 及 +3648/+3680/+3688 单列行逐字节重合, 无独立信息) |  |
| +3648 | SSO 串 | link | 门 qword@+3664≠0; tok 14790 |
| +3649..+3679 | SSO 串本体 (31B) | = link SSO 32B 本体 (+3648..+3679; ctor 清空 / dtor free) |  |
| +3680 | CUnitLeaderSkill* | skill 对象指针 — 叶值 = u32@(*ptr+440) (军衔等级) | **恒写, 指针无判空门** (直接解引用); tok 10453 |
| +3688 | fixed×1e-5 (int64) | experience 经验 | 门 ≠0; tok 11930 |
| +3689..+3711 | 匿名结构 (23B 形状) | = experience 尾 + **max_traits 缓存①②** (+3696 i32 ctor=0 / +3700 i32 ctor=−1 未算哨兵) + **海战计数@+3704** + **leader_type@+3708** (ctor 参数2; 3 = operative (推定); **dtor 置 4** = destructed 哨兵勿入合法域; **GUI: 将领类型判别显示** — CNavyLeaderItem/TraitWindow 命中, 2=navy_leader) + female 哨兵对 (+3712/3713) |  |
| +3696 | int32 | **max_traits 缓存①** (corps/FM define 基值 + 修正 0x15F) | sub_140C21D30 写, getter sub_140C18790 |
| +3700 | int32 | **max_traits 缓存②** (基值 + 修正 0x160; HQ 条件下再缩放) | getter sub_140C186D0 |
| +3704 | uint32 | **将领进行中海战计数** (定案: CNavalCombatant 参战将领数组选拔链读取) |  |
| +3708..+3767 | 匿名结构 (60B 形状) | = **leader_type u32@+3708** (ctor 参数2; dtor 置 4 哨兵) + **female 0xAA 哨兵对** {u8@3712 = 0xAA, 写门 u8@3713} (ctor WORD@3712=0x00AA; 门开才落盘; dtor 门@3713≠0 复位 0x00AA) + cooldown 组总门@3716 + 冷却起始日期对 {vtable@3720, hours@3728, 视图@3736} + 修正启用日期对 {vtable@3744, hours@3752, 视图@3760}; 与 +3712/+3713/+3716 单列行重叠 | ctor/dtor 复位闭环 |
| +3712 | uint8 | female 值 | 门 byte@+3713≠0 → yes/no; 文本模式门; tok 10773 |
| +3713 | uint8 | female 写门 |  |
| +3716 | uint32 | cooldown 组总门 — ① cooldown_reason = 枚举→引号串 sub_140C12910 (0=no_cooldown / 1=reassigned / 2=harmed / 3=forced_into_hiding / 4=deployed / 5=withdrawing; tok 19226); ② leader_modifier_enable_date (tok 14723, 日期对@+3744/+3752, 视图 vptr@+3760); ③ leader_cooldown_start_date (tok 19458, 日期对@+3720/+3728, 视图 vptr@+3736) | 门 u32@+3716≠0; 日期对布局见 §4.4.4 |
| +3717..+3775 | 匿名结构 (59B 形状) | (**覆盖行** 与 +3708..+3767 行重合, 且其 +3768 划入日期区与脏标记实证冲突) |  |
| +3768 | uint8 | **修正重建脏标记** (RebuildModifiers 尾清 0; SetLeaderType/FM 刷新/勋章流均清) | 13 处清零命中 |
| +3769..+3787 | 匿名结构 (19B 形状) | = 修正重建脏标记区尾 + ctor 清零 pad (含 **+3784 u8 = loader trait 列表「免排序」开关**: 真=追加去重 sub_140C0EC40 / 假=二分有序插入 sub_1401B14F0; ctor 清零为族内唯一写点, copy ctor 恰跳过 → **永不置位残留旗**); 与 +3776 行重叠 |  |
| +3776 | fixed×1e-5 (int64) | max_traits | 门 ≠0; tok 14576 |
| +3777..+3795 | 匿名结构 (19B 形状) | = max_traits 尾 + ctor 清零 pad (含 +3784 u8 免排序开关, 见上行); 与 +3788 行重叠 |  |
| +3788 | uint64 | **已见特质数** (terrain 类 AddTrait 递减下限 0; CUpdateLeaderSeenTraitsCountCommand 直写; GUI 新特质红点源) | 定案 |
| +3789..+3795 | 匿名结构 (7B 形状) | = +3788 遗留 qword 尾 (+3789..+3795) + pad |  |
| +3796 | tag_id (int32) | government_in_exile_tag | 门 >0 引号 tag; tok 15034 |
| +3800 | int32 | legacy_id | 门 ≠-1 (0xFFFFFFFF); tok 19498; **有符号域** — 存档实证负值 -2/-3412 (PB:LOM), 读取须 i32 还原 (同 CCountryLeader+328 id 族); mem 恒 0 (reader 推定不回填 — 存档值仅存档侧可见) |
| +3804 | uint8 | promoted_from_unit | 门 ≠0 → yes/no; tok 17869 |
| +3805..+3839 | 匿名结构 (35B 形状) | = pad (+3805..+3807) + **CUnitLeader::TNamespacedTrait 本体 = 32B std::string (SSO) 死成员** (+3808..+3839; buf@3808 / size@3824 / cap@3832=15; ctor 建空串 + dtor 完整 SSO 析构闭环, **全 dump 零赋值点 → 负定案**; RTTI 谱系列基类@3808 见 §4.4.1) |  |
| +3840 | CDynamicModifierContainer 内嵌 (72B) | dynamic_modifier | 门 u32@+3892≠0 (sub_14060D020); tok 15361; 块体展开见下方子表 |
| +3841..+3911 | 匿名结构 (71B 形状) | = dynamic_modifier 72B 块体 (+3840..+3911, 见下方子表); dtor sub_140549F40 |  |
| +3912 | uint32 | **owner CCharacter 回指 CID.type** (leader→character; loader tok 10697 转发 CCharacter loader) | SetOwnerCharacter sub_140C24C70; **GUI: 将领条目 owner 显示链** (CNavyLeaderItem 命中) |
| +3916 | uint32 | owner CCharacter 回指 CID.id | 同上 |
| +3920 | uint8 | character template 存在缓存 (= *(char+32)!=0) | sub_140C24C70 |
| +3921..+3923 | 匿名结构 (3B 形状) | = +3920 u8 尾 pad (ctor 清零) |  |
| +3924 | uint32 | script_id (**引擎名 _UnitLeaderIndexInGameState** — gs+1040 全局 unit-leader 注册表下标, 写入器 sub_140C275E0 debug 门 assert 直证) | 门 ≠0; tok 19349 |

表后注① GUI 消费 (leader+64 显示名缓存): Badge 将领技能/名 + ListView 部署 tooltip — sub_140C15500 攻击技能; loc 键 LEADER_SKILL_DESC / UNIT_LEADER_NO_LEADER / LEADER_DEPLOY_* / LEADER_COMING / LEADER_WITHDRAWING; 部署三态字节 = **COrdersGroup+409 deployed / +410 deploy_queued / +411 withdrawing** (⚠ 本组字节曾按 leader 基址登记, 实为 COrdersGroup 基址 — 读取点对象为 COrdersGroup; 见 §4.4.8); vtable[26] = 将领冷却剩余天数 `(23 − 今日 + enable_date)/24`。

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
| +40 | 匿名结构 (NNB 形状) 向量 | values {data@+40, cap@+48, count@+52 = def+452} |

序列化形 `modifier/value[.#N]/enabled` (锚件 1826 叶实证; 效果类锚 CAddRemoveDynamicModifierEffect::Execute 0x1403efa30)。

#### 4.4.3 CUnitLeader 命名修正阵 b0..b14

trait 四类修正源 = modifier (trait+864) / non_shared_modifier (trait+1056) / corps_commander_modifier (trait+1248) / field_marshal_modifier (trait+1440) (tok 10597/14886/14690/14691); 归并链 = trait loader sub_140AEBC20 token switch + RebuildModifiers sub_140C21FC0 归并 + ApplyModifiers sub_140C21570 输出 (定案)。

| 块 | 块锚 (= CModifier+16 成员基; 对象物理基 = 锚−16) | 来源/用途 |
|---|---|---|
| b0 | +664 | **最终输出 A (军级 corps)**: += b6 trait.modifier + b8 non_shared + (有 HQ? b12 corps-mod : b10 FM-mod) + FM 分享 (FM.b10×v35 + FM.b6×v35×qword_143338288/1e5); 快照输出 → b4 |
| b1 | +856 | **最终输出 B (元帅 FM)**: += b7 trait.modifier 聚合 + b9 non_shared 聚合 + 勋章修正 (char+208 store+32) + (有 HQ 且 HQ+57 假? b11 FM-mod : b13 corps-mod) + FM 分享 (FM.b11×v35 + FM.b7×v35×qword_143338288/1e5) |
| b2 | +1048 | b1 的缩放副本 (权重@+1220, 系数 v4) |
| b3 | +1240 | b1 的缩放副本 (权重@+1412, 系数 qword_143333338) |
| b4 | +1432 | 快照块 (b4 ← b0 块, src 648) |
| b5 | +1624 | 快照块 (b5 ← b1 块, src 840) |
| b6 | +1816 | ← 每 trait **modifier** (trait+864) |
| b7 | +2008 | ← 每 trait **modifier** (trait+864); 另 += skill(+3680)+16 |
| b8 | +2200 | ← 每 trait **non_shared_modifier** (trait+1056) |
| b9 | +2392 | ← 每 trait **non_shared_modifier** (trait+1056) |
| b10 | +2584 | ← 每 trait **field_marshal_modifier** (trait+1440) |
| b11 | +2776 | ← 每 trait **field_marshal_modifier** (trait+1440) |
| b12 | +2968 | ← 每 trait **corps_commander_modifier** (trait+1248) |
| b13 | +3160 | ← 每 trait **corps_commander_modifier** (trait+1248) |
| b14 | +3352 | b1 输出快照 (name SSO@+3424; RebuildModifiers 名链最后一站) |

表内块锚 = CModifier+16 成员锚, 对象物理基 = 锚−16; 15 块对象阵实际 **+648..+3527** (ctor 0X140C0C2A0 直写 vtable×15), 与 traits@+3528 无缝; 块内「name SSO@+72」即 CModifier+88 (绝对地址两算等价)。army 有 HQ 时 b12/b13 另 += HQ 主将 skill 修正。

#### 4.4.4 FM→general 修正分享与冷却日期组

| 项 | 值 |
|---|---|
| 触发条件 | general 无 cooldown 且 FM (经 HQ obj+440→leader) 无 cooldown |
| general b0 增量 | += FM.b10×v35 + FM.b6×v35×qword_143338288/1e5 (sub_140C21570 / sub_140C19AC0 双站点) |
| general b1 增量 | += FM.b11×v35 + FM.b7×v35×qword_143338288/1e5 (qword_143338288 = FM 分享 define) |

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

#### 4.4.5 CArmyLeader 尾段全字段表 (writer 0X140C28200, vtable 0X2955CA8 slot2; vtable[18] = 0x140C10A10 FM 分享权重计算 / vtable[15] = sub_140C16C90 FM HQ 下辖 general 数 getter u32@HQ+572)

首行调基 writer, 以下为派生尾段。

**技能 setter 八件套 commit 三连**: 陆军攻/防/计/后 = sub_140C24740/25580/26C50/260D0 (+3928/+3944/+3960/+3976) + 海军攻/防/机/协 = sub_140C24870/256B0/26200/253B0 (+3944/+3960/+3976/+3992), 同构骨架 = deficit = min(value−1, 0) → skill = max(value, 1) → 上限钳 (cap = 型 getter −1) → def 查写伴随槽 → commit 时 **sub_140C21FC0 (RebuildModifiers) → vtable[28] (vtable+224) RecalcSkillBonuses → 清脏 +3768 = 0** 三连 (书原只记 RebuildModifiers 一步; 与 §4.4.22 日更⑤三连同形); cap getter 六件 sub_140AE94F0/9510/9540/9520/9530/9500 与 def 查找六件 sub_140AE7D60/AE7FB0/AE96A0/AE8090/AE80B0/AE7D80 配对逐位互证 (海军攻/防与陆军共用 — 七梯库按 +24×leader_type 寻梯)。部署/撤收冷却发起 = sub_140C1EA90 (reason 4) / sub_140C20060 (reason 5): 门 leader_type > 1 "Tried to deploy a non-General" (:3187) + HQ 空/未指派 (:3195), 天数源 = sub_140BEF400(HQ)+400 → sub_1415B0030/B01D0; 返 1 = 天数 ≤ 0 无冷却直进, 返 0 = 已进冷却。冷却延长 sub_140C22B60: **enable(+3752) = start(+3728) + scaled** (先直写 start 值再经 +3744 视图 AddDays); SetCooldown days ≤ 0 只复位 enable+reason, **start 不触**。operative 捕获迁移 sub_140C24AC0 旧态清理矩阵: state 0→清对+日志 "released" / 1→"cooldown" / 4→"operation" / 3→清 mission 容器 / **2 (disbanded), 5 (killed) 无动作**; capture_date +4032 ← *(date+8)。debug 断言门按源码区段分双字节: 冷却族 byte_1435E1B51 / setter 族 byte_1435E1B52。

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
| +4008 | CUnitAdjuster 内嵌 (40B) | **attack_skill 修正缓存** (vtable 0x142789CD0) | clone 摆 vtable |
| +4048 | CUnitAdjuster 内嵌 (40B) | defense_skill 修正缓存 | 同上 |
| +4088 | CUnitAdjuster 内嵌 (40B) | planning_skill 修正缓存 | 同上 |
| +4128 | CUnitAdjuster 内嵌 (40B) | logistics_skill 修正缓存 | 同上 |
| +4168 | uint32 | **Army HQ 引用 CID.type** (FM = 所辖 HQ / general = 所属 HQ, 同字段双向) | Rebuild/Apply 经 sub_14221F310 校验取 HQ 修正 |
| +4172 | uint32 | Army HQ 引用 CID.id | 同上 |
| +4176 | uint32 | pending_reassign_target.type — id 对 (0X142220180, 写序先 id 后 type) | 门 type≠0 ∨ id≠0 **且注册表校验 sub_14221F310 过**; 块键 tok 10301 |
| +4180 | uint32 | pending_reassign_target.id | 同上 |
| +4184 | uint8 | **deploy_army_hq** | 门 ≠0 → yes/no; tok 10283; **语义定案: reassign 请求「部署到 Army HQ」标志** (SetPendingReassignTarget sub_140C26B70 第三参; 与 pending_reassign_target 同写同清; loc LEADER_DEPLOY_PROMPT 锚定) — 非静态驻防态; 现档锚全零仍属潜叶 |
| +4185 | uint8 | captured 组总门 — ① captured yes/no (tok 15636); ② captured_by = tag_id@+4188 >0 引号 tag (tok 15638); ③ location = u32@(*(指针@+4192))+164 (tok 10349, 指针判空) — **派生类边界: 仅 CArmyLeader/COperativeLeader 形态; CNavyLeader+3928 起为 CCustomizableBuildingListener 子对象, +4188 = listener+260 属其内字段非 captured_by (活体: 本档被俘 0 例, NAVY 三例 +4188 非零全系该字段假阳性)** | 门 byte@+4185≠0 |
| +4188 | tag_id (int32) | captured_by | 门 >0 (随组门); 同上行派生类边界 |
| +4192 | 匿名结构 (NNB 形状)* | location 载体 — 值 = u32@(*ptr+164) | 随组门, 指针判空 |
| +4200 | uint8 | deployed | 门 byte@+4200≠0 → yes/no (tok 16839) + deployment_cost 同门 |
| +4208 | fixed×1e-5 (int64) | deployment_cost | 门 = +4200 组门; tok 16840 |
| +4209..+4215 | uint8[7] | (**覆盖行**) = +4208 deployment_cost i64 的 7 个尾字节 |  |
| +4216 | CCommandPowerAllocator 内嵌 (56B) | 指挥点分配器 {vtable@4216, qword@4224/+4232, 容器@4240..+4271} | clone 直证 (形态定案) |
| +4272 | 匿名结构 (NNB 形状)* | preferred_tactic 载体 — 值 = u32@(*ptr+152) (getter sub_1406C00D0) | 门仅指针 ≠0 (**0 值也写**); tok 19912 |

#### 4.4.6 CNavyLeader 尾段全字段表 (writer 0X140C283F0, vtable 0X2955DC0 slot2)

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +3944 | uint32 | attack_skill | 门 ≠0; tok 14537 |
| +3945..+3959 | 匿名结构 (15B 形状) | = attack 16B 元 {pad4, def 指针@+3952} (navy 伴随指针 setter sub_140C24870/sub_140C256B0 带 pAttackSkill/pDefenseSkill assert 实名直写 +3952/+3968, 定案) |  |
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
| +4032 | fixed×1e-5 (int64) | penalty — 值 = sub_140C19FA0(leader) 同帧计算, cooldown≠0 时钳 0 | 门 **i64≠-100000 (= fix5 -1.0)**: sub_1424EF6F0 构 -100000 比较后写出; tok 15572; ⚠ 段侧若按恒写复刻, penalty 恰 = -1.0 的将领会多发射 (现档未触发) |

army/navy 互斥由 character.cpp 分派保证 (leader_type 0/1→army writer, 2→navy writer; 段侧以 `lt == 2` 复刻)。captured/deployed/pending_reassign_target/preferred_tactic/deploy_army_hq 仅 army writer 有; penalty/naval_headquarter 仅 navy writer 有。

#### 4.4.7 writer 协议与对象生命周期

| 机制 | 地址 | 说明 |
|---|---|---|
| 共享壳 (vtable slot1) | 0X1424BEC50 | 写 `{` → slot2 字段 writer → 写 `}` |
| 多态内嵌块 | 0X1424C2E20 | 加载对偶 0X1424C0AA0 |
| id 对块 (`id = { id type }`) | 0X142220340 | CID 双字段 |
| id 对块 (无键) | 0X142220180 | 写序先 id 后 type |
| id 对块 (带键) | 0X142220260 | 如 `operative = { id type }` |
| u32 通道 | 0X1424C2F40 | 负值按有符号打印 |
| tag 写 | sub_140BB59C0 | 门 *p>0 |
| 加载侧字段分发器 | sub_140C1BEA0 | token switch 与 writer 逐字段互证 |

| 项 | 值 |
|---|---|
| CUnitLeaderBase 子对象 | leader+24; 默认 ctor 0X140C0C2A0; dtor 链 0X140C0D2A0 → 0X140C0D340(a1+24); ctor 形参 = leader_type 初值落 +3708; **首 8B (+24..+31) = CUnitLeaderTemplate\* 模板回指 (非 vptr, 领袖工厂写入 — 见 +24 行定案)** |
| 文本模式门 | sub_1424BFF30 (CChecksumFile 检查) 支配 name + 五枚条件 SSO + female + portraits 整块; 二进制/checksum 档这些叶不落盘 (文本档不受影响) |

#### 4.4.8 未决项

| 项 | 状态 | 描述 |
|---|---|---|
| pending_reassign_target / naval_headquarter 段侧门 | 定案 (不等价) | writer 门 = 非零 ∧ 三层注册表可解析 (type>4712 / 100..4712 / <100, sub_14221F310; 悬空 id 反例成立); 段仅判非零 → 悬空 id 时段侧多发射; 现档 0-diff 未触发, 遇 MISS_MEM 先查此二处 |
| leader+96 指挥官角色串 | 定案 | **desc 键 (+128) 的本地化解析缓存** — 写点 sub_140C257E0: 效果载荷串先拷 leader+128 (desc 键, tok 10644) → 过 loc 键校验则本地化结果写 +96, 不过则清空; 见 §4.4.2 +96 行 |
| leader+288 tag_id (ctor 参数3) | 定案 | **归属国 tag**; vtable[21] = SetOwnerCountry 虚槽 — army/navy 版 0x140C25570 纯 setter / **operative 版 0x140C254E0 换国即清 operation 对 (+3968) 与 mission optional (+3976/+4008) + GUI 通知** (特工换国 = 行动/任务全弃); 上游 = CCharacter::SetCountry sub_140FA6170 (char+104 同步传播); 读者链全部按该国取修正 (0x140C15140 任命成本 / 0x140C14BD0 XP 计速 / 0x140C21FC0 RebuildModifiers 等) |
| leader+3624 隐藏引擎容器 | 定案 (负) | **触发条件不存在** — 全 dump 穷举零追加点 (生命周期仅 ctor/copy/dtor; loader/writer 不触) = 恒空死容器 |
| leader+3784 u8 | 定案 | **loader trait 追加排序开关** (真 → 追加去重 / 假 → 二分有序插入 sub_1401B14F0; 参与对象校验和权重 1); 全 dump 无置位点 (唯一写 = ctor 清零), copy 会拷 — 恒 0, loader 恒走二分分支 |
| leader+3808 TNamespacedTrait | 定案 (负) | mixin 全域废置 — 仅 CUnitLeader 族 + CEvent@+32 持有, 双证零赋值 (copy ctor 不拷, 拷贝终于 base+3780); 填充时机不存在, 与 §4.4.2 负定案注一致 |
| leader+409/+410/+411 部署三态字节 | 定案 | 实为 **COrdersGroup** 的 deployed / deploy_queued / withdrawing — GUI 读取点 sub_14169F350 的对象 v38 = resolve(a1+228) 其 +80/+92/+136/+392 全中 §4.24.3 COrdersGroup; COrdersGroup writer case 16839/10751/16843 三键对偶; vtable[26] = 将领冷却天数 |
| char+40 隐藏 SSO #2 | 定案 | 本地化显示名缓存 — 填充点 CCharacter vtable[8] sub_140FA43C0 (char+72 name → sub_142245E60 本地化 → char+40); name setter sub_140FA61E0 同步刷新; 与 leader+32→+64 完全同构 (见 §4.4.8 +40 行) |

writer 不触盲区已清 (详见 §4.4.2 对应行): +3616..+3647 = trait_xp_factor alloc + 隐藏引擎容器 / +3696..+3715 = max_traits 双缓存 (+3704..+3707 pad) / +3780..+3807 = +3788 遗留 qword + padding (负定案)。

#### 4.4.9 CCharacterManager 全字段表

`mgr = *(gs + 1704)`。

| 偏移 | 类型 | 名称 | 语义 |
|---|---|---|---|
| +0 | vtable | CCharacterManager (vtable 0x1427e5d30; sizeof 160B; writer vtable[2] 0x1406BACB0 / loader vtable[4] 0x1406BA1C0 / Load 壳 vtable[3] 0x1406B9BB0 载入前清两容器与三图) | 旧「+0 恒空容器」系 vtable+next_id 误读 (负定案) |
| +8 | uint32 | next_id (键 19495 next_character_id; 写者 = 新局批产 sub_1406B97D0 + generate_character 效果 Execute 0x140357BE0 → sub_1406B7510 + **随机创建双路 sub_1406B8060/sub_1406B82A0** [CID 派发点各 ++ 一次, character_manager 批补录] + **复制双路 sub_1406B7140/sub_1406B71D0** (两函体首 `v3=*(mgr+8); *(mgr+8)=v3+1`, 以 {73, v3} 组 CID — character.cpp 批补录]) | 角色 id 分配器 (ctor 初值 = 1) |
| +16 | CCharacter* | historical 容器数据指针 (键 12322; 元素键 19478 character, null assert) |  |
| +17..+27 | 匿名结构 (11B 形状) | = historical 容器 data 尾 (+17..+23) + cap u32@+24 (pdx 24B) | ctor 0X1406B4B20 |
| +28 | uint32 | historical 容器计数 |  |
| +29..+39 | 匿名结构 (11B 形状) | = count 尾 (+29..+31) + alloc@+32 (哨兵初值) |  |
| +40 | CCharacter* | dynamic 容器数据指针 (键 13075; **分野四族**: 批产按模板 +577 u8 旗判定 / generate_character 效果路恒 +16 historical / 随机生成路 [8060/82A0] 恒 +40 dynamic / **角色复制双路 [7140/71D0] 恒 +16 historical** (两函均 sub_1406B2A10(mgr+16, &Block), 71D0 以 mgr+28 计数回读末元素)) |  |
| +41..+51 | 匿名结构 (11B 形状) | = dynamic 容器 data 尾 (+41..+47) + cap u32@+48 |  |
| +52 | uint32 | dynamic 容器计数 |  |
| +56 | allocator 槽 | dynamic 容器 alloc 指针 (ctor 置 &off_143085170 哨兵; dtor 经其虚槽 deallocate) | 定案 |
| +64 | RH 反查表 #1 | **角色 token (char+24) → CCharacter\*** {data@+72, count@+80, mask@+84, extra@+88, mlf@+92=0.9}; 桶 24B {hash, dist, key u32, CCharacter*}; 哨兵 &unk_1430871C8; 注册 sub_1406BA240 (重复 → "Several characters have the name %s %s"); **插入原语唯一业务调用者 = 新局批产 → 读档后恒空** (token 反查仅新局会话内有效) | 不序列化 |
| +96 | RH 反查表 #2 | **已用角色名登记表** {data@+104, count@+112, mask@+116, extra@+120, mlf@+124}; 桶 48B 含 std::string@+8 与 aux u32@+40, 墓碑 0xFF; 哨兵 &unk_143085240; 插入 sub_1406B2FA0 / 批量 sub_1406BAAC0; **载入期经 CCountryCharacters case 19622 持续维护, 读档后仍可用** | 不序列化 |
| +128 | RH 反查表 #3 | **leader+3800 legacy_id → CCharacter\*** {data@+136, count@+144, mask@+148, extra@+152, mlf@+156}; 桶 24B; 哨兵 &unk_1430871F8; 注册同 #1 (重复 → "Several characters have the legacy unit leader id %i"); 读档后恒空 (同 #1) | 不序列化 |

两容器元素均为 CCharacter 指针 (8 字节/项); 合并遍历 = 全部角色 (~1.25 万)。

#### 4.4.10 CCharacter 关键挂载

| 挂载 | 位置 | 布局 | 备注 |
|---|---|---|---|
| portraits | 内嵌@char+120; 容器 {d@char+128, c@char+140} | 元素 56B: ptype u32@0 (0-5 = civilian/army/navy/air/operative/scientist), size u32@4 (0=small 1=large; 容器按 {+4,+0} 有序二分 upsert), +8 已定义旗 (构造恒 1), +12 值形态 (1 = 文件路径 / 0 = GFX 条目 — **双形态**, GFX_ 前缀校验 icon_entry.cpp:38), 串 MSVC@+16, +48 解析句柄 (路径形态经 qword_143453090+368 注册表查询缓存) | **path 空串也写 `""`** (锚件 1,464 叶实证; SL.Q 滤空会整族蒸发) |
| variables | **内嵌@char+216** (CVariables) | 空判 = BB9830 同构 (`u32@+224==1 && u32@+248==0` → 空); RH 桶 0x30 {dist@+4, 名 MSVC@+8, value i64×1e-5@+40} | ⚠ 与 char_extras 同源; 内嵌对象非指针 — 误按 +216 指针解引用且无判空门 = 海量假叶; `^num` 非纯数字后缀键 → `.#N` 序号叶 (与 country.variables 同款) |

**CIconEntry** (icon_entry.cpp; 48B 值记录 — 与上表 portraits 56B 元素的值子记录同构互证): +0 已定义旗 (构造恒 1) / +4 kind (**0 = GFX 条目 / 1 = 文件路径**, 分支标签 GFX=/Path= 三错误串直证) / +8 值串 (32B) / +40 解析句柄 (路径形态经注册表解析, GFX 构造置 0)。函数族: 严格解析 0x14139D5A0 (含 `/` 或 `.` → 路径; 否则须 GFX_ 前缀, 违者 :38 错误 — 与 0x14139D460 双旗参数化版为姊妹对) / 构造包装两件 0x14139D310 (GFX, :59) 与 0x14139D3B0 (路径, :49) / **operator== = 0x14139CC00** (同 kind 串全等, 值串 SSO 三件套 data@+8/size@+24/cap@+32; **kind 不等直接返 0** — 静态空串哨兵 qword_1430C71F8 赋值为不可达死路径 (三出口控制流直证, 勿据此推断跨 kind 比较); kind ≥ 2 → :143 `Invalid enum value` 断言后返 0) / 诊断串构造 0x14139CCF0 (` Portrait for [|<名>] is not valid - GFX=/Path=/? =` — `[|` 排版为原代码 quirk; kind 无效臂先发 :186 `what kind of IconEntry is this ?` 断言; 字面量经 exe 反汇编恢复, IDA 隐藏 append 实参)。邻接 0x14139D1E0 = IsResolved 判定 (gamestate.h 线程禁入断言属此函, 勿因 lea 扫描越界误归 0x14139CCF0)。

#### 4.4.11 CCharacter 全字段表 (304B, vtable 0X297EA60, writer 0X140FA6520)

偏移绝对; 引擎落盘序 ≠ 偏移序。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | uint32 | CID.type (type=73) | 恒写; `id = { id type }` 块 (0X142220340) |
| +12 | uint32 | CID.id | 恒写 (同上) |
| +13..+23 | 匿名结构 (11B 形状) | = CID.id 尾 (+13..+15) + CReferenceObject 簿记首字节 (+16, ctor 清 0; +17..+23 基类余量, writer 不触; 高置信) |  |
| +24 | uint32 | token 角色唯一名 (如 GER_albert_kesselring) | 恒写, 引号 token 名 (sub_1424BC260 + ADF40); tok 19015 |
| +32 | 匿名结构 (NNB 形状) | template — 名 = token u32@(*ptr+8) | 门 ptr≠0; 引号串; tok 19482 |
| +33..+71 | 匿名结构 (39B 形状) | = template 指针尾 (+33..+39) + 显示名缓存 SSO#2 本体 (+40..+71) (ctor 0X140F9EEA0 / writer 0X140FA6520 尺寸直证 **304B**) |  |
| +40 | SSO 串 (32B) | **本地化显示名缓存 #2** (定案: 与 leader+64 同族, 实读显示名与 name token 对应; writer 不序列化) | dtor 完整析构直证 (存在性定案) |
| +72 | SSO 串 | name | 门 qword@+88≠0 且文本模式; tok 27 |
| +73..+103 | SSO 串本体 (31B) | = name SSO 本体 (+72..+103) |  |
| +104 | tag_id (int32) | country 所属国 | 门 >0 引号 tag (sub_140BB59C0); tok 10394 |
| +108 | tag_id (int32) | nationality 国籍 | 门 >0; tok 19480 (现档零叶) |
| +112 | uint32 枚举 | gender — 0=undefined (tok 19479) / 1=male (tok 12775) / 2=female (tok 10773) | **恒写**; 枚举→串 sub_1413F04A0 (其它值断言 "Invalid enum value" 后仍回落 19479; token 名经双检锁缓存 (unk_1435E1AD8 锁 / 界 dword_1435E1AB4, dword_1435E1ABC / 回落 qword_1430C71F8)); 块键 tok 19481 |
| +120 | CCharacterPortraits 内嵌 | portraits — 容器/元素表见 §4.4.10 | **仅文本模式**整块 (0X1424C2E20); 块键 tok 19497 |
| +121..+151 | 匿名结构 (31B 形状) | = portraits {vtable@120 尾 + pdx 24B 容器@128 {d@128, cap@136, c@140, alloc@144}} — 元素 56B 同 §4.4.10 (0X14139DE90 ctor 直证) |  |
| +152 | std::map 头指针 | country_leaders — 节点 {_Left@0, _Parent@8, _Right@16, isnil@+25}, 载荷 CCountryLeader* @node+40; 空载荷写常量 357 (none); **key = ideology id u32 @node+32 (CIdeology+8)** | 门 qword@+160≠0; 块键 tok 19973; 后继 sub_1401FF1F0 (中序); 插入路径 0x140FA2C10 (手写红黑树下降: isnil@+25 / key@+32 / value@+40; 命中 → :885 "Character already has a country leader role with this ideology" 闩 byte_14333D67A; ideology+56 有效性旗 → :888 "Invalid ideology" 闩 byte_14333D67B) |
| +153..+167 | 匿名结构 (15B 形状) | = country_leaders std::map {head@152 尾 + size u64@+160} — ctor malloc 0x30 头哨兵; writer 门 = qword@+160 |  |
| +168 | CUnitLeader* | leader — CArmyLeader/CNavyLeader/COperativeLeader 三选一 (leader_type 判别) | 门 ptr≠0 且 u32@(leader+3708)∈{0,1,2}; 块键 = field_marshal (13538) / corps_commander (13511) / navy_leader (12471); 块体 = 对应派生 writer (§4.4.5 / §4.4.6) |
| +176 | std::map 头指针 | advisors — 载荷 CAdvisor* @node+72 | 门 qword@+184≠0; 块键 tok 19484; 后继同上 |
| +177..+191 | 匿名结构 (15B 形状) | = advisors std::map {head@176, size@184} 同款 |  |
| +192 | CScientist* | scientist (堆) | 门 ptr≠0; 块键 tok 16389 |
| +200 | uint32 | operative 对.type | 任一≠0 才写; `operative = { id type }` (0X142220260); tok 15635; 消费点 = CopyRoles/0860 以其作 unit-leader 角色在场判据与克隆源 (:1217 `+168 || sub_14221F310(char+200)`) |
| +204 | uint32 | operative 对.id | 同上 (消费点同 +200) |
| +208 | CUnitMedalStore* | unit_medals | 门 = **store≠0 且 (u32@store+12≠0 或 u32@store+608≠0)** (定案); 块键 tok 15870; store 布局见表后注② |
| +216 | CVariables 内嵌 | variables — RH 桶布局见 §4.4.10 | 门 = 非 (u32@+224==1 且 u32@+248==0) (sub_140BC8D50); 块键 tok 10826 |
| +217..+271 | 匿名结构 (55B 形状) | = **CVariables 56B 全形** {vtable@216, u32@224 = random 种子#1 (ctor=1; §4.13.2 random 对写形反序 = 存档 `<+228> <+224>`), u32@228 = random 种子#2 ctor 常量 1587985054 (float 位型, 语义未名), pad, 静态空串指针@240, 桶数据指针@248 (ctor=0), u8@256, u32@260=常量 1063675494, 回指指针@264} — 空判 (u32@224==1 && u32@248==0) 与 ctor 初值完全互证 (0X140BC5BD0) |  |
| +272 | CFlagManager | flags — {vtable@272, data@280, {cap u32@288, count u32@292}, 静态指针@296}; 元素 48B {key token@+8, date hours u32@+24, value i16@+40, days i16@+42}; 叶 = flags.<名>.value/.date/.days | 门 = i32 计数@+292 >0; 块键 tok 10697 |

表后注② CUnitMedalStore 布局 (616B = 0x268 malloc 直证): history 容器 {data@+8, count@+20}, **元 = CUnitHistoryEntry\* (328B; 两处 reader 均 malloc(0x148) 直证; 勋章 def 只以名驻条目 +104, 不入队)**, 叶 `history = { history_queue = <medal ref> }` (tok 10293/12340); +32 勋章修正块 (并入将领 b1, §4.4.3); amount u32@+608, 叶 `amount = N` (tok 417)。

表后注③ writer 0X140FA6520 全函数不触 +456 (该处无字段行)。

⚠ 按 id 查角色需缓存 id→地址 (代际缓存)。

⚠ 每次访问前必须重校验 vtable (引擎会回收复用角色对象)。

char 对象 304B (ctor 直证), 终于 flags 块尾 +303; +320..+328 为对象外 (负定案)。

#### 4.4.12 CSubUnitDefinitionAssociatedModifiers (navy_leader.sub_unit_modifiers)

内嵌@leader+296 (vtable 0x142955af0, 288B; 归并 writer 0X141016D10; IsEmpty 0X140643140 = 两容器 count 全 0 则整块不写)。描述侧归并 = **MergeAdjustersWith\<CSubUnitDefinitionAssociatedModifiers\> sub_140AE2780** (断言 subunitdefinition.h:455; 消费于 CTraitDefinition tooltip 构建器 sub_140AE8120 — 特质→兵种修正的 tooltip 合成链)。

| 偏移 (leader 绝对) | 类型 | 名称/语义 |
|---|---|---|
| +304 | 匿名结构 (56B) | 容器 A data — stride 56 "units" 数组: {vtable(CSubUnitDefinitionId)@0, **key u32@8**, CUnitAdjuster vtable@16, dword@24, qword@32/40/48} |
| +305..+315 | 匿名结构 (11B 形状) | = 容器 A {data@304, **cap@312**, count@316, alloc@320} 内部 (pdx 24B; ctor sub_141019140) |
| +316 | uint32 | 容器 A count |
| +317..+327 | 匿名结构 (11B 形状) | = 容器 A count 尾 + **alloc@320** |
| +328 | 匿名结构 (208B, 内嵌 CModifier) | 容器 B data — stride 208 修正数组: {pad@0, **key u32@8**, **CModifier 内嵌@+16 (192B)**} |
| +329..+339 | 匿名结构 (11B 形状) | = 容器 B {data@328, **cap@336**, count@340, alloc@344} 内部 (stride 208) |
| +340 | uint32 | 容器 B count |

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
| ctor | 参数化 sub_1413DEAF0 / 默认 sub_1413DECC0 (TNullObject 用); 0X14129DE10 系 CAdvisor ctor 勿混 |
| 堆指针实证 | writer 0X1412A5390 反汇编 `mov r8,[rbx+20h]` |

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint8 | 标志 (ctor=1; 语义未名) | 存在性定案 |
| +16 | 匿名结构 (NNB 形状)* | 属主/库回挂 (ctor 置 0; 未名) |  |
| +24 | uint32 | ledger | 枚举映射 sub_141528240 (**2=civilian 也写行** — 锚件 2 例落盘; 0xFFFF 规整为 0xFFFFFFFF); PostLoad 按 slot 串补默认 |
| +32 | SSO | idea_token | PostLoad 与 name 互补拷贝 |
| +64 | int32 | idea_token 伴随 hash/缓存 (-1 哨兵) | PostLoad 连带复制 |
| +72 | SSO 串 | **name** | loader tok 27 (定案) |
| +104 | int32 | name 伴随 hash/缓存 (-1) | 高置信 |
| +112 | SSO | slot | loader tok 13378 |
| +144 | int32 | slot 伴随 hash/缓存 (-1) | 高置信 |
| +152 | SSO 串 | **picture** | loader tok 464 (定案) |
| +184 | fixed×1e-5 | cost (ctor=define qword_143338118; PostLoad 默认价覆盖门) | **write-only 镜像** (loader 读弃, 运行时 = 模板重建) |
| +192 | uint8 | **cost 键存在旗** (loader tok 10323 读值即弃后置 1; PostLoad 以此门控 slot=="political_advisor" 默认价覆盖) | 定案 |
| +200 | fixed×1e-5 | removal_cost | write-only 镜像 |
| +208 | uint8 | can_be_fired → yes/no (恒写正逻辑) | write-only 镜像; factory `*(tpl+208)` → advisor+184 直证 |
| +216 | fixed×1e-5 | command_power (ctor=define qword_143338298) | write-only 镜像 |
| +224 | 匿名结构 (40B) | traits 名串数组 {data, cap@232, count@236, alloc@240}, stride 40, 名 SSO@elem+0 | loader tok 12278 增长码 40B 步进直读 |
| +248 | CModifier (192B) | **modifier** (vtable@248 内嵌@264) | ctor 直证; loader tok 10597 → ABB40(+248) |
| +440 | CAndTrigger (88B) | **allowed** | ctor 装 CAndTrigger vtable + loader tok 12263 |
| +528 | CAndTrigger (88B) | **available** | tok 12264 |
| +616 | CAndTrigger (88B) | **visible** | tok 11562 |
| +704 | 匿名结构 (64B 形状) | research_bonus 多态元数组 {data@704, count@716} (64B 元工厂 sub_1413DE990; 本档 0 叶) | loader tok 12641 |
| +728 | CMeanTimeToHappen (56B) | **ai_will_do** (ctor 基值 4 天/100000@+24) | tok 10819 |
| +784 | CEffect (88B) | **on_add** | ctor 装 CEffect vtable + loader tok 12356 |
| +872 | CEffect (88B) | **on_remove** | tok 14710 |
| +960 | CAndTrigger (88B) | **do_effect** (loader 参 4) | tok 13321 |
| +1048 | SSO | desc | **恒写, 空串也写 `""`** (tok 10644) |

script-only 键 (loader 有案不入存档; dynamic_template 存档叶仅上表恒写族): name / picture / allowed / available / visible / do_effect / on_add / on_remove / ai_will_do。

兼容键 always_show_on_actions_tooltip (10753): loader 读弃, 无字段。

#### 4.4.14 CAdvisor 修正块 (+224 块门三选一与 +416 孪生块)

CModifier 内嵌@**adv+224** (vtable 0x1427185f0); 块门 writer 三选一:

| 门分支 | 判别 | 读法 |
|---|---|---|
| ① | i32[adv+360] > 0 (= CModifier+136) | 块写 |
| ② | i32[adv+276] ≠ 0 (= CModifier+52 = 数组B count) | 块写 |
| ③ | 数组A {data@adv+240, count@adv+252, stride 16} 任一条目 def 过类属检查 sub_14055F700 | **引擎精确谓词**: cat = u32[def+104]; 过 = cat==0 或 `(类属掩码 & cat)≠0`; 掩码 = u32@BASE+53571192 = 回调 fnptr@0x33300a0 恒返值 = `M.modifier_category_mask`; 访问器 `M.modifier_category(idx)` |

孪生块注: advisor+416 = **运行时生效修正** (CModifier 192B, writer 盲区; ctor vtable@+416 内嵌@+432); 存档序列化块 = +224, 运行时生效 = +416。

RebuildModifiers sub_1412A5030 清 +432 归并 traits (trait+152 修正块), slot8 尾 +432 += +224。

#### 4.4.15 CAdvisor 全字段表 (792B=0x318, vtable 0x1429A7D60, writer 0X1412A5390, loader sub_1412A3C70, factory sub_14129ED90)

writer 0X1412A5390 (vtable slot2 直证)。⚠ can_be_fired (14487) 仅 ==0 时发射 (模板侧恒写, 段侧复刻 advisor 块须按条件发射)。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | slot 名 token 化 id (基类簿记槽) | factory token 化 |
| +16 | CCharacter* | owner 角色回指 | ctor a2 |
| +24 | ref | **advisor 角色条目引用** (→ character template+544 map 条目载荷; 与 +32 互斥, ref 优先) | loader tok 19482 → sub_1413F1AF0(tpl, +128) |
| +32 | ScopedPtr | dynamic_template (CAdvisorTemplate* 0x438) | loader tok 19596 malloc 注入 |
| +40 | uint32 枚举 | ledger | ctor 0; loader tok 10354 |
| +48 | SSO 串 | idea_token {size@64, cap@72} | loader tok 19483 |
| +80 | int32 | idea_token 伴随 hash/缓存 (-1) | 高置信 |
| +88 | SSO 串 | **name** {size@104, cap@112} | factory ← 模板 name getter (定案) |
| +120 | int32 | name 伴随 hash/缓存 (-1) | 高置信 |
| +128 | SSO 串 | slot {size@144, cap@152} | loader tok 13378 |
| +160 | int32 | slot 伴随 hash/缓存 (-1) | 高置信 |
| +168 | fixed×1e-5 | political_power (聘用 PP 基价) | **write-only 镜像** |
| +176 | fixed×1e-5 | removal_cost | write-only 镜像 |
| +184 | uint8 | can_be_fired (默认 1) | write-only 镜像; SetCanBeFired sub_1412A4CD0 |
| +192 | fixed×1e-5 | command_power | write-only 镜像 |
| +200 | 匿名结构 (元素待裁) 向量 | traits 指针数组 {data, cap@208, count@212, alloc@216} (8B 元) | loader tok 12278 去重插入 |
| +224 | CModifier (192B) | **modifier#1 = 脚本/模板修正** (存档序列化块 = 此块) | ctor vtable@224 内嵌@240; loader tok 10597 |
| +416 | CModifier (192B) | **modifier#2 = 运行时生效修正** (writer 盲区) | ctor vtable@416 内嵌@432; Rebuild sub_1412A5030 归并 traits(trait+152) |
| +608 | 匿名结构 (元素待裁) 向量 | **trait 子对象指针收集器** {data, cap@616, count@620, alloc@624} (8B 元 ← trait+344 的 544B 元数组) | 形态定案, 语义推定 |
| +632 | uint32 | **slot 成本修正 def 索引** (db qword_14333D6E8) | assert "has not generated cost modifier." (真断言直证; 写者 = sub_14129F190, §4.4.27) |
| +640 | SSO 串 | portrait {size@656, cap@664; 仅动态角色序列化} | loader tok 12773 |
| +672 | CCommandPowerAllocator (56B) | 指挥权分配器 {vtable@672, 占用标@680, amount@688, name SSO@696} | sub_1412A4E70 写 amount=Σ(trait+424−trait+432); vtable 与 CArmyLeader+4216 同型 |
| +728 | SSO 串 | desc loc 键 {size@744, cap@752} | loader tok 10644 |
| +760 | SSO 串 | **desc 解析文本缓存** (writer 盲区) | +728 经 loc 校验解析入 |

#### 4.4.16 CCountryLeader 全字段表 (336B=0x150, vtable 0x142981350, writer 0X140FCC690, loader sub_140FCBDA0, factory sub_140FCAF30)

country_leaders map 载荷 @node+40。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CCharacter* | owner 角色回指 | assert "country leader not attached to a character" |
| +16 | SSO 串 | **desc 解析文本缓存** (writer 盲区; size@32, cap@40) | slot8 loc 解析 |
| +48 | SSO 串 | desc loc 键 {size@64, cap@72; tok 10644, 文本模式门} | 定案 |
| +80 | token 向量 | traits 指针数组 {data, cap@88, count@92, alloc@96} (8B 元; tok 12278, token@elem+8; 元素 = CTrait def: 另有 **+24 名串/+56 int 等级**, CopyRoles 复制路按名串搬运重建) | 定案 |
| +104 | CModifier (192B) | **运行时生效修正块** (writer 盲区; traits(trait+152) 归并; name SSO@+192 ← char 名) | Rebuild sub_140FCC200 |
| +296 | CGameDate vtable | expire 日期数据对象 (hours@+304, 哨兵 43808760) | writer 门 +304 ≠ dword_143086B50 |
| +304 | uint32 (hours) | expire (tok 12277) | factory ← 模板日期 |
| +312 | CGameDate vtable | expire 保存视图 (writer/loader 官方寻址, hours = 视图−8) | §3.7a 视图规则互证 |
| +320 | CIdeology* | ideology def obj (tok 11838 写 idx@obj+8) | loader 校验 *(obj+56); **GUI: ideology_ico 有领袖分支** (party+112/+124 门 → CCountryLeader+320 → +16 SSO 名拼 `GFX_ideology_<名>[_<TAG>]`; sub_140B48C70 复核闭合) |
| +328 | int32 | id (tok 11, ≠-1 门) | **write-only 镜像** (loader sub_1424C08D0 读弃); **有符号域** — 存档实证负值 -2 (黄粱 historical.character[1804]), 读取须 i32 还原 (旧按 u32 直读印 4294967294) |

#### 4.4.17 CScientist 全字段表 (312B=0x138, vtable 0x14297EAB8, writer 0X14140CF50, loader sub_14140C3D0)

ctor 内联于 CCharacter loader tok 16389 分支。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CCharacter* | owner 角色回指 | slot8 经它取 char+24 token |
| +16 | SSO 串 | desc loc 键 {size@32, cap@40; tok 10644} | 定案 |
| +48 | token 向量 | traits 指针数组 {data, cap@56, count@60, alloc@64} (8B 元; tok 12278, token@elem+8; 不在库报错 scientist.cpp:86) | 定案 |
| +72 | CModifier (192B) | **运行时生效修正块** (writer 盲区; traits(trait+72) 归并) | Rebuild sub_14140CA30 |
| +264 | 内嵌块 | **skills** {vtable@264, data@272, cap@280, count@284, alloc@288}; 32B 元 {spec tok@0, exp i64×1e-5@+16, level i32@+24} | tok 16431 ADEC0 块; AddRole sub_14140CDD0 |
| +296 | 匿名结构 (NNB 形状)* | **模板派生指针** (slot8: 按 char+24 token 查 character template db, *(tpl+16)≠0 则 +296 = *(tpl+568)) | 形态定案, 语义推定 (推定默认 GFX/数据) |
| +304 | uint8 | is_assigned (tok 14427, 仅真才写) | **write-only 镜像** |
| +308 | uint32 | is_scientist_injured (tok 10124, >0 门) | write-only 镜像 |

#### 4.4.18 write-only 叶族群

行为定案: loader 单参只读丢弃壳 (sub_1424C0A70 定点, 解析后置 0 / sub_1424C0C00 布尔 / sub_1424C08D0 整数) 实证下列存档叶**写出不回读**, 加载时由模板/factory 重建。

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

**CCharacterTemplate** (common/characters/*.txt 角色模板, ~584B; vtable 0x1429BC9A0; TNullObject vtable 0x1427E6258; [2]=CFG 空桩 不入档, [3]=0x1413F1E90 非标准 Load wrapper 变体, [4]=0x1413F1EF0 键值 reader; ctor 0x1413F06A0):

| 偏移 | 类型 | 键/语义 |
|---|---|---|
| +8 | uint32 | idb 库配发 id (基 tag 357 被覆盖) |
| +16 | uint8 | 有效门 =1 (idb character_template 行「值有效性门 +16」ctor 实证) |
| +24 | std::string 32B | 内部串 (推定调试名) |
| +56 | int32 | 未名 (-1) |
| +64 | std::string | name (27) |
| +96 | std::string | country_leader 槽名暂存 (哈希作 map 键) |
| +128 | uint32 | nationality = 国 tag FNV (19480) |
| +132 | int32 | gender (19481: 0/1/2; female=10773→2 / male=12775→1) |
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
| +577 | uint8 | **历史/动态旗** (批产分野判据: 1 → dynamic 容器 mgr+40 / 0 → historical mgr+16; RegisterCharacter 国家登记同门 — sub_1413F1E80 = `*(u8*)(tpl+577)` 直读, character_manager 批双证补行) |

**CScientistTemplate** (科学家子模板, 184B; vtable 0x142765DA0; writer 桩; reader 0x14140D610): +8 bool 有效旗 / +16 traits 容器 (12278) / +40 desc 串 (10644) / +72 skills 子对象 (16431, CPersistent: +80 map) / +96 CTrigger visible 88B (11562)。

**CUnitLeaderTemplate** (将领角色模板, 192B; vtable 0x1429C0138; writer 桩; reader 0x141427DC0; ctor 0x141427B90, 断言 ≤2): +8 traits 容器 (12278) / **+24 &off_143085170 共享子对象 vptr (ctor 直写; 身份待裁)** / **+32 u32 EUnitLeaderType (0=CorpsCommander/1=FieldMarshal/2=Navy)** / **+36 skill (10453) / +40 attack_skill (14537) / +44 defense_skill (14538) / +48 planning_skill (14539) / +52 logistics_skill (14540) / +56 maneuvering_skill (15150) / +60 coordination_skill (15151)** / +64 legacy_id (19498) / +72 CTrigger visible 88B (11562) / +160 desc 串 (10644)。

**CUnitLeaderData** (内嵌领袖定义块, ~376B; vtable 0x14276A620; writer 桩; reader 0x1403B6C70; ctor 0x14032D180; 宿主 = legacy create_*_leader 效果实例 5 工厂 0x14033B910 系, 第二实参 0/1/2 转发): +8 CUnitLeaderTemplate 内嵌 192B / +200 picture (464) / +232 portrait_path (13051) / +264 gfx (12472) / +296 name (27) / +328 desc (10644) / +360 token (19015) / +364 bool female (10773) / +368 i32 id (11)。

> 与运行时 CUnitLeader (§4.4.2, 巨型存档对象) 是不同类: 本族 = 效果定义侧模板数据; 运行时领袖由 CArmyLeader/CNavyLeader/COperativeLeader 承载 (leader_type u32@char+3708 判别)。


**角色模板名字归一后处理 sub_1413F1CF0** (character_template.cpp:101; 高置信): 门 = `*(qword*)(a1+80)` 非 0（+64 name std::string 的 size 域）∧ +136 generic 旗 → CLog 65540 告警 :101 "Character '…' is marked as generic but has custom name."; 主体取 +64 名串（cap@+88 >0xF 走堆）经 sub_142245E60 变换 → sub_14011FE60 赋入 +96 串槽；随后 `if (!*(dword*)(a1+132)) *(dword*)(a1+132) = 1` — 性别缺省补 male；尾调 sub_1409E75A0(a1)（后处理传播，语义未决）。偏移与本节表逐项互证。
#### 4.4.21 特质与科学家等级 (CScientistTrait / CCountryLeaderTrait / CScientistLevel)

**CScientistTrait** (common/scientist_traits 特质条目, ~448B; vtable 0x14271B480; writer 桩; reader 0x140AA19F0): +8 id / +32 MSVC SSO 名串拷贝 / +64 uint32 名串大小写折叠 FNV-1a32 哈希 (0x811C9DC5×0x01000193, A−Z +32 折叠; −1 = ctor 未算哨兵) / **+72 CModifier 内嵌 192B (10597)** / +160 解析后名串 (MSVC SSO) / +264 name (27) / +296 icon (181) / +328 specialization token 数组 {data@+328, count@+340} (10012) / +352 CTrigger available 88B (12264)。**装载后校验/规范化 = vtable [7] 0x140AA1290** (签名 (trait, 源文件串, 行, 列), 后三参仅诊断前缀): ① 名解析 = +264 自定义名 SSO (size@+280 非 0 即用) 否则回退 +8 token 名, 缺本地化键 → scientist_trait.cpp:37 "scientist trait \<名\> does not have a matching localization key"; ② +160 = 解析后名串; ③ +32/+64 = sub_140BC96D0 拷串 + 大小写折叠 FNV-1a32; ④ +328 数组逐元对 CSpecializationDatabase (qword_14332F068, sub_140ABAB90 取合法 id 数组) 线性查, 未中 → scientist_trait.cpp:47 "scientist trait has invalid specialization: \<token\>"。装载顺序自洽: 专精库 = LoadDatabases 步 8 (§4.28), 特质 = 步 13 → 校验时专精库已就绪。

**CCountryLeaderTrait** (顾问/高指挥特质定义, ~472B; vtable 0x1427EA648; writer 桩; reader 0x14071FC50 巨 reader): +8 id / +24 特质名串 / +64 CTrigger available / +168 未名容器 / **+344 targeted_modifier 向量 (14623, 544B 元)** / **+368 equipment_bonus 指针向量 (12647, 元素 CTraitEquipmentBonus 0xA0)** / **+392 ai_strategy 指针向量 (12544, 元素 CAIStrategyReader 0x20)** / +420 sprite token (61) / +424 command_cap_cost (16408) / +432 command_cap_increase (16375) / +440 command_power (14467) / +448 bool random (10171) / +456 ai_will_do 子对象 (10819)。GUI 消费 = §4.31 CCountryLeaderTraitItem 数据源。

**CScientistLevel** (科学家按专长技能等级容器, 32B; vtable 0x1429BF088; **唯一实现写槽的类**: writer 0x1414606F0 / reader 0x1414603E0, 入档): 容器 {d@8, cap@16, count@20, alloc@24}, 元素 32B = {spec id u32@0 (= specialization idb def+8), 内嵌 SSkillLevel 24B {vtable@+8, i64×1e-5@+16 (键 11930), u32@+24 (键 10348)} (SSkillLevel writer 0x141460750)}; ctor 按 specialization 库 (0x332F068) 全量预填; reader 按 id find-or-append, id 不在库抛 "specialization %s in save file does not match any in DB." (scientist_skill_levels.cpp:120)。**SSkillLevel = CScientistLevel 嵌套类型 (RTTI 符号 `CScientistLevel::SSkillLevel::vftable` 直证)**, 24B = {vtable@0, experience i64×1e-5@8, level i32@16}。**NProject define 对 (定案)**: SCIENTIST_SKILL_LEVEL_THRESHOLDS (qword_1433399F8/dword_143339A04, 8B/条升级经验阈值) + SCIENTIST_SKILL_LEVEL_SPEED_MODIFIER (qword_143339A10/dword_143339A1C, 8B/条等级速度修正); **大小约束 = SPEED_MODIFIER = THRESHOLDS+1** (:292, 错误串 "THREHOLDS" 为引擎拼写错误); 逐级 loc 键 SCIENTIST_SKILL_LEVEL_NAME_<i> 完整性校验 (:302)。**运行期函数五件 (定案)**: 按 spec id 线性查元素 0x1414600D0 (命中返 data+32×idx+8 = SSkillLevel*; 未命中断言 :140 + terminate) / **升级结算 0x141460260** = while exp ≥ THRESHOLDS[level]: level+1 (钳 ≤ 大小−1 满级) + exp −= THRESHOLDS[旧级]; exp<0 清 0; 返 level 是否变化 / **等级→速度修正 0x14145FA10** = a4=0 返 SPEED_MODIFIER[level]+1e5; a4≠0 (支援科学家旗) 返 max(1e5, 1e5 + floor(SPEED_MODIFIER[level] × **NProject.SUPPORTIVE_SCIENTISTS_FRACTION** (defines_project.h:35) ÷1e5)) — 支援份折扣且**下钳中性值** (负修正不生效); 唯一调用方 = s4_07 已收 sub_14140B030 (a1 = CScientist, +264 skills 互证) / 逐元素 tooltip 行 0x14145EA40 (level>0 才产行; SCIENTIST_TOOLTIP_SKILL_LEVEL {LEVELNAME/CURRENT_XP/NEEDED_XP} 或满级 _MAX; 首行前缀 SCIENTIST_SKILL_NAME : SPECIALIZATION_NAME, 国别参数 = gs+1312 ≤0 回退 +1316) / 单行经验 0x14145F590 (SCIENTIST_TOOLTIP_EXPERIENCE)。

> **本域 GUI 类布局**: 见 4.31.21 / 4.31.36 / 4.31.52 / 4.31.57。

#### 4.4.22 角色周期流程 (leaders.daily / XP / 冷却 / 特质生命周期)

**leaders.daily = CUnitLeader 虚槽 [23]** (0x140C130B0, zone "leaders.daily";
COperativeLeader 覆写 0x140C12DD0)。遍历宿主 = **CCountryCharacters::DailyUpdate
sub_1410EB430** (army 数组 ch+112 / navy 数组 ch+136, country_characters.cpp:220/226
断言), 挂 CCountry::DailyUpdate 串行段 (cc+4032 机构日更 → cc+4088 → cc+4080
本步)。现役特工不走此处 — 走 CIntelligenceAgency::DailyUpdate sub_140FDBD60
(agency+216 数组逐个 vtable[23])。

CUnitLeader::DailyUpdate 五段 (定案): ① traits_to_remove (+3552) 倒计时收割
(--days <0 → RemoveTrait + swap-remove); ② 建 leader scope; ③ 门 = leader_type
≤1 ∧ HQ 可解析 ∧ !HQ+57 → 派发 **on_army_leader_daily** on_action; ④ 逐特质
**trait+1808 daily_effect** (门 trait+1828; CEffect vtable[12] ExecuteChecked
0x14053D9E0, effect.cpp:530); ⑤ 动态修正 tick 有变化 ∨ 需重评估 ∨ 脏旗 +3768
→ (reason∉{4,5} → vtable[25] EndCooldown) + RebuildModifiers sub_140C21FC0 + vtable[28]
RecalcSkillBonuses + 清脏。COperativeLeader 版前插冷却到期检查、后挂 mission
日更 sub_140FC2830 + 行动悬空修复 (assert AR-21634, unitleader.cpp:6372)。

冷却全链 (定案): **SetCooldown = vtable[24] sub_140C25150** (days>0 → start(+3728)
=now / enable(+3752) = AddDays / reason(+3716); 时长 ×(1+修正 385
MODIFIER_REASSIGNMENT_DURATION_FACTOR)); **army/navy 自动到期不在日更体** —
country.daily_parallel 波 sub_1406E8210 (§4.2.7 序10 事件检查波) 函数尾调
**CCountryCharacters 冷却扫描 sub_1410EB2F0** → 逐 leader sub_140C280C0
(reason≠0 ∧ enable_date ≤ gs+1128 → vtable[25]); EndCooldown 基类 sub_140C12470 /
operative 版 sub_140C12340 (状态机: state 0 → 清 captured(+4016)/capture_date
(+4032) + "released" 日志; 3 → 取消 mission; 4 → "operation"; 尾接基类复位);
剩余天数 = vtable[26] (基类 0x140C19680; army 0x140C19490 另加 HQ 部署行军天数);
冷却期 RebuildModifiers 走 penalty=0 分支 + RecalcSkillBonuses 跳特质聚合。

特质 XP 引擎 = **GainXpForTraits sub_140C14BD0** (zone "Gain XP for Traits"):
in_progress (+3576) 逐特质累进; 修正 = 国修正 (trait+2672 指id) ×
(1+修正 594 MODIFIER_TERRAIN_TRAIT_XP_GAIN_FACTOR — **仅 terrain 类特质**,
判据 IsTerrainTrait sub_140AEB5A0 = gain_xp 子触发器树含 is_fighting_in_terrain
token 13133) + trait_xp_factor (+3600);
XP 按可学特质数+1 均摊 (UNIT_LEADER_USE_NONLINEAR_XP_GAIN byte_143330E4D,
非线性 100000×a3/(100000×(i+1)); 阈值比较 ≥ 即到阈);
MAX_NUM_TRAITS (dword_143336994, 默认 −1 恒过) 门; 门 = trait+2220 category 掩码 ⊆ flags ∧
触发器 (trait+324→+304 / trait+236→+216); 到阈 → 收割 sub_140C1E370 →
**AddTrait sub_140C0EC40**。三入口: 战斗 (flags=7, ApplyCombatXpGains tbb →
sub_140C14A80; 得点式头乘 = BASE_LEADER_TRAIT_GAIN_XP 0.45 ×
(1+mod45(leader)+mod45(country)) 加法合成, 侧账 FIELD_MARSHAL_XP_RATIO 0.3 /
THEATER_COMMANDER_LAND_EXPERIENCE_SCALE 0.1) / 特工任务日更 (flags=8, sub_140FC2830 按 mission type 取
*_DAILY_XP_GAIN define × 修正 45) / 行动完成 (flags=8, OPERATION_COMPLETION_XP
qword_1433333B0 × op+224 参与特工) (定案)。

CUnitLeaderTrait 脚本块与键 (定案): on_add 效果 +1632 (门 +1652, token 12356) /
on_remove +1720 (门 +1740, token 14710) / daily_effect +1808 (门 +1828, token
14478) / cost +2208 (XP 阈值, token 10323) / category 掩码 +2220 (token 225
"type": FM=1/CC=2/land=3/navy=4/operative=8/all=15) / trait_type +2336 (token
14518: 0=personality/1=status/2=basic/3=assignable/4=basic_terrain/
5=assignable_terrain/6=exile; {2,3}=可学, {4,5}=terrain 加成 594) / XP 增益
modifier id +2672 / trait_xp_factor 引用清单 +2680 (16B 元, Add/Remove 双向
扣账)。AddTrait: 有序插入 → 战时 terrain 类国级效果 → vtable[32] 通知 → on_add →
terrain 类 +3788 已见数递减 → Rebuild; 第 3 参 ≥0 → 入 traits_to_remove
(timed trait)。RemoveTrait sub_140C23100: 压缩 + vtable[33] + on_remove + 扣账。

晋升 (定案): 军衔全自动 — AddExperience sub_140C14950 (leader+3688 += xp;
**严格 >** 100000×下级 def+444 → LevelUp sub_140C1D950 可连升, 升后
LevelUpTo sub_140C271B0 内 xp = max(0, xp−100000×新档 cost) → 派发
**on_unit_leader_level_up**); FM 晋升 = SetLeaderType sub_140C202C0 (命令
CPromoteUnitLeaderCommand / promote_leader 效果)。AddExperience 其余入口:
**演习 = sub_140C8FF80** (CArmy::[19] 日 tick 尾 army.cpp:4906; sub_140C895B0
实为碾过/强推 overrun 结算 (§4.18.18 定案) / 海军训练 sub_1415C1060 / 铁路炮 sub_140E8C020 / 舰长晋升
sub_141451580 / 师军官 sub_141451020 / **击溃 shatter sub_1412AE910
(XP_GAIN_FOR_SHATTERING 35/单位)** / gain_xp 效果 sub_1402E7D20 / 控制台
gain_xp sub_14025C7F0 / 反谍捕获附带 sub_140FDC3A0。

任命/顾问维护 = **CCountryCharacters::HourlyUpdate sub_1410ECB40** (hourly
相位 5 pass⑥): ① ch+264 顾问状态维护队列逐个 sub_1410EB5A0; ② ch+288 领袖
清理队列逐个 sub_1410EE1A0 (navy 脱舰队/出数组, army HQ 校验); ③ ch+224 空 →
sub_1414EC630 空位补生成 (定案①②/③高置信)。

俘获/获释 (定案): army = CCaptureGeneralEffect (DLC 门 57) →
CArmyLeader::Capture sub_140C11D60 (模板 can_be_captured 门,
unitleader.cpp:5864; +4185=1, +4188=捕获方 tag); 获释 sub_140C22F80 多入口
(效果/和会/省份易手 country_characters.cpp:1286/342)。operative =
CCaptureOperativeEffect (门 leader_type==3 — **operative 定案**) → 机构捕获
掷骰 sub_140FDAAE0: 先掷 **修正 517
MODIFIER_OPERATIVE_DEATH_ON_CAPTURE_CHANCE** (中 → SetState(5 killed) +
on_operative_death + 入 retired 池 ch+200) → 未中 → 状态机 sub_140C24AC0 置
on_capture (captured+4016 / capture_date+4032) + 56B CCapturedOperativeReference
入捕获方 agency+264 + **on_operative_captured**; 获释 = EndCooldown state-0
分支 (enable_date 到点自动获释回 on_mission)。

CCountryCharacters (ch = cc+4080 解引用; vtable 0x14298AE18) — 权威骨架已统一至
s4_03 §4.3.1 chars 表 (H 批 writer/reader 全键反编译归一; 序列化仅 5 键
19622/19968/19485/15702/17327)。本册侧要点复核: +112 = pArmyLeader /
+136 = pNavyLeader (cpp:220/226 断言直证, 原「army/navy 领袖数组」名保留);
+200 = retired 特工池 (探针定案 ✓); +224 = recruit_scientist 招募池 =
**CScientistRecruitmentPool** (88B 推定; vtable 0x14298AD78; writer 0x1414ED250 /
reader 0x1414ED0E0; 键 16389 scientist = 科学家指针向量 {data@M+8, cap@+16,
count@+20}; 元素名串发射, reader 按名解析取 `*(obj+192)` 入池; 回指 CCountry*@+32;
第二向量@+40 与惰性静态指针@+80 不序列化; CCountryCharacters ctor 内联装配,
无独立 ctor; 空池每小时补生成) / +264 待解任顾问队列 / +288 待清理领袖队列 (leader_type 分派)。

CIntelligenceAgency 增补: +120 属主 CCountry* / +192 已建成门 / +193 创建中门 /
+200 进度累计 / +208 升级目标 / +216 现役特工数组 {d,c@+228} / +240/+244/+248
升级槽三元 / +252 特工死亡计数 / +256 反谍强度缓存 / +264 捕获特工登记表
(56B 元) (定案)。


#### 4.4.23 CUnitLeaderTrait 全字段表 (2704B=0xA90, vtable 0x1429457A0; writer = 槽[2] CFG 空桩 → def 不序列化; reader sub_140AEBC20 47 键; ctor sub_140AE3C60 带名 / sub_140AE3980 无名; finalize sub_140AE5620 = unitleadertraits.cpp 父特质校验三错误串; 单件已存在时 sub_140AE6E10 原地重载)

| 偏移 | 类型 | 语义 (脚本键) | 备注 | 置信 |
|---|---|---|---|---|
| +8 | uint32 | trait token (名串 tokenize; traits 容器叶名即此) | sub_1424BB460 | 定案 |
| +16 | MSVC SSO 串 32B | 名串 name (ctor 无键, 带名 ctor 写入; GUI "GFX_trait_"+名 派生) | size@+32, cap@+40 | 定案 |
| +48 | int32 | 名串伴随 id (ctor −1) | 同构 +96 推定同名 hash/loc id 缓存 | 高置信 |
| +56 | uint8 | 有效旗 valid (ctor 1; TNullObject 0; 效果 resolve 门与 has_trait 门) | — | 定案 |
| +64 | MSVC SSO 串 32B | slot 键串 (可多次累积, 写入 = assign+哈希重算) | 键 13378 | 定案 |
| +96 | int32 | slot 串小写折叠 FNV-1a hash 缓存 (ctor −1; 基值 0x811C9DC5 × 16777619, A-Z+32 折叠) | sub_140612C40 | 定案 |
| +128 | CAndTrigger 88B | allowed | 12263 — add_unit_leader_trait 过的「子对象虚槽[3] 门」即此 (s4_32 未收书点收口) | 定案 |
| +216 | CAndTrigger 88B | gain_xp (XP 门 = 子计数 @+236) | 12355 | 定案 |
| +304 | CAndTrigger 88B | gain_xp_leader (门 @+324) | 19413 | 定案 |
| +392 | CAndTrigger 88B | prerequisites | 10317 | 定案 |
| +480 | CAndTrigger 88B | unit_trigger | 12374 | 定案 |
| +568 | CAndTrigger 88B | country_trigger | 19328 | 定案 |
| +656 | CAnonymousEquipmentGroup 208B | allowed_ship_equipments {装备组 id@+664, 串@+672/+704, pdx 容器@+736/+768/+800/+832, vptr2@+760, bool@+792/+824/+856}; 解析 = 键清单 → 匿名装备组登记 → 定型 → 整块拷入 | 10666 | 定案 |
| +864 | CModifier 192B | modifier — §4.4.3 b6/b7 源 | 10597 | 定案 |
| +1056 | CModifier 192B | non_shared_modifier — b8/b9 | 14886 | 定案 |
| +1248 | CModifier 192B | corps_commander_modifier — b12/b13 | 14690 | 定案 |
| +1440 | CModifier 192B | field_marshal_modifier — b10/b11 | 14691 | 定案 |
| +1632 | CEffect 88B | on_add (门 = 子计数 @+1652) | 12356 | 定案 |
| +1720 | CEffect 88B | on_remove (门 @+1740) | 14710 | 定案 |
| +1808 | CEffect 88B | daily_effect (门 @+1828) | 14478 | 定案 |
| +1896 | 匿名结构 (40B 形状) 向量 24B | **CUnitAdjuster\* 条件修正表** (40B 元, 元素键 = 元+8 token) — modifier 块内键 night/amphibious/river/fort/blizzard 或命中注册模板的条目改道入此; 普通修正键才落四内嵌 CModifier 块 | factory sub_141016A40 | 定案 |
| +1920 | CSubUnitDefinitionAssociatedModifiers 288B | sub_unit_modifiers (与 CSubUnitDefinition+296 同类同 token, §4.18) | 15459 | 定案 |
| +2208 | uint32 (fixed×1e-5) | cost (ctor 默认 1000; XP 阈值 = 100000×cost, §4.4.22) | 10323 | 定案 |
| +2212 | uint32 | 图标帧索引 (无 reader 键 = 运行时/GUI 字段; ctor 清 0) | 书 s4_31 锚保留 | 定案 |
| +2216 | uint32 | gain_xp_on_spotting (默认 0) | 13592 | 定案 |
| +2220 | uint32 | type/category 掩码 (ctor 默认 15=all; FM=1/CC=2/land=3/navy=4/operative=8) | 225 | 定案 |
| +2224 | 因子块 56B | ai_will_do {类型@+16=8, 基因子@+24=100000=1.0, pdx 容器@+32} | 10819 | 定案 |
| +2280 | 因子块 56B | new_commander_weight | 14683 | 定案 |
| +2336 | uint32 | trait_type (ctor 默认 2=basic): personality 0 / status 1 / basic 2 / assignable 3 / basic_terrain 4 / assignable_terrain 5 / exile 6 | 14518 | 定案 |
| +2340 | int32 | gui_row (默认 −1) | 14516 | 定案 |
| +2344 | int32 | gui_column (默认 −1) | 15176 | 定案 |
| +2352 | 匿名结构 (NNB 形状) 向量 24B | mutually_exclusive | 13242 | 定案 |
| +2376 | 匿名结构 (32B 形状) 向量 24B | parent — 32B 元 CUnitLeaderTrait::SParentKey; any_parent/all_parents 写尾元 +12/+24 | 135/16705/16704 | 元素定案 |
| +2400 | 匿名结构 (32B 形状 = MSVC SSO string, cap@+24 判 0xF) 向量 24B | enable_ability | 14574 | 定案 (元素运行期直证; writer 键序未复核) |
| +2424 | 匿名结构 (NNB 形状) 向量 24B | custom_effect_tooltip | 10015 | 定案 |
| +2448 | 匿名结构 (NNB 形状) 向量 24B | override_effect_tooltip | 14985 | 定案 |
| +2472 | 匿名结构 (NNB 形状) 向量 24B | custom_prerequisite_tooltip | 14685 | 定案 |
| +2496 | 匿名结构 (NNB 形状) 向量 24B | custom_gain_xp_trigger_tooltip | 14789 | 定案 |
| +2520 | 匿名结构 (NNB 形状) 向量 24B | 校验期指针容器 (finalize 增长重拷; 父特质解析关联推定) | — | 结构定案 |
| +2544 | uint32 向量 32B | 校验期容器 {指针@0, u32@8, 引用对象@16 (release 销毁)} — finalize 按 count@+2552 遍历 | — | 结构定案 |
| +2568 | 匿名结构 (NNB 形状) 向量 24B | unit_type — 元 = subunit def 的 db 索引 (def+1420, §4.18) | 11230 | 定案 |
| +2592 | uint32 | attack_skill | 14537 | 定案 |
| +2596 | uint32 | defense_skill | 14538 | 定案 |
| +2600 | uint32 | logistics_skill | 14540 | 定案 |
| +2604 | uint32 | planning_skill | 14539 | 定案 |
| +2608 | uint32 | maneuvering_skill | 15150 | 定案 |
| +2612 | uint32 | coordination_skill | 15151 | 定案 |
| +2616 | uint32 | leader_default_proximity_offset | 10292 | 定案 |
| +2624..+2664 | int64 ×6 | 六技能因子 attack/defense/logistics/planning/maneuvering/coordination_skill_factor | 14624/14625/14627/14626/15154/15155 | 定案 |
| +2672 | uint32 | XP 增益修正 def id — ctor 期 "trait_"+名 修正 def 查得; GainXpForTraits 按此查国修正表 country+1464 | sub_140AE6E10 | 定案 |
| +2676 | uint8 | show_in_combat (ctor 默认 1) | 14788 | 定案 |
| +2680 | 匿名结构 (NNB 形状) 向量 24B | trait_xp_factor 引用清单 (元素[0] 须过该 trait +56 有效门; Add/Remove 双向扣账) | 14791 | 定案 |

> 装载: traits 库 (per-file malloc(0xA90) + 带名 ctor → vtable[3] 直调 Load → finalize);
> 键 12263/12355/19413/10317/12374/19328 六触发器块 XP 门 = 块内子计数
> (+236/+324); +56 有效门四证 (ctor 1 / TNullObject 0 / resolve :1317 / trait_xp_factor
> 元素门)。原「+152 修正块」碎片属 CAdvisor 域 (s4_04:435), 本类 +152 为 allowed 块
> 虚槽位 — 两类勿混。

**CUnitLeaderTraitsDB 载入入口 sub_140AEDCF0** (高置信): 门1 = 已置注册锁 (db+1048 byte) → 断言 "_RegisteringDynamicModifiers == false" unitleadertraits.cpp:1706 (闩 byte_14333A2B2); 置锁 → 门2 = db+20 loaded 旗非零 → "DB already loaded when loading %s" gameitemdatabase.h:160 → 抛异常; 正常 = 名写 +8 容器 → 装载本体 sub_140AEA720 → vtable[+16]/[+32] 两虚钩子 (per-def 后处理, 其一经 sub_140AEDEA0 遍历 db+88 容器 {data@+88, count@+100} 逐 def 调下述压缩器); 尾恒执行 = 清锁 → 清 +88/+208 两容器 → 四对索引 dword 清零 (+124/+244, +148/+268, +172/+292, +196/+316) → +8 区间清空且 count(+12)=0。
**enable_ability 校验压缩 sub_140AE30C0** (容器 {data@+0, count@+12}, 32B SSO 元): 逐元查 ability 库 (a2[1] 句柄, sub_140613EE0), 非法 (结果+16 byte == 0) → ""%s", defined in %s is not a valid ability" :646; copy-erase 压缩合法元素 → 返回移除数。
**校验错误格式化 helper sub_140AEB6E0**: 消息 = "<前缀>:<行起>-<行止> '<特质名>': <错误>" (:615, 级别旗 65540); 调用者 sub_140AEAA80 特质校验 (门 = def+500 dword / def+2220&3), 已直证串 "Non-land trait had a unit_trigger"。


#### 4.4.24 CUnitLeaderSkill 全字段表 (456B; 库 = CUnitLeaderDatabase 1056B 七梯, 单例 qword_14332F0D0; token 12357/14533/14534/14535/14536/15152/15153; Array[0] = TNullObject; 梯内按 +448 分 4 桶)

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vtable | CUnitLeaderSkill | |
| +8 | uint8 | 非 null 旗 | 定案 |
| +16 | CModifier 内嵌 | skill 修正块 (b7 消费, §4.4.3) | 定案 |
| +208 | CModifier 内嵌 | 第二 CModifier | 定案 |
| +400 | SSO 32B | 名串 | 定案 |
| +440 | uint32 | **军衔等级** (writer 恒写无判空直接解引用) | 定案 |
| +444 | uint32 | **下级 XP 阈值** (数据源 = common/unit_leader/00_skills.txt leader_skills 块 cost 键直读, navy 100..25600 / CC 与 FM 100..10000 九级 / operative 100,1000; SKILL_LEVEL_NEXT_AMOUNT define 于 1.19.3 不存在; 兼 XP 比例分母; 活证 100/300) | 定案 |
| +448 | uint32 | 分桶码 (梯内 4 桶键) | 定案 |

**等级上限 = logistics 梯 count−1** (sub_140AE9520 读 db+724+24×t; 活证 t0/1/2 = 11、t3 = 0)。
晋升链 (def+444)、技能上限 (sub_140AE9520)、skill_advantage 触发器 (+440) 三链落位。**技能上限六梯全景 (定案)**: db+364/484/604/724/**844/964** 六梯 + 24×leader_type (attack/defense/planning/logistics/maneuvering/coordination; getter 配对 sub_140AE94F0/9510/9540/9520/9530/9500; 844/964 = navy 专用 maneuvering/coordination); 升级掷点 vtable[31] sub_140C1EC10 army / sub_140C1F330 navy: 权重 = max(1000,(基值+Σtrait因子)×等级), 基值 = define COMMANDER_LEVEL_UP_STAT_WEIGHTS (army, qword_143339650) / NAVY_LEADER_LEVEL_UP_STAT_WEIGHTS (qword_143339668), 每级掷点数 = COMMANDER_LEVEL_UP_STAT_COUNT (dword_143331430), 命中 +1 并回填减益。**navy 掷点双错位怪癖 (定案, 引擎原样)**: ① maneuvering/coordination 桶到顶门误用 planning(+604)/logistics(+724) 梯 (setter 钳位在 844/964 梯, 多掷命中被钳吞不越界); ② 两桶权重错读特质因子 +2640/+2648 (logistics/planning), 真因子 +2656/+2664 被无视 — 海航特质因子对海军升级权重无效 (roll 体 + trait reader 偏移映射双证)。

领袖工厂与状态机增补 (定案): 领袖对象工厂 sub_140C14160 = CCharacter+560 模板 → 按模板+32 类型造 CArmyLeader (**4280B = 0x10B8**) / CNavyLeader (**4040B = 0xFC8**); operative (3/4) 断言 "Not implemented" 不走本工厂 (走机构路径, 与四胞胎 AddUnitLeader 分工); tag 初值 0, 归属国由 vtable[21] SetOwnerCountry 后置。CNavyLeader ctor 尾手工段: +3936/+4008 = null CID 哨兵 qword_14333D528、+3944..+4000 四技能 quad 清零、**+4032 penalty ctor 初值 = fixed 1.0** (sub_1424EF6F0 构造)。**COperativeLeader 正典状态机** (SetState sub_140C27350): EOperativeState 0..5 (0=captured / 1=cooldown / 2=disbanded / 3=on_mission / 4=operation / 5=killed) + 合法迁移矩阵; SetCooldown (vtable[24] 覆写 sub_140C24DB0) 状态 3/4→1 + 任务 optional 复位/预载 (<OPERATIVE_MAX_DAYS_TO_AUTO_RESUME_MISSION 自动恢复); Release sub_140C26E20 清捕获对 + 回 on_mission(3) + 分配本国反谍; 随机特质授予引擎 sub_140C10600 (define chances 容器逐下标掷 + 16B {weight,trait*} 加权抽取 + swap-remove + scope 复评收缩)。

unitleader.cpp 簇对账增补 (38 函数闭环; 断言锚行 156..7244 全员体内, 单编译单元确认):

**冷却机制族全链** (新): 基类 SetCooldown vtable[24] sub_140C25150 (days>0 → start=now/enable
=AddDays/reason; 否则哨兵 43808760); **冷却设值包装 sub_140C1FD60** = `(leader, reason,
days, scale_flag)` — scaled = scale_flag ? sub_140C0FDB0 : **2×days** (scale=0 分支语义待裁),
先 vtable[24] 再「只延长」补写 (now+24×scaled > 现 enable 才重写); **时长缩放 sub_140C0FDB0 =
days + int(days×mod385)** 读自 leader b0 块 (+664 锚) — 「×(1+修正 385)」读数块落定;
reason 1 (组变更) 天数 = define UNIT_LEADER_MODIFIER_COOLDOWN_ON_GROUP_CHANGE
(dword_1433371D4)。**deploy/withdraw 冷却三叶族** (新): 发起 sub_140C1EA90 (部署,
reason 4) / sub_140C20060 (撤收, reason 5) — 天数源 = sub_1415B0030/1415B01D0
(u32@(HQ 派生+400)); 延长 sub_140C22B60 (锚既有 start, 不走 vtable[24]); 查询 sub_140C11990。
operative SetCooldown 覆写 (互证 + define 落址 OPERATIVE_MAX_DAYS_TO_AUTO_RESUME_MISSION
= dword_143332E88; 落账核 = sub_140C25340)。

**operative 状态机族实名补录**: SetMissionToNone = sub_140C263A0 (:6836 错误串实名);
SetOnOperation = sub_140C26600 (operation idpair@+3968 = COperation+8 或 nullCID 哨兵
qword_14333D528); SetMissionImpl 双包装 = sub_140C0B2E0 (bool) / sub_140C0B410 (void)
(state3 门 + optional→容器恢复→销 optional 舞步后函数指针回调); state 字段 = operative
+4224; 任务 optional 舞步三件套 = sub_140C28050 (打包) / sub_140FC4C30 (恢复) /
sub_140FC5A90 (清空)。

**捕获特工 intel yield** (新定性): sub_140C27680 聚合器 + 变参/直参两壳 (sub_140C2A9D0 /
sub_140C185E0) = `1.0 + mod545 + mod546` — 545 = MODIFIER_OWN_OPERATIVE_INTEL_EXTRACTION_
RATE (本国侧: +3944 nationalities 有序 tag 容器**二分**查国籍修正 [消费侧新补] + 本国
cc+1448 + leader b2 (+1032)); 546 = MODIFIER_ENEMY_… (捕获国 cc+1448); 门 = captured
(+4016) > 0 (:7210)。

**Capture 新链路**: 归属国 +288 改写有**玩家门** — 仅当玩家国 (gs+1312/1316 规范形比较)
∈ {原属国, 捕获方} 才改写为捕获方 (非玩家参与的 AI 互俘不改归属; MP 对称性待裁);
location +4192 填充链 (a4 优先, 否则 HQ+496 派生); 捕获方 = 玩家门内 sub_140CC2140 +
sub_140CCE5B0 玩家侧挂钩; owner character 登记与通知入队。

**部署指挥点重分配 sub_140C22CE0** (新): leader+4208 现额 ≠ 新需额 → 释放旧额 → 清
+4216 CCommandPowerAllocator → 国级重分配, 失败 :4736 assert。

**实名补录**: CArmyLeader 参数化 ctor = sub_140C0B7D0; CNavyLeader 手工尾段 ctor =
sub_140C0C200; RecalcSkillBonuses 基实现 = sub_140C21280 (工厂 vtable[28] 指针直比后非虚调用);
技能 DB getter = sub_14022FD90 (qword_14332F0D0 访问器); 梯内 def 查找六件 =
sub_140AE7D60/AE7FB0/AE96A0/AE8090/AE80B0/AE7D80。**小函数批量**: 八 setter 同构模板
(deficit@X = min(v−1,0) / skill@Y = max(v,1) / 梯钳位 / def 查写伴随槽 / rebuild 三连);
EOperativeState→存档 token 映射 (0→19025 on_capture / 1→19026 on_cooldown / 2→19027
on_disband / 3→14668 on_mission / 4→19024 on_operation / 5→13164 killed; 默认 assert 仍写
14668) 独立函数 sub_140C201B0 与 writer 内联同款。未决: 两个枚举映射器 (sub_140C27FC0
→{1,1,2,4} / sub_140C19100 leader_type→{army 1, navy 2, operative 4}) 消费方; +584 索引域
探针取证; scale_flag=0 触发路径。

character_manager.cpp 簇对账增补 (15 函数闭环; 单元 = 随机角色生成装配线, 簇 = 含锚子集):

**三入口 × 五生成器 × 两创建路** (定案): 入口 A sub_1406B7AE0 (通用) / B sub_1406B75A0
(文官, 内联女性掷点修正 565) / C sub_1406B84E0 (文官·ideology, §4.32 已实名); 每生成步间
sub_142234110(seed, file, line, 0) **RNG 审计埋点** (行号 = 源码行, 高置信 = 确定性回放/
联机同歧校验, 落盘去向未决)。**种子方案**: seed = tag 序号 + next_id (或 CID.id) + 引擎
RNG; 配对 {seed, 1587985055 − seed}; PRNG 常数族 1255572915/1759714724/458671337/
−1831433054, 消费 &0x7FFFFFFF %100000 (引擎级通用小 RNG, 选举域独立复现)。

**性别掷点 sub_1406B5000** (定案): 返回 1 = male / 2 = female; 阈值 = 基值表
qword_1433386D8[ptype] + 国修正 @cc+1464 (ptype 0→565 / 1→563 / 2→564 / 4→561 / 5→562,
3 无修正); **门字节 cc+1729 (ptype 0) / cc+1728 (ptype 1-3)** = 0 时直接 male (语义推定
女性头像开关; define 名未决); "invalid portrait type" :107。

**头像族** (定案): 姓名库 qword_14332EF68 / 头像库 qword_14332EFD8 (+书技能库
qword_14332F0D0) = 三个独立 CGameItemDatabase 实例; 文官生成器失败 terminate :207 (通用
版仅日志 :190); **小头像换算 sub_1406B64E0** = 模板查无 → 大路径+"_small" / 查有 → 4 段
路径重组 `gfx/interface/ideas/idea_<名段>` + 文件存在校验, 三级 fatal :283/:307/:319;
师长/舰长对 sub_1406B5C70/5D60 (bool 性别映射 (male^1)+1; 5D60 种子对 = 栈 8B {seed, 1587985055−seed} 整体入取像器第 2 参, a5 = gender bool / a6 = ptype, 失败仅日志 :229, 尾调小头像换算 sub_1406B64E0); 缺省补挂 sub_1406B8790
(leader_unknown.dds 回退判定门, 消费者 = 选举/党魁域 [宿主类未决])。

**注册链** (定案): RegisterCharacter sub_1406BA240 — RH#1 (mgr+64, token→CCharacter*)
门 token ≠ −1, RH#3 (mgr+128, legacy_id→char) 门 legacy_id > 0, 哈希 = 73244475 二轮乘混
(非 FNV); 唯一调用者 = 批产 (书互证); 国家侧 sub_1410E9650 = SetCountry (书实名互证) +
**空名回退** (token 空名先本地化, 否则以 {CID.id, 1587985055−id} 再生成姓名 SetName) +
槽位登记。**随机角色 token 派生** = 名首词去 `-`/`'` + `_` + TAG 名 → tokenize 写
char+24 (工厂 sub_1406B7260 内; malloc(0x130) = 304B 书第三证)。

消费者全景 (招募生命周期): 军/海军领袖空池补员 (ptype 2/1) / 科学家招募池 (ptype 5) /
文官池 (入口 B) / create_country_leader 效果链 (§4.32) / 新局批产 (RegisterCharacter
唯一调用者)。未决: cc+1728/1729 与修正 561-565 define 名; 基值表来源; cc+1640 载体;
EPortraitType 3/4 (推定 air/operative); RNG 审计去向; 0x1411A4620 宿主类 (其 +112 元素 =
CCharacter* 与 CCountryCharacters +112 = CUnitLeader* 属不同对象)。

#### 4.4.25 character.cpp 复制域增补 (角色复制与三军领袖角色; 10 函闭环)

清册 (10/10 函体内含完整路径锚 characters\character.cpp): **CopyRoles 0x140FA0FF0 (922)** /
CopyCore 0x140FA0A20 (258, malloc 0x130 + ctor 140F9EC50(名, 性别); :97 断言限纯顾问角色) /
AddArmyLeaderRole 0x140F9D360 (207, 0x10B8 CArmyLeader) / AddNavyLeaderRole 0x140F9D780
(207, 0xFC8 CNavyLeader, 与上者逐行孪生) / CCharacter writer 0x140FA6520 (180, §4.4.11
互证全吻合) / SetCountryLeader 0x140FA2DE0 (140, 工厂 140FCA190; 调用者 = gamestate 级
1410EAD60, 缺省 id −86) / 角色复制壳·单位领袖变体 0x140FA22D0 (104, :146 源角色须隐藏) /
AddCountryLeaderRole 0x140FA2C10 (84, 调用者 = create_country_leader 效果, §4.32 逐参互证) /
AssertPortraitExists 0x140FA01E0 (79, :618 throw, 查 +120 肖像) / 角色复制壳·科学家变体
0x140FA21D0 (49)。

**CopyRoles 四阶段** (定案): ① 顾问 (+176) ② 国领袖 (+152) ③ 单位领袖 (+168 ∪ CID+200/204
operative 对在场判据) ④ 科学家 (+192) 角色整体复制; 冲突各抛错 (:1181/:1203/:1217/:1230),
错误槽 a3+16 门。**CID 注册双路**: 有效 id 走 CID {type=55} 注册表, 无效走 vtable[9] 0x14221E990
自增 CID (type 分量 = word+4712, 0x1268 恰为注册表分界, 待闭合)。**三薄包装**
0x140FA3050/140FA2C00/140FA3060 = leader_type 0/1/2 重载 (非vtable槽)。肖像校验趟
0x140FA0320 = "advisor"/"country_leader"/"unit_leader" 三角色肖像校验。CCharacterManager
复制双路 = mgr+8 ++ + 恒入 +16 historical (§4.4.9 分野第四族)。

未决: 140FC9F80 第三参两调用形态 (单串 vs 名串向量, 待汇编) / vtable[9] type 分量闭合 /
CopyCore a4=1 调用面。

#### 4.4.26 country_characters.cpp 国家角色域增补 (状态同步/顾问聘任-解任闭环; 17 函闭环)

清册 (17/17 函体内含 country_characters.cpp 路径锚): UpdateCharacterAdvisorStatus
0x1410EF4C0 (431) / UpdateCharacterUnitLeaderStatus 0x1410F0040 (260) / AddAdvisorRole
0x1410E91A0 (210, 五断言) / PromoteToCountryLeader 0x1410ED280 (201) / GenerateAdvisor
0x1410EA930 (191, spec+8 来源枚举 0/1/2/3, 类型码 4/8/16/28) / UnassignAdvisor
0x1410EB5A0 (154) / 领袖清理分派 0x1410EE1A0 (146, 尾清 fac+2552 CFactionTheaterManager
168B 元+40/44 CID) / AddCountryLeader 0x1410EAD60 (140) / 政党成员批量登记 0x1410E99A0
(122, char 全部国家领袖挂入各自意识形态政党 +120 向量) / GetOrCreateScientist
0x1410EB030 (109, kind5 置名册 bit24) / AppointAdvisor 0x1410E9BE0 (106) /
UpdateCharacterScientistStatus 0x1410EFCD0 (104) / DailyUpdate 0x1410EB430 (54) / 冷却扫描
0x1410EB2F0 (54) / UpdateCharacterStatus 总入口 0x1410EFF10 (50, 三件套分派, 实参 = ch+16
名册元素) / RemoveCountryLeader 0x1410ED1E0 (32) / HasCharacter 0x1410EA790 (26)。

**状态同步三件套** (定案): 顾问 = ch+64 已创建 CAdvisor 登记表 ↔ char+176 advisors map 双向
对账 (陈旧项解任 + 清 fac+2104 阵营情报槽 + 出列); 单位领袖 = army (leader_type 0,1)/navy (2)
名册互斥同步, 无角色双侧摘除 (vtable[29] 获释门); 科学家 = char+192 判空同步 ch+160。ch+16 名册
元素 16B = {CCharacter*, flags} (四写点 bit0/8/16/24)。**总入口 0x1410EFF10 增补**: 名册线性查 sub_1410E7090 (出参 = 命中 flags 槽) + sub_141A9B6E0 二次校验; flags 写点 = *(元素+8), 判据 = *(char+32) && sub_1413F0E00() **零参形态** 或 sub_140FA01A0(char) 非零 (断言 :249 "Character Must be Added before we can process their Status.", 门 B52 闩 byte_14333DB5B; *(char+32) 语义未决)。DailyUpdate sub_1410EB430 / 冷却扫描 sub_1410EB2F0 两体逐行同骨架 (army ch+112 / navy ch+136 引擎向量 {d@+0,c@+12}, 差异 = 虚槽 [23] 日更 vs sub_140C280C0 冷却判定), 四枚断言闩 byte_14333DB57..DB5A (:205/:211 vs :220/:226 = 源码两处同名 assert 复用, 非 IDA 重复)。

**聘任-解任对称闭环** (定案): AppointAdvisor (on_add vtable[12]) ↔ UnassignAdvisor (槽位树空余
+1 — **ch+184 节点+84 空余数消费点首证** / 指挥权归还 / on_remove 载荷 vtable[12] / ch+88 出列);
**ch+64/ch+88 排序主键 = CAdvisor+48 idea_token 缓存 hash(+80)** (升定案; adv+632 修正索引
消费点首证)。**IA 渲染定则**: `_except_get_jumpbuf_sp` = *(x+16)、`file_name` = *(x+8), 本簇
全为 owner 回指 (非异常机制)。⚠「UpdateCharacter…Status」断言串源码复用 3 次 (:271/:342/:424),
串名 ≠ 函数身份。

未决: UnassignAdvisor 退费正负方向 (待汇编) / sub_1413F0E00 实参截断 (UpdateCharacterStatus 内为零参形态 — 实参归属待机器码) / EAD60 的 a2 定义件
类身份 / charman(+0) 登记表与 ch+96 表关系 / vtable[29] 谓词语义 / leader+4168/+4008 双 ref
目标类型。

#### 4.4.27 晋升链与 promote-from-ranks 域 (unit_util.cpp 3 函 + advisor.cpp 写者; 闭环)

簇清册 (体内 cpp 锚 5/5):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_141451AB0 | 147 | Random :202/:204/:214 | **promote-from-ranks on_action 发射器** (随机老兵 trait + 双 on_action) | 新 |
| sub_141451020 | 204 | 断言 :271 | 陆军军官晋升实现 (army, type ≤ 1) | 已收 (§4.32 实现行), 本批大幅精化 |
| sub_141451580 | 197 | 断言 :338 | 海军军官 (舰长) 晋升实现 (ship, type == 2) | 已收 (§4.4 舰长晋升), 本批大幅精化 |
| sub_1412A3C70 | 578 | 断言 advisor.cpp:155 + gameitemdatabase.h:142 | CAdvisor 成员分派 (loader) | 已收 §4.4.15, 本批全表互证 (13 token case 逐一吻合) |
| sub_14129F190 | 172 | 断言 advisor.cpp:255 | **CAdvisor+632 写者** (slot 成本修正 def 索引解析器) | 新 |

**CAdvisor+632 写者** (sub_14129F190): hash = sub_1424BB460(a2 串视图) → +632 = sub_141484090(qword_14333D6E8, hash) 查 def 索引; miss → 断言 "<名> has not generated cost modifier." :255 (真断言直证) + 慢路 sub_141483B40(管理器, hash, &s1, &s2, &s3) get-or-generate (3 个栈上空 SSO 出参, 返回后析构弃置)。闭环 §4.10 四制造商类别特判注册的「同源」注。

**loader 互证补细节** (sub_1412A3C70): 19482 双错误串 = "Character template <名> does not exist anymore" / "…does not have an advisor definition anymore" (sub_1424C1CA0 解析期抛出); 查库 = 名串 FNV → qword_14332EE58 (TGameItemDatabase 实例) sub_1406BD460; 模板有效性门 = tpl+16 字节, advisor 定义门 = sub_1413F0DA0(tpl)。12278 traits 循环: 元素名空 → 断言 :155 (一次性闩 byte_143389FCD); 列表块类型 ≠ 3 → "Expected start of list" 抛出; 元素名 '@' 前缀 → sub_1424C04A0 变量间接解析。19596 dynamic_template: malloc 1080 + ctor sub_1413DECC0 + sub_1401C49A0 注入 + vtable[0](obj, 1) 持有计数 + 子对象 vtable+24 解析。+16 dword 亦 ctor 清 0。

**promote-from-ranks 发射器** (sub_141451AB0; 唯二调用方 = 两条晋升链 :164/:158 = 公共收尾): Random 播种 → 双 scope (国 sub_14053B8E0 / 宿主 sub_14053B6B0), eventscope.h:193 无限循环守卫断言 → sub_14144FED0 取候选表 + sub_141450910 资格判定 → 真: Random 从候选表随机取 1 → sub_140C0EC40(国, leader, −1) (= AddTrait) + fire **"on_unit_leader_promote_from_ranks_veteran"** (scope = 国); 假: fire **"on_unit_leader_promote_from_ranks_green"** (两 on_action 名为本批新发现)。

**两条晋升链精化** (公共骨架 army/ship 平行): 国 id 取法 (army+476>0 ? +476 : +472 / ship 走 sub_140C3ACC0()+8) → sub_140BB4390 得国 → 取/建 leader (sub_1406E63B0 陆 / sub_1406E6B80 海) → **四维起始技能加成** (sub_14055E360(国+1464, &out, 键)/1e5 加到对应技能):

| 域 | modifier id (键) | 技能 | getter | setter |
|---|---|---|---|---|
| 141451020 陆 | 338 ARMY_LEADER_START_ATTACK_LEVEL | 攻击 | sub_140C15500 | sub_140C24740 |
| (同上) | 339 ARMY_LEADER_START_DEFENSE_LEVEL | 防御 | sub_140C15510 | sub_140C25580 |
| (同上) | 340 ARMY_LEADER_START_LOGISTICS_LEVEL | 后勤 | sub_140C186C0 | sub_140C260D0 |
| (同上) | 341 ARMY_LEADER_START_PLANNING_LEVEL | 计划 | sub_140C16DA0 | sub_140C26C50 |
| 141451580 海 | 342 NAVY_LEADER_START_ATTACK_LEVEL | 攻击 | sub_140C15510 | sub_140C24870 |
| (同上) | 343 NAVY_LEADER_START_DEFENSE_LEVEL | 防御 | sub_140C16DA0 | sub_140C256B0 |
| (同上) | 344 NAVY_LEADER_START_MANEUVERING_LEVEL | 机动 | sub_140C186C0 | sub_140C26200 |
| (同上) | 345 NAVY_LEADER_START_COORDINATION_LEVEL | 协同 | sub_140C165C0 | sub_140C253B0 |

(getter 家族按槽位跨域复用: sub_140C15510 = 槽1 / sub_140C186C0 = 槽2 / sub_140C16DA0 = 槽3; sub_140C15500 = 槽0 陆独用 / sub_140C165C0 = 槽4 海独用。)

- 起始等级: 键 124 ARMY_LEADER_START_LEVEL (陆) / 125 NAVY_LEADER_START_LEVEL (海) 为 0 时 → sub_141450440 随机 + 权重表拾取 (qword_1433396B0/dword_1433396BC 陆; qword_143339980/dword_14333998C 海); 海版消费 = sub_140C271B0(leader, pick+1) LevelUpTo (✓ 书); 陆版拾取结果在伪码中无可见消费者 (sub_140C1D950 只单参 LevelUp) — 待裁 (疑反编译器丢参)。
- 军史/船史双条目: sub_140C6F1E0(army, 名, &tag, 2/3) / sub_140C328E0(ship, 名, &tag, 18/19)。
- AddExperience sub_140C14950 两函同款 (经验源 = 官slot块 vtable+8 取物 +136); UI: 陆 "PROMOTED_FROM_TOOLTIP_DESC" / 海 "PROMOTED_FROM_SHIP_TOOLTIP_DESC" → sub_141451E10 (末参 1 = 陆 2 = 海)。
- **leader+3804 = 1 两函同写 = promoted_from_unit 旗** (§4.32:128 trigger is_promoted_from_unit 直读此字节 — 写者至此钉死)。
- 收尾: sub_1414507D0(leader, army+1592 / ship+2264) → sub_141451AB0 (上) → MODIFIER_FIELD_OFFICER_PROMOTION_PENALTY (606) 折扣 (qword_143337E08 × (mod+100000)/1e5, 钳 [0, 1e5]; 陆乘 army+1072、海乘 ship XP sub_140C36370/sub_140C3D780) → sub_1413EACB0 → (陆) sub_140CC6980/sub_140CD0F60 国领袖刷新 → sub_141452330(官slot, tag, type, a3) 终通知。
- 断言: :271 "Promoted an army officer to an invalid type" (a2 > 1, 闩 byte_14338A4D3) / :338 "Promoted a ship officer to an invalid type" (a2 ≠ 2, byte_14338A4D4); 门 = byte_1435E1B51。

未决: 陆版起始等级权重拾取消费者 (疑反编译器损形) / leader+3804 以外晋升旗位 / advisor 模板 1080B 全布局。

#### 4.4.28 师级指挥官持有件 (unit_officer_holder.cpp; 5 函闭环 — SUnitOfficerData 88B / 女指挥官 roll / 晋升门)

簇清册 (体内 cpp 锚 5/5):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_1413E9D20 | 471 | :82 断言 "Invalid officer holder" (B51, 闩 byte_14338A3C2) | 晋升门 + tooltip 构建器 (师指挥官/舰长双型) | 新 |
| sub_1413E8EA0 | 120 | :260/:275 断言 (B52) | 存档 blob 恢复指挥官 | 引用互证 (§4.32 create_unit) |
| sub_1413E9160 | 84 | :234 RNG + :242 断言 (B52, 闩 byte_14338A3C4) | 指挥官随机生成 (含性别 roll) | 新 |
| sub_1413EA7D0 | 75 | :242 同上 (闩共享) | 重摇 (去种子, 与随机生成尾半同体) | 引用互证 (§4.32 reseed) |
| sub_1413EA720 | 42 | :160 断言 "Division commander with negative seed!" (B52, 闩 byte_14338A3C3) | SUnitOfficerData 终化 (种子钳 + 名哈希) | 新 |

**宿主内嵌点**: 1672B 师对象 (ctor sub_140C6D470) **+1272** (ctor 尾即摇); 另一宿主 +2120 (门 = gs+2617 战役活跃总门); ⚠ 本簇两体判的禁随机门 = **gs+2613 读档/世界构建期总门**, 与 gs+2617 异义勿混 (2613≠0 ⇒ 读档期 ⇒ 禁止随机); **army+824 带 vtable 子对象 vtable[2] 返回 holder 指针** (§4.32 reseed/create_unit 通路互证闭合)。

**holder 布局**: +8 宿主回指 (vtable[4] → 属主国) / +32 指挥官种子 (RNG & 0x7FFFFFFF) / +40 名串 / +72 32B 子对象 (类型未定名) / **+104 性别旗 (1 = 男)** / +108 名 FNV / +112 vector\<SUnitOfficerData\> 存档 blob (恢复 = 弹出 [0])。**SUnitOfficerData 88B** (RTTI 实名): {+0 vtable, +8 种子, +16 名串, +48 32B 子对象, +80 性别旗, +84 名哈希}。

**随机生成 roll (定案)**: `女% = (BASE_FEMALE_DIVISIONAL_COMMANDER_CHANCE qword_143336DD8 + mod 607)/1e5` (mod 607 = MODIFIER_FEMALE_DIVISIONAL_COMMANDER_CHANCE); **+104 = (种子%100 >= 女%) = 男旗**。恢复: blob 弹出五字段拷入; 种子 0 时非世界构建期 (gs+2613 == 0) 重摇兜底 / 读档期断言 :275 (存档必须带种子)。惰性分派 (簇外邻件): blob 有 → 恢复; gs+2613 → 恢复; 否则随机。**gamestate 访问前置 (新增机制点, 推定)**: 两体在双断言 (gamestate.h:1116 "gamestate unitilialized" / :1117 "Current thread is forbidden") 前走 `_dyn_tls_on_demand_init` + *(TLS+2144) 初始旗 = 线程局部 gamestate 懒初始化探针 (_ThreadForbidCount 在 TLS+16); 本簇 debug 门 = **B52** (byte_1435E1B52), 非 §4.4.27 晋升链的 B51 — 同文件域两门并存勿混; ReRoll (sub_1413EA7D0) 伪码双参签名的 a2 仅喂 TLS 探针, 业务未用 (真签名单参)。

**晋升门 + tooltip** (sub_1413E9D20; type < 2 = 师指挥官 / == 2 = 舰长): 额外经验 = 官slot块 +136 (§4.4.27 同址); 志愿军门 (+472 ≠ +480 ∧ 非同原初国) / 远征军门 (+476 > 0) 各拒; **惩罚比 = sub_141450210(国) = FIELD_OFFICER_PROMOTION_PENALTY × (1 + mod 606/1e5) 钳 [0, 1e5] — §4.4.27 同式的函数级钉死**; CP 成本 = sub_1406F1950 (§4.3 领袖招募成本同函) 对 cc+496 command_power, 不足拒。

未决: BFS 搜索核展开规则 (§4.24.18) / 1672B 师对象全布局 / 备用宿主身份 (推定舰长 ship 侧) / holder +72 子对象类型 / feature id 57 DLC 位。


**scientist_skill_levels.cpp 互证增补**: 升级结算 0x141460260 钳位上界读 dword_143339A1C (SPEED_MODIFIER 大小) 而断言边界读 dword_143339A04 (THRESHOLDS 大小) — 两静态同值依赖 :292 大小约束 (SPEED_MODIFIER = THRESHOLDS+1)。⚠ tooltip 0x14145F590 **无满级分支** (姊妹 0x14145EA40 有 _MAX 分支): 满级时 THRESHOLDS[level] 断言触发 / release 尾后读 — 是否上层保证不满级调用待裁 (运行时探针可定)。

#### 4.4.29 CUnitLeaderTraitsDB 库装载器 (unitleadertraits.cpp; 1 函 = 0x140AE6950, 定案)

0x140AE6950: token 门 **12276 = leader_traits** 主循环 + 14533-14536/15152 五技能桶 (全对 ref token 表); 条目 **'@' 写回**; ctor sub_140AE3C60 / 重载 sub_140AE6E10 书已收互证; 唯一调用方 sub_140AEA720 = §4.4 装载本体 (s4_04:734 邻域)。

#### 4.4.30 角色族函数补遗（13 函）

| VA | 语义/证据 |
|---|---|
| 0x141463CD0 | sub_141463CD0 ref.h:83 断言 + CHARACTER / PROJECT / SPECIAL_PROJECT_SCIENTIST_ALREADY_ASSIGNED（角色-项目科学家分配检查） |
| 0x1413F0E70 | sub_1413F0E70 character_template.cpp:279 "tries to cumulate 2 times the same advisor type (...). Last occurrence will override."（角色模板顾问类型累积检查） |
| 0x140AE7940 | sub_140AE7940 gameitemdatabase.h:142 + NAME / ENABLES_ABILITY（角色特质启用能力条目） |
| 0x14179C9F0 | sub_14179C9F0 gamestate.h:1125 + ref.h:83 + THEATER_COMMANDER_MASTERY_SKILL（将领/战区指挥官技能） |
| 0x141C73CE0 | sub_141C73CE0 CUnitLeaderTraitItem vtable + unit_leader_(exile_)trait_entry（将领特质条目 UI） |
| 0x1410E8870 | sub_1410E8870 体内构造/操作 vtable 类 CCountryCharacters::SAdvisorSlotInfo（&CCountryCharacters::SAdvisorSlotInfo::vftable）→ 角色模板/顾问槽信息/科学家任命命令 |
| 0x141447A30 | （未命名）pdx_scopedptr.h:134 断言 + 串 "NO_AWARDABLE pdx_scopedptr.h:134 断言 + 串 "NO_AWARDABLE_HISTORY_ENTRIES"/"CANNOT_AWARD_TO_EXPEDITIONARY"（勋章/远征授奖历史） |
| 0x141697600 | （未命名）loc 串 OPEN_ARMY_LEADER_PREFERRED_TACTIC_ loc 串 OPEN_ARMY_LEADER_PREFERRED_TACTIC_SELECTION（将领偏好战术） |
| 0x14145FE80 | sub_14145FE80 科学家技能等级系统（SCIENTIST_SKILL_LEVEL） |
| 0x1417BC120 | sub_1417BC120 将领偏好战术选择 loc 键 OPEN_ARMY_LEADER_PREFERRED_TACTIC_SELECTION |
| 0x1413F0B50 | sub_1413F0B50 体内构造/操作 vtable 类 CCharacterTemplate（&CCharacterTemplate::vftable）→ 角色模板/顾问槽信息/科学家任命命令 |
| 0x141528CC0 | sub_141528CC0 将领经验类型错误路径（"unexpected XP type"） |
| 0x140C28550 | CUnitLeader::AddTriggerDynamicVariable? 陆军师模板/将领经验与技能/单位领袖/OOB/部署（CUnitLeader::AddTriggerDynamicVariable?） |

#### 4.4.31 角色族函数补遗（5 函）

| VA | 语义/证据 |
|---|---|
| 0x140AE6070 | （无名）TRAIT_MODIFIER_FOR_ADVISOR_RANK + RANK/TEXT 键 x3（顾问特质 rank 描述） TRAIT_MODIFIER_FOR_ADVISOR_RANK + RANK/TEXT 键 x3（顾问特质 rank 描述） |
| 0x140C16430 | 无名大函数 0x140C16430 loc 键 UNITLEADER_IS_EN_ROUTE（单位领袖途中状态） |
| 0x1414466E0 | CUnitMedal::[0] CUnitMedal::[0] + vtable/RTTI 类 CUnitMedal; vtable/RTTI 含 CUnitMedal; 被 CUnitMedal::[0] 等 1 命名函数调用 |
| 0x141BE68D0 | vtable/RTTI 类 COperativeMissionData sub_141BE68D0 + vtable/RTTI 类 COperativeMissionData |
| 0x1406B4DE0 | CCharacterManager::[0] CCharacterManager::[0] + vtable/RTTI 类 CCharacterManager; vtable/RTTI 含 CCharacterManager; 被 CCharacterManager::[0] 等 1 命名函数调用 |

#### 4.4.32 角色族函数补遗（7 函）

| VA | 语义/证据 |
|---|---|
| 0x1414E64F0 | 顾问生成数据校验 顾问生成数据校验；断言 \"Advisor data contains invalid trait names %s\"（character_advisor_generation_entry.cpp） |
| 0x1402F63B0 | "high command/political_advisor" 顾问角色 "high command/political_advisor" 顾问角色 §4.4 角色/将领/特工 |
| 0x140FD1190 | "POLITICS_ADVISOR_NAME_PATTERN/NAME/SURN "POLITICS_ADVISOR_NAME_PATTERN/NAME/SURNAME" 顾问姓名生成 §4.4 角色/将领/特工 |
| 0x141F18D80 | "SCIENTIST_RECRUIT_COST_NOT_ENOUGH/SCIEN "SCIENTIST_RECRUIT_COST_NOT_ENOUGH/SCIENTIST_RECRUIT_COST/AM §4.4 角色/将领/特工 |
| 0x1411A5ED0 | （未具名） "Trying to call CCharacter::GetUnitLeaderRole on a nonexisting character" + AR-26311 + political_party.cpp:287 |
| 0x141449000 | "MEDAL_COMBINED_DESCRIPTION/LOCATION/TYP "MEDAL_COMBINED_DESCRIPTION/LOCATION/TYPE/DESC" 勋章 §4.4 角色/将领/特工 |
| 0x1411A9470 | "Invalid trait token:/Needs 1 trait toke "Invalid trait token:/Needs 1 trait token as argument" + CGu §4.4 角色/将领/特工 |

#### 4.4.33 角色族函数补遗（11 函）

| VA | 语义/证据 |
|---|---|
| 0x1412A11D0 | （无名，按证据定性） 键 COMMAND_POWER_CAP_ADD_ADVISOR + VALUE（指挥点上限/顾问）+ SSO 串构造 |
| 0x141160390 | （无名，按证据定性） 键 UNIT_LEADER_ADD_ADVISOR_DESC + NAME/ROLE/COST（长官/顾问描述） |
| 0x1402F3EA0 | 角色列表提示角色类型 "character has an unrecognized role type in character_list_tooltip." + political_advisor，country_character_effect_implementation.cpp:82 |
| 0x141443FC0 | （无名，按证据定性） program.cpp:444 断言 Scientist.GetScientistRole()（科学家角色判定） |
| 0x140C18AA0 | 特质学习 LEARNING_TRAITS + NAME/PERC |
| 0x140C10AB0 | CUnitLeader::[17] vtable 槽 CUnitLeader::[17]（func_names RTTI 名） |
| 0x140C0D2A0 | （无名） 体设 CUnitLeader::vftable（RTTI 名） |
| 0x140C11CE0 | CUnitLeader::[19] vtable 槽 CUnitLeader::[19]（func_names RTTI 名） |
| 0x140C1D550 | CUnitLeader::[16] vtable 槽 CUnitLeader::[16]（func_names RTTI 名） |
| 0x1406B4DA0 | CCharacter::[0] vtable 槽 CCharacter::[0]（func_names RTTI 名） |
| 0x140C0EB90 | CUnitLeader::[0] vtable 槽 CUnitLeader::[0]（func_names RTTI 名） |

#### 4.4.34 角色族函数补遗（11 函）

| VA | 语义/证据 |
|---|---|

#### 4.4.35 角色族函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x140C0F8F0 | CUnitLeader::AddTriggerDynamicVariable? func_names 名 CUnitLeader::AddTriggerDynamicVariable? |
| 0x140C1B1C0 | CUnitLeader::UpdateLocalizedName func_names 名 CUnitLeader::UpdateLocalizedName |

#### 4.4.36 角色族函数补遗（2 函）

| VA | 语义/证据 |
|---|---|

#### 4.4.37 角色族函数补遗（124 函）

| VA | 语义/证据 |
|---|---|
| 0x14137BDE0 | （无名） 调用图传播: 11 锚点投 §4.4（73%） |
| 0x1411CAF00 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x14225F450 | （无名） 调用图传播: 9 锚点投 §4.4（100%） |
| 0x141928320 | （无名） 调用图传播: 8 锚点投 §4.4（100%） |
| 0x1406B36B0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1402C66A0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140BC4600 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1402C6350 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140AF5CC0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141FF6200 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14203EBC0 | （无名） 调用图传播: 4 锚点投 §4.4（75%） |
| 0x141EDE6F0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x141EDF2A0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x141773C30 | （无名） 调用图传播: 6 锚点投 §4.4（67%） |
| 0x140A90090 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140CA3200 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x14203F3F0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x141774B70 | （无名） 调用图传播: 9 锚点投 §4.4（89%） |
| 0x141DE1DE0 | （无名） 调用图传播: 8 锚点投 §4.4（100%） |
| 0x141EDD8D0 | （无名） 调用图传播: 7 锚点投 §4.4（86%） |
| 0x140A90250 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x1417D47B0 | （无名） 调用图传播: 5 锚点投 §4.4（100%） |
| 0x1417D4D60 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x14203EF40 | （无名） 调用图传播: 9 锚点投 §4.4（89%） |
| 0x141DFC9B0 | （无名） 调用图传播: 8 锚点投 §4.4（100%） |
| 0x140AFBA40 | （无名） 调用图传播: 5 锚点投 §4.4（100%） |
| 0x141283730 | （无名） 调用图传播: 18 锚点投 §4.4（100%） |
| 0x14203EA00 | （无名） 调用图传播: 6 锚点投 §4.4（83%） |
| 0x141EDD1C0 | （无名） 调用图传播: 5 锚点投 §4.4（80%） |
| 0x140AFBFC0 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x1417D49E0 | （无名） 调用图传播: 6 锚点投 §4.4（100%） |
| 0x1424E23A0 | （无名） 调用图传播: 11 锚点投 §4.4（91%） |
| 0x1417D50D0 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x1402F7960 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141929220 | （无名） 调用图传播: 13 锚点投 §4.4（92%） |
| 0x141AE5210 | （无名） 调用图传播: 6 锚点投 §4.4（100%） |
| 0x14137BA20 | （无名） 调用图传播: 13 锚点投 §4.4（92%） |
| 0x141AE5620 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x141774070 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140AFBC20 | （无名） 调用图传播: 6 锚点投 §4.4（100%） |
| 0x141EDF7A0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141774470 | （无名） 调用图传播: 8 锚点投 §4.4（100%） |
| 0x141AE5810 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x14137B860 | （无名） 调用图传播: 9 锚点投 §4.4（89%） |
| 0x140AFC540 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x141283560 | （无名） 调用图传播: 12 锚点投 §4.4（100%） |
| 0x141EDCBB0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141DE16D0 | （无名） 调用图传播: 10 锚点投 §4.4（80%） |
| 0x1412833C0 | （无名） 调用图传播: 6 锚点投 §4.4（100%） |
| 0x14230E550 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x14137B570 | （无名） 调用图传播: 5 锚点投 §4.4（80%） |
| 0x14225F9D0 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x141624A40 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x1417D4BC0 | （无名） 调用图传播: 6 锚点投 §4.4（100%） |
| 0x141DE1A90 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x1424E2580 | （无名） 调用图传播: 14 锚点投 §4.4（86%） |
| 0x1409CA450 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1402DCE30 | （无名） 调用图传播: 4 锚点投 §4.4（50%） |
| 0x140543640 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x14139F020 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x1409D3980 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140A342B0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140A34700 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140A34170 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140E7ADD0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140A92800 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140A8EBB0 | （无名） 调用图传播: 4 锚点投 §4.4（50%） |
| 0x140C1A950 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140C2D490 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141DFE710 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x1423A9A80 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x1417CBDA0 | （无名） 调用图传播: 4 锚点投 §4.4（75%） |
| 0x141B03F00 | （无名） 调用图传播: 4 锚点投 §4.4（50%） |
| 0x140A35480 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140A373F0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x1402F3410 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1412AA190 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141DFFF10 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x1423A9890 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141923660 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140CBC6B0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x1414A61E0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x14235B2C0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140A05CE0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141774E70 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14192DE70 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x141339020 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140C1A0C0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140C10C10 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140C1A830 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141774DD0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14196A3F0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141B04B70 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140E573E0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x142282350 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x14066DEC0 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x141284050 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x141DE20C0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141DE2030 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141283FD0 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x141761A00 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140C0F0E0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141BD8AD0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140A0ADB0 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x142289DF0 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x1410E6520 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14137C160 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14137C1F0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1406815B0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140A35580 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x140C8B140 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140FA5060 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x14052E6E0 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x141929D40 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140FA64C0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141929CE0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14225F780 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x14225F7F0 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x14052EE40 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1424E2E50 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1424E2EB0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140C14E80 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141A2CD40 | PayloadWriter 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141A2CB10 | PayloadWriter 调用图传播: 2 锚点投 §4.4（100%） |

#### 4.4.38 角色族函数补遗（20 函）

| VA | 语义/证据 |
|---|---|
| 0x1402499E0 | sub_1402499E0 角色立绘分析（character portraits） |
| 0x141A84940 | sub_141A84940 角色意识形态文本函数（![MD] 文档串） |
| 0x141A99A60 | sub_141A99A60 单位将领技能文本函数 GetLeaderSkill（![MD] 文档串） |
| 0x141E394C0 | 域关键词匹配 sub_141E394C0 + 域关键词匹配; 被调源码 clausewitz |
| 0x141832E30 | 域关键词匹配 sub_141832E30 + 域关键词匹配; 源码路径 hoi4; 被 CEmptyEntryListBase<COperativeBottomBarItem>::[0] 等 1 命名函数调用 |
| 0x141A9A410 | sub_141A9A410 将领性别代词文本函数 GetHerHimCap（![MD] 文档串） |
| 0x141A84F10 | sub_141A84F10 角色姓名文本函数（![MD] 文档串） |
| 0x1411EC940 | 调用图上游传播(占 100%, 1 票) sub_1411EC940 + 调用图上游传播(占 100%, 1 票) |
| 0x1419DEA90 | 域关键词匹配 sub_1419DEA90 + 域关键词匹配; 被 NOperativeMissions::CPropaganda::GetTooltip 等 1 命名函数调用 |
| 0x1406B5D60 | sub_1406B5D60 串:Failed to generate a portrait for divisional commander or sh |
| 0x1411F57A0 | 域关键词匹配 sub_1411F57A0 + 域关键词匹配; 被 NOperativeMissions::CBoostIdeology::GetEstimatedDays 等 1 命名函数调用 |
| 0x1406C77E0 | 同区段近邻 CCharacterManager::[0](距 0x12A00)属 4.4 族 sub_1406C77E0 + 同区段近邻 CCharacterManager::[0](距 0x12A00)属 4.4 族 |
| 0x141441F20 | 同区段近邻 CUnitMedal::[0](距 0x47C0)属 4.4 族 sub_141441F20 + 同区段近邻 CUnitMedal::[0](距 0x47C0)属 4.4 族 |
| 0x1406BABC0 | 域关键词匹配 sub_1406BABC0 + 域关键词匹配; 源码路径 clausewitz; 被 CCharacterManager::[2] 等 1 命名函数调用 |
| 0x141C6B4A0 | 域关键词匹配 sub_141C6B4A0 + 域关键词匹配 |
| 0x1410D32A0 | 调用图上游传播(占 100%, 1 票) sub_1410D32A0 + 调用图上游传播(占 100%, 1 票) |
| 0x1411EF220 | 调用图上游传播(占 100%, 1 票) sub_1411EF220 + 调用图上游传播(占 100%, 1 票) |
| 0x1410E8590 | 调用图上游传播(占 38%, 4 票) sub_1410E8590 + 调用图上游传播(占 38%, 4 票) |
| 0x1410D33B0 | 调用图上游传播(占 100%, 1 票) sub_1410D33B0 + 调用图上游传播(占 100%, 1 票) |
| 0x1411EF770 | 调用图上游传播(占 67%, 2 票) sub_1411EF770 + 调用图上游传播(占 67%, 2 票) |

#### 4.4.39 角色族函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x141955710 | 无名 · "OPERATIVE_INVALID_MISSION_REASON_ "OPERATIVE_INVALID_MISSION_REASON_INELIGIBLE_STATE" |
| 0x14007FD40 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140080680 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140A078A0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |

#### 4.4.40 角色族函数补遗（4 函）

| VA | 语义/证据 |
|---|---|
| 0x1402994B0 | 业务逻辑（见证据锚） "Consumed/Granted XP of all kinds to"（单位领袖经验授予） |
| 0x14071DF20 | 业务逻辑（见证据锚） "Leader traits loaded '…' #"（国家领袖特质 DB 载入） |
| 0x14157B600 | 业务逻辑（键 on_operative_recruited） "on_operative_recruited"/"%s: Cannot recruit operative %s (%i:%i)"（特工招募事件） |
| 0x141E841C0 | COperativeMapIconEntry 特工地图图标条目 (vtable类名 COperativeMapIconEntry) vtable引用 COperativeMapIconEntry vftable |

#### 4.4.41 角色族函数补遗（25 函）

| VA | 语义/证据 |
|---|---|
| 0x14139E460 | （无名） 调用图传播: 13 锚点投 §4.4（54%） |
| 0x140AF5970 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x14066CCA0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x140A32D10 | （无名） 调用图传播: 7 锚点投 §4.4（86%） |
| 0x14191E140 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x14191DD40 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x141EE0BF0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x14203E820 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x140687C10 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x141335E10 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141773870 | （无名） 调用图传播: 6 锚点投 §4.4（100%） |
| 0x140A32410 | （无名） 调用图传播: 7 锚点投 §4.4（57%） |
| 0x141460580 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141773F20 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x140AFB280 | （无名） 调用图传播: 4 锚点投 §4.4（100%） |
| 0x141774F10 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x14006EEA0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x1424E2290 | （无名） 调用图传播: 4 锚点投 §4.4（75%） |
| 0x141EDC430 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |
| 0x140A34680 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x14145F520 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141460690 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x141DFF560 | （无名） 调用图传播: 3 锚点投 §4.4（67%） |
| 0x14145F4E0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |
| 0x1414600A0 | （无名） 调用图传播: 2 锚点投 §4.4（100%） |

#### 4.4.42 角色族函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x14203F620 | （无名） 调用图传播: 3 锚点投 §4.4（100%） |
| 0x140A02DD0 | （无名） 调用图传播: 2 锚点投 §4.4（50%） |

#### 4.4.43 角色族函数补遗（42 函）

| VA | 语义/证据 |
|---|---|
| 0x140F547F0 | 无名 sub_（断言站点/串定位） 串字面量 "hover_operative_build_network_target" |
| 0x1402F6840 | 无名 sub_（断言站点/串定位） 串字面量 "EFFECT_CHARACTER_LIST_SKILL" |
| 0x1416F1780 | 无名 sub_（断言站点/串定位） 串字面量 "LEADER_SKILL_AT_CAP" |
| 0x141E3F7A0 | 无名 sub_（断言站点/串定位） 断言站点 operativesorderbar.cpp:80 |
| 0x140B49230 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_leader_unknown" |
| 0x141AC2230 | 无名 sub_（断言站点/串定位） 串字面量 "UNIT_LEADER_ADD_ADVISOR_HAS_ROLES" |
| 0x140D8AE00 | 无名 sub_（断言站点/串定位） 串字面量 "FACTION_LEADER" |
| 0x140B2CBD0 | 无名 sub_（断言站点/串定位） 串字面量 "ALERT_OPERATIVE_READY_TO_RECRUIT_INSTANT" |
| 0x14123ABE0 | 无名 sub_（断言站点/串定位） 串字面量 "leader_details_container" |
| 0x141C708F0 | 无名 sub_（断言站点/串定位） 串字面量 "PREFERRED_TACTIC_CHARACTER_SELECTION_LIST_HEADER" |
| 0x141A33830 | 无名 sub_（断言站点/串定位） 串字面量 "LEADER_NAME" |
| 0x1406B5670 | 无名 sub_（断言站点/串定位） 断言站点 character_manager.cpp:180 |
| 0x141A8B6E0 | 无名 sub_（断言站点/串定位） 串字面量 "GetCommunistLeader" |
| 0x141A8B8F0 | 无名 sub_（断言站点/串定位） 串字面量 "GetDemocraticLeader" |
| 0x1416DA110 | 无名 sub_（断言站点/串定位） 串字面量 "LEADER_PROXIMITY_MODIFIER_PCT" |
| 0x140B48950 | 无名 sub_（断言站点/串定位） 串字面量 "GFX_leader_unknown" |
| 0x1419534C0 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_NO_INTEL_NETWORK_" |
| 0x14123AED0 | 无名 sub_（断言站点/串定位） 串字面量 "leader_picture_container" |
| 0x1402AAF60 | 无名 sub_（断言站点/串定位） 串字面量 "REQUEST_EXP_NOT_LEADER" |
| 0x1419E01F0 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_NO_INTEL_NETWORK_" |
| 0x14002CA30 | 无名 sub_（断言站点/串定位） 串字面量 "Checks if the scientist of the character in scope " |
| 0x141478E20 | 无名 sub_（断言站点/串定位） 串字面量 "DIPLOMACY_ASSUME_FACTION_LEADERSHIP_NOT_SUBJECT_PR" |
| 0x1419E0100 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_INTEL_NETWORK_TOO" |
| 0x141DF3810 | 无名 sub_（断言站点/串定位） 断言站点 leadergroupsview_attachmentitems.cpp:55 |
| 0x141DF2E50 | 无名 sub_（断言站点/串定位） 断言站点 leadergroupsview_attachmentitems.cpp:108 |
| 0x141DF2DA0 | 无名 sub_（断言站点/串定位） 断言站点 leadergroupsview_attachmentitems.cpp:91 |
| 0x141AC2520 | 无名 sub_（断言站点/串定位） 断言站点 unitleaderwindow.cpp:4055 |
| 0x141956DA0 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_CANNOT_TARGET_SEL" |
| 0x140FC3FD0 | 无名 sub_（断言站点/串定位） 断言站点 operativemission.cpp:293 |
| 0x1413F02F0 | 无名 sub_（断言站点/串定位） 断言站点 character_enums.cpp:24 |
| 0x141956CE0 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_CANNOT_TARGET_SEL" |
| 0x14195C2A0 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_NOT_A_CONTROLLER_" |
| 0x14195A840 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_INTEL_NETWORK_TOO" |
| 0x140C1FFC0 | 无名 sub_（断言站点/串定位） 串字面量 "LEADER_DEPLOYMENT_COMMAND_POWER_ALLOCATOR" |
| 0x141ACA180 | 无名 sub_（断言站点/串定位） 串字面量 "UNIT_LEADER_SEARCH" |
| 0x1402715B0 | 无名 sub_（断言站点/串定位） 串字面量 "Operatives are now avoiding detection" |
| 0x1419580E0 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_NOT_AN_ALLY" |
| 0x141ACA210 | 无名 sub_（断言站点/串定位） 串字面量 "UNIT_LEADER_SEARCH" |
| 0x141AC9EB0 | 无名 sub_（断言站点/串定位） 串字面量 "UNIT_LEADER_SEARCH" |
| 0x141958050 | 无名 sub_（断言站点/串定位） 串字面量 "OPERATIVE_INVALID_MISSION_REASON_NOT_AN_ALLY" |
| 0x141AC9F40 | 无名 sub_（断言站点/串定位） 串字面量 "UNIT_LEADER_SEARCH" |
| 0x140C1B260 | 无名 sub_（断言站点/串定位） 串字面量 "LEADER_DEPLOYMENT_COMMAND_POWER_ALLOCATOR" |

#### 4.4.44 角色族函数补遗（56 函）

| VA | 语义/证据 |
|---|---|
| 0x1402C6D60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1401FE3A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140EC9480 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1409ECA40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141AA8CC0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.4 |
| 0x141AE4DF0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x142283090 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140D19C20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141B17ED0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141AB22D0 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.4 |
| 0x14191DF80 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140EBB8F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141AB3210 | 无名 sub_（调用图定位） 调用图传播: 4/4 锚点投 §4.4 |
| 0x141EDFA40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141EDFB60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1413CF130 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140C14EB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141EDBE50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140A72220 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141EDBF70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140ED27F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140A929C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140D7F670 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1411CAE40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141338F50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140AB3DB0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140CB6280 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1423AA050 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140C19A00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1423B3220 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1402C87F0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140FC3F20 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.4 |
| 0x14225FB30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141EDF9B0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140A88C70 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140CA3FE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1411EF440 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1411DC4A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141EDF910 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140C91FD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141EDC7D0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140A32FE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1417D54A0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140D7F5E0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140EE2B00 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141DE2130 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140622330 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140B00C60 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140EC3D20 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140C27BD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140EC3E40 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140A71800 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x14148EC50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140BE1FD0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x141332F30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x14240BCE0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |

#### 4.4.45 角色族函数补遗（6 函）

| VA | 语义/证据 |
|---|---|
| 0x140A6F530 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.4 |
| 0x1413412C0 | 无名 sub_（调用图定位） 调用图传播: 2/2 锚点投 §4.4 |
| 0x1411C8F50 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x14122EB30 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x1412302C0 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |
| 0x140D18990 | 无名 sub_（调用图定位） 调用图传播: 单锚点投 §4.4 |

#### 4.4.46 角色族函数补遗（2 函）

| VA | 语义/证据 |
|---|---|
| 0x140293ED0 | 肖像设置 剪影肖像开关："Silhouette portraits ENABLED"/"DISABLED" + "An error occurred" |
| 0x140A7FB50 | 特工调试 特工调试信息：a1+1416 容器查询 + "[debug] no strategic operative" |
