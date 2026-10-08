

### 4.17 通知与警报系统族 (NNotification 命名空间 + CAlertManager)

> 族 = `NNotification` 命名空间下**恰 6 个类** (RTTI 全量枚举: 类型描述符直扫 + 基类反查 +
> 独立重建 COL→CHD→TD 链, 三法同解)。命名空间内另有匿名命名空间 `NNotification::?A0x7797ffe3`
> (容器件所在; 其布局 = GUI 行件, 见 §4.31.92)。头文件 `source/interfaces/notifications/notification.h`, 实现
> `notification_handler.cpp`; GUI 定义 `interface/notifications/notification.gui`
> (含 `notification_center` / `notification_entry` 两容器窗)。
>
> **全族零存档面 (定案)**: 6 类基链无 `CPersistent` 任一层 (CHD 直读; 且 6 张主vtable全部
> 不匹配 CPersistent 家族指纹 [1] = 0x1424BEC50 & [3] = 0x1424BE690); `ref/serfam_1193.txt`
> 内 `notification` 零命中; 运行时全量内存导出 (129 MB) 内 `notification` / `notif` / `alert` /
> `popup` / `toast` 全部零命中 (对照 `idea|focus` 14,830 命中)。⇒ 通知是**纯会话内瞬态 UI 状态**,
> 读档/换会话即清空; handler 生命周期 = `CInGameInterfaceHandler` 生命周期。

#### 4.17.1 通知族类清单

| 类 (RTTI 实名) | sizeof | 主vtable | 次vtable (mdisp) | ctor | 基类链 |
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
| +40 | CTooltipHandler vtable | tooltip 面vtable (2 槽) | ctor |
| +48 | 匿名结构 (32B, std::string 形) | 通知窗口名串 (调用方传入, 如 `message_popup_window`) | ctor 从 a2 拷入 |
| +80 | CClass* | tooltip 目标元素 | sub_141BBEF90: `sub_1422B8BC0(root, 名+"_instance")`; 高置信 |
| +88 | CClass* | tooltip 根窗元素 | sub_141BBEF90 直写 a2; 高置信 |
| +96 | CButtonEventDispatcher + 回调束 (1288B) | 束头 = CButtonEventDispatcher 子对象 (dtor 回写其 vftable); 束内 **12 个 GUI 事件回调槽** (安装器 sub_141BBE0A0, 逐槽 `CLegacyButtonObserverGlue<CNotification>` + sub_1402A69E0 挂 std::function); 基 ctor 仅装 2 个非空 (sub_1402A08F0 / sub_141BBF120, 二者均操作 +1432 过期旗), 余 10 空; 束跨度 = +96 → +1384 = 1288B | 结构/尺寸定案; 逐槽元素名待裁 (需 .gui 侧 `notification_entry` 元素名对齐) |
| +1384 | CGameDate 内嵌 24B | **创建时刻** {vtable@1384, hours@1392, 视图 vtable@1400} | ctor: +1392 = `*(gs+1128)` 当前小时 |
| +1408 | CGameDate 内嵌 24B | **超时基线** {vtable@1408, hours@1416, 视图 vtable@1424} | ctor: +1416 = 43808760 (CGameDate ctor 哨兵 "1.1.1.1") |
| +1432 | uint8 | **已过期/待移除旗** (置 1 → 下一帧自毁) | sub_1402A08F0 置 1; sub_141BBF1B0 收尾判 |
| +1436 | int32 | **超时天数** (ctor 初值 −1; 0 触发 notification.h:39 断言) | setter sub_141378090 (断言门 `Days > 0`); 默认值源 = define `INFO_MESSAGE_TIMEOUT_DAYS` (sub_14083FD20 读, 兜底 1) |

**CNotification 主vtable 9 槽** (0x142A4B708):

| 槽 | 地址 | 语义 |
|---|---|---|
| [0] | 0x141BBED30 | 完整 dtor (拆 glue → CGregorianDate → 串 → CButtonEventDispatcher → CTooltipHandler → 基) |
| [1] | 0x14011D220 | ret 0 |
| [2] | 0x141BBF140 | Reload (CReloadableInterface 面覆写; 重建 tooltip 面 + 自调 vtable[5]) |
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
| [8] | 点击动作 | 0x141378120 → `sub_140B68FB0(iface, *(this+1440))` | 0x14011D220 (ret 0) | 0x1417C97D0 → `*(this+1576)` 对象 vtable[2] |

> 三具体类的 [5]/[7] 各持独立 loc key 族 ⇒ 通知文案**完全数据驱动**, 引擎侧无硬编码文本。

**回调签名族 (RTTI 实证 5 族)**: `void (CNotification::*)(void)` / `(CGuiObject*)` /
`(CGuiObject*, int)` / `(CGuiObject*, CVector<int>)` / `(int)` — 5 个 `std::_Binder` 类型描述符实名。

#### 4.17.3 CNotificationHandler (全局单例, 96B)

ctor = `sub_1413911A0`; 由 `CInGameInterfaceHandler` ctor `sub_140B614C0` 内 `malloc(0x60)` +
存入 **iface+1240**。全局定位链: `CInGameIdler + 1720 = iface` (ctor sub_140DC1B30 内
`*(a1+1720) = sub_140B614C0(...)`) → iface 主虚槽 **[23] (vtable+184) = 取回 iface 自身** →
`+1240` 取 handler (df397 直证强化为定案: sub_140C24120 内 `v6 = vt[+184](v5)` +
`sub_141391400(*(v6+1240), v4)` 与本链逐字吻合)。

| 偏移 | 类型 | 名称/语义 | 证据 |
|---|---|---|---|
| +16 | CReloadableInterface vtable | 次vtable (5 槽) | ctor `*(a1+16) = vftable` |
| +40 | CClass* | **`notification_center` 窗** (GUI 顶层容器) | sub_1413916B0: `vtable+96(guimgr, "notification_center")` → `a1[5]` |
| +48 | CClass* | **`notification_list`** (OverlappingElementsBox, 通知条目列表) | sub_1413916B0: `sub_1422BCBA0(a1[5], "notification_list", 1)` → `a1[6]` |
| +56 | int32 对 | GUI positionType **`maximum_offset`** {x@56, y@60} | 来源定案 (`sub_1422BD000(...,"maximum_offset",1)+240` → `a1[7]`); 轴角色待裁 |
| +64 | int32 对 | GUI positionType **`maximum_size`** {x@64, y@68} | 来源定案 (同上 `"maximum_size"` → `a1[8]`); 轴角色待裁 |
| +72 | uint8 | **本帧有条目被摘除门** (Update 收集到 `*(条目+72)+1432 == 1` 的通知 → 从列表 `vtable[82](+656)` 摘除 → 置 1 → 触发布局重算) | 触发条件定案; 清除点推定 (每帧开头不清, 残留到下次置位) |

**主vtable 6 槽 (0x1429B59A8)**: [0] 0x141391390 dtor (回写 CUpdateable vftable; 调
`*(Block[8] vtable+664)` 释窗; sub_1422560A0(Block+2)) / [1] 0x141391B30 **Update** (CUpdateable[1] 覆写) /
[2] 0x1413916B0 **Reload** (重建 notification_center/notification_list + 重挂既有条目) /
[3] 0x14012A2C0 CFG / [4] 0x14011D220 ret 0 / [5] 0x14012A2C0 CFG。

**次vtable 5 槽 (0x1429B59E0)**: [0] 0x1413912E8 (thunk → 0x141391390, this−16) / [1] ret0 /
[2] 0x1413916B0 Reload / [3] CFG / [4] 0x14011D220。

> ⚠ 本类为 **CUpdateable + CReloadableInterface 多继承宿主**: CUpdateable 的 [2] 位被
> CReloadableInterface 的 Reload 占据 (MI 重排), 与单继承宿主的槽序不同 — 读槽须按 MI 处理。

**帧驱动链**: `CInGameInterfaceHandler` 每帧更新 sub_140B67570 →
`(*(*(iface+1240)+8))(iface+1240)` = handler vtable[1] Update → 紧接 `sub_141391660(iface+1240)`
对 notification_center 与 notification_list 各调 vtable+128 并置 +165 / +117 的 0x10 位
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
> `iface vtable+184` (玩家国 tag) 有效 且 `byte_14332F639 == 0` (非 AI 托管) 且
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
| +1512 | uint8 | **图标变体旗** (`diplo_war_large_icon` vs `diplo_war_large_icon2`) | ctor 六参版 a6 |
| +1520 | 内嵌对象 (56B) | 引用/观察者对象 (析构 = `*(+56)` 对象 vtable[4](.., flag)) | ctor unwind 链; 类名待裁 |
| +1576 | CClass* | **点击动作对象** (vtable[2] 被调) | sub_1417C97D0 |
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
| sub_140C24120 | 将领伤病 `NOTIFICATION_OUR_GENERAL_SICK/WOUNDED[_DESC]` (df397 精化: 门 = idler vtable+160 槽 20 取玩家国 tag 指针, 与 leader+288 等值比对 + sub_140BB52F0 同原初国容错; CEventScope 宿主 = 将领 (sub_14053B8E0); 标题本地化带 NAME = 将领名绑定, 描述不带 (第 4 参 1 vs 0); sender = leader+288 tag / receiver = 0 / 图标旗 0 → diplo_war_large_icon) |
| sub_140FE3AA0 | 特殊项目被夺 `SPECIAL_PROJECT_CAPTURED_TITLE/MESSAGE` |
| sub_141A34910 | 学说奖励解锁 `NOTIFICATION_REWARD_UNLOCKED` (断言 `doctrine_ui_utils.cpp`) |
| sub_140BABD00 | 理念失效替换 `POLITICS_INVALID_IDEA_REMOVED/REPLACED` |
| sub_140D93260 | 宗主国下建阵营 `FACTION_CREATED_UNDER_MASTER_{TITLE,MESSAGE}` |

#### 4.17.5 派发三层结构

| 层 | 动作 | 证据 |
|---|---|---|
| ① 业务侧 | 构造具体派生对象 (malloc + ctor) — 焦点完成 1 处 / 理念过期 1 处 / 弹窗 13 处 | 各推送点 |
| ② 入队 | `sub_141391400(handler, obj)` — **全族唯一入队入口** (14 个不同调用函数); 建 CNotificationContainer (malloc 0x50) 包 obj 挂 `notification_entry`, `_RTDynamicCast` 校验宿主为 CContainerWindow, `notification_list.vt[81](+648)` 插入列表; 置 handler+72 = 1 | 二进制文件 |
| ③ 帧驱动 | handler vtable[1] Update (sub_141391B30): 遍历 notification_list 全部条目 → 逐条判 `*(item+72)+1432` (过期旗) → 未过期者收集 → 逐条 `notification_list.vt[82](+656)(item, 0)` 重排 → `+72` 门 → 按 maximum_offset / maximum_size 钳制重算列表位置写 list+136 | 二进制文件 |
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
| 类 | CAlertManager (源文件 alertmanager.cpp; **无独立 RTTI vtable** — 纯聚合结构, 非 CPersistent) |
| sizeof | 100776B (malloc 0x189A8); ctor sub_140AFDB60 (ctor 内完成 81 项警报注册 + common/alerts.txt 加载) |
| 挂载 | idler+1944 (CInGameIdler+243×8; 装配 = idler 构造期 sub_140DDE8A0); 紧随 idler+1952 = 72B 条状管理器 (ctor sub_141756990) |
| 驱动 | CInGameIdler::Idle **暂停门分支内**、iface 帧更新之前 (§4.2.1) 每帧调 sub_140B188A0 (profiler 域 "alert_manager_update"); 四层门: 暂停位 +1729/+1732 全零 ∧ 玩家 tag (gs+1312/1316 >0) ∧ 无全屏窗 (sub_140B67DD0) ∧ renderhide 旗 byte_14332F61F = 0 (toggle 点 = sub_140252D70, 回显 "Rendering is now SHOWN/HIDDEN") |
| 分拍 | 每帧只评估 **1 个**警报 id 的触发条件 (+96432 轮转, 82 帧一周期, 尾置整圈旗 +100432); 82 容器的 widget 定位/glow 刷新 sweep 每帧全量 |
| 数据文件 | common/alerts.txt (ctor 尾 sub_140B169A0 加载; 格式 `alerts = { <名> = { category = HIGH\|MEDIUM\|LOW } }`) |

CAlertManager 布局 (偏移十进制):

| 偏移 | 类型 | 名称/语义 |
|---|---|---|
| +0 | 内联槽×82 (1128B/槽) | 警报型主槽 (模板; id i 槽 @ +1128×i) — 无 widget |
| +92496 | 匿名结构 (NNB 形状) 向量 ×82 (24B/容器) | **活跃条目表** — id i 容器 @ +92496+24×i; 容器 = {data@+0, cap i32@+8, count i32@+12, allocator*@+16} |
| +94464 | CGameDate×82 (24B/项) | **音效冷却戳** — id i 项 @ +94464+24×i; 项 +8 = 下次允许播放小时; 消费 = sub_140B166A0 (写入 `now + ALERT_SFX_COOLDOWN_DAYS×24`) |
| +96432 | int32 | round-robin 轮转计数器 (0..81; 复位 sub_140B17A50) |
| +96436..+96452 | int32×5 | 网格配置 {X0@+96436, Y0@+96440, step_x@+96444, step_y@+96448, 列数@+96452 (sub_140B18130 按 alerticon_offset/alerticon_endposition 属性 + 分辨率宽算)} |
| +96456 | int32 | 网格游标 (本帧最大格序; 条状管理器排其后) |
| +96464 | 匿名结构 (NNB 形状) 向量 ×82 (24B) | 休眠成员 (负定案: 1.19.3 无读写点, 字面量+索引形双重检索; 元素 ctor 与 +92496 族同款); 业务名未决 |
| +98432 | 匿名结构 (NNB 形状) 向量 ×82 (24B) | 同 +96464 (休眠负定案) |
| +100400 | int32 | 海战类警报副钮逐条轮转游标 (sub_140B143B0 每次 +1, sub_140B288F0 读比对选中项; init −1 = 无游标) |
| +100416 | int32 | 逐师/逐组跳转轮转游标 (sub_140B0FB00 模 count 递增, −1 复位; 供 sub_140B13FD0 点击链) |
| +100420 | int32 | clamp 缓存 (id 57 用) |
| +100432 | uint8 | 整圈完成旗 (兼音效总闸: 首圈 82 帧内静音) |
| +100440 | 匿名结构 (NNB 形状) 向量 24B | **已解除警报 id 列表** (int32/项; count@+100452); push = sub_140B062B0, 清 = sub_140B175B0, 判 = sub_140B0D980 |
| +100452 | int32 | = +100440 容器 count (dismissed 判据 `!= 0`) |
| +100464 | 匿名结构 (NNB 形状) 向量 24B | **crypto 已解除 id 列表** (int32/项); id 61 检查器 sub_140B1ECE0 查重 |
| +100488 | uint8 | crypto 点击确认一次性门 (点击 61/62 置 1; sub_140B1ECE0 消费后自清; sub_140B17450 亦清) |
| +100496 | 匿名结构 (NNB 形状) 向量 24B | 有效州集合 (逐帧重建; 源 = cc+360 数组 / cc+372 计数) |
| +100512 | allocator vtable | off_143085170 (与 notification handler 同款分配器桩) |
| +100520 | int32 | 时间戳钳制 (id 52 用) |
| +100680 | 有序映射 (16B 头) | int 键 std::map 形 (自链哨兵 32B, 节点键@+28) = **id 71 上一轮项目 id 集** (边沿检测); 消费 = sub_140B2F4B0 |
| +100696 | 有序映射 (16B 头) | 同形 = **id 70 上一轮项目 id 集**; 消费 = sub_140B2FF30 |
| +100712 | 平坦哈希 | **警报名→id 索引** (键 = 名串, 值@节点+40 = id; 128 桶); 仅注册期写入, 查找侧休眠 |
| +100740 | float | +100712 最大载因子 = 0.9 (0x3F666666) |
| +100744 | int32 | id 65 学说逐个点击游标 (sub_140B10070, 越界归零) |
| +100752 | int32 | id 72 项目逐个跳转游标 (sub_140B14FD0 / sub_140B16360) |

主槽 / 活跃条目 (1128B 同形; 条目独有 +1112/+1120):

| 元素+N | 类型 | 名称/语义 |
|---|---|---|
| +0 | uint8 | 闩锁 (主槽 = 已置位判重; 条目 = 活跃旗) |
| +8 | 32B 串 | `<名>_instant` (token) |
| +40 | 32B 串 | `<名>_delayed` + 换行 + `"ALERT_RIGHTCLICK"` |
| +1040 | 32B 串 | **警报名** (common/alerts.txt 键; 条目名串 = dismissed tooltip 素材) |
| +1072 | int32 | **severity**: category 映射 sub_140B026F0 — high→2 / medium→1 / low→0 (未知名报 "Unexpected alert category" 后落 0) |
| +1080 | 16B 键对 | 清除/判重键 (键0+键1; 全零 = 空闲槽) |
| +1088 | 同上第二槽 | 常为对象指针 (如州 ptr; 合法性清扫 sub_140B37B40 查此槽) |
| +1096 | int32 | 动作码 (RegisterAlert 第 4 参; **有活读点**: 点击主入口 sub_140B13C90 命中条目后喂 sub_140A66DE0 消费; 值分布: 多数 0 / 3-6 补给=5 / 7·67=1 / 22·60=2) |
| +1104 | uint64 | 条目锚 (非 0 = 可清除门) |
| +1112 | CGlobalAlertIcon* | widget (仅条目; ctor sub_140AFF650, 1376B, 主 vtable 命名 RTTI + 次 vtable@+40, +48 = mgr 回指 / +72 = 警报 id; 窗名 `global_alerticon_window`) |
| +1120 | int32 | 网格序号 (同格堆叠序, 仅条目) |

红/黄两态 (定案): 条目 +1072 == 2 (category HIGH: 战争/登陆/补给枯竭/海战等) → 显 `red_alert_glow` 隐黄; MEDIUM/LOW → 显 `yellow_alert_glow`。⚠ `theatre_alert_red/yellow/green_glow` = 剧场 UI 自有辉光, 不属本管理器。

原语族 (全定案):

| 函数 | 语义 |
|---|---|
| sub_140B01D40 | 底层入队 (mgr, id, 键×3): 主槽闩锁 + 键双重判重 → 主槽拷 1128B 尾插容器 (满则 1.5×扩容) → 锚非 0 即时刷 glow |
| sub_140B01B00 | 高层 raise (mgr, id) = 1D40 全零键 + 网格堆叠移位 (severity≥新条目者格序 +1) + malloc(1376) 建 CGlobalAlertIcon 存 +1112 |
| sub_140B17240 | 按键清除 (键匹配 ∧ +1104==0) → 析构 + 摘 widget + 按序删除 |
| sub_140B062B0 | 点击/确认复合动作: id≤59 特例位图; 含 61/62 (crypto) 清除与 +100488 置位; widget 主回调 sub_140B15B50 与海战 UI (sub_141E6C6C0/C700) 共走此口 |
| sub_140B172E0 | **活跃条目群析构器**: 逐条目 dtor (1128B 步) + count=0 (data/cap 不动)。调用点 ① update 门失败回退路径 (玩家 tag ≤0 ∨ 全屏窗开 → 清当前轮转 id 活跃条目后照常推进轮转; 正常帧路径不经过) ② +92496 族容器元素 dtor sub_140AFFFC0 |
| sub_140B166A0 | 音效播放 (id): +94464[id] 冷却门 (上次日 ≤ 当前日放行) + +100432 总闸; `<警报名>_sound` 经 sub_140B69E40 播放并回写冷却 = `now + ALERT_SFX_COOLDOWN_DAYS×24`; 唯一调用者 = sub_140B01D40 尾 (每次成功入队); 断言 alertmanager.cpp:1281 |
| sub_140B10070 | id 65 学说逐个点击推进 (+100744 游标; 按目录名 land/naval/air/special_forces_doctrine_folder 分派视图 7/8) |
| sub_140B14FD0 / sub_140B16360 | id 72 项目逐个跳转推进 (+100752 游标, 视图 5) |
| sub_140B0FB00 | 逐师跳转游标推进 (+100416; 供 sub_140B13FD0 点击链) |
| sub_140B001F0 | CAlertManager dtor (清理序: +100712 哈希 → 两映射 → 8 个尾部容器 → 三族数组逆序 → 主槽族) |
| sub_140B2FF30 / sub_140B2F4B0 | id 70/71 检查器 (+100696/+100680 前态集边沿检测; 新 id 出现 → 清树 + 批量重建 + sub_140B177B0 复用 raise) |
| sub_140B175B0 | 全量重建 widget (遍历 82 容器摘除后按 id 启用重发) = 顶栏 dismissed_alerts_button handler (§4.30.29 +2840) |
| sub_140B17A50 | 复位轮转 (+96432 = 0, 清 +100432); 调用点 = CTopBar @48[7] 逐帧体 |
| sub_140B37B40 | 逐帧合法性清扫: 重建 +100496 有效州集合 → 全容器倒序查条目 +1088 键, 州失效即摘 (占领翻转/割让即消) |

辅助件 (拷贝/清扫/GUI 链内件, 全定案):

| 函数 | 语义 |
|---|---|
| sub_140AFFD80 | raise 路径主槽拷贝 (1128B 注册形定案基准) |
| sub_140AFFCA0 / sub_140B004E0 | 入队条目的元素拷贝 / dtor (sub_140B01D40 满容器 1.5× 扩容路径) |
| sub_140AFD280 | CGlobalAlertIcon 事件回调束安装: 主钮 sub_140B15B50 + 副钮 sub_140B14370 (id 58 特判 → sub_140B6EB60(iface) → sub_140B11C30(mgr, id)) |
| sub_140B17190 / sub_140B18820 | 逐帧合法性清扫内联件 (有效州集合解析链; 源 = cc+360 数组 / cc+372 计数, 经 sub_140CDCC80) |
| sub_141861210 | 全屏窗门分支: iface+1018 非零 → 和会/lobby 窗检查 sub_141861210(*(iface+576)) |
| sub_140B0CDC0 / sub_140B0CDE0 | 条状管理器格位计算 (格序自 +96456+1 起 = 条状区排活跃警报网格之后) |
| sub_141756D70 | 条状管理器 tag/条目失配全量重建 |
| sub_141897AB0 | CTopBar BuildTooltip 宿主 (dismissed_alerts_button tooltip 拼接发生地) |
| sub_140B67F10 | iface 每帧更新调用点 (警报更新先于 iface 帧更新, 同层其后) |
| sub_1424CFA60 | profiler 作用域 begin/end 对之 end (域 "alert_manager_update" 覆盖整个 update: 分拍检查 + 82 容器 sweep) |
| sub_140B13C90 | 点击→界面主入口 (widget 副链 / sub_141E6C3D0 转发): 相机跳转 (a3+48 对象 +224/+228 坐标 → vtable+304 → sub_141262730) → 按键定位条目 → sub_140B11C30 大 switch 按 id 开视图 (视图号族 = §4.30.29 顶栏视图编号) |
| sub_140B15E10 / sub_140B15B80 / sub_140B145F0 / sub_140B11840 | id 1/2/45/46 / id 5/6 / id 22 / id 60 的专用开界面分支 (id 7 = sub_140B68DE0 经 iface; id 58 特判 = sub_140B699F0(2)) |

警报 id 全表 (0..81 共 82 值; "Invalid enum" = default 支, alertmanager.cpp:1096; 注册表 = ctor 内 sub_140B0E640 连续调用 81 项, **无 id 68**; 行序 = id 序即契约序; 分派 = update 内第二 switch 按 +96432, raise = sub_140B01B00 / clear = sub_140B17240; 偏移均已折十进制, 锚对象 cc+360/cc+3944/cc+3952/cc+3976/cc+4008/cc+4016/cc+5504 = 国家对象槽族):

| id | common/alerts.txt 键 | 动作码 | round-robin 检查路径 |
|---|---|---|---|
| 0 | alert_hostile_troops | 0 | 无 raise 点 (负定案: 检查支路为空操作, 60 个 raise 调用点零命中; 死位) |
| 1 | alert_naval_invasion | 0 | 直跳; 第一 switch case 批量 sub_140B183F0: 入侵列表逐项 4 档威胁值 (sub_1406FD050) 与缓存 severity 比对 → 四态互换 |
| 2 | alert_naval_invasion | 0 | 同 id 1 |
| 3 | alert_low_supply | 5 | 直跳; 前置块逐州 (cc+360 州数组) sub_140B26E40, 州 ptr 为键 |
| 4 | alert_very_low_supply | 5 | 同 id 3 |
| 5 | alert_base_low_supply | 5 | 直跳; sub_140B33E40 |
| 6 | alert_base_very_low_supply | 5 | 同 id 5 |
| 7 | alert_enemy_air_superiority | 1 | 直跳; sub_140B33A70 → sub_140B36100 (键控 raise) |
| 8 | alert_no_research | 0 | sub_140B2B0A0 |
| 9 | alert_deployment_ready | 0 | sub_140B1EFE0 |
| 10 | alert_production_no_template | 0 | sub_140702890(cc,0)≠0 → raise: +88 产线数组中存在「非五类豁免 (sub_140C97430/97B90/97C00/97C40/97C80, 业务名未决; ⚠ 97430 与 s4_18:764「指挥链权限位谓词」定名异读 — 本处及装备查量门语境均为 CEquipmentType 实参, 与 +1240 上级链读法冲突, ICF 汇点或对象误判待裁) ∧ 产出占比>0 ∧ vtable+248 未过」线 (a2 非 0 = tooltip 逐条拼行模式) |
| 11 | alert_free_civilian_factories | 0 | sub_140E6A540 ==0 → raise (反向): (+888/1e5 − +944 − +920) 逐 +112 行加 (行+24 − MAX_CIV_FACTORIES_PER_LINE) 不中途归零 ⇔ 有富余民用工厂 (行+24 业务名推定) |
| 12 | alert_free_military_factories | 0 | 内联: (+696/1e5) − +752 − +728 > 0 → raise (军事工厂富余) |
| 13 | alert_free_naval_dockyards | 0 | sub_140E69130 >0 → raise: (+792/1e5) − +848 − +824 − 阵营共享扣减 (sub_140EA60A0; 扣减项精确语义推定) |
| 14 | alert_no_equipment_production | 0 | sub_1407008C0(cc,0)≠0 → raise: 全局装备原型表 (country.cpp:12654 niche 位图) 存在未被产线/生产/建设覆盖的原型; DLC 门 29/38 (逐原型豁免函数业务名未决) |
| 15 | alert_pick_new_idea | 0 | sub_140B27690 |
| 16 | alert_select_focus | 0 | 内联: 遍历 cc+4976 评估器表 vtable+72 全 false → raise |
| 17 | alert_volunteer_transfer | 0 | sub_140B36FC0 |
| 18 | alert_trade_import_unfullfilled | 0 | 内联: cc+4600 对象 +1856 数组, 需求 sub_140CA81F0 vs 供给 sub_140CAD5A0 取整比较 |
| 19 | alert_expeditionary_force | 0 | 无 raise 点 (负定案, 同 id 0: 60 个 raise 调用点 `, 19)` 零命中, 两 switch 均无支路) |
| 20 | alert_available_wargoal | 0 | 内联: cc+3976 对象 +104 数组逐国查 **+744** 槽空/位 73 (修正: 原「+728」系取槽笔误, 判位 +73 无误) |
| 21 | alert_enemy_generate_wargoal | 0 | sub_140D3FB30(cc+3976 对象) |
| 22 | alert_naval_combat | 2 | sub_140B29870 清 + sub_140B34F20 查 (键控) |
| 23 | alert_few_manpower | 0 | sub_140B0E110 |
| 24 | alert_faction_generate_wargoal | 0 | sub_140B23AF0 |
| 25 | alert_faction_possible_invite | 0 | sub_140B22F30 |
| 26 | alert_faction_assume_leadership_possible | 0 | 内联: 日期窗口 sub_1415FFE70 / sub_141138CA0 / sub_141615250 |
| 27 | alert_faction_member_near_assuming_leadership | 0 | sub_140B21E00 |
| 28 | alert_expensive_ships_low_str | 0 | 内联三层嵌套 sub_140D230E0 / sub_140D6EEB0 / sub_140B0F330 |
| 29 | alert_timed_activity_low_equipment | 0 | 内联: cc+3952 列表, sub_140AD9ED0(…) > 50000 ∧ sub_140AD9950(…) < 50000 |
| 30 | alert_air_reserve_unused | 0 | sub_140B1AEF0 |
| 31 | alert_air_wings_unassigned | 0 | 内联: sub_140700520 + sub_1401E2A80(gs) + sub_140B02A30 |
| 32 | alert_blocked_national_focus | 0 | 内联: sub_1406CF4C0(cc) +16/+24, 旗 +1466/+1465, vtable+448 槽 +24 |
| 33 | alert_naval_battle_results | 0 | sub_140B286C0(mgr, cc, 0) |
| 34 | alert_is_observer | 0 | 内联: gs+1312 ≤ 0 → raise (gs+1312 = 观察者判据字段, 唯一连写者 = SetPlayerCountry 核 sub_1401EE7F0 写 0; 全链 §4.36.8) |
| 35 | alert_can_play_observed | 0 | sub_140B1E420 |
| 36 | alert_not_training_divisions | 0 | 内联: sub_140D11940(cc+3952 列表) 与 cc+440 数组 sub_140BA2440 |
| 37 | alert_exiled_units | 0 | sub_140B20650 |
| 38 | alert_external_influences | 0 | sub_140B09470(cc+8, out) |
| 39 | alert_lack_of_resources | 0 | sub_140B0A8E0 |
| 40 | alert_resistance | 0 | sub_140B31B80 (severity 动态 0/1/2 写 +1072) |
| 41 | alert_naval_convoy_raiding_results | 0 | sub_140B286C0(mgr, cc, 1) |
| 42 | alert_paused_diplomatic_actions | 0 | 内联: sub_1406CF890(cc)+224 ≤ 0 且 gs vtable+72 国家数 >1 → sub_140B0E1F0 |
| 43 | alert_battleplans_with_no_divs | 0 | 直跳; 前置块逐州 sub_140B1C320 (带键): a2+72 容器 → 元素双数组 +152/+176 → 子项 +504 数组/+540 缺省计数/+664 旗 → 计划对象 +57 旗/+164 计数/+560 数组 (元素 +92 师数); 收集判据三支 (+664 ∧ +164>0 直收 / 总和==0 收 / 逐项 sub_140B08B20 非空即停); 非空 → sub_140B01D40 add (键 = 州) / 全空 → sub_140B17240 remove (字面 43 对锁) |
| 44 | alert_port_strike_results | 0 | sub_140B2E330 |
| 45 | alert_dangerous_naval_invasion | 0 | 直跳; 第一 switch case 批量 sub_140B183F0 (同 id 1) |
| 46 | alert_dangerous_naval_invasion | 0 | 同 id 45 |
| 47 | alert_outdated_equipment | 0 | sub_140B0F120 |
| 48 | alert_self_gain_autonomy | 0 | 内联: cc+3976 对象 +840 → sub_140675290 |
| 49 | alert_self_lose_autonomy | 0 | 内联: 同槽 → sub_140674990 |
| 50 | alert_subject_lose_autonomy | 0 | sub_140B35AE0 |
| 51 | alert_subject_gain_autonomy | 0 | sub_140B354C0 |
| 52 | alert_unassigned_divisions | 0 | 内联 + sub_140B05AA0, 维护 +100520 钳制缓存 |
| 53 | alert_players_lagging_behind | 0 | sub_140B04E60; **tooltip = sub_140B2DDC0** (BuildTooltip case 53; 逐掉队玩家格式化 alert_players_lagging_behind_desc_entry, 参数 PLAYER = 条目+64 名串 / HOURS = 当前小时 − 条目+128 水位 (下钳 0), append 到出参 a2+8; 掉队门 = LAG_DAYS_FOR_LOWER_SPEED (dword_1433361D0, 10 天); a2+40 恒空; 条目布局见 §4.1 gs+248) |
| 54 | alert_non_payed_license | 0 | sub_140B2B810 |
| 55 | alert_decision_new | 0 | sub_140B0D120(0, ·) |
| 56 | alert_decision_timeout | 0 | sub_140B0D390(0, ·) |
| 57 | alert_border_conflict | 0 | sub_140B030D0 + +100420 钳制 + +64296 旗 |
| 58 | alert_is_at_war | 0 | sub_140D3FD60(cc2+3976 对象, 0) (cc2 按 gs+1312 重取) |
| 59 | alert_ally_pulling_its_expeditionaries | 0 | sub_140B1BF30 |
| 60 | alert_is_spotting | 2 | sub_140B259A0 |
| 61 | alert_enemy_crypto_is_broken | 0 | sub_140B1ECE0 (连带 62) |
| 62 | alert_no_crypto_is_being_decrypted | 0 | 直跳; 事件面驱动 |
| 63 | alert_not_enough_garrison | 0 | sub_140B0D9D0 |
| 64 | alert_operative_ready_to_recruit | 0 | sub_1406CF7F0(cc) → sub_140FDA0D0 |
| 65 | alert_doctrine_unlock | 0 | sub_140B036C0 |
| 66 | alert_officer_corps | 0 | sub_140B2C110 |
| 67 | alert_losing_trains | 1 | sub_140B26CE0 |
| 68 | (未注册死 id) | — | 第二 switch 有 case (走 sub_140B0D390(1, ·), 门 = gs+1104 系逐国对象 +8 字节非零 — 常规局推定为 0 不可达) 但 ctor 未注册不可显; 若 raise 真发生主槽名空 → 音效断言 alertmanager.cpp:1281 绊 (debug 门) |
| 69 | alert_industrial_org_sizeup | 0 | 内联: cc+3944 对象 +304 数组 sub_140DB6020 |
| 70 | ui_alert_special_project_available | 0 | sub_140B2FF30 → 内部 sub_140B177B0(mgr, id) 复用 |
| 71 | ui_alert_special_project_available | 0 | sub_140B2F4B0 → 同 id 70 复用 |
| 72 | ui_alert_program_unassigned_scientist | 0 | 内联: cc+4008 对象 +32 数组 sub_141442B30 + 位 160 |
| 73 | alert_raid_available | 0 | 内联: gs+1008 (CRaidSystem*) **+532** 非零即 raise (双 switch 互证) |
| 74 | alert_raid_launchable | 0 | 同上 **+508** |
| 75 | alert_raid_detected | 0 | 同上 **+436** |
| 76 | alert_raid_completed | 0 | 同上 **+460** |
| 77 | alert_got_raided | 0 | 同上 **+484** |
| 78 | alert_out_of_fuel | 0 | sub_1410F3570(cc+5504, &fuel) vs qword_143331E18 + qword_143331D68 (define 双和) |
| 79 | alert_headquarter_admiral | 0 | 内联: cc2+4016 对象 +52 == sub_1415C6330() ∨ ≥ dword_143332744 → clear |
| 80 | alert_lack_of_power | 0 | 内联: cc+3944 对象 +936 < 100000 → raise (工业容量比, §4.30.29 同锚) |
| 81 | alert_faction_can_select_goal | 0 | sub_1401AEB50(50) 门 + cc+3976 对象 +656 MIO/阵营对象扫描 (+1568/+1588/+1580/+3336/+1612 等) |

事件驱动面 (round-robin 之外): widget 回调 sub_140B15B50 / 海战 UI 双入口 sub_141E6C6C0 / sub_141E6C700 (以 idler+1944 取 mgr) / 顶栏重建 sub_140B175B0 / CTopBar 复位 sub_140B17A50。renderhide 渲染开关旗 byte_14332F61F 的 toggle 点 = sub_140252D70 (回显 "Rendering is now SHOWN/HIDDEN"); +94464 第二族容器的元素构造 = sub_1401BFD10 (24B 元素)。

worker 层补全 (定案): 簇实为 7 函数 (清单 6 + **sub_140B188A0 = 每帧 update 驱动本体**, 内核四层门/82 容器 sweep/glow 公式与书逐段一致); **sub_140B026F0** = category→severity 映射 (high→2/medium→1/low→0, exe 三串尺寸 4/6/3 直证; 唯一调用者 = alerts.txt loader sub_140B169A0); **sub_140B13FD0** = 条状图标转发器 sub_141E6C3F0 的点击处理 (id 3/4 缺补给选师跳转: 动作码 5 + 三级解引用取最小 id 单位; id 43 游标 +100416; 其余 "Not implemented" :5865); **sub_140B0E290** = 海军入侵威胁评估 (直袭玩家/盟友时威胁档出参写 4 — id 1/2「4 档威胁值」来源点, 与条目 +1072 severity 值域无关); **sub_140B0AB70** = BuildTooltip (按键三元组 +1080/+1088/**+1104** 定位活跃条目, 按 id 委托组 40 函数重建 +8/+40 文案; default "invalid enum" :2072); **sub_140B11C30** 点击大 switch 补 id 68 开视图支 (视图 12) 与 **id 73-77 五个 raid 点击游标 +100756..+100772** (+100776 恰 = sizeof, 布局尾界闭合)。

消费面 (GUI): ① `global_alerticon_window` 网格 — 每条目一窗, 定位公式 `X = +96436 + step_x×(格序 % 列数)`, `Y = +96440 + step_y×(格序 / 列数)`, 窗 vtable+416 SetPosition; red/yellow glow 按 severity 显隐。② 顶栏 `dismissed_alerts_button` — sub_140B0D980 (任一容器有条目 ∨ +100452) 显隐; tooltip = DISMISSED_ALERTS_MENU + sub_140B08E80 拼接全部条目名; 点击 → sub_140B175B0 全量重建。③ 条状管理器 (idler+1952, 72B) — 每帧 sub_1417582C0 与警报更新成对调用; 条目排活跃网格之后 (+96456+1 起); 条目类 = **CDiplomacyRequestIcon** (1384B, malloc 0x568; 主 vtable + 次 vtable@+40; +48 条状管理器回指; 窗名 global_alerticon_window; +1368 CReference 目标 + +1376 ref 内嵌件 — 与外交请求条共用类)。④ 点击链 — 相机跳转 + sub_140B11C30 大 switch 按警报 id 开对应视图 (视图号族 = §4.30.29 顶栏视图编号)。⑤ 音效 = sub_140B166A0 (冷却戳 +94464[id], define `NGame.ALERT_SFX_COOLDOWN_DAYS` 读入 dword_143336E00; 唯一调用者 = sub_140B01D40 尾)。

与 NNotification (§4.17.1-6) 边界: alert = **条件轮询** (82 类逐帧 round-robin 重评估, 条件消失即消, common/alerts.txt 配色, 点击跳转, 挂 idler+1944); notification = **事件推送** (业务侧建对象入队, 一次性消息, 超时天数, 挂 iface+1240)。两系统零函数交叠; 海战战果类 (33/41/44) 虽名含 results 仍走 alert 通道。

对拍定案: **零游戏状态写门** (update + 原语族 + 检查器群对 gs/cc 只读; 写仅落 mgr 自身字段与 GUI 元素) + **零存档面** (无 CPersistent 形态; serfam `alert` 零命中; 逐帧重评估自再生成) — sv2_export 无新增叶。风险三点: renderhide 旗置位时整体跳过 / 暂停冻结轮转 (+96432 不推进) / 单 id 82 帧采样延迟 (探针读某警报状态须等轮转位); `alert_manager_update` 出现在 profile_top/folded = 帧级常规项非异常。

> 仍开放: id 68 门字节 (gs+1104 系逐国对象 +8) 业务名; id 10 豁免五函数与 id 14 原型表逐项业务名; +96464/+98432 休眠容器业务名; id 11 行 +24 字段业务名。

**警报文案分发器 sub_140B0AB70 与 case 构建函族 (df366 补)**: a2 → 管理器 → **1128B/条的警报条目数组** (entry = base + 1128×i; +40 = std::string 文本成员); switch a3 警报类型, case 20-29 各有专属构建函 (sub_140B37230/140B1FA40/140B299B0/140B23D90/140B232F0/**140B21830**/140B22040/140B20B60/140B36210)。**case 26 = 阵营领导权转移可触发 (sub_140B21830 全案)**: 玩家阵营 (dip+656) 非空 → 领导国 = **fac+88 成员数组首元素 (推定成员序即领导序)** → CEventScope 构造 (sub_1415FFE70(scope, 玩家tag, 领导tag, gs+1128 日期), 176B; dtor sub_140302750 重置 CDiplomaticAction + 两 CGregorianDate vftable) → 双门 (sub_141138CA0 同源+FROM 环检 eventscope.h:193 ∧ sub_141615250 触发器求值, 门 byte_14332F617 + sub_1401AEB50(16)) → 写 `alert_faction_assume_leadership_possible_delayed` (FACTION = fac+24 阵营名 / LEADER = cc+80 definite name 定冠词形) + 尾附 ALERT_RIGHTCLICK。辅助定性: **sub_140129CA0 = string assign (dst ← src[0..size], size 0 = 清空)** 非 append。
