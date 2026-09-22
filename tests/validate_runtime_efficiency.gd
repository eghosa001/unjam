extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _water_controls_are_reused():
		return
	if not await _rescue_refresh_is_settled():
		return
	if not _dead_helpers_are_gone():
		return
	print("RUNTIME_EFFICIENCY_OK: stable Water controls, settled Rescue refreshes, and retired UI helpers removed.")
	quit(0)

func _water_controls_are_reused() -> bool:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var board = game.get("board") as GridContainer
	if board == null or board.get_child_count() == 0:
		game.queue_free()
		return _fail("Water Sort board did not render")
	var before: Array[int] = []
	for child in board.get_children():
		before.append(child.get_instance_id())
	game.call("render_board")
	var after: Array[int] = []
	for child in board.get_children():
		after.append(child.get_instance_id())
	if before != after:
		game.queue_free()
		return _fail("Water Sort rebuilt bottle controls during an unchanged render")
	game.queue_free()
	await process_frame
	return true

func _rescue_refresh_is_settled() -> bool:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue Rush scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	if not bool(game.get("_board_has_rendered")):
		game.queue_free()
		return _fail("Rescue Rush did not mark initial board render complete")
	game.call("render_board")
	var board = game.get("board_grid") as GridContainer
	if board == null:
		game.queue_free()
		return _fail("Rescue Rush board missing")
	for child in board.get_children():
		if child is Control:
			var control := child as Control
			if control.modulate.a < 0.99 or control.scale.distance_to(Vector2.ONE) > 0.01:
				game.queue_free()
				return _fail("Rescue Rush replayed full-board entrance animation during refresh")
	game.queue_free()
	await process_frame
	return true

func _dead_helpers_are_gone() -> bool:
	var paths := [
		"res://scripts/ui/robust_main.gd",
		"res://scripts/ui/premium_main_casual.gd",
	]
	var retired := [
		"_add_game_card",
		"_change_multi_world",
		"_restyle_secondary_nav",
		"_inject_game_tabs",
		"_add_surface_diorama",
		"_find_page_root",
	]
	var combined := ""
	for path in paths:
		combined += FileAccess.get_file_as_string(path)
	for name in retired:
		if ("func %s(" % name) in combined:
			return _fail("Retired helper still exists: %s" % name)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
