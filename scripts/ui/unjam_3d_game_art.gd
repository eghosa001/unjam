class_name Unjam3DGameArt
extends SubViewportContainer

# Lightweight real 3D preview used on Choose-a-Game cards. Each card is a
# one-shot rendered toy diorama: true lighting/depth without three permanent
# 3D render loops running behind a scroll view.
var game_id := "rescue_rush"
var accent := Unjam3DTheme.GREEN
var viewport_3d: SubViewport
var stage: Node3D
var display_root: Node3D

func configure(id: String) -> void:
	game_id = id
	accent = Unjam3DTheme.game_accent(id)
	if is_inside_tree() and viewport_3d != null:
		call_deferred("_rebuild_stage")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.name = "GamePreviewViewport3D"
	viewport_3d.size = Vector2i(480, 360)
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)
	_build_stage()
	call_deferred("_finish_initial_render")

func _finish_initial_render() -> void:
	# The card can enter the tree before its ScrollContainer/layout is visible.
	# Render a couple of real frames, then return to one-shot mode so previews
	# stay cheap on mobile instead of becoming permanent 3D render loops.
	# Navigation may detach/free this card while these frames are pending, so
	# never await through a null SceneTree or touch a stale viewport afterward.
	for _frame in range(2):
		if not is_inside_tree():
			return
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
		if not is_inside_tree():
			return
	if viewport_3d != null and is_instance_valid(viewport_3d):
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _rebuild_stage() -> void:
	if not is_inside_tree() or viewport_3d == null:
		return
	if stage != null and is_instance_valid(stage):
		if stage.get_parent() == viewport_3d:
			viewport_3d.remove_child(stage)
		stage.queue_free()
		stage = null
		display_root = null
	_build_stage()
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _build_stage() -> void:
	if viewport_3d == null:
		return
	stage = Node3D.new()
	stage.name = "PreviewStage_%s" % game_id
	viewport_3d.add_child(stage)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Unjam3DTheme.game_dark(game_id)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = accent.lightened(0.70)
	environment.ambient_light_energy = 1.02
	world_environment.environment = environment
	stage.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -34, 0)
	key.light_color = Color("fff7dc")
	key.light_energy = 1.55
	key.shadow_enabled = true
	stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-22, 146, 12)
	rim.light_color = accent.lightened(0.45)
	rim.light_energy = 0.92
	stage.add_child(rim)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.2, 3.4, 4.1)
	fill.light_color = Color("9beaff")
	fill.light_energy = 0.62
	fill.omni_range = 12.0
	stage.add_child(fill)

	var camera := Camera3D.new()
	camera.position = Vector3(4.9, 5.0, 7.3)
	camera.fov = 43.0
	stage.add_child(camera)
	camera.look_at(Vector3(0, 0.45, 0), Vector3.UP)
	camera.current = true

	display_root = Node3D.new()
	display_root.name = "Diorama"
	stage.add_child(display_root)
	match game_id:
		"water_sort": _build_water_sort()
		"block_puzzle": _build_block_puzzle()
		_: _build_rescue_rush()

func _build_rescue_rush() -> void:
	_add_box(display_root, Vector3(5.7, 0.32, 4.25), Vector3(0, -0.38, 0), Color("07579b"), 0.06, 0.46)
	_add_box(display_root, Vector3(5.28, 0.14, 3.84), Vector3(0, -0.13, 0), Color("0b315d"), 0.02, 0.55)
	for row in range(3):
		for column in range(4):
			var slot_pos := Vector3(-1.74 + float(column) * 1.15, 0.01, -1.16 + float(row) * 1.12)
			_add_box(display_root, Vector3(1.02, 0.10, 0.98), slot_pos, Color("123f6d"), 0.0, 0.62)
	_add_arrow_tile(Vector3(-0.59, 0.34, -1.16), Color("19b9ff"), 0.0)
	_add_arrow_tile(Vector3(0.56, 0.34, -0.04), Color("ff4d55"), 90.0)
	_add_arrow_tile(Vector3(0.56, 0.34, 1.08), Color("20d86b"), 180.0)
	_add_arrow_tile(Vector3(-1.74, 0.34, -0.04), Color("c63cff"), -90.0)

	_add_sphere(display_root, 0.46, Vector3(-0.58, 0.57, -0.02), Color("ffd83d"), Vector3(1.0, 0.96, 1.0))
	_add_sphere(display_root, 0.06, Vector3(-0.72, 0.68, 0.40), Color("17304a"), Vector3.ONE)
	_add_sphere(display_root, 0.06, Vector3(-0.44, 0.68, 0.40), Color("17304a"), Vector3.ONE)
	_add_sphere(display_root, 0.09, Vector3(-0.58, 0.51, 0.43), Color("ff795f"), Vector3(1.35, 0.35, 0.30))

	_add_box(display_root, Vector3(0.18, 0.95, 0.18), Vector3(2.78, 0.28, -0.72), Color("fff3d1"), 0.0, 0.34)
	_add_box(display_root, Vector3(0.18, 0.95, 0.18), Vector3(2.78, 0.28, 0.72), Color("fff3d1"), 0.0, 0.34)
	_add_box(display_root, Vector3(0.18, 0.18, 1.62), Vector3(2.78, 0.72, 0), Color("ffd83d"), 0.0, 0.30)

func _add_arrow_tile(position_value: Vector3, color: Color, yaw_degrees: float) -> void:
	var tile := Node3D.new()
	tile.position = position_value
	tile.rotation_degrees.y = yaw_degrees
	display_root.add_child(tile)
	_add_box(tile, Vector3(0.92, 0.56, 0.92), Vector3.ZERO, color, 0.08, 0.24)
	_add_box(tile, Vector3(0.16, 0.08, 0.52), Vector3(0, 0.33, 0.02), Color.WHITE, 0.0, 0.25)
	var head_left := _add_box(tile, Vector3(0.15, 0.08, 0.38), Vector3(-0.13, 0.33, -0.27), Color.WHITE, 0.0, 0.25)
	head_left.rotation_degrees.y = -36.0
	var head_right := _add_box(tile, Vector3(0.15, 0.08, 0.38), Vector3(0.13, 0.33, -0.27), Color.WHITE, 0.0, 0.25)
	head_right.rotation_degrees.y = 36.0
	_add_box(tile, Vector3(0.68, 0.035, 0.30), Vector3(0, 0.31, 0.27), Color(1, 1, 1, 0.28), 0.0, 0.18)

func _build_water_sort() -> void:
	_add_box(display_root, Vector3(5.9, 0.34, 3.9), Vector3(0, -0.40, 0), Color("087dcc"), 0.08, 0.42)
	_add_box(display_root, Vector3(5.45, 0.13, 3.52), Vector3(0, -0.12, 0), Color("d9f7ff"), 0.0, 0.48)
	var colors := [Color("ffd83d"), Color("ff4ca5"), Color("19b9ff"), Color("c63cff")]
	var fill_levels := [1.25, 1.72, 0.92, 1.48]
	for i in range(4):
		var x := -1.72 + float(i) * 1.15
		_add_tube(Vector3(x, 1.22, 0.15), colors[i], float(fill_levels[i]))

	var pour_root := Node3D.new()
	pour_root.position = Vector3(-0.72, 2.84, -0.40)
	pour_root.rotation_degrees = Vector3(0, 0, -58)
	display_root.add_child(pour_root)
	_add_cylinder(pour_root, 0.34, 0.34, 1.80, Vector3.ZERO, Color(0.82, 0.96, 1.0, 0.28), 0.02, 0.10)
	_add_cylinder(pour_root, 0.27, 0.27, 0.92, Vector3(0, -0.38, 0), Color("c63cff"), 0.02, 0.22)
	var stream := _add_cylinder(display_root, 0.08, 0.10, 1.45, Vector3(0.05, 2.20, -0.26), Color("d958ff"), 0.0, 0.18)
	stream.rotation_degrees.z = -25.0

func _add_tube(position_value: Vector3, liquid: Color, fill_height: float) -> void:
	_add_cylinder(display_root, 0.43, 0.43, 2.62, position_value, Color(0.86, 0.98, 1.0, 0.24), 0.05, 0.08)
	var inner_y := position_value.y - 1.14 + fill_height * 0.5
	_add_cylinder(display_root, 0.33, 0.33, fill_height, Vector3(position_value.x, inner_y, position_value.z), liquid, 0.02, 0.20)
	_add_cylinder(display_root, 0.50, 0.50, 0.10, Vector3(position_value.x, position_value.y + 1.31, position_value.z), Color("e9fdff"), 0.0, 0.12)
	_add_box(display_root, Vector3(0.08, 2.10, 0.08), Vector3(position_value.x - 0.24, position_value.y + 0.05, position_value.z + 0.36), Color(1, 1, 1, 0.52), 0.0, 0.08)

func _build_block_puzzle() -> void:
	_add_box(display_root, Vector3(5.7, 0.34, 4.25), Vector3(0, -0.38, 0), Color("6e1abf"), 0.08, 0.42)
	_add_box(display_root, Vector3(5.30, 0.14, 3.84), Vector3(0, -0.12, 0), Color("251747"), 0.02, 0.56)
	var palette := [Color("ffd83d"), Color("ff8d1f"), Color("ff4ca5"), Color("20d86b"), Color("19b9ff"), Color("c63cff")]
	var occupied := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 0),
		Vector2i(0, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(3, 3)
	]
	for row in range(4):
		for column in range(4):
			var pos := Vector3(-1.72 + float(column) * 1.14, 0.02, -1.16 + float(row) * 1.08)
			_add_box(display_root, Vector3(0.98, 0.08, 0.92), pos, Color("39265f"), 0.0, 0.62)
	for i in range(occupied.size()):
		var cell: Vector2i = occupied[i]
		var c: Color = palette[i % palette.size()]
		var y := 0.34 + float(i % 3) * 0.045
		var pos := Vector3(-1.72 + float(cell.x) * 1.14, y, -1.16 + float(cell.y) * 1.08)
		_add_block_cube(pos, c)

	_add_block_cube(Vector3(-1.25, 0.33, 2.34), Color("19b9ff"), 0.72)
	_add_block_cube(Vector3(-0.50, 0.33, 2.34), Color("19b9ff"), 0.72)
	_add_block_cube(Vector3(0.58, 0.33, 2.34), Color("ffd83d"), 0.72)
	_add_block_cube(Vector3(1.33, 0.33, 2.34), Color("ffd83d"), 0.72)

func _add_block_cube(position_value: Vector3, color: Color, scale_value: float = 0.88) -> void:
	_add_box(display_root, Vector3(scale_value, 0.56, scale_value), position_value, color, 0.08, 0.23)
	_add_box(display_root, Vector3(scale_value * 0.70, 0.035, scale_value * 0.30), position_value + Vector3(0, 0.30, -scale_value * 0.18), Color(1, 1, 1, 0.30), 0.0, 0.15)

func _material(color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = clampf(roughness_value, 0.12, 0.42)
	material.clearcoat_enabled = true
	material.clearcoat = 0.62 if color.a >= 0.90 else 0.38
	material.clearcoat_roughness = 0.13 if color.a >= 0.90 else 0.08
	if color.a < 0.995:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _add_box(parent: Node3D, dimensions: Vector3, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_sphere(parent: Node3D, radius: float, position_value: Vector3, color: Color, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.scale = scale_value
	instance.material_override = _material(color, 0.0, 0.24)
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance
