extends "res://scripts/ui/water_tube_reference_motion.gd"
class_name WaterTube3DMotion

const GLASS_BODY_RADIUS := 0.72
const GLASS_BODY_HEIGHT := 2.72
const GLASS_BODY_CENTER_Y := -0.18
const GLASS_SHOULDER_HEIGHT := 0.38
const GLASS_SHOULDER_CENTER_Y := 1.37
const GLASS_NECK_RADIUS := 0.40
const GLASS_NECK_HEIGHT := 0.36
const GLASS_NECK_CENTER_Y := 1.74
const GLASS_MOUTH_Y := 1.92
const GLASS_MOUTH_RADIUS := 0.42
const GLASS_BASE_Y := -1.54

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
var _arrival_impulse := 0.0
var _arrival_phase := 0.0

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
	_arrival_impulse = 0.0
	_arrival_phase = 0.0
	super.begin_pour_in(color_index, amount)
	_refresh_liquid_3d()

func set_pour_progress(value: float) -> void:
	set_process(true)
	var previous_progress := pour_progress
	super.set_pour_progress(value)
	# Each completed incoming unit produces a short surface displacement instead
	# of merely changing cylinder height. This is the perceptual "liquid landed"
	# moment missing from the otherwise-real 3D bottle.
	if pour_mode == 1 and pour_amount > 0:
		var previous_units := floori(previous_progress * float(pour_amount) + 0.0001)
		var current_units := floori(pour_progress * float(pour_amount) + 0.0001)
		if current_units > previous_units:
			_arrival_impulse = 1.0
			_arrival_phase = 0.0
	_refresh_liquid_3d()

func play_invalid() -> void:
	set_process(true)
	super.play_invalid()

func play_success() -> void:
	set_process(true)
	super.play_success()

func _process(delta: float) -> void:
	super._process(delta)
	if _arrival_impulse > 0.001:
		_arrival_phase += delta * 18.0
		_arrival_impulse = maxf(0.0, _arrival_impulse - delta * 4.8)
		_refresh_liquid_3d()
	_sync_motion_processing()

func _sync_motion_processing() -> void:
	var needs_motion := is_selected or invalid_flash > 0.001 or success_flash > 0.001 or pour_mode != 0 or slosh > 0.001 or _arrival_impulse > 0.001
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
	# Premium bottle silhouette built from real geometry: broad body, tapered
	# shoulder and narrow neck. This replaces the old single tapered cylinder
	# that was technically 3D but still read as a test tube on the phone.
	# Glass must remain visible over opaque liquid at phone scale. Use a wider,
	# brighter shell with a very small emissive lift; the liquid remains the colour
	# focal point while the vessel finally reads as a crystal bottle.
	var glass_material := _glass_material_3d(Color(0.76, 0.95, 1.0, 0.30), 0.030, 0.075)
	var shoulder_material := _glass_material_3d(Color(0.84, 0.99, 1.0, 0.34), 0.025, 0.090)

	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = GLASS_BODY_RADIUS
	body_mesh.bottom_radius = GLASS_BODY_RADIUS * 0.96
	body_mesh.height = GLASS_BODY_HEIGHT
	body_mesh.radial_segments = 32
	body_mesh.cap_top = false
	body_mesh.cap_bottom = true
	var body := MeshInstance3D.new()
	body.name = "BottleBody3D"
	body.mesh = body_mesh
	body.position.y = GLASS_BODY_CENTER_Y
	body.material_override = glass_material
	stage_3d.add_child(body)

	var shoulder_mesh := CylinderMesh.new()
	shoulder_mesh.top_radius = GLASS_NECK_RADIUS
	shoulder_mesh.bottom_radius = GLASS_BODY_RADIUS
	shoulder_mesh.height = GLASS_SHOULDER_HEIGHT
	shoulder_mesh.radial_segments = 32
	shoulder_mesh.cap_top = false
	shoulder_mesh.cap_bottom = false
	var shoulder := MeshInstance3D.new()
	shoulder.name = "BottleShoulder3D"
	shoulder.mesh = shoulder_mesh
	shoulder.position.y = GLASS_SHOULDER_CENTER_Y
	shoulder.material_override = shoulder_material
	stage_3d.add_child(shoulder)

	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = GLASS_NECK_RADIUS
	neck_mesh.bottom_radius = GLASS_NECK_RADIUS
	neck_mesh.height = GLASS_NECK_HEIGHT
	neck_mesh.radial_segments = 28
	neck_mesh.cap_top = false
	neck_mesh.cap_bottom = false
	var neck := MeshInstance3D.new()
	neck.name = "BottleNeck3D"
	neck.mesh = neck_mesh
	neck.position.y = GLASS_NECK_CENTER_Y
	neck.material_override = shoulder_material
	stage_3d.add_child(neck)

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = GLASS_MOUTH_RADIUS * 0.82
	rim_mesh.outer_radius = GLASS_MOUTH_RADIUS * 1.12
	rim_mesh.rings = 20
	rim_mesh.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.name = "BottleMouthRim3D"
	rim.mesh = rim_mesh
	rim.position.y = GLASS_MOUTH_Y
	rim.material_override = _material_3d(Color(0.94, 0.998, 1.0, 0.94), 0.0, 0.028)
	stage_3d.add_child(rim)

	var inner_rim_mesh := TorusMesh.new()
	inner_rim_mesh.inner_radius = GLASS_MOUTH_RADIUS * 0.68
	inner_rim_mesh.outer_radius = GLASS_MOUTH_RADIUS * 0.84
	inner_rim_mesh.rings = 18
	inner_rim_mesh.ring_segments = 7
	var inner_rim := MeshInstance3D.new()
	inner_rim.name = "BottleInnerRim3D"
	inner_rim.mesh = inner_rim_mesh
	inner_rim.position.y = GLASS_MOUTH_Y - 0.015
	inner_rim.material_override = _material_3d(Color(0.35, 0.78, 1.0, 0.42), 0.0, 0.040)
	stage_3d.add_child(inner_rim)

	var base_mesh := TorusMesh.new()
	base_mesh.inner_radius = GLASS_BODY_RADIUS * 0.78
	base_mesh.outer_radius = GLASS_BODY_RADIUS * 0.98
	base_mesh.rings = 18
	base_mesh.ring_segments = 7
	var base_rim := MeshInstance3D.new()
	base_rim.name = "BottleBaseRim3D"
	base_rim.mesh = base_mesh
	base_rim.position.y = GLASS_BASE_Y
	base_rim.material_override = _material_3d(Color(0.72, 0.94, 1.0, 0.62), 0.0, 0.050)
	stage_3d.add_child(base_rim)

	# A thin transparent inset shell gives visible wall thickness around coloured
	# liquid without drawing a fake vertical highlight stripe.
	var inner_shell_mesh := CylinderMesh.new()
	inner_shell_mesh.top_radius = GLASS_BODY_RADIUS * 0.84
	inner_shell_mesh.bottom_radius = GLASS_BODY_RADIUS * 0.82
	inner_shell_mesh.height = GLASS_BODY_HEIGHT - 0.10
	inner_shell_mesh.radial_segments = 28
	inner_shell_mesh.cap_top = false
	inner_shell_mesh.cap_bottom = false
	var inner_shell := MeshInstance3D.new()
	inner_shell.name = "BottleInnerWall3D"
	inner_shell.mesh = inner_shell_mesh
	inner_shell.position.y = GLASS_BODY_CENTER_Y
	inner_shell.material_override = _glass_material_3d(Color(0.30, 0.76, 0.96, 0.105), 0.045, 0.045)
	stage_3d.add_child(inner_shell)

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.76
	shadow_mesh.bottom_radius = 0.76
	shadow_mesh.height = 0.025
	shadow_mesh.radial_segments = 28
	var contact_shadow := MeshInstance3D.new()
	contact_shadow.name = "TubeContactShadow"
	contact_shadow.mesh = shadow_mesh
	contact_shadow.position = Vector3(0.10, GLASS_BASE_Y - 0.16, -0.08)
	contact_shadow.scale = Vector3(1.0, 1.0, 0.50)
	contact_shadow.material_override = _material_3d(Color(0.02, 0.15, 0.28, 0.22), 0.0, 0.18)
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
		mesh.top_radius = 0.46
		mesh.bottom_radius = 0.46
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
	mesh.radius = 0.46
	mesh.height = 0.92
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
			# Arrival ripple: flatten on contact, then rebound with a small lateral
			# wobble. It affects only the exposed meniscus/root and costs no particles.
			var arrival_wave := sin(_arrival_phase) * _arrival_impulse
			var arrival_flatten := _arrival_impulse * (0.030 + 0.010 * absf(arrival_wave))
			liquid_meniscus_3d.position = Vector3(arrival_wave * 0.035, top_surface - 0.01 - arrival_flatten * 0.20, 0)
			liquid_meniscus_3d.scale = Vector3(1.0 + arrival_flatten * 1.8, maxf(0.075, 0.11 - arrival_flatten), 1.0 + arrival_flatten * 1.3)
			liquid_root_3d.rotation.z = deg_to_rad(arrival_wave * 1.8)
			if top_color < liquid_materials_3d.size():
				liquid_meniscus_3d.material_override = liquid_materials_3d[top_color]
		else:
			liquid_root_3d.rotation.z = 0.0
	_request_3d_frame()

func _glass_material_3d(color: Color, roughness_value: float, emission_energy: float) -> StandardMaterial3D:
	var material := _material_3d(color, 0.0, roughness_value)
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = emission_energy
	return material

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
	return _project_rim_point(Vector3(0.0, GLASS_MOUTH_Y, 0.0))

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
		var rim_3d := Vector3(cos(angle) * GLASS_MOUTH_RADIUS, GLASS_MOUTH_Y, sin(angle) * GLASS_MOUTH_RADIUS)
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
