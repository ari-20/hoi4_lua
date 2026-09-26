

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

| 偏移 | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| +8 | uint32 | tag_id | |
| +12 | tag_id | **last_collaborated_surrender_recipient** (writer sub_1407191B0 门 >0 → sub_140BB4E70 取 tag 名串, 键 19368; reader case 19368 → sub_140BB5560; 复位 sub_1406E2DE0 置 0) | 写门 >0; 落盘形 = 引号 tag 名 |
| +16 | MSVC 串 32B | **name 缓存** (本地化全名; sub_140716580 名称缓存刷新 = tag (或 +4876 original_tag>0 优先) + 意识形态 + cosmetic_tag(+5256) 组合本地化键渲染; 调用方 = 外交/GUI 全域 16 处) | 不序列化 (定案; 探针 GER="德意志帝国") |
| +48 | MSVC 串 32B | **adjective 缓存** (TAG_ADJ, "_ADJ" 常量参与构造; cap@+72=15) | 不序列化 (高置信; 探针 GER="德国") |
| +80 | MSVC 串 32B | **definite name 缓存** (TAG_DEF, "_DEF" 常量; surrender 拷贝它做消息文本; +84/+88 = buffer 内部, size@+96, cap@+104=15) | 不序列化 |
| +112 | CNameGroupTracker* | division_names_tracker (mode 0) | §4.3.8 起; vt 0X2935BB8 (探针+RTTI) |
| +120 | CNameGroupTracker* | ship_names_tracker (mode 1) | writer ADEC0 0x3C85 (定案) |
| +121..+127 | — | = +120 指针尾字节 (无独立字段) | |
| +128 | CNameGroupTracker* | railway_gun_names_tracker (mode 2) | writer 键 0x3463, 门 *(cc+128)≠0 |
| +129..+135 | — | = +128 指针尾字节 | |
| +136 | CNameGroupTracker* | operative_codenames_tracker (mode 3) | writer ADEC0 0x3D19 |
| +144 | MSVC 串 32B | **prev_name** (改名前上一代 name 副本; sub_140716580 尾段: 新值≠旧值时落旧值) | 不序列化 (高置信; 探针 GER 三串均空=未改名) |
| +176 | MSVC 串 32B | **prev_adjective** (同上) | 不序列化 |
| +208 | MSVC 串 32B | **prev_definite** (同上) | 不序列化 |
| +240 | 容器 24B | cached trade influence 数组 {data@240, cap@248, count@252, alloc@256} — 8B 值, 按下标 *(obj+4) 取 (探针 GER cap=count=333=全局 tag 槽数; Reset 按 gamestate vt+72 扩容) | 断言 "Trying to get cached trade influence before it exists" (sub_1406EC770) |
| +252 | uint32 | 上述数组计数/有效位 | if(*(a1+252)) 门 |
| +264 | uint8 | _HasCachedTradeInfluence 旗 | 断言原文 (sub_140712930/1406DAAF0) |
| +272 | u8 | 运行时旗 (+272/+280 各一枚 u8 旗; ctor 零填; 消费按字节读, 三处 — 语义待裁; **全量国家双槽恒 0**, 与 +5209/+5210 major 族不同义) | 不序列化 (定案) |
| +288 | u32 | 运行时字段 (ctor/0X1406E2DE0 置 0; 无读点, 未决) | 不序列化 (定案) |
| +292 | u8 | 运行时旗 (ctor 唯一写点 = 0, 无读点, 未决) | 不序列化 (定案) |
| +296 | 容器 24B | **OOB 待加载队列** {data@296, cap@304, count@308, alloc@312} — 72B 元 {串@+40}; 0X140702E70 遍历调 LoadOOB (拼 "history/units/<名>.txt" → vt+24 Parse); 门 = owned_states(+1156)>0 或 tag≤0 | 不序列化 (高置信; 探针 GER count=0) |
| +320 | MSVC 串 32B | **当前 OOB 文件名** (LoadOOB 写入 "history/units/X.txt" 路径) | 不序列化 |
| +352 | CNavyTheater* | 海军剧场 | vt 0X29D2B88 (探针+RTTI) |
| +360 | CTheatre** | theatres 容器数据指针 — writer 壳 `if((cc+372))` 计数>0 才整块写; 舰队在 +632/+644 | §4.24 |
| +368 | uint32 | theatres 容器 cap | loader case 12217 增长码 {data,cap,count,alloc} |
| +372 | u32 | theatres 容器计数 | §4.24 |
| +376 | 指针 (allocator) | theatres 容器 allocator | 同上 |
| +377..+383 | — | = theatres 容器 alloc@+376 指针尾 (四元组 {data@360, cap@368, count@372, alloc@376} 到齐) | |
| +384 | 指针数组数据 (8B 元) | **air_theatre 指针数组数据** | writer 尾段 ADEC0 0x4DED 循环 + 断言 "Trying to remove air theatre…" (sub_1406E8C90) |
| +396 | u32 | air_theatre 计数 | 同上 |
| +400..+431 | — | = air_theatre 容器 alloc@+400 (四元组 {384,392,396,400}) + **侵入式串链表 24B@408** {head@408, tail@416, count u32@424, u32@428} (节点 {buf 16B, cap@16, size@24, next@40}; dtor 逐节点 free = sub_14061C4F0; 运行时-only, 业务名未决) | |
| +432 | u32 | **instances_counter** (可定制建筑实例计数器; writer 键 12464 **恒写**; loader case 12464 读而弃之; 与 +436 无伴生门关系; 探针 GER=1022) | 定案 |
| +436 | u8 | templates_locked (仅真写; 兼 reason 串门: 门开则 MSVC 串@cc+464 **空串照写 `""`**) | |
| +440 | CDivisionTemplate** | 编制模板 id 容器数据 | **GUI: TemplateChanger 可改编模板列表源** (锁+过时+HQ 三滤; sub_14169D590) **+ 驻军模板列表** (占领驻军窗 [2] 0X14156C940) |
| +441..+451 | — | = 编制模板容器尾 {cap@448} | |
| +452 | u32 | 编制模板 id 容器计数 (MIO 关联区) | |
| +453..+463 | — | = 编制模板容器尾 {alloc@456 = &off_143085170 哨兵} | |
| +464 | MSVC 串 32B | **templates_locked reason 串** {buf@464, size@480, cap@488=15} | 定案 |
| +496 | fixed×1e-5 | command_power | §4.3.11 country_fields; **GUI: HQ 部署 CP 行** (populate 缓存 view+17744; HQ_DEPLOY_CP_COST) |
| +497..+503 | — | = command_power@+496 尾 — +496 实为 **i64×1e-5 8B 定点** (消费 sub_1406EAE40 记账) | |
| +504 | int64 | **战斗力分配池** (与 +496 联动记账) | 断言 "pCombatPowerAllocator->GetAllocator == this" (sub_1406EAE40, country.cpp) |
| +512 | CCommandPowerAllocator** 向量 | 战斗力分配条目容器 {data@512, cap@520, count@524, alloc@528} (分配器类 ctor sub_1414E6F40, 56B+; 入表 sub_140714830 `*(*(cc+512)+8*(cc+524)++) = a2`, 1.5× 增长; 出表 sub_1406EAE40; 消费 12+ 处; 不序列化) | |
| +536 | CVariables* | 国家脚本变量 (variables 族, reader country_variables73) | §4.3.8 起 |
| +544 | 8B (双 u32 hash 种子) | scripted_gui_random — writer ADFE0 0x3D64 裸整数; loader case 15716 双写 +544/+548 双 hash 混合态 | §4.3.8 起 |
| +552 | CCountryAI* | AI state 挂链: csa = rp(rp(cc+552)+2800)+2800; 本指针 vt 0X2736CA0 (探针+RTTI); 挂链末段 +2800 = CStrategicAI 内部 CPersistent 基子对象 (vt 0X27E2088; 本体 vt 0X27E1FB8, sizeof 9016), 非再次解引用; 部长八指针与 AI 主干见 §4.34; 挂链容器见下四行 | §4.3.8 起; §4.34; writer 0X14066B3F0 |
| csa+144 | int32 向量 | ai_strategy 平行数组 A — 112 槽, data@csa+144+24i (= base+2944 起, 帧约定见 §4.34.5); 条 12B {value i32, target u32, id u32}; id 仅槽 9/16/21 写 token 名 | writer 0X14066B3F0 |
| csa+2832 | 匿名结构 (元素待裁) 向量 | persistent_strategy 平行数组 B — 112 槽, data@csa+2832+24i (= base+5632 起; 与 A 同条结构) | writer 0X14066B3F0 |
| csa+5520 | 匿名结构 (40B 计划条目) 向量 | **allowed_strategy_plans** {d@csa+5520, c@csa+5532} (= base+8320) — 元素 40B {计划名串 32B, +32 u32 计划库下标}; **运行期唯一写者 = 日更重建 sub_140664C10** (遍历 CAIStrategyPlanDatabase, 条目+72 触发器对国家 scope 求值); Save/Load 键 15260 | §4.34.11 |
| csa+5664 | CAIResearchNeed | 科技完成/效果注入 need 聚合 (= base+8464; 访问器 sub_14064D200) | §4.34.6/§4.34.9 |
| csa+5696 | i32 | days_to_need_update (日更开头清 0; Save 13445) | §4.34.11 |
| csa+5700 | i32 | days_until_next_rebuild_access_list (日更 −1, ≤0 重置 rand%5+5; Save 13443) | §4.34.11 |
| csa+5808 | uint32 向量 | military_access {d@csa+5808} — 440×u32 | |
| csa+5856 | 匿名结构 (元素待裁) 向量 | **vector\<CAIFocus\>×9 焦点类别权重表** (= base+8656; 72B 槽 {vt, weight i64@+8, CAIResearchNeed@+16, 引擎向量@+48}; 九类实名见 §4.34.11) | §4.34.11 |
| csa+5880 | token 向量 | **历史焦点列表** {d@csa+5880, cap@csa+5888, c@csa+5892} (token u32 向量; ai_historical_focus_list; cnt>0 时 DecideFocus 走历史路径) | §4.34.10 |
| csa+5904 | CAIResearchNeed | focus 类目+计划+科技 need 聚合 (= base+8704; 日更清零重算, 写经 sub_1413C5260; 打分读入口 sub_1406516E0) | §4.34.6/§4.34.9 |
| csa+5936 | 双 u32 | AI 私有种子 (xorshift 状态; 日更重掷; Save 10647) | §4.34.11 |
| csa+5960 | i32 | **irrationality 非理性度** (−1 = 未掷; 日更 sub_140652A00 一次性掷点, 溢出断言 ai_strategy.cpp:4457; 读点 = GetIrrationality 访问器 + 决策门 sub_14108F750) | 定案 |
| csa+5965 | u8 | **战略首轮就绪旗** (= base+8765; 宿主 = CStrategicAI **定案**, 20 处访问全经 GetStrategy sub_1401DBCE0; UpdateStrategy 末置 1 / 全局复位 sub_1406539F0 清 0; AI 模块日/周更首判门 — **非人控判据**, 人控门 = byte_14332F639) | 定案 |
| csa+6064 | 匿名结构 (元素待裁) 向量 | 他国战力/威胁缓存 (日更逐国写 4B×i; 本国 0) | 推定 |
| csa+6132 | i32 | **num_wanted_divisions** (= ai_wants_divisions; −1 = 未算; 计算 sub_140650CC0, 细化数组 csa+6136..6160; UI "Nr Wanted Divisions: %i" 直证) | 定案 |
| +560 | CFlagManager* | **国家脚本旗 store** (set/country_flag 族落点; 解引用后 {entries@+8, count@+20}, 条目 48B {token@+8, setdate@+24, value\|expiry@+40} — country.flags savefull 直出同构; ⚠ flag token 取值 = 全 lexer 域（mod 旗在 lexer 扩展段，读侧上界必须用 lexer_token_max 运行时值，非原版 10 万界）) | vt 0X295D3D8 (探针+RTTI); 布局高置信 |
| +561..+567 | — | = CFlagManager 指针尾 | |
| +568 | CGameDate 内嵌 24B | {vt1@568, hours@576=43808760 ctor 哨兵, vt2@584} — **pride_of_the_fleet 关联日期** (与 +600 date_lost 成对; 复位 sub_1406E2DE0 尾置 +592 与 +608) | 不序列化 |
| +592 | u32 | pride_of_the_fleet.type — id 对之 type (id 对 {id@+596, type@+592}; 初值 = **qword_14333D528 全局 8B 拷入**) | §4.3.8 起 |
| +596 | u32 | pride_of_the_fleet.id — id 对之 id | §4.3.8 起 |
| +597..+607 | — | = pride_of_the_fleet id 对 {type@592, id@596} 尾 (ctor 整 qword 拷 qword_14333D528) + **第二 CGameDate@600** 头 | |
| +608 | hours | pride_of_the_fleet_date_lost (哨兵 43808760 照发) | §4.3.8 起 |
| +609..+615 | — | = **第二 CGameDate {vt1@600, hours@608=43808760 哨兵, vt2@616}** 的内部 (+608/+616 = 同一日期对象的 hours/vt2); dtor 将两日期 vt 复位 CGregorianDate 基 vt (CGameDate⊂CGregorianDate) | |
| +616 | vptr | 第二 CGameDate vt2 — ADEC0 序列化代理 (规则: hours = arg−8); 与 +608 同字段 | 定案 |
| +617..+631 | — | = 第二 CGameDate vt2@616 尾 + **u8@624 日期伴生旗** (ctor 显式零填; 语义未决) + 填充@625..631 | |
| +632 | CTaskForce** | 舰队 容器数据指针 | §4.16; **GUI: B13 navy 页汇总行** (cc+632/{+644} 逐元聚合 {键, 数}; 面板 vt[2] 0X141ECCCA0 → sub_140D230E0; 语义推定舰型汇总, 未决) |
| +633..+643 | — | = 舰队容器 {data@632, cap@640, count@644, alloc@648} 内部 (ctor sub_14011DF40 + dtor 擦除) | |
| +644 | u32 | 舰队 容器计数 | §4.16 |
| +645..+655 | — | = 舰队容器 count@644 尾 + alloc@648..655 | |
| +656 | CArmy** | 师列表 容器数据指针 — {data, count} | §4.18 |
| +657..+667 | — | = 师列表 {data@656, cap@664, count@668, alloc@672} 内部 | |
| +668 | u32 | 师列表 容器计数 | §4.18 |
| +669..+679 | — | = 师列表 count@668 尾 + alloc@672..679 | |
| +680 | CRailwayGun** | 铁路炮 容器数据指针 | |
| +681..+691 | — | = 铁路炮 {data@680, cap@688, count@692, alloc@696} 内部 | |
| +692 | u32 | 铁路炮 容器计数 | |
| +693..+727 | — | = 铁路炮 count@692 尾 + alloc@696..703 + **未名指针元素容器 24B@704** {data@704, cap@712, count@716, alloc@720} (元素 8B 指针, dtor 经 vt+16 释放; writer/loader 不序列化; 语义未决; **空态: 全量国家 count 恒 0**, 非空分支未证) | |
| +728 | 内嵌 | cached_navy_strength: {d@+736, c@+748} 8B 元素 {舰种 token, 数量} (宿主 vt = CNavyStrengthCache::vftable, 类名直读) | §4.3.8 起 |
| +729..+759 | — | = CNavyStrengthCache (vt 0X27E71D0) vt@728 尾 + **容器 {data@736, cap@744, count@748, alloc@752}** 四元组补齐 | |
| +760 | 内嵌块 | expeditionaries_sent 容器块 {count@+772}; writer `if(*(a1+772)) sub_1406C8960(a2, 13427, a1+760)` | §4.10.19 |
| +772 | u32 | expeditionaries_sent 计数 (写门) | 定案 |
| +773..+783 | — | = expeditionaries_sent 容器 {data@760, cap@768, count@772, alloc@776..783} = count 尾 3B + alloc | |
| +784 | 内嵌块 | volunteers_sent 容器块 {count@+796}; writer 键 13426 | §4.10.19 |
| +796 | u32 | volunteers_sent 计数 (写门) | 定案 |
| +797..+807 | — | = volunteers_sent 容器 {data@784, cap@792, count@796, alloc@800..807} = count 尾 3B + alloc | |
| +808 | CCountryManpower (内嵌 40B) | **人力块宿主** — 布局见下行; writer 0X140CFE9D0 ratio>0 才写 | §4.3.8 起; **GUI: Reorg confirm 人力门** (sub_14202C760) |
| +809..+847 | — | = CCountryManpower (vt 0X295EB90) 本体: {vt@808, tag u32@816 (=cc+8), manpower.current u32@820 (键 11125), **ratio qword@824 (键 694**; GER 250000/ENG 105000/SOV 154500), exile u32@832 (键 15036; >0 才写), max u32@836 (键 15047), 尾 qword@840 (= 库块 sub_140CFA0F0 +32 拷贝, 与 +816/+820/+824/+832/+836 同批从库块拷入; writer 不写)} | |
| +848 | CCountryColors (内嵌) | **颜色/外观对象 #1** (vt+32 finalize; loader 键 11450 解析入 +848; 化妆 tag 解析 sub_1401DB180) | **GUI: 阵营成员行色源** (sub_1406ECF80(cc) = 沿 CDiplomacyStatus(+848 色 obj/+392 宗主 tag) 爬宗主链取色 getter — 返回+32 = cc+880 行色, 返回+16 同 rgba = 阵营默认色种子; 非新字段) |
| +849..+879 | — | = CCountryColors#1 vt@848 尾 + **间隙 8B@856** + CColor#1 vt@864 尾 + **CColor +8 间隙@872** (rgba@880 已知) — 两间隙 ctor/dtor/writer/reader 全域不触, 推定 = MSVC 对齐填充 (CColor 16B 对齐使 rgba 落 +880 需 8B 垫) | |
| +880 | 4×f32 | **color** (16B 色值) | 复制对 +976 |
| +881..+911 | — | = rgba@880 尾 15B + CColor#2 vt@896 + **+8 间隙@904..911** | |
| +912 | 4×f32 | **color_ui** (第二 16B 色值) | 复制对 +1008 |
| +913..+927 | — | = rgba_ui@912 尾填充 15B | |
| +928 | uint8 | 颜色旗字节 | 复制 +1024 |
| +929..+943 | — | = flag@928 后尾填充 15B | |
| +944 | CCountryColors 内嵌 #2 | **原始副本宿主** (+944..+1039: vt@944, rgba@976, rgba_ui@1008, flag@1024) | ctor 定案 |
| +945..+975 | — | = CCountryColors#2 vt@944 尾 + **间隙 8B@952** + CColor vt@960 尾 + **+8 间隙@968** (rgba@976 已知) | |
| +976 | 4×f32 | color **原始副本** (化妆 tag 应用前快照) | 高置信 |
| +977..+1007 | — | = rgba@976 尾 15B + CColor#2 vt@992 + **+8 间隙@1000** | |
| +1008 | 4×f32 | color_ui **原始副本** | 高置信 |
| +1009..+1023 | — | = rgba_ui@1008 尾填充 15B | |
| +1024 | uint8 | 颜色旗 **原始副本** | 高置信 |
| +1025..+1063 | — | = flag@1024 后 Colors#2 尾填 15B + **owned_provinces {data@1040, cap@1048, count@1052, alloc@1056}** | |
| +1040 | 容器 24B | **owned_provinces 缓存** {data@1040, cap@1048, count@1052, alloc@1056} — u32 省 id (**不序列化**; neighbors 计算第二源; 探针 GER count=300) | 擦除 0X14070FB90 / 空查 0X1406FCFA0 / getter 0X1406D1DF0 |
| +1064 | 匿名结构 (NNB 形状)* | **controlled_provinces 数据** (u32 省 id 数组) | AddControlledProvince sub_1406D00A0 dup 查 *(prov+164) 后插入 |
| +1076 | u32 | controlled_provinces 计数 | 同上; **GUI: 世界紧张度战争行 投降进度门** (CWorldTensionWarEntry) |
| +1077..+1087 | — | = controlled_provinces {data@1064, cap@1072, count@1076, alloc@1080..1087} = count 尾 + alloc | |
| +1088 | int64 | **首都控制区 BestVP 省缓存** (-1=无) | 断言 "Country with no province worth any VP in capital controller area" (sub_1406D9350) |
| +1089..+1119 | — | = BestVP@1088 (i64=−1) 尾 + **未名指针元素容器 24B@1096** {data@1096, cap@1104, count@1108, alloc@1112} (元素 8B 指针, dtor 经 vt+16 释放; 不序列化; 语义未决; **空态: 全量国家 count 恒 0**) | |
| +1120 | CState** | **controlled_states 数据** (vector<CState*>) | SetController sub_1409DDA40 推入/移除 |
| +1132 | u32 | controlled_states 计数 | 同上 |
| +1133..+1143 | — | = controlled_states {data@1120, cap@1128, count@1132, alloc@1136..1143} = count 尾 + alloc | |
| +1144 | CState** | **owned_states 数据** (vector<CState*>, 本国拥有州表) | SetOwner sub_1409DE560 对新主 sub_1406D1DF0 查重推入并重建 cc+1040 owned_provinces 缓存 + cc+4932 owned points, 对旧主 sub_14070FB90 移除并擦缓存 (双向配对); all/any_owned_state (GUI 串 TRIGGER_*_OWNED_STATE) 直遍历之; AddContestedState (sub_1406CFF30) 只推 +1168, 其 assert "not contested, use AddContestedOwner" 说的是州侧 contested-owner 属性门槛非容器名 (assert 曾被误作容器命名证据) |
| +1156 | u32 | **owned_states 计数** | 同上; **GUI: 密码候选门** (≤0 排除; sub_141A228B0) **+ 国列表门** (与 capital cc+4120 / cc+5210 并列; 贸易过滤同键); trigger is_capital / owns_any_state_of / transfer_state 系「旧主失尽所有州」门同读此计数; **亦作 global_every_army_leader 收集器国侧门** (>0 才收集; 推定) |
| +1157..+1167 | — | = owned_states {data@1144, cap@1152, count@1156, alloc@1160..1167} | |
| +1168 | CState** | **contested_states_pending 暂存队列数据** (合入 +1144 前的暂存) | AddContestedState 先暂存, points 重算并入 |
| +1180 | u32 | 上述队列计数 | 高置信 |
| +1181..+1191 | — | = contested_pending {data@1168, cap@1176, count@1180, alloc@1184..1191} | |
| +1192 | CState** | cores 容器数据指针 — vector<CState*> 8B 州指针, 经 gs+712 反查州 id, 保容器序 (禁止排序); 与 §4.1.2 TOPC 条目非同一对象 (TOPC = gs 基) | §4.3.8 起; **GUI: 被占领国 owned states 计数** (cc+1192/{+1204} × state+204==玩家 过滤 → 州数 "x/y"; sub_14155D120) |
| +1204 | u32 | cores 容器计数 | §4.3.8 起 |
| +1205..+1215 | — | = cores {data@1192, cap@1200, count@1204, alloc@1208..1215} | |
| +1216 | CState** | claims 容器数据指针 — vector<CState*> 与 cores 完全同构; c>0 才写 | §4.3.8 起 |
| +1217..+1227 | — | = claims {data@1216, cap@1224, count@1228, alloc@1232} 的 data 尾 + cap@1224..1227 | |
| +1228 | u32 | claims 容器计数 | §4.3.8 起 |
| +1229..+1247 | — | = claims count@1228 尾 + **alloc@1232..1239** + strategic_region_data 块头 **{max_load f32@1240=1.0, pad@1244}** | |
| +1248 | 内嵌 | **strategic_region_data 链式迭代表头** (侵入式链表; ctor 全布局: {f32 max_load@1240=1.0, 侵入链头节点@1248 (malloc 0x20 自链), 未决@1256, 桶@1264, 未决@1272, 未决@1280, mask@1288=7, 桶数@1296=8}; +1304/+1352/+1376/+1400/+1424 = 24B 容器×5 未决, ctor 哨兵; **+1328 = wargoal 容器** {data@1328, cap@1336, count@1340, alloc@1344} — 元+60 目标 tag / 元+64 类型, 类型 def+816 = annex 旗 (推定); **与 dip+104 available_wargoals 非同一容器** (全量 451 国计数分布: 同值 4 / 仅本侧非空 14 / 仅 dip+104 非空 1)) | writer 块键 0x39C2; 节点键 = CStrategicRegion*, 写 id@region+96; 值对象 {command_power i64@+16, more_ground_crews_enabled u8@+56, modifier 块@+64} |
| +1249..+1263 | — | = **侵入链头指针@1248** (malloc 0x20 自链节点) 尾 + qword@1256 (ctor 零) | |
| +1264 | 匿名结构 (NNB 形状)* | strategic_region_data **RH 桶数组** (16B 桶) | FNV(region)&mask 取桶 |
| +1265..+1287 | — | = RH 桶数组@1264 尾 + qword@1272 + qword@1280 (桶指针+桶哨兵+计数/容量对, ctor 全零; sub_1401F4FF0(a1+158,0x10,节点)) | |
| +1288 | u64 | strategic_region_data **hash mask** | 定案 |
| +1289..+1447 | — | = RH hash mask@1288 (=7) 尾 + 桶数 u32@1296 (=8) + **24B 容器×6** {data@1304/cap@1312/c@1316/alloc@1320} / {@1328/1336/1340/1344} / {@1352/1360/1364/1368} / {@1376/1384/1388/1392} / {@1400/1408/1412/1416} / {@1424/1432/1436/1440} — strategic_region_data 块区, 语义未决 | |
| +1448 | CModifier 内嵌 192B | **country_modifiers 块** (+1448..+1639; ctor a1[181]=&CModifier::vftable, 查表 ctor sub_140555FB0@1464; 全布局见 §4.3.8 通用表) | loader case 11577; **GUI: 共享槽基数输入** (sub_1409D4980: CState+2136 + owner 国(+1448)×类别 → shared_slot_count); **生产/密码修正族查表** (cc+1464 键: mdef 0xA9-0xD6 生产族/528-529 密码族/201-203 舰载族 — 各册消费链) |
| +1464 | 匿名结构 (16B 键值对) RH 桶数组 | country_modifiers token→i64 值查找表 (形态同 CState +1352/+1368) | 修正查表总入口 (sub_14055E360); **"daily PP" 实为指挥力**: modifier id 330-333 + define BASE_COMMAND_POWER_GAIN/BASE_MAX_COMMAND_POWER → 写 cc+496 (上限扣 cc+504 分配池) |
| +1640 | CRuleOverrides 内嵌 1016B | **第二规则覆盖对象** (+1640..+2655; 与 +2656 external_rules 同型同窗 ctor sub_140638A10, 1640+1016=2656 严丝合缝; 消费者 sub_140705AD0 全链: 清空 → 执政党 (+3984 → +208 → +24 → +96/+144 两处 sub_140638DB0) → 阵营 (dip+656 CFaction → sub_140D8A2A0) → 自治 (dip+848 → +40 → +528) → 理念表 (cc+3984+80, count@+92, 逐 `*(idea+1216)`) 四源聚合; 复位 sub_1406E2DE0 与 +2656 并列清空; **writer/loader 不序列化**) | 不序列化 (定案: **规则覆盖合成缓存** — 上述四源聚合的运行时合成版, 与 +2656 存档装载的外部规则成对非重复) |
| +2656 | CRuleOverrides (内嵌) | external_rules 宿主: 28 规则槽 i∈[0,28), 写门 = u8@cc+2656+92+i ≠ 0 (门开才写, yes/no 皆落盘), 值 = u8@cc+2656+64+i, 键名 = token_name(u32@defs+56*i+40), defs = *(BASE+53575920); **override = 28×32B MSVC 串槽 @cc+2656+120+32k** (SSO cap=15), size u64@cc+2656+136+32k≠0 才写, 键 = 槽序号裸数字 (writer sub_14063C490 AD7A0 裸串), 值 = 裸规则名 | §4.3.8 起 |
| +2657..+3671 | — | = external_rules CRuleOverrides 1016B 本体细分 (+2657..+2719 对象头 {串@+8 尾/容器@+40/u8@60}, **值槽 u8×28@+2720..+2747, 门槽 u8×28@+2748..+2775, override 串槽 28×32B@+2776..+3671**) | |
| +3672 | CDynamicModifierContainer (内嵌) | 动态修正 字段 1 | §4.3.8 起; 条目数组 {data@cc+3672+40, count@+52}, 元素 64B SDynamicModifierEntry |
| +3673..+3711 | — | = CDynamicModifierContainer 本体尾 | |
| +3712 | SDynamicModifierEntry* | 动态修正 字段 2 | §4.3.8 起; vt 探针+RTTI |
| +3713..+3831 | — | = CDynamicModifierContainer (vt 0X27D62B8, 72B, ctor sub_140556350) 尾: 条目 data@3712 尾 + **cap@3720** + count@3724 + alloc@3728 + u8@3736 + 填充 + **CModifier#2 内嵌 192B 头** (vt@3744 CModifier::vftable, 查表@3760 sub_140555FB0; 不序列化; 语义未决) | |
| +3832 | 匿名结构 (NNB 形状)* | **_pFocusPalette** (连续国策 palette 对象指针) | 断言 `!pFocus || _pFocusPalette == pFocus->GetPalette` (sub_140711430) |
| +3833..+3935 | — | = _pFocusPalette@3832 尾 + **CModifier#2 后 96B** (3840..3935, 按 §4.3.8 通用表) | |
| +3936 | CTechnologyStatus* | 科技状态 | §4.7 |
| +3944 | CProductionStatus* | 生产状态 | §4.8; **GUI: 多消费者** — 生产面板直读 (无存储 target) / 师设计装备原型池 (D+264×) / Reorg 可部署池 (+512 库存 × CAirBase+136) / B15 工厂占用条 (详 §4.8 消费链) |
| +3952 | CDeployment* | 部署 | §4.18; **GUI: 装备可用性校验表** (D+180 16B 条 × cc+3952; def+1448 并入) |
| +3960 | CReinforcementStatus* | reinforcement_priority (u32@obj+8; **写门 ≠1**, 1=默认值不落盘) | §4.10; vt 0X29D1E48 (探针+RTTI); **GUI: 增援优先级行** (CArmyReinforcementItem GetPriority = 本对象+8, 回退 1 与写门互证; 命令 = CSetCountryReinforcementPriorityCommand {+40 tag / +44 priority}) |
| +3968 | CArmyUpgradesStatus* | 陆军升级状态 (剧场) | §4.3.8 起; vt 0X29D1FF8 (探针+RTTI); **GUI: 升级优先级行** (CArmyUpgradeItem GetPriority = 本对象+8 — 升级链 = 装备升级优先级状态机; 命令 = CSetCountryUpgradePriorityCommand {+40 tag / +44 priority}) |
| +3976 | CDiplomacyStatus* | 外交 (capitulated b@+736 / cap_date hours@+752 / last_surrender hours@+696 / hosting tid@+424 / legitimacy ×1e-5@+432 / gov_in_exile_we_host {d@+400, c@+412}, writer 0X140D47400) | §4.10 |
| +3984 | CPolitics* | 政治 | §4.10 |
| +3992 | CLogisticsStatus* | **CLogisticsStatus** (logistics 19 槽队列; writer 0X141375A30, 仅人类控制国落盘) | §4.3.11; **GUI: 后勤账本行数值** (sub_141D9BFE0 → sub_141371450; 详 §4.3.11 B15 注) |
| +4000 | CDecisionStatus* (vt 0x1427EB5C0, sizeof 456; writer 0x140738AA0 / reader 0x140733A20) | **decision_status** | writer ADEC0 0x3804; 内部: 容器 {data@obj+160, count@obj+172}, 条目 **+28 = u32 state 枚举** (0 active/1 completed/2 failed/3 aborted/4 re_enable_cooldown, 见 §4.8.12) |
| +4008 | 匿名结构* | **program_status** (写 obj+8 基) | writer ADEC0 0x4010; project_pool 448B 元素 {id@+12, type@+8, name_token@+24}; **同名 project 可重复** (黄粱 sp_naval_ice_carrier 每国两条不同 id) → 发射按名 seqc 编号 (首现裸名 / 重复 [N], 同 save 侧提取器) |
| +4009..+4015 | — | = program_status 指针尾 | |
| +4016 | CCustomizableBuildingCollection* | **naval_headquarter_status** (0x58B, 双 vt; Reset 规则#52 开时按数据库重填) | writer 块键 0x49A0=18848; loader case 0x49A0 → ABB40(a2, *(cc+4016)); 定案 |
| +4024 | 匿名结构 (0x138B)* | **equipment_market** (指针非内嵌; ctor sub_1413B6EB0(cc, production, logistics, incoming_diplo, diplo)) | loader case 15103; daily 更新; **GUI: 市场清空按钮目标** (CMarketStockpileClearCommand 10191 → \*(cc+4024) → sub_1419D6F20) |
| +4025..+4031 | — | = equipment_market 指针尾 | |
| +4032 | 匿名结构* | **intelligence_agency** 机构对象 (+288 = CCryptology\* 密码学部门态, ctor sub_1413F61D0 — UI 密码学视图数据源) | writer ADEC0 0x3D32; **GUI: 机构面板目标** (AgencyView @48[9] 0X140F2F3A0 现取; 省点击转发 → CCryptologyView+48) |
| +4032→agency | COperativeLeader* | gfx = MSVC std::string **@e+256** (writer 链定案; e+192 恒 nil, 实机 4/4 对照); mission.state 仅 build_intel_network(1)/root_out_resistance(4) 写, counter_intelligence(3) 只有 target | 导出键 `intelligence_agency.operative[N].gfx` / `.mission.<type>.state`; 类型 5-8 口径未决 |
| +4033..+4039 | — | = intelligence_agency@4032 指针尾 7B (ctor a1[504]=0) | |
| +4040 | CLoopHistory* | **CLoopHistory** (0x38B, ctor sub_141516640(5,0)+sub_141516990(·,1); country.history 三队列族; writer L863 ADEC0(0x2835)) | §4.3.11 |
| +4048 | CCountryOccupationStatus* | **CCountryOccupationStatus** (0x128 字节, vt 0X142982CF0 RTTI 定名); 序列化 writer 0X141000120 — ⚠ a1 = occ+24 基差 24 (division_template_id reader+120 ↔ writer+96 同证) | §4.3.8 起; **GUI: 占领面板数据源**; 布局/日志条目详 §4.3.2 |
| +4056 | CCountryCollaborationStatus* (vt 0x1429BCC68; 条目 24B = **CCountryCollaborationData**, vt 0x1429BCC18, 槽[2] writer 0x1413F5C70 / [4] reader 0x1413F53A0) | **collaboration (0x4BB0)**: {data@+40, count@+52} 8B 指针数组, 条目 CCountryCollaborationData 24B {vt@0, tag tid u32@+8, value i64×1e-5@+16} (ctor 0X1413F46E0 malloc 0x18; body writer 0X1413F5C70 AE590(776,+16)); 外层块嵌套同名两层 (国家 writer sub_1407191B0 ADEC0(0x4BB0, cc+4056); body 0X1413F5C90; reader 0X1413F53C0), 内层键 = occupier tag — ⚠ 挂载 cc+4056, 非 +4048 occupation | §4.3.8 起; **GUI: 战争盟友行 collaboration 图标** (CWarAllyItem: count@+52 消费) |
| +4064 | 匿名结构* | **country_reports** | §4.11.14; writer ADEC0 0x4BC3 |
| +4072 | 匿名结构* | **intel** | §4.11; writer ADEC0 0x30EC; loader case 12524 同 |
| +4080 | CCountryCharacters* | **characters 宿主 (0x138 堆对象, ctor malloc 双调用点直证; vt 0X14298AE18, 活体探针 + ASLR 换算 + RTTI 名三证; ctor sub_1410E8A20 / dtor sub_1410E8C70); writer 块键 0x4C14; 断言 "Unit leader without a character" 互证; 8 张指针表; ⚠ sub_1411867E0 = 任命资格校验器 (技能门槛+理由串), 与本对象无代码关系 | §4.4; 内部表见下; **GUI: 阵营指挥官窗候选列表** (Repopulate sub_141BFA2A0; EFilterFactionCommanders 掩码 15 @win+4504) |
| chars+16 | 容器 | status {d@+16, count@+28} | 16B 元素 {status ref ptr@+0, flags u32@+8}: bit0 country_leader / bit8 advisor / bit16 unit_leader / bit24 scientist |
| chars+40 | 容器 | retired {d@+40, count@+52} | 元素同构 |
| chars+88 | 容器 | appointed_advisors {d@+88, count@+100} | advisor slot 串 @advisor+128; character id 对 = 打包 qword (低32 type, 高32 id); recruit_scientist ref 壳打包 qword 同构 |
| chars+112 | CUnitLeader** | 候选表#1 {data@+112, count@+124} (阵营指挥官窗; GER 活体 27 人) | |
| chars+136 | CUnitLeader** | 候选表#2 {data@+136, count@+148} (GER 活体 12 人) | |
| chars+160 | 指针数组 | **在聘科学家表** (CScientistList roster 模式数据源) | |
| chars+184 | — | 链表头 | |
| chars+200 | COperativeLeader** | 表 (键 15702) | |
| chars+224 | CScientistRecruitmentPool (内嵌) | 招募池 {data@+232, count@+244} (recruit 模式) | |
| chars+256 | 匿名结构 (NNB 形状)* | 第二回指 | |
| +4088 | 内嵌 | **incoming_diplomatic_action**; writer ADEC0 0x3D0E | §4.10 |
| +4089..+4095 | — | = incoming_diplomatic_action@4088 指针尾 7B | |
| +4096 | SInvasionReport* 数组 (vt 0x1429D2950; writer 0x1415165C0 / reader 0x141516410) | invasion_report 容器数据指针 {cap@4104, count@4108, alloc@4112 哨兵} — (指针数组) | 元素: tag tid@+8 / enemy tid@+12 / province=*(e+16)+164 / date hours@+40 (CGregorianDate 24B @+32); +24 = *(province+200) 装载快照 (高置信) |
| +4108 | u32 | invasion_report 容器计数 | |
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
| +4208 | uint8* | **neighbors 位图#1** {data@4208, 未决@4216, n@4220} — 字节/国 (探针 GER n=333=tag 槽数); 重算 = sub_14070AF30 遍历 **controlled_provinces(+1064)** → 省静态描述符(+184) 邻接表(+112, 48B 元, id@+8) → 邻省 **controller(+392)** ≠ 己者去重入位图1/列表1; 控区变更后刷新 (0X1406EAB50/0X1406FF1F0/0X140E801A0) | 不序列化 (高置信) |
| +4232 | 容器 24B | **neighbors 列表#1** {data@4232, cap@4240, count@4244, alloc@4248} — u32 tag (断言 "Asking if X is a neighbor of Y…" country.h; **探针 GER count=11** = 德 1939 邻国信度锁死) | 不序列化 |
| +4256 | uint8* | **neighbors 位图#2** {data@4256, 未决@4264, n@4268} (探针 333; 语义 = 拥有口径); 重算 = sub_14070AF30 遍历 **+1040 (owned)** → 邻省 **owner(+192→+200)** ≠ 己者入位图2/列表2 | 不序列化 |
| +4280 | 容器 24B | **neighbors 列表#2** {data@4280, cap@4288, count@4292, alloc@4296} (探针 GER=11) | 不序列化 |
| +4304 | fixed×1e-5 | stability | §4.3.8 起 |
| +4312 | fixed×1e-5 | war_support | §4.3.8 起 |
| +4313..+4319 | — | = war_support@4312 (**i64×1e-5 8B**) 尾 — stability@4304 同型 (ctor 初值全局) | |
| +4320 | uint32 | **refresh** | writer ADFE0 0x3495 (定案) |
| +4324 | uint32 | **original_research_slots** | writer 键 0x361D, >0 才写 |
| +4325..+4343 | — | = original_research_slots@4324 尾 3B + **CPlayerAiPrefs 16B@4328 (vt 0X27E72C0)**: {vt@4328, 4B 偏好@4336 = 0x01000001, i32@4340 = −1}; 同类见 CSetPlayerAiPrefsCommand (命令对象 +48 同布局拷贝) — 「玩家手动接管 AI 偏好」 | |
| +4344 | CRadarsPool 内嵌 (双 vt @+4344/+4352) | radar 键 12237 走 +4352 facet; 成员: 容器群 @+16/+40/+96/+120/+144/+168, 子对象@+72, RH 桶×2 @+200/+232 (dtor 0X1410A31F0 双 vt; 内嵌定案) | Reset 清理 |
| +4345..+4351 | — | = CRadarsPool vt@4344 尾 7B | |
| +4352 | 内嵌块 | **radar** | writer ADEC0 0x2FCD; loader case 12237 同 |
| +4353..+4415 | — | = **CRadarsPool 256B 全布局** 后半: 容器群 @+16/+40/+96/+120/+144/+168, tag u32@+4408, CStaticIntelSourceReference@+4416, RH×2@+4544/+4576 (内偏移 = CRadarsPool 相对) | |
| +4416 | CStaticIntelSourceReference | 情报源引用 (CRadarsPool 内; 情报源/省附加区) | |
| +4417..+4599 | — | = CRadarsPool 后半 (tag@+4408 / CStaticIntelSourceReference@+4416 / RH×2@+4544/+4576) | |
| +4600 | 匿名结构* | **资源/租借系统 rs** (vt 0X295C4B0, writer sub_140CBE2D0); 内含每州资源因子缓存 — sub_140CAE3F0(*(cc+4600), state) 按州查条目 → infra factor sub_140CAD400 / supply factor sub_140CB48C0 (RESOURCE_INFRA/SUPPLY_FACTOR_TOOLTIP; 缺省各 1.0); CResourceOrigin 元素 spotter = 内联 id 对 {type@el+112, id@el+116} 任≠0 才写 (探针 PRU id=803 type=61); 元素内资源向量 {resources@136 / resources_unclapmed@312 / buildings@664} 落盘门两级 (同 CStrategicResourcePool 族): 块级 = 至少一个正值条目才整块写, 条目级 = 块写后 ≠0 全发含负值 (EoaNB origin[3].resources_unclapmed 仅 fabric=-1 → 整块无叶实证) | §4.3.8 起; GUI 消费表见 §4.3.3 |
| +4601..+4607 | — | = 资源/租借 rs@4600 指针尾 7B | |
| +4608 | CConvoys (内嵌 136B) | **convoys** — writer ADEC0 0x3062; **第二容器 {data@cc+4688, cap@4696, count@4700, alloc@4704}** — 8B 堆对象指针元, runtime-only 语义未决 (dtor 拆除) | §4.3.16 |
| +4609..+4743 | — | = **CConvoys 136B (vt 0X27E7130, ctor sub_1410203E0)**: {vt@4608, tag u32@4616, **CEquipmentVariantPool 64B 内嵌@4624** (容器A 24B 元 + 容器B + u8), 容器@4688 {data@4688, cap@4696, c@4700, alloc@4704}, qword@4712, qword@4720, u8@4728, qword@4736} — 租借护航计算域 | |
| +4744 | u32 | convoys 派生计算值 (sub_1402BC8A0(cc+4608); 0X140705630 消费) | 推定 |
| +4749 | uint8 | dirty_controlled_states | §4.3.8 起 |
| +4750 | u8 | **tick 分片槽 = hash(tag) % dword_143336F50** (ctor 写入; 消费 0X1406E8210: `hour % N == +4750` 才跑 delayed_event 同步 (写 +4776 伴随表) — 错峰调度; 探针 GER=2) | 不序列化 |
| +4752 | 匿名结构 (0xC8 形状)* | delayed_event 容器数据指针 — 元素 0xC8: 事件对象指针@+8, 名 SSO@+32, originator tid@+192, 延迟总小时@+196 | §4.3.8 起 |
| +4753..+4763 | — | = delayed_event 容器尾 {cap@+4760} | |
| +4764 | u32 | delayed_event 容器计数 | §4.3.8 起 |
| +4765..+4823 | — | = delayed_event 容器尾 {alloc@+4768} + 伴随表/串表本体 | |
| +4776 | CEvent** | **delayed_event 伴随事件指针表** {data, cap@4784, count@4788, alloc@4792} — 8B CEvent* 元 (按事件对象同步删除) | dtor + 消费者 0X1406EA3A0 |
| +4800 | 容器 24B | **关联名称串表** {data, cap@4808, count@4812, alloc@4816} — 32B MSVC 串元 (对象改名时删旧推新) | dtor + pusher 增长码 |
| +4824 | CAirAce* | ace 容器数据 {cap@4832, alloc@4840} (serialize 0X14061BD30; 计数无 ≤64 上限, 探针 GER 80+ 王牌) | §4.3.8 起; reader Country.aces; **CAirAce 元素首批字段**: +8 idpair / +24 熟悉机型掩码 / +48 修正块 / +232 指派翼 idpair / +344 KIA (ACE_PILOT_CANT_ASSIGN_KIA 门) / +1384 熟悉机型容器 |
| +4825..+4835 | — | = ace 容器尾 | |
| +4836 | u32 | ace 族容器计数 | §4.3.8 起 |
| +4837..+4847 | — | = ace 容器 {data@4824, cap@4832, count@4836, alloc@4840..4847} = count 尾 + alloc | |
| +4848 | 容器 24B | **civil_war_target tag 容器** {data@4848, cap@4856, count@4860, alloc@4864} (writer 逐元键 0x314B=12619 写 tag 名; 探针 GER count=0) | 定案 |
| +4872 | u32 | **civil_war_initiator** (writer 键 0x3802=14338, >0 才写 tag 名) | 定案 |
| +4876 | u32 | **m_OriginalTag** (original_tag tid; 三证: "original tag: " 调试串 + `_CountriesForOriginalTags` assert (国管理器 **+2440** = 24B vector/identity 桶) + 名回退; **gs+832 = 每国 original-tag 恒等表 u32 数组**, sub_140BB5490(tag)=identity[tag], **sub_140BB52F0(A,B) = 「同原初国」谓词** (内战分离 tag/换 tag 继承=同国, 宗主-傀儡=不同国; 全引擎 3146 处调用); COriginalTagTrigger/CAnyCountryWithOriginalTagOfTrigger RTTI 实名; >0 时名称缓存优先用它) | §4.3.8 起 |
| +4880 | CNuke* | nukes 容器数据 {cap@4888, alloc@4896}; 元素 72B **CNuke** (vt 0X27E7270): +8 自存 token / +32 nuclear_strikes 容器 / +24 amount / +60 nukes_ready — 全表见 §4.3.8; **ctor 预填 2 条默认 CNuke** (do/while v5<2 推入, 1.5x 增长) | §4.3.8 起 |
| +4881..+4891 | — | = nukes 容器 {data@4880, cap@4888, count@4892, alloc@4896} = data 尾 + cap | |
| +4892 | u32 | nukes 容器计数 | §4.3.8 起 |
| +4893..+4903 | — | = nukes count@4892 尾 + alloc@4896..4903 | |
| +4904 | u32 | 战斗计数字段族 (num_armies_in_combat, 详见 §4.3.8 起 标量行) | §4.3.8 起 |
| +4908 | u32 | **num_ships_in_combat**; writer 键 0x35BE | §4.3.8 起 |
| +4912 | u32 | num_ships | §4.3.8 起 |
| +4916 | u32 | convoys_destroyed | §4.3.8 起 |
| +4917..+4935 | — | = convoys_destroyed@4916 尾 + **占领度量 4×u32@4920/4924/4928/4932** (控制省-core己 / 控制省-claim己 / owned points / contested points; 重算 sub_14070BDB0, 消费 sub_1406DA100 占领比率; 不序列化) | |
| +4936 | u32 | research_slot **动态可用科研槽数** (初值 = dword_14333701C 全局, 运行时 defines 填; ideas/国策加成后的现值——⚠ 非 ts+172 槽容量, 两者独立: BICE 实测容量恒 6 而动态 0~6, 动态=0 国无可用槽) | §4.3.8 起 / §4.7 |
| +4937..+4943 | — | = research_slot@4936 (u32) 尾 3B + 4B 未名@4940 (ctor 未触, 8 对齐填充推定) | |
| +4944 | CBuildingStatus* | **buildings 国家侧建筑宿主** (writer 键 12121 "buildings" 恒写块; loader case 12121 → vt+24 parse; 0x78B, ctor sub_141171AD0(2, 0, cc+8): {vt, alloc 哨兵@24, 容器@32/56/80, u32@104=2, u32@108=0, u32@112=tag}) | 定案 (gs+1000 注互证, §4.1) |
| +4952 | 容器 24B | **建筑类累计表** {data@4952, cap@4960, count@4964, alloc@4968} — 8B 内联对 {token u32@+0, value i32@+4} (按 token 累加差值) | dtor + 消费者 0X1407042D0 |
| +4953..+4975 | — | = 建筑类累计表 {data@4952, cap@4960, count@4964, alloc@4968..4975} 内部 | |
| +4976 | CNationalFocusTree* | focus_tree (名 MSVC@+8) | §4.3.8 起; vt 0X2739BB8 (探针+RTTI) |
| +4984 | 匿名结构 (NNB 形状)* | **continuous_focus_palette** (loader case 14045: 数据库解析 sub_1406C22A0, fallback sub_1402D2580; 存后 focus_status 刷新) | §4.3.8 起 (定案) |
| +4992 | CFocusStatus* | focus 对象 (CFocusStatus 宿主, §4.3.12) | §4.3.8 起 |
| +4993..+4999 | — | = focus_status@4992 指针尾 7B | |
| +5000 | 内嵌块 | **focus_cost_reduction = CReducedFocusCost** (vt 名直读 @5000; {vt@5000, 未决@5008, RH 桶哨兵@5016=&unk_143086920, count@5024, u8@5032, **f32@5036=0.9** = RH 表 load_factor — 复位函数写 0x3F666666; 与 fp+88/fp+152 表族同排布; 高置信; 探针 GER=0.900}) | writer 键 0x27F1; **条目值 i32 有符号** (负减免 −5 ↔ raw 0xFFFFFFFB) |
| +5024 | u32 | focus_cost_reduction 块计数 (写门) | 定案 |
| +5025..+5039 | — | = CReducedFocusCost 本体尾 {u8@5032, f32@5036=0.9} | |
| +5040 | 匿名结构 (元素待裁) 向量 | **volunteers_transfer 指针数组数据** {cap@+5048, alloc@+5056} (8B 元); writer 循环 ADEC0 0x346B | §4.10.19 |
| +5052 | u32 | volunteers_transfer 计数 | 定案 |
| +5053..+5063 | — | = volunteers_transfer 容器尾: count@5052 高 3B + **alloc@5056 哨兵** | ctor a1[630..632] |
| +5064 | 匿名结构 (8B 形状) 向量 | **exile_divisions_transfer 指针数组数据** {cap@+5072, alloc@+5080} (8B 元, 元素多态 vt); writer 循环 ADEC0 0x3AC1 | §4.10.19 |
| +5076 | u32 | exile_divisions_transfer 计数 | 定案 |
| +5077..+5111 | — | = exile 容器尾 (count@5076 高 3B + alloc 哨兵@5080) + **civil_war 动态 tag 会话注入表 {d@5088, cap@5096, c@5100, alloc@5104}** — 16B 元 {key 对象指针, u32 tag}; 查值 0X1406F8340 先查本表再落 +5112 持久层 (civilwar.cpp:662 建国路径); 运行时-only 不序列化 | ctor sub_14011DF40(a1+636) |
| +5112 | 匿名结构 (16B 形状) 向量 | **dynamic_revolution_tag 容器数据** (16B 条 {obj 指针@0, tag u32@+8}; ideology token@obj+20) | writer 块键 0x3564; loader 增长码四元组 |
| +5120 | u32 | dynamic_revolution_tag cap (1.5x 增长) | 定案 |
| +5124 | u32 | dynamic_revolution_tag count | 定案 |
| +5128 | 指针 (allocator) | dynamic_revolution_tag allocator | 定案 |
| +5129..+5135 | — | = dynamic_revolution_tag 容器尾: alloc@5128 高 7B 哨兵 | |
| +5136 | tag_id* | given_air_volunteer_permission 容器数据指针 {cap@+5144, alloc@+5152} — (tag 数组) | §4.3.8 起 |
| +5137..+5147 | — | = given_air_volunteer_permission 容器尾: data@5136 高 7B + **cap@5144** | |
| +5148 | u32 | given_air_volunteer_permission 容器计数 | §4.3.8 起 |
| +5149..+5159 | — | = 同容器尾: count@5148 高 3B + **alloc@5152 哨兵** | |
| +5160 | tag_id* | received_air_volunteer_permission tag 数组数据 {cap@+5168, alloc@+5176} | §4.3.8 起 |
| +5161..+5171 | — | = received_air_volunteer_permission 容器尾: data@5160 高 7B + **cap@5168** | |
| +5172 | u32 | received_air_volunteer_permission tag 数组计数 | §4.3.8 起 |
| +5173..+5183 | — | = 同容器尾: count@5172 高 3B + **alloc@5176 哨兵** | |
| +5184 | uint32* | received_air_volunteer_permission count 并行数组数据 (导出形 "TAG=cnt" 串) | §4.3.8 起 |
| +5185..+5195 | — | = received_counts 并行数组容器尾: data@5184 高 7B + **cap@5192** | |
| +5196 | u32 | received_air_volunteer_permission **counts 数组计数** | writer 断言 Tags.GetSize==Counts.GetSize (country.cpp:0x3F0) |
| +5197..+5207 | — | = 同容器尾: count@5196 高 3B + **alloc@5200 哨兵** (紧贴 +5208 旗 dword) | |
| +5208 | uint8 | **和平会议挂起旗 (surrender 抑制)** — surrender sub_1406E16C0 首行 `if (!*(cc+5208))` 才进投降逻辑; **置 1 = 和会创建时对所有 winner+loser tag** (peaceconference.cpp), 清 0 = 和会侧 + 国家重置 | 高置信 (探针 GER=0) |
| +5209 | uint8 | **is_major** (仅真写; 与 +5210 major 并存双键; writer 键 0x34BE; **两键分立实证: 全量国家分布 = (0,1) 5 国 + (0,0) 446 国, 无 (1,1)**, 本档 +5209 恒 0) | §4.3.8 起 |
| +5210 | uint8 | major (仅真写; 与 +5209 is_major 分立; writer 键 0x2BE9; **本档 = 5 国置位/446 国零**) | §4.3.8 起; **GUI: 国列表门之一** (与 cc+1156 / capital cc+4120 并列四门) |
| +5211 | uint8 | is_top_ic_country (仅真写) | §4.3.8 起 |
| +5212 | uint8 | **日更门** — slot[8] 桩 sub_1406FE1D0 首行 `if (!*(cc+5212)) return sub_1406FE1E0();` (非零才进日更大体: 读 +1120 异常表 / 刷 +3832 串 / 遍历 +5560 容器 count@+5572) | §4.00.1 槽表 |
| +5213 | uint8 | reserved_dynamic_country | §4.3.8 起 |
| +5214 | uint8 | use_legacy_ai_pp_spend | §4.3.8 起 |
| +5215..+5223 | — | = +5215 对齐垫 + **+5216 = **start_equipment_factor** (i64 fixed×1e-5; reader case 13195 → sub_1424C0A70 → sub_1424C53E0 定点解析; **writer 无对应键** ⇒ 只读档不写档): 日更 0X1406FE1E0 检非零 → 汇总本国资源池快照 → 按 /1e5 缩放 (sub_141010F70) → 并入 production+512 资源映射 → **自清 0**; 置值生产者未决 (唯一读入路径 = 存档 13195 键) | sub_1406FE1E0 L243-251 |
| +5224 | MSVC 串 | **assign_all_forces_to** {buf@5224, size@5240, cap@5248=15} | loader case 13993 串解析 |
| +5225..+5255 | — | = assign_all_forces_to 串本体 | |
| +5256 | MSVC 串 | cosmetic_tag {buf@5256, size@5272, cap@5280=15; 名称缓存组合源之一} | §4.3.8 起 |
| +5257..+5311 | — | = cosmetic_tag 串尾 (size@5272, cap@5280=15; ctor+探针双证) + **+5288/+5296/+5304 = army/navy/air_score 三缓存** (i64×1e-5: ARMY/NAVY/AIR_SCORE_MULTIPLIER defines × 军力摘要; 日更 sub_1406D77C0; getter 0X1406EC030/0X1406F30B0/0X1406EB6A0; 探针 GER 16.350/13.000/0.000; GUI Country 面板消费) | sub_1406D77C0 |
| +5312 | fixed×1e-5 (i64) | **propaganda_stability_penalty** (≠0 才写裸键; writer 键 19272) | §4.3.8 起 |
| +5320 | fixed×1e-5 (i64) | **being_bombed_support_penalty** (≠0 才写; writer 键 15440) | §4.3.8 起 |
| +5328 | Q15 (i64) | heroes_dying_war_support_penalty (门非零才写, writer 0X1407191B0 尾段) | §4.3.8 起; writer 键 15441 互证 |
| +5336 | fixed×1e-5 (i64) | **convoy_raiding_war_support_penalty** (≠0 才写; writer 键 15439) | §4.3.8 起 |
| +5344 | fixed×1e-5 (i64) | **propaganda_war_support_penalty** (≠0 才写; writer 键 19271) | §4.3.8 起 |
| +5352 | fixed×1e-5 | accidents_score | §4.3.8 起; writer 键 0x37FC 互证 |
| +5353..+5359 | — | = accidents_score 本体: i64 (+5352..+5359) 的尾 7B, 无独立字段 (探针 0.013) | |
| +5360 | CCountryPlayerSettings (内嵌) | **player_settings** (vt 名直读; 内容器 {data@5368, cap@5376, count@5380, alloc@5384}, u8@5392) | writer 键 0x3857; **GUI: 决议 ignored 名集 (定案)** = 本对象 (token 14423) 内 ignored 决议名集合 — 写侧 CIgnoreDecisionCommand::Execute 0X141157240 (+72=1 插入/=0 删除) + CIgnoreAllAvailableDecisionCommand::Execute 0X141156FD0; 读侧 sub_1414E7100(cc+5360, def+288 名) 命中 → 行状态元 1, 未中 2 |
| +5380 | u32 | player_settings 写门/计数 | 定案 |
| +5381..+5415 | — | = player_settings (64B, +5360..+5423) 尾: count@5380 高 3B + **alloc@5384 哨兵** + **u8@5392 = unit_controller_weights_tracking 调试旗** (控制台 "Toggled unit controller weights tracking" 翻转; 探针 0) + pad + **第二运行时容器 {d@5400, cap@5408, c@5412, alloc@5416}** — ⚠ +5416 = 本容器 alloc (序列化器 0X1414E7670 只发第一容器, 本容器不落盘) | dtor sub_1406CCDD0 |
| +5416 | CPdxNewDeleteAllocator* | 第二运行时容器 alloc (哨兵 &off_143085170) | 定案 |
| +5424 | std::function\<bool(bool)\> | (ctor sub_140CFEA50 由 lambda 构造, 类型名含 `CCountry::QEAA_H_Z`; 读者 0X1406FDBA0 sub_140CFEAD0/3C0) | 不序列化 (形态定案; 语义未决) |
| +5504 | CCountryFuelStatus* (0xE8=232B; vt 0x298B3A8) | **fuel_status** (writer 键 0x3B10=15120; loader case 15120 → vt+24 parse; ctor sub_1410F0AF0(cc); surrender 调 sub_1410F7F50; 其 +8 = **燃料量** (fixed×1e-5; 0X1406D3F00 读写; §4.30 油料子窗同源) — 高置信) | 定案; **GUI: 油料子窗** (logistics_fuel_window; 详 §4.3.14 B15 注) |
| +5512 | CCountryExperienceStatus* | 经验/活动 (0xA0B, ctor sub_1412A6130(cc)) | §4.3.8 起; vt 0X29A80C0 (探针+RTTI) |
| +5513..+5519 | — | = CCountryExperienceStatus 指针@5512 尾 7B | |
| +5520 | 容器 24B | **name_group** 容器 (32B 串条目) | writer 块键 0x3C87 |
| +5532 | u32 | name_group 计数 | 定案 |
| +5533..+5543 | — | = name_group 容器尾: count@5532 高 3B + **alloc@5536 哨兵** | |
| +5544 | scoped_ptr<CCountryOperationManager> | **operations** → **CCountryOperationManager** (0x60B; 内联 ctor: vt + CCountryFinishedOperations vt@+40, f32@+76=0.9) | writer ADEC0 0x4A38, 前置 scopedptr 断言 (定案) |
| +5552 | scoped_ptr<CCountryOperationTokenManager> | **tokens** → **CCountryOperationTokenManager** (0x48B; ctor sub_141405CF0(cc); 落键 intel_source/operation_assets, 旧键 tokens 兼容 — 布局 §4.11.17) | writer ADEC0 0x4A48 (定案) |
| +5553..+5559 | — | = tokens scopedptr@5552 尾 7B | |
| +5560 | 匿名结构 (88B 形状)* | **active_ability 数组数据** (88B 条目) | writer 块键 0x3891, 子键 id/start_date/country/leader/num_units/strategic_region/cost 全对位; 消费详 §4.3.5 |
| +5572 | u32 | active_ability 计数 | 定案 |
| +5573..+5583 | — | = active_ability 容器尾: count@5572 高 3B + **alloc@5576 哨兵** | |
| +5584 | CCombatTactic* | preferred_tactic: u32@*(cc+5584)+152 (writer 0X1407191B0; GER=0/CHI=42 定案) | §4.3.8 起; GER=0 时 = CNullCombatTactic 空对象 (vt 0X27E6588, 探针+RTTI) |
| +5585..+5591 | — | = preferred_tactic 指针@5584 尾 7B | |
| +5592 | CState** | **scorched_states 数据** (8B 州指针数组, 写 state id@+88) | writer 块键 0x4DCD; loader 增长码四元组 |
| +5600 | u32 | scorched_states cap (1.5x) | 定案 |
| +5604 | u32 | scorched_states count (写门) | 定案 |
| +5608 | 指针 (allocator) | scorched_states allocator | 定案 |
| +5609..+5615 | — | = scorched_states 容器尾: alloc@5608 高 7B 哨兵 | |
| +5616 | uint8 | **underway_replenishment** (仅真写; +5618 removed_controlled_province / +5619 landlocked_start ctor 全零互证) | writer 键 0x402B |
| +5618 | uint8 | removed_controlled_province | §4.3.8 起 |
| +5619 | uint8 | landlocked_start (仅真写 yes) | §4.3.8 起 |
| +5620..+5631 | — | = **u32 国家修订号@+5620** (ctor 0; sub_1406FE1B0 ++; 触发 = 控制台 hidden focuses / 内战 releasing 大流程对母子两国各 ++; GUI 缓存到自身 +8476 做脏检查; 探针 GER=0; 不序列化) + +5624 = 地形位掩码 dword (has_terrain 直读位运算; 掩码语义见 §4.32 地形族) | sub_1406FE1B0; sub_14138A400 |
| +5632 | fixed×1e-5 | coastal_protection_ratio | §4.3.8 起 |

#### 4.3.2 CCountryOccupationStatus 布局 (cc+4048)

对象 sizeof 0x128, vt 0X142982CF0 (RTTI 定名); 序列化 writer 0X141000120 — ⚠ a1 = occ+24 基差 24 (division_template_id reader+120 ↔ writer+96 同证; ⚠ decompile 字面 +232/+244 是 a1 基, 直读 occ 会撞空壳)。

| 偏移 | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| occ+8 | 匿名结构 (NNB 形状)* | occmgr 回指 (非占领国 cc; ctor 直证) | |
| occ+24 | CDivisionTemplate* | 表3 记录 驻军模板 | |
| occ+32 | CState** | CState* 向量 | |
| occ+64 | — | **通国占领状态 RH 表头占位** (load 0.9f@+92 自检) | |
| occ+72 | RH 桶数组 | **按目标国 tag 查占领记录** {dist u8@+4, tag dword@+8, 值 ptr@+16, 24B 桶} (活体 1942.11 德国档 count=1 与 writer 直读双证) | 定案 |
| occ+80 | u32 | RH count | |
| occ+84 | u32 | RH mask (nbuckets = mask+1+extra) | |
| occ+88 | u8 | RH extra | |
| occ+96 | 匿名结构 (元素待裁) 向量 | 记录列表 {data@96, count@108} (条目级 [N] 第 2 起) | GUI: 按页签过滤 (sub_14156F5B0 / sub_14156E780) |
| occ+120 | — | 默认法槽 (GUI occdata+120/+128) | GUI |
| occ+136 | u64 | 堆指针 (第二容器; 语义未决) | |
| occ+144 | CArmyManpowerValues (内嵌) | ctor sub_140FF2940 装 vt; 内联容器 {data@+152, cap@+160, count@+164} (foreign_manpower 求和链闭合) | 定案 |
| occ+152..+164 | — | = CArmyManpowerValues 内联容器 {data@+152, cap@+160, count@+164} (空态共享容器静态) | |
| occ+160 | COccupationLaw* | 占领法 — 记录 writer 0X140FFF910 以 token 19029 `occupation_law` 写法名 SSO(law+16); loader 0X140FFA320 名→COccupationLawDatabase 解析回写 (报错串 "occupation law does not exist: "); finder 0X140FF8060/0X140FF8290 回退链 rec+160→occmgr+280 default_law→全局默认; GUI 0X14156D6B0 同作法指针 | 定案 |
| occ+280 | COccupationLaw* | occmgr 默认法槽 (ctor sub_140FF2940 自 lawdb+88 装填; 与条目 rec+160 默认法分层) | 定案 |
| occ+248 | — | 记录槽 (GUI 消费) | GUI |
| occ+256 | 匿名结构 (元素待裁) 向量 | **resistance_attack_log** (键 0x4ACE=19150) {d@occ+256, c@occ+268} 8B 指针数组 (探针 SIA 47 条 ↔ cnt 一致) | 条目 writer 0X141000640; 元素表见下 |

resistance_attack_log 条目 (元素 = 日志条目):

| 元素+N | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| 元素+8 | u32 | country tid (恒写; 0x289A 引号) | |
| 元素+16 | CState* | state ptr → id u32@ptr+88 (指针门; 0x1B7) | |
| 元素+32 | hours | date (ADEC0 0x284A, ptr=+40−8) | |
| 元素+48 | u8 | garrison (恒写; 0x2928) | |
| 元素+64 | uint32 向量 | manpower (键 0x283C=10300) {d@+64, c@+76} 元 8B {tag u32, value i32}, value>0 才写 (sub_140C6AD50; value={tag=.. value=..} 折叠叶) | |
| 元素+88 | 匿名结构 (元素待裁) 向量 | equipment 池 (ADEC0 0x2F4E; 无门 → allow_zero_entries 恒写; 0X141012DB0: {d@+120, c@+132, az u8@+144}; 元 16B {var ptr, amount i64}, 门 amount≠0 或 az; id 对 {type@ptr+8, id@ptr+12}) | |
| 元素+152 | 匿名结构 (NNB 形状)* | resistance_activity (0x3D8D; ptr→SSO@+8 有值才写) | |

表2 记录 (CGarrisonDeployItem) 槽位:

| 表2记录+N | 类型 | 名称 | 参见 |
|---|---|---|---|
| 表2记录+104 | — | CGarrisonDeployItem 槽 | |
| 表2记录+136 | — | CGarrisonDeployItem 槽 (= 驻军人力需求读取槽, TRIGGER_GARRISON_MANPOWER_NEED_MORE_THAN/LESS_THAN 消费; 推定) | |
| 表2记录+144 | — | CGarrisonDeployItem 槽 | |
| 表2记录+208 | — | CGarrisonDeployItem 槽 | |

GUI: 占领面板数据源 — 记录列表 {data@96, count@108} 按页签过滤, RH 表 (occ+72 桶/occ+80 计数) 汇总回灌行 +48/+56 (sub_14156F5B0 / sub_14156E780); occdata+120/+128 默认法; +248 记录; 面板 +3952 = 驻军模板旗标, +3992 = 表2 记录经 sub_140FF5490 计算的 1e5 进度值 (定案: 所属 = occupied_territory_state_entry — Setup sub_14156EF60 a1[494]/a1[498]/a1[499] 对位; 非 cc 非 occdata)。

占领管理器 (occmgr, 经 occ+8 回指):

| 偏移 | 类型 | 名称/语义 | 参见 |
|---|---|---|---|
| occmgr+8 | — | 驻军优先级 (CSetCountryGarrisonPriorityCommand 双向闭环) | |
| occmgr+160 | — | foreign_manpower 容器 cap — ⚠ 与 occ+160 法指针同偏移不同对象, 防混 | |
| occmgr+256 | 匿名结构 (驻军日志条目) 向量 | 驻军活动日志容器 (元素 +8 tag / +32 时限 / +56 人力 / +88 装备; CGarrisonLogView) | |
| occmgr+280 | COccupationLaw* | default_law | |

**占领记录 dp 布局补行** (dp = occ+72 RH 桶值@+16 = occ+96 记录列表条目; 详形与写门见 §4.3.6)

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| dp+56 | i64 | core compliance/resistance 值 (求和器 getter 直读) | 高置信 |
| dp+176 | RH 桶数据 | **occupation_law_list** 州级占领法表 {mask@dp+188, extra@dp+192; 24B 桶 {dist@+4, sid@+8, 值*@+16}, 键 = 州 id} | 定案 (§4.3.6 写门族同源) |

#### 4.3.3 资源/租借系统 GUI 消费 (cc+4600)

| 字段 | 消费点 | 用途 |
|---|---|---|
| rs (整体) | 顶部资源条: sub_141D6DAC0 → sub_140CAED60 (resources_grid) | 顶部资源条 |
| rs+48 / +216 (净余) / +224 / +400 / +1112 | B15 资源余额行: × def+216 行号 → RESOURCE_BALANCE_VALUE 六元素; 进出口 sub_140C9DAE0(0/1); 因子 = 1e10/def+224 分母 | B15 资源余额行 |
| rs+1928 delivery_routes | 贸易路线快照: 按买方 idx → subwin+4144 (route+40 船队占用 / route+108 未名) | 贸易路线快照 |
| rs+576 | 产线材料成本行: 余额数组 × def+216 行号 → lacking 列 (填充 0X141D641E0, §4.31.33) | 资源余额数组 |

rs 布局补行 (rs = *(cc+4600); 推定, 单批孤证)

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| rs+1640 | 匿名结构 (元素待裁) 向量 | only_imported 侧资源数组 (16B 元) | 推定 |
| rs+1808 | 匿名结构 (元素待裁) 向量 | 资源权利对象列表 {data@+1808, count@+1820} | 推定 |
| rs+1952 | 匿名结构 (元素待裁) 向量 | 建筑→资源产出表 {data@+1952, count@+1964; 32B 外条/16B 内元} | 推定 |
| rs+1976 | 匿名结构 (元素待裁) 向量 | 资源权利列表 {data@+1976, count@+1988; 16B scoped-ptr 条} | 推定 |

权利对象 (rs+1808 列表条目) 子布局:

| 条目内偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +24 | u32 | tag | 推定 |
| +128 | CState* | 州指针 | 推定 |

CResourceOrigin 元素 given_resource_rights (rs+1976 条目 origin 解引用 el):

| 元素内偏移 | 类型 | 名称/语义 |
|---|---|---|
| el+992 | 容器 {d@el+992, count@el+1004} | given_resource_rights — 8B 条 {res_key u32@+0, tid u32@+4}; res_key 1..7 = 资源索引序 (oil..coal), 资源名 = 运行时本国资源向量动态收集 (非静态表, mod 新资源自动对) |

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
| 0x10E (=270) | MISSION_CONVOY_ESCORT |

#### 4.3.5 活动能力与借调条 (CActiveAbilityItem / 借调 strip)

**CActiveAbilityItem**: target = item+48 = CAbility\* (宿主 unit counter 非虚注入, 池@counter+280 {data+416, c+428}); 数据 = cc+5560 active_ability 88B 条目, 按条目+16==将领收集 (将领 +4168 HQ 引用 / +288 tag); 条目+72 = u8 隐藏门; 条目+0「id 代理对象」真身 = CAbility 本体。

**CAbility** (vt 0x1429852f8, ctor 0X141009500):

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
| occupation.\<R\> compliance_modifiers.#N | 引号名, 向量序 |
| occupation.\<R\> resistance / compliance | 恒写 (writer 0X140FFF910 L153-154 无门) |
| occupation.\<R\> strength_ratio / garrison_required | **≠0 门** (writer L381-386) |
| state_compliance_cache.\<sid\> | 块门 = count u32@occ+216 ≠0; RH {data@occ+208, mask@occ+220, extra@occ+224} 桶 24B {dist@+4, sid u32@+8, value i64×1e-5@+16}; 写 sid=fixed5 (writer 0X141000120 L135-208, test1r HOL.309) |
| occupation_law (每层) | 指针@dp+160 非空才写 |
| occupation_law_list.\<sid\> | 块门 = count u32@dp+184 ≠0; 桶 data@dp+176, 上界 = mask@dp+188+1+extra@dp+192; 桶 24B {dist, sid@+8, val*@+16}; 值名 = C 串内联 val+16 裸串; **sid 不经 states 过滤** (TUR KUR 353/800 越集实证); ⚠ law_list reader (对象层) 头偏移以本表为准 (错位曾致 MISS_MEM) |
| state_garrison_data.\<sid\> | **写门 = sid ∈ states 列表** (⚠ reader 扫 SGD 桶无头界会越界读入他国 occupation 桶; writer 本身无过滤, 全档 sid 集 == states 集等价门控); strength_ratio / garrison_required / army_manpower_need **≠0 门** (writer 0X141000700 if(*(a1+240/248/136))); manpower_pool.value 恒 1 条 owner tag; equipment.equipment[N] id 对 + amount ×1e5 向量序 (**条目门 = amount≠0 或 allow_zero_entries≠0**, 池 writer 0X141012DB0; 编号须在门内递增); **equipment_need.\<token\> = fixed×1e-5, 写门 amount≠0** (零需求不落盘); **garrison_reinforcement_requests.request[N]** (tok 19126, writer 0X141000700 尾调): 请求对象 {status u32@+32, progress i64@+40, total_progress i64@+48, produced 池内嵌@+88 {d@+8, c@+20, **az u8@池基+24 = itm+112**}, need {d@+128, count u32@+140}, date u32@+160}; **produced 条目门 = amount≠0 或 az** (与装备池同规则; 缺门则零额条目混入致编号错位) |

**CMajorCountrySelectionEntry / CMinorCountrySelectionEntry (国选器条目, GUI)**: (各 0x598B, def country_entry / country_entry_mini/_medium; 真入口 = 槽[19] Update 0X141F4A350/0X141F4A890): target = **+48 CCountry\***; Major 填 country_name (tag≤0 走 INTERESTING_COUNTRIES_OTHER_COUNTRIES 伪条目)/country_flag/country_leader 三元素, Minor 只填 country_flag; **大卡门 = cc+272==0** (消费方向定案; ⚠ 该消费点对象归属待裁 — 条目元素来自 v2+240/+252 容器且以 +160 容器/+172 计数/+8 tag/+184 谓词 vt 读取, 非 CCountry 形状, 故 cc+272 语义与归属均待裁; Major/Minor 互补互证); 同一选中高亮尾。

#### 4.3.7 国规则对象 (sub_1406F8410(国) 返回)

无独立 RTTI 类 (负定案) — 按国返回的规则状态对象; rule def 库见 §4.26 (qword_1433304C0, 56B/条)。

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +64 | uint8 数组 | 规则字节表 (按 rule def 索引寻址; has_rule 读取) | 推定 |
| +84 | uint8 | collaboration 可用门 (错误串 ":21458" 锚定) | 推定 |

#### 4.3.8 CModifier 通用布局 (192B; 内嵌@cc+3672 等五处) 与动态修正容器

**CModifier (192B; vt 0x1427185f0; body ctor sub_140555FB0 于 mod+16 起调, 基 ctor sub_1424BE3C0 置 +8=357; writer sub_140612640 递归同类)** — 全书唯一权威布局, 全部内嵌点共用: 州 st+1736 (added_modifier) / MIO org / cc+1448 country_modifiers / power_balance+184 / leader+3840 命名修正块阵 b0..b14 / advisor.modifier / sub_unit_modifiers 容器B / faction upgrades spymaster。mod = CModifier 对象基址:

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +0 | vt | CModifier | 不序列化 |
| +8 | u32 | =357 (none) 「末次键」调试 token (与 CTechnologySharing+8 同款) | — |
| +16 | vector 24B | **base pairs** {d@16, cap@24, c@28, alloc@32} — 16B 元 {mdef idx u32@0, pad@4, value i64×1e-5@+8} | c>0; 叶名 = 修饰 def token, 值 fixed5 (可负 — 读侧有符号 /100000) |
| +40 | vector 24B | **children** {d@40, cap@48, c@52, alloc@56} — 8B 指针元 → 嵌套 CModifier (= added_modifier 块); child 关键位 = name SSO@child+88 / data=u32@child+188 | c>0 (本档 0 叶) |
| +64 | vector 24B | **children 回收池** (`vector<CModifier*>` 自由表 {d@64, cap@72, c@76, alloc@80} — ClearChildren(flag=0) 整体 append 入池不删实例, GetOrRecycleChild LIFO 弹尾元重填复用; 仅 flag=1 路径真毁) | writer 不触 = 运行时 |
| +88 | MSVC SSO 32B | **name** (size@+104; writer 键 27=name / parser 同址读入; 存档形态例 `added_modifier.name="operative_mission_icons_small|1情报网"`) | size≠0 引号 |
| +120 | 匿名结构 (40B RH 桶) RH 桶数组 | **custom_modifier_tooltip 串集合** (表基 = mod+120; 槽 40B {hash, probe, 串} = 引擎 RH 桶族中的 40B 桶宽, 含 SSO 串内联; 键 768 每串 FNV-1a 插入; 消费 = 描述构建器 sub_14055B220 遍历追加为额外提示行) | writer 不触 |
| +148 | u32 | 常量 1063675494 (ctor; ≈0.85f 位型, 与 CVariables+44 的 0.9f 位型同族常数) | 不序列化 |
| +152 | uint32 RH 桶数组 | **hidden_modifier mdef idx 集合** (表基 mod+152, 槽 8B u32 集, 键 769 块内 pair 的 mdef idx 插入; 消费 = 行构建器 sub_140E630F0 探针命中即跳过该行) | writer 不触 |
| +160 | MSVC 串 | 第二 MSVC 串 {静态空@160, size@168, cap@176} (ctor 指向静态空串, dtor 非静态才 free) | writer 不触 |
| +184 | u32 | **pair 接纳类别掩码** (sub_140557940 首行 `(mdef+100 flags & mod+184) != 0` 才合并该 pair; 国家聚合用 0xFFFFFF=24 类位) | 不序列化 |

> ⚠ **+184 双读待裁**: 本节取自 pair 合并门 (读点 sub_140557940); 另有 ctor 侧读数记为 **i32 = −1 哨兵**。
> 二者或为「同槽不同内嵌点初值差异」或「其一误读」, 待裁 — 按内嵌点复核后归一。
| +188 | u32 | **data = 子级展开深度** (writer 键 240=data, ≠1 才写; merge 时 dst.data>0 → 每来源生一个命名 child (data=dst−1); 存档形态 `added_modifier.data=0` 吻合; ⚠ parser 对 data 读值即弃 — 加载后由宿主 recalc 重建) | ≠1 才写 |

修饰定义表寻址 (BASE 相对; 供 +16 pair 的 def_idx → def 解引用):

| 项 | 值 |
|---|---|
| defs | rp(BASE+53569984) |
| count | ru32(BASE+53569996) |
| stride | 120B |
| token id | u32@def+112 |
| 类属掩码 | u32@def+104 |

⚠ 修饰值叶静默缺失排查: 定义表基址手抄 hex 掉位 (如误写 0x3169C0) 即全族缺叶 — 以十进制 BASE+ 值为准。
⚠ 全族闭合证据: ctor sub_140555FB0 / dtor sub_1405566B0 / writer sub_140612640 三方闭合; 与 state added_modifier 同 writer 互证。

cc+3672 动态修正容器:

| 偏移 (容器) | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +40 | 匿名结构 (64B) | 条目数组 容器数据指针 — {data, count}, 元素 64B |  |
| +52 | u32 | 条目数组 容器计数 |  |
| 元素+8 | tag_id | tag (i32) | >0 才写 |
| 元素+12 | int32 | state 州 id | >0 才写 |
| 元素+16 | int32 | days | ≥0 才写 (哨兵 -1) |
| 元素+24 | 匿名结构 (NNB 形状) | def 名: cstr(*(e+24)+40) 静态类 | 双形态: 静态类 = cstr@(*(e+24)+40); 脚本实例化类 = MSVC 串内联@obj+40 (vtable 0x1D8FD48, size@+56), 以指针可解性判定形态; 恒写 (名读不出则整条跳过) |
| 元素+32 | uint8 | enabled | 恒写 yes/no |
| 元素+40 | fixed×1e-5 | value fixed×1e-5 数组数据 | c>0 才写块 |
| 元素+52 | u32 | value 数组计数 | c>0 才写块 |

#### 4.3.9 名字组 tracker (cc+112 + 8×mode)

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| cc+112 + 8×mode | CNameGroupTracker* | tracker 本体; mode 0=division 1=ship 2=railway_gun 3=operative | |
| +16 | 匿名名字条目 | unavailable_groups 容器数据 {d@+16, cap@+24, c@+28, alloc@+32} | 8B CNameGroup* 元, 元素名 = cstr(*(g+8)) 或 MSVC@g+8; writer 键 14603 (legacy 14567 同址) |
| +28 | u32 | unavailable 容器计数 |  |
| +40 | 匿名名字条目 | available_groups 容器数据 {d@+40, cap@+48, c@+52, alloc@+56} | 同上; writer 键 14602 (legacy 12264) |
| +52 | u32 | available 容器计数 | 同上 |
| +64 | u32 | 未名 (ctor 零) | 形态定案/未名 |
| +68 | uint8 | 未名 (ctor 零) | 形态定案/未名 |
| +72 | 匿名结构 (176B) | post_mortem 容器数据 {d@+72, cap@+80, c@+84, alloc@+88} — 第三容器, 元素 176B **CNameGroupMember 内联** (writer 0X1409C9B80, 键 14604) | 下表; BlackICE 实测峰值: ship 761/div 572 (bi8), 防御界须 ≥4096 |
| +84 | u32 | post_mortem 容器计数 |  |
| +96 | u32 | **mode** (0=division 1=ship 2=railway_gun 3=operative) | ctor a3 |

post_mortem 元素布局:

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | uint32 | type | 恒写 (token 225); 定案 |
| +12..+15 | pad | (copy-ctor 不复制) |  |
| +16 | MSVC 串 (32B) | **串#1 = 身份名** (runtime-only; assign 不复制 = 身份字段) | ctor 栈 buf@+16 |
| +48 | int32 | **名字库记录 serial** | -1 = 未命名 |
| +52 | pad | (copy-ctor 跳过) |  |
| +56 | u32 | **owner id** (国/特工) |  |
| +64 | qword | **owner 对象回指** |  |
| +72 | 匿名结构 (NNB 形状)* | 未名指针 (创建时 sub_1409C9240 直写) | 形态定案/未名 |
| +80 | 匿名结构 (NNB 形状) | equipment id 对指针 (→{type@+8, id@+12}) | ptr≠0 门, 写 tok 12110 |
| +88 | 匿名结构 (NNB 形状)* | id 对宿主#2 (默认 = qword_14333D528 = **BSS 零全局**; runtime-only) | 推定 |
| +96 | MSVC 串 (32B) | **串#2 = 当前名缓存** (驱动 override/osp 刷新; copy-ctor 复制; **+72 恒 0 成立**: 唯一写点 = setter sub_1409C9240, 全 dump 仅 1 个调用点 sub_140E8D310 且实参恒 0) |  |
| +128 | uint32 | name_order | ≠0 才写 (14563) |
| +136 | MSVC 串 | override | 门 = size@+152 ≠ 0 (14561); 串体 {size@+152, cap@+160} |
| +168 | uint8 | is_name_ordered | 默认 1; ==0 写 `is_name_ordered=no` (14562) |
| +169 | uint8 | **override_set_programmatically** (osp 定案) | ≠0 写 (14646); ⚠ loader: type/name_order/is_name_ordered/osp 四键解析即弃, 仅 override/equipment 落储 |

#### 4.3.10 经验 / 核弹 / 力量平衡 / 国策

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| cc+5512 区 | CCountryExperienceStatus* | experience 三军经验 + shortages; activity_data 同区 | 布局 §4.3.15 |
| cc+4880 | CNuke* 容器数据 {cap@+4888, alloc@+4896} | nukes 容器 | 元素 72B CNuke (下表); 块 13719 门 count≠0 |
| cc+4892 | u32 | nukes 容器计数 |  |
| gs+1104 | CPowerBalanceSystem* | power_balance 系统 | 系统 vtable 0X296FCA0, 条目 vtable 0X296FC50; value/friends/Enemies 三槽; 1024 魔数已改 1e5 定点 |
| cc+5000..+5032 | 容器簇 | 国策 focus_cost_reduction / national_focus 进度树 / 海军剧场 / focus 减免 | focus_tree 名 MSVC@*(cc+4976)+8; CFocusStatus 全布局 §4.3.12; GUI: 焦点树重建 (0X141386BD0: cc+4976 树; 门 = win+8424/+8432 双缓存 ∧ cc+5620 树版本; 题栏 NATIONAL_FOCUS_TITLE) |

CNuke 元素布局 (72B, vt 0X27E7270; writer/loader/RTTI 三源定案):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | — | 自存 token 13517 | 恒写 |
| +16 | 匿名结构 (NNB 形状)* | 宿主回指 |  |
| +24 | fixed×1e-5 | amount ×1e-5 | 恒写 |
| +32 | 容器 24B | nuclear_strikes (多态元 CNuclearStrike, 下表) | count≠0 开块 (块 13719, 条 13718 ADEC0) |
| +56 | — | 未名 |  |
| +60 | u32 | nukes_ready | 恒写 |
| +64 | u32 | 待投余量 (num_nukes_left_to_drop 累加项) | 推定 |

CNuclearStrike 元素 (24B 多态; loader 弃读 = 在途打击运行时重建):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt |  |
| +8 | — | 键 13718 |
| +16 | u32 | province (10304) |
| +20 | u32 | time (424) |

#### 4.3.11 country_fields 标量字段族 (覆盖率体检定案)

偏移均相对 cc; `*(…)` 解引行与「州自有」行不参与升序。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +496 | fixed×1e-5 | command_power |  |
| +536 | CVariables* | variables 族 (reader country_variables73) |  |
| +544 | CVariables* | scripted_gui_random (直读 cc+544) | ⚠ i32 符号门: 大值读 i32 (-2080830976 ↔ u32 2214136320), 勿按 u32 直读有符号字段 |
| +1192 | CState* | cores 容器数据指针 — `vector<CState*>` 8B 州指针 → gs+712 反查州 id | 保容器序单行 (FRA 尾部非升序 = 插入序, 禁止排序); c>0 |
| +1204 | u32 | cores 容器计数 |  |
| +1205..+1215 | — | = cores count 尾 + cores alloc@1208 |  |
| +1216 | CState* | claims 容器数据指针 — 同构 `vector<CState*>` {cap@+1224} | ⚠ 非 stride-4 u32 id 读法 (误读形态 = 指针 lo/hi 对); c>0 |
| +1228 | u32 | claims 容器计数 |  |
| +1229..+4123 | — | = §4.3 CCountry 主表全覆盖 (全量定案); 本行不再记账 |  |
| +4120 | uint32 | capital | GER=64 对拍定案 |
| +4124 | uint32 | original_capital | GER=64 对拍定案 |
| +4125..+4763 | — | = §4.3 主表 + **CRadarsPool@+4344 (256B 全闭)** + rs@+4600 + **CConvoys@+4608 (136B 全闭)** + delayed_event@+4752/+4764 (定案) |  |
| +4752 | 匿名事件条目 (0xC8)* | delayed_event 容器数据指针 — 元素 0xC8 | 下表 |
| +4764 | u32 | delayed_event 容器计数 | 下表 |
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

> 实名与函数锚 (1.19.3): vt 0x1427E7488 / reader 0x141180910 / ctor 0x14117F120 (CCountry 侧工厂 sub_1406D0880 malloc 0xC8 后 push cc+4752); +16 CEventScope ctor sub_140534F00; +192 = ctor *a3; +196 = ctor a5 延迟小时; reader 10604 months×720 + 10605 days×24 + 12656 hours 三支累加。

CEventScope 递归布局 (sc = 作用域首址):

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | tag_id | country → tag 引号 | >0 |
| +12 | u32 | random 值 2 (存档序第二) | **恒写** (默认 1) |
| +16 | u32 | random 值 1 (存档序第一 — **写序反**, CHRX variables.random 同款) | **恒写** (默认 1587985054 = 0x5EB5B01E 魔数种子) |
| +24 | CEventScope* | root | ≠自指 (自指 = 根哨兵, 递归终止; 读取深度上限 8) |
| +32 | CEventScope* | from |  |
| +40 | CEventScope* | prev = CEventScope* 递归 |  |
| +48 | qword | 未名 runtime-only (ctor 零; writer/loader 均不触) | 形态定案/未名 |
| +56 | qword | 同上 | 定案 |
| +64 | qword | 同上 | 定案 |
| +72 | CStrategicRegion* | strategic_region = u32@*(sc+72)+88 | ptr 非空 |
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
| +160 | 匿名结构 (元素待裁) 向量 | saved_event_target 112B 元素数组 | 仅 from==自指时写 |
| +168 | uint32 | state 州 id | ≠0 |

#### 4.3.12 杂项标量与容器族

偏移均相对 cc (country 对象); `tg+` 前缀行 = theater_group 对象相对。

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +12 | int32 | last_collaborated_surrender_recipient | 带符号 >0 才写; 值 = 国 idx → 引号 tag (writer 0X1407191B0 → sub_140BB4E70 串表); reader combat_support_scalars |
| +29..+771 | — | = **CCountryManpower (40B @+808)** 与各 id 对/容器实底 (max_exile/add.. 全闭 + RH/六容器); 本行不再记账 |  |
| +136 | CNameGroupTracker* | operative_codenames_tracker (= names_trackers 基 cc+112 + 8×mode, mode 3) | post_mortem 全字段镜像 names_trackers 模式 (mode 0-2 属 names_trackers); §4.3.6 |
| +728 | 内嵌 | cached_navy_strength.sub_units: {d@+736, c@+748} 8B 元素 {舰种 token, 数量} | **块门 = 师/舰队/铁路炮容器任一非空** (writer `if(cc+668\|\|cc+644\|\|cc+692)`; 无军队国整块不写 — KR 被吞并 VNC 实证) |
| +760 | idpair | expeditionaries_sent 容器数据指针 — {d, c} 8B 内联对 {type@+0, id@+4} (writer sub_1406C8960 token 13427; `if ((cc+772))` 门) | c>0; `id=N type=T` |
| +772 | u32 | expeditionaries_sent 容器计数 |  |
| +773..+795 | — | = expeditionaries_sent 容器 {d@760, cap@768, c@772, alloc@776} 内部 (pdx 24B) |  |
| +784 | idpair | volunteers_sent 容器数据指针 — {d, c} 8B 内联对 {type@+0, id@+4} | c>0; `id=N type=T` |
| +796 | u32 | volunteers_sent 容器计数 |  |
| +797..+4107 | — | = volunteers_sent@784 + **CCountryManpower@808** + CCountryColors ×2 (含 +8 间隙) + owned/controlled/contested/cores/claims 五容器 + strategic_region_data RH 头 + 六容器@1304..1440 + 二 CRuleOverrides/CModifier#2 内嵌 — 定案, 本行不再记账 |  |
| +820 | uint32 | manpower.current (CCountryManpower@+808 内 +12) | CTX 段 |
| +824 | uint32 | manpower_ratio | writer 0X140CFE9D0 AE670(694, [blk+16]); qword≠0 才写 (门 = ≠0 非 >0); GER 250000/ENG 105000/SOV 154500 |
| +832 | uint32 | exile (CCountryManpower@+808 内 +24) | exile >0 才写 |
| +836 | uint32 | max_exile manpower (CCountryManpower@+808 内 +28) | 独立 >0 才写 (writer 0X140CFE9D0 内 exile(+24)>0 与 max(+28)>0 两门互不联动) |
| +4016 | CCustomizableBuildingCollection* | naval_headquarter_status CBC: {d@+40, c@+52} 80B 条 | 条目布局见下表; CBC vt 0X27E7418 (探针+RTTI); §4.16 关联 |
| +4096 | 匿名结构 (report 条目) | invasion_report 容器数据指针 — (指针数组) | 元素: tag tid@+8 / enemy tid@+12 / province=*(e+16)+164 / date hours@+40 |
| +4108 | u32 | invasion_report 容器计数 |  |
| +4109..+4311 | — | = invasion_report count 尾 + intel_agency@4032 尾 + incoming_diplo@4088 尾 + original_capital@4124 尾 + graphical_culture 串@4136 + stability@4304 (定案) |  |
| +4304 | fixed×1e-5 | stability |  |
| +4312 | fixed×1e-5 | war_support |  |
| +4313..+4859 | — | = war_support@4312 (i64) 尾 + refresh@4320 + original_research_slots@4324 + **CPlayerAiPrefs@4328 (16B)** + CRadarsPool@4344 + rs@4600 + CConvoys@4608 + dirty@4749 + delayed_event + ace/nukes 累计表 — 定案, 本行不再记账 |  |
| +4324 | uint32 | original_research_slots | ≠0 才写 (亡国 0 不写) |
| +4749 | uint8 | dirty_controlled_states |  |
| +4848 | tag_id | civil_war_target 容器数据指针 — u32 tid 数组 → tag 引号 | c>0 |
| +4860 | u32 | civil_war_target 容器计数 | c>0 |
| +4861..+4907 | — | = civil_war 尾 + initiator@4872 + original_tag@4876 + nukes 四元组@4880 + **占领度量 4×u32@4920..4935** + num_armies@4904 (定案) |  |
| +4904 | uint32 | num_armies_in_combat | 均 ≠0 才写 (num_ships 首轮 MISS_MEM = 日缓存刷新时序非布局问题); reader combat_support_scalars |
| +4908 | uint32 | num_ships_in_combat |  |
| +4912 | uint32 | num_ships |  |
| +4916 | uint32 | convoys_destroyed |  |
| +4917..+5051 | — | = convoys_destroyed@4916 尾 + **占领度量 @4920/4924/4928/4932** + research_slot@4936 + 4B@4940 + buildings@4944 + 建筑累计@4952 + focus 族 + fcr RH@5000..5039 (定案) |  |
| +4936 | uint32 | research_slot |  |
| +4944 | CBuildingStatus* | buildings 容器宿主 (vt 0X2999050): level=lv%65536 / healthy=lv/65536 恒写 | **partial_health 原值 ≠100000 才写** (writer 0x487F); vt 0X2999050 (RTTI) |
| +5040 | CVolunteerForceTransfer* | volunteers_transfer 容器数据指针 — {d, c} 8B 指针元 → CVolunteerForceTransfer (0xA0, ctor 0X1415201A0); 块 writer sub_141523660 | c>0; 段 sv2_sec_c_volunteers |
| +5052 | u32 | volunteers_transfer 容器计数 |  |
| +5053..+5075 | — | = volunteers_transfer 容器 {d@5040, cap@5048, c@5052, alloc@5056} 内部 (pdx 24B) |  |
| +5064 | CExileDivisionsTransfer* | exile_divisions_transfer 容器数据指针 — {d, c} 8B 指针元 → CExileDivisionsTransfer (0x38, ctor 0X1415117A0); 块 writer sub_141513970 | c>0; 同段 mode="exile" |
| +5076 | u32 | exile_divisions_transfer 容器计数 |  |
| +5077..+5123 | — | = exile 容器 {d@5064, cap@5072, c@5076, alloc@5080} 内部 + **civil_war 动态 tag 注入表 {d@5088, cap@5096, c@5100, alloc@5104}** (运行时-only) |  |
| +5112 | 匿名结构 (16B) | dynamic_revolution_tag 容器数据指针 — (0x3569 推定): 16B 元 {子对象 ptr@+0, tag_id u32@+8} → 引号 tag; ideology = 裸 token u32@(elem+0)+20 (ADCE0 11838) |  |
| +5124 | u32 | dynamic_revolution_tag 容器计数 |  |
| +5125..+5147 | — | = dyn_rev 容器 {d@5112, cap@5120, c@5124, alloc@5128} + given_air 容器 {d@5136, cap@5144} 内部 |  |
| +5136 | tag_id | given_air_volunteer_permission 容器数据指针 | tag 数组 |
| +5148 | u32 | given_air_volunteer_permission 容器计数 | tag 数组 |
| +5160 | tag_id | received_air_volunteer_permission tag 数组数据 |  |
| +5172 | u32 | received_air_volunteer_permission tag 数组计数 |  |
| +5184 | uint32 | received_air_volunteer_permission count 并行数组 (导出 "TAG=cnt" 串) |  |
| +5209 | uint8 | **is_major** (JAP/ITA/AUS=1, GER/ENG=0) | ⚠ 与 major@+5210 为两字段勿混; TGWR 等 mod 另落 is_major 叶 |
| +5210 | uint8 | major (vanilla 叶) |  |
| +5213 | uint8 | reserved_dynamic_country |  |
| +5214 | uint8 | use_legacy_ai_pp_spend |  |
| +5256 | MSVC 串 | cosmetic_tag |  |
| +5312 | Q15 i64 | propaganda_stability penalty | 同批同 helper (sub_1407191B0), ≠0 才写; reader Country.combat_support_scalars |
| +5320 | Q15 i64 | being_bombed_support penalty | 同批同 helper (sub_1407191B0), ≠0 才写 |
| +5328 | Q15 i64 | heroes_dying penalty (heroes_dying_war_support_penalty) | ≠0 才写 (writer 0X1407191B0 尾段 ADFE0(15441), 同批同 helper); reader Country.combat_support_scalars |
| +5336 | Q15 i64 | convoy_raiding_war_support penalty | 同批同 helper (sub_1407191B0), ≠0 才写 |
| +5344 | Q15 i64 | propaganda_war_support penalty | 同批同 helper (sub_1407191B0), ≠0 才写 |
| +5352 | fixed×1e-5 | accidents_score |  |
| +5584 | CCombatTactic* | preferred_tactic = u32@*(cc+5584)+152 | writer 0X1407191B0; GER=0 / CHI=42; GER=0 时 = CNullCombatTactic 空对象 |
| +5618 | uint8 | removed_controlled_province |  |
| +5632 | fixed×1e-5 | coastal_protection_ratio |  |
| tg+88 | uint8 | navy_theater.theater_group.is_important (tg = theater_group 对象) | ≠0 写 yes, 常态 0 不发射 |

naval_headquarter_status CBC 条目 (80B, CCustomizableBuildingItem vt 0X29D24B8) — 条目 writer 链: 容器 0X141511720 (门 count@+52>0, 键 0x2F59) → 逐条 slot1 0X1424BEC50 (开匿名块 thunk) → 条目 slot2 0X1415C1160:

| 字段/块 | 键 | 写门 |
|---|---|---|
| id/省键 | — | binst 指针@e+56 非空 (省 10304/439 双模式分支) |
| character | 0x4C16 | (type≠0 ∨ id≠0) ∧ 有效谓词 sub_14221F310; 非恒写 |
| 模块块 | 0x44C3 | 模块指针@e+64 非空 (writer 0X1416237C0 CNavyLeaderModule; 段门 char_type≠0 = 实战充分子集) |
| experience | — | ≠0 |

country.ace (CAce 元素; writer 0X14061BD30; 段侧实现 sv2_sec_c_country_scalars) — id 块恒写 {id@+12, type@+8}:

| 偏移 (e) | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | u32 | type | id 块恒写 |
| +12 | u32 | id | id 块恒写 |
| +240 | MSVC 串 | name | 恒写 (空串照写) |
| +272 | MSVC 串 | surname | 恒写 (空串照写) |
| +304 | MSVC 串 | callsign | 非空才写 (size@+320) |
| +336 | uint8 | is_female | ≠0 |
| +340 | MSVC 串 | portrait | 恒写 |
| +344 | uint8 | alive | =0 写 no |
| +348 | u32 | kill_type | ≠0 |
| +352 | u32 | killer_name id 对.type | 任非零 (对 e+352/+356) |
| +356 | u32 | killer_name id 对.id | 任非零 (对) |
| +360 | int32 | killer_country | 带符号 >0 → 引号 tag |
| +364 | uint8 | handled | ≠0 写 yes |
| +368 | 匿名结构 (NNB 形状)* | modifier (SSO@*(e+368)+8) | 指针非 0 |

特殊项目池 resources (池类 = NProject::CProjectPool vt 0X29C6E28; resources 子对象 = CStrategicResourcePool)。访问链: S = rp(cc+4008) (vt 0X2971838) → 池 P = rp(S+24) (项目容器 {data@P+16, count@P+28} 448B 元) → **resources = 池内嵌子对象 @P+72** {vt@0, data@+80, count@+92}。

| 项 | 偏移 | 名称/语义 | 写门 |
|---|---|---|---|
| resources 容器 | P+72 {data@P+80, count@P+92} | CStrategicResourcePool 内嵌子对象 | 池 writer 0X141483890 (NProject::CProjectPool slot2; P vt 0X29C6E28 RTTI 证) 尾部 ADEC0(11842=resources, P+72) |
| 资源元素 | 16B | {amount i64×1e-5@+0, 资源 token u32@+8}; 键 = lexer 资源名 (**aluminium=19999**, ≠ aluminum=15876 — 存档拼写为准) | 元素 writer 0X140BCCAF0 (CStrategicResourcePool slot2, vt 0X29515A0) 发裸 `token=i64` 叶; ⚠ amount==0 整条不写; 元素门 = 指针≠0 (sub_140BCCAF0 实证) |
| 池元素 program id 对 | 元+96 (type) / 元+100 (id) | 元素 448B 内嵌 program 回填对 | ⚠ 同名 project 可重复 (每国两条实测) — 按容器下标对齐取对, 按名索引互覆 |

CProgramStatus (S) 布局:

| 偏移 (S) | 类型 | 名称/语义 |
|---|---|---|
| +8 | vt | vt1 = 0x142971858 (CPersistent 基 @ mdisp 8; RTTI COL 铁证); writer/dispatch 皆 vt1 相对坐标 (this = S+8) |
| +24 | NProject::CProjectPool* | 池 P (NProject::CProjectPool, vt 0X29C6E28) |
| +32 | CRef 向量 | program CRef 向量 {data@S+32, count@S+44} (GUI 宿主 CFacilitiesTabView+152) |
| +80 | NProject::CBreakthroughProgress | NProject::CBreakthroughProgress (块键 11956 breakthrough; ctor 0X140E75510 于 S+80 初始化); ⚠ writer 0X140E78830 (vt1 slot2, this=S+8) 发 a1+72 = 绝对 S+80 — 「a1+72」勿按 S+72 读 (vt1 相对坐标基差陷阱) |

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
| +368 | 旗容器 {vt@+368, data@+376, count@+388} — 48B 条 {键@+8, 日期 dword@+24, 旗值 i16@+40}; 与 CFlagManager 条目同构 (高置信, 两批互证); ⚠ 先前记「+376 = 未读奖励」与容器 data 槽相抵 — 待裁 |
| +376 | 旗容器数据 (上表) |

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

#### 4.3.13 CLoopHistory / 队列族 (country.history @cc+4040 / logistics @cc+3992 / strategic_air history — 三处同构, 唯一队列 writer 0X141517EC0, 全 dump 仅此一处写 max_elements token, 无类型分流)

vt 实测定案: CLoopHistory vt = BASE+**0X29D2A48** (slot2 = 0X141517EA0 纯转发), CLoopHistoryContainer vt = BASE+**0X29D29A8** (slot2 = 0X141517EC0)。

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
| +0 | 8B | vt | |
| +8 | 8B | ContainerQueue 基类子对象 vt | |
| +16 | CLoopHistory* | history_queue.0 队列对象 (CLoopHistory) | |
| +24 | CLoopHistory* | history_queue.1 队列对象 (CLoopHistory) | |
| +32 | CLoopHistory* | history_queue.2 队列对象 (CLoopHistory) | |
| +40 | CLoopHistory* | self | 自指 |
| +48 | uint8 | is_16th | |
| +52 | uint32 | **cols 列数** | 双重身份: 槽守卫 >0 兼 data 行内值数 |
| +56 | CLoopHistory* | parent → cols = ru32(parent+52) | parent 回指; 三队列共享同一 cols (writer 经 parent 回读); **CLoopHistory (0x38) 继承 CLoopHistoryContainerQueue** (基子对象@+8, vt 0X29D29F8, writer 0X141518230 数字键三队列; ctor/dtor 定案) |

队列对象 (qc):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +8 | 行句柄** 数组* | data = 行**对象**指针数组 | |
| +16 | u32 | **cap** | ctor/dtor 定案 |
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
| 槽[13] | 返 token **10394="country"** (GetToken; 族契约: Apply = vt[17], 基 sub_140A3D610 递归遍历 +32 子表; 驱动 = sub_140A3D2A0 按 from<date<=to 过滤派发, 源串 history.cpp:165) |
| 落盘实证 | **条目不落盘** (负定案): 原版 GER 1937 与 KR2 晚局双档全量提取, 5 鉴别 token (revolutionary_tag/starting_truck_buffer/starting_train_buffer/add_nuclear_bombs/set_convoys) 零命中; 存档 country.history 只含 history_queue×3 数值遥测队列 — 8 case = history/countries 文件装载侧解析 (开局执行后不保留), writer 链运行时恒空; **export 无缺口, sv2 无需段** |

派生条目实名 (sizeof 统一 80; 载荷槽 = +72; vt[1] Save 吐键值):

| 类 | vt[13] token | vt[1] 键 | 装载 case | Apply 语义 (+64 = country tag) |
|---|---|---|---|---|
| CCountryConvoysChange | 12386 convoys | convoys = i32@+72 | 12384 set_convoys | +72>0 则 sub_141020680(cc+4608, +72) 加进护航船池 (只加正数) |
| CCountryNukesChange | 12676 nuclear_bombs | nuclear_bombs = u32@+72 | 12677 add_nuclear_bombs | sub_141097B10(rp(*(cc+4880)+24), +72 推定): stock += 枚×1000×1e-5, clamp [0, 99900000000] (核弹库存 = cc+4880) |
| CCountryStartingTrainChange | 19710 starting_train_buffer | 同键 = u64@+72 | 19710 | sub_1406CF380(cc)+424 = +72 (开局火车缓冲) |
| CCountryStartingTruckChange | 19699 starting_truck_buffer | 同键 = u64@+72 | 19699 | sub_1406CF380(cc)+416 = +72 (开局卡车缓冲) |
| CCountryCapitalChange | 10315 capital | capital = u32@+72 | 10315 | sub_140710DD0(sub_140BB4390(+64), +72, 1) 设首都 (重存 vt[1]=0x141540E70) |
| CCountryDecisionChange | 11142 decision | decision = CString@+72 | 11142 | 决策名加载入国史记录 (vt[1]=0x141540EB0) |
| COOBChange | 12137 oob | oob = CString@+72 | 12137 | OOB 名加载入国史记录 (vt[1]=0x141540F90) |
| CRevolutionaryTagChange | 13312 revolutionary_tag | tag = 名串(+72 革命 tag) + ideology = 名串(*(+80)+20) | 13312 | sub_1406D20A0(国, +80 意识形态 def, +72); **= CCountryHistory 后代 (兼容器身份, 自覆写 [1][2][4]: writer 0x1415411D0 / reader 0x141540B30)** |

容器与兜底: 国史容器 = **CCountryHistory** (vt 0x1429D5D18, 基 72B + **+64 = 国 tag**; writer 0x141540FF0 = 州/国史容器共用, 双分支 = 条目+48≠0 → 写日期键块, 否则调条目 vt[1]; reader 0x141540190 = 日期键 → 造壳 → Load → 注册日期); **CHistoryAddEffectCountry** (336B, vt 0x1429D5DC0, [13]=89 effect) = 工厂默认分支兜底 (一切未识别键 → 内嵌 CEffect 列表@+72 + scope 子对象@+160; Execute 0x14153FF80 与州变体共享 = 重放效应; vt[1] = 断言桩不回流)。州侧镜像族见 §4.13.7。

B15 后勤面板消费 — 行数值 = sub_141D9BFE0 → sub_141371450 聚合桶 (kind 枚举 loc+写入链双证定名); **logi+32 = 属主 CCountry*** (ctor sub_14136FA80 直证, CCountry ctor a1[499]=cc+3992 处传入):

| 值 | 名称 | 语义 |
|---|---|---|
| k1 | 师增援 |  |
| k2 | 空军增援 | 读端定案 (sub_141D9BFE0 写 panel+1432 / sub_141D9D280 累加 panel+1464, 均 `sub_141371450(...,2,...)`); **写入端未定位** — 桶 push 入口 sub_1415173C0 (CLoopHistory::Push) 与包装 sub_141516980 在全 dump 均无调用者 ⇒ 走间接调用 (vt 槽); 桶机制 = CLogisticsStatus ctor sub_14136FA80 建 19 个 CLoopHistory 桶 (i==17 特判 v17=7) |
| k3 | 租借 |  |
| k4 | 驻军增援 |  |
| k5 | 行动 (operation) |  |
| k6 | 需求合计 |  |
| k7 | 增援交付完成 |  |
| k8 | 增援交付完成 |  |
| k14 | 窗口内交付部队装备合计 | status 条分子, LOGISTICS_STATUS "need covered by production"; 窗口 = define **LOGISTICS_PAST_WEEK = 7** (dword_143334C2C) |
| k15 | 库存现值 |  |
| k18 | 补给系统装备消耗 | country_supply.cpp:0x335 断言链 (卡车/火车) |

行槽字段:

| 偏移 (logi) | 名称/语义 |
|---|---|
| +1408 | 已承诺合计归一百分比 |
| +1440 | 可用余量 = k6−Σk1..k5 |
| +1384..+1488 | 行槽全字段定名区: 效率/库存/需求/结余/可增产/产量 |

#### 4.3.14 CFocusStatus (= CNationalFocusProgress, RTTI 正名)

fp = *(cc+4992); ctor 0X1402CB9C0 (malloc 0xB8); vt BASE+0X2739D50, slot2 = writer 0X1402DC910。

| 偏移 | 类型 | 名称/语义 | 写门 |
|---|---|---|---|
| +8 | CCountry* | **宿主国回指** (首字段定案) | runtime-only |
| +16 | CNationalFocus* | current 对象 → 名 SSO@+24 | ptr≠0; def 对象; **GUI: 国策进度块 label/goal_ico(_shine)** (外交 active_national_focus_info; 门 sub_141433D90 情报) |
| +24 | CNationalFocus* | current_continuous (0x36E5) → 名@+24 | ptr≠0; GER/test1/test2 0 现, BHU 6 例; reader Country.focus.current_continuous; def 对象 (CContinuousNationalFocus 系) |
| +32 | CNationalFocus* | shine 容器数据指针 — {d, c} 8B focus 指针, 名 = C 串@elem+24 (与 completed 同形态) | c>0 整块 |
| +40 | u32 | shine 容器 cap | ctor |
| +44 | u32 | shine 容器计数 | c>0 整块 |
| +48 | 匿名结构 (NNB 形状)* | shine 容器 alloc |  |
| +56 | fixed×1e-5 | progress | **≠0 才写**; **GUI: 国策进度条** (progressbar = 1e7×progress/total; NO_NATIONAL_FOCUS / UNKNOWN_INFO) |
| +64 | CNationalFocus* | completed 容器数据指针 — {d, c} 8B CNationalFocus 指针 | 逐元双形态 (下表) |
| +72 | u32 | completed 容器 cap | ctor |
| +76 | u32 | completed 容器计数 | 逐元双形态 (下表) |
| +80 | 匿名结构 (NNB 形状)* | completed 容器 alloc |  |
| +88 | RH 图 | **本视角国自有完成图** (定案): 写入侧 CompleteFocus sub_1402DC740 → sub_1402CD590 = **fp+88 FNV(def) RH 插** 直证; 读侧 sub_1402D6C40 = 命中且 byte+4≠0xFF (**0xFF = 空桶/墓碑**); 桶结构 32B {base@+88, buckets@+96 (默认空桶哨兵 &unk_143086980), mask u32@+108, extra u8@+112, load_factor f32=0.9@+116} — 16B 桶 {val*@0, dist u8@+4, key 元针@+8} | originator 查询①; ctor 逐字段; runtime-only; **GUI: 焦点块状态码** (fp+88 命中 → item+48 状态 1..4 五状态窗 +56..+88; **状态 2 = 查看国自己完成**; 联合国策进度住工作国 fp, UI 经 sub_140DF65C0 GetWorkingCountry 换 fp 显示) |
| +120 | CNationalFocus* 向量 | **available focuses 可选候选缓存 (定案)** {d@+120, cap@+128, c@+132, alloc@+136} — 8B CNationalFocus* 按 focus id(e+8) 有序二分插入 (重建 0X1402D7340: 前置容器空或全 ∈ completed 才插入); 语义链: CompleteFocus 尾段逐 def+1440 前置反向依赖表 → 前置满足 (sub_1402DB370 查 def+1392 vs fp+64) 且未录 → fp+120 插, 完成时自移出, daily tick 作候选集筛选推进; 互斥在选择时判定 (ExclusiveItem 状态 4 输入 = def+1416 互斥组任一元 ∈ fp+88, sub_1402CEFA0 — 与 fp+120 无关) | runtime-only |
| +144 | 匿名结构 (桶) RH 桶数组 | originator RH 表基部位 (桶宽未坐实 — 书内「镜像 +88 表结构」即 32B 桶之说未被验证, 待裁); 联合国策 originator 记录: joint (def vt[14]) → fp+144 插 {def→+16=完成者 tag}, 与 fp+152 originator 查询 sub_1402D1930 同族 (§4.3.13) | 高置信 |
| +152 | 匿名结构 (24B 形状) RH 桶数组 | originator 表 {buckets@+152 (默认 &unk_1430869A0), mask@+164, extra@+168, load f32=0.9@+172} — 24B 桶 {dist@+4, key 元针@+8, tid u32@+16} | 查询② (读侧两链: 完成图→originator 表), 未命中 → tid=0; ctor 逐字段 + FNV-1a 指针哈希; runtime-only |
| +176 | uint8 | paused | **反向: ==0 时写 `paused=no`; ==1 整叶省略**; 且 focus 块无内容时整块不写 (paused 门 = ru8==0 且 has_content) |

completed 双形态:

| 形态 | 判别 | 读法 |
|---|---|---|
| 联合国策 | 元 vt+112 (slot14) ≠ BASE+**0x11D220** (万能 return-0 stub = sub_14011D220, dump 定案 `return 0`; CNationalFocus 基类 vt = BASE+41040872, 派生联合国策覆写返 1) | 写 `completed={ <TAG> <name> }` (originator tid 经 sub_1402D1930 三链查询) |
| 普通国策 | 上判不成立 | 写 `completed="name"` (引号, 名 SSO@e+24) |

RH 哈希 (fp+88 / fp+152 表通用):

| 项 | 值 |
|---|---|
| 哈希函数 | FNV-1a 32bit 作用于指针 8 字节 (h=0x811C9DC5, `h=((h^b)*16777619)&0xFFFFFFFF`) |
| 桶定位 | buckets + 24*(h&mask) |
| 探查 | RH 距离递增 (不环绕, 尾部 extra 槽吸收) |

#### 4.3.15 国策 def / 树 / inlay (CNationalFocus def / CJointNationalFocus / CNationalFocusTree / CFocusInlayWindow)

CNationalFocus def (size 0x620, ctor 0X1402CB440):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +888 | — | ai_will_do 值块 (token 10819) |
| +1392 | — | prerequisite (token 13243 直证) |
| +1416 | — | mutually_exclusive (token 13242 定案: 名直证 + vt[9] 全链 + sub_1402CFE50 + ExclusiveItem 四证) |
| +1440 | 匿名结构 (元素待裁) 向量 | **16B 前置反向依赖 (dependents) 表** {依赖方 def*, u8 = 依赖方前置组多备选旗} (写入 = 依赖解析 Finalize sub_1402D4D90, 断言 "Couldn't find dependency" nationalfocus.cpp:2472 直证; 消费 = CompleteFocus sub_1402CD590 → §4.3.14 fp+120 候选增量; 互斥真身 = +1416 组指针表不变) |
| +1464 | uint8 | historical 徽标门 (死门, 见下 ⚠) |
| +1467 | — | complete_tooltip (token 13748; 活) |
| +1468 | uint8 | available_if_capitulated (死门, 见下 ⚠) |
| +1469 | — | Finalize select_effect 链 (活) |
| +1470 | uint8 | 「dynamic name→Repopulate 重算名」旗 (死门, 见下 ⚠) |
| +1471 | uint8 | dynamic/shared 实例旗 (推定; 死门, 见下 ⚠) |
| +1480 | 匿名结构 (元素待裁) 向量 | will_lead_to_war_with 表 (CompleteFocus 发事件 9/10) |
| +1528 | MSVC SSO | (vt[3] Parse 写) |
| +1560 | — | 源行号 (vt[3] Parse 写) |

旗簇 ctor 默认值 (def+1464..+1473): {0,1,0,0, 0,1,0,0, 1,0}。

⚠ 死门机制 (机器码级定案): dynamic / historical / available_if_capitulated / continue_if_invalid / internal 五 token 被解析器 9 处尾跳 `jmp sub_1424C0C00` 空吞, 无写回 — def+1464 historical 徽标门 / def+1468 available_if_capitulated / def+1470 dynamic 重算名旗 / def+1471 (推定 dynamic/shared 实例旗) / CFocusInlayWindow def+208 internal 均死。⚠ 行为性结论: mods 依赖 historical= / available_if_capitulated= / dynamic= 的 UI 效果在解析层不生效。

CNationalFocus def vt (15 槽全图, 已点名槽):

| 槽 | 函数/语义 |
|---|---|
| vt[3] | Parse (写 +1528 SSO / +1560 源行号) |
| vt[9] | 可开始 (含 sub_1402CFE50 = 可开始 ∧ 与在研不互斥) |
| vt[11] | `+1471‖bypass 触发器非空` |
| vt[12] | ShouldBypass (共享实例自动绕过; sub_1402DB420 带域封装) |
| vt[14] (112) | 联合谓词 (基 ret0; CJointNationalFocus const-true) |

CJointNationalFocus (size 0x728, token joint_focus=14390):

| 偏移 | 名称/语义 |
|---|---|
| +1568 | 触发器 |
| +1656 | 双效应块之一 |
| +1744 | 双效应块之二 |

GetWorkingCountry = sub_140DF65C0 (逐国 fp+16==def 反查); 工厂 sub_1402D83B0 (shared_focus=14364→CNationalFocus / joint_focus=14390→CJoint)。

CNationalFocusTree (ctor sub_1402CBA60):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +104 | 32B SSO | 串表 |
| +128 | 指针表 | 快捷条指针表 |
| +152 | CFocusInlayWindowInstance 向量 | inlay 实例表 (56B 元 = CFocusInlayWindowInstance 内联, 下表) |
| +176 | — | CNationalFocusPosition (token 19276 initial_show_position) |
| +256 | MSVC SSO | 替代树名 (+272 = size 作门) |
| +296 | 值块 | country (token 10394) |
| +352 | — | 未名 |

CFocusInlayWindowInstance (56B 内联元):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vt |  |
| +8 | u32 | =357 类登记 id |
| +16 | {x,y} | position |
| +24 | def* | CFocusInlayWindow def |
| +32 | CPositionOverride 向量 | CPositionOverride 表 {104B 元: +8 x / +12 y / +16 CAndTrigger} |

token id/position/override_position = 11/76/10242 定案; 存档与树文件共用同一 vt[4] 链。

CFocusInlayWindow def = 216B 数据库项 (TGameItemDatabase; 单例 qword_14332EFD0; 目录 common/focus_inlay_windows):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | — | id |
| +16 | 匿名结构 (元素待裁) 向量 | scripted_images 表 {64B 元} |
| +40 | 匿名结构 (元素待裁) 向量 | buttons 表 {192B 元} |
| +64 | 匿名结构 (元素待裁) 向量 | progressbars 表 {248B 元} |
| +88 | MSVC SSO | window_name |
| +120 | CAndTrigger (88B) | visible |
| +208 | — | 本国可见门 (internal; 死门, 见上 ⚠) |

token 全图 16520/10233/10275/14957/11562 定案; 每条目 push 104B CFocusInlayWindowView (池 win+1448 {c@1460}), Setup 建 `<def+88名>_instance`。

#### 4.3.16 country.fuel_status (fs = rp(cc+5504), vt 0X298B3A8; writer 0X1410F8710 / reader 0X1410F7790 / 条目 0X1410F8650 / 列表 0X1410F09F0)

| 字段 | 量纲 | 偏移 (fs) | 备注 |
|---|---|---|---|
| fuel | Q15 | +8 | writer %.5f 定宽 |
| max_fuel | Q15 | +16 | writer %.5f 定宽 |
| fuel_gain | fix5 | +24 | AE590 族, writer 去尾零 |
| fuel_gain_from_states | fix5 | +32 | AE590 族, writer 去尾零 |
| fuel_gain_from_lend_lease | Q15 | +40 | 对象层 fuel 字段已按 Q15 口径 |
| fuel_consumption_from_lend_lease | Q15 | +48 | 同上 |
| fuel_cost | fix5 | +56 | AE590 族, writer 去尾零 |
| fuel_gain_per_oil | fix5 | +64 | AE590 族, writer 去尾零 |
| fuel_consumer_data (15127) | fix5 | data@+72, count@+84 | 24B 条 {priority u32@0, requested fix5@+8, received fix5@+16}; index = writer 循环计数器合成; 实证恒 3 条/国; 元素 requested/received 槽位名归属**定案** (writer sub_1410F8710 循环体: 元素 +8 发 token 15132 `requested` / +16 发 token 15130 `received`, 步长 24B — 发射序键序反, 字段归属与表序一致; history 环形条 sub_1410F8650 同证); **GUI: 油料子窗** (sub_141D900D0 / sub_141732C30; logistics_fuel_window; 断言 "invalid fuel type") **+ 优先级按钮** (低/中/高 ×3 域 → CSetFuelPriorityCommand {tag@+40, category@+44, level@+48}; 域号 = 行+8) |
| history_index (15135) | u32 | +200 | |
| remaining_hours (15134) | u32 | +204 | |
| history 环形缓冲 | 混合 | 哨兵内联@+96 (index=−1 先写); 24 槽 rp(+176)+80j (index=j 合成) | 80B 条: fuel Q15@0 / fuel_gain fix5@+8 / consumed Q15@+16 / requested fix5[3]@+24 / other Q15@+48 / received fix5[3]@+56; requested/received 固定写 3 值匿名块 → 提取键 .#1 |

全部字段**恒写** (零值也写, 无省略规则); history 写序 = 物理槽序 −1,0..23 (非时序旋转); 存档实证 439 国 × (10 标量 + 3 consumers + 25 history 条) = 86,483 叶全覆盖。

#### 4.3.17 country.experience_status (es = rp(cc+5512), vt 0X29A80C0)

| 字段 | 量纲 | 偏移 | 写门 |
|---|---|---|---|
| army | Q15 (i64/32768) | +16 | 仅 ≠0 写 |
| army_daily | Q15 (i64/32768) | +24 | 同上 |
| army_daily_training | Q15 (i64/32768) | +32 | 同上 |
| navy | Q15 (i64/32768) | +40 | 同上 |
| navy_daily | Q15 (i64/32768) | +48 | 同上 |
| air | Q15 (i64/32768) | +64 | 同上 |
| air_daily | Q15 (i64/32768) | +72 | 同上 |
| num_armies_for_training | Q15 | +80 | **恒写含 0** |
| xp_by_template.#N | — | {d@+88, c@+100} 24B 元 (vt 0X295A5B0) | 容器 writer 0X1412A92B0 全槽迭代无跳过, **空槽也写空块 → #N 含空槽** (容器序 1 基) |
| xp_by_taskforce.#N | — | {d@+112, c@+124} 40B 元 (vt 0X2958040) | 同上; 另 on_mission i32@+32 >0 (14668) + mission 门 byte@+28≠0 值 u32@+24 (11450) |
| xp_by_airwing.#N | — | {d@+136, c@+148} 24B 元 (vt 0X2965260) | 同上 |

元素写门 (template 0X141961B30 / taskforce 0X141961BB0 / airwing 0X141961AB0):

| 字段 | 键 token | 写门 |
|---|---|---|
| combat | 10518 | u32@+8 ≠0 |
| training | 12218 | u32@+12 ≠0 |
| ref (division / task_force / air_wing id 对) | 471 / 15157 / 13161 | {type@+16, id@+20} 任一 ≠0 **且 sub_14221F310(e+16) ≠ 0** (返 0 = 目标已不存在 → 不写; KR SIC 三条失败 ref 实证) |

⚠ ref=0 槽: training 照写, 仅 division 叶省 (ref 全 0 孤儿整体不写的口径不成立)。

#### 4.3.18 CConvoys (cc+4608; writer 0X141022CF0 + 池 writer 0X141012DB0; 池类 = **CEquipmentVariantPool** 64B, vt 0x142749270, reader 0x1410113B0)

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
| 五容器族 | failed_naval_invasions {d@+5568, c@+5580} 64B 元 / raids {d@+5592, c@+5604} 80B 元 / force_concentration_target {d@+5624, c@+5636} 24B 元 / expeditionary_force_data {d@+6160, c@+6172} 48B 元 | 元素字段见下表; 四容器块键 token = writer sub_14066B3F0 逐容器 sub_1424C2E20 调用定案: +5568→19828 / +5592→19184 / +5624→11171 / +6160→15433 (离线 token 表对证) |
| desire/reserved 簇 (13 连 fixed×1e-5) | +5704..+5800 (步进 8) | desire_unlock_land/naval/air_doctrine (+5704/5712/5720) / desire_update_land_template (+5728) / desire_upgrade_land/naval/air_equipment (+5736/5744/5752) / reserved_xp_land/naval/air_research (+5760/5768/5776) / desire_unlock_army/navy/air_spirit (+5784/5792/5800); writer sub_1424C34F0 逐槽, 键序与偏移序不齐 (19812-19819 / 15795-15797 / 19801-19803 区段) |

五容器族元素字段 (块门 = 各 count>0; 元素发射 = writer 逐容器调元素 vt 序列化):

| 容器 (块键) | 元素+N | 类型 | 字段/语义 | 写门 |
|---|---|---|---|---|
| force_concentration_target (11171) | +8 | u32 | target | 恒写 |
| force_concentration_target (11171) | +12 | u32 | from | 恒写 |
| force_concentration_target (11171) | +16 | i64 fixed×1e-5 | progress | 恒写 |
| expeditionary_force_data (15433) | +8 | u32 | tag (国 idx → 引号串) | 恒写 |
| expeditionary_force_data (15433) | +12 | u32 | casualties | 恒写 |
| expeditionary_force_data (15433) | +16 | u8 | do_not_send_forces (yes/no) | 恒写 |
| expeditionary_force_data (15433) | +17 | u8 | pull_forces_back (yes/no) | 恒写 |
| expeditionary_force_data (15433) | +32 | CGameDate {hours@+32, vt2@+40} | date | hours≠43808760 |
| raids (19184) | +8 | u32 token | type (token 名, 裸) | 名非空才发 |
| raids (19184) | +16 | SRaidTarget 块 | building ptr@+0 → template token@*(bld+0x1E0)+8 裸 / location u32@*(bld+0x1D8)+108; province ptr@+8 → +164; state ptr@+16 → +88; leader id 对 {type@+24, id@+28}; leader_province ptr@+32 → +164 | 块恒写; leader (ty\|id)≠0 |
| raids (19184) | +64 | CGameDate {hours@+64, vt2@+72} | end_date | 恒写 |
| failed_naval_invasions (19828) | +8 | CProvince* | province = u32@*(el+8)+164 | 恒写 |
| failed_naval_invasions (19828) | +16 | u32 列 {data@+16, count@+28} | invasion_order_ids | ptr 有效即写 |
| failed_naval_invasions (19828) | +48 | CGameDate {hours@+48, vt2@+56} | invasion_date | 恒写 |

#### 4.3.20 CCountryReportsManager (crm = rp(cc+4064); vt 0x1429D10A8)

country_reports 节点 61 叶**全部恒写** (439 国 0 值照写; writer 无条件写)。

| 偏移 | 类型 | 名称/语义 | 写门/格式 |
|---|---|---|---|
| +16 | uint32 向量 | log 向量数据 — SDailyEntry 32B = 8×u32; 存档编码: 逐记录 "k v1..vk" (k = 最末非零槽 1 基), 全零记录只写 "0", 拼接单 token 流行 → `log.#1` (每国恰一块) | 门 计数@+28>0 |
| +24 | uint32 | log 容器 cap | |
| +28 | uint32 | log 容器计数 | |
| +32 | 匿名结构 (NNB 形状)* | log 容器 alloc | ctor |
| +40 | uint32 | days (tok 10605) — 读档丢弃族, mem 运行时重算 (GER=4) | 恒写 |
| +44 | uint32 | index (tok 524) — 同上 (GER=39 = 末条下标) | 恒写 |
| +48 | CGameDate vt | **date 数据对象 vt** (内嵌 CGameDate@+48, hours@+56) | ctor |
| +56 | uint32 | date hours (内嵌 CGameDate@+64) — 休眠国哨兵 43808760 **照发** "1.1.1.1" (存档 337 国实证; 不用 SL.date 哨兵抑制版, 段内自算) | 恒写 |
| +64 | CGameDate vt | **date 序列化代理 vt** (ADEC0 规则: hours = 代理−8 = +56) | ctor + writer ADEC0(0x284A, a1+64) |
| +72 | NCountryStatTracking::CConstructedBuildingsTracker* | construction 容器数据 (0x28 对象: {vt, data@+8, cap@+16, count@+20, alloc@+24, owner@+32}; RTTI 名直现) (writer 0X141C32D50: for i=0..18 恒写, 值 = *(*(obj+8)+4i) 纯 u32; 查不到默认 0) | 恒写 19 键; token 序 = CR_CONSTR 序 = 存档文档序 |
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

sys = **CPowerBalanceSystem\* = *(gs+1104)***; vt 0X296FCA0; 容器 {data@+8, count@+20};
400B 条目 = CPowerBalance (vt 0X296FC50 RTTI 直证; ctor 0X140E54DD0);
writers 0X140E58E30 (容器) / 0X140E58C50 (元素)。

CPowerBalance 主表:

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CPowerBalance | 不序列化 | |
| +8 | uint8 | 有效位标志 | 不序列化 | ctor = 1 |
| +16 | CPowerBalanceDatabase 条目* | template | 恒写 | def 对象; *(def)+16 = MSVC 引号 |
| +24 | CPowerBalanceSide* | left_side | 恒写 | ctor = null 单例 qword_14333A070; SetSides sub_140E58330 经注册表换真身 |
| +32 | CPowerBalanceSide* | right_side | 恒写 | |
| +40 | CPowerBalanceSide* | trending_side | 恒写 | 同 template (+16) |
| +48 | fixed×1e-5 | value | 恒写 | |
| +56 | 容器 24B | countries | c>0 且 idx>0 | {data@+56, cap@+64, count@+68, alloc@+72}; 元 = u32 国 idx → 引号 tag |
| +68 | uint32 | countries 计数 | c>0 且 idx>0 | |
| +80 | 容器 24B | modifier | 恒写循环 | {data@+80, cap@+88, count@+92, alloc@+96}; 元 = 8B 指针 → MSVC@ptr+424 引号 |
| +92 | uint32 | modifier 计数 | 恒写循环 | |
| +104 | 容器 24B | ranges 合并视图缓存 | 不序列化 | {data@+104, cap@+112, count@+116, alloc@+120}; 8B 指针 → 1856B CPowerBalanceRange; Rebuild sub_140E58950 = 左 ranges + 右 ranges + def ranges 合并排序; 连续性校验 sub_140E56190 ("gap/overlap detected") |
| +128 | 容器 24B | 左侧 ranges 收集暂存 | 不序列化 | {data@+128, cap@+136, count@+140, alloc@+144}; Rebuild merge 源 |
| +152 | 容器 24B | 右侧 ranges 收集暂存 | 不序列化 | {data@+152, cap@+160, count@+164, alloc@+168} |
| +176 | CPowerBalanceRange* | 当前/默认 range 缓存 | 不序列化 | |
| +184 | CModifier (内嵌 192B) | 平衡自身修正块 | 不序列化 | 运行时合成; 序列化走 +80 指针数组非本内嵌; 全布局见 §4.3.8 通用表 (分区见下方映射表) |
| +376 | 容器 24B | sides | c>0 | {data@+376, cap@+384, count@+388, alloc@+392}; 80B 元素 = CPowerBalanceSideInfo (ctor 0X140E55020, 下方子表) |
| +388 | uint32 | sides 计数 | c>0 | |

注 (写入点): +176 唯一写入点 = sub_140E58770 (Rebuild 尾调): min 含 / max 排他 /
max==100000 哨兵; 区间切换时执行旧/新 range 的 on_deactivate/on_activate。
注 (读点): sub_140E55EA0 模式 1 = 名比对直读 +176, 467 = 之上, 468 = 之下。
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
| +0 | vt | CPowerBalanceSideInfo | |
| +8 | MSVC SSO 32B | id | 引号 |
| +40 | uint32 | **id 的 FNV-1a ci-hash (int32 截断)** | ctor sub_140E55020 `*(u32*)(a1+40) = *(u32*)(a2+32)`; 源 +32 由哈希器 sub_140612C40 写入 (常量 2166136261/16777619 + 大小写折叠); 与 +8 的 id SSO 串配对 |
| +48 | MSVC SSO 32B | gfx | 引号 |

CPowerBalanceSide 主表 (~288B; ctor 0X140A8B8C0):

| 偏移 | 类型 | 名称 | 写门 | 备注 |
|---|---|---|---|---|
| +0 | vt | CPowerBalanceSide | 不序列化 | |
| +8 | uint8 | valid | | |
| +16 | MSVC SSO 32B | name | | |
| +48 | u32 | id | | **u32 FNV-1a ci-hash** (ctor sub_140A8B8C0 初值 −1); 赋值 = 自身 reader vt[4] sub_140A8ED10 case 11 → sub_140612C40(&v6, a2, a1+16), hash 落 +16+32 |
| +56 | MSVC SSO 32B | icon | | |
| +88 | CEffect (内嵌 88B) | on_activate | | 键 15557 |
| +176 | CEffect (内嵌 88B) | on_deactivate | | 键 15558 |

注: CEffect 88B 复合块形 = {vt CEffect, children vector@+8 c@+20, MSVC@+56}。
注: SetSides sub_140E58330 换侧时逐国执行旧侧 on_deactivate (+176) / 新侧 on_activate (+88)。

#### 4.3.22 CPowerBalanceRange (1856B = CProgressSection 1808B + 48B 尾)

CProgressSection = 1808B 具体类; CPowerBalanceRange = 之 + 48B 尾。键名经
各自 reader + common/bop 脚本逐键对账: **CProgressSection 的 reader = sub_140A12670**
(vt 0x1427197D0: case 675/676 = min/max +8/+16, 10876 = +568 CRule, 15557/15558 = +1584/+1672 CEffect,
10597 = +24 CStaticModifier); **CPowerBalanceRange 的 reader = sub_140A8ECE0** (vt 0x14293FFA8, 仅 case 11
→ id 串 +1816 / hash +1848); CPowerBalanceTemplate 的 reader = sub_140A8EDD0 (vt 0x142940050);
CPowerBalanceSide 的 reader = sub_140A8ED10 (vt 0x142940000 [4])。四者非同类。
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
| +1848 | u32 | id hash | | **u32 FNV-1a ci-hash**; 读取点 = 自身 reader vt[4] sub_140A8ECE0 case 11 → sub_140612C40(&v4, a2, a1+1816), hash 落 +1816+32 |

#### 4.3.23 国级周期更新入口 (hourly / daily / weekly / monthly 时序钩子)

时间推进链 (§4.2) 逐国调用的国级行为入口 (探针域 + country.cpp source_location 定案):

| 入口 | 函数 | 调用时机 | 要点 |
|---|---|---|---|
| CCountry::PostHourlyUpdate | sub_140705630 | hourly 主调度六阶段之 postHourlyUpdate 串行段 (§4.2.6) | **on_daily / on_daily_<TAG> 派发点**; 判据 `(tag + gs+1128 总小时) % 24 == 0` → 每国每天恰一次, 时辰由 tag 固定 (country.cpp:4861) |
| CCountry::DailyUpdate | sub_1406E76A0 | CGameState::DailyUpdate 全量国循环 (§4.2.7) | 探针 "country.daily"; 门 = cc+1156>0, 活跃分支 31 步 (内战目标/exile_divisions/人力·生产·资源·科研·部署/市场/政治/外交/核弹/焦点/后勤/燃料/operations/经验/志愿远征军/fleets/railway_guns/**投降流亡 sub_1406E16C0**/trade_influence/剧场/queued_events 派发); on_border_war_lost 判据 = 控制州 state+2149 活跃旗 且 进度 > define BORDER_WAR_VICTORY (派发后 sub_1409DDA30 熄火); "country.calc_modifier" (sub_1406DADE0) = 13 pass 修正重算 (§4.2.7 备注) |
| CCountry::WeeklyUpdate | sub_140718CA0 | CGameState::WeeklyUpdate 国循环 (§4.2.8) | 周累加族: cc+5312 宣传稳定惩罚 clamp [-0.2,0] / cc+4304 stability / cc+5320..5344 四战争支持度惩罚 / cc+4312 war_support 双 clamp / WEEKLY_MANPOWER (mdef 62) + 流亡 mdef 588 / 占领日志 GARRISON_LOG_MAX_MONTHS(12) 清理; major 断言 cc+5210 一致性 (country.cpp:5793/:5810); **on_weekly / on_weekly_<TAG> 派发点** |
| CCountry::MonthlyUpdate | sub_140703490 | CGameState::MonthlyUpdate 国循环 (§4.2.10) | 门 = owned_states(+1156)>0; 十段: dip 月更 (MONTHLY_LEASED_IC_DECAY) / **major 全量重算** (无宗主 && is_top_ic(cc+5211) && 工厂 ≥ MAJOR_MIN_FACTORIES=35 → cc+5210, 补判 0.7×top 均值) / calc_modifier pass / 州征兵 + **阵营人力上缴** (token 10476, faction+2288 记账 + mdef 648) / 改善关系 / **on_monthly / on_monthly_<TAG> 派发点** / 玩家 tag 管理器引用计数 / **季度舰队重整** (月长表直读, 1/5/9 月, sub_140218EB0) (country.cpp:5677) |
| sub_1406FF1F0（国级按位更新派发器） | sub_1406FF1F0 | 双入口: ① postHourlyUpdate 阶段① 带本小时累积修改位, 算毕 cc+4320 清零 (§4.2.6); ② CSelectEventOptionCommand::Execute 尾部带掩码 0x0FFFFFEF (§4.33.18) | 二参 = 位掩码, 按位派发 (country.cpp:8857): bit0 sub_140716580 (无参) / **bit1 = CalcMod 修正重算 sub_1406DADE0** ("CalcMod for <tag>" + supply_factor 误用警告 :8863, cc+1464 容器 find token 566) + sub_140E70C80(\*(cc+3944)) / bit2 sub_1406DD0C0 / bit3 sub_140CFE770(cc+808) / bit4+5 同现门 sub_14070C890 / **bit7 sub_140D46650 = 外交状态 on_action 评估** (diplomacy.cpp, on_war / on_uncapitulation 串; §4.2.9) / bit8 sub_14070BDB0 / bit9 sub_140E6C810(\*(cc+3944)) |

> 备注: hourly 主调度并行段的排序键 = `cc+5488 (double)` 升序 (插入/并行归并两套)。
> **cc+5488 定案 = 每国小时更新耗时 EWMA (α=0.02s)** — 纯自测量负载均衡键:
> sub_1406FDBA0 头 stamp cc+5496 / 尾 sub_140CFEAF0 写 5488。
> 备注: 活跃国门 = owned_states cc+1156 > 0 (hourly/daily/weekly/monthly 四级共用)。
