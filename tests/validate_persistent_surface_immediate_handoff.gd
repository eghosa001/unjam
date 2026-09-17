extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene could not be loaded")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var home := main.get_node_or_null("PremiumHome") as Control
	var live := main.get_node_or_null("PremiumLive") as Control
	var failures: Array[String] = []
	if home == null or live == null:
		failures.append("Persistent Home/Live surfaces are missing")
	else:
		home.call("_open_game_selector")
		if home.visible:
			failures.append("Home remains visible until the deferred surface signal")
		if not live.visible:
			failures.append("Game Selector is not visible in the same navigation call")
		await process_frame
		main.call("build_settings")
		if live.visible:
			failures.append("Game Selector remains visible underneath Settings for one frame")
		if home.visible:
			failures.append("Home becomes visible during Selector -> Settings handoff")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS immediate persistent surface handoff")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
