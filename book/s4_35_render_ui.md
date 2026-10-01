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

按子系统分组 (★ = ≥1,000 行)。S16 面板/视图行件 108 件为分组摘要 (逐件身份见 findings 原档),
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
| S16 面板/视图行件 (分组摘要) | 108 | 军事 24 (★单位领袖 tooltip 3,103 / ★陆军视图 2,299 / ★师数文本 2,120 / ★军令 tooltip 1,694 / ★边境冲突窗 1,513 等); 外交 6 (★国家列表 2,850 / ★流亡政府 1,837 等); 贸易 4 (★贸易 tooltip 1,805 等); 科研 6 (★tech info 2,277 / ★科研 XP 2,197 等); 政治/焦点/决议 10 (★决议 tooltip 1,664 / ★idea 槽 1,149 等); 海军 13 (★特混编成 2,117 / ★海军 tooltip 2,004 等); 生产/装备 5 (★模块选择窗 2,497 / ★stats 网格 2,464 / ★装备设计器 2,077 等); 后勤/补给 7 (★燃料 tooltip 2,261 / ★补给效率 1,598 等); 战斗 2; 谍报 4 (★情报网络 2,021 / ★谍报账本 1,000); 占领/角色 3 (★角色窗 1,277); 警报/修正/loc 12 (★修正对比 1,568 / ★单位统计 loc 分发 1,552); 地图交互 tooltip 5 (★省份点击 3,488); 杂项窗口 9 (★脚本窗口管理器 1,089) |

细作专批优先序 (按体量 × 框架消费价值): CGraphics 布局全量测绘 (双树根容器/绘制列表 48B 项/剪裁结构, 一次探针批) > 地图箭头族 (5,020 行主件 + manager 布局) > 地图模式管线 (OnMapModeChange 全链数据流) > 后端 ABI 表槽语义标注 (~70 槽 × 3 后端, scan_symbols.py 路线) > 字体/文本链。
