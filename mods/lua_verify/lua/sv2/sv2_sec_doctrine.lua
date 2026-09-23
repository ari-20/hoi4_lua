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
            -- equipment_bonus (§4.6 CCountryDoctrineStatus; writer 0x1413CF470 块尾段; 容器
            -- @rd+112 {count@124}, 24B 条 {id token@+8, index@+12,
            -- equipment_bonus@+16}; 块门 count≠0, 条目恒写含 0 值;
            -- id = 装备原型名 lexer token, token 串发射不带引号)
            local ebd = rd.addr and rp(rd.addr + 112)
            local ebc = rd.addr and ru32(rd.addr + 124) or 0
            if ebd and kptr(ebd) and ebc > 0 and ebc < 4096 then
                local lexmax = hoi4.read_u32(
                    hoi4.base() + GAME.layout.rva.lexer_token_max) or 100000
                for ei = 0, ebc - 1 do
                    local ee = ebd + 24 * ei
                    if kptr(rp(ee)) then
                        local mb = "equipment_bonus.#" .. (ei + 1) .. "."
                        local idt = ru32(ee + 8) or 0
                        local idn = idt > 0 and idt <= lexmax
                            and SL.tok(idt) or nil
                        if idn then
                            E(mb .. "id", tostring(idn))
                        end
                        E(mb .. "index", tostring(ru32(ee + 12) or 0))
                        E(mb .. "equipment_bonus",
                            tostring(ru32(ee + 16) or 0))
                    end
                end
            end
            for dk, dm in ipairs(rd.daily_mastery or {}) do
                local db = "daily_mastery.#" .. dk .. "."
                if dm.name then E(db .. "name", '"' .. tostring(dm.name) .. '"') end
                -- relevant_tracks (§4.6 NDoctrines::STrackFilter; dm+40 内嵌
                -- 48B 非容器/叶序/门 = 书) — 元素基址 = rp(rd.addr+88)
                -- +112*(dk-1) (reader O.vec 无过滤, 索引对齐)
                local dmd = rd.addr and rp(rd.addr + 88)
                local dmc = rd.addr and ru32(rd.addr + 100) or 0
                if dmd and kptr(dmd) and dk <= dmc then
                    local dm0 = dmd + 112 * (dk - 1)
                    -- 1.19.3 : STrackFilter vt 0x27BAC60 → 0x27D1130
                    -- (+0x166D0; 旧门恒假致 relevant_tracks 全灭)
                    if not BASE or rp(dm0 + 40) == BASE + 0x27D1130 then
                        for _, lf in ipairs({
                            { 48, "track" }, { 56, "folder" },
                            { 64, "grand_doctrine" }, { 72, "sub_doctrine" } }) do
                            local dp = rp(dm0 + lf[1])      -- 写门: 指针≠0
                            if kptr(dp) then
                                local nm = SL.tok(ru32(dp + 8))
                                if nm then
                                    E(db .. "relevant_tracks." .. lf[2],
                                        '"' .. tostring(nm) .. '"')
                                end
                            end
                        end
                        local tidx = ru32(dm0 + 80)         -- i32, 默认 -1
                        if tidx and tidx ~= 0xFFFFFFFF then
                            E(db .. "relevant_tracks.track_index", tostring(tidx))
                        end
                    end
                end
                E(db .. "daily_mastery", SL.num(dm.daily_mastery or 0))
                E(db .. "bonus", SL.num(dm.bonus or 0))
                E(db .. "days", tostring(dm.days or 0))
            end
        end
    end
end }
