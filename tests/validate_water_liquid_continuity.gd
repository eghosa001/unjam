extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var script := load("res://scripts/ui/water_tube_3d_motion.gd")
	if script == null:
		return _fail("WaterTube3DMotion script is missing")
	var tube = script.new()
	tube.size = Vector2(120.0, 240.0)
	tube.custom_minimum_size = tube.size
	tube.configure([0, 0, 0, 0], false, 0)
	root.add_child(tube)
	await _frames(4)

	if _visible_volume_count(tube) != 1:
		return _fail("Four identical Water layers render as more than one 3D liquid body")
	var segments: Array = tube.get("liquid_segments_3d")
	var first := segments[0] as MeshInstance3D
	var first_mesh := first.mesh as CylinderMesh
	if first_mesh == null or first_mesh.cap_top or first_mesh.cap_bottom:
		return _fail("Continuous Water volume still owns rigid internal cylinder caps")
	if first_mesh.height < 2.45:
		return _fail("Merged same-colour Water volume does not span the full four-slot height")
	var meniscus := tube.get("liquid_meniscus_3d") as MeshInstance3D
	if meniscus == null or not meniscus.visible:
		return _fail("Continuous Water volume has no exposed meniscus")
	var meniscus_mesh := meniscus.mesh as SphereMesh
	if meniscus_mesh == null or absf(first_mesh.top_radius - meniscus_mesh.radius) > 0.001:
		return _fail("Water body and meniscus no longer share one uniform container-aligned radius")

	tube.configure([0, 0, 1, 1], false, 0)
	await _frames(2)
	if _visible_volume_count(tube) != 2:
		return _fail("Two colour runs should render as exactly two touching liquid bodies")

	tube.configure([0, 1, 0, 1], false, 0)
	await _frames(2)
	if _visible_volume_count(tube) != 4:
		return _fail("Alternating Water colours lost distinct colour boundaries")

	# Incoming liquid of the same colour must merge continuously even while the
	# upper incoming slot is only partially filled.
	tube.configure([0, 0], false, 0)
	tube.call("begin_pour_in", 0, 2)
	tube.call("set_pour_progress", 0.75)
	await _frames(2)
	if _visible_volume_count(tube) != 1:
		return _fail("Mid-pour same-colour Water still splits into stacked 3D solids")
	var liquid_root := tube.get("liquid_root_3d") as Node3D
	if liquid_root == null or absf(liquid_root.rotation.z) > 0.0001:
		return _fail("Water arrival ripple tilted the bulk liquid away from the bottle walls")

	tube.queue_free()
	await _frames(2)
	print("WATER_LIQUID_CONTINUITY_OK: equal colours merge into one continuous 3D body with one exposed meniscus.")
	quit(0)

func _visible_volume_count(tube: Node) -> int:
	var count := 0
	var segments: Array = tube.get("liquid_segments_3d")
	for segment in segments:
		if segment is MeshInstance3D and (segment as MeshInstance3D).visible:
			count += 1
	return count

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
