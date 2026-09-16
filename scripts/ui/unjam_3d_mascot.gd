class_name Unjam3DMascot
extends SubViewportContainer

# Real-time lightweight 3D mascot used by the home hero. The scene is made
# entirely from Godot primitive meshes so it needs no external art assets and
# remains friendly to the GL Compatibility/mobile renderer.
var viewport_3d: SubViewport
var stage: Node3D
var mascot_root: Node3D
var wave_pivot: Node3D
var phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_build_3d_scene()
	visibility_changed.connect(_sync_render_activity)
	_sync_render_activity()

func _sync_render_activity() -> void:
	var active := is_visible_in_tree()
	set_process(active)
	if viewport_3d != null:
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED

func _process(delta: float) -> void:
	phase += delta
	if mascot_root != null:
		mascot_root.position.y = sin(phase * 1.75) * 0.075
		mascot_root.rotation.y = sin(phase * 0.72) * 0.07
	if wave_pivot != null:
		wave_pivot.rotation.z = deg_to_rad(-42.0 + sin(phase * 3.0) * 10.0)

func _build_3d_scene() -> void:
	viewport_3d = SubViewport.new()
	viewport_3d.name = "MascotViewport3D"
	viewport_3d.size = Vector2i(512, 512)
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport_3d)

	stage = Node3D.new()
	stage.name = "MascotStage"
	viewport_3d.add_child(stage)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("78d7ff")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d8f6ff")
	environment.ambient_light_energy = 1.25
	world_environment.environment = environment
	stage.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -34, 0)
	key.light_color = Color("fff4d0")
	key.light_energy = 1.45
	key.shadow_enabled = true
	stage.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 142, 18)
	fill.light_color = Color("75d7ff")
	fill.light_energy = 0.72
	stage.add_child(fill)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.05, 7.2)
	camera.fov = 40.0
	stage.add_child(camera)
	camera.look_at(Vector3(0.0, 1.55, 0.0), Vector3.UP)
	camera.current = true

	mascot_root = Node3D.new()
	mascot_root.name = "ExplorerMascot"
	mascot_root.position = Vector3(0, -0.34, 0)
	stage.add_child(mascot_root)

	# Floating toy platform and contact shadow.
	_add_cylinder(mascot_root, 1.42, 1.55, 0.24, Vector3(0, -1.42, 0), Color("1d9e63"), 0.0, 0.72)
	_add_cylinder(mascot_root, 1.23, 1.34, 0.08, Vector3(0, -1.26, 0), Color("7be45c"), 0.0, 0.58)
	_add_sphere(mascot_root, 1.20, Vector3(0, -1.34, -0.10), Color(0.02, 0.16, 0.25, 0.18), Vector3(1.05, 0.12, 0.55))

	# Body and explorer outfit.
	_add_capsule(mascot_root, 0.72, 1.72, Vector3(0, 0.10, 0), Color("ffd83d"), 0.05, 0.28)
	_add_box(mascot_root, Vector3(1.34, 0.54, 0.66), Vector3(0, -0.28, 0.16), Color("1c86e8"), 0.15, 0.26)
	_add_box(mascot_root, Vector3(1.10, 0.14, 0.72), Vector3(0, 0.10, 0.18), Color("b56e16"), 0.10, 0.36)
	_add_sphere(mascot_root, 0.13, Vector3(0, 0.11, 0.60), Color("ffd83d"), Vector3.ONE)

	# Head with face depth.
	_add_sphere(mascot_root, 0.93, Vector3(0, 1.36, 0), Color("ffd83d"), Vector3(1.03, 0.98, 0.96))
	_add_sphere(mascot_root, 0.25, Vector3(-0.36, 1.23, 0.78), Color("ff8c6a"), Vector3(1.0, 0.58, 0.28))
	_add_sphere(mascot_root, 0.25, Vector3(0.36, 1.23, 0.78), Color("ff8c6a"), Vector3(1.0, 0.58, 0.28))
	_add_sphere(mascot_root, 0.115, Vector3(-0.30, 1.52, 0.82), Color("183450"), Vector3(0.84, 1.12, 0.45))
	_add_sphere(mascot_root, 0.115, Vector3(0.30, 1.52, 0.82), Color("183450"), Vector3(0.84, 1.12, 0.45))
	_add_sphere(mascot_root, 0.038, Vector3(-0.335, 1.565, 0.918), Color.WHITE, Vector3.ONE)
	_add_sphere(mascot_root, 0.038, Vector3(0.265, 1.565, 0.918), Color.WHITE, Vector3.ONE)
	_add_sphere(mascot_root, 0.20, Vector3(0, 1.16, 0.865), Color("7b321f"), Vector3(1.35, 0.34, 0.25))

	# Explorer cap with brim.
	_add_cylinder(mascot_root, 0.70, 0.77, 0.34, Vector3(0, 2.18, 0), Color("ff6a37"), 0.05, 0.30)
	_add_box(mascot_root, Vector3(1.28, 0.12, 0.58), Vector3(0, 2.02, 0.44), Color("ff8d1f"), 0.05, 0.30)
	_add_box(mascot_root, Vector3(0.66, 0.10, 0.10), Vector3(0, 2.31, 0.69), Color("fff3d1"), 0.02, 0.40)

	# Left arm relaxed.
	var left_pivot := Node3D.new()
	left_pivot.position = Vector3(-0.76, 0.56, 0)
	left_pivot.rotation.z = deg_to_rad(35.0)
	mascot_root.add_child(left_pivot)
	_add_capsule(left_pivot, 0.20, 1.12, Vector3(0, -0.46, 0), Color("f5b920"), 0.03, 0.34)
	_add_sphere(left_pivot, 0.29, Vector3(0, -1.02, 0.02), Color("fff6df"), Vector3.ONE)

	# Right arm waves toward the player.
	wave_pivot = Node3D.new()
	wave_pivot.position = Vector3(0.76, 0.70, 0)
	wave_pivot.rotation.z = deg_to_rad(-42.0)
	mascot_root.add_child(wave_pivot)
	_add_capsule(wave_pivot, 0.20, 1.18, Vector3(0, 0.48, 0), Color("f5b920"), 0.03, 0.34)
	_add_sphere(wave_pivot, 0.30, Vector3(0, 1.07, 0.02), Color("fff6df"), Vector3.ONE)

	# Legs and chunky boots.
	for side in [-1.0, 1.0]:
		_add_capsule(mascot_root, 0.25, 0.82, Vector3(side * 0.38, -0.86, 0), Color("1c86e8"), 0.08, 0.34)
		_add_sphere(mascot_root, 0.34, Vector3(side * 0.38, -1.24, 0.18), Color("ff6748"), Vector3(1.18, 0.62, 1.52))

func _material(color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	if color.a < 0.995:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _add_sphere(parent: Node3D, radius: float, position_value: Vector3, color: Color, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.scale = scale_value
	instance.material_override = _material(color, 0.0, 0.26)
	parent.add_child(instance)
	return instance

func _add_capsule(parent: Node3D, radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_box(parent: Node3D, dimensions: Vector3, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.34) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 32
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance
