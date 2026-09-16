class_name RescueToken
extends SubViewportContainer

# The rescue target is now an actual lit 3D character rather than a flat draw
# routine. It remains a Control, so the existing Rescue Rush board/input logic
# can use it without changing puzzle behavior.
var rescue_id := "chick"
var accent := Color("ffd166")
var viewport_3d: SubViewport
var stage: Node3D
var character_root: Node3D
var face_root: Node3D
var phase := 0.0
var celebrating := false

func configure(id: String, color: Color = Color("ffd166")) -> void:
	rescue_id = id
	accent = color
	if is_inside_tree() and viewport_3d != null:
		call_deferred("_rebuild")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.name = "RescueCharacterViewport3D"
	viewport_3d.size = Vector2i(320, 320)
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport_3d)
	_build_stage()
	add_to_group("reduced_motion_aware")
	visibility_changed.connect(_sync_render_lifecycle)
	_sync_render_lifecycle()

func apply_motion_preference() -> void:
	_sync_render_lifecycle()

func _sync_render_lifecycle() -> void:
	if viewport_3d == null:
		return
	if not is_visible_in_tree():
		set_process(false)
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if MotionSystem.reduced():
		set_process(false)
		if character_root != null and is_instance_valid(character_root):
			character_root.position.y = 0.0
			character_root.rotation = Vector3.ZERO
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	set_process(true)
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _process(delta: float) -> void:
	phase += delta
	if character_root == null or celebrating:
		return
	if MotionSystem.reduced():
		_sync_render_lifecycle()
		return
	character_root.position.y = sin(phase * 2.8) * 0.055
	character_root.rotation.y = sin(phase * 1.25) * 0.08
	character_root.rotation.z = sin(phase * 1.9) * 0.025

func celebrate() -> void:
	if character_root == null or not is_instance_valid(character_root):
		return
	FeedbackManager.complete()
	if MotionSystem.reduced():
		character_root.scale = Vector3.ONE
		character_root.rotation_degrees = Vector3.ZERO
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	celebrating = true
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(character_root, "scale", Vector3(1.18, 0.84, 1.18), 0.09)
	tween.tween_property(character_root, "scale", Vector3(0.92, 1.20, 0.92), 0.10)
	tween.parallel().tween_property(character_root, "rotation_degrees:y", 22.0, 0.10)
	tween.tween_property(character_root, "scale", Vector3.ONE, 0.16)
	tween.parallel().tween_property(character_root, "rotation_degrees:y", -18.0, 0.16)
	tween.tween_property(character_root, "rotation_degrees:y", 0.0, 0.10)
	tween.tween_callback(func():
		celebrating = false
		_sync_render_lifecycle()
	)

func _rebuild() -> void:
	if stage != null and is_instance_valid(stage):
		stage.queue_free()
		stage = null
		character_root = null
		face_root = null
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_build_stage()
	_sync_render_lifecycle()

func _build_stage() -> void:
	if viewport_3d == null:
		return
	stage = Node3D.new()
	stage.name = "RescueCharacter3D"
	viewport_3d.add_child(stage)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("effcff")
	environment.ambient_light_energy = 1.30
	world_environment.environment = environment
	stage.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -32, 0)
	key.light_color = Color("fff3cf")
	key.light_energy = 1.65
	key.shadow_enabled = true
	stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-24, 146, 12)
	rim.light_color = Color("69dfff")
	rim.light_energy = 0.76
	stage.add_child(rim)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.28, 4.8)
	camera.fov = 37.0
	stage.add_child(camera)
	camera.look_at(Vector3(0, 0.22, 0), Vector3.UP)
	camera.current = true

	character_root = Node3D.new()
	character_root.name = "CharacterRoot"
	character_root.position = Vector3(0, -0.10, 0)
	stage.add_child(character_root)
	_build_character()

func _build_character() -> void:
	var colors := _variant_colors()
	var body_color: Color = colors[0]
	var detail_color: Color = colors[1]
	var dark_color: Color = colors[2]

	# Contact shadow and chunky feet anchor the miniature to the board tile.
	_add_sphere(character_root, 0.72, Vector3(0, -1.05, -0.18), Color(0.02, 0.14, 0.22, 0.20), Vector3(1.22, 0.12, 0.58))
	_add_sphere(character_root, 0.28, Vector3(-0.36, -0.82, 0.20), detail_color.darkened(0.08), Vector3(1.20, 0.58, 1.45))
	_add_sphere(character_root, 0.28, Vector3(0.36, -0.82, 0.20), detail_color.darkened(0.08), Vector3(1.20, 0.58, 1.45))

	# Body and head use overlapping glossy volumes for a toy-character silhouette.
	_add_sphere(character_root, 0.70, Vector3(0, -0.15, 0), body_color, Vector3(0.90, 1.02, 0.88))
	_add_sphere(character_root, 0.78, Vector3(0, 0.67, 0.04), body_color.lightened(0.03), Vector3(1.02, 0.94, 0.94))
	_add_sphere(character_root, 0.23, Vector3(-0.67, -0.15, 0.05), body_color.darkened(0.05), Vector3(0.72, 1.35, 0.72))
	_add_sphere(character_root, 0.23, Vector3(0.67, -0.15, 0.05), body_color.darkened(0.05), Vector3(0.72, 1.35, 0.72))

	face_root = Node3D.new()
	face_root.position = Vector3(0, 0.70, 0)
	character_root.add_child(face_root)
	_add_face(dark_color)
	_add_variant_details(body_color, detail_color, dark_color)

	# Broad top-light patches mimic the glossy sculpted finish of the reference.
	_add_sphere(character_root, 0.18, Vector3(-0.27, 1.02, 0.63), Color(1,1,1,0.28), Vector3(1.30,0.72,0.34))
	_add_sphere(character_root, 0.12, Vector3(-0.38, 0.10, 0.56), Color(1,1,1,0.16), Vector3(1.10,1.60,0.32))

func _add_face(dark_color: Color) -> void:
	for side in [-1.0, 1.0]:
		_add_sphere(face_root, 0.105, Vector3(side * 0.27, 0.10, 0.70), dark_color, Vector3(0.82, 1.12, 0.45))
		_add_sphere(face_root, 0.036, Vector3(side * 0.25 - side * 0.025, 0.15, 0.795), Color.WHITE, Vector3.ONE)
		_add_sphere(face_root, 0.14, Vector3(side * 0.43, -0.10, 0.66), Color("ff826f"), Vector3(1.0, 0.52, 0.28))
	# Smile is a small dark capsule with a pink inner volume.
	_add_capsule(face_root, 0.08, 0.30, Vector3(0, -0.15, 0.725), dark_color, 0.0, 0.28, Vector3(0,0,90))
	_add_sphere(face_root, 0.065, Vector3(0, -0.20, 0.785), Color("ff7891"), Vector3(1.35,0.38,0.35))

func _add_variant_details(body_color: Color, detail_color: Color, dark_color: Color) -> void:
	match rescue_id:
		"puppy":
			_add_sphere(character_root, 0.31, Vector3(-0.67, 1.08, 0.0), detail_color, Vector3(0.58,1.42,0.58))
			_add_sphere(character_root, 0.31, Vector3(0.67, 1.08, 0.0), detail_color, Vector3(0.58,1.42,0.58))
			_add_sphere(face_root, 0.13, Vector3(0, -0.01, 0.79), dark_color, Vector3(1.0,0.72,0.52))
		"kitten":
			_add_cone(character_root, 0.42, 0.68, Vector3(-0.46, 1.42, 0), body_color.darkened(0.06), Vector3(0,0,-18))
			_add_cone(character_root, 0.42, 0.68, Vector3(0.46, 1.42, 0), body_color.darkened(0.06), Vector3(0,0,18))
			for side in [-1.0, 1.0]:
				_add_box(face_root, Vector3(0.54,0.025,0.025), Vector3(side * 0.33,-0.12,0.76), Color("fff4e4"), 0.0, 0.30, Vector3(0, side * 8.0, side * 6.0))
		"robot":
			# Metallic face plate and antenna distinguish the robot while preserving the friendly silhouette.
			_add_box(character_root, Vector3(1.20,0.72,0.18), Vector3(0,0.70,0.63), Color("cde7f1"), 0.70, 0.18)
			_add_cylinder(character_root, 0.035, 0.035, 0.45, Vector3(0,1.60,0), Color("b9d2df"), 0.62, 0.22)
			_add_sphere(character_root, 0.12, Vector3(0,1.86,0), Color("ff4d55"), Vector3.ONE)
		"slime":
			_add_sphere(character_root, 0.50, Vector3(-0.42,-0.55,0), body_color, Vector3(1.0,0.45,0.82))
			_add_sphere(character_root, 0.50, Vector3(0.42,-0.55,0), body_color, Vector3(1.0,0.45,0.82))
		"panda":
			_add_sphere(character_root, 0.31, Vector3(-0.56,1.29,-0.02), Color("222936"), Vector3.ONE)
			_add_sphere(character_root, 0.31, Vector3(0.56,1.29,-0.02), Color("222936"), Vector3.ONE)
			_add_sphere(face_root, 0.20, Vector3(-0.27,0.08,0.63), Color("222936"), Vector3(1.25,1.0,0.42))
			_add_sphere(face_root, 0.20, Vector3(0.27,0.08,0.63), Color("222936"), Vector3(1.25,1.0,0.42))
		"fox":
			_add_cone(character_root, 0.46, 0.76, Vector3(-0.47,1.42,0), Color("f47d37"), Vector3(0,0,-20))
			_add_cone(character_root, 0.46, 0.76, Vector3(0.47,1.42,0), Color("f47d37"), Vector3(0,0,20))
			_add_sphere(face_root, 0.23, Vector3(0,-0.10,0.70), Color("fff1dc"), Vector3(1.55,0.80,0.42))
		"alien":
			_add_cylinder(character_root, 0.025,0.025,0.38,Vector3(-0.24,1.58,0),Color("74f1c0"),0.0,0.30,Vector3(0,0,-16))
			_add_cylinder(character_root, 0.025,0.025,0.38,Vector3(0.24,1.58,0),Color("74f1c0"),0.0,0.30,Vector3(0,0,16))
			_add_sphere(character_root,0.10,Vector3(-0.34,1.82,0),Color("ffd83d"),Vector3.ONE)
			_add_sphere(character_root,0.10,Vector3(0.34,1.82,0),Color("ff4ca5"),Vector3.ONE)
		_:
			# Chick beak and feather tuft.
			_add_cone(face_root, 0.16, 0.34, Vector3(0,-0.08,0.84), Color("ff8d1f"), Vector3(90,0,0))
			_add_sphere(character_root,0.15,Vector3(-0.10,1.48,0),Color("ffd83d"),Vector3(0.55,1.20,0.55))
			_add_sphere(character_root,0.13,Vector3(0.10,1.51,0),Color("ffed70"),Vector3(0.52,1.16,0.52))

func _variant_colors() -> Array[Color]:
	match rescue_id:
		"puppy": return [Color("d8945f"), Color("8b5a3c"), Color("273342")]
		"kitten": return [Color("ffb0c9"), Color("fff0e6"), Color("3e3150")]
		"robot": return [Color("91dff5"), Color("3d8ec6"), Color("17304a")]
		"slime": return [Color("6be56e"), Color("2faf50"), Color("173b32")]
		"panda": return [Color("f5f6f0"), Color("282e39"), Color("1f2631")]
		"fox": return [Color("f58c42"), Color("fff0da"), Color("3b2c2e")]
		"alien": return [Color("7ef0bd"), Color("36bc91"), Color("23334e")]
		_: return [accent, Color("ff9b2f"), Color("23334e")]

func _material(color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28) -> StandardMaterial3D:
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
	mesh.radial_segments = 24
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.scale = scale_value
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _add_box(parent: Node3D, dimensions: Vector3, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.rotation_degrees = rotation_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_capsule(parent: Node3D, radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.rotation_degrees = rotation_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.rotation_degrees = rotation_value
	instance.material_override = _material(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_cone(parent: Node3D, radius: float, height: float, position_value: Vector3, color: Color, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return _add_cylinder(parent, 0.0, radius, height, position_value, color, 0.0, 0.30, rotation_value)
