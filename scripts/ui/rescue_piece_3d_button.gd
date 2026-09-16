extends "res://scripts/ui/premium_piece_button.gd"
class_name RescuePiece3DButton

# Real 3D visual for Rescue Rush board pieces. Gameplay still lives entirely in
# the board state; this control only renders the already-authoritative piece.
# Each piece is one-shot rendered while idle, so a board full of pieces does not
# create a permanent set of SubViewport render loops on Android.
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport
var stage_3d: Node3D
var piece_root_3d: Node3D

func configure(type_value: String, direction_value: String, base_color: Color) -> void:
	super.configure(type_value, direction_value, base_color)
	if viewport_3d != null:
		_rebuild_piece_3d()

func _ready() -> void:
	super._ready()
	# PremiumPieceButton animates its Canvas drawing every frame. This subclass
	# renders the tile through a one-shot 3D viewport and overrides _draw(), so the
	# inherited idle loop only wastes per-piece CPU/redraw work and can fight the
	# direct press/release tweens. Keep it asleep while idle.
	set_process(false)
	_build_viewport_3d()
	_rebuild_piece_3d()

func _draw() -> void:
	# The inherited Control remains responsible for input/press/hover motion, but
	# the visible tile itself is rendered by the real 3D child viewport.
	pass

func _build_viewport_3d() -> void:
	if viewport_3d != null:
		return
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "RescuePiece3DView"
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = true
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(viewport_container)

	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.name = "RescuePieceViewport3D"
	viewport_3d.size = Vector2i(256, 256)
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_container.add_child(viewport_3d)

	stage_3d = Node3D.new()
	stage_3d.name = "RescuePieceStage3D"
	viewport_3d.add_child(stage_3d)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dff6ff")
	environment.ambient_light_energy = 1.05
	world_environment.environment = environment
	stage_3d.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -34, 0)
	key.light_color = Color("fff6de")
	key.light_energy = 1.45
	key.shadow_enabled = false
	stage_3d.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-24, 142, 0)
	rim.light_color = glow.lightened(0.32)
	rim.light_energy = 0.66
	stage_3d.add_child(rim)

	var camera := Camera3D.new()
	camera.position = Vector3(3.7, 4.6, 6.4)
	camera.fov = 38.0
	stage_3d.add_child(camera)
	camera.look_at(Vector3(0, 0.18, 0), Vector3.UP)
	camera.current = true

func _rebuild_piece_3d() -> void:
	if viewport_3d == null or stage_3d == null:
		return
	if piece_root_3d != null and is_instance_valid(piece_root_3d):
		piece_root_3d.queue_free()
	piece_root_3d = Node3D.new()
	piece_root_3d.name = "PieceVisual3D"
	stage_3d.add_child(piece_root_3d)

	_build_tile_shell()
	match piece_type:
		"rotate": _build_rotate_symbol()
		"key": _build_key_symbol()
		"gate": _build_gate_symbol()
		"bomb": _build_bomb_symbol()
		"linked": _build_linked_symbol()
		"blocker": _build_blocker_symbol()
		_: _build_arrow_symbol()
	_request_3d_frame()

func _build_tile_shell() -> void:
	_add_box(piece_root_3d, Vector3(2.20, 0.52, 2.20), Vector3(0, 0, 0), accent.darkened(0.18), 0.02, 0.28)
	_add_box(piece_root_3d, Vector3(2.04, 0.28, 2.04), Vector3(0, 0.28, 0), accent, 0.03, 0.20)
	_add_box(piece_root_3d, Vector3(1.70, 0.035, 0.42), Vector3(-0.08, 0.445, -0.63), Color(1, 1, 1, 0.28), 0.0, 0.12)
	_add_box(piece_root_3d, Vector3(0.10, 0.18, 1.45), Vector3(-0.79, 0.31, 0.08), Color(1, 1, 1, 0.16), 0.0, 0.16)

func _build_arrow_symbol() -> void:
	var symbol := Node3D.new()
	symbol.name = "ArrowSymbol3D"
	symbol.position.y = 0.50
	symbol.rotation_degrees.y = _direction_yaw(direction)
	piece_root_3d.add_child(symbol)
	_add_box(symbol, Vector3(1.02, 0.12, 0.34), Vector3(-0.18, 0, 0), Color.WHITE, 0.0, 0.18)
	var wing_a := _add_box(symbol, Vector3(0.72, 0.12, 0.30), Vector3(0.45, 0, -0.30), Color.WHITE, 0.0, 0.18)
	wing_a.rotation_degrees.y = -38.0
	var wing_b := _add_box(symbol, Vector3(0.72, 0.12, 0.30), Vector3(0.45, 0, 0.30), Color.WHITE, 0.0, 0.18)
	wing_b.rotation_degrees.y = 38.0

func _build_rotate_symbol() -> void:
	var ring := _add_torus(piece_root_3d, 0.46, 0.69, Vector3(0, 0.53, 0), Color.WHITE)
	ring.rotation_degrees.y = 12.0
	var head := _add_box(piece_root_3d, Vector3(0.48, 0.12, 0.25), Vector3(0.52, 0.56, -0.28), Color.WHITE, 0.0, 0.18)
	head.rotation_degrees.y = -32.0

func _build_key_symbol() -> void:
	_add_torus(piece_root_3d, 0.24, 0.43, Vector3(-0.45, 0.53, 0), Color.WHITE)
	_add_box(piece_root_3d, Vector3(1.12, 0.12, 0.22), Vector3(0.26, 0.53, 0), Color.WHITE, 0.0, 0.18)
	_add_box(piece_root_3d, Vector3(0.18, 0.12, 0.42), Vector3(0.53, 0.53, 0.18), Color.WHITE, 0.0, 0.18)
	_add_box(piece_root_3d, Vector3(0.18, 0.12, 0.34), Vector3(0.83, 0.53, 0.14), Color.WHITE, 0.0, 0.18)

func _build_gate_symbol() -> void:
	for x in [-0.58, 0.0, 0.58]:
		_add_box(piece_root_3d, Vector3(0.18, 0.46, 1.38), Vector3(x, 0.62, 0), Color("f4f8ff"), 0.06, 0.22)
	_add_box(piece_root_3d, Vector3(1.42, 0.22, 0.20), Vector3(0, 0.78, -0.58), Color("f4f8ff"), 0.06, 0.22)
	_add_box(piece_root_3d, Vector3(1.42, 0.22, 0.20), Vector3(0, 0.78, 0.58), Color("f4f8ff"), 0.06, 0.22)

func _build_bomb_symbol() -> void:
	_add_sphere(piece_root_3d, 0.62, Vector3(0, 0.80, 0), Color("f7fbff"))
	var fuse := _add_cylinder(piece_root_3d, 0.09, 0.09, 0.54, Vector3(0.43, 1.23, -0.14), Color("f7fbff"))
	fuse.rotation_degrees.z = 48.0
	_add_sphere(piece_root_3d, 0.13, Vector3(0.61, 1.45, -0.14), Unjam3DTheme.GOLD)

func _build_linked_symbol() -> void:
	var left := _add_torus(piece_root_3d, 0.26, 0.48, Vector3(-0.42, 0.58, 0), Color.WHITE)
	left.rotation_degrees.z = 12.0
	var right := _add_torus(piece_root_3d, 0.26, 0.48, Vector3(0.42, 0.58, 0), Color.WHITE)
	right.rotation_degrees.z = -12.0
	_add_box(piece_root_3d, Vector3(0.54, 0.10, 0.20), Vector3(0, 0.58, 0), Color.WHITE, 0.0, 0.18)

func _build_blocker_symbol() -> void:
	_add_box(piece_root_3d, Vector3(1.55, 0.44, 1.55), Vector3(0, 0.55, 0), Color("596674"), 0.20, 0.30)
	for x in [-0.50, 0.50]:
		for z in [-0.50, 0.50]:
			_add_cylinder(piece_root_3d, 0.11, 0.11, 0.12, Vector3(x, 0.84, z), Color("e3ebf2"), 0.35, 0.20)

func _direction_yaw(value: String) -> float:
	match value:
		"left": return 180.0
		"up": return 90.0
		"down": return -90.0
		_: return 0.0

func _material_3d(color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	if color.a < 0.995:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _add_box(parent: Node3D, dimensions: Vector3, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material_3d(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _add_torus(parent: Node3D, inner_radius: float, outer_radius: float, position_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 20
	mesh.ring_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material_3d(color, 0.05, 0.20)
	parent.add_child(instance)
	return instance

func _add_sphere(parent: Node3D, radius: float, position_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 18
	mesh.rings = 10
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material_3d(color, 0.02, 0.22)
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, color: Color, metallic_value: float = 0.0, roughness_value: float = 0.28) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = _material_3d(color, metallic_value, roughness_value)
	parent.add_child(instance)
	return instance

func _request_3d_frame() -> void:
	if viewport_3d != null:
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
