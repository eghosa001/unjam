extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_canonical_motion_key(): return
	if not await _validate_active_game_monetization_identity(): return
	if not _validate_water_concurrent_action_safety(): return
	if not _validate_multi_game_retention_parity(): return
	if not _validate_rewarded_result_state(): return
	if not await _validate_shared_completion_overlay(): return
	if not await _validate_help_does_not_overlap_game_footer(): return
	if not await _validate_primary_visual_occupancy(): return
	if not _validate_figma_button_contrast(): return
	if not await _validate_header_badge_clearance(): return
	if not await _validate_shop_header_clearance(): return
	if not await _validate_selector_header_and_navigation(): return
	if not await _validate_exact_touch_target_floor(): return
	if not _validate_dead_code_cleanup(): return
	if not _validate_retention_failure_wiring(): return
	if not _validate_visual_workflow_installs_plugins(): return
	if not _validate_main_ci_runs_new_hardening_gates(): return
	if not _validate_release_workflow_exists(): return
	if not _validate_retired_dead_code_removed(): return
	if not await _validate_audio_teardown_contract(): return
	print("Production hardening regressions validated")
	quit(0)

func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _validate_canonical_motion_key() -> bool:
	# Only sources that actually drive time-varying motion belong here. One-shot
	# 3D dioramas and skinning-only surface managers intentionally do not need a
	# Reduced Motion branch; MotionDirector remains the sole navigation animator.
	for path in [
		"res://scripts/ui/motion_director.gd",
		"res://scripts/ui/premium_home_casual.gd",
		"res://scripts/systems/premium_visuals.gd"
	]:
		var source := _source(path)
		if not source.contains("MotionSystem.reduced()"):
			return _fail("%s does not use MotionSystem.reduced()" % path)
		if source.contains('SaveManager.data.get("reduced_motion"'):
			return _fail("%s still reads legacy reduced_motion directly" % path)
	var static_surface := _source("res://scripts/ui/premium_surface_manager_static.gd")
	if not static_surface.contains("func _animate_surface") or static_surface.contains("create_tween"):
		return _fail("Static surface manager must defer navigation motion to MotionDirector")
	var settings := _source("res://scripts/ui/premium_main_casual.gd")
	if settings.contains('SaveManager.data["reduced_motion"]'):
		return _fail("Settings still writes duplicate reduced_motion key")
	return true

func _validate_active_game_monetization_identity() -> bool:
	var cases := [
		["res://scenes/WaterSort.tscn", "water_sort"],
		["res://scenes/BlockPuzzle.tscn", "block_puzzle"]
	]
	for case_value in cases:
		var scene := load(String(case_value[0])) as PackedScene
		var game := scene.instantiate()
		root.add_child(game)
		await process_frame
		if not game.has_method("monetization_game_id"):
			game.queue_free(); await process_frame
			return _fail("Active scene %s has no monetization_game_id method" % case_value[0])
		if String(game.call("monetization_game_id")) != String(case_value[1]):
			game.queue_free(); await process_frame
			return _fail("Active scene %s reports wrong monetization game id" % case_value[0])
		game.queue_free()
		await process_frame
	var hub := _source("res://scripts/ui/monetization_hub.gd")
	if not hub.contains('node.has_method("monetization_game_id")'):
		return _fail("MonetizationHub still identifies active games by script filename")
	return true

func _validate_water_concurrent_action_safety() -> bool:
	var source := _source("res://scripts/game/water_sort_reference_motion.gd")
	for needle in ["func _has_active_pours", "func undo_move", "func restart_level", "func _quit", "_queued_action", "_run_queued_action_if_ready"]:
		if not source.contains(needle):
			return _fail("Water concurrent action safety missing: %s" % needle)
	return true

func _validate_multi_game_retention_parity() -> bool:
	var save := root.get_node_or_null("SaveManager")
	var multi := root.get_node_or_null("MultiGameManager")
	var retention := root.get_node_or_null("RetentionManager")
	if save == null or multi == null or retention == null:
		return _fail("Shared managers missing during retention parity test")
	var backup: Dictionary = (save.get("data") as Dictionary).duplicate(true)
	save.call("reset_progress")
	multi.call("ensure_state")
	retention.call("ensure_state")
	var data: Dictionary = save.get("data") as Dictionary
	var before_weekly := int(data.get("weekly_points", 0))
	multi.call("complete_level", "water_sort", 1, 3, 0)
	data = save.get("data") as Dictionary
	var water_weekly := int(data.get("weekly_points", 0))
	multi.call("complete_level", "block_puzzle", 1, 3, 0)
	data = save.get("data") as Dictionary
	var block_weekly := int(data.get("weekly_points", 0))
	save.set("data", backup)
	save.call("save")
	if water_weekly <= before_weekly:
		return _fail("Water Sort completion does not advance shared retention")
	if block_weekly <= water_weekly:
		return _fail("Block Puzzle level with same number is incorrectly deduplicated against Water Sort")
	return true

func _validate_rewarded_result_state() -> bool:
	var source := _source("res://scripts/game/game.gd")
	if not source.contains('"WATCHING AD…"'):
		return _fail("Rescue rewarded result button has no loading state")
	if not source.contains('"BASE REWARD DOUBLED"') or not source.contains("on_failed"):
		return _fail("Rescue rewarded result does not update from explicit success/failure callbacks")
	var ads := _source("res://scripts/systems/ad_manager.gd")
	if not ads.contains("on_failed: Callable"):
		return _fail("AdManager rewarded API has no failure callback")
	return true

func _validate_shared_completion_overlay() -> bool:
	var block_source := _source("res://scripts/game/block_puzzle_ultra_motion.gd")
	var rescue_source := _source("res://scripts/game/game.gd")
	var overlay_source := _source("res://scripts/ui/premium_result_overlay.gd")
	if not block_source.contains("PremiumResultOverlay.new()"):
		return _fail("Active Block Puzzle completion bypasses shared premium result overlay")
	if not rescue_source.contains("PremiumResultOverlay.new()"):
		return _fail("Rescue Rush completion bypasses shared premium result overlay")
	if not overlay_source.contains("signal secondary_requested") or not overlay_source.contains("func configure_secondary"):
		return _fail("Shared premium result overlay cannot host rewarded secondary actions")
	var overlay := PremiumResultOverlay.new()
	overlay.configure("TEST COMPLETE", "Shared presentation", "3 MOVES", 3, Color.WHITE, "CONTINUE")
	overlay.configure_secondary("DOUBLE REWARD", true)
	root.add_child(overlay)
	await process_frame
	var secondary := overlay.find_child("SecondaryAction", true, false) as Button
	var ok := secondary != null and secondary.visible and secondary.text == "DOUBLE REWARD"
	overlay.queue_free()
	await process_frame
	if not ok:
		return _fail("Shared result overlay does not render its configured secondary action")
	return true

func _validate_help_does_not_overlap_game_footer() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	for game_id in ["water_sort", "block_puzzle"]:
		main.call("start_multi_level", game_id, 1, false)
		await _frames(10)
		var shell := main.get_node_or_null("UXShell")
		var help = shell.get("help_button") if shell != null else null
		if help != null and is_instance_valid(help) and help.visible:
			main.queue_free(); await process_frame
			return _fail("Retired floating Help button returned on %s Figma gameplay" % game_id)
		var game := main.get_node_or_null("ActiveGame") as Control
		var canvas_name := "FigmaWater390x844" if game_id == "water_sort" else "FigmaBlock390x844"
		var canvas := game.find_child(canvas_name, true, false) as Control if game != null else null
		var footer := _first_named_control(game, ["CompactGameActions", "CampaignBoosters"]) if game != null else null
		if game == null or canvas == null or footer == null:
			main.queue_free(); await process_frame
			return _fail("%s Figma gameplay/footer structure is incomplete" % game_id)
		if not canvas.get_global_rect().encloses(footer.get_global_rect()):
			main.queue_free(); await process_frame
			return _fail("%s footer escapes its audited Figma gameplay canvas" % game_id)
		main.call("build_home")
		await _frames(5)
	main.queue_free()
	await process_frame
	return true

func _first_named_control(node: Node, names: Array[String]) -> Control:
	if node is Control and String(node.name) in names:
		return node as Control
	for child in node.get_children():
		var found := _first_named_control(child, names)
		if found != null:
			return found
	return null

func _validate_primary_visual_occupancy() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	main.call("build_home")
	await _frames(6)

	var home := main.get_node_or_null("PremiumHome") as Control
	var canvas := home.find_child("FigmaHome390x844", true, false) as Control if home != null else null
	var hero := home.find_child("FigmaHomeHero", true, false) as Control if home != null else null
	var primary := home.find_child("HomePrimaryAction", true, false) as Control if home != null else null
	if canvas == null or hero == null or primary == null:
		main.queue_free(); await process_frame
		return _fail("Figma Home primary visual hierarchy is incomplete")
	if hero.size.distance_to(Vector2(346,224)) > 1.0:
		main.queue_free(); await process_frame
		return _fail("Figma Home hero drifted from audited 346x224 geometry")
	if hero.get_global_rect().size.x < 760.0 or hero.get_global_rect().size.y < 480.0:
		main.queue_free(); await process_frame
		return _fail("Figma Home hero no longer has dominant physical presence on 1080x1920")
	# In the audited Figma composition the primary CTA is intentionally embedded
	# inside the hero card (x41..219, y285..333) rather than sitting below it.
	# Guard containment instead of applying the retired non-overlap rule.
	if not hero.get_global_rect().encloses(primary.get_global_rect()):
		main.queue_free(); await process_frame
		return _fail("Figma Home primary action escapes its hero card")
	var hero_title := home.find_child("HomeHeroGameTitle", true, false) as Control
	var hero_preview := home.find_child("FigmaHomeHeroPreview", true, false) as Control
	if hero_title == null or hero_preview == null:
		main.queue_free(); await process_frame
		return _fail("Figma Home title/preview diagnostics are incomplete")
	if hero_title.get_global_rect().intersects(hero_preview.get_global_rect()):
		main.queue_free(); await process_frame
		return _fail("Figma Home game title overlaps its hero preview")

	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(10)
	var game := main.get_node_or_null("ActiveGame")
	var water_canvas := game.find_child("FigmaWater390x844", true, false) as Control if game != null else null
	var stage := game.find_child("GameplayStage", true, false) as Control if game != null else null
	var board = game.get("board") if game != null else null
	if water_canvas == null or stage == null or board == null or board.get_child_count() < 1:
		main.queue_free(); await process_frame
		return _fail("Water Sort Figma stage/board missing during visual occupancy check")
	if stage.size.distance_to(Vector2(354,420)) > 1.0:
		main.queue_free(); await process_frame
		return _fail("Water Sort stage drifted from audited 354x420 geometry")
	var tube := board.get_child(0) as Control
	if tube == null or tube.custom_minimum_size.x < 42.0 or tube.custom_minimum_size.y < 168.0:
		main.queue_free(); await process_frame
		return _fail("Water Sort bottles are below the audited Figma gameplay readability floor")
	main.queue_free()
	await process_frame
	return true

func _validate_figma_button_contrast() -> bool:
	var bright_orange := Color("#ff8c1f")
	var button := FigmaReferenceCanvas.premium_button("TEST", 12, Color.WHITE, bright_orange, 16)
	var resolved: Color = button.get_theme_color("font_color")
	button.free()
	if FigmaReferenceCanvas.contrast_ratio(resolved, bright_orange) < 4.5:
		return _fail("Shared Figma premium button allows sub-4.5:1 text contrast on bright orange")
	var direct := FigmaReferenceCanvas.accessible_text_color(Color.WHITE, bright_orange)
	if FigmaReferenceCanvas.contrast_ratio(direct, bright_orange) < 4.5:
		return _fail("Figma accessible_text_color does not meet the production contrast floor")
	return true

func _validate_header_badge_clearance() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	main.call("build_settings")
	await _frames(6)
	var title := main.find_child("FigmaHeaderTitle", true, false) as Control
	var subtitle := main.find_child("FigmaHeaderSubtitle", true, false) as Control
	var pill := main.find_child("FigmaHeaderPill", true, false) as Control
	if title == null or subtitle == null or pill == null:
		main.queue_free(); await process_frame
		return _fail("Shared Figma header diagnostics are incomplete")
	if title.get_global_rect().intersects(pill.get_global_rect()) or subtitle.get_global_rect().intersects(pill.get_global_rect()):
		main.queue_free(); await process_frame
		return _fail("Shared Figma header title/subtitle intrudes into the status pill")
	main.queue_free()
	await process_frame
	return true

func _validate_shop_header_clearance() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	var hub := main.get_node_or_null("MonetizationHub")
	if hub == null or not hub.has_method("open_shop"):
		main.queue_free(); await process_frame
		return _fail("Shop hub unavailable for header clearance check")
	hub.call("open_shop")
	await _frames(6)
	var title := main.find_child("ShopTitle3D", true, false) as Control
	var subtitle := main.find_child("ShopSubtitle", true, false) as Control
	var wallet := main.find_child("ShopCoinPill", true, false) as Control
	if title == null or subtitle == null or wallet == null:
		main.queue_free(); await process_frame
		return _fail("Shop header diagnostics are incomplete")
	if title.get_global_rect().intersects(wallet.get_global_rect()) or subtitle.get_global_rect().intersects(wallet.get_global_rect()):
		main.queue_free(); await process_frame
		return _fail("Shop header title/subtitle intrudes into the wallet pill")
	main.queue_free()
	await process_frame
	return true

func _validate_selector_header_and_navigation() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	main.call("_open_games_surface")
	await _frames(8)
	var title := main.find_child("SelectorTitle3D", true, false) as Control
	var subtitle := main.find_child("SelectorSubtitle", true, false) as Control
	var settings := main.find_child("SelectorSettingsButton", true, false) as Button
	var back := main.find_child("SelectorBackButton", true, false) as Button
	if title == null or subtitle == null or settings == null or back == null:
		main.queue_free(); await process_frame
		return _fail("Choose-a-Game header/navigation diagnostics are incomplete")
	if title.get_global_rect().intersects(settings.get_global_rect()) or subtitle.get_global_rect().intersects(settings.get_global_rect()):
		main.queue_free(); await process_frame
		return _fail("Choose-a-Game title/subtitle intrudes into Settings")
	if back.tooltip_text.is_empty() or settings.tooltip_text.is_empty():
		main.queue_free(); await process_frame
		return _fail("Choose-a-Game icon navigation lacks descriptive tooltips")
	main.queue_free()
	await process_frame
	return true

func _validate_exact_touch_target_floor() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	main.call("build_settings")
	await _frames(5)
	if not _figma_buttons_meet_floor(main, "Settings"):
		main.queue_free(); await process_frame
		return false
	main.set("selected_game_id", "block_puzzle")
	main.call("build_multi_level_select")
	await _frames(6)
	if not _figma_buttons_meet_floor(main, "Block level select"):
		main.queue_free(); await process_frame
		return false
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		hub.call("open_shop")
		await _frames(5)
		if not _figma_buttons_meet_floor(main, "Shop"):
			main.queue_free(); await process_frame
			return false
	main.queue_free()
	await process_frame
	return true

func _figma_buttons_meet_floor(node: Node, context: String) -> bool:
	for found in node.find_children("*", "Button", true, false):
		var button := found as Button
		if button == null or not button.visible or not bool(button.get_meta("unjam_figma_exact_geometry", false)):
			continue
		if button.size.x + 0.01 < 44.0 or button.size.y + 0.01 < 44.0:
			return _fail("%s exact button is below 44x44: %s %.1fx%.1f" % [context, button.name, button.size.x, button.size.y])
	return true

func _validate_dead_code_cleanup() -> bool:
	var retired := {
		"res://scripts/systems/hint_manager.gd": ["func can_afford_hint("],
		"res://scripts/core/multi_game_manager.gd": ["func can_start_daily("],
		"res://scripts/systems/economy_manager.gd": ["func collection_daily_reward("],
		"res://scripts/ui/device_fit.gd": ["func content_rect("],
		"res://scripts/ui/figma_reference_canvas.gd": ["func ref_rect("],
		"res://scripts/ui/premium_live_hub.gd": ["const DESCRIPTIONS"],
		"res://scripts/ui/unjam_3d_theme.gd": ["const DEEP_BLUE", "const PINK"],
		"res://scripts/game/block_puzzle_premium_layout.gd": ["const PREMIUM_CELL_MIN"],
		"res://scripts/ui/premium_main_casual.gd": ["const FIGMA_BG_MID", "const FIGMA_DARK_MID", "const FIGMA_PURPLE", "func _setting_button(", "func _daily_game_card(", "func _add_secondary_nav(", "func _journey_metric(", "func _collection_game_card(", "func _inject_block_modes(", "func _inject_journey_summary(", "func _continue_campaign("],
		"res://scripts/ui/premium_home_casual.gd": ["func _make_tagline(", "func _make_sign_stack("],
		"res://scripts/ui/premium_home_direct_levels.gd": ["func _open_game_levels(", "func _select_and_open_game("],
		"res://scripts/ui/ux_shell_casual.gd": ["func _layout_tutorial_panel(", "func _layout_help_button(", "func _restyle_3d_shell("],
		"res://scripts/ui/robust_main.gd": ["func _add_journey_card("],
		"res://scripts/game/water_sort_reference_motion.gd": ["func _transfer_amount("],
		"res://scripts/game/rescue_rush_polished.gd": ["func _route_from("],
		"res://scripts/ui/water_tube_button.gd": ["func _draw_round_rect_border("],
		"res://scripts/ui/monetization_hub_3d.gd": ["const SHOP_DARK_BG_TOP", "const SHOP_DARK_BG_MID", "const SHOP_DARK_BG_BOTTOM", "const SHOP_DARK_CARD", "const SHOP_DARK_INK", "const SHOP_DARK_MUTED"]
	}
	for dead_path in retired:
		var source := _source(dead_path)
		for token in retired[dead_path]:
			if source.contains(String(token)):
				return _fail("Verified dead source returned: %s in %s" % [token, dead_path])
	var tutorial := _source("res://scripts/ui/ux_shell_casual.gd")
	if not tutorial.contains("TUTORIAL_DARK_NEUTRAL_FALLBACK.lerp"):
		return _fail("Tutorial compatibility fallback became dead instead of serving the dark-scene contract")
	return true

func _validate_retention_failure_wiring() -> bool:
	var rescue := _source("res://scripts/game/game.gd")
	if rescue.count("RetentionManager.record_level_complete(") != 0:
		return _fail("Rescue Rush still double-records retention completion")
	if not rescue.contains("if not daily_mode:\n\t\tRetentionManager.record_level_fail()"):
		return _fail("Rescue Rush campaign failure does not reset the win streak")
	var water := _source("res://scripts/game/water_sort_10000.gd")
	if not water.contains("if not daily_mode:\n\t\tRetentionManager.record_level_fail()"):
		return _fail("Water Sort campaign failure does not reset the win streak")
	var block := _source("res://scripts/game/block_puzzle_10000.gd")
	if not block.contains("if not daily_mode and play_mode == \"campaign\":\n\t\tRetentionManager.record_level_fail()"):
		return _fail("Block Puzzle campaign failure does not reset the win streak")
	return true

func _validate_visual_workflow_installs_plugins() -> bool:
	var source := _source("res://.github/workflows/visual-audit.yml")
	if not source.contains("tools/install_monetization_plugins.sh"):
		return _fail("Visual audit workflow imports the project without monetization plugins")
	return true

func _validate_main_ci_runs_new_hardening_gates() -> bool:
	var source := _source("res://.github/workflows/godot-ci.yml")
	for needle in ["validate_production_hardening_regressions", "validate_water_constructive_solvability", "ObjectDB instances were leaked"]:
		if not source.contains(needle):
			return _fail("Main CI is missing production hardening gate: %s" % needle)
	return true

func _validate_release_workflow_exists() -> bool:
	var source := _source("res://.github/workflows/android-release.yml")
	if source.is_empty() or not source.contains("--export-release") or not source.contains("workflow_dispatch"):
		return _fail("Protected Android release workflow is missing")
	if not source.contains("version_code:") or not source.contains("VERSION_CODE"):
		return _fail("Release workflow does not require an explicit monotonic Play version code")
	if not source.contains('VERSION_CODE: ${{ inputs.version_code }}'):
		return _fail("Release workflow does not pass the requested Play version code into its configuration step")
	if source.contains("GITHUB_RUN_NUMBER"):
		return _fail("Release workflow still derives Play version code from workflow run number")
	if source.contains("STORE_PASSWORD") or source.contains("GODOT_ANDROID_KEYSTORE_RELEASE_STORE_PASSWORD"):
		return _fail("Release workflow uses an unsupported separate Android keystore store-password path")
	if not source.contains("validate_water_constructive_solvability"):
		return _fail("Release workflow skips the full Water Sort solvability gate")
	if not source.contains("keytool -list"):
		return _fail("Release workflow does not validate the keystore alias/password before export")
	return true

func _validate_retired_dead_code_removed() -> bool:
	for path in [
		"res://scripts/ui/water_sort_reference_backdrop.gd",
		"res://scripts/ui/game_showcase_art.gd",
		"res://scripts/ui/game_select_tile.gd",
		"res://scripts/ui/unjam_logo.gd",
		"res://scripts/ui/polished_block_piece_button.gd",
		"res://scripts/ui/level_browser_polish.gd",
		"res://scripts/ui/rescue_layout_polish.gd",
		"res://scripts/ui/water_stage_polish.gd",
		"res://scripts/ui/puzzle_casual_polish.gd"
	]:
		if FileAccess.file_exists(path):
			return _fail("Retired UI source is still shipped: %s" % path)
	return true

func _validate_audio_teardown_contract() -> bool:
	var feedback := root.get_node_or_null("FeedbackManager")
	if feedback == null or not feedback.has_method("shutdown_audio"):
		return _fail("FeedbackManager has no explicit audio teardown for deterministic visual/test shutdown")
	feedback.call("shutdown_audio")
	await process_frame
	var player = feedback.get("player")
	var music_player = feedback.get("music_player")
	if player != null and player.get("stream") != null:
		return _fail("FeedbackManager sound player retains a stream after shutdown")
	if music_player != null and music_player.get("stream") != null:
		return _fail("FeedbackManager music player retains a stream after shutdown")
	var capture := _source("res://tests/capture_visual_audit.gd")
	if not capture.contains('feedback.call("shutdown_audio")'):
		return _fail("Visual audit does not explicitly release generated audio before quitting")
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
