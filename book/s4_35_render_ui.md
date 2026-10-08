### 4.35 渲染/UI 体系

> 渲染与界面域定案落账。§4.35.13 = 域内 269 件按 16 子系统的函数地图;
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

截图合成件 sub_140B411B0 = BeginFrame + 装载屏轮换 sub_140B40BD0 + 横幅纹理盖印 (形参序 = (gfx, 文本串&, a3 合成门旗, a4 轮换门旗); a3 门控 BeginFrame 族操作, a4 门控装载屏轮换 sub_140B40BD0; 装载屏初始化期文本实参恒为空串临时量, §4.35.63)
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
| 64 ★ | ★ 按句柄销毁 (RT/纹理共用句柄空间; CTextureData 默认构造器 0x1424063A0 (入口全字段初始化 + 串 SSO cap 15@+32 + 串析构 unwind + 向量增长路 realloc 后 placement 调用 2 处; 其 if 紧跟置 0 之后 = 内联 ClearData 体的死分支残留) 与 ClearData(int) 0x142406C40 (+52 = 实参) 两版共用句柄单参释放; 旧记「DestroyRenderTarget 包装」系归属偏窄, 旧记「双版 ClearData」系把构造器误标为无参清除) | 97 |
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
wglCreateContext/wglMakeCurrent)。GL 扩展装载双件 = sub_142438B50 (**= GLEW glewContextInit, 静态链**, 5,472 行; 返回码 {0 OK, 1 NO_GL_VERSION, 2 GL_VERSION_10_ONLY}; 顶旗 GL 4.2 -> GLEW 1.7.0/1.8.0 窗口, 见 4.35.44) +
sub_142441940 (WGL 枚举 3,665 行)。图形设置装载 = sub_14241A230 ("Loading settings for
adapter")。纹理类型枚举 (载体 sub_14240CFD0): "2d"=0 / "shadow"=0 (别名, shadow map 按二维纹理处理) /
"cube"=1 / "3d"=2 (gfx_helper.cpp:142)。SDL2-2.0.20 静态链 = 窗口/软光栅底座。

**pdx_gfx 串→枚举查表器族 (gfx_helper.cpp, 9 函同构定案)**: 骨架 = `(const char* name, int* out) -> int` stricmp 查 16B 名值对表 {名指针, int 值}, 命中写 *out 并返值; 全未中组错误串抛异常 (terminate 兜底); 全部 0 基自定义枚举 — comparison/stencil/address 三表值序与 D3D11 同名枚举同序整体 −1 (fill/cull 同理, D3D9 CULL_NONE=1 → 此 0), **.gfx/材质脚本侧这些 token 的数值落点由此族唯一锁定**:

| 函 | 源行 | 枚举表 (名=值) |
|---|---|---|
| sub_14240CE80 | :98 | 采样地址: wrap=0 / mirror=1 / clamp=2 / border=3 / mirror_once=4 |
| sub_14240CBA0 | :120 | 纹理过滤: none=0 / point=1 / linear=2 / anisotropic=3 |
| sub_14240CFD0 | :142 | 纹理类型: 2d=0 / shadow=0 (别名) / cube=1 / 3d=2 (见上行) |
| sub_14240C520 | :197 | 混合操作: blend_op_add=0 / _subtract=1 / _rev_subtract=2 / _min=3 / _max=4 |
| sub_14240C980 | :250 | 深度写: depth_write_zero=0 / depth_write_all=1 |
| sub_14240CCE0 | :271 | 模板操作: stencil_op_keep=0 / _zero=1 / _replace=2 / _incr_sat=3 / _decr_sat=4 / _invert=5 / _incr=6 / _decr=7 |
| sub_14240C670 | :296 | 比较函数: comparison_never=0 / _less=1 / _equal=2 / _less_equal=3 / _greater=4 / _not_equal=5 / _greater_equal=6 / _always=7 |
| sub_14240CA90 | :315 | 填充模式: fill_wireframe=1 / fill_solid=2 (无 0 值条目) |
| sub_14240C810 | :334 | 剔除模式: cull_none=0 / cull_front=1 / cull_back=2 + 短名 none/front/back 双别名表 |

⚠ 多函错误串前缀错置 (CFD0/C520 用 "Invalid filter type: ", C980 用 depth stencil 串, C810 用 rasterizer fill mode 串) — 源码复制粘贴痕, 勿按错误串定函数语义; 9 函真名未决 (无 RTTI/名字符串锚, 工作名为拟名)。

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
| S7 | 地图箭头/前线几何 | maparrow 481+370 / raid_arrow 824 | sub_141244070; sub_1423F4C90 点集切分; sub_141039F80 寻路 manager ctor sub_14126E990 / LoadDefinitions sub_141272920 (gfx/maparrows/maparrows.txt, lua 解析器 sub_141272F00) / 订单箭头装配 sub_141254FB0 (三静态色源 + 地图模式 39 分支) / per-frame sub_14124F710 / (⚠ 三池析构 sub_141662150 归属已改判 CGfxNavalCombatManager 清理 — §4.35.31, 非箭头管理器自身析构) / **军令线总入口 sub_141258D30 链 8 件**: 路径点追加 sub_1412664D0 (x 环绕钳位到 CMap+64 + 距离阈值细分插点 + 点数 ≥ 8192 清空重建) / 复位 sub_14126C390 / 提交 sub_14126C4E0 / 缎带重建 sub_14126C830 + sub_14126D680 / 地形贴合缎带 sub_14126AE10 / finalize sub_14126D480 / **省集合绑定器 sub_1412517B0** (把省集合绑到箭头/区域 — 军令线 ← 带状省数组 / df135 战略区 ← 省列表 / df33 fleet_area 同族; ⚠ 原 S11「定长缓冲三件」系误归, 已迁此) / 标签项查 sub_1412510F0 / 调试线 sub_1412542D0 |
| S8 | 相机/交互输入 | (0x140DB-DC / 0x14126 区) | CEU3Camera; sub_1412627C0 热键+位移 |
| S9 | GUI 框架核心 | containerwindow / buttonwrapper / gui.cpp | sub_1402A44A0 .gui 解析; sub_14225C690 事件分派 |
| S10 | 字体/文本渲染 | bitmapfont 2,102 | sub_14229C770 装载; sub_1422A1810 布局 |
| S11 | 文本引擎/本地化 | (0x14224 / 0x1411B 区; 0x1421E 区 = ImGui) | sub_1411B4B10 = STL num_get 浮点解析 (`_Parse_fp_with_locale` char 版, §4.35.62); ⚠ sub_1421EAA30 系 **ImGui::InputTextEx** (改判迁 §4.26, 原「文本流格式化」误归) |
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
- **每帧**: 泵 sub_140B58470 宿主 +1816 → **sub_14124F710 (箭头+弹道实体共享 per-frame)** → **gs+2617 会话门** (§4.1 该字段新消费点) → sub_141244070 (5,020 行重建主件; 时间节流门 qword_1430B2E18+上次时刻; 玩家国 gs+1680 视角); 动画时钟 = (gs+1212 速度级+1)×Δt, 暂停归零; 袭击箭头独立走宿主 +1792 → **sub_141668C10 = 地图单位覆盖层 per-frame 泵 (非箭头专属)**: 袭击箭头 + **deployed_general_base_plate 将领底板重建步 sub_14166ABC0** (LOD 门 = idler vtable+120→+32→f32@+1668 vs dword_1433333E0 超阈清空 + 情报门 sub_141618DC0 可见度 ≥250 最高档; 遍历链 = 国+360 theatres → theatre+128 orders_group → group+104 provider 两跳 vtable → 位置源 +496 → +184/+188) 等多步共享。
- **销毁**: sub_140B52130 = 突袭 GFX 清理+懒取复合 (含 :3732 断言); 三清理循环 = a1+104 数组 (计数 a1+116, 8B 步) 逐元省对象 (5992B/元) 清理 / a1+1848 数组 (计数 a1+1860, 16B 步取元 +8) 逐元 sub_14228D700 / a1+1824 非空 → sub_141662150; 清零 a1+1860 与 a1+304, 尾 a1+88 → sub_141278460 后懒建 56B 管理器 (ctor sub_14167D7F0(mgr, a1+1744 箭头管理器)); 其调用的 sub_141662150 三池析构 (实体句柄+SSO 串+双定长数组) **归属已改判 = CGfxNavalCombatManager 元素清理** (唯一调用点被 CGraphicalMap+1824 门守卫 — §4.35.31; 箭头管理器自身析构函另寻)。

**defines 全族** (NGraphics): ARROW×5 / RAID_ARROW×14 / RAILWAY_MAP_ARROW×15 / RIVER_SUPPLY+SUPPLY_CONSUMER×3, 含数据槽 dword_1433363BC (ARROW_MOVEMENT_SPEED)。主要未决: qword_1430B2E18 初值 / mgr+184 辅助数组语义。

**CMapArrowObject 布局直证补强** (maparrow.h:327 内联族, 高置信): **+88 = 纹理掩码列表宿主指针** (宿主 +40 数据 / +52 计数 = GetTextureMaskListSize() 来源) / **+516 = dword 纹理掩码索引 (0..5)**。箭头池 Acquire (sub_14165F290): 风格码映射 `1→1 / 3→2 / 其余 0`, a4 真再加 3 → 掩码索引; 池复用游标 @mgr+32 < 计数 @mgr+20 → 取 (+8 数组)[游标++] 直接复用, 否则经 sub_14126F380 新建后 1.5 倍增长推入; 写 +516 后 sub_14126C470 (起点=终点同置) / sub_14126C5C0 (位置) / sub_14126C510 (激活旗) 三 setter (逐字语义未决)。SetTextureMaskIndex (sub_1412576A0) = 断言 + 单写 +516。两函共享断言 "Index >= 0 && Index < GetTextureMaskListSize()" (闩 byte_14333DE3E)。

> **纹理列表 GPU 重建对 (0x141269880 / 0x14126C120; 布局定案, 功能身份推定)** —
> 两函同骨架 (推定 = CLostDeviceInterface::Restore / OnResetDevice 两版本): 共用管理器
> `mgr = *(*(a1+16) + 368)`; 对 mask 列表与 pattern 列表各一遍, 逐元素 (源跨距 32B)
> 经 sub_142406B40(mgr, elem, &{0,1,0}, 1) 建贴图句柄 → sub_1424071E0(mgr, handle) 取
> GPU 资源指针 → 存入 a1+40 (mask) / a1+64 (pattern)。⚠ 与上表宿主字段同源: 宿主 =
> *(a1+88), 其 +40 mask 数据 / +52 mask 计数 / +64 pattern 数据 / +76 pattern 计数;
> 字段名 TextureMaskList / TexturePatternList 的第二处断言 (maparrow.cpp:472/:479) 出自
> 0x14126C120, :440/:447 出自 0x141269880。差异:
>
> | 项 | 0x141269880 (insert 版) | 0x14126C120 (裸数组版) |
> |---|---|---|
> | 断言 (mask/pattern) | maparrow.cpp:440 / :447 (闩 byte_14333DE48 / DE49) | maparrow.cpp:472 / :479 (闩 byte_14333DE4A / DE4B) |
> | 校验时机 | 每段遍历**之后** | 每段遍历**之前** |
> | 目标写入 | sub_1401205A0(a1+40 / a1+64, &handle) 容器 insert (推定向量 push) | `*v9++ = ptr` 预分配裸数组直写 |
>
> 推定 insert 版 = 运行期懒重建 (先建设后自检, 容错), 裸数组版 = 确定性装载/设备恢复
> 路径 (先校验后建设, 严格), 待裁。sub_142406B40 / sub_1424071E0 真名与 mgr+368 对象
> 身份未决 (仅此两函共用, 未见第三消费点)。

#### 4.35.15 地图模式管线 (CMapModeManager 三段)

**切换段** (~80 处统一点): sub_140A66DE0 = CMapModeDispatcher::OnMapModeChange (mapmodedispatcher.cpp:238 实名) → 旧模式退出清理 (overlay 隐藏/hover 清/层停用) → 新模式入场预着色 → **sub_140E17F30 SetMapMode 状态机**: 同 id 非 force 早退 / 释放旧实例 / vtable+184 通知 / switch(id) 写 bank 槽对 (sub_140F31D20) + 层子模式 (sub_140F3B090) + 行选脏闩 (+129/+130) / ≥40 查自定义库 qword_14332F040 → 每路尾调 sub_140E18DF0 SelectModeInstances 向 hub (mgr+64) 灌 tag 色 → 尾取 24B 槽可见性掩码。

**每帧段**: 三 idler (ingame/frontend/nudge) 全部驱动 sub_140E1A890 UpdateDispatch — 日历追赶门 (dword_1430B15C0 三日游标逐日追赶扫) / 图例旗 → hub 全量重建 / switch(模式 id) 逐模式 updater / mgr+4 副模式支 (gs+700 省数门); 随后 sub_140E1DAA0 ApplyTweens 应用闩 (脏时写 mapview+1696/+1700 行选并触发行重建)。

**输出段双通道**: A. 省色贴图通道 — bank 23 槽脏位 → RefreshSlot (分派断言属 gradientbordermanager.cpp, 与 S4 渐变边框 18 件同库互证) → CRect 合并 → 省色纹理脏矩形提交; B. 国色通道 — hub 树暂存 tag→色 → flush 逐 tag/全量刷 (pdxmap 省色通道)。

**模式注册表**: 40 个硬编码 id 全表 (−1..39, 含槽对/层选参/行选逐模式表); id→loc 名 17 项 (sub_140E028C0, "MAPMODE_DEFAULT/STRATEGIC_AIR/…/RAIDS"; 1/32 与 16/38 别名组, 28 = DEFAULT 别名); **custom 模式 id = 40+下标**, 库单例 qword_14332F040 (64B; item+232 名 / +272 激活旗) — ⚠ **两层对象**: 该槽 = CMapModeManager 侧运行时实例库; 装载期另有**定义库 qword_143330DC8** (40B, 511 桶链式, 条目 176B CCustomMapMode, §4.30.54); 定义库→运行时库桥接 (id = 40+下标实例化) 未定位。**CMapModeManager 288B 字段级增量**: +4 层选参 / +16+24 实例 shared_ptr / +80/+84 行选 (+129/+130 脏闩) / +64 hub / +88 全量重建旗 / +96 hub 对象 / +272/+276/+280 (自定义模式暂存)。

#### 4.35.13 渲染域函数地图 (16 子系统, 269 件)

按子系统分组 (★ = ≥1,000 行)。S16 面板/视图行件 114 件逐件全表见下,
其余子系统全列。

| 子系统 | 件数 | 件清单 (★=≥1000 行) |
|---|---|---|
| S1 设备/后端 | 3 | ★sub_142438B50 5,472 GL 扩展装载 (= **glewContextInit**); ★sub_142441940 3,665 WGL/GL 扩展 (= **wglewInit**); ★sub_14241A230 1,729 适配器设置装载 |
| S3 地图图形 | 9 | ★sub_141244070 5,020 地图箭头绘制; ★sub_1423F4C90 4,233 前线点集平面切分; ★sub_141B204A0 2,248 省界图形生成; ★sub_1420A8510 1,560 float3 几何; sub_1412761A0 1,257 断言域巨函; sub_1412615B0 146 视觉数学; sub_14124F710 319 **箭头重建+弹道实体共享 per-frame (身份收窄: 原「导弹/爆炸实体」系其中 type==15 分支以偏概全 — "missile_explosion_entity" 仅该分支)**; 弹道循环生成 missile_explosion_entity; 箭头部分/爆炸实体; sub_140B52C90 269 懒初始化/FX |
| S4 渐变边框 | 18 | sub_140F34020 465 队列装配; sub_140F37330 388; sub_140F36C50 351 claim 管理; sub_14159BBE0 307 tbb 任务体; 家族件 14 (140F3A680 case-9 变体 = §4.35.49 / A0D0/38E60/39BF0/36710/38A30/34F90/37A40, 1417A1920/A2D490/27F4F0 1,122 LOD, 140A5CDC0/359D0, 140F3B370 431 池管理) |
| S5 地图模式 | 11 | sub_140E15A40 476 特工任务着色; sub_140E14680 470 OnMapModeChange; sub_140E1D2E0 396; sub_140E13FE0 307; sub_140E1CD90 288; sub_140E13A80 271; sub_140E1A400 269; sub_140E152F0 253; sub_140E1DD10 163; sub_140E1E090 159; sub_140E157F0 120 国色图例 |
| S6 地图图标 | 1 | ★sub_1418C99A0 1,141 建设图标 tooltip |
| S7 箭头/前线几何 | 7 | ★sub_141039F80 1,746 advancement 寻路; ★sub_14126FD50 1,162 纹理校验; sub_141662150 102 三池析构 (归属已改判 CGfxNavalCombatManager, §4.35.31); 海战图形三件+选优 (sub_141663E50 150 舰船实体名三级回退 / sub_141661FC0 88 命中特效实体表 / sub_141549F20 170 海军雷视觉件 ctor / sub_1415C6F30 83 idpair 选优 — §4.35.31a) |
| S8 相机/交互 | 4 | sub_1412627C0 392 热键+位移; sub_141261960 207 清场; sub_140DC0860 230 / sub_140DC0B20 181 递归数学 |
| S9 GUI 框架核心 | 29 | ★sub_1402A44A0 1,621 .gui 解析; ★sub_14230FEE0 1,313 重复类型校验; ★sub_1422BE890 1,511 布局递归; ★sub_141CDC170 1,165 文本项元件; sub_1422A4110 100 锚点分派; sub_14225C690 279 事件分派; idler/tick 族 12 (14167DB20/1412DFDC0/141289980/140DDDA40/1419AD3E0/140B92B30/141688A60/1422DC530/1417A7310/141833DB0/140CBC200/1416408A0); clausewitzlib graphics 控件基件 11 (sub_1422AFB40 233 按钮事件共享 Dispatch §4.00 / sub_1422B0B50+sub_1422B0BB0 21+21 button.cpp 未实现桩 / sub_1422F7EA0 CWindowType 模板继承链解析 / sub_1422F99E0 105 CWindowType 属性拷贝器 / sub_142372360 241 CDropDownMenuType 继承链解析 / sub_142307FA0 147+sub_142308260 144 CLineChart::SetData\<i32\>/\<fixed\> 两实例 / sub_1422CB020 128 CInstantTextBox 文本解析 / sub_1422B3020 121 锚点权重表 — 全部机制见 §4.30.32c) |
| S10 字体/文本渲染 | 4 | ★sub_14229C770 1,654 字体装载; ★sub_1422A1810 1,036 布局/图标; ★sub_1422A0230 1,049 缓冲构建; sub_142238A20 102 解析共享 |
| S11 文本引擎/本地化 | 14 | sub_1421EAA30 2,087 = ImGui::InputTextEx 本体 (改判迁 §4.26); ★sub_1411B4B10 1,930 = STL num_get 浮点解析 (§4.35.62); ★sub_14252ACD4 1,214 money_get; ★sub_1418530F0 1,272 / ★sub_140E18DF0 = SelectModeInstances (更正: 原 S11 归文本域系误归 — 实为地图模式层选实例选择器, 向 hub 灌色) 1,079 / ★sub_140D20450 1,336 战争名键求值; sub_142245880 235 $展开; sub_14224B9F0 225; sub_140BD3530 388; sub_140BD2F80 279; sub_140FD2240 264; sub_1411C5D30 255; sub_14225CD50 102 |
| S12 纹理/像素 | 8 | ★sub_142130DF0 1,617 搬运/填充; ★sub_142171F50 1,492 blit 巨函 (×24 分量表); ★sub_142133600 1,338 上传核; ★sub_14219BF40 1,401 / ★sub_14219D7D0 1,397 16 位变体; ★sub_14218FCE0 1,365 GUI blit; sub_14225FF10 106; sub_140D5BBC0 1,590 robin-hood 枚举 (通用基建) |
| S13 软件光栅 | 4 | ★sub_1421A0670 1,830 自递归内核; ★sub_142197DD0 1,604 16bpp 混合; ★sub_142196690 1,429 32bpp RGBA; ★sub_14219F1E0 1,315 32bpp RGBX |
| S14 3D 实体/动画/粒子 | 4+14 | ★sub_14228AF80 1,461 **实例逐帧动画/附件更新器 (递归)** (原「attachment 定位」系收窄误标 — 含时间归一/TTL 销毁/特效表/动态子实体生成/双子表递归/播完销毁); ★sub_14228D730 1,400 实例 dt=0 初始化更新 (精灵创建路径, 唯一调用方 entity_sprite.cpp); ★sub_1423AE8F0 1,115 float4 流变换; sub_1423FE460 280 粒子更新; pdx_entity.cpp 簇 12 盲区件补入 §4.35.17 |
| S15 调试/ImGui | 9 | ★sub_1422095C0 2,394 profiler SIMD 内核; ★sub_1421CBE30 1,426 Begin 原语; ★sub_1421F4480 1,156 / ★sub_1421F9450 1,134 观察窗族; ★sub_141B0F6D0 1,066 Faction Member 窗; ★sub_1410652F0 1,128 AI 前线调试; sub_1421D9B40 213; sub_1422A2F90 114 DebugTexture; sub_140222300 105 采样三缓冲 |
| S17 资产装载/压缩 | 6 | ★sub_142388030 2,950 bzip2 压缩 (sendMTFValues, §4.35.52); ★sub_14250CD90 1,537 range 解码; ★sub_14123D920 1,087 旗帜图集装载; sub_140B406A0 248 国旗图集; sub_140B40BD0 202 装载屏轮换; sub_140FA30E0 470 库条目实例化 |
| S18 基础库旁支 | 5 | sub_140E84150 192 批量释放; sub_14029E0F0 118 POD 拷贝; sub_140B6BC60 115 idpair 去重; sub_140210AF0 202 核爆遥测 (素材包误纳); sub_1406A40E0 101 生涯档案提交/上传总入口 (10 步: 本地/云载入合并→保存→云删除/上传路由; §4.28.22) |
S16 面板/视图 GUI 行件逐件表 (108 件, 按组):

##### S16a 军队/军事 (24)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1418D35C0 | 3,103 | 单位领袖 tooltip |
| ★sub_1416A3930 | 2,299 | 陆军视图 tooltip (师列表窗单位按钮回调, 全量精化 = §4.35.59) |
| ★sub_1417C39E0 | 2,120 | 订单组行件逐帧刷新 (师数文本为其一节; §4.30.71) |
| ★sub_140F454A0 | 1,694 | 军令 tooltip (orderstools.cpp) |
| ★sub_141258D30 | 1,848 | **军令线几何+锚点生成总入口** (orderstools.cpp; a1 = pGfxFronts **死参** — 函内零引用, 改经全局 idler vt[16] 自取同一对象; **有父订单 (a3=2)** → 邻接叉积定侧 + 垂距阈值 qword_1430B2E20 展开单侧带状边界省集合 → 增量绑定 (变化 ≤ max(1, n/5) 走轻量重绑, 否则全量重建); **无父订单 (a3=1/默认)** → 省位 + 邻接边第二坐标对折点 → 中点细分平滑 (轮数 dword_1433374D4 / 143337620); 终段提交路径 sub_14126C4E0 → 地形贴合缎带 sub_14126AE10 → finalize sub_14126D480; 写 a2+512 侧面旗 ±1, 清 pGfxFronts 标签缓存 +36/+48 |
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
| ★sub_1415E5C60 | 2,850 | 外交视图 BuildTooltip (元素名分发 tooltip 构造器, 主 vt[18]/@40[0] = §4.30.64; 面板 populate 侧 = §4.30.9 诸函) |
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

##### S16f 海军/海战 (18)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_141E29DE0 | 2,117 | 特混编成编辑器窗 tooltip 构建器 (15 槽分发 + 荣誉舰兜底; §4.16.23 尾块) |
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
| sub_141E12B70 | 288 | 紧凑舰列表更新主入口 (CCompactShipListView::UpdateCompactShipList, §4.30) |
| sub_141E15E20 | 211 | 分舰队修理父汇总入容器 (CNavyTheaterFleetRowItem 320B 行, §4.16) |
| sub_1419027F0 | 222 | 海任务地图图标布局 (CNavalMissionMapIcon, §4.31) |
| sub_140CE53F0 | 201 | CNavalCombatAirEntry 读取分派器 (§4.22.6) |
| sub_140CE3010 | 35 | CFEXMember 舰/运输 idpair 取值器 (§4.22.5) |

##### S16g 生产/建设/装备 (净 5)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_141788E70 | 2,497 | 模块选择窗 |
| ★sub_14176B330 | 2,464 | stats 网格 |
| ★sub_141780F80 | 2,077 | 装备设计器 tooltip = CEquipmentDesignerView BuildTooltip 全案 (§4.30.4a) |
| sub_141F78DD0 | 1,049 | 海军模块图标 |
| ★sub_141438470 | 1,008 | 许可证生产速度 |

##### S16h 后勤/补给/燃料/人力 (7)

| 函数 | 行数 | 身份 |
|---|---|---|
| ★sub_1410F35E0 | 2,261 | 燃料 tooltip (mode=0 明细 / mode=1 摘要; 顶栏 BuildTooltip 明细 / 后勤统计页摘要; 详 §4.3.16 GUI 消费面) |
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
| ★sub_140E10910 | 2,021 | 情报网络 (mode 3 operatives 通道州情报网 tooltip; 唯一调用方 = 省点击 tooltip 巨函 sub_140E05340 case 3) |
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
| sub_141F87720 | 248 | 终局得分页签填充 (CEndGameView, §4.30.32c) |

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
三槽 +40/+72/+104 / 432 shader→+136 / 678 shader_file→+168 / 524 index→+212 / default → 基类回落 sub_1424BEC40(a1); token 15 触发名
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

**pdxmeshtype 簇复核 (3 函全读, 零冲突)**: 装载巨函十要点抽验全吻合 (test_object.mesh 回退 / count mismatch 七组 / 四步管线 / 关节 >50 :326 错误旗 |= 4 / 动画不相容原地 erase / 材质槽 24B + 264B 记录 / FLT_MAX 哨兵包围盒 / +336/+340 id 对 / +312 平方数组 count@+324 / 双尾锚); reader 五键两门复核 ("dlc/" 断言全文 @pdxmeshtype.cpp:421 latch byte_143481439 / "Duplicated animation" :431 terminate); 嵌套类 RTTI 直证 CPdxMeshType::SAnimationLookup; meshsettings 栈构 SMeshData 216B {vptr, 6x std::string@+8..+168, dword -1@+200} SSO cap=15 直证; 增长 = copy ctor sub_1423094C0 落新 + move ctor sub_142309320 搬旧 (书双址逐位吻合); 顶点步 sub_142264190 实参 = +184 文件名 + +96 SMeshData 向量整体 + +48 scale + +370 preload 旗, 出参 +312 — SMeshData 跨宿主共享再添一宿主证据 (pdxmeshtype 基 +96 与 SEntityReader +1272)。

**SAnimationLookup** (56B; vtable 0x142B4D750):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | vptr | vtable 0x142B4D750 |
| +8 | u64 | FNV-1a32 零扩展 (键 = token 11 "id" 串值) |
| +16 | 指针 | 已解析动画资源 (token 225 "type" 串经动画库查得, 查表链 = sub_14222BDB0 → *(+856) → +8 → sub_1423AFC90(表, 名); 查无 → 错误日志 "Failed to find animation: \"<名>\"... Make sure it is declared in a .asset file." @pdxmeshtype.cpp:607 + throw) |
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

已决 (定案): CreateTexture2D Usage 槽 (+28) = **1 (D3D11_USAGE_IMMUTABLE) 仅纯 SRV 路** (SRV 旗 ∧ 无 RT ∧ 无 DS ∧ 无动/裸旗), RT 路 → BindFlags |= 32 / DS 路 → 64 + 格式钉 45 (D24S8), 与公开枚举零自洽矛盾; cube 旗 → ArraySize 6 + MiscFlags |= 4 /
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
0x142237FA0 (77, 双删断言; TU 锚 = graphics.cpp:1291, 括内数含义待裁; 延迟 = +325 压 +16 队列 / 即时 = swap-remove; 公共尾 = vt[12] (+96) 预通知 + a1+80/a1+104 双容器移除 + 对象+328 反向指针清零, +325 兼双删标记) /
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
sub_142429CD0 = gfx_glsl_builder CU; **同 CU 返回结构名解析器 0x14242D050** = 末空白 token 截取 (右去空白 → 左找词界 → substr) → sub_14240C210 按名查 GLSL 结构; 全空白 → :326 / 空 token → :338 双同文错误 "Failed finding return struct name" → 返 0)。
**GL buffer 12B 三 u32 用法 (SetVertexStream 直证)**: 描述符 [+8] 非零 = 有效门 (零则整槽跳过并触发 :2092 "Bad vertex buffer" 错误路径 + throw); [+4] = 元素计数 (仅首流 → dev+104); [+0] = 步长默认值 (仅当每流步长数组 a6 == 0 时采用, 写 dev+360/dev+112); a5 = 每流偏移 u32 数组 (a5==0 → 偏移 0), a6 = 每流步长 u32 数组 (a6==0 → 取描述符 [+0]); *(dev+120) 非空 → 先 sub_142420160() (推定解绑当前顶点缓冲); 空缓冲错误门 byte_1430BFDEA 反常 — 仅在该字节已非零时输出且输出后清零 (一次性闩且需外部先置位, 语义未决); 循环上界 = a2 (流数), 起始流号 = a4。
⚠ buffer 12B [+0] 语义**待裁**: 若 [+0] 为「偏移」则写入 dev+360/dev+112 (步长槽) 矛盾 — 候选 A = [+0] 实为每流默认**步长** (12B 记改 {步长, 顶点数, GL 名}); 候选 B = dev+360 非步长而为偏移槽。两候选均需汇编/他函核。

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
总门字节按 CU 分治**定案** (四 CU 实读: gfx_opengl = B51 3 站 / gfx_dx11 = B52 4 站 / filelogger = B52 9 站 / containerwindow = B51 多站 — 同层异值真实存在, dx11 记载无偏); 两旗各自级别语义未决 (GLSL builder CU 侧亦用 B51)。

未决: SDL 包装三件浮点 get/set(32) 语义 / 绑定条目 +16..39 元数据 (归 glsl_builder 批) /
GL 小查询槽 ~15 个 / LoadSettings 出参块跨后端异构的泛型消费方式。

#### 4.35.16f gfx_supply.cpp 路径条管线域 (9 函闭环; 补给/铁路/河网共用)

清册 (5/5 函体内含 gfx_supply.cpp 路径锚; 与 §4.28 BAB0 铁路线绘制核咬合): 连接-父边收集器
0x141656F90 (183, SRiverPath 请求 {端点 A/B, 段 id} + 省对去重 + 待绘 PQ) / 路径求解器
0x14165DA50 (658, **CMap+616 路径条图 +628 计数补录**, **堆式优先队列遍历** (df390 精化: 非 BFS — 工作队列 =
CPdxArray<32B 元素> 最大堆, push sub_1416559E0 扩容+追加+sift-up / pop 搬末元素到根+count−−+
sift-down sub_141657830 / 比较器 sub_141657320 五键复合序: +8↓ → +12↓ → +16 跳数 (0 = 最低优先,
非零升序 = 跳数少优先) → (+0,+4) 端点对 lex↑; 严格比较器), 扩展门 = sys+16 偏移表 →
calc+208 涉足位图, 回溯填请求 +16 found/+20 终点对/+40 途经对向量) / 旗标发射器 0x14165B4D0
(368, 省对序列按去重集切 run, 写 48B 几何记录 +44 位域 bit0 命中/bit1 方向/bit2 高亮) /
省份标记取色器 0x1416569F0 (128, 悬停/瓶颈红绿 = 省+32 vs max(MAX_RAILWAY_LEVEL, 首都节点
_TotalSupply), 白-色渐变 lerp, 开闭五态) / 补给流箭头刷新 0x14165E8E0 (416, **css+168 节点流
缓存第二读者** — country_supply.h:386 断言与 §4.21 已收 sub_141658020 同源; 按
SUPPLY_FLOW_REDUCTION_THRESHOLD 三档取 NODE_FLOW_IN_{CURRENT,HALF,FULL}_RANGE_COLOR 发射;
由渲染环 sub_140B572D0 经宿主+1840 每帧驱动)。
> df390 补录优先队列四件 (同域, 调用方 DA50 体内 gfx_supply.cpp 锚直证): **sift-down
> sub_141657830** (285, 唯一调用点恒 sift 根 a2=0; 返回值 char 为寄存器残留 — 比较径持 bool /
> 落叶径持 count 低字节, 调用方不取, 真身 void) / **比较器 sub_141657320** (五键复合序, 返
> bool = A≻B; ⚠ `!(v5 ^ v6 | v4)` = **有符号 (a>b)**, 极易误读为 (a<b), 逐值代入已证伪) /
> **sift-up sub_141657D50** (while (parent ≯ child) 交换上移, push 收尾) / **push 封装
> sub_1416559E0** (count==cap 则 1.5× 扩容 align 4 → 追加 32B → sift-up 从旧 count 上浮)。
> **32B 堆元素布局** (df390 定案, 比较器 + sift-up/sift-down + 调用方 5 见证互证): 边端点对
> (min,max)@+0/+4 (末键 lex↑) / 锚节点 id@+8 (主键↓, 沿路径继承, 业务含义未决) / 路径常量@+12
> (次键↓, 沿路径继承, 种子 0, 域语义未决) / 跳数@+16 (三键, 逐边 +1 — 松弛时 qword(+12) +=
> 0x100000000 只增高 dword +16; 种子 0 = 最低优先) / byte@+20 (不参与比较) / **padding@+21..+23**
> (XMM 交换显式跳过 = 编译器已知填充) / 继承对@+24/+28 (沿路径继承; 种子分支 A = 端点对 /
> 分支 B = 0, 域语义未决, 呼应下文「途经对向量」未决项)。

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

清册 (11/11 函身份经 RTTI 名 + vtable 槽契约双直证): **CAssetFactory::Reader** 0x14234DB90 (501, .asset 顶层四键分派; :767 动画装载失败 / :876 clone 父实体缺失 两格式化错误日志) / SAnimationData::Reader 0x1423506F0 (51, :35 "dlc/" 断言, 闩 byte_14348145D; 键 26/27 宿主槽 = 对象 +8/+40, 其他键 fallback sub_1424BEC40 默认分派) / **SEntityReader::Reader** 0x142350EA0 (543, :622 game_data 无注册 reader) / SEntityStateReader::Reader 0x142351B70 (422, :253 time_offset 参数数 / :335 game_data) / **CAssetFactoryAudio::Reader** 0x14234A010 (430, 六键分派; :499 music / :467 sound 缺失) / SSoundEffectReader::Reader 0x14234AB90 (187, :178 overflow 行为) / SSoundFalloffReader::Reader 0x14234B020 (97, :302 falloff 类型) / **CAssetFactoryAudio::[0] 装载后链接器** 0x142349D30 (174, :555 类别↔音效未匹配 / :577 音效无类别 + pdx_scoped_buffer.h:54 容量断言) / SAnimatedLightReader::Reader 0x14234E580 (1768, 8 键) / SVectorParamReader::Reader 0x14232CCB0 (1941, 九分量→4 槽位对) / SForceReader::Reader 0x142331D20 (1012, 8 键)。

**CAssetFactory::Reader 四键分派 (定案)**: animation(64) → SAnimationData {file(26)@+8 / name(27)@+40 两 std::string}, 经 Load wrapper sub_1424BE690 解析 (非裸 reader), 以工厂 +16 名串拼 '/' + 动画 file → 动画库装载 sub_142262560(工厂+8) (失败 :767); light(84) → SAnimatedLightReader, 九参数容器各经 sub_14232C820 转串 (32B/块, 写入序 = pos xyz / col rgb / intensity / radius / falloff) → sub_1423DE650(灯管理器单例 **qword_1435DA0F0**, 名, 九串块, **第 4/5 参 = +224 动画曲线数组 {data, count}**, count==0 时 data 强制置 0) 登记; particle(407) → SParticleSystemReader (ctor 0x142330750, +8 ← 工厂+16), 置 +26=1 递归解析; entity(438) → SEntityReader, 收尾 sub_1423529A0 → **meshsettings 登记环** → clone 父实体解析; 其他键落基 reader sub_1424BEC40。

**meshsettings 登记环 (定案)**: 遍历 SEntityReader+1272 meshsettings 向量 (元素 SMeshData 216B), 门 = 条目 +56/+88/+120 (三串 size) 任一 > 0 → sub_142261B40(**qword_143453090 = CGraphics::Get() 单例**, 条目, id 出参 {-1,0}, 三串出参, .asset 目录前缀, 0, preload 旗 = 条目+1296); 登记返回后三串写回条目 +40/+72/+104、id 对写回 +200/+208。clone: 条目 +520 名非空 → sub_142291330/sub_142293530 查父实体, 命中 sub_142291E30 克隆, 未命中 :876 错误日志; 空则 sub_142292800 直登。+25 旗 → sub_142291C70(1/0) 包裹 clone 段 (开 = 登记环之后 / 关 = SEntityReader dtor 之后; 实体库克隆态开关)。

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
| +1152 | 数组 | state (439) 正式层 | 元素 600B = 656B 解析态前 600B 截断拷贝 (收尾器 sub_1423529A0); 条目内 event 向量压缩内联 {+568 data, +576 count} / propagate {+584, +592}; data 回写 +1032, count → +1040 |
| +1176 | 向量<SAttachment> | attach (338) / group (63) 解析层 | 元素 336B; attach 额外置条目+8=1 + push 后写条目+16 附加字段 (sub_14234BE10→sub_14234D3B0, 语义未决), 随后块内键直接在尾条目上继续解析 |
| +1200 | 数组 | attach 正式层 | 元素 272B = 336B 解析态自 +64 起拷 (逐条 sub_1423525C0 预处理); data 回写 +1048, count → +1056 |
| +1224 | 向量<SEntityLocatorReader> | locator (511) 解析层 | 元素 624B |
| +1248 | 数组 | locator 正式层 | 元素 576B = 624B 解析态压缩 (对齐 16); count → +1072 |
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
| +532 | i32 | time_offset (476) base | {base variation} 二元或单值; 列表计数 0 或 >2 均报 :253 (1..2 收) |
| +536 | i32 | time_offset (476) variation | |
| +540 | u8 | loop_animation (444) / looping (454) | 同槽别名对 |
| +544 | f64 | loop_time (450) / state_time (475) | 同槽别名对 |
| +552 | u64 | next_state (472) | 键名串 FNV-1a32 零扩展 |
| +560 | i32 | chance (446) | 读后钳 ≥0 |
| +600 | u64 | game_data (508) 上下文 | 第 4 参 = 1 |
| +608 | 向量<SEntityEventReader> | event (440) | 元素 1808B |
| +632 | 哈希容器 | propagate_state (505) | 二元对入表 sub_140224490: 块形态 = {FNV(键名), FNV(词法器伴生串槽 a2+56/+68)} (第二分量语义待裁); 标量形态 = {FNV(键名), 0} 只记存在性 |

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
**SSoundFalloffReader** (vtable[4] = 0x14234B020; 五键分派, 定案):
| 偏移 | 类型 | 键 (token) | 语义 |
|---|---|---|---|
| +8 | std::string | name (27) | 衰减名 |
| +40 | f32 (推定) | 590 | 数值参数甲 (语义未决, 须游戏内 lexer 取名) |
| +44 | f32 (推定) | 591 | 数值参数乙 |
| +48 | f32 (推定) | 592 | 数值参数丙 |
| +52 | i32 | type (225) | falloff 枚举: stricmp "linear" → 0 / "logarithmic" → 1; 他 → assetfactory_audio.cpp:302 "Not a valid falloff type: %s" (通道 4096) |
| 他键 | — | — | 落基 reader sub_1424BEC40 = **单行 thunk** → sub_1424C2060(a2); SAnimationLookup / SSoundFalloffReader / CAssetFactory::Reader 三簇他键共用 (推定 = 忽略未知键) |
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
| +8 | i32 | type (225) | 力型枚举 (下表); 非法 → sub_1424C1CA0 词法器错误通道 "Unknown force type: \<名\>" (无 latch 非断言门, 不中止解析, 枚举保持未写态 — 非致命) |
| +12 | char[64] | name (27) | strncpy 0x3F 截断 + [75]=0 null 终结 |
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


**收尾器 sub_1423529A0 = 解析态→正式态压缩器 (定案)**: SEntityReader 双层结构 = 解析层 (+1128 起大元素向量, reader 协议布局) + 正式层 (+1032..+1104 镜像计数/指针 + +1152/+1200/+1248 紧凑容器, 引擎消费布局), 收尾器单向转换; SMeshData (+1272) 例外不经压缩直接被登记环消费。块形态 `{base variation}` 机制 = 基/变体是两个独立容器 (基 +N 与变体 +N+32), 第 3 值 → assetfactory_common.h:130 `Too many parameters! File: <文件> Line: <N>` 格式化日志 + terminate 致命 (三巨函 7 处触发点)。巨函膨胀本质 = 同一 ~200 行状态机 ×4~9 组参数槽的模板展开 (SVectorParamReader 内 @ 展开 sub_1424C04A0 ×30 / POD 扩容 sub_14208A4A0 ×18 量化直证)。event (440) 向量增长 = 纯 memcpy 平移 (SEntityEventReader 为 POD, 四向量中唯一); state/locator/meshsettings 均逐元素 copy ctor。块形态栈临时初始化源 = 静态默认模板单例 (state sub_142296450 / locator sub_142296410 含默认 f32 1.0 / event sub_142296340)。animation_speed (442) f32 读入升格 f64 存 +520; chance (446) 负值钳 0。'@' 引用展开 = 词法层机制 (sub_1424C04A0 三元组 {kind, 形态, 引用名串} 回填词法器 token 槽后由统一循环再消费, reader 零特殊分支; entity/state 系内联直写 / force/light 系经 sub_14015A6F0 回写两法并存)。目录前缀 = 源文件名 rfind('/')+1 截取 (含末斜杠, 未命中 → 空串)。case 84 magic static 守卫 = TLS 感知变体 (TEB ThreadLocalStoragePointer + dword_14332ECF0 双门)。断言总门 B52 在 graphics 两 CU 通用, 与 GL CU 用 B51 并存 (按 CU 分治再添一例)。

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

FX 粒子系统定义 writer = sub_142344F20 (2739 行; 与粒子定义解析件 sub_142296A40 成对; 经 vtable 槽[1] 间接调用, 语料零显式调用方, 本体类名未决): **32 键全表落定** (原记 6 键) — 头部 name(27) / max_amount(409) / sort(426; **枚举数值 1=depth / 2=distance / 3=age, 0 不发射**) / emitter_type(481; **三态 0=point / 1=sphere / 2=box 推定**; sphere(482-484) 与 box(485-487) 参数键共享同一批向量存储) / slave_particles(608) 等; **19+1 曲线块双向量布局全表** (force 唯一单向量); 68B keyframe {模式位, +4 值}; float → ×1e5 round-half-away 定点整数字面量发射; **发射原语精化**: 279× 串 sub_1424C2AD0 + 76× **sub_1424C3900 = int→十进制文本** (原未定性) + bool 键原语 sub_1424C37B0 + **块委托 trampoline sub_1424C24F0 ×3 + 递归** (原「4× 块 sub_1424C4220」定性失真 — 4220 实为键名发射); texture/color/position 三代理委托块字段组; 主对象标量带 +1756..+1870; childsystem 1872B/条递归经元素 vtable[1]。

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

**DDS 装载** (sub_142424F90; (out*, buf, size, params*, filename*)): 调用链 = 纹理装载分发器 sub_14240E9B0 (§4.35.7 S1 CU) → 魔数门 sub_142424F70 ("DDS ") → 本函; 失败且 .tga → sub_142425900 TGA 分支 (失败 → :458 旗 4096 日志 "Failed to load image '<名>': <errmsg>"); TGA 亦失败或文件名非 .tga → **第三兜底解码 sub_14240E660(out, buf, size)** (书原未记此分支; 解码格式未决, 推定 BMP 或未压缩 TGA 变体), 再失败才返 0。后处理: *(params) ∨ sub_142405710() → sub_14240DF00(out) (推定 mipmap/上载); params[1] → out+12 = sub_14240F3E0(out+12) (纹理 +12 格式槽重映射, 推定 sRGB/格式转换)。头消费: +12/+16 高宽 → out+4/+0; +80 ddspf.flags (0x4 = FOURCC 门, 0x40 = RGB, 掩码族 0x20240); +84 fourCC 分派 (DXT1=1/DXT3=3/DXT5=5 内部格式; **DXT2/DXT4 不支持返 0**; DX10 → 像素数据起点 +148); +88 bpp 类 + +92..+104 位掩码细分 (565=7/4444=8/1555=9/24bpp=11/32bpp=13/其余=26); 不可识别 = 断言 :118 "Unknown texture format" (B52 门, 闩 byte_1435DD583); +112 dwCaps2 bit 0x200 = cubemap ×6 面。

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

**ReloadTexture** (sub_142408B20; (this, 记录下标, params)): 全局互斥锁 0x1430BFA90 (紧跟 ABI 表尾) → 记录门 = 引用计数 > 0 且句柄非空 → **槽 65 覆写前奏** (无可见实参) → 解析 → 文件长 ≥ 16MB **静默返 false** (与执行件有门对照) → 读入 +112 → 解码 → **槽 61 (设备, 既有句柄, 解码件, data, size) 像素上传** (§4.35.5 槽 61 语义改定直证) → 返句柄非空; 解析失败 → ③:656 "Missing texture file"。DumpTextureInfo (sub_142408810): 逐记录 (引用计数>0 且已装载) 输出句柄/名/refcount/宽高, 控制台回显包裹对; 调用方之一 = console 侧 dump 命令路径 (*(qword_14332F698+1264)+368) = **`debug_textures` handler 0x14024F020** (ConsoleCmdImpl.cpp:2380, 类别码 774: DumpTextureInfo → 流内追加纹理汇总串 sub_142238E00 → 回显 "Texture info has been written to the debug log.")。同族 **`error` handler 0x140257D70** (:7850, 类别码 65540: 日志头 \"======== show errors from console ========\" + 11×'\n' → sub_14222BDB0() 取引擎单例 → sub_140175840 转储错误日志到控制台, 回显空串仅置成功位)。两 handler 与 §4.28.26 定案 ABI 一致 (result 40B {+0 u8 状态, +8 std::string 回显}); 注册名归属高置信 (注册名表串域相配, 待 rip-rel 注册扫描二验)。

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
| 省界 | sub_141B204A0(*(+8 上下文), +18848, +18872, +18920, 256, +17 ? −1 : 0x10000) — 256 = 分块边长 (像素), 0x10000 = 单顶点缓冲顶点上限 (u16 索引寻址上限), −1 = +17 自建门置位时合并单缓冲; 全量定案 §4.35.60 |
| 树 | sub_141B26810(设备, +21296) (16B/条, +21308 条目数, +10 u8 类型序); 树类型名 = "mapobject_" 拼类型名 → sub_142238C00 → 存 +19256+8×类型序; 失败 → ③:2980 (flag 65543) |
| 顶点缓冲 | +296 空则 **槽 35** CreateVertexBuffer (调试串 pdxmap.cpp:3373 — §4.35.16③ 第 6 参新实例互证); +304 空则 **槽 45** (产物存 +304) |
| 索引缓冲 | +17 门: 旧 +23712 经 **槽 42** 释放 → u16 索引 6×(n−1) 条 (条带模式) → **槽 41** CreateIndexBuffer (调试串 :3274) → 存 +23712; else 支 sub_141278AD0 |

尾 = sub_14125D530(上下文, +23448) → LOAD_GFX 收尾 → +16 清零 → CMapModeDispatcher 族收尾。唯一调用方 = sub_140B4F9C0 (传 mgr+88 的 CPdxMap)。

**CPdxMap 装载域偏移群**: +8 渲染上下文 (后端设备 = *(ctx+128)) / +16 装载中旗 / +17 索引缓冲自建门 / +176/+200 物件层与箭头层 (推定) / +296 顶点缓冲 / +304 槽 45 产物 (待裁) / +18792 边界/省描述符侧 (sub_141B27AC0 产物, 本函范围外) / +18848 省界顶点缓冲句柄 vector<u64> / +18872 省界边界记录 vector<20B> / +18920 分块剔除网格 48B/块 (§4.35.60) / +19256 每树类型图形表 / +21296/+21308 树层容器与计数 / +23368/+23376 河流输出对 / +23424/+23436 河流点 data/count (24B/省) / +23448 输出层 (推定) / +23712 GB 索引缓冲 / +23744 分块级数 / +23752 GB 纹理指针。

未决: +304 槽 45 产物 / GB 纹理 192B 全形 / 单例 qword_143339D28 +64/+68 宽高 (推定) / 24B 省河流条目内部形状 / 槽 89 本调用形态。

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

#### 4.35.31a 海战图形三件 (gfxnavalcombat.cpp 2 函 / navalmines.cpp 1 函 / naval_utility.cpp 选优 1 函)

**海战舰船实体名解析 (0x141663E50, gfxnavalcombat.cpp)** — 为海战舰船图标取 3D 实体名, 三级回退 + 占位兜底:

| 偏移 (a1 视觉对象, 类名未直证) | 类型 | 语义 |
|---|---|---|
| +64 | 指针 | 舰船实体源 (经 sub_14100FF30 解出; 空 → 走对象名回退) |
| +128 | — | 实体名构造第二参数 (与上者共入 sub_14192DC30 组名) |
| +144 | bool | 有效旗; 为 0 → 直接返回占位实体名 "test_object_entity" |
| +232 | — | 兜底实体名源 |
| +2064 | int32 | 实体 id (入 sub_141662C00) |

> 回退序: 组名 (sub_14192DC30(&out, 舰实体, a1+128, 舰实体+28)) → 对象名 (sub_140C39AC0(a1), 非空入注册表) → 组合件名 (舰实体+1008 且其 +296 非空 → sub_141662C00(…, 舰实体+1008+280, …)) → 兜底名 (a1+232)。全失败 → 日志 "Missing ship entity '\<名\>' deploying placeholder box!" (名 = sub_140C39160(a1)) 并返回 "test_object_entity"。实体注册表 = sub_142291330() (CGraphics 实体库), 查名登记 = sub_142293530。

**命中特效实体表解析 (0x141661FC0)** — 源 = 32B std::string 记录向量 (data@+0 / count@+12; SSO 判容量@+24 > 0xF); 逐名 sub_142293530(注册表, 名) → 命中则指针入输出引擎向量 (几何扩容 max(n+1, (int)(cap×1.5))); 未命中 → 日志 "Failed to find hit effect entity '%s'" (只日志不中断, 返回注册表句柄)。输出向量扩容 max(n+1, (int)(cap×1.5)) 走分配器虚槽 (*(a2+16) 对象 vtable+8 分配 8×cap → 拷旧 8×count → vtable+16 释放旧 → 更新 {data@+0, cap@+8, count@+12}); 注册表 getter = sub_142291330() 无参全局。

**海军雷视觉件 ctor (0x141549F20, navalmines.cpp)** — sizeof 0xC0=192; 由 CRegionGraphics ctor sub_14167E190 于其 **+136** 创建, 门 = 区域 a2+160 > 0 (malloc(0xC0) 直证):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | 指针 | 宿主 CRegionGraphics 回指 |
| +8 | 24B 对象 | ctor sub_14011DF40 (构 {0, 0, vtable@+16 = off_143085170}) |
| +32 | 24B 对象 | 同上 |
| +56 | 指针 | 实体 naval_mine_friendly_entity; 空 → 日志 "Missing naval_mine_friendly_entity. Visual 3d mines will not be displayed." |
| +64 | 指针 | 实体 naval_mine_enemy_entity; 空 → 同族日志 enemy 版 |
| +72 | qword | ctor 清零, 语义未定 |
| +80 | 24B 对象 | ctor sub_14011DF40 同构 |
| +104 | 24B 对象 | 同上 |
| +128 | int32 | −1 (推定「未选中」哨兵) |
| +132 | int32 | 0 |
| +136 | byte | 0 |
| +140 | int32 | 0 |
| +144 | 24B 对象 | 内联构 {0, 0, vtable@+16 = off_143085170} |
| +168 | 24B 对象 | 同上 |

> 六个 24B 成员类型未定 (IDA 判其析构同 `std::locale::global` 静态析构; 公共 vtable 槽 off_143085170, CRegionGraphics ctor +88/+120 亦见同构件)。视觉件类名无 RTTI 直证。

**idpair 数组选优 (sub_1415C6F30, naval_utility.cpp)** — a1 = idpair 数组 (data@+0 / count@+12 / 元 8B); 逐元非空且 sub_14221F310 有效 → 取**对象基址−16** 的 +124 dword, 否则 0; 写入定长对齐临时缓冲 ((4n+7)&~8, pdx_scoped_buffer.h:54 容量断言); sub_1424F0890(count, 键数组, file:line 哈希) 返单一下标按该下标取回对象返回 = 按对象 +124 键选一个代表 (**加权随机**取代表, 非 argmax: sub_1424F0890 = sub_1424F02E0(count, 权重, rand, 0xFFFFFFFF) = 加权随机核 SIMD 版 — 与 weightedrandom.cpp:133 同核 (正权重求和 + 2^−31 尺度 + 2^63 回绕守卫), 失败/穷尽返 0xFFFFFFFF 静默哨兵; 随机源 = sub_142233FA0(naval_utility.cpp:457) & 0x7FFFFFFF (file:line 哈希作 RNG 种子); 全部权重 0 / 穷尽 → 返 NULL; +124 字段语义在 CTaskForce/CShip 表均未载)。

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

#### 4.35.16h assetfactory_particle 粒子发射器一致性校验 (assetfactory_particle.cpp; 1 函)

`sub_1423316F0` (参数互斥校验 + 类型枚举回取，返回 +1764 类型枚举；所属类 SParticleSystemReader / CParticleEmitter 未决):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +1764 | u32 | 发射器类型枚举（1 = sphere / 2 = box） |
| +1832 | std::string | 名串（size@+1848, cap@+1856） |
| +1864 | 旗 | 含盒体参数 |
| +1865 | 旗 | 含球体参数 |
| +1867 | 旗 | 已校验 |
| +1868 | 旗 | 警告旗（有未报告问题且已校验 → 置 1） |
| +1869 | 旗 | 已报告门（防重复刷屏） |

告警：枚举 1 且 +1865 → :91 `Sphere emitter contains box emitter parameters and will probably be wrong: <名串>`；
枚举 2 且 +1864 → :99 `Box emitter contains sphere emitter parameters and will probably be wrong: <名串>`。
同族 CAssetFactoryParticle vtable 0x142B501A8 / Load wrapper 0x142331870 已收 §4.00 bases。

#### 4.35.33 渐变边框构建管线 (gradientborder.cpp; 6 函全链 — S4 渐变边框族的下游实现侧)

管线闭合 (高置信): S4 已收 tbb 任务体 0x14159BBE0 → **邻接边界边收集 0x14159B770** (168 行; 选择集字节表 = scratch 缓冲按省数切出; 逐省取省图形 +184 邻接数组 {数据@+112, 数@+124} 条目 48B, **只处理不在选择集的邻居** = 外沿; :828 `out of bounds - adjacencies` 断言 byte_14338A93B) → 0x141598160 → **省对边界构建派发 0x14159AAB0** (140 行; 省界门 1 ≤ id < 根+628; :209 区间同省断言 byte_14338A938; 请求条目按对侧 id 二分分组, sub_14140A320 定位边槽号; 失败 :233 log-and-continue) → **边界段贪心双端链 0x14159AED0** (466 行; 种子 = 曼哈顿邻居数最少段, 空 → :286 `Impossible just happened` 断言; 贪心最近邻双端生长 — 头侧更近整链 std::reverse 后追加; 段 swap-remove; 点 u32 {x|y<<16} 压出列) → 更新循环 0x1415963F0 / 0x141596150 → **梯度/平色双路径**。

**距离掩码梯度构建 0x141597240** (607 行, 定案): 半径 = sqrt(inner² + 外延²) × 3.0; 核窗口逐格到 24B 边界格记录点列的最小距离² (提前退出 ≤0.5 命中即止 / > 当前最优 + 格对角² 剪枝); 命中格像素重算取最小距离 d → 梯度值 = d < inner ? 255 − (u8)d : 255 − (int)((d − inner) × slope × 255) − (int)inner, 统一 −8 后钳 [0,255]; 写图层缓冲 **Y 翻转** `数据 + pitch×(高−y−1) + x`; 层 +64 空 → :1337 断言 (文案互指 CGradientBorderManager::HasDistanceMask() / CGradientBorder::SetOverrideGradient(), byte_14338A93E)。**平色直写 0x14159D010** (88 行) = 同断言同 Y 翻转, 边界 run 逐像素直写 255 — HasDistanceMask 开关的梯度/平色双路径。run 记录 = **6B {x0 word@+0, y word@+2, 长度 word@+4}** (run 列表向量 {data@+0, count@+12}, 经 (ctx+32 提供者)+8 函子 → 宿主+184 指针 +88 偏移抵达); 逐 run 先查 ctx+24 掩码表 (layer+24 +8×idx 非空 = 该 run 有距离掩码 → **跳过平色**, 梯度路径 0x141597240 负责); layer+120 纹理句柄非空 → 每像素触发 sub_14166F070 失效回调。**图层缓冲分配 0x141598970** (214 行): 层 +52 宽 / +56 高 (源 = a2+64/+68); 距离掩码旗 (+112) 开 → 宽高 (0, 65535) 双断言 (byte_14338A93C/93D) + **+64 = malloc(宽×高)** (1 字节/地图像素距离掩码); 内存报告三连 (日志旗 65541 = 0x10005 变体, 与 4096/65540 并存)。

**CGradientBorder 图层对象布局 (高置信, 读者面反推)**: +24/+32/+36/+40 省掩码向量 {data, cap, count, alloc} / +48 宽×高 / +52 宽 (= pitch) / +56 高 / +64 距离掩码缓冲 (空 = 平色层) / +72/+75 脏旗 / +112 距离掩码开关 (推定) / +120 纹理句柄 (非零反复触发 sub_14166F070 — 纹理失效回调推定)。**pdx 全局 scratch 缓冲原语直证** = sub_1424E40D0 获取 / sub_1401C3820 归还 / 游标@+8 / 容量 dword_1435E3ECC (pdx_scoped_buffer.h:54 断言) — 帧内零分配 scratch 通道第三消费域。构建 ctx 同型性 (0x141597240 读 {+8 提供者, +16 尺寸, +24 格数组, +32 图层} vs 0x14159D010 读 {+24 查表, +32 提供者, +40 图层}) 待裁。

**GPU 纹理侧 (gradientbordertexture.cpp 两函, df304 定案)**: ① 分辨率计算 0x14166EC40 (112 行): `W = *(a1+64) / dword_1430B3C00`, `H = *(a1+68) / 除数`; 随后全局除数 dword_1430B3C00 **逐次 ×2 且跨调用持久** (数据段初值, 代码侧无复位点 — 设计意图待裁: 单次初始化 vs 质量棘轮), 退出条件 = 除数 ≥ max(W,H), 等价 2 的幂 d 使 d² ≥ 全宽 → **终态 ≈ 开方降采样** (4096×2048 → 64×32 量级); 循环体跑过即走 :414 "Unsupported texture resolution: %dx%d. Going to use lower quality: %dx%d" 日志 (伪码顺序落入收尾非条件失败); 收尾 dword_14338AB88 = H+1 / dword_14338AB8C = 2×(H+1)。② 双纹理创建 0x14166DB60 (148 行): 三重断言 (:427/:428/:429, 对象 +128 _Texture / +136 _TextureFx 须 NULL_GFXHANDLE) → +120 缓冲空则 malloc(16×W×AB88) 清零, 拆四平面指针 +144/+152/+160/+168 (步长 4×W×(H+1) 等大; ⚠ IDA 赋值序 18/20/19/21 交错 = 面2/面1 槽号互换, 按偏移记录) → 两次 sub_1424046D0(a2, +120 基址, W, AB8C, **格式 14**, 0, 1, 溯源串) 产出 _Texture/_TextureFx — **同数据同参双纹理**; 失败 → :462 "Failed to create a texture. Gradient borders will not be visible."。⚠ 字节账待裁: 缓冲 16W(H+1) B vs 单纹理 4B/px 计 8W(H+1) B = 半缓冲 — 格式枚举 14 = 8B/px 或四平面为 CPU 写入窗只消费前半, 未裁。对象布局 (高置信): +64 全图宽 / +68 全图高 / +120 像素缓冲 / +128/+136 双纹理 / +144..+168 四平面指针 (写入方 = 本节 0x141597240/0x14159D010 侧, 本两函不写平面)。全局参数: dword_14338AB80/84 = 当前宽/高; qword_14338AB78 = gfx 上下文管理器 (sub_1424D5400 校验活, 失活 sub_1424D5B70 重建)。

#### 4.35.33a 渐变取色器 (gradientbordermanager.cpp; 1 函)

`sub_140F32FB0` (resistance map color 梯度插值；输入值经 xmm1 传入，IDA 漏参，伪码签名缺一个 float):

| 项 | 事实 |
|---|---|
| 描述符 | a1 = {float* 数据 @*a1, u32 计数 @a1+12} |
| 站布局 | 每站 5 float：[0] = 阈值，[4] = 颜色分量；站数 = 计数/5 |
| 校验门 | 计数 <10 → a2 = 计数/5；计数 % 5 != 0 → :2820 `invalid resistance map color define`（日志旗 4096）→ 回退插值 1.0 |
| 查找 | 从站 1 起步，步长 5 扫到首个 站[0] >= 输入值 |
| 插值 | 比例 = (输入 − 站[i−1][0]) / (站[i][0] − 站[i−1][0])；分母 <1e-2 → 比例 0；负数钳 0；fminf(1.0, 比例) |
| 出口 | a4 = alpha 通道旗：真 → 两端取 站[i−1][4] / 站[i][4]；假 → 皆 1.0；结果 = (上端 − 下端) × 比例 + 下端，交 `sub_14224C7C0`（推定 CColor 构造，签名未决） |

书内坐标：§4.30 resistance 百分比显示链的颜色源（本节定案该环节原「本地化」标签）。
#### 4.35.34 pdx 动画注册/播放层 (pdx_anim.cpp; 3 函 — PlayAnimation 引擎核 + AddAnimation 注册件 + 关节数校验件; clausewitz 树)

pdx 引擎动画层 (clausewitz\pdx_anim\pdx_anim.cpp, 非 hoi4\source 玩法层), 与 §4.35.17 pdx_entity.cpp (实体/状态机层) 为邻接编译单元: entity 事件播动画 → 本簇注册/播放; 同 CU 邻函 sub_1423AE8F0 (float4 流变换, 1115 行) 已名。PlayAnimation 引擎核 0x1423B01B0 (1162 行) 唯一调用方 = sub_14227C730 CPdxMeshObject 播放入口 (pdxmeshobject.cpp:678 日志 "PlayAnimation failed for mesh \"%s\""); AddAnimation 注册件 0x1423AE1F0 (191 行, 源记录 → 运行期 def 打包); 关节数校验件 0x1423AE0E0 (51 行; a1 = 网格 / a2 = 动画, 关节数不等 → CLog 4096 pdx_anim.cpp:1124「Animation [<名@a2+60>]: ...joints does not match...」+ 返 0)。

**CPdxMeshObject 播放入口 = sub_14227C730** (pdxmeshobject.cpp:678; 补本节 VA 空缺, 定案): a1+88 = mesh 持有者 (+64 = 动画集非空门, +16 = 名串供日志); a1+112 = 动画播放器; 动画查找 sub_14230A380(mesh, name, &idx) (失败 idx=−1 返 0); 播放 sub_1423B01B0(player, anim, &transform) (a3 空 → 默认变换 sub_1423AC400), 失败 → :678 "PlayAnimation failed for mesh …"; 选中态 = `(a1+96 & 1) && (a1+80 == dword_143481264)` 经 sub_1423B1780(player, &flag, 1) 传入。dword_143481264 语义未决 (推定当前选中 mesh 实例 id)。

播放器实例布局 (0x1423B01B0 主语, 定案):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | 系统指针 | 动画系统 (时钟 double @系统+24) |
| +8 | mesh 指针 | 网格 (关节数 u32 @+0; 关节表指针 @+8) |
| +16 | 64B×关节数 | 输出关节调色板 (4×16B 变换矩阵/关节) |
| +40 | float×3 | AABB min |
| +52 | float×3 | AABB max |
| +64 | double | 本次启动时钟 |
| +72 | def 指针 | 当前动画定义 |
| +80 | double | 启动时钟快照 (混合时随 16B 拷入混合区) |
| +88 | f32 | 播放速度 |
| +96 | u8 | 循环旗 |
| +104 | f32 | 位置基 (a3+4) |
| +112 | def 指针 | 混合源动画 (上一动画; 混合完成清 0) |
| +120 | double | 混合源启动时钟快照 |
| +128 | f32 | 混合源速度 |
| +136 | u8 | 混合源循环旗 |
| +144 | double | 混合源位置 |
| +152 | double | 混合启动时钟 |
| +160 | f32 | 混合时长 (a3+8) |

参数块 a3 (12B, 默认构造 sub_1423AC400): {speed f32 @+0, 位置基 f32 @+4, 混合时长 f32 @+8, 循环 u8 @+12}; 默认值 = {1.0, 0, 0, 循环=1}。

时间公式 (定案): 位置 = (时钟 − 启动) × 速度 + 位置基; 循环 = fmod(位置, 时长) (负值补一圈); 非循环钳位 [0, 时长]。混合完成门 = 时钟 − 混合启动 ≥ 混合时长 → +112 清零。无前动画时立即全量求值姿态; 有前动画 (混合建立) 时本函直接返回, 姿态由逐帧更新路径求 (与 §4.35.17 逐帧动画更新器的接续点未决)。

运行期动画定义 (def) 384B — 写侧 (0x1423AE1F0) 读侧 (0x1423B01B0) 双证:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +0 | uint32 | 关节数 |
| +4 | uint32 | 帧数 |
| +8 | float | fps |
| +16 | double | 帧步 = 1/fps |
| +24 | double | 总时长 = (帧数−1)×帧步; 帧数<2 → 帧步 (并 :772 告警 "Animation has only one sample: %s") |
| +32 | 指针 | 关节描述 32B×关节数 (malloc; 静态值内嵌: 旋转 16B @+0 / 平移 3f @+16 / 缩放 f @+28) |
| +40 | 指针 | 逐帧逐关节旗 byte (帧主序) |
| +48 | 指针 | 载荷浮点 (帧主序, 帧步长 = 4×打包数) |
| +56 | uint32 | 每帧打包浮点数 |
| +60 | char[64] | 动画名 (strncpy 64) |
| +124 | char[255] | 源记录名 (strncpy 255) |

通道打包旗位 (定案): 每关节旗 byte: bit1 = 平移 (3 浮点) / bit2 = 旋转四元数 (4 浮点, 采样插值 sub_1424FDD20) / bit4 = 缩放 (1 浮点); 旗 0 关节不占载荷; 帧内打包序 = 关节序 × 通道序。

mesh 关节记录 56B: {父下标 u32 @+0 (255 = 根), 半径 f32 @+4, 逆绑定/绑定矩阵 12f @+8..+52}。骨骼组合 = 逐关节 世界矩阵 = 父世界 × 本地 (4×16B shuffle 乘法), 写回调色板; AABB 逐关节 min/max 收缩扩张 (带动画通道按关节半径扩张: min−半径 / max+半径, 静态通道精确值)。

关节数不一致四站: :907 debug_assert "Animation and mesh does not have matching number of joints!" (门 byte_1435E1B51 + latch byte_1435BA0AA) / :908 一行式日志 (sub_1424C9240 流) "Animation \"X\" does not have the same amount of joints as the mesh it is trying to animate. ( Animation N, Mesh M)" / :673 格式化日志 "Different number of joints in animation (Might cause crash)" (AddAnimation 同名重注册) / :1124 一行式 "Animation [X]: Animation's number of joints does not match mesh's number of joints. ( Animation N, Mesh M)" (另一动画型, 名裸 char* @+60)。

动画库 = 对象+32 hash 表 (sub_1401B6E00 按名 find-or-insert; 值对象 +48 = def 指针); CPdxMeshObject 侧名→实例线性表 (+216 表基, 跨距 56, 计数 +228, sub_14230A380 扫名)。

#### 4.35.35 地图区域名标签放置 (graphics\countryname.cpp; 1 巨函 — 区域名文字标签的光栅化渲染, 与本地化零关系)

CU = `hoi4\source\graphics\countryname.cpp`。**定性甄别**: 簇名易误读为「国名文本解析」(本地化域), 实际 = **地图上国名/区域名文字标签的放置与旋转光栅化** (graphics 渲染域)。调用链 = CGraphicalMap::UpdateMapNameMode (§4.35.2 具名) tbb parallel_for lambda → sub_14164A150 (逐 tile 包装: pdx_scoped_buffer 建 省→area 映射 u32 数组; 32B 记录逐条 arr[省对象+164] = 记录+8) / sub_140B5C7F0 (同构第二包装) → 巨函 0x141647360 (1181 行)。

**区记录 32B 形态** (定案): {+0 省对象* (消费 +164 省 id / +192 州对象), +8 area id, +16 区名 MSVC 串*, +24 u8 旗A, +25 u8 旗B}。巨函参数 = a1 省→area 映射数组 / a2 目标 area id / a3 文本渲染对象 (vtable+144 = 测量槽) / a4+a5 标签缓冲宽高 (CMap+64/+68) / a6 区记录 / a7 字形输出描述符 (双可增数组 20B/元 + 8B/元, 计数族 +48 起载荷) / a8 输出位图缓冲。入口门 = 区名空串 → 返 0。

**主流程五段** (定案, 全有体内证据)。 ① 扫描省表收本区省份, 任两省 x 差 > 宽/2 → **日期线回绕旗** (bbox x 偏移整体 +WIDTH); ② 逐省按 bbox 遍历像素省表 (CMap+2096 → +24 u16 表), SSE2 四路累加 Σx/Σy/Σxy/Σx²/Σy²/count/minmax; ③ 最小二乘双回归 (y 对 x / x 对 y) 得两候选基线 = 回归线在 min/max 主坐标处端点对; ④ 端点 ±3 像素法向偏移成 6px 带, 两长边光栅化 (sub_1422EC290) → sub_14164A8E0 评分 (带内连续命中最长跑, ≥8 元素且 dword_1430C76A8 ≥ 2 时 SIMD 4 路最近锚点距离²平局判定), 长者胜; 第二基线平方长 ≥ 第一 ×1.2 → 改选; ⑤ 区名测量后超密度预算进**空格适配循环** (名串前迭代插空格 ≤19 轮重测量至测量宽 ≥ 预算, 呈现意图未决) → 基线方向构造旋转基 (sub_1424FC0F0 归一 + 法向) → sub_142299FC0 定距字形布局填 a7 双数组 (×1.5 增长) → sub_141648A10 (17 参) 按字形位姿旋转写入标签位图。

**评分器宽容门三态** (sub_14164A8E0): 映射[省]==area ∨ desc+210 bit1 ∨ (desc+210 & 3)==0 ∧ 旗A; 预剪枝从头剔除非本区引导像素 (memmove 移除)。**错误路径** (:771/:779/:786, 通道 65540) = 同文案 "No points for area name, should never happen! in: <区名>" 三形态 — 有州对象附 State 名+ID, 无州附 Province ID, 无省对象附 Area ID。

#### 4.35.36 后效体积装载域 (posteffectvolumes.cpp; 2 函 — reader 四键 + 装载后构建器 values 父链继承)

CU = `hoi4\source\graphics\posteffectvolumes.cpp`。宿主 CPdxPostEffectVolumeManager 布局见 §4.00 (s4_00:810); 本节补 reader 键表与下半段构建器 (书原载上半段)。

**reader 0x141288FE0 四键** (定案): 12688 posteffect_values → 读 SPostEffectValuesReader (160B) push +280 数组; 12690 posteffect_volume → 读 SPostEffectVolumeReader (200B), 门 = 首串非空否则 :488 "No posteffect_values_day scripted for %s" 报错不入 → +304; 12691 posteffect_volumes → 直读宿主本体; 12696 posteffect_height_volume → 读 SPostEffectHeightVolumeReader (112B), 门同 :503 → sub_141282920 装入 **+328 = reader 数组 {data@+328, count@+340}** (非单纯挂点)。三 reader vftable 符号直证。

**SPostEffectValuesReader 160B 全布局** (定案): +8 name 串 (FNV-1a 32 查重键) / +40 父 values 引用名 (继承链) / +72 lut_day 贴图名 / +104 has_lut 旗 / +112..+159 六 8B optional {f32 值, u32 has} — 覆盖字段与默认全局全部实名 NGraphics defines: MIN_HDR_ADJUSTMENT (dword_1433371D8) / MAX_HDR_ADJUSTMENT (14333728C) / TONE_MAP_MIDDLE_GREY (143337398) / BLOOM_WIDTH (143336F38) / BLOOM_SCALE (143336FD8) / BRIGHT_THRESHOLD (143337078)。

**装载后构建器 0x141288170 三段** (定案): ① values 物化 — +280 逐元素 FNV 查 +128 哈希表 (重名 :544), sub_141287030 递归收集父链 (+40 引用名线性找父) 后**逆序逐层覆盖**: malloc 32B 运行时条目 {贴图句柄@+0, 六 f32@+8..+28} (默认 = 六 defines, 每层 optional 有值即覆盖), 贴图名取名单末层 (+72) 查句柄 (失败 :575), 挂哈希表 value 对象 +48; ② height volume 物化 — +328 逐 112B 元 → malloc 16B CPdxPostEffectHeightVolume {vftable, u32@+8, u32@+12} → 查 e+40/e+72 两 values 名 → 40B 元 {体*, values*, values2*} push **+192 运行时向量** {data@192, count@204}; count==0 → :612 "No post effect height volumes, should atleast have one for base values." 全局门; ③ box volume 物化 — +304 逐 200B 元 → malloc 72B CPdxPostEffectVolumeBox {min/max = center(e+168..175) ∓ size(e+180..187)/2 逐轴, u32@+32 = *(e+192), vtable[3] 虚初始化} → 查 e+40/e+72 (必填) + e+104/e+136 (可选, 缺失写 0 仍 push) 四 values 名 → 40B 元 push **+216 运行时向量** {data@216, count@228}。错误形态 = PdxError 抛出形 (sub_1424C8950 + sub_1424C8E60), 非 B51/B52 断言门。

#### 4.35.37 渲染元件杂件三面 (df304 收尾 — entity_sprite / gamebitmapfont / HLSL builder 双后端 / 模块选择器 GUI)

**舰船 3D 查看器精灵 (entity_sprite.cpp 两函, 定案)**: 族身份由日志 :41 "Ship 3d viewer settings reloaded!" 钉死; 0x141DCC090 (12 行) = 设置热重载回调 (sub_141DCC5A0 + 日志)。**SetEntity (0x141DCCD70, 222 行)**: 门 = sub_14222BD90(sub_14222BDB0(a1, key, flag)) 返回对象 byte+161 == 0 (语义待裁, 推定重入/挂起旗); 缓存 key 串 a1+1464 (SSO) 比对, 相同只走尾部刷新; 变更 → 销毁旧实例 +16 (_CurrentEntityInstance, assert 直证) → sub_142291330+sub_142293530 按名查原型 (+8) → sub_14228CD30(原型, 0, 4, 0) 建实例 (+16; 第 3 参 4 待裁) → float4 常量 (x = min(3, 值−1)) 经 sub_142290350 下发常量槽 32; 未命中 → entity_sprite.cpp:318 "Unable to find entity for key '%s'"。就绪后播 **"idle"** 动画 (dword0 = 75 待裁; +1497 旗 0 则 dword2 = 1.0f, 推定倍速旗) → 恒等四元数复位 + xyz 取全局 dword_1430B6038/3C/40 (推定缩放) → **sub_14228D730(实例) = §4.35.17 dt=0 初始化更新, 其唯一调用点本函坐实 (互证零冲突)** → +24 写 16B 常量 (语义待裁) / +40 写两枚 −FLT_MAX (推定最小包围盒复位)。布局 (高置信): +8 原型 / +16 实例 / +24 16B 常量 / +40 最小值对 / +1464 缓存 key / +1497 倍速旗。

**单位图标字形 (gamebitmapfont.cpp 两函, S10 消费侧新细目, 定案)**: 两函同构 = sub_141640E60(a1, 名, &下标) 按名查字形条目; **图标 = 图集帧横向切片** (U = {下标/帧数, min((下标+1)/帧数, 1.0), 0, 1}); **字形 +416 = 图集纹理 id; vtable[15] (+120) = 帧数 (GetFrameCount)**; sub_142407010 = 图集宽查询 (**读出后除以 vtable[15] 帧数得单帧像素宽**, 随 UV 一同入 sub_14229FFB0) / sub_1424071E0 = 句柄 / sub_14229FFB0 = 出 quad。断言: gamebitmapfont.cpp:218 "rendering a unit icon with no name" / :182 "getting width of invalid unit icon"。字体对象 +13872 一次性初始化旗 / +13864 = malloc(0x60) 工作块 / +72 → 子对象 +368 图集纹理表。

**HLSL 着色器源码组装双后端 (gfx_dx9_hlsl_builder / gfx_dx11_hlsl_builder, clausewitz pdx_gfx, 定案)**: 同骨架 = 清输出串 → `#define VERTEX_SHADER`/`PIXEL_SHADER` (stage 分派) → 遍历 defines 数组 (a5+12 计数 = 引擎自定义容器形制, 元素 32B) 逐项 `#define <名>` → 公共 defines 头 (懒加载缓存) → stage 专属段 → sub_14240C110 找主码追加 (失败 dx9 :183 / dx11 :135 "Failed finding main code %s" 返 0)。**差异表**:

| 维度 | DX9 (0x1424274B0) | DX11 (0x142426390) |
|---|---|---|
| defines 头 | gfx/FX/defines_hlsl.fxh | gfx/FX/defines_hlsl_dx11.fxh |
| 头缓存全局 | qword_1430BFE10 / 旗 1430BFE20 | qword_1430BFDF0 / 旗 1430BFE00 |
| 懒加载同步 | **SRWLOCK 独占 (stru_1435DD588)** | **无锁** (双重装载末者胜, 推定无害待裁) |
| 采样器段 | **有**: 数组 a3+(stage+1)×128, 元素 112B, 逐项 `sampler %s : register(s%d);` (s0..sN 直证) | 无 (SM5 资源绑定不经 register 串拼) |
| 主码前专属段 | 无 | sub_142426A10 |
| 主码后段 | sub_142427970×2 + sub_142426D00×2 | sub_1424267A0×2 + sub_142426D00×2 (sub_142426D00 = 两后端公共尾段, 内容未析) |

**DX9 着色器创建消费端 (gfx_dx9.cpp 两函, 新收)**: 0x142418580 像素 / 0x1424186D0 顶点 — 同骨架 = 源码组装 0x1424274B0 (上表双后端) → 24B 编译产物持有器初始化 (sub_140F90F00 = sub_14011DF40, +0 = shader code 指针槽) → 编译 sub_142417B40 (src, profile, flags, blob; .scache 读写者 §4.28) → 释放旧着色器 (obj vtable[2] = Release) → **设备 vtable 槽创建**: **+848 = CreatePixelShader** / **+728 = CreateVertexShader**。差异: profile "ps_3_0" / "vs_3_0"; 编译第 3 参 flags = 0 / 16; 旧对象槽位 a2+8 / a2; 失败日志 gfx_dx9.cpp:1644 "Failed building pixel shader %s" / :1599 "Failed building vertex shader %s" (CLogStream 一行式, 同 §4.12 events ⑤ EH 胶水形态)。设备对象取 `*(a1+8)`。

**GUI 脏化收尾三连模式 (模式级发现, df304)**: `vfunc+128(elem+48); byte(elem+165) |= 0x10; vfunc+128(elem+48)` — 装备模块选择器 (+1424 元件) 与特殊项目视图 (+8 容器) 同款; **0x10 = 脏/关闭位** (与 §4.31 CWindow +117 bit4 显隐旗同址异类待裁)。


**pdx_audio.cpp 音频管理器四张名字哈希表 (定案)**: 管理器 (= CAssetFactoryAudio+24 句柄) 四子表 — sound@+2088 (查表 0x1423B77A0, 缺名流式日志 :337) / soundeffect@+2128 (查表 0x1423B7110, a3 控缺名警告 "Missing sound effect: %s" :1033) / falloff@+2152 (注册 0x1423B66E0) / music@+2192 (查表 0x1423B6140, "Could not find music named %s" :1356)。条目统一 48B {+4 占用/探针字节, +8 名串 SSO (len@+24/cap@+32), +40 对象指针}, 表尾哨兵 = data+48×(pad+1+mask), FNV-1a 32 位。falloff 注册: 未命中建条目默认 {+36=100.0f, +40=1.0f, +44=1}; 已存在 = 覆盖通道 (旗 byte_1435BA0AB, 语义待裁) 或 "Falloff with name '%s' already added" :1085。


**gfx_dx11.cpp 三槽机制增补**: EndFrame/Present = 槽 9 (0x142414D10): deferred 槽 688 跨距 {+664 单旗, +672 ctx, +680 command list}, FinishCommandList = ctx vt+912; **hr == 0x887A0005 (DXGI_ERROR_DEVICE_REMOVED) → GetDeviceRemovedReason (设备 vt+312)**; Present = swapchain vt+64, **0x200 = DXGI_PRESENT_ALLOW_TEARING (推定)**, 帧计数 %3 三缓冲轮转。GfxSetVertexBuffers = 槽 39 (0x142415700): IASetVertexBuffers 包装 (ctx vt+144), 缺省步长 = 内部对象+80, 断言 "invalid input buffers in GfxSetVertexBuffers" :1978。UploadTexture = 槽 67 (0x142415DA0): UpdateSubresource 包装 (vt+384), 参数块 {+8 数据, +32 宽, +36 高, +52 可更新旗}, 断言 :3027 "Trying to update texture with null resource" / :3033 "Textures does not support updates, declare as dynamic"。

**pdx_cloudstorage_steam.cpp 云存储域 (整域新录)**: **CSteamCloudFile sizeof = 144B**, 布局 = +80 云内路径名 SSO / +112 当前大小 / +120 远端大小回读缓存 / +128 流句柄 (-1 = 未开) / +136 开旗。**OpenStream 0x1423DD8E0 / CloseStream 0x1423DCA50** 幂等对 (已开/未开各 WARNING :472/:520); **Write 0x1423DDFF0** = (ctx+24) vt 槽 0 写 + **ctx+40 云用量累计器** (±新旧差核算), "Failed to write file." :447 = **整文件写**; **WriteStream 0x1423DE120** = (ctx+24) vtable 槽 10 流写 (句柄 = file+128; ctx = file vtable 槽 15 + 槽 9 可用门同构); 未开流 (+128==−1) :498「WARNING! Stream to this file is not open.」/ 写失败 :507「ERROR! Failed to write to stream」(均 B51, 闩 byte_1435DA0E6/E7 落既有连号区间) — 与 Write 同族异槽配对; **CreateFile 路径 0x1423DCE30** = malloc 0x90 → ctor sub_1423DC380 → push 进 ctx+56 数组 (书 RTTI 行 CSteamCloudStorageContext 互证), "Could not create file, perhaps you should check how much space you have." :238。云可用门 = 上下文 vt 槽 9; 断言闩 byte_1435DA0E0..E9 连号。方法名全为推定 (无 RTTI 槽名)。

#### 4.35.38 加权随机选型核 (weightedrandom.cpp; clausewitz pdx_core 通用层)

#### 4.35.39 前端背景轮换计时器 (frontend_background_manager.cpp; 1 函 = sub_141CC9670, 定案/间隔全局语义推定)

#### 4.35.40 位图字体逐字符颜色查找 (bitmapfont.cpp; 1 函 = sub_14229A7C0, 定案/表基待裁)

#### 4.35.41 GL 图元枚举映射 (gfx_opengl_enums.cpp; 1 函 = sub_1424447E0, 定案/成员命名推定)

#### 4.35.42 粒子修饰符记录打包簇 (pdx_particle.cpp 高置信; 5 函 = 打包 0x1423F1BE0 + 宿主重建 0x1423F3AC0 + 辅助三件, 高置信)

**sub_1423F1BE0(ctx, record, slot)** — 修饰符记录 → 发射实例槽递归打包: record (顶层 2296B / 子代 2304B 同尾布局) 消费 +1872 采样数 / +2272 子修饰符向量 (2304B/条, count@+2284) / 72B 曲线槽 [0][1][2][3][12][13][14] (曲线对象 +0 = 求值函数指针, ABI `(curve*, ctx+32, ?, 0, 0, dest, 1, 4, 0, 0)` 尾参待裁)。**实例槽 (≥136B 头)**: +0 112B 行向量 / +24 48B 向量 / +48..+71 常量块 (曲线[12][13][14] 输出, vec3 双份复制 48..59→60..71) / +80..+88 曲线[0][1][2] 输出 (+80 **取负** = Y 翻转推定) / +96 曲线[3] / +72..+108 状态字 (收尾 +108=1/+92=0/+100=1/+104=0) / +112 136B 叶向量。网格展开: 叶数 = 采样数×子数, 行记录 112B 的 **+100 = cols×i (该行叶段起始号)**, 逐子递归打包 — 同一子集按采样行重复展开 (GPU 逐采样实例化布局推定)。**宿主 sub_1423F3AC0(holder, entry)**: holder = {+0 = 208B 注册表条目 (§4.35.26) / +8 136B 叶向量 / +32 上下文 / +40 10504B 块向量}; entry+160 修饰符向量 (2296B/条) 逐条打包; entry+184 发射源 A 向量 (120B/条) 逐条扫 **+0 型 dword ==4 才处理**: 栈暂存 10504B (清 256B 头 + 9216B 体) → 入块向量 (1.5× 增容) → 尾调 sub_1423FEA10(块, holder+32, *(记录+112)) 后初始化。辅助 = sub_1423F1B20 (叶向量收缩) / sub_1423F39E0 (叶区间拷贝) / sub_1423ED0C0 (136B 叶初始化)。

#### 4.35.43 软件表面 blit/缩放域 (0x142107 带; 6 函 — 域定性高置信/TU 未决)

**sub_142107F10** = RGBA8 软件双线性缩放核 (标量回退, 恒返 0): 签名 (srcPtr, srcW, srcH, srcPitch, dstPtr, dstW, dstH, dstPitch); 16.16 定点步进 (`(src<<16)/dst`), 7bit 权重 (`128−frac`, 乘积 `>>7`); 中段双线性 4 邻点加权, 边缘相位越界计钳位行列数退化单边加权 (源维 <2 全面钳); 行尾跳过 = dstPitch − 4×dstW。**域内六件**: sub_142107BD0 分派器 (表面锁 + 矩形换算 + dword_1430BA4F0 懒取缓存 (−1 哨兵 → sub_1420D73B0 现算) → SSE 快路径 sub_142108480 返 −1 时落本函标量回退; a5=0 支路 → sub_142107910 4 参 blit) / sub_142107B90·BB0 薄壳对 (缩放/1:1 双入口推定) / 0x142108480 SSE 快路径 (10 xmm, 返 −1 = 拒)。错误串 "Unable to lock source surface" (无 cpp 锚)。

sub_1424447E0 (内部 PrimitiveType 枚举 {0..8} → GL 枚举, int→int 纯映射): {0→0, 1→1, 2→3, 3→4, 4→5, 5→10, 6→11, 7→12, 8→13} = {GL_POINTS, GL_LINES, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_LINES_ADJACENCY, GL_LINE_STRIP_ADJACENCY, GL_TRIANGLES_ADJACENCY, GL_TRIANGLE_STRIP_ADJACENCY} (OpenGL 3.2+ 规范常数直证; 无 LineLoop/TriangleFan/Quads 族 = GL3+ 核心剖面; 方向判定 = 内部紧凑 0..8 展开为稀疏 GL 码, 反向则 GL 的 2/6..9 落空不符); 落空 → :436「INVALID PRIMITIVE TYPE」B51 (闩 byte_1435E1A2C) + 默认 4 (GL_TRIANGLES)。内部枚举成员命名为按 GL 目标反推 (推定), 映射表定案。

sub_14229A7C0 (出参 a3+16 = 16B 颜色 OWORD): a2 == 33 ('!') → 默认色 *(OWORD*)(a1+128) 返 1; 否则 entry = a1 + 48×a2 — 自定义色门字节 @entry+272 → 色 OWORD @entry+304; 无自定义 → 静态回退表 unk_1434690B0 (同 48B 步距: 门 @+0, 色 OWORD @+16); 皆无 → 格式化日志 4096: 可打印域 (a2−32 ≤ 0x5E, 即 32..126) 走「...character '%c'」(:2861), 否则「...character id '%u'」(:2857), 返 0。字符表步距 48 定案; 表基相对 a1 的定位待裁。

sub_141CC9670: v5 = 当前时钟 (sub_1422333C0 单例 → sub_142233480, f64) − *(double*)(a1+1672) (上次切换时刻); 阈值 = dword_143335C5C (f32 秒) 经 1e-5 定点取整回读 — PE 验算 = `result = (int)((x≥0?1:0) + x×1e5) − 0.5`, x ≥ 0 时 result = x×1e5 (阈值向上取整到 1e-5 网格); `v5 ≥ 阈值` ∧ a1+72 窗口未隐藏 (`*(byte*)(*(a1+72)+165) & 8 == 0`) → CLog **772** :158「new one selected」+ sub_141CC7ED0() 选新背景。前端背景静态库已收 §4.26; 本件为运行期管理器。dword_143335C5C 推定 = 轮换间隔秒数, 写入方未查。

选型核 0x1424F0700 (定案; `(TotalWeight i32, 权重容器 {data@+0, count@+12}, rand u32)` → 命中下标 int):

| 项 | 定案 |
|---|---|
| 退化门 | count == 0 → 返 −1;TotalWeight == 0 → 断言 "TotalWeight != 0" (:133, 闩 byte_1435E3F28) 返 −1 (断言门关时静默返 −1);−1 = 双态哨兵 (零权重 / 扫尽, 后者在权重和 < TotalWeight 时可达) |
| 阈值 | threshold = rand 绝对值 × 2^−31 (4.656612873077393e-10, double 域) × TotalWeight 绝对值;两输入均取绝对值 (符号位无符号右移技巧, IDA 位运算展开);含 2^63 回绕守卫 (≥ 9.223372036854776e18 时减 2^63, 保 i64 截断安全) |
| 扫描 | 前缀和 cum 累加 (权重 ≤ 0 的项跳过不计),(int)threshold < cum → 返该下标;扫尽 → 断言 "Failed to get random index" (:158, 闩 byte_1435E3F29) → −1 |
| 关联 | 邻函 sub_1424F0890 (§4.35 idpair 选优段已载, 带 file:line 哈希参) = 本核的 SIMD 非断言包装 (**定案**): 单行尾调 sub_1424F02E0(a1,a2,a3,0xFFFFFFFF); 总权重 0 / 穷尽返 a4 哨兵而非断言; 阈值公式与 sub_1424F0700 逐字同构 (d4054 收口) |

#### 4.35.44 GLEW 初始化巨函 (glewContextInit 0x142438B50 + glewInit 包装 0x142441920 + wglewInit 0x142441940, 定案/精确小版本待裁)

**0x142438B50 = glewContextInit()** (GLEW 静态链入 hoi4.exe; 5,472 行中前 794 行为局部声明表, 逻辑区无 EH 噪音): glGetString(0x1F02 GL_VERSION) 手工字符解析 (无 sscanf) -> 15 级版本旗阶梯 **byte_1435E1428..1436 = GLEW_VERSION_1_1..4_2** (阈值回落逐级清 0; 142A = 1.3 导出镜像零读方 / 142B = 1.3 装载门真消费); glGetString(0x1F03 GL_EXTENSIONS) -> 扩展串区间 [start, end] (NULL 兜底空串 — **core profile 下扩展旗全灭盲区**, 靠兼容 profile 或 experimental 强载)。**扩展旗库 = byte_1435E1437..15D8 共 418 个** (首旗 GL_3DFX_multisample, 尾旗 GL_WIN_swap_hint; 搜索 392 次经 helper **sub_142438A60 = _glewSearchExtension(name, start, end)**, 首批 ~10 个内联); 每扩展标准序 = 旗置位 -> `if (旗 ‖ byte_1435E15D9)` -> wglGetProcAddress 族 -> 旗改写 = 「函数指针全部实际可解析」(**byte_1435E15D9 = glewExperimental**, 跨函恰 2 消费者 = 本函 + wglewInit; experimental 置位时旗仅剩装载结果语义)。**338 个 GL 函数指针全局** (qword_1435DD598 首 = glCopyTexSubImage3D .. qword_1435E1420 末 = glAddSwapHintRectWIN)。**版本子装载器实名**: sub_1424368D0/36E80/37450/376B0/38210 = _glewInit_GL_VERSION_1_3/1_4/1_5/2_0/3_0; sub_1424363E0 = _glewInit_GL_SUN_vertex。无 KHR_debug、无 4.3+ core 探针 -> GLEW 版本窗口 1.7.0/1.8.0 (精确小版本待 wglewInit 批查 WGL_EXT_swap_control_tear 仲裁)。**家族三件套**: 0x142441920 = glewInit 三行包装 (contextInit → !r 则 wglewInit); 0x142441940 = wglewInit (3,665 行, 同 experimental 级联同构); 上游双调用点 sub_142422AF0 / sub_142422530 (S1 设备创建簇, GL2/GL3 变体分工未决)。

#### 4.35.45 libpng 1.6.16 PNG 写出器与图像 I/O 函数表 (1 函 = sub_142454F20 + 表初始化器 sub_1424543C0, 定案/表属类名待裁)

**sub_142454F20 = PNG 写出器** (libpng **1.6.16** 静态链, 版本串直证; 图像 I/O 函数表 sub_1424543C0 槽[9]; 16 槽表: 槽[8] = 装载器候选推定 / 槽[14]/[15] = charNode::raw_length 符号直证域属; dword_1435E1A5C = 表 init 第二参 = 错误输出模式旗, libpng 错误经 error_fn longjmp 抛串 catch 消费同旗)。**API 映射 22 件** (0x14246A890 = png_create_write_struct / 4681C0 = create_info_struct / 46C270 = set_longjmp_fn + setjmp 256B / 46A950 = destroy_write_struct / 471580 = set_write_fn (io = {a1,a3} 打包) / 471AB0 = set_IHDR / 46AB10 = set_compression_level (level 1..9 门) / 471DF0 = set_iCCP ("Embedded Profile" ICC 串, data = img+BC70 {len@+4, data@+8}) / 4726A0 = set_tRNS / 471CB0 = set_bKGD / 46AF00 = write_info / 4714E0 = set_swap (16bpp) / 471480 = set_interlace_handling / 46B440 = write_row / 471840 = png_malloc / 471BB0 = set_PLTE / 46AD20 = write_end / 471810 = png_free)。**入参开关**: a5 bit0-3 = zlib 压缩级 1..9 / bit8 = 无压缩 / bit9 = Adam7 interlace。**色型支**: 源枚举 B830 {0 灰度→color 0 / 1,3 调色板→color 3 + PLTE / 2 RGB→color 2 / 4 RGBA→color 6}; IHDR 位深 = 调色板 ? min(位深, 8) : 16 (**16bpp swap 真实使用**); **行写出倒序** (源位图底行先行/DIB 行序); 32bpp→24bpp 降深支 (malloc 3x宽 + sub_14244D1B0 转换); **PLTE BGRA→RGB 重排** (每 4B 源元取 [2],[1],[0])。

#### 4.35.46 顶点缓冲填充簇 (接口工厂 sub_142111EF0 +96 槽; 1 函 = 0x142113710, ABI 定案/簇归属推定)

**接口工厂 sub_142111EF0**: sub_1420FFE60(1, 624) 分配 624B 接口对象 + 680B 伴生 (+608..+664 拷入 sub_142121A70 构造 64B); +40/+48 = UserMathErrorFunction 占位; **+96 = 本填充函数**; +240 起从静态模板 off_1430BA598 拷默认槽 32B。**0x142113710 填充 ABI**: sub_1420F6A80(a1, 20×count, 0, a2+8) 分配 (失败返 **0xFFFFFFFF**, 成功 *(a2+16) = count 返 0); **顶点 20B** = {+0 f32 pos_x = a14×src_x, +4 f32 pos_y = a15×src_y (双轴缩放), +8/+12 f32 uv (a3==0 填 0), +16 dword 附加流 (语义未决)}; 位置/uv/附加流三源各带 stride; **索引三态** = a13: 4 = u32 / 2 = u16 / 其余顺序递增 (a11==0 时 a10 = a12)。簇归属推定 = 2D 矢量图形顶点 (USMapArrowVertex 族, §4.35 CMapArrow 簇仅类名级收录; 无 COL 直证待裁)。

#### 4.35.47 24/32bpp BGR↔RGB 像素格式转换内核 (1 函 = 0x14216B410, 高置信形态/类归属未决)

0x14216B410 (纯算法, 零 xref 零断言 — 引用走数据段函数指针): 上下文描述符 a1 = {源 ptr@+0, 源 stride@+20, 目标 ptr@+24, 宽@+32, 高@+36, 目标 stride@+44, 源格式对象@+48, 目标格式对象@+56, 填充 alpha@+83}; 格式对象 = {+8 第 4 通道存在旗, +17 像素字节宽 (3/4), +43 alpha 移位 (实测 24)}。**转换矩阵** = 目标字节序恒 [src[2], src[1], src[0], X]: 4B→4B dword 打包 (src[0]↔src[2] 交换, alpha 直通) / 3B→4B (预计算 fillAlpha 填充) / →3B 逐字节交换丢弃 A — 标准 **BGR(A)↔RGB(A) blit**。**Duff's device 8 路行展开** (`switch (宽&7)` 直落 + (宽+7)/8 主循环), 行尾双 stride 换行。

#### 4.35.48 CGraphics sprite type 派发器 (1 函 = 0x14223A770 + 单件派发 sub_142355FA0, 高置信)

0x14223A770 (CGraphics a1, 进度回调 a2, ctx a3): **表形状** = +256 总数 / +260 桶数 / +264 桶指针表 (桶 = 链式集合 {val@0, next@8}, 遍历确定性)。**双路按设备 ABI 槽 2 GetOwnBackendId (off_1430BF7C0)**: **ret==1 (dx11) → 异步路** = 桶表收集进 vector → std::function 打包 (40B 捕获块, functor vtable **off_142B3DD10** 新录) → `sub_1424D4D10(job, &fn, "Long Task")` (Long 池提交口) → 泵循环 `while (!sub_1424D5400(job)) { 回调(ctx, done, total); sub_1401BA490(&10ms) }` (到点等待器每轮睡 10ms) → 收尾引用计数释放; **其余 (D3D9/GL) → inline 路** = 逐节点 sub_142355FA0 + 进度回调。**dx11 才异步** (后端 id 决定并行化, 非设置驱动)。**sub_142355FA0 = sprite type 一次性惰性派发**: sprite type 对象 {+64 过滤类别 i32 (0 = 全部), +68 已处理闩 u8}; 过门 → +68 = 1 → vtable[9] 无参调用; 与 df186 DeInit 侧释放通知件同族对偶。**调用方两站** = CGraphics::Init 预 init (df186 已收) + **装载链图形步** (进度组 5 → 6, 进度回调 = **sub_1401ADA70** 加载屏回调新录; 与 §4.28 InitBase LOADING_MAP_SPRITES 链互证)。

#### 4.35.49 S4 渐变边框 case-9 变体处理器 (1 函 = 0x140F3A680, 定案 (结构))

0x140F3A680 (owner a2, a3): 调用者 = 家族分发器 sub_140F33D50 (2 参形 case 9) 与 sub_140F3AC50 (3 参形 case 9); a2 = 条目数组 owner {data@+0, cap@+8, size@+12, 分配器@+16}, a2+73 置 1, a2+76/+80 抄全局 dword_143333188 / dword_1433328B0 (样式参数, 推定)。断言三站 (前二与姊妹函共享闩): gamestate.h:1125 "_pInstance && \"gamestate unitilialized\"" (闩 byte_14332ED00, 引擎原文拼写错误照录) / :1126 "_ThreadForbidCount == 0" (闩 byte_14332ED01, _ThreadForbidCount = TLS+16) / gameitemdatabase.h:142 "_pInstance && \"Instance not created.\"" (闩 byte_14332F589, 库单例 qword_14332F0A8)。**重建段**: `*(gs+8)->vt[2]` 取引擎侧源表 {data@+0, count@+12}, a2 size ≠ count−1 → 全毁重建, i=1..count−1 逐条 malloc(0x88) = **136B 条目** (ctor sub_141596C00), **索引 0 跳过**; 尾 a3→1 = 全量刷新旗。**136B 条目布局 (ctor 定案)**: +16 = off_143085170 分配器 vtable / +24 与 +48 = 两个 24B 子块 (+24 = int 集合 {begin@+24, count@+36}, 主函 sub_140F33600 二分查找) / **+76 i16 = −1 哨兵** (后写 id) / **+80 qword = 1.0f** / +88..+120 零 / **+128 = a2 回指 owner**。**颜色源三态 (定案)**: ① 源条目 +184 非空且 +210 bit0 → 取缓存 item +168; ② 否则 +200 非空 → sub_1415A5560(+48 句柄) 间接解析; ③ 都无 → gameitemdatabase 兜底 (函数级 static 注册串 **"ocean"** → sub_1403BD130 名表查 item)。**着色**: item+80 起 16B = RGBA 浮点块拷入栈上 CColor → sub_14159C260 置色 → sub_14159C3D0(条目, 127) (0x7F, 推定半透上限, 待裁) → sub_141598430 写 id (占 +76 哨兵位) → sub_14159C350(0,0) 收尾。**CColor 布局 (高置信)**: {vtable@+0, r/g/b/a float @+16/+20/+24/+28}; ctor sub_14224BEE0 (默认 1.0f×4), alpha 写 = sub_14224C7E0 (+28)。gs 侧源表条目字段: +164 (u32 key) / +184 {+168 item 缓存, +210 bit0 有效旗} / +200 {+48 间接句柄}; 源表身份 (州/区域) 未决。

#### 4.35.50 CGameGraphics::Init3DTypes 体形态 (1 函 = 0x142238FD0, 定案)

0x142238FD0 (CGameGraphics* a1; 调用图位 §4.35.6 / s4_28 InitBase 步 840): **3D 类型注册表装载**。数据面: +1320 = 3D 类型计数 (进度分母, 高置信) / +1324 = 桶数 / +1328 = 桶数组 (**链式哈希集**, 桶元素 = 节点 {type\*, next})。执行: sub_14222BDB0() 进度上报器单例 → 门 `off_1430BF7C0() == 1` (async 模式查询, 数据槽被 IDA 渲染成带参调用失真): 同步路 = 直扫桶链逐类型 `(*(type vtable+72))(type, a1)` (**槽 [9] = 各类型初始装载槽**, 与 CPdxMeshType [9] .mesh 装载同位), 每件 sub_14222E270(v44, 3, ++进度, v41, 0); 异步路 = 类型指针收进局部向量 → 任务闭包 (malloc 0x28, **functor vtable off_142B3DD20**, 按引用捕获 {向量, 上报器, 进度写点, a1}) → sub_1424D4D10 以名 **"Long Task"** 发射 → 主线程 `while(!sub_1424D5400(任务))` { 进度泵 sub_14222E270(op=3) + sub_1401BA490(**10ms** 等待) }; 任务对象 InterlockedExchangeAdd 引用计数。尾: sub_1423FDAE0() 特效库单例非空 → sub_142294270 + sub_142293DF0 两步图形侧续 init。与 §4.35.48 sprite type 派发器同族双路形态 (functor vtable 相邻 B3DD10/B3DD20)。

#### 4.35.51 省份堆叠优势单位选择与择配链 (1 函 = 0x14192BF60 + 调用链 2 函, 结构定案/对象字段待裁)

0x14192BF60 (out {ptr,id} 对, 上下文 a2): 省份单位堆叠「**优势单位**选择器 + 优势方→目标择配」(单位图形名解析链顶层; 消费方 0x14128E9A0 = provincegraphics.cpp:210 "we shouldnt show air or navies like this. something is fishy" 断言, 闩 byte_143389FBC, 结果经 sub_142293790(结果, "naval_move") 名核查)。调用链 = 0x14192C590 (缓存薄壳: a1+8 已算旗 + vtable+64 getter; 名注册表直查 sub_142293530 未中落 B740) → 0x14192B740 (主实现: 复合名构造 sub_14192B2C0 = 基名 + `(u8)*(a2+1200)` 字节参 + 第二串; 无效对象走 +504 缺省件路) → 本函。执行序: 内嵌视图对象 (+968/:+952 二选一 +24 入视, sub_140C7E7E0) → 缺省件 (sub_140BA03A0: +416 优先, 否则全局缺省; +16 有效门) → 逐 a2+872 数组 (16B 元 {ptr,id}, count@+884) 过滤 (旗置位按 id `sub_140C95730==v46` / 否则按分组键 `*(v13+1240)==v7`) → 排序 (≤32 插排 sub_141929960 / 归并 sub_141929DA0, >256 malloc 缓冲否则 4KB 栈) → 逐有序元素命中即返: 扫 v4+168 容器 {候选, 权重} (count@+180, 排除表 = v4+296 已用对象数组), `sub_14100EA10(v31+784, &v48, *(对象+1008))>0` 门 → **打分 `10×(100×权重 + *(v13+968) + 10)`**, 候选 +1480 打包值 BYTE4 置位时整值直用覆盖公式 → 取最大为目标; 目标 +16 无效则下一元素, 耗尽返 {0,0}。callee 定形态: sub_140BA04B0 = `a1+504` 纯偏移 / sub_140BA04C0 = 拷 +488 起 16B {id, 旗}。a2+872 宿主类 / +968 / +1240 / +1480 打包域语义待裁。

#### 4.35.52 bzip2 压缩端 sendMTFValues (compress.c 静态链接; 1 函 = 0x142388030, 定案)

0x142388030 = **bzip2 压缩端 `sendMTFValues`** (上游 compress.c 1.0.x 指纹甄别; 原书索引行「解码」系方向误判, 已勘)。五重证据: compress.c 专属 debug 串 ("pass %d: size is %d, grp uses are" / "…after MTF & 1-2 coding…") / AssertH 错误码 3001/3003/3004/3005/3006/3007 六连 / nGroups 五档分界逐界吻合 / `BZ2_hbMakeCodeLengths(len, freq, alphaSize, 17)` 调用形态 / 唯一调用方 0x1423874F0 = BZ2_compressBlock (高置信)。**EState 偏移链 21 项 (六段数组首尾相接零缝自洽, 首次收录)**:

| 偏移 | 字段 |
|---|---|
| +72 | mtfv |
| +80 | zbits |
| +108 | nblock |
| +116 | numZ |
| +124 | nInUse |
| +128 | inUse |
| +640 | bsBuff |
| +644 | bsLive |
| +656 | verbosity |
| +668 | nMTF |
| +672 | mtfFreq |
| +1704 | selector |
| +19706 | selectorMtf |
| +37708 | len |
| +39256 | code |
| +45448 | rfreq |
| +51640 | len_pack |

**库族身份表**: hbAssignCodes = 0x142390DD0 (五参严丝合缝) / hbMakeCodeLengths = 0x142391140 / AssertH-fail = 0x1423820B0 / fprintf = 0x14012A5D0 / BZ2_compressBlock = 0x1423874F0 (高置信)。未决: bzip2 具体版本 (len_pack 特化与 rfreq 归一缺失两特征互斥) / AssertH 3002 缺席 / EState 前段字段 (+56/+64/+112/+384..+639, 留 BZ2_compressBlock 批)。

#### 4.35.53 frontend 整帧 overlay 绘制 (1 函 = 0x1420ADC20, 高置信/具体屏面待裁)

0x1420ADC20 (a1): frontend/渲染域整帧 overlay。门 = 渲染就绪 sub_1422370E0(a1+12064) (§4.35:10 设备簇); 尾 = sub_14223D2C0 / sub_14223D8B0 / **EndFrame sub_142238180** / 帧就绪+Present 复合锁存 sub_14223B030。选中元 = `*(a1 + 8×(a1+336) + 320)`: 元+36/44 → a1+12464/12472, 元+24/32 → a1+12476/12484 (每次 sub_1422D9380(a1+12080) 通知), 元+49 word 清 0。a1+12632 接口对象 vtable[5]/[6]/[7] 三连。**批元提交双原语 (新锚)**: sub_1422CBE50(batch@+12688, …) 两路 = ①count 8 + 12×float4 颜色表 + 主色 0xFFC8B8B8 (门 a1+318==0) ②count 3 + **RGB 轴色三元组 {青 0xFF00FFFF, 绿 0xFF00FF00, 红 0xFFFF0000}**; sub_1422CC260(batch@+12640, count=**42**, 数据表 63 float4 常量, 颜色表 = 前 6 黑 0xFF000000 + 后 36 灰 0xFF646464); a1+318≠0 互斥分支走 @12688 count=3。**字体**: sub_142082400(dev, …, **"garamond_12"**, …) (全书首录字体串) + byte_14344F179 门 → 栈拼 "standard_font" → sub_14225DA00。

#### 4.35.54 PdxEntity 实例 spawn 工厂 (1 函 = 0x142288EF0, 高置信; df124 复核无冲突)

0x142288EF0: **272B 实例布局** (+224 = FNV-1a(附件名) 等); 加权模板挑选 = 累和数组末元 = 模 + 二分; 全局兜底工厂 = qword_143468F10; 递归子种子链 = 7919×根; 宿主实体 +312 = 632B/元状态表 → sub_142290520。

#### 4.35.55 bzip2 解码端 BZ2_decompress 与全族 (1 函 = 0x14238C060, 定案; 与 §4.35.52 压缩端成对)

0x14238C060 (2,512 行三窗全析) = **bzip2 1.0.x `BZ2_decompress`** (八重证据: 状态机 switch 10..50 = `BZ_X_*` 41 态全枚举 + AssertH(False, 4001) / 魔数 `BZh` + blockSize '1'-'9' / 块魔数 `1AY&SY` / 流尾 `0x177245385090` + combinedCRC / `alloc(400000·b)` = tt 路 vs small 路 `200000·b`/`50000·b` = ll16/ll4 / GET_BITS 补位环 / selector MTF 双趟相距恰 18002 = BZ_MAX_SELECTORS / 5bit±1 len 表 / RUNA/RUNB 界 0x200000)。⚠ 在音频带下界 0x1423B1AD0 之外属 bzip2 TU (音频带毗邻 = 链接布位巧合)。**解码端 6 函身份**: 唯一调用方 0x142381D60 = `BZ2_bzDecompress` (返回码谱/verbosity 串逐字吻合) ← 0x1422E32C0 断言带出 **`clausewitzlib/zip.cpp:1269`** = 服务于 Clausewitz ZIP 容器读取; 助手 BZ2_indexIntoF = 0x142382120 / hbCreateDecodeTables = 0x142390E20 / unRLE FAST/SMALL = 0x142382640 / 0x142382BA0 (Init/End = 0x142381FB0/0x142381F20 推定); 书已录 AssertH = 0x1423820B0 / fprintf = 0x14012A5D0 互证一致。**DState 偏移链 ~45 项** (含 SAVE_STATE 27 槽, 恢复点 case 34/38-41 复读自洽互证) + BZ2_rNums 表; **版本证据** = 解码端 verbosity 插桩 (`huff+mtf`/`rt+rld` 串 + `return 1` 合并路径) → 非 vanilla 1.0.8 逐字节 (具体版本待裁, 延续 §4.35.52 未决)。

#### 4.35.56 provincegraphics 堆叠槽位装载与距离校验 (1 函 = 0x14128F430, 定案; 与 §4.35.51 同 TU 异函)

0x14128F430: 宿主 **+4568 起三阵列 (39 槽: 12B 浮点 / 2×dword)**; P+196 = ProvGfx; 阈值 100.0 (距离校验); **跳槽集 = {1-8, 11-18, 30-37}**; **移动镜像槽对 1..8 ↔ 22..29**。唯一调用点 = sub_14164F260 (勘误候选: mp_sp survey 将别函扫描段误挂本函, 档案级待裁)。

#### 4.35.57 自动连拍截图管理器 (1 函 = 0x1420A7470, 高置信)

0x1420A7470: 拼 "ScreenCapture/" 路径 → 调渲染后端**截屏槽 off_1430BFA60** (三后端实现由 sub_1424047C0 注册; **手动单张姊妹路 = sub_140B3C4C0 "Screenshots/"** 双通道); 拍毕 sub_1420A7C00 = getenv("FFMPEG_PREVIEWER") + SHELLEXECUTEINFOA **外链预览器**。连拍状态对象与文件名 4 段 append 细节待汇编取证。

#### 4.35.58 内嵌 SDL2 渲染层窗口事件桥 (1 函 = 0x1420FC140, 定案; **新区带登记候选 0x1420C..0x1420FF = SDL2 渲染层, 非 gameplay**)

0x1420FC140 = SDL2 窗口事件桥 handler: 消息码直证 512 = WINDOWEVENT / 1024 = MOUSEMOTION / 1025-1026 = BUTTON / 1792-1794 = FINGER\*; **letterbox 缩放 +448/+452 / 视口矩形 +360/+376 / 隐藏旗 +336**。注册方 sub_1420F6BF0 = SDL_CreateRenderer 形 / 注销方 sub_1420F7940 = DestroyRenderer 形。

#### 4.35.59 师列表窗单位按钮 tooltip 构建回调 (armiesview.cpp; 1 函 = 0x1416A3930, 定案; df77 精化)

sub_1416A3930 (this, hover_elem, **a3 = 3 个 std::string 输出数组** — 原记单串签名修正; 断言 armiesview.cpp:4878 直证 TU): **悬停槽 19 槽** (df77 漏 +224 假军/部署段)。**双委托**: +64 与 +72 双槽 `sub_140C7E930` = 陆军经验 tooltip; +192 委托 `sub_1416BAD10` (1,213 行) = **习服 tooltip** (消费 NAcclimatization::CData+20/+40/+48/+56 = 书 §4.18 CData 行 UI 消费侧首证; 两委托内部逐行未析, 待下钻)。**堑壕三常量 PE 精确匹配** = DIG_IN_FACTOR (0x3336880) / UNIT_DIGIN_CAP (0x337E30) / UNIT_DIGIN_SPEED (0x337EF0) (defines_map_1193 逐项核)。**CArmy+680 = 警告码枚举 (1..7 键全表) + CArmy+590 警告旗** (书未见新字段候选)。第三输出串 = "ctrl+g+s" 快捷键提示。**Debug ID 门 = byte_14332EC69** (非 byte_1435E1B51); 移动枚举第三值 = 3→friend (df77 漏记); df77「色值 0x600/0x6000/0x38000」实为 EH 析构位掩码非颜色 (高置信)。

**SDL_IntersectRectAndLine = 0x1420F4E20 (SDL_rect.c 直证; 定案)**: outcode 助手 sub_1420F4A00 码位 1/2/4/8 与 SDL2 源逐位一致; sub_1420C0EB0 = SDL_SetError; 消费者二函字面串直证 = SDL_DrawLines / SDL_BlendLines — §4.35.58 区带第二函实证。

#### 4.35.60 省界图形生成巨函 (pdxmapborders.cpp; 1 函 = 0x141B204A0, 定案)

身份表:

| 项 | 值 |
|---|---|
| 语义 | 从省位图提取省边界轮廓, 生成带宽度的 3D 带状顶点缓冲 + 256×256 像素分块剔除网格 |
| 唯一调用方 | sub_14127C980 (装载编排主件, §4.35.16③); 宿主 = CPdxMap 实例 |
| 调用形态 | sub_141B204A0(*(CPdxMap+8), CPdxMap+18848, CPdxMap+18872, CPdxMap+18920, 256, +17 ? −1 : 0x10000) |
| 返回值 | u32 = 边界记录条数 (低半; 高半 = 单边界最大顶点数, 待裁) |
| 线程上下文 | 装载期单任务; 每行循环经 sub_14222E270 汇报进度 + 协作让步 |

参数表:

| 参数 | 语义 |
|---|---|
| a1 | 渲染上下文; *(a1+128) = 后端图形设备 (CreateVertexBuffer 槽 35 消费) |
| a2 | 出 = 顶点缓冲句柄数组 (宿主 +18848); vector<u64>, 每分块一个句柄 |
| a3 | 出 = 边界记录数组 (宿主 +18872); vector<20B 记录>, 1.5× 增长 |
| a4 | 出 = 分块剔除网格 (宿主 +18920); 头 16B + (W/256)×(H/256) 个 48B 块 |
| a5 | 256 = 分块边长 (像素); 兼块角点坐标步进 |
| a6 | 单顶点缓冲顶点上限: 0x10000 常态 (u16 索引寻址上限) / −1 = +17 置位时合并单一缓冲 |

CPdxMap 输出槽 (写):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +8 | 渲染上下文* | 透传为本函数 a1; 后端设备 = *(ctx+128) |
| +17 | uint8 | 自建/合并门 (原「未决」已收口): 置位 → a6 = −1 → 全部省界顶点并入单缓冲; 与「索引缓冲」通道行 +17 索引缓冲自建门为同一开关两侧消费 |
| +18848 | vector<u64> 24B | 省界顶点缓冲句柄数组 {data@+18848, cap@+18856, count@+18860, alloc@+18864} |
| +18872 | vector<20B> 24B | 省界边界记录数组 {data@+18872, cap@+18880, count@+18888, alloc@+18892} |
| +18920 | 容器头 + 扁平数组 | 分块剔除网格 {data@+18920, cap@+18928, count@+18932 = 块数}; 元素 48B |

CMap 单例 qword_143339D28 (只读):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +64 | int32 | 地图宽 W (经度方向; 轮廓跟踪 x 走 % W 环绕) |
| +68 | int32 | 地图高 H |
| +376 | 匿名结构* | 高度图 {宽@+8, 高@+12, 行跨距@+16, u8 数据@+40}; 顶点 z 双线性采样贴合 3D 地形 |
| +560 | uint32 | 省表界 (有效省 id ∈ [1, +560)); 兼边界记录预分配基数 (20 × +560 条) |
| +616 | 省静态描述符** 指针数组 | {data@+616, cap@+624, count@+628}; 按省 id 直索引; 描述符 +210 bit0 = 陆/海分判旗 (与 §4.14.6「可通铁路位」同一位两种消费, 不冲突) |
| +2096 | 匿名结构* | 省位图 {u16 数据@+24, 宽@+48, 高@+52}; 每像素一个省 id |

管线 (七阶段):

| 阶段 | 动作 |
|---|---|
| 1 连通分量标号 | 显式栈 4 邻域 flood fill (同省描述符指针判等), 分量号 = 轮廓号; 单像素省 (弹栈计数 == 1 ∧ debug 旗 byte_14332EC69) 告警 "One-pixel province color found at <x,y>." (:195) |
| 2 逐像素边掩码 | calloc(W×H, 4), 每像素 4 字节 = N/E/S/W 四向「邻省不同」旗; 比较对象 = 分量标号 (同省不同分量必不邻接) |
| 3 闭合轮廓跟踪 | marching-squares 式: 步进/转向表每方向 9 int = 3 组候选 (dx, dy, 转向), x 走 (W+x+dx)%W 短弧; 3/4 省共点角点歧义取周围 4 像素 SIMD 掩码归属判定; 每步发射轮廓顶点 (相邻两像素中心均值) |
| 4 分块网格初始化 | a4 重定容到 (W/256)×(H/256) 块, 每块 48B 写两角点 float3, 块内 vector<u16> @+24 = 命中该块的边界下标表 (初始空) |
| 5 带状顶点发射 | 遍历省对 map 逐记录: 段法向 (dy, −dx) 归一化 × BORDER_WIDTH/2 双侧偏移 → 折线变带; 顶点 16B {f32 x, f32 y, f32 z = 高度图采样, u16 侧旗 0/1, u16 折线顶点序}; 块号 = (y/256)×每行列数 + (x/256), 记录下标去重 push 进块表; 累计顶点达 a6 上限切新块 |
| 6 顶点缓冲创建 | 逐块槽 35 CreateVertexBuffer(设备, Block+16×start, count, 跨距 16, 0, 调试串 :1048); 句柄 push 进 a2 |
| 7 收尾 | 释放临时区 (flood 栈 / 掩码 / 占用旗 / 边图 / Block); 析构 std::map 与 vector; 返回边界记录条数 |

记录布局:

| 记录 | 偏移 | 类型 | 语义 |
|---|---|---|---|
| 轮廓记录 16B (引擎分配器, 预分配 20×省表界, 1.5×) | +0 | int32 | 首顶点下标 (Src 全局递增计数) |
| | +4 | int32 | 顶点计数 |
| | +8 | int32 | 配对链 = 同 (省A, 省B) 对既有记录下标, 无则 −1 |
| | +12 | uint8 | 同类旗 (跨界两侧同属非陆地或一侧为省表界哨兵 → 选渲染样式) |
| | +14 | uint16 | 第二遍写入的 a3 记录下标 |
| 边界记录 20B (a3 输出) | +0 | u16 | 省A |
| | +2 | u16 | 省B |
| | +4 | u16 | 带状顶点数 |
| | +6 | u16 | 顶点数 − 2 |
| | +8 | int32 | 顶点基址 |
| | +18 | uint8 | 同类旗 (自轮廓记录 +12) |
| 分块记录 48B (a4 元素) | +0 | float3 | 块角点 0 (像素坐标) |
| | +12 | float3 | 块角点 1 (块矩形 [x, x+256]×[y, y+256]) |
| | +24 | vector<u16> 24B | 命中该块的边界下标表 (去重 push, 1.5×) |
| 顶点 16B | +0 | f32/f32/f32 | x / y / z (z = 高度图双线性) |
| | +12 | u16 | 侧旗 (0/1 = 带之内/外侧) |
| | +14 | u16 | 折线顶点序 |

去重与合并机制:

| 环节 | 方法 |
|---|---|
| 省对去重 | std::map<(u32 省A, u32 省B), int32 记录下标> (sub_141B201E0 原地插入); 轮廓上邻省 id 变化即开新记录 |
| 同省多岛 | 同对多段经配对链 + 记录合并 (首顶点回填 / 计数累加 / sub_141B23390 旋转 Src 顶点区间使折线连续 / 丢弃末记录 / 边图回写下标) |
| 空间索引 | 256×256 分块网格, 每块挂命中边界下标 vector<u16> = 渲染期视锥剔除 |
| 环绕 | x 全程 % W 短弧 (abs(Δx) > W/2 时给较西侧者 +W); 轮廓跟踪/顶点插值/分块坐标三处一致 |

define / 魔数:

| 值 | 语义 |
|---|---|
| BORDER_WIDTH (0x143335FAC) | 省界带宽; 半值 ×0.5 作法向偏移量 |
| 0x10000 | 单顶点缓冲顶点上限 = u16 索引寻址上限 |
| −1 | a6 合并门值 (+17 置位) |
| 20 × 省表界 | 边界记录预分配条数 (每省约 20 段经验上限, 高置信) |
| W/2 | 经度短弧判定阈值 |
| 1010000 ticks | 让步节流周期 (环境串回收) |

关键子函数:

| VA | 语义 |
|---|---|
| sub_14222E270 | 装载进度汇报 + 协作让步 (ctx, 源码行, 当前行, 总数, 0) |
| sub_141B201E0 | std::map 原地插入/查找 (省对表) |
| sub_141B23390 | 顶点区间旋转/拼接 (合并记录时使折线连续) |
| sub_141B22F50 | 边界记录收尾 (配对链并合 / 计数归一) |
| sub_140A60F10 | 高度采样 (CMap+376 u8 高度图双线性, 返 __m128) |
| sub_141B22DD0 / sub_141B20330 / sub_1412793F0 | 分块数组重定容 / 新段就地构造 / 定容路径 |
| off_143085170 | 引擎分配器 vtable ([1] alloc / [2] free) |

> 推定: 步进/转向表 9-int/方向的精确三元组布局 (反编译把两表与 12×12B 初始化序列压同一栈区, SIMD 常量未内联不可直读); 分块角点 float3 第三分量语义。待裁: 返回值高半; a3 记录未用字节。

#### 4.35.61 CWrapWorldShadowMap 构造 (渲染设备域; 1 函 = 0x1422D9670, 定案; df360)

CWrapWorldShadowMap ctor (672B = malloc 0x2A0 直证; vtable 写 +0 直证): 世界阴影贴图包裹件 — 清零 + 挂 world + 后端分支装载采样常量 + 双实例装载 shadowblur FX + 5-tap 高斯模糊常数预置 + 按 44B 描述建渲染目标。**唯一调用方 = CGraphicalMap ctor sub_140B4F9C0** (malloc 0x2A0 → 存宿主 +96; §4.00 CGraphicalMap 段同步增补)。签名 (this, world, 边长=2048, a4 f32 = *(CGraphicalMap+40 对象)+64, "gfx/FX/shadowblur.lua")。

| 偏移 | 类型 | 语义 |
|---|---|---|
| +400 | 16B | 采样常量组 1 (非 D3D9 路装 rdata 常量) |
| +416 | 16B | 采样常量组 2 (后端 id==1 与 id==2 分岔装不同常量 — GL/D3D 系深度/NDC 约定差异候选, 值未决) |
| +432 | 16B | 采样常量组 3 |
| +448 | float4 | texel 向量: D3D9 路 = 计算形 {v8, v8, 1.0, 0.0} (v8 = 0.5/size + 0.5 **半纹素偏移**, D3D9 采样惯例); 非 D3D9 路 = rdata 常量 |
| +488 | i32 | FX 渲染资源 id 1 — 同一 "gfx/FX/shadowblur.lua" 两次 sub_142409E20 (横向/纵向双 pass 各持一实例, 推定; CPdxMeshType +336/+340 同形互证) |
| +492 | i32 | FX 渲染资源 id 2 (同上第二次装载) |
| +512 | f32 | 模糊采样偏移 0.0 |
| +516 | f32 | 模糊采样偏移 1.3846154 (5-tap 线性采样高斯核偏移 18/13) |
| +520 | f32 | 模糊采样偏移 3.2307692 (42/13) |
| +524 | f32 | 高斯权重 0.227027 (经典 5-tap 三件套, 逐位解码直证) |
| +528 | f32 | 高斯权重 0.316216 |
| +532 | f32 | 高斯权重 0.070270 |
| +544 | i32 | 阴影图边长 (现役 2048) |
| +548 | f32 | a4 位型落位 (语义未决) |
| +560 | qword | world 反向指针 |
| +568 | 子对象 (ctor sub_1422CBA50) | 渲染目标持有块: 其 +24 = 目标槽 (释放旧 = 设备 ABI 槽 54 off_1430BF960 / 建新 = 槽 53 off_1430BF958) |

流程: 写 vftable + 清零 → sub_1422CBA50 构 +568 块 → sub_142236CE0 尾插进 **world+1272 容器** {count@+1272, cap@+1276} (×1.5 增长) → sub_1422DB400 后按 **GetOwnBackendId off_1430BF7C0** (ret 0=D3D9 / 1=dx11 / 2=GL) 分支装采样常量 → 双装载 FX → 预置高斯常数 → sub_14240C0A0 装 44B 默认渲染目标描述 {byte0=1, +4=1, +8=3, +12=0, +16=−1, +24=0, +32=0, +36=7} → sub_1422CD1C0(this+568, \*(world+128), 描述) = 换目标。⚠ IDA 陷阱: off_1430BF7C0 的垃圾实参 = 数据槽渲染失真 (真身无参查询); sub_142409E20 的 vector<string> 出参与 sub_1422CD1C0 的 2/3 参被 IDA 吞 (尾参经寄存器)。

#### 4.35.62 STL num_get 数字解析族 (S11 带; char 实例化聚集 0x1411B-C; 定案)

**sub_1411B4B10 = `std::num_get<char, istreambuf_iterator<char>>::_Parse_fp_with_locale`** (1930 行): 流式浮点解析器, 返 2 字节 {低 = 基数 10/16, 高 = failbit 请求旗}。身份直证 = 同表兄弟带完整修饰名 (0x142521554 = wchar_t 版 `_Parse_fp_with_locale`; 0x1425243A4/0x142524E18 = `_Parse_int_with_locale`) + 三调用方 = do_get(float 0x1411C7CA0 / double 0x1411C7E10 / long double 0x1411C7F80) 虚函数体 (骨架 = 800/816 字节缓冲 → errno 保存清零 → strtof 0x14255FC50/strtod 0x14255FC48 → endptr/errno/高字节三重判 failbit)。主流程 = use_facet<ctype> vt+56 宽化 28 字符表 `"0123456789ABCDEFabcdef-+XxPp"` (尾哨兵 unk_1429A1365) → numpunct vt+32/40 千分位/grouping → 符号 → '0' 占位 → '0x' hex 检测 → 整数/小数扫描 (768 位上限, 超限计数) → 小数点 (vt+24 → localeconv '.') → half-up 舍入补偿 (dec 末位 '5' / hex '8' 进位) → 指数 e/E/p/P (int64 饱和累加, 溢出对消 dec ±1100 / hex 1050/4200) → 发指数 (std::reverse 残名收尾)。分组校验 = std::string 复用计每组位数 (≤127), 违例转高字节 failbit。同 TU 0x1411B65F0 = `_Parse_int_with_locale` char 版 (26 字符表)。

| 族件 | VA | 定性 |
|---|---|---|
| use_facet<ctype<char>> | sub_14011DE30 | facet id 惰性注册 (计数器 dword_1435E6870; ctype id qword_1435E6888; C 域兜底缓存 qword_14332ECF8) |
| use_facet<numpunct<char>> | sub_1401453F0 | 同形态 (id qword_14332ED30; 兜底 qword_14332F1F0) |
| istreambuf_iterator sgetc / snextc | sub_1411C6F30 / sub_1411BF0E0 | 迭代原语 (迭代器态 16B {缓冲 ptr@0, 缓存旗@8, 当前符@9}; streambuf gnext@+56 / gcount@+80, underflow vt+48) |
| char_traits::find | sub_14251D050 | (首,尾,符) → 命中指针 (dump 无定义体) |
| facet 槽位 | — | ctype vt+56 do_widen / numpunct vt+24 do_decimal_point / vt+32 do_thousands_sep / vt+40 do_grouping (sret std::string) |
| wchar_t 副本 | 0x142521554 (带名) / 0x142522C7C (无名) | 三副本未 ICF 折叠成因待裁 |

#### 4.35.63 装载屏管理器单例簇 (loadingscreen 域推定; 建拆件 0x140B6F840 + 同簇件 — 新收)

sub_140B6F840 = **装载屏管理器单例的建/拆/再建件**。a1 = CGameGraphics*, a2 = 加载屏对象 (app+872, 0xCC8, ctor sub_140B429A0), a3 = 跳过文本初始化旗, a4 = 强制重建旗。机制: a4=1 且旧管理器存在 → 旧 (manager+48)->vt+128 → 旧 manager->vt+200 → 清两单例全局, **随后 fall-through 重建** (非纯拆卸); a4=0 且已存在 → 幂等早退。建路 = a2 vt+80 按名取 "load_screen" 根窗口 → qword_14333C590; a3=0 时置 tip 轮换截止 qword_14333C5A0 = now + 15.0 (时钟单例 §4.35.39) + 首条 tip 文本入 qword_1430B0860 → manager vt+264 FindWindow("tip") → 其 vt+120 FindWindow("text") → SetText (§4.31) → sub_140B411B0 刷新帧合成; 无条件取 status 容器 vt+136 FindWindow("progressbar") → qword_14333C598 进度条元件 → 其 vt+752 子件 vt+144 推定归零。三调用点: InitLoadScreen sub_140184B30 (0,0 全量首建, §4.28.21) / 前端图形重初始化 sub_140B3D9B0 (a4=1 拆卸重建) / 包装 sub_140174040 (运行期显隐切换, a3=1 跳 tip)。

全局与 widget 树 (定案):

| 全局 / 件 | 语义 | 置信 |
|---|---|---|
| qword_14333C590 | 装载屏管理器单例 = load_screen 根窗口指针 (CContainerWindow, vtable 0x142B45278; 类层级 CContainerWindow ← TWindow ← CWindowObservable; CGuiObject 基子对象 @+48 持独立 vtable 段 = 主段 +632) | 定案 (PE RTTI 直读) |
| qword_14333C598 | status→progressbar 进度条元件指针 | 定案 |
| qword_14333C5A0 | f64 = 下一次 tip 轮换截止时刻 (建/轮换时置 now + 15.0) | 定案 |
| qword_1430B0860 | 全局 32B std::string = 当前 tip 文本缓存 | 定案 |
| sub_140B70520 | 随机 LOADING_TIP_\<N\> 本地化串构造器 (按语言/日期过滤 tip 池, 规则待裁) | 高置信 |
| sub_140B70B30 | 进度/状态发射器 = 三全局唯一消费方 (设备前门 + 15.0s 轮换门 + status/tip 双文本 + 进度条复位 + 单帧合成 + Show→渲染→Hide; 全流程见下) | 定案 |
| sub_140B711D0 | (manager+48)->vt+120 = Show | 定案 |
| sub_140B711F0 | 三步显隐+刷新 (StartNewGame 路径, §4.2) | 高置信 |

> widget 树 = load_screen → tip→text (tip 文本) / status→text (状态文本)·progressbar (进度条)。manager+48 子对象持独立 vtable, 显隐对在其 +120/+128 (§4.6 族形)。

> **+120/+128 显隐指向定案 (读 A 成立)**: +120 = Show / +128 = Hide — 三重直证: ① +48 段 [15]+120 的 guard 要求 (+165 & 0x10) == 0 (非 hidden 才执行); ② 其体调子件 vt+120 并置 +312 = 1, [16]+128 调子件 vt+128 并置 +312 = 0; ③ 即时路径对 +165 bit3 (visible) 置/清, 且 Show 用 +5704 (show_position) / Hide 用 +5708 (hide_position)。显隐槽全表见下。

**sub_140B70B30 全流程 (定案)** — 形参 (CGameGraphics* a1, 状态文本串 a2, 轮换门 a3, 合成门 a4, 状态文门 a5); 20 调用点 (形参序 = gfx, 文本, 轮换, 合成, 状态文), 主消费 = 地图/GFX 装载进度环 ("LOAD_GFX_PDXMAP_RIVERS/TERRAIN/…" 本地化键):

| 步 | 门 | 贡献 |
|---|---|---|
| 1-2 | sub_1422370E0(a1) 设备轮询 (gfx+1288; graphics.cpp:2440/2455 alt-tab 日志) | 设备丢失 → 早退; byte_1430B0880 = gfx+1288 全局镜像 |
| 3 | !qword_14333C590 | 无管理器 → sub_140B411B0(a1, a2, 1, 0) 直渲一帧 |
| 4 | now > qword_14333C5A0 (§4.35.39 时钟单例) | a3 强制 1; 新 LOADING_TIP_N 串入 qword_1430B0860; 截止 = now + 15.0 |
| 5 | 无条件 | manager vt+64 = Show |
| 6 | a5 | status→text SetText (a2) |
| 7 | 内容变化时 (元件 +272 与全局串比对) | tip→text SetText (qword_1430B0860) |
| 8 | qword_1434531C0 | 进度条复位 (sub_140B70AE0: qword_14333C598 → vt+752 子件 → vt+144) |
| 9 | 无条件 | sub_140B411B0(a1, 空串, a4, a3) 单帧合成 |
| 10 | 无条件 | manager vt+72 = Hide; 其返回值即本件返回值 |

显隐槽定案 (CContainerWindow):

| 槽 | 语义 | 证据 |
|---|---|---|
| 主 vtable [8] vt+64 = sub_1422C45F0 | Show | +5752 != 1 门 + show_position + 子件 vt+120 + +312 = 1 |
| 主 vtable [9] vt+72 = sub_1422BE470 | Hide | +5752 != 2 门 + hide_position + (this+48)->vt+528 + 子件 vt+128 + +312 = 0 |
| +48 段 [15] vt+120 = sub_1422C4510 | Show (子件传播) | guard = (+165 & 0x10) == 0; 置 +165 bit3 (visible); 用 +5704 |
| +48 段 [16] vt+128 = sub_1422BE1A0 | Hide (子件传播) | 调子件 vt+128; 清 +165 bit3; 用 +5708 |

> 消费序: 本件 = Show → 渲染 → Hide; sub_140B711F0 = Hide → Show → Show(status 块) 重显序列 (§4.2 StartNewGame 路径)。
> FindWindow 双槽定名: manager vt+264 = 转发桩 sub_1422BDC70 → vt+440 = sub_1422BA280 (containerwindow.cpp:868 断言, 严重度 4096); 另 vt+120 = sub_1422BC460 同族变体。两槽签名均为 (this, 串, bool), IDA 因桩体把形参记为 1 参 (实 3 参) 属失真。status 容器两槽 (vt+120 取 "text" / vt+136 取 "progressbar") 的立即子件 vs 递归差异仍未决。
> 文本元件文本 @+272 (std::string); SetText = sub_1422CA920 (写 +272 + 刷新 sub_1422CB4A0); GetText = sub_140D55DA0 (返 a1+272)。

新定性全局与姊妹件:

| 全局 / 件 | 语义 | 置信 |
|---|---|---|
| byte_1430B0880 | gfx+1288 设备丢失旗的全局镜像 (两消费方 = 本件 + sub_140B70FF0) | 定案 |
| qword_1434531C0 | 72B 装载进度跟踪器 (+12 计数 / +16 与 +40 回调表 / +48 id 哨兵 -1 / +56 与 +64 上下文; 唯一构造点 sub_142257B00 malloc 0x48) | 推定 (真身未决) |
| dword_1434531C8 | 跟踪器自旋锁 (_InterlockedCompareExchange + _mm_pause) | 定案 |
| sub_140B70FF0 | 姊妹件: 同设备前门 + 跟踪器/进度条, 无文本/无 Show-Hide 路径 | 高置信 |

> 待裁: qword_1434531C0 真身 (无类名/源文件串); Show→渲染→Hide 包夹意图 (推定 = 装载屏由 sub_140B411B0 直接合成入帧, GUI 窗仅在合成窗口期内入树以避免截获输入, 或显隐动画被即时路径短路); +5752 状态机其余取值与迁移回调; sub_1422C4070 动画启动器完整语义; 两 FindWindow 槽递归差异; sub_140B70520 tip 池过滤规则; +5776/+5784 音效属性 (形态直证 = 句柄 + 去重播放 id + gfx 通道 qword_143453230, 资源名未取)。
