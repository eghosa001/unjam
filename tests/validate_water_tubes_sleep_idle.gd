extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script := load("res://scripts/ui/water_tube_3d_motion.gd") as Script
	if script == null:
		return _fail("Water Sort compatibility tube source is missing")
	var tube := script.new() as Control
	if tube == null:
		return _fail("Water Sort compatibility tube could not instantiate")
	root.add_child(tube)
	tube.size = Vector2(120, 300)
	tube.custom_minimum_size = tube.size
	tube.call("configure", [0, 0, 0, 0], false, 0)

	# Force one idle process tick. The production renderer must put itself to
	# sleep when no pour/slosh/selection/feedback animation remains.
	tube.set_process(true)
	tube.call("_process", 1.0)
	if tube.is_processing():
		tube.queue_free()
		return _fail("Idle Water Sort tube stays on the per-frame process list")

	tube.call("begin_pour_out", 1)
	if not tube.is_processing():
		tube.queue_free()
		return _fail("Water Sort tube does not wake when a pour begins")

	var source := FileAccess.get_file_as_string("res://scripts/ui/water_tube_3d_motion.gd")
	for forbidden in ["SubViewport", "Camera3D", "MeshInstance3D"]:
		if source.contains(forbidden):
			tube.queue_free()
			return _fail("Water Sort idle renderer regressed to nested 3D work: " + forbidden)

	tube.queue_free()
	await process_frame
	print("WATER_TUBES_SLEEP_IDLE_OK: optimized 2D tubes sleep when idle and wake for active pours.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
