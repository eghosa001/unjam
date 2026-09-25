extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene is missing")
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(6)

	main.call("start_multi_level", "water_sort", 7, false)
	await _frames(5)
	main.set("selected_game_id", "block_puzzle")
	main.call("force_back_from_game")
	await _frames(4)
	if String(main.get("selected_game_id")) != "water_sort" or String(main.get("current_surface")) != "levels":
		return _fail("Back from Water Sort followed stale game selection")

	main.call("start_level", 3)
	await _frames(5)
	main.set("selected_game_id", "water_sort")
	main.call("force_back_from_game")
	await _frames(4)
	if String(main.get("selected_game_id")) != "rescue_rush" or String(main.get("current_surface")) != "levels":
		return _fail("Back from Rescue Rush followed stale game selection")

	var block_source := _read("res://scripts/game/block_puzzle.gd")
	var water_source := _read("res://scripts/game/water_sort_casual.gd")
	var rescue_source := _read("res://scripts/game/rescue_rush_casual.gd")
	if not block_source.contains("back.text = \"←\""):
		return _fail("Block Puzzle back glyph is inconsistent")
	if not water_source.contains("premium_button(\"←\""):
		return _fail("Water Sort back glyph is inconsistent")
	if not rescue_source.contains("premium_button(\"←\""):
		return _fail("Rescue Rush back glyph is inconsistent")

	print("GAME_BACK_CONSISTENCY_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
