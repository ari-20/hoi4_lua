

### 4.17 通知与警报系统族 (NNotification 命名空间 + CAlertManager)

> 族 = `NNotification` 命名空间下**恰 6 个类** (RTTI 全量枚举: 类型描述符直扫 + 基类反查 +
> 独立重建 COL→CHD→TD 链, 三法同解)。命名空间内另有匿名命名空间 `NNotification::?A0x7797ffe3`
> (容器件所在; 其布局 = GUI 行件, 见 §4.31.92)。头文件 `source/interfaces/notifications/notification.h`, 实现
> `notification_handler.cpp`; GUI 定义 `interface/notifications/notification.gui`
> (含 `notification_center` / `notification_entry` 两容器窗)。
>
> **全族零存档面 (定案)**: 6 类基链无 `CPersistent` 任一层 (CHD 直读; 且 6 张主虚表全部
> 不匹配 CPersistent 家族指纹 [1] = 0x1424BEC50 & [3] = 0x1424BE690); `ref/serfam_1193.txt`
> 内 `notification` 零命中; 运行时全量内存导出 (129 MB) 内 `notification` / `notif` / `alert` /
> `popup` / `toast` 全部零命中 (对照 `idea|focus` 14,830 命中)。⇒ 通知是**纯会话内瞬态 UI 状态**,
> 读档/换会话即清空; handler 生命周期 = `CInGameInterfaceHandler` 生命周期。

#### 4.17.1 通知族类清单

| 类 (RTTI 实名) | sizeof | 主虚表 | 次虚表 (mdisp) | ctor | 基类链 |
|---|---|---|---|---|---|
| NNotification::CNotification | 1440 | 0x142A4B708 | 0x142A4B758 (+40) | sub_141BBE880 | CReloadableInterface → CReloadDispatcher; CTooltipHandler (+40) |
| NNotification::CNotificationHandler | 96 | 0x1429B59A8 | 0x1429B59E0 (+16) | sub_1413911A0 | CUpdateable; CReloadableInterface (+16) → CReloadDispatcher (+16) |
| NNotification::CNotificationContainer | 80 | 0x1429B5A08 | 0x1429B5A78 (+56) | sub_1422A9260 (CStandardlistboxItem ctor) | CStandardlistboxItem → COption → COptionObservable → CObservable; TListboxItem (+56) — **GUI 行件, 布局见 §4.31.92** |
| NNotification::CExternallyCompletedFocusNotification | 1496 | 0x1429B4378 | 0x1429B43C8 (+40) | sub_141377A40 | CNotification → … |
| NNotification::CIdeaExpiredNotification | 1448 | 0x142A1BCB0 | 0x142A1BD00 (+40) | sub_14192F2E0 | CNotification → … |
| NNotification::CLegacyMessagePopUpNotification | 1616 | 0x142A02EA0 | 0x142A02EF0 (+40) | sub_1417C91D0 (三参) / sub_1417C9380 (六参) | CNotification → … |

> sizeof 证据 = 分配点 malloc 实参直读 (定案): 类 4 = `malloc(0x5D8)` (调用点 sub_1402CF380) /
> 类 5 = `malloc(0x5A8)` (sub_140BA8300) / 类 6 = `malloc(0x650)` (9 处调用点零例外) /
> 类 2 = `malloc(0x60)` (sub_140B614C0) / 类 3 = `malloc(0x50)` (sub_141391400)。
> 类 1 无独立分配点 (纯基类), 尺寸由字段上界定 = 1440 — 三派生类字段一律自 +1440 起 (互证)。

#### 4.17.2 CNotification (基类, 1440B)

ctor = `sub_141BBE880(this, &window_name)`; 三具体类均先调本 ctor 再写自有域。

| 偏移 | 类型 | 名称/语义 | 写门/证据 |
|---|---|---|---|
| +8 | 匿名结构 (32B, std::string 形) | 窗口名串 | sub_142255FA0 从 .gui 描述子解析写入 |
| +40 | CTooltipHandler vt | tooltip 面虚表 (2 槽) | ctor |
| +48 | 匿名结构 (32B, std::string 形) | 通知窗口名串 (调用方传入, 如 `message_popup_window`) | ctor 从 a2 拷入 |
| +80 | CClass* | tooltip 目标元素 | sub_141BBEF90: `sub_1422B8BC0(root, 名+"_instance")`; 高置信 |
| +88 | CClass* | tooltip 根窗元素 | sub_141BBEF90 直写 a2; 高置信 |
| +96 | CButtonEventDispatcher + 回调束 (1288B) | 束头 = CButtonEventDispatcher 子对象 (dtor 回写其 vftable); 束内 **12 个 GUI 事件回调槽** (安装器 sub_141BBE0A0, 逐槽 `CLegacyButtonObserverGlue<CNotification>` + sub_1402A69E0 挂 std::function); 基 ctor 仅装 2 个非空 (sub_1402A08F0 / sub_141BBF120, 二者均操作 +1432 过期旗), 余 10 空; 束跨度 = +96 → +1384 = 1288B | 结构/尺寸定案; 逐槽元素名待裁 (需 .gui 侧 `notification_entry` 元素名对齐) |
| +1384 | CGameDate 内嵌 24B | **创建时刻** {vt@1384, hours@1392, 视图 vt@1400} | ctor: +1392 = `*(gs+1128)` 当前小时 |
| +1408 | CGameDate 内嵌 24B | **超时基线** {vt@1408, hours@1416, 视图 vt@1424} | ctor: +1416 = 43808760 (CGameDate ctor 哨兵 "1.1.1.1") |
| +1432 | u8 | **已过期/待移除旗** (置 1 → 下一帧自毁) | sub_1402A08F0 置 1; sub_141BBF1B0 收尾判 |
| +1436 | int32 | **超时天数** (ctor 初值 −1; 0 触发 notification.h:39 断言) | setter sub_141378090 (断言门 `Days > 0`); 默认值源 = define `INFO_MESSAGE_TIMEOUT_DAYS` (sub_14083FD20 读, 兜底 1) |

**CNotification 主虚表 9 槽** (0x142A4B708):

| 槽 | 地址 | 语义 |
|---|---|---|
| [0] | 0x141BBED30 | 完整 dtor (拆 glue → CGregorianDate → 串 → CButtonEventDispatcher → CTooltipHandler → 基) |
| [1] | 0x14011D220 | ret 0 |
| [2] | 0x141BBF140 | Reload (CReloadableInterface 面覆写; 重建 tooltip 面 + 自调 vt[5]) |
| [3] | 0x14012A2C0 | CFG 空桩 |
| [4] | 0x14012A2C0 | CFG 空桩 |
| [5] | 0x14012A2C0 | CFG 空桩 (派生覆写 = Populate) |
| [6] | 0x14012A2C0 | CFG 空桩 |
| [7] | 0x14012A2C0 | CFG 空桩 (派生覆写 = Tooltip/正文拼装) |
| [8] | 0x14011D220 | ret 0 (派生覆写 = 点击动作) |

**派生类覆写的业务槽 [5]/[7]/[8]** (基类全为 CFG 空桩 ⇒ 每类必覆写):

| 槽 | 语义 | CExternallyCompletedFocus | CIdeaExpired | CLegacyMessagePopUp |
|---|---|---|---|---|
| [5] | Populate (灌窗口元素) | 0x141378150 (`FOCUS_MESSAGE_UNLOCKED_TITLE` / `FOCUS_SIDE_MESSAGE_UNLOCKED_DESC` / `ORIGINATOR` / `FOCUS` / `originator`) | 0x14192F850 (`IDEA_EXPIRED_DESC` / `IDEA` / `owner` / `"messag"`) | 0x1417C9850 (`title` / `"messag"` / `sender_flag` / `receiver_flag` / `diplo_war_large_icon[2]`) |
| [7] | Tooltip/正文拼装 | 0x141377C40 (`FOCUS_SIDE_MESSAGE_UNLOCKED_TOOLTIP` / `FOCUS_SIDE_MESSAGE_CLICK_ACTION` / `REWARD` / `ORIGINATOR`) | 0x14192F430 (`IDEA_EXPIRED_TT` / `IDEA` / `EFFECTS`) | 0x1417C9730 (追加换行, 门 = +1600 非空) |
| [8] | 点击动作 | 0x141378120 → `sub_140B68FB0(iface, *(this+1440))` | 0x14011D220 (ret 0) | 0x1417C97D0 → `*(this+1576)` 对象 vt[2] |

> 三具体类的 [5]/[7] 各持独立 loc key 族 ⇒ 通知文案**完全数据驱动**, 引擎侧无硬编码文本。

**回调签名族 (RTTI 实证 5 族)**: `void (CNotification::*)(void)` / `(CGuiObject*)` /
`(CGuiObject*, int)` / `(CGuiObject*, CVector<int>)` / `(int)` — 5 个 `std::_Binder` 类型描述符实名。

#### 4.17.3 CNotificationHandler (全局单例, 96B)

ctor = `sub_1413911A0`; 由 `CInGameInterfaceHandler` ctor `sub_140B614C0` 内 `malloc(0x60)` +
存入 **iface+1240**。全局定位链: `CInGameIdler + 1720 = iface` (ctor sub_140DC1B30 内
`*(a1+1720) = sub_140B614C0(...)`) → iface 主虚槽 **[23] (vt+184) = 取回 iface 自身** →
`+1240` 取 handler。

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +16 | CReloadableInterface vt | 次虚表 (5 槽) | ctor `*(a1+16) = vftable` |
| +40 | CClass* | **`notification_center` 窗** (GUI 顶层容器) | sub_1413916B0: `vt+96(guimgr, "notification_center")` → `a1[5]` |
| +48 | CClass* | **`notification_list`** (OverlappingElementsBox, 通知条目列表) | sub_1413916B0: `sub_1422BCBA0(a1[5], "notification_list", 1)` → `a1[6]` |
| +56 | int32 对 | GUI positionType **`maximum_offset`** {x@56, y@60} | 来源定案 (`sub_1422BD000(...,"maximum_offset",1)+240` → `a1[7]`); 轴角色待裁 |
| +64 | int32 对 | GUI positionType **`maximum_size`** {x@64, y@68} | 来源定案 (同上 `"maximum_size"` → `a1[8]`); 轴角色待裁 |
| +72 | u8 | **本帧有条目被摘除门** (Update 收集到 `*(条目+72)+1432 == 1` 的通知 → 从列表 `vt[82](+656)` 摘除 → 置 1 → 触发布局重算) | 触发条件定案; 清除点推定 (每帧开头不清, 残留到下次置位) |

**主虚表 6 槽 (0x1429B59A8)**: [0] 0x141391390 dtor (回写 CUpdateable vftable; 调
`*(Block[8] vt+664)` 释窗; sub_1422560A0(Block+2)) / [1] 0x141391B30 **Update** (CUpdateable[1] 覆写) /
[2] 0x1413916B0 **Reload** (重建 notification_center/notification_list + 重挂既有条目) /
[3] 0x14012A2C0 CFG / [4] 0x14011D220 ret 0 / [5] 0x14012A2C0 CFG。

**次虚表 5 槽 (0x1429B59E0)**: [0] 0x1413912E8 (thunk → 0x141391390, this−16) / [1] ret0 /
[2] 0x1413916B0 Reload / [3] CFG / [4] 0x14011D220。

> ⚠ 本类为 **CUpdateable + CReloadableInterface 多继承宿主**: CUpdateable 的 [2] 位被
> CReloadableInterface 的 Reload 占据 (MI 重排), 与单继承宿主的槽序不同 — 读槽须按 MI 处理。

**帧驱动链**: `CInGameInterfaceHandler` 每帧更新 sub_140B67570 →
`(*(*(iface+1240)+8))(iface+1240)` = handler vt[1] Update → 紧接 `sub_141391660(iface+1240)`
对 notification_center 与 notification_list 各调 vt+128 并置 +165 / +117 的 0x10 位
(与 container dtor / Reload 同款形态, 语义待裁)。

#### 4.17.4 三具体通知类字段表

**CExternallyCompletedFocusNotification** (1496B; ctor `sub_141377A40(this, focus, &name_str, originator)`;
窗名 `externally_completed_focus_notification_window`):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +1440 | CClass* | **焦点对象** (ctor a2) | ctor 直存 |
| +1448 | 匿名结构 (32B, std::string 形) | **焦点名串** (从 a3 移动构造) | ctor OWORD 双拷 + 清源 |
| +1480 | u64 | 0 (ctor 显式清零, 无消费点 — 未决) | ctor |
| +1488 | u64 | **originator** (ctor a4 = `sub_140BB48F0(tag)` 结果) | 调用点 sub_1402CF380 |

> **推送点 (唯一)**: `sub_1402CF380` (焦点完成事件处理) → `sub_141391400(iface+1240, obj)`。
> 门: 目标国 ∈ {gs+1312 当前国 / gs+1316 观察国} (`sub_140BB52F0` 同原初国容错) 且
> `iface vt+184` (玩家国 tag) 有效 且 `byte_14332F639 == 0` (非 AI 托管) 且
> `byte_14332F62C == 0` 且 `*a4 == 1` (通知类型枚举 = 1)。

**CIdeaExpiredNotification** (1448B; ctor `sub_14192F2E0(this, idea)`;
窗名 `idea_expired_notification_window`):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +1440 | CClass* | **理念对象** (ctor a2) | ctor 直存 |

> **推送点 (唯一)**: `sub_140BA8300` (politics daily update, 断言串 `politics.cpp` +
> `"politics.daily"`) → `malloc(0x5A8)` → `sub_14192F2E0` → `sub_141391400(*(v54+1240), obj)`。
> 同段紧邻 `*(v54+1204)` = 接口处理器 +1192 历史容器的 count (与 §4.32 `add_raid_history_entry`
> 同款 216B 记录, tag=12)。

**CLegacyMessagePopUpNotification** (1616B; 两个 ctor: `sub_1417C91D0(this, &title, &body)`
三参全串版被 4 处调用; `sub_1417C9380(this, &title, &body, &sender_tag, &receiver_tag, flag)`
六参版被 9 处调用; 窗名 `message_popup_window`):

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +1440 | 匿名结构 (32B, std::string 形) | **标题串** (loc key, 如 `NOTIFICATION_OUR_GENERAL_SICK`) | ctor |
| +1472 | 匿名结构 (32B, std::string 形) | **正文串** (loc key, 如 `NOTIFICATION_OUR_GENERAL_SICK_DESC`) | ctor |
| +1504 | int32 | **发送方 tag** (consumed `sub_140B44AC0(..., a1+1504, ...)` 挂 `sender_flag`) | ctor 六参版 |
| +1508 | int32 | **接收方 tag** (`receiver_flag`) | ctor 六参版 |
| +1512 | u8 | **图标变体旗** (`diplo_war_large_icon` vs `diplo_war_large_icon2`) | ctor 六参版 a6 |
| +1520 | 内嵌对象 (56B) | 引用/观察者对象 (析构 = `*(+56)` 对象 vt[4](.., flag)) | ctor unwind 链; 类名待裁 |
| +1576 | CClass* | **点击动作对象** (vt[2] 被调) | sub_1417C97D0 |
| +1584 | 匿名结构 (32B, std::string 形) | 附加串 (ctor 置空) | ctor |

**CLegacyMessagePopUpNotification 推送点** (13 处, 全部经 `sub_141391400(handler, obj)`):

| 调用函数 | 业务域 (loc key 指纹) |
|---|---|
| sub_141148AF0 | 远征军请求被拒 `DIPLOMACY_REQUEST_EXPEDITIONARY_REJECTED[_INFO]` |
| sub_141159F90 | 远征军请求被接受 `DIPLOMACY_REQUEST_EXPEDITIONARY_ACCEPTED[_INFO]` |
| sub_140C23DE0 | 将领获释 `NOTIFICATION_OUR_GENERAL_RELEASED[_DESC]` |
| sub_140C23450 | 将领被俘 `NOTIFICATION_OUR_GENERAL_CAPTURED[_DESC]` / `NOTIFICATION_WE_CAPTURED_GENERAL[_DESC]` / `alert_commander_captured` |
| sub_140CAB520 | 海军封锁贸易线 `NAVAL_BLOCKADE_TRADE_ROUTE_{TITLE,INFO}` / `..._REESTABLISHED_*` |
| sub_1413F71D0 | 敌方密码被破 `CRYPTO_ENEMY_CRYPTO_IS_BROKEN_TITLE` |
| sub_1413F6A00 | 同上 (第二路) |
| sub_140F30200 | 通用消息泵 (见 §4.17.6) |
| sub_140C24120 | 将领伤病 `NOTIFICATION_OUR_GENERAL_SICK/WOUNDED[_DESC]` |
| sub_140FE3AA0 | 特殊项目被夺 `SPECIAL_PROJECT_CAPTURED_TITLE/MESSAGE` |
| sub_141A34910 | 学说奖励解锁 `NOTIFICATION_REWARD_UNLOCKED` (断言 `doctrine_ui_utils.cpp`) |
| sub_140BABD00 | 理念失效替换 `POLITICS_INVALID_IDEA_REMOVED/REPLACED` |
| sub_140D93260 | 宗主国下建阵营 `FACTION_CREATED_UNDER_MASTER_{TITLE,MESSAGE}` |

#### 4.17.5 派发三层结构

| 层 | 动作 | 证据 |
|---|---|---|
| ① 业务侧 | 构造具体派生对象 (malloc + ctor) — 焦点完成 1 处 / 理念过期 1 处 / 弹窗 13 处 | 各推送点 |
| ② 入队 | `sub_141391400(handler, obj)` — **全族唯一入队入口** (14 个不同调用函数); 建 CNotificationContainer (malloc 0x50) 包 obj 挂 `notification_entry`, `_RTDynamicCast` 校验宿主为 CContainerWindow, `notification_list.vt[81](+648)` 插入列表; 置 handler+72 = 1 | 二进制文件 |
| ③ 帧驱动 | handler vt[1] Update (sub_141391B30): 遍历 notification_list 全部条目 → 逐条判 `*(item+72)+1432` (过期旗) → 未过期者收集 → 逐条 `notification_list.vt[82](+656)(item, 0)` 重排 → `+72` 门 → 按 maximum_offset / maximum_size 钳制重算列表位置写 list+136 | 二进制文件 |
| ④ 自毁 | CNotification 自身超时计时 `sub_141BBF1B0`: 进度条 `timeout_progressbar` + `+1436`(天) × 24 vs 当前小时 − +1392 比较 → 达阈置 +1432 = 1 → 下一帧自毁 | 二进制文件 |

> **无 `Add` / `Queue` 命名函数** — 入队原语即 `sub_141391400` (未具名, 证据 = 14 处唯一调用形态);
> 「加通知」= 业务侧 new 派生对象 + 调本函数, 无集中 `CNotificationHandler::Add` API。

#### 4.17.6 通用消息泵 sub_140F30200

`sub_140F30190(out, iface, &title, &body, &sender_tag, &receiver_tag, flag)` = 载荷打包器
(64B 结构: 标题串@+0 / 正文串@+32 / 发送方 tag@+64 / 接收方 tag@+68 / 旗@+72 / iface@+80),
被 14 处调用; `sub_140F30200(payload)` = `malloc(0x650)` + `sub_1417C9380` + `sub_141391400`,
被 18 处调用。

> ⚠ **双通道辨析**: 书内多处已引的「尾 UI 通知」`sub_140224C30(ui, {code})` (175 处) 是
> **界面刷新码通道** (只发消息码不建对象), 与本族**真通知对象通道**互不替代, 二者并列。

> **本域 GUI 类布局**: 见 §4.31.92。

#### 4.17.7 CAlertManager 警报系统族 (alertmanager.cpp; 与 §4.17.1-6 通知系统并列的第二套玩家通知面)

| 项 | 值 |
|---|---|
| 类 | CAlertManager (源文件 alertmanager.cpp; **无独立 RTTI 虚表** — 纯聚合结构, 非 CPersistent) |
| sizeof | 100776B (malloc 0x189A8); ctor sub_140AFDB60 (ctor 内完成 81 项警报注册 + common/alerts.txt 加载) |
| 挂载 | idler+1944 (CInGameIdler+243×8; 装配 = idler 构造期 sub_140DDE8A0); 紧随 idler+1952 = 72B 条状管理器 (ctor sub_141756990) |
| 驱动 | CInGameIdler::Idle **暂停门分支内**、iface 帧更新之前 (§4.2.1) 每帧调 sub_140B188A0 (profiler 域 "alert_manager_update"); 四层门: 暂停位 +1729/+1732 全零 ∧ 玩家 tag (gs+1312/1316 >0) ∧ 无全屏窗 (sub_140B67DD0) ∧ renderhide 旗 byte_14332F61F = 0 |
| 分拍 | 每帧只评估 **1 个**警报 id 的触发条件 (+96432 轮转, 82 帧一周期, 尾置整圈旗 +100432); 82 容器的 widget 定位/glow 刷新 sweep 每帧全量 |
| 数据文件 | common/alerts.txt (ctor 尾 sub_140B169A0 加载; 格式 `alerts = { <名> = { category = HIGH\|MEDIUM\|LOW } }`) |

CAlertManager 布局 (偏移十进制):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | 内联槽×82 (1128B/槽) | 警报型主槽 (模板; id i 槽 @ +1128×i) — 无 widget |
| +92496 | 容器×82 (24B/容器) | **活跃条目表** — id i 容器 @ +92496+24×i; 容器 = {data@+0, cap i32@+8, count i32@+12, allocator*@+16} |
| +94464 | 容器×82 (24B) | 第二族 (ctor 定形, 读者未展开, 待裁) |
| +96432 | int32 | round-robin 轮转计数器 (0..81; 复位 sub_140B17A50) |
| +96436..+96452 | int32×5 | 网格配置 {X0@+96436, Y0@+96440, step_x@+96444, step_y@+96448, 列数@+96452 (sub_140B18130 按 alerticon_offset/alerticon_endposition 属性 + 分辨率宽算)} |
| +96456 | int32 | 网格游标 (本帧最大格序; 条状管理器排其后) |
| +96464 | 容器×82 (24B) | 第三族 (待裁) |
| +98432 | 容器×82 (24B) | 第四族 (待裁) |
| +100400 | int32 | init = −1 |
| +100416 | int32 | init = −1 |
| +100420 | int32 | clamp 缓存 (id 57 用) |
| +100432 | uint8 | 整圈完成旗 |
| +100452 | uint32 | 粘滞旗 (dismissed 判据 sub_140B0D980 兜底) |
| +100488 | uint8 | crypto 联动旗 |
| +100496 | 容器 (24B) | 有效州集合 (逐帧重建; 源 = cc+360 数组 / cc+372 计数) |
| +100512 | allocator vt | off_143085170 (与 notification handler 同款分配器桩) |
| +100520 | int32 | 时间戳钳制 (id 52 用) |
| +100680 | 32B 节点 | ctor 自建 (推定名→id 哈希索引成员; 载 f32 0.9, 待裁) |
| +100696 | 32B 节点 | 同上第二节点 |

主槽 / 活跃条目 (1128B 同形; 条目独有 +1112/+1120):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| +0 | uint8 | 闩锁 (主槽 = 已置位判重; 条目 = 活跃旗) |
| +8 | 32B 串 | `<名>_instant` (token) |
| +40 | 32B 串 | `<名>_delayed` + 换行 + `"ALERT_RIGHTCLICK"` |
| +1040 | 32B 串 | **警报名** (common/alerts.txt 键; 条目名串 = dismissed tooltip 素材) |
| +1072 | int32 | **severity**: category 映射 sub_140B026F0 — HIGH→2 / 其余类别→1 / 无→0 |
| +1080 | 16B 键对 | 清除/判重键 (键0+键1; 全零 = 空闲槽) |
| +1088 | 同上第二槽 | 常为对象指针 (如州 ptr; 合法性清扫 sub_140B37B40 查此槽) |
| +1096 | int32 | 动作码 (RegisterAlert 第 4 参: 多数 0 / 3-6 补给=5 / 7·67=1 / 22·60=2) |
| +1104 | qword | 条目锚 (非 0 = 可清除门) |
| +1112 | CGlobalAlertIcon* | widget (仅条目; ctor sub_140AFF650, 1376B, 主 vt 命名 RTTI + 次 vt@+40, +48 = mgr 回指 / +72 = 警报 id; 窗名 `global_alerticon_window`) |
| +1120 | int32 | 网格序号 (同格堆叠序, 仅条目) |

红/黄两态 (定案): 条目 +1072 == 2 (category HIGH: 战争/登陆/补给枯竭/海战等) → 显 `red_alert_glow` 隐黄; MEDIUM/LOW → 显 `yellow_alert_glow`。⚠ `theatre_alert_red/yellow/green_glow` = 剧场 UI 自有辉光, 不属本管理器。

原语族 (全定案):

| 函数 | 语义 |
|---|---|
| sub_140B01D40 | 底层入队 (mgr, id, 键×3): 主槽闩锁 + 键双重判重 → 主槽拷 1128B 尾插容器 (满则 1.5×扩容) → 锚非 0 即时刷 glow |
| sub_140B01B00 | 高层 raise (mgr, id) = 1D40 全零键 + 网格堆叠移位 (severity≥新条目者格序 +1) + malloc(1376) 建 CGlobalAlertIcon 存 +1112 |
| sub_140B17240 | 按键清除 (键匹配 ∧ +1104==0) → 析构 + 摘 widget + 按序删除 |
| sub_140B062B0 | 点击/确认复合动作: id≤59 特例位图; 含 61/62 (crypto) 清除与 +100488 置位; widget 主回调 sub_140B15B50 与海战 UI (sub_141E6C6C0/C700) 共走此口 |
| sub_140B172E0 | 清空整容器 (update 尾对当前轮转 id 调用; 精确触发路径待裁 — 推定轮转重评前清, 条目由检查器/事件面重发) |
| sub_140B175B0 | 全量重建 widget (遍历 82 容器摘除后按 id 启用重发) = 顶栏 dismissed_alerts_button handler (§4.30.29 +2840) |
| sub_140B17A50 | 复位轮转 (+96432 = 0, 清 +100432); 调用点 = CTopBar @48[7] 逐帧体 |
| sub_140B37B40 | 逐帧合法性清扫: 重建 +100496 有效州集合 → 全容器倒序查条目 +1088 键, 州失效即摘 (占领翻转/割让即消) |

round-robin 检查器 (update 内第二 switch 按 +96432 分派; raise = sub_140B01B00 / clear = sub_140B17240): id 0..7/19/43/45/46/62 直跳 sweep (无逐帧检查, 由专用批量函数或外部事件面驱动); id 10..14 检查支路未展开 (待裁); 其余逐帧, 评估入口代表例: 3/4 补给两态 = sub_140B26E40 逐州 (州 ptr 为键) / 8 无科研 = sub_140B2B0A0 / 16 选焦点 = 内联 (遍历 cc+4976 评估器表 vt+72) / 22 海战 = sub_140B29870 清 + sub_140B34F20 查 / 40 抵抗 = sub_140B31B80 (severity 动态 0/1/2) / 58 交战中 = sub_140D3FD60 / 63 驻军不足 = sub_140B0D9D0 / 73..77 突袭五件 = gs+1008 CRaidSystem +436/+460/+484/+508/+532 非零即 raise / 78 无燃油 = sub_1410F3570(cc+5504) vs define 双和 / 80 缺电力 = ps+936 < 100000。事件驱动面 (轮转之外): widget 回调 sub_140B15B50 / 海战 UI 双入口 / 顶栏重建 sub_140B175B0 / CTopBar 复位 sub_140B17A50。

消费面 (GUI): ① `global_alerticon_window` 网格 — 每条目一窗, 定位公式 `X = +96436 + step_x×(格序 % 列数)`, `Y = +96440 + step_y×(格序 / 列数)`, 窗 vt+416 SetPosition; red/yellow glow 按 severity 显隐。② 顶栏 `dismissed_alerts_button` — sub_140B0D980 (任一容器有条目 ∨ +100452) 显隐; tooltip = DISMISSED_ALERTS_MENU + sub_140B08E80 拼接全部条目名; 点击 → sub_140B175B0 全量重建。③ 条状管理器 (idler+1952, 72B) — 每帧 sub_1417582C0 与警报更新成对调用; 条目排活跃网格之后 (+96456+1 起), 携 +1368 警报 id / +1372 键 / +1376 隐藏旗 (条目对象类名待裁)。④ 点击链 — 相机跳转 + sub_140B11C30 大 switch 按警报 id 开对应视图 (视图号族 = §4.30.29 顶栏视图编号)。⑤ 音效 define `ALERT_SFX_COOLDOWN_DAYS` (读入 dword_143336E00; 播放点待裁)。

与 NNotification (§4.17.1-6) 边界: alert = **条件轮询** (82 类逐帧 round-robin 重评估, 条件消失即消, common/alerts.txt 配色, 点击跳转, 挂 idler+1944); notification = **事件推送** (业务侧建对象入队, 一次性消息, 超时天数, 挂 iface+1240)。两系统零函数交叠; 海战战果类 (33/41/44) 虽名含 results 仍走 alert 通道。

对拍定案: **零游戏状态写门** (update + 原语族 + 检查器群对 gs/cc 只读; 写仅落 mgr 自身字段与 GUI 元素) + **零存档面** (无 CPersistent 形态; serfam `alert` 零命中; 逐帧重评估自再生成) — sv2_export 无新增叶。风险三点: renderhide 旗置位时整体跳过 / 暂停冻结轮转 (+96432 不推进) / 单 id 82 帧采样延迟 (探针读某警报状态须等轮转位); `alert_manager_update` 出现在 profile_top/folded = 帧级常规项非异常。

> 待裁: +94464/+96464/+98432 三族容器角色; sub_140B172E0 触发路径; 动作码全语义; id 68 未注册废弃槽 (有 case 不可显); id 0 无 raise 点; +100452/+100488 完整写史; 音效播放点; 条状管理器条目对象类名; id 10..14 检查支路。
