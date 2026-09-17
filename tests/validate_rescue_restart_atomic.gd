extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	var game := packed.instantiate() as Control
	root.add_child(game)
	await process_frame
	await process_frame
	var enhancer := game.get_node_or_null("UiTouchEnhancer")
	if enhancer == null:
		push_error("Rescue scene must begin with UiTouchEnhancer")
		game.queue_free()
		quit(1)
		return
	var old_runtime: Array[Node] = []
	for child in game.get_children():
		if child != enhancer:
			old_runtime.append(child)
	game.restart_level()
	var failures: Array[String] = []
	if enhancer.get_parent() != game:
		failures.append("Rescue restart detaches its persistent UiTouchEnhancer")
	for child in old_runtime:
		if is_instance_valid(child) and child.get_parent() == game:
			failures.append("Rescue restart leaves old runtime UI parented during replacement")
			break
	await process_frame
	if not is_instance_valid(enhancer) or enhancer.get_parent() != game:
		failures.append("Rescue restart destroys UiTouchEnhancer instead of preserving it")
	if game.get_child_count() <= 1:
		failures.append("Rescue restart did not rebuild runtime UI after clearing the old tree")
	game.queue_free()
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Rescue restart preserves touch enhancement and replaces runtime UI atomically.")
	quit(0)
