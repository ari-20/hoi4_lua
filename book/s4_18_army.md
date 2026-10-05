

### 4.18 陆军师族 (CArmy / CDivisionTemplate / requests / 部署 CDeployment 与 conveyor 三层)

师/铁路炮容器访问:

| 容器 | 位置 | 元素 |
|---|---|---|
| 师容器 | {data@cc+656, count@cc+668} | CArmy* (8B/项); 双重 vtable 校验 `*(d) == 0X295A2B0 且 *(d+16) == 0X295A490` |
| 铁路炮容器 | {data@cc+680, count@cc+692} | 8B 指针元 |

任意地址/id 对 → 师对象: `Runtime.division_at(addr)` (mk_div 公开) / `Runtime.unit_division(ty, id)` (idreg 解析 + vtable1/vt0 双校验 + raw = res−16 调整); volunteers/exile 不再走 DivMT 跨国借用。

#### 4.18.1 CArmy (师对象)

| 项 | 值 |
|---|---|
| 挂载 | 师容器 {data@cc+656, count@cc+668} 元素, CArmy* 8B/项 |
| vtable RVA | vt0 0X295A2B0 / vtable1 0X295A490 (双重校验 `*(d)==0X295A2B0 且 *(d+16)==0X295A490`) |
| writer | **vtable1[2] 0X140C90550** (先调 CUnit writer 0X140C06540, §4.18.5; 0X1414B59B0 系产线族 writer, 与 CArmy 无关) |
| loader | 派生 loader = vtable1[4] 0X140C8C7E0 (default → CUnit loader 0X140C02AE0) |
| ctor / dtor | 0X140C6D470 / real dtor 0X140C6D8A0 |
| 行为槽 | vt0[46] = 0X140C7D9B0 = combat width getter (师统计/UI 消费) |

⚠ vtable1 槽函数 this = ser = raw+16 (vt0/普通方法 this = raw, 混用即错 16B)。

loader 键位落点表 (派生 loader 0X140C8C7E0 逐键经 sub_1424C0A70/C00 **直写字段 — 全部落字段**; ser 落点坐标 = raw+16; 载入后运行时每小时重算照常覆盖):

| 键 | token | ser 落点 | raw 字段 |
|---|---|---|---|
| strategic_redeployment | 11995 | +671 (u8) | +687 |
| bonus | 10931 | +1120 | +1136 |
| strength | 10406 | +1040 | +1056 |
| organisation | 11979 | +1048 | +1064 |
| experience | 11930 | +1056 | +1072 |
| str_damage_from_air | 14156 | +1072 | +1088 |
| str_damage | 14157 | +1080 | +1096 |
| org_damage | 14158 | +1088 | +1104 |
| dig_in | 11991 | +1096 | +1112 |
| dig_in_cap | 13562 | +1104 | +1120 |
| execute_order | 12353 | +1164 | +1180 |
| out_of_supply_days | 13151 | +1160 | +1176 |
| unit_controller_pause | 13754 | +1180 | +1196 |
| leader | 10423 | +1568 (u8) | +1584 |
| killed | 13164 | +1640 | +1656 |
| killer_definition | 13556 | +1644 (u8) | +1660 |
| max_supply | 14915 | +1520 | +1536 |
| supply_gain | 19692 | +1528 | +1544 |
| army_current_supply_ratio | 19693 | +1536 | +1552 |
| fuel (值) | 12003 | +1552 (**并置旗 ser+1544 = raw+1560 = 1**) | +1568 |
| fuel_requested | 15298 | +1560 | +1576 |
| script_id | 19349 | +1648 | +1664 |
| equipment 块 | 12110 | +824 (对象解析 sub_1424C0AA0) | +840 |
| requests 块 | 13230 | +1128 (对象解析; owner 变更守卫 = ser+456/ser+460 比对, 变则先毁旧 q + sub_140C8F3F0 重建) | +1144 |

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
| +480 | uint32 | **logical_country** (i32 tid → 串表; 消费实证, 与 §4.18.5 CUnit 公共段 +480 定案同源 — §4.31.46 借调东道国比对同读此槽) | 非 division_name override 串 — writer 实证 division_name 键目标 = raw+832 名称持有对象, +480 无任何名称写入通道 | |
| +481..+495 | — | pad | = +480 u32 (ctor 写 *a3; 转交/来源标记) 尾 pad (481..487) + 496 location 指针前 pad (488..495) | |
| +496 | 匿名结构 (NNB 形状) | location 对象指针 1 | 省 idx = uint32@对象+164 | |
| +504 | 匿名结构 (NNB 形状) | previous 指针 | writer token 0x29A3 (非 "location 对象指针 2") | |
| +512 | uint32 | path 容器数据指针 — / full_path | full_path 门 = uint32@+556 ≠ 0 | |
| +513..+523 | — | = path 容器 {d@512, cap@520, c@524, alloc@528} 的 data 尾 + cap@520..523 (ctor sub_14011DF40(a1+512)) | | |
| +524 | uint32 | path 容器计数 | (+544 系 full_path 数据) | |
| +525..+543 | — | = path count@524 尾 (525..527) + alloc@528..535 + u32=0@536 (ctor) + full_path@544 前 pad (540..543) | | |
| +544 | uint32 | full_path 数据指针 | writer tokens 372/13868 | |
| +545..+575 | — | = full_path 容器 {d@544, cap@552, c@556, alloc@560} 内部 (545..567) + u32=0@568 + pad + movement_progress@576 前 | | |
| +576 | fixed×1e-5 | movement_progress | token 0x28A4 = 10404; 门 = *(a+560) ≠ 0 才写 (实测样本 7.7022) | |
| +577..+685 | — | = movement_progress 尾 (577..583) + qword=1@584 + **生效移动令旗 u8@590** (ctor 0; 写者 = CUnitMoveAction::Execute sub_141234E30 / 下令入口 sub_1414D0F10 / AI unitcontroller 拒动协议置 1) + **拒动原因枚举 u8@680** {0=清, 1=下令非法军通, 2=CC540 败, 3=补给门, 5=寻路/海运败, 6=无落点, 7=兵力不足} (ctor 0; AI 侧写, GUI 箭头/tooltip + AI 升级 sub_14107A600 读) + **移动令目的省 qword@592** (ctor 0; 拒动协议 = 清 −1 / 拒时目标省 id) + MSVC 串 name {buf@600, size@616, cap@624=15} + 容器 {d@632, cap@640, c@644, alloc@648} + 对象指针@656 (=sub_140A3C0A0) / @664 + **CTheatre\* @672** (ctor 零, 运行时写; getter sub_140BF9660 = GetTheatre, railway_gun.cpp:676 断言直证) + qword 零 @680 + exile@686 前 pad (ctor 直读) | | |
| +686 | uint8 | exile | 均 ≠0 写 yes; 0x2D0D(11533 exile)@ser+670 | |
| +687 | uint8 | strategic_redeployment (11995) | ≠0 写 | |
| +688 | uint8 | move_capital | 0x2B5F(11103 move_capital)@ser+672 (o = ser+16); GRE/USA/ENG 4 师 move_capital=yes 实证 | |
| +824 | 内嵌多态成员 | vtable@+824 的 16B 槽成员 | CHeldOfficer+8 回指它 (ctor `*(a1+1280)=a1+824`) | 不序列化; **语义定名 = 师版 CHeldOfficer 内联** (CDivisionCommanderWindow 枚举链: cc+656 师容器 → 本字段, 与 CShip+2120 舰版同构 — §4.31.44 舰长数据源同族); GUI: 任职军官经验 getter (成员→vtable[1]→对象+136; HISTORY_EXPERIENCE_COUNT_TEXT / ARMY_FIELD_OFFICER_EXPERIENCE_GAIN_TOOLTIP, +32 = Update 变更侦测) |
| +832 | CDivisionNameHolder 族* | 师名持有对象 | malloc 0xB0 ctor sub_1409BFEC0; 键 name(0x1B)/division_name(0x3904) 共同目标; 国家唯一性注册 "The division name is occupied"; SetFakeIntelTemplate 经 sub_1409C8A90 注册 | ADEC0 委托 |
| +840 | CEquipmentVariantPool 内嵌 64B | equipment 块 | vtable@840, vec1 {data@848, cap@856, count@860, alloc@864} 24B 元, vec2 {data@872, cap@880, count@884, alloc@888}, allow_zero u8@896 (ctor 0X14100C710, 师 +1472/船空侧同型) | ADEC0(0x2F4E); allow_zero_entries 门 = u8@+896 |
| +904 | vector 24B | 装备构成类别计数表 | {data@904, count@916, alloc@920} — 师×模板类别合并计数 cavalry/armor/rocket/artillery/motorized/mechanized/infantry/special_forces | 不序列化; GUI: 装备构成 8 类 tooltip (BuildTooltip → sub_140B9D860, ⊕ 模板 data+168 容器) |
| +928 | vector 24B | **师掌握度权重向量** (每营类型 8B 定点 1e-5; 平行模板营表, 计数须 == 当前模板营数, 断言 mastery_conditions.cpp:118; §4.6.9) | {data@928, count@940, alloc@944} | 不序列化; ⚠ 待裁: StatsView Setup 三小窗 ctor 读 u32@+944/+984 (armiesview 簇) 与本行 alloc@944 / +976 行 value 容器@984 的关系未决 (标量读 vs 指针槽, 两侧读法不可同真); 元素是否已含计数聚合见 §4.6.9 U1 |
| +952 | CDivisionTemplate* | template 引用 (键 12610 division_template_id) | template_id = uint32@对象+12 (§4.18.4) | |
| +960 | CDivisionTemplate* | old_template 引用 (键 13647 old_division_template_id) | 同上 | GUI: 改编待生效指示 (≠0 → template_change_icon 显; @64[2] 0X1416AD770) |
| +968 | CDivisionTemplate* | fake_intel_division_template_id (19404) | 断言 `_pFakeIntelDivTemplate` 实名 (0X140C8E010 读写 +968) | writer/loader/断言三通道 |
| +976 | 内嵌块基 = **CArmyManpower** (vtable 0x14295A130, sizeof 80) | army_manpower 块 | 键 manpower (10300) = 填充此容器, 清后按 owner tag 重填; value 容器@+984 (army_manpower_value, token 14075), need 容器@+1016 (army_manpower_need, token 14076); 容器 = CArmyManpowerValues 内嵌 {data@+8, count@+20} 8B 条 {tag_id u32@0, value uint32@4}; ctor sub_140C67BD0(a1+976, a1) | ADEC0(0x36FA); value>0 才写 |
| +992 | vector ×2 | manpower 块内嵌 vector 对 | {data, count@+12, alloc@16} (+992/+1024) | 不序列化; 形态高置信 |
| +1056 | fixed×1e-5 | strength | tok 10406; init = 10000000 (1e7); **派生值语义**: CalculateActiveUnitStats sub_140C8D600 (army.cpp:1796) 非战斗态 SetStrength(max_str) — max_str 由人力因子 sub_140C69780 × 装备齐备率 sub_140C7F0A0 缩放; 战斗中 TakeDamage 扣减不自动回满, 补充交付后 RefreshAbilities 拉回 | |
| +1064 | fixed×1e-5 | organisation | tok 11979; init = 1e7 同 strength | |
| +1072 | fixed×1e-5 | experience | tok 11930 | |
| +1080 | fixed | **本小时 attrition 值缓存** | 每小时 sub_140C88A70: gs+2617 门开 → = sub_140C75500(attrition breakdown), 否则 0 | 不序列化 |
| +1088 | fixed×1e-5 | str_damage_from_air (tok 14156) | >0 才写; TakeDamage `+=` | |
| +1096 | fixed×1e-5 | str_damage (tok 14157) | >0 才写; **= 人力伤亡账本** (人力比例 getter sub_140C87F70 与人力补偿需求的数据源) | |
| +1104 | fixed×1e-5 | org_damage (tok 14158) | >0 才写 | |
| +1112 | fixed×1e-5 | dig_in (tok 11991) | >0 才写; vt0[19] 0X140C78B00 读 | |
| +1120 | fixed×1e-5 | dig_in_cap (tok 13562) | >0 才写 | |
| +1128 | fixed×1e-5 | _vAverageEquipmentStatus 平均装备状态 | init 100000 — 断言串实名 (CalculateActiveUnitStats 0X140C8D600 写 +1128 + 断言 `_vAverageEquipmentStatus = `) | 不序列化 |
| +1136 | fixed×1e-5 | bonus (tok 10931) | >0 才写 | UI: 计划准备度 PLAN_PREPARATION tooltip 直读此值 (armiesview 簇; UI 名「计划准备度」= 计划加成本体, 与存档键名 bonus 同物两名) |
| +1144 | CArmyRequests* | requests q | 块门 = q+68 \|\| q+172 \|\| q+196 (= 门函数 sub_14150D490); owner 变更先删旧; 族详见 §4.18.3 | |
| +1152 | 内嵌 CGameDate 16B 形 | date#1 | {vtable@1152, hours@1160}, init = 43791240 ("−1.1.1.1" 合法日期, dword_143086B20); 0X140C89F10 写 = **伞降完成时间戳** (sub_140C89F10 伞降 org 公式同函数, §4.18.15) | 不序列化; +1144 CArmyRequests* (8B) 与 +1152 相邻不重叠 (旧「冲突」系容器宽度笔误, 已解除) |
| +1168..+1183 | — | **out_of_supply_days 计数器区** | 定案: writer 键 13151 ← raw+1176; 日 tick sub_140C78B00 重置/自增直证; 旧「date#2 真日期」行删 (无日期消费) | writer 按 +1176 u32 天数发 |
| +1176 | uint32 | out_of_supply_days (tok 13151) | 同上 | >0 才写 |
| +1180 | uint32 | execute_order (tok 12353) | >0 写 | |
| +1184 | fixed×1e-5 | **org 比例缓存** (vtable[39] 写; ctor 0) — GUI: 陆军行件组织度条 = 100 × 本值 (§4.31.107) | | 不序列化 |
| +1192 | uint32 | was_paradropped (tok 12008) | 值 = 全局计数 dword_143335314 快照 | >0 写 |
| +1196 | uint32 | unit_controller_pause (tok 13754) | vt0[18] 0X140C881D0 消费 | ≠0 写 |
| +1200 | uint32 | 0-init 未名 | | 不序列化 |
| +1208 | NAcclimatization::CData 内嵌 64B | acclimatization 块 (vtable 0x1427DE000, writer 0x1406167B0 / reader 0x140616320): +8 值表矢量 16B 元 {定义指针, i64 值} (动态键 = 每元素定义对象+32 token, 未知名报 "Found unknown acclimatization token name") / +32 actively_gaining 类型指针 (14446, 读类型名回查库 qword_143330450) / +40 actively_gaining_speed (14447) / +48 other_loss (14448) / +56 max_acclimatization (14606, ctor 10000000=100.0, 仅非默认才写); 废键 14441 is_gaining 吞弃 | ctor sub_1406140A0 | tok 14417, 非空才写 (门 sub_140614BC0) |
| +1216 | vector 24B | 未名 | {data@1216, count@1228, alloc@1232} | 不序列化; 形态定案/未名 |
| +1272 | 匿名结构 (NNB 形状) | officer wrapper (officer 键) | officer 子块载体, 布局见下方 officer 子表 | writer 槽1 0X1413EACF0 (经 wrapper 对象 vtable; ship 侧由 0X140C3E6C0 对 sh+2120 虚调用实证); 先写内嵌 officer[1] 再遍历追加向量 → savefull `officer[2]/officer[3]…` (追加向量非仅读档入口, 多军官舰实证) |
| +1408 | fixed×1e-5 | held_officer | 随军军官 experience | |
| +1416 | 匿名结构 (NNB 形状) | 位置共享宿主回指 | 宿主同带 +1424/+1436 数组, 析构互摘; SetLocation 比较 `*(host+496)==*(this+496)` 才同步 | 不序列化; 形态定案/语义推定 (战斗/运输宿主) |
| +1424 | vector 24B | 位置跟随子对象指针数组 | {data@1424, count@1436, alloc@1440} (SetLocation 遍历对每元素 sub_1414D0F10 广播) | 不序列化; 形态定案/语义推定 |
| +1448 | u64 ×3 | 0-init 三元组 | +1448/+1456/+1464; 容器形态推定, dtor 不杀 = POD 元 | 不序列化 (推定) |
| +1472 | CEquipmentVariantPool 内嵌 64B | force_equipment_variants 块 | +840 同型; vec1 {data@1480, cap@1488, count@1492, alloc@1496}, vec2 {data@1504, cap@1512, count@1516, alloc@1520}, u8@1528 | loader-only legacy 键 13787, writer 不发射 |
| +1536 | fixed×1e-5 | max_supply (tok 14915) 随身储备上限 (满值 = SUPPLY_GRACE(72)×100000) | init = 100000×dword_143331604 (NMilitary.SUPPLY_GRACE); **每小时** sub_140C8FB20 重算 (MODIFIER_NO_SUPPLY_GRACE 266 族, 降幅钳 dword_1433316B0 = SUPPLY_GRACE_MAX_REDUCE_PER_HOUR); loader 落字段 (writer 0x140C90550 ↔ loader 0x140C8C7E0) | 消费链 §4.18.14 |
| +1544 | fixed×1e-5 | supply_gain (tok 19692) 本小时增量 | **每小时** sub_1414E4780 写 (随小时正反馈爬升 0.01→0.15/h); loader 落字段 (同上述 writer/loader) | 消费链 §4.18.14 |
| +1552 | fixed×1e-5 | army_current_supply_ratio (tok 19693) 当前储备量 | init 同 +1536; **每小时** sub_1414E4780 更新, 分支门 = vtable[48] 储备比 < CUnit+64 或 CUnit+64 ≥ 100000 → 增益 = min(SPEED_GAIN_PER_HOUR + max(prev(+1544), STARTING_GAIN), MAX_GAIN_PER_HOUR) 上钳 +1536, 否则衰减 = STORED_SUPPLY_CONSUMPTION_RATE_FACTOR×(100000−CUnit+64)/100000; 消耗门 = +760/retreat(+588)/withdraw(+589); 读侧 sub_140C87EC0; loader 落字段 | 消费链 §4.18.14 |
| +1560 | uint8 | fuel 已初始化旗 | ctor 0; loader case 12003 在场置 1; 惰性门 sub_140C88D30 — 未置则回填满油 (= stats+288 max_fuel); 存档 fuel=0 (≠0 门省略) ⇒ 旗不置 ⇒ 载入后回满 | 不序列化; 定案 |
| +1568 | fixed×1e-5 | fuel (tok 12003) | **loader 落字段** (ser+1552); 每小时消耗扣减 sub_140C78990 + 优先级分配回填 sub_1410F2E70 (+1568 += grant); max_fuel = 模板+288 (sub_140C7F070) | ≠0 才写 |
| +1576 | fixed×1e-5 | fuel_requested (tok 15298) | **loader 落字段** (ser+1560); 每小时 sub_140C78990 写 (ARMY_*_FUEL_MULT 状态公式) | ≠0 才写 |
| +1584 | uint8 | leader (有/无; tok 10423) | | ≠0 才写; GUI: HQ 师判据 (TemplateChanger[2] 模板集按 leader==is_army_hq 匹配; 撤编 HQ 注记 + Badge 将领技能显示门) |
| +1592 | 内嵌块基 | army_history 块 | ctor sub_141445E90, CUnitMedalStore 族 0x14143xxxx 邻址互证; 布局见下方 army_history 子表 | 写门 = u32@+1644 ≠ 0; GUI: 历史页行重建 (sub_1416BEE50: +1592 块补行 0x5B0 条 + +1624 CUnitMedalStore 按键@+1064 分组 0x50 行) |
| +1656 | uint32 | killed (tok 13164) | >0 才写且**连带写 killer_definition** | GUI: HISTORY_KILL_COUNT_TEXT (sub_1416BEE50) |
| +1660 | uint8 | killer_definition (tok 13556) | 随 killed 门 | |
| +1664 | int32 | script_id (tok 19349) | init −1; 带符号 | |

officer 子块布局 (raw; wrapper = **CHeldOfficer** 内嵌 @+1272, 主vtable 0x142957ED8;
  save wrapper 槽[1] sub_1413EACF0: 块序 = 内嵌 officer 记录先 → 追加向量逐元素
  (同键 officer) → held_officer 嵌套块; 自身 writer 槽[2] sub_1413EAD80 = 仅
  held_officer.experience 单字段; reader 槽[4] sub_1413EA9E0: case 11930 → +136):

| 偏移 (raw) | 类型 | 名称/语义 |
|---|---|---|
| +1272 | CHeldOfficer 内嵌 | officer 键载体 |
| +1296 | officer 记录 88B 内嵌 (wrapper+24) | savefull 第 1 个 officer 块 |
| +1384 | vector {data@+1384, count@+1396} (wrapper+112) | 追加 officer 记录 = savefull `officer[2]/officer[3]…` |
| +1408 | int64 fixed×1e-5 (wrapper+136) | held_officer.experience (>0 才写) |

officer 记录 (88B; 主vtable 0x142765628, **无独立 RTTI 类 (负定案)**; 机制 = 师
军官团历史链: 晋升/阵亡腾空为 seed=0 占位记录 (male/name 清空), 现任 = 链末
真 seed 记录; 元素基址 E):

| 偏移 (E) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| E+0 | 主vtable 0x142765628 | 记录类 (槽[1] 0X140B0EC50 save wrapper / 槽[2] 0X141A3ADA0 writer / 槽[4] 0X141A3AA00 reader) | |
| E+8 | uint32 | seed | 恒写 (0 亦写) |
| E+16 | MSVC 串 (buf@E+16, size@E+32) | name | size>0 才写 |
| E+48 | CCharacterPortraits 内嵌 (vtable 0x1427655D8) | portraits {数据@E+56, 计数@E+68} | 计数>0 整块才写 |
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

**历史条目本地化键枚举全表 (sub_14144E9D0, army_history.cpp:285, 129 行, df306 定案)**: 类型枚举 → 本地化键 (a1+40 = 条目动态键串)。**0..15 陆军段**: 0 CONQUERED_PROVINCE / 1 UNIT_KILL / 2 COMMANDER_PROMOTED / 3 NEW_COMMANDER / 4 INVASION_SUCCESS / 5 PROVINCE_LIBERATED / 6 CORE_LIBERATED / 7 HIGH_VP / 8 AIRFIELD / 9 CAPITAL / 10 PARADROP / 11 UNIT_RENAMED / 12 WAS_ON_OPERATION / 13 WAS_ON_OPERATION_EXCELLED / 14 RECEIVED_MANY_CASUALTIES / 15 RAID (键后缀 `_HISTORY`); **16 = 特工动态键** (a1+40 串直取); **17 = 沉船专用** (debug 门断言 "Sunk ship history shouldn't try to localize" → 落 INVALID, 不经本地化); **18..24 海军段**: 18 CAPTAIN_PROMOTED / 19 NEW_CAPTAIN / 20 SHIP_LAUNCHED / 21 SHIP_RENAMED / 22 SHIP_REFITTED / 23 WAS_IN_NAVAL_COMBAT / 24 WAS_IN_NAVAL_COMBAT_EXCELLED; default → INVALID_ARMY_HISTORY。

CUnitMedalStore (vtable 0x1429C1818, **sizeof 616 = 0x268 malloc 直证, 原「0x268B」hex 误读**; writer 0X14144D130; 元素基址 H = 条目; **类名三分: 0x29C1818 = 本类 / +1592 块 = CUnitHistory (vtable 0x29C1868) / 条目 = CUnitHistoryEntry (vtable 0x29C1BC8, 328B)**):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| H+8 | 容器 data | history 条目 vector {data@+8, count@+20} → **CUnitHistoryEntry\* (两处 reader 均 malloc(0x148) 直证)** | |
| H+20 | u32 | history 条目计数 | |
| H+32 | CModifier | CModifier #1 | 不落盘 |
| H+224 | CModifier | CModifier #2 | 不落盘 |
| H+416 | CModifier | CModifier #3 | 不落盘 |
| H+40/+52 | 匿名结构 (元素待裁) 向量 | 普通 history_queue 容器 (不变) | |
| H+608 | uint32 | amount | >0 才写 |

CUnitHistoryEntry (328B = 0x148; writer 0x14144F560 / ParseKey 0x14144ED30; 活体授勋条目验证) — 328B 全表:

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +8 | 串 32B | army_names | |
| +40 | 串 32B | custom_lockey (原「+8 seed / +40 子队列」碎锚修正) | |
| +72 | uint32 | unique (活体 8/9/12/13) | |
| +76 | uint32 | target_country | |
| +80 | CGameDate 形 union | 事件日期 (= gs+1128 快照; **CGameDate 端指针约定: Save 读 this−16, date 键实际发射 +80..+95**) | |
| +96..+111 | union | 受勋后 +104 = 勋章 def (活体 vt96 保持 CGameDate vtable 而 +104 = 堆指针) | |
| +112 | uint8 | medal_count 授勋旗 (授后清 0) | |
| +113 | uint8 | inherit | |
| +114 | uint8 | sunk_ship 门 (舰侧) | |
| +120 | CSunkShipInfo 168B | 沉船信息 | |
| +288 | 队列宿主 | location 宿主队列 (原「+40 子队列」修正至此) | |
| +312 | fixed×1e-5 | multiplier 经验 (ctor 100000) | |
| +320 | uint32 | orders | |

授勋链 (定案): hash 分支置 medal_count → AddEntry 门 (store+608 < cap ∧ unit_medals.cpp:1038 时间戳 < 国价值 650) → 库选章 (类别 0/1 分触发器) → 挂章 + 折国陆军经验 (def+760 因子) → 落 store 队列 + amount++ + 三 CModifier 重建 → on_add_history 事件。原书条目 4 个「推定」碎锚全部升级/修正。
| 条目+104 | CUnitMedal* | unit_medals medal 定义指针 | ptr≠0 且 **ru8(def+16)≠0** 才写; 名 = MSVC 串@def+24 (size@+40); 两队列 (store history 与普通 army_history 队列) 通用, ship 条目同型顺带适用 (def 对象) |
| 条目+112 | u8 | 可受勋旗 (受勋后清 0) | 推定 |
| 条目+312 | i64 | **勋章权重基准 (fixed×1e-5)** = key651 授勋基值 + 100000 (授勋时写); 消费 = tooltip 聚合 `值 × map权重 / 100000` (§4.18.23 直证) | 定案 |

#### 4.18.2 CRailwayGun

| 项 | 值 |
|---|---|
| 挂载 | 容器 {d@cc+680, c@cc+692} 8B 指针元 (紧挨师列表 cc+656; 本类属陆军/单位族, CUnit 基类域与师/舰队单位共用) |
| vtable RVA | 0X2972228 (过滤器) |
| sizeof | 0x448 = 1096 (三处创建点 malloc 直证; ctor sub_140E87F30, CUnit 基 ctor sub_140BF88A0(a1, 13) type 13 = 铁路炮名册型) |
| Serialize | 0X140E8DE80; 尾部接 CUnit::Serialize 0X140C06540 (raw = ser+16) |
| loader | 0x140E8C870 (vtable+16 组槽[4]; func_names CRailwayGun::Reader, railway_gun.cpp:356; reader 9 键落点与 writer 全对称) |

⚠ 0X140E527D0 系和平会议 writer (勿用); 定线锚 = token 0x341D railway_gun_name 全 dump 唯一写点 5660464 反查。

| 偏移 (raw) | 类型 | 名称 | 写门/备注 |
|---|---|---|---|
| +12 | uint8 | **CSelectable 选中字节** (IsSelectable 断言 railway_gun_view.cpp:0x1A3 + 双 listener 直读; id 对在 +24/+28, 重叠虑不成立) | |
| +24 | uint32 | id 对.type | |
| +28 | uint32 | id 对.id | |
| +29..+311 | — | = CUnit 基类域 (writer 0X140C06540, 布局见 §4.18.5) | |
| +312 | scoped_ptr<匿名结构 (NNB 形状)> | definition → token@p+8 | GUI: StatsView 攻击/射程行 (攻击 = def+608×(1+**MODIFIER_RAILWAY_GUN_BOMBARDMENT_FACTOR**, mdef 0x24E 注册定名); 射程 = RAILWAY_GUN_POSSIBLE_RANGES[def+616] (档位取值件 = sub_140E8AC00, 100000 档位; 极值消费方 = sub_140E89B80), assert railway_gun.cpp:0x464) |
| +313..+823 | — | = CUnit 基类域 (同 §4.18.5; 例外见下 +696/+700 派生自身字段) | |
| +696 | uint32 | **transfer_offset_1** (writer 13986 门≠0; loader 实落字段; ser 坐标 +680 与 raw 差 16 勿混) | |
| +700 | uint32 | **transfer_offset_2** (writer 13987 门≠0; ser 坐标 +684) | |
| +824 | uint32 | equipment id 对.type | GUI: StatsView 装备行 / ListView 条目 |
| +828 | uint32 | equipment id 对.id | |
| +832 | 内嵌 | railway_gun_name (serialize 0X1409C9AC0): type u32@840, name_order@960 门≠0, is_name_ordered byte@1000 ==0 写 no, override ptr@984→MSVC@968 | |
| +833..+1007 | — | = railway_gun_name 块本体 (CNameGroupMember 族, 布局见 §4.3) | |
| +1008 | int64 fixed5 | strength | GUI: StatsView 统计行 (COMMON_MAX_STRENGTH; 命中 5 项之一: +312 def / +824 装备 / +1008 strength / +480 logical_country / CEquipment+1056 manpower) |
| +1016 | uint32 | manpower (裸值) | |
| +1024 | fixed5 | max_supply | |
| +1032 | fixed5 | supply_gain | ⚠ writer 写 +1032 (探针定) |
| +1040 | fixed5 | army_current_supply_ratio | |
| +1048 | uint32 | repair_line id 对.type (键 19548; 门 = 双 dword 任一非零 + resolver 校验, writer/reader 同门) | 先于 combat |
| +1052 | uint32 | repair_line id 对.id | 先于 combat |
| +1056 | idpair | combat 容器数据 (元素 8B {type@0, id@4}; 键 0x2916=10518) | 计数≠0 才写; 存档 = 命名块逐元素行内匿名 idpair → 提取器折 combat.#N (1-based 首现即编号, 同 naval_headquarter.#N) |
| +1057..+1067 | — | = combat 容器尾 | |
| +1068 | uint32 | combat 容器计数 | |
| +1069..+1087 | — | = combat 容器尾 + army 前置 | |
| +1088 | CArmyGroup/COrdersGroup 族子对象视口指针 | army (键 10397): vtable[0]=0x140BEF7C0 (= CArmyGroup::[0]) 返 *(p−16) 组 id 对; 断言名 _pAssignee railway_gun.cpp:1333; 存储值 = 组 id 解析结果+24 (sub_140E8F1F0); +1080 = army id 对 fallback (loader 落点) | |

CRailwayGun GUI 消费:

| 类 | 锚 | 内容 |
|---|---|---|
| CRailwayGunStatsView | target = CRailwayGun refid 对 @view+2672 (ctor sub_141CFF1C0 写入, +56 raw 缓存; +2680 窗 / +2688 btn_delete / +2696 type_icon / +2704 title) | 统计行 id→loc 全表 (off_1430B33F0): STAT_RAILWAY_GUN_ATTACK / ATTACK_RANGE / HOURS_TO_REDISTRIBUTE / COMMON_MAX_STRENGTH / COMMON_MAXIMUM_SPEED / ARMY_SUPPLY_CONSUMPTION |
| CRailwayGunListView | 非窗口监听器/控制器 (CTooltipHandler 2 槽 + CRailwayGunEntryListener 9 槽全定名: 单击选择/同步/加选/地图居中/脱离指挥组/开统计窗/单选; 5 glue 钮 = 批量脱离/批量取消移动/全选/批量删除确认/收集 helper) | 条目 = CRailwayGunViewEntry* 数组 {d@L+128, c@L+140} |
| 命令链 (RTTI 实名) | CUnassignRailwayGunFromOrdersGroup / CCancelMovementCommand / CConfirmDeleteUnits / CChangeRailwayConstructionLeveLCommand | — |
| CRailwayMapIcon | 正名 = 铁路(轨道)图标, 非铁路炮图标 (§4.30.16) | — |

#### 4.18.3 requests 全族 (q = *(div+1144); writer 0X1415103C0)

**块门 = `q+68 || q+172 || q+196`** (逐字 = 门函数 sub_14150D490 `a1[17] || a1[43] || a1[49]`):
三者全 0 ⇒ 该师在存档里**整块不存在** (连 date 也没有); 任一 ≠0 才写块, 块内
date 无条件写 (writer 尾部 ADEC0(0x284A) 无门)。⚠ date @q+224 是**写就残留**的
(置位后不清), 故"date 有值"**不能**反推块存在 —— AI 托管后大量师 date 仍有效
而三门外全 0 (实测 14/14), 按 date 判存在会整批 MISS_SAVE。

**族实名与造物点**: 根 q = **CArmyRequests** (RTTI vtable 0x1429D2080, sizeof 240); 内嵌子对象 = **CArmyReinforcementRequests** (96B @q+16, 主 vtable 0x1429D1DC0 / pers 0x1429D1DF8) + **CArmyUpgradesRequests** (128B @q+112, 主 vtable 0x1429D1F70 / pers 0x1429D1FA8) — **date 实体 = upgrades 子对象尾部 CGameDate 24B** (q+224 属 upgrades, 「date 写就残留」由此归属解释); 后端 = cc+3960 CReinforcementStatus (R 注册表) / cc+3968 CArmyUpgradesStatus (U 注册表), q+80 / q+152 回指 (cc+3952 CDeploymentStatus 为部署域独立件)。运行时请求创建 = **0x141507410** (reinforcement.cpp 族; 调用者 0x14150F740 gamestate 分发) = AI 托管写入门; 驻军变体 = **CGarrisonReinforcementRequests** (72B, 宿主 CStateGarrisonData+8, 块键同 reinforcement, writer 0x141510520, 创建点 0x141507740); 请求元素实名 = **CReinforcementRequest** (sizeof 176); delivery 元素 = **CUpgradeDelivery** (96B, CEquipmentDistributable@0 + CEquipmentDelivery@8)。

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

request 行的发射主体 = **CArmyUpgradesRequests::CUpgradeRequestPersister** (24B 栈上
值适配器; vtable 0x1429D1F20; CPersistent 派生; [2] writer 0x141510700 / [4] reader
0x14150F1B0): 外层 writer/reader 对 U+24 容器逐元素现场装配 {vtable@+0, 目标缓冲指针@+8,
变体 DB ctx@+16 = `*(*(U+16)+56)`}, 一元素一枚、永不独立存在 (写读两侧装配均恰
3 qword, sizeof 24 定案)。适配器发/收三键: 12613 request → 元+8 / 10770 total →
元+16 / 13891 equipment_variant_index → 元+0 variant 的 id 对 (非 0 才写; reader
侧 assert `_Request._pVariant` reinforcement.cpp:1259, 无效请求报
"Invalid equipment request on line " :1316)。

#### 4.18.4 CDivisionTemplate

国家挂载容器 {data@cc+440, count@cc+452}; 全局容器 {data@*(gs+1776), count@*(gs+1788)}; vtable 0X294F5B0; 布局基 d = 对象+24。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | id.type — id 对之 type (对 {type, id}) | |
| +12 (对象基) | uint32 | id.id — id 对之 id | |
| d+8 | string (SSO) | name | |
| d+40 | string (SSO) | localization_key | |
| d+72 | CSubUnitGrid 内嵌 | **regiments 网格** (subunit_grid.cpp 类名断言直证) | {列数 u16@+0, 列高 u16@+2, data@+8, cap u32@+16, count@+20, alloc@+24}; **元素 = CSubUnitDefinition* 8B 直接引用** (token@def+8, 有效旗@def+16 — def 自身字段非包装结构); 坐标 x=slot//列高, y=slot%列高 (非方格时旧读 +0 低 u16 全错); 写者六通道 = 载入 reader (键 12195, def+1448 & 0x1000000 置位拒绝) / setter 六件套 0x140BA51F0-6140 / 批量 0x140FBF810 / 0x140B93340 / 设计器 GUI 七函数 + 交互层三函数 / 网格 ctor; **writer 发射序 = 倒序 16871→12188→12195** ; 复位消费者 = sub_140BA47B0 (CCountry 复位链 §4.3) |
| d+104 | CSubUnitGrid 内嵌 | support 网格 (布局同 regiments) | 序列化键 12188 |
| d+136 | CSubUnitGrid 内嵌 | regimental_support 网格 (布局同 regiments) | 序列化键 16871; regiments 本尊键 = 12195 |
| d+168 | 容器 {data@168, cap@176, count@180} | **营平铺列表** (16B 元 = CSubUnitDefinition* + 计数; def 级旗 @+1463) — SF 训练成本占比 (消费 sub_140B99E70) **与师掌握度人力加权遍历** (§4.6.9 sub_1409E3C20 以此为全师营表, 分母含全部营的 manpower×计数) 的统一营表 | 不序列化 (def 级) |
| d+296 | 容器 {data@296, count@308} | 装备模块引用数组 | 键 13657, 元素 CIdentifier 经专键 13891 逐条写 |
| d+320 | 容器 {data@320, count@332} | 思想/学说 def 指针数组 | 键 19914, 元素写 *(def+8) u32 于键 19015 |
| d+368 | CIdentifier 8B (+372 尾) | **parent 模板引用** (键名 parent = token 135; 与装备变体母本同键), 双 dword 非零才写 | 定案 |
| d+396 | uint32 | priority | 键 141 |
| d+424 | int32 | template_counter | u32 位型读后转符号; 键 13549 |
| d+428 | uint8 | ingame_set_template_counter | |
| d+429 | uint8 | allow_new_equipment | 键 13656 (恒写) |
| d+430 | uint8 | allow_foreign_equipment | |
| d+436 | uint8 | is_army_hq | 键 16913; **GUI: 设计器格重排** (sub_14168B430 → hq_view/non_hq_view) **+ TemplateChanger 模板集过滤键** |
| d+460 | u8 | 模板分组过滤键 (TemplateChanger 匹配 sub_14169D590; ctor 0) | 推定 |
| d+448 | uint32 (门 d+452) | role 名引用 (token 名串) | 键 14279 (与输送带 role 同键), 经 token 名反查写串 |
| d+468 | uint32 | country (tid → 串表) | 键 10394 |
| d+472 | uint32 | original_tag (tid → 串表) | 键 13649 |
| d+476 | uint32 | foreign_template_tag (tid → 串表) | 键 15038 (流亡 tag 键复用) |
| d+480 | uint32 | origin_type (0=无 1=subject) | 键 15039 块头 (殖民模板 effect 写 1, §4.18.6) |
| d+488 | i64 (门 d+496) | 未名标量 | 键 16902 (writer sub_140BA6A40 / reader sub_140BA29F0 落点双向钉) |
| d+504 | string SSO (门 d+520) | **override_model** | 键 15089 |
| d+540 | uint8 | is_fake_intel_division | 键 19403 |
| d+541 | uint8 | is_locked | 键 14766 |
| d+542 | uint8 | obsolete | 键 12396; **GUI: TemplateChanger 滤** (锁+过时+HQ 三滤; sub_14169D590) |
| d+552 | hours | obsolete_change_date | 门 = obsolete b@542 且 ≠ 哨兵 0x29C77F8 ("1.1.1.1") (token 0x2BA0); writer 另发键 11168 嵌套对象 (体 a1+560 起, 哨兵 dword_143086B50) |
| d+568 | uint8 | **force_allow_recruiting** (effect set_division_force_allow_recruiting) | 键 12290 (真才写) |
| d+572 | uint32 (门 d+576) | **division_cap** (effect set_division_template_cap; GUI "Division Cap") | 键 19944 |
| d+580 | int32 | **equipment_niche** (niche_selection_widget.cpp 断言) | 键 19904 (char 型写) |
| d+428/+430 落点补 | u8×2 | ingame_set_template_counter (键 13605 → d+428) / **allow_foreign_equipment (键 19913 → d+430)** | 恒写 yes/no |

#### 4.18.5 CUnit 公共段 (writer 0X140C06540 / loader 0X140C02AE0, ser = raw+16)

全部师/铁路炮/舰队单位共用; writer 25 键 + loader 逐键互证; ctor/dtor 补 runtime-only 区。标量键 loader 落点全表见 §4.18.1 loader 键位落点表 (全部落字段)。

| 偏移 (raw) | token | 字段 | 写门/备注 |
|---|---|---|---|
| +24 | — | id 对.type | writer 体内不发射 (id 机制层序列化) |
| +28 | — | id 对.id | 同上 |
| +29..+95 | — | = id 对尾 3B + **CReferenceObject 簿记 u8@+32** + **CSupplyConsumer u32@+40** (0) + **motorization@+45 / 伴生 byte@+46 (=1)** + 三定点 100000 @+48/+56/+64 + **+72 = sub_1424EF6F0(100000)** + +80=100000 + qword 零 @+88/+96/+104 + 容器@96 头 (子对象 ctor sub_140BF8700, 基 = raw+16) | |
| +96 | 匿名结构 (NNB 形状) | **CSupplyConsumer 内嵌域 (consumer+80) = _DistributedSupplyInfo 分配记账表** — 48B 元 (键 u32@+0 有序二分插入, 回指@+8, 累加点 +16/+24/+32; supply_consumer.cpp:167 断言; 插入 sub_141A0ACF0 / 累加 sub_141A0AFB0) | 定案 |
| +113..+231 | — | = 容器@96 尾 (113..119) + qword 零区 +120..+183 + **CUnit 子对象 vftable@+184** (COrdersGroupMember 视口, vtable 0x142953320) + +192..+231 (40B, CUnit 子对象前段; **+192 = _pOrdersGroup** = member+8 拥有者军群回指, 写入 COrdersGroup reader sub_140BF30A0 `*(unit+192)=this` RTDynamicCast CUnit 链定案) | |
| +232 | 匿名结构 (元素待裁) 向量 | **死字段 (负定案)** — 四vtable全扫 + 双坐标穷举零命中 | |
| +257..+279 | — | = **容器 {d@256, cap@264, c@268, alloc@272}** 内部 (上邻 +232 / 下邻 +280 两容器间的第三容器, ctor sub_14011DF40(a1+256)) | |
| +280 | 匿名结构 (元素待裁) 向量 | **死字段 (负定案)** — 穷举零命中 | |
| +304 | 12002 | disengage (uint32) | signed>0; **loader 解析即弃** (运行时重算族) |
| +308 | 12005 | possible_retreat (uint32) | 随 disengage>0 同写; loader 解析即弃 |
| +312 | CSubUnitDefinition* | **师统计对象** (ctor sub_141018D00 置 CSubUnitDefinition vftable = 合成形态对象, a2=类型 id −1; 0x678B 族 — 与师设计器预览统计对象同类; **统计数组 @对象+160 起 8B/项 × 78 statId, 枚举全表见 §4.31.27**; 对象另有 +816..+976 五统计组与 +1040 CModifier; 清零 sub_140B63730; **聚合 = CArmy::CalculateActiveUnitStats sub_140C8D600 → 聚合核 sub_140B9AD70 → 逐 statId 后处理 sub_140C6F960, 见 §4.31.27**) | **GUI: 师详情三栏统计行** (§4.31.27: 24 行中 20 行读本缓存; 硬度 BuildTooltip 0X1416A2270 读 对象+184 statId 3 = 装甲度 fixed5; SOFT_ATTACK_TAKEN = 1e5−值) |
| +320 | CGameDate vtable | start_date 对象头 {vtable@320, h@328, 代理 vtable@336} | 日期对象 24B 双 vtable 定案 (ADEC0 hours=arg−8 多证) |
| +328 | 0x28E0 | start_date (i32 小时) | 门 h∉[43800000, 43817520) 双哨兵带 |
| +344 | CGameDate vtable | end_date 对象头 {vtable@344, h@352, 代理@360} | 定案 |
| +352 | 0x28E1 | end_date (i32 小时) | 同 start_date 门 |
| +353..+367 | — | = end_date CGameDate {vtable1@344, hours@352, vtable2@360} 的 hours 尾 (353..359) + vtable2 (360..367) — 全在日期对象内 | |
| +368 | 匿名结构 (24B 形状) 向量 | **滚动累加事件队列** — 24B 元 {u32@0, i64@8, i64@16}; 推入时累进 **A(+392)/B(+400)** (dword_1430B132C 切乘/加模式); **C(+408)/D(+416) 不走队列 = CLandCombatant vtable[22] 每小时整写基值** (两栖入侵师曲线 AMPHIBIOUS_INVADE_{ATTACK,DEFEND}_{LOW,HIGH} lerp, 门 = 两栖入侵中) | 形态+机制定案 (0X140BF97C0 全文); 业务名推定 (战斗损伤/修正事件族) |
| +392 | int64 fixed5 | **累加器 A** (ctor=0, dtor 归位 100000=1.0; 队列累进) | 高置信形态/推定语义 |
| +400 | int64 fixed5 | 累加器 B (队列累进) | 同上 (战斗内取 100*(+400*+416/1e5)) |
| +408 | int64 fixed5 | 累加器 C (**vtable[22] 每小时整写**, 非队列) | 同上 |
| +416 | int64 fixed5 | 累加器 D (同 C; 两栖守方曲线) | 同上; **消耗 = A×C (攻) / B×D (守)** (齐射伤害池) |
| +417..+423 | — | = **累加器 D** i64 @416 尾 7B | |
| +424 | 匿名结构 (元素待裁) 向量 | **combats 进行中的战斗指针数组** (8B 指针元) | 定案 — RemoveFrom(combat) 表空则 last_combat_date=当前时刻 (0X140C03E00); 9 函数遍历互证 |
| +448 | CGameDate vtable | last_combat_date 对象头 {vtable@448, h@456, 代理@464} | 定案 |
| +456 | 0x2FDF | last_combat_date (u32 小时) | **i32 ≠0**; 哨兵 43808760 也写 "1.1.1.1" (探针) |
| +472 | tag uint32 | **owner tag** (运行时, 不序列化; ctor = *a3, UI 归属判断比较) | 高置信; **GUI: 撤编按钮门回退** (expeditionary_owner==0 → 用本值; sub_1416BE4F0) |
| +476 | 11997 | expeditionary_owner (tag u32 → 串) | signed>0; **上界 = tag 表 count (gs+868) 非国数** (实测 tag id 可 > country_count); **GUI: 撤编按钮文案/门** (远征师换远征按钮组+旗签; sub_1416BE4F0 → DISBAND_ALL_UNIT / DISBAND_BUTTON_HQ_WITHDRAW_NOTE / SPECIAL_UNIT_CANNOT_BE_DISBANDED) |
| +480 | 0x3410 | logical_country (i32 tid → 串表) | tid>0 且 < **tag 表 count (gs+868)** — ⚠ **非国数**: tag id 由 tag 表槽分配, 实测 339 vs country_count 333, 用国数当界会漏尾部动态 tag (D06 一类); **GUI: 借调东道国 tag 比对** (借调双 StripView 存在谓词 = 元对象+480 == 目标国 tag; cc+760/cc+784 idreg 链) |
| +488 | 0x2EDA | **support_attack** → uint32@obj+164 | kptr 门 (writer 键 0x2EDA=11994 + loader case 11994 + 存档键序 `previous→support_attack→last_combat_date` 实证; 双师共享 id 306) |
| +496 | 0x286D | location → uint32@prov+164 | kptr 门 (unit.cpp:297 错误串直证) |
| +504 | 0x29A3 | previous → uint32@obj+164 | kptr 门 |
| +512 | 372 | path 容器数据 {cap@520, alloc@528} — u32 密集 → 单行 .#1 | count>0; loader 越界剔除 (≥ *(gs+700) 省数删尾) |
| +524 | uint32 | path 容器计数 | count>0 |
| +536 | uint32 | **死字段 (负定案)** (ctor 置 0, 穷举零命中) | |
| +544 | 13868 | full_path 容器数据 {cap@552, alloc@560} — 同 path | count≠0 才读 |
| +556 | uint32 | full_path 容器计数 | count≠0 才读 |
| +568 | uint32 | **死字段 (负定案)** (键 12290 真才写; 无运行时写者) | |
| +576 | 0x28A4 | movement_progress (int64×1e-5; token 10404) | ≠0 (实测样本 7.7022); **loader 解析即弃** |
| +584 | 14268 | move_priority 枚举 {0=front_order, 2=player_order, 3=ai_player_order, 余 normal} | ≠1 (ctor 置 1); loader legacy override_move → 映射 0/1 |
| +588 | — | retreat (uint8) | ≠0 写 yes; **loader 解析即弃** |
| +589 | — | withdraw (uint8) | ≠0 写 yes; loader 解析即弃 |
| +592 | uint64 | 拒动时目标省 id (dword; 拒动协议: AI unitcontroller 落 −1=清/省 id=拒) | 定案 (ctor 置 0) |
| +600 | — | name (MSVC {buf@600, size@616}) | size≠0 且 !sub_1424BFF30; 虚函数 SetName (raw vtable+320) |
| +616 | uint32 | name size | SSO 内部 |
| +624 | uint32 | name cap | SSO 内部 |
| +625..+631 | — | = name MSVC 串 cap@624 尾 7B (串 {buf@600, size@616, cap@624}) | |
| +632 | 12009 | country_intel 容器数据 {cap@640, alloc@648} — 24B 元 {tid u32, val u32, u8@+16} → 单行 .#1 | count>0 |
| +644 | uint32 | country_intel 容器计数 | count>0 |
| +656 | CNullGraphicalCultureType* | **全局单例指针** (恒初值 sub_140A3C0A0 取/惰性建 sub_140A3C160, 无运行时替换写者) | 定案 |
| +664 | 匿名结构 (0x88) | **移动路径环境因子缓存** — 堆分配 (malloc 0x88) 缓存对象指针 (非内嵌; ctor sub_1416434C0 带 unit 回指; 主更新 sub_141644710 以 unit+512 path 比较触发重算; 消费 sub_14055E360 参与 ×6 倍率公式; GUI GetPosition 作非空门) | 高置信 |
| +685 | uint8 | **metrics 观察注册旗** (qword_14333D3E0 = metrics 系统单例; 注册 sub_140F0A640 FNV 哈希 + 军群 +418 联动, 反注册 sub_140F0FF50) | 定案 |
| +686 | — | exile (uint8) | ≠0 写 yes; **loader 解析即弃** |
| +688 | 0x2B5F | move_capital (u8; 旧名 exile_capital 误名, 存档无此键) | ≠0 写 yes; loader 解析即弃 |
| +696 | 0x36A2 | **重试冷却倒计时** (AI unitcontroller; transfer_offset_1 为存档快照键) | ≠0 (writer 键 0x36A2=13986); **loader 解析即弃** |
| +700 | 0x36A3 | **重试退避步长** (3 起步 ×2 封顶 24; 失败时写 +696 = 本值) | ≠0 (writer 键 0x36A3=13987); loader 解析即弃 |
| +704 | 203 | commandlist 容器数据 {cap@712, alloc@720} — 多态命令对象指针数组; 逐元动态键 = token u32@(elem+8) + AD590 多态序列化 | count≠0; 工厂 sub_141234C70(键 token) 创建 |
| +728 | uint64 | **死字段 (负定案)** (ctor 置 0, 穷举零命中) | |
| +736 | 内嵌 32B 结构 | 补位航点容器 {data@736, count@748} — 元素 32B {省 id@+12} (AI 补位点; unitcontroller 目的地判定尾扫首个 +12 非零) + qword@760 = 战略海运载体 ([14] 海省门联动) | 定案 |
| +768 | 内嵌结构 | 容器 {d@776, cap@784, c@788, alloc@792} @+8 起 (u8@768 = 5 ctor; 24B 元 u8@+16 倒计时族, [18] tick 递减摘除; push 者未定位) | 形态定案 |
| +800 | 匿名结构 (NNB 形状) | **raid 族运行时对象** (dtor sub_140F66990 反注册; 断言门) | 高置信 |
| +808 | 0x2997 | seed (uint32) | ≠0; **loader 解析即弃** |
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
| sizeof | 0x260 = 608 = 24B CReferenceObject 头 {vtable@0, idpair {type@+8, id@+12}} + CDivisionTemplateData 内嵌@+24 (0x248) |
| writer (vtable slot2) | 0X140BA6EC0 (0X142220340 头 + 委托内嵌 vtable slot2 = CDivisionTemplateData writer 0X140BA6A40) |
| 存储 | 全局容器 **gs+1776** {data@1776, cap@1784, count@1788} vector\<ptr\> — 定案: CReferencedDivisionTemplate 全局容器**单义** (gamestate.cpp:3316 落盘, 元素键 12112 division_template; 库存锚 = ps+520/544 + cc+4024) |
| 提取键 | `division_template[N]` (首现不编号); 段内按 id 升序发射 (writer 物理序 = 容器序, 段排序是对拍口径) |
| 归属判别 | origin_type=1(subject) 且 foreign_template_tag = subject tag |

#### 4.18.7 CDivisionTemplateData

writer 0X140BA6A40; vtable 0x14294F560 (RTTI: CPersistent 直接派生); ctor 0X140B95480; sizeof 0x248; 偏移基 data = wrapper+24。表行序 = 偏移升序; writer 发射序与升序交叉 (三网格倒序 16871→12188→12195, +542 obsolete 先于 +436 is_army_hq, +448 role 殿后)。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +8 | MSVC SSO (size@+24) | name | 门 size≠0; tok 27; **GUI: 名字输入框** (sub_14168DF50 → DIVISION_DESIGNER_RENAME) |
| +9..+39 | — | = name MSVC SSO 32B 本体 (+8..+39) | |
| +40 | MSVC SSO (size@+56) | localization_key | 门 size≠0; tok 799 |
| +41..+71 | — | = localization_key MSVC SSO 32B 本体 (+40..+71) | |
| +72 | uint32 向量 | regiments {列数 u16@+0, 列高 u16@+2, data@+8, 计数@+20; 元 8B ptr: token@+8, 有效 u8@+16; x=v5/列高, y=v5%列高} | 块 **12195** (0x2FA3); 门 = 空判 !0X140FBF580(+136); 逐格 0X140B93410, `x=N y=M` 重复键; **GUI: 三网格摆格/拆格** (sub_14168E150/BF90/B600/B520 + sub_140FBF5F0 → regiments_grid 等) |
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
| +430 | uint8 | allow_foreign_equipment (ctor 1) | 恒写 yes/no; tok 19913 |
| +436 | uint8 | is_army_hq | 门 ≠0 (yes-only); tok 16913 (0x4211); **GUI: 格重排/模板过滤** (sub_14168B430; TemplateChanger[2] 与 CArmy+1584 联动) |
| +440 | 匿名结构 (NNB 形状)* | division_names_group → 串@ptr+8 | 门 指针非空; ADF40 引号串; tok 14559 (0x38DF) |
| +448 | uint32 token (+452 有效 u8) | role | 门 b@+452≠0; 值 = token 名 (0X1424BC260) 引号串; tok 14279 (0x37C7) |
| +449..+467 | — | = +448 区尾 + qword=357@464 (none 哨兵) + pad | |
| +468 | tag_id (uint32) | country — 值 = tag 名 (0X140BB4E70) | 恒写; tok 10394 (0x289A) |
| +472 | tag_id (uint32) | original_tag | 恒写; tok 13649 (0x3551) |
| +476 | tag_id (uint32) | foreign_template_tag — 殖民地模板在此落 subject tag | 恒写; tok 15038 (0x3ABE) |
| +480 | uint32 枚举 | origin_type — 0=master_host→15037 / 1=subject→13024 / 2=exile→11533 | 块 15039 (0x3ABF) 内写枚举原子 + 尾随原子 16; **值 ∉ {0,1,2} 整块不写** (writer 直接返回) |
| +488 | i64 (+496 门 u8; 16B 块 +488..+503) | **override_model_equipment_category_filter** (tok 16902 直名) — 16B = {i64 类别值@+488, 门 u8@+496}; getter sub_140BA04C0 原样拷 16B / GUI sub_14176EFB0 以门字节门 UI 重建; 写点 = 清空 override_model (D+504, sub_140BA6030) 后写 {源 qword, 1} (sub_14168E320→sub_140BA6050) | 门 b@+496≠0; AE760; tok 16902; objects 层未消费 (待补) |
| +489..+503 | — | = +488 fixed i64 尾 (+489..+495) + 门 u8@+496 + pad | |
| +504 | MSVC SSO (size@+520) | override_model | 门 size≠0; tok 15089 (0x3AF1); **GUI: 模型覆盖名编辑框** (0X141763F10→sub_140BA6030; division_designer_model; 脏旗 view+17705) |
| +505..+539 | — | = override_model MSVC SSO 32B 本体 (+504..+535) + pad | |
| +540 | uint8 | is_fake_intel_division | 门 ≠0 (段不发射, 20 档恒 0); tok 19403 (0x4BCB) |
| +541 | uint8 | is_locked | 门 ≠0; tok 14766 (0x39AE); **GUI: 模板锁门** (可改性总门 sub_140BA2440/93230 三键之一 → DESIGNER_LOCKED) |
| +542 | uint8 | obsolete | 门 ≠0; tok **12396** (0x306C; writer 0x140BA6A40 体直发 + token 表反查; 12460 = `last_hit` 海战域, 0x30AC = 12396 非笔误口径已正); **GUI: TemplateChanger 滤** (sub_14169D590 三滤之一); 另 = 陆军行件组织度图标显隐门 (§4.31.107, 语义反直觉待裁) |
| +543 | — | pad 1B (vtable1@+544 前置对齐) | |
| +544 | CGameDate 24B {vtable1@+544, hours@+552, vtable2@+560} | obsolete_change_date (24B 闭合) | ADEC0 (ptr=vtable2=+560, hours=ptr−8=+552); 门 = obsolete≠0 **且** hours@+552 ≠ 哨兵 dword_143086B50 (= 0x29C77F8 "1.1.1.1" 默认); tok 11168 (0x2BA0) |
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

unit_medal def 新锚 (def reader = sub_14144B920 @CUnitMedal vtable 0x1429C17C8 槽[4]; 库单例 qword_14332F0C8; 另收三键: 12264 available → +64 触发器块 / 14476 one_time_effect → +768 / 10668 officer_xp → +856):

| 偏移 (def) | 语义 |
|---|---|
| +152 | 图标 gfx 基名串 (实例行直用; 模板按钮 + "_large" 后缀取大图 sub_141448E00, 三源互证) |
| +184 | **unit_modifiers** 块 (reader token 14527 定案; 模板项/将领项 populate mode 0 同向选用; 块 +16 起喂渲染/统计链 (原引 sub_140FADF60 系海军 CONVOY_ESCORT 效率计算器误植, 真实消费函数待裁)) |
| +376 | **leader_modifiers** 块 (reader token 14526 定案) |
| +568 | **ship_modifiers** 块 (reader token 10662 定案; populate mode 1 选用, 舰船用) |
| +760 | 基础花费 (无单位上下文直取, unit_medals.cpp:0x329 断言; 有单位时 ± 国修正后比对 *(cc+3984 CPolitics+224) PP, 着色 loc = MEDAL_COST_UI_POS/NEG) |
| +1068 | 图标 frame u32 (vtable+176 SetFrame 三处同址) |

GUI 条目类:

| 类 | 锚 | 内容 |
|---|---|---|
| CMedalInstanceItem (vtable 0x142A69278, 窗 medal_instance_entry, ctor sub_141D102A0) | target = 重建函数现场构造的临时分组 std::map 节点 value 向量 (node+40 = value 槽; §4.18.1 entry+40 = custom_lockey 串 勿混) → item+56 vector\<CUnitHistoryEntry*\> | +68 = count>1 时 "number" 子件带 NUM_OF_MEDALS_UI; 创建点 sub_1416BEE50 (历史页行重建互证) + sub_141BF0140 (单位详情历史段, 宿主视图精名未决 — 同 §4.31.18); tooltip glue 0X141D11420 → MEDAL_EFFECTS_TOOLTIP_DELAYED |
| CMedalTemplateItem / CMedalTemplateLeaderItem (窗 medal_button_entry; ctor sub_141D10600 / sub_141ABC380; populate sub_141D12630 / sub_141AD1DA0 逐行同构) | +64 = medal def / +72 = 授勋 ctx (ctx+8=单位, +24=mode, +32=名串; ctx 宿主 = 母窗+1448 token → 对象+2264 内嵌) | 将领版 populate sub_141ACF0C0 = 全库遍历 (0x14332F0C8, 门 u8@def+16 册双证); click 均落 **CGiveMedalCommand** (sub_141144D60 / 将领双分支 +sub_141144CE0) + default_confirmation_popup (ADD_MEDAL_TITLE/DESC) |

8 个 Item 类全部只覆写 [0] 析构 (vs 基 CStandardGridBoxItem), 真入口 = ctor + glue 子vtable槽。

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

**获取**: `dep = *(cc + 3952)` — 类身份 = CDeploymentStatus (vtable 0x14295FC38; ctor sub_140D0D020 / writer sub_140D14650 / dtor sub_140D0D4C0 三源互证)。

| 偏移 | 类型 | 名称 | 语义 | 参见 |
|---|---|---|---|---|
| +8 | 匿名结构 (112B) | unit_modifiers 容器数据指针 | {data, count}, 元素内联 112B, count<64 | §4.18.11 |
| +9..+19 | — | = unit_modifiers 容器 {data@8, **cap@16**, count@20, alloc@24} 内部 (pdx 24B; ctor sub_140D0D020) |  |  |
| +20 | uint32 | unit_modifiers 容器计数 |  | §4.18.11 |
| +21..+71 | — | = unit_modifiers count@20 尾 + **alloc@24** + **运行时容器#2 {data@32, cap@40, count@44, alloc@48}** (未序列化) + **std::map unlocked_subunits {head@56 (malloc 0x28 三自指哨兵), size@64}** (writer 块 token 16572 = unlocked_subunits; 节点 {key token@+28, u8@+32})  |  |  |
| +72 | CMilitaryDeploymentConveyor* | conveyors 容器数据指针 | {data, count<128} 8B 指针元; 元素布局与 GUI 消费见 §4.18.12 | §4.18.12 |
| +73..+83 | — | = conveyors 容器 {data@72, **cap@80**, count@84, alloc@88} 内部  |  |  |
| +84 | uint32 | conveyors 容器计数 |  |  |
| +85..+191 | — | = conveyors count@84 尾 + **alloc@88** + **训练行列表 容器#4 {d@96, cap@104, c@108, alloc@112} (CMilitaryDeployment\*, daily tick/分发主名单, push = sub_140D0E0C0)** + **容器#5 {d@120, cap@128, c@132, alloc@136} = 定时活动装备分发件** (CTimedActivityEquipmentDistributable 视口; push = sub_140D0E3A0) + **容器#6 {d@144, cap@152, c@156, alloc@160} = HQ 部署件** (CHqDeploymentDistributable 152B, 挂 og+392 / reader 键 16908, 元素 {池@+40, 池@+104, cur@+136, tgt@+140}; 人力配给首填 sub_14193E770) (均未序列化, dtor 逐个清) + **+168 = hq_next_deploy_order u32** (writer 键 16910, >0 门) + **+172/+176 = default_hq_template id 对** {type@172, id@176} (qword_14333D528 初值; writer B320 键 10667) + **+180 = INFIELD 在场师人力和** (Σ sub_140C691B0(师+976); cap 错误面板字段) + **+184 = 加权训练行数** (Σ行需求人力 含托管流亡国行; cap 现值) + **+188 = 部署行上限 (cap)** |  | §4.18.14 |
| +280 | CCountry* | **owner 母国指针** | 供师上限 SF cap 修正读 (cc+1464) 与国师列表 (sub_1406EB770) 双证 | §4.18.22 |
| +192..+239 | — | = **情报估计三元组 ×2** (sub_140D14010 每日重算: 遍历 cc+656 全师对 *(师+312)+664 / +672 两统计量各算 min/max/avg, 零值师半权; **A = armor (+664) / B = piercing (+672) 定案** — 齐射乘数守卫链直证: PIERCING 乘数档除数 = 目标装甲, 装甲=0 守卫 ×1.0 ⇒ +664=装甲/+672=穿甲): {+192 min, +200 max, +208 avg}ₐ {+216 min, +224 max, +232 avg}ᵦ, 空军 → 0xFFFFFFFF; **值为直读非指针** (sub_1414318B0 读 +200 max, sub_14142FD80 读 +208 avg) | 定案 | §4.32.2 |
| +240 | CEquipmentArcheTypePool* 向量 | initial_carrier_air_wing_deployment | **CEquipmentArcheTypePool 32B (ctor sub_14100C630)** {vtable@240, 容器@248 {d@248, cap@256, c@260, alloc@264}} (writer 键 13691); 消费 sub_141980140 = 同模板已排产行数 (add_limit 上限, >9 显 MORE_THAN_NINE) | |
| +272 | 上下文指针 | 部署限制触发器上下文 | 启动上限检查 sub_141980310 / daily 停线复检 sub_14197FF50 / GUI 同模板计数 sub_141980140 三消费 (定案) | §4.18.14 |
| +280 | CCountry* | 国家回指 | 全域 `*(dep+280)` 消费 (定案) | |

其余区域 = 未序列化运行时容器群 (上列 #2/#4/#5/#6 与 +56 map 之外无其他容器; 对拍工具链不消费)。

#### 4.18.11 CSubunitBonusPersistent (unit_modifiers 元素, 112B; vtable 0x14295FAA8; writer 0X14197FA10)

| 偏移 | 类型 | 名称 | 语义 | 备注 |
|---|---|---|---|---|
| +0 | — | vtable 槽 | 序列化分发 (writer 首行虚调用) | |
| +8 | 静态类描述符* | 类描述符 | 指向静态描述对象 | |
| +16 | 匿名结构 (8B 形状) | stats 容器数据指针 — 列表 1 | {data, count<64}; 元素 8B 指针 → 类别对象 |  |
| +17..+27 | — | = CSubUnitStatBonus (内嵌@+8) 容器1 {data@16, **cap@24**, count@28, alloc@32} 内部 (pdx 24B; ctor sub_140641990) |  |  |
| +28 | uint32 | stats 容器计数 |  |  |
| +29..+39 | — | = 容器1 count@28 尾 + **alloc@32**  |  |  |
| +40 | 匿名结构 (16B) | stats 容器数据指针 — 列表 2 | {data, count<64}; 元素 16B {静态 DB 条目指针, 对象} |  |
| +41..+51 | — | = 容器2 {data@40, **cap@48**, count@52, alloc@56} 内部  |  |  |
| +52 | uint32 | stats 容器计数 |  |  |
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

**stats 子对象布局** (头部 24B + 主数组): 类名 = **USSubUnitStats** (RTTI `.?AUSSubUnitStats`, 主 vtable 0x142789D70, 本 writer = 该vtable槽 [2]; ctor 经 sub_141018080 内嵌构造 = CSubUnitDefinition+64)

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | — | vtable | |
| +16 | fixed×1e-5 | factor 头 | 恒 100000 (factor 类, writer 不写) |
| +24 | fixed×1e-5 | combat_width | 主数组外独立字段 |
| +72 | 匿名结构 (48B 形状) 向量 | battalion_mult (48B 条) | category/add/display/stats 逐叶门 |
| +96..+719 | fixed×1e-5[78] | 主数组 | 78 槽 int64×1e-5 |
| +720 | CEquipmentArcheTypePool | **need_equipment** (tok 15244) | 池 {vtable@+0, data@+8, cap@+16, count@+20, alloc@+24}; 元素 16B = {CEquipmentArchetype* @+0, 数量 i64 fixed×1e-5 @+8}; 键名 = token_name(原型+8) 装备原型名 (support_equipment / motorized_equipment); 写门 = count>0 ∧ 任一数量 ≠0 (sub_141010B70); ⚠ 池自身地址在 +720, 数据指针在 +728 (少一层解引用 = 读到池vtable) |
| +752..+912 | 地形静态块 ×5 | 地形修正 (attack/defence/movement) | 块门 = attack/defence/movement 任一非零 |
| +952 | 匿名结构 (40B 形状) 向量 | 动态地形容器 (40B 条) | |

78 槽 → 修饰名映射 = reader 层 STAT2TOK token id 数组。列表 2 元素的 obj: 类别 token@db+84, stats 对象 obj+64。
#### 4.18.12 conveyor 对象三层 (CMilitaryDeploymentConveyor / Line / Deployment)

**类名绑定 (1.19.3 实证)**: conveyor 元素 = **CMilitaryDeploymentConveyor** (vtable 0x14295E100, ~160B, writer 0x140CEBC10 / reader 0x140CEAE70, ctor 0x140CE7070); 行包裹件 W = **CMilitaryDeploymentLine** (64B, vtable 0x14295E0A8, writer 0x140CEBD60); 训练行 L = **CMilitaryDeployment** (200B, MI: CEquipmentDistributable@0 (priority@+8, ≠1 写) + CPersistent@24, vtable 0x14295E020 / pers 0x14295E058, writer 0x140CEBB30 / reader 0x140CEACB0, ctor 0x140CE6DE0)。

line 包裹件 division_name: dn = *(line+32) (lines 容器 {d@cv+120}); type 恒写 / name_order@dn+128 (≠0 才写) / override SSO@dn+136 (size@dn+152 ≠0, 引号) / override_set_prog b@dn+169 (≠0 写 yes)。

conveyors 元素布局与 GUI 三视图消费 (九字段 GUI 坐实; cv = 元素基):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | idpair | id 对 | {type@+8, id@+12} |
| +32 | 匿名结构 (NNB 形状) | template | 模板侧偏移见下表 |
| +40 | string | name | SSO; GUI 消费 |
| +72 | — | amount | 0 → INFINITY 无限系列 |
| +76 | — | location | 非零 → gs+8 vtable[1] → *(obj+192) → sub_1409D91D0 地名串 |
| +80 | — | priority | 0/1/2 → 三钮态 (2,1,1)(1,1,4)(1,3,1) |
| +84 | — | order_index | GUI 消费; 与 +88 orders group 配对 |
| +88 | idpair | orders group | sub_140CE9E00 → RTDynamicCast COrdersGroup 直证 → sub_140BEAA30(group, order_index) → *(entry+56)+272 = CColor 军团色 |
| +120 | 匿名结构 (NNB 形状) 向量 12B | lines | {d@+120, c@+132}; GUI 消费 |
| +144 | token | role |  |
| +148 | uint8 | closed | GUI 消费 |
| +152 | tag_id | government_in_exile_tag | >0 才写 (实证: ENG cv[0] tid=5=FRA); 训练 ETA 因子双 define dword_143335D10 (GIE_EXILE_…)/dword_14333226C (DEPLOY_TRAINING_MAX_LEVEL) |

**行包裹件 W** (cv+120 lines 容器元素; dep+120 容器装 CTimedActivityEquipmentDistributable +120 子对象, 勿混):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +8 | idpair | id 对 |  |
| +32 | CNameGroupMember* (176B) | division_name 对象指针 (ctor sub_1409BFEC0; writer 嵌套块 14596; 模板经 W+56→conveyor+32 间接可达) |  |
| +40 | uint32 | 当前 series 序号 |  |
| +48 | 匿名结构 (NNB 形状) | 训练行 L | 布局见下表 |
| +56 | CMilitaryDeploymentConveyor* | conveyor 回指 |  |

**训练行 L** (训练行对象):

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +32 | CEquipmentVariantPool (64B 内嵌) | equipment (tok 12110) 训练装备池 (ctor sub_14100C710; 池空判 sub_141010BA0 / 满足率 sub_141010160 / 落师过继 sub_140C6DF60 三消费; 占 +32..+95) | writer/reader 双证 (多态值 I/O) |
| +96 | fixed×1e-5 | 训练进度 (tok 12218) | 定点; >0 写 |
| +104 | fixed×1e-5 | 目标 max_training (tok 13078) | 100000 |
| +112 | — | 装备人力池 army_manpower_value (tok 14075) | sub_140C69830 求和; writer 0x140C6AD50 |
| +144 | — | 需求侧池 army_manpower_need (tok 14076) | reader 0x140C6A330 同容器对 |
| +176 | uint32 | max_manpower (tok 10608) | >0 写 |
| +184 | 行包裹件 W* | W 回指 |  |
| +192..+195 | uint32 | 停滞理由 id |  |
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

#### 4.18.13 CUnit / CArmy vtable槽语义 (slot-contract)

CUnit 主 vtable 0x1429530D8 = 58 槽 (0-57); CArmy 主 vtable 0x14295A2B0 = 59 槽 (0-58)。
两表为多基布局: 主表之后紧邻次级基子对象 vftable (CUnit +16 组 13 槽 = CPersistent 系
前缀 [1]Save/[2]Writer/[3]Load/[4]Reader + AssignId/AllocateId id 机制 + 登记旗标 setter;
+184 组 8 槽 = 位置/在册状态通知 + GetOuter/GetName/GetOwner; CArmy 另有 +824 组 10 槽)
—— 次级组槽号独立, 勿与主表连续计数; 派生实体序列化前缀在次级组, 不占主表槽号。
ICF 桩身份: 0x140120540 = `return 0` / 0x1401F8A60 = `mov rax,rcx;ret` (return this) /
0x14011D220 = `return 0` / 0x1401807B0 = `return 1`。

| 槽 | 语义 | 证据 |
|---|---|---|
| CUnit [7]..[12] | return 0 桩 (多基转换族, 非陆军实体无自转换) | exe 直读 0x140120540 桩 ×6 |
| CArmy [7]/[8] | AsArmy = return this (0x1401F8A60; 陆军实体自识别) | exe 直读; AI 分兵缓存归类/AIFC 评分 vtable[8] 读点 |
| CUnit [13] | GetName (返 +600 名称串首址; CArmy 覆写转向 *(+832)+96) | writer token 27 写该串 |
| CUnit [21] | IsValid (基 `return 1`; CArmy 覆写 sub_140C77BE0 = vtable[31] 当前兵力 < 10000 → NO_STRENGTH_TO_FIGHT, org 半段对称 NO_ORG) | 覆写错误键直证 |
| CUnit [24] | TakeDamage (基 = stub; CArmy 覆写 sub_140C8F510: **函数首读模板(+952)+564 = is_fake_intel_division 假情报师旗** (CDivisionTemplate d+540, 键 19403) 非零 → 整个伤害短路跳过 — 短路面 = attrition + 战斗伤害两面, 是假情报师不可磨损不受伤的效果非独立豁免开关; 之后伤害 ×(mod661+100000)/100000 乘 a2 str 参 / ×(mod660+100000)/100000 乘 a3 org 参) 后 `+1064 −= org伤害 / +1056 −= str伤害` 双钳非负, 累计 +1088(a4 时)/+1096/+1104; 尾项伤亡 × WAR_SUPPORT_FROM_CASUALTIES(qword_143336A18, 负系数; **mod662 裸值并入此系数**) × (1−statId9 CASUALTY_TRICKLEBACK) → sub_1406D1950 → sub_141516940 **加法累积**入国家 +4040 块槽 2 战争支持下调) | 断言 "TakeDamage is not implemented for this unit type" unit.h:182 |
| CUnit [25] | TakeDamageImmediate (基 = stub) | 断言 unit.h:187 |
| CUnit [40] | SetName (a2 拷入 +600; CArmy::[40] 覆写 = 禁用断言体 **0x140C8EE90**, RVA 直读钉) | 断言 "CArmy::SetName( CString ) is forbidden to use!" army.cpp:3887 |
| CUnit [43] | HasLowSupply (基 = stub) | 断言 "Unit type has not implemented HasLowSupply" unit.h |
| CUnit [50] | Exile (基 = stub; **CArmy 覆写 0x140C8E770**: 门 = +472>0 在册, a2 流亡旗假仅清 +686; 真则清战斗态 sub_140C04C60 → **+686 exile = 1 与 +688 move_capital = 1 同置** → +840 池按 EXILE_EQUIPMENT(qword_143331228) 削减 → +1064 ×= EXILE_ORG(qword_1433312D8)/1e5 钳 [0,[38]] → 池缺额损失上报 → RefreshAbilities → sub_140BFB4A0 取消移动) | 断言 "Can only exile armies and railway guns!" unit.cpp |
| CUnit [51] | ReturnFromExile (基 = stub; **CArmy 覆写 0x140C8DD50**【高置信】: sub_140E2AD40(tag, army, +496 location) 归国传送落位 + sub_140BFBAD0 清队列 + vtable+424 槽[53]) | 断言 unit.cpp:1956 |
| CArmy [41] | **伞降扰乱缩编 = 0x140C8A7D0** (无静态调用方 = 虚调入口, 空降执行链 0x140F84680 形态吻合): 分母 = 100000 + 2×mod371 PARATROOPER_DEFENSE (国 +1464 与 og 侧 sub_140C1A070 两路, 伞兵防御越高扰动越轻) → 三支比例 = PARACHUTE_DISRUPTED_{EQUIPMENT/MANPOWER/STR}_DIV × 扰动强度基数/1e5 + 100000, 各 ± PARACHUTE_PENALTY_RANDOMNESS/2 中心化抖动 (army.cpp:4625-4627 三 RNG) → 尾调三比例缩编叶 sub_140C8A550 (装备缩池/人力扣减·借调记远征 AI 台账/SetStrength, 唯一调用者即本链) | exe vtable直读 + define 实名 |
| CArmy [42] | **伞降完成 = 0x140C89F10** (槽号新钉, 函数体书已收: +1064 = PARACHUTE_COMPLETE_ORG 公式 + +1160 时间戳) | exe vtable直读 |
| CArmy [45] | **战斗伤亡折算清账 = 0x140C8AAB0**: gs+2618 载入门 → 100000×+1088/vtable[33] 钳 → × EQUIPMENT_COMBAT_LOSS_FACTOR(qword_143331410)/1e5 → 战斗上下文两侧单位列表定位自身做伤亡分摊 → **清 +1088/+1096/+1104 三账本** (与人力比例 getter sub_140C87F70 同 define, 互为消费/清账两侧)【高置信】 | exe vtable直读 |
| CArmy [19] | 日 tick ("GetTheatre()" 断言串 army.cpp:3384 在体内, 非槽语义) | dig_in 增长 (钳 +1120 cap) → out_of_supply_days 判定: +760 空 且 有效比 < SUPPLY_THRESHOLD_FOR_ARMY_ATTRITION(qword_1433322C0) → ++ 钳 MAX_OUT_OF_SUPPLY_DAYS(30), 否则清 0; 每日由 CCountry::DailyUpdate sub_1406E76A0 (profiler "country.daily") 经 cc+656/cc+680 数组调 |
| CArmy [43] | HasLowSupply 覆写 (sub_140C88120) | 有效比 (sub_140C87EC0) < LOW_SUPPLY(qword_143331E58=0.99) → true; +760 非零 → false |
| CArmy [48] | 储备比 getter (sub_140C87E10) | 100000×+1552/(100000×GRACE), 不含 CUnit+64 下限; 1414E4780 经 vtable+384 调 |
| CArmy [54] | 补给消耗 getter (sub_140C87E90) | max(MIN_SUPPLY_CONSUMPTION(qword_143331C98), 师统计(+312)+248); 供应系统消费者登记 (lam 3) 按此计消耗 |
| CArmy [22] | **RefreshAbilities = sub_140C8D450** (定案) | 体首 sub_140C8D600 全量统计重算 (CalculateActiveUnitStats, §4.18.3 78-statId 聚合) + leader 旗 → **sub_140C20F70 刷新叶** (sub_140C21FC0(leader) + leader vtable[28] (+224) + leader+3768 = 0; og+136 = CArmyLeader\*, §4.24.3) — 战时换装高频即采样 5.9% 热点; 断言 "Refreshing abilities from non-serialcontext, OOS may occur!" army.cpp:1743; **sub_140C89090 = 错峰小时 leader 聚合独立入口** (HourlyUpdate sub_1401D85A0 的 (id+1)%24 循环调, 与 RefreshAbilities 共享尾叶但两函数不互调) |
| CArmy [35] | 有效兵力 getter = sub_140C7EFF0 (定案) | `+1128 × vtable[34](a1) / 100000` 钳 [0,100000]; C881D0 经 vtable+280 虚调取值 vs 阈值 qword_143332988 (唯一热点入径) |
| CUnit [18] / CArmy [18] | **每小时更新 tick** (定案): 基类 impl sub_140BFF830 (unit.cpp:679) — country_intel 容器 (+632 数据/+644 计数, 24B 元) 每小时按 define 双档累加、过阈清零降级 (级 0 摘除) / 目的地异国单位遭遇 → 成员逐个虚槽 +144 接战 / 命令队列 (+704/+716) 空闲态清理 / 第二定时数组 (+776/+788, 24B 元 u8@+16) 递减到期摘除 (语义待裁); **CArmy 覆写 sub_140C881D0** = 每师每小时总入口 (army.cpp:3066 "_Strength: %lli"): 取消移动 sub_140BFB4A0 (unit.cpp:2344 "Cancel movement"; 清命令/离运输船/摘 theatre 与路径省登记, 按控制权落位 +496; **非解散**) / 战斗·撤退推进 (sub_140C04BE0 = 清 +588 撤退+目的地, sub_140C04D90 = 清 +589 脱离) / 补给比读取 (sub_140C87EC0) / 有效兵力 vtable[35] < 阈值 FIGHTING_STRENGTH_DEATH_THRESHOLD (qword_143332988; 第二消费点 sub_1413E3990 移动/撤退决策) → sub_1401D7460 延迟删除登记 / 流亡·归国编排 sub_140C050E0 (许可翻转 Exile vtable[50]; 日相位选点 ReturnFromExile vtable[51]) / 移动经验+租借分成 sub_140C8C0E0 / ApplyAttrition sub_140C6F5C0 (army.cpp:2874; +1080 缓存 → 扣 **+1064 组织度** (ATTRITION_DAMAGE_ORG qword_143335650, 行军中系数换 ATTRITION_WHILE_MOVING_FACTOR qword_143335788, 门 = 模板+564 假情报师旗) + +872 装备逐条损耗 sub_140C6E100, §4.18.15) / theatre 摘挂 sub_140C8E3B0 / 同州情报标记遍历 sub_140DF75B0 (写他军 +632) / 卡死落点决策 sub_140DF7A40 (战略转移 sub_140EA9720 or 删除登记) / 两处直调 sub_140BB9220 进省登记+夺省 (尾调 SetController sub_140E801A0, 仅控制权真实翻转才入级联, §4.14) / 内联日更块 = **CArmyRequests (+1144)**: 141510110 到期重建 + 14150E460 每小时推进 (门 id%24, §4.2.6 相位 11)。三型小时链共用基类 (CArmy 0x140C881D0 / CTaskForce 0x140D705F0 / CRailwayGun 0x140E8B8E0 各 ×1 调 BFF830) | func_names rtti CArmy::[18] army.cpp:3066 / CUnit::[18] unit.cpp:679 + 语料直读 |

| CUnit [14] | **省准入校验** (CanEnterProvince/HasAccess; 基 = _purecall) | CArmy 0x140C881C0→sub_140DF72C0 (海省门 unit+760/属主/流亡/军通/边境战树扫描, 面相等直过, 终判军通 sub_1406FD540); CTaskForce 0x140D70550→sub_140D702D0 (断言 "pTarget should never be null"); CRailwayGun 同 CArmy | exe 直读三派生 |
| CUnit [15] | **移动校验短式** (unit, prov, flag, errSink) | 基 0x140BFB220 = 纯转发 vtable[16](unit, prov, prov, …); CArmy 0x140C78280 = 基础 + 陆/海细化 (两栖判定 sub_14140A390); CTaskForce 0x140D674C0; CRailwayGun 0x140E89410 (禁海) | exe 直读 |
| CUnit [16] | **移动校验核** 5 参 (unit, from, to, flag, path) — 错误键报告 | **三派生共享** 0x140BFA300: NO_ACCESS_TO_TARGET (先 [14] dry-run) → NO_RETREAT_ALLOWED (+436 战斗中 ∧ 无军通 ∧ ¬[20]) → NO_ADVANCE_IN_COMBAT (+524 路径非空 ∧ 战斗, 门 sub_140C00520/sub_140BF9F90); CRailwayGun 专版 0x140E88D90 (NO_RAILWAY_ACCESS_* 三键) | exe 直读 + 错误键簇 |
| CUnit [17] | **八参 dry-run IsValid** (CMoveCommand::IsValid 消费, §4.33 tok 10402 互证) | 基 0x140BFA100 (+588 retreat 非强制 → NO_MOVE_RETREAT); CArmy 0x140C77E80 = CMilAccessAreaCostCallback + 军通面寻路 sub_140DF7030 (失败且 a5 → sub_140BFF170 海运兜底); CTaskForce 0x140D67480→sub_140D6C800; CRailwayGun 0x140E88C30 (TRANSPORT_ACTIVE_CANT_MOVE) | exe 直读 |

> **寻路海域成本回调家族** (栈上小对象 + 单槽 vtable 类型标签, 寻路器按 vtable 指针识别): CMilAccessAreaCostCallback (上 [17] 行) 之外两件 — **CAccessAreaCostCallback** 16B (vtable 0x14295E808 单槽 0x140CF3850; +8 tag 块; 成本查询 = `*(area+60)` 非零 ∧ 军通检查通过 → 100000; ctor sub_140CF05A0) / **CVerySafeAreaCostCallback** 8B (vtable 0x1427E2250 单槽 0x140CF39C0; 区值 ≤0 → 100000 否则按值缩放; 7 处全栈上构造, 纯策略标签)。消费侧 = 区域成本查询 sub_140CF3B20 (§4.34 part11)。
| CUnit [20] | **战斗/海况豁免的省可入校验** ([16] 撤退豁免通道) | 军共享 0x140C001B0 (海省判定 + 军通门 + vtable[37]<100000 拒 + 战斗强度扫描 prov+224 ≤0 可入); CTaskForce 0x140D73C60 (= [14] 带 flag); CRailwayGun 0x140E8BEC0 | exe 直读 |

| CUnit [31]..[39] | **纯虚资源接口族** (基表九槽全 `_purecall` 0x14253C3B8; CArmy/CTaskForce 0x142962F70/CRailwayGun 0x142972228 三派生各自实现) | 三重奏结构: 当前值 [31]/[36]、平均值 [32]/[37]、上限值 [33]/[38] + 比例派生 [34]/[39] + 有效兵力特化 [35]; 逐槽见下 | 三派生vtable直读 |
| CArmy [31] | **GetStrength 当前兵力原值** (定案) | `*(this+1056)` 64 位定点; CTF sub_140D6B520 = Σ船 str(CShip+1784); CRG 0x140C959B0 | exe 直读 |
| CArmy [32] | **GetAverageStrength 平均兵力** (定案) | sub_140C7CD30 虚调 +248 转发 [31]; CTF sub_140D6B320 = Σstr/(100000×船数); CRG 与 [31] 同函数 (单实体等价直证) | 三派生对照 |
| CArmy [33] | **GetMaxStrength 最大兵力** (定案) | sub_140C825F0 = max(100, 师统计对象(+312) statId 61 = STAT_COMMON_MAX_STRENGTH, §4.31.27); 国家修饰符经 CalculateActiveUnitStats 聚合链间接进入统计数组; CTF sub_140D6CC60 = Σ max(100, CShip+776); CRG 0x140E89C90 | exe 直读 |
| CArmy [34] | **GetStrengthRatio 兵力比例** (定案) | sub_140C87920 = 100000×[31]/[33] 钳 [0,100000]; CTF sub_140D6F910 = Σstr/Σmaxstr 同钳; CRG 0x140E8B090 | exe 直读 |
| CArmy [35] | **GetEffectiveStrengthRatio 有效兵力** (定案) | sub_140C7EFF0 = +1128 平均装备状态 × vtable[34]/100000 钳; 基线共享 sub_140D6C6D0 = 转发 [34] (CTF/CRG 用基线版 = 槽契约默认兵力比例, CArmy 覆写乘装备状态) | exe 直读 |
| CArmy [36] | **GetOrganisation 当前组织度原值** (定案) | `*(this+1064)`; CTF sub_140D6FFA0 = Σ船 org(CShip+1792); CRG 0x140E89B20 | exe 直读 |
| CArmy [37] | **GetAverageOrganisation 平均组织度** (定案) | sub_140C7CD10 虚调 +288 转发 [36]; CTF = Σorg/(100000×船数); CRG [36]=[37]=[38] 同函数 (org 单值无上限区分直证); UI 聚合消费 sub_140B3CA20 读 [37] 佐证「层级平均」契约 | 三派生对照 |
| CArmy [38] | **GetMaxOrganisation 最大组织度** (定案) | sub_140C81D20 = max(100, 师统计对象(+312) statId 60 = STAT_COMMON_MAX_ORG); CTF Σ 船 max org = (基础+stat70)×(stat71+100000+stat638)/100000 | exe 直读 |
| CArmy [39] | **GetOrganisationRatio 组织度比例** (定案) | sub_140C82B60 = 100000×[36]/[38] 钳 [0,100000]; CTF sub_140D6E990 = Σ船 org 比例/船数; CRG 0x140AD80B0; AI 微操弱军段 sub_141088F40 读点 | exe 直读 |

> 待裁项暂不定名: CUnit [5] 可见性判定 (移动族 [14]-[17]/[20] 与资源族 [31]-[39] 已定名见上表)。

- CArmy+760 = **战略海运载体指针** (strategicnavy.cpp sub_140EAA5C0 唯一写点直证;
  非零 = 海军转移中; [19] 消耗门与 [43] HasLowSupply 读此判空)。定案。
- sub_140BFD700 = **unit.cpp 海域加权选址** ("IsNavy()" / "pProvince->GetTemplate().IsSea()"
  断言串直证; caller 0xBBA690 夺省链; 采样帧 +BFD763 归此)。定案。
- sub_140C97430 = **指挥链权限位谓词** (定案): +1240 上级链遍历 + +1344/+1352 旗,
  掩码 0x1F0037FC00; 75 调用者。
- sub_141547440 = **邻接规则主评估核** (adjacencyrule.cpp, 定案; 全布局与谓词门见 §4.14.8): 海峡/运河 (苏伊士/
  巴拿马/直布罗陀等) 通行判定; 四位掩码 = 陆军/海军/潜艇/贸易可通行 (&1/&2/&4/&8);
  规则对象 +248/+336/+424 = 敌/友/中立三触发器组, +108 = adjacency_check 调试旗,
  a4 = REASON 输出; 海军寻路 (D65D60/D67AA0) + trade 车队 (CAA1B0) + adjacency.tick
  (CB47B0) 组合调用, 每次判定全量跑触发器组 (两窗 71 样本热点)。
> CUnit [7]-[12] 六槽同址 `return 0` 且三派生各覆 2 槽 return this (CArmy 7/8、
> CTaskForce 9/10、CRailwayGun 11/12) = 按单位类型的转换函数族, 无逐槽直接证据, 整族不命名。

#### 4.18.14 单位补给状态与消费链 (全部惩罚消费点收口)

**总模型 = 随身储备**: +1536 上限 / +1552 储备 / +1544 增量 / +1176 缺补天数 /
CUnit+64 (= CSupplyConsumer+48, 基对象 CUnit+16; ctor sub_140BF8700 写 100000,
supply_consumer.h:72 断言; 不序列化 — consumer 侧只发 19698/19943) = 所在地可获
补给比。写者收口 (高置信): 写点集合均落 CSupplySystem::UpdateSupply 调用树
(每游戏小时一次) —— 消费者重建清零 (流亡 sub_1412212C0 /
复位 sub_141230CA0, 唯一调用点 sub_14121B650)、比值重算 sub_141A0AFB0 /
sub_141A0ACF0 (+48 = 100000×_ReceivedSupply/_AskedSupply, asked=0 → 100000;
supply_consumer.cpp:167/181 断言); ctor 常量 100000 (空容器/项目族 ctor
sub_140C482A0 同)。消费者宿主矩阵:
CArmy/CTaskForce/CRailwayGun = 宿主+16 内嵌基 (补给比落宿主+64);
CCountryAirContainer/项目消费者 = 宿主+0 (落宿主+48)。序列化链坐标系 (定案):
CArmy writer 0x140C90550 / loader 0x140C8C7E0 跑在 mdisp=16 子对象 (0x14295a490)
上, writer/loader 体内偏移 = 本节偏移 −16 (12 组 token 互证)。全部消费点只读
同一个**有效补给比**:

```
sub_140C87EC0(u)  = clamp( max( *(u+64), 100000×+1552/(100000×SUPPLY_GRACE) ), 0, 100000 )
sub_140C77680(u, out, norm)  惩罚比 = (OOS天数/30) × (1−有效比) × (1+mod94/383 out_of_supply_factor);
                             +760 非零 → 0; norm=1 时按 SUPPLY_THRESHOLD_FOR_ARMY_ATTRITION 归一
日 tick [19] sub_140C78B00 与 sub_140C77680 均 inline 复算上述有效比 (不调 sub_140C87EC0)
vtable 实现面 (vtable 全扫): [48] 储备比 getter 全 exe 仅 2 实现 (CArmy sub_140C87E10 /
CRailwayGun 0x140E8B130); [43] HasLowSupply 2 (sub_140C88120 / 0x140E8B710);
[19] 日 tick 2 (sub_140C78B00 / 0x140E89480); sub_1414E4780 不写 +64 (只写 +1552/+1544)
```

| 消费点 | 函数 | 补给项 |
|---|---|---|
| 损耗 attrition | sub_140C75500 (每小时落 +1080) | OUT_OF_SUPPLY_ATTRITION(qword_1433318B8=0.20) × 惩罚比, breakdown "ATTRITION_SUPPLY" |
| 组织度恢复 | sub_140C6F3B0→140C82C10→140C6F960 | OUT_OF_SUPPLY_MORALE(qword_143331B78=−0.2) × 惩罚比, breakdown "out_of_supply_factor_tt" |
| 移动速度 | sub_140C7FDB0 (vtable[28]) | OUT_OF_SUPPLY_SPEED(qword_143331968=−0.8) × 惩罚比, breakdown "SUPPLY_SPEED_MODIFIER"; ⚠ NON_CORE_SUPPLY_SPEED(qword_143331A10) 项为常量, 与补给比无关 |
| 战斗修正 | sub_1412AF7C0 | lack = 100000−有效比, × COMBAT_SUPPLY_LACK_{ATTACKER,DEFENDER}_{ATTACK,DEFEND}(qword_1433353B0/448/4E0/578, 唯一读者) × 州 mod603/604 + 国家 mod595 入修正栈 17 |

刷新时机: **每小时** 调度层 Mem_fn 并行逐师 sub_140C88A70 (140C8FB20 重算 +1536 →
1414E4780 增/衰减 +1552/+1544 → +1192 paradrop−− → +1080 attrition → acclimatization
→ org 落地); **每日** country.daily (sub_1406E76A0) 调 [19] 日 tick; 错峰日检
lambda_5 (串行叶 1401BACB0, (army_id+1)%24) → 140C8D600 CalculateActiveUnitStats。
AI 面同读 140C87EC0 (front eval 141064840 / 训练门 141A55110 / AIFC refresh
141A3E070), 见 §4.34。

补给相关 define → 全局 (装载器直证, NMilitary 表除非注明):

| define | 全局 | 消费 |
|---|---|---|
| SUPPLY_GRACE (72) | dword_143331604 | ctor 初值; 全部归一化分母 |
| SUPPLY_GRACE_MAX_REDUCE_PER_HOUR (2) | dword_1433316B0 | 140C8FB20/140E8B8E0 降幅钳 |
| LOW_SUPPLY (0.99) | qword_143331E58 | [43] HasLowSupply |
| MAX_OUT_OF_SUPPLY_DAYS (30) | dword_143331818 | [19] 天数钳; 140C77680 |
| OUT_OF_SUPPLY_ATTRITION (0.20) | qword_1433318B8 | 140C75500 |
| OUT_OF_SUPPLY_MORALE (−0.2) | qword_143331B78 | 140C6F960 |
| OUT_OF_SUPPLY_SPEED (−0.8) | qword_143331968 | 140C7FDB0 |
| NRailwayGun.OUT_OF_SUPPLY_SPEED | qword_143331528 | 140E8AE40 |
| NON_CORE_SUPPLY_SPEED / NSupply.NON_CORE_SUPPLY_AIR_SPEED | qword_143331A10 / 143331AC8 | 140C7FDB0 常量项 |
| SUPPLY_THRESHOLD_FOR_ARMY_ATTRITION (0.35, NSupply) | qword_1433322C0 | [19] 阈; 140C77680 归一 |
| MIN_SUPPLY_CONSUMPTION | qword_143331C98 | [54] 140C87E90 |
| COMBAT_SUPPLY_LACK_ATTACKER_ATTACK / _ATTACKER_DEFEND / _DEFENDER_ATTACK / _DEFENDER_DEFEND | qword_1433353B0 / 143335448 / 1433354E0 / 143335578 | 1412AF7C0 (唯一读者) |
| ARMY_SUPPLY_RATIO_STARTING_GAIN / SPEED_GAIN_PER_HOUR / MAX_GAIN_PER_HOUR (NSupply) | qword_1433378F8 / 1433377F0 / 1433376F0 | 1414E4780 |
| STORED_SUPPLY_CONSUMPTION_RATE_FACTOR (NSupply, 0.75) | qword_1433327C8 | 1414E4780 衰减 |

相关修饰符 (idmap 直证): 94 OUT_OF_SUPPLY_FACTOR / 383 SPECIAL_FORCES 版
(140C77680/140C8FB20), 266 NO_SUPPLY_GRACE + 382 SPECIAL_FORCES 版 + 354/355
PARATROOPER/MARINE_EXTRA_SUPPLY_GRACE (140C8FB20), 595 SUPPLY_PENALTY_ON_CORE +
603/604 LOCAL_(NON_CORE_)SUPPLY_IMPACT (1412AF7C0)。
CRailwayGun 镜像: max_supply +1024 / supply_gain +1032 / ratio +1040; 小时链
140E8B8E0, 日 tick 140E89480 (vtable[19]), 储备比 getter 0x140E8B130 (vtable[48]),
HasLowSupply 140E8B710, 移速 140E8AE40 (仅认镜像储备比, 不读 CUnit+64)。
脚本供给 = supply_units effect (sub_140C79080: +1552 += 值, 封顶 +1536)。
**燃料惩罚链 (CUnit+1568 消费面收口)**: 比值 getter `sub_140C7F0A0` = clamp(100000×fuel(+1568) / (FUEL_PENALTY_START_RATIO(0.25) × 模板 maxfuel(*(u+312)+288)), 0, 100000) — fuel ≥ 25% 满 → 比 1.0; 分母裸 getter sub_140C7F070 = 模板+288 原值 (UI 徽标); 消耗写者 sub_140C78990 / 分配回填 sub_1410F2E70 见 §4.3.16 域表。全部消费点 (穷举 6 + inline 1):

| 消费点 | 函数 | 公式与零态 (fuel=0) |
|---|---|---|
| 移动速度 | sub_140C7F140 (**CArmy::CalculateSpeed 总移速核**, 非 stat getter; 调用者 140C82620/140C875B0) | 总式 = stats[62] 基准 × vtable[28] 修饰栈 × 海运分支 (+760 门, NAVAL_SPEED_MODIFIER) × 两栖分支 (AMPHIBIOUS_INVADE_SPEED_BASE × LAND_SPEED_MODIFIER, breakdown "MOVING_AMPHIBIOUS_INVASION") × 零组织分支 (vtable[39] < LOW_ORG_FOR_ATTACK → ×(ZERO_ORG_MOVEMENT_MODIFIER×(1−org比/阈)+100000)/100000 — **LOW_ORG_FOR_ATTACK 消费面扩至移动**) × 燃料分支: mult = 0.4 + 0.6×比, breakdown "LACK_OF_FUEL"; 零态 ×0.4 无硬停; army.cpp:6077 "Name:%s, Value:%lli" |
| 装备 stats (战斗面真身) | sub_140B9AD70 第 10 参 | 需燃料装备 (eqdef+808>0) stats × (0.1+0.9×比), 非燃料装备不受影响; 入口两路 = 错峰日检 sub_140C8D600 + 部署/换装 sub_140C86CC0 (inline 复算同比) |
| 训练 XP | sub_140C751B0 | mult = 0+1×比; 零态 XP=0 (完全停) |
| 消耗请求收缩 | sub_140C73560 | 消耗 ×= min(比,1.0) — 低燃料时抽油按比例收缩 (结算输入侧) |
| 战斗 tooltip / icon | sub_1415D5FA0 / sub_1415DCB60 | 比 <100000 → LACK_OF_FUEL_DESC / icon 16 |
| 地图徽标三档 | sub_1416B89C0 | 裸比 (不带 START_RATIO): ≥0.99 → 1 档, ≥0.25 → 2 档, 否则 3 档 |
| 组织度恢复 | — | **负定案**: OUT_OF_FUEL 族无 morale 键, org 恢复核 sub_140C6F960 不读燃料比, 警报条目无 org 项 (三证) |


#### 4.18.15 组织度/兵力维护链 (org 写者全集 + 补充交付 + 维修负定案)

org (+1064) 写者全集 (五种形态穷举; 同帧序位 = 相位 7 恢复 → 相位 10 attrition 扣 → 相位 12 战斗结算最后写):

| 写者 | 函数 | 公式与要点 |
|---|---|---|
| ctor | sub_140C6D470 | `+1056 = +1064 = 10000000` (100.0 定点初值) |
| 战斗扣减 | TakeDamage vtable[24] sub_140C8F510 | org/str 双扣 (§4.18.13 [24] 行); 百分比伤害变体 TakeDamageImmediate vtable[25] sub_140C8F770 (伤害按当前值百分比, 尾调 sub_140C8B710 伤亡上报) |
| attrition 扣减 | ApplyAttrition sub_140C6F5C0 | `+1064 −= ATTRITION_DAMAGE_ORG × +1080 缓存 /100000`; 行军中 (path count +524>0) 系数换 ATTRITION_WHILE_MOVING_FACTOR; **breakdown kind 三档** = 2 战斗中 (sub_140C00000) / 3 在训 (sub_140C89400) / 1 默认 |
| 每小时恢复 | sub_140C6F3B0 | `+1064 += sub_140C82C10 恢复量`, 钳 [0, [38]]; 恢复上限缩水: 基线 100000 → TRAINING_ORG (训练态) / STRATEGIC_REDEPLOY_ORG_RATIO (战略部署 +687 或模板+92) / 修正链取 min; 当前 org 超上限 → 压回 |
| 恢复计算核 | sub_140C82C10 | INFRA_ORG_IMPACT × (省基建−50000)/100000; 惩罚面 = 补给惩罚比 × SUPPLY_ORG_MAX_CAP 帽; OUT_OF_SUPPLY_MORALE 消费在 sub_140C6F960 (逐 statId 后处理, §4.18.14 已收) |
| 低 org 加速 | sub_140C82A90 | vtable[39] org 比例 < FASTER_ORG_REGAIN_LEVEL → 加速恢复分支 |
| 伞降完成 | sub_140C89F10 | `+1064 = PARACHUTE_COMPLETE_ORG × (1+mod370) × max_org/100000`; 并写 +1160 时间戳 (旧「战斗/到达事件时间戳」实为伞降) |
| 夺省惩罚 | sub_140C8B080 | `+1064 −= ORG_LOSS_FACTOR_ON_CONQUER × max_org/100000` 钳非负 |
| 赋值入口 | SetOrganisation sub_140C8F170 | 赋值 → 钳 [0, [38]]; 7 直调者 |
| 赋值入口 (str) | **SetStrength = sub_140C8F1D0** (army.cpp:738, 定案) | gs+2613 载入旗门 (载入中直写不钳) → +1056 = v → 钳 [0, [33]] (负值钳 0); "_Strength: %s, %i" 日志门 byte_14345252A; 与 SetOrganisation 完全对称; 调用者 = 伞降扰乱缩编 / CalculateActiveUnitStats 非战斗回满 / 读档·转移链 (sub_140247F00, 高置信) |

补充链 (相位 11 错峰日步):

| 环节 | 函数 | 要点 |
|---|---|---|
| 装备补充交付 | sub_14150E460 | reinforcement 推进器 sub_1415069F0 (补给距离门 SUPPLY_PATH_MAX_DISTANCE 钳); status==1 → progress += REINFORCEMENT_EQUIPMENT_DELIVERY_SPEED; status==2 → sub_140C78F60 装备入 +840 池 ("Reinforcing %lli equipment(s) to army") / upgrades 走 sub_140C78E90; 交付后虚调 vtable[22] RefreshAbilities |
| 人力比例 getter | sub_140C87F70 | `(1 − EQUIPMENT_COMBAT_LOSS_FACTOR × clamp(100000×str_damage(+1096)/max_str,0,100000)/100000) × 人力因子 sub_140C69780` (UI manpower 行消费) |
| attrition 装备损耗 | sub_140C6E100 | 逐装备条 (+872 容器 16B 元): 豁免因子 = (statId 66 RELIABILITY_FACTOR+100000) × min(100000, 原型+776)/100000; sub_140C73310 RNG 掷骰 → sub_141012850 从 +840 池直接扣除 (消失) → sub_140CD9D90 损失上报 (战斗中经 +424 数组分摊) |
| 人力重算 | sub_140C6A730/140C6A760 | 载入重建 sub_140C88D70 内, CArmyManpower(+976) value/need 按国家/tag 重填 |

维修负定案: 师装备**不存在**「损耗→维修→归还仓库」回路 — 损耗装备从师池直接扣除消失 (可靠度仅提高豁免概率); §4.8 维修全部是建筑侧 (CBuildingProductionLine +120 to_repair) 与铁路炮侧 (§4.8.7) 产线; 装备回流仓库只发生在师解散/改编/转属 (transfercountry 链)。

伤亡结算总入口 (sub_140C8B710, 8 参, TakeDamageImmediate 尾调; 定案): ① name seed hash = `0x5EA6BA9F − 0x4AD685B4 × (+28 id + 日(gs+1120))` 确定性种子 → ② +1656 killed > CASUALTY_COUNT_FOR_HISTORY_ENTRY(dword_143337D48) 且无 killer_definition(+1660) → 历史条目支 → ③ 装备损失逐条上报 (sub_140CDA570/CD9F60/CD9BF0 族) → ④ XP 损失 = stats[14] EXPERIENCE_LOSS_FACTOR 链 + define(qword_143331370) → 写 +1072 钳非负 → 尾部 RefreshAbilities (army.cpp:4222)。

载入重建零态 (sub_140C88D70, vtable1 域): 装备池惰性填充 sub_14100E730 (填充源 = **师模板装备需求表** (师模板+288 经 sub_1403C7680 构建, raw+1432 强制计数门 >0 时经 sub_141010D00 施加强制变体计数) + **强制变体池** raw+1472; 国家仓库仅作变体查表目标, 强制池条目量 >1.0 时**覆盖**模板需求量, 详 §4.3.18a) → 人力重算 → experience(raw+1072)==0 时 = raw+1464 种子 × 人力因子 (函数体内 "+1056" 系 ser 坐标, 勿混) → location 非零则 RefreshAbilities; gs+2613 只读门时跳过。
序列化两侧: writer 0x140C90550 ser+1040/+1048 (tok 10406/11979) ↔ loader 0x140C8C7E0 落 raw+1056/+1064 (§4.18.1 键位表)。

#### 4.18.16 部署/训练 daily 执行链

daily 入口 = **sub_140D0FFC0 (CDeploymentStatus::DailyUpdate, zone
"deployment.daily")**, 挂 CCountry::DailyUpdate 串行段 research 之后:
`sub_140D0FFC0(*(cc+3952), *(cc+3960), *(cc+3968), *(cc+4048))` — a2/a3/a4
(增援/升级/占领状态) 穿透传入装备分发作消费者。

每日七步 (函数体顺序):

| 步 | 函数 | 语义 | 置信 |
|---|---|---|---|
| ① 装备分发 | sub_140D10310 | 收集生产库存变体 (production+512 池拷贝) + 全部 CEquipmentDistributable 消费者 (cc+4600 资源 / 增援 cc+3960 / 占领 cc+4048 / 升级 cc+3968 / 容器#5 定时活动件 / 容器#6 HQ 件 / 容器#4 训练行 / cc+5544 operations / gs+1008 突袭逐国件) → 按优先级排序逐变体发放 (消费者虚槽[2] 收货返余额); 消耗经 sub_140E6EB90 从 production+512 扣除; 库存空 → 逐行缺口上报 sub_140CE9EA0 | 定案 |
| ② 人力配给 | sub_140D10F60 | 预算 = sub_140CFC300(cc+808) 可征人力; 先按优先级填容器#6 HQ 件 ({cur@136,tgt@140} 顶到目标); 训练行 sub_140D07C80 以 tag 为种子确定性洗牌 → 逐行 sub_140CE9400 按 tag 池配给 | 定案 |
| ③ 流亡人力分发 | sub_140D10CF0 | 遍历 politics+400 托管流亡 tag 数组 (count@+412): 预算 = *(流亡cc+832) 流亡专属人力; 逐行匹配 conveyor+152 (government_in_exile_tag) 配给 (deployment.cpp:1357 断言同域) | 定案 |
| ④ 行状态重算 | sub_140CEB9B0 | 逐行: 重算需求池 L+144 (← 模板); **L+104 max_training = min(装备满足率×(1+mod222), 100000×人力值池和/模板目标人力, 100000)**; 模板目标人力变化时 L+96 进度等比重定 (×旧/新); L+176 缓存模板目标人力 | 定案 |
| ④b/c/d | sub_140CE8720 / sub_14197FF50 / sub_140CEB5A0 | 停滞旗消费 (L+196 置位 → L+192 低字节 0xAA、清 196) → 限制触发器复检 (dep+272 上下文, 失败取最小理由) → 停线落笔 (L+192 = 理由 id, L+196 = 1); 停滞序列化键 = 14382 halting_reason (writer 尾) | 定案 (触发器内容高置信) |
| ④e 进度 tick | sub_140CEA930 | 未停行且 L+96 < max_training: L+96 += 100000×BASE_DEPLOYMENT_TRAINING/cost, 顶 100000; T==0 或 Instant army training 作弊 (byte_14332F62B, **控制台 `instanttraining`** — 命令表实名直证) +玩家国模板 → 直接 100000 | 定案 |
| ⑤ conveyor 收尾 | sub_140D141C0 → sub_140CEB7D0 | 逆序逐 conveyor 逐行: 可部署 ∧ L+96 ≥ 100000 → **sub_140CE8BA0 落师** (下表); 空行移除; 行数 0 的 conveyor 移除; 玩家国 → GUI 刷新事件 (type=14) | 定案 |
| ⑥ 宿主链上限重算 | sub_140D129B0 → sub_140D126A0 | 沿 dip+392 (dip = *(cc+3976)) 宿主链上溯 (循环检测断言 "Circular depenency in Overlord-Subject hierarchy" deployment.cpp:1484); dep+184 = Σ行需求人力 (含托管流亡国行) / dep+180 = 在场师人力和; 从属递归 sub_140D12AC0 | 定案 |
| ⑦ 情报统计重算 | sub_140D14010 | 清 dep+192..+239; 遍历 cc+656 全师对 *(师+312)+664/+672 各算 min/max/avg (零值师半权) → §4.18.10 表 | 定案 |

训练公式 (定案): `进度/日 = 100000 × BASE_DEPLOYMENT_TRAINING (qword_143332808,
lua=1 ×1e5) / cost`; `cost = (100000×T + mod66) × (100000 + mod67 +
mod223 + SF占比×mod381) / 100000`, T = tpl+416 training_time (天); SF占比 =
特种营数/总营数; 剩余天数 = cost × (100000−L+96)/100000/BASE (sub_140CE9550);
完成天数 = T×(1+修正)。装备满足率 (sub_141010160) = 100000×Σ已有/Σ需求
(需求表 = tpl+288)。

落师 **sub_140CE8BA0** (militarydeploymentconveyor.cpp:1036/1067 直证) 九步:
① malloc(1672B) + CDivision ctor sub_140C6D470; ② 定位 (div vtable+232 置省);
③ 模板套用 sub_140C8E550; ④ **装备过继 sub_140C6DF60(div+840, L+32)**;
⑤ **人力过继 sub_140C6A730(div+976, L+112)**; ⑥ 出生 XP = XP表值 ×
sub_140C69780(div+976 和) × L+96/100000 (XP 表 qword_143339500 +8×(idx−1); 钳 ≤100000×人力和);
⑦ 流亡分支 (dip+392>0 (dip = *(cc+3976), §4.10) ∧ 托管在册 → sub_140C044A0 + 编入流亡国军队);
⑧ 常规: sub_1406D2CA0(本国cc, div, 1) 编入军队; 订单组存活 → 匹配单位取
最少数者军团挂起 (sub_141837A50 + sub_14184D810); ⑨ 清偿 sub_140CE87C0
(库存池收尾 + 人力池全额退还 + 注销装备需求) + 续列判定 sub_140CEA540
(cv+72 amount==0 (∞) 或 系列序号 < amount 才续) (定案)。

启动链 (定案): CStartDeploymentCommand::IsValid 0x141BA39F0 → 部署校验
sub_140D0E740 (模板可训练; 对象基+504==1 → 路由宿主国 dep; ==2 → 需托管流亡在册 (断言 deployment.cpp:1357); 该字段 = §4.18.4 d+480 origin_type, 同一字段两视角)
→ 上限检查 sub_140D0EBE0 (`tpl+400 (对象基, = 目标人力同字段) 行权重 × 数量 + dep+184 ≤ dep+188`, 否则
"DEPLOYMENT_LINES_HIT_THE_CAP") → conveyor 创建 sub_140D0F4F0 (malloc 160 +
ctor sub_140CE6EA0 → push dep+72) → 行 ctor sub_140CE6DE0 (MI
CEquipmentDistributable@0 + CPersistent@24; **+32 = CEquipmentArcheTypePool**;
+192 低字节 0xAA 初值) → 注册 sub_140D0E0C0 (push 容器#4 + 上限链刷新,
gs+2613 载入旗跳过)。conveyor ctor 字段: +24 role token / +32 模板 / +40 名
SSO / +72 amount=0 / +80 priority=1 / +88 orders 对 / +152 giw tag
(对象基 tpl+504==2 = 流亡路由时; §4.18.4 d+480 origin_type)。

新字段: L (CMilitaryDeployment) +32 = CEquipmentArcheTypePool 已收装备池
(条目 24B {变体 ptr, ?, 数量@+16}; 落师过继 → 师+840) / +96 训练进度 /
+104 max_training / +152 tag 来源池 (8B 条, 人力配给匹配键) / +176 模板目标
人力缓存 / +192 停滞理由 id; 模板侧: tpl+400 行权重 / tpl+416 training_time /
tpl+480 (= 对象基+504 origin_type: 0=无 1=subject 路由宿主 2=流亡) 流亡路由; dip+392
宿主 tag / +368 从属列表 / +400 托管流亡列表 (count@+412); cc+832 = 流亡专属
人力 (cc+808 对象+24) (定案)。

#### 4.18.3a requests 执行链 (生成 → 分配 → 交付 → 清理)

五段函数级定案 (偏移基: q = *(army+1144); R = q+16; U = q+112):

| 阶段 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 生成·日步门 | sub_141510110 | `q+224 + 24×REINFORCEMENT_REQUEST_DAYS_FREQUENCY (dword_143337C10, 7 天) ≤ 当前小时` → 重建 (前置门 = `(gs 小时−43800000)%24 == 师id%24` 错峰, CArmy::HourlyUpdate 内联) | 定案 |
| 生成·重建 | sub_14150F740 | reinforcement 重建 + 超配回流 + upgrades 重建 + 经验折减; 每次写 q+224=now | 定案 |
| 生成·请求填充 | sub_141507410 | 逐 def: 缺口 = **模板需求表 (CDivisionTemplateData+264 need map) − (army+840 池存量 + Σ既有请求 need)**; 缺口>0 → 新建 176B CReinforcementRequest 或并入; 首个请求注册 R → cc+3960 (sub_14150A140) | 定案 |
| 生成·超配回流 | sub_14150AA00 | 池+请求 > 需求表 → 缩 need, produced 超余经 sub_140E6F910 退 ps+512; need 空 → status=2 | 定案 |
| 生成·upgrades | sub_14150F740 尾 | 收集 army+840 池变体 → def 级去重 → 对 deliveries 已发运量出净额 → 24B 元 {variant, 净额, 需求表量} 压 q+160; 注册 U → cc+3968 | 定案 |
| 生成·经验折减 | 同上中段 | CArmyManpower Σvalue > Σneed (**超员, 模板缩编场景**) → army+1072 experience ×= Σneed/Σvalue; 缺员不乘因子, XP 走 cap (≤ 1e5×Σ持有) | 定案 |
| 分配·主循环 | sub_140D10310 | deployment.daily (§4.18.16 步①) 首段: 收 ps+512 国家库存 → 收集消费者 (cc+3960 R 表 / cc+3968 U 表 / 部署三队列 / 装备市场国别表等) → sub_140D0BDD0 排序 (**优先级 = base@+16 + vtable[3]×priority@+8**, 平局 vtable[4] 身份) → 逐变体依序 `vtable[2](variant, remaining)` 分完; 消费量 sub_140E6EB90 扣 ps+512 | 定案 |
| 分配·请求叶 | sub_14150E070 | `produced += min(need−produced, remaining)` (archetype 档位对齐; **status≠0 不消费门**); 齐套 (readiness = 1e5×Σproduced/Σneed **聚合比**, 非逐变体 min) → status=1 | 定案 |
| 分配·升级叶 | sub_14150DA70 | chunk = min(1e5×EQUIPMENT_UPGRADE_CHUNK_MAX_SIZE, 元.request, remaining) (元.request −= chunk) → 新建 **CUpgradeDelivery** (96B: status@+8 / progress@+16 / total@+24 / produced 池@+32; ctor status=1 直接起步) 压 q+184 | 定案 |
| 交付·每小时 | sub_14150E460 | CArmy::HourlyUpdate 无条件调用 (前置门 sub_140DF6D30 被封锁不补); **三态状态机**: 0→1 = 日期 e+160 ≤ now (等待超时 = 请求日 + 24×REINFORCEMENT_REQUEST_MAX_WAITING_DAYS dword_143337CCC 14 天, 未齐套也发运) ∧ readiness>0; 1→2 = progress += 1e5×0.3/h (REINFORCEMENT_EQUIPMENT_DELIVERY_SPEED qword_143337770), total = clamp(army+72, [1e5, **1.5e6 = 1e5×SUPPLY_PATH_MAX_DISTANCE** (0x143331208)]), total_progress 每小时重写; 2 = 台账 kind7 + **sub_140C78F60 并入 army+840 池** ("Reinforcing %lli equipment(s) to army with id %i:" army.cpp:3127) + 齐套毁请求/未齐套复位 (need←produced 拷贝 / produced 清 / date+336h); upgrades deliveries 同型内联 (→ sub_140C78E90 army.cpp:3148) | 定案 |
| 交付·人力通道 | sub_14150E730 | 逐 tag (CArmyManpower+976 m+48 标签表): 转入 = min(**0.1×Σneed_tag**, cc+808/832 可用, 缺口) **∧ 进度门** (manpower_pool q+88 进度 += 1e5×rate/h, > 1e5×转入量才发); rate = REINFORCEMENT_MANPOWER_DELIVERY_SPEED(1e6)×army+64/1e10; 扣国库 sub_140CFE7E0 | 定案 |
| 清理·R 摘除 | sub_14150F3A0 | 请求计数==0 ∧ CArmyManpower 缺口≤0 → 从 cc+3960 移除 | 定案 |
| 清理·U 摘除 | sub_14150F740 尾 | 计数 (q+172)==0 ∧ U+96 注册旗 → 从 cc+3968 移除, 清旗 | 定案 |
| 清理·取消全部 | sub_14150A640 / sub_14150A7E0 | 逐请求 produced 退回 ps+512 → 毁 (army 拆卸/变 owner 路径; garrison 宿主变体同型); 师删除 → army+840 池整体退库 (sub_1401D6690; 池退库执行件 = sub_140E60E50 → CProductionStatus+512, §4.18.20) | 定案 |
| 台账 | sub_141374FB0 / sub_141374F90 / sub_141371390 | 缺口登记/发运消费 CLogisticsStatus (cc+3992) 计数板 kind 0/1/6/7 (kind 索引 = *(def+1336)); logistics.daily 逐师聚合需求表 | 定案 |

驻军 (garrison) 平行链 (对照): 创建 sub_141507740 (宿主 CStateGarrisonData) /
日重建门 sub_14150FED0 / 每小时 sub_14150E6A0 (**total 无下钳, 与陆军 [1e5,·]
区分**) → sub_141506D30 (**速度 =
GARRISON_EQUIPMENT_DELIVERY_SPEED qword_143331320 = 4.0** 与陆军 0.3 分槽;
总时长 = sub_14150A530 州补给距离查表) / 交付并入宿主池 host+144 (非
army+840) + 置州脏旗 / 人力 sub_14150EA90 + sub_14150F5F0
(GARRISON_MANPOWER_REINFORCEMENT_SPEED qword_143331270; chunk = [1400,2000]
人 × 距离因子 [0.7,1.0]) / 驱动 sub_140FF6D10
州级逐 garrison / 摘除 sub_14150F420 (定案)。REINFORCEMENT_DELIVERY_SPEED_MIN
(0.6) 全码零引用 = 死 define。

关键语义定案: **CArmyManpower m+8 value = 已持有/到位 (交付写入者
sub_140C67F50 加向 m+8), m+40 need = 应编需求**; 缺口 = Σneed−Σvalue; XP
折减 = ×(Σneed/Σvalue) 超员 (Σ持有>Σ应编, 模板缩编场景) 才降。请求族**主vtable运行时分配接口**: [1]=Wants/
GetAmount / [2]=Distribute / [3]=乘数 / [4]=身份 — 与持久vtable (对象+24,
§4.00.1 Save/writer/reader 槽) **两套槽位勿混** (定案)。ps+512 =
CEquipmentVariantPool 国家装备库存 (data@+520, count@+532; +536 第二池 =
替换源 data@+544, count@+556); CEquipmentVariantPool 布局 = {vtable@0, 运行时
向量@+8 (24B 元 {variant, ?, amount@+16}), 序列化向量@+32 (16B 元 {variant,
amount@+8}), allow_zero u8@+56}, ctor 0x14100C710 — produced/army+840 池/
ps+512 库存三处同型 (定案)。army+72 = 交付总时长缓存 (init −100000 未置;
语义 = 补员运输时长, fix5 活值域 3.0~14.6; **部署后冻结的部署期一次性快照** —
探针定案: DR0 watch 2.5 游戏年零命中, 强制重建/交付直调零命中, 师链
(ctor/重建/请求填充/交付/人力/进度/注册/日步门) 静态全链 0 写点; 写点疑在
师部署/新建一次性计算, 未定位)。CDivisionTemplateData+264 = 装备
需求表 need map {data@d+272, count@d+284}, 16B 元 {CEquipmentVariant*,
amount i64} (定案)。

#### 4.18.17 师计划加成（planning）积累与消耗链

**师级日更机制**（无独立小时链）: CArmy[19] 日 tick（sub_140C78B00）尾段调
sub_140C8FDA0（定案）。师计划加成存 **army+1136**（战斗加成本体）; og+304
plan_value（§4.24.3）只是计划优势评估视图（battleplan 箭头 UI + AI 微操门，
sub_140BEC940 消费成员 +1136/cap 比作输入）— 两层分工（定案）。

| 段 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 积累门 | sub_140C78300 | 非移动（+524==0）、非 HQ（+436）、有 location、og+112 前线计划槽省列表含所在省（或 og+48==3 海军入侵且 malus 门过）; 无部署将领时按 feature57 门硬禁 | 定案 |
| 增益 | sub_140C855A0 | base（**PLANNING_GAIN 0.02/日**; 入侵分支 NAVAL_GAIN×malus 合成）× (1+Σ254 PLANNING_SPEED) × cohesion==3 时 ×0.5 × comms 缩放 → army+1136 钳上限 | 定案 |
| 上限 | sub_140C84C70 | (PLANNING_MAX 0.3 + Σ255) × (1+Σ256) × comms_cap / 1e5; 255/256 三源（国家+将领+location） | 定案 |
| comms 缩放 | sub_140C84570 → sub_140C15D30 | 将领部署 + HQ 落后前线省数（og+452 front / og+460 入侵）索引 5 档表 {1.0…0.8}; 无将领或师不在将领订单上 → NO_HQ 0.8 档; **表型 define 槽存堆指针** | 定案 |
| 消耗 | （日衰减） | 非积累态按 **DECAY 0.01/天**（手动令 +584==2 → 0.03/天）× (1+Σ647)，钳 0; floor(100×bonus) percent 走国家 view+408 纯 GUI 副通道 | 定案 |
| 战斗消费 | CLandCombatant::[22] sub_1412AF7C0 (combatland.cpp:1067 每小时修饰符重算) | combatant+216 门 → 把师 +1136 以 **kind=4 条目（attack=defense）** 推入 CUnit+368 战斗修正队列并累进 +392/+400 乘积 — §4.18.5「滚动累加事件队列」业务名 | 定案 |

脚本接口: min_planning/has_max_planning 触发器 = 100000×bonus/cap 比较式;
`add_planning` 效果加的是将领 skill 非师 bonus; CBoostPlanning 角色效果可经
sub_140C72A80 直喂师 +1136（定案）。

#### 4.18.18 演习（exercise）流

**载体定案**: 演习状态 = **COrdersGroup 两字节（+413 bTraining / +416
StopAtMax）**，由 COrderSetTrainingCommand（ctor 0x14183B160 / IsValid
0x14184EC00 / Execute 0x14184AF70 / Clone 0x14183EE00）经 GUI 演习钮
sub_1416DD7B0 写入并沿军群树传播（ordersgroup.cpp:2760 SetTraining）。
**XP 入口定案**: 真演习 XP = **sub_140C8FF80**（CArmy::[19] 日 tick 尾,
army.cpp:4906）; sub_140C895B0 实为**碾过/强推（overrun）结算**（体用
XP_GAIN_PER_OVERRUN_UNIT; §4.4.22 行已同步订正）。

| 段 | 函数 | 语义 | 置信 |
|---|---|---|---|
| 在训谓词 | sub_140C89400 | 组旗 ∧ 战争门 ∧ 非交战引用 ∧ CArmy[34] 兵力比 > TRAINING_MIN_STRENGTH ∧ StopAtMax | 定案 |
| 每小时代价 | sub_140C6F3B0 / sub_140C78990 | org 恢复帽 = TRAINING_ORG; 燃料 ×ARMY_TRAINING_FUEL_MULT（顺带钉死 ARMY_*FUEL_MULT 全族公式）; 在训不长挖掩 | 定案 |
| XP 双公式（日结） | sub_140C751B0 / sub_140C73560 | 师经验 = UNIT_EXPERIENCE_SCALE × 末级阈值 × min(装备状态, 规模比) ÷ (tpl+416 训练时间 × mod66/67/223/381) × 师数 × 缺油系数 → +1072; 国家军经验仅 **level ≥ DEPLOY_TRAINING_MAX_LEVEL** 的师产出 ÷ 全国军数 | 定案 |
| 自动启停 | sub_141A55110（每 3 日错峰） | 供给/装备 START/STOP_*、满级比例 STOP_TRAINING_FULLY_TRAINED_FACTOR、同省接战即停 + 全国战况门（交战军占比 > STOP_TRAINING_ACTIVE_COMBAT_RATIO → 全停） | 定案 |
| 训练级 | — | = +1072/(1e5×师数) 按 UNIT_EXP_LEVELS 阈值表数级 | 定案 |


#### 4.18.19 CSubUnitDefinition 全字段表 (1656B=0x678; 主 vtable 0x142789E08; Save 槽[1] = 断言桩 "Not Implemented." subunitdefinition.cpp:517 → **def 不落存档**; reader = 槽[4] sub_14101E130 37 键; 槽[7] sub_14101C180 = 载入后校验/回填; ctor sub_141018B30 类别播种 / sub_141018080 名串; 定义库单例 qword_14332F090, 装载 = common/units 递归 per-entry malloc(0x678) → sub_141018080(名串,索引) → vtable[3] 基址直调 Load; 热重载按 +1420 DB 母本索引保位克隆覆盖)

| 偏移 | 类型 | 名称/语义 | 键 | 置信 |
|---|---|---|---|---|
| +8 | uint32 | 名字 token (lexer id; DB 双查找键) | — | 定案 |
| +16 | uint8 | 有效旗 (ctor 1; TNullObject 0) | — | 定案 |
| +24 | MSVC SSO 串 32B | 名字串 {buf@24, size@40, cap@48} (CCountrySpecificNamedItem 主体) | — | 定案 |
| +56 | uint32 | CCountrySpecificNamedItem 附带 u32 (拷自源; 语义未决) | — | 推定 |
| +64 | SSubUnitStats 内嵌 992B | 统计子对象 (子表见下) | — | 定案 |
| +1056 | 176B 运行时对象 | sub_140555FB0 构造 {vec@1056, vec@1080, vec@1104, string@1128, 双 RH 形图@1168/1200, 尾 dword −1@1224 / 1@1228}; reader 零覆盖 | — | 形态定案 |
| +1232 | vector 24B | critical_parts (元素 32B 串名 → 按名经 game item DB 查找 sub_140AC4D30 回填; 未知名报错; ⚠ 元素对象类型待裁 — CSubUnitDefinition* 与 ship.cpp 消费点布局冲突 (候选条目消费 +360 权重 i64/+368 上限/+328..+352 修饰对, 若为 def 则与统计数组重叠), 倾向 game item DB 条目, RTTI 未取) | 15358 | 写读点定案/元素类待裁 |
| +1256 | int64 fixed×1e-5 | critical_part_damage_chance_mult | 15428 | 定案 |
| +1264 | 匿名结构 (NNB 形状) 向量 24B | reader 零覆盖, 不序列化 | — | 形态定案 |
| +1288 | 匿名结构 (NNB 形状) 向量 24B | categories — CSubUnitCategory* 数组 (重名报 "Duplicate subunit category") | 11352 | 定案 |
| +1312 | 匿名结构 (NNB 形状) 向量 24B | essential — CEquipmentArchetype* 数组 | 13723 | 定案 |
| +1336 | 匿名结构 (24B 形状) 向量 24B | need_equipment_modules — 元素 24B 嵌套容器, 叶 = {模块/模块类别 id u32, 数量 u32}; 子键 any(11163) = 组内多选 | 15245 | 定案 |
| +1392 | uint32 向量 24B | required_dlc — u32 token 数组 | 15200 | 定案 |
| +1416 | uint32 | map_icon_category 枚举 {infantry 0 / armored 1 / other 2 (ctor 默认) / ship 3 / transport 4 / uboat 5} | 12178 | 定案 |
| +1420 | uint32 | **DB 母本索引** (ctor 落 db 数组下标; 克隆体按此回溯母本 = §4.7 既有锚) | — | 定案 |
| +1424 | uint32 | manpower | 10300 | 定案 |
| +1440 | uint32 | training_time | 12258 | 定案 |
| +1444 | uint32 | group (串→token; =12188 support 时槽[7] 强制 type 位 0x1000000) | 63 | 定案 |
| +1448 | u64 | **type 类别位域** (逐名 OR 位, 38 位全集: 0x10000000 = artillery、0x100000400 = heavy_fighter ∨ fighter — 原散锚「载具位/国旗」两说废; 槽[7] 校验掩码 airwing 0x1F0037FC00 / ship 0x80004003C1 / carrier 例外 0x1C00010000) | 225 | 定案 |
| +1456 | uint32 | 主类别 id (位域首个可映射位; ctor 0 已非零不覆盖) | — | 定案 |
| +1460 | uint8 | carrier-capable (槽[7] 自 need[0] 原型 +1000 拷贝) | — | 定案 |
| +1461 | uint8 | can_be_parachuted | 12762 | 定案 |
| +1462 | uint8 | active (⚠ 读取后取反存储: 文件 yes → 内存 0) | 11390 | 定案 |
| +1463 | uint8 | special_forces | 12989 | 定案 |
| +1464 | uint8 | cavalry | 10112 | 定案 |
| +1465 | uint8 | is_artillery_brigade | 16884 | 定案 |
| +1466 | uint8 | marines | 13807 | 定案 |
| +1467 | uint8 | rangers | 17501 | 定案 |
| +1468 | uint8 | mountaineers | 13806 | 定案 |
| +1469 | uint8 | collateral (ctor 默认 1) | 13408 | 定案 |
| +1470 | uint8 | affects_speed (ctor 默认 1) | 19409 | 定案 |
| +1472 | uint8 | can_exfiltrate_from_coast | 13038 | 定案 |
| +1473 | uint8 | divisional (ctor 默认 1) | 16875 | 定案 |
| +1474 | uint8 | regimental (ctor 默认 1) | 16872 | 定案 |
| +1475 | uint8 | allow_in_army_hq | 16847 | 定案 |
| +1476 | uint8 | allow_in_non_army_hq (ctor 默认 1) | 16846 | 定案 |
| +1480 | int32 | division_3d_model_priority (带符号; 负值告警) | 10061 | 定案 |
| +1484 | uint8 | priority 已设旗 (reader 置 1) | — | 定案 |
| +1488 | uint32[5] | 载入后脚本求值区 (sub_14101A7C0 逐槽填; 语义未决) | — | 形态定案 |
| +1508 | int32 | 名字表索引 1 (全局表 qword_14332ED90 条距 120B; 0=无; ship 族本地化校验) | — | 定案 |
| +1512 | int32 | 名字表索引 2 (同上) | — | 定案 |
| +1516 | int32 | 名字表索引 3 (同上) | — | 定案 |
| +1528 | int64 fixed×1e-5 | hit_profile_mult (ctor 默认 1.0) | 15443 | 定案 |
| +1536 | uint32 | land_air_wing_size (缺省回填 100) | 12646 | 定案 |
| +1540 | uint32 | carrier_air_wing_size (缺省回填 10; 非 capable 却设 → 清 0) | 12645 | 定案 |
| +1544 | uint32 | mega_carrier_air_wing_size | 10110 | 定案 |
| +1548 | uint32 | submarine_carrier_air_wing_size | 17094 | 定案 |
| +1552 | pdx small_vector | same_support_type {data@1552, cap@1560, count@1564, alloc@1568, 内联 2×token@1576} | 19339 | 定案 |
| +1600 | uint32 向量 24B | allowed_battalion_groups — u32 token 数组 (计数 @+1612) | 16876 | 定案 |
| +1624 | MSVC 串 向量 24B | enable_ability — 32B 串元素 | 14574 | 定案 |
| +1648 | id 对 {i32, i32} | DLC 锁定对 (ctor {−1,−1}; Load wrapper 从 reader 上下文盖章) | — | 定案 |

**SSubUnitStats 子表** (基址 = def+64; 相对偏移 s): s+16 factor 头 (恒 1.0) /
s+24 combat_width (11471), 累加写点 `+= src×w/100000` / s+32 max 追踪字段甲 (取 max(dest,src), 命中连带拷 +40 串; 推定, 业务名待裁) / s+36 max 追踪字段乙 (独立取 max; 推定) / s+40 sprite 串 (61) {buf@+40, size@+56, cap@+64, SSO 阈 15} / s+72 battalion_mult 容器 (13688) /
**s+96 = 主统计数组 int64 fixed ×78 (def+160 起 8B/项; 槽号 = (s−96)/8 = statId, 全表
= §4.31.27; statId 16 = fuel_capacity (原「+288 max_fuel」散锚即 def+288 = 槽 16)、
statId 65 = reliability (def+680)、statId 69 = fuel_consumption (def+712))** /
s+720 = need 与 need_equipment 两键共用 CEquipmentArcheTypePool 池 (12111/15244;
16B 元 {CEquipmentArchetype*, 数量 fixed}; airwing 类槽[7] 强制恰 1 条; 加权合并写点 = sub_141011150(s+720, src+720, w, 92233720200000), 第四参 = 钳位界, 方向与单位待裁) /
**五上下文修正器 CUnitAdjuster 40B (def+816 night / +856 fort / +896 river /
+936 amphibious / +976 snow; 各 {vtable, 上下文 token@+8, attack/defence/movement 三
fixed5}; 原「+816..+976 五统计组细节未决」收口)** / def+1016 (s+952) = 动态地形修正数组
{data@+952 CUnitAdjuster*, count@+964 uint32, 元跨距 40; 预填地形库条数−1 条,
elem+8 = 地形 token; cap@+960/alloc@+968 按 24B 形推定}。
原「+564 attrition 豁免旗」散锚经查实为 CDivisionTemplate 字段 (ApplyAttrition 读
*(CArmy+952)+564; TakeDamage 函数首同旗短路 = **豁免面含战斗伤害**, §4.18.13 [24]),
非本类; +1336 logistics kind 索引 host 待裁 (本类该处 =
need_equipment_modules 容器 data 槽); 原「+1536..+1548 基地容量四档」= land/carrier/
mega/submarine 四个 air_wing_size (上表定案)。

#### 4.18.19a SSubUnitStats 运行期方法群 (subunitstats.cpp 8 函; 加权累加/平均/装备乘子/修正器合并/查找)

清册 (8/8 函): 0x14142AAA0 (384, :185..:216 断言串 20 枚 = 源在 20 个「不应贡献」statId 上须为 0) **统计数组级部分累加器** / 0x141429D30 (286, :321 断言) **AddWithMultiplier 加权累加主函** / 0x14142B270 (168, :377 断言) **AddWithMultiplierAndSupport 支援连变体** / 0x14142BE20 (183, :892 `TotalSubUnits > 0` 断言) **统计平均器** / 0x14142A580 (100, :401 `EquipmentMultiplier > 0_fixed` 断言) **装备乘子施加器 (空军)** / 0x14142D490 (70, :118 CLogStream `SSupportCategoryStatMultiplier::WriteMembers called without a valid category.`) **SSupportCategoryStatMultiplier::WriteMembers** / 0x14142C660 (55, :882 `Should not ever happen!` 断言) **CUnitAdjuster 查找器** / 0x141429020 (64, :377 断言) **MergeTerrainAdjusters**。

**统一 thunk 层** — 八裸函数均不经vtable, 由 subunitdefinition 域一层 thunk 转接 (thunk 一律 `+64` 取 SSubUnitStats, 与「内嵌 @def+64」互证):

| thunk | 目标 | 实参固定值 | 业务名 (日志/断言实证) |
|---|---|---|---|
| 0x1410198E0 / 0x141019C80 | D30 | w=100000, a5=0 (跳主循环), a6=1, a7=1 | 部分合并 (子集 + 池 + 战宽 + max 追踪 + 修正器 + 钳位) |
| 0x141019EA0 | D30 | w=100000, a5=1, a6=1, a7=1 | **AddWithMultiplier** (ship.cpp:2263 日志 "Calling AddWithMultiplier: %i") |
| 0x141019F40 | B270 | w=a3, a4=100000×count, a5=支援旗取反, a6=加成向量 | **AddWithMultiplierAndSupport** (divisiontemplate.cpp:1424 日志同名) |
| 0x141019F80 | BE20 | a2=100000×总子单位数, a3=100000×支援连数 | 统计平均 |
| 0x141019AD0 | 9020 | — | 修正器单独合并 (支援连分支) |
| 0x141019F30 | AAA0 | (dest 数组, src def+160 数组) | 数组级部分累加 (airwing 链) |
| 0x141019EF0 | A580 | (dest, base, 装备对象, 率) | 装备乘子施加 |
| 0x14101AFB0 | C660 | — | 修正器查找 |

**AddWithMultiplier (D30) 主循环** (a5 门): 78 项逐项 `dest[i] += trunc(src[i] × a3 / 100000)` (魔数 0x29F16B11C6D1E109 + >>64 + >>14 + 符号修正 = 64 位无符号除以 100000, 数值逐例验算定案), 三例外: statId 16 (fuel_capacity) 与 69 (fuel_consumption) **直加** (不经权重); statId 34 (navy_range) **钳位直加**, 界 ±92233720200000。随后无条件追加 sub_141429580 子集 (34 项: 6..15 陆军战斗 / 35/36 水雷 / 37..43 海军 / 56..59 铁路炮 / 60/61/65..67/69/70/74/75 通用; statId 0 与 60 走第二权重 a4, 16/69/70 直加)。⚠ a5=1 时主循环与子集对重叠 statId 同权重双计, 是否设计意图 (或 IDA 对该 2 参调用参数丢失) 待裁。

> AddWithMultiplierAndSupport (B270) = D30 的支援连变体: 624B 整拷源数组 → 套加成向量 (引擎向量 {data@+0, cap@+8, count@+12}, 24B 元 {statId, 值, 启用旗}; 仅启用项 `buf[statId] += 值`) → sub_14142BA70 按 w 缩放 (SSE 展开, 同 /100000 魔数) → 下游同 D30。聚合核 0x140B9AD70 (§4.31.27) 内: 战斗营走 141019EA0, **支援连 (v224 旗) 走 141019F40** (a5 = 旗取反 → 跳修正器合并, 由 141019AD0 单独合) + 0x141019C30/0x141019C60 把支援统计折算进加成向量。
> **平均器 (BE20)**: a2 = 总子单位数, a3 = 支援连数 (推定); 按总数平均 = statId 0 (default_morale) / 19..22 (探测/可见性) / 34 (navy_range) / 43..45 (三协同) / 60 (max_org) / 63 (armor) / 64 (piercing) / 65 (reliability); 按 a2−a3 (战斗营数) 平均 = statId 3 (hardness) / 74 (hot_gain) / 75 (cold_gain) + 五固定 CUnitAdjuster + 动态地形数组每项 (sub_141014830 缩放); 每项前哨兵检查 `(x + 0x7FFFFFFFFFFFFFFE) > 0xFFFFFFFFFFFFFFFC` → int64 极值视为无效保留原值, a2=0 时全部置 0xFFFFFFFF。
> **装备乘子 (A580, airwing 消费链)**: `dest[i] += mod[i] × trunc(a4 × (base[i] + 100000) / 100000) / 100000` (i = 0..77; dest = a1+96, base = a2+96, **mod = a3 装备对象 +256 数组** — 装备对象内嵌统计数组于 +256, 与 CSubUnitDefinition 的 +160 不同基); a4 = EquipmentMultiplier。调用方 sub_140F661E0 (airwing.cpp:1444): 逐装备条目 {对象@+0, 数量@+8} 按率 `100000×count/total` 施加, 经 sub_141019F00 取装备 +256 数组逐 statId 求差累入 a1+2408 显示数组。
> **查找器 (C660)**: 依上下文 token (elem+8) 顺序查 s+792 → s+752 → s+832 → s+872 → s+912 五固定块, 再线性扫 +952 动态数组 (跨距 40); 未命中 → B51 断言 + **回退返回 s+792** (非空指针, 调用方必判)。
> **部分累加器 (AAA0)**: 断言源在 20 个 statId (0/6..16/43/56/60/61/67/74/75 = 陆军战斗/补给/侦察/铁路炮/通用上限/重量/适应化类) 须为 0, 只允许贡献 35/36 (水雷) / 65/66 (可靠性) / 69/70 (油耗); 钳位 77 (build_cost_ic) ≥ 10000 (= 0.1 IC 下限) / 65 ≥ 0 / 11 ≥ 0。被 airwing 聚合链 (thunk 141019F30, 调用方 sub_140F661E0 / sub_140FA6320) 按「只加海空侧统计」语义消费。

**SSupportCategoryStatMultiplier** (48B; 书内零覆盖, 本批全表; 元素跨距 48 由 CPdxHybridInlineBufferAllocator<SSupportCategoryStatMultiplier,21,int> 内联分配器与 vector 搬运族三源同证):

| 偏移 | 类型 | 语义 | 证据档 |
|---|---|---|---|
| +0 | vtable 指针 | 序列化分发; WriteMembers = 0x14142D490 (槽位推定 [2]) | 定案 (错误日志实名) |
| +8 | CSubUnitCategory* | 支援类别对象; 发射 `category` (702) = *(uint32*)(cat+84) | 定案 |
| +16 | 容器 (24B) | stat 乘数表 {data@+16, cap@+24, count@+28, alloc@+32}; 元素 {statId uint32@+0, 值 i64 fixed×1e-5@+8} | 定案 |
| +40 | uint8 | `add` 旗 (13802) | 定案 |
| +41 | uint8 | `display_as_percentage` 旗 (10048) | 定案 |

> WriteMembers 语义: cat 指针空 → CLogStream 一行式错误 (通道 4096, 无中断); 否则写 category 值 → add → display_as_percentage → 逐元素 (值 ≠ 0 才写, 经 sub_1413E8820(writer, statId, 值))。宿主容器 (内联分配器 21 元归属 DB) 与 vtable 槽位归属推定。


#### 4.18.20 单位删除链 (CGameState::DeleteUnit = sub_1401D6690; ~654 行)

签名 (gs, unit, disband_flag); a3 = 删(0)/散(1) 旗 (§4.32 delete_unit 族); 日志门
byte_143452529 打 "Deleting unit ..." (vtable+104 槽[13] 取名)。五段编排 (定案):

| 段 | 动作 | 关键函数 |
|---|---|---|
| 入闸 | unit 指针压 gs+1400 数组 (计数 gs+1412; §4.2「已登记删除」去重闸, sub_1401D7460 查重同数组); 尾部对称自摘 (swap-erase) | — |
| 远征预清理 | vtable[7] (+56) 父单位 +476 > 0 → 清 unit+476 + 从属主国 idreg (国+760/+772) 摘除 (⚠ 760/772 vs 784/796 双 idreg 分工待裁: 推定 760=收编远征 / 784=借调); 非载入态 (gs+2618 == 0) 宿主国 CCountryAI 记账 | sub_140C04370 (ClearExpeditionaryOwner) / sub_1402AB5A0 (→ CStrategicAI+8960 48B 条 {tag@+8, 计数@+12} 按原初国归并累加 = 远征人力 AI 台账) |
| 删/散分叉 | a3=0 删除 → **名号回收**: army → cc+112 mode0 / convoy → cc+120 mode1 逐船 / railway gun → cc+128 mode2 (三 mode 表 = §4.3.9); a3=1 解散 → **人力退还**: army 走 CArmyManpower (army+976) value 容器 (data@+16, count@+28) 逐 tag 分摊 `100000×金额×value÷1e10` (sub_140BB5490 原初国归一去重) 退 cc+808; 总系数 = (100000 − DISBAND_MANPOWER_LOSS) × {1 流亡支 / ENCIRCLED_DISBAND_MANPOWER_FACTOR 常态 / NAVAL_TRANSFER_DISBAND_MANPOWER_FACTOR 海运} ÷ 100000 (**流亡支 IDA 丢支 / convoy 15 位定点式 / railway gun 128/64 除数 三处待 PE 验算**); convoy 人力输入 = Σ +840 池元素 +2056 | sub_140C8E520 / sub_140C3D900 / sub_140E8D310 / sub_140C69A30 → sub_140CFE1B0 / sub_140D65040 |
| 引用清理 (不分删散, 序) | ① 借调单位: 门 sub_140C01960 (unit+472 ≠ unit+480 且非同原初国) → 国+784/+796 idreg 摘除 ② iface +1336 列表摘除 (门 unit+12 旗; **+1336 = SelectionList 选中列表定案** — airutil.cpp :143/:168 断言 "Invalid selectable in SelectionList" 直证, 链节点 {+0 对象, +8 u32 类型 (==2 单位), +16 next}, §4.15.16; ⚠ 全局槽差: airutil 侧读 qword_14332F6A0, 本节原记 qword_14332F698 相邻槽, 同对象两入口或两对象未核双注保留) ③ 省在场四表摘除 (主表 prov+224/+236 + 三分型表 248/272/296 系 swap-erase, §4.14) ④ 国名册三型分派 (type0 army → country.cpp:8333 / type1 舰队 cc+632/+644 扫描 / type13 railway gun) ⑤ **CCountryAI::RemoveReferences 双派发** (经 CCountry::RemoveUnit 一次 + 锚内直调一次, 同一 cc+552 目标; 订阅表逐项 vtable[23] OnUnitDeleted 级联) ⑥ gs+1600/+1612 玩家选中单位表摘除 ⑦ logical_country → cc+360/+372 战区数组 → theatre+128/+140 og 数组三级扫描, 逐 og 摘成员钩 (og+80/+92 摘除 + og+152/+164 与 +176/+188 引用表清 + og+415 脏旗 → 重算 og+452/+456; **钩节点 = &unit+184, 清 +8 置 +40 — 形状待 PE 验算**) | sub_14070FFD0 / sub_1402A00F0 / sub_140E7FA10 / sub_140710140 → sub_1406FF9F0·sub_140D597F0 族·sub_1406FFBD0 / sub_1402AC3C0 / sub_1401EBCF0 / sub_140BF29B0 |
| 尾段 | type==13 且 unit+1088 ≠ 0 → 用其 og 命令列表构造 CUnassignRailwayGunFromOrdersGroup (ctor sub_140E8E630, RTTI 直证; sizeof 72) → IsValid sub_140E8F590 → Execute sub_140E8F1F0 (§4.33 19871) → holder 复位 sub_1401C28C0; vtable[0](unit,1) 标量析构; 非载入态 iface vtable[23] 派发 + 216B UI 事件 (码 2) 入 iface+1192/+1204 队列 + sub_140B6B050 刷新 | sub_140E8E630 / sub_140E8F590 / sub_140E8F1F0 / sub_1401C28C0 |

配套定案: cc+808 人力池 = {tag@+8, 常态池@+12, 流亡池@+24} (sub_140CFE1B0 =
CCountryManpower::Add, manpower.cpp:466 断言 "Giving exile manpower to a nation
not in exile"; exile 旗直加流亡池, 常态经 sub_140CFE290 从世界人力池 cc+1120
扣减可得量后入池 — 扣减分支待 PE 验算)。名号回收/重登记的精确语义待 PE 验算
(删除期 tracker 建 176B CNameGroupMember 后释放, 取新名回填)。

#### 4.18.21 缴获装备链 (战斗/碾过 → 师侧落袋)

| 环节 | 函数 | 机制 |
|---|---|---|
| 加权随机分发 (多师) | sub_140C790A0 (定案) | 签名 (师包装条目列表 {data@0, count@12}, 源装备池, 汇集池, unused); 权重 = 人力因子 sub_140C69780(army+976) × stats[15] EQUIPMENT_CAPTURE_FACTOR (师统计对象+280; 缺省 = BASE_CAPTURE_EQUIPMENT_RATIO qword_143336E60); 每师份额 = 100000×(权重×capture_factor)/1e5÷Σ权重 对源池逐变体预分 → 非借调师 (sub_140C97430/sub_140C97B90 双门) 装备需求登记 (国+3944) + sub_14100CAE0 入 +840 池 → 非战斗则超配回流 sub_14150AA00 → vtable[22] RefreshAbilities; 余量按 RNG (random.cpp:187 OOS 断言; army.cpp:5372/5375 检查点) 权重累计区间线性落点选师, 每单位 (100000 fixed) 一掷 |
| 概率回收 (单师逐条) | sub_140C8BE60 (定案) | 遍历源池序列化向量 {data@+32, count@+44} 16B 元 {原型指针, amount}: amount≤0 跳过; 接收量 = amount×stats[17] RECOVERY (统计+296)/1e5 + amount×RELIABILTY_RECOVERY(qword_143335AA0)×(原型+776 可靠度)²/1e10 钳 ≤1e5; RNG 判定 (army.cpp:5253): 量 ≥1e5 全收, 否则 rand≥量 收 → sub_14100CCE0 入 +840 池 + 同入汇集池; 任一条收得 → 超配回流 + RefreshAbilities (army.cpp:5296) |
| 三比例缩编执行叶 | sub_140C8A550 (定案) | (army, 损失归属 tag\*, 装备缩比, 人力扣比, 兵力缩比) 各 max(x, 100000): +840 池快照 (sub_1403022F0) → sub_14100DE60 按比缩池 → 按 tag 从 CArmyManpower(+976) 扣人力 (扣得>0 且 army+476>0 借调门 → sub_1402AB5A0 记远征 AI 台账) → 池缺额 sub_140CD9F60 / 人力 sub_140CDA570 损失上报 → SetStrength(100000×当前/兵力缩比) → RefreshAbilities; 唯一调用者 = 伞降扰乱 vt0[41] |

调用者: sub_1412B9460 ×2 (战斗两侧, 各传己方师列表 + 战斗对象 +576 缴获池) / sub_140C895B0 (overrun 碾过, 传被歼师 +840 池 — 装备流向补记) / sub_1412B9F20 (战斗结束: 快照战斗对象 +112 缴获池按比缩 → 遍历己方师列表逐师概率回收)。

同簇伴生: **订单组将领事件派发叶 sub_140C8AEA0** (调用者 sub_1413E1760 战斗带): og = +192 判空 resolve → og+3708 ≤ 1 军衔门 (违者断言 "The deployed leader is not an army leader!" army.cpp:3835) → 构造双 event scope (scope₁ = {og, army+472}, scope₂ = {事件目标}) → sub_140A79BA0 分发器触发 — 事件名未决 (静态不可见, 可游戏内钩分发器第三参观名), 其余全链定案。

**army.cpp 簇对账增补 (25 函数全读, 全员体内 army.cpp 锚)**: **CArmy real dtor sub_140C6D8A0 全拆解 (定案)**: 四vtable盖写 (+0/+16/+184/+824 四基组) → requests q (+1144) 虚槽[1] 删除 → **位置共享互摘** (+1416 宿主非空 → 宿主 +1424 向量 swap-erase 摘自身并清槽; 再遍历自身 +1424 对每跟随者同样摘除) → 名持有 (+832) 删除 → 断言 army.cpp:227 (国家军队容器内仍可析构即崩 = DeleteUnit 引用清理必须先于析构) → army_history 清理 → 各向量/池逐一销毁 (+1504/+1480/+1424/+1216/+1024/+992/+928/+904/+872/+848) → officer 记录清理 (+1296 内嵌 + +1384 向量) → +1152 日期静态复位 → 尾 CUnit 基类 dtor (累加器归位在彼处, 本 dtor 不触碰)。

**fake intel 惰性链 (定案)**: **+564 门 → sub_140C8D600 内 `*(tpl+564) && !+968` → sub_140C8E010 加权随机选假情报模板** (owner 国现有师模板收集 → 剔 ignore → 空集 fatal "no existing templates for creating fake units" army.cpp:342 → 加权随机 → **+968 = 选中 CDivisionTemplate\***, NULL 回退 +952 真模板 → 师名双注册 sub_1409C8A90/C1A90); 调用方 3 处 (统计 hub 惰性门 / reinforcement 族 / 遍历列表, 后两者未展开)。**统计 hub 新写点**: +1120 dig_in_cap 运行时写者 = sub_140C73820 (公式未展开); **+1184 = vtable[39] org 比例缓存**。

**日 tick 挖掩三态 (细化定案)**: 门 = 移动(+524>0) ∨ 战斗 ∨ 演习 — **战斗中冻结不动 / 移动·演习清 0 / idle 增长后钳 [0, +1120 cap]** (§4.18.18「在训不长挖掩」实为清零); 无 theatre 时查国 theatre 数 (cc+372) → sub_140EFA2F0 自动挂 theatre (推定)。

**伞降完成 sub_140C89F10 补遗 (定案)**: **fire on_paradrop 事件** (scope₁ = og+192 门 + army+472 owner / scope₂ = 目标 id) + **完成即 +1112 dig_in = 0** + vtable[29] 到达通知 (语义推定)。

**演习 XP 尾链 (定案)**: XP → +1072 钳 100000×人力因子 → 国军经验份额 sub_140C73560 (>0 走国通道 sub_1412A64B0) → 尾构造 **SArmyUnitActivityData** (RTTI 名直证) 经 sub_1412A8E40 推送 (陆军活动记录通道, 消费侧未决)。

**位置变更级联 sub_140C8E9E0 (定案)**: og+152 成员逐个运输成员登记 + +1424 跟随者八参广播; **与位置共享宿主 (+1416) 同省落位 → 构造 72B 命令 (sizeof 与 CMergeArmiesCommand 一致) 经 qword_14332F6A0 vtable+136 → sub_142250B00 POST** (合并投递触发侧; 执行在命令层 tok 14344)。

#### 4.18.22 师上限评估链 (SDivisionCap 32B; division_template_cap_type.h)

SDivisionCap (pdx_optional\<32B\>, 旗@+32; §3.12): `{+0 cap u32, +4 类型枚举 {0 DivisionCap / 1 SpecialForces / 其他断言 "Name is not defined for CapType." :22 + "NA"}, +8 计数1 (现役), +12 计数2 (队列), +16 合计, +20 剩余可部署数 (两类统一语义), +24 源模板 data 指针}`。模板 data 基 = CReferencedDivisionTemplate+24 (registry 解析值 +24; cap@data+572 与 d+572 同位)。

| 计算器 | 函数 | 语义 |
|---|---|---|
| A DivisionCap | sub_141980AF0 | set 门 = 模板 data+576 (division_cap 已设旗, §4.32 set_division_template_cap); cap = data+572; 计数1 = Σ sub_140C7E7C0(师)==data 逐师 (国师列表经 dep+280 母国 sub_1406EB770); 计数2 = 部署队列 (dep+96) 条目模板比对 (+24==data; 过滤旗剔除已部署态 u8@条目+196) |
| B SpecialForcesCap | sub_141980DD0 | set 门 = 模板网格 (data+168 ×count data+180) 任一营 def+1463 特战; cap = **max(SPECIAL_FORCES_CAP_BASE qword_1433354E8 + mod 367, SPECIAL_FORCES_CAP_MIN dword_14333560C + mod 368) + mod 628/1e5** (mods 经 dep+280 母国 cc+1464); 余量 = `(cap − 队列 SF 权重 + 部署中权重)/本模板权重` 整除 (100000 定点防溢出 + 负向 floor) |

模板 SF 权重 sub_140B9A240 = Σ 特战营 (def+1463) 每营权重 = 母国 cc+1464 修正 + 1.0 负值钳 0: {+1461 can_be_parachuted → mdef 608 PARATROOPERS_…_FACTOR / +1466 marines → 609 / +1468 mountaineers → 610 / +1467 rangers → 611 / 其他特战营默认 100000}; 合计**向上取整**。合并 = sub_14197FCC0 (两 optional set 者 append); 判限 sub_14197FDF0 = 取 +20 最小条目, `min余量 < 师数` → 受限。消费者 sub_14136A8B0 (部署请求校验, 虚槽形态): 师数组@+40 逐师 {null/远征+476/类型匹配 (data+480==2)/指挥力 (Σ sub_140C11450 − 4208 基线, 不足报 LEADER_DEPLOY_INSUFFICIENT_COMMAND_POWER)} → 判限 → 受限组装 `"#~ army is limited by division " + CapType名 + " ."`。

#### 4.18.23 勋章域运行期 (unit_medals.cpp; 3 函闭环 — tooltip 构建 / AddEntry 本体 / 花费包装)

簇清册 (体内 cpp 锚 3/3):

| 函数 | 行数 | 体内锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_141449F10 | 616 | 断言 :643 "We shouldn't get here" (B51, 闩 byte_14338A4CB) + loc 串 MEDAL_NAME_TITLE / COMBINED_MEDAL_EFFECTS | CUnitMedalStore 勋章 tooltip 构建器 (单勋章三段 / 多勋章聚合) | 新 |
| sub_1414468B0 | 110 | 断言 :970 "Unit was null when trying to add a history entry" | AddEntry 本体 (army_history 入队 + 授勋触发) | 已收调用形, 本批补全门与常量 |
| sub_141447440 | 35 | 断言 :809 "Unit was null when computing medal cost" (B51, 闩 byte_14338A4CC) | 勋章花费计算包装 (:809 = 书 §4.18 0x329 同行号互证) | 新 |

**tooltip 构建器** (sub_141449F10; (store, out, 条目数组 {d, n@+24}, mode)): a1 = **CUnitMedalStore 确证** (调用者 = 勋章历史行件 BuildTooltip, 经 sub_140C0DC90(宿主+32) 解出 — 与 AddEntry 同一解出函数); mode 0 = def+184 源 + store+224 上下文 / 1 = def+568 源 + store+416 上下文 / 2 = 断言。单条目 (n==1) = 三段拼装 (标题段 → MEDAL_NAME_TITLE → 主体段带条目+312 → 收尾段); **聚合 (n>1) = 双 std::map (def→count / def→累计值) → 值 = 累计勋章数 × 元+4 权重 / 100 (魔数除法直证) → sub_14055D110(qword_14332ED90 + 120×modifier_key) 取名 (modifier 定义表全局, 120B 元) → 带色数值**。条目+312 = fixed×1e-5 权重基值 (§4.18.1 行已升级定案)。

**AddEntry 本体** (sub_1414468B0; (授勋上下文, 条目 328B); §4.32 调用形互证): 上下文 = {+8 unit (空断言 :970), +16 可选对象, +24 u32, +32 store 宿主, +40 队列 {d, n@+52}}。授勋门 = **store+608 < dword_1433377B0 (cap define 直证)** ∧ 随机源 (unit_medals.cpp:1038) < sub_14055E360(国+1464, key 650) + qword_143337718 (玩家国时加修正; key 650 = 国价值 / key 651 = 授勋基值 — 书三锚互证); 旁路 = 非玩家国 ‖ byte_143330F7E 全局旗。落队 = **条目+312 = key651 值 + 100000** → 入队 → sub_14144CC20 选章 (勋章随机授勋互证) → 挂章两变体 (上下文+16 非空走 sub_141447070 / 否则 vtable+56 走 sub_141446B30, 实参均含队列末元素) → 尾 sub_14144B250 (on_add_history 类派发)。

**花费包装** (sub_141447440): unit 空 → 断言 :809 + **回退纯基础花费 `*out = *(def+760)` (def+760 直证)**; 全路径 = sub_141447520(store, out, def, 国, a4) (书「有单位时 ± 国修正后比对 PP」实现体)。

未决: 五全局 define 名 (dword_143336234/dword_1433377B0/qword_143337718/qword_14332ED90/qword_1430900F8) / byte_143330F7E 旗语义 / 挂章两变体分工。

#### 4.18.24 单位命名库 (unitnames.cpp; 2 函闭环 — 三军命名模板 / 唯一名生成器)

簇清册 (体内 cpp 锚 2/2; 全新):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_140AF02C0 | 89 | :305 CLogStream (65540) "<X> - expecting country tag or (generic) keyword." | unitnames DB 单文件块解析循环 |
| sub_140AF3A90 | 384 | :175/:178/:232 三断言 (B51/B52/B52, 闩 byte_14333A2E0..E2) | 唯一名生成器 (后缀递增 + FNV 查重) |

**DB 形态** (TGameItemDatabase 族, 装载包装 sub_14018BA40): db+40 = generic 名池表 (16B 元 {token, CUnitNamesPool*}); **db+64 = 每国数组 120B/国, 按国索引直下标** (sub_140BB5490 — §3.2 间接表函数落点互证)。块解析 (sub_140AF02C0): token 12537 ("generic") → generic 池 get-or-create (120B **CUnitNamesPool**, RTTI 字面直证; 四串 +8/+40/+64/+88); 否则串 → 国 tag → 国块装载: **13350 fleet_names_template → 块+0 / 15173 task_force_names_template → 块+32 / 14328 air_wing_names_template → 块+64**; 其他 token → 块+96 向量 (16B 元) get-or-create 池。

**唯一名生成器** (sub_140AF3A90; (out, loc_key, default_key, taken_table, loc_ctx)): loc_key 不存在 → :175 断言; default 也无效 → :178 断言 + 拷原串兜底; **循环 N = 1..: localizer 以整型后缀格式化 "<键文本> <N>" → FNV-1a → taken_table {16B 元 {hash, 串*}} 线性查重 (hash 相等再串比对)** → 唯一即出; 空串 → :232 断言 + 键文本兜底。调用方 = 邻域 5 包装 (舰队/特遣舰队/空军联队命名族各带 taken 表; 宿主容器未逐追)。

未决: 各命名族 taken 表宿主容器 / CUnitNamesPool 四串语义。

#### 4.18.25 海军部署运行期 (deployment.cpp; 11 函闭环 — CNavalDeployment::CreateUnit / 改装重部署 / CTaskForce 布局)

簇清册 (体内 cpp 锚 11/11):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_140D0F5A0 | 504 | :456/:517 日志 ("CNavalDeployment::CreateUnit AddUnit %s" 类名串证) | **CNavalDeployment::CreateUnit** (建特混+逐船+人力拨付) | 新 |
| sub_140D0EEC0 | 305 | :567 断言 + :685 CLogStream | 海军改装完成舰船重部署 (三路分派 + 预备队兜底) | 本体新定性 |
| sub_140D0E740 | 184 | :1357 断言 + DEPLOYMENT_CANNOT_TRAIN_* 串 | CanStartDeployment 四段校验 | 互证 + 细节新补 (可训失败串优先级 = 国+464 自定义 > HQ 旗 > SPECIAL_UNITS; origin_type == 2 → 宿主国 dip+400 托管流亡 tag 数组核验) |
| sub_140D129B0 | 55 | :1484 断言 | 宿主链上限重算入口 (环检测) | 已收互证 |
| sub_140D0EB00 | 48 | :274 断言 (B52, 闩 byte_14333CC82) | 生产海军线部署目标校验/修复 | 本体新定性 |
| sub_140D12F10 | 35 | :1155 | **RemoveAllGIWConveyors** (逆序删全部 giw 带; 调用方 = EndWarsTerminate 流亡清退 §4.10) | 新 |
| sub_140D118B0 | 26 | :1390 断言 (B51) | GetMaxAdditionalLines = (dep+188 − dep+184) / 模板+376 每行人力 | 互证 + 公式与模板 +376 新偏移补 |
| 其余四函 (conveyor 命令执行体) | 27×4 | 各断言 | Deploy/RemoveConveyor(Line) 同构四件 | 已收互证 |

**CDeployment 布局增补** (cc+3952): +72 _MilitaryDeploymentConveyors data (计数 +84) / +184/+188 已用行人力和与上限 / +272 装备校验池 scoped ptr / +280 属主国。

**CTaskForce 布局 (新, 1888B; ctor sub_140D63320)**: +16 创建日期 / +472 属主 tag / +480 当前省 / **+864..871 = 0xAA 初值区 (污染哨兵)** / +884 类型 = 8 (省+248 特混数组成员判定项) / +1200 自身 idpair。舰船 2360B: +64 变体/经验块 / +1832 特混反指 / **+2056 人力缺口** (申请 − 实拨)。生产海军线: +12 特混 / +20 舰队 / +32 变体三 idpair + +40 船体 / +48 XP 来源。

**CreateUnit 流程 (定案)**: 目标校验修复 (异国特混断言 + idpair 清空) → 选落点特混 (线+12 在目标省直用 → 舰队匹配扫省+248 数组 → 属主任一 → 全无**新建特混** + 日志 :456) → 逐艘建船 (2360B → 船体/变体定 → cc+808 人力扣拨缺口写 +2056 → 入特混 → 命名三级 (显式名 > 模板名表随机 > 默认) → XP 过继) → 尾 vtable[22] finalize + 新建特混带 idpair 或入预备队 + 注册国海军。

**改装重部署** (sub_140D0EEC0): 舰 idpair 空或解析失败 → :567 断言; 三路分派 = 目标特混异于现特混换船 / 目标舰队沿现特混搜空位并入 (无则新建 + 预备队化, 失败 :685) / 无显式目标 → 部署省找类型 8 特混并入或移出重建 + 巡航令。

未决: CTaskForce 三 vtable 槽语义 / 舰船 XP 与人力缺口消费侧 / 类型 8 外的特混类型枚举全景。

#### 4.18.26 军种精神视图装配 (country_army_spirit_view.cpp; 1 函 = 0x141D22090 — 书未收簇)

**机制 (233 行, 定案)** — 断言 country_army_spirit_view.cpp:361 `TakenSpirits.GetSize() <= 9` (闩 byte_14338C674; 超出即 bug)。精神 id 构造 = 串拼接 `<名>_spirit` → sub_140FD6790 转 id (直证 §4.28 army_spirit 事件 type 键语义)。已取精神集合 = 国家精神管理器 (sub_140BB48F0 → sub_1406CF890) **+80 向量 / +92 计数**, 过滤 `sub_140FCF630(elem)+120 == id`。**军种精神 def 三点布局: +16 名串 / +48 精神 id / +120 类型 id**。GUI 行件 (a1+32 向量 / +44 计数): **+1424 精神名 std::string (缓冲+1424/容量+1448) / +1456 精神 id**; def 匹配 = def+48 == item+1456 ∧ stricmp(def+16, item+1424); 全不中 → 全局空对象 qword_14332FB10 (null_object.h:140 "_pInstance" 断言, 闩 byte_143339CF2); 装配 sub_141D21A70(item, 国, def, 0); 收尾 a1+24 子对象重刷 (sub_141C50580/sub_141C51E90, 推定图表/列表)。静态分配器 off_143085170 全局单例复用 ✓。
