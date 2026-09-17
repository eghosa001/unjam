extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	await _check_scene("res://scenes/WaterSort.tscn", "GameplayStageHolder", failures)
	await _check_scene("res://scenes/Game.tscn", "GameplayBoardHolder", failures)
	if failures.is_empty():
		print("PASS compact gameplay stack")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_scene(path: String, holder_name: String, failures: Array[String]) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Could not load %s" % path)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var holder := scene.find_child(holder_name, true, false) as Control
	if holder == null:
		failures.append("%s missing %s" % [path, holder_name])
		scene.queue_free()
		await process_frame
		return
	if holder.size_flags_vertical == Control.SIZE_EXPAND_FILL:
		failures.append("%s still expands the gameplay holder vertically" % path)
	if holder.get_child_count() == 0 or not (holder.get_child(0) is Control):
		failures.append("%s holder has no visual gameplay child" % path)
	else:
		var visual := holder.get_child(0) as Control
		if visual.position.y > 24.0:
			failures.append("%s gameplay visual floats %.1fpx below its holder top" % [path, visual.position.y])
	scene.queue_free()
	await process_frame
