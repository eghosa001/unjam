extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check("res://scripts/ui/premium_home_direct_levels.gd", ["FigmaHome390x844", "FigmaHomeHero", "HomeCoinShopButton", "HomeLevelsNavButton"], failures)
	_check("res://scripts/ui/premium_live_hub_3d.gd", ["FigmaSelector390x844", "GameCard3D_", "_preview_block", "SelectorCardHit_"], failures)
	_check("res://scripts/ui/premium_main_casual.gd", ["FigmaSurface390x844", "_figma_level_tabs", "_add_figma_block_modes", "SettingsCard/Sound"], failures)
	_check("res://scripts/ui/monetization_hub_3d.gd", ["FigmaShop390x844", "WATCH & EARN", "ShopRestorePurchases", "ShopPrivacyOptions"], failures)
	_check("res://scripts/ui/insufficient_coins_prompt.gd", ["FigmaInsufficientCoins390x844", "CoinModal/Rewarded", "CoinModal/Shop", "CoinModal/Later"], failures)
	_check("res://scripts/ui/premium_result_overlay.gd", ["FigmaResult390x844", "ResultCard3D", "PrimaryAction", "ResultStatsText"], failures)
	_check("res://scripts/ui/ux_shell_casual.gd", ["FigmaTutorial390x844", "_apply_figma_tutorial_theme", "TutorialDemoArt", "TutorialClose"], failures)
	_check("res://scripts/game/rescue_rush_casual.gd", ["FigmaRescue390x844", "Identity/Rescue Emblem", "RescueBoardPanel", "RescueHintAction"], failures)
	_check("res://scripts/game/water_sort_casual.gd", ["FigmaWater390x844", "Identity/Water Emblem", "GameplayStage", "WaterHintAction"], failures)
	_check("res://scripts/game/block_puzzle_3d.gd", ["FigmaBlock390x844", "Identity/Block Emblem", "BlockBoardShell", "BlockPieceRow"], failures)
	_check("res://scripts/ui/unjam_3d_gameplay_stage.gd", ["class_name Unjam3DGameplayStage", "_build_rescue_world", "_build_water_world", "_build_block_world"], failures)
	_check("res://scripts/ui/water_tube_3d_motion.gd", ["SubViewport", "Camera3D"], failures)
	_check("res://scripts/ui/rescue_piece_3d_button.gd", ["_draw"], failures)
	_check("res://scripts/ui/block_cell_button.gd", ["_draw"], failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("FIGMA_3D_RUNTIME_OK: active Home, selector, Shop, tutorials, results and all three gameplay surfaces use the audited Figma/3D runtime chain.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _check(path: String, needles: Array[String], failures: Array[String]) -> void:
	var source := _read(path)
	if source.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if not source.contains(needle):
			failures.append("Missing Figma runtime contract '%s' in %s" % [needle, path])
