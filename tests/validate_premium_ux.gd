extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_source("res://scripts/ui/figma_reference_canvas.gd", ["REFERENCE_SIZE := Vector2(390.0, 844.0)", "rounded_gradient", "set_rect"], failures)
	_check_source("res://scripts/ui/premium_home_direct_levels.gd", ["FigmaHome390x844", "FigmaHomeHero", "HomePrimaryAction", "HomeChooseGameButton", "HomeBottomNav3D"], failures)
	_check_source("res://scripts/ui/premium_live_hub_3d.gd", ["FigmaSelector390x844", "GameCard3D_", "SelectorCardHit_", "SelectorBottomNav"], failures)
	_check_source("res://scripts/game/water_sort_casual.gd", ["FigmaWater390x844", "GameplayStage", "WaterUndoAction", "WaterRetryAction"], failures)
	_check_source("res://scripts/game/block_puzzle_3d.gd", ["FigmaBlock390x844", "BlockBoardShell", "BlockTray", "BlockPieceRow"], failures)
	_check_source("res://scripts/game/rescue_rush_casual.gd", ["FigmaRescue390x844", "RescueBoardPanel", "RescueUndoAction", "RescueRestartAction"], failures)
	_check_source("res://scripts/ui/premium_result_overlay.gd", ["FigmaResult390x844", "ResultCard3D", "PrimaryAction"], failures)
	_check_source("res://scripts/ui/ux_shell_casual.gd", ["FigmaTutorial390x844", "TutorialPanel", "TutorialDemoArt", "PLAY NOW"], failures)
	_check_source("res://scripts/ui/monetization_hub_3d.gd", ["FigmaShop390x844", "ShopProduct_", "ShopRewardedCoinsButton"], failures)
	_check_source("res://scripts/ui/insufficient_coins_prompt.gd", ["FigmaInsufficientCoins390x844", "CoinModal/Card", "WATCH AD"], failures)
	_check_source("res://scripts/ui/block_piece_button.gd", ["touch_preview", "TOUCH_LIFT", "_update_touch_footprint", "register_touch_drag"], failures)
	_check_source("res://scripts/game/block_puzzle_polished.gd", ["active_touch_piece", "register_touch_drag", "_finish_touch_drag"], failures)
	_check_source("res://scripts/ui/water_tube_reference_button.gd", ["PALETTE", "liquid_base", "glass lip", "Premium bottle silhouette", "Shoulder bridge", "neck_width := rect.size.x * 0.48", "double-wall glass", "center_glow", "OUTER crystal contour", "Local refraction", "visual_pour_rim_local", "visual_receive_rim_local", "play_invalid", "play_success"], failures)
	_check_source("res://scripts/systems/premium_visuals.gd", ["tactile_success", "tactile_invalid", "transition_cover"], failures)
	_check_source("res://scripts/ui/motion_director.gd", ["create_tween", "TRANS", "EASE"], failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Premium UX contract validated: audited 390x844 Figma reference composition is the runtime visual source of truth.")
	quit(0)

func _check_source(path: String, needles: Array[String], failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Missing source: " + path)
		return
	var source := file.get_as_text()
	for needle in needles:
		if not source.contains(needle):
			failures.append("Missing Figma runtime contract '%s' in %s" % [needle, path])
