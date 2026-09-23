-- resource.lua -- 静态资源访问层 (; 自 hoi4_layout 拆出)
-- 覆盖: lexer token 名 / modifier 定义表 / idb 102 库规格 / id 注册表三源 /
-- mods 管理器 / combat_data_entry 静态表 / external_rules / SET 串表 /
-- CDefines。
-- 挂载点每次热重载重取 (file-local 随 re-dofile 重置, 悬垂安全)。
-- 加载: hoi4_layout.lua 经 MOD_LUA_DIR dofile 本文件并 attach 到 M。
return function(M)
local rp, ru8, kptr = M.rp, M.ru8, M.kptr

-- 共享访问器: token id -> 名 (objects.lua 等统一引用, 版本知识单一来源)
-- §4.26.2 lexer token 表
function M.token_name(id)
    if not id or id < 1 then return nil end
    if type(id) ~= "number" then return nil end
    local B = hoi4.base()
    local tbl = rp(B + M.rva.lexer_token_table)
    local mx  = hoi4.read_u32(B + M.rva.lexer_token_max)
    if tbl and mx and id <= mx then
        return hoi4.read_str(tbl + id * M.off.token_string.stride)
    end
    return nil
end
-- ---------------------------------------------------------------- 静态资源访问层
-- 五张静态注册表 + name→token 反查。布局定案 = §4.26.3 非 DB 静态注册表
-- (+ 反查 §4.26.2 基础访问器);
-- 段侧一律调这里, 禁止散写内联 (modobj 0x3169C0 掉位事故教训)。
-- 挂载点每次热重载重取 (file-local 随 re-dofile 重置, 悬垂安全)。
local sreg_cache = nil
local function sreg()
    if sreg_cache then return sreg_cache end
    local B = hoi4.base()
    -- 1.19.3 : .data 槽位移不均匀 — idb 块 (0x3316xxx/0x3317xxx 族)
    -- 整块 +0x183D0; settbl/set_count +0x18F90; idreg/mods +0x18F60;
    -- cde +0x18F70。逐址 dump+活体双证。
    local c = {
        mdefs  = rp(B + 0x332ED90),            -- modifier 定义表 (旧 0x33169C0)
        mnd    = hoi4.read_u32(B + 0x332ED9C) or 0,
        idb    = rp(B + 0x332F090),            -- CGameItemDatabase (旧 0x3316CC0)
        rules  = rp(B + 0x33304C0),            -- external_rules 定义 (28 槽; 旧 0x33180F0)
        settbl = rp(B + 0x333D530),            -- SET 名串表 (指针全局, 已解引用; 旧 0x33245A0)
    }
    -- nil 不缓存 (早载窗口 rp 失败缓存 nil 会锁死到重载)
    if c.mdefs then sreg_cache = c end
    return c
end

-- §4.26.3 modifier 定义表 — idx → 叶名 token (stride 120, token u32@def+112;
-- 字段补全: 名 MSVC@+0 / flags@+96 / caller 掩码
-- @+100 / **类属回调掩码 u32@def+104** / token@+112;
-- 引擎谓词 sub_140552BC0: mask104==0 or (回调&mask104)~=0 通过)
function M.modifier_token(idx)
    local c = sreg()
    if not c.mdefs or not idx or idx < 0 or idx >= c.mnd then return nil end
    return M.token_name(hoi4.read_u32(c.mdefs + 120 * idx + 112))
end
function M.modifier_count()
    return sreg().mnd
end

-- §4.26.3 modifier 定义表 — 类属掩码 u32@def+104 (引擎谓词 sub_140552BC0
-- 左操作数; 补, charmgr advisor.modifier 块门精确式 = cat==0 or (category_mask&cat)~=0)
function M.modifier_category(idx)
    local c = sreg()
    if not c.mdefs or not idx or idx < 0 or idx >= c.mnd then return nil end
    return hoi4.read_u32(c.mdefs + 120 * idx + 104)
end

-- §4.26.3 modifier 定义表
-- 类属回调 = 单 fnptr @BASE+0x33300A0 (非表), 恒返回当前类别掩码
-- u32@BASE+0x332F248 (引擎谓词/同址两名 = 书 §4.26)
function M.modifier_category_mask()
    return hoi4.read_u32(hoi4.base() + 0x332F248)
end

-- §4.26.4 idb 库规格 — CGameItemDatabase key → 类型名。
-- **TGameItemDatabase<T> 模板家族布局并非全族同构** (arr/cnt 偏移与
-- def 名字段随派生类漂移); 标准族 Null Object 语义 = 书 §4.26.4。
-- 条目值 = rva 数字 (默认族 arr@64/cnt@76/tok8) 或规格表
-- {rva=, arr=, cnt=, nm=, nonull=} — nm/nonull 形态码释义见 idb_def_name 注;
-- nonull 库越界一律 nil, 标准族越界回退 arr[0] (多数 = "none")
M.rva.idb = {
    state_category = 0x332f968,   -- CStateCategoryDatabase 14 (13+none) tok8; STATE 段
    building = 0x332ee28,         -- CBuildingDatabase 56 (55+none) tok8; states buildings (取代 legacy BLD2_NAMES)
    equipment = { rva = 0x332eec0, arr = 104, cnt = 116 },  -- CEquipmentDatabase 457 tok8 (变体+原型合并; upgrades@176/38, modules@224/313 另有)
    technology = { rva = 0x332f0a0, arr = 72, cnt = 84, nm = "sso16" },  -- 553 (arr[0]=null 空名) sso@def+16; folders@168/17
    focus = { rva = 0x332ef70, arr = 88, cnt = 100 },  -- CNationalFocusDatabase 10888 tok8; arr@64/22 = focus styles (名 sso@+8)
    idea = { rva = 0x332ef30, arr = 104, cnt = 116 },  -- CIdeaDatabase 5797 tok8; 分类@216/25 tok8, @160/15 sso16
    decision = { rva = 0x332ee80, arr = 40, cnt = 52, nm = "tok16" },  -- CDecisionDatabase 4128 tok16; lookup@64 (40B 元, 非指针数组); 分类@88/594 (名 sso@def+24)
    strategic_resource = { rva = 0x332f088, arr = 40, cnt = 52 },  -- 8 (7+none) tok8; db+64 是字符串另物
    autonomous_state = { rva = 0x332ee18, nm = "msvc8" },  -- ⚠ 特例: 无 arr/cnt — defs=内联指针数组@db+48, 名 MSVC@def+8, count 扫描; puppet 名也可直接读 def 对象 sso@+8 (§4.10)
    ideology_group = { rva = 0x332ef38, arr = 96, cnt = 108, nonull = true },  -- 4 tok8 无 Null Object (democratic/communism/fascism/neutrality)
    sub_unit = 0x332f090,         -- CSubUnitDatabase 158 (157+none) tok8 (charmgr sub_unit_modifiers 键)
    wargoal = 0x332ef28,          -- CWarGoalDatabase 11 (10+none) tok8
    gamerules = { rva = 0x332ef20, arr = 40, cnt = 52 },  -- ⚠ 稀疏: 86 槽大半脏指针, 枚举须逐槽 kptr+名过滤; 规则实例侧用 rule_key
    -- ↓ nm 新形态: ssoN=MSVC@def+N, "none"=仅计数无名字段
    terrain = { rva = 0x332f0a8, arr = 64, cnt = 76, nm = "sso24" },  -- CTerrainDatabase A 族; sso@def+24 (+8 非 token)
    opinion_modifier = { rva = 0x332efc0, arr = 40, cnt = 52 },  -- B 族 tok8
    strategic_region = { rva = 0x332f080, arr = 40, cnt = 52, nm = "sso32" },  -- "%s (%i)" 直证
    state = { rva = 0x332f070, arr = 40, cnt = 52, nm = "none" },  -- 按 id 无名
    country_leader = 0x332ee68,   -- A 族标准
    continuous_focus = { rva = 0x332ee60, arr = 48, cnt = 60, nm = "sso24", nonull = true },  -- miss 返 0, arr[0] 真实元素 (hash@+16 不参与取名; sso24h16 别名在泛化时丢失致断名, 已改直写 sso24)
    agency_upgrade = 0x332edc0,   -- 标准 tok8; TNullObject@0x33180B0
    ai_focus = 0x332ee08,         -- 标准 tok8; CNullAIFocusDatabaseEntry
    ai_equipment_role = { rva = 0x332edd8, arr = 64, cnt = 76, nm = "msvc8" },  -- CNull…Entry
    ai_role = { rva = 0x332edf0, arr = 64, cnt = 76, nm = "sso16" },  -- CNullAIRoleDatabaseEntry
    ai_strategy_plan = { rva = 0x332ee10, arr = 72, cnt = 84, nm = "sso24" },  -- ⚠ cnt 漂移 84 (B 族 72 起步实例)
    bookmark = { rva = 0x332ee20, arr = 40, cnt = 52, nm = "sso16" },  -- TNullObject@0x332f350
    unit_leader = { rva = 0x332f0d0, arr = 88, cnt = 100, nm = "sso16" },  -- TNullObject@0x3321338
    aces = { rva = 0x332edb0, arr = 40, cnt = 52, nm = "msvc8", nonull = true },  -- miss→0 无 Null Object
    scripted_window = { rva = 0x332f060, arr = 40, cnt = 52, nm = "msvc8", nonull = true },  -- miss→0
    ability = { rva = 0x332eda8, arr = 40, cnt = 52, nm = "none" },  -- 名未定 (疑串@112), 暂计数
    ai_area = { rva = 0x332edc8, arr = 40, cnt = 52, nm = "none" },
    ai_attitude = { rva = 0x332ede8, arr = 64, cnt = 76, nm = "none" },
    country_scorer = { rva = 0x332f018, arr = 136, cnt = 148, nm = "none" },  -- TReloadable 样板 (内联 null@db+160)
    timed_activity = { rva = 0x332f0b8, arr = 48, cnt = 60, nm = "none" },  -- 内联 16B 元
    -- ↓ PersistentReloadable 族 {vec@8 基类, 表@48, 条目 vec@80/cnt@92,
    -- token vec@104} 均无 null 回退 (§4.26.4 PR 族)
    career_medal = { rva = 0x332ee30, arr = 40, cnt = 52, nm = "sso72" },  -- A 族; 条目 u32@+8 是硬编码 id 非 token, 显示串@+72
    career_picture = { rva = 0x332ee38, arr = 40, cnt = 52, nm = "none" },  -- GUI-only
    career_background = { rva = 0x332ee40, arr = 40, cnt = 52, nm = "none" },
    career_ribbon = { rva = 0x332ee48, arr = 40, cnt = 52, nm = "none" },  -- medal 同款 (名待验)
    ai_fleet_template = { rva = 0x332ef88, arr = 80, cnt = 92, nonull = true },  -- PersistentReloadable; tok8 (FNV@+8)
    ai_taskforce_template = { rva = 0x332ef80, arr = 80, cnt = 92, nonull = true },  -- fleet 同构 (nm 中置信)
    focus_inlay_window = { rva = 0x332efd0, arr = 80, cnt = 92, nm = "none", nonull = true },
    frontend_background = { rva = 0x332ef18, arr = 80, cnt = 92, nm = "none", nonull = true },
    strategic_location = { rva = 0x332f078, arr = 80, cnt = 92, nm = "none", nonull = true },  -- nm 中置信
    scripted_trigger_template = { rva = 0x332f058, arr = 64, cnt = 76, nm = "sso96" },  -- null=TNullObject@0x33121140
    scripted_diplomatic_action = { rva = 0x332f048, arr = 40, cnt = 52, nm = "none" },  -- nm 低置信
    scripted_map_mode = { rva = 0x332f040, arr = 40, cnt = 52, nm = "none" },  -- nm 低置信
    equipment_group = { rva = 0x332eed0, arr = 96, cnt = 108, nonull = true },  -- A 族变体 GetByToken vec@96/tok8@+8
    character_advisor_generation = { rva = 0x332ee50, arr = 40, cnt = 52, nm = "none" },  -- 同族推测
    -- ↓ TReloadable 骨架 {vec24@40, RH-map@64, 条目 vec@96/cnt@108,
    -- 默认槽@120, byte@128 标志}; 基类容器@8 = _Paths 文件路径表非条目
    -- (§4.26.4 TReloadable 骨架)
    ideology = { rva = 0x332f528, arr = 96, cnt = 108 },  -- miss 回退 +120 默认槽 (TNullObject<CIdeology>@0x3320D90)
    country_tag_alias = { rva = 0x332ee78, arr = 96, cnt = 108, nm = "tok264" },  -- ⚠ token 在元素+264 非 +8 (防呆)
    mtth = { rva = 0x332ef58, arr = 96, cnt = 108 },  -- tok8; byte@128 评估模式标志
    historical_agency = { rva = 0x332edb8, arr = 40, cnt = 52, nm = "sso40", nonull = true },  -- nm 中置信 (dtor 线索)
    scientist_trait = { rva = 0x332f010, arr = 96, cnt = 108, nonull = true },  -- tok8
    difficulty_settings = { rva = 0x332ee88, arr = 40, cnt = 52, nm = "sso56" },  -- 0x332ee88 旧猜实证成立 (getter sub_140170120)
    operations = { rva = 0x332efa8, arr = 96, cnt = 108, nonull = true },  -- TReloadable 三连
    operation_phases = { rva = 0x332efb0, arr = 96, cnt = 108, nonull = true },
    operation_tokens = { rva = 0x332efb8, arr = 96, cnt = 108, nonull = true },
    on_action_data = { rva = 0x332efa0, arr = 64, cnt = 76, nm = "none" },  -- A 族; arr[0]=COnActionList null@0x3320F10
    unit_medal = { rva = 0x332f0c8, arr = 64, cnt = 76, nm = "sso24" },  -- A 族; arr[0]=TNullObject@0x3321308 (sso24 读 null 得 nil 安全)
    scripted_effect_template = { rva = 0x332f050, arr = 80, cnt = 92, nm = "sso96", nonull = true },  -- PR 族; 条目 128B CScriptedEffectTemplate
    test_db = { rva = 0x332f0b0, arr = 40, cnt = 52, nm = "none" },  -- 测试桩 (无 parse 路径, 常态空)
    -- ↓ 23/23 进程级单例: PR 族 ×17 (PersistentReloadable, 0x80, arr@80/
    -- cnt@92) + TRS 族 ×4 (0xA0-0xC0, arr@96/cnt@108, 宽名表@64
    -- stride56); 全部无 Null Object, 全部 tok8 (§4.26.4 跨库通用定案)
    faction_goal = { rva = 0x332eee0, arr = 80, cnt = 92, nonull = true },
    faction_icons = { rva = 0x332eee8, arr = 80, cnt = 92, nonull = true },
    faction_member_upgrade = { rva = 0x332eef0, arr = 80, cnt = 92, nonull = true },
    faction_member_upgrade_group = { rva = 0x332eef8, arr = 80, cnt = 92, nonull = true },
    faction_rule = { rva = 0x332ef00, arr = 80, cnt = 92, nonull = true },
    faction_rule_group = { rva = 0x332ef08, arr = 80, cnt = 92, nonull = true },
    faction_template = { rva = 0x332ef10, arr = 80, cnt = 92, nonull = true },
    ai_faction_theater = { rva = 0x332ede0, arr = 80, cnt = 92, nonull = true },
    doctrine_folder = { rva = 0x332eea0, arr = 80, cnt = 92, nonull = true },
    grand_doctrine = { rva = 0x332eea8, arr = 80, cnt = 92, nonull = true },
    sub_doctrine = { rva = 0x332eeb0, arr = 80, cnt = 92, nonull = true },
    doctrine_track = { rva = 0x332eeb8, arr = 80, cnt = 92, nonull = true },
    ai_bonus_weight = { rva = 0x332edd0, arr = 96, cnt = 108, nonull = true },  -- TRS
    mio_organisation = { rva = 0x332ef48, arr = 96, cnt = 108, nonull = true },  -- TRS (Add 直证 sub_140167C50; 副表@160)
    mio_policy = { rva = 0x332ef40, arr = 96, cnt = 108, nonull = true },  -- TRS
    project = { rva = 0x332efe8, arr = 80, cnt = 92, nonull = true },
    prototype_reward = { rva = 0x332eff8, arr = 80, cnt = 92, nonull = true },
    specialization = { rva = 0x332f068, arr = 96, cnt = 108, nonull = true },  -- TRS
    raid_category = { rva = 0x332f000, arr = 120, cnt = 132, nonull = true },  -- 双仓之 categories 仓 (types 仓 vec@176/cnt@188 需专读)
    script_constant = { rva = 0x332f020, arr = 80, cnt = 92, nonull = true },
    script_named_collection = { rva = 0x332eed8, arr = 80, cnt = 92, nonull = true },
    ai_naval_goal = { rva = 0x332ef78, arr = 80, cnt = 92, nonull = true },
    -- ============ §4.26.4 形态外 22 库 (layout 定案)
    -- shape 字段 → M.idb_find 分发; arr/cnt 仍给出以兼容 idb_count。
    -- 「rh」= pdx robin-hood 32B 头 {+0 未决, +8 data, +16 cnt, +20 mask,
    -- +24 extra u8, +28 mf 0.9f}; 条目 {hash u32@0, dist u8@4, 键串@+8, 值@val}。
    -- 「umap」= MSVC unordered_map; 「stdmap」= std::map(RB); 「chain4」= 4 链式表。
    name = { rva = 0x332ef68, shape = "umap", tbl = 40, sentinel = 48, size = 56,
             node = 16, val = 48, defoff = 104, hash = "cs", nm = "none" },
    name_group = { rva = 0x332ee90, shape = "chain4", mod = 511, node = 0,
             entry = 0x170, arr = 48, cnt = 40, nm = "sso8", hash = "ci",
             nonull = true },  -- miss → 0 (无 Null Object, 4 表全扫也不能回退)
    unit_names = { rva = 0x332f0d8, shape = "inline", arr = 64, cnt = 76,
             stride = 120, nm = "none" },
    portrait = { rva = 0x332efd8, shape = "umap", tbl = 40, sentinel = 48, size = 56,
             node = 16, val = 48, hash = "cs", nm = "none" },
    power_balance = { rva = 0x332efe0, shape = "rh", tbl = 40, stride = 456,
             key = 8, val = 48, hash = "ci", nm = "none" },
    occupation_modifier = { rva = 0x332ef90, shape = "rh", tbl = 40, stride = 48,
             key = 8, val = 40, valptr = true, hash = "cs", nm = "none" },
    occupation_law = { rva = 0x332ef98, shape = "rh", tbl = 40, stride = 48,
             key = 8, val = 40, valptr = true, hash = "cs", nm = "none" },
    resistance_activity = { rva = 0x332f008, shape = "rh", tbl = 40, stride = 48,
             key = 8, val = 40, valptr = true, hash = "cs", nm = "none" },
    ai_strategy = { rva = 0x332ee00, shape = "vec3", arr = 64, cnt = 76,
             nm = "none" },
    character_template = { rva = 0x332ee58, shape = "rh", tbl = 64, stride = 24,
             key = 8, val = 16, valptr = true, keytok = true, nm = "none" },
    insignia_graphics = { rva = 0x332ef50, shape = "kind8", arr = 40,
             stride = 64, nm = "none" },
    scriptable_localization = { rva = 0x332f038, shape = "umap", tbl = 40,
             sentinel = 48, size = 56, node = 16, val = 48, hash = "cs",
             nm = "none" },  -- 与 name 同形: 哨兵@48/size@56/桶@64/mask@88
    equipment_graphic = { rva = 0x332eec8, shape = "rh4", tbl = 48, stride = 72,
             key = 8, val = 16, valptr = true, nm = "none" },
             -- ⚠ 非 keytok: 键 = 字符串 FNV-1a32 (活体直证 armored_car_chassis_5
             -- → 槽 hash db11bfe7 == fnv1a32(名)); 早期误标 keytok 致该库
             -- 全键查不到 (keytok 走 token id 比较路径)
    ncountry_metadata = { rva = 0x332ee70, shape = "stdmap", tbl = 40,
             node_key = 32, node_val = 40, defoff = 56, hash = "cs", nm = "none" },
    dlc_metadata = { rva = 0x332ee98, shape = "stdmap", tbl = 40,
             node_key = 32, node_val = 64, hash = "cs", nm = "none" },
    train_gfx = { rva = 0x332f0c0, shape = "slots", arr = 104, cnt = 116,
             nm = "none" },
    technology_sharing_group = { rva = 0x332f098, shape = "rh", tbl = 48,
             stride = 24, key = 8, val = 16, valptr = true, keytok = true,
             defoff = 80, nm = "none" },
    script_enum = { rva = 0x332f028, shape = "rh", tbl = 64, stride = 40,
             key = 8, val = 16, valptr = false, hash = "wang", nm = "none" },
    peace_conference = { rva = 0x332efc8, shape = "inline", arr = 208, cnt = 220,
             stride = 192, nm = "none" },
    project_dynamic_modifier = { rva = 0x332eff0, arr = 40, cnt = 52, nm = "none" },
    -- 未入表 (形态不合 {arr,cnt}, 需专写 reader): message_handler (非内容库,
    -- 消息类型注册表+设置处理器); raid_type 第二仓
    -- (同库 @176/188) 待专读; achievements 等非 idb 单例见 §4.26.8
}
local function idb_spec(key)
    local v = M.rva.idb[key]
    if not v then return nil end
    if type(v) == "number" then
        return { rva = v, arr = 64, cnt = 76, nm = "tok8" }
    end
    local sp = { rva = v.rva, arr = v.arr or 64, cnt = v.cnt or 76,
                 nm = v.nm or "tok8", nonull = v.nonull }
    for k, val in pairs(v) do sp[k] = val end   -- 透传 shape/表参数
    return sp
end
local function idb(key)
    local sp = idb_spec(key)
    return sp and rp(hoi4.base() + sp.rva) or nil
end
M.idb = idb
-- def → 名 (按库规格 nm)。ssoN = MSVC 串@def+N; tokN = lexer token@def+N
-- (⚠ N 可非 8/16: country_tag_alias 实证 tok264); msvc8 = sso8 别名
-- (autonomous_state/ai_equipment_role 系在用); "none" = 无名字段。
local function idb_def_name(sp, def)
    local nm = sp.nm == "msvc8" and "sso8" or sp.nm
    local t = nm:match("^tok(%d+)$")
    if t then return M.token_name(hoi4.read_u32(def + tonumber(t))) end
    local s = nm:match("^sso(%d+)$")
    if s then return M.read_msvc_str(def + tonumber(s)) end
    return nil
end
-- §4.26.5 idb_token/idb_count (规格 = §4.26.4)
-- 家族通用查名: M.idb_token(key, idx) → 名 (token 名或 MSVC 串)。
-- 越界语义: 标准族回退 arr[0] (与引擎 sub_140AB5E40 同款); nonull 库 nil。
function M.idb_token(key, idx)
    local db = idb(key)
    if not db then return nil end
    local sp = idb_spec(key)
    local arr, cnt
    if sp.nm == "msvc8" then
        arr = rp(db + 48)                     -- CAutonomousState 内联指针数组
        cnt = M.idb_count(key)
    else
        arr = rp(db + sp.arr)
        cnt = hoi4.read_u32(db + sp.cnt) or 0
    end
    if not arr then return nil end
    local def
    if sp.nonull then
        if not idx or idx < 0 or idx >= cnt then return nil end
        def = rp(arr + 8 * idx)
    else
        def = (not idx or idx < 1 or idx >= cnt) and rp(arr)
            or rp(arr + 8 * idx)
    end
    if not def then return nil end
    return idb_def_name(sp, def)
end
function M.idb_count(key)
    local db = idb(key)
    if not db then return 0 end
    local sp = idb_spec(key)
    if sp.nm == "msvc8" then
        local p = rp(db + 48)
        if not p then return 0 end
        local n = 0
        while n < 64 do
            local e = rp(p + 8 * n)
            if not e or e < 0x10000 then break end
            n = n + 1
        end
        return n
    end
    -- 形态感知: RH 族 count 在表头 +16; umap 在 size 字段; chain4 四表求和;
    -- stdmap / vec3 / slots 无单值 count (返 0, 用 idb_find 按名取)
    local shape = sp.shape
    if shape == "rh" or shape == "rh4" then
        local off = (shape == "rh4") and 48 or (sp.tbl or 40)
        return hoi4.read_u32(db + off + 16) or 0
    elseif shape == "umap" then
        return hoi4.read_u32(db + (sp.size or 56)) or 0
    elseif shape == "chain4" then
        local n = 0
        for t = 0, 3 do n = n + (hoi4.read_u32(db + 40 + 16 * t) or 0) end
        return n
    elseif shape == "stdmap" or shape == "vec3" or shape == "slots"
        or shape == "kind8" then
        return 0
    end
    return hoi4.read_u32(db + sp.cnt) or 0
end

-- ------------------------------------------------ 哈希形库 reader (§4.26.4 形态外 22 库)
-- 键哈希三族: cs=/ci-FNV-1a32 (0x811C9DC5/0x01000193) / wang (0x45D9F3B 混洗)
local function fnv1a32(s, ci)
    local h = 0x811C9DC5
    for i = 1, #s do
        local b = s:byte(i)
        if ci and b >= 65 and b <= 90 then b = b + 32 end
        h = ((h ~ b) * 0x01000193) & 0xFFFFFFFF
    end
    return h
end
local function wang32(s)
    local h = 0
    for i = 1, #s do
        local b = s:byte(i)
        if b >= 65 and b <= 90 then b = b + 32 end
        h = ((h ~ b) * 0x045D9F3B) & 0xFFFFFFFF
        h = ((h ~ (h >> 16)) * 0x045D9F3B) & 0xFFFFFFFF
    end
    return h
end
local function key_hash(sp, name)
    if sp.hash == "wang" then return wang32(name) end
    return fnv1a32(name, sp.hash == "ci")
end
-- RH 32B 头 {+0 unk, +8 data, +16 cnt, +20 mask, +24 extra u8, +28 mf}
-- 返回条目基址 (data + stride*slot) 或 nil; 上限 PTR 级防御
-- keytok 形 (键 = u32 token): 引擎存 hash 非名哈希, 走有界线性扫比对键值
-- 条目键比对: rh key= 串偏移; umap/stdmap key= 节点键串偏移
local function entry_key(e, sp)
    local off = sp.key or sp.node_key or sp.node or 8
    return M.read_msvc_str(e + off)
end
-- robin-hood 槽按名查找 (§3.2 RH; §4.26.4 idb 哈希形库通用)
local function rh_slot(T, sp, name)
    local data = rp(T + 8)
    local mask = hoi4.read_u32(T + 20) or 0
    local extra = hoi4.read_u8(T + 24) or 0
    if not kptr(data) or mask == 0 or mask > 0x800000 then return nil end
    local nb = mask + 1 + extra
    if sp.keytok then
        local want = sp.want_tok
        if not want then return nil end
        for i = 0, nb - 1 do
            local e = data + sp.stride * i
            local dist = hoi4.read_u8(e + 4)
            if dist and dist ~= 0 and dist ~= 0xFF
                and (hoi4.read_u32(e + 8) or 0) == want then
                return e
            end
        end
        return nil
    end
    local h = key_hash(sp, name)
    local i = h & mask
    for _ = 1, nb + 8 do
        local e = data + sp.stride * i
        -- 空槽判据 = **hash 槽 == 0**（非 dist; dist=0 的填充槽可在探测链
        -- 中途, 早期以 dist==0 终止曾断链致其后键全灭）。
        -- dist 语义 = 0-based 探测距离, 仅作参考不作判据。
        local eh = hoi4.read_u32(e)
        if not eh or eh == 0 then return nil end
        if eh == h then
            -- 键串复核 (可读名时): 防哈希碰撞误配
            local k = entry_key(e, sp)
            if k == nil or k == name then return e end
        end
        -- ⚠ 回绕模数 = nb = mask+1+extra, 不是 mask+1: 表增长后尾部槽
        -- (idx >= mask+1) 仍持条目 (power_balance nb=22/mask=15: 槽16-21 有键),
        -- 用 & mask 回绕永远走不到 → 位移键全灭。活体 46 键可达性验证
        -- %nb 回绕 100% 可达, & mask 回绕 29 位移键失 7。
        i = (i + 1) % nb
    end
    return nil
end
-- MSVC unordered_map: 哨兵节点链 (_Hash: 哨兵 +0/+8 分别为首/尾链节)
-- 链序遍历比对键串; 上限防御
local function umap_find(db, sp, name)
    local sent = rp(db + sp.sentinel)
    if not kptr(sent) then return nil end
    -- 节点布局 {next@+0, prev@+8, 键 MSVC 串内联@+16}; 桶指针直接指节点,
    -- 链表由 sentinel(+0 = 首节点) 串起 — ⚠ 早期实现误走 +8(prev) 只走一步,
    -- 致 name/portrait/scriptable_localization 三库按名查找恒 nil 而计数正常
    local node = rp(sent)
    for _ = 1, 400000 do
        if not kptr(node) or node == sent then return nil end
        if entry_key(node, sp) == name then
            return node + (sp.val or 48)
        end
        node = rp(node)
        if not node then return nil end
    end
    return nil
end
-- std::map: RB 中序 (§3.3; §4.26.4 idb stdmap 库通用), 节点键串比对
local function stdmap_find(db, sp, name)
    local head = rp(db + sp.tbl + 8)      -- _Myhead (map 头第二 qword)
    if not kptr(head) then return nil end
    local root = rp(head + 8)             -- _Myhead->_Parent = root
    local nil_ = rp(head)                 -- _Myhead->_Left = _Nil
    if not kptr(root) or not kptr(nil_) then return nil end
    local node = root
    for _ = 1, 400000 do
        if not kptr(node) or node == nil_ then return nil end
        local k = entry_key(node, sp)
        if k == name then return node + (sp.node_val or 40) end
        node = (k and name < k) and rp(node) or rp(node + 16)
    end
    return nil
end
-- name_group 4 链式表: 表 i 三件套 {cnt@40+16i, mod@44+16i, buckets@48+16i}
local function chain4_find(db, sp, name)
    local h = key_hash(sp, name)
    for t = 0, 3 do
        local base = db + 40 + 16 * t
        local buckets = rp(base + 8)
        if kptr(buckets) then
            local node = rp(buckets + 8 * (h % sp.mod))
            for _ = 1, 20000 do
                if not kptr(node) then break end
                local entry = rp(node + sp.node)
                if kptr(entry) then
                    local nm = sp.nm == "sso8" and M.read_msvc_str(entry + 8) or nil
                    if nm == name then return entry end
                end
                node = rp(node + 8)
            end
        end
    end
    return nil
end
-- §4.26.5 idb_find — 统一入口: M.idb_find(key, name) → def/值地址 (指针形库已解引用到位)。
-- 支持 shape: rh / rh4 / umap / stdmap / chain4; nil shape = 按名线性扫指针数组。
-- keytok 形库 (键 = lexer token): name 传 token id (number) 或 token 串。
function M.idb_find(key, name)
    if not name then return nil end
    local db = idb(key)
    if not db then return nil end
    local sp = idb_spec(key)
    local fkey = name
    if sp.keytok then
        fkey = type(name) == "number" and name or nil
        if not fkey then                 -- 名 → 反查 token
            fkey = M.name_to_token and M.name_to_token(name) or nil
        end
        sp.want_tok = fkey
    end
    local e
    if sp.shape == "rh" then
        local T = db + (sp.tbl or 40)
        e = rh_slot(T, sp, name)
    elseif sp.shape == "rh4" then
        for _, toff in ipairs({ 48, 80, 112, 144 }) do
            e = rh_slot(db + toff, sp, name)
            if e then break end
        end
    elseif sp.shape == "umap" then
        e = umap_find(db, sp, name)
        return e
    elseif sp.shape == "stdmap" then
        e = stdmap_find(db, sp, name)
        return e
    elseif sp.shape == "chain4" then
        return chain4_find(db, sp, name)
    else
        -- 线性扫: 指针数组 (arr/cnt) 或内联 (stride)
        local cnt, arr
        if sp.nm == "msvc8" then
            -- CAutonomousState 特例: 内联指针数组@db+48, count 扫描
            -- (与 idb_count/idb_token 同源; 名 MSVC@def+8)
            arr = rp(db + 48)
            cnt = M.idb_count(key)
        else
            cnt = hoi4.read_u32(db + sp.cnt) or 0
            arr = rp(db + sp.arr)
        end
        if cnt > 200000 then return nil end
        if not kptr(arr) then return nil end
        for i = 0, cnt - 1 do
            local def
            if sp.shape == "inline" then
                def = arr + (sp.stride or 0) * i
            else
                def = rp(arr + 8 * i)
            end
            if kptr(def) and idb_def_name(sp, def) == name then return def end
        end
        return nil
    end
    if not e then return nil end
    local val = e + (sp.val or 0)
    if sp.valptr then
        local p = rp(val)
        -- 内联值对象: 指针槽无效时回退条目内联位 (power_balance 等)
        return kptr(p) and p or val
    end
    return val
end
-- §4.26.4 item_token 兼容壳 — 兼容包装 (旧 item_token 签名;
-- db 分支只适用标准族布局 arr@64/cnt@76/tok8
-- — 非 standard 库勿传 db, 一律走 idb_token(key,·))
function M.item_token(idx, db)
    if db then
        local arr = rp(db + 64)
        if not arr then return nil end
        local cnt = hoi4.read_u32(db + 76) or 0
        local def = (not idx or idx < 1 or idx >= cnt) and rp(arr)
            or rp(arr + 8 * idx)
        if not def then return nil end
        return M.token_name(hoi4.read_u32(def + 8))
    end
    return M.idb_token("sub_unit", idx)
end

-- §4.26.5 idb_index_of_token — token → 库内 idx 反查 (sub_140AB5EE0 同构线性扫: def token@+8 逐项比对)。
-- 仅 token 系库 (tok8/tok16) 支持; sso/msvc 系库返回 nil (引擎按名 stricmp
-- 另走 sub_140AB37F0)。命中返回 idx (0=Null Object 槽, 引擎语义保留);
-- 未命中/库未知 → nil。防越界: 扫描上界 = idb_count。
function M.idb_index_of_token(key, tok)
    if not tok then return nil end
    local db = idb(key)
    local sp = idb_spec(key)
    if not db or not sp then return nil end
    local toff = sp.nm:match("^tok(%d+)$")
    if not toff then return nil end
    local arr = rp(db + sp.arr)
    local cnt = hoi4.read_u32(db + sp.cnt) or 0
    if not arr or cnt < 0 or cnt > M.lim.PTR_HUGE then return nil end
    local off = tonumber(toff)
    for i = 0, cnt - 1 do
        local def = rp(arr + 8 * i)
        if def then
            local t = hoi4.read_u32(def + off)
            if t == tok then return i end
        end
    end
    return nil
end

-- ============ §4.26.3 id 注册表三源 (writer sub_14220A030; §3.9/§4.2) ============
-- (type,id) → 对象; 三源分域/RH 布局/8B 步进勘误 = 书 §4.26.3
-- (分域偏移见 M.rva.idreg 与 idreg_unit_resolve)。
-- 对象 = this 调整指针 raw+16 (第二基类 vt1; 师类调用方按需 res-16 取 vt0)。
M.rva.idreg = { big = 0x3451DB0, mid = 0x3451DB8, arr = 0x3451DC0,
                arr_end = 0x34520E0 }  -- 1.19.3: 整组 +0x18F60 (旧 0x3438E50/E58/E60 → 0x3439180; 新 dump sub_14221EF70 三源 + 活体)

-- (ty,id) → 对象指针 (sub_14220A3D0/1422083E0 同构); 未注册/无效 → nil
function M.idreg_unit_resolve(ty, id)
    if not (ty and id) then return nil end
    local B = hoi4.base()
    local db
    if ty > 0x1268 then db = rp(B + M.rva.idreg.big)
    elseif ty >= 100 then db = rp(B + M.rva.idreg.mid)
    else db = rp(B + M.rva.idreg.arr + 8 * ty) end
    if not kptr(db) then return nil end
    local d, mask, maxp = rp(db + 8), hoi4.read_u32(db + 20), ru8(db + 24)
    if not (kptr(d) and mask and mask > 0 and mask < 0x4000000) then
        return nil end
    for bi = 0, mask + (maxp or 0) do
        local b = d + 24 * bi
        if (ru8(b + 4) or 0) ~= 0
            and hoi4.read_u32(b + 8) == ty and hoi4.read_u32(b + 12) == id then
            local o = rp(b + 16)
            if kptr(o) then return o end
            return nil
        end
    end
    return nil
end

-- 三源合并 #.id maxima (writer sub_14220A030 填充语义, 每型取 max 已分配
-- id): 返回 {[type]=id,...}, 仅 type≥4712 且 type-4712<4711 且 id>0。
-- 消费: session_meta #.id 叶 (写序 = type 升序由段侧 sort)。
function M.idreg_maxima()
    local B = hoi4.base()
    local merged = {}
    local function harvest(buckets, mask, distmax)   -- §4.26.3 id 注册表单源桶收集
        if not (kptr(buckets) and mask and mask > 0 and mask < 0x100000) then
            return
        end
        for i = 0, mask + (distmax or 0) do
            local b = buckets + 24 * i
            if (ru8(b + 4) or 0) ~= 0 then
                local vp = rp(b + 16)
                if kptr(vp) then
                    local ty = hoi4.read_u32(vp + 8) or 0
                    local idv = hoi4.read_u32(vp + 12) or 0
                    if ty >= 4712 and ty - 4712 < 4711 and idv > 0 then
                        if not merged[ty] or idv > merged[ty] then
                            merged[ty] = idv
                        end
                    end
                end
            end
        end
    end
    local function harvest_map(regp)
        if kptr(regp) then
            harvest(rp(regp + 8), hoi4.read_u32(regp + 20), ru8(regp + 24))
        end
    end
    harvest_map(rp(B + M.rva.idreg.big))
    harvest_map(rp(B + M.rva.idreg.mid))
    local arr = B + M.rva.idreg.arr
    while arr < B + M.rva.idreg.arr_end do
        harvest_map(rp(arr))
        arr = arr + 8          -- 8B 步进 (§4.26.3; 旧 16B 漏扫奇数槽)
    end
    return merged
end

-- ============ mods 管理器 / combat_data_entry / rules def 侧 (§4.26.5) ============
-- mods mgr = rp(0x344A568) (1.19.3 +0x18F60); 注册表 RB 树 head@+176
-- (节点名/路径 MSVC) 与播放集容器 = 书 §4.26.5 (偏移见 mods_registry /
-- mods_playset_tails 代码)
M.rva.mods = 0x344A568

-- §4.26.5 rb_inorder — MSVC RB 树中序 ({_Left@0,_Parent@8,_Right@16,_Isnil@25}); 防御界 1e5 帧。
-- (镜像 global_tails 同名 helper, 供静态注册表收敛; 段侧旧本地待退役)
function M.rb_inorder(head)
    local out = {}
    if not kptr(head) then return out end
    local function sent(n)
        return (not kptr(n)) or (ru8(n + 25) or 1) ~= 0
    end
    local node = rp(head)
    while not sent(node) do
        out[#out + 1] = node
        local right = rp(node + 16)
        if not sent(right) then
            node = right
            local l = rp(node)
            while not sent(l) do
                node = l
                l = rp(node)
            end
        else
            local p = rp(node + 8)
            while not sent(p) and rp(p + 16) == node do
                node = p
                p = rp(node + 8)
            end
            node = p
        end
        if #out > 100000 then break end
    end
    return out
end

-- §4.26.5 mods_registry — 注册表中序 → {{name=, path=},...} (RB 中序 = 写序; kptr 门)
function M.mods_registry()
    local mgr = rp(hoi4.base() + M.rva.mods)
    if not kptr(mgr) then return {} end
    local out = {}
    for _, node in ipairs(M.rb_inorder(rp(mgr + 176))) do
        out[#out + 1] = { name = M.read_msvc_str(node + 72),
                          path = M.read_msvc_str(node + 136) }
    end
    return out
end

-- §4.26.5 mods_playset_tails — 播放集路径末两段 "a/b" 集合 (引擎启用匹配语义)
function M.mods_playset_tails()
    local mgr = rp(hoi4.base() + M.rva.mods)
    local tails = {}
    if not kptr(mgr) then return tails end
    local pd, pc = rp(mgr + 104), hoi4.read_u32(mgr + 116) or 0
    if not (kptr(pd) and pc > 0 and pc < M.lim.FIXED_SMALL) then
        return tails
    end
    for i = 0, pc - 1 do
        local p = M.read_msvc_str(pd + 32 * i)
        if p then
            p = p:gsub("\\", "/"):gsub("/+$", "")
            local a, b = p:match("([^/]+)/([^/]+)$")
            if a then tails[a .. "/" .. b] = true end
        end
    end
    return tails
end

-- §4.26.5 cde_table — combat_data_entry 静态表 (writer 0x140CD08A0 唯一 gs-writer 级 def 引用)
-- {data=数据数组 (1096B 元), refs=u16 并行数组, count=i32}
-- 1.19.3 整组 +0x18F70 (旧 0x3323C00/C18/C48; 新 dump writer 0x140CDFFF0
-- 引用 qword_14333CB70/CB88 + dword_14333CBB8, 活体 cnt=4 与锚件吻合)
M.rva.cde = { data = 0x333CB70, refs = 0x333CB88, count = 0x333CBB8 }
function M.cde_table()
    local B = hoi4.base()
    return { data = rp(B + M.rva.cde.data),
             refs = rp(B + M.rva.cde.refs),
             count = hoi4.read_u32(B + M.rva.cde.count) or 0 }
end

-- §4.26.5 rule_def_flags — rules 定义侧附加 flags: 槽 i 字节 @+48/+49/+50 (sub_14062BED0 拷入
-- state+64+slot; 值级对拍备用)。返回 {a=,b=,c=} 或 nil。
function M.rule_def_flags(i)
    local c = sreg()
    if not c.rules or not i or i < 0 or i >= M.dim.EXTERNAL_RULES then
        return nil
    end
    local base = c.rules + 56 * i
    return { a = ru8(base + 48) or 0, b = ru8(base + 49) or 0,
             c = ru8(base + 50) or 0 }
end

-- ============ CDefines (§4.26.5 define/define_f; 运行时扫像 §4.26.7) ============
-- name → 定义值。地址来自 DLL 侧镜像扫描 (hoi4.define_lookup / define_targets):
-- 引擎把每个 define 以 `lea r8,[目标]; lea rdx,[名字]; lea rcx,[ctx]; call 装载器`
-- 的形式注册, 故 name→地址表就烙在代码字节里, 进程内一次扫像即可复原 —
-- 无外部数据文件, 游戏更新后也不需要重新生成步骤。
-- define 返回原始 qword (double/i64 由调用方判); 未知名/扫描失败 → nil。
-- ⚠ 多义名 (同 name 注册进多个 namespace, 各有独立存储) 取首个命中;
-- 需要指定 namespace 用 M.define_at(name, i); 真实地址集用 M.define_targets(name)。
function M.define(name)
    if not name then return nil end
    local rva = hoi4.define_lookup(name)
    if not rva then return nil end
    return rp(hoi4.base() + rva)
end
-- 多义名按序取第 i 个 namespace 的存储 (i 从 1 起); 越界/未知名 → nil
function M.define_at(name, i)
    if not name or not i then return nil end
    local t = hoi4.define_targets(name)
    if not t or not t[i] then return nil end
    return rp(hoi4.base() + t[i])
end
-- 返回 name 的全部 namespace 地址数组 (无则 nil)
function M.define_targets(name)
    if not name then return nil end
    return hoi4.define_targets(name)
end
-- double 形 defines (OUT_OF_SUPPLY_SPEED 等浮点族) 便捷读
function M.define_f(name)
    local a = M.define(name)
    if not a then return nil end
    -- 位级重解释 u64 → double, 拆高低字必须用位运算: 读原语给的是 8 字节
    -- 位模式 (带符号视图), 而 floor(bits/2^32) 走 float 除法, 低位非零时
    -- 商的小数部分会被舍入进位 → 高字差 1 (实测 20 万随机位模式 1 例错值);
    -- & 0xFFFFFFFF 与 >> 32 对负数取的是同一位段, 构造上精确 (§3.7 数值换算)。
    local lo = a & 0xFFFFFFFF
    local hi = (a >> 32) & 0xFFFFFFFF
    return (string.unpack("<d", string.pack("<I4I4", lo, hi)))
end

-- §4.26.3 external_rules 定义 — 槽 i∈[0,M.dim.EXTERNAL_RULES) → 键名 token (u32@defs+56*i+40)
function M.rule_key(i)
    local c = sreg()
    if not c.rules or not i or i < 0 or i >= M.dim.EXTERNAL_RULES then
        return nil
    end
    return M.token_name(hoi4.read_u32(c.rules + 56 * i + 40))
end

-- §4.26.3 SET 名串表 — saved_event_target name: u16 idx → 名 (条目 32B MSVC 串; idx=0 无 name)
-- 上界 = 实时 set_count (count@BASE+0x333D53C (= settbl+0xC; 1.19.3
-- +0x18F90, 旧 0x33245AC), push_back 终界 sub_140F43E10);
-- 越界/0 → nil
function M.set_count()
    return hoi4.read_u32(hoi4.base() + 0x333D53C) or 0
end
function M.set_name(idx)
    local c = sreg()
    if not c.settbl or not idx or idx == 0 then return nil end
    local n = M.set_count()
    if n and (idx < 0 or idx >= n) then return nil end
    return M.read_msvc_str(c.settbl + 32 * idx)
end

-- ---------------------------------------------------------------- §4.14.4 CMap 单例
-- m = rp(BASE+0x3339D28); 省表界 +560 (= gs+0x2BC = max_province_id+1) /
-- 陆省数 +564 / 省→州 i16 数组@*(m+40) / 省非海 u32 数组@*(m+568)
-- (0xFFFFFFFF=海; 旧注 i16 隔行错位已勘误) — 边界细节 = 书 §4.14
function M.map_ptr()
    local m = rp(hoi4.base() + 0x3339D28)
    return kptr(m) and m or nil
end
function M.province_state(pid)   -- 省 id → 州 id (0=海/无州); 越界 nil
    local m = M.map_ptr()
    if not (m and pid and pid >= 1) then return nil end
    if pid >= (hoi4.read_u32(m + 560) or 0) then return nil end
    local sa = rp(m + 40)
    if not kptr(sa) then return nil end
    return hoi4.read_u16(sa + 2 * pid)
end
function M.province_is_land(pid) -- 省 id → true/false; 越界 nil
    local m = M.map_ptr()
    if not (m and pid and pid >= 1) then return nil end
    if pid >= (hoi4.read_u32(m + 560) or 0) then return nil end
    local la = rp(m + 568)
    if not kptr(la) then return nil end
    return (hoi4.read_u32(la + 4 * pid) or 0xFFFFFFFF) ~= 0xFFFFFFFF
end

-- ------------------------------------------------- terrain LUT / 省地形双读
-- §4.26.8 CTerrainDatabase 扩展 — LUT int[]@db+136 / cnt@db+148
function M.terrain_lut(byte)   -- 无参 → LUT count; 带 byte → 对应 db 下标 (i32)
    local db = idb("terrain")
    if not db then return nil end
    local cnt = hoi4.read_u32(db + 148) or 0
    if byte == nil then return cnt end
    if byte < 0 or byte >= cnt or cnt > 4096 then return nil end
    local lut = rp(db + 136)
    if not kptr(lut) then return nil end
    return hoi4.read_u32(lut + 4 * byte)
end
-- §4.14.3 省静态描述符: CMap+616 8B 指针数组 {data@+616 cap@+624 cnt@+628},
-- desc+168 = 地形 def*, 名 MSVC SSO@def+24; desc+196 = 省 id (一致性自证)
function M.province_terrain_name(pid)
    local m = M.map_ptr()
    if not (m and pid and pid >= 1) then return nil end
    if pid >= (hoi4.read_u32(m + 628) or 0) then return nil end
    local data = rp(m + 616)
    if not kptr(data) then return nil end
    local desc = rp(data + 8 * pid)
    if not kptr(desc) then return nil end
    if (hoi4.read_u32(desc + 196) or -1) ~= pid then return nil end
    local tdef = rp(desc + 168)
    if not kptr(tdef) then return nil end
    return M.read_msvc_str(tdef + 24)
end

-- ---------------------------------------------------------------- loc_text (本地化直查)
-- §4.26.8 本地化运行时管理器 — mgr = rp(BASE+0x35BA038); texts 有序
-- 索引/全局串 blob 布局 = 书 §4.26.8 (偏移见 loc_text 代码)。
-- 读侧: 确认 = 值前紧邻即 key 串 (blob+off-#key-1); 命中级接口,
-- key 不存在 → nil。⚠ 文本走 read_cstr (read_str 对 UTF-8 长串会 nil)
local function fnv1_64(s)
    local h = 0xCBF29CE484222325
    for i = 1, #s do h = (h ~ s:byte(i)) * 0x100000001B3 end
    return h
end
local function u64lt(a, b)          -- 无符号 64 位比较 (Lua 整数为回绕有符号)
    if (a < 0) ~= (b < 0) then return a >= 0 end   -- 负数=巨值: 非负侧必小
    return a < b
end
function M.loc_text(key)
    if not key or key == "" then return nil end
    local mgr = rp(hoi4.base() + 0x35BA038)
    if not kptr(mgr) then return nil end
    local texts = rp(mgr)
    if not kptr(texts) then return nil end
    local idx = rp(texts + 32)
    local cnt = hoi4.read_u32(texts + 44) or 0
    local blob = rp(mgr + 32)
    if not kptr(idx) or not kptr(blob) or cnt > 2000000 then return nil end
    local h = fnv1_64(key)
    local lo, hi = 0, cnt - 1
    while lo <= hi do
        local mid = (lo + hi) // 2
        local rh = rp(idx + 16 * mid)
        if rh == h then
            -- 哈希命中带 (冲突时向两侧线性扩)
            for d = 0, 8 do
                for _, mi in ipairs({ mid + d, mid - d }) do
                    if mi >= 0 and mi < cnt and rp(idx + 16 * mi) == h then
                        local off = hoi4.read_u32(idx + 16 * mi + 8)
                        if off and off > #key
                            and hoi4.read_cstr(blob + off - #key - 1) == key then
                            return hoi4.read_cstr(blob + off)
                        end
                    end
                end
            end
            return nil
        elseif u64lt(h, rh) then
            hi = mid - 1
        else
            lo = mid + 1
        end
    end
    return nil
end
end  -- resource.lua attach
