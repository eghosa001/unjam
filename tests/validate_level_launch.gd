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
	await process_frame
	await process_frame
	main.call("start_level", 1)
	await process_frame
	await process_frame
	await process_frame
	var game := main.get_node_or_null("ActiveGame") as Control
	if game == null:
		_fail("Level 1 did not create ActiveGame")
		return
	if not game.visible:
		_fail("ActiveGame is not visible")
		return
	if game.size.x <= 1.0 or game.size.y <= 1.0:
		_fail("ActiveGame has an invalid viewport size: %s" % str(game.size))
		return
	var board_grid = game.get("board_grid")
	if board_grid == null or not board_grid is GridContainer:
		_fail("Gameplay board grid was not initialized")
		return
	if board_grid.get_child_count() <= 0:
		_fail("Gameplay board rendered no cells")
		return
	var level_data = game.get("level_data")
	if not level_data is Dictionary or level_data.is_empty():
		_fail("Level 1 data was not loaded")
		return
	print("Level launch validated: Level 1 opened a visible game scene with %d board cells." % board_grid.get_child_count())
	main.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
