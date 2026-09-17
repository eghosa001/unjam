extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _active_count(pieces: Array) -> int:
	var count := 0
	for raw in pieces:
		if raw is Dictionary and bool((raw as Dictionary).get("active", true)):
			count += 1
	return count

func _run() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager != null:
		var save_data: Dictionary = save_manager.get("data")
		save_data["active_run"] = {}
		save_manager.set("data", save_data)
	var scene := load("res://scenes/Game.tscn") as PackedScene
	if scene == null:
		push_error("Rescue scene failed to load")
		quit(1)
		return
	var game = scene.instantiate()
	game.set("level_number", 5)
	root.add_child(game)
	await process_frame
	await process_frame
	var before: int = _active_count(game.get("pieces") as Array)
	var before_moves: int = int(game.get("moves"))
	game.call("show_hint")
	for _i in range(40):
		await process_frame
	var after: int = _active_count(game.get("pieces") as Array)
	var after_moves: int = int(game.get("moves"))
	if after >= before or after_moves != before_moves + 1:
		push_error("Rescue hint did not execute the solver-selected move: active %d->%d, moves %d->%d" % [before, after, before_moves, after_moves])
		game.queue_free()
		quit(1)
		return
	print("RESCUE_HINT_EXEC_OK active=%d->%d moves=%d->%d" % [before, after, before_moves, after_moves])
	game.queue_free()
	await process_frame
	quit(0)
