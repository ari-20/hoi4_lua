

### 4.36 联机模式运行逻辑 (单机/联机判别 / 网络服务器族 / 命令传输 / 同步确定性 / 掉线与热加入)

> **本册定位**: 联机 (multiplayer) 模式的运行全链, 以及与单机的全部行为分叉。
> CSession / CGameLobby 布局所有权归 §4.28, 命令子类行归 §4.33, 时间调度骨架
> 归 §4.2, OOS checksum 91 槽的哈希管线细节归 §4.2.4 步骤 8; 本册记判别契约、
> 网络服务器族布局、命令网络链路与 MP 专属流程。**单机不是「无网络」**, 而是同一
> 命令管线的本地环回特例 (§4.36.2 CDummyServer) —— 单机/联机共用生成、序列化、
> 反序列化、派发全链, 差异只在 server 对象的类型与传输层是否出网。
> 传输层 = Steam P2P (ISteamNetworking, User+GameServer 双接口); 引擎侧 WinSock
> 调用全语料 0 命中, 加密/压缩由 Steam 通道内建。

#### 4.36.1 运行形态与判别契约

五个判定原语 (全部定案)。「本机在联机吗」运行时**不走任何 gs 位域**, 全部走 P1
server 类型 dynamic_cast:

| 原语 | 判别 | 读法 |
|---|---|---|
| P1 server 类型 | `server = *(session = appmgr vtable[+136](appmgr))+88`, `_RTDynamicCast` 到 CNetworkServer/CProxyServer 任一非空 = 联机; 两者皆空 = 单机 (CDummyServer) | 全库统一谓词, 内联形态散布 58 宿主 (150 直读站); 常与 session+84 合取 `MP && session+84` |
| P2 会话状态 | session+72 十九值枚举 (§4.28.16 全表), 读者 getter sub_140CE9520 | 联机连接/热加入状态机; 单机正常运行态 = 4 (CONNECTED) |
| P3 gs+192 位域 | bit0 ironman / bit3 tutorial 有真实消费面; **bit1(多人)/bit2(coop) 单例侧零读写点** (bit2 负定案见 §4.36.8) | 「是否联机」不走此位; bit0 只管铁人/成就域 (自动存档三路分叉走 bit0 而非 P1) |
| P4 观察者判据 | gs+1312 ≤ 0 (该偏移唯一连写者 = SetPlayerCountry 核 sub_1401EE7F0 写 0) | 观察者无独立状态位; 详细链见 §4.36.8 |
| P5 会话类型枚举 | session-info+80 (getter sub_140AD0570) → CSession ctor 开关, type 0=CProxyServer / 1=CNetworkServer / 2=CDummyServer | 三型选择唯一写点; Init 行为见下表 |

会话构造 (CSession ctor 重载 sub_141FFFD40 内 switch, 定案):

| type | server 类 | malloc | ctor | Init (sub_142250890) 后语义 |
|---|---|---|---|---|
| 0 | CProxyServer | 552 | sub_1423690F0 | session+72=0 起步; **session+84=0** (客户端无时间生成权); 纯中继客户端 |
| 1 | CNetworkServer | 296 | sub_142364DE0 | **Init 即 session+72=4 (CONNECTED)** — 主机不自连; session+84=1 (时间生成权) |
| 2 | CDummyServer | 248 | sub_142362D50 | session+72=0 起步由 server 环回拉起, 单机正常态 4; session+84=1 |
| 其他 | 不建 server 直接 Init | — | — | — |

Init 通用写点: session+76 = type / session+80 = 会话信息状态 / session+84 =
`(type-1)<=1` (即 type∈{1,2} 才有时间生成权——tick 生成门 §4.2.2 步骤 5 与掉线遍历
§4.2.3 步骤 3 均被它过滤, proxy 客户端两不沾)。type 编号与角色的语义解释 (1=主机 /
0=中继客户端 / 2=单机) 与 bootstrap `CSession("localhost", type=2)` (§4.28.21) 相容,
标高置信。

P1/P2/P3 消费面分域小结 (站点计数含内联形态; 判定原语归属 = 该域主判据):

| 领域 | 主判据 | 站点 | 联机/单机分叉语义 |
|---|---|---|---|
| 时间推进/暂停/速度 | P1 (+P2 ≠13 门) | 8 | 「单机直写暂停位、联机发命令」双轨 4 站复现: app 槽[94] (单机 `!MP` 门; ⚠ 原记 VA sub_140FD42D0 系误记 — 真身 = CIdea::FinalizeIdeas (§4.10.12c), 第一站 VA 未决重定) / app 槽[71] (sub_140FFB2D0) / 直写 idler+1729=1 (sub_141313860 `!MP`) / CPauseGame 广播 (sub_142390340 `MP`); 速度命令发送门 sub_140B07D60 = `!MP ∥ session+84`; idler+2396 联机重试计数 sub_1412073E0 = `!MP ∥ session+84` |
| 命令发送/入队 | P1 + server 槽[5] | 4 | CDummyServer/CNetworkServer 各持独立 tbb 并发命令队列 (ctor 直证, 均 NFS_Allocate 0x2C0); 接收域反伪造门见 §4.36.3 |
| OOS checksum | P1 ∥ 旗组 | 步骤级 | 对比仅在 server 非 CDummy 或调试旗时执行 (§4.2.4 步骤 8; 旗组全表 §4.36.10) |
| 存档 | P3 bit0 (非 P1) | 6 | 自动存档三路分叉 (铁人/云/本地) 走 bit0; 存档确认 UI sub_1402806A0 = `!MP` 才走; 存档失败横幅门 sub_141A38B20 = `!MP ∥ session+84` |
| 读档装载 | P3 bit0 + P2 | 3 | 铁人恢复 = lobby+1217 ∧ bit0 (sub_1404E6220); **联机载入等待屏状态轮询环** sub_141F383E0: `{1,5}` 30 秒墙钟自旋 → `∈{4,6,9,16}` 收尾, 单机直过 |
| 教程 | P1 (仅单机) | 2 | 教程复位+装载 (sub_141503460 块) 与 objective 直改 (sub_14137E790) 均 `!MP` 门 —— 联机无教程的结构性证据 (§4.28.15 互证) |
| 生涯档案/成就 | P1 (MP 禁用) | 6 | "CAREER_PROFILE_AWARDS_NOT_AVAILABLE_IN_MULTIPLAYER" (sub_1414A31E0); 生涯取数链 sub_140C1D950 `!MP`; 成就可用门 (sub_1403DF7A0) MP 直接满足 |
| 聊天/社交 | P1 (联机专属) | 5 | ChatSettingsProviderImpl 仅 `MP && 聊天单例空` 时构造 (sub_140B86A70); 聊天视图单机裁剪 (sub_1423A07B0); KickPlayer/BanPlayer lambda 全库 9 站 |
| 观察者 | P4 | 4 | §4.36.8 |
| 掉线/重连 | P2 + session+84 | 5 | §4.36.5 |
| 会话构造 | P5 | 1 | 本节上表 |

> 备注: P1 判定前必经 `appmgr->vtable[+136](appmgr)` 取 session——单机/联机同构, 不构成
> 分叉; 分叉点恒在 server 对象的 RTTI 类型上。
>
> 备注: `+192) & 2/4/8` 形命中约 30 站全部为 EH 异常清理 funclet 假阳性 (逐一排除);
> 按偏移 grep 位域必须回溯宿主函数确认真 gs 访问。

#### 4.36.2 网络服务器族 (CServer / CDummyServer / CNetworkServer / CProxyServer / CSteamNetContext)

族谱与构造链 (定案): **CServer** (抽象基, 31 槽) → 三实现封闭集 **CDummyServer** (单机
本地环回) / **CNetworkServer** (联机主机) / **CProxyServer** (客户端)。三型由 CSession
ctor 内工厂分支按 type 枚举分配 (§4.36.1 表); 分配后 session+88 = server、server+80 =
session 双向反指。传输层 = **CSteamNetContext** (CServer+72, 工厂 sub_1423E6100;
a5≠1 即 Steam GameServer 接口未就绪直接返 0)。连接管理器登入全局注册表
{qword_1435DA818 data / dword_1435DA820 cap / dword_1435DA824 count} (1.5 倍增长,
多实例合法)。源域 = server.cpp / network_server.cpp / proxy_server.cpp /
pdx_net_steam.cpp (内嵌路径串直证)。

**CServer** (抽象基; ctor sub_142362FD0 三参 this/session 反指/构造门):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | CServer* | 主vtable (派生覆盖) | ctor 直写 (定案) |
| +8 | 链表头 (20B: first@8, last@16, count u32@24, u8@28) | 320B 大节点链 (清理解 sub_141CE6C80 沿节点+320 步进); getter = 槽[11] | ctor + dtor 直读 (定案) |
| +32 | 匿名结构 (40B) | 服务器连接描述 (CNetworkServer/CProxyServer ctor 从 session+32 整块拷入; 子表见下) | ctor 拷贝直证 (定案) |
| +68 | uint16 | 端口 (描述内 +36; getter 槽[23]) | 函数体直读 (定案) |
| +72 | CSteamNetContext* | 连接/传输上下文 (工厂 0x1423E6100, malloc 520) | ctor + 工厂体 (定案) |
| +80 | CSession* | 会话反指 (Init 写; ⚠ +84 无独立字段 = 本指针高 4 字节, 见 §4.36.4) | 直证 (定案) |
| +88 | uint32 | 初值 15; CProxyServer ctor 改写 35; **全族零读者** (负证) | ctor 直写 (值定案/语义待裁) |
| +96 | 链表头 (20B) | 链表 #1: 客户端 (CProxyServer) PackageCallback 的 before-sync 命令暂存链 (getter 槽[19]); 主机 PackageCallback 不消费此链 (零引用) | ctor unwind + 槽函数 + 两型收包泵直读 (定案) |
| +120 | 链表头 (20B) | 链表 #2 = **主机定向命令表** (first@+120/last@+128/count@+136; 节点 0x20 = {cmd@0, prev@8, next@16, 旗 u8@24}, 尾插不重盖序号; getter 槽[20]) | 同上 + PackageCallback 直读 (定案) |
| +144 | 链表头 (20B) | **待处理命令收集链** (槽[6] 入链 / 槽[8] getter / 槽[13] 清链) | 三槽互证 (定案) |
| +168 | RH 哈希表头 (32B) | **机器表** {引用槽@168, 桶@176=静态空 unk_1430BE0F0, count@184, mask@188, extra u8@192, lf f32@196=0.9}; 哈希 = machine id ×73244475 双轮雪崩; 插入 sub_142364470 | ctor/dtor/查表槽直读 (定案) |
| +200 | uint8 | 「Update 已跑」旗 (ctor: Dummy/Network 置 1、Proxy 置 0; Proxy 每轮 Update 尾置 1) | ctor + Update 直读 (定案) |
| +208 | 停表对象* | 全局停表 (sub_14224DBD0 读秒 / sub_14224DC90 重启 / sub_14224DD20 冻结) | ctor + helper 直读 (定案) |

连接描述 40B 元素子表 (构造器 sub_1423E5300 + connmgr vtable[14] 填充):

| 描述内偏移 | 类型 | 语义 |
|---|---|---|
| +0 | uint32 | 标识 dword |
| +4..+19 | 16B | 地址/密钥块 (形态定案, 逐字节待裁) |
| +24 | uint64 | 连接句柄 (踢出/断开用) |
| +32 | uint32 | 主机标识值 |
| +36 | uint16 | 端口 (= CServer+68) |

CServer vtable槽 (0x142B52AC8, 31 槽; 有函数体者, 其余纯虚/共享):

| 槽 | 函数 | 语义 |
|---|---|---|
| [0] | 0x1423634E0 | dtor (完整析构 + 条件 free) |
| [1] | 0x142363830 | 置全局旗 byte_1435B9CF0=1 (派生类覆写为 CFG 空桩, 旗由基 ctor 直置) |
| [2] | ret 0 | Connect 失败桩 (派生覆写: Dummy 立即成功 / Network 恒真 / Proxy 真连接流程) |
| [4] | 0x142363E10 | **发包转发**: SendCtx(this+72, conn, data, len, 1) |
| [5] | 纯虚 | 命令入队 (server.cpp:319 契约) |
| [6] | 纯虚 | 队列出队 → 收集链 |
| [8] | 0x1406F3910 | getter &this+144 (收集链) |
| [11] | 0x140129780 | getter &this+8 (320B 节点链头) |
| [13] | 0x142363650 | 清收集链 (逐节点 delete cmd + free 节点) |
| [16] | ret −1 | 机器表查值缺席默认 (派生覆写真查值) |
| [17] | ret 0xFFFF | 机器表查值缺席默认 (同上) |
| [18] | ret 0 | 机器表查值缺席默认 (同上) |
| [19] | 0x140AD9E50 | getter &this+96 |
| [20] | 0x140CE9BA0 | getter &this+120 |
| [21] | ret 1 | 准入门 (仅 Proxy 覆写为真门) |
| [23] | 0x142363820 | 端口 getter `*(u16*)(this+68)` |
| [24] | — | 空串工厂 (名串 getter 默认版; Network 覆写为 40B 描述拷贝) |
| [29] | 0x142363AF0 | **SendGameState** (server.cpp:189): session+328 门 → 序列化消息头 18 (+协议号 203) → 遍历 session+312 命令日志逐条序列化 → 槽[4] 发送 |

**CDummyServer** (248B, vtable 0x142B52C28, ctor sub_142362D50) —— **单机 = 本地环回,
非空桩**: 31 槽仅 6 槽自覆写, 单机命令走完整的「入队→出队→Clone→收集链→派发」回路
不触网络。专有槽: [2] Connect = 立即 SetState(4 CONNECTED) 返 1; [3] Disconnect =
SetState(0); [5] 入队 (盖 tick cmd+22 = min(session+128, 0x7FFF); 本地命令
cmd+24==0 经原子 +240 分配序号写 cmd+28/+32 入 +216 并发队列); [6] 出队 (pop →
命令槽[13] Clone → 0x20 节点挂 +152/+160 链); [13] 清空。专有布局: +200 uint8=1 /
+216 tbb 并发命令队列 {vtable@216, 页@224} (页 = NFS_Allocate 704, 页+256=32/页+264=8
微块参数) / +240 原子序号分配器 (初值 1)。dtor [0] = 从全局登记表 qword_1435B9CF8
摘除 + 清队列。全局广播器 = CDummy[5] 的注册表回路 (遍历 qword_1435B9CF8 逐 server
反序列化副本入队; 单机仅 Dummy 自身登记)。

**CNetworkServer** (296B, vtable 0x142B53020, ctor sub_142364DE0; 联机主机; 基类域同上表):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +220 | uint16 | **继承者机 id** (NAMED_SUCCESSOR(7) 下发; 首台加入者 = 新机 id) | 接入函数 sub_142368240 直读 (定案) |
| +224 | uint32 | 已连接机器计数 | 同上 (定案) |
| +228 | uint32 | **SERVER_TICK 脉冲周期** = 10 (每 10 泵发 5 号脉冲) | ctor + 槽[6] (定案) |
| +232 | uint32 | 脉冲计数器 (==周期发脉冲归 0) | 槽[6] (定案) |
| +240 | tbb 并发命令队列 (16B {vtable@240, 页@248}) | host 命令队列 | ctor 直写 (定案) |
| +264 | 原子 int32 | 命令序号分配器 (初值 1; 序号写 cmd+28/+32) | ctor + 槽[5]/[27] (定案) |
| +268 | uint8 | **接入窗旗**: REQUEST_ID(8) 分支 `if(+268)` 才允许分配机 id, 否则回 RECONNECT_REFUSED(11); =0 时槽[6] 才发脉冲/推进批号; 重连机 sub_1422502F0 等待环每轮 vtable[6](server,1) 置 1 (1 秒停表为界) | 四写点 + 两读点 (定案) |
| +272 | pdx vector (24B: data@272, cap@280, count@284, 分配器@288) | **大厅成员快照** (元素 8B 连接句柄; 槽[7] 与新名册对账, 变化才重建+日志) | ctor + 槽[7] (定案) |

CNetworkServer vtable (31 槽, 关键槽; [1][9][10][28] = 空桩/常量):

| 槽 | 函数 | 语义 |
|---|---|---|
| [2] | 0x1401807B0 | Connect = 恒真 (主机无须连接流程) |
| [3] | 0x142365280 | Disconnect (断连接对象 + 全局重置) |
| [5] | 0x142367E70 | **入队+定向发送** (盖 tick; 本地命令分配序号入 +240 队列; cmd+24≠0 带目标 → vtable[18] 查连接句柄 → 定向发送; 失败串 "FAILED ... failed to find connection") |
| [6] | 0x1423684C0 | 出队收集 + **首行 +268=a2 直写** + 脉冲按 +232/+228 周期门 |
| [7] | 0x1423686D0 | **成员同步泵**: 全局 +856+16 对象取 Steam 名册 → sub_1423E5B30 逐成员登记 → 与 +272 快照对账 → 尾调 connmgr vtable[3] 收包泵 (server vtable[7] 与 connmgr vtable[3] = 外内两层泵) |
| [13] | 0x142365040 | 清收集链 + 排空 +240 队列 |
| [14] | 0x142366350 | **踢出(原因 19)**: 发 19 号消息 + sub_142250F50 会话侧移除 |
| [15] | 0x142364FE0 | **踢出(原因 20)**: 发 20 → vtable[18] 解析连接句柄 → 关连接 → 会话侧移除 |
| [16] | 0x1423657D0 | 机器表查值 → 描述+32 (缺席 0xFFFFFFFF) |
| [17] | 0x142365A40 | 机器表查值 → 描述+36 端口 (缺席 0xFFFF) |
| [18] | 0x142365B80 | 机器表查值 → 描述+24 连接句柄 (缺席 0) |
| [25] | 0x142365140 | **ConnectionCallback** (network_server.cpp:413) |
| [26] | 0x1423652B0 | **DisconnectCallback** ("Client Disconnected") |
| [27] | 0x1423663F0 | **PackageCallback 收包主泵** (反伪造门 REJECTED SPOOFED COMMAND; 全链 §4.36.3) |
| [30] | 0x142365770 | 废弃槽断言 ("Should no longer happen! ... DispatchOrder") |

机器表 (表基 +168) 64B 桶元素子表: {值域低位 u64@0, dist u8@4, **machine_id 键 u32@8**,
连接记录 48B@16 = {machine_id u32@0, pad@4, 40B 连接描述@8}}; dtor 按桶 dist 清扫。

加密/压缩: CNetworkServer 布局无独立开关域 (负定案) —— 传输加密属 Steam P2P 通道内建。

**CProxyServer** (552B, vtable 0x142B53598, ctor sub_1423690F0; 客户端; 基类域同上):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +216 | pdx vector (20B) | 已发现服务器描述数组 A (元素含 40B 描述; 槽[25]/[26] 读元素+36 端口) | ctor + dtor + 槽直读 (定案) |
| +240 | pdx vector (20B) | 局域网游戏列表 B (元素 40B = {std::string 32B@0, u64@32}) | sub_140B17340 步进直读 (定案) |
| +264 | 链表头 (20B) | 已知服务器大节点链 (**节点 336B = 0x150**; 体 = 308B SServerInfo 拷贝 + **+312 prev / +320 next 链指针** + **+328 延迟删除旗** [链头 +284 字节置位时只打标不摘]; 键域 = SServerInfo 内 {+296 u32, +300 u16} — 行为代码三重证 [双向摘链 + 尾插 ctor + 清理器沿 +320 步进]) | ctor + dtor + 槽[26] (定案) |
| +296 | std::string (32B) | 串#1 (语义待裁, 推定加入请求参数域) | ctor + unwind (形态定案) |
| +328 | uint8 | Update 反门 (槽[6] `if(!+328)` 才跑; 置 1 者族内未见 = 残余待裁) | ctor + 两槽 (定案写读点) |
| +336 | 停表对象* | 全局停表冻结件 (与基 +208 同源) | ctor 直读 (定案) |
| +344 | uint32 | LAN 刷新计数 (槽[11] 递增/清 0) | 槽[11] (定案) |
| +348 | uint32 | **连接状态枚举**: 0=DISCONNECTED / 1=CHECK_LOCAL / 2=CONNECTING / 3=CONNECTED (状态名直印) | 四函数直读 (定案) |
| +360 | std::string (32B) | 串#2 (语义待裁同 +296) | ctor + unwind (形态定案) |
| +392 | uint64 | **主机连接句柄** (Connect 结果; 槽[3] 清 0) | 直读 (定案) |
| +404 | uint8 | 使能旗 (ctor 1; 槽[5] 入队尾清 0) | 直读 (定案) |
| +416 | 停表对象* | Update 停表 (>1.0s 打 "Long update!" 并重启) | ctor + Connect + 槽[6] (定案) |
| +424 | uint8 | KICK_USER(19) 收到旗 (Update → SetState(8) + 断开 + 清旗) | Update 直读 (定案) |
| +425 | uint8 | BAN_USER(20) 旗 (→ SetState(9)) | 同上 (定案) |
| +426 | uint8 | 连接参数旗 (Connect a2 直存) | 直读 (定案) |
| +427 | uint8 | 连接就绪旗 (Connect 等待环退出条件) | 直读 (定案) |
| +432 | tbb 并发命令队列 (16B {vtable@432, 页@440}) | proxy 命令队列 | ctor 直写 (定案) |
| +456 | 原子 int32 | 序号分配器 (初值 1; 回声表键) | ctor (定案) |
| +464 | RH 哈希表头 (32B: 桶@472=静态空 unk_1430BE170, count@480, mask@484, lf@492=0.9) | **回声待答表** (键 = 自分序号 cmd+32, 值 = 时间戳; 槽[27] 自回声摘表) | ctor + dtor + 槽[3]/[27] (定案) |
| +496 | pdx vector (20B) | RTT 样本数组 (元素 8B) | 槽[27] 增长段 (定案) |
| +536 | 16B 子对象 | {SRWLOCK@536, ptr@544} 锁护指针 | ctor 函数体 (定案) |

CProxyServer vtable (31 槽, 关键槽; [14][15] = 空桩):

| 槽 | 函数 | 语义 |
|---|---|---|
| [2] | 0x1423699F0 | **Connect** (proxy_server.cpp:111): SetState(1) → 停表绑定 → +348=2 → 拷 40B 描述 → sub_1423E5CA0 连主机 → +392 → a3 秒等待环 (每轮收包泵 + 查 +427) → 就绪后组包发加入请求 |
| [3] | 0x14236A290 | Disconnect (+348=0 + 断开 + +392=0 + SetState(0) + 回声表清扫) |
| [5] | 0x14236CAC0 | 入队·转发双分支: cmd+24≠0 → 序列化直发 (catch :328/329, 失败 "Failed to post order!"); cmd+24==0 → +456 分配序号 (cmd+28 = cmd+32 同值) → 回声表登记 (SRWLock +536) → +432 tbb 入队; +404=0 为两分支共尾 |
| [6] | 0x14236D250 | **Update** (+328 门 → "Long update!" → 槽[30] → 槽[7] 泵 → +424/+425 处置 → +200=1) |
| [7] | 0x14236D3E0 | 收包泵壳 (= connmgr vtable[3]) |
| [9] | 0x14236CD30 | 按 u16 通道发送 (大厅/浏览器广播域) |
| [10] | 0x14236D210 | 重置 (清列表/停表/连接) |
| [11] | 0x1423696C0 | **LAN 浏览重试泵** ("Local games: Retry...") |
| [21] | 0x14236AED0 | 准入/流控门 `+404 && +400 < a2` |
| [25] | 0x142369FD0 | ConnectionCallback (_PS_* 状态串) |
| [26] | 0x14236A330 | DisconnectCallback (+ 机 id 提取 + +264 链比对) |
| [27] | 0x14236AFE0 | **PackageCallback 收包主泵** (gametype/gamestatus/Tick reset/Game State 等分类; ASYNCHRONOUSLY_CONNECTED = 控制消息 0 MACHINE_ID 伴随日志 :749, 非「消息 6」— 客户端 switch 对 6 走 default 静默; 全链 §4.36.3) |
| [30] | 0x14236A700 | **SendOrders** (排空 +432, 逐条盖 tick/序列化/发主机) |

**CSteamNetContext** (520B, vtable 0x142B6E2A8 24 槽接口型, ctor sub_1423E6D90;
CServer+72; 注册控制台命令 "Print debug info about the networking layer"):

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +8 | uint32 | 1 | ctor (定案) |
| +16..+303 | CCallback ×9 (各 32B) | Steam 回调注册块 (CCallback = {vtable@0, 形态旗 u8@8, 0 u32@12, 属主@16, Run@24}; 注册链见下表) | ctor + SteamAPI_RegisterCallback (定案) |
| +304 | CPdxArray 24B {data@304, cap@312, count@316, alloc@320} | 活跃连接指针数组 (尾插/逆向扫描/memmove 移除; 广播沿倒序逐发, 过滤 = **CSteamID 有效性位域判定** sub_1423E1480 同式 — 连接+4 = steamid 高 32 位, 非业务状态字) | ctor + Send + 泵直读 (定案) |
| +328 | RH 表 32B 内嵌形 {未用@328, 桶 data@336=静态空 unk_1430BF668, count@344, mask@348, extra u8@352, lf@356=0.9} | **连接表 (泵侧)** — 表对象基址 = +328 (insert/find API 实参直证; +320 = +304 数组的分配器槽, 原记表头含分配器系错位); 桶 24B {hash u32@0, dist u8@4, steamid 键 u64@8 (FNV-1a 32 展开 8 字节), 连接记录*@16}; insert 返 16B 对 {桶, inserted u8@+8} | ctor + insert/find + 泵直读 (定案) |
| +360 | uint32 | **最近活动时刻 ms** (ctor 写创建值 + 泵每收一包刷新 = 连接记录 +24 last_seen 复制源; 原记「创建时刻」系单写点误读) | 双写点全查 (定案) |
| +364 | uint32 | 上次泵时刻 ms | 泵刷新 (定案) |
| +368 | CServer* | 所属 server 反指 | ctor (定案) |
| +376 | 函数* | cb1 = server vtable[25] 尾跳 thunk | 字节直读 (定案) |
| +384 | 函数* | cb2 = server vtable[26] 尾跳 thunk | 同上 (定案) |
| +392 | 函数* | cb3 = server vtable[27] 尾跳 thunk | 同上 (定案) |
| +400 | uint8 | **Steam 在线旗** (SteamAPI_IsSteamRunning && ContextInit; Send 先查) | ctor + Send (定案) |
| +416 | RH 表 24B 裸形 {data@416, mask@428, extra u8@432} | **大厅成员表** (16B 桶 {hash, dist, steamid}; byte_143085001 过滤旗开时当白名单, sub_1423E8430 计数源) | 受理判定 + 计数直读 (定案) |
| +440 | RH 表 32B 内嵌形 {未用@440, data@448, mask@460, extra u8@464} | **排除/黑名单表** (16B 桶; 受理判定命中 = 一票否决) | 受理判定直读 (定案; 原记 +448 表头系内联读 data@448 误作基址) |
| +472 | pdx vector (20B) | **待处理 P2P 请求队列** (元素 16B = {steamid u64@0, 登记时刻 ms u32@8}) | 回调 1202 入队 + sub_1423E9F30 消费 (定案) |
| +496 | CPdxArray 24B {data@496, cap@504, count@508, alloc@512} | **待关闭会话队列** (16B 元 {steamid, 到期 = 登记+15000 ms}; 入队 sub_1423EA270 / 消费 sub_1423E9CE0 — 断连后延迟 15 s 关 P2P 会话等缓冲排空) | 入队/消费双函直读 (定案) |

九组 Steam 回调注册链 (定案; 形态旗 0=用户接口 / 2=GameServer 接口, GS 形态处理函数
= 尾跳 thunk 共用用户形态处理体):

| 回调 ID | Steam 事件 | 处理函数 | 引擎消费链 |
|---|---|---|---|
| 1202 | P2PSessionRequest (对端请求 P2P 会话) | 0x1423E99F0 (pdx_net_steam.cpp:1132) | steamid 入 +472 队列 (去重; byte_143085001 = 大厅过滤旗); 消费者 sub_1423E9F30 (:1155): **受理判定 = 排除表 (+440) 不含 ∧ (过滤旗关 ∨ 大厅成员表 (+416) 含)** → Steam 接口 +24 原语接受 + :1149 (受理路体内未见 vtable[25] 直调 — 原记 cb1 (vtable[25]) 待裁); 未列名且年龄 >5000ms → "Rejected deferred P2P session ... (lobby propagation grace exceeded)" 拒绝; 否则留队 (memmove 压缩出队) |
| 1203 | P2PSessionConnectFail | 0x1423E97A0 (:1181) | FNV 查 +328 表 → 读记录 {连接 ID@20/IP@12/端口@16} → connmgr vtable[7] (+56) 单参直调 → :1181 错误串 (错误码 = 事件字节+8); cb2 直调体内不可见 (疑在 vtable[7] 下游, 待裁) |
| 101 | SteamServersConnected | 0x1423E9CB0 | 刷新 SteamInternal 上下文槽 + ContextInit 重建 |
| 102/103/115/143 | 连接失败/断开/GS 策略/认证票 | 0x14012A2C0 (空桩) | 无操作 (注册占位) |

connmgr 关键槽: [3] = 收包主泵 (SteamGameServer_RunCallbacks + 轮询收包 + 拆 4B 头
按通道分派 cb1/cb2/cb3) / [4] = 附着初始化 / [7] = 断连处理 / [8] = **Send** (帧 =
4B 头+载荷; target≠0 单发 / 0 = +304 数组广播; +400 在线门) / [10] = 连接置机 id /
[13] = 查连接 / [14] = 填 40B 连接描述; 其余槽未逐槽定案 (接口型辅助)。

> 备注: 服务器对象可在会话中途整体替换——重连机 sub_1422502F0 析构旧 server 后重新
> malloc 同尺寸构造并回写 session+88 (§4.36.5)。
> 备注: 全局哨兵 off_143085170 = CPdxNewDeleteAllocator 单例 (vtable 0x142716590:
> 槽[1] malloc/槽[2] free), 各容器分配器引用均指它; 静态空桶哨兵 = unk_1430BE0F0
> (64B 桶族) / unk_1430BE170·unk_1430BF698 (24B 桶族) / unk_1430BF668 (泵侧)。
> PDX 哈希表 32B 头族 {引用@0, 桶@8, count@16, mask@20, extra u8@24, lf f32@28=0.9}
> 为 §3.2 RH 表头的网络域变体 (max_load_factor 恒 0.9)。

CSteamNetContext 收发域全案 (pdx_net_steam.cpp 真名 27 站直证, 定案) — 收包泵 = connmgr vtable[3] 0x1423EA960 (1504 行), 发包原语 = vtable[8] 0x1423EA470。

**4B 消息头协议五型** (包帧 = [u32 消息号][载荷]; 双通道 0/1 轮询; 对端 steamid 由 Read 原语带出): 0 = _NET_CONNECT_ (ConnectToPeer 主动连出, 通道 1) / 1 = _NET_CONNECT_ACCEPTED_ (0 号应答) / 2 = _NET_DISCONNECT_ (主动断开应答前发) / 3 = _NET_DISCONNECT_ACCEPTED_ (2 号应答, 通道 0) / 4 = DATA; 收侧全部先按 steamid FNV-1a 32 查 +328 连接表分派 (0 号未命中建记录 + 发 1 号 + cb1; 2 号 = cb2 + 发 3 号 + RH backward-shift 删桶 + +304 数组 memmove 移除 + 待关闭入队; 4 号 = 洪泛记账 + cb3(+392)(ctx, 载荷, size−4, conn, 通道), 未命中丢弃)。

**每 tick 收包预算 1024** (:544 超额留队下轮); **每连接洪泛控制窗** = 1000 ms 滚窗限 1000 包 / 4194304 字节, 滚窗时上窗洪泛则连续计数 +1, **连续 3 洪泛窗 → connmgr vtable[25] (+200) 踢出** (:517)。收包缓冲 = 函数局部静态 CPdxHybridInlineBufferAllocator<unsigned char, 8192, int> (query 判等直取内联缓冲, 超长 ×1.5 上堆)。发包 = pdx_scoped_buffer scratch bump (对齐路 (size+4+7)&~7, 溢出断言 :54 latch byte_14333051E); 大小双门 = >1 MiB 硬限告警仍发 / ≥128 KiB 告警; conn 空 = +304 数组广播 (逆向逐连接过 CSteamID 有效性过滤)。**sub_1423E1480 = CSteamID 有效性判定** (SteamID64 位域: 账户类型 bits 20-23 ∈ 1..10 ∧ universe bits 24-31 ∈ 1..4 + 各类型细分; 体内 0xF00000 系魔数 = 位域掩码非业务状态) — 广播过滤/断开门/入队门三消费。**会话延迟关闭队列** (+496, 元 {steamid, 到期 = 登记+15000 ms}): 断连后延迟 15 s 才关 P2P 会话等发送缓冲排空 — 消费器逐项查连接表 (仍在 → 直出队) / 排除表命中或 bytesQueued == 0 → 立即关 / 否则到期才关。**InitGameServer 0x1423E9590** = SteamInternal_GameServer_Init(0, 8766, 端口, 27016, 2, "1.0.0.0") + 属主全局 qword_1435DA838 + 三 latch byte_1435DA840/841/842。早退门 = a1+400==0 ∨ a2+36 端口==0 → return 1 (不初始化); 入口 a1+364 dword 清 0; init 成功 → context vtable 槽 [6] (obj+48) 后置属主; 语境已存在且属主≠a1 → 仅警告仍 return 1; 三消息 :576 "Failed to initialize Steam Game Server." / :587 "Steam Game Server is not initialized." / :600 "SteamGameServer already initialized in another context."; SteamInternal_ContextInit 入参 = &off_1430BF610。Steam 网络接口六槽: +0 Send (flag 3) / +8 IsP2PPacketAvailable / +16 ReadP2PPacket / +24 会话接受 / +32 会话关闭 / +48 GetP2PSessionState。**连接记录 48B 全表**: +0 steamid (+4 = 高 32 位位域) / +8 连接态 / +12 远端 IP (失败回退 steamid 低 32 位 "using account id as host") / +16 端口 / +20 连接 ID / +24 last_seen / +28..+44 洪泛窗五字段。ConnectToPeer 0x1423E7710 建记录后调 connmgr vtable[22] (+176, 语义待裁) 再发 0 号。
#### 4.36.3 命令网络传输链 (拓扑 / 发送半边 / 包格式 / 接收半边)

**拓扑 (定案)**: 主机权威 client-server 星型 (Steam P2P 传输)。命令执行权唯一归主机
批流——客户端产生的一切命令先上行主机, 主机执行并广播, 各端只执行广播流。时间推进
命令仅主机生成 (session+84 生成权旗, §4.36.1), 随命令流分发, 双 tick 不可能。
ADD_PEER_ADDRESS 仅名册交换, 无客户端互连通道。证据链: 客户端上行单出口 (槽[30]
"Sending N commands on tick T" 全量发主机) / 主机下行全广播 (sub_142365680 在
Execute 前发 target 0 = 遍历全部连接) / 客户端就绪表唯一写入者 = 收包路径 /
ADD_PEER_ADDRESS 处理仅登名册无对连代码 / CCheckSyncCommand 按 machine id 全员比对。

**发送半边**——post 入口 sub_142250B00 (session.cpp:374; 四条件门 §4.28.21b):

| 步 | 动作 |
|---|---|
| 1 | 门: `a3 ∨ session+1941 ∨ cmd 槽[16] ∨ cmd 槽[12]`; 不过则 "Dropped command: " 就地析构返 0 |
| 2 | 盖 `cmd+12 = session+164` (本机 machine id); `cmd+22 = min(session+128, 0x7FFF)` (批号戳) |
| 3 | server 槽[5] (session+88 对象)——三型分叉见下表 |

三型 server 槽[5] 分叉 (定案):

| 类 | 行为 |
|---|---|
| CDummyServer | **单机也走完整序列化回路**: 原子 +240 分配序号写 cmd+28/+32 → 序列化 → 对全局注册表 (qword_1435B9CF8/dword_1435B9D04) 逐 server 反序列化副本入其队列 → 销毁原对象 (执行对象永远是序列化重建的副本 = 确定性设计) |
| CNetworkServer (主机) | 普通命令 (cmd+24==0): +264 分配序号 → 入 +240 tbb 队列待批; 定向命令 (cmd+24≠0): 立即序列化直发目标连接 ("Sending targeted asynchronous command") |
| CProxyServer (客户端) | 普通命令: +456 分配序号 → 登记回声待答表 (+464, 键=序号) → 入 +432 待发队列 (**不本地执行, 等主机回声**); 定向命令直发主机 (连接 0) |

序列化器 (post 定向路径 / CDummy 全路径 / 执行期广播三处同款): std::string 缓冲 →
CMemoryFile (0x58B) → CWriter (存档同款 token 写器) → sub_1424C2E20(writer,
GetTypeId, cmd) = {type_id, version=1} 两键值 + Save wrapper 全量落流。执行期广播
sub_142365680 (network_server.cpp:751): 门 session+80 ∈ {2,4,5} (网络角色枚举) →
序列化 → sub_1423E6490(connmgr, 0=broadcast) —— **先广播后 Execute**。

**包格式**——传输帧 (connmgr 槽[8] Send):

| 字段 | 位置 | 类型 | 语义 |
|---|---|---|---|
| 头 | 帧首 4B | u32 | 恒 4 (推定 = 用户消息类型标记, 收侧剥离) |
| 载荷 | +4 | bytes | channel 0 = 命令体 / channel 1 = 控制消息 |
| channel | 发送第 5 参 | u8 | 0 = 命令通道 / 1 = 控制通道 |
| target | 发送第 2 参 | 连接 | 非空 = Steam P2P 单发; 空 = 广播 (遍历 connmgr+304 连接数组按状态位过滤) |
| 长度上限 | — | — | len+4 ≤ 1 MiB; ≥ 128 KiB 走另一发送分支 |

命令体 (channel 0 载荷; CWriter token 流, 与存档同机制):

| 顺序 | 键/形态 | 内容 |
|---|---|---|
| 1 | 键值对 | type_id (槽[11]) |
| 2 | 键值对 | version = 1 |
| 3 | 键 499 | 嵌套对象 SInternalData (16B) |
| 4 | 键 65 (列表头) | 逐字段: 派生类槽[22] 载荷 writer 发射; 收侧槽[23] 按 token 派发 (哨兵 4/19 收束) |

SInternalData 字段子表 (writer 直证):

| 源偏移 | 类型 | 语义 |
|---|---|---|
| +12 | uint32 | 发送方 machine id (post 盖; 防伪造校验键) |
| +22 | uint16 | 批号戳 tick |
| +24 | uint8 | 定向旗 (≠0 = 定向命令) |
| +28 | uint32 | **identity 序号** (主机侧分配; 命令日志顺序键) |
| +32 | uint32 | **origin 序号** (发送侧分配; 客户端回声/RTT 配对键; 主机转发时保留) |

> 备注: §4.00.7 的 +28/+32 语义细化为 identity/origin 双序号; 定向命令目标寻址在
> cmd+16 (u32 machine, 槽[18]) / cmd+20 (u16 辅, 槽[19])。

控制消息 (channel 1; 8B = {u32 type, u32 value}, 打包 sub_142363E40; 类型名直取
主机 PackageCallback 字符串表):

| 值 | 名称 | 语义 |
|---|---|---|
| 0 | MACHINE_ID | 分配的机 id (主机侧处理 = 新机器接入链 sub_142368240; 客户端置 session+164 + SetState(5)) |
| 1 | SERVER_ADDRESS | 继任者连接描述+32 地址标识 (server+220==0 时 = 新客 desc+32; 客户端写 session+100 镜像) |
| 2 | ADD_PEER_ADDRESS | 已在场机 id (双向名册交换; 客户端仅登 session+136/+144/+152) |
| 3 | REMOVE_PEER_ADDRESS | 机 id |
| 4 | SERVER_TICK_VALUE | 当前批号 (客户端硬重置 session+128, "Tick reset to N") |
| 5 | SERVER_TICK | 提交后的批号 (主机每批广播自增前值; 客户端锁步: 缓存==值 → ++session+128, 否则硬追) |
| 6 | MESSAGE_DROPPED | — |
| 7 | NAMED_SUCCESSOR | 机 id (==本机 id → session+96=1 继承者标记, §4.36.5 主机迁移) |
| 8 | REQUEST_ID | 接入请求 (含密码 token 222) |
| 9/10/11 | RECONNECTED / RECONNECT_DONE / RECONNECT_REFUSED | 重连握手 (客户端 11 → SetState(7)) |
| 12/13 | REQUEST_TYPE / REQUEST_TYPE_VERSION | — |
| 14/15/16 | REQUEST_HOTJOIN / HOTJOIN_ACCEPTED / HOTJOIN_DECLINED | 热加入协议 (15 → SetState(13)+1940=1; 16 → SetState(15)) |
| 17 | SESSION_TYPE | session+80 网络角色枚举下发; 客户端 LAN 发现支另作 "Got gametype" 消费 (+288, 方向语义待裁) |
| 18 | GAME_STATE | 大载荷 (gamestate+日志流; 客户端存 session+400 → SetState(6)) |
| 19/20/21 | KICK_USER / BAN_USER / BANNED | 踢出协议 (客户端 +424/+425 → SetState(8/9) + 断开) |
| 22 | APPLICATION_MESSAGE | 大载荷 |
| 23/24 | GAME_NAME / GAME_STATUS | — |
| 25 | REQUEST_GAME_INFO | 主机回 17 + 24 + 308B 结构体直发 |
| 26..35 | VERSION_CHECK / INCORRECT_PASSWORD / NAME_TAKEN / HOTJOIN_DECLINED_BUSY / HOTJOIN_DECLINED_NAMECONFLICT / REQUEST_PASSWORD / HOTJOIN_DECLINED_DISABLED / DECLINED_JOIN_DISABLED / NAME_INVALID / VERSION_MISMATCH | 大厅/准入域 (流程 §4.36.7) |

**接收半边**——传输泵 connmgr 槽[3] (SteamGameServer_RunCallbacks + 轮询收包 + 拆
4B 头按 channel 分派 cb1/cb2/cb3 = server 槽[25]/[26]/[27])。主机侧 CNetworkServer
槽[27] PackageCallback:

| 步 | 动作 |
|---|---|
| 1 | channel 0: sub_142269960 反序列化 (CMemoryFile → lexer → reader → 读 type_id → 工厂 → Load wrapper 填对象) |
| 2 | 防伪造: 连接实际机 id ≠ cmd+12 → "REJECTED SPOOFED COMMAND!" 丢弃 |
| 3 | !IsValid → "COMMAND LOST! Sent: <cmd+22> Received: <session+128>" |
| 4 | 机器表**只查找**发送者 (登记仅发生在接入链; 未登记发送者的命令静默丢弃无日志) |
| 5 | cmd+24 → 定向表 (**+120 链**); 否则重盖本地序号 cmd+28 = InterlockedAdd(server+264) (+32 origin 不动) → 就绪表 (+144) → 下一泵执行+广播 |
| 6 | channel 1: 控制消息 switch (上表); **主机消费集仅 {8, 9, 14, 25}**, 其余 0-35 全记 "Unknown message received"; 8/9 → 新机器接入链 (对既有机器逐台发 ADD_PEER_ADDRESS → 新机登机器表 → 广播 → NAMED_SUCCESSOR → SERVER_TICK_VALUE 定向新客 → 置连接机 id → ++server+224; **9 RECONNECTED 与 8 同走 +268 门但绕过准入五闸** = 重连免检; MACHINE_ID(0) 是链的**输出**非输入) |
| 7 | 反序列化失败 → "COMMAND UNKNOWN!" |

工厂 sub_142269AD0 (order.cpp:273): **id ≥ 10000 先减 9000**; 表 = funcs_142269B19
(11008 槽 ctor 指针数组 funcs_142269B19, 上界 id ≤ 0x2AF7); 未知 id → CLogStream level 3 一行式错误日志 (order.cpp:273 "Couldn't find command " + 名串) + :274 断言 (旗 byte_1435E1B51 / 闩 byte_143468B40) + **返 0** (上游 0x142269960 拿到 0 仅跳过 vt[3] Load, 命令被丢弃; 体内 terminate 系 ostream 构造 EH 胶水, 非 throw)。名串经 **sub_14206CDC0** = token 描述符表线性查找 (表基 unk_14338D170, 条目 72B {id u32@+0, 名 ptr@+8, 名长 u32@+20}, 末界 byte_14344A518, 未命中断言 "no token??" hoi4_tokens.cpp:10829)。**反序列化总装 0x142269960 九步流水**: CMemoryFile (sub_1424EDFC0, 24B+72B) → CLexer (sub_1424BB040, 112B) → CReader (sub_1424BED40) → GetKeyEqualsValue (sub_1424C1540) → reader+32 错误旗 → "Error creating command" (:292) → type_id = reader+48 → 工厂 sub_142269AD0 → token 名回填 CMemoryFile+24 → cmd vtable[3] Load wrapper (sub_1424C0AA0, §4.00.1)。
命令日志链表读端 sub_142269C60 = 循环 {读 token; 4/19 收束; 读 id → 工厂 → Load}。

客户端侧 CProxyServer 槽[27]: channel 1 按控制消息表处置 (SERVER_TICK(5) 锁步:
`缓存(proxy+356)==值 → ++session+128; 否则硬追`); channel 0 命令按会话状态三分流:
state==5 → "COMMAND BEFORE SYNC RECEIVED" 暂存 +96 链 / state==6 独立 EARLY 支 →
cmd+24 定向旗=1 入定向链 +120/+128/+136, 非定向入 +96 链, 日志 "EARLY COMMAND RECEIVED" :653 (与 VERY EARLY 不同支) / 其余非五值集 {2,4,12,13,14} → "VERY EARLY COMMAND RECEIVED" 同表 / state∈{2,4,12,13,14} → 就绪表 +144 (与主机同构,
泵经共享槽[8] 消费)。自回声: cmd+12==本机 id → 按 cmd+32 摘 +472 待答表 →
now−时间戳 入 +496 RTT 数组。

> 备注: session+128 = **命令流批号 (lockstep 计数器)**, 非游戏小时 (gs+1128 另计);
> 主机每批 (泵每轮) 自增并以 SERVER_TICK(5) 脉冲广播, 客户端由脉冲锁步/硬追, 入场时
> SERVER_TICK_VALUE(4) 硬对齐。批号入 cmd+22 (u16 截断); 接收端用途 = 陈旧检测
> (COMMAND LOST 日志并列 Sent vs Received) + 日志重放顺序校验。
> 备注: session+80 = 网络角色枚举 (Init a4 直写; 广播门 {2,4,5}; SESSION_TYPE(17)
> 下发), 逐值角色映射待裁 (2 = 主机高置信)。
> 备注: 主机侧热加入打包函数 (gamestate+日志 → GAME_STATE 载荷) 待裁, 疑走大厅文件
> 分块通道 (§4.36.9); 收侧全链已定案。

#### 4.36.4 时间 / 暂停 / 速度的联机契约

时间生成权: tick 生成门 sub_1401F0590 = `session+84` (§4.2.2 步骤 5) —— Init 按
type∈{1,2} 置位 = **主机/单机才生成 CHourlyTickCommand**, 客户端从广播流反序列化
获得 (含 91 槽 checksum 载荷, §4.36.10)。⚠ server+84 无独立字段——它是 server+80
QWORD 会话反指的高 4 字节, 判定实为 **CSession+84 = 时间生成权旗 (本地权威门)**:
唯一写点 Init sub_142250890 `+84 = (a3−1)<=1`, 读者 = tick 生成门与调速命令发送侧
sub_140DD6930。

暂停双轨 (4 个独立站点复现, 全走 P1):

| 站点 | 判定 | 语义 |
|---|---|---|
| (未决) | `!MP && !paused` | 直调 app 槽[94] 暂停 toggle —— 单机直翻; ⚠ 原记 VA sub_140FD42D0 系误记 (真身 = CIdea::FinalizeIdeas, idea.cpp:791/816 日志 + gameitemdatabase.h:142 断言直证), 第一站真实 VA 待重定 |
| sub_140FFB2D0 | `!paused && !MP` | 直调 app 槽[71] 锁定式 toggle —— 单机直翻 |
| sub_141313860 | `!MP` | 直写 idler+1729 = 1 (强制暂停) —— 单机才直写 |
| sub_142390340 (CPauseGame::Execute 域) | `MP` | 联机不直翻, 构造 CPauseGame 广播 (§4.33 已载) |

速度域: 速度命令发送门 sub_140B07D60 = `!MP ∥ session+84` (单机直发 / 联机须局已
开始); idler+2396 联机卡顿重试计数 sub_1412073E0 = `!MP ∥ session+84` (>12 发网
清零, §1.1b slot[95] 互证)。

掉队降速/暂停链 (每小时, CHourlyTickCommand::Execute 内): 逐玩家比对水位 (条目 =
gs+248 数组 160B/条 {计数@260}; **+152 = machine id ≠ 本机 machine id 才参与**;
**+128 = u32 日期水位**, 写者 = CClientPingCommand::Execute sub_140F05D80; 本机基准
= gs+1128 折天): 差值 > **LAG_DAYS_FOR_LOWER_SPEED = 10 天** (dword_1433361D0) 且未在本日
告警 (dword_14333D3D8 记忆日) → "LAG_DECREASE_SPEED" 聊天通报 + gs+1212>0 时降速
(速度>0 走 idler 槽[95] 每 13 次节流发 CDecreaseGameSpeedCommand(10456); 速度=0 发
CPauseGame(10732) 带玩家名条件 toggle——30 秒/原因串匹配才翻); 差值 >
**LAG_DAYS_FOR_PAUSE = 25 天** (dword_143336270) → "LAG_PAUSE" 通报 + 直接暂停
(未暂停才发; 按日去重 dword_14333D3D4)。CClientPingCommand (id **11376**, vtable
0x1427217E0): 每小时每机构造 {cmd+48 = 当前日期, cmd+64 = 本地国 tag, cmd+68 =
本机连接信息 (server 槽[28] 值)} 投递; Execute 写条目 +128 (日期水位) / +144 (连接
信息); Execute 门 session+72≠13; 日期只比不写 = **心跳+进度滞后监测, 非日期同步**。

> 备注: 掉队链的联机性由 CClientPingCommand 的存在保证——单机亦每小时构造 (载荷 =
> 自身), 恒不触发差值告警。
> 备注: OOS checksum 对比为 hourly 步骤 8 的 P1 分支, 管线与 91 槽语义归 §4.36.10;
> 热加入等待档客户端不推进时间 (session+72≠13 门) 归 §4.36.6。

#### 4.36.5 掉线 · 断线重连 · 主机迁移

**断线如何被发现 (客户端侧, 定案)**: 主路 = CProxyServer::DisconnectCallback 槽[26]
(proxy_server.cpp:465): 连接状态 (+348 枚举) ≠ CONNECTING → 日志 **"Server lost!"**
→ **session+1968 = 1** + 连接重置; 辅路 = 状态 == CHECK_LOCAL 分支为 P2P 网格 peer
掉线 (只摘 peer 不动会话); 底层 = Steam 回调 1203 P2PSessionConnectFail ("Lost
connection. Steam P2P Session Connect Failure") 触发上述链。session+1968 的另一写者
= CGameLobby 玩家加入处理器 sub_140DA1A40 (人控国 ≠ 本地 tag 的玩家加入 → 置 1) ——
热加入/重 join 复用同一触发旗。+1968 消费 = CSession::Update 两处: 清旗 → 观察者广播
事件码 3 → **重连机 sub_1422502F0**。

Update 状态路由 (§4.28.21b 位集 {2,4,13,14} 才走命令派发主循环); state 8/9
(KICKED/IS_BANNED) Update 直接 return 0 (停摆待 UI); state 7 → 观察者广播 2; state
12 只泵 server。

**重连机 sub_1422502F0 三分岔** (函数体直读, 定案):

| 门 | 路 | 步骤 |
|---|---|---|
| session+1056 == 0 | 无动作路 | 仅观察者广播 13。⚠ +1056 全语料无置 1 写者 (Init 与 sub_142252660 均清 0)——负发现, 语义待裁 (形态 = 重连机总门) |
| +1056≠0 ∧ session+96≠0 | **主机重建路 (§主机迁移)** | 观察者广播 4 → session+84=1 → 快照旧成员链 (+136/+144/+152) → 销毁旧 server → 建 40B 连接描述 → **重建 CNetworkServer** → 反复泵等旧成员逐个重新登记 (计数窗) → 未归成员进 session+168 掉线名单 + 广播 5 → 全归后 session+72 直写 4 (CONNECTED) |
| +1056≠0 ∧ +96==0 | **客户端重连路** | state 直写 0 → 清 +136 链 → 销毁旧 server → **重建 CProxyServer** → **2 秒墙钟窗**反复 Connect → 成功走 join 握手续行; 超时 → state 直写 3 (RECONNECTING_FAILED) + 广播 13 |

重连握手与进度追赶 (与全新 join 共用同一通道): Connect → state 1 → 收 MACHINE_ID(0)
→ 记机 id → SetState(5 WAITING_FOR_GAMESTATE) → 主机 SendGameState (槽[29]: session+328
门 → GAME_STATE(18) + 协议号 203 + session+312 命令日志逐条序列化) → 客户端收 18 →
session+400 = 载荷 → SetState(6) → RequestSynch 反序列化重放追进度 (§4.36.6)。
重连专用消费: **SERVER_TICK_VALUE(4)** 值域且 state==2 → SetState(4) (重连被接受的实际信号); **SERVER_TICK(5)** / RECONNECT_REFUSED(11) 且 state==2 → SetState(7 REFUSED) — proxy 批 switch 直证。
state 2 (RECONNECTING) 的置位者未在语料命中 (待裁)。

**主机迁移存在 (高置信, 引擎层全自动无 UI 参与)** —— 五环证据链:

| 环 | 定案 |
|---|---|
| 继任指定 (主机在位时) | 新成员接入链 sub_142368240: server+220 (u16 继任 tag) == 0 时 → **继任 = 该新成员** (即首个加入者), 向其发 NAMED_SUCCESSOR(7) + SERVER_ADDRESS(1) |
| 继任维持 (成员掉线时) | CNetworkServer::DisconnectCallback 槽[26]: 掉线者 == server+220 → 从其余成员挑一 → sub_142366390 重指 (发 7 + 更新 +220 + 发 1) → 广播 REMOVE_PEER_ADDRESS(3) |
| 继任旗落位 (客户端) | 收 7 且值 == 本地 tag → **session+96 = 1** (该旗唯一运行时写点; Init 清 0) |
| 主机真掉 → 分岔迁移 | "Server lost!" → +1968 → 重连机: 继任者 (+96=1) 走主机重建路 (本机重建 CNetworkServer 等成员重登记); 其余客户端走客户端重连路 (Connect 到 SERVER_ADDRESS 指向的新主机地址) |
| 未归队处置 | 计数窗内未重登记成员进 session+168 名单 → 广播 5 (按掉线处理) → 清名单 |

待裁两项 (不推翻结论): a) 总门 session+1056 无置 1 写者; b) 主机「优雅退出」时是否
显式指定继任未决 (sub_142366390 仅接入/掉线两调用点, 退出路径未观察到发 7)。若迁移不可用
(+1056 恒 0 场景), 主机消失后各客户端 "Server lost!" → 重连机无动作路 → UI 回菜单;
游戏不继续 (主机即权威, 权威消失 = 会话终结)。

踢人/禁人全链 (主机主动, 定案):

| 步 | 环节 |
|---|---|
| 1 | CPlayerLobby KickPlayer/BanPlayer lambda (§4.00) 打开 CConfirmKickBanPlayerDialog (+4152 动作对象, 置 1 写者待裁) |
| 1a | **弹窗设置 0x141E59B60 (confirmkickbanplayer.cpp:24, 高置信)**: (a1 弹窗, a2 玩家名串, a3 动作, a4 回调) — a3: 0 = kick / 1 = ban / 其他 → "Undefined ActionType" 断言且不加正文; 本地化四键 = MULTIPLAYER_LOBBY_PLAYER_{KICK,BAN}_CONFIRMATION (正文, NAME 占位 = 玩家名) / MULTIPLAYER_LOBBY_PLAYER_{KICK,BAN}_TITLE (标题); **回调存储 = a1+512 内联缓冲 (4096B) / a1+4152 大 functor 堆指针** (先虚 vt+32 释放旧值再赋新); 尾 sub_140B82510 + vtable[9] 刷新/显示; 纯 UI 层不触网络/会话 |
| 2 | OnAccept 0x141E59B30: dialog+4152 非空 → 调其 vtable+16 (空则 fatal); 动作闭包触发 server 踢人槽 (高置信) |
| 3 | CNetworkServer 槽[14]: 发 KICK_USER(19) + sub_142250F50 会话侧移除 |
| 4 | CNetworkServer 槽[15]: 发 BAN_USER(20) → 机器表删 → 关连接 → 会话侧移除 |
| 5 | 被踢端 PackageCallback: 19 且目标==本地 → proxy+424=1; 20 → proxy+425=1; 目标非本地 → 本地名册同步移除; 21 BANNED → 直接 SetState(9) |
| 6 | CProxyServer::Update: +424 → SetState(8 KICKED) + 断开 + 清旗; +425 → SetState(9 IS_BANNED) |

会话成员摘除 sub_142250F50: +136/+144/+152 机器 id 链摘节点 (两遍式, 节点+24 延迟
删除旗), 同时把 id 追加进 **session+168/+176/+184 已掉线成员名单** (头/尾/计数);
名单消费 = 重连机与观察者。

> 备注: §4.2.3 步骤 3 的「超时掉线」链不是踢人——是掉队降速/暂停滞后处理
> (§4.36.4); 真正的断线检测在 server 层 Steam 回调, 真正的踢出在 CPlayerLobby UI 链。

#### 4.36.6 热加入 (hotjoin)

主机侧状态机与分派 (§4.28.18/§4.28.21b 已载: nNumOfHotjoins 分派 / CReopenLobby /
Resync / RequestHotjoin 双旗) 不重复; 本节补客户端全链 (定案):

| 步 | 环节 | 定案 |
|---|---|---|
| 1 | 客户端请求 | ConnectToGame 装会话 + SetState(12); RequestHotjoin 0x142251120: `*(WORD*)(session+1854) = 257` 一次写 **+1854=1 与 +1855=1** (+1854 = 热加入当前态, +1855 = 粘滞「曾开热加入」; 独立 setter = SetHotjoin sub_142252520) → 组 REQUEST_HOTJOIN(14) 消息 (键 11=id / 27=name / 226=user) → server 槽[4] 发送 → state 直写 12 → 立即泵一次 |
| 2 | 主机批准 | 收 HOTJOIN_ACCEPTED(15) → SetState(**13 HOTJOIN_WAITING_FOR_SAVE**) + session+1940=1 + +1856=0; 13 态即 CHourlyTick `≠13` 门 = **不推进时间** (§4.2.3) |
| 3 | 主机拒绝 | 收 16/29/30/32 → SetState(15 HOTJOIN_REFUSED) + +1940=0 + **+1856 = 拒绝码** (0=declined / 1=busy / 2=nameconflict / 3=disabled); 33 DECLINED_JOIN_DISABLED → state 18 |
| 4 | 存档流传输 | 主机 largefile 通道分块发存档; 客户端 CChunkReceived(307) 接收, 收齐 → "Done with received N chunks. Creating save file.." + "Total time to transfer file: X seconds." → 落盘; CGameLobby+1204=1 (MP gamesetup 文件传输) 即此阶段 (传输链细节 §4.36.9) |
| 5 | 客户端装载 | 落盘后走常规读档链 (§4.28.17) → 进大厅态 14 HOTJOIN_IN_LOBBY (⚠ 置位者未在语料命中——SetState 调用点与 +72 直写均无 14, 待裁; Update 主派发位集含 14, 态本身真实) |
| 6 | 主机收尾链 | CReopenLobbyCommand (11467, "HOTJOIN_STARTING!", 清国控旗+重置 gamesetup+重加玩家) → CRequestGameStateSynchCommand (11438, Resync 校验和) → sub_141875860 (HOTJOIN_PENDING_REQUEST_BLOCK 门: gamesetup+124 无 pending 块才放行) → CPostHotJoinCommand (11504, 按 human_controlled_countries/disabled_countries 重排控制权) → CReadyAfterHotJoinCommand (11469, "Waiting for other players." 栅栏) → sub_140DA1020 ("HOTJOIN_ENDING!" + SetState(4) + net "running") → 正式入局 |

命令日志重放 (热加入者追进度的引擎核, RequestSynch 0x142251420, 门 `!+1852 ∧
!+1969 ∧ state==6`):

| 步 | 动作 |
|---|---|
| 1 | session+400 (GAME_STATE 载荷缓冲, 去 8B 头) 为空 → SetState(4) + 泵 + "Connected with previously empty gamestate" |
| 2 | 否则 CMemoryFile → lexer → reader → sub_142269C60 重建 +312 命令日志链表 (与线上命令同一反序列化单元) |
| 3 | "Executing N logged commands." 顺序重放: identity(+28) 严格递增校验 (违者 "COMMANDLOG OUT OF ORDER!") → IsValid → Execute/Discard, 全程 +1852=1 防重入 |
| 4 | **每 5 条插一次命令泵** (帧保活) |
| 5 | 尾: server 槽[19] 定向表条目并回 +312 → SetState(4 CONNECTED) → 泵 |

单机热加入: 全部会话命令 (含热加入 UI 流) 经 CDummyServer +216 队列环回执行不触网络
(§4.36.2); 单机 toggle sub_1418AD500 = state 12↔13 直翻 (**无 SetState 广播、无语料
调用者** = GUI 按钮 vtable 派发回调), 翻到 13 让单机也吃「不推进时间」门呈现等待态。

#### 4.36.7 Steam 大厅与开局准入

大厅对象族: 核心 = **CSteamMatchmakingContext** (784B 单例, 挂 `*(CGameApplication+856)+16`,
46 槽vtable, 9 个 Steam 回调/CCallResult; 基类 CMatchmakingContext 全纯虚); 浏览器 GUI =
CMatchmakingGui / ServerItem / FriendItem (RTTI); 大厅句柄 = context+440 的 SteamID; **CMatchmakingGui::RefreshInternetServers = sub_14231B4C0** (§4.36.13)
房主房间设置块 = context+112..+383。ISteamMatchmaking 调用形态直证 (CreateLobby /
RequestLobbyList 族)。

建房链 (定案): ServerAnnounce (槽[28] 0x1423E3960) 按 context+348 可见性枚举映射
CreateLobby / 复用旧厅 (0=Public / 1=Private / 2=FriendsOnly) → OnLobbyCreated 内
SetLobbyGameServer + **一次性全量发布十个 lobby data 键**: name / desc / mod /
password / tags / version / checksum / join_phase / status / actual_password;
join_phase 由 sub_140DA0A40 / sub_140DA1020 两写点推进 lobby→starting→running
(与热加入收尾 sub_140DA1020 同函数)。

密码流 (**全程明文**, 定案): 房主密码存 gamesetup+480 并以 `actual_password` 键随
大厅数据公开 (客户端未入厅即可读到「有无密码」); 客户端把密码放 REQUEST_ID(8) 包
token 222 上送, 主机侧 gamesetup+480 纯 memcmp 比对, 不符回 INCORRECT_PASSWORD(27)
→ 客户端 SetState(17 BAD_PASSWORD)。

版本校验 (**双闸**, 定案): ① 客户端预检——ConnectToGame 比对大厅 `checksum` 键 vs
本地 appmgr+352 串, mismatch 不发包直接走; ② 主机闸——REQUEST_ID(8) 包 token 377
vs 同款构建器 sub_1406ECFE0 串, mismatch 回 VERSION_MISMATCH(35) → SetState(16
BAD_VERSION)。比对对象 = 版本+mod 构建串, 非存档 checksum。

主机准入闸顺序 (各拒绝态写点全定): **ban → 名无效(NAME_INVALID 34) → 名重
(NAME_TAKEN 28) → 密码(INCORRECT_PASSWORD 27) → 版本(VERSION_MISMATCH 35) → 收下**;
另有 DECLINED_JOIN_DISABLED(33) → state 18 STATE_JOIN_DISABLED。收下后走新机器接入链
(§4.36.3 MACHINE_ID 处理)。

邀请加入链: Steam 回调 333 GameLobbyJoinRequested → FetchLobbyInfo → 注册回调进
ConnectToGame; InviteUserToGame / RichPresence 语料零命中 (邀请走 Steam 大厅原生
机制, 推定)。

CSetGameUniqueId (15237): Execute = 0x140DE9C10 (⚠ §4.33 记 0x140DE9E80 系槽位
错配——那是 IsValid), 唯一动作 = 32B 身份串写 **gs+1832 (game_unique_id)**,
writer/reader 只走 token 11; 走普通命令流广播/热加入日志重放, 使全员 gs+1832 同值。

#### 4.36.8 观察者模式与合作操控

**观察者无独立状态位 (定案)**: 判据 = **gs+1312 ≤ 0** (§4.17 alert_is_observer 即
此; 该偏移唯一连写者 = SetPlayerCountry 核 sub_1401EE7F0 写 0), 成为观察者时
CHuman.tag 同步落 0。

成为观察者的四入口 (全部汇入切国命令族):

| 入口 | 链 |
|---|---|
| 大厅 observer_button | 提交 tag 0 → CChangeCountryControllerCommand{country=none(0)} |
| 游戏内切换 | sub_141DED420 → 同上命令族 |
| 控制台 `observe` | sub_14026DC30 (成功 → gs+1328 清 + 旗清 0; 失败 → "Could not become observer") |
| 控制台 `play` 系 | sub_1412A9560 (play 切国执行体) → CSetCountryControllerCommand(10707) |

Execute 侧: CSetCountryControllerCommand::IsValid (sub_140CEE530) 门 = 目标国已被
他人控制 ∧ coop 关 → 拒绝 (「已开局后大厅指派被拒」门 = CHuman+148 bit2 已开局旗,
CStartGameCommand 置位) → SetPlayerCountry 核 sub_1401EE7F0 写 gs+1312。

运行时差异: 旧国 AI 替跑 = 纯谓词推导 (CHuman 脱钩 → 「有 human 控制」假 →
sub_140E49A40 假), 与 human_ai 旗 (byte_14332F639) 正交; 45 个 `gs+1312<=0` 分支中
情报/控制者揭示门 5 站以「观察者 ∥ 情报门」并联全量放行 (观察者看穿 fog/intel);
CStartGameCommand::Execute 的铁人位清位精确条件 = **观察者开局** (新局清 gs+192
bit0 的真实语境); 全局字节 byte_14332F60B = 「play 系自动建的无开局 Human」辅助标记
(推定), 非 is-observer 本体。

**coop (合作操控) 负定案 (加强)**: gs+192 bit2 = 纯死位——存档键 `cooperative_game`
(token 13916) 写侧源头 = **CSession+646** (CSetCoopHotJoinOptions 13465 的 Execute
sub_14163D3A0 写入, 写时恒 1), 读侧 loader case 13916 直接跳过不落任何字段。
**coop 真载体 = 多 CHuman 绑同一国 tag** (CSetCountryControllerCommand::IsValid 的
session+646 放行门即 coop 开关), 无独立运行时位。

**MP_locked_countries = loader-only 死数据**: gs+1648 u32 向量 (计数@+1660) 由
loader case 11572 按 gs vtable[9]=gs+796 国家数扩容读表; token 11572 无写者、向量无运行时
读者 (兼容残留)。运行期「锁国」由 CSetCountryControllerCommand::IsValid 的「目标国
已被他人控制且 coop 关 → 拒绝」+ 大厅国列表门 cc+1156 (owned_states) 承担, 无独立
锁国命令族。

#### 4.36.9 MP 存档传输与重开局 / 结束局

**CLargefileHandler** (240B, clausewitzlib largefile.cpp; 无独立序列化指纹——书 §4.28
CID 对 {type 225, id 11} 即其身份件): 大文件传输状态机。主机把存档按 **16KB 切块**,
以三会话命令流水发送 (命令行 §4.33.2):

| 步 | 命令 | 语义 |
|---|---|---|
| 1 | CStartFileTransfer (305) | 传输通告 (文件名/总块数) |
| 2 | CSendChunk (306) | 数据块 (**8 块在途滑窗, 无应用层重传**) |
| 3 | CChunkReceived (307) | ack 带定点进度 ("received chunk ... progress") |

收端 CID 解析组装进 handler+96 缓冲, 收齐 → "Done with received N chunks. Creating
save file.." + "Total time to transfer file: X seconds." → 落盘 → 走常规读档链。
CID 注册句柄 = lobby+8 视图; CGameLobby 覆写接口槽 [10] Ack (**实名 CGameLobby::IncomingFileChunkAck, 体内日志串直证**; 体 = 块收妥 ack + Human 匹配, "Already/Failed to find Human for " 两分支) / [11] 收档校验 /
[12] GetSession (vtable 0x1429672D8 / 0x142B48D08 RTTI)。热加入时主机按
**lobby+256 待传输队列** (24B 节点 {machineid@0, handler@16}, 键 = human+152) 逐客
分发; 挂起旗 = lobby+244。与 GAME_STATE(18) 双通道并存: **热加入先经 largefile 收
整档, 后经 GAME_STATE (协议 203 + 命令日志增量流, §4.36.3) 追命令**。

传输阶段 (CGameLobby+1204=1) 全貌: 只传当前局存档一个文件 (进 lobby+232 内存缓冲);
大厅设置走命令级联 (§4.28.18)/replay 旗 +1219, mod 文件未见传输路径 (待运行期验证);
+1213 = 客户端全块收妥旗, 收完双落到 +1214=1。

**重开局链 (rehost)**: +1152 请求 (GUI 回调唯一写者 sub_140D9BB90, 双 idler 门) →
打包转移描述符 + +1204=2「重开中」(sub_140D9F630) → attach 派发置 +1218
(sub_140DA3A40 三分支) → 下帧自毁大厅 + ConnectToGame 正常握手重入 → 复用热加入链
(ReopenLobby → Resync → PostHotJoin → ReadyAfterHotJoin 栅栏, §4.36.6), 名册按玩家名
匹配回绑。

**结束局流**: 主机优雅退出 = 前端离开钮 sub_140D99A90 摘大厅 + 会话收尾 → 回服务器
浏览器 (sub_141CE7910/7620), 其余端走 "Server lost!" → 继任迁移 (§4.36.5) 或回菜单;
任一端退主菜单 = EXITING_TO_FRONTEND 序列 (退出自动存档 → +1904 第二大厅 → gs 摘除
→ FE idler 换装)。

**MP 存/读档差异 (定案)**: 自动存档 = 到期判定端广播 CAutosave(105) (§4.33 已载),
Execute 一行转 idler vtable+728, **各端各自本地写盘**; 读档 = **仅主机发起** (选档
sub_141CE7440 → +1204=1), 存档经 largefile 分发各端落盘后各走常规读档链 (§4.28.17)。

#### 4.36.10 同步与确定性 (OOS 91 槽契约)

命名空间 **NGameSynchronizationHelper** (tbb lambda 符号直证 CalcChecksums\<CPdxHasher,
CSimpleBitMask, ...\>); 逐项日志域 = gamesynchronizationmanager.cpp; 比较域 =
gamestate.cpp:4744-4795; 弹窗域 = ingameidler.cpp:1067/1078。**槽名权威 = 本地化键
OOS_0..OOS_90** (multiplayer loc, 全 91 键在案; 取名经 sub_142245E60 以 "OOS_"+槽号)。
哈希核 = MurmurHash3 x86_32 流式 (update sub_1424ED930 / finalize sub_1424EDA70, 总
字节数参与混合 → 走访次序本身是契约)。本端数组 = qword_14333CEA8 (计数 dword_14333CEB4;
wrapper 带 **硬OOS闩锁 u8@+24 / 槽2首发闩锁 u8@+25**)。双变体: 静默生产 (重算
sub_140DB1740, 每小时; tbb 并行) vs Logging 诊断 (sub_140DA5C80/sub_140DAB4C0, 只喂
dump/日志不进比对)。

**逐国哈希收集器 = sub_140DAE720** (1323 行; CalcChecksums 本体): 三参 (错峰相位指针 u32 = `(gs+1128 当前日期 − 43800000) % 24` 小时相 / CCountry\* / 该国 91 槽 × 12B MurmurHash3 流式状态行 {累加器 u32, 尾字节\|计数 u32, 总长 u32}, 行距 1092B); ~118 项恒采集, 错峰门 (`hard_oos` 旗 ∧ **original-tag identity (gs+832 恒等表, 非裸 tag)** %12 == 小时相) 只豁免槽 71 (逐师 8B) 与槽 62 (cc+4688 船队内嵌对) 两附加项 — 每国每天深挖恰一次。**token 双形态哈希门** (跨客户端确定性): token ≤ dword_1435E1ABC (静态 lexer 上界) 哈希 4B id / ≤ dword_1435E1AB4 (mod 注册扩容后运行时上界) 哈希 token **名串** / 超界 fatal — 作用于槽 18-20/61/73/88。调用链: DAE720 ← sub_140DB1B30 (串行) / sub_140DAAF00 (TBB CCalcAllCountryChecksumsThreaded, 分裂深度 ≤8) ← sub_140DA8A40 汇编器 (游戏级槽: 0/1 = multiplayer_random count/seed; 2 = CGameState::Save sub_1401F2E40 全 gs 摘要 (bit0 门); 87 = all_playthrough_data 序列化摘要 sub_1401F2DD0 (bit1 门 byte_143468B46); 80 = 本地玩家国 1B; 81 = 三调试旗) ← sub_140DB1740 每小时静默重算 / sub_140DB09F0 (dump/对比路径, "checksums/" 落盘 = oos_dump 命令族)。比较器 sub_140DB1830: hard_oos 模式 memcmp 全 91 槽; 普通模式只比槽 0/1 (差 → 硬闩锁+24) 与槽 2 (差 → 首发闩锁+25), 差槽下标收集进报告。game.log 逐槽行内槽名 = 空串 (sub_140DB1400 忽略下标恒返全局空串; "OOS_N" 取名路径属弹窗/差异码域)。

对拍门 (全部满足才比较): idler vtable+880 返回非空 ∧ (server 为 CNetworkServer/CProxyServer
∨ `-hard_oos`(word_143468B44 低字节) ∨ `-log_checksummed_member`(高字节) ∨
`-playthrough_stats_oos_check`(byte_143468B46) ∨ `-randomlog`(byte_143452529, 控制台
rlog) ∨ `-lightrandomlog`(byte_14345252B) ∨ **human_ai**(byte_14332F639)) ∧ (返回
对象)+1217 = 读档局旗非 0 (**上报只在读档局生效**, 开局新档不出报告)。

**91 槽主表** (〔W〕静默走访伪码直读 / 〔LOC〕OOS_N 本地化名; 槽 27 = 1.19.3 恒空槽
—— 四走访函数穷举 0 写入点, 推定旧版遗留):

| 槽 | 名称 (OOS_N) | 归属 | 哈希内容 (锚点) |
|---|---|---|---|
| 0 | Random seed | 全局 | dword_143452524 = multiplayer_random_seed (§4.28.13) |
| 1 | Random count | 全局 | dword_143452520 = multiplayer_random_count |
| 2 | Gamestate checksum | 全局 (ExtraChecks 位 0 门) | sub_1401F2E40 全持久态 token 键控哈希; hourly 默认不跑, dump 路径恒跑 |
| 3..10 | Army/Navy/Air Score·Exp·数量·领袖数 | 逐国 Country 头 | **逐槽拆定 (定案)**: 3=陆军数 (陆军容器计数 u32) / 4=领袖数 (**陆军+海军领袖容器计数双 feed 同槽**) / 5/6/7=陆/海/空 Score (u64 sub_1406EC030/6F30B0/6EB6A0) / 8/9/10=陆/海/空 Experience (经验对象 +16/+40/+64) |
| 11 | Total ship strength | 逐国 Fleet 走访 | 每舰 *(舰+1784) 8B |
| 12..17 | 民用/军用/船坞 Total·Available | 逐国 Factories | CProductionStatus (cc+3944) 折算; **族定案: 888=民用 / 696=军用 / 792=船坞** (OOS_12..17 名序直证), 槽序 = 民总/民可/军总/军可/坞总/坞可 (avail: 888 族 −944−920 / 696 族 −752−728 / **792 族走 sub_140E69130 非「总−两计数」**) |
| 18..20 | 民用/军用/海军 生产进度 | 逐国 Production Lines | 生产线数组逐 CBuildingProductionLine (state id 或名字串 fallback + 进度) |
| 21..24 | 省建筑数/前线数/前线省数/前线敌方 | 省走访 | 每省 *(省+468) / 每前线 *(+44)/(+68)+56 数组 |
| 25/26/36/43 | 战区数/最优省/明细/省数 | 逐国 Theaters | cc+360 数组逐战区 |
| 27 | Reinforcement Priority | — | **恒空槽** (0 写入点) |
| 28 | Country Modifiers | 逐国 Modifiers | cc+1464 条目数组 |
| 29 | State Modifiers | 州走访 | 州 +1352/+2312/+2248 三修正容器 (sub_1409D36F0) |
| 30/72 | Temperature/Weather | 省+天气区走访 | 天气管理器 gs+1672 (sub_140F1A0C0 族) |
| 31..35 | 控制/拥有地区 数·省·大小 | 逐国 Area List | sub_1406CF360 / sub_1406F6E00 逐区 |
| 37..42 | 资源 产/进/耗/出/池 ×2 | 逐国 Resources | sub_140BCC2F0 逐资源域 |
| 44 | 定时活动进度 | 逐国 Political Timed Activities | sub_1406CF890 活动数组 |
| 45 | 政治点数 | 逐国 Country 头 | 政治点对象 +224 8B |
| 46 | AI Countries | 逐国 AI | AI 策略存在性布尔 |
| 47/69 | 订单组/单位控制 | 逐国 Theaters | 战区 +128 数组逐组 |
| 48/60/70/71 | 在战陆军/师组织度/兵力/组织恢复 | 逐国 Divisions | 每陆军元素 vtable[+288]/vtable[+248]; **槽 71 错峰门**: word_143468B44≠0 且 tag%12==当前小时 |
| 49 | 已完成国策 | 逐国 Country 头 | focus 容器 +76 计数 |
| 50 | 燃料储备 | 逐国 Country 头 | *(cc+5504)+8 |
| 51 | 海军任务区 | 逐国 Naval Mission | sub_1406F9760 +272 数组 |
| 52..54 | 指挥点 现用/已分/总 | 逐国 Country 头 | cc+496/cc+504/sub_1406F1C60 |
| 55 | Next ID | 全局 | dword_1434520E0 全局 ID 分配器 |
| 56/57 | 陆/海军领袖 | 逐国 Leaders | 容器逐元素 vtable[+80] 领袖 id |
| 58/59/62 | 已用/空闲船队/船队客户 | 逐国 Convoys | cc+4716 / sub_1402BC8A0 / cc+4688 (槽 62 同错峰门) |
| 61 | 科技状态 | 逐国 Technologies | sub_1406CFCB0 逐项 |
| 63..68 | AI 策略 6 项 | 逐国 AI | Local Random/Fuel Ratio/Fuel Usage/Irrationality/Num Divisions/Threat |
| 73 | 情报机构升级 | 逐国 | sub_1406CF7F0 +96 数组 |
| 74 | 情报值 | 逐国 CountryIntel | sub_1406F1680 (SRW 锁内) 32B 条目数组 |
| 75/76 | 陆战/海战 | 战斗走访 gs+608 | 每战斗 vtable[+88] 分流 1=陆/2=海 |
| 77/78 | 补给/补给缓存 | 全局 | sub_140EC7E10 / sub_140EC5A80 (gs+984 CSupplySystem) |
| 79 | 铁路炮数 | 逐国 Country 头 | sub_1401DBAF0 +12 |
| 80 | 本地玩家国 | 全局 | 1B 布尔三支 (定案): 无人类国 → 恒 1; 有人类国 → 当前国==gs+1312 ∨ 双方非零且 sub_140BB52F0(gs+164) 同盟观察判真 |
| 81 | Debug | 全局 | fow (byte_14332F63A) / allowtraits (byte_14332F618) / debug (byte_14332EC69) 三字节 |
| 82 | 偏好战术 | 逐国 Country 头 | sub_1406C00D0 |
| 83 | Country Controllers | 全局 (按省下标序) | 逐省控制器 tag (gs+880 字节数组) |
| 84 | 特混舰队 | 逐国 Fleet 走访 | mission/+884/在战旗/sub_140C82C10 邻域; ⚠ **偏移分歧已结案 (定案)**: 两变体同读特混 **+1640** — Logging 伪码 +205 系 `_QWORD*` 算术 (205×8=1640); 特混四元组 = u32 (tf+1208≠0 ? sub_140D6CE90 : *(tf+884)) + u8 在战旗 (sub_140C00000) + u8 (*(tf+912)≠0) + u32 sub_140559750(+1640) |
| 85/86 | 空军联队/王牌 | 逐国 Air Wings·Aces | sub_1406F9600 +88 数组 / cc+4824 数组 |
| 87 | Playthrough Stats | 全局 (位 1 门) | sub_1401F2DD0 (_AllPlaythroughData gs+2200; byte_143468B46 门) |
| 88 | 军工组织 | 逐国 MIO | (cc+3944)+304 数组 |
| 89 | 国际市场 | 全局+逐国双写 | sub_14199AC40 (gs+1000) + 逐国 sub_14199A960 折叠 |
| 90 | 特殊项目 | 逐国 Country 头 | sub_14199B680 |

**走访顺序契约** (确定性本体): 全局段 = 槽2[位0]→87[位1]→0→1→55→77→78→89(全局半)→80→
83(逐省下标序)→81 → 国家列表 (gs+784 过滤 cc+1156>0) → 逐国 91 态 → **主线程按国家
列表序逐国逐槽 finalize 折叠 (含空槽)** → 省走访 (槽21/23/24/22/30/72) → 州 (29) →
天气区 (72/30) → 战斗 (75/76)。逐国段固定 24 分区序: Country 头(3-10,45,49-54,79,82,89,90)
→ 陆/海军领袖 → 两类生产线 → 科技 → MIO → AI(46,63-68) → 政治定时活动 → 舰队/特混 →
海军任务 → 空联队/王牌 → 资源 → 工厂 → 修正 → 控制/拥有地区 → 战区族 → 师族 → 船队族 →
情报机构 → CountryIntel。**tbb 只并行「每国产 91 态」, 折叠恒按国家列表序串行**;
错峰位 (槽 71/62 附加项) = `word_143468B44 && tag%12==当前小时` 摊到 12 小时档, 同刻
同 tag 同门, 确定性不受影响。

**比较与检出后行为** (sub_140DB1830): 计数门 (本端>0 且 == 主机载荷 count) →
hard_oos 模式 = memcmp 全数组 (任一槽差 = 硬 OOS); 普通模式 = 槽 0/1 差 → 硬闩锁
(+24=1, 此后每小时都判 OOS); 槽 2 差 → **首发闩锁** (+25=1) 一次性告警 (推定用途 =
两侧 ExtraChecks 配置漂移告警) → 差槽表出参。检出后: 构造 CClientOutOfSyncCommand
(0x68B: +40 玩家tag / +48 玩家名 / +80 差异码串) **广播** → 本地 game.log 三连
(banner / "Hourly tick on <日期>" / 逐槽 `* Checksum N (<槽名>): <本端> Host: <主机>`)
→ 各端 Execute → sub_140DD8D60 弹 GAME_IS_OOS (差异码 = sub_140DB1050 "Y/N" 前缀 +
差槽序列) → 聊天 "oos" 通告 → randomlog 模式附加 Logging 变体全量重算逐槽 hex 日志。
**不暂停不回大厅, 分叉继续跑**; 处置引导 = OOS_DESC 本地化文案 (resync / 重连 /
rehost / 带坏档继续)。dump 命令族 = `oos_dump` / `dump_checksum` /
`compare_to_last_checksum` (控制台)。

> 备注: human_ai 置位使单机也每小时跑比较+重算管线 (单机载荷 = 自身快照, 恒等不触发
> 上报) = **单机确定性金丝雀** (动机推定, 高置信)。
> 备注: 与存档 #checksum (MD5(文件+盐)) 无关; 本簇 = 活体 gamestate 结构化分槽
> MurmurHash (§4.2.4 步骤 8 汇总仍有效, 本节为逐槽展开)。

#### 4.36.10a Logging 变体逐槽填充映射精写 (feed 全形 + 未收函数闭环)

Logging 装配链全貌: sub_140DD8D60 (OOS 弹窗域唯一入口) → sub_140DB1560(&qword_14333CEA8, 掩码) → sub_140DA5C80(rows, 掩码, 并行旗=0)。**sub_140DB1560 的 a1 形参函数体内零引用 (定案)** — 91 个 finalize 结果只进日志 ("Checksum: <i> <hash>", :1129) 不回写本端数组; qword_14333CEA8 真写者仍在静默族 sub_140DB1740 路径。**并行支路 = 现役死码 (定案)**: DA5C80 第三参 a3 选路, a3≠0 走 TBB parallel_for CCalcAllCountryChecksumsThreaded<LoggingHasher> (lambda 符号直证; 分裂器 sub_140DAAC10 + 叶 sub_140DB1AB0 区间逐国行距 1092B); 现役唯一调用 DB1560 恒传 0。

逐槽 feed 精写 (主表锚点的喂入式; feed 原语 = DA5560 u32 / DA5900 u64 / DA53A0 u16 / DA5AC0 u8 / 1424ED930 原始字节):

| 槽 | feed 精写 |
|---|---|
| 18 | 一般生产线: 仅 `_RTDynamicCast`→CBuildingProductionLine **动型成功者**; 每线 2 项 = token 门 *(*(line+112)+8) + u16 sub_1410DB9F0(*(line+112)) |
| 19/20 | 装备生产线 (+88 数组): `vt[+192](line)` 真者 → 19 / 假者 → 20; 每线 4 项 = token 门 *(*(line+136)+24) + u32 *(line+24)+*(line+28) + u32 sub_141938D40(line) + u64 *(line+144) |
| 28 | cc+1464 数组 (16B 条目): **每条目只哈希前 12B** = u32 id@+0 + u64 值@+8 (sub_140DA5720) |
| 31..35 | 31=控制区数; 逐控制区 (*(area+60)>0 才喂): 32=州id *(*(area+40)+164) + 33=省数 *(area+60); **槽 35 先喂 original-tag 恒等 id (sub_140BB5490(cc+8))** 再逐拥有区 (34=州id + 35=省数) — 双语义槽 |
| 36/25/26/43 | 25=战区数 *(cc+372); 36=同值再喂 + 逐战区 u32 *(th+8)+*(th+12); 26=逐战区 *(*(th+232)+164) 空则 0; 43=逐战区 sub_140EF8060 |
| 37..42 | 逐资源 u64 ×6, **feed 序 = 37,38,39,40,42,41 (41/42 交换)** |
| 44 | 逐政治定时活动 u64 sub_140AD9ED0 |
| 47/69 | 逐订单组: 47=u64 *(og+8) + u8 *(og+57) + 成员三数组 (+152/+176/+200) 逐元 sub_140DAA240; 69=u32 *(*(og+72)+296) |
| 48/60/70/71 | 48=u8 在战旗 sub_140C00000; 60=u64 vt[+288]; 70=u64 vt[+248]; 71=u64 sub_140C82C10 **仅错峰门内** (v334 = word_143468B44 ∧ tag%12==相位) |
| 58/59/62 | 58=*(cc+4716); 59=sub_1402BC8A0(cc+4608); 62=逐船队条目 u32 e[0],e[1],e[2],*(e+28); **错峰门内追加** e+16 数组逐元 u32 *(se+8), *(se+12) |
| 61 | 科技每项 **6 feed** = token 门 *(tech+8) + u32 +368/+372 + u64 +408/+492 + u64 max(0, sub_140EDA300−408) (剩余时间钳非负); 空项喂 0 保序 |
| 63..68 | AI 门 = sub_1406FFC90 ∧ AI 对象 ∧ …: 46=1; 63=u32 sub_14065AB50; 64=u64 sub_14065A550; 65←ai_dword[2232](+8928) / 66←ai_dword[2190](+8760) / 67←ai_dword[2233](+8932) (⚠ 与本地化名 Fuel Usage/Irrationality/Num Divisions 的逐槽对应待静默族旁证) / 68=u64 sub_14065D520; 否则 46=0 |
| 73 | 情报机构 +96 数组 (16B): 内联 token 门喂 *(*(entry)+8) + u32 *(entry+8) |
| 74 | CountryIntel **SRW 锁内**: 32B 条目 4×u64 直哈希 |
| 75 | 陆战 (vt[+88]==1): 省id + 每侧 {侧容器计数, u8 偏好战术, u64 *(*(sub_1412AAAE0(side))+616), side[45..50] 五对, u64 +392/+400} |
| 76 | 海战 (vt[+88]==2): 省id + u32 再取 +68 + u64 vt[+200] + 每侧 {计数, u8 *(side+320), u8 sub_14161FCF0, u64 +344, u64 +384} |
| 21/22/23/24 | 21=逐省 *(prov+468); 22=逐省 *(prov+108) 前线数; 23=每前线 *(front+44); 24=*(front+68) + 逐敌方 tag sub_140BB5490 |
| 29/30/72 | 29=逐州 sub_1409D36F0; **30 = 省半 (逐省 3+ 项天气查询 sub_140F1A0C0/80/5E0) + 州天气区半 (同区 u64 *(region+312)) 两段拼接**; 72=逐州天气区 6×u8 (+264..+304 步 8) |

未收函数闭环 (12 件全定案): feed 原语四件 = sub_140DA5560 (u32, " <hex2>" 日志 :246) / sub_140DA5900 (u64) / sub_140DA53A0 (u16) / sub_140DA5AC0 (u8); 日志标签四件 = sub_140DAB2C0 (分区开 "<名>:") / sub_140DAB1F0 (具名开 "<名> \"<串>\":", 用于 Country+tag/Fleet/Task Force/Orders Group/州名) / sub_140DAB370 (编号开 "<名> (<u32>):") / sub_140DAB440 (闭标签空行, 兼 DAB4C0 尾清理); **sub_140DA5720** = 修正条目 feed (16B 条目只哈希前 12B); **sub_140DAA240** = "Orders Instance" 递归哈希树 (u32 +580 + (+592 ? +592+12 : 0) + +124 + +48 kind + +540; kind==3 → +184/+124/+112 数组逐元; kind==4 → +184/+112 首元; **递归子表 +504/+720 两张**) — 槽 47 成员展开实为带标签实例树; 并行支路二件 = sub_140DAAC10 (分裂器) / sub_140DB1AB0 (叶)。 hex2 语义 = 三状态字按字节异或折叠 (d0^d4^d8)&0xFF 的 %02X (小写表低位在前); finalize 0x140DB1560 = 91 行 1092B 栈上 scratch (sub_140DA5C80 并行旗恒 0), 逐行 "Checksum: <i> <hash>" (:1129) 后该行三 dword 清零。

#### 4.36.11 MP 玩家生命周期与聊天社交

玩家诞生链 (两级加人, 定案):

| 步 | 环节 | 定案 |
|---|---|---|
| 1 | 会话级加人 | CAddPlayerCommand (10723) 双端 Execute = sub_141997C00: 先社交 id 插聊天名册 (sub_1424011D0) → **防重扫描** (gs+248 人类表线性查 +152 == cmd+120 machineid; 命中 → "Human already added!" 断言 + 主机现场构造 **CRemovePlayerCommand{reason=2}** 自动移除陈旧条目) → **CHuman 6 参 ctor sub_140BBC630** (user=cmd+40, name=cmd+72, badge=cmd+104..116, machineid=cmd+120, hotjoin=cmd+124; +120 日期装哨兵 / +148=9 或 11) → AddHuman 入 gs+248 |
| 2 | 大厅级登记 | 大厅 OnPlayerAdded (聊天名册 + 监听器 + **热加入存档分发表**: lobby+244 挂起时 malloc 240B CLargefileHandler 以 human+152 为键压 lobby+256 队列, §4.36.9) |
| 3 | 热加入名册重建 | 主机对每个在场老玩家**定向** (cmd+24=1, cmd+16/20 = 新客连接描述) 补发 CAddHumanCommand (13995) 供新客重建带绑国的名册 |
| 4 | 聊天层广播 | CChatUserJoinedCommand (389) = 聊天层独立广播, 与 CHuman 建立无关 |

**machine id 分配与 id 空间 (定案)**: 主机恒 1 (Init 直写 session+164=1、计数器
+160=2 并自登记成员链); 新客 id = sub_1422502C0 对 session+160 后缀自增 (唯一分配点 =
REQUEST_ID 收下尾 sub_142366030 发 MACHINE_ID(0)), 客户端落位 +164 并镜像 +160=id+1;
**无回收** (纯单调, 退出后 id 不复用); 特值 = **−1 = gs+272 内嵌哨兵 human / −2 → gs+432
(第二内嵌槽 = CDedicatedServer 占位, §4.36.1; 语义待裁)**; 查找器 sub_1401C9CD0 对
±特值直返内嵌槽, 未命中返 gs+272 (+152 = −1 即「无此 human」判据)。主机迁移靠老成员
持旧 id 经消息 0 接收处理 (server+268 接入窗) 重注册 (§4.36.5)。

**选国/换国链 (定案)**: CSetCountryControllerCommand(10707)::IsValid 全门 = human
存在 ∧ CHuman+148 bit2 == 0 ∧ (coop 开 ∨ tag≤0 观察者 ∨ 无人持同 tag); Execute 账目
= 旧国计数−− (归零打 "AI will control") + coop 交棒 + 新国使能/计数++ (绑国落账 =
gs+880 使能阵 + gs+904 计数); **换国零对象转移** (建筑队列等随国不随人)。显式接管
广播 = CSetCountryControllerTypeCommand (13908): type 0 = AI 接管 / 1 = 保留使能清
计数 / 2 = 人控建立。coop 共控 = 多 CHuman 绑同国 (§4.36.8)。

**就绪协议 (定案)**: 就绪位 = **CHuman+148 bit2** (CSetReadyStatus 写/清并连带清
bit1; 置位时名字入 lobby+88 名册; **开局后该位粘滞 = 「已开局门」**——开局流程亦置
位, §4.36.8 的 IsValid 门消费它); CRequestReadyStatus (13090) = 进局装载完成的「我已
就位」信号 (为本地玩家 post CSetReadyStatus(1)); 重开局清零 = CReopenLobbyCommand
Execute + OnSaveGameLoadBegin 群发。**引擎无全员就绪自动开局环 (负发现)**——开局恒
由主机经前端簇发 CStartGameCommand (13726; 执行器门 = lobby+1204==0 ∧ 未开局 ∧ 会话
态∉{8,9}; 就绪约束在 UI 使能层)。

**玩家退出链 (定案)**: 单载体 CRemovePlayerCommand (13901), reason 定案 = 0 自退 /
1 暂存清理 / **2 踢 (先走 server 踢出槽[14])/ 3 禁 (sub_14224FAB0 写 session+336
ban 名册)**。掉线瞬间仅会话层摘除 (sub_142250F50, §4.36.5; CHuman+绑国+计数原样
保留、AI 不接管、等同 id 重连), **移除命令到达才计数−− → AI 接管** (旧国归零打
"AI will control") + 主机弹 CAIControllerPopUpWindow (4056B,
"aicontroller_popup_window")。

**名字与身份 (定案)**: 账号名 = CHuman+32 / 显示名 = +64 / machine id = +152
(Added/Removed 日志打 user 非 name); 国家关联 = country-link id@+112 (§4.28.1);
Steam id = CPdxSocialPlayerId 平台表键 374 (§4.28 布局引用), 随 10723/13995 上链,
消费落聊天名册单例 qword_1435DA858, **不进 gs**。⚠ s4_33 速查表 10723 行「+128 嵌套
(389)」的嵌套对象 = CPdxSocialPlayerId (序列化键 389 与命令 id 389 同数不同域)。

**聊天/社交挂点**: CChat slash 命令表与 CChatMessage 族布局归 §4.00/§4.28 (不重复);
联机专属门 = ChatSettingsProviderImpl 仅 `MP && 聊天单例空` 时构造 (§4.36.1 表);
PdxSocialPermissions 权限簇 (social_* 键) 归 §4.28; "oos" 聊天通告 = OOS 链尾
(§4.36.10); "LAG_DECREASE_SPEED"/"LAG_PAUSE" 通告 = 掉队链 (§4.36.4)。

proxy_server.cpp 簇对账增补 (CProxyServer 运行期行为层; 11 函数闭环):

**类实名 CProxyServer 定案** (ctor vtable 符号 + RTTI 81 站 + 三条 [NET_DEBUG] 串); 552B
布局表全部既有行互证一致, **增补六行**: +288 u64 = SESSION_TYPE(17) 值缓存 (LAN 泵清 0) /
+352 u16 = ctor 清零 (语义待裁) / **+356 u32 = SERVER_TICK 锁步缓存** / **+400 u32 = 最近
发送批号** (slot[21] 流控门读数) / +520 u64 = RTT 均值窗锚点 (ns) / +528 u32 = 平均 RTT
(ms, 5 秒窗)。三个 catch funclet (0x1426F24C0/2820/26E0) = SendOrders / vtable[5] /
PackageCallback 主路的 CFileException 处理器 (零静态引用 EH 表独占; 闩组 = **byte_1435B9D10
..B9D1F 连续 16B 块** — network_server.cpp 侧占 D12/D13/D14, proxy_server.cpp 侧占 D16..D1C,
§4.28.25 COMDAT 合并定式的完整边界)。

**Connect 全链** (vtable[2] 定案): 预连双写 (**session+360 ← 连接描述+32** — §4.28.25「+360
待裁」第二写点, 推定 = 当前连接目标主机标识; matchmaking ctx vtable+304 登记) → +426 = a2
(探测旗: 链上即 Disconnect(3000), 只测可达性不入握手) → REQUEST_ID 帧 = 8B {8,0} 头 +
CWriter 键 27 玩家名 / 222 密码 / 377 版本串 → 30s 自驱态泵 (sub_142252D00, 态 {1,5}) →
终态 +427 = state ∈ {4,6,9,16}; 成功即 **session+1968 = 0** (撤销重连诉求)。

**命令中继上行双函数** (定案): slot[5] 入队 — cmd+24≠0 定向命令**直发连接 0 不入队**;
普通命令 = +456 序号 → cmd+28/cmd+32 同值 → SRW(+536) 锁内回声待答表 (hash 73244475) →
tbb 微批 (页 0x2C0, 8 槽 × 40B, (3·idx)&7) → 尾 +404 = 0。SendOrders (vtable[30]) —
**cmd+22 发送时二次盖批号** / +400 = 最近发送批号快照 / +404 = 1 / 逐条 delete。
**自回声 RTT 管线**: cmd+12 == 本机 → +472 回声表按 cmd+32 查 → RTT → +496 ns 样本向量 →
5 秒窗 → +528 ms 均值 (读者未决)。

**PackageCallback 接收半边** (vtable[27], channel 1 控制面 35 值全互证): 增补 = 0 MACHINE_ID
与 2 ADD_PEER 均写 **session+160 = 值+1** (「下一 machine id」客户端镜像写点, §4.28.25
待裁补全) / 1 SERVER_ADDRESS = session+100 直写 / **33 DECLINED_JOIN_DISABLED →
session+1942 = 1 / +1944 = 值** (新字段) / 22 APPLICATION_MESSAGE → session+376 链头插
(新链, 消费者待裁) / 15/16 → 广播码 14 + +1856 处置。**channel 0 分流实为四分流**: 态 ∈ {4,2,12,13,14} → 就绪表 +144 链 / 态 5 → +96 链 (before-sync 暂存)
/ **态 6 定向 → +120 链** (EARLY 定向命令链) / 态 6 普通 → +96 链; +120 链双型消费 =
主机 PackageCallback 定向表 + proxy 态 6 定向 EARLY 链 (主机 PackageCallback 对 +96
零引用 — 原「+96 主机定向表」说废弃, 定向表定案见 §4.36.2 表)。

**LAN 浏览三件套** (vtable[11]/[25]/[26] 定案): 泵返回 **&+264** = 浏览器枚举链头; B 表
(+240) 元素 +32 u64 状态机 (<0 未探/失联 → 0 探活成功 → 1-2 GAME_STATUS → 3 已入链);
SServerInfo = 308B 定长 (sizeof 名直印); 单轮 255 探针上限 + 5s Retry 清扫; CHECK_LOCAL
路 REQUEST_GAME_INFO(25) + B+32 = 0。Update 精化: 踢/禁处置前置全局门 = appmgr (+56 子
对象) vtable+112 bool (CGameApplication 单例直证); SetState 全量互证 + 增补「态 8/9/10/11
广播后 session+72 = 0 回写」。日志类别码观测补样: 769 (常规) / 771 (就绪表收包, 单站)。

未决: +328 置 1 写者 (族内零写点负证加强); +528/+352 读者; appmgr+56 身份; session+376
消费者; 自旋阈值 35 计量; 日志码枚举名。

#### 4.36.12 network_server.cpp 主机侧收发链定案 (CNetworkServer 运行期行为层)

清册 (10 函数全含 network_server.cpp 锚; 框架槽归属与 §4.36.2 互证一致):

| VA | 行数 | 身份 |
|---|---|---|
| 0x1423663F0 | 1233 | vtable[27] PackageCallback 收包主泵 (全链精读; §4.36.3 接收半边本源) |
| 0x1423686D0 | 280 | vtable[7] 成员同步泵 (精化见下) |
| 0x142367E70 | 268 | vtable[5] 入队+定向发送 |
| 0x1423652B0 | 188 | vtable[26] DisconnectCallback |
| 0x142366030 | 171 | 接入执行体 ("New Client Connected" :138) |
| 0x142365680 | 135 | 执行期广播 (唯一调用点 = CSession::Update 主派发 Execute 前) |
| 0x142365140 | 72 | vtable[25] ConnectionCallback (= 日志 + 连接机 id 清 0) |
| 0x1426F2160 | 45 | 广播函数 catch funclet (CFileException, :751/:752, 闩 B9D13) |
| 0x1426F2290 | 45 | vtable[5] catch funclet (:330/:331, 闩 B9D12) |
| 0x142365770 | 21 | vtable[30] 废弃槽断言 (:770) |

vtable[27] channel 0 精读 (定案):

| 步 | 动作 |
|---|---|
| 1 | 反序列化 → 收包日志 (类别码 771, 消息 = `<type_id>, ID: <cmd+28>`) |
| 2 | 防伪造: cmd+12 ≠ 连接实际机 id (connmgr vtable[18] 查) → "REJECTED SPOOFED COMMAND! Actual sender: `<实际>`" (类别 775) → delete |
| 3 | !IsValid (槽[9] 双参) → "COMMAND LOST! Sent: <cmd+22> Received: <session+128>" (类别 775) → delete |
| 4 | 机器表只查找 (哈希内联 = 73244475 双轮, 探测步进 64B, 未命中探测位 = 桶末哨兵 (mask+extra+1)×64B); **未登记发送者 = 静默丢弃无日志** |
| 5 | cmd+24≠0 → 0x20 节点尾插 +120 定向链 (不重盖序号); ==0 → 重盖 cmd+28 = InterlockedAdd(server+264) (+32 origin 不动) → 尾插就绪链 (+144); 两路所有权转移不再 delete |
| 6 | 反序列化失败 → "COMMAND UNKNOWN! Received: <session+128>" (769) |

channel 1 消费集与准入 (定案): 消费集仅 {8 REQUEST_ID, 9 RECONNECTED, 14 REQUEST_HOTJOIN,
25 REQUEST_GAME_INFO}, 其余 0-35 全记 "Unknown message received" (:664); len<8 丢包日志;
0-35 名称 switch 与 §4.36.3 类型表逐值一致。REQUEST_ID 准入五闸逐闸直证 (顺序 §4.36.7 ✓):
ban 闸 (输入 = 连接描述+24 句柄 u64, 命中回 BANNED(21)) / 名无效 (NAME_INVALID(34)) /
名重 (session 槽[6], NAME_TAKEN(28)) / 密码 (gamesetup 密码串非空才 memcmp 比对 —
**主机密码为空 = 整闸跳过**; INCORRECT_PASSWORD(27)) / 版本 (构建串 vs 客户端串,
VERSION_MISMATCH(35)); 拒绝一律 8B 值 0 形态 channel 1 定向回发。**9 RECONNECTED 与 8
同走 +268 接入窗门但绕过全部五闸** = 重连免检通道。载荷 reader 内含首字节 `!= '@'` (0x40)
跳读分支 (语义待裁)。

REQUEST_HOTJOIN(14) 主机处置 (定案):

| 项 | 值 |
|---|---|
| 使能门 | gamesetup+645 = 热加入使能旗 |
| 使能路 | 写 session+1864 / +1896 (载荷两串) + +1928 (conn) + +1936 = 1 → 观察者广播 14 |
| 未使能路 | sub_142250180(session, conn, 3) 拒绝 (码 3 = DECLINED_DISABLED 域) |

REQUEST_GAME_INFO(25) 应答 (定案): SESSION_TYPE(17) 值 = session+80 → GAME_STATUS(24) 值 =
gamesetup info 首 dword → **308B SServerInfo 直发 channel 1** (与 proxy LAN 浏览同构,
§4.36.11)。字段表 (构造点直读):

| 偏移 | 类型 | 语义 |
|---|---|---|
| 0 / 64 / 128 / 192 | char 64B ×4 | 名 / 描述 / mod / tags |
| 256 | char 32B | 版本串 (= appmgr+352) |
| 288 / 290 | uint16 | 大厅数据两读 (sub_1423DF930 / sub_1423DF910) |
| 292 | uint8 | 密码存在旗 (= gamesetup 密码串+16 != 0) |
| 296 | uint8 | join_phase (= 大厅 sub_1423DF950) |
| 300 | int32 | 会话态 (= sub_140CE9520) |

接入执行体 sub_142366030 十步 (定案; 触发 = 8 准入全过 / 9 免检): 分配机 id
(sub_1422502C0, session+160 自增) → MACHINE_ID(0) 定向新客 → 快照成员链逐台
ADD_PEER_ADDRESS(2) 定向新客 → 机器表插入 (48B 记录 = {机 id u32, pad, 40B 连接描述};
值域低 u64 = 机 id) → 会话侧入成员链 → ADD_PEER(2) 对其余全员广播 → 继任判定
(server+220≠0: NAMED_SUCCESSOR(7) 值 = +220 + SERVER_ADDRESS(1) 值 = session+100 镜像;
==0: **继任 = 新客** + SERVER_ADDRESS 值 = 新客描述+32) → SERVER_TICK_VALUE(4) 定向新客 →
连接置机 id → SendGameState (槽[29]) → **session+392 = 新客机 id** → 观察者广播 6 →
"New Client Connected" (:138)。

vtable[26] DisconnectCallback (定案): 早退支 = 连接机 id == 0 (未指派连接) 仅重置机 id 即返,
不动会话/机器表; 主路 = 会话成员两遍式摘除 (sub_142250F50, **返回值 = 继任候选** = 首个
非移除成员) → 掉线 id 尾插 +168 链 → 机器表桶+56/+60 取 addrport 入 +192 数组 → conn 入
+216 数组 → 掉线者 == server+220 且候选非 0 → 继任重指 (sub_142366390) →
REMOVE_PEER_ADDRESS(3) 广播 → 机器表按键擦除 → 观察者广播 5 → 三暂存区齐清
(sub_1422500C0: +184/+204/+228 计数清零, 数据保留)。

vtable[5] 定向路与执行期广播 (定案): vtable[5] 定向支序列化后按槽[18] machine / 槽[19] aux 解析
连接 (sub_1423E5E50), 发送即 delete 命令 (入队路所有权转移不 delete); catch (CFileException)
段 :330/:331。执行期广播 sub_142365680: 先调 cmd vtable[+112] (槽[14], 语义待裁 — 本簇唯一
消费点) → 序列化 → target 0 广播 (channel 0); 唯一调用点 = CSession::Update 主派发
Execute 之前, 门 session+80 ∈ {2,4,5}。

vtable[7] 成员同步泵精化 (定案): 总门 = byte_143085001 (与 P2PSessionRequest 回调共用);
名册源 = appmgr 单例 (qword_143452450) +856 → +16 大厅上下文; 逐成员登记 connmgr 后与
+272 快照逐元素全比对, 全等静默 / 有差重建 + "lobby roster changed" (:292); 尾调
connmgr 收包泵。

tbb 队列页 704B 布局精化 (定案): u64 原子序号 @页+128 (InterlockedExchangeAdd64),
槽区 @页+384 (8 槽 × 40B), 槽位 = 页 + 40×((3·idx)&7) + 384; 入队 helper = sub_142364310
(proxy 同构); 主机入队时 cmd+28 与 cmd+32 同值。

日志类别码 (观测): 775 = 命令拒收警告级 (SPOOFED/LOST 两站) / 771 = channel-0 命令收包
(与 proxy 侧单站同码) / 769 = 常规。

未决: cmd 槽[14] 广播前调用语义; session+392 读者; ban 名册键域 (sub_1422509C0 与
session+336 名册是否同域); '@' 跳读分支; 序列化缓冲对象 (malloc 0x58) 类实名;
vtable[3]/[6]/[13..15] 等同 cpp 邻接件归属簇。

#### 4.36.13 CMatchmakingGui::RefreshInternetServers (matchmaking_gui.cpp; 1 函 — clausewitzlib 图形库层)

sub_14231B4C0 (352 行; 锚 :927 "Matchmaking not connected when refreshing internet servers." — **路径 = clausewitzlib\graphics\matchmaking_gui.cpp, 引擎库层非游戏 source 层**; CLogStream 形态③); 布线 = sub_1423137F0(+8160 按钮 glue 组注册回调)。

**CMatchmakingGui 布局补**: +64 元素查找接口 (vtable[120] 取文本 / vtable[168] 取 checkbox 与容器 / vtable[304] 取列表) / +88..+120 mod 过滤词缓存串 / +152 匹配上下文句柄 (互证) / +8160 按钮 glue 组 / +12100 刷新游标 / +13432/+13488 连接回调函数指针对 / +13568 264B 服务器查询参数块。

机制: 连接检查 (sub_1423DF5C0+sub_1423DF7C0) → 已连接: 清列表 → "no_servers" 元素 (禁用 + SEARCHING 文本 + 隐) → 游标清 0 → "servers" 容器清空 → 264B 查询参数初始化 → **四 checkbox** (filter_not_full / filter_has_players / filter_no_password / filter_mod) 读值 → **双路查询发起** (sub_1423DF810 带 mod 串 + 三 bool / sub_1423DF880 另路, 目标差异推定 Steam 互联网 vs 局域/好友); 未连接: 回调对非零 → :927 日志 → 尾函数指针调用。

未决: 双查询目标差异 / +13432/+13488 回调身份。

#### 4.36.14 CProxyServer 客户端半边全案 (proxy_server.cpp; 11 函闭环 — clausewitzlib 联机栈, 客户端中继服务器)

CU = `clausewitz\clausewitzlib\proxy_server.cpp`; CProxyServer = 主机权威星型拓扑下客户端侧的命令上行/广播下行中继 (跑在 Steam P2P 传输上, connmgr = CSteamNetContext), 与任何 HTTP 代理语义零亲缘。信道 0 = 命令 / 信道 1 = 控制消息 (8B {u32 type, u32 value}); 另有 CHECK_LOCAL 态局域网发现支。

**LAN 发现支全机制 (定案)**: state(+348)==1 且 channel 1 → 消息 17 ("Got gametype") → +288 = value (浏览器 GUI 消费, LAN 重试泵每轮清 0); 消息 24 ("Got gamestatus") → 由 conn 提取地址键 {u32, u16} (sub_1423E60A0) → 向量 A {data@216, count@228, 元素 40B, 键域元素+32/+36} 线性查 → 列表 B (40B 元) 对应条目 +32 写值 (未命中写首条目)。「Added game」门 (:543) = B 条目状态 ∈ (0,3) ∧ size ≥ 308 (**sizeof(SServerInfo) = 308 串直证** :548) → malloc 336B 节点拷 308B SServerInfo, **+264 链头 / +272 链尾 / +280 u32 节点计数**; 尾插后该连接机 id = 节点序号−1 (sub_1423E5CD0); 最后 B 条目 +32 = 3。DisconnectCallback: 断连节点键查列表 B 条目 +32 = −1 (gone); +284 门 → 置位仅打标 (+328 = 1 延迟删旗) 否则双向摘链 free; 非 1/2 态断连 = "Server lost!" + session+1968 = 1。ConnectionCallback state==1 → REQUEST_GAME_INFO(25) + B 条目状态复位 0。LAN 重试泵 [11]: 游标 +344 循环 B 表, >5.0s 停表 → "Local games: Retry..." 清死连接归零; 状态 <0 (gone) 才重连; 返回 +264 (服务器列表 getter)。

**客户端控制消息消费集 (24 值)**: {0,1,2,3,4,5,7,11,15,16,18,19,20,21,22,27,28,29,30,32,33,34,35} + default 静默 return (无 Unknown message 日志 — 那是主机侧)。要点: 消息 0 MACHINE_ID → 置本机 id + **session+160 = value+1** (已知机器计数, 消息 2 ADD_PEER 同) + SetState(5); 消息 5 先行短路 = SERVER_TICK 锁步 (+356 比对, 会话类型==2 → SetState(7)); 消息 15/16 HOTJOIN → SetState(13)/(15) + +1940/+1856 清位; 消息 18 GAME_STATE → 载荷 [8:] 拷入 **session+400** 容器, 类型≠16 → SetState(6) 等 SYNCHCOMPLETE; 19/20 KICK/BAN → value==本机 id 置 +424/+425 (Update 处置 shutdown) 否则按 REMOVE_PEER; 29/30/32 HOTJOIN_DECLINED → **session+1856 = 拒绝原因码 {1,2,3}**; 33 DECLINED_JOIN_DISABLED → SetState(18) + 事件 17; 21 BANNED → SetState(9); 27/28/34/35 → 状态 17/10/11/16。

**命令支五值分流**: 就绪集 {2,4,12,13,14} → 就绪链 +144/+152/+160 (日志 "[type_id], ID: N", ID = cmd+28); state==6 EARLY 支 (定向 +120 链 / 非定向 +96 链); state==5 → +96 链; 其余 VERY EARLY → +96 链; 链节点 = 32B {cmd, prev, next, u8}。反序列化 sub_142269960; **cmd vtable[11] = GetTypeId** (日志与序列化同槽直证); 反序列化失败四组 latch (byte_1435B9D17/19/1A/1B)。**自回声 RTT (就绪支独占)**: cmd+12 == 本机 id → SRWLock(+536) → hash = 0x045D9F3B 混淆 cmd+32 (origin 序号) → 回声表 (data@472/count@480/mask@484/extra@488) 查桶 (24B {hash, dist u8@4, key u32@8, 时间戳 u64@16}) → RTT = now − 桶时间戳 → 入 +496 样本数组 {8B/元, cap@504, count@508, 分配器@512} (backward-shift 摘桶); **每 5s 窗 (+520 上窗锚 ns) 汇 sum/count/1e6 → +528 平均 RTT (ms)**, 样本清零。

**Connect [2] 加入流**: SetState(1) → 40B 连接描述全局登记 → +392 连主机 (失败 SetState(0)) → 等待环 (sub_1423C1E80 收包泵 + Sleep(1ms)) → 加入请求 = 控制消息 {8 REQUEST_ID, 0} + CMemoryFile (**88B = 0x58**) + CWriter **token {27 name, 222 password, 377 version}** → vtable[4] 裸发 → 等机 id 环 (状态 ∈ {1,5}, <30s, Sleep(30ms)) → +427 = 结果态 ∈ {4,6,9,16}; 成功态 3 / 失败 0 + connmgr shutdown。**+426 = 仅连接不加入探针旗** (Connect a2 直存; ConnectionCallback 置位 → vtable[3] Disconnect(3000) 连上即断 = 版本探测/浏览器 ping, 不走加入流)。SendOrders [30]: tbb CAS 取票 (InterlockedCompareExchange64 +440) → 微队列 &queue[48+40*((3*ticket)&7)] 出队 (步 40B) → **cmd+22 = min(session+128, 0x7FFF) 盖 tick (客户端发送侧盖点)** → +400 = session+128, +404 = 1 → 序列化发主机 (vtable[11] GetTypeId; 失败 :944; CFileException → catch 断言 :949/950) → cmd 即析构。Update [6]: +328 反门; +416 停表 >1.0s "Long update!" 日志; 依次 SendOrders → 收包泵壳; KICK/BAN 处置; 尾 +200 = 1。3 个 45 行函 = EH 清理 funclet (SendOrders catch / slot[5] catch / PackageCallback catch, latch byte_1435B9D1C/16/18, B51 门)。

#### 4.36.15 friends_handler_steam_request.cpp 好友排行回调消费 (1 函 = 0x141C34BC0 — 书未收簇; friends_handler/leaderboard/ISteamUserStats 既有空白的首块填补)

**机制 (定案)**: Steam 排行榜单条目下载回调处理器 —
1. 接口获取 = `*(qword*)SteamInternal_ContextInit(&off_1430B3898)` (接口访问器宏形态); 由调用形态钉死 = **ISteamUserStats\***。
2. 失败短路: 接口空 ∨ a3 旗真 ∨ 条目数 `*(int*)(a2+16) <= 0` → 构造**空结果记录**派发后返回 (无 Steam 调用)。
3. 条目数 ≠ 1 → friends_handler_steam_request.cpp:74 (通道 4096) "Got more leaderboards entries than expected, got: " 告警后**照取条目 0** (warn-and-take-first 不中断)。
4. 单条目读取 = `vtable[+240] = ISteamUserStats 槽 30 GetDownloadedLeaderboardEntry(entriesHandle, 0, &entry, &details, 11)`; a2 = 下载完成回调载荷 {entries 句柄@+8, 条目数@+16}; 出参 LeaderboardEntry_t 24B = {CSteamID@+0, rank@+8, score@+12, cDetails@+16, hUGC@+20} (CSteamID 位域清零掩码 0xFF0FFFFF/0xFFF00000 直证默认初始化); details = 11 × u32 (cDetailsMax = 11)。
5. **结果记录** (~92B 栈对象, 字段序定案 / 尺寸推定): 首 32B std::string (名字/键, 失败态空串) / id 槽默认 −1 / **三 token 槽默认 19479 `undefined`** (token 表直证; 与 §4.7/§4.8 的 19479 哨兵用法同源), 成功态被条目 details 覆写; ok 旗首字节 1/0。
6. 派发 = 宿主 `*(a1+72)` 对象 **vtable[2]** 消费 (失败/成功同槽); a1+72 空则 sub_14251BAFC 硬停形。

> 语义 (推定): 下载请求按单条目对单个 steamid 发起 (大概率 DownloadLeaderboardEntriesForUsers 逐好友), 本函把每份回调转一行好友排行结果喂宿主 (+72 = 结果汇)。宿主类名 / 排行榜请求发起侧 (哪张榜/哪个用户集) 待裁; 语料内零直接调用点 (Steam 回调经注册分派表间接进入)。

#### 4.36.16 DirectJoin 弹窗条目地址文本 (multiplayerviewitems.cpp; 1 函 = 0x141F5BB90 — df305 新簇)

#### 4.36.17 pdx_net 主机名 → IPv4 解析器 (pdx_net.cpp; 1 函 = sub_1423E5D00, 高置信/对象类名未证)

sub_1423E5D00 (getaddrinfo 包装): hints = {flags=0, family=AF_INET(2), socktype=SOCK_STREAM(1), 其余 32B 清零}; getaddrinfo(host, NULL, &hints, &ppResult) (host = 入参 MSVC 串, cap@+24 > 0xF 取堆) — 失败 → CLog 4096 :276「getaddrinfo Failed: %s」(实参 = FormatMessageA(0x12FF, NULL, err, 0x400, buf, 0x400, NULL) 系统文案); 成功 → 遍历结果链取首个 ai_family==AF_INET, `ntohl(*(u32*)(addr+2))` (sockaddr_in.sin_addr) 存出参 **+32 (IPv4 主机字节序)**, freeaddrinfo。**地址对象布局**: +0 u32 = 1 (族/有效标记, 推定) / +4..+20 16B 清零 (IPv6 或备用域, 未决) / +24 qword = 0 / +32 u32 IPv4 / +36 u16 端口。类名无 RTTI 锚 (CAddress/CIpAddress 均未证)。与 §4.36 pdx_net_steam.cpp 收发域同库不同件。

**机制 (101 行, multiplayerviewitems.cpp:252, 定案)**: 多人浏览器/DirectJoin 弹窗每条目的地址列来源选择 — 按 a2 连接类型三分支, 全部汇入 sub_141F5BD50(a1, 串, a3) 写入视图项 (SetText 语义): ① a2+24 非空 → sub_1424CB370(id→串) = **Steam ID 路线** (§4.00.36 同名转换函互证); ② a2+32 dword 非空 → sub_1424CA660 = **AppId 串路线**; ③ 否则 → :252 断言 `Address.IsValid() && "Invalid Address on DirectJoin Popup"` (闩 byte_14338CB0C) → sub_1423E5E80 = **IP 地址格式化路线**。**连接信息布局**: +24 = Steam id (8B) / +32 = dword AppId / 其余 = IP 地址结构。玩家数据取自连接对象自身字段, 不查国家或存档数据。


**pdx_matchmaking_steam.cpp 主控对象 (书未收, ≥721B, 类名未决)**: 方法族五站 — Update 0x1423E50A0 (:268, bIsServer 门; +658 就绪旗清后自虚槽[28]; lobby 快照 +448 ≠ 现 SteamID → 更新 + ctx5E0 槽+232 SetLobbyGameServer) / Shutdown 0x1423E4E50 (:237, bIsServer 自虚槽[29] + LeaveLobby + 清 +440) / LobbyLeave 0x1423E1700 (:1044, **server 只打日志 "SKIPPED (still server, lobby kept)" 不动 lobby**; 非 server 才 LeaveLobby + 清 +659/+440/+720 call result) / GetGameServer 0x1423E0CF0 (:1075, 出参块 {+24 server id, +32 IP, +36 port}) / ServerHide 0x1423E3D50 (:875, SetLobbyJoinable(false) + word 清 +657/+658, lobby 保留)。宿主布局 = +440 lobby id / +444 高 32 位位域 / +448 server id 快照 / +657 bIsServer / +658 就绪待办 / +659 未定 / +704 call result / +720 有效旗。Steam 接口描述符 = off_1430BF5E0 (ISteamMatchmaking 域推定: 槽+120 LeaveLobby / +232 SetLobbyGameServer / +240 GetLobbyGameServer / +264 SetLobbyJoinable) / off_1430BF610 (槽+64 登录门 / +80 GetSteamID 语义定案 / +312(0) 待裁) — 槽名按 SDK 对照待裁。**lobby CSteamID Chat 型快判式** = (高32 & 0xF00000)==0x800000 ∧ (高32 & 0x40000)!=0 (账户类型 8 ∧ instance 位 18; §4.36 全判定的 Chat 特化, 四函内联复用)。


**pdx_achievements_interface.cpp 成就统计量域 (整域新, 类名推定 CStatistic)**: 统计量对象 = +16 观察者 (写后调 vtable 槽[13]=+104) / +24 类型 {0 未初始化, 1 int, 2 float, 3 平均率} / +28 值槽 (int/float 二义) / +32 平均率缓存 (类型 3 SetFloat 时复位 -1.0f) / +36 率参数。SetInt 0x142398450 / SetFloat 0x1423982E0 / GetFloat 0x1423980E0 / GetInt 0x1423981D0 / UpdateAvgRate 0x142398620。通则: 类型错配**强转不拒绝** (int↔float), 唯平均率被 SetInt/SetFloat 硬拒 ("Cannot set average rate types, use UpdateAvgRate instead." :115) 必走 UpdateAvgRate; 断言非致命 (once 后 return 0); 门 = byte_1435E1B51, 旗 byte_1435BA026..30。⚠ 注意: 此文件断言串连字断行易被误读为 "evements_interface" — 真名 pdx_achievements_interface.cpp, 检索勿按误名归事件界面域。
