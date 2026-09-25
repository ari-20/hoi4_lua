-- example_cmd_r.lua -- R 表全集 (由 hoi4_lua/ref/cmd_registry_1193.json
-- 生成: python hoi4_lua/tools/cmd_extract.py rtable; 勿手改)
-- 键 = 命令短名, 值字段与 EXAMPLE_CMD.R 同构
-- (size/vft/isvalid/exec 裸 RVA; 内嵌对象带 ref_vft+ref_off;
-- 转发桩带 action_vft; 容器带 vec_sentinel)。载荷布局查书 §4.33.20。
-- 本文件字母序晚于 example_cmd.lua, 顶层并入 EXAMPLE_CMD.R
-- (现役四键被 registry 值覆盖 = sizeof 笔误清偿); 纯表无闭包。
local T = {
    on_ruling_party_change_action = { size=0x30, vft=0x272DEA8, isvalid=0xCAA8B0, exec=0x1157AA0 },  -- 10047 COnRulingPartyChangeActionCommand
    prototype_reward_option = { size=0x38, vft=0x2A90730, isvalid=0x1EF4290, exec=0x1EF3D60 },  -- 10050 CPrototypeRewardOptionCommand
    dismantle_facility = { size=0x30, vft=0x2A907F8, isvalid=0x1162CE0, exec=0x1EF3D00 },  -- 10080 CDismantleFacilityCommand
    abort_dismantle_facility = { size=0x30, vft=0x2A908C0, isvalid=0x1162CE0, exec=0x1EF3C30 },  -- 10085 CAbortDismantleFacilityCommand
    set_max_allowed_repair_factories = { size=0x30, vft=0x29B0240, isvalid=0x1359260, exec=0x1355F40 },  -- 10104 CSetMaxAllowedRepairFactoriesCommand
    set_market_request_automation_options = { size=0x30, vft=0x2A3F8F0, isvalid=0xCAA8B0, exec=0x1B1BB50 },  -- 10105 NInternationalMarket::CSetMarketRequestAutomationOptionsCommand
    reset_unread_prototype_rewards_counter = { size=0x30, vft=0x2A90988, isvalid=0x1162CE0, exec=0x1EF3F20 },  -- 10144 CResetUnreadPrototypeRewardsCounterCommand
    market_stockpile_clear = { size=0x30, vft=0x2AB6D08, isvalid=0xCAA8B0, exec=0x205C330 },  -- 10191 NInternationalMarket::CMarketStockpileClearCommand
    set_carrier_defensive_stance = { size=0x38, vft=0x29B0C68, isvalid=0x1358CE0, exec=0x1355010 },  -- 10227 CSetCarrierDefensiveStance
    execute_button = { size=0x38, vft=0x2A4BF10, isvalid=0x1BBFE60, exec=0x1BBFCD0 },  -- 10228 CExecuteButtonCommand
    remove_faction_program = { size=0x30, vft=0x2A49FD0, isvalid=0x1BAC330, exec=0x1BA9930 },  -- 10248 NFactions::CRemoveFactionProgramCommand
    select_bookmark = { size=0x30, vft=0x29E6198, isvalid=0x163DDA0, exec=0x163D250 },  -- 10250 CSelectBookmarkCommand
    set_difficulty = { size=0x30, vft=0x29E6260, isvalid=0x1807B0, exec=0x163D520 },  -- 10258 CSetDifficulty
    naval_mission_set_target = { size=0x58, vft=0x29B0EC0, isvalid=0x1358AC0, exec=0x1351BE0, vec_sentinel=0x3085170 },  -- 10261 CNavalMissionSetTargetCommand
    deploy_army_hq = { size=0x38, vft=0x29B2398, isvalid=0x1368EE0, exec=0x13661E0 },  -- 10283 CDeployArmyHqCommand
    selection_group = { size=0x50, vft=0x2996F98, isvalid=0x1166560, exec=0x115B660, vec_sentinel=0x3085170 },  -- 10285 CSelectionGroupCommand
    withdraw_army_hq = { size=0x30, vft=0x29B2460, isvalid=0x136BEF0, exec=0x1368310 },  -- 10291 CWithdrawArmyHqCommand
    add_task_capacity = { size=0x38, vft=0x2967B48, isvalid=0x199D290, exec=0x199C7E0 },  -- 10297 CAddTaskCapacityCommand
    set_pending_reassign_target = { size=0x40, vft=0x29B2528, isvalid=0x136B460, exec=0x1367C00 },  -- 10307 CSetPendingReassignTargetCommand
    move = { size=0x88, vft=0x29B1BC8, isvalid=0x1369CB0, exec=0x13669E0, action_vft=0x29A3A38, vec_sentinel=0x3085170 },  -- 转发内嵌动作  -- 10402 CMoveCommand
    cancel_movement = { size=0x48, vft=0x29B1E20, isvalid=0x1368790, exec=0x1365C20 },  -- 10415 CCancelMovementCommand
    automate_homebase_for_fleet = { size=0x30, vft=0x29B0DF8, isvalid=0x13581A0, exec=0x13508D0 },  -- 10417 CAutomateHomebaseForFleetCommand
    add_size = { size=0x38, vft=0x2967C10, isvalid=0x199D290, exec=0x199C7A0 },  -- 10438 CAddSizeCommand
    set_faction_upgrade = { size=0x38, vft=0x2A49A58, isvalid=0x1BACA10, exec=0x1BA9ED0 },  -- 10446 NFactions::CSetFactionUpgradeCommand
    use_faction_member_manpower = { size=0x30, vft=0x29AC938, isvalid=0x1BAD520, exec=0x1BAA460 },  -- 10449 NFactions::CUseFactionMemberManpower
    decrease_game_speed = { size=0x48, vft=0x2977108, isvalid=0x1807B0, exec=0xF069B0 },  -- 10456 CDecreaseGameSpeedCommand
    erase_faction_rule = { size=0x30, vft=0x2A49990, isvalid=0x1BAB470, exec=0x1BA94C0 },  -- 10494 NFactions::CEraseFactionRuleCommand
    update_intelligence_advisor_slot = { size=0x40, vft=0x2A4A480, isvalid=0x1BAD160, exec=0x1BAA210 },  -- 10500 NFactions::CUpdateIntelligenceAdvisorSlotCommand
    faction_set_commander = { size=0x38, vft=0x2A4A228, isvalid=0x1BABA90, exec=0x1BA96C0 },  -- 10509 NFactions::CFactionSetCommanderCommand
    faction_attach_scientist = { size=0x40, vft=0x2A4A098, isvalid=0x1BAB760, exec=0x1BA95A0 },  -- 10513 NFactions::CFactionAttachScientistCommand
    faction_unattach_scientist = { size=0x38, vft=0x2A4A160, isvalid=0x1BABD00, exec=0x1BA9700 },  -- 10514 NFactions::CFactionUnattachScientistCommand
    diplomatic_action = { size=0x30, vft=0x298B708, isvalid=0x1138E10, exec=0x1104D80 },  -- 动态token  -- 10545 CDiplomaticActionCommand
    remove_intelligence_advisor_from_slot = { size=0x30, vft=0x2A4A548, isvalid=0x1BAC4D0, exec=0x1BA99C0 },  -- 10563 NFactions::CRemoveIntelligenceAdvisorFromSlotCommand
    set_auto_update_designs_for_industrial_org = { size=0x38, vft=0x2968188, isvalid=0x1807B0, exec=0x199CA50 },  -- 10625 CSetAutoUpdateDesignsForIndustrialOrgCommand
    select_event_option = { size=0xF0, vft=0x2938E60, isvalid=0x153AFB0, exec=0x153A110 },  -- 10645 CSelectEventOptionCommand
    set_country_controller = { size=0x30, vft=0x295E368, isvalid=0xCEE530, exec=0xCECE50 },  -- 10707 CSetCountryControllerCommand
    clear_all_controllers = { size=0x28, vft=0x295E5C0, isvalid=0x1807B0, exec=0xCEC980 },  -- 10708 CClearAllControllersCommand
    add_player = { size=0xB0, vft=0x2A22D40, isvalid=0x1999000, exec=0x1997C00 },  -- 10723 CAddPlayerCommand
    set_random_seed = { size=0x30, vft=0x296A240, isvalid=0x1807B0, exec=0xDE9D30 },  -- 10731 CSetRandomSeed
    pause_game = { size=0x50, vft=0x296A560, isvalid=0x1807B0, exec=0xDE8360 },  -- 10732 CPauseGame
    autosave = { size=0x30, vft=0x296A880, isvalid=0x1807B0, exec=0xDE7C40 },  -- 10808 CAutosave
    upgrade_division_officer = { size=0x38, vft=0x29979C0, isvalid=0x11681B0, exec=0x115FA10 },  -- 11061 CUpgradeDivisionOfficerCommand
    set_game_play_options = { size=0x40, vft=0x29E6710, isvalid=0x1807B0, exec=0x163D640, ref_vft=0x2950990, ref_off=40 },  -- 11100 CSetGamePlayOptions
    ai_store_force_concentration_target = { size=0x40, vft=0x2A31D80, isvalid=0x1A747B0, exec=0x1A74550 },  -- 11169 CAiStoreForceConcentrationTargetCommand
    ai_discard_force_concentration_target = { size=0x38, vft=0x2A31E48, isvalid=0x1A747B0, exec=0x1A74100 },  -- 11170 CAiDiscardForceConcentrationTargetCommand
    client_ping = { size=0x48, vft=0x27217E0, isvalid=0x1807B0, exec=0xF05D80 },  -- 11376 CClientPingCommand
    request_game_state_synch = { size=0x40, vft=0x296A178, isvalid=0x1807B0, exec=0xDE9360, vec_sentinel=0x3085170 },  -- 11438 CRequestGameStateSynchCommand
    reopen_lobby = { size=0x28, vft=0x296A7B8, isvalid=0x1807B0, exec=0xDE8A30 },  -- 11467 CReopenLobbyCommand
    ready_after_hot_join = { size=0x50, vft=0x296A6F0, isvalid=0xDE9E40, exec=0xDE8A00 },  -- 11469 CReadyAfterHotJoinCommand
    post_hot_join = { size=0x58, vft=0x296A628, isvalid=0x1807B0, exec=0xDE83B0 },  -- 11504 CPostHotJoinCommand
    set_ready_status = { size=0x30, vft=0x29E6580, isvalid=0x163E110, exec=0x163D8B0 },  -- 11517 CSetReadyStatus
    check_sync_response = { size=0x50, vft=0x296AA10, isvalid=0x1807B0, exec=0xDE8080 },  -- 11529 CCheckSyncResponseCommand
    check_sync = { size=0x40, vft=0x296A948, isvalid=0x1807B0, exec=0xDE7C60, vec_sentinel=0x3085170 },  -- 11530 CCheckSyncCommand
    set_dlcs = { size=0x30, vft=0x2A22F98, isvalid=0x1807B0, exec=0x1998D60 },  -- 11545 CSetDLCsCommand
    set_player_ai_prefs = { size=0x40, vft=0x2993640, isvalid=0xCAA8B0, exec=0x115CA30 },  -- 11579 CSetPlayerAiPrefsCommand
    set_use_dynamic_version_positioning_variant = { size=0x38, vft=0x2A24958, isvalid=0x1162CE0, exec=0x19A4CA0 },  -- 11801 CSetUseDynamicVersionPositioningVariantCommand
    order_group = { size=0x60, vft=0x2A0AAF8, isvalid=0x184DD60, exec=0x1846510 },  -- 11983 COrderGroupCommand
    set_theatre = { size=0x38, vft=0x29B2078, isvalid=0x136B6F0, exec=0x1367CC0 },  -- 12045 CSetTheatreCommand
    set_order_group_orders_instance_names = { size=0x50, vft=0x2A0A648, isvalid=0x1162CE0, exec=0x184BA10 },  -- 12057 CSetOrderGroupOrdersInstanceNamesCommand
    hourly_tick = { size=0x40, vft=0x2976F78, isvalid=0x1807B0, exec=0xF06BF0, vec_sentinel=0x3085170 },  -- 12092 CHourlyTickCommand
    set_game_speed = { size=0x30, vft=0x29771D0, isvalid=0xF07270, exec=0xF07110 },  -- 12098 CSetGameSpeedCommand
    create_operation = { size=0x58, vft=0x2978310, isvalid=0x1A29390, exec=0x1A27660, vec_sentinel=0x3085170 },  -- 12118 CCreateOperationCommand
    set_production_line = { size=0x38, vft=0x2993AF0, isvalid=0x1166B10, exec=0x115CE70 },  -- 12142 CSetProductionLineCommand
    research = { size=0x40, vft=0x2994F40, isvalid=0x1166BC0, exec=0x115D2E0 },  -- 12144 CSetResearchCommand
    change_production_line_priority = { size=0x38, vft=0x2994C20, isvalid=0x1162CB0, exec=0x1155930 },  -- 12147 CChangeProductionLinePriorityCommand
    add_production_line_factories = { size=0x38, vft=0x2994DB0, isvalid=0x1162420, exec=0x11524C0 },  -- 12149 CAddProductionLineFactoriesCommand
    build = { size=0x50, vft=0x2994770, isvalid=0x11616F0, exec=0x1150FB0, ref_vft=0x2971F30, ref_off=48 },  -- 12151 CAddConstructionCommand
    set_order_group_cohesion_type = { size=0x38, vft=0x2A0A968, isvalid=0x1162CE0, exec=0x184B660 },  -- 12189 CSetOrderGroupCohesionTypeCommand
    create_division_template = { size=0x288, vft=0x29ABD00, isvalid=0x1BA0290, exec=0x1B9EAE0 },  -- 12197 CCreateDivisionTemplateCommand
    update_division_template = { size=0x288, vft=0x29ABC38, isvalid=0x1BA03F0, exec=0x1B9FAE0 },  -- 12198 CUpdateDivisionTemplateCommand
    strat_air_set_mission = { size=0x48, vft=0x2A1D638, isvalid=0x1948B30, exec=0x1946B40, vec_sentinel=0x3085170 },  -- 12221 CStratAirSetMissionCommand
    strat_air_enable_mission = { size=0x60, vft=0x2A1D570, isvalid=0x19488C0, exec=0x1946880 },  -- 12222 CStratAirEnableMissionCommand
    strat_air_transfer = { size=0x48, vft=0x2A1D700, isvalid=0x1948C10, exec=0x1946C40 },  -- 12230 CStratAirTransferCommand
    strat_air_split = { size=0x38, vft=0x2A1D890, isvalid=0x1948BC0, exec=0x1946BD0 },  -- 12231 CStratAirSplitCommand
    strat_air_consolidate = { size=0x40, vft=0x2A1D958, isvalid=0x1948850, exec=0x19465A0, vec_sentinel=0x3085170 },  -- 12234 CStratAirConsolidateCommand
    strat_air_cancel_transfer = { size=0x38, vft=0x2A1D7C8, isvalid=0x19487E0, exec=0x1946500 },  -- 12235 CStratAirCancelTransferCommand
    create_faction = { size=0xD0, vft=0x2995260, isvalid=0x1162F10, exec=0x1155F90, ref_vft=0x27181E0, ref_off=128, vec_sentinel=0x3085170 },  -- 12242 CCreateFactionCommand
    strat_air_day_night = { size=0x38, vft=0x2A1DBB0, isvalid=0x1948820, exec=0x1946830 },  -- 12246 CStratAirDayNightCommand
    set_production_line_amount_to_produce = { size=0x38, vft=0x2994E78, isvalid=0x1166AE0, exec=0x115CDA0 },  -- 12257 CSetProductionLineAmountToProduceCommand
    naval_mission_set_type = { size=0x48, vft=0x29AF430, isvalid=0x1358B30, exec=0x1351C50 },  -- 12272 CNavalMissionSetTypeCommand
    naval_mission_set_regions = { size=0x48, vft=0x29AF4F8, isvalid=0x1358A70, exec=0x13517C0, vec_sentinel=0x3085170 },  -- 12273 CNavalMissionSetRegionsCommand
    naval_mission_add_region = { size=0x38, vft=0x29AF5C0, isvalid=0x13584D0, exec=0x1350FE0 },  -- 12274 CNavalMissionAddRegionCommand
    naval_mission_remove_region = { size=0x48, vft=0x29AF688, isvalid=0x1358890, exec=0x1351580, vec_sentinel=0x3085170 },  -- 12275 CNavalMissionRemoveRegionCommand
    naval_mission_move = { size=0x48, vft=0x29AF750, isvalid=0x1358730, exec=0x1351260, vec_sentinel=0x3085170 },  -- 12284 CNavalMissionMoveCommand
    add_idea = { size=0x40, vft=0x2995328, isvalid=0x1161AC0, exec=0x1151720 },  -- 12303 CAddIdeaCommand
    remove_idea = { size=0x40, vft=0x2995648, isvalid=0x1165950, exec=0x1159340 },  -- 12304 CRemoveIdeaCommand
    order_set_path = { size=0x58, vft=0x2A0B520, isvalid=0x184EBA0, exec=0x184AF10, vec_sentinel=0x3085170 },  -- 12345 COrderSetPathCommand
    order_assign = { size=0x50, vft=0x2A0B200, isvalid=0x184D810, exec=0x1844530 },  -- 12350 COrderAssignCommand
    order_delete = { size=0x38, vft=0x2A0B138, isvalid=0x184DC90, exec=0x1846000 },  -- 12351 COrderDeleteCommand
    order_execute = { size=0x38, vft=0x2A0C330, isvalid=0x184DCE0, exec=0x1846450 },  -- 12352 COrderExecuteCommand
    order_unassign = { size=0x50, vft=0x2A0B2C8, isvalid=0x184EE20, exec=0x184B070 },  -- 12365 COrderUnassignCommand
    delete_order_group = { size=0x30, vft=0x2A0ABC0, isvalid=0x184D230, exec=0x1843650 },  -- 12366 CDeleteOrderGroupCommand
    set_army_leader = { size=0x40, vft=0x2A0C3F8, isvalid=0x184EFB0, exec=0x184B2E0 },  -- 12369 CSetArmyLeaderCommand
    set_fleet_leader = { size=0x38, vft=0x2A0C4C0, isvalid=0x184F0D0, exec=0x184B550 },  -- 12370 CSetFleetLeaderCommand
    create_trade = { size=0x40, vft=0x2A49150, isvalid=0x1BA56D0, exec=0x1BA54B0 },  -- 12387 CCreateTradeCommand
    create_equipment_variant = { size=0x190, vft=0x2A240C0, isvalid=0x19A5AF0, exec=0x19A30E0, ref_vft=0x2718C58, ref_off=360 },  -- 12395 CCreateEquipmentVariantCommand
    rename_equipment_variant = { size=0x50, vft=0x2A24570, isvalid=0x19A5CA0, exec=0x19A41F0 },  -- 12398 CRenameEquipmentVariantCommand
    delete_unit = { size=0x38, vft=0x29B2140, isvalid=0x1368CC0, exec=0x1365FF0 },  -- 12448 CDeleteUnitCommand
    end_turn_peace_conference = { size=0x38, vft=0x2A845D0, isvalid=0x1E53E00, exec=0x1E53B90 },  -- 12521 CEndTurnPeaceConferenceCommand
    pass_peace_conference = { size=0x30, vft=0x2A84440, isvalid=0x1E54130, exec=0x1E53BC0 },  -- 12566 CPassPeaceConferenceCommand
    set_occupation_policy = { size=0x50, vft=0x2995AF8, isvalid=0x11669B0, exec=0x115C7C0 },  -- 12568 CSetOccupationPolicyCommand
    set_country_reinforcement_priority = { size=0x30, vft=0x272DAC0, isvalid=0x1166710, exec=0x115C1C0 },  -- 12612 CSetCountryReinforcementPriorityCommand
    set_wing_reinforcement_priority = { size=0x38, vft=0x2A1DED0, isvalid=0x1948790, exec=0x19464B0 },  -- 12615 CSetWingReinforcementPriorityCommand
    support_attack = { size=0x38, vft=0x29B1FB0, isvalid=0x136BA70, exec=0x1367D70 },  -- 12620 CSupportAttackCommand
    order_set_invasion_source = { size=0x60, vft=0x2A0C588, isvalid=0x184E450, exec=0x184A920 },  -- 12643 COrderSetInvasionSourceCommand
    remove_naval_invasion_target = { size=0x38, vft=0x2A0C650, isvalid=0x184EF30, exec=0x184B250 },  -- 12660 CRemoveNavalInvasionTargetCommand
    add_naval_invasion_target = { size=0x38, vft=0x2A0C718, isvalid=0x184CF70, exec=0x1842910 },  -- 12661 CAddNavalInvasionTargetCommand
    naval_move = { size=0x48, vft=0x29AF8E0, isvalid=0x1358BB0, exec=0x1351FA0 },  -- 12664 CNavalMoveCommand
    convert_factory = { size=0x38, vft=0x2994B58, isvalid=0x1162D10, exec=0x1155C00 },  -- 12679 CConvertFactoryCommand
    add_faction_program = { size=0x38, vft=0x2A49F08, isvalid=0x1BAAC90, exec=0x1BA90E0 },  -- 12711 NFactions::CAddFactionProgramCommand
    order_set_paradrop_source = { size=0x50, vft=0x2A0CA38, isvalid=0x184E6A0, exec=0x184ABD0 },  -- 12729 COrderSetParadropSourceCommand
    order_set_paradrop_target = { size=0x38, vft=0x2A0CB00, isvalid=0x184E920, exec=0x184AEB0 },  -- 12730 COrderSetParadropTargetCommand
    set_faction_icon_and_color = { size=0x70, vft=0x2A4A2F0, isvalid=0x1BAC6E0, exec=0x1BA9A50 },  -- 12732 NFactions::CSetFactionIconAndColor
    assign_ace = { size=0x38, vft=0x2996138, isvalid=0x11629D0, exec=0x1152A80 },  -- 12778 CAssignAceCommand
    replace_idea = { size=0x48, vft=0x29958A0, isvalid=0x1165BF0, exec=0x1159B70 },  -- 13017 CReplaceIdeaCommand
    set_xorresearch = { size=0x48, vft=0x29950D0, isvalid=0x1167620, exec=0x115E670 },  -- 13028 CSetXORResearchCommand
    remove_construction = { size=0x38, vft=0x2994838, isvalid=0x1165920, exec=0x11591C0 },  -- 13088 CRemoveConstructionCommand
    remove_all_construction = { size=0x40, vft=0x2994900, isvalid=0x11656E0, exec=0x1158AF0 },  -- 13089 CRemoveAllConstructionCommand
    request_ready_status = { size=0x28, vft=0x29E6648, isvalid=0x1807B0, exec=0x163CE70 },  -- 13090 CRequestReadyStatus
    deploy_air_wing = { size=0xA8, vft=0x2995198, isvalid=0x1162FB0, exec=0x11565E0 },  -- 13091 CDeployAirWingCommand
    move_ships = { size=0x58, vft=0x29B2780, isvalid=0x1369CC0, exec=0x13669F0 },  -- 13092 CMoveShipsCommand
    order_new_front = { size=0x70, vft=0x2A0B908, isvalid=0x184E1F0, exec=0x1848FE0, vec_sentinel=0x3085170 },  -- 13095 COrderNewFrontCommand
    order_new_root = { size=0x70, vft=0x2A0BC28, isvalid=0x184E280, exec=0x18499A0 },  -- 13096 COrderNewRootCommand
    order_edit_root = { size=0x50, vft=0x2A0BF48, isvalid=0x184DC90, exec=0x1846360 },  -- 13097 COrderEditRootCommand
    order_merge_roots = { size=0x40, vft=0x2A0C1A0, isvalid=0x184E070, exec=0x1848B20 },  -- 13098 COrderMergeRootsCommand
    order_members_fair_split = { size=0x40, vft=0x2A0C268, isvalid=0x184DFA0, exec=0x18468A0 },  -- 13099 COrderMembersFairSplitCommand
    client_out_of_sync = { size=0x68, vft=0x296A3D0, isvalid=0xDE9E20, exec=0xDE8340, vec_sentinel=0x3085170 },  -- 13100 CClientOutOfSyncCommand
    add_production_line = { size=0x40, vft=0x2993708, isvalid=0x11622F0, exec=0x1152210 },  -- 13101 CAddProductionLineCommand
    release_country = { size=0x38, vft=0x2996200, isvalid=0x11655B0, exec=0x1158370 },  -- 13103 CReleaseCountryCommand
    promote_to_country_leader = { size=0x30, vft=0x295E4F8, isvalid=0xCEE410, exec=0xCECBC0 },  -- 13104 CPromoteToCountryLeaderCommand
    remove_ship_refit_production_line = { size=0x30, vft=0x2993C80, isvalid=0x1162CE0, exec=0x1159750 },  -- 13105 CRemoveShipRefitProductionLineCommand
    set_naval_deployment_target = { size=0x48, vft=0x29941F8, isvalid=0x11668C0, exec=0x115C6A0 },  -- 13106 CSetNavalDeploymentTargetCommand
    create_unit_leader = { size=0x30, vft=0x29962C8, isvalid=0x1162F60, exec=0x11562D0 },  -- 13107 CCreateUnitLeaderCommand
    delete_ship = { size=0x38, vft=0x29B2910, isvalid=0x1368AA0, exec=0x1365D60 },  -- 13150 CDeleteShipCommand
    change_country_controller = { size=0x38, vft=0x2996390, isvalid=0x1162B60, exec=0x1153210 },  -- 13174 CChangeCountryControllerCommand
    merge_navies = { size=0x48, vft=0x29B2B68, isvalid=0x13699E0, exec=0x13666A0 },  -- 13176 CMergeNaviesCommand
    order_insert_front = { size=0x98, vft=0x2A0B840, isvalid=0x184DF50, exec=0x1846610, vec_sentinel=0x3085170 },  -- 13208 COrderInsertFrontCommand
    order_reshape = { size=0x50, vft=0x2A0B5E8, isvalid=0x184E3C0, exec=0x184A7F0, vec_sentinel=0x3085170 },  -- 13214 COrderReshapeCommand
    order_set_training = { size=0x38, vft=0x2A0CBC8, isvalid=0x184EC00, exec=0x184AF70 },  -- 13215 COrderSetTrainingCommand
    set_obsolete_equipment_variant = { size=0x38, vft=0x2A24700, isvalid=0x1165920, exec=0x19A4BF0 },  -- 13225 CSetObsoleteEquipmentVariantCommand
    set_country_upgrade_priority = { size=0x30, vft=0x272DDE0, isvalid=0x1166710, exec=0x115C260 },  -- 13226 CSetCountryUpgradePriorityCommand
    order_reconnect = { size=0x40, vft=0x2A0B6B0, isvalid=0x184E2D0, exec=0x1849E20 },  -- 13232 COrderReconnectCommand
    order_connect = { size=0x40, vft=0x2A0B778, isvalid=0x184DB70, exec=0x1845820 },  -- 13233 COrderConnectCommand
    set_unit_name = { size=0x50, vft=0x29B2208, isvalid=0x136B810, exec=0xE8F1A0 },  -- 13235 CSetUnitNameCommand
    focus = { size=0x38, vft=0x2996458, isvalid=0x1166830, exec=0x115C670 },  -- 13245 CSetNationalFocusCommand
    set_ship_name = { size=0x50, vft=0x29B2848, isvalid=0x1162CE0, exec=0x1367C80 },  -- 13268 CSetShipNameCommand
    set_army_template = { size=0x48, vft=0x29B25F0, isvalid=0x136A8B0, exec=0x13675A0, vec_sentinel=0x3085170 },  -- 13270 CSetArmyTemplateCommand
    order_new_fallback = { size=0x60, vft=0x2A0BA98, isvalid=0x184E1B0, exec=0x1848FA0, vec_sentinel=0x3085170 },  -- 13271 COrderNewFallbackCommand
    order_delete_all = { size=0x30, vft=0x2A0B070, isvalid=0x1162CE0, exec=0x1845920 },  -- 13297 COrderDeleteAllCommand
    promote_unit_leader = { size=0x30, vft=0x29B2C30, isvalid=0x136A5B0, exec=0x13670D0 },  -- 13306 CPromoteUnitLeaderCommand
    mass_move = { size=0x60, vft=0x29B1C90, isvalid=0x1369610, exec=0x1366360, vec_sentinel=0x3085170 },  -- 13343 CMassMoveCommand
    add_mass_productions_line = { size=0x60, vft=0x29937D0, isvalid=0x1162260, exec=0x1152000, vec_sentinel=0x3085170 },  -- 13352 CAddMassProductionsLineCommand
    naval_mission_mass_move = { size=0x58, vft=0x29AF818, isvalid=0x1358510, exec=0x13511A0 },  -- 13353 CNavalMissionMassMoveCommand
    set_navy_engagement = { size=0x48, vft=0x29B29D8, isvalid=0x1164440, exec=0x1367B40, vec_sentinel=0x3085170 },  -- 13357 CSetNavyEngagementCommand
    set_coop_hot_join_options = { size=0x30, vft=0x29E67D8, isvalid=0x1807B0, exec=0x163D3A0 },  -- 13465 CSetCoopHotJoinOptions
    set_mpdebug_settings = { size=0x30, vft=0x29E68A0, isvalid=0x1807B0, exec=0x163D8A0 },  -- 13470 CSetMPDebugSettings
    create_conveyor = { size=0x38, vft=0x2A483C0, isvalid=0x1162CE0, exec=0x1BA3060 },  -- 13479 CCreateConveyorCommand
    set_conveyor_name = { size=0x50, vft=0x2A48550, isvalid=0x1A7FE30, exec=0x1BA3580 },  -- 13480 CSetConveyorNameCommand
    set_conveyor_location = { size=0x38, vft=0x2A48618, isvalid=0x1BA3C10, exec=0x1BA3510 },  -- 13481 CSetConveyorLocationCommand
    set_conveyor_priority = { size=0x38, vft=0x2A48870, isvalid=0x1BA4580, exec=0x1BA35F0 },  -- 13482 CSetConveyorPriorityCommand
    set_conveyor_series = { size=0x38, vft=0x2A48938, isvalid=0x1BA03B0, exec=0x1BA3660 },  -- 13483 CSetConveyorSeriesCommand
    add_conveyor_line = { size=0x38, vft=0x2A48A00, isvalid=0x1BA38C0, exec=0x1BA2D20 },  -- 13484 CAddConveyorLineCommand
    deploy_conveyor_line = { size=0x30, vft=0x2A48DE8, isvalid=0x1162CE0, exec=0x1BA3270 },  -- 13485 CDeployConveyorLineCommand
    remove_conveyor_line = { size=0x30, vft=0x2A48F78, isvalid=0x1162CE0, exec=0x1BA33A0 },  -- 13487 CRemoveConveyorLineCommand
    create_conveyor_extended = { size=0x40, vft=0x2A48488, isvalid=0x1BA39F0, exec=0x1BA3100 },  -- 13493 CCreateConveyorExtendedCommand
    set_conveyor_group = { size=0x40, vft=0x2A486E0, isvalid=0x1162CE0, exec=0x1BA3450 },  -- 13498 CSetConveyorGroupCommand
    transport_unit = { size=0x58, vft=0x29B2CF8, isvalid=0x136BA60, exec=0x13682C0, action_vft=0x29A3B08, vec_sentinel=0x3085170 },  -- 转发内嵌动作  -- 13533 CTransportUnitCommand
    set_division_template_symbol = { size=0x38, vft=0x29ABB70, isvalid=0x1162CE0, exec=0x1B9F780 },  -- 13550 CSetDivisionTemplateSymbolCommand
    set_order_group_name = { size=0x50, vft=0x2A0A580, isvalid=0x1162CE0, exec=0x184B9A0 },  -- 13563 CSetOrderGroupNameCommand
    dispatch_naval_combat_results = { size=0x48, vft=0x2993578, isvalid=0x1164440, exec=0x1156890 },  -- 13565 CDispatchNavalCombatResultsCommand
    set_order_group_motorization = { size=0x38, vft=0x2A0A710, isvalid=0x1162CE0, exec=0x184B7F0 },  -- 13571 CSetOrderGroupMotorizationCommand
    remove_division_template = { size=0x30, vft=0x29ABDC8, isvalid=0x1BA0350, exec=0x1B9F370 },  -- 13574 CRemoveDivisionTemplateCommand
    order_replace_root_commands = { size=0x70, vft=0x2A0BDB8, isvalid=0x184E280, exec=0x184A470 },  -- 13578 COrderReplaceRootCommands
    order_remove_root_commands = { size=0x30, vft=0x2A0BE80, isvalid=0x1162CE0, exec=0x184A210 },  -- 13579 COrderRemoveRootCommands
    order_replace_fallback_commands = { size=0x60, vft=0x2A0BB60, isvalid=0x184E1B0, exec=0x184A3C0, vec_sentinel=0x3085170 },  -- 13580 COrderReplaceFallbackCommands
    navy_repair_mode = { size=0x50, vft=0x29AEF80, isvalid=0x1358CB0, exec=0x13535E0 },  -- 13581 CNavyRepairModeCommand
    navy_repair_now = { size=0x38, vft=0x29AEEB8, isvalid=0x1358CE0, exec=0x13536B0 },  -- 13583 CNavyRepairNowCommand
    navy_cancel_repair = { size=0x48, vft=0x29AEDF0, isvalid=0x1164440, exec=0x1352D90 },  -- 13590 CNavyCancelRepairCommand
    navy_detach_ships_and_repair = { size=0x48, vft=0x29AED28, isvalid=0x1358C10, exec=0x1353450 },  -- 13599 CNavyDetachShipsAndRepairCommand
    deploy_conveyor = { size=0x30, vft=0x2A48AC8, isvalid=0x1162CE0, exec=0x1BA3200 },  -- 13600 CDeployConveyorCommand
    remove_conveyor = { size=0x30, vft=0x2A48D20, isvalid=0x1162CE0, exec=0x1BA3320 },  -- 13601 CRemoveConveyorCommand
    remove_building_level = { size=0x38, vft=0x29949C8, isvalid=0x1165750, exec=0x1158E40 },  -- 13604 CRemoveBuildingLevelCommand
    set_timed_activity_distribution_priority = { size=0x38, vft=0x2996840, isvalid=0x1167600, exec=0x115E550 },  -- 13614 CSetTimedActivityDistributionPriorityCommand
    add_mass_factory_assignment = { size=0x58, vft=0x2993A28, isvalid=0x1161BE0, exec=0x1151D00 },  -- 13636 CAddMassFactoryAssignmentCommand
    strat_air_change_aggressivness = { size=0x38, vft=0x2A1DC78, isvalid=0x1948820, exec=0x1946550 },  -- 13637 CStratAirChangeAggressivnessCommand
    mass_remove_productions_line = { size=0x40, vft=0x2993898, isvalid=0x1164DD0, exec=0x11578A0 },  -- 13638 CMassRemoveProductionsLineCommand
    strat_air_move_equipment = { size=0x80, vft=0x2A1DA20, isvalid=0x1948980, exec=0x1946950 },  -- 13642 CStratAirMoveEquipmentCommand
    strat_air_move_equipment_to_reserves = { size=0x78, vft=0x2A1DAE8, isvalid=0x1948AA0, exec=0x1946A80 },  -- 13646 CStratAirMoveEquipmentToReservesCommand
    auto_merge_orders = { size=0x38, vft=0x2A0B9D0, isvalid=0x184D200, exec=0x1843540 },  -- 13650 CAutoMergeOrdersCommand
    delete_air_wing = { size=0x48, vft=0x2A1DF98, isvalid=0x19480D0, exec=0x1944DC0 },  -- 13651 CDeleteAirWingCommand
    ask_to_coop_with_country = { size=0x30, vft=0x295E430, isvalid=0xCEE2C0, exec=0xCEC380 },  -- 13682 CAskToCoopWithCountryCommand
    set_naval_production_line_air_wing_composition = { size=0x50, vft=0x2994130, isvalid=0x1166910, exec=0x115C750 },  -- 13694 CSetNavalProductionLineAirWingCompositionCommand
    set_carrier_sticky_mission_area = { size=0x38, vft=0x2A1E060, isvalid=0x1165920, exec=0x1946340 },  -- 13713 CSetCarrierStickyMissionAreaCommand
    toggle_pinned_strategic_region = { size=0x30, vft=0x2A87BA0, isvalid=0x1E74890, exec=0x1E74600 },  -- 13725 CTogglePinnedStrategicRegionCommand
    start_game = { size=0x28, vft=0x29E6008, isvalid=0x1807B0, exec=0x163DA10 },  -- 13726 CStartGameCommand
    set_pinned_strategic_region = { size=0x48, vft=0x2A87D30, isvalid=0x1807B0, exec=0x1E744A0, vec_sentinel=0x3085170 },  -- 13728 CSetPinnedStrategicRegionCommand
    strategic_redeployment = { size=0x50, vft=0x29B2DC0, isvalid=0x136BA60, exec=0x13669E0, action_vft=0x29A3BD8, vec_sentinel=0x3085170 },  -- 转发内嵌动作  -- 13753 CStrategicRedeploymentCommand
    assign_to_theater_group = { size=0x68, vft=0x2A326D0, isvalid=0x1A7FB40, exec=0x1A7E8C0 },  -- 13789 CAssignToTheaterGroupCommand
    disband_theater_group = { size=0x30, vft=0x2A32860, isvalid=0x1162CE0, exec=0x1A7EA50 },  -- 13790 CDisbandTheaterGroupCommand
    set_theater_group_name = { size=0x50, vft=0x2A32928, isvalid=0x1A7FE30, exec=0x1A7F5C0 },  -- 13791 CSetTheaterGroupNameCommand
    set_theater_group_priority = { size=0x38, vft=0x2A329F0, isvalid=0x1A7FE70, exec=0x1A7F600 },  -- 13792 CSetTheaterGroupPriorityCommand
    done_peace_conference = { size=0x30, vft=0x2A84508, isvalid=0x1E53C10, exec=0x1E53B70 },  -- 13830 CDonePeaceConferenceCommand
    market_stockpile_equipment_transfer = { size=0xB0, vft=0x2A3F9C0, isvalid=0x1B1C0C0, exec=0x1B1BF30 },  -- 13859 NInternationalMarket::CMarketStockpileEquipmentTransferCommand
    mass_cancel_movement = { size=0x40, vft=0x2993960, isvalid=0x1164DC0, exec=0x1157820 },  -- 13872 CMassCancelMovementCommand
    edit_area_defense_state = { size=0x58, vft=0x2A0C7E0, isvalid=0x184D2B0, exec=0x18436E0 },  -- 13873 CEditAreaDefenseStateCommand
    queue_unit_action = { size=0x38, vft=0x29B2E88, isvalid=0x136A6B0, exec=0x13672E0 },  -- 动态token  -- 13894 CQueueUnitActionCommand
    remove_player = { size=0x60, vft=0x2A22ED0, isvalid=0x1999900, exec=0x19981F0 },  -- 13901 CRemovePlayerCommand
    set_country_controller_type = { size=0x30, vft=0x295E688, isvalid=0xCAA8B0, exec=0xCEDD10 },  -- 13908 CSetCountryControllerTypeCommand
    order_add_new_complete_plan = { size=0x80, vft=0x2A0BCF0, isvalid=0x184D7C0, exec=0x18442B0, vec_sentinel=0x3085170 },  -- 13918 COrderAddNewCompletePlanCommand
    set_order_group_icon_and_color = { size=0x60, vft=0x2A0A7D8, isvalid=0x1162CE0, exec=0x184B740, ref_vft=0x27181E0, ref_off=48 },  -- 13924 CSetOrderGroupIconAndColorCommand
    remove_all_production_line = { size=0x30, vft=0x2993D48, isvalid=0xCAA8B0, exec=0x1158CB0 },  -- 13979 CRemoveAllProductionLineCommand
    set_order_group_execution_type = { size=0x38, vft=0x2A0A8A0, isvalid=0x1162CE0, exec=0x184B6D0 },  -- 13992 CSetOrderGroupExecutionTypeCommand
    add_human = { size=0xF8, vft=0x2A22E08, isvalid=0x1998FF0, exec=0x19977E0 },  -- 13995 CAddHumanCommand
    request_game_state_transfer = { size=0x50, vft=0x296A0B0, isvalid=0x1807B0, exec=0xDE98C0 },  -- 13997 CRequestGameStateTransferCommand
    collapse_conveyor = { size=0x30, vft=0x2A48B90, isvalid=0x1162CE0, exec=0x1BA3010 },  -- 14003 CCollapseConveyorCommand
    change_conveyor_position = { size=0x38, vft=0x2A48C58, isvalid=0x1162CE0, exec=0x1BA2DE0 },  -- 14004 CChangeConveyorPositionCommand
    replace_building = { size=0xB0, vft=0x2994A90, isvalid=0x1165BE0, exec=0x1159B20, ref_vft=0x29949C8, ref_off=40 },  -- 14005 CReplaceBuildingCommand
    set_custom_difficulty_multiplier = { size=0x50, vft=0x29E6328, isvalid=0x163DDB0, exec=0x163D3F0 },  -- 14008 CSetCustomDifficultyMultiplier
    override_market_equipment_price_levels = { size=0x40, vft=0x2A3F820, isvalid=0xCAA8B0, exec=0x1B1B930 },  -- 14010 NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand
    change_conveyor_template = { size=0x38, vft=0x2A487A8, isvalid=0x1BA3990, exec=0x1BA2F00 },  -- 14022 CChangeConveyorTemplateCommand
    set_equipment_variant_highlight = { size=0x38, vft=0x2A24638, isvalid=0x1162CE0, exec=0x19A44D0 },  -- 14038 CSetEquipmentVariantHighlightCommand
    set_continuous_focus = { size=0x38, vft=0x29966B0, isvalid=0x11666E0, exec=0x115BC50 },  -- 14048 CSetContinuousFocusCommand
    drop_continuous_focus = { size=0x30, vft=0x2996778, isvalid=0x1164450, exec=0x1156900 },  -- 14050 CDropContinuousFocusCommand
    promote_autonomy = { size=0x30, vft=0x29AB3F8, isvalid=0x1B8E670, exec=0x1B8E4A0 },  -- 14061 CPromoteAutonomyCommand
    remove_autonomy = { size=0x30, vft=0x29AB4C0, isvalid=0x1B8E6B0, exec=0x1B8E580 },  -- 14062 CRemoveAutonomyCommand
    set_area_defense_setting = { size=0x38, vft=0x2A0C970, isvalid=0x184DC90, exec=0x184B290 },  -- 14063 CSetAreaDefenseSettingCommand
    order_block_sections = { size=0x58, vft=0x2A0B458, isvalid=0x1165920, exec=0x1845720, vec_sentinel=0x3085170 },  -- 14069 COrderBlockSectionsCommand
    bypass_national_focus = { size=0x38, vft=0x29965E8, isvalid=0x1162A80, exec=0x11531E0 },  -- 14250 CBypassNationalFocusCommand
    drop_current_national_focus = { size=0x30, vft=0x2996520, isvalid=0x1164490, exec=0x1156920 },  -- 14257 CDropCurrentNationalFocusCommand
    set_production_line_convert = { size=0x38, vft=0x2993E10, isvalid=0x1166B90, exec=0x115CFE0 },  -- 14301 CSetProductionLineConvertCommand
    set_air_wing_name = { size=0x50, vft=0x2A1E128, isvalid=0xE8F550, exec=0x19462E0 },  -- 14312 CSetAirWingNameCommand
    merge_armies = { size=0x48, vft=0x29B2F50, isvalid=0x1369630, exec=0x1366400 },  -- 14344 CMergeArmiesCommand
    select_decision = { size=0x38, vft=0x2996908, isvalid=0x1165F10, exec=0x115ADE0 },  -- 14345 CSelectDecisionCommand
    send_ping = { size=0x78, vft=0x296A498, isvalid=0xDE9E70, exec=0xDE9A20 },  -- 14350 CSendPingCommand
    set_production_line_priority = { size=0x40, vft=0x2994CE8, isvalid=0x1164440, exec=0x115D190, vec_sentinel=0x3085170 },  -- 14372 CSetProductionLinePriorityCommand
    select_targeted_decision = { size=0x40, vft=0x29969D0, isvalid=0x1166030, exec=0x115B0E0 },  -- 14383 CSelectTargetedDecisionCommand
    stockpiled_equipment_delete = { size=0x38, vft=0x2A247C8, isvalid=0x19A5DD0, exec=0x19A4DE0 },  -- 14424 CStockpiledEquipmentDeleteCommand
    army_group = { size=0x80, vft=0x2A0AC88, isvalid=0x184CFC0, exec=0x1842970, vec_sentinel=0x3085170 },  -- 14433 CArmyGroupCommand
    set_army_to_consolidate_for_unit = { size=0x38, vft=0x29B1D58, isvalid=0x1358CE0, exec=0x1367A40 },  -- 14463 CSetArmyToConsolidateForUnit
    assign_to_army_group = { size=0x50, vft=0x2A0AD50, isvalid=0x184D170, exec=0x18431A0 },  -- 14470 CAssignToArmyGroupCommand
    remove_from_army_group = { size=0x40, vft=0x2A0AE18, isvalid=0x1164DD0, exec=0x184B1E0 },  -- 14471 CRemoveFromArmyGroupCommand
    unlock_industrial_organisation_trait = { size=0x48, vft=0x2967CD8, isvalid=0x199D910, exec=0x199CF00 },  -- 14495 CUnlockIndustrialOrganisationTrait
    set_industrial_manufacturer = { size=0x40, vft=0x2A23280, isvalid=0x199D780, exec=0x199CC70 },  -- 14496 CSetIndustrialManufacturerCommand
    trigger_ability = { size=0x78, vft=0x2996B60, isvalid=0x11676F0, exec=0x115E8C0 },  -- 14513 CTriggerAbilityCommand
    learn_trait = { size=0x38, vft=0x2A0CD58, isvalid=0x184D300, exec=0x18439B0 },  -- 14525 CLearnTraitCommand
    set_division_name = { size=0x58, vft=0x29B22D0, isvalid=0x136B320, exec=0x1367AB0 },  -- 14601 CSetDivisionNameCommand
    set_deployment_line_name = { size=0x58, vft=0x2A48EB0, isvalid=0x1162CE0, exec=0x1BA36D0 },  -- 14612 CSetDeploymentLineNameCommand
    attach_air_wing_to_army = { size=0x48, vft=0x2A1E1F0, isvalid=0x1947FF0, exec=0x1944CD0 },  -- 14636 CAttachAirWingToArmyCommand
    detach_air_wing_from_army = { size=0x40, vft=0x2A1E2B8, isvalid=0x1948190, exec=0x1945130 },  -- 14637 CDetachAirWingFromArmyCommand
    production_line_interface_toggle_expand = { size=0x48, vft=0x2993FA0, isvalid=0x1164EC0, exec=0x1158100 },  -- 14678 CProductionLineInterfaceToggleExpandCommand
    production_line_interface_toggle_expand_all = { size=0x30, vft=0x2994068, isvalid=0xCAA8B0, exec=0x1157F50 },  -- 14699 CProductionLineInterfaceToggleExpandAllCommand
    toggle_bombing_priority = { size=0x38, vft=0x2A1E380, isvalid=0x1948CC0, exec=0x1946E60 },  -- 14706 CToggleBombingPriorityCommand
    production_line_interface_factories_scale = { size=0x48, vft=0x2993ED8, isvalid=0x1164E40, exec=0x1157D50 },  -- 14730 CProductionLineInterfaceFactoriesScaleCommand
    ignore_decision = { size=0x50, vft=0x2996C28, isvalid=0x1164A20, exec=0x1157240, vec_sentinel=0x3085170 },  -- 14768 CIgnoreDecisionCommand
    ignore_targeted_decision = { size=0x50, vft=0x2996D40, isvalid=0x1164B10, exec=0x1157540, vec_sentinel=0x3085170 },  -- 14769 CIgnoreTargetedDecisionCommand
    more_ground_crews = { size=0x38, vft=0x2A1E448, isvalid=0x1948200, exec=0x1945190 },  -- 14785 CMoreGroundCrewsCommand
    set_naval_region_access = { size=0x50, vft=0x29AFA70, isvalid=0x1359400, exec=0x13560B0, vec_sentinel=0x3085170 },  -- 14858 CSetNavalRegionAccessCommand
    set_country_operations_priority = { size=0x30, vft=0x272DC50, isvalid=0x1166710, exec=0x115BF30 },  -- 14859 CSetCountryOperationsPriorityCommand
    set_operation_target = { size=0x38, vft=0x29786F8, isvalid=0x1A2B890, exec=0x1A284D0 },  -- 14860 CSetOperationTargetCommand
    reserve_operative_for_operation = { size=0x50, vft=0x2978248, isvalid=0x1A2AE10, exec=0x1A27F70 },  -- 14861 CReserveOperativeForOperationCommand
    delete_operation = { size=0x38, vft=0x29783D8, isvalid=0x1A296A0, exec=0x1A276B0 },  -- 14862 CDeleteOperationCommand
    move_air_wing_and_air_group_to_air_theatre = { size=0x68, vft=0x2A1E510, isvalid=0x19484B0, exec=0x1945610, vec_sentinel=0x3085170 },  -- 14863 CMoveAirWingAndAirGroupToAirTheatreCommand
    move_air_group_and_air_theatre_to_free = { size=0x68, vft=0x2A1E5D8, isvalid=0x19483A0, exec=0x19452E0, vec_sentinel=0x3085170 },  -- 14864 CMoveAirGroupAndAirTheatreToFreeCommand
    move_air_wing_to_air_group = { size=0x50, vft=0x2A1E6A0, isvalid=0x19485A0, exec=0x1945DE0, vec_sentinel=0x3085170 },  -- 14865 CMoveAirWingToAirGroupCommand
    rename_air_theatre = { size=0x50, vft=0x2A1E830, isvalid=0x1948650, exec=0x1946170 },  -- 14866 CRenameAirTheatreCommand
    rename_air_group = { size=0x50, vft=0x2A1E8F8, isvalid=0x1948650, exec=0x1946120 },  -- 14867 CRenameAirGroupCommand
    change_air_group_insignia = { size=0x60, vft=0x2A1E9C0, isvalid=0x1948090, exec=0x1944D80, ref_vft=0x27181E0, ref_off=48 },  -- 14868 CChangeAirGroupInsigniaCommand
    reorder_air_theaters = { size=0x38, vft=0x2A1E768, isvalid=0x1162CE0, exec=0x19461C0 },  -- 14869 CReorderAirTheatersCommand
    set_quick_deploy_preference = { size=0x48, vft=0x2A1EA88, isvalid=0x1948690, exec=0x1946380, vec_sentinel=0x3085170 },  -- 14876 CSetQuickDeployPreferenceCommand
    order_set_collapse = { size=0x38, vft=0x2A0CC90, isvalid=0x184E410, exec=0x184A8E0 },  -- 14895 COrderSetCollapseCommand
    update_leader_seen_traits_count = { size=0x38, vft=0x2A0CE20, isvalid=0x1165920, exec=0x184BBA0 },  -- 14918 CUpdateLeaderSeenTraitsCountCommand
    create_area_defense = { size=0x50, vft=0x2A0C8A8, isvalid=0x1165920, exec=0x18435A0, vec_sentinel=0x3085170 },  -- 14954 CCreateAreaDefenseCommand
    execute_scripted_window_effect = { size=0x98, vft=0x2996ED0, isvalid=0x11644D0, exec=0x1156950, vec_sentinel=0x3085170 },  -- 14966 CExecuteScriptedWindowEffect
    set_selected_army_group_fallback = { size=0x38, vft=0x2A0D140, isvalid=0x184F150, exec=0x184BB00 },  -- 14987 CSetSelectedArmyGroupFallback
    move_armies_in_theater = { size=0x48, vft=0x2A0AEE0, isvalid=0x184D700, exec=0x1843A40 },  -- 14990 CMoveArmiesInTheaterCommand
    move_army_group_in_theater = { size=0x38, vft=0x2A0AFA8, isvalid=0x1359530, exec=0x1843F10 },  -- 14991 CMoveArmyGroupInTheaterCommand
    reorder_theaters = { size=0x38, vft=0x2A32798, isvalid=0x1162CE0, exec=0x1A7ECC0 },  -- 14993 CReorderTheatersCommand
    reorder_pinned_strategic_region = { size=0x38, vft=0x2A87C68, isvalid=0x1E74890, exec=0x1E74370 },  -- 14994 CReorderPinnedStrategicRegionCommand
    set_pride_of_the_fleet = { size=0x38, vft=0x29AF9A8, isvalid=0x1359420, exec=0x1356850 },  -- 15001 CSetPrideOfTheFleetCommand
    create_fleet = { size=0x90, vft=0x29AFB38, isvalid=0x1358300, exec=0x1350A90 },  -- 15158 CCreateFleetCommand
    reorder_navy_theater_group = { size=0x38, vft=0x2A32AB8, isvalid=0x1A7FDD0, exec=0x1A7EAA0 },  -- 15160 CReorderNavyTheaterGroupCommand
    set_navy_theater_group_for = { size=0x68, vft=0x2A32B80, isvalid=0x1A7FE10, exec=0x1A7EEA0 },  -- 15161 CSetNavyTheaterGroupForCommand
    set_fleet_name = { size=0x50, vft=0x29AFC00, isvalid=0x13591E0, exec=0x1355ED0 },  -- 15163 CSetFleetNameCommand
    set_navy_theater_group_name = { size=0x50, vft=0x2A32C48, isvalid=0x13591E0, exec=0x1A7F580 },  -- 15164 CSetNavyTheaterGroupNameCommand
    set_fleet = { size=0x48, vft=0x29AFCC8, isvalid=0x1359180, exec=0x1355060 },  -- 15165 CSetFleetCommand
    set_task_force_auto_reinforcement = { size=0x48, vft=0x29AFE58, isvalid=0x1164440, exec=0x13568E0 },  -- 15170 CSetTaskForceAutoReinforcementCommand
    set_task_force_composition_requirements = { size=0x98, vft=0x29AFF20, isvalid=0x1359530, exec=0x13569C0 },  -- 15171 CSetTaskForceCompositionRequirementsCommand
    set_as_reserve_fleet = { size=0x70, vft=0x29B00B0, isvalid=0x1359160, exec=0x1354E20 },  -- 15172 CSetAsReserveFleetCommand
    reorganize_ships = { size=0x58, vft=0x29B06F0, isvalid=0x1358FB0, exec=0x1353AE0 },  -- 15174 CReorganizeShipsCommand
    set_task_force_icon_and_color = { size=0x60, vft=0x29B0948, isvalid=0x13591C0, exec=0x1356A00, ref_vft=0x27181E0, ref_off=48 },  -- 15177 CSetTaskForceIconAndColorCommand
    set_fleet_icon_and_color = { size=0x60, vft=0x29B0880, isvalid=0x13591C0, exec=0x1355E80, ref_vft=0x27181E0, ref_off=48 },  -- 15178 CSetFleetIconAndColorCommand
    navy_detach_ships_and_merge = { size=0x48, vft=0x29AF110, isvalid=0x1358C10, exec=0x1352E90 },  -- 15179 CNavyDetachShipsAndMergeCommand
    navy_cancel_activity = { size=0x40, vft=0x29AF368, isvalid=0x1164440, exec=0x13526D0 },  -- 15181 CNavyCancelActivityCommand
    set_game_rule_option = { size=0x30, vft=0x29E63F0, isvalid=0x163E050, exec=0x163D770 },  -- 15203 CSetGameRuleOption
    reset_game_rules = { size=0x28, vft=0x2A99B60, isvalid=0x1807B0, exec=0x163D130 },  -- 15205 CResetGameRules
    reset_custom_difficulty_multipliers = { size=0x28, vft=0x2A99A98, isvalid=0x1807B0, exec=0x163D020 },  -- 15206 CResetCustomDifficultyMultipliers
    navy_cancel_refit = { size=0x60, vft=0x29AF2A0, isvalid=0x1164440, exec=0x13527B0 },  -- 15229 CNavyCancelRefitCommand
    navy_detach_ships_and_refit = { size=0x58, vft=0x29AF1D8, isvalid=0x1358C50, exec=0x1353280 },  -- 15230 CNavyDetachShipsAndRefitCommand
    set_ship_refit_deployment_target = { size=0x48, vft=0x29942C0, isvalid=0x11668C0, exec=0x115D9D0 },  -- 15233 CSetShipRefitDeploymentTargetCommand
    remove_production_line = { size=0x30, vft=0x2993BB8, isvalid=0x1165920, exec=0x1159500 },  -- 15235 CRemoveProductionLineCommand
    set_game_unique_id = { size=0x48, vft=0x296A308, isvalid=0xDE9E80, exec=0xDE9C10 },  -- 15237 CSetGameUniqueId
    cancel_running_away = { size=0x30, vft=0x29B2AA0, isvalid=0x1358CE0, exec=0x1365CF0 },  -- 15284 CCancelRunningAwayCommand
    navy_clear_accident_reports = { size=0x30, vft=0x29AFFE8, isvalid=0x1358BF0, exec=0x1352E60 },  -- 15301 CNavyClearAccidentReportsCommand
    reinstate_exile = { size=0x30, vft=0x2997060, isvalid=0x1164F30, exec=0x1158310 },  -- 15317 CReinstateExileCommand
    change_production_line_name_priority = { size=0x38, vft=0x2994388, isvalid=0x1162C80, exec=0x11558F0 },  -- 15318 CChangeProductionLineNamePriorityCommand
    remove_production_line_name = { size=0x38, vft=0x29946A8, isvalid=0x1165A20, exec=0x11596B0 },  -- 15319 CRemoveProductionLineName
    add_production_line_name = { size=0x50, vft=0x2994450, isvalid=0x1162480, exec=0x11525A0 },  -- 15320 CAddProductionLineName
    set_state_override_occupation_policy = { size=0x50, vft=0x2995BC0, isvalid=0x11673B0, exec=0x115DDD0 },  -- 15324 CSetStateOverrideOccupationPolicyCommand
    set_max_allowed_repair_dockyards = { size=0x30, vft=0x29B0178, isvalid=0x1359200, exec=0x1355F10 },  -- 15337 CSetMaxAllowedRepairDockyards
    reorder_naval_repair_queue = { size=0x40, vft=0x29B0308, isvalid=0x1358DE0, exec=0x1353990 },  -- 15339 CReorderNavalRepairQueue
    switch_naval_repair_dockyard = { size=0x40, vft=0x29B0498, isvalid=0x1359550, exec=0x1356A80 },  -- 15340 CSwitchNavalRepairDockyard
    request_expeditionaries = { size=0x50, vft=0x2996A98, isvalid=0x1165D30, exec=0x1159F90, vec_sentinel=0x3085170 },  -- 15341 CRequestExpeditionariesCommand
    add_to_or_remove_ship_from_naval_repair_queue = { size=0x40, vft=0x29B03D0, isvalid=0x1357FE0, exec=0x13505B0 },  -- 15342 CAddToOrRemoveShipFromNavalRepairQueue
    change_naval_base_repair_priority = { size=0x30, vft=0x29B0560, isvalid=0x13581C0, exec=0x1350960 },  -- 15344 CChangeNavalBaseRepairPriorityCommand
    disengage_from_naval_combat = { size=0x38, vft=0x29B07B8, isvalid=0x1358350, exec=0x1350F40 },  -- 15345 CDisengageFromNavalCombatCommand
    set_naval_base_disabled_for_repairs_state = { size=0x38, vft=0x29B0628, isvalid=0x13592C0, exec=0x1355F70 },  -- 15435 CSetNavalBaseDisabledForRepairsStateCommand
    show_scripted_diplomatic_action_send_popup = { size=0x38, vft=0x2997128, isvalid=0x1168350, exec=0x115FEB0 },  -- 15473 ShowScriptedDiplomaticActionSendPopupCommand
    set_equipment_variant_override_model = { size=0x50, vft=0x2A24250, isvalid=0x1165920, exec=0x19A4930 },  -- 15496 CSetEquipmentVariantOverrideModelCommand
    set_equipment_variant_name_list = { size=0x50, vft=0x2A244A8, isvalid=0x19A5CE0, exec=0x19A4580 },  -- 15497 CSetEquipmentVariantNameListCommand
    add_production_line_ordered_name = { size=0x38, vft=0x2994518, isvalid=0x11624E0, exec=0x11526C0 },  -- 15498 CAddProductionLineOrderedName
    add_production_line_unordered_name = { size=0x38, vft=0x29945E0, isvalid=0x11624E0, exec=0x11527E0 },  -- 15499 CAddProductionLineUnorderedName
    set_equipment_variant_override_sprite = { size=0x60, vft=0x2A24318, isvalid=0x1165920, exec=0x19A4A80 },  -- 15505 CSetEquipmentVariantOverrideSpriteCommand
    update_equipment_variant = { size=0x180, vft=0x2A24188, isvalid=0x19A5E20, exec=0x19A4F60, ref_vft=0x2718C58, ref_off=344 },  -- 15524 CUpdateEquipmentVariantCommand
    set_equipment_variant_niche_icon = { size=0x38, vft=0x2A243E0, isvalid=0x1165920, exec=0x19A46F0 },  -- 15525 CSetEquipmentVariantNicheIconCommand
    set_intelligence_agency_random_historical_name = { size=0x30, vft=0x2A2E818, isvalid=0x1A2B090, exec=0x1A28320 },  -- 15537 CSetIntelligenceAgencyRandomHistoricalNameCommand
    set_fuel_priority = { size=0x38, vft=0x2996070, isvalid=0xCAA8B0, exec=0x115C4C0 },  -- 15573 CSetFuelPriorityCommand
    set_navy_theater_group_important = { size=0x38, vft=0x2A32D10, isvalid=0x1359530, exec=0x1A7F550 },  -- 15576 CSetNavyTheaterGroupImportantCommand
    toggle_strategic_deployment = { size=0x40, vft=0x29B1EE8, isvalid=0x136BD80, exec=0x1367F00, vec_sentinel=0x3085170 },  -- 15584 CToggleStrategicDeploymentCommand
    mark_sunk_ship_info_as_read = { size=0x38, vft=0x29B0A10, isvalid=0x13583B0, exec=0x1350FA0 },  -- 15625 CMarkSunkShipInfoAsReadCommand
    incoming_diplomatic_action_acting = { size=0x40, vft=0x29971F0, isvalid=0x1164C10, exec=0x11577E0 },  -- 15628 CIncomingDiplomaticActionActingCommand
    amend_incoming_lend_lease_action = { size=0x40, vft=0x29972B8, isvalid=0x1162820, exec=0x1152950 },  -- 15629 CAmendIncomingLendLeaseActionCommand
    dismiss_operative = { size=0x38, vft=0x2A2E2A0, isvalid=0x1A296C0, exec=0x1A277D0 },  -- 15637 CDismissOperativeCommand
    set_operative_codename = { size=0x58, vft=0x2A2E368, isvalid=0x1A2B8A0, exec=0x1A28800 },  -- 15640 CSetOperativeCodenameCommand
    set_operative_mission = { size=0x68, vft=0x2A2EA70, isvalid=0x1A2B8F0, exec=0x1A28870, ref_vft=0x2955B40, ref_off=72, vec_sentinel=0x3085170 },  -- 15657 CSetOperativeMissionCommand
    intelligence_agency_creation = { size=0x30, vft=0x2A2E430, isvalid=0x1A298E0, exec=0x1A27C00 },  -- 15670 CIntelligenceAgencyCreationCommand
    set_intelligence_agency_logo = { size=0x50, vft=0x2A2E8E0, isvalid=0x1358DC0, exec=0x1A281C0 },  -- 15671 CSetIntelligenceAgencyLogoCommand
    set_intelligence_agency_name = { size=0x50, vft=0x2A2E750, isvalid=0x1A2AF00, exec=0x1A28270 },  -- 15672 CSetIntelligenceAgencyNameCommand
    intelligence_agency_upgrade = { size=0x38, vft=0x2A2E5C0, isvalid=0x1A29950, exec=0x1A27CF0 },  -- 15679 CIntelligenceAgencyUpgradeCommand
    order_child_front_ratio = { size=0x48, vft=0x2A0C010, isvalid=0x184DB00, exec=0x1845770 },  -- 15758 COrderChildFrontRatioCommand
    order_delete_child_front = { size=0x40, vft=0x2A0B390, isvalid=0x184DC00, exec=0x1845F90 },  -- 15782 COrderDeleteChildFront
    order_reorder_child_front = { size=0x40, vft=0x2A0C0D8, isvalid=0x184E330, exec=0x184A340 },  -- 15785 COrderReorderChildFrontCommand
    give_medal = { size=0x48, vft=0x2997B50, isvalid=0x1164870, exec=0x1156BD0 },  -- 15871 CGiveMedalCommand
    update_profile_badge = { size=0x38, vft=0x2A22C48, isvalid=0x1996C10, exec=0x1996AA0 },  -- 16118 CUpdateProfileBadgeCommand
    attach_policy_to_industrial_org = { size=0x38, vft=0x2967DA0, isvalid=0x199D2C0, exec=0x199C820 },  -- 16260 CAttachPolicyToIndustrialOrgCommand
    move_industrial_org_trait_in_queue = { size=0x50, vft=0x2967FF8, isvalid=0x199D2F0, exec=0x199C9D0 },  -- 16390 CMoveIndustrialOrgTraitInQueueCommand
    attach_scientist = { size=0x40, vft=0x2A90410, isvalid=0x1EF4110, exec=0x1EF3C80 },  -- 16398 CAttachScientistCommand
    unattach_scientist = { size=0x38, vft=0x2A904D8, isvalid=0x1EF4730, exec=0x1EF4010 },  -- 16399 CUnattachScientistCommand
    start_project = { size=0x38, vft=0x2A905A0, isvalid=0x1EF4530, exec=0x1EF3F60 },  -- 16402 CStartProjectCommand
    stop_project = { size=0x30, vft=0x2A90668, isvalid=0x1EF4680, exec=0x1EF3FD0 },  -- 16403 CStopProjectCommand
    add_industrial_org_trait_to_queue = { size=0x48, vft=0x2967E68, isvalid=0x199D220, exec=0x199C760 },  -- 16412 CAddIndustrialOrgTraitToQueueCommand
    remove_industrial_org_trait_from_queue = { size=0x48, vft=0x2967F30, isvalid=0x199D3A0, exec=0x199CA10 },  -- 16413 CRemoveIndustrialOrgTraitFromQueueCommand
    navy_set_underway_replenishment = { size=0x48, vft=0x29AF048, isvalid=0x1358D20, exec=0x1353700 },  -- 16467 CNavySetUnderwayReplenishmentCommand
    set_raid_risk_level = { size=0x38, vft=0x2A41650, isvalid=0x1B34200, exec=0x1B33560 },  -- 16602 NRaids::NNet::CSetRaidRiskLevelCommand
    set_country_raids_priority = { size=0x30, vft=0x272DD18, isvalid=0x1166710, exec=0x115C030 },  -- 16737 CSetCountryRaidsPriorityCommand
    set_fleet_home_base = { size=0x38, vft=0x29AFD90, isvalid=0x13591A0, exec=0x13559E0 },  -- 16738 CSetFleetHomeBaseCommand
    unlock_folder_doctrine_sharing = { size=0x38, vft=0x2A49D78, isvalid=0x1BACDA0, exec=0x1BA9F50 },  -- 16755 NFactions::CUnlockFolderDoctrineSharingCommand
    unlock_grand_doctrine = { size=0x38, vft=0x2A32320, isvalid=0x1A7BF90, exec=0x1A7BC10 },  -- 16777 NDoctrines::CUnlockGrandDoctrineCommand
    unlock_sub_doctrine = { size=0x40, vft=0x2A323E8, isvalid=0x1A7C1B0, exec=0x1A7BDD0 },  -- 16779 NDoctrines::CUnlockSubDoctrineCommand
    set_order_group_leader_proximity = { size=0x38, vft=0x2A0AA30, isvalid=0x1162CE0, exec=0x184B780 },  -- 16842 CSetOrderGroupLeaderProximityCommand
    recruit_scientist = { size=0x38, vft=0x2A90348, isvalid=0x1EF4380, exec=0x1EF3E10 },  -- 17327 CRecruitScientistCommand
    restructure_ships_to_taskforce_compositions = { size=0x48, vft=0x29B0D30, isvalid=0x1359140, exec=0x1354720, vec_sentinel=0x3085170 },  -- 17596 CRestructureShipsToTaskforceCompositions
    upgrade_ship_captain = { size=0x30, vft=0x2997A88, isvalid=0x11682A0, exec=0x115FBD0 },  -- 17685 CUpgradeShipCaptainCommand
    set_industrial_org_traits_in_queue = { size=0x50, vft=0x29680C0, isvalid=0x199D820, exec=0x199CE40, vec_sentinel=0x3085170 },  -- 18740 CSetIndustrialOrgTraitsInQueueCommand
    remove_admiral_from_navy_headquarter = { size=0x30, vft=0x2A0D2D0, isvalid=0x184EE60, exec=0x184B110 },  -- 18856 CRemoveAdmiralFromNavyHeadquarter
    assign_admiral_to_navy_headquarter = { size=0x38, vft=0x2A0D208, isvalid=0x184D0A0, exec=0x18430A0 },  -- 18857 CAssignAdmiralToNavyHeadquarter
    launch_operation = { size=0x38, vft=0x29784A0, isvalid=0x1A2A660, exec=0x1A27DC0 },  -- 19010 CLaunchOperationCommand
    set_operation_auto_commence = { size=0x38, vft=0x2978568, isvalid=0x1A2B310, exec=0x1A28450 },  -- 19020 CSetOperationAutoCommenceCommand
    start_stop_decryption = { size=0x38, vft=0x2A2EB38, isvalid=0x1A2BF30, exec=0x1A28BE0 },  -- 19064 CStartStopDecryptionCommand
    activate_active_decryption_bonuses = { size=0x30, vft=0x2A2EC00, isvalid=0x1A28F10, exec=0x1A27290 },  -- 19072 CActivateActiveDecryptionBonuses
    hide_decryption = { size=0x30, vft=0x2A2ECC8, isvalid=0x1A29700, exec=0x1A278D0 },  -- 19078 CHideDecryptionCommand
    become_spy_master = { size=0x30, vft=0x2A2E9A8, isvalid=0x1A29100, exec=0x1A27370 },  -- 19119 CBecomeSpyMasterCommand
    set_main_garrison_template = { size=0x38, vft=0x2995C88, isvalid=0x1166800, exec=0x115C560 },  -- 19120 CSetMainGarrisonTemplateCommand
    set_country_garrison_template = { size=0x38, vft=0x2995D50, isvalid=0x1166730, exec=0x115BD20 },  -- 19121 CSetCountryGarrisonTemplateCommand
    set_state_garrison_template = { size=0x38, vft=0x2995E18, isvalid=0x1167240, exec=0x115DA90 },  -- 19123 CSetStateGarrisonTemplateCommand
    set_country_garrison_priority = { size=0x30, vft=0x272DB88, isvalid=0x1166710, exec=0x115BC80 },  -- 19124 CSetCountryGarrisonPriorityCommand
    intelligence_agency_cancel_creation = { size=0x30, vft=0x2A2E4F8, isvalid=0x1A29830, exec=0x1A279F0 },  -- 19128 CIntelligenceAgencyCancelCreationCommand
    intelligence_agency_cancel_upgrade = { size=0x38, vft=0x2A2E688, isvalid=0x1A29890, exec=0x1A27AA0 },  -- 19129 CIntelligenceAgencyCancelUpgradeCommand
    amend_foreign_manpower_action = { size=0x38, vft=0x2997380, isvalid=0x1162550, exec=0x1152900 },  -- 19138 CAmendForeignManpowerActionCommand
    set_design_team = { size=0x40, vft=0x2967A80, isvalid=0x199D3F0, exec=0x199CA90 },  -- 19163 CSetDesignTeamCommand
    set_industrial_organisation_task = { size=0x48, vft=0x2A23348, isvalid=0x199D8B0, exec=0x199CE80 },  -- 19173 CSetIndustrialOrganisationTaskCommand
    create_raid = { size=0xB0, vft=0x2A41010, isvalid=0x1B33920, exec=0x1B32920, ref_vft=0x2971F30, ref_off=128, vec_sentinel=0x3085170 },  -- 19192 NRaids::NNet::CCreateRaidCommand
    execute_raid = { size=0x30, vft=0x2A411A0, isvalid=0x1B33E70, exec=0x1B32E70 },  -- 19194 NRaids::NNet::CExecuteRaidCommand
    set_raid_auto_complete = { size=0x38, vft=0x2A41330, isvalid=0x1B33780, exec=0x1B331F0 },  -- 19195 NRaids::NNet::CSetRaidAutoComplete
    cancel_raid = { size=0x30, vft=0x2A417E0, isvalid=0x1B33830, exec=0x1B32770 },  -- 19209 NRaids::NNet::CCancelRaidCommand
    recruit_operative = { size=0x38, vft=0x2A2ED90, isvalid=0x1A2A7F0, exec=0x1A27E70 },  -- 19266 CRecruitOperativeCommand
    set_army_fake_template = { size=0x48, vft=0x29B26B8, isvalid=0x136A700, exec=0x1367340, vec_sentinel=0x3085170 },  -- 19334 CSetArmyFakeTemplateCommand
    set_default_country_occupation_policy = { size=0x50, vft=0x2995A30, isvalid=0x1166750, exec=0x115C300 },  -- 19370 CSetDefaultCountryOccupationPolicyCommand
    ignore_all_available_decision = { size=0x30, vft=0x2996E08, isvalid=0xCAA8B0, exec=0x1156FD0 },  -- 19412 CIgnoreAllAvailableDecisionCommand
    set_wing_reinforcement_preference = { size=0x48, vft=0x2A1DE08, isvalid=0x1948750, exec=0x1946430, vec_sentinel=0x3085170 },  -- 19416 CSetWingReinforcementPreferenceCommand
    set_operation_auto_repeat = { size=0x38, vft=0x2978630, isvalid=0x1A2B480, exec=0x1A28490 },  -- 19425 CSetOperationAutoRepeatCommand
    remove_raid = { size=0x38, vft=0x2A41970, isvalid=0x1B33F60, exec=0x1B331B0 },  -- 19438 NRaids::NNet::CRemoveRaidCommand
    set_raid_auto_launch_option = { size=0x38, vft=0x2A414C0, isvalid=0x1B340C0, exec=0x1B333B0 },  -- 19526 NRaids::NNet::CSetRaidAutoLaunchOption
    replace_advisor = { size=0x60, vft=0x2995968, isvalid=0x1165A90, exec=0x1159910 },  -- 19563 CReplaceAdvisorCommand
    add_advisor = { size=0x58, vft=0x2995580, isvalid=0x1161560, exec=0x11508A0 },  -- 19564 CAddAdvisorCommand
    remove_advisor = { size=0x50, vft=0x2995710, isvalid=0x1165630, exec=0x1158A10 },  -- 19567 CRemoveAdvisorCommand
    unlock_research = { size=0x40, vft=0x2995008, isvalid=0x1167FD0, exec=0x115EC70 },  -- 19568 CUnlockResearchCommand
    generate_advisor = { size=0x98, vft=0x29954B8, isvalid=0x1164850, exec=0x1156B10 },  -- 19586 CGenerateAdvisorCommand
    add_advisor_role_to_character = { size=0x98, vft=0x29953F0, isvalid=0x1161610, exec=0x1150C70 },  -- 19603 CAddAdvisorRoleToCharacterCommand
    add_faction_goal = { size=0x48, vft=0x2A4A3B8, isvalid=0x1BAA5F0, exec=0x1BA8FD0 },  -- 19604 NFactions::CAddFactionGoalCommand
    set_faction_rule = { size=0x30, vft=0x2A498C8, isvalid=0x1BAB470, exec=0x1BA9BD0 },  -- 19610 NFactions::CSetFactionRuleCommand
    retire_character = { size=0x30, vft=0x29957D8, isvalid=0x1165EA0, exec=0x115AC90 },  -- 19624 CRetireCharacterCommand
    create_faction_theater = { size=0xB8, vft=0x2A49B20, isvalid=0x1BAB0E0, exec=0x1BA9430, vec_sentinel=0x3085170 },  -- 19641 NFactions::CCreateFactionTheater
    set_supply_truck_buffer_ratio = { size=0x38, vft=0x2995FA8, isvalid=0x1807B0, exec=0x115E3A0 },  -- 19689 CSetSupplyTruckBufferRatioCommand
    set_supply_reinforcement_priority = { size=0x30, vft=0x2995EE0, isvalid=0x1807B0, exec=0x115E1F0 },  -- 19690 CSetSupplyReinforcementPriorityCommand
    change_railway_construction_leve_l = { size=0x38, vft=0x29975D8, isvalid=0x1162CE0, exec=0x1155A40 },  -- 19691 CChangeRailwayConstructionLeveLCommand
    update_supply_node_country_settings = { size=0x38, vft=0x29976A0, isvalid=0x1168080, exec=0x115F340 },  -- 19701 CUpdateSupplyNodeCountrySettingsCommand
    build_railway = { size=0x50, vft=0x2997510, isvalid=0x1162A60, exec=0x1152AF0, vec_sentinel=0x3085170 },  -- 19705 CBuildRailwayCommand
    set_supply_capital_node = { size=0x30, vft=0x2997448, isvalid=0x1167590, exec=0x115E1C0 },  -- 19723 CSetSupplyCapitalNodeCommand
    set_obsolete_division_template = { size=0x38, vft=0x2A48118, isvalid=0x1162CE0, exec=0x1B9F9F0 },  -- 19730 CSetObsoleteDivisionTemplateCommand
    reorder_template_list = { size=0x38, vft=0x2A481E0, isvalid=0x1BA03B0, exec=0x1B9F5F0 },  -- 19731 CReorderTemplateListCommand
    set_auto_upgraded_equipment_variant = { size=0x38, vft=0x2A24890, isvalid=0x1162CE0, exec=0x19A4380 },  -- 19743 CSetAutoUpgradedEquipmentVariantCommand
    set_faction_ping_execution_type = { size=0x38, vft=0x29AC870, isvalid=0x1BAC710, exec=0x1BA9B30 },  -- 19754 NFactions::CSetFactionPingExecutionType
    clear_faction_theater = { size=0x38, vft=0x2A49BE8, isvalid=0x1BAAEB0, exec=0x1BA93A0 },  -- 19760 NFactions::CClearFactionTheater
    modify_faction_theater = { size=0xB0, vft=0x2A49E40, isvalid=0x1BABF70, exec=0x1BA97D0, vec_sentinel=0x3085170 },  -- 19761 NFactions::CModifyFactionTheater
    set_faction_theater_pin_visibility = { size=0x38, vft=0x2A49CB0, isvalid=0x1BAC850, exec=0x1BA9E90 },  -- 19765 NFactions::CSetFactionTheaterPinVisibility
    ai_on_failed_invasion = { size=0x30, vft=0x2A31BF0, isvalid=0x1A74940, exec=0x1A74210 },  -- 19837 CAiOnFailedInvasionCommand
    ai_store_total_wanted_nr_divisions = { size=0x38, vft=0x2A31CB8, isvalid=0x1A74B70, exec=0x1A74660 },  -- 19847 CAiStoreTotalWantedNrDivisionsCommand
    assign_railway_gun_to_orders_group = { size=0x48, vft=0x2972960, isvalid=0xE8F340, exec=0xE8EE90 },  -- 19870 CAssignRailwayGunToOrdersGroup
    unassign_railway_gun_from_orders_group = { size=0x48, vft=0x2972A28, isvalid=0xE8F590, exec=0xE8F1F0 },  -- 19871 CUnassignRailwayGunFromOrdersGroup
    railway_gun_manual_order = { size=0x48, vft=0x2972AF0, isvalid=0xE8F3E0, exec=0xE8EF60 },  -- 19872 CRailwayGunManualOrderCommand
    railway_gun_set_name = { size=0x50, vft=0x2972BB8, isvalid=0xE8F550, exec=0xE8F1A0 },  -- 19873 CRailwayGunSetNameCommand
    set_wing_equipment_niche = { size=0x48, vft=0x2A1DD40, isvalid=0x1948710, exec=0x19463C0, vec_sentinel=0x3085170 },  -- 19882 CSetWingEquipmentNicheCommand
    set_preferred_tactic = { size=0x38, vft=0x2997768, isvalid=0x1166A30, exec=0x115CA80 },  -- 19911 CSetPreferredTacticCommand
    set_scorched_state = { size=0x40, vft=0x29978F8, isvalid=0x1166C90, exec=0x115D520 },  -- 19918 CSetScorchedStateCommand
    update_leader_seen_advisor_roles_count = { size=0x38, vft=0x2A0CEE8, isvalid=0x1165920, exec=0x184BB60 },  -- 19926 CUpdateLeaderSeenAdvisorRolesCountCommand
    set_army_leader_preferred_tactic = { size=0x38, vft=0x2997830, isvalid=0x1166680, exec=0x115B940 },  -- 19927 CSetArmyLeaderPreferredTacticCommand
    add_task_force_template = { size=0xB8, vft=0x29B0AD8, isvalid=0x1357FB0, exec=0x1350450 },  -- 19941 CAddTaskForceTemplateCommand
    remove_task_force_template = { size=0x50, vft=0x29B0BA0, isvalid=0x1358DC0, exec=0x1353770 },  -- 19942 CRemoveTaskForceTemplateCommand
    write_to_chat_buffer = { size=0x70, vft=0x2B49C00, isvalid=0x1165920, exec=0x22E8450 },  -- 290 CChatBuffer::CWriteToChatBuffer
    send_chat_message = { size=0x38, vft=0x2B49B38, isvalid=0x1162CE0, exec=0x22E8360 },  -- 292 CChatBuffer::CSendChatMessage
    start_file_transfer = { size=0x60, vft=0x2B48AB0, isvalid=0x22E1350, exec=0x22E1000 },  -- 305 CStartFileTransfer
    send_chunk = { size=0x50, vft=0x2B48B78, isvalid=0x22E1280, exec=0x22E0E90 },  -- 306 CSendChunk
    chunk_received = { size=0x40, vft=0x2B48C40, isvalid=0x22E1260, exec=0x22E0D00 },  -- 307 CChunkReceived
    chat = { size=0x80, vft=0x29AD250, isvalid=0x1807B0, exec=0x1337140 },  -- 388 CChatCommand
    chat_user_joined = { size=0x80, vft=0x29AD318, isvalid=0x1338570, exec=0x1337610 },  -- 389 CChatUserJoinedCommand
    chat_user_left = { size=0x30, vft=0x29AD3E0, isvalid=0x1338690, exec=0x13376C0 },  -- 390 CChatUserLeftCommand
    chat_user_joined_channel = { size=0x30, vft=0x29AD4A8, isvalid=0x1807B0, exec=0x1337510 },  -- 391 CChatUserJoinedChannelCommand
    chat_user_left_channel = { size=0x30, vft=0x29AD570, isvalid=0x1338620, exec=0x1337690 },  -- 392 CChatUserLeftChannelCommand
    chat_new_channel = { size=0x60, vft=0x29AD638, isvalid=0x1807B0, exec=0x13371C0, vec_sentinel=0x3085170 },  -- 393 CChatNewChannelCommand
    chat_sync_all = { size=0x90, vft=0x29AD750, isvalid=0x1807B0, exec=0x13372A0, vec_sentinel=0x3085170 },  -- 395 CChatSyncAllCommand
    chat_request_sync = { size=0x28, vft=0x29AD818, isvalid=0x1807B0, exec=0x1337240 },  -- 396 CChatRequestSyncCommand
    increase_game_speed = { size=0x28, vft=0x2977040, isvalid=0x1807B0, exec=0xF06EF0 },  -- —(继承基座) CIncreaseGameSpeedCommand
}
local C = rawget(_G, "EXAMPLE_CMD")
if C and C.R then
    for k, v in pairs(T) do C.R[k] = v end
else
    _G.EXAMPLE_CMD_R = T
end
