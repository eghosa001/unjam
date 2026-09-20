extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var specs := [
		["res://scenes/Game.tscn", "RescuePremiumFeedback"],
		["res://scenes/WaterSort.tscn", "WaterPremiumFeedback"],
		["res://scenes/BlockPuzzle.tscn", "BlockPremiumFeedback"],
	]
	for spec in specs:
		var packed := load(String(spec[0])) as PackedScene
		if packed == null:
			return _fail("Premium benchmark scene failed to load: %s" % String(spec[0]))
		var game := packed.instantiate() as Control
		root.add_child(game)
		await _frames(8)
		var feedback := game.find_child(String(spec[1]), true, false) as Control
		if feedback == null:
			return _fail("Missing premium gameplay feedback layer: %s" % String(spec[1]))
		if feedback.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return _fail("%s may intercept gameplay touches" % String(spec[1]))
		var feedback_center := feedback.size * 0.5
		feedback.call("show_banner", "PREMIUM FLOW", Color("#ffd166"), Vector2(feedback_center.x, feedback.size.y * 0.30), 190.0)
		feedback.call("show_ring", Vector2(feedback_center.x, feedback.size.y * 0.49), 92.0, Color("#67e8ff"))
		feedback.call("show_sweep", Rect2(Vector2(feedback.size.x * 0.18, feedback.size.y * 0.36), Vector2(feedback.size.x * 0.64, feedback.size.y * 0.16)), Color("#ff7a66"))
		await _frames(2)
		if feedback.find_child("PremiumGameplayBanner", true, false) == null:
			return _fail("%s failed to render its premium banner" % String(spec[1]))
		if feedback.find_child("PremiumGameplayRing", true, false) == null:
			return _fail("%s failed to render its local success ring" % String(spec[1]))
		if feedback.find_child("PremiumGameplaySweep", true, false) == null:
			return _fail("%s failed to render its local clear sweep" % String(spec[1]))
		game.queue_free()
		await _frames(2)

	var motion_source := _read("res://scripts/ui/motion_system.gd")
	for token in ["&\"micro\": 0.055", "&\"travel\": 0.19", "&\"pour\": 0.235", "&\"screen\": 0.12"]:
		if not motion_source.contains(token):
			return _fail("Premium response timing missing: %s" % token)
	var audio_source := _read("res://scripts/systems/feedback_manager.gd")
	if not audio_source.contains("func snap()") or not audio_source.contains("_vibrate(7)") or not audio_source.contains("MUSIC_DURATION := 32.0"):
		return _fail("Premium snap/pour haptics or longer calm music phrase is missing")
	var drag_source := _read("res://scripts/ui/block_drag_preview.gd")
	if not drag_source.contains("became_valid") or not drag_source.contains("feedback.call(\"snap\")"):
		return _fail("Block Puzzle magnetic snap confirmation is missing")
	var restore_source := _read("res://scripts/game/block_puzzle_polished.gd")
	if restore_source.contains("pieces[i] = [Vector2i(0,0)]"):
		return _fail("Block Puzzle checkpoint restore still fabricates a rescue piece")
	var block_campaign_source := _read("res://scripts/game/block_puzzle_10000.gd")
	if block_campaign_source.contains("pieces[0] = CampaignGenerator.SHAPES[0].duplicate()"):
		return _fail("Block Puzzle free modes still fabricate a rescue piece after a dead end")
	if not block_campaign_source.contains('call_deferred("_handle_no_legal_moves")'):
		return _fail("Block Puzzle free-mode dead ends are not routed to the explicit failure/reset handler")
	var water_3d_source := _read("res://scripts/ui/water_tube_3d_motion.gd")
	if water_3d_source.contains("GlassSecondaryHighlight") or water_3d_source.contains("highlight_mesh := BoxMesh.new()"):
		return _fail("Water Sort still contains synthetic vertical glass highlight bars")

	var home_source := _read("res://scripts/ui/premium_home_direct_levels.gd")
	if not home_source.contains("HomeWorldProgress") or not home_source.contains("HomeWorldProgressBar"):
		return _fail("Home still lacks useful current-world progress in its open middle area")
	var water_base_source := _read("res://scripts/game/water_sort.gd")
	if not water_base_source.contains("Tap a tube, then a destination"):
		return _fail("Compact Water Sort guidance was not shortened for phone readability")

	var water_ui_source := _read("res://scripts/game/water_sort_casual.gd")
	if not water_ui_source.contains("ratio := 3.8") or not water_ui_source.contains("preferred_width := 60.0"):
		return _fail("Water Sort still lacks premium chunkier bottle proportions")
	var tube_source := _read("res://scripts/ui/water_tube_button.gd")
	if not tube_source.contains("side_inset := clampf(size.x * 0.10") or not tube_source.contains("cavity_side := clampf"):
		return _fail("Water bottle geometry is not scaling with compact/late-game slot width")
	var tray_source := _read("res://scripts/ui/block_piece_button.gd")
	if not tray_source.contains("minf(32.0, fit_cell)") or not tray_source.contains("size.x - 10.0"):
		return _fail("Block Puzzle tray pieces are still undersized against the board")
	var rescue_ui_source := _read("res://scripts/game/rescue_rush_casual.gd")
	if not rescue_ui_source.contains("set_rect(actions,21,638,346,62)"):
		return _fail("Rescue controls are not in the premium thumb-zone position")
	var performance_source := _read("res://scripts/systems/robust_premium_visuals.gd")
	if not performance_source.contains("_set_quality(0.75)") or not performance_source.contains("_set_quality(0.50)") or not performance_source.contains("fps < 53"):
		return _fail("Three-tier low-end effects scaling is missing")

	var water_source := _read("res://scripts/game/water_sort_10000.gd")
	if not water_source.contains("PERFECT TUBE") or not water_source.contains("_pour_flow_streak") or not water_source.contains("_show_level_intro"):
		return _fail("Water Sort premium flow/milestone feature is missing")
	var sequence_index := water_source.find("_pour_feedback_sequence += 1")
	var await_index := water_source.find("await super._play_premium_concurrent_pour")
	if sequence_index < 0 or await_index < 0 or sequence_index > await_index:
		return _fail("Water flow accounting must advance before concurrent pour animation awaits")
	if not water_source.contains("_last_rendered_pour_feedback_sequence") or not water_source.contains("streak_for_feedback"):
		return _fail("Water feedback must suppress stale async completions")
	var rescue_source := _read("res://scripts/game/rescue_rush_assisted.gd")
	if not rescue_source.contains("FLOW ×%d") or not rescue_source.contains("show_ring") or not rescue_source.contains("_show_level_intro"):
		return _fail("Rescue Rush premium flow/milestone feedback is missing")
	if not rescue_source.contains("local_bottom_right") or not rescue_source.contains("local_size"):
		return _fail("Rescue blocked-path ring must use transformed board size")
	var block_source := _read("res://scripts/game/block_puzzle_10000.gd")
	if not block_source.contains("LINE BLAST") or not block_source.contains("show_sweep") or not block_source.contains("_show_level_intro"):
		return _fail("Block Puzzle premium combo/milestone feedback is missing")

	print("PREMIUM_BENCHMARK_FEATURES_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
