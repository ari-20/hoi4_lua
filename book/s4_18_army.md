

### 4.18 陆军师族 (CArmy / CDivisionTemplate / requests / 部署 CDeployment 与 conveyor 三层)

师/铁路炮容器访问:

| 容器 | 位置 | 元素 |
|---|---|---|
| 师容器 | {data@cc+656, count@cc+668} | CArmy* (8B/项); 双重 vtable 校验 `*(d) == 0X295A2B0 且 *(d+16) == 0X295A490` |
| 铁路炮容器 | {data@cc+680, count@cc+692} | 8B 指针元 |

任意地址/id 对 → 师对象: `Runtime.division_at(addr)` (mk_div 公开) / `Runtime.unit_division(ty, id)` (idreg 解析 + vt1/vt0 双校验 + raw = res−16 调整); volunteers/exile 不再走 DivMT 跨国借用。

#### 4.18.1 CArmy (师对象)

| 项 | 值 |
|---|---|
| 挂载 | 师容器 {data@cc+656, count@cc+668} 元素, CArmy* 8B/项 |
| vtable RVA | vt0 0X295A2B0 / vt1 0X295A490 (双重校验 `*(d)==0X295A2B0 且 *(d+16)==0X295A490`) |
| writer | **vt1[2] 0X140C90550** (先调 CUnit writer 0X140C06540, §4.18.5; 0X1414B59B0 系产线族 writer, 与 CArmy 无关) |
| loader | 派生 loader = vt1[4] 0X140C8C7E0 (default → CUnit loader 0X140C02AE0) |
| ctor / dtor | 0X140C6D470 / real dtor 0X140C6D8A0 |
| 行为槽 | vt0[46] = 0X140C7D9B0 = combat width getter (师统计/UI 消费) |

⚠ vt1 槽函数 this = ser = raw+16 (vt0/普通方法 this = raw, 混用即错 16B)。

loader 解析即弃键 (writer 发射 / loader 解析即弃 — 运行时重算, 不落字段):

| 键 | token |
|---|---|
| strength | 10406 |
| experience | 11930 |
| organisation | 11979 |
| dig_in | 11991 |
| strategic_redeployment | 11995 |
| fuel (值) | 12003 |
| str_damage_from_air | 14156 |
| str_damage | 14157 |
| org_damage | 14158 |
| dig_in_cap | 13562 |
| max_supply | 14915 |
| fuel_requested | 15298 |
| supply_gain | 19692 |
| army_current_supply_ratio | 19693 |
| out_of_supply_days | 13151 |
| killed | 13164 |
| killer_definition | 13556 |
| leader | 10423 |
| bonus | 10931 |
| script_id | 19349 |
| execute_order | 12353 |
| unit_controller_pause | 13754 |

loader-only legacy 键 (writer 不发射):

| 键 | token | 备注 |
|---|---|---|
| start_manpower_factor | 13196 | loader-only legacy |
| start_experience_factor | 13548 | loader-only legacy |
| supplies | 12004 | loader-only legacy; 版本门 |
| division_template | 12112 | loader-only legacy; 按名 |
| force_equipment_variants | 13787 | loader-only legacy (+1472 块, 见主表) |

主表 (偏移升序):

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +24 | uint32 | type (id 对 .type) | 定案 (CArmy writer 链上不发射 +24/+28, name/name_order 双读行删) | |
| +28 | uint32 | id | 师 id (by_id 键) | |
| +29..+479 | — | CUnit 基类域 | id 对尾 3B / CReferenceObject 簿记 u8@+32 (ctor 清 0) / CSupplyConsumer 起始 u32@+40 (ctor 置 0) / motorization@+45 / 基类容器与日期族; 完整布局见 §4.18.5 | |
| +480 | u32 | **logical_country** (i32 tid → 串表; 消费实证, 与 §4.18.5 CUnit 公共段 +480 定案同源 — §4.31.46 借调东道国比对同读此槽) | 非 division_name override 串 — writer 实证 division_name 键目标 = raw+832 名称持有对象, +480 无任何名称写入通道 | |
| +481..+495 | — | pad | = +480 u32 (ctor 写 *a3; 转交/来源标记) 尾 pad (481..487) + 496 location 指针前 pad (488..495) | |
| +496 | 匿名结构 (NNB 形状) | location 对象指针 1 | 省 idx = uint32@对象+164 | |
| +504 | 匿名结构 (NNB 形状) | previous 指针 | writer token 0x29A3 (非 "location 对象指针 2") | |
| +512 | uint32 | path 容器数据指针 — / full_path | full_path 门 = uint32@+556 ≠ 0 | |
| +513..+523 | — | = path 容器 {d@512, cap@520, c@524, alloc@528} 的 data 尾 + cap@520..523 (ctor sub_14011DF40(a1+512)) | | |
| +524 | u32 | path 容器计数 | (+544 系 full_path 数据) | |
| +525..+543 | — | = path count@524 尾 (525..527) + alloc@528..535 + u32=0@536 (ctor) + full_path@544 前 pad (540..543) | | |
| +544 | uint32 | full_path 数据指针 | writer tokens 372/13868 | |
| +545..+575 | — | = full_path 容器 {d@544, cap@552, c@556, alloc@560} 内部 (545..567) + u32=0@568 + pad + movement_progress@576 前 | | |
| +576 | fixed×1e-5 | movement_progress | token 0x28A4 = 10404; 门 = *(a+560) ≠ 0 才写 (实测样本 7.7022) | |
| +577..+685 | — | = movement_progress 尾 (577..583) + qword=1@584 + qword=0@592 + MSVC 串 name {buf@600, size@616, cap@624=15} + 容器 {d@632, cap@640, c@644, alloc@648} + 对象指针@656 (=sub_140A3C0A0) / @664 + qword 零 @672/+680 + exile@686 前 pad (ctor 直读) | | |
| +686 | uint8 | exile | 均 ≠0 写 yes; 0x2D0D(11533 exile)@ser+670 | |
| +687 | uint8 | strategic_redeployment (11995) | ≠0 写; loader 解析即弃 | |
| +688 | uint8 | move_capital | 0x2B5F(11103 move_capital)@ser+672 (o = ser+16); GRE/USA/ENG 4 师 move_capital=yes 实证 | |
| +824 | 内嵌多态成员 | vt@+824 的 16B 槽成员 | CHeldOfficer+8 回指它 (ctor `*(a1+1280)=a1+824`) | 不序列化; **语义定名 = 师版 CHeldOfficer 内联** (CDivisionCommanderWindow 枚举链: cc+656 师容器 → 本字段, 与 CShip+2120 舰版同构 — §4.31.44 舰长数据源同族); GUI: 任职军官经验 getter (成员→vt[1]→对象+136; HISTORY_EXPERIENCE_COUNT_TEXT / ARMY_FIELD_OFFICER_EXPERIENCE_GAIN_TOOLTIP, +32 = Update 变更侦测) |
| +832 | CDivisionNameHolder 族* | 师名持有对象 | malloc 0xB0 ctor sub_1409BFEC0; 键 name(0x1B)/division_name(0x3904) 共同目标; 国家唯一性注册 "The division name is occupied"; SetFakeIntelTemplate 经 sub_1409C8A90 注册 | ADEC0 委托 |
| +840 | CEquipmentVariantPool 内嵌 64B | equipment 块 | vt@840, vec1 {data@848, cap@856, count@860, alloc@864} 24B 元, vec2 {data@872, cap@880, count@884, alloc@888}, allow_zero u8@896 (ctor 0X14100C710, 师 +1472/船空侧同型) | ADEC0(0x2F4E); allow_zero_entries 门 = u8@+896 |
| +904 | vector 24B | 装备构成类别计数表 | {data@904, count@916, alloc@920} — 师×模板类别合并计数 cavalry/armor/rocket/artillery/motorized/mechanized/infantry/special_forces | 不序列化; GUI: 装备构成 8 类 tooltip (BuildTooltip → sub_140B9D860, ⊕ 模板 data+168 容器) |
| +928 | vector 24B | 未名 | {data@928, count@940, alloc@944} | 不序列化; 形态定案/未名 |
| +952 | CDivisionTemplate* | template 引用 | template_id = uint32@对象+12 (§4.18.4) | |
| +960 | CDivisionTemplate* | old_template 引用 | 同上 | GUI: 改编待生效指示 (≠0 → template_change_icon 显; @64[2] 0X1416AD770) |
| +968 | CDivisionTemplate* | fake_intel_division_template_id (19404) | 断言 `_pFakeIntelDivTemplate` 实名 (0X140C8E010 读写 +968) | writer/loader/断言三通道 |
| +976 | 内嵌块基 = **CArmyManpower** (vt 0x14295A130, sizeof 80) | army_manpower 块 | 键 manpower (10300) = 填充此容器, 清后按 owner tag 重填; value 容器@+984 (army_manpower_value, token 14075), need 容器@+1016 (army_manpower_need, token 14076); 容器 = CArmyManpowerValues 内嵌 {data@+8, count@+20} 8B 条 {tag_id u32@0, value uint32@4}; ctor sub_140C67BD0(a1+976, a1) | ADEC0(0x36FA); value>0 才写 |
| +992 | vector ×2 | manpower 块内嵌 vector 对 | {data, count@+12, alloc@16} (+992/+1024) | 不序列化; 形态高置信 |
| +1056 | fixed×1e-5 | strength | tok 10406; init = 10000000 (1e7); TakeDamage 0X140C8F510 递减; loader 解析即弃 | |
| +1064 | fixed×1e-5 | organisation | tok 11979; init = 1e7 同 strength | |
| +1072 | fixed×1e-5 | experience | tok 11930; loader 解析即弃 | |
| +1080 | fixed | 0-init 标量, 未名 | str_damage_from_air 前一槽 | 不序列化 |
| +1088 | fixed×1e-5 | str_damage_from_air (tok 14156) | >0 才写; TakeDamage `+=` | |
| +1096 | fixed×1e-5 | str_damage (tok 14157) | >0 才写 | |
| +1104 | fixed×1e-5 | org_damage (tok 14158) | >0 才写 | |
| +1112 | fixed×1e-5 | dig_in (tok 11991) | >0 才写; vt0[19] 0X140C78B00 读 | |
| +1120 | fixed×1e-5 | dig_in_cap (tok 13562) | >0 才写 | |
| +1128 | fixed×1e-5 | _vAverageEquipmentStatus 平均装备状态 | init 100000 — 断言串实名 (CalculateActiveUnitStats 0X140C8D600 写 +1128 + 断言 `_vAverageEquipmentStatus = `) | 不序列化 |
| +1136 | fixed×1e-5 | bonus (tok 10931) | >0 才写 | |
| +1144 | CArmyRequests* | requests q | 块门 = q+68 \|\| q+172 \|\| q+196 (= 门函数 sub_14150D490); owner 变更先删旧; 族详见 §4.18.3 | |
| +1152 | 内嵌 CGameDate 16B 形 | date#1 | {vt@1152, hours@1160}, init = 43791240 ("−1.1.1.1" 合法日期, dword_143086B20); 0X140C89F10 `*(a1+1160)=*(gs+1128)` (疑战斗/到达事件时间戳) | 不序列化; ⚠ 24B vt1 位与 +1144 冲突 — 未决 |
| +1168..+1183 | — | **out_of_supply_days 计数器区** | 定案: writer 键 13151 ← raw+1176; 日 tick sub_140C78B00 重置/自增直证; 旧「date#2 真日期」行删 (无日期消费) | writer 按 +1176 u32 天数发 |
| +1176 | uint32 | out_of_supply_days (tok 13151) | 同上; loader 解析即弃 | >0 才写 |
| +1180 | u32 | execute_order (tok 12353) | >0 写; loader 解析即弃 | |
| +1184 | u64 | 0-init 未名 | | 不序列化 |
| +1192 | u32 | was_paradropped (tok 12008) | 值 = 全局计数 dword_143335314 快照 | >0 写 |
| +1196 | u32 | unit_controller_pause (tok 13754) | vt0[18] 0X140C881D0 消费 | ≠0 写 |
| +1200 | u32 | 0-init 未名 | | 不序列化 |
| +1208 | 内嵌块 | acclimatization 块基 | ctor sub_1406140A0; cold/hot 两槽 | tok 14417, 非空才写 (门 sub_140614BC0) |
| +1216 | vector 24B | 未名 | {data@1216, count@1228, alloc@1232} | 不序列化; 形态定案/未名 |
| +1272 | 匿名结构 (NNB 形状) | officer wrapper (officer 键) | officer 子块载体, 布局见下方 officer 子表 | writer 槽1 0X1413EACF0 (经 wrapper 对象 vt; ship 侧由 0X140C3E6C0 对 sh+2120 虚调用实证); 先写内嵌 officer[1] 再遍历追加向量 → savefull `officer[2]/officer[3]…` (追加向量非仅读档入口, 多军官舰实证) |
| +1408 | fixed×1e-5 | held_officer | 随军军官 experience | |
| +1416 | 匿名结构 (NNB 形状) | 位置共享宿主回指 | 宿主同带 +1424/+1436 数组, 析构互摘; SetLocation 比较 `*(host+496)==*(this+496)` 才同步 | 不序列化; 形态定案/语义推定 (战斗/运输宿主) |
| +1424 | vector 24B | 位置跟随子对象指针数组 | {data@1424, count@1436, alloc@1440} (SetLocation 遍历对每元素 sub_1414D0F10 广播) | 不序列化; 形态定案/语义推定 |
| +1448 | u64 ×3 | 0-init 三元组 | +1448/+1456/+1464; 容器形态推定, dtor 不杀 = POD 元 | 不序列化 (推定) |
| +1472 | CEquipmentVariantPool 内嵌 64B | force_equipment_variants 块 | +840 同型; vec1 {data@1480, cap@1488, count@1492, alloc@1496}, vec2 {data@1504, cap@1512, count@1516, alloc@1520}, u8@1528 | loader-only legacy 键 13787, writer 不发射 |
| +1536 | fixed×1e-5 | max_supply (tok 14915) | init = 100000×dword_143331604; loader 解析即弃 | |
| +1544 | fixed×1e-5 | supply_gain (tok 19692) | init 0; loader 解析即弃 | |
| +1552 | fixed×1e-5 | army_current_supply_ratio (tok 19693) | init = 100000×dword_143331604; loader 解析即弃 | |
| +1560 | u8 | fuel 加载置位旗 | loader case 12003 解析值即弃 + 置 1; ctor=0 | 不序列化; 行为定案/语义推定 |
| +1568 | fixed×1e-5 | fuel (tok 12003) | loader 值不落字段 | ≠0 才写 |
| +1576 | fixed×1e-5 | fuel_requested (tok 15298) | loader 值不落字段 | ≠0 才写 |
| +1584 | uint8 | leader (有/无; tok 10423) | loader 解析即弃 | ≠0 才写; GUI: HQ 师判据 (TemplateChanger[2] 模板集按 leader==is_army_hq 匹配; 撤编 HQ 注记 + Badge 将领技能显示门) |
| +1592 | 内嵌块基 | army_history 块 | ctor sub_141445E90, CUnitMedalStore 族 0x14143xxxx 邻址互证; 布局见下方 army_history 子表 | 写门 = u32@+1644 ≠ 0; GUI: 历史页行重建 (sub_1416BEE50: +1592 块补行 0x5B0 条 + +1624 CUnitMedalStore 按键@+1064 分组 0x50 行) |
| +1656 | u32 | killed (tok 13164) | >0 才写且**连带写 killer_definition** | GUI: HISTORY_KILL_COUNT_TEXT (sub_1416BEE50) |
| +1660 | u8 | killer_definition (tok 13556) | 随 killed 门 | |
| +1664 | int32 | script_id (tok 19349) | init −1; 带符号; loader 解析即弃 | |

officer 子块布局 (raw; wrapper = **CHeldOfficer** 内嵌 @+1272, 主虚表 0x142957ED8;
  save wrapper 槽[1] sub_1413EACF0: 块序 = 内嵌 officer 记录先 → 追加向量逐元素
  (同键 officer) → held_officer 嵌套块; 自身 writer 槽[2] sub_1413EAD80 = 仅
  held_officer.experience 单字段; reader 槽[4] sub_1413EA9E0: case 11930 → +136):

| 偏移 (raw) | 类型 | 名称/语义 |
|---|---|---|
| +1272 | CHeldOfficer 内嵌 | officer 键载体 |
| +1296 | officer 记录 88B 内嵌 (wrapper+24) | savefull 第 1 个 officer 块 |
| +1384 | vector {data@+1384, count@+1396} (wrapper+112) | 追加 officer 记录 = savefull `officer[2]/officer[3]…` |
| +1408 | i64 fixed×1e-5 (wrapper+136) | held_officer.experience (>0 才写) |

officer 记录 (88B; 主虚表 0x142765628, **无独立 RTTI 类 (负定案)**; 机制 = 师
军官团历史链: 晋升/阵亡腾空为 seed=0 占位记录 (male/name 清空), 现任 = 链末
真 seed 记录; 元素基址 E):

| 偏移 (E) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| E+0 | 主虚表 0x142765628 | 记录类 (槽[1] 0X140B0EC50 save wrapper / 槽[2] 0X141A3ADA0 writer / 槽[4] 0X141A3AA00 reader) | |
| E+8 | uint32 | seed | 恒写 (0 亦写) |
| E+16 | MSVC 串 (buf@E+16, size@E+32) | name | size>0 才写 |
| E+48 | CCharacterPortraits 内嵌 (vt 0x1427655D8) | portraits {数据@E+56, 计数@E+68} | 计数>0 整块才写 |
| E+72 | 匿名结构 (NNB 形状)* | 静态共享对象 (live 恒 0x143085170) | 不序列化 |
| E+80 | uint8 | male (低字节; ctor=1) | 恒写 ("yes"/"no") |
| E+84 | uint32 | 哨兵 (恒 0xFFFFFFFF) | 不序列化 |

CCharacterPortraits 元素 P (56B; 每项 branch/size/gate/path; 块内 branch 键重名
第 2 现起 [N]):

| 偏移 (P) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| P+0 | uint32 | branch (0=civilian 1=army 2=navy 3=air 4=operative 5=scientist) | |
| P+4 | uint32 | size (0=small 1=large) | |
| P+8 | uint32 | hash/id | 不序列化 |
| P+12 | uint32 | 写门值 | ≤1 才写 |
| P+16 | MSVC 串 | 路径 | size@P+32 |

块内键序 = seed/name/portraits/male。ship 侧同构 (wrapper @ship+2120, 内嵌
@+2144, 向量 @+2232/+2244, xp@+2256, §4.16)。

army_history 子块布局 (+1592; 键 army_history; 写门 = u32@+1644 ≠ 0; ctor sub_141445E90):

| 偏移 (raw) | 类型 | 名称/语义 |
|---|---|---|
| +1624 | scoped_ptr<CUnitMedalStore> | → CUnitMedalStore |
| +1632 | CUnitHistoryEntry** | history 条目数组数据 {data@+1632, count@+1644} (写门源 = count@+1644≠0) |

CUnitMedalStore (vt 0x1429C1818, sizeof 0x268B, writer 0X14144D130; 元素基址 H = 条目):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| H+8 | 容器 data | history 条目 vector {data@+8, count@+20} → CUnitHistoryEntry (同现役条目) | |
| H+20 | u32 | history 条目计数 | |
| H+32 | CModifier | CModifier #1 | 不落盘 |
| H+224 | CModifier | CModifier #2 | 不落盘 |
| H+416 | CModifier | CModifier #3 | 不落盘 |
| H+40/+52 | 匿名结构 (元素待裁) 向量 | 普通 history_queue 容器 (不变) | |
| H+608 | uint32 | amount | >0 才写 |
| 条目+72 | u32 | 受勋调用参 | 推定 |
| 条目+104 | CUnitMedal* | unit_medals medal 定义指针 | ptr≠0 且 **ru8(def+16)≠0** 才写; 名 = MSVC 串@def+24 (size@+40); 两队列 (store history 与普通 army_history 队列) 通用, ship 条目同型顺带适用 (def 对象) |
| 条目+112 | u8 | 可受勋旗 (受勋后清 0) | 推定 |
| 条目+312 | i64 | 受勋调用参 | 推定 |

#### 4.18.2 CRailwayGun

| 项 | 值 |
|---|---|
| 挂载 | 容器 {d@cc+680, c@cc+692} 8B 指针元 (紧挨师列表 cc+656; 本类属陆军/单位族, CUnit 基类域与师/舰队单位共用) |
| vtable RVA | 0X2972228 (过滤器) |
| Serialize | 0X140E8DE80; 尾部接 CUnit::Serialize 0X140C06540 (raw = ser+16) |
| loader | — |

⚠ 0X140E527D0 系和平会议 writer (勿用); 定线锚 = token 0x341D railway_gun_name 全 dump 唯一写点 5660464 反查。

| 偏移 (raw) | 类型 | 名称 | 写门/备注 |
|---|---|---|---|
| +24 | u32 | id 对.type | |
| +28 | u32 | id 对.id | |
| +29..+311 | — | = CUnit 基类域 (writer 0X140C06540, 布局见 §4.18.5) | |
| +312 | scoped_ptr<匿名结构 (NNB 形状)> | definition → token@p+8 | GUI: StatsView 攻击/射程行 (攻击 = def+608×(1+**MODIFIER_RAILWAY_GUN_BOMBARDMENT_FACTOR**, mdef 0x24E 注册定名); 射程 = RAILWAY_GUN_POSSIBLE_RANGES[def+616], assert railway_gun.cpp:0x464) |
| +313..+823 | — | = CUnit 基类域 (同 §4.18.5) | |
| +824 | u32 | equipment id 对.type | GUI: StatsView 装备行 / ListView 条目 |
| +828 | u32 | equipment id 对.id | |
| +832 | 内嵌 | railway_gun_name (serialize 0X1409C9AC0): type u32@840, name_order@960 门≠0, is_name_ordered byte@1000 ==0 写 no, override ptr@984→MSVC@968 | |
| +833..+1007 | — | = railway_gun_name 块本体 (CNameGroupMember 族, 布局见 §4.3) | |
| +1008 | i64 fixed5 | strength | GUI: StatsView 统计行 (COMMON_MAX_STRENGTH; 命中 5 项之一: +312 def / +824 装备 / +1008 strength / +480 logical_country / CEquipment+1056 manpower) |
| +1016 | u32 | manpower (裸值) | |
| +1024 | fixed5 | max_supply | |
| +1032 | fixed5 | supply_gain | ⚠ writer 写 1034 系笔误, 探针定 1032 |
| +1040 | fixed5 | army_current_supply_ratio | |
| +1048 | u32 | repair_line id 对.type | 先于 combat |
| +1052 | u32 | repair_line id 对.id | 先于 combat |
| +1056 | idpair | combat 容器数据 (元素 8B {type@0, id@4}; 键 0x2916=10518) | 计数≠0 才写; 存档 = 命名块逐元素行内匿名 idpair → 提取器折 combat.#N (1-based 首现即编号, 同 naval_headquarter.#N) |
| +1057..+1067 | — | = combat 容器尾 | |
| +1068 | u32 | combat 容器计数 | |
| +1069..+1087 | — | = combat 容器尾 + army 前置 | |
| +1088 | CArmy* | army: p → 虚函数 0X140BEF7C0 返 *(p−16) qword idpair | |

CRailwayGun GUI 消费:

| 类 | 锚 | 内容 |
|---|---|---|
| CRailwayGunStatsView | target = CRailwayGun refid 对 @view+2672 (ctor sub_141CFF1C0 写入, +56 raw 缓存; +2680 窗 / +2688 btn_delete / +2696 type_icon / +2704 title) | 统计行 id→loc 全表 (off_1430B33F0): STAT_RAILWAY_GUN_ATTACK / ATTACK_RANGE / HOURS_TO_REDISTRIBUTE / COMMON_MAX_STRENGTH / COMMON_MAXIMUM_SPEED / ARMY_SUPPLY_CONSUMPTION |
| CRailwayGunListView | 非窗口监听器/控制器 (CTooltipHandler 2 槽 + CRailwayGunEntryListener 9 槽全定名: 单击选择/同步/加选/地图居中/脱离指挥组/开统计窗/单选; 5 glue 钮 = 批量脱离/批量取消移动/全选/批量删除确认/收集 helper) | 条目 = CRailwayGunViewEntry* 数组 {d@L+128, c@L+140} |
| 命令链 (RTTI 实名) | CUnassignRailwayGunFromOrdersGroup / CCancelMovementCommand / CConfirmDeleteUnits / CChangeRailwayConstructionLeveLCommand | — |
| CRailwayMapIcon | 正名 = 铁路(轨道)图标, 非铁路炮图标 (§4.30.16) | — |

候选新偏移 (定案): gun+12 = **CSelectable 选中字节** (IsSelectable 断言 railway_gun_view.cpp:0x1A3 + 双 listener 直读; id 对在 +24/+28, 重叠虑不成立); gun+680/+684 = **transfer_offset_1/2** (writer 13986/13987 门≠0, loader 读弃 = 运行时重算族); gun+1088 = **army 转化** (writer 键 10397, idpair 经对象虚函数; 见上表)。

#### 4.18.3 requests 全族 (q = *(div+1144); writer 0X1415103C0)

**块门 = `q+68 || q+172 || q+196`** (逐字 = 门函数 sub_14150D490 `a1[17] || a1[43] || a1[49]`):
三者全 0 ⇒ 该师在存档里**整块不存在** (连 date 也没有); 任一 ≠0 才写块, 块内
date 无条件写 (writer 尾部 ADEC0(0x284A) 无门)。⚠ date @q+224 是**写就残留**的
(置位后不清), 故"date 有值"**不能**反推块存在 —— AI 托管后大量师 date 仍有效
而三门外全 0 (实测 14/14), 按 date 判存在会整批 MISS_SAVE。

**族实名与造物点**: 根 q = **CArmyRequests** (RTTI vt 0x1429D2080, sizeof 240); 内嵌子对象 = **CArmyReinforcementRequests** (96B @q+16, 主 vt 0x1429D1DC0 / pers 0x1429D1DF8) + **CArmyUpgradesRequests** (128B @q+112, 主 vt 0x1429D1F70 / pers 0x1429D1FA8) — **date 实体 = upgrades 子对象尾部 CGameDate 24B** (q+224 属 upgrades, 「date 写就残留」由此归属解释); 后端 = cc+3960 CReinforcementStatus / cc+3952 CDeploymentStatus 双指针 (ctor 路由)。运行时请求创建 = **0x141507410** (reinforcement.cpp 族; 调用者 0x14150F740 gamestate 分发) = AI 托管写入门; 驻军变体 = **CGarrisonReinforcementRequests** (72B, 宿主 CStateGarrisonData+8, 块键同 reinforcement, writer 0x141510520, 创建点 0x141507740); 请求元素实名 = **CReinforcementRequest** (sizeof 176); delivery 元素 = **CUpgradeDelivery** (96B, CEquipmentDistributable@0 + CEquipmentDelivery@8)。

顶层键:

| 键 | token | 位置/量纲 |
|---|---|---|
| date | 10314 | hours i32 @ q+224 (序列化基 q+232) |
| reinforcement | 12609 | 容器 @q+40 (writer 0X141510290) |
| upgrades | 12393 | 容器 @q+136 (writer 0X141510430) |

reinforcement 容器 (C = q+40):

| 键 | token | 容器 | 元素 |
|---|---|---|---|
| manpower_pool | 13877 | {data@C+48, count@C+60} | 16B {tag uint32@0, value int64@8} |
| request | 12613 | {data@C+16, count@C+28} | 指针 e; 序列化基 B = e+24 (布局见下请求元素表) |

请求元素 (writer 0X1415105B0, a1 = B):

| 键 | token | 位置 | 写门 |
|---|---|---|---|
| status | 208 | uint32 @B+8 | ≠0 |
| progress | 11013 | fixed×1e-5 @B+16 | status==1 |
| total_progress | 13818 | fixed×1e-5 @B+24 | ≠100000 |
| produced | 12204 | 对象 @B+32 (writer 0X141012DB0) | 非空 |
| need | 12111 | 对象 @B+96 (writer 0X141012D40) | 非空 |
| date | 10314 | hours @B+136 | 序列化基 B+144 |

produced / need 对象:

| 对象 | 匿名结构 (元素待裁) 向量 | 元素 16B | 写门 |
|---|---|---|---|
| produced (P) | {data@P+32, count@P+44} | {variant 指针, amount int64} | amount≠0 或 allow_zero (uint8@P+56); id 对 = {type@variant+8, id@variant+12} |
| need (N) | {data@N+8, count@N+20} | {定义指针, amount int64} | 键 = token@定义+8; amount≠0 才写 |

upgrades 容器 (U = q+136):

| 键 | token | 容器 | 元素 |
|---|---|---|---|
| request | 12613 | {data@U+24, count@U+36} | 24B 内联 {variant@+0, request int64@+8, total int64@+16}; equipment_variant_index (13891) = variant 的 id 对 (非 0 才写) |
| delivery | 13231 | {data@U+48, count@U+60} | 指针 e → **CUpgradeDelivery** (sizeof 96: status@+8 / progress@+16 / total_progress@+24 同请求元素 CEquipmentDelivery 形态 / produced@+32; writer 0x141510680 / reader 0x14150F100) |

#### 4.18.4 CDivisionTemplate

国家挂载容器 {data@cc+440, count@cc+452}; 全局容器 {data@*(gs+1776), count@*(gs+1788)}; vtable 0X294F5B0; 布局基 d = 对象+24。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | u32 | id.type — id 对之 type (对 {type, id}) | |
| +12 (对象基) | u32 | id.id — id 对之 id | |
| d+8 | string (SSO) | name | |
| d+40 | string (SSO) | localization_key | |
| d+72 | 匿名结构 (元素待裁) 向量 | regiments 网格 | 探针定案: {列数 u16@+0, 列高(宽度) u16@+2, data@+8, count@+20}; 元素 ptr: +8 兵种 token, +16 有效标志; 坐标 x=slot//列高, y=slot%列高 (非方格 (列数≠列高) 时旧读 +0 低 u16 全错) |
| d+104 | 匿名结构 (元素待裁) 向量 | support 网格 (布局同 regiments) | 序列化键 12188 |
| d+136 | 匿名结构 (元素待裁) 向量 | regimental_support 网格 (布局同 regiments) | 序列化键 16871; regiments 本尊键 = 12195 |
| d+296 | 容器 {data@296, count@308} | 装备模块引用数组 | 键 13657, 元素 CIdentifier 经专键 13891 逐条写 |
| d+320 | 容器 {data@320, count@332} | 思想/学说 def 指针数组 | 键 19914, 元素写 *(def+8) u32 于键 19015 |
| d+368 | CIdentifier 8B (+372 尾) | parent 模板引用 | 键 135 (与装备变体母本同键), 双 dword 非零才写 |
| d+396 | uint32 | priority | 键 141 |
| d+424 | int32 | template_counter | u32 位型读后转符号; 键 13549 |
| d+428 | uint8 | ingame_set_template_counter | |
| d+429 | uint8 | allow_new_equipment | 键 13656 (恒写) |
| d+430 | uint8 | allow_foreign_equipment | |
| d+436 | uint8 | is_army_hq | 键 16913; **GUI: 设计器格重排** (sub_14168B430 → hq_view/non_hq_view) **+ TemplateChanger 模板集过滤键** |
| d+448 | uint32 (门 d+452) | role 名引用 (token 名串) | 键 14279 (与输送带 role 同键), 经 token 名反查写串 |
| d+468 | uint32 | country (tid → 串表) | 键 10394 |
| d+472 | uint32 | original_tag (tid → 串表) | 键 13649 |
| d+476 | uint32 | foreign_template_tag (tid → 串表) | 键 15038 (流亡 tag 键复用) |
| d+480 | uint32 | origin_type (0=无 1=subject) | 键 15039 块头 (殖民模板 effect 写 1, §4.18.6) |
| d+488 | i64 (门 d+496) | 未名标量 | 键 16902 |
| d+504 | string SSO (门 d+520) | 未名串 | 键 15089 |
| d+540 | uint8 | is_fake_intel_division | 键 19403 |
| d+541 | uint8 | is_locked | 键 14766 |
| d+542 | uint8 | obsolete | 键 12396; **GUI: TemplateChanger 滤** (锁+过时+HQ 三滤; sub_14169D590) |
| d+552 | hours | obsolete_change_date | 门 = obsolete b@542 且 ≠ 哨兵 0x29C77F8 ("1.1.1.1") (token 0x2BA0); writer 另发键 11168 嵌套对象 (体 a1+560 起, 哨兵 dword_143086B50) |
| d+568 | uint8 | 未名旗 | 键 12290 (真才写) |
| d+572 | uint32 (门 d+576) | 未名标量 | 键 19944 |
| d+580 | int32 | 未名标量 (char 型写) | 键 19904 |
| 未名恒写 | — | writer 另恒发 bool 键 19913 / 13605 | 无独立落点 (读侧常量) |

#### 4.18.5 CUnit 公共段 (writer 0X140C06540 / loader 0X140C02AE0, ser = raw+16)

全部师/铁路炮/舰队单位共用; writer 25 键 + loader 逐键互证; ctor/dtor 补 runtime-only 区。10 键「writer 发射 / loader 解析即弃」运行时重算族见 §4.18.1 弃键表。

| 偏移 (raw) | token | 字段 | 写门/备注 |
|---|---|---|---|
| +24 | — | id 对.type | 恒写 |
| +28 | — | id 对.id | 恒写 |
| +29..+95 | — | = id 对尾 3B + **CReferenceObject 簿记 u8@+32** + **CSupplyConsumer u32@+40** (0) + **motorization@+45 / 伴生 byte@+46 (=1)** + 三定点 100000 @+48/+56/+64 + **+72 = sub_1424EF6F0(100000)** + +80=100000 + qword 零 @+88/+96/+104 + 容器@96 头 (子对象 ctor sub_140BF8700, 基 = raw+16) | |
| +96 | CSupplyConsumer* 向量 | CSupplyConsumer 基类域容器 | 形态定案/语义未名 (基类域, dtor 直读) |
| +113..+231 | — | = 容器@96 尾 (113..119) + qword 零区 +120..+183 + **CUnit 子对象 vftable@+184** (COrdersGroupMember 视口, vt 0x142953320) + +192..+231 (40B, CUnit 子对象前段; **+192 = _pOrdersGroup** = member+8 拥有者军群回指, 写入 COrdersGroup reader sub_140BF30A0 `*(unit+192)=this` RTDynamicCast CUnit 链定案) | |
| +232 | 匿名结构 (元素待裁) 向量 | 未名 | 定案 (ctor/dtor) |
| +257..+279 | — | = **容器 {d@256, cap@264, c@268, alloc@272}** 内部 (上邻 +232 / 下邻 +280 两容器间的第三容器, ctor sub_14011DF40(a1+256)) | |
| +280 | 匿名结构 (元素待裁) 向量 | 未名 | 定案 |
| +304 | 12002 | disengage (u32) | signed>0; **loader 解析即弃** (运行时重算族) |
| +308 | 12005 | possible_retreat (u32) | 随 disengage>0 同写; loader 解析即弃 |
| +312 | CSubUnitDefinition* | **师统计对象** (ctor sub_141018D00 置 CSubUnitDefinition vftable = 合成形态对象, a2=类型 id −1; 0x678B 族 — 与师设计器预览统计对象同类; **统计数组 @对象+160 起 8B/项 × 78 statId, 枚举全表见 §4.31.27**; 对象另有 +816..+976 五统计组与 +1040 CModifier; 清零 sub_140B63730; **聚合 = CArmy::CalculateActiveUnitStats sub_140C8D600 → 聚合核 sub_140B9AD70 → 逐 statId 后处理 sub_140C6F960, 见 §4.31.27**) | **GUI: 师详情三栏统计行** (§4.31.27: 24 行中 20 行读本缓存; 硬度 BuildTooltip 0X1416A2270 读 对象+184 statId 3 = 装甲度 fixed5; SOFT_ATTACK_TAKEN = 1e5−值) |
| +320 | CGameDate vt | start_date 对象头 {vt@320, h@328, 代理 vt@336} | 日期对象 24B 双 vt 定案 (ADEC0 hours=arg−8 多证) |
| +328 | 0x28E0 | start_date (i32 小时) | 门 h∉[43800000, 43817520) 双哨兵带 |
| +344 | CGameDate vt | end_date 对象头 {vt@344, h@352, 代理@360} | 定案 |
| +352 | 0x28E1 | end_date (i32 小时) | 同 start_date 门 |
| +353..+367 | — | = end_date CGameDate {vt1@344, hours@352, vt2@360} 的 hours 尾 (353..359) + vt2 (360..367) — 全在日期对象内 | |
| +368 | 匿名结构 (24B 形状) 向量 | **滚动累加事件队列** — 24B 元 {u32@0, i64@8, i64@16}; 推入时累进 +392..+416 (dword_1430B132C 切乘/加模式) | 形态+机制定案 (0X140BF97C0 全文); 业务名推定 (战斗损伤/修正事件族) |
| +392 | i64 fixed5 | **累加器 A** (ctor=0, dtor 归位 100000=1.0) | 高置信形态/推定语义 |
| +400 | i64 fixed5 | 累加器 B | 同上 (战斗内取 100*(+400*+416/1e5)) |
| +408 | i64 fixed5 | 累加器 C | 同上 |
| +416 | i64 fixed5 | 累加器 D | 同上 |
| +417..+423 | — | = **累加器 D** i64 @416 尾 7B | |
| +424 | 匿名结构 (元素待裁) 向量 | **combats 进行中的战斗指针数组** (8B 指针元) | 定案 — RemoveFrom(combat) 表空则 last_combat_date=当前时刻 (0X140C03E00); 9 函数遍历互证 |
| +448 | CGameDate vt | last_combat_date 对象头 {vt@448, h@456, 代理@464} | 定案 |
| +456 | 0x2FDF | last_combat_date (u32 小时) | **i32 ≠0**; 哨兵 43808760 也写 "1.1.1.1" (探针) |
| +472 | tag u32 | **owner tag** (运行时, 不序列化; ctor = *a3, UI 归属判断比较) | 高置信; **GUI: 撤编按钮门回退** (expeditionary_owner==0 → 用本值; sub_1416BE4F0) |
| +476 | 11997 | expeditionary_owner (tag u32 → 串) | signed>0; **上界 = tag 表 count (gs+868) 非国数** (实测 tag id 可 > country_count); **GUI: 撤编按钮文案/门** (远征师换远征按钮组+旗签; sub_1416BE4F0 → DISBAND_ALL_UNIT / DISBAND_BUTTON_HQ_WITHDRAW_NOTE / SPECIAL_UNIT_CANNOT_BE_DISBANDED) |
| +480 | 0x3410 | logical_country (i32 tid → 串表) | tid>0 且 < **tag 表 count (gs+868)** — ⚠ **非国数**: tag id 由 tag 表槽分配, 实测 339 vs country_count 333, 用国数当界会漏尾部动态 tag (D06 一类); **GUI: 借调东道国 tag 比对** (借调双 StripView 存在谓词 = 元对象+480 == 目标国 tag; cc+760/cc+784 idreg 链) |
| +488 | 0x2EDA | **support_attack** → u32@obj+164 | kptr 门 (writer 键 0x2EDA=11994 + loader case 11994 + 存档键序 `previous→support_attack→last_combat_date` 实证; 双师共享 id 306) |
| +496 | 0x286D | location → u32@prov+164 | kptr 门 (unit.cpp:297 错误串铁证) |
| +504 | 0x29A3 | previous → u32@obj+164 | kptr 门 |
| +512 | 372 | path 容器数据 {cap@520, alloc@528} — u32 密集 → 单行 .#1 | count>0; loader 越界剔除 (≥ *(gs+700) 省数删尾) |
| +524 | u32 | path 容器计数 | count>0 |
| +536 | u32 | 零星标量 (ctor 置 0) | 定案清零/未名 |
| +544 | 13868 | full_path 容器数据 {cap@552, alloc@560} — 同 path | count≠0 才读 |
| +556 | u32 | full_path 容器计数 | count≠0 才读 |
| +568 | u32 | 零星标量 (ctor 置 0) | 定案 (ctor 置 0) |
| +576 | 0x28A4 | movement_progress (i64×1e-5; token 10404) | ≠0 (实测样本 7.7022); **loader 解析即弃** |
| +584 | 14268 | move_priority 枚举 {0=front_order, 2=player_order, 3=ai_player_order, 余 normal} | ≠1 (ctor 置 1); loader legacy override_move → 映射 0/1 |
| +588 | — | retreat (u8) | ≠0 写 yes; **loader 解析即弃** |
| +589 | — | withdraw (u8) | ≠0 写 yes; loader 解析即弃 |
| +592 | qword | 零星标量 (ctor 置 0) | 定案 (ctor 置 0) |
| +600 | — | name (MSVC {buf@600, size@616}) | size≠0 且 !sub_1424BFF30; 虚函数 SetName (raw vt+320) |
| +616 | u32 | name size | SSO 内部 |
| +624 | u32 | name cap | SSO 内部 |
| +625..+631 | — | = name MSVC 串 cap@624 尾 7B (串 {buf@600, size@616, cap@624}) | |
| +632 | 12009 | country_intel 容器数据 {cap@640, alloc@648} — 24B 元 {tid u32, val u32, u8@+16} → 单行 .#1 | count>0 |
| +644 | u32 | country_intel 容器计数 | count>0 |
| +656 | 匿名结构 (NNB 形状) | (ctor sub_140A3C0A0 创建) | 形态定案/语义未名 |
| +664 | 匿名结构 (NNB 形状) | (ctor sub_1416434C0 带 unit 回指; 消费 sub_14055E360, 参与 ×6 倍率公式) | 形态定案/推定语义 |
| +685 | uint8 | **管理器注册旗** (置位且 qword_14333D3E0 非空时 dtor 反注册并清零) | 形态+机制定案/管理器身份未名 |
| +686 | — | exile (u8) | ≠0 写 yes; **loader 解析即弃** |
| +688 | 0x2B5F | move_capital (u8; 旧名 exile_capital 误名, 存档无此键) | ≠0 写 yes; loader 解析即弃 |
| +696 | 0x36A2 | **transfer_offset_1** (u32) | ≠0 (writer 键 0x36A2=13986); **loader 解析即弃** |
| +700 | 0x36A3 | **transfer_offset_2** (u32) | ≠0 (writer 键 0x36A3=13987); loader 解析即弃 |
| +704 | 203 | commandlist 容器数据 {cap@712, alloc@720} — 多态命令对象指针数组; 逐元动态键 = token u32@(elem+8) + AD590 多态序列化 | count≠0; 工厂 sub_141234C70(键 token) 创建 |
| +728 | qword | 零星标量 (ctor 置 0) | 定案 (ctor 置 0) |
| +736 | 内嵌 32B 结构 | {容器@736 + qword 标量@760} 未名 | 定案 |
| +768 | 内嵌结构 | 容器 {d@776, cap@784, c@788, alloc@792} @+8 起, 未名 | 定案 |
| +800 | 匿名结构 (NNB 形状) | **raid 族运行时对象** (dtor sub_140F66990 反注册; 断言门) | 高置信 |
| +808 | 0x2997 | seed (u32) | ≠0; **loader 解析即弃** |
| +812 | 0x4AEF | raid_instance id 对.type | 任一≠0 且 sub_14221F310 校验有效 (对) |
| +816 | 0x4AEF | raid_instance id 对.id | 任一≠0 (对) |

commandlist 族: {d@+704, cap@+712, c@+716, alloc@+720} 四元组补齐 + 两个动作类 (units 侧内联, 布局未入册)。

CUnit 公共段补充: sunk_ship.killer_name = MSVC @entry+160 **恒写含空串** (存档 98/98 实例; 0x40 reader 同源); last_combat_date (+456) / logical_country (+480) 见上表。

#### 4.18.6 殖民地编制模板 (CCreateColonialDivisionTemplateEffect / CReferencedDivisionTemplate)

⚠ 负定案: 二进制不存在名为 CColonialDivisionTemplate 的类 (RTTI 8,755 类全扫零命中; 全文唯一相关符号 = CCreateColonialDivisionTemplateEffect)。「殖民地编制模板」= 打了 subject 标记的普通编制模板, 与全部模板同容器同序列化路径, 无独立 writer/段。

effect 入口:

| 项 | 值 |
|---|---|
| 类 | CCreateColonialDivisionTemplateEffect |
| token | 10055 `create_colonial_division_template` |
| vtable RVA | 0x142768E28 |
| sizeof | 0x68 |
| ctor | 0X14033CF70 |
| 基类 | CAddDivisionTemplateEffect |
| +88 | CDivisionTemplateData* — Parse 0X1403B17A0: token 12112 → malloc(0x248) + ctor 0X140B95480 存 +88 (12112 = `division_template` 键名, 双参数文档推断) |
| +96 | subject tag — token 13024 → sub_140BB5560 解析 tag 入 +96 (= `subject` 键, 与 origin_type 枚举名 token 13024 同 token) |

Execute (0X140350470) 五步:

| 步 | 操作 |
|---|---|
| 1 | sub_140BA5E50(数据, &subject, 1) → **foreign_template_tag@data+476 = subject, origin_type@data+480 = 1(subject)** |
| 2 | sub_1401D2E80 = malloc(0x260) + ctor 0X140B956C0 建 CReferencedDivisionTemplate |
| 3 | 数据拷入 +24 |
| 4 | division_names 库刷新 0X1409C9680 |
| 5 | 容器登记 |

落盘类:

| 项 | 值 |
|---|---|
| 类 | CReferencedDivisionTemplate |
| vtable RVA | 0x14294F5B0 |
| sizeof | 0x260 = 608 = 24B CReferenceObject 头 {vt@0, idpair {type@+8, id@+12}} + CDivisionTemplateData 内嵌@+24 (0x248) |
| writer (vt slot2) | 0X140BA6EC0 (0X142220340 头 + 委托内嵌 vt slot2 = CDivisionTemplateData writer 0X140BA6A40) |
| 存储 | 全局容器 **gs+1776** {data@1776, cap@1784, count@1788} vector\<ptr\> — 定案: CReferencedDivisionTemplate 全局容器**单义** (gamestate.cpp:3316 落盘, 元素键 12112 division_template; 库存锚 = ps+520/544 + cc+4024) |
| 提取键 | `division_template[N]` (首现不编号); 段内按 id 升序发射 (writer 物理序 = 容器序, 段排序是对拍口径) |
| 归属判别 | origin_type=1(subject) 且 foreign_template_tag = subject tag |

#### 4.18.7 CDivisionTemplateData

writer 0X140BA6A40; vt 0X14294DEC0 (RTTI: CPersistent 直接派生); ctor 0X140B95480; sizeof 0x248; 偏移基 data = wrapper+24。表行序 = 偏移升序 = writer 物理落盘序。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | MSVC SSO (size@+24) | name | 门 size≠0; tok 27; **GUI: 名字输入框** (sub_14168DF50 → DIVISION_DESIGNER_RENAME) |
| +9..+39 | — | = name MSVC SSO 32B 本体 (+8..+39) | |
| +40 | MSVC SSO (size@+56) | localization_key | 门 size≠0; tok 799 |
| +41..+71 | — | = localization_key MSVC SSO 32B 本体 (+40..+71) | |
| +72 | 格容器 | regiments {列数 u16@+0, 列高 u16@+2, data@+8, 计数@+20; 元 8B ptr: token@+8, 有效 u8@+16; x=v5/列高, y=v5%列高} | 块 **12195** (0x2FA3); 门 = 空判 !0X140FBF580(+136); 逐格 0X140B93410, `x=N y=M` 重复键; **GUI: 三网格摆格/拆格** (sub_14168E150/BF90/B600/B520 + sub_140FBF5F0 → regiments_grid 等) |
| +73..+103 | — | = regiments 格容器 32B 本体 (+72..+103) | |
| +104 | 匿名结构 (NNB 形状) | support | 块 12188 (0x2F9C); 门 = 空判 (!…(+104)); **GUI: 摆格/拆格** (同 regiments 链) |
| +105..+135 | — | = support 格容器 32B 本体 (+104..+135) | |
| +136 | 匿名结构 (NNB 形状) | regimental_support | 块 **16871** (0x41E7); 门 = 独立同谓词 `!sub_140FBF580` (至少一格占用+旗标); **GUI: 摆格/拆格** (同 regiments 链) |
| +137..+295 | — | = regimental_support 格容器@136 体 (32B 至 +167) + **容器 @168/{d@168,cap@176,c@180,alloc@184} / @192 / @216 / @240** (各 24B) + **CEquipmentArcheTypePool (ctor sub_14100C630) @264** 体 (至 +295) (ctor sub_140B95480) **— GUI: 装备原型池输入** (D+264 × cc+3944; sub_14168B9E0→sub_14100E140) | |
| +296 | 匿名结构 (16B 形状) | not_allowed_equipment (变体引用) | 块 13657 (0x3559), 门 计数≠0; AF4B0 数组, 元素 = 0X142220260(13891, obj+8) |
| +297..+319 | — | = not_allowed_equipment 16B 容器本体 + 至 +320 对齐 pad | |
| +320 | 匿名结构 (16B 形状) | forbidden_equipment_types | 块 19946 (0x4DCA), 门 计数≠0, 元素 ADFE0(19015, u32@obj+8); **GUI: 装备类别过滤** (reset_equipment_categories_filter_button 群 × D+180 可用性校验 cc+3952 → EQUIPMENT_CATEGORIES_DESC) |
| +321..+367 | — | = 容器 {d@320, cap@328, c@332, alloc@336} + 容器 {d@344, cap@352, c@356, alloc@360} 两个 24B 容器全体 | |
| +368 | 8B idpair {A@+368, B@+372} | [名未定; ctor 零; objects 层未消费] | 块 135 (0x87) + 0X142220180, 门 A≠0 ∨ B≠0 |
| +369..+395 | — | = idpair@368 (qword_14333D528 初值) 尾 + **u32=0@376 + qword=0@384 + u32=0@392** (ctor 置零) | |
| +396 | uint32 (存档 i32 形, 0xFFFFFFFF→−1) | priority | 恒写 (ADFE0 u32 通道收有符号值, −1→0xFFFFFFFF 原样出字节); tok 141 (0x8D) — ⚠ 与 template_counter (+424) 同形勿混; **GUI: 优先级按钮 0..3** (sub_14168DF80, clamp dword_143337338 → TEMPLATE_PRIO_0..2(_DESC)) |
| +397..+423 | — | = priority@396 尾 + **+400 惰性缓存指针 (qword; 运行时-only, ctor 零/writer 不触) + qword 零 @408/@416** (ctor; +400 首格缓存: getter sub_140B9F5C0 = 为 0 时取 regiments 网格 (+72) 第 (0,0) 格, 网格空 → Null Object 单例 qword_14333A210 [null_object.h]) | +400 = 首格缓存 (定案读法/推定语义) |
| +424 | int32 | template_counter (ctor = −1) | 恒写; tok 13549 (0x34ED) |
| +428 | uint8 | ingame_set_template_counter | 恒写 yes/no; tok 13605 (0x3525) |
| +429 | uint8 | allow_new_equipment (ctor 1) | 恒写 yes/no; tok 13656 (0x3558) |
| +430 | uint8 | allow_foreign_equipment (ctor 1) | 恒写 yes/no; tok 19945 (0x4DC9) |
| +436 | uint8 | is_army_hq | 门 ≠0 (yes-only); tok 16913 (0x4211); **GUI: 格重排/模板过滤** (sub_14168B430; TemplateChanger[2] 与 CArmy+1584 联动) |
| +440 | 匿名结构 (NNB 形状)* | division_names_group → 串@ptr+8 | 门 指针非空; ADF40 引号串; tok 14559 (0x38DF) |
| +448 | uint32 token (+452 有效 u8) | role | 门 b@+452≠0; 值 = token 名 (0X1424BC260) 引号串; tok 14279 (0x37C7) |
| +449..+467 | — | = +448 区尾 + qword=357@464 (none 哨兵) + pad | |
| +468 | tag_id (u32) | country — 值 = tag 名 (0X140BB4E70) | 恒写; tok 10394 (0x289A) |
| +472 | tag_id (u32) | original_tag | 恒写; tok 13649 (0x3551) |
| +476 | tag_id (u32) | foreign_template_tag — 殖民地模板在此落 subject tag | 恒写; tok 15038 (0x3ABE) |
| +480 | uint32 枚举 | origin_type — 0=master_host→15037 / 1=subject→13024 / 2=exile→11533 | 块 15039 (0x3ABF) 内写枚举原子 + 尾随原子 16; **值 ∉ {0,1,2} 整块不写** (writer 直接返回) |
| +488 | i64 (+496 门 u8; 16B 块 +488..+503) | **override_model_equipment_category_filter** (tok 16902 直名) — 16B = {i64 类别值@+488, 门 u8@+496}; getter sub_140BA04C0 原样拷 16B / GUI sub_14176EFB0 以门字节门 UI 重建; 写点 = 清空 override_model (D+504, sub_140BA6030) 后写 {源 qword, 1} (sub_14168E320→sub_140BA6050) | 门 b@+496≠0; AE760; tok 16902; objects 层未消费 (待补) |
| +489..+503 | — | = +488 fixed i64 尾 (+489..+495) + 门 u8@+496 + pad | |
| +504 | MSVC SSO (size@+520) | override_model | 门 size≠0; tok 15089 (0x3AF1); **GUI: 模型覆盖名编辑框** (0X141763F10→sub_140BA6030; division_designer_model; 脏旗 view+17705) |
| +505..+539 | — | = override_model MSVC SSO 32B 本体 (+504..+535) + pad | |
| +540 | uint8 | is_fake_intel_division | 门 ≠0 (段不发射, 20 档恒 0); tok 19403 (0x4BCB) |
| +541 | uint8 | is_locked | 门 ≠0; tok 14766 (0x39AE); **GUI: 模板锁门** (可改性总门 sub_140BA2440/93230 三键之一 → DESIGNER_LOCKED) |
| +542 | uint8 | obsolete | 门 ≠0; tok 12460 (0x306C); **GUI: TemplateChanger 滤** (sub_14169D590 三滤之一) |
| +543 | — | pad 1B (vt1@+544 前置对齐) | |
| +544 | CGameDate 24B {vt1@+544, hours@+552, vt2@+560} | obsolete_change_date (24B 闭合) | ADEC0 (ptr=vt2=+560, hours=ptr−8=+552); 门 = obsolete≠0 **且** hours@+552 ≠ 哨兵 dword_143086B50 (= 0x29C77F8 "1.1.1.1" 默认); tok 11168 (0x2BA0) |
| +568 | uint8 | force_allow_recruiting | 门 ≠0; tok 12290 (0x3002) |
| +572 | uint32 (+576 门 u8) | division_cap | 门 b@+576≠0; tok 19944 (0x4DE8); **GUI: 模板锁门第三键** (cap; DESIGNER_LOCKED) |
| +580 | int8 | equipment_niche | 门 b@+580≠0; tok 19904 (0x4DC0); **GUI: niche 图标列表** (sub_14176F490 → niche_icon_*) |

模板侧不确定点:

| 事项 | 状态 |
|---|---|
| CDivisionTemplateData +368 idpair (块 135) 的存档键名 | 未决 |
| override_model_equipment_category_filter (+488) 键名 | 定案 (游戏内 lexer 直证) |
| effect Parse token 12112 = division_template | 定案 (lexer 表直查) |
| regimental_support 块门 | 定案: 三块独立同谓词门 `!sub_140FBF580`; 键映射 72→12195 / 104→12188 / 136→16871 |

#### 4.18.8 勋章簇 (unit_medal)

unit_medal def 新锚:

| 偏移 (def) | 语义 |
|---|---|
| +152 | 图标 gfx 基名串 (实例行直用; 模板按钮 + "_large" 后缀取大图 sub_141448E00, 三源互证) |
| +184 | **unit_modifiers** 块 (reader token 14527 定案; 模板项/将领项 populate mode 0 同向选用; 块 +16 起喂 sub_140FADF60) |
| +376 | **leader_modifiers** 块 (reader token 14526 定案) |
| +568 | **ship_modifiers** 块 (reader token 10662 定案; populate mode 1 选用, 舰船用) |
| +760 | 基础花费 (无单位上下文直取, unit_medals.cpp:0x329 断言; 有单位时 ± 国修正后比对 *(cc+3984 CPolitics+224) PP, 着色 loc = MEDAL_COST_UI_POS/NEG) |
| +1068 | 图标 frame u32 (vt+176 SetFrame 三处同址) |

GUI 条目类:

| 类 | 锚 | 内容 |
|---|---|---|
| CMedalInstanceItem (vt 0X142A67410, 窗 medal_instance_entry, ctor sub_141D102A0) | target = CUnitHistoryEntry+40 内嵌子队列拷贝 → item+56 vector\<CUnitHistoryEntry*\> | +68 = count>1 时 "number" 子件带 NUM_OF_MEDALS_UI; 创建点 sub_1416BEE50 (历史页行重建互证) + sub_141BF0140 (单位详情历史段, 宿主视图精名未决 — 同 §4.31.18); tooltip glue 0X141D11420 → MEDAL_EFFECTS_TOOLTIP_DELAYED |
| CMedalTemplateItem / CMedalTemplateLeaderItem (窗 medal_button_entry; ctor sub_141D10600 / sub_141ABC380; populate sub_141D12630 / sub_141AD1DA0 逐行同构) | +64 = medal def / +72 = 授勋 ctx (ctx+8=单位, +24=mode, +32=名串; ctx 宿主 = 母窗+1448 token → 对象+2264 内嵌) | 将领版 populate sub_141ACF0C0 = 全库遍历 (0x14332F0C8, 门 u8@def+16 册双证); click 均落 **CGiveMedalCommand** (sub_141144D60 / 将领双分支 +sub_141144CE0) + default_confirmation_popup (ADD_MEDAL_TITLE/DESC) |

8 个 Item 类全部只覆写 [0] 析构 (vs 基 CStandardGridBoxItem), 真入口 = ctor + glue 子虚表槽。

#### 4.18.9 子单位条目簇

| 类 | target | 锚点 |
|---|---|---|
| CSubUnitDefinitionEntry (舰艇编成编辑器格) | entry+1376 def 指针 (宿主直写) | def+104 = 图标串; def+1448 位域 0x201 = 排除门 |
| CSubUnitInfoEntry (陆军 sub_units_grid 格) | {def id@+32, count@+36} 对 | tooltip 用 def+1448 &0x80000 (bit19) = 铁路炮分支 (与 §4.23 +1032 _Category 族邻域, 同源位域说) |
| CSubUnitSimpleEntry (单位统计格) | {双 u16 索引@+32, D 对象@+40, 模式@+48} | 命中 D+436 is_army_hq / cc+3944 CProductionStatus / D+264 装备原型池三册锚; sub_unit def+816..+976 = 五统计组 (细节未决) |

#### 4.18.10 CDeployment (部署; dep = *(cc+3952))

> **§4.18 并入说明**: 原「部署」独立分册内容按性质三向归位 —— 域对象 (CDeployment /
> 子单位加成 / conveyor 三层) 收本节 §4.18.10–§4.18.12; 其命令族收 §4.33;
> GUI 类 (舰载机编成窗 / 卡车增援行 / 两地图模式类) 收 §4.31 / §4.30。

**获取**: `dep = *(cc + 3952)` — 类身份 = CDeploymentStatus (vt 0x14295FC38; ctor sub_140D0D020 / writer sub_140D14650 / dtor sub_140D0D4C0 三源互证)。

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +8 | 匿名结构 (112B) | unit_modifiers 容器数据指针 | {data, count}, 元素内联 112B, count<64 | §4.18.11 |
| +9..+19 | — | = unit_modifiers 容器 {data@8, **cap@16**, count@20, alloc@24} 内部 (pdx 24B; ctor sub_140D0D020) |  |  |
| +20 | u32 | unit_modifiers 容器计数 |  | §4.18.11 |
| +21..+71 | — | = unit_modifiers count@20 尾 + **alloc@24** + **运行时容器#2 {data@32, cap@40, count@44, alloc@48}** (未序列化) + **std::map unlocked_subunits {head@56 (malloc 0x28 三自指哨兵), size@64}** (writer 块 token 16572 = unlocked_subunits; 节点 {key token@+28, u8@+32})  |  |  |
| +72 | CMilitaryDeploymentConveyor* | conveyors 容器数据指针 | {data, count<128} 8B 指针元; 元素布局与 GUI 消费见 §4.18.12 | §4.18.12 |
| +73..+83 | — | = conveyors 容器 {data@72, **cap@80**, count@84, alloc@88} 内部  |  |  |
| +84 | u32 | conveyors 容器计数 |  |  |
| +85..+239 | — | = conveyors count@84 尾 + **alloc@88** + **运行时容器#4 {d@96, cap@104, c@108, alloc@112}** + **#5 {d@120, cap@128, c@132, alloc@136}** (**定案 = 部署中单位列表**, CCountryDeploymentView 数据链: 玩家 tag → cc+3952 本对象) + **#6 {d@144, cap@152, c@156, alloc@160}** (均未序列化, dtor 逐个清) + **+168 = hq_next_deploy_order u32** (writer 键 16910, >0 门) + **+172/+176 = default_hq_template id 对** {type@172, id@176} (qword_14333D528 初值; writer B320 键 10667) + +180 qword 0 + +188 u32 0 + +192..239 零区  |  |  |
| +240 | CEquipmentArcheTypePool* 向量 | initial_carrier_air_wing_deployment | **CEquipmentArcheTypePool 32B (ctor sub_14100C630)** {vt@240, 容器@248 {d@248, cap@256, c@260, alloc@264}} (writer 键 13691); +272 = lambda scoped ptr (8B), 消费 sub_141980140 = 同模板已排产行数 (add_limit 上限, >9 显 MORE_THAN_NINE) | |

其余区域 = 未序列化运行时容器群 (上列 #2/#4/#5/#6 与 +56 map 之外无其他容器; 对拍工具链不消费)。

#### 4.18.11 CSubunitBonusPersistent (unit_modifiers 元素, 112B; vt 0x14295FAA8; writer 0X14197FA10)

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +0 | — | vtable 槽 | 序列化分发 (writer 首行虚调用) | |
| +8 | 静态类描述符* | 类描述符 | 指向静态描述对象 | |
| +16 | 匿名结构 (8B 形状) | stats 容器数据指针 — 列表 1 | {data, count<64}; 元素 8B 指针 → 类别对象 |  |
| +17..+27 | — | = CSubUnitStatBonus (内嵌@+8) 容器1 {data@16, **cap@24**, count@28, alloc@32} 内部 (pdx 24B; ctor sub_140641990) |  |  |
| +28 | u32 | stats 容器计数 |  |  |
| +29..+39 | — | = 容器1 count@28 尾 + **alloc@32**  |  |  |
| +40 | 匿名结构 (16B) | stats 容器数据指针 — 列表 2 | {data, count<64}; 元素 16B {静态 DB 条目指针, 对象} |  |
| +41..+51 | — | = 容器2 {data@40, **cap@48**, count@52, alloc@56} 内部  |  |  |
| +52 | u32 | stats 容器计数 |  |  |
| +53..+63 | — | = 容器2 count@52 尾 + **alloc@56**; @+64 起 type/id/number/localization_key 区  |  |  |
| +64 | uint32 | type | 枚举: 值→token 映射见下表 | |
| +68 | token | id | ≠357 才写 | |
| +72 | uint32 | number | | |
| +80 | string | localization_key | SSO; 门 = 指针@+96 ≠ 0 | |

**type 枚举** (值→token):

| 值 | token |
|---|---|
| 1 | 10022 |
| 2 | 89 |
| 3 | 16775 |
| 4 | 16778 |
| 5 | 16770 |
| 6 | 16771 |
| 默认 | 357 |

**类别对象** (列表 1 元素解引用): 类别 token uint32@+8; 内嵌 stats 子对象 @+64 (vtable@+64)。

**stats 子对象布局** (头部 24B + 主数组): 类名 = **USSubUnitStats** (RTTI `.?AUSSubUnitStats`, 主 vt 0x142789D70, 本 writer = 该虚表槽 [2]; ctor 经 sub_141018080 内嵌构造 = CSubUnitDefinition+64)

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | vtable | |
| +16 | fixed×1e-5 | factor 头 | 恒 100000 (factor 类, writer 不写) |
| +24 | fixed×1e-5 | combat_width | 主数组外独立字段 |
| +72 | 容器 | battalion_mult (48B 条) | category/add/display/stats 逐叶门 |
| +96..+719 | fixed×1e-5[78] | 主数组 | 78 槽 int64×1e-5 |
| +720 | CEquipmentArcheTypePool | **need_equipment** (tok 15244) | 池 {vt@+0, data@+8, cap@+16, count@+20, alloc@+24}; 元素 16B = {CEquipmentArchetype* @+0, 数量 i64 fixed×1e-5 @+8}; 键名 = token_name(原型+8) 装备原型名 (support_equipment / motorized_equipment); 写门 = count>0 ∧ 任一数量 ≠0 (sub_141010B70); ⚠ 池自身地址在 +720, 数据指针在 +728 (少一层解引用 = 读到池虚表) |
| +752..+912 | 地形静态块 ×5 | 地形修正 (attack/defence/movement) | 块门 = attack/defence/movement 任一非零 |
| +952 | 容器 | 动态地形容器 (40B 条) | |

78 槽 → 修饰名映射 = reader 层 STAT2TOK token id 数组。列表 2 元素的 obj: 类别 token@db+84, stats 对象 obj+64。
#### 4.18.12 conveyor 对象三层 (CMilitaryDeploymentConveyor / Line / Deployment)

**类名绑定 (1.19.3 实证)**: conveyor 元素 = **CMilitaryDeploymentConveyor** (vt 0x14295E100, ~160B, writer 0x140CEBC10 / reader 0x140CEAE70, ctor 0x140CE7070); 行包裹件 W = **CMilitaryDeploymentLine** (64B, vt 0x14295E0A8, writer 0x140CEBD60); 训练行 L = **CMilitaryDeployment** (200B, MI: CEquipmentDistributable@0 (priority@+8, ≠1 写) + CPersistent@24, vt 0x14295E020 / pers 0x14295E058, writer 0x140CEBB30 / reader 0x140CEACB0, ctor 0x140CE6DE0)。

line 包裹件 division_name: dn = *(line+32) (lines 容器 {d@cv+120}); type 恒写 / name_order@dn+128 (≠0 才写) / override SSO@dn+136 (size@dn+152 ≠0, 引号) / override_set_prog b@dn+169 (≠0 写 yes)。

conveyors 元素布局与 GUI 三视图消费 (九字段 GUI 坐实; cv = 元素基):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | idpair | id 对 | {type@+8, id@+12} |
| +32 | 匿名结构 (NNB 形状) | template | 模板侧偏移见下表 |
| +40 | string | name | SSO; GUI 消费 |
| +72 | — | amount | 0 → INFINITY 无限系列 |
| +76 | — | location | 非零 → gs+8 vt[1] → *(obj+192) → sub_1409D91D0 地名串 |
| +80 | — | priority | 0/1/2 → 三钮态 (2,1,1)(1,1,4)(1,3,1) |
| +84 | — | order_index | GUI 消费; 与 +88 orders group 配对 |
| +88 | idpair | orders group | sub_140CE9E00 → RTDynamicCast COrdersGroup 铁证 → sub_140BEAA30(group, order_index) → *(entry+56)+272 = CColor 军团色 |
| +120 | 容器 12B | lines | {d@+120, c@+132}; GUI 消费 |
| +144 | token | role |  |
| +148 | uint8 | closed | GUI 消费 |
| +152 | tag_id | government_in_exile_tag | >0 才写 (实证: ENG cv[0] tid=5=FRA); 训练 ETA 因子双 define dword_143335D10/143319D00 |

**行包裹件 W** (cv+120 / dep+120 容器元素):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | idpair | id 对 |  |
| +32 | 匿名结构 (NNB 形状) | 模板 ptr |  |
| +40 | uint32 | 当前 series 序号 |  |
| +48 | 匿名结构 (NNB 形状) | 训练行 L | 布局见下表 |
| +56 | CMilitaryDeploymentConveyor* | conveyor 回指 |  |

**训练行 L** (训练行对象):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +32 | CString 32B | equipment (tok 12110) 训练装备引用 | writer/reader 双证 (多态值 I/O); 原表未载 |
| +96 | fixed×1e-5 | 训练进度 (tok 12218) | 定点; >0 写 |
| +104 | fixed×1e-5 | 目标 max_training (tok 13078) | 100000 |
| +112 | — | 装备人力池 army_manpower_value (tok 14075) | sub_140C69830 求和; writer 0x140C6AD50 |
| +144 | — | 需求侧池 army_manpower_need (tok 14076) | reader 0x140C6A330 同容器对 |
| +176 | u32 | max_manpower (tok 10608) | >0 写 |
| +184 | 行包裹件 W* | W 回指 |  |
| +192..+195 | u32 | 停滞理由 id |  |
| +196 | uint8 | 停滞字节 | 置位 → TRAINING_HALTED; 否则人力比不足 → CONVEYOR_CAN_NOT_MANPOWER_TRAIN; 其它 → CONVEYOR_CAN_NOT_TRAIN |

需人 = 模板需人 × (cc+1464 modifier 键 222 + 100000) / 100000。

**模板侧偏移** (除名模板类 tpl):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | — | 图标/所有者上下文 |
| +400 | — | 目标人力 |
| +420 | — | 优先级图标枚举 |
| +492 | tag_id | owner tag |
| +566 | uint8 | 过时警告字节 |

⚠ sub_1406CF0F0 = cc+656 CArmy 师列表容器直返 (非「特种部队」专表)。

> **本域 GUI 类布局**: 见 4.30.2 / 4.30.26 / 4.31.19 / 4.31.27 / 4.31.46 / 4.31.48 / 4.31.53 / 4.31.91。

#### 4.18.13 CUnit / CArmy 虚表槽语义 (slot-contract)

CUnit 主 vtable 0x1429530D8 = 58 槽 (0-57); CArmy 主 vtable 0x14295A2B0 = 59 槽 (0-58)。
两表为多基布局: 主表之后紧邻次级基子对象 vftable (CUnit +16 组 13 槽 = CPersistent 系
前缀 [1]Save/[2]Writer/[3]Load/[4]Reader + AssignId/AllocateId id 机制 + 登记旗标 setter;
+184 组 8 槽 = 位置/在册状态通知 + GetOuter/GetName/GetOwner; CArmy 另有 +824 组 10 槽)
—— 次级组槽号独立, 勿与主表连续计数; 派生实体序列化前缀在次级组, 不占主表槽号。
ICF 桩身份: 0x140120540 = `return 0` / 0x1401F8A60 = `mov rax,rcx;ret` (return this) /
0x14011D220 = `return 0` / 0x1401807B0 = `return 1`。

| 槽 | 语义 | 证据 |
|---|---|---|
| CUnit [13] | GetName (返 +600 名称串首址; CArmy 覆写转向 *(+832)+96) | writer token 27 写该串 |
| CUnit [21] | IsValid (基 `return 1`; CArmy 覆写 = 战力/组织判定 NO_STRENGTH/NO_ORG) | 覆写错误键直证 |
| CUnit [24] | TakeDamage (基 = stub; CArmy 覆写 = 伤害按 defines 660-662 修正后累加损失 +1088/+1096/+1104) | 断言 "TakeDamage is not implemented for this unit type" unit.h:182 |
| CUnit [25] | TakeDamageImmediate (基 = stub) | 断言 unit.h:187 |
| CUnit [40] | SetName (a2 拷入 +600; CArmy::[40] 覆写 = 禁用断言体) | 断言 "CArmy::SetName( CString ) is forbidden to use!" army.cpp:3887 |
| CUnit [43] | HasLowSupply (基 = stub) | 断言 "Unit type has not implemented HasLowSupply" unit.h |
| CUnit [50] | Exile (基 = stub) | 断言 "Can only exile armies and railway guns!" unit.cpp |
| CUnit [51] | ReturnFromExile (基 = stub) | 断言 unit.cpp:1956 |
| CArmy [19] | GetTheatre | 断言 "GetTheatre()" army.cpp |
| CArmy [22] | RefreshAbilities | 断言 "Refreshing abilities from non-serialcontext, OOS may occur!" army.cpp:1743 |

> 待裁项暂不定名: CUnit [5] 可见性判定、[18] 复合状态刷新; 移动族 [14]-[17]/[20]
> (ExecuteMove/MoveTo/TryMove/CanMoveTo/CanEnterProvince, 错误键 NO_ACCESS_TO_TARGET 等
> 已锚 unit.cpp 但函数名系行为推定); CArmy [31]-[39] 资源对称族 (A=+1056/+33=国家+648 上限,
> B=+1064/+38=国家+640 上限, 100000 定点) 游戏语义 (org/str/人力) 未裁。
> CUnit [7]-[12] 六槽同址 `return 0` 且三派生各覆 2 槽 return this (CArmy 7/8、
> CTaskForce 9/10、CRailwayGun 11/12) = 按单位类型的转换函数族, 无逐槽直接证据, 整族不命名。
