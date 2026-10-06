

### 4.3 CCountry (国家)

CCountry 是最大的聚合根, 下挂数十个子系统指针。

| 项 | 值 |
|---|---|
| RTTI 名 | CCountry (RTTI + GER 探针双证) |
| sizeof | — |
| vtable RVA | 0X27E7360 (校验用, 部分上下文) |
| writer | sub_1407191B0 (键 token 直译; 方法群 0x1406C0000-0XUNRESOLVED, country.cpp 断言串 173 处) |
| loader | switch 直译 (case→槽位, 与 writer 键双通道) |
| 挂载点 | `cc = 国家数组[国家 idx]` (数组 = `*(gs+784)`, 8 字节/项) |
| 基类 | CAIOwner@+0 / CPersistent@+0 |

#### 4.3.1 字段布局 (+8..+5632)

> 全状态复位件 = **sub_1406E2DE0** (CCountry 每国复位: 字段默认表恢复 + 关联对象清点; 两调用入口 = CCountryDataBase::ReadCountryFiles 装载期 + gamestate 新局构建逐国 — §4.28.18; 本册各表「复位 sub_1406E2DE0」注均指此件)。

| 偏移 | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| +8 | uint32 | tag_id | |
| +12 | tag_id | **last_collaborated_surrender_recipient** (writer sub_1407191B0 门 >0 → sub_140BB4E70 取 tag 名串, 键 19368; reader case 19368 → sub_140BB5560; 复位 sub_1406E2DE0 置 0) | 写门 >0; 落盘形 = 引号 tag 名 |
| +16 | MSVC 串 32B | **name 缓存** (本地化全名; sub_140716580 名称缓存刷新 = tag (或 +4876 original_tag>0 优先) + 意识形态 + cosmetic_tag(+5256) 组合本地化键渲染; 调用方 = 外交/GUI 全域 16 处) | 不序列化 (定案; 探针 GER="德意志帝国") |
| +48 | MSVC 串 32B | **adjective 缓存** (TAG_ADJ, "_ADJ" 常量参与构造; cap@+72=15) | 不序列化 (高置信; 探针 GER="德国") |
| +80 | MSVC 串 32B | **definite name 缓存** (TAG_DEF, "_DEF" 常量; surrender 拷贝它做消息文本; +84/+88 = buffer 内部, size@+96, cap@+104=15) | 不序列化 |
| +112 | CNameGroupTracker* | division_names_tracker (mode 0; 发射键 14605) | §4.3.8 起; vtable 0X2935BB8 (探针+RTTI) |
| +120 | CNameGroupTracker* | ship_names_tracker (mode 1) | writer ADEC0 0x3C85 (定案) |
| +121..+127 | — | = +120 指针尾字节 (无独立字段) | |
| +128 | CNameGroupTracker* | railway_gun_names_tracker (mode 2) | writer 键 0x3463, 门 *(cc+128)≠0 |
| +129..+135 | — | = +128 指针尾字节 | |
| +136 | CNameGroupTracker* | operative_codenames_tracker (mode 3) | writer ADEC0 0x3D19 |
| +144 | MSVC 串 32B | **prev_name** (改名前上一代 name 副本; sub_140716580 尾段: 新值≠旧值时落旧值) | 不序列化 (高置信; 探针 GER 三串均空=未改名) |
| +176 | MSVC 串 32B | **prev_adjective** (同上) | 不序列化 |
| +208 | MSVC 串 32B | **prev_definite** (同上) | 不序列化 |
| +240 | uint32 向量 24B | cached trade influence 数组 {data@240, cap@248, count@252, alloc@256} — 8B 值, 按下标 *(obj+4) 取 (探针 GER cap=count=333=全局 tag 槽数; Reset 按 gamestate vtable+72 扩容) | 断言 "Trying to get cached trade influence before it exists" (sub_1406EC770) |
| +252 | uint32 | 上述数组计数/有效位 | if(*(a1+252)) 门 |
| +264 | uint8 | _HasCachedTradeInfluence 旗 | 断言原文 (sub_140712930/1406DAAF0) |
| +272 | uint8 | 运行时旗 (+272 见上; +280 无静态可见消费 (全域命中皆异类, 负定案), ctor qword a1[35] 零填; 消费 = sub_141F3BFA0 随机国家候选资格门 (错误串 FE_RANDOM_COUNTRY_ERROR_NO_COUNTRIES 直证; ⚠ weathermanager.cpp sub_140F20EF0 同偏移异对象勿混); ctor qword a1[34] 零填; **全量国家双槽恒 0**, 与 +5209/+5210 major 族不同义) | 不序列化 (定案) |
| +288 | uint32 | 休眠成员 (ctor 零填, 全 dump 无读写点, 运行时恒 0 — 负定案; 疑裁撤特性残留) | 不序列化 (定案) |
| +292 | uint8 | 休眠成员 (ctor 零填同 +288 序列, 全 dump 无读写点 — 负定案) | 不序列化 (定案) |
| +296 | 匿名结构 (72B 形状) 向量 24B | **OOB 待加载队列** {data@296, cap@304, count@308, alloc@312} — 72B 元 {串@+40}; 0X140702E70 遍历调 LoadOOB (拼 "history/units/<名>.txt" → vtable+24 Parse); 门 = owned_states(+1156)>0 或 tag≤0 | 不序列化 (高置信; 探针 GER count=0) |
| +320 | MSVC 串 32B | **当前 OOB 文件名** (LoadOOB 写入 "history/units/X.txt" 路径) | 不序列化 |
| +352 | CNavyTheater* | 海军剧场 | vtable 0X29D2B88 (探针+RTTI) |
| +360 | CTheatre** | theatres 容器数据指针 — writer 壳 `if((cc+372))` 计数>0 才整块写; 舰队在 +632/+644 | §4.24 |
| +368 | uint32 | theatres 容器 cap | loader case 12217 增长码 {data,cap,count,alloc} |
| +372 | uint32 | theatres 容器计数 | §4.24 |
| +376 | 指针 (allocator) | theatres 容器 allocator | 同上 |
| +377..+383 | — | = theatres 容器 alloc@+376 指针尾 (四元组 {data@360, cap@368, count@372, alloc@376} 到齐) | |
| +384 | 指针数组数据 (8B 元) | **air_theatre 指针数组数据** | writer 尾段 ADEC0 0x4DED 循环 + 断言 "Trying to remove air theatre…" (sub_1406E8C90) |
| +396 | uint32 | air_theatre 计数 | 同上 |
| +400..+431 | — | = air_theatre 容器 alloc@+400 (四元组 {384,392,396,400}) + **侵入式串链表 24B@408** {head@408, tail@416, count u32@424, u32@428} (节点 48B {MSVC 串 32B@+0, next@+40}; 清扫 = sub_14061C4F0 逐节点 free 串堆缓冲 + SSO 复位; ctor 纯零填; **全 dump 无引擎写点 = 休眠成员**; 不序列化, dtor 唯一触点 — 休眠定案; ctor unwind 异常清理路径亦调 sub_14061C4F0(a1+51) 为第二触点 (异常安全语义); 全 dump 67 调用点皆清扫/复位用途无插入点 — 业务名不可静态考, 负定案) | |
| +432 | uint32 | **instances_counter** (可定制建筑实例计数器; writer 键 12464 **恒写**; loader case 12464 读而弃之; 与 +436 无伴生门关系; 探针 GER=1022) | 定案 |
| +436 | uint8 | templates_locked (仅真写; 兼 reason 串门: 门开则 MSVC 串@cc+464 **空串照写 `""`**) | |
| +440 | CDivisionTemplate** | 编制模板 id 容器数据 | **GUI: TemplateChanger 可改编模板列表源** (锁+过时+HQ 三滤; sub_14169D590) **+ 驻军模板列表** (占领驻军窗 [2] 0X14156C940) |
| +441..+451 | — | = 编制模板容器尾 {cap@448} | |
| +452 | uint32 | 编制模板 id 容器计数 (MIO 关联区) | |
| +453..+463 | — | = 编制模板容器尾 {alloc@456 = &off_143085170 哨兵} | |
| +464 | MSVC 串 32B | **templates_locked reason 串** {buf@464, size@480, cap@488=15} | 定案 |
| +496 | fixed×1e-5 | command_power | §4.3.11 country_fields; **GUI: HQ 部署 CP 行** (populate 缓存 view+17744; HQ_DEPLOY_CP_COST) |
| +497..+503 | — | = command_power@+496 尾 — +496 实为 **i64×1e-5 8B 定点** (消费 sub_1406EAE40 记账) | ; 块 dtor = sub_1414E6F80 (CCommandPowerAllocator) |
| +504 | int64 | **战斗力分配池** (与 +496 联动记账) | 断言 "pCombatPowerAllocator->GetAllocator == this" (sub_1406EAE40, country.cpp) |
| +512 | CCommandPowerAllocator** 向量 | 战斗力分配条目容器 {data@512, cap@520, count@524, alloc@528} (分配器类 ctor sub_1414E6F40, 56B+; 入表 sub_140714830 `*(*(cc+512)+8*(cc+524)++) = a2`, 1.5× 增长; 出表 sub_1406EAE40; 消费 12+ 处; 不序列化) | |
| +536 | CVariables* | 国家脚本变量 (variables 族, reader country_variables73) | §4.3.8 起 |
| +544 | 8B (双 u32 hash 种子) | scripted_gui_random — writer ADFE0 0x3D64 裸整数; loader case 15716 双写 +544/+548 双 hash 混合态 | §4.3.8 起 |
| +552 | CCountryAI* | AI state 挂链: csa = rp(rp(cc+552)+2800)+2800; 本指针 vtable 0X2736CA0 (探针+RTTI); 挂链末段 +2800 = CStrategicAI 内部 CPersistent 基子对象 (vtable 0X27E2088; 本体 vtable 0X27E1FB8, sizeof 9016), 非再次解引用; 部长八指针与 AI 主干见 §4.34; 挂链容器见下四行 | §4.3.8 起; §4.34; writer 0X14066B3F0 |
| csa+144 | int32 向量 | ai_strategy 平行数组 A — 112 槽, data@csa+144+24i (= base+2944 起, 帧约定见 §4.34.5); 条 12B {value i32, target u32, id u32}; id 仅槽 9/16/21 写 token 名 | writer 0X14066B3F0 |
| csa+2832 | 匿名结构 (12B {i32 value, u32 target, u32 id}) 向量 | persistent_strategy 平行数组 B (元素 12B = push 件 sub_14064D830 直写 8B value+target + 第 3 dword, 与 A 侧同构 — 定案) — 112 槽, data@csa+2832+24i (= base+5632 起; 与 A 同条结构); B 槽运行时形状 = {data@+0, cap@+8, count@+12, alloc@+16} 24B pdx 向量, 12B 元素, 自带多态分配器 (reader sub_14064D830 直证); 真 dtor (vtable 0x1427E1FB8 槽[0] 0x14064D060 → 成员 dtor sub_14064C980) 的 eh vector destructor iterator(MID+5632, 24B×112) 直证 112 个 24B 对象原生 C++ 数组逐元素析构 — 内联数组说定案; ⚠ 旧「dtor 释放 {data@2816..alloc@2832} 8B 元向量」系 dtor 侧 **MID 相对**偏移 (= csa+16/24/28/32, 对象前部另一小向量), 与本数组 (csa+2832 起) 不重叠, 两套锚系混用致假冲突 (已消解) | writer 0X14066B3F0 |
| csa+5520 | 匿名结构 (40B 计划条目) 向量 | **allowed_strategy_plans** {d@csa+5520, c@csa+5532} (= base+8320) — 元素 40B {计划名串 32B, +32 u32 计划库下标}; **运行期唯一写者 = 日更重建 sub_140664C10** (遍历 CAIStrategyPlanDatabase, 条目+72 触发器对国家 scope 求值); Save/Load 键 15260 | §4.34.11 |
| csa+5664 | CAIResearchNeed | 科技完成/效果注入 need 聚合 (= base+8464; 访问器 sub_14064D200) | §4.34.6/§4.34.9 |
| csa+5696 | i32 | days_to_need_update (日更开头清 0; Save 13445) | §4.34.11 |
| csa+5700 | i32 | days_until_next_rebuild_access_list (日更 −1, ≤0 重置 rand%5+5; Save 13443) | §4.34.11 |
| csa+5808 | uint32 向量 | military_access {d@csa+5808} — 440×u32 | |
| csa+5856 | CAIFocus 槽 (72B) 内联数组 ×9 | **vector\<CAIFocus\>×9 焦点类别权重表** (= base+8656; 72B 槽 {vtable, weight i64@+8, CAIResearchNeed@+16, 引擎向量@+48}; 九类实名见 §4.34.11; copy ctor sub_14064B220 逐槽对位定案) | §4.34.11 |
| csa+5880 | token 向量 | **历史焦点列表** {d@csa+5880, cap@csa+5888, c@csa+5892} (token u32 向量; ai_historical_focus_list; cnt>0 时 DecideFocus 走历史路径) | §4.34.10 |
| csa+5904 | CAIResearchNeed | focus 类目+计划+科技 need 聚合 (= base+8704; 日更清零重算, 写经 sub_1413C5260; 打分读入口 sub_1406516E0) | §4.34.6/§4.34.9 |
| csa+5936 | 双 u32 | AI 私有种子 (xorshift 状态; 日更重掷; Save 10647) | §4.34.11 |
| csa+5960 | i32 | **irrationality 非理性度** (−1 = 未掷; 日更 sub_140652A00 一次性掷点, 溢出断言 ai_strategy.cpp:4457; 读点 = GetIrrationality 访问器 + 决策门 sub_14108F750) | 定案 |
| csa+5965 | u8 | **战略首轮就绪旗** (= base+8765; 宿主 = CStrategicAI **定案**, 20 处访问全经 GetStrategy sub_1401DBCE0; UpdateStrategy 末置 1 / 全局复位 sub_1406539F0 清 0; AI 模块日/周更首判门 — **非人控判据**, 人控门 = byte_14332F639) | 定案 |
| csa+6064 | 内联定长 per-tag 槽 | 他国战力/威胁缓存 (日更逐国写 4B×i; 本国 0); 非堆容器 (dtor 不触, 无堆缓冲) — 高置信 | 推定 |
| csa+6132 | i32 | **num_wanted_divisions** (= ai_wants_divisions; −1 = 未算; 计算 sub_140650CC0, 细化数组 csa+6136..6160; UI "Nr Wanted Divisions: %i" 直证) | 定案 |
| +560 | CFlagManager* | **国家脚本旗 store** (set/country_flag 族落点; 解引用后 {entries@+8, count@+20}, 条目 48B {token@+8, setdate@+24, value\|days@+40} — country.flags savefull 直出同构; ⚠ flag token 取值 = 全 lexer 域（mod 旗在 lexer 扩展段，读侧上界必须用 lexer_token_max 运行时值，非原版 10 万界）) | vtable 0X295D3D8 (探针+RTTI); 全字段布局与同族宿主 §4.13.3 |
| +561..+567 | — | = CFlagManager 指针尾 | |
| +568 | CGameDate 内嵌 24B | {vtable1@568, hours@576=43808760 ctor 哨兵, vtable2@584} — **pride_of_the_fleet 关联日期** (与 +600 date_lost 成对; 复位 sub_1406E2DE0 尾置 +592 与 +608) | 不序列化 |
| +592 | uint32 | pride_of_the_fleet.type — id 对之 type (id 对 {id@+596, type@+592}; 初值 = **qword_14333D528 全局 8B 拷入**) | §4.3.8 起 |
| +596 | uint32 | pride_of_the_fleet.id — id 对之 id | §4.3.8 起 |
| +597..+607 | — | = pride_of_the_fleet id 对 {type@592, id@596} 尾 (ctor 整 qword 拷 qword_14333D528) + **第二 CGameDate@600** 头 | |
| +608 | hours | pride_of_the_fleet_date_lost (哨兵 43808760 照发) | §4.3.8 起 |
| +609..+615 | — | = **第二 CGameDate {vtable1@600, hours@608=43808760 哨兵, vtable2@616}** 的内部 (+608/+616 = 同一日期对象的 hours/vtable2); dtor 将两日期 vtable 复位 CGregorianDate 基 vtable (CGameDate⊂CGregorianDate) | |
| +616 | vptr | 第二 CGameDate vtable2 — ADEC0 序列化代理 (规则: hours = arg−8); 与 +608 同字段 | 定案 |
| +617..+631 | — | = 第二 CGameDate vtable2@616 尾 + **u8@624 pride_of_the_fleet 日期有效旗** (定案: reset 同组零填; 日更 sub_1406E76A0 旗开读 +608 折算失旗舰天数, ≥ dword_1433321A8 define 窗口外免罚; 置 1 = sub_1406DADE0) + 填充@625..631 | |
| +632 | CFleet** | 舰队 容器数据指针 (元素 = CFleet\*; 特混舰队经 CFleet+184 二级展开 — 全特混平铺收集器 = sub_1406D35A0 逐 CFleet\* append 其 +184 task_force 容器, navy 页 Update 0X141ECCCA0 消费; 原「{键,数} 舰型汇总」系 vector append 误读, 负定案) | §4.16 (writer 键 15156 = fleet 级 / 15157 = task force 级, 两级对象树); **GUI: B13 navy 页取全特混舰队平表** |
| +633..+643 | — | = 舰队容器 {data@632, cap@640, count@644, alloc@648} 内部 (ctor sub_14011DF40 + dtor 擦除) | |
| +644 | uint32 | 舰队 容器计数 | §4.16 |
| +645..+655 | — | = 舰队容器 count@644 尾 + alloc@648..655 | |
| +656 | CArmy** | 师列表 容器数据指针 — {data, count} | §4.18 |
| +657..+667 | — | = 师列表 {data@656, cap@664, count@668, alloc@672} 内部 | |
| +668 | uint32 | 师列表 容器计数 | §4.18 |
| +669..+679 | — | = 师列表 count@668 尾 + alloc@672..679 | |
| +680 | CRailwayGun** | 铁路炮 容器数据指针 | |
| +681..+691 | — | = 铁路炮 {data@680, cap@688, count@692, alloc@696} 内部 | |
| +692 | uint32 | 铁路炮 容器计数 | |
| +693..+727 | — | = 铁路炮 count@692 尾 + alloc@696..703 + **休眠 24B 向量@704** {data@704, cap@712, count@716, alloc@720 = CPdxNewDeleteAllocator 哨兵} (8B 平凡元素; ctor {0,0,0,哨兵} / dtor 0x1406CBBC0 分配器整体 dealloc 非逐元析构 / 日更时体 0x1406FDBA0 仅清 count; **全 dump 四元组扫描无引擎写点 = 休眠成员**; 空态: 全量国家 count 恒 0; 不序列化 — 休眠定案, 业务名不可静态考 (负定案)) | |
| +728 | 内嵌 | cached_navy_strength: {d@+736, c@+748} 8B 元素 {舰种 token, 数量} (宿主 vtable = CNavyStrengthCache::vftable, 类名直读) | §4.3.8 起 |
| +729..+759 | — | = CNavyStrengthCache (vtable 0X27E71D0) vtable@728 尾 + **容器 {data@736, cap@744, count@748, alloc@752}** 四元组补齐 | |
| +760 | 内嵌块 | expeditionaries_sent 容器块 {count@+772}; writer `if(*(a1+772)) sub_1406C8960(a2, 13427, a1+760)` | §4.10.19 |
| +772 | uint32 | expeditionaries_sent 计数 (写门) | 定案 |
| +773..+783 | — | = expeditionaries_sent 容器 {data@760, cap@768, count@772, alloc@776..783} = count 尾 3B + alloc | |
| +784 | 内嵌块 | volunteers_sent 容器块 {count@+796}; writer 键 13426 | §4.10.19 |
| +796 | uint32 | volunteers_sent 计数 (写门) | 定案 |
| +797..+807 | — | = volunteers_sent 容器 {data@784, cap@792, count@796, alloc@800..807} = count 尾 3B + alloc | |
| +808 | CCountryManpower (内嵌 40B) | **人力块宿主** — 布局见下行; writer 0X140CFE9D0 ratio>0 才写 | §4.3.8 起; **GUI: Reorg confirm 人力门** (sub_14202C760) |
| +809..+847 | — | = CCountryManpower (vtable 0X295EB90) 本体: {vtable@808, tag u32@816 (=cc+8), manpower.current u32@820 (键 11125), **ratio qword@824 (键 694**; GER 250000/ENG 105000/SOV 154500), exile u32@832 (键 15036; >0 才写), max u32@836 (键 15047), 尾 qword@840 (= 库块 sub_140CFA0F0 +32 拷贝, 与 +816/+820/+824/+832/+836 同批从库块拷入; writer 不写)} | |

**CCountryManpower::Withdraw = sub_140CFE7E0** (manpower.cpp; 定案): a3 (use_exile) 真 → 断言 `_ExileManpower >= Amount` (:458, B52/闩 byte_14333CC3F) 后 exile(a1+24) −= amount, 返 0; 假 → current(a1+12) −= min(current, amount), 余量按 controlled_states 两轮摊销 (第一轮每州扣 余量/州数, 整除商>0 才进; 第二轮顺序补扣至余量 ≤0), 逐州经 sub_1413EAE50(state+2104, n) 扣减 (返回实扣量; §4.13 state+2104 人力基准锚, 重算入口 sub_1413EB4D0 / Reset sub_1413EAE90 之外的新第三入口), 返未扣尽余量。
| +848 | CCountryColors (内嵌) | **颜色/外观对象 #1** (vtable+32 finalize; loader 键 **86 (color) / 12728 (color_ui)** 双键解析入 +848 — 11450 实为 mission 键零命中, country.cpp Load 巨 switch 直证; 快照对 +976←+880 / +1008←+912 / +1024←+928; 化妆 tag 解析 sub_1401DB180) | **GUI: 阵营成员行色源** (sub_1406ECF80(cc) = 沿 CDiplomacyStatus(+848 色 obj/+392 宗主 tag) 爬宗主链取色 getter — 返回+32 = cc+880 行色, 返回+16 同 rgba = 阵营默认色种子; 非新字段) |
| +849..+879 | — | = CCountryColors#1 vtable@848 尾 + **间隙 8B@856** + CColor#1 vtable@864 尾 + **CColor +8 间隙@872** (rgba@880 已知) — 两间隙 ctor/dtor/writer/reader 全域不触, 推定 = MSVC 对齐填充 (CColor 16B 对齐使 rgba 落 +880 需 8B 垫) | |
| +880 | 4×float | **color** (16B 色值) | 复制对 +976 |
| +881..+911 | — | = rgba@880 尾 15B + CColor#2 vtable@896 + **+8 间隙@904..911** | |
| +912 | 4×float | **color_ui** (第二 16B 色值) | 复制对 +1008 |
| +913..+927 | — | = rgba_ui@912 尾填充 15B | |
| +928 | uint8 | 颜色旗字节 | 复制 +1024 |
| +929..+943 | — | = flag@928 后尾填充 15B | |
| +944 | CCountryColors 内嵌 #2 | **原始副本宿主** (+944..+1039: vtable@944, rgba@976, rgba_ui@1008, flag@1024) | ctor 定案 |
| +945..+975 | — | = CCountryColors#2 vtable@944 尾 + **间隙 8B@952** + CColor vtable@960 尾 + **+8 间隙@968** (rgba@976 已知) | |
| +976 | 4×float | color **原始副本** (化妆 tag 应用前快照) | 高置信 |
| +977..+1007 | — | = rgba@976 尾 15B + CColor#2 vtable@992 + **+8 间隙@1000** | |
| +1008 | 4×float | color_ui **原始副本** | 高置信 |
| +1009..+1023 | — | = rgba_ui@1008 尾填充 15B | |
| +1024 | uint8 | 颜色旗 **原始副本** | 高置信 |
| +1025..+1063 | — | = flag@1024 后 Colors#2 尾填 15B + **owned_provinces {data@1040, cap@1048, count@1052, alloc@1056}** | |
| +1040 | uint32 向量 24B | **owned_provinces 缓存** {data@1040, cap@1048, count@1052, alloc@1056} — u32 省 id (**不序列化**; neighbors 计算第二源; 探针 GER count=300) | 擦除 0X14070FB90 / 空查 0X1406FCFA0 / getter 0X1406D1DF0 |
| +1064 | 匿名结构 (NNB 形状)* | **controlled_provinces 数据** (u32 省 id 数组) | AddControlledProvince sub_1406D00A0 dup 查 *(prov+164) 后插入 |
| +1076 | uint32 | controlled_provinces 计数 | 同上; **GUI: 世界紧张度战争行 投降进度门** (CWorldTensionWarEntry) |
| +1077..+1087 | — | = controlled_provinces {data@1064, cap@1072, count@1076, alloc@1080..1087} = count 尾 + alloc | |
| +1088 | int64 | **首都控制区 BestVP 省缓存** (-1=无) | 断言 "Country with no province worth any VP in capital controller area" (sub_1406D9350) |
| +1089..+1119 | — | = BestVP@1088 (i64=−1) 尾 + **休眠 24B 向量@1096** {data@1096, cap@1104, count@1108, alloc@1112 哨兵} (与 +704 同家族: ctor sub_14011DF40 / dtor 整体 dealloc / 无写点; 空态: 全量国家 count 恒 0; ⚠ 同号异类碰撞: 他类 +1096 有 RH 表 {mask@1108, extra@1112} 形态 (0x141303160 系), 勿混; 不序列化 — 休眠定案, 业务名不可静态考 (负定案)) | |
| +1120 | CState** | **controlled_states 数据** (vector<CState*>) | SetController sub_1409DDA40 推入/移除 |
| +1132 | uint32 | controlled_states 计数 | 同上 |
| +1133..+1143 | — | = controlled_states {data@1120, cap@1128, count@1132, alloc@1136..1143} = count 尾 + alloc | |
| +1144 | CState** | **owned_states 数据** (vector<CState*>, 本国拥有州表) | SetOwner sub_1409DE560 对新主 sub_1406D1DF0 查重推入并重建 cc+1040 owned_provinces 缓存 + cc+4932 (**contested points** — 双证: AddContestedState 对争议非己有州 `+= 州 VP` (sub_1409D47C0 = CState::GetVictoryPoints); 占领比回落式分母; owned points 在 +4928), 对旧主 sub_14070FB90 移除并擦缓存 (双向配对); all/any_owned_state (GUI 串 TRIGGER_*_OWNED_STATE) 直遍历之; AddContestedState (sub_1406CFF30) 只推 +1168, 其 assert "not contested, use AddContestedOwner" 说的是州侧 contested-owner 属性门槛非容器名 |
| +1156 | uint32 | **owned_states 计数** | 同上; **GUI: 密码候选门** (≤0 排除; sub_141A228B0) **+ 国列表门** (与 capital cc+4120 / cc+5210 并列; 贸易过滤同键); trigger is_capital / owns_any_state_of / transfer_state 系「旧主失尽所有州」门同读此计数; **亦作 global_every_army_leader 收集器国侧门** (>0 才收集; 推定) |
| +1157..+1167 | — | = owned_states {data@1144, cap@1152, count@1156, alloc@1160..1167} | |
| +1168 | CState** | **contested_states_pending 暂存队列数据** (合入 +1144 前的暂存) | AddContestedState 先暂存, points 重算并入 |
| +1180 | uint32 | 上述队列计数 | 高置信 |
| +1181..+1191 | — | = contested_pending {data@1168, cap@1176, count@1180, alloc@1184..1191} | |
| +1192 | CState** | cores 容器数据指针 — vector<CState*> 8B 州指针, 经 gs+712 反查州 id, 保容器序 (禁止排序); 与 §4.1.2 TOPC 条目非同一对象 (TOPC = gs 基) | §4.3.8 起; **GUI: 被占领国 owned states 计数** (cc+1192/{+1204} × state+204==玩家 过滤 → 州数 "x/y"; sub_14155D120) |
| +1204 | uint32 | cores 容器计数 | §4.3.8 起 |
| +1205..+1215 | — | = cores {data@1192, cap@1200, count@1204, alloc@1208..1215} | |
| +1216 | CState** | claims 容器数据指针 — vector<CState*> 与 cores 完全同构; c>0 才写 | §4.3.8 起 |
| +1217..+1227 | — | = claims {data@1216, cap@1224, count@1228, alloc@1232} 的 data 尾 + cap@1224..1227 | |
| +1228 | uint32 | claims 容器计数 | §4.3.8 起 |
| +1229..+1247 | — | = claims count@1228 尾 + **alloc@1232..1239** + strategic_region_data 块头 **{max_load f32@1240=1.0, pad@1244}** | |
| +1248 | 内嵌 | **strategic_region_data 链式迭代表头** (侵入式链表; ctor 全布局: {f32 max_load@1240=1.0, 侵入链头节点@1248 (malloc 0x20 自链), 链尾@1256 见下行, 桶@1264, 水位@1272, 末界@1280 见下行, mask@1288=7, 桶数@1296=8}; +1304 = 控制州大陆去重缓存见下行; +1352 = CControllerArea 注册容器 (前线区, 分组键 = 省+392 controller) / +1376 = COwnerArea 注册容器 (所有者区, 分组键 = 州+200 owner) — 两类完整布局 §4.24.2 / +1400 = 战区分配器记录 (sub_140CF59A0 逐国重算记录·区域互指) / +1424 = 战区分配记录历史档见下行; **+1328 = wargoal 容器** {data@1328, cap@1336, count@1340, alloc@1344} — 元+60 目标 tag / 元+64 类型, 类型 def+816 = annex 旗 (推定); **与 dip+104 available_wargoals 非同一容器** (全量 451 国计数分布: 同值 4 / 仅本侧非空 14 / 仅 dip+104 非空 1)) | writer 块键 0x39C2; 节点键 = CStrategicRegion*, 写 id@region+96; 值对象 {command_power i64@+16, more_ground_crews_enabled u8@+56, modifier 块@+64} |
| +1249..+1263 | — | = **侵入链头哨兵节点@1248** (malloc 0x20, {next@0 自链, 回链指针@节点+8 → &cc+1256}) 尾 + **侵入链尾指针@1256** (ctor 0; dtor sub_1406CB960 经哨兵回链清零; writer 沿 next 迭代至回卷) | 定案 |
| +1264 | 匿名结构 (NNB 形状)* | strategic_region_data **RH 桶数组** (16B 桶) | FNV(region)&mask 取桶 |
| +1265..+1287 | — | = RH 桶数组@1264 尾 + **桶缓冲水位@1272** (推定: dtor 与末界同清) + **桶缓冲末界@1280** (dtor 空间量算式 `(*(cc+1280) − 桶起) & ~7` ≥ 0x1000 大页判式直证) | +1280 定案; +1272 推定 |
| +1288 | u64 | strategic_region_data **hash mask** | 定案 |
| +1289..+1447 | — | = RH hash mask@1288 (=7) 尾 + 桶数 u32@1296 (=8) + **24B 容器×6** {data@1304/cap@1312/c@1316/alloc@1320} / {@1328/1336/1340/1344} / {@1352/1360/1364/1368} / {@1376/1384/1388/1392} / {@1400/1408/1412/1416} / {@1424/1432/1436/1440} — strategic_region_data 块区 (writer 块键 14786 仅发 4 键 12014/14467/14787/10597 且仅遍历侵入链 ⇒ 本区 runtime-only 定案; +1352/+1376 = 双类注册容器 (§4.24.2); +1400 战区分配工作集 (每轮重算 sub_140CF59A0 先经 sub_140CF36A0 复位记录区域预留, append 入 +1424 后清 +1412); +1424 = 战区分配记录历史档 (append-only, 元素同 +1400 记录指针 — 定案); 六槽各有名 (+1304/+1328/+1352/+1376/+1400/+1424)) | |
| +1304 | CContinent** | **控制州大陆去重缓存** {data@1304, cap@1312, count@1316, alloc@1320} — 重建 = sub_1406D9040 (日更 0x1406FE1E0 调, gs 级 TBB 包装 0x1401A5630 逐国): 遍历 controlled_states (+1120/+1132) → st+48 stateDef+320 = CContinent* → 大陆旗 u8@+40 门 → 线性查重 1.5× 推入 (8B 指针元); 与 GUI 大陆过滤读链同源 | 不序列化 (定案) |
| +1424 | 指针 (元素) 向量 24B | **未名 8B 指针元向量** — dtor 收尾 sub_1401A7E50 (memcpy 8*count 整体搬移 = 元素平凡); cc 侧无写点 | 形态定案; 语义待裁 |
| +1448 | CModifier 内嵌 192B | **country_modifiers 块** (+1448..+1639; ctor a1[181]=&CModifier::vftable, 查表 ctor sub_140555FB0@1464; 全布局见 §4.3.8 通用表) | loader case 11577; **GUI: 共享槽基数输入** (sub_1409D4980: CState+2136 + owner 国(+1448)×类别 → shared_slot_count); **生产/密码修正族查表** (cc+1464 键: mdef 0xA9-0xD6 生产族/528-529 密码族/201-203 舰载族 — 各册消费链) |
| +1464 | 匿名结构 (16B 键值对) RH 桶数组 | country_modifiers token→i64 值查找表 (形态同 CState +1352/+1368); = cc+1448 CModifier 的 mod+16 pairs vector 本体 (同一对象, 容器描述符 {d@+0, count@+12} 视角) | 修正查表总入口 (sub_14055E360); **"daily PP" 实为指挥力**: modifier id 330-333 + define BASE_COMMAND_POWER_GAIN/BASE_MAX_COMMAND_POWER → 写 cc+496 (上限扣 cc+504 分配池) |
| +1640 | CRule 内嵌 1016B | **第二规则覆盖对象** (RTTI 真名 = CRule, 书旧名 CRuleOverrides 已并; 全域机制 §4.3.7a) (+1640..+2655; 与 +2656 external_rules 同型同窗 ctor sub_140638A10, 1640+1016=2656 严丝合缝; 消费者 sub_140705AD0 全链: 清空 → 执政党 (+3984 → +208 → +24 → +96/+144 两处 sub_140638DB0) → 阵营 (dip+656 CFaction → sub_140D8A2A0) → 自治 (dip+848 → +40 → +528) → 理念表 (cc+3984+80, count@+92, 逐 `*(idea+1216)`) 四源聚合; 复位 sub_1406E2DE0 与 +2656 并列清空; **writer/loader 不序列化**) | 不序列化 (定案: **规则覆盖合成缓存** — 上述四源聚合的运行时合成版, 与 +2656 存档装载的外部规则成对非重复) |
| +2656 | CRule (内嵌) | external_rules 宿主: 28 规则槽 i∈[0,28), 写门 = u8@cc+2656+92+i ≠ 0 (门开才写, yes/no 皆落盘), 值 = u8@cc+2656+64+i, 键名 = token_name(u32@defs+56*i+40), defs = *(BASE+53575920) (⚠ defs 基址待裁: 规则定义表全局直读 = qword_1433304C0, 与该址 0x1433180F0 差 0x183D0, 疑旧算/旧版残留); **override = 28×32B MSVC 串槽 @cc+2656+120+32k** (SSO cap=15), size u64@cc+2656+136+32k≠0 才写, 键 = 槽序号裸数字 (writer sub_14063C490 AD7A0 裸串), 值 = 裸规则名 | §4.3.8 起 |
| +2657..+3671 | — | = external_rules CRule 1016B 本体细分 (+2657..+2719 对象头 {串@+8 尾/容器@+40/u8@60}, **值槽 u8×28@+2720..+2747, 门槽 u8×28@+2748..+2775, override 串槽 28×32B@+2776..+3671**) | |
| +3672 | CDynamicModifierContainer (内嵌) | 动态修正 字段 1 (块键 15361 `dynamic_modifier`, 门 = 容器非空 sub_14060D020) | §4.3.8 起; 条目数组 {data@cc+3672+40, count@+52}, 元素 64B SDynamicModifierEntry |
| +3673..+3711 | — | = CDynamicModifierContainer 本体尾 | |
| +3712 | SDynamicModifierEntry* | 动态修正 字段 2 | §4.3.8 起; vtable 探针+RTTI |
| +3713..+3831 | — | = CDynamicModifierContainer (vtable 0X27D62B8, 72B, ctor sub_140556350) 尾: 条目 data@3712 尾 + **cap@3720** + count@3724 + alloc@3728 + u8@3736 + 填充 + **CModifier#2 内嵌 192B 头** (vtable@3744 CModifier::vftable, 查表@3760 sub_140555FB0; 不序列化; 初始化分工 = CDynamicModifierContainer ctor 不触 +72, CModifier#2 由 CCountry ctor 直填) | **= 动态修正聚合值表 (定案)**: calc_modifier 后段经 sub_140557840(cc+1464 ← CModifier#2, 缩放) 并入国家聚合 |
| +3832 | 匿名结构 (NNB 形状)* | **CModifier#2 的 name 槽 (mod+88)** — SelectFocus 时 SSO 串拷贝 (focus palette 名); 位置 = 3744 (CModifier#2 基址) + 88 | 断言 `!pFocus \|\| *(cc+4984) == pFocus->GetPalette` (sub_140711430) — **palette 断言真值在 cc+4984**, 非 +3832 |
| +3833..+3935 | — | = _pFocusPalette@3832 尾 + **CModifier#2 后 96B** (3840..3935, 按 §4.3.8 通用表) | |
| +3936 | CTechnologyStatus* | 科技状态 | §4.7 |
| +3944 | CProductionStatus* | 生产状态 | §4.8; **GUI: 多消费者** — 生产面板直读 (无存储 target) / 师设计装备原型池 (D+264×) / Reorg 可部署池 (+512 库存 × CAirBase+136) / B15 工厂占用条 (详 §4.8 消费链) |
| +3952 | CDeployment* | 部署 | §4.18; **GUI: 装备可用性校验表** (D+180 16B 条 × cc+3952; def+1448 并入) |
| +3960 | CReinforcementStatus* | reinforcement_priority (u32@obj+8; **写门 ≠1**, 1=默认值不落盘) | §4.10; vtable 0X29D1E48 (探针+RTTI); **GUI: 增援优先级行** (CArmyReinforcementItem GetPriority = 本对象+8, 回退 1 与写门互证; 命令 = CSetCountryReinforcementPriorityCommand {+40 tag / +44 priority}) |
| +3968 | CArmyUpgradesStatus* | 陆军升级状态 (剧场) | §4.3.8 起; vtable 0X29D1FF8 (探针+RTTI); **GUI: 升级优先级行** (CArmyUpgradeItem GetPriority = 本对象+8 — 升级链 = 装备升级优先级状态机; 命令 = CSetCountryUpgradePriorityCommand {+40 tag / +44 priority}) |
| +3976 | CDiplomacyStatus* | 外交 (capitulated b@+736 / cap_date hours@+752 / last_surrender hours@+696 / hosting tid@+424 / legitimacy ×1e-5@+432 / gov_in_exile_we_host {d@+400, c@+412}, writer 0X140D47400) | §4.10 |
| +3984 | CPolitics* | 政治 | §4.10 |
| +3992 | CLogisticsStatus* | **CLogisticsStatus** (logistics 19 槽队列; writer 0X141375A30, 仅人类控制国落盘) | §4.3.11; **GUI: 后勤账本行数值** (sub_141D9BFE0 → sub_141371450; 详 §4.3.11 B15 注) ; 复位件 = sub_141371330 (CCountry 复位链; 邻件 AddTriggerDynamicVariable RTTI 系 sub_14071ACF0 非本件) |
| +4000 | CDecisionStatus* (vtable 0x1427EB5C0, sizeof 456; writer 0x140738AA0 / reader 0x140733A20) | **decision_status** | writer ADEC0 0x3804; 内部: 容器 {data@obj+160, count@obj+172}, 条目 **+28 = u32 state 枚举** (0 active/1 completed/2 failed/3 aborted/4 re_enable_cooldown, 见 §4.8.12) |
| +4008 | 匿名结构* | **program_status** (写 obj+8 基) | writer ADEC0 0x4010; project_pool 448B 元素 {id@+12, type@+8, name_token@+24}; **同名 project 可重复** (黄粱 sp_naval_ice_carrier 每国两条不同 id) → 发射按名 seqc 编号 (首现裸名 / 重复 [N], 同 save 侧提取器) |
| +4009..+4015 | — | = program_status 指针尾 | |
| +4016 | CCustomizableBuildingCollection* | **naval_headquarter_status** (0x58B, 双 vtable; Reset 规则#52 开时按数据库重填) | writer 块键 0x49A0=18848; loader case 0x49A0 → ABB40(a2, *(cc+4016)); 定案 |
| +4024 | 匿名结构 (0x138B)* | **equipment_market** (指针非内嵌; ctor sub_1413B6EB0(cc, production, logistics, incoming_diplo, diplo)) | loader case 15103; daily 更新; **GUI: 市场清空按钮目标** (CMarketStockpileClearCommand 10191 → \*(cc+4024) → sub_1419D6F20) |
| +4025..+4031 | — | = equipment_market 指针尾 | |
| +4032 | 匿名结构* | **intelligence_agency** 机构对象 (+288 = CCryptology\* 密码学部门态, ctor sub_1413F61D0 — UI 密码学视图数据源) | writer ADEC0 0x3D32; **GUI: 机构面板目标** (AgencyView @48[9] 0X140F2F3A0 现取; 省点击转发 → CCryptologyView+48) |
| +4032→agency | COperativeLeader* | gfx = MSVC std::string **@e+256** (writer 链定案; e+192 恒 nil, 实机 4/4 对照); mission.state 仅 build_intel_network(1)/root_out_resistance(4) 写, counter_intelligence(3) 只有 target; **类型枚举 0..8 全表 = no_mission(0)/build_intel_network(1)/quiet_network(2)/counter_intelligence(3)/root_out_resistance(4)/boost_ideology(5)/control_trade(6)/diplomatic_pressure(7)/propaganda(8)** (双证: 发射器 sub_140FC6240 enum→token 全表直证 + scorerdatabase 注册件 sub_140AA36F0 下标 0..8 名表直证) | 导出键 `intelligence_agency.operative[N].gfx` / `.mission.<type>.state` |
| +4033..+4039 | — | = intelligence_agency@4032 指针尾 7B (ctor a1[504]=0) | |
| +4040 | CLoopHistory* | **CLoopHistory** (0x38B, ctor sub_141516640(5,0)+sub_141516990(·,1); country.history 三队列族; writer L863 ADEC0(0x2835)) | §4.3.11 |
| +4048 | CCountryOccupationStatus* | **CCountryOccupationStatus** (0x128 字节, 双vtable vtable1 0x142984978 @occ+0 / vtable2 0x1429849b0 @occ+24, RTTI 定名); 序列化 writer 0X141000120 = vtable2 槽[2] — ⚠ a1 = occ+24 基差 24 (division_template_id reader+120 ↔ writer+96 同证) | §4.3.8 起; **GUI: 占领面板数据源**; 布局/日志条目详 §4.3.2 |
| +4056 | CCountryCollaborationStatus* (vtable 0x1429BCC68; 条目 24B = **CCountryCollaborationData**, vtable 0x1429BCC18, 槽[2] writer 0x1413F5C70 / [4] reader 0x1413F53A0) | **collaboration (0x4BB0)**: {data@+40, count@+52} 8B 指针数组, 条目 CCountryCollaborationData 24B {vtable@0, tag tid u32@+8, value i64×1e-5@+16} (ctor 0X1413F46E0 malloc 0x18; body writer 0X1413F5C70 AE590(776,+16)); 外层块嵌套同名两层 (国家 writer sub_1407191B0 ADEC0(0x4BB0, cc+4056); body 0X1413F5C90; reader 0X1413F53C0), 内层键 = occupier tag — ⚠ 挂载 cc+4056, 非 +4048 occupation ; **+72 CPdxArray<tag u32> = 反向协作标签集** ("谁正和我协作": {data@+72, cap@+80, count@+84, alloc@+88}; 唯一插入 0x1413F49A0 (归属链 sub_1413F46E0 → GetCollaborationStatus(country_of(tag)) 直证反向语义) / 前移压缩删除 0x1413F57C0; tag 比较经 **sub_140BB52F0 = tag 等价谓词** — 读 gs+104 国家间接表 `table[*a1] == table[a2]`, gamestate.h:1125 (:1126 双断言 = CGameState 单例 + TLS 线程禁入); 另 +16 RH 表 {count@+24, mask@+28, extra@+32} 24B 条目 / +40 有序指针数组 (二分插入 sub_1401B14F0, 键 = sub_140BB5490(tag) 国家索引) / +64 持有者标签来源指针 (+8 = tag u32)) | §4.3.8 起; **GUI: 战争盟友行 collaboration 图标** (CWarAllyItem: count@+52 消费) |
| +4064 | 匿名结构* | **country_reports** | §4.11.14; writer ADEC0 0x4BC3 |
| +4072 | 匿名结构* | **intel** | §4.11; writer ADEC0 0x30EC; loader case 12524 同 |
| +4080 | CCountryCharacters* | **characters 宿主 (0x138 堆对象, ctor malloc 双调用点直证; vtable 0X14298AE18, 活体探针 + ASLR 换算 + RTTI 名三证; ctor sub_1410E8A20 / dtor sub_1410E8C70); writer 块键 0x4C14; 断言 "Unit leader without a character" 互证; 8 张指针表; ⚠ sub_1411867E0 = 任命资格校验器 (技能门槛+理由串), 与本对象无代码关系 | §4.4; 内部表见下; **GUI: 阵营指挥官窗候选列表** (Repopulate sub_141BFA2A0; EFilterFactionCommanders 掩码 15 @win+4504) |
| chars+8 | CCountry* | 属主回指 (chars+8 == cc == chars+256 三点互证, 活体 440 国) | 序列化仅 5 键 (19622/19968/19485/15702/17327, token 全直证); 全部容器 = 24B {data, cap u32, count u32, allocator vptr off_143085170} — 原「+128..+159/+216/+304 独立槽」系各容器第 4 格误拆 |
| chars+16 | 容器 24B | **character_status** (16B 元 {**CCharacter\*** @+0, flags u32@+8}: bit0 country_leader / bit8 advisor / bit16 unit_leader / bit24 scientist) | 键 19622 (s4_03 原锚 ✓) |
| chars+40 | 容器 24B | **retired_character_status** (元素同构) | 键 19968 |
| chars+64 | 容器 24B | **已创建 CAdvisor 登记表** (8B 指针元) | 不序列化 |
| chars+88 | 容器 24B | **appointed_advisors** {d@88, count@100}; **advisor slot 主键 = idea_token @advisor+48 (hash 缓存 @+80** — 排序树键); character id 对 = 打包 qword | 键 19485 (原「推定 advisor 角色名映射」定案) |
| chars+112 | CUnitLeader* 24B 容器 | **pArmyLeader** (cpp:220 断言直证; 原「候选表#1」名废) | 不序列化 |
| chars+136 | CUnitLeader* 24B 容器 | **pNavyLeader** (cpp:226 断言直证; 原「候选表#2」名废) | 不序列化 |
| chars+160 | 容器 24B | **在聘科学家花名册** (CScientistList roster 模式数据源) | 不序列化 |
| chars+184 | std::map | **槽位注册树** (键 = theorist/high_command 等槽名串; 节点 0x58B; +80 职位总数 / +84 空余数, 活体直证) | 不序列化 |
| chars+200 | 容器 24B | **retired_operative_leader** (retired 特工池; 元 COperativeLeader* 0x10A8) | 键 15702 |
| chars+224 | 容器 24B | **recruit_scientist 招募池** (空池每小时 sub_1414EC630 补生成) | 键 17327 |
| chars+248 | — | = +224 容器 alloc 槽 (共占) | 定案 |
| chars+256 | CCountry* | **属主 CCountry* 第二回指** | 定案 |
| chars+264 | 容器 24B | **待解任顾问队列** (CAdvisorUnsafeRef) | 不序列化 |
| chars+288 | 容器 24B | **待清理领袖队列** (按 leader_type 0,1/2/3 分派) | 不序列化 |

| +4088 | 内嵌 | **incoming_diplomatic_action**; writer ADEC0 0x3D0E | §4.10 |
| +4089..+4095 | — | = incoming_diplomatic_action@4088 指针尾 7B | |
| +4096 | SInvasionReport* 数组 (vtable 0x1429D2950; writer 0x1415165C0 / reader 0x141516410) | invasion_report 容器数据指针 {cap@4104, count@4108, alloc@4112 哨兵} — (指针数组) | 元素: tag tid@+8 / enemy tid@+12 / province=*(e+16)+164 / date hours@+40 (CGregorianDate 24B @+32); +24 = *(province+200) 装载快照 (高置信) |
| +4108 | uint32 | invasion_report 容器计数 | |
| +4109..+4119 | — | = invasion_report 容器尾 {alloc@4112} | |
| +4120 | uint32 | capital | §4.3.8 起; **GUI: 国列表门** (sub_1406EC810 = gs 表[cc+4120]; capital=0 国行跳过) |
| +4124 | uint32 | original_capital (GER=64 对拍定案) | §4.3.8 起 |
| +4125..+4127 | — | = original_capital@4124 尾 3B (capital@4120 同槽 qword 清零) | |
| +4128 | uint32 | **graphical_culture token** (lexer 索引) | loader case 10475 |
| +4136 | MSVC 串 | graphical_culture 原文串 | 同上 |
| +4137..+4167 | — | = graphical_culture 串@4136 本体: buf 15B + **size@4152** + **cap@4160=15** (标准 MSVC 32B 串) | |
| +4168 | uint32 | **graphical_culture_2d token** | loader case 13951 |
| +4176 | MSVC 串 | graphical_culture_2d 原文串 | 同上 |
| +4177..+4207 | — | = 串尾 + neighbors 前置 | |
| +4208 | uint8* | **neighbors 位图#1** {data@4208, cap u32@4216, n@4220} (位图 ensure 结构 {data, cap, n, alloc}: 1.5× 增长 + memset 补 0, sub_1402C1560 — 定案) — 字节/国 (探针 GER n=333=tag 槽数); 重算 = sub_14070AF30 遍历 **controlled_provinces(+1064)** → 省静态描述符(+184) 邻接表(+112, 48B 元, id@+8) → 邻省 **controller(+392)** ≠ 己者去重入位图1/列表1; 控区变更后刷新 (0X1406EAB50/0X1406FF1F0/0X140E801A0) | 不序列化 (高置信) |
| +4232 | uint32 向量 24B | **neighbors 列表#1** {data@4232, cap@4240, count@4244, alloc@4248} — u32 tag (断言 "Asking if X is a neighbor of Y…" country.h; **探针 GER count=11** = 德 1939 邻国信度锁死) | 不序列化 |
| +4256 | uint8* | **neighbors 位图#2** {data@4256, cap u32@4264, n@4268} (同位图 ensure 结构) (探针 333; 语义 = 拥有口径); 重算 = sub_14070AF30 遍历 **+1040 (owned)** → 邻省 **owner(+192→+200)** ≠ 己者入位图2/列表2 | 不序列化 |
| +4280 | 匿名结构 (NNB 形状) 向量 24B | **neighbors 列表#2** {data@4280, cap@4288, count@4292, alloc@4296} (探针 GER=11) | 不序列化 |
| +4304 | fixed×1e-5 | stability | §4.3.8 起 |
| +4312 | fixed×1e-5 | war_support | §4.3.8 起 |
| +4313..+4319 | — | = war_support@4312 (**i64×1e-5 8B**) 尾 — stability@4304 同型 (ctor 初值全局) | |
| +4320 | uint32 | **refresh** | writer ADFE0 0x3495 (定案) |
| +4324 | uint32 | **original_research_slots** | writer 键 0x361D, >0 才写 |
| +4325..+4343 | — | = original_research_slots@4324 尾 3B + **CPlayerAiPrefs 16B@4328 (vtable 0X27E72C0)**: {vtable@4328, 4B 偏好@4336 = 0x01000001, i32@4340 = −1}; 同类见 CSetPlayerAiPrefsCommand (命令对象 +48 同布局拷贝) — 「玩家手动接管 AI 偏好」 | |
| +4344 | CRadarsPool 内嵌 (双 vtable @+4344/+4352) | radar 键 12237 走 +4352 facet; 成员: 容器群 @+16/+40/+96/+120/+144/+168, 子对象@+72 = **RADAR 静源引用 (池槽 3)**, +64 = owner tag, RH 桶×2 @+200/+232 (dtor 0X1410A31F0 双 vtable; 内嵌定案); 运行期消费点语义 = §4.11.19 | Reset 清理 |
| +4345..+4351 | — | = CRadarsPool vtable@4344 尾 7B | |
| +4352 | 内嵌块 | **radar** | writer ADEC0 0x2FCD; loader case 12237 同 |
| +4353..+4415 | — | = **CRadarsPool 256B 全布局** 后半: 容器群 @+16/+40/+96/+120/+144/+168, tag u32@+4408, CStaticIntelSourceReference@+4416, RH×2@+4544/+4576 (内偏移 = CRadarsPool 相对) | |
| +4416 | CStaticIntelSourceReference | 情报源引用 (CRadarsPool 内; 情报源/省附加区) | |
| +4417..+4599 | — | = CRadarsPool 后半 (tag@+4408 / CStaticIntelSourceReference@+4416 / RH×2@+4544/+4576) | |
| +4600 | 匿名结构* | **资源/租借系统 rs** (vtable 0X295C4B0, writer sub_140CBE2D0); 内含每州资源因子缓存 — sub_140CAE3F0(*(cc+4600), state) 按州查条目 → infra factor sub_140CAD400 / supply factor sub_140CB48C0 (RESOURCE_INFRA/SUPPLY_FACTOR_TOOLTIP; 缺省各 1.0); CResourceOrigin 元素 spotter = 内联 id 对 {type@el+112, id@el+116} 任≠0 才写 (探针 PRU id=803 type=61); 元素内资源向量 {resources@136 / resources_unclapmed@312 / buildings@664} 落盘门两级 (同 CStrategicResourcePool 族): 块级 = 至少一个正值条目才整块写, 条目级 = 块写后 ≠0 全发含负值 (EoaNB origin[3].resources_unclapmed 仅 fabric=-1 → 整块无叶实证) | §4.3.8 起; GUI 消费表见 §4.3.3 |
| +4601..+4607 | — | = 资源/租借 rs@4600 指针尾 7B | |
| +4608 | CConvoys (内嵌 136B) | **convoys** — writer ADEC0 0x3062; **第二容器 {data@cc+4688, cap@4696, count@4700, alloc@4704}** — 8B 堆对象指针元, runtime-only (dtor 拆除); 消费 = sync manager "Convoys" desync dump (sub_140DAB4C0); sub_1402BC8A0 可用护航 = 缓存总量 (+4728/+4736, /1e5) − +4716 占用 — 护航分配明细, 业务名推定; 活体形态进展: 元素本体 ≥24B 无 vtable 结构 {u32@0, u32@4, u32@8 (与 +4 同值), u32/char4@12, 8B 堆指针@+16} (本档 103 国非空, 单国 ≤6 条) | §4.3.16 |
| +4609..+4743 | — | = **CConvoys 136B (vtable 0X27E7130, ctor sub_1410203E0)**: {vtable@4608, tag u32@4616, **CEquipmentVariantPool 64B 内嵌@4624** (容器A 24B 元 + 容器B + u8), 容器@4688 {data@4688, cap@4696, c@4700, alloc@4704}, qword@4712 (⚠ 实为 dword = **Σrequested 申请占用累计**, RequestConvoys 与 bucket+8 双写; qword 类型标记载待 PE 复核), qword@4720 = **_pConvoyVariant** (懒解析指针; country+3944 容器 {data@+160, count@+172} 取首个 variant+1032 bit0 置位者, convoys.cpp:543 断言), u8@4728 = **池缓存有效旗** (AddConvoys 正数入池后清 0 → sub_1410215C0 重算), qword@4736} — 租借护航计算域; 字段名对齐 §4.16.7b (cc+4716 = Σallocated 为另一字段, 勿混) | |
| +4744 | uint32 | convoys 派生计算值 (sub_1402BC8A0(cc+4608); 0X140705630 消费) | 推定 |
| +4749 | uint8 | dirty_controlled_states | §4.3.8 起 |
| +4750 | uint8 | **tick 分片槽 = hash(tag) % dword_143336F50** (ctor 写入; 消费 0X1406E8210: `hour % N == +4750` 才跑 delayed_event 同步 (写 +4776 伴随表) — 错峰调度; 探针 GER=2) | 不序列化 |
| +4752 | 匿名结构 (0xC8 形状)* | delayed_event 容器数据指针 — 元素 0xC8: 事件对象指针@+8, 名 SSO@+32, originator tid@+192, 延迟总小时@+196 | §4.3.8 起 |
| +4753..+4763 | — | = delayed_event 容器尾 {cap@+4760} | |
| +4764 | uint32 | delayed_event 容器计数 | §4.3.8 起 |
| +4765..+4823 | — | = delayed_event 容器尾 {alloc@+4768} + 伴随表/串表本体 | |
| +4776 | CEvent** | **delayed_event 伴随事件指针表** {data, cap@4784, count@4788, alloc@4792} — 8B CEvent* 元 (按事件对象同步删除) | dtor + 消费者 0X1406EA3A0 |
| +4800 | MSVC 串 向量 24B | **关联名称串表** {data, cap@4808, count@4812, alloc@4816} — 32B MSVC 串元 (对象改名时删旧推新) | dtor + pusher 增长码 |
| +4824 | CAce* | ace 容器数据 {cap@4832, alloc@4840} (serialize 0X14061BD30; 计数无 ≤64 上限, 探针 GER 80+ 王牌) | §4.3.8 起; reader Country.aces; **类名定案 = CAce** (ctor 直写 vtable 符号, 「CAirAce」无符号; sizeof 376B 双 malloc); 元素全表见 §4.3.12 合并版 (+1384 行废 — 376B 无此域, 熟悉机型 = +24 掩码) |
| +4825..+4835 | — | = ace 容器尾 | |
| +4836 | uint32 | ace 族容器计数 | §4.3.8 起 |
| +4837..+4847 | — | = ace 容器 {data@4824, cap@4832, count@4836, alloc@4840..4847} = count 尾 + alloc | |
| +4848 | uint32 向量 24B | **civil_war_target tag 容器** {data@4848, cap@4856, count@4860, alloc@4864} (writer 逐元键 0x314B=12619 写 tag 名; 探针 GER count=0) | 定案 |
| +4872 | uint32 | **civil_war_initiator** (writer 键 0x3802=14338, >0 才写 tag 名) | 定案 |
| +4876 | uint32 | **m_OriginalTag** (original_tag tid; 三证: "original tag: " 调试串 + `_CountriesForOriginalTags` assert (国管理器 **+2440** = 24B vector/identity 桶) + 名回退; **gs+832 = 每国 original-tag 恒等表 u32 数组**, sub_140BB5490(tag)=identity[tag], **sub_140BB52F0(A,B) = 「同原初国」谓词** (内战分离 tag/换 tag 继承=同国, 宗主-傀儡=不同国; 全引擎 3146 处调用); COriginalTagTrigger/CAnyCountryWithOriginalTagOfTrigger RTTI 实名; >0 时名称缓存优先用它) | §4.3.8 起 |
| +4880 | CNuke* | nukes 容器数据 {cap@4888, alloc@4896}; 元素 72B **CNuke** (vtable 0X27E7270): +8 自存 token / +32 nuclear_strikes 容器 / +24 amount / +60 nukes_ready — 全表见 §4.3.8; **ctor 预填 2 条默认 CNuke** (do/while v5<2 推入, 1.5x 增长) | §4.3.8 起 |
| +4881..+4891 | — | = nukes 容器 {data@4880, cap@4888, count@4892, alloc@4896} = data 尾 + cap | |
| +4892 | uint32 | nukes 容器计数 | §4.3.8 起 |
| +4893..+4903 | — | = nukes count@4892 尾 + alloc@4896..4903 | |
| +4904 | uint32 | 战斗计数字段族 (num_armies_in_combat, 详见 §4.3.8 起 标量行) | §4.3.8 起 |
| +4908 | uint32 | **num_ships_in_combat**; writer 键 0x35BE | §4.3.8 起 |
| +4912 | uint32 | num_ships | §4.3.8 起 |
| +4916 | uint32 | convoys_destroyed | §4.3.8 起 |
| +4917..+4935 | — | = convoys_destroyed@4916 尾 + **占领度量 4×u32@4920/4924/4928/4932** (控制省-core己 / 控制省-claim己 / owned points / contested points; 重算 sub_14070BDB0, 消费 sub_1406DA100 占领比率; 不序列化) | |
| +4936 | uint32 | research_slot **动态可用科研槽数** (初值 = dword_14333701C 全局, 运行时 defines 填; ideas/国策加成后的现值——⚠ 非 ts+172 槽容量, 两者独立: BICE 实测容量恒 6 而动态 0~6, 动态=0 国无可用槽) | §4.3.8 起 / §4.7 |
| +4937..+4943 | — | = research_slot@4936 (u32) 尾 3B + 无引用填充槽@4940 (ctor 未触; 全域零命中, 定案) | |
| +4944 | CBuildingStatus* | **buildings 国家侧建筑宿主** (writer 键 12121 "buildings" 恒写块; loader case 12121 → vtable+24 parse; 0x78B, ctor sub_141171AD0(2, 0, cc+8): {vtable, alloc 哨兵@24, 容器@32/56/80, u32@104=2, u32@108=0, u32@112=tag}) | 定案 (gs+1000 注互证, §4.1) |
| +4952 | uint32 向量 24B | **建筑类累计表** {data@4952, cap@4960, count@4964, alloc@4968} — 8B 内联对 {token u32@+0, value i32@+4} (按 token 累加差值) | dtor + 消费者 0X1407042D0 |
| +4953..+4975 | — | = 建筑类累计表 {data@4952, cap@4960, count@4964, alloc@4968..4975} 内部 | |
| +4976 | CNationalFocusTree* | focus_tree (名 MSVC@+8) | §4.3.8 起; vtable 0X2739BB8 (探针+RTTI) |
| +4984 | 匿名结构 (NNB 形状)* | **continuous_focus_palette** (loader case 14045: 数据库解析 sub_1406C22A0, fallback sub_1402D2580; 存后 focus_status 刷新) | §4.3.8 起 (定案) |
| +4992 | CFocusStatus* | focus 对象 (CFocusStatus 宿主, §4.3.12) | §4.3.8 起 |
| +4993..+4999 | — | = focus_status@4992 指针尾 7B | |
| +5000 | 内嵌块 | **focus_cost_reduction = CReducedFocusCost** (全布局 §4.3.15b) | writer 键 0x27F1 |
| +5024 | uint32 | focus_cost_reduction 块计数 (写门) | 定案 |
| +5025..+5039 | — | = CReducedFocusCost 本体尾 (§4.3.15b) | |
| +5040 | CVolunteerForceTransfer* 向量 | **volunteers_transfer 指针数组数据** {cap@+5048, alloc@+5056} (8B 元; 元素 160B, ctor sub_1415201A0 RTTI 直读; loader case 13309/13419 对位); writer 循环 ADEC0 0x346B | §4.10.19 |
| +5052 | uint32 | volunteers_transfer 计数 | 定案 |
| +5053..+5063 | — | = volunteers_transfer 容器尾: count@5052 高 3B + **alloc@5056 哨兵** | ctor a1[630..632] |
| +5064 | 匿名结构 (8B 形状) 向量 | **exile_divisions_transfer 指针数组数据** {cap@+5072, alloc@+5080} (8B 元, 元素多态 vtable); writer 循环 ADEC0 0x3AC1 | §4.10.19 |
| +5076 | uint32 | exile_divisions_transfer 计数 | 定案 |
| +5077..+5111 | — | = exile 容器尾 (count@5076 高 3B + alloc 哨兵@5080) + **civil_war 动态 tag 会话注入表 {d@5088, cap@5096, c@5100, alloc@5104}** — 16B 元 {key 对象指针, u32 tag}; 查值 0X1406F8340 先查本表再落 +5112 持久层 (civilwar.cpp:662 建国路径); 运行时-only 不序列化 | ctor sub_14011DF40(a1+636) |
| +5112 | 匿名结构 (16B 形状) 向量 | **dynamic_revolution_tag 容器数据** (16B 条 {obj 指针@0, tag u32@+8}; ideology token@obj+20) | writer 块键 0x3564; loader 增长码四元组 |
| +5120 | uint32 | dynamic_revolution_tag cap (1.5x 增长) | 定案 |
| +5124 | uint32 | dynamic_revolution_tag count | 定案 |
| +5128 | 指针 (allocator) | dynamic_revolution_tag allocator | 定案 |
| +5129..+5135 | — | = dynamic_revolution_tag 容器尾: alloc@5128 高 7B 哨兵 | |
| +5136 | tag_id* | given_air_volunteer_permission 容器数据指针 {cap@+5144, alloc@+5152} — (tag 数组) | §4.3.8 起 |
| +5137..+5147 | — | = given_air_volunteer_permission 容器尾: data@5136 高 7B + **cap@5144** | |
| +5148 | uint32 | given_air_volunteer_permission 容器计数 | §4.3.8 起 |
| +5149..+5159 | — | = 同容器尾: count@5148 高 3B + **alloc@5152 哨兵** | |
| +5160 | tag_id* | received_air_volunteer_permission tag 数组数据 {cap@+5168, alloc@+5176} | §4.3.8 起 |
| +5161..+5171 | — | = received_air_volunteer_permission 容器尾: data@5160 高 7B + **cap@5168** | |
| +5172 | uint32 | received_air_volunteer_permission tag 数组计数 | §4.3.8 起 |
| +5173..+5183 | — | = 同容器尾: count@5172 高 3B + **alloc@5176 哨兵** | |
| +5184 | uint32* | received_air_volunteer_permission count 并行数组数据 (导出形 "TAG=cnt" 串) | §4.3.8 起 |
| +5185..+5195 | — | = received_counts 并行数组容器尾: data@5184 高 7B + **cap@5192** | |
| +5196 | uint32 | received_air_volunteer_permission **counts 数组计数** | writer 断言 Tags.GetSize==Counts.GetSize (country.cpp:0x3F0) |
| +5197..+5207 | — | = 同容器尾: count@5196 高 3B + **alloc@5200 哨兵** (紧贴 +5208 旗 dword) | |
| +5208 | uint8 | **和平会议挂起旗 (surrender 抑制)** — surrender sub_1406E16C0 首行 `if (!*(cc+5208))` 才进投降逻辑; **置 1 = 和会创建时对所有 winner+loser tag** (peaceconference.cpp), 清 0 = 和会侧 + 国家重置 | 高置信 (探针 GER=0) |
| +5209 | uint8 | **is_major** (仅真写; 与 +5210 major 并存双键; writer 键 0x34BE; **两键分立实证: 全量国家分布 = (0,1) 5 国 + (0,0) 446 国, 无 (1,1)**, 本档 +5209 恒 0) | §4.3.8 起 |
| +5210 | uint8 | major (仅真写; 与 +5209 is_major 分立; writer 键 0x2BE9; **本档 = 5 国置位/446 国零**) | §4.3.8 起; **GUI: 国列表门之一** (与 cc+1156 / capital cc+4120 并列四门) |
| +5211 | uint8 | is_top_ic_country (仅真写) | §4.3.8 起 |
| +5212 | uint8 | **日更门** — slot[8] 桩 sub_1406FE1D0 首行 `if (!*(cc+5212)) return sub_1406FE1E0();` (非零才进日更大体: 读 +1120 异常表 / 刷 +3832 串 / 遍历 +5560 容器 count@+5572) | §4.00.1 槽表 |
| +5213 | uint8 | reserved_dynamic_country | §4.3.8 起 |
| +5214 | uint8 | use_legacy_ai_pp_spend | §4.3.8 起 |
| +5215..+5223 | — | = +5215 对齐垫 + **+5216 = **start_equipment_factor** (i64 fixed×1e-5; reader case 13195 → sub_1424C0A70 → sub_1424C53E0 定点解析; **writer 无对应键** ⇒ 只读档不写档): 日更 0X1406FE1E0 检非零 → 汇总本国资源池快照 → 按 /1e5 缩放 (sub_141010F70) → 并入 production+512 资源映射 → **自清 0**; 置值生产者 = 读档键 13195 唯一 (负定案: 引擎无第二写点 — 全 dump +5216 触点逐一归属, 余皆异类对象) 语义 = 存档单向注入的一次性资源快照, 载档后首个日更消费并自清 | sub_1406FE1E0 L243-251 |
| +5224 | MSVC 串 | **assign_all_forces_to** {buf@5224, size@5240, cap@5248=15} | loader case 13993 串解析 |
| +5225..+5255 | — | = assign_all_forces_to 串本体 | |
| +5256 | MSVC 串 | cosmetic_tag {buf@5256, size@5272, cap@5280=15; 名称缓存组合源之一} | §4.3.8 起 |
| +5257..+5311 | — | = cosmetic_tag 串尾 (size@5272, cap@5280=15; ctor+探针双证) + **+5288/+5296/+5304 = army/navy/air_score 三缓存** (i64×1e-5: ARMY/NAVY/AIR_SCORE_MULTIPLIER defines × 军力摘要; 日更 sub_1406D77C0; getter 0X1406EC030/0X1406F30B0/0X1406EB6A0; 探针 GER 16.350/13.000/0.000; GUI Country 面板消费) | sub_1406D77C0 |
| +5312 | fixed×1e-5 (int64) | **propaganda_stability_penalty** (≠0 才写裸键; writer 键 19272) | §4.3.8 起 |
| +5320 | fixed×1e-5 (int64) | **being_bombed_support_penalty** (≠0 才写; writer 键 15440) | §4.3.8 起 |
| +5328 | Q15 (int64) | heroes_dying_war_support_penalty (门非零才写, writer 0X1407191B0 尾段) | §4.3.8 起; writer 键 15441 互证 |
| +5336 | fixed×1e-5 (int64) | **convoy_raiding_war_support_penalty** (≠0 才写; writer 键 15439) | §4.3.8 起 |
| +5344 | fixed×1e-5 (int64) | **propaganda_war_support_penalty** (≠0 才写; writer 键 19271) | §4.3.8 起 |
| +5352 | fixed×1e-5 | accidents_score | §4.3.8 起; writer 键 0x37FC 互证 |
| +5353..+5359 | — | = accidents_score 本体: i64 (+5352..+5359) 的尾 7B, 无独立字段 (探针 0.013) | |
| +5360 | CCountryPlayerSettings (内嵌) | **player_settings** (vtable 名直读; 内容器 {data@5368, cap@5376, count@5380, alloc@5384}, u8@5392) | writer 键 0x3857; **GUI: 决议 ignored 名集 (定案)** = 本对象 (token 14423) 内 ignored 决议名集合 — 写侧 CIgnoreDecisionCommand::Execute 0X141157240 (+72=1 插入/=0 删除) + CIgnoreAllAvailableDecisionCommand::Execute 0X141156FD0; 读侧 sub_1414E7100(cc+5360, def+288 名) 命中 → 行状态元 1, 未中 2 |
| +5380 | uint32 | player_settings 写门/计数 | 定案 |
| +5381..+5415 | — | = player_settings (64B, +5360..+5423) 尾: count@5380 高 3B + **alloc@5384 哨兵** + **u8@5392 = unit_controller_weights_tracking 调试旗** (控制台 "Toggled unit controller weights tracking" 翻转; 探针 0) + pad + **第二运行时容器 {d@5400, cap@5408, c@5412, alloc@5416}** — ⚠ +5416 = 本容器 alloc (序列化器 0X1414E7670 只发第一容器, 本容器不落盘) | dtor sub_1406CCDD0 |
| +5416 | CPdxNewDeleteAllocator* | 第二运行时容器 alloc (哨兵 &off_143085170) | 定案 |
| +5424 | std::function\<bool(bool)\> | (ctor sub_140CFEA50 由 lambda 构造, 类型名含 `CCountry::QEAA_H_Z`; 读者 0X1406FDBA0 sub_140CFEAD0/3C0) | 不序列化 (形态定案; 语义未决) |
| +5496 | double | 战术重估计时采样 (闭包体 sub_140CFEAD0 写 functor+72 = cc+5496; sub_14224DBD0 = 高精度计时器非 RNG; **每小时被日更时体 0x1406FDBA0 经 functor 直写盖章** = 计时器现值; 调用方 = preferred_tactic 重估链, 消费链闭合: sub_1406FDBA0 头部经 functor 盖章后接 cc+5584 preferred_tactic → vtable+80 门 → sub_1413C6EA0 战术校验失败换 sub_1406C0710 默认 (高置信 — 闭包 = preferred_tactic 重估计时戳采样)) | 不序列化 (高置信) |
| +5504 | CCountryFuelStatus* (0xE8=232B; vtable 0x298B3A8) | **fuel_status** (writer 键 0x3B10=15120; loader case 15120 → vtable+24 parse; ctor sub_1410F0AF0(cc); surrender 调 sub_1410F7F50; 其 +8 = **燃料量** (Q15; setter sub_1410F7F50 / 比 getter sub_1410F3570; §4.30 油料子窗同源) — 定案; 全链详 §4.3.16) | 定案; **GUI: 油料子窗** (logistics_fuel_window; 详 §4.3.14 B15 注) |
| +5512 | CCountryExperienceStatus* | 经验/活动 (0xA0B, ctor sub_1412A6130(cc)) | §4.3.8 起; vtable 0X29A80C0 (探针+RTTI) |
| +5513..+5519 | — | = CCountryExperienceStatus 指针@5512 尾 7B | |
| +5520 | MSVC 串 向量 24B | **name_group** 容器 (32B 串条目) | writer 块键 0x3C87 |
| +5532 | uint32 | name_group 计数 | 定案 |
| +5533..+5543 | — | = name_group 容器尾: count@5532 高 3B + **alloc@5536 哨兵** | |
| +5544 | scoped_ptr<CCountryOperationManager> | **operations** → **CCountryOperationManager** (0x60B; 内联 ctor: vtable + CCountryFinishedOperations vtable@+40, f32@+76=0.9; 容器 {data@+16, count@+28}; 按型净账 Σ = sub_141373BF0) | writer ADEC0 0x4A38, 前置 scopedptr 断言 (定案) |
| +5552 | scoped_ptr<CCountryOperationTokenManager> | **tokens** → **CCountryOperationTokenManager** (0x48B; ctor sub_141405CF0(cc); 落键 intel_source/operation_assets, 旧键 tokens 兼容 — 布局 §4.11.17) | writer ADEC0 0x4A48 (定案) |
| +5553..+5559 | — | = tokens scopedptr@5552 尾 7B | |
| +5560 | 匿名结构 (88B 形状)* | **active_ability 数组数据** (88B 条目) | writer 块键 0x3891, 子键 id/start_date/country/leader/num_units/strategic_region/cost 全对位; 消费详 §4.3.5 |
| +5572 | uint32 | active_ability 计数 | 定案 |
| +5573..+5583 | — | = active_ability 容器尾: count@5572 高 3B + **alloc@5576 哨兵** | |
| +5584 | CCombatTactic* | preferred_tactic: u32@*(cc+5584)+152 (writer 0X1407191B0; GER=0/CHI=42 定案) | §4.3.8 起; GER=0 时 = CNullCombatTactic 空对象 (vtable 0X27E6588, 探针+RTTI) |
| +5585..+5591 | — | = preferred_tactic 指针@5584 尾 7B | |
| +5592 | CState** | **scorched_states 数据** (8B 州指针数组, 写 state id@+88; writer 块键 19917=0x4DCD, 8B 步进, count@5604 门) | writer 块键 0x4DCD; loader 增长码四元组 | ⚠ 已消解: 与五容器族行 raids {d@csa+5592, 80B 元, writer 0x14066B3F0 键 19184} 系 cc/csa 两锚系同号并存 (本行 = cc 本体; raids = CStrategicAI), 双 writer 互证无重叠 (定案)
| +5593..+5599 | — | = scorched_states 数据尾 | |
| +5600 | uint32 | scorched_states cap (1.5x) | 定案 |
| +5604 | uint32 | scorched_states count (写门) | 定案 |
| +5608 | 指针 (allocator) | scorched_states allocator | 定案 |
| +5609..+5615 | — | = scorched_states 容器尾: alloc@5608 高 7B 哨兵 | |
| +5616 | uint8 | **underway_replenishment** (仅真写; +5618 removed_controlled_province / +5619 landlocked_start ctor 全零互证) | writer 键 0x402B |
| +5618 | uint8 | removed_controlled_province | §4.3.8 起 |
| +5619 | uint8 | landlocked_start (仅真写 yes) | §4.3.8 起 |
| +5620..+5631 | — | = **u32 国家修订号@+5620** (ctor 0; sub_1406FE1B0 ++; 触发 = 控制台 hidden focuses / 内战 releasing 大流程对母子两国各 ++; GUI 缓存到自身 +8476 做脏检查; 探针 GER=0; 不序列化) + +5624 = 地形位掩码 dword (has_terrain 直读位运算; 掩码语义见 §4.32 地形族) | sub_1406FE1B0; sub_14138A400 |
| +5632 | fixed×1e-5 | coastal_protection_ratio | §4.3.8 起 |

#### 4.3.2 CCountryOccupationStatus 布局 (cc+4048)

对象 sizeof 0x128, 双vtable vtable1 0x142984978 @occ+0 / vtable2 0x1429849b0 @occ+24 (RTTI 定名; ctor sub_140FF2940 双写); 序列化 writer 0X141000120 = vtable2 槽[2] — ⚠ a1 = occ+24 基差 24 (division_template_id reader+120 ↔ writer+96 同证; ⚠ decompile 字面 +232/+244 是 a1 基, 直读 occ 会撞空壳)。

| 偏移 | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| occ+8 | u32 | 驻军优先级 (写门 ≠1 才写, §4.3.6; ctor 链不写 +8, 占领管理器即 occ 本身, 记录回指 = dp+8 → occ) | |
| occ+24 | CDivisionTemplate* | 表3 记录 驻军模板 | |
| occ+32 | CCountry* | 所有者国 (州表经 cc+1120/cc+1132 双容器; 旧「CState* 向量」系 writer 视角误标) | |
| occ+64 | — | **通国占领状态 RH 表头占位** (load 0.9f@+92 自检) | |
| occ+120 | CDivisionTemplate* | division_template_id (§4.3.6 写门: 指针非空才写) | |
| occ+128 | CDivisionTemplate* | 现役驻军模板 (日更 phase A sub_140FF9DE0 重验: sub_140B9DD90(t+24) 判失效 → 遍历 cc+440 模板表 count@cc+452 选首个有效) | |
| occ+176 | u32 向量 | foreign_manpower_receiver (键 19144; {data@+176, count@+188}; 运行期作无效接收者清理队列 — 日更尾倒序清理, 谓词 sub_140FF7DA0) | |
| occ+200 | 匿名结构 (NNB 形状)* | 24B 容器 {data@200, cap@208, count@212, alloc@216}, 32B 元 {tag u32@+0, …, obj CPersistent@+24}; writer 块键 15700 (门 count@occ+212), tag 经 sub_140BB5980, obj 经 sub_1424C24F0 分发; reader 侧 = 「tag/sid 键 + CGameDate 值」对, 按键二分查找 (32B 步进), 命中写**元素+16 = 打包日期**, 未命中插入 (推定; 与 obj@+24 的 writer 分发口径关系待裁) | |
| occ+72 | RH 桶数组 | **按目标国 tag 查占领记录** {dist u8@+4, tag dword@+8, 值 ptr@+16, 24B 桶} (活体 1942.11 德国档 count=1 与 writer 直读双证) | 定案 |
| occ+80 | u32 | RH count | |
| occ+84 | u32 | RH mask (nbuckets = mask+1+extra) | |
| occ+88 | u8 | RH extra | |
| occ+96 | CCountryOccupationData* 向量 | 记录列表 {data@96, count@108} (条目级 [N] 第 2 起; writer token 13667, 键 = 条目+24→国+8 tag 引号串, 体 CPersistent 分发) | GUI: 按页签过滤 (sub_14156F5B0 / sub_14156E780) |
| occ+120 | — | 默认法槽 (GUI occdata+120/+128) | GUI |
| occ+136 | 匿名结构 (NNB 形状)* | owning 裸指针 → ~2.3KB runtime-only 助手对象 {+8 多态成员(带串), +600/+16 容器, +2256..+2288 多态槽×4} (dtor sub_140FF2F20→sub_141689370+free; writer 不触); 语义推定 | 形态定案/语义推定 |
| occ+144 | CArmyManpowerValues (内嵌) | ctor sub_140FF2940 装 vtable; 内联容器 {data@+152, cap@+160, count@+164} (foreign_manpower 求和链闭合) | 定案 |
| occ+152..+164 | — | = CArmyManpowerValues 内联容器 {data@+152, cap@+160, count@+164} (空态共享容器静态) | |
| occ+160 | — | = CArmyManpowerValues 内联容器 cap (上 144 行内嵌容器成员; 非指针, 详 §4.3.6) | |
| occ+280 | COccupationLaw* | 默认法槽 (ctor sub_140FF2940 自 lawdb+88 装填; lawdb 库类 = COccupationLawDatabase; finder 回退链 rec+160 → occ+280 → 全局默认; 断言 countryoccupationstatus.cpp:561) | 定案 |
| occ+248 | — | 记录槽 (GUI 消费) | GUI |
| occ+256 | CScopedPtr 向量 (8B 元) | **resistance_attack_log** (键 0x4ACE=19150; 元素 = pdx CScopedPtr 8B, 断言非空 pdx_scopedptr.h:129; 条目类 **CResistanceActivityLog 定案** (vtable 符号 0x142984888, ctor sub_140FF2B50)) {d@occ+256, c@occ+268} 8B 指针数组 (探针 SIA 47 条 ↔ cnt 一致) | 条目 writer 0X141000640; 元素表见下 |
| occ+288 | u8 | 州↔记录对账进行中门旗 (phase C sub_140FFE6D0) | |

resistance_attack_log 条目 (元素 = 日志条目):

| 元素+N | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| 元素+8 | u32 | country tid (恒写; 0x289A 引号) | |
| 元素+16 | CState* | state ptr → id u32@ptr+88 (指针门; 0x1B7) | |
| 元素+32 | hours | date (ADEC0 0x284A, ptr=+40−8) | |
| 元素+48 | u8 | garrison (恒写; 0x2928) | |
| 元素+64 | uint32 向量 | manpower (键 0x283C=10300) {d@+64, c@+76} 元 8B {tag u32, value i32}, value>0 才写 (sub_140C6AD50; value={tag=.. value=..} 折叠叶) | |
| 元素+88 | CEquipmentVariantPool 内嵌 (64B) 向量数据 | equipment 池 (ADEC0 0x2F4E; 池槽位 = 池相对 {data@+32, count@+44, az@+56} — 条目相对即 +120/+132/+144; 无门 → allow_zero_entries 恒写; 尾 token 10208; 元 16B {var ptr, amount i64}, 门 amount≠0 或 az; id 对 {type@ptr+8, id@ptr+12}) | |
| 元素+152 | 匿名结构 (NNB 形状)* | resistance_activity (0x3D8D; ptr→SSO@+8 有值才写) | |

表2 记录 (CGarrisonDeployItem, vtable 0x1429f6200) 槽位 — 槽语义即 CStateGarrisonData 同对象字段 (上表 SGD+104/+136/+144/+208/+240 的 writer 视角):

| 表2记录+N | 类型 | 名称 | 参见 |
|---|---|---|---|
| 表2记录+104 | — | CGarrisonDeployItem 槽 | |
| 表2记录+136 | — | CGarrisonDeployItem 槽 (= 驻军人力需求读取槽, TRIGGER_GARRISON_MANPOWER_NEED_MORE_THAN/LESS_THAN 消费; 推定) | |
| 表2记录+144 | — | CGarrisonDeployItem 槽 | |
| 表2记录+208 | — | CGarrisonDeployItem 槽 | |

GUI: 占领面板数据源 — 记录列表 {data@96, count@108} 按页签过滤, RH 表 (occ+72 桶/occ+80 计数) 汇总回灌行 +48/+56 (sub_14156F5B0 / sub_14156E780); occdata+120/+128 默认法; +248 记录; 面板 +3952 = 驻军模板旗标, +3992 = 表2 记录经 sub_140FF5490 计算的 1e5 进度值 (定案: 所属 = occupied_territory_state_entry — Setup sub_14156EF60 a1[494]/a1[498]/a1[499] 对位; 非 cc 非 occdata)。

占领管理器 (occmgr = occ 本身, 无独立对象 — 旧「经 occ+8 回指」不成立, 记录回指 = dp+8 → occ; 下表基址 = occ):

| 偏移 | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| occ+256 | 匿名结构 (驻军日志条目) 向量 | 驻军活动日志容器 (= occ 主表 +256 resistance_attack_log 同容器; 元素 +8 tag / +32 时限 / +56 人力 / +88 装备; CGarrisonLogView) | |
| occ+280 | COccupationLaw* | default_law (= occ 主表 +280 行) | |

**占领记录 dp 布局补行** (dp = occ+72 RH 桶值@+16 = occ+96 记录列表条目; 真类名 **CCountryOccupationData 定案** vtable 0x142984928; 详形与写门见 §4.3.6)

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| dp+56 | i64 | **记录全部州平均抵抗** (写者 sub_140FFEBA0 = Σ st+632 / count; 0 州 → 置 0; −1 = Σ 溢出保护值 非哨兵; 读者 = CCoreResistanceTrigger 值 getter sub_1403EB0D0 直读) | 定案 |
| dp+64 | i64 | **记录全部州平均顺从** (Σ st+680 / count; core_compliance 触发器读; 0 州 → 置 0) | 定案 |
| dp+72 | fixed×1e-5 (i64) | garrison_required (键 19153; 记录级, 与 SGD 侧 +240 区分) | 定案 |
| dp+80 | fixed×1e-5 (i64) | strength_ratio (键 13567; 记录级, 与 SGD 侧 +248 区分) | 定案 |
| dp+176 | RH 桶数据 | **occupation_law_list** 州级占领法表 {mask@dp+188, extra@dp+192; 24B 桶 {dist@+4, sid@+8, 值*@+16}, 键 = 州 id} | 定案 (§4.3.6 写门族同源) |
| dp+200 | CDivisionTemplate* | division_template_id (键 12610, 记录级; 与 occ+120 并存, 两级序列化的分工未决) | 定案 |
| dp+208 | RH map 对象基 | **CStateGarrisonData map** {桶 data@dp+216, count@dp+224, mask@dp+228, extra@dp+232; 键 = 州 id FNV 73244475; 条目 = CStateGarrisonData 264B, 布局见下} | 定案 |
| dp+240 | RH map 基 | **garrison_template_by_state** 逐州驻军模板覆盖表 (键 19122; {data@dp+248, count@dp+256, mask@dp+260, extra@dp+264}; sid → CDivisionTemplate*; 供 SGD ctor 取模板, 推定) | 定案 |

CStateGarrisonData (SGD, vtable 0x1429848d8, 264B; writer 0x141000700 / reader 0x140FFC420):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 内嵌子对象 | 增援/交付请求子对象 (推定 CGarrisonReinforcementRequests; 交付速度 sub_14150EA90 = GARRISON_EQUIPMENT_DELIVERY_SPEED × 缺口, 人力交付率 sub_14150A490) |
| +48 | 向量 | 装备池 A {data@+48, count@+60} |
| +80 | 指针 | 脏旗宿主 (变化写 宿主+1312 = 1) |
| +88 | 指针 | 所有者链 (宿主 = *(SGD+88)+8+32) |
| +96 | uint8 | **驻军禁用 bool** (= 需求 < 0; sub_140FFCB60) |
| +104 | 匿名结构 (NNB 形状) 向量 | 人力池 (CArmyManpowerValues 形; 求和 sub_140C69830, 日扣 sub_140FF8BE0) |
| +136 | fixed×1e-5 | army_manpower_need (= 需求 × 模板人力(模板+400); 触发器 garrison_manpower_need 读全记录 Σ sub_140FF87C0) |
| +144 | 匿名结构 (NNB 形状) 向量 | 装备池 B (请求生成 sub_140FF88F0 → sub_140E6F910) |
| +208 | RH map | equipment_need (模板+288 装填 sub_14100D330) |
| +216 | 入参 | 装备满足率查表入参 (sub_140B99610(SGD+216, SGD+144, SGD+208)) |
| +240 | fixed×1e-5 | **strength 现值** (= min(1e5−(1e5−eq)^GARRISON_STR_POW_EQUIPMENT(3), 1e5−(1e5−mp)^GARRISON_STR_POW_MANPOWER(2)), sub_140FFC4E0, mp = min(1e5, 1e5×池/需求); set_garrison_strength 效果与 +256 双写; 边界: 池==0∧需求==0 → 1e5, 按需 getter sub_140FF5490(a3=1) 同型路径返 0 (穿透口径)) |
| +248 | fixed×1e-5 | garrison_required (= 需求核心 sub_140F94100: 0.75×clamp(抵抗, 10, 50)/模板压制值 × (1+mdef499 = MODIFIER_REQUIRED_GARRISON_FACTOR); 压制值 0 → −100000 禁用) |
| +256 | fixed×1e-5 | strength 基值 (override 对) |

#### 4.3.3 资源/租借系统 GUI 消费 (cc+4600)

| 字段 | 消费点 | 用途 |
|---|---|---|
| rs (整体) | 顶部资源条: sub_141D6DAC0 → sub_140CAED60 (resources_grid) | 顶部资源条 |
| rs+48 / +216 (净余) / +224 / +400 / +1112 | B15 资源余额行: × def+216 行号 → RESOURCE_BALANCE_VALUE 六元素; 进出口 sub_140C9DAE0(0/1); 因子 = 1e10/def+224 分母 | B15 资源余额行 |
| rs+1928 delivery_routes | 贸易路线快照: 按买方 idx → subwin+4144 (route+40 船队占用 / route+108 u32 = 贸易窗快照 win+4144 直拷, 语义推定; route+120 重算旗) | 贸易路线快照 |
| rs+576 | 产线材料成本行: 余额数组 × def+216 行号 → lacking 列 (填充 0X141D641E0, §4.31.33) | 资源余额数组 |

rs 布局全表已立 **§4.3.25**（下述 4 条补行 + origin/modify_building_resources/
extra_resource_origin 详表均已并入; giver tag = **u32**（键 12500, writer 转 tag 名串 /
reader 存 tag id）; only_imported 行宿主 = §4.3.25 第 4 池 @rs+1632, 其资源向量
@rs+1640）:

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| rs+1640 | 匿名结构 (16B {i64 value, u32 idx, pad}) 向量 | only_imported 侧资源数组 (16B 元); 不序列化 (writer 全扫无 a1+1616, 负结论) — 业务名 = only_imported 定案 (has_resources_in_country 键 12546 触发器: only_imported 旗→读 rs+1640 / extracted→rs+400 / buildings→rs+96 位对位直证); rs+1632 = CStrategicResourcePool 第 4 池 ctor 直证 | 定案 |
| rs+1808 | CResourceOrigin* 向量 | 资源权利对象列表 {data@+1808, count@+1820} (token `origin`) | 定案 |
| rs+1952 | 容器 (元素待裁) | modify_building_resources 表 (14547): 外条 32B {键 token u32@+0, pad, 内表 24B 向量@+8} (writer v4 += 32 步进直证), 内元 16B {u32 资源 idx, fixed×1e-5} (v30 += 16 同证) — 与 §4.3.25 行 1792 一致 | 定案 |
| rs+1976 | 16B 条向量 | extra_resource_origin (15049): 16B 条 {CScopedPtr<CResourceOrigin>, giver tag SSO@+8 (12500)} | 定案 |

权利对象 (rs+1808 列表条目) 与 given_resource_rights 布局已收 **§4.3.25**
（CResourceOrigin 元素布局表）。

#### 4.3.4 特种部队修正网格 (modifiers_grid)

CModifierEntry target = {item+32 = CModifier\* (= cc+1448 country_modifiers), item+40 = mdef idx u32}。宿主 = "modifiers_grid" **特种部队九格** populate sub_14170FA20 (唯一调用点 sub_1416FE590, 陆军/集团军 HQ 视图推定)。refresh/tooltip 消费 mdef 120B 行名 ("GFX_"+名 / 名+"_DESC") 与 pairs×1e-5。

九键映射:

| 值 | 名称 | 语义 |
|---|---|---|
| 367 | SPECIAL_FORCES_CAP | — |
| 187 | SPECIAL_FORCES_ATTACK_FACTOR | — |
| 188 | SPECIAL_FORCES_DEFENCE_FACTOR | — |
| 381 | SPECIAL_FORCES_TRAINING_TIME_FACTOR | — |
| 383 | SPECIAL_FORCES_OUT_OF_SUPPLY_FACTOR | — |
| 608 | PARATROOPERS | _SF_CONTRIBUTION_FACTOR 四兵种贡献率 |
| 609 | MARINES | _SF_CONTRIBUTION_FACTOR 四兵种贡献率 |
| 610 | MOUNTAINEERS | _SF_CONTRIBUTION_FACTOR 四兵种贡献率 |
| 611 | RANGERS | _SF_CONTRIBUTION_FACTOR 四兵种贡献率 |

特例格式化分派表 (样例, 其余分派条目未录):

| 值 | 格式化目标 |
|---|---|
| 0xFF | MAX_PLANNING |
| 0x101 | MAX_DIG_IN |
| 0x103 | LAND_NIGHT_ATTACK |
| 0x10A | NO_SUPPLY_GRACE |
| 0x10E (=270) | MISSION_CONVOY_ESCORT_EFFICIENCY |

#### 4.3.5 活动能力与借调条 (CActiveAbilityItem / 借调 strip)

> 可用性校验体 = **sub_1406DD920** (1,123 行; CP 不足/冷却/已激活组门 + 拒绝原因 loc 装配; 指令执行与 GUI 共用)。

**CActiveAbilityItem**: target = item+48 = CAbility\* (宿主 unit counter 非虚注入, 池@counter+280 {data+416, c+428}); 数据 = cc+5560 active_ability 88B 条目, 按条目+16==将领收集 (将领 +4168 HQ 引用 / +288 tag); 条目+72 = u8 隐藏门; 条目+0「id 代理对象」真身 = CAbility 本体。

**CAbility** (vtable 0x1429852f8, ctor 0X141009500):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | MSVC 串 | 串 id ("INVALID_ABILITY" 哨兵) |
| +584 | MSVC 串 | 双串之一 |
| +616 | MSVC 串 | 双串之二 |
| +680 | — | 图标块 |

**借调双条** (CActiveExpeditionariesStripView / CActiveVolunteersStripView): target = +56 本国 tag (基骨架, 模式 0/1/2 三实例, 工厂 sub_1415EAE80 直建入外交视图+5160); 链 = cc+760 expeditionaries_sent / cc+784 volunteers_sent id 对容器 → idreg 解析 (raw=res−16) → **元对象+480 当目标国 tag 比 = 借调东道国 tag** (§4.18 +480 行互证)。

四 strip 全走 CRelationStripViewBase 骨架 (仅覆写 [19] 扩展描述 / [20] 短描述 / [21] 存在谓词, [22] 全留基桩); loc 键 = `<token>_<侧>_extended_desc` / `_desc` 动态拼接 (token 13729 volunteers / 13730 expeditionaries / 10877 faction / 11490 wargoal 全直证)。

#### 4.3.6 occupation_status 顶级写门族 (偏移基 occ / dp; occ = writer 基 rp(cc+4048)+24, dp = 占领记录详 §4.3.2; 定案)

| 字段/块 | 写门/备注 |
|---|---|
| priority u32@occ+8 | **≠1 才写** (mem 337×1 无行 ↔ save 102×2 全为 2) |
| division_template_id | 指针@occ+120 非空才写 |
| default_law | 恒写 (439/439), 引号串 |
| occupation.\<R\> states.#1 | 单行多 token 空格串, 序 = 向量写序 (**非升序** — 原档 ETH 实证; reader table.sort 失真故段内联重读 {d@dp+32, c@dp+44}) |
| occupation.\<R\> compliance_modifiers.#N | 引号名, 向量序 (dp+88 键 15743 / dp+112 键 15747 两向量) |
| occupation.\<R\> resistance / compliance | 恒写 (writer 0X140FFF910 L153-154 无门) |
| occupation.\<R\> strength_ratio / garrison_required | **≠0 门** (writer L381-386) |
| state_compliance_cache.\<sid\> | 块门 = count u32@occ+240 ≠0; RH map 基 occ+224 {data@occ+232, count@occ+240, mask@occ+244, extra@occ+248} 桶 24B {dist@+4, sid u32@+8, value i64×1e-5@+16}; 写 sid=fixed5 (writer 0X141000120 L135-208, test1r HOL.309; reader 0x140FFB2D0 传 occ+224 为 map 基, 与 writer 同 occ+24 坐标系 — 单一坐标系定案) |
| occupation_law (每层) | 指针@dp+160 非空才写 |
| occupation_law_list.\<sid\> | 块门 = count u32@dp+184 ≠0; 桶 data@dp+176, 上界 = mask@dp+188+1+extra@dp+192; 桶 24B {dist, sid@+8, val*@+16}; 值名 = C 串内联 val+16 裸串; **sid 不经 states 过滤** (TUR KUR 353/800 越集实证); ⚠ law_list reader (对象层) 头偏移以本表为准 (错位曾致 MISS_MEM) |
| compliance_modifier (dp+248) | 块门 = count u32@dp+256 ≠0; RH 桶 24B {dist@+4, sid@+8, 值*@+16}; 值发射 = 值对象+8 的 id 对 (sub_142220180) |
| state_garrison_data.\<sid\> | **写门 = sid ∈ states 列表** (⚠ reader 扫 SGD 桶无头界会越界读入他国 occupation 桶; writer 本身无过滤, 全档 sid 集 == states 集等价门控); strength_ratio / garrison_required / army_manpower_need **≠0 门** (writer 0X141000700 if(*(a1+240/248/136))); manpower_pool.value 恒 1 条 owner tag; equipment.equipment[N] id 对 + amount ×1e5 向量序 (**条目门 = amount≠0 或 allow_zero_entries≠0**, 池 writer 0X141012DB0; 编号须在门内递增); **equipment_need.\<token\> = fixed×1e-5, 写门 amount≠0** (零需求不落盘); **garrison_reinforcement_requests.request[N]** (tok 19126, writer 0X141000700 尾调): 请求对象 {status u32@+32, progress i64@+40, total_progress i64@+48, produced 池内嵌@+88 {d@+8, c@+20, **az u8@池基+24 = itm+112**}, need {d@+128, count u32@+140}, date u32@+160}; **produced 条目门 = amount≠0 或 az** (与装备池同规则; 缺门则零额条目混入致编号错位) |

reader 三件 (CPersistent 槽[4]): occ = **0x140FFB2D0** / 记录 CCountryOccupationData = **0x140FFA320** (整记录 reader, 非仅法名段) / SGD = **0x140FFC420**。

**occ reader 键分发表** (sub_140FFB2D0; this = occ+24, 与 writer 同基 — 由 tok 12610→occ+120 / 19112→occ+280 / 19137→occ+144 / 19144→occ+176 / 15700→occ+200 五锚互锁):

| 键 token | 名 | 目标 (occ 坐标) | 读取器 / 错误路径 |
|---|---|---|---|
| 12610 | division_template_id | occ+120 | idpair 解析; 失败 → 跳值 + assert「No matching template!」:164 (B52, latch byte_14333D7ED) |
| 13667 | occupation | 记录列表 (occ+96) | tag 串 → 查建记录 → 记录槽[3] Load → 记录 reader |
| 15700 | foreign_manpower_date | occ+200 tag 排序容器 (32B 元, 二分) | 键可为 sid 整数或 tag 串; 坏 tag → 解析错误「Invalid country tag」 |
| 19112 | default_law | occ+280 | 串 → lawdb; 失败 → 解析错误「occupation law does not exist: 」 |
| 19137 | foreign_manpower | occ+144 (CArmyManpowerValues 内嵌) | 人力值 reader |
| 19144 | foreign_manpower_receiver | occ+176 tag 向量 | tag 列表 reader |
| 19150 | resistance_attack_log | occ+256 (CScopedPtr 向量, 8B 元) | malloc(0xA0) + 内联 CResistanceActivityLog ctor → 槽[3] Parse → 追加器入 occ+256 |
| 19329 | state_compliance_cache | RH map 基 occ+224 | sid 整数 + 定点串 → FNV 73244475 → 查插, 桶+16 = 值 |
| 其他 | — | — | 默认跳过 |

**记录 reader 键分发表** (sub_140FFA320; this = dp, 记录基 — 由 tok 11835→dp+32 / 19079→dp+168 / 19125→dp+208 / 15743·15747→dp+88·dp+112 四锚互锁):

| 键 token | 名 | 目标 | 读取器 / 错误路径 |
|---|---|---|---|
| 11835 | states | dp+32 向量 {data@+32, cap@+40, count@+44, alloc@+48} | int 列表 → gs+712 州指针数组 (界 [1, gs+724 计数)); **按存档序追加, 不排序**; 扩容 1.5× 经 alloc vtable+8/+16 |
| 12610 | division_template_id | dp+200 | idpair 解析; 失败 → 跳值 + assert「No matching template!」:1188 (B52, latch byte_14333D7F2) |
| 13025 | resistance | dp+56 | 定点 |
| 13567 | strength_ratio | dp+80 | 定点 |
| 15718 | compliance | dp+64 | 定点 |
| 15743 / 15747 | resistance_modifiers / compliance_modifiers | dp+88 / dp+112 | 修饰符容器 reader |
| 19029 | occupation_law | dp+160 | 串 → lawdb; 失败 → 解析错误「occupation law does not exist: 」 |
| 19079 | occupation_law_list | RH map 基 dp+168 | sid + 法名串 → 查插 |
| 19122 | garrison_template_by_state | RH map 基 dp+240 | sid + 模板 idpair → 查插; 失败 → assert「No matching template!」:1204 (B52, latch byte_14333D7F3) |
| 19125 | state_garrison_data | RH map 基 dp+208 | sid → malloc(0x108=264) + ctor sub_140FF2D20(inst, 记录, 州指针) → 查插 → SGD 槽[3] Load; **sid 越界/空 → 格式化错误日志「Unknow state」:1224 (通道 4096, 引擎原串拼写缺 l)** |
| 19153 | garrison_required | dp+72 | 定点 |

> **RH map 基址约定 (定案)**: reader 一律传 this 相对 map 基给查插助手, map 内布局统一为 **data@基+8 / count@基+16 / mask@基+20 / extra@基+24**。四处直证: occ+224 (state_compliance_cache) / dp+168 (occupation_law_list) / dp+208 (SGD) / dp+240 (garrison_template_by_state)。states 循环内含 gamestate 访问契约双断言 (:1116「gamestate unitilialized」latch byte_14332EDF9 / :1117「_ThreadForbidCount == 0」latch byte_14332EDFA)。

**驻军受损结算管线细化** (sub_140FF4D30, §4.3.6「攻击驻军」条补充): 损耗率 unk_1433317B0 (人力) / unk_143331868 (装备) × 攻击强度 >> 15; 强度比经 184B 缓冲 + 助手 sub_140FF3200(occ+136) 求模板强度比 (无模板 → assert「pGarrison should not be null」:746, latch byte_14333D7F0); 削减 = min(强度比, qword_143331910) 钳位上界; 人力损耗 = (人力率 × (0x8000−削减)) >> 15, 装备同形, 各钳 [0, 0x8000]; 人力池三段 (拷 → 扣 → 回写 SGD+104), 装备池 B 四段 (初始化 → 拷 → 扣 → 回写 SGD+144); 历史日志门 byte_14332F625 ∧ qword_14332F6A0 → SRW 锁@+2584, 条目 ctor sub_140FF2B50 (8 参) → 追加入 occ+256; 收尾 CState 脏旗 (+1312 = 1)。

> 断言 latch 家族 (countryoccupationstatus.cpp, B52 门 a4=1 一次性): byte_14333D7ED (:164 模板) / byte_14333D7EE (:561 默认法) / byte_14333D7EF (:729 驻军空) / byte_14333D7F0 (:746 驻军空) / byte_14333D7F1 (:908 接收者非空) / byte_14333D7F2 (:1188 记录模板) / byte_14333D7F3 (:1204 逐州模板) / byte_14333D7F4 (:1261 记录法) / byte_14333D7F5 (:2145 无模板); 外加 byte_14332F520 (eventscope.h:193 无限环) / byte_14332EDF9·FA (gamestate.h:1116/1117 访问契约)。

占领链行为链 (定案; 调度 = 日任务 "daily.occupation_update" → 逐国 (门 cc+1156>0) sub_1406E7680 → sub_140FF7170 六阶段): ① 模板重验 sub_140FF9DE0 → ② 默认占领法重验 sub_140FFF110 → ③ 州↔记录对账 sub_140FFE6D0 (死记录移除 / 找建 dp / 建 SGD ctor sub_140FF2D20 / 目标基值 sub_140F9BF40 / 邻州扩散 sub_140FF45E0 → sub_140F921A0 写 cr+40 (flow = RESISTANCE_RATIO_DIFF_TO_SPREAD 0.5×(源.cr+40 − 邻.cr+40)/1e5, 仅 >0 才写; defines:572) / 均值 sub_140FFEBA0 写 dp+56/64) → ④ 顺从缓存衰减 sub_140FF7380 (STATE_COMPLIANCE_DECAY_FOR_LOST_STATES) → ⑤ 逐控制州推进 sub_140F98050 (限时目标到期 / operational 重算 cr+520 / **cr+64 += cr+72 顺从** / **cr+16 += cr+24 抵抗** / LOCAL_ pairs 重建 sub_140F97640 / 活动掷骰 sub_140F97920) → ⑥ 逐记录 SGD 维护 sub_140FF6D10 (需求 sub_140FFCB60 → 人力日扣 sub_140FF8BE0 → 装备请求 sub_140FF88F0 → 交付子对象维护 → 强度 sub_140FFC4E0)。**州并行日更不推进抵抗** (sub_140F9C1C0 仅清 cr+696 脏旗)。载入重建零态: SGD 由 phase C 对账补建; occ+136 助手 sub_140FFE5A0 重建; 速度 (cr+24/cr+72) 与目标 (cr+32/cr+40) 不落盘每日重算; 驻军不足惩罚**不进抵抗公式** (目标/速度均无 SGD+240 项), 走穿透率 **sub_140F92B20** = (1e5−强度)×(1+Σmdef496 三源)/1e5 (下限 0.02 = RESISTANCE_ACTIVITY_MIN_GARRISON_PENETRATE_CHANCE, 钳 [0,1e5]) 与活动概率 sub_140F92E00 (基值 1.0 + mdef505 三读取点: 控制国 cc+1464 / 州×tag / 控制国→被占国外交关系 rel+304 CModifier, 无档位阈值; 终式 = 抵抗%×0.312×(1+Σ505) 钳 [0,1e5]) → 攻击驻军 sub_140F92710 (掷骰 RNG = sub_142233DB0 random_fixed 全局计数器哈希流 (§4.28.13), 输出 [0,1e5); 门① rand<发生率 严格< / 门② rand≤穿透率 含等号 / 门③ ΣW×rand 加权取) → sub_140FF4D30 扣池+写 occ+256 日志; 攻击损耗 = 因子 (1+Σ497×3+498, 下限 0.1) × 损耗率 (0.016 人力 / 0.02 装备) × (1−min(硬度, 0.90)), **2^15 定点** (占领域唯一非 ×1e5 域), 池按 (1−损耗) 缩减。

**CMajorCountrySelectionEntry / CMinorCountrySelectionEntry (国选器条目, GUI)**: (各 0x598B, def country_entry / country_entry_mini/_medium; 真入口 = 槽[19] Update 0X141F4A350/0X141F4A890): target = **+48 CBookmarkCountryEntry\*** (更正: 非 CCountry\* — ctor a1[6] = 第 4 参候选条目, tag 经其 +8 idpair 间接); Major 填 country_name (tag≤0 走 INTERESTING_COUNTRIES_OTHER_COUNTRIES 伪条目)/country_flag/country_leader 三元素, Minor 只填 country_flag; **大卡门 = CBookmarkCountryEntry+272 (minor 旗, 键 11242) == 0 — 定案** (候选元素类 = CBookmarkCountryEntry, vtable 0x1427E3DB8: +8 tag idpair / +24 MSVC 串 / +128/+160 容器 / +184 CAndTrigger available (12264) / +272 minor u16 / +280 OWORD / +152 ideology; Parse sub_14067E210 case 11242→+272 直证; 装载器 sub_14067DB80 按 +272 分档计数入 a2+240 容器; 原「判定对象=条目自身 +272」方向对但宿主类落名有误; CCountry+272 恒 0 与此门无涉); 同一选中高亮尾。

#### 4.3.7 国规则对象 (sub_1406F8410(国) 返回)

无独立 RTTI 类 (负定案) — 按国返回的规则状态对象; rule def 库见 §4.26 (qword_1433304C0, 56B/条)。

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +64 | uint8 数组 | 规则字节表 = CRule 值区 (ctor 默认 = CRuleDefinition+50 逐槽拷入; has_rule 读取; +84 = 值[20] = CAN_CREATE_COLLABORATION_GOVERNMENT — collaboration 门即此规则) | 定案 |
| +84 | uint8 | collaboration 可用门 (错误串 ":21458" 锚定) | 推定 |

#### 4.3.7a CRule 固定规则域 (rule.cpp; RTTI 真名 CRule — 书旧名 CRuleOverrides 已并; 外交/意识形态固定规则系, 与 gamerules.cpp 自定义规则系两域勿混)

类 = **CRule** (1016B; vtable 0x142718B48, RTTI `.?AVCRule@@` exe 直证; ctor sub_140638A10 / copy ctor sub_14014AC90; writer sub_14063C490 书已载); 宿主 = cc+1640 (合成缓存) / cc+2656 (external_rules) / idea+1216 / **CProgressSection+568 (新记)**:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | MSVC 串 (32) | desc (token 10644; writer 仅在规则定义表空 (count==0) 时写 — 兜底怪癖) |
| +40 | 链表头 (24) | {first@+40, last@+48, count@+56, u8@+60}; 32B 节点; 载荷未决 |
| +64 | byte×28 | 规则值表 (ctor 默认 = CRuleDefinition+50 逐槽拷入) |
| +92 | byte×28 | 显式设定旗 (ctor 清 0; writer 只写旗≠0 槽, yes/no 皆落盘) |
| +120 | MSVC 串 (32) ×28 | override 名串槽 (token 14561; writer 键 = 槽序号裸数字, 仅文本模式门写) |

**CRuleDefinition** (56B; ctor sub_140638B20, vtable 符号直证): +8 规则名串 (32B) / +40 规则名 token / +44 装入序号 (NONE = 0, 余 1..27) / +48 旗A (25/28 条 = 1; 唯 CAN_ONLY_JUSTIFY_WAR_ON_THREAT_COUNTRY 与 UNITS_DEPLOYED_TO_OVERLORD = 0; 语义推定 = UI 可选择性) / +49 旗B = 反转规则门 (仅 CAN_NOT_BUILD_BUILDINGS / CAN_NOT_DECLARE_WAR; 求值器按它换早退方向与组合子) / +50 默认值。全局定义表 = **qword_1433304C0 族** {基址 qword_1433304C0 / cap dword_1433304C8 / count dword_1433304CC / 分配器 qword_1433304D0 = off_143085170}; 默认 28 条 builder sub_14063A700 (表空才建), 全表:

| 序 | 名 | token | 旗A | 旗B | 默认 |
|---|---|---|---|---|---|
| 0 | NONE | 357 | 1 | 0 | 0 |
| 1 | CAN_NOT_BUILD_BUILDINGS | 10872 | 0 | 1 | 0 |
| 2 | CAN_NOT_DECLARE_WAR | 10874 | 0 | 1 | 0 |
| 3 | CAN_DECLARE_WAR_WITHOUT_WARGOAL_WHEN_IN_WAR | 12665 | 1 | 0 | 0 |
| 4 | CAN_DECLARE_WAR_ON_SAME_IDEOLOGY | 12666 | 1 | 0 | 1 (内联读取有变量复用歧义, 待裁) |
| 5 | CAN_FORCE_GOVERNMENT | 13087 | 1 | 0 | 1 |
| 6 | CAN_GUARANTEE_OTHER_IDEOLOGIES | 13766 | 1 | 0 | 0 |
| 7 | CAN_SEND_VOLUNTEERS | 13315 | 1 | 0 | 0 |
| 8 | CAN_GENERATE_FAMALE_ACES | 13332 | 1 | 0 | 0 |
| 9 | CAN_USE_KAMIKAZE_PILOTS | 13344 | 1 | 0 | 0 |
| 10 | CAN_LOWER_TENSION | 13495 | 1 | 0 | 0 |
| 11 | CAN_JOIN_OPPOSITE_FACTIONS | 13537 | 1 | 0 | 1 |
| 12 | CAN_CREATE_FACTIONS | 13692 | 1 | 0 | 0 |
| 13 | CAN_PUPPET | 21573 | 1 | 0 | 1 |
| 14 | CAN_ONLY_JUSTIFY_WAR_ON_THREAT_COUNTRY | 13697 | 0 | 0 | 0 |
| 15 | CAN_BOOST_OTHER_IDEOLOGIES | 13893 | 1 | 0 | 0 |
| 16 | CAN_OCCUPY_NON_WAR | 13932 | 1 | 0 | 1 |
| 17 | CAN_DECLINE_CALL_TO_WAR | 14115 | 1 | 0 | 1 |
| 18 | UNITS_DEPLOYED_TO_OVERLORD | 14104 | 0 | 0 | 0 |
| 19 | CAN_JOIN_FACTIONS | 14220 | 1 | 0 | 1 |
| 20 | CAN_CREATE_COLLABORATION_GOVERNMENT | 14672 | 1 | 0 | 1 |
| 21 | CAN_BE_SPYMASTER | 19131 | 1 | 0 | 1 |
| 22 | CONTRIBUTES_OPERATIVES | 19130 | 1 | 0 | 1 |
| 23 | CAN_BOOST_OWN_IDEOLOGY | 19559 | 1 | 0 | 1 |
| 24 | CAN_GENERATE_FEMALE_UNIT_LEADERS | 12686 | 1 | 0 | 0 |
| 25 | CAN_GENERATE_FEMALE_COUNTRY_LEADERS | 12683 | 1 | 0 | 0 |
| 26 | CAN_ACCESS_MARKET | 16292 | 1 | 0 | 1 |
| 27 | CAN_USE_UNDERWAY_REPLENISHMENT | 16490 | 1 | 0 | 0 |

**reader = 0x14063B900** (CRule::ReadMember 槽[4]; [2] writer 0x14063C490 / [3] Load wrapper 0x1424BE690): 10644 desc → +8 读串 / 14561 override 块循环 (惰性协议模板, 惰性值首字节 `@` 触发三元重读回写 — 与 character_portraits.cpp 循环逐指令同构, 同一内联模板跨 TU 复用) 逐串写 +120+32×下标 / 181 icon 仅拒绝块形态 (串值接受即弃, 推定图标由调用方统一读) / 28 规则名 token → 查表 sub_14063C120 (返 {序号, 值 byte}; 未中 = 28 哨兵) → 值入 +64+序号 + 设定旗 = 1 / 其他 → **throw** rule.cpp:172 `unknown rule '<名>' in file <文件>`。

**USOverrideSerializer** (≥56B; vtable 0x1427E0E98; 匿名命名空间 struct; writer sub_14063C6B0 = 写 `<规则名> = <值>` + desc + trigger 名): +8 规则序号 (28 条线性查表, token 比对 +40; 未中 rule.cpp:428 throw) / +12 值 (yes/no) / +16 desc 串 (10644) / +48 trigger 条目 (token 10595, 按名查 **qword_14332F058 = TGameItemDatabase<CScriptedTriggerTemplateDatabase>** 单例); 按键面推定 = 规则带条件覆盖条目 (宿主容器未决)。

**求值器 sub_14063A620** (定案): 实参 (运行期块基址, 规则序号, scope, 基线 CRule); 运行期块 = {tri-state u32×28 @块+8, 条件修正向量 28×24B @块+1016 (元 {值 u32@0, 条件对象@8}, 计数@+12)} = §4.3.1 cc+808 块 (+816 旗步进 4 / +1824 向量 与此吻合); 逐修正条件 (条件对象 vt[3]) 过后按旗B 分组合子 (旗B = 1 → sub_1403A61D0 且 tri-state==1 早退真; 否则 sub_140334950 且 ==2 早退假); tri-state 终态 {1 = yes, 2 = no}, 0 (未定) 回落基线 CRule+64+序号。**has_rule 触发器**: 解析 sub_140435880 (触发器 +88 存规则名 token, 查表拷序号 → +92) / 求值 sub_140416B80 (旗B 规则失败产 loc TRIGGER_HAS_NOT_RULE, 参数名 "RULE") / 事件域 sub_1406EA240 (scope 国 +808 块进求值器, 基线 = 宿主 +1640)。

#### 4.3.8 CModifier 通用布局 (192B; 内嵌@cc+3672 等五处) 与动态修正容器

**CModifier (192B; vtable 0x1427185f0; body ctor sub_140555FB0 于 mod+16 起调, 基 ctor sub_1424BE3C0 置 +8=357; writer sub_140612640 递归同类)** — 全书唯一权威布局, 全部内嵌点共用: 州 st+1736 (added_modifier) / MIO org / cc+1448 country_modifiers / power_balance+184 / leader+3840 命名修正块阵 b0..b14 / advisor.modifier / sub_unit_modifiers 容器B / faction upgrades spymaster。mod = CModifier 对象基址:

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | vtable | CModifier | 不序列化 |
| +8 | uint32 | =357 (none) 「末次键」调试 token (与 CTechnologySharing+8 同款) | — |
| +16 | vector 24B | **base pairs** {d@16, cap@24, c@28, alloc@32} — 16B 元 {mdef idx u32@0, pad@4, value i64×1e-5@+8} | c>0; 叶名 = 修饰 def token, 值 fixed5 (可负 — 读侧有符号 /100000) |
| +40 | vector 24B | **children** {d@40, cap@48, c@52, alloc@56} — 8B 指针元 → 嵌套 CModifier (= added_modifier 块); child 关键位 = name SSO@child+88 / data=u32@child+188 | c>0 (本档 0 叶) |
| +64 | vector 24B | **children 回收池** (`vector<CModifier*>` 自由表 {d@64, cap@72, c@76, alloc@80} — ClearChildren(flag=0) 整体 append 入池不删实例, GetOrRecycleChild LIFO 弹尾元重填复用; 仅 flag=1 路径真毁) | writer 不触 = 运行时 |
| +88 | MSVC SSO 32B | **name** (size@+104; writer 键 27=name / parser 同址读入; 存档形态例 `added_modifier.name="operative_mission_icons_small|1情报网"`) | size≠0 引号 |
| +120 | 匿名结构 (40B RH 桶) RH 桶数组 | **custom_modifier_tooltip 串集合** (表基 = mod+120; 槽 40B {hash, probe, 串} = 引擎 RH 桶族中的 40B 桶宽, 含 SSO 串内联; 键 768 每串 FNV-1a 插入; 消费 = 描述构建器 sub_14055B220 遍历追加为额外提示行) | writer 不触 |
| +148 | uint32 | 常量 1063675494 = 0.9f 精确位型 (0x3F666666, §3.2; RH load factor) | 不序列化 |
| +152 | uint32 RH 桶数组 | **hidden_modifier mdef idx 集合** (表基 mod+152, 槽 8B u32 集, 键 769 块内 pair 的 mdef idx 插入; 消费 = 行构建器 sub_140E630F0 探针命中即跳过该行) | writer 不触 |
| +160 | MSVC 串 | 第二 MSVC 串 {静态空@160, size@168, cap@176} (ctor 指向静态空串, dtor 非静态才 free) | writer 不触 |
| +180 | uint32 | 常量 1063675494 = 0.9f (hidden 集 mod+152 表 RH 尾, ctor 直证; §3.2) | 不序列化 |
| +184 | uint32 | **pair 接纳类别掩码** (sub_140557940 首行 `(mdef+100 flags & mod+184) != 0` 才合并该 pair; 国家聚合用 0xFFFFFF=24 类位) | 不序列化 |

> +184 双读归一定案: ctor 0xFFFFFFFF 与 pair 合并门掩码同一位型 (i32 −1 = 全类接纳初值), 无冲突; 不序列化。
> 归一补证: body ctor sub_140555FB0 全 dump 184 个调用点全部经它, `*(a1+168) = -1` (mod+184 = 0xFFFFFFFF) 无任何内嵌点写异值; 掩码读 sub_140557940 首行 (def+100 & a1[21]) 与 pair 合并门位型自洽 — 两假说 (内嵌点差异/误读) 皆否定。
| +188 | uint32 | **data = 子级展开深度** (writer 键 240=data, ≠1 才写; merge 时 dst.data>0 → 每来源生一个命名 child (data=dst−1); 存档形态 `added_modifier.data=0` 吻合; ⚠ parser 对 data 读值即弃 — 加载后由宿主 recalc 重建) | ≠1 才写 |

静态修正注册/查重器 = sub_14060D830 (modifier.cpp:127 "Duplicate modifier ID: %s"; 内联 ~70 静态修正名清单: weather 13 种 / war_support_good|bad|during_war / stability_good|bad / screening|capital_screening_bonus / pride_of_the_fleet×3 / resistance_effect|_base / compliance_effect|_base / {active,full,passive}_decryption_modifier / intel_network_state_level_{bonus,penalty} / lacking_consumer_goods / night / non_core{,_controller} / attache_sent / in_faction{,_original} / country_is_at_{peace,war} / naval_mines_effect / root_out_resistance_mission_modifier / operative_nationality_{mission,operation} / air|carrier|ship_experience_{bonus_max,malus_min} / created_intelligence_agency 等 — 静态修正枚举源)。

修饰定义表寻址 (BASE 相对; 供 +16 pair 的 def_idx → def 解引用; 消费者 = sub_14101CC90 sub_unit 定义装载校验 ("Sub unit definition X already specified" / "Invalid sub unit definition: ") / sub_140C35570 同族构造件 / **sub_140225AF0 全名收集器** — 控制台 loc_check_modifiers 与 loc_check 总校验的 mdef 名源, 遍历 120B 条跳空白名查本地化键缺失):

| 项 | 值 |
|---|---|
| defs | rp(BASE+53669264) (= qword_14332ED90) |
| count | ru32(BASE+53669276) (= dword_14332ED9C) |
| stride | 120B |
| token id | u32@def+112 |
| flags | u32@def+96 (bit4 = 读取时值钳 [0,100000], factor 型防负防爆) |
| 合并类别位 | u32@def+100 (sub_140557840 接纳外门, 与 mod+184 掩码按位与) |
| 适用性门 | u32@def+104 (非 0 时调内容适用性回调 qword_1433300A0, 结果按位与为零 → 取值返 0) |

修正读取 API (定案; 引用定义表的 65 函数全数核对, 无第二套取值原语):

| 层 | 函数 | 语义 |
|---|---|---|
| 国家/容器级取值原语 | sub_14055E360 | (容器描述符 = CModifier mod+16, out, mdef_id): 二分 16B 条 {id, i64×1e-5}; 未命中返 0; 命中过 def+104 门 + def+96 bit4 钳位; 直量消费 952 处 / 421 函数 |
| 州×tag 级 wrapper | sub_1409D8F90 | (CState, out, tag/对象, mdef_id, Src, …): state+2256 桶 (208B 条) 国下标探测, 命中谓词 = tag 相等或 sub_140BB52F0 同原初国, 取条目+32 (桶内 CModifier.pairs); 无命中回退 state+1368 州默认表; Src 非空时同 id 边算边 append 格式化行 (战斗 breakdown 通道) |
| 显示格式化族 | sub_140559C30 / sub_1405592B0 | (容器, out 串, id, scale, 精度) 返格式化串; tooltip/面板与公式点同读一份聚合表, 无独立显示缓存 |
| def 字段桥 (间接) | — | 海军 61 id 经 STAT 桥 sub_140BAAA20 (stat+1536 加值 id / stat+1544 因子 id → 查 cc+1464, §4.16); 装备 def+912 / 资源 def+240+244 / 特殊项目 def+1540 族 / 静态 def 按名查 sub_14055D480 (断言 "missing static modifier definition: %s") 各走宿主 def 字段 |

叠加律 (定案): 多来源同 id 聚合 = **纯加法** (sub_140557940 `entry.value += value×scale/100000`); 乘法结构 (X_FACTOR 族) 由公式点自算 `base×(1+Σfactor)/100000`; 无 max 型合成; 防负防爆由读取钳位 (def+96 bit4) 承担。
取整语义 (定案): 逐来源并入 `value×scale/100000` 为**有符号整除向零截断** (编译器 /100000 魔数 0x29F16B11C6D1E109 特征); scale=100000 无损, 非整 scale 来源有逐步截断——**每步整除处取整, 无最终统一取整** (截断差数值级, 平台无关)。
乘法折叠细则 (定案; 补上表 sub_140E5B960 行): ① pair 值 0 跳过乘; ② `out = out×(val+100000)/100000` 为逐步整除截断; ③ depth 语义 = children 递减计数, 0 = 不入子层; ④ 消费品链 (sub_140E630F0) 全式含**双下限钳** (百分比下限 define 槽 @3331498 / 数值下限槽 @33313C8) + 可用上限 + floor-1e5 取整——非仅"对全局下限钳位"。
线性插值注入 (定案; calc_modifier 尾部, sub_1406D5C20 + sub_140558470): 稳定度/战争支持度的 good/bad 族修正 (war_support_good|bad|during_war / stability_good|bad 等) 非阶跃并表, 而是**按当前值偏离阈值全局 (qword_1433314F8 / qword_143330E98) 的比例连续缩放注入**——同一条 good 修正在不同稳定度水平下贡献不同, 全书其余修正均为纯加法, 此为唯一连续缩放特例。

泛型壳层 CPdxModifier\<CModifier, ModifierType, ModifierCategory\> (clausewitzlib 模板; 与本 192B 布局**同物异视角** — 方法首参恒为 mod+16 pairs 描述符视角 (children=mod+40 / 计数=mod+52), 无独立 RTTI/存储/vtable, **不新增任何布局**):

| 方法 | 函数 | 语义 |
|---|---|---|
| 乘法折叠 | sub_140E5B960 | (pairs 视角, mdef id, out i64, depth): id 过注册表门 (断言 "Invalid modifier call!" pdxmodifier.h:539) → 无子或 depth==0 且查值 ≠0 则 `out = out×(val+100000)/100000`; 沿 children (child+16) 递归; a1==0 时以 TNullObject 单例 pairs 视角兜底 |
| 树展平快照 | sub_140559650 | GetAllEntries: 自身 pairs 有序并入 CSortedAssociativeArray\<ModifierType, CFixedPoint\> 出参, 子树递归合并 |
| 逐条回调 | (全内联, `_Func_impl_no_alloc` mangle 直证) | ForEachEntry 式 lambda 入口 (GetPopularityTooltip 族消费) |

乘法折叠唯一外部消费 = 消费品计算链 sub_140E630F0 (cc+1464 传 pairs 视角, id 102 = MODIFIER_CONSUMER_GOODS_FACTOR 折叠 → 乘 id 103 = …EXPECTED_VALUE → 对全局下限 qword_143331498 钳位)。

**CResourceOrigin 资源池四联 writer = sub_140CBEFD0** (宿主 = CResourceOrigin, §4.23.3a CConvoyClient 派生; 键 11842 resources →+136 / 15753 resources_unclapamed (引擎拼写如此) →+312 / 15756 resources_temporary →+488 / 12121 buildings →+664; 另 state(439)/efficiency(13799)/delivery_route(12479)/+992 逐国名表; a1+128 = CState\* 字段; §4.13.6 步长同型系复用非同物)。

⚠ 修饰值叶静默缺失排查: 定义表基址手抄掉位即全族缺叶 — 以符号名 qword_14332ED90 / dword_14332ED9C 为准 (十进制 BASE+ 值手抄亦会掉位)。
⚠ 全族闭合证据: ctor sub_140555FB0 / dtor sub_1405566B0 / writer sub_140612640 三方闭合; 与 state added_modifier 同 writer 互证。

cc+3672 动态修正容器:

| 偏移 (容器) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +40 | 匿名结构 (64B) | 条目数组 容器数据指针 — {data, count}, 元素 64B |  |
| +52 | uint32 | 条目数组 容器计数 |  |
| 元素+8 | tag_id | tag (i32) | >0 才写 |
| 元素+12 | int32 | state 州 id | >0 才写 |
| 元素+16 | int32 | days | ≥0 才写 (哨兵 -1) |
| 元素+24 | 匿名结构 (NNB 形状) | def 名: cstr(*(e+24)+40) 静态类 | 双形态: 静态类 = cstr@(*(e+24)+40); 脚本实例化类 = MSVC 串内联@obj+40 (vtable 0x1D8FD48, size@+56), 以指针可解性判定形态; 恒写 (名读不出则整条跳过) |
| 元素+32 | uint8 | enabled | 恒写 yes/no |
| 元素+40 | fixed×1e-5 | value fixed×1e-5 数组数据 | c>0 才写块 |
| 元素+52 | u32 | value 数组计数 | c>0 才写块 |

动态修正求值 (定案; 求值函数 sub_140557BF0, calc_modifier 内先跑): 逐条目 — ① scope 决策: 条目 tag@+8 > 0 → tag 国 scope / state@+12 > 0 → 州 scope / 否则容器 scope; ② **enabled 门**: def+180 无 trigger 声明, 或 def+160 CTrigger 槽+24 Evaluate 对 scope 真 → 写条目+32 enabled=1; 假 → enabled=0 且 value 槽清零; ③ enabled 时双路并入聚合表: 静态部分 def+248 CModifier (sub_140557840, 类别位门 def+100) + 动态变量 def+440 数组 (216B/条) × def+452 计数逐条 sub_140544C90 对 scope 求值写条目 value 容器。容器虚方法 (vtable 0x1427D62B8) 仅序列化四槽 + dtor, 应用逻辑全在求值函数。载入零态 = CCountry Reset → sub_140558400 容器重置 + 燃料块 init (sub_1410F2960)。

#### 4.3.9 名字组 tracker (四槽位; ⚠ 槽位序 ≠ mode 值序)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| cc+112/120/128/136 | CNameGroupTracker* | 四 tracker (malloc 0x68, CCountry ctor 建); **槽位↔mode: cc+112 mode 0 = division / cc+120 mode 1 = ship / cc+128 mode 3 = railway_gun / cc+136 mode 2 = operative codename** | |
| +16 | 匿名名字条目 | unavailable_groups 容器数据 {d@+16, cap@+24, c@+28, alloc@+32} | 8B CNameGroup* 元, 元素名 = cstr(*(g+8)) 或 MSVC@g+8; writer 键 14603 (legacy 14567 同址) |
| +28 | uint32 | unavailable 容器计数 |  |
| +40 | 匿名名字条目 | available_groups 容器数据 {d@+40, cap@+48, c@+52, alloc@+56} | 同上; writer 键 14602 (legacy 12264) |
| +52 | uint32 | available 容器计数 | 同上 |
| +64 | uint32 | **_EndOfAlwaysAvailableIndex** (断言串直证) = available_groups 前 [0, +64) 恒可用前缀数 (可用组重建 sub_1409C9460 写入; 日更搬迁步 1 自此起扫, 前缀永不降级) | 定案 |
| +68 | uint8 | **列表变更脏旗** (日更搬迁/可用组重建分区均置 1; ctor 零) | 定案 |
| +72 | 匿名结构 (176B) | post_mortem 容器数据 {d@+72, cap@+80, c@+84, alloc@+88} — 第三容器, 元素 176B **CNameGroupMember 内联** (writer 0X1409C9B80, 键 14604) | 下表; BlackICE 实测峰值: ship 761/div 572 (bi8), 防御界须 ≥4096 |
| +84 | uint32 | post_mortem 容器计数 |  |
| +96 | uint32 | **mode** (0=division 1=ship **2=operative codename 3=railway_gun** — 三重证据 = 四 tracker 创建点 mode 实参 0/1/3/2 (cc+112/120/128/136) + mode 2 回调遍历 country+4032 情报机构 +216 特工 + mode 3 回调遍历铁路炮容器 +832/+984; 与 CNameGroup+336 E_NAME_GROUP_TYPE 同域) | ctor a3 |

post_mortem 元素布局:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | type | 恒写 (token 225); 定案 |
| +12..+15 | pad | (copy-ctor 不复制) |  |
| +16 | MSVC 串 (32B) | **串#1 = 身份名** (runtime-only; assign 不复制 = 身份字段) | ctor 栈 buf@+16 |
| +48 | int32 | **名字库记录 serial** | -1 = 未命名 |
| +52 | pad | (copy-ctor 跳过) |  |
| +56 | uint32 | **owner id** (国/特工) |  |
| +64 | uint64 | **owner 对象回指** |  |
| +72 | 匿名结构 (NNB 形状)* | **按 type 分域**: type3 = 铁路炮对象回指 (显示名 type3 支消费 `sub_140AF2070(db, …, *(a1+72))`, 解析后备 `*(*(a1+72)+472)` 取 tag); 其余语境恒 0 (唯一写点 setter 实参恒 0 仅证 codename/ship writer 语境) | 定案 (分域) |
| +80 | 匿名结构 (NNB 形状) | **源对象指针** (type1 语境断言串直呼 _pShip, 舰组 = `*(_pShip+1152)`; type3 = 铁路炮对象; writer 键 12110 ptr≠0 门写; equipment id 对指针形态 (→{type@+8, id@+12}) 属 +88) | 定案 (分域) |
| +88 | uint64 | **内联 8B idpair {type@+88, id@+92}** (type0 = 师引用, sub_14221F310 解析 → 对象+464 = 其名字组; post_mortem 日清/显示名 type0 同路消费 — 定案); 默认 = qword_14333D528 = **全局空 idpair 哨兵值** (全库 2567 处引用零写点, 凡 `x == qword_14333D528` 即「pair 为空」判 — 跨单元泛化模式) | 定案 |
| +96 | MSVC 串 (32B) | **串#2 = 当前名缓存** (驱动 override/osp 刷新; copy-ctor 复制) |  |
| +128 | uint32 | name_order | ≠0 才写 (14563) |
| +136 | MSVC 串 | override | 门 = size@+152 ≠ 0 (14561); 串体 {size@+152, cap@+160} |
| +168 | uint8 | is_name_ordered | 默认 1; ==0 写 `is_name_ordered=no` (14562) |
| +169 | uint8 | **override_set_programmatically** (osp 定案) | ≠0 写 (14646); ⚠ loader: type/name_order/is_name_ordered/osp 四键解析即弃, 仅 override/equipment 落储 |

divisionnamesdatabase.cpp 簇对账增补 (14 函数闭环; 断言锚行 316..2105 全员体内):

**CNameGroup (368B) 布局增补 12 字段** (装载器 = CNameGroup::ReadMember sub_1409C6870
块键分派, 缝合 = sub_1409C6530 PostFinalize 每组): +80 组名串 / +112 可用性触发器对象
(vtable[3] Eval 国 scope / vtable[5] Parse — §4.00.3 槽契约互证; 键 14254) / +120 恒可用旗
(重建时居前缀, 日更永不降级; 置位点未决) / +128 外部库 id 列表 (键 14557, 无效抛
"Error reading division names group") / **+152 有序与 +176 无序双名条目容器 (104B 条 =
{int 序号, 3×MSVC 串}; 键 14599/14600, 无序装载序自动编)** / +200 显示名格式模板
(键 14560) / +232 for_countries tag 数组 (键 14564) / +256 link_numbering_with pending
串表 (键 14558, 缝合消费后清空) / +280 互链组表 (双向互插) / +304 串 (键 12536, 语义待裁)
/ +336 E_NAME_GROUP_TYPE (键 10397/10400/15639/19732 → 0/1/2/3) / +344 单位类型 token 表
(键 15492, "_num_"=12 哨兵)。**显示名公式** (sub_1409C1B30): 模板 %s = 序号**罗马数字**
(sub_1422CDD10 贪婪查表), %d = 十进制 (替换原语 sub_1409C2610); 无组按 type 四路后备 =
师 → CUnitNamesDatabase 历史名 / 舰三级级联 / 特工按 +56 / 铁路炮取国组首元素。
**编号分配 sub_1409C0850**: 组+互链展开 → mode 出借者标 used 位图 (有序位图 = group+164,
无序 = group+188) → 首空位 (有序取条目文件序号, 无序取下标), 全满 = 出借者 out+1。
**组登记/注销对偶壳** sub_1409C5A80/5D90 (变参组列表 + 互链自动捎带; 桥 sub_1409C5940
按 member+168 分向)。**铁路炮组约束** sub_1409C50C0: 每国 ≤2 组 (1 公共后备 + 1 国家专属),
违规 throw :2099/:2105, >1 组保留专属弃公共。**post_mortem 日清 sub_1409C1780** (mode0 专属, mode 1/2/3 静默跳, >3 断言 "not supported" :718, 闩 byte_143339B28): 逆向扫 post_mortem 容器 (条目 176B: +8 E_NAME_GROUP_TYPE u32 — 非 ARMY 组类型待剪 → 断言 "_NameGroupType == E_NAME_GROUP_TYPE_ARMY" :1034, 闩 byte_143339B29 / +88 idpair {type,id} / +152 override 引用 qword), 无 override ∧ (+88 idpair 空 ∨ 解析失败) → swap-remove (sub_1409C04A0 搬运 + 末条目 vtable[0] 删除析构 + count--)。**成员→组解析 sub_1409C40E0 四路**: type0 = +88 idpair → 对象+464; type1 =
`*(+80 _pShip + 1152)`; type2 = 串#1 查 codename 链; type3 = +72/+80 对象取 tag → 国铁路
组容器首元素。
**成员↔组单位类型匹配谓词 sub_1409C1610** (结构高置信/语义推定): a1 = CNameGroup (+344 单位类型 token 表 / +356 计数), a2 = 变体对象; 表空 → 返 1 (全兼容); 非空取三路候选 id (变体 +1008 域对象 +8 / 沿 +1240 两级链末端 +8 / 国引用 +28 → cc+3952 CDeployment +8), 线性扫表命中或元素出现在变体自身 id 列表 (+1008 对象 +1376 data/+1388 count) → 返 1, 扫尽 → 0; a2 空且表非空 → 断言 :1746 (闩 byte_143339B30)。
**tracker mode 分派壳 sub_1409C5740** (语义推定按 mode 取/分配名字组): mode 0/1/2 → 单例 (sub_1409C4D60) +40/+56/+72 组容器槽经 sub_1409B9930 按名取组; mode 3 → sub_1409C50C0 (铁路炮约束, 上文); 收尾 sub_1409C9460; mode 非法断言 "unexpected tracker type" :437 (闩 byte_143339B26)。

#### 4.3.10 经验 / 核弹 / 力量平衡 / 国策

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| cc+5512 区 | CCountryExperienceStatus* | experience 三军经验 + shortages; activity_data 同区 | 布局 §4.3.15 |
| cc+4880 | CNuke* 容器数据 {cap@+4888, alloc@+4896} | nukes 容器 | 元素 72B CNuke (下表); 块 13719 门 count≠0 |
| cc+4892 | u32 | nukes 容器计数 |  |
| gs+1104 | CPowerBalanceSystem* | power_balance 系统 | 系统 vtable 0X296FCA0, 条目 vtable 0X296FC50; value/friends/Enemies 三槽; 1024 魔数已改 1e5 定点 |
| cc+5000..+5032 | 容器簇 | 国策 focus_cost_reduction / national_focus 进度树 / 海军剧场 / focus 减免 | focus_tree 名 MSVC@*(cc+4976)+8; CFocusStatus 全布局 §4.3.12; GUI: 焦点树重建 (0X141386BD0: cc+4976 树; 门 = win+8424/+8432 双缓存 ∧ cc+5620 树版本; 题栏 NATIONAL_FOCUS_TITLE) |

CNuke 元素布局 (72B, vtable 0X27E7270; writer/loader/RTTI 三源定案):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | — | 自存 token 13517 | 恒写 |
| +16 | 匿名结构 (NNB 形状)* | 宿主回指 |  |
| +24 | int64 | amount (**×1e8 = 1 弹**; 999 弹钳顶 = 99900000000; 扣弹/产弹/装填全链同量纲) | 恒写 |
| +32 | CNuclearStrike* 向量 24B | nuclear_strikes (多态元 CNuclearStrike, 下表) | count≠0 开块 (块 13719, 条 13718 ADEC0) |
| +56 | uint32 | **热核级旗** (1 = thermonuclear: 破坏域全州/装备全灭/伤害 max 档/视效 nuke_big_entity; ctor 第三参直存; 国侧复位预填 entry0=tier0/entry1=tier1; writer sub_14109A660 / loader sub_141099F80 均不触) | 不序列化 |
| +60 | uint32 | nukes_ready | 恒写 |
| +64 | uint32 | 待投余量 (num_nukes_left_to_drop 累加项; 落地清扫 sub_141098460 置 0) | 定案 |

CNuclearStrike 元素 (24B 多态; loader 逐元装载 = **在途打击随档持久**, 旧「弃读运行时重建」读法废):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable |  |
| +8 | — | 键 13718 |
| +16 | uint32 | province (10304) |
| +20 | uint32 | time (424) — 飞行小时 (0..NUKE_DELAY_HOURS dword_1433351D8, 默认 2) |

#### 4.3.11 country_fields 标量字段族 (覆盖率体检定案)

偏移均相对 cc; `*(…)` 解引行与「州自有」行不参与升序。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +496 | fixed×1e-5 | command_power |  |
| +536 | CVariables* | variables 族 (reader country_variables73) |  |
| +544 | uint32 | scripted_gui_random 种子 (writer sub_1407191B0 直读 cc+544 发 u32 叶, 键 15716 恒写) | ⚠ i32 符号门: 大值读 i32 (-2080830976 ↔ u32 2214136320), 勿按 u32 直读有符号字段 |
| +1192 | CState* | cores 容器数据指针 — `vector<CState*>` 8B 州指针 → gs+712 反查州 id | 保容器序单行 (FRA 尾部非升序 = 插入序, 禁止排序); c>0 |
| +1204 | uint32 | cores 容器计数 |  |
| +1205..+1215 | — | = cores count 尾 + cores alloc@1208 |  |
| +1216 | CState* | claims 容器数据指针 — 同构 `vector<CState*>` {cap@+1224} | ⚠ 非 stride-4 u32 id 读法 (误读形态 = 指针 lo/hi 对); c>0 |
| +1228 | uint32 | claims 容器计数 |  |
| +1229..+4123 | — | = §4.3 CCountry 主表全覆盖 (全量定案); 本行不再记账 |  |
| +4120 | uint32 | capital | GER=64 对拍定案 |
| +4124 | uint32 | original_capital | GER=64 对拍定案 |
| +4125..+4763 | — | = §4.3 主表 + **CRadarsPool@+4344 (256B 全闭)** + rs@+4600 + **CConvoys@+4608 (136B 全闭)** + delayed_event@+4752/+4764 (定案) |  |
| +4752 | 匿名事件条目 (0xC8)* | delayed_event 容器数据指针 — 元素 0xC8 | 下表 |
| +4764 | uint32 | delayed_event 容器计数 | 下表 |
| *(cc+5544)+88 | int32 | operations 顶层 priority | writer 0X1411A2690 ADFE0(0x8D=141); CZE/ITA/SWI=2 唯三/GER=1 |
| 州自有 | CVariables* | states variables.random: st+2040 指针, random = vo+12/vo+8 (与国家 CVariables 同构同序; writer 0X140BC9280 尾 ADEC0(0x2A4A, *(st+2040))) |  |

delayed_event 元素布局 (writer sub_141181300):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CEvent* | 事件对象指针 (名 SSO@+32; ev+48==0 时 B320 id 形态, 本档未现) |
| +16 | 内嵌 | **scope = CEventScope (writer 0X14053BDA0, 恒写块, 下表)** |
| +17..+191 | — | = 内嵌 CEventScope 全体 (176B @+16..+191 恰满; 见下方递归布局表) |
| +192 | uint32 | originator tag_id (tid>0 才写) |
| +196 | uint32 | 延迟总小时 (hours=h%24, days=h%720/24, months=h/720; 恒写三行) |

> 实名与函数锚 (1.19.3): vtable 0x1427E7488 / reader 0x141180910 / ctor 0x14117F120 (CCountry 侧工厂 sub_1406D0880 malloc 0xC8 后 push cc+4752); +16 内嵌 CEventScope: 拷贝构造 sub_140534F00 (根构造 sub_140535110 / 析构 sub_140535820 / Clear sub_14053BD00, 族全表 §4.00.4); +192 = ctor *a3; +196 = ctor a5 延迟小时; reader 10604 months×720 + 10605 days×24 + 12656 hours 三支累加; 每小时消费者 sub_1406FC980 (profiler "country.delayed_events"; 生命周期链 = §4.12.9)。

CEventScope 递归布局 (sc = 作用域首址):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | tag_id | country → tag 引号 | >0 |
| +12 | uint32 | random 值 2 (存档序第二) | **恒写** (默认 1) |
| +16 | uint32 | random 值 1 (存档序第一 — **写序反**, CHRX variables.random 同款) | **恒写** (默认 1587985054 = 0x5EB5B01E 魔数种子) |
| +24 | CEventScope* | root | ≠自指 (自指 = 根哨兵, 递归终止; 读取深度上限 8) |
| +32 | CEventScope* | from |  |
| +40 | CEventScope* | prev = CEventScope* 递归 |  |
| +48 | uint64 | runtime-only 保留 (ctor sub_140534CA0 与 +56/+64 三连清零) — 定案 (负) | 不序列化 |
| +56 | uint64 | 同上 | 定案 |
| +64 | uint64 | 同上 | 定案 |
| +72 | CStrategicRegion* | strategic_region = uint32@*(sc+72)+88 | ptr 非空 |
| +80 | uint32 | character id 对.type | 任非零 (对) |
| +84 | uint32 | character id 对.id | 任非零 (对) |
| +88 | uint32 | operation id 对.type | 任非零 (对) |
| +92 | uint32 | operation id 对.id | 任非零 (对) |
| +96 | uint32 | **combatant id 对.type** | 任非零 (对); ⚠ 永不持久化: writer 见非零即 assert "CEventScope cannot persist CCombatant" |
| +100 | uint32 | combatant id 对.id | 任非零 (对) |
| +104 | uint32 | **ace id 对.type** (12770) | 任非零 (对) |
| +108 | uint32 | ace id 对.id | 任非零 (对) |
| +112 | uint32 | **unit id 对.type** (10403) | 任非零 (对) |
| +116 | uint32 | unit id 对.id | 任非零 (对) |
| +120 | uint32 | **industrial_organisation id 对.type** (14501) | 任非零 (对) |
| +124 | uint32 | industrial_organisation id 对.id | 任非零 (对) |
| +128 | uint32 | **purchase_contract id 对.type** (19773) | 任非零 (对) |
| +132 | uint32 | purchase_contract id 对.id | 任非零 (对) |
| +136 | uint32 | **raid_instance id 对.type** (19183) | 任非零 (对) |
| +140 | uint32 | raid_instance id 对.id | 任非零 (对) |
| +144 | uint32 | **project id 对.type** (10022) | 任非零 (对) |
| +148 | uint32 | project id 对.id | 任非零 (对) |
| +152 | uint32 | **faction id 对.type** (10877; 定案) | 任非零 (对) |
| +156 | uint32 | faction id 对.id | 任非零 (对) |
| +160 | CSavedEventTarget* 向量 | saved_event_target 112B 元素数组 (类名 assert 直证; 元素键表 = state/country/character/operation/strategic_region/ace/unit/MIO/purchase_contract/raid_instance/project, combatant 拒写断言) | 仅 from==自指时写 |
| +168 | uint32 | state 州 id | ≠0 |

#### 4.3.12 杂项标量与容器族

偏移均相对 cc (country 对象); `tg+` 前缀行 = theater_group 对象相对。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +12 | int32 | last_collaborated_surrender_recipient | 带符号 >0 才写; 值 = 国 idx → 引号 tag (writer 0X1407191B0 → sub_140BB4E70 串表); reader combat_support_scalars |
| +29..+771 | — | = **CCountryManpower (40B @+808)** 与各 id 对/容器实底 (max_exile/add.. 全闭 + RH/六容器); 本行不再记账 |  |
| +136 | CNameGroupTracker* | operative_codenames_tracker (**mode 2**, 槽位 3) | post_mortem 全字段镜像 names_trackers 模式; §4.3.6 |
| +728 | 内嵌 | cached_navy_strength.sub_units: {d@+736, c@+748} 8B 元素 {舰种 token, 数量} | **块门 = 师/舰队/铁路炮容器任一非空** (writer `if(cc+668\|\|cc+644\|\|cc+692)`; 无军队国整块不写 — KR 被吞并 VNC 实证) |
| +760 | idpair | expeditionaries_sent 容器数据指针 — {d, c} 8B 内联对 {type@+0, id@+4} (writer sub_1406C8960 token 13427; `if ((cc+772))` 门) | c>0; `id=N type=T` |
| +772 | uint32 | expeditionaries_sent 容器计数 |  |
| +773..+795 | — | = expeditionaries_sent 容器 {d@760, cap@768, c@772, alloc@776} 内部 (pdx 24B) |  |
| +784 | idpair | volunteers_sent 容器数据指针 — {d, c} 8B 内联对 {type@+0, id@+4} | c>0; `id=N type=T` |
| +796 | uint32 | volunteers_sent 容器计数 |  |
| +797..+4107 | — | = volunteers_sent@784 + **CCountryManpower@808** + CCountryColors ×2 (含 +8 间隙) + owned/controlled/contested/cores/claims 五容器 + strategic_region_data RH 头 + 六容器@1304..1440 + 二 CRule/CModifier#2 内嵌 — 定案, 本行不再记账 |  |
| +820 | uint32 | manpower.current (CCountryManpower@+808 内 +12) | CTX 段 |
| +824 | uint32 | manpower_ratio | writer 0X140CFE9D0 AE670(694, [blk+16]); qword≠0 才写 (门 = ≠0 非 >0); GER 250000/ENG 105000/SOV 154500 |
| +832 | uint32 | exile (CCountryManpower@+808 内 +24) | exile >0 才写 |
| +836 | uint32 | max_exile manpower (CCountryManpower@+808 内 +28) | 独立 >0 才写 (writer 0X140CFE9D0 内 exile(+24)>0 与 max(+28)>0 两门互不联动) |
| +4016 | CCustomizableBuildingCollection* | naval_headquarter_status CBC: {d@+40, c@+52} 80B 条 | 条目布局见下表; CBC vtable 0X27E7418 (探针+RTTI); §4.16 关联 |
| +4096 | 匿名结构 (report 条目) | invasion_report 容器数据指针 — (指针数组) | 元素: tag tid@+8 / enemy tid@+12 / province=*(e+16)+164 / date hours@+40 |
| +4108 | uint32 | invasion_report 容器计数 |  |
| +4109..+4311 | — | = invasion_report count 尾 + intel_agency@4032 尾 + incoming_diplo@4088 尾 + original_capital@4124 尾 + graphical_culture 串@4136 + stability@4304 (定案) |  |
| +4304 | fixed×1e-5 | stability |  |
| +4312 | fixed×1e-5 | war_support |  |
| +4313..+4859 | — | = war_support@4312 (i64) 尾 + refresh@4320 + original_research_slots@4324 + **CPlayerAiPrefs@4328 (16B)** + CRadarsPool@4344 + rs@4600 + CConvoys@4608 + dirty@4749 + delayed_event + ace/nukes 累计表 — 定案, 本行不再记账 |  |
| +4324 | uint32 | original_research_slots | ≠0 才写 (亡国 0 不写) |
| +4749 | uint8 | dirty_controlled_states |  |
| +4848 | tag_id | civil_war_target 容器数据指针 — u32 tid 数组 → tag 引号 | c>0 |
| +4860 | uint32 | civil_war_target 容器计数 | c>0 |
| +4861..+4907 | — | = civil_war 尾 + initiator@4872 + original_tag@4876 + nukes 四元组@4880 + **占领度量 4×u32@4920..4935** + num_armies@4904 (定案) |  |
| +4904 | uint32 | num_armies_in_combat | 均 ≠0 才写 (num_ships 首轮 MISS_MEM = 日缓存刷新时序非布局问题); reader combat_support_scalars |
| +4908 | uint32 | num_ships_in_combat |  |
| +4912 | uint32 | num_ships |  |
| +4916 | uint32 | convoys_destroyed |  |
| +4917..+5051 | — | = convoys_destroyed@4916 尾 + **占领度量 @4920/4924/4928/4932** + research_slot@4936 + 4B@4940 + buildings@4944 + 建筑累计@4952 + focus 族 + fcr RH@5000..5039 (定案) |  |
| +4936 | uint32 | research_slot |  |
| +4944 | CBuildingStatus* | buildings 容器宿主 (vtable 0X2999050; 条目 writer = CBuilding vtable 0x298A7B8 槽[2] sub_1410DCCA0): level=lv%65536 (键 10348, entry+64) / healthy=lv/65536 (键 18560, entry+66) / partial_health (键 18559, entry+72) **恒写** | **repair_speed_factor ≠100000 才写** (键 15662, entry+80); reader 对称无门 |
| +5040 | CVolunteerForceTransfer* | volunteers_transfer 容器数据指针 — {d, c} 8B 指针元 → CVolunteerForceTransfer (0xA0, ctor 0X1415201A0); 块 writer sub_141523660 | c>0; 段 sv2_sec_c_volunteers |
| +5052 | uint32 | volunteers_transfer 容器计数 |  |
| +5053..+5075 | — | = volunteers_transfer 容器 {d@5040, cap@5048, c@5052, alloc@5056} 内部 (pdx 24B) |  |
| +5064 | CExileDivisionsTransfer* | exile_divisions_transfer 容器数据指针 — {d, c} 8B 指针元 → CExileDivisionsTransfer (0x38, ctor 0X1415117A0); 块 writer sub_141513970 | c>0; 同段 mode="exile" |
| +5076 | uint32 | exile_divisions_transfer 容器计数 |  |
| +5077..+5123 | — | = exile 容器 {d@5064, cap@5072, c@5076, alloc@5080} 内部 + **civil_war 动态 tag 注入表 {d@5088, cap@5096, c@5100, alloc@5104}** (运行时-only) |  |
| +5112 | 匿名结构 (16B) | dynamic_revolution_tag 容器数据指针 — (0x3569 推定): 16B 元 {子对象 ptr@+0, tag_id u32@+8} → 引号 tag; ideology = 裸 token 11838, 解引用层级 = 元→ptr→+8 (sub_140ADCDD0) |  |
| +5124 | uint32 | dynamic_revolution_tag 容器计数 |  |
| +5125..+5147 | — | = dyn_rev 容器 {d@5112, cap@5120, c@5124, alloc@5128} + given_air 容器 {d@5136, cap@5144} 内部 |  |
| +5136 | tag_id | given_air_volunteer_permission 容器数据指针 | tag 数组 |
| +5148 | uint32 | given_air_volunteer_permission 容器计数 | tag 数组 |
| +5160 | tag_id | received_air_volunteer_permission tag 数组数据 |  |
| +5172 | uint32 | received_air_volunteer_permission tag 数组计数 |  |
| +5184 | uint32 | received_air_volunteer_permission count 并行数组 (导出 "TAG=cnt" 串) |  |
| +5209 | uint8 | **is_major** (JAP/ITA/AUS=1, GER/ENG=0) | ⚠ 与 major@+5210 为两字段勿混; TGWR 等 mod 另落 is_major 叶 |
| +5210 | uint8 | major (vanilla 叶) |  |
| +5213 | uint8 | reserved_dynamic_country |  |
| +5214 | uint8 | use_legacy_ai_pp_spend |  |
| +5256 | MSVC 串 | cosmetic_tag |  |
| +5312 | Q15 int64 | propaganda_stability penalty | 同批同 helper (sub_1407191B0), ≠0 才写; reader Country.combat_support_scalars |
| +5320 | Q15 int64 | being_bombed_support penalty | 同批同 helper (sub_1407191B0), ≠0 才写 |
| +5328 | Q15 int64 | heroes_dying penalty (heroes_dying_war_support_penalty) | ≠0 才写 (writer 0X1407191B0 尾段 ADFE0(15441), 同批同 helper); reader Country.combat_support_scalars |
| +5336 | Q15 int64 | convoy_raiding_war_support penalty | 同批同 helper (sub_1407191B0), ≠0 才写 |
| +5344 | Q15 int64 | propaganda_war_support penalty | 同批同 helper (sub_1407191B0), ≠0 才写 |
| +5352 | fixed×1e-5 | accidents_score |  |
| +5584 | CCombatTactic* | preferred_tactic = uint32@*(cc+5584)+152 | writer 0X1407191B0; GER=0 / CHI=42; GER=0 时 = CNullCombatTactic 空对象 |
| +5618 | uint8 | removed_controlled_province |  |
| +5632 | fixed×1e-5 | coastal_protection_ratio |  |
| tg+88 | uint8 | navy_theater.theater_group.is_important (tg = theater_group 对象) | ≠0 写 yes, 常态 0 不发射 |

naval_headquarter_status CBC 条目 (80B, CCustomizableBuildingItem vtable 0X29D24B8) — 条目 writer 链: 容器 0X141511720 (门 count@+52>0, 键 0x2F59) → 逐条 slot1 0X1424BEC50 (开匿名块 thunk) → 条目 slot2 0X1415C1160:

| 字段/块 | 键 | 写门 |
|---|---|---|
| id/省键 | — | binst 指针@e+56 非空 (省 10304/439 双模式分支) |
| character | 0x4C16 | (type≠0 ∨ id≠0) ∧ 有效谓词 sub_14221F310; 非恒写 |
| 模块块 | 0x44C3 | 模块指针@e+64 非空 (writer 0X1416237C0 CNavyLeaderModule; 段门 char_type≠0 = 实战充分子集) |
| experience | — | ≠0 |

country.ace (CAce 元素; writer 0X14061BD30; 段侧实现 sv2_sec_c_country_scalars) — id 块恒写 {id@+12, type@+8}:

| 偏移 (e) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | uint32 | type | id 块恒写 |
| +12 | uint32 | id | id 块恒写 |
| +240 | MSVC 串 | name | 恒写 (空串照写) |
| +272 | MSVC 串 | surname | 恒写 (空串照写) |
| +304 | MSVC 串 | callsign | 非空才写 (size@+320) |
| +336 | uint8 | is_female | ≠0 |
| +344 | uint8 | alive | =0 写 no |
| +348 | uint32 | kill_type | ≠0 |
| +352 | uint32 | killer_name id 对.type | 任非零 (对 e+352/+356) |
| +356 | uint32 | killer_name id 对.id | 任非零 (对) |
| +360 | int32 | killer_country | 带符号 >0 → 引号 tag |
| +364 | uint8 | handled | ≠0 写 yes |
| +368 | 匿名结构 (NNB 形状)* | modifier (SSO@*(e+368)+8) | 指针非 0 |

特殊项目池 resources (池类 = NProject::CProjectPool vtable 0X29C6E28; resources 子对象 = CStrategicResourcePool)。访问链: S = rp(cc+4008) (vtable 0X2971838) → 池 P = rp(S+24) (项目容器 {data@P+16, count@P+28} 448B 元) → **resources = 池内嵌子对象 @P+72** {vtable@0, data@+80, count@+92}。

| 项 | 偏移 | 名称/语义 | 写门 |
|---|---|---|---|
| resources 容器 | P+72 {data@P+80, count@P+92} | CStrategicResourcePool 内嵌子对象 | 池 writer 0X141483890 (NProject::CProjectPool slot2; P vtable 0X29C6E28 RTTI 证) 尾部 ADEC0(11842=resources, P+72) |
| 资源元素 | 16B | {amount i64×1e-5@+0, 资源 token u32@+8}; 键 = lexer 资源名 (**aluminium=19999**, ≠ aluminum=15876 — 存档拼写为准) | 元素 writer 0X140BCCAF0 (CStrategicResourcePool slot2, vtable 0X29515A0) 发裸 `token=i64` 叶; ⚠ amount==0 整条不写; 元素门 = 指针≠0 (sub_140BCCAF0 实证) |
| 池元素 program id 对 | 元+96 (type) / 元+100 (id) | 元素 448B 内嵌 program 回填对 | ⚠ 同名 project 可重复 (每国两条实测) — 按容器下标对齐取对, 按名索引互覆 |

**CProjectPool reader/Setup (定案)**: reader = **0x141482CB0** (与 writer 0X141483890 对) — 键 10022 (project) → 主循环: 项目库全局单例 **qword_14332EFE8** (TGameItemDatabase 族, gameitemdatabase.h:142 断言) RH 查表 (data@+56 / mask@+68 / extra@+72, 24B 桶 {链长 u8@+4, 键 u32@+8, 值 qword@+16}, 哈希 = 0x45D9F3B 双轮雪崩, 键 = u32 lo^HIWORD) → 未命中错误 "Special Project \<名\> is in save but not in DB" (project_pool.cpp:93) / 命中 → sub_141480E60(P+16, def, P+8) 建池元 (池项目容器 = P+16 {data@+16, count@P+28}, 448B 元); 键 11842 (resources) → sub_1424C0AA0(ctx, P+72) (与 writer 尾部 ADEC0 对称); 其他 → sub_1424C2060 跳块。
> **Setup = 0x141483700**: 池空断言 (计数 a1+28==0, 否则 :54); **gs+2613 门** (世界构建进行中 → 跳过 clear+填充, 直接返 gs; 非构建期 → sub_141482A70 清池 + sub_141483010 自 DB 全量填充)。

CProgramStatus (S) 布局:

| 偏移 (S) | 类型 | 名称/语义 |
|---|---|---|
| +8 | vtable | vtable1 = 0x142971858 (CPersistent 基 @ mdisp 8; RTTI COL 直证); writer/dispatch 皆 vtable1 相对坐标 (this = S+8) |
| +24 | NProject::CProjectPool* | 池 P (NProject::CProjectPool, vtable 0X29C6E28) |
| +32 | CRef 向量 | program CRef 向量 {data@S+32, count@S+44} (GUI 宿主 CFacilitiesTabView+152) |
| +80 | NProject::CBreakthroughProgress | NProject::CBreakthroughProgress (块键 11956 breakthrough; ctor 0X140E75510 于 S+80 初始化); ⚠ writer 0X140E78830 (vtable1 slot2, this=S+8) 发 a1+72 = 绝对 S+80 — 「a1+72」勿按 S+72 读 (vtable1 相对坐标基差陷阱) |

CProgramItemBase target = NProject::CProgram (+56 CRef 柄):

| 偏移 | 名称/语义 |
|---|---|
| +72 | facility def |
| +80 | 项目词元 |
| +84 | 旗 |
| +88 | 科学家 CRef |
| +128 | 移除旗 |
| +144 | 拆除 COnDelay |
| +160 | 拆除中 |
| +176 | 支援科学家 |
| +248 | 进度 fix5 |
| +376 | uint32 未读原型奖励计数器 — ctor 0; Execute 0x141EF3F20 清零 + 项目 id 通知; **GUI 消费 = CProgramItemBase::Update 未读奖励窗柄 (+288) 显隐门** (`*(int*)(program+376) <= 0` → 隐, §4.31.32); ⚠「+368 旗容器」说与 ctor 无 +368 vtable 写相抵 (推定) |


NProject::CProgram 初始化 sub_141442B60 (program.cpp:106; 高置信): ① a1+8/a1+12 idpair 双 dword 非全零 → sub_14221E700(a1, a1+8, 0) 引用解析/登记; ② 派生量 **a1+168 = a1+144 − a1+148** (两 i32 计算字段, 语义未决); ③ CBuildingDatabase 单例 qword_14332EE28 (gameitemdatabase.h:142 断言, 闩 byte_14332F970) → sub_140683650(db, a1+32 建筑模板键串) → 模板指针挂 **a1+72**; ④ 模板 +32 有效旗为 0 → CLog 4096 "Invalid building template key: " + 键。

**特殊项目数据库输出件 sub_140A918A0** (project_database_output.cpp:185; 高置信): a1+8 = 项目 token u32; token == 357 (空哨兵) → CLog 4096 拼错 "\<a2\>:\<a3\>-\<a4\> : in option, the token is mandatory" (a2 = 名串, a3/a4 两 u32 转文本, 语义未决); 无论是否报错, sub_1424BC260(token) → 名串 → sub_14011FC50 追加进 **a1+528** (std::string 输出缓冲, 消费端未决)。
facility def 布局补行 (def = CProgram+72 所指):

| 偏移 (def) | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +664 | u32 数组数据 | 专精 id 表 (4B/条); 计数 @+676 | 推定 |

GUI 消费:

| 项 | 值 |
|---|---|
| CProjectListFilterWindow\<T\> (8 槽抽象) | populate 链 = cc+4008 → +24 = CProjectPool → P+16 项目容器; 实例化点 = CFacilitiesTabView ctor 0X141CAEA90 (§4.30.11 设施页签互证); 过滤维度 = 专精 (**CSpecializationDatabase = qword_14332F068**) |
| CProjectItem 双 target | CRef\<CProgram\>@+32 + CProject*@+40 (§4.31.6) |
| CProgramOngoingProjectView | **P+48 = token→项目 RH 映射** |
| 四命令 | CDismantleFacility / CAbortDismantleFacility / CUnattachScientist / CResetUnreadPrototypeRewardsCounter |

⚠ 运行时 base 每次启动随 ASLR 变, 布局证据里的绝对地址以 hoi4.base 为准勿照抄。


CAce 合并版全布局 (376B = 0x178; 类名 CAce 定案; writer 0X14061BD30 / reader sub_14061AFB0 (aces.cpp:547); ctor sub_1406176C0; 三源并表 — writer 表与 §4.3.12/§4.3.15 碎片归一):

| 偏移 | 类型 | 语义 | 备注 |
|---|---|---|---|
| +0 | vtable | CAce | |
| +8 | idpair | ace id 对 | |
| +24 | u32 掩码 | **熟悉机型掩码** (+1384 行废 — 376B 无此域, 掩码即本槽) | 定案 |
| +48 | 修正块 | ace 修正 | 定案 |
| +232 | idpair | 指派翼 idpair | 定案 |
| +336 | uint8 | **is_female** 女性旗 (GUI 侧头像族解析; 布局补行并表) | 推定 |
| +340 | uint32 | **portrait 整数** (ctor/reader/存档 portrait=78/活证 78 四证 — 原串说废) | 定案 |
| +344 | uint8 | **alive** (两表归并 — KIA = 零值语义; 原「+344 KIA/alive 两说」结案) | 定案 |
| +368 | CAceDef* | **ace def 指针** (ApplyAceDef sub_14061B7D0 写; writer 表只见 def+8 名串) | 定案 (原锚吻合) |

**省控制权变更监听 (CProgramStatus::[2] = 0x140E775B0; 新收)**: (this, prov, newTag) — 门 = tag 相同 ∨ (双非空 ∧ 同原初国 sub_140BB52F0), 否则断言 program_status.cpp:269 "OldController == _Tag && Province controller changes to same tag…"。入内: 新控制者 program_status = *(sub_140BB4390(prov+392) + 4008) (cc+4008, §4.3); 附庸旗 = sub_140D25830(*(*(国+3976 表 +8) + 8×idx)) (宗主−附庸判定, §4.8.10 同款); 省上设施 = sub_140689480(prov) (null → 断言 :282 "province is listened by program status but has no facility"); sub_140E75D40(新 program_status, prov+164 省序号, 设施+480 载荷); 非附庸 → sub_140E77EB0 (§4.7 阵营支援科学家链件); 主重绑 sub_140E77A70(省序号, newTag, 附庸旗^1); 尾经 idler 单例 qword_14332F698 vt[+128] → sub_140B53EE0(idler, 省序号) → 结果 **+5979 = 1 UI 脏旗**。

#### 4.3.13 CLoopHistory / 队列族 (country.history @cc+4040 / logistics @cc+3992 / strategic_air history — 三处同构, 唯一队列 writer 0X141517EC0, 全 dump 仅此一处写 max_elements token, 无类型分流)

vtable 实测定案: CLoopHistory vtable = BASE+**0X29D2A48** (slot2 = 0X141517EA0 纯转发), CLoopHistoryContainer vtable = BASE+**0X29D29A8** (slot2 = 0X141517EC0)。

```
logi = *(cc+3992)                      ; CLogisticsStatus (writer 0X141375A30)
ld   = *(logi+8)                       ; 19 槽指针数组 (定长)
elem = *(ld + 8*slot)                  ; CLoopHistory (0x38), slot ∈ [0,19)
槽守卫: elem ≠ null 且 ru32(elem+52) > 0
country.history: elem = *(cc+4040)     ; 固定 3 槽 (30/12/1 max 恒定)
strategic_air: {d@sa+344, c@sa+356} 指针元, N = 原槽位 0 起
```

CLoopHistory (elem, 0x38):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +0 | 8B | vtable | |
| +8 | 8B | ContainerQueue 基类子对象 vtable | |
| +16 | CLoopHistory* | history_queue.0 队列对象 (CLoopHistory) | |
| +24 | CLoopHistory* | history_queue.1 队列对象 (CLoopHistory) | |
| +32 | CLoopHistory* | history_queue.2 队列对象 (CLoopHistory) | |
| +40 | CLoopHistory* | self | 自指 |
| +48 | uint8 | is_16th | |
| +52 | uint32 | **cols 列数** | 双重身份: 槽守卫 >0 兼 data 行内值数 |
| +56 | CLoopHistory* | parent → cols = ru32(parent+52) | parent 回指; 三队列共享同一 cols (writer 经 parent 回读); **CLoopHistory (0x38) 继承 CLoopHistoryContainerQueue** (基子对象@+8, vtable 0X29D29F8, writer 0X141518230 数字键三队列; ctor/dtor 定案) |

队列对象 (qc):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 行句柄** 数组* | data = 行**对象**指针数组 | |
| +16 | uint32 | **cap** | ctor/dtor 定案 |
| +20 | uint32 | rows (行数 = 容量) | data 迭代上界 |
| +24 | CPdxNewDeleteAllocator* | **alloc** (&off_143085170 单例) | ctor/dtor |
| +32 | uint32 | **max_elements** | **writer 0X141517EC0 直读 +32**; 定案: +16 ≡ +20 ≡ +32 三槽值恒等 (46 队列零差, 探针); max 随族异 — history=1 / logistics=7 / strategic_air=5 (「30/12/1」系家族特定样本非普适) |
| +36 | uint32 | offset | 仅簿记, **写序不旋转** (物理行序直写) |
| +40 | uint8 | is_full → yes/no | |
| +41..+55 | pad | 对齐填充 (对象 64B) | 定案 |
| +56 | CLoopHistory* | parent → cols = ru32(parent+52) | parent 回指 |

data 块 (三阶解引 + 全零省略):

| 项 | 读法/语义 |
|---|---|
| 解引链 | `v = *(*( *(buf + 8*row) ) + 8*col)` — 行主序线性 |
| 第 1 阶 | buf[i] = **行句柄指针** (⚠ 直接当行数据基址 = 二阶解引读出指针字节恒非零 → 全队列误发) |
| 第 2 阶 | *(句柄) = 行数据基址; 行对象 {数据@0, count@12, alloc@16} |
| 第 3 阶 | 行基址 + 8*col = 值; 值型统一 i64×1e-5 fixed5 无按队列分流 (整值塌陷: raw -4100000 ↔ "-41") |
| 全零 v9 门 | 收集时所有值全 0 (或 count==0) → 整块 data 不写; 零值队列只发 max_elements/offset/is_full 三头叶 |

logistics 外层守卫:

| 项 | 值/语义 |
|---|---|
| 外层门 | writer 0X141375A30: `if (!sub_1406FFC90(owner))` — **仅人类控制国落盘** (AI 国 19 槽整块跳过) |
| idx | `u32@(*(gs+832))[tid]` (0X140BB5490; tid = ru32(cc+8)) |
| is_ai | b@(*(gs+880)+idx)≠0 且 b@(*(gs+904)+idx)==0 |
| 上界/落盘 | gs+916 = idx 上界; 落盘 iff not is_ai |

CCountryHistoryEntry (country.history (cc+4040) 条目对象; 数据类非 GUI, CPersistent 谱系指纹):

| 项 | 值 |
|---|---|
| writer | sub_141541190 (+32 侵入链表遍历) |
| reader | sub_1415403C0 — 8 case token 全解名: revolutionary_tag / starting_truck_buffer / starting_train_buffer / add_nuclear_bombs / capital / decision / oob / set_convoys |
| 槽[13] | 返 token **10394="country"** (GetToken; 族契约: Apply = vtable[17], 基 sub_140A3D610 递归遍历 +32 子表; 驱动 = sub_140A3D2A0 按 from<date<=to 过滤派发, 源串 history.cpp:165) |
| 落盘实证 | **条目不落盘** (负定案): 原版 GER 1937 与 KR2 晚局双档全量提取, 5 鉴别 token (revolutionary_tag/starting_truck_buffer/starting_train_buffer/add_nuclear_bombs/set_convoys) 零命中; 存档 country.history 只含 history_queue×3 数值遥测队列 — 8 case = history/countries 文件装载侧解析 (开局执行后不保留), writer 链运行时恒空; **export 无缺口, sv2 无需段** |

派生条目实名 (sizeof 统一 80; 载荷槽 = +72; vtable[1] Save 吐键值):

| 类 | vtable[13] token | vtable[1] 键 | 装载 case | Apply 语义 (+64 = country tag) |
|---|---|---|---|---|
| CCountryConvoysChange | 12386 convoys | convoys = i32@+72 | 12384 set_convoys | +72>0 则 sub_141020680(cc+4608, +72) 加进护航船池 (只加正数) |
| CCountryNukesChange | 12676 nuclear_bombs | nuclear_bombs = u32@+72 | 12677 add_nuclear_bombs | sub_141097B10(rp(*(cc+4880)+24), +72 推定): stock += 枚×1000×1e-5, clamp [0, 99900000000] (核弹库存 = cc+4880) |
| CCountryStartingTrainChange | 19710 starting_train_buffer | 同键 = u64@+72 | 19710 | sub_1406CF380(cc)+424 = +72 (开局火车缓冲) |
| CCountryStartingTruckChange | 19699 starting_truck_buffer | 同键 = u64@+72 | 19699 | sub_1406CF380(cc)+416 = +72 (开局卡车缓冲) |
| CCountryCapitalChange | 10315 capital | capital = u32@+72 | 10315 | sub_140710DD0(sub_140BB4390(+64), +72, 1) 设首都 (重存 vtable[1]=0x141540E70) |
| CCountryDecisionChange | 11142 decision | decision = CString@+72 | 11142 | 决策名加载入国史记录 (vtable[1]=0x141540EB0) |
| COOBChange | 12137 oob | oob = CString@+72 | 12137 | OOB 名加载入国史记录 (vtable[1]=0x141540F90) |
| CRevolutionaryTagChange | 13312 revolutionary_tag | tag = 名串(+72 革命 tag) + ideology = 名串(*(+80)+20) | 13312 | sub_1406D20A0(国, +80 意识形态 def, +72); **= CCountryHistory 后代 (兼容器身份, 自覆写 [1][2][4]: writer 0x1415411D0 / reader 0x141540B30)** |

容器与兜底: 国史容器 = **CCountryHistory** (vtable 0x1429D5D18, 基 72B + **+64 = 国 tag**; writer 0x141540FF0 = 州/国史容器共用, 双分支 = 条目+48≠0 → 写日期键块, 否则调条目 vtable[1]; reader 0x141540190 = 日期键 → 造壳 → Load → 注册日期); **CHistoryAddEffectCountry** (336B, vtable 0x1429D5DC0, [13]=89 effect) = 工厂默认分支兜底 (一切未识别键 → 内嵌 CEffect 列表@+72 + scope 子对象@+160; Execute 0x14153FF80 与州变体共享 = 重放效应; vtable[1] = 断言桩不回流)。州侧镜像族见 §4.13.7。

B15 后勤面板消费 — 行数值 = sub_141D9BFE0 → sub_141371450 聚合桶 (kind 枚举 loc+写入链双证定名); **logi+32 = 属主 CCountry*** (ctor sub_14136FA80 直证, CCountry ctor a1[499]=cc+3992 处传入)。

**CLogisticsStatus (128B, 每国恰一个)** 布局与运行时写者（定案）：

| 项 | 值 |
|---|---|
| 布局 | +0 vtable 0x29B3B88 / +8 19 桶指针数组 {data@+8, cap@+16, count@+20} / +24 alloc / +32 属主 / +40 flat 查量表 (24B 条 {CEquipmentType*@0, int 变体 id@8, i64 量@16}, 条数 +52; 查量 = sub_141373440 按 type / sub_141373540 按 (type, 变体), 前置谓词 sub_140C97430; 写者仍未位)/ +64 子对象 / +96 次表 (0x1429B3B70) / +112..+120 40B 节点 + 侵入链表头; 合法字段止于 +120（对象 0x80）——**+232 系越界读邻接堆块, 非字段** |
| 身份 | CCountry ctor `sub_1406C9CC0` a1[499] 逐国建（malloc 0x80 + ctor 第二参注入属主; 上游 = ReadCountryFiles sub_14071C5C0; 活体 440 国 440/440 非空, +32 回指零差） |
| 运行时写者① 每日推写 | sub_141375000（断言串 "logistics.postdailythreaded"）→ tbb `CCountryPostDailyUpdateThreaded` → 逐国 sub_140705580 → 全 19 桶推进 sub_141516980; ld[15] ← ps+520 生产条目（sub_141517DC0）; 人类国门 `!sub_1406FFC90` 内 ld[16] ← 库存−在用 |
| 运行时写者② 日更聚合 | CCountry::DailyUpdate sub_1406E76A0 → sub_141371390(logi) + 燃料史 sub_1410F2B50(fs) → sub_141373E50 七列写 ld[17]（桶 +136; 7 列 = `EFuelHistoryData::FUEL_DATA_COUNT`, col0 = (fuel≪15)/32768000） |
| 运行时写者③ 事件重填 | sub_141375840（同①填充段, 不推队列; 调用者 = 投降/吞并/读档族 0x140714170 / 0x140713DD0 / 0x14122F2F0 / 0x1419A4DE0 / 0x1419D6A60 / 0x14049CDA0） |
| 运行时写者④ 懒写回 | sub_1413719A0（logistics.cpp:934 断言 "CEquipmentType seems not be an archetype"; archetype 需求算毕写 ld[15] 单元格; 调用链 sub_141D99C10 行件读端 → sub_141371830, GUI 读端触发） |
| 桶 push 入口 | sub_141516980 直调调用者 = 上列①②③三路; 落盘 writer 0X141375A30 见 §4.3.13 外层守卫 |

kind 枚举（k 值 = sub_141371450 首参桶号）：

| 值 | 名称 | 语义 |
|---|---|---|
| k1 | 师增援 |  |
| k2 | 空军增援 | 读端定案 (sub_141D9BFE0 写 panel+1432 / sub_141D9D280 累加 panel+1464, 均 `sub_141371450(...,2,...)`); 写入端 = 上表写者①③; 桶机制 = CLogisticsStatus ctor sub_14136FA80 建 19 个 CLoopHistory 桶 (i==17 特判 v17=7) |
| k3 | 租借 |  |
| k4 | 驻军增援 |  |
| k5 | 行动 (operation) |  |
| k6 | 需求合计 |  |
| k7 | 增援交付完成 |  |
| k8 | 增援交付完成 |  |
| k14 | 窗口内交付部队装备合计 | status 条分子, LOGISTICS_STATUS "need covered by production"; 窗口 = define **LOGISTICS_PAST_WEEK = 7** (dword_143334C2C) |
| k15 | 库存现值 | 特例径 = 本桶 ∨ scale==0: 四基类谓词 sub_140C95730(type)&1 真 → 国家级 memoize (cc+4728 valid byte 未置则 sub_14100DCB0(cc+4624, ·, 1) 算一次存 cc+4736; 结果 = 1e5×(缓存/1e5 − *(dword*)(cc+4716)); 四件业务语义待裁) |
| k18 | 补给系统装备消耗 | country_supply.cpp:0x335 断言链 (卡车/火车) |

行槽字段:

| 偏移 (logi) | 名称/语义 |
|---|---|
| +1408 | 已承诺合计归一百分比 |
| +1440 | 可用余量 = k6−Σk1..k5 |
| +1384..+1488 | 行槽全字段定名区: 效率/库存/需求/结余/可增产/产量 |

#### 4.3.14 CFocusStatus (= CNationalFocusProgress, RTTI 正名)

fp = *(cc+4992); ctor 0X1402CB9C0 (malloc 0xB8); vtable BASE+0X2739D50, slot2 = writer 0X1402DC910。 writer 全键序 = 16323 activate_shine_on_focus (fp+32, c≠0 开块, joint 占位 alloc(18) 待裁) → 12583 completed (fp+64, joint 判 def vtable slot14 ≠ 桩, originator tag 断言 "completed joint focus has been added…" :1755) → 11013 progress (fp+56, ≠0) → 11125 current (fp+16) → 14053 current_continuous (fp+24) → 13969 paused (fp+176 反向门 ==0 才写)。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | CCountry* | **宿主国回指** (首字段定案) | runtime-only |
| +16 | CNationalFocus* | current 对象 → 名 SSO@+24 | ptr≠0; def 对象; **GUI: 国策进度块 label/goal_ico(_shine)** (外交 active_national_focus_info; 门 sub_141433D90 情报) |
| +24 | CNationalFocus* | current_continuous (0x36E5) → 名@+24 | ptr≠0; GER/test1/test2 0 现, BHU 6 例; reader Country.focus.current_continuous; def 对象 (CContinuousNationalFocus 系) |
| +32 | CNationalFocus* | shine 容器数据指针 — {d, c} 8B focus 指针, 名 = C 串@elem+24 (与 completed 同形态) | c>0 整块 |
| +40 | uint32 | shine 容器 cap | ctor |
| +44 | uint32 | shine 容器计数 | c>0 整块 |
| +48 | 匿名结构 (NNB 形状)* | shine 容器 alloc |  |
| +56 | fixed×1e-5 | progress | **≠0 才写**; **GUI: 国策进度条** (progressbar = 1e7×progress/total; NO_NATIONAL_FOCUS / UNKNOWN_INFO) |
| +64 | CNationalFocus* | completed 容器数据指针 — {d, c} 8B CNationalFocus 指针 | 逐元双形态 (下表) |
| +72 | uint32 | completed 容器 cap | ctor |
| +76 | uint32 | completed 容器计数 | 逐元双形态 (下表) |
| +80 | 匿名结构 (NNB 形状)* | completed 容器 alloc |  |
| +88 | RH 图 | **本视角国自有完成图** (定案): 写入侧 CompleteFocus sub_1402DC740 → sub_1402CD590 = **fp+88 FNV(def) RH 插** 直证; 读侧 sub_1402D6C40 = 命中且 byte+4≠0xFF (**0xFF = 空桶/墓碑**); 桶结构 32B {base@+88, buckets@+96 (默认空桶哨兵 &unk_143086980), count u32@+104, mask u32@+108, extra u8@+112, load_factor f32=0.9@+116} — 16B 桶 {hash u32@+0, dist u8@+4, key CNationalFocus*@+8} (插入器 sub_1402C5240 写 +0 哈希; 查找器 sub_1402C7270 只读 +4/+8, +0 无值语义) | originator 查询①; ctor 逐字段; runtime-only; **GUI: 焦点块状态码** (fp+88 命中 → item+48 状态 1..4 五状态窗 +56..+88; **状态 2 = 查看国自己完成**; 联合国策进度住工作国 fp, UI 经 sub_140DF65C0 GetWorkingCountry 换 fp 显示) |
| +120 | CNationalFocus* 向量 | **available focuses 可选候选缓存 (定案)** {d@+120, cap@+128, c@+132, alloc@+136} — 8B CNationalFocus* 按 focus id(e+8) 有序二分插入; 维护 = **完成路径增量** (sub_1402CD590: 有序移除自身 sub_1402C86B0 + 逐 def+1440 dependents 前置满足者有序插入 sub_1402D5F60); **全量重建唯一调用点 = 焦点树切换/恢复 sub_140711A60** (sub_1402D7340: 清空 → 遍历树全焦点 → 前置容器 (def+1392,{d,c@1404}) 空 或 每依赖组有备选 ∈ fp+64 → 插入; "Country focus tree is not set" nationalfocus.cpp:1612); daily 只做旁路扫描消费, 从不重建; AI DecideFocus sub_14131DAF0 **不读本表** (自走树扫描); 互斥在选择时判定 (ExclusiveItem 状态 4 输入 = def+1416 互斥组任一元 ∈ fp+88, sub_1402CEFA0 — 与 fp+120 无关) | runtime-only |
| +144 | 匿名结构 (24B 桶) RH 桶数组 | originator 表 **定案: 桶宽 24B = {hash u32@+0, dist u8@+4, key 指针@+8, tag u32@+16}** (插入器 sub_1402C5F10 stride 立即数 24; 插入调用点 sub_1402CD590 joint 分支 sub_1402C5F10(fp+144,…) / 查询 sub_1402D1930 / 删除 sub_1402DA9D0 四点闭环); 表头字段在基址 +8..+28 (与 +88 表头同构, 桶宽不镜像: +88 桶 16B); 联合国策 originator 记录: joint (def vtable[14]) → 插 {def→+16=完成者 tag}, 与 fp+152 originator 查询 sub_1402D1930 同族 (§4.3.13) | 定案 |
| +152 | 匿名结构 (24B 形状) RH 桶数组 | originator 表 {buckets@+152 (默认 &unk_1430869A0), mask@+164, extra@+168, load f32=0.9@+172} — 24B 桶 {dist@+4, key 元针@+8, tid u32@+16} | 查询② (读侧两链: 完成图→originator 表), 未命中 → tid=0; ctor 逐字段 + FNV-1a 指针哈希; runtime-only |
| +176 | uint8 | paused | **反向: ==0 时写 `paused=no`; ==1 整叶省略**; 且 focus 块无内容时整块不写 (paused 门 = ru8==0 且 has_content); reader 侧 token 13969 死吞 (sub_1424C0C00, nationalfocus.cpp 直证) = **非持久字段**, 载入后恒 0 由 daily 重算 — 写读两半边闭环 |

completed 双形态:

| 形态 | 判别 | 读法 |
|---|---|---|
| 联合国策 | 元 vtable+112 (slot14) ≠ BASE+**0x11D220** (万能 return-0 stub = sub_14011D220, dump 定案 `return 0`; CNationalFocus 基类 vtable = 0x2739C08, 派生联合国策 CJoint vtable 0x142739DA0 覆写返 1) | 写 `completed={ <TAG> <name> }` (originator tid 经 sub_1402D1930 三链查询) |
| 普通国策 | 上判不成立 | 写 `completed="name"` (引号, 名 SSO@e+24) |

RH 哈希 (fp+88 / fp+152 表通用):

| 项 | 值 |
|---|---|
| 哈希函数 | FNV-1a 32bit 作用于指针 8 字节 (h=0x811C9DC5, `h=((h^b)*16777619)&0xFFFFFFFF`) |
| 桶定位 | buckets + stride*(h&mask); stride 按表 = 16 (fp+88) / 24 (fp+144/152) |
| 探查 | RH 距离递增 (不环绕, 尾部 extra 槽吸收) |

#### 4.3.15 国策 def / 树 / inlay (CNationalFocus def / CJointNationalFocus / CNationalFocusTree / CFocusInlayWindow)

CNationalFocus def (size 0x620, ctor 0X1402CB440):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | MSVC 串 32B | 焦点名 {buf@+24, size@+40, cap@+48} (查名/错误串消费; +1528 SSO 为另一串) |
| +88 | uint32 | 名 FNV-1a 哈希缓存 (库线性扫 + 插树哈希) |
| +128 | 容器头 | 主图标 case 选择器对象 |
| +136 | 指针表 | 主图标表 {d@+136, n@+148}, 40B 元 (元素首字段 = 图标名串, GFX 库查名) |
| +160 | uint8 | 有主图标旗 (无图标且无 default case 报错) |
| +168 | 容器头 | 备用图标 case 选择器对象 |
| +176 | 指针表 | 备用图标表 {d@+176, n@+188}, 40B 元 |
| +200 | uint8 | 有备用图标旗 |
| +208 | 值块 | overlay (token 489) |
| +280 | 值块 | x (token 32) |
| +284 | int32 | y (自身原始坐标; 与 +280 同供相对位置求值求和) |
| +288 | int32 | **relative_position_id 解析缓存 x** = 被引焦点绝对位置 x (装载期 sub_1402D5500 递推写入 `def+288 = ref+280 + ref+288`, 要求被引焦点先脚本化) |
| +292 | int32 | **relative_position_id 解析缓存 y** (同上, 运行期算术中与 +288 抵消, 实效 = ref 绝对位 + 自身 x/y) |
| +296 | 偏移条目向量 | 条件位置偏移表 {d@+296, n@+308} (推定), 元素 {dx@+8, dy@+12, 谓词对象@+16 (vtable 槽 3 求值), 门 dword@+36 (语义待裁)}; show-hidden 旗 (byte_14332F638) 关闭且门≠0 且谓词真 → 位置加算 |
| +320 | 值块 | relative_position_id (token 14029) |
| +352 | CNationalFocusTree* | **所属树回指** (树内查名空则回退全库; 可开始谓词门 `country+4976 != def+352` 即不可开始) |
| +360 | 触发器 | historical_ai (token 13862) |
| +448 | 匿名结构 (NNB 形状) 向量 | **available** (token 12264); 条目计数@+468 |
| +712 | 匿名结构 (NNB 形状) 向量 | **bypass** (bypass_conditions, token 13241); 计数@+732 |
| +800 | 匿名结构 (NNB 形状) 向量 | **cancel** (token 10469); 条目计数@+820 |
| +888 | — | ai_will_do 值块 (token 10819) |
| +944 | 效果块 | **select_effect** (token 13244) — 选择焦点时执行 (§4.3.15a) |
| +964 | dword | select_effect 块区字段 (语义待裁) — 非零触发 sub_1402D5500 清 def+1469 cancelable |
| +1032 | 效果块 | **completion_reward** (token 12784) — vtable[10] 完成时执行 |
| +1120 | 值块 | complete_tooltip 值 (token 键值; 配 +1467 旗) |
| +1296 | 效果块 | **bypass_effect** (token 12932) — 旁路完成时执行 (替代 completion_reward) |
| +1384 | fixed×1e-5 | **cost** (token 10323) — 完成阈值基数 |
| +1392 | — | prerequisite (token 13243 直证); vector\<CNationalFocusDependency*\> (0x38 元; 备选向量 {d@+8, c@+20}) |
| +1416 | — | mutually_exclusive (token 13242 定案: 名直证 + vtable[9] 全链 + sub_1402CFE50 + ExclusiveItem 四证); **计数@+1428** (旁路门输入) |
| +1440 | 16B POD 向量 | **前置反向依赖 (dependents) 表** {CNationalFocus* 依赖方, u8 备选旗, pad} (容器 {d@1440, cap@1448, c@1452, alloc@1456}; nationalfocus.cpp:2472 逐字节) (写入 = 依赖解析 Finalize sub_1402D4D90, 断言 "Couldn't find dependency" nationalfocus.cpp:2472 直证; 消费 = CompleteFocus sub_1402CD590 → §4.3.14 fp+120 候选增量; 互斥真身 = +1416 组指针表不变) |
| +1464 | uint8 | historical 徽标门 (死门, 见下 ⚠) |
| +1465 | uint8 | **cancel_if_invalid** (token 13669; 死吞 — ctor 1 → available 失败即取消恒开) |
| +1466 | uint8 | **continue_if_invalid** (token 13895; 死吞 — ctor 0 → 恒关) |
| +1467 | — | complete_tooltip (token 13748; 活) |
| +1468 | uint8 | available_if_capitulated (死门, 见下 ⚠) |
| +1469 | uint8 | **cancelable** (token 14256; 解析死吞 — ctor 1; 收窄: 解析层确不写, 但 def 解析后验证器 sub_1402D5500 有运行期清零写者 `def+964 非零 → +1469 = 0`, 非绝对恒值) |
| +1470 | uint8 | 「dynamic name→Repopulate 重算名」旗 (死门, 见下 ⚠) |
| +1471 | uint8 | **bypass_if_unavailable** (token 19780; 死门, 见下 ⚠ — vtable[11] HasBypassConditions = 本旗 ‖ bypass 触发器非空, 死门下实效 = bypass 触发器非空) |
| +1472 | uint8 | **enable_automatic_bypass** (token 17903; 死吞 — ctor 1 → 自动旁路恒开) |
| +1480 | 16B POD 向量 | will_lead_to_war_with 表; 16B = 名字解析 def 引用句柄 (解析期 sub_140BB41B0 + 有效性门 sub_140BB5470, 无效名 Parse 报错; 键 13828 分支直证); **消费 = 完成时 sub_1402CDDE0 写 politics+856 标记表 (kind 9=自身/10=目标, 值 = max(WILL_LEAD_TO_WAR_FOCUS_PERSISTENCE dword_143336AC0, 旧值) 倒计时) — 非发事件** (§4.3.15a) |
| +1504 | 值块 | search_filters (token 19320) |
| +1528 | MSVC SSO | (vtable[3] Parse 写) |
| +1560 | — | 源行号 (vtable[3] Parse 写) |

旗簇 ctor 默认值 (def+1464..+1473): {0,1,0,0, 0,1,0,0, 1,0}。

⚠ 死门机制 (机器码级定案): dynamic / historical / available_if_capitulated / continue_if_invalid / internal / cancel_if_invalid / enable_automatic_bypass / cancelable **八 token** 被解析器尾跳 `jmp sub_1424C0C00` 空吞 (第二实参弃置), 无写回 — def+1464 historical 徽标门 (token 12322) / +1465 cancel_if_invalid (13669) / +1466 continue_if_invalid (13895) / +1468 available_if_capitulated (14011) / +1469 cancelable (14256) / +1470 dynamic 重算名旗 (13075) / +1471 bypass_if_unavailable (19780) / +1472 enable_automatic_bypass (17903) / CFocusInlayWindow def+208 internal (11380; ⚠ +208 运行时身份 = visible= 已解析旗 — Update 可见门实判 def+120 CAndTrigger Evaluate ∧ 查看国一致, 死的仅是 internal= token 的解析写回) / CJoint+1656 内部旗 均死。⚠ 行为性结论: mods 依赖 historical= / available_if_capitulated= / dynamic= / cancelable= / bypass_if_unavailable= 的效果在解析层不生效; cancel_if_invalid 恒 1 (available 失败即取消焦点)、enable_automatic_bypass 恒 1 (自动旁路恒开)、bypass_if_unavailable 恒 0 (自动旁路须显式 bypass_conditions)。

CNationalFocus def vtable (15 槽全图, 已点名槽):

| 槽 | 函数/语义 |
|---|---|
| vtable[3] | Parse (写 +1528 SSO / +1560 源行号) |
| vtable[4] | 成员解析 sub_1402D7AC0 (token→偏移全图即上表) |
| vtable[9] | 可开始 (含 sub_1402CFE50 = 可开始 ∧ 与在研不互斥) |
| vtable[10] | **ExecuteCompletionReward sub_1402CF740** (建 ctx → sub_1402DB1F0 播 RNG → 执行 def+1032; CJoint 覆写 sub_140DF5000 先基类链再 def+1664) |
| vtable[11] | `+1471‖bypass 触发器非空` |
| vtable[12] | ShouldBypass (共享实例自动绕过; sub_1402DB420 带域封装) |
| vtable[14] (112) | 联合谓词 (基 ret0; CJointNationalFocus const-true) |

CJointNationalFocus (size 0x730, token joint_focus=14390; 工厂 sub_1402D83B0 malloc 0x730; 解析覆写 sub_140DF67F0):

| 偏移 | 名称/语义 |
|---|---|
| +1568 | 触发器 |
| +1664 | **completion_reward_joint_originator** (token 14396) — originator 侧完成奖励 |
| +1752 | **completion_reward_joint_member** (token 19639) — 成员国侧 (≠originator 时经 sub_140DF6AB0: 执行本块 + def+1032 + sub_1406E4B50 在成员 fp 记录完成) |

GetWorkingCountry = sub_140DF65C0 (逐国 fp+16==def 反查); 工厂 sub_1402D83B0 (shared_focus=14364→CNationalFocus / joint_focus=14390→CJoint)。

CContinuousNationalFocus def (成员解析 sub_1406C3310; fp+24 current_continuous 的 def 对象; 定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +160 | 值块 | ai_will_do (token 10819) |
| +216 | 匿名结构 (NNB 形状) 向量 | **available** (token 12264) |
| +304 | 匿名结构 (NNB 形状) 向量 | **enable** (token 10376/705) |
| +392 | — | idea (token 10491) |
| +400 | 效果块 | **daily_reward** (token 14046); 计数@+420 |
| +488 | 效果块 | **select_effect** (token 13244) |
| +576 | 效果块 | **cancel_effect** (token 11449) |
| +856 | fixed×1e-5 | **daily_cost** (token 13318) — 连续焦点 PP 日费基数 (§4.3.15a) |
| +864 | — | supports_ai_strategy (token 14052) |
| +868 | — | available_if_capitulated (token 14011; 死吞) |

CNationalFocusTree (ctor sub_1402CBA60; **sizeof = 360** — malloc @case 13240 focus_tree 直证; ctor 逐段与书记吻合):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | MSVC 串 32B | 树名 |
| +40..+43 | uint32 | 树名 FNV-1a (高置信推定 — continuousfocus 域同构直证: palette +40 = id 名 FNV-1a, sub_1406C2E30 case 11; 树侧 reader 0x1402D8CB0 直证待做) |
| +44..+47 | — | 未决 (原 8B 残余拆分后余段) |
| +48 | 指针向量 | 已注册焦点 def 指针向量 {d@+48, c@+60} (注册器 sub_1402CDC70 线性查重 + push) |
| +72..+103 | CPdxRobinHoodTable | **FNV-1a 名字→focus def 查找表** (表头 @+72, 插入器 sub_1402C5BC0 于 a1+72 直证, 碰撞报错 nationalfocus.cpp:308; 桶 48B, mask=(1<<k)−1 / extra=k+2 / lf 0.9 — pdx_robin_hood_table.h:579 直证; 活证全中) |
| +104 | 32B MSVC 串向量 | 串表 (pdx 向量 {d@104, cap@112, c@116, alloc@120} 持 32B MSVC 串元素, 32B 步进) |
| +128 | 指针表 | 快捷条指针表 {d@+128, c@+140} (元素为指针, 目标 +40 cap 串名 +184 byte 解析成功清 0; 布局器逐元树内查名, 未命中报 "Attempting to find a focus for shortcut that doesn't exist in tree!") |
| +152 | CFocusInlayWindowInstance 向量 | inlay 实例表 (56B 元 = CFocusInlayWindowInstance 内联, 下表) |
| +176 | — | CNationalFocusPosition (token 19276 initial_show_position) |
| +256 | MSVC SSO | 替代树名 (+272 = size 作门) |
| +288 | uint8 | **default 树旗** (默认树 getter 取旗≠0 的树, 多默认取最后一个并警告 nationalfocus.cpp:1439) |
| +296 | 值块 | country (token 10394) |
| +352 | 指针 | continuous_focus_position (token 14173) 解析产物 (32B 堆对象; Reader 0x1402D8CB0 case 14173 → sub_1402C7E70 malloc(0x20)×N Parse 期写入 — 定案; 活体非零 0x51500000234 即堆指针形态, 属正常态) |

CFocusInlayWindowInstance (56B 内联元):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable |  |
| +8 | uint32 | =357 类登记 id |
| +16 | {x,y} | position |
| +24 | def* | CFocusInlayWindow def |
| +32 | CPositionOverride 向量 | CPositionOverride 表 {104B 元: +8 x / +12 y / +16 CAndTrigger} |

token id/position/override_position = 11/76/10242 定案; 存档与树文件共用同一 vtable[4] 链。

CFocusInlayWindow def = 216B 数据库项 (TGameItemDatabase; 单例 qword_14332EFD0; 目录 common/focus_inlay_windows):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | — | id |
| +16 | NInlayWindowScript::SIcon 向量 | scripted_images 表 — 64B 元, 元素类 vftable 直证 (SIconReader 解析); 容器归属定案: ctor sub_140A6C410 三容器基址; db = TGameItemDatabase<CFocusInlayWindowDatabase>; 字段布局待裁 — 定案 |
| +40 | NInlayWindowScript::SButton 向量 | buttons 表 — 元素 {vtable@0, u32@8, u32@12, CAndTrigger 88B@16, 块@104..+191} — 定案 |
| +64 | NInlayWindowScript::SProgressbar (248B 元) 向量 | progressbars 表 — 元素 {vtable@0, 数据@8..+39, CScopedVariable@40, token 19479 "undefined" 默认@92/96, SSO@152, SSO@216} — 定案 |
| +88 | MSVC SSO | window_name |
| +120 | CAndTrigger (88B) | visible |
| +208 | — | 本国可见门 (internal; 死门, 见上 ⚠) |

token 全图 16520/10233/10275/14957/11562 定案; 每条目 push 104B CFocusInlayWindowView (池 win+1448 {c@1460}), Setup 建 `<def+88名>_instance`。

#### 4.3.15a 焦点日进度执行链

日推进挂点 = CCountry::DailyUpdate (sub_1406E76A0) 在 politics (cc+3976) 之后、
logistics (cc+3992) 之前调 **sub_1402D0260(fp)** (fp = *(cc+4992) CFocusStatus),
profiler 域 "nationalfocus.daily"。

主日函数 sub_1402D0260 四分支与完成链:

| 步 | 函数/内联 | 语义 | 置信 |
|---|---|---|---|
| 每日点数 | sub_1406DADA0 | GetDailyFocusProgress: at_war (sub_140D3FD60: politics+164 战争计数≠0) ? FOCUS_PROGRESS_WAR (qword_1433352D8) : FOCUS_PROGRESS_PEACE (qword_143335230), 两 define 均默认 1.0; **无修正链** (country modifier 不作用焦点速度); debug Focus.AutoComplete (byte_14332F62C) ∧ 玩家 tag → ×10 | 定案 |
| 闲置蓄能 | (内联 else) | fp+16==0 ∧ fp+24==0: fp+56 += 点数, clamp [0, MAX_SAVED_FOCUS_PROGRESS (qword_143335368 = 10.0)]; fp+176=1 | 定案 |
| 暂停位 | (内联) | fp+176 = !def+1466 ∧ !Focus.NoChecks (byte_14332F631) ∧ !trig(def+448 available); 实际因取消门 (+1465 恒 1) 先触发, 暂停位主要由「无激活焦点」置位 | 定案 |
| 失效取消 | sub_1402CEBB0(fp,0) | 硬取消 (fp+56=0 无退款): 门 = (def+820∧trig(def+800 cancel)) ∨ (def+1465∧def+468∧!trig(def+448)) ∨ (投降∧!def+1468) | 定案 |
| 完成判定 | (内联) | fp+56 ≥ def+1384 (cost) − 100000×减免; 减免 = sub_1402C7460(cc+5008, def+24 名) 在 CReducedFocusCost RH 按焦点名查 i32 百分数 (桶 48B, 布局 §4.3.15b) | 定案 |
| 完成派发 | sub_1402CF380 | ①sub_1402CD590 记录 (fp+32 shine 移除 + fp+64 completed push + fp+88 RH 插 + joint→fp+144 originator 插 + fp+120 候选移除 + dependents 增量解锁 + 玩家 tag 国史 sub_140207B50; "Trying to add null focus" nationalfocus.cpp:2229) ②sub_1402CDDE0 战争预警 (def+1480 逐名 → sub_140D34410(politics, tag, kind, …) 写 politics+856 标记表 12B {tag,kind,倒计时}, kind 9=自身/10=目标, 值 = max(WILL_LEAD_TO_WAR_FOCUS_PERSISTENCE, 旧值)) ③**def vtable[10]** 执行 def+1032 completion_reward (RNG 播种 sub_1402DB1F0 = def+88 id + gs 随机态双 hash → ctx) ④玩家通知 ⑤清 current + fp+56=0 | 定案 |
| 旁路完成 | sub_1402CE7F0 | 记录 + 预警 + 清 current + **执行 def+1296 bypass_effect** (非 completion_reward) + 通知; 扫描门 = vtable[11] HasBypassConditions ∧ (==current ∨ vtable[9] CanStart) ∧ def+1472 (恒 1) ∧ vtable[12] ShouldBypass ∧ (==current ∨ def+1428 互斥计数≤0) | 定案 |
| 连续焦点 | (内联) | fp+24≠0: 取消门 (!def+868 ∧ politics+736 投降) ∨ !trig(def+304 enable) ∨ !trig(def+216 available) → sub_140711430(cc,0); 否则 def+420 非空 → 执行 def+400 **daily_reward** | 定案 |

选择/取消链 (定案): **SetCurrentFocus sub_1402DAE20** = fp+16=new、fp+24=0 (连续让位)、
fp+56 保留; new≠0: fp+176=0 + **PP 扣费 −(进度×GetFocusPPCost)** + 执行 def+944
select_effect + 通知 id 12; AutoComplete∧玩家 tag → fp+56 直接置 cost−减免 当日完成。
**GetFocusPPCost sub_1406F2F70** = 修正键 38 (MODIFIER_POLITICAL_POWER_COST) ×
(fp+24 连续? def+856 daily_cost : 100000) / 1e5 (GUI 键 "focus_cost")。
**CancelCurrentFocus sub_1402CEBB0(fp, keep)**: keep=1 (玩家取消命令
CCancelFocusCommand sub_141156920) → **PP 退款 +=(进度×cost)**; keep=0 → fp+56=0;
清 will_lead_to_war 标记 (sub_140D42820)。**进度跨选择保留 + PP 反向对冲 (escrow)**
(机器码定案)。SelectFocus sub_140711660 (country.cpp:13030) / SelectContinuousFocus
sub_140711430 (country.cpp:13082) / SetContinuousFocus sub_1402DACA0 (fp+24=def +
def 侧工作国表注册 sub_1406C2B40/C2BE0)。uncomplete_national_focus =
sub_1402DBDF0 (摘完成 + current 依赖被摘时取消)。

效果块执行约定 (本域实证): 效果块 (def+944/+1032/+1296/+400/+488/+576/+1664/+1752)
= `(块 vtable 槽12)(块基址, ctx)`; 触发器容器 (def+448/+712/+800/+216/+304) =
`(容器 vtable 槽3)(容器基址, ctx)`; ctx = sub_140535110 + sub_14053A610(ctx, tag, 1)
构造, 执行前过 sub_1402DB1F0 播种。

CContinuousNationalFocus def 布局 (成员解析 sub_1406C3310 全表) = §4.3.15。

debug 旗族: byte_14332F62C = Focus.AutoComplete / byte_14332F630 =
Focus.IgnorePrerequisites / byte_14332F631 = Focus.NoChecks (注册串直证)。

**负定案: 无 on_focus_finished on_action** (token 表与原版 common/ 均无 on_focus*
token); CReducedFocusCost 布局 = §4.3.15b。

> F3 验算注 (46 项 PE 级复核全部一致): 上表全部数字/槽址/define 对齐。边界补充:
> ① 失效取消门前 AutoComplete ∧ 玩家 ∧ 非人机 → **先强完 (sub_140B65F80 + 通知 9) 再取消**;
> ② 完成判定后派发前有玩家门控遥测旁支 (sub_140210560, 串 "nf_unlock"/"nf_name");
> ③ at_war 在 politics+164==0 时回退扫 [politics+32, politics+44) 条目表,
> 条目+8 == token 14346 (war_relation) 亦判战争; ④ AutoComplete ×10 只作用激活焦点日加
> 路径 (内联于 sub_1402D0260), 闲置蓄能不加倍; ⑤ SetCurrentFocus 对保留的 fp+56 也做
> [0, MAX_SAVED] clamp; ⑥ AddPoliticalPower 钳位对 = POLITICAL_POWER_LOWER/UPPER_CAP
> (qword_143332860/143332918); ⑦ 挂点精序: 间谍(5544) → focus(4992) → 指挥点内联回充 →
> 经验(5512)。GUI 键 "focus_cost" = interface .gui 元素名 (数据驱动 UI, 名住脚本文件不进 exe, 非缺口); def+1472 恒 1 定案 (ctor 置 1 + 解析死吞 + 全 dump 无 focus 族写者, 16 处 +1472 碰撞写点逐一归属异类)。

#### 4.3.15b CReducedFocusCost (cc+5000 内嵌; 焦点名→i32 减免 RH 表)

CCountry 内嵌块 @cc+5000 (40B 本体; vtable 名直读; 与 fp+88/fp+152 表族同排布 —
高置信; 探针 GER load_factor=0.900; 查询 = sub_1402C7460(cc+5008, 名), §4.3.15a):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | (RTTI 名 CReducedFocusCost 直证) |
| +8 | — | 保留槽 (未初始化; ctor/reset 跳过 a1[626], 全域命中皆异类 — 高置信) |
| +16 | RH 桶数组 | buckets (默认空桶哨兵 &unk_143086920) |
| +24 | uint32 | count |
| +28 | uint32 | mask |
| +32 | uint8 | extra |
| +36 | float | load_factor = 0.9 (复位函数写 0x3F666666) |

桶条目 (48B stride):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| 元素+0 | uint32 | hash |
| 元素+4 | uint8 | dist |
| 元素+8 | MSVC SSO | key = 焦点名 (+8..+39) |
| 元素+40 | i32 | value = 减免百分数 (**有符号**: 负减免 −5 ↔ raw 0xFFFFFFFB) |

#### 4.3.15c nationalfocus.cpp 簇对账增补 (22 函数闭环; reader/装载/校验侧)

**树默认锚点** = sub_1402D41D0: 焦点 x≠0 者 (y 任意) 中取 x 最近均值者之名 → 写 tree+184。书 §4.3.14/§4.3.15a 收 writer/完成/daily 半边, 本簇补 reader/装载/校验侧 — 装载→运行管线:
def/树解析 (vtable[4] 成员解析, 树侧 = sub_1402D8CB0) → db 注册 (sub_1402CCB90 全局重名查,
"Duplicate focus name …" :1366) → 树注册 (sub_1402CDC70: tree+48 查重 push + FNV + tree+72 级联精化: 注册器对 dependents (def+1440, 16B 元 {依赖方*, u8 旗}) 递归注册 = 注册一焦点整链连带注册其依赖方; FNV 冲突告警 ("Focus %s has a hash collision…" :308) 后**照插不中止**。
RH 插) → db finalize (sub_1402D4500: 逐 def sub_1402D4930 校验[互斥对称回查 :1426 族 +
逐前置组触发 sub_1402D4D90 写 def+1440 dependents] → 逐 def sub_1402DB4F0 (簇外, 未决) →
逐树 sub_1402D5280 布局校验[+104 串表重解析 / initial_show_position :274 / shortcut 条目])
→ def 解析后验证 (sub_1402D5500: relative_position_id 缓存 +288/+292 递推 + 图标双查
:620..:666 + def+964 → 清 +1469) → 开局选树 → 存档载入重放。

**焦点数据库单例图谱** (定案): **qword_14332EF70 = CNationalFocus + CNationalFocusTree
统一数据库** (sub_14022FB90 即其 getter, s4_32 焦点族效果的 db 实为此物): +88/+100 =
def 指针数组 {d, c} / +112 = RH 名字→def 查找表 (48B 桶, def@桶+40) / +128 = 建表完成门
(==+100 计数走 RH 快路径, 否则 FNV-1a 线性扫 +88 数组) / +144/+156 = 树指针数组 {d, c}。
查名 = sub_1402D2180 两级查找。**qword_14332EE60 = CContinuousNationalFocus 库单例**
(case 14053 直证)。

**CNationalFocus::IsAllowed = sub_1402D6020** (定案, 符号串 `CNationalFocus::IsAllowed`
直证): 前置可用性谓词 — scope+8 tag → 国 → tree = country+4976; 前置组 any-of 递归
(SAnyOfNode, 每线程混合内联缓冲分配器); 带 CPdxUnorderedMap<def, EIsAllowedCacheState>
求值缓存 (24B 桶); 访问链环检测 → 一次性警告闩 byte_14332F743 "Circular dependency
detected in focus tree"。调用面 15+ = AI DecideFocus 域 / GUI 焦点树项族 / 可开始谓词
sub_1402CFF10 (vtable[9]) / 完成链 — 共用前置。控制台 "show all hidden focuses for the
player nation" 切换旗 **byte_14332F638** 置位时 IsAllowed 直接放行 + 偏移条目 (+296)
不生效 (定案)。

**fp reader dispatch = sub_1402D89B0** (CFocusStatus 成员解析, 补 §4.3.14 writer 半边):
六 case 与 writer 六键闭环 — 11013 progress → fp+56 / 11125 current → fp+16 (sub_1402D2180
名查, 失效 :1651) / 14053 current_continuous → fp+24 (qword_14332EE60 查, 失效 :1659) /
12583 completed → sub_1402D7650 存档重放 ({TAG 可 @scope 前缀, 名} → def 查得 →
sub_1402CD590 **完整重放**, 连带 fp+88 RH / fp+144 / dependents 解锁; 失效 :1710) /
16323 activate_shine_on_focus → sub_1402C76C0 (按 def+8 id 二分查重 → 有序插 fp+32,
失效名跳过 :1640) / 13969 paused → 死吞 (非持久, 见 §4.3.14 +176 行)。

**开局选树链** (定案): 逐树评分 sub_1405520E0(tree+296 country 值块) 取最高且 >0 → 无候选
走默认树 getter sub_1402D1D90 (tree+288 旗, 多默认取最后 :1439) → 仍无取首棵树
("No default tree scripted…" :1503) → sub_140711A60 装载。单国版 sub_1402CE220 (调用点 树选择三级回退 = 逐树 sub_1405520E0(tree+296, &score, 国串) 评分取最高 >0 → 脚本默认树 → 首树+:1503 告警; tree+296 = 评分输入槽 (语义待裁)。
sub_141425810 国家建立链, 直传统一库单例) / 全国家版 sub_1402CE350 (gs+784 数组 / gs+796
计数; 另两调用点 sub_1401CC780 / sub_1401E0E30 = 启动 setup 区, 触发时机推定)。

调试面: `-dumpdb` 启动选项旗 **byte_14332F73C** → db finalize 追加 "==== FOCUS IDs ===="
逐 def id 落盘 (定案)。GUI 图标求值 sub_1402D0CB0 (备用/主图标 case 选择 → GFX 名,
fallback "GFX_goal_unknown"; 断言三闩 :1202/:1210/:1216)。相对位置惰性求值 sub_1402D2750
(递归 + 环检测; 公式见 def +288 行注)。消歧: sub_1402D5F00 (position 解析互斥校验 :97,
解析器上下文) ≠ sub_1402D5F60 (fp+120 有序插入, §4.3.14 所引) — 两函数并存。

未决: def+964 语义; def+296 偏移条目容器语义 (门 dword@+36); sub_1402DB4F0 身份;
sub_1402D22C0(tree) 单参形态语义; tree+40..+47 8B 残余; gs+2617 与 UI 窗口槽 13 门链
(推定 = 焦点树界面打开态)。

#### 4.3.16 country.fuel_status (fs = rp(cc+5504), vtable 0X298B3A8; ctor 0X1410F0AF0 / 小时结算 0X1410F71B0 / writer 0X1410F8710 / reader 0X1410F7790 / 条目 0X1410F8650 / 列表 0X1410F09F0)

| 字段 | 量纲 | 偏移 (fs) | 备注 |
|---|---|---|---|
| fuel | Q15 | +8 | writer %.5f 定宽; setter sub_1410F7F50 (直赋+钳位 [0,max], 钳位门 = gs 在 ∧ byte[gs+2617]≠0); 比值 getter sub_1410F3570 = (fuel≪15)/max (max≤0→0) |
| max_fuel | Q15 | +16 | writer %.5f 定宽; 公式见下修正重算表 |
| fuel_gain | fix5 | +24 | AE590 族, writer 去尾零 |
| fuel_gain_from_states | fix5 | +32 | AE590 族, writer 去尾零 |
| fuel_gain_from_lend_lease | Q15 | +40 | 对象层 fuel 字段已按 Q15 口径; 每小时 = Σ租借收入条 (sub_140CA7C70, ccr+1904 容器) |
| fuel_consumption_from_lend_lease | Q15 | +48 | 同上; 每小时 = Σ租借支出条 (sub_140CB56B0, ccr+1880 容器) |
| fuel_cost | fix5 | +56 | AE590 族, writer 去尾零 |
| fuel_gain_per_oil | fix5 | +64 | AE590 族, writer 去尾零 |
| fuel_consumer_data (15127) | fix5 | data@+72, cap@+80, count@+84 | 24B 条 {priority u32@0, requested fix5@+8, received fix5@+16}; **恒 3 条 = 类别固定槽** (域表见下); loader 键对位: priority (键 141) / received 15130 / requested 15132 |
| history 哨兵条 (内联) | 混合 | +96 | 80B 同形条目内联于对象; fuel Q15@+96 / fuel_gain@+104 / consumed@+112 / other@+144 — 每小时结算累计水位 (index=−1 先写) |
| history 环形缓冲 | 混合 | 24 槽 {d@+176, cap@+184, c@+188}+80j (index=j 合成) | 80B 条: fuel Q15@0 / fuel_gain fix5@+8 / consumed Q15@+16 / requested fix5[3]@+24 / other Q15@+48 / received fix5[3]@+56; **每小时一格** (sub_1410F8130 推进, remaining_hours 恒 1) = 最近 24 小时; requested/received 固定写 3 值匿名块 → 提取键 .#1 |
| history_index (15135) | u32 | +200 | 与 +204 联作分配公平抖动种子 |
| remaining_hours (15134) | u32 | +204 | 恒 1 |
| fuel 已初始化旗 | uint8 | +208 | ctor 0; 新国初始化 sub_1406FEEB0 后置 1; 小时结算步 0 清 0 (仅首小时种子分支用) |
| 起始比率覆盖 | fix5 | +216 | ctor **−1.0** (−100000 原码); sub_1410F7700 判据 == −1.0 哨兵 → 取 define STARTING_FUEL_RATIO, 否则用本值; 写者 = sub_1410F80B0 (set_fuel_ratio) fuel<0 分支 |
| CCountry* 回指 | CCountry* | +224 | ctor sub_1410F0AF0(fs, cc) 注入 |

全部序列化字段**恒写** (零值也写, 无省略规则); history 写序 = 物理槽序 −1,0..23 (非时序旋转); 存档实证 439 国 × (10 标量 + 3 consumers + 25 history 条) = 86,483 叶全覆盖。+208/+216/+224 不序列化 (旗/运行时)。

**小时结算 sub_1410F71B0** (每活跃国每游戏小时; 调度 = CGameState::HourlyUpdate 序 11 DoCountryHourlyUpdates 阶段 4 "hourlyUpdateUnits" 串行逐国 → sub_1407164E0 → 本体; 燃料结算先于同帧战斗段 序 12):

| 步 | 动作 |
|---|---|
| 0 | 首小时种子: 若 +208 旗 → 清 0, gain 总额写入全部 24 环形条 fuel_gain 槽 |
| 1 | 修正重算 sub_1410F82C0 (下表) |
| 2 | 租借收入: fs+40 = sub_140CA7C70(ccr) |
| 3 | 增益入账: fs+8 += Q15(fs+32+fs+24 (+\|fs+56\| 若负) + (油量≤0 → 0, 否则 fs+64×油量)) + fs+40 |
| 4 | 哨兵累计: fs+96 += fs+8 (水位采样); fs+104 += 增益 |
| 5 | 国家级消耗: 若 fs+56>0: fs+8 −= Q15(fs+56); fs+112/fs+144 += 同值 |
| 6 | 租借支出: fs+8 −= v24; fs+48 = v24; fs+112/fs+144 += v24 (sub_140CB56B0; 支出受预算封顶) |
| 7 | 陆军扇出: cc+656 逐师 sub_140C78990 (写 +1576/+1568) |
| 8 | 海军扇出: cc+632 逐舰队逐 TF sub_140D68B90 (写 tf+1280, 清 tf+1272) |
| 9 | 空军扇出: 战略空军国对象两容器逐基地 sub_140C4F920: cp+240 = 0 |
| 10 | 优先级分配: 清 consumer_data 3 条 requested/received → sub_1410F3080(fs, 2/1/0) |
| 11 | 钳位: fuel = fuel<0 ? 0 : min(fuel, fs+16) |
| 12 | 史环推进 sub_1410F8130: consumer received → fs+112 (Q15) 与 requested/received 原码 → 哨兵累计 → 整 80B 推送环条 (index fs+200, 24 回绕清哨兵; 哨兵 10 字段 = requested[3]@120/128/136 + received[3]@152/160/168 + 水位/增益) |

**修正重算 sub_1410F82C0** (每小时 + ctor 尾; 修正表 = cc+1464, id 见 ref/modifier_idmap.txt):

| 字段 | 公式 |
|---|---|
| fs+16 max_fuel | (BASE_FUEL_CAPACITY + 1000×Q15(mod406 MAX_FUEL_ADD) + 1000×Q15(mod407 MAX_FUEL_ADD_FROM_STATES)) × (1+mod405 MAX_FUEL_FACTOR); <0 钳 0 |
| fs+24 fuel_gain | (BASE_FUEL_GAIN + mod408 BASE_FUEL_GAIN_ADD) × (1+mod409 BASE_FUEL_GAIN_FACTOR) |
| fs+32 fuel_gain_from_states | mod403 FUEL_GAIN_FROM_STATES × (1+mod402 FUEL_GAIN_FACTOR_FROM_STATES) |
| fs+56 fuel_cost | mod410 FUEL_COST; 观察者国 (gs 1312/1316 特殊 tag) 再减 Q15(fix5(qword_14332F658)/24) |
| fs+64 fuel_gain_per_oil | (BASE_FUEL_GAIN_PER_OIL + mod404 FUEL_GAIN_ADD) × (1+mod401 FUEL_GAIN_FACTOR); <0 钳 0 |
| 尾 | fuel = min(fuel, max_fuel) |

**consumer_data 域表** (类别固定槽, 分配按 priority 2→1→0 高先得; 稀缺时按总额比率 + 偶次 +100 公平抖动, 种子 = fs+200+fs+204):

| 槽 | 军种 | 请求采集器 (每轮门与公式) | 分配回填 |
|---|---|---|---|
| 0 | 陆军 (师) | sub_1410F1E20: 逐师, 门 = 师+46 活跃 ∨ (师+760 ∧ sub_140C00000); request = min(max_fuel(模板+288, sub_140C7F070) − fuel(+1568), ARMY_MAX_FUEL_FLOW_MULT×vtable[57]); 非移动态再乘 师+64 补给比 | sub_1410F2E70: 逐师 +1568 += grant |
| 1 | 空军 (基地国容器) | sub_1410F2030: 逐基地, cp = *(base+48)[tag], 门 = cp+30; request = min(cp+224, cp+48 补给比 × MAX_FUEL_FLOW_MULT [air 槽 0x143332C18, NAir 域 1.0] × cp+232) (供给比乘流量帽, min 之前) | sub_140C4BB10: cp+240 = grant |
| 2 | 海军 (TF) | sub_1410F2390: 逐舰队逐 TF, 门 = tf+46; request = min(tf+1280, tf+64 补给比 × MAX_FUEL_FLOW_MULT [navy 槽 0x14334690, NNaval 域 2.0] × vtable[57]) | sub_140D64740: tf+1272 += grant |

priority u32 = 玩家可设等级 (0=低 1=中 2=高, ctor=1); 写者 = CSetFuelPriorityCommand::Execute → sub_1410F80A0 (条[category]+0 = level)。

树外写者 (结算树之外):

| 路径 | 函数 | 动作 |
|---|---|---|
| 吞并 | sub_1406D3F00 | 吞并者 fs+8 += 被吞并国 fuel × ANNEX_FUEL_RATIO (+钳位) |
| 投降分油 | sub_140714170 | 战胜国 fs+8 += 份额 × capitulator.fuel × CAPITULATE_FUEL_RATIO |
| 投降清零 | sub_1406E16C0 | 投降国 fuel = 0 (sub_1410F7F50 直赋) |
| 流亡 | — | 负定案: 流亡路径无燃料触点 |

脚本面 (穷举负定案: 全库恰 5 件, 全部落国级, 不读单位级燃料):

| token | 名 | 实现 | 语义 |
|---|---|---|---|
| 15287 | has_fuel | vtable[23] sub_1403ED580 | 直读 fs+8 裸值比较 |
| 15482 | fuel_ratio | vtable[23] sub_1403ED530 = sub_1410F3570 | fuel/max |
| 15286 | add_fuel | Execute sub_1403479C0 | fs+8 += 值, 后钳位 sub_1410F2940 |
| 15288 | set_fuel | sub_1410F7F50 | 直写 |
| 15481 | set_fuel_ratio | sub_1410F80B0 | fuel≥0 → ratio × fs+16 后写; fuel<0 → 写 +216 起始比率覆盖 |

控制台 `fuel <int>` 写全局 qword_14332F658 (fix5) — 观察者国 (tag 选择器 gs+1312>0 → 1312 否则 1316) 每小时 fs+56 fuel_cost −= fix5(Q15(global)/24) (魔数 ÷786432), **持续生效, 无倒数与期限**。

**初始化/零态**: 新国 fuel = −1 哨兵 → sub_1406FEEB0 以起始比率 × max 初始化 (+216 覆盖规则见上) + 师满油惰性初始化 (sub_140C88D30); 读档路径**无燃料重建步骤**, 增益/上限族由每小时修正重算自愈。fs+8 行为读者另见 §4.18.14 (陆军惩罚链)、§4.16 (海军)、§4.15 (空军) 与 §4.34 (AI 燃料门: sub_141A65AB0 任务预算 / sub_14130B700 燃料贸易 / sub_1406690D0 节约模式状态机, 三 define 门 0.60/30 天/0.4)。

#### 4.3.17 country.experience_status (es = rp(cc+5512), vtable 0X29A80C0)

| 字段 | 量纲 | 偏移 | 写门 |
|---|---|---|---|
| army | Q15 (i64/32768) | +16 | 仅 ≠0 写 |
| army_daily | Q15 (i64/32768) | +24 | 同上 |
| army_daily_training | Q15 (i64/32768) | +32 | 同上 |
| navy | Q15 (i64/32768) | +40 | 同上 |
| navy_daily | Q15 (i64/32768) | +48 | 同上 |
| navy_daily_training | Q15 (i64/32768) | +56 | 同上 (token 19959; writer sub_1412A92B0 + reader case + ctor 连续 Q15 槽三向) |
| air | Q15 (i64/32768) | +64 | 同上 |
| air_daily | Q15 (i64/32768) | +72 | 同上 |
| num_armies_for_training | Q15 | +80 | **恒写含 0** |
| xp_by_template.#N | — | {d@+88, c@+100} 24B 元 (vtable 0X295A5B0) | 容器 writer 0X1412A92B0 全槽迭代无跳过, **空槽也写空块 → #N 含空槽** (容器序 1 基) |
| xp_by_taskforce.#N | — | {d@+112, c@+124} 40B 元 (vtable 0X2958040) | 同上; 另 on_mission i32@+32 >0 (14668) + mission 门 byte@+28≠0 值 u32@+24 (11450) |
| xp_by_airwing.#N | — | {d@+136, c@+148} 24B 元 (vtable 0X2965260) | 同上 |

元素写门 (template 0X141961B30 / taskforce 0X141961BB0 / airwing 0X141961AB0):

| 字段 | 键 token | 写门 |
|---|---|---|
| combat | 10518 | u32@+8 ≠0 |
| training | 12218 | u32@+12 ≠0 |
| ref (division / task_force / air_wing id 对) | 471 / 15157 / 13161 | {type@+16, id@+20} 任一 ≠0 且 sub_14221F310(e+16) ∉ {0, 16} (0 = 目标已不存在, 16 = 哨兵型亦不写; KR SIC 三条失败 ref 实证) |

⚠ ref=0 槽: training 照写, 仅 division 叶省 (ref 全 0 孤儿整体不写的口径不成立)。

日更收敛步 = sub_1412A8060 (CCountry::DailyUpdate 内; 公式定案): 键 46-55 取界 lerp
收敛, 钳位字段 +16..+64; mdef 46/47、50/51、54/55 = XP_GAIN_{ARMY,NAVY,AIR}(_FACTOR);
日累计钳 FIELD_EXPERIENCE_MAX_PER_DAY ×3 / 存量钳 MAX_{ARMY,NAVY,AIR}_EXPERIENCE;
训练 XP lerp 目标 = 军队计数<<15 (ARMY_COUNT_DAILY_LERP / DECREASE_FOR_TRAINING_XP)。

#### 4.3.18 CConvoys (cc+4608; writer 0X141022CF0 + 池 writer 0X141012DB0; 池类 = **CEquipmentVariantPool** 64B, vtable 0x142749270, reader 0x1410113B0)

equipment 池 @+16 (cvp = cc+4624):

| 项 | 偏移/类型 | 名称/语义 | 写门 |
|---|---|---|---|
| 池头 | cvp+32 / +40 / +44 / +56 | {data@cvp+32, cap@cvp+40, count@cvp+44, allow_zero u8@cvp+56} |  |
| 条目 | 16B | {variant ptr@0, amount i64×1e-5@+8}; variant: id u32@+12 / type u32@+8 | **amount (raw i64) ≠0 ∨ allow_zero≠0** (writer 0X141012DB0 定案; 0X141022CF0 本体 = 单发 ADEC0(0x2F4E, cv+16) 内嵌池块; variant 非空仍是 id 对解引用前提) |
| allow_zero_entries | 0x27E0 |  | 恒写 |

存档文档序: equipment 条目 (重复键 [N]) → allow_zero_entries。

B15 GUI 消费:

| 消费点 | 字段/偏移 | 用途 |
|---|---|---|
| 空闲船队 | cc+4608 (sub_141021C20) | 贸易 convoys_description 需 vs 有; × route+40 占用 |
| 市场库存行可投放量 | cc+4624 池 / cc+4716 / cc+4728+4736 缓存 | 换算源 (variant+1032 bit0 分支; sub_1413BAC30); 即 cc+4608 第二容器 (§4.3) 的 UI 消费侧直证 — **第二容器形态定案 = cc+4688 起 8B 指针数组** {data@+4688, count@+4700} (消费点 sub_140DAB4C0 逐元素 scopedptr 解引用 + `_pPtr` 非空断言); 元素类名未取到 (无 vftable 字面量锚) |

#### 4.3.18a CEquipmentVariantPool 读侧两形态 (equipmentpool.cpp; reader 0x1410113B0 / 创建块解析器 0x141011680 / 重装器 0x14100E730)

reader 键分发表 (a1 = 池 this, a2 = 解析器上下文, a3 = 键 token):

| 键 token | 名 | 分发 | 落点 |
|---|---|---|---|
| 10208 | allow_zero_entries | u8 读 | 池 +56 |
| 12110 | equipment | 内块循环 | 经入池原语 0x141012230 |
| 其他 (装备类型 token) | <类型名> | 创建块解析器 0x141011680 (尾调) | 类型化创建块 |

两形态: 12110 内块 = **落盘形** `equipment={ id=<id 对> amount=<fixed×1e-5> }`, 直接引用既有变体; 其他装备类型键 = **创建形** `<类型名>={ creator=… owner=… version=… version_name=… amount=… create_if_missing=… }`, 按创建者国家 + 版本名/版本号现场创建变体。两路最终都经同一入池原语 0x141012230; writer 只发落盘形, 创建形为纯解析通道不落盘。

12110 内块 (循环至块尾):

| 键 token | 名 | 读法 | 语义 |
|---|---|---|---|
| 11 | id | 8B id 对 | 变体引用; 块尾经解析器取变体指针 |
| 417 | amount | i64 fixed×1e-5 | 数量, 入池第三参 |
| 其他 | — | 跳值 | — |

id 对三段式注册表 (按 id 对首 u32 分流):

| 首 u32 区间 | 注册表全局 | 语义 |
|---|---|---|
| > 4904 | qword_143451DB0 | mod 扩展装备注册表 |
| 100 | qword_143451DB8 | 中段注册表 |
| < 100 | qword_143451DC0[id] | 原版装备类型数组 |

> 延迟引用门: 解析器 a2+296 引用解析上下文的 +8/+9 双旗**不同时置位** → 立即解析; 否则保持零 id 对哨兵 qword_14333D528, 块尾走 :75 一次性断言 (双旗语义未闭合, 待裁)。注册表条目经查表命中取 +0 指针 = 变体指针, 未命中返 0。

创建形六键 (全部解析器局部量):

| 键 token | 名 | 局部 | 语义 |
|---|---|---|---|
| 12397 | creator | i32 | 创建者国家 id (tag→国家对象→id 链); ≤0 时整块退基类 |
| 10302 | owner | i32 | 拥有者国家 id; creator 缺失/无效时兜底为 owner |
| 12444 | create_if_missing | u8 | 创建失败时是否走库存兜底 |
| 13788 | version_name | SSO 串 | 命名变体路径 |
| 238 | version | u8 | 版本号 (命名路径不用) |
| 417 | amount | i64 fixed | 入池数量, 缺省 100000 (1.0) |

> 变体创建双入口: 有版本名 → 按名创建/查找; 无版本名 → 按 u8 版本号创建/查找。失败两路: create_if_missing 置位 → 库存任意变体兜底 (取该类型任意可用变体), 再失败 → 日志「<类型名> is not valid for creation, are you sure it is buildable?」; 无兜底 → 日志「Country "<创建者>" does not have any equipment variant for type "<类型名>" version <版本号> created by "<创建者>"」(均 CLogStream 通道 65540, 无中断)。入口门 = 装备类型定义 +16 支持变体创建旗。

师装备池重装链 (CArmy::[8] 载入重建零态内): 池空判定 (pool1 count@+20 ≤0, 否则逐元查 +16 有效位) → 模板非空 → 构建模板装备需求表 (临时向量 {data@+8, count@+20}, 16B 元 {变体指针@+0, 需求量 i64@+8}) → 强制计数门施加 → sub_14100E730(池, 国家仓库 ps, 需求表, 强制池)。

sub_14100E730 内部三步:

| 步 | 行为 |
|---|---|
| 1 清空 | pool1/pool2 计数归零 (双池同步) |
| 2 指纹匹配 | 逐需求条扫强制池 (stride 16), 以原型 id u32 (变体+1048, 或变体→类型→原型三级链) 匹配; 命中取强制池变体与其量; 未命中 → 国家仓库查该类型变体; 仍空 → 日志「Trying to fill variant where none exist from type: <类型名> belonging to <国家名>」并跳过 |
| 3 覆盖量门 | 强制池条目量 ≤1.0 或未命中 → 入池量 = 模板需求量; 否则 → 入池量 = 强制池量 (覆盖模板需求) |

> 入池原语双池同步: 排序键 = 变体→类型→原型 +1048 的原型 id u32; pool1 (24B 元) 按键升序定位插入点; pool2 (data@+32, 16B 元 {变体指针@+0, amount i64@+8}) 同步追加。

#### 4.3.19 CStrategicAI 标量簇 (csa = rp(rp(cc+552)+2800)+2800; writer 0X14066B3F0 = `sub_14066B3F0`)

> **AI 是否处理该国的总门 = 全局静态旗** (非 gs、非 cc 字段):
> `byte_14332F639` — 20+ 处以 `if (sub_140700750(cc) && !byte_14332F639)`
> 形式出现, 语义 = "**人控国就跳过 AI 处理**"。置 1 ⇒ AI 也经营人控国
> (启动参数 `-human_ai` / 控制台 `human_ai`; 后者是 **toggle**)。
> 相关: `byte_14332F63C` = AI 总闸 (启动参数 `-noai` 清 0, `-human_ai` 亦清 0) /
> `byte_14332F63D` = ai_view / `byte_14332F640` = ai_realism;
> **单国 AI 开/关 = 禁用名单容器** (qword_14332F668 体系, toggle 语义),
> 控制台 `ai TAG` 原生支持 — 全链定案见 §4.34.7。
> ⚠ 玩家国默认不走 AI ⇒ 玩家不动的存档看不到本表多数字段被刷新;
> 要覆盖 AI 独占写门须开 `-human_ai` 并推进时钟。

| 字段 | 偏移 (csa) | 备注 |
|---|---|---|
| days_to_need_update | +5696 (u32) | writer token 0x3485 |
| days_until_next_rebuild_access_list | +5700 (u32) | writer token 0x3483 |
| seed | +5936 | 存档形 "<u32@+5940> <u32@+5936>" 之次 (**存档序反**, writer 10647) |
| seed | +5940 | 存档形 "<u32@+5940> <u32@+5936>" 之首 (**存档序反**, writer 10647) |
| irrationality | +5960 (i32 有符号) | 0x3599; 337 国 =−1 |
| pp_spend_priority | +6096 (u32) | 0x37F2 |
| pp_spend_amount.#1 | +6104 / +6112 (fix5×2 合成一叶) | 0x3A44 |
| num_wanted_divisions | +6132 (i32 有符号) | 0x3D78 |
| ai_strategy A 数组 (0x3100) / persistent_strategy B 数组 (0x3A32) | A: data@+144+24i, count@+156+24i / B: data@+2832+24i, count@+2844+24i | 双平行 112 槽, 12B 条 {value i32, target u32, id u32}; id 仅槽 9/16/21 写 token 名; persistent 非 "value<0 子集" (csa+5520 = allowed_strategy_plans; 对象层 ai_strategy 族已按此口径) |
| military_access | +5808 | 440×u32 (n = gs+796 含 idx0 哨兵) |
| allowed_strategy_plans | {d@+5520, c@+5532} 40B MSVC SSO 元 | count>0 才写 |
| recently_invaded_areas[N] | {d@+5544, c@+5556} 64B 元 (writer 0x3CDE) | 定案 |
| 五容器族 | failed_naval_invasions {d@+5568, c@+5580} 64B 元 / raids {d@+5592, c@+5604} 80B 元 / force_concentration_target {d@+5624, c@+5636} 24B 元 / expeditionary_force_data {d@+6160, c@+6172, alloc@+6176} 48B 元 / port_strike_history 表 32B @+6184 | 元素字段见下表; 块键 token = writer sub_14066B3F0 逐容器 sub_1424C2E20 调用定案: +5568→19828 / +5592→19184 / +5624→11171 / +6160→15433 / 表体+6184→15596 (离线 token 表对证) |
| desire/reserved 簇 (13 连 fixed×1e-5) | +5704..+5800 (步进 8) | desire_unlock_land/naval/air_doctrine (+5704/5712/5720) / desire_update_land_template (+5728) / desire_upgrade_land/naval/air_equipment (+5736/5744/5752) / reserved_xp_land/naval/air_research (+5760/5768/5776) / desire_unlock_army/navy/air_spirit (+5784/5792/5800); writer sub_1424C34F0 逐槽, 键序与偏移序不齐 (19812-19819 / 15795-15797 / 19801-19803 区段) |

五容器族元素字段 (块门 = 各 count>0; 元素发射 = writer 逐容器调元素 vtable 序列化):

| 容器 (块键) | 元素+N | 类型 | 字段/语义 | 写门 |
|---|---|---|---|---|
| force_concentration_target (11171) | +8 | u32 | target | 恒写 |
| force_concentration_target (11171) | +12 | u32 | from | 恒写 |
| force_concentration_target (11171) | +16 | i64 fixed×1e-5 | progress | 恒写 |
| expeditionary_force_data (15433) | +8 | u32 | tag (国 idx → 引号串) | 恒写 |
| expeditionary_force_data (15433) | +12 | u32 | casualties | 恒写 |
| expeditionary_force_data (15433) | +16 | u8 | do_not_send_forces (yes/no) | 恒写 |
| expeditionary_force_data (15433) | +17 | u8 | pull_forces_back (yes/no) | 恒写 |
| expeditionary_force_data (15433) | +32 | CGameDate {hours@+32, vtable2@+40} | date | hours≠43808760 |
| raids (19184) | +8 | u32 token | type (token 名, 裸) | 名非空才发 |
| raids (19184) | +16 | SRaidTarget 块 | building ptr@+0 → template token@*(bld+480)+8 裸 / location u32@*(bld+472)+108; province ptr@+8 → +164; state ptr@+16 → +88; leader id 对 {type@+24, id@+28}; leader_province ptr@+32 → +164 | 块恒写; leader (ty\|id)≠0 |
| raids (19184) | +64 | CGameDate {hours@+64, vtable2@+72} | end_date | 恒写 |
| failed_naval_invasions (19828) | +8 | CProvince* | province = u32@*(el+8)+164 | 恒写 |
| failed_naval_invasions (19828) | +16 | u32 列 {data@+16, count@+28} | invasion_order_ids | ptr 有效即写 |
| failed_naval_invasions (19828) | +48 | CGameDate {hours@+48, vtable2@+56} | invasion_date | 恒写 |
| port_strike_history (15596) | +8 | i64 fixed×1e-5 | damage — 按省空袭伤害累计; 生产者 sub_14065FF00 (airmission.cpp 空袭伤害路径, 门 byte MID+99) += 100000×量, 钳位全局帽 qword_1433332A8 = define MAX_PORT_STRIKE_HISTORY_TO_REMEMBER | 恒写 |
| port_strike_history (15596) | +16 | uint32 | hour — 相对小时戳 = gs 当前小时 − 43800000 | 恒写 |
| port_strike_history (15596) | +20 | uint32 | province — 省 id, 兼表键; reader 命中已有键原地覆盖三叶 (状态恢复语义) | 恒写 |

port_strike_history 表体 (csa+6184 32B) = CPdxRobinHoodTable<u32 省 id → CStrategicAI::SPortStrikeData> (元素 vtable 0x1427E1F68, 24B {vtable, damage i64 fixed×1e-5@+8, hour u32@+16, province u32@+20}; 元素 writer 0x14066BC90 / reader 走 CPersistent Load wrapper 槽); 结构字段运行时重建不序列化, 空表 = 零条目块:

| 偏移 (csa) | 表内 | 类型 | 语义 | 证据档 |
|---|---|---|---|---|
| +6184 | 表+0 | 8B | 模板前置哑成员占位 (空 functor/EBO 失效致 8B 实占, 恒不初始化 — 定案: 三实例同族对照 [CReducedFocusCost +8 / CFleet+40 RH 死槽 / 本表] 皆 ctor 不写 insert/grow/dtor 不触; 排除 vptr/分配器/水位) | 定案 |
| +6192 | 表+8 | 匿名结构 (40B 桶)* | 桶 = {hash u32@+0, DistancePlus1 u8@+4 (0xFF = 迭代哨兵), 键 province u32@+8, 元素 24B@+16}; 分配 = (桶数+maxdist+1)×40B, 末桶初始化为哨兵; 空表 = 静态哨兵 unk_143086F70 (PE 静态字节逐位验证) | 定案 |
| +6200 | 表+16 | uint32 | 元素计数 (载荷因子分子) | 定案 |
| +6204 | 表+20 | int32 | mask = 桶数−1 (扩容写 (1<<k)−1; 运行时重建) | 定案 |
| +6208 | 表+24 | uint8 | 最大探测距离 maxdist; 扩容后 = log2(桶数)+2; ctor 初值 0 | 定案 |
| +6212 | 表+28 | float32 | 最大载荷因子 0.9f (ctor 0x3F666666); 扩容门 (count+1)/mask > max_load | 定案 |

writer 0x14066B3F0 落盘序 (键 token): A/B 策略数组 112 槽交错 (每槽先 A=12544
ai_strategy 后 B=14898 persistent_strategy; 条内叶序 type 225 → id 11 → target 107
(0 跳过) → value 776) → allowed_strategy_plans 15260 → military_access 10548 →
days_until_next_rebuild_access_list 13443 → days_to_need_update 13445 → seed 10647 →
irrationality 13721 → pp_spend_priority 14322 → pp_spend_amount 14916 →
expeditionary_force_data 15433 → recently_invaded_areas 15582 → failed_naval_invasions
19828 → port_strike_history 15596 (逐条目) → raids 19184 → force_concentration_target
11171 → num_wanted_divisions 15736 → 13 fixed 叶 (19812/19813/19814/19815/19816/
19818/19819/15795/15796/15797/19801/19802/19803)。token 19817 键位 = 已删键 `wagon_last` 残留 (词法实名; writer 19816→19818 跳过无发射点 — 定案, 无偏移映射,
疑已删除键位, 未决)。

#### 4.3.20 CCountryReportsManager (crm = rp(cc+4064); vtable 0x1429D10A8)

country_reports 节点 61 叶**全部恒写** (439 国 0 值照写; writer 无条件写)。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +16 | uint32 向量 | log 向量数据 — SDailyEntry 32B = 8×u32; 存档编码: 逐记录 "k v1..vk" (k = 最末非零槽 1 基), 全零记录只写 "0", 拼接单 token 流行 → `log.#1` (每国恰一块) | 恒写 (writer 无条件开闭块) |
| +24 | uint32 | log 容器 cap | |
| +28 | uint32 | log 容器计数 | |
| +32 | 匿名结构 (NNB 形状)* | log 容器 alloc | ctor |
| +40 | uint32 | days (tok 10605) — 读档丢弃族, mem 运行时重算 (GER=4) | 恒写 |
| +44 | uint32 | index (tok 524) — 同上 (GER=39 = 末条下标) | 恒写 |
| +48 | CGameDate vtable | **date 数据对象 vtable** (内嵌 CGameDate@+48, hours@+56) | ctor |
| +56 | uint32 | date hours (内嵌 CGameDate@+64) — 休眠国哨兵 43808760 **照发** "1.1.1.1" (存档 337 国实证; 不用 SL.date 哨兵抑制版, 段内自算) | 恒写 |
| +64 | CGameDate vtable | **date 序列化代理 vtable** (ADEC0 规则: hours = 代理−8 = +56) | ctor + writer ADEC0(0x284A, a1+64) |
| +72 | NCountryStatTracking::CConstructedBuildingsTracker* | construction 容器数据 (0x28 对象: {vtable, data@+8, cap@+16, count@+20, alloc@+24, owner@+32}; RTTI 名直现) (writer 0X141C32D50: for i=0..18 恒写, 值 = *(*(obj+8)+4i) 纯 u32; 查不到默认 0) | 恒写 19 键; token 序 = CR_CONSTR 序 = 存档文档序 |
| +80 | 匿名结构 (16B 形状) 向量 | equipment_production 容器数据 (同族 0x28 tracker 对象, sub_141C33350) — 元素 stride16 {mask u64@+0, 值 i64×1e-5@+8}, 数组按 mask 升序 (writer 内 0X141C338A0 二分查找佐证); writer 0X141C34270 逐个 if(popcount(mask)<=1) 恒真 → 38 键恒写, 查不到 mask 默认 0 | 恒写 38 键 |

construction 19 键序 (CR_CONSTR; token 序 = 存档文档序):

| 序 | 键名 |
|---|---|
| 1 | civilian_factory |
| 2 | military_factory |
| 3 | dockyard |
| 4 | port |
| 5 | infrastructure |
| 6 | air_base |
| 7 | rocket_site |
| 8 | gun_emplacement |
| 9 | radar |
| 10 | anti_air |
| 11 | refinery |
| 12 | fuel_silo |
| 13 | supply_node |
| 14 | nuclear_reactor |
| 15 | land_fort |
| 16 | naval_fort |
| 17 | naval_headquarter |
| 18 | naval_supply_hub |
| 19 | other |

equipment_production 38 键 (mask→键名; writer (mask,token) 对序 = 存档文档序; 23 位标定全吻合, 余 15 键已补齐):

| 键名 | mask |
|---|---|
| convoy | 0x1 |
| train | 0x80000000 |
| floating_harbor | 0x200 |
| railway_gun | 0x80000 |
| armor | 0x4 |
| land_cruiser | 0x4000000000 |
| motorized | 0x8 |
| mechanized | 0x10 |
| infantry | 0x20 |
| capital_ship | 0x40 |
| submarine | 0x80 |
| screen_ship | 0x100 |
| support_ship | 0x8000000000 |
| fighter | 0x400 |
| heavy_fighter | 0x100000000 |
| interceptor | 0x800 |
| tactical_bomber | 0x1000 |
| strategic_bomber | 0x2000 |
| cas | 0x4000 |
| naval_bomber | 0x8000 |
| missile | 0x10000 |
| emplacement_gun_ammo | 0x200000000 |
| ballistic_missile | 0x400000000 |
| nuclear_missile | 0x800000000 |
| sam_missile | 0x1000000000 |
| suicide | 0x20000 |
| scout_plane | 0x40000 |
| maritime_patrol_plane | 0x200000 |
| air_transport | 0x100000 |
| carrier | 0x400000 |
| missile_launcher | 0x2000000000 |
| support | 0x1000000 |
| amphibious | 0x4000000 |
| anti_air | 0x8000000 |
| artillery | 0x10000000 |
| anti_tank | 0x20000000 |
| rocket | 0x40000000 |
| flame | 0x2000000 |

**log 空形态段可发射 = 空块 `log={}`**: writer sub_1414FB590 结构为 `sub_1424C4220(a2, 10676)` 写键 → `sub_1424C4410(a2)` **无条件开块** → 记录循环 (count==0 时零次) → `sub_1424C3A20(a2)` **无条件闭块**; 故「无样本故不发射」的顾虑不成立, 段可按 `log.#1` 空块发射。

#### 4.3.21 power_balance (CPowerBalanceSystem / CPowerBalance / CPowerBalanceSide; 按国家索引)

sys = **CPowerBalanceSystem\* = *(gs+1104)***; vtable 0X296FCA0; 容器 {data@+8, count@+20};
400B 条目 = CPowerBalance (vtable 0X296FC50 RTTI 直证; ctor 0X140E54DD0);
writers 0X140E58E30 (容器) / 0X140E58C50 (元素)。

CPowerBalance 主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CPowerBalance | 不序列化 | |
| +8 | uint8 | 有效位标志 | 不序列化 | ctor = 1 |
| +16 | CPowerBalanceDatabase 条目* | template | 恒写 | def 对象; *(def)+16 = MSVC 引号 |
| +24 | CPowerBalanceSide* | left_side | 恒写 | ctor = null 单例 qword_14333A070; SetSides sub_140E58330 经注册表换真身 |
| +32 | CPowerBalanceSide* | right_side | 恒写 | |
| +40 | CPowerBalanceSide* | trending_side | 恒写 | 同 template (+16) |
| +48 | fixed×1e-5 | value | 恒写 | |
| +56 | 匿名结构 (NNB 形状) 向量 24B | countries | c>0 且 idx>0 | {data@+56, cap@+64, count@+68, alloc@+72}; 元 = u32 国 idx → 引号 tag |
| +68 | uint32 | countries 计数 | c>0 且 idx>0 | |
| +80 | 匿名结构 (NNB 形状) 向量 24B | modifier | 恒写循环 | {data@+80, cap@+88, count@+92, alloc@+96}; 元 = 8B 指针 → MSVC@ptr+424 引号 |
| +92 | uint32 | modifier 计数 | 恒写循环 | |
| +104 | 匿名结构 (NNB 形状) 向量 24B | ranges 合并视图缓存 | 不序列化 | {data@+104, cap@+112, count@+116, alloc@+120}; 8B 指针 → 1856B CPowerBalanceRange; Rebuild sub_140E58950 = 左 ranges + 右 ranges + def ranges 合并排序; 连续性校验 sub_140E56190 ("gap/overlap detected") |
| +128 | 匿名结构 (NNB 形状) 向量 24B | 左侧 ranges 收集暂存 | 不序列化 | {data@+128, cap@+136, count@+140, alloc@+144}; Rebuild merge 源 |
| +152 | 匿名结构 (NNB 形状) 向量 24B | 右侧 ranges 收集暂存 | 不序列化 | {data@+152, cap@+160, count@+164, alloc@+168} |
| +176 | CPowerBalanceRange* | 当前/默认 range 缓存 | 不序列化 | |
| +184 | CModifier (内嵌 192B) | 平衡自身修正块 | 不序列化 | 运行时合成; 序列化走 +80 指针数组非本内嵌; 全布局见 §4.3.8 通用表 (分区见下方映射表) |
| +376 | 匿名结构 (NNB 形状) 向量 24B | sides | c>0 | {data@+376, cap@+384, count@+388, alloc@+392}; 80B 元素 = CPowerBalanceSideInfo (ctor 0X140E55020, 下方子表) |
| +388 | uint32 | sides 计数 | c>0 | |

注 (写入点): +176 唯一写入点 = sub_140E58770 (Rebuild 尾调): min 含 / max 排他 /
max==100000 哨兵; 区间切换时执行旧/新 range 的 on_deactivate/on_activate。
注 (读点): sub_140E55EA0 — 模式 1 = 名比对直读 +176 (range+1848 FNV ci-hash 等 + range+1816 id SSO stricmp); 非 1 扫 +104 ranges 合并视图缓存, **未命中回落 CPowerBalanceRange null 单例** (sub_140A8D660 → qword_14333A078, null_object.h:133; 与 CPowerBalanceSide null 单例 qword_14333A070 相邻同族); **467 = value < min (严格小于); 468 = value >= max ∧ max ≠ 100000** (哨兵排除, 与 +176 写点同体系)。
注: SetSides sub_140E58330 断言读侧对象 valid 与 +8 同位。

映射表: +184 CModifier 内嵌块分区 (全布局见 §4.3.8):

| 子对象+N | 名称 | 语义 |
|---|---|---|
| +64 | children | 回收池 |
| +88 | name | |
| +120 | custom_modifier_tooltip | 串集合 (表基 −8 修正) |
| +152 | hidden_modifier | mdef idx 集合 |
| +184 | pair | 接纳类别掩码 |
| +188 | data | 子级展开深度 |

元素子表: +376 sides 元素 CPowerBalanceSideInfo (80B; 皆引号):

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| +0 | vtable | CPowerBalanceSideInfo | |
| +8 | MSVC SSO 32B | id | 引号 |
| +40 | uint32 | **id 的 FNV-1a ci-hash (int32 截断)** | ctor sub_140E55020 `*(u32*)(a1+40) = *(u32*)(a2+32)`; 源 +32 由哈希器 sub_140612C40 写入 (常量 2166136261/16777619 + 大小写折叠); 与 +8 的 id SSO 串配对 |
| +48 | MSVC SSO 32B | gfx | 引号 |

CPowerBalanceSide 主表 (~288B; ctor 0X140A8B8C0):

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vtable | CPowerBalanceSide | 不序列化 | |
| +8 | uint8 | valid | | |
| +16 | MSVC SSO 32B | name | | |
| +48 | uint32 | id | | **u32 FNV-1a ci-hash** (ctor sub_140A8B8C0 初值 −1); 赋值 = 自身 reader vtable[4] sub_140A8ED10 case 11 → sub_140612C40(&v6, a2, a1+16), hash 落 +16+32 |
| +56 | MSVC SSO 32B | icon | | |
| +88 | CEffect (内嵌 88B) | on_activate | | 键 15557 |
| +176 | CEffect (内嵌 88B) | on_deactivate | | 键 15558 |
| +264 | CPowerBalanceRange* 向量 | ranges | c>0 | 1856B 元素 = CPowerBalanceRange (§4.3.22); reader case 78; Rebuild 收集器 sub_140A8C680 |

注: CEffect 88B 复合块形 = {vtable CEffect, children vector@+8 c@+20, MSVC@+56}。
注: SetSides sub_140E58330 换侧时逐国执行旧侧 on_deactivate (+176) / 新侧 on_activate (+88)。

#### 4.3.22 CPowerBalanceRange (1856B = CProgressSection 1808B + 48B 尾)

CProgressSection = 1808B 具体类; CPowerBalanceRange = 之 + 48B 尾。键名经
各自 reader + common/bop 脚本逐键对账: **CProgressSection 的 reader = sub_140A12670**
(vtable 0x1427197D0: case 675/676 = min/max +8/+16, 10876 = +568 CRule, 15557/15558 = +1584/+1672 CEffect,
10597 = +24 CStaticModifier); **CPowerBalanceRange 的 reader = sub_140A8ECE0** (vtable 0x14293FFA8, 仅 case 11
→ id 串 +1816 / hash +1848); CPowerBalanceTemplate 的 reader = sub_140A8EDD0 (vtable 0x142940050);
CPowerBalanceSide 的 reader = sub_140A8ED10 (vtable 0x142940000 [4])。四者非同类。
⚠ 另有 1808B vector\<CProgressSection\> 变体 (sub_140A1FD20) 与 bop 1856B 路径
(sub_140A8A770) 并存, 勿混。

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +8 | int64 | min | | |
| +16 | int64 | max | | |
| +24 | CStaticModifier (内嵌 544B) | — | | |
| +568 | CRule (内嵌 1016B) | — | | |
| +1584 | CEffect (内嵌 88B) | on_activate | | |
| +1672 | CEffect (内嵌 88B) | on_deactivate | | |
| +1760 | token | 显示名 loc | | |
| +1768 | uint8 | allow_effects | | Validate sub_140A12240 三连断言 |
| +1769 | uint8 | allow_modifier | | 同上 |
| +1770 | uint8 | allow_rule | | 同上 |
| +1776 | MSVC SSO 32B | desc loc 键 | | |
| +1808 | uint8 | valid | | THasNullObject mdisp 直证 |
| +1816 | MSVC SSO 32B | id | | |
| +1848 | uint32 | id hash | | **u32 FNV-1a ci-hash**; 读取点 = 自身 reader vtable[4] sub_140A8ECE0 case 11 → sub_140612C40(&v4, a2, a1+1816), hash 落 +1816+32 |

#### 4.3.23 国级周期更新入口 (hourly / daily / weekly / monthly 时序钩子)

时间推进链 (§4.2) 逐国调用的国级行为入口 (探针域 + country.cpp source_location 定案):

| 入口 | 函数 | 调用时机 | 要点 |
|---|---|---|---|
| CCountry::PostHourlyUpdate | sub_140705630 | hourly 主调度六阶段之 postHourlyUpdate 串行段 (§4.2.6) | **on_daily / on_daily_<TAG> 派发点**; 判据 `(tag + gs+1128 总小时) % 24 == 0` → 每国每天恰一次, 时辰由 tag 固定 (country.cpp:4861) |
| CCountry::DailyUpdate | sub_1406E76A0 | CGameState::DailyUpdate 全量国循环 (§4.2.7) | 探针 "country.daily"; 门 = cc+1156>0, 活跃分支 31 步 (内战目标/exile_divisions/人力·生产·资源·科研·部署/市场/政治/外交/核弹/焦点/后勤/燃料/operations/经验/志愿远征军/fleets/railway_guns/**投降流亡 sub_1406E16C0**/trade_influence/剧场/queued_events 派发); on_border_war_lost 判据 = 控制州 state+2149 活跃旗 且 进度 > define BORDER_WAR_VICTORY (派发后 sub_1409DDA30 熄火); "country.calc_modifier" (sub_1406DADE0) = 13 pass 修正重算 (§4.2.7 备注) |
| CCountry::WeeklyUpdate | sub_140718CA0 | CGameState::WeeklyUpdate 国循环 (§4.2.8) | 周累加族: cc+5312 宣传稳定惩罚 clamp [−0.2, 硬编码 0] / cc+4304 stability / cc+5320..5344 四战争支持度惩罚 (−0.3/−0.3/−0.5/−0.2 轰炸/英雄/护航/宣传; 下界 define 上界硬编码 0) / cc+4312 war_support 双 clamp [双 define 0/1] / WEEKLY_MANPOWER (mdef 62) + 流亡 mdef 588 / 占领日志 GARRISON_LOG_MAX_MONTHS(12) 清理; major 断言 cc+5210 一致性 (country.cpp:5793/:5810); **on_weekly / on_weekly_<TAG> 派发点** |
| CCountry::MonthlyUpdate | sub_140703490 | CGameState::MonthlyUpdate 国循环 (§4.2.10) | 门 = owned_states(+1156)>0; 十段: dip 月更 (MONTHLY_LEASED_IC_DECAY) / **major 全量重算** (无宗主 && is_top_ic(cc+5211) && 工厂 ≥ MAJOR_MIN_FACTORIES=35 → cc+5210; 补判门 = 工厂 ≥ 0.7×top 均值 且 ≥35 双条件 AND) / calc_modifier pass / 州征兵 + **阵营人力上缴** (token 10476, faction+2288 记原人力; mdef648 只缩放贡献分) / 改善关系 / **on_monthly / on_monthly_<TAG> 派发点** / 玩家 tag 管理器引用计数 / **季度舰队重整** (绝对月 %4==0 = 4/8/12 月, 玩家国专属, sub_140218EB0) (country.cpp:5677) |
| sub_1406FF1F0（国级按位更新派发器） | sub_1406FF1F0 | 双入口: ① postHourlyUpdate 阶段① 带本小时累积修改位, 算毕 cc+4320 清零 (§4.2.6); ② CSelectEventOptionCommand::Execute 尾部带掩码 0x0FFFFFEF (§4.33.18) | 二参 = 位掩码, 按位派发 (country.cpp:8857): bit0 sub_140716580 (无参) / **bit1 = CalcMod 修正重算 sub_1406DADE0** ("CalcMod for <tag>" + supply_factor 误用警告 :8863, cc+1464 容器 find token 566) + sub_140E70C80(\*(cc+3944)) / bit2 sub_1406DD0C0 / bit3 sub_140CFE770(cc+808) / bit4+5 同现门 sub_14070C890 / **bit6 sub_14070AF30** (InitData 新局路以掩码 65 = bit0+bit6 调用实证) / **bit7 sub_140D46650 = 外交状态 on_action 评估** (diplomacy.cpp, on_war / on_uncapitulation 串; §4.2.9) / bit8 sub_14070BDB0 / bit9 sub_140E6C810(\*(cc+3944)) |

> 备注: hourly 主调度并行段的排序键 = `cc+5488 (double)` 升序 (插入/并行归并两套)。
> 备注: **cc+4320 脏位置位者清单 (定案)**: sub_1410DC4E0 → sub_1407042D0 置 \|=2 (建筑/工厂
> 计数链) / sub_140EE3E70 置 \|=0xA (科技) / sub_140D46650 置 \|=0xFFFFFFF (外交全位) /
> sub_140E801A0 置 \|=0x40 (省控制权变更)——现役写者全表, 派发器本体见上表。
> **cc+5488 定案 = 每国小时更新耗时 EWMA (α=0.02s)** — 纯自测量负载均衡键:
> stamp 头 sub_140CFEAD0 / 尾 sub_140CFEAF0, 作用于 cc+5424 块 (5496 = 块内 +72 槽);
> 双键排序每小时执行两轮: sub_1401DF400 出口前 (sub_1401B6AD0 归并 → sub_1401B6720 插入)
> + sub_1401D85A0 相位 2 (sub_1401B6BE0 归并 / sub_1401B6870 插入); 插入式双键入口对
> sub_1401B4780/sub_1401B4900 (EWMA 键/师数键) 同族 (定案)。
> 备注: 活跃国门 = owned_states cc+1156 > 0 (hourly/daily/weekly/monthly 四级共用)。
> 备注: **trade_influence 贸易影响力十因子** (装配器/求和 = sub_1406DD280; 定案):
> BASE=sub_1406EC400 / DISTANCE=sub_1406EF880 / PUPPET_MASTER=sub_1406F7180 /
> PUPPET=sub_1406F7370 / PARTY_SUPPORT=sub_1406F8420 / RELATION=sub_1406F8010 /
> TROOPS=sub_1406F0960 / NAVIES=sub_1406F06F0 / ANTI_MONOPOLY=sub_1406EBBD0
> (§4.23.3b 公式) / OPERATIVE_MISSION=sub_1406F7A90; 终式 =
> S×(1e5+他国 mdef225 TRADE_OPINION_FACTOR [他国+1464])/1e5 (÷1e5 magic-mul, PE 核);
> 前置门 = 他国 cc+1156>0。

#### 4.3.10a 核弹投放执行链

**投放通道 (定案, 全引擎三处收口)**: ① 脚本效果 launch_nuke
(CLaunchNukeEffect::Execute 0x140359620; ctor 0x14033EB90: +88 州 id / +504
省表达式 / +512 省直门 / +712 nuke 条目序 / +716 扣弹旗; 目标解析 = +512 门
直取 ∨ 州内均匀随机选省 (sub_14039F210 `candidate[rand % count]`, 无 VP 权重;
候选 = 州内省按 owner 域/控制域/省表达式三层过滤); +716≠0 → sub_14109A5A0 扣 1e8/弹); ② 控制台
**`nukes`** (命令表实名, sub_14023EF20; **不扣库存; 遍历全部州逐州
GetBestVPProvince sub_1409D8A80 (state+2140 _BestVPIndex, state.cpp:1845 断言)
投 entry 1 热核**; 回显 "Now I am become Death, the Destroyer of Worlds.");
③ 控制台按省版 sub_140264870 (entry 0 常规核; 扣弹返回值被忽略); 另有
**`launch_nuke`** 控制台命令 (与脚本效果同名通道)。**1.19 玩家投放主通道 =
突袭系统** (00_defines.lua NUCLEAR_RAID_CATEGORY_NAME="nuclear_raids" 注释
"nuclear mission button for a rocket" 直证 — 火箭核任务钮激活核突袭类别,
消耗 country+4880、伤害走 EndRaid 效果块, **不经 CNuclearStrike**; 经典轰炸机
点图投弹在 1.19 无执行体 (airmission 64 函数全扫 0 命中))。

strike 入队 = **sub_1410979D0(CNuke, province)**: push 24B **CNuclearStrike**
{vtable 0x1427E7220, +8 = 13718, +16 = 省 id, +20 = time 0}; 槽契约: [2] writer
sub_14109A620 / [4] reader sub_141099F40 / [3] Load wrapper 0x1424BE690
(CPersistent §4.00.1 契约)。**CNuke+56 = 热核级
旗** (THERMONUCLEAR_* define 族 + nuke_big_entity 视效双证; 1 = 热核全州每省
结算/装备全灭, 0 = 常规仅目标省随机部分销)。

飞行两拍 (每小时, 定案): 相位 0 preHourlyUpdate sub_14109A520 — 逐 strike
time = min(time+1, NUKE_DELAY_HOURS dword_1433351D8 = 2); 相位 12
postHourlyUpdate sub_141098460 — 逐到期 strike: 省解析 (gs+8 槽[1]) →
**sub_1410986E0 落地结算** + 压缩删除 (**§4.2 相位 12 桶身份闭合 = cc+4880
在途核打击**; num_nukes_being_dropped = Σ元+60 / num_nukes_left_to_drop =
Σ元+64 与 §4.32 trigger 对齐)。

落地结算 **sub_1410986E0** (nuke.cpp:609) 九步 (定案): ① 日志; ② **受害者
war_support −= 效果值** (公式 sub_140E7A220(省, 出参, tier) = clamp(州最大省 VP/(*_MAX_VP=3), ≤1) ×
(infra 等级比 × *_MAX_INFRA=0.2); tier==1 选 THERMONUCLEAR 定义对 (cmove 双槽);
VP 取省+56 最大值; define 注释 "Reduce
enemy national war support" 直证; 边界: MAX_VP=0 → 哨兵 −1 → 上钳 → **满效应**);
③ 省/州破坏域 (tier≠1 仅目标省, tier==1
全州): 每省三件 = 在场单位双随机强度/组织伤 (dmg = MIN + rand%101×(MAX−MIN)/100
两独立 roll 分给 STR/ORG, CUnit vtable+200; 海军 unit+8==1 跳过)
+ 空军基地/火箭位/炮位驻机全灭 (CStrategicAirManager +144/+168/+192, 断言
nuke.cpp:553) + **省建筑全灭** (prov+456 = CBuildingStatus+56 CBuilding*
数组, §4.14.1, **循环无门无条件**; sub_1410DC060 拆级, 拆级内部伤害值 =
1e7×级数 + partial_health, 仅 >0 门用; 修理线第 2 参 1 = repair, 第 4 参 =
拆除级数); ④ 州建筑
(st+344 = CBuildingStatus+56, §4.13): tier==1 全灭 / tier≠1 rand 保留级数;
**免损三旗门 = 州建筑侧两面** — 主函数 ④ 循环的排除门与 sub_141097F40
第二段的包含+定位省门, 旗 = def+867 (air_base) / def+784
(rocket_launch_capacity >0) / def+883 (inherit);
⑤ 拆毁级数入 **AddConstruction(repair=1) 修理线** (sub_140E5F8C0,
§4.8.5a — 非装备损益); ⑥ **战争分账 +Σ(拆毁级数)×
WAR_SCORE_STRATEGIC_BOMBING_FACTOR** (和会战争分来源; 计量不对称: tier==1 与
省建筑/三类场站计 level(+64), tier≠1 州循环计 healthy(+66)−rand%healthy,
partial_health 不计); ⑦ 玩家侧成就/统计
事件; ⑧ **on_nuke_drop on-action** (**THIS = 投弹国 scope / FROM = 被炸州 scope** — 发射器 sub_14109A2A0 :583/:586 直证, 方向定案); ⑨ 视效
(tier 选 nuke_entity / nuke_big_entity)。

库存侧 (每日, 定案): CCountry::DailyUpdate 逐 CNuke — **sub_141097D50**
① 产弹 sub_141098D50 (门槛 mdef MODIFIER_NUCLEAR_PRODUCTION ≠0; 日增 =
NUCLEAR_PRODUCTION_FACTOR 修正 × 1e8 / NUCLEAR_BOMB_PRODUCTION_SCALE(2555)
/ THERMONUCLEAR_..._SCALE 换算, vanilla 注释 "+1 production = 1
nuke/7 years"; SCALE=0 哨兵 → 钳 0 不产) → amount(+24) 累加 clamp (999 弹
顶); ② **sub_141098240 raid 装填**:
可用弹 = amount÷1e8, 遍历 gs+1008 核突袭系统按国 active raids 逐个
sub_140FEC7E0 装弹 (写 inst+336 族) 扣库存 — 核突袭弹药供弹端。

#### 4.3.24 指挥点（Command Power）回充链

每日回充（无 hourly 通道——+496 全域写点 census 收敛为 3 函数 + loader）:
挂 CCountry::DailyUpdate 串行段，间谍行动日更（cc+5544）之后、三军经验日更
（cc+5512）之前（定案）。

公式（全程 fixed×1e-5，定案）:

| 项 | 公式 | 默认/修正 |
|---|---|---|
| gain | (BASE_COMMAND_POWER_GAIN + mod330) × (mod332+100000)/100000 | define 0.4/日; 330 = command_power_gain 族 / 332 = 增益因子 |
| cap | (BASE_MAX_COMMAND_POWER + mod331) × (mod333+100000)/100000 − cc+504 | define 80.0; 331/333 = 上限族; **cc+504 = 已分配额**（分配器指派 sub_140714830 联动） |

唯一写收口 **sub_1406CFE60**（写 +496 并钳 [0, cap]）；日更体内为**内联公式
复制**，共享实现 sub_1406EE860 只服务 GUI（顶栏 tooltip + 绑定取值器）——
**改公式须两处同步**（定案）。存档读回走 case 14467 直写 +496 不过钳位；
初始化 = sub_1406E2DE0 赋 STARTING_COMMAND_POWER(0.0)。sub_1406CFE60 十调用
方全定名（effect/控制台/顾问/将领命令族）。

#### 4.3.25 CCountryResources (存档块 country.resources; rs = rp(cc+4600), 堆对象; 主 vtable 0X295C4B0@+0 / CPersistent vtable 0X295C4E8@+24; ctor 0X140CA49D0 / dtor 0X140CA5860 / writer 0X140CBE2D0 / reader 0x140CB7610, 收 a1 = rs+24)

⚠ **坐标桥定案**: writer/reader 收到的 a1 = **rs+24**（CPersistent 序列化子对象
vptr@rs+24），非 rs 本体；`a1 − 24` 全部指回 rs 本体（writer 首参 sub_1415A7480 /
reader 兜底 sub_1415A7450 / CResourceExchange+128 回链 / CLendLeaseExchange+176 回链）。
三侧互证 = dtor 清扫集与 writer 直读容器集逐项恒差 24 + 真 ctor 初始化集与 dtor 重合
（ctor-this = dtor-this = rs）+ 书内五锚（§4.2 rs+40 / §4.8 rs+1096 / §4.21
rs+1832·+2000 / §4.23 rs+1928 / §4.32 rs+1832+24×cat）全部吻合。⚠ 按 a1 偏移字面
检索全书会系统性落空（24 位移）。⚠ 单类取证工具把 0x140CA5860 标为 ctor，实为
**dtor**（容器逐个清扫 + 双 vptr 回写）；真 ctor = 0x140CA49D0（`*(_DWORD *)(a1+32) = *a2` 抄 tag 起手）。
sizeof 下界 ≥ 2001（ctor 最大直写 = dirty u8@rs+2000）；基类 = CEquipmentDistributable,
CPersistent（双序列化路径: 主表槽 [8..11] 与子表槽 [1..4] 同 writer/reader）。

| 偏移 | 类型 | 名称/语义/键 | 序列化 | 证据档 |
|---|---|---|---|---|
| +0 | vptr | 主vtable 0x14295C4B0（CEquipmentDistributable 链; [8]Save/[9]writer/[10]Load/[11]reader） | — | 定案 |
| +8 | uint32 | priority（141）= CEquipmentDistributable 基类「分配优先级」(基类 ctor sub_1415A7410 默认 1; rs ctor 尾覆写 3; writer 门 ≠1 = 非基类默认才落盘; reader case 141 回读 — 高置信; 消费点 [谁读它排序] 需活体; **活体: 载档后读值 = 1** — 读档走基类默认路径, ctor 置 3 只在新建会话态) | 是 | 高置信 |
| +12..+15 | — | 对齐垫 (priority 后) | 否 | 高置信 |
| +16..+23 | 8B | CEquipmentDistributable 第二基类字段 (基类 ctor 置 0; 消费未定位) | 否 | 高置信 |
| +24 | vptr | CPersistent 序列化子对象 0x14295C4E8（[1]/[2]/[3]/[4] = Save/writer/Load/reader）; **writer/reader 的 a1 基点** | — | 定案 |
| +32 | uint32 | 本国 tag（ctor `*a2` 抄入; CResourceOrigin ctor 填 el+24/el+904） | 否（tag 由父层表达） | 定案 |
| +40 | CStrategicResourcePool 内嵌 (176B) | produced（12204）资源产量池 | 是 | 定案 |
| +216 | CStrategicResourcePool 内嵌 | transfer_overlord_subject（16764）宗主转运池 | 是 | 定案 |
| +392 | CStrategicResourcePool 内嵌 | imported（12482）进口池 | 是 | 定案 |
| +568 | CStrategicResourcePool[3] (3×176) | to_use（12483; 单块包 3 池; [0]/[2] 直拷 sub_140BCAF50, [1] = f(1)−f(0) 差值合成 sub_140BCB3B0）; 池 [2] 基 = rs+920 = 产线消耗释放回收池 (equipment_production_line.cpp:653 释放遍 trade.h:554 断言直证; **定案升级: UI 产线消耗行直读 [2]**, trade.cpp CB4220); [0]/[1] = 基准/含预备总池 — **消费语义 [1]−[0] = 特殊项目消耗** (高置信, UI 特殊项目行取差 + reader 差值编码自洽)。**池内网格 (活体)**: 池 = 头 48B + 8×16B 元 {资源 id u32@+0, 量 i64 fixed×1e-5@+8}; 首元 id = `none` 哨兵 (lexer 直证 oil/aluminium/rubber/tungsten/steel/chromium/coal 七资源随 mod); 尾锚读数 = 空容器哨兵 0x2E85170 非业务量; **活体对拍: P0 == P1 全程相等 (暂停与跑 6.5 月后均等 — 本会话无预备消耗), P2 = 负值累计且跑动期有增量 (tungsten −49→−48) = 产线释放持续发生** | 是 | 定案 (落盘契约: 块 2 = mem[1]−mem[0] delta 编码, 读侧 pool[1] += pool[0] 重组) |
| +1096 | uint16 | **逐池代数戳 [0]** (池 0 = 基准池; reader case 12483 装载尾 ++, 0xFFFF 回绕置 1) | 否（派生缓存） | 定案 |
| +1098 | uint16 | **逐池代数戳 [1]** (bump 与池操作同索引: 消耗原语 sub_140E5AAB0 按 a5 写 rs+1098+2×a5 = 本戳或戳[2]; 0xFFFF 回绕置 1) | 否（派生缓存） | 定案 |
| +1100 | uint16 | **逐池代数戳 [2]** (产线释放固定 bump — 池[2] 释放遍 sub_141937BB0 / 0x14193A460 内联清算段; 0xFFFF 回绕置 1) | 否（派生缓存） | 定案 |
| +1102 | uint16 | 未见表 (a5 = 2 防御路径存在但现役调用者只用 0/1 — 待裁) | 否 | 未决 |
| +1104 | CStrategicResourcePool 内嵌 | to_export（12484） | 是 | 定案 |
| +1280 | CStrategicResourcePool 内嵌 | base_export（14178） | 是 | 定案 |
| +1456 | CStrategicResourcePool 内嵌 | exported（12485） | 是 | 定案 |
| +1632 | CStrategicResourcePool 内嵌 | 第 4 池（资源向量@+1640 = §4.3.3 only_imported 推定行宿主） | 否 | 推定 |
| +1808 | CResourceOrigin* 向量 {d@+1808, cap@+1816, c@+1820, alloc@+1824} | 资源权利对象列表; 逐元素键 12473 origin 发多态子块（无包裹键, 重复键发射）; 元素 1016B（ctor 0x140CA5090, owner tag 抄 rs+32） | 是 | 定案 |
| +1832 | CResourceExchange* 向量 24B | 按 资源 def+216 cat 索引的 24B 槽组, 头 {d@+1832, cap@+1840, c@+1844, alloc@+1848}（ctor 预扩至全局 cat 数槽, 槽 = sub_14011DF40 形 24B 容器）; 槽内元素逐个键 12486 export 发子块; 元素 = CResourceExchange（240B; vtable 0x14295C410 / writer 0x140CBEEC0 / reader 0x140CB8E10; +128 = rs 回链, §4.8） | 是 | 定案 |
| +1856 | CResourceExchange* 向量 {d@+1856, cap@+1864, c@+1868, alloc@+1872} | **_ResourceImports 进口交换条目扁平表** (定案: 断言串 `_ResourceImports.Contains( pImport )` trade.cpp:3246 直证; 元素 = CResourceExchange\*, 其 +136 receiver = 本国; 写点 = 建交换 sub_140CA6370 双注册之进口侧 — seller 侧进 +1832 cat 桶、receiver 侧进本表; **runtime-only**, reader 12486 export 只建出口桶不触本表 = 读档后重建; 消费 = 进口民厂分配 sub_140CBAA10 遍历) | 否（runtime-only） | 定案 (原「语义未决」升) |
| +1880 | CLendLeaseExchange* 向量 {d@+1880, cap@+1888, c@+1892, alloc@+1896} | lend_lease（12618）; 元素 896B（malloc 0x380）, ctor sub_14196A480: CConvoySubscriber@+136 / rs 回链@+176 / 10×64B 容器 @+216..+728 / CGameDate×4 @+792..+840; 元素级 getter +408/+472 差 = 按型出站租借净量 (sub_1413716B0, 饱和累加; 方向语义「承诺−已交付」待裁) | 是 | 定案 |
| +1904 | 匿名结构 (8B 形状) 向量 | 在途输入条目队列 (8B 元素指 0x14196 交换族 896B 对象; 求和 getter sub_140CA7C70 = Σ(元+880), 另有 Σ getter(元+600) = sub_141372CF0 (按型在途量); 唯一消费 = 燃料日更 sub_1410F71B0 取和入 fuel+40 参与资源槽分配 — 机制定案, 业务名「inbound 租借/输送条目」高置信) | 否（runtime-only） | 定案 (机制) |
| +1928 | CResourceDeliveryRoute* 数组 {d@+1928, cap@+1936, c@+1940, alloc@+1944} | delivery_routes（13476）; 按买方国 idx 索引（ctor 尾扩到国家容器规模并 null 填充）; writer 跳 idx 0, 逐非空元素以 route+52 tag 名（sub_140BB4E70）为键发命名子块; reader 按 tag 名回填原槽 vtable[3]（trade.cpp:3844 未知 tag 报错） | 是 | 定案 |
| +1952 | modify_building_resources 表向量 {d@+1952, cap@+1960, c@+1964, alloc@+1968} | modify_building_resources（14547, 门 count≠0）; 外条 32B {建筑 token u32@+0, 内表 24B 向量@+8}, 内元 16B {u32 资源 idx, fixed×1e-5 → sub_1424ED730 转整落盘}; reader 外键走 TGameItemDatabase 查建筑 | 是 | 定案 |
| +1976 | 16B 条向量 {d@+1976, cap@+1984, c@+1988, alloc@+1992} | extra_resource_origin（15049, 逐条重复发块）; 条 = {CResourceOrigin* @+0（键 12473 子块）, giver tag u32@+8（键 12500 giver; writer 转 tag 名串 / reader 存 tag id）}; reader 建新 CResourceOrigin（tag 抄 rs+32） | 是 | 定案 |
| +2000 | uint8 | dirty（13444）; 资源系统重算五连末段清位（§4.32） | 是 | 定案 |

> writer 21 个直读偏移（a1 基准）→ 上表行映射: a1−24→+0; a1+16→+40; +192→+216;
> +368→+392; +544→+568（×3 循环）; +1080→+1104; +1256→+1280; +1432→+1456;
> +1784/+1796→+1808/+1820; +1808/+1820→+1832/+1844; +1856/+1868→+1880/+1892;
> +1904/+1916→+1928/+1940; +1928/+1940→+1952/+1964; +1952/+1964→+1976/+1988;
> +1976→+2000 —— 21/21 全数定案。
> reader 遗留键（写侧不发）: 11841 raw_materials / 12488 raw_materials_consumed
> —— 解析态 a2+192==3 时报错（sub_1424C2100）; 兜底 sub_1415A7450 仅 case 141
> （priority→rs+8）。
> writer 发射序（存档形）: delivery_routes → extra_resource_origin×N → dirty →
> produced → transfer_overlord_subject → imported → to_use（3 池块）→ to_export →
> base_export → exported → origin×N（裸重复键）→ export×槽（裸重复键）→
> lend_lease×N（裸重复键）→ modify_building_resources（条件块）。

CStrategicResourcePool（176B; ctor sub_140BCAFB0 直写 vftable 符号定名; 拷贝
sub_140BCAF50; 差值合成 sub_140BCB3B0 = copy 后逐资源减; 阵营侧宿主 §4.5.8 元素形同）:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vptr | — |
| +8 | 资源向量 {d@+8, cap@+16, c@+20, alloc@+24} | 元素 16B {i64 定点 value@+0, u32 资源 token@+8, pad@+12}; ctor 按全局资源数+1 预扩, idx 0 = 哨兵（与 delivery_routes 跳 idx 0 同风） |
| +32..+175 | — | 死尾 (高置信: ctor 只写 {vtable@+0, 向量@+8} 无 memset, copy/diff 只动 +8 向量, writer/触发器取值件同域封闭全不触; 176 = 嵌入步长 [eh vector constructor iterator stride], 疑历史/扩展预留) |

> rs 内 8 实例: +40/+216/+392/+568×3/+1104/+1280/+1456/+1632; CResourceOrigin 内
> 4 实例 @el+136/312/488/664（§4.3.3 已记 136/312/664 三处, 第 4 处 @488 本节补,
> 键名待 origin writer 侧取证）。

CResourceOrigin 元素布局（1016B; ctor 0x140CA5090; 挂载 = rs+1808 向量条目 /
rs+1976 条解引用; 消费行 §4.3.3）:

| 条目内偏移 | 类型 | 名称/语义 | 证据档 |
|---|---|---|---|
| +24 | uint32 | tag（owner, 抄 rs+32） | 定案 (ctor sub_140CA51D0 直证; 原「推定」升) |
| +128 | CState* | 州指针 (权利授予 wrapper sub_140CA6760 按 origin+128 == 州 查找命中) | 定案 (ctor 直证; 原「推定」升) |
| +904 | uint32 | tag 第二落点 (= 抄 +24, ctor 直证) | 定案 (原「推定」升) |
| +992 | 匿名结构 (8B 形状) 向量 | given_resource_rights — 8B 条 {res_key u32@+0, tid u32@+4}; res_key 1..7 = 资源索引序 (oil..coal), 资源名 = 运行时本国资源向量动态收集（非静态表, mod 新资源自动对）; **写者 = sub_140CB58F0 单资源 / sub_140CB5AF0 批量** (有序向量按 res_key 二分, 命中改条+4 / 未中 sub_140C9EBF0 插入; 前置断言 trade.cpp:1985 `HasOwnRightsTo ∥ GetRightsHolderTo == RightsHolder` / :1986 `def->GetIndex() > 0`); 共同宿主 wrapper = sub_140CA6760 | 定案 |

#### 4.3.25a 资源贸易运行时 (trade.cpp 全簇定性)

16 函数全定性 (ctor/dtor 族 + 运行时重算 + 权利与属国转移 + 序列化 + 民厂分配/UI 文本; 断言行号锚定 trade.cpp 源 ≥4700 行)。对外入口: **resources.daily** sub_140CABB30 → 结算 sub_140CA6EB0 (×3 调交付重算) / **hourly DoTradeRoutesUpdate** sub_1401D9890 → 工作体 sub_140CBC8C0 → 快检 sub_140CA7990 / 全量 sub_140CA90F0 (港口 BFS sub_140CABF00 + 海路四值枚举 sub_140CAA1B0) / 资源并行 harness (F07470 系) → 巡检/重评/extra origins sub_140CBA140 / 民厂消费者 (civ_factory_consumer.cpp 虚槽 sub_1419FE9B0) → 进口民厂分配 sub_140CBAA10 / 命令域 sub_140CB5D60 (建/改/删出口贸易: 现存交换查 +136 receiver → 无则建、有则摘旧重建且**起始日期从旧交换保留**; amount ≤0 = 取消) / UI 贸易视图 (出口面板 sub_140CAEF80 五段文本 / 消耗明细 sub_140CB4220 / 进口请求 tooltip 族)。

公式 (全整型定点, 无浮点):

| 公式 | 定案式 |
|---|---|
| 交付量 (sub_140CA9EF0) | `delivered = clamp(量,0) × eff(+72) × eff_lost(+80) / 1e10`; 返回值魔数 = 进位修正合并渲染, 非独立语义; 虚槽槽15 (+120) = origin 获取器 / 槽16 (+128) = receiver 获取器 (receiver+8 kind ==2 才进主路径); request 链 = 路线键 sub_140CA7CD0 (含 mdef 275 TRADE_COST_FACTOR [DLC 门 sub_1401AEB50(5)] 与 mdef 377 TRADE_COST_TO_TARGET_FACTOR, 尾乘 Required) → sub_141020F40 (define qword_143333200, 下限钳 1e5) → 损失折减 + ceil 1e5 网格 → sub_141022950 提交 (语义未决) |
| 护航申请量 (sub_140CA78F0) | `ceil((1e5 − coverage) × 期望(+120) / 1e5)` |
| 海区安全覆盖率 (sub_140CA7700) | `1e5 × Σ(受控海区权重 region+224) / Σ(权重) × CONVOY_CONTROLLED_ROUTE_COST_REDUCTION_FACTOR / 1e5` (谓词 = sub_141003F50(region+232, tag)); define qword_1433334D0 定名 |
| RequiredCic (sub_140CAAA20) | `ceil(1e5 × 量 / 单位成本)`, cost(1)==0 或量==INT64_MAX → 0xFFFFFFFF |
| 属国资源转移 (sub_140CB4100) | CountryResources = country+4600 (空 → 断言 "Failed to find CountryResources for subject country" :2803 → 空池构造 sub_140BCAFB0); produced 池 (= res+40) 快照 × mdef 641 `MODIFIER_RESOURCES_TO_OVERLORD_FACTOR`; 属国聚合器 sub_140CBDE80 遍历 **dip+368 数组/{count@+380} 属国 tag 表**; CStrategicResourcePool 三构造器 = sub_140BCAF00 拷贝 / sub_140BCAFB0 空 (按全局资源表 sub_1401DB5C0 扩容) / sub_140BCAF50 快照入局部 |

CConvoyClient 基类补行: **+124 u8** (ctor 清 0; sub_140CAB520 消费门); dtor = sub_140CA5600 (+88 战斗 idpair 表逐元解绑 — 元素 −16 还原 CNavalCombat, sub_1415C5090 注销; +112 spotter 反清 sub_140FBA990(对象+848, 0) 后复位哨兵)。CConvoySubscriber init (sub_141021F90) 末两参 = kind (8 = 资源交换 / 0x10 = 资源 origin) + priority define (NMarket.RESOURCE_EXPORT_PRIORITY dword_143334208 / NMarket.RESOURCE_ORIGIN_PRIORITY dword_14333415C)。

进口民厂分配 sub_140CBAA10 (定案): 遍历 rs+1856 `_ResourceImports` 扁平表, 逐条 `Required(+224) − Assigned(+228) ≥ 0` 断言 (:3207) 后 min(预算, 缺口) 分配; 部分分配 → 按剩余量重算 RequiredCic (TRADE_WAS_MODIFIED), 全额 → **从 seller 出口桶反删** (sub_140CBBA40, TRADE_WAS_TERMINATED)。

UpdateExtraResourceOrigins sub_140CBA140 三环 (定案): ① 清除 — giver tag 命中 dip+152 交战国缓存即删 + 州+204 controller 与条+8 giver 失配删 (同原初国内战场景留); ② 补建 — 本国持有州满足 (stateDef+260 资源条 >0 ∨ 州+448 数组有正值 ∨ 州+436 可见旗 ∨ sub_1409DAA80) 且 rs+1808 无该州 origin → 建补; ③ 终检 — origin 州 controller ≠ 本国 tag 即删 = **origin 存续条件 = 州仍由本国控制**。

> 港口 BFS 队列元 SFindAllPortsQueueItem 16B {省指针, 距离} (内联 64 项起步); 配套谓词 sub_140CAA8C0 = 省+204 controller 对路线两端 tag (+48/+52) 及其宗主 (dip+392)/hosting (dip+424) 任一同原初国即放行。海路四值枚举 sub_140CAA1B0 的门控全局对象 (sub_140E23570 返回值, +0 bit1 门 / +64 成员数组) 身份未决 (结构近似阵营/从属过滤器, 无业务串可锚, 不强行定名)。

#### 4.3.26 country.cpp 簇增补 (81 函数全量定性; 领袖/铁路炮分发/能力/修正门)

- **领袖四胞胎精确分型** (定案): A/B/C/D 唯一差异 = 机构登记尾调用 (A 全量登记 / C 招募池+64 / D 变体待裁 / B 无); 转发器 3 件 + 路由器 type 分型 (0/1/2→B, 3 = operative 报错, 4 = 销毁, ≥5 静默) + 内部件 + 工厂双件全链。
- **领袖招募成本 sub_1406F1950 = 陆/海双分支** (定案): 公共底 = modifier(121, cc+1464) + 100000; 海军支 = (底 + modifier(123)) × min(NAVY_LEADER_MAX_COST qword_1433336B8, NAVY_LEADER_COST qword_143333538 × 1e5 × *(外交首项+12) / 1e5) / 1e5; 陆军支 = (底 + modifier(122)) × min(ARMY_LEADER_MAX_COST qword_143333600, ARMY_LEADER_COST qword_143333490 × …) / 1e5; 负值钳 0; 修正 id 121/122/123 三枚; 断言 "Invalid leader type" country.cpp:7791。
- **sub_140704380 = TransferRailwayGuns** (源码符号泄漏实名, 定案): 战胜国按份额随机分发铁路炮全算法 (步进 1255572915 哈希族)。
- **CCountry::ActivateAbility sub_1406EA4E0** (定案): 付费门 (payCheck ∧ 免费旗 ab+148 假 → CP ≥ cost 扣减, 断言 "bSuccess" country.cpp:4269 debug 下失败即断) → **88B 条目 append 至 cc+5560 数组** (count cc+5572; 字段 +0 ab / +8 scope tag / +16 scope / +24 角色名 id / +32 *(scope+72) / **+48 = gs+1128 当前日期** / +64 56B CCommandPowerAllocator / +80 v43) → 战斗力分配表 sub_140714830 → 三能力回调。
- **CCountry::CalcModifiers sub_1406FF1F0 = 9 位门逐位表** (定案; country.cpp:8857 "CalcMod for <tag>"): 0x001 名称缓存 / 0x002 全修正重算+production+修正 id 566 特例 / 0x004 sub_1406DD0C0 / 0x008 人力块 / 0x030 双位同设 sub_14070C890 / 0x040 邻国位图 / 0x080 dip 侧 / 0x100 占领度量 / 0x200 production 侧。
- **首都 VP 省收集器 sub_1406EC9E0** (定案): 首都州 BestVP ≥0 单省; 否则查 **gs+984 表** (条目 = 基址 + 120×identity(tag); **门 u32 在条目+0** — 旧「条目+64 计数门」有误) ≤0 → 州全部省回退, >0 → 单值解析一省; 消费链 = 地图层 "Update Provinces (%d)" (gs+984 宿主类名待裁)。
- **所有权一致性清扫 sub_14070F0A0 = 三段** (增补): 原两段之外有**铁路炮引用摘除段**。
- 小件: CreateUnit 多类型工厂 (charman = gs+1704) / GetCachedTradeInfluence (断言 "_HasCachedTradeInfluence ‖ IsFirstTime", 无 gs 断言 = 热 join 外可安全调, 返 cc+240+8×slot) / airbase 谓词对 (A 国匹配门 :11162 / B 位掩码门 :11138 掩码宿主待裁) / 科研槽增设对称对 (cc+4936 ±/＝, 负钳 0) / 傀儡广播对。

#### 4.3.27 CContinuousFocusPalette 域 (continuousfocus.cpp; 7 函闭环 — palette 布局/def 增补/库单例/选择链/icon case)

> 书 §4.3.15 系原只收 CContinuousNationalFocus def 侧 (sub_1406C3310 成员解析); 本节补出 palette 侧全域。7 函体内 cpp 锚 7/7。

簇清册:

| 函数 | 行数 | 锚 (file:line) | 定性 |
|---|---|---|---|
| sub_1406C2E30 | 337 | CLogStream :51 | CContinuousFocusPalette 成员分派 + CContinuousNationalFocus 工厂 (双角色一体) |
| sub_1406C2550 | 205 | 错误日志 :199 / CLogStream :206/:211 | def 图标校验 (后装载 pass, 纯 vtable 引用无直调方) |
| sub_1406C1640 | 107 | 错误日志 :494 (内联共享) | 全国家 palette 选择 (启动 setup 区) |
| sub_1406C1520 | 67 | 错误日志 :494 (同上内联) | 单国 palette 选择 (国家建立链 sub_141425810) |
| sub_1406C2180 | 57 | 错误日志 :88 | 库单例内 def 查名 (FNV 预筛线扫) |
| sub_1406C1FA0 | 48 | 错误日志 :436 | 默认 palette getter (扫 default 旗, 后者胜) |
| sub_1406C19E0 | 42 | 断言 :227/:233 | def 当前 icon case 解析 (selector 求值) |

**CContinuousFocusPalette 布局** (sub_1406C2E30 分派半边 + 消费点定案):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | MSVC 串 {size@+24, cap@+32} | id 名 | token 11 "id"; 读入后立算 FNV-1a |
| +40 | uint32 | id 名 FNV-1a hash | |
| +48 | CContinuousNationalFocus* 向量 {d, cap@+56, count@+60, alloc@+64} | focus def 表 | token 13239 "focus" 工厂 push |
| +72 | uint8 | default 旗 | token 11405; 多默认警告 :436 后者胜 |
| +73 | uint8 | reset_on_civilwar | token 13494 |
| +80 | 值块 | country 评分块 | token 10394; 评分器 sub_1405520E0 |
| +136 | 匿名结构 (32B 堆对象) 指针 | position | token 76 "position", 解析器 sub_1402C7E70 (与 §4.19 14173 同解析器异键) |

**CContinuousNationalFocus def 增补行** (ctor 半边; 书 §4.3.15 def 表原从 +160 起, +160..+576 ai_will_do/available/enable/idea/daily_reward/select_effect/cancel_effect 逐段 ctor 互证全符, +856 daily_cost = 100000 / +864 supports_ai_strategy = −1 / +868 available_if_capitulated = 0 ✓书):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | CContinuousFocusPalette* | palette 回指 | 工厂写 |
| +16 | uint32 | id 名 hash (ctor 0) | 查名预筛读此 |
| +24 | MSVC 串 {size@+40, cap@+48} | id 名 | |
| +56 | MSVC 串 {size@+72, cap@+80} | 图标键 | sub_1406C2550 消费 |
| +88 | MSVC 串 {size@+104, cap@+112} | 图标回退/派生串 | 空 → 抄 +24 名 |
| +120 | 值块 | icon case selector | sub_1413772C0 (有无默认 case) / sub_141377240 (求值→case 序号) |
| +128 | 向量 {d, cap@+136, count@+140} | icon case 表, 40B 元 | 元 = 纹理名字串视图 |
| +152 | uint8 | has_icons 旗 | |
| +664 | CModifier (192B) {内嵌 inner vtable@+680} | 内嵌修正块 | 书 def 表缺行, 本批补 |

**库单例 qword_14332EE60** (getter sub_140161E30, gameitemdatabase.h:149 断言): +48 = 全部 def 指针向量 {d, cap@+56, count@+60, alloc@+64}; +72 = 全部 palette 指针向量 {d, cap@+80, count@+84}。

机制面:

- 工厂半边 (sub_1406C2E30, token 13239 "focus"): malloc 872 → 逐段 ctor → vtable[+24] (槽[3] Load wrapper) 子解析 → debug 门 byte_14332EC69 下重名查 (本 def 名 hash 对库 +48 已有条目, 命中 → CLogStream "Duplicate focus name will cause database problems" :51, **报后照常注册 — 重名检查仅 debug 态生效, 装载期默关, mod 重名连续焦点静默注册成立**) → 双 push: 库 +48 与 palette +48 (1.5× 增长)。
- palette 选择链 (sub_1406C1640 全国家 / sub_1406C1520 单国, 同一算法): 逐 palette 评 sub_1405520E0(+80 值块, ctx) 取最高且 >0 → 无候选走默认 getter sub_1406C1FA0 → 仍无 → 格式化错误日志 "No default tree scripted, will apply first scripted instead." :494 取首 palette → **sub_140711A30(国, palette) = sub_1402DACA0(fp,0) 清当前连续焦点 + cc+4984 = palette** (✓ 书 cc+4984 行闭环)。全国家版迭代 gs+784/gs+796 国家表, 门 = tag > 0, 带 gamestate.h:1126 线程禁入断言。
- 默认 getter (sub_1406C1FA0): 扫库 +72 取 +72 default 旗; 多默认 → "Only one continuous national focus palette should be default, switching from %s to %s" :436, 后者胜; 无默认返 0。
- 查名 (sub_1406C2180): FNV-1a (init 0x811C9DC5 / mul 0x01000193) → 线扫库 {data@+48, count@+60} 8B 指针元; entry ≥ 88B = {+16 hash u32 预筛, +24 名 32B SSO {size@+40, cap@+48} (命中谓词 = size 等 ∧ (size==0 ‖ memcmp 等)), +56 第二串 32B SSO {size@+72, cap@+80} 仅碰撞日志用}; hash 同名异 → "Hash collision for national focus: %s while looking for %s" :88 继续扫 (非终止); 未命中返 0。调用方 sub_14138B9B0 (GUI 域)。
- def 图标校验 (sub_1406C2550, 后装载): +88 空 → 抄 +24 名; +752 (def+752 = 内嵌 CModifier+88 域, 归属待裁) 空则缓存 +56 串; has_icons(+152) 时: selector 无默认 case → "Focus %s (%s) does not have a default icon case." :199; 逐 40B case 查纹理管理器 qword_143453090 sub_142238DF0, 缺 → "Missing icon for focus" :206; 拼 "_shine" 再查, 缺 → :211。
- icon case 解析 (sub_1406C19E0): !+152 → 断言 "No icons defined for continuous focus!" :227; 求值 idx < 0 → 断言 "Icon evaluation failed to return a valid case!" :233; 返 +128 + 40×idx; 两失败路径均返静态默认条目 qword_143330CA8。调用方 = sub_140B41760 (效果/触发执行域); 断言总门 = byte_1435E1B51 (与 advisor/combatmanager 的 B52 异位)。

未决: def+752 串缓存写归属 (CModifier 内部名缓存 vs def 独立域) / sub_1406C2550 直调方 / 邻件 sub_1406C23A0 (调全国家 palette 选择, 无 cpp 锚, 身份待裁) / 树侧 +40 FNV 的 reader 直证 (§4.3.15 树表行)。

#### 4.3.25b to_use 三池消耗/释放协议 (trade.h 5 函闭环; 产线资源链)

簇清册 (体内 cpp 锚 5/5; 0/5 原 VA 级收录, 全部本批新定):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_14193A460 | 424 | equipment_production_line.cpp:653 + gamestate.h:1125/1126 + trade.h:554 | CEquipmentProductionLine 资源消耗更新主函数 |
| sub_141937BB0 | 94 | trade.h:554 + production_line.h:224 | 产线消耗批量释放 (独立函数版, 10 调用点) |
| sub_140E5AAB0 | 108 | trade.h:541 | 消耗登记原语 ("Consuming %s of resource %i for %s") |
| sub_140E5A100 | 63 | trade.h:554 | 单条释放原语 (Releasing 同串) |
| sub_140CA53E0 | 43 | trade.h:164/165 断言对 | 护航可用率 16B 对 setter {AvailabilityConvoyEfficiency@+0, ConvoyEfficiencySunkMultiplier@+8}, 断言 [0, 1_fixed] (闩 byte_14333CB4C/4D, B52 门) |

to_use 三池「负量记账」协议 (定案):

| 项 | 定案 |
|---|---|
| 消耗方向 | 池 += 负量 (sub_1424EF6F0 取负); a5 = 0 同时扣池[1]+池[2], a5 = 1 只扣池[2]; out = 实扣 = min(请求, 池可用) |
| 释放方向 | 池[2] += 正量 (实扣+欠账之和, 向上取整 1e5); **产线每 tick 先全额返还再按新配方重扣** |
| 条目形态 | 32B {消耗者对象*@8 (+16 有效 byte), 实扣 i64@+16, 欠账 i64@+24} (count@+100); 欠账 = 请求 − 实扣 |
| 净额语义 | P2 = 当前被产线占用量 (负数记账) — §4.3.25 活体「P2 负值累计」自洽 |
| 消费者 | 0x14193A460 (a5=1, 产线) / 0x140E6AE80 (a5=1, **煤预留+电力覆盖率写者** — 语料全读: ps+1256 三元组 + coverage 写四工厂池, 旧记"特殊项目"系误标) / 0x1414830F0、0x141482020 (a5=0, 第三类池宿主; 0x1414830F0 = 特殊项目真身, 宿主链 cc+4008 → NProject::CProjectPool 直证) |
| RTTI | 0x141933EA0/0x141934030 体内 `CEquipmentProductionLine::vftable'` 符号直证 |

**主函数链** (sub_14193A460): gamestate 门 (TLS 禁入) → gs+2613 世界就绪门 → vtable[11] 规模取值 + a1+192 数组扩容逐元素钳 [带, 上界 = 1e5 × dword_143336790 + 100 × modifier(171, cc+1464)] (dword_143336790 不在 defines 表, 定名未决) → a1+40 = 基速 × (1 + modifier(0)/1e5) → rs = *(cc+4600) (:653 断言 pCountryResources) → **清算段** (遍历 a1+88 条目, (量A+量B) 取整返还池[2] + Releasing 日志 + bump 戳[2], 与 sub_141937BB0 逐指令同构) → **重扣段** (配方 = vtable[28] 容器 16B 元 {量, 资源 def id@+8}; 逐条库内索引 sub_140AC1F80 → 需求 = 配方量 × *(a1+24) × (1 + modifier(4)/1e5) → sub_140E5AAB0 消耗登记 → 条目 +16 = 实扣 / +24 = 欠账) → 缺口结算 (sub_141936210 逐条取 max; a1+216 = min(0, 缺口 − modifier(5)) 饱和负差) → 通知 + SetSpeed。

**代数戳对账快照宿主 (两例定案)**: ① 0x140E71350 (特殊项目消耗管理器): a1+1194..+1199 三 WORD 逐戳对 rs+1096/+1098/+1100, 差一置脏 → 重释放/重扣, 尾部回写快照; ② 0x1414830F0 (第三类池宿主): v1+248 = {u32 ← rs+1096, u16 ← rs+1100} 同型打包快照。§4.3.25 rs+1100 行原「生产侧 6B 快照」宿主至此定位。

**护航可用率对装配** (sub_140CA9C70, setter 唯一调用者): clamp(1e5 × 可用量 / 覆盖基, 1e5) → sub_140CA53E0 落 §4.3.25a 公式族邻域; trade.h:164/165 字段名直证 16B 内嵌对全名。

未决: dword_143336790 与 dword_143334180 定名 / 特殊项目消耗管理器与第三类池宿主类名 / qword_14332F698 vtable[37] 情报视图宿主 / a5 = 2 防御路径 (pool[3] 越界读推定死路) / 生产域辅助族 sub_141936210/1419364B0/1419360B0/141938100/1419382D0 未深读。

#### 4.3.28 核弹落地结算运行期 (nuke.cpp; 3 实现体 + 结算互证 — §4.3.10a 九步的实现体落位)

簇清册 (体内 cpp 锚 3/3; 九步主函 sub_1410986E0 已收, 本批互证 + 三实现体):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_141097DC0 | 47 | :504/:506 rand loc-id | 核弹单位双掷伤害 roller |
| sub_141099D50 | 88 | :553 断言 "Country thinks it has access to an airbase…" | 场站驻机全灭 (基地侧) |
| sub_14109A2A0 | 119 | :583/:586 scope 名 | on_nuke_drop + 成就 + 视效发射器 |

**伤害 roller** (sub_141097DC0): **dmg = MIN + rand%101 × (MAX−MIN) / 100**, 两独立 roll 分配 STR/ORG; define 对定名: 常规 = **NUCLEAR_BOMB_MIN/MAX_DAMAGE_PERCENT** (qword_1433338F8/1433339A8); tier == 1 → **THERMONUCLEAR_BOMB_MIN/MAX** (qword_143333A58/143333B18) (书「tier==1 cmove 双槽」的具名); 海军单位 (+8 == 1) 跳过; 伤害经单位 vtable 槽[25] 入账, 尾参 = 投弹国 tag。

**场站驻机全灭** (sub_141099D50): 有权国 tag 表逐国 access 门 (sub_140C57400) — 假 → :553 断言 (书断言号实现体); 真 → 驻留块 → 逐 wing sub_140F63580(wing, wing+124, 投弹国 tag) 销毁。上层 = sub_141099C60 (tier 分流同 roller)。

**on_action 发射器** (sub_14109A2A0): on_nuke_drop **THIS = 投弹国 scope / FROM = 被炸州 scope** (§4.3.10a ⑧ 方向已按此改定) + 成就 (管理器 vtable[23] → sub_140B685F0) + 视效 (vtable[16] → sub_140B53EE0(省 id) → sub_1412905A0(条目, tier) — 书 ⑨ tier 选 entity 实现体); 结算尾直调。

互证: 主函 sub_1410986E0 九步锚全对; 内部链 = roller + 驻机全灭 + 免损三旗 + 本发射器; 库存侧 sub_141097D50 (DailyUpdate 内, 书互证)。

未决: 免损三旗第二段 sub_141097F40 未整读 / 单位收集容器宿主。

#### 4.3.29 力量平衡装载与 reader (power_balance_database 3 函 + power_balance.cpp reader; 4 函闭环 — §4.3.21/22 的装载侧与 reader 补全)

簇清册 (体内 cpp 锚 4/4):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_140A8E210 | 246 | :275 "Template ID duplicate" | power_balance 库装载器 (RH stride 456) | 新 |
| sub_140A8E5D0 | 225 | :211 "Range ID duplicate" | Template range 名索引重建 + 重名检查 | 新 |
| sub_140A8EDD0 | 152 | :187 | CPowerBalanceTemplate reader (8 键) | 已收身份, 本批键表补全 |
| sub_140E57540 | 259 | :466/:481/:491 三断言 (B52, 闩 byte_14333D14A/B/C) | **CPowerBalance reader (书原缺 reader VA)** | 新 |

**装载器** (sub_140A8E210): RH 表 stride 456 {hash@0, dist@4, 键串@8, 值 408B 内嵌@48} (§4.26 互证零冲突); 重复键 → 格式化错误日志不中断; reload 路径 = 逐条目析构清表再遍历目录。**range 索引重建** (sub_140A8E5D0): 两源收集 (模板 ranges + 逐 side 内 ranges) → 40B 条目表 {串, hash} 查重。**Template 全布局定案 (408B)**: +56 decision_category 串 / +96 initial_value / +104 left_side / +144 right_side / +184/+272 双 CEffect(88B) on_activate/on_deactivate / +360 ranges 向量 (1856B 元) / +384 sides 向量 (288B 内嵌)。键集与 Side reader 同 token 复用 (模板层与侧层共享键命名空间)。

**CPowerBalance reader 8 键** (sub_140E57540; 与书 §4.3.21 主表逐项吻合 — reader 反向补全写门): 776 value→+48 / 10597 modifier→+80 指针向量 / 11593 countries→+56 / 15559 left_side→+24 / 15560 right_side→+32 / 15563 trending_side→+40 / 15565 sides→+376 (80B SideInfo 列表) / 19482 template→+16。**失效自愈**: side 键解析失败按模板默认侧名 (left_side/right_side 串) 重查 — 存档缺侧可自愈。set_power_balance_gfx (sub_140E57EF0) 展开证实 = 书「高置信对应」升格定案 (条目下标族 sub_140E564D0 与指针族 sub_140E56ED0 不同族; SideInfo gfx@+48 覆写; sub_140E53970 = SideInfo 追加 helper 登记)。find-or-add 全链: entry = *(sys+8) + 400×idx + 376 (sides 向量头, count@entry+388); 侧匹配 = elem+40 FNV ci-hash 等 ∧ elem+8 id SSO stricmp; 未命中 → sub_140E53970 push (1.5× 扩容, ctor sub_140E55020, hash 由 a3+32 透传); 命中/新建后写 gfx@elem+48 (sub_140129CA0 SSO 串赋值)。

未决: range 重建函数vtable槽位 / 工厂 case↔策略 id 映射 (§4.34.27) / trending 失效回退 sub_140E58B20 语义。
