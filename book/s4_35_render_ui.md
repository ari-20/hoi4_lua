### 4.35 渲染/UI 体系

> 渲染与界面域专项调查的定案落账。账目: 域内 A 档 248 件归位 16 子系统 (§4.35.13);
> ≥1,000 行大件 34 个全列入册。阅读顺序 = §4.35.1 管线总览 → §4.35.2-5 各层 → §4.35.7-13 子系统与台账。

#### 4.35.1 管线总览与帧驱动

L0 帧驱动: main (sub_140126E50) → CApplication::Run (sub_14222E7E0, 钉单核) → 帧顶
sub_14222EEB0 → idler 派发 vt[4] Idle (ingame sub_140DD3A50 / frontend sub_140B3CA20 /
nudge sub_1412D49D0)。渲染槽[28] (thunk sub_1402A1700) → 渲染就绪门 sub_1422370E0
(graphics.cpp:2440) → 槽[29] 帧渲染体: ingame = sub_140DDDDF0 / frontend = sub_140B3D860。
旁路驱动: nudge 帧与 StartNewGame 走**应用级整帧包装链** sub_140B70FF0 → 门 sub_1422370E0 →
sub_140B41180 (BeginFrame) → sub_14223D2C0 → EndFrame → 截图闩。

L1 帧序 (槽[29] 帧内步序, 定案):

| 步 | 内容 |
|---|---|
| 1 | BeginFrame = sub_142236FF0 + 设目标 sub_1422374C0 (经设备 ABI 表 §4.35.5) |
| 2 | 世界/地图三段链 sub_140B56840 → sub_140B572D0 → sub_140B567E0 (§4.35.3); FE 侧有门 sub_14163F1B0 (idler+1560 菜单背景地图开关), ingame 无条件 |
| 3 | 加载淡入 quad (idler+1764/1768 尺寸) |
| 4 | **跳渲染旗 byte_14332F6A9 门 → 2D 树两连**: sub_14223D2C0 (树 1) → sub_14223D8B0 (树 2); 写者三处 = 双 idler Idle 热键 (键码 1073741890) + 控制台命令件 sub_14024C840; **只门 2D 树, 地图照渲** |
| 5 | 每帧对象/动画分发泵 sub_1402A1950 |
| 6 | ImGui 观察窗帧刷 (sub_1421D1C20 门 → sub_1420820D0 → sub_141198E70(idler+2608) → sub_142082120) |
| 7 | 瞬态横幅 ×4 (AUTOSAVING / SCREENSHOT_TAKEN / MAP_SAVED / Running Test...) |
| 8 | EndFrame sub_142238180 + 截图/横幅合成闩 sub_14223B030 (a1+1288 旗) |

截图合成件 sub_140B411B0 = BeginFrame + 装载屏轮换 sub_140B40BD0 + 横幅纹理盖印
(懒载字体 "vic_36" 经 sub_142238A20) + 整帧 2D 树 + EndFrame — 横幅即此路盖章。

#### 4.35.2 世界/地图渲染三段链

三段消费件 (a1 = idler vt[16] 结果对象 (持 CPdxMap@+88), a2 = vt[74] 结果):

| 段 | 函数 | 内容 |
|---|---|---|
| 1 地形 | sub_140B56840 | pdxmap 地形通道 sub_14127DA80 + 设置门控渲染通道 sub_14127E160 (pdxmap.cpp:2342) + 边界 LOD 刷新 sub_141288F80 (批量遍历件 sub_14127F4F0, 宿主串 "Update Border LOD") |
| 2 相机 | sub_140B572D0 | 相机/缩放插值 (a1+1728 clamp 0..1 / +1732 反向) |
| 3 对象 | sub_140B567E0 | pdxmap 对象层 sub_14127D900 + 地图物件 sub_1410083C0 |

类定案: **CEU3Camera = 相机类真名** (boost::bind RTTI `CPdxMap::mf2(CEU3Camera const*,
CPdxMap::SBorderRenderProxy)` 直证; SBorderRenderProxy = 边界渲染代理); CMapIdler 实现
CLostDeviceInterface (`CMapIdler::RestoreDeviceObjects` lambda 符号 ×2 = 设备丢失重建);
CGraphicalMap 两具名方法 = UpdateMapNameMode (sub_140B4F2E0, tbb/EMapNameMode) 与
UpdateProvinces (sub_140B4E860, PdxParallelFor)。InGame 与 FE 菜单背景地图**共用**三段链。

#### 4.35.3 CGraphics 对象布局与双 2D 树

CGraphics (idler+1264 / CGameApplication+864 同指; 基类布局 ~206KB):

| 偏移 | 语义 |
|---|---|
| +64 | 时间槽 (帧首拷贝源) |
| +72 | 矩阵槽 (帧首 +64→+72 拷贝) |
| +80 | 树 1 剪裁上下文 1 (SScissorRectangle) |
| +104 | 树 1 剪裁上下文 2 (SScissorRectangle) |
| +296 (+308=count) | 扁平化绘制列表 (顺序派发用) |
| +496 | **2D 树 1 根容器** (CPdxArray<CGraphicalObject*>) — 主树带剪裁 |
| +864 | **2D 树 2 根容器** — 第二遍无剪裁 = 顶层覆盖/tooltip 层 |
| +206228 | 后备缓冲宽 (绘制剪裁钳位源) |
| +206232 | 后备缓冲高 (绘制剪裁钳位源) |
| +206320 | CLostDeviceInterface 虚继承 |

#### 4.35.4 CGraphics::Render2dTree 与绘制派发

**CGraphics::Render2dTree = sub_14223D3F0 (定案**; tbb lambda 符号串
`Render2dTree(CGraphics*, …, CGraphicalObject**, SScissorRectangle const*, …)` 直证)。内部三步:

1. BFS 展开进全局渲染队列 qword_1434530A0 (48B/项; count = dword_1434530AC, 容量 =
   dword_1434530A8, 分配器槽 qword_1434530B0 = off_143085170); 每节点可见性/布局 =
   sub_1422AE800, 子向量 @对象+208。
2. tbb parallel_for (≥12 项才并行) 对本层条目并行处理。
3. 顺序绘制派发 sub_14223DB60: 逐项走对象虚表 **+80 = Draw 槽**, 剪裁推/弹 =
   off_1430BF988 / off_1430BFA18 设备调用对, 视口钳位 +206228/+206232。

同步局部重绘: gui.cpp 事件分派 sub_14225C690 / sub_14225CF20 尾调 **sub_14223BBA0** =
只重渲染树 1 — 输入事件路径自带同步重绘, 不经 idler 渲染槽。调试旗 GUI.Wireframe
byte_143453088 (控制台可注册): sub_14223D2C0 帧首/尾各一次设备调用 off_1430BFA70。

#### 4.35.5 图形设备 ABI 与三后端

设备 ABI 分派表 = off_1430BF7B0 .. off_1430BFA88 (~70 个全局函数指针槽; 帧/绘制代码一律经此表
调设备, 部分槽在后端 = 空桩)。后端选择器 sub_1424047C0(后端 id) 三分支; **三渲染后端:
dx9(0) / opengl(2) / opengl4(3)** — 选择串直证 (graphicssettings.cpp:172): `opengl`/`ogl` → 2,
`opengl4` → 3, `dx9`/`dx9_compat` → 0, `dx9legacy` → 旗 byte_1435DA930; id 1 无独立串 (与 3
共用函数域)。后端 2 = OpenGL 定案 (表槽函数引 pdx_gfx\gfx_opengl.cpp 断言; GL 上下文 =
wglCreateContext/wglMakeCurrent)。GL 扩展装载双件 = sub_142438B50 (gl3w 形态 5,472 行) +
sub_142441940 (WGL 枚举 3,665 行)。图形设置装载 = sub_14241A230 ("Loading settings for
adapter")。shader filter 类型枚举: "2d"=0 / "shadow"=0 / "cube"=1 / "3d"=2
(gfx_helper.cpp:142)。SDL2-2.0.20 静态链 = 窗口/软光栅底座。

#### 4.35.6 启动/资产层 (§4.28.21 增补)

Init 链: InitTextureLookup(gfx/models) sub_142266590 → InitBase sub_140181110 →
Init3DTypes sub_142238FD0 ("Long Task"; 实参 = CGameApplication+864 CGameGraphics*) →
LoadAssets sub_140B39270 → InitGame。⚠ **LoadAssets 名不符实** (勘误): 体仅两行 = 注册菜单
web_link 解析器回调 (twitter/youtube/discord/facebook/instagram 链接项), 非图形资产装载;
图形侧资产装载真身 = InitTextureLookup + LoadDefinitions<CMapArrowManager> (§4.26) +
InitGame 资产批 (§4.29)。渲染相关热重载四对: gfx (interface, CGFXReloader) / assets /
equipment_graphic_database / train_gfx_database; "Map reloaded"/"Map arrows reloaded" =
地图资产热重载回显。

#### 4.35.7 子系统清单 (16 子系统)

| # | 子系统 | 代表编译单元 (depth3 行数) | 代表函数 |
|---|---|---|---|
| S1 | 设备/后端 (pdx_gfx) | gfx_opengl 343 / gfx_glsl_builder 1,148 / gfx_texture_loader 190 | sub_1424047C0 后端表; sub_142438B50 GL 扩展 |
| S2 | 帧管线/2D 树 | graphics.cpp 778 | sub_14223D3F0 Render2dTree; sub_14223DB60 Draw 派发 |
| S3 | 地图图形 (map_graphics) | map.cpp 2,053 / pdxmap.cpp 1,310 / mapbuildings 1,466 / provincegraphics 981 | sub_141244070 地图箭头; sub_141B204A0 省界生成 |
| S4 | 渐变边框/边界 | gradientborder 三件 1,010 | sub_14159BBE0 tbb 任务体; sub_140F36C50 claim 管理 |
| S5 | 地图模式 | mapmodemanager 946 / defines_mapmode 1,588 / custom_map_mode 603 | sub_140E14680 OnMapModeChange; sub_140E1B280 逐省着色 (§4.2 链) |
| S6 | 地图图标 | mapicon.h 1,358 / mapiconmanagerimpl 691 | §4.30.26-28 类族 |
| S7 | 地图箭头/前线几何 | maparrow 481+370 / raid_arrow 824 | sub_141244070; sub_1423F4C90 点集切分; sub_141039F80 寻路 |
| S8 | 相机/交互输入 | (0x140DB-DC / 0x14126 区) | CEU3Camera; sub_1412627C0 热键+位移 |
| S9 | GUI 框架核心 | containerwindow / buttonwrapper / gui.cpp | sub_1402A44A0 .gui 解析; sub_14225C690 事件分派 |
| S10 | 字体/文本渲染 | bitmapfont 2,102 | sub_14229C770 装载; sub_1422A1810 布局 |
| S11 | 文本引擎/本地化 | (0x1421E / 0x14224 / 0x1411B 区) | sub_1421EAA30 文本流格式化; sub_1411B4B10 浮点格式化 |
| S12 | 纹理/像素搬运 | texturehandler 949 / gfx_texture_cache 392 / flagtextureatlas 1,002 | sub_142133600 上传核; sub_142171F50 blit |
| S13 | 软件光栅 | SDL_render_gl 2,137 / SDL_render_gles2 1,612 | SDL_BlendLines 三核; 分派器 sub_1421A31A0 |
| S14 | 3D 实体/动画/粒子 | pdx_anim 1,185 / pdx_particle 408 | sub_14228D730 挂点定位; sub_1423FE460 粒子更新 |
| S15 | 调试/ImGui | pdx_dearimgui | sub_1421CBE30 Begin 原语; 观察窗族 |
| S16 | 面板/视图 GUI 行件 | (0x1416-0x141F GUI 区) | ~120 件, §4.35.13 分组台账 |

#### 4.35.13 渲染系 A 档归位台账 (248 件)

按子系统分组 (★ = ≥1,000 行)。S16 面板/视图行件 108 件逐件全表见下,
其余子系统全列。

| 子系统 | 件数 | 件清单 (★=≥1000 行) |
|---|---|---|
| S1 设备/后端 | 3 | ★sub_142438B50 5,472 GL 扩展装载; ★sub_142441940 3,665 WGL/GL 扩展; ★sub_14241A230 1,729 适配器设置装载 |
| S3 地图图形 | 9 | ★sub_141244070 5,020 地图箭头绘制; ★sub_1423F4C90 4,233 前线点集平面切分; ★sub_141B204A0 2,248 省界图形生成; ★sub_1423BA890 2,763 SSE 数学内核; ★sub_1420A8510 1,560 float3 几何; sub_1412761A0 1,257 断言域巨函; sub_1412615B0 146 视觉数学; sub_14124F710 319 导弹/爆炸实体; sub_140B52C90 269 懒初始化/FX |
| S4 渐变边框 | 18 | sub_140F34020 465 队列装配; sub_140F37330 388; sub_140F36C50 351 claim 管理; sub_14159BBE0 307 tbb 任务体; 家族件 14 (140F3A680/A0D0/38E60/39BF0/36710/38A30/34F90/37A40, 1417A1920/A2D490/27F4F0 1,122 LOD, 140A5CDC0/359D0, 140F3B370 431 池管理) |
| S5 地图模式 | 11 | sub_140E15A40 476 特工任务着色; sub_140E14680 470 OnMapModeChange; sub_140E1D2E0 396; sub_140E13FE0 307; sub_140E1CD90 288; sub_140E13A80 271; sub_140E1A400 269; sub_140E152F0 253; sub_140E1DD10 163; sub_140E1E090 159; sub_140E157F0 120 国色图例 |
| S6 地图图标 | 1 | ★sub_1418C99A0 1,141 建设图标 tooltip |
| S7 箭头/前线几何 | 3 | ★sub_141039F80 1,746 advancement 寻路; ★sub_14126FD50 1,162 纹理校验; sub_141662150 102 三池析构 |
| S8 相机/交互 | 4 | sub_1412627C0 392 热键+位移; sub_141261960 207 清场; sub_140DC0860 230 / sub_140DC0B20 181 递归数学 |
| S9 GUI 框架核心 | 18 | ★sub_1402A44A0 1,621 .gui 解析; ★sub_14230FEE0 1,313 重复类型校验; ★sub_1422BE890 1,511 布局递归; ★sub_141CDC170 1,165 文本项元件; sub_1422A4110 100 锚点分派; sub_14225C690 279 事件分派; idler/tick 族 12 (14167DB20/1412DFDC0/141289980/140DDDA40/1419AD3E0/140B92B30/141688A60/1422DC530/1417A7310/141833DB0/140CBC200/1416408A0) |
| S10 字体/文本渲染 | 4 | ★sub_14229C770 1,654 字体装载; ★sub_1422A1810 1,036 布局/图标; ★sub_1422A0230 1,049 缓冲构建; sub_142238A20 102 解析共享 |
| S11 文本引擎/本地化 | 14 | ★sub_1421EAA30 2,087 文本流格式化; ★sub_1411B4B10 1,930 浮点格式化; ★sub_14252ACD4 1,214 money_get; ★sub_1418530F0 1,272 / ★sub_140E18DF0 1,079 / ★sub_1412517B0 1,002 定长缓冲三件; ★sub_140D20450 1,336 战争名键求值; sub_142245880 235 $展开; sub_14224B9F0 225; sub_140BD3530 388; sub_140BD2F80 279; sub_140FD2240 264; sub_1411C5D30 255; sub_14225CD50 102 |
| S12 纹理/像素 | 8 | ★sub_142130DF0 1,617 搬运/填充; ★sub_142171F50 1,492 blit 巨函 (×24 分量表); ★sub_142133600 1,338 上传核; ★sub_14219BF40 1,401 / ★sub_14219D7D0 1,397 16 位变体; ★sub_14218FCE0 1,365 GUI blit; sub_14225FF10 106; sub_140D5BBC0 1,590 robin-hood 枚举 (通用基建) |
| S13 软件光栅 | 4 | ★sub_1421A0670 1,830 自递归内核; ★sub_142197DD0 1,604 16bpp 混合; ★sub_142196690 1,429 32bpp RGBA; ★sub_14219F1E0 1,315 32bpp RGBX |
| S14 3D 实体/动画/粒子 | 4 | ★sub_14228D730 1,400 挂点查找; ★sub_14228AF80 1,461 attachment 定位; ★sub_1423AE8F0 1,115 float4 流变换; sub_1423FE460 280 粒子更新 |
| S15 调试/ImGui | 9 | ★sub_1422095C0 2,394 profiler SIMD 内核; ★sub_1421CBE30 1,426 Begin 原语; ★sub_1421F4480 1,156 / ★sub_1421F9450 1,134 观察窗族; ★sub_141B0F6D0 1,066 Faction Member 窗; ★sub_1410652F0 1,128 AI 前线调试; sub_1421D9B40 213; sub_1422A2F90 114 DebugTexture; sub_140222300 105 采样三缓冲 |
| S17 资产装载/压缩 | 6 | ★sub_142388030 2,950 bzip2 解码; ★sub_14250CD90 1,537 range 解码; ★sub_14123D920 1,087 旗帜图集装载; sub_140B406A0 248 国旗图集; sub_140B40BD0 202 装载屏轮换; sub_140FA30E0 470 库条目实例化 |
| S18 基础库旁支 | 5 | sub_140E84150 192 批量释放; sub_14029E0F0 118 POD 拷贝; sub_140B6BC60 115 idpair 去重; sub_140210AF0 202 核爆遥测 (素材包误纳); sub_1406A40E0 101 career 云清理 |
S16 面板/视图 GUI 行件逐件表 (108 件, 按组):

##### S16a 军队/军事 (24)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1418D35C0 | 3,103 | 单位领袖 tooltip |
| ★sub_1416A3930 | 2,299 | 陆军视图 tooltip |
| ★sub_1417C39E0 | 2,120 | 师数文本 |
| ★sub_140F454A0 | 1,694 | 军令 tooltip (orderstools.cpp) |
| ★sub_141258D30 | 1,848 | 军令绘制文本 |
| ★sub_1413EBD60 | 1,513 | 边境冲突窗 |
| sub_1416DDD90 | 1,531 | 战斗计划工具窗 |
| sub_141D198E0 | 1,493 | 指挥官能力 |
| sub_141D55700 | 1,487 | 建造修理队列 |
| sub_141562C30 | 1,462 | 占领面板 |
| sub_141FCF8D0 | 1,458 | 联队行 |
| sub_14187D580 | 1,445 | 空军视图过滤 |
| sub_141D86160 | 1,310 | 部署面板 |
| sub_141D145E0 | 1,264 | 将领特质/顾问 |
| ★sub_141D51300 | 1,170 | 生产线 refit 明细 |
| sub_141D26B30 | 1,127 | 模板 AI 评估 |
| sub_140AE8120 | 1,125 | 特质加成装配 (unitleadertraits.cpp) |
| sub_1416B1C00 | 1,108 | 勋章历史窗 |
| sub_14158CA70 | 1,095 | 袭击装备缺口 |
| sub_14175C2B0 | 1,045 | 师编制网格 |
| sub_1416B05C0 | 1,006 | 部署师列表 |
| sub_1419AB510 | 248 | 突袭状态缓存 |
| sub_1419ACCB0 | 232 | 突袭缓存件 |
| sub_1419ABE00 | 198 | 突袭缓存重建体 |

##### S16b 外交/租借 (6)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1415E5C60 | 2,850 | 国家列表面板 |
| ★sub_141C55960 | 1,837 | 流亡政府视图 |
| ★sub_14196C300 | 1,080 | 租借明细 |
| sub_1415833C0 | 1,110 | 政治视图装配 (归 S16e 更准) |
| ★sub_1411282F0 | 1,017 | 战争目标成本 |
| sub_14112A270 | 1,046 | 毁约行动 |

##### S16c 贸易/市场 (4)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_141CBA9D0 | 1,805 | 贸易 tooltip |
| ★sub_140CAEF80 | 1,714 | 出口明细面板 |
| ★sub_140CB0ED0 | 1,088 | 进口明细 |
| sub_1406EC400 | 119 | TRADE_FACTOR_BASE |

##### S16d 科研/科技树 (6)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_141BDED00 | 2,277 | tech info |
| ★sub_141BDB140 | 2,197 | 科研 XP |
| sub_140ED7CE0 | 1,137 | 前置需求 |
| ★sub_140EDD7D0 | 1,041 | 科研加成 |
| sub_1413D6490 | 1,034 | 科技树网格盒 |
| sub_140EDFD20 | 105 | 进度 |

##### S16e 政治/焦点/决议 (10)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_14171E990 | 1,664 | 决议 tooltip |
| ★sub_141F4D520 | 1,149 | idea 槽条目 |
| ★sub_141720800 | 1,125 | 计时决议行 |
| ★sub_141C45050 | 1,057 | idea 取消/规则 |
| ★sub_14203A0C0 | 1,084 | 生涯档案统计 |
| ★sub_140DF5370 | 1,087 | 焦点 desc |
| sub_1415833C0 | 1,110 | 政治装配 (自 S16b 挪入) |
| sub_14138C490 | 208 | 国策条目 (NationalFocusView) |
| sub_140B79230 | 184 | 焦点完成弹窗 (CFocusFinishedPopUpWindow RTTI) |
| sub_1406F2770 | 435 | 稳定度周变化 |

##### S16f 海军/海战 (13)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_141E29DE0 | 2,117 | 特混编成编辑器 |
| ★sub_14143D3E0 | 2,004 | 海军 tooltip |
| ★sub_141BF0C60 | 1,242 | 舰船属性页 |
| ★sub_141E27000 | 1,168 | 舰队视图条目 |
| ★sub_141F96700 | 1,157 | 海战舰船行 |
| ★sub_140D6D2C0 | 1,128 | 海军力量统计 |
| ★sub_141F90540 | 1,063 | 将领/舰队详情 |
| sub_141976DB0 | 1,190 | 航母效率 |
| sub_1418EE340 | 1,179 | 海军基地 |
| sub_1417EDF20 | 1,032 | 海战空战图标 |
| sub_1417E6700 | 1,007 | 海战船只 |
| sub_140C395A0 | 267 | 统计值表 |
| sub_140D651C0 | 160 | 组织度打击比 |

##### S16g 生产/建设/装备 (净 5)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_141788E70 | 2,497 | 模块选择窗 |
| ★sub_14176B330 | 2,464 | stats 网格 |
| ★sub_141780F80 | 2,077 | 装备设计器 tooltip |
| sub_141F78DD0 | 1,049 | 海军模块图标 |
| ★sub_141438470 | 1,008 | 许可证生产速度 |

##### S16h 后勤/补给/燃料/人力 (7)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1410F35E0 | 2,261 | 燃料 tooltip |
| ★sub_141D97D50 | 1,598 | 补给效率 |
| ★sub_141631E60 | 1,322 | 州补给 |
| ★sub_141EC0450 | 1,289 | 预算图表 (ledgerview_civilian.cpp) |
| ★sub_14172E9A0 | 1,252 | 后勤统计页 |
| sub_140CFCB10 | 1,046 | 人力用途 |
| sub_1410C2030 | 1,023 | 资源燃料明细 |

##### S16i 战斗/适应度 (2)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1415D3F60 | 1,614 | 战斗窗供应器 |
| sub_1416BAD10 | 1,213 | acclimatization 明细 |

##### S16j 谍报/间谍/情报 (4)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_140E10910 | 2,021 | 情报网络 |
| ★sub_140FC1200 | 1,099 | 任务覆盖明细 |
| ★sub_141EB42D0 | 1,000 | 谍报账本 |
| sub_141835130 | 290 | 间谍视图 |

##### S16k 占领/志愿/角色 (3)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1416CEB40 | 1,277 | unit_leader 角色窗 |
| sub_14163A100 | 1,031 | 志愿军命名 |
| sub_141561070 | 1,011 | 驻军条 |

##### S16l 警报/修正/统计 loc (12)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1423D23A0 | 1,568 | 修正对比 |
| ★sub_14063D550 | 1,552 | 单位统计 loc 分发器 (~77 案) |
| ★sub_140B0AB70 | 1,256 | 警报明细 (alertmanager.cpp) |
| sub_1407008C0 | 1,498 | 警报条件检查 |
| sub_140C17F40 | 368 | 修正 tooltip |
| sub_1411D1E30 | 362 | (修正侧) |
| sub_1411F8F10 | 345 | 修正文本件 |
| sub_140B07150 | 327 | 警报管理器内部件 |
| sub_140702890 | 300 | 警报管理器内部件 |
| sub_140B34A10 | 283 | 警报管理器内部件 |
| sub_1406FB4E0 | 272 | 战争支持度周变化 |
| sub_140D792F0 | 105 | (归 S6 资产, 兼) |

##### S16m 地图交互 tooltip 簇 (5)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_140E05340 | 3,488 | 省份点击 tooltip 构建器 |
| ★sub_140E0D390 | 1,413 | 战略区域段 |
| ★sub_1419EB850 | 1,208 | 海军通行权限 dump |
| ★sub_141B7FCF0 | 1,055 | 天气概率 (weathernudger.cpp) |
| ★sub_140F1A630 | 1,024 | 天气 debug 报告 (其调用方) |

##### S16n 杂项窗口 (9)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_140B8BE40 | 1,089 | 脚本窗口管理器 (scriptedwindowmanager.cpp) |
| ★sub_1424D6C40 | 255 | 错误弹窗 |
| sub_141877110 | 459 | 多人玩家列表 |
| sub_1419CDC00 | 308 | GUI 弹窗 |
| sub_1419C7270 | 238 | 教程屏 |
| sub_1417AFAF0 | 205 | 请求窗 |
| sub_142232A90 | 118 | continue_game.json 装载 |
| sub_142204E30 | 387 + sub_142205CF0 234 | 加载进度回调对 |
| sub_1417B4A80 | 107 | 主菜单保存按钮 |



细作专批优先序 (按体量 × 框架消费价值): CGraphics 布局全量测绘 (双树根容器/绘制列表 48B 项/剪裁结构, 一次探针批) > 地图箭头族 (5,020 行主件 + manager 布局) > 地图模式管线 (OnMapModeChange 全链数据流) > 后端 ABI 表槽语义标注 (~70 槽 × 3 后端, scan_symbols.py 路线) > 字体/文本链。
