extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	_require("res://project.godot", ["theme/default_font_multichannel_signed_distance_field=true"], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["RESCUE RUSH", "WATER SORT", "BLOCK PUZZLE", "daily_done_count", "HomeHeroGameArt3D", "#dcebe8", "#29465b"], errors)
	_require("res://scripts/ui/premium_home_overhaul.gd", ["Progress, stars, wallet", "_sync()"], errors)
	_require("res://scripts/ui/premium_main_casual.gd", ["One challenge per game today", "DONE TODAY", "PLAY TODAY", "TODAY’S SORT", "\"Sound, motion & theme\"", "DailyAccent/", "game-tinted lacquer", "SurfaceWorldDepth", "SurfaceBackdropHaloTop", "SurfaceGlossSweep"], errors)
	_require("res://scripts/ui/premium_design_system.gd", ["PremiumGlossBackdrop", "func _gloss_style", "func _install_gloss"], errors)
	_require("res://scripts/ui/figma_reference_canvas.gd", ["Premium casual-game gloss", "lower_rolloff", "center_boost"], errors)
	_require("res://scripts/ui/figma_reference_canvas.gd", ["TEXTURE_FILTER_LINEAR", "var image_size := 160", "func add_world_depth", "func add_scene_backdrop_layers", "func add_collectible_star", "func add_collectible_gem", "Localized key-light hotspot", "Premium 3D bevel side"], errors)
	_require("res://scripts/ui/figma_button_backdrop.gd", ["Premium toy-like controls", "var pressed := false", "button_down.connect", "height_loss"], errors)
	_require("res://scripts/ui/unjam_3d_backdrop.gd", ["Fewer, larger foliage clusters"], errors)
	_require("res://scripts/ui/premium_main_casual.gd", ["SurfaceKeyLight", "SurfaceAccentGlow", "#1b63c5", "#173f98", "#0a1d58"], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["HomeKeyLight", "HomeAccentGlow", "HomeCurrencyGem3D", "HomeCurrencyStar3D", "WorldProgressSpecular"], errors)
	_require("res://scripts/ui/premium_result_overlay.gd", ["ResultKeyLight", "ResultStar3D", "ResultGameArt3D", "add_collectible_star"], errors)
	_require("res://scripts/ui/ux_shell_casual.gd", ["TutorialKeyLight", "add_scene_backdrop_layers"], errors)
	_require("res://scripts/ui/premium_live_hub_3d.gd", ["SelectorWorldDepth", "SelectorGameArt3D_", "SelectorKeyLight", "#1b63c5", "\"CHOOSE A GAME\", Rect2(83, 21, 186, 28), 21", "style_display_title"], errors)
	_require("res://scripts/ui/unjam_3d_game_art.gd", ["camera.fov = 39.0", "Game-specific card-scale composition", "display_root.scale = Vector3.ONE * 1.05", "Vector3(-0.14, 0.05, 0.08)"], errors)
	_require("res://scripts/ui/monetization_hub_3d.gd", ["ShopWorldDepth", "ShopKeyLight", "ShopCurrencyGem3D", "add_collectible_gem", "style_display_title"], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["rounded_gradient3(stage_mid", "rounded_gradient3(nav_fill", "rounded_gradient3(fill.lightened"], errors)
	_require("res://scripts/ui/premium_live_hub_3d.gd", ["rounded_gradient3(pill_mid", "rounded_gradient3(stage_mid", "rounded_gradient3(nav_fill"], errors)
	_require("res://scripts/ui/insufficient_coins_prompt.gd", ["card_mid", "rounded_gradient3"], errors)
	_require("res://scripts/game/rescue_rush_casual.gd", ["rounded_gradient3"], errors)
	_require("res://scripts/game/water_sort_casual.gd", ["rounded_gradient3", "Premium glass needs contrast", "#173d67", "#061f3c"], errors)
	_require("res://scripts/core/multi_game_manager.gd", ["func daily_started_games", "func daily_selected_game", "func claim_daily_game", "daily_game_choices"], errors)
	_require("res://scripts/game/water_sort_casual.gd", ["stage_height := 390.0", "count <= 12 else 5", "height_width_limit"], errors)
	_require("res://scripts/game/water_sort_10000.gd", ["if tubes.size() > 10:", "meta_label.text = \"%s • WORLD %d\"", "premium_feedback.show_banner"], errors)
	_require("res://scripts/ui/water_tube_3d_motion.gd", ["Premium bottle silhouette built from real geometry", "GLASS_BODY_RADIUS := 0.72", "_glass_material_3d", "BottleShoulder3D", "BottleNeck3D", "BottleInnerWall3D"], errors)
	_require("res://scripts/game/water_sort_10000.gd", ["WATER SORT FAILED", "func _has_any_legal_pour", "NO LEGAL POURS"], errors)
	_require("res://scripts/game/block_puzzle_10000.gd", ["BLOCK PUZZLE FAILED", "func _handle_no_legal_moves", "BlockFailureResult", "func _level_intro_banner_center()", "board_top_local.y - 27.0"], errors)
	_require("res://scripts/game/rescue_rush_assisted.gd", ["func _level_intro_banner_center()", "board_bottom_local.y + 54.0"], errors)
	_reject("res://scripts/game/block_puzzle_10000.gd", ["view.y * 0.22"], errors)
	_reject("res://scripts/game/rescue_rush_assisted.gd", ["view.y * 0.22"], errors)
	_require("res://scripts/game/game.gd", ["RESCUE FAILED", "func _has_any_legal_move", "var failed: bool = false"], errors)
	_reject("res://scripts/ui/water_tube_button.gd", ["draw_line(body.position + Vector2(31, 43)", "glass_shine", "draw_rect(glass_shine", "var shine: Rect2", "draw_rect(shine", "draw_line(body.position + Vector2(9, 25)", "draw_line(Vector2(body.end.x - 9", "_draw_round_rect(cavity, Color(0.025, 0.075, 0.14"], errors)
	_reject("res://scripts/game/block_puzzle_3d.gd", ["No moves — new blocks"], errors)
	_reject("res://scripts/game/block_puzzle.gd", ["No moves — new blocks", "pieces[0] = SHAPES[0].duplicate()"], errors)
	_reject("res://scripts/ui/premium_main_casual.gd", ["Daily level %d", "Three fresh challenges every day", "TODAY: %s"], errors)
	if not errors.is_empty():
		for error in errors:
			printerr(error)
		quit(1)
		return
	print("REQUESTED_POLISH_CONTRACT_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _require(path: String, tokens: Array[String], errors: Array[String]) -> void:
	var source := _read(path)
	if source.is_empty():
		errors.append("Missing source: %s" % path)
		return
	for token in tokens:
		if not source.contains(token):
			errors.append("%s missing %s" % [path, token])

func _reject(path: String, tokens: Array[String], errors: Array[String]) -> void:
	var source := _read(path)
	for token in tokens:
		if source.contains(token):
			errors.append("%s still contains retired behavior: %s" % [path, token])
