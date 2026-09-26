-- sv2_sec_doctrine.lua -- doctrine 节点 savefull 直出 (主写)
-- 结构 (普查 7,131 叶): countries.#N (N = 国家 idx+1, 含 idx0 哨兵, 440 块;
-- country 引号 tag 行哨兵无); enable_tactic.#1 = token id 空格单行;
-- folder.#N.folder 四键恒写; grand_doctrine/sub_doctrine 仅已选;
-- tracks.#N.rewards/mastery/mastery_bank/daily_mastery 恒写 (fixed5);
-- cost_reduction.#N.{uses,name,folder,cost_factor} / daily_mastery.#N.
-- {name,daily_mastery,bonus,days,relevant_tracks.*} 仅表非空。
-- reader = Runtime.doctrine(idx) (§3)。
-- §4.6 学说 NDoctrines — CDoctrineSystem (gs+1024) / CCountryDoctrineStatus;
-- gs 原语访问 = §1.1 CGameState (国家数组 gs+784 / 国家数 gs+796 / tag 串表 gs+856)。
SV2.gsec[#SV2.gsec + 1] = { name = "doctrine", emit = function(ctx)
    local SL, emit, O = SV2.lib, ctx.emit, ctx.O
    local rp, ru32, kptr = SL.rp, SL.ru32, SL.kptr
    local BASE = ctx.BASE
    local gs = ctx.gs
    local n = gs and ru32(gs + 0x31C) or 0
    local carr = gs and rp(gs + 0x310)
    if not (carr and n and n > 0) then return end
    for i = 0, n - 1 do
        local okd, rd = pcall(function() return O:doctrine(i) end)
        if okd and rd then
            local base = "countries.#" .. (i + 1) .. "."
            local function E(path, val) emit("doctrine", base .. path, val) end
            local cc = rp(carr + 8 * i)
            local tid = cc and ru32(cc + 8)
            local tt = rp(gs + 0x358)
            local tag = tid and tt and hoi4.read_str(tt + 32 * tid) or nil
            if tag and tag ~= "" and tag ~= "---" then
                E("country", '"' .. tag .. '"')
            end
            if rd.enable_tactic and #rd.enable_tactic > 0 then
                local vs = {}
                for _, t in ipairs(rd.enable_tactic) do
                    vs[#vs + 1] = tostring(t)
                end
                E("enable_tactic.#1", table.concat(vs, " "))
            end
            for fk, fo in ipairs(rd.folders or {}) do
                local fb = "folder.#" .. fk .. "."
                if fo.folder then E(fb .. "folder", '"' .. tostring(fo.folder) .. '"') end
                if fo.grand_doctrine and fo.grand_doctrine ~= "" then
                    E(fb .. "grand_doctrine", '"' .. tostring(fo.grand_doctrine) .. '"')
                end
                for tk, tr in ipairs(fo.tracks or {}) do
                    local tb = fb .. "tracks.#" .. tk .. "."
                    if tr.sub_doctrine and tr.sub_doctrine ~= "" then
                        E(tb .. "sub_doctrine", '"' .. tostring(tr.sub_doctrine) .. '"')
                    end
                    E(tb .. "rewards", tostring(tr.rewards or 0))
                    E(tb .. "mastery", SL.num(tr.mastery or 0))
                    E(tb .. "mastery_bank", SL.num(tr.mastery_bank or 0))
                    E(tb .. "daily_mastery", SL.num(tr.daily_mastery or 0))
                    -- leaders_daily_mastery.#N.{leader,mastery} (§4.6
                    -- CCountryDoctrineStatus; track writer 0x14146A9F0 {d@+48,c@+60} 24B 条,
                    -- 块门 count>0; 匿名条目 #N 从 1 起编 — seqc 首现
                    -- 不编号与此不符, 用 ipairs 序号)
                    for li, lm in ipairs(tr.leaders_daily_mastery or {}) do
                        local lb = tb .. "leaders_daily_mastery.#"
                            .. li .. "."
                        E(lb .. "leader",
                            SL.idpair(lm.lid, lm.ltype))
                        E(lb .. "mastery", SL.num(lm.mastery or 0))
                    end
                end
            end
            for ck, cr in ipairs(rd.cost_reduction or {}) do
                local cb = "cost_reduction.#" .. ck .. "."
                E(cb .. "uses", tostring(cr.uses or 0))
                if cr.name then E(cb .. "name", '"' .. tostring(cr.name) .. '"') end
                if cr.folder then E(cb .. "folder", '"' .. tostring(cr.folder) .. '"') end
                E(cb .. "cost_factor", SL.num(cr.cost_factor or 0))
            end
            -- equipment_bonus (§4.6; reader rd.equipment_bonus.list;
            -- id = 装备原型名 lexer token, 门 lexmax, 串发射不带引号)
            do
                local lexmax = hoi4.read_u32(
                    hoi4.base() + GAME.layout.rva.lexer_token_max) or 100000
                for ei, ee in ipairs((rd.equipment_bonus or {}).list or {}) do
                    local mb = "equipment_bonus.#" .. ei .. "."
                    local idt = ee.id_tok
                    local idn = idt > 0 and idt <= lexmax
                        and SL.tok(idt) or nil
                    if idn then E(mb .. "id", tostring(idn)) end
                    E(mb .. "index", tostring(ee.index))
                    E(mb .. "equipment_bonus", tostring(ee.bonus)) end end
            for dk, dm in ipairs(rd.daily_mastery or {}) do
                local db = "daily_mastery.#" .. dk .. "."
                if dm.name then E(db .. "name", '"' .. tostring(dm.name) .. '"') end
                -- relevant_tracks (§4.6 STrackFilter; reader rt 表带
                -- vt 门解析 + track_index; 槽位 = dk 对齐)
                local rtf = (dm.relevant_tracks or {})[dk] or {}
                for _, lf in ipairs({ "track", "folder",
                    "grand_doctrine", "sub_doctrine" }) do
                    local nm = rtf[lf]
                    if nm then
                        E(db .. "relevant_tracks." .. lf,
                            '"' .. tostring(nm) .. '"') end
                end
                if rtf.track_index then
                    E(db .. "relevant_tracks.track_index",
                        tostring(rtf.track_index)) end
                E(db .. "daily_mastery", SL.num(dm.daily_mastery or 0))
                E(db .. "bonus", SL.num(dm.bonus or 0))
                E(db .. "days", tostring(dm.days or 0))
            end
        end
    end
end }
