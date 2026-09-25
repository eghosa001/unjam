extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	_require("res://project.godot", ["theme/default_font_multichannel_signed_distance_field=false"], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["RESCUE RUSH", "WATER SORT", "BLOCK PUZZLE", "daily_done_count", "HomeHeroFlatGameLogo", "HomeWorldFlatGameLogo", "#e4dfd5", "#1f1f1f"], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["HomeNavTopGloss", "HomeNavActivePlate", "HomeNavGlyph_", "HomeGamesNavButton", "\"GAMES\", \"▦\"", "\"DAILY\", \"✦\"", "\"COLLECT\", \"◆\""], errors)
	_require("res://scripts/ui/premium_home_overhaul.gd", ["Progress, stars, wallet", "_sync()"], errors)
	_require("res://scripts/ui/premium_home_casual.gd", ["HomeCoinShopButton", "HomeGamesNavButton", "HomeDailyNavButton", "HomeCollectionNavButton", "HomeSettingsNavButton", "GAMES", "DAILY", "COLLECT"], errors)
	_require("res://scripts/ui/premium_main_casual.gd", ["COMPLETED", "\"PLAY\"", "DailyAccent/", "CLEAR THE ROUTE", "SORT THE COLOURS", "CLEAR THE BOARD", "SurfaceWorldDepth", "SurfaceBackdropHaloTop", "SurfaceGlossSweep", "\"SETTINGS\", \"\", \"\""], errors)
	_require("res://scripts/ui/premium_design_system.gd", ["PremiumGlossBackdrop", "func _gloss_style", "func _install_gloss"], errors)
	_require("res://scripts/ui/figma_reference_canvas.gd", ["Premium casual-game gloss", "lower_rolloff", "center_boost"], errors)
	_require("res://scripts/ui/figma_reference_canvas.gd", ["TEXTURE_FILTER_LINEAR", "var image_size := 160", "Unjam3DTheme.strong_font()", "Unjam3DTheme.readable_font()", "shadow_offset_y\", 0", "shadow_outline_size\", 0", "func add_world_depth", "func add_scene_backdrop_layers", "func add_collectible_star", "func add_collectible_gem", "Localized key-light hotspot", "Premium 3D bevel side"], errors)
	_require("res://scripts/ui/unjam_3d_theme.gd", ["func strong_font()", "font.variation_embolden = 0.08", "font.variation_embolden = 0.38"], errors)
	_require("res://scripts/ui/unjam_3d_backdrop.gd", ["_sky_gradient_texture", "_river_gradient_texture", "draw_texture_rect(_sky_gradient()", "draw_texture_rect(_river_gradient()", "TEXTURE_FILTER_LINEAR"], errors)
	_require("res://scripts/ui/figma_button_backdrop.gd", ["Premium toy-like controls", "var pressed := false", "button_down.connect", "height_loss"], errors)
	_require("res://scripts/ui/unjam_3d_backdrop.gd", ["Fewer, larger foliage clusters"], errors)
	_require("res://scripts/ui/premium_main_casual.gd", ["SurfaceKeyLight", "SurfaceAccentGlow", "#e4dfd5", "#b3aca2", "#80786e"], errors)
	_require("res://scripts/ui/premium_main_casual.gd", ["StdNavTopGloss", "StdNavActivePlate_", "StdNavGlyph_", "\"games\":\"▦\"", "\"daily\":\"✦\"", "\"collection\":\"◆\"", "\"settings\":\"⚙\""], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["HomeKeyLight", "HomeAccentGlow", "HomeCurrencyGem3D", "HomeCurrencyStar3D", "WorldProgressSpecular"], errors)
	_require("res://scripts/ui/premium_result_overlay.gd", ["ResultKeyLight", "ResultStar3D", "ResultGameArt3D", "add_collectible_star"], errors)
	_require("res://scripts/ui/ux_shell_casual.gd", ["TutorialKeyLight", "add_scene_backdrop_layers"], errors)
	_require("res://scripts/ui/ux_shell_casual.gd", ["FigmaReferenceCanvas.label(\"EXIT\",12", "TutorialDemoExitLabel", "FigmaReferenceCanvas.set_rect(exit_label,160,34,46,17)"], errors)
	_require("res://scripts/ui/premium_gameplay_feedback.gd", ["is_intro_banner", "BlockPremiumFeedback", "RescuePremiumFeedback", "viewport_size.y * 0.68"], errors)
	_require("res://scripts/ui/premium_live_hub_3d.gd", ["SelectorWorldDepth", "SelectorFlatGameLogo_", "SelectorKeyLight", "#e4dfd5", "#b3aca2", "#80786e", "\"CHOOSE A GAME\", Rect2(78, 26, 196, 34), 22", "style_display_title", "mark.configure(game_id)", "SelectorGamePreviewFrame_"], errors)
	_require("res://scripts/ui/unjam_3d_game_art.gd", ["PROJECTION_ORTHOGONAL", "camera.size = 9.15", "camera.fov = 39.0", "flat_selector_mode", "Vector2i(416, 448) if flat_selector_mode else Vector2i(576, 432)", "unjam_flat_3d_preview", "Game-specific card-scale composition", "display_root.scale = Vector3.ONE * 1.05", "Vector3(-0.14, 0.05, 0.08)"], errors)
	_require("res://scripts/ui/monetization_hub_3d.gd", ["add_scene_backdrop_layers", "ShopKeyLight", "ShopCurrencyGem3D", "add_collectible_gem", "style_display_title"], errors)
	_require("res://scripts/ui/premium_home_direct_levels.gd", ["rounded_gradient3(stage_mid", "rounded_gradient3(nav_fill", "rounded_gradient3(fill.lightened"], errors)
	_require("res://scripts/ui/premium_live_hub_3d.gd", ["rounded_gradient3(pill_mid", "rounded_gradient3(stage_mid", "rounded_gradient3(nav_fill"], errors)
	_require("res://scripts/ui/insufficient_coins_prompt.gd", ["card_mid", "rounded_gradient3"], errors)
	_require("res://scripts/game/rescue_rush_casual.gd", ["rounded_gradient3"], errors)
	_require("res://scripts/game/rescue_rush_polished.gd", ["one tween owner", "final_target", "travel_time", "launch_scale", "shape_tween"], errors)
	_require("res://scripts/game/water_sort_casual.gd", ["rounded_gradient3", "Premium glass needs contrast", "#173d67", "#061f3c"], errors)
	_require("res://scripts/core/multi_game_manager.gd", ["func daily_started_games", "func daily_selected_game", "func claim_daily_game", "daily_game_choices"], errors)
	_require("res://scripts/game/water_sort_casual.gd", ["stage_height := 420.0", "count <= 12 else 5", "height_width_limit"], errors)
	_require("res://scripts/game/water_sort_10000.gd", ["if tubes.size() > 10:", "meta_label.text = \"DAILY CHALLENGE\" if daily_mode else \"LEVEL %d • WORLD %d\"", "premium_feedback.show_banner"], errors)
	_require("res://scripts/ui/water_tube_3d_motion.gd", ["Premium bottle silhouette built from real geometry", "GLASS_BODY_RADIUS := 0.72", "_glass_material_3d", "BottleShoulder3D", "BottleNeck3D", "BottleInnerWall3D", "_arrival_impulse", "Arrival ripple", "arrival_flatten", "and not MotionSystem.reduced()"], errors)
	_require("res://scripts/game/water_sort_10000.gd", ["STUCK • NO LEGAL POUR", "func _has_any_legal_pour", "UNDO, ADD A TUBE, OR RETRY • NO PENALTY"], errors)
	_require("res://scripts/game/block_puzzle_10000.gd", ["func _failure_presentation", "OUT OF MOVES", "NO MOVES LEFT", "func _handle_no_legal_moves", "BlockFailureResult", "func _level_intro_banner_center()", "board_top_local.y - 27.0", "spectacle_level", "show_ring(center", "FeedbackManager.combo(spectacle_level)"], errors)
	_require("res://scripts/game/rescue_rush_assisted.gd", ["func _level_intro_banner_center()", "board_bottom_local.y + 54.0"], errors)
	_reject("res://scripts/game/block_puzzle_10000.gd", ["view.y * 0.22"], errors)
	_reject("res://scripts/game/rescue_rush_assisted.gd", ["view.y * 0.22"], errors)
	_require("res://scripts/game/game.gd", ["RESCUE FAILED", "func _has_any_legal_move", "var failed: bool = false"], errors)
	_reject("res://scripts/ui/water_tube_button.gd", ["draw_line(body.position + Vector2(31, 43)", "glass_shine", "draw_rect(glass_shine", "var shine: Rect2", "draw_rect(shine", "draw_line(body.position + Vector2(9, 25)", "draw_line(Vector2(body.end.x - 9", "_draw_round_rect(cavity, Color(0.025, 0.075, 0.14"], errors)
	_reject("res://scripts/game/block_puzzle_3d.gd", ["No moves — new blocks"], errors)
	_reject("res://scripts/game/block_puzzle.gd", ["No moves — new blocks", "pieces[0] = SHAPES[0].duplicate()"], errors)
	_reject("res://scripts/ui/premium_home_direct_levels.gd", ["HomeLevelsNavButton", "HomeShopNavButton", "HomeNavSelectedDot", "HomeNavSelectedUnderline"], errors)
	_reject("res://scripts/ui/premium_home_casual.gd", ["HomeLevelsNavButton", "HomeShopNavButton"], errors)
	_reject("res://scripts/ui/premium_main_casual.gd", ["Daily level %d", "Three fresh challenges every day", "TODAY: %s", "One challenge per game today", "Sound, motion & theme", "game-tinted lacquer", "Each Daily is independent • play in any order", "ACHIEVEMENT CABINET"], errors)
	_reject("res://scripts/ui/premium_home_direct_levels.gd", ["NEXT • LEVEL %d", "QUICK SWITCH"], errors)
	_reject("res://scripts/game/block_puzzle_3d.gd", ["BlockCampaignSubtitle", "\"CAMPAIGN\""], errors)
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
