extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var board := game.get("board") as GridContainer
	var tubes: Array = game.get("tubes")
	if board == null or board.get_child_count() != tubes.size():
		game.queue_free()
		return _fail("Water Sort board did not initialize correctly")

	var selected_index := -1
	for i in range(tubes.size()):
		if not (tubes[i] as Array).is_empty():
			selected_index = i
			break
	if selected_index < 0:
		game.queue_free()
		return _fail("No selectable Water Sort bottle found")

	game.call("select_tube", selected_index)
	await process_frame
	await process_frame

	if int(game.get("selected")) != selected_index:
		game.queue_free()
		return _fail("Bottle selection did not persist")

	for i in range(board.get_child_count()):
		var bottle := board.get_child(i) as Control
		if bottle == null:
			game.queue_free()
			return _fail("Water bottle control missing after selection")
		if bottle.modulate.a < 0.99:
			game.queue_free()
			return _fail("Bottle %d became transparent after selection" % i)
		var viewport := bottle.get("viewport_3d") as SubViewport
		if viewport == null:
			game.queue_free()
			return _fail("Bottle %d lost its 3D viewport after selection" % i)
		if viewport.render_target_update_mode != SubViewport.UPDATE_ONCE:
			game.queue_free()
			return _fail("Bottle %d did not request a fresh one-shot 3D frame after selection" % i)

	game.queue_free()
	await process_frame
	print("WATER_SELECTION_RELEASE_VISIBILITY_OK: selecting a bottle keeps all live bottles visible and refreshes every one-shot 3D viewport.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
