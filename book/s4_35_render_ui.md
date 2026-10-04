### 4.35 渲染/UI 体系

> 渲染与界面域定案落账。§4.35.13 = 域内 248 件按 16 子系统的函数地图;
> ≥1,000 行大件 34 个全列入册。阅读顺序 = §4.35.1 管线总览 → §4.35.2-5 各层 → §4.35.7-13 子系统与函数地图。

#### 4.35.1 管线总览与帧驱动

L0 帧驱动: main (sub_140126E50) → CApplication::Run (sub_14222E7E0, 钉单核) → 帧顶
sub_14222EEB0 → idler 派发 vtable[4] Idle (ingame sub_140DD3A50 / frontend sub_140B3CA20 /
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
| 8 | EndFrame sub_142238180 + 截图/横幅合成闩 sub_14223B030 (a1+1288 旗 — 精化: 该字节 = **帧就绪/Present 复合锁存** 非截图专用, 设备 ok 时 sub_1422370E0 置 1 / B030 用槽 9 Present 返回值覆写, 截图横幅只是消费者之一) |

截图合成件 sub_140B411B0 = BeginFrame + 装载屏轮换 sub_140B40BD0 + 横幅纹理盖印
(懒载字体 "vic_36" 经 sub_142238A20 = **GetFont 带回退** (缺名回退表中首字体)) + 整帧 2D 树 + EndFrame — 横幅即此路盖章。

#### 4.35.2 世界/地图渲染三段链

三段消费件 (a1 = idler vtable[16] 结果对象 (持 CPdxMap@+88), a2 = vtable[74] 结果):

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
| CGraphics 本体（含虚基前全部） | **206,328B**（ctor 最大写偏移 +206316，+206320 虚基） | ctor ；DeInit 置 +206316=0（ 附近） |
| CAnimViewerGraphics 分配 | malloc(0x325F0) = **206,336B**（= CGraphics 206328 + 虚基 8B 对齐） | 分配后先跑 CGraphics ctor 再覆写 vtable = CAnimViewerGraphics（-3926182） |
| CGameGraphics 分配 | malloc(0x32A00) = **207,360B**；日志 "InitBase:: CGameGraphics takes N KB memory."（gameapplication.cpp:1379） | -3905795 |
| CLostDeviceInterface 虚基 | **vptr @+206320，8B**（dtor 恢复 `*(Block+206320) = &CLostDeviceInterface::vftable'`；CGameGraphics 成员自 +206328 续接） | -1510359（两处 vtable 写，25790×8 = 206320）、-7756007 |
| CGraphics ctor | `sub_142235600(this, window_mgr, settings)` | — |
| 设备初始化（Init 尾段） | `sub_142239540(this, window_mgr)`（ctor 尾调用；**此函数内 `qword_143453090 = this` 写单例**） | （ctor 内调用）、 |
| CGraphics dtor | `sub_14223D220(this, vbase)`（由 CGameGraphics dtor 调） | （`sub_14223D220(Block, Block + 206320)`） |
| CGraphics 全量析构 | `sub_142236330` (5 重载器注销 particle/texture/mesh/anim/guianim + 9 状态对象销毁 + 双 2D 树拆除 + "Textures still loaded" :1231 — 升级: 原「dtor 壳」系折叠视图) | — |
| CGameGraphics ctor / dtor | `sub_140B3FEB0` / `sub_140B3FFE0` | / |
| DeInit 守卫 | 未初始化时 "Attempted to DeInitialize CGraphics without first initializing it."（graphics.cpp:1763） | — |
| 单例 CGraphics::Get() | `qword_143453090`（GetSpriteType 断言串直证 "CGraphics::Get()->GetSpriteType( SpriteName )"） | 、 |
| 实参 a2 | `*(CGameApplication+104)` = 窗口/显示管理器对象（内联成员，ctor `sub_141332690`；vtable+520 查窗口化、vtable+648/656 切模式），存 CGraphics+8 | 、（a2=v31=*（a1+104)） |
| 实参 a3 | CGraphicsSettings*（`sub_14222BD90()` 双跳取单例），存 CGraphics+1248 | 、ctor |
| 派生杀链 | CAnimViewer 路径：malloc → sub_142235600 → 覆写 vtable；游戏主路径：malloc(0x32A00) → sub_140B3FEB0 → 挂 CGameApplication+864 | / |




> 证据列缩写：ctor = sub_142235600（ 起）；devinit = sub_142239540
> （ 起）；dtor = sub_140B3FFE0（ 起）；R2D = sub_14223D3F0
> （ 起）；DISP = sub_14223DB60（ 起）；FLAT = sub_14223BB10
> （ 起）；D2C0 = sub_14223D2C0（ 起）。


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | CGraphics*（vtable） | 主vtable（派生覆写） | ctor |
| +8 | 窗口/显示管理器* | ctor 实参 a2 原样存 | ctor devinit |
| +16 | CPdxArray (24B) | {data,cap,count,alloc} 容器 #0（`sub_14011DF40` 初始化，alloc=off_143085170）；内容语义未决 | ctor sub_14011DF40 |
| +40 | CPdxArray (24B) | 容器 #1（+40/+48/+56 手工内联初始化）；内容语义未决 | ctor -3026802 |
| +64 | float×2 | **光标位置槽（当前帧）** {x,y}：AE800 命中测试按 {x×aspect_x, y×aspect_y} 对剪裁框判定；帧首 D2C0/BBA0 做 +64→+72 拷贝 | AE800 （`*a5`/`HIDWORD(*a5)` × a4）；D2C0 |
| +72 | float×2 | 光标位置槽（帧首自 +64 拷贝的副本） | D2C0 BBA0 |
| +80 | CPdxArray (24B) | **展平输出列表 A**：命中测试通过的可见项（FLAT bit2 → push 节点指针）；R2D 实参 a6（非空 = 开启命中测试模式位）；devinit 按容量增长（<2048 → max(1.5x,2048)） | devinit -7058717；FLAT R2D |
| +104 | CPdxArray (24B) | **展平输出列表 B**：交互目标项（FLAT bit1，要求节点 +328 非空）；R2D 实参 a7（非空 = 开启目标收集模式位） | devinit -7058731；FLAT AE800 |
| +128 | 设备句柄 | 主设备对象（`off_1430BF7B0(&params,&err)` 创建；失败降级桌面分辨率重试 graphics.cpp:979-981；DISP/其他帧件全部经 +128 取设备） | devinit -7059262 |
| +136 | 设备状态对象 | 设备 ABI `off_1430BF958()` 创建（状态组 1） | devinit -7059316 |
| +144 | 设备状态对象 | 同上（组 2） | devinit |
| +152 | 设备状态对象 | 同上（组 3） | devinit |
| +160 | 设备状态对象 | 同上（组 4，参数变体 DWORD2=7） | devinit -7059313 |
| +168..+200 | 设备状态对象 ×5（+168/+176/+184/+192/+200） | 设备 ABI `off_1430BF978()` 创建（BYTE8 旗变体；渲染状态族：混合/采样器类） | devinit -7059330 |


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +208 | {int32 count, int32 cap=511, ptr} (16B) | 定容指针数组 #1（malloc 0xFF8 = 511×8B；dtor `sub_1401C1510` 释放）；内容语义未决（dtor 迭代元素走 vtable+80 并随 [1] 链，见 DeInit 对 +1328 同型数组的用法） | ctor -3026880 |
| +224 | std::string (32B) | MSVC 串（SSO +248=15）；内容未写入 ctor，语义未决 | ctor -3026887 |
| +256 | {int32 count, int32 cap=511, ptr} (16B) | 定容指针数组 #2（同 +208 形态） | ctor -3026893 |
| +272 | 24B 件（sub_14011DF40） | CPdxArray #N（ctor 内联第三形态）；内容语义未决 | ctor |
| +296 | **CPdxArray (24B)** | **扁平化绘制列表**：{data@+296, cap@+304, count@+308, alloc@+312}；FLAT bit0 输出（绘制顺序 = BFS 序节点指针）；DISP 消费（count 在 +308）；增长同 1.5x/2048 | devinit -7058695；FLAT DISP |
| +320 | CPdxArray (24B) | 容器（+320/+328 清零、+336=alloc）；语义未决 | ctor -3026962 |
| +344 | CPdxArray (24B) | 容器（+344/+352 清零、+360=alloc）；语义未决 | ctor -3027077 |
| +368 | CTextureHandler* (128B+) | 纹理管理器（`sub_142406120` 构造；devinit 写其 +104 = 主设备 +128、+112/+120 = 派生块 +840/+848 帧缓存信息） | ctor -3027088；devinit -7059338 |
| +376 | {i32 宽, i32 高} | **全分辨率对**（settings +188 `size` 对拷入；设备创建失败降级时被写回桌面分辨率） | ctor /-3027105；devinit -7059258 |
| +384 | {i32 宽, i32 高} | **UI（min_gui）分辨率对**（settings +204 `min_gui` 对拷入；ctor 尾按长宽比适配 + 1/gui_scale 缩放后回写） | ctor /-3027146 |
| +400 | float[16] (64B) | **正交投影矩阵**（D3D 列主序 OrthoOffCenter 形态：[0]=2/(r-l)、[5]=2/(t-b)、[10]=1.0f、[12]=-tx、[13]=-ty、[14]=-0.0f、[15]=1.0f；由适配后 UI 分辨率构建） | ctor -3027140 |
| +464 | float ×4 | {uiW/fullW, uiH/fullH, 1/(uiW/fullW), 1/(uiH/fullH)}（UI 分辨率占比及倒数；AE800 命中测试用 +472/+476 做光标屏幕坐标换算） | ctor -3027144；AE800 |


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +496 | C2dPositionObject (368B) | **2D 树 1 根**（vtable 先 CGraphicalObject 后覆写 C2dPositionObject；+800=根+304 {w,h} 屏幕尺寸对、+820=根+324 字节旗） | ctor -3027097 |
| +864 | C2dPositionObject (368B) | **2D 树 2 根**（同构；+1168=根+304、+1188=根+324；R2D 调用 a6=0 = 无剪裁/无命中测试） | ctor -3027102；D8B0 |
| +1232 | {uint64 0, int32 0, uint8 0} (16B) | 16B 状态块（语义未决；+1232 帧内偶读） | ctor -3027105 |
| +1248 | CGraphicsSettings* | settings 引用（devinit 全程密集读取） | ctor |
| +1256 | uint8 | 影子贴图意愿门（devinit：`sub_142229D50(settings)`=硬件支持时若此位非 0 → 日志 "Hardware supports \"shadowmapping\", shadows enabled."；否则 `sub_142229D40(settings,0)` 关闭） | devinit -7059390 |
| +1264 | CPdxArray (24B) | 容器（+1264/+1272 清零、+1280=alloc）；语义未决 | ctor -3027123 |
| +1288 | uint16 = 1 | 初始 1 = **帧就绪/Present 复合锁存** (+1289 = reset 旗; 精化: 原「消费点未定」) | ctor |
| +1308 | float = -1.0 | 三浮点初值组（语义未决） | ctor -3027127 |
| +1312 | float = -1.0 | 同上 | ctor |
| +1316 | float = 0.5 | 同上 | ctor |
| +1320 | {int32 count, int32 cap=511, ptr} (16B) | 定容指针数组 #3（DeInit 遍历：元素走 vtable+80(this) 并沿元素+8 链——**屏/根对象注销表**形态） | ctor -3027131；DeInit -3479800 |
| +1336 | CEffectHandler (204,880B) | **内嵌效果/着色器池**（见 §4.2）；恰占 +1336..+206215，与 +206216 下一字段严丝合缝 | ctor sub_142409480 |


| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +206216 | 设备根对象* | devinit 首建（工厂 `sub_1422333C0()` 单例 → vtable+8 创生）；紧接 `sub_14224DC90` 消费 | devinit -7058732 |
| +206224 | int32 = 0 | 状态字（DeInit 分支清零；语义未决） | ctor devinit |
| +206228 | int32 | **后备缓冲高**（= +380 值；DISP 视口钳位 bottom=min(bottom,+206228)）——⚠ 与书对调，见 §7 | ctor 无初值；devinit -7059399；DISP -601390 |
| +206232 | int32 | **后备缓冲宽**（= +376 值；DISP 视口钳位 right=min(right,+206232)） | 同上 |
| +206236 | float = 1.0 | 分辨率应用时重置的浮点（+206240 = 0；语义未决） | devinit |
| +206244 | int32 = 0 | 状态字（语义未决） | devinit |
| +206256 | CParticleReloader* | 热重载件 ×5（注册名 "particle"）：new 后交 `sub_1422564C0` 登记 | ctor -3027230 |
| +206264 | CTextureReloader* | 热重载件（"texture"） | ctor -3027250 |
| +206272 | CMeshReloader* | 热重载件（"mesh"） | ctor -3027271 |
| +206280 | CAnimationReloader* | 热重载件（"anim"） | ctor -3027292 |
| +206288 | CGuiAnimationReloader* | 热重载件（"guianim"；**双 vtable 多基**，+8 存 this 反指） | ctor -3027300 |
| +206296 | float | **gui_scale**（ctor 读 settings+212 浮点；ctor 尾以 1/gui_scale 缩放 UI 分辨率对） | ctor settings 取值器 sub_142228770 |
| +206300..+206315 | 14B 零块 | {uint64 0, uint64 0}（+206300/+206308） | ctor -3027155 |
| +206316 | uint8 | **已初始化旗**（ctor 置 0；devinit 成功路径隐含置位；DeInit 尾清 0，未初始化即拒） | ctor DeInit |



#### 4.35.3a 双 2D 树节点 — CGraphicalObject 基类布局 (368B; 定案)


基类 ctor = `sub_1422AE140`，368B；树根 = C2dPositionObject（ctor 内联：
AE140 之后覆写 vtable + 写 +304/+324）。类层级（书 §4.31 已有）：CSprite →
C2dVisibleObject → C2dObject → CGraphicalObject；C2dPositionObject → C2dObject →
CGraphicalObject。实例计数器 = `dword_143481104`（ctor 递增）。

| 偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | vtable | CGraphicalObject 主表（根被覆写 C2dPositionObject） | AE140 |
| +16 | uint64 = 0 | 未名（AE140 只清零） | AE140 |
| +32 | CColor (32B) | 内嵌颜色对象（vtable=CColor::vftable；+48 处以 {1.0f×4} 常量 xmmword_1430BDF00 初始化 = 白色族；+36..+47 本 ctor 未写） | AE140 -6539548；PE 取常量 = 4×0x3F800000 |
| +64 | uint8×2 = {1,1} | 双字节旗（dword 65537 = 0x010001；+65 在 AE800 命中分支读：非 0 且全局门关 → 跳过命中测试） | AE140 AE800 |
| +68 | int32 = -1 | 未名（-1 哨兵） | AE140 |
| +80 | float[16] (64B) | **布局变换矩阵（恒等初始化，列主序 4×4）** | AE140 -6539561 |
| +128 | float | 局部偏移 x（AE800：光标累加位 = 父位 + 此值） | AE800 |
| +132 | float | 局部偏移 y | AE800 |
| +136 | int32 = 0 | 未名 | AE140 |
| +140 | float = 1.0 | 未名（比值/缩放候选） | AE140 |
| +144 | float[16] (64B) | **渲染矩阵（Draw 槽第 4 参 = this+144）**：[0]=累计缩放 x、[4]=累计缩放 y（AE800 写 f32@+144/+164）、[8]/[9]=旋转槽（旋转时写）、[12]=绝对 x、[13]=绝对 y、[15]=1.0 | AE140 -6539577；AE800 -1199761；DISP （`v8+18` = 指针算术 ×8 = +144） |
| +208 | CPdxHybridArray<CGraphicalObject*> | **子节点向量**：{data@+208, cap@+216, count@+220, alloc@+224}；alloc = 内联 `CPdxHybridInlineBufferAllocator<CGraphicalObject*,4,int>` @+232（≤4 项用内联缓冲 +240..+271，全局兜底 off_143085170 @+272）——**书「子向量 @+208」复核成立** | AE140 -6539610；R2D BFS -5277050 |
| +280 | uint64 = 0 | 未名 | AE140 |
| +288 | int32 = 0 | 未名 | AE140 |
| +292 | float = 1.0 | 自身缩放（AE800：累计缩放 ×= 此值；≠1 时 Draw 命中修正除以它） | AE140 AE800 -1199746/ |
| +296 | uint64 = 0 | 未名 | AE140 |
| +304 | {int32, int32} | （C2dPositionObject 增字段）**尺寸对 {w,h}**：树根处 = 最终帧缓冲尺寸 | ctor -3027097/-3027103 |
| +312 | uint8 = 1 | **子树遍历旗**（AE800 入口门二：+340 或（+312 ∧ 子数>0）才处理） | AE140 AE800 |
| +316..+323 | 8B 零 | 未名 | AE140 |
| +324 | uint8 | （C2dPositionObject 增字段）绕中心旋转模式旗（非 0 → 定位按自身中心缩放） | ctor AE800 |
| +328 | uint64 = 0 | 交互载荷指针（非 0 时 FLAT bit1 才收目标项——tooltip/点击处理器族） | AE140 AE800 FLAT |
| +336 | int32 = -1 | 剪裁模式枚举前的 -1 哨兵/句柄 | AE140 |
| +340 | uint8 = 0 | **自身可绘旗**（AE800 返回 bit0 仅在此位非 0 时置位 = 进绘制列表；GUI 层 SetVisible 写） | AE140 AE800 -1199784 |
| +341 | uint8 = 0 | **剪裁已应用旗**（AE800 剪裁成立时置 1；DISP 非零才读 +688 剪裁框——368B 根类永不受影响） | AE800 DISP |
| +344 | {int32 x, int32 y, int32 w, int32 h} (16B) | **剪裁界限框**（DISP 快速剔除：x≥w 或 y≥h → 跳过；AE800 命中测试同框） | AE140 -6539625；DISP -601368 |
| +360 | int32 = 0 | **剪裁模式枚举**（0=无自剪裁；1=用自身 +688 矩形与其余求交——置 bit4 让子节点不继承父剪裁） | AE140 AE800 -1199705 |
| +364 | 4B 尾垫 | （368B 止） | AE140 -6539628 |
| (GUI 派生类) +688 | SScissorRectangle {l,t,r,b} (16B) | **自身剪裁矩形**（AE800 模式 1 读初值→与父剪裁求交→回写此处；DISP 读此处推剪裁。超出 368B 基类 = C2dVisibleObject/C2dObject 级字段，随 gui-items 批定类归属） | AE800 /DISP （`v8+43` = m128i 指针算术 ×16 = +688） |

**AE800（sub_1422AE800 = 每节点可见性/布局/剪裁计算）返回旗位**（R2D 存队列项 +44）：

| bit | 含义 | 证据 |
|---|---|---|
| 0 | 自身入绘制列表（+340 非零才置） | AE800 |
| 1 | 入目标收集列表（模式位 a2&1 ∧ +328 非零） | AE800 -1199786 |
| 2 | 命中测试通过（在屏）→ 入 +80 列表 | AE800 -1199809 |
| 3 | 展开子节点（+312 ∧ 子数>0） | AE800 -1199793 |
| 4 | 节点自设剪裁（+360==1；其子节点父剪裁置 NULL，不继承） | AE800 -1199705；R2D -5277149 |



#### 4.35.4 CGraphics::Render2dTree 与绘制派发

**CGraphics::Render2dTree = sub_14223D3F0 (定案**; tbb lambda 符号串
`Render2dTree(CGraphics*, …, CGraphicalObject**, SScissorRectangle const*, …)` 直证)。内部三步:

1. BFS 展开进全局渲染队列 qword_1434530A0 (48B/项; count = dword_1434530AC, 容量 =
   dword_1434530A8, 分配器槽 qword_1434530B0 = off_143085170); 每节点可见性/布局 =
   sub_1422AE800, 子向量 @对象+208。
2. tbb parallel_for (≥12 项才并行) 对本层条目并行处理。
3. 顺序绘制派发 sub_14223DB60: 逐项走对象vtable **+80 = Draw 槽**, 剪裁推/弹 =
   off_1430BF988 / off_1430BFA18 设备调用对, 视口钳位 +206228/+206232。

同步局部重绘: gui.cpp 事件分派 sub_14225C690 / sub_14225CF20 尾调 **sub_14223BBA0** =
只重渲染树 1 — 输入事件路径自带同步重绘, 不经 idler 渲染槽。调试旗 GUI.Wireframe
byte_143453088 (控制台可注册): sub_14223D2C0 帧首/尾各一次设备调用 off_1430BFA70。


| 项内偏移 | 类型 | 语义 | 证据 |
|---|---|---|---|
| +0 | CGraphicalObject* | 节点 | R2D |
| +8 | int32 | 父 BFS 下标 | R2D |
| +12 | int32 | 首子 BFS 下标（子项连续区间） | R2D |
| +16 | float×2 | 累计位置 {x,y}（AE800 入出口；子项继承父值） | R2D / |
| +24 | float | 累计缩放（初值 1.0f；子项继承父值） | R2D / |
| +28 | SScissorRectangle (16B) | 本节点生效剪裁框（AE800 出参） | R2D |
| +44 | uint8 | AE800 返回旗（§3 bit 表；bit3 = 展开、bit4 = 不继承剪裁） | R2D -5277052 |
| 容量/计数 | dword_1434530A8 / dword_1434530AC | 分配器 qword_1434530B0 = off_143085170；增长 1.5x——**书复核成立** | R2D -5277036 |

队列驱动：tbb parallel_for（新层 ≥12 项才并行，否则顺序循环逐项 AE800），
层界 [v15, v16)（R2D -5277158）。收尾 `sub_14223BB10` 递归展平：
`{队列, 列表+296, 列表+80, 列表+104}` 四路输出（-5277176、FLAT 全函数）。




| 列表 | 入选位 | 消费 | 证据 |
|---|---|---|---|
| +296 绘制列表 | bit0 | DISP 顺序派发：vtable+80 = Draw 槽（实参 = this, graphics, 设备, 节点+144 渲染矩阵, vtable+136 返回浮点, vtable+176 返回整数, 0）；剪裁推/弹 = off_1430BF988/off_1430BFA18 | DISP -601405 |
| +80 列表 | bit2（命中通过） | 输入/悬停路径消费（本批未追 tail） | FLAT |
| +104 列表 | bit1（+328 非零目标） | 交互目标消费（本批未追 tail） | FLAT |

树 1（D2C0）= a6(+80)/a7(+104) 全开 → 命中+目标；BBA0 = a7 置 0 → 仅命中；
树 2（D8B0）= 双 0 → 纯绘制（顶层覆盖层无输入）——与书「第二遍无剪裁」一致。



#### 4.35.5 图形设备 ABI 与三后端
> **定案**: ① ABI 表 = **92 槽** (0x1430BF7B0..0x1430BFA88 含端点); ② 后端簇身份 — **dx11 = id 1**, id 3 (串 opengl4) 与 id 1 **共用 D3D11 函数域** (首槽 CreateDXGIFactory2 + D3D11CreateDevice; gfx_opengl4.cpp 全 dump 零引用); GL 簇仅 id 2 (SDL_GL_CreateContext/glewInit 直证), D3D9 簇 id 0。③ 分派机制: 选择器 sub_1424047C0 唯一调用点 = sub_142228800 (CGraphicsSettings 方法, settings+172 驱动) → 整表重装 → 槽 BFA80 后端能力装载; off_1430BF7C0 = GetOwnBackendId (三后端 ret 0/1/2 常数桩); settings+72 = 用户选择 id (串解析写, +76 显式旗) / +172 = 生效 id。④ **42 槽语义已认领** (高频全含: Begin/EndScene/SetViewport/Clear/Draw 族/SetVertexStream "Bad vertex buffer" 51 refs/纹理全生命周期/RT 族/着色器编译绑定/混合深度状态/剪裁推弹对 BF988+BFA18/截图/线框)  — 92 槽语义状态全表 (★ = 跨后端互证认领):

| 槽 | 语义 | refs |
|---|---|---|
| 槽  | 语义 | refs |
| 0 ★ | ★ CreateDevice | 5 |
| 1 ★ | ★ DestroyDevice | 4 |
| 2 ★ | ★ GetOwnBackendId | 32 |
| 3 | 未认领 | — |
| 4  | 能力查询（char(dev)，GL 10 行） | 4 |
| 5  | **OnResetDevice 通知** (与槽 6 OnLost 成对称释放/重建对 — sub_14223AF50 头部调槽 5 / AE60 尾部槽 6, 逐容器 restore 紧随) | 4 |
| 6 | 空桩；D3D9 = sub_14241CBF0 | — |
| 7  | 无参全局查询 | 9 |
| 8 ★ | ★ GetDeviceDataPtr | 82 |
| 9  | **EndFrame/Present** (dx9 = Present vtable+136; dx11 = FinishCommandList×N → ExecuteCommandList → Present(vsync? (1,0):(0,tearing?0x200:0)) → 帧计数; GL = SDL 交换推定 — 消费点把返回布尔当帧末成功旗缓存) | 5 |
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
| 30  | GL = **LinkProgram** (ret bool = 链接成败; attach + glBindAttribLocationARB + 23 uniform 位置预解析; D3D9/D3D11 = ret1 桩) | 4 |
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
| 48 ★ | ★ FlushConstantEntry（memcpy(entry.buf, src, 4n) 冲刷常量; GL 侧变体 = **绘制时 glUniform4fvARB 惰性冲刷** (六具名 uniform + 顶点声明懒重绑, §4.35.16d) — dx 侧 memcpy 形态未证伪) | 85 |
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
| 60 | **CreateTexture (新建纹理句柄)** — 两独立调用点直证 (texturehandler 装载执行 0x142407CB0 / gfx_texture_cache 装载核 0x14241F900), 返回值均直接入库为新句柄, 实参 (设备, 解码像素件, 宽, 高, 0); 其余 refs 待逐一复核 (旧记「辅助」系未认领) | 9 |
| 61 ★ | **UploadTexture (像素上传)** — ReloadTexture (0x142408B20) 直证: 第 2 实参 = 记录 +0 既有句柄, 句柄不变内容被替换 (纯 Create 不应传旧句柄); 6 refs 新建场景推定设备内部 create-or-update (待活体); 旧记「CreateTexture」系调用场景误推 | 6 |
| 62 ★ | ★ CreateRenderTarget 包装 | 25 |
| 63 ★ | ★ CreateRenderTarget 内核 | 4 |
| 64 ★ | ★ 按句柄销毁 (RT/纹理共用句柄空间; CTextureData::ClearData 双版纹理句柄单参释放直证 0x1424063A0/0x142406C40; 旧记「DestroyRenderTarget 包装」系归属偏窄) | 97 |
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
| 81  | **GetUsedVideoMemory** (VRAM 前后对账消费 = 渲染就绪门 :2440/:2455; dx11 实装 0x14240FEA0 邻域) | 4 |
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


Reader = `sub_142229630`（`CGraphicsSettings::Reader` 槽 0x142229630）；
ctor = `sub_142227B10`；键名由 ref/token_table_1193.txt 映射：

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
LoadAssets sub_140B39270 → InitGame。⚠ **LoadAssets 名不符实**: 体仅两行 = 注册菜单
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
| S5 | 地图模式 | mapmodemanager 946 / defines_mapmode 1,588 / custom_map_mode 603 | sub_140E14680 = 模式 2 (STRATEGIC_NAVY) 每帧 updater (真 OnMapModeChange = sub_140A66DE0 CMapModeDispatcher::OnMapModeChange, mapmodedispatcher.cpp:238 实名, ~80 处切换统一点); sub_140E1B280 逐省着色 (§4.2 链): 政治混合 = byte/255 → 0.9f/0.65f/0.25f 三色构造 (14224BEB0 + 14224BFF0 lerp); 未认领哨兵色 0xAA00FFFF (PE ×4); 动画帧 = fmod(Δt, 帧数×qword_1430B1648)/周期×帧数 钳 [0,帧数−1]; gs+700 计数门语义 = **省数 (省表界)** (同函数 sub_140E1B280 逐省着色按省数消费 (§4.2 链) + mapbuildings 两处独立直证 (省 id 有效门 + 等级表按省一行), §4.14/§4.13 主流定案); 淡入淡出三通道 +1728/+1732/+316 步进 dt 后各 clamp [0,1], 方向门 = DRAW_COUNTRY_NAMES_CUTOFF (dword_14333645C) ≤ 缩放(a2+1668); +312 = +1732 镜像 |
| S6 | 地图图标 | mapicon.h 1,358 / mapiconmanagerimpl 691 | §4.30.26-28 类族 |
| S7 | 地图箭头/前线几何 | maparrow 481+370 / raid_arrow 824 | sub_141244070; sub_1423F4C90 点集切分; sub_141039F80 寻路 manager ctor sub_14126E990 / LoadDefinitions sub_141272920 (gfx/maparrows/maparrows.txt, lua 解析器 sub_141272F00) / 订单箭头装配 sub_141254FB0 (三静态色源 + 地图模式 39 分支) / per-frame sub_14124F710 / (⚠ 三池析构 sub_141662150 归属已改判 CGfxNavalCombatManager 清理 — §4.35.31, 非箭头管理器自身析构) |
| S8 | 相机/交互输入 | (0x140DB-DC / 0x14126 区) | CEU3Camera; sub_1412627C0 热键+位移 |
| S9 | GUI 框架核心 | containerwindow / buttonwrapper / gui.cpp | sub_1402A44A0 .gui 解析; sub_14225C690 事件分派 |
| S10 | 字体/文本渲染 | bitmapfont 2,102 | sub_14229C770 装载; sub_1422A1810 布局 |
| S11 | 文本引擎/本地化 | (0x1421E / 0x14224 / 0x1411B 区) | sub_1421EAA30 文本流格式化; sub_1411B4B10 浮点格式化 |
| S12 | 纹理/像素搬运 | texturehandler 949 (行数 = depth3 口径; 全 CU 7 函 989 行) / gfx_texture_cache 392 / flagtextureatlas 1,002 | sub_142133600 上传核; sub_142171F50 blit |
| S13 | 软件光栅 | SDL_render_gl 2,137 / SDL_render_gles2 1,612 | SDL_BlendLines 三核; 分派器 sub_1421A31A0 |
| S14 | 3D 实体/动画/粒子 | pdx_anim 1,185 / pdx_particle 408 (行数 = depth3 口径单函; 全 CU 2 函 931 行) | sub_14228D730 实例初始化更新 (dt=0, 精灵创建路径 — 原「挂点定位」系误标, pdx_entity.cpp 簇定性); sub_1423FE460 粒子更新; 全簇 14 件见 §4.35.17 |
| S15 | 调试/ImGui | pdx_dearimgui | sub_1421CBE30 Begin 原语; 观察窗族 |
| S16 | 面板/视图 GUI 行件 | (0x1416-0x141F GUI 区) | ~120 件, §4.35.13 分组台账 |

#### 4.35.14 地图箭头族布局与管线 (CMapArrowManager 族)

**类清单 (RTTI 认领 11 类)**: CMapArrowManager (lambda COL 0x1429a6848 直证类名) / CMapArrowDefinition (COL 0x1429a6348) / CMapArrowDefinitionInstance (基类 CLostDeviceInterface) / CMapArrowSymbolDefinition (推定) / CMapArrowTextDefinition (COL 0x1429a62a8) / CMapArrowButtonDefinition (COL 0x1429a62f8) / CArrowObject (COL 0x142b47c08, 基类 CPdx3DObject, ~216B: +96 CColor SetColor=sub_14126C590 / +112 顶点缓冲 + AABB 对) / CArrowType (COL 0x142b51ac8, ≥340B 含 5 std::string + f32 0.2) / CMapArrowObject (GfxCommonArrowUpdateCallback lambda RTTI 串 + hybrid allocator COL 直证类名) / USMapArrowVertex (COL 0x1429a65e0) / GfxCommonArrowUpdateCallback (COL 0x1429a59e0; 签名 `void(const CMapArrowObject*, const COrderInstance*, const COrdersGroup&, float, const CMapMode*)` mangled 直证)。

**CMapArrowManager (0x180=384B, ctor sub_14126E990, 定案)**: +0 上下文指针 (构造实参 a2, 设备/渲染上下文待裁) / +16+48 双 std::string 32B / +80 CColor 数组 (LoadDefinitions 第4输出) / **+136 原始定义数组 / +160 实例数组** / +184 辅助数组 (装载尾 sub_1412746B0 构建, 语义待裁) / **+208 原始符号定义 / +232 符号实例数组** (元素 0x30B) / +256 数组头 / +336+360 双 std::string 24B。

管线三链 —
- **装载 (启动)**: map 初始化巨函 sub_1413944D0 → malloc(0x180) ctor → 宿主 +1744 → sub_141272920 装载 `gfx/maparrows/maparrows.txt` (lua 解析器 sub_141272F00, LoadDefinitions 五参签名 RTTI 直证: path + arrows→+136 + symbols→+208 + textDef→+288 区 + colors→+80); 循环1 逐箭头 malloc(0x60) ctor sub_141265130 → +160; 循环2 逐符号 malloc(0x30) ctor sub_141B1F350 → +232; 热重载 sub_141587A90 ("Map arrows reloaded") + 重解析比对件 sub_1412739D0。字段名 TextureMaskList/TexturePatternList = maparrow.cpp:440/447 断言直证。
- **创建 (订单→箭头)**: 三包装 sub_1412563A0/E0/480 → 订单解析 sub_141254CD0/D40 (order+96 引用槽 → COrdersGroup) → **装配总入口 sub_141254FB0**: 选色三分 (orderInst+665 旗 → 静态色 unk_143331BE0 / 同国 → scope 派生色 / 异国 → unk_143331B30, 地图模式==39 改 A70) → CColor lerp sub_14224BEB0 (1.0f/0.5f 两档) → SetColor 写 +96; 同国且有选中指令组 → GfxCommonArrowUpdateCallback 经 sub_140DFD540 注册延迟更新; 箭头指针集合 = CPdxHybridInlineBufferAllocator<CMapArrowObject*,128,int> (128 项内联)。
- **每帧**: 泵 sub_140B58470 宿主 +1816 → **sub_14124F710 (箭头+弹道实体共享 per-frame)** → **gs+2617 会话门** (§4.1 该字段新消费点) → sub_141244070 (5,020 行重建主件; 时间节流门 qword_1430B2E18+上次时刻; 玩家国 gs+1680 视角); 动画时钟 = (gs+1212 速度级+1)×Δt, 暂停归零; 袭击箭头独立走宿主 +1792 → sub_141668C10。
- **销毁**: sub_140B52130 = 突袭 GFX 清理+懒取复合 (含 :3732 断言); 其调用的 sub_141662150 三池析构 (实体句柄+SSO 串+双定长数组) **归属已改判 = CGfxNavalCombatManager 元素清理** (唯一调用点被 CGraphicalMap+1824 门守卫 — §4.35.31; 箭头管理器自身析构函另寻)。

**defines 全族** (NGraphics): ARROW×5 / RAID_ARROW×14 / RAILWAY_MAP_ARROW×15 / RIVER_SUPPLY+SUPPLY_CONSUMER×3, 含数据槽 dword_1433363BC (ARROW_MOVEMENT_SPEED)。主要未决: qword_1430B2E18 初值 / CMapArrowObject 完整布局 (≥512B 无 ctor) / mgr+184 辅助数组语义。

#### 4.35.15 地图模式管线 (CMapModeManager 三段)

**切换段** (~80 处统一点): sub_140A66DE0 = CMapModeDispatcher::OnMapModeChange (mapmodedispatcher.cpp:238 实名) → 旧模式退出清理 (overlay 隐藏/hover 清/层停用) → 新模式入场预着色 → **sub_140E17F30 SetMapMode 状态机**: 同 id 非 force 早退 / 释放旧实例 / vtable+184 通知 / switch(id) 写 bank 槽对 (sub_140F31D20) + 层子模式 (sub_140F3B090) + 行选脏闩 (+129/+130) / ≥40 查自定义库 qword_14332F040 → 每路尾调 sub_140E18DF0 SelectModeInstances 向 hub (mgr+64) 灌 tag 色 → 尾取 24B 槽可见性掩码。

**每帧段**: 三 idler (ingame/frontend/nudge) 全部驱动 sub_140E1A890 UpdateDispatch — 日历追赶门 (dword_1430B15C0 三日游标逐日追赶扫) / 图例旗 → hub 全量重建 / switch(模式 id) 逐模式 updater / mgr+4 副模式支 (gs+700 省数门); 随后 sub_140E1DAA0 ApplyTweens 应用闩 (脏时写 mapview+1696/+1700 行选并触发行重建)。

**输出段双通道**: A. 省色贴图通道 — bank 23 槽脏位 → RefreshSlot (分派断言属 gradientbordermanager.cpp, 与 S4 渐变边框 18 件同库互证) → CRect 合并 → 省色纹理脏矩形提交; B. 国色通道 — hub 树暂存 tag→色 → flush 逐 tag/全量刷 (pdxmap 省色通道)。

**模式注册表**: 40 个硬编码 id 全表 (−1..39, 含槽对/层选参/行选逐模式表); id→loc 名 17 项 (sub_140E028C0, "MAPMODE_DEFAULT/STRATEGIC_AIR/…/RAIDS"; 1/32 与 16/38 别名组, 28 = DEFAULT 别名); **custom 模式 id = 40+下标**, 库单例 qword_14332F040 (64B; item+232 名 / +272 激活旗) — ⚠ **两层对象**: 该槽 = CMapModeManager 侧运行时实例库; 装载期另有**定义库 qword_143330DC8** (40B, 511 桶链式, 条目 176B CCustomMapMode, §4.30.54); 定义库→运行时库桥接 (id = 40+下标实例化) 未定位。**CMapModeManager 288B 字段级增量**: +4 层选参 / +16+24 实例 shared_ptr / +80/+84 行选 (+129/+130 脏闩) / +64 hub / +88 全量重建旗 / +96 hub 对象 / +272/+276/+280 (自定义模式暂存)。

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
| S7 箭头/前线几何 | 3 | ★sub_141039F80 1,746 advancement 寻路; ★sub_14126FD50 1,162 纹理校验; sub_141662150 102 三池析构 (归属已改判 CGfxNavalCombatManager, §4.35.31) |
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

**② 网格装载管线 (mesh → GPU)**: 装载入口 = **CPdxMeshType vtable[9] 0x14230A510** (.mesh
装载巨函, pdxmeshtype.cpp; 管线上游全貌 §4.35.16a), sub_142264F50 = 其骨架提取子步
(pdxassetutil.cpp 系; 键 object/skeleton/mesh/skin;
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

#### 4.35.16a CPdxMeshType .mesh 装载域 (pdxmeshtype.cpp 3 函; vtable 槽模式横向定案)

清册 (3/3 函体内含 pdxmeshtype.cpp 全路径锚):

| VA | 行数 | 身份 |
|---|---|---|
| 0x14230A510 | 2142 | vtable[9] .mesh 装载巨函 (Load/Reload; §4.35.16 ② 管线的宿主, 详见下) |
| 0x14230D680 | 250 | vtable[4] token reader (§4.00 键表全复核 ✓ + 新增两门, 见下) |
| 0x14230DAE0 | 99 | SAnimationLookup vtable[4] token reader (新定案) |

**CPdxMeshType vtable (0x142B4D7A0) 15 槽语义实测**: [-1] COL / [1][3] = Save/Load wrapper
全族共享桩 (0x1424BEC50/0x1424BE690, [3] = 共享 token 循环逐 token 调 [4]) / [2] writer =
CFG 空桩 (= 不入存档直证) / [4] reader / **[9] .mesh 装载** / **[13] 对象工厂**
(malloc 208 + ctor 0x142275B60 = CPdxMeshObject)。横向互证: 基 CPdx3DType / 兄弟类
CPdxParticleType 同槽位对比, **[4] reader / [9] 装载 / [13] 工厂三槽模式全族一致 (定案)**;
子对象 SAnimationLookup 亦套 [3] 同值 wrapper + [4] reader 的 5 槽前缀。

**vtable[9] 装载全机制** (定案, 签名 (this, gfx_mgr)): ① 开档失败 → assert + **永久回退**:
错误日志后把 `gfx/models/test_object.mesh` 写回 +184 重开。② 结构校验双循环: object 数组
(112B/条) 仅取名 == "object" 条目 → mesh 数组仅取名 == "mesh" 条目 (字面量 PE 直证);
流表按名查 p/n/ta/u0..u3, 计数对账 = vertex = p/3、n = 3·vertex、ta = 4·vertex、UV 各
2·vertex, 违者累积 "vertex <-> … count mismatch" 串 → 汇总错误日志。③ 四步管线
(骨架 142264F50 / 顶点 142264190 / 皮肤 1422637D0 / 索引 142262F00, 四步全为本函专属调用方)
→ §4.35.16 ② 设备 ABI。④ 关节上限: 骨架关节数 > 50 → "too many joints" 错误日志。⑤
动画相容性: 逐 +216 条目以骨架验, 不相容 → 错误日志 + **原地 erase 条目**。⑥ 材质槽表
+72/+84 (24B/槽) 分组: 264B 记录 {+72 材质索引 (−1 = 无), +76..+88 中心半径, +92..+112
包围盒, +125 旗}; 索引 −1 的记录第二遍归表尾新追加槽; 记录 +125 旗 → 置 +368/+369 双旗。
⑦ 包围盒 +160..+180 重置哨兵并入全记录; 中心 = (min+max)×0.5 → +144..+152; **包围球半径
+156** = max(各记录 |中心−类型中心| + 记录半径)。⑧ +336/+340 = 两次 sub_142409E20 渲染
资源 id 对。⑨ +312 f32 数组 (count@+324) 逐元素平方 (语义待裁)。⑩ 双尾锚: 皮肤错误汇总
(:397) / +84 == 0 → "Pdx mesh type with no meshes … won't render." (:404)。

**vtable[4] reader 增补两门** (键表 §4.00 全复核 ✓): file 键读入后 `\`→`/` 归一, 以 "dlc/"
开头 → assert (资产不得显式引 DLC 路径, debugbreak); animation 键整块解析后按 +8 FNV 键
线性去重, 重复且已解析 → 错误日志 + **terminate**。

**SAnimationLookup** (56B; vtable 0x142B4D750):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vptr | vtable 0x142B4D750 |
| +8 | u64 | FNV-1a32 零扩展 (键 = token 11 "id" 串值) |
| +16 | 指针 | 已解析动画资源 (token 225 "type" 串经动画库查得; 查无 → 错误日志 + terminate) |
| +24 | CString (32B) | type 串本体 |

> 备注: 同键多 stub 允许多条共存 (去重只拦 +16 非空者), 后续覆盖路径未查。
> 未决: vtable[9] 的 .asset 侧分发点 (纯间接调用, 语料不可见, 归 pdxasset.cpp 簇) / +312 平方

#### 4.35.16b DX11 后端设备域 (gfx_dx11.cpp 15 函; 92 槽表 dx11 侧实装)

清册 (15/15 函体内含 gfx_dx11.cpp 路径锚; 11/15 函经表安装器 sub_1424047C0 id==1 分支交叉
归位): CreateDevice 0x142414270 (356, 槽 0) / LoadSettingsForAdapter 0x142413B90 (311, 槽 90) /
CreateTexture2D 内核 0x142410450 (307, 非表槽, 被槽 61/62/63 直调) / HLSL 编译+磁盘缓存
0x142410B70 (279) / Screenshot 0x142416500 (148, 槽 86) / HRESULT 错误格式化器 0x142416C70
(116, FormatMessageA + DEVICE_REMOVED 特判追 GetDeviceRemovedReason) / UploadTexSub
0x142415F40 (114, 槽 68) / EndFrame/Present 0x142414D10 (99, 槽 9) / GfxSetVertexBuffers
0x142415700 (97, 槽 39) / UploadTexture 0x142415DA0 (90, 槽 67) / BuildVertexShader
0x142411880 (49, 槽 26) / BuildPixelShader 0x142411770 (49, 槽 29) / DestroyDevice
0x142415890 (41, 槽 1, 9 对象成对释放) / COM 释放 helper 0x14240FEA0 (22) / catch funclet
0x1426F4710 (11)。

**CreateDevice 全机制** (定案): DXGI Factory2 + D3D11CreateDevice (FL 4 级 / DEBUG 旗 /
E_INVALIDARG 弃 11_1 回退; "dx11-old" 旗短路 Device1/Context1 QI) → 交换链 (三缓冲
R8G8B8A8, 条件 FLIP_DISCARD/ALLOW_TEARING, NO_ALT_ENTER) → 深度 D24S8 → N 上下文记录 +
默认资源。**槽 9 = EndFrame/Present 三后端定案** (dx11 = FinishCommandList×N →
ExecuteCommandList → Present(vsync? (1,0):(0, tearing?0x200:0)) → 帧计数%3 → 记录重置;
详见 §4.35.5 表)。槽 10/11 Begin/EndScene 对 dx11 = ret1 桩 (dx11 真实帧末在槽 9)。

**设备对象 272B 全表 + 688B 记录全表** (含 flip/tearing 位、双三状态组成对释放; findings §2)。
**shader 缓存机制**: `shadercache/dx11_win32/<target>.scache` (FNV-1a-32 源码哈希, 存源码 +
字节码两段; ENABLE_STRICTNESS)。**槽 90 出参契约**: 适配器名/VRAM MB + MSAA 档表 (12B/档) +
FL11.x → 阴影默认 1280 否则 1024。上传双函数 = dynamic 门 (+52) + 子矩形盒钳位
UpdateSubresource。9 个 GUID PE 直读破译 (Factory2/4/5, Device1/Context1, Texture2D,
UserDefinedAnnotation, Factory1, Adapter3) + FL 表 {11_1, 11_0, 10_1, 10_0}。

未决: CreateTexture2D Usage 槽 (+28 纯 RT 路=1/其余=0) 与公开 D3D11_USAGE 枚举解读矛盾 /
两处反编译 D3D 槽号与公开 vtable 出入 (一律按语义定案) / 记录准备段与槽 7/12/27 默认状态
模板逐字段。
> 数组语义 / SMeshData 六串键名 / +264/+288 出参数组字段级布局 / +336/+340 渲染 id 类型 /
> 热重载下材质槽只增不清的依赖条件。

#### 4.35.16c graphics.cpp 图形核心运行期 (CGraphics 三件套与资产工厂; 10 函闭环)

清册 (10/10 函体内含 graphics.cpp 路径锚): InitDevice 0x142239540 (892) / CAnimationReloader
reader 0x14223B400 (513, 图形资产族工厂+热置换; vtable 0x142B3D770 [9] 直证) / CGraphics
全量析构 0x142236330 (276) / **DeInit 本体 0x142237CD0 (143**, 书原只有守卫串) / 渲染就绪门
0x1422370E0 (169) / sprite 实例获取 0x142237A10 (131, 缺失 → GFX_default_fallback_texture
递归, fallback 也缺则 Fatal) / GetFont 带回退 0x142238A20 (131) / 2D 实例释放双路
0x142237FA0 (77, 双删断言; 延迟 = +325 压 +16 队列 / 即时 = swap-remove) /
**ResetDevice 0x14223E300 (42**, "Reset occurred."; 消费端 = 控制台 fullscreen 切换命令) /
ReloadShaders 0x142238190 (17, 零直接调用点)。

**三件套定案**: InitDevice = 三数组前置扩容 (min 2048) → 34B 参数块槽 0 建设备 → fullscreen
失败降级桌面分辨率重试 (:979/:981) → 9 状态对象 (槽 53×4/槽 57×5) → shadowmap 门; DeInit =
sprite type 释放 + 设备对象卸载 + 六子系统 teardown + 清 +206316 (与 Init 六子系统配对);
ResetDevice 尾 +1288 词写 0x0101。**+1288 = 帧就绪/Present 复合锁存** (+1289 reset 旗;
§4.35.1/§4.35.3 注)。渲染就绪门三态 = 槽 3 设备态 0 → 置 1; 首帧失败 QPC 精确睡 1000ms;
态 2 → VRAM 前后对账 (槽 81) + AE60/AF50 恢复链。**ABI 补槽**: 槽 3 = GetDeviceState /
槽 5 = OnResetDevice / 槽 6 = OnLost / 槽 81 = GetUsedVideoMemory / 槽 82/83 = 设备批 RAII
guard (现役空桩)。**资产工厂 20 token 全表** (spriteType/bitmapfont/pdxmesh/pdxparticle 等;
三容器族, 同名同型迁移链, 异型报错 :641/:655)。

未决: "anim" 扩展名重载器却解析 .gfx 全族的触发链归属 / +1320/+1264 与 20 token 产品类
RTTI / devinit 槽 14/82/83 实参汇编核 / shadowmap 分支无动作语义。

#### 4.35.16d OpenGL 后端设备域 (gfx_opengl.cpp 11 函; 92 槽 GL 分支全图)

清册 (11/11 函体内含 pdx_gfx\gfx_opengl.cpp 路径锚): CreateDevice 0x142422AF0 (333, 槽 0) /
LoadSettingsForAdapter 0x142422530 (317, 槽 90) / 必需扩展校验 0x142424C20 (221, 8 项
FBO/VBO/GLSL 族, 只警不拒恒返 1) / CompileShader(PS/VS) 0x142420600/0x142420B60 (185/158,
槽 28/25; ARB 兼容剖面, 信息日志行号解析抽出错行 ±4 "SHADER CODE / ACTUAL FAULTY LINE") /
DrawPrimitive/Indexed 0x142422190/0x142421F20 (153/153, 槽 18/19) / **LinkProgram
0x142424990 (104, 槽 30 真身**, 表槽 sub_1424237F0 尾调) / SetVertexStream 0x142424060
(97, 槽 39) / BuildVS/PS 0x142420F50/0x142420E40 (49/49, 槽 26/29; GLSL builder
sub_142429CD0 = gfx_glsl_builder CU)。

**GL 分支 92 槽全图** (安装器直证)。**GL 设备 424B 全布局** (dx11 272B 对照; 单例
qword_1435DD178): CreateDevice = SDL_GL_CreateContext + glewInit + 能力旗 7 字节 + 三默认
状态/纹理/三态快照 (上下文失败不中止)。**program 120B = uint[30]** (UNIFORM0-5/tex0-15/
vertextex0, PE 名串直读) + buffer 12B {偏移, 顶点数, GL 名}。**双常量系统双脏旗**:
+208..+304 具名 uniform / +312..+376 顶点流 — 槽 39 SetVertexStream = 纯缓存置脏
(dev+312/+344/+360, 脏旗 dev+376), 绘制时惰性冲刷 glUniform4fvARB + 顶点声明懒重绑 →
glDrawArrays / glDrawElements(BaseVertex), 索引恒 ushort。LoadSettings 出参
{+16=1, +20=MAX_ANISOTROPY, +24/+28=768, +32=1024}; MSAA 档按「倍增序列 ∧ ≤GL_MAX_SAMPLES」
校验 (判据与 dx11 异构)。GL 函数指针 19 个全部按装载器 wglGetProcAddress 字面串定案。

⚠ 断言总门歧义待裁: GL CU 内 Important 断言门 = byte_1435E1B51 而 dx11 实装记载 = E1B52 —
总门字节按 CU 分治或 dx11 侧记载偏 1, 待三后端并裁 (GLSL builder CU 侧亦用 B51)。

未决: SDL 包装三件浮点 get/set(32) 语义 / 绑定条目 +16..39 元数据 (归 glsl_builder 批) /
GL 小查询槽 ~15 个 / LoadSettings 出参块跨后端异构的泛型消费方式。

#### 4.35.16f gfx_supply.cpp 路径条管线域 (5 函闭环; 补给/铁路/河网共用)

清册 (5/5 函体内含 gfx_supply.cpp 路径锚; 与 §4.28 BAB0 铁路线绘制核咬合): 连接-父边收集器
0x141656F90 (183, SRiverPath 请求 {端点 A/B, 段 id} + 省对去重 + 待绘 PQ) / 路径求解器
0x14165DA50 (658, **CMap+616 路径条图 +628 计数补录**, BFS 顶点链, 扩展门 = sys+16 偏移表 →
calc+208 涉足位图, 回溯填请求 +16 found/+20 终点对/+40 途经对向量) / 旗标发射器 0x14165B4D0
(368, 省对序列按去重集切 run, 写 48B 几何记录 +44 位域 bit0 命中/bit1 方向/bit2 高亮) /
省份标记取色器 0x1416569F0 (128, 悬停/瓶颈红绿 = 省+32 vs max(MAX_RAILWAY_LEVEL, 首都节点
_TotalSupply), 白-色渐变 lerp, 开闭五态) / 补给流箭头刷新 0x14165E8E0 (416, **css+168 节点流
缓存第二读者** — country_supply.h:386 断言与 §4.21 已收 sub_141658020 同源; 按
SUPPLY_FLOW_REDUCTION_THRESHOLD 三档取 NODE_FLOW_IN_{CURRENT,HALF,FULL}_RANGE_COLOR 发射;
由渲染环 sub_140B572D0 经宿主+1840 每帧驱动)。

**流水线总控** (定案): sub_14165FB20 串联 6F90 → BAB0 → DA50 → B4D0×2 → D050 (调 69F0) →
D730 — BAB0 与发射器为兄弟调用 (§4.28 注)。**define 三锚**: NSupply.MAX_RAILWAY_LEVEL
(= dword_1433349D8, 钳 1) / SUPPLY_FLOW_REDUCTION_THRESHOLD (= qword_143335070) /
CIVILIAN_MIN_INTEL_TO_SHOW_RAIL_STAUS (= qword_143331D40, 轨道状态情报门)。CColor 工具面 =
14118F770 (ARGB 截断打包) / 14224BEE0 (白 ctor) / 14224BFB0 (钳位 lerp)。

> 工具注: PE 直读颜色时 **.data raw<virtual 陷阱** — va2off 须加 raw_size 校验, 否则未校验段
> 会读到 .pdata 文件字节。

未决: DA50 边条 [1][2] vs [3][4] 顶点对语义 / 6F90 三处 MAX_RAILWAY_LEVEL 槽 / 69F0 渐变 t
源 (xmm 不可见) 与 7 个色槽运行期值 (.data 未初始化尾部静态不可得) / FB20 的 v91/v96 宿主槽 /
模式编号 5/34 对 §4.35.15 核对。

#### 4.35.16e 国旗纹理图集域 (flagtextureatlas.cpp 3 巨函闭环; 全量构建/增量重绘/单旗装载)

清册 (3/3 函体内含 flagtextureatlas.cpp 路径锚): 图集全量构建 0x14123D920 (1087) / 增量逐旗
重绘 0x1412405C0 (397) / 单旗像素装载 0x14123F7E0 (234)。

**图集对象 304B 全布局** (定案; 软重置函 0x14123D890 九 count 清零互证): 9 容器 + 基路径/
overlay 双串 + 旗宽高/图集宽高/紧排模式五几何字段; **三实例内嵌宿主 +206328/206632/206936**
(大/中/小旗, CGraphics 尾部)。**旗槽 24B UV 记录** = {u0/v0/du/dv 四 float + 有效位 + 纹理号 +
纹理基序号} — GUI/地图旗渲染取数契约面。旗序号 1-based = 国家下标 (国家 0 无旗); +20 字段 =
每纹理容量×纹理号+1。

**全量构建** (定案): 几何布置 (紧排/缩边双模尺寸搜索) → 纹理新建 (sub_1424046D0, format 13) /
整面上传 (槽表 off_1430BF9C8 → 0x142415DA0) + tbb parallel_for (functor = CGenerateThreaded)
逐旗并行生成。**增量重绘** = 写国 → 元数据四数组 + 逐旗子矩形 blit (off_1430BF9D0 →
0x142415F40) + 填 24B UV 旗槽; **调度 0x14123FE20**: 元数据现值比对, 变更 ≤ 国家数/4 走增量,
否则全量重建; 装载谓词四探针 (!sub_140BB5440 ∨ owned_states+1156>0 ∨ 非人类控制 ∨
+5213 reserved_dynamic_country)。

**单旗装载四组合序** (定案): cosmetic_tag×ideology → cosmetic_tag → tag名×ideology → tag名,
各 + ".tga"; TGA 装载核 sub_14123FBB0 错误码 0..5 全文 (PE 直读 off_1430B2D20; **5 = 24 位慢
格式警告仍判成功**) + 底左翻转 + 24 位 alpha 强制 0xFF。九尺寸全局 ↔
NDefines::NGraphics::COUNTRY_FLAG_{,MEDIUM_,SMALL_}TEX_{WIDTH,HEIGHT,MAX_SIZE} 逐一对应;
中/小图集单纹理门 (gamegraphics.cpp:128/:134 — S17 sub_140B406A0 = 三图集初建编排者直证)。

未决: tbb 任务捕获块字段排布 (IDA OWORD 失真) / sub_140BB5440 阈值
*(qword_143330D98+136) 语义 (推定动态国 tag 分界) /意识形态链 +208→+24 书内归属 (politics
域) / 宿主类名 (可达式 *(qword_14332F698+1264)) / overlay 混合公式未汇编复核。

#### 4.35.16g .asset 装载链 (assetfactory.cpp / assetfactory_audio.cpp / assetfactory_common.h 11 函; 工厂 reader → 专用模板 reader → 管理器登记)

清册 (11/11 函身份经 RTTI 名 + vtable 槽契约双直证): **CAssetFactory::Reader** 0x14234DB90 (501, .asset 顶层四键分派; :767 动画装载失败 / :876 clone 父实体缺失 两格式化错误日志) / SAnimationData::Reader 0x1423506F0 (51, :35 "dlc/" 断言) / **SEntityReader::Reader** 0x142350EA0 (543, :622 game_data 无注册 reader) / SEntityStateReader::Reader 0x142351B70 (422, :253 time_offset 参数数 / :335 game_data) / **CAssetFactoryAudio::Reader** 0x14234A010 (430, 六键分派; :499 music / :467 sound 缺失) / SSoundEffectReader::Reader 0x14234AB90 (187, :178 overflow 行为) / SSoundFalloffReader::Reader 0x14234B020 (97, :302 falloff 类型) / **CAssetFactoryAudio::[0] 装载后链接器** 0x142349D30 (174, :555 类别↔音效未匹配 / :577 音效无类别 + pdx_scoped_buffer.h:54 容量断言) / SAnimatedLightReader::Reader 0x14234E580 (1768, 8 键) / SVectorParamReader::Reader 0x14232CCB0 (1941, 九分量→4 槽位对) / SForceReader::Reader 0x142331D20 (1012, 8 键)。

**CAssetFactory::Reader 四键分派 (定案)**: animation(64) → SAnimationData {file(26)@+8 / name(27)@+40 两 std::string}, 以工厂 +16 名串拼路径 → 动画库登记 (失败 :767); light(84) → SAnimatedLightReader, 九参数容器各经 sub_14232C820 转串 → sub_1423DE650(灯管理器单例 **qword_1435DA0F0**, 名, 九串块) 登记; particle(407) → SParticleSystemReader (ctor 0x142330750, +8 ← 工厂+16), 置 +26=1 递归解析; entity(438) → SEntityReader, 收尾 sub_1423529A0 → **meshsettings 登记环** → clone 父实体解析; 其他键落基 reader sub_1424BEC40。

**meshsettings 登记环 (定案)**: 遍历 SEntityReader+1272 meshsettings 向量 (元素 SMeshData 216B), 门 = 条目 +56/+88/+120 (三串 size) 任一 > 0 → sub_142261B40(**qword_143453090 = CGraphics::Get() 单例**, 条目, id 出参 {-1,0}, 三串出参, .asset 目录前缀, 0, preload 旗 = 条目+1296); 登记返回后三串写回条目 +40/+72/+104、id 对写回 +200/+208。clone: 条目 +520 名非空 → sub_142291330/sub_142293530 查父实体, 命中 sub_142291E30 克隆, 未命中 :876 错误日志; 空则 sub_142292800 直登。+25 旗 → 全程 sub_142291C70(1/0) 包裹 (实体库克隆态开关)。

SEntityReader (≥1297B; ctor 0x14234C010):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | char[256] | name (27) | +263 收尾 \0 |
| +264 | char[256] | pdxmesh (384) | +519 \0 |
| +520 | char[256] | clone (449) | 父实体名; +775 \0 |
| +776 | char[256] | default_state (499) | +1031 \0 |
| +1044 | u8 | get_state_from_parent (572) | +1045 存在旗 |
| +1092 | u8 | scale (93) 存在旗 | |
| +1096 | f32 | scale (93) | |
| +1100 | i32 | version (238) | ctor 0 |
| +1108 | f32 | cull_radius (500) | |
| +1112 | u8 | playback_rate (501) 存在旗 | |
| +1116 | f32 | playback_rate (501) | |
| +1120 | u64 | game_data (508) 上下文 | 第 4 参 = 0; ctor 0 |
| +1128 | 向量<SEntityStateReader> | state (439) | 元素 656B; 1.5× 增长; alloc off_143085170 |
| +1152 | 容器 | 未决 | ctor 置分配器 |
| +1176 | 向量<SAttachment> | attach (338) / group (63) | 元素 336B; attach 额外置条目+8=1 |
| +1200 | 容器 | 未决 | |
| +1224 | 向量<SEntityLocatorReader> | locator (511) | 元素 624B |
| +1248 | 容器 | 未决 | |
| +1272 | 向量<SMeshData> | meshsettings (677) | 元素 216B; 登记环消费 |
| +1296 | u8 | preload_textures (673) | 登记环第 7 参 |

> game_data 键 (508) 在 SEntityReader (+1120) 与 SEntityStateReader (+600) 两 reader 语义异构: 前者第 4 参传 0 / 后者传 1 (推定 实体级 vs 状态级回调旗); 两处同走「无注册 reader → 错误日志 + skip 块」路径。game_data 注册表 = sub_1422912E0() 返非空时以函数指针逐 token 回调的全局单表, 跨两 reader 与模板属性解析回调共用。

SEntityStateReader (≥640B):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | char[256] | name (27) | +263 \0 |
| +264 | char[256] | animation (64) | +519 \0 |
| +520 | f64 | animation_speed (442) | |
| +528 | f64 | animation_blend_time (443) | |
| +532 | i32 | time_offset (476) base | {base variation} 二元或单值, 违者 :253 |
| +536 | i32 | time_offset (476) variation | |
| +540 | u8 | loop_animation (444) / looping (454) | 同槽别名对 |
| +544 | f64 | loop_time (450) / state_time (475) | 同槽别名对 |
| +552 | u64 | next_state (472) | 键名串 FNV-1a32 零扩展 |
| +560 | i32 | chance (446) | 读后钳 ≥0 |
| +600 | u64 | game_data (508) 上下文 | 第 4 参 = 1 |
| +608 | 向量<SEntityEventReader> | event (440) | 元素 1808B |
| +632 | 哈希容器 | propagate_state (505) | (键名 FNV, 源文件名 FNV) 二元对入表 sub_140224490 |

**SMeshData (216B)** — 跨宿主共享结构 (CPdxMeshType 向量基 +96 / SEntityReader 基 +1272; copy ctor 0x1423094C0 + move ctor 0x142309320 双直证):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vptr | SMeshData::vftable |
| +8 | std::string | 串 1 {buf@+8, size@+24, cap@+32} |
| +40 | std::string | 串 2 (登记环写回位 1) |
| +72 | std::string | 串 3 (登记环写回位 2) |
| +104 | std::string | 串 4 (登记环写回位 3) |
| +136 | std::string | 串 5 |
| +168 | std::string | 串 6 {buf@+168, size@+184, cap@+192} |
| +200 | u64 | 登记 id 对 (入参 {-1,0} → CGraphics::RegisterMesh 返回; +204 高位) |
| +208 | u32 | 登记 id dword2 |
| +212 | u32 | 未决 (ctor −1 落点) |

> 六串语义未决 (登记环只写回 +40/+72/+104 三串)。「dlc/" 资产路径禁令 = **资产层通用约束**, 两实例: CPdxMeshType file 键 (§4.35.16a) 与 SAnimationData file 键 (读后 sub_1424CD530 查 "dlc/" 前缀 → 断言 assetfactory.cpp:35, B52 门 latch byte_14348145D 一次性)。

**CAssetFactoryAudio::Reader 六键分派 (定案)**: falloff(79) → SSoundFalloffReader → sub_1423B66E0(+24 管理器句柄) / soundeffect(276) → SSoundEffectReader 入 +32 向量 (152B/条, 1.5×) / sound(441) → SSoundReader (ctor +16 ← 工厂 +8 名串) → sub_1423BE9F0, 失败 :467 / music(573) → SMusicReader → sub_1424DC920 校验 → sub_1423B5C40, 失败 :499 / category(702) → SCategoryReader 入 +56 向量 (88B/条) / master_compressor(703)·music_compressor(704) → SCompressorReader → sub_1423BE810/0x1423BE8D0; 其他键落基 reader。

**装载后链接三段 (CAssetFactoryAudio::[0] 0x142349D30, 定案)**: ① 清+登记 = sub_1423B6030(+24) 重置管理器 → 逐 +32 条目 sub_1423B68A0 登记音效 → 逐 +56 条目 sub_1423BDFC0 登记类别 (返类别句柄); ② 交叉链接 = 逐类别的名串向量 (类别+64 data/+76 count, 32B/串) → sub_1423B7110(管理器, 名, 1) 查音效 → 命中 sub_1423B75E0(管理器, 音效, 类别句柄) 赋类别, 未命中 :555; ③ 全表校验 = sub_1423B72D0(管理器, 0, 0) 取总数 → scoped 缓冲 (sub_1424E40D0; B52 门 pdx_scoped_buffer.h:54, latch byte_14348145C) → sub_1423B72D0 填指针 → 逐项 sub_1423B72A0 查类别, 未赋且 byte_1430BE031 → :577 警告。

SSoundEffectReader (152B) / SSoundFalloffReader:

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | std::string | name (27) | 音效名 |
| +40 | std::string | falloff (79) | 引用衰减名 |
| +72 | i32 | max_audible (680) | |
| +76 | i32 | polyphony (743) | |
| +80 | f32 | volume (287) | |
| +84 | 2×f32 | volume_random_offset (589) | sub_140ADDCA0 二元读 |
| +92 | 2×f32 | delay_random_offset (682) | |
| +104 | 容器 | sounds (588) | SSoundsReader 子 reader 写入 a1+104 |
| +128 | i32 | max_audible_behaviour (681) | "fail"→0 / "silent"→1, 否则 :178 |
| +132 | f32 | fade_in (684) | |
| +136 | f32 | fade_out (683) | |
| +140 | f32 | playbackrate (699) | 读入 ÷100, 默认 100.0 |
| +144 | 2×f32 | playbackrate_random_offset (700) | ÷100 |
| +153..+158 | u8×6 | looping_volume_random_offset (688) / looping_delay_random_offset (689) / random_sound_when_looping (690) / looping_playbackrate_random_offset (701) / is3d (605) / prevent_random_repetition (742) | 六 u8 |

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | std::string | name (27) | 衰减名 |
| +40 | f32 | min_distance (590) | |
| +44 | f32 | max_distance (591) | |
| +48 | f32 | height_scale (592) | |
| +52 | i32 | type (225) | "linear"→0 / "logarithmic"→1, 否则 :302 |

> 音频资产链与图形资产链结构同构 (工厂 reader → 专用 reader → 管理器登记), 但**无 CGraphics 中间层** — 管理器句柄直接内嵌工厂 +24。

**头模板族共性 (common.h 三 reader, 定案)**: 三 reader 同基 (默认分派 sub_1424BEC40), 同用**动画参数槽**机制与**词法 token kind** 协议; 膨胀代码量 (1012~1941 行/函) = 模板逐分量展开 + 数值/串双态分支, 非业务复杂度。

**动画参数槽 (三族共享, 定案)**: 参数槽 68B = {+0 u32 形态旗 = 0 数值 / 1 字面串; +4 f32 数值 (形态 0, 定点 1e-5 还原 = 词法值 ÷100000.0) 或 char[64] 引用名 (形态 1, strncpy ≤63)}。参数容器 24B = {+0 参数槽* data / +8 u32 capacity / +12 u32 count / +16 引擎分配器* (vtable+8 alloc(size,align) / vtable+16 free)}。词法 token kind 协议 (a2+40 词法器, +24 当前 kind): **12 = 数值 / 8 = 分隔 (列表续) / 4·19 = 块结束** / 串形态首字节 **'@' (0x40) = 引用语法** → sub_1424C04A0 解析 (u32, u8, 串) 三元组 + sub_14015A6F0 回写 (推定 曲线/变量引用, 待裁); 块形态判定 = a2+192 == 3。

SAnimatedLightReader (≥284B):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | 参数容器 | position (76) → x | 位置 X 动画参数 |
| +32 | 参数容器 | position → y | 位置 Y |
| +56 | 参数容器 | position → z | 位置 Z |
| +80 | 参数容器 | color (86) → r | 颜色 R |
| +104 | 参数容器 | color → g | 颜色 G |
| +128 | 参数容器 | color → b | 颜色 B |
| +152 | 参数容器 | intensity (436) | 单值形态 |
| +176 | 参数容器 | radius (437) | {base variation} 二元形态 |
| +200 | 参数容器 | falloff (79) | |
| +224 | 向量<SCurveAnimationReader> | animation (64) | 动画曲线表, 元素 128B, 1.5× |
| +248 | std::string | name (27) | {buf@+248, size@+264, cap@+272} |
| +280 | f32 | duration (109) | ctor 默认 −1.0 |

> position/color 两键均委派 SVectorParamReader 子 reader (宿主 ctor 传入三分量目标容器指针); 分量超过 3 → assetfactory_common.h:130 "Too many parameters!" 格式化错误日志 (三族共用串)。light 键收尾时九参数容器各经 sub_14232C820 转 32B 串块交 sub_1423DE650 登记入灯管理器 (容器→串转换语义待裁)。

**SVectorParamReader 分量→槽位映射 (定案)**: reader+8/+16/+24 = 三分量基容器 (宿主 ctor 传入), +40/+48/+56/+64 = 变体容器 (灯宿主未设 = 灯分量不支持变体)。x(32)/r(428)→基+24 变体+56 / y(33)/g(429)→基+16 变体+48 / z(421)/b(430)→基+8 变体+40 / w(422)/alpha(423)/a(431)→基+32 变体+64 — 四组同槽别名 = 同一 reader 模板服务向量与颜色两类宿主; 其他键落基 reader。

SForceReader (≥152B):

| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | i32 | type (225) | 力型枚举 (下表); 非法 → "Unknown force type: \<名\>" |
| +12 | char[256] | name (27) | null@+75 |
| +76 | 2×f32 | position (76) | 位置 XY (sub_140ADDCA0 二元读) |
| +84 | f32 | position 第三分量槽 | 固定路径写入, 语义待裁 |
| +88 | 2×f32 | direction (77) | 方向 XY |
| +96 | f32 | direction 第三分量槽 | 同上 |
| +100 | f32 | yaw (413) | 偏航角 |
| +104 | i32 | division (471) | 细分数 |
| +108 | u8 | local_force (575) | 局部力旗 |
| +144 | 参数容器 | amount (417) | {base variation} 二元 + 列表形态 |

> 力型枚举 (token 225, 定案): planar=0 / point=1 / vortex=2 / friction=3 / turbulence=4 / spin=5。

未决: CAssetFactory +8/+16 精确类型与设置点 (推定 动画库句柄/资产名串, 尾调失真) / SEntityReader +1152/+1200/+1248 三未决容器 / SMeshData 六串语义与 +212 / 参数槽 '@' 引用语法 / 灯登记九容器→串转换 / SEntityReader 收尾器 sub_1423529A0 / SForceReader 非法力型输出通道 / 444·454 与 450·475 两组同槽别名键命名意图 (新旧脚本键并存?).


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

#### 4.35.24 FX 粒子系统定义 writer (gfx/FX/particle.lua 导出半边)

FX 粒子系统定义 writer = sub_142344F20 (2739 行; 与粒子定义解析件 sub_142296A40 成对): 键 = name(27) / max_amount(409) / sort(426, 枚举串 depth|distance|age) / emitter_type(481 "sphere") / sphere_emitter_radius(482, 块) / slave_particles(608); 发射原语计数 279× 串 sub_1424C2AD0 + 76× sub_1424C3900 + 4× 块 sub_1424C4220。

#### 4.35.25 战略地图图形域带锚 (0x14165 区 / orderstools 带)

- **0x14165 区 = 战略地图图形域** (负定案: 与焦点树无关 — CNationalFocusTree 运行期域在 0x1402C-0x1402D, GUI 在 0x14138, 均已入书): gfx_supply.cpp ~50 函 (补给图形发射器 sub_14165DA50 "Path._Found" / sub_14165B4D0; 分档 sub_14165D050 消费 §4.30 阈值) + cities.cpp ~24 函 + maparrow.h 6 函 + CCitySettings reader 族; 总控 = sub_14165FB20 (§4.28 延迟子系统表)。
- **0x140F4 带 = orderstools.cpp 前线绘制/军令工具域** (105 函, 87 函未单独入名): 油漆工具 sub_140F4E9E0 / 军令 tooltip sub_140F454A0 (§4.35 S16a 军队表已名) / §4.33 十余命令的玩家 UI 通道; 邻带 0x140EF = theatre.cpp 战区运行期域 (§4.24 reader 所在), 0x14103 = orderinstance.cpp 域 (§4.24.5)。

#### 4.35.26 渲染资源装载域 (pdxshaderparser / gfx_dds_loader / pdx_particle; 5 函闭环 — shader 编译链 / DDS 跳级切片 / 粒子注册表)

簇清册 (体内 cpp 锚 5/5; 5 函书内零 VA 覆盖, 全部本批新定性):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_142359D50 | 343 | pdxshaderparser.cpp :1289/:1295/:1303 | shader 程序编译驱动 (查库→查入口→查三状态布局表→拼 defines→BuildVS/BuildPS/Link) |
| sub_14235A750 | 223 | 同 CU :794 | shader include 图 DFS 后序展平 (防环 + 拓扑序收集) |
| sub_142424F90 | 438 | gfx_dds_loader.cpp :118/:325/:328 | DDS 头解析 + mip 切片表构建 (**base-mip 跳级**) |
| sub_1423FC680 | 523 | pdx_particle.cpp :1608 | 粒子系统类型注册表 create-or-reuse + 三向量重填充 |
| sub_1423F4250 | 408 | 同 CU :1569 | 修饰符记录递归构建器 (2296B 运行时记录 ← 1352B 链节点) |

**shader 编译驱动** (sub_142359D50; 签名 (ctx, file*, entry*, a4, out*, defines 数组)): 调用链 = CGraphics ctor sub_142235600 (§4.35.3) → sub_142409480(+1336, sub_142359440, 本函) 编译回调注册 (成对回调, sub_142359440 = 装载侧待裁)。流程: sub_14235AC70 shader 库哈希表按名查 bank (FNV-1a, 全局表 qword_1435B9C88/98/B0) → *(bank+504) 空 = sub_142359530 懒建解析表示 → 按 entry 名在 216B 条目表查行 → 三张布局表逐表查行覆写默认值 → 拼 defines 行向量 (a6 数组 + 条目 +192 strview 片段) → 设备 ABI 表 (表基 0x1430BF7B0, §4.35.5 互证) 槽 26 BuildVS sub_142420F50 / 槽 29 BuildPS sub_142420E40 / 槽 30 Link sub_1424237F0 三连 (GL 槽语义 §4.35.16d 互证全符); 失败各走格式化错误日志 :1289 "Failed adding vertex shader" / :1295 "Failed adding pixel shader" / :1303 "Failed linking shader" (无中断)。

bank 解析表示对象布局:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +384 | 指针 | 条目表 data (216B/条 = 着色器入口表) |
| +396 | int32 | 入口条目数 |
| +408 | 指针 | 条目表 data (72B/条 = 顶点侧状态/布局表) |
| +420 | int32 | 条目数 |
| +432 | 指针 | 条目表 data (80B/条 = 第二状态表) |
| +444 | int32 | 条目数 |
| +456 | 指针 | 条目表 data (64B/条 = 第三状态表) |
| +468 | int32 | 条目数 |
| +504 | 指针 | 解析表示懒建指针 (bank 侧, sub_142359530 建) |

入口条目 216B = 6 × std::string (+0 名〔查找键〕/+32/+64/+96/+128/+160) + strview {ptr@+192, len@+204} (拼 defines, +208..+216 待裁)。out 对象 = {+0 程序对象 (空则槽 24 工厂建), +8/+16/+24 三状态组 (构造槽 49/51/55 / 销毁槽 50/52/56 — 槽 51/55 即 §4.35.3 设备状态对象工厂互证)}; a4 非 0 调槽 27 sub_142420910。

**include 展平** (sub_14235A750; (bank, out 向量*, visited 向量*) 递归): bank+480 = include 名表 (32B 串数组, +492 计数), 逐条拼 "gfx/FX/" 前缀; visited 查重后**先递归后追加** = 后序展平 (被包含者先于包含者); 查名失败 :794 "Shader include file '%s' not loaded"。返回 = 处理条目数。

**DDS 装载** (sub_142424F90; (out*, buf, size, params*, filename*)): 调用链 = 纹理装载分发器 sub_14240E9B0 (§4.35.7 S1 CU) → 魔数门 sub_142424F70 ("DDS ") → 本函; 失败且 .tga → sub_142425900 TGA 分支。头消费: +12/+16 高宽 → out+4/+0; +80 ddspf.flags (0x4 = FOURCC 门, 0x40 = RGB, 掩码族 0x20240); +84 fourCC 分派 (DXT1=1/DXT3=3/DXT5=5 内部格式; **DXT2/DXT4 不支持返 0**; DX10 → 像素数据起点 +148); +88 bpp 类 + +92..+104 位掩码细分 (565=7/4444=8/1555=9/24bpp=11/32bpp=13/其余=26); 不可识别 = 断言 :118 "Unknown texture format" (B52 门, 闩 byte_1435DD583); +112 dwCaps2 bit 0x200 = cubemap ×6 面。

**base-mip 跳级机制 (核心新发现)**: v22 = min(头+28, params+4) = 跳过级数 (头 +28 字段语义待 PE 对真实 .dds 实证 — 标准 DDS 该位为保留) — 预循环按块压缩 (DXT 系 blockbytes×((w+3)/4)×((h+3)/4), 块字节 8/16) / 未压缩 bpp×w×h 累加被跳 mip 字节入偏移基准, 宽高逐级减半; **跳完后首级宽高才写 out+0/+4 (out 尺寸 ≠ 文件首 mip 尺寸)**, out+8 = 剩余级数。切片表条目 32B: {+0 mip 级 (重编后), +4 面号, +8 高, +12 宽, +16 字节大小, +24 数据偏移}; 越界门破防 = :325 CLogStream 一行式 + :328 断言同文案 (闩 byte_1435DD584)。

**粒子类型注册表** (sub_1423FC680; registry: +32 条目指针向量 data, +44 count, +56 曲线采样数水位): 条目 208B = {+0 char[64] 系统名, +64 char[64] 来源文件名, +128 u32 名 FNV-1a, +136 向量 276B/条 (发射源 B, count = a8), +160 向量 2296B/条 (修饰符, count = a4), +184 向量 120B/条 (发射源 A, count = a6)}。同名命中即复用 (清计数 + resize + 清修饰符组) **再发重名警告** :1608 "Particle name is not unique" (CLogStream; 静音旗 byte_1435DA850 置位时静默 — 解析驱动以 sub_1423FE0E0(1)/(0) 包裹); 新建 = malloc 208。

**修饰符记录递归构建器** (sub_1423F4250; 2296B 记录): +0..+1512 = 21 × 72B 曲线 (sub_142505AF0 逐槽; 源映射 0←0/1←32/…/20←672, 槽 9/10/11 三处乱序照录); +1512..+1872 = 5 × 72B 可选曲线 (源缺失用缺省曲线回退, 缺省 = 栈上单点键 {t=0,v=1.0}/{t=0,v=200.0}); +1872 ← node+992 采样数 (同步抬 registry+56 水位); +1876..+2208 = 332B 整块拷贝; +2208 = 力目标向量 (8B/条 = 120B 发射记录指针); +2248 = 力子对象 (216B: 3 曲线 + 6 串); +2256/+2264 = 力公共函数 sub_1423F17B0 / 按型更新函数 (型 1 = sub_1423FBD50, 型 2 = sub_1423F1790); +2272 = 子修饰符向量 (2304B/条, 递归 node+1344 链, next@+1352)。力绑定: node+960 = 68B/条力名目表 (型 dword == 1 才处理), 逐名查名串向量, 命中 → 父条目+184 向量 + 120×idx 入力目标向量; 未命中 → :1569 "Couldn't find particle force" 报错。

互证: 设备 ABI 表基 0x1430BF7B0/92 槽 (§4.35.5)、槽 26/29/30 与 BuildVS/PS/Link VA (§4.35.16d)、槽 51/55 状态工厂 (§4.35.3)、B51/B52 断言门族、§4.35.24 FX writer 与 §4.35.17 粒子定义解析件 sub_142296A40 为同带邻件 (非本批 VA)。

未决: DDS 头 +28 跳级数挪用实证 (PE 对真实文件) / params 完整形状 / shader 表示尾 8B 与槽 27 行为 / 库哈希表宿主与静音旗写入方全图 / 276B 记录 sub_1425056F0 落点 (= §4.35.32 变值动画记录族, 方向键 @记录+12) / 修饰符源节点与解析件对接字段全表。

#### 4.35.27 贸易路线 GFX 域 (gfxtraderoute.cpp; 2 函闭环 — tooltip 组装 / 补给转运谓词)

簇清册 (体内 cpp 锚 2/2; 书内原空白域):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_1412DD420 | 577 | gfxtraderoute.cpp:1843 + gamestate.h:1125/1126 | 贸易路线 tooltip 文本组装器 |
| sub_1412DE0A0 | 28 | 同 CU :844 ("_eType == GFX_TRADE_TYPE_SUPPLIES_TRANSFER") | 补给转运谓词 |

**tooltip 组装器** (sub_1412DD420): 前置 = 单例 qword_14332F698 vtable[16] 返回对象 (情报视图宿主, 类名未决) **+1784 = CGfxTradeRoute 全局槽**; 三数据槽 = 宿主+16 (恒取) / +560 (门 byte@+1784 ∧ byte@+1648) / +1104 (门 byte@+1649)。可见性谓词对 sub_141436080/1414366E0 (gs+1312/1316 上下文), 行级门失败 → 行文本 = 本地化 "NO_INTEL"。三重环 = 3 情报槽 × 8 组 (24B 容器) × 组内条目, 条目 +16 对象经 sub_141268FE0 匹配。类型切换插头 (条目 +32 类型, 变化才插): 0 = TRADE_ROUTE_CONVOY_PRODUCTION_HEADER / 1 = …_SUPPLIES_HEADER / 2 = …_EXPORT_HEADER / 3 = …_IMPORT_HEADER (本地化 + "
" 前缀); 4..7 静默; default 断言 :1843 "Unexpected trade transfer type" (severity 0)。行去重 sub_1424CBB60 (== −1 才追加); 行文本生成器 = sub_1412DB650。调用者 = 三个 UI 文本组装大函数 (0x140E0D390 tooltip 一支 / 0x140E05340 情报兜底链 / 0x140E10000 布尔合成)。

**补给转运谓词** (sub_1412DE0A0): a1+32 == 1 ∧ u64@+44 ≠ 0 ∧ token 解析 sub_14221F310 ≠ 0 ∧ *(int*)(def+44) > 0; a1 空 → false。无直调 — 唯一引用 = 0x1412D9B10 内 sub_14126C800(v16, 本函, v3) 回调注册 (type==1 对象构建期挂谓词、渲染期回调; 注册点邻域 obj+380 = 1065353216 = 1.0f 位型)。

未决: 情报视图宿主类名 / dword_143334180 (匹配 define, 不在 defines 表) / 行文本生成器 sub_1412DB650 未展开。

#### 4.35.28 纹理装载运行期 (gfx_texture_cache / texturehandler; 8 函闭环 — 装载核/装载链/72B 记录/重载)

簇清册 (体内 cpp 锚 8/8; 除互证外全部本批新定性):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_14241F900 | 392 | gfx_texture_cache.cpp :67/:68 | 命名纹理装载核 (.tga→.dds 换名优先 → 读文件 → 解码 → 建纹理; **无 MAX_TEXTURE_SIZE 门**) |
| sub_14241F8A0 | — | 邻址件 | 条目重载包装 (全局锁 0x1430BFCC8 + 槽 65 前奏 + 重载核) |
| sub_1424063A0 | 91 | texturehandler.cpp :17/:18 | CTextureData::ClearData() 无参版 (+52 = −1) |
| sub_142406C40 | 80 | 同上 | CTextureData::ClearData(int) 实参版 |
| sub_142407CB0 | 137 | :232/:233 | 装载执行件 (16MB 门 → 解码 → 槽 60 建纹理 → 可选 alpha 掩码抽取) |
| sub_142407F50 | 140 | :216/:217 | LoadTexture 包装 (解析路径 → 装载执行 → 释放文件对象) |
| sub_142408280 | 363 | :160/:166 | 三级扩展名解析 (stem.dds → stem.tga → 原名) |
| sub_142408B20 | 171 | :656 | ReloadTexture (全局锁 0x1430BFA90 + 槽 65 前奏 + 槽 61 向既有句柄传像素) |

**CTextureData 布局** (ClearData 双版初始化面, ≥72B 定案): +0 设备纹理句柄 (非空清除路径 = **槽 64 单参释放** — §4.35.5 槽 64 语义放宽直证) / +8 std::string 纹理名 (SSO, cap@+32 = 15) / +40 u64 清零 (待裁) / +48 u32 / +52 int (无参版 = −1, 实参版 = 实参, 槽位/类型 id 推定) / +56..+68 五标量 (1/0/0/1/0)。错误双版同构: +0 非空 → ①断言 :17 "Texture handle should be NULL…" (B51, 闩 byte_1435DA8AC) → ③:18 同义 (4096) → 照常释放清场。

**72B 纹理记录** (Dump 遍历 + 调用方 +72×idx+60 取参互证; 定案):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | u64 | 设备纹理句柄 (null = 未装载) |
| +8 | std::string (24B) | 纹理名 |
| +40 | uint32 | 宽 |
| +44 | uint32 | 高 |
| +48 | uint32 | 引用计数 |
| +56 | uint8 | 已装载旗 (Dump ERROR 判据) |
| +60 | {int@60, u8@64, u8@65} | 装载参数 (ReloadTexture 第三实参直取; 解码分发 params 源) |

**CTextureHandler 布局增补**: +8 记录数组 data (72B/条) / +20 记录数 / +56 纹理总数 / +104 设备对象指针 (ABI 第 1 实参, §4.35.3 互证) / +112 文件缓冲。挂点 +368 双点互证 ✓书。

**装载链**: 0x142408280 (name, report_flag) → `\`→`/` 归一 → rfind('.') 无扩展名 → ①:166 "No file ending" (B51); 依次 stem.dds/stem.tga/原名 三路 malloc 56 文件对象 + sub_1424DF570; 全败且 report → ②:160 "Texture Handler encountered missing texture file"。0x142407F50 包装: 命中 → 装载执行 → 释放; 未中且 params+4 旗 → ③双连 :216/:217 → 返 0。0x142407CB0 执行件: 文件长 > 16MB → ①:232 + ②:233 "Failed to load texture larger than MAX_TEXTURE_SIZE" (B51, 闩 byte_1435DA8AE) → 返 0; 读入 TLS 守卫区 → params 折叠 → sub_14240E9B0 (§4.35.26 分发器) 解码 → GL 状态对包裹 → **槽 60** 建句柄; out_mask 非空且解码格式 == 13 (32bpp, §4.35.26 DDS 表互证) → 逐像素 alpha 掩码抽取 (w×h 字节)。

**ReloadTexture** (sub_142408B20; (this, 记录下标, params)): 全局互斥锁 0x1430BFA90 (紧跟 ABI 表尾) → 记录门 = 引用计数 > 0 且句柄非空 → **槽 65 覆写前奏** (无可见实参) → 解析 → 文件长 ≥ 16MB **静默返 false** (与执行件有门对照) → 读入 +112 → 解码 → **槽 61 (设备, 既有句柄, 解码件, data, size) 像素上传** (§4.35.5 槽 61 语义改定直证) → 返句柄非空; 解析失败 → ③:656 "Missing texture file"。DumpTextureInfo (sub_142408810): 逐记录 (引用计数>0 且已装载) 输出句柄/名/refcount/宽高, 控制台回显包裹对; 调用方之一 = console 侧 dump 命令路径 (*(qword_14332F698+1264)+368)。

**gfx_texture_cache 装载核** (sub_14241F900; (name, flag)): .tga 结尾 → 换 .dds 探测存在 (存在用 .dds, 否则回退 .tga, 高置信) → 打开 → 读全长 → sub_14240E9B0 解码 → **槽 7** 无参取设备 → **槽 60** 建句柄; 失败 → ③双连 :67 (4096) + :68 (0x2000) "Couldn't find texture"。相邻件 sub_14241F8A0 = 条目重载包装: 全局锁 0x1430BFCC8 → 槽 65 → 重载核 (条目形状 {GPU 句柄@+24, 名串@+32, u8 旗@+64} 推定) — 与 ReloadTexture 同构 (同一槽 65 前奏 + 全局锁 + 重载核)。

全局对象认领: 0x1430BFA90 = texturehandler 全局互斥锁 / 0x1430BFCC8 = gfx_texture_cache 全局互斥锁 (均紧跟设备 ABI 表区)。ABI 槽 42 (DestroyBuffer v2 ✓书) 经 GB 索引释放再证; 槽 45/65/89 书已有认领 (AllocConstantArray/ReleaseRenderTarget 后端释放/Set16B 属性 v2), 本批调用形态互证存疑处见未决。

未决: 条目重载包装上游 / CTextureData +40/+48 与记录 +60 params 的脚本侧键名 / 槽 45/65/89 语义 / 0x142407F50 两调用点宿主。

#### 4.35.29 CPdxMap 图形装载编排 (pdxmap.cpp; 2 函闭环 — LOAD_GFX 五进度事件 / 河流·省界·树通道 / 索引缓冲)

簇清册 (体内 cpp 锚 2/2; §4.35.2 原仅点名同 CU 地形/对象通道):

| 函数 | 行数 | 体内锚 | 定性 |
|---|---|---|---|
| sub_14127C980 | 597 | pdxmap.cpp :2886/:2980 + 嵌串 :3274/:3373 | 装载编排主件 (五进度事件 + GB 纹理 + 三通道 + 索引缓冲重建) |
| sub_14127BAB0 | 24 | :363 (串内自称 CPdxMap::GetProvinceRiverPoints) | 省河流点访问器 (越界哨兵回退) |

**GetProvinceRiverPoints** (sub_14127BAB0): 门 0 ≤ 省 id < *(this+23436) → 返 *(this+23424) + 24×id (24B/省条目); 越界 → ①:363 "Invalid ProvinceID sent to CPdxMap::GetProvinceRiverPoints…" (B51, 闩 byte_14333DED8) → 返静态哨兵 qword_14333DEB8。+23424/+23436 与主件河流构建输出 (sub_141B24A10 第四实参) 互证 ✓。

**装载编排主件** (sub_14127C980; a1+16 装载中旗门控全部进度事件, 结尾清零): ①:2886 "_GBTexture == nullptr" 重入门 (B52, 闩 byte_14333DF25) → sub_14166EC40(单例 qword_143339D28, 设备) → malloc 192 清零建 GB 纹理对象存 +23752 → **槽 89** (栈传 {0, 0x1000000, 1}, 书认领 Set16B 属性 v2 之别例待裁) → +17 清零 → 分块级数 +23744 (≤4; 宽/64 与高/64 对 16/8/4 试除取小) → **进度事件五连** (LOAD_GFX_PDXMAP_RIVERS (0x130000) → _TERRAIN (|=0xC00) → _BORDERS (|=0xC000) → _TEXTURES (|=0x3000) → _TREES (|=0xC0000, 门 byte_1430869D6) → 收尾 LOAD_GFX; sub_140B70B30 发射, 权重位掩码累进) → 通道构建:

| 通道 | 调用与存储 |
|---|---|
| 河流 | sub_141B24A10(设备, +23376, +23368, +23424) → 顶点数 |
| 地形 | sub_141278ED0 / sub_1412784E0 (§4.35.2 表行邻域) |
| 省界 | sub_141B204A0(上下文, +18848, +18872, +18920, 256, +17 ? −1 : 0x10000) (§4.35.7 S3 互证) |
| 树 | sub_141B26810(设备, +21296) (16B/条, +21308 条目数, +10 u8 类型序); 树类型名 = "mapobject_" 拼类型名 → sub_142238C00 → 存 +19256+8×类型序; 失败 → ③:2980 (flag 65543) |
| 顶点缓冲 | +296 空则 **槽 35** CreateVertexBuffer (调试串 pdxmap.cpp:3373 — §4.35.16③ 第 6 参新实例互证); +304 空则 **槽 45** (产物存 +304) |
| 索引缓冲 | +17 门: 旧 +23712 经 **槽 42** 释放 → u16 索引 6×(n−1) 条 (条带模式) → **槽 41** CreateIndexBuffer (调试串 :3274) → 存 +23712; else 支 sub_141278AD0 |

尾 = sub_14125D530(上下文, +23448) → LOAD_GFX 收尾 → +16 清零 → CMapModeDispatcher 族收尾。唯一调用方 = sub_140B4F9C0 (传 mgr+88 的 CPdxMap)。

**CPdxMap 装载域偏移群**: +8 渲染上下文 (后端设备 = *(ctx+128)) / +16 装载中旗 / +17 索引缓冲自建门 / +176/+200 物件层与箭头层 (推定) / +296 顶点缓冲 / +304 槽 45 产物 (待裁) / +18792..+18920 边界与省界三输出 / +19256 每树类型图形表 / +21296/+21308 树层容器与计数 / +23368/+23376 河流输出对 / +23424/+23436 河流点 data/count (24B/省) / +23448 输出层 (推定) / +23712 GB 索引缓冲 / +23744 分块级数 / +23752 GB 纹理指针。

未决: +17 位语义 / +304 槽 45 产物 / GB 纹理 192B 全形 / 单例 qword_143339D28 +64/+68 宽高 (推定) / 24B 省河流条目内部形状 / 槽 89 本调用形态。

#### 4.35.30 地图情报覆盖贴图 (map_graphics\intel.cpp; 2 函闭环 — 逐省 u8 六源填充 / 每帧失效驱动)

> 路径锚定目录 = source\map_graphics\ (渲染面, 非游戏逻辑侧 intel 域)。

簇清册 (体内 cpp 锚 2/2; 全新):

| 函数 | 行数 | 锚 | 定性 |
|---|---|---|---|
| sub_141618890 | 283 | :291 断言 "no location for unit wat??" (B51, 闩 byte_14338A9BA) | 覆盖贴图填充器 (六源) |
| sub_1416193A0 | 165 | :200 断言 "Invalid country for volunteer" (B52, 闩 byte_14338A9B9) | 每帧更新驱动 (失效检测 + 逐国补充) |

**状态对象**: +0 当前帧缓冲 / +8 上一帧 / +16 字节尺寸 (省数) / +20 观察者 tag 缓存 / +24 需重建门 / +25 本帧变更旗 / +26 强制旗 / +27 byte_14332F63A 旗缓存 (变化即重建)。缓冲 = **逐省 u8 覆盖值**: 0xFF = 直接可见; 150/250 = 邻接/单位扩散; 敌控州按情报梯度累加。写原语 sub_141618720 = **is_land 门** (省+184 描述符 +210 bit0) + clamp(旧+值, 0, 255) 累加; 邻接刷 sub_141619160 = +112/+124 邻表扩散。

**六源填充** (sub_141618890): ① cc+1064 属省全 0xFF + 刷 150; ② (含盟友旗) cc+360 theatres (**CTheatre+272 = 属主 tag**, 两函四处一致 — s4_24 域可收) theatre+24 元素 +48 省数组; ③ gs+5160 u32 tag 列表 (推定盟友/阵营成员, 写者未查) 逐国属省全 0xFF; ④ cc+1144 owned states 中控制国 ≠ 己 → sub_1409D8F90(州, 出, tag, 75, …) × 情报查询 → 逐省梯度累加; ⑤ cc+656 师容器 → 单位 +496 所在省 0xFF + 刷 250; ⑥ cc+632 特混舰队 → tf+184 舰 +496 刷 250; + cc+4384 容器省 id 数组同梯度。

**每帧驱动** (sub_1416193A0): 失效检测 = gs+1312/1316 玩家 tag (双槽回退) 对比缓存 + byte_14332F63A 变化; 重建 = memcpy(prev←cur) → memset(cur) → 填充(观察国); 逐国补充: sub_140702780 真 → 填充(国); 否则 sub_1406F9DE0 = 「他国境内指挥国为观察者的 theatre」查找 (**志愿军/远征 theatre**) → 遍历 theatre+104 单位: +496 省刷 250 (+480 属主 == 观察者或同原初; 不符 → :200 断言)。收尾 memcmp 判 +25 变更旗。

未决: gs+5160 写者 / sub_1409D8F90 量纲与 75 常量 / dword_14333421C define 名 / 渲染消费端 / byte_14332F63A 写者与常态值。

#### 4.35.31 图形地图运行期 (graphicalmap.cpp; 8 函闭环 — 点击拾取 / 类型分派 / CreateProvinces / CGfxNavalCombatManager 新类)

簇清册 (体内 cpp 锚 8/8):

| 函数 | 行数 | 锚 | 定性 | 状态 |
|---|---|---|---|---|
| sub_140B54210 | 398 | :1036 断言 "Implement selection test" (B52) + gamestate.h 四断言 | 地图点击单位拾取 (三拾取集 + 省 id 纹理 + 同省叠队环形轮选) | 互证, 本体新定性 |
| sub_140B54930 | 178 | :1127 断言 "Unsupported type of selectable" (B51) | 可选对象类型分派器 | 新 |
| sub_140B54F20 | 165 | :1186 断言 (B51) | 按类型收集单位 (类型 0/1/13 → gs+1600 全单位数组过滤) | 新 |
| sub_140B52620 | 120 | :2447 "Fatal error while creating provinces!" (65540) | CreateProvinces (运行时省对象 5992B×N; 进度组 17) | 新 |
| sub_140B52130 | 71 | :3732 断言 (B52) | 突袭 GFX 清理+懒取复合 | 互证并档 (孪生 getter sub_140B558C0 = 纯懒取) |
| sub_140B55620 | 24 | :3803 "Failed to initialize CGfxNavalCombatManager" (4096) | **CGfxNavalCombatManager 懒建 (新类登记: 408B; ctor sub_140B4F770 / init sub_141664850 / 清理 sub_141662150)** | 新 |
| sub_142606650 | 14 | 同 :2447 | 建省失败 rethrow funclet (EH landing pad 引用) | 新 |

**CGraphicalMap 布局增补**: +24 进度事件宿主 / **+40 CMap 单例指针** (+560 省表界 / +2096 省 id 纹理) / **+104..+116 运行时省对象数组 (5992B/元, CreateProvinces 产物)** / +120 分配器 / +1744 CMapArrowManager / **+1800 突袭 GFX 管理器 (56B)** / **+1824 CGfxNavalCombatManager** / +1848 实体条目数组。

**点击拾取** (sub_140B54210): 三拾取集 = gs+16 / gs+560 / gs+1104 (门旗 gs+1784 ∧ +1648 / +1649; 语义推定陆军/海军/其他); 选中集类型 ∈ {≤1, 13} 环形轮选 (gs+1600 数组); 未中单位 → 反投影 → **CMap+2096 省 id 纹理 {宽@+48, 高@+52, u16@+24} 取省 id (0 = miss)**; 地图模式 ∈ {2, 3, 39} 直返省+200 产物; gs 省查询重入门 _InterlockedIncrement/Decrement ≤ 2 (gamestate.h:1140/:1146 断言)。

**类型分派表** (sub_140B54930): 0/1/13 → 收集器 / 4 → 邻函 / 5 → magic static 收集+去重+静态后处理 / 7/8 → 空操作 / 9 → gmap+1264 数组 / default 断言。

**CreateProvinces** (sub_140B52620): CREATING_PROVINCE 进度事件 → 按省表界扩数组 → 逐省 (CMap+616 静态描述符) malloc 5992 + ctor sub_14128A420 → 入数组; catch → :2447 后 rethrow (funclet sub_142606650)。**运行时省对象**: +164 省 id / +184 静态描述符回指 / +200 → 对象+88 (= desc+88 战略区模板 id, §4.25.9) / +224/+248 驻扎单位与特混数组。

**归属改判 (定案)**: sub_141662150「三池析构」唯一调用点在 sub_140B52130 内且被 +1824 门守卫 → **归属 = CGfxNavalCombatManager 元素清理** (§4.35 S7 两处已改判; 箭头管理器自身析构函另寻)。

未决: 温度校验虚槽 (§4.25.9) / 类型 4/5 分派细节 / 三拾取集类属 / 省+224 与 +248 两数组对象级归属 / 特混类型枚举全景。

#### 4.35.32 变值曲线层 (variedvalue.cpp; 求值核 0x142504C50 / 动画名解析器 0x142502FE0 两函闭环; pdx_core 通用数学层, 粒子/动画共用)

曲线描述符 (推定类名 CVariantValue/CVariedCurve, RTTI 未直证):

| 偏移 | 类型 | 语义 | 证据档 |
|---|---|---|---|
| +0 | float | 曲线定义域下界 min | 定案 |
| +4 | float | 曲线定义域上界 max (亦 fmodf 包裹模数) | 定案 |
| +8 | int32 | 模式枚举: 0 = 加 / 1 = 乘 / 2 = 替换; 其他 → 断言 | 定案 |
| +12 | int32 | 曲线类型枚举; {2,3} 配合 +272 旗触发 fmodf 包裹 | 高置信 (枚举实名待裁) |
| +16..+267 | float[64] | 64 点分段线性曲线 (采样点 y 值; 索引 i 点在 +16+4i) | 定案 |
| +268 | float | 上界钳位值 (= 第 63 点, t ≥ 63 时取此处) | 定案 |
| +272 | u8 | 包裹旗 (置位且类型 ∈ {2,3} → 输入先 fmodf(value, max)) | 定案 |

施加项数组元 (求值核第四参数组, stride 32):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | 曲线描述符* | 本项的曲线/模式描述 |
| +8 | float* | 本项输入值数组 |
| +16 | float* | 可选除数数组 (空指针 = 无除法) |
| +24 | int32 | 输入/除数数组跨距 |

求值核两相位 (sub_142504C50; src int 数组 / 施加项数组 / dst float 数组):

| 相位 | 行为 |
|---|---|
| 1 基值拷贝 | 无施加项, 或首项模式为加/乘 → src 逐元素按位拷到 dst (4 路循环展开)。与相位 2 **不互斥**: 加/乘需要基值, 替换模式跳过拷贝 |
| 2 施加 | 逐施加项: 可选除数 (替换模式额外判除数非零防除零) → 可选包裹 (fmodf) → 归一化插值 `t = (value−min)×64/(max−min)` (t<0 → 首点; t≥63 → 末点; 否则分段线性 lerp) → 合并 (加/乘/替换) |

> 曲线语义 = 64 点分段线性映射: 输入经 (可选除数 → 可选包裹) 预处理后映射到 [min, max] 的 64 段等分网格, 端点外钳位; 三模式把映射结果叠加/相乘/覆写到目标数组。

动画名解析器 (sub_142502FE0; 标量输出 float* / 记录指针向量 / 通道条目数组 / 动画名表 / 记录数组句柄 / 方向旗):

| 对象 | 布局 | 语义 | 证据档 |
|---|---|---|---|
| 通道条目 | stride 68 = {通道 id int32@+0; 名 char[64]@+4}; id==0 = 标量通道 | 逐通道描述 | 推定 (68 = 4+64) |
| 动画名表 | pdx 向量 {data@+0, 计数@+12}; 元 stride 32 = MSVC SSO 串 (size@+16, cap@+24) | 已注册动画名集合 | 定案 |
| 记录数组 | 276B 元, 索引 = 名表内位置; 匹配地址 = 基址 + 276×索引 | 每名一条动画记录 | 定案 (与 §4.35.26 粒子注册表 276B 条目同跨距, 互证同记录族) |
| 记录内 +12 | int32 | 方向选择键 (方向旗非 0 → 仅取该键非 0 记录; 为 0 → 仅取该键为 0 记录) | 高置信 (键实名待裁) |

解析流程: 逐通道 — id==0 标量通道 → 写浮点回退 + 置返回位 0; id!=0 → 名在名表内 strlen+memcmp 匹配, 命中读记录方向键按方向旗筛选, 通过则记录地址追加进向量 + 置返回位 1; 未命中 → :504 一次性断言 + :505 CLogStream 错误日志「Couldn't find animation "<名>"」(通道 4096)。返回值 = 位掩码 (bit0 = 标量回退已写, bit1 = 动画记录已入向量)。
