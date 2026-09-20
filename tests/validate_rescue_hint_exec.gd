extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _active_count(pieces: Array) -> int:
	var count := 0
	for raw in pieces:
		if raw is Dictionary and bool((raw as Dictionary).get("active",true)):
			count += 1
	return count

func _run() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager != null:
		var save_data: Dictionary = save_manager.get("data")
		save_data["active_run"] = {}
		save_manager.set("data",save_data)

	var scene := load("res://scenes/Game.tscn") as PackedScene
	if scene == null:
		return _fail("Rescue scene failed to load")
	var game := scene.instantiate()
	game.set("level_number",5)
	root.add_child(game)
	await _frames(4)

	var before := _active_count(game.get("pieces") as Array)
	var before_moves := int(game.get("moves"))
	game.call("show_hint")
	await _frames(24)
	var after := _active_count(game.get("pieces") as Array)
	var after_moves := int(game.get("moves"))
	if after >= before:
		return _fail("Rescue Hint did not remove an arrow: %d -> %d" % [before,after])
	if after_moves != before_moves:
		return _fail("Rescue Hint consumed a player move: %d -> %d" % [before_moves,after_moves])

	print("RESCUE_HINT_REMOVAL_OK active=%d->%d moves=%d" % [before,after,after_moves])
	game.queue_free()
	await process_frame
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
