extends "res://scripts/ui/water_tube_reference_motion.gd"
class_name WaterTube3DMotion

# Real 3D presentation layered under the existing authoritative Water Sort
# control. The SubViewport is one-shot while idle; pour progress explicitly
# requests frames, so a board full of tubes does not create permanent 3D loops.
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport
var stage_3d: Node3D
var liquid_root_3d: Node3D
var liquid_segments_3d: Array[MeshInstance3D] = []
var liquid_materials_3d: Array[StandardMaterial3D] = []

func configure(values: Array, selected: bool, index: int) -> void:
	super.configure(values, selected, index)
	if viewport_3d != null:
		_refresh_liquid_3d()
		_request_3d_frame()

func _ready() -> void:
	super._ready()
	_build_3d_view()
	_refresh_liquid_3d()
	_request_3d_frame()

func begin_pour_out(amount: int) -> void:
	super.begin_pour_out(amount)
	_refresh_liquid_3d()

func begin_pour_in(color_index: int, amount: int) -> void:
	super.begin_pour_in(color_index, amount)
	_refresh_liquid_3d()

func set_pour_progress(value: float) -> void:
	super.set_pour_progress(value)
	_refresh_liquid_3d()

func _build_3d_view() -> void:
	if viewport_3d != null:
		return
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "WaterTube3DView"
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = true
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(viewport_container)

	viewport_3d = SubViewport.new()
	viewport_3d.name = "TubeViewport3D"
	viewport_3d.size = Vector2i(220, 420)
	viewport_3d.transparent_bg = true
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_container.add_child(viewport_3d)

	stage_3d = Node3D.new()
	stage_3d.name = "TubeStage3D"
	viewport_3d.add_child(stage_3d)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dff8ff")
	environment.ambient_light_energy = 1.15
	world_environment.environment = environment
	stage_3d.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -36, 0)
	key.light_color = Color("fff8e8")
	key.light_energy = 1.45
	key.shadow_enabled = false
	stage_3d.add_child(key)
	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-20, 145, 8)
	rim_light.light_color = Color("70dcff")
	rim_light.light_energy = 0.72
	stage_3d.add_child(rim_light)

	var camera := Camera3D.new()
	camera.position = Vector3(3.05, 0.90, 6.65)
	camera.fov = 31.0
	stage_3d.add_child(camera)
	camera.look_at(Vector3(0, 0.08, 0), Vector3.UP)
	camera.current = true

	_build_glass_3d()
	_build_liquid_materials_3d()
	_build_liquid_segments_3d()

func _build_glass_3d() -> void:
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = 0.62
	glass_mesh.bottom_radius = 0.54
	glass_mesh.height = 3.32
	glass_mesh.radial_segments = 20
	glass_mesh.cap_top = false
	glass_mesh.cap_bottom = true
	var glass := MeshInstance3D.new()
	glass.name = "OpenTopGlass"
	glass.mesh = glass_mesh
	glass.material_override = _material_3d(Color(0.78, 0.96, 1.0, 0.20), 0.0, 0.08)
	stage_3d.add_child(glass)

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.56
	rim_mesh.outer_radius = 0.68
	rim_mesh.rings = 20
	rim_mesh.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.name = "OpenGlassRim"
	rim.mesh = rim_mesh
	rim.position.y = 1.66
	rim.material_override = _material_3d(Color(0.88, 0.99, 1.0, 0.72), 0.0, 0.10)
	stage_3d.add_child(rim)

	var base_mesh := TorusMesh.new()
	base_mesh.inner_radius = 0.47
	base_mesh.outer_radius = 0.57
	base_mesh.rings = 18
	base_mesh.ring_segments = 8
	var base_rim := MeshInstance3D.new()
	base_rim.mesh = base_mesh
	base_rim.position.y = -1.61
	base_rim.material_override = _material_3d(Color(0.74, 0.94, 1.0, 0.38), 0.0, 0.12)
	stage_3d.add_child(base_rim)

	var highlight_mesh := BoxMesh.new()
	highlight_mesh.size = Vector3(0.055, 2.46, 0.055)
	var highlight := MeshInstance3D.new()
	highlight.mesh = highlight_mesh
	highlight.position = Vector3(-0.34, 0.05, 0.51)
	highlight.material_override = _material_3d(Color(1, 1, 1, 0.52), 0.0, 0.06)
	stage_3d.add_child(highlight)

func _build_liquid_materials_3d() -> void:
	liquid_materials_3d.clear()
	for color in PALETTE:
		liquid_materials_3d.append(_material_3d(color, 0.02, 0.20))

func _build_liquid_segments_3d() -> void:
	liquid_root_3d = Node3D.new()
	liquid_root_3d.name = "LiquidVolumes3D"
	stage_3d.add_child(liquid_root_3d)
	liquid_segments_3d.clear()
	for slot in range(CAPACITY):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.46
		mesh.bottom_radius = 0.46
		mesh.height = 0.60
		mesh.radial_segments = 18
		mesh.cap_top = true
		mesh.cap_bottom = true
		var segment := MeshInstance3D.new()
		segment.name = "LiquidSegment%d" % slot
		segment.mesh = mesh
		segment.visible = false
		liquid_root_3d.add_child(segment)
		liquid_segments_3d.append(segment)

func _refresh_liquid_3d() -> void:
	if viewport_3d == null or liquid_segments_3d.size() != CAPACITY:
		return
	var slot_height := 0.63
	var liquid_bottom := -1.43
	for slot in range(CAPACITY):
		var segment := liquid_segments_3d[slot]
		var fraction := _slot_fill(slot)
		if fraction <= 0.001:
			segment.visible = false
			continue
		segment.visible = true
		var height := maxf(0.025, slot_height * fraction - 0.018)
		var mesh := segment.mesh as CylinderMesh
		if mesh != null:
			mesh.height = height
		var slot_bottom := liquid_bottom + float(slot) * slot_height
		segment.position = Vector3(0, slot_bottom + height * 0.5, 0)
		var color_index := clampi(_slot_color(slot), 0, PALETTE.size() - 1)
		if color_index < liquid_materials_3d.size():
			segment.material_override = liquid_materials_3d[color_index]
	_request_3d_frame()

func _material_3d(color: Color, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	if color.a < 0.995:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _request_3d_frame() -> void:
	if viewport_3d != null:
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _draw() -> void:
	# Keep interaction feedback in the inexpensive 2D layer while the bottle and
	# liquid themselves are real 3D. The outline is local, not a screen flash.
	var center := size * 0.5
	var radius := maxf(18.0, minf(size.x, size.y) * 0.38)
	if is_selected and pour_mode == 0:
		var alpha := 0.34 if MotionSystem.reduced() else 0.34 + 0.12 * sin(pulse * 5.0)
		draw_arc(center, radius, 0.0, TAU, 40, Color(1.0, 0.88, 0.35, alpha), 4.0, true)
	if invalid_flash > 0.0:
		draw_arc(center, radius + 3.0, 0.0, TAU, 40, Color("ff4d67", invalid_flash), 5.0, true)
	if success_flash > 0.0:
		draw_arc(center, radius + 3.0, 0.0, TAU, 40, Color("7ff0b0", success_flash), 5.0, true)
