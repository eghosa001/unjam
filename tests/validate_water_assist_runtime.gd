extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var multi := root.get_node_or_null("MultiGameManager")
	if multi != null:
		multi.call("clear_checkpoint", "water_sort")
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null:
		push_error("Water Sort scene failed to load")
		quit(1)
		return
	var game = scene.instantiate()
	game.set("level_number", 31)
	root.add_child(game)
	await process_frame
	await process_frame
	var initial_tubes: int = (game.get("tubes") as Array).size()
	game.call("add_extra_tube")
	await process_frame
	if (game.get("tubes") as Array).size() != initial_tubes + 1 or not bool(game.get("extra_tube_used")):
		push_error("Extra Tube did not append exactly one empty bottle")
		game.queue_free()
		quit(1)
		return
	game.call("add_extra_tube")
	await process_frame
	if (game.get("tubes") as Array).size() != initial_tubes + 1:
		push_error("Extra Tube can be used more than once per attempt")
		game.queue_free()
		quit(1)
		return
	var before_moves: int = int(game.get("moves"))
	var move: Vector2i = game.call("_best_water_move")
	if move.x < 0 or move.y < 0:
		push_error("Water solver found no verified finish from generated level")
		game.queue_free()
		quit(1)
		return
	game.call("show_hint")
	await process_frame
	await process_frame
	if int(game.get("moves")) != before_moves + 1:
		push_error("Water hint did not execute exactly one solver-selected pour")
		game.queue_free()
		quit(1)
		return
	print("WATER_ASSIST_RUNTIME_OK tubes=%d->%d move=%s" % [initial_tubes, initial_tubes + 1, str(move)])
	game.queue_free()
	await process_frame
	quit(0)
