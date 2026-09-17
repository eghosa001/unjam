class_name Unjam3DGameplayStage
extends SubViewportContainer

# Shared low-poly 3D environment behind all three interactive puzzle boards.
# Gameplay stays in the existing fast 2D Control layer while this viewport gives
# the screen real perspective, lighting and mesh depth at low cost. The scenic
# world is intentionally one-shot rendered; gameplay motion lives above it.
var game_id := "rescue_rush"
var accent := Unjam3DTheme.GREEN
var viewport_3d: SubViewport
var stage: Node3D
var scenic_root: Node3D
var dark_mode := false

func configure(id: String, accent_value: Color = Color.TRANSPARENT) -> void:
	game_id = id
	accent = Unjam3DTheme.game_accent(id) if accent_value.a <= 0.001 else accent_value
	if is_inside_tree() and viewport_3d != null:
		call_deferred("_rebuild")

func set_dark_mode(value: bool) -> void:
	if dark_mode == value:
		return
	dark_mode = value
	if is_inside_tree() and viewport_3d != null:
		call_deferred("_rebuild")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.name = "GameplayViewport3D"
	viewport_3d.size = Vector2i(540, 960)
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_3d.transparent_bg = false
	add_child(viewport_3d)
	_build_stage()

func _rebuild() -> void:
	if not is_inside_tree() or viewport_3d == null:
		return
	if stage != null and is_instance_valid(stage):
		if stage.get_parent() == viewport_3d:
			viewport_3d.remove_child(stage)
		stage.queue_free()
		stage = null
		scenic_root = null
	_build_stage()
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _build_stage() -> void:
	if viewport_3d == null:
		return
	stage = Node3D.new()
	stage.name = "GameplayStage_%s" % game_id
	viewport_3d.add_child(stage)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	if dark_mode:
		environment.background_color = Color("10182f") if game_id != "block_puzzle" else Color("241638")
	else:
		environment.background_color = Color("46c0ff") if game_id != "block_puzzle" else Color("a56cff")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = (accent.lightened(0.20) if dark_mode else (Color("e4faff") if game_id != "block_puzzle" else Color("fff0ff")))
	environment.ambient_light_energy = (0.62 if dark_mode else (1.32 if game_id == "block_puzzle" else 1.18))
	world_environment.environment = environment
	stage.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -32, 0)
	key.light_color = Color("fff0c5")
	key.light_energy = (0.92 if dark_mode else (1.68 if game_id == "block_puzzle" else 1.50))
	key.shadow_enabled = true
	stage.add_child(key)

	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, 142, 12)
	rim.light_color = accent.lightened(0.55)
	rim.light_energy = 0.52 if dark_mode else 0.72
	stage.add_child(rim)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.6, 11.8)
	camera.fov = 47.0
	stage.add_child(camera)
	camera.look_at(Vector3(0, 0.55, 0), Vector3.UP)
	camera.current = true

	scenic_root = Node3D.new()
	scenic_root.name = "ScenicWorld"
	stage.add_child(scenic_root)

	match game_id:
		"water_sort": _build_water_world()
		"block_puzzle": _build_block_world()
		_: _build_rescue_world()

func _build_rescue_world() -> void:
	# Layered green islands, water and a waterfall valley echo the reference art.
	_add_box(scenic_root, Vector3(22, 0.30, 16), Vector3(0, -1.72, 0), Color("1bb4d4"), 0.04, 0.22)
	for z in [-4.6, -1.8, 1.1, 4.2]:
		_add_island(Vector3(-5.2, -0.35, z), 2.7, Color("47bd5a"))
		_add_island(Vector3(5.2, -0.30, z + 0.8), 2.5, Color("67d45f"))
	for z in [-4.2, -0.9, 2.8]:
		_add_waterfall(Vector3(-3.9, 0.45, z), 1.05, 3.6)
	for p in [Vector3(-5.0,1.05,-2.2), Vector3(4.8,1.12,-3.6), Vector3(-5.1,0.96,3.2), Vector3(4.7,1.04,2.0)]:
		_add_tree(p, 0.82)
	for p in [Vector3(-4.1,-0.90,-0.4), Vector3(4.0,-0.85,-1.0), Vector3(-3.8,-0.88,4.0), Vector3(3.9,-0.84,4.6)]:
		_add_rock_cluster(p, 0.85)
	# A central raised stone pedestal sits behind the interactive board.
	_add_cylinder(scenic_root, 3.4, 3.7, 0.62, Vector3(0, -0.96, 0.6), Color("78938b"), 0.03, 0.62)
	_add_cylinder(scenic_root, 3.1, 3.3, 0.16, Vector3(0, -0.57, 0.6), Color("90df62"), 0.0, 0.52)

func _build_water_world() -> void:
	_add_box(scenic_root, Vector3(22, 0.34, 16), Vector3(0, -1.72, 0), Color("119fd5"), 0.05, 0.18)
	# Glassy pool platform and luminous crystal tubes around the edge.
	_add_cylinder(scenic_root, 4.3, 4.7, 0.54, Vector3(0, -0.96, 0.8), Color("71ddeb"), 0.04, 0.30)
	_add_cylinder(scenic_root, 4.0, 4.2, 0.16, Vector3(0, -0.60, 0.8), Color("d8fbff"), 0.02, 0.16)
	var palette := [Color("ff4ca5"), Color("ffd83d"), Color("19b9ff"), Color("c63cff"), Color("20d86b")]
	var positions := [Vector3(-5.0,0.1,-3.5), Vector3(5.1,0.2,-3.0), Vector3(-5.2,0.1,2.2), Vector3(5.0,0.16,2.6), Vector3(0,0.0,6.0)]
	for i in range(positions.size()):
		_add_crystal(positions[i], palette[i], 0.92 + float(i % 2) * 0.16)
	for p in [Vector3(-4.5,-0.82,-0.3), Vector3(4.4,-0.82,0.0), Vector3(-4.2,-0.84,4.8), Vector3(4.0,-0.84,5.0)]:
		_add_rock_cluster(p, 0.72)
	for p in [Vector3(-5.2,0.92,-1.4), Vector3(5.0,0.95,-0.8), Vector3(-4.8,0.90,4.0), Vector3(4.8,0.92,4.2)]:
		_add_tree(p, 0.70)

func _build_block_world() -> void:
	# Block Puzzle gets a candy-colored floating-island world instead of a dark board.
	_add_box(scenic_root, Vector3(22, 0.30, 16), Vector3(0, -1.74, 0), Color("7652d4"), 0.03, 0.28)
	_add_cylinder(scenic_root, 4.0, 4.5, 0.64, Vector3(0, -0.98, 0.8), Color("8159d1"), 0.06, 0.38)
	_add_cylinder(scenic_root, 3.72, 3.95, 0.15, Vector3(0, -0.56, 0.8), Color("f0a2ff"), 0.02, 0.24)
	var colors := [Color("ffd83d"), Color("ff8d1f"), Color("ff4ca5"), Color("20d86b"), Color("19b9ff"), Color("c63cff")]
	var positions := [Vector3(-5.3,0.0,-3.2), Vector3(5.0,0.0,-2.6), Vector3(-5.2,0.0,1.1), Vector3(5.1,0.0,1.8), Vector3(-4.6,0.0,5.2), Vector3(4.5,0.0,5.3)]
	for i in range(positions.size()):
		_add_toy_stack(positions[i], colors[i])
	for p in [Vector3(-4.9,0.90,-0.6), Vector3(4.8,0.94,0.2), Vector3(-4.4,0.86,4.0), Vector3(4.3,0.88,4.2)]:
		_add_round_bush(p, 0.72, colors[int(abs(p.x)) % colors.size()])

func _add_island(position_value: Vector3, radius: float, grass: Color) -> void:
	_add_cylinder(scenic_root, radius * 0.82, radius, radius * 0.78, position_value, Color("586b64"), 0.0, 0.72)
	_add_cylinder(scenic_root, radius * 0.88, radius * 0.92, 0.18, position_value + Vector3(0, radius * 0.47, 0), grass, 0.0, 0.58)

func _add_waterfall(position_value: Vector3, width: float, height: float) -> void:
	_add_box(scenic_root, Vector3(width * 1.12, height, 0.20), position_value, Color("73dce8"), 0.0, 0.16)
	_add_box(scenic_root, Vector3(width * 0.62, height, 0.13), position_value + Vector3(0,0,0.13), Color("ddfeff"), 0.0, 0.12)
	_add_box(scenic_root, Vector3(width * 0.16, height * 0.96, 0.08), position_value + Vector3(-width * 0.18,0,0.24), Color(1,1,1,0.66), 0.0, 0.10)

func _add_tree(position_value: Vector3, scale_value: float) -> void:
	_add_cylinder(scenic_root, 0.13 * scale_value, 0.18 * scale_value, 1.42 * scale_value, position_value, Color("7a4a28"), 0.0, 0.72)
	_add_sphere(scenic_root, 0.78 * scale_value, position_value + Vector3(0, 0.94 * scale_value, 0), Color("1a8d45"), Vector3(1.0,0.92,1.0))
	_add_sphere(scenic_root, 0.62 * scale_value, position_value + Vector3(-0.42, 1.08, 0.08) * scale_value, Color("38bb51"), Vector3.ONE)
	_add_sphere(scenic_root, 0.55 * scale_value, position_value + Vector3(0.40, 1.20, -0.04) * scale_value, Color("74db58"), Vector3.ONE)
	_add_sphere(scenic_root, 0.42 * scale_value, position_value + Vector3(-0.05, 1.48, 0.02) * scale_value, Color("a5e967"), Vector3.ONE)

func _add_rock_cluster(position_value: Vector3, scale_value: float) -> void:
	_add_sphere(scenic_root, 0.72 * scale_value, position_value, Color("70857f"), Vector3(1.25,0.72,1.0))
	_add_sphere(scenic_root, 0.48 * scale_value, position_value + Vector3(0.58,0.12,0.16) * scale_value, Color("94a69a"), Vector3(1.0,0.75,0.90))
	_add_sphere(scenic_root, 0.38 * scale_value, position_value + Vector3(-0.58,0.10,-0.08) * scale_value, Color("aab8a4"), Vector3(1.0,0.70,0.92))

func _add_crystal(position_value: Vector3, color: Color, scale_value: float) -> void:
	var root := Node3D.new()
	root.position = position_value
	root.rotation_degrees.y = position_value.x * 8.0
	scenic_root.add_child(root)
	var crystal := _add_cylinder(root, 0.0, 0.44 * scale_value, 1.70 * scale_value, Vector3.ZERO, color, 0.12, 0.20)
	crystal.rotation_degrees.z = -8.0
	_add_sphere(root, 0.24 * scale_value, Vector3(-0.14,0.36,0.30), Color(1,1,1,0.35), Vector3(0.42,1.18,0.42))

func _add_toy_stack(position_value: Vector3, color: Color) -> void:
	for i in range(3):
		var offset := Vector3(float(i % 2) * 0.48, float(i) * 0.46, -float(i % 2) * 0.18)
		_add_box(scenic_root, Vector3(0.82,0.42,0.82), position_value + offset, color.lightened(float(i) * 0.05), 0.08, 0.25)

func _add_round_bush(position_value: Vector3, scale_value: float, flower_color: Color) -> void:
	_add_sphere(scenic_root, 0.80 * scale_value, position_value, Color("35a64e"), Vector3(1.15,0.72,1.0))
	_add_sphere(scenic_root, 0.18 * scale_value, position_value + Vector3(-0.38,0.34,0.42) * scale_value, flower_color, Vector3.ONE)
	_add_sphere(scenic_root, 0.16 * scale_value, position_value + Vector3(0.30,0.28,0.48) * scale_value, Color("ffd83d"), Vector3.ONE)

func _material(color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
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
	mesh.radial_segments = 18
	mesh.rings = 9
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.scale = scale_value
	instance.material_override = _material(color, 0.0, 0.34)
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 18
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance
