extends SceneTree

const OUT_DIR := "res://build/visual-audit"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Main.tscn for visual audit")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _settle(8)

	var shell := main.get_node_or_null("UXShell")
	await _set_theme(shell, "dark")
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1":
		await _run_fast_visual_audit(main, shell)
		await _shutdown_visual_audit()
		return

	main.call("build_home")
	await _capture("01-home-dark")
	var home := main.get_node_or_null("PremiumHome")
	if home != null:
		var water_switch := home.find_child("HomeDirect_water_sort",true,false) as Button
		if water_switch != null:
			water_switch.pressed.emit()
			await _settle(3)
			await _capture("01b-home-water-dark")
		var block_switch := home.find_child("HomeDirect_block_puzzle",true,false) as Button
		if block_switch != null:
			block_switch.pressed.emit()
			await _settle(3)
			await _capture("01c-home-block-dark")
		var rescue_switch := home.find_child("HomeDirect_rescue_rush",true,false) as Button
		if rescue_switch != null:
			rescue_switch.pressed.emit()
			await _settle(2)

	main.set("current_surface", "live")
	await _capture("02-live-dark")

	# Capture the game selector at the smallest supported portrait class too.
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.set("current_surface", "live")
	if main.has_signal("surface_changed"):
		main.emit_signal("surface_changed", "live")
	await _capture("02b-live-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	main.call("build_level_select")
	await _capture("03-levels-rescue-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.call("build_level_select")
	await _capture("03b-levels-rescue-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	main.set("selected_game_id", "water_sort")
	main.set("selected_multi_world", 1)
	main.call("build_multi_level_select")
	await _capture("04-levels-water-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.call("build_multi_level_select")
	await _capture("04b-levels-water-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	main.call("build_collection")
	await _capture("05-collection-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.call("build_collection")
	await _capture("05b-collection-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	main.call("build_daily_games")
	await _capture("05c-daily-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.call("build_daily_games")
	await _capture("05d-daily-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	if main.has_method("build_collection_upgrades"):
		main.call("build_collection_upgrades")
		await _capture("05e-collection-upgrades-dark")
		root.size = Vector2i(540, 960)
		await _settle(8)
		main.call("build_collection_upgrades")
		await _capture("05f-collection-upgrades-540x960-dark")
		root.size = Vector2i(1080, 1920)
		await _settle(8)

	main.call("build_settings")
	await _capture("06-settings-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.call("build_settings")
	await _capture("06b-settings-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	var shop := main.get_node_or_null("MonetizationHub")
	if shop != null and shop.has_method("open_shop"):
		shop.call("open_shop")
		await _capture("06c-shop-dark")
		root.size = Vector2i(540, 960)
		await _settle(8)
		await _capture("06d-shop-540x960-dark")
		root.size = Vector2i(1080, 1920)
		await _settle(6)
		if shop.has_method("_close_shop"):
			shop.call("_close_shop")
			await _settle(4)

	var coin_prompt := main.get_node_or_null("InsufficientCoinsPrompt")
	if coin_prompt != null and coin_prompt.has_method("show_for"):
		var economy := root.get_node_or_null("EconomyManager")
		var balance := int(economy.call("balance")) if economy != null and economy.has_method("balance") else 0
		coin_prompt.call("show_for", "HINT", balance + 25)
		await _capture("06e-insufficient-coins-dark")
		root.size = Vector2i(540, 960)
		await _settle(8)
		await _capture("06f-insufficient-coins-540x960-dark")
		var coin_overlay = coin_prompt.get("overlay")
		if coin_overlay != null and is_instance_valid(coin_overlay):
			coin_overlay.visible = false
		root.size = Vector2i(1080, 1920)
		await _settle(6)

	await _set_theme(shell, "light")
	main.call("build_home")
	await _capture("07-home-light")
	main.call("build_settings")
	await _capture("08-settings-light")

	await _set_theme(shell, "dark")

	main.call("start_level", 1)
	await _settle(8)
	_hide_tutorial(shell)
	await _capture("09-game-rescue")
	root.size = Vector2i(540, 960)
	await _settle(8)
	await _capture("09b-game-rescue-540x960")
	var rescue_game = main.get("active_game")
	if rescue_game != null and is_instance_valid(rescue_game):
		var rescue_feedback: Control = rescue_game.find_child("RescuePremiumFeedback", true, false) as Control
		if rescue_feedback != null:
			var rescue_center: Vector2 = rescue_feedback.size * 0.5
			rescue_feedback.call("show_banner", "FLOW ×3", Color("#21c763"), Vector2(rescue_center.x, rescue_feedback.size.y * 0.30), 184.0)
			rescue_feedback.call("show_ring", Vector2(rescue_center.x, rescue_feedback.size.y * 0.49), 120.0, Color("#67e8ff"))
			await _settle(2)
			await _capture("09e-game-rescue-premium-feedback-540x960")

	if rescue_game != null and is_instance_valid(rescue_game):
		var legal_index := -1
		var rescue_pieces: Array = rescue_game.get("pieces")
		for i in range(rescue_pieces.size()):
			if bool(rescue_game.call("is_path_clear", i)):
				legal_index = i
				break
		if legal_index >= 0:
			rescue_game.call("try_move", legal_index)
			if await _wait_for_named_motion(rescue_game, "RescueEscapeGhost", 90):
				await _capture("09c-game-rescue-motion-540x960")
			else:
				push_error("Rescue motion capture never exposed RescueEscapeGhost")
			await _wait_until_rescue_unlocked(rescue_game)
		var active_before := 0
		for raw in (rescue_game.get("pieces") as Array):
			if raw is Dictionary and bool((raw as Dictionary).get("active",true)):
				active_before += 1
		rescue_game.call("show_hint")
		await _settle(14)
		var active_after := 0
		for raw in (rescue_game.get("pieces") as Array):
			if raw is Dictionary and bool((raw as Dictionary).get("active",true)):
				active_after += 1
		if active_after >= active_before:
			push_error("Rescue visual audit hint did not remove an arrow")
		await _capture("09d-game-rescue-hint-removal-540x960")
	# Endgame Rescue Rush must remain readable on a compact phone. Capture the
	# actual Level 10,000 board and its milestone treatment, not only Level 1.
	main.call("start_level", 10000)
	await _settle(3)
	_hide_tutorial(shell)
	await _capture("09f-game-rescue-level10000-540x960")
	await _settle(8)
	var late_rescue = main.get("active_game")
	if late_rescue == null or not is_instance_valid(late_rescue):
		push_error("Late Rescue Rush did not launch for visual audit")
	root.size = Vector2i(1080, 1920)
	await _settle(6)

	main.call("start_multi_level", "water_sort", 1, false)
	await _settle(8)
	_hide_tutorial(shell)
	await _capture("10-game-water")
	root.size = Vector2i(540, 960)
	await _settle(8)
	await _capture("10b-game-water-540x960")
	var water_game = main.get("active_game")
	if water_game != null and is_instance_valid(water_game):
		var water_feedback: Control = water_game.find_child("WaterPremiumFeedback", true, false) as Control
		if water_feedback != null:
			var water_center: Vector2 = water_feedback.size * 0.5
			water_feedback.call("show_banner", "PERFECT TUBE", Color("#19b9ff"), Vector2(water_center.x, water_feedback.size.y * 0.30), 194.0)
			water_feedback.call("show_ring", Vector2(water_center.x, water_feedback.size.y * 0.49), 104.0, Color("#67e8ff"))
			await _settle(2)
			await _capture("10e-game-water-premium-feedback-540x960")

	if water_game != null and is_instance_valid(water_game) and bool(water_game.call("can_show_hint")):
		water_game.call("show_hint")
		if await _wait_for_named_motion(water_game, "PourStream", 120):
			await _capture("10c-game-water-pouring-540x960")
		else:
			push_error("Water motion capture never exposed PourStream")
		await _wait_until_water_idle(water_game)
		await _capture("10d-game-water-settled-540x960")

	# Late Water Sort levels can render 13–14 generated bottles. Keep an exact
	# compact-phone evidence frame so future layout changes cannot reintroduce
	# the lower-layer overlap fixed by the 15-tube-safe fitter.
	main.call("start_multi_level", "water_sort", 10000, false)
	await _settle(12)
	_hide_tutorial(shell)
	await _capture("10f-game-water-level10000-540x960")
	var late_water = main.get("active_game")
	if late_water != null and is_instance_valid(late_water):
		var late_board := late_water.get("board") as GridContainer
		if late_board == null or late_board.position.y < 169.0 or late_board.position.y + late_board.size.y > 589.5:
			push_error("Late Water Sort board escaped the compact gameplay stage")
	root.size = Vector2i(1080, 1920)
	await _settle(6)

	main.call("start_multi_level", "block_puzzle", 1, false)
	await _settle(8)
	_hide_tutorial(shell)
	await _capture("11-game-block")
	root.size = Vector2i(540, 960)
	await _settle(8)
	await _capture("11b-game-block-540x960")
	var block_game = main.get("active_game")
	if block_game != null and is_instance_valid(block_game):
		var block_feedback: Control = block_game.find_child("BlockPremiumFeedback", true, false) as Control
		if block_feedback != null:
			var block_center: Vector2 = block_feedback.size * 0.5
			var block_sweep_rect := Rect2(
				Vector2(block_feedback.size.x * 0.15, block_feedback.size.y * 0.30),
				Vector2(block_feedback.size.x * 0.70, block_feedback.size.y * 0.34)
			)
			block_feedback.call("show_banner", "COMBO ×3", Color("#ffd166"), Vector2(block_center.x, block_feedback.size.y * 0.24), 184.0)
			block_feedback.call("show_sweep", block_sweep_rect, Color("#ff7a66"))
			await _settle(2)
			await _capture("11c-game-block-premium-feedback-540x960")
	# Block Puzzle late-game boards add occupancy/objective pressure. Keep a
	# compact Level 10,000 frame so tray, boosters, board and milestone banner are
	# reviewed together under maximum progression complexity.
	main.call("start_multi_level", "block_puzzle", 10000, false)
	await _settle(3)
	_hide_tutorial(shell)
	await _capture("11d-game-block-level10000-540x960")
	await _settle(8)
	var late_block = main.get("active_game")
	if late_block == null or not is_instance_valid(late_block):
		push_error("Late Block Puzzle did not launch for visual audit")
	root.size = Vector2i(1080, 1920)
	await _settle(6)

	main.call("force_back_from_game")
	main.set("selected_game_id", "block_puzzle")
	main.set("selected_multi_world", 1)
	main.call("build_multi_level_select")
	await _capture("12-levels-block-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	main.call("build_multi_level_select")
	await _capture("12b-levels-block-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)

	await _set_theme(shell, "light")
	main.call("build_collection")
	await _capture("13-collection-light")
	main.set("current_surface", "live")
	await _capture("14-live-light")

	await _set_theme(shell, "dark")
	main.call("start_level", 1)
	await _settle(8)
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", "rescue_rush")
	await _capture("15-tutorial-rescue-dark")
	root.size = Vector2i(540, 960)
	await _settle(8)
	await _capture("15b-tutorial-540x960-dark")
	root.size = Vector2i(1080, 1920)
	await _settle(8)
	_hide_tutorial(shell)

	var result := PremiumResultOverlay.new()
	result.configure(
		"LEVEL COMPLETE",
		"Clean play. Strong route. Keep the streak moving.",
		"7 MOVES   •   PERFECT ≤ 8\n1 RESCUE SECURED",
		3,
		Color("2dd4b6"),
		"NEXT PUZZLE"
	)
	main.add_child(result)
	await _capture("16-result-overlay-dark")
	result.queue_free()
	await _settle(3)

	root.size = Vector2i(540, 960)
	await _settle(6)
	var compact_result := PremiumResultOverlay.new()
	compact_result.configure(
		"LEVEL COMPLETE",
		"Clean play. Strong route. Keep the streak moving.",
		"7 MOVES   •   PERFECT ≤ 8\n1 RESCUE SECURED",
		3,
		Color("2dd4b6"),
		"NEXT PUZZLE"
	)
	main.add_child(compact_result)
	await _capture("16b-result-540x960-dark")
	compact_result.queue_free()
	root.size = Vector2i(1080, 1920)
	await _settle(3)

	print("Visual audit captures written to %s" % OUT_DIR)
	await _shutdown_visual_audit()

func _run_fast_visual_audit(main: Node, shell: Node) -> void:
	# PR loop: capture only the highest-signal compact states. The manual Visual UI
	# Audit intentionally continues through the full matrix above.
	main.call("build_home")
	await _capture("01-home-dark")

	root.size = Vector2i(540, 960)
	await _settle(4)
	main.call("start_level", 1)
	await _settle(5)
	_hide_tutorial(shell)
	var rescue_game = main.get("active_game")
	if rescue_game != null and is_instance_valid(rescue_game):
		var legal_index := -1
		var rescue_pieces: Array = rescue_game.get("pieces")
		for i in range(rescue_pieces.size()):
			if bool(rescue_game.call("is_path_clear", i)):
				legal_index = i
				break
		if legal_index >= 0:
			rescue_game.call("try_move", legal_index)
			if await _wait_for_named_motion(rescue_game, "RescueEscapeGhost", 90):
				await _capture("09c-game-rescue-motion-540x960")
			else:
				push_error("Fast visual audit never exposed RescueEscapeGhost")
	else:
		push_error("Fast visual audit could not launch Rescue Rush")

	main.call("start_multi_level", "water_sort", 1, false)
	await _settle(5)
	_hide_tutorial(shell)
	var water_game = main.get("active_game")
	if water_game != null and is_instance_valid(water_game) and bool(water_game.call("can_show_hint")):
		water_game.call("show_hint")
		if await _wait_for_named_motion(water_game, "PourStream", 120):
			await _capture("10c-game-water-pouring-540x960")
		else:
			push_error("Fast visual audit never exposed PourStream")
	else:
		push_error("Fast visual audit could not launch a hintable Water Sort board")

	main.call("start_multi_level", "block_puzzle", 1, false)
	await _settle(5)
	_hide_tutorial(shell)
	var block_game = main.get("active_game")
	if block_game != null and is_instance_valid(block_game):
		var block_status := block_game.get("status_label") as Label
		var block_hint := block_game.get("hint_label") as Label
		if block_status != null:
			block_status.text = "Choose a block"
		if block_hint != null:
			block_hint.text = "Release when the preview locks into place"
	await _capture("11-game-block")

	main.call("start_level", 1)
	await _settle(5)
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", "rescue_rush")
	await _capture("15b-tutorial-540x960-dark")
	_hide_tutorial(shell)

	var compact_result := PremiumResultOverlay.new()
	compact_result.configure(
		"LEVEL COMPLETE",
		"Clean play. Strong route. Keep the streak moving.",
		"7 MOVES   •   PERFECT ≤ 8\n1 RESCUE SECURED",
		3,
		Color("2dd4b6"),
		"NEXT PUZZLE"
	)
	main.add_child(compact_result)
	await _capture("16b-result-540x960-dark")
	compact_result.queue_free()
	await _settle(2)
	print("Fast visual audit captures written to %s" % OUT_DIR)

func _shutdown_visual_audit() -> void:
	# The visual runner synthesizes music through FeedbackManager. Release the
	# generated stream/player before SceneTree quits so leak diagnostics remain
	# meaningful instead of reporting the intentionally persistent autoload.
	var feedback := root.get_node_or_null("FeedbackManager")
	if feedback != null and feedback.has_method("shutdown_audio"):
		feedback.call("shutdown_audio")
	await _settle(3)
	quit(0)

func _set_theme(shell: Node, mode: String) -> void:
	if shell == null:
		return
	shell.set("theme_mode", mode)
	if shell.has_method("_apply_theme"):
		shell.call("_apply_theme")
	await _settle(4)

func _hide_tutorial(shell: Node) -> void:
	if shell == null:
		return
	var panel = shell.get("tutorial_panel")
	if panel != null and is_instance_valid(panel) and panel.visible and shell.has_method("hide_tutorial"):
		shell.call("hide_tutorial")

func _wait_for_named_motion(game: Node, node_name: String, max_frames: int) -> bool:
	for _i in range(max_frames):
		if game == null or not is_instance_valid(game):
			return false
		var motion := game.find_child(node_name, true, false)
		if motion != null and is_instance_valid(motion):
			return true
		await process_frame
	return false

func _wait_until_rescue_unlocked(game: Node, max_frames: int = 180) -> void:
	for _i in range(max_frames):
		if game == null or not is_instance_valid(game):
			return
		if not bool(game.get("board_locked")):
			return
		await process_frame

func _wait_until_water_idle(game: Node, max_frames: int = 240) -> void:
	for _i in range(max_frames):
		if game == null or not is_instance_valid(game):
			return
		if not bool(game.call("_has_active_pours")):
			return
		await process_frame

func _settle(frames: int = 5) -> void:
	for _i in range(frames):
		await process_frame

func _capture(name: String) -> void:
	await _settle(7)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Visual audit capture failed for %s" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save visual audit capture %s: %s" % [name, error_string(err)])
	else:
		print("Captured %s" % path)
