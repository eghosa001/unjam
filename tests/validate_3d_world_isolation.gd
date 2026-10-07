extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var arts: Array[Unjam3DGameArt] = []
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var art := Unjam3DGameArt.new()
		art.configure(game_id)
		root.add_child(art)
		arts.append(art)
	var mascot := Unjam3DMascot.new()
	root.add_child(mascot)
	var gameplay := Unjam3DGameplayStage.new()
	gameplay.configure("water_sort")
	root.add_child(gameplay)

	await process_frame
	await process_frame

	for i in range(arts.size()):
		var viewport := arts[i].viewport_3d
		if viewport == null or not viewport.own_world_3d:
			failures.append("Game preview %d does not own an isolated World3D" % i)
	if mascot.viewport_3d == null or not mascot.viewport_3d.own_world_3d:
		failures.append("Home mascot does not own an isolated World3D")
	if gameplay.viewport_3d == null or not gameplay.viewport_3d.own_world_3d:
		failures.append("Gameplay scenic viewport does not own an isolated World3D")

	# Gameplay bottles and Rescue characters are intentionally 2D now. They must
	# not allocate nested rendering worlds.
	for source_path in [
		"res://scripts/ui/water_tube_3d_motion.gd",
		"res://scripts/ui/rescue_token.gd"
	]:
		var file := FileAccess.open(source_path, FileAccess.READ)
		var source := "" if file == null else file.get_as_text()
		for forbidden in ["SubViewport", "Camera3D", "own_world_3d"]:
			if source.contains(forbidden):
				failures.append("Gameplay 2D renderer reintroduced '%s' in %s" % [forbidden, source_path])

	var flat_piece_file := FileAccess.open("res://scripts/ui/rescue_piece_3d_button.gd", FileAccess.READ)
	var flat_piece_source := "" if flat_piece_file == null else flat_piece_file.get_as_text()
	if flat_piece_source.contains("SubViewport") or flat_piece_source.contains("Camera3D"):
		failures.append("Rescue board pieces reintroduced a perspective nested 3D viewport")

	for node in arts:
		node.queue_free()
	mascot.queue_free()
	gameplay.queue_free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("World3D isolation validated for remaining decorative 3D; gameplay renderers remain 2D.")
	quit(0)
