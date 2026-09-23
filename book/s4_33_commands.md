### 4.33 命令层 CCommand 家族逐类定案

> 定位：CCommand 派生命令的普查与逐类卡册。基座虚表槽表 / 实例布局 /
> post→drain 会话链 = §4.00.7。普查口径 = RTTI 全表 ∩ 共享 writer 槽[2]
> (0x14226A110) 的全部虚表，剔除模板实例化别名 6 行后 **446 类**。

#### 4.33.1 家族普查

| 项 | 值 |
|---|---|
| 家族规模 | 453 vtable（基座 1 + 派生 452）；去模板别名后 446 类 |
| 行为分布 | 五槽自定义 439 / 无载荷 thin 6 / 全继承基座 1 |
| GetTypeId 覆盖 | 445/446 类，445 个唯一值，零碰撞 |
| id 值域 | 290..19942 |

> 基座槽值（二进制约 0x142977040 实读）：[2]=0x14226A110 / [4]=0x142269E60
> （与 §4.00.7 一致）；[9] 默认 = mov al,1（IsValid 缺省真）；[22] 默认 =
> ret（空载荷 writer）；[11] 默认 = 写 10455。

> [2]/[4] 全家族共享的唯一例外 = CIsHighCommand（自行覆写 writer/reader）。

> GetTypeId 指令形态三族：`mov eax,imm32` / `mov dword[rdx],imm32` /
> `mov eax,[rip+disp]`（全局槽间接，35 处，槽值即 id）。


> thin 6 类（IsValid/Clone/载荷走基座，仅 Execute/Clone 变体）：CClearAllControllersCommand、CReopenLobbyCommand、CChatRequestSyncCommand、CStartGameCommand、CQuit、CRequestReadyStatus。
> CIncreaseGameSpeedCommand 全盘继承基座（含 Execute 与 TypeId=10455），
> 视为残影类。

#### 4.33.2 GetTypeId 总表（落盘序 = id 升序；无自有 id 者列尾）

| id | 类 | 行为形态 | vtable |
|---:|---|---|---|
| 290 | CChatBuffer::CWriteToChatBuffer | 五槽自定义 | 0x142b49c00 |
| 292 | CChatBuffer::CSendChatMessage | 五槽自定义 | 0x142b49b38 |
| 305 | CStartFileTransfer | 五槽自定义 | 0x142b48ab0 |
| 306 | CSendChunk | 五槽自定义 | 0x142b48b78 |
| 307 | CChunkReceived | 五槽自定义 | 0x142b48c40 |
| 388 | CChatCommand | 五槽自定义 | 0x1429ad250 |
| 389 | CChatUserJoinedCommand | 五槽自定义 | 0x1429ad318 |
| 390 | CChatUserLeftCommand | 五槽自定义 | 0x1429ad3e0 |
| 391 | CChatUserJoinedChannelCommand | 五槽自定义 | 0x1429ad4a8 |
| 392 | CChatUserLeftChannelCommand | 五槽自定义 | 0x1429ad570 |
| 393 | CChatNewChannelCommand | 五槽自定义 | 0x1429ad638 |
| 395 | CChatSyncAllCommand | 五槽自定义 | 0x1429ad750 |
| 396 | CChatRequestSyncCommand | [10][13] 自定义·无载荷 | 0x1429ad818 |
| 10047 | COnRulingPartyChangeActionCommand | 五槽自定义 | 0x14272dea8 |
| 10050 | CPrototypeRewardOptionCommand | 五槽自定义 | 0x142a90730 |
| 10080 | CDismantleFacilityCommand | 五槽自定义 | 0x142a907f8 |
| 10085 | CAbortDismantleFacilityCommand | 五槽自定义 | 0x142a908c0 |
| 10104 | CSetMaxAllowedRepairFactoriesCommand | 五槽自定义 | 0x1429b0240 |
| 10105 | NInternationalMarket::CSetMarketRequestAutomationOptionsCommand | 五槽自定义 | 0x142a3f8f0 |
| 10144 | CResetUnreadPrototypeRewardsCounterCommand | 五槽自定义 | 0x142a90988 |
| 10191 | NInternationalMarket::CMarketStockpileClearCommand | 五槽自定义 | 0x142ab6d08 |
| 10227 | CSetCarrierDefensiveStance | 五槽自定义 | 0x1429b0c68 |
| 10228 | CExecuteButtonCommand | 五槽自定义 | 0x142a4bf10 |
| 10248 | NFactions::CRemoveFactionProgramCommand | 五槽自定义 | 0x142a49fd0 |
| 10250 | CSelectBookmarkCommand | 五槽自定义 | 0x1429e6198 |
| 10258 | CSetDifficulty | 五槽自定义 | 0x1429e6260 |
| 10261 | CNavalMissionSetTargetCommand | 五槽自定义 | 0x1429b0ec0 |
| 10283 | CDeployArmyHqCommand | 五槽自定义 | 0x1429b2398 |
| 10285 | CSelectionGroupCommand | 五槽自定义 | 0x142996f98 |
| 10291 | CWithdrawArmyHqCommand | 五槽自定义 | 0x1429b2460 |
| 10297 | CAddTaskCapacityCommand | 五槽自定义 | 0x142967b48 |
| 10307 | CSetPendingReassignTargetCommand | 五槽自定义 | 0x1429b2528 |
| 10402 | CMoveCommand | 五槽自定义 | 0x1429b1bc8 |
| 10415 | CCancelMovementCommand | 五槽自定义 | 0x1429b1e20 |
| 10417 | CAutomateHomebaseForFleetCommand | 五槽自定义 | 0x1429b0df8 |
| 10438 | CAddSizeCommand | 五槽自定义 | 0x142967c10 |
| 10446 | NFactions::CSetFactionUpgradeCommand | 五槽自定义 | 0x142a49a58 |
| 10449 | NFactions::CUseFactionMemberManpower | 五槽自定义 | 0x1429ac938 |
| 10456 | CDecreaseGameSpeedCommand | 五槽自定义 | 0x142977108 |
| 10494 | NFactions::CEraseFactionRuleCommand | 五槽自定义 | 0x142a49990 |
| 10500 | NFactions::CUpdateIntelligenceAdvisorSlotCommand | 五槽自定义 | 0x142a4a480 |
| 10509 | NFactions::CFactionSetCommanderCommand | 五槽自定义 | 0x142a4a228 |
| 10513 | NFactions::CFactionAttachScientistCommand | 五槽自定义 | 0x142a4a098 |
| 10514 | NFactions::CFactionUnattachScientistCommand | 五槽自定义 | 0x142a4a160 |
| 10545 | CDiplomaticActionCommand | 五槽自定义 | 0x14298b708 |
| 10563 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand | 五槽自定义 | 0x142a4a548 |
| 10625 | CSetAutoUpdateDesignsForIndustrialOrgCommand | 五槽自定义 | 0x142968188 |
| 10645 | CSelectEventOptionCommand | 五槽自定义 | 0x142938e60 |
| 10707 | CSetCountryControllerCommand | 五槽自定义 | 0x14295e368 |
| 10708 | CClearAllControllersCommand | [10][13] 自定义·无载荷 | 0x14295e5c0 |
| 10714 | CQuit | [10][13] 自定义·无载荷 | 0x1429e60d0 |
| 10723 | CAddPlayerCommand | 五槽自定义 | 0x142a22d40 |
| 10731 | CSetRandomSeed | 五槽自定义 | 0x14296a240 |
| 10732 | CPauseGame | 五槽自定义 | 0x14296a560 |
| 10808 | CAutosave | 五槽自定义 | 0x14296a880 |
| 10890 | CSetAchievementsOK | 五槽自定义 | 0x1429e64b8 |
| 11061 | CUpgradeDivisionOfficerCommand | 五槽自定义 | 0x1429979c0 |
| 11100 | CSetGamePlayOptions | 五槽自定义 | 0x1429e6710 |
| 11169 | CAiStoreForceConcentrationTargetCommand | 五槽自定义 | 0x142a31d80 |
| 11170 | CAiDiscardForceConcentrationTargetCommand | 五槽自定义 | 0x142a31e48 |
| 11376 | CClientPingCommand | 五槽自定义 | 0x1427217e0 |
| 11438 | CRequestGameStateSynchCommand | 五槽自定义 | 0x14296a178 |
| 11467 | CReopenLobbyCommand | [10][13] 自定义·无载荷 | 0x14296a7b8 |
| 11469 | CReadyAfterHotJoinCommand | 五槽自定义 | 0x14296a6f0 |
| 11504 | CPostHotJoinCommand | 五槽自定义 | 0x14296a628 |
| 11517 | CSetReadyStatus | 五槽自定义 | 0x1429e6580 |
| 11529 | CCheckSyncResponseCommand | 五槽自定义 | 0x14296aa10 |
| 11530 | CCheckSyncCommand | 五槽自定义 | 0x14296a948 |
| 11545 | CSetDLCsCommand | 五槽自定义 | 0x142a22f98 |
| 11579 | CSetPlayerAiPrefsCommand | 五槽自定义 | 0x142993640 |
| 11801 | CSetUseDynamicVersionPositioningVariantCommand | 五槽自定义 | 0x142a24958 |
| 11983 | COrderGroupCommand | 五槽自定义 | 0x142a0aaf8 |
| 12045 | CSetTheatreCommand | 五槽自定义 | 0x1429b2078 |
| 12057 | CSetOrderGroupOrdersInstanceNamesCommand | 五槽自定义 | 0x142a0a648 |
| 12092 | CHourlyTickCommand | 五槽自定义 | 0x142976f78 |
| 12098 | CSetGameSpeedCommand | 五槽自定义 | 0x1429771d0 |
| 12118 | CCreateOperationCommand | 五槽自定义 | 0x142978310 |
| 12142 | CSetProductionLineCommand | 五槽自定义 | 0x142993af0 |
| 12144 | CSetResearchCommand | 五槽自定义 | 0x142994f40 |
| 12147 | CChangeProductionLinePriorityCommand | 五槽自定义 | 0x142994c20 |
| 12149 | CAddProductionLineFactoriesCommand | 五槽自定义 | 0x142994db0 |
| 12151 | CAddConstructionCommand | 五槽自定义 | 0x142994770 |
| 12189 | CSetOrderGroupCohesionTypeCommand | 五槽自定义 | 0x142a0a968 |
| 12197 | CCreateDivisionTemplateCommand | 五槽自定义 | 0x1429abd00 |
| 12198 | CUpdateDivisionTemplateCommand | 五槽自定义 | 0x1429abc38 |
| 12221 | CStratAirSetMissionCommand | 五槽自定义 | 0x142a1d638 |
| 12222 | CStratAirEnableMissionCommand | 五槽自定义 | 0x142a1d570 |
| 12230 | CStratAirTransferCommand | 五槽自定义 | 0x142a1d700 |
| 12231 | CStratAirSplitCommand | 五槽自定义 | 0x142a1d890 |
| 12234 | CStratAirConsolidateCommand | 五槽自定义 | 0x142a1d958 |
| 12235 | CStratAirCancelTransferCommand | 五槽自定义 | 0x142a1d7c8 |
| 12242 | CCreateFactionCommand | 五槽自定义 | 0x142995260 |
| 12246 | CStratAirDayNightCommand | 五槽自定义 | 0x142a1dbb0 |
| 12257 | CSetProductionLineAmountToProduceCommand | 五槽自定义 | 0x142994e78 |
| 12272 | CNavalMissionSetTypeCommand | 五槽自定义 | 0x1429af430 |
| 12273 | CNavalMissionSetRegionsCommand | 五槽自定义 | 0x1429af4f8 |
| 12274 | CNavalMissionAddRegionCommand | 五槽自定义 | 0x1429af5c0 |
| 12275 | CNavalMissionRemoveRegionCommand | 五槽自定义 | 0x1429af688 |
| 12284 | CNavalMissionMoveCommand | 五槽自定义 | 0x1429af750 |
| 12303 | CAddIdeaCommand | 五槽自定义 | 0x142995328 |
| 12304 | CRemoveIdeaCommand | 五槽自定义 | 0x142995648 |
| 12345 | COrderSetPathCommand | 五槽自定义 | 0x142a0b520 |
| 12350 | COrderAssignCommand | 五槽自定义 | 0x142a0b200 |
| 12351 | COrderDeleteCommand | 五槽自定义 | 0x142a0b138 |
| 12352 | COrderExecuteCommand | 五槽自定义 | 0x142a0c330 |
| 12365 | COrderUnassignCommand | 五槽自定义 | 0x142a0b2c8 |
| 12366 | CDeleteOrderGroupCommand | 五槽自定义 | 0x142a0abc0 |
| 12369 | CSetArmyLeaderCommand | 五槽自定义 | 0x142a0c3f8 |
| 12370 | CSetFleetLeaderCommand | 五槽自定义 | 0x142a0c4c0 |
| 12387 | CCreateTradeCommand | 五槽自定义 | 0x142a49150 |
| 12395 | CCreateEquipmentVariantCommand | 五槽自定义 | 0x142a240c0 |
| 12398 | CRenameEquipmentVariantCommand | 五槽自定义 | 0x142a24570 |
| 12448 | CDeleteUnitCommand | 五槽自定义 | 0x1429b2140 |
| 12521 | CEndTurnPeaceConferenceCommand | 五槽自定义 | 0x142a845d0 |
| 12566 | CPassPeaceConferenceCommand | 五槽自定义 | 0x142a84440 |
| 12568 | CSetOccupationPolicyCommand | 五槽自定义 | 0x142995af8 |
| 12612 | CSetCountryReinforcementPriorityCommand | 五槽自定义 | 0x14272dac0 |
| 12615 | CSetWingReinforcementPriorityCommand | 五槽自定义 | 0x142a1ded0 |
| 12620 | CSupportAttackCommand | 五槽自定义 | 0x1429b1fb0 |
| 12643 | COrderSetInvasionSourceCommand | 五槽自定义 | 0x142a0c588 |
| 12660 | CRemoveNavalInvasionTargetCommand | 五槽自定义 | 0x142a0c650 |
| 12661 | CAddNavalInvasionTargetCommand | 五槽自定义 | 0x142a0c718 |
| 12664 | CNavalMoveCommand | 五槽自定义 | 0x1429af8e0 |
| 12679 | CConvertFactoryCommand | 五槽自定义 | 0x142994b58 |
| 12711 | NFactions::CAddFactionProgramCommand | 五槽自定义 | 0x142a49f08 |
| 12729 | COrderSetParadropSourceCommand | 五槽自定义 | 0x142a0ca38 |
| 12730 | COrderSetParadropTargetCommand | 五槽自定义 | 0x142a0cb00 |
| 12732 | NFactions::CSetFactionIconAndColor | 五槽自定义 | 0x142a4a2f0 |
| 12778 | CAssignAceCommand | 五槽自定义 | 0x142996138 |
| 13017 | CReplaceIdeaCommand | 五槽自定义 | 0x1429958a0 |
| 13028 | CSetXORResearchCommand | 五槽自定义 | 0x1429950d0 |
| 13088 | CRemoveConstructionCommand | 五槽自定义 | 0x142994838 |
| 13089 | CRemoveAllConstructionCommand | 五槽自定义 | 0x142994900 |
| 13090 | CRequestReadyStatus | [10][13] 自定义·无载荷 | 0x1429e6648 |
| 13091 | CDeployAirWingCommand | 五槽自定义 | 0x142995198 |
| 13092 | CMoveShipsCommand | 五槽自定义 | 0x1429b2780 |
| 13095 | COrderNewFrontCommand | 五槽自定义 | 0x142a0b908 |
| 13096 | COrderNewRootCommand | 五槽自定义 | 0x142a0bc28 |
| 13097 | COrderEditRootCommand | 五槽自定义 | 0x142a0bf48 |
| 13098 | COrderMergeRootsCommand | 五槽自定义 | 0x142a0c1a0 |
| 13099 | COrderMembersFairSplitCommand | 五槽自定义 | 0x142a0c268 |
| 13100 | CClientOutOfSyncCommand | 五槽自定义 | 0x14296a3d0 |
| 13101 | CAddProductionLineCommand | 五槽自定义 | 0x142993708 |
| 13103 | CReleaseCountryCommand | 五槽自定义 | 0x142996200 |
| 13104 | CPromoteToCountryLeaderCommand | 五槽自定义 | 0x14295e4f8 |
| 13105 | CRemoveShipRefitProductionLineCommand | 五槽自定义 | 0x142993c80 |
| 13106 | CSetNavalDeploymentTargetCommand | 五槽自定义 | 0x1429941f8 |
| 13107 | CCreateUnitLeaderCommand | 五槽自定义 | 0x1429962c8 |
| 13150 | CDeleteShipCommand | 五槽自定义 | 0x1429b2910 |
| 13174 | CChangeCountryControllerCommand | 五槽自定义 | 0x142996390 |
| 13176 | CMergeNaviesCommand | 五槽自定义 | 0x1429b2b68 |
| 13208 | COrderInsertFrontCommand | 五槽自定义 | 0x142a0b840 |
| 13214 | COrderReshapeCommand | 五槽自定义 | 0x142a0b5e8 |
| 13215 | COrderSetTrainingCommand | 五槽自定义 | 0x142a0cbc8 |
| 13225 | CSetObsoleteEquipmentVariantCommand | 五槽自定义 | 0x142a24700 |
| 13226 | CSetCountryUpgradePriorityCommand | 五槽自定义 | 0x14272dde0 |
| 13232 | COrderReconnectCommand | 五槽自定义 | 0x142a0b6b0 |
| 13233 | COrderConnectCommand | 五槽自定义 | 0x142a0b778 |
| 13235 | CSetUnitNameCommand | 五槽自定义 | 0x1429b2208 |
| 13245 | CSetNationalFocusCommand | 五槽自定义 | 0x142996458 |
| 13268 | CSetShipNameCommand | 五槽自定义 | 0x1429b2848 |
| 13270 | CSetArmyTemplateCommand | 五槽自定义 | 0x1429b25f0 |
| 13271 | COrderNewFallbackCommand | 五槽自定义 | 0x142a0ba98 |
| 13297 | COrderDeleteAllCommand | 五槽自定义 | 0x142a0b070 |
| 13306 | CPromoteUnitLeaderCommand | 五槽自定义 | 0x1429b2c30 |
| 13343 | CMassMoveCommand | 五槽自定义 | 0x1429b1c90 |
| 13352 | CAddMassProductionsLineCommand | 五槽自定义 | 0x1429937d0 |
| 13353 | CNavalMissionMassMoveCommand | 五槽自定义 | 0x1429af818 |
| 13357 | CSetNavyEngagementCommand | 五槽自定义 | 0x1429b29d8 |
| 13465 | CSetCoopHotJoinOptions | 五槽自定义 | 0x1429e67d8 |
| 13470 | CSetMPDebugSettings | 五槽自定义 | 0x1429e68a0 |
| 13479 | CCreateConveyorCommand | 五槽自定义 | 0x142a483c0 |
| 13480 | CSetConveyorNameCommand | 五槽自定义 | 0x142a48550 |
| 13481 | CSetConveyorLocationCommand | 五槽自定义 | 0x142a48618 |
| 13482 | CSetConveyorPriorityCommand | 五槽自定义 | 0x142a48870 |
| 13483 | CSetConveyorSeriesCommand | 五槽自定义 | 0x142a48938 |
| 13484 | CAddConveyorLineCommand | 五槽自定义 | 0x142a48a00 |
| 13485 | CDeployConveyorLineCommand | 五槽自定义 | 0x142a48de8 |
| 13487 | CRemoveConveyorLineCommand | 五槽自定义 | 0x142a48f78 |
| 13493 | CCreateConveyorExtendedCommand | 五槽自定义 | 0x142a48488 |
| 13498 | CSetConveyorGroupCommand | 五槽自定义 | 0x142a486e0 |
| 13533 | CTransportUnitCommand | 五槽自定义 | 0x1429b2cf8 |
| 13550 | CSetDivisionTemplateSymbolCommand | 五槽自定义 | 0x1429abb70 |
| 13563 | CSetOrderGroupNameCommand | 五槽自定义 | 0x142a0a580 |
| 13565 | CDispatchNavalCombatResultsCommand | 五槽自定义 | 0x142993578 |
| 13571 | CSetOrderGroupMotorizationCommand | 五槽自定义 | 0x142a0a710 |
| 13574 | CRemoveDivisionTemplateCommand | 五槽自定义 | 0x1429abdc8 |
| 13578 | COrderReplaceRootCommands | 五槽自定义 | 0x142a0bdb8 |
| 13579 | COrderRemoveRootCommands | 五槽自定义 | 0x142a0be80 |
| 13580 | COrderReplaceFallbackCommands | 五槽自定义 | 0x142a0bb60 |
| 13581 | CNavyRepairModeCommand | 五槽自定义 | 0x1429aef80 |
| 13583 | CNavyRepairNowCommand | 五槽自定义 | 0x1429aeeb8 |
| 13590 | CNavyCancelRepairCommand | 五槽自定义 | 0x1429aedf0 |
| 13599 | CNavyDetachShipsAndRepairCommand | 五槽自定义 | 0x1429aed28 |
| 13600 | CDeployConveyorCommand | 五槽自定义 | 0x142a48ac8 |
| 13601 | CRemoveConveyorCommand | 五槽自定义 | 0x142a48d20 |
| 13604 | CRemoveBuildingLevelCommand | 五槽自定义 | 0x1429949c8 |
| 13614 | CSetTimedActivityDistributionPriorityCommand | 五槽自定义 | 0x142996840 |
| 13636 | CAddMassFactoryAssignmentCommand | 五槽自定义 | 0x142993a28 |
| 13637 | CStratAirChangeAggressivnessCommand | 五槽自定义 | 0x142a1dc78 |
| 13638 | CMassRemoveProductionsLineCommand | 五槽自定义 | 0x142993898 |
| 13642 | CStratAirMoveEquipmentCommand | 五槽自定义 | 0x142a1da20 |
| 13646 | CStratAirMoveEquipmentToReservesCommand | 五槽自定义 | 0x142a1dae8 |
| 13650 | CAutoMergeOrdersCommand | 五槽自定义 | 0x142a0b9d0 |
| 13651 | CDeleteAirWingCommand | 五槽自定义 | 0x142a1df98 |
| 13682 | CAskToCoopWithCountryCommand | 五槽自定义 | 0x14295e430 |
| 13694 | CSetNavalProductionLineAirWingCompositionCommand | 五槽自定义 | 0x142994130 |
| 13713 | CSetCarrierStickyMissionAreaCommand | 五槽自定义 | 0x142a1e060 |
| 13725 | CTogglePinnedStrategicRegionCommand | 五槽自定义 | 0x142a87ba0 |
| 13726 | CStartGameCommand | [10][13] 自定义·无载荷 | 0x1429e6008 |
| 13728 | CSetPinnedStrategicRegionCommand | 五槽自定义 | 0x142a87d30 |
| 13753 | CStrategicRedeploymentCommand | 五槽自定义 | 0x1429b2dc0 |
| 13789 | CAssignToTheaterGroupCommand | 五槽自定义 | 0x142a326d0 |
| 13790 | CDisbandTheaterGroupCommand | 五槽自定义 | 0x142a32860 |
| 13791 | CSetTheaterGroupNameCommand | 五槽自定义 | 0x142a32928 |
| 13792 | CSetTheaterGroupPriorityCommand | 五槽自定义 | 0x142a329f0 |
| 13830 | CDonePeaceConferenceCommand | 五槽自定义 | 0x142a84508 |
| 13859 | NInternationalMarket::CMarketStockpileEquipmentTransferCommand | 五槽自定义 | 0x142a3f9c0 |
| 13872 | CMassCancelMovementCommand | 五槽自定义 | 0x142993960 |
| 13873 | CEditAreaDefenseStateCommand | 五槽自定义 | 0x142a0c7e0 |
| 13894 | CQueueUnitActionCommand | 五槽自定义 | 0x1429b2e88 |
| 13901 | CRemovePlayerCommand | 五槽自定义 | 0x142a22ed0 |
| 13908 | CSetCountryControllerTypeCommand | 五槽自定义 | 0x14295e688 |
| 13918 | COrderAddNewCompletePlanCommand | 五槽自定义 | 0x142a0bcf0 |
| 13924 | CSetOrderGroupIconAndColorCommand | 五槽自定义 | 0x142a0a7d8 |
| 13979 | CRemoveAllProductionLineCommand | 五槽自定义 | 0x142993d48 |
| 13992 | CSetOrderGroupExecutionTypeCommand | 五槽自定义 | 0x142a0a8a0 |
| 13995 | CAddHumanCommand | 五槽自定义 | 0x142a22e08 |
| 13997 | CRequestGameStateTransferCommand | 五槽自定义 | 0x14296a0b0 |
| 14003 | CCollapseConveyorCommand | 五槽自定义 | 0x142a48b90 |
| 14004 | CChangeConveyorPositionCommand | 五槽自定义 | 0x142a48c58 |
| 14005 | CReplaceBuildingCommand | 五槽自定义 | 0x142994a90 |
| 14008 | CSetCustomDifficultyMultiplier | 五槽自定义 | 0x1429e6328 |
| 14010 | NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand | 五槽自定义 | 0x142a3f820 |
| 14022 | CChangeConveyorTemplateCommand | 五槽自定义 | 0x142a487a8 |
| 14038 | CSetEquipmentVariantHighlightCommand | 五槽自定义 | 0x142a24638 |
| 14048 | CSetContinuousFocusCommand | 五槽自定义 | 0x1429966b0 |
| 14050 | CDropContinuousFocusCommand | 五槽自定义 | 0x142996778 |
| 14061 | CPromoteAutonomyCommand | 五槽自定义 | 0x1429ab3f8 |
| 14062 | CRemoveAutonomyCommand | 五槽自定义 | 0x1429ab4c0 |
| 14063 | CSetAreaDefenseSettingCommand | 五槽自定义 | 0x142a0c970 |
| 14069 | COrderBlockSectionsCommand | 五槽自定义 | 0x142a0b458 |
| 14250 | CBypassNationalFocusCommand | 五槽自定义 | 0x1429965e8 |
| 14257 | CDropCurrentNationalFocusCommand | 五槽自定义 | 0x142996520 |
| 14301 | CSetProductionLineConvertCommand | 五槽自定义 | 0x142993e10 |
| 14312 | CSetAirWingNameCommand | 五槽自定义 | 0x142a1e128 |
| 14344 | CMergeArmiesCommand | 五槽自定义 | 0x1429b2f50 |
| 14345 | CSelectDecisionCommand | 五槽自定义 | 0x142996908 |
| 14350 | CSendPingCommand | 五槽自定义 | 0x14296a498 |
| 14372 | CSetProductionLinePriorityCommand | 五槽自定义 | 0x142994ce8 |
| 14383 | CSelectTargetedDecisionCommand | 五槽自定义 | 0x1429969d0 |
| 14424 | CStockpiledEquipmentDeleteCommand | 五槽自定义 | 0x142a247c8 |
| 14433 | CArmyGroupCommand | 五槽自定义 | 0x142a0ac88 |
| 14463 | CSetArmyToConsolidateForUnit | 五槽自定义 | 0x1429b1d58 |
| 14470 | CAssignToArmyGroupCommand | 五槽自定义 | 0x142a0ad50 |
| 14471 | CRemoveFromArmyGroupCommand | 五槽自定义 | 0x142a0ae18 |
| 14495 | CUnlockIndustrialOrganisationTrait | 五槽自定义 | 0x142967cd8 |
| 14496 | CSetIndustrialManufacturerCommand | 五槽自定义 | 0x142a23280 |
| 14513 | CTriggerAbilityCommand | 五槽自定义 | 0x142996b60 |
| 14525 | CLearnTraitCommand | 五槽自定义 | 0x142a0cd58 |
| 14601 | CSetDivisionNameCommand | 五槽自定义 | 0x1429b22d0 |
| 14612 | CSetDeploymentLineNameCommand | 五槽自定义 | 0x142a48eb0 |
| 14636 | CAttachAirWingToArmyCommand | 五槽自定义 | 0x142a1e1f0 |
| 14637 | CDetachAirWingFromArmyCommand | 五槽自定义 | 0x142a1e2b8 |
| 14678 | CProductionLineInterfaceToggleExpandCommand | 五槽自定义 | 0x142993fa0 |
| 14699 | CProductionLineInterfaceToggleExpandAllCommand | 五槽自定义 | 0x142994068 |
| 14706 | CToggleBombingPriorityCommand | 五槽自定义 | 0x142a1e380 |
| 14730 | CProductionLineInterfaceFactoriesScaleCommand | 五槽自定义 | 0x142993ed8 |
| 14768 | CIgnoreDecisionCommand | 五槽自定义 | 0x142996c28 |
| 14769 | CIgnoreTargetedDecisionCommand | 五槽自定义 | 0x142996d40 |
| 14785 | CMoreGroundCrewsCommand | 五槽自定义 | 0x142a1e448 |
| 14857 | CSetOrdersLinkCommand | 五槽自定义 | 0x142a0cfb0 |
| 14858 | CSetNavalRegionAccessCommand | 五槽自定义 | 0x1429afa70 |
| 14859 | CSetCountryOperationsPriorityCommand | 五槽自定义 | 0x14272dc50 |
| 14860 | CSetOperationTargetCommand | 五槽自定义 | 0x1429786f8 |
| 14861 | CReserveOperativeForOperationCommand | 五槽自定义 | 0x142978248 |
| 14862 | CDeleteOperationCommand | 五槽自定义 | 0x1429783d8 |
| 14863 | CMoveAirWingAndAirGroupToAirTheatreCommand | 五槽自定义 | 0x142a1e510 |
| 14864 | CMoveAirGroupAndAirTheatreToFreeCommand | 五槽自定义 | 0x142a1e5d8 |
| 14865 | CMoveAirWingToAirGroupCommand | 五槽自定义 | 0x142a1e6a0 |
| 14866 | CRenameAirTheatreCommand | 五槽自定义 | 0x142a1e830 |
| 14867 | CRenameAirGroupCommand | 五槽自定义 | 0x142a1e8f8 |
| 14868 | CChangeAirGroupInsigniaCommand | 五槽自定义 | 0x142a1e9c0 |
| 14869 | CReorderAirTheatersCommand | 五槽自定义 | 0x142a1e768 |
| 14876 | CSetQuickDeployPreferenceCommand | 五槽自定义 | 0x142a1ea88 |
| 14895 | COrderSetCollapseCommand | 五槽自定义 | 0x142a0cc90 |
| 14901 | CAssignArmyToArmyGroupFront | 五槽自定义 | 0x142a0d078 |
| 14918 | CUpdateLeaderSeenTraitsCountCommand | 五槽自定义 | 0x142a0ce20 |
| 14954 | CCreateAreaDefenseCommand | 五槽自定义 | 0x142a0c8a8 |
| 14966 | CExecuteScriptedWindowEffect | 五槽自定义 | 0x142996ed0 |
| 14987 | CSetSelectedArmyGroupFallback | 五槽自定义 | 0x142a0d140 |
| 14990 | CMoveArmiesInTheaterCommand | 五槽自定义 | 0x142a0aee0 |
| 14991 | CMoveArmyGroupInTheaterCommand | 五槽自定义 | 0x142a0afa8 |
| 14993 | CReorderTheatersCommand | 五槽自定义 | 0x142a32798 |
| 14994 | CReorderPinnedStrategicRegionCommand | 五槽自定义 | 0x142a87c68 |
| 15001 | CSetPrideOfTheFleetCommand | 五槽自定义 | 0x1429af9a8 |
| 15158 | CCreateFleetCommand | 五槽自定义 | 0x1429afb38 |
| 15160 | CReorderNavyTheaterGroupCommand | 五槽自定义 | 0x142a32ab8 |
| 15161 | CSetNavyTheaterGroupForCommand | 五槽自定义 | 0x142a32b80 |
| 15163 | CSetFleetNameCommand | 五槽自定义 | 0x1429afc00 |
| 15164 | CSetNavyTheaterGroupNameCommand | 五槽自定义 | 0x142a32c48 |
| 15165 | CSetFleetCommand | 五槽自定义 | 0x1429afcc8 |
| 15170 | CSetTaskForceAutoReinforcementCommand | 五槽自定义 | 0x1429afe58 |
| 15171 | CSetTaskForceCompositionRequirementsCommand | 五槽自定义 | 0x1429aff20 |
| 15172 | CSetAsReserveFleetCommand | 五槽自定义 | 0x1429b00b0 |
| 15174 | CReorganizeShipsCommand | 五槽自定义 | 0x1429b06f0 |
| 15177 | CSetTaskForceIconAndColorCommand | 五槽自定义 | 0x1429b0948 |
| 15178 | CSetFleetIconAndColorCommand | 五槽自定义 | 0x1429b0880 |
| 15179 | CNavyDetachShipsAndMergeCommand | 五槽自定义 | 0x1429af110 |
| 15181 | CNavyCancelActivityCommand | 五槽自定义 | 0x1429af368 |
| 15203 | CSetGameRuleOption | 五槽自定义 | 0x1429e63f0 |
| 15205 | CResetGameRules | 五槽自定义 | 0x142a99b60 |
| 15206 | CResetCustomDifficultyMultipliers | 五槽自定义 | 0x142a99a98 |
| 15229 | CNavyCancelRefitCommand | 五槽自定义 | 0x1429af2a0 |
| 15230 | CNavyDetachShipsAndRefitCommand | 五槽自定义 | 0x1429af1d8 |
| 15233 | CSetShipRefitDeploymentTargetCommand | 五槽自定义 | 0x1429942c0 |
| 15235 | CRemoveProductionLineCommand | 五槽自定义 | 0x142993bb8 |
| 15237 | CSetGameUniqueId | 五槽自定义 | 0x14296a308 |
| 15284 | CCancelRunningAwayCommand | 五槽自定义 | 0x1429b2aa0 |
| 15301 | CNavyClearAccidentReportsCommand | 五槽自定义 | 0x1429affe8 |
| 15317 | CReinstateExileCommand | 五槽自定义 | 0x142997060 |
| 15318 | CChangeProductionLineNamePriorityCommand | 五槽自定义 | 0x142994388 |
| 15319 | CRemoveProductionLineName | 五槽自定义 | 0x1429946a8 |
| 15320 | CAddProductionLineName | 五槽自定义 | 0x142994450 |
| 15324 | CSetStateOverrideOccupationPolicyCommand | 五槽自定义 | 0x142995bc0 |
| 15337 | CSetMaxAllowedRepairDockyards | 五槽自定义 | 0x1429b0178 |
| 15339 | CReorderNavalRepairQueue | 五槽自定义 | 0x1429b0308 |
| 15340 | CSwitchNavalRepairDockyard | 五槽自定义 | 0x1429b0498 |
| 15341 | CRequestExpeditionariesCommand | 五槽自定义 | 0x142996a98 |
| 15342 | CAddToOrRemoveShipFromNavalRepairQueue | 五槽自定义 | 0x1429b03d0 |
| 15344 | CChangeNavalBaseRepairPriorityCommand | 五槽自定义 | 0x1429b0560 |
| 15345 | CDisengageFromNavalCombatCommand | 五槽自定义 | 0x1429b07b8 |
| 15435 | CSetNavalBaseDisabledForRepairsStateCommand | 五槽自定义 | 0x1429b0628 |
| 15473 | ShowScriptedDiplomaticActionSendPopupCommand | 五槽自定义 | 0x142997128 |
| 15496 | CSetEquipmentVariantOverrideModelCommand | 五槽自定义 | 0x142a24250 |
| 15497 | CSetEquipmentVariantNameListCommand | 五槽自定义 | 0x142a244a8 |
| 15498 | CAddProductionLineOrderedName | 五槽自定义 | 0x142994518 |
| 15499 | CAddProductionLineUnorderedName | 五槽自定义 | 0x1429945e0 |
| 15505 | CSetEquipmentVariantOverrideSpriteCommand | 五槽自定义 | 0x142a24318 |
| 15524 | CUpdateEquipmentVariantCommand | 五槽自定义 | 0x142a24188 |
| 15525 | CSetEquipmentVariantNicheIconCommand | 五槽自定义 | 0x142a243e0 |
| 15537 | CSetIntelligenceAgencyRandomHistoricalNameCommand | 五槽自定义 | 0x142a2e818 |
| 15573 | CSetFuelPriorityCommand | 五槽自定义 | 0x142996070 |
| 15576 | CSetNavyTheaterGroupImportantCommand | 五槽自定义 | 0x142a32d10 |
| 15584 | CToggleStrategicDeploymentCommand | 五槽自定义 | 0x1429b1ee8 |
| 15625 | CMarkSunkShipInfoAsReadCommand | 五槽自定义 | 0x1429b0a10 |
| 15628 | CIncomingDiplomaticActionActingCommand | 五槽自定义 | 0x1429971f0 |
| 15629 | CAmendIncomingLendLeaseActionCommand | 五槽自定义 | 0x1429972b8 |
| 15637 | CDismissOperativeCommand | 五槽自定义 | 0x142a2e2a0 |
| 15640 | CSetOperativeCodenameCommand | 五槽自定义 | 0x142a2e368 |
| 15657 | CSetOperativeMissionCommand | 五槽自定义 | 0x142a2ea70 |
| 15670 | CIntelligenceAgencyCreationCommand | 五槽自定义 | 0x142a2e430 |
| 15671 | CSetIntelligenceAgencyLogoCommand | 五槽自定义 | 0x142a2e8e0 |
| 15672 | CSetIntelligenceAgencyNameCommand | 五槽自定义 | 0x142a2e750 |
| 15679 | CIntelligenceAgencyUpgradeCommand | 五槽自定义 | 0x142a2e5c0 |
| 15758 | COrderChildFrontRatioCommand | 五槽自定义 | 0x142a0c010 |
| 15782 | COrderDeleteChildFront | 五槽自定义 | 0x142a0b390 |
| 15785 | COrderReorderChildFrontCommand | 五槽自定义 | 0x142a0c0d8 |
| 15871 | CGiveMedalCommand | 五槽自定义 | 0x142997b50 |
| 16118 | CUpdateProfileBadgeCommand | 五槽自定义 | 0x142a22c48 |
| 16260 | CAttachPolicyToIndustrialOrgCommand | 五槽自定义 | 0x142967da0 |
| 16390 | CMoveIndustrialOrgTraitInQueueCommand | 五槽自定义 | 0x142967ff8 |
| 16398 | CAttachScientistCommand | 五槽自定义 | 0x142a90410 |
| 16399 | CUnattachScientistCommand | 五槽自定义 | 0x142a904d8 |
| 16402 | CStartProjectCommand | 五槽自定义 | 0x142a905a0 |
| 16403 | CStopProjectCommand | 五槽自定义 | 0x142a90668 |
| 16412 | CAddIndustrialOrgTraitToQueueCommand | 五槽自定义 | 0x142967e68 |
| 16413 | CRemoveIndustrialOrgTraitFromQueueCommand | 五槽自定义 | 0x142967f30 |
| 16467 | CNavySetUnderwayReplenishmentCommand | 五槽自定义 | 0x1429af048 |
| 16602 | NRaids::NNet::CSetRaidRiskLevelCommand | 五槽自定义 | 0x142a41650 |
| 16737 | CSetCountryRaidsPriorityCommand | 五槽自定义 | 0x14272dd18 |
| 16738 | CSetFleetHomeBaseCommand | 五槽自定义 | 0x1429afd90 |
| 16755 | NFactions::CUnlockFolderDoctrineSharingCommand | 五槽自定义 | 0x142a49d78 |
| 16777 | NDoctrines::CUnlockGrandDoctrineCommand | 五槽自定义 | 0x142a32320 |
| 16779 | NDoctrines::CUnlockSubDoctrineCommand | 五槽自定义 | 0x142a323e8 |
| 16842 | CSetOrderGroupLeaderProximityCommand | 五槽自定义 | 0x142a0aa30 |
| 17327 | CRecruitScientistCommand | 五槽自定义 | 0x142a90348 |
| 17596 | CRestructureShipsToTaskforceCompositions | 五槽自定义 | 0x1429b0d30 |
| 17685 | CUpgradeShipCaptainCommand | 五槽自定义 | 0x142997a88 |
| 18740 | CSetIndustrialOrgTraitsInQueueCommand | 五槽自定义 | 0x1429680c0 |
| 18856 | CRemoveAdmiralFromNavyHeadquarter | 五槽自定义 | 0x142a0d2d0 |
| 18857 | CAssignAdmiralToNavyHeadquarter | 五槽自定义 | 0x142a0d208 |
| 19010 | CLaunchOperationCommand | 五槽自定义 | 0x1429784a0 |
| 19020 | CSetOperationAutoCommenceCommand | 五槽自定义 | 0x142978568 |
| 19064 | CStartStopDecryptionCommand | 五槽自定义 | 0x142a2eb38 |
| 19072 | CActivateActiveDecryptionBonuses | 五槽自定义 | 0x142a2ec00 |
| 19078 | CHideDecryptionCommand | 五槽自定义 | 0x142a2ecc8 |
| 19119 | CBecomeSpyMasterCommand | 五槽自定义 | 0x142a2e9a8 |
| 19120 | CSetMainGarrisonTemplateCommand | 五槽自定义 | 0x142995c88 |
| 19121 | CSetCountryGarrisonTemplateCommand | 五槽自定义 | 0x142995d50 |
| 19123 | CSetStateGarrisonTemplateCommand | 五槽自定义 | 0x142995e18 |
| 19124 | CSetCountryGarrisonPriorityCommand | 五槽自定义 | 0x14272db88 |
| 19128 | CIntelligenceAgencyCancelCreationCommand | 五槽自定义 | 0x142a2e4f8 |
| 19129 | CIntelligenceAgencyCancelUpgradeCommand | 五槽自定义 | 0x142a2e688 |
| 19138 | CAmendForeignManpowerActionCommand | 五槽自定义 | 0x142997380 |
| 19163 | CSetDesignTeamCommand | 五槽自定义 | 0x142967a80 |
| 19173 | CSetIndustrialOrganisationTaskCommand | 五槽自定义 | 0x142a23348 |
| 19192 | NRaids::NNet::CCreateRaidCommand | 五槽自定义 | 0x142a41010 |
| 19194 | NRaids::NNet::CExecuteRaidCommand | 五槽自定义 | 0x142a411a0 |
| 19195 | NRaids::NNet::CSetRaidAutoComplete | 五槽自定义 | 0x142a41330 |
| 19209 | NRaids::NNet::CCancelRaidCommand | 五槽自定义 | 0x142a417e0 |
| 19266 | CRecruitOperativeCommand | 五槽自定义 | 0x142a2ed90 |
| 19334 | CSetArmyFakeTemplateCommand | 五槽自定义 | 0x1429b26b8 |
| 19370 | CSetDefaultCountryOccupationPolicyCommand | 五槽自定义 | 0x142995a30 |
| 19412 | CIgnoreAllAvailableDecisionCommand | 五槽自定义 | 0x142996e08 |
| 19416 | CSetWingReinforcementPreferenceCommand | 五槽自定义 | 0x142a1de08 |
| 19425 | CSetOperationAutoRepeatCommand | 五槽自定义 | 0x142978630 |
| 19438 | NRaids::NNet::CRemoveRaidCommand | 五槽自定义 | 0x142a41970 |
| 19526 | NRaids::NNet::CSetRaidAutoLaunchOption | 五槽自定义 | 0x142a414c0 |
| 19563 | CReplaceAdvisorCommand | 五槽自定义 | 0x142995968 |
| 19564 | CAddAdvisorCommand | 五槽自定义 | 0x142995580 |
| 19567 | CRemoveAdvisorCommand | 五槽自定义 | 0x142995710 |
| 19568 | CUnlockResearchCommand | 五槽自定义 | 0x142995008 |
| 19586 | CGenerateAdvisorCommand | 五槽自定义 | 0x1429954b8 |
| 19603 | CAddAdvisorRoleToCharacterCommand | 五槽自定义 | 0x1429953f0 |
| 19604 | NFactions::CAddFactionGoalCommand | 五槽自定义 | 0x142a4a3b8 |
| 19610 | NFactions::CSetFactionRuleCommand | 五槽自定义 | 0x142a498c8 |
| 19624 | CRetireCharacterCommand | 五槽自定义 | 0x1429957d8 |
| 19641 | NFactions::CCreateFactionTheater | 五槽自定义 | 0x142a49b20 |
| 19689 | CSetSupplyTruckBufferRatioCommand | 五槽自定义 | 0x142995fa8 |
| 19690 | CSetSupplyReinforcementPriorityCommand | 五槽自定义 | 0x142995ee0 |
| 19691 | CChangeRailwayConstructionLeveLCommand | 五槽自定义 | 0x1429975d8 |
| 19701 | CUpdateSupplyNodeCountrySettingsCommand | 五槽自定义 | 0x1429976a0 |
| 19705 | CBuildRailwayCommand | 五槽自定义 | 0x142997510 |
| 19723 | CSetSupplyCapitalNodeCommand | 五槽自定义 | 0x142997448 |
| 19730 | CSetObsoleteDivisionTemplateCommand | 五槽自定义 | 0x142a48118 |
| 19731 | CReorderTemplateListCommand | 五槽自定义 | 0x142a481e0 |
| 19743 | CSetAutoUpgradedEquipmentVariantCommand | 五槽自定义 | 0x142a24890 |
| 19754 | NFactions::CSetFactionPingExecutionType | 五槽自定义 | 0x1429ac870 |
| 19760 | NFactions::CClearFactionTheater | 五槽自定义 | 0x142a49be8 |
| 19761 | NFactions::CModifyFactionTheater | 五槽自定义 | 0x142a49e40 |
| 19765 | NFactions::CSetFactionTheaterPinVisibility | 五槽自定义 | 0x142a49cb0 |
| 19837 | CAiOnFailedInvasionCommand | 五槽自定义 | 0x142a31bf0 |
| 19847 | CAiStoreTotalWantedNrDivisionsCommand | 五槽自定义 | 0x142a31cb8 |
| 19870 | CAssignRailwayGunToOrdersGroup | 五槽自定义 | 0x142972960 |
| 19871 | CUnassignRailwayGunFromOrdersGroup | 五槽自定义 | 0x142972a28 |
| 19872 | CRailwayGunManualOrderCommand | 五槽自定义 | 0x142972af0 |
| 19873 | CRailwayGunSetNameCommand | 五槽自定义 | 0x142972bb8 |
| 19882 | CSetWingEquipmentNicheCommand | 五槽自定义 | 0x142a1dd40 |
| 19911 | CSetPreferredTacticCommand | 五槽自定义 | 0x142997768 |
| 19918 | CSetScorchedStateCommand | 五槽自定义 | 0x1429978f8 |
| 19926 | CUpdateLeaderSeenAdvisorRolesCountCommand | 五槽自定义 | 0x142a0cee8 |
| 19927 | CSetArmyLeaderPreferredTacticCommand | 五槽自定义 | 0x142997830 |
| 19941 | CAddTaskForceTemplateCommand | 五槽自定义 | 0x1429b0ad8 |
| 19942 | CRemoveTaskForceTemplateCommand | 五槽自定义 | 0x1429b0ba0 |
| —(继承基座) | CIncreaseGameSpeedCommand | 全继承基座 | 0x142977040 |

#### 4.33.3 CSetRandomSeed (id 10731)

| 项 | 值 |
|---|---|
| vtable | 0x14296A240 |
| IsValid [9] | 基座默认 (恒真) |
| Execute [10] | 0x140DE9D30 |
| Clone [13] | 0x140DE7070 |
| 载荷 writer / reader | 0x140DEA430 / 0x140DEA0E0 |

载荷布局 (基类 +40 起):

| 偏移 | 类型 | 名称 | reader token | 备注 |
|---|---|---|---|---|
| +40 | uint32 | seed_lo | 10647 | 播种迭代输入 |
| +44 | uint32 | seed_hi | 10730 | 直存状态槽 |

> Execute 语义 (定案): 调播种函数 sub_142234600(seed_lo, seed_hi)，随后
> sub_140DB13D0(&qword_14333CEA8) 全局通知 (未名)。

> 播种函数 sub_142234600 (定案): 状态槽 = dword_143452520 (= seed_hi) 与
> dword_143452524 (= 由 seed_lo 经 mulberry 型迭代:
> v2 = (2126043716·lo) ^ ((2126043716·lo) >> 8) + 282605150;
> v3 = 1831007003 · (v2 ^ (v2 << 8)); state = v3 ^ (v3 >> 8))。
> Lua 侧直接驱动 = call_void(基址 + RVA 0x2234600, lo, hi)。

> **活体验证（test1 会话实测）**: call_void 后 hi 槽 = 678 精确落位、state 槽 = 3697534018 与公式期望值逐位一致——全链定案。

#### 4.33.4 命令载荷序列化 helper 指纹

writer [22] / reader [23] 体内的公共 helper（逐调用对名定案，读卡先验）:

| helper | 语义 |
|---|---|
| sub_1424C4220(w, tok) | 只写 token 名（开键） |
| sub_1424C2EA0 / sub_1424C2C40 / sub_1424C2E20 | 写串 / 写 u32 / 写嵌套对象 |
| sub_1424C2F40 / sub_1424C34F0 / sub_1424C37B0 | 写 u32 / 写 i64 / 写 bool |
| sub_142220180 / sub_142220260 | 写 CIdentifier（8B 双 dword）/ 带 token 版 |
| sub_1424C4410 / sub_1424C3E60 / sub_1424C3A20 | 数组开 / 元素开 / 数组闭 |
| sub_14221F970 / sub_1401B2240 / sub_1401B29C0 / sub_1401CBF60 | 读 CIdentifier（常带门）/ 读 id 直写 / 读 id 数组 / 数组追加 |
| sub_1424C08D0 / sub_1424C0A70 / sub_1424C0C00 / sub_1424C0AB0 / sub_1424C0AA0 | 读 u32 / 读 i64 / 读 bool / 读串 / 读嵌套对象 |
| sub_1424C2060 | 未知 token 跳过（air 系 reader 默认分支用，非家族默认） |
| sub_1424BEC40 | 家族基座默认载荷 reader（各 reader default 分支统一转它） |

> 嵌套对象读门：凡 sub_14221F970 读 id 后都有 `v = *(r+296); if (!v || !*BYTE(v+8) || !*BYTE(v+9))` 才落盘——解析上下文 +296 双字节旗控制 id 字段写入。

> CIdentifier 约定：sub_14221F310(&id) 解析得**对象指针 +16**（判空哨兵 = 16）；有效载荷对象 = 返回值 −16。

> 标识符数组容器：24B {data@+0, ?@+8, count(int)@+12}；Clone 统一 sub_14011DF40 空建 + sub_1402BE050 重建。

> 经验值换算（模板 Create/Update 共用）：`((v %100000)<<30)/3276800000 + ((v/100000)<<15)` = 1e-5 XP → fixed×2^15 XP。

> Clone 基座拷贝细节：malloc(sizeof) 后 +0 先写基座虚表再覆写派生表；+8 重播门清零；+12 发送方拷贝；+16 清零；+20/+22/+24/+25/+28/+32 逐值拷贝；派生载荷自 +40。

> 玩家/UI 通道（反复出现）：gamestate+1312（+328）/ +1316 = 当前/观察国 tag；qword_14332F698（陆军 UI）+160 查看国 / +184 玩家国家 / +200 战区页；通知号 sub_140224C30（本域见 4/11/14/18/19）。

#### 4.33.5 编成/模板/部署域

| id | 类 | vtable | sizeof | 载荷（+40 起） | Execute 语义 |
|---:|---|---|---:|---|---|
| 12197 | CCreateDivisionTemplateCommand | 0x1429ABD00 | 648 | +40 定义块 584B(12112 = CDivisionTemplateData, 布局 §4.18.4; 深拷贝 sub_1412FB340; 命令级校验 = 块+476 byte 许可选择旗 / 块+520 dword 类别 ≠3) / +624 tag(10394) / +632 i64 经验(10323) / +640 可选群(12462) | 0x141B9EAE0 定案: def+tag 定形 → 注册进国模板集（sub_140BA61C0→sub_140B95E30 集+24）→ 挂册 sub_1406D09A0 → 扣经验（池=国+5512）→ 可选群绑模板 sub_140BF6370 → "update_template" 事件 |
| 12198 | CUpdateDivisionTemplateCommand | 0x1429ABC38 | 648 | +40 定义块 584B(12112, §4.18.4; +476 置位时 Execute 联动部队) / +624 目标模板(12610) / +632 tag(10394) / +640 经验(10323) | 0x141B9FAE0 定案: sub_140B9E550(模板+24, def) 落体 → 扣经验 → 模板+460 旗时遍历国部队表重灌编成（sub_140C22CE0）→ 四路刷新 |
| 13574 | CRemoveDivisionTemplateCommand | 0x1429ABDC8 | 48 | +40 模板 id(12610) | 0x141B9F370 定案: sub_14070E770(国,模板,0,1) 注销 + 全局注销/通知 |
| 14601 | CSetDivisionNameCommand | 0x1429B22D0 | 88 | +40 师(10403) / +48 名串(27) / +80 名序(14563, -1=缺省) / +84 override(14561) / +85 有序(14562) | 0x141367AB0 定案: 显式名 sub_140C8EFB0 / 名序双路 sub_140C8EF50·sub_140C8F110; 远征队禁改 |
| 13270 | CSetArmyTemplateCommand | 0x1429B25F0 | 72 | +40 部队 id 数组(12202, count@+52) / +64 模板(12112) | 0x1413675A0 定案: 逐部队 sub_140C8E550 套模板 + 指挥权重核算（超限延迟清单）+ 重灌编成; 特战上限/指挥权预检 |
| 19334 | CSetArmyFakeTemplateCommand | 0x1429B26B8 | 72 | 载荷同 13270: +40 部队 id 数组(12202, count@+52) / +64 模板(12112) | 0x141367340 定案: 逐部队写假模板 sub_140C8E970; 仅限假情报编队（IsValid 双参 not fake intel army 门） |
| 12369 | CSetArmyLeaderCommand | 0x142A0C3F8 | 64 | +40 指挥官(10423, 可缺省) / +48 群(63) / +56 部署 HQ 旗(10283) | 0x14184B2E0 定案: 调任三连（sub_141361F10/BEF0/8310）或直任 sub_140BF5A20 → 扣指挥权 → 登册; +56 时构 CDeployArmyHq 计划执行 |
| 19927 | CSetArmyLeaderPreferredTacticCommand | 0x142997830 | 56 | +40 指挥官(10423) / +48 CTactic*(19912) | 0x14115B940 定案: *(指挥官+4272)=战术指针; 同缺省战术则复位+通知 |
| 10283 | CDeployArmyHqCommand | 0x1429B2398 | 56 | +40 群(12462) / +48 模板(19482) | 0x1413661E0 定案: sub_140BF6370(群, 模板) 群绑模板; IsValid 门最多（db 门/冷却/指挥权/成员位置） |
| 14433 | CArmyGroupCommand | 0x142A0AC88 | 128 | +40 战区(12058) / +48 部队 id 数组(63) / +72 分组条目数组(12202) / +96 可选前线(10720) / +104 section / +112/+120 比例区间 i64(10639/10640) | 0x141842970 定案: sub_140EF0FC0(战区, 清单) 建群 → 可选前线命令体构造挂接（sub_140BEAC90） |
| 14470 | CAssignToArmyGroupCommand | 0x142A0AD50 | 80 | +40 部队 id 数组(63) / +64 群(14482) / +72 位次 i32(76) | 0x1418431A0 定案: 计划三连整批划入; 位次自增保序（sub_140BEAB30） |
| 14471 | CRemoveFromArmyGroupCommand | 0x142A0AE18 | 64 | +40 部队 id 数组(63) | 0x14184B1E0 定案: 部队+440 现属群非零则 sub_140BF58D0(部队, 0) 出群 |
| 14901 | CAssignArmyToArmyGroupFront | 0x142A0D078 | 80 | +40 部队(63) / +48 SOrderInstanceRef 16B(13815) / +72 比例 i64(694) | **死命令壳（定案, 高置信）**: Execute=CFG 空桩; post 不生效/drain 无特判/工厂与 Clone 零调用者/18 处 ref 消费者皆非执行体 |
| 14991 | CMoveArmyGroupInTheaterCommand | 0x142A0AFA8 | 56 | +40 群(14482) / +48 位次 u32(524) | 0x141843F10 定案: 群+64 战区容器（+152 数组/+164 数目）重排 |
| 14636 | CAttachAirWingToArmyCommand | 0x142A1E1F0 | 72 | +40 联队 id 数组(13161) / +64 陆军(10397) | 0x141944CD0 定案: 关系==4（可挂接）者 sub_140BEB3C0 挂接 |
| 14637 | CDetachAirWingFromArmyCommand | 0x142A1E2B8 | 64 | +40 联队 id 数组(13161) | 0x141945130 定案: sub_140F5DD60 脱挂; reader 默认分支=sub_1424C2060（air 系跳过式） |
| 13091 | CDeployAirWingCommand | 0x142995198 | 168 | +40 tag(10394) / +44 流亡 tag(15034) / +48 转场(12249) / +56 定义块64B(12110, 旗+120) / +128 SubUnitDef* 活指针(10706, 仅发端; +164=死 id 残槽, sub_unit 键跨会话必失——清偿定案) / +136 联队组(12213) / +144 目标(107) / +152 王牌(12770) / +160 补充旗(19415) / +164 名表 id 落点 | 0x1411565E0 定案: 定义/名表二路造联队件 → sub_140E6EBB0 入册 → sub_140C4FD20 分派战区/基地/王牌 |
| 19941 | CAddTaskForceTemplateCommand | 0x1429B0AD8 | 184 | +40 tag(10394) / +48 名(27) / +80 模板对象(15157) | 0x141350450 定案: *(gs+1688) 国槽管理器 → 模板列追加 sub_14135C2C0 |
| 19942 | CRemoveTaskForceTemplateCommand | 0x1429B0BA0 | 80 | +40 tag(10394) / +48 名(27) | 0x141353770 定案: 模板列线性扫名（条目 stride 136B）删单条 |
| 14022 | CChangeConveyorTemplateCommand | 0x142A487A8 | 56 | +40 传送带(13492) / +48 模板(12610) | 0x141BA2F00 定案: 换绑 + 按模板名改名（sub_140CEB580） |
| 13600 | CDeployConveyorCommand | 0x142A48AC8 | 48 | +40 传送带(13492) | 0x141BA3200 定案: 管理器定位序 sub_140D11370 → 部署 sub_140D101C0 |
| 13485 | CDeployConveyorLineCommand | 0x142A48DE8 | 48 | +40 部署线(13491) | 0x141BA3270 定案: 父带（线+56）→ sub_140D10260 线入带 |
| 19847 | CAiStoreTotalWantedNrDivisionsCommand | 0x142A31CB8 | 56 | +40 tag(10394) / +44/+48/+52 min/desired/max i32(19846/15585/15586) | 0x141A74660 定案: 写战略 AI +8448/+8452/+8456 |
| 19731 | CReorderTemplateListCommand | 0x142A481E0 | 56 | +40 模板(12610) / +48 位次 u32(524) | 0x141B9F5F0 定案: 国+440 指针表相邻交换平移（钳 count−1） |
| 13753 | CStrategicRedeploymentCommand | 0x1429B2DC0 | 80 | +40 内嵌 CUnitStrategicMoveAction 40B(vt 0x1429A3BD8) / +48 u32 不序列化(=action+8 动作类型 id 13898, ctor 写死——清偿定案) / +56 army(10397) / +64 省(10304) / +68 clear(10737) / +72 move_priority(14268) | 0x1413669E0 定案: 五槽薄壳转发 action（槽序相反）; action[9]→sub_1412346D0 寻路 sub_140E2AD40 → sub_140BF9A40 落路径 |
| 10291 | CWithdrawArmyHqCommand | 0x1429B2460 | 48 | +40 群(12462) | 0x141368310 定案: DLC 57 门 → sub_140BF6620 撤回命令组将领; 冷却双门 |
| 19121 | CSetCountryGarrisonTemplateCommand | 0x142995D50 | 56 | +40 占领国(10394) / +44 被占国(15793) / +48 模板(12610) | 0x14115BD20 定案: OccupationData 查键 sub_140FF3BE0 → sub_140FFE3C0: occdata+200=模板 + 遍历 +32 容器重配驻军 |
| 12612 | CSetCountryReinforcementPriorityCommand | 0x14272DAC0 | 48 | +40 tag(10394) / +44 priority(141, 0..2) | 0x14115C1C0 定案: 写 sub_1406CF8B0(国)+8 = 国+3960 子对象+8 |
| 14612 | CSetDeploymentLineNameCommand | 0x142A48EB0 | 88 | +40 线(13491) / +48 名(27) / +80 名序(14563) / +84 is_name_ordered(14562) / +85 override(14561) | 0x141BA36D0 定案: 自定名 sub_1409C8B90 / 序号双路; ⚠ 两旗偏移与 CSetDivisionNameCommand 互换（三侧自洽） |
| 13550 | CSetDivisionTemplateSymbolCommand | 0x1429ABB70 | 56 | +40 模板(12610) / +48 符号计数(13549, -1=无) | 0x141B9F780 定案: 模板+448 号与 +452 有无旗双写; 玩家侧 216B 事件入队 |
| 19120 | CSetMainGarrisonTemplateCommand | 0x142995C88 | 56 | +40 tag(10394) / +44 模板(12610) | 0x14115C560 定案: sub_140FFDDE0 = *(国家+120)=模板（主驻军模板槽） |
| 13106 | CSetNavalDeploymentTargetCommand | 0x1429941F8 | 72 | +40 线(12211) / +48 特混(15157, 兼容旧 10398 navy) / +56 战区(12058) / +64 基地省(11398) | 0x14115C6A0 定案: 五元写 sub_1411601D0（line 基对象 +656 取得） |
| 19730 | CSetObsoleteDivisionTemplateCommand | 0x142A48118 | 56 | +40 模板(12610) / +48 obsolete u8(12396) | 0x141B9F9F0 定案: 模板+566 废弃旗写点（sub_140BA5F10 带重算） |
| 14876 | CSetQuickDeployPreferenceCommand | 0x142A1EA88 | 72 | +40 引擎向量 32B 对象指针数组(12300 types; reader id→sub_1409F7F60(qword_14332EEC0,id) 反解) / +64 tag(10394) / +68 类目(702) | 0x141946380 定案: sub_141965920 整表替换快速部署偏好清单 |
| 14987 | CSetSelectedArmyGroupFallback | 0x142A0D140 | 56 | +40 群(63) / +48 命令实例(13815) | 0x14184BB00 定案: **Execute 空操作**（仅断言 !"remove"）; 壳保留 |
| 15233 | CSetShipRefitDeploymentTargetCommand | 0x1429942C0 | 72 | 与 13106 同构载荷: +40 线(12211) / +48 特混(15157) / +56 战区(12058) / +64 基地省(11398); writer 特混/战区互斥写其一 | 0x14115D9D0 定案: 改装目标 sub_140F71AF0 → sub_1411601D0 |
| 19123 | CSetStateGarrisonTemplateCommand | 0x142995E18 | 56 | +40 占领国(10394) / +44 州(439) / +48 模板(12610) | 0x14115DA90 定案: 按州控制方查 OccupationData → sub_140FFE420 按州设模板 |
| 19690 | CSetSupplyReinforcementPriorityCommand | 0x142995EE0 | 48 | +40 tag(10754) / +44 priority(141) | 0x14115E1F0 定案: wrapper=*(gs+784 基+8·idx)，写 sub_1406CF380(wrapper)+16（wrapper 身份待裁）; [9] 走基座恒真 |
| 15170 | CSetTaskForceAutoReinforcementCommand | 0x1429AFE58 | 72 | +40 特混 id 对数组(15157) / +64 旗 u8(15169) | 0x1413568E0 定案: 批量设特混自动补员旗（+1271） |
| 19416 | CSetWingReinforcementPreferenceCommand | 0x142A1DE08 | 72 | +40 联队 id 对数组(12213) / +64 设定 u8(19415, <4) | 0x141946430 定案: 批量设联队补员设定（ret+2492） |
| 12615 | CSetWingReinforcementPriorityCommand | 0x142A1DED0 | 56 | +40 联队(13161) / +48 priority(141) | 0x1419464B0 定案: 联队+40 钳制写入（上界全局 dword_143337588 运行时值待裁） |
| 15584 | CToggleStrategicDeploymentCommand | 0x1429B1EE8 | 64 | +40 单位 id 对数组(12202) | 0x141367F00 定案: +687 战略转移旗多数决批量切换（单位虚槽 +424 开/关） |
| 11061 | CUpgradeDivisionOfficerCommand | 0x1429979C0 | 56 | +40 师(10403) / +48 type u32(225, reader 拒>3, IsValid 限<2) | 0x14115FA10 定案: 扣经验升级师军官 |
| 14463 | CSetArmyToConsolidateForUnit | 0x1429B1D58 | 56 | +40 army(10397) / +48 并入目标(14464, 可空对=清除) | 0x141367A40 定案: 设单位整编目标 |

> [17] GetDesc 家族内唯一覆写 = CSetArmyLeaderCommand（0x14184C790，"CSetArmyLeaderCommand: <名> Assigned to <名>"），其余基座空串。

> IsValid 双参变体（带 "#~ " 错误串出口）五类：CSetDivisionName / CSetArmyTemplate / CSetArmyFakeTemplate / CDeployArmyHq / CAiStoreTotalWantedNrDivisions；其余单参。


> 编成域补充待裁：① 联队补员优先级上界 = dword_143337588（**活体实读 = 3, 定案**）；② CStrategicRedeployment +48 不序列化；③ DLC 门 sub_1401AEB50(57) 对应资料片名；④ 补给补员优先级 wrapper（gs+784 数组元素经 sub_1406CF380）对象身份；⑤ 单位虚槽 +424 与 +56/+64 的槽语义。

> 机动/订单域补充：新 helper sub_1424C0900/C3020（文本标量通道）、u32 数组三件套、find-instance 两株；运行时全局 qword_14333D528 = 当前前线 idpair（三证）；订单实例 +48 类型枚举（1/3/4）、+184 源省、CUnit+704 动作队列。**死命令壳 2（14901/14857, 清偿定案无生效路由）、空操作 1（14987）**。

> **清偿定案（编成/机动域）**: ① XP 刻度不对称 = 引擎原生不一致（内存两命令同 1e-5 XP; 盘上 create cost=原值 i64 通道、update cost=整 XP /100000+u32 通道——重放后 Update 扣减缩水 1e5 倍）; ② 13753 +48 = 动作类型 id 13898; ③ DLC 门 sub_1401AEB50(57) = **Thunder at Our Gates**（dlc052）; ④ 补给 wrapper = **CCountrySupplySystem**（sub_1406CF380 = per-country getter, +16=priority 与 s4_21 同槽）; ⑤ CUnit 虚槽 +424 = SetStrategicRedeploying(bool)→写 +687, +56/+64 = 军官载体 getter; ⑥ CUnit 1.19.3 主虚表 = **0x1429530D8**（0x14293CA88 系 1.19.2 旧址, 勘误）。

> 待裁三项：① Update(12198) 载荷经验 writer 除 100000 而 Create(12197) 原值直写，Execute 两侧均按 1e-5 口径——落盘刻度不对称；② DeployAirWing(13091) +128 写侧解引用取 id / 读侧 id 落 +164 且 +128 保持空；③ CAssignArmyToArmyGroupFront(14901) 空桩 Execute 的实际生效路由。

#### 4.33.6 经济生产域（生产线）

> 线对象横断事实：生产线 idpair 经 sub_14221F310 解析即线对象基址；线 +248 = 名表宿主 {data@+0, count@+12}，元素 176B（naval 名表）；naval deployment +48 = 舰载机初编成池。Name 三件套共享槽组 0x1411624E0/0x14116F130/0x1411698C0；Remove 对共享 0x141170250/0x14116BEE0；tag>0 门共享 0x140CAA8B0。Name 族 IsValid 只认线 type ∈ {57,75}。

| id | 类 | vtable | sizeof | 载荷（+40 起） | Execute 语义 |
|---:|---|---|---:|---|---|
| 13101 | CAddProductionLineCommand | 0x142993708 | 64 | +40 tag(107, 串→tag) / +44 装备(12110) / +52 可选厂商(19160) / +60 置顶旗(602) | 0x141152210 定案: 建线（可内联挂厂商） |
| 15235 | CRemoveProductionLineCommand | 0x142993BB8 | 48 | +40 线(12211) | 0x141159500 定案: 删单线（sub_140E6ED60） |
| 12142 | CSetProductionLineCommand | 0x142993AF0 | 56 | +40 线(12211) / +48 新装备(12110) | 0x14115CE70 定案: 线换绑装备；判异四键 = 架构/version 任一不同即清 +56 produced，creator(+28)/origin(+32) 双 0 不判异、带同盟等价容差 sub_140BB52F0 |
| 12257 | CSetProductionLineAmountToProduceCommand | 0x142994E78 | 56 | +40 线(12211) / +48 数量 u32(417, -1=默认无限) | 0x14115CDA0 定案: 线虚槽[17] 写产出量（数量落**线+72**，活体实测 0xFFFFFFFF→99 精确落位） |
| 14372 | CSetProductionLinePriorityCommand | 0x142994CE8 | 64 | +40 idpair 数组(141; **数组顺序即目标优先序**) | 0x14115D190 定案: 整表批量定序（GetType 0 军产/1..3 general 分派） |
| 12147 | CChangeProductionLinePriorityCommand | 0x142994C20 | 56 | +40 线(12211) / +48 目标位次 u32(12146) | 0x141155930 定案: 单线绝对位次重排 |
| 13636 | CAddMassFactoryAssignmentCommand | 0x142993A28 | 88 | +40 线 id 数组(12211) / +64 i32 数组(12150) 平行 | 0x141151D00 定案: 批量产线工厂增量（按位对齐） |
| 13352 | CAddMassProductionsLineCommand | 0x1429937D0 | 96 | +40 tag(107) / +48 装备数组(12110) / +72 数量数组(10730) | 0x141152000 定案: 批量建线（装备×count 平行表） |
| 12149 | CAddProductionLineFactoriesCommand | 0x142994DB0 | 56 | +40 线(12211) / +48 工厂增量 i32(12150, 可负) | 0x1411524C0 定案: requested_factories(+232) 增量; IsValid 钳虚表[11] 上限 |
| 13638 | CMassRemoveProductionsLineCommand | 0x142993898 | 64 | +40 线 id 数组(12211, 平铺重复键无数组包) | 0x1411578A0 定案: 批量删线 |
| 13979 | CRemoveAllProductionLineCommand | 0x142993D48 | 48 | +40 tag(10754) | 0x141158CB0 定案: 全清产线（sub_140E6E220）; IsValid=tag>0 门共享 |
| 12679 | CConvertFactoryCommand | 0x142994B58 | 56 | +40 源省(10639) / +44 目标省(10640) / +48 州(439) / +52 优先旗 u8(141) | 0x141155C00 定案: 省间工厂转换队列入列/撤销（队列条目布局待裁） |
| 14301 | CSetProductionLineConvertCommand | 0x142993E10 | 56 | +40 线(12211) / +48 开关 u8(10376, 仅真写) | 0x14115CFE0 定案: 线 +236 is_converting 开关 |
| 15320 | CAddProductionLineName | 0x142994450 | 80 | +40 naval 线(12211, type∈{57,75}) / +48 名串 32B(27) | 0x1411525A0 定案: 按名登记（线+248 名表） |
| 15498 | CAddProductionLineOrderedName | 0x142994518 | 56 | +40 naval 线 / +48 位次 u32(524, >0 门) | 0x1411526C0 定案: 名表有序登记 |
| 15499 | CAddProductionLineUnorderedName | 0x1429945E0 | 56 | 同 15320: +40 naval 线(12211) / +48 位次 u32(524, idx≥0 门) | 0x1411527E0 定案: 名表无序登记（sub_1409C9260） |
| 15319 | CRemoveProductionLineName | 0x1429946A8 | 56 | +40 naval 线 / +48 位次 u32(524) | 0x1411596B0 定案: 删名表条目 |
| 15318 | CChangeProductionLineNamePriorityCommand | 0x142994388 | 56 | +40 naval 线 / +48 现位次(524) / +52 目标位次(12146) | 0x1411558F0 定案: 名表条目移位重排 |
| 13105 | CRemoveShipRefitProductionLineCommand | 0x142993C80 | 48 | +40 refit 线(12211) | 0x141159750 定案: 线→舰→sub_140D76BD0 摘除（写点链高置信） |
| 14730 | CProductionLineInterfaceFactoriesScaleCommand | 0x142993ED8 | 72 | +40 线数组(12211) / +64 缩放 u32(93, 限 1..3, ≠1 才写) | 0x141157D50 定案: 批量写线 +240 缩放 |
| 14678 | CProductionLineInterfaceToggleExpandCommand | 0x142993FA0 | 72 | +40 线数组(12211) | 0x141158100 定案: 批量写线 +237 折叠 |
| 14699 | CProductionLineInterfaceToggleExpandAllCommand | 0x142994068 | 48 | +40 tag(10394) / +44 折叠旗 u8(14608, 仅真写) | 0x141157F50 定案: 全军产线写 +237 折叠（仅 ps+88 容器） |
| 13694 | CSetNavalProductionLineAirWingCompositionCommand | 0x142994130 | 80 | +40 naval 线(12211) / +48 CEquipmentArcheTypePool 内嵌(13691; 容器 {data@56, count@68}) | 0x14115C750 定案: 舰载机初编成池双写（deployment+48 与国+3952 持有点） |

#### 4.33.7 装备/市场/MIO 域

> 变体写点与书 s4_23 CEquipmentVariant 字段表互证一致（+1060 obsolete / +1061 auto_upgraded / +1062 highlight / +1068 niche_icon / +1072 override_model / +1104..+1151 override_sprite / +1152 name_list）；`*(cc+3944)` = CProductionStatus 与 s4_08 互证。共享 IsValid 桩：0x141165920 四类、0x141162CE0 两类；MIO Add/Remove/Unlock 三胞胎共享 [22]/[23]（0x14199E680/0x14199DE90）。

| id | 类 | vtable | sizeof | 载荷（+40 起） | Execute 语义 |
|---:|---|---|---:|---|---|
| 12395 | CCreateEquipmentVariantCommand | 0x142A240C0 | 400 | +40 架构 CEquipmentType*(12110) / +48 创建国(12397) / +52 母本(135)+has_parent / +64 名(27) / +96 upgrades(12393) / +176 modules(15211) / +200 图标(15526) / +208 名单组预置 121B(15494) / +336 XP(10323) / +344..348 三旗+设计团(19159) / +360 团加成内嵌(19165) / +392 团特性数(16386) / +396 沿用产线旗(12143) | 0x1419A30E0 定案: 组装 upgrades/modules/设计团请求包 → sub_1401D2EE0 建变体 + 扣 XP + 登记 ps + 可转母本产线 |
| 15524 | CUpdateEquipmentVariantCommand | 0x142A24188 | 384 | +40 待改变体（**挂在 135 parent 键下**） / +48 新架构(12110) / +56 新名(27) / +88 upgrades / +168 modules … | 0x1419A4F60 定案: 换架构/模块/名/设计团，sub_140BD6FC0 应用设计 + XP 扣减 + 师图标刷新 |
| 14424 | CStockpiledEquipmentDeleteCommand | 0x142A247C8 | 56 | +40 tag u32(10754) / +44 变体 idpair 8B(12110, 哨兵门) | 0x1419A4DE0 定案: 删国库存中该变体全部存量并重算装备缺口 |
| 14495 | CUnlockIndustrialOrganisationTrait | 0x142967CD8 | 72 | +40 属国 tag u32(10394) / +48 STraitId 16B(11918; id@+56) / +64 MIO idpair 8B(11979) | 0x14199CF00 定案: MIO 特性解锁（sub_140DBC7D0）+ ps 刷新 + 窗口 2 |
| 19173 | CSetIndustrialOrganisationTaskCommand | 0x142A23348 | 72 | +40 MIO idpair 8B(11979) / +48 让出产线 idpair 8B(12212, 条件写) / +56 新研究句柄 qword(19174, 按名 sub_140ACBF40) / +64 新产线 idpair 8B(19175, 条件写) | 0x14199CE80 定案: 设 MIO 任务——解绑旧产线 / 挂研究（sub_141A00F80）/ 挂产线（sub_141A00F70）；new_research 与 new_production 恰选一 |
| 12398 | CRenameEquipmentVariantCommand | 0x142A24570 | 80 | +40 变体 idpair 8B(12110) / +48 新名串 32B(27) | 0x1419A41F0 定案: 变体改名 |
| 19743 | CSetAutoUpgradedEquipmentVariantCommand | 0x142A24890 | 56 | +40 变体 idpair 8B(12110) / +48 auto_upgraded u8(19744) | 0x1419A4380 定案: 变体 +1061 auto_upgraded 开关 |
| 19163 | CSetDesignTeamCommand | 0x142967A80 | 64 | +40 属国 tag u32(10394) / +48 科技句柄 qword(10335, 按名解析) / +56 MIO idpair 8B(11979, 可缺省) | 0x14199CA90 定案: MIO 挂为科技设计团（sub_141A00F80 同原语），刷窗口 5/6 |
| 14038 | CSetEquipmentVariantHighlightCommand | 0x142A24638 | 56 | +40 变体 idpair 8B(专键 13891) / +48 highlight u8(14039) | 0x1419A44D0 定案: 变体 +1062 highlight 开关 |
| 15497 | CSetEquipmentVariantNameListCommand | 0x142A244A8 | 80 | +40 变体 idpair 8B(12110) / +48 名字组名串 32B(15495) | 0x1419A4580 定案: 设师名组（intern 后写变体 +1152） |
| 15525 | CSetEquipmentVariantNicheIconCommand | 0x142A243E0 | 56 | +40 变体 idpair 8B(12110) / +48 角色图标 u32(15526) | 0x1419A46F0 定案: 变体 +1068 角色图标，海/空现役单位刷新 |
| 15496 | CSetEquipmentVariantOverrideModelCommand | 0x142A24250 | 80 | +40 变体 idpair 8B(12110) / +48 模型覆盖名串 32B(15089) | 0x1419A4930 定案: 模型覆盖名 → 变体 +1072 |
| 15505 | CSetEquipmentVariantOverrideSpriteCommand | 0x142A24318 | 96 | +40 变体 idpair 8B(12110) / +48 覆盖块 48B(15506; +48 has u8 门, +52 u32, +56 串 32B, +88 qword; 门关整块不写) | 0x1419A4A80 定案: 覆盖块 → 变体 +1104..+1151 |
| 13225 | CSetObsoleteEquipmentVariantCommand | 0x142A24700 | 56 | +40 变体 idpair 8B(12110) / +48 obsolete u8(12396) | 0x1419A4BF0 定案: 变体 +1060 obsolete 开关 |
| 19882 | CSetWingEquipmentNicheCommand | 0x142A1DD40 | 72 | +40 机队 idpair 容器 {d@40, c@52} 元 8B(12213) / +64 生态位枚举 u32(19904) | 0x1419463C0 定案: 批量机队设装备生态位 |
| 13642 | CStratAirMoveEquipmentCommand | 0x142A1DA20 | 128 | +40 属国 tag u32(10394) / +44 源节点 idpair 8B(10639) / +52 目标节点 idpair 8B(10640) / +64 装备规格对象 64B(12110) | 0x141946950 定案: 战略空军 from→to 节点装备转移（同空域校验） |
| 13646 | CStratAirMoveEquipmentToReservesCommand | 0x142A1DAE8 | 120 | +40 属国 tag u32(10394) / +44 源机队 idpair 8B(12213) / +56 装备规格对象 64B(12110) | 0x141946A80 定案: 机队装备卸入国家储备（ps） |
| 13859 | NInternationalMarket::CMarketStockpileEquipmentTransferCommand | 0x142A3F9C0 | 176 | +40 转储备规格对象 64B(19776 to_reserve) / +104 解禁规格对象 64B(19775 to_release) / +168 操作国 tag u32(10754) | 0x141B1BF30 定案: 市场库存 to_reserve/to_release 双规格转移（"reserve"/"release" 池名记账） |
| 14010 | NInternationalMarket::COverrideMarketEquipmentPriceLevelsCommand | 0x142A3F820 | 64 | +40 操作国 tag u32(10754) / +48 价级覆盖表 16B(14150; +48 树头指针 + +56 尾随 qword 待裁; Clone 节点深拷 0x28) | 0x141B1B930 定案: 覆盖市场价级表 map<CIdentifier, 枚举 low=0/normal=1/high=2>（存档形 levels={id,type,low/normal/high}，serializer.cpp:362；键 = **CEquipmentVariant 自身 idpair 定案** — 全局 CIdentifier 注册表解析门 sub_14221F310 + InternationalMarket.SetPriceLevel 控制台反查 + ref.h:83 断言三证；语义资格另走 NMarketCore::IsTradable 谓词簇） |
| 16412 | CAddIndustrialOrgTraitToQueueCommand | 0x142967E68 | 72 | 同 14495: +40 属国 tag(10394) / +48 STraitId 16B(11918) / +64 MIO idpair 8B(11979) | 0x14199C760 定案: 特性入 MIO 队列（org+336 查重 = 不在队） |
| 16260 | CAttachPolicyToIndustrialOrgCommand | 0x142967DA0 | 56 | +40 属国 tag u32(10394) / +44 政策枚举 u32(10492) / +48 MIO idpair 8B(11979) | 0x14199C820 定案: MIO 换政策：sub_140DB50B0 换组 + 政治点扣费 |
| 16390 | CMoveIndustrialOrgTraitInQueueCommand | 0x142967FF8 | 80 | +40 属国 tag u32(10394) / +48 STraitId 16B(11918) / +64 MIO idpair 8B(11979) / +72 目标位次 u32(524) | 0x14199C9D0 定案: 队列内挪位（含 index 校验） |
| 16413 | CRemoveIndustrialOrgTraitFromQueueCommand | 0x142967F30 | 72 | 同 14495: +40 属国 tag(10394) / +48 STraitId 16B(11918) / +64 MIO idpair 8B(11979) | 0x14199CA10 定案: 特性出队 |
| 10625 | CSetAutoUpdateDesignsForIndustrialOrgCommand | 0x142968188 | 56 | +40 MIO idpair 8B(11979) / +48 开关 u8(13846 update_connections, 语义推定) | 0x14199CA50 定案: org+312 自动更新设计开关; IsValid 恒真 |
| 18740 | CSetIndustrialOrgTraitsInQueueCommand | 0x1429680C0 | 80 | +40 属国 tag u32(10394) / +48 STraitId 容器 {d@48, c@60} 元 16B(12278, 空表不写) / +72 MIO idpair 8B(11979) | 0x14199CE40 定案: STraitId 清单整表替换队列 |

#### 4.33.8 外交/阵营/和会域

> 横断事实：① 全 28 类五槽全覆写，无空桩 Execute；② **initiative（MemberStatus+72）扣款模式** `+= -cost`（sub_1424EF6F0 取负+钳 0）贯穿 rule/goal/program/doctrine/情报夺槽，代价为各自 .bss 全局；③ **fac+2104 CFactionUpgradeStatus 兼营情报顾问槽**（新发现）；④ 建阵会话链 = 逐成员造 COfferJoinFactionAction 包 CDiplomaticActionCommand post。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12242 | CCreateFactionCommand | 0x142995260 | sizeof 208; +40 发起国 tag u32(10394, 串→id) / +48 阵营名 SSO 32B(27, size@+64) / +80 图标串 SSO 32B(181, 可选门 +112) / +128 CColor 内嵌 48B(86, 值 16B@+144, 可选门 +160) / +176 模板 def 指针 8B(19482, 可选) / +184 成员 tag 扁平数组 {data@+184, count@+196}(10918) | 定案: 离旧阵 sub_14118BA30 → sub_140D91E00 建阵 → 逐成员造 COfferJoinFactionAction(0x88B) 包 CDiplomaticActionCommand post; IsValid = tag>0 + 名或模板非空 + 未入阵 (dip+656==0) |
| 14061 | CPromoteAutonomyCommand | 0x1429AB3F8 | sizeof 48; +40 目标附庸国 tag u32(10754) | 定案: dip+848 自治档提升（sub_14067A3F0），目标+宗主（dip+392）侧通知窗 12; IsValid = tag>0 + dip+848 非空 + 可提升门 |
| 14062 | CRemoveAutonomyCommand | 0x1429AB4C0 | sizeof 48; 同 14061 行: +40 tag u32(10754) | 定案: 剥夺版（sub_1406783A0），通知旗先算后写 |
| 19610 | NFactions::CSetFactionRuleCommand | 0x142A498C8 | sizeof 48; +40 规则 id u32(10876, def token 直存) / +44 发起成员国 tag u32(10302) | 定案: 扣 initiative → sub_140D8EC80 落 rule_status+telemetry；与 Erase 共享 IsValid/[22][23]; 门 = member+72 initiative ≥ qword_143332EF8 |
| 10494 | NFactions::CEraseFactionRuleCommand | 0x142A49990 | sizeof 48; 同 19610: +40 rule(10876) / +44 owner(10302) | 定案: 擦除版（sub_140D8AD60），无 telemetry |
| 13830 | CDonePeaceConferenceCommand | 0x142A84508 | sizeof 48; +40 谈判国 tag u32(12518) | 定案: Execute = sub_140E4A9B0 — 清 conf+456/+472 两树 → sub_140E45FB0 结束流程 (细目见 §4.10.31 分数链) |
| 12566 | CPassPeaceConferenceCommand | 0x142A84440 | sizeof 48; 同 13830: +40 negotiator tag u32(12518) | 定案: Execute 0x140E4AA00 = **thunk 直转 sub_140E45FB0 结束流程**（与 CDone 同函数；——dump 按 thunk 属性不导出函数头, 故缺件） |
| 12521 | CEndTurnPeaceConferenceCommand | 0x142A845D0 | sizeof 56; +40 谈判国 tag u32(12518) / +48 scoped\<CPeaceBiddingTurn\> 8B(12494, 竞标快照 0x40B, 断言 "_pPtr" pdx_scopedptr.h:119) | 定案: 竞标快照 scoped 落 conf+488 树 (= 谈判方回合 RB-tree, 节点 0x30B, key = 国 tag@节点+32, sub_140E46260), 结束该谈判方回合 |
| 15629 | CAmendIncomingLendLeaseActionCommand | 0x1429972B8 | sizeof 64; +40 接收国 tag u32(10394) / +44 外交行动引用 idpair 8B(10472, +296 门) / +56 新条款值对象指针 8B(14027, 0x168B, 可选) | 定案: incoming lend-lease 行动线性定位后整块覆写新条款值（14027 对象） |
| 10050 | CPrototypeRewardOptionCommand | 0x142A90730 | sizeof 56; +40 项目 idpair 8B(10022, +296 门) / +48 奖励组 id u32(10034) / +52 选项 id u32(10598) | 定案: 项目原型条目 624B 选项表选中 (sub_140FE0E00; 二级门 = 624B 项目条目表内 条目+8 == reward_group id 线性匹配) |
| 10144 | CResetUnreadPrototypeRewardsCounterCommand | 0x142A90988 | sizeof 48; +40 项目 idpair 8B(16392, +296 门) | 定案: 项目 +376 未读奖励计数清零+通知 |
| 19604 | NFactions::CAddFactionGoalCommand | 0x142A4A3B8 | sizeof 72; +40 发起成员国 tag u32(10302) / +48 目标 def 指针 8B(19592, def+8=token) / +56 被替换目标 def 指针 8B(10515, 可选) / +64 initiative 代价 i64 fixed(10323, ≤0=免费) | 定案: goal_status 换/加目标（sub_140A26840）+ initiative 扣款 |
| 12711 | NFactions::CAddFactionProgramCommand | 0x142A49F08 | sizeof 56; +40 项目 idpair 8B(16392, +296 门) / +48 发起成员国 tag u32(10302) | 定案: 项目入 fac+1992 program_status + 扣款 |
| 19760 | NFactions::CClearFactionTheater | 0x142A49BE8 | sizeof 56; +40 tag u32(10754) / +44 战区序号 u32(524) / +48 清除旗 u8(10737) | 定案: sub_1419503E0 删 fac+2552 指定 ping region; ctor sub_141BA6E30; AI 投递点 = 外交部长周更 sub_141A4AE30 (§4.34.10) |
| 19641 | NFactions::CCreateFactionTheater | 0x142A49B20 | sizeof 184; +40 tag u32(10754) / +48 名 SSO 32B(27, 可选门 +64) / +80 执行类型 u32(13994, 枚举串→值) / +84 指挥官 idpair 8B(11355, 可选门 +84∨+88) / +96 成员 tag 扁平数组 {count@+108}(11593) / +120 地区扁平数组 {count@+132}(12065, 可选) / +144 选择序数组 {count@+156}(12799, 可选) / +168 模板 def 指针 8B(19482, 可选) / +176 插入序 u32(524) | 定案: sub_141186FB0 建 theaters 168B 条目（名/型/指挥官/成员/地区/序/模板） |
| 10513 | NFactions::CFactionAttachScientistCommand | 0x142A4A098 | sizeof 64; +40 项目 idpair 8B(16392) / +48 政治力代价 i64 fixed(10323) / +56 科学家 idpair 8B(16389) | 定案: 挂科学家+扣政治力+MemberStatus+128 贡献增量 |
| 10509 | NFactions::CFactionSetCommanderCommand | 0x142A4A228 | sizeof 56; +40 战区序号 u32(524) / +44 新指挥官 idpair 8B(10423, 可选门 +44∨+48) / +52 发起成员国 tag u32(10302) | 定案: sub_141185F10 战区指挥官落位 |
| 10514 | NFactions::CFactionUnattachScientistCommand | 0x142A4A160 | sizeof 56; +40 科学家 idpair 8B(16389) / +48 项目 idpair 8B(16392) | 定案: 退贡献增量+sub_141443AF0 摘除 |
| 19761 | NFactions::CModifyFactionTheater | 0x142A49E40 | sizeof 176; +40 tag u32(10754) / +44 战区序号 u32(524) / +48 新名 SSO 32B(27, 可选) / +80 增成员数组 {count@+92}(11593) / +104 删成员数组 {count@+116}(19762) / +128 增 id 数组 {count@+140}(19759) / +152 删 id 数组 {count@+164}(19763) | 定案: 改名/增删成员/增删 id 四组写点 (ids 域与 countries 域同构: 0x14194FA30 增 / 0x141950FF0 删, 同 0xA8 per-country 条目 +72 u32 表) |
| 10248 | NFactions::CRemoveFactionProgramCommand | 0x142A49FD0 | sizeof 48; +40 项目 idpair 8B(16392) 单字段 | 定案: 从 fac+1992 移除项目（无退还） |
| 10563 | NFactions::CRemoveIntelligenceAdvisorFromSlotCommand | 0x142A4A548 | sizeof 48; +40 owner tag u32(10302) / +44 槽序号 u32(13378) | 定案: sub_1413FC040(fac+2104, slot, 0, 0) 清槽 |
| 10500 | NFactions::CUpdateIntelligenceAdvisorSlotCommand | 0x142A4A480 | sizeof 64; +40 owner tag u32(10302) / +48 顾问 def 指针 8B(10454, 可选; writer 写 *(def+24); reader 含国内清单比对+political_advisor 串名预检) / +56 槽序号 u32(13378) | 定案: 夺槽扣 initiative（100000×全局）→ 落槽+重算 |
| 12732 | NFactions::CSetFactionIconAndColor | 0x142A4A2F0 | sizeof 112; +40 owner tag u32(10302) / +48 图标 SSO 串(181) / +80 CColor 内嵌 48B(86, 值 16B@+96) | 定案: fac+1352 icon 串 + fac+2528 rgba 16B 直写（书互证） |
| 19754 | NFactions::CSetFactionPingExecutionType | 0x1429AC870 | sizeof 56; +40 战区序号 u32(524) / +44 tag u32(10754) / +48 执行类型 u32(13994, 枚举串↔值) | 定案: theaters[idx]+120 execution_type 直写（168 步长字节级实证） |
| 19765 | NFactions::CSetFactionTheaterPinVisibility | 0x142A49CB0 | sizeof 56; +40 tag u32(10754) / +44 战区序号 u32(524) / +48 显隐旗 u8(11562) | 定案: sub_141951600 pin 显隐写 |
| 10446 | NFactions::CSetFactionUpgradeCommand | 0x142A49A58 | sizeof 56; +40 升级 def 指针 8B(15356, 可选; 解析失败即发解析错) / +48 owner tag u32(10302) | 定案: upgrade def 虚槽[12] 应用升级（fac+248 传参待裁）; ctor sub_141BA7940; AI 投递点 = 外交部长周更 sub_141A4AE30 (§4.34.10) |
| 16755 | NFactions::CUnlockFolderDoctrineSharingCommand | 0x142A49D78 | sizeof 56; +40 tag u32(10754) / +48 文件夹 def 指针 8B(11873, 可选; 第二 GameItemDatabase qword_14332EEA0 解析) | 定案: fac+2224 登记文件夹共享+扣款 |
| 10449 | NFactions::CUseFactionMemberManpower | 0x1429AC938 | sizeof 48; +40 请求人力量 u32(776) / +44 请求国 tag u32(10302) | 定案: sub_140D897E0 从 fac+2288 人力池负扣交付请求国 (扣出人力以贡献条目追加请求国 cc+144 表 sub_140C67DB0 + 双刷新) |

#### 4.33.9 科研/基建域

> 横断事实：`*(国+3952)` = 军事部署输送带宿主（与 C2 互证）；`*(国+3976)` = 跨国建造许可容器；生产线链 线+32→ps→ps+656→国→国+8=tag；铁路炮 +1072/+1088 = 挂接组引用区；补给设置对象按 tag 有序映射，枢纽条目 232B。CSetResearchCommand Execute = 0x14115D2E0（1.19.3 未迁移，与 example 自动驾驶旧址同值复核）。

科研 9 类:

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12144 | CSetResearchCommand | 0x142994F40 | sizeof 48; +40 tag u32 / +44 tag ref 尾 / +48 tech 模板指针 8B / +56 槽号 i32 / +60 XP 旗 u8（详卡 §4.33.18） | 0x14115D2E0 定案: 科技槽挂/摘 tech（写点 sub_140EE3680） |
| 19568 | CUnlockResearchCommand | 0x142995008 | sizeof 64; +40 命令国 tag u32(10394) / +48 新 tech CTechnology* 8B(13259) / +56 原 focus tech 指针 8B(13260, +64 旗门) | 0x14115EC70 定案: 直接解锁 tech/切 focus（+学说夹清 AI 策略） |
| 13028 | CSetXORResearchCommand | 0x1429950D0 | sizeof 72; +40 命令国 tag u32(10394) / +48 新 tech 指针 8B(13259) / +56 旧 tech 指针 8B(13260) / +64 科研槽下标 u32(12145) / +68 经验加速旗 u8(15370, 可选) | 0x14115E670 定案: 新 tech 换旧 tech、进度折算 |
| 17327 | CRecruitScientistCommand | 0x142A90348 | sizeof 56; +40 科学家 idpair 8B(16389, def 引用) / +48 招募国 tag u32(10394) | 0x141EF3E10 定案: 招募科学家入池并扣款 |
| 16398 | CAttachScientistCommand | 0x142A90410 | sizeof 64; +40 设施/项目 idpair 8B(16392) / +48 首席旗 u8(10489, 仅真写) / +52 科学家 idpair 8B(16389) | 0x141EF3C80 定案: 科学家挂设施（首席旗） |
| 16399 | CUnattachScientistCommand | 0x142A904D8 | sizeof 56; +40 科学家 idpair 8B(16389) / +48 设施/项目 idpair 8B(16392) | 0x141EF4010 定案: 科学家摘离设施 |
| 10080 | CDismantleFacilityCommand | 0x142A907F8 | sizeof 48; +40 设施 idpair 8B(16392) 单字段 | 0x141EF3D00 定案: 启动设施拆除排程 |
| 10085 | CAbortDismantleFacilityCommand | 0x142A908C0 | sizeof 48; 同 10080: +40 设施 idpair 8B(16392)（共享读写体） | 0x141EF3C30 定案: 中止拆除并按比例退款 |
| 15782 | COrderDeleteChildFront | 0x142A0B390 | sizeof 64; +40 组 idpair 8B(63) / +48 orders 实例号 u32(13815) / +52 子前线组 idpair 8B(15781) | 0x141845F90 定案: 删 orders 前线子节 |

基建/铁路/补给 26 类:

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12151 | CAddConstructionCommand | 0x142994770 | sizeof 80; +40 tag / +48 CBuildingReference 内嵌 / +72 数量 / +76 插入枚举（详卡 §4.33.18） | 0x141150FB0 定案: 建筑营建入队（含跨国许可/共享建造对互链） |
| 13088 | CRemoveConstructionCommand | 0x142994838 | sizeof 56; +40 生产线 idpair 8B(12211, 建筑/军线通吃) / +48 撤销量 u32(417) | 0x1411591C0 定案: 生产线撤量/整线出队 |
| 13089 | CRemoveAllConstructionCommand | 0x142994900 | sizeof 64; +40 线 idpair 数组 {data@40, 容量@48, 计数@52, 分配器@56}(12211) | 0x141158AF0 定案: 清空营建队列（idpair 动态数组载荷, ×1.5 重分配） |
| 13604 | CRemoveBuildingLevelCommand | 0x1429949C8 | sizeof 56; +40 州内建筑 id u32(10319) / +44 州 id u32(439) / +48 拆在建旗 u8(13608) / +49 拆转换旗 u8(13609) | 0x141158E40 定案: 拆建筑级（在建/转换/即时三路） |
| 14005 | CReplaceBuildingCommand | 0x142994A90 | sizeof 176; +40 内嵌 CRemoveBuildingLevelCommand 56B(13604) / +96 内嵌 CAddConstructionCommand 80B(12151) | 0x141159B20 定案: 复合命令 = 内嵌 RemoveBuildingLevel+AddConstruction |
| 19705 | CBuildRailwayCommand | 0x142997510 | sizeof 80; +40 建造国 tag u32(10394) / +48 路径省数组 {容量@56, 计数@60} u32 元(10304, ≥2) / +72 目标铁路等级 u32(107) / +76 优先枚举 u8(141) | 0x141152AF0 定案: 铁路路径排营建（取全路径最小既有等级） |
| 19691 | CChangeRailwayConstructionLeveLCommand | 0x1429975D8 | sizeof 56; +40 铁路营建线 idpair 8B(12211) / +48 新等级值 u32(13802) | 0x141155A40 定案: 改铁路营建线等级 |
| 13479 | CCreateConveyorCommand | 0x142A483C0 | sizeof 56; +40 模板 idpair 8B(12610) / +48 role 枚举 u32(14279, 串→枚举) | 0x141BA3060 定案: 建军事部署输送带（宿主 = *(国+3952), sub_140D0F4F0） |
| 13493 | CCreateConveyorExtendedCommand | 0x142A48488 | sizeof 64; +40 模板 idpair 8B(12610) / +48 末线数量 u32(417) / +52 初始线数 u32(361) / +56 部署省 u32(10349) / +60 role 枚举(14279) | 0x141BA3100 定案: 建带+逐线 sub_140D0D970 增线+末线数量/位置; IsValid 加容量门 sub_140D0E740 + 省可达判 |
| 13484 | CAddConveyorLineCommand | 0x142A48A00 | sizeof 56; +40 输送带 idpair 8B(13492) / +48 插入线数 u32(417) | 0x141BA2D20 定案: 带内插线（容量门 sub_140D0E740） |
| 13483 | CSetConveyorSeriesCommand | 0x142A48938 | sizeof 56; +40 输送带 idpair 8B(13492) / +48 线数量 u32(417, ≥0 门) | 0x141BA3660 定案: 线数量直写（sub_140CEB400 = 训练条数入口） |
| 13480 | CSetConveyorNameCommand | 0x142A48550 | sizeof 80; +40 输送带 idpair 8B(13492) / +48 名串 SSO 16B 头(27, +64 容量) | 0x141BA3580 定案: 带改名; IsValid 串非空 |
| 13481 | CSetConveyorLocationCommand | 0x142A48618 | sizeof 56; +40 输送带 idpair 8B(13492) / +48 部署省 u32(10349) | 0x141BA3510 定案: 改部署省; IsValid 错误串出口 = 省界 [0,MaxNrProvinces) + 可达细检 |
| 13498 | CSetConveyorGroupCommand | 0x142A486E0 | sizeof 64; +40 输送带 idpair 8B(13492) / +48 命令组 idpair 8B(63) / +56 orders 实例号 u32(12342) | 0x141BA3450 定案: 带挂 orders 实例（RTDynamicCast→COrdersGroup） |
| 13482 | CSetConveyorPriorityCommand | 0x142A48870 | sizeof 56; +40 输送带 idpair 8B(13492) / +48 优先级 u32(141, ≤2 门) | 0x141BA35F0 定案: 带优先级（sub_140CEB480） |
| 14004 | CChangeConveyorPositionCommand | 0x142A48C58 | sizeof 56; +40 输送带 idpair 8B(13492) / +48 position 枚举 u32(76; 0=移至末尾 1=下移 2=上移 3=移至顶部) | 0x141BA2DE0 定案: 带移位（sub_140D13A70; 断言 militarydeploymentconveyorcommands.cpp:729） |
| 14003 | CCollapseConveyorCommand | 0x142A48B90 | sizeof 48; +40 输送带 idpair 8B(13492) | 0x141BA3010 定案: 带折叠态翻转 |
| 13601 | CRemoveConveyorCommand | 0x142A48D20 | sizeof 48; +40 输送带 idpair 8B(13492) | 0x141BA3320 定案: 删整带（sub_140D12E20） |
| 13487 | CRemoveConveyorLineCommand | 0x142A48F78 | sizeof 48; +40 带内线 idpair 8B(13491) | 0x141BA33A0 定案: 删带内线（sub_140D12FE0） |
| 19870 | CAssignRailwayGunToOrdersGroup | 0x142972960 | sizeof 72; +40 铁路炮 idpair 数组 {容量@48, 计数@52}(19732) / +64 目标命令组 idpair 8B(10397=COrdersGroup 引用) | 0x140E8EE90 定案: 铁路炮组挂接（数组载荷） |
| 19871 | CUnassignRailwayGunFromOrdersGroup | 0x142972A28 | sizeof 72; 同 19870 读写体（共享 [22]/[23]） | 0x140E8F1F0 定案: 铁路炮摘组（炮+1072/+1088==group+24 才摘） |
| 19872 | CRailwayGunManualOrderCommand | 0x142972AF0 | sizeof 72; +40 铁路炮 idpair 数组 {容量@48, 计数@52}(19732) / +64 目标省 u32(10304) | 0x140E8EF60 定案: 铁路炮改挂手动目标（省 id） |
| 19873 | CRailwayGunSetNameCommand | 0x142972BB8 | sizeof 80; +40 铁路炮 idpair 8B(19732) / +48 新名串(27) | 0x140E8F1A0 定案: 铁路炮改名（vtable+320 虚槽） |
| 19723 | CSetSupplyCapitalNodeCommand | 0x142997448 | sizeof 48; +40 命令国 tag u32(10394) / +44 新首都补给节点省 u32(10304) | 0x14115E1C0 定案: 设补给首都节点 |
| 19689 | CSetSupplyTruckBufferRatioCommand | 0x142995FA8 | sizeof 56; +40 命令国 tag u32(10754) / +48 卡车缓冲比 u64(694) | 0x14115E3A0 定案: 写卡车缓冲比; [9] 基座恒真（唯一） |
| 19701 | CUpdateSupplyNodeCountrySettingsCommand | 0x1429976A0 | sizeof 56; +40 目标国 tag u32(10754) / +44 disabled u8(14065, 可选 +45 在场旗) / +46 motorization_level u8(19943, 可选 +47 在场旗) / +48 节点省 id u32(11 列表首元素) / +52 列表第二元素 u32(语义待裁) | 0x14115F340 定案: 补给节点国别设置（disabled/摩托化等级；id 列表第二元素待裁） |

#### 4.33.10 谍报/行动域

> 横断事实：① **GetTypeId 值 = 命令名 token 同名同值**（本域 20/20 直证，如 create_operation_command=12118）——id 空间与命令名 token 空间同一；② 新挂载点：COperationManager = `*(cc+5544)`（+8 owner / +16,+28 实例表 / +88 优先级 / +1936 种子阶段）；agency+128 名(SSO) / +200,+208 升级槽 / +96,+108 已做清单 / +120 计时；op+288 属主 tag / op+4048 代号宿主 / op+4224 状态（3 可开除 / 4 外派）；fac+2104 间谍首脑槽表（424B 条目@+152，条目+8 tag）；CCountry+8 = 本国 tag（四证）。③ cc+3944 疑异经复核为类属之别：CCountry+3944 = 生产状态（s4_03 ✓，production.cpp:4628 断言佐证），特工 Leader+3944 = 国籍数组（s4_29 ✓），非冲突。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12118 | CCreateOperationCommand | 0x142978310 | sizeof 88; +40 auto_commence u8(19422) / +41 repeat u8(419) / +44 行动定义 id u32(11, dual 数值或串→hash) / +48 特工委派数组 24B {cap@+56, count@+60} 元 12B {idpair 8B(15635) + resume_mission u8(19473)} / +72 发起国 tag u32(10754) / +76 目标国 tag u32(107) / +80 目标省指针 8B(10304, reader 读 id 即解析, 断言 operativecommands.cpp:1709) | 定案: 发起国对目标国+省建行动实例（去重+种子阶段门+特工快照表逐槽落位; 纯引擎侧无 UI 尾缀） |
| 19010 | CLaunchOperationCommand | 0x1429784A0 | sizeof 56; +40 行动实例 CIdentifier 8B(11, inst+8/+12) / +48 所属国 tag u32(10754) | 定案: 按 idpair 找行动实例并启动（重跑启动门）+ owner/盟 UI 窗 4 |
| 19266 | CRecruitOperativeCommand | 0x142A2ED90 | sizeof 56; +40 招募国 tag u32(10394) / +44 待招募特工 CIdentifier 8B(15635, +296 门) | 定案: 特工入局（容量门 agency+228<+244；触发 on_operative_recruited 事件） |
| 15657 | CSetOperativeMissionCommand | 0x142A2EA70 | sizeof 104; +40 所属国 tag u32(10394) / +48 特工 idpair 数组 24B {cap@+56, count@+60}(15635) / +72 内嵌 COperativeMissionData 32B(11450; +80 mission kind u32 / +84 target tag i32 / +88 目标对象指针 / +96 副目标指针, **clone 双 8B 成对复制定案**) | 定案: 批量给特工落 COperativeMissionData 任务 + 战略特工重部署链 |
| 19119 | CBecomeSpyMasterCommand | 0x142A2E9A8 | sizeof 48; +40 竞选国 tag u32(10394) 单字段 | 定案: 竞得阵营 0 号槽间谍首脑 (升级数门 + DLC50 双通道扣费; 费率 = define `BECOME_SPYMASTER_PP_COST` 0x143335C90 + `FACTION_INTELLIGENCE_UNLOCK_COST` 0x1433357C8) |
| 14862 | CDeleteOperationCommand | 0x1429783D8 | sizeof 56; +40 行动实例 CIdentifier 8B(11) / +48 所属国 tag u32(10754) / +52 连装备退款旗 u8(12110, 未开工才允许) | 定案: 退款+删行动实例（召回外派特工/恢复任务） |
| 15637 | CDismissOperativeCommand | 0x142A2E2A0 | 2 | 定案: 开除特工（名册摘除+释放；op+4224==3 门） |
| 19128 | CIntelligenceAgencyCancelCreationCommand | 0x142A2E4F8 | sizeof 48; +40 建局中国 tag u32(10394) 单字段 | 定案: 撤销建局（清 agency+193 建局中旗+重置计时） |
| 15670 | CIntelligenceAgencyCreationCommand | 0x142A2E430 | sizeof 48; +40 建局国 tag u32(10394) 单字段 | 定案: 建情报机构 (未建 + 不在建 + 可用民工厂 ≥ define `AGENCY_CREATION_FACTORIES` 0x143335730) |
| 15679 | CIntelligenceAgencyUpgradeCommand | 0x142A2E5C0 | sizeof 56; +40 升级国 tag u32(10394) / +48 升级 def 指针 8B(15356, 读侧查库即解析, 断言 operativecommands.cpp:429; writer 写 *(def+8)) | 定案: 开始局升级（五重断言门+民工厂造价，def 挂 agency+208） |
| 19129 | CIntelligenceAgencyCancelUpgradeCommand | 0x142A2E688 | 2 | 定案: 撤销升级（agency+208 必须正是该 def；窗 4+20 双全局刷新） |
| 14861 | CReserveOperativeForOperationCommand | 0x142978248 | sizeof 80; +40 所属国 tag u32(10394) / +44 可选特工 12B {idpair 8B(15635) + resume_mission u8} / +56 槽号 i32(11879, −1 无效) / +60 行动实例 CIdentifier 8B(12059, 可选) / +68 目标国 tag u32(107, 可选) / +72 行动定义 id u32(11, dual, 配合 +68 定位) | 定案: 行动槽位派驻/撤空特工（idpair 或 def+目标双路定位实例；cc+1156 待裁） |
| 14859 | CSetCountryOperationsPriorityCommand | 0x14272DC50 | sizeof 48; +40 目标国 tag u32(10394) / +44 行动优先级 u32(141, 0..2) | 定案: 写 COperationManager+88 行动优先级（0..2），窗 14 |
| 15671 | CSetIntelligenceAgencyLogoCommand | 0x142A2E8E0 | sizeof 80; +40 所属国 tag u32(10394) / +48 徽标 SSO 串 32B(181, size@+64) | 定案: 写局徽标串 |
| 15672 | CSetIntelligenceAgencyNameCommand | 0x142A2E750 | sizeof 80; +40 所属国 tag u32(10394) / +48 局名 SSO 串 32B(27, size@+64) | 定案: 写局名（agency+128 SSO 串直证） |
| 15537 | CSetIntelligenceAgencyRandomHistoricalNameCommand | 0x142A2E818 | sizeof 48; +40 所属国 tag u32(10394) 单字段 | 定案: 从历史局名库按国随机取名（复用 Name setter） |
| 19020 | CSetOperationAutoCommenceCommand | 0x142978568 | sizeof 56; +40 行动实例 CIdentifier 8B(11) / +48 auto_commence u8(19422) / +52 所属国 tag u32(10754) | 定案: 写 inst+64 auto_commence |
| 19425 | CSetOperationAutoRepeatCommand | 0x142978630 | sizeof 56; 同 19020 构: +40 实例 idpair(11) / +48 repeat u8(419) / +52 所属国 tag u32(10754) | 定案: 写 inst+65 repeat（IsValid 门 inst+66 completed） |
| 14860 | CSetOperationTargetCommand | 0x1429786F8 | sizeof 56; +40 所属国 tag u32(10754) / +44 行动实例 CIdentifier 8B(11) / +52 新目标省 id u32(107 target, 0 合法清靶) | 定案: 换行动目标省（inst+96） |
| 15640 | CSetOperativeCodenameCommand | 0x142A2E368 | sizeof 88; +40 特工 CIdentifier 8B(15635) / +48 代号 SSO 串 32B(15639, size@+64) / +80 所属国 tag u32(10302) | 定案: 写特工代号 (op+4048 宿主; 属主/盟校验 op+288; 串非法判在 IsValid 0x141A2B8A0, 不在 Execute) |

#### 4.33.11 海军域（一）

> 横断事实：共享槽两组——[9]=0x141164440（count≠0 门）= DispatchNavalCombatResults/CancelActivity/CancelRefit/CancelRepair 四类；[22]/[23]=0x14135CB50/0x14135A6B0 = RemoveRegion/SetRegions。CTaskForce 字段横断与 gs 落点、60 余条域桩指纹已定位。待裁集中：sub_140C3AF20 舰旗位语义、入侵流水线常量 3、CTaskForce +524/+1232/Activity==2、qword_14332F698 海军/陆军 UI 并案。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12272 | CNavalMissionSetTypeCommand | 0x1429AF430 | sizeof 72; +40 navy idpair 数组 {cap@+48, count@+52, alloc@+56}(10398) / +64 任务类型 u32(11450, IsValid 上界 ≤9) / +68 stop_training_at_max_xp u8(19076) / +69 cancel u8(10469) | 定案: 一批特混舰队设海战任务类型（锚定 sub_140FBA460 / 在航 sub_140D77E60; 断言 navalcommands.cpp:1237/1253/1270） |
| 10261 | CNavalMissionSetTargetCommand | 0x1429B0EC0 | sizeof 88; +40 navy idpair 数组 {cap@+48, count@+52}(10398) / +64 目标舰型块数组 32B 元 {cap@+72, count@+76}(10256) | 定案: 整块覆写特混舰队 +1856 任务目标舰型清单 |
| 13092 | CMoveShipsCommand | 0x1429B2780 | sizeof 88; +40 ship idpair 数组 {cap@+48, count@+52}(10400 平铺) / +64 目标特混 idpair 8B(10398, 可缺省) / +72 落点舰队 idpair 8B(15156, 可缺省) / +80 目标基地省 u32(12790) / +84 move_order u8(10402) / +85 new_navy u8(13175) | 定案: 舰在特混舰队间移动/新建队/入港（断言 unitcommands.cpp:1481-1512; 改装中禁带目标队 refit 拆分专用路径; 四条 "#~ " 错误串门） |
| 12664 | CNavalMoveCommand | 0x1429AF8E0 | sizeof 72; +40 navy idpair 数组 {cap@+48, count@+52}(10398) / +64 目标省 u32(10349, IsValid >0 错误串门) / +68 access u8(10284) / +69 clear u8(10737) | 定案: 一批特混舰队向目标省移动（现路径栈求算 sub_141359780 → sub_140BF9A40 落路径） |
| 12661 | CAddNavalInvasionTargetCommand | 0x142A0C718 | sizeof 56; +40 订单组 idpair 8B(63) / +48 订单序 i32(12342, 文本标量通道) / +52 入侵目标省 u32(10304, 仅非零写) | 定案: 订单组第 idx 号入侵订单追加目标省并启动准备 (实例+112 = 目标省 u32 push 数组; 常量 3 = `ORDER_INVASION` 断言直证; +282 = 准备旗) |
| 15342 | CAddToOrRemoveShipFromNavalRepairQueue | 0x1429B03D0 | sizeof 64; +40 属国 tag u32(10754) / +44 基地省 id u32(12790) / +48 目标舰 idpair 8B(10400) / +56 add u8(13802; 1=入队 0=出队) | 定案: 舰入/出海军基地维修队列（异国出队走并国接收通道） |
| 18857 | CAssignAdmiralToNavyHeadquarter | 0x142A0D208 | sizeof 64; +40 海军 HQ 建筑 idpair 8B(10319) / +48 指派将领 idpair 8B(12354) | 高置信: 将领指派海军 HQ 建筑（引用重指换岗；指向细节推定） |
| 15344 | CChangeNavalBaseRepairPriorityCommand | 0x1429B0560 | sizeof 56; +40 基地省 id u32(12790) / +48 维修优先级 u32(141, 0..2) | 定案: 写基地维修优先级并重排队列 |
| 13150 | CDeleteShipCommand | 0x1429B2910 | sizeof 56; +40 待删舰 idpair 8B(10400) / +48 所在特混 idpair 8B(10398) | 定案: 删舰（荣誉舰先扣 PP 撤销；空队随之删除） |
| 15345 | CDisengageFromNavalCombatCommand | 0x1429B07B8 | sizeof 56; +40 海战 idpair 8B(10518) / +48 攻方侧旗 u8(10485) | 定案: 海战按攻/守侧脱离 |
| 13565 | CDispatchNavalCombatResultsCommand | 0x142993578 | sizeof 72; +40 海战结果数组 {cap@+48, count@+52}(13564 平铺键) / +64 收件国 tag u32(10754) | 定案: 一批海战结果按国发放 |
| 15625 | CMarkSunkShipInfoAsReadCommand | 0x1429B0A10 | sizeof 56; +40 舰 idpair 8B(10400) / +48 已读索引 i32(15624, ≥0 门) | 定案: 舰沉没信息已读索引落舰 +56 |
| 12274 | CNavalMissionAddRegionCommand | 0x1429AF5C0 | sizeof 56; +40 navy idpair 8B(10398) / +48 区域 id u32(10827) | 定案: 任务加一海区（上限 dword_1433369C8+防重复门 sub_140D53ED0+区域注册舰队+AI 通报） |
| 13353 | CNavalMissionMassMoveCommand | 0x1429AF818 | sizeof 88; +40 navy idpair 数组 {cap@+48, count@+52}(10398) / +64 指派省数组 {cap@+72, count@+76} u32 元(10349, 与 navy 等长) | 定案: 平行表批量设各队指派基地省（tf+888 落点; IsValid = 等长 + 逐队虚表[17] 入港门） |
| 12284 | CNavalMissionMoveCommand | 0x1429AF750 | sizeof 72; +40 navy idpair 数组 {count@+52}(10398) / +64 safe u8(11396) / +68 目标省 u32(10304) | 定案: 一批舰队向目标省开拔（tf+888 落点; 任务/预备队/海战全善后; IsValid 错误串 none of the navies were able to move） |
| 12275 | CNavalMissionRemoveRegionCommand | 0x1429AF688 | sizeof 72; +40 navy idpair 8B(10398) / +48 区域数组 {cap@+56, count@+60} u32 元(12065; count==0 不发射键) | 定案: 任务移除一批海区（含区域侧注销 sub_141006240 + 重算 + AI 通报） |
| 12273 | CNavalMissionSetRegionsCommand | 0x1429AF4F8 | sizeof 72; 同 12275 读写体: +40 navy idpair 8B(10398) / +48 区域数组 {cap@+56, count@+60}(12065) | 定案: 任务区域整表重设（无任务先挂默认 sub_141518450; 空表=清任务 sub_140D59520） |
| 15181 | CNavyCancelActivityCommand | 0x1429AF368 | sizeof 64; +40 特混数组 {cap@+48, count@+52}(10398) 单字段 | 定案: 一批舰队取消当前活动（改装需可中断、Reinforcing 跳过） |
| 15229 | CNavyCancelRefitCommand | 0x1429AF2A0 | sizeof 80; +40 特混数组 {cap@+48, count@+52}(10398) / +64 待拆舰数组 {cap@+72, count@+76}(12261) / +88 先并队旗 u8(13176) | 定案: 取消改装（可先拆舰成新队；尾部海军 UI 通知） |
| 13590 | CNavyCancelRepairCommand | 0x1429AEDF0 | 2 | 定案: 取消维修（Activity==1 门，清 +1124） |
| 15301 | CNavyClearAccidentReportsCommand | 0x1429AFFE8 | sizeof 56; +40 属国 tag u32(10394) / +44 区域 id u32(10827) | 定案: 清国×区域海难事故报告 |
| 15179 | CNavyDetachShipsAndMergeCommand | 0x1429AF110 | sizeof 64; +40 待并舰数组 {cap@+48, count@+52}(12261) / +64 合并目标特混 idpair 8B(10398) | 定案: 拆舰经新建队并入目标特混舰队（无舰队目标即 terminate） |
| 15230 | CNavyDetachShipsAndRefitCommand | 0x1429AF1D8 | sizeof 80; +40 待改装箱数组 {cap@+48, count@+52}(12261) / +64 源特混 idpair 8B(15157) / +72 改装型别 idpair 8B(14323) / +80 厂商 idpair 8B(19160, 可缺省) | 定案: 拆舰送改装 |

#### 4.33.12 海军域（二）

> 横断事实：**idpair 解析基准二分**——ship 族 = 裸指针/哨兵 0，navy·taskforce 族 = 对象+16/哨兵 16（Execute 用法自证）；reader default 分支四形态（家族默认 19 / 跳过 1 / FATAL 1 / 静默 2）。新锚：gs+736/+748、cc+352/+496/+4016（司令部数组）、sn+440、inflow+792/+888/+1200、tf+913/+916/+1260/+1268/+1544、海军基地 +40/+64。三条共享槽：Reorder/Switch 修理队列载荷同体、两个 SetMaxAllowedRepair 载荷同体、RepairNow/CarrierDefensiveStance 共 [9]。Execute 无一自调 IsValid（23/23）。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 13268 | CSetShipNameCommand | 0x1429B2848 | sizeof 80; +40 目标舰 CIdentifier 8B(10400, 裸指针族哨兵 0) / +48 新舰名串 32B(27) | 定案: 舰+1832→tf+472→cc+120 上下文写舰名块 ship+2072（ship.cpp:1641 deprecated 断言） |
| 15174 | CReorganizeShipsCommand | 0x1429B06F0 | sizeof 88; +40 命令国 tag u32(10394) / +48 特混身份容器 24B 元 128B(15157, CTaskForceIdentity 嵌套; 元内 optional 旗控字段 +32/+64/+68/+72/+76/+84) / +72 并入目标 idpair 8B(15476, 非空才写) / +80 清选中 u8(15633, true 不发射) | 定案: 按 CTaskForceIdentity(128B) 清单找/建特混、过滤本/盟舰排序搬移、可并入 to_merge、UI 选中联动 |
| 17596 | CRestructureShipsToTaskforceCompositions | 0x1429B0D30 | sizeof 72; +40 命令国 tag u32(10754) / +48 分组容器 24B 元 32B(15157; 元内嵌舰数组(12261) + 布局模板 id u32(17899)) | 定案: 按 ai_taskforce_composition 分组重编特混，composition 查库写 tf+1544 |
| 13583 | CNavyRepairNowCommand | 0x1429AEEB8 | sizeof 56; +40 特混 CIdentifier 8B(10398, 空哨兵 16) / +48 可选母港省 u32(10304, >0 才写) | 定案: 特混立即回港修：写点 tf+1208 detached_activity=1 / +1216 repair_target / +1264 旧任务 / +913 立即送修旗（无效省回退自寻, 断言 taskforce.cpp:5043）; IsValid = idpair 非空可解析 |
| 13599 | CNavyDetachShipsAndRepairCommand | 0x1429AED28 | sizeof 72; +40 舰清单 24B 容器 {data@+40, cap@+48, count@+52} 元 idpair 8B(12261, 仅非空发射键) / +64 所属特混 CIdentifier 8B(10398) | 定案: 从特混摘指定舰送修（全舰数命中 → 整队走 RepairNow 株; 否则 sub_140D77900 拆分送修） |
| 13581 | CNavyRepairModeCommand | 0x1429AEF80 | sizeof 80; +40 特混清单 24B 容器 {cap@+48, count@+52} 元 idpair 8B(15157 平铺) / +64 有键旗 u8 / +68 repair_mode u32(12504 → tf+1124) / +72 有键旗 u8 / +73 repair_split u8(10911 → tf+1268) / +74 cancel_repairs u8(15512, 真才发射兼有键旗) | 定案: 批量设 repair_mode/repair_split/取消在修（跳过 repair_parent 已设者; IsValid = 无 mode 键须带 cancel / mode ∈ 0..3∪{5}） |
| 16467 | CNavySetUnderwayReplenishmentCommand | 0x1429AF048 | sizeof 72; +40 特混清单 24B 容器 {cap@+48, count@+52} 元 idpair 8B(15157 平铺) / +64 开关 u8(16427, 恒写) | 定案: 批量开 underway_replenishment(tf+1128) 并拨 convoy（开 = sub_141021F90 拨 128/特混定额, 关 = sub_141022A70 清） |
| 18856 | CRemoveAdmiralFromNavyHeadquarter | 0x142A0D2D0 | sizeof 48; +40 海军上将 CIdentifier 8B(12354, handle=对象+16) 单字段 | 定案: 摘上将任职：cc+4016 司令部数组槽匹配 admiral+3912 |
| 12660 | CRemoveNavalInvasionTargetCommand | 0x142A0C650 | sizeof 56; +40 订单组 CIdentifier 8B(63) / +48 命令实例下标 i32(12342) / +52 入侵目标省 u32(10304, 非零才写) | 定案: 订单组命令实例入侵目标省表移除 |
| 15339 | CReorderNavalRepairQueue | 0x1429B0308 | sizeof 64; +40 基地/州 id u32(12790) / +44 目标舰 CIdentifier 8B(10400) / +52 新队列位次 u32(12146) / +56 插自己舰间变体 u8(15343, 真才写) | 定案: 海军基地修理队列按 new_priority 重排 |
| 15160 | CReorderNavyTheaterGroupCommand | 0x142A32AB8 | sizeof 56; +40 订战区组 CIdentifier 8B(13777) / +48 位移量 u32(13778, 可负) | 定案: 订战区组在父战区内按位移重排（三 FATAL 断言锚） |
| 10227 | CSetCarrierDefensiveStance | 0x1429B0C68 | sizeof 56; +40 特混 CIdentifier 8B(15157, handle=tf+16) / +48 出击效率 u32(12970) | 定案: 写 tf+1260 sortie_efficiency |
| 13713 | CSetCarrierStickyMissionAreaCommand | 0x142A1E060 | sizeof 56; +40 任务对象 CIdentifier 8B(12214, 运行时表名义 air_base, handle=对象+16) / +48 粘滞旗 u8(13714, 恒写) | 定案: 目标 = **CAirBase**，写点真身 = CAirBase+128 byte（序列化键 13714）; c8b「对象+144」推定证伪 |
| 15337 | CSetMaxAllowedRepairDockyards | 0x1429B0178 | sizeof 48; +40 命令国 tag u32(10394) / +44 船坞上限 u32(键 12, 运行时无名键) | 定案: 战略海军 +440 = 船坞修理上限 |
| 10104 | CSetMaxAllowedRepairFactoriesCommand | 0x1429B0240 | sizeof 48; 同 15337: +40 tag(10394) / +44 上限 u32(键 12) | 定案: inflow+1200 = 工厂修理上限; IsValid 值 ≤ 民工厂总数 (ps+888/1e5) |
| 15435 | CSetNavalBaseDisabledForRepairsStateCommand | 0x1429B0628 | sizeof 56; +40 基地/州 id u32(12790) / +44 目标国 tag u32(10754) / +48 禁修旗 u8(15434, 恒写) | 定案: 基地 +64 区 per-country 禁修开关 |
| 14858 | CSetNavalRegionAccessCommand | 0x1429AFA70 | sizeof 80; +40 命令国 tag u32(10394) / +48 区域 id 容器 24B 元 u32(12065) / +72 通行权值 i8(10284, 恒写) / +73 全区旗 u8(10737, 真才写) | 定案: 国家海军区域通行权 |
| 13357 | CSetNavyEngagementCommand | 0x1429B29D8 | sizeof 72; +40 特混容器 24B{data@40,cap@48,count@52} 元 idpair 8B(10398) / +64 交战规则值 u32(13358, 恒写) | 定案: 批量写 tf+916 交战规则（任务类型 2 时下限 1）并清 tf+913 |
| 15161 | CSetNavyTheaterGroupForCommand | 0x142A32B80 | sizeof 104; +40 命令国 tag u32(10394) / +44 新建组旗 u8(15162, 真才写) / +48 目标组 CIdentifier 8B(13777, 非空才写) / +56 舰队容器 24B(15156 平铺) / +80 特混容器 24B(15157 平铺) | 定案: 舰队/特混挂订战区组（可新建组；混源时移挂国家海军对象） |
| 15576 | CSetNavyTheaterGroupImportantCommand | 0x142A32D10 | sizeof 56; +40 目标组 CIdentifier 8B(13777, 非空才写) / +48 重要旗 u8(15575, 真才写) | 高置信: 写组对象 +104 is_important |
| 15164 | CSetNavyTheaterGroupNameCommand | 0x142A32C48 | sizeof 80; +40 目标组 CIdentifier 8B(13777, 非空才写) / +48 组名串 32B(27) | 定案: 写组名（组 +56 串） |
| 15340 | CSwitchNavalRepairDockyard | 0x1429B0498 | sizeof 64; 载荷同 15339（共享 [22]/[23]）: +40 基地 id(12790) / +44 舰 CIdentifier(10400) / +52 位次(12146) / +56 变体旗(15343) | 定案: 单舰/整队换修船母港（sub_140D731A0 重发 + refit 附属随迁）+ 重排队列 |
| 17685 | CUpgradeShipCaptainCommand | 0x142997A88 | sizeof 48; +40 目标舰 CIdentifier 8B(10400, 裸指针族) 单字段 | 定案: 舰长升级：cc+496 海军经验扣费（affordability 门）+ sub_141451580 执行（补足书 GUI 行两环） |
| 13176 | CMergeNaviesCommand | 0x1429B2B68 | sizeof 72; +40 源特混 idpair 数组 {cap@+48, count@+52}(10398) / +64 merge_to_first u8(15475) | 定案: 合并舰队（可并入第一支; 载荷缓冲区断言样板） |
| 15158 | CCreateFleetCommand | 0x1429AFB38 | sizeof 144; +40 country tag u32(10394, 串→tag) / +44 theater_group CIdentifier 8B(13777) / +56 task_force idpair 数组 24B(15157) / +80 ship idpair 数组 24B(10400) / +104 province_id u32(11087) / +108 orders u32(12119) / +112 region u32 数组(10827, push 式) / +136 mission u32(11450) / +140 u32 = **`home_base`** (键 10241) | 定案: 创建舰队（舰船/区域/任务/编队/战区组全套参数一次建齐） |
| 15165 | CSetFleetCommand | 0x1429AFCC8 | sizeof 72; +40 fleet CIdentifier 8B(15156) / +48 task_force idpair 数组 {cap@+56, count@+60}(15157) | 定案: 把特混舰队挂到舰队（拒绝挂到预备舰队 "Refusing to assign task forces to a reserve fleet"） |
| 15172 | CSetAsReserveFleetCommand | 0x1429B00B0 | sizeof 112; +40 fleet CIdentifier 8B(15156) / +48 task_force idpair 数组(15157) / +72 ship idpair 数组(10400) / +96 theater_group CIdentifier 8B(13777) / +104 u8 = **`preserve_reinforce_requirements`** (键 15528); reader 对 12790 naval_base 只校验类型不落盘 (legacy 键) | 定案: 把特混舰队设为预备舰队（可带编队组） |
| 16738 | CSetFleetHomeBaseCommand | 0x1429AFD90 | sizeof 56; +40 fleet CIdentifier 8B(15156) / +48 naval_base 省 u32(12790) / +52 move u8 bool(333) | 定案: 设置舰队母港（可带搬迁旗; "Invalid fleet" 半语义佐证） |

#### 4.33.13 空军/订单域

> 横断事实：**联队 idpair 解析 holder 约定（高置信，四路独立锚互证）**——air 系命令 resolve 后一律 −16 得 holder；书 §4.15.4「CAirWing」基址 = holder+16，CAirMission m = holder+144，影响全书 air 命令族读法。CAirMission 新字段：m+8 日夜旗 u8 / m+12 运行时激进度 u32（ctor 置 0，不序列化）。⚠ 基点澄清（活体实测 1.19.3）：本节「resolve」直接返回池元素+16 的 CAirWing 对象（即 §4.15.3 holder+16），air 命令写点一律以该对象为基（如 12246 写 resolve+152）；「resolve−16 得 holder」中的 holder = 池元素本体，勿与 §4.15.3 holder 混名。air 系 reader 默认分支二分（sub_1424C2060 vs sub_1424BEC40）。域勘误确认：CReplaceAdvisor/CReplaceIdea 虽编在空军簇，Execute 落点全在顾问槽/民族精神管理（政治域）。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12778 | CAssignAceCommand | 0x142996138 | sizeof 56; +40 王牌 idpair 8B(12770, 可缺省) / +48 联队 idpair 8B(12213) | 定案: 设/清联队王牌（ace+air_wing idpair → sub_140F5B320；KIA ace+344 拒绝 ACE_PILOT_CANT_ASSIGN_KIA） |
| 14868 | CChangeAirGroupInsigniaCommand | 0x142A1E9C0 | sizeof 96; +40 集团 idpair 8B(12227) / +48 CColor 内嵌 16B(86, 嵌套读写) / +80 图标索引 u32(181, >0 门) | 定案: 改空军集团图标索引+颜色（写 resolve+32 / resolve+64） |
| 13651 | CDeleteAirWingCommand | 0x142A1DF98 | sizeof 72; +40 联队 idpair 数组 {cap@+48, count@+52}(13161 平铺重复键) / +64 属主 tag u32(10394) | 定案: 删联队：剧场注销（断言 strategicaircommands.cpp:1275）→装备归还生产状态(cc+3944)→清王牌→池摘除; IsValid = 数组非空 + 末条属主同国或同盟 |
| 14864 | CMoveAirGroupAndAirTheatreToFreeCommand | 0x142A1E5D8 | sizeof 120; +40 属主国 tag u32(10394) / +48 联队 idpair 数组 {cap@56,count@60}(13161) / +72 集团 idpair 数组 {cap@80,count@84}(12227) / +96 剧场 idpair 8B(19949) | 定案: 集团/联队连同剧场退回 free 池 |
| 14863 | CMoveAirWingAndAirGroupToAirTheatreCommand | 0x142A1E510 | sizeof 104; 载荷同 14864（共享 [22]/[23]）: +40 tag(10394) / +48 联队数组(13161) / +72 集团数组(12227) / +96 剧场 idpair(19949) | 定案: 联队+集团迁入目标空军剧场（防自迁断言 :1877） |
| 14865 | CMoveAirWingToAirGroupCommand | 0x142A1E6A0 | sizeof 96; +40 属主国 tag u32(10394) / +48 联队 idpair 数组 {cap@56,count@60}(13161) / +72 目标集团 idpair 8B(12227) | 定案: 联队出原剧场后划入目标集团 |
| 13099 | COrderMembersFairSplitCommand | 0x142A0C268 | sizeof 72; +40 源订单组 idpair 8B(13113) / +48 目标订单组 idpair 8B(13114) / +56 源组订单序号 u32(13115) / +60 目标组订单序号 u32(13116) | 定案: 两 COrdersGroup 各取一订单做成员省均分 |
| 13580 | COrderReplaceFallbackCommands | 0x142A0BB60 | sizeof 88; +40 部队 idpair 8B(63) / +48 单位 idpair 数组 {cap@56,count@60}(10403 平铺) / +72 路径省数组 24B(372) | 定案: 排空部队两份挂起清单后按单位+path 省表重落 fallback 订单 |
| 13578 | COrderReplaceRootCommands | 0x142A0BDB8 | sizeof 112; +40 部队 idpair 8B(63) / +48 单位数组 {cap@56,count@60}(10403) / +72 前线 idpair 8B(10720, +296 门) / +80 分节 u32(13093) / +88 比例下限 i64(10639) / +96 比例上限 i64(10640) / +104 子分节管理旗 u8(15783) | 定案: 部队单位清单改挂前线 root 订单 |
| 12729 | COrderSetParadropSourceCommand | 0x142A0CA38 | sizeof 80; +40 部队 idpair 8B(63, +296 门) / +48 订单序号 i32(12342) / +52 空投源省 u32(10304, 仅非零写) / +56 划入单位数组 {cap@64,count@68}(10403) | 定案: 设空降源：新建 4 型订单实例挂接+单位划入+管线刷新 |
| 12730 | COrderSetParadropTargetCommand | 0x142A0CB00 | sizeof 64; +40 部队 idpair 8B(63, +296 门) / +48 订单序号 i32(12342) / +52 空投目标省 u32(10304, 仅非零写) | 定案: 订单写空投目标省 + sub_141029490(inst,4) 准备流水线 |
| 14867 | CRenameAirGroupCommand | 0x142A1E8F8 | sizeof 80; +40 集团 idpair 8B(12227) / +48 新名 SSO 32B(27, size@+64, cap@+72) | 定案: 改空军集团名 |
| 14866 | CRenameAirTheatreCommand | 0x142A1E830 | sizeof 80; +40 剧场 idpair 8B(19949) / +48 新名 SSO 32B(27) | 定案: 改空军剧场名 |
| 14869 | CReorderAirTheatersCommand | 0x142A1E768 | sizeof 56; +40 剧场 idpair 8B(19949) / +48 新位次 u32(76) | 定案: 剧场在国 cc+384 指针表内摘除后按 position 重插 |
| 19563 | CReplaceAdvisorCommand | 0x142995968 | sizeof 96; +40 旧顾问 idpair 8B(19565) / +48 新顾问 idpair 8B(19566) / +56 cost u8(10323) / +64 槽名串 SSO(13378) | 定案（政治域）: 顾问解雇-雇佣; IsValid = 双 idpair 解析存活 + 属主同国或同盟 (sub_140BB52F0) + 新槽可上任/旧可离任 |
| 13017 | CReplaceIdeaCommand | 0x1429958A0 | sizeof 72; +40 tag(10394) / +48 旧 idea 对象指针 8B(13102; id=*(idea+8)) / +56 新 idea 对象指针 8B(13082) / +64 cost u8(10323) | 定案（政治域）: 民族精神换装（主写点 sub_140BAF050，PP 退旧购新）; IsValid = 两 idea+56 可用旗 + 同槽 (+2720) + 持旧缺新 + 费用 PP 门 + 三道换装合法性 |
| 14312 | CSetAirWingNameCommand | 0x142A1E128 | sizeof 80; +40 联队 idpair 8B(13161, +296 门) / +48 新名 SSO 32B(27) | 定案: 改联队名（sub_140F67130 → wing+2440，与书 GUI 闭环互证） |
| 12235 | CStratAirCancelTransferCommand | 0x142A1D7C8 | sizeof 56; +40 联队 idpair 8B(12213) / +48 is_ai u8(13179) | 定案: 取消转场（holder+120=1、清任务 m、停 wing+2576 timed_disabling; 非 AI 先脱挂陆军）; IsValid = 可解析 ≠16 + 未曾取消门 sub_140F5CAD0 |
| 13637 | CStratAirChangeAggressivnessCommand | 0x142A1DC78 | sizeof 56; +40 联队 idpair 8B(12213) / +48 激进度档 u32(11922) | 写点定案: 写 CAirMission m+12 运行时激进度（与序列化档 m+28 并存，关系待裁）; IsValid 共享桩可解析 |
| 12234 | CStratAirConsolidateCommand | 0x142A1D958 | sizeof 64; +40 联队 idpair 数组 {cap@+48, count@+52}(12213) | 定案: 合并联队（断言 strategicaircommands.cpp:770）; 被并翼**直调 CDeleteAirWing 的 IsValid/Execute** 走删除通道 |
| 12246 | CStratAirDayNightCommand | 0x142A1DBB0 | sizeof 56; +40 联队 idpair 8B(12213) / +48 日夜值 u32 按字节写(124) | 定案: 写 resolve+152 = CAirWing 对象+152（活体双向实测 1↔0 精确落位; 按横断 m 基即 m+8, 不序列化）; IsValid 共享桩 |
| 12222 | CStratAirEnableMissionCommand | 0x142A1D570 | sizeof 96; +40 联队 idpair 数组 {cap@+48, count@+52}(12213) / +64 任务定义件 idpair 数组 {cap@+72, count@+76}(11450, 按位并行) / +88 战略区域 u32(12014) / +92 is_ai u8(13179) | 定案（定义件型推定）: 按任务定义件（掩码@+160/周期@+168）对 18 任务位逐位启停+设战略区域; IsValid 分路 = wing+28 allow_mission_type 0x20 直拒 / 0x10000 需 DLC(48) / 0x20000 需 DLC(47) / 余走区域校验链 |
| 12221 | CStratAirSetMissionCommand | 0x142A1D638 | sizeof 72; +40 联队 idpair 数组 {cap@+48, count@+52, alloc@+56}(15270 array) / +64 任务类型位掩码 u32(225; 2048=MISSION_TRAINING) / +68 enable u8(10376) / +69 clear u8(10737) / +70 stop_training_at_max_xp u8(19076) | 定案: 设任务类型位掩码/enable/clear/停训旗（airmission.cpp:410）; IsValid = 数组非空 + type≤0 须带 clear + enable 时 type∧wing+32 equipment_mission_types 非零（装备不会飞则拒）+ 转场挂链检查 |
| 12231 | CStratAirSplitCommand | 0x142A1D890 | sizeof 56; +40 被拆联队 idpair 8B(12213) / +48 拆出机数 u32(12174) | 定案: 按 split_amount 拆出新联队（malloc 0xA38，新 id {69,++计数}）; IsValid = wing+108 机数 > split_amount > 0 |
| 12230 | CStratAirTransferCommand | 0x142A1D700 | sizeof 72; +40 源联队 idpair 8B(12213, 直写无门) / +48 目标基地 idpair 8B(12214) / +56 transfer_to_warehouse u8(13206) / +57 is_ai u8(13179) / +60 战略区域 u32(12014) / +64 任务类型 u32(11450) | 定案: 转场至 air_base/入库；跨型整翼转/超员自动拆翼；sub_140F67AB0 落 transferring_to 等四字段（断言 strategicaircommands.cpp:560）; IsValid = 非展开中 (wing+84≥wing+80) + 基地校验 + 转场中目标须异 |

#### 4.33.14 角色/政治域

> 横断事实（公共新锚）：character idpair 解析 = 对象+16/哨兵 16（IsValid `!=16` + Execute 显式 −16 双证）；CCountry 子对象 +3984 ideas / +4000 决策 / +4080 人事 / +4992 国策进度 / +5360 决议忽略集（40B 键，FNV 小写）；CCharacter +3688 XP(1e-5) / +3708 晋升旗 / +3788/+3792 已见计数；gs+248 角色 160B 花名册；gs+1624 控制组表（24B×(index+10×国序数)）；STargetedDecisionTarget 48B。GetTypeId=命令 token 28/28 同名。28/28 real，无空桩。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 13245 | CSetNationalFocusCommand | 0x142996458 | sizeof 56; +40 目标国 tag u32(10394) / +48 国策焦点对象指针 8B(13239, 株 A 按名解析)（详卡 §4.33.18） | 定案: 开启国策（country.cpp:13030 断言写点） |
| 14250 | CBypassNationalFocusCommand | 0x1429965E8 | sizeof 56; 同 13245 读写体: +40 tag(10394) / +48 focus 指针 8B(13239) | 定案: 跨越国策；bypass 旁支组互斥门 |
| 14257 | CDropCurrentNationalFocusCommand | 0x142996520 | sizeof 48; +40 目标国 tag u32(10394) 单字段（与 14050 共享读写体） | 定案: 放弃当前国策（焦点 +1469 可放弃旗门） |
| 14048 | CSetContinuousFocusCommand | 0x1429966B0 | sizeof 56; +40 tag(10394) / +48 连续焦点对象指针 8B(13239) | 定案: 设连续焦点（palette+冷却门; IsValid = 焦点+8 调色板==cc+4984 + 焦点+868/cc+3976→+736/全局旗 + 冷却 progress+76 + 焦点+216/+304 触发槽[3]） |
| 14050 | CDropContinuousFocusCommand | 0x142996778 | sizeof 48; +40 tag(10394)（与 14257 共享读写体） | 定案: 清连续焦点（同写点传 0）; IsValid = progress+24 在挂 + tag>0 |
| 12303 | CAddIdeaCommand | 0x142995328 | sizeof 64; +40 tag(10394) / +48 idea 槽对象指针 8B(10491) / +56 cost u8(10323) | 定案: 加精神：sub_140BAF050 + 全套刷新 + 精神 AI 三槽清零; IsValid = tag>0 + idea+56 有效旗 + 未挂载 + 费用可付 + 槽级三连检 |
| 12304 | CRemoveIdeaCommand | 0x142995648 | sizeof 64; 同 CAddIdea 读写体: +40 tag(10394) / +48 idea 指针 8B(10491) / +56 cost u8(10323) | 定案: 删精神（含退款路径 sub_140BA9410）; IsValid 要求 idea 已挂载（与加方向成对） |
| 19564 | CAddAdvisorCommand | 0x142995580 | sizeof 88; +40 character idpair 8B(19478) / +48 cost u8(10323) / +56 槽名串 32B(13378) | 定案: 雇顾问：槽解析→付旧任命费+新费用→sub_1410E9E60; IsValid = idpair 解析(≠0,≠16) + 存活 + 槽解析非空 + 可雇检查 sub_1410EA0C0 |
| 19567 | CRemoveAdvisorCommand | 0x142995710 | sizeof 80; +40 character idpair 8B(19478) / +48 槽名串 32B(13378) | 定案: 解雇顾问 sub_1410EB8C0; IsValid = 存活 + 槽解析 + 可解雇 sub_1410EA560 |
| 19586 | CGenerateAdvisorCommand | 0x1429954B8 | sizeof 152; +40 目标国 tag u32(10754) / +48 槽类型串 32B(19588, +64 串长 IsValid 消费) / +80 生成规格块 72B(240, 多态 Parse, 内部待裁) | 定案: 按规格块生成顾问 sub_1410EA930 |
| 19603 | CAddAdvisorRoleToCharacterCommand | 0x1429953F0 | sizeof 152; +40 角色 idpair 8B(19478) / +48 授予国 tag u32(10754) / +56 规格块 96B(240; +16 串指针/+28 dword/+64 区/+80 指针, 整体待裁) | 定案: 角色挂顾问角色 sub_1410E91A0 + 名单重挂 (载荷 +56 规格块 96B = token 240 `data` 多态块) |
| 10047 | COnRulingPartyChangeActionCommand | 0x14272DEA8 | sizeof 48; +40 目标国 tag u32(10754) / +44 旧意识形态 token u32(19015; 19479=undefined 哨兵) | 定案: 设 temp_var:old_ideology_token（×1e5）后触发 on_ruling_party_change 事件 |
| 14345 | CSelectDecisionCommand | 0x142996908 | sizeof 56; +40 tag(10394) / +48 decision 对象指针 8B(11142; u32 id 往返 sub_14072B2C0/14072B8A0) | 定案: 激活决议（普通/目标化分派 sub_1407357F0/sub_140735BE0）+ 决议日志; IsValid = 可见 + 未激活 + 可用/有目标分派 |
| 14383 | CSelectTargetedDecisionCommand | 0x1429969D0 | sizeof 72; +40 tag(10394) / +44 目标国 tag(107) / +48 目标州 u32(14965) / +56 decision 指针 8B(11142) | 定案: 采纳目标化决议 sub_140735910；IsValid 7 条错误串出口（未激活/invalid tag/invalid target/不可用/已采纳/不可采/已标删） |
| 14768 | CIgnoreDecisionCommand | 0x142996C28 | sizeof 80; +40 tag(10394) / +48 名串数组容器 24B{data@+48, count@+60} 元素 32B 串(11142) / +72 ignore u8(11736) | 定案: 按名清单加/删 cc+5360 忽略集（40B 键 FNV-1a 小写归一 hash@+32）; IsValid = 逐名可解析且条目+280 非零 |
| 14769 | CIgnoreTargetedDecisionCommand | 0x142996D40 | sizeof 80; +40 决策国 tag u32(10394) / +48 目标清单容器 24B{data@48,cap@56,count@60} 元 48B(15733; 元=vt@0/+8,+12 目标对/+16..47 决议名串) / +72 ignore u8(11736) | 定案: 目标化决议活跃实例 +44 写忽略旗 |
| 19412 | CIgnoreAllAvailableDecisionCommand | 0x142996E08 | sizeof 48; +40 决策国 tag u32(10394, 推定) 单字段 | 定案: 全量忽略：目标化进忽略集 + 普通决议 +44 旗 |
| 10285 | CSelectionGroupCommand | 0x142996F98 | sizeof 80; +40 所属国 tag u32(10754) / +48 SControlGroupData 容器 24B{data@48,cap@56,count@60} 元 32B(63) / +72 控制组槽号 u32(524, 0..9) | 定案: 存编队控制组：gs+1624 表重建 + "SHORTCUT_SAVED" 音效 |
| 13107 | CCreateUnitLeaderCommand | 0x1429962C8 | sizeof 48; +40 tag(10394) / +44 type u32(225; 0=陆军元帅 1=陆军上将 2=海军上将, reader 收 ≤3 而 IsValid 拒 3) | 定案: 花费扣账后生成将领（sub_1406F1950 取费→sub_1406CFE60 扣账; 四维随机+军衔扣 XP; IsValid = type∈{0,1,2} + tag>0 + 费用可付 sub_1406DD670） |
| 13104 | CPromoteToCountryLeaderCommand | 0x14295E4F8 | sizeof 48; +40 花名册角色 u32(22 machineid 键, sub_1401C9CD0 线性查 gs+248) | 定案: gs+248 花名册条目 +148 bit0 立为国家领导人 |
| 13306 | CPromoteUnitLeaderCommand | 0x1429B2C30 | sizeof 48; +40 将领 idpair 8B(10423, 带门读) 单字段 | 定案: character+3708==1 时 sub_140C202C0 晋升 + UI 通知向量 |
| 19624 | CRetireCharacterCommand | 0x1429957D8 | sizeof 48; +40 角色 idpair 8B(19478, 带门读) 单字段 | 定案: sub_1410EE3F0 退役 + 刷新级联 |
| 15871 | CGiveMedalCommand | 0x142997B50 | sizeof 72; +40 将领 idpair 8B(10397, 可缺省) / +48 舰支 idpair 8B(10400, 可缺省) / +56 勋章条目指针 8B(15870, 按名解析) / +64 颁授国 tag u32(10394) / +68 勋位序号 u32(10293) | 定案: 双路径授勋：将领（+1576 清单）/舰支（+2264），国库价目门 |
| 12370 | CSetFleetLeaderCommand | 0x142A0C4C0 | sizeof 56; +40 新司令 idpair 8B(10423, 空对不写键) / +48 目标舰队 idpair 8B(15156, 必填) | 定案: 任命舰队司令 sub_140D5A170（旧司令摘除+CReferenceObject 挂接） |
| 16842 | CSetOrderGroupLeaderProximityCommand | 0x142A0AA30 | sizeof 56; +40 订单组 idpair 8B(63) / +48 近接档位 u32(225 type) | 定案: 订单组 +428 近接档位写入并向子组树传播 |
| 14918 | CUpdateLeaderSeenTraitsCountCommand | 0x142A0CE20 | sizeof 56; +40 将领 idpair 8B(10423, 带门读) / +48 已见特质数 u32(10730) | 定案: 解析值 +3788 = count 直写 |
| 19926 | CUpdateLeaderSeenAdvisorRolesCountCommand | 0x142A0CEE8 | sizeof 56; 同 14918 读写体: +40 将领 idpair 8B(10423) / +48 已见顾问角色数 u32(10730) | 定案: 解析值 +3792 = count 直写（wire 级同体） |
| 15341 | CRequestExpeditionariesCommand | 0x142996A98 | sizeof 80; +40 宗主国 tag u32(10394) / +48 目标清单容器 24B{data@48,cap@56,count@60} 元 8B{目标国 tag u32 + 旗 u32}(13230 = `requests`) / +72 目标订单组 idpair 8B(12462) | 定案: 逐目标国构造远征请求条目 + 外交音效/气泡；IsValid 含 AI 意愿门 |

#### 4.33.15 机动/订单域（一）

> 横断事实：**薄壳转发 action 范式第二例**——CMoveCommand = 136B 薄壳，+40 内嵌 CUnitMoveAction（vt 0x1429A3A38），[10][22][23] 转发桩与 CStrategicRedeploymentCommand（§4.33.5）同址；action 载荷 9 token（unit 10403 / province 10304 表 / path 372 表 / clear / safe / safe_until_very_end / safe_with_nonsafe_fallback / avoid / move_priority 14268 / sticky）。RTTI 直证：COrdersGroup、CFront 存在（MergeRoots/AutoMerge Execute 内 _RTDynamicCast）。IsValid 双参 "#~ " 错误串变体新增 5 类；reader 默认分支 24/24 = 家族默认。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 10402 | CMoveCommand | 0x1429B1BC8 | sizeof 136; action 内嵌 @+40（CUnitMoveAction, vt 0x1429A3A38; 命令偏移=action 相对 +40）: +56 unit idpair 8B(10403) / +64 目的省数组 24B(10304, count@+76) / +88 显式路径数组 24B(372, count@+100) / +120..+125 六旗 u8（clear 10737 / safe 11396 / safe_until_very_end 15000 / safe_with_nonsafe_fallback 14577 / 通行校验强度(不序列化) / avoid 11397）/ +128 move_priority u32(14268, 缺省 1 不落盘) / +132 sticky u8(13967) | 定案: 薄壳转发 action（逐省/路径移动令; 路径非空直走 sub_140BF9A40, 否则逐省 vt+120 校验; sticky 钉 unit+692）; IsValid = 逐省 vt+136 八参 dry-run; 行为桩 = Execute 0x1413669E0 → action vt[9] 0x141234E30 / IsValid 0x141369CB0 → action vt[10] 0x141235430 (转发经 cmd+40 处 action 自虚表 — 构造必填两张虚表); 手工构造参照: action ctor 0x141233F30 (action+8 即 cmd+48 写 token 13896, 目的省/路径两 vector alloc 哨兵 = off_143085170, 目的省数组元素 = u32 省 id)。⚠ 纯陆军令对不可步行邻接目标 (跨海峡/海岛陆省) IsValid dry-run 在 mil-access pathing (→sub_140DF7030) 可 0xc0000005 — 引擎 UI 通道走海军运输编排不经此路径, 手工构造侧须预滤或按 (源省,目标省) 对屏蔽 |
| 13343 | CMassMoveCommand | 0x1429B1C90 | sizeof 96; +40 路径数组（元素 32B, 372, count@+52 每单位一条）/ +64 unit idpair 数组(10403, count@+76) / +88 move_priority u32(14268) | 定案: N 单位各带路径批量移动（按下标配对, sub_140BF9A40）; IsValid = 两 count 相等且 ≥1 |
| 10415 | CCancelMovementCommand | 0x1429B1E20 | sizeof 72; +40 unit idpair 数组 24B(10403, count@+52) / +64 sticky u8(13967) | 定案: 批量取消移动（sticky 钉原地 = unit+692=当前省; 三错误串门: no units specified / no valid references / none allow cancel） |
| 13095 | COrderNewFrontCommand | 0x142A0B908 | sizeof 112; +40 group idpair 8B(63) / +48 可选子组 idpair 8B(14897) / +56 unit idpair 数组(10403, count@+68) / +72 划线路径 u32 数组(372, count@+92) / +104 attach 父线 order_index u32(338, 必非零) / +108 split_from u8(13156) / +109 blitz u8(14028) / +110 withdraw u8(14572) | 定案: 划线建前线+连接件挂靠 attach 父线（路径→计划 sub_141032780→新前线 sub_140BEBEB0(group,2)+连接件(group,1) 双挂; 断言 orderscommands.cpp:5359）; IsValid = path 非零 + attach 可解析 + ¬(blitz∧withdraw) |
| 13096 | COrderNewRootCommand | 0x142A0BC28 | sizeof 112; +40 组 idpair 8B(63) / +48 单位数组(10403, count@+60) / +72 新前线 idpair 8B(10720, 客户端预分配, IsValid 判 ≠qword_14333D528) / +80 section u32(13093, 落前线+608) / +88 比例下界 i64(10639) / +96 比例上界 i64(10640) / +104 原根 order_index u32(19474, ≠0 才写) / +108 子分节管理旗 u8(15783) | 定案: 建新根前线（可并 original_order 的子件/备降链） |
| 13271 | COrderNewFallbackCommand | 0x142A0BA98 | sizeof 96; +40 组 idpair 8B(63, 带门读) / +48 单位数组(10403, count@+60) / +72 路径省数组(372, count@+84) | 定案: 建备降线（Execute 内部高置信） |
| 13097 | COrderEditRootCommand | 0x142A0BF48 | sizeof 80; +40 组 idpair 8B(63) / +48 order_index u32(12342) / +56 比例下界 i64(10639) / +64 比例上界 i64(10640) / +72 update_connections u8(13846) / +73 手编旗 u8(14833) | 定案: 改根前线比例区间（from/to）+重建连接 |
| 13098 | COrderMergeRootsCommand | 0x142A0C1A0 | sizeof 64; +40 组 a idpair 8B(13113, 带门) / +48 组 b idpair 8B(13114, 带门) / +56 a 序号 u32(13115) / +60 b 序号 u32(13116) | 定案: 两根前线并线（子件/单位/比例并集，删 b 线） |
| 12350 | COrderAssignCommand | 0x142A0B200 | sizeof 80; +40 unit idpair 数组 24B(10403, count@+52) / +64 group idpair 8B(63) / +72 order_index u32(12342) / +76 assign_to_minimum_order u8(15603) | 定案: 单位批量分配前线（目标前线 find(order_index) 空则回退 group+440/+152/+164; 写点=前线+528/+540 单位表; InsertFront/NewRoot/CompletePlan 内联复用其 Execute）; IsValid 双参错误串 = no units specified / border war (单位+192→+432) / invalid order group |
| 13297 | COrderDeleteAllCommand | 0x142A0B070 | sizeof 48; +40 group idpair 8B(63) 单字段（与 12366 同读写体） | 定案: 清空组全部前线/挂接/备降（+80/+92 前线、+176/+188 挂接、+200/+212 备降三清单逐项拆解 + group+440 子组递归） |
| 12351 | COrderDeleteCommand | 0x142A0B138 | sizeof 56; +40 group idpair 8B(63) / +48 order_index u32(12342) | 定案: 删单前线（连接件单子件顶替分支; 断言 orderscommands.cpp:1891）; IsValid = group 可解析 + find 非零（共享 0x14184DC90） |
| 12352 | COrderExecuteCommand | 0x142A0C330 | sizeof 56; +40 group idpair 8B(63) / +48 order_index u32(12342; 0=全组) / +52 execute_order u8(12353) / +53 all u8(11159) | 定案: 执行前线/整组订单（单线 sub_141047610 / 整组 sub_141854620; all∧group+57 下探子组）; IsValid = 前线非空或 all + find 门 |
| 12366 | CDeleteOrderGroupCommand | 0x142A0ABC0 | sizeof 48; +40 组 idpair 8B(63, 带门读) 单字段（与 13297 同读写体） | 定案: 注销订单组（子组/普通双分支 + AI 通知） |
| 11983 | COrderGroupCommand | 0x142A0AAF8 | sizeof 96; +40 远征旗 u8(13730) / +48 成员单位数组(10403, count@+60) / +72 目标战区 idpair 8B(12058) / +80 可选战区组 idpair 8B(13777, 带门) / +88 可选陆军集团 idpair 8B(14482) | 定案: 建订单组（战区组上限门 + COMMAND_GROUP_CANT_REASSIGN 门） |
| 13208 | COrderInsertFrontCommand | 0x142A0B840 | sizeof 152; +40 组 idpair 8B(63) / +48 单位数组(10403, count@+60) / +72 路径数组(372, count@+84) / +96 attach 路径数组(13094, count@+108, 非空才写) / +120 attach 父线 u32(338) / +128 相交订单数组(13209, count@+140, idpair 平铺) | 定案: 在 attach 位插前线并并入相交线单位 |
| 13233 | COrderConnectCommand | 0x142A0B778 | sizeof 64; +40 组 idpair 8B(63) / +48 reconnect_from u32(13229) / +52 reconnect_to u32(13228) / +56 midpoint_from u32(13236) / +60 midpoint_to u32(13237)（writer 键序 13228→+52、13229→+48） | 定案: 两前线间建连接件（midpoint 压栈; IsValid 两线非连接件且同组） |
| 14069 | COrderBlockSectionsCommand | 0x142A0B458 | sizeof 88; +40 组 idpair 8B(63) / +48 order_index u32(12342) / +56 封锁段数组 {count@+68}(reader token 14070, wire = u32 对平铺重组 idpair) / +80 clear u8(10737) | 定案: 置/清前线封锁段（section idpair = 订单实例域 {69, 计数}） |
| 15758 | COrderChildFrontRatioCommand | 0x142A0C010 | sizeof 72; +40 组 idpair 8B(63, 带门) / +48 子组 idpair 8B(14897) / +56 order_index u32(12342) / +64 比例 i64(694) | 定案: 置子组比例 |
| 13918 | COrderAddNewCompletePlanCommand | 0x142A0BCF0 | sizeof 128; +40 组 idpair 8B(63) / +48 单位数组(10403, count@+60) / +72 路径数组(372, count@+84) / +96 split_from u8(13156, ≠0 才写) / +100 新根 idpair 8B(10720, IsValid 判 ≠哨兵) / +108 section u32(13093) / +112 from i64(10639) / +120 to i64(10640) | 定案: 组合命令：内联构造 NewRoot+NewFront+Assign 三连执行 |
| 13650 | CAutoMergeOrdersCommand | 0x142A0B9D0 | sizeof 56; +40 前线 idpair 8B(10720, 带门) / +48 section u32(13093, ≥0 门) | 定案: 前线 section 订单自动合并（CFront RTTI 直证） |
| 14990 | CMoveArmiesInTheaterCommand | 0x142A0AEE0 | sizeof 72; +40 组 idpair 数组(63, count@+52, 跳全零对) / +64 位次 u32(524) | 定案: 战区内 order group 按位次重排（各解析对象 +64 战区须同首元素） |
| 12448 | CDeleteUnitCommand | 0x1429B2140 | sizeof 56; +40 unit idpair 8B(10403) / +48 disband_unit u8(10698) / +52 country tag u32(10394, 串→哈希株) | 定案: 解散单位（远征属主 unit+476>0 分流退还属主 sub_1406EC040, 否则 sub_1401D6690 直散）; IsValid 双参错误串 = unit was null / cannot be disbanded by <tag> (vt+392 门) |
| 13872 | CMassCancelMovementCommand | 0x142993960 | sizeof 64; +40 unit idpair 数组 24B(10403, count@+52) 单字段 | 定案: 批量取消移动（无 sticky 简版 sub_140BFB4A0; IsValid = count ≥1） |
| 19837 | CAiOnFailedInvasionCommand | 0x142A31BF0 | sizeof 48; +40 国家 tag u32(10394) / +44 登陆失败省 u32(10304) | 定案: 登陆失败省上报战略 AI（IsValid 双参错误串 invalid country tag / Invalid command parameters） |
| 13235 | CSetUnitNameCommand | 0x1429B2208 | sizeof 80; +40 单位 idpair 8B(10403, +296 门) / +48 新名 SSO 串 32B(27) | 定案: 单位改名（师禁用，走 set_division_name; 虚表槽 [40] 设名） |
| 13533 | CTransportUnitCommand | 0x1429B2CF8 | sizeof 88; +40..+79 内嵌 CUnitNavalMoveAction 40B(vt 0x1429A3B08; 动作+16=壳+56 unit idpair 10403 / 动作+24=壳+64 省 u32 10304 / 动作+28=壳+68 location u32 10349 / 动作+32=壳+72 is_amphibious_invasion u8 13530) / +80 可选清队列目标 unit idpair 8B(13923) | 定案: 海运单位：+80 非空先 sub_140BFBAD0 清单位+704 动作队列 → CStrategicNavy 下单 sub_140EA9720(logical_country 链); IsValid = 单位≠16 + 省/location 互异可解析 + 两栖门 unit+8==0 或海域准入 |
| 12620 | CSupportAttackCommand | 0x1429B1FB0 | sizeof 56; +40 unit idpair 8B(10403, 须为师) / +48 location 目标省 u32(10349) | 定案: 师支援进攻：单位+488=省指针/+512 容器入列/+524=0; IsValid 错误串 = not a division (vt[8]) / fake intel army (+952→+564) + 可达五连 sub_140C785B0（结构定案/逐旗推定） |
| 12345 | COrderSetPathCommand | 0x142A0B520 | sizeof 88; +40 群 idpair 8B(63, 门) / +48 instance_id u32(12342, 文本标量) / +56 路径省数组 {cap@+64, 计数@+68}(372, 计数非零才写) / +72 非载荷槽 (既不序列化亦不 Clone, 定案) / +80 human u8(11126, 真才写) | 定案: 前线路径设置 sub_141854830；IsValid 要求实例 +600==qword_14333D528（当前前线全局，三证定案） |
| 13232 | COrderReconnectCommand | 0x142A0B6B0 | sizeof 64; +40 群 idpair 8B(63) / +48 instance_id u32(12463, 文本标量) / +52 reconnect_to u32(13228, 0=不用) / +56 reconnect_from u32(13229, 0=不用) | 定案: 实例重连双模式：to=唯一子转挂/to，from=自身转挂/from（orderscommands.cpp:6045/6079 断言定名） |
| 13579 | COrderRemoveRootCommands | 0x142A0BE80 | sizeof 48; +40 群 idpair 8B(63) 单字段 | 定案: 快照遍历删群全部根命令 + 国+3952 刷新 |
| 15785 | COrderReorderChildFrontCommand | 0x142A0C0D8 | sizeof 64; +40 群 idpair 8B(63) / +48 子前线 idpair 8B(14897, 直读) / +56 order_index u32(12342, 文本标量) / +60 目标位次 u32(524) | 定案: 子前线在 +896 清单（72B 元）按元+8 重排——72B 匿名元首块实证 |
| 13214 | COrderReshapeCommand | 0x142A0B5E8 | sizeof 64; +40 群 idpair 8B(63) / +48 instance_id u32(12463, 文本标量) / +56 中途点省数组 {cap@+64, 计数@+68}(13222, 恒写数组行) | 定案: 实例 +640 midpoints 整表替换 + blitz 刷新 |
| 14895 | COrderSetCollapseCommand | 0x142A0CC90 | sizeof 56; +40 群 idpair 8B(63) / +48 collapse u8(14894, 真才写) | 定案: og+584 collapse 直写，no-op 门 |
| 12643 | COrderSetInvasionSourceCommand | 0x142A0C588 | sizeof 80; +40 群 idpair 8B(63, 无门直读——唯一) / +48 既有入侵实例 id u32(12342, 0=新建) / +52 待接连单 u32(13117) / +56 入侵源省 u32(10304, 非零才写) / +64 参战单位数组 {计数@+76}(10403, 逐对独立行) | 定案: 入侵源省：既有实例写 +184，或新建 3 型实例+浮动港择优扣 100000 配额 |
| 13215 | COrderSetTrainingCommand | 0x142A0CBC8 | sizeof 56; +40 群 idpair 8B(63) / +48 训练旗 u8(12218, 真才写) / +49 经验满停训旗 u8(19076, 真才写) | 定案: og+413/+416 训练双旗，CArmyGroup 下探子群 |
| 12365 | COrderUnassignCommand | 0x142A0B2C8 | sizeof 80; +40 摘出单位数组 {cap@+48, 计数@+52}(10403; **群在 +64 倒置布局，唯一**) / +64 群 idpair 8B(63, 门) / +72 连群旗 u8(13955, 恒写) / +73 集团军级连带旗 u8(15774, 真才写) | 定案: 逐单位 RTDynamicCast→CUnit（RTTI 实名），+192 回指比对摘出 |
| 13894 | CQueueUnitActionCommand | 0x1429B2E88 | sizeof 56; +40 单位 idpair 8B(10403) / +48 动作对象指针 8B(嵌套行; 动作+8 类型 id: 13897=NavalMove / 13898=StrategicMove, 工厂 sub_141234C70 未知 token 断言返 0) | 定案: 通用动作排队壳：动作 Clone 后 push 单位+704 |
| 13901 | CRemovePlayerCommand | 0x142A22ED0 | sizeof 80; +40 踢人原因 u32(13902) / +44 目标机器 id u32(22, −1 无效) / +48 用户描述嵌套对象 32B(390) | 定案: 大厅踢人：非主机仅可 reason==0 自踢 |
| 14994 | CReorderPinnedStrategicRegionCommand | 0x142A87C68 | sizeof 56; +40 战略区域 id u32(12014) / +44 玩家 u32(10805) / +48 目标位次 u32(76)（三 u32 恒写） | 定案: 玩家钉选区域移位（IsValid 用 gs+736/748 区域表） |
| 14993 | CReorderTheatersCommand | 0x142A32798 | sizeof 56; +40 战区群 idpair 8B(13777) / +48 目标位次 u32(76) | 定案: 战区群在 theatre+200 清单摘除重插 |
| 12189 | CSetOrderGroupCohesionTypeCommand | 0x142A0A968 | sizeof 56; +40 群 idpair 8B(63) / +48 cohesion 类型 u32(225)（与 13992 全同体共享 [22]/[23]） | 定案: og+424 直写，CArmyGroup 下探 |
| 13992 | CSetOrderGroupExecutionTypeCommand | 0x142A0A8A0 | sizeof 56; 同 12189: +40 群 idpair 8B(63) / +48 execution 类型 u32(225) | 定案: og+420 直写，同探；与 Cohesion 共享序列化体 |
| 13924 | CSetOrderGroupIconAndColorCommand | 0x142A0A7D8 | sizeof 96; +40 群 idpair 8B(63) / +48 CColor 嵌套 32B(86, 分量 16B@+64..79) / +80 图标 u32(181) | 定案: og+272 颜色分量 16B + og+288 icon 直写 |
| 13571 | CSetOrderGroupMotorizationCommand | 0x142A0A710 | sizeof 56; +40 群 idpair 8B(63) / +48 摩托化等级 u8(19943, r8 通道恒写) | 定案: og+56 摩托化 + sub_140BF74B0 重算 |
| 13563 | CSetOrderGroupNameCommand | 0x142A0A580 | sizeof 80; +40 群 idpair 8B(63) / +48 新名 SSO 32B(27, size@+64 非零才写)（与 12057 共享 [22]/[23]） | 定案: og+352 改名；空名=清名复位 |
| 12057 | CSetOrderGroupOrdersInstanceNamesCommand | 0x142A0A648 | sizeof 80; 同 13563 体: +40 群 idpair 8B(63) / +48 名 SSO 32B(27) | 定案: 根清单实例批量改名（与 Name 共享序列化体、语义异；父群回退高置信） |
| 14857 | CSetOrdersLinkCommand | 0x142A0CFB0 | sizeof 96; +40 集团军 idpair 8B(14482) / +48 订单实例引用 24B(14642; 系统 idpair@+0/群 idpair@+8/order_index@+16 推定形) / +72 订单实例引用 24B(14643 同构) | 定案: **死命令壳**（Execute=CFG 空桩, 同 14901 款; 无生效路由） |
| 19438 | NRaids::NNet::CRemoveRaidCommand | 0x142A41970 | sizeof 56; +40 袭击实例 idpair 8B(19183, 非空才写带门) / +48 移除发起国 tag u32(19361, 串→tag 恒写) | 定案: 从 raid+440 参与国清单移除该 tag |

#### 4.33.16 占领/AI/突袭域

> 横断事实：NRaids 五个实例命令为 **CRTP `CRaidInstanceCommand<T>` 派生**（Clone 双虚表写）；raid 实例 raw 基锚 = +48 自动完成 / +52 自动发射 / +56 ERaidPhase / +64 风险 / +88 属主链。新锚（供各分册增补）：CRaidSystem+216 按国 176B 条目（+96 优先级、+128 实例表）、csa+8424 力量集中表、CCountryOccupationStatus 记录 +160 法槽 / +168 州覆盖法表、cc+4336 CPlayerAiPrefs 16B、taskforce+1336 编成需求宿主、外交动作包装 +8 类型 id / +120 人力值。

| id | 类 | vtable | 载荷字段 | Execute 语义 |
|---:|---|---|---:|---|
| 12568 | CSetOccupationPolicyCommand | 0x142995AF8 | sizeof 80; +40 被占国 tag u32(10302, RH 表键) / +44 占领国 tag u32(10303) / +48 法名串 32B(10492, 空串合法语义待裁; +64 size 门) | 定案: 设「owner×controller」记录级占领法（记录 +160 法槽） |
| 19370 | CSetDefaultCountryOccupationPolicyCommand | 0x142995A30 | sizeof 80; +40 目标国 tag u32(10754) / +48 法名串 32B(10492, 空 = 置空默认) | 定案: 设 occ+280 默认法并全清记录级/州级覆盖 |
| 15324 | CSetStateOverrideOccupationPolicyCommand | 0x142995BC0 | sizeof 80; +40 占领国 tag u32(10303, 须 == state+204 或同盟门) / +44 州 id u32(439, 1..gs+724) / +48 法名串 32B(10492, 空 = 合法) | 定案: 记录 +168 州覆盖表[state_id]=法（键 = state+696 被占国 tag） |
| 19138 | CAmendForeignManpowerActionCommand | 0x142997380 | sizeof 56; +40 动作所属国 tag u32(writer 10426/reader 10394 ⚠ 不对称) / +44 incoming 外交动作 idpair 8B(10472, 带门) / +52 新人力值 u32(10300, ≠0 门) | 定案: 改 incoming 外交动作人力值（包装 +120） |
| 11169 | CAiStoreForceConcentrationTargetCommand | 0x142A31D80 | sizeof 64; +40 国 tag u32(10394) / +44 目标省 u32(107) / +48 源省 u32(10639) / +56 进度 i64(11013) = `progress` (fixed×1e-5) | 定案: 战略 AI 力量集中目标 upsert（csa+8424 表 24B 元） |
| 11170 | CAiDiscardForceConcentrationTargetCommand | 0x142A31E48 | sizeof 56; +40 国 tag u32(10394) / +44 目标省 u32(107) / +48 源省 u32(10639) | 定案: 同表同键删除（与 Store 共享 IsValid 0x141A747B0） |
| 14525 | CLearnTraitCommand | 0x142A0CD58 | sizeof 56; +40 指挥官 idpair 8B(10423, 带门; 空则断言 orderscommands.cpp:7919) / +48 特性对象指针 8B(11918; reader 名串哈希→特性 DB qword_14332F0D0, writer 写 *(trait+8) DB 槽号) | 定案: 指挥官学特性+扣 cc+496 指挥力（qword_143337680 开销） |
| 11579 | CSetPlayerAiPrefsCommand | 0x142993640 | sizeof 64; +40 目标国 tag u32(10394) / +48 CPlayerAiPrefs 内嵌 16B(11101; vt@+48, u8×4@+56..59, u32@+60) | 定案: 写 cc+4336 玩家 AI 偏好 8B (CPlayerAiPrefs 16B 键面 = {start_wars, keep_alliances, quick_peace, move_traders} u8×4 + timeout u32, 键 11580/11582/11583/11584/11585; IsValid = 共享 tag>0 桩) |
| 16737 | CSetCountryRaidsPriorityCommand | 0x14272DD18 | sizeof 48; +40 国 tag u32(10394) / +44 优先级 u32(141, 0..2 门) | 定案: CRaidSystem 按国条目（+216 数组 176B/国）+96 = 优先级；GetTypeId 间接常量形态 |
| 15171 | CSetTaskForceCompositionRequirementsCommand | 0x1429AFF20 | sizeof 152; +40 特混 idpair 8B(15157, 带门, 执行须 ≠16) / +48 需求对象 104B(15166; 数组A 16B 元 {d@56,cap@64,c@68} / 数组B u32 {d@80,c@92} / 数组C u32 {d@104,c@116} / 尾 32B 待裁) | 高置信: 编成需求三数组整表拷入 taskforce+1336 |
| 19192 | NRaids::CCreateRaidCommand | 0x142A41010 | sizeof 176; +40 发起国 tag u32(10394, >0 才写) / +48 突袭类型对象指针 8B(225, 名串哈希 db+144 表) / +56 目标容器 40B(107; 外指针+内联 16B+count@+24+待裁 16B; leader 子目标@+80 非空须带省) / +96 源变体 52B(10383; 枚举@0/旗@4/指针@8/内嵌 CBuildingReference@32; type 2 = tag@+24+州) / +152 内联单位表 16B(10403, 定长 ≤2 idpair) / +168 风险等级 u32(19196) / +172 auto_launch u8(10155, 置位写 raw+48, 语义交叠待裁) | 定案: 建突袭实例（容器细部待裁项见载荷注） |
| 19194 | NRaids::CExecuteRaidCommand | 0x142A411A0 | sizeof 48; +40 突袭实例 idpair 8B(19183, 带门, 全零不写) | 定案: 发射突袭（phase 门，拒 4） |
| 19209 | NRaids::CCancelRaidCommand | 0x142A417E0 | sizeof 48; +40 突袭实例 idpair 8B(19183) 单字段 | 定案: 取消突袭（置 phase 5；与 Execute 共享 [22]/[23]） |
| 19195 | NRaids::CSetRaidAutoComplete | 0x142A41330 | sizeof 56; +40 突袭实例 idpair 8B(19183) / +48 enable u8(10376, 恒写无实例门) | 定案: 写 raw+48 自动完成旗 (auto_launch +172 与 auto_complete 实例+48 **不交叠**, sub_140FEF560 直证) |
| 19526 | NRaids::CSetRaidAutoLaunchOption | 0x142A414C0 | sizeof 56; +40 突袭实例 idpair 8B(19183) / +48 选项枚举 u32(10348, IsValid ≤4) | 定案: 写 raw+52 枚举 (值域 0..4, IsValid 0x141B340C0 直证) |
| 16602 | NRaids::CSetRaidRiskLevelCommand | 0x142A41650 | sizeof 56; +40 突袭实例 idpair 8B(19183) / +48 风险等级 u32(19196) | 定案: 写 raw+64（与 CCreateRaid +168 互证） |


#### 4.33.17 杂项/网络域（名录批）

> 名录口径：每类一句话用途（非深读卡）；证据等级 = Execute 语义串 16 / reader token 84 / 类名推定 8；置信分布 定案 83 / 高置信 22 / 推定 3。GetTypeId 直读对账 99/108 与普查一致（9 类函数序非标，id 从普查表）。侧观察：CChunkReceived/CSendChunk/CStartFileTransfer 实为网络大文件传输三件套；CChatUserJoinedCommand 载荷含 token 765=pops_id（疑复用，待裁）；普查基座虚表 0x142977040 疑即 CIncreaseGameSpeedCommand 自身表（GetTypeId=10455 直读）。

杂项 88 类:

| id | 类 | 载荷（sizeof） | 用途（证据） | 置信 |
|---:|---|---|---|---|
| 19072 | CActivateActiveDecryptionBonuses | sizeof 48; +44 tag(串解析)(107) / +40 tag(串解析)(10394) | 激活当前(对目标国的)解密加成（R:{107=target, 10394=country}） | 定案 |
| 13995 | CAddHumanCommand | sizeof 248; 11126:? / 16004:嵌套(暂存) / +152 直写(10394) / 22:u32(暂存) / 27:? | 把人类玩家(machineid/名字/用户/profile徽章)加入人类槽（串:"Added player '%s' (%d)" + R:{11126=human, 16004=profile_badge, 10394=country, 22=machineid, 27=name, 226=user}） | 定案 |
| 10723 | CAddPlayerCommand | sizeof 176; 389:? / +128 嵌套(389) / +120 u32(22) / 27:? / 226:? / 11466:bool@a1+124; 嵌套对象@a1+104 | 大厅加玩家(含热加入/聊天用户加入旗与防重入门)（串:"Human already added!"/"Tried to add already added human!"/"Failed to access game lobby!" + R:{389=chat_user_joined, 22=machineid, 27=name, 226=user, 11466=hotjoin}） | 定案 |
| 10438 | CAddSizeCommand | sizeof 56; 417:u32@a1+40; CIdentifier带门@&栈; 写入@a1+44 | 向某(引用)对象加数量 amount, 目标对象语义未定（R:{417=amount}, Execute 调共用助手+引用对(a1+44)判空） | 推定 |
| 10297 | CAddTaskCapacityCommand | sizeof 56; 417:u32@a1+40; CIdentifier带门@&栈; 写入@a1+44 | 增加任务容量 amount, 所属系统(战区/编队任务容量)未定（R:{417=amount}, 与 CAddSize 同 reader/同形 Execute） | 推定 |
| 13682 | CAskToCoopWithCountryCommand | sizeof 48; +44 u32(22) / +40 直写(10394) | 弹确认框询问是否允许与他国合作(co-op)（串:"default_confirmation_popup"/"ALLOW_COOP_REQUEST_DESC"/"ALLOW_COOP_REQUEST" + R:{22=machineid, 10394=country}） | 定案 |
| 13789 | CAssignToTheaterGroupCommand | sizeof 104; +72 串(27) / 12462:CIdentifier(门)(暂存) / +40 CIdentifier(13777) | 把 orders_group 指派进 theater_group（R:{27=name, 12462=orders_group, 13777=theater_group}） | 定案 |
| 10417 | CAutomateHomebaseForFleetCommand | sizeof 48; 无自有载荷（基座默认 reader） | 让舰队的母港选择转为自动（NE:15156=fleet + 串:"Invalid fleet"） | 定案 |
| 10808 | CAutosave | sizeof 48; +40 u8(105) | 触发自动存档（R:{105=start}） | 高置信 |
| 15284 | CCancelRunningAwayCommand | sizeof 48; 无自有载荷（基座默认 reader） | 取消舰队撤退/逃离状态（NE:10398=navy） | 定案 |
| 13174 | CChangeCountryControllerCommand | sizeof 56; +48 u32(22) / +40 直写(10394) / +44 直写(10724) | 国家控制权在本地/远程玩家间切换（串:"Local player will control"/"Remote player will control"/"CalcMod for" + R:{22=machineid, 10394=country, 10724=other}） | 定案 |
| 307 | CChunkReceived | sizeof 64; +40 u32(11) / +48 i64(108) / +56 u8(213) / +44 u32(226) | 网络大文件传输: 接收块并推进进度（串:"received chunk ... for id ... progress"/"missing large file handle (chunk received)" + R:{11=id, 108=up, 213=announcedone, 226=user}） | 定案 |
| 10708 | CClearAllControllersCommand | vt 0x14295E5C0 (24 槽): [9] ret1 / [10] Execute sub_140CEC980 / [11] GetTypeId sub_140CEE280 / [13] Clone sub_140CEBF50; **Execute = 逐国把 cc+112 controller 槽置 0** (循环 gs 国家数组, `*(u32*)(v11 + i*160 + 112) = *sub_140BB3E00(&v,0)`) | 清空全部国家控制者(全部回到无人控制)（空(五槽 thin), 载荷空载, 类名+id） | 高置信 |
| 14954 | CCreateAreaDefenseCommand | sizeof 80; 63:CIdentifier(门)(暂存) / 11101:文本标量(暂存) / 11835:? | 创建区域防御 order group(含设置与州集)（R:{63=group, 11101=settings, 11835=states}） | 定案 |
| 15158 | CCreateFleetCommand | sizeof 144; +40 tag(10394) / +44 theater_group(13777) / +56 task_force 数组 / +80 ship 数组 / +104 province_id / +108 orders / +112 region 数组 / +136 mission / +140 待裁（详卡 §4.33.12） | 创建舰队(舰船/区域/任务/编队/战区组全套参数)（R:{11087=province_id, 10394=country, 10400=ship, 10827=region, 11450=mission, 12119=orders, 13777=theater_group, 15157=task_force}(Execute 串=防垃圾引用样板, 不作语义证)） | 定案 |
| 12387 | CCreateTradeCommand | sizeof 64; +40 importer tag / +44 exporter tag / +48 资源 def 指针 / +56 数量（详卡 §4.33.18） | 创建贸易交易(资源/出口方/进口方/数量)（R:{417=amount, 12388=resource, 12389=exporter, 12390=importer} + 串:ThreadIsMainThread() 断言） | 定案 |
| 10456 | CDecreaseGameSpeedCommand | sizeof 72; +40 串(27) | 游戏减速(前端按钮, 逐级)（R:{27=name}） | 高置信 |
| 10545 | CDiplomaticActionCommand | sizeof 48; +40 多态外交动作指针（工厂 38 动作 id，详卡 §4.33.18） | 外交动作封装命令: 载荷=单个内嵌外交动作对象（嵌入载荷 (reader 读 a1+40 的内嵌对象, 无 token)） | 高置信 |
| 13790 | CDisbandTheaterGroupCommand | sizeof 48; 无自有载荷（基座默认 reader） | 解散战区组（NE:13777=theater_group） | 定案 |
| 13873 | CEditAreaDefenseStateCommand | sizeof 88; 63:CIdentifier(门)(暂存) / 439:u32(暂存) / +80 u8(10737) / 11101:写入@a1+81; 文本标量@&栈 / +48 文本标量(12342) | 编辑区域防御组内的州条目(加/清)（R:{63=group, 439=state, 10737=clear, 11101=settings, 12342=order_index}） | 定案 |
| 10228 | CExecuteButtonCommand | sizeof 56; +44 直写(135) / +40 tag(串解析)(10754) / +48 直写(11827) | 执行 GUI 窗口按钮(按 parent/tag/button 定位)（R:{135=parent, 10754=tag, 11827=button}） | 定案 |
| 14966 | CExecuteScriptedWindowEffect | sizeof 152; 27:? / 89:? | 执行 scripted GUI 窗口 effect（R:{27=name, 89=effect, 439=state, 10423=leader, 10754=tag}） | 定案 |
| 19078 | CHideDecryptionCommand | sizeof 48; +44 tag(串解析)(107) / +40 tag(串解析)(10394) | 隐藏/撤除对目标国的解密情报显示（R:{107=target, 10394=country}） | 定案 |
| 12092 | CHourlyTickCommand | sizeof 64; +40 u32数组(776) | 每游戏小时驱动命令(联机同步的逐时推进载体)（R:{776=value} + 类名） | 高置信 |
| 15628 | CIncomingDiplomaticActionActingCommand | 无 case 标签（待人工核） | 来向外交动作的 AI 决策响应处理（链:{10394=country, 10472=diplomacy, 11142=decision, 15626=process_ai_response}） | 定案 |
| 10455 | CIncreaseGameSpeedCommand | 全继承基座（空载） | 游戏加速(前端按钮, 逐级); 与减速成对（空载; id=10455 由 GetTypeId 直读; 五槽=普查基座自比(见 §3 侧观察)） | 高置信 |
| 14344 | CMergeArmiesCommand | sizeof 72; 10397:CIdentifier(门)(暂存) / 14464:CIdentifier(门)(暂存) | 合并集团军(并入指定军)（R:{10397=army, 14464=army_to_consolidate}） | 定案 |
| 13176 | CMergeNaviesCommand | sizeof 72; +40 navy idpair 数组(10398) / +64 merge_to_first u8(15475)（§4.33.12） | 合并舰队(可并入第一支)（R:{10398=navy, 15475=merge_to_first} + 串(缓冲区断言样板)） | 定案 |
| 14785 | CMoreGroundCrewsCommand | sizeof 56; +48 u8(705) / +40 直写(10394) / +44 u32(10827) | 增派地勤(空军基地 ground crews, 可开关)（R:{705=enabled, 10394=country, 10827=region}） | 定案 |
| 10732 | CPauseGame | sizeof 80; +40 串(27) / +72 u8(776) / +73 u8(10598) | 暂停/恢复游戏(可带选项与来源名)（R:{27=name, 776=value, 10598=option}） | 高置信 |
| 10714 | CQuit | vt 0x1429E60D0 (24 槽): **[10] Execute = CFG 空桩 (0x14012A2C0)** / [9] ret1 / [11] GetTypeId sub_14163DCE0 / [13] Clone sub_14163C2F0; [22]/[23] 亦 CFG 空桩 (载荷空载) | 退出游戏（Execute=CFG 空桩, 载荷空载, 类名+id） | 高置信 |
| 15317 | CReinstateExileCommand | sizeof 48; +40 tag(串解析)(11533) | 复位/迎回流亡(政府/人员)（R:{11533=exile}） | 定案 |
| 13103 | CReleaseCountryCommand | sizeof 56; +52 u32(22) / 10960:? / 12497:? / +44 直写(13024) | 释放附庸国(可择傀儡或完全自由)（串:"on_release_as_puppet"/"on_release_as_free" + R:{22=machineid, 10960=core_creation, 12497=puppet, 13024=subject}） | 定案 |
| 13997 | CRequestGameStateTransferCommand | sizeof 80; +72 u32(22) / +40 串(27) | 请求(向某玩家)做游戏状态全量转移（R:{22=machineid, 27=name}） | 高置信 |
| 13090 | CRequestReadyStatus | vt 0x1429E6648 (24 槽): [10] Execute sub_14163CE70 / [11] GetTypeId sub_14163DCF0 / [13] Clone sub_14163C370; **Execute = 为本地玩家造一条 CSetReadyStatus(就绪=true) 并投递** (取本地 machine id → 玩家对象 → 门 +152≠−1 → 造 0x30 命令 → sub_142250B00) | 大厅就绪状态请求广播（空(五槽 thin), 载荷空载, 类名+id） | 高置信 |
| 15206 | CResetCustomDifficultyMultipliers | 无 case 标签（待人工核） | 重置全部自定义难度乘数（reader=CFG 空桩(无载荷), 类名+id） | 高置信 |
| 15205 | CResetGameRules | 无 case 标签（待人工核） | 重置游戏规则到默认（reader=CFG 空桩(无载荷), 类名+id） | 高置信 |
| 10250 | CSelectBookmarkCommand | sizeof 48; 无自有载荷（基座默认 reader） | 选择开局剧本书签（NE:10249=bookmark + 串:"_pInstance && \"Instance not created.\""(gameitemdatabase.h)） | 定案 |
| 10645 | CSelectEventOptionCommand | sizeof 240; +40 id / +44 事件 CIdentifier / +52 actor tag / +56 内嵌 scope 176B / +232 选项序（详卡 §4.33.18） | 选择事件选项(驱动事件走向)（串:"EVENT"/"OPTION"/"EVENTHAPPENUS"/"MAJOREVENTHAPPENOTHER"/"EVENTHAPPENOTHEROPTION"/"Calling UpdateCB" + R:{11=id, 440=event, 10542=actor, 10598=option, 10646=scope}） | 定案 |
| 306 | CSendChunk | sizeof 80; +64 u32(11) / 218:CIdentifier(门)(暂存) / +40 sub_1424C0C30(240) | 网络大文件传输: 发送块（串:"CSendChunk Execute: chunk"/"CSendChunk Execute FAIL: chunk" + R:{11=id, 218=handler, 240=data}） | 定案 |
| 10890 | CSetAchievementsOK | sizeof 48; +40 u8(776) | 设置成就可用标志(铁人/成就门)（R:{776=value} + 类名） | 高置信 |
| 14063 | CSetAreaDefenseSettingCommand | sizeof 56; 63:CIdentifier(门)(暂存) / +54 u8(776) / +48 文本标量(12342) / +52 sub_1424C08A0(14072) | 设置区域防御组设置项（R:{63=group, 776=value, 12342=order_index, 14072=area_defense_setting}） | 定案 |
| 15172 | CSetAsReserveFleetCommand | sizeof 112; +40 fleet(15156) / +48 task_force 数组 / +72 ship 数组(10400) / +96 theater_group(13777) / +104 u8 = `preserve_reinforce_requirements` (15528)（§4.33.12） | 把(特混)舰队设为预备舰队(可带母港/编队组)（R:{15157=task_force, 15156=fleet, 10400=ship, 12790=naval_base, 13777=theater_group}） | 定案 |
| 10707 | CSetCountryControllerCommand | sizeof 48; +44 u32(22) / +40 直写(10394) | 指派某玩家控制某国（串:"Attempted to assign ... to nonexistent human"/"Current thread is forbidden" + R:{22=machineid, 10394=country}） | 定案 |
| 13908 | CSetCountryControllerTypeCommand | sizeof 48; +44 直写(225) / +40 直写(10394) | 设置国家控制类型(枚举门)（R:{225=type, 10394=country}(串 "Invalid enum" 枚举门佐证)） | 定案 |
| 19124 | CSetCountryGarrisonPriorityCommand | sizeof 48; +44 u32(141) / +40 tag(串解析)(10394) | 设置国家驻军(garrison)优先级（R:{141=priority, 10394=country}） | 定案 |
| 13226 | CSetCountryUpgradePriorityCommand | sizeof 48; +44 u32(141) / +40 tag(串解析)(10394) | 设置国家升级优先级（R:{141=priority, 10394=country}） | 定案 |
| 14008 | CSetCustomDifficultyMultiplier | sizeof 80; 220:? / +72 i64(776) | 设置单项自定义难度乘数(键值对)（R:{220=key, 776=value}） | 定案 |
| 11545 | CSetDLCsCommand | sizeof 48; +40 文本标量(11546) | 设置会话启用的 DLC 集合（R:{11546=dlcs}） | 定案 |
| 10258 | CSetDifficulty | sizeof 48; 无自有载荷（基座默认 reader） | 设置(全球)难度等级（NE:10655=difficulty） | 定案 |
| 15165 | CSetFleetCommand | sizeof 72; +40 fleet CIdentifier(15156) / +48 task_force 数组(15157)（§4.33.12） | 把特混舰队挂到舰队(拒绝挂到预备舰队)（串:"Refusing to assign task forces to a reserve fleet" + R:{15156=fleet, 15157=task_force}） | 定案 |
| 16738 | CSetFleetHomeBaseCommand | sizeof 56; +40 fleet CIdentifier(15156) / +48 naval_base 省 u32(12790) / +52 move u8(333)（§4.33.12） | 设置舰队母港(可带搬迁旗)（R:{333=move, 12790=naval_base, 15156=fleet}(串 "Invalid fleet" 半语义佐证)） | 定案 |
| 15178 | CSetFleetIconAndColorCommand | sizeof 96; +48 嵌套(86) / 181:u32@a1+80; CIdentifier带门@&栈; 写入@a1+40 | 设置舰队图标与颜色（R:{86=color, 181=icon}） | 定案 |
| 15163 | CSetFleetNameCommand | sizeof 80; 27:串@a1+48; CIdentifier带门@&栈; 写入@a1+40 | 设置舰队名（R:{27=name}） | 定案 |
| 15573 | CSetFuelPriorityCommand | sizeof 56; +48 u32(141) / +44 u32(225) / +40 直写(10394) | 设置国家燃油(分配)优先级（R:{141=priority, 225=type, 10394=country}） | 定案 |
| 11100 | CSetGamePlayOptions | sizeof 64; +40 嵌套(11100) | 设置游戏玩法选项(整块读入)（R:{11100=setgameplayoptions}） | 高置信 |
| 15203 | CSetGameRuleOption | sizeof 48; +44 直写(10598) / +40 直写(10876) | 设置单项游戏规则选项（R:{10598=option, 10876=rule}） | 定案 |
| 12098 | CSetGameSpeedCommand | sizeof 48; +40 u32(110) | 设置游戏速度(绝对档位)（R:{110=speed}） | 定案 |
| 15237 | CSetGameUniqueId | sizeof 72; +40 串(11) | 设置游戏唯一 id(联机会话标识)（R:{11=id}） | 高置信 |
| 14496 | CSetIndustrialManufacturerCommand | sizeof 64; +40 tag(串解析)(10394) / 11979:CIdentifier(门)(暂存) / +44 CIdentifier(12143) | 设置生产线的工业组织(MIO 制造商)归属（R:{10394=country, 11979=organisation, 12143=production_line}） | 定案 |
| 13470 | CSetMPDebugSettings | sizeof 48; +40 sub_14163BC90(11101) | 设置多人调试设置块（R:{11101=settings} + 类名） | 定案 |
| 10307 | CSetPendingReassignTargetCommand | sizeof 64; +56 u8(10283) / 12354:CIdentifier(门)(暂存) / 12462:CIdentifier(门)(暂存) | 设置挂起的部队重指派目标（R:{10283=deploy_army_hq, 12354=unit_leader, 12462=orders_group}） | 定案 |
| 13728 | CSetPinnedStrategicRegionCommand | sizeof 72; +64 u32(10805) / 12014:? | 设置钉选战略区域(按玩家)（R:{10805=player, 12014=strategic_region}） | 定案 |
| 19911 | CSetPreferredTacticCommand | sizeof 56; 10754:串→tag@a1+40; u32@&栈; 写入@a1+48 | 设置(陆战)偏好战术（R:{10754=tag}） | 高置信 |
| 15001 | CSetPrideOfTheFleetCommand | sizeof 56; +48 直写(10394) / 10400:CIdentifier(门)(暂存) | 设置「舰队荣耀」功勋舰（R:{10394=country, 10400=ship}） | 定案 |
| 10731 | CSetRandomSeed | sizeof 48; +40 u32(10647) / +44 u32(10730) | 设置随机种子(联机确定性同步)（R:{10647=seed, 10730=count}） | 定案 |
| 11517 | CSetReadyStatus | sizeof 48; +40 u32(22) / +44 u8(776) | 设置(某玩家的)大厅就绪状态（R:{22=machineid, 776=value}） | 定案 |
| 19918 | CSetScorchedStateCommand | sizeof 64; 439:u32(暂存) / +40 tag(串解析)(10394) / +56 u8(11231) | 设置州焦土状态（R:{439=state, 10394=country, 11231=scorched}） | 定案 |
| 15177 | CSetTaskForceIconAndColorCommand | sizeof 96; +48 嵌套(86) / +80 u32(181) / 15157:CIdentifier(门)(暂存) / +84 u8(15195) | 设置特混舰队图标与颜色(可沿用舰队色)（R:{86=color, 181=icon, 15157=task_force, 15195=use_fleet_color}） | 定案 |
| 13791 | CSetTheaterGroupNameCommand | sizeof 80; 27:串@a1+48; CIdentifier带门@&栈; 写入@a1+40 | 设置战区组名（R:{27=name}） | 定案 |
| 13792 | CSetTheaterGroupPriorityCommand | sizeof 56; 141:u32@a1+48; CIdentifier带门@&栈; 写入@a1+40 | 设置战区组优先级（R:{141=priority}） | 定案 |
| 12045 | CSetTheatreCommand | sizeof 56; 11:CIdentifier(门)(暂存) | 设置(部队/编队)所属战区（R:{11=id}） | 定案 |
| 13614 | CSetTimedActivityDistributionPriorityCommand | sizeof 56; +44 直写(107) / +52 u32(141) / 10546:串→枚举@a1+48; 写入@a1+40 | 设置(角色)定时活动分配优先级（R:{107=target, 141=priority, 10546=action}） | 定案 |
| 11801 | CSetUseDynamicVersionPositioningVariantCommand | sizeof 56; 398:bool@a1+48; CIdentifier带门@&栈; 写入@a1+40 | 前端动态版本号定位变体开关(主菜单版本摆放)（R:{398=show_position} + 类名） | 推定 |
| 305 | CStartFileTransfer | sizeof 96; +64 串(27) / +40 u32(47) / +52 u32(107) / +44 CIdentifier(218) / +56 u32(240) | 开始网络文件传输(mod/存档同步, 带大小与校验和)（串:"CStartFileTransfer Name: ... size: ... checksum:" + R:{27=name, 47=size, 107=target, 218=handler, 240=data}） | 定案 |
| 13726 | CStartGameCommand | vt 0x1429E6008 (24 槽): [10] Execute sub_14163DA10 / [11] GetTypeId sub_14163DD90 / [13] Clone sub_14163C930; **Execute = 从大厅开始游戏** (清 gs 旗 bit0 → sub_140DE2C00 → 置 lobby 对象 +148 bit2 → 调应用槽 640) | 从大厅开始游戏（空(五槽 thin), 载荷空载, 类名+id） | 高置信 |
| 16402 | CStartProjectCommand | sizeof 56; 10022:CIdentifier(门)(暂存) / 16392:CIdentifier(门)(暂存) | 启动(特殊)项目（R:{10022=project, 16392=program}） | 定案 |
| 19064 | CStartStopDecryptionCommand | sizeof 56; +48 u8(105) / +44 tag(串解析)(107) / +40 tag(串解析)(10394) | 启停对目标国的解密（R:{105=start, 107=target, 10394=country}） | 定案 |
| 16403 | CStopProjectCommand | sizeof 48; 无自有载荷（基座默认 reader） | 停止(特殊)项目（NE:10022=project） | 定案 |
| 14706 | CToggleBombingPriorityCommand | sizeof 56; 10319:枚举(串解析)(暂存) / 13161:CIdentifier(门)(暂存) | 切换( air_wing 对 building 的)轰炸优先级（R:{10319=building, 13161=air_wing}） | 定案 |
| 13725 | CTogglePinnedStrategicRegionCommand | sizeof 48; +44 u32(10805) / +40 u32(12014) | 切换钉选战略区域（R:{10805=player, 12014=strategic_region}） | 定案 |
| 14513 | CTriggerAbilityCommand | sizeof 120; +40 直写(10394) / +112 u8(10469) / 12354:CIdentifier(门)(暂存) / 14475:串@a1+48; u32@&栈 | 触发/取消(指挥官)技能（R:{10394=country, 10469=cancel, 12354=unit_leader, 14475=ability} + 串:"Infinite cycle in"(内部防死循环断言)） | 定案 |
| 16118 | CUpdateProfileBadgeCommand | sizeof 56; +40 嵌套(16004) | 更新玩家资料徽章（R:{16004=profile_badge}） | 定案 |
| 16777 | NDoctrines::CUnlockGrandDoctrineCommand | sizeof 56; +48 tag(串解析)(10394) / +40 直写(16775) | 解锁 grand doctrine(大主义)（R:{10394=country, 16775=grand_doctrine} + 串:"Invalid elements in subdoctrine unlock command"(两命令共用断言)） | 定案 |
| 16779 | NDoctrines::CUnlockSubDoctrineCommand | sizeof 64; +56 u32(139) / +60 tag(串解析)(10394) | 解锁 sub doctrine(子主义, 按轨道)（R:{139=track, 10394=country} + 同上共用断言） | 定案 |
| 10191 | NInternationalMarket::CMarketStockpileClearCommand | sizeof 48; +40 tag(串解析)(10754) | 清空国际市场(某 tag 的)装备库存（R:{10754=tag}） | 高置信 |
| 10105 | NInternationalMarket::CSetMarketRequestAutomationOptionsCommand | sizeof 48; +44 sub_140DEF040(10598) / +40 tag(串解析)(10754) | 设置国际市场请求自动化选项（R:{10598=option, 10754=tag}） | 定案 |
| 15473 | ShowScriptedDiplomaticActionSendPopupCommand | 无 case 标签（待人工核） | 显示 scripted 外交动作「已发送」弹窗（链:{107=target, 10542=actor, 10546=action}） | 定案 |

网络 20 类:

| id | 类 | 载荷（sizeof） | 用途（证据） | 置信 |
|---:|---|---|---|---|
| 292 | CChatBuffer::CSendChatMessage | sizeof 56; 291:CIdentifier(门)(暂存) | 经聊天缓冲发送聊天消息（R:{291=chatbuffer}） | 高置信 |
| 290 | CChatBuffer::CWriteToChatBuffer | sizeof 112; 215:? / 226:? / 291:CIdentifier(门)(暂存) | 把消息文本写入聊天缓冲（R:{215=chattext, 226=user, 291=chatbuffer}） | 定案 |
| 388 | CChatCommand | sizeof 128; 217:? / +88 u8(217) / 86:? / 198:? / 214:? / 221:sub_1424CD070@a1+40; sub_1424CB4D0@a1+40 / 226:? / +96 串(576) | 聊天消息主命令(频道/正文/收发者/颜色/时间全字段)（R:{217=datetime, 86=color, 198=receiver, 214=channel, 221=message, 226=user, 576=sender}） | 定案 |
| 393 | CChatNewChannelCommand | sizeof 96; +40 串(27) / +72 u32数组(228) | 新建聊天频道(带用户列表)（R:{27=name, 228=userslist}） | 定案 |
| 396 | CChatRequestSyncCommand | vt 0x1429AD818 (24 槽): [10] Execute sub_141337240 / [11] GetTypeId sub_141337B10 / [13] Clone sub_141336310; **Execute = 造一条 CChatSyncAllCommand 并投递** (门 qword_14338A140 + +48 对象 +84 字节) | 请求聊天全量同步（空(五槽 thin), 载荷空载, 类名+id） | 高置信 |
| 395 | CChatSyncAllCommand | sizeof 144; +136 u32(11) / +112 sub_14132D6F0(62) / +40 sub_14132D420(214) / +64 串数组(226) / 228:? | 聊天全量同步(频道/对象/用户列表整体投递)（R:{11=id, 62=objects, 214=channel, 226=user, 228=userslist}） | 定案 |
| 391 | CChatUserJoinedChannelCommand | sizeof 48; +40 u32(11) / +44 u32(214) | 用户加入频道通知（R:{11=id, 214=channel}） | 定案 |
| 389 | CChatUserJoinedCommand | sizeof 128; 11:u32@a1+72; sub_14070CEA0@a1+80 / +40 串(27) / 765:sub_1401F9270(暂存) | 用户加入会话通知（R:{11=id, 27=name, 765=pops_id}） | 定案 |
| 392 | CChatUserLeftChannelCommand | sizeof 48; +40 u32(11) / +44 u32(214) | 用户离开频道通知（R:{11=id, 214=channel}） | 定案 |
| 390 | CChatUserLeftCommand | sizeof 48; +40 u32(11) | 用户离开会话通知（R:{11=id}） | 定案 |
| 11530 | CCheckSyncCommand | sizeof 64; +40 u32数组(13670) | 发起同步校验(对全部人类玩家)（R:{13670=humans}） | 高置信 |
| 11529 | CCheckSyncResponseCommand | sizeof 80; +72 u32(22) / +40 串(27) / +76 u8(10347) | 同步校验响应(进/失步回报)（串:"' ( ... ) is now in sync! (CheckSyncResponseCommand)"/") is NOT in sync!" + R:{22=machineid, 27=name, 10347=success}） | 定案 |
| 13100 | CClientOutOfSyncCommand | sizeof 104; +48 串(27) / +40 tag(串解析)(10754) / +80 u32数组(12967) | 客户端失步报告(带错误码)（R:{27=name, 10754=tag, 12967=error_code}） | 定案 |
| 11376 | CClientPingCommand | sizeof 72; +64 u32(22) / +68 文本标量(789) / +56 嵌套(10314) | 客户端延迟探测+高延迟处置(降速/暂停门)（串:"LAG_DECREASE_SPEED"/"LAG_PAUSE"/"PLAYER" + R:{22=machineid, 789=latency, 10314=date}） | 定案 |
| 11504 | CPostHotJoinCommand | sizeof 88; +64 sub_1406330D0(13274) / +40 sub_1406330D0(16537) | 热加入后置命令批量执行(重排人控国)（串:"EXECUTING_POST_HOTJOIN_COMMANDS"/"POSTJOININITDONE"/"Post hotjoin-commands executed."/"Waiting for other players." + R:{13274=disabled_countries, 16537=human_controlled_countries}） | 定案 |
| 11469 | CReadyAfterHotJoinCommand | sizeof 80; +72 u32(22) / +40 串(27) | 热加入后就绪确认（R:{22=machineid, 27=name}） | 高置信 |
| 11467 | CReopenLobbyCommand | vt 0x14296A7B8 (24 槽): [10] Execute sub_140DE8A30 (14.9KB, 体内含串 "HOTJOIN_STARTING!") / [11] GetTypeId sub_140DE9DC0 / [13] Clone sub_140DE6D00 | 重开大厅(热加入起点)（串:"HOTJOIN_STARTING!" + 空(五槽 thin)） | 定案 |
| 11438 | CRequestGameStateSynchCommand | sizeof 64; +40 u32数组(377) | 请求游戏状态再同步(resync, 带校验和)（串:"Resync" + R:{377=checksum}） | 定案 |
| 14350 | CSendPingCommand | 无 case 标签（待人工核） | 多人地图标点 ping(位置/时长/可攻旗)（链:{27=name, 10394=country, 10925=time_duration, 14351=ping_position, 14352=is_offensive}） | 定案 |
| 13465 | CSetCoopHotJoinOptions | sizeof 48; +40 u32(13466) / +44 u32(13467) | 设置合作/热加入选项（R:{13466=coop_setting, 13467=hotjoin_setting}） | 定案 |

#### 4.33.18 外部驱动重点命令详卡（载荷逐字段；配套 example 自动驾驶实测）

> 三张详卡补 4.33.5/4.33.9 的简行; 载荷自 +40, 实例 0x48/0x48/0x50 依次。
> 外部构造配方: engine_alloc 整块零填 → 写 vtable+载荷 → [9] IsValid 神谕
> (返回 bool 只置 AL, 判 v%256≠0) → [10] Execute。实测全链已逐段复核。

CSetResearchCommand (12144) 载荷:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | u32 | 目标国 tag id (= gs 国家数组下标, >0 门) |
| +44 | — | tag ref 尾 4B (零填可; 解析 sub_140BB48F0 取址) |
| +48 | CTechnologyTemplate* | 目标科技**模板** (模板+56 = 1 基实例索引进 ts+136; ⚠ 非 CTechnology 实例——实例 +352 才是模板) |
| +56 | i32 | 槽号 (0 ≤ x < ts+172 容量; 可用槽数 = cc+4936 动态值) |
| +60 | u8 | XP 旗: 0 = 短路放行/免 XP; 非 0 = 加验模板+1312 并置 use_experience |

CSetNationalFocusCommand (13245) 载荷:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | u32 | 目标国 tag id (同上) |
| +44 | — | tag ref 尾 4B |
| +48 | CNationalFocus* | 目标国策 def (§4.3.13) |

> Execute (0x14115C670) 全文 4 语句: sub_140BB4390(+40) → return
> sub_140711660(国, *(+48))。sub_140711660 = 启动/切换/取消三合一 (a2=0 取消):
> fp+24 (current_continuous) 非空先清 → sub_1402DAE20(fp, focus) 落 fp+16 /
> 清 fp+24 → 名 SSO 写 cc+3832 → def+1480 宣战表通知; 树一致性断言
> country.cpp:13030。

CAddConstructionCommand (12151) 载荷:

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | u32 | 目标国 tag id |
| +44 | — | tag ref 尾 4B (零填可) |
| +48 | CBuildingReference 内嵌 | {vt@+48 = 0x142971F30, +56 州 id i32 (键 10349 location), +60 建筑 def 名 token (键 19482 template), **+64 = country tag_id** (键 10394 country; writer sub_1413C0D80 经 sub_140BB59C0 发引号 tag, 门 >0; ctor 默认 {州 id=−1, token=19479 undefined})} |
| +72 | i32 | 数量 (Execute 逐次加) |
| +76 | u8 | 插入位置枚举 (IsValid 门 < 3) |

> IsValid (0x1411616F0): tag>0 → ref 检 sub_1413C0920 → 州检 sub_1411771B0 →
> 可建神谕 sub_1411749A0(州, token, tag, 1) → 枚举 < 3。CBuildingReference ctor
> sub_1413C07D0 (buildingreference.cpp:0x14, 默认 {州 id=−1, token=19479
> "undefined"})。按引用查既有队列线 = sub_140E5CF90(cm, ref, 0, 0) 非零即存活;
> ⚠ 建筑队列项不在 ps+88 产线容器 (那里 type 56/57 = 军/海线)。

CSelectEventOptionCommand (10645) 载荷 (sizeof 240):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | u32 | id (文本标量通道) |
| +44 | CIdentifier 8B | 目标事件 id 对 (双 dword, 零=无效) |
| +52 | u32 | actor 国 tag (解析上下文串→tag 通道, >0 门) |
| +56 | 匿名结构 (176B 形状) | 事件 scope (嵌套对象通道, 占至 +232) |
| +232 | u32 | option 选项序号 |

> Execute (0x14153A110): event id 解析 (sub_14221F310) → 门 = 事件 def+884
> 选项数 >0 且 actor>0 → sub_141180110(事件, scope+56) 按选项落子 → "EVENT"
> 日志节点 (0x58B) 链入事件历史链表。事件 def+884 = 选项数 (静态锚, CEvent
> 布局未入册)。IsValid (0x14153AFB0): id 非零且解析非空 + actor>0 + 选项数
> 非零 + 全局实例门 (gameitemdatabase "_pInstance")。

CCreateTradeCommand (12387) 载荷 (sizeof 64):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | u32 | importer 进口国 tag (12390; 文本通道 = 国名串→tag; >0 门) |
| +44 | u32 | exporter 出口国 tag (12389; 同上; >0 门) |
| +48 | 资源 def 指针 8B | 12388; gameitemdatabase 按 id 解析; IsValid 判 def+16 可贸易旗 |
| +56 | u32 | amount 数量 (417) |

> Execute (0x141BA54B0): sub_140CB5D60(exporter, importer, 资源def, amount)
> 建交易 → UI 国/同盟等价容差 (sub_140BB52F0) → ThreadIsMainThread 断言
> (ingameinterfacehandler.h:197, 帧顶执行天然满足)。IsValid (0x141BA56D0):
> 双 tag>0 → tag ref 解析 (sub_140BB48F0) → 国家有效 (sub_140700120) 双门 +
> 资源 def+16 旗非零。

CDiplomaticActionCommand (10545) 载荷 (sizeof 48):

| 偏移 | 类型 | 语义 |
|---|---|---|
| +40 | CDiplomaticAction* 多态指针 8B | 内嵌外交动作对象（reader 先虚析构旧件再装新件; 空则走未知 token 跳过桩） |

> 动作对象工厂 (reader 0x14113D350): 按动作类型 id 分派 malloc+构造, 现普查
> **38 型**: 10111/10232/10298/10325/10544/10548/11479/12220/12232/12243/12244/
> 12474/12525/12716/12916/13289/13310/13333/13339/13345/13423/13522(入阵邀请)/
> 13782/14027(输入租借)/14078/14079/14271/14426/14553/15097/15098/15099/19135/
> 19136/19141/19348/19353/19774（id 空间独立于命令 id）。动作对象公共头 (高置信):
> +8 = 类型 id / +20 = 发起方 tag / +28 = 目标方 tag (wrapper IsValid 0x141138E10
> 直读三门)。Execute (0x141104D80) 转发动作对象虚调用。用法先例 = 12242 建阵
> 逐成员包本命令 post (diplomaticaction.cpp:110 断言)。

> 重播种注意: 4.33.3 的 CSetRandomSeed 语义 (lo 迭代入 524 / hi 直存 520) 与
> savefull 导出名 (524=multiplayer_random_seed / 520=count) 是同一对槽的两种
> 命名; 直写 524+清 520 与走 sub_142234600 等效 (均为设定初始状态)。
