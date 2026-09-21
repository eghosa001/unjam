extends "res://tests/capture_visual_audit.gd"

# Minimal rendered regression evidence for the inner implementation loop.
# The full capture_visual_audit.gd remains the manual/release visual audit.
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/visual-audit"))
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Main.tscn for fast visual audit")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _settle(5)

	var shell := main.get_node_or_null("UXShell")
	await _set_theme(shell, "dark")

	# Home: glossy hierarchy and world-progress shell.
	main.call("build_home")
	await _capture("01-home-dark")

	# Rescue Rush: compact-phone motion frame.
	main.call("start_level", 1)
	await _settle(5)
	_hide_tutorial(shell)
	root.size = Vector2i(540, 960)
	await _settle(5)
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
				push_error("Fast Rescue capture never exposed RescueEscapeGhost")
		await _wait_until_rescue_unlocked(rescue_game)

	# Water Sort: bottle silhouette and live stream are the high-risk visual state.
	main.call("start_multi_level", "water_sort", 1, false)
	await _settle(5)
	_hide_tutorial(shell)
	var water_game = main.get("active_game")
	if water_game != null and is_instance_valid(water_game) and bool(water_game.call("can_show_hint")):
		water_game.call("show_hint")
		if await _wait_for_named_motion(water_game, "PourStream", 120):
			await _capture("10c-game-water-pouring-540x960")
		else:
			push_error("Fast Water capture never exposed PourStream")
		await _wait_until_water_idle(water_game)

	# Block Puzzle: compact phone is the important tray/board fit gate.
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _settle(5)
	_hide_tutorial(shell)
	await _capture("11b-game-block-540x960")

	# Tutorial and result overlays: collision/readability regressions.
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

	var feedback := root.get_node_or_null("FeedbackManager")
	if feedback != null and feedback.has_method("shutdown_audio"):
		feedback.call("shutdown_audio")
	await _settle(2)
	print("Fast visual audit captures written to res://build/visual-audit")
	quit()
