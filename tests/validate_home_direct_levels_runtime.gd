extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		push_error("Main scene failed to load")
		quit(1)
		return
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		main.call("build_home")
		await process_frame
		await process_frame
		var button := main.find_child("HomeDirect_%s" % game_id, true, false) as Button
		if button == null:
			push_error("Home direct button missing for %s" % game_id)
			main.queue_free()
			quit(1)
			return
		button.emit_signal("pressed")
		await process_frame
		await process_frame
		if String(main.get("current_surface")) != "levels" or String(main.get("selected_game_id")) != game_id:
			push_error("Home direct shortcut did not open %s levels" % game_id)
			main.queue_free()
			quit(1)
			return
	print("HOME_DIRECT_LEVELS_OK")
	main.queue_free()
	await process_frame
	quit(0)
