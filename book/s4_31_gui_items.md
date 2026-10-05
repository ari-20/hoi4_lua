

### 4.31 GUI 行件与条目族 (散簇行件 / 条目 / 图标行)

> **定位**: 主视图/面板本体与地图模式基础设施见 §4.30; 本册收纳**全部 GUI 行件/条目类的类布局**——
> 行件/条目/图标/行级 PopUp (Item / Entry / Icon) 的 (元素, 取值函数) ↔ (对象+偏移) ↔ (语义) ↔ (loc key)
> 映射, 与各域册迁入的类布局表并列 (尾段 §4.31.90 起)。基类槽语义 = §4.00.2/§4.00.5/§4.00.6。

#### 4.31.1 散簇·CCountry 家族残留 (16 类)

**入口链**: ConstructionsView target = view+1392 国语境 (vtable[20]=tag); Deployment/
Doctrine/OfficerCorp 三视图 target = +1408 会话子控制器 (非游戏对象);
MilitaryOverview = 无存储 target 现取本地玩家; IntlMarketView = +1408 内嵌市场
窗控 + tag 语境。方法学: [14]/[15] 在本族全为 build/teardown 布线对, 真
populate 挂 @48 facet[9] 或 [4]; 8 item 类中 7 个仅 dtor 与基不同。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 建设视图行集 | populate | **ps+112 general_lines** / 民池 val(888)/+40(920)/+64(944) / cc+3944 | §4.8 命中; 三槽语义已定案 = 总量/建造已分配/生活消费品 (§4.8.9) | — | 定案 |
| 建筑条目点击开建 | item+32 建筑 def | 可建校验 → 地图选址模式 1/3; 候选 def+740 使能旗 | 全链定案 (机制) | — | 定案 / 候选推定 |
| 部署视图 | +1408 子控制器 | 玩家 tag → cc+3952 CDeploymentStatus; **dep+72 conveyors / dep+120 = 部署中单位列表 (定案)** | §4.18.10 命中+坐实 | — | 定案 |
| 军事总览三 tab | populate ×3 | cc+360 theatres / playthrough 三元组 | army/navy/air tab | ARMY_DIVISIONS / NAVIES / AIR_WINGS_ACTIVE∥THEATRES | 定案 |
| 学说视图 | +1408 scopedptr 子控制器 | **gs+1024 CDoctrineSystem 锚** / folder 库容器; folder 模板 token 12989 跳过门 | §4.6 命中 | — | 定案 |
| 军官团视图 | +1408 CCountryCharacterSelector | cc+3976→HQ 部署详情 / **cc+4080 候选池** | army/navy/air 三组 + captured_generals 件 | — | 定案 |
| 国际市场视图 | +1408 市场窗控 | **cc+4024 equipment_market / ps+672 cic_bank / ps+1184 consumer#5**; 市场列表条目+280 = convoy 占用数 (新发现) | §4.23.2/§4.8 命中 | — | 定案 / 新发现 |
| **CCountryHistoryEntry** | **数据类非 GUI** (CPersistent 指纹) | cc+4040 CLoopHistory 条目基; **writer sub_141541190 / reader sub_1415403C0** | **全新族**: 8 token 全解名 (revolutionary_tag/starting_truck_buffer/starting_train_buffer/add_nuclear_bombs/capital/decision/oob/set_convoys); 槽[13]=10394 "country" | — | **定案 (新族)** |
| 国/旗条目 ×5 | 各 ctor/Setup | item+32 国家 idx (sub_140BB5490) / item+1560 CCharacterStatus\* / +112/+120/+128 三指针 / +1320..1336 三槽 | FlagGridBoxItem/CharacterSelectionItem/LeaderTraitItem/EnemyFlagItem/OrFactionItem | countryflag_entry / advisor_traits_window / navallosses_dropdown_item / POLITICS_IDEA_COST_COMPACT | 定案 |
| 生涯档案国条目 ×2 | Setup | tag u32 / "BASE_GAME" 伪国行 | NCareerProfile 族 | CAREER_PROFILE_COUNTRY_ 前缀 | 定案 |


#### 4.31.2 散簇·海军将领 (CNavyLeaderItem / CNavyLeaderTraitWindow / CNavyLeaderWindow)

**入口链**: LeaderItem target = **leader 裸指针 @item+3944** (ctor a4 直存, 无
SetTarget 槽; 填充器 sub_141AD21D0); TraitWindow target = **leader idpair @基+120**
(基 CUnitLeaderTraitWindow SetTarget sub_1416D06C0); LeaderWindow target =
**CFleet idpair @win+7048** (可空 = 名册态; 双宿主 = 舰队视图+22240 指派态 /
CCountryOfficerCorpView **+8592** 名册态)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 将领条目全字段 | 填充器 sub_141AD21D0 | leader+64 名 / +288 tag_id / +3528+3540 traits / +3680 技能指针 / +3708 leader_type / +3912 owner CID / **四技能 +3944/+3960/+3976/+3992** | §4.4 命中 10 处; CFactionCommanderWindow 复用 a3=1 阵营指挥官列态 | navyleaderentry | 定案 |
| 特质树下级技能 | [8] 四技能刷新 | **技能 def DB = qword_14332F0D0 (等级+1, leader_type); def+444 = 下级 XP 阈值** | §4.4 新锚 | SKILL_NAVY_LEADER_LEVEL_* | 定案 |
| 将领窗指派/名册 | SetTarget sub_1416D06C0 | **CFleet idpair @win+7048; fl+176 = leader idpair 新消费点**; cc+4080+136 海军表 / cc+496 command_power / fl+224 name; **+7056 / +7024 池 / +3160 / +4448 / +5736** | §4.16/§4.3 命中; 命令族 CSetFleetLeaderCommand (ctor sub_14183BD10) {+40/+48} / CCreateUnitLeaderCommand (ctor sub_141144080) {+44=2 navy} / CChangeNavyLeaderDialog (ctor sub_141ED8F40/91A0, 窗名与 0x1020 未变, 布局 +4096..+4120) | navyleaderwindow | 定案 |
| 将领窗三按钮 | 绑定 sub_141ACE6C0 | **no_leader_button (cb sub_141ACAB40) / new_leader_button (cb sub_141ACAA10, feature 门 sub_1401AEB50(58) 隐藏) / show_ship_captains_button (cb sub_141ACC330)**; [10] 指派 sub_141ACA7F0 | — | — | 定案 |
| divisions_count 源 | 四读取函数 | **dword_1433364B8 = NDefines `ADMIRAL_TASKFORCE_CAP`** (1.19.3 唯一全局); 舰队/将领 UI「现数/上限 + FLEET_OVERCAPACITY_DESCRIPTION 超编」计算 | sub_140C18780 = `return dword_1433364B8` 纯 getter; defines 注册 sub_142070630 字面绑定同址 — 注册与 GUI 同源, 无副本 | FLEET_OVERCAPACITY_DESCRIPTION | 定案 |

#### 4.31.3 散簇·战争总览 (CWarOverView / WarButton / CWarAllyItem / CWarFactionItem / CWarRelationStripView)

**入口链**: WarOverView (0x5C50B) 无 SetTarget; target = **dip+792 战争一览
48B 元的同构副本** (side1 集@+23576/count+23588, side2@+23600/count+23612);
入口 = Reload[2]→populate sub_1418AC420 (13 窗件), Update @40[9] 门 →
sub_1418AFFC0 (页签/聚合头) + sub_1418ADFA0 (网格)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 战争一览网格 | sub_1418ADFA0 | **dip+792 48B 元** (§4.10 ✓; 构建器三调用点) + 聚合旗+23624 / 三过滤器+23625-27 / 双排序模式+72/+76 (1=participants…12-13=wargoal 成对升降) / +23544 展开派系表 | 同构副本 | waroverview_window | 定案 |
| 战争按钮 | 点击 = CButtonEventDispatcher@+32 → sub_1418AC180(view, idx) | **view 回指@+1320 + 战争索引@+1328 (-1=聚合)** | 聚合页签 tooltip | WAR_OVERVIEW_WAR_BUTTON_ALL | 定案 |
| 盟友行 | Setup sub_141E7B400 (+2616=国 tag) / Refresh sub_141E7B700 | dip+736 capitulated / cc+5210 major / **cc+4056 collaboration count@+52** / war rel token 14346+16+20 | 派系成员 24B 元 {tag@0, 旗@+16}; wargoal/collaboration 三图标选择 | war_ally_entry | 定案 |
| 派系行 | populate | **CFaction\*@+2656 (0=无派系聚合行)** + 成员向量副本@+2664; 三聚合列 (divisions/ic/casualties) sub_141E79030 | §4.5 ✓; 组 48B 元形态 | DIPLOMACY_NO_FACTION / war_faction_entry | 定案 |
| 关系条 | target 链 | +56 本国 tag (视图件自有) → dip+8 active_relations[对方idx] → **rs+744 _pWarRelation**; **+40 token 10637 / +44 侧模式 (1=initiator/2=receiver) 均属 CWarRelationStripView 自有字段** (基 ctor sub_141CA6730 写入; war 对象 writer sub_140D2DE80 无 10637) | relationstripview.cpp 直证; instigator/defender 选择子 sub_140D230C0/D0D960 (war+344 复用) | relation_strip_view | 定案 |
| war rel +72 / +73 双字节 | CRelation 基 | **+72 = 序列化 bool** (writer token 10469 / reader case 10469) / **+73 = 非序列化运行时抑制门** (8 读点语义统一: 非 0 → UI 视同关系不存在); CWarRelation 自身无写点。写点账目更正: sub_140D1E470 的 +72/+73 写 = **复位拷贝** (默认模板值 0, relation.cpp:2975 清链, dtor 调用) — 移列清点侧; sub_140E17F30 = ≥29 态通用状态机, case 9 `+73=1` 宿主类名未证 = CRelation, 归属降推定。**普通战争不置位 (活体直证)**: 两对战争 (rs+744 war 对象非空) 跑 6.5 个游戏月, +72/+73 读值恒 0 — **置位点定案 = CWarRelation::SetParticipants (0x140D24EB0) 同阵营腐局兜底** (sub_140D3F440 判真 → "Game corrupted" 日志 + rel+72 = 1, 对象照建永不生效; 业务名 = **IsCancelMarker**, relation.cpp:2533/:5481 断言实名, 全族 Add/Remove 以 !IsCancelMarker 前置; 普通战争恒 0 活体直证不冲突 — 该路径仅腐局触发) | sub_140D2DAA0 / sub_140D2B100 / sub_140D17AB0 (双字节清) / sub_140D1E470 (复位拷贝, 更正入清点) / sub_140D24EB0 (腐局置位, 唯一写点) | — | 定案 (+72/+73 语义 + 置位点 = 腐局兜底 IsCancelMarker + 普通战争恒 0) / 推定 (140E17F30 归属) |


**战争总览族vtable普查**（1.19.3 直读；零覆写位全未变）：

| 类 | 主 vtable（1.19.3） | 次表 | 备注 |
|---|---|---|---|
| CWarOverView | 0x142A12C98 | @40 / @64 | populate sub_1418AC420 / Reload 0x1418ABD10 |
| CWarAllyItem | 0x142A88080（19，仅 [0] 独享） | @24 0x142A88120（tooltip 0x141E79470） | ctor sub_141E77AC0，0xAA0 |
| CWarFactionItem | 0x142A881A0（[0]+[2]） | @24 0x142A88240 | [2]=0x1418AD410 与 WarButton ICF 共享 |
| CWarRelationStripView | 0x142A5F2B8（23，[19..21] 自填基纯虚） | @24 0x142A5F378 | ctor sub_141CA6940 |
| CWarOverViewWarButton | 0x142A12B18（19，[0] dtor + [2]） | @24 | ctor sub_1418A9BF0，0x538 |
| CGarrisonLogView | 0x142A00678 | @40 / @48 | §4.16 已载域 |
| CSubjectViewItem | 0x142A59288 | — | 附庸行件 |
| CNavyTheaterGroupItemBase | 0x142A87778 | — | 剧场行基 |
| CNavyTheaterGroupItem | 0x142A87920 | @24 | 剧场行 |
| CNavyTheaterFleetItem | 0x142A7DF38 | @24 | 舰队行 |
| CNavyTheaterFleetRowItem | 0x142A7EF28 | @24 | 舰队行件 |
| CNavyMilitaryOverviewItem | 0x142A6BB88 | @24 | @24[0] 0x141D36240 |
| CSubjectRelationStripView | 0x142A5F7C8 | @24 | 同族条 |

**CWarAllyItem 布局**（0xAA0）：+2608 view / +2616 tag dword（Setup `+2616=\*a3`）/ +2620 WORD=1（+2621 旗）/ +2624 country_name 元素群…+2712 call 钮 / +2696 vtable[67]+536 取件；Setup = sub_141E7B400（`+2608=a2 → Refresh`）；Refresh = sub_141E7B700（dip+736 capitulated / cc+5210 major / collaboration 计数 \*(\*(cc+…)+52) / view(+2608)+23576/+23600 侧集 / GFX_wargoal_icon_with_collaboration_icon 三图支）；tooltip @24[0] = 0x141E79470（调整器 a1+2592=tag, a1+2616=wargoal 件；loc PARTICIPANT/CAN_BE_CALLED_TO_WAR/FACTION_MEMBER_IS_FACTION_LEADER/DIPLOMACY_OPEN/WARSCORE_STATE_*/SURRENDER 全在）。

**CWarRelationStripView 布局**：token 10637 → +40 / 侧模式 → +44（1=initiator/2=receiver）/ 国 tag → +56；[19] 谓词 0x141CAA5D0（+56 tag → cc → +3976 dip → dip+8 active_relations → +744 _pWarRelation；**war+73 byte 抑制门不变**）；[20] 0x141CAAD10 / [21] 0x141CAD5F0；基 ctor sub_141CA6730。

> 页签点击链：CButtonEventDispatcher@+32 → sub_1418AC180(view, idx)：idx==-1 → sub_1418ABDB0（聚合）+ sub_141236980 刷新；否则单选支。

#### 4.31.4 散簇·世界紧张度+剧场组 (CWorldTensionEntry/WarEntry/PopUpWindow / CTheaterGroupAlertEntry/Item/SettingsView)

> ⚠ **警报行件族 ≠ 通知族**: 本节的 `C*Alert*` 三行件 (CTheaterGroupAlertEntry / CRegionAlertEntry /
> CGlobalAlertIcon) 属 **GUI 警报体系** (基类 = CGuiObject 系), 与 `NNotification` 通知族
> (§4.17, 基类 = CReloadableInterface + CTooltipHandler) **无 RTTI 亲缘**; 二者是并列的两套 UI 消息面。

**入口链**: TensionEntry target = **CThreatSource\*** (entry+40, populate
sub_1418B4360); PopUpWindow [1]=populate 主入口 (sub_1418B47B0: **CWorldThreat
@gs+1712 + 各国 dip+792 双源**); TheaterGroupItem target = **CTheaterGroup
idpair** (item+32, populate sub_141E6F9A0 逐次 resolve)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 紧张度条目 | populate sub_1418B4360 | **CThreatSource +8 tag / +16 threat / +24 final_threat / +48 date.hours / +64 label** | **5/5 全中 §4.25** (排序比较器三证) | world_tension 族 | 定案 |
| 紧张度战争行 | populate sub_1418B4550 | **dip+792 48B 元** (订阅拷贝@+1368/+1392); cc+1076 投降进度门 (新消费) | war 名经 CWarRelation assert 直证 | — | 定案 |
| 紧张度弹窗 | [1] populate sub_1418B47B0 / [11] 排序绑定 / [12] OnClose | **gs+1712 CWorldThreat + dip+792 双源** (§4.25/§4.10 ✓) | 四排序/战争按钮 | — | 定案 |
| 剧场组警报条目 | SetTarget sub_141E6D870 | **{kind u32@+1368, idpair@+1372}**; grp+8 idpair / +24 owner (§4.24 ✓) | **alert def DB 单例 = qword_14332F6A0+1944** (icon/严重度红黄金绿/双动作 三访问器) | — | 定案 / DB 新锚 |
| 剧场组行 | populate sub_141E6F9A0 | **grp+32 priority 序号 / +40 name (改名 CSetTheaterGroupNameCommand) / +72 orders_group / COrdersGroup+92 member 数求和**; **COrdersGroup+384 = _pTheaterGroup 回指 (assert 直证)** / +440 | 4/4 全中 §4.24 + 新锚 | — | 定案 |
| 剧场组设置 | [4] Refresh / @88[0] tooltip | view+4168 → item+32 间接解析; **COrdersGroup+432 = disband 门**; define dword_1433374E0 (每组上限/选中偏移基数) | THEATER_GROUP_CANT_DISBAND_DESC 双 loc 证 | — | 定案 |

#### 4.31.5 散簇·海军剧场/军事总览 (CNavyTheaterGroupItem(Base) / CNavyTheaterFleetItem / CNavyTheaterFleetRowItem / CNavyMilitaryOverviewItem)

**入口链**: GroupItem target(item+72) = **grp+8 refid** (SetTarget
sub_141E73010 直拷, 0xB70); FleetItem target = **CFleet +1584 idpair**; FleetRowItem
target = **CFleet +2696 idpair** (+2704 内嵌 FleetItem); MilitaryOverviewItem
target = **CTaskForce raw+40 idpair** (sub_1402A6F30=*(tf+24) 灌入, −16 胶水双互证)。
host 链 = 剧场视图 `*(country+352)` → CNavyTheater+16/+28 逐组建 GroupItem。

**CNavyTheaterNavyItemBase** (「海军」行抽象基, 主表 [15] 纯虚; 多基 CStandardlistboxItem + COption + 双 observable + TListboxItem@56 + CTooltipHandler@72): 子类 = CNavyTheaterFleetItem (1592B) / CNavyTheaterTaskForceItem — 上表舰队行即此基的具体化。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 剧场组行 | SetTarget sub_141E73010 | **CNavyTheaterGroup +32 fleet 容器 (tok 15156) / +56 name (tok 27, ⚠ 与陆军+40 异构) / +88 is_important / +8 refid** | **布局全闭合** (§4.24); 命令族 CSetNavyTheaterGroupFor/Important/Name | — | 定案 |
| 舰队行 | 纯虚 [15] Refresh | **fl+184 tf 容器 / fl+224 name / fl+256 icon / fl+272 color / fl+84 region 计数** | §4.16 命中 5; **fl+36 = CSelectable 基 (fl+24 子对象) 的 _bSelected** (CSelectable ctor sub_140BC2AA0: +8=id=11 / +12=_bSelected=0; dtor sub_140BC2B60 断言 `_bSelected==false` + 反注册 qword_14332F698+1336) | — | 定案 |
| 舰队行 (row 变体) | populate | **tf+1200 repair_parent → split_off 徽标 = 分桶分离舰数**; tf+852 舰数 | NAVY_THEATER_DETACHED 族; CSetFleetCommand 拖放重编链 (REASSIGN_ALL_TASKFORCES) | — | 定案 |
| 军事总览行 | sub_1402AA280→raw 消费 | **tf+840 ship 容器 / tf+472 owner / country+592/596 pride / ship+1832 宿主 / ship+232 舰体名**; **tf+832 leader 指针 / tf+884 mission type (==8=reserve, 定案) / tf+496 当前 region / tf+436 战斗中谓词** | §4.16 命中 5 + 新发现 4 | — | 定案 |

> 子件与 loc 补名（重锚实测）：**ARMY_NAVIES_BUTTON**（CNavyMilitaryOverviewItem @24[0] 0x141D36240 悬停 btn_bg）；**theater_name_box / fleets_row_box**（GroupItem populate 绑 item+2904/+2912）；**fleets_box**（SetupDerived [19] 0x141E73C00 第二查找 vtable+184（两版 .gui 双证））。

#### 4.31.6 散簇·NProject Project+特种 (CProjectListFilterWindow 族 / CProjectItem / FilterListItem/SimpleItem/HistoryItem / CProjectOutputRewardWindow / CSpecialFacilityMapIcon / CSpecialProjectCaptured/FinishedPopUpWindow)

**入口链**: FilterWindow\<T\> (8 槽抽象) populate 链 = **cc+4008→+24 =
CProjectPool → P+16 容器**; 实例化点 = CFacilitiesTabView ctor 0X141CAEA90
(§4.30.11 互证); ProjectItem 双 target = CRef\<CProgram\>@+32 + CProject\*@+40;
RewardWindow target = CRef\<CProject\> 16B @win+4304/4312; FacilityMapIcon
target = u32 省 id @+1424 (21 槽 CMapIcon 派生, 与陆战图标同构)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 项目条目九窗件 | populate | **CProject+28 tag / +32 模板 / +40 状态机 / +444 突破门**; template+472 名结构 / +576 图标键 / +1072 map (突破成本页签) | 进度/时间/速度/科学家/突破成本 | PROGRAM_VIEW_RESEARCH_TIME / PROGRAM_VIEW_REQUIRE_SCIENTIST | 定案 |
| 项目过滤窗 | [5..7] 纯虚 roster 实现 | **cc+4008→+24 CProjectPool → P+16 容器**; 过滤维度 = 专精 (**CSpecializationDatabase = qword_14332F068**) | 8 槽抽象, Simple/History 两实例 | — | 定案 |
| 奖励窗提交 | 确认 | 奖励源 = **template+856 容器**; **CPrototypeRewardOptionCommand {+48 option id/+52 reward id}** | 13 槽 CEmbeddedWindow 派生 | — | 定案 |
| 设施地图图标 | 活查 | 省+480 设施数组 → 实例+480 def (**def+528 名 / +676 存活 / +740 帧 / +1200 建筑链接**) | 点击开设施页签 | — | 定案 |
| 项目完成/被夺弹窗 | 多参 target | CProject\*@+1456 / 原属国 tag@+1480 / 设施 def\*@+1472/+1488; 弹出门 = **project+28==玩家 && 状态机终态 (sm+8/sm+16/sm+232)** | CAutomaticPause@1440 | SPECIAL_PROJECT_COMPLETED_POPUP_TITLE / view_special_project_history | 定案 |


#### 4.31.7 散簇·省建筑/占领条目 (CProvinceBuildingItem / CustomIconItem / StrategicLocationEntry / COccupiedTerritoryCountryEntry / StateEntry / StateEntryWithoutResistance)

**入口链**: BuildingItem target = 基 CBuildingItemBase +32=view / **+40=建筑 def**
(双 status 规则: def+700≤0→州+288, >0→省+400); StrategicLocationEntry target =
+32 CProvince\* + +40 location token; WithoutResistance target = **+1320 CState\***
(tooltip = ret0 桩 = 有意无 tooltip)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 省建筑行 | Setup A800 | **def+700 省级等级上限 / def+740 图标帧**; status/level+64/healthy_levels+66/def+736 | §4.14 命中 4 + def 新锚 | CAPACITY{level,max} / BUILDING_DAMAGED{DAMAGED,CURRENT} / 满级特殊字形 | 定案 |
| 自定义图标行 | 点击 lambda | **def+676 设施旗 / def+808 自定义图标 GFX / def+824 门槛** → sub_14174AB30 开设施 program 窗 (countrystateview.cpp:0x658 断言) | 行自有 +1416 scale/+1424 damage_bar | — | 定案 |
| 战略位置条目 | Setup 8D70 | +32 CProvince\* / +40 location token; **CState+2048 第二 u32 = prov_id 定案 (tooltip 双名 getter 再证)** | GFX_strategic_location_\<lexer名\> 拼名 | — | 定案 |
| 占领国行 | Setup (复证 +7800) | **6 glue 钮全定名**: 钉选/政策弹窗/驻军弹窗/Release nation = **CReleaseCountryDialog** / Return territory / +6512 地图定位; **occdata+32 = CState\* 向量 (非 SSO)**; tooltip 9 族 loc 普查 | E3C0 无抵抗行分支 | occupied_territory_country_entry | 定案 |
| 占领州行 | Setup (复证 +3904) | +3968 法加成图标 / +3976 驻军模板钮 / **+3952 = 驻军模板旗标 / 表3 记录+24 = CDivisionTemplate\* / +3992 = 表2 进度值**; **CState+8 = 内嵌 CSelectable** (断言) | 行订正见 §4.30.14 | occupied_territory_state_entry | 定案 |
| 无抵抗州行 | Setup CFB0 | **+1320 CState\***; 创建点 = E3C0 分支 (被占领国 owned × 玩家控制 × cr+80≠被占领 tag); 点击 = gui vtable+464 + 地图选中 | tooltip = ret0 桩 (有意无 tooltip) | OCCUPATION_STATE_OCCUPATION_INFO(_NO_RESISTANCE) | 定案 |

#### 4.31.8 散簇·政党理念/民族精神 (CPoliticalIdeasWindow / IdeaItem / PartyInfoItem / SelectableIdeaItem / CSpiritItemWindow / CSpiritView / CSpiritViewEntry)

**入口链**: IdeasWindow target = win+16 CIdeaGroupType\* + win+1384 现 CIdea\* +
win+1392 候选向量 (**= ps ideas + ps+56 拼接**); 宿主 CCountryPoliticsView+31296;
SetTarget = sub_141582ED0 (非虚, politicalideaswindow.cpp assert 直证)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 理念窗候选/现装 | sub_141582ED0 | **ps+80 ideas {d,c@+92} + ps+56 拼接** (§4.10 ✓) — 定案 : 两容器同为 CIdea\* (ps+56 缓存 2088 条 + ps+80 现装 9 条, token 名全读出); 「拼接」= GUI 消费端组合非冲突 | 三窗共享 target (SpiritItemWindow 继承) | — | 定案 |
| 理念条目 | populate | item+32 组 def / item+40 现 CIdea\* (politicalitems.cpp 直证) | ps+56 辉光扫描; CIdea 名 = token@+8 | — | 定案 |
| 政党信息条目 | populate | item+32 CPoliticalParty\*; **parties {d+32,c+44} / party+136 popularity / +24 组 / +40 name / +104 default_flag / ps+208 ruling_party / 党色 sub_1411A4780+16** | §4.10 命中 6; tooltip 尾直链 sub_140BAAA20 互证 | — | 定案 |
| 可选理念条目 | populate | item+48 CIdea\* / item+32 tag; **ps+128[*(组+92)-1] 费用链** (= 书内 sub_140BA92B0) | CIdea+2720/+664/+2752/+2816 系 (新发现) | REPLACE_IDEA 确认弹窗 — **确认后 ps 写点定案 = sub_140BAF050(ps, 旧def, 新def, −1)** (CReplaceIdeaCommand vtable 0x1429958A0 Execute[10] sub_141159B70 调用; 内部直改 ps+80 现装表 / ps+56 缓存 / ps+128 费用表; ps = `*(cc+3984)` CPolitics) | 定案 |
| 精神窗 | 继承 + 四军种底图 | **CIdeaGroupType+96 → CIdeaCategory+120 门类 id 链** (2=army/3=navy) | country_army_spirit_view.cpp 直证 | — | 定案 |
| 精神视图/条目 | SetupDerived sub_141D21330 | 非多态 (+8 窗/+16 grid/+32 条目向量); **CIdeaCategory+8/+16/+48/+120** (新族); entry+1408 现 CIdea\* / +1416 组 / +1424 门类名 | 门类 id = FNV 名哈希查表; 空槽发 SPIRIT_ADD_IDEA | SPIRIT_ADD_IDEA | 定案 / 新族 |


#### 4.31.9 散簇·机种选择 (CPlaneTypeSelectionWindow / SelectionEntry / CountEntryItem / ArchetypeHeaderItem / CPlaneItem / CPlaneInfoEntry)

**入口链三宿主**: CAirbaseQuickDeployWidget lambda → 控制器 →
CPlaneTypeSelectionWindow ("quick_wing_deployment_selection_window", ctor a3
控制器@+1440 + SetAirbase@+1448); **CPlanesOverview** ("planeswindow") →
ArchetypeHeaderItem; **CCountryMilitaryOverview vtable[9]** (PE 反查定案) →
PlaneInfoEntry。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 快部署选择窗 | [1]Update/[11]OnOpen/[12]OnClose | 条目 def+24/+960 图标; **dword_143333C2C = NAir::MAX_QUICK_WING_SELECTION** (离线 defines 映射缺行) | selection_count=N/上限 | quick_wing_deployment_selection_window | 定案 |
| 选择条目 | 双 glue lambda + 每帧 Update | **CQuickWingDeployOption 32B**(+80){+0 ctrl, +8 def, +28 选中字节}; def+1448 掩码/池÷1e5 (§4.23 ✓); def+784 变体容器 | 批量修饰键 1/5/10 | quick_wing_deploy_plane_type_entry_item | 定案 |
| 账本机种计数行 | 账本 populate 直写 | +32 = archetype→类别 (**经 def+1240 链取 def+320 类别枚举**) / +36 国 tag / +60/+64 估值区间 / +56 精度旗 | gs+1312/1316 账本存储区间查询 | TARGET_HAS_CATEGORY_\<n\> / NO_INTEL / intel_ledger_plane_count_detail | 定案 |
| 机种头行 | ctor a3 16B {archetype, current, total}@+1320/1328/1332 | **def+1000 舰载机字节显隐门**; +1336 折叠宿主回指 | 宿主 CPlanesOverview | EQUIPMENT_FILL / EQUIPMENT_VARIANTS_TOGGLE_ON/OFF / plane_archetype_header_entry | 定案 |
| 机条目 (0x30 最小) | 直写 | +32=variant / +40=amount; **归组谓词 *(variant+1008)+1240==头行 archetype** (+1008/+1240/+1032/+1448 四命中 §4.23) | 宿主聚合管线 | ARMY_AIR_VARIANT_AIRWING_ITEM / equipment_plane_entry | 定案 |
| 空军节条目 | populate 写 count@+40 | ctor a3 archetype@+32; def+320 类别 | 宿主 CCountryMilitaryOverview vtable[9] | AIR_OVERVIEW_CATEGORY_\<n\> + REGULAR/CARRIER / air_view_plane_entry | 定案 |

#### 4.31.10 散簇·驻军/政策/附庸 (CGarrisonDeployItem / CGarrisonLogView / CPolicyWindow / CPolicyItem / CSubjectRelationstripView / CSubjectViewItem)

**入口链**: 驻军二类 target = 玩家 occmgr 自见 (无 SetTarget 存储); PolicyWindow
= **非独立窗内嵌 COrganisationDetailWindow+8464** (政策管理器对象 {+368 可用 id
列表, +392 当前挂载 id}); SubjectStrip target = +56 附属国 tag。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 驻军部署条目 | populate (父级 CCountryDeploymentView [14]) | cc+4048 occmgr; **occmgr+8 = 驻军优先级** (CSetCountryGarrisonPriorityCommand 双向闭环); occdata 表2 记录 +104/+136/+144/+208 四槽 | CDeployBaseItem 7 纯虚槽骨架 (7 子类族) | — | 定案 |
| 驻军日志视图 | populate | occdata+16/+56/+144; **occmgr+256 = 驻军活动日志容器** (元素 +8 tag/+32 时限/+56 人力/+88 装备) | 三行类 (CStripFlagGarrisonItem/CResistanceActivityItem/NCombatLogView::CEqLossItem); CArmyManpowerValues 累积器 | — | 定案 |
| MIO 政策窗/条目 | Setup | **管理器经 \*(mio+48)+132 ref 解析**; item+120 政策 def id / +124 库 ref; 19479=undefined 卸下哨兵 | **CAttachPolicyToIndustrialOrgCommand {+40 tag/+44 id/+48 ref}**; **def 库 qword_14332EF40 = TGameItemDatabase\<CPolicyDatabase\>** (条目类 = NIndustrialOrganisation::CPolicy, RTTI 在册, 布局未深作) | — | 定案 |
| 附庸关系条 | target 链 | +56 附属国 tag → dip+8 → **rs+648=puppet(12497) 槽** / rs+80 / dip+848 autonomy+40 current_state | CRelationStripViewBase 4 抽象槽骨架 (13 子类家族 + token 工厂 sub_1415EAE80) | AUTONOMY_RELATION_DESC/DESC2 + GFX_\<level\>_icon | 定案 |
| 附庸条目 | Setup (0x28 极薄行) | +32 附属国 tag; **dip+368 = 附属国 tag 集** — 扁平 u32 数组 {data@+368, count@+380} 非 RH | 内嵌 CAutonomyProgressView — **读 dip+392 = overlord tag 标量** (sub_141C4CC10 SetTarget 体: `*(u32*)(dip+392)` 作 tag 取名 + loc `SUBJECT_OF_NAME {VALUE}`); +368 与 +392 是两个不同字段 | — | 定案 |


> loc 键补名（重锚实测 1.19.3 存活）：**COMBAT_LOG_EMPTY_EQ / COMBAT_LOG_PERIOD_DESC**（填充 sub_1417AA7B0 + combat log sub_1416F49A0）；**GARRISON_LOG_EMPTY_ACTIVITY / COMBAT_LOG_LOSSES_IN_MP / GARRISON_LOG_LOSSES_IN_IC**（sub_1417ABBA0 / sub_1417AA7B0 消费）。

#### 4.31.11 散簇·翼选/Ace (CGunEmplacementMapIcon / CRocketSiteMapIcon / GunEmplacementWingsSelectionItem / CRocketWingsSelectionItem / CAttachedRailwayGunTypeItem / CAttachedWingsTypeItem / CAcesView / CAcesViewEntry)

**入口链**: 炮/火箭图标 target = 省 id u32@+1424 (省图标同步器 sub_141292300);
翼选条目 target = CAirWing\*@+7008 (炮) / @+9856 (火箭); AcesViewEntry target =
**双 idpair: +40=ace (ace+8 直拷) / +48=上下文翼 (SetAce sub_142033D60)**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 炮位图标 | resolve | mgr+192 gun_emplacement 容器 = **per-state 稀疏索引**; emplacement+48/+72/+104 容器形态 | 命中 prov+192/392/state+88/gs+1680/SA+136 链 | — | 定案 |
| 火箭场图标 | resolve 尾调 sub_140C4B040 | mgr+168 火箭容器 (同 per-state 索引); **+1448 内嵌 CAirWingMapStack 48B** (vtable[15] 独占槽); site+120 等级/site+104 州 | ROCKET_SITE_LEVEL/CAPACITY + 翼状态 loc ×4 | — | 定案 |
| 翼选条目 (炮/火箭) | set-wing sub_141FD5410 | CAirWing\*@+7008/+9856; 消费 wing+12 _bSelected 与 wing+144=书+128 mission 内联 | priorities 控制器 @+7000/@+9848; 7 钮+8 窗全名 (select_missile_button/nuclear_button/reinforce_preference 火箭特有) | strategic_gun_emplacement_priorities_window | 定案 |
| 挂载类型条目 ×2 | 基+1344 宿主接口 + +1352 槽索引 | **上下文+32 RailwayGuns 容器 / +112/+124 attached wings 容器** (按槽掩码 ∧ def+1448 类别掩码过滤) | **宿主视图定案 = CLeaderGroupView** (vtable 0x142A02258; populate sub_1417C1CF0 直建 4×CAttachedRailwayGunTypeItem (ctor sub_141DF1DE0) + 2×CAttachedWingsTypeItem (ctor sub_141DF1B00), 均 0x550, 入 view+14848..+14888; +14840 = "attached_units" 元素); 传给项 ctor 的上下文 = **view+8 内嵌子对象** (非 CArmy 本体); [25]=槽≠3 恒隐第 4 槽 | — | 定案 |
| Ace 条目 | SetAce sub_142033D60 | **CAirAce 首批字段: +8 idpair/+24 熟悉机型掩码/+48 修正块/+232 指派翼 idpair/+344 KIA/+1384 熟悉机型容器** | §4.3 已立行; 7 行窗+eligible_planetypes_N 容器 | ACE_PILOT_CANT_ASSIGN_KIA/UNFAMILIAR/ELIGIBLE_TYPES / ACE_UNASSIGNED | 定案 |

**图标工厂与池域（重锚后零漂移）**：map icon 总工厂 = 0x140B71B50（case 5/6/7/13 → malloc 1520/1496/1448/2472 全同）；三池获取包装 = 0x140B72C30/0x140B73190/0x140B72DB0（type 5/6/7）；池全局 = **qword_14333C5A8**；释放 = 0x140B3BF80；同步器 = 0x141292300（底座共享）。

工厂 18 case 全表 (ctor 与 sizeof 经 ctor 内 `&类名::vftable'` 直证; case 18 为非 icon 私有分支):

| case | ctor | sizeof | 类 |
|---:|---|---:|---|
| 0 | sub_141912C40 | 208 | CUnitsStackMapIcon |
| 1 | sub_141912D30 | 208 | **CUnitsStackMapIconGroup** (三级基链 CMapIcon→CUnitsStackMapIcon→Group 末写 vftable 直证; 与 case 0 同尺寸同行件名, 单体/成组两件型) |
| 2 | sub_1418BA0D0 | 192 | CVictoryPointMapIcon |
| 3 | sub_1418B9A40 | 224 | CResourceMapIcon |
| 4 | sub_1418B8970 | 1600 | CConstructionInfoMapIcon |
| 5 | sub_1418B8310 | 1520 | CAirBaseMapIcon |
| 6 | sub_1418B9CB0 | 1496 | CRocketSiteMapIcon |
| 7 | sub_1418B9080 | 1448 | CGunEmplacementMapIcon |
| 8 | sub_1418ED6C0 | 1472 | CNavalBaseMapIcon |
| 9 | sub_1418F4410 | 1568 | CNavalCombatMapIcon |
| 10 | sub_1418B94B0 | 1464 | CNavalCombatResultsMapIcon |
| 11 | sub_1418B9240 | 1528 | CLandCombatMapIcon |
| 12 | sub_1418F9C60 | 5656 | CMissionMapIcon |
| 13 | sub_1418B8510 | 2472 | CMissionMapIcon |
| 14 | sub_1418B8880 | 216 | CCapitalMapIcon |
| 15 | sub_141904CC0 | 296 | CPeaceMapIcon |
| 16 | sub_1418B8150 | 1448 | CAdjacencyRuleIcon |
| 17 | sub_1418B9800 | 152 | CRadarMapIcon |

**holder 槽/旗统形**：+5800/+4492、+5808/+4493、+5816/+4494；**icon+1485/1509 = 内嵌 CAirWingMapStack(+1448)/空军基地对象(+1472) +37 ← holder+4488 字节透传**（同律）；CAirWingMapStack ctor 0x141E7C9B0。翼选项 ctor = 0x141FD4160(7016)/0x141FD5F30(9872)；set-wing 0x141FD5410(+7008)/0x141FD88E0(+9856)；+8400/+9840/+9848/+6976 全同（+6976 实为炮位翼选项 "equipment_icon"）；5×/7× 按钮槽步长 1368、CButtonWrapper ctor 0x140B77E10 (wrapper 布局与注册链全表见 §4.31.95)。**⚠ wings_box 字面**：1.19.3 dump 内为 QWORD 立即数 0x6F625F73676E6977（"wings_bo" 前缀截断内联），非引号串——喂入函数 0x141E7E820。Ace 簇：CAcesView ctor 0x1420324E0 / Open 0x142033270；entry ctor 0x142031A40 / SetAce 0x142033D60（双 idpair，哨兵 qword_14333D528）。挂载项三 ctor = 0x141DF1B00/0x141DF1DE0/基 0x141DF2090（+1344/+1352 同）；**铁路炮挂接项 tooltip 构造器 = 0x141DF23D0** (leadergroupsview_attachmentitems.cpp:315; `(item+24, ?, tooltip_struct* a3) → char`): 项基 = a1−24; roster = `*(item+1344)` 经其 vtable 取; 项类型 = 项 vtable **槽[25] (+200)** — 0 → 未指派 (tooltip RAILWAY_GUN_CLICK_TO_ASSIGN) / 1 → 已指派 (标题 RAILWAY_GUNS_ASSIGNED → a3+0 串 + '\n' + RAILWAY_GUNS_UNASSIGN → a3+32 串 + 逐铁路炮 '\n' + 槽 **[13] (+104)** GetDesc) / 其他 → assert "Unsupported item type" (:315)。铁路炮表 = roster+32 {data@+32, count@+44} (8B 指针元, 元素类 = CRailwayGun 推定); a3 = 64B 双 std::string 结构 {串@+0 (size@+16/cap@+24), 串@+32}, '\n' 手工追加于 size 位 (MSVC SSO 形态自证)。LeaderGroupsView populate = 0x1417C1CF0（host+14840 attached_units、4+2 槽、0x550/项、+14972 门全同）。CAirWingDetailsPopUpWindow Refresh 0x142037B40 / 装备行 ctor 0x142034F80 / setter 0x142037220(+40)。任务钮：CAirMissionButton 0x141CECD40；目标钮创建于 0x141CEEBF0（+2648 槽，bit3\|bit16 ∧ sub_1401AEB50(9/14/19/26/36)）；任务图标创建器 0x14167F4A0。

#### 4.31.12 散簇·国策延伸 (CNationalFocusDetailView / TreeItem / ExclusiveItem / LinkItem / FilterItem / FilterShowRestItem / ShortcutItem)

**入口链**: DetailView target = **CNationalFocus def\* @+3920** (池 win+8352 去重);
TreeItem target = def @item+32 (**池A win+8280, size 0x550**);
ExclusiveItem target = defA+32/defB+40 互斥对 (池B win+8328, size 0x60);
FilterItem target = **96B 过滤器描述符** {+40 名/+72 显示名/+104 DB 索引/+112 命中表};
ShortcutItem target = **tree+128 快捷描述符条** @item+40 {+80 def/+88 谓词/+176 fixed/+184 enable}。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 详情视图 | [8]=IsOpenAndVisible | **def vtable+88/96/104 谓词 / def+1469 取消旗**; fp+16/+56/+88 RH (§4.3.12 ✓); 窗+165 bit3=visible | **start/bypass/cancel 三命令 RTTI 定案** | — | 定案 |
| 树条目 | OnClick=开详情 / OnMouseEnter=shine | def @item+32; **def+1464/1468/1470 旗簇 / def+888/1404**; cc+3976→+736 投降旗; fp+32 shine 二分/+88 RH/+152 originator/情报门族/def vtable+112/win+8424 | **状态码 0-3 全链** | — | 定案 |
| 互斥条目 | populate | defA+32/defB+40; **+48 状态机四码定案 (属本条目, 非池B)** | 五窗 link1/link2/left/right/mid | — | 定案 |
| 连线节 | (纯视觉) | +32 方向码/+36 样式; **win+8304 = LinkItem 池** | GFX_focus_link_up/down 贴图族 | — | 定案 |
| 过滤器条目 | populate | **def+1504 filter 名表** (构建+匹配双证); CNationalFocusDatabase+176 名映射; 替代树 tree+256/+272 + win+2952 单件 | 搜索匹配行/游标见 §4.30.11 (+8728/+8824) | — | 定案 |
| 显隐/快捷条目 | OnClick | ShowRest: sub_14138B470 切 win+1504 (窗+165 bit4=hidden); Shortcut: tree+128 条 {+80 def/+88 谓词/+176 fixed/+184 enable} → 跳转 sub_14138B680 | — | — | 定案 |

**框架副产品**: CLegacyButtonObserverGlue 槽数组 = glue+8 起 64B×20, **callable
指针在槽内+56** (§4.00.5 已补); 窗 vtable[15]/vtable[16]=Show/Hide 极性; **fp+8 = 宿主
CCountry\*** (CFocusStatus 新首字段, §4.3.12)。



**国策类vtable与关键函数**（1.19.3 直读，基链零漂移）：

| 类 | 主 vtable（1.19.3） | ctor | 关键槽/体 |
|---|---|---|---|
| CNationalFocusDetailView | 0x142A4C640（10，@24 0x142A4C698） | sub_141BC5710（+3896 owner / +3904 NFView / +3920 def / +3928 SSO 副本） | Setup sub_141BCA050；BuildTooltip sub_141BC81F0（元素名分派，FOCUS_CANCEL 直消费） |
| CNationalFocusTreeItem | 0x1429B4C40（19，@24 0x1429B4CE0） | sub_14137F620（+32 def / +1328 NFView / +1344=4 / +1336 symbol / +1356=257 → gates；0x550 分配） | OnClick sub_14138B100（debug/复制 id/开详情 sub_14138E400 三支）；OnMouseEnter sub_14138AA40；BuildTooltip sub_141388390（loc 键主消费）；状态应用 sub_14138C950 |
| CNationalFocusExclusiveItem | 0x1429B4AB8 | sub_14137E2F0 | tooltip sub_141387AB0（NATIONAL_FOCUS_MUTUALLY_EXCLUSIVE_TREE） |
| CNationalFocusFilterItem | 0x1429B4708 | — | 应用重算 sub_14138ACF0（两处）+ sub_14138F440 |
| CNationalFocusFilterShowRestItem | 0x1429B49F0 | — | 无 tooltip 基 |
| CNationalFocusLinkItem | 0x1429B4EB0 | sub_14137F020（+32 方向码 / +36 u8 样式 / +24 link 子窗） | 连线段构建 sub_141382790（GFX_focus_link%s%s%s%s） |
| CNationalFocusShortcutItem | 0x1429B48A0（@24 0x1429B4940） | — | — |

**loc 键组**：

| 键 | 主引用函数 | 消费窗 |
|---|---|---|
| FOCUS_STATUS_TOOLTIP | sub_141388390（TreeItem BuildTooltip） | national_focus_item tooltip 容器 |
| FOCUS_FILTERED | sub_14138ACF0（过滤器重算 ×2）+ sub_14138F440（搜索支路 ×2） | national_focus_view 匹配计数/高亮文本 |
| FOCUS_STATUS_INPROGRESS_TOOLTIP | sub_141388390 + sub_1415E9440（连续国策视图） | national_focus_item / continuous_focus 族 |
| FOCUS_REWARD_TOOLTIP | **五引用点全正名**: ① sub_141388390 = CNationalFocusTreeItem BuildTooltip / ② **sub_141BC2710 = CContinuousFocusItem tooltip 槽** (vtable 0x142A4C320 slot[0]) / ③ **sub_1415E9440 = CDiplomacyCountryInfoController 主 vtable[0]** (vtable 0x1429E0798) / ④ **sub_140EDB120 = 科技研究 tooltip 组装器** (调用者 CResearchSlotItem / CTechnologyTreeTechItem) / ⑤ **sub_140A222D0 = 派系目标 tooltip 组装器** (调用者 NFactions::CGoalItem / CChangeGoalItem) | 该键为**通用「奖励段」标题键**, 被 国策/持续国策/外交国信息/科技/派系目标 五族复用 — 定案 |
| FOCUS_STATUS_COMPLETED_TOOLTIP | sub_141388390 | national_focus_item tooltip |
| FOCUS_STATUS_INPROGRESS_NO_INTEL_TOOLTIP | sub_141388390 | national_focus_item tooltip |
| FOCUS_CANCEL | sub_141388390；sub_141BC81F0（DetailView）；sub_141BCB490；sub_14157F870；sub_14157EAA0 | national_focus_item / detail_view / continuous 族 |
| CLICK_DETAILS | sub_141388390；sub_141BC2710；sub_141BD1840（×2） | item/detail tooltip 尾行 |

> 情报门双检：sub_141433D90（def 项 +1356 分支）/ sub_141434250（+1357）；阈值 = qword_143337D10 / qword_143337E90；作弊直通 byte_14332F63A。DetailView start 按钮文本 = sub_141BCBF10（START_FOCUS/BYPASS_FOCUS/CANCEL_FOCUS 三键 + 状态机 sub_141BC77F0）；close/start glue cb = sub_141BC77B0 / sub_141BC9750；状态行 populate = sub_141BCAB60（fp+56 progress + FOCUS_STATUS_IN_PROGRESS/CURR/TOT）。详情开启 = sub_14138E400（池 win+8352{c@8364} 去重，new(0xF78)，ctor 调 sub_141BC5710(this, owner=\*(win+1392), mgr qword_14332F698 vtable+184, win, def)）。

**NRaids 视图族**（raid 视图；1.19.3 全部存在，布局零漂移）：

| 类 | 主 vtable（1.19.3） | 形态/要点 |
|---|---|---|
| NRaids::NUi::CRaidGuiManager | 0x1429A79F8（10；mi: CInGameUpdateableInterface@0 + CSelectionListObserver@24） | ctor sub_1412983A0：+72 step=0 / +80 target=0 / +288 反馈数组 / +312 内嵌 CRaidSetupView（sub_141B30400）/ +4648 内嵌 CRaidFilter（sub_141B29310） |
| NRaids::NUi::CRaidSetupView | 0x142A40DE0（4；tooltip@40 virtual + CInGameUpdateableInterface@48 virtual） | ctor sub_141B30400：信号持有 1368B×3 @+192/+1560/+2928；单位 vector {buf@+88, cap@+96, count@+100} + 分配器+104；source vector +112..+124 + 分配器+128 |
| NRaids::NUi::CRaidFeedbackView | 0x142A41BF8（4；tooltip@64 + CInGameUpdateable@40，虚基索引对换） | populate = **sub_141B35B80**（this=view+40；26 widget 偏移 + raid+56/+60/+200 三锚全同） |
| NRaids::NUi::CRaidFilterCategoryItem | 0x142A41F38（19 零覆写） | tooltip 子表 0x142A41FD8 |
| NRaids::NUi::CRaidTypeIconItem | 0x142A41FF0（19 零覆写） | tooltip 子表 0x142A42090 |
| NRaids::NUi::CRaidUnitItem / CRaidSourceItem | 0x142A420A8 / 0x142A421F8（族外） | ctor sub_141B37040 / sub_141B36A40 |
| NRaids::NNet::CCreateRaidCommand | 0x142A41010（24 槽 CCommandHelper 基族） | ctor = **sub_141B319B0**；12 载荷偏移一致 |
| NRaids::NNet::CRemoveRaidCommand | 0x142A41970（24 槽 CRaidInstanceCommand\<T\> 基） | — |

#### 4.31.13 散簇·账本行族 (CLedgerAirwingEntry/AirwingHeaderEntry/ArmyTemplateEntry/StockpileEntry/ShipEntry/ShipHeaderEntry/ShipTypeEntry)

**入口链**: 7 类全为 CStandardGridBoxItem 19 槽+CTooltipHandler@24 骨架, 主表无
覆写, 个性全在 @24[0] BuildTooltip + 非虚 Setup; **计数全走 sub_14142EB50
模糊化引擎**; **cat = 型类 idx + 域基址常量 {1174/1186/1261/1293}**; army 模板与
库存存在 intel 双轨 (≥阈显真/<阈显假镜像)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 联队行 | Setup | {tag@+32, CEquipmentVariant\*@+64, 机数@+72}; gs+1680/SA+88 池/pool+40 wings/holder+16/wing+108/456/variant+1008 | §4.15 命中 7; CEquipmentType+320 继承式型类 idx (cat 基址 1293) | — | 定案 |
| 联队头行 | Setup | {tag@+32, 根 archetype CEquipmentType\*@+40, 机数和@+48}; type+1240 父链/+24 名键 | type+1336 账本型类 idx | — | 定案 |
| 师模板行 | Setup | {模板 idpair@+32, tag@+40, 师数@+44}; cc+656/div+952 真模板/div+968 fake_intel/d+468/d+476/cc+440+452 | §4.18 命中 6; d+540 明细门旗 (新) | — | 定案 |
| 库存行 | Setup | {tag@+32, archetype\*@+48, 库存量@+56, **国际市场量@+64**} (loc 直证); ps+544 真池/cc+4024 market/+1344 域掩码; **ps+520 假镜像池 / \*market+64/+88 假真市场容器 / ps+184 variant 列表** | intel 双轨实证; §4.8 池元拆分 (定案): CEquipmentVariantPool = 双数组 A{data@+8, **24B 元** ctor 扩容直证} + B{data@+32, **16B 元** 序列化 writer 0x141012DB0 键 12122（⚠ 旧址 sub_141A00AF0 = CCreateEquipmentVariantScheduler writer）} — 序列化池 16B 维持; 「ps+544 且 24B」两说留运行时复核 | "International Market Amount" | 定案 (拆分) |
| 舰行 ×3 | Setup | {tag@+32, 舰船变体/X=ship+128 内嵌舰体块@+40..+64, 舰数@+48..+72}; cc+632+644/tf+840/ship+64/ship+136 definition/ship+232 舰体名; **ship+152 舰型名键 / ship+1548 账本舰型 idx** | §4.16 命中 6 | — | 定案 |

define 新实名 15 个 (离线 defines 映射直证), loc 12 键全中 (intel_ledger_l_english.yml)。


#### 4.31.14 散簇·行动总览 (COperationOverviewWindow / COperationViewEntry / OverviewOperativeEntry / PhasesViewEntry / PhaseTitlesViewEntry / ResourcesViewEntry / ResourcesEntryCivilian / CollectionItem / MapIconEntry)

**入口链**: OverviewWindow target = idpair 存储@win+5940 + spec 缓存块
(win+5856..5935) 双入口变奏 (setter 0X14182CCD0 既有 / opener 0X14182C990 新筹备);
**AgencyView+1416 子视图 B = 本窗 (定案, §4.11)**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 行动行 | 主填充 sub_141A1B7C0 | 行+2736 COperation\* / 行+2744 instance idpair; **行+2728 = 目标国 tag 非序号 (三证)** | **COperationInstance 行级 14 字段定案** (+64 auto_commence/+65 auto_repeat/+66 completed/+72 def/+80 owner cc/+88 目标 tag/+96 目标对象/+112 开工 hours/+128 工期 days/+160 完成文本/+192/193 双旗/+224 特工快照表/+248 名/+336 资源区 (§4.11)); COperation def +376/+472/+1168/+8 四消费点 | — | 定案 |
| 阶段条目 ×2 | [18] 当前阶段高亮 | COperationPhase\*@+64/+48; **phase+144 名/+176 icon / +240 标题/+368 icon** | instance@+56 | — | 定案 |
| 资源条目 | Setup | 32B 资源元拷贝@+80 + def@+64 + instance@+72; §4.11.12 32B 元/op+344 容器/op+48 三命中 | **COperationResourcesEntryCivilian = 非 GUI 类 (parse/serialize 适配器; writer 0X140A7B070/parser 0X140A7AB40/token 19421)** | civilian_factories | 定案 — **宿主定案 = COperationResources** (vtable 0x14271AB70, writer 0x140A7B070 / reader 0x140A7AB40, 该函数对即其 [2]/[4]; 本类 = 32B 元素适配器) |
| 特工条目 | Setup | instance ref@+40 + leader ref + EOperativeResumeMission; §4.11 56B 快照容器 inst+224 命中 | 56B 小条目无 tooltip | — | 定案 |
| 地图图标 | 双 target | instance ref@+80 (运行) ∨ def@+88+tag@+96 (可筹备); **def+1200 地图 icon SSO / inst+96→+192 地图位置** | 点击双路开总览窗 | — | 定案 |
| 集合头 | (无游戏对象) | CCountryDeploymentView vtable[14] "OPERATIONS" 静态集合头 (CDeployBaseItem 26 槽, [22..24] 纯文本 getter) | — | — | 定案 (形态) |

**COperationOverviewWindow 窗侧骨架**（重锚后零漂移确认；命令侧已收 §4.33）：主 vtable 0x142A09180 + @40 BuildTooltip 0x14182B730 + @48[5] 0x14182D2F0（门 = this+5880 即 win+5928 spec 有效）/[7] 0x14182D4B0/[9] Repopulate 0x141830510；[2] Reload 0x14182EB60；六回调与 glue 区 = close@+96（→CDeleteOperationCommand）/ collect@+1384（→CCreateOperationCommand，ctor 0x141A24D50，实参 {def token, 玩家 tag, win+5856 目标}）/ start@+2672（0x38B）/ refund@+3960（→COperationRefundDialog 0x141E342A0）/ cb_auto_commence@+5248（win+5480，→CSetOperationAutoCommenceCommand）/ cb_auto_repeat@+5360（win+5488，→CSetOperationAutoRepeatCommand）；四格 win+5624 operatives_grid / +5632 phases_grid / +5640 phase_titles_grid / +5648 resources_grid（Repopulate 四段循环逐元 vtable[18](+144) 自刷，格内 {items@+416, count@+428}）；四池 CEmptyEntryListBase @+5656/+5696/+5736/+5776；leader 子窗 win+5816（惰建 scoped-ptr，ctor 0x141ABDE70）；btn_location win+5512 + 选择器 win+5952 = CMapModeOperationSelectTarget（vtable 0x142A09218；if(win+5936) sub_141E340A0）；12B 元向量池 {d@+5824, cap@+5832, count@+5836, glue@+5840}（×1.5 增长，元 {leader idpair@0, EOperativeResumeMission u32@+8}）；spec 缓存块 win+5856..5935（+5856 tag / +5864+5876 阶段 def 表 / +5888 内嵌 COperationResources / +5920 def / +5928 spec 有效 / +5936 已选择）；win+5940 idpair / +5948 未提交删除旗（ctor 0 → opener 不传 → btn_close 置位派 CDeleteOperationCommand → Reload 清）；哨兵 = qword_14333D528。Repopulate 状态机：inst = resolve(win+5940)；state = !inst?0 : inst+66?3 : inst+128?2 : 1；btn_start 文案 COMMENCE(state≤1)/OPERATION_VIEW_PROGRESS(2)、vtable+840(state==2)；进度 = 100×(today−inst+112 hours, −43800000 基, /24)/inst+128 灌 win+5608 vtable+176。

> 条目族主 vtable：OperativeEntry 0x142A817E8 / PhasesEntry 0x142A81918（[18] 覆写 0x141E30AF0）/ PhaseTitlesEntry 0x142A81AA8 / ResourcesEntry 0x142A81CC8（[18] 覆写 0x141E32A40）；桩基底 = 0x14012A2C0。COperationInstance vtable 0x1429BE5D0（[2] writer 0x141404B00 / [4] 0x141402770）；COperation def vtable 0x14293F2D8；COperationPhase def vtable 0x14271ABC0。

#### 4.31.15 散簇·市场/租借 (CPurchaseContractEntry / PurchaseDraftItem / PurchaseDraftWindow / PurchaseEquipmentItem / SubsidyDraftListItemView / SubsidyOverview / LendLeaseEquipmentItem / LendLeaseExportItem / PopupLendLeaseInfoItem / PopupLendLeaseRequestItem / CEditMarketStockpileWindow)

**入口链**: ContractEntry target = CPurchaseContract\* @item+64; DraftWindow
target = CCountry\* 买方 @win+1656 (= \*(status+104), status = CPurchasableEquipmentWindow+2624;
win+1440 起 216B contract_draft def 同构, 构造器 sub_140DF2320);
**EditMarketStockpileWindow**: 双槽 target = win+1448 CMarketStockpile\*
+ win+1440 卖方 tag, 数据 = SMarketEquipmentData @win+5624; ctor sub_142053160
(另 +1456 = \*(a2+1272) 模板厂 / 1368B 子对象×3 @+1464/+2832/+4200 / +5696 首刷旗)。

**CPurchaseDraftWindow 窗壳** (主 vtable 0x142AB4560 (14 槽) + 次表 0x142AB45D8 (4 槽); [11] OnOpen 0x142049000 / [12] OnClose 0x142045A50;
ctor sub_142044230; sizeof 0x1368)：

| 偏移 | 类型 | 名称/语义 | 置信 |
|---|---|---|---|
| +1656 | CCountry* | 买方国 (= ctor a2 = \*(status+104); CIC 账 getter sub_142046270 入口) | 定案 |
| +1664 | std::function | 回调对之一 (ctor a3 = SetupDerived lambda_1 移入; 与 +1720 成对) | 定案 |
| +1720 | std::function | 回调对之二 (ctor a3 = SetupDerived lambda_1 移入; 与 +1664 成对) | 定案 |
| +1728 | std::function | 双函数包之一 (ctor a4 = lambda_2, 克隆器 sub_1402A69E0) | 定案 |
| +1792 | std::function | 双函数包之二 (ctor a5 = lambda_3, 克隆器 sub_1402A69E0) | 定案 |
| +1896 | 1368B 子对象 | cancel_button (CButtonWrapper ctor sub_140B77E10 建, 宿主经 builder sub_1422DCB20 落回调; OnOpen 以临缓冲 v92[1368] 装配) | 定案 |
| +3264 | 1368B 子对象 | send_button (CButtonWrapper ctor sub_140B77E10 建, 宿主经 builder sub_1422DCB20 落回调; OnOpen 以临缓冲 v92[1368] 装配) | 定案 |
| +4712 | 子窗 | 补贴/CIC 草稿子窗 (OnOpen 建件; +156 = 可用 CIC = sub_142046270(a1) / +160 使能 / +152=1) | 定案 |
| CIC 账 getter | sub_142046270 | ps = \*(win+1656+3944); +888/1e5 − +912/1e5 − +1112 − +1088 − (+952+960) − sub_140E691A0(ps), 封顶 dword_143331AB8 | 定案 |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 合同条目 | [18]=Refresh | 合同+216/224/232/496/604/**+608 交付计数 (新)** / def+96/156/168 / cli+280/284 | §4.23.2 命中 10 | — | 定案 |
| 草稿窗/条目 | populate | **SMarketEquipmentData 72B** (+0 CEquipmentVariant* 原型 — 变体显示名 getter sub_140BDA540 (s4_11 同函) → EQUIPMENT 变量/+16 amount = fixed×1e-5 上架量 (显示取整 sub_1424ED730)/+24 生产库存断言定名/+40 cic_cost/+48 price_level/+56 convoy_cost); **CMarketEquipmentItem 25 槽基族**; status+104=CCountry\*; ps+888..1112 CIC 账六项; dword_143331AB8 封顶 | CSubsidyDraftPayload 32B @view+208; 补贴 48B 条 §4.23.2 ✓ | — | 定案 |
| 库存编辑窗 | Setup | **stockpile+104 = CCountry\* 属主**; **COverrideMarketEquipmentPriceLevelsCommand (id 14010)** + EPriceLevel 枚举实名 | EPool@+56/13859 命令载荷复证  | — | 定案 |
| 租借装备条目 | SetTarget sub_141F2C590 (零虚覆写) | CEquipmentVariant\* @item+1368; variant+1032 bit0/ps+512/cc+4608/ps+3944/type+1000 | §4.23/§4.8 命中 5 | — | 定案 |
| 租借出口条目 | Setup | **CLendLeaseExchange refid 快照 @item+32**; **rs+1880{+1892} = Exchange\* 数组; Exchange 布局 = CConvoyClient 派生全字段** | §4.23.2 | — | 定案 |
| 租借弹窗条目 ×2 | populate | variant @+80 (+88 amount/+96 kind 0/1/2; fuel 伪行 +72) / archetype @+8072 (**+8080 = populate/回写主消费对象** — §4.31.105 五函全部只触及 +8080); +7920 手填请求量 | DIPLOMACY_LEND_LEASE_DESC 五键 + diplomacypopupitems.cpp 断言 | — | 定案 |

**横断新骨架**: CStandardGridBoxItem 基 vtable 0X142B45EF0 实名; 嵌入窗基族 B
(sub_140B79CD0, 与 §4.30.15 CEmbeddedWindow 并族); 数量输入组件 0xC08 / 价格档组件 0x1078。



> **补贴草案控制器 CSubsidyDraft (352B; NInternationalMarket 域)**: 构造 = CPurchaseDraftWindow::SetupSubsidyDraft (lambda 实名直证; 宿主窗壳本节已载 0x1368), malloc(0x160); 基 **CUpdateable** 6 槽 {[1] Update = `return +16==0` (CUpdateable 契约)}; +16 完成/脏旗 / +24 市场侧引用 / +32..+344 容器与 std::function 族 (dtor 逐槽 +200/+232/+240/+244/+248/+312 子窗件/+344 引用包装); 读 gs+1312/1316 玩家 tag。语义闭环: 列表条目 CSubsidyDraftListItemView (名录行) ↔ 本草案控制器 ↔ 载荷 CSubsidyDraftPayload 32B @view+208 (本节已载) + 补贴 48B 条 (§4.23.2)。**CPriceLevelsWidget** 4216B ("price_levels_widget"; 基 CUiWidget 主 vtable 1 槽 + 次 vtable @+16; 三个 1368B 容器子件 @+24/+1392/+2760 — 与 CEditMarketStockpileWindow 同型): 国际市场价格档位显示 widget, 轻耦合; 数值侧语义 = §4.23.16b (显示值 = 档因子 − 1.0)。

> **市场面板状态控制器 NInternationalMarket::CMarketPanelsStateController** (market_panels_state_controller.cpp, 4 函; 类身份三重直证 = Setup 的两个 `std::_Func_impl_no_alloc<…CMarketPanelsStateController::Setup'::'2'::_lambda_1_/2_…>` vtable 符号名 + PE RTTI 串 + vt2class.json 条目 0x142A7BBB0 / 0x142A7BBE8):

| VA | 行数 | 身份 |
|---|---|---|
| 0x141DF10E0 | 89 | Setup (字段映射 + 双 tab 回调注册 + 首建 overview 面板) |
| 0x141DF0DE0 | 87 | ShowBuyerPanel (→ state 1, buyer_specific_tab_window) |
| 0x141DF0F50 | 91 | ShowSellerPanel (→ state 2, seller_specific_tab_window) |
| 0x141DF0CA0 | 57 | Hide / Teardown (state→0, 释放面板 + 撤回调 + 清上下文槽) |

控制器布局 (断言 `_pSellerTabButton && _pBuyerTabButton` cpp:111, latch byte_14338C780):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | CMarketPanelController* | 当前面板 (旧值经 vt[0](this,1) 释放, CReferenceObject 风格 Release) |
| +8 | uint32 | 面板状态枚举 (0 = 无 / 1 = 买方 / 2 = 卖方 / 3 = 总览) |
| +16 | 指针 | 上下文 A (面板构造器第 2 参; overview 构造器读其 +16 域) |
| +24 | 指针 | 上下文 B (三个面板构造器共用首参) |
| +32 | 指针 | 上下文 C (仅 seller 面板构造器消费) |
| +40 | 指针 | 上下文 D (三构造器末参) |
| +48 | CButtonWrapper | 卖方 tab 钮 (Setup 的 a4; lambda_2 回调注册于 +48+24) |
| +56 | CButtonWrapper | 买方 tab 钮 (Setup 的 a5; lambda_1 回调注册于 +56+24) |

lambda → 状态映射 (`_Func_impl_no_alloc` vtable operator() 在 +16 槽, PE 直证): lambda_1 (vtable 0x142A7BBB0) operator() = sub_141DF12E0 → sub_141DF0DE0 (state 1 / 买方); lambda_2 (0x142A7BBE8) operator() = sub_141DF12F0 → sub_141DF0F50 (state 2 / 卖方)。回调注册 sub_1402E1260 = CButtonWrapper 回调注册 (回调表 @+24, §4.00.6 CButtonObserverGlue)。**切换语义**: ShowBuyerPanel — state==1 → state 3 + 建 overview 面板; 否则 state 1 + 建买方面板。ShowSellerPanel — state==2 → state 3 + 建 overview; 否则 state 2 + 建卖方面板 (即「再点当前 tab → 展开总览」)。

面板类四件套 (PE RTTI 串 + 窗口名串直证):

| state | 窗口名 | 类 (RTTI) | 尺寸 | 构造器 |
|---|---|---|---|---|
| 1 | buyer_specific_tab_window | NInternationalMarket::CMarketBuyerPanelController | 40 | sub_141F8A610 |
| 2 | seller_specific_tab_window | NInternationalMarket::CMarketSellerPanelController | 48 | sub_141F8C630 |
| 3 | overview_specific_tab_window | NInternationalMarket::CMarketOverviewPanelController | 5608 | sub_141F8A970 |

基类 ctor sub_141FF25D0(obj, a2, a3, name, a4): `*obj = CMarketPanelController::vftable; obj[1] = a2; obj[2] = a4; obj[3] = sub_1422BA420(a3, name, 1)` (按 (容器, 名) 建子窗存 +24; 建后 `*(obj[3]+165) &= ~0x10` + 调子窗 vt[+120])。CMarketOverviewPanelController 另有 7 个 lambda (vtable 0x142A9FA18…0x142A9FB68), 与 5608B 体积相符 (内含多个 1368B 容器子件, 同 CPriceLevelsWidget 同型)。tab 钮高亮: 卖方钮 (+48) 得 `(state==2)+1`, 买方钮 (+56) 得 `(state==1)+1` → 调 CButton vtable+176 (slot 22; 实参 1 = 未选 / 2 = 选中, 与 §4.30.31 CButton+176 状态机体系相容); 钮解析 sub_140F28EA0 = CButtonWrapper::GetButton (buttonwrapper.h:40 断言, 返 wrapper+8)。Hide: state!=0 时 state→0 + 释面板 + 双钮状态重算, 随后清 +16/+24/+32/+40, 并对两钮 +24 回调表发 sub_1402E1260 撤销。⚠ +24/+32 类型方向未决 (lambda 签名含 `CEquipmentMarketStatus*` + 2×`CProductionStatus*`, 但 overview 构造器只用 +24、seller 构造器用 +24 与 +32; +16/+40 亦未定名)。

> **护航任务进度条 NInternationalMarket::SConvoyAssignment** (purchase_contract_entry.cpp 匿名命名空间; GetProgressText sub_142052D70, 148 行): 布局 {+0 vtable, +8 i32 当前护航量, +12 i32 需求护航量 _Max, +16 qword 护航源}。栈构造来源 (宿主数据对象 `*(entry+64)`): +240 → +16 / +280 → +8 / +284 → +12; 断言 `_Max > 0` (cpp:598, latch byte_14338D000)。§G/§R 文本着色 = `*(+8) < *(+12)` ? 'G' (71) : 'R' (82); ⚠ **颜色方向两批分析不一致待裁** — 一读为「未满 → 绿 / 已满 → 红」, 另读为「current < max → §R 未竟红」(语义与进度条直觉相反, 候选: a1+8 实为「剩余量」而非「已完成量」), 需 UI 截图/运行期复核; vtable[0](this, &out) 取比率字符后拼百分比串 (尾追图标码点 8465 = 0x2111, §4.31 cic_icon 同体系, 具体图标名未决)。唯一业务调用方 = sub_142050B00 (合同条目 tooltip 构建器, 头部 loc 键 PURCHASE_CONTRACT_REQUIRED_CONVOYS_TITLE_TT, 同帖随后格式化 EFFICIENCY 项); 同件 sub_142052B10 用 vtable[+8] (当前<需求时触发刷新)。

> **装备类别 → 市场图标名** (sub_1420516C0, 80 行; 枚举序与上 CEquipmentCategoryFiltersWidget 四过滤钮一致):

| 类别枚举 | 图标 key | 存放 |
|---|---|---|
| 0 (infantry) | GFX_im_infantry_artillery_equipment_icon | 堆 malloc(0x30) |
| 1 (armor) | GFX_im_armor_icon | 堆 malloc(0x20) |
| 2 (air) | GFX_im_air_icon | SSO 内联 |
| 3 (naval) | GFX_im_navy_icon | 堆 malloc(0x20) |
| 其他 | GFX_placeholder_bordered | 堆 malloc(0x20) + 断言 `Something went wrong with equipment category.` (cpp:843, latch byte_14338D001) |

#### 4.31.16 散簇·建筑+MIO (CBuildingRosterWindow/RosterItem/ItemBase/Listener/StatEntry / COrganisationListWindow/ListItem/DetailWindow/TreeWindow)

**入口链**: RosterWindow target = **CCustomizableBuildingCollection\* @win+80**
(自由函数 SetTarget sub_1415C1740, 源 = 当前国 cc+4016 naval_headquarter_status);
OrganisationListItem target = org idpair @item+132 (哨兵 qword_14333D528);
**MIO 实例挂在 CPolitics 下 (cc+3984→+256 listenable 枚举源)**, 不走 cc+304 序列化块直读。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 建筑 roster 行 | Refresh [18] | item+32 = 80B 数据元指针 (e+56 binst / e+64 模块); CBuilding+64 level / +472 状态回指 / +480 def 回指; def+740 图标帧 / def+696/+700 省州双模式门; taskforce +1832/+1844 计数链 | §4.14/§4.16 命中 6 | — | 定案 |
| MIO 列表窗 | 模式态机 @+248 + 选中 org @+280 | **DB 0x332ef48** / cc+3984 CPolitics (+256 listenable 枚举源); 6 宿主视图嵌入点 | COrganisationListItem @112 notify→[8] Refresh 自刷新闭环 | — | 定案 |
| MIO 组织行 | SetTarget sub_141F22940 | **COrganisation 运行时偏移 9 个: +168 容量/+228 已指派/+272 def/+280 指派/+288（= 属主国 tag, §4.8.12）/+304 size/+312 开关/+336+348 队列/+392 政策 token=19479 "undefined" 命中** | byte_143330ECC = "capacity" 特性全局门 (sort_capacity/task_capacity 共用) | — | 定案 |
| MIO 详情/树窗 | owner item+132 idpair 间接 | DetailWindow 内嵌于 ListItem+144 (tab0 树/tab1 历史; +8280 树窗指针); TreeWindow target = org idpair @+40, +1336 内嵌 **CTraitTree** (CSkillTreeBase\<CTraitTreeItem\> 特化, 新类) | — | — | 定案 |

**建筑/MIO vtable与尺寸总表**（1.19.3 直读；COL offset 判定主/次表，mdisp 40/24/56/104/112 全未变）：

| 类 | 主 vtable（槽数） | 次表 | sizeof | 备注 |
|---|---|---|---|---|
| CBuildingRosterWindow | 0x1429DD9A0（4） | @40 0x1429DD9C8（2） | 1480 | 总装厂 sub_140B614C0 嵌 @+424 |
| CBuildingRosterItem | 0x142A59878（19） | @24 0x142A59918（tooltip） | 2856 | [18] Refresh 0x141C693B0 |
| CBuildingItemBase | 0x142A76C28（19） | @24 0x142A76CC8（tooltip，[0]=纯虚） | 48 足迹 | 四派生 ctor 均 +32=a3 → 布局定案 |
| CBuildingListener | 0x142A206C0（5） | — | — | 空 listener 壳（[0][3][4] 纯虚） |
| CBuildingStatEntry | 0x142AA2FC8（19） | @24 0x142AA3068 | 104（0x68） | 池工厂 sub_141EFCFC0（宿主+4216 gui ctx）；**宿主定案 = CTechnologyStatListEntry**（科技窗单位统计列表项；池容器 @宿主 +0..+32；ctor sub_141EFC5E0 同时写 +4216 gui ctx 与 +4064 内嵌块） |
| COrganisationListWindow | 0x142A56348（4） | @40 0x142A56370（2） | — | [2] Reload 0x141C3C7A0 |
| COrganisationListItem | 0x142A94550（13） | @56 0x142A945C0（24） + @104 0x142A94688（2） + @112 0x142A946A0（4） | 17488（0x4450） | [8] Refresh 0x141F23810；@112[2] notify → 主表[8] 自刷新闭环；flag==1 → 空行名 `industrial_organisation_empty_list_item`（**无独立 EmptyItem 类，负定案**） |
| COrganisationDetailWindow | 0x142A93CA0（4） | @40 0x142A93CC8（2） | 14472（内嵌于 ListItem+144） | [2] Reload 0x141F1EB10；源断言 industrial_org_detail_window.cpp:225 两版同行 |
| COrganisationTreeWindow | 0x142AA5BA8（19） | @24 0x142AA5C48（2） | **1576（0x628 新定案）** | [4] 开钩 0x141FC13A0（+1521 dirty → 重建 sub_1416CD6B0） |

**COrganisationListWindow 字段**（ctor 0x141C3A650 逐行定案）：+240 root / +248 模式结构（+248 mode / +256 self-ptr / +264 can_unlock / +268 type_filter 1..4 / +272 sort / +276 asc；`+288..+312` 四组 std::function 上下文回调——选择回调消费者 = sub_141F21750 读 owner+288（mode==2 另读 owner+296）；**装载点定案 = sub_141C3C560**（按 win+248 模式码分派: mode==1 → sub_141A01960(win+288, 目标, 0) / mode==2 → sub_141A01930(win+296, 目标, 0)，两支失败均落 `目标+128 = 0` 置灰；惰性触发包装 sub_141F23DF0）；+288 与 +296 是两条互斥的模式化取值回调）/ +280 选中 / +320 alloc = off_143085170。**10×1368B 钮胶水（偏移全定案，ctor sub_140B77E10 逐块 / Setup sub_1422DD480 绑 λ1..λ10）**：

| 偏移 | 元素名 | 回调 |
|---|---|---|
| +328 | close_button | λ1 |
| +1696 | can_unlock_trait_filter_button | λ2 |
| +3064 | tank_filter_button | λ3 |
| +4432 | ship_filter_button | λ4 |
| +5800 | plane_filter_button | λ5 |
| +7168 | materiel_filter_button | λ6 |
| +8536 | sort_size | λ7 |
| +9904 | sort_name | λ8 |
| +11272 | sort_capacity（受 byte_143330ECC 门） | λ9 |
| +12640 | sort_cost（受 sub_141E8F840(&+248) 门） | λ10 |

池/模板/锚点：行池 {data@+14008, cap@+14016, count@+14020, alloc@+14024}（malloc 0x4450 行 ctor flag=0）/ +14032 模板项（flag=1 → 空行名）/ 数据双源 = 块1 mio_organisation DB **qword_14332EF48**（枚举 sub_140A53900 + 槽 off_142A56A48）→ +14048 / 块2 当前国 → \*(cc+3984) CPolitics → \*(CPolitics+256) listenable（sub_140BACE10 枚举 + 槽 off_142A56A58）→ +14080 / 元素 `organisation_list` listbox @+14096 / `filter_options` @+14104 / 位置锚 +14112 default / +14120 mode4 equipment_designer / +14128 mode1 technology（可见列刷新 sub_141C3D820）；钮态刷新 sub_141C3DA90；池维护/过滤排序 = 引擎 sub_141E8F260(&+248)（sub_141C3B620）；6 宿主嵌入点 +9544/+17128/+7096/+22256/+72/+5328（宿主函数 0x141738090 / 0x14157C600 / 0x141F6F570 / 0x1418029A0 / 0x141776C00 / 0x141BD9330；+7096 宿主 = production_equipment_window，创建点 0x141738090，宿主窗 +9272 存本窗）。

**MIO 名册排序器 (industrial_org_selector.cpp; 定案)** — 比较器对象 (相对 window = obj+256): +0 上下文/模式结构指针 (指 `{+0 mode 枚举, +32 钉住的 MIO 指针}`; mode = win+248) / +16 排序类型枚举 (= win+272 sort) / +20 升序旗 (= win+276 asc; **1 = 升序, 0 = 降序**):

| 排序类型 | 比较内容 | 取值函数 / 偏移 |
|---|---|---|
| 0 | 默认 (转 sub_141914DF0) | 见下 |
| 1 | MIO 规模 size | mio+304 |
| 2 | 显示名 (字典序, memcmp 取 min 长度, 等长再比长度) | sub_140DB8CD0(mio) 出 std::string |
| 3 | 空闲任务容量 = 生效容量 − 已指派 | sub_140DB9860(mio,0) − mio+228 |
| 4 | 上下文相关**指派成本** (按 mode 分发, 见下表) | 三分发函数 |
| ≥5 / <0 | 断言 :41 "invalid MIO order type" → 回落默认 | — |

类型 4 的 mode 分发:

| mode | 函数 | 成本槽 | 基准 define |
|---|---|---|---|
| 1 (研究槽) | sub_140DB5B90 | mio+176 research_assign_cost | 616 ASSIGN_DESIGN_TEAM_PP_COST_PER_DAY |
| 2 / 3 (生产线 / 舰船改装) | sub_140DB5AF0 | mio+184 production_assign_cost | 618 ASSIGN_INDUSTRIAL_MANUFACTURER_PP_COST_PER_DAY |
| 4 (变体) | sub_140DB5800 | — = round(mio+192 × 617 DESIGN_TEAM_CHANGE_XP_COST) (§4.8.18 XP 成本公式) | 617 |
| 其他 | 断言 :117 "invalid MIO Roster UI mode" → 返回 flag==0 | — | |

> **默认比较器 sub_141914DF0**: mode==0 → 直接按 size 降序; 否则钉住的 MIO (*(ctx+32)) 恒排首 (a2 命中→1, a3 命中→0), 若 byte_143330ECC == 0 (ENABLE_TASK_CAPACITY 特性门) 或两者空闲容量相等 → 按 size 降序, 否则按空闲容量降序。
> **CycleSortOrder sub_1419152C0 三档状态机**: type==a2 且 asc=1 → asc=0 (转降序); type==a2 且 asc=0 → type=0, asc=1 (回默认序); type!=a2 → type=a2, asc=1 (新列升序)。断言 :49 "OrderType != EOrderType::Default && should be impossible to have set directly default order in MIO Roster" — 外部只能传非 0 类型。比较器 = sub_141914F30; 按钮处理器 sub_141C3E000 → (…, 1) sort_size λ7 / sub_141C3DE90 → (…, 4) sort_cost λ10, 尾调刷新 sub_141C3D820。
> **类别过滤器文案 (industrial_org_politic.cpp sub_141F24250)**: 枚举 1..4 → 本地化键 `INDUSTRIAL_ORG_LIST_WINDOW_FILTER_CATEGORY_{TANK(47 字符)/SHIP(47)/PLANE(48)/MATERIEL(51)}` (前缀 43 字符); 其他 → 空串 + 断言 :42 "unknown MIO category filter"。


**COrganisationListItem 字段**：+120 owner / +128 u8 / +132 target idpair（初值 qword_14333D528）/ +140 mode flag / +144 内嵌 DetailWindow / +14616 background_button（胶水）/ +15984 details_button（胶水）/ +17352 特质图标数组 {d, c@+17364} / +17368 alloc / +17376..+17480 元素（name/initial_traits/task_capacity(_container)/details_button_position_no_task_capacity/icon/size_icon/size/has_policy_icon/assign_cost/empty_text/details_button_glow/equipment_icons/ai_value/background_button/details_button，Setup 0x141F22B30 逐位绑定）；SetTarget = sub_141F22940（旧 idpair 摘 listener sub_140714DB0(org+24, item+112) → 写 +132=壳+8 → 挂 @112 进壳+48（32B 元；缺则壳+24）；a2=0 复位哨兵）；Refresh = sub_141F23810（消费 org+280 指派判 sub_140DBB160(org,0) / org+272 def→def+152/+164 特质 / org+304 size / org+392 政策 token / org+168 容量 / org+228 已指派；特质图标 sub_141F20690 建 0x180/个）；空行文案 = INDUSTRIAL_ORG_EMPTY_RESEARCH/_PRODUCE/_REFIT/_GENERIC 按 owner+248 mode；mode 高亮 sub_141E8F700 / assign_cost 门 sub_141E8F840。

**COrganisationDetailWindow 字段**：+48 owner / +56 root / +64 tab / +72,+1440,+2808,+4176,+5544,+6912 六胶水（close_button/open_policies/traits_tab/history_tab/open_queue_button/toggle_auto_designs，λ1..λ7）/ +8280 树窗指针 / +8288..+8416 容器群 / **+8440 进度条** / +8456 / +8464,+9920 子面板 / +14344..+14464 元素（top_left_window/icon/industrial_org_name/size/points/tree_scrollbar_window/tree_window/tree_list/history_window/variant_history_list/prod_line_history_list/aggregated_bonus_list/open_policies_text/click_to_open_policies_text/attached_policy_icon/attached_policy_name/funds_progressbar_position）；Refresh = sub_141F1FC30（queue 文案 org+336/+348 16B 元过滤 → tab 显隐 → tab0/1 填充）；toggle 钮 = 门 + \*(u8)(org+312)；tab0 填充 = sub_141F1C470（tree+40 = org 壳+8 → populate sub_141FC1CC0 → +14400）；收起/展开 = sub_141F1E8D0 / sub_141F1FB90（+8464 清 sub_141FB25B0 / +9920 清 sub_141FB6DC0）；**表头刷新 = sub_141F20190（tab 钮态、icon、名 sub_140DB8CD0、size org+304、trait points、funds 进度条 = 100000×sub_140DB8B30(org) 与 org+296 比值）**；**政策段 = sub_141F1C2A0（org+392 → sub_140DB7DB0(org, \*(u32\*)(org+392)) 定 attached_policy_icon/name 显隐）**。

**COrganisationTreeWindow (1576B)**：+32 owner（sub_141F1A8E0 取 org）/ +40 target idpair（初值 qword_14333D528）/ +48 胶水（cb + 20 槽 sub_141FBD5C0 装；拆 sub_1402DE2D0）/ +1336 内嵌 CTraitTree（CSkillTreeBase\<CTraitTreeItem\> 特化，vtable 0x142AA5A18；CTraitTreeItem vtable 0x142AB1E58/0x142AB1EA0，0x180/个）；内嵌树字段：+1360 traits_window / +1368 scrollbar_window / +1392 alloc / +1400 0x58 自链节点（malloc 88B 存 +1400）/ +1440,+1464,+1488,+1528 串 / +1520 u16 态；populate = sub_141FC1CC0（org = resolve(&+40)；背景元素贴图 sub_140DB5540；子组按 !assigned 置灰（sub_140DBB160(org,0)^1 = org+280 门）；+1521=1 → 重建 sub_1416CD6B0 → 清 +1520 → 回基）。

> gui 库双源 1.19.3 = **qword_143453230**（building_roster_window/naval_headquarter_item ctor 字面量）与 \*(qword_14332F698+1272)（MIO 窗 ctor）；RosterWindow @40 tooltip = 悬停==win+72 → NAVAL_HEADQUARTER_ACTIVE_TT（参 dword_143332744）；条目跳过谓词 = def+883∧!DLC49 ∨ def+885∧!DLC52 ∨ !(\*(def+1208))vtable[3]；StatEntry = +32 串 label（cap+56=15）/ +64 u32=1 / +72 串 value（cap+96=15），SetContent sub_141FAFEB0；tooltip 色码 `0x11+'Y'` 黄标。

#### 4.31.17 散簇·NProject Program (CProgramListBase/List/ItemBase/Item/View/AvailableProjectsView/OngoingProjectView)

**入口链**: CProgramList target = 玩家国 **cc+4008 CProgramStatus 的 program
CRef 向量 {data@S+32, count@S+44}** (宿主 CFacilitiesTabView+152); ItemBase
target = **NProject::CProgram (+56 CRef 柄, SetTarget vtable[20])**;
CProgramStatus 双vtable (vtable1@8=0x142971858) — **「+72 块键 11956」实为绝对 S+80
(定案: writer sub_140E78830 this=S+8, program 向量 +24/+36 逐位吻合; 候选注销, 见 §4.3)**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 程序条目 | 19 窗柄 + 7 glue | **program+72 facility def / +80 项目词元 / +84 旗 / +88 科学家 CRef / +128 移除旗 / +144 拆除 COnDelay / +160 拆除中 / +176 支援科学家 / +248 进度 fix5 / +376 未读奖励** | 4 vtable含 RTTI 实名 SScientistUpdatedListener@32; CCharacter+192 CScientist/+308 is_scientist_injured 命中 | — | 定案 |
| 程序条目 (Item) | [21] open_program→CProgramView / [24] faction_icon / [26] 拆除确认 | faction+2000/+2012 成员判定 + faction+1352 icon+"_miniature"; CFactionProgramStatus+1992 命中 | 弹窗 = CGenericDefaultConfirmationPopUpWindow (0x1080) | — | 定案 |
| 可用项目视图 | Update | 池按 **facility def 词元表 def+664/+676** 筛可用项目 → CProjectItem 行; **P+48 = RH 桶数组** (12B 桶 {u8 探测序长, u32 键词元, i16 值}, 73244475 双轮混淆, 值 bit15 空哨; P+16 元素数组 448B/元, P+60 桶掩码, +64 附加桶) (OngoingProjectView +148 词元解析 → +152 CProject\*) | 非多态内嵌辅助类 @ProjectsView+16 | — | 定案 |
| 进行中项目视图 | vtable[1] Update / vtable[6] / vtable[11] SetupDerived | project+24/+28/+32/+40 布局 (同族命中 §4.30.23); program+80 词元终证/+444 旗 | **CResetUnreadPrototypeRewardsCounterCommand** 等四命令实名 (CDismantleFacility / CAbortDismantleFacility / CUnattachScientist / CResetUnreadPrototypeRewardsCounter) | — | 定案 |

**CProgramItemBase（重锚后零漂移；4 vtable @0/24/32/40：CTooltipHandler/SScopedListener\<SScientistUpdatedListener\>/NLoc 实名照见）**：主 vtable 0x142A92250（28 槽：[19] populate 0x141F0FAB0 / [20] SetTarget 0x141F0F960（\*(program+8)→item+56，ref.h 断言）/ [22] 0x141F0F3B0 / [27] 0x141F0CCB0）；ctor sub_141F0B180(a1,"program_item")；空 CRef 柄 = qword_14333D528 → item+56；+64 NLoc 环境 176B（sub_140535110）；+240/+256 = populate 缓存 OWORD 对（populate 尾写）；+272..+416 = **十九窗柄同名绑定**（ongoing 图标容器/facility_damage_bar/unread_prototype_reward/state_name/facility_name/research_speed_tex/进度 pips 图/ongoing_project_window/ongoing_project_display/ongoing_project_default/resource_usage/status_info_text/basic_research/dismantle_window/scientist_name/scientist_removal_clock_icon/scientist_injured/skill_levels/scientist_trait_icons；新证三枚：+48 = "facility_icon" 初值 GFX_buildings_strip / +272 = "project_progressbar_position" widget + tooltip lambda / +320 = "supply_icon"）；+424 = open_program + 高亮框 glue（SetTarget/populate/[24] 三处消费）；+1792 = assign_scientist_button glue；+3160/+4528/+5896/+7264/+8632 = change/unassign/dismantle/abort/第七 glue（+7264 abort 初隐 vtable+128 \|=0x10）；+10000/+10008 = 双弹窗缓存。

**CProgramItemBase::Update 消费链 (sub_141F10000; 高置信)**: +48 ← `*(u32*)(facility_def+740)` 图标 (def = *(facility+480)) / **+280 ← `100 − trunc(progress/1e5)`** (progress = sub_1410DB810(facility, &out, level): level==0 或 level>healthy+1 → 0; level==healthy+1 在建级 → partial_health@+72; level≤healthy 完工 → 10000000) — ⚠ +280 与 +272 `project_progressbar_position` 的 gui 名对应关系待裁 / **+288 显隐门 = `program+376 > 0`** (≤0 → 隐 + widget+117|=0x10; 显则清 0x10) — 即 unread_prototype_reward, 与 §4.3 CProgram+376 计数器互证 / +296 ← 本地化 `PROGRAM_STATE_NAME {STATE: sub_1409D91D0(*(progress+192))}` / +304 ← `*(facility_def+480)+528` 串 (facility_name) / +312 ← sub_1414422B0(program, &out, 0) 程序名 (program+84 旗 → 所属国 *(cc+4008)+24 项目池 → sub_1414823B0(pool, program+80 token) 反查项目 → sub_141BE7200 本地化) / +320 ← 供应图标 = clamp(program+248, MINIMUM_PROJECT_SPEED_FACTOR_FROM_SUPPLY qword_143332638, 1e5) ≤ FACILITY_SUPPLY_WARNING_RED_RATIO qword_143333C50 → 4 否则 5 (sub_141442A90)。

**CProgramItemBase 程序名取值桥 = 0x141F0CC00** (program_item.cpp:559): item+56 CRef (`{type@+56, id@+60}`, 任一非 0 → sub_14221F310 解引, 否则 0) → 0 时断言 "pProgram" → sub_1414422B0(program, out, flag) 取程序名 → 返 out (字符串出参)。唯一调用点 = tooltip/populate 写器 sub_141F0E930 在件名为 `research_speed_text` 时填名。两断言所测对象不同: :155 `"pFacility && \"Special project program without a facility\""` 测 sub_1414427B0(program) 的**派生设施**; :559 `"pProgram"` 测 item+56 CRef 解引的 **program 本身**。⚠ +280 与 +272 `project_progressbar_position` 的 gui 名对应关系仍待裁; +320 另有显隐门 = 供应进度 (sub_141442A90 出参 v30) **≥ 1e5 才显示** (widget+117 |= 0x10 / vt[+120] 隐, 否则清 0x10 / vt[+128] 显)。

**CProgramItem (11384B)**：主 vtable 0x142A92388（[21] 0x141F0F370 / [23] 0x141F0DB90 / [24] faction_icon 0x141F0FC90（faction = \*(\*(country+3976)+656)；faction_programs {d@+2000, c@+2012} 含 item+56/+60 idpair → +10016 显 + 贴 faction+1352+"_miniature"；+424 高亮帧 2/1）/ [26] 拆除确认 0x141F0F440 → malloc 0x30 CDismantleFacilityCommand（item+56 resolve）投递 sub_142250B00）；ctor sub_141F0AF70；glue+10016 = "faction_icon" + memset 1368B；CProgramList::Update 主链 = gs+1312/1316 → cc+4008 → S+32{count@S+44} → malloc 0x2C78 → vtable[20]（list {d@8, cap@16, c@20, alloc@24}）。

**CFactionProgramItem (11448B, "faction_program_item")**：主 vtable 0x142A528D8（[19]/[20] 同基 / [21] 0x141C19CC0 / [24] Update 0x141C1A090 / [25] 0x141C1A030 / [26] 0x141C19D30）；ctor sub_141C18C70；+10016 icon "background"（无项目时显；Update [24] 本地国 → 隐）；+10000 popup ptr = OnDismantleFacility 确认窗缓存（[26] malloc 4224B CGenericDefaultConfirmationPopUpWindow，vtable 0x142A40428，内联 ctor：+4096 确认 fn/+4160 取消 fn/+4152/+4216 置零；题/文 = FACTION_UNASSIGN_PROJECT_POPUP_TITLE/_DESC{STATE_NAME}）；拆除出口 = CRemoveFactionProgramCommand 0x30（+40 = status ref）投递（队列 = qword_14332F698 vtable+136）；+10024 facility_assign_button（无 status → 显）；+11392/+11400 = member_scientists_grid / _window；**科学家格子项向量 +11408/+11416/+11420/+11424**（预建 dword_143333FA8 个；行 = CFactionMemberScientistItem 4184B malloc → sub_141F16130，入格 sub_1422C7E50）；+11432 设施指派管理器 = \*(sub_140B674F0(\*(qword_14332F698 vtable+184), 20)+20200)；+11440 country_flag（Update：sub_140B44AC0(\*(mgr+1272), item+11440, status+24 tag, 1, 0, 1)）；Update 显隐主链 = 本地 tag 判定（gs+1312/1316 + sub_140BB52F0）+ +5896/+7264 hover 门 + +4528 谓词 sub_141442B30 + +368/+336/+280 恒隐。

**CProgramOngoingProjectView::SetupDerived = 0x141EEE8F0** (438 行, 本节槽位 [11] 补 VA; lambda 修饰名直证; 源簇名 ing_project_view.cpp = **program_ongoing_project_view.cpp** 断行伪影, special_projects/ui/ 域): 执行序 = ① kind6 监听注册 (向 handler 监听表尾插 view+128, 先于断言) → ② 断言 :359 view+148 词元 ≠ 19479 (undefined 哨兵) → ③ 项目解析 `sub_140BB4390(view+136)` → `sub_1414823B0(*(*(cc+4008)+24), view+148)` (CProjectPool 词元查找) → ④ 命中 → view+152 = project + reward 装载 sub_141FA3A60 (obj+4312 = project / obj+4297 有效旗) + obj vtable[11] → ⑤ 未命中 → 断言 :365 + view+148 复位 19479 + handler+1192 收件箱尾插 216B 条 {载荷 u32@+0 = 5, 分发 kind u8@+208 = 1} (视图码标脏槽 5, handler+240 槽) + render_thread 旗 byte_14332F6AA == 0 才立即泵 sub_140B6B050 — 书 s4_00 收件箱通道的第一个**消费侧完整体**样本。尾段 debug 订阅 (byte_14332EC69 门) = 「打开 db 文件」点击回调经 open_db_file_window vtable[67] 订阅, 存 view+200。

CProgramOngoingProjectView 窗件表 (查找根 = view+112):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +112 | 窗口根* | 全部子件查找宿主 |
| +136 | 国引用 | → sub_140BB4390 得 CCountry* |
| +140 | 8B 值 | 视图上下文值 (三窗 ctor 共同解引用源, 语义未决) |
| +148 | uint32 | 项目词元 (program+80 同源; 失败复位 19479) |
| +152 | NProject::CProject* | 解析命中缓存 |
| +160 | 匿名结构 (56) | ctor sub_141EECB20 (无 vtable): {+0 窗根, +8 *(view+140), +16 project, +24..+48 清零} |
| +168 | NProject::NUi::CPreviewState* | 2848B, ctor sub_141EEC440 (vftable 实名直证); 头部 {+0 vtable, +8 flavor_window, +16 *(view+140), +24 project} |
| +176 | NProject::NUi::CStartedResearchState* | 5552B, ctor sub_141EECF40 (vftable 实名; 其 lambda 签名直证 **NProject::NUi::CProjectOutputRewardWindow** 类名) |
| +184 | project_name 标签* | sub_1422BC600 取件 |
| +192 | open_db_file_window* | sub_1422BA420 取件; 其 +48 子体 vtable[69] ← view+56 (上下文绑定) |
| +200 | std::function | debug 订阅存储 |
| +1568 | research_completed_icon* | sub_1422BC0B0 取件 |
| +1576 | CProjectOutputRewardWindow (内嵌) | 装载器 sub_141FA3A60 |
| +5968 | 状态源对象* | 未名; vtable[0] 填 64B 结构, +56 指针被 CPreviewState ctor 消费 |

> handler (经 idler qword_14332F6A0 vtable[23] 取用, 与「idler+1720 handler」同源两路) 两容器精确形: kind6 监听表 {data@+1216, cap@+1224, count@+1228, 分配器@+1232} 8B 元 / 收件箱 {data@+1192, cap@+1200, count@+1204, 分配器@+1208} 216B 条; 扩容式 = max(count+1, (int)(cap×1.5)) (基数 = **cap**, 仅 count==cap 时触发), 重分配序 = 新表[count] 先落新元 → memcpy 旧数据 → free 旧表。取件原语三型 sub_1422BA420/sub_1422BC600/sub_1422BC0B0 = containerwindow.cpp FindWindow 族 (共用子件数组 {data@window+4912, count@+4924}; 缺件错误通道 :991)。CProjectPool 桶形: +16 元素数组 448B/元 / **+48 RH 桶数组 12B 桶 {u8 探测序长, u32 键词元, i16 值}** (73244475 双轮混淆, 值 bit15 = 空哨) / +60 桶掩码 / +64 附加桶数。子件回调绑定通则再证: 子件+128 = 回调控制子对象 (vtable[1] bind / vtable[2] unbind), vtable[69] (offset 552) = 宿主/上下文设置槽 (传 0 清绑)。

**NProject 装载期硬校验器三函 (project_database.cpp, 五 throw 站 :178/:188/:199/:209/:224; 定案)**: 主函 0x140A93B20 = specialization 存在性 (a1+24 词元查 CSpecializationDatabase, 哈希 = 0x045D9F3B 双轮雪崩 + k^HIWORD(k) 预混, 桶 56B {dist u8@+4, 键 u32@+8, 值@+16}, 表 data@+72/mask@+84/extra@+88) + 父项目校验 0x140A94050 (a1+664 词元数组逐个查 CProjectDatabase, 桶 24B 同形, 表 data@+56/mask@+68/extra@+72, 断言锚 gameitemdatabase.h:142) + 时长两段 0x140A93E90 (a1+16 < 0 → :199 负值 / == 0 → :209 全零天数) + 阈值校验 (a1+880 原型奖励数组 16B/元 → **NProject::CPrototypeReward::SThreshold** (vftable 实名直证; 奖励 +48 min / +52 max) 拷贝构造后 min >= max → :224 throw)。CProject 新偏移: +8 项目词元 / +16 总时长 / +24 specialization 词元 / +664 父词元数组 / +676 计数 / +880 原型奖励数组 / +892 计数。

#### 4.31.18 散簇·勋章/徽章/绶带 (CMedalInstanceItem / MedalTemplateItem / MedalTemplateLeaderItem / CInsigniaEntry / InsigniaSelectionWindow / NCareerProfile::CMedalItem / CRibbonItem / CMedalPickerItem / CRibbonPickerItem / CMedalPopupWindow / CRibbonPopupWindow)

游戏内半簇 (unit_medal) 业务侧 def+152/+1068/+760/+184·+568 见 §4.18;
徽章选窗见 §4.16 (insignia); 生涯半簇见 §4.3 (NCareerProfile 六类 + 弹窗队列
CInGameIdler+2560, §4.28.14)。视图侧骨架: **8 个 Item 类全部只覆写 [0] 析构** (vs 基
CStandardGridBoxItem vtable 0X142B45EF0), 真入口 = ctor (布线+首刷) + glue 子vtable槽
(tooltip/click)。Item ctor 三件套: sub_1422C6040(this, 母件,
窗口名) → 装双vtable → FindControl 子件 (窗口vtable +120=text/+136=icon/+168=
checkbox/+440=container) → observer 挂载 (子件+48/+128)。图标控件两消费槽:
**vtable+728 = SetGfx(MSVC 串) / vtable+176 = SetFrame(u32)**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 实例勋章行 | ctor 内联 → SetGfx/SetFrame | CUnitHistoryEntry+40 子队列拷贝 → item+56 vector; 条目+104 def → def+152/+1068 | 创建点 sub_1416BEE50 (历史页行重建互证) + sub_141BF0140 (宿主 = CShipEntryDetailed, 定案) | NUM_OF_MEDALS_UI / MEDAL_EFFECTS_TOOLTIP_DELAYED | 定案 |
| 授勋模板钮 (单位/将领同构) | populate sub_141D12630/sub_141AD1DA0 | item+64=def / +72=授勋 ctx (母窗+1448 token → +2264 内嵌) | 将领版 populate sub_141ACF0C0 全库遍历门 u8@def+16; click → CGiveMedalCommand sub_141144D60 | ADD_MEDAL_TITLE/DESC; MEDAL_COST_UI_POS/NEG | 定案 |
| 徽章选窗 | populate sub_1417B79B0 / 列表重建 sub_1417B8870 | win+1704 dirty / +1708..+1732 四目标 token / +1740 选中徽章 | 母窗 = **CInGameInterfaceHandler +704 子窗** (+1716=fleet/+1732=air_group 槽类别定案, §4.31.89); 三命令 CSetOrderGroupName/IconAndColor + CSetTaskForceIconAndColor | — | 定案 |
| 生涯奖章/绶带行 | getter 族 sub_1406ABD30/14069F160/1406A38B0 | def+72 名 / +104 描述 / +136 quote(绶带) | 创建点 CAwardsView populate sub_141F7F060; collect_button lambda 含 NGameTelemetry::SAwardCollectedData 直证 | def 串即 key | 定案 |
| 生涯解锁弹窗 | [6]SetupContent sub_1419C4580/sub_1419C4DE0 | win+1496/+1500 {id,tier} / +112 Show 时间戳 | 队列管理器 CInGameIdler+2560 (§4.28.14) (medal 8B 元/ribbon 4B 元); DB 0x14332EE30/0x14332EE48 双证; 淡出 define dword_1433374B8 (CONTENT_DELAY) / dword_1433373FC (DURATION) | "ui_award_tier_01/02/03" = tier→音效名 (勋章/绶带弹窗按 tier 选播; sub_1419C40D0, medal_and_ribbon_popup_window.cpp:59 断言 + "Trying to get sound for invalid tier") | 定案 |

InstanceItem ctx 宿主 高置信: 军侧 = CArmyDivisionView 历史页 (sub_1416BEE50, §4.31.27 互证) / 舰侧 = CShipStatsView (history_grid 所在窗, shipstatsview.cpp 实名; CShipEntryDetailed = 外层详情面板, RTTI 两名并存非同物) (sub_141BF0140 建历史格);
career def+56 与 MedalData 字段语义 / 扣费币种写路径 / 弹窗伴生串性质。
(def+184/+568 归属、巨 ctor 母类 = CInGameInterfaceHandler、insignia 槽类别
均已定案 — §4.18.8 / §4.31.89。)

#### 4.31.19 散簇·部署 conveyor/请求窗 (CMilitaryDeploymentConveyorSummaryView / ConveyorView / LineView / NInternationalMarket::CRequestAutomationOptionsWindow / CRequestExpeditionariesWindowCountryEntry)

业务侧: conveyor 九字段+cv+88/W/L/模板五偏移见 §4.18.10; 远征窗见

类布局 (类名 / target / 锚点):

"aces_view"; 0x5F8B; = reorg+4224 内嵌翼; Open = sub_142033270(wing, mode, mask);
第二生命周期 = CAirWingSelectionItem+9744 按钮新建实例。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +1448 | — | 上下文翼 idpair (定案) | |
| +1504 | — | 翼属主国 | cc+1448 |
| +1508 | — | 翼属主国 | cc+1448 |
| +1512 | — | 回指窗 | |
| +1520 | — | 翼属主国 | cc+1448 |

条目 CAcesViewEntry 双 idpair:

| 元素+N | 类型 | 名称 | 备注 |
|---|---|---|---|
| 元素+40 | idpair | ace (ace+8 直拷) | |
| 元素+48 | idpair | 上下文翼 | SetAce sub_142033D60 |
§4.10; 市场自动化窗见 §4.23。视图侧: 三 conveyor 行件均由
CCountryDeploymentView+1408 子控制器派发 (链已坐实); SummaryView/
LineView 仅 [0]dtor 覆写, ConveyorView 多覆 [4]=Refresh 0X141D87950 (退出
两个内嵌地图模式)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 传送带汇总行 | populate sub_141D8A200 | **item+3944 = conveyor idpair** (ctor sub_141D83480 取 a3=CMilitaryDeploymentConveyor+8) | 七 §4.18.10 锚全中 (closed+148/lines+120/amount+72/location+76/dep+72/template+32→+492) | DIVISION_QUEUED / TRAINING_HALTED / CONVEYOR_CAN_NOT_* | 定案 |
| 传送带编辑行 | populate sub_141D8A520 | **item+6792 = conveyor idpair**; **+6800/+6816 = CMapModeMilitaryDeployment(20)/ToOrder(21) 两新类** | 18 元素窗名全对字面量; 11 命令全 RTTI (§4.18.10 补记); [4]Refresh 退出选址模式 | CONVEYOR_SET_LOCATION_NOT_SET / MORE_THAN_NINE | 定案 |
| 训练行卡片 | populate sub_141D8AE90 | **item+4184 = 行包裹件 W idpair** (W+40 序号/+48 训练行 L/+56 conveyor 回指) | 双进度条 (装备 sub_140CE7660 / 训练 sub_140CE9E90=L+96); ETA 流亡修正 cv+152; 取消 >20% 弹确认 | CONVEYOR_LINE_SERIES_BASE / CONVEYOR_LINE_CANCEL_ACCEPT_* | 高置信 |
| 市场自动化弹窗 | [11]SetupDerived 0X142007AD0 | **win+1440 = 宿主上下文+64**; target+32/+33/+34 三 bool ↔ 三 checkbox | 统一投 CSetMarketRequestAutomationOptionsCommand (cmd+40=请求 id) | 三 checkbox 名 | 定案 |
| 远征军国条目 | 填充 sub_141D07900 | **item+40 = CCountry\* 裸指针** (池复用直写) | dip+656→fac+88 成员国遍历; cc+552 CCountryAI 双评估; ±1/5/10 shift/ctrl 修饰 clamp 师总数 | REQUEST_EXPEDITIONARIES_DIVISIONS_COUNT | 定案 |

未决 2 项: 可用性谓词容器语义 (populate sub_141D8AE90 谓词容器未逐值展开) / automation target 类名 (+1440 = ctor a2, 创建点 sub_1424AB6C0 传宿主 a2+64; 消费 = +32/+33/+34 三布尔, toggle 回调 sub_142008030, 命令构造 sub_141B1BA00 — 定案; 类名需活体: 扫堆定位 "request_automation_options_window" 读 +1440 比对 vt_rtti)。
已结 4 项: 训练行 L 类名 = CMilitaryDeployment (§4.18.12 定案) / 远征窗发送命令 = CRequestExpeditionariesCommand (RTTI, 80B; ctor sub_14114C910 从 action 拷贝 {+12 tag/+20/+22 WORD/+24/+25 byte/+28/+32 u32/+40 u32/+48 容器} / sub_14114F8D0 默认 +12=-1; 载荷逐字段待裁) / modifier 键 222 = MODIFIER_MAX_TRAINING_XP_FACTOR (idmap:223) / L+112 池 = 装备人力池 army_manpower_value (§4.18.12)。

#### 4.31.20 散簇·过滤器行项 (CFilterItem 基 / CFilterTokenItem / MajorItem / FactionItem / GoalItem / RuleItem / ListItem / CFilterEntryItem\<T\>×3)

业务侧: 外交视四创建点+控制器四激活集见 §4.10; 阵营 goal/rule 过滤见 §4.5;
空军重组分类过滤见 §4.15; 项目专精过滤见 §4.3。视图侧骨架: **全族主vtable
19 槽零功能覆写** (唯一差异 = [0] dtor; 基 CFilterItem 槽0 纯虚) — 真入口 =
ctor + 副vtable CTooltipHandler 槽0 + 非虚 setter (Goal/Rule/List 有, Token/
Major/Faction 无, target ctor 一次性写入); 基布局 +16=行根/+24=param 枚举
(0州/1理念组/3阵营/4major/5subject; 2 未见)/+28=checked; SetChecked =
sub_141C41140。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| token 过滤钮 (贸易/外交) | ctor sub_141C3EFD0 | item+72=token / +40=显示名 | 外交视双创建点 (CStateDatabase p0 / **CIdeologyGroup 库 qword_14332EF38 p1 定案**) | CORE_FILTER_BY | 定案 |
| 阵营过滤钮 | ctor sub_141C3EA40 | item+72=*(fac+8) id 对 CRef | 名=GetName (fac+24/template+1384 互证); toggle→控制器+3936 | CORE_FILTER_BY | 定案 |
| major 过滤钮 | ctor sub_141C3EDD0 | 无 target, +40="MAJOR" 字面 | toggle→控制器+3960 旗; 应用 cc+5210 互证 | CORE_FILTER_BY_MAJOR | 定案 |
| goal 过滤钮 | Refresh sub_141F13C00 | item+32=goal token; window+1664 槽 idx/+1668 激活 token | 行源 fac+1784 per-slot 表 (§4.5 互证) | `<goal>`_FACTION_GOAL_FILTER | 定案 |
| rule 过滤钮 | Refresh sub_141F15EC0 | item+32=rule token; window+2896 激活/+2848 选中门 | 行源 fac+1544 哈希D (RH 8B 元 token@+4) | `<rule>`_filter_tooltip | 定案 |
| 库存分类过滤钮 | setter sub_14205DE80 | item+1328={archetype*,count} 向量; **interface_overview_category_index** 分桶 | 断言语义直证; 窗+4336=激活分类; 装备型身份并案候选 | CREATE_AIRWING_VIEW_FILTER_DESC/_BREAKDOWN | 定案 |
| 项目专精过滤钮 | populate sub_141471C40 | +32=CSpecializationTemplate def {+8 token/+16 图标}; +1416..+1448 回调五件套 | TGameItemDatabase qword_14332F068 查表; lambda 签名直证 | FILTER_ON_SPECIALIZATION_TOOLTIP | 定案 |

未决 5 项: param=2 (neighbor 预留; 探针 = 遍历外交/贸易过滤行读 +24 param 值域) / rule 窗+2848 写入链 /
Goal/Rule 应用逐项条件 / 重组窗+4128 CRef 名义 / loc 键存在检查语义。
已结 1 项: EntryItem 另两实例 = CResearchFacilityItem (vtable 0X1429C5920, ctor sub_1414683C0) / CProjectSimpleItem / CProjectHistoryItem (§4.31.25 三实例全名)。
(理念组 def+20 ≡ group+8 ctor 同参双写定案 §4.10.12; ListItem 装备型 =
CEquipmentType 定案 §4.31.20。)

> **CFilterListItem = 上表「库存分类过滤钮」** (空军重组分类过滤行; vtable 0X142AB5100; NAirWingReorganizationUI::NInternal;
> 存档元素名 airwing_filter_item; 分类 id = interface_overview_category_index
(sub_140C95880 读装备型+320, 负则沿 +1240 archetype 父链上溯; 断言
"archetype … has no interface_overview_category_index"
airwingreorganizationview.cpp:0xEC; CEquipmentType+320 类别枚举与 §4.23 册行
互证; 装备型对象身份 = **CEquipmentType 定案** (字段 +320/+1000/+1240/+1344/+1365
与 §4.23 布局及 reader sub_140C99410 逐一对位 + 断言实名双证)。

| 偏移 | 类型 | 名称 | 备注 |
|---|---|---|---|
| +1240 | — | archetype 父链 | 分类 id 负值时沿链上溯 |
| +1328 | — | {archetype*, u32 count} 16B 元向量数据 | 本分类逐 archetype 存量明细 |
| +1340 | uint32 | 上述向量计数 | |
| +1352 | uint32 | Σ count | |

图标帧 = 分类 idx+1; 行源 populate sub_14202BAB0 (库存对数组 window+4056;
门 = 装备型掩码 &0x10036FC00 / &~0x100000 + 装备+1000 显示旗 — 掩码语义定案:
0x10036FC00 = 全机种 12 类位集, ~0x100000 剔除 air_transport, 合读 =
「飞机类装备且非运输机」); tooltip =
CREATE_AIRWING_VIEW_FILTER_DESC / _BREAKDOWN 逐 archetype 名×架数。

命令族: CDeployAirWingCommand (id 13091) / CSetAirWingNameCommand (id 14312)
— §4.00.6 命令册成员。

#### 4.31.21 散簇·科学家/顾问 (CScientistItem / CScientistList / CBranchUpgradeRepetitionIcon / ResearchedIcon / CAgencyLogoSelectionWindow / CAgencyUpgradesWindow / CIntelligenceAdvisorSlotItem / AdvisorSelectionItem / CResearchFinishedPopUpWindow)

业务侧: 科学家视图见 §4.4 (+ chars+160 定名 §4.3); 顾问槽见 §4.5; 机构

类布局 (类名 / target / 锚点):

| 类 | 字段/锚 | 消费/语义 |
|---|---|---|
| CScientistItem | target = item+40 → CScientist* | +32 = 宿主 CScientistList; +2968 = mode |
| CScientistItem | 消费字段 | sci+8 char / sci+48 traits / sci+304 assigned / sci+308 injured 四册锚 + char+40 名 + CPolitics+224 PP |
| CScientistItem | RECRUIT_SCIENTIST_COST | 递档数组消费点 (招聘费按已聘数递档) |
| CScientistList | 抽象基 (vtable[5/8/9/14] purecall) | 三亚类分流数据源 — roster → chars+160 (定名互证) / recruit → chars+224 池 |
| CScientistList | +2928 | 排序态 token (默认 357=none, 27=name); 13 元素绑定 |
| CSkillLevelItem | target = {CScientist*@+32 (skills@+264 同册), level@+40, spec tok@+44} | tooltip SCIENTIST_SKILL_LEVEL_TOOLTIP |

类布局 (类名 / target / 锚点):

| 类 | 项 | 语义 |
|---|---|---|
| CIntelligenceAdvisorSlotItem | target (+2776) | 槽组 idx (0 = spymaster) |
| CIntelligenceAdvisorSlotItem | 数据源 | fac+2104 CFactionUpgradeStatus slots 条目 {+0 advisor def, +8 owner tag} — writer 双键 (10454/10302) 与 GUI 直读闭环互证 |
| CIntelligenceAdvisorSlotItem | 解锁费 | FACTION_INTELLIGENCE_UNLOCK_COST define; loc FACTION_INTEL_* 8 键 |
| CIntelligenceAdvisorSelectionItem | 形态 | 无自有成员纯类型行 (基 CCountryCharacterSelectionItem); ctor = AppointAdvisors lambda_4 工厂 (_Func_impl vtable 槽直证); target = CCharacterStatus |

sub_1411867E0 = 任命资格校验器 (技能门槛 + 理由串输出; 与 cc+4080 roster
无代码关系)。

类布局 (类名 / target / 锚点):

| 项 | 值 |
|---|---|
| target | +4032 CTechnology* |
| 消费册锚 | tech+104 / tech+116 / tech+352 / tech+360 / tech+492 (五锚互证) |
| 自动关窗 | MESSAGE_TIMEOUT_DAYS define |
| 触发链 | sub_140EE3E70 → sub_140B66230 |
| ok/details 双钮 | 链定案; details → sub_1415F91E0 科技视图定位 |
升级窗见 §4.31.88; 研究弹窗见 §4.7。附带: 子视图 A/C 身份定案
(§4.11.10 行); CCountryCharacters+160
未名表定名 = 在聘科学家表。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 科学家行 | 宿主 CScientistList 派发 | item+40=CScientist\* / +32=宿主 / +2968=mode | sci+8/+48/+304/+308 四锚互证; RECRUIT_SCIENTIST_COST 递档 | — | 定案 |
| 科学家列表基 | 三亚类分流 | roster→chars+160 / recruit→chars+224 池; **+2928=排序态 token** (357=none/27=name) | vtable[5/8/9/14] purecall 抽象基 | — | 定案 |
| 升级重复/已研图标 | 宿主 CUpgradeEntry::Refresh 内联 | ResearchedIcon+32 序号/+40 def/+48 tag; **def+540=最大重复数**; 帧=idx+R(R+1)/2 | CUpgradeEntry 实名 0x1588B; tooltip sub_140623870 | — | 定案 |
| 徽标选窗 (=子视图 A) | reset sub_141A112C0 | ag+128 名 / ag+160 徽标 | 两命令 CSetIntelligenceAgencyName/LogoCommand; agencylogoselectionwindow.cpp 断言 | name_logo_agency_selection_window | 定案 |
| 升级窗 (=子视图 C) | reset sub_141A16230 | +72 分支/+80 factory/+104 grid; **ag+120=CCountry\* 回指** | AGENCY_UPGRADE_DAYS define; agencyupgradeswindow.cpp:0x1BE | intelligence_agency_upgrades_window | 定案 |
| 顾问槽行 | 填充 | +2776 槽组 idx; **fac+2104 slots 条目 {+0 def/+8 owner}** | FACTION_INTELLIGENCE_UNLOCK_COST define | FACTION_INTEL_* ×8 | 定案 |
| 研究完成弹窗 | 触发链 sub_140EE3E70→140B57100 | +4032=CTechnology\* | tech 五锚互证; MESSAGE_TIMEOUT_DAYS 自动关窗; details→sub_1415F91E0 定位 | — | 定案 |

未决: CUpgradeEntry::Refresh 公式
逐行 / tech+116 语义等。

**CScientistList::Setup = 0x141C20FF0** (431 行, NProject::NUi::Setup(CScientistList*, bool), scientist_list.cpp:135 断言 `Window already created.`; 特设项目 UI 域, special_projects\ui\): 根窗 = *(qword_14332F698+1272) 窗口管理器 vtable[12] 创建 (23 字符 .gui 模板名, 数据常量未证); vtable[11] = CFG 空桩 0x14012A2C0 实例 (基类无实现钩子, Setup 尾 a2=false 时调用)。元素绑定表:

| 偏移 | 类型 | 元素/语义 |
|---|---|---|
| +40 | 窗口指针 | 根窗 |
| +48 | 订阅槽 | close_button 回调 |
| +1416 | 订阅槽 | sort_name 按钮回调 (SSortButtonFunction 32B = {spec id u32, &宿主+2928, this, cmp sub_141C208D0}) |
| +2784 | 元素指针 | sort_name_arrow 图标 |
| +2792 | 元素指针 | scientist_text_search 搜索框 |
| +2800 | CTextBufferObserverGlue | 订阅到搜索框 +128 文本缓冲 vt[1] |
| +2888 | 元素指针 | scientist_list_container |
| +2896 | CPdxArray (32) | 行适配容器 {data@+8, alloc vptr@+16, cap@+20, count@+24}; 换值先销毁旧值 (逐行 deleting dtor) |
| +2904 | 元素指针 | instructions_text |
| +2912 | 元素指针 | title_text |
| +2920 | 元素指针 | sort_specialization_box (listbox) |
| +2928 | uint32 | 排序态 token — **双语义: 27 = 按名, 否则 = specialization 库条目 id** |
| +2932 | byte | 排序方向旗 (箭头帧值 2/8 互换) |

**CSpecializationSortItem** (1416B, RTTI 直证; ctor sub_141C1F310): +8 窗基子对象 (模板 "specialization_sort_entry") / +32 specialization 库条目 / +40 specialization_icon 按钮回调 / +48 图标件 (gfx 串 = sub_140ABAD20(库条目, out, gs+1312) — 国别参数进图标名) / +1408 sort_arrow。**specialization 库 (qword_14332F068) 两副面孔 (定案)**: 平表 {data@+96, cap@+104, count@+108} (元素 +8 = id) + RH 表 {桶基@+72, 桶距 56, mask@+84, extra@+88} (桶 = {哈希 u32@0, dist u8@4, 键 id u32@8, 值指针@16}; u32 键 ×0x45D9F3B 双轮雪崩)。排序处理器 sub_141C208D0 = 按 +2928 分支刷 sort_name_arrow → 遍历 sort_specialization_box (+416 条目数组/计数@+428) 逐条目刷 +1408 → listbox 刷新 sub_1422C7E50 + 主列表重排 sub_141C1FC90。

#### 4.31.22 散簇·子单位/战术/技能 (CSubFiltersWidget×4 / CSubMessageView / CSubUnitDefinitionEntry / SubUnitInfoEntry / SubUnitSimpleEntry / CTacticsListEntry / CTacticsListView×3 / CSelectArmyLeaderPreferredTacticsEntry / CSelectCountryPreferredTacticsEntry / CSelectTechTreeIconOrigin / CSkillLevelItem / CSkillTreeBaseItem / CSpecializationItem / CSpecializationSortItem)

业务侧: 战术簇见 §4.22 (CCombatTactic 8 偏移定案); 子单位条目见 §4.18;
科技树图标效果见 §4.7; 杂项四件见 §4.3; CSkillLevelItem 见 §4.4
(同簇并录)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 战术行 | SetTarget 0X141C70760 | entry+32=CCombatTactic\*; tactic+112 图标/+312..352 f64 六值/+360+364 阶段/+368+369 双门 | CCombatTactic 布局本册首发 | — | 定案 |
| 战术列表 ×3 | SetCombat 0X141C70F60 | combat+40/+48 att/def ✓册; **combat+208=阶段新定案**; 池化 9 成员 | 撞偏移复核: 0X1415CE480/0X1415CEFB0 属本族非 CLandCombatView | — | 定案 |
| 首选战术 (将领/国) | 可用判定 | skill+440≥PREFERRED_TACTIC_CHARACTER_SKILL_LEVEL_REQUIRED / cc+496 CP ≥ 100000×(modifiers[#589]+PREFERRED_TACTIC_COMMAND_POWER_COST) | 双 define 锚 + 双册锚 | — | 定案 |
| 舰艇编成格 | 宿主直写 | entry+1376=def; def+104 图标/def+1448&0x201 排除 | — | — | 定案 |
| 陆军子单位格 | tooltip | {def id@+32, count@+36}; **def+1448&0x80000=铁路炮分支** | — | — | 定案 |
| 单位统计格 | 三册锚命中 | {双 u16@+32, D 对象@+40, 模式@+48}; D+436/+264、cc+3944 | def+816..976 五统计组新发现 | — | 高置信 |
| 专精项/排序钮 | cc+4008 解析 | spec id@+112 / def@+32; **def+8=spec id 新定案** | facility 链 +2912→{+2944,+2956} 高置信 | SCIENTIST_ROSTER_SORT_BUTTON_TOOLTIP | 定案 |

未决 9 项。

#### 4.31.23 散簇·修正条目族 (CDynamicModifierItem / BigItem / SmallItem / CModifierEntry / CModifierGridEntry / CModifierIconEntry)

业务侧: 动态修正簇+def 布局见 §4.13; 特种部队九格 9 键定名见 §4.3; 天气/

类布局 (战斗修正图标条; 17 slot loc 全表):


CLandCombatView 战斗修正图标条: target = {view ptr@+48, **slot idx 0-16@+32**, 侧旗@+56}; 图标 SetFrame(slot+1) (反汇编定案)。

17 slot → loc key 全表 (定案):

| slot | loc key | 备注 |
|---|---|---|
| 0 | BM_ENCIRCLEMENT_PENALTY |  |
| 1 | BM_DUGIN_MODIFIER |  |
| 2 | BM_RIVER_PENALTY |  |
| 3 | BM_MULTIPLE |  |
| 4 | BM_TERRAIN |  |
| 5 | BM_AMPH_PENALTY |  |
| 6 | BM_SUPPLY |  |
| 7 | BM_PARADROP |  |
| 8 | GOOD_ARMOR_DEFENSE_DESC |  |
| 9 | GOOD_ARMOR_ATTACK_DESC_STR/ORG |  |
| 10 | PIERCING_GOOD_DESC |  |
| 11 | PIERCING_GOOD_DESC |  |
| 12 | DIFFERENT_COMMANDER_DESC | sub_1415D0B60 |
| 13 | BM_ENEMY_AIR_SUPERIORITY_COUNTER_DESC |  |
| 14 | COMBAT_EXILES_DESC (+_DELAYED) | view+1472 = 数量 / +1476 = 总数 (流亡师计数新锚); ATK/DEF_VS_OCCUPIER = qword_143336250 / qword_143336310 双 define |
| 15 | COMBAT_EXILES_ON_CORES_DESC | ATK/DEF_ON_CORE = qword_143336408 / qword_1433364D8 |
| 16 | LACK_OF_FUEL (+_DESC) | 战斗 ref view+1336 → sub_140C7F0A0 油比<100000 门 |

战斗对象+368 = 活动修正类型表 (8 类型枚举) — 新发现。

**战斗修正条目第二 tooltip 族** (sub_1415D2FE0, slot 0-9):

| slot | loc key | 要点 |
|---|---|---|
| 0 | BM_FORT_MODIFIER (+_DESC) | 特性门 → BM_FORT_MODIFIER_DESC_WITH_RAILWAY_GUN 铁路炮变体 |
| 1 | BM_ENEMY_AIR_SUPERIORITY | |
| 2 | BM_AIR_SUPPORT | |
| 3 | BM_SHORE_BOMBARD | |
| 4 | BM_RAILWAY_GUN_BOMBARD | |
| 5 | BM_STACKING | |
| 6 | BM_MULTIPLE_DIRECTIONS | |
| 7 | BM_DECRYPTION | |
| 8 | BORDER_CONFLICT 明细 | CLandBorderWarCombatant: +1272 修正 → BORDER_CONFLICT_MODIFIER; +1384 地形因子 / +1376 挖壕因子, **各在 ==100000 时跳过**, <100000 时配色码 72 否则 82 |
| 9 | BM_ACTIVE_CODE_CRACKING_BONUSES | |
| default | assert「Invalid enum」:1158 | B51 门, latch byte_14338A99F |

> slot 0-7/9 经 sub_1415D10A0 族装配; slot 8 与 §4.22.2 边境战 combatant +1272/+1376/+1384 三偏移互证 (一致)。第一族 default = assert「Invalid assert」:934 (latch byte_14338A99E); 第一族 slot 0-7 的修正 idpair 由 view+1336 (a1+24 → +1336) 经 sub_14221F310 解析 (16 = 无效)。


类布局 (网格条目 target / 宿主):

CModifierGridEntry target:


CModifierGridEntry target:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | SSO 串 | 名 loc 键 ("<名>_name") |
| +64 | SSO 串 | 图标 |
| +96 | 匿名结构 (NNB 形状) | 修正宿主 (obj+16 = CModifier) |

宿主 = 海军区域修正 + 天气六格 populate (CWeatherManager = gs+1672); 区域
对象+312 = 修正源容器 80B 行; 天气单例 6 行指针。
海军区域修正网格见 §4.16; 战斗修正图标条 17 slot 全表见 §4.22。族形态:
6 类 19 槽主表仅 [0] dtor 覆写, 无虚拟 SetTarget — target 全靠 ctor/池厂
直写 + 非虚刷新 (与政治理念条目族同构)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 动态修正行 (大/小) | SetTarget sub_141C471B0 | item+32=内嵌 SDynamicModifierEntry 64B (6/6 命中 §4.13) | CCountry+3712 容器迭代 (+3672 ✓); tooltip 双发射器 sub_14055D670+14054CCB0 | def+40 名+"_desc"; WILL_BE_REMOVED | 定案 |
| 特种部队九格 | populate sub_14170FA20 | item+32=CModifier\*(cc+1448 ✓)/+40=mdef idx | **9 键定名** (367 SF_CAP/187 ATK/188 DEF/381 TRAINING/383 OUT_OF_SUPPLY/608-611 四兵种贡献) | "GFX_"+名 / 名+"_DESC" | 定案 |
| 天气/区域修正格 | populate | +32 名键/+64 图标/+96 宿主 obj (obj+16=CModifier) | CWeatherManager=gs+1672 ✓; 区域对象+312 修正源容器 80B 行新发现 | — | 定案 |
| 战斗修正图标条 | SetFrame(slot+1) | {view@+48, slot 0-16@+32, 侧旗@+56} | **17 slot→loc key 全表** (BM_* 族/GOOD_ARMOR/PIERCING/EXILES/LACK_OF_FUEL); 战斗对象+368 活动修正类型表新发现 | COMBAT_EXILES_DESC 等 | 定案 |

未决 8 项: 两宿主视图精名 / item+96 恒 0 字段 / def+24 门语义 /
mdef 表双指针等。

#### 4.31.24 散簇·活动条 (CActiveAbilityItem / CActiveContractsUiController / CActiveExpeditionariesStripView / CActiveFactionStripView / CActiveRaidMapIconData / CActiveVolunteersStripView / CActiveWargoalStripView)

业务侧: 活动能力+CAbility 本体布局见 §4.3 (+借调双条); 关系条簇见 §4.10;
活跃合同控制器见 §4.23; 师+480 GUI 注见 §4.18。族级结论: 四 strip 全走
CRelationStripViewBase 骨架 (仅覆写 [19]/[20]/[21], [22] 全留基桩); loc 键
= `<token>_<侧>_extended_desc`/`_desc` 动态拼接 (13729/13730/10877/11490
直证)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 活动能力行 | 宿主 unit counter 注入 | item+48=CAbility\* (池@counter+280); cc+5560 88B 条目按+16==将领收集 | **CAbility 本体定案** (vtable 0x1429852f8; +112 id 串/+584/+616/+680 图标块); 条目+72 隐藏门新锚 | — | 定案 |
| 借调双条 (远征/志愿) | 存在谓词 | +56=本国 tag; cc+760/cc+784 → idreg → 元对象+480==目标国 tag | 师+480=借调东道国 tag UI 消费证 (§4.18 互证) | 13729/13730_<侧>_desc 族 | 定案 |
| 阵营条 | [20] 覆写 0X141CAB180 | dip+656 双边 CFaction\* 相等 | faction_general_desc + members[0] 领袖行 | 10877 族 | 定案 |
| 战争目标条 | 逐 wargoal sub_1415DECF0 | dip+104 available_wargoals; wg+60==对方 ∨ dip+368 contains | dip+368 附属覆盖第四票 (dual 定案互证) | 11490 族 | 定案 |
| 活跃合同行 | 类别分组器 sub_140FCC870 | mkt by_buyer+72/by_seller+48 双路 | CPurchaseContractEntry 窗 active_purchase_contract_entry; 取消 → CCancelEquipmentPurchaseAction | — | 定案 |
| 空袭地图图标数据 | SetRaid sub_141E87920 | +2784=CRaidInstance\*; raid+56/+60/+152/+160/+200 五锚 | 变体基族四兄弟 icon+152/3040/5888/8688; 结束自动派 CRemoveRaidCommand | — | 定案 |

未决 8 项。

#### 4.31.25 CFilterEntryItem\<T\> 项目专精过滤

| 项 | 值 |
|---|---|
| 模板 | CFilterEntryItem\<T\> (NProject::NUi 模板 ×3) |
| 实例 T | CResearchFacilityItem (vtable 0x1429c5920, ctor sub_1414683C0) / CProjectSimpleItem / CProjectHistoryItem (三实例 dtor/tooltip ICF 折叠同址) |
| 元素 | project_list_filter_entry |
| 图标回退 | GFX_PLACEHOLDER_sp_specialization_icon |
| tooltip | FILTER_ON_SPECIALIZATION_TOOLTIP (参数 PROJECT_COUNT) |

元素字段:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | def* | 过滤器描述符 = CSpecializationTemplate 族 {+8 = LexerToken, +16 = 图标基名串} (populate sub_141471C40 逐 token 查 TGameItemDatabase qword_14332F068 56B 哈希; lambda 签名直证) |
| +1408 | — | "project_count" 元素 |
| +1416..+1448 | — | {window*, on-select, on-deselect, 未用 fn, count fn} 五件套 (a3..a7 注入) |

#### 4.31.26 GUI 杂项 (子过滤器 / 订阅滚动条 / 技能树 / 专精项)

| 类 | 实例/定位 | 语义/消费点 |
|---|---|---|
| CSubFiltersWidget ×4 | 模板 4 实例 equip/inf/tank/plane | target = 宿主视图类别索引; tooltip 消费宿主 +404 数量 / +488 选中 (两新锚); **主宿主定案 = NInternationalMarket::CPurchasableEquipmentWindow** (Setup sub_141FFFD40 = vtable 0x142AAC558 slot[11]; 四实例 equipment_category_filters_widget (ctor sub_141FF71D0) / infantry_ (sub_141FF7B50) / plane_ (sub_141FF83C0) / tank_ (sub_141FF98C0) 全在该窗内; 同族 Setup 亦被 CMarketStockpileWindow (sub_14200CFC0) 与 CAddEquipmentToMarketWindow (sub_14205A8F0) 复用)。equip 实例确切类名 = **CEquipmentCategoryFiltersWidget** (CTooltipHandler→CUiWidget→CSubFiltersWidget<CEquipmentCategoryFilter,EEquipmentFilterCategory> 基链); ctor 尾注册 4 过滤钮: {infantry_button / armor_button / air_button / naval_button × loc INTERNATIONAL_MARKET_EQUIPMENT_FILTER_{INFANTRY,ARMOR,AIR,NAVAL} × script value available_{infantry,armor,air,naval}_equipment × 数量变量 inf_art/armor/air/naval_amount} (注册原语 sub_141FFBBF0) — script value 耦合为显示侧读点 |
| CSubMessageView | 主菜单订阅滚动条 | target = ctor 配置结构 (5 串 + 速度); Update 驱动 "scrolling_content" 7 格滚动; 成员布局 ctor 全直读 |
| CSkillTreeBaseItem | 抽象基 (4 purecall 槽) | 基布局 +16/+24/+32; 派生 CUnitLeaderTraitTreeItem / MIO CTraitTreeItem 实证 |
| CSpecializationItem | 设施专精项 | target = spec id@+112; 经 cc+4008 program_status 解析; facility 链 +2912 → {+2944, +2956} 项目表 (高置信) |
| CSpecializationSortItem | 科学家名册排序钮 | target = CSpecialization def*@+32 (哈希库查); def+8 = spec id (定案); loc SCIENTIST_ROSTER_SORT_BUTTON_TOOLTIP |


#### 4.31.27 师详情窗 (CArmyDivisionView / CArmyDivisionStatsView / CArmyDivisionViewLandCombatEntry) 

业务侧类布局见下 (target 形态 / 三栏 24 行 statId 映射 / 78 项枚举表 / 聚合核); 师统计对象行 = §4.18.1 +312。视图侧要点: CArmyDivisionView 仅 2 槽vtable (行为全在 glue 回调+消息处理器 sub_1416B6110); CArmyDivisionStatsView 基链六员 (CReloadableInterface+CInGameUpdateableInterface+CUpdateable+CTemplateChanger+CTooltipHandler), 帧更新 = CUpdateable[2] → 六段 → 按 +8312 分页; **行写入器在 value 子件 +8 打 statId 标签**, BuildTooltip (CTooltipHandler[0] sub_1416A2270) 据此路由 (<78 门) — 统计行 tooltip 的通用范式。

类布局 (类名 / target / 锚点):

UNIT DETAILS 面板的视图族。CArmyDivisionView = 师条目/选中面板（2 槽vtable，行为全在 glue 回调与消息处理）；CArmyDivisionStatsView = 三栏统计窗本体（窗名 army_division_stats_view，sizeof 8384）；三栏统计行除 max_speed/combat_width/attrition/manpower 四行活算外全部读 §4.18.1 +312 师统计对象的缓存数组。

| 类 | target 形态 | 入口链 |
|---|---|---|
| CArmyDivisionView (vtable 0x1429e9fd0, 仅 dtor 2 槽) | refid 对 @view+260/+264 (消息处理器 sub_1416B6110 写入; D 对象 = sub_14221F310(refid)−16) | glue 主表 vtable@+312 (CLegacyButtonObserverGlue, 回调表 +320..+1600) + CButtonEventDispatcher ×5 (@+1600/+2888/+4176/+5464); 子面板刷新 sub_1416B89C0 (fuel 三态 = *(D+1568)/统计[16] 百分比; 陆战条目池 @view+280/{cap+288, count+292}, 来源容器 sub_140BFBFF0(D) = {items@+0, count@+12}); 开 UNIT DETAILS 回调 sub_1416AA900 (find-or-create StatsView, +8312=2 页/+8376=2 模式) |
| CArmyDivisionStatsView (vtable 0x1429ea2e0 族; 基链 CReloadableInterface+CInGameUpdateableInterface+CUpdateable+CTemplateChanger+CTooltipHandler) | **unit refid 对 @+1664** (ctor sub_141693EB0 直写, 定案) | Reload 主[2] sub_1416ADD60 与 ctor 双调 Setup **sub_1416B1C00** (控件缓存槽表见下); 帧更新 CUpdateable[2] sub_1416AD770 (**this = 本体+64 基视口** — 其 +8312 ≡ 本体 **+8376 分页 dword**, 与 §4.30.5 页切换行同址; 本体坐标勿按 +8312 记) → 六段 (含统计+装备段 **sub_1416BF6C0**) → 按本体 +8376 分页; **BuildTooltip = CTooltipHandler[0] sub_1416A2270** (widget a2[2]=statId 标签路由, <78 门) |
| CArmyDivisionViewLandCombatEntry (vtable 0x1429ea050, 构件 unit_land_combat_entry, 0x538B) | **战斗对象指针 @entry+1320 + refid 对 @+1328** (ctor sub_141695650) | populate sub_1416B9AD0: 进度条 = combat vtable[25] fixed5→%; 图标帧 = war refid 匹配 (combat+40→+56 vs gs+1312/1316); 点击 sub_1416A9C30 → sub_1415D9A20 (开战斗视图, 推定) |

Setup 控件缓存槽表 (Setup sub_1416B1C00 按名抓取直写; 断言 armiesview.cpp:6725 "Setting up without a unit"; 定案):

| 槽 | 控件 | 抓取途径 / 备注 |
|---|---|---|
| +6840 | commanding_officer | 根(+136) vtable+120 抓取; 值域 = CArmy+824 CHeldOfficer 链; promote_officer 回调绑同槽族 |
| +8128 | portraittime | 根 vtable+104 |
| +8136 | promote_officer | 根 vtable+104 |
| +8208 | 小窗对象 1 | sub_141498500 (0x1B8 元, 数据源 +1272 弹窗容器) |
| +8216 | 小窗对象 2 | 同上; 输入含 CArmy u32 槽 — 待裁, 见 §4.18 |
| +8224 | 小窗对象 3 | 同上 |
| +8232 | adjuster_container | 根 vtable+440 |
| +8240 | adjuster_stats | +8232 容器 vtable+440 |
| +8256 | stats_grid | +8240 容器 vtable+432 |
| +8272 | obsolete_template_warning | 根 vtable+136 (尾段重建) |
| +8280 | 勋章/史页页容器 | 根 vtable+440 |
| +8288 | history_entry_container | +8280 容器 vtable+440 |
| +8296 | history_entry_grid | +8288 容器 vtable+304 |
| +8304 | medal_instance_container | +8280 容器 vtable+440 |
| +8312 | medals_grid | +8304 容器 vtable+432; 初始可见性 = 控件 +165 字节 & 8 |

tab/列表绑定: stats/template/history 三 tab_button 的 +128 子对象统一绑 +1680 回调对象; divisions 列表 (根 vtable+160 → sub_142302CC0 包装) 绑 +2968; division_name_dropdown 绑 sub_141CF7FD0(+144 状态域)。单位域消费: +1584 leader 旗 → og 头像链; 模板 priority@396 → unitlist_priority_icon (互证); CArmy+1644 history count = 0 门 history_tab_button 禁用位 (控件 +117 \|= 0x10)。

**三栏统计行映射** (populate sub_1416BF6C0; 每栏 FindWindow info→<栏>_stats→stats_grid → 清 grid → 行写入器建行): 行写入器 sub_141BE9DC0(view, value_fixed5, grid, statId) — label = sub_1413E6570(statId) loc key, **value 子件 +8 dword = statId (tooltip 路由标签)**, 值文本 = sub_1413E6800(statId, value) (key+"_VALUE"); 变体 sub_141BE9DC0 = 标签/值预格式化 (reliability/combat_width/attrition 三行, tag 79/80 = tooltip 路由伪 id 不进枚举表)。「缓存+N」= 师统计对象+160+8×statId (fixed5 i64):

| 面板行 | statId | 取值 | loc key |
|---|---|---|---|
| max_speed (Base) | 62 | **活算** sub_140C875B0(D): raw = sub_140C7F140(D,…), 结果 = 100000×raw/LAND_SPEED_MODIFIER (qword_143336258, defines 直证); 内部地形/修正权重链 (sub_140C7F140) 细节未决 | STAT_COMMON_MAXIMUM_SPEED |
| hp / max_strength (Base) | 61 | 缓存+648 | STAT_COMMON_MAX_STRENGTH |
| organization (Base) | 60 | 缓存+640 | STAT_COMMON_MAX_ORG |
| default_morale (Base) | 0 | 缓存+160 | STAT_ARMY_DEFAULT_MORALE |
| recon (Base) | 6 | 缓存+208 | STAT_ARMY_RECON |
| supply_use (Base) | 11 | 缓存+248 | STAT_ARMY_SUPPLY_CONSUMPTION |
| reliability (Base) | 65 | 缓存+680 (sub_141BE9DC0 特行) | STAT_COMMON_RELIABILITY |
| reliability_factor (Base) | 66 | 缓存+688 | STAT_COMMON_RELIABILITY_FACTOR |
| casualty_trickleback (Base) | 9 | 缓存+232 | STAT_ARMY_CASUALTY_TRICKLEBACK |
| experience_loss (Base) | 14 | 缓存+272 | STAT_ARMY_EXPERIENCE_LOSS_FACTOR |
| soft_attack (Combat) | 4 | 缓存+192 | STAT_ARMY_SOFT_ATTACK |
| hard_attack (Combat) | 5 | 缓存+200 | STAT_ARMY_HARD_ATTACK |
| air_attack (Combat) | 48 | 缓存+544 | STAT_AIR_ATTACK |
| defense (Combat) | 1 | 缓存+168 | STAT_ARMY_DEFENSE |
| breakthrough (Combat) | 2 | 缓存+176 | STAT_ARMY_BREAKTHROUGH |
| armor (Combat) | 63 | 缓存+664 | STAT_COMMON_ARMOR |
| piercing (Combat) | 64 | 缓存+672 | STAT_COMMON_PIERCING |
| initiative (Combat) | 8 | 缓存+224 | STAT_ARMY_INITIATIVE |
| entrenchment (Combat) | 7 | 缓存+216 | STAT_ARMY_ENTRENCHMENT |
| equipment_capture (Combat) | 15 | 缓存+280 | STAT_ARMY_EQUIPMENT_CAPTURE_FACTOR |
| combat_width (Combat) | tag 79 | **活算** CArmy vtable[46] sub_140C7D9B0(D) (§4.18.1 既有锚) | "COMBAT_WIDTH" |
| attrition (Misc) | tag 80 | **活算** sub_140C75500(D, &out, 0, 1) (公式未展开) | "ATTRITION" |
| weight (Misc) | 67 | 缓存+696 | STAT_COMMON_WEIGHT |
| fuel_capacity (Misc) | 16 | 缓存+288 (sub_140C7F070(D) null 门包装) | STAT_ARMY_FUEL_CAPACITY |
| fuel_usage (Misc) | 69 | 缓存+712 (CArmy vtable[57] sub_140BFBFB0(D)) | STAT_COMMON_FUEL_CONSUMPTION |

同函数非栏行: experience 文本 = UNIT_VIEW_ARMY_EXPERIENCE; unit_level = sub_140C7E890(D)+1; softness 进度条 = 100×缓存+184 (statId 3 HARDNESS); manpower 行当前值 = sub_140C87F70(D) (clamp 100000×*(D+1096)/vtable[33] 经 define qword_143331410 与 sub_140C69780(D+976) 修正) / 容量 = *(u32*)(sub_140C7E7C0(D)+376) (模板数据 CDivisionTemplateData+376); 装备段 equipment_ratio = 100000×have/need (have/need 自 sub_141012890(**模板数据+264** 装备池 — 非 D+264))。

**statId 枚举表 (off_1430B33F0, 恰 78 项, 表后 0x10101010 填充; 全局共享 — 海军/空军/铁路炮/通用统计同一编号空间)**; 配套 helper 族 (0X1413E4380..0X1413E6F80 共 10 函数): sub_1413E6570=loc key / sub_1413E6450=key+"_DIFF" / sub_1413E6800=key+"_VALUE" / sub_1413E5AC0=label / sub_1413E5BD0=tooltip 文本:

| id | loc key | id | loc key | id | loc key |
|---|---|---|---|---|---|
| 0 | STAT_ARMY_DEFAULT_MORALE | 27 | STAT_NAVY_HG_ATTACK | 54 | STAT_AIR_GROUND_ATTACK |
| 1 | STAT_ARMY_DEFENSE | 28 | STAT_NAVY_HG_ARMOR_PIERCING | 55 | STAT_AIR_VISIBILITY_FACTOR |
| 2 | STAT_ARMY_BREAKTHROUGH | 29 | STAT_NAVY_TORPEDO_ATTACK | 56 | STAT_RAILWAY_GUN_ATTACK |
| 3 | STAT_ARMY_HARDNESS | 30 | STAT_NAVY_SUB_ATTACK | 57 | STAT_RAILWAY_GUN_ATTACK_RANGE |
| 4 | STAT_ARMY_SOFT_ATTACK | 31 | STAT_NAVY_ANTI_AIR_ATTACK | 58 | STAT_RAILWAY_GUN_ANNEX_RATIO |
| 5 | STAT_ARMY_HARD_ATTACK | 32 | STAT_NAVY_AMPHIBIOUS_DEFENSE | 59 | STAT_RAILWAY_GUN_HOURS_TO_REDISTRIBUTE |
| 6 | STAT_ARMY_RECON | 33 | STAT_NAVY_MAXIMUM_SPEED | 60 | STAT_COMMON_MAX_ORG |
| 7 | STAT_ARMY_ENTRENCHMENT | 34 | STAT_NAVY_RANGE | 61 | STAT_COMMON_MAX_STRENGTH |
| 8 | STAT_ARMY_INITIATIVE | 35 | STAT_NAVY_MINES_PLANTING | 62 | STAT_COMMON_MAXIMUM_SPEED |
| 9 | STAT_ARMY_CASUALTY_TRICKLEBACK | 36 | STAT_NAVY_MINES_SWEEPING | 63 | STAT_COMMON_ARMOR |
| 10 | STAT_ARMY_SUPPLY_CONSUMPTION_FACTOR | 37 | STAT_NAVY_LIGHT_GUN_HIT_CHANCE | 64 | STAT_COMMON_PIERCING |
| 11 | STAT_ARMY_SUPPLY_CONSUMPTION | 38 | STAT_NAVY_HEAVY_GUN_HIT_CHANCE | 65 | STAT_COMMON_RELIABILITY |
| 12 | STAT_ARMY_SUPRESSION | 39 | STAT_NAVY_TORPEDO_HIT_CHANCE | 66 | STAT_COMMON_RELIABILITY_FACTOR |
| 13 | STAT_ARMY_SUPRESSION_FACTOR | 40 | STAT_NAVY_TORPEDO_DAMAGE_REDUCTION | 67 | STAT_COMMON_WEIGHT |
| 14 | STAT_ARMY_EXPERIENCE_LOSS_FACTOR | 41 | STAT_NAVY_TORPEDO_ENEMY_CRIT_CHANCE | 68 | STAT_COMMON_THRUST |
| 15 | STAT_ARMY_EQUIPMENT_CAPTURE_FACTOR | 42 | STAT_NAVY_WEATHER_PENALTY | 69 | STAT_COMMON_FUEL_CONSUMPTION |
| 16 | STAT_ARMY_FUEL_CAPACITY | 43 | STAT_NAVY_RAIDING_COORDINATION | 70 | STAT_COMMON_FUEL_CONSUMPTION_FACTOR |
| 17 | STAT_ARMY_RECOVERY | 44 | STAT_NAVY_PATROL_COORDINATION | 71 | STAT_STRATEGIC_ATTACK |
| 18 | STAT_ARMY_ADDITIONAL_COLLATERAL_DAMAGE | 45 | STAT_NAVY_SEARCH_AND_DESTROY_COORDINATION | 72 | STAT_CARRIER_SIZE |
| 19 | STAT_NAVY_SURFACE_DETECTION | 46 | STAT_AIR_RANGE | 73 | STAT_SUB_CARRIER_SIZE |
| 20 | STAT_NAVY_SUB_DETECTION | 47 | STAT_AIR_DEFENCE | 74 | STAT_COMMON_ACCLIMATIZATION_HOT_GAIN |
| 21 | STAT_NAVY_SURFACE_VISIBILITY | 48 | STAT_AIR_ATTACK | 75 | STAT_COMMON_ACCLIMATIZATION_COLD_GAIN |
| 22 | STAT_NAVY_SUB_VISIBILITY | 49 | STAT_AIR_AGILITY | 76 | STAT_COMMON_NIGHT_PENALTY |
| 23 | STAT_NAVY_CARRIER_SUB_DETECTION | 50 | STAT_AIR_BOMBING | 77 | STAT_COMMON_BUILD_COST_IC |
| 24 | STAT_NAVY_CARRIER_SURFACE_DETECTION | 51 | STAT_AIR_SUPERIORITY | | |
| 25 | STAT_NAVY_LG_ATTACK | 52 | STAT_AIR_NAVAL_STRIKE_ATTACK | | |
| 26 | STAT_NAVY_LG_ARMOR_PIERCING | 53 | STAT_AIR_NAVAL_STRIKE_TARGETTING | | |

**聚合 (写入侧)**: 入口 = **CArmy::CalculateActiveUnitStats sub_140C8D600** (army.cpp:1760 调试实名, 定案) — 以当前模板数据 (*(D+960) 或 *(D+952) 取 +24) 为底, 经 sub_140C7F0A0(D) 装备齐备率 + sub_140C69780(D+976) 人力因子调**聚合核 sub_140B9AD70** (遍历模板 sub-units × 装备原型套修正链), 随后 0..77 逐 statId 后处理 sub_140C6F960(&ctx, D, statId, statsObj, 0) 套装备修正 (subunitdefinition.h:136 "_EquipmentModifiers[i]" 调试串实证) 落缓存数组; 副产物 D+1128 = 聚合核首值 / D+1184 = vtable[39] 结果。**设计师预览 sub_14168B9E0 (divisiontemplatemanager.cpp:1269 同名) 共用同一聚合核** — 运行时/设计器同核定案。缓存对象清零 = sub_140B63730。recovery(17)/suppression(12/13) 等 statId 在本窗不出现 — 行集合以上表为准, 无隐藏行。

**CArmyHistoryEntryItem (军史行壳, GUI 族)**: 槽[13] GetMedalStore 返 **CUnitHistory** (= CUnit 视口 +1576 ≡ CArmy+1592 块基) ✓ — 指令层真路径 = `resolve(item+1448)+1576`, 空 ref 路径返回常量 1592 = **同字段的空 ref 哨兵** (= 偏移+16), 非第二个字段 / 槽[14] = **CMedalTemplateItem 工厂** (§4.18.8 互证) / 槽[15] 固定 loc ASSIGN_COMMANDER_MEDAL_TOOLTIP; target = **CUnitHistoryEntry\*@item+40**; medal 图标 = **entry+104 def** ✓; 宿主 = CArmyDivisionView 历史页 sub_1416BEE50 ✓ (§4.31.27 互证)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 师条目面板 | 消息处理器 sub_1416B6110 | refid 对 @view+260/+264 | glue 主表@+312 + dispatcher×5; 开窗回调 sub_1416AA900 | — | 定案 |
| 三栏统计 | populate sub_1416BF6C0 | StatsView+1664 refid; 缓存 = §4.18.1 +312 对象+160+8×statId | 20/24 行读缓存; max_speed/combat_width/attrition/manpower 四行活算 | STAT_* 78 项 (§4.31.27) | 定案 |
| 统计行 tooltip | sub_1416A2270 | widget a2[2]=statId 标签 (行写入器打入) | statId 62 速度走 "_AIR_DESC" 特判; 其余 sub_1413E5BD0 族 | STAT_*_VALUE/_DIFF | 定案 |
| 陆战条目 | populate sub_1416B9AD0 | entry+1320 战斗对象/+1328 refid; 源 = sub_140BFBFF0(D) {items@+0, count@+12} | 进度 = combat vtable[25]; 帧 = war refid 匹配 | unit_land_combat_entry | 定案 |
| 模板页格子 | ctor sub_141695DC0 | 构件名按 +48 二选一 (0=subunit/1=support/2=第三格) support/subunit entry; **+32 双 u16 格坐标 / +40 = CDivisionTemplateData\* (sub_140C7E7C0(D)) / +48 = 页模式 — 填充点定案 = 宿主重建 sub_141699E50 池取 (a1+8344 池数组/a1+8356 池顶) 或 malloc(0x38) 新建后直写** | = StatsView 模板页 regiments_grid/support_grid 格 | unit_stats_view_*_entry | 定案 |

未决 5 项: max_speed/attrition 公式细节 / StatsView 分页槽 13/14 与 CUpdateable[1] / CSubUnitSimpleEntry +40/+48 填充点 / Reload 尾链 sub_1416B3E00 / sub_1416BE4F0 军官段。

#### 4.31.28 空袭行件 (CRaidEquipmentCollectionItem / CRaidEquipmentItem / CRaidSimpleTextItem / CRaidSourceItem / CRaidUnitItem / CRaidTargetMapIconEntry)

业务侧: CRaidCategory+2600/+2624 双需求 map / raid+160 目标访问器 / raid+200 双 id 对 / raid_source 64B 扩展拷贝 — 均见 §4.23 CRaidInstance 表。**族级结论: 行件均无直接 CCommand 出口** — 点击全路由 CRaidGuiManager 状态机 (mgr+72 step; SelectSource 0X14129B1C0 / SelectUnit 0X14129B670, mgr+128 写 16B 引用) 或 CGameGui vtable+440 地图 ping。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 部署总览「突袭」瓦片 | vtable[22..24] | 无数据载荷 (def deploy_entry) | 部署总览第 6 片类别瓦片 | RAIDS / DEPLOYMENT_RAIDS_DESC/_EMPTY; GFX_deploy_raids_icon | 定案 |
| 装备需求行 | populate | item+48=CRaidInstance\*/+56=CEquipmentType\* (0=nukes 行); 元素 name/current_amount/required_amount @+24/+32/+40 | current = raid+272 池查找 / nukes = raid+336; **required = CRaidCategory(raid+152)+2600/+2624 双 map** | raid_equipment_item | 定案 |
| 通用文本选项行 | SetupAutoLaunchOptions | text @+1392; 档位载荷 @+1400/+1404 门; 双 std::function @+1408/+1472 | = CRaidInstanceView::SetupAutoLaunchOptions 每档一行 | raid_simple_text_item | 定案 |
| 来源行 | vtable[8] Update 0X141B397D0 | **内联 CRaidSource 64B** (前 56B 与 raid+216 同体, +56=距离 fixed) | 填 name + distance; 点击 → SelectSource / ping | raid_source_list_item_name / raid_source_distance_to_target | 定案 |
| 参与单位行 | Setup | **+120 = 16B 双 id 对 {师, 翼}** (raid+200 同形) | name 先师后翼 / land-air 图标分支 / xp_level SetFrame=经验+1 / success_modifier_text; 点击 → SelectUnit / ping | raid_unit_entry | 定案 |
| 目标图标条目 | 合格性二分 sub_1412996A0 | **SRaidTarget 40B** (宿主 CRaidTargetMapIconData+2832 拷贝 / gamestate 目标条目+8); raid+160 访问器 sub_1406ABC90 直证 | 按 raid types 填图标格 | raid_target_entries_item | 定案 |

未决 6 项: 瓦片点击基类 / +24 内嵌对象定名 / naval 图标名 / mgr+80/+88 形态 / 详情视图类名 / 两需求 map 语义分界。

#### 4.31.29 舰船视图行族 (CShipItem / CShipArchetypeHeaderItem / CShipInfoEntry / CShipOverviewHeaderItem / CShipArchetypeItem / CShipEntry)

业务侧全收 §4.31.30 (含 CRestructureShipsToTaskforceCompositions 命令载荷); 族形态 = 六类全零覆写 Item 族 (真入口 = tooltip 泵槽0 + 非虚 populate); **无 statId 统计行** (舰船统计在 CShipStatsView 族, 不在此 6 类)。CShipEntry 裸名 RTTI 落空, 真名 = NTaskForceCompositionEditor::CShipEntry (命名空间类按 COL 扫描兜底)。注意: §4.31.27 statId 表不适用本族。

类布局 (类名 / target / 锚点):

六类全部零覆写 CStandardGridBoxItem+CTooltipHandler 族 (主 vtable 19 槽仅 dtor 逐类), 真入口 = tooltip 泵 (槽0, a1=this+24) + ctor/宿主 refresh 内非虚 populate; 6 类本身均不投 CCommand (编成应用命令见表末)。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CShipItem (48B, equipment_ship_entry) | CEquipmentVariant\*@+32 + 数量@+40 | CShipsOverview 变体展示行; ctor 被 ICF 并入宿主 refresh 0X141D43DF0; 无 tooltip 无交互 |
| CShipArchetypeHeaderItem (ship_archetype_header_entry) | **+1320 = CEquipmentType\* def / +1328 = 型内舰数** | **def+24 = 显示名块 (def 侧新偏移)**; 点击在 host+48 展开表增删 def → 重刷; EQUIPMENT_VARIANTS_TOGGLE 提示 |
| CShipInfoEntry (navy_view_ship_entry) | **40B (malloc 0x28 直证)**: +16 宿主窗 / +32 = 舰型 def idx (来源 = 聚合元素 ptr+1420) / +36 = 数量 (来源 = 聚合元素 dword@+8) | countryarmyview 海军页舰型计数行; **图标 = "GFX_navalcombat_ship_icon_"+def+104 舰体名 (def 侧新偏移)**; tooltip ARMY_NAVIES_TOOLTIP_DETAILED[_MULTIPLE]_DESC; **刷新 0x14170C110** (130 行): FindWindow 槽宿主 vtable+120 (ships_count 设数) / +136 (ship_icon 子件 vtable+728 SetSprite); sprite 存在断言 sub_142238DF0 不过 → countryarmyview.cpp:1991 "CGraphics::Get()->GetSpriteType( SpriteName )" (闩 byte_14338AF1C) |
| CShipOverviewHeaderItem (naval_losses_header_entry) | +1320 ptr / +1328 idpair / **+1336 = 时间段枚举 (1-4 = CURRENT_MONTH/LAST_MONTH/CURRENT_YEAR/OLDER)** / +1368 海难变体片 | ⚠ 类名误导 — 实为 **CNavalLossesOverview 过滤片头**; 点击在三张 host 键表 (+2720/+2744/+2768) 增删或翻转 host+2792, 无排序语义 |
| CShipArchetypeItem (equipment_archetype_entry) | **item+1344 = CSunkShipInfo\* 向量** (elem+124 变体 idpair, §4.30.17 互证) | 海损战役-archetype 聚合行; **72B 记录全解: def@0 / 图标键@8 / 损失@16 / 击杀者数组@24 / 沉船向量@48**; 沉船名链 obj+1008→+1240→+24 (§4.23 双命中); 点击灌 host+2800 进明细态 |
| NTaskForceCompositionEditor::CShipEntry (5320B, 4 glue; **裸名 RTTI 落空, 真名带命名空间**, COL 扫描兜底) | +32 舰型 / +36 角色 (0=any) / +44 目标数 | 编成编辑器唯一交互行; 增减按钮经修饰键 ±1/5/10 直写 editor+40 编成映射 (sub_14198A8A0 槽); 角色钮开 ShowRoleIconSelector 0X141E247E0 |

编成应用命令 (RTTI 实名): **CRestructureShipsToTaskforceCompositions** (vtable 0x1429B0D30, Execute 0X141354720) — 载荷 **+40 = tag** (token 10754 直证) / **+48 = task_force (15157) 映射**, 元素 32B {ships (12261) idpair 向量, +24 数量}。

**行族宿主锚与函数表** (1.19.3 重锚): CShipInfoEntry 宿主 **host+13504 条目池** — populate sub_14170F210 (16B 记录聚合 {def idx@0, count@+8}, stride 16) 逐条调 ctor sub_1417050A0 建行; 整理/排序 sub_141703120; populate (ships_count/ship_icon) 0x141E02290 (图标 = "GFX_navalcombat_ship_icon_" + def+104 舰体名)。
CShipOverviewHeaderItem 片头点击 sub_1417F7190 四路: +1368 → 翻转 host(+1376) 与 host+2792 / +1320 → sub_1417F9EA0 / +1328 (+1332) → sub_1417FA020(host, idpair) / +1336 → sub_1417FA1A0(host, enum)。
host 三键表增删函数与容器四元组全组: ptr 表 {data@2720, cap@2728, count@2732, alloc@2736} = sub_1417F9EA0 / idpair 表 {data@2744, cap@2752, count@2756, alloc@2760} = sub_1417FA020 / enum 表 {data@2768, cap@2776, count@2780, alloc@2784} (4B 元素) = sub_1417FA1A0; host 重刷 (NOTEWORTHY_BATTLES / BATTLES_OVER_TIME / total_ships_sunk / ALL_COUNTRIES 四串) sub_1417FA310; 标签泵 sub_1417FD000 (+1368 → "NAVAL_ACCIDENTS"; +1336 枚举 → CURRENT_MONTH/LAST_MONTH/CURRENT_YEAR/OLDER; our_kills_icon SetFrame = +1368?2:1); tooltip getter sub_1417F6760 (EQUIPMENT_VARIANTS_TOGGLE_OFF/ON)。
CShipArchetypeItem ctor sub_1417F2740; CShipArchetypeHeaderItem ctor sub_141D42A90; CShipEntry ctor sub_141E1DFB0 (+32/+48/+52/+56 清零, +5248 gui ctx, +5256 编辑器, +5272/+5280/+5288/+5304 四件); CShipEntry tooltip sub_141E22950 (TASK_FORCE_COMPOSITION_ADD_1/ADD_10)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 变体展示行 | 宿主 refresh 0X141D43DF0 内联 | variant\*@+32 + 数量@+40 | CShipsOverview; ICF 并入宿主 | equipment_ship_entry | 定案 |
| archetype 组头 | host+48 展开表 | +1320=CEquipmentType\* def/+1328 舰数 | **def+24 = 显示名块新偏移** | EQUIPMENT_VARIANTS_TOGGLE | 定案 |
| 海军页舰型计数行 | populate | +32 def idx/+36 数量 | **图标 = "GFX_navalcombat_ship_icon_"+def+104 新偏移** | ARMY_NAVIES_TOOLTIP_DETAILED[_MULTIPLE]_DESC | 定案 |
| 海损过滤片头 | 点击增删/翻转 | +1336 时间段枚举 1-4 / host 键表+2720/+2744/+2768/+2792 | 类名误导 = CNavalLossesOverview 片头 | naval_losses_header_entry | 定案 |
| 海损 archetype 聚合行 | 点击进明细 | item+1344 = CSunkShipInfo\* 向量; 72B 记录 {def@0/图标键@8/损失@16/击杀者@24/沉船向量@48} | 沉船名链 obj+1008→+1240→+24 双命中 | equipment_archetype_entry | 定案 |
| 编成编辑行 | 修饰键 ±1/5/10 | +32 舰型/+36 角色/+44 目标数; editor+40 编成映射 | 命令 = CRestructureShipsToTaskforceCompositions (+40 tag/+48 task_force 映射) | — | 定案 |

未决 9 项详项未录。

#### 4.31.30 生产部署+工厂格 (CProductionFactoryItem / CProductionNavalDeploymentItem 基 / DeploymentNavalBaseItem / NavyTheaterItem / TaskForceItem)

业务侧: 工厂格收 §4.31.30 (含宿主无 RTTI 堆视图对象布局); 海军部署三行+两命令收 §4.31.42。族形态 = 五类全零覆写 Item 族; tooltip 宿主 = 工厂格图标 (§4.30.3 同名行)。

类布局 (类名 / target / 锚点):

**CProductionFactoryItem** (1368B, 双 def production_military/naval_factory_item, ctor 0X141D49360; 零覆写 Item 族, 真入口 = tooltip 槽0 0X141D54820 + 非虚 populate): 生产窗工厂格图标。

| 偏移 | 语义 | 出处 |
|---|---|---|
| +1328 | 主状态 (由 sub_141D68F10 按**线+24 active / +28 damaged / +64 queued** 三段区间计算 — §4.8 三偏移互证) | 定案 |
| +1332 | overlay 状态 (同由 sub_141D68F10 计算 — §4.8 三偏移互证) | 定案 |
| +1352 | 格下标 | 定案 |
| +1360 | = **线+240 interface_factory_scale** (§4.8 互证) | 定案 |

左键 → **CAddProductionLineFactoriesCommand** (+40 线 id 对 / +48 i32 增减量; 目标值 = (下标+1)×每格数 − **线+232 requested_factories** 双证互证); tooltip 双分支 **PRODUCTION_FACTORY_ASSIGN_DESC / PRODUCTION_DOCKYARD_ASSIGN_DESC** (宿主 = 工厂格图标, §4.30.3 互证)。
**宿主 = CCountryProductionLineView+9288 指向的 CProductionNavalDeploymentWindow 子窗控制器** (1448B/0x5A8; 无独立 RTTI 类 — 负定案, 实名经主 vtable CLegacyButtonObserverGlue\<CProductionNavalDeploymentWindow\> 模板实例; ctor 0X141DAFAF0, 写入点 view ctor 0X141738090; +0 glue 基 160 槽回调表@+8..+1288 / +1288 窗名 SSO "production_deployment_window" / **+1320/+1344/+1368 = 三部署行容器** / +1392 = ctor a2 / **+1408/+1416 = 选中线 id 对** / +1424 SSO 容器 — 定案)。
⚠ +7888 选中产线 idref / +7896 工厂格向量 / +8000 悬停下标 (init −1) 归属 = **CProductionLineEquipmentItem** (ctor 0X141D4A210 直写三字段, RTTI 实名; 子件经 item+8 回指消费) — 原并入 +9288 对象系误并, 已拆正。

类布局 (类名 / target / 锚点):

新舰分配去向 (基地/剧场/特混三级) 行件; 全部零覆写 Item 族; 与 §4.18.10 陆军 conveyor 族边界划清 (数据源/命令/def 全无交集)。基类 CProductionNavalDeploymentItem (tooltip 槽0 = purecall 抽象): +32 名串 (setter sub_141DB3B80) / **+64 = 视图回指 (非 target)** / +1360 = CNavalDeploymentTarget id 对。

| 类 | 数据源 | 锚点 |
|---|---|---|
| CProductionDeploymentNavalBaseItem (production_deployment_port_item, ctor 0X141DAE550) | **CStrategicNavy (gamestate+1688 ✓) +24 容器**, 条目 +16 州 id/+24 基地等级 | 名 = PRODUCTION_NAVAL_DEPLOYMENT_STATE_NAME{STATE,LVL}; tooltip PRODUCTION_DEPLOY_TO_BASE+右键缩放提示; 右键缩放地图 sub_141DB2E10 / 左键设目标 sub_141DB3940 |
| CProductionDeploymentNavyTheaterItem (production_deployment_navy_theater_item, ctor 0X141DAE850) | **CNavyTheater (country+352 ✓) +0 容器** | tooltip PRODUCTION_DEPLOY_TO_RESERVE_FLEET_THEATER; 左键 sub_141DB2BA0 → 按视图+1408/+1416 选中线发命令 |
| CProductionDeploymentTaskForceItem (1376B, production_deployment_task_force_item, ctor 0X141DAEB50) | **country+632 CTaskForce\*\* ✓** (扁平化 sub_1406D35A0) | **item+1360 = tf+24 id 对** (= 内嵌 CNavalDeploymentTarget@+16 互证); +1368 内嵌 CNavyTheaterTaskForceItem 徽章子件 (§4.24 复用); tooltip PRODUCTION_DEPLOY_TO_FLEET; 左键设目标 / 右键选中特混 (宿主=目标−16) |

命令出口 (均 RTTI 实名): **CSetNavalDeploymentTargetCommand** (0x48B; +40 线 id 对, 断言 "_ProductionLine.IsValid" countrycommands.cpp / +56 target id 对) / **CSetShipRefitDeploymentTargetCommand** (+40 改装线 id 对 / +48 目标拷贝 / +56 id 对) — 与 §4.30.3 已立的 vtable[11] 地图点省通道 (sub_141DB3390) 同字段同命令互证。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 工厂格图标 | sub_141D68F10 状态机 | +1352 下标/+1328+1332 状态 (线+24/+28/+64 三段 ✓)/+1360=线+240 ✓ | 左键 → CAddProductionLineFactoriesCommand (目标=(下标+1)×每格数−线+232 ✓) | PRODUCTION_FACTORY_ASSIGN_DESC / _DOCKYARD_ | 定案 |
| 母港行 | sub_141DB3940 | CStrategicNavy (gamestate+1688)+24 容器; 条目+16 州/+24 等级 | 右键缩放地图 sub_141DB2E10 | PRODUCTION_NAVAL_DEPLOYMENT_STATE_NAME / PRODUCTION_DEPLOY_TO_BASE | 定案 |
| 剧场行 | sub_141DB2BA0 | CNavyTheater (country+352) 容器 {data@theater+0, count@+12} (装配器 sub_141DB04C0) | 按视图+1408/+1416 选中线发命令 | PRODUCTION_DEPLOY_TO_RESERVE_FLEET_THEATER | 定案 |
| 特混行 | 左键设目标/右键选中 | country+632 CTaskForce**; item+1360=tf+24 id 对 | +1368 内嵌 CNavyTheaterTaskForceItem 徽章 (§4.24 复用) | PRODUCTION_DEPLOY_TO_FLEET | 定案 |
| 命令出口 | RTTI 实名 | CSetNavalDeploymentTargetCommand (+40 线/+56 target) / CSetShipRefitDeploymentTargetCommand (+40/+48/+56) | 与 §4.30.3 vtable[11] 地图点省通道同字段互证 | countrycommands.cpp 断言 | 定案 |

未决 8 项 (宿主堆视图对象已定案 = CProductionNavalDeploymentWindow 子窗控制器,
+7888/+7896/+8000 改属 CProductionLineEquipmentItem — §4.31.30)。

#### 4.31.31 阵营窗/列表/剧场 (CFactionListWindow / CFactionListItem / CFactionCountryItem / CFactionIconItem / CFactionInfluenceItem / CFactionTheaterWindow / CFactionTheaterItem / CFactionTheaterFlagItem)

业务侧类布局见下 (逐类 target+锚点+四命令载荷) + §4.26.8 (CFactionIconsDatabase qword_14332EEE8); theater 条目 168B 布局入 §4.30.41 子表 (fac+2552)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CFactionListWindow | 无存储 target (populate 现取 **facsys+32 全阵营表**, facsys = gs+1016 ✓) | CReloadableWindow 9 槽第 4 例 ([4]=Setup/[5]=Clear/[6]=populate 槽语义); 宿主 = CCountryPoliticsView+15680 |
| CFactionListItem | CFaction\*@item+56 (非虚 setter sub_141C5AB40) | fac+24/+56 名、+1352 icon、+2072 power_projection 四锚命中 |
| CFactionCountryItem | **u32 country tag@item+32** (tag 存储; +24 = 父窗非 tooltip) | **members+88 消费坐实** = CFactionMemberCountriesWindow::SetupDerived sub_141ADE680 (fac+88/+100 ✓ + 首元领袖 tag); 派生三行 (Invite/Kick/Ping) 出口 = item 槽 [20][21] |
| CFactionIconItem | icon 名串@item+24 | SetGfx vtable+728 / SetFrame vtable+176 双消费槽; 图标库 = CFactionIconsDatabase (§4.26.8) |
| CFactionInfluenceItem | CCountry\*@item+72 (setter sub_141C18B30) | **MemberStatus+56 占比/+80 排名互证**: populate sub_141474550 直读 → FACTION_INFLUENCE_PERCENTAGE; 第三处 +56 消费 = 排序 sub_1414680B0 (208 步长直读) |
| CFactionTheaterWindow | 无存储 target (查看国 tag→MemberStatus→dip+656→CFaction→**fac+2552 CFactionTheaterManager ✓**, mgr+16/+28 ✓) | parent = CFactionTheaterPopup; 选中序号@win+128 |
| CFactionTheaterItem | **theater 序号@item+48** | 条目 168B (name+0/tag+32 ✓; flags/regions 向量布局见 §4.30.41 子表); 改名/pin/删除三命令出口实名 |
| CFactionTheaterFlagItem | theater 条目+48 向量元素指针 (u32 tag) | ctor 即 SetFlag (sub_140B44870), 无独立 populate; 基族 = 旗件基 (sub_1422A9260), 非 19 槽 Item 骨架 |

命令出口四枚 (载荷全定案): **CClearFactionTheater** {+40 tag / +44 idx} / **CSetFactionTheaterPinVisibility** {+40 tag / +44 idx / +48 bool} / **CModifyFactionTheater** {+40 tag / +44 idx / +48 新名 SSO / +80..+152 四空容器} / **CSetFactionIconAndColor** {+40 tag / +48 icon 串 / +80 CColor} — Execute 写 fac+1352 icon 与 fac+2512 rgba (CColor+16) ✓。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 阵营列表窗 | populate 槽 [6] | facsys+32 全阵营表 (gs+1016 ✓) | CReloadableWindow 9 槽第 4 例; 宿主 = CCountryPoliticsView+15680 | — | 定案 |
| 阵营行 | setter sub_141C5AB40 | item+56 = CFaction\* | fac+24/+56/+1352/+2072 四锚 | — | 定案 |
| 成员国行 | SetupDerived sub_141ADE680 | item+32 = u32 tag; fac+88/+100 ✓ | Invite/Kick/Ping 出口 = item 槽 [20][21] | — | 定案 |
| 图标行 | SetGfx/SetFrame | item+24 icon 名串; DB qword_14332EEE8 | CSetFactionIconAndColor Execute 写 fac+1352/fac+2512 rgba | — | 定案 |
| 影响力行 | populate sub_141474550 | item+72 = CCountry\*; MemberStatus+56/+80 ✓ | 第三处 +56 消费 = 排序 sub_1414680B0 (208 步长) | FACTION_INFLUENCE_PERCENTAGE | 定案 |
| 剧场窗/行/旗 | 查看国→dip+656 链 | fac+2552 mgr ✓; 条目 168B {+0 name/+32 tag/+48 flags/+72 regions} | 三命令 CClearFactionTheater / CSetFactionTheaterPinVisibility / CModifyFactionTheater 载荷全解 | — | 定案 |

未决 4 项: 条目+48 flags 业务语义 / 阵营表排序比较键 / win+2968 写入点 / 条目+36 commander 字段映射。已结 1 项: **CSetFactionIconAndColor UI 投递 = 高置信走外交 action 提交链** — 工厂 sub_141BA84C0 从 action 对象 ICF 拷贝构造 {+40 tag / +48.. icon SSO / +80 CColor vtable + +96 16B 色数据}, dump 全文无 UI 直构点 (同 §4.31.60 外交 action 链模式; 默认 ctor sub_141BA8D70 同 ICF); 具体按钮需活体。sub_141189310 = 阵营影响力 tooltip (FACTION_INFLUENCE_TOOLTIP_HEADER + TOTAL_INFLUENCE) 已定案。

#### 4.31.32 阵营成员科学家/升级/情报/计划 (CFactionMemberScientistItem / CFactionMemberUpgradeButton / CFactionIntelligencePopup / CFactionProgramItem)

业务侧类布局见下 (含三边界裁清与四命令载荷); CFactionMemberUpgradeGroupDatabase = qword_14332EEF8 (静态库, 与 §4.26.8 同族登记)。

类布局 (类名 / target / 锚点):

边界裁清: 科学家行走 **CFactionProgramStatus 内嵌 48B 科学家条目数组 (status+176/+188)** — 与 §4.30.41 fac+2104 slots 顾问槽**不同源**; 升级钮走组 def 库 + fac+2104 member_upgrades RH; 情报弹窗只持组 id (slots 由 §4.31.21 CIntelligenceAdvisorSlotItem 消费)。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CFactionMemberScientistItem (vtable 0X142A91780, 4184B, member_scientist_item) | 科学家 ref→+4152 (setter sub_141F17330) / 国家 ref→+4160 (sub_141F17270) | ctor 0X141F16130 + tooltip 槽0 0X141F169D0; 数据源 = CFactionProgramStatus+176/+188 48B 条目数组; unassign 钮出口 = **NFactions::CFactionUnattachScientistCommand {+40 科学家 ref / +48 国家 ref}** |
| CFactionMemberUpgradeButton (vtable 0X142A90178, 1424B) | 组 def 驱动 (**CFactionMemberUpgradeGroupDatabase = qword_14332EEF8**, def+128 升级数组) | **fac+2104 member_upgrades RH 互证 ✓** (父项 Update sub_141F0AB00 经 sub_1413FB0D0(fac+2104, groupToken) 查当前计数); 钮布局 +1400 升级 def/+1408 selected/+1409 阈值/+1416 父项; 点击出口 = **NFactions::CSetFactionUpgradeCommand {+40 def 指针 / +48 tag id}** |
| CFactionIntelligencePopup (vtable 0x1429C43B8, 4208B, CFactionPopup 基 id=7) | **popup+4200 = EIntelligenceGroups 组 id** (show 前 sub_141C04E40 写入) | 覆写槽 [14]CanShow (机构存在 + 经费 ≥ 100000×define 定点) / [15]GetTitle "FACTION_INTELLIGENCE_TAB" / [16]GetDescription ("FACTION_INTEL_HEAD_OF_" 前缀 + INTELLIGENCE_POPUP_DESCRIPTION{GROUP,COST}) / [17]Accept; 出口 = **NFactions::CUpdateIntelligenceAdvisorSlotCommand {+40 tag / +48=0 / +56 组 id}** |
| CFactionProgramItem (vtable 0x142A528D8, 11448B, 基 CProgramItemBase) | **item+56 = CFactionProgramStatus ref** (源 = fac+1992 faction_programs 容器 ✓, data@2000/count@2012 (元 = 8B CRef 双 u32 对)) | status 读出 +24 owner tag/+160 科学家区禁用旗/+176 科学家数组; 类专属槽 [24]Update 0X141C1A090 (显隐/使能全表) / [25] 广播 SetCountry / [26]OnDismantleFacility (确认窗) / [27] 卡背 "GFX_faction_sp_facility_card_bg"; 拆除出口 = **NFactions::CRemoveFactionProgramCommand {+40 status ref}** |

**CDismantleFactionDialog (解散阵营对话框, GUI)**: **+4096 = 裸 u32 tag id**; 描述取 CFaction 名 (cc+3976→dip+656 链 ✓ 互证); 接受 = **CDiplomaticActionCommand 包 NFactions::CDismantleFactionAction** 投递。

**NFactions::NUi::CAssignResearchFacilityWindow (研究设施指派窗, GUI)**: (vtable 0x1429C4D48, 1624B): **CProjectListFilterWindow\<CResearchFacilityItem\> 模板基三纯虚实现**; Setup ICF 数据源 = **cc+4008 program_status+32 程序表 ✓✓ 双命中**; 本体纯选择器不投命令; 候选出口 = **NFactions::CAddFactionProgramCommand {+40 faction / +48 program}** (Execute 定案; 本体零命令构造, 三构造点在族外 = sub_141C023A0 (CFactionProgramItem 确认行) / sub_141C03790 / sub_141A4AC10 — §4.31.60, 接线点悬念已销)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 阵营科学家行 | setter ×2 + tooltip 槽0 | ref→+4152/+4160; status+176/+188 48B 数组 | **与 fac+2104 slots 不同源** (边界定案); 出口 CFactionUnattachScientistCommand | member_scientist_item | 定案 |
| 升级钮 | 父项 Update sub_141F0AB00 | 组 def 库 qword_14332EEF8 def+128; fac+2104 RH ✓ | +1408 selected / **+1409 = 「当前值 ≥ 目标值」比较结果旗** (唯一写点 sub_141F0A870: `*(BYTE*)(a1+1409) = *(QWORD*)(*(a1+1400)+104) >= *a3`; 配套帧 GFX_checkbox_small_red_circle, 使能档 selected?2:1); 出口 CSetFactionUpgradeCommand | — | 定案 |
| 情报弹窗 | [14]CanShow/[15..17] | popup+4200 = EIntelligenceGroups 组 id | 经费 ≥ 100000×define 定点; 出口 CUpdateIntelligenceAdvisorSlotCommand | FACTION_INTELLIGENCE_TAB / INTELLIGENCE_POPUP_DESCRIPTION | 定案 |
| 阵营计划行 | [24]Update 0X141C1A090 | item+56 = status ref (fac+1992 ✓) | status+24/+160/+176 读出; 拆除出口 CRemoveFactionProgramCommand | GFX_faction_sp_facility_card_bg | 定案 |

未决 6 项 (+1409 方向语义已定案)。

#### 4.31.33 生产信息/资源/名表 (CProductionInfoEquipmentItem / CProductionResourceItem / CProductionTypeResourceItem / CProductionNameListItem / CProductionNameListWindow)

业务侧类布局见下 (含四命令载荷); rs+576 资源余额数组锚入 §4.3 +4600 行。

类布局 (类名 / target / 锚点):

源文件 productionlineitems.cpp / productiondeploymentwindow.cpp 实名; 全部零覆写 Item 族。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CProductionInfoEquipmentItem | entry ptr @ item+4056 (**entry 无 RTTI**: **+872 成本 fixed / +984 资源成本容器 / +996 int 资源过滤门 / +1008 CEquipmentType\* / +1160 MIO ref**) | 真 populate = 非虚 Update 0X141D620E0; **25 个子 widget 槽 (+3896..+4048) 全部按 GUI 名定案**; 双布局 (military/naval_equipment_info_entry) 共用同类; 填充 fn military sub_141DB9C00 / naval sub_141DBA920 (item malloc 0x1060=4192); **过滤门 +996**: >0 时须 +984 镜像容器存在正额资源才放行; **过滤链伴随锚**: 窗口 +4000 掩码 ∧ entry+1032 / +4012 bool / +3904 行池 / +3916 已填 / entry+1060 |
| CProductionInfoEquipmentItem 过滤门 +997 | — | **属主定案: 宿主 = \*(entry+1008)+997, 即 CEquipmentType+997** (非 entry 本体) |
| CProductionResourceItem (主 vtable 0x142A6DEC0, 19 槽仅 [0] dtor 自有 0x141D50F90) | **32B payload @ item+32 {+8 资源 def / +16 amount / +24 lacking fixed×1e-5}** | 产线材料成本行; 填充 sub_141D641E0 (池 +7864 索引调用 setter) 命中 **country+4600 rs 簇 + rs+576 余额数组 × def+216 行号** (RESOURCE_BALANCE_VALUE 互证 ✓); tooltip 四 loc (COST_DESC/NO_WASTE/WASTE/LACKING); setter sub_141D61820 体仅写 amount (PRODUCTION_RESOURCE_COST) — **色码定案 = setter 第三实参 (IDA 2 参头丢参): 调用点 sub_141D641E0 / sub_141D633C0 传字节 71 'G'(富余) / 87 'W'(恰好) / 82 'R'(lacking>0 或需求>可得); 资源图标行 lacking>0 换 GFX_missing_resources_strip**; **池初始化 sub_141D63E90** (ctor 内联 malloc 0x38 写双 vtable + "production_resource_item"); **父窗资源行池 = +7864 data / +7872 cap / +7876 count / +7880 分配器 (+2616 父 widget)**; 池尺寸全局 dword_143335B90 |
| CProductionTypeResourceItem | target def ptr @ item+32 | 装备资源成本图标: setter 0X141D61A00 (resource_icon **SetFrame = def+220 ✓** + amount 文本); tooltip = 资源名; 唯一生产现场 = resources_grid 填充 0X141D636F0 (**entry+984 容器 16B 元素 {fixed, 库索引}**) |
| CProductionNameListItem (naval_name_list_entry, **海军专用**; 主 vtable 0x142A75BD0, 19 槽仅 [0] dtor 自有 0x141DB00A0; ctor sub_141DAF230, +2608/+2616/+2648/+2856 槽) | 显示名 @ row+96→item+2776→+2608 文本框 | 舰名表条目; **13 字段从 176B 行直拷** (逐偏移定案, 部分语义未决); tooltip = PRODUCTION_DRAG_N_DROP / PRODUCTION_LINE_SHIP_NAME_ALLOCATE |
| CProductionNameListWindow (ship_name_list_window, 2896B) | **名表数据源 = +2880/+2888 ref → 对象 {+260 行数, +8 内层容器, 176B 行}** | 内嵌 CGenericEmptyEntryList\<CProductionNameListItem\> @ +2784; 校验 loc 族 PRODUCTION_NAVAL_NAME_LIST_* |

命令出口四枚 (均 RTTI 实名): **CChangeProductionLineNamePriorityCommand** {+40 容器 / +48 from / +52 to, 拖拽换序} / **CRemoveProductionLineName** {+40 / +48 idx} / **CAddProductionLineName** {+40 / +48 名串} / **CAddProductionLineOrderedName** {+40 / +48 int}。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 装备信息行 | Update 0X141D620E0 | entry@item+4056 (无 RTTI): +872 成本/+984 资源成本/+1008 CEquipmentType\*/+1160 MIO | 25 widget 槽全定案; productionlineitems.cpp 实名 | military/naval_equipment_info_entry | 定案 |
| 材料成本行 | 填充 0X141D641E0 | payload@item+32 {+8 def/+16 amount/+24 lacking} | **rs+576 余额数组 × def+216 行号** ✓; 色码 = setter 第三参 'G'/'W'/'R' (调用点分档) | COST_DESC/NO_WASTE/WASTE/LACKING | 定案 |
| 资源成本图标 | setter 0X141D61A00 | item+32 def; SetFrame = **def+220 ✓** | resources_grid 填充 0X141D636F0 (entry+984 容器 16B 元) | 资源名 | 定案 |
| 舰名表条目/窗 | CGenericEmptyEntryList@+2784 | 数据源 +2880/+2888 ref → {+260 行数, +8 容器, 176B 行} | 13 字段直拷; 四命令 (换序/删/加/有序加) 载荷全解 | PRODUCTION_NAVAL_NAME_LIST_* / PRODUCTION_DRAG_N_DROP | 定案 |

未决: ResourceItem item+40/+48 写入点 / 名表持有对象 RTTI / 装备信息父窗类名 / equipment_button 点击命令。

#### 4.31.34 空袭设置/反馈窗 (CRaidSetupView / CRaidFeedbackView / CRaidFilterCategoryItem / CRaidTypeIconItem)

业务侧: raid+56/+60/+200 三锚消费入 §4.23 CRaidInstance 行注 (见 §4.31.28 同族); **CCreateRaidCommand 新收入 §4.23 命令族** (本条末)。视图侧: CRaidSetupView 窗族基形 = CReloadable@0+CTooltipHandler@40+CInGameUpdateable@48, 真入口 vtable[2] Reload (teardown→Setup→Populate); 数据全走回指+152 的 **CRaidGuiManager** (manager+312 内嵌本视图)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 设置窗两步列表 | vtable[2] Reload | unit/source 分别产 CRaidUnitItem (16B id 对元) / CRaidSourceItem (64B 元) | CRaidGuiManager+312 内嵌 | raid_unit/source_selection_prompt | 定案 |
| 反馈窗 | populate (this=view+40) | raid=view+88 CRaidInstance\*; **raid+60 outcome ✓ (∈{3,4}=成功档) / raid+200 unit id 对 ✓ / +2960 isActor 视角字节** | dismiss 钮断言 **raid+56 phase==5 ✓** 后派 CRemoveRaidCommand | actor/victim 双 loc 族 | 定案 |
| 类别过滤行 | setter sub_141B37490 | 图标 = `GFX_raid_category_small_<token名(def+8)>`; **def 侧新定: CRaidCategory +8 名 token / +36 启用标志** | 点击 → CRaidFilter::ToggleCategory | raid_category_filter_entry | 定案 |
| 类型图标行 | setter sub_141B399C0 | **CRaidType def\* @+1512 (断言实名)** + type key 40B 串 @+1472 + available @+1520 | 点击 → sub_14129B4A0 选定类型; 消费侧 = CRaidTargetMapIconEntry 双列表 (§4.31.28) | — | 定案 |
| 发起空袭命令 | CRaidGuiManager::LaunchRaid | **NRaids::NNet::CCreateRaidCommand** (176B, ctor sub_141B319B0): +40 actor id / +48 def ptr / +96.. CBuildingReference 源建筑 / +152 id 对 / +168 u32 / +172 u8 | 由 launch 按钮派发; 结束 = CRemoveRaidCommand (+40 raid 引用/+48 请求国 id) ✓ | — | 定案 |

未决 6 项: unit 16B 元素语义 / +2880 widget 名 / manager+80 类名等。已结 1 项: CCreateRaidCommand 四字段语义 (本节表行已逐项列出 +40 actor id / +48 def ptr / +96.. CBuildingReference / +152 id 对 / +168 u32 / +172 u8 — 表行全覆盖, 销)。

#### 4.31.35 科技信息/树行 (CTechnologyInfoWindow / TreeTechItem / TreeXorItem / TreeLineSegmentItem / CTechnologyGroupEntry / CTechnologySharingGroupEntry / CTechnologyAirMissionEntry / CTechnologyEquipmentStatEntry / CTechnologyTechnologyStatEntry)

业务侧类布局见下 (含 def 侧四新锚: CTechnology def+16 修正值容器 / def+400 任务细节数组 / template+1036 图标门 (`show_equipment_icon`, reader case 13950; dump 侧 token 字面 "show_equipment" qword_1430B3E20 — 与 +1034 相邻, +1034 本身待裁: 探针 = 含/不含装备图标门两科技模板读 +1032/+1034 对照) / template+1040 子槽位索引)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CTechnologyInfoWindow | ctor 签名 demangle 直证 (CCountryTechTreeView&, CString, CTechnology → +5248/+32/+5272) | 主 vtable [9] 0X141BDDF10 = 头部刷新 (tech_info_title/research_progressbar/HEADER_ENABLED); **变体分发 0X141BDDD10 六指针结构**: +0 科技 (tech+352/+360 ✓ + **template+1036 = `show_equipment_icon`** reader case 13950 直证) / +8 装备 (读集对象 = **CEquipmentModule 模块 def (定案; 三锚比对 §4.23.7a)**: +116 allow_mission_type 键 11057 (`|0x20` = DROP_NUKE 位喂任务网格 sub_141F00E00) / +432 build_cost_resources 键 15216 (16B {资源 token, fixed64}) / +344+376 = 内嵌 CEquipmentStatsGroup (+296 起 104B) stats pairs 16B {statId, i64}, 78 = EEquipmentStats 枚举上界; 读出经 statId helper 建 technology_unit_stat_item — 原「形态与 CSubUnitDefinition 不符」正解 = 类名认领错位) / +16 / +24 / +40 修正网格 / +56; 无 CCommand, 出口 = 8 个填充器 (loc 键直证: sub_141F02880 海军统治/技术树 · sub_141F06610 · sub_141F02440 · sub_141F05FE0 战术攻防 · sub_141F04A80 战宽 · sub_141F037B0 · sub_141F05680 · sub_141F03E00 设计商人力/训练) |
| CTechnologyTreeTechItem | **216B, 构造器 0X141BD0070**; **item+200 = CTechnology\*** (listener 注销互证) / item+48 = CCountryTechTreeView\* / **item+128 子科技 tech 指针表 {data@+128, count@+140} / item+152 子槽状态 int32 数组 (1..6 枚举, 与 +128 平行同下标) / item+176 子槽窗口表 / item+208 主项状态枚举 (1..6) / item+212 foreign 旗 u8** | populate 0X141BD6770 第 5 参 = **view+2784 (本文件夹项容器) / view+4072 (他文件夹项容器)** 按 folder 匹配旗分流; 消费 **tech+352 模板 ✓ / tech+176 后继表 (count@188) ✓ 双册锚**; 子槽名 `sub_technology_slot_<template+1040>` — **template+1040 = 子槽位索引 (template 侧新锚)**; tooltip 巨函含 template+836/+1336 与 RESEARCH_DONE/TECH_SHARNG_* loc |
| CTechnologyTreeXorItem | **64B, 构造器 0X141BD0540 (a2 = 树根), GetOrCreate = 0X1413D4DD0 (view+6696/+6708 待绑表按盒+件坐标查重)**; **item+32 = 格坐标对** (池键互证) / item+56 = 树层索引 (格对象+380) | 朝向 setter 0X141BD0D80 按 dir 0..3 给 First/Second 子窗上 GFX_techtree_xor_* (vtable+728 SetGfx ✓); tooltip = MUTUALLY_EXCLUSIVE_TREE — 互斥对连接标, **非 def 互斥对直读** |
| CTechnologyTreeLineSegmentItem | item+128 = view | 格坐标键池化连线段; 子窗 Up/Down/Left/Right/Center + **13 根静态线型 LUT (+136..+232)**; populate 0X141BD5E80 / update 0X141BD5780 |
| CTechnologyGroupEntry (technology_idea_entry) | **item+32 = 理念槽目标对象** (+56 byte 占用旗 / +2684 可见门 / +2720 槽型→+56 槽名) | 科技页底部国策理念槽行; GFX_idea_slot_* 兜底 GFX_add_pol_idea_button; Update 0X1415F9C70 |
| CTechnologySharingGroupEntry | **item+32 = CTechnologySharingGroup\*** | **命中册锚: 国家上下文+3936 → +280 共享组 vector ✓**; Update 0X1415FA010 设组图标/帧; tooltip 三段 (组名 KEY/HEADER + 成员 + item+40 门控附加段) |
| CTechnologyAirMissionEntry (technology_air_mission_entry) | **item+32 = 空军任务位掩码** (0X141013C50 → AIRWING_MISSION_TYPE_*; **位 0x20 = DROP_NUKE 触发 "nukes" idb 特判**) / item+40 = 目标 def+400 任务细节数组元素+8 | **def+400 = 任务细节数组 (def 侧新锚)**; 真入口 = ctor 0X141FAE540 + tooltip 0X141FAEF90 + 网格构建 0X141F00E00 (18 任务位) |
| CTechnologyEquipmentStatEntry | **item+32 = statId (0..77, 78 = 哨兵)** / item+40 = 上下文 ptr / item+48 = tooltip 附加串 | name/amount 走 statId LUT (sub_1413E6570/0X1413E6800/0X1413E5BD0 — §4.31.27 同族 helper); setter 0X141FB01E0/0X141FB0050 |
| CTechnologyTechnologyStatEntry | **item+32 = 修正元表 (qword_14332ED90, 120B stride = modifier def 表) 索引** / item+36 = 行类型 (**仅 2 合法**, technologyinfo_entries.cpp 断言直证) | **数据源 = CTechnology def+16 修正值容器 (def 侧新锚)**; loc STAT_VALUE_CHANGE(_PERC)/YES/NO + <名>_DESC; **vtable 0x142AA3080 (RTTI) / ctor 0x141FAE7E0 (置 +36=1, +0/+24 双 vtable 拷贝) / 本地化键构造 = vtable [20] 0x141FAF770** (this = entry+24 子对象): 门 +36==2 否则一次性断言 "incorrect type" (:134, 闩 byte_14338CD28) ⇒ **类型 1 = 另一变体, 2 = 本地化路径**; 头部 = 修正 def 名经 sub_14055D110 (move 语义) 构 104B 参数 {type@0=1, 名@8="KEY", 串值@+48} → sub_142245E60(out, "HEADER", &param, 1); 尾段 = 名 + "_DESC" 追加 (容量不足先 sub_14011DBC0 扩) → 键存在检查 → 命中则本地化 append (sub_140129C10) |

**CTechnologyTreeTechItem 状态枚举 → GFX 背景后缀表** (SetSubSlotState 0x141BD5200 非虚 / SetMainState 0x141BD48D0; 定案):

| state | 非 foreign 后缀 | foreign 后缀 (item+212) |
|---|---|---|
| 1 / 2 | `_unavailable_item_bg` | `_foreign_unavailable_item_bg` |
| 3 / 6 | `_available_item_bg` | `_foreign_available_item_bg` |
| 4 | `_researched_item_bg` | `_foreign_researched_item_bg` |
| 5 | `_currently_researching_item_bg` | `_foreign_currently_researching_item_bg` |
| 其他 | 不变 (一次性断言 "Invalid enum", technologytreeitems.cpp:531, 闩 byte_14338C3F1) | 同 |

> GFX 拼装: `*( *( *(item+200) + 352 ) + 1344 )` (template+1344 special_project 旗, §4.7.7) 非 0 → 后缀追加 "_special_project"; 总键 = "GFX_subtechnology_" + 后缀; 查表 sub_142238DF0(*(qword_14332F698+1264), key) → sub_1422AF6C0(gfx 窗, key, 0) 设图; **未命中回退 "GFX_subtechnology"**。仅当新状态 ≠ 旧状态才重绘。主项 GFX 窗取 item+16, 子槽窗取 *(item+176)+8×slot (同 vtable+536 槽)。
> **状态来源 = 情报可见性门计算 sub_141433870** (返 2/3/4/5; 定案): folder def (sub_140EDA240 → template+896 folder 条目) +56==0 → 情报等级 0; 否则 **folder+200 位域 bits 1-4 解码** (bit1→0 / bit2→1 / bit3→2 / bit4→3); 情报比值 = 进度×1e5 ÷ **INTEL_COUNTRY_LEVEL_MAXIMUMS[level]** (qword_1433390B8, countryintel.cpp:302 断言 "Expected INTEL_COUNTRY_LEVEL_MAXIMUMS to contain 4 values", 缺项填 100000; 防溢出门未过 → −1); 可见门 = template+1033 非 0 → 自定门 sub_141434600, 否则比值 ≥ **INTEL_TO_SHOW_PREVIOUSLY_RESEARCHED[level]** (qword_143339118, defines_intel.h:76); byte_14332F63A 非 0 强制放行; 未过门 → 2; 过门 → GetTechState sub_140EDEE40 (§4.7.1 +368 枚举): ≠5 → 经 template+1312/+1320 XP 门与两辅助门返 3/4 (不符返 2); ==5 (在研) → 比值 ≥ **INTEL_TO_SHOW_CURRENTLY_RESEARCHED[level]** (qword_143339130) → 5, 否则降级 3。
> **刷新链**: view 全量刷新 sub_1413DDF20 — 遍历 **view+6768** 40B/条 item 容器 (count@+6780, 条+16 = item 指针) → 逐项 SetMainState + 逐子槽 SetSubSlotState; 观察国 tag = gs+1312 (>0 时) 否则 gs+1316。**item+32 监听子对象回调 0x141BD4410**: 变更科技在主科技 **tech+224 互斥表** (count@+236) 内 → 仅刷主项; = 主科技 → 主项 + 全部子槽; = 某子槽科技 → 仅该子槽。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 科技信息窗 | 主 vtable[9] + 变体分发 0X141BDDD10 | ctor +5248/+32/+5272 (签名直证) | 三变体: 科技 (tech+352/+360 ✓) / 装备 (CSubUnitDefinition 族待裁) / 修正网格 | tech_info_title / HEADER_ENABLED | 定案 |
| 树节点 | populate 0X141BD6770 | item+200 = CTechnology\*; tech+352 ✓/tech+176 (c@188) ✓ | 子槽名 = template+1040 索引 | RESEARCH_DONE / TECH_SHARNG_* | 定案 |
| 互斥连接标 | 朝向 setter 0X141BD0D80 | item+32 格坐标对/+56 树层 | GFX_techtree_xor_* SetGfx ✓; 非 def 互斥直读 | MUTUALLY_EXCLUSIVE_TREE | 定案 |
| 连线段 | populate 0X141BD5E80 | 格坐标键池化; 13 线型 LUT +136..+232 | 五向子窗 | — | 定案 |
| 理念槽行 | Update 0X1415F9C70 | item+32 槽对象 (+56 占用/+2684 可见/+2720 槽型) | 科技页底部国策理念槽 | GFX_idea_slot_* | 定案 |
| 分享组行 | Update 0X1415FA010 | item+32 = CTechnologySharingGroup\*; 上下文+3936→+280 ✓ | 三段 tooltip | 组名 KEY/HEADER | 定案 |
| 空军任务行 | 网格构建 0X141F00E00 | item+32 任务位掩码 (0x20=DROP_NUKE→nukes 特判)/+40 def+400 元素+8 | AIRWING_MISSION_TYPE_* 18 任务位 | technology_air_mission_entry | 定案 |
| 装备统计行 | setter ×2 | item+32 = statId (78=哨兵) | §4.31.27 LUT 同族 | statId loc | 定案 |
| 科技统计行 | 修正元表 120B | item+32 mdef 索引/+36 行类型 (仅 2 合法断言) | **def+16 修正值容器新锚** | STAT_VALUE_CHANGE(_PERC) | 定案 |

未决 7 项 (按钮命令载荷等; 装备变体锚族已结 = CEquipmentModule 定案, 见 §4.31.35 头注行)。

#### 4.31.36 陆军行件 (CArmyGroupItem / CArmyItem / CArmyHistoryEntryItem / CArmyLeaderTraitWindow / CArmyLeaderWindow / CArmyReinforcementItem / CArmyUpgradeItem)

业务侧: 军/集团军行收 §4.24.13; 将领窗收 §4.31.36; 军史行壳收 §4.18 (CArmyHistoryEntryItem 注); 增援/升级优先级收 §4.3 +3960/+3968 行。

类布局 (类名 / target / 锚点):

**CArmyLeaderTraitWindow** (unitleader_trait_tree_window): target = **CUnitLeader idpair@基+120**; 槽[7] 绑 regular/advisor(high_command)/terrain/officer_corps 八元素 (**军官团体系 = 海军版无此簇的同构差异**); 槽[8] 四技能 = **+3928/+3944/+3960/+3976 ✓ 四证** (与海军错位 16B 版对照 — 海军 = +3944/+3960/+3976/+3992, §4.4.17 行注); 槽[9] tooltip 命中 **skill+440 等级 / def DB qword_14332F0D0 / def+444 下级 XP 阈值** (全双证)。
**CArmyLeaderWindow**: 见 §4.24.13 (target/命令出口)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CArmyGroupItem (army_group_box; 零覆写 Item 族, ctor 0X141889AC0 + setter sub_14188C020) | **CArmyGroup idpair@item+32** | populate sub_14188C680 遍历 **CArmyGroup+560 orders_group 数组 (count@+572) ✓** 逐元建 CArmyItem; 门 = **og+57 field_marshal_group ✓** (双证) |
| CArmyItem (主表槽[8] 0X141E6EDF0 = 真入口 (基槽 CFG 空桩) + TT 槽0 0X141E6A850) | **COrdersGroup idpair@item+112** | 师数文本 = og->vtable[11](); 军徽 frame = **og+288 icon**; 训练/停训/边境冲突三图标 = **og+413/+416/+432** (+432 = 当前边境冲突对象指针定案, 图标窗 ctor 实名 `orders_group_item_border_conflict`); combats 收集走 **CUnit+424 ✓** (§4.18) |

**CArmyLeaderWindow** (陆军将领窗): target = **COrdersGroup/CArmyGroup idpair@win+7048** (与海军 CFleet@+7048 同位同构); 槽[10] 命令出口 = **CSetArmyLeaderCommand {+40 leader idpair / +48 orders_group idpair / +56 bool}** (载荷次序高置信) + 控制台串 "assign_leader"; 备选出口 = **CChangeGroupLeaderDialog** (RTTI 实名)。

**CReassignFullOrdersGroupDialog (重指派整集团军对话框, GUI)**: 三载荷 = **源群列表 @+4104 / 目标群 idpair @+4128 / HQ 撤离列表 @+4136**; 接受 = 有目标直调 sub_140F3FF80 (命令组指派投递器, orderstools.cpp:3125 铁路炮断言; 80B 命令 sub_141837CC0 → 队列 sub_142250B00) / 无目标投 **COrderGroupCommand** + 逐 HQ 投 **CWithdrawArmyHqCommand** (双 RTTI 实名)。

**CLeaderGroupView (将领组视图, GUI)**: 数据源 = gui vtable[25] 对象+112 = **CTheatre\*** (新挂载锚); 枚举链全中 (theatre+152/+164 FM 群 / CArmyGroup+560/+572/+584 / og+57/+92); 行类 = **CLeaderGroupPortrait** (RTTI 实名新收)。

**CNewTheaterGroupItem (新建剧场组行, GUI)**: 宿主 = CTheatreSelector+1752 (loc NEW_THEATER_GROUP); 点击按选择集三分流, 命令全 RTTI 实名: 陆军 **CAssignToTheaterGroupCommand** / 海军 **CSetNavyTheaterGroupForCommand ✓** / 空军 **CMoveAirWingAndAirGroupToAirTheatreCommand** (含 dump 缺函数 raw-bytes tail-jmp 破解两例)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 集团军行 | populate sub_14188C680 | item+32 = CArmyGroup idpair; ag+560/{c@572} ✓ / og+57 ✓ | 逐元建 CArmyItem | army_group_box | 定案 |
| 军行 | 槽[8] 0X141E6EDF0 + TT 槽0 | item+112 = COrdersGroup idpair; og+288 icon / og+413/+416/+432 三图标 (+432 = 边境冲突对象指针, §4.24.3) / CUnit+424 combats ✓ | 师数 = og->vtable[11]() | — | 定案 |
| 军史行 | 槽[13] GetMedalStore | CArmy+1592 ✓; item+40 = CUnitHistoryEntry\*; entry+104 medal def ✓ | 槽[14] = CMedalTemplateItem 工厂 (§4.18.8); 宿主 sub_1416BEE50 ✓ | ASSIGN_COMMANDER_MEDAL_TOOLTIP | 定案 |
| 特质窗 | 槽[7]/[8]/[9] | CUnitLeader idpair@基+120; 四技能 +3928/+3944/+3960/+3976 ✓ | 军官团八元素 = 海军版无此簇的同构差异; skill+440/def DB/def+444 ✓ | unitleader_trait_tree_window | 定案 |
| 将领窗 | 槽[10] | win+7048 = COrdersGroup/CArmyGroup idpair (与海军 CFleet 同位) | **CSetArmyLeaderCommand {+40/+48/+56}** + CChangeGroupLeaderDialog | "assign_leader" | 定案 |
| 增援/升级行 | CDeployBaseItem 主表 24 槽 [19]-[23] 纯虚 (叶类全实现) | cc+3960/+3968 对象+8 ✓ | **CSetCountryReinforcementPriorityCommand / CSetCountryUpgradePriorityCommand {+40 tag / +44 priority}** | — | 定案 |

定案 (五项全解): CArmyItem +1456 = `orders_group_no_order` 控件 (绑定 sub_141E6D9F0 用串 0x1429F10C8; 消费 sub_141E6EDF0) / 历史行槽[13] 返 CUnitHistory (= CUnit 视口 +1576 ≡ CArmy+1592; 常量 1592 = 空 ref 哨兵 = 字段偏移+16) / medal def+1068 = 图标 frame (三处 vtable+176 SetFrame 直证) / gs+784 = 国家指针数组 (sub_140BB48F0 体 `qword_14332F260[98]`) / CSetArmyLeaderCommand 载荷次序 (writer sub_141857C30 键 10423 `leader`→+40 / 63 `group`→+48 / 10283 `deploy_army_hq`→+56 三重互证)。

> **空 ref 回退常量定式 (reader 层通则)**: CRef 取字段的函数形如 `if (ref 空) return <imm32>; else return resolve(ref)+<imm8>;`, 其 imm32 = **同一逻辑字段的空 ref 哨兵** (= 该字段偏移 + 16), **不是第二个字段**。根因 = CRef 解引用返回子对象, 比类基址多 16B (与 sub_1416BEE50 `resolve(...) - 16` 取类基址互证)。本册实例: 1592 (CArmyHistoryEntryItem 槽[13], 真偏移 1576) 与 124 (CAirWing::count, 真偏移 108, 五站点同形)。空路径在运行时不可达 (立即数极小, 真执行即访问页 0), 属编译器保留哨兵。

#### 4.31.37 海战结果窗 (CNavalCombatResults×6 / CNavalCombatMapIcon)

业务侧全收 §4.22.8 (**数据源归属定案: 结果行件 = §4.22.6 报告池 / MapIcon = §4.22.5 进行中战斗**, 两族分离; Line/Item 两级结构; CDispatchNavalCombatResultsCommand 载荷)。

类布局 (类名 / target / 锚点):

**数据源归属定案**: 六个结果行件全读 **§4.22.6 战果报告池** (window+5048 = results 自 refid → +24/+136 双侧 → side+8/+32 容器, 三向互证); **CNavalCombatMapIcon 反向 = 读 §4.22.5 进行中海战** (refid @icon+136) — 两族分离。**Line/Item 两级**: Lost = Line (类型分组行) + Item (每 tag 子行); Survivor = 单层可排序 Item (船按 (型号 index, type) 降序, 机按父 archetype)。**沉船判据 = cached_info.sunk_by 非空; 机以 alive>0/killed>0 双门** (可同进两列)。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CNavalCombatResultsLostShipItem (0x88) | **战果池沉船 SCachedInfo 向量** (+48, 按 tag 分组键+40) | 命中册内 6 处; 新发现 = 布局+"number"/"country_flag" 填充链与 +104 预建 tooltip |
| CNavalCombatResultsShipLostLineItem (0xD0) | 按 sprite 分组的沉船行容器 (**子件池+96 / SCachedInfo 池+120 / sprite 键+144 / pride 件+48**) | 命中 8 处; 新发现 = 分组谓词 sub_141E00CD0 / **convoy 分流 (entry+57→panel+104 池)** / pride 特殊 tooltip |
| CNavalCombatResultsLostAirItem (0x48) | **{equip\*, killed} 16B 向量 (+40)** + tag+68 | 命中 air entry+24/+28; 新发现 = 布局与逐装备 tooltip 生成器 |
| CNavalCombatResultsAirLostLineItem (0x80) | 按装备父 archetype 分组的击坠行 (+48 总数 / **+56 archetype 键 = \*(\*(equip+1008)+1240)** — §4.23 双命中) | 新发现 = 分组链与 "lost_air_grid" 结构 |
| CNavalCombatResultsShipSurvivorItem (0x60) | SCachedInfo 向量 (+32) + **Σbuild_cost_ic (+88 = 降序排序键, 槽[19])** | 命中 cached_info+24/+112; 新发现 = (index,type) 分组与幸存网格混排排序 |
| CNavalCombatResultsAirSurvivorItem (0x50) | **{tag, alive} 8B 向量 (+48)** + archetype+40 + 价值+72 (排序键) | 命中 air entry+20/+28; **价值键定案: +72 u32 = Σ alive×(变体 stats[52]×stats[53]/1e10)** (填充器 sub_141E063A0; stats[52]/[53] = STAT_AIR_NAVAL_STRIKE_ATTACK/TARGETTING §4.31.27) |
| CNavalCombatMapIcon (≥1568B) | **§4.22.5 进行中海战 refid @+136** (与六件反向); 锚省缓存+144 | 9 槽覆写全定名, AddCombatantToGridBox lambda 实名; 命中册内 12+ 处 (combat+24/+32/+136/+144/+264, combatant+56/+216/+232, ship+1832, tf+472/1832/1844); 新发现 = **combatant+218 玩家可见门 / +1464 CTinyUnitCounter 池** / 8 子件布局 |

**命令出口**: 窗口 dispatch 钮 sub_1417D9350 → **CDispatchNavalCombatResultsCommand** (ctor 0X1411446C0, 0x48B; **载荷 +40 = results refid 容器, +64 = 玩家国家 id**) → 命令队列 sub_142250B00。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 沉船行 (Line+Item) | 分组谓词 sub_141E00CD0 | SCachedInfo 向量+48 (tag 键+40); sprite 键+144 | convoy 分流 entry+57→panel+104 池; 沉船判据 = sunk_by 非空 | — | 定案 |
| 击坠行 (Line+Item) | 分组链 | {equip*, killed} 16B 向量+40; **archetype 键 = \*(\*(equip+1008)+1240) ✓§4.23** | 机 alive>0/killed>0 双门 | lost_air_grid | 定案 |
| 幸存行 (单层可排序) | 槽[19] 排序 | SCachedInfo+32 / {tag, alive} 8B+48; **排序键 = Σbuild_cost_ic +88 / 价值+72** | equip+672/680 = CEquipmentVariant stats[52]/[53] (对海打击攻/瞄, 消费 sub_141E063A0) | — | 定案 |
| 海战地图图标 | 9 槽覆写全定名 | **target = §4.22.5 refid @+136**; combatant+218 玩家可见门 / +1464 CTinyUnitCounter 池 | 命中册内 12+ 处 | — | 定案 |
| dispatch 钮 | sub_1417D9350 | **CDispatchNavalCombatResultsCommand {+40 results refid 容器 / +64 玩家国家 id}** | → 命令队列 sub_142250B00 | — | 定案 |

定案 (结构): LostShipItem (CNavalCombatResultsLostShipItem, vtable 0x142A7D310, ctor sub_141E00650) **+48 = 200B 元素向量 / +40 tag / +72 SSO 串一 / +104 SSO 串二 (buf@104/size@120/cap@128)**; ShipLostLineItem (ctor sub_141DFF770) +40 = "equipment" 子件 / +48 = "pride" 子件 / +64/+144/+176 三 SSO / +96/+120 两容器。equip+672/680 = 变体 stats[52]/[53] 已定案 (上行); MapIcon target 管理器写入点转 PN5。

#### 4.31.38 空军剧场+联队行 (CAirTheatreItem / CAirTheatreGroupItem / CAirTheatreGroupRowItem / CAirTheatreWingItem / CAirFreeWingsItem / CAirWingEntry / CAirWingOptionButton / CAirSelectionView)

业务侧全收 §4.31.61 (**CAirTheatre vtable 0x1427E73C0 / CAirGroup = 两新数据类**, 宿主 CTheatreSelector 新锚; 七命令: CRenameAirTheatre / CMoveAirWingAndAirGroupToAirTheatre / CMoveAirWingToAirGroup / CMoveAirGroupAndAirTheatreToFree / CStratAirConsolidate / CStratAirCancelTransfer / CStratAirEnableMission)。

类布局 (类名 / target / 锚点):

**CAirTheatre (vtable 0x1427E73C0) 与 CAirGroup (vtable 0x1429CCF30) = 两独立数据类** (与 §4.24 剧场族不同族; 均 CReferenceObject ← CPersistent):

CAirGroup (sizeof 144 = 0x90; ctor sub_1414EB410; writer sub_1414EC490 / reader sub_1414EBE00 五键互证闭合无遗漏):

| 偏移 | 类型 | 名称 | 键 | 备注 |
|---|---|---|---|---|
| +8 | 指针 | CReferenceObject 域全局 qword_14333D528 | — | |
| +16 | uint8 | 旗 = 0 | — | |
| +32 | uint32 | icon (ctor 默认 1) | 181 恒写 | |
| +48 | CColor 内嵌 32B | color {vtable@+48, 数据 16B@+64} | 86 恒写 | |
| +80 | CString 32B | name (默认 "NEW_THEATER_GROUP") | 27 恒写 | |
| +112 | idpair 8B | air_theatre {id@112, serial@116} | 19949 恒写 | ctor 注册引用 |
| +120 | 匿名结构 (8B 形状) 向量 24B | air_wing 列表 {begin@120, cap@128, count@132, alloc@136}; 元素 8B idpair | 13161 (count≠0 门) | dtor sub_1414EB8E0 |

air_group idpair = {类型 78, serial = ++*(u32*)(*(gs+1680)+40)} (CStrategicAirManager 生成器, §4.15.1 CNonstaticIdGenerator<78> 吻合); group 自身 idpair 不序列化。

CAirTheatre (sizeof 88 = 0x58; ctor sub_1414EB6A0; writer 0x1414EC5A0 / reader 0x1414EBEF0):

| 偏移 | 类型 | 名称 | 键 | 备注 |
|---|---|---|---|---|
| +8 | 指针 | CReferenceObject 域全局 | — | |
| +16 | uint8 | 旗 = 0 | — | |
| +24 | uint32 | 创建时 = 序号解引; 载入路径被键 10394 owner tag 覆写 (字段双用, id 不序列化) | 10394 country | |
| +32 | CString 32B | name (默认 "NEW_THEATER_GROUP", 新建后经 CUnitNamesDatabase 生成器覆写) | 27 | |
| +64 | CAirGroup* 向量 24B | air_group 列表 {begin@64, cap@72, count@76, alloc@80}; 元素 8B CAirGroup*; 键 12227 逐元: reader malloc(0x90) 内联构造 → 槽[3] Load → count≠0 追加否则销毁 | 12227 | |

air_theatre idpair = {类型 77, serial = ++*(u32*)(*(gs+1680)+24)}。
**宿主定案 = CCountry+384** {begin@384, cap@392, count@396, alloc@400}, 元素 8B CAirTheatre*; 块键 19949 由 CCountry 主 writer (sub_1407191B0) / reader (sub_140705CE0) 发射 — **空军剧场组织随国存盘**。

**运行期所有权操作层** (airtheatre.cpp 3 函定案; 全纯运行期无序列化行为, 返回 char 1 成功/0 no-op):

| VA | 实名 | 断言 | 语义 |
|---|---|---|---|
| 0x1414EC290 | CAirTheatre 过继组 | airtheatre.cpp:193 "Air group has to be connected to a theatre" | 组从旧属 theatre+64 保序摘除 → 挂目标 theatre+64 → group+112 = 新 theatre idpair; 组不在旧表返 0 |
| 0x1414EBA00 | CAirGroup::StealWing | :78 "Air wing has a valid air group when another group tries to steal it" | 组+120 翼表查重 → 断言翼当前无组 → wing real+64 = 组 idpair → 翼句柄 push 组+120 |
| 0x1414EBC80 | CAirTheatre::DeleteAirGroup | :216 "Trying to delete an air group from a theatre it does not belong to" | theatre+64 摘除 → group+112 清空句柄 qword_14333D528 → 解析组后 vtable[0] deleting dtor 删除; **本身不摘翼**, 悬挂由调用方契约维护 |

所有权树 = theatre → group → wing 三层 (翼不直接挂 theatre): 翼换组 = RemoveWing
sub_1414EC080 (组+120 保序摘 + wing+64 清) + StealWing 两步, :78 断言守「两步间翼无组」
契约; 组换 theatre = 过继组单步 (翼两级间接无感); 删组 = 调用方先逐翼 EC080 再 EBC80。
调用拓扑: 删翼级联 sub_140F5D8C0 (airwing.cpp:84 断言 "Air wing was connected to an air
group without theatre" — 守 EBC80 契约的运行期校验; 翼出账 → 摘组 → 组空则删组 → theatre
空则移除 → 删翼) / 批量删组收口器 sub_14193F1B0 (首败即停 + 成功条目压实 + 返删除数) /
剧场合并 sub_141945610 (strategicaircommands.cpp:1877 断言; 无目标 malloc(0x58) 经 EB6A0
新建 → `while(源+76 > 0)` 全量过继 → 尾翼列表重挂) / CMoveAirWingToAirGroupCommand 执行体
sub_141945DE0 经批量包装 sub_1414EBC30 调 StealWing。单元地图: 0x1414EB410-EC5A0 连续带
8 函同域 (EB410 = CAirGroup 原位 ctor, `&CAirGroup::vftable'` 符号直证, 布局 +8 idpair/
+16 注册旗/+32 icon/+48 CColor vptr/+80 名 "NEW_THEATER_GROUP"/+112 theatre 句柄/+120 翼表;
EB6A0 = CAirTheatre ctor; EC080 = RemoveWing; EBC30 = StealWings 批量包装)。
断言门通式 = `byte_1435E1B52 && !闩字节` 二重门 (闩 0x14338A764-66 相邻, 每点一发即闩)。

GUI 消费锚 (CTheatreSelector 族, vtable 0x142A10E80):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CAirTheatreItem (air_theatre_item, 1616B, ctor 0X141E5D490) | **CAirTheatre CRef idpair @+48** (来源 = theatre+8 自引用对, 消费经 sub_14221F310) | populate 0X141E60C90 填 name_box/assign_button/air_groups_box/wing_count/selected_frame, 同循环双建 GroupItem+GroupRowItem; 命令 = **CRenameAirTheatreCommand {+40 剧场 ref / +48 新名}** 与 **CMoveAirWingAndAirGroupToAirTheatreCommand {+40 id / +48/+72 双向量 / +96}** |
**CAirTheatreItem 槽位偏移全表** (Populate 0X141E60C90 直证, 1616B):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +16 | GUI 上下文* | CreateWindowByName 宿主 (vtable+104/+112/+120/+128/+136/+184/+240/+432 各建子件) |
| +32 | GUI 上下文* | 行件 ctor 第二参 (GroupItem / GroupRowItem 共用) |
| +40 | uint32 | 计数对 lo (经 ctx vtable+240 原样回写) |
| +44 | uint32 | 计数对 hi — 累加 Σ(行件 vtable+136 返回值 +4) (推定 = 翼数总计, 与 air_wing_count_box 同源) |
| +48 | idpair | CAirTheatre CRef {type@+48, id@+52} (双零时跳过解析) |
| +64 | 窗口* | theatre_name_box (建名串 "theatre_name_box", ctx vtable+128) |
| +72 | 位置数据 | name_box 布局槽 (经 child+128 的 vtable+8 消费) |
| +232 | 窗口* | assign_button (ctx vtable+104) |
| +240 | 位置数据 | assign_button 布局槽 (同 +72 消费形) |
| +1528 | 窗口* | air_groups_box (ctx vtable+184) |
| +1536 | 窗口* | air_wing_count_box (ctx vtable+120) |
| +1544 | 窗口* | selected_theatre_frame (ctx vtable+136; 显隐 = 界面处理器 getter 谓词 → win+117 bit 0x10 配对写) |
| +1552 | 窗口* | air_groups_row_box 分页行盒 (ctx vtable+432) |
| +1568 | CAirTheatreGroupItem* CPdxArray | 集团行件池 {data@+1568, cap@+1576, count@+1580, alloc@+1584}; 元 1400B (malloc 0x578) |
| +1592 | CAirTheatreGroupRowItem* CPdxArray | 集团行行件池 {data@+1592, cap@+1600, count@+1604, alloc@+1608}; 元 1376B (malloc 0x560) |

分页行盒 (air_groups_row_box 对象) 槽位:

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +368 | int32 | 每页上限 A (mode≠0 分支作行数界) |
| +372 | int32 | 每页上限 B (mode≠0 分支作列数界) |
| +384 | uint8 | 布局模式开关 (两分支分页算法不同) |
| +392 | 匿名结构 (条目)* | 条目数组 data |
| +404 | int32 | 条目数组 count |
| +416 | 匿名结构 (行件)* | 行件数组 data |
| +428 | int32 | 行件数组 count |

> 条目入盒 = sub_1402DE9B0(盒, 行件, &位置, 0, 1); +416/+428 与本册「格内 {items@+416, count@+428}」同构 (COperationOverviewWindow 四格互证)。主循环逐集团 (theatre+64 数组, count theatre+76), :282 断言守 group+112 归属, 翼数累加 group+132。
| CAirTheatreGroupItem (1400B, ctor 0X141E5CFD0) | **CAirGroup CRef idpair @+80** (ctor 以 qword_14333D528 空引用哨兵初始化) | 集团 listbox 行: group+32 icon 帧/+80 名/+132 联队数/选中框; 点击 = 选集团; 拖放出口 = **CMoveAirWingToAirGroupCommand {+40 集团 id / +48 联队向量 / +72 集团 ptr}** |
| CAirTheatreGroupRowItem (ctor 0X141E5D230) | 内嵌 GroupItem @+1344 | 集团 gridbox 行: 遍历 group+120/+132 联队按**主装备机型 archetype 分组** (wing+456 池 → variant+1008 _pType → type+1240 父链, 键 archetype+320) 建 WingItem 簇 |
| CAirTheatreWingItem (1416B) (ctor 0X141E5D8A0) | **联队 idpair 向量 @+80 {count@+92}** | 联队簇行: 图标帧 = vtable+176 SetFrame 主装备机型帧; count_box = 簇内联队数; 点击 = 选中簇内全部联队 (无命令) |
| CAirFreeWingsItem (ctor 0X141E5CD60) | **自由联队 idpair 向量 @+40** (判据 = **wing+48/+52 air_group idpair 双零 ✓**, 断言直证) | 内嵌宿主 CTheatreSelector+256; 滤 **wing+108>0 ✓** 且 variant+1032&0x200000000==0 (bit33 = emplacement_gun_ammo, 见节尾定案) 后按机型建 WingItem; 按钮出口 = **CMoveAirGroupAndAirTheatreToFreeCommand** (+40 = 玩家国 actor id, ctor sub_1419408C0, gs+1312/1316 取值法 — 节尾定案) |
| NAirSelectionUI::CAirWingEntry (wing_entry_compact, ctor 0X141CF2440) | **联队 idpair 向量 @+32 {count@+44}** | planes_count = Σwing+108 ✓; 宿主 = CSelectedAirGroupView (populate 0X141CF4230, 超 "wings_compact_number_of_elements" 阈值按机型合簇) |
| NAirSelectionUI::CAirWingOptionButton (ctor 0X141FDAD00; 抽象基, 槽[1][2][3] 纯虚) | +8 = 上下文载荷 / +1304 = 按钮元素 | **派生 8 族定案**: CCreateAirGroupOption / CMergeGroupsOption / CConsolidateWingsOption (→**CStratAirConsolidateCommand**) / CRemoveFromGroupOption / CHoldWingsOption (→**CStratAirCancelTransferCommand** + **CStratAirEnableMissionCommand**) / CSelectAllOption / CSplitSelectionButton / CCloseViewOption |
| NAirSelectionUI::CAirSelectionView (air_selection_view, ctor 0X1416881C0) | CReloadableInterface 子类 | 槽[2] = Update 0X1416884C0; **宿主 5 子件: CMissionToolbarController@+56 / CAirWingsToolbarController@+64 / CAirWingsByBaseView@+72 / CSelectedAirGroupsView@+80 / CQuickWingDeployUIController@+88**; 选择快照 @+104/+128 |

注: 本族 populate 无 statId 消费 (§4.31.27 STAT_AIR 表不适用)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 剧场四级行件 | populate 0X141E60C90 | 剧场 CAirTheatre\*@+48 → 集团 CAirGroup\*@+80 → 联队簇 idpair 向量@+80 | 集团行按主装备机型 archetype 分簇 (wing+456→variant+1008→type+1240, 键 archetype+320) | air_theatre_item | 定案 |
| 自由翼行 | 宿主 CTheatreSelector+256 | **判据 = wing+48/+52 air_group 双零 ✓**; 滤 wing+108>0 ✓ + variant+1032 掩码 | 出口 CMoveAirGroupAndAirTheatreToFreeCommand | — | 定案 |
| 选择视图 | Update 0X1416884C0 | 五子件 +56/+64/+72/+80/+88; 快照 +104/+128 | CAirWingEntry: planes_count = Σwing+108 ✓ | air_selection_view / wing_entry_compact | 定案 |
| 选项钮 8 派生 | 抽象基槽[1][2][3] 纯虚 | +8 载荷/+1304 按钮元素 | Consolidate→CStratAirConsolidateCommand; Hold→CStratAirCancelTransfer+CStratAirEnableMission | — | 定案 |

定案: ToFree 命令 +40 = 玩家国 (actor) id (与 CCreateRaidCommand +40 同源 `gs+1312/1316` 取值法; ctor sub_1419408C0) / variant+1032 bit33 = 装备 capability token 10087 `emplacement_gun_ammo` (reader sub_141C33A80 逐位表直证)。

#### 4.31.39 外交行件 (CDiplomacyCallAllyWarRelationItem / CDiplomacyTradeItem / CDiplomacyIdeaItem / CDiplomacyIncomingLendLeaseItem / CDiplomacyRequestIncomingLendLeaseItem / CDiplomacyRequestIcon / CDiplomacyCountryListRelationEntry / CDiplomacyCountryBaseWarGoalActionController)

业务侧: 战争/关系/战争目标/请求四类收 §4.31.39; 贸易/租借三类收 §4.30.36。命令出口 = CCallAllyAction / CAddWarGoalAction / CGenerateWarGoalAction / CIncomingDiplomaticActionActingCommand (+40 行动 id/+56 accept)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CDiplomacyCallAllyWarRelationItem (diplomacy_call_ally_war_entry; 零覆写 Item 族) | **+1328 = _pWarRelation** (断言互证 + setter 直写; 仅读侧) | tooltip = 战争名 + DIPLOMACY_ATTACKERS/DEFENDERS (country+3976 = CDiplomacyStatus ✓); 点击翻转 item+1340 选中态, 盟友 tag 增删于控制器+2664 选择集, 并整体拷入 **(\*(view+2640 item)+1328) = 待发 CCallAllyAction 的 +120 versus 容器** {d@+120, c@+132, 4B tag} (writer sub_141141350 token 0x294B versus 同构对拍 — 定案; wr+120 在 §4.10.4 war_score 112B 块内, 无容器) |
| CDiplomacyCountryListRelationEntry (diplomacy_country_list_relation_entry; CStandardlistboxItem+COption 三表) | **+80/+84 = 对方国 refid 对 / +88 = 关系类型 token** (图标 `GFX_relation_<名>`) | **关系槽链直证**: country+3976 = dip ✓ → **\*(\*(dip+8)+8×idx)+208 = 槽数组 / +220 = 条数, 元素 24B {+8 token, +16 id, +20 type}** (dip+8 按国索引 ✓) |
| CDiplomacyCountryBaseWarGoalActionController (单表基类, 槽1/7 纯虚) | ctor +8/+16/+24/+32 + 四 vector (+1328..+1400) + map+1424 + 缓存+1480/+1488 wargoal def | 槽4 = ClearView (wargoals_grid/additionals_grid/cancel_button); **派生 Add** (槽7 填格 0X141CA4750 枚举 **wargoal def 库 qword_14332EF28 ✓** → CDiplomacyCreateWarGoalItem) / **Generate** (槽7 目标+144←def); 命令出口 = **CAddWarGoalAction / CGenerateWarGoalAction** (实名); ⚠ dip+104 available_wargoals 消费在 §4.30.12 另族 (槽7=0X141C99DA0), 本族不读 |
| CDiplomacyRequestIcon (CReloadableInterface 派生, 覆写槽[2] Reload; 双窗口 def global_alerticon_window / global_diplorequesticon_window) | **+1368 = 请求对象** (CReference 解引用 ✓) | icon frame = 行动 handler vtable+344 / flag = handler+24 tag; accept/decline 出口 = **CIncomingDiplomaticActionActingCommand {+40 行动 id / +56 accept bool}** (实名定案) |

**CStandardDiplomacyPopup (标准外交弹窗, GUI)**: 工厂 sub_141752E80 按 **CIncomingDiplomaticAction+8 类型 id 四分流** (14027 = 租借 / 19135 = 人力 / vtable[51] = 脚本 GUI / 兜底标准); 载荷 = 消息 idpair @+4064 / 描述 @+4072; 接受/拒绝 = 响应码 2/1 投 **CIncomingDiplomaticActionActingCommand** (与 §4.31.39 CDiplomacyRequestIcon 同命令互证)。**全局活动外交弹窗注册表 = 0x14338B060**。

**CIdeaItem / CNationalSpiritItem (理念/国家精神行, GUI)**: CIdeaItem (0x38B, CStandardGridBoxItem 零覆写族) = 理念行基类 **{+24 CIdea\* def / +32 u32}**, 本体仅作子对象出现 (CGameSetupIdeaItem/CNationalSpiritItem 派生), def 源 = ps+80 ideas ✓。CNationalSpiritItem (0x540B, CTooltipHandler@+0 + CIdeaItem@+8, def 在 +32) = 政治窗国家精神行 (gui spirit_idea_entry[_small], Small/Big 两派生 (**CNationalSpiritItemBig** 1344B/次表 19 槽, 三装配点本册已核)): 真入口 = 非虚 refresh sub_141C47340; 宿主 populate 0X141587A90 以 **def 组过滤 `*(*(def+2720)+96)+120==1`** (def 侧新链) + **cc+3712 动态修正容器计数 ✓**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| CallAlly 行 | setter 直写 | +1328 = _pWarRelation ✓ (仅读侧) | 点击写 **待发 CCallAllyAction +120 versus 容器** (§4.31.39 定案) | DIPLOMACY_ATTACKERS/DEFENDERS | 定案 |
| 国别关系行 | 容器刷新 | +80/+84 对方 refid/+88 类型 token; **dip+8 索引→+208 槽数组/+220 条数, 24B 元 {+8 token,+16 id,+20 type}** | GFX_relation_<名> | diplomacy_country_list_relation_entry | 定案 |
| 战争目标控制器 | 派生 Add/Generate 槽7 | wargoal def 库 qword_14332EF28 ✓; 缓存+1480/+1488 | Add→CDiplomacyCreateWarGoalItem; dip+104 在另族不读本族 | wargoals_grid | 定案 |
| 外交请求图标 | 槽[2] Reload | +1368 请求对象; handler vtable+344 frame/+24 tag | **CIncomingDiplomaticActionActingCommand 载荷定案** | global_[diplo]requesticon_window | 定案 |
| 贸易行 | — | +56 贸易对象 (无 RTTI): +8 资源/+16 注册/+220 frame | TRADE_PRODUCED+64/+32 数量 | diplomacy_trade_entry | 定案 |
| 理念行 | CIdea 共享描述族 | +32 idea 对象/+56 idea id | 空态 DIPLOMACY_IDEA_EMPTY | diplomacy_idea_entry | 定案 |
| 租借行 ×2 | — | +1368 variant\* ✓/+1376 is_fuel; +1360 deal (+24 def = CPurchaseRequest ✓) | cancel 仅翻转选中/摘行, 真命令在 controller 侧 | DIPLOMACY_LEND_LEASE_EQUIPMENT_TOOLTIP | 定案 |

本表 7 行全部定案, 无未决项 (旧计数已销)。

#### 4.31.40 空军地图图标/任务钮/装备明细 (CAirBaseMapIcon / CAirMissionMapIcon / CAirMissionButton / CAirStrategicTargetButton / CAirWingDetailsEquipmentEntry)

业务侧类布局见下 (含三命令: CMoreGroundCrewsCommand / CStratAirSetMissionCommand / 设计器跳转); **CStrategicRegion+88 = 区数字 id 定案** (旧「天气 id」已修正 = 区 id → gs+1672 天气管理器查键, §4.14 +200 行); CStrategicAirManager+144 = per-state 稀疏索引第三址 (§4.15 +144 行)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CAirBaseMapIcon | **省 id u32 @+1424** (同步器 sub_141292300 holder+5800 直写 prov+164, 无 SetTarget) | 解析尾 sub_140C4AF30 = **CStrategicAirManager+144 州基地容器[state+88]** (与 +192 炮位/+168 火箭同形第三址); 五控件 (bg_btn/bg_strat_btn/wings_count/permission_wings_count/_bg) + 内嵌 CAirWingMapStack @+1472; [2]迷雾门/[3]帧表/[4]省锚点同炮族; tooltip = CAirBase 自构 sub_140C54F90 |
| CAirMissionMapIcon | **CStrategicRegion\* @+1424** (创建器 sub_14167F4A0 写 holder+48; **region+96 id** 与 more_ground_crews_enabled 值对象双证) | 7×18 per-任务类型控件阵 (类型 10 = 补给空运); 点击分发槽[23] → **CMoreGroundCrewsCommand** (vtable 0x142A1E448; **+40 国 tag / +44 区 id / +48 开关**; writer 键 10410 = token can_declare_war (键名复用, 语义 = 区 id)); CP 门槛 = cc+496 vs qword_143337C08 |
| NAirSelectionUI::CAirMissionButton (零覆写 Item 族) | widget+8 = 类型 idx | 宿主 = **CMissionToolbarController** (RTTI 实名) 按 18 类型位循环建行; 点击 → sub_1415B8880 逐翼造 **CStratAirSetMissionCommand** (vtable 0x142A1D638; **+40 翼 idpair 容器 / +64 类型掩码 / +68 enable / +69 clear / +70 stop_training_at_max_xp**; writer 键 array/type/enable/clear/stop_training_at_max_xp 互证) |
| NAirSelectionUI::CAirStrategicTargetButton (零覆写 Item 族) | 仅任务类型 bit3/bit16 创建 ("_target_btn", 特性旗门 sub_1401AEB50(14)) | 点击不发命令, 开合 **CStrategicPrioritiesWindow** ("strategic_air_priorities_window"/"bombing_priorities_grid" 实名) |
| CAirWingDetailsEquipmentEntry | **CEquipmentVariant\* @+40** (setter sub_142037220) | 数据源 = **CAirWing 装备池 pool2 {data@+488, count@+500} ✓** (sizeof 0x560 吻合); "count" = amount/1e5 (宿主 Refresh 写); "carrier_capable_icon" 门 = **_pType+1000 字节**; 点击 = sub_141788C50 开装备设计器 (调用方互证); tooltip = OPEN_DESIGNER_VIEW_NOT_FOREIGN |

**CManpowerListItem / CReceivedDamageItem (空军行件, GUI)**: CManpowerListItem (NAirWingReorganizationUI::NInternal, "airwing_manpower_item") = 空军重组窗流亡政府人力行: payload = tag id; 数据源 = **dip+400 governments_in_exile_we_host ✓** (§4.10), AMOUNT = 流亡人力 (**cc+832 ✓**) 或人力块 (**cc+808 ✓**) — 全链命中。CReceivedDamageItem ("air_combat_damage_received", 64B) = **CStrategicAirView** 空战受损分解行 **{+32 damage_type / +40 count_txt / +48 类型枚举 / +56 宿主}**; 24B 源元 {+8 类型, +16 对象} 经 **win+2836 位掩码**过滤, setter sub_141886310。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 基地图标 | 同步器 sub_141292300 | 省 id @+1424; 解析 = SA mgr+144[state+88] | 内嵌 CAirWingMapStack @+1472; tooltip 自构 | — | 定案 |
| 任务图标 | 创建器 sub_14167F4A0 | CStrategicRegion\* @+1424; region+96 id ✓ | 7×18 控件阵; 槽[23] → CMoreGroundCrewsCommand {+40/+44/+48}; CP 门槛 cc+496 vs qword_143337C08 | — | 定案 |
| 任务钮 18 类型 | CMissionToolbarController 循环 | widget+8 = 类型 idx | **CStratAirSetMissionCommand 载荷五键全解** (writer 键互证) | — | 定案 |
| 战略目标钮 | 特性旗门 sub_1401AEB50(14) | 仅 bit3/bit16 创建 | 开合 CStrategicPrioritiesWindow (实名) | strategic_air_priorities_window | 定案 |
| 装备明细行 | setter sub_142037220 | CEquipmentVariant\* @+40; 翼池 pool2 {d@+488, c@+500} ✓ | carrier_capable_icon 门 = _pType+1000; 点击开设计器 | OPEN_DESIGNER_VIEW_NOT_FOREIGN | 定案 |

已结 2 项 (原未决): ①战略目标窗命令出口 = CToggleBombingPriorityCommand {+40 air_wing CRef / +48 building def\*} (§4.31.61 行明文); ②writer 键 10410 复用 = token can_declare_war 键名复用, 语义 = 区 id (行 1234 注)。CMissionMapIconEntry 布局定案: 构建器 sub_1418CB920 写该类 vftable (+0/+56), 依序解析 `missions_list` → `more_ground_crews_bg`(+136 查孙) → `more_ground_crews_icon`(+104 查子件) → `air_mission_mapicon_entry`(行件型) → `button`(+104) → `bg`(+136) → `alert`(+136) → `supply_count`(+120) → `supply_count_small`(+120) → 尾 SetEnabled(+176, idx+1); 表形态 = 主表 0x142A14608 (13 槽) + @56 TListboxItem 0x142A14678 (24 槽)。

#### 4.31.41 生产线行件 (CProductionLineBuildingItem / NavalItem / NewItem / RailwayBuildingItem / RailwayGunItem / RailwayGunRepairItem / ShipRefitItem)

业务侧类布局见下 (**族级: vtable[19]=Populate 真入口基类纯虚 / vtable[21][22]=优先级±1 shift→0/9999 / 槽 31=关闭行→CConfirmDeleteEquipmentProductionLine(s)**; 命令 = CAddConstruction/CRemove(All)Construction/CSetProductionLineAmountToProduce/CChangeRailwayConstructionLeveL)。

类布局 (类名 / target / 锚点):

**族级定案**: **vtable[19] = 每叶类 Populate 真入口** (基类纯虚); **vtable[21]/[22] = Increase/DecreasePriority** (±1, shift → 0/9999 ✓); 基类行引用对 @+2624 / 装备族 @+7888; **槽 31 = 关闭行** (→ CConfirmDeleteEquipmentProductionLine(s) 对话框); 槽 23-30 = 中间层 CProductionLineEquipmentItem 新增的**四叶接口转型 getter 对** (23/24 Naval、25/26 ShipRefit、27/28 Military、29/30 RailwayGun; 默认 ret0 0x140120540, 叶覆写 return this 0x1401F8A60) — 零业务行为 (负定案); 基表实长 23 槽。

| 类 | target/行指针 | 锚点 |
|---|---|---|
| CProductionLineBuildingItem (ctor 0X141D49750, production_building_line_entry) | populate 0X141D647A0 | **行+112 CBuilding\* ✓ / +140 conversion ✓ / +24/+72 ✓**; 命令 = **CAddConstructionCommand / CRemove(All)ConstructionCommand** + 优先级命令 {+40 行 id 对 / +48 新值} |
| CProductionLineNavalItem (ctor 0X141D4C540, production_naval_line_entry[_collapsed]) | 行指针 @+15760 | populate 命中 **行+136 变体/+68/+72/+272 deployment/+248 names 全 ✓**; amount 命令 = **CSetProductionLineAmountToProduceCommand** (+48 ✓) |
| CProductionLineNewItem (ctor 0X141D4D660) | 零覆写占位件 (无成员无绑定) | 模板 military/naval_new_line_entry; tooltip = PRODUCTION_ASSIGN_EQUIPMENT; 点击归视图侧 (未决) |
| CProductionLineRailwayBuildingItem (ctor 0X141D4D6B0) | **与建筑线共用同一模板** | populate 命中 **rail_way path {d@128, c@140} / base+112 / target+116 ✓✓**; 专属命令 = **CChangeRailwayConstructionLeveLCommand** |
| CProductionLineRailwayGunItem (ctor 0X141D4E540) | 行指针 @+13184 | populate = Naval 同构 (无 deployment); **railway_gun 线亦有 names 容器 @+248** (新证) |
| CProductionLineRailwayGunRepairItem | 最小行件 (1 dispatcher + 2 元素) | populate 0X141D677B0 解析 **行+112 引用 → CRailwayGun 单位显名** + 修复进度条; 无自有命令仅跳转 |
| CProductionLineShipRefitItem (ctor 0X141D4F5B0) | deployment = sub_140F71AF0 = **行+248 内联块** (§4.8.2 实证) | **槽 31 自有关闭实现 0X141D5FF20** (ship 在战确认框, 否则 amount=0 命令) |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 建筑线行 | populate 0X141D647A0 | 行+112 CBuilding\* ✓/+140 conversion ✓ | 优先级命令 {+40 行 id 对/+48 新值} | production_building_line_entry | 定案 |
| 海军线行 | populate | 行指针@+15760; 行+136/+68/+72/+272/+248 五锚 ✓ | amount 命令 +48 ✓ | production_naval_line_entry | 定案 |
| 铁路线行 | populate | rail_way path{d@128,c@140}/base+112/target+116 ✓ | CChangeRailwayConstructionLeveLCommand | 与建筑线同模板 | 定案 |
| 铁路炮线行/修理行 | populate 0X141D677B0 | 行指针@+13184; 行+112 引用 → CRailwayGun 显名 | names 容器 @+248 新证; 修理行无自有命令 | — | 定案 |
| 改装线行 | sub_140F71AF0 | deployment = 行+248 内联块 ✓§4.8.2 | 槽 31 自有关闭 (ship 在战确认框) | — | 定案 |
| 新建占位件 | — | 无成员 | 点击 = 基类共享分发器 sub_1422AFB40 (vtable[24] → vtable+64 回调; 该分发器 = CButtonObserverGlue 基表 [1] Dispatch, 事件类型→槽位全表见 §4.00) | PRODUCTION_ASSIGN_EQUIPMENT | 定案 |

定案: 三小函数 = 5 字节 jmp thunk, 本体在 dump 内 (0x141D68400 多分支显隐 / 0x141D60F20 优先级 −1 (MP 分支写 0) / 0x141D60520 优先级 +1 (MP 分支写 9999)) / 槽 23-33 = 基类共享清尾样板 (逐槽清 scoped 指针 + vtable[16]) / NewItem 点击 = 共享分发器 sub_1422AFB40 (vtable[24])。

#### 4.31.42 舰长/历史/改装 (CShipCaptainItem / CShipCaptainWindow / CShipHistoryEntryItem / CShipRefitConfirmationWindow / CShipRefitEquipmentItem / CShipStatsViewAirWingEntry)

业务侧全收 §4.31.44; **舰长数据源定案 = CShip+2120 内联 CHeldOfficer** (IOfficerHolder vtable[1] 双证, 非 +2232 追加向量); **history 容器类名 = CUnitHistory {+16 owner/+24 type/+40 向量}** (§4.16 history 行); 三命令 (CUpgradeShipCaptainCommand / CNavyDetachShipsAndRefitCommand / CGiveMedalCommand) 载荷全解。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CShipCaptainItem (CHeldOfficerItem 子类, 8064B, ctor 0X141ABED80) | **CRef\<CShip\> @+5320** (ctor 拷 CShip+8 refid) | Update 设 ship_icon (**GFX_navy_icon_+舰体名@CShip+232 ✓**) + btn_army 跳特混 (**CShip+1832 = CTaskForce\* ✓ 三证再中**); 槽[20] 雇舰长走 CAcceptCommandDialog + **CUpgradeShipCaptainCommand {+40 CRef\<CShip\>}** (Execute 0X14115FBD0 经 ship+1832→tf+472 取国扣费 ✓); 槽[21] 开 CShipStatsView (10704B) |
| CShipCaptainWindow (CHeldOfficerWindow 子类, 2968B, 复用 "divisioncommanderwindow" GUI) | 槽[9] 枚举玩家全舰 (**国+632 舰队 → tf → 舰**, 逐舰取 **ship+24 IOfficerHolder**) | 槽[10] 造 item; 槽[11] 定制排序 (模式@win+2928); 标题 loc CHOOSE_SHIP_CAPTAIN |
| CShipHistoryEntryItem (CHistoryEntryItemBase 子类, 1456B, 宿主 = CShipStatsView 0X141BF0140) | 存舰 CRef@+1448 | 舰长授勋行 (见 §4.16 history 行注); 命令 = **CGiveMedalCommand {+40 授勋目标 CRef / +56 medal 模板 / +64/+68 i32}** (Execute 0X141156BD0) |
| CShipRefitConfirmationWindow (CDefaultConfirmationPopUpWindow 子类) | ctor 0X141E19620 收 **{舰 CRef 向量@+4096, CShipRefitProductionLine\*@+4120 ✓§4.8, 国 CRef@+4128}** | Setup loc SHIP_REFIT_CONFIRM_TITLE/DESCRIPTION {COUNT / VARIANT_NAME (**line+40 名或 +1008 变体链 ✓**) / DAYS}; OnAccept 筛同 tf 舰 (ship+1832) → **CNavyDetachShipsAndRefitCommand {+40 舰向量 / +64 = tf+24 指挥官 CRef / +72 改装线 CRef / +80 国 CRef}** (Execute 0X141353280) |
| CShipRefitEquipmentItem (CEquipmentViewItem 子类) | **改装生产线元素 @+4056** (line+1008 变体 ✓§4.8); 视图回指 @+4184 | 槽[19]/[20] = 点击动作 (产线队列操作链); 槽[21] Update 消费 line+1032 bit0 / line+1060 状态旗 (§4.8 表外, 推定) |
| CShipStatsViewAirWingEntry (零覆写 Item 族, 80B, ship_stats_air_wing_entry) | **CAirWingPool wings 容器元素 holder** (wing = holder+16, §4.15 全中); entry+40 CRef = \*(holder+24) | 数据链 = **ship+1840 (战略空军管理器式对象, HasAccess(tag) 断言直证 — 新锚)** → 按 tag 取 pool 向量; 行内容 = 主中队装备图标 ("_medium") + 变体名 + 当前/上限机数 + 翼 tooltip |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 舰长行 | Update | CRef\<CShip\>@+5320; ship+232 舰体名 ✓/ship+1832 ✓ | 槽[20] 雇舰长 (扣费链 ship+1832→tf+472 ✓)/槽[21] 开 CShipStatsView | CHOOSE_SHIP_CAPTAIN | 定案 |
| 舰长选窗 | 槽[9] 枚举 | 国+632→tf→舰; ship+24 IOfficerHolder | 排序模式@win+2928 | divisioncommanderwindow (复用) | 定案 |
| 舰史行 (=授勋行) | 槽[13]/[14] | ship+2264 CUnitHistory ✓; 条目+112 awardable/+80 日期 | **+114/+120 本行不消费** (沉船归因归 §4.16.14) | — | 定案 |
| 改装确认窗 | OnAccept | {舰向量@+4096, 改装线@+4120, 国@+4128} | VARIANT_NAME = line+40/+1008 变体链 ✓ | SHIP_REFIT_CONFIRM_TITLE/DESCRIPTION | 定案 |
| 改装装备行 | 槽[21] Update | 线元素@+4056 (line+1008 ✓); line+1032 bit0/+1060 旗 (推定) | 槽[19]/[20] 产线队列操作 | — | 高置信 |
| 舰载机行 | 数据链 ship+1840 (新锚) | holder+16 = wing ✓; entry+40 CRef=\*(holder+24) | HasAccess(tag) 断言; 主中队图标+当前/上限机数 | ship_stats_air_wing_entry | 定案 |

定案: **CUnitHistory 两 ctor 变体 owner 落点不同** — 军侧 sub_141445E90 落 **+8**, 舰侧 sub_141445E00 落 **+16** (两者 vtable 同为 0x1429C1868; 引用本容器须按军/舰分注) / **+108/+124 非两字段**: 124 = 空 ref 哨兵 (= 偏移+16), CAirWing::count 唯一字段在 +108。高置信: CGiveMedalCommand +40 将领 CRef / +48 舰支 CRef (双路径写点 sub_141144CE0 / sub_141144D60)。已结: 条目 icon 类名 = **负定案 (无独立 icon 类)**, gfx 由 def+152 基名 + def+1068 frame 直驱。

#### 4.31.43 特工个人侧 (COperativeBottomBar / BottomBarItem / EmptySlotItem / COperativeLeaderItem / COperativeLeaderWindow / COperativeLeaderRecruitmentWindow / COperativeMapIconEntry / COperativePortraitView / COperativeView)

业务侧类布局见下 (含两命令: CDismissOperativeCommand / CRecruitOperativeCommand); **leader+4224 状态枚举 GUI 显示态分组** (0/2/5=idle / 1=enroute / 3=on_mission / 4=on_operation) 与 **COperation def 双 gfx (+1200 大 = COperativePortraitView SetGfx sub_141E366B0 消费, 定案; +1168 小 = 推定, GUI 消费点全 dump 未命中 — 探针: 对 COperation def (vtable 0x14293F2D8) +1168 下 dr_watch 执行一次任务徽标刷新)** 入 §4.11 对应表。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| COperativeBottomBarItem (2744B, operative_leader_portrait_window; 零覆写 Item 族) | **leader refid@+32** | 13 元素全实名: portrait_btn 点击 = 选中 **CSelectable@leader+3928 ✓**; dismiss_btn (on_mission 才显示) → 确认弹窗 → **CDismissOperativeCommand {+40 leader refid}** |
| COperativesBottomBarEmptySlotItem (1416B, operative_empty_slot_window) | 槽位序号@+96 + std::function 回调@+32 | tooltip 9 条 loc 全录 (OPERATIVE_SLOT_LOCKED/QUEUED/MAX_NUMBER 族) |
| COperativeBottomBar | [2] Update = 脏旗重建 | DoFullUpdate sub_141833030 (lambda RTTI 实名) 池化填槽; 成员全定案: **+2784 招募窗宿主 / +2792 COperativeOrderBar / +2816 operatives_box grid**; **网格同步比较器 (sub_1418329B0, 191 行, operativesbottombar.cpp:361/:362/:436, df303 补)**: 返 1 = 需重建 — 早退脏 = +184 强制脏旗 ∨ +2808 状态门对象 (vtable 槽 29 返回 +4 int ≤ 1, 身份待裁) ∨ +88 期望计数 > 容器计数 ∨ +128 空槽计数 > NumEmptySlotToShow; 成员补行: **+64 期望条目数组 / +88 期望计数 / +104 空槽条目数组 / +128 空槽计数 / +184 强制脏旗 / +188 _DisplayRangeStart / +192 _DisplayRangeSize / +2808 状态门对象**; 比对 = operatives 段**双条件相等** (网格元素指针 == 条目指针 ∧ 条目 refid (sub_140D0D950, 推定 +32) == 源项) + 空槽段指针相等 + 计数精确; 残留元素 → :436 "Untracked elements in gridbox" 断言 (闩 byte_14338B1AA) |
| COperativeLeaderItem (2664B, operativeleaderentry) | **target refid@+2616** | name = **leader+64 ✓** / title = **leader_type@+3708 ✓** / skill = **def+440 ✓** / 国籍 = **leader+3944 ✓**; traits_grid 填充器 sub_141C75BB0 第三参 = **leader+288** (tag_id\*; 值存 CUnitLeaderTraitItem+32, tooltip sub_141C744A0 经 sub_140BB4E70 转 tag 串 — 与 §4.4 tag_id 一致第四证); 点击 → 父窗槽[13] 招募 |
| COperativeLeaderWindow (3184B, operativeleaderwindow; 抽象基 [11][13][14][15] 纯虚) | +3024/+3028 排序状态 (unitleaderwindow.cpp:0xB00 实名) | **19 件排序按钮静态表 off_1430B52B0 全录** |
| COperativeLeaderRecruitmentWindow (四纯虚全实现) | [14] GetCandidates 候选池 | [11] SetupDerived 标题 RECRUIT_OPERATIVE_TITLE; [13] OnRecruit → **CRecruitOperativeCommand {+40 国家 id / +44 候选人 refid}** → gui 事件 "assign_leader" |
| COperativeMapIconEntry | **target refid@+80** | [8] UpdateIcon 肖像 + 回退 GFX_mapicon_operative_unknown + 任务徽标动画; [19] 定位 = **leader+4224 状态枚举分支** (1→+3976 optional / 3→mission impl vtable+72, §4.11.13 双中); tooltip OPERATIVE_NAME_AND_CODENAME {NAME=+64, CODENAME=**+4144**} ✓ |
| COperativePortraitView (2992B) | **target refid@+88** | SetPortrait sub_141E366B0 = 核心填充器 (captured/enroute/mission frame/operation icon 四态; **mission SetFrame = type@+4256 ✓**, operation SetGfx = COperation def+1200); **AttachAsSubWindow (sub_141E354B0, 139 行, df303 补)** = §4.11 挂接契约第二实例 (+216/+456 挂、+224/+464 卸、**锚 = 窗+48 子内容锚点**; 门 = operativeportraitview.cpp:196 "Calling AttachAsSubWindow on a null window" 闩 byte_14338C87E); 成员补行: **+2904 当前控制器 / +2912 挂接窗 / +2968/+2976/+2984 三子元素缓存** = "portrait_overlay_bg"/"mission_icon"/"operation_icon" (operation_icon 磁盘 .gui 实名确证; IDA 将串尾 2B 渲染为 HIDWORD 拼出垃圾 — 失真注明); mission/operation icon 设属主 vtable+552, overlay_bg 不设; 三元素各 vtable+920 刷新 |
| COperativeView | 瘦壳 | [2] populate (重建式: 先清后建) 建 "operative_view" 窗 + 取 "entry_padding" 容器; **持列表管理态** — 父视图@+40 / 容器槽@+56 / _OperativeEntries CPdxArray@+64 / _UsedEntries u32@+88 / 窗@+96 (:140/:145/:146 断言字段名直证, 详 §4.11.13b); 与 BottomBar 同由主 GUI 工厂 sub_140B614C0 挂载 (宿主+488/+464) |

**CNationalitiesBoxItem (特工国籍旗行, GUI)**: (0x30B, operative_nationality_entry): **+32 = nationality tag / +40 = flag_icn**; 数据源 = **operative+3944 nationalities 数组 ✓** (§4.11.2) — 是特工国籍旗行, 与 graphical_culture 族无关。

**CBoostIdeologyMissionItem / CBoostIdeologyMissionWindow (理念提升任务 GUI 族)**: Item (1464B): **+1448 = CIdeology\* / +1456 = "name"**; 副 vtable tooltip 独覆写 (执政党 lambda_2); 宿主 populate = FillPickableIdeologies (lambda RTTI 实名)。Window: **+80/+84/+88/+96 = 任务四参** (与 COperativeMissionData 同构) / **+248 = 选中理念**; send_button 回调 0X1416E5250 → **CSetOperativeMissionCommand {+40 country / +48 operative CRef 向量 / +72 内嵌 mission 数据 type=5+ideology}** (writer 键 country/operative/mission 三证); GUI 事件 "assign_operative_boost_ideology" 实名互证。

**Show 建件表** (Show sub_1416E5580, 每开窗重建; 件型 = a1 索引直读):

| 偏移 | 元素 | 语义 |
|---|---|---|
| +2832 | 窗实例件 | a1[354]; 尾段 vtable+552 注册 |
| +2840 | title 文本件 | a1[355]; 写 loc DIPLOMACY_BOOST_PARTY_POPULARITY_TITLE |
| +2848 | description 文本件 | a1[356]; 清空串 |
| +2856 | send_button | a1[357]; 观察块 @+256 (a1+32) |
| +2864 | cancel_button | a1[358]; 观察块 @+1544 (a1+193) |
| +2872 | additionals_grid | a1[359]; vtable+432 查找 |
| +2880 | additionals | a1[360]; vtable+440 查找 |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 底栏肖像槽 | 13 元素实名 | leader refid@+32; 选中 = CSelectable@leader+3928 ✓ | dismiss → CDismissOperativeCommand | operative_leader_portrait_window | 定案 |
| 底栏重建 | DoFullUpdate sub_141833030 | +2784 招募窗宿主/+2816 operatives_box | 空槽 tooltip 9 loc | OPERATIVE_SLOT_LOCKED/QUEUED/MAX_NUMBER | 定案 |
| 领袖行 | 四锚命中 | refid@+2616; leader+64/+3708/def+440/+3944 ✓ | traits_grid 第三参 = leader+288 (tag_id, 与 §4.4 一致第四证) | operativeleaderentry | 定案 |
| 招募窗 | [13] OnRecruit | **CRecruitOperativeCommand {+40 国家 id / +44 候选人 refid}** | 排序按钮静态表 off_1430B52B0 ×19 | RECRUIT_OPERATIVE_TITLE | 定案 |
| 地图图标 | [8] UpdateIcon / [19] 定位 | refid@+80; leader+4224 分支 (1→+3976 / 3→mission vtable+72 ✓) | OPERATIVE_NAME_AND_CODENAME {+64/+4144} ✓ | GFX_mapicon_operative_unknown | 定案 |
| 肖像视图 | SetPortrait sub_141E366B0 | refid@+88; mission SetFrame=type@+4256 ✓ | 四态填充; operation SetGfx = def+1200 | — | 定案 |

未决 8 项: window+1512 上下文类名 / MapIconEntry 三元素名等。已结 1 项: leader vtable+232 (slot 29) captured 判定 = SetPortrait (sub_141E366B0) captured 分支实际调用点 (dump:1219324), 语义名 func_names 未录 ([21]-[28] 有名)。**活体分表核查**: CArmyLeader vtable+232 = 映像内函数 (RVA 0xC1D5A0), call_u64 直调未俘样本返 0 无异常; **CNavyLeader vtable+232 = 越界读堆地址 (表长 < 30 槽, 无此槽)** — 本槽语义名待裁仅对 ARMY/OPER 表形态成立。另: 本档无被俘将领实例 (ARMY 885 全 +4188=0 / OPER 0), 「被俘返 1」侧未验证; NAVY 三例 +4188 非零系 **CCustomizableBuildingListener+260 假阳性** (CNavyLeader+3928 起为 listener 子对象, 3928+260=4188 — captured_by 语义仅 ARMY/OPER 形态, §4.4)。

#### 4.31.44 海军基地/任务/修理 (CNavalBaseMapIcon / CNavalHeadquarterMapIcon / CNavalBaseSelectionItem / CNavalLicenseEntry / CNavalMissionExtensionEntry / CNavalMissionUnitItem / CNavalRepairWindow)

业务侧: **nb+28 = 修理容量新锚** (§4.16.8 行); **修理队列数据源归属定案 = CStrategicNavy+24 bases → CNavalBase+40/+52 ships_in_repair** (非 §4.8 refit 生产线); **M=\*(gs+1688)+40 = 省 id→CNavalBase RH 表** (sub_140E7C420 解析器); **mission+8 = CTaskForce\* 新锚** (§4.16.5 行); 省 map_obj+4796/+5448 锚点 (§4.14); 建筑库 +232/+244/+832/+844 类别子集 (§4.26.4 building 行)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CNavalBaseMapIcon (工厂 case 8, 层 8) | **省 id @icon+1424** (mapdata 下标 + gamestate 双消费) | populate 命中 CNavalBase+24/+52/+64 ✓ 与 prov+248; **nb+28 = 修理容量** (新锚); **省 map_obj+4796 = 默认锚点 / +5448 = 建筑图标锚点数组** (与 +4568/+4688/+5984 并列); tooltip = NAVAL_BASE_LEVEL 族 |
| CNavalHeadquarterMapIcon (case 31, 层 31) | 同构省 id | 站点 = 省 CBuildingStatus 内经建筑库 **+832 类别容器**匹配且**实例+64 i16 level>0** 的 CBuilding; **帧 3 门 = cc+4016 naval_headquarter_status ✓ 直中**; tooltip = NAVAL_HEADQUARTER |
| CNavalBaseSelectionItem (零覆写 Item 族) | **CNavalBase\* @item+1440**; 宿主 = CHomeBaseSelectionWindow | def+885/+886 旗分控 "naval_headquarter_icon"/"naval_supply_icon" (帧 def+740); 命令 = **CSetFleetHomeBaseCommand {+40 舰队 CRef / +48 省 id / +52=1}** |
| CNavalLicenseEntry | **零覆写类** (主/副 vtable 与 CLicenseProductionEntry 逐槽全同含 dtor) | 与 §4.22.6 CLandLicenseEntry 同族对照成立; 唯一区别 = 窗口名 "request_license_naval_entry" |
| CNavalMissionExtensionEntry (主 vtable 零覆写, 副 vtable tooltip 独覆写) | **mission+8 = CTaskForce\*** (数据源 = S+104 per-region 桶 ✓, 见 §4.16.5 行注) | mission+20 = 任务类型 u32; pride 判定 = ship+1832 == tf 回指 |
| CNavalMissionUnitItem ("unit_counter_navy") | **item+48 = 单位 CRef 数组** | 海军单位堆叠计数器; NNavyMapIconUtils 三 sorter/grouper RTTI 实名; 被 CNavalBaseMapIcon box_ship 修理船条等三处共用; tooltip = NAVAL_SPOTTING_* 五键 + SHIP_ENGAGEMENT_* 键群; +2768/+2776 = "spotting_bar_fg"/"spotting_bar_bg" GUI 子元素指针 (ctor sub_14198CE60 尾调 sub_1419913F0 绑定, 定案) |
| CNavalRepairWindow (0xB78, CTooltipHandler + CReorderObserver 虚基) | 队列 = CStrategicNavy+24 bases → **CNavalBase+40/+52 ships_in_repair ✓** (见 §4.16.8 行注; 非 §4.8 refit 生产线) | 行类 CNavalRepairQueueNavalBaseEntry (行+3904 = nb) / CNavalRepairQueueShipEntry (行+48 = 船 idpair); **命令出口六枚全 RTTI 实名 + 载荷定案**: CSetMaxAllowedRepairDockyards / CChangeNavalBaseRepairPriorityCommand / CSetNavalBaseDisabledForRepairsStateCommand / CReorderNavalRepairQueue / CSwitchNavalRepairDockyard / CAddToOrRemoveShipFromNavalRepairQueue |

**CAccidentItem (海难事故聚合行, GUI)**: "accident_equipment_archetype_entry" (0x560B) = 海难窗事故页逐 archetype 聚合行; setter sub_1417F8460 消费 **56B 聚合元** (源 = CNavalAccidentReport 聚合; **report+32 = is_sunk ✓**); 行件 = 图标/名/双计数四件; 宿主窗实名另见 §4.31.54 CNavalLossesOverview 定案 (另高置信: sub_141901220 装配的海军图标展开面板亦消费本行 — combat_results/accidents/mine_status 三容器簇)。

**NTaskForceCompositionEditor::CNewShipEntryButton (裸名 RTTI 落空, 真名带命名空间)**: = CTaskForceCompositionEditor+8360 静态按钮 (widget task_force_composition_editor_new_entry); 点击 = 翻转 **editor+8352 CSubUnitDefinitionSelectionWindow** 显隐; 纯 GUI 动作, 无命令出口。

**CMissionExtensionEntry (任务扩展行基类, GUI)**: **唯一直系后代 = CNavalMissionExtensionEntry** (§4.31.44); 零覆写族, ctor 0X141DF60A0 定 +32 = host / +40 = "text" / +48 = "btn"; setter 0X141DF6900 写 **+1344 = CTaskForce CRef**; 宿主 populate 数据源 = **战略海军 +104 per-region 桶** (region+88 下标, §4.16.5 ✓✓)。

**CReserveBottomBarItem / CMoveShipItem (预备底栏/移船行, GUI)**: CReserveBottomBarItem (vtable 0X142A78348, 1352B, fleetsbottombar.cpp, navy_reserve_portrait_window): 目标 = **剧场 CRef@+32** (SetTarget 0X141DE7570); 元素 portrait_btn@+1328 / portrait_frame_hightlight@+1336 / taskforce_count@+1344; tooltip RESERVE_FLEETS_FOR_THIS_THEATER; 点击 = 开剧场预备视图, 右键 = 镜头跳转, 无命令。CMoveShipItem (vtable 0x142a4b218, 1440B, move_ship_entry, CMoveShipsWindow 族 ✓): **+48 = 舰 CRef 向量** (AddShip 0X141BBC960); 目标上下文@+40 (其+1464 目标舰队 CRef); 元素 ship_icon@+80 / ship_name@+128 / ship_type@+136 / pride@+72; 点击 0X141BBC3C0 → **CMoveShipsCommand (vtable 0x1429B2780) {+40 舰 refid 向量 / +72 目标 navy CRef / +80 u32 / +84/+85 u8}**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 基地图标 (case 8) | populate | 省 id @+1424; CNavalBase+24/+52/+64 ✓ + nb+28 修理容量 | 省 map_obj+4796/+5448 锚点 | NAVAL_BASE_LEVEL 族 | 定案 |
| HQ 图标 (case 31) | 站点匹配 | 建筑库+832 类别容器 ∩ 实例+64 level>0; **帧 3 门 = cc+4016 ✓** | — | NAVAL_HEADQUARTER | 定案 |
| 母港选择行 | 零覆写 Item | CNavalBase\* @+1440; def+885/+886 旗分控 | **CSetFleetHomeBaseCommand {+40/+48/+52=1}** | — | 定案 |
| 许可行 | 主/副 vtable 全同 CLicenseProductionEntry | 零覆写对照成立 | 仅窗口名异 | request_license_naval_entry | 定案 |
| 任务扩展行 | 副 vtable tooltip 独覆写 | S+104 桶 (region+88 下标) → mission+8 = CTaskForce\* | pride = ship+1832 == tf 回指 | SPECIFIC_NAVY_CONTAINS_PRIDE_OF_FLEET | 定案 |
| 单位堆叠计数器 | NNavyMapIconUtils 三 sorter/grouper | item+48 = 单位 CRef 数组 | 三处共用 (修理船条等) | NAVAL_SPOTTING_*/SHIP_ENGAGEMENT_* | 定案 |
| 修理窗 | CReorderObserver | 队列 = CNavalBase+40/+52 ✓; 行+3904 = nb / 行+48 = 船 idpair | **六命令全实名** (SetMaxAllowedRepairDockyards/ChangeNavalBaseRepairPriority/SetNavalBaseDisabledForRepairsState/ReorderNavalRepairQueue/SwitchNavalRepairDockyard/AddToOrRemoveShipFromNavalRepairQueue) | — | 定案 |

本表 7 行全部定案, 无未决项 (旧计数已销)。

#### 4.31.45 地图图标散件 A (CCapitalMapIcon / CVictoryPointMapIcon / CRadarMapIcon / CResourceMapIcon / CResourceMapIconItem / CStrategicLocationMapIcon / CSupplyNodeMapIcon / CResistanceComplianceMapIcon)

业务侧全收 §4.30.27 (**基类 +112 = 层可见性缓存新锚** / 工厂 case↔类映射补齐 7 项 / CTooltipHandler 副vtable = 2 槽 / 州·省地图对象位置与可见字段 — 均无 RTTI 名); 创建/target 写入点未定位 (推定在管理器 Update ICF 内联, 未决首项)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 首都图标 (14) | populate | +152 CState\*/+160 首都省 CRef ✓; +172 模式旗 | SetFrame 归属四色 | — | 定案 |
| 胜利点图标 (2) | 帧计算 | +152 CProvince\*; 省+392 ✓/省+56 ✓ 对阈值表 qword_143338A70 | 大 VP 远焦可见 | — | 定案 |
| 雷达图标 (17) | 存在谓词 | +136 省 id; cc+4344 CRadarsPool ✓ | 站+88 等级 vs 最大 | RADAR_ONMAP_TOOLTIP/_DAMAGED | 定案 |
| 资源图标 (3) | 近焦门 dword_1433342A0 | +128 CState\*; +160 数量数组 × def+216−1 ✓ | 唯一无 CTooltipHandler; Item = listbox 派生非图标 | resources_list | 定案 |
| 战略要地图标 (33) | SetGfx | +136 = st+2048 对第二 u32 ✓ | "GFX_strategic_location_*" 拼名 | STRATEGIC_LOCATION_MAPICON | 定案 |
| 补给节点图标 (26) | 五回调束 ×1288B | +6576 CProvince\*; +6584 变体旗 | 五按钮五键全定名; 点击走控制器非裸 CCommand | SUPPLY_NODE_* ×5 | 定案 |
| 抵抗顺从图标 (20) | populate (map mode 6/7) | +136 CState\*; st+616 ✓ cr+528/+552 ✓ | 内嵌 ModifierEntry 列表逐修正建行 | resistancemapicons.cpp 实名 | 定案 |

未决: 八类创建/target 写入点 (CCapitalMapIcon / CVictoryPointMapIcon / CRadarMapIcon / CResourceMapIcon / CResourceMapIconItem / CStrategicLocationMapIcon / CSupplyNodeMapIcon / CResistanceComplianceMapIcon; 推定在管理器 Update 内联 ICF) — 余项计数已销 (本表 8 行全部定案)。

#### 4.31.46 设计师子项 (CDesignerAdjusterItem / CDesignerDivisionItem / CDesignerDivisionSlotItem / CDesignerNewTemplateItem / CDesignerStatItem / CDesignerSubUnitItem / CDesignerSubUnitTypeItem)

业务侧类布局见下; **§4.30.2「+632 经验差价」悬念定案 = 命令载荷 cost 字段** (Create+632 raw / Update+640 fixed5; Execute 0X141B9EAE0/0X141B9FAE0); **dump thunk 归属错位三处已字节级纠正** (0X1414A31A0/EA0/EB0 → 0x141761da0/0x141763c20/0X141763BA0)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CDesignerAdjusterItem (440B, designer_adjuster_entry[_with_modifier]; 主 vtable 0x1429C9630, [0] dtor 0x14149BE80; ctor sub_141498500) | **内嵌 CUnitAdjuster@+224 + 调整器 lexer token id@+232** | 地形调整器行: night/fort/river/amphibious/snow 五行挂 **view+11936/+11944/+11952/+11960/+11968** ← id **11944/11947/11946/11945/12036** + 动态列表 **view+11304 data / +11312 cap / +11316 count** (列表源 = 调整器库 库+64 数据 / +76 count, 元素+8 = lexer token id); 三列窗 (movement/attack/other) +264 统计组 + 图标链 GFX_adjuster_<tok>_bg; tooltip 0X14149FF70; Setup sub_1417645E0 |
| CDesignerDivisionItem (1328B, designer_division_entry) | **模板对象@+1320 (+24 名/+460 过滤旗)** + view@+1312 | 点击 thunk 0x1414a31b0 **字节级解码** = 0x141763c20 尾跳 → sub_141763C40 → sub_14168D4C0 (**ES: 模式=2 装载草稿** ✓ view+11096); ⚠ dump 对 0X1414A31A0/EA0/EB0 三 thunk 函数体归属错位, 已用 exe 原始字节纠正 (真实目标 0x141761da0/0x141763c20/0X141763BA0) |
| CDesignerDivisionSlotItem (1392B) | **CSubUnitDefinition\*@+1328** + view@+1320 | **+1336 = 打包坐标 (lo 槽号/hi 列号) / +1348 槽型 (0=regiment / 1,2=support) / +1344 状态**; 回调 sub_1414A31E0 = 拖拽总入口 (view+11336 拖拽槽 ✓); tooltip 0X1414A0930 栈上双 0x678B 统计对象与 ES+2280 预览对比 ✓ |
| CDesignerNewTemplateItem (1416B, 复用 designer_division_entry) | **克隆 std::function (+1320 内嵌/+1376 指针)** | 点击 = _Do_call → 设计器侧 sub_14175DCE0 (新建草稿进 ES) / 列表侧 lambda_1 (CArmyDivisionListView, 开设计器) 双源定案 |
| CDesignerStatItem (88B, designer_stat_entry) | **statId@+32 (哨兵 78)** | **三直证命中**: 预览+160 起 8B/项 × statId ✓ / ES+600/2280/2288 三预览对象 ✓ / 红绿增量 = 新旧差 ✓; **27 行 statId 簿全录** (特例行: 22 = 战斗宽度 / 23 = 人力@预览+1424 / 24 = 训练@预览+1440 — 新发现) |
| CDesignerSubUnitItem (≥1352B, designer_subunit_entry) | def@+1328 + view@+1320 + **每行 0x678B 统计预览缓存@+1336** (ctor sub_141018D00 ✓ 同类) | **宿主 = CDesignerBattalionsWindow** (新归属定案; +1376 = 设计器视图/+1392 = 选中类别); 三回调 (点击取消选中/拖放落槽/整列填充) 全链; **def+1461 = 可空降旗** |
| CDesignerSubUnitTypeItem (≥1328B, designer_subunit_category_entry) | **类别 lexer token id@+1320** + 宿主@+1312 | populate sub_1414A7CB0 = "group_<tok>_title" + GFX_group_<tok>_icon (SetGfx vtable+728 / SetFrame vtable+176 ✓) + NEW_GROUP_ADDITIONAL_COST 红绿费用; designeritems.cpp:1959 实名 |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 地形调整器行 | tooltip 0X14149FF70 | CUnitAdjuster@+224 + token@+232 | 五行挂 view+11936..+11968 | GFX_adjuster_<tok>_bg | 定案 |
| 编制模板行 | 点击→sub_14168D4C0 | 模板@+1320 (+24 名/+460 过滤旗); ES 模式=2 装载 ✓ | thunk 字节级解码纠正 | designer_division_entry | 定案 |
| 槽位行 | 拖拽总入口 sub_1414A31E0 | +1336 打包坐标/+1348 槽型/+1344 状态 | tooltip 双 0x678B vs ES+2280 对比 ✓ | view+11336 拖拽槽 ✓ | 定案 |
| 统计行 | statId@+32 | 预览+160+8×statId ✓; **特例行 22/23/24** (战斗宽度/人力@+1424/训练@+1440) | §4.31.27 statId 表同族 | designer_stat_entry | 定案 |
| 子单位行/类别行 | populate sub_1414A7CB0 | def@+1328 + 0x678B 缓存@+1336 ✓; 类别 token@+1320 | **宿主 = CDesignerBattalionsWindow 新归属**; def+1461 可空降旗 | NEW_GROUP_ADDITIONAL_COST | 定案 |
| 新建模板行 | _Do_call | std::function +1320/+1376 | 双源: 设计器 sub_14175DCE0 / 列表 lambda_1 | — | 定案 |

本表 6 行全部定案, 无未决项 (旧计数已销)。

#### 4.31.47 地图图标散件 B (CCryptologyMapIcon / CIntelLedgerMapIcon / CIntelLedgerResourceEntry / CConstructionInfoMapIcon / CStateModifierMapIcon / CAdjacencyRuleIcon / CPeaceMapIcon / CCounterintelligenceMapIconEntry)

业务侧全收 §4.30.28 (**基槽[3] = 帧级 Update/populate 分发定案** / +108 兼作 icon type / **州·省地图对象双查表: vtable+120=州 (pos+112, 迷雾+124) / vtable+128=省 (pos+4568, 迷雾旗+5985 bit1 双证)** / 工厂 case 补 4/15/16/22/23/24/28)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 密码战图标 (24) | 槽[6] 门 | tag@+2756; cc+4120 首都 ✓/cc+1156 contested ✓ | **CStartStopDecryptionCommand / CActivateActiveDecryptionBonuses** | CRYPTO_* ×8 | 定案 |
| 账本图标 (22/23) | revision 门 | CState\* 向量@+144; 单例 qword_14338B4C0 | 14 widget + 空海任务行表; 无 tooltip | missions_grid | 定案 |
| 账本资源行 | 零覆写 | +32 资源 def ✓; 帧 = def+220 ✓; **+88 = C2dPieChartTemplate 饼图** | NO_INTEL 门 | TRADE_PRODUCED/IMPORTED/EXPORTED | 定案 |
| 建造/厂转图标 (4) | 点击 | 州 id@+136 + 转换对象@+176 | **CConvertFactoryCommand 双向** (sub_1409D5740/89F0 门) | STATE_CONVERT_BUILDING{FACTOR,…} | 定案 |
| 州修正图标 (28) | populate | CState\*@+128; **遍历 st+1968/+1980 dynamic_modifier ✓** (非 st+2256 哈希) | 最小派生, 无 tooltip | modifiers_list | 定案 |
| 邻接规则图标 (16) | hover sub_140B6C5E0 | CAdjacencyRule\*@+1432 + 省对象@+1440 | 位置 = 省地图对象+4568 + 规则偏移; 高亮海峡 | 规则名 HEADER | 定案 |
| 和会割让图标 (15) | 无自有点击 | 州 id@+136; 双行表 CResourceEntry/CNegotiatorFlagEntry | tooltip = sub_1419E5540 处置预览; peacemapicon.cpp:65 实名 | PEACE_HIDE_MAP_ICON | 定案 |
| 反情报行 | 槽[19] | tag@+88; 目标国首都省 | **define COUNTERINTELLIGENCE_ACTIVITY_LEVEL_THRESHOLD_COLORS 着色数组** | AGENCY_DEFENSE_LEVEL_DESC 等 | 定案 |

未决 8 组: 三类 ICF populate 逐值链 / CI 反情报记录对象类名 / CAdjacencyRule 布局 / 和会会话对象类名。

#### 4.31.48 师行件 (CDivisionCommanderWindow / CDivisionLeaderItem / CDivisionLeaderMedalItem / CDivisionEquipmentTypeItem / CDivisionEquipmentItem / CDivisionNamesContainerItem / CDivisionTemplateNamedItem)

业务侧类布局见下 (**CHeldOfficer 基类族三军同构定案**: 师版与舰版逐槽同构; **CArmy+192 = COrdersGroup\* 定案** (member 视口 +8 回指, reader 写入侧 RTTI 钉死); **CArmy+824 = 师版 CHeldOfficer 内联定名**); 命令 = CUpgradeDivisionOfficerCommand / CSetDivisionNameCommand / CSetObsoleteDivisionTemplateCommand / CRemoveDivisionTemplateCommand / CCreateConveyorCommand / CReorderTemplateListCommand 载荷全解。

类布局 (类名 / target / 锚点):

**CHeldOfficerWindow/Item 基类族三军同构定案**: 师版 (CDivisionCommanderWindow/CDivisionLeaderItem) 与舰版 (CShipCaptainWindow/CShipCaptainItem, §4.31.44) 逐槽同构; 师版嵌于 CCountryArmyOfficerCorpView **+8584**；军官团视图五窗块 (army 8536→+8568 / captured 8544→+8576 / division 8552→+8584 / navy 8560→+8592 / ship 8568→+8600, ctor 子件 sub_1416F62F0) 统一 +32。
**CCountryArmyOfficerCorpView::SetupDerived** (sub_1416FC350, 663 行; 控件创建/缓存布局, 与五窗块表相邻):

| 偏移 | 类型 | 语义 | 证据档 |
|---|---|---|---|
| +40 | 上下文对象指针 | 四控件 vtable+552 调用第二参 (视图空时传 0); 推定 位置/父级锚点 | 推定 |
| +1408 | 容器 (40B 元) | 行容器 {data@+1408, 分配器@+1424}; 容量按全局 qword_143338614 对齐, 40×1.5 扩容 | 定案 |
| +1432 | 对象 | army 分支容器 (feature 门 34) | 定案 |
| +1496 | 对象 | navy 分支容器 (名 "navy") | 定案 |
| +1560 | 对象 | air 分支容器 (名 "air") | 定案 |
| +1624 | 容器 (1440B 元) | 学说文件夹按钮容器 {data@+1624, 分配器@+1640}; 元素 ctor sub_1416F6D70, 清零 0x5A0B | 定案 |
| +1648 | CWindow* | 主窗 command_character_view_window (0x1210B) | 定案 |
| +5552 | 观察者对象 | button_captured_generals (sub_1422DC710 建观察 + sub_1422DD480 注册; lambda_1/lambda_2 回调) | 定案 |
| +8608 | CWindow* | armyhqtemplatewindow (0xFF8B; feature 门 57; sub_141D25AF0 创建, 入参 +9984) | 定案 |
| +8616 | 观察者对象 | button_army_hq_templates_toggle (lambda_3 回调) | 定案 |
| +9992 | 控件 | captured_generals_amount (主窗 vtable+120 按名抓取) | 定案 |
| +10000 | 控件 | deployed_hq_icon (主窗 vtable+136 按名抓取) | 定案 |
| +10008 | 控件 | deployed_counter (主窗 vtable+120 按名抓取) | 定案 |

> 建窗序: 取本地化上下文 → 建主窗落 +1648 → 初始化 → 行容器扩容/逐行构建 (数据源 = 全局 qword_143338608 32B 元数组, 键表 qword_14338AED8/dword_14338AEE4 经 sub_14011D540 匹配)。feature 门 sub_1401AEB50: **34** → 建三军分支容器; **57** → 建 armyhqtemplatewindow + 切换钮 (与 §4.24 国默认 HQ 模板 feature gate 57 同门互证), 门假 → 隐藏容器 (控件 +165 \|= 0x10)。学说文件夹行: 遍历 sub_140322E60() 表 (+80 数据/+92 计数), 每项 token 经 sub_1424BC260 转名 → sub_1422BA420 按名查控件; 查不到 → CLogStream 错误 :765 "Missing button for doctrine folder in officer corps view" (仅记录, 该项跳过); 查到 → memset 0x5A0 + ctor + 落行。主窗 vtable+120 / vtable+136 = 按名抓取控件两 finder 槽; sub_1422BA420 = 上下文按名解析 (空对象返 NULL = 缺控件错误的判定源)。
> 未决: feature gate 34 对应的 DLC/功能名 (57 已知与 HQ 模板同门) / 三全局表身份 (qword_143338608 行数据源 / qword_14338AED8+dword_14338AEE4 键表 / sub_140322E60() 学说文件夹表) — 形态定案, 身份待裁。


| 类 | target 形态 | 锚点 |
|---|---|---|
| CDivisionCommanderWindow (2968B, CHeldOfficerWindow 师版子类) | 覆写 [8] 标题 CHOOSE_DIVISIONAL_LEADER / [9] 枚举 (**cc+656 师容器 → CArmy+824 CHeldOfficer ✓✓**) / [10] 造 CDivisionLeaderItem / [11] 定制排序 (模式+2928) | 与 CShipCaptainWindow 逐槽同构 |
| CDivisionLeaderItem (8064B, CHeldOfficerItem 子类) | **CRef\<CArmy\> @+5320** (与舰长行同位 ✓) | 槽[20] 雇师长 = **CUpgradeDivisionOfficerCommand {+40 师 CRef / +48 u32 1}** (Execute 计费链实证); 槽[21] 开 CArmyDivisionStatsView; btn_army 跳所属军群 — **CArmy+192 = COrdersGroup\*** (= CUnit+184 COrdersGroupMember 视口 +8 回指; 写入侧 reader sub_140BF30A0 `*(unit+192)=this` RTTI 钉死 + CArmyDivisionView btn_army sub_1416A9430 双证 — 定案) |
| CDivisionLeaderMedalItem (1352B, division_medal_entry) | **已授勋章展示行** (与 §4.18.8 授勋列表划界) | entry+104 def ✓ / **def+152 icon / def+1068 frame 两消费槽全中 ✓**; populate 源 = **CArmy+1592 army_history ✓** + **u32@CArmy+480** (消费实证 = logical_country, 与 §4.18.1 +480 行借调东道国比对同源) |
| CDivisionEquipmentTypeItem (1352B) | **CEquipmentType\* @+1328** (池条目+1008 _pType ✓); 组头行刷新 0x141DD3220 增补: **item+1320 u8 is_allowed 旗 / +1344 匹配键 CRef**; 类型对象新读 **+28 CRef** (与 +1344 比对: 相等或双方非零过 sub_140BB52F0 容差) / **+1068 niche 计数 int**; is_allowed_button = vtable+176 SetNumber((allowed)+1) 帧 1/2; equipment_niche_icon = niche 非零 ∧ CRef 匹配 → Show + SetNumber(计数+1) 否则 Hide; equipment_icon = sub_140B46320(ctx, win, type, **"_medium"**) 尺寸变体通道 (与 §4.31.107 sub_140B45860 同族, 失败 → divisionequipmentview.cpp:161 "Failed to apply equipment type to button" 断言 闩 byte_14338C716); name 子窗 SetText ← sub_140BDB510 显示名 | CDivisionEquipmentView archetype 组头行; "toggle_collapse" 折叠组; tooltip REINFORCE_WITH_TYPE_OF_EQUIPMENT / EQUIPMENT_TYPE_FORBIDDEN |
| CDivisionEquipmentItem (1352B) | 装备池条目 @+1328 (**cc+3944 CProductionStatus 扁平池 ✓**) | 行内容 = is_allowed / niche 图标 / equipment_icon ("_medium") / 名称 |
| CDivisionNamesContainerItem (1352B) | **{+1336 CNameGroup\* / +1344 备选条目}** | CDivisionNamesContainer dropdown 名字组行; 数据源 = **cc+112 CNameGroupTracker ✓**; 点击落 **CSetDivisionNameCommand {+40 师 CRef / +80 名 token / +85 组旗}** |
| CDivisionTemplateNamedItem (6616B) | **CDivisionTemplate\* @+6600** (**cc+440 容器 ✓**, 四重过滤含 +564/+566/+460); +6592 / +6612; 元素行 +32..+144; 宿主行池 | CTemplateDeploymentWindow 模板行; **命令出口四枚全 RTTI 实名**: CSetObsoleteDivisionTemplateCommand / CRemoveDivisionTemplateCommand / CCreateConveyorCommand / CCreateDivisionTemplateCommand; 宿主拖排 = **CReorderTemplateListCommand {+40 模板 CRef / +48 新索引}**; **add_template_button 元素 (+104, 胶水 +2728) 点击 = sub_141D2ADE0** — 主路 sub_141BA11B0 (Conveyor) {+40 模板 CRef / +48}, 备路 sub_141B9E400 |

**CChangeUnitTemplateDialog (换模板对话框, GUI)**: 载荷 = **目标模板 idpair @+4104 + 单位列表 @+4112 {count@+4124}**; loc = CONFIRMCHANGE_UNIT_TEMPLATE / CONFIRMCHANGE_HQ_TEMPLATE 系列 (HQ 判定 sub_141CFCB60); 接受投 **CSetArmyTemplateCommand**。

**CHqTemplateNamedItem / NCombatLogView::CDivTemplateItem (GUI 族)**: CHqTemplateNamedItem (vtable 0x142a6ab38, 仅 dtor 覆写) = 军官团视图 "armyhqtemplatewindow" 的 HQ 模板行: item+3976 父窗 / **+3984 = CDivisionTemplate**; 消费 **d+396 priority+1 SetFrame ✓ / d+436 is_army_hq ✓ 双命中**, 新读 **d+376 = 部署天数**; 出口 = 选择 (changer+2600) / 编辑 (0X141763C40 与 §4.30.2 同函数 ✓) / 删除 (**CRemoveDivisionTemplateCommand** 实名)。**「HQ 模板」本体 = CDivisionTemplate 的 is_army_hq 子集, 非独立类** (定案)。NCombatLogView::CDivTemplateItem (vtable 0x1429F1348) = 战斗日志窗师模板统计行 (combat_log_div_template_item): **+112 模板 CRef / +120 胜场 / +124 参战** (num_won = fixed 百分比胜率); 点击跳模板设计器 (同 0X141763C40 链), 无命令 — 与 §4.30.2 部署窗模板行边界划清。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 师长选窗 | [9] 枚举 | cc+656 → CArmy+824 CHeldOfficer ✓ | 嵌于 CCountryArmyOfficerCorpView **+8584** | CHOOSE_DIVISIONAL_LEADER | 定案 |
| 师长行 | 槽[20]/[21] | CRef\<CArmy\>@+5320 (舰长同位 ✓) | CUpgradeDivisionOfficerCommand {+40/+48} | — | 定案 |
| 勋章展示行 | populate | entry+104 def ✓/def+152/+1068 ✓; CArmy+1592 ✓ + CArmy+480 (logical_country) | 与 §4.18.8 授勋列表划界 | division_medal_entry | 定案 |
| 装备组头/条目行 | — | CEquipmentType\*@+1328; cc+3944 扁平池 ✓ | toggle_collapse 折叠 | REINFORCE_WITH_TYPE_OF_EQUIPMENT | 定案 |
| 名字组行 | 点击回调 | +1336 CNameGroup\*/+1344 备选; cc+112 ✓ | CSetDivisionNameCommand {+40/+80/+85} | — | 定案 |
| 模板行 | 四重过滤 | CDivisionTemplate\*@+6600; cc+440 ✓ (+564/+566/+460) | 四命令 + CReorderTemplateListCommand | — | 定案 |

定案: CCreateDivisionTemplateCommand 载荷 = +40 CDivisionTemplateData 584B (键 12112) / +624 国 tag (10394) / **+632 i64 经验 (键 10323 `cost`, writer sub_141BA0B70 走 i64 十进制通道 sub_1424C34F0)** / +640 CRef (12462); GUI 调用点 sub_141D2ADE0 传 (data, 0, tag) → +632 = 0, 即 +632 由调用点赋经验值, 非「备路模板指针」。未决: CArmy+480 语义第三读法核对 / 副产骨架四类 (CDivisionEquipmentView/CTemplateDeploymentWindow/CDivisionNamesContainer/CHqTemplateNamedItem)。

#### 4.31.49 战斗日志/历史 (CCombatLogView / NCombatLogView::CCombatItem / CCombatantEntry / CCombatantReserveEntry / CCombatantSideModifierIconEntry / CCombatHistoryEntry / CHistoryEntry / NIndustrialOrganisation::CHistoryItem)

业务侧全收 §4.31.37 (**数据源归属: 日志窗读 gs+2176 NCombatLog::CManager 池, 不读 CCombatHistory** / **cb+8 旗位段位义定案** (八值枚举 {2,7,10,13,27,8,17,16→图标0-7}) / CCombatHistoryEntry 本体+gs+648 链表头 / CHistoryEntry = 场景历史抽象基 vtable[13] 纯虚 Apply); **族级: 8 类零 CCommand 出口**。

类布局 (类名 / target / 锚点):

**数据源归属定案**: CCombatLogView **不读 CCombatHistory** — 读 **gs+2176 NCombatLog::CManager → COrdersGroupLogs → combat_data_index → combat_data_entry 池** (§4.22.4 全命中)。**CCombatHistoryEntry = §4.22.4 战斗历史条目类本体** (writer 0X140BBAF10 token end_date/attacker/defender/type/location 直证); **CHistoryEntry = 场景历史抽象基** (CPersistent 直系, writer 空桩, **vtable[13] = 纯虚 GetToken** (country 族返 10394); **vtable[17] = Apply** (基 sub_140A3D610 树递归, 历史执行驱动 sub_140A3D2A0 按 from<date<=to 日期窗派发); +8 CGameDate 日期 / +32/+40/+48 子条目侵入链表; 18 派生全为 country/state 开局历史族) — 与 CCombatHistoryEntry 平级兄弟而非父子。**族级: 8 类零 CCommand 出口** (全按钮 = GUI 直调/地图选中)。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CCombatLogView (combat_log_view, ctor 0X1416E8680; 界面注册名槽 qword_1430B3D98, 静态初始化 sub_14007DA40) | view+1376 内嵌 **NCombatLogView::CPage** (0xBB0, 构建器 0X1416E9BC0) | Update = 主 vtable[2] 0X1416F0D20 + vtable3[6][7]; CPage 三 tab + 双滑条 + filter_button 全元素定案; view 成员 +72 钮派发阵 / +1360 host / +1368 窗 / +1376 CPage\* / +1384 目标国 idpair (哨兵 qword_14333D528) / +1392 导航表; 数据源见上归属定案 |
| CPage log_month_slider | 构建器取 page+1376 (vtable+448) | **page+1376 滑条 / +1384 观察器胶水**; 量程 = 100000 × page+2940; 值回调 sub_1416EF240 (`page+2940 = (int)slider f32` → 重过滤重泵) |
| CPage max_log_months | define dword_143336458 (键 COMBAT_LOG_MAX_MONTHS) | **page+2940 u32**; 文本 setter sub_1422CAA00; 月窗消费链 = 主泵 sub_1416EF860 (`sub_140164350(&d, −*(v1+2940))`) + COrdersGroupLogs 族 sub_140CDD370 / sub_140CDD3D0 / sub_140CD6A90 三函数直读 define |
| CPage 其余元素 | 构建器 | `combats_slider` page+2976 / filter page+1624 + 胶水 +1632 / period page+1504 |
| CPage 战斗列表填充/裁剪 (0x1416F2E30, 205 行, combatlogview.cpp:1591 断言 "Combats in the log view - bug in code. Should not happen." 闩 byte_14338AEC6) | **+1616 行件容器** {+368 {u32 旧值, u32 需求行数} 行数账目 / +404 计数器 / +416 行件指针数组 / +428 计数 / vtable+632 移除后置钩子} / **+2952 战斗源 16B 元数组** {combat_data_entry 指针@+0, u8 player_is_attacker@+8} / **+2964 可见行上限** / **+2976 combats_slider** (内嵌 +128 控件: vtable+40 设区间 denom 恒 100000 = 0x29F16B11C6D1E109>>14 倒数乘法 / vtable+32 取 f32 / vtable+56 设值) | 需求行数 = (sub_1422DEEA0+4)÷(sub_1422DF180+4) 回写 +368 → clamp +2964 → 滑条显隐/区间/值维护 → 按滚动偏移填行: 源 16B 元 → 复用池行 (item+32/+40 与 CCombatItem 同槽 ✓) 或 malloc 0x1058 新建 (ctor/Refresh ✓) → 源多于行位触发断言 → 尾部裁剪: 超容行自数组摘除 (sub_1422C6DD0 + memmove + vtable+632) 虚删 |
| NCombatLogView::CCombatItem (0x1058, ctor 0X1416E75A0, combat_log_combat_item; **命名空间坑 — 裸名落空**) | **combat_data_entry 1096B 指针@+32 + player_is_attacker@+40** | Refresh 0X1416F3260 命中册内 **+1088/1092/1093/1094/1095 五连偏移 ✓**; 21 元素全映射 (地点/将领可点击直跳地图) |
| CCombatantEntry (0x5C8, ctor 0X1415CC740, division_combat_attacker/defender_entry) | **CUnit ref@+1336 + 侧旗@+1344** | 陆战窗 committed 师行; 消费 **cb+232 front 列表 ✓** 与 **unit+312 统计对象 ✓** (soft/hard/defense/breakthrough, §4.30.18 链) |
| CCombatantReserveEntry (0x550, ctor 0X1415CD110, reserve_combat_entry) | unit@+1336 / 侧旗@+1344 / combat@+1352 | 预备队行; 消费 **cb+256 reserves 列表 ✓** |
| CCombatantSideModifierIconEntry (64B, ctor 0X1415CD5F0, **global_modifier_icon_entry**) | {+32 类型 idx, +40 图标, **+48 = CCombatant**, +56 侧旗} | 与 §4.22.8 CModifierIconEntry 为 **ICF 同构孪生**; 驱动 = **cb+8 旗位段** (位义定案, 见 §4.30.18 行) ∧ cb vtable+248 ∧ sub_1401F6EA0(cb)+152 |
| CCombatHistoryEntry | **+48 prev 双链** | **gs+648 链表头对象 {head@+8, tail@+16, count@+24}**; 创建点 sub_140BB6D00; writer 0X140BBAF10 ✓ (§4.22.4 本体) |
| CHistoryEntry (抽象基) | +8 日期 (CGameDate 24B 双 vtable, hours@+16) / +32/+40/+48 侵入链表 | vtable[13] = 纯虚 GetToken; vtable[17] = Apply (基 sub_140A3D610 递归); 18 派生 = 开局历史族 (country/state) |
| NIndustrialOrganisation::CHistoryItem (industrial_organisation_history_item, ctor 0X141FBA330, 三 vtable @0/+56/+104) | MIO 详情窗历史行 | Refresh 覆写槽[8] = 0X141FBC720 (三 loc key 全在: …_EQUIMENT_NAME 原拼写 / …_ARCHETYPE_NAME / PRODUCTION_ENTRY_OUTDATED); 成员 +112 idpair / +120 int 条目类型 (1=指派·升级 / 2=产量) / +124 idpair2 (类型1=变体 / 类型2=历史记录键) / **+132 过时旗 u8 (类型2 = org+216 容器逐元匹配 +124 未命中; 类型1 = 变体+1060 直读) / +133 加成差分旗 u8 (变体+1160 挂接 MIO 时 sub_140DB7A10 对比 +1168 表, 无则 *(变体+1188)==0) / +134 可负担旗 u8** / +136..+160 串 (XP 成本) / **+1560 flavor 文本元件** / **+168 upgrade_variant_button** (建胶同体 sub_1422DC710; Refresh 读 +168 显隐门 `*(item+120)==1`; 点击 handler 未决) / +1536 equipment_icon; 与 CShip/CArmyHistoryEntryItem 不同基支 |

**CEqLossItem (战斗日志装备损失行, GUI)**: NCombatLogView::CEqLossItem ("combat_log_[enemy_]loss_item", 192B, CSmoothListboxItem 族): **+112 装备 ref idpair / +120 eq_name / +128/+136/+144 三项损失数 / +152 equipment_icon**; 名链 **def+1008→+1240→+24 ✓ 双命中** (§4.23 archetype 父链); 损失值 = fixed ×1e-5。

**CTinyUnitCounter (海战迷你计数器, GUI)**: (vtable 0x142A8A010, 144B, ctor sub_141E8CB40 "GFX_mapicon_tiny_unit_counter"): 海战参与者格迷你计数器 (宿主池 +1472/+1484/+1496, §4.22.5/§4.31.37 +1464 池互证); **三非虚 setter 定案**: 背景色 = **单位+16 CColor** / count 文本 / **spotting 条 = (1 − progress/1e5/100) × 背景宽**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 日志窗 | 主 vtable[2] Update | view+1376 = NCombatLogView::CPage (三 tab+双滑条) | gs+2176 → COrdersGroupLogs → combat_data_entry 池 ✓ | combat_log_view | 定案 |
| 日志战斗行 | Refresh 0X1416F3260 | entry ptr@+32/+40 attacker 旗; **+1088..+1095 五连 ✓** | 命名空间坑 (裸名落空); 21 元素 | combat_log_combat_item | 定案 |
| committed/预备队行 | ctor | unit ref@+1336/+1344/+1352; **cb+232 front ✓ / cb+256 reserves ✓** | unit+312 统计对象消费 ✓ | division_combat_*_entry / reserve_combat_entry | 定案 |
| 侧修正图标 | populate | {+32 类型/+48 CCombatant/+56 侧旗}; **cb+8 位段 ✓ 位义定案** | 与 §4.22.7 为 ICF 同构孪生 | global_modifier_icon_entry | 定案 |
| 战斗历史条目 | writer 0X140BBAF10 ✓ | +48 prev 双链; **gs+648 链表头 {head+8/tail+16/count+24}** | 创建点 sub_140BB6D00 | — | 定案 |
| 场景历史基 | vtable[13] 纯虚 Apply | +8 日期/+32/+40/+48 侵入链表 | 18 派生 = 开局历史族; 与 CCombatHistoryEntry 平级 | — | 定案 |
| MIO 历史行 | 槽[8] 0X141FBC720 | NIndustrialOrganisation::CHistoryItem | 与 CShip/CArmyHistoryEntryItem 不同基支 | industrial_organisation_history_item | 定案 |

未决 12 项: view+1384 国家 id 对写点 / manpower loc 第 4 参漏显 / 主泵 cd+1072≥gs+1128 直比语义等。

#### 4.31.50 持续国策/和会总结 (CContinuousFocusDetailView / CContinuousFocusItem / CFocusFinishedPopUpWindow / CPeaceSummaryPopUpWindow / CBiddingsPopupItem)

持续国策族权威表见下 (target 形态/锚点/def 四新字段 +56 显示名 / +868 投降后可用显示门 — **与死门 +1468 区分** / +216 / +304+324); 和会总结消费验证+三新字段 (conf+344 改政府/+544 缴获装备/winners 条目+36 州数) + CPeaceAction+48 = 行动方 tag 收 §4.10.26。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 持续国策详情 | populate sub_141BC9950 | def @+5208; fp+16/fp+24 ✓ | **CSetContinuousFocusCommand / CDropContinuousFocusCommand** | coninuous_focus_detail_view (原生拼写) | 定案 |
| 持续国策行 | ctor sub_141BC16A0 | def @item+1352; 宿主 CContinuousFocusView+96 调色板 | def+216 触发器可见门 | continuous_national_focus_item | 定案 |
| 国策完成弹窗 | [11] SetupDerived | def @win+4032 + bypassed/canceled @+4040/+4041 | 无命令出口 (ok/details 双钮) | — | 定案 |
| 和会总结弹窗 | [11] sub_140B7F070 | **conf @win+2744**; winners/losers/liberated/subject/white peace/message 消费全中 ✓ | 新字段 conf+344/+544/条目+36 | — | 定案 |
| 竞标弹窗行 | 宿主 vtable[2] populate | item+40=_pConference/+48=_pAction (断言实名) | **CPeaceAction+48 = 行动方 tag**; conf+520 ✓/GetCurrentNegotiator ✓; 与三行池边界 = Popup 变体独立类 | — | 定案 |

| 类 | target 形态 | 锚点 |
|---|---|---|
| CContinuousFocusItem hover 旗族 | **+1341 hover 旗 / +1342 hover 已触发锁** (ctor 置 0 → hover 置 1) / **+1332/+1336 hover 动画计时** (全局 dword_14338C228 累加) | hover cb sub_141BC3580 / click cb sub_141BC35D0; click 模式门 = `(*(qword_14332F698+1288) vtable+40)==0`; click → `sub_14138E1F0(*(*(item+1344)+8), *(item+1352), flag)` |

**持续国策 def 新字段**: **def+56 = 显示名 loc 键** (三处消费定案) / **def+868 = 投降后可用显示门** (活字段 — 与 §4.3.13 死门 def+1468 available_if_capitulated 区分: 解析层死门是 +1468, 运行时显示门是 +868) / def+216 (触发器可见门) / def+304+324。

未决 9 项详项未录 (subject 条目+96 vs tag@+8 并存待裁)。

#### 4.31.51 弹窗/对话框杂项 (CStandardInfoPopUpWindow / CDefaultInfoPopUpWindow / CConfirmationPopUpWindow / CAcceptCommandDialog / CReassignFullOrdersGroupDialog / CChangeUnitTemplateDialog / CDismantleFactionDialog / CStandardDiplomacyPopup)

框架侧: **CDefaultConfirmationPopUpWindow 扩槽契约全定案** ([14]=Populate/[15]=关闭清理/[16]=OnAccept/[17]=关闭门) + 三通用弹窗 + CAcceptCommandDialog 载荷 (CCommand\* 数组@+4184) — 全收 §4.00 弹窗节。业务侧: CReassignFullOrdersGroupDialog 三载荷+双命令收 §4.24; CChangeUnitTemplateDialog 收 §4.18; CDismantleFactionDialog 收 §4.5; CStandardDiplomacyPopup 四分流+注册表收 §4.10。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 信息弹窗 | [14] Populate 0X141BE5690 | 标题+2728/描述+2760 | def default_info_popup_window | — | 定案 |
| 确认弹窗 | 独立分支 | 标题+2744/正文+2776/旗 tag+2808/+2812/战争图标+2816; CAutomaticPause@+1440 | 实测 = MILESTONE_UNLOCK_HEADER 通知 | confirmation_popup_window | 定案 |
| 命令接受对话框 | [16] 逐个投递 | **CCommand\* 数组@+4184{c@4196}** | [15] 销毁未投; sub_142250B00 队列 | default_confirmation_popup | 定案 |
| 重指派集团军 | 接受双路 | +4104 源群/+4128 目标/+4136 HQ 列表 | **COrderGroupCommand + CWithdrawArmyHqCommand** | — | 定案 |
| 换模板对话框 | HQ 判定 sub_141CFCB60 | +4104 模板 idpair/+4112 单位列表 | **CSetArmyTemplateCommand** | CONFIRMCHANGE_UNIT/HQ_TEMPLATE | 定案 |
| 解散阵营 | 接受投递 | +4096 = u32 tag; CFaction 名链 ✓ | **CDiplomaticActionCommand 包 CDismantleFactionAction** | — | 定案 |
| 标准外交弹窗 | 工厂 sub_141752E80 | CIncomingDiplomaticAction+8 类型四分流 (14027/19135/vtable[51]/兜底) | 响应码 2/1 → CIncomingDiplomaticActionActingCommand ✓; **注册表 0x14338B060** | — | 定案 |

未决 6 项: info 族 [16] 语义 / +1456/+1488 双拷用途 / 旗标写入路径 / 消息槽清理链 等 (原第七项 sub_140F3FF80 本体已消解 — 命令组指派投递器本体定性入 §4.33 orderstools worker 补全块)。

#### 4.31.52 特质/升级杂项 (CTraitIconItem / CBonusTypeIconItem / CUnlockTraitPopup / CUpgradeVariantPopup / COpenRosterButtonForPoliticalScreen / CHqTemplateNamedItem / NCombatLogView::CDivTemplateItem)

业务侧: CTraitIconItem+特质 def 五字段收 §4.31.52 (**科学家特质行 ≠ 将领特质窗**); MIO 四件权威表见下 (**MIO 特质树 org+320 ≠ 将领 XP 体系**); HQ 模板行收 §4.18 (**「HQ 模板」= CDivisionTemplate 的 is_army_hq 子集非独立类**)。

类布局 (类名 / target / 锚点):

CTraitIconItem (vtable 0x142aafbc0, 仅 dtor 覆写; gui scientist_trait_entry): **= 科学家详情视图的特质图标行** (不属 §4.31.36 将领特质窗); item+32 = 特质 def; 宿主链 = **CScientist traits 容器 {data@+48, count@+60} ✓✓ 双证**。**特质 def 侧五字段**: **def+8 = token / def+32 = 描述 loc / def+88 = modifier / def+264 = 自定义名 / def+296 = 自定义 gfx**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 科学家特质图标 | 宿主 traits 容器 ✓✓ | item+32 = 特质 def; def+8/+32/+88/+264/+296 五字段 | scientist_trait_entry | — | 定案 |
| MIO 加成类型图标 | 槽[8] Update | item+72 = EBonusType (1 设计团队/2 工业制造商)/+76 = **std::variant<EBonusType,bool> 判别符** (断言实名 _BonusTypeOrHasModifier; 0=EBonusType/1=bool — 精化: 原「has_modifier」系裸 bool 误读) | industrial_org_detail_items.cpp 实名 | 三 GFX 常量 | 定案 |
| MIO 特质解锁弹窗 | 槽[11] SetupDerived | +1448 org/+1456 def/+1464 变体; org+320 特质树 map | **CUnlockIndustrialOrganisationTrait {cmd+48 STraitId/cmd+64 org}** | unlock_industrial_org_trait_popup | 定案 |
| MIO 变体升级确认 | [16] OnConfirm | +4096 org/+4104 variant; 扣 XP = org+192×1e5 | **CSetObsoleteEquipmentVariantCommand + CCreateEquipmentVariantCommand (CTraitBonus@cmd+360)** | — | 定案 |
| 政治屏花名册钮 | 纯导航 | +1400 EOrganisationCategory/+1408 CCountryPoliticsView& | 无命令出口 | INDUSTRIAL_ORG_POLITICAL_SCREEN_OPEN_ROSTER_WITH_FILTER | 定案 |
| HQ 模板行 | tooltip 槽0 巨函 | +3984 = CDivisionTemplate; d+396 ✓/d+436 ✓/d+376 部署天数 | 选择/编辑(0X141763C40 ✓)/删除 CRemoveDivisionTemplateCommand | armyhqtemplatewindow | 定案 |
| 战斗日志模板行 | — | +112 模板 CRef/+120 胜场/+124 参战 | 胜率 = fixed 百分比; 与 §4.30.2 部署窗划界 | combat_log_div_template_item | 定案 |

本表 7 行全部定案, 无未决项 (旧计数已销)。


#### 4.31.53 详情/总览窗行件 (CDivisionsSummaryItemView / CDetailsInitialTraitItem / CDetailsModifierItem / CDetailsSeparatorItem)

业务侧: **CDetails\* 三兄弟 = NIndustrialOrganisation:: MIO 详情窗行件** (宿主 COrganisationDetailWindow 列表框 @+14432; 数据源开展见下行的 trait 行待裁注) 收 §4.3; CDivisionsSummaryItemView 行件全表见下 (宿主 CArmyBadgeView divisions_summary 池 badge+456)。**宿主视图本体 (CArmiesView / CTopBar / CPowerBalanceView) 与 GUI 根管理器槽位 (CInGameInterfaceHandler) 收 §4.30.29**。族级: 全部无 CCommand 出口 (纯显示/导航; CTopBar 调速两钮的 MP 分支见 §4.30.29)。

类布局 (类名 / target / 锚点):

CArmiesView 本体 (1640B) 全布局 + CDivisionsSummaryItemView 行件 (1432B; 宿主 CArmyBadgeView divisions_summary 池 badge+456) + GUI 根管理器 CInGameInterfaceHandler 槽位 (+392 CTopBar / +472 CArmiesView) = 视图本体, 权威表收 §4.30.29 / §4.30.30。

**CUnitCounterItem / CUnitTemplateItem (单位计数器/模板行, GUI)**: CUnitCounterItem (vtable 0X142A14830, 2992B, unit_counter_item.cpp): 地图单位栈计数器行, 零覆写 Item 族; 目标 = **单位 CRef 数组@+56 {count@+68} + 代表单位 CRef@+48**, **类型@+384 (0 陆军 / 1 海军 / 2 铁路炮)**; populate 0X1418DA680 抓 30+ 元素 (count_bg@+96 … capital_ship@+312); 刷新 0X1418D8110 分列海军 0X1418D9F80 / 陆军 0X1418D92A0; 无命令出口 (纯选择 API); 命中 unit+8 kind、舰+1840 载机 holder ✓。CUnitTemplateItem (vtable 0x1429ea3e8, 1432B, unit_template_entry): 目标 = **CTemplateChanger\*@+1408 + CReferencedDivisionTemplate CRef@+1416**; **unitlist_priority_icon SetFrame = CDivisionTemplateData+396 priority+1 ✓ §4.18.4 命中**; IButtonEventFilter@+32 拦不可负担点击 (tooltip 键 CANT_CHANGE_DUE_TO_*)。

**CDetailsInitialTraitItem / CDetailsModifierItem / CDetailsSeparatorItem (定案, 双证)**: 三者 = **NIndustrialOrganisation:: 命名空间的 MIO 详情窗行件** (与师详情窗无关); 宿主 = **COrganisationDetailWindow** (industrial_organisation_detail_window, 列表框 @+14432)。separator = 段头隔行 (**loc key@+104**, INDUSTRIAL_ORG_DETAIL_MIO_MODIFIERS/EQUIPMENT_BONUSES); modifier = 修正行 (**+112 名 / +144 值 / +176/+208 tooltip 双串**, INDUSTRIAL_ORG_DETAIL_MIO_MODIFIER_ITEM); trait = MIO 初始特质行 (**+112 名 / +144 tooltip**; 数据源 = MIO 对象特质键容器（宿主偏移待裁——+288 已翻，§4.8.12 +288 = 属主国 tag）, INDUSTRIAL_ORG_DETAIL_MIO_INITIAL_TRAIT_ITEM)。三类唯一真入口 = 主表槽[8] 行 Update + tooltip 槽0。

**CDetailedOutputItem (特种项目产出奖励明细行, GUI)**: NProject::NUi::CDetailedOutputItem ("detailed_output_item", 1728B): 唯一覆写 **vtable[8] = Update 布局泵 0X14201A360**; 13 段布局链全解 (header/country/state/scientist 效果、装备加成、解锁子单位/模块/装备、progress_text、rewards_header 显隐); 宿主 = CProjectOutputRewardWindow 族 (高置信)。

**CDivisionsSummaryItemView (1432B, "divisions_summary_item")**：主 vtable 0x142A67320（13 槽，仅 [0]=dtor 0x141CFAA80 类属覆写）+ @56 TListboxItem 面 0x142A67390（**实 24 槽**）+ @72 tooltip 0x142A67458（[0] BuildTooltip 0x141CFAE50）；ctor 0x141CFA1B0。布局：+64 宿主窗 / +88 "button"（glue @+120 挂接，handler sub_141CFB210）/ +96 "selection_marker" / +104 "icon" / +1344 idpair（{type@1344, id@1348}，BuildTooltip 读门同形；写入点未决）/ +1408/+1416 sentinel ×2 = qword_14333D528 / +1424/+1428 = 0。行池 = sub_141CFB8C0（"divisions_summary_max_item_count" 取数，clamp 1..16；调用点 sub_1416AED50(a1+456, a1+32) = CArmyBadgeView populate）；第二宿主 sub_141C7B7D0 = **CSendUnitsGroupItem**（唯一 strcpy "diplomacy_send_units_group_entry" 者，写该类 vftable +0/+24）；glue ctor sub_141CF9940。

**MIO 详情三行件（宿主 COrganisationDetailWindow）**：宿主 vtable 0x142A93CA0（4 槽；[2] Reload 0x141F1EB10 → 建窗 0x141F1EB60，def "industrial_organisation_detail_window"）；MIO idpair 目标 = *(view+48)+132/+136；详情列表框 @+14432（sub_141F1A900 体清表）；行件容器 +8312（{+8336 数据, +8348 count}/+8360 区）；段头门 = *(a1+8348)>0（修饰）/ *(a1+8372) \|\| *(a1+8384)（装备加成）；填充链 = sub_141F1A900（总装）→ sub_141F1B5D0（修饰行 ×4）/ sub_141F1AC70（特质行）/ sub_141F19D50（另一路）。三行件：CDetailsSeparatorItem（136B，vtable 0x142AA4A40，[8] Update 0x141FBC2F0：+96 窗 "separator_name" ← loc(item+104)；ctor 0x141FB9B30 内即 FindWindow 填）/ CDetailsModifierItem（240B，vtable 0x142AA4B78，[8] Update 0x141FBC190 loc INDUSTRIAL_ORG_DETAIL_MIO_MODIFIER_ITEM{NAME,VALUE}；@104 tooltip 面 0x142AA4CB0：[0] 0x141FBAEF0 = +176 + +208 两段直拷；ctor 0x141FB97F0 +112=NAME/+144=VALUE/+176=tooltip1/+208=tooltip2 逐参同）/ CDetailsInitialTraitItem（176B，vtable 0x142AA4CC8，[8] Update 0x141FBC050 loc _INITIAL_TRAIT_ITEM{NAME}；@104 tooltip 面 0x142AA4E00：[0] 0x1414A1D30 = +144 串直拷；ctor 0x141FB9540）。

#### 4.31.54 行件杂项 A (CIdeaItem / CNationalSpiritItem / CManpowerListItem / CTrackProgressItem / CAccidentItem / CReceivedDamageItem / CEqLossItem / CDetailedOutputItem)

业务侧: 理念/精神行收 §4.10; 学说 track 行收 §4.6; 事故聚合行收 §4.16; 流亡人力/空战受损行收 §4.15; 装备损失行收 §4.22; 项目产出行收 §4.3。族级: 8 类 7 个零覆写 Item 族 (真入口 = ctor + 宿主非虚 populate), 唯 CDetailedOutputItem 有 vtable[8] 覆写; **8 类 ctor 全域扫描均无行内 CCommand 投递**。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 理念行基类 | 派生复用 | {+24 CIdea\* def / +32 u32}; ps+80 ✓ | CGameSetupIdeaItem/CNationalSpiritItem 派生 | — | 定案 |
| CNationalSpiritItemSmall/Big | 零虚覆写, 真入口 = 基类非虚 refresh sub_141C47340 | {+24 CIdea\* def / +32 u32} 同基; 主表 0x1429D9210/0x1429D92C8 各 2 槽 + 次表 0x1429D9228/0x1429D92E0 各 19 槽; 1344B | 政治窗双池 +31416/+31464 + 三旁路装配点 (sub_1415F4200/141F4D2F0/141F4D0C0); ctor a4=1/0 选元素名 | spirit_idea_entry_small / spirit_idea_entry | 定案 (类名悬案结案: 同行件小/大两排版) |
| 国家精神行 | refresh sub_141C47340 | def 组过滤 `*(*(def+2720)+96)+120==1`; cc+3712 ✓ | Small/Big 两派生 | spirit_idea_entry[_small] | 定案 |
| 流亡人力行 | payload = tag id | dip+400 ✓ / cc+832 ✓ / cc+808 ✓ | 空军重组窗 | airwing_manpower_item | 定案 |
| 学说 track 行 | Update sub_141F690B0 | {+40 track/+48 索引/+52 tag} | 进度值/全掌握门 | track_progress_item | 定案 |
| 事故聚合行 | setter sub_1417F8460 | 56B 聚合元; report+32 = is_sunk ✓ | 图标/名/双计数 | accident_equipment_archetype_entry | 定案 |
| 空战受损行 | setter sub_141886310 | {+32/+40/+48/+56}; win+2836 位掩码 | CStrategicAirView 分解行 | air_combat_damage_received | 定案 |
| 装备损失行 | CSmoothListboxItem 族 | +112 ref/+120 名/+128/+136/+144 三项损失 | 名链 def+1008→+1240→+24 ✓✓ | combat_log_[enemy_]loss_item | 定案 |
| 项目产出行 | vtable[8] 泵 0X14201A360 | 13 段布局链 | 宿主 = CProjectOutputRewardWindow 族 | detailed_output_item | 高置信 |

**定案**: sub_141C47340 的 a2 = **CIdea\* def, 落点 item+24** (基 ctor sub_140552760 体 `*(a1+24)=a2`；同族工厂 sub_141C41D00 传 CIdea 库条目) / 事故宿主窗 = **CNavalLossesOverview** (vtable 0x142A05AF0, 窗名 `navallosseswindow`; 事故行件 CAccidentItem vtable 0x142A05930, ctor sub_1417F1B30, 件名 `accident_equipment_archetype_entry`; 行池 = 其 +2984; populate 入口 = vtable[2] sub_1417F7210) / CReceivedDamageItem setter = **sub_141886310(item, damage_type, v, a4)**: +32 damage 控件 / +40 count_txt / +48 类型枚举 / +52 第二值 / +56 宿主; 枚举 9 → GFX_placeholder_bordered + 控件清空, case 3 → AIRWING_DISRUPTED_VAL。

#### 4.31.55 国家选择/流亡 (CMajorCountrySelectionEntry / CMinorCountrySelectionEntry / CNationalitiesBoxItem / CCollabarationViewItem / CExileViewItem / CForeignManpowerDiplomacyPopup / CNewExileHostedPopupWindow)

业务侧: 流亡/合作/外国人力四件收 §4.31.55 (含 **dip+320/332 占领者 tag 数组新锚** 与 CReinstateExileCommand/CAmendForeignManpowerActionCommand 两命令); 国籍旗行收 §4.11 (operative+3944 ✓); 国选器收 §4.3 (**门读的是 CBookmarkCountryEntry+272 `minor` 键 (11242), 非 CCountry 本体字段** — CCountry ctor 该址是容器三元组 {data@272, cap@280, count@288}; 门体 sub_141F42E40 `if (!*(_BYTE*)(a2+272) && a3) return 1;`, a2 = CBookmarkCountryEntry const&; §4.26 已载 minor→+272); 流亡/合作子视图槽 = CCountryPoliticsView+31280。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CExileViewItem (0x5E0B, exile_item) | **+1496 = 被收容流亡 tag** | 数据源 = 玩家 **dip+400/412 gov_in_exile_we_host ✓✓** (dip+424/432/440/736 全命中 §4.10.18); 命令出口 = **CReinstateExileCommand {cmd+40 = tag}**; **dip+320/332 = 占领者 tag 数组** (新锚) |
| CNewExileHostedPopupWindow (0xB18B, new_exiled_hosted_popup[_small]) | **+2824 = 流亡国 tag / +2832 = 收容国 tag** | 创建点 = CCountry 0X1406D5FA0 (门 = **dip+424 hosting==玩家 ✓**); 标题 NEW_EXILE_POPUP_TITLE + 正文带 LEGITIMACY=**dip+432 ✓**/EQDESC/DIVDESC; 仅 ok 关窗无命令 |
| CForeignManpowerDiplomacyPopup (0x1078B, diplomacy_foreign_manpower_popup_window; 工厂 token 19135=request_foreign_manpower ✓) | **+4064 = action id 对** (action+20/+28 = sender/receiver tag) | 人力滑条上限 = receiver **cc+808**; accept → **CAmendForeignManpowerActionCommand {+40 tag / +44 action id / +52 数量}**; decline 走 action 虚函数拒绝 (非命令族) |
| CCollabarationViewItem (0x78B, collaboration_item; 非虚 Update 0X141C58F40) | **+36 = 目标国 tag** | progress = **cc+4056 collaboration 宿主**按 tag 查 value×1e-5 ✓; 子列表 CSimpleEmptyEntryList\<COccupationModifierEntry\>; 父 = **CCountryPoliticsView** (fill 门 **cc+1156 ✓** + 合作值>0; 子视图槽 **CCountryPoliticsView+31280**) |

**CForeignTemplateListItem (附属国模板源国行, GUI)**: feed = **dip+368 附属国 tag 缓存 ✓✓** (dip+368 第五处 GUI 消费); 点击写 **win+4032 tag / +4036 kind**; tooltip = **dip+848 自治 → {LEVEL}**。

**CAbstractStateControlController (州控制子控制器抽象中介基, GUI)**: (TD 0X1432CCA78, 无自身 vtable): 链 CTooltipHandler ← CDiplomacyViewActionSubController ← 本类 ← **Ask/Give 两派生** (各 22 槽, 新增**槽[21] = OnStateClick** 消费 **st+88 州 id / st+200 owner / st+204 controller ✓§4.13 三命中**); **+32 = 动作 token 13781/13782 双证**; 定位 = CDiplomacyView 州选择子控制器 (与 §4.30.21 州面板不同物); 动作出口 = **CAsk/GiveStateControlAction {+120 states 向量, 键 "states" 定案}**。派生地址: Ask vtable 0x142A5D870 / ctor 0x141C89210 / dtor 0x141C8BD90 / OnStateClick 0x141C96070; Give vtable 0x142A5D990 / ctor 0x141C89E20 / dtor 0x141C8C1C0 / OnStateClick 0x141C96290; 全族名录见 §4.10.22。

**CSendUnitsGroupItem (志愿军/远征军派遣组行, GUI)**: (vtable 0X142A594D0, 1400B, diplomacy_send_units_group_entry): +32 = 宿主组控制器 / +40 = 内嵌 divisions_summary 助手 (**define divisions_summary_max_item_count**) / background_button@+88 = 折叠切换 (+1384); tooltip = 集团军将领技能键; 行内无命令, 出口推定 = CSendVolunteerAction / CSendExpeditionaryForceAction (宿主侧, 未坐实)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 国选器条目 (大/小) | 槽[19] Update | +48 = CCountry\*; cc+272==0 门 | 伪条目 INTERESTING_COUNTRIES_OTHER_COUNTRIES | country_entry[_mini/_medium] | 定案 |
| 特工国籍旗行 | — | +32 tag/+40 flag_icn; operative+3944 ✓ | 非 graphical_culture 族 | operative_nationality_entry | 定案 |
| 合作政府行 | Update 0X141C58F40 | +36 目标 tag; cc+4056 collaboration ✓; fill 门 cc+1156 ✓ | COccupationModifierEntry 子列表 | collaboration_item | 定案 |
| 流亡行 | 数据源 dip+400/412 ✓✓ | +1496 = 流亡 tag; dip+320/332 占领者表 (新锚) | **CReinstateExileCommand {+40 tag}** | exile_item | 定案 |
| 外国人力弹窗 | 工厂 token 19135 ✓ | +4064 action id 对; 上限 = receiver cc+808 | **CAmendForeignManpowerActionCommand {+40/+44/+52}** | diplomacy_foreign_manpower_popup_window | 定案 |
| 流亡收容弹窗 | 创建点 0X1406D5FA0 | +2824 流亡国/+2832 收容国; 门 = dip+424 ✓ | LEGITIMACY = dip+432 ✓ | NEW_EXILE_POPUP_TITLE | 定案 |

**定案 3 项 + 未决 3 项**: 父窗 = **CGameSetupInterestingCountriesWindow** (vtable 0x142A98A10, COL 链 → CTooltipHandler; ctor sub_141F3FEB0) / CExileViewItem 第二消费父 UI = **CExilesAndCollaborationsView** (ctor sub_141C53840, malloc 0x578, 窗名 `exiles_window`; 宿主 = CCountryPoliticsView+31280) / cc+272 见上条 (CBookmarkCountryEntry+272 `minor`)。CNewExileHostedPopupWindow 槽[1] = 0x141527F90（调整器位；窗名双变体 ctor sub_141525350 按 a7 二选一 `new_exiled_hosted_popup` / `new_exiled_hosted_popup_small`；主表 0x1429D3EC8 15 槽 [0]=0x141525710 / [11]=0x1415275B0 Setup）；定案。未决 2 项: country_leader 无领袖回退 sub_140B472F0 / CCollabarationViewItem `surrender_text` 内容源。

#### 4.31.56 行件杂项 B (CWeatherEntry / CWeatherPositionEntry / CResourceEntry / CDoctrineListItem / CDoctrineSharingFolderItem / CGoalItem / CRuleTypeItem / CChangeRuleItem)

业务侧: 天气两行收 §4.20; 学说两行收 §4.6 (**def 五锚**: 学说 def+40/+104/+36, folder def+96); goal/rule 三行收 §4.31.56 (**CSetFactionRuleCommand/CEraseFactionRuleCommand 载荷定案** {+40 rule token/+44 国 id}; CActiveRuleText 新类; def+592 三旗字节)。CResourceEntry = **CPeaceMapIcon 的 peace_resource_item 行** (+24 数量/+32 精灵名/+64 帧; populate 0X1419076F0 双消费 ✓; 数据源 strategic_resource 库 ✓, def+216 数值 id/def+220 strip 帧)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CGoalItem (CCountryFactionView 阵营目标槽行; 与 §4.31.20 CFilterGoalItem 过滤钮边界划清) | **goal elem @+56 直取 fac+1568 goal_status+24 的 1344B 元 ✓** | **def+3336 = 槽 idx / def+3400 = token (==357 空) 双 ✓ 互证**; background 帧 1/2/3 = active/completed/canceled; 点击切 CChangeGoalWindow (view+1416) |
| CRuleTypeItem (规则类型行) | token @+48 | 宿主逐 **fac+1544 rule_status 哈希D ✓** (RH 8B 元 {distance@0, token@+4}, 桶数 = mask+1+extra ✓ RH 通式) 建行; **"ActiveRules" 内嵌新类 CActiveRuleText 子行** (遍历 **fac+1480 rules 向量**按 **def+32==token** 过滤 ✓); edit_button 开关 change_rule_window; **token 19479 = "undefined" 全隐门** |
| CChangeRuleItem (change_rule_window 主列表规则行; ≠ §4.31.20 过滤钮) | **rule def @+1408** | 宿主遍历 **external_rules 库 ✓ §4.26**; button 帧 = def 是否 ∈ fac+1480 rules ✓; **def+592 = 三旗字节** 驱动 mod_icon_1-3; 成本 loc FACTION_CHANGE_RULE_ITEM_COST; 命令出口双分 — 未激活 → **CSetFactionRuleCommand** / 已激活 → **CEraseFactionRuleCommand**, 载荷同构 **{+40 = rule token (def+8 ✓) / +44 = 本机国家 id}** |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 天气周期行 | Update 0X141B89380 | period+8/+32 hours 回写; 224B CWeatherChancePeriod ✓ | apply/delete/select 三钮 | nudge_window_database_period_entry | 定案 |
| 天气位置行 | select 点击 | obj+1376/1380 位置 id/序号; nudger+1236/+1240 | "Position N" | — | 定案 |
| 和会资源行 | populate 0X1419076F0 | +24 数量/+32 精灵/+64 帧; def+216/def+220 | CPeaceMapIcon 内嵌行 (§4.31.47 互证) | peace_resource_item | 定案 |
| 学说行 | 宿主 0X141F3AC50 | def @+1440 (assert); def+40 name/+104 gfx/+36 XP 类别 | CDoctrineSelectionList | — | 定案 |
| 学说共享文件夹行 | 共享态 @+2784 | folder def @+2776; def+96 icon | CUnlockFolderDoctrineSharingCommand {+40/+48} | FACTION_UNLOCK_BUTTON | 定案 |
| 阵营目标槽行 | 点击切窗 | goal elem @+56 (fac+1568+24 ✓); def+3336/+3400 ✓✓ | 帧 1/2/3 = active/completed/canceled | — | 定案 |
| 规则类型/换规则行 | 宿主遍历 fac+1544 ✓ / external_rules 库 ✓ | token @+48 / rule def @+1408; def+592 三旗 | **CSetFactionRuleCommand / CEraseFactionRuleCommand {+40 token/+44 国 id}**; CActiveRuleText 子行 | FACTION_CHANGE_RULE_ITEM_COST | 定案 |

**定案 3 项**: 天气主 vtable = **0x142A462C8, 基链 = CWeatherEntry → CStandardlistboxItem → COption → … → TListboxItem** (无 CWeatherNudger 血缘; Nudger vtable 0x142A461F8 为另一类, 只作宿主) / rule def+592 = **3 字节 mod 图标旗** (sub_141185E60 打包器按 16B 键值对表 + qword_14332ED90 flag 位判 lo/hi; 三字节 → mod_icon_1/2/3 帧, 余钮隐藏) / unlock 命令 +40 = **玩家国 tag** (非 idx; 取法 `gs+328` 下标 → sub_140BB4AC0 返 CCountry\* → +8 = tag)。余 4 项 (学说 def 五锚 / CResourceEntry def+216/220 / goal+rule 载荷 / 天气位置行位置对) **已在 §4.6 / §4.26 / §4.31.56 定案 — 本行旧计数为重复挂账**。

#### 4.31.57 军官/被俘将领 (CHeldOfficerItem / CHeldOfficerWindow / CCapturedArmyLeaderWindow / CCapturedArmyLeaderItem / CAbstractArmyLeaderItem / CLeaderGroupView / CUnitLeaderTraitItem / CAssignCharacterPreferredTacticDialog)

业务侧类布局见下 + §4.24 (CLeaderGroupView); **CHeldOfficerWindow 与 CUnitLeaderWindow 为兄弟基类** (槽位语义不同勿混); **CSetArmyLeaderPreferredTacticCommand {+40 将领 CRef/+48 战术\*} → Execute 直写 leader+4272 preferred_tactic ✓✓** (与 §4.30.18 互证闭合; **leader+288 = tag 第三证**)。

类布局 (类名 / target / 锚点):

**CHeldOfficerWindow 与 CUnitLeaderWindow 为兄弟基类** (unitleaderwindow.cpp assert 三处实名), 槽位语义不同勿混。

| 类 | target 形态 | 锚点 |
|---|---|---|
| CHeldOfficerItem (基 5320B, ctor 0X141ABB1C0, divisionleaderentry) | **IOfficerHolder\* @+40** | 槽[19] = Update 全映射 (name/division_name/gained_xp/portrait/unit_level/promote 门); [20][21] 基纯虚; **新锚: CHeldOfficer+104/+136 → CShip+2224/+2256 / leader+992/+1004/+1072 = XP 进度 / leader+1592 = 勋章史** |
| CHeldOfficerWindow (2968B, ctor 0X141ABBF10) | 槽[9] 枚举/[10] 造件纯虚 | **[11] 默认排序定案: 模式+2928 / 升序+2932; 四表头实名 sort_experience/medals/total_exp/unit_type** (第 4 列 release 空转); medals 键 = leader+1592/ship+2264 history 计数 |
| CCapturedArmyLeaderWindow (capturedarmyleaderwindow, ctor 0X141ABAB30) | **CUnitLeaderWindow 族** ([9] = CP 门槛 **country+496 ✓** / [10] = 命令出口 (本类空桩化) / [11] = SetupDerived 双 tab / dispatcher[9] = 填充 0X141AD4CC0) | 数据源 = **CDiplomacyStatus country+3976 ✓** (diplo+648 链 / +1000 容器两向枚举, our/their 口径推定未裁); 窗口+5896 池/+5920 向量/+5944 tab 字节 |
| CCapturedArmyLeaderItem (2864B, ctor 0X141ABA1E0) | **CArmyLeader\* @基+72** (lambda RTTI 直证) | captof_flag ← **leader+4188 captured_by ✓** / 营救门 ← **leader+4192 ✓**; 营救出口 = 特工任务系统 ("rescue_captured_general", 非 CCommand); rescue_raid 五元素 + tooltip loc 全族 |
| CAbstractArmyLeaderItem (基至 +144, ctor 0X141AB8580) | 派生谱 = CArmyLeaderItem + CCapturedArmyLeaderItem (仅此二) | 共享 populate sub_141AD6290 全映射: leader+64 名/+288 tag/四技能 skill+440 ✓; +136 = 100000 缩放常量 |
| CLeaderGroupView (208B, leader_groups_window) | 数据源 = gui vtable[25] 对象+112 = **CTheatre\*** (新挂载锚) | 枚举链: theatre+152/+164 FM 群 ✓ / CArmyGroup+560/+572/+584 ✓ / og+57/+92 ✓; 行类 RTTI 实名 = **CLeaderGroupPortrait** (新收) |
| CUnitLeaderTraitItem (零覆写族, ctor 0X141C73CE0) | **特质 def\* @+56** + 将领\* @+40 | **def+2336==6 = 流放特质 (def 侧新锚)**; **leader+3796 = 流放国 tag ✓**; 图标 "GFX_trait_"+def 名, 帧 def+2212; 点击开特质树/分配视图 |
| CAssignCharacterPreferredTacticDialog (4120B, 基 CDefaultConfirmationPopUpWindow) | 载荷 **+4096 = CCombatTactic\* / +4104 = CArmyLeader\* / +4112 = 父窗** | OnShow loc 双键定案; 命令出口 = **CSetArmyLeaderPreferredTacticCommand {+40 将领 CRef / +48 战术\*}** (RTTI 实名), Execute 0X14115B940 **直写 leader+4272 preferred_tactic ✓✓ + leader+288 tag ✓ 校验** (与 §4.30.18 战术族互证闭合; **leader+288 = tag 第三证**) |

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 军官行基类 | 槽[19] Update | IOfficerHolder\*@+40; **leader+992/+1004/+1072 XP 进度/+1592 勋章史新锚** | CHeldOfficer+104/+136 → CShip+2224/+2256 | divisionleaderentry | 定案 |
| 军官窗 | 槽[11] 排序 | 模式+2928/升序+2932; 四表头实名 | medals 键 = leader+1592/history 计数 | sort_experience/medals/total_exp/unit_type | 定案 |
| 被俘将领窗/行 | dispatcher[9] 填充 | CDiplomacyStatus ✓ (diplo+648/+1000 两向枚举, our/their 未裁); item 基+72 = CArmyLeader\* | **leader+4188 captured_by ✓ / +4192 营救门 ✓**; 营救走特工任务系统非 CCommand | capturedarmyleaderwindow / rescue_captured_general | 定案 |
| 将领组视图 | gui vtable[25] 对象+112 | **= CTheatre\* 新挂载锚**; theatre+152/+164 ✓ | 行类 = CLeaderGroupPortrait 新收 | leader_groups_window | 定案 |
| 特质行 | 点击开树 | def\*@+56 (**def+2336==6 = 流放特质新锚**) + 将领@+40 (**leader+3796 流放国 tag ✓**) | GFX_trait_+def 名, 帧 def+2212 | — | 定案 |
| 首选战术对话框 | OnShow 双 loc | +4096 战术\*/+4104 将领\*/+4112 父窗 | **CSetArmyLeaderPreferredTacticCommand → leader+4272 ✓✓** | — | 定案 |

未决 5 项。**leader+464/+480 待裁已裁定 (不成立)**: +464 = **CUnit 的 `logical_country` 国 tag** (GUI 读后经 gs+784 国家指针数组 sub_140BB48F0 解析成 CCountry*), 宿主是 CUnit (CArmy/CShip) 而非 CUnitLeader — 与 §4.4.12 的 CUnitLeader+296..+583 容器区不同类、偏移空间无关; +480 处无对象字段访问 (`mov r15d, 0x1E0` 零扩展哑元, 非 obj+480)。仅余 raw/ser 基址 16B 之差待运行时探针。

#### 4.31.58 行件杂项 C (CStateStakeholderItem / CStateStrategicResourceItem / CSupplyTruckReinforcementItem / CTemplateEntry / CTemplateDeploymentWindow / CForeignTemplateListItem / CNewTheaterGroupItem / CNewShipEntryButton)

业务侧: 州两行收 §4.13 (kind 枚举 0-3 定案); 卡车增援行 (宿主 = CCountryDeploymentView, rdata 反查定案; CDeployBaseItem 七纯虚槽 [19]-[25] 全实现, SUPPLY_TRUCKS/_DESC/_EMPTY 三 loc 直证; 命令出口 **CSetSupplyReinforcementPriorityCommand {+40 玩家 tag, +44 优先级}**); **CTemplateEntry 正名纠偏 = CBuildingsNudger 建筑模板行** (非师模板, 建筑库 def+20>0 ∧ def+84==357 过滤 (357 = token none — == none = 独立建筑门, 三消费一致; +84 字段名待运行时 token_name)) 收 §4.13; CForeignTemplateListItem 收 §4.10 (**dip+368 第五处消费 ✓✓**); CNewTheaterGroupItem 收 §4.24 (三分流三命令); CNewShipEntryButton 收 §4.16 (真名带命名空间, 无命令)。**CTemplateDeploymentWindow = 非窗口类, 是 CTooltipHandler+CReorderObserver 控制器 (4088B)**: 双实例 = templatedeploymentwindow (CCountryDeploymentView+1408) 与 armyhqtemplatewindow (HQ 模式); ctor sub_141D25B10 / populate sub_141D266B0 (同名同函数含 Update); **mode @+4080**; +4016 = 设计器 view (ES ✓§4.30.2); 拖排槽[0] → **CReorderTemplateListCommand {+40 CRef, +48 新索引}** 双证。**两模式行池 (新锚)**: mode0 池 {data@+3888, cap@+3896, count@+3900, alloc@+3904} / mode1(HQ) 池 {+3912/+3920/+3924/+3928}; 网格 +4072; 过滤器 +4032/+4036 (+4036==0 时回退模板 +504 u32); mode0 行 = CDivisionTemplateNamedItem (0x19D8, ctor sub_141D24BC0), mode1 行 = CHqTemplateNamedItem (0xF98, ctor sub_141D255F0, target +3984)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 利益相关者行 | 宿主 populate ✓ | kind 0-3 → st+176/+152/+200/+208 ✓ | 国旗+边框+惊叹号 | — | 定案 |
| 州资源行 | tooltip 链 | item+32/+40/+48; **def+220 图标 frame 三证** | st+204→cc+4600 因子缓存 ✓ | STATE_FOREIGN_RESOURCE_OWNER | 定案 |
| 卡车增援行 | CDeployBaseItem [19-25] 全实现 | 宿主 = CCountryDeploymentView (rdata 反查) | **CSetSupplyReinforcementPriorityCommand {+40 玩家 tag/+44 优先级}** | SUPPLY_TRUCKS/_DESC/_EMPTY | 定案 |
| 建筑模板行 | feed 建筑库 ✓ | 滤 def+20>0 ∧ def+84==357; def 名 = \*(def+8) token | **正名纠偏 = Nudger 行非师模板** | — | 定案 |
| 模板部署控制器 | 拖排槽[0] | 双实例; +4016 = ES ✓ | **CReorderTemplateListCommand {+40/+48}** 双证 | templatedeploymentwindow / armyhqtemplatewindow | 定案 |
| 附属国模板行 | 点击 | feed = dip+368 ✓✓; win+4032/+4036 | tooltip = dip+848 自治 {LEVEL} | — | 定案 |
| 新建剧场组行 | 三分流 | CTheatreSelector+1752 | CAssignToTheaterGroupCommand / CSetNavyTheaterGroupForCommand ✓ / CMoveAirWingAndAirGroupToAirTheatreCommand | NEW_THEATER_GROUP | 定案 |
| 新舰条目按钮 | 点击翻转显隐 | editor+8360 钮 → editor+8352 CSubUnitDefinitionSelectionWindow | 真名 NTaskForceCompositionEditor::CNewShipEntryButton; 无命令 | task_force_composition_editor_new_entry | 定案 |

**定案 3 项**: 每国补给对象真名 = **CCountrySupplySystem** (vtable 0x1429A2B08/0x1429A2B58, ctor sub_141218530; getter sub_1406EE6E0 体 = `gs[123]+264` 每国指针表按 tag idx 索引) / 五字段分两级 — **条目级 +200 卡车需求基数 / +312 卡车在役数**; **记录级 (\*(条目+128), 800B) +304 卡车缓冲比定点 / +320 火车在役数** / 槽[20] = **当前卡车比例百分比** (sub_141D7D400: `1e10*(条目+312)/(1e5*(条目+200))` clamp 0..1e5 → 进度条 `100*v/1e5`)。未决: CDeployBaseItem [19..25] 槽名 / 外国占用者谓词链 / def+84==357 字段名 / 模板控制器三列表模型。

**CTemplateDeploymentWindow 子件装配 = 0x141D2CF10** (317 行, 本类 ctor sub_141D25B10 / populate sub_141D266B0 之外的第三个成员函数; 断言 :1078 `_pDivisionDesigner != nullptr`): 根窗 = *(view+4000)+1272 窗口管理器 vtable[12] 建 (存 view+4008), 随即 (win+48) vtable[69] ← view 宿主回绑。mode 分流补全: **mode 0 = templatedeploymentwindow (国家部署视图内嵌** — 有 show_decommissioned_templates_window + checkbox + foreign_templates 两件, 无 close_button) / **mode 1 = armyhqtemplatewindow (HQ 弹窗** — 有 close_button, 无退役/外国模板区)。

view 偏移增量 (本节既有记录之外):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 拖排观察者体 | sub_1422C6650 第 2 参 |
| +16 | checkbox (退役模板)* | 仅 mode 0; 旧值清理 = 遍历 +136 链表逐节点 vtable[2] 注销 → vtable[69](0) 销毁 |
| +24 | open_designer_button 回调收件体 | (btn+128) vtable[1] ← view+24 |
| +1312 | checkbox 回调收件体 | (chk+128) vtable[1] ← view+1312 |
| +2600 | close_button 回调收件体 | 仅 mode 1 |
| +3968 | 建窗上下文槽 | winmgr vtable[12] 第 1 参 (语义未决) |
| +4000 | interface handler* | *(handler+1272) = winmgr |
| +4008 | 窗口根* | 建窗产物 + 全部子件查找宿主 |
| +4024 | CCustomIconChangeView* | 2616B, ctor sub_141DCF670 (handler, 根窗, 0), 激活 sub_141DD0190 |
| +4040 | byte | 显示已退役模板旗 (checkbox 初态源) |
| +4048 | foreign_templates_grid* | 下拉展开窗 vtable[54] 取 |
| +4056 | foreign_templates_drop_down* | 根窗 vtable[20] 取 |
| +4064 | templates 窗* | 根窗 vtable[55] 取; templates_grid 经其 vtable[54] 取 |

> **CCustomIconChangeView 实名直证** (customiconchangeview.cpp 断言 + 窗名 "div_templ_custom_icon_view" + CButtonObserverGlue/CLegacyButtonObserverGlue<CCustomIconChangeView>/std::_Binder 三 vftable 符号): CTemplateDeploymentWindow+4024 与 CDivisionDesignerView+17720 为同类双实例 (§4.30 师设计器行已补实名)。sub_142302DD0 = CDropDownBox::GetExpandedWindow (dropdownbox.cpp:282 错误通道; dropdown+2824 = expandedWindow 缓存槽)。**sub_1422C6650 拖排观察者挂接本体** (定案): 门 = grid+368 == 1 (kind 1 网格才可挂, 否则断言 latch byte_143481178); 写 grid+512 滚动条 / +520 观察者 / +528 DnD 灵敏度 / +536 = a6 / +548 旗 / +600 插值速度, 收尾 sub_1422C6400; **两 define 定案: dword_143335D40 = GRIDBOX_ELEMENTS_INTERPOLATION_SPEED / qword_143335CA8 = DRAG_AND_DROP_SCROLLING_SENSITIVITY**。

**CCustomIconChangeView ctor 全案 (0x141DCF670, 374 行切片全读; 簇名再甄别: onchangeview.cpp = customiconchangeview.cpp 伪影, :21 断言再证)**: 布局 +0 主表 (CLegacyButtonObserverGlue<自>, 先安 CButtonObserverGlue 基表再覆写) / +8 与 +1288 双 glue 体 (各 1272B, sub_1402DDEF0 初始化) / +2576 根窗 (a3 vtable[55] 建 "div_templ_custom_icon_view") / +2584 symbols_grid (根窗 vtable[54]) / +2592 直改模式槽 / +2600 命令模式槽 / +2608 上下文对象 (ctor a4)。**图标填充循环** = sub_140B4AE60 枚举 winmgr+184 sprite 表拼名 `GFX_div_templ_<i>_large` (上限 1024), 每命中 malloc 1328 建 **CCustomIconChangeView::CSymbol** (vftable 实名; +24 第三 glue 体 1272B 绑 sub_141DD01D0 / +1312 图标下标 / +1320 宿主回指) 经 sub_1402DE9B0 入格 → 收尾 sub_1422C4970(根窗, 1)。**三回调闭环 (定案)**: sub_141DD0220 = "default" (选择处理传 -1 恢复默认) / sub_141DD0190 = "back" / sub_141DD01D0 = 图标点击 (传 sym+1312 下标); 共同尾段 = 通知根窗+48 子体 vtable[16]。**选择处理 sub_141DD0250 双模**: 命令模式 (+2600 非 0) → malloc 56B 命令 sub_141B9E630 → qword_14332F698 vtable[17] 取栈 → sub_142250B00 提交; 直改模式 (+2592 非 0 ∧ +2608 非 0) → sub_1416897D0 + sub_141236980(view+2608+40)。

> CGridboxData 网格读点 (sub_1402DE9B0 前段, 与 §4.31.112 stations_grid 同构互证): +368 W / +372 H (0/负 = 无界) / +384 方向旗 (1 = 行优先水平流动) / +392 已放位置数组 {x u32, y u32} 8B/元 / +404 计数; 插入门 = 另一轴 < 上界, 超门丢弃不入格。

#### 4.31.59 市场/贸易杂项 (CAddEquipmentToMarketWindow / CAddToMarketEquipmentItem / CMarketAccessOverviewWindow / CMarketAccessOverviewItem / CTradeOfferWindow / CCancelSellingContractPopup / CIncomingLendLeaseEquipmentItem)

业务侧全收 §4.30.37 (含 **CMarketStockpileWindow 布局五槽** 与四命令: CMarketStockpileEquipmentTransferCommand id 13859 / COverrideMarketEquipmentPriceLevelsCommand id 14010 / CMarketStockpileClearCommand id 10191 / CCreateTradeCommand)。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 上架窗 | add_button 恒投 | win+1440 stockpile/+1448 卖方 ✓ | TransferCommand 双 64B 池; 价差加投 OverridePriceLevels | — | 定案 |
| 上架选格行 | [22..24] 覆写 | SMarketEquipmentData 72B@+40; 数量/价格档组件 ✓ | 基 CMarketEquipmentItem 25 槽 | — | 定案 |
| 准入总览窗/行 | [11] 枚举 gs+784 | 关系过滤 类型 26 推定; item+2784/+2788 双 tag | 确认 = CRequestMarketAccessRightsAction {+120=1 撤销} | — | 定案 |
| 资源要约窗 | send | 挂 CCountryTradeView+7952 | **CCreateTradeCommand {+40/+44/+48 资源 id/+56 量}**; 超运力延后派发 | — | 定案 |
| 卖方下架确认 | 全删/单条双分 (上游弹窗 = CCancelSellingContractPopup, ctor 0x14200A7F0 + 文案刷新器 0x14200C720, §4.31.110) | — | **CMarketStockpileClearCommand id 10191** / TransferCommand | — | 定案 |
| 租借进账装备行 | setter sub_141F2BE90 | controller+9168 网格; 舰载机门 元素+1000 ✓ | 与 §4.30.36 按国行边界划清 | — | 定案 |

**已解 2 项**: CPopUpWindow [11] = 装配/打开 (共享 0x140B7E3F0, 建窗绑 accept/decline 后委托 [14]), [12] = 关闭 (共享 0x140B7BE00, 单行转发 [15]) — 机制定案, 见 §4.00 槽表; **qword_14332F698 = CInGameIdler** (RTTI 实名, 主 vtable 0x142968FF0; 写点 = idler 族 vtable[11] 激活槽 sub_1402A2A10, 运行期 = 当前活动 idler)。

**定案**: 贸易目标双槽 = **CMarketAccessOverviewItem+2784/+2788 双 tag id (各 u32)** (写者 sub_1420049F0 / sub_142005A70 均 `*(item+2784)=*a3; *(item+2788)=*a4`; 件名 `market_access_item_entry`) / 租借行元素 = **CIncomingLendLeaseEquipmentItem** (vtable 0x142A95238, 件名 `diplomacy_incoming_lend_lease_equipment_entry`, ctor sub_141F263C0)。市场族类名补全 `NInternationalMarket::` 前缀: CAddToMarketEquipmentItem (0x142AB6170) / CMarketEquipmentItem (0x142AB3A88) / CCancelSellingContractPopup (0x142AAE7E0) / CMarketAccessOverviewWindow (0x142AADE80)。已闭: CTradeOfferWindow +40 次vtable = 0x142A60F80（COL 0x142D830C8, mdisp=40, 2 槽: [0]=0x141CB5770 / [1]=0x141CB4EF4 调整器 = 主 dtor 0x141CB4F50 的 this−40 位）。未决: 3 项「等」明细 (CFactionProgramItemEmpty / ItemBase 三张次vtable / CCreateTradeCommand 载荷)。

**CAddEquipmentToMarketWindow（上架窗，6528B；重锚后窗槽零漂移）**：主 vtable 0x142AB62B0（14 槽，[11] SetupDerived 0x14205A8F0）+ +16 次表 0x142AB6328；ctor 0x1420579B0；开窗 thunk 0x14200E950（capture+8 = 宿主；宿主+2928 窗缓存/+5120 另窗/+104 父 gui）；+1440 CMarketStockpile\*（= 宿主+136 值；数据源 sub_1413BA910 读 a2[13]=+104 属主国）/ +1448 CCountry\* 卖方（= 宿主+144 值；add 处理器读 \*(\*(win+1448)+656)+8 = 卖方 tag）——⚠ 宿主侧 +136/+144 语义 1.19.3 互换（见 §4.30.37 待裁）；+1456 嵌入按钮 add_button（sub_140B77E10 构造，SetupDerived 绑 lambda_4）；+2824 嵌入按钮 clear_all_button（lambda_5：清 +6348 / sub_1420593C0(+4208) / 清选格 / 全刷）；+4192 智能包装 "selected_equipment_grid" / +4200 "selected_equipment_grid_container" / +4208 组件（sub_142057060 构造 / sub_1420593C0 刷新）；**+4216/+4712/+5304/+5800 四组过滤器 96B 元数组基**（plane/tank/infantry/equipment-category，共 21 元×96B；widget 绑定：+6408(plane,5824B,初值4) / +6400(tank,7256B,初值5) / +6392(infantry,5824B,初值4) / +6384(equipment,5824B,初值4)；ctor 四循环步长 96、元+24 = a1+6360 哨兵链）；+6296 vector\<16B\> 已选 idpair 列（SelectEquipment lambda_2 push）；+6320 = 自指哨兵；+6348 i32 选中计数/状态（clear/teardown 清零）；+6360 变长数组 {data, cap+6368, count+6372, alloc+6376=&off_143085170}（数据源 sub_1413BA910 填 72B 元，同滤 elem+24 ≥100000）；+6416 widget / +6424 CCountryEquipmentList\* / +6432 "total_cic_cost" / +6440 map / +6504 map（malloc 40B 自指头）/ +6520 价格档 widget；add 出口 = sub_142059140（lambda_4 直转；卖方 tag/+6440 选中量/+6504 覆盖价）；合同列枚举 = sub_1413BAC30(out, stockpile, country)（实参序与宿主 lambda_4 体 sub_14200EBD0 随宿主互换）；teardown [12] = sub_1420592E0（清 +4192/+6384..+6408/+6520/+6348=0/+6440/+6504 map）。

**CTradeOfferWindow（贸易要约窗，4152B）**：主 vtable 0x142A60F58（4 槽：[0] dtor 0x141CB4F50 / [2] Reload 0x141CB6430）+ @40 tooltip 面 0x142A60F90；ctor sub_141CB48A0（"tradeoffer_window"；+48 CScrollbarObserverGlue{+56=this}；+144/+1432/+2720 三观察块 sub_141CB40C0×3；+4008/+4032 两容器）；+4056/+4064/+4072/+4080 = 上下文/tradeview/窗柄/自体国（ctor 写 a2/a3/0/country）；+4088 量 i32（−1 空；Reload 尾复写 −1）；**+4092 滑条上限**（滚动回调 sub_141CB5AD0：`v2 = *(DWORD*)(a1+4092)` → sub_141CB6B50(a1, val, v2)）；+4096/+4104/+4112/+4144/+4148 = send/buy_needed 控件、SSO 串（cap+4136=15）、i32、byte（Reload 分位回零）。

#### 4.31.60 航母/设施杂项 (CCarrierAirWingCompositionWindow / CCarrierAirWingCompositionEntry / CAssignResearchFacilityWindow / CAbstractStateControlController)

业务侧: 舰载机编成弹窗 (**窗 vtable 0x142A750D8, 2816B, CPopUpWindow 族**; target = 线 CRef@+2804 非 CShip; **CSetNavalProductionLineAirWingCompositionCommand {+40 line/+48 dep+48 映射}** Execute 0X14115C750 写回双 token 定案; 线+136 变体 / 线+272→dep+48 编成映射 §4.8/§4.8.2 互证; 经 CProductionLineNavalItem 开启; **与 §4.31.30 舰版编成编辑器同构**); **Entry** (vtable 0x142a75250, 2824B, 零覆写 Item 族; 行 = equipment_icon/name + number_box + ±按钮三回调, +32 装备项/+40 机数/+44 上限/+48 指回 win+2800, 内容由宿主窗 rebuild 直写); 设施指派窗收 §4.5 (真名 NFactions::NUi::; cc+4008+32 ✓✓; 候选出口 CAddFactionProgramCommand); 州控制子控制器收 §4.10 (CAsk/GiveStateControlAction {+120 states 向量}).

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 舰载机编成弹窗 | confirm | 线 CRef@+2804; 线+136/+272→dep+48 ✓✓ | **CSetNavalProductionLineAirWingCompositionCommand** (Execute 0X14115C750) | — | 定案 |
| 编成行 | 宿主 rebuild 直写 | +32 装备/+40 机数/+44 上限/+48 回指 | 零覆写 Item 族 | — | 定案 |
| 设施指派窗 | Setup ICF | cc+4008 program_status+32 ✓✓ | 纯选择器不投命令; 候选 = CAddFactionProgramCommand {+40/+48} | — | 定案 |
| 州控制子控制器 | 槽[21] OnStateClick | st+88/st+200/st+204 ✓✓✓; +32 动作 token 13781/13782 | Ask/Give 两派生 22 槽; **CAsk/GiveStateControlAction {+120 states 向量}** | — | 定案 |

**定案 3 项 + 高置信 1 项**: 修饰键对象 = **`*(qword_14332F698 + 1288)`** (会话 GUI 根输入修饰键对象; 实锚 mvt = 0x2B594D8, 8 槽), **三槽定名 (定案, keys.cpp 键名注册表绑定直证)**: **vtable+40 = Shift** (L/RSHIFT, handle E1/E5) / **vtable+48 = Alt** (L/RALT, E2/E6) / **vtable+56 = Ctrl** (L/RCTRL, E0/E4) — 槽体同构 = `IsDown(主键) || IsDown(副键)` (先主后副, 经 vtable[4] 分发器查 keystate 数组, 含 text-capture 守卫); 活调三槽无按键返 0。⚠ 初判「+48=Ctrl/+56=Alt」系猜测, 活体/静态双证为 **+48=Alt / +56=Ctrl** / 变体 stats[72]@+832、stats[73]@+840 = **EEquipmentStats 枚举 id 空间 72/73** (非 token; 成员名为纯编译期枚举, PE 仅存类型名与 `NUMBER_OF_EQUIPMENT_STATS` 断言串 — 负定案) / 设施窗族**零命令构造** (CAssignResearchFacilityWindow ctor sub_141468980 全文无 Command; CAddFactionProgramCommand 三构造点均在族外: sub_141C023A0 CFactionProgramItem 确认行 / sub_141C03790 / sub_141A4AC10) / 动作投递两段 = **sub_141C971E0** (控制器侧构建 + gate vtable+648/656/360) → **sub_1412EC4A0** (通用 CDiplomaticAction 提交) → **sub_1412F0480**; 选中集载体 = **action+120 u32 数组 {data@120, cap@128, count@132}**。

#### 4.31.61 任务/战略空军杂项 (CMissionExtensionEntry / CMissionMapIcon / CMissionMapIconEntry / CMissionIconItem / CStrategicAirView / CStrategicPriorityItem / CBoostIdeologyMissionItem / CBoostIdeologyMissionWindow)

业务侧: 任务图标/战略空军五件收 §4.31.61 (**CStrategicAirView 本体定案**: target = CStrategicRegion\*@+1696, 消费 CStrategicAir+224 按区 160B 态势缓存 region+96 索引 ✓✓; **wing+128 = bombing priority 建筑 def 集合新锚** + **CToggleBombingPriorityCommand {+40/+48}** — §4.31.40 两未决 (MapIconEntry 布局/战略目标窗命令出口) 已定案); CMissionExtensionEntry = 基类收 §4.16 (唯一直系后代 = 海军行); 理念提升两件收 §4.11 (**CSetOperativeMissionCommand {+40 country/+48 operative CRef 向量/+72 type=5+ideology}**, writer 键三证)。

类布局 (类名 / target / 锚点):

| 类 | target 形态 | 锚点 |
|---|---|---|
| CMissionMapIcon (空/海任务地图图标**抽象基**) | 扩展区 +136 观察块 / **+1424 = region** | 新增纯虚槽 [22][23][24]; 覆写槽全解: [2] 可见门/[3] 刷新/[4] 取锚点/[6] 判空/[7] 清 target; **空军层 13 "air_mission_mapicon" / 海军层 12 "naval_mission_mapicon"** |
| CMissionMapIconEntry (真·零覆写 72B 行件, air_mission_mapicon_entry) | 宿主构建器 0X1418CB920 建 18 格 | **button 阵 SetFrame = 任务位+1**; count/supply_icon/alert/supply_count(_small) 五阵偏移全定; **任务位 10 (补给空运) = supply_icon 唯一保留位** (构建器 `if (1<<位 != 1024)` 才 hide+锁显; 极性: 位 10 保留 supply_icon)) |
| CMissionIconItem (NAirInterfaceUtil; 24B; air_mission_util.cpp 断言实名) | 零覆写格件 | ctor 0X141C28A90 以 "mission_grid_item"/"mission_icon" 按**任务位掩码 SetFrame(ctz+1)**; 填充器 0X141C28C60 **跳过位 11** |
| CStrategicAirView (**战略空军视图本体**, strategicairview.cpp 实名, 0x2F70B) | **CStrategicRegion\* @+1696** (setter 0X141883F00) | Update 消费 **player CStrategicAir+224 按区 160B 态势缓存** (**region+96 索引 ✓✓**); Init 件位图表全列 (progress/wing_type 五阵/detection/efficiency/crypto_broken/air_combat_wnd); tooltip = AIR_SUPERIORITY_TYPE_ 族 |
| CStrategicPriorityItem (1360B) (NAirSelectionUI, bombing_priority_item) | def+740 帧聚合 def 向量 | 点击翻牌 **wing+128 priority 容器** (新锚 = bombing priority 建筑 def 集合, GUI 与 writer 双视角互认); 命令出口 = **CToggleBombingPriorityCommand {+40 air_wing CRef / +48 building def\*}** (writer 键 air_wing/building 双证); 窗 populate 走建筑库 qword_14332EE28 + "bombing_priorities_grid" ✓ |

**CWingQuickDeployWidget / CSelectedAirGroupView (快速部署/选中集团, GUI)**: CWingQuickDeployWidget (vtable 0x142AB6DD0, 1416B, **RTTI 实名 NAirSelectionUI::NQuickWingDeployment**, quick_wing_deployment_item): 目标 = **CQuickWingDeployOption\*@+32 + CAirBase@+40 ✓** (option 布局双命中 def+1448/+784); deploy 钮 → controller DeployWings 0X141965410 → **CDeployAirWingCommand** (vtable 0x142995198)。CSelectedAirGroupView (vtable 0x142A66AA0, **4240B 类本体**, 窗口实名 "air_group_view_entry"): 目标 = **CAirGroup CRef@+112** (group+120/+132 联队容器 ✓ §4.31.38); 联队快照向量@+120; populate 0X141CF4230 ✓ (超 define 按机型合簇建 CAirWingEntry ✓); 出口 = **CRenameAirGroupCommand {+40 集团 id, +48 名}** 与 **CChangeAirGroupInsigniaCommand (vtable 0x142A1E9C0) {+40 id, +48 CColor 内嵌, +80 索引}**。

**CAce 布局**: ace 对象全布局表 (含 +336 is_female) 见 §4.3.12 合并版 — 布局事实不滞留本节。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 任务图标基 | 覆写槽 [2][3][4][6][7] | +136 观察块/+1424 region | 纯虚槽 [22][23][24]; 空 13/海 12 双层 | air/naval_mission_mapicon | 定案 |
| 任务图标行 | 构建器 0X1418CB920 | 18 格; SetFrame = 任务位+1; 五阵偏移 | 任务位 10 不挂补给图标 | air_mission_mapicon_entry | 定案 |
| 任务格件 | ctor 0X141C28A90 | 任务位掩码 SetFrame(ctz+1); 跳过位 11 | air_mission_util.cpp 实名 | mission_grid_item | 定案 |
| 战略空军视图 | Update | CStrategicRegion\*@+1696; CStrategicAir+224 按区 160B 缓存 (region+96 ✓✓) | strategicairview.cpp 实名; 件位图表全列 | AIR_SUPERIORITY_TYPE_ 族 | 定案 |
| 战略目标行 | 点击翻牌 | **wing+128 priority 容器新锚**; def+740 帧聚合 | **CToggleBombingPriorityCommand {+40/+48}** writer 键双证 | bombing_priority_item / bombing_priorities_grid | 定案 |
| 理念行/窗 | FillPickableIdeologies | +1448 CIdeology\*; 窗+80..+96 任务四参/+248 选中 | **CSetOperativeMissionCommand 三键 writer 证** | assign_operative_boost_ideology | 定案 |

**定案 2 项**: 件型全局串解码 = CBoostIdeologyMissionWindow **`boost_party_popularity_mission_window`** (off_1430B3D88 → 0x1429F0698) / 行件 **`diplomacy_party_entry`** (off_1430B3D90 → 0x1429F06C0) / 巨窗宿主 = **CInGameInterfaceHandler** (1248B = 0x4E0 GUI 聚合根; 1.19.3 ctor = sub_140B614C0; 挂载 CInGameIdler+1720)。负定案: lambda Do_call ICF 折叠 (与 `_LocaleUpdate::GetLocaleT` 同址, PE 不可分离) 等 5 项。

#### 4.31.62 单位/部署杂项 (CUnitCounterItem / CUnitTemplateItem / CTinyUnitCounter / CReserveBottomBarItem / CWingQuickDeployWidget / CSelectedAirGroupView / CSendUnitsGroupItem / CMoveShipItem)

业务侧: 计数器/模板行收 §4.18; 迷你计数器收 §4.22; 预备底栏/移船行收 §4.16; 快速部署/选中集团收 §4.15; 派遣组行收 §4.10。**五命令**: CDeployAirWingCommand / CRenameAirGroupCommand {+40 id/+48 名} / CChangeAirGroupInsigniaCommand {+40/+48 CColor/+80 索引} / CMoveShipsCommand {+40 舰 refid 向量/+72 目标 navy/+80/+84/+85} / 派遣系推定未坐实。族级: 7/8 类零覆写 Item 族。

| 面板元素/行为 | 取值函数 | 对象+偏移 | 语义+出处 | loc key / 元素 | 置信 |
|---|---|---|---|---|---|
| 单位栈计数器行 | populate 0X1418DA680 | 单位 CRef 数组@+56/代表@+48; **类型@+384 (0 陆/1 海/2 铁路炮)** | 刷新分列 0X1418D9F80/0X1418D92A0; 无命令 | unit_counter_item.cpp | 定案 |
| 单位模板行 | IButtonEventFilter@+32 | CTemplateChanger\*@+1408 + CRef@+1416 | **SetFrame = DtplData+396 priority+1 ✓** | CANT_CHANGE_DUE_TO_* | 定案 |
| 迷你计数器 | 三非虚 setter | 背景色 = 单位+16 CColor; **spotting 条 = (1−progress/1e5/100)×宽** | 宿主池 +1472/+1484/+1496 ✓ | — | 定案 |
| 预备底栏项 | SetTarget 0X141DE7570 | 剧场 CRef@+32; taskforce_count@+1344 | fleetsbottombar.cpp; 无命令 | RESERVE_FLEETS_FOR_THIS_THEATER | 定案 |
| 快速部署翼控件 | DeployWings 0X141965410 | option\*@+32 + CAirBase@+40 ✓ (def+1448/+784 双命中) | **CDeployAirWingCommand**; RTTI 实名 NQuickWingDeployment | quick_wing_deployment_item | 定案 |
| 选中集团视图本体 | populate 0X141CF4230 | CAirGroup CRef@+112; 快照向量@+120 | **CRenameAirGroupCommand / CChangeAirGroupInsigniaCommand** 载荷全解 | — | 定案 |
| 派遣组行 | 折叠切换 +1384 | +32 组控制器/+40 divisions_summary 助手 | 出口推定宿主侧 (未坐实) | diplomacy_send_units_group_entry | 高置信 |
| 移船行 | AddShip 0X141BBC960 | **+48 = 舰 CRef 向量**; 上下文@+40 (其+1464 目标舰队) | **CMoveShipsCommand 载荷五键全解** | move_ship_entry | 定案 |

**定案 2 项**: +1388 写入点 = **sub_141C80FF0** (唯一写点 `*(a1+1388) = a2[1]`; 门/去重缓存 = *(a1+1384) u8; ctor sub_141C7B7D0 初值 `*(WORD*)(a1+1384)=0; *(a1+1388)=qword_14333D528`) / **CAirGroup+32 = icon (u32 帧 id, writer 键 181 `icon`)**, **+80 = name (SSO 串, 键 27 `name`)** — writer sub_1414EC490 尾三行 + reader sub_1414EBE00 四 case 逐键互证 (+48 = color 键 86 / +120 联队容器 键 13161 / +112 键 19949 air_theatre); ⚠ 书 §4.31.61「CAirGroup+32 = 名」系误记。未决: CTinyUnitCounter+88 / CMoveShipItem 三字段等 (CUnitCounterItem 五项已由下块消解)。

**CUnitCounterItem worker 补全 (定案, 原五项未决消解)**: 簇 5 函数全定性 (第 5 = **sub_1418D35C0 tooltip 构建器 3102 行**, CTooltipHandler 副 vtable 槽[0], this = item+24; 零直接调用者定因 = 全映像唯一取址在副 vtable)。**层级**: 主基 CStandardGridBoxItem(+0) + **CTooltipHandler 副基(+24, vtable 0x142A16690)**; 按钮回调 = 双 CButtonEventDispatcher (+416/+1704); 主 vtable 38 槽 (0x142A14960 止) 零簇函数 (「零覆写」限主表成立)。**方法名直证**: sub_1418D2410 = **CanAdd** (units_stack_map_icon.cpp:655 assert; 形参 bSplitSelected/bCoarseCountryGrouping), sub_1418D1ED0 = Add (类型门三 assert + pdx 向量入列 +56/+64/+68/+72)。**刷新双函**: 陆军 sub_1418D92A0 (14 GUI 子元素槽定名: +96 背景精灵 GFX_onmap_unit_counter[_empty] / 挖壕·姿态·命令·损耗·领导图标对 / +208 人像; item+280 芯片容器 = **CActiveAbilityItem** 0x38B, 新类 RTTI 直证, :2146 插入失败 assert) / 海军 sub_1418D9F80 (舰数 Σ / 使命类型 max / 载机翼容器 +320 (plane+1840) / +288 舰数文本 / +296 GFX_mapicon_air_base·rocket_site / +304 pride-of-fleet)。tooltip 按 item 特殊单位槽 (+128/+136/+152/+216/+224/+232/+240/+264/+296/+304) 分派, 未命中走 COARSE_COUNTER_* 聚合块 (item+409 门)。**宿主/入口**: CUnitsStackMapIcon::AddUnit = sub_141913420 (CanAdd 筛选→Add); 刷新链 sub_141913FC0→D8110; ctor sub_1418D1850 (元素名 unit_counter[_navy|_railway_gun], 尾调 populate)。**数值**: 挖壕 ÷100000 魔数核验; 供应三档 = SUPPLY_UNIT_COUNTER_{VERY_LOW,LOW,SHOW}_THRESHOLD; 单位 250 规模门三处一致。

#### 4.31.63 游戏规则行窗 (CGameRuleView / CGameRuleOptionView)

同构三表行窗 (CStandardGridBoxItem 19 槽@0 + CTooltipHandler 次表@24 + CLegacyButtonObserverGlue@32; 骨架 §4.00.6):

| 类 | vtable | GUI 名 | 绑定/自有 | sizeof |
|---|---|---|---|---|
| CGameRuleView | 0x142A99878 | game_rule_window | ctor 0x141F50D70; +32 钮 glue 回调 sub_141F53740; dtor 清至 +1432 | ≈1440 (高置信) |
| CGameRuleOptionView | 0x142A99758 | game_rule_option_dropdown_entry | ctor 0x141F50AF0; **+1336 = 规则 / +1344 = 选项**; 首刷 sub_141F540B0 | ≥1352 (下限定案) |

#### 4.31.64 装备域填空行件（设计师/概览/市场/AI 设计库）

同构分组（骨架 = §4.00.6 变体）:

| 分组 | 类 | 要点 |
|---|---|---|
| CClickableStandardGridBoxItem 23 槽族（Tooltip@24+胶水@88+共享 OnClick 0x1414A3980） | CDesignerEquipmentCreatorItem（designer_creator_entry, 1400B）/ CDesignerEquipmentRoleItem（tank_designer_role_entry, 1400 推定）/ CDesignerEquipmentVariantItem（designer_equipment_entry, 1392B）/ CEquipmentModuleCategoryEntry（equipment_module_category_entry, 1416B）/ CEquipmentModuleEntry（equipment_module_entry, 2816B, 字段尾 +2810 byte）/ CEquipmentModuleRemovalEntry（同 GUI 名, 2720B）/ CEquipmentRoleIconEntry（equipment_designer_niche_icon_entry, 1504B） | 设计师行件；Module 族带二级观察者分支@+1376 |
| 基 24B+二级vtable@24 族 | CEquipmentModelListItem（equipment_designer_3d_model_entry, 4288B, CButtonWrapper 1368B@+1328）/ CEquipmentBlueprintWindow（蓝图窗）/ NEquipmentDesigner::CEquipmentSpriteListItem（equipment_designer_sprite_entry, 1344 推定）/ CLogisticsInfoEquipmentItem（logistics_info_equipment_entry, 1352B）/ NAirWingReorg::CEquipmentEntry（空军改组行, 1456B, 池化传入） | — |
| CStandardlistboxItem 三表族（链 vtable 0x142B42BE0 24 槽） | NIO::CEquipmentIconItem（industrial_organisation_equipment_icon_item, 内嵌 CDynamicEquipmentGroup@96+CTraitBonus@312）/ NIO::CEquipmentTypeHeaderItem（industrial_organisation_equipment_type_window, 424 定案 — ctor sub_141FB9D10, MIO 详情窗装备类型头行, 构建点 sub_141F1AC70） | MIO 装备行 |
| 嵌入窗基族 | CEquipmentMessagePopup（内嵌 CEquipmentVariantPool@2752; 国 cc+4876 互证）/ NIM::CPurchasableEquipmentWindow（market_purchasable_equipment_window, 6864B, 事件向量@2584+三过滤钮） | — |
| 国际市场共享槽族（[19] 0x141FFC260 等 6 槽同址） | NIM::CEquipmentStockpileEquipmentItem（market_equipment_stockpile_entry, 4488B, 双嵌入窗@1616 绑 "modification_button" / 2984 绑 "remove_button"+双 Tooltip@4352/4416 载荷位 +4408/+4472+4480 子件 country_stockpile_status_amount 文本喂 sub_1422CA920）/ NIM::CPurchaseEquipmentItem（market_purchasable_equipment_entry, 1624B） | — |
| AI 序列化条目族（TGameItemDatabase 宿主） | CAIEquipmentRoleDatabaseEntry（字段 +8..+440）/ CAIEquipmentDesignUpgradeEntry（72B）/ CNullAIEquipmentRoleDatabaseEntry（"NullAIEquipmentRole" 键, 448B）/ CNullAIEquipmentDesignEntry（"NullAIEquipment" 键, 800B）/ CAIEquipmentDesignModuleSlotEntry（token 27/10314/15356→+108 旗） | 数据条目非控件; 布局定案 |
| 概览/租借 | CEquipmentVariantDetailItem（overview_equipment_entry, 1336B）/ CEquipmentVariantEntry（equipment_lend_lease_entry, 1336B, 父=iface+1272）/ CLendLeaseEquipmentItem（diplomacy_lend_lease_equipment_entry, 1384B, variant@+1368 与 §4.31.15 互证）/ CEquipmentArchetypeHeaderItem（overview_archetype_header_list_entry, 11 绑定） | — |
| 独立窗 | CEquipmentUpgradeDesignerWindow（equipment_upgrade_designer_window, 25920B, CTextBufferObserverGlue@2784+型号件@25872） | — |

> 新骨架速查：CStandardGridBoxItem 基vtable（1.19.3）= 0x142B45EF0（19 槽），基 ctor 0x1422C6040 / 基 dtor 0x1422C6230（工厂名 = parent vtable[12] CreateChild 的 .gui 元素名）；CTooltipHandler 64B（载荷@+56，dtor 0x14011EB50）；子件内嵌派发器 @+128、父派发器表 @容器+4312（count@4324）；子件查找槽 父[13]=+104/[15]=+120/[17]=+136，释放 [69]=+552；会话接口宿主 qword_14332F698+1272。

#### 4.31.65 国别域填空行件（国旗行/选择行/过滤器行）

| 类 | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---:|---|---|
| CFactionCountryListWindow | faction_countries_window（派生实例） | 1520（派生 2888 直证；CFactionPingWindow 内联基域写至 +1515 复证） | 阵营成员国列窗基窗 | 定案 |
| CGameSetupRandomCountryWindow | gamesetup_pick_random_country_window | 2904 | 随机国家挑选窗（3×CCheckBoxObserverGlue） | 定案 |
| CCountryConstructionViewBuildingItem | start_construction_entry | 1328 | 建设视图可建建筑行（def+740 使能→选址） | 定案 |
| CCountryFilterEntry | country_filter | 1496 | 感兴趣国家过滤器行（EFilter+LexerToken 字段 RTTI 直证） | 定案 |
| CCountryItem | country_filter_entry | 1424 | 国家过滤器行 | 定案 |
| CCountryLeaderTraitItem | advisor_trait | 1528 | 将领特质下拉行 | 定案 |
| CCountrySelectionEntry | country_entry | 1432 | 感兴趣国家选择行（CMinorCountrySelectionEntry 之基） | 定案 |
| CDiplomacyCountryListCountryItem | diplomacy_country_list_country_entry | 1368 | 外交国列表行 | 定案 |
| CFactionInvitedCountryEntry | negotiator_flag_entry | 96 | 已受邀国旗行 | 定案 |
| CFactionPingCountryItem | faction_ping_item | 1496 | 集结 ping 行（虚继承 tooltip 特例 vbptr@1448） | 定案 |
| CInviteCountryItem | invite_country_item | 1464 | 邀请国行（ctor 内联于 populate） | 定案 |
| CKickFromFactionCountryItem | kick_from_faction_country_item | 2840 | 踢出国行（双 CButtonWrapper） | 定案 |
| CTradeCountryItem | country_trade_entry | 1416 | 贸易国行 | 定案 |
| CEndGameCountryEntry | endgame_country_entry | 80 | 终局结算国行（无 tooltip 基） | 定案 |
| CCountryEnemyFlagItem / CCountryTradeFlagItem / CCountryWargoalFlagItem | countryflag_entry 基 | 48 | 敌国/贸易/战目标旗行（Wargoal = "threating_countries" 列） | 定案 |
| CCountryFlagGridBoxItem | countryflag_entry | 40 | 国旗格行基类（+32 国家 idx） | 推定 |
| CCountryOrFactionItem | navallosses_dropdown_item | 1352 | 海损国/派系行（⚠ §4.31.1「+32 国家 idx」对本类不成立） | 定案 |
| CCountryScorerEntry / CBookmarkCountryEntry / CCountryTagAliasEntry | —（数据件） | 48/344/864 | 国家评分数据 / 开局书签国数据 / tag 别名数据件（countrytagalias.cpp 直证，CScriptTargets 基） | 定案 |

> 新锚 (六视图本体表见 §4.30.30)：装配器 0x140B614C0 统一 malloc 并挂宿主 +232/+240/+272/+288/+328/+336；1288B 窗件块与 1368B CButtonWrapper 两个共享构件定案；CTooltipHandler = 2 槽接口（[0]=FillTooltip）。**定案**：CStandardGridBoxItem 全 exe 唯一基表 = 0x142B45EF0（COL 0x142DDF5C0，19 槽）；0x142B440D0 非表首（其 vtable−8 处为串常量 `OutOfTurr` 尾，非 COL 指针），真表首 = 0x142B440D8 = `CPdxHybridInlineBufferAllocator<CGraphicalObject*,4,int>`（8 槽）。

**CCountryConstructionViewBuildingItem (1328B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 匿名结构 (NNB 形状)* | 构造上下文（建筑定义侧；项 +740 使能值 → facet+176 SetEnabled；可建谓词 sub_1406896B0，高置信） |
| +40 | 窗件块 (1288) | 回调 sub_141716D10；收尾恰至 1328 |

> ctor 内查子件 "start_construction_button"；点击按 def 使能旗开地图选址模式。

**CCountryItem@NCountryFilterUI (1424B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | uint64 | 0 |
| +40 | uint64 | 0 |
| +48 | CButtonWrapper (1368) | 至 1416 |
| +1416 | uint32 | 0 |
| +1420 | uint8 | 1 |

> ctor 查子件 "country_name" / "country_flag" / "country_filter_button"，点击走 0x48 字节 _Func_impl lambda。

**CCountryOrFactionItem (1352B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 窗件块 (1288) | 回调 sub_1417F70E0；至 1320（⚠ +32 非国家 idx） |
| +1320 | uint64 | 0 |
| +1328 | uint32 | 0 |
| +1336 | uint64 | 0 |
| +1344 | uint8 | 0 |

> ctor 查子件 "bg" 挂窗件块（facet+128 槽 [1]）。

**CCountrySelectionEntry (1432B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | CGameSetupInterestingCountriesWindow* | 窗口上下文（CGameSetupInterestingCountriesWindow，lambda 签名直证） |
| +40 | CGuiObject* | 父 gui |
| +48 | 匿名结构 (NNB 形状)* | 参 a4（高置信） |
| +56 | CGuiObject* | 查得子件（"new_content…"，ctor 后填，高置信） |
| +64 | CButtonWrapper (1368) | 至 1432 恰满 |

> CMinorCountrySelectionEntry 之基（0x141F40D00 先调本 ctor 再覆写vtable）；两条 lambda 消费 CBookmarkCountryEntry const&（组 D/组 A 互挂）；vtable 20 槽（[19] = 0x14253C3B8 纯虚）。

**CCryptologyViewCountryEntry (4000B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | uint32 | 0 |
| +40 | 窗件块 (1288) | 回调 sub_141A21210 |
| +1328 | 窗件块 (1288) | 同型 |
| +2616 | 窗件块 (1288) | 同型 |
| +3904..+3992 | 12×uint64 | 零初始化尾块（向量组，推定） |

> 父 gui 由全局单例直取（不经调用者传）。

**CDiplomacyCountryListCountryItem (1368B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 匿名结构 (NNB 形状)* | 所属窗拷贝（=a2） |
| +40 | 窗件块 (1288) | 回调 sub_141C80DD0；至 1328 |
| +1328 | uint32 | 入参 \*a4（国相关 id，推定 tag idx） |
| +1336 | CGuiObject* | 入参 a3 |
| +1344 | uint64 | 0 |
| +1352 | uint32 | 0 |
| +1360 | CGuiObject* | 查得子件 "relations"（ctor 末写） |

**CEndGameCountryEntry (80B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | uint32 | 入参 a4（国别侧 id；随后 sub_140BB48F0 取国 → 建 "pol_faction_icon" 件） |
| +32..+76 | 7×uint64 | 零初始化（结算列数据，填充期写，推定） |

> 无 CTooltipHandler 基（COL 定案）；基 ctor 以 a3 为名串。

**CTradeCountryItem (1416B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 窗件块 (1288) | 回调 sub_141CBD6B0；至 1320 |
| +1320 | CGuiObject* | 入参 a3（上下文 A） |
| +1328 | CGuiObject* | 入参 a4（上下文 B） |
| +1336..+1352 | 3×uint64 | 0 |
| +1360 | uint16 | 0（贸易量/旗组，推定） |
| +1362 | uint8 | 0 |
| +1364 | uint64 | 0 |
| +1372 | uint32 | 0 |
| +1376..+1408 | 4×uint64 | 0 |

> ctor 末 sub_141CBD6F0 刷新；遍历描述子 +4312/+4324 列表把窗件块挂到各子件（与外交国行同构）。

**旗行件组（CCountryFlagGridBoxItem 系）**：

| 类 | 偏移 | 类型 | 名称/语义 |
|---|---|---|---|
| CCountryFlagGridBoxItem | +32 | u32 | 国家 idx（sub_140BB5490(tag)，0 兜底；刷新件 sub_141C411A0 边界校验 vs 国家定义库 dword[3] → sub_140BB3E00 → sub_140B44AC0 设旗） |
| CCountryEnemyFlagItem | +40 | u32 | 状态位（战争总览 "enemies" 侧栏；工厂 0x141C99DA0，创建后 sub_141C41050(item, tag) 刷新） |
| CCountryTradeFlagItem | +40 | u32 | tag_id（ctor 以 sub_140BB3E00(idx0→tag) 写入；贸易视图 "flags" 列） |
| CCountryWargoalFlagItem | — | — | 战目标旗行（"threating_countries" 列表行；ctor 体在 0x141C9A8C0 工厂内） |

> 三子类恒 48B（基 40 推定 + 自有 dword，malloc(48) 直证）；tooltip 槽 [0] 0x141C3FFA0 同数据链。

**CCountryFilterEntry (1496B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +64 | CGuiObject* | 查得 gui 元素（基 ctor 写） |
| +72 | CGuiObject* | 入参 a3（窗上下文） |
| +80 | CGuiObject* | 父 gui（=a2） |
| +88 | CButtonWrapper (1368) | 至 1456；"button" 子件挂入 |
| +1456 | uint32 | EFilter 枚举（lambda RTTI 直证；=2 时再取名串入 +1464） |
| +1460 | uint32 | LexerToken（经 sub_1424BC260 取名） |
| +1464 | MSVC 串 32B | SSO（cap@+1488=15） |

> COption 语义：选中态过滤枚举；无 CTooltipHandler 基（COL 定案）；列表系基链骨架 = +0 主表 / +56 TListboxItem 次表（+72 或 +104 CTooltipHandler），CStandardlistboxItem 基 ctor sub_1422A9260、CSmoothListboxItem 基 ctor sub_1422FF1F0。

**CFactionInvitedCountryEntry (96B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +56 | CClass* | TListboxItem 次表 |
| +72 | CClass* | CTooltipHandler 次表（三表齐写） |
| +80 | uint32 | 国家 tag（\*a3；随后 sub_140B44AC0 设旗） |
| +88 | CGuiObject* | 查得 "flag" 子件 |

> 填充器 0x141822E30 从阵营外交态两组 4B tag 流（+368/+380、+400/+412）建行。

**CCountryLeaderTraitItem (1528B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +56 | CClass* | TListboxItem 次表 |
| +104 | CClass* | CTooltipHandler 次表（CSmoothListboxItem 链） |
| +112 | CGuiObject* | 入参 a3 |
| +120 | CGuiObject* | 特质定义（名串取 +24 副本进 "name" 子件，高置信） |
| +128 | CGuiObject* | 入参 a6 |
| +136 | uint32 | 0 |
| +144 | 窗件块 (1288) | 回调 sub_1416CCC40；至 1432；"bg" 子件挂入 |
| +1432 | 匿名结构 (NNB 形状) | sub_1416C88E0(…, a5) 初始化；至 1528 恰满（语义推定） |

**CBookmarkCountryEntry (344B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | 匿名结构 (16B 形状) | 书签国定义拷贝（_OWORD 入参；{tag 侧 u32, u32} 推定） |
| +24 | MSVC 串 32B | SSO（cap@+48=15） |
| +56 | uint64 | 0 |
| +64 | uint64 | 0 |
| +72 | 24B 向量 | 空向量（锚 off_143085170） |
| +96 | 24B 向量 | 空向量 |
| +120 | 24B 向量 | 空向量 |
| +128 | 匿名结构 (24B 形状) | sub_14011DF40 构造（语义推定） |

> CPersistent 直系（9 槽 [1]Save/[3]Load wrapper）；[2]/[6]/[7]/[8] = guard nop；被开局感兴趣国家窗 lambda 消费。

**CCountryScorerEntry (48B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CClass* | CProfiledScopeObject 次表 |
| +16 | uint32 | 入参 int（国别侧 id，推定 tag idx） |
| +24 | uint64 | 0 |
| +32 | uint64 | 0 |
| +40 | uint64 | alloc anchor（向量头残块，至 48） |

**CCountryTagAliasEntry (864B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CClass* | CScriptTargets 次表 |
| +16 | uint16 | 0 |
| +18 | uint8 | 0 |
| +24 | 块 (280) | sub_140549F40 初始化（别名块 A；内含 +112 第二块、+192/+216 两 24B 对象、+240/+248 字节，语义推定） |
| +264 | uint32 | 别名 tag（ctor 末断言其不存在于国家定义库，countrytagalias.cpp:22） |
| +272 | 数组 (208) | sub_14014AFD0 构造（语义推定） |
| +480 | uint8 | 0 |
| +488 | uint32 | 0 |
| +496 | uint64 | 0 |
| +504 | 块 (88) | sub_140549F40（别名块 B，语义推定） |
| +592 | uint8 | 0 |
| +600 | 块 (56) | sub_1405516A0(…,4)（语义推定） |
| +656 | 数组 (208) | sub_14014AFD0 |

> 槽 [8] = 0x140721400 = **别名无原 tag / 无目标 诊断发射器**（`countrytagalias.cpp:82`，读 `*(BYTE*)(sub_14039DF40()+128)` 门 → 三条件全假时置 +480 一次性旗并 `sub_1424C8E60` 发告警串）；定案。

**CFactionCountryListWindow (1520B 基域)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +104 | uint64 | 0 |
| +112 | CButtonWrapper (1368) | 至 1480 |
| +1480 | uint64 | 0 |
| +1488 | uint64 | 0 |
| +1496 | uint64 | 0 |
| +1504 | 24B 向量头 | 锚 |
| +1512 | uint32 | −1（选中/页哨兵，推定） |

> CReloadableWindow 链 11 槽；实例化形态 = 派生 CFactionMemberCountriesWindow（ctor 0x141ADA8F0，malloc 2888 @0x141472080，自有 +1520 CButtonWrapper）；槽 [4] 0x141ADD860 = populate 重建国列、[5] 0x141ADB790、[9] = CReloadableWindow 基槽；本窗是阵营三行（下）的宿主（Kick lambda 签名直证；Ping/Invite 由其 populate 0x14179D040 / 0x141ADEC30 建）。

**CGameSetupRandomCountryWindow (2904B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +40 | 窗件块 (1288) | sub_141F3B320，回调 sub_141F3BF00；至 1328 |
| +1328 | 窗件块 (1288) | 同型，回调 sub_141F3BFA0；至 2616 |
| +2616 | CCheckBoxObserverGlue (64) | fn sub_141F3BF10 |
| +2680 | CCheckBoxObserverGlue (64) | fn sub_141F3BF40 |
| +2744 | CCheckBoxObserverGlue (64) | fn sub_141F3BF70 |
| +2808 | CGuiObject* | 父 gui（a2） |
| +2816 | 匿名结构 (NNB 形状)* | 容器（a3） |
| +2824 | CGuiObject* | _pWindow（窗 "gamesetup_pick_random_country_window"; 初始化 0x141F3CB00 经父 +1272 vtable[12] 建, 断言 :39） |
| +2832 | CGuiObject* | _pScrollableWindow（"scrollable_container", 窗 vtable[55], :47） |
| +2840 | CGuiObject* | _pIncludeMajorsCheckbox（"include_interesting_majors_cb", scrollable vtable[21], :76） |
| +2848 | CGuiObject* | _pIncludeMinorsCheckbox（"include_interesting_minors_cb", :77） |
| +2856 | CGuiObject* | _pIncludeOthersCheckbox（"include_other_countries_cb", :78） |
| +2864 | CGuiObject* | _pButtonBar（"button_bar", :52） |
| +2872 | CGuiObject* | _pCloseButton（"close_button", bar vtable[13], :58; 回调 ← +40 块） |
| +2880 | CGuiObject* | _pPickRandomButton（"pick_random_button", :59; 回调 ← +1328 块; ctor 清零致旧观感为 0） |
| +2888 | CGuiObject* | _pErrorText（"error_text", bar vtable[15], :60） |
| +2896 | uint8 | **majors 复选框初始勾选态**（ctor 全 1; 原「u16 =257 旗组 0x0101 推定」系编译器合并三次字节存的误读, 定案） |
| +2897 | uint8 | **minors 复选框初始勾选态**（=1） |
| +2898 | uint8 | **others 复选框初始勾选态**（=1） |

> 初始化 0x141F3CB00 / checkbox 段 0x141F3D200 (断言 :76/:77/:78; 初始态应用 = 非 0 → sub_1422C9DB0 勾选否则 sub_1422C9F20, 随后 sub_1422C8E90(cb,0) 刷新)。

> CReloadableInterface 直系 4 槽小vtable；槽 [2] 0x141F3C970 = 可见性刷新（byte165&8 扫描）；过滤器行与选择行的 lambda 均持本窗引用。

**阵营三行**（宿主 = CFactionCountryListWindow；基 ctor sub_141ADA460 = CFactionCountryItem：+24 tooltip 上下文 / +40 "name" 子件 / +64 CButtonWrapper 至 1432 / +1432 byte / +1436 u32=1 / +1440 u32=2）：

| 类 | 偏移 | 类型 | 名称/语义 |
|---|---|---|---|
| CKickFromFactionCountryItem | +1448 | CClass* | CTooltipHandler 次表（COL：this=1448） |
| CKickFromFactionCountryItem | +1456 | CButtonWrapper (1368) | 第二按钮包裹（移除按钮），至 2824 |
| CKickFromFactionCountryItem | +2824 | 指针 | 色块子件（名色 0x5050C6，高置信） |
| CKickFromFactionCountryItem | +2832 | 指针 | "leader_border" 子件 |
| CInviteCountryItem | +1448 | CClass* | CTooltipHandler 次表（自有尾域与 Kick 同构，推定；无独立 ctor——邀请窗 populate 直接 malloc 构造） |
| CFactionPingCountryItem | +1448 | vbtable 指针 | 虚继承特例：&unk_1429FF188（按旗 a4 条件置；ctor 显式算 \*(this+vboff+1444) = vboff−40），虚基 CTooltipHandler 表经 vbptr 解引 @+1488 |
| CFactionPingCountryItem | +1456 | 指针 | 子件 "divisions" |
| CFactionPingCountryItem | +1464 | 指针 | 子件 "fleets" |
| CFactionPingCountryItem | +1472 | 指针 | 子件 "disabled" |

#### 4.31.66 账本/国策/决议填空行件

> 横断事实：sizeof 全部 malloc 直证（工厂 caller 内 malloc 与 ctor 调用逐一配位）；共享 dtor 四组（ICF 折叠）与 sizeof 两两互证；**新中间基类 CDecisionViewDecisionItemBase**（ctor 0x141D704E0，+24..+1312 胶水）= 普通/计时/定向决议行公共前缀；CNationalFocusView 行向量 +1448（104B 元）、六 24B 指针向量（8280/8304/8328 ✓书，8352/8376/8400 归属未决）；观察者区：+2968 = CTextBufferObserverGlue\<CNationalFocusView\> + 8×16B 回调（回调区 +2984..+3112；[0][1]=sub_14138ACF0/[2]=sub_14138ABE0/[3]=sub_14138AC20 余空）、+3128 观察者区 1（sub_14137DDC0 建；cb sub_14138B470 = ShowRest 切换）、+5704 观察者区 3（cb sub_14138A7D0）、+6992 观察者区 4（cb sub_14138ABE0）、+8472 = 1.0f、+8728/+8776/+8800 容器×3（拆除序 8800→8776→8752→8728；书 win+8728/+8824 搜索结果域）。⚠ 方法坑：ICF 折叠会令 dtor 带错误符号名（0x14064CF60 被挂成 stringbuf dtor）——按vtable反查 dtor 必须先验函数体。

| 类 | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---:|---|---|
| CNationalFocusView | nationalfocusview | 8864 | 国策面板主窗（4 vtable 位挂接，主接口在 +48） | 定案 |
| CNationalFocusTreeItem | national_focus_item | 1360 | 树内国策行（def@+32，View*@+1328） | 定案 |
| CNationalFocusExclusiveItem | national_focus_exclusive_item | 96 | 互斥国策对行（defA/defB@+32/+40，5 子件） | 定案 |
| CNationalFocusLinkItem | （参数传入） | 40 | 树连线纯视觉行 | 定案 |
| CNationalFocusFilterItem | （参数传入） | 1432 | 过滤行（96B 描述符逐项展开 +40/+72/+104/+112） | 定案 |
| CNationalFocusFilterShowRestItem | （参数传入） | 1320 | 显隐切换行（无 TooltipHandler，+24=View*） | 定案 |
| CNationalFocusShortcutItem | （参数传入） | 1336 | 快捷跳转行（+40 = tree+128 描述符条） | 定案 |
| CGameSetupFocusItem | focus_entry | 48 | 开局国策选择行（def@+32，内联 ctor） | 定案 |
| CAIFocusDatabaseEntry | —（库条目） | 120 | AI 国策库条目（宿主 CAIFocusDatabase=88，单例 qword_14332EE08） | 定案 |
| CDecisionViewCategoryItem | category_header | 2664 | 决议类别页签行（SetTarget[19]→+72） | 定案 |
| CDecisionViewCategoryInfoItem | decision_category_desc | 136 | scripted_gui 类别描述行（SetTarget→+32） | 定案 |
| CDecisionViewDecisionItem | decision_item | 4024 | 普通决议行（def@+4016，26 槽，槽表全定） | 定案 |
| CDecisionViewOnMapLocatorItem | on_map_decision_locator_item | 1408 | 地图决议定位行 | 定案 |
| CIntelLedgerTechnologyEntry | ledger_tech_entry | 1344 | 账本科技行（"button"@+1336） | 定案 |
| CIntelLedgerDoctrineEntry | ledger_tech_entry（克隆名） | 1416 | 账本学说行（CButtonWrapper 1368B@+48） | 定案 |
| CIntelLedgerIdeaEntry | ledger_idea_entry | 72 | 账本精神行（"icon"@+40） | 定案 |
| CLedgerAirwingHeaderEntry | ledger_airwing_header_entry | 72 | 账本联队头行（tag/archetype/数@+32/40/48 逐位） | 定案 |
| CLedgerArmyTemplateEntry | ledger_template_entry | 72 | 账本师模板行（idpair@+32，ctor sub_141EB0EB0 初值 = qword_14333D528 空哨兵；+48 = "name" 控件） | 定案 |
| CLedgerStockpileEntry | ledger_equipment_stockpile_entry | 96 | 账本库存行（⚠ ≠G1 装备侧库存行） | 定案 |
| CLedgerShipTypeEntry / CLedgerShipEntry / CLedgerShipHeaderEntry | ledger_ship_* | 72/80/80 | 账本舰型/舰/舰头行（后两者同构共 dtor） | 定案 |

#### 4.31.67 阵营/外交填空行件

> 横断事实：① **主/次vtable判定法则**（COL+4 offset 字段 = 16/48 等非 0 ⇒ 次基表；主表 COL offset=0 且 signature=1）——RTTI 扫描给出的类地址可能是次表，用前必验（本节 16 类 6 类命中）；② **新底座基类**：CMapIcon（ctor 0x14163F310：+36 float = 全局图标流水号（dword_14338AA18 自增）、+108 byte = 图标类型、基域至 127；图标工厂 0x140B71B50 按 int 类型 34 分支分派，case 32 = 阵营 ping）、NProject::NUi::CProgramListBase（ctor 0x141C05C30 / dtor 0x141C05E20，4 槽）、NFactions 弹窗封装 CFactionPopup（ctor 0x141BFE5B0(this, int 弹窗 id)，.gui 名 "faction_popup"，弹窗 id 枚举见下表）；③ CFactionCountryListWindow 基 sizeof 1520 经 PingWindow 内联基域升级定案；CReloadableWindow 基 ctor = sub_1422DBB20（this, 父 gui, 名串；名串以 {指针,长度} 16B 传入）；④ 19 槽网格行件 [1..18] 与 CStandardGridBoxItem 基表 0x142B45EF0 逐槽同址（第三批复证，定案维持）；⑤ tooltip 注册范式 = 窗体+48 facet 的 vtable+552 槽（传 this+24 tooltip 子基），本节四处 ctor 复证。

| 类 | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---:|---|---|
| CDiplomacyJoinAllyWarRelationItem | diplomacy_join_ally_war_entry | 1344 | 外交行动页·加入盟友战争行（**+1304 CWarRelation\* pWarRelation** (FillTooltip 断言直证, §4.31.105) / +1320 外交窗 / +1328 战争对象; 存战争对象+攻/守侧） | 定案 |
| CDiplomacyLendLeaseItem | diplomacy_lend_lease_entry | 9336 | 外交租借页·装备租借行（7×1288B 窗件块+文本胶水） | 定案 |
| CDiplomacyPartyItem | diplomacy_party_entry | 1344 | 外交行动页·政党行动行（boost party） | 定案 |
| CDismantleFactionConfirmationWindow | faction_popup(id1) | 4200 | 解散阵营确认弹窗 | 定案 |
| CLeaveFactionConfirmationWindow | faction_popup(id2) | 4200 | 退出阵营确认弹窗（dtor 与 Dismantle ICF 共享） | 定案 |
| CInviteToFactionPopup | faction_popup(id12) | 4224 | 邀请入阵营弹窗（+4216 引用计数对象） | 定案 |
| CKickFromFactionPopup | faction_popup(id11) | 4208 | 踢出国确认弹窗 | 定案 |
| CIncomingLendLeaseDiplomacyPopup | diplomacy_incoming_lend_lease_popup_window | 5432 | 收到的租借提议弹窗（行动类型 14027 分派；主表 0x1429F9948 16 槽） | 定案 |
| CEndGameFactionEntry | （名串调用者传） | 32 | 终局结算阵营行（+24 = 阵营语境指针；ctor 查 name/strength/member 三子件喂文本） | 定案 |
| CFactionCommanderItem | faction_commander_item | 4384 | 阵营将领行（肖像/剧场/技能/受派州，3 wrapper+复选胶水） | 定案 |
| CFactionInfluenceEntry | faction_influence_entry | 24 | 新建阵营窗影响力页国行（纯基域 24B；比率 = 100000×value/total 万分比；loc CREATE_FACTION_FACTION_INFLUENCE_ENTRY） | 定案 |
| CFactionPingMapIcon | faction_ping_map_icon（图标类型 32） | 1536 | 地图阵营 ping 图标（CMapIcon 底座+CButtonWrapper） | 定案 |
| CFactionPingView | factionpingview | 1416 | 国家面板 ping 视图（CCountryView 第六视图，挂宿主 +376；主表 0x14294B0E0 17 槽） | 定案 |
| CFactionPingWindow | faction_ping_window | 11432 | 阵营国列 ping 派生窗（虚基 CTooltipHandler@11424，8 wrapper） | 定案 |
| CFactionProgramList | （宿主内联） | 80 | 研究区设施项目列表控件（CProgramListBase 直系） | 定案 |
| CNewFactionTemplateItem | new_faction_template_item | 1472 | 新建阵营窗模板行（select_button+rule/goal 窗） | 定案 |

**弹窗 id 枚举**（CFactionPopup+4192 dword；总装 0x141472080 逐 id malloc，定案；基形 4200 / id 11 = 4208 / id 12 = 4224）：

| id | 语义 |
|---:|---|
| 1 | 解散阵营确认（CDismantleFactionConfirmationWindow） |
| 2 | 退出阵营确认（CLeaveFactionConfirmationWindow） |
| 3 | 成为阵营领袖 |
| 4 | 确认目标 |
| 5 | 确认规则 |
| 6 | 确认阵营设施项目 |
| 7 | 阵营情报 |
| 8 | 阵营战区 |
| 9 | 任命战区领袖 |
| 10 | 学说共享 |
| 11 | 踢出国确认（CKickFromFactionPopup） |
| 12 | 邀请入阵营（CInviteToFactionPopup） |

**CFactionPopup 弹窗域**（四确认弹窗共用底座域，定案）：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1440 | uint64 | 0 |
| +1448 | uint64 | 0 |
| +1456 | CButtonWrapper (1368) | |
| +2824 | CButtonWrapper (1368) | |
| +4192 | uint32 | 弹窗 id（枚举见上表） |

> 主表 19 槽形：[1..13] 与 [18] 四类全同址（定案），[0]/[14]/[15]/[16]/[17] 各类独异（[0] 仅 Dismantle/Leave 因 ICF 折叠共享 0x14146CD20）；+16 次表 4 槽（[0] 调整器 this−16 → 真 dtor）；+56 次表 2/7/11 槽（[1] 调整器 this−56）；四类 ctor 全部内联于阵营窗总装 0x141472080。

**CDiplomacyJoinAllyWarRelationItem (1344B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 窗件块 (1288) | builder 0x141C78460，回调 0x141C80E30 |
| +1320 | CGuiObject* | 入参 a3 = 外交窗 |
| +1328 | 匿名结构 (NNB 形状)* | 战争对象（工厂由攻守 tag 对经 sub_141986BA0 解析回填） |
| +1336 | uint32 | 加入侧（战争对象 +16/+20 两 id 按 sub_1401B0250 比对二选一） |
| +1340 | uint8 | 0 |

> dtor 0x141C7BFD0；宿主 = 外交窗 gridbox @+2616（count +2628）；FillTooltip 0x141C7F0F0（DIPLOMACY_ATTACKERS/DEFENDERS 列表）。

**CDiplomacyLendLeaseItem (9336B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | CGuiObject* | 入参 a2 = 父 gui |
| +40 | CGuiObject* | 入参 a3 = 宿主 |
| +48 | uint32 | 0 |
| +56..+80 | 4×uint64 | 0 |
| +88 | 窗件块 (1288) | builder 0x141F24B90，回调 0x141F29CB0 |
| +1376 | 窗件块 (1288) | 同 builder，回调 0x141F29E20 |
| +2664 | 窗件块 (1288) | 同 builder，回调 0x141F29D70 |
| +3952 | 窗件块 (1288) | 同 builder，回调 0x141F29B60 |
| +5240 | 窗件块 (1288) | 同 builder，回调 0x141F29B10 |
| +6528 | 窗件块 (1288) | 同 builder，回调 0x141F2B670 |
| +7816 | 窗件块 (1288) | 同 builder，回调 0x141F29B90 |
| +9104..+9144 | 6×uint64 | 0 |
| +9152 | CTextBufferObserverGlue (160) | {vtable, self, fn=0x141F29B40, 回调区}；文本刷新订阅 |
| +9312 | uint64 | 0 |
| +9320 | uint64 | 0 |
| +9328 | uint16 | 0 |
| +9330 | uint8 | 0 |

> 七块首槽运行期覆写 CButtonEventDispatcher vtable（dtor 复证七块位）；尾布线 sub_141F2A690；dtor 0x141F272D0；行池 = 外交视图宿主 +9144/+9160；FillTooltip 0x141F290D0（LEND_LEASE daily/percent/equipment 族 loc）。

**CDiplomacyPartyItem (1344B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 窗件块 (1288) | builder 0x141C78880，回调 0x141C80EC0 |
| +1320 | CGuiObject* | 入参 a3 = 外交窗 |
| +1328 | uint64 | 0（工厂回填位） |
| +1336 | uint8 | 0 |

> 与 CDiplomacyJoinAllyWarRelationItem 双生（工厂相邻、同宿主域；vtable 池尾串 diplomacy_action_entry_bg 与 DIPLOMACY_ACTION_*_COST loc 互证）；dtor 0x141C7C040；FillTooltip 0x141C7F7E0（BOOST_PARTY_SELECT_TT + NAME/CURR/WHY/CHANGE 列）。

**CFactionCommanderItem (4384B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | 匿名结构 (16B 形状) | 子件 "leader_stat_mastery"（sub_141C15020 名建） |
| +48 | 匿名结构 (16B 形状) | 子件 "leader_stat_supply" |
| +64 | 匿名结构 (16B 形状) | 子件 "supply_navy_value" |
| +80 | uint32 | −1（选中哨兵） |
| +88 | CButtonWrapper (1368) | 子件 "background_button" |
| +1456 | CButtonWrapper (1368) | 子件 "portrait_btn" |
| +2824 | CButtonWrapper (1368) | 子件 "portrait_btn_empty" |
| +4192 | CGuiObject* | 子件 "leader_skill" |
| +4200 | CGuiObject* | 子件 "flag"（0x1422BC0B0 系） |
| +4208 | CGuiObject* | 子件 "supreme_leader_name" |
| +4216 | CGuiObject* | 子件 "leader_enroute" |
| +4224 | CGuiObject* | 子件 "theater_name" |
| +4232 | CGuiObject* | 子件 "show_pin"（0x1422BA060 系；+128 派发器订阅 +4272 胶水；facet+552 注册 tooltip） |
| +4240 | CGuiObject* | 子件 "assigned_countries" |
| +4248 | CGuiObject* | 子件 "assigned_regions" |
| +4256 | CGuiObject* | 子件 "assigned_countries_icon" |
| +4264 | CGuiObject* | 子件 "assigned_regions_icon" |
| +4272 | CCheckBoxObserverGlue (112) | {vtable, self, fn=0x141C163E0, 回调区}；拆 0x1402DE2C0 |

> 宿主 gridbox @面板+1408，数据源 = 名将库 sub_14118D710（count@其+2580）；dtor 0x141C15190；FillTooltip 0x141C15450（FACTION_COMMANDER_DESC/PORTRAIT + 剧场州/国计数 loc）。

**CNewFactionTemplateItem (1472B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +32 | uint64 | 0 |
| +40 | CGuiObject* | 子件 "name" |
| +48 | CGuiObject* | 子件 "manifest_name" |
| +56 | CGuiObject* | 子件 "manifest_desc" |
| +64 | CButtonWrapper (1368) | 绑子件 "select_button"（0x1422DC710 深建）；回调签名 (CGuiObject*, CNewFactionWindow&) RTTI 直证 |
| +1432 | CNewFactionWindow* | 入参 a3 = CNewFactionWindow& |
| +1440 | 匿名结构 (NNB 形状)* | 深查找窗 "rule_window"（0x1422BA420 系） |
| +1448 | 匿名结构 (NNB 形状)* | 深查找窗 "goal_window" |
| +1456 | CGuiObject* | 子件 "rule_text" |
| +1464 | CGuiObject* | 子件 "goal_text" |

> 模板库遍历 qword_14332EF10（gameitemdatabase.h 断言）；+24 tooltip 子基经 facet vtable+552 注册进 select_button；dtor 0x141822D80；FillTooltip 0x141824000（NEW_FACTION_WINDOW_RULES/GOALS_TOOLTIP，NAME/TYPE 列）。

**NFactions 弹窗族自有字段**（基域止于 +4200，定案）：

| 类 | 偏移 | 类型 | 名称/语义 |
|---|---|---|---|
| CKickFromFactionPopup | +4200 | qword | 0（唯一自有字段；dtor 0x14146CE00，与 0x14146CD20 同形未折叠） |
| CInviteToFactionPopup | +4200 | 24B 对象 | sub_14011DF40 构造（语义推定） |
| CInviteToFactionPopup | +4208 | u32 | 0 |
| CInviteToFactionPopup | +4216 | 指针 | 引用计数对象（dtor 经 vtable[2]=+16 Release 释放后置 0） |

**CIncomingLendLeaseDiplomacyPopup (5432B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1488 | 窗件块 (1288) | builder 0x141750F00，回调 0x141525674 |
| +2776 | 窗件块 (1288) | 同 builder，回调 0x141753E00 |
| +4064 | uint64 | = qword_14333D528（与 CFactionPingWindow +11400 同全局） |
| +4072 | 窗件块 (1288) | builder 0x141751320，回调 0x141753B00；首槽覆写 CButtonEventDispatcher vtable |
| +5360 | uint64 | 0 |
| +5368 | uint64 | 0 |
| +5376 | 24B 向量头 | 锚 off_143085170 |
| +5384 | 匿名结构 (24B 形状) | sub_14011DF40（语义推定） |
| +5408 | 匿名结构 (24B 形状) | sub_14011DF40（语义推定） |

> +0..+4063 = CDiplomacyPopupWindowBase 域（基 ctor 0x141751740；+1456 = 16B 入参拷贝 sub_14011E010；CAutomaticPause@1440 四表齐写 +0/+16/+56/+1440）；主表 16 槽 [1]/[11]/[12]/[14]/[15] 语义未决；dtor = 主表 [0] 0x141752920（释 +1392 门、+5384/+5408/+5360 三组、拆 +4080 块），+16 次表 [0] = 调整器 0x141752760；ctor 包装 0x141751E60 由外交行动取国/名（sub_141AA6DB0 → sub_141129630）后调基 ctor；工厂 0x141752E80 按外交行动类型分派 4 弹窗（14027 → 本类 / 19135 → 4216 (CForeignManpowerDiplomacyPopup) / 两谓词分支 → 4272、4104）。

**CFactionPingMapIcon (1536B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +128 | CClass* | CTooltipHandler 次表（5 槽；[0] FillTooltip 0x1418DEA80，[1] 调整器 0x1418DE734） |
| +136 | CButtonWrapper (1368) | glue 槽 +152；回调表 20×64B（0x1402DDEF0 建） |
| +1496 | uint64 | 0 |
| +1504 | uint64 | 0 |
| +1512 | uint64 | 0 |
| +1520 | uint32 | 0 |
| +1528 | uint64 | 0 |

> +0..+127 = CMapIcon 域（COL 链 CTooltipHandler@128 非虚 mdisp=128）；主表 0x142A174C8 21 槽：[1]/[2]/[7]/[9]..[14]/[17] = 0x14163Fxxx 底座共享组，**[3] 0x1418DF2E0 = 按图标类型刷新帧**（先做 mapicon.h:189 `eType < MAP_ICON_TYPES_COUNT` 断言，再 `sub_140FA61D0` 写 `*(DWORD*)(a1+112) = 类型→gfx id`）/ **[4] 0x1418DE7C0 = 地图位置/可见性计算**（读 `*(a1+1512)` 为门）/ **[8] 0x1418DEE60 = 可见性判定**（基可见 `sub_14163F6C0` && 本类 count 件 `sub_1418DEEA0`），[5] xor-eax / [6]/[16] ret0（三址均返 0，[5] 为 ICF 折叠 `UserMathErrorFunction`）；dtor 0x1418DE740（拆 wrapper → 回写 +128 基表 → CMapIcon 基 dtor 0x14163F3A0）。

**CFactionPingView (1416B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1408 | uint8 | 刷新门（主表 [7] 置 1→调→置 0） |

> +0..+1407 = CCountryView 域（+72 窗件块 / +1360 名串副本 / +1392 宿主面板）；主表 17 槽：[4] 0x14179C0D0 = 面板刷新（sub_14179F9C0 刷窗件域 +528 列表）、[7] 0x141798900 = 可见性刷新（门 +1408 + sub_1417A0720），其余 = 0x141237xxx 底座桩；+40 次表 2 槽（[1] 0x140B64330）；+48 次表 [0] = 调整器 0x140B6433C；视图挂国家面板装配器宿主 +376。

**CFactionPingWindow (11432B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1520 | vbtable 指针 | 虚基 CTooltipHandler vbptr（vtord 写 +1516） |
| +1528 | CGuiObject* | 入参 a3 = 宿主 section |
| +1536 | uint64 | 0 |
| +1544 | CCheckBoxObserverGlue (112) | {vtable, self, fn=0x141799700, 回调区} |
| +1656 | CButtonWrapper (1368) | |
| +3024 | CButtonWrapper (1368) | |
| +4392..+4551 | 20×uint64 | 0 |
| +4552 | 3×CButtonWrapper 数组 | 3×1368（eh vector constructor iterator 直证）；对应子件名未决 |
| +8656 | CButtonWrapper (1368) | |
| +10024 | CButtonWrapper (1368) | |
| +11392 | NFactions::NUi::CFactionCommanderWindow* | malloc(4520) 子窗（sub_141BF84C0 建，三处写该类 vftable +0/+40/+48，含唯一串 `factioncommanderwindow`；主表 [5] 释放） |
| +11400 | uint64 | = qword_14333D528 |
| +11408 | uint32 | 1 |
| +11420 | uint32 | vtordisp 槽 (虚基前 4B; ctor 写 0; +1516 = 反编译 disp32 字面量勿混, vboff=9904) |
| +11424 | CTooltipHandler 虚基域 | 2 槽表 0x1429FF0A0 ([0] BuildTooltip thunk 0x141797540 / [1] 调整器 0x141796C74, this − vbdisp − 11424); 紧邻 0x1429FF0B0 = vbtable |

> +104..+1519 = CFactionCountryListWindow 域（+112 CButtonWrapper / +1504 向量锚 / +1512 = −1，基域写至 +1515）；主表 11 槽：[4] populate 0x14179A150（重建国列）、[5] 0x141796F50（释 +11392、+1536=0、尾转基 0x141ADB790）、[6] 0x14179DB20（按钮使能刷新，buttonwrapper.h 断言）、[9] 0x141798DB0（发起 ping：qword_14332F6A0+1720 层 sub_140B65430(x,22,0) + sub_140B674F0(x,20)）、[10] 0x141799AA0（按国列填充：+1528 宿主 + CPdxHybridInlineBufferAllocator\<CCountryTag\> 标签集 → sub_1417A0EC0 → 建 176B 件挂会话 UI）；dtor 0x141796D30 逆序拆 5 组 wrapper + 数组 + 胶水 + 基链 + 虚基回写；工厂 0x1417A2570 同厂兼建 136B 助手（0x141796BA0）与 CFactionTheaterSwitch（2888，"faction_theater_switch"）。

**CFactionProgramList (80B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | uint64 | 0（CProgramListBase 域） |
| +16 | uint64 | 0（基域） |
| +24 | 24B 向量头 | 锚 off_143085170（基域） |
| +32 | uint64 | 0（运行期承载宿主 gridbox，槽 [2] 读其 +428 count） |
| +40 | uint64 | 0（基域） |
| +48 | 匿名结构 (NNB 形状)* | owner（基 ctor a2 = 宿主 ResearchSection 窗体） |
| +56 | 向量头 {data@+56, count@+64, alloc@+72} | 条目指针向量（释放经 alloc vtable[2] Release = 引用计数条目） |

> 无独立工厂——由宿主 CFactionResearchSection ctor 0x14146A6C0 内联 malloc(80) 构造；主表 4 槽：[1] 0x141C19770 = 清空条目向量、[2] 0x141C1A5B0 = 重建行（sub_141C06090 过滤 → 循环 malloc(1400) 建行 sub_141C193C0 入 gridbox，补足至 dword_143333FA8 上限）、[3] 0x141C1A8D0 = 大重建（内含 malloc(11448)，语义未决）；宿主 ResearchSection +112 持本列表指针；子件 "facility_count" 计数喂显。

#### 4.31.68 州/占领/海军/和会填空行件

> 横断事实：NFactions 弹窗工厂 0x141472080（模板 id 3/9，三表 MI 形）；mapicon 总工厂 0x140B71B50；occupation 选择视图族宿主 = CCountryOccupationView Setup 0x14156A6F0（建成后存 +11720 Policy / +11728 Garrison / +11752 = 184B 旗件 sub_141C363D0，子件 garrison_template_icon/button、resistance/compliance_tab_button 绑定）；CNavyTheaterRowItem = 书 CNavyTheaterFleetRowItem 基类；20 槽双表史条目族（邻位 6 类同形，CHistoryEntry 效果史基）。sizeof 除标注外全部 malloc 直证（ctor/dtor 90 函数、工厂 caller、malloc↔ctor 配对）。

| 类 | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---:|---|---|
| COccupiedTerritoryStateEntry | occupied_territory_state_entry | 4000 | 占领州行（3 胶水组） | 定案 |
| COccupationPolicySelectLawEntry | select_law_entry_container | 1384 | 占领法选择行 | 定案 |
| COccupationGarrisonTemplateSelectEntry | select_garrison_entry_container | 1408 | 驻军模板选择行（GetTooltip = CTooltipHandler 次基 vtable[0] 三分支: IC 占比 / 人力占比 / 全量模板装备构成+缺陷警告; tpl+296 装备表 {data@+296, count@+308} 步长 16, tpl+400 人力需求; +1304..+1400 十二项布局补全; 选中态 = 按钮 frame a2+1/3 + DEFAULT_LAW_ENTRY 占位名, 紧凑模式字形替代名） | 定案 |
| COccupationSettingSelectionView | select_occupation_setting_container | 2688 | 占领设置视图基（CLegacyButtonObserverGlue 块 ×2 @+48/+1336 开关两态；+2624 宿主窗/+2632 选项子窗/**+2664 修正 id 向量 {data@+2664, cap@+2672, count@+2676}** 40B 元 {std::string, u32} — Populate 收割 `modifier_` 9 字节前缀子件名 → FNV token → 节点+20 修正 id 入向量; 槽 [3] 0x14155D9C0 = Clear、[4] 0x141567E20 = Populate 三视图共用 (绑定 7 命名子件; 经 \*(宿主+1272) 查子件并 facet+552 注册 tooltip)） | 定案 |
| COccupationPolicySelectionView | —（: Setting） | 2720 | 法选择视图（+2688 {data, cap@+2696, count@+2700} 法条目向量 + +2712 byte 旗；首条 a3=0 占位; vtable[2] 0x14156D6B0 法列表重建 = tag/州/无上下文三路定现行法与默认法, lawdb+72 兜底, 过滤+配置法条目 :2675） | 定案 |
| COccupationGarrisonTemplateSelectionView | —（: Setting） | 2688 | 驻军模板视图（ctor 内联于宿主 Setup；槽 [2] 0x14156C940 = Refresh，malloc 1408 建条目，"OCCUPATION_PRIMARY_GARRISON_TITLE" 断言点; **rec+200 = 记录级当前驻军模板**, 回退链 rec+200 → occ+120 → occ+128) | 定案 |
| CStateBuildingItem | state_building_entry | 1344 | 州建筑行（CBuildingItemBase 挂接） | 定案 |
| CStateSharedSlotBuildingItem | state_shared_slot_building_entry | 2816 | 州共享槽建筑行（2×CButtonWrapper） | 定案 |
| CStateDynamicModifierItem | state_view_dynamic_modifier_entry | 136 | 州动态修正行（双构造路径） | 定案 |
| CStateEntry | nudge_window_state_entry | 1384 | 省归并 nudge 州行（CStandardlistboxItem 24 槽直系） | 定案 |
| CStateHistoryEntry | —（非视觉，双表 20 槽） | 72 | 州史条目（CPersistent+CHistoryEntry 次基，嵌入 CStateTemplate+176；reader token 10238/块键 10304） | 推定 |
| CBuildingStatEntry | — | 104 | 建筑统计行 | 定案 |
| CNavalCombatView | navalcombatview | 3888 | 海战视图窗（主 vtable 0x142A04868 + @40 0x142A04890；ctor 0x1417E1FD0；刷新链/胶水全表见 §4.30.17） | 定案 |
| CIntelLedgerMapIcon::CNavalMissionEntry | intel_ledger_naval_mission_entry | 64 | 账本海任务行 | 定案 |
| CNavalMissionMapIcon | naval_mission_mapicon | 5656 | 海任务地图图标（CMissionMapIcon 基+双内嵌列表件 CSimpleEmptyEntryList\<CTinyUnitCounter\>/CEmptyEntryListBase\<CNavalMissionUnitItem\>；+1424..+1600 主数据区；**+1616/+2936/+4256/+5576 四图标列表件槽（步距 1320，四槽同形）**；自有槽 [21..25] 语义未决；布局函数 0x1419027F0 读侧布局见下表） | 定案 |
| CNavyTheaterRowItem | — | 2696 | 剧场行基类（FleetRowItem 之父）; 基类 ctor sub_141E15550 尾部清零至 +2688 → sizeof = 2696; 派生工厂 sub_141E151C0 ("fleet_row_item_box") / sub_141E152F0 ("reserve_fleet_row_item_box"); 调用方 malloc 0xFA0 / 0xA98 互证 | 定案 |
| CNavyTheaterReserveFleetRowItem | reserve_fleet_row_item_box | 4000 | 预备舰队行（: RowItem） | 定案 |
| CPeaceConferenceWindow | peaceconference_full_window | 21008 | 和会窗（主 vtable 0x142A0DB20 四槽 + @40 tooltip 子表；16 胶水块 @+48+k×1288，16 次 sub_14185A680 分区构建；+20656..+21000 尾部数据区全表见 §4.30.10，含三行池/根窗槽 +20768/双竞标弹窗 +20776+20784/byte 旗 +20756+20757+20758） | 定案 |
| CPeaceAvailableActionItem | available_action_item | 1408 | 和会可行动行 | 定案 |
| CPeaceClickAllEntry | peace_click_all | 1368 | 和会全选行 | 定案 |
| CPeaceExpandableSeparatorEntry | peace_expandable_separator | 1424 | 和会展开分隔行 | 定案 |
| CAssignTheaterLeaderPopup | （NFactions 弹窗，模板 id 9） | 4216 | 剧场指挥官指派弹窗（三表 MI：+0 主/+16 次表/+56 CTooltipHandler） | 定案 |
| CBecomeLeaderConfirmationWindow | （同构，模板 id 3） | 4200 | 升任确认弹窗 | 定案 |
| CCommandStructureLeaderView | country_view_advisor_entry 域 | 1592 | 指挥结构将领槽（21 槽，SetTarget+1400 idpair，内嵌 CCommandViewButton；顾问/军官/MIO 三域复用） | 定案 |
| COperativeLeaderForOperationWindow | — | 3320 | 行动领队特工选择窗（10 槽@+48 子对象；+3184/+3192 + +3296..+3312 字段；宿主 = 行动总览窗域，OPERATION_VIEW_PROGRESS 挂点 +5816；ctor 0x141ABDE70 带 CCheckBoxObserverGlue 胶水） | 定案 |
| CUnitLeaderTraitTree | unitleadertraitwindow 域 | 192 | 将领特质树（CSkillTreeBase\<CUnitLeaderTraitTreeItem\> 特化；宿主 = CUnitLeaderTraitWindow vtable 0x1429edb28，**+288 = regular 树 / +304 = terrain 树**；树 ctor sub_1416C6140 (malloc 0xC0)，建树点 sub_1416D0330，源槽 +152 regular_traits / +184 terrain_traits 经 sub_1416D45B0 绑定；条目 CUnitLeaderTraitTreeItem 双 vptr + 三内嵌 1368B 子对象） | 定案 |
| CDiplomacyActionStateItem | stage_coup_state_entry | 1344 | 外交行动目标州行 | 定案 |
| CDiplomacyWarGoalStateItem | diplomacy_wargoal_state_entry | 1344 | 战争目标州行 | 定案 |
| CLogisticsEntryResourceItem | logistics_entry_resource_item | 64 | 后勤资源子行（双构造路径） | 定案 |
| CLogisticsInfoFuelLineItem | logistics_info_fuel_line_entry | 1344 | 燃油线行（胶水@+24） | 定案 |
| CLogisticsOverviewOtherItem | logistics_overview_land/naval/air_other_entry | 1384 | 后勤总览其他行（三实例） | 定案 |

**占领域字段全表**（重锚复核双版本一致，无漂移）：

| 类 | 布局 |
|---|---|
| CCountryOccupationView (11976B) | 8 glue 块 stride 1288 @+1416..+10432；+1408 a3；**选择持有点 +11720/+11728（Policy/Garrison）与各 {vtable, cur+8, ctx+16}**；+11736 格/+11744 列表；**+11752 = 184B 弹窗管理器 sub_141C363D0**；行池 {data@+11768, cap@+11776, count@+11780, glue@+11784, 可见@+11792}（⚠ 旧原稿 cap/count 互换误记，1.19.3 扩容代码同形证 cap@11776/count@11780）；+11800/+11812 钉选数组；+11824 garrison_template_icon（默认法旗标）；+11832/+11888/+11896 按钮；**5 页签元素 +11840..+11872（id 0..4 存元素+8）+ 激活索引 +11880**；+11904 checkbox/+11912 标签/+11920 空态/+11928 select_law_icon/+11936 钮/+11944 文本/+11952 头计数（foreign_support_amount）；**+11960 = Σ行+48 / +11968 = 均行+56** |
| COccupiedTerritoryCountryEntry (8072B) | +32 view / +40 工厂；6 glue @+72..+6512（+6512 = top_bg 粘地图定位钮）；**+7800 tag**；+7808/+7816 双 StatusView；+7824 州行格 {data@+7920, cap@+7928, count@+7932, glue@+7936, used@+7944}；+7840 旗/+7848 名/+7856..+7880 文本列/+7888 强度文本/+7896 expand；+7952 无抵抗行池 {data@+7960, cap@+7968, count@+7972, used@+7984}；+7992..+8096 元素列（法帧+8016/条+8040/法图标+8048/法名+8056/驻军钮+8064/争议双钮+8088/+8096）；+48=occdata+72 / +56=occdata+80 / +64 bool；目标加载 = occupier cc+4048 occmgr+96 向量按 dip tag 搜 +48 |
| COccupiedTerritoryStateEntry (4000B) | 3 glue @+40/+1328/+2616；**+3904 state**；+3912/+3920 StatusView；+3928 名/+3936 数值/+3944 法图标/**+3952 驻军模板旗标**/+3960 进度条/+3984 表2记录+248/+3992 进度（1e5） |
| COccupiedTerritoryStateEntryWithoutResistance (1344B) | glue @+32；**+1320 state / +1328 state_name / +1336 state_info** |
| COccupationStatusView | +8 obj/+16/+24/+32/+40 元素列/+48 进度条/+56 覆盖源/+64 size 枚举 0..3/+68 a6/+72 修正行列表/+96 glue/+104 count/+112 state target/+120 dword |
| COccupiedTerritoryModifierEntry | +104 view/+112 法 id/+124 mod id/+144 显示状态（vtable[4]）；装配器 0x1413EB130（vtable 0x142A5DC98；第二 vtable 写者 0x140F959F0 = 占领州抵抗修正明细 tooltip 发射/装配器, resistance.cpp 串集 RESISTANCE_TARGET_* 全证） |

**选择弹窗基域**（共用基 2688B，Populate = sub_141567E20 三视图共享）：+8 tag 过滤/+16 state 过滤/+24 标题/+32 list_container/+40 setting_list/+48 glue×20/+1336 glue2/+2624 父/+2632 容器/+2640 clear_override/+2648 size_when_clear_button_visible/+2656 limit；基槽 [2]/[3]/[4]/[5] 语义随派生（参见 §4.31.68 上方三行件表）；PolicyView ctor 0x14155A6E0（+2688 法行池 {data, cap@+2696, count@+2700, glue@+2704} + +2712 byte 旗）；GarrisonTemplateView ctor 0x14155A080（0x580 行 ct 内联）；Policy refresh 0x14156D6B0（三分支：tag≠0 → occdata+160 法 id；state≠0 → st+616 CResistance；双空 → occmgr+280 回退 ∧ 全局默认 = sub_14039E040()+72 (1.19.3 默认法)）；Garrison refresh 0x14156C940（cc+440 模板容器 {data@+440, count@+452}，谓词 sub_140BA1BA0/sub_140B9DD90；occdata+200→occmgr+120/+128 默认；标题 OCCUPATION_PRIMARY_GARRISON_TITLE）；装配器 ModifierEntry = sub_14155CF20。

**结构级变化两则（引擎层，非仅址移）**：① **占领法 DB 全局 qword_143316BC8 在 1.19.3 消失 → getter sub_14039E040**（双证：Policy refresh 直调该企业函数取 +72 默认法）；② 建筑 DB qword_143316A58 → **qword_14332EE28 + sub_140683700 组合**。

**SetTarget 尾链第二帧（草稿漏记）**：0x14156B3E0。

**populate [14] 注记**（双版本证据）：close_button→+1416 / garrison_log_open→+2704 / equipment_open→+3992（书 §4.30.14 [11]=0x141566650 与 Setup=0x14156A6F0 双体复核一致）；**§4.30.30 占领视图 @48 槽号**：0x141566AF0 驻 @48[7]（占领刷新），[9] = 0x14156F5A0（Repopulate）——§4.30.30 行已修；occdata 法 id 槽位 = **+160**（静态双直读: Policy refresh 0x14156D6B0 分支 `tag≠0 → occdata+160 法 id` + 窗体刷新 0x14156FE90；+168 无静态支持 — 定案）；`sub_1406F2F20` = `occupied_country_tag` 取址器（函数体 `return cr+80`），非取法 id。

**CNavalMissionMapIcon 图标布局（0x1419027F0，naval_mission_map_icon.cpp）** — 定位四任务图标列表件与两标签窗；读侧布局：

| 偏移 | 类型 | 语义 |
|---|---|---|
| +1440 | 指针 | 父窗口 (vt+48 = SetPosition, 收 packed {x@LO, y@HI}) |
| +1448 | 指针 | 缩放/比例对象 (vt+680 → int 比例; vt+760 = SetPosition) |
| +1456 | int32 | 锚点 x |
| +1460 | int32 | 锚点 y |
| +1464 | 指针 | 任务数组数据 |
| +1476 | int32 | 任务计数 (容器 count@+12); 为 0 → 断言 "_Missions should be initialized by this point" |
| +1568 | 内嵌 | 位置/变换子件 (sub_1418ED940 取访 / sub_141E8C510 判有效 / sub_141E8C520 写位 / sub_141E8C280 取比例) |
| +1584 | 指针 | 标签窗 A (int@+428) |
| +1600 | 指针 | 标签窗 B (int@+428) |
| +1608 | qword | 基点 packed {x@LO, y@HI} |
| +1616 | 指针 | 图标列表件槽 #1 (此前被归入主数据区) |
| +2936 | 指针 | 图标列表件槽 #2 |
| +4256 | 指针 | 图标列表件槽 #3 |
| +5576 | 指针 | 图标列表件槽 #4 (四槽步距 1320, 同形处理) |

> 四槽同形处理: 每件 vt+232 = 度量 (返 packed qword: LODWORD = 宽, HIDWORD = 高) / 字节 +165 bit3 = 有效旗 / vt+48 = SetPosition; 布局 = 有效件纵向堆叠 + 整体水平居中 (x = 基点 x − Σ宽/2), 父窗 +1440 随之上移 总高/−2; 两标签窗按 +1584/+1600 的 +428 与度量值定尺寸; 旗 a2 = false 时跳过四件定位仅结算标签。

#### 4.31.69 前端/多人/成就/杂项 GUI 名录（189 类）

> 名录口径（轻登记非深读）：证据等级 = ctor 工厂名直证 152 / 高置信 17 / 推定 20。主/次vtable PE 直读全量判定：134 主 / 55 次（次表 = 多继承第二基）。大簇共性：前端族（工厂串=类名小写样板）、关系条幅族、设计弹窗族（合并 ctor 混叠，整组推定）、部署页条目族、nudge 调试族（Continent/Terrain/Instance/Stack Entry = 地图 nudge 工具库条目）、AI 数据库 Null 哨兵簇。值得深读跟进：CMTTHDatabaseEntry（前端背景轮换 MTTH 库条目）、CAIControllerPopUpWindow（AI 托管 UI，与 human_ai 路线相关）。

#### 4.31.70 前端系（29 类）
| CBookmarkEntry | 0x142a981d0（主） | 开局书签条目（ctor 串 "bookmark_entry"） | 定案 |
| CDifficultySettingGroupView | 0x142a99618（主） | 难度/游戏玩法设置组视图（ctor 串 "gamesetup_custom_gameplay_settings_window"+"settings_groups_grid"） | 定案 |
| CDifficultySettingItemView | 0x142a99560（主） | 难度设置项视图（ctor 串 "difficulty_setting_item"） | 定案 |
| CFrontEndBackgroundDatabaseItem | 0x14271a210（主） | 前端背景数据库条目（ctor 串 "GFX_frontend_bg_basic"） | 定案 |
| CFrontEndCreditsView | 0x142a640e8（主）+ 0x142a64080（CLegacyButtonObserverGlue 次基@+40） | 制作人员名单视图（ctor 串 "frontendcreditsview"; **本体定案**: 装载 = 读 `interface/credits.txt` (**UTF-8-BOM 强制**, 缺则仅告警 :127; '#' 行 = 标题) → 行表 40B 条目 {串, is_header} → 建最多 **35 个** "CreditsText/CreditsTextBold" 文本元件 (X = 宽/2−250; Y 首行 +2740+40 起逐行 + dword_1430B5E80 行距) + back_button 接线观察器 +1400; **滚动 = 35 槽循环复用** (Update sub_141CD1CF0: 可视带 = +2736 高/2−266 .. +2740 高/2+180, 槽滚出顶且行游标未耗尽 → Y += 35×行距 回底部重取模板, 行耗尽且滚完 → sub_14163EC30 关窗); 行高自适应 (+2688 提供者, 变化时全 Y 按 Δ×20.0f 平移); **布局增量** = +1368 app 根 (+1264 分辨率 {+384 宽, +388 高}; +1272 文本元件工厂) / +1376 关闭目标 / +1384 父容器 / +1400 观察器 / +2688/+2696/+2700(=20.0f) 行高族 / +2736/+2740 可视带 / +2744..+2764 行表 / +2768 游标 / +2776..+3055 35 元件槽 / +3056..+3335 35×{X,Y} | 定案 |
| CFrontEndFriendsFriendEntry | 0x142a63b90（主） | 好友列表好友条目（ctor 串 "frontend_friends_friend_entry"） | 定案 |
| CFrontEndGameSetupView | 0x142a643f0（主） | 前端游戏设置视图（ctor 串 "frontendgamesetupview"） | 定案 |
| CFrontEndMainView | 0x142a65190（主） | 主菜单视图（前端样板推定: 同族 Credits/GameSetup/MultiplayerView/FriendsView 工厂串=类名小写; 本类 ctor 与巨型合并函数混叠） | 高置信 |
| CFrontEndSingleplayerView | 0x142a65e50（主） | 单人游戏前端视图（前端样板推定（同族 4+ 类工厂串=类名小写; 本类 ctor 合并）） | 高置信 |
| CFrontEndView | 0x142a630b0（主） | 前端视图基类（前端样板推定; 含 profile_picture_changed/new_pic 等头像切换串） | 高置信 |
| CFrontendCareerProfileView | 0x142a63270（主） | 前端生涯档案视图（前端样板推定（ctor 合并; 同族样板）） | 高置信 |
| CFrontendFriendsView | 0x142a63a88（主） | 前端好友视图（ctor 串 "frontend_friends_view"） | 定案 |
| CFrontendMultiplayerView | 0x142a65a48（主） | 前端多人游戏视图（ctor 串 "frontendmultiplayerview"） | 定案 |
| CFrontendSettingsView | 0x142a25a88（主） | 前端设置视图（ctor 串 "menu_settings"） | 定案 |
| CGameSetupCustomSettingsWindow | 0x142a99a70（主） | 游戏设置自定义玩法规则窗口（ctor 串 "gamesetup_custom_gameplay_settings_window"） | 定案 |
| CInGameMenuLoadWindow | 0x142a7a980（主） | 游戏内菜单读档窗口（ctor 串 "savegame_item"） | 定案 |
| CInGameMenuSaveWindow | 0x142a7a8d0（主） | 游戏内菜单存档窗口（ctor 串 "savegame_item"） | 定案 |
| CLoadingFriendProfileView | 0x142a91830（主） | 好友档案加载视图（串 "loading_friend_profile_view"（同族合并构造内, 类名精确对应 + FRIENDS_LOAD_FRIEND_PROFILE 串）） | 定案 |
| CMusicPlayerView | 0x142a03db0（次(96)） | 音乐播放器视图（ctor 串 "musicplayer_window"; 次基 = 音乐管理器客户端, 首填充与布局见 §4.31.112） | 定案 |
| CPlaythroughOverviewWindow | 0x142a7b4e0（主） | 本局进程概览窗口（ctor 串 "playthrough_overview_window"） | 定案 |
| CPotentialDLCItem | 0x142a65070（主） | 潜在 DLC 列表项（游戏设置）（ctor 合并无串; 类名 + 游戏设置邻域） | 高置信 |
| CSettingsGroupView | 0x142a99450（主） | 设置组视图（ctor 合并无串; 同窗 settings_groups_grid + 类名） | 高置信 |
| CStandardMusicStationItem | 0x142a7d1f0（主） | 音乐电台/频道选择条目（ctor 串 "select_station_button"） | 定案 |
| CStandardMusicTrackItem | 0x142a9fca0（主） | 音乐曲目条目（ctor 串 "play_track_button"/"disable_track_button"） | 定案 |
| CSteamStoreItem | 0x142b6f228（主） | Steam 商店物品项（ctor 合并无串; 0x142b6f Steam 族聚集 + 类名） | 推定 |
| CSteamUGCContentItem | 0x142b6f578（主） | Steam UGC 内容项（错误串实名直证 CSteamUGCContentItem::OnQueryCompleted; 运行期布局与工坊提交状态机见 §4.00.23） | 高置信 |
| CStoreItem | 0x142b6f108（主） | 商店物品项（族基类推定）（ctor 合并无串; Steam/UGC 族聚集 + 类名） | 推定 |
| CTheaterGroupSettingsView | 0x142aa0e80（主） | 战区组设置视图（ctor 串 "theater_group_settings_view"） | 定案 |
| CUGCContentItem | 0x142b6f3a0（主） | UGC 内容项（族基类推定）（ctor 合并无串; Steam/UGC 族聚集 + 类名） | 推定 |
#### 4.31.71 多人系（7 类）
| CChatItem | 0x142a0eae0（主） | 多人聊天列表条目（ctor 合并无串; 同合并构造含 chat_window/chat_inbox_window/chat_item 串族 + 类名） | 高置信 |
| CHotJoinRequestItem | 0x142a00fd8（主） | 热加入请求条目（ctor 串 "hotjoin_request_entry"） | 定案 |
| CHotJoinWindow | 0x142a01148（次(96)） | 热加入窗口（ctor 串 "hotjoin_window"; 同函数 airwing_icon/custom_icons 子元素） | 定案 |
| CJoinConfigurationPopup | 0x142a9b6e0（主） | 加入游戏/连接配置弹窗（ctor 串 "multiplayer_connect_window"） | 定案 |
| CMatchmakingGuiFriendItem | 0x142b4e568（次(56)） | 匹配大厅好友条目（ctor 串 "matchmaking_friend_item"） | 定案 |
| CMatchmakingGuiServerItem | 0x142b4e220（次(56)） | 匹配大厅服务器条目（ctor 串 "matchmaking_server_item"） | 定案 |
| COOSPopUpWindow | 0x142a037d8（次(16)） | 脱步（OOS）警告弹窗（ctor 串 "oos_popup_window"） | 定案 |
#### 4.31.72 成就系（4 类）
| CAchievementListItem | 0x1429e8ce0（主） | 成就列表条目（ctor 串 "achievement_entry"） | 定案 |
| CAchievementsView | 0x1429e8e28（次(40)） | 成就浏览视图（ctor 串 "achievements_window"） | 定案 |
| CModAchievementItem | 0x142aa9610（主） | mod 成就列表条目（ctor 串 "mod_achievement_item"） | 定案 |
| CModAchievementPopupWindow | 0x142a27010（次(96)） | mod/自定义成就解锁弹窗（ctor 串 "medal_popup_window"/"ribbon_popup_window"/"custom_achievement_popup_window"） | 定案 |
#### 4.31.73 杂项散件（123 类）
| CAIControllerPopUpWindow | 0x14294ce98（次(16)） | AI 控制器弹窗（ctor 串 "aicontroller_popup_window"）= **MP 大厅踢人确认窗**: CRemovePlayerCommand::Execute 移真人玩家且大厅支持 AI 接管时弹出; 按钮 1/2 回调 0x140B7CD20/0x140B7CF70 各发 CSetCountryControllerTypeCommand (type=2/0, 载荷 +40 玩家 id/+44 控制器类型) 后置 +1400 关闭旗 | 定案 (布局 4056B: 主 vtable 0x14294CE20 / 次@+16 0x14294CE98 / glue vtable@+56 / 按钮 glue@+1440,+2728 / 玩家名串@+4016 / 玩家 id@+4048) |
| CAIStrategyDatabaseEntry | 0x1427e2128（次(16)） | AI 战略数据库条目（数据件）（ctor 无工厂串; 0x1427e AI 数据库簇 + 类名） | 定案 (reader 0x140660850: tok 12263 allowed→+2976 / 10376 enable→+3064 / 10828 abort→+3152 / 12544 ai_strategy 栈造 CAIStrategyReader 读值) |
| CAIStrategyPlanDatabaseEntry | 0x1427e1990（主） | AI 战略计划数据库条目（数据件）（ctor 无工厂串; 0x1427e AI 数据库簇 + 类名） | 定案 (reader 0x140660B80; 内嵌 CAIStrategyReader) |
| CAITemplateEntry | 0x1429c79e0（主） | AI 模板数据库条目（数据件）（ctor 无工厂串; 0x1427e AI 数据库簇 + 类名） | 定案 (ctor 0x141493A10: 名 sso@16 / FNV@48 / CAICompactDivisionTemplate@64..143 / CAndTrigger@192,280 / CAIMTTHChance@368) |
| CAbilityListWindow | 0x142a69a20（主） | 指挥官能力列表窗口（ctor 串 "abilitylist_window"） | 定案 |
| CAdjusterEntry | 0x142aa3138（主） | 科技子单位调整器条目（nudge/调试）（ctor 串 "technology_subunit_adjuster_entry"+"GFX_adjuster_"） | 定案 |
| CAggressivenessItem | 0x142a06bd0（主） | 舰队交战侵略性选择条目（ctor 串 "aggressiveness_item"+"SHIP_ENGAGEMENT_BUTTON_AGGRESSIVENESS_"） | 定案 |
| CAiBonusWeightList | 0x1427df758（主） | AI 加成权重列表（数据件; 获取通道 = sub_140628A20 经 CAiBonusWeightDatabase def+16 std::map 值@节点+40; 库 qword_14332EDD0 / +96 / +108 / tok8 + token 11405 "default" 回退三重互证） | 高置信 |
| CAllCountriesItem | 0x142ab07d8（主） | "所有国家"列表/筛选项（ctor 串 "all_countries_item"） | 定案 |
| CArmyMilitaryOverviewItem | 0x142a6b9c0（主） | 军事概览页陆军条目（ctor 串 "armyview_army_entry"） | 定案 |
| CAttachmentItem | 0x142a7bc88（主） | 消息/聊天附件条目（ctor 合并无串; 同合并构造含 MESSAGE/CHAT_CVAA_MESSAGE 串 + 类名） | 推定 |
| CBackgroundItem | 0x142a62d30（主） | 前端（生涯）背景选择条目（ctor 串 "available_background"+"change_background_button"） | 定案 |
| CBreakthroughCostItem | 0x142a8f450（主） | 突破（特殊项目）成本条目（ctor 串 "breakthrough_cost_item"+"breakthrough_tab_icon"） | 定案 |
| CCareerProfileSimpleDropdownItem | 0x142ab0da0（主） | 生涯档案简单下拉项（ctor 串 "career_profile_simple_dropdown_item"） | 定案 |
| CChangeDesignFolderPopUp | 0x142a55598（次(16)） | 设计更改文件夹弹窗（ctor 串 "change_design_folder_popup"） | 定案 |
| CChannelItem | 0x1429adb58（次(56)） | 聊天频道选择条目（ctor 串 "channel_window"; 邻 CUserItem(0x1429adcf8) 同簇） | 定案 |
| CConfirmGoalWindow | 0x1429c41a0（次(16)） | 确认目标弹窗（学说/设计器族）（ctor 与 CConfirmRuleWindow/CDoctrineSharingPopup 共享同一合并函数（内含 open_scientist_roster/command_character_view_window 串）） | 推定 |
| CConfirmRuleWindow | 0x1429c4280（次(16)） | 确认规则弹窗（学说/设计器族）（同 CConfirmGoalWindow 共享合并 ctor） | 推定 |
| CConfirmSaveGameRulesWindow | 0x142aa6850（主） | 存档游戏规则确认弹窗（ctor 合并无串; savedgamerules 窗族（CSetupLoad/SaveGameRulesWindow 同族）+ 类名） | 高置信 |
| CConnectionInfoPopup | 0x142a9b530（主） | 多人连接信息弹窗（ctor 串 "multiplayer_info_window"+"mapicons_container"） | 定案 |
| CContinentEntry | 0x142a44598（次(56)） | nudge 数据库窗口大陆条目（ctor 串 "nudge_window_database_terrain_entry"（与 CTerrainEntry 共用工厂模板串）） | 定案 |
| CCreateFolderPopUp | 0x142a55130（次(16)） | 新建文件夹弹窗（ctor 串 "create_folder_popup"） | 定案 |
| CCustomIcon | 0x1427eb290（主） | 自定义图标控件（联队/模板自定义标记）（ctor 合并无串; 同族 div_templ_custom_icon_view/custom_icons 串 + 类名） | 推定 |
| CDefensiveStanceItem | 0x142a06a90（主） | 舰队防御姿态选择条目（ctor 串 "defensive_stand_item"+"CARRIER_DEFENSIVE_STANCE_SELECTION_"） | 定案 |
| CDeleteDesignPopUp | 0x142a55208（次(16)） | 删除设计弹窗（ctor 串 "delete_design_popup"+"DELETE_DESIGN_POPUP_TITLE"） | 定案 |
| CDeleteOrRenameFolderPopUp | 0x142a55338（次(16)） | 删除/重命名文件夹弹窗（ctor 串 "delete_or_rename_folder_popup"） | 定案 |
| CDeleteQueuePopUp | 0x142ab1030（次(16)） | MIO 队列删除弹窗（ctor = 0x142020420, 4208B, RTTI vftable 三重直证, 基 NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow>; 布局与双模式见 §4.31.109） | 定案 |
| CDeleteSaveGamePopUpWindow | 0x14273ade0（次(16)） | 删除存档确认弹窗（ctor 串 "CONFIRMDELETETITLE"） | 定案 |
| CDeleteSavedGameRulesPopUpWindow | 0x142aa6428（次(16)） | 删除已存游戏规则确认弹窗（ctor 串 "CONFIRMDELETETITLE"） | 定案 |
| CDesignFolderItem | 0x1429c99b0（主） | 设计文件夹条目（ctor 串 "design_folder"） | 定案 |
| CDesignFolderListItem | 0x1429c9b70（主） | 设计文件夹列表条目（ctor 串 "design_folder_list_item"） | 定案 |
| CDesignerHqModifierItem | 0x1429c9578（主） | 师设计器 HQ（军部）修正条目（ctor 合并无串; 设计器族邻域 + 类名） | 推定 |
| CDoctrineSharingPopup | 0x1429c4650（次(16)） | 学说共享弹窗（与阵营成员共享学说）（ctor 与 CConfirmGoalWindow 共享合并函数; 类名直推） | 推定 |
| CDynamicModifierBigItem | 0x1429d9510（主） | 动态/精神修正大条目（ctor 串 "spirit_modifier_entry"） | 定案 |
| CDynamicModifierSmallItem | 0x1429d9438（主） | 动态/精神修正小条目（ctor 串 "spirit_modifier_entry_small"） | 定案 |
| CEditDesignerNotePopup | 0x142a55468（次(16)） | 编辑设计备注弹窗（ctor 串 "edit_designer_note"） | 定案 |
| CFilterRuleItem | 0x142a93528（主） | 过滤规则类型条目容器（ctor 串 "filter_rule_type_item_container"+"filter_button"） | 定案 |
| CFindView | 0x1429fff38（主） | 查找（Ctrl+F）视图（ctor 合并无串; 仅类名） | 推定 |
| CFlagItem | 0x142a580b8（次(56)） | 占领者国旗条目（ctor 串 "occupier_flag_entry"） | 定案 |
| CFleetViewEntry | 0x142aa0080（主） | 舰队视图条目（ctor 合并无串; 同构造含 assign_leader/ACE_SELECTION_TITLE 串 + 类名） | 高置信 |
| CFolderTabItem | 0x142a620e0（主） | 学说文件夹页签条目（ctor 串 "doctrine_folder_tab"） | 定案 |
| CForeignManpowerRelationStripView | 0x142a5fa50（主） | 外籍人力关系条（关系条幅视图）（ctor 串 "relation_strip_view"） | 定案 |
| CGameRuleGroupView | 0x142a99930（主） | 游戏规则分组窗口（ctor 串 "game_rule_group_window"） | 定案 |
| CGameRuleOptionView | 0x142a99758（主） | 游戏规则选项下拉条目（ctor 串 "game_rule_option_dropdown_entry"） | 定案 |
| CGameRuleView | 0x142a99878（主） | 游戏规则窗口（ctor 串 "game_rule_window"） | 定案 |
| CGameSetupIronmanSaveWindow | 0x142a988e0（主） | 游戏设置 Ironman 存档窗口（ctor 串 "savegame_item"（复用存档列表元素）） | 定案 |
| CGameSetupMenuLoadWindow | 0x142a987d8（主） | 游戏设置菜单读档窗口（ctor 串 "savegame_item"） | 定案 |
| CGlobalAlertIcon | 0x1429468f8（主） | 全局警报图标窗口（ctor 串 "global_alerticon_window"） | 定案 |
| CHistoricalDesignItem | 0x1429c97f0（主） | 历史设计条目（历史装备设计）（ctor 串 "historical_design_entry"） | 定案 |
| CHumanItem | 0x142a0e9c0（主） | 多人大厅人类玩家条目（ctor 串 "MP_lobby"+"player_shield"） | 定案 |
| CImportDesignPopUp | 0x142a55738（次(16)） | 导入设计弹窗（ctor 合并无串; 设计弹窗族（Save/Delete/ChangeDesignPopUp 均有工厂串）+ 类名） | 高置信 |
| CInstanceEntry | 0x142a43a70（次(56)） | nudge 建筑实例条目（ctor 串 "nudge_window_building_entry"） | 定案 |
| CLendLeaseExportItem | 0x142a71d38（主） | 租借出口部署条目（部署页）（ctor 串 "deploy_entry"） | 定案 |
| CLoadQueuePopUp | 0x142ab1208（次(16)） | MIO 队列装载弹窗（ctor 串 "industrial_org_load_queue_popup"） | 定案 |
| CLogoEntry | 0x142a2c738（主） | 国家徽标列表条目（ctor 串 "logo_list_entry"） | 定案 |
| CMTTHDatabaseEntry | 0x14271a658（主） | MTTH 数据库条目（common/mtth 库条目 = `mtth:` 前缀 scoped variable 的目标; 条目名皆为 AI/事件 MTTH 模板; 布局全解码 §4.26.11） | 定案 |
| CMarketAccessRelationsStripView | 0x142a5fb28（主） | 市场准入关系条（关系条幅视图）（ctor 串 "relation_strip_view"） | 定案 |
| CMasterRelationStripView | 0x142a5f978（主） | 宗主国关系条（关系条幅视图）（ctor 串 "relation_strip_view"） | 定案 |
| CMilitaryDeploymentConveyorView | 0x142a72518（主） | 军事部署输送带视图（ctor 串 "military_deployment_conveyor_view"） | 定案 |
| CMilitaryDeploymentLineView | 0x142a723a0（主） | 军事部署线视图（ctor 串 "military_deployment_line_view"） | 定案 |
| CNicheIconListItem | 0x142a9ed38（主） | 装备设计器生态位图标列表条目（ctor 串 "equipment_designer_niche_icon_entry"） | 定案 |
| CNicheSelectionItem | 0x1429fa848（主） | 装备设计器生态位选择条目（ctor 串 "equipment_designer_niche_icon_entry"） | 定案 |
| CNullAIStrategyPlanDatabaseEntry | 0x1427e1a00（主） | AI 战略计划空哨兵条目（Null Object）（ctor 串 "NullAIStrategyPlan"） | 定案 |
| CNullAITemplateEntry | 0x1429c7a38（主） | AI 模板空哨兵条目（Null Object）（ctor 串 "NullAITemplate"） | 定案 |
| CNullIcon | 0x142b56258（次(128)） | 空图标占位控件（Null Object）（ctor 串 "GFX_nullobject"） | 定案 |
| COperationCollectionItem | 0x1429f5f68（主） | 行动部署集合条目（部署页）（ctor 串 "deploy_entry"+"GFX_deploy_operations_entry"） | 定案 |
| COperationMapIconEntry | 0x142a892e0（次(56)） | 行动地图图标条目（ctor 合并无串; 地图图标族 + 类名） | 高置信 |
| COperationOverviewOperativeEntry | 0x142a817e8（主） | 行动概览干员条目（ctor 串 "operation_operative_view_entry"） | 定案 |
| COperationPhaseTitlesViewEntry | 0x142a81aa8（主） | 行动阶段标题视图条目（ctor 串 "operation_phase_titles_view_entry"） | 定案 |
| COperationPhasesViewEntry | 0x142a81918（主） | 行动阶段视图条目（ctor 串 "operation_phases_view_entry"） | 定案 |
| COperationResourcesViewEntry | 0x142a81cc8（主） | 行动资源视图条目（ctor 串 "operation_resources_view_entry"） | 定案 |
| COrganisationTreeWindow | 0x142aa5ba8（主） | MIO（军工组织）组织树窗口（ctor 串 "industrial_organisation_tree_window"） | 定案 |
| CPingMapIcon | 0x142a14ae8（主） | 多人地图 ping 图标（ctor 串 "ping_mapicon"） | 定案 |
| CPoliticalIdeaItem | 0x142a56f30（次(8)） | 政治民族精神条目（ctor 串 "political_idea_entry"+"add_idea_button"） | 定案 |
| CPoliticalPartyInfoItem | 0x142a57088（主） | 政党信息条目（ctor 串 "political_party_info_entry"） | 定案 |
| CPoliticsIdeaCategoryEntry | 0x142a57140（主） | 政治精神分类条目（ctor 串 "country_politics_idea_category_entry"） | 定案 |
| CPopupLendLeaseInfoItem | 0x142a779d0（主） | 租借信息弹窗条目（ctor 串 "popup_lend_lease_info_item"） | 定案 |
| CPopupLendLeaseRequestItem | 0x142a77918（主） | 租借请求弹窗条目（含 +/- 数量按钮）（ctor 串 "popup_lend_lease_request_item"+"VALUE_CLICK_ADD_1"） | 定案 |
| CProfileBackgroundItem | 0x142ab0a98（主） | 生涯档案背景条目（ctor 串 "profile_background_item"） | 定案 |
| CProfilePictureItem | 0x142ab09f8（主） | 生涯档案头像条目（ctor 串 "profile_picture_item"） | 定案 |
| CProjectFilterListItem | 0x142a53360（主） | 特殊项目过滤列表条目（ctor 串 "project_simple_list_item"+"project_name"/"project_icon"） | 定案 |
| CQueueItem | 0x142aa3fa8（主） | MIO 解锁队列条目（ctor 串 "queue_to_unlock_item"+"remove_from_queue_button"） | 定案 |
| CQueueToUnlockWindow | 0x142a93c78（次(48)） | MIO 解锁队列窗口（ctor 串 "industrial_organisation_queue_to_unlock_window"） | 定案 |
| CQuitConfirmationPopUpWindow | 0x142a0f650（次(16)） | 退出游戏确认弹窗（ctor 串 "default_confirmation_popup"） | 定案 |
| CRaidInstanceItem | 0x142a423b8（次(56)） | 突袭实例条目（ctor 串 "raid_instance_entry"） | 定案 |
| CRaidList | 0x142a42d48（主） | 突袭实例列表（ctor 串 "raid_instance_list"） | 定案 |
| CRandomLocList | 0x1429423d0（主） | 随机本地化文本列表辅助件（ctor 含 chat_window/chat_inbox_window/chat_item 串族; 类名直推） | 推定 |
| CRegionAlertEntry | 0x142a86f38（次(56)） | 战略区域警报条目（ctor 串 "strategic_region_alert_entry"） | 定案 |
| CResistanceComplianceMapIconModifierEntry | 0x142a19db0（主） | 抵抗/合规度地图图标修正条目（ctor 串 "resistance_compliance_map_icon_modifier_entry"） | 定案 |
| CResourceStripItem | 0x142a70468（主） | 资源条幅条目（顶部资源栏）（ctor 串 "resource_strip_item"+"energy_ratio_anim"） | 定案 |
| CRewardItem | 0x142aa5f00（主） | 学说轨道精通奖励条目（ctor 串 "reward_container"/"reward_level"/"mastery_text"; **视觉刷新 0x141FC3230, reward_item.cpp:156, 274 行, df303 补全成员表**: 208B; +32 数值文本 / +40 等级文本 / +48 图标/说明 / +56 进度条 (SetInt(roundf((1−+124 f32)×100))) / +64 启停件 (+117 bit 0x10 配对) / +72 徽标 / +80 define 值件 (sub_1402E31F0 "DOCTRINE_MASTERY_LEVEL_COST","VALUE") / +120 视觉状态 (switch 1/2/3 = rewards_grid 三值在行自身再现) / +124 进度源 / +128 旗 / +136 宿主 / +152 双读待裁 (bit0 = 三元组选择 ∧ dword = 等级) / +160..+207 双三元组; **默认名 "incentive"**; 断言 "Invalid reward visual state" 走 **B51 消息形 debug_assert 门** (a4=0, 闩 byte_14338CDA8) — 本域唯一非 B52 站点, 断言双门定案吻合) | 定案 |
| CRightClickCloseItem | 0x1429a9d08（次(64)） | 调试右键菜单"关闭"项（ctor 串 "right_click_entry"） | 定案 |
| CRightClickOpenItem | 0x1429aa088（次(64)） | 调试右键菜单"打开"项（ctor 串 "right_click_entry"+"Open:"） | 定案 |
| CRightClickReloadItem | 0x1429a9ec8（次(64)） | 调试右键菜单"重载"项（ctor 串 "right_click_entry_2"） | 定案 |
| CSaveDesignToFilePopUp | 0x142a55000（次(16)） | 设计保存到文件弹窗（ctor 串 "save_to_file_popup"） | 定案 |
| CSaveGameItem | 0x14273ac20（主） | 存档列表条目（ctor 串 "BackgroundButton"/"delete"/"_extended_desc"） | 定案 |
| CSaveQueuePopUp | 0x142ab0f58（次(16)） | MIO 队列保存弹窗（ctor 串 "industrial_org_save_queue_popup"） | 定案 |
| CSavedGameRulesItem | 0x142aa6268（主） | 已存游戏规则条目（ctor 串 "BackgroundButton"/"delete"（存档规则项按钮组）+ 类名） | 高置信 |
| CSavedQueueItem | 0x142aa4248（主） | 已保存 MIO 队列条目（ctor 串 "different_mio_warning"/"delete_queue"） | 定案 |
| CScriptedDiplomaticActionSendPopup | 0x14294cfb8（次(16)） | 脚本化外交行动发送弹窗（ctor 串 "send_diplomacy_scripted_popup_window"） | 定案 |
| CSetupLoadGameRulesWindow | 0x142aa67a0（主） | 读档游戏规则设置窗口（ctor 串 "savedgamerules_item"） | 定案 |
| CSetupSaveGameRulesWindow | 0x142aa66f0（主） | 存档游戏规则设置窗口（ctor 串 "savedgamerules_item"+"GFX_military_industrial_organization_"） | 定案 |
| CSpecialProjectCapturedPopUpWindow | 0x14294c9d8（次(16)） | 特殊项目设施被占领弹窗（ctor 串 "facility_captured_popup_window"） | 定案 |
| CSpecialProjectFinishedPopUpWindow | 0x14294c910（次(16)） | 特殊项目完成弹窗（ctor 串 "research_finished_popup_window"） | 定案 |
| CStackEntry | 0x142a45b58（次(56)） | nudge 建筑堆栈条目（ctor 串 "nudge_window_building_entry"） | 定案 |
| CStandardRelationStripView | 0x142a5f8a0（主） | 标准关系条（关系条幅视图基件）（ctor 串 "relation_strip_view"） | 定案 |
| CStatRowItem | 0x1429ea1c0（主） | 统计行条目（窗体/元素名 = `stat_entry` — ctor sub_141695BC0 以 SSO 立即数合成 16 字符串；控件 `label`/`value`；`designer_stat_entry` / `equipment_designer_stat_entry` 为设计器侧另件勿混）（含 preferred_tactic 串; vtable邻接 CAchievementsView） | 定案 |
| CStrategicRegionItem | 0x142a867f0（主） | 战略区域条目（列表选择项）（ctor 串 "strategic_region_item"） | 定案 |
| CStripFlagItem | 0x142a5f028（次(56)） | 国旗条幅条目（关系条幅用）（ctor 串 "countryflag_entry"） | 定案 |
| CSubsidyDraftListItemView | 0x142ab8230（次(8)） | 国际市场补贴草案列表条目（ctor 串 "applied_text"/"applied_checkbox"; 同族 subsidy_draft 串 + 类名） | 高置信 |
| CSurrenderedPopupWindow | 0x1429d3e88（次(16)） | 投降国弹窗（ctor 串 "surrendered_country_popup"） | 定案 |
| CTaskForceTemplateEntry | 0x142a7fa58（主） | 特混舰队模板条目（ctor 串 "task_force_template_entry"） | 定案 |
| CTerrainEntry | 0x142a443d0（次(56)） | nudge 数据库地形条目（ctor 串 "nudge_window_database_terrain_entry"） | 定案 |
| CTimedActivityDistributableViewItem | 0x142a71df0（主） | 定时活动分派条目（租借/政变等部署页）（ctor 串 "deploy_entry"+"GFX_deploy_lendlease_entry"/"GFX_stage_coup_icon"） | 定案 |
| CTimedActivityRelationStripView | 0x142a5f618（主） | 定时活动关系条（关系条幅视图）（ctor 串 "relation_strip_view"+"subsidy_draft"） | 定案 |
| CTotalIcon | 0x142ab4480（次(56)） | 装备模块选择合计图标（ctor 串 "total_amount"; equipmentmoduleselectorwindow.cpp 断言） | 定案 |
| CTrackItem | 0x142a97168（主 19 槽零本类覆写）+ 次表 0x142A97208@+24（CTooltipHandler 2 槽） | 学说轨道条目（ctor 0x141F34630, 1568B; ctor 串 "doctrine_track_item"+"sub_doctrine_button"; widget 全图 17 项）; **双 COL 定案**; 方法地图: tooltip 总分派 = 次表[0] 0x141F36330 (五路路由: sub_doctrine_button/milestone_icon/mastery_text→0x141F35370/bonus_text→成本减免/lock_icon); Reload 0x141F37980 (CRewardItem 行 208B, +112=父回指针); Update 0x141F370A0 (rewards_grid 三态: 1 未来/2 当前/3 已得; mastery_text DOCTRINE_MASTERY/_BANKED/_UNKNOWN 三分支); GetTrackTemplate 0x141F36F50 (grand+792 数组按 track_idx; 断言 :614) — **非纯壳**: 经 sub_1413C60B0 学说状态链读 gameplay 真值 | 定案 (升级) |
| CTruceRelationStripView | 0x142a5f6f0（主） | 停战关系条（关系条幅视图）（ctor 串 "relation_strip_view"） | 定案 |
| CTweakerListItem | 0x142af9b80（次(56)） | 调试 tweaker 列表项（ctor 合并无串; 邻 CONFIRMCANCELALLPRODUCTIONLINE 等串; 仅类名） | 推定 |
| CTypeItem | 0x142a4fe18（主） | 阵营最高统帅类型条目（ctor 串 "supreme_commander_type_item"） | 定案 |
| CUnitsStackMapIcon | 0x142a1a6f8（主） | 单位堆叠地图图标（ctor 串 "unit_mapicon"） | 定案 |
| CUpgradeBranchEntry | 0x142a2cf68（主） | 装备升级分支条目（ctor 串 "upgrade_branch_entry"+"upgrades_grid"） | 定案 |
| CUserItem | 0x1429adcf8（次(56)） | 聊天/大厅用户列表条目（ctor 串 "country_icon"/"small_flag_frame_thin"/"viewing_flag"; 邻 CChannelItem 同簇） | 高置信 |
#### 4.31.74 空军域（8 类）
| CAIRoleDatabaseEntry | 0x1427e09e8（主） | AI 空军角色数据库条目（数据件, 非窗口）（ctor 无工厂串; 邻 NullAITemplate/BOP_TOOLTIP 断言串; 0x1427d-f AI 数据库簇） | 推定 |
| CAirMilitaryOverviewItem | 0x142a6bca8（主） | 军事概览页空军条目（ctor 串 "armyview_air_entry"） | 定案 |
| CAirMissionEntry | 0x142a17708（主） | 情报账本空军任务条目（ctor 串 "intel_ledger_air_mission_entry"） | 定案 |
| CAirWingDetailsPopUpWindow | 0x142ab2dc0（次(16)） | 空军联队详情/统计弹窗（ctor 串 "air_wing_stats_window"） | 定案 |
| CAirWingDropdownItem | 0x142aa8ab8（主） | 联队下拉选择条目（ctor 串 "airwing_dropdown_selection_item"） | 定案 |
| CAirWingMapStackItem | 0x142a887f0（主） | 地图联队堆叠计数条目（ctor 串 "air_wing_counter"） | 定案 |
| CAirWingReorganizationWindow | 0x142ab2410（次(16)） | 联队重组窗口（ctor 串 "air_wing_reorganization"） | 定案 |
| CRepairPriorityItem | 0x142a06cd0（主） | 维修优先级选择条目（ctor 串 "repair_priority_item"） | 定案 |
#### 4.31.75 机种域（3 类）
| CPlaneArchetypeHeaderItem | 0x142a6c540（主） | 飞机原型机分组头条目（ctor 串 "plane_archetype_header_entry"） | 定案 |
| CPlaneTypeCountEntryItem | 0x142a8c260（主） | 情报账本机种数量明细条目（ctor 串 "intel_ledger_plane_count_detail"） | 定案 |
| CPlaneTypeSelectionEntry | 0x142aa86e0（次(56)） | 快速联队部署机种选择条目（ctor 串 "quick_wing_deploy_plane_type_entry_item"） | 定案 |
#### 4.31.76 市场域（2 类）
| CPurchaseDraftItem | 0x142ab46f8（主） | 国际市场装备购买草案条目（ctor 串 "market_draft_equipment_entry"） | 定案 |
| CPurchaseDraftWindow | 0x142ab45d8（次(16)） | 国际市场购买草案窗口（ctor 串 "market_purchase_draft_window"） | 定案 |
#### 4.31.77 生产域（2 类）
| CProductionLineItem | 0x142a6ce20（主） | 生产线通用条目（军民共用基础件）（ctor 含 increase_priority/decrease_priority 按钮; 同窗兄弟类 production_military_line_entry） | 高置信 |
| CProductionLineMilitaryItem | 0x142a6d0d0（主） | 军用生产线条目（ctor 串 "production_military_line_entry"(+collapsed 变体)） | 定案 |
#### 4.31.78 贸易域（2 类）
| CTradeResourceFilterItem | 0x142a61458（主） | 贸易资源过滤条目（ctor 串 "resources_filter_entry"） | 定案 |
| CTradeResourceInfoItem | 0x142a61338（主） | 贸易资源信息条目（ctor 串 "resources_info_entry"） | 定案 |
#### 4.31.79 建筑域（2 类）
| CBuildingRosterItem | 0x142a59878（主） | 建筑名册条目（含 building_info/building_picture 子元素）（ctor 串 "building_info"/"building_picture"/"entry_header"） | 定案 |
| CProvinceBuildingCustomIconItem | 0x142a76fd8（主） | 省建筑特殊图标条目（ctor 串 "province_building_special_icon_entry"） | 定案 |
#### 4.31.80 谍报域（2 类）
| CIntelAgencyFinishedPopUpWindow | 0x14294c848（次(16)） | 情报机构建成完成弹窗（ctor 串 "research_finished_popup_window"+"agency_complete"） | 定案 |
| CIntelMapModeMapIcon | 0x142a17c80（主） | 谍报地图模式图标（ctor 合并无串; 地图图标族（ping/unit_mapicon 同族）+ 类名） | 高置信 |
#### 4.31.81 营建域（1 类）
| CConversionConstructionViewItem | 0x1429f49a0（主） | 建造页军工/民工转换条目（ctor 串 "convert_ic_entry"/"convert_ic_button"/"convert_ic_overlay"） | 定案 |
#### 4.31.82 王牌域（1 类）
| CGunEmplacementWingsSelectionItem | 0x142aa7e58（次(56)） | 火炮阵地驻扎空军联队选择条目（ctor 串 "gun_emplacement_selection_item"） | 定案 |
#### 4.31.83 师域（1 类）
| CDesignerDivisionNameGroupItem | 0x1429c92e8（主） | 师设计器师名组条目（ctor 串 "designer_div_name_group_entry"） | 定案 |
#### 4.31.84 科学家域（1 类）
| CRecruitScientistWindow | 0x142a93a78（主） | 招募科学家窗口（ctor 串 "RECRUIT_SCIENTIST_WINDOW_TITLE"/"RECRUIT_SCIENTIST_WINDOW_INSTRUCTIONS"） | 定案 |
#### 4.31.85 舰船域（1 类）
| CFexShipIcon | 0x142a04638（主） | 海战舰船图标条目（含交战/逃脱进度条）（ctor 串 "navalcombat_ship_entry"+"bar_st"/"bar_or"/"escape_progres"） | 定案 |

#### 4.31.86 通用控件底座（窗口/容器/按钮基族）

> 横断事实：窗族 CGuiObject 次表 [0] = sub_1422AE010 **延迟删除标记**（按 +88 id 分派，置 +117 |= 0x20 并把 this 写进父(+104) 的 +320 待删链），非删除序 dtor；三窗类次表 [0] 全同址。TWindow 基 ctor = sub_14237F6A0（写 CObservable\<CWindowObserver,CWindowClassObservable\> 域 → sub_1422ADC00 init → 回写 +0/+48 双 vtable；`++dword_143481134` 实例计数）；窗族公共域 +88 id / +104 父指针 / +117 flags / +165 flags。CObservable 模板布局（+8 表头/+16 尾/+24 计数/+28 延迟删除旗/+40 旗2）三处互证；**Subscribe/Unsubscribe 槽地址逐模板实例而异**（0x142230980 / 0x1422AF460 / 0x14029EDD0 三例），布局才恒定。子件派发器订阅原语 = 遍历容器+4312 数组（计数 +4324），对每子件调 (子件+128)→vtable[1]（观察者）。主/次表判定 5/12 命中次表（@56 TListboxItem 接口 / @48 CGuiObject 接口 79 槽 / @128 observable 4 槽），已按"同 TD 扫 off=0 COL 反查"定位主表。**定案**：0x142A4F008 的 COL 0x142D734C0 → `CNaviesViewSunkShipItem`（mdisp=0，13 槽），即该址是 CNaviesViewSunkShipItem 主表而非 COption；COption 主表 = 0x142B4A5A0（COL 0x142DE1590，9 槽）。CStandardGridBoxItem 唯一基表 = 0x142B45EF0（0x142B440D0 非表首）。外围顺带：CCommandStructureLeaderView 1592B（CCommandViewButton 派生）、CContainerWindowType 1432B、CGameIdler 内嵌 CSelectionList@1336。

**通用 setter 底座契约（全 GUI 受益，定案）**：

| 项 | 定案 |
|---|---|
| 文字 setter sub_1422CA920 | = `SetText(widget, 临时串)`：SSO 拷入元件 **+272**（与 CInstantTextBox 文本域互证）+ sub_1422CB4A0 重排版失效；吞掉调用方临时串。全 exe 1920 调用点 / 915 调用者 / 371 宿主类（Top 宿主 = CCountryMilitaryOverview 44 / CNavalLossesOverview 37 / CArmiesView 33 / CFrontEndGameSetupView 32 / CCountryIntelligenceAgencyView 29 / CTopBar 22） |
| vtable+152 真身 | **C2dVisibleObject 系（精灵族）槽[19] = `SetFrame(int)`**——CSprite 基 0x1422FE900（帧 + 脏旗）、CProgressbarSprite 0x1423604D0（帧数钳制）；**非 CIcon 的槽**：CIcon 写值链 = vtable+752 GetSprite 取精灵后对**精灵**调 vtable+152（全 exe 9259 vtable逐一读槽[19] = 149 去重实现，15 个 GUI 语义实现全反读定案，余 134 非 GUI 族） |
| widget 系 +152（同名撞车） | CGuiObject 系的 +152 = 另一槽 = **拉取器**（基 0x140BEF7D0 `*out=0`；CIcon 覆写 0x1422FB4A0 = 读 +276）；另有 facet 次表（@+48 等）与 CEffect/CCommand 族 +152 各异 |
| 判别口诀 | 先谱系（2d 精灵族 / widget 系 / 非 GUI）、再实参形态（值参 = SetFrame 候选 / `&` 出参 = 拉取器）、最后看 +752 GetSprite 链 |
| 数值规整 | fixed×1e-5 → int 帧值舍入器 = sub_1424ED730（(x+50000)/100000）；规整 sub_1424ED580（Q15→fixed 1e5） |
| 静态不可归因 | 文字 203 点 / vt152 210 行（vtable间接/回调注册）留活体 detour 归因 |

| 类 | 主vtable（槽数） | GUI 名 | sizeof | 用途 | 置信 |
|---|---|---|---:|---|---|
| CAliasButton | 0x142AFAC20（14）+次@56 | tweaker_aliascomponent | 1456 | tweak 控制台别名按钮条目 | 定案 |
| CColorPickerPresetEntry | 0x142A7B870（19） | color_picker_preset_entry | 1360 | 颜色选择器预设色块（点选联动 RGB 三滑条） | 定案 |
| CCommandViewButton | 0x142A6A2F8（19） | （调用方传） | 1400 推定 | 指挥结构视图按钮条目 | 布局定案 |
| CContainerWindow | 0x142B45278（78） | （按 .gui 名查型 containerWindowType） | 5944 | 容器窗运行时实例 | 定案 |
| CFixedWindow | 0x142B4F2B0（82） | 同窗族 | 7928 | 固定布局窗底座（六张 CTernary 类型化子件注册表） | 定案 |
| CMultiSpriteButton | 0x142B59D18（117）+次@128 | — | 552 | 多精灵多态贴图按钮 | 定案 |
| CNullContainerWindow | 0x142B562A0（78） | 无（默认型直造） | 5952 | 无头逻辑容器（+5944 TNullGuiObjectTrait；查型失败兜底窗） | 定案 |
| CPdxWindow | 0x142AFD5C8（6） | — | 8 | PdxEditor 主窗口句柄 monostate 单例（6 槽全操作全局） | 定案 |
| CSearchableGridBoxItem | 0x142A79E10（19） | find_view_item | 1344 | 查找视图搜索结果条目 | 定案 |
| CSelectionList | 0x142736258（4） | —（非视觉） | 88 | 可选中列表观察者主体（observable mixin，内嵌宿主; 无独立 ctor — 宿主内联构造 (CGameIdler ctor sub_14029D800 @+1336 等); +48 第二链表全语料无消费者 = 预留域负定案） | 定案 |
| CSortableGridBoxItem | 0x142A7D690（20） | —（抽象） | — | 可排序网格条目接口基座（[19] 纯虚） | 定案 |
| CWarOverViewWarButton | 0x142A12B18（19） | waroverview_war_button | 1336 | 战争总览战争按钮条目 | 定案 |

**CAliasButton (1456B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +56 | CClass* | TListboxItem 接口次表（24 槽；接口本体 0x142B42AA8 大部纯虚） |
| +66 | uint8 | 旗 =1 |
| +96 | CGuiObject* | 容器子件（基链 vtable[29](+232) CreateChild 产物） |
| +104 | CGuiObject* | 父 gui |
| +112 | MSVC 串 16B | 文本回退串（sub_14011E010 拷建） |
| +144 | CGuiObject* | 第二子件 |
| +152 | CGuiObject* | 子件 "tweaker_button"（FindChild） |
| +160 | 观察者胶水 | builder sub_1420843D0；回调 = OnClick sub_14208A6F0（+168..+1447 拟合 20×64B 回调表） |
| +1448 | 匿名结构 (NNB 形状)* | a3 别名数据（OnClick 消费 → +144 对象按 0x20 长度构串经 qword_1435E1A80 提交 = 激活别名，推定） |

> 基链 CAliasButton → CTweakerListItem → CSmoothListboxItem → COption → CObservable + TListboxItem@56；基 ctor sub_142089360(this, 父gui, 名串, 字符串)；ctor sub_142085C90 回写双表后建 +160 胶水；主表 [1..8] = COption 族共享槽（与 COption 主表 0x142B4A5A0 八槽同址）；tweaker 条目工厂 0x14208A220 / 0x14208A330 按元素类型分派：0 → 1472B（sub_1420868B0）/ 1、2 → 368B（sub_142088B90）/ 3 → 本类 / 4 → 自定义 creator；删除序 dtor 0x142089690（存在性由次表调整器 0x1420895F0 反证）。

**CColorPickerPresetEntry (1360B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | CClass* | CButtonEventDispatcher vtable（dtor 回写） |
| +32 | 观察者胶水 | builder sub_141DEF330；回调 = OnClick sub_141DEFF70（+32..+1311 拟合 20×64B 回调表） |
| +1312 | 内嵌 CColor (24B 投影) | {vtable, 16B RGB 值 ← a3+16}; 尺寸分档见 §4.00.10 |
| +1344 | 借用单指针 | **滑条对象数组基址** (调用方拥有; OnClick sub_141DEFF70 经 sub_1424F01D0 **RGB→HSV** 后对三滑条送定点值 — 滑条实为 HSV) |

> ctor sub_141DEFAD0(this, 父, a3 预设数据, a4 滑条数组)；OnClick = sub_1424F01D0 取预设色 3 float → 对三滑条各调 (滑条+128)→vtable[7](+56) 送 (int)(v×100000+0.5 符号处理) = 点色块联动三滑条（定案）；dtor 0x141DEFE40。

**CContainerWindow (5944B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +88 | uint32 | 窗族 id |
| +104 | CGuiObject* | 父窗 |
| +117 | uint8 | flags（bit 0x20 = 删除标记，bit 0x4 亦被消费） |
| +165 | uint8 | flags（bit2 dtor 侧证） |
| +176 | CScrollbarObserverGlue | 模板特化 \<CContainerWindow\>；回调 sub_1422C2060 |
| +272 | CScrollbarObserverGlue | 同形；回调 sub_1422C23C0 |
| +4232 | CButtonEventDispatcherGlue | 模板特化 \<CContainerWindow\> |
| +4312 | 派发器数组 | 子件派发器订阅源（计数 +4324） |
| +5032..+5152 | 6 组 {ptr, count, vtable} 列表 | dtor 侧证 |
| +5568 | 匿名结构 (368B 形状)* | **精灵宿主 + 本窗图形节点对** |
| +5600 | CExtendedScrollbar* | **真垂直滚动条** (装配器 sub_1422C0710; 取用器 sub_1422B6F70; 错误串 "vertical" 引擎误写) |
| +5608 | CExtendedScrollbar* | **真水平滚动条** (同装配器; 取用器 sub_1422B6E60) |
| +5616 | 匿名结构 (NNB 形状)* | 图形节点对尾 (同 +5568 族) |
| +5624 | 匿名结构 (NNB 形状)* | 图形节点对尾 (同 +5568 族) |
| +5872 | std::function 位 | 拆除序 |
| +5936 | std::function 位 | 拆除序 |

> 巨型 .gui 装载 ctor sub_1422B3F90(this, a2=CContainerWindowType*, …)；teardown 体 0x1422B6390，删除序 dtor 0x1422B6DC0（teardown + j_free）；次表 @+48 = CGuiObject 接口 79 槽（[0] = 延迟删除标记，见横断事实注）；工厂 0x14230F5B0（宿主型：a1[84] 查型委托 → malloc → ctor → a1[170]→vtable[20](+160) 挂接）/ 0x14230FE70（直造型）；按 .gui 定义名运行时查型（containerwindowtype.cpp:597 断言），查型失败回退全局共享空窗 qword_143453278。
getter 家族 17 型 (双轨: 直查 = vtable槽 / 递归 = 辅助函数): GetInstantTextBox[15]/GetEditBox[16]/GetIcon[17]/GetBrowser[18]/GetDropDownBox[20]/GetCheckBox[21]/GetOverlappingElementsBox[23]/GetType[24] (回退 CPositionType)/GetGridbox[54]/GetSubwindow[55]/GetExtendedScrollbar[56]/GetButton[13]/GetStandardListbox[38]/GetSmoothListbox[37]/GetButtonDrag[67]; 滚动条装配几何四参 + 百分比旗 (+5600/5608 写入侧); 子件位置校验 + 滚动条范围记账 sub_1422B7300; 淡入淡出步进器 [76] (模式+5680/时长+5684/缓动+5692/进度+5592); 拖拽滚动事件过滤 sub_1422C1F00 (moveable+5807 / dragscroll+5810 xor 警告); RemoveSubwindow (数组本名 `_ContainerWindows`) / RemoveIcon (`_Icons`)。**`*(this+152)` = CGui 单例** (gui.cpp, qword_143453230, ctor 0x142259B30); 其 +416..+552 = **15 个 CNull\* 类型化空件单例表 + CPositionType** (null 工厂 0x14225B7D0) — 全族 getter 的兜底通道; CNullContainerWindow 九槽全部落定为类型化 getter (原「未逐槽定」收口)。NOT IMPLEMENTED 断言桩 ×11 (主表 [34][35][39]-[45][14]、次表[36])。

**CFixedWindow (7928B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +7264 | CTernary 注册表 (64B) | CTextBox* 型化子件表 |
| +7328 | CTernary 注册表 (64B) | CEditBox* 型化子件表 |
| +7392 | CTernary 注册表 (64B) | CCheckBox* 型化子件表 |
| +7456 | CTernary 注册表 (64B) | CStandardlistbox* 型化子件表 |
| +7520 | CTernary 注册表 (64B) | CSmoothListbox* 型化子件表 |
| +7584 | CTernary 注册表 (64B) | CScrollbar* 型化子件表 |
| +7616 | 空闲链 | {head, +7624, count@+7632} — 归属精化: = CScrollbar CTernary 注册表内部空闲链, 非窗级独立成员 |
| +7648 | 40B 元数组 | **子件名→widget 对象登记表** (元 {SSO 名串 32B, 对象指针@+32}; 销毁器 sub_1401756F0; 消费 sub_142327A30 逐元调 obj vtable[9]; {cap@+7656, count@+7660, alloc@+7664}) |
| +7672..+7816 | 七个 24B 链表头 | **按类型分组的控件名登记链** (+7672/+7696/+7720/+7744/+7768/+7792/+7816 步进 24; 节点 **56B** {SSO 控件名 32B, prev@+32, next@+40, byte@+48} (malloc 0x38 直证); 销毁器 sub_14061C4F0; 遍历按名查 CTernary 表 (+7264 CTextBox/+7392 CCheckBox/+7456 CStandardlistbox) 后调 vtable+464) |
| +7840 | 精灵/纹理引用 | 释放经 sub_142237FA0 |
| +7888 | MSVC 串 | cap@+7912 |

> 六张 CTernary 注册表 = GetChild\<类型\>(名) 型化查找底座（用途推定）；ctor sub_142321570（35 参，.gui 型 + 布局 + 约三十个子件绑定出参展平）；teardown 0x1423248E0，删除序 dtor 0x1423253C0；工厂 0x1422F7210 / 0x1422F81E0（查型委托 a1+68，失败 fallback sub_1422F7DD0 现建型）；主表 82 槽 [1][2][3] 窗族共享、[4][5] = ret1/guard_nop；次表 79 槽与容器窗差异 32 槽（0x14232xxxx 族自有实现），[0] 延迟删除标记同址。
> **ctor 机制增补** (0x142321570, 2694 行; fixedwindow.cpp 6 函闭环): 36 形参含 this; 基 ctor →
> 双 vtable → **5×1288B 绑定组** (12 回调槽, 逐槽语义待裁) → 9×48B 组 (对象向量+名字向量, 内嵌
> 共享分配器单例 off_143085170) → 六张 CTernary → 7 链头 → 逐类型装配环 (14 个 typed 工厂 +
> vtable+232 设位 + 越界校验 main[81]: `x>w || y>h` 仅告警不裁剪) → 锚点枚举定位 (1..6 六档停靠
> 全表) → a27 重定位环 (11 级查找瀑布; +7840 368B 对象兼任子件重定位位置源)。
> **⚠ 次表 this 调整定式** (排雷): 次表基址 0x142B4F548 = B2 子对象@+48, **次表方法 this =
> obj+48** — 反编译偏移需 +48 还原为对象视角, 否则得出「+7216 多态分发 vs 构造清零」假矛盾
> (capstone 字节级定案)。**CTernary<T\*> = 三叉搜索树** (根@+8, 节点 40B, tolower 键;
> Find/Insert/Clear 共享实现 0x14225C4B0/C4F0/A4B0/D9A0) + CScrollbar 表平铺条目双通道;
> sub_142325400 = 查找**或插入** (先 contains 后 get 是必要次序)。子件名查找 resolver =
> 次表 sec[60]: 组2 平行数组 → CTextBox 树 → CEditBox 树 → +7648 登记表 → 断言返 0;
> NOT IMPLEMENTED 桩 main[24] 恒返 CGui+552 兜底空件。

**CMultiSpriteButton (552B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +232 | CGuiObject* | 精灵宿主（析构逐元素 sub_142237FA0(此, 元素, +117&4) 归还） |
| +240 | CGuiObject* | 精灵引用（CButtonStandard 域） |
| +272 | CGuiObject* | 精灵引用（CButtonStandard 域） |
| +392 | MSVC 串 | cap@+416 |
| +521 | uint8 | 延迟删除门旗（主表 [0] 0x1422D17D0 以此为门转发 CGuiObject 延迟删除） |
| +528 | 向量 {data@+528, +536, 计数@+540} | 精灵句柄向量 |
| +544 | 24B 向量头 | 空锚 off_143085170 |

> 基链 CMultiSpriteButton → CButtonStandard → CButton → TButton → CGuiObject + CButtonObservable@128；基 ctor sub_1422CF840（17 参：位置/尺寸 int + 精灵名串族 + 布局参数），teardown sub_1422D0850；ctor sub_142385D80；observable 次表 4 槽：[0] 调整器 this−128 → teardown 0x1423860F0、[1] Subscribe 0x1422AF460、[2] Unsubscribe 0x1422AF9C0、[3] 未名；主表 117 槽语义未逐；精灵名/元素名全由调用方传入（无类字面量）。

**CNullContainerWindow (5952B)**：

| 槽 | CContainerWindow | CNullContainerWindow | 语义 |
|---|---|---|---|
| [0] | 0x1422B6DC0 | 0x142379660 | 删除序 dtor（写 +5944 TNullGuiObjectTrait vtable → 基 teardown 0x1422B6390） |
| [7] | 0x1422C1B60 | 0x142379160 | = 调整器 this−48 → 0x142379660；与姊妹类同槽（位置类方法）语义冲突，推定 ICF 折叠，待裁 |
| [13] | 0x1422B9960 | 0x142379CE0 | null 版 = 转发 *(this+152) 的 +424 getter（定案） |
| [15] | 0x1422BC460 | 0x142379D50 | null 语义覆盖（未逐槽定） |
| [16] | 0x1422BABA0 | 0x142379D20 | 同上 |
| [17] | 0x1422BBF10 | 0x142379D40 | 同上 |
| [20] | 0x1422BA7F0 | 0x142379D10 | 同上 |
| [21] | 0x1422B9EC0 | 0x142379CF0 | 同上 |
| [54] | 0x1422BD8B0 | 0x142379DD0 | 同上 |
| [55] | 0x1422BA280 | 0x142379D00 | 同上 |
| [56] | 0x1422BAF50 | 0x142379D30 | 同上 |
| [67] | 0x1422B9610 | 0x142379CD0 | 同上 |

> 主表与容器窗差异 12 槽（余 67 槽同址）；次表 79 槽仅差 3 槽（[7] = this−48 调整后转发 [0] 删除序 dtor 的 thunk 0x142379160 (定案) / [29] guard_nop / [71] ret1）；ctor sub_142378300 = malloc(1432) 经 sub_14230E910 建 CContainerWindowType 默认型 → sub_1422B3F90(this, 0, …) → 回写 +0/+48/+5944 三 vtable；+5944 = TNullGuiObjectTrait vtable 8B；工厂 0x14225B7D0（产物缓存 qword_143453278 等全局）；无视觉子件承载的逻辑容器 + 查型失败全局兜底窗。

**CPdxWindow (8B)**：

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | 0x1422226C0 | set 句柄 qword_143452188 = a2 |
| [1] | 0x142222670 | get 句柄 |
| [2] | 0x142222680 | get 旗 byte_1430BDDE8 |
| [3] | 0x1422226B0 | set 旗 = a2 |
| [4] | 0x1422226D0 | 对编辑器句柄应用 (a2,a3) 条目链（thunk → off_1430B71D8/0x1430B74D8/0x1430B7708/0x1430B74B8；推定） |
| [5] | 0x142222630 | 取 2×int（句柄尺寸/位置查询，推定） |

> monostate 单例：全槽无视 this 操作全局；访问器 0x1422225E0 懒建 malloc(8) 缓存 qword_143452190；注册 0x14209E610（PHYSFS_freezeConfig 之后）；编辑器域，非游戏 UI 管线。

**CSearchableGridBoxItem (1344B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | CClass* | CButtonEventDispatcher vtable |
| +32 | 观察者胶水 | builder sub_141DE27A0；回调 sub_141DE4460 |
| +1312 | 匿名结构 (NNB 形状)* | 搜索目标变体槽（类型 1 走此，再经 sub_141DE47E0） |
| +1320 | 匿名结构 (NNB 形状)* | 搜索目标变体槽（类型 3） |
| +1328 | 匿名结构 (NNB 形状)* | 搜索目标变体槽（类型 4；3/4 皆取 a2+64 指针） |
| +1336 | uint32 | 搜索目标类型（init sub_141DE45A0 分派 1/2/3/4；2 = 按 "name" 找子件走子流程；其余断言 "Not supported"） |

> GUI 名 "find_view_item"；源文件 interfaces\findviewitems.cpp 断言；工厂 0x1417A4480（两处 malloc 直证；parent = qword_14332F698+1272 会话宿主）；ctor sub_141DE2F40 → init 后子件派发器订阅循环（容器+4312/+4324）；dtor 0x141DE30C0。

**CSelectionList (72 推定)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +8 | CObservable* | 观察者链表头（CObservable 域） |
| +16 | 匿名结构 (NNB 形状)* | 观察者链表尾 |
| +24 | uint32 | 观察者计数 |
| +28 | uint8 | 延迟删除旗 |
| +40 | uint8 | 旗2 |
| +48 | 匿名结构 (NNB 形状)* | 第二链表头（语义待裁，推定待通知队列） |
| +56 | 匿名结构 (NNB 形状)* | 第二链表尾 |
| +64 | uint32 | 第二链表计数 |

> 非视觉 observable mixin（同 COptionObservable 形）；主表 4 槽全定案：[0] 0x14029E970 完整 dtor（清第二列表 → CObservable 部分 0x14029DB90）/ [1] 0x14029EDD0 Subscribe（断言 notificationinterface.h "_ObserverList.Contains( Observer ) == false"）/ [2] 0x1402A0120 Unsubscribe（摘链/延迟删除）/ [3] 0x1402A0270 get 全局 qword_14332F6C8（当前派发观察者）；嵌入实证 CGameIdler +1336（ctor 0x14029D800），另 0x140DCBDA0 / 0x140DE3430 两宿主；独立 ctor 未定位（宿主内联零初始化 + vtable 回写，未决）。

**CSortableGridBoxItem（抽象基座）**：

> [19] = _purecall（0x14253C3B8）→ 抽象基座（**[19] = 排序键取值槽**，返回 int 键 — 定案: 实体派生 CNavalCombatResultsAirSurvivorItem [19]=0x141E07950 `return *(DWORD*)(a1+72)/-5` / CNavalCombatResultsShipSurvivorItem [19]=0x141E07970 `return -*(DWORD*)(a1+88)`；全 exe 共 63 个实体派生）；基域 +0..+31（派生自 +32 起布字段）；删除序 dtor 0x141E06360（0x141E061B0 = 非删除版不 free）；已知派生：

| 派生类 | 删除序 dtor | 布局要点 |
|---|---|---|
| CNavalCombatResultsAirSurvivorItem | 0x141E061E0 | +24 自有次 vtable（CTooltipHandler 位覆写）；+48 指针 + 计数@+60；+64 析构器 |
| CNavalCombatResultsShipSurvivorItem | 0x141E06270 | +24 自有次 vtable；+32 指针（sub_140E6E1C0 拆）；+56 MSVC 串（cap@+64） |

**CWarOverViewWarButton (1336B)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | CClass* | 自有次表（CTooltipHandler 槽位覆写） |
| +32 | CClass* | CButtonEventDispatcher vtable |
| +40 | 观察者胶水 | builder sub_1418A7E10；回调 = OnClick sub_1418ABCB0 |
| +1320 | 匿名结构 (NNB 形状)* | 战争选择器对象（ctor 置 0，装配者填） |
| +1328 | uint32 | 战争 id（默认 −1） |

> 主表 19 槽仅 [0] dtor 0x1418AA8A0 与 [2] 0x1418AD410（转发容器(+16)+48 facet vtable[15](+120)）覆写，余与基表同址；OnClick = sub_1418AC180(*(this+1320), *(u32*)(this+1328)) = 按 id 打开/聚焦战争视图（推定）；工厂 0x1418AFFC0；parent = qword_14332F698+1272。

**CCommandViewButton (1400 推定)**：

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +24 | CClass* | 自有次表（CTooltipHandler 槽位覆写） |
| +32 | CButtonWrapper (1368) | 深窗查找就地内联（sub_1422DC710(+32, 容器, a5 按钮名, a4 回调表, 56B tmp)） |

> ctor 简版 sub_141D1ECD0(this, 父, a3 名串, a4 回调表, a5 按钮名)；完整构造内联于派生 CCommandStructureLeaderView ctor 0x141D1E6E0（1592B 三工厂直证；自有域：+1400 = 0、+1416 CTooltipHandler 64B、+1472 观察者、+1480 = 1、+1488 CreateChild 件、+1496 "leader_t…"、+1504 "idea_…"、+1512 "advisor_type_icon"、+1520 "idea_alert_glow"、+1528/+1560 两 16B 串）；facet tooltip 注册 = (容器+48)→vtable[69](+552)；GUI 名由调用方传入（CCommandStructureView 装配，工厂串 "OFFICER_ARMY" / "_advisors" / "button"）；工厂 0x141D203A0（成员位构造无 malloc；lambda_2/3 经 sub_1402DDEF0 建 20×64B 回调表）；dtor 0x141D1EE60 → 0x141D1ED70（拆 wrapper → +24 → CTooltipHandler vtable → 基）。

#### 4.31.87 突袭地图图标数据族 (NRaids::NUi::CRaidMapIconVariant 及四派生)

**突袭地图图标 GUI 族** (非 def; 五者全部不入存档 — 无 CPersistent 基、无 writer/reader 槽):

| 类 | vtable | 基 | ctor | 关键字段 |
|---|---|---|---|---|
| NRaids::NUi::CRaidMapIconVariant | 0x142A17FB0 | 无基 (纯 GUI) | — | {vtable@0, u8@20, 两块 1368B@24/@1392} = 2776B |
| NRaids::NUi::CActiveRaidMapIconData | 0x142A18000 | ← CRaidMapIconVariant | — | 同族 |
| NRaids::NUi::CRaidTargetMapIconData | 0x142A18050 (9 槽: [1] tooltip 0x141E88240 / [3] GFX 名 / [5] 点击 0x141E88C00) | ← CRaidMapIconVariant | — | +2832 = SRaidTarget 40B 拷贝宿主; 全 14 字段与方法族全案 = §4.27.9 |
| NRaids::NUi::CEnemyRaidMapIconData | 0x142A180F0 | ← CRaidMapIconVariant | 0x1418EABE0 | +2760/+2768/+2776 (ptr×3, +2776 = ctor 第 2 参 = 外部管理器回指) + 2784 (ptr) + 2792 (u8) |
| NRaids::NUi::CRaidUnitMapIconData | 0x142A180A0 | ← CRaidMapIconVariant | 0x1418EAF60 | 同族 |

> 业务侧 CRaidInstance 五锚见 §4.27.1; 行件族 (CRaidSourceItem/CRaidUnitItem 等) 见 §4.31.28。

#### 4.31.88 机构升级/徽标窗族 (CAgencyUpgradesWindow / CAgencyLogoSelectionWindow / 分支图标件)

**CAgencyUpgradesWindow** (= AgencyView 子视图 C, 见 §4.18):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +72 | — | 选中分支 | |
| +80 | — | factory | |
| +104 | — | branches_grid | |
| ag+120 | CCountry* | 回指 | |

分支 DB = qword_14332EDC0 (册锚互证); 升级工期 = AGENCY_UPGRADE_DAYS define 锚。

**CAgencyLogoSelectionWindow** (= AgencyView 子视图 A, 见 §4.18):

| 项 | 值 |
|---|---|
| 名 | ag+128 |
| 徽标 | ag+160 |

改名/换徽标两命令实名 = **CSetIntelligenceAgencyNameCommand /
CSetIntelligenceAgencyLogoCommand**。

**CBranchUpgradeRepetitionIcon** = 72B 纯状态皮 (无字段; 宿主 **CUpgradeEntry**
(实名, 0x1588B) Refresh 内联建)。

**CBranchUpgradeResearchedIcon** (tooltip = sub_140623870(def, idx, tag) 定案;
entry 布局互证):

| 偏移 | 类型 | 名称/语义 | 备注 |
|---|---|---|---|
| +32 | — | 重复序号 | 帧号 = idx + R(R+1)/2 |
| +40 | CAgencyUpgrade* | upgrade | def+540 = 最大重复数 |
| +48 | — | tag | |
| +56 | CBranchUpgradeButtonEntry* | button entry | |

#### 4.31.89 CInsigniaSelectionWindow (徽章选窗; 母窗 = CInGameInterfaceHandler+704, 三军徽章八 kind)

母窗 = **CInGameInterfaceHandler** (全 GUI 聚合根, 1248B; ctor sub_140B614C0
真实范围 0x1F86 字节, ingameinterfacehandler.cpp 路径串 + lambda RTTI 双证)
的 +704 子窗 (+680 CGarrisonLogView / +688 CArmyLeaderTraitWindow /
+696 CNavyLeaderTraitWindow 并置)。

CInsigniaSelectionWindow (vtable 0x142A01900 主 + 更新口 0x142A01950, 0x758B;
ctor sub_1417B5AD0; 窗 insignia_selection_window):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +104..+136 | 五子件 | 窗体 / group_ic / group_name / fleet_color_checkbox / label |
| +1704 | uint8 | **dirty 字节** |
| +1708 | token 对 | **order group** |
| +1716 | token 对 | **fleet** (列表源 sub_1417B67D0 机码硬编码 kind 3, token 15156) |
| +1724 | token 对 | **task force** (取值 −16; ⚠ 运行时实列 fleet 徽章 — 列表源同 sub_1417B67D0 函数体硬编码 kind 3, 调用点传 kind 2 为死参) |
| +1732 | token 对 | **air_group** (列表源 sub_1417B6320 机码硬编码 kind 6, token 12227) |
| +1740 | token | **当前选中徽章 token** |
| +1744 | 匿名结构 (NNB 形状) | HSV 颜色选择器子结构 (color_selection_container / sat / val / picked_color) |

徽章类别库 CInsigniaGraphicsDatabase (Load sub_140A55E30): kind 访问器
sub_140A55E20 = `db + kind*64 + 40`, 八 kind 键全集:

| kind | db+偏移 | token | 键名 |
|---|---|---|---|
| 0 | +40 | 10397 | army |
| 1 | +104 | 14482 | army_group |
| 2 | +168 | 15157 | task_force |
| 3 | +232 | 15156 | fleet |
| 4 | +296 | 15527 | naval_equipment_role |
| 5 | +360 | 19905 | equipment_niche_insignias |
| 6 | +424 | 12227 | air_group |
| 7 | +488 | 12672 | air_niche |

注: niche_selection_widget.cpp 分流 enum 0/1/2 → kind 4/5/7 (陆/海/空装备
niche), air_wing_button_widget.cpp case 4 → kind 7, 与上表自洽。

命令族:

| 命令 | 入口 | 用途 |
|---|---|---|
| CSetOrderGroupNameCommand | sub_14183C260 | 改名 |
| CSetTaskForceIconAndColorCommand | sub_14134A890 | 跟随舰队色 |
| CSetOrderGroupIconAndColorCommand | sub_14183C050 (内嵌 CColor) | 图标+颜色应用 |

CInsigniaEntry (vtable 0X1429FFC50, 0x540B; ctor sub_1417B57D0; 窗
insignia_list_entry):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1320 | token | 徽章 token |
| +1328 | 匿名结构 (NNB 形状)* | 回指母窗 |
| +1336 | 子件 | "button" |

点击 sub_1417B62F0 → 写 win+1740 + 置 dirty。

徽章列表项 (40B; 由 CInsigniaGraphicsDatabase (0x14332EF50) sub_140A55D30
从 insignia def 展开):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | SSO 串 | gfx |
| +32 | uint32 | token |
| +36 | uint8 | 有 FleetColor 标记 |

有色时 vtable+240 叠 CColor (色 = gui+16)。

#### 4.31.90 NAirSelectionUI 行控件双宿主 (CAirBaseSelectionItem / CAirWingSelectionItem)

| 项 | 值 |
|---|---|
| NAirSelectionUI::CAirBaseSelectionItem (reorg 工厂宿主) | sizeof 0x14F8; ctor sub_141FCB410 (3 vtable @0/+56/+104); +5264 基地 idpair (**SetBase sub_141FCD570**, 体首行 `v3 = *(a2+8)`); +2688 glue cb (工厂 sub_141FCC4B0) |
| NAirSelectionUI::CAirWingSelectionItem (popup 工厂宿主) | sizeof 0x2620; ctor sub_141FCE510 (3 vtable); +9744 翼 idpair (哨兵 qword_14333D528); +1400 glue cb (工厂 sub_141FD2240); wing set-wing sub_141FD38B0 (builder case 0 尾调) |
| NAirSelectionUI::SAirMissionItem (任务图标行件, 64B) | {vtable 0x142AA78F0 2 槽 + CStandardGridBoxItem 基@+8 (19 槽次表), +24 基窗, +32 "mission_icon" 元素, +40 "training_will_stop_at_max_icon" (初始隐藏 \|= 0x10), +48 翼 idpair (哨兵同上), +56 u32 mission idx 待裁} — .gui 名 mission_icon_item; 由本行 set-wing sub_141FD38B0 case 0 尾调 0x141FD32C0 构造; 纯显示, 命令出口 = CAirMissionButton (§4.31.38) |
| NAirSelectionUI 选项件四联 (CAggressiveness / CDayNightCycle / CReinforcementPreference / CNicheSelection OptionSelections) | CWingsToolbarWidget 派生 2 槽形; 共享构造 sub_141FDAE10 (mode 0/2/3 分型), +8 CWingUISelectionState& 直存; lambda do_call 0x141F60320 → **sub_1415B87D0** 逐翼 malloc(0x38) 造 CStratAir 系命令 → IsValid → 派发器入队 (与 §4.31.38 sub_1415B8880 同簇; 写门全在命令对象) |
| NAirSelectionUI::CEquipmentPriorityOption (优先级行容器, 1344B) | ctor 循环 **dword_143337588 次** (全局装备优先级档数, 非硬编码) 查 "priority_"+i 元素收入向量 (+1296 {data, cap, size}); 每元素 +8 = 优先级 idx; 剧场选择器 theatreselector.cpp (0x14188C880) 面板件 |
| NAirSelectionUI::CRocketWingsSelectionItem | sizeof 0x2690; ctor **sub_141FD5F30**; rocket set-wing **sub_141FD88E0** (builder case 1 调 + LABEL_113 补空位 base+124==1); 复用器 **sub_141F5DE90** |
| NAirSelectionUI::CGunEmplacementWingsSelectionItem | sizeof 0x1B68; ctor **sub_141FD4160**; gun set-wing **sub_141FD5410** (builder case 2 尾调) |

#### 4.31.91 CDesignerEquipmentCategoryItem (设计器行项)

ctor sub_1414991A0。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1328 | CDivisionDesignerView* | 宿主视图 |
| +1336 | 载荷 | division_names_group 载荷 |
| +1344 | u8 旗 | 点击旗 (旗@+1344 门 → 推 {+1336,1} 进设计器 ES 名字组落账 + designer+17705 脏旗; 回调注册 sub_1414A38A0) |

⚠ +1328/+1336/+1348 簇属本类, 与 CArmy 无关 (CArmy 缺口区 +1228..+1415 亦与此无关)。

#### 4.31.92 NNotification::CNotificationContainer (通知列表行件, 80B)

> **归属**: 本类在 `NNotification` 命名空间的匿名命名空间 (`NNotification::?A0x7797ffe3`) 内,
> 属通知族枚举; 但结构 = GUI 行件 (基链 `CStandardlistboxItem`), 故布局归本册, 派发链仍见 §4.17。

| 项 | 值 |
|---|---|
| RTTI 名 | NNotification::CNotificationContainer (匿名命名空间 `?A0x7797ffe3` 内) |
| sizeof | 80 (0x50) — 分配点 `malloc(0x50)`, 唯一调用点 sub_141391400 |
| vtable RVA | vt0 0x1429B5A08 / vtable1 0x1429B5A78 (TListboxItem 次表, mdisp 56) |
| 基类链 | CStandardlistboxItem → COption → COptionObservable → CObservable; TListboxItem (+56) |
| ctor | sub_1422A9260 (CStandardlistboxItem 族基 ctor) |
| dtor | sub_141391300 |
| 挂载点 | notification_list 列表条目 (建/挂 = sub_141391400, §4.17.5 ② 层) |
| .gui 名 | notification_entry |

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +56 | TListboxItem vtable | 次vtable (8 槽, mdisp 56) | ctor `v10[7] = vftable` |
| +64 | CClass* | **宿主窗元素** (TWindow, 由 `_RTDynamicCast` 校验为 `CContainerWindow`) | sub_141391400; 非容器则断 `notification_handler.cpp:26` "A notifications root element must be a container window" |
| +72 | CNotification* | **承载的通知对象** (列表条目 ↔ 通知 1:1) | sub_141391400: `v10[9] = a2` |

> 基 ctor 的 .gui 解析: 先 `sub_14225C5A0(guimgr, 名, 0)`, 命中且 `+8 == 612` → `vtable+96` 建,
> 否则 `vtable+80` 建; 失败断 `clausewitzlib/graphics/standardlistbox.cpp:26`
> `"gui element '%s' does not exist."` 并回落 `a2[62]`。
> 容器 dtor `sub_141391300`: 宿主窗 `+165 &= ~0x10` (解冻) → 回写 `+165 |= 0x10` →
> `Block[9]` (通知对象) `vtable[0](.., 1)` → `sub_1422A97E0`。

#### 4.31.93 GUI 行件长尾批简卡 (基链/大小/元素名/装配点简卡, 非全布局)

| 类 | 基链 / vtable | 大小 | 元素名 | 装配点与语义 |
|---|---|---|---|---|
| NInternationalMarket::CSubsidyOverview | CUpdateable@0 (0x142AB34B0, 6 槽) + CReloadableInterface@16 (0x142AB34E8) | 232B | — | **市场窗补贴总览内嵌控制器 (非行件本体)**: 挂 CPurchasableEquipmentWindow+2680, 回调 ToggleSubsidiesOverview; 邻座 CListController/CSubsidyListItem/CListWidget 族 = 行件真身 (定案) |
| NInternationalMarket::CContractEquipmentType | CStandardlistboxItem@0 (→COption 链, 0x142AB4F50, 13 槽) + TListboxItem@56 (0x142AB4FC0) | 72B | contract_equipment_type | 市场合同详情「按装备类型」可选行 (宿主池 +5576, 件内 equipment_icon) (定案) |
| NFactions::NUi::CConfirmFactionFacilityProgram | CFactionPopup@0 (→CPopUpWindow→CUpdateable, 0x1429C42C0, 19 槽) + CReloadableInterface@16 + CTooltipHandler@56 | 4216B | — (faction_popup 变体 6) | 阵营设施计划确认弹窗; 同簇 ADD_FACILITY_BUTTON 邻串; 装配 sub_141472080 (高置信) |
| NFactions::NUi::CChangeGoalItemRow | CStandardGridBoxItem@0 (0x142A92F18, 19 槽零覆写) | 32B | change_goal_item_pair_container | 换目标窗 (CChangeGoalWindow, populate = §4.5.2 表 goal_status 行已载 sub_141C08C40) 成对 goal 行容器行; 数据/命令出口在邻座定案, 本类只持布局 (定案) |
| NFactions::NUi::CChangeRuleItemPair | CStandardGridBoxItem@0 (0x142A93360, 19 槽) | 32B | change_rule_item_pair_container (+24 = box_list 子件) | 换规则窗「规则对」容器行; 规则语义/命令出口复用 §4.31.56 CChangeRuleItem (rule def@+1408) (定案) |
| NAirSelectionUI::CDisbandAllOption | CAirWingOptionButton@0 → CWingsToolbarWidget@0 (0x142A9C0C8, 4 槽) | 1312B | btn_delete | 翼选工具栏「解散全部」选项钮; 装配 sub_141CF5ED0 与 SplitWing 同池; 邻串 AIRWING_DISBAND (定案) |
| NAirSelectionUI::CSplitWingOption | 同上 (0x142A9C488, 4 槽) | 1312B | split_wing_btn | 翼选「联队分半」选项钮; blocked 态独立 loc 键 SELECT_HALF_WINGS[_BLOCKED] (定案) |
| CDecisionViewEventCategoryHeader | CStandardGridBoxItem@0 + CTooltipHandler@24 (0x142A70828, 19 槽); 成员 CCheckBoxObserverGlue@+64 | 400B | event_header | 决议网格 (decision_grid) 事件类目头行, 勾选经 glue 回调宿主过滤类目; 池 win+1512 (定案) |
| NCareerProfile::CCareerProfilePageDot | CStandardlistboxItem@0 (→COption 链) + TListboxItem@56 (0x142AA9E50, 13 槽) | 1440B | career_profile_page_dot | 生涯档案多页导航页点行, 回调切 CCareerProfilePages (装配 sub_141FE4DB0) (定案) |

> 注: CStandardGridBoxItem (19 槽 gridbox) 与 CStandardlistboxItem→COption+TListboxItem@56 (13+24 槽 listbox) 是两套并行行件基座; 同族派生常零虚覆写 (仅 ctor 换表), 简卡记「基链 + 元素名 + 大小 + 装配点」即足。槽值均 PE 直读。

#### 4.31.94 零提及件定性批 (负定案名录 + 三件数据形态; 全部 ctor/vtable PE 直读)

**负定案名录** (纯壳/零 gameplay 耦合 — 「此处无操作面」账, 复用先查宿主):

| 类 (主 vtable 槽数) | 基链 | 定性证据 |
|---|---|---|
| CConsoleMemberOption (24=次表) | CStandardlistboxItem→COption | 控制台窗行件 "console_entry_wnd"; ctor sub_142080200 双 vtable 写 (+0 主/+56 COption 次); 全 dump 仅此 2 行命中 |
| CDecisionMapIconContainer (21) | CMapIcon | 决议地图图标容器; 基 ctor (名串, 类型 19); +128..+164 清零 + 三容器头 (+168/+192/+216) 全空哨兵; 零序列化 (基族 §4.30.26) |
| CUnitsStackMapIconGroup (21) | CMapIcon→CUnitsStackMapIcon | 单位堆叠图标成组件型 (工厂 case 1); 208B 与单体同类两型 |
| CProductionSubUnitDefFilter (19) | CStandardGridBoxItem + CTooltipHandler@24 | 海军生产过滤行 "navy_view_ship_entry"; def DB 遍历为显示侧填充 (+176 事件派发器/+184 串), 无存储无序列化 |
| CPdxParticleObject (17) | CPdx3DObject | 粒子 3D 对象: +112 引擎句柄 (按名查找) +120 f32=1.0; dtor 释放句柄 |
| CAnimatedMapText (17) | CPdx3DObject | 浮动地图文字实例: +272 dword/+276 f32=1.0/+112 引擎对象; def 侧 CAnimatedMapTextType 已载 (§4.00.9) |
| CGameLobbyPlayerListener (16) | CGameLobbyListener + TListenerTrait | **8B 接口标签**: ctor 仅写 vtable; 全表 purecall/CFG 桩仅 [1] dtor; 宿主 CPlayerLobby+40 内嵌, 事件实现在宿主次表 0x142A0EC80 (16 槽 11 实函数, 槽[2] = "SYSTEM_PLAYER_ARRIVED" 系统消息) — 多人事件流 = CGameLobby → TListenerTrait 通道 → 宿主次表 |
| CGameLobbyHotJoinListener (16) | 同上 | 同构 8B 标签; 宿主 CHotJoinWindow+96 (次表 0x142A01148, 5 实函数); 与 §4.28.1 CHuman bit1 hotjoin 旗层次不同 (会话玩家状态层 vs 大厅 UI 事件层), 互不矛盾 |
| CStandardInterface (6) | CReloadableInterface + CReloadDispatcher + CTooltipHandler | 窗名驱动接口基: 窗查找→绑定→双 vtable 写; 窗名 SSO@+48 + 会话/管理器 ptr@+80; 纯基础设施基类 |
| CSettingsScreen (6) | CTooltipHandler | 设置屏 ~28KB 全控件观察者 (~20 个 CCheckBoxObserver 步进 64: +27408..+28112 + 按钮/文本观察者); 选项真值走命令通道 → gs+1576 (§4.28.18) |
| CDarkFullscreenOverlayUpdateable (6) | CDarkFullscreenOverlay + CUpdateable | 全屏渐暗过渡件; 工厂 malloc(0x28) {vtable, 基@+8, vtable2@+16, +32 byte=1} |
| CHostConfigurationPupup (6) | CStandardInterface | "multiplayer_host_window" 建主机弹窗; 双 binder 组 (+96/+1384) + 3×CCheckBoxObserverGlue (+2672/+2784/+2896) + 会话 ptr@+3008; Pupup 系 RTTI 实名照录 |
| CMatchmakingGui (5) | CReloadableInterface + CReloadDispatcher | 匹配大厅浏览器: 句柄 +40/+48/+152, SSO 串 +88/+120, 按钮 glue @+160 起 binder 群 (memset 0x500) |
| CShieldObject (89) | CSprite → C2dVisibleObject → C2dObject → CGraphicalObject | 纯渲染壳 (盾形 sprite); **全量证据 = 55 实槽函数体 18 项 gameplay 标记扫描 0 命中** + 类名 dump 仅 2 处全落渲染簇; [2]/[4] = 家族共享 getter/坐标算术非 writer |
| CInstantTextObject (88) | 同上族 | 即时文本对象; 18 参 ctor 全字体/文本/坐标原语; 45 实体 0 标记 |
| C2dLineObject (88) | 同上族 | 2D 折线对象; ctor memset 4000B 点数组 + f32 常量; 41 实体 0 标记 |
| C2dPositionObject (87) | C2dObject → CGraphicalObject | 2D 位置对象 (回调布线); 40 实体 0 标记, 12 处命中全落渲染簇 |
| CDebugMapModeConfig::{CCallbacksWrapper, CNormalizer, CFloatToHsv} | CMapModeData(CDecorator) 族 | **debug-only 负定案**: 调试地图模式装饰器三件 (ShowAiMapModes 回调包装捕 (CCountryTag, CStrategicAI) 闭包 / 数值归一化 / float→HSV 着色); 调试模式 id 14927/14928/14929 (Unit Controller 系), 与 CAiFrontImportanceMapModeConfig 同族 |
| CArmyDivisionListView::HqSlotTemplateChanger | CTemplateChanger 派生 | HQ 槽模板更换器; 全 dump 仅 ctor 1 处内联进宿主 (嵌套子件簇 ≈1288B/件 × ~20); 宿主节已覆盖 (s4_00_bases CArmyDivisionListView) |
| NEquipmentDesigner::CEquipmentNameGroupItem | CStandardGridBoxItem + CTooltipHandler | 装备设计器名组行件 (54 处全在设计器簇; LegacyButtonObserverGlue 绑定); 纯壳 |
| CCustomIconChangeView::CSymbol | CStandardGridBoxItem | 自定义图标更换视图符号行件; 8 处全在视图簇; 纯壳 |
| NCareerProfile::{CCareerProfileViewUpdateable, CMedalDisplaySlot, CRibbonDisplaySlot, CCountryItemBaseGame} | CUpdateable / CStandardGridBoxItem 族 | 生涯档案视图刷新器与奖章/绶带/国别行件四件; 全纯壳 (Medal/Ribbon ctor 现场构造 §4.28.8 已载 MedalData); 归宿 §4.28.8 |

数据形态三件:

| 类 | 形态 | 布局要点 |
|---|---|---|
| CParticleEffectEditor (9; 基 **CPersistent**, vtable 0x142AFBA10) | 粒子效果编辑器工作态 (dev 工具; 控制台命令 particle_editor save/restart/undo/redo/exit/add_animation) | ≥16368B; [1] Save 写**块 407** + 序列化 +8 起成员 / [4] reader case 407 成员 ctor + 读 + 置旗 +152=1/+15525=1; +15552/+16296/+16320/+16344 指针族 (dtor 逐一释放); 块 407 = 编辑器工作态, 未见战役存档路径 |
| CAiFrontImportanceMapModeConfig (5; NDebugMapMode::M::CMapModeData→CMapModeDataBase) | 调试地图模式 "AI Front Importance" 配置件 (96B, ctor sub_141EE1850; 宿主切换器挂模式 2) | +8 = u32 配置 id; +16/+32 = 双 CGameDate (A 哨兵 43808760 / B 0 — 生效区间语义推定); +64/+88 = SEntry 容器双头 (CPdxHybridInlineBufferAllocator<SEntry,51> 内联 51 元; SEntry = 16B {qword@0, u32@8, u32@12} swap 直证, 字段语义待裁) |
| (MMDToOrder 增量) | 见 §4.30.19 定案段 (make_shared 0x558 / +1344 = COrdersGroup 引用包装) | — |
| SSpriteFramePair (48B) | **非 Reader** — 运行时 sprite 选择值对象 | {vtable@0, string GFX 名@8 (32B), int 旗@40 (ctor 恒 1, 待裁)}; 海军活动 GUI 状态机 switch (sub_141E28DA0 ×12) / 占领法图标 (COccupationLaw ctor 内嵌) 等 6+ 宿主按状态填不同 GFX 串 |
| CEntitySprite +1392 内嵌 (≥104B) | SGfxSettingsReader 持久内嵌 (S*Reader 族唯一例外) | owner 回指 @+1456 = a1, 双 SSO 串 @+1424/+1464, sprite settings reload 通道形态 (高置信, 逐 token 语义待裁); CEntitySprite 本体未决 |
| SAudioContext / SSDLAudioContext | 音频后端基类+SDL 派生 (≥2.5KB 运行时件) | 基 dtor 清 +2088/+2160 双 RH 表 (48B 元) + 释放 +2376; SDL deleting dtor free Block[309] @+2472; 存在账, 布局不展开 |
| CEquipmentUpgradeDesignerView (≈2744B) | 装备「从既有变体升级」子设计窗本体 | 窗 equipment_upgrade_designer_window (宿主 0x141F729C0; 元素 upgrade_assigned_industrial_org / variant_name 等); ctor 0x141F6F120: 双 CLegacyButtonObserverGlue (+8/+1296) / +2640 = MIO 检索指针 (ctor sub_140C94220(qword_143339BE8) 初查; **选型分发 sub_141F71EF0 以当前选型 def 为键 sub_140BD77D0 重查**, 命中对象 +1016 回写 def 指针) / +2656 变体名 SSO / **+2704 NIndustrialOrganisation::CTraitBonus 内嵌** (§4.8.12b 同型); 三个调用域共用 (角色钮 / ship_refit / plane_designer_model_list); 装备设计器总装配锚 = 0x141788E70 = CEquipmentDesignerView::Create (lambda 符号直证, §4.23.10); 运行期四函闭环见 §4.31.99 |
| CEquipmentUpgradeView / CEquipmentModuleSlotView / CEquipmentRoleSelectionWindow | 设计器行件三件 (零序列化) | UpgradeView = 已获变体行步进子视图 (ctor 0x141DDE000: 双列表控制器 +224/+1512, btn_inc/btn_dec/level/name 四元素); ModuleSlotView 真 ctor 0x141DDC320; RoleSelectionWindow 真 ctor 0x141F6D910 |


#### 4.31.95 CButtonWrapper 与按钮包装访问器 (buttonwrapper.h 定案)

簇定性: buttonwrapper.h = 单一非模板具体类 **CButtonWrapper (1368B)** + 两处内联按钮访问器 (头文件行 34/40); 簇 64 函数全是访问器内联展开落点 (2 个落出体副本 + 62 个消费者, 跨 ≥20 GUI 域) — 非模板实例族。布局 (五件互证定案: ctor 0x140B77E10 / dtor 体 0x1422DD3E0 / Assign 0x1422DDC40 / Init 0x1422DDB50 / BuildTooltip 0x1422DD920):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable* | **CButtonWrapper vtable 0x14294C180 (仅 2 槽; RTTI `.?AVCButtonWrapper@@` 直证)**: [0] BuildTooltip 覆写 0x1422DD920 (委托 +1304 std::function; callable 缺失时 sub_14251BAFC 兜底) / [1] scalar deleting dtor 0x140B7B4B0 → 体 0x1422DD3E0 |
| +8 | CButton* | _pButton (GetButton 0x140F28770 返 `*(a1+8)` 直证) |
| +16 | vtable* | 次基 **CButtonObserverGlue** vtable 0x14273AA38 (12 槽) |
| +24 | std::function[20] | **20×64B 事件回调表** (槽内 +56 = callable; ctor sub_1402DDEF0 建空表; Assign 逐槽移 0x1422DD1F0/0x1422DD4A0; 与 §4.00.6 glue 同构) |
| +1304 | std::function | **tooltip 构造回调** (BuildTooltip 委托目标) |
| +1360 | 可调用指针* | **= +1304 的 callable (定案, 原「语义未决」升档)**: 非空 ⇒ Init/Assign 时 `button->vt[69](button, wrapper)` 把 wrapper 注册为按钮 tooltip handler (写 button+80) |

**双基结构 (dtor 尾部直证, 0x1422DD3E0)**: 主基 = **CTooltipHandler** (0x14273AA08, dtor 尾恢复其 vftable@+0), 次基 = CButtonObserverGlue (恢复 CButtonEventDispatcher vftable@+16 = glue 链顶基); wrapper 自身**不覆写任何 glue 虚方法**, 仅覆写主基 BuildTooltip (vtable[0]); 事件路由全靠 +16 glue 回调表。**注册/分派链 (全函数族定案)**: 宿主 view ctor → builder **sub_1422DCB20**(out, button, glueSrc, funcSrc) 建壳+空表 → Init **sub_1422DDB50**: Clear **sub_1422DD950** (解订+清 20 槽+销 tooltip 回调+_pButton=0) → _pButton = button → glue 克隆 **sub_141B2CF40** 入 +24 → tooltip 回调移入 +1304 → **(button+128)->vt[1] 订阅 CButtonObservable (observer = wrapper+16)** → +1360 非空则 vt[69] 注册 tooltip handler; move-assign **sub_1422DDC40** = 解订旧钮→交换 _pButton→移表→移 +1304→重订→条件回指 (赋值入口 0x1422DD480); dtor 体 0x1422DD3E0 解订+清回指+销表。**耦合点 = 宿主 ctor** (.gui 模板键经 CButtonType 建 CButton 实例后宿主自绑回调) — **不经 idb 库、不经 token 表**; wrapper = 「按钮句柄 + 回调表 + tooltip handler」三合一宿主对象。消费侧形态补: 按钮组批量遍历形 = 宿主 +2792 数组 / +2804 计数, 条目 +8 = _pButton (0x1415D8330 刷帧 / 0x141C70D70 失效); 内嵌样板 = NRaids::NUi::CRaidSimpleTextItem ctor (wrapper @ 宿主 +24, lambda 经 builder 落回调)。访问器对 = sub_140F28770 (行 34, 23 函数全只读/tooltip 语境) / sub_140F28EA0 (行 40, 41 函数全变异语境) — 体全同仅断言行号异 (不被 ICF 合并), **const/非 const 双过载** (推定)。断言三件套: 门 byte_1435E1B52 + 按 (表达式, 文件, 行) 全局去重旗 byte_14333D404/405 + 处理器 sub_1424C8080。

CButton 槽语义 (定案): **+568 IsNullObject 判定 (基类实现 = 0x14011D220 `return 0` 恒非空 — 簇内 `vt[71](btn)` 判空实为存活校验)** / **+176 SetFrame (帧 1 常态 / 2 选中; 实现 0x1422D1ED0, 写 button+496)** / **+552 = [69] SetTooltipHandler 实现 0x1414A57E0 (写 button+80) / +560 = [70] GetTooltipHandler 0x1406773A0 — button+80 = CTooltipHandler\* 回指, 跨 CButtonStandard/CIcon/CButtonDrag 同址** — 页点/单选钮选中态实现; **显隐槽方向定案 (df87 三证收敛, 原推定升档)**: **vtable[+120] = Show / vtable[+128] = Hide** (对偶分支 sub_14202A1B0 同函数内双语境 + teardown/应用语义对偶 + 隐藏扫描全 +128 三证) / **vtable[+648] = Show / vtable[+656] = Hide** (badge 显隐条件二选一 sub_141BBF940 + 布尔直选 sub_141D1F7D0); **wrapper+117 bit0x10 = hidden 态旗** (+120 路径清 `&= ~0x10` / +128 路径置 `|= 0x10`, 与页点 +165 位 0x10 同律)。

**wrapper 布局与回调形态增补 (定案/高置信批)**: +16 (glue 首槽) 存**按钮指针副本** (FillTooltip hovered 比对基准); **+1368/+1376 尾块双对象成对** (+1368 对象 A = 文案提供者 / +1376 处理件; 访问器**第三形态** = 内联展开时 this = wrapper+1376 尾块件, 断言反取 `*(this−1376)`; BW34 断言 15 处内联 / BW40 30 处)。**CTooltipHandler FillTooltip 形态学 (定案)**: 簇内 15+ 个 `char f(this, hovered, out)` 无调用者函数 = 各 GUI 件次vtable FillTooltip 覆写, 通用前置 = hovered 与 `_pButton` 指针比对, 不等即返 0; 文案 SSO 串经 sub_140129C10 转出 out。**过滤面板四兄弟模式应用核心** = sub_141FFB030 / sub_14200B8E0 / sub_142058A30 / sub_141FFFD40 (第四件 = "equipments_grid_container" 装备格过滤, 含 no_market_access_no_equipment_to_buy_text 无货三态文案; 体同构: 脏旗 host+4088 → 各 widget teardown → radio4/radio5 帧扫 → 按 mode 内联显扫); **radio4 帧扫 = sub_142001D30 (钮槽 a1[5]/[184]/[363]/[542]) / radio5 = sub_142001F80 (+[721])**, 每钮 SetFrame((mode==k)+1), 步长 179 qword = 1432B (与行跨定案互证; gridbox 侧 CBranchUpgradeResearchedIcon 整行 1432B 第四证); **widget 物理顺序** host+2656 = infantry / +2664 = tank / +2672 = plane (行数 4/5/4 双写直证); **行数组 = N 数据行 + 1 尾随行** (teardown 拆 N+1 / radio 扫 N); **尾随行 OnClick = sub_142002DF0: `win->mode(+584)==本行 mode` 时置 mode=N(=行数) + radio5 帧全回落常态 = mode==N 即清空过滤** (尾随行语义定案)。**NDoctrines::CEntryButton::Setup sub_141D23290** = 深建模式实例 (sub_1422DC710 栈 1376B wrapper 深建 "button" 子件挂 this+40, context 存 +1432)。

按钮包装宿主新件 (RTTI 直证):

| 宿主 | 要点 |
|---|---|
| 市场过滤面板 (行数 N=4/5 定长行数组模板) | 9 函数按 N 成对 (teardown / radio 帧扫 / tooltip) × 3 宿主编排; **行跨 1432B = wrapper 1368 + 64 尾块** — §4.31.59 上架窗 +6392/+6400/+6408 过滤 widget「初值 4/4/5」由此定案 = **行数** (infantry 4 行 / tank 5 行 / plane 4 行) |
| CFactionPingWindow (NFactions::NUi) | SetupDerived sub_14179A150 (lambda 1-5 挂 glue); wrapper 连续阵列 @+4560 步长 1368, 显启扫 sub_14179DB20; 同域 sub_14179E2A0 |
| NCareerProfile::CCareerProfilePageDot | 页点条目 (条目+80 wrapper / +165 位 0x10 选中旗 / SetFrame 选中?2:1); 刷新器 sub_141FEEC30 (池 +2752/+2764, 选中 +2776) |
| NAirSelectionUI::NQuickWingDeployment::CWingQuickDeployWidget | quick_wing_deployment_item; 行构造/绑定 sub_14205C3B0 — NAirSelectionUI 8 派生表外新件 |
| CShipStatsViewAirWingEntry | 行内容刷新器 = sub_141BF0C60 (写其 vftable; §4.31.42 类本体 80B 零覆写) |
| NInternationalMarket::CMarketEquipmentItem | 行 ctor sub_142041050 (selection_button/general_name/stockpile_amount/price_level_icon/convoys_icon/creator_flag/has_subsidies_icon 七件; 四过滤窗各一调用方) |
| CPoliticalSelectableIdeaItem / CIntelLedgerDoctrineEntry / CSelectArmyLeaderPreferredTacticsEntry | 行 ctor 实名 (RTTI; 后者双 lambda 过滤 sub_1416D25A0, 前者 "ledger_tech_entry" 模板复用) |
| NProject::NUi 域 (0x14147 段) | §4.31.96 池挂两大宿主 +12608/+6880 的 0x14147 段类名待裁解决 = **NProject::NUi** (special_projects 列表/过滤 UI, §4.31.98); 建筑受损 FillTooltip = sub_141DC02B0 / 阵营成员升级 = sub_141F0A140 / 国际市场过滤钮对 = sub_141FFD8C0 (BW34 形态学 +3 落名) |

df87 簇新定案大件 (buttonwrapper 消费侧, 域归属靠元素名串链):

| 函数 | 身份 | 要点 |
|---|---|---|
| sub_14157F870 (1,564) | **政治视图按钮全路由/tooltip** | leader/party/ideology/elections/pol_faction_icon/pie_chart/add_national_goal (CLICK_OPEN_FOCUS)/drop_focus (FOCUS_CANCEL_BUTTON_DESC)/remove_goal (POLITICS_RESELECT_GOAL)/dismantle_faction (DIPLOMACY_DISMANTLE_FACTION_TITLE)/manage_occupied_territories 全路由表 |
| sub_1416DFC80 (948) | **驻防命令 + 战计执行速度刷新** | garrison_order_headline / BATTLE_PLANS_X_WILL_BE_ASSIGNED / GFX_BPT_execute_mid/fast/slow; 调用者双域 = 战计工具窗 sub_1416DDAB0 + orders 域 sub_140B68600 (§4.24.14 驻防链直连边) |
| sub_141F1D850 / 141F21D30 / 142024B30 / 1420261F0 / 141FBAFE0 | **MIO tooltip 五件** | 政策条目 / 任务容量 (断言 "pOrg" industrial_org_list_item.cpp:212, wrapper@**this = COrganisationListItem+104 子对象 (CTooltipHandler 副基; 尾调 sub_141F21750(a1−104) 回基)**, +15888 即 item+15992) / 解锁特质弹窗装配 (sub_1420261F0 断言行 40 = BW40 setup 语境, INDUSTRIAL_ORG_UNLOCK_TRAIT_POPUP_* 装配, 非纯 FillTooltip) / 详情窗历史升级行; INDUSTRIAL_ORG_* loc 族 |
| sub_140F2A5F0 (606) | 阵营情报窗 FillTooltip | FACTION_INTEL_HEAD_OF_SPYMASTER / AGENCY_DEFENSE_LEVEL_* / CREATE_AGENCY_* 等 |
| sub_141DD53B0 (202) | **学说窗口 folder tab 刷新** | tab 名数组 @+88 步进 72B / 选中名 SSO @+1552 / 副本区 +1584、+3088 (门 +4592); 子窗 "button" 两级查找 vtable[+104] 直取 ∨ vtable[+536] 深查; SetFrame((idx==选中)+1) — 帧号 ±1 双分支待裁 |
| sub_141B350E0 (435) / 141B34F70 | 袭击反馈弹窗行构造 + dismiss tooltip | raid_feedback_view 窗族 (§4.33 raid 命令同窗) |
| sub_141C27A20 (430) | 1456B 池化 gridbox 条目刷新 | gridbox.h:654 断言; 池装配 sub_141476030 (条目 ctor 141C26510 malloc 1456 / 绑定 141C27950 +48 目标 id); 池挂两大宿主 +12608 / +6880 (0x14147 段, 类名待裁) |
| sub_141BB7910 / 141BBF940 | profile badge 条目 + tooltip 显隐 | "pictur" 子件 SetTexture ← idpair 解引; 会话 tag 比对分叉; +648/656 方向关键证据 |
| 其余 FillTooltip/行构造 20 件 | 间谍首脑条目 / grand doctrine 槽 / raid 过滤器 / 建筑受损 / naval_headquarter / 采购合同取消 / 特遣母港 / 科学家招募钮 / 阵营目标 glow 帧刷 / 阵营规则组行 / 阵营成员升级条目 / 国际市场过滤钮对 | 各 GUI 域元素名可检索, 详细见 archive findings |

#### 4.31.96 CEmptyEntryListBase\<T\> 行项回收池 (emptylists.h 定案)

GUI 行项回收池模板 (73 实例; T = 行项类: CIntelLedgerTechnologyEntry ×10 / CNegotiatorFlagEntry ×8 / CEquipmentModelListItem / CTinyUnitCounter / COperationViewEntry 族等)。持 T* 指针数组, 池内 = 未用/已回收列表行项; 销毁时逐项校验已从 gridbox 摘除。**无实例级全局单例槽** — 全部实例为宿主 GUI 视图内嵌成员 (CNavalCombatView +472/+6840 / CCountryNavalRegionView +855 等); 全局件仅 per-instantiation 断言旗 byte_14338xxxx 族。

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable | CEmptyEntryListBase\<T\> |
| +8 | T** | data (指针数组) |
| +16 | int32 | cap |
| +20 | int32 | count |
| +24 | allocator* | (vtable+8 alloc(bytes,align) / vtable+16 free) |
| +32 | int32 | 第二计数 (clear 时清 0) |

宿主内嵌另有**池管理器双向量形态** (无自有 vftable): A 活动表 {data@0, cap@8, count@12} + B 空池 {data@24, cap@32, count@36, allocator@40}; 排空 = A 逐项倒出推入 B 再销毁 B 全部 (drain+destroy = sub_141734CD0)。

销毁协议 (逐项): [debug 总门 ∧ per-instantiation 旗] → 引用校验 → deleting dtor `item->vtable[0](item,1)` → count 清 0 → allocator free(data)。

校验断言两式 (同尾句 "GUI object managed by empty list is still referenced when deleted! … use after free later on."):

| 断言行 | 条件 | 链语义 |
|---|---|---|
| 44 | `!obj->HasAnyObserver()` | obj+24 dword 非零 = 仍被观察 |
| 60 | `pItem->GetWindow()==null ∥ GetWindow()->GetOrigo()==null ∥ GetOrigo()->GetParent()==null` | item+16 window → window vtable[+208] (槽 26) GetOrigo → origo+280 parent |

> 与 gridbox 的引用关系 = **单向收养-摘除契约**: 池项曾被 gridbox/listbox 收养为行, 回池/销毁前必须已 RemoveChild (parent==null); 断言文本点名 "gridbox or alike"。window vtable[+208]=GetOrigo / origo+280=parent 槽语义同供 §4.30/§4.31 vtable读法复用。

#### 4.31.97 CSkillTreeBase\<T\> 布局机制 (skill_tree.h; 将领版 CUnitLeaderTraitTree)

特质树 UI 布局系统通用层 (MIO 版 CTraitTree 见 §4.31.40 同构; .gui 模板 = interface/traittreewindow_common.gui, 要素 = skill_tree_empty_window_for_line 连线占位容器 / skill_tree_exclusive_vertical|horizontal 互斥分支角标 / skill_tree_line_mid 连线段)。将领版特化: CUnitLeaderTraitTree (vtable 0x1429ED7C0; 条目 CUnitLeaderTraitTreeItem vtable 0x142A69D8/0x142A69820; 基 CSkillTreeBaseItem vtable 0x142A69728/0x142A69770)。

| 偏移 (树宿主) | 类型 | 名称/语义 |
|---|---|---|
| +24 | 容器* | 连线占位窗父容器 (a1[3]) |
| +40 | 节点* 数组 data | 节点数组 (a1[5]) |
| +52 | int32 | 节点 count |
| +176 | {i32,i32} | 内容包围盒 (布局后写, a1[22]) |
| +184 | uint16 | 状态字 |
| +185 | uint8 | 布局脏旗 (置 1 → 刷新) |

| 偏移 (节点元素) | 类型 | 语义 |
|---|---|---|
| +24 | uint8 | hidden 门 (布局遍历跳过) |
| vtable+16 (槽[2]) | — | 返回该节点树格列表 {data, count@+24}, 元素 12B {格 x i32@0, 格 y i32@4, 辅@+8} |

布局主算法 sub_1416C9BE0 (将领版; MIO 版 = sub_141FBFF80): 宿主虚槽 [10] (vtable+80) = orientation (0 水平/1 垂直, 其他断言 skill_tree.h:791 "unknown orientation in skill tree"); 每格取相对父节点位移 (dx,dy) → 方向位 = (dx>0?4:8) 与 (dy>0?1:2) 组合 (位掩码 1/2/4/8 四向); 线段发射经线型规格 32B {步进 dx@0, dy@4, 尺寸@+8/+12, 段数@+24} (sub_141D12C10) 沿步进逐段放贴图 (sub_1416C9470); **布局不变量**: 子格与父格同位置 → 断言 skill_tree.h:358 "cell and its parent have the same position"。连线占位窗生成 (sub_1416C8F60 将领 / sub_141FBED80 MIO): 全局递增计数 dword_14338CD60 → 名 "connection_line_N" → UI 模板实例化工厂 sub_1422B8BC0 (容器, "skill_tree_empty_window_for_line", 名); 位置经子窗虚槽 [91] (vtable+728) 设置。连线模板名 getter (sub_1416CB630 将领 / sub_141FC0C20 MIO): direction∈{1,2,4,8} 分派 → **树节点vtable槽 [13]-[16]** (vtable+104/+112/+120/+128) 四模板名 (trait_tree_line_{left,right,top,bottom}[_dotted]); 非法方向断言 :590 "unknown skill tree direction"。宿主窗持**双树实例** (a1[36]=+288 / a1[38]=+304 指针槽; +296 = 名 "tree" 子窗查找), 重建 sub_1416C4160 灌两树 + 置 +185=1 → sub_1416CD520 刷新 (门 = 脏旗 ∥ 状态字)。节点数组稳定重排基建 = std::rotate/inplace_merge 链 (sub_1424287D0 → sub_142428130, 40B 元素 {int@+0, qword@+8, shared_ptr 16B@+16}, sub_142429890 = _Reverse)。

#### 4.31.98 NProject::NUi::CProjectListFilterWindow\<TItem\> (special_projects 列表过滤窗; project_list_filter_window.h)

特殊项目列表过滤窗模板 (三实例化 TItem = CResearchFacilityItem / CProjectHistoryItem / CProjectSimpleItem, lambda 名直证; Setup 断言 `_pWindow == nullptr && "Window already created."` :150):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vtable | CProjectListFilterWindow\<T\> |
| +40..+136 | SSO 串 ×4 (步 32: +40 窗/+72 格/+104 列/+136 容器) | 模板名 |
| +168 | CWindow* | _pWindow (Create = 模板 db `**(qword_14332F698+1272) vtable+96` 以 +40 名实例化) |
| +176 | CGridBox* | 格 (sub_1422BA420(window, this+72, 1, 1)) |
| +184 | CButtonWrapper | **内嵌 1368B** ("close_button" 深建 sub_1422DC8A0 + 胶水 sub_1422DD480) |
| +1576 | — | 列/子格 |
| +1584 | — | 行容器 |

Setup 流: 建窗 → 双 lambda (tooltip + click) → close_button 挂 wrapper → 建 gridbox/列/容器 → 取库 (sub_140496D20 + sub_140ABAB90 得 tag 数组) → 逐 tag 查条目 (全局 RH 表 qword_14332F068, 0x45D9F3B 双轮雪崩 lo^hi 索引, 桶 56B {链长 u8@+4, 键 u32@+8, 值 qword@+16}, miss 落 0; tag = idpair {lo,hi}) → 建行挂格 → 刷新 sub_141473D60。**行件 1456B** — 三实例化各自 ctor: Setup<CResearchFacilityItem> = sub_141471C40 (行件 ctor sub_1414683C0, 回调槽2 = sub_141471910, 插入器 sub_1402DEC80) / Setup<CProjectHistoryItem> = sub_141CB1D30 (ctor sub_141CADF10, 槽2 = sub_141CB1CE0, 插入器 sub_14146D5D0) / Setup<CProjectSimpleItem> = sub_141CB2170 (ctor sub_141CAE4D0, 同 History 组); 回调槽 1/3/4 三实例共享 (sub_14146D5E0/sub_1414719D0/sub_1413331D8); History/Simple 共用 0x141CA 段组, ResearchFacility 独用 0x14147 段 (§4.31.95 同源说法只覆盖后者)。⚠ **两行件尺寸须区分**: 过滤窗包装行 = **1456B (0x5B0)** (gui 名 "project_list_filter_entry", CFilterEntryItem 包装头 32B); **名册本体行 = 1424B (0x590)** (gui 名 "history_list_item", CProjectHistoryRoster::Populate sub_141F337E0 建元 — 可视区虚拟列表, 行数 = (容器高 − cabinet_top_border_size)/history_list_item_size, :79 断言行高禁 0; 双 vtable @+0 CProjectHistoryItem / @+1408 CTooltipHandler; 基 CProjectFilterListItem + CStandardGridBoxItem) — 勿按 1456 读名册行。**NCountryFilterUI::CCountryItem** (市场可购装备窗国家过滤列表行, 双 vtable @+0/+24, 128B 基 + wrapper 内嵌@+48 ctor sub_140B77E10 + tag_id@+1416 + 旗@+1420; "country_flag"/"country_name" 子件)。

#### 4.31.99 CEquipmentUpgradeDesignerWindow 运行期 (equipmentupgradedesignerwindow.cpp; 4 函闭环 — Setup 绑定图 / 选型三态换装 / 等级行重建 / MIO 槽 GFX)

窗对象 25920B (与 §4.31 窗体清单 CEquipmentUpgradeDesignerView 行同体); 四函全部体内含 cpp 锚:

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_141F729C0 | 461 | 错误日志 "No model selector window found in the equipment upgrade designer window. Model selection will be unavailable." @519 | Setup 全元素绑定图 |
| sub_141F71EF0 | 196 | 断言 "Unhandled equipment type" @122 | 选型分发器 (内嵌三态设计视图换装) |
| sub_141F73400 | 332 | 错误日志 "Failed to find override upgrade window %s, will use default one instead" @245 | 升级等级行重建器 |
| sub_141F70620 | 97 | 断言 "unknown equipment type" @880 | MIO 槽 GFX 键选择 |

**Setup 绑定图** (sub_141F729C0; 存储偏移均相对窗对象):

| 元素/对象 | 通道 | 存储 |
|---|---|---|
| equipment_upgrade_designer_window | 父容器 +7072 → +1272 容器 vtable[12] CreateWindowByName | +7080 (窗本体) |
| variant_name | 按名取元 vtable[16] → 绑回调接收者 | 接收者 = +2784 (CTextBufferObserverGlue, 窗体清单行互证) |
| close_button | 按钮 lambda (sub_1422DC8A0) | +48 |
| save_button | 按钮 lambda | +1416 |
| select_model_button | 先 sub_1422B9CA0 探存在 → 按钮 lambda | +5680 (可选元素) |
| open_roster | 列表双 lambda (sub_1402E1260 行模型 + +128 附 lambda) → sub_1422DC710 列表绑定 | +2944 |
| upgrade_assigned_industrial_org | 按钮 lambda | +4312 |
| equipment_select_model | sub_1422BA420 查子窗 | +21232 (命中 → sub_141DD5050(+2656) 模型选择器 init; 未命中 → @519 错误日志, 模型选择不可用不中断) |
| 设计视图 | malloc 2744 → sub_141F6F120 ctor (父容器, this) | +7088 (= 窗体清单行三方互证) |
| equipment_designer_stat_entry ×78 | malloc 88 → sub_14149A2B0 逐条构造 | 数组 @ +7048 (**78 条统计行预建**) |

**选型分发器** (sub_141F71EF0; a2 = 装备类型/原型 def): ① 旧 MIO 检索指针 (+2640) vtable[0] 释放 → sub_140BD77D0(a2, +2640) 以选型 def 重查存回, 命中对象 +1016 = a2, +2688 清 0; ② a2 == 当前选型 (+2632) → 只刷 sub_141F73C00 返回; ③ 旧内嵌视图 (+2624) 摘除 (可视位暂存 → vtable 槽 25 (+200) 销毁); ④ 按 *(a2+1008) 原型对象判族 (谓词 = 递归父链 + 类别掩码 sub_140F8B020): & 0x1F0037FC00 (sub_140C97430) → air_equipment_designer_view; & 0x80004003C1 (sub_140C97B90) → naval_equipment_designer_view; & 0x408000003C (sub_140C97600) ∨ sub_140C97C00 (**& 0x80000 railway_gun 位**) → land_equipment_designer_view (**railway_gun 归陆设计器**); 其余断言 @122 (闩 byte_14338CB22); 建视图 = sub_141F70410(容器 +2616, 名); ⑤ 新视图绑定 (元+48 子对象 vtable 槽 69 (+552) 绑 this; 原可视 → vtable 槽 15 (+120) 显示) → sub_141F73400 重建等级行 → sub_140B46320 列表绑定 (+2608, `"archetype"`/`"_medium"` 串参) → sub_141F73C00。

**升级等级行重建** (sub_141F73400): 先遍历内嵌视图子窗逐个隐藏 (+165 |= 0x10) + +2596 行计数清 0; 数据源 = *(a2+1008)+1456 升级等级数组 (**72B/条目, count @ +1468**) 逐条目名 (+8 SSO) 比对等级名; 逐等级 sub_1422BA420 找覆写升级窗, 未找到 → @245 错误日志 + vtable 槽 55 (+440) 建默认窗兜底 (窗内 +4312 数组 count +4324 逐元 +8 = 等级序号); 按名取四元 decrease_level/increase_level (vtable 槽 13) 与 level/label (vtable 槽 15); 追加 32B 行 {label, level, increase, decrease} 到动态数组 {data +2584, cap +2592, count +2596} (扩容 = max(count+1, cap×1.5)); 新行接线 (label 文本 sub_1422CA920; increase 回调接收者 = +8 / decrease = +1296, 各带等级序号 +8; 行窗 +165 &= ~0x10 取消隐藏, 原可视 vtable 槽 15 显示)。

**MIO 槽 GFX 键** (sub_141F70620; a2 = 装备类型 def, sub_140C95730 = def→类别掩码): & 0x4 → GFX_idea_slot_tank_manufacturer; & 0x80000038 (**含 parachute 位 23**) ∨ sub_140C97C00 (railway_gun) → GFX_idea_slot_materiel_manufacturer; & 0x1F0037FC00 → GFX_idea_slot_aircraft_manufacturer; & 0x80004003C1 → GFX_idea_slot_naval_manufacturer; 其余断言 @880 (闩 byte_14338CB23) → 空串。唯一调用方 = sub_141F74540 (同窗族)。**parachute 位 (23) 参与 materiel 判定** — 该位无 token 但有语义 (§4.23.15)。

未决: Setup 六枚 lambda 函数体语义 / +7072 父容器定名 / 78 条 stat entry 的逐条消费 (+7048 数组读者未追)。

#### 4.31.100 CGameSetupCustomSettingsWindow 运行期 (setupcustomsettingswindow.cpp; 2 函闭环 — 主窗 Setup / 难度组视图 Setup)

簇清册 (体内 cpp 锚 2/2; 书内原仅类名登记, 两函均新定案):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141F54780 | 475 | setupcustomsettingswindow.cpp :785..:811 (latch byte_14338CAFB-CB03 连号) | CGameSetupCustomSettingsWindow::Setup (建窗 + 滚动容器 + 设置格 + 难度组视图 + 按钮栏全绑定) |
| sub_141F55230 | 193 | 同 CU :46 (latch byte_14338CAFA) | CDifficultySettingGroupView::Setup (2808B 视图布局) |

**主窗绑定图** (窗对象; 全部子件断言带 latch 连号 — 找不到即断言):

| 偏移 | 语义 |
|---|---|
| +40 | close 回调载荷 (经按钮 +128 内嵌包装物 vtable+8 绑定) |
| +1328 | load 回调载荷 (同上) |
| +2616 | save 回调载荷 (同上) |
| +3904 | revert 回调载荷 (同上) |
| +5192 | 模板 db 持有者 (成员内持管理器, *(其+1272) vtable+96 = Create) |
| +5224 | _pWindow (Create "gamesetup_custom_gameplay_settings_window"; 前置断言 :785 "!_pWindow" / 后置 :790) |
| +5232 | _pScrollableWindow (窗 vtable+440 GetChild "scrollable_container"; :793) |
| +5240 | _pSettingsGroupsGridBox (容器 vtable+432 GetChild "settings_groups_grid"; :796) |
| +5248 | CDifficultySettingGroupView* (2808B 堆对象; 旧值先析构再覆盖) |
| +5304 | _pCloseButton (条 vtable+104 GetChild "close_button"; :808) |
| +5312 | _pButtonBar (窗 vtable+440 GetChild "button_bar"; :801) |
| +5320 | _pLoadButton ("load_button"; :809) |
| +5328 | _pSaveButton ("save_button"; :810) |
| +5336 | _pRevertButton ("revert_button"; :811) |

流程尾 = 设置条目列表两段刷新 (sub_141F51CC0 → sub_141FC9F10 / sub_141F51C40 → sub_141FC9C70, 未深读)。

**难度组视图布局** (2808B; ctor 链 = malloc → sub_141F51500(view, 模板db, "difficulty_setting_group_window") → 双 vtable (+0 主 / +24 副) → +2752/+2776 SSO 串 ×2 → +2800 区清零 → Setup):

| 偏移 | 语义 |
|---|---|
| +16 | 父容器 (ctor 所建) |
| +24 | 回调载荷 A → 父容器 vtable+552 注册 (自指针判空兜底) |
| +32 | 回调载荷 B → expand_button 绑定目标 |
| +1320 | 回调载荷 C → 头部 vtable+536 取出对象的 +128 包装物绑定目标 |
| +2608 | 回调载荷 D → 复选框绑定目标 |
| +2720 | _pHeader = sub_1422B8BC0 双同名串 "game_setting_group_header"; 断言 :46 |
| +2728 | group_name 元素 (头 vtable+120 GetChild) |
| +2736 | _pExpandButton (头 vtable+104 GetChild) |
| +2744 | _pUseCustomSettingsCheckbox (头 vtable+168 GetChild) |
| +2752 | SSO 串 (标题占位) |
| +2776 | SSO 串 (名域占位) |

展开钮三态同步: 绑定后读按钮 vtable+184 状态, 状态 != 2 时经 vtable+176 写入 (1 ↔ 2 互斥对齐); 复选框取到后先调其 vtable+128 再绑包装物; 尾 = 父容器 vtable+552 注册 + 自身 vtable+152 虚调 (语义未追)。Setup 绑定图样板与 §4.31.99 一致 (GetChild 槽位族 / +128 包装物绑定原语)。

未决: 四回调载荷 lambda 体 / 父容器 vtable+552 与自身 vtable+152 尾调语义 / 两段刷新函数。

#### 4.31.101 GUI 修正条目 tooltip 两级发射器 (interfaces/modifierentry.cpp; 2 函闭环 — 涨跌着色行 / 按 id 基值表)

簇清册 (体内 cpp 锚 2/2; sub_141D2FF80 无直接调用者 = 虚槽/函数指针目标):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141D2FF80 | 552 | modifierentry.cpp:226 (断言 "Unexpected modifier type!", B51, 闩 byte_14338C67B) | 修正条目 tooltip: HEADER + 按 id 基值行 + 现值行 |
| sub_141D31140 | 231 | :58 (断言 "Never expected", B51, 闩 byte_14338C67A) | 涨跌着色值行发射器 (abs(新) 与 abs(旧) 比较, invert 翻极性) |

**涨跌行** (sub_141D31140; (out, 新值*, 旧值*, invert, percentage, hour)): 符号 → 键 **POSITIVE_VALUE / NEGATIVE_VALUE / NEUTRAL_VALUE**; percentage → 后缀 "_PERCENTAGE"、hour → "_HOUR"; 本地化参数名 "VALUE" (值 = 新值原值非 abs); 着色语义由本地化文案承担。同 TU 调用链: sub_141D2FE20/sub_141D31630 → sub_141D31650 (351 行多行装配) → 本函。

**按 id 基值表** (sub_141D2FF80; 条目 {+8 上下文对象 (+16 = 修正聚合子块), +16 修正 id}): HEADER = 修正 def (qword_14332ED90 + 120×id) 名本地化 (def+80 非零 → 名带 "ARG" 参数); desc 键存在检查后格式化 (构键两实参伪码丢失, 待汇编核)。基值行 switch (键 MODIFIER_BASE_VALUE[_PERCENTAGE], 参数 VALUE):

| 档 | 修正 id |
|---|---|
| 白名单 → 基值 100% | 4 STRAT_BOMBING_VISIBILITY / 7 AIR_ACE_GENERATION_CHANCE_FACTOR / 8 AIR_INTERCEPTION_DETECT_FACTOR / 9 AIR_SUPERIORITY_DETECT_FACTOR / 10 STRATEGIC_BOMBER_BOMBING_FACTOR / 11 AIR_SUPERIORITY_EFFICIENCY / 12 AIR_ESCORT_EFFICIENCY / 13 AIR_INTERCEPT_EFFICIENCY / 15 AIR_CAS_EFFICIENCY / 16 AIR_NAV_EFFICIENCY / 79 ATTRITION / 94 OUT_OF_SUPPLY_FACTOR / 97 SUPPLY_CONSUMPTION_FACTOR / 118 STRATEGIC_BOMBER_DEFENCE_FACTOR / 133 ARMY_BONUS_AIR_SUPERIORITY_FACTOR / 134 ENEMY_ARMY_BONUS_AIR_SUPERIORITY_FACTOR / 187 与 188 SPECIAL_FORCES_ATTACK/DEFENCE_FACTOR / 204 CONVOY_RAIDING_EFFICIENCY_FACTOR / 254 PLANNING_SPEED / 260/267/268/367/381/383/452/494/495 (AIR_STRAT_BOMBER_NIGHT_PENALTY / PORT_STRIKE_ATTACK_FACTOR / CARRIER_CAPACITY_PENALTY_REDUCTION / SPECIAL_FORCES_CAP / SPECIAL_FORCES_TRAINING_TIME_FACTOR / SPECIAL_FORCES_OUT_OF_SUPPLY_FACTOR / NAVAL_SUPPLY_CONSUMPTION_FACTOR / ATTRITION_FOR_CONTROLLER / ENEMY_ATTRITION) / 608 PARATROOPERS_SPECIAL_FORCES_CONTRIBUTION_FACTOR |
| define 全局基值 | 32 NAVAL_INVASION_DIVISION_CAP ← BASE_NAVAL_INVASION_DIVISION_CAP (dword_143338310) / 36 CARRIER_SORTIE_EFFICIENCY_FACTOR ← BASE_CARRIER_SORTIE_EFFICIENCY (qword_143337EC8) / 77 ORG_LOSS_WHEN_MOVING ← HOURLY_ORG_MOVEMENT_IMPACT (qword_143332FA0) / 131 DIG_IN_SPEED ← UNIT_DIGIN_SPEED (qword_143337EF0; 随后 131+132 双行) / 135 AIR_CAS_PRESENT_FACTOR ← AIR_SUPPORT_BASE+100% (qword_143331D90+100000) / 230 EXPERIENCE_LOSS_FACTOR (qword_143331370) / 251 LAND_REINFORCE_RATE ← REINFORCE_CHANCE (qword_143332880) / 255 MAX_PLANNING ← PLANNING_MAX (qword_143332648) / 257 MAX_DIG_IN ← UNIT_DIGIN_CAP (qword_143337E30; 随后 257+258 双行) / 259 LAND_NIGHT_ATTACK ← BASE_NIGHT_ATTACK_PENALTY (qword_143331178) / 266 NO_SUPPLY_GRACE ← SUPPLY_GRACE×1e5 升定点 (dword_143331604) / 387 NAVAL_INVASION_PLAN_CAP (dword_143338260, 整数型变体) / 388 NAVAL_INVASION_PREPARATION_DAYS ← NAVAL_INVASION_PREPARE_DAYS (dword_14333819C, 整数型) |
| 字面 0 | 23 NAVAL_STRIKE_TARGETTING_FACTOR / 43 ARMY_SPEED_FACTOR / 270 MISSION_CONVOY_ESCORT_EFFICIENCY |
| default | "MODIFIER_NOT_SUPPORTED" 行 + 断言 :226 |

现值行 = 共享单修正现值格式化器 sub_140559C30 (与 §4.26.15 清单版 sub_14055AB90 同族), 双换行分隔。

未决: desc 键第二段实参 (待汇编核) / 本函所属 GUI 件与槽号。

#### 4.31.102 铁路炮单位视图条目 tooltip (railway_gun_entry.cpp; 1 函 — GUI 回调表挂接, 无代码调用方)

sub_141F66420 (856 行; 锚 :90 断言 "Not supported" B51, 闩 byte_14338CB16): `(entry, 元素 id, out 串构建器)` — entry+48/+52 双 dword id 经 sub_14221F310 解析单位对象 (空或值 16 → 返 0); 分支键 = 元素 id 对 entry 四元素槽:

| 分支 | 槽 | 内容 |
|---|---|---|
| 1 | entry+80 | "CURRENT_STRENGTH" (单位虚槽[35] 串) |
| 2 | entry+112 | 移动状态: 虚槽[23] 返 −1 分三路 (0 = MOVING_TO_FRIEND_TERRITORY / 1 = MOVING_TO_ENEMY_TERRITORY / 其余断言); 时长格式化 "UNIT_VIEW_MOVE_DAYS_HOURS"/"_HOURS" (时 = 定点值四舍五入整后 %24; **取整方向 = 向 +∞**: `100000×(v/100000 + (v>0))`) |
| 3 | entry+120 | "UNIT_EXILED" |
| 4 | entry+96 且单位[590] 旗 | 主 tooltip: "RAILWAY_GUN_CLICK_HEADER" → "HEADER"{名} → (-debug 门 byte_14332EC69) "Debug ID" 行 → CURRENT_STRENGTH → "CURRENT_MANPOWER" → 补给行 RAILWAY_GUN_SUPPLY_DESC_OK/BAD (虚槽[43] 布尔择键) → 条件行 NO_RAILWAYS |
| 兜底 | — | sub_140BFD0B0 取键 localize |

定点渲染互证 (书写规范 7): 比值 = (int)(ratio×100000.0 + 进位旗 − 0.5) 上钳 100000; 全部文案经 sub_142245E60 (§4.19.9 同源)。与 s4_08 铁路炮产线/§4.31.99 railway_gun 位不重叠 (本函 = 单位视图 GUI 展示层)。

未决: GUI 挂接表位置 (语料无数据段引用)。

#### 4.31.103 租借行件运行期 (diplomacylendleaseitems.cpp; 6 函闭环 — 两代行件同构 / mode 三态 / 编辑框回写)

簇清册 (体内 cpp 锚 6/6, 断言全 B51 门, latch 分立 byte_14338CA06..0B):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_141F2CFF0 | 288 | :732 "Not an valid enum" + gamestate.h:1125/1126 | 大行件模式刷新器 |
| sub_141F2B9B0 | 201 | :480 "Invalid enum" | 大行件 SetEntry 装载器 |
| sub_141F2A0E0 | 168 | :684 "Invalid Enum" | 大行件数值编辑框回写器 (七块回调共用) |
| sub_141F2B6B0 | 125 | :1282 "Invalid enum" | 小行件 SetEntry 装载器 |
| sub_141F2DB20 | 103 | :1365 "Not an valid enum" | 小行件描述文本刷新器 |
| sub_141F29B90 | 61 | :620 "Invalid Enum" | 大行件 +7816 块回调 (mode==2 输入框同步; 书原仅「回调」点名, 本批补语义) |

**两代行件同构 (新定案)** — 同一 cpp 内两代租借行件, 字段形态逐位同构:

| 代 | 类 (件名) | 尺寸 | ctor | 行池工厂 |
|---|---|---|---|---|
| 小行件 | CDiplomacyIncomingLendLeaseItem ("diplomacy_incoming_lend_lease_entry") | 1384B | sub_141F253D0 (件名串直证) | sub_141C8CAE0 (外交租借页行池) |
| 大行件 | CDiplomacyLendLeaseItem ("diplomacy_lend_lease_entry") | 9336B | 书已收 | sub_141C8CC60 (装载调 SetEntry) |

语义槽对照: mode 枚举 (0 = number / 1 = percent / 2 = once) 小 +40 / 大 +48; variant 指针 +1368 / +9320; is_fuel u8 +1376 / +9328; 描述文本 +64 同; 大行件独有 = +9312 输入组件 (+128 = 编辑框) / +9329 u16 附加字。

**CDiplomacyLendLeaseItem 零槽运行期语义** (ctor 清零记录无误, 本批补运行期): +48 mode 枚举 / +9104/+9112/+9120 三列文本元素 (模式轮换 SetColor 高亮) / +9144 使能块 (+117 0x10 旗, vtable[128]/vtable[176]) / +9312 输入组件 / +9320 variant / +9328 is_fuel / +9329 u16。

**机制要点**: SetEntry (大件): mode→+48, 数值写入编辑框 (percent → ×100 定点化转串; number/once → 数字格式化或取现行值); gamestate 门后 is_fuel → sub_141F76030, 否则 sub_141F76260(**gs+1312/1316 择一**, variant) — 择一对为两代行件共同消费。模式刷新器: 三态对三列轮换着色 (两静态 CColor 常量, 元素 vtable+240 SetColor); 描述 = `DIPLOMACY_LEND_LEASE_DESC_{NUMBER,PERCENT,ONCE}` (前两态 is_fuel 加 `DAILY_` 前缀变体); mode1/2 尾门 = variant+28 与 gs+1312/1316 择一不等时单参刷新。回写器: 编辑框取文本拼 `%` 解析 → 按模式格式写回; 七块回调全落此族 (+88/+1376/+2664/+9152 传 delta=0, +3952 传 +delta, +5240 传 −delta)。

gs+1312/1316 择一对 = **玩家 tag 双槽定案** (dword[gs+1312] > 0 ? 1312 : 1316 — §4.31.105 第三/四处消费点互证)。未决余: 两静态 CColor RGBA (汇编核) / vtable[6]→vtable[2] 成员链 (§4.30.53)。

#### 4.31.104 卖家库存编辑窗与市场装备行件 (edit_market_stockpile_window.cpp 4 函 + market_equipment_item.cpp 1 函)

簇清册 (体内 cpp 锚 5/5; 符号名直证):

| 函数 | 行数 | 锚行 | 定性 |
|---|---|---|---|
| sub_142053F70 | 324 | :41 | CEditMarketStockpileWindow::SetupDerived (lambda 符号名直证) |
| sub_1420548D0 | 212 | :233/:234 | UpdateDisplayedEquipment(const SMarketEquipmentData&, EPriceLevel) (符号名直证) |
| sub_142053BB0 | 193 | :82/:87 | confirm 按钮 lambda (13859/14010 双命令发射; §4.33 两行已补单变体 ctor) |
| sub_1420534D0 | 35 | :158 | 库存 delta 计算器 (= 100000 × 输入值 − 市场池现量) |
| sub_1420428F0 | 516 | :243 "Price level icon element is not provided." | CMarketEquipmentItem 行数据刷新步 (13 组件槽) |

**SetupDerived 绑定图** (win): +1392 GUI 基根 / +2832 confirm_button (lambda = sub_142053BB0) / +4200 set_to_zero_button / +5568 variant_name / +5576 equipment_archetype / +5584 cic_cost / +5592 cic_icon / +5600 country_stockpile_status_amount / **+5608 _pEquipmentInputWidget (3080B, ctor sub_14206A530)** / **+5616 CPriceLevelsWidget (4216B, ctor sub_14206BCB0, 书互证)** / +5624..+5695 SMarketEquipmentData 72B 拷入 + +5696 has_value / +1440 卖家 tag / +1448 CMarketStockpile*。

**UpdateDisplayedEquipment 全步**: 72B 拷入 → 原型图标/名 → 输入件配置 (步进三元组 {1,10,100}; 上限 = (生产库存 + 市场库存)/100000; **SMarketEquipmentData+24 = 生产库存 (断言串 AmountInProductionStockpile 直证) / +48 = price_level (消费直证)**) → 双 lambda 安装 (输入件+88 / 价级件+4152) → cic 成本串 (sub_1413BCAC0 临时池 + 价级 map 单条写者 sub_1419D40F0) → 刷新。

**confirm lambda**: delta = 计算器式 → >0 入 to_reserve 池 / <0 取负入 to_release → 任一非空 → malloc 176 **sub_141B1BC20 (13859 单变体 ctor)** 投递 (qword_14332F698 虚槽+136 取投递器 → sub_142250B00); 价级现值 ≠ 上次 → malloc 64 **sub_141B1B590 (14010 单变体 ctor)**。

**CMarketEquipmentItem 13 组件槽** (sub_1420428F0; item+33 早退门): +1488 名 / +1496 原型名 (同名置空) / +1504 数值 / +1514 cic 成本 (a2+40, 2 位小数) / +1520/+1552 护航成本双件 (a2+56 门) / +1576 第三门件 (原型+1000) / +1528 第四门件 (variant+1040) / +1544 价级图标 (a2+48 门; 件空 → :243 断言) / +1560 状态件 (a3[1] 三态) / +1584 谓词门件 (**sub_1413B7B90** 48B 记录容器查找) / +1592 尾件。

未决: SMarketEquipmentData+8 指针对象语义 / +1584 谓词门七件定名归属。

#### 4.31.105 租借弹窗行件与战争关系行件 (diplomacypopupitems 5 函 + diplomacyitems 2 函; kind 枚举跨件闭环)

簇清册 (体内 cpp 锚 7/7; latch 按 cpp 行序连续分配 = 单文件交叉证据: byte_14338C706..C70A ↔ 行 213<253<430<474<630):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_141DCA900 | 236 | :213 断言 "Invalid enum" (B51, 闩 byte_14338C706) | PopupLendLeaseRequestItem populate (archetype +8080 侧) |
| sub_141DC8980 | 33 | :253 断言 (a4=1→B52, 闩 byte_14338C707) | kind→施用目标三槽调度器 (两类共用) |
| sub_141DC92D0 | 168 | :430 断言 "Invalid Enum" (B51, 闩 byte_14338C708) | RequestItem 编辑框回写器 (+7920 输入组件) |
| sub_141DCAE50 | 213 | :474 断言 "Not an valid enum" (B51, 闩 byte_14338C709) | RequestItem 三列色轮 + 描述键刷新 |
| sub_141DCA400 | 243 | :630 断言 "Invalid enum" (B51, 闩 byte_14338C70A) | PopupLendLeaseInfoItem populate (variant +80 侧) |
| sub_141C7CA00 | 389 | :1083 断言 "Missing War Relation" (B52, 闩 byte_14338C4A9) | **CDiplomacyCallAllyWarRelationItem::FillTooltip (新归属)** |
| sub_141C7F0F0 | 313 | :1165 同文案 (B52, 闩 byte_14338C4AA) | CDiplomacyJoinAllyWarRelationItem::FillTooltip (书互证 + 精化) |

**kind 枚举 0=number / 1=percent / 2=once 三处一致 (定案)**: info populate 描述键序 (_DESC_NUMBER/_DESC_PERCENT/_DESC_ONCE, 前两态 is_fuel 走 DAILY_ 变体) + request 色轮列序 (+7992/+8000/+8008 三列, 选中 vtable[30] SetColor, 两静态 CColor RGBA 待汇编核) + §4.31.103 行件 mode 同序 — **枚举跨三件共享**。回写器: kind0/1 经转换器写输入组件+128; **kind2 不写 (无编辑路, 不触发断言)**。+8088 getter (sub_141DC8E50): **kind1 (percent) → 值 = v/100 (百分比→定点 1e5)**, 否则原值。kind 调度器: 0→target+136 / 1→+200 / 2→+264 (else 断言返 +136); 两包装消费 = fuel 路常量 sub_141504670 / 装备路 sub_14100CCE0。**gs+1312/1316 择一形态 = dword[gs+1312] > 0 ? 1312 : 1316 (玩家 tag 双槽, 1312 优先) — 本批第三/四处消费点, §4.31.103 未决升级定案**。info 侧布局: variant@+80 (+88 amount / +96 kind / +72 fuel) 书互证; request 侧 +7920 区布局 (输入组件/名/描述/模式描述/库存与第二统计/色轮三列/+8032 显示/+8064 fuel/+8080 arch/+8088 派生量/+8096 kind)。

**战争关系 tooltip 双函** (逐位同构, 差异仅 EH 块): 守门 item+**1304 = CWarRelation\*** (两类布局表已补行) → 战争名 → 取侧 (+344 朝向旗选 relation+16/+20 攻守 tag 对, 取互补另一员) → **sub_140D38F30(mgr, 对侧 tag, &攻方容器, &守方容器) — 隐藏第 4 参 (r9 = 第二出参), 定义处 1 参伪码系反编译器尾调误形 (第三方调用点直证)** → DIPLOMACY_ATTACKERS/DEFENDERS 两段逐国名追加。**出参 = 双串结构**: 战争名经 sub_14011FE60 (std::string move) 入 a3+0 (标题), 列表段经 sub_140129C10 追加至 a3+32 (正文)。CallAlly 归属证据链 = ctor 件名串 "diplomacy_call_ally_war_entry" 直证 + ctor/dtor 地址序 + 断言行序/latch 序 (C4A9 < C4AA) + dump 内仅此两族战争关系行件类。

未决: kind 调度器施用目标类身份 / +32 转换器语义 / 回写器 strtod 返回值无消费者 (疑丢栈存) / 两静态 CColor RGBA / CWarRelation 全布局 / state 库条目日期键换算 (§4.28.30)。

#### 4.31.106 情报台账海军任务图标行 (intel_ledger_map_icons.cpp; 1 函 + 海军规模估计器 — 任务枚举 GFX 表全钉)

簇清册 (体内 cpp 锚 1/1 + 帮手):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_1418E39A0 | 492 | :678 断言 "MissionIcon.IsEmpty() == false" (B52, 闩 byte_14338B2E1) + gamestate.h:1125/1126 | CIntelLedgerMapIcon::CNavalMissionEntry populate |
| sub_14142FBD0 | — | countryintelhelper 族第三成员 | **海军规模估计器** (§4.11.20 原只收陆/空) |

调用方 = sub_1418E41A0 情报台账地图图标刷新 (CCountryIntelLedgerView 单例 qword_14338B4C0 +5456 观察者 tag; sub_140EA5F50 取海任务记录; 条目池 icon+320 重建)。

**条目字段** (64B CNavalMissionEntry 同体): +32 任务类型 / +36 展示模式旗 (1 = 原始计数 / 0 = 情报估计) / +40 count1 总数 / +44 count2 本区域活跃数 / +48 图标件 / +56 文本件。记录字段: +8 CTaskForce* (+496 所在省 → 省+200 区比对) / +20 任务类型 / +48 旗 / +240 FleetRegionRange 块 (谓词 sub_141987CA0, fleetregionrange.cpp 三断言直证)。

**海军任务类型枚举 (GFX 名表直证定案)**: 1 = GFX_mapicon_naval_mission_patrol / 2 = …_strike_force / 3 = …_convoy_raid / 4 = …_convoy_escort / 5 = …_mines_planting / 6 = …_mines_sweeping / 7 = …_training / 9 = GFX_mapicon_naval_invasion_support / 0/8 = 空串 (:678 拦 0)。count2 分型: 1/2/9 = 旗 ∧ 非区范围 ∧ tf 在本区; 3/4/5/6 = 旗 ∧ 在区范围; 7 = ¬旗 ∧ 在本区。文本三态: 原始计数 "N/M" 或单数; 情报形 "?" / "N" / "lo-hi"。

**海军规模估计器** (sub_14142FBD0; §4.11.20 表已补): 满情报捷径同形 (!byte_14332F63A) / 情报比 = 1e5 × intel / 上限 — intel = sub_140D045C0 返回 **+16 navy 象限**, 上限 = qword_1433390B8 **[2]** (陆 [1]/空 [3]/海 [2] 四象限补齐第三件); 区间核 sub_14142EB50 (书已收); 抖动种子 = region_id + 1361 (陆 1140 / 空 1280)。

未决: 海任务记录完整布局与宿主类名 / CFleetRegionRange 全布局 / sub_140EA5F50 其余段。

#### 4.31.107 陆军行件 (armyviewitems.cpp; tooltip 派发 0x141D35400 754 行 + 全量刷新 0x141D3ADB0 355 行)

陆军列表行件 (推定 CArmyViewItem 族 — 无静态调用方 + 无 RTTI/串名锚 = 虚槽派发, 两函 +3936/+3944/+3952 三槽语义互证同类)。单位类型判定: `*(obj+8)` CRef type = **13 铁路炮** (断言 "pUnit->IsRailwayGun()", 闩 byte_14338C681/C680) / **0 师本体** (CArmy)。

行件对象布局 (全新收录):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +16 | CRef {type u32, id u32} | 目标单位引用·甲 (守门 = +16 与 +24 两者皆空才返 0; 仅 +16 解析; +24 关系未决) |
| +40 | CRef {type u32, id u32} | **目标单位引用·乙 (成员实名 `_Unit`, armyviewitems.h:156 断言串直证)**; 解析 = sub_14221F310 → GetPtr −16 = 单位对象 (GetPtr 返 obj+16 内指针), **type 读法 = `*(int*)(GetPtr−8)`**; `if (v3 != 16) return 0` 中 16 = 空指针哨兵 (NULL+16) 非魔数偏移; 排序比较器 0x141D3A210: **师 < 铁路炮** (type ∈ {0,13}, 其他值触发 :156 断言) — 铁路炮组内键 = unit vtable+96 → +312 → +1420 模板 def idx (与 CShipInfoEntry def 来源同字段), 师组内键 = vtable+64 → +952 持针 → +12 比较; 平级仲裁 sub_141D398B0 未析 |
| +3888 | CWindow* | 师数标题按钮 (tooltip = ARMY_DIVISIONS_BUTTON) |
| +3896 | CWindow* | 单位/模板图标按钮 (三态: UNIT_BUTTON_DESC / UNIT_BUTTON_FAKE_ARMY_DESC / ARMY_RAILWAY_GUNS_BUTTON) |
| +3912 | CWindow* | 经验按钮 (tooltip = EXP_TOOLTIP_ARMY + EXP_DAILY_GAIN) |
| +3928 | CWindow* | 师模板图标 |
| +3936 | CWindow* | 军群等级徽章 (设值 = 等级+1; tooltip = ARMY_DIVISIONS_GROUP_LEADER / _NO_LEADER) |
| +3944 | CWindow* | 战斗中兵力图标 (显隐门 = CUnit+436 > 0; tooltip = CURRENT_STRENGTH) |
| +3952 | CWindow* | 组织度图标 (tooltip = CURRENT_ORGANIZATION; 显隐门 = 模板 obsolete 旗 data+542 — 语义反直觉, 待裁) |
| +3960 | CWindow* | 战区图标 (依 COrdersGroup 设; 无军群 → 隐) |
| +3968 | CWindow* | 兵力条 (设值 = 100 × CUnit vtable[35] 有效兵力) |
| +3976 | CWindow* | 组织度条 (设值 = 100 × CArmy+1184 org 比例缓存) |
| +3984 | CWindow* | 远征归属图标 (显隐门 = CUnit+476 expeditionary_owner > 0; 文案 tag@+476, ≤0 回退 tag@+472 owner) |
| +3992 | CWindow* | 起源国图标 (origin_type ∈ {1,2} 显; 文案 = sub_140BA04D0 = data+476 foreign_template_tag, ≤0 回退 data+468 country) |
| +4000 | CWindow* | 起源图标·乙 (origin_type == 1 显; == 2 隐; 两窗业务名未决) |
| +4008 | CWindow* | 起源图标·丙 (origin_type == 2 显; 其他隐) |
| +4016 | CWindow* | 师名文本 (= CUnit vtable[13] GetName) |
| +4024 | CWindow* | 战区组名文本 (= CTheaterGroup+40 名串; 无军群 → THEATRE_GROUP_UNASSIGNED) |
| +4032 | CWindow* | 军群名文本 (= COrdersGroup+352 名串; 无军群 → 清空) |

CWindow 通用控件协议 (本簇双函实证, 亦适用于其他 GUI 簇):

| 偏移/槽 | 类型 | 名称/语义 |
|---|---|---|
| +117 | uint8 位域 | bit4 (0x10) = 隐藏旗 (vtable[128] 置位 / vtable[120] 清位); bit3 (0x08) = 文本已设旗 |
| vtable[15] (+120) | 虚槽 | Show/Enable (清 +117 bit4) |
| vtable[16] (+128) | 虚槽 | Hide/Disable (置 +117 bit4) |
| vtable[19] (+152) | 虚槽 | 设百分比文本 (进度条; 实参 = sub_1424ED730 格式化的 100×比例) |
| vtable[22] (+176) | 虚槽 | 设数值 (徽章/计数) |
| vtable[94] (+752) | 虚槽 | 取内嵌进度条对象 (返回值的 vtable[19] 为设百分比入口) |

tooltip 派发 (0x141D35400): a2 命中某子件槽则把 loc 串写进 a3 (a3+0 主行 / a3+32 次行), 返 1; 全不命中返 0。六槽 = +3888 ARMY_DIVISIONS_BUTTON / +3896 三态 (正常师 TYPE=模板类型名; 假情报师 TYPE=fake 模板名, 取 army+968; 铁路炮) / +3912 EXP_TOOLTIP_ARMY (LEVEL=等级名串 / NUMBER=等级+1 / EXP=等级内进度; 每日增益 > 0 时追加 EXP_DAILY_GAIN) / +3936 军群两键 (ARMY_NAME=军群名 / LEADER=将名 og+136→+64) / +3944 CURRENT_STRENGTH + 次行 STAT_COMMON_MAX_STRENGTH_DESC / +3952 CURRENT_ORGANIZATION + 次行 STAT_COMMON_MAX_ORG_DESC。

**tooltip 细化增补 (0x141D35400 复核批, 与上表零冲突)**: +3896 正常师 tooltip 有**第二行** (a3+32 = sub_140BA0580(template)); CURRENT_ORGANIZATION 主行 = 双值格式化器 sub_140616890 ("CURRENT_ORGANIZATION", "CUR", max(vtable+288 [36]), unk_1427CBDE8, cur(vtable+304 [38])), 次行 = sub_140C81D50(army) 以 "\n" 连接; EXP 四变量条目 = **104B 结构 ×4** {type, key, 值}: LEVEL (type1 串) / NUMBER (**type5** int32) / COMBAT (type1 串, 每日增益) / EXP (**type9** int64, 进度); **EXP_DAILY_GAIN 追加条目 = type10 (i64) — type10 首次观察** (§4.31.108 原仅录 1/5/9 三型; type10 精确语义待裁); LEADER 串 = 军群对象 **+64 直取** (og+136→+64 链的直读短路形)。

**双模板图标 helper 辨析 + 刷新失败支路 (0x141D3ADB0 复核批)**: 铁路炮模板图标助手 = **sub_140B458F0** (6 参, 尾参 −1; 图源 = vtable[12]()+312) 与师用 sub_140B45860 (5 参) 为**两函数**; 模板图标应用失败时收尾前**补隐 +3992/+4000/+3928** (八步表原未载的失败支路); 远征图标 tooltip tag 实参 = **引用传递** (sub_140B44AC0(ctx, win, &tag, 0,0,0), IDA 显示为截断指针值勿按值读)。GameItemDatabase 单例断言精确化 = gameitemdatabase.h:142 "_pInstance && \"Instance not created.\"" (闩 byte_14338ABDD, 单例全局 **qword_14332EF50**)。

刷新流程 (0x141D3ADB0) 八步:

| 步 | 动作 | 门 |
|---|---|---|
| ① | 解 a1+40 CRef → unit (空/解析返 0/返 16 哨兵 → 返 0 不刷新) | — |
| ② | 兵力条 (+3968) = 100 × unit vtable[35]; 师名 (+4016) = unit vtable[13] 名 | 恒 |
| ③ | 战斗图标 (+3944) 显/隐 = `*(unit+436)` > 0 | CUnit+436 |
| ④ | 军群 = sub_141D348C0(unit) (非铁路炮返 unit+192 _pOrdersGroup; 铁路炮经 vtable[12] + obj+1088/+1080 CRef): 有 → 战区图标 (+3960) + 战区组名 (+4024 = 军群+384 CTheaterGroup+40) + 军群名 (+4032 = 军群+352); 无 → 战区图标隐 / 组名 = THEATRE_GROUP_UNASSIGNED / +4032 清空 | GameItemDatabase 单例断言 (闩 byte_14338ABDD) |
| ⑤ | type ≠ 0 (铁路炮) → 模板图标 (+3928) 依军群统计 (vtable[12]()+312 = CArmy+312) 设图; 隐 +3952/+3984/+3992/+4000/+4008/+3936/+3976; 返 1 (铁路炮只显模板图标与军群信息) | type == 13 断言 |
| ⑥ | type == 0 (师): 模板图标 (+3928) = sub_140B45860(gui, win, templateData, 1, 0); 成功 → 显 | templateData ≠ 0 |
| ⑦ | 组织度图标 (+3952) 显/隐 = `*(templateData+542)` obsolete 旗; 远征图标 (+3984) 显/隐 = `*(unit+476)` > 0; 起源三窗 = `*(templateData+480)` origin_type: 1 → 显 +3992/+4000; 2 → 显 +3992/+4008; 其他 → 全隐 | data+542 / unit+476 / data+480 |
| ⑧ | 收尾: 等级徽章 (+3936) = 等级+1; 组织度条 (+3976) = 100 × `*(army+1184)`; 两槽 + 兵力条恒显, 返 1 | 恒 |

等级/经验模型 (本簇实证消费链): 等级 = 经验 (CArmy+1072 fixed×1e-5) ÷ 总人力 (army_manpower 值容器求和, sub_140C69830 八路展开: data@army+992, count@army+1004, 8B 元 {tag_id u32@+0, value u32@+4}) 落入 UNIT_EXP_LEVELS 阈值表档位 (sub_140C7E890); 等级内进度 = 区间线性百分比 (sub_140C77540, 首档 = ratio/th[0], 越界/除零 → 0xFFFFFFFF 哨兵); 每日增益 = EXPERIENCE_COMBAT_FACTOR × (等级 − ARMY_EXP_BASE_LEVEL) (sub_140C7E840); 徽章 = 等级+1 (1-based)。

助手函数 (本簇调用链定案): sub_141D348C0 = CUnit → COrdersGroup 解析 (铁路炮走 vtable[12] + obj+1088/+1080) / sub_140BEFC20 = COrdersGroup::GetTheaterGroup (`*(og+384)`, 断言 ordersgroup.cpp:533, 闩 byte_14333C93D) / sub_14061F7D0 = CTheaterGroup+40 名串 / sub_140C891E0 = CArmy::IsFakeIntelDivision (`*(army+952) ? *(template+564) : 0`, §4.18.13 同字段) / sub_140C7E7C0 = CDivisionTemplateData 指针 (`*(army+952) ? *(army+952)+24 : 0`) / sub_140C00000 = 在战斗中 (`*(unit+436) > 0`) / sub_140BA04D0 = 模板 tag (data+476 > 0 ? data+476 : data+468)。

未决: 行件类实名 / a1+16 与 a1+24 双 CRef 关系 / 组织度图标显门 = obsolete 旗的语义解释 / 起源两窗业务名 / 其余子件槽 tooltip 归属。

#### 4.31.108 MIO 政策窗/详情行件/列表行 tooltip (industrial_org_policy_window + detail_items + list_item; 6 函闭环)

**NIndustrialOrganisation::CPolicyWindow** (类名 lambda 符号直证, 书中全新): 布局 +48 _pWindow (窗名 `industrial_organisation_policy_window`) / +80 close_button 胶 / +1448 policy_list 子窗; Setup = 0x141FB2D00 (断言 :50), 开合编排 0x141FB2CB0。**政策附/卸/换三态弹窗文案构造器 0x141FB14E0**: UNATTACH/SWAP/ATTACH × title/desc 全键表 (变量名 OLDPOLICY/NEWPOLICY/POLICY/INDUSTRIAL_ORG); **成本尾段 = round(policy_def+72 × MODIFIER_MIO_POLICY_COST_FACTOR(622))** (断言 :203); 调用方 0x141FB26D0 = CAttachPolicyToIndustrialOrgCommand {+40/+44/+48} (§4.31.40 互证)。**弹窗/tooltip 变量条目统一 104B 结构** (跨四簇一致): {i32 type@0 (1=串/5=int32/9=int64), cstr 键@8, 值@16}; 拼接前修剪 = sub_1424CB5C0(串, 2) 至多去 2 尾部换行。

**CHistoryItem 三旗细化与 flavor** (0x141FBB5D0 Setup / 0x141FBB9D0 flavor 刷新): 三旗 = +132 过时 (类型2 = org+216 容器 (24B 元, count org+228) 逐元 ptr@+16 → +136 idpair 匹配 +124 未命中; 类型1 = 变体+1060 直读) / +133 加成差分 (变体+1160 挂 MIO → sub_140DB7A10(org,列,原型) 对比 +1168 表; 无 MIO → *(变体+1188)==0) / +134 可负担 (成本 ≤ 军种经验; INDUSTRIAL_ORG_{AIR,NAVY,ARMY}_XP_COST)。flavor: 指派历史 rh 表查找 sub_140DB8C10 返回 **rh 元素+16 记录体** ({+8 CGameDate / +32 has_value / +40 产量} — 与 §4.8.18 载荷读数恰差 16B 元素头, 互证); 断言 :377/:379; 变体 +1052 选 _FLAVOR_DESIGN_DATE vs _FLAVOR_RESEARCH_DATE; 类型2 = …_FLAVOR_UNITS_PRODUCED {NUMBER(type=5)=记录+40}; 文本写 item+1560 (sub_1422CA920 SetText)。**加成图标行 0x141FBBCC0**: 判别字 +76==1 → bool 支 GFX_organization_modifier_icon; ==0 → EBonusType +72: 1=GFX_design_team_icon / 2=GFX_industrial_manufacturer_icon / 其余断言 :185 (§4.31.41 判别式复核通过, 三 GFX 实名落定); icon 子窗 = vtable+136 FindWindow("icon"), SetSprite = 元件 vtable+728 (槽 91 族)。

**COrganisationListItem::BuildTooltip 0x141F21D30 全案** (this = item+104 子对象; tooltip 对象三串槽 {+0 主串/+32 帮助/+64 附加}): ① 任务容量悬停 = INDUSTRIAL_ORG_TASK_CAPACITY_TITLE/DESC {NUM_ASSIGNED=org+228, CAPACITY=max(0, floor(org+168 × 619/1e5))} + 逐元 sub_140DB8210 行 (…_TASK_RESEARCH_DESC {RESEARCH=元+8 对象本地化名}) / 空则 …_NOT_ASSIGNED; 帮助串 = …_TASK_HELP; ② 开详情钮悬停 (item+15992 wrapper, buttonwrapper.h:34 断言) = …_OPEN_DETAILS_WINDOW_TOOLTIP + org+308 trait points>0 再 …_TOOLTIP_DELAYED {NAME, NUMBER}; ③ 体+模式机 = sub_141918810 (org 名起头) + sub_141E8E030(列表窗+248 模式机): case1 = UNASSIGN_DESIGN_TEAM / ASSIGN_TO_RESEARCH 双键 (+32 = 当前选中 org 槽); ④ 模式机==1 时附加串 = "RETURN" 直写。尾段 sub_141F21750 = wrapper 级 (门 byte_14332F63D; wrapper+132 org idpair/+120 列表窗 +288/+296 子件, 模式机==2 走 +296 sub_1415419C0); 色码 18193 = 0x4711 = 0x11+\'G\' 绿标 (与黄标 0x11+\'Y\' 同族)。

#### 4.31.109 MIO 队列保存/删除弹窗 (industrial_org_queue_pop_ups.cpp; 3 函闭环)

CSaveQueuePopUp 布局 (dtor 0x142021770 同址 vtable + OnSetupDerived lambda 修饰名旁证; 定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +1392 | 窗口根* | FindWindow 宿主 (OnSetupDerived sub_142022DC0 四次子件查找的根) |
| +1440 | 内嵌确认弹窗基* | NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow> 本体; +688 = SetConfirmButtonText (sub_140B7D390), title/desc setter = sub_140B7D4A0/sub_140B7D3D0, +648/+656 = 确认钮启用/禁用 (推定) |
| +4104 | 名字编辑框* | 子件 "name"; +128 = 其文本控制子对象 (GetText sub_1422F0160 / SetText sub_1422F27C0 / 刷新 sub_1422F4D80) |
| +4272 | 下拉控件* | 子件 "queue_dropdown" |
| +4280 | 条目列表* | 下拉的 "queue_list" 子元素 |
| +4288 | 文本标签* | 下拉的 "text" 子元素 (当前选中名) |
| +4296 | MSVC 串 (32) | 编辑框名缓冲 (初始化喂源) |
| +4328 | CPersistedMioQueueId (8) | 当前选中保存队列 id; 全 FF (<0) = 无选中 |
| +4336 | COrganisation* | 被保存的组织 (读 org+336/+348 队列容器互证 §4.31; org+56 = MIO org id) |

机制 (定案): **警示/确认文案刷新器 0x142022330** (断言 :42 "Unknown queue ID in save queue popup", 闩 byte_14338CF47): 无选中 → loc INDUSTRIAL_ORG_QUEUE_SAVE_AS; 内容差分 (保存记录 {data@+48, count@+60} 与 org+336/+348 队列逐 16B 元相等取反) ∧ 名匹配 (编辑框文本 == 记录名@+16) → …_OVERWRITE / 差分∧不匹配 → …_RENAME_AND_OVERWRITE / 无差分 → …_RENAME; 尾编辑框非空 → vt+648 启用确认钮 / 空 → vt+656 禁用; 注册表查未中 → 断言后静默返回 (保持旧文案)。**OnQueueSelected 0x142023250** (:147 同款文案, 闩 byte_14338CF48): 写 +4328 → 无选中标签置空; 否则注册表查名 → 编辑框空时自动补名 → 标签 SetText(记录名) → 刷编辑框 → 下拉 +2840 非零时刷下拉 → 尾调 0x142022330 闭环; 回调接线 = CQueueToUnlockWindow::BuildSavedQueueItems lambda (thunk 0x142023AE0) + OnSetupDerived lambda_1 (签名 `(const CPersistedMioQueueId*, const CPersistedMioQueueId&, const CString&)`, 登记点 sub_142021300 下拉重填充)。

CDeleteQueuePopUp 布局 (ctor 0x142020420, 4208B; RTTI vftable 三重直证, 定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | vtable 指针 | CDeleteQueuePopUp 主表 (三重安装之一; ctor 先基后派生重盖) |
| +16 | vtable 指针 | 三重安装之二 |
| +56 | vtable 指针 | 三重安装之三; 基链 = NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow> |
| +1440 | 内嵌确认弹窗基* | 同 CSaveQueuePopUp (三文案 sub_1420227D0) |
| +4096 | 槽 (指针的指针) | 来源条目槽 — ctor 窃取形: 条目+1400 = 1 + 清槽 + *条目 = this 回指 |
| +4104 | CPersistedMioQueueId (8) | 目标队列 id; 高双字 <0 = 「清空组织队列」模式 (跳过注册表查找) |
| +4112 | MSVC 串 (32) | 来源条目显示名 (ctor 第 4 参) |
| +4176 | MSVC 串 (32) {size@4192, cap@4200} | 注册表查得的队列名 |

> 双模式文案 sub_1420227D0: id<0 → INDUSTRIAL_ORG_CLEAR_QUEUE_{TITLE,DESC,CONFIRM}; id≥0 → 按 id 低双字查 MIO 组织 (sub_140300560 单例 → sub_14022F740) 得名 (sub_140A53710), **查无组织 → 以字面串 "INDUSTRIAL_ORG_QUEUE_LOAD_UNKNOWN_MIO" 当 loc 键** (删除/加载弹窗共享文案族证据); 命中 → INDUSTRIAL_ORG_DELETE_QUEUE_TITLE / _DESC (2 变量) / _CONFIRM。创建点 = sub_141FB6050 (CQueueToUnlockWindow 删除钮, malloc 0x1070 → ctor → sub_140B43150 挂弹窗管理器 *(mgr+1272)); **CQueueToUnlockWindow +4408 = 来源条目槽 / +4416 = 当前选中队列 id** (新偏移; 宿主方法实名 CQueueToUnlockWindow::DeleteQueue(CPersistedMioQueueId))。

**保存队列注册表 qword_14333C5F8** (新结构, 定案): 两级 robin-hood — 一级键 = CPersistedMioQueueId 低双字 (= COrganisation+56 org id; 查找器 sub_1419256B0/sub_141925790), 二级键 = 完整 8B id (FNV-1a 0x811C9DC5; sub_141924D60); 两级同 24B 桶形 {u8 占用@+4, u32 键@+8, 值@+16}, 73244475 混淆哈希线性探针; 二级值 = 记录* {+16 名串 32B, +48 16B 元素数组 data, +60 count} (16B 元与 org+336 队列同构)。**CPersistedMioQueueId** (8B id 类型实名) 由三处 lambda 修饰名直证。

> ICF 失真注: 刷新器 16B 元素相等比较助手被折叠到 `FH4::HandlerMap4::iterator::operator==` 符号 = 错命名, 非 EH 语义, 勿据此推断队列元素类型。

#### 4.31.111 生产装备窗取前 N 件填充 (productionequipmentwindow.cpp; 五键稳定排序)

0x141DB9780 (304 行, 签名 (this, Items, Count, gridbox); a1 全程零消费): Items = 引擎指针向量 {data@+0, count@+12}, 条目 +4056 = CEquipmentVariant* (§4.33 同文件族消费端互证)。机制 = 断言 :952 `Count <= Items.GetSize()` → Count 钳位 (超上界取 count, 负取 0) → 建下标数组 0..n−1 (off_143085170 引擎分配器) → **全量稳定排序** (n > 32 走 sub_141DB8B30 归并 — MSVC stable_sort 形: 递归分半, 缓冲 1024B 栈内/超则堆分配, 不足转插入排序; n ≤ 32 内联插入) → 取前 Count 条目逐个 `sub_1402DEC80(gridbox, item, 0)` 入格 → sub_1422C7E50 收尾。

排序比较器五键 (comp(a,b) = a 排前; 定案):

| 序 | 键 | 方向 |
|---|---|---|
| 1 | variant+1062 highlight | 高亮 (1) 在前 |
| 2 | sub_140BDE100(variant) 谓词 (IsTradable 链 A = DLC 门 ∧ type+1366 ∧ variant+1054 is_frame) | 非「frame 变体」在前 |
| 3 | CEquipmentType+976 (u32, getter sub_140C96180) | 升序 |
| 4 | CEquipmentType+964 (i32) | 升序 |
| 5 | 原下标 | 升序 (稳定性 tiebreak) |

> IDA 失真: sub_140BDE100 四参形态 = 寄存器垃圾参, 谓词实为单参; 魔法静态 dword_14332ECF0 = 排序器一次性初始化。

#### 4.31.112 音乐播放器视图首填充 (musicplayerview.cpp; stations_grid 网格布局)

**首填充 = 0x1417D2250** (357 行, OnSetup/首填充): 守卫 sub_1417AD1E0 = 懒建根窗 (+88 已建返 0 不再填充; *(+80) 系统 vt[+96] 建窗, 失败断言 standardinterface.cpp:56 `Failed to create window.` 新闩 byte_14338B11A) → 返 1 仅当本次新建成功。布局: +48 窗模板 / +80 GUI 系统 (GetGuiType 上下文) / +88 根窗 / **+96 = 音乐管理器客户端** (类名表「次(96) vtable」实指; 注册进 unk_14333C610, §4.00.25) / +104 播放控制子结构基 (+112 按钮组 / +5336 窗口持有者, 其 +56 = playlist 窗 / +64 = tracks_grid) / +5472 close_button 回调 sink。GUI 五件套: close_button / stations_grid / default_playlist_window / tracks_grid / default_stations_window (根窗 vt+440 槽[55] 查后激活)。

流程 = 客户端注册 → 播放子结构初始化 → 从管理器 gather 电台名 (CPdxArray<串> 32B 元素, 用后逐串析构) → 逐电台 sub_14225C5A0 校验 **music_station_entry** GUI type (失败 :63 `Missing music_station_entry GUI component containerWindowType with name: %s` 且 quiet=0 时 gui.cpp:931 同发, 跳过该电台) → malloc 184 建 **CStandardMusicStationItem** (ctor sub_141DF9AA0 直证: 主 + 次 vtable 双安装 / +40 CCheckBoxObserverGlue<自> 内嵌观察器 / +48 this 回指 / +56..+119 回调状态 64B (fn sub_141DFA010)) → qword_14333C708 电台名数组线性查命中 → sub_141DFA060 (语义推定 = 隐藏/排除名单, 未决) → 网格放置。

stations_grid 网格件布局 (定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +368 | int | X 方向容量 (≤0 = 不限) |
| +372 | int | Y 方向容量 (≤0 = 不限) |
| +384 | byte | 方向旗: 1 = X 轴快变 (行主序, X 满移行) / 0 = Y 轴快变 (Y 满移列) |
| +392 | 指针 | 已放坐标数组 (8B/项 {x u32, y u32}) |
| +404 | int | 坐标对计数 |
| +416 | 指针 | 已放条目指针数组 |
| +428 | int | 条目计数 (放置去重扫此表) |

> 放置 = sub_1402DE9B0(grid, item, &{x,y}, 1, 去重旗); 尾 sub_1422C7E50(grid) 刷新。

#### 4.31.113 空军增援偏好控制器 (reinforce_preferences_controller.cpp — 簇名 orce_ 系 reinf|orce_ 断片; interfaces/air)

构造器 = 0x142062910 (353 行, 返 this; 定案): 布局 +0 按钮指针数组 {data@+0, cap@+8, count@+12, 分配器@+16 = off_143085170} / +24 分发器对象 (sub_142062170 十四参构造, 回调 = sub_142063080) / +1312 56B 辅助缓冲 / +1368 采纳对象 / +1376 "reinforce_preferences" 子窗口 (sub_1422B8BC0 建窗; containerwindow.cpp:2107 断言 `Asked null object to create a window that does not exist`, latch byte_14348116E) / +1384 宿主引用。机制: 建窗后窗口虚槽 [52] 挂数据源 (推定) + sub_1422C3790 触发刷新 (写窗口+5732 f32 + 尾调窗口 +5616 虚槽 [33]) → **四级按钮抓取循环** = reinforce_1..4 (窗口虚槽 [13] 按名查; 命中 → 按钮入 +0 数组 + 按钮 +8 写级别下标 + 按钮 +128 内嵌观察者订阅控制器分发器; 未命中 → :26 `missing reinforce button for level` 断言 latch byte_14338D02C)。**分发器回调 sub_142063080** = 读 +1368 采纳对象, 取布尔转发其虚槽 [2] (空指针 → sub_14251BAFC 空引用处理)。**a3+56 槽所有权接管** = 自引形态 (槽值 == a3 内嵌对象) 走虚槽 [1] 克隆进 +1312/+1368, 外部形态直接采纳指针; 随后 `*(a3+56) = 0` 清槽 + 自引形态再走虚槽 [4] 释放原体; 函数尾对残值同款释放。

#### 4.31.110 卖家下架确认弹窗 (market_stockpile_window.cpp; 文案侧全案 — 国际市场 seller_view)

窗体 = NInternationalMarket::CCancelSellingContractPopup (RTTI 0x142AAE7E0, §4.31.59 已实名); ctor = 0x14200A7F0 (vftable 符号三重直证 @+0/+16/+56, 基链 = NUI::CScopedPopUp<CDefaultConfirmationPopUpWindow> 与 §4.31.109 同款); 窗名 "default_confirmation_popup" (malloc 32B 串 → 建窗原语 sub_140B789C0)。§4.31.59 业务行 (卖方下架确认 → CMarketStockpileClearCommand 10191 / TransferCommand) 的文案侧上游即本弹窗。ctor 尾序: 装容器 (sub_141FFED60 = 72B 元数组拷贝助手, src = 引擎自定义容器 {data@+0, count@+12}) → 写旗/回调/载荷 → 0x14200C720 初始文案刷新 → `++dword_14338CE68` (弹窗创建全局计数器, 消费端未定位)。

+4096 区段布局 (定案):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +4096 | 引擎自定义容器头 | _Equipments {data@+4096, count@+4108} (元素 = SMarketEquipmentData 72B) |
| +4108 | uint32 | _Equipments count (断言 :88 `_Equipments.GetSize() == 1 && "Someone is using this function incorrectly"` 实名直证) |
| +4120 | byte | 全删旗 (ctor a5): 1 = 删全部合同 (DELETE_ALL 键族), 0 = 删单条 (断言容器恰 1 元) |
| +4128 | std::function (64) | 确认回调 (ctor 自 a6+56 拷构造; vtable 槽间接调用) |
| +4192 | byte | 回调存在旗 (ctor 置 1) |
| +4200 | uint64 | 上下文载荷 (ctor a3 原样存) |

文案刷新器 0x14200C720 (448 行, void(this)): title = 全删 → INTERNATIONAL_MARKET_DELETE_ALL_TITLE / 单删 → **INTERNATIONL_MARKET_DELETE_TARGET_TITLE** (⚠ 引擎 loc 键原文拼错 INTERNATIONL, strcpy 字面直读非 IDA 失真); SetTitle = sub_140B7D4A0 (§4.31.109 同函互证)。desc 段序 (以 '\n' 连接, SetDescription = sub_140B7D3D0):

| 序 | 键/内容 | 变量 |
|---|---|---|
| 1 | 单删 INTERNATIONAL_MARKET_DELETE_TARGET_CONTRACT / 全删 INTERNATIONAL_MARKET_DELETE_ALL_CONTRACTS | 单删 {EQUIPMENT (type=1 串) = 首元变体显示名} |
| 2 | "\n\n" (显式双换行 append) | — |
| 3 | INTERNATIONAL_MARKET_DELETE_DESC | — |
| 4 | '\n' | — |
| 5 | CONFIRMCHANGE_UNIT_TEMPLATE_EQUIPMENT_GAIN_TITLE (**跨域借键** — 单位模板装备窗标题键复用为警告标题段) | — |
| 6 | '\n' | — |
| 7 | 逐装备条目 **INTERNATIONL_MARKET_DELETE_AMOUNT_AND_TYPE** (同款拼错键) + 条目后 '\n' | {AMOUNT (type=5 int32), EQUIPMENT (type=1 串)} (数组序 AMOUNT 先) |

> 变量条目 = 104B 统一结构 (§4.31.108 定案跨域再证, international_market 域同构)。SMarketEquipmentData 元增补: +0 = CEquipmentVariant* (显示名 getter sub_140BDA540) / +16 = fixed×1e-5 上架量 (显示取整 sub_1424ED730)。

#### 4.31.114 舰船改装装备视图与补给信息轴标签 (shiprefitequipmentview.cpp + logisticsinfowindow.cpp; 2 函 — df302 新簇)

**舰船改装装备视图窗口装配 (0x141E1AA30, 226 行, 定案文件归属)** — 候选池截断名 `tequipmentview` 实为 **interfaces\naviesview\shiprefitequipmentview.cpp** (断言 :122 `_pWindow == nullptr && "Window already created."` 闩 byte_14338C871 + 串 "ship_refit_equipment_view"; 类名 CShipRefitEquipmentView 推定, 无 RTTI 锚)。控制器 (QWORD 槽序):

| 偏移 | 语义 |
|---|---|
| +2712 | 上级视图 (其 +1272 = 窗查找提供者 — 与 qword_14332F698+1272 / CCombatItem / CShipInfoEntry ctor 实参同源) |
| +2720 | _pWindow = FindOrCreate("ship_refit_equipment_view", 0) (vtable+96 = 带创建查找) |
| +2728 | outdated_equipment_checkbox (vtable+104; SetNumber(2) 初始帧; 内嵌 +128 控件 vtable+8 BindCallback delegate @this+1296) |
| +2736 | description 子窗 (vtable+120) |
| +2744 | no_matches 子窗 |
| +2752 | equipments 列表窗 (窗 vtable+440 = 列表查找槽) |
| +2760 | equipments_grid (equipments 的 vtable+432 子查找) |
| +2768 | 网格子控制器 (sub_141E19940 构造 → sub_141F729C0 收尾) |

close 钮 (vtable+104) 内嵌 +128 控件 BindCallback (delegate @this+8); 窗内嵌 +48 对象 vtable+552 注册数据提供者。

> **双类槽位辨析 (本簇 + countryarmyview/divisionequipmentview 综合, GUI 树通用)**: (a) **容器/窗口树管理类** — 命名查找槽 vtable+96 (FindOrCreate) / +104 / +120 / +136 / +432 / +440 / +552, 签名 (this, 串, bool); (b) **叶控件类** (§4.31.107 CWindow 协议) — +117 显隐旗位 / vtable+120 Show / +128 Hide / +176 SetNumber / 内嵌 +128 子控件 (其 vtable+8 = BindCallback)。两者 vtable 槽号偶有重合 (+120/+128) 但签名不同, 勿混读。

**补给信息折线图轴标签刷新 (0x141D92450, 165 行, logisticsinfowindow.cpp:387 "Not Supported!" 断言 闩 byte_14338C6EC; 类名待裁)**: **+2576 = 图表模式枚举 0=DAYS / 1=MONTHS / 2=YEARS** (loc 键 LINECHART_DETAILS_DAYS/_MONTHS/_YEARS); +2616 宿主窗。流程 = sub_141517520(a2+8, mode) + sub_140CFE190 (推定折线数据重算) → FindWindow("min_value"/"max_value") SetText (格式化器 sub_1424CA600, 实参 IDA 丢失) → FindWindow("x_axis_type") SetText(localize(LINECHART_DETAILS_*))。子窗实名 min_value / max_value / x_axis_type 新增。

#### 4.31.115 游戏内时钟窗口与循环历史图表 (ingameclock.cpp + loophistory.cpp; 3 函 — df305 新簇)

**游戏内时钟窗口创建 (0x1417B0980, ingameclock.cpp:74, 121 行, 定案; 类名 CIngameClock 推定)**: 前置 sub_141236970(a1+40); 断言 :74 "_pWindow == nullptr && \"Window already created.\"" (闩 byte_14338B11B)。窗口工厂 = a1+96 管理器 → **+1272 子对象 → vtable[12]** (模板 = a1+64, 0) 创建, 句柄存 a1+104。三次具名子件解析: **"peace_conference_offset" → a1+112** / **"minimap_offset" → a1+120** (vtable[24] = FindChild(name, 1) 语义) / **"time_text" → a1+128** (vtable[15] 变体; 栈串 0x7865745F656D6974 直证; = 日期/速度显示载体, 推定)。a1+136 = 窗口 vtable[31] 返回对象解引用 (推定日期文本附加件); 尾 (窗口+48) vtable[33] (推定注册进父容器)。⚠ GUI 窗口槽契约 [12]/[15]/[24]/[31]/[33] 为本函单点证据, 与 §4.31.114 双类槽位辨析的「容器树管理类 Find 槽族」互证待更多簇归并。

循环历史总览图 (loophistory.cpp 两函, 定案):
- **图表显示刷新 (sub_1415170E0, 99 行, :56)**: `sub_1415170E0(a1 图表数据, a2 环形容器, a3 char)` — ⚠ IDA 签名丢第三参 (三调用点全传 3 参, 定案级失真)。图表数据: +0 输出数组 (8B/点) / +12 点数 (先全清零) / +24 配置对象 {类型 int@+48 ∈ {0,1}, 点数@+52}。环形容器: +8 快照指针环形数组 / +32 容量 (取模) / +36 head 下标 / +40 u8 已回卷旗。类型 0 → 委派 sub_141517260 (同族变体); 类型 1 → 从 head 往回扫, 跳过全非正快照, 遇首个含正快照把元素顺序拷入输出 (至点数); 其他 → :56 "Something went wrong, unknow type, please investigate!" (原文 unknow 拼写保留, 闩 byte_14338A82C)。
- **每拍记录步 (sub_1415173C0, 同文件, 定案)**: head+1 → 达容量回卷 (head=0, +40 旗置 1) → 当前槽存容器+48 → 按「已回卷 ∧ head≠0」以 a3=1/0 刷新两个图表 (a1[2]/a1[3] 槽; a1 顶层 = 循环历史管理器持 ≥3 槽)。
- **存档 reader (sub_1415176C0, 146 行, 高置信; vtable 槽号待裁)**: token 分发 — 240 = 图表数据块 (sub_141517070 复位 → 读数组 → **维度校验 count == (+52)×(+32) 列×行**, 不符 → :396 "Backward compatibility Warning: found old data syntax - looped history overview graphs will not be loaded from this save-game." **旧档语法整体弃载不崩**) / 314 = 当前图下标 (+36 → +48 指针解析) / 12337 = 尺寸 (+32 → sub_141517A60 重建) / 12338 = +40 值 / 13825 = 版本门 (流+192 == 3 消费兼容块, 推定旧档可选块) / default = sub_1424BEC40 跳过。缓冲释放走 off_143085170 槽[2]。

#### 4.31.116 装备模块选择窗与特殊项目可用项目视图 (equipmentmoduleselectorwindow.cpp 4 函 + program_available_projects_view.cpp 1 函 + equipment_upgrade_view.cpp 1 函 — df304 新簇; 三截断名定案)

**截断名甄别 (定案)**: 候选池 `odule/ule/eselectorwindow` 三者 VA 重叠 (0x141DDBAF0/0x141DDC040) 确系同族, 合并为 **interfaces\designer\equipmentmoduleselectorwindow.cpp** (4 函同窗口族, 7 处断言路径串直证); `ailable_projects_view` = **special_projects\ui\program_available_projects_view.cpp**, 类名 **CProgramAvailableProjectsView** (lambda 符号直证, 命名空间 Ui::Project); upgrade_view 实为 **equipment_upgrade_view.cpp** (设计器目录)。

**装备模块选择窗口状态机 (舰船设计器, 本地化键 SHIP_DESIGNER_MODULE_SELECTION 直证, 定案)**: 类别名推定 CE(quipment)ModuleSelectorWindow (无 RTTI 直证待裁)。状态对象: +72 回调 functor (vfunc+16 触发) / +80 当前类别 int (−1 = 未选) / +96 选择恢复回调目标 / +120 槽指针 / +128 builder 指针 / +1424 窗元件 / +1432 列表 / +1448 标题 / +1456 模块容器 / +1544 列表填充上下文; **子处理器实参为包装对象, 状态在其 +8**。builder (+128) 侧: **+4976 模块集容器 / +5992 槽→当前模块映射** (sub_140BDA480 按键查找两容器复用)。状态机 = 类别点选 (sub_141DDBF80, :291 "Invalid categoty selected..." **原文拼写 categoty 好锚**; 类别数组 data@+96 / 计数@+108 引擎容器形制, 元素 32B 首 dword = id) → 列表重建 (sub_141DDBAF0, 217 行: 按槽筛模块 → 标题写 SHIP_DESIGNER_MODULE_SELECTION → 当前模块高亮 → 提交; 断言 :174 "The slot is supposed to be set at that time" / :179 "Builder must be set") → 确认 (sub_141DDC040: 回调(槽, &模块); sub_1406225F0 全局真则只 sub_14152E8B0(模块) 替代动作, 语义待裁) 或取消 (sub_141DDC1B0: **回调(槽, null 模块)**); 收尾 = §4.35.37 GUI 脏化三连。

**CProgramAvailableProjectsView::Setup (0x141EEB140, 202 行, 定案)**: 断言 :273 "Setup has been called twice" (a1+8 _pContainerWindow 门); GUI 树五件套 = 根 → "projects" → "available_projects" (+8) → "available_projects_list" (+16) → 条目模板 "project_entries" (+56) + **"show_unavailable_button"** 处理器 (+72, std::function 捕 self); 后置填充 sub_141EEB7E0 + 容器脏化三连。数据源侧未析 (sub_141EEB7E0 未展开)。

**升级视图刷新 (0x141DDFEC0, 201 行, equipment_upgrade_view.cpp, 定案/语义待裁)**: 门 = qword_14332F6A0 (idler 双槽) 非空 (:305 "Expected idler") ∧ _pUpgrade = *(a1+16) 非空 (:310 "Expected _pUpgrade to be set")。流程: upgrade+24 取名写元件 +2832 → **byte+24 == byte+25 分支**组装第二文案 (+2824; 相等 = 定串, 不等 = 格式化串推定带数量) → 元件 +2816 双态对: byte+24 非零走 vfunc+648、零走 +656 (推定 enable/disable) → idler vfunc+160 取值 → v17 = sub_141537940(upgrade, v16, 0) (推定按库存算可升级数) → 元件 +2808: byte+24 ≥ v17 走 +656 否则 +648。+24/+25 与 v17 业务含义待裁 (需 upgrade 对象侧另批)。**idler vfunc+160 (槽 [20]) = 两 UI 族 (模块选择器 qword_14332F698 / 升级视图 qword_14332F6A0) 共同数据源, 书内首录**。

#### 4.31.117 生涯档案奖章绶带展示与顾问引用块解析 (career_profile_award_display.cpp 1 函 + advisor_ref.cpp 1 函 — df303 新簇)

**生涯档案奖章/绶带槽刷新 (sub_141FA8390, career_profile_award_display.cpp:117/:118, 176 行, 定案; 类名推定 CCareerProfileAwardDisplay)**: 前置断言 `_PlayerSettings._MedalDisplay.size() <= ...` (奖章槽需求 **6 槽**) / `_RibbonDisplay.size() <= ...` (**绶带 2 槽**) (闩 byte_14338CD22/23)。条目布局: +8 生涯数据 ctx / +16 _PlayerSettings (+8 u32 目标 id / **+12..+35 奖章 id ×6 / +36..+43 绶带 id ×2**) / +24 显示模式 / +160 奖章槽 GUI 列表 ({items@+416, count@+428} 同形第三证) / +1544 绶带槽列表。**显示门 sub_140A31CB0(目标 id, 模式)**: 模式 1 → id≠0 才显示 / 模式 2 → id==1 / 其它不显示; 不显示 → 槽 id 置 **token 19479 "undefined"** 空位哨兵 (书内第四/五处复用)。**DB 单例: 奖章 qword_14332EE30 / 绶带 qword_14332EE48** (gameitemdatabase.h:142 _pInstance 断言族, 闩 byte_14332FC94/95); 键转换 sub_1424BC260(id) → sub_1406AB530 / sub_1406AFD30 查项。填槽栈构 **NCareerProfile::SCareerProfileMedalData / SCareerProfileRibbonData** (vtable 符号直证真类名) {vtable, id, settings 值副本} → sub_14201B600/B6F0。

**advisor 引用块解析器 (sub_141A9B220, advisor_ref.cpp:69, 228 行, 定案)**: 解析 `{slot = <槽名>, character = <CRef>}` 块 → 按槽名取该角色的顾问。块门 = a2+192 ≠ 3 → 抛 "Expected start of block" (token 类 3 = 块开始); 结果初值 = **CRef 哨兵 qword_14333D528 拷贝**; 块键 **13378 "slot"** (sub_140612C40; 槽名结构 = 32B 串 + 缓存 int −1) / **19478 "character"** (sub_14221F970 解析 idpair; **延迟门** = a2+296 上下文 +8/+9 双旗全置 → 不落结果保持哨兵延迟解析, 业务含义待裁); '@' 具名值 → sub_1424C04A0 解析 {i32, u8, string} 三件组 (解析器通用机制)。解析链 = 非哨兵 → **sub_14221F310 CRef 全局注册表解析 → sub_140F9F6D0(角色, &槽名) → *a3 = 顾问槽内容**; 失败臂 = idpair 非空但 F310 返 0 → :69 断言 (串字面 `CharacterRef.IsNull() && "Character associated to this ref is likelly not constructed yet"` — "likelly" 原文拼写照录; **极性存疑待裁**, 疑 IDA 丢 `!`); **空引用臂 = 不写 *a3 静默返回 (调用方须预初始化出参)**。
