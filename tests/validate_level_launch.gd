extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene could not be loaded")
		return
	var main := packed.instantiate() as Control
	if main == null:
		_fail("Main scene could not be instantiated")
		return
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(3)

	main.call("start_level", 1)
	await _frames(4)
	if not _validate_rescue(main): return

	main.call("build_home")
	await _frames(2)
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(4)
	if not _validate_water(main): return

	main.call("build_home")
	await _frames(2)
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(4)
	if not _validate_block(main): return

	print("All Level 1 launches validated: Rescue Rush, Water Sort and Block Puzzle render visible interactive gameplay.")
	main.queue_free()
	await process_frame
	quit(0)

func _validate_common(main: Control, game_name: String) -> Control:
	var game := main.get_node_or_null("ActiveGame") as Control
	if game == null:
		_fail("%s Level 1 did not create ActiveGame" % game_name)
		return null
	if not game.visible or not game.is_visible_in_tree():
		_fail("%s ActiveGame is not visible" % game_name)
		return null
	if game.size.x <= 1.0 or game.size.y <= 1.0:
		_fail("%s ActiveGame has invalid viewport size: %s" % [game_name, str(game.size)])
		return null
	if game.modulate.a < 0.5:
		_fail("%s ActiveGame is effectively transparent" % game_name)
		return null
	return game

func _validate_rescue(main: Control) -> bool:
	var game := _validate_common(main, "Rescue Rush")
	if game == null: return false
	var board_grid = game.get("board_grid")
	if board_grid == null or not board_grid is GridContainer or board_grid.get_child_count() <= 0:
		_fail("Rescue Rush gameplay board was not rendered")
		return false
	var level_data = game.get("level_data")
	if not level_data is Dictionary or level_data.is_empty():
		_fail("Rescue Rush Level 1 data was not loaded")
		return false
	return true

func _validate_water(main: Control) -> bool:
	var game := _validate_common(main, "Water Sort")
	if game == null: return false
	var board = game.get("board")
	if board == null or not board is GridContainer:
		_fail("Water Sort board was not initialized")
		return false
	var tubes = game.get("tubes")
	if not tubes is Array or tubes.is_empty():
		_fail("Water Sort Level 1 generated no tube data")
		return false
	if tubes.size() < 5:
		_fail("Water Sort Level 1 generated too few tubes: %d" % tubes.size())
		return false
	if board.get_child_count() != tubes.size():
		_fail("Water Sort rendered %d tubes for %d generated tubes" % [board.get_child_count(), tubes.size()])
		return false
	return true

func _validate_block(main: Control) -> bool:
	var game := _validate_common(main, "Block Puzzle")
	if game == null: return false
	var cell_buttons = game.get("cell_buttons")
	if not cell_buttons is Array or cell_buttons.size() != 64:
		_fail("Block Puzzle did not render an 8x8 board")
		return false
	var pieces = game.get("pieces")
	if not pieces is Array or pieces.size() != 3:
		_fail("Block Puzzle did not generate its three playable pieces")
		return false
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
