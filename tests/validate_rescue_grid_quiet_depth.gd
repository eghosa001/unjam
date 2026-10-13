extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue game scene missing")
	var game := packed.instantiate() as Control
	game.set("level_number",1)
	root.add_child(game)
	for _i in range(5): await process_frame
	var grid := game.get("board_backdrop_grid") as GridContainer
	if grid == null or grid.get_child_count() != 49:
		return _fail("The opening 7x7 Rescue visual backdrop is incomplete")
	for dark in [true,false]:
		var style := game.call("_rescue_grid_slot_style",dark) as StyleBoxFlat
		if style == null or style.bg_color.a > 0.23 or style.border_color.a > 0.16:
			return _fail("Empty Rescue tiles overpower game pieces")
		if style.border_color.a < 0.10 or style.bg_color.a < 0.10:
			return _fail("Rescue grid cells are no longer discoverable")
	game.queue_free()
	await process_frame
	print("RESCUE_QUIET_GRID_HIERARCHY_OK")
	quit(0)

func _fail(reason: String) -> bool:
	push_error(reason)
	quit(1)
	return false
