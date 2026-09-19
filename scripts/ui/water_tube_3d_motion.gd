extends "res://scripts/ui/water_tube_reference_motion.gd"
class_name WaterTube3DMotion

# Real 3D presentation layered under the existing authoritative Water Sort
# control. The SubViewport is one-shot while idle; pour progress explicitly
# requests frames, so a board full of tubes does not create permanent 3D loops.
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport
var stage_3d: Node3D
var camera_3d: Camera3D
var liquid_root_3d: Node3D
var liquid_meniscus_3d: MeshInstance3D
var liquid_segments_3d: Array[MeshInstance3D] = []
var liquid_materials_3d: Array[StandardMaterial3D] = []

func configure(values: Array, selected: bool, index: int) -> void:
	super.configure(values, selected, index)
	if viewport_3d != null:
		_refresh_liquid_3d()
		_request_3d_frame()
	if is_inside_tree():
		_sync_motion_processing()

func _ready() -> void:
	super._ready()
	_build_3d_view()
	_refresh_liquid_3d()
	_request_3d_frame()
	_sync_motion_processing()

func begin_pour_out(amount: int) -> void:
	set_process(true)
	super.begin_pour_out(amount)
	_refresh_liquid_3d()

func begin_pour_in(color_index: int, amount: int) -> void:
	set_process(true)
	super.begin_pour_in(color_index, amount)
	_refresh_liquid_3d()

func set_pour_progress(value: float) -> void:
	set_process(true)
	super.set_pour_progress(value)
	_refresh_liquid_3d()

func play_invalid() -> void:
	set_process(true)
	super.play_invalid()

func play_success() -> void:
	set_process(true)
	super.play_success()

func _process(delta: float) -> void:
	super._process(delta)
	_sync_motion_processing()

func _sync_motion_processing() -> void:
	var needs_motion := is_selected or invalid_flash > 0.001 or success_flash > 0.001 or pour_mode != 0 or slosh > 0.001
	set_process(needs_motion)

func _build_3d_view() -> void:
	if viewport_3d != null:
		return
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "WaterTube3DView"
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = true
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the real 3D bottle above the translucent stage panel. A negative
	# z-index puts it behind ancestor panel chrome and visibly bleaches the liquid.
	viewport_container.z_index = 0
	add_child(viewport_container)

	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.name = "TubeViewport3D"
	# Slightly above the on-screen tube resolution, but far below the old
	# 220x420 buffer. Idle tubes still render only once.
	viewport_3d.size = Vector2i(192, 384)
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
	environment.ambient_light_energy = 0.82
	world_environment.environment = environment
	stage_3d.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -36, 0)
	key.light_color = Color("fff8e8")
	key.light_energy = 1.70
	key.shadow_enabled = false
	stage_3d.add_child(key)
	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-20, 145, 8)
	rim_light.light_color = Color("70dcff")
	rim_light.light_energy = 1.10
	stage_3d.add_child(rim_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2.2, 2.8, 4.1)
	fill_light.light_color = Color("b6f2ff")
	fill_light.light_energy = 0.30
	fill_light.omni_range = 9.0
	stage_3d.add_child(fill_light)

	camera_3d = Camera3D.new()
	camera_3d.position = Vector3(2.30, 0.72, 7.15)
	camera_3d.fov = 31.0
	stage_3d.add_child(camera_3d)
	camera_3d.look_at(Vector3(0, 0.08, 0), Vector3.UP)
	camera_3d.current = true

	_build_glass_3d()
	_build_liquid_materials_3d()
	_build_liquid_segments_3d()
	_build_liquid_meniscus_3d()

func _build_glass_3d() -> void:
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = 0.62
	glass_mesh.bottom_radius = 0.54
	glass_mesh.height = 3.32
	glass_mesh.radial_segments = 24
	glass_mesh.cap_top = false
	glass_mesh.cap_bottom = true
	var glass := MeshInstance3D.new()
	glass.name = "OpenTopGlass"
	glass.mesh = glass_mesh
	glass.material_override = _material_3d(Color(0.82, 0.97, 1.0, 0.11), 0.0, 0.045)
	stage_3d.add_child(glass)

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.56
	rim_mesh.outer_radius = 0.68
	rim_mesh.rings = 16
	rim_mesh.ring_segments = 6
	var rim := MeshInstance3D.new()
	rim.name = "OpenGlassRim"
	rim.mesh = rim_mesh
	rim.position.y = 1.66
	rim.material_override = _material_3d(Color(0.92, 0.995, 1.0, 0.90), 0.0, 0.045)
	stage_3d.add_child(rim)

	var base_mesh := TorusMesh.new()
	base_mesh.inner_radius = 0.47
	base_mesh.outer_radius = 0.57
	base_mesh.rings = 14
	base_mesh.ring_segments = 6
	var base_rim := MeshInstance3D.new()
	base_rim.mesh = base_mesh
	base_rim.position.y = -1.61
	base_rim.material_override = _material_3d(Color(0.80, 0.96, 1.0, 0.56), 0.0, 0.065)
	stage_3d.add_child(base_rim)

	var highlight_mesh := BoxMesh.new()
	highlight_mesh.size = Vector3(0.055, 2.46, 0.055)
	var highlight := MeshInstance3D.new()
	highlight.mesh = highlight_mesh
	highlight.position = Vector3(-0.34, 0.05, 0.51)
	highlight.material_override = _material_3d(Color(1, 1, 1, 0.72), 0.0, 0.035)
	stage_3d.add_child(highlight)

	var secondary_highlight_mesh := BoxMesh.new()
	secondary_highlight_mesh.size = Vector3(0.035, 1.62, 0.035)
	var secondary_highlight := MeshInstance3D.new()
	secondary_highlight.name = "GlassSecondaryHighlight"
	secondary_highlight.mesh = secondary_highlight_mesh
	secondary_highlight.position = Vector3(0.31, 0.34, 0.50)
	secondary_highlight.material_override = _material_3d(Color(1, 1, 1, 0.38), 0.0, 0.03)
	stage_3d.add_child(secondary_highlight)

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.72
	shadow_mesh.bottom_radius = 0.72
	shadow_mesh.height = 0.025
	shadow_mesh.radial_segments = 24
	var contact_shadow := MeshInstance3D.new()
	contact_shadow.name = "TubeContactShadow"
	contact_shadow.mesh = shadow_mesh
	contact_shadow.position = Vector3(0.10, -1.77, -0.08)
	contact_shadow.scale = Vector3(1.0, 1.0, 0.52)
	contact_shadow.material_override = _material_3d(Color(0.02, 0.15, 0.28, 0.20), 0.0, 0.18)
	stage_3d.add_child(contact_shadow)

func _build_liquid_materials_3d() -> void:
	# Cache palette materials once. Pour progress changes mesh height only; it no
	# longer allocates new StandardMaterial3D resources every animation frame.
	liquid_materials_3d.clear()
	for color in PALETTE:
		liquid_materials_3d.append(_material_3d(color.lightened(0.025), 0.0, 0.10))

func _build_liquid_segments_3d() -> void:
	liquid_root_3d = Node3D.new()
	liquid_root_3d.name = "LiquidVolumes3D"
	stage_3d.add_child(liquid_root_3d)
	liquid_segments_3d.clear()
	for slot in range(CAPACITY):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.49
		mesh.bottom_radius = 0.49
		mesh.height = 0.60
		mesh.radial_segments = 20
		# Interior liquid volumes do not own horizontal caps. Contiguous slots
		# are merged into one run below, and only the exposed top gets a meniscus.
		# This removes the stacked-solid-disc look between equal colours.
		mesh.cap_top = false
		mesh.cap_bottom = false
		var segment := MeshInstance3D.new()
		segment.name = "LiquidSegment%d" % slot
		segment.mesh = mesh
		segment.visible = false
		liquid_root_3d.add_child(segment)
		liquid_segments_3d.append(segment)

func _build_liquid_meniscus_3d() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.49
	mesh.height = 0.98
	mesh.radial_segments = 24
	mesh.rings = 8
	liquid_meniscus_3d = MeshInstance3D.new()
	liquid_meniscus_3d.name = "LiquidMeniscus3D"
	liquid_meniscus_3d.mesh = mesh
	liquid_meniscus_3d.scale = Vector3(1.0, 0.11, 1.0)
	liquid_meniscus_3d.visible = false
	liquid_root_3d.add_child(liquid_meniscus_3d)

func _liquid_runs_3d(slot_height: float, liquid_bottom: float) -> Array:
	var runs: Array = []
	var active := false
	var run_color := -1
	var run_bottom := liquid_bottom
	var run_height := 0.0
	for slot in range(CAPACITY):
		var fraction := _slot_fill(slot)
		if fraction <= 0.001:
			if active:
				runs.append({"color": run_color, "bottom": run_bottom, "height": run_height})
				active = false
				run_height = 0.0
			continue
		var color_index := clampi(_slot_color(slot), 0, PALETTE.size() - 1)
		var slot_bottom := liquid_bottom + float(slot) * slot_height
		var fill_height := slot_height * fraction
		var touches_previous := active and absf((run_bottom + run_height) - slot_bottom) <= 0.025
		if active and run_color == color_index and touches_previous:
			run_height += fill_height
		else:
			if active:
				runs.append({"color": run_color, "bottom": run_bottom, "height": run_height})
			active = true
			run_color = color_index
			run_bottom = slot_bottom
			run_height = fill_height
	if active:
		runs.append({"color": run_color, "bottom": run_bottom, "height": run_height})
	return runs

func _refresh_liquid_3d() -> void:
	if viewport_3d == null or liquid_segments_3d.size() != CAPACITY:
		return
	var slot_height := 0.63
	var liquid_bottom := -1.43
	for segment in liquid_segments_3d:
		segment.visible = false
	var runs := _liquid_runs_3d(slot_height, liquid_bottom)
	var top_surface := liquid_bottom
	var top_color := 0
	for run_index in range(mini(runs.size(), liquid_segments_3d.size())):
		var run: Dictionary = runs[run_index]
		var segment := liquid_segments_3d[run_index]
		var height := maxf(0.025, float(run.get("height", 0.0)))
		var bottom := float(run.get("bottom", liquid_bottom))
		var color_index := clampi(int(run.get("color", 0)), 0, PALETTE.size() - 1)
		var mesh := segment.mesh as CylinderMesh
		if mesh != null:
			mesh.height = height
		segment.position = Vector3(0, bottom + height * 0.5, 0)
		if color_index < liquid_materials_3d.size():
			segment.material_override = liquid_materials_3d[color_index]
		segment.visible = true
		top_surface = bottom + height
		top_color = color_index
	if liquid_meniscus_3d != null:
		liquid_meniscus_3d.visible = not runs.is_empty()
		if not runs.is_empty():
			liquid_meniscus_3d.position = Vector3(0, top_surface - 0.01, 0)
			if top_color < liquid_materials_3d.size():
				liquid_meniscus_3d.material_override = liquid_materials_3d[top_color]
	_request_3d_frame()

func _material_3d(color: Color, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = clampf(roughness_value, 0.025, 0.24)
	material.clearcoat_enabled = true
	material.clearcoat = 0.92 if color.a < 0.995 else 0.78
	material.clearcoat_roughness = 0.035 if color.a < 0.995 else 0.075
	if color.a < 0.995:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		material.emission_enabled = true
		material.emission = color.darkened(0.72)
		material.emission_energy_multiplier = 0.22
	return material

func _request_3d_frame() -> void:
	if viewport_3d != null:
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _project_rim_point(local_3d: Vector3) -> Vector2:
	if camera_3d == null or viewport_3d == null or stage_3d == null:
		return Vector2(size.x * 0.5, size.y * 0.10)
	var viewport_point := camera_3d.unproject_position(stage_3d.to_global(local_3d))
	var viewport_size := Vector2(viewport_3d.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2(size.x * 0.5, size.y * 0.10)
	return Vector2(
		viewport_point.x / viewport_size.x * size.x,
		viewport_point.y / viewport_size.y * size.y
	)

func visual_receive_rim_local() -> Vector2:
	# Project the actual 3D opening center instead of reusing the retired 2D
	# bottle rectangle. This keeps the incoming stream glued to the rendered rim
	# across responsive tube sizes and SubViewport stretching.
	return _project_rim_point(Vector3(0.0, 1.66, 0.0))

func visual_pour_rim_local(direction: float) -> Vector2:
	# Find the left/right screen edge of the real 3D torus rim. Camera perspective
	# means a fixed world-X offset is not guaranteed to be the visible downhill
	# lip, so sample the circumference and select by projected screen X.
	if camera_3d == null or viewport_3d == null or stage_3d == null:
		return super.visual_pour_rim_local(direction)
	var want_right := direction >= 0.0
	var best := visual_receive_rim_local()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		var rim_3d := Vector3(cos(angle) * 0.62, 1.66, sin(angle) * 0.62)
		var projected := _project_rim_point(rim_3d)
		if (want_right and projected.x > best.x) or (not want_right and projected.x < best.x):
			best = projected
	return best

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
