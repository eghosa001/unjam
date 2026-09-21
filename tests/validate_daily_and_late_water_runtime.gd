extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	var multi_game_manager := root.get_node_or_null("/root/MultiGameManager")
	if save_manager == null or multi_game_manager == null:
		push_error("Required gameplay autoloads are unavailable")
		quit(1)
		return

	var original: Dictionary = (save_manager.get("data") as Dictionary).duplicate(true)
	var data: Dictionary = (save_manager.get("data") as Dictionary)
	data["daily_game_choices"] = {}
	save_manager.set("data", data)
	multi_game_manager.call("ensure_state")
	for game_id in ["water_sort", "block_puzzle", "rescue_rush"]:
		if not bool(multi_game_manager.call("claim_daily_game", game_id)):
			return _fail(save_manager, original, "Daily game should be independently playable: %s" % game_id)
	var started: Array = multi_game_manager.call("daily_started_games")
	for game_id in ["water_sort", "block_puzzle", "rescue_rush"]:
		if game_id not in started:
			return _fail(save_manager, original, "Daily start state did not preserve %s" % game_id)
	if not bool(multi_game_manager.call("claim_daily_game", "water_sort")):
		return _fail(save_manager, original, "Re-entering an unfinished daily game should remain allowed")

	# UI state must remain independent even after one game is completed.
	var main_packed := load("res://scenes/Main.tscn") as PackedScene
	if main_packed == null:
		return _fail(save_manager, original, "Main scene missing for Daily UI regression")
	var main := main_packed.instantiate() as Control
	root.add_child(main)
	await _frames(6)
	if not main.has_method("_daily_ui_state"):
		return _fail(save_manager, original, "Daily UI state helper unavailable")
	for game_id in ["water_sort", "block_puzzle", "rescue_rush"]:
		var state: Dictionary = main.call("_daily_ui_state", game_id, Color.WHITE)
		if bool(state.get("disabled", true)):
			return _fail(save_manager, original, "Starting one Daily game disabled %s" % game_id)
	if not bool(multi_game_manager.call("complete_daily", "water_sort", 0)):
		return _fail(save_manager, original, "Could not complete Water Daily for independence regression")
	var water_state: Dictionary = main.call("_daily_ui_state", "water_sort", Color.WHITE)
	var block_state: Dictionary = main.call("_daily_ui_state", "block_puzzle", Color.WHITE)
	var rescue_state: Dictionary = main.call("_daily_ui_state", "rescue_rush", Color.WHITE)
	if not bool(water_state.get("disabled", false)):
		return _fail(save_manager, original, "Completed Water Daily should disable only itself")
	if bool(block_state.get("disabled", true)) or bool(rescue_state.get("disabled", true)):
		return _fail(save_manager, original, "Completing Water Daily disabled another Daily game")
	main.queue_free()
	await process_frame

	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail(save_manager, original, "Water Sort scene missing")
	var water := packed.instantiate()
	water.set("level_number", 1)
	root.add_child(water)
	current_scene = water
	await _frames(8)

	var synthetic: Array = []
	for i in range(15):
		synthetic.append([] if i >= 12 else [i % 12])
	water.set("tubes", synthetic)
	water.call("render_board")
	await _frames(4)
	var board := water.get("board") as GridContainer
	if board == null:
		return _fail(save_manager, original, "Water Sort board missing")
	var stage_rect := Rect2(31.0, 169.0, 326.0, 420.0)
	var board_rect := Rect2(board.position, board.size)
	if board_rect.position.y < stage_rect.position.y - 0.5 or board_rect.end.y > stage_rect.end.y + 0.5:
		return _fail(save_manager, original, "15-tube layout exceeds gameplay stage: %s" % str(board_rect))
	if board_rect.position.x < stage_rect.position.x - 1.0 or board_rect.end.x > stage_rect.end.x + 1.0:
		return _fail(save_manager, original, "15-tube layout exceeds stage width: %s" % str(board_rect))

	water.queue_free()
	save_manager.set("data", original)
	save_manager.call("save")
	await process_frame
	print("DAILY_AND_LATE_WATER_RUNTIME_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(save_manager: Node, original: Dictionary, message: String) -> bool:
	save_manager.set("data", original)
	save_manager.call("save")
	push_error(message)
	quit(1)
	return false
