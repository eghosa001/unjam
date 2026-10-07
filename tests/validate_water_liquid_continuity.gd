extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var script := load("res://scripts/ui/water_tube_3d_motion.gd")
	if script == null:
		return _fail("Water bottle renderer is missing")
	var tube = script.new()
	tube.size = Vector2(120.0, 240.0)
	tube.custom_minimum_size = tube.size
	root.add_child(tube)

	tube.configure([0, 0, 0, 0], false, 0)
	await _frames(2)
	if _exposed_surface_count(tube) != 1:
		return _fail("Four equal layers should read as one continuous liquid body")

	tube.configure([0, 0, 1, 1], false, 0)
	await _frames(1)
	if _exposed_surface_count(tube) != 2:
		return _fail("Two colour runs should expose exactly two liquid surfaces")

	tube.configure([0, 1, 0, 1], false, 0)
	await _frames(1)
	if _exposed_surface_count(tube) != 4:
		return _fail("Alternating colours should keep four readable boundaries")

	tube.configure([0, 0], false, 0)
	tube.call("begin_pour_in", 0, 2)
	tube.call("set_pour_progress", 0.75)
	await _frames(1)
	if _exposed_surface_count(tube) != 1:
		return _fail("Incoming same-colour liquid should merge visually during the pour")
	if absf(tube.rotation) > 0.0001:
		return _fail("Arrival feedback rotated the bottle control instead of the liquid detail")

	var source := _read("res://scripts/ui/water_tube_reference_motion.gd")
	for needle in ["slot_h + 1.0", "next_color != _slot_color(slot)", "Only the exposed liquid surface owns a highlight/meniscus line"]:
		if not source.contains(needle):
			return _fail("2D liquid continuity contract is missing: " + needle)

	tube.queue_free()
	await _frames(1)
	print("WATER_2D_LIQUID_CONTINUITY_OK")
	quit(0)

func _exposed_surface_count(tube: Node) -> int:
	var count := 0
	for slot in range(4):
		var fill := float(tube.call("_slot_fill", slot))
		if fill <= 0.001:
			continue
		var next_fill := float(tube.call("_slot_fill", slot + 1)) if slot < 3 else 0.0
		var color := int(tube.call("_slot_color", slot))
		var next_color := int(tube.call("_slot_color", slot + 1)) if next_fill > 0.001 and slot < 3 else -1
		if next_fill <= 0.001 or next_color != color:
			count += 1
	return count

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
