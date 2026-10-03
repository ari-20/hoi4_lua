### 4.35 渲染/UI 体系

> 渲染与界面域定案落账。§4.35.13 = 域内 248 件按 16 子系统的函数地图;
> ≥1,000 行大件 34 个全列入册。阅读顺序 = §4.35.1 管线总览 → §4.35.2-5 各层 → §4.35.7-13 子系统与函数地图。

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

| 项 | 值 | 证据 |
|---|---|---|
| CGraphics 本体（含虚基前全部） | **206,328B**（ctor 最大写偏移 +206316，+206320 虚基） | ctor L3026763..3027300；DeInit 置 +206316=0（L3479886 附近） |
| CAnimViewerGraphics 分配 | malloc(0x325F0) = **206,336B**（= CGraphics 206328 + 虚基 8B 对齐） | L3926172；分配后先跑 CGraphics ctor 再覆写 vtable = CAnimViewerGraphics（L3926180-3926182） |
| CGameGraphics 分配 | malloc(0x32A00) = **207,360B**；日志 "InitBase:: CGameGraphics takes N KB memory."（gameapplication.cpp:1379） | L3905770-3905795 |
| CLostDeviceInterface 虚基 | **vptr @+206320，8B**（dtor 恢复 `*(Block+206320) = &CLostDeviceInterface::vftable'`；CGameGraphics 成员自 +206328 续接） | L1510358-1510359（两处 vtable 写，25790×8 = 206320）、L7756005-7756007 |
| CGraphics ctor | `sub_142235600(this, window_mgr, settings)` | L3026763 |
| 设备初始化（Init 尾段） | `sub_142239540(this, window_mgr)`（ctor 尾调用；**此函数内 `qword_143453090 = this` 写单例**） | L3027159（ctor 内调用）、L7058727 |
| CGraphics dtor | `sub_14223D220(this, vbase)`（由 CGameGraphics dtor 调） | L1510377（`sub_14223D220(Block, Block + 206320)`） |
| 基类 dtor 壳 | `sub_142236330`（vtable 恢复 + 折叠） | L2089068 |
| CGameGraphics ctor / dtor | `sub_140B3FEB0` / `sub_140B3FFE0` | L7756003 / L1510347 |
| DeInit 守卫 | 未初始化时 "Attempted to DeInitialize CGraphics without first initializing it."（graphics.cpp:1763） | L3479819 |
| 单例 CGraphics::Get() | `qword_143453090`（GetSpriteType 断言串直证 "CGraphics::Get()->GetSpriteType( SpriteName )"） | L7058727、L7527205 |
| 实参 a2 | `*(CGameApplication+104)` = 窗口/显示管理器对象（内联成员，ctor `sub_141332690`；vt+520 查窗口化、vt+648/656 切模式），存 CGraphics+8 | L3905778、L3905779（a2=v31=*（a1+104)） |
| 实参 a3 | CGraphicsSettings*（`sub_14222BD90()` 双跳取单例），存 CGraphics+1248 | L863234、ctor L3027063 |
| 派生杀链 | CAnimViewer 路径：malloc → sub_142235600 → 覆写 vtable；游戏主路径：malloc(0x32A00) → sub_140B3FEB0 → 挂 CGameApplication+864 | L3926172 / L3905779 |




> 证据列缩写：ctor = sub_142235600（L3026763 起）；devinit = sub_142239540
> （L7058529 起）；dtor = sub_140B3FFE0（L1510347 起）；R2D = sub_14223D3F0
> （L5276956 起）；DISP = sub_14223DB60（L601346 起）；FLAT = sub_14223BB10
> （L761857 起）；D2C0 = sub_14223D2C0（L5686699 起）。


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | CGraphics*（vtable） | 主虚表（派生覆写） | ctor L3026766 |
| +8 | 窗口/显示管理器* | ctor 实参 a2 原样存 | ctor L3026767；devinit L7058732 |
| +16 | CPdxArray (24B) | {data,cap,count,alloc} 容器 #0（`sub_14011DF40` 初始化，alloc=off_143085170）；内容语义未决 | ctor L3026768；sub_14011DF40 L3726791 |
| +40 | CPdxArray (24B) | 容器 #1（+40/+48/+56 手工内联初始化）；内容语义未决 | ctor L3026785-3026802 |
| +64 | float×2 | **光标位置槽（当前帧）** {x,y}：AE800 命中测试按 {x×aspect_x, y×aspect_y} 对剪裁框判定；帧首 D2C0/BBA0 做 +64→+72 拷贝 | AE800 L1199735（`*a5`/`HIDWORD(*a5)` × a4）；D2C0 L5686725 |
| +72 | float×2 | 光标位置槽（帧首自 +64 拷贝的副本） | D2C0 L5686725；BBA0 L1701948 |
| +80 | CPdxArray (24B) | **展平输出列表 A**：命中测试通过的可见项（FLAT bit2 → push 节点指针）；R2D 实参 a6（非空 = 开启命中测试模式位）；devinit 按容量增长（<2048 → max(1.5x,2048)） | devinit L7058700-7058717；FLAT L761864；R2D L5276981 |
| +104 | CPdxArray (24B) | **展平输出列表 B**：交互目标项（FLAT bit1，要求节点 +328 非空）；R2D 实参 a7（非空 = 开启目标收集模式位） | devinit L7058718-7058731；FLAT L761867；AE800 L1199722 |
| +128 | 设备句柄 | 主设备对象（`off_1430BF7B0(&params,&err)` 创建；失败降级桌面分辨率重试 graphics.cpp:979-981；DISP/其他帧件全部经 +128 取设备） | devinit L7059198-7059262 |
| +136 | 设备状态对象 | 设备 ABI `off_1430BF958()` 创建（状态组 1） | devinit L7059290-7059316 |
| +144 | 设备状态对象 | 同上（组 2） | devinit L7059303 |
| +152 | 设备状态对象 | 同上（组 3） | devinit L7059304 |
| +160 | 设备状态对象 | 同上（组 4，参数变体 DWORD2=7） | devinit L7059312-7059313 |
| +168..+200 | 设备状态对象 ×5（+168/+176/+184/+192/+200） | 设备 ABI `off_1430BF978()` 创建（BYTE8 旗变体；渲染状态族：混合/采样器类） | devinit L7059317-7059330 |


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +208 | {int32 count, int32 cap=511, ptr} (16B) | 定容指针数组 #1（malloc 0xFF8 = 511×8B；dtor `sub_1401C1510` 释放）；内容语义未决（dtor 迭代元素走 vt+80 并随 [1] 链，见 DeInit 对 +1328 同型数组的用法） | ctor L3026875-3026880 |
| +224 | std::string (32B) | MSVC 串（SSO +248=15）；内容未写入 ctor，语义未决 | ctor L3026883-3026887 |
| +256 | {int32 count, int32 cap=511, ptr} (16B) | 定容指针数组 #2（同 +208 形态） | ctor L3026888-3026893 |
| +272 | 24B 件（sub_14011DF40） | CPdxArray #N（ctor 内联第三形态）；内容语义未决 | ctor L3026894 |
| +296 | **CPdxArray (24B)** | **扁平化绘制列表**：{data@+296, cap@+304, count@+308, alloc@+312}；FLAT bit0 输出（绘制顺序 = BFS 序节点指针）；DISP 消费（count 在 +308）；增长同 1.5x/2048 | devinit L7058679-7058695；FLAT L761862；DISP L601356 |
| +320 | CPdxArray (24B) | 容器（+320/+328 清零、+336=alloc）；语义未决 | ctor L3026934-3026962 |
| +344 | CPdxArray (24B) | 容器（+344/+352 清零、+360=alloc）；语义未决 | ctor L3027076-3027077 |
| +368 | CTextureHandler* (128B+) | 纹理管理器（`sub_142406120` 构造；devinit 写其 +104 = 主设备 +128、+112/+120 = 派生块 +840/+848 帧缓存信息） | ctor L3027078-3027088；devinit L7059330-7059338 |
| +376 | {i32 宽, i32 高} | **全分辨率对**（settings +188 `size` 对拷入；设备创建失败降级时被写回桌面分辨率） | ctor L3027089/L3027101-3027105；devinit L7059256-7059258 |
| +384 | {i32 宽, i32 高} | **UI（min_gui）分辨率对**（settings +204 `min_gui` 对拷入；ctor 尾按长宽比适配 + 1/gui_scale 缩放后回写） | ctor L3027090/L3027106-3027146 |
| +400 | float[16] (64B) | **正交投影矩阵**（D3D 列主序 OrthoOffCenter 形态：[0]=2/(r-l)、[5]=2/(t-b)、[10]=1.0f、[12]=-tx、[13]=-ty、[14]=-0.0f、[15]=1.0f；由适配后 UI 分辨率构建） | ctor L3027120-3027140 |
| +464 | float ×4 | {uiW/fullW, uiH/fullH, 1/(uiW/fullW), 1/(uiH/fullH)}（UI 分辨率占比及倒数；AE800 命中测试用 +472/+476 做光标屏幕坐标换算） | ctor L3027141-3027144；AE800 L1199735 |


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +496 | C2dPositionObject (368B) | **2D 树 1 根**（vtable 先 CGraphicalObject 后覆写 C2dPositionObject；+800=根+304 {w,h} 屏幕尺寸对、+820=根+324 字节旗） | ctor L3027092-3027097 |
| +864 | C2dPositionObject (368B) | **2D 树 2 根**（同构；+1168=根+304、+1188=根+324；R2D 调用 a6=0 = 无剪裁/无命中测试） | ctor L3027098-3027102；D8B0 L4693112 |
| +1232 | {uint64 0, int32 0, uint8 0} (16B) | 16B 状态块（语义未决；+1232 帧内偶读） | ctor L3027103-3027105 |
| +1248 | CGraphicsSettings* | settings 引用（devinit 全程密集读取） | ctor L3027106 |
| +1256 | uint8 | 影子贴图意愿门（devinit：`sub_142229D50(settings)`=硬件支持时若此位非 0 → 日志 "Hardware supports \"shadowmapping\", shadows enabled."；否则 `sub_142229D40(settings,0)` 关闭） | devinit L7059341-7059390 |
| +1264 | CPdxArray (24B) | 容器（+1264/+1272 清零、+1280=alloc）；语义未决 | ctor L3027107-3027123 |
| +1288 | uint16 = 1 | 初始 1（消费点未定） | ctor L3027124 |
| +1308 | float = -1.0 | 三浮点初值组（语义未决） | ctor L3027125-3027127 |
| +1312 | float = -1.0 | 同上 | ctor L3027126 |
| +1316 | float = 0.5 | 同上 | ctor L3027127 |
| +1320 | {int32 count, int32 cap=511, ptr} (16B) | 定容指针数组 #3（DeInit 遍历：元素走 vt+80(this) 并沿元素+8 链——**屏/根对象注销表**形态） | ctor L3027128-3027131；DeInit L3479770-3479800 |
| +1336 | CEffectHandler (204,880B) | **内嵌效果/着色器池**（见 §4.2）；恰占 +1336..+206215，与 +206216 下一字段严丝合缝 | ctor L3027132；sub_142409480 L5650372 |


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +206216 | 设备根对象* | devinit 首建（工厂 `sub_1422333C0()` 单例 → vt+8 创生）；紧接 `sub_14224DC90` 消费 | devinit L7058718-7058732 |
| +206224 | int32 = 0 | 状态字（DeInit 分支清零；语义未决） | ctor L3027152；devinit L7059396 |
| +206228 | int32 | **后备缓冲高**（= +380 值；DISP 视口钳位 bottom=min(bottom,+206228)）——⚠ 与书对调，见 §7 | ctor 无初值；devinit L7059397-7059399；DISP L601385-601390 |
| +206232 | int32 | **后备缓冲宽**（= +376 值；DISP 视口钳位 right=min(right,+206232)） | 同上 |
| +206236 | float = 1.0 | 分辨率应用时重置的浮点（+206240 = 0；语义未决） | devinit L7059400 |
| +206244 | int32 = 0 | 状态字（语义未决） | devinit L7059396 |
| +206256 | CParticleReloader* | 热重载件 ×5（注册名 "particle"）：new 后交 `sub_1422564C0` 登记 | ctor L3027153-3027230 |
| +206264 | CTextureReloader* | 热重载件（"texture"） | ctor L3027231-3027250 |
| +206272 | CMeshReloader* | 热重载件（"mesh"） | ctor L3027251-3027271 |
| +206280 | CAnimationReloader* | 热重载件（"anim"） | ctor L3027272-3027292 |
| +206288 | CGuiAnimationReloader* | 热重载件（"guianim"；**双 vtable 多基**，+8 存 this 反指） | ctor L3027293-3027300 |
| +206296 | float | **gui_scale**（ctor 读 settings+212 浮点；ctor 尾以 1/gui_scale 缩放 UI 分辨率对） | ctor L3027151；settings 取值器 sub_142228770 L6919498 |
| +206300..+206315 | 14B 零块 | {uint64 0, uint64 0}（+206300/+206308） | ctor L3027153-3027155 |
| +206316 | uint8 | **已初始化旗**（ctor 置 0；devinit 成功路径隐含置位；DeInit 尾清 0，未初始化即拒） | ctor L3027156；DeInit L3479886 |



#### 4.35.3a 双 2D 树节点 — CGraphicalObject 基类布局 (368B; 定案)


基类 ctor = `sub_1422AE140`（L6539533），368B；树根 = C2dPositionObject（ctor 内联：
AE140 之后覆写 vtable + 写 +304/+324）。类层级（书 §4.31 已有）：CSprite →
C2dVisibleObject → C2dObject → CGraphicalObject；C2dPositionObject → C2dObject →
CGraphicalObject。实例计数器 = `dword_143481104`（ctor 递增）。

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | vtable | CGraphicalObject 主表（根被覆写 C2dPositionObject） | AE140 L6539545 |
| +16 | uint64 = 0 | 未名（AE140 只清零） | AE140 L6539543 |
| +32 | CColor (32B) | 内嵌颜色对象（vt=CColor::vftable；+48 处以 {1.0f×4} 常量 xmmword_1430BDF00 初始化 = 白色族；+36..+47 本 ctor 未写） | AE140 L6539546-6539548；PE 取常量 = 4×0x3F800000 |
| +64 | uint8×2 = {1,1} | 双字节旗（dword 65537 = 0x010001；+65 在 AE800 命中分支读：非 0 且全局门关 → 跳过命中测试） | AE140 L6539550；AE800 L1199725 |
| +68 | int32 = -1 | 未名（-1 哨兵） | AE140 L6539551 |
| +80 | float[16] (64B) | **布局变换矩阵（恒等初始化，列主序 4×4）** | AE140 L6539552-6539561 |
| +128 | float | 局部偏移 x（AE800：光标累加位 = 父位 + 此值） | AE800 L1199752 |
| +132 | float | 局部偏移 y | AE800 L1199755 |
| +136 | int32 = 0 | 未名 | AE140 L6539564 |
| +140 | float = 1.0 | 未名（比值/缩放候选） | AE140 L6539565 |
| +144 | float[16] (64B) | **渲染矩阵（Draw 槽第 4 参 = this+144）**：[0]=累计缩放 x、[4]=累计缩放 y（AE800 写 f32@+144/+164）、[8]/[9]=旋转槽（旋转时写）、[12]=绝对 x、[13]=绝对 y、[15]=1.0 | AE140 L6539566-6539577；AE800 L1199758-1199761；DISP L601399（`v8+18` = 指针算术 ×8 = +144） |
| +208 | CPdxHybridArray<CGraphicalObject*> | **子节点向量**：{data@+208, cap@+216, count@+220, alloc@+224}；alloc = 内联 `CPdxHybridInlineBufferAllocator<CGraphicalObject*,4,int>` @+232（≤4 项用内联缓冲 +240..+271，全局兜底 off_143085170 @+272）——**书「子向量 @+208」复核成立** | AE140 L6539579-6539610；R2D BFS L5277040-5277050 |
| +280 | uint64 = 0 | 未名 | AE140 L6539611 |
| +288 | int32 = 0 | 未名 | AE140 L6539612 |
| +292 | float = 1.0 | 自身缩放（AE800：累计缩放 ×= 此值；≠1 时 Draw 命中修正除以它） | AE140 L6539613；AE800 L1199742-1199746/L1199778 |
| +296 | uint64 = 0 | 未名 | AE140 L6539614 |
| +304 | {int32, int32} | （C2dPositionObject 增字段）**尺寸对 {w,h}**：树根处 = 最终帧缓冲尺寸 | ctor L3027095-3027097/L3027101-3027103 |
| +312 | uint8 = 1 | **子树遍历旗**（AE800 入口门二：+340 或（+312 ∧ 子数>0）才处理） | AE140 L6539616；AE800 L1199604 |
| +316..+323 | 8B 零 | 未名 | AE140 L6539617 |
| +324 | uint8 | （C2dPositionObject 增字段）绕中心旋转模式旗（非 0 → 定位按自身中心缩放） | ctor L3027096；AE800 L1199763 |
| +328 | uint64 = 0 | 交互载荷指针（非 0 时 FLAT bit1 才收目标项——tooltip/点击处理器族） | AE140 L6539619；AE800 L1199722；FLAT L761867 |
| +336 | int32 = -1 | 剪裁模式枚举前的 -1 哨兵/句柄 | AE140 L6539621 |
| +340 | uint8 = 0 | **自身可绘旗**（AE800 返回 bit0 仅在此位非 0 时置位 = 进绘制列表；GUI 层 SetVisible 写） | AE140 L6539620；AE800 L1199782-1199784 |
| +341 | uint8 = 0 | **剪裁已应用旗**（AE800 剪裁成立时置 1；DISP 非零才读 +688 剪裁框——368B 根类永不受影响） | AE800 L1199790；DISP L601362 |
| +344 | {int32 x, int32 y, int32 w, int32 h} (16B) | **剪裁界限框**（DISP 快速剔除：x≥w 或 y≥h → 跳过；AE800 命中测试同框） | AE140 L6539622-6539625；DISP L601364-601368 |
| +360 | int32 = 0 | **剪裁模式枚举**（0=无自剪裁；1=用自身 +688 矩形与其余求交——置 bit4 让子节点不继承父剪裁） | AE140 L6539623；AE800 L1199668-1199705 |
| +364 | 4B 尾垫 | （368B 止） | AE140 L6539626-6539628 |
| (GUI 派生类) +688 | SScissorRectangle {l,t,r,b} (16B) | **自身剪裁矩形**（AE800 模式 1 读初值→与父剪裁求交→回写此处；DISP 读此处推剪裁。超出 368B 基类 = C2dVisibleObject/C2dObject 级字段，随 gui-items 批定类归属） | AE800 L1199669/L1199794；DISP L601371（`v8+43` = m128i 指针算术 ×16 = +688） |

**AE800（sub_1422AE800 = 每节点可见性/布局/剪裁计算）返回旗位**（R2D 存队列项 +44）：

| bit | 含义 | 证据 |
|---|---|---|
| 0 | 自身入绘制列表（+340 非零才置） | AE800 L1199784 |
| 1 | 入目标收集列表（模式位 a2&1 ∧ +328 非零） | AE800 L1199785-1199786 |
| 2 | 命中测试通过（在屏）→ 入 +80 列表 | AE800 L1199787-1199809 |
| 3 | 展开子节点（+312 ∧ 子数>0） | AE800 L1199791-1199793 |
| 4 | 节点自设剪裁（+360==1；其子节点父剪裁置 NULL，不继承） | AE800 L1199668-1199705；R2D L5277147-5277149 |



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


| 项内偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | CGraphicalObject* | 节点 | R2D L5277041 |
| +8 | int32 | 父 BFS 下标 | R2D L5277056 |
| +12 | int32 | 首子 BFS 下标（子项连续区间） | R2D L5277047 |
| +16 | float×2 | 累计位置 {x,y}（AE800 入出口；子项继承父值） | R2D L5276986/L5277057 |
| +24 | float | 累计缩放（初值 1.0f；子项继承父值） | R2D L5276987/L5277058 |
| +28 | SScissorRectangle (16B) | 本节点生效剪裁框（AE800 出参） | R2D L5276993 |
| +44 | uint8 | AE800 返回旗（§3 bit 表；bit3 = 展开、bit4 = 不继承剪裁） | R2D L5277039-5277052 |
| 容量/计数 | dword_1434530A8 / dword_1434530AC | 分配器 qword_1434530B0 = off_143085170；增长 1.5x——**书复核成立** | R2D L5277010-5277036 |

队列驱动：tbb parallel_for（新层 ≥12 项才并行，否则顺序循环逐项 AE800），
层界 [v15, v16)（R2D L5277143-5277158）。收尾 `sub_14223BB10` 递归展平：
`{队列, 列表+296, 列表+80, 列表+104}` 四路输出（L5277172-5277176、FLAT 全函数）。




| 列表 | 入选位 | 消费 | 证据 |
|---|---|---|---|
| +296 绘制列表 | bit0 | DISP 顺序派发：vt+80 = Draw 槽（实参 = this, graphics, 设备, 节点+144 渲染矩阵, vt+136 返回浮点, vt+176 返回整数, 0）；剪裁推/弹 = off_1430BF988/off_1430BFA18 | DISP L601395-601405 |
| +80 列表 | bit2（命中通过） | 输入/悬停路径消费（本批未追 tail） | FLAT L761864 |
| +104 列表 | bit1（+328 非零目标） | 交互目标消费（本批未追 tail） | FLAT L761867 |

树 1（D2C0）= a6(+80)/a7(+104) 全开 → 命中+目标；BBA0 = a7 置 0 → 仅命中；
树 2（D8B0）= 双 0 → 纯绘制（顶层覆盖层无输入）——与书「第二遍无剪裁」一致。



#### 4.35.5 图形设备 ABI 与三后端
> **勘误**: ① ABI 表 = **92 槽** (0x1430BF7B0..0x1430BFA88 含端点, 非「~70」); ② 后端簇身份 — **dx11 = id 1 (书漏)**, id 3 (串 opengl4) 与 id 1 **共用 D3D11 函数域** (首槽 CreateDXGIFactory2 + D3D11CreateDevice; gfx_opengl4.cpp 全 dump 零引用); GL 簇仅 id 2 (SDL_GL_CreateContext/glewInit 直证), D3D9 簇 id 0。③ 分派机制: 选择器 sub_1424047C0 唯一调用点 = sub_142228800 (CGraphicsSettings 方法, settings+172 驱动) → 整表重装 → 槽 BFA80 后端能力装载; off_1430BF7C0 = GetOwnBackendId (三后端 ret 0/1/2 常数桩); settings+72 = 用户选择 id (串解析写, +76 显式旗) / +172 = 生效 id。④ **42 槽语义已认领** (高频全含: Begin/EndScene/SetViewport/Clear/Draw 族/SetVertexStream "Bad vertex buffer" 51 refs/纹理全生命周期/RT 族/着色器编译绑定/混合深度状态/剪裁推弹对 BF988+BFA18/截图/线框)  — 92 槽语义状态全表 (★ = 跨后端互证认领):

| 槽 | 语义 | refs |
|---|---|---|
| 槽  | 语义 | refs |
| 0 ★ | ★ CreateDevice | 5 |
| 1 ★ | ★ DestroyDevice | 4 |
| 2 ★ | ★ GetOwnBackendId | 32 |
| 3 | 未认领 | — |
| 4  | 能力查询（char(dev)，GL 10 行） | 4 |
| 5  | 能力查询（int(dev)，GL 12 行） | 4 |
| 6 | 空桩；D3D9 = sub_14241CBF0 | — |
| 7  | 无参全局查询 | 9 |
| 8 ★ | ★ GetDeviceDataPtr | 82 |
| 9  | 查询 char(dev) | 5 |
| 10 ★ | ★ BeginScene | 7 |
| 11 ★ | ★ EndScene | 7 |
| 12  | GetDeviceDataPtr v2 | 3 |
| 13 | 空桩 | — |
| 14 ★ | ★ SetViewport | 11 |
| 15 | 未认领 | — |
| 16  | SetEnumState | 45 |
| 17 ★ | ★ Clear | 35 |
| 18 ★ | ★ DrawPrimitive | 36 |
| 19 ★ | ★ DrawIndexedPrimitive | 12 |
| 20 | 空桩；D3D11 = sub_1424139A0 | — |
| 21  | DrawInstanced | 7 |
| 22  | DrawLine2D 族 A | 26 |
| 23  | DrawLine2D 族 B | 4 |
| 24  | CreateProgram | 4 |
| 25  | CompileShader | 5 |
| 26  | shader 链辅助 | 4 |
| 27  | shader 链辅助 | 5 |
| 28  | CompileShader 变体 | 5 |
| 29  | shader 链辅助 | 4 |
| 30  | 查询 char(dev,ptr)；D3D9/D3D11 = ret1 桩 | 4 |
| 31  | DestroyProgram | 7 |
| 32  | BindProgram + SetUniform1i | 49 |
| 33  | 查询 int(dev) | 3 |
| 34 | 未认领 | — |
| 35 ★ | ★ CreateBuffer | 41 |
| 36 ★ | ★ DestroyBuffer | 60 |
| 37  | SetBufferData | 25 |
| 38  | BufferSubData | 5 |
| 39 ★ | ★ SetVertexStream | 51 |
| 40  | 查询 | 4 |
| 41  | CreateBuffer v2 | 14 |
| 42  | DestroyBuffer v2 | 17 |
| 43  | SetBufferData v2 | 6 |
| 44  | BindBuffer | 18 |
| 45 ★ | ★ AllocConstantArray | 46 |
| 46 ★ | ★ FreeConstantArray | 33 |
| 47 ★ | ★ SetConstantEntry（登记 {ceil(n/4), vals} 入设备常量表 [dev + 16*(idx+13)]；置 dev+304=1 脏 | 85 |
| 48 ★ | ★ FlushConstantEntry（memcpy(entry.buf, src, 4n) 冲刷常量） | 85 |
| 49  | 查询/描述（GL 35 行 char*(dev,char*)） | 8 |
| 50  | 析构小件 void(ptr) | 9 |
| 51 ★ | ★ ApplyBlendState | 52 |
| 52  | 查询/辅助 | 5 |
| 53 ★ | ★ CreateRenderState | 20 |
| 54  | 析构小件 void(ptr) | 18 |
| 55 ★ | ★ ApplyDepthStencilState | 49 |
| 56  | 辅助 | 4 |
| 57 ★ | ★ CreateBlendState | 19 |
| 58  | 共享小件 void(ptr) | 9 |
| 59 ★ | ★ ApplyRenderStateBlock | 55 |
| 60  | 辅助 | 9 |
| 61 ★ | ★ CreateTexture | 6 |
| 62 ★ | ★ CreateRenderTarget 包装 | 25 |
| 63 ★ | ★ CreateRenderTarget 内核 | 4 |
| 64 ★ | ★ DestroyRenderTarget 包装 | 97 |
| 65 ★ | ★ ReleaseRenderTarget 后端释放 | 9 |
| 66 ★ | ★ SetTexture + SetSamplerState | 60 |
| 67 ★ | ★ UploadTexture | 14 |
| 68 ★ | ★ UploadTexSub | 9 |
| 69  | GenerateMipmap | 5 |
| 70 ★ | ★ SetRenderTarget | 38 |
| 71  | 查询；D3D11 = 共享 sub_141532E30 | 4 |
| 72  | CopyRenderTargetToTexture | 3 |
| 73  | BlitRenderTarget | 4 |
| 74  | Set16B 属性（(dev, 16B 值) 拷贝；颜色/打包参数候选） | 15 |
| 75  | 辅助 | 16 |
| 76  | 共享小件 void(ptr) | 7 |
| 77 ★ | ★ RestoreScissor | 5 |
| 78  | 辅助 | 4 |
| 79  | 辅助（GL 30 行 (dev,uint,ptr)） | 4 |
| 80 | 空桩；D3D9 = sub_14241D3E0 | — |
| 81  | 桩 ret 0 | 4 |
| 82 | 空桩 | — |
| 83 | 空桩 | — |
| 84  | 桩 ret 0 | 4 |
| 85 | 空桩 | — |
| 86 ★ | ★ Screenshot | 6 |
| 87  | ReadTexturePixels | 6 |
| 88 ★ | ★ SetWireframe | 10 |
| 89  | Set16B 属性 v2（(dev, 16B 值)，与槽 74 同形） | 12 |
| 90 ★ | ★ LoadSettingsForAdapter | 4 |
| 91  | BackendPostInit | 4 |

(92 槽全实现三后端逐列与桩清单见专项档; ~10 查询槽 + 2 折叠槽未认领待后续批); CGraphics +136..+160 四对象 = 槽 53 CreateRenderState 产物 (84B) / +168..+200 五对象 = 槽 57 CreateBlendState 产物 (44B); 常量 (uniform) 系统四槽链 = 128 项池分配 → 设备常量表 [dev+16×(idx+13)] 登记 → memcpy 冲刷 → 还池 (85+85 refs)。


设备 ABI 分派表 = off_1430BF7B0 .. off_1430BFA88 (~70 个全局函数指针槽; 帧/绘制代码一律经此表
调设备, 部分槽在后端 = 空桩)。后端选择器 sub_1424047C0(后端 id) 三分支; **三渲染后端:
dx9(0) / opengl(2) / opengl4(3)** — 选择串直证 (graphicssettings.cpp:172): `opengl`/`ogl` → 2,
`opengl4` → 3, `dx9`/`dx9_compat` → 0, `dx9legacy` → 旗 byte_1435DA930; id 1 无独立串 (与 3
共用函数域)。后端 2 = OpenGL 定案 (表槽函数引 pdx_gfx\gfx_opengl.cpp 断言; GL 上下文 =
wglCreateContext/wglMakeCurrent)。GL 扩展装载双件 = sub_142438B50 (gl3w 形态 5,472 行) +
sub_142441940 (WGL 枚举 3,665 行)。图形设置装载 = sub_14241A230 ("Loading settings for
adapter")。shader filter 类型枚举: "2d"=0 / "shadow"=0 / "cube"=1 / "3d"=2
(gfx_helper.cpp:142)。SDL2-2.0.20 静态链 = 窗口/软光栅底座。

CGraphicsSettings 键→偏移映射 (Reader sub_142229630, 18 tag 全部落名) —


Reader = `sub_142229630`（L383215，`CGraphicsSettings::Reader` 槽 0x142229630）；
ctor = `sub_142227B10`（L394983）；键名由 ref/token_table_1193.txt 映射：

| tag | 键名 | settings 偏移 | 类型/默认 | 消费 |
|---|---|---|---|---|
| 47 | size | +188 {w,h} | 1280×720（ctor 后被桌面分辨率覆盖） | → CGraphics +376/+380 |
| 445 | min_gui | +204 {w,h} | = +188 拷贝 | → CGraphics +384/+388（UI 分辨率） |
| 48 | fullScreen | +224 | u8，默认 0 | devinit 设备创建参数 |
| 469 | borderless | +225 | u8，默认 1 | 同上 |
| 96 | refreshRate | +216 | i32，默认 0 | devinit（"\tRefreshRate=" 日志） |
| 737 | max_refresh_rate | +220 | i32，默认 75 | devinit |
| 302 | adapter | +180 | i32，默认 -1（-1 时回退 +184） | devinit |
| 246 | vsync | +178 | u8，默认 1 | devinit 参数 v123 |
| 99 | shadows | +240 | u8，默认 0 | devinit shadowmapping 门 |
| 348 | multi_sampling | +236 | i32，默认 4 | devinit（12 字距支撑表校验 sub_142228790） |
| 667 | maxanisotropy | +232 | i32，默认 4 | devinit 参数 v122 |
| 321 | shadowSize | +248 | i32，默认 2048；读时钳 [256,4096] + 2 的幂圆整 | — |
| 654 | gui_scale | +212 | f32，默认 1.0 | → CGraphics +206296 |
| 118 | gamma | +244 | f32，默认 50.0f（0x42480000） | — |
| 748 | disable_3d_model_viewer | +161 | u8，默认 0 | — |
| 97/111/113/247 | firstRun / anti_alias_geometry / dynamic_lights / debugmonitor | — | 读后丢弃（兼容键） | — |
| 98/315/316/347 | userAnisotropy / multisampling / anisotropicFiltering / anisotropic_filtering | — | 读后丢弃（兼容键） | — |

ctor 未入 Reader 的字段：+8/+40/+72 三 std::string（后端/驱动串候选，未定案）、
+108 i32=0、+112/+136 CPdxArray×2、+160 word=1、+164 qword=0、
**+172 = `off_1430BF7C0()` 设备 ABI 调用返回值**（图形设置 ctor 期即调设备 ABI）、
+176 word=0、+252=2、+256..+428 {0,N,0}×12B 条目表（multi_sampling 支撑级表）。
Writer = 0x142229D60（`CGraphicsSettings::Writer`，本批未逐键核）。



#### 4.35.6 启动/资产层 (§4.28.21 增补)

> **图形资产热重载五件 (定案)**: ctor 注册 particle/texture/mesh/anim/guianim 五个 Reloader @+206256..+206295 — 与书原列「渲染相关热重载四对」(mod 侧重载) 并存, 两族不同层。

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
| S5 | 地图模式 | mapmodemanager 946 / defines_mapmode 1,588 / custom_map_mode 603 | sub_140E14680 = 模式 2 (STRATEGIC_NAVY) 每帧 updater (勘误正名: 原「OnMapModeChange」系误记 — 真 OnMapModeChange = sub_140A66DE0 CMapModeDispatcher::OnMapModeChange, mapmodedispatcher.cpp:238 实名, ~80 处切换统一点); sub_140E1B280 逐省着色 (§4.2 链): 政治混合 = byte/255 → 0.9f/0.65f/0.25f 三色构造 (14224BEB0 + 14224BFF0 lerp); 未认领哨兵色 0xAA00FFFF (PE ×4); 动画帧 = fmod(Δt, 帧数×qword_1430B1648)/周期×帧数 钳 [0,帧数−1]; gs+700 计数门语义 = 国数 (同 dword175) 非省数; 淡入淡出三通道 +1728/+1732/+316 步进 dt 后各 clamp [0,1], 方向门 = DRAW_COUNTRY_NAMES_CUTOFF (dword_14333645C) ≤ 缩放(a2+1668); +312 = +1732 镜像 |
| S6 | 地图图标 | mapicon.h 1,358 / mapiconmanagerimpl 691 | §4.30.26-28 类族 |
| S7 | 地图箭头/前线几何 | maparrow 481+370 / raid_arrow 824 | sub_141244070; sub_1423F4C90 点集切分; sub_141039F80 寻路 manager ctor sub_14126E990 / LoadDefinitions sub_141272920 (gfx/maparrows/maparrows.txt, lua 解析器 sub_141272F00) / 订单箭头装配 sub_141254FB0 (三静态色源 + 地图模式 39 分支) / per-frame sub_14124F710 / 三池析构 sub_141662150 |
| S8 | 相机/交互输入 | (0x140DB-DC / 0x14126 区) | CEU3Camera; sub_1412627C0 热键+位移 |
| S9 | GUI 框架核心 | containerwindow / buttonwrapper / gui.cpp | sub_1402A44A0 .gui 解析; sub_14225C690 事件分派 |
| S10 | 字体/文本渲染 | bitmapfont 2,102 | sub_14229C770 装载; sub_1422A1810 布局 |
| S11 | 文本引擎/本地化 | (0x1421E / 0x14224 / 0x1411B 区) | sub_1421EAA30 文本流格式化; sub_1411B4B10 浮点格式化 |
| S12 | 纹理/像素搬运 | texturehandler 949 / gfx_texture_cache 392 / flagtextureatlas 1,002 | sub_142133600 上传核; sub_142171F50 blit |
| S13 | 软件光栅 | SDL_render_gl 2,137 / SDL_render_gles2 1,612 | SDL_BlendLines 三核; 分派器 sub_1421A31A0 |
| S14 | 3D 实体/动画/粒子 | pdx_anim 1,185 / pdx_particle 408 | sub_14228D730 实例初始化更新 (dt=0, 精灵创建路径 — 原「挂点定位」系误标, pdx_entity.cpp 簇定性); sub_1423FE460 粒子更新; 全簇 14 件见 §4.35.17 |
| S15 | 调试/ImGui | pdx_dearimgui | sub_1421CBE30 Begin 原语; 观察窗族 |
| S16 | 面板/视图 GUI 行件 | (0x1416-0x141F GUI 区) | ~120 件, §4.35.13 分组台账 |

#### 4.35.14 地图箭头族布局与管线 (CMapArrowManager 族)

**类清单 (RTTI 认领 11 类)**: CMapArrowManager (lambda COL 0x1429a6848 直证类名) / CMapArrowDefinition (COL 0x1429a6348) / CMapArrowDefinitionInstance (基类 CLostDeviceInterface) / CMapArrowSymbolDefinition (推定) / CMapArrowTextDefinition (COL 0x1429a62a8) / CMapArrowButtonDefinition (COL 0x1429a62f8) / CArrowObject (COL 0x142b47c08, 基类 CPdx3DObject, ~216B: +96 CColor SetColor=sub_14126C590 / +112 顶点缓冲 + AABB 对) / CArrowType (COL 0x142b51ac8, ≥340B 含 5 std::string + f32 0.2) / CMapArrowObject (GfxCommonArrowUpdateCallback lambda RTTI 串 + hybrid allocator COL 直证类名) / USMapArrowVertex (COL 0x1429a65e0) / GfxCommonArrowUpdateCallback (COL 0x1429a59e0; 签名 `void(const CMapArrowObject*, const COrderInstance*, const COrdersGroup&, float, const CMapMode*)` mangled 直证)。

**CMapArrowManager (0x180=384B, ctor sub_14126E990, 定案)**: +0 上下文指针 (构造实参 a2, 设备/渲染上下文待裁) / +16+48 双 std::string 32B / +80 CColor 数组 (LoadDefinitions 第4输出) / **+136 原始定义数组 / +160 实例数组** / +184 辅助数组 (装载尾 sub_1412746B0 构建, 语义待裁) / **+208 原始符号定义 / +232 符号实例数组** (元素 0x30B) / +256 数组头 / +336+360 双 std::string 24B。

管线三链 —
- **装载 (启动)**: map 初始化巨函 sub_1413944D0 → malloc(0x180) ctor → 宿主 +1744 → sub_141272920 装载 `gfx/maparrows/maparrows.txt` (lua 解析器 sub_141272F00, LoadDefinitions 五参签名 RTTI 直证: path + arrows→+136 + symbols→+208 + textDef→+288 区 + colors→+80); 循环1 逐箭头 malloc(0x60) ctor sub_141265130 → +160; 循环2 逐符号 malloc(0x30) ctor sub_141B1F350 → +232; 热重载 sub_141587A90 ("Map arrows reloaded") + 重解析比对件 sub_1412739D0。字段名 TextureMaskList/TexturePatternList = maparrow.cpp:440/447 断言直证。
- **创建 (订单→箭头)**: 三包装 sub_1412563A0/E0/480 → 订单解析 sub_141254CD0/D40 (order+96 引用槽 → COrdersGroup) → **装配总入口 sub_141254FB0**: 选色三分 (orderInst+665 旗 → 静态色 unk_143331BE0 / 同国 → scope 派生色 / 异国 → unk_143331B30, 地图模式==39 改 A70) → CColor lerp sub_14224BEB0 (1.0f/0.5f 两档) → SetColor 写 +96; 同国且有选中指令组 → GfxCommonArrowUpdateCallback 经 sub_140DFD540 注册延迟更新; 箭头指针集合 = CPdxHybridInlineBufferAllocator<CMapArrowObject*,128,int> (128 项内联)。
- **每帧**: 泵 sub_140B58470 宿主 +1816 → **sub_14124F710 (箭头+弹道实体共享 per-frame)** → **gs+2617 会话门** (§4.1 该字段新消费点) → sub_141244070 (5,020 行重建主件; 时间节流门 qword_1430B2E18+上次时刻; 玩家国 gs+1680 视角); 动画时钟 = (gs+1212 速度级+1)×Δt, 暂停归零; 袭击箭头独立走宿主 +1792 → sub_141668C10。
- **销毁**: sub_140B52130 → sub_141662150 三池析构 (实体句柄+字符串+定长数组)。

**defines 全族** (NGraphics): ARROW×5 / RAID_ARROW×14 / RAILWAY_MAP_ARROW×15 / RIVER_SUPPLY+SUPPLY_CONSUMER×3, 含数据槽 dword_1433363BC (ARROW_MOVEMENT_SPEED)。主要未决: qword_1430B2E18 初值 / CMapArrowObject 完整布局 (≥512B 无 ctor) / mgr+184 辅助数组语义。

#### 4.35.15 地图模式管线 (CMapModeManager 三段)

**切换段** (~80 处统一点): sub_140A66DE0 = CMapModeDispatcher::OnMapModeChange (mapmodedispatcher.cpp:238 实名) → 旧模式退出清理 (overlay 隐藏/hover 清/层停用) → 新模式入场预着色 → **sub_140E17F30 SetMapMode 状态机**: 同 id 非 force 早退 / 释放旧实例 / vt+184 通知 / switch(id) 写 bank 槽对 (sub_140F31D20) + 层子模式 (sub_140F3B090) + 行选脏闩 (+129/+130) / ≥40 查自定义库 qword_14332F040 → 每路尾调 sub_140E18DF0 SelectModeInstances 向 hub (mgr+64) 灌 tag 色 → 尾取 24B 槽可见性掩码。

**每帧段**: 三 idler (ingame/frontend/nudge) 全部驱动 sub_140E1A890 UpdateDispatch — 日历追赶门 (dword_1430B15C0 三日游标逐日追赶扫) / 图例旗 → hub 全量重建 / switch(模式 id) 逐模式 updater / mgr+4 副模式支 (gs+700 国数门互证); 随后 sub_140E1DAA0 ApplyTweens 应用闩 (脏时写 mapview+1696/+1700 行选并触发行重建)。

**输出段双通道**: A. 省色贴图通道 — bank 23 槽脏位 → RefreshSlot (分派断言属 gradientbordermanager.cpp, 与 S4 渐变边框 18 件同库互证) → CRect 合并 → 省色纹理脏矩形提交; B. 国色通道 — hub 树暂存 tag→色 → flush 逐 tag/全量刷 (pdxmap 省色通道)。

**模式注册表**: 40 个硬编码 id 全表 (−1..39, 含槽对/层选参/行选逐模式表); id→loc 名 17 项 (sub_140E028C0, "MAPMODE_DEFAULT/STRATEGIC_AIR/…/RAIDS"; 1/32 与 16/38 别名组, 28 = DEFAULT 别名); **custom 模式 id = 40+下标**, 库单例 qword_14332F040 (64B; item+232 名 / +272 激活旗)。**CMapModeManager 288B 字段级增量**: +4 层选参 / +16+24 实例 shared_ptr / +80/+84 行选 (+129/+130 脏闩) / +64 hub / +88 全量重建旗 / +96 hub 对象 / +272/+276/+280 (自定义模式暂存)。

#### 4.35.13 渲染域函数地图 (16 子系统, 248 件)

按子系统分组 (★ = ≥1,000 行)。S16 面板/视图行件 108 件逐件全表见下,
其余子系统全列。

| 子系统 | 件数 | 件清单 (★=≥1000 行) |
|---|---|---|
| S1 设备/后端 | 3 | ★sub_142438B50 5,472 GL 扩展装载; ★sub_142441940 3,665 WGL/GL 扩展; ★sub_14241A230 1,729 适配器设置装载 |
| S3 地图图形 | 9 | ★sub_141244070 5,020 地图箭头绘制; ★sub_1423F4C90 4,233 前线点集平面切分; ★sub_141B204A0 2,248 省界图形生成; ★sub_1423BA890 2,763 SSE 数学内核; ★sub_1420A8510 1,560 float3 几何; sub_1412761A0 1,257 断言域巨函; sub_1412615B0 146 视觉数学; sub_14124F710 319 **箭头重建+弹道实体共享 per-frame (身份收窄: 原「导弹/爆炸实体」系其中 type==15 分支以偏概全 — "missile_explosion_entity" 仅该分支)**; 弹道循环生成 missile_explosion_entity; 箭头部分/爆炸实体; sub_140B52C90 269 懒初始化/FX |
| S4 渐变边框 | 18 | sub_140F34020 465 队列装配; sub_140F37330 388; sub_140F36C50 351 claim 管理; sub_14159BBE0 307 tbb 任务体; 家族件 14 (140F3A680/A0D0/38E60/39BF0/36710/38A30/34F90/37A40, 1417A1920/A2D490/27F4F0 1,122 LOD, 140A5CDC0/359D0, 140F3B370 431 池管理) |
| S5 地图模式 | 11 | sub_140E15A40 476 特工任务着色; sub_140E14680 470 OnMapModeChange; sub_140E1D2E0 396; sub_140E13FE0 307; sub_140E1CD90 288; sub_140E13A80 271; sub_140E1A400 269; sub_140E152F0 253; sub_140E1DD10 163; sub_140E1E090 159; sub_140E157F0 120 国色图例 |
| S6 地图图标 | 1 | ★sub_1418C99A0 1,141 建设图标 tooltip |
| S7 箭头/前线几何 | 3 | ★sub_141039F80 1,746 advancement 寻路; ★sub_14126FD50 1,162 纹理校验; sub_141662150 102 三池析构 |
| S8 相机/交互 | 4 | sub_1412627C0 392 热键+位移; sub_141261960 207 清场; sub_140DC0860 230 / sub_140DC0B20 181 递归数学 |
| S9 GUI 框架核心 | 18 | ★sub_1402A44A0 1,621 .gui 解析; ★sub_14230FEE0 1,313 重复类型校验; ★sub_1422BE890 1,511 布局递归; ★sub_141CDC170 1,165 文本项元件; sub_1422A4110 100 锚点分派; sub_14225C690 279 事件分派; idler/tick 族 12 (14167DB20/1412DFDC0/141289980/140DDDA40/1419AD3E0/140B92B30/141688A60/1422DC530/1417A7310/141833DB0/140CBC200/1416408A0) |
| S10 字体/文本渲染 | 4 | ★sub_14229C770 1,654 字体装载; ★sub_1422A1810 1,036 布局/图标; ★sub_1422A0230 1,049 缓冲构建; sub_142238A20 102 解析共享 |
| S11 文本引擎/本地化 | 14 | ★sub_1421EAA30 2,087 文本流格式化; ★sub_1411B4B10 1,930 浮点格式化; ★sub_14252ACD4 1,214 money_get; ★sub_1418530F0 1,272 / ★sub_140E18DF0 = SelectModeInstances (更正: 原 S11 归文本域系误归 — 实为地图模式层选实例选择器, 向 hub 灌色) 1,079 / ★sub_1412517B0 1,002 定长缓冲三件; ★sub_140D20450 1,336 战争名键求值; sub_142245880 235 $展开; sub_14224B9F0 225; sub_140BD3530 388; sub_140BD2F80 279; sub_140FD2240 264; sub_1411C5D30 255; sub_14225CD50 102 |
| S12 纹理/像素 | 8 | ★sub_142130DF0 1,617 搬运/填充; ★sub_142171F50 1,492 blit 巨函 (×24 分量表); ★sub_142133600 1,338 上传核; ★sub_14219BF40 1,401 / ★sub_14219D7D0 1,397 16 位变体; ★sub_14218FCE0 1,365 GUI blit; sub_14225FF10 106; sub_140D5BBC0 1,590 robin-hood 枚举 (通用基建) |
| S13 软件光栅 | 4 | ★sub_1421A0670 1,830 自递归内核; ★sub_142197DD0 1,604 16bpp 混合; ★sub_142196690 1,429 32bpp RGBA; ★sub_14219F1E0 1,315 32bpp RGBX |
| S14 3D 实体/动画/粒子 | 4+14 | ★sub_14228AF80 1,461 **实例逐帧动画/附件更新器 (递归)** (原「attachment 定位」系收窄误标 — 含时间归一/TTL 销毁/特效表/动态子实体生成/双子表递归/播完销毁); ★sub_14228D730 1,400 实例 dt=0 初始化更新 (精灵创建路径, 唯一调用方 entity_sprite.cpp); ★sub_1423AE8F0 1,115 float4 流变换; sub_1423FE460 280 粒子更新; pdx_entity.cpp 簇 12 盲区件补入 §4.35.17 |
| S15 调试/ImGui | 9 | ★sub_1422095C0 2,394 profiler SIMD 内核; ★sub_1421CBE30 1,426 Begin 原语; ★sub_1421F4480 1,156 / ★sub_1421F9450 1,134 观察窗族; ★sub_141B0F6D0 1,066 Faction Member 窗; ★sub_1410652F0 1,128 AI 前线调试; sub_1421D9B40 213; sub_1422A2F90 114 DebugTexture; sub_140222300 105 采样三缓冲 |
| S17 资产装载/压缩 | 6 | ★sub_142388030 2,950 bzip2 解码; ★sub_14250CD90 1,537 range 解码; ★sub_14123D920 1,087 旗帜图集装载; sub_140B406A0 248 国旗图集; sub_140B40BD0 202 装载屏轮换; sub_140FA30E0 470 库条目实例化 |
| S18 基础库旁支 | 5 | sub_140E84150 192 批量释放; sub_14029E0F0 118 POD 拷贝; sub_140B6BC60 115 idpair 去重; sub_140210AF0 202 核爆遥测 (素材包误纳); sub_1406A40E0 101 生涯档案提交/上传总入口 (10 步: 本地/云载入合并→保存→云删除/上传路由; §4.28.22) |
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
| sub_1416B1C00 | 1,108 | UNIT DETAILS 四页统计窗 Setup (CArmyDivisionStatsView; ctor/Reload 双调用者直证) |
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

#### 4.35.16 引擎库资产工具层 (pdxassetutil.cpp 8 函数 + 边界件 2; 书内盲区首批定案)

定位 = clausewitzlib/graphics 引擎库层, 在 game 侧 texturehandler (§4.35.13 S12) /
gfx_texture_cache 之下: 先经纹理名解析缓存把短名解析为全路径, 再交上层真装载; 网格管线
= pdxmeshtype.cpp → 本簇 → 设备 ABI。**三子机制 (定案)**:

**① 纹理名→全路径哈希表**: 装载 = InitTextureLookup sub_142266590 (§4.35.6 已锚;
"Long Task" 并行任务经运行器 sub_14225FF10 以**函数指针**调回调 sub_142266E40 — 此即
266E40 零直连调用方的原因), 逐文件仅收 .dds/.tga, 键 = 末 '/' 后子串, 命中已有条目 →
组 {键, 新路径, 旧路径} 入 96B×3 串延迟数组; 消费 sub_142266170 = 扩展名归一 → FNV-1a
查表 → 未命中原始名再查一遍 → 两空报 "Failed to find texture '%s'" (:1138); 重复警告冲刷
sub_142267700 = "LookupTaskMutex" SRW 独占下排序 (≤32 插排/32 归并, 缓冲失败减半重试)
逐条报 "Duplicate texture '%s' found (…)" (:1098)。全局状态: 哈希表桶基 qword_143453318 /
桶掩码 +330 / 表非空旗 +310 / 查找使能门 byte_1434532F0 / 延迟数组 1434532C0 区 /
挂起批 shared_ptr qword_1434532E8。**热重载复入 = sub_14209E610 重跑 InitTextureLookup**
(清表重建, §4.35 热重载 assets 对, 高置信)。条目布局 = {+0 next, +8 prev, +16 键串, +48 值全路径串}。

**② 网格装载管线 (mesh → GPU)**: sub_142264F50 装载入口 (键 object/skeleton/mesh/skin;
骨骼矩阵 SSE; "Didn't find skeleton in mesh file") → sub_142263D10 缓冲构建 (流键
p/n/ta/u0-3/tri(必选)/skin; **流对象 +20 = 元素计数按各自单位**; 皮肤校验
"Bones/Weights doesn't match coordinates!" :994/:998; 返回 1 = 仅网格 / 2 = 网格+皮肤) →
顶点交错器 sub_142265BB0 (全 f32: pos3×scale | n3 | ta4 | uv0-3 各 2; **零向量防退化**:
零法线 ny = 0.01 / 零切线 ty = 0.01) + 皮肤缓冲 sub_1422659D0 (**16B/顶点 = 4×u8 骨骼索引 +
3×f32 权重**, 源 4×i32 负值→0 截 u8) + 索引降频 sub_1422635D0 (u32→u16 SSE shuffle) →
设备 ABI。材质排列创建 sub_142260A40 (变体后缀 Unlit/Skinned/Shadow/SkinnedShadow/
SkinnedUnlit/%sAlpha, PDX_MESH_UV1 判据; 失败 throw 门 byte_1430BDF84 否则回退错误材质
dword_1430BDF7C/80)。动画装载 sub_1422625E0 (.anim info{fps,samples} + 逐骨骼轨道位掩码,
"Bad animation" 双串)。模板属性解析回调 sub_142266A20 (token 27 name→+8 / 15 texture_* 前缀
三槽 +40/+72/+104 / 432 shader→+136 / 678 shader_file→+168 / 524 index→+212; token 15 触发名
待裁; 对象 = 实体/材质模板推定)。

**③ 设备 ABI 槽 35/41 细化 (§4.35.13 92 槽表增补, 高置信)**: 槽 35 off_1430BF8C8 = 
**CreateVertexBuffer** (本簇 3 消费点全为顶点数据: 交错顶点 + 皮肤缓冲, stride 4×浮点数 / 16) /
槽 41 off_1430BF8F8 = **CreateIndexBuffer** (u16 降频产物 stride 2) — 原「CreateBuffer /
CreateBuffer v2」实质 = 顶点/索引双通道; **两槽第 6 参 = 调试源串** ("pdxassetutil.cpp:861/898")。

#### 4.35.17 实体系统 (pdx_entity.cpp 14 函数; 场景图/状态机层, §4.35.16 资产层消费侧)

本簇自身**零设备 ABI 调用** — 经 qword_143453090 资产对象库按名取用 (类型 id **384 = pdxmesh /
385 = pdxparticle** 鉴型), 网格/音效/粒子/动画库均为邻接消费面。

**三级数据形态 (构建期→运行期, 定案)**: 解析期 (.gfx entity 块) 宿主大对象 (+256 mesh 名 /
+1024 状态数组 600B/条 / +1040 附件数组 272B/条 / +1072 mesh 变体 48B/条 {+8 权重, +16 名} /
+1092 优先级) → 运行期定义 **448B** (+8 名 / +264 mesh 变体向量 / +288 累计权重向量 /
+312 状态向量 632B/条 / +344 附件向量 88B/条 / +392 meshsettings / +416 缩放缺省 1.0 /
+420 优先级 / +424 骨骼 FNV) → 状态记录 632B (+0/+8 状态名 FNV/串, +264/+272 动画名,
+548 循环旗, +552 时长, +576 事件向量 1096B/条, +600 音效容器) / 事件记录 1096B (+0 触发时戳 /
+4 附件点名 / +260 子实体名 →+520 回填 / +1064 音效 / +1072 粒子 / +1080 音效效果 /
+1090 = 播完触发旗) / 附件记录 88B (+32 子附件向量 72B/条 {+32 名, +64 定义指针})。
名→定义 map 在系统对象 +96。

**装载链 (定案)**: AddEntity 双路径 — merge 初载 sub_142291E30 (同名低优先旧件删匹配条目再追加;
优先级门 +420 vs +1092; 重复警告 :2277) vs **热重载清空重建 sub_142292800** (置脏旗
byte_1430BDF8C, +624 载荷经全局释放指针 qword_143468F50 释放); 网格绑定 sub_142287080
五断言校验集 (:2070/:2071 类型 384 鉴型 / :2081 meshsettings×变体互斥 / :2101 权重 <1 /
:2109 累计溢出基准 100000 / :2124 变体 mesh 与父一致); 状态构建 sub_142280940 (双 FNV +
动画库查时长, "Could not find animation" :228) / 事件构建 sub_142280270 (1808B→1096B 逐槽迁移);
装载后解析趟 sub_142291410 (附件 +64 与事件子实体 +520 按名回填, :167/:324); 热重载修复趟
sub_1422917A0 (实例群状态重绑定 + 速度从 def+436 重装, "Setting animation failed" :681)。

**运行期 (定案)**: Spawn = sub_14228D650 按名包装 (:2512) → sub_14228CD30 (实例分配 +
mode 字段 [实例+164 = 1/2/3] 包围盒解析 — 1/2 = mesh 变体包围 / 3 = 附件节点相对 112B/条表)。
**驱动双路径正交**: ① 地图 Idler 泵 (§4.28 泵链 sub_14222EB50 → sub_142291D40 批量提交 →
逐实例 **sub_142283E70** [§4.28 定案互证全符: 4 平面 SSE 剔除 → 时钟推进 → 事件扫描 →
音效/粒子/附挂生成 → 播完销毁] → 自递归 **sub_14228AF80 = 实例逐帧动画/附件更新器** [时间归一/
TTL 子件销毁/特效表处理/动态子实体生成/双子表递归/播完销毁 — 原标「attachment 定位」系收窄误标]);
② 精灵创建路径 (entity_sprite.cpp → **sub_14228D730 = dt=0 初始化更新**, 与 AF80 同构但速度项
×0.0 不推进、子件改派 AF80 — 原标「挂点查找」系误标, 唯一调用方直证)。状态机 API: SetState
sub_14228A4E0 (+72 换装 + 速度装订 + 选项随机起点) / 挂接迁移 sub_1422833D0
("has no attach point named" :874)。未决: 事件 +528/+792 名串语义 / 实例 +104/+112 双时钟分工 /
mode 1/2 具体差别 / 剔除门节点表是否即「四叉树」/ 状态 +600 音效容器内部形态。
