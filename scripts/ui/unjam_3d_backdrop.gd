class_name Unjam3DBackdrop
extends SubViewportContainer

# One persistent real-3D fantasy water world behind every launcher surface.
# It is built from lightweight Godot primitives, rendered at a mobile-friendly
# fixed resolution and switched to one-shot rendering once settled.
var accent: Color = Unjam3DTheme.GREEN
var dark_mode := false

var viewport_3d: SubViewport
var stage: Node3D
var world_environment: WorldEnvironment
var environment: Environment
var key_light: DirectionalLight3D
var rim_light: DirectionalLight3D
var warm_fill: OmniLight3D
var water_material: StandardMaterial3D
var accent_materials: Array[StandardMaterial3D] = []

func configure(value: Color, use_dark_mode: bool = false) -> void:
	accent = value
	dark_mode = use_dark_mode
	if environment != null:
		_apply_world_style()
		_request_render()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_build_world()
	visibility_changed.connect(_sync_render_activity)
	_sync_render_activity()
	call_deferred("_finish_initial_render")

func _sync_render_activity() -> void:
	if viewport_3d == null:
		return
	if is_visible_in_tree():
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _finish_initial_render() -> void:
	for _i in range(3):
		if not is_inside_tree():
			return
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
	if viewport_3d != null and is_instance_valid(viewport_3d):
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _request_render() -> void:
	if viewport_3d != null and is_instance_valid(viewport_3d):
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE

func _build_world() -> void:
	viewport_3d = SubViewport.new()
	viewport_3d.name = "PremiumWorldViewport3D"
	viewport_3d.size = Vector2i(720, 1280)
	viewport_3d.own_world_3d = true
	viewport_3d.transparent_bg = false
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)

	stage = Node3D.new()
	stage.name = "PremiumWaterWorld"
	viewport_3d.add_child(stage)

	_build_environment()
	_build_camera()
	_build_sky_details()
	_build_water()
	_build_distant_world()
	_build_bridge()
	_build_waterfalls()
	_build_shoreline()
	_build_stepping_stones()
	_build_foreground_frame()
	_apply_world_style()

func _build_environment() -> void:
	world_environment = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("34b9f6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dffaff")
	environment.ambient_light_energy = 0.92
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	world_environment.environment = environment
	stage.add_child(world_environment)

	key_light = DirectionalLight3D.new()
	key_light.name = "WarmSun"
	key_light.rotation_degrees = Vector3(-46, -34, -7)
	key_light.light_color = Color("fff1c5")
	key_light.light_energy = 1.34
	key_light.shadow_enabled = true
	stage.add_child(key_light)

	rim_light = DirectionalLight3D.new()
	rim_light.name = "SkyRim"
	rim_light.rotation_degrees = Vector3(-24, 146, 15)
	rim_light.light_color = Color("8fe7ff")
	rim_light.light_energy = 0.66
	stage.add_child(rim_light)

	warm_fill = OmniLight3D.new()
	warm_fill.name = "WaterBounce"
	warm_fill.position = Vector3(0, 1.2, 5.4)
	warm_fill.light_color = Color("8ff4ff")
	warm_fill.light_energy = 0.56
	warm_fill.omni_range = 24.0
	stage.add_child(warm_fill)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "WorldCamera"
	camera.position = Vector3(0.0, 5.6, 15.8)
	camera.fov = 43.0
	camera.near = 0.2
	camera.far = 80.0
	stage.add_child(camera)
	camera.look_at(Vector3(0.0, 0.45, -5.8), Vector3.UP)
	camera.current = true

func _build_sky_details() -> void:
	var cloud := _material(Color(0.96, 0.99, 1.0, 0.94), 0.0, 0.62, 0.18)
	var cloud_shadow := _material(Color(0.70, 0.87, 0.93, 0.48), 0.0, 0.72, 0.08)
	for center in [
		Vector3(-5.8, 6.4, -18.0),
		Vector3(4.6, 7.0, -20.0),
		Vector3(0.4, 8.0, -24.0)
	]:
		_add_cloud_cluster(center, cloud, cloud_shadow)
	var sun := _material(Color("ffe891"), 0.0, 0.22, 0.70)
	sun.emission_enabled = true
	sun.emission = Color("ffd86c")
	sun.emission_energy_multiplier = 0.85
	_add_sphere(stage, 1.18, Vector3(6.7, 8.1, -24.0), sun, Vector3.ONE)

func _add_cloud_cluster(center: Vector3, cloud: Material, cloud_shadow: Material) -> void:
	_add_sphere(stage, 0.95, center + Vector3(0.10, -0.24, 0.18), cloud_shadow, Vector3(1.48, 0.58, 0.82))
	_add_sphere(stage, 0.82, center, cloud, Vector3(1.42, 0.66, 0.90))
	_add_sphere(stage, 0.62, center + Vector3(-0.86, -0.02, 0.05), cloud, Vector3(1.25, 0.70, 0.88))
	_add_sphere(stage, 0.66, center + Vector3(0.84, -0.05, 0.02), cloud, Vector3(1.28, 0.68, 0.90))
	_add_sphere(stage, 0.56, center + Vector3(0.14, 0.54, -0.08), cloud, Vector3(1.05, 0.86, 0.92))

func _build_water() -> void:
	water_material = _material(Color("0d9fd0"), 0.06, 0.20, 0.82)
	water_material.clearcoat_enabled = true
	water_material.clearcoat = 0.90
	water_material.clearcoat_roughness = 0.07
	var water := _add_box(stage, Vector3(19.0, 0.20, 34.0), Vector3(0, -2.05, -4.2), water_material)
	water.name = "GlossyRiver"

	# Semi-transparent highlight lanes give the static river a reflective, premium
	# finish without a continuously running shader.
	var gloss := _material(Color(0.76, 0.96, 1.0, 0.24), 0.0, 0.12, 0.58)
	for item in [
		Vector4(-3.8, -1.91, -1.0, 2.8),
		Vector4(2.9, -1.90, -4.2, 3.4),
		Vector4(-1.2, -1.89, -8.0, 4.1),
		Vector4(4.4, -1.88, 3.0, 2.0)
	]:
		_add_box(stage, Vector3(item.w, 0.025, 0.08), Vector3(item.x, item.y, item.z), gloss)

func _build_distant_world() -> void:
	# Far mountain/island silhouettes.
	_add_island(Vector3(-5.2, 4.4, -17.0), 2.65, 2.9, 0.65)
	_add_island(Vector3(4.9, 4.8, -18.5), 2.35, 2.7, 0.56)
	_add_island(Vector3(-1.1, 6.6, -22.0), 1.55, 2.15, 0.44)

	# Main waterfall terrace across the horizon.
	for item in [
		Vector4(-5.5, 0.60, -11.8, 3.2),
		Vector4(-1.8, 0.95, -12.8, 4.0),
		Vector4(2.1, 0.55, -12.0, 3.4),
		Vector4(5.6, 0.90, -13.2, 3.0)
	]:
		_add_cliff_terrace(Vector3(item.x, item.y, item.z), item.w)

	# Small tree silhouettes at different depths stop the scene from feeling stamped.
	for item in [
		Vector4(-6.1,2.55,-11.1,0.62), Vector4(-4.1,2.35,-12.2,0.52),
		Vector4(-2.8,2.9,-12.7,0.48), Vector4(0.2,2.75,-13.0,0.56),
		Vector4(2.8,2.55,-12.2,0.50), Vector4(4.6,2.75,-12.8,0.58),
		Vector4(6.1,2.48,-11.7,0.62)
	]:
		_add_tree(Vector3(item.x, item.y, item.z), item.w)

func _build_bridge() -> void:
	var stone := _material(Color("889c94"), 0.02, 0.52, 0.30)
	var stone_light := _material(Color("c9d8ca"), 0.01, 0.42, 0.40)
	var deck := _add_box(stage, Vector3(7.8, 0.48, 0.72), Vector3(3.35, 2.15, -12.8), stone)
	deck.rotation_degrees.y = -5.0
	var cap := _add_box(stage, Vector3(7.9, 0.14, 0.82), Vector3(3.35, 2.48, -12.8), stone_light)
	cap.rotation_degrees.y = -5.0
	for x in [0.7, 2.55, 4.4, 6.25]:
		_add_box(stage, Vector3(0.58, 3.15, 0.68), Vector3(x, 0.70, -12.82), stone)
		_add_box(stage, Vector3(0.20, 3.0, 0.74), Vector3(x - 0.17, 0.76, -12.45), stone_light)
	for x in [-0.25, 0.75, 1.75, 2.75, 3.75, 4.75, 5.75, 6.75]:
		_add_box(stage, Vector3(0.16, 0.72, 0.18), Vector3(x, 2.88, -12.75), stone_light)
	_add_box(stage, Vector3(7.8, 0.14, 0.14), Vector3(3.35, 3.12, -12.75), stone_light)

func _build_waterfalls() -> void:
	var edge := _material(Color("1aa6c8"), 0.0, 0.16, 0.65)
	var body := _material(Color("78e8f5"), 0.0, 0.10, 0.58)
	var core := _material(Color(0.93, 1.0, 1.0, 0.82), 0.0, 0.06, 0.50)
	for fall in [
		Vector4(-5.2,0.1,-10.75,1.15),
		Vector4(-1.7,0.0,-11.65,1.55),
		Vector4(2.4,0.0,-10.95,1.28),
		Vector4(5.6,0.15,-12.0,1.02)
	]:
		_add_box(stage, Vector3(fall.w, 4.7, 0.16), Vector3(fall.x, fall.y, fall.z), edge)
		_add_box(stage, Vector3(fall.w * 0.76, 4.66, 0.18), Vector3(fall.x, fall.y, fall.z + 0.05), body)
		_add_box(stage, Vector3(fall.w * 0.22, 4.60, 0.20), Vector3(fall.x - fall.w * 0.12, fall.y + 0.05, fall.z + 0.10), core)
		for n in range(3):
			_add_sphere(
				stage,
				fall.w * (0.26 + float(n) * 0.04),
				Vector3(fall.x + (float(n) - 1.0) * fall.w * 0.27, -2.00, fall.z + 0.18),
				_material(Color(0.80, 0.99, 1.0, 0.32), 0.0, 0.12, 0.45),
				Vector3(1.25, 0.24, 0.72)
			)

func _build_shoreline() -> void:
	var rock := _material(Color("647a72"), 0.0, 0.62, 0.22)
	var rock_light := _material(Color("9fb2a4"), 0.0, 0.48, 0.28)
	var grass := _material(Color("45c65b"), 0.0, 0.48, 0.32)
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		for i in range(7):
			var z := 5.5 - float(i) * 2.35
			var x := side * (6.0 + float(i % 3) * 0.34)
			var scale := 1.10 - float(i) * 0.045
			_add_sphere(stage, 1.45 * scale, Vector3(x, -1.15, z), rock, Vector3(1.45, 0.62, 1.10))
			_add_sphere(stage, 1.10 * scale, Vector3(x - side * 0.26, -0.72, z - 0.10), rock_light, Vector3(1.36, 0.45, 0.96))
			_add_sphere(stage, 1.04 * scale, Vector3(x - side * 0.18, -0.38, z - 0.18), grass, Vector3(1.52, 0.28, 1.08))
			if i % 2 == 0:
				_add_tree(Vector3(x - side * 0.20, 0.35, z - 0.45), 0.55 * scale)

	# Lily pads and white flowers.
	var leaf := _material(Color("36a84a"), 0.0, 0.44, 0.25)
	for item in [
		Vector3(-3.8,-1.86,2.4), Vector3(3.5,-1.86,0.8),
		Vector3(-4.5,-1.86,-4.8), Vector3(4.1,-1.86,-6.0)
	]:
		_add_cylinder(stage, 0.62, 0.62, 0.07, item, leaf)
		_add_flower(item + Vector3(0, 0.18, 0), 0.24)

func _build_stepping_stones() -> void:
	var stone := _material(Color("7f9389"), 0.0, 0.52, 0.28)
	var top := _material(Color("aebdaf"), 0.0, 0.40, 0.36)
	var shadow := _material(Color(0.02, 0.15, 0.22, 0.25), 0.0, 0.72, 0.0)
	var stones := [
		Vector4(0.35,-1.78,4.8,1.05),
		Vector4(-0.25,-1.79,2.4,0.92),
		Vector4(0.18,-1.80,0.2,0.82),
		Vector4(-0.16,-1.81,-1.7,0.70),
		Vector4(0.08,-1.82,-3.2,0.58)
	]
	for item in stones:
		_add_sphere(stage, item.w * 1.10, Vector3(item.x + 0.12, item.y - 0.10, item.z + 0.12), shadow, Vector3(1.18, 0.18, 0.88))
		_add_sphere(stage, item.w, Vector3(item.x, item.y, item.z), stone, Vector3(1.18, 0.30, 0.90))
		_add_sphere(stage, item.w * 0.78, Vector3(item.x - item.w * 0.12, item.y + item.w * 0.18, item.z - item.w * 0.08), top, Vector3(1.12, 0.20, 0.84))

func _build_foreground_frame() -> void:
	# Larger near-camera foliage produces the cinematic framing and depth seen in
	# premium casual titles while leaving the central interaction area clear.
	for item in [
		Vector4(-7.0,0.1,5.0,1.15), Vector4(-6.7,2.0,3.0,0.92),
		Vector4(7.0,0.0,4.5,1.18), Vector4(6.6,2.1,2.7,0.88)
	]:
		_add_tree(Vector3(item.x, item.y, item.z), item.w)

	var leaf_dark := _material(Color("0b793d"), 0.0, 0.48, 0.30)
	var leaf_mid := _material(Color("27b94b"), 0.0, 0.40, 0.38)
	var leaf_light := _material(Color("83e256"), 0.0, 0.36, 0.42)
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		for i in range(4):
			var base := Vector3(side * 7.55, -0.1 + float(i) * 1.65, 5.6 - float(i) * 1.4)
			_add_sphere(stage, 1.25, base, leaf_dark, Vector3(1.20, 0.85, 0.85))
			_add_sphere(stage, 0.92, base + Vector3(-side * 0.40, 0.45, -0.15), leaf_mid, Vector3(1.15, 0.90, 0.90))
			_add_sphere(stage, 0.54, base + Vector3(-side * 0.68, 0.78, 0.02), leaf_light, Vector3.ONE)

func _add_island(position_value: Vector3, radius: float, height: float, opacity: float) -> void:
	var rock := _material(Color(0.35, 0.45, 0.42, opacity), 0.0, 0.58, 0.12)
	var grass := _material(Color(0.34, 0.78, 0.34, opacity), 0.0, 0.44, 0.25)
	_add_cylinder(stage, radius, radius * 0.34, height, position_value, rock)
	_add_cylinder(stage, radius * 1.03, radius * 0.94, 0.22, position_value + Vector3(0, height * 0.51, 0), grass)
	_add_tree(position_value + Vector3(-radius * 0.18, height * 0.72, 0), radius * 0.24)
	var fall := _material(Color(0.76, 0.98, 1.0, 0.56 * opacity), 0.0, 0.10, 0.42)
	_add_box(stage, Vector3(radius * 0.28, height * 0.92, 0.12), position_value + Vector3(radius * 0.48, -height * 0.02, radius * 0.62), fall)

func _add_cliff_terrace(position_value: Vector3, width: float) -> void:
	var rock := _material(Color("5d766e"), 0.0, 0.64, 0.16)
	var rock_light := _material(Color("8fa697"), 0.0, 0.50, 0.24)
	var grass := _material(Color("48bd59"), 0.0, 0.46, 0.28)
	var radius := width * 0.52
	_add_cylinder(stage, radius, radius * 0.76, 2.70, position_value, rock)
	_add_cylinder(stage, radius * 1.03, radius * 0.96, 0.28, position_value + Vector3(0, 1.49, 0), grass)
	_add_sphere(stage, radius * 0.62, position_value + Vector3(-radius * 0.26, 0.25, radius * 0.72), rock_light, Vector3(1.10, 0.78, 0.56))
	_add_sphere(stage, radius * 0.45, position_value + Vector3(radius * 0.46, 0.04, radius * 0.68), rock_light, Vector3(1.02, 0.72, 0.52))

func _add_tree(position_value: Vector3, scale_value: float) -> void:
	var trunk := _material(Color("80502d"), 0.0, 0.58, 0.18)
	var dark := _material(Color("087642"), 0.0, 0.46, 0.24)
	var mid := _material(Color("23b34d"), 0.0, 0.38, 0.34)
	var light := _material(Color("78dd54"), 0.0, 0.34, 0.40)
	_add_cylinder(stage, scale_value * 0.16, scale_value * 0.20, scale_value * 1.55, position_value, trunk)
	_add_sphere(stage, scale_value * 0.74, position_value + Vector3(0, scale_value * 1.05, 0), dark, Vector3(1.05, 0.92, 1.0))
	_add_sphere(stage, scale_value * 0.58, position_value + Vector3(-scale_value * 0.48, scale_value * 0.95, 0.02), mid, Vector3.ONE)
	_add_sphere(stage, scale_value * 0.55, position_value + Vector3(scale_value * 0.46, scale_value * 1.08, -0.04), mid, Vector3.ONE)
	_add_sphere(stage, scale_value * 0.48, position_value + Vector3(-scale_value * 0.15, scale_value * 1.55, -0.02), light, Vector3.ONE)

func _add_flower(position_value: Vector3, radius: float) -> void:
	var white := _material(Color("fffef2"), 0.0, 0.32, 0.38)
	var gold := _material(Color("ffd83d"), 0.0, 0.28, 0.52)
	for offset in [
		Vector3(radius,0,0), Vector3(-radius,0,0),
		Vector3(0,0,radius), Vector3(0,0,-radius)
	]:
		_add_sphere(stage, radius * 0.55, position_value + offset, white, Vector3(1.0, 0.45, 1.0))
	_add_sphere(stage, radius * 0.48, position_value + Vector3(0,0.04,0), gold, Vector3.ONE)

func _apply_world_style() -> void:
	if environment == null:
		return
	if dark_mode:
		environment.background_color = Color("092653")
		environment.ambient_light_color = Color("6db4d6")
		environment.ambient_light_energy = 0.72
		key_light.light_color = Color("b8dcff")
		key_light.light_energy = 1.15
		rim_light.light_color = accent.lightened(0.34)
		rim_light.light_energy = 0.78
		warm_fill.light_color = Color("2dbde7")
		warm_fill.light_energy = 0.62
	else:
		environment.background_color = Color("32b8f7")
		environment.ambient_light_color = Color("e8fbff")
		environment.ambient_light_energy = 0.94
		key_light.light_color = Color("fff0c6")
		key_light.light_energy = 1.34
		rim_light.light_color = accent.lightened(0.48)
		rim_light.light_energy = 0.68
		warm_fill.light_color = Color("99f5ff")
		warm_fill.light_energy = 0.58
	if water_material != null:
		water_material.albedo_color = (Color("116cac") if dark_mode else Color("0d9fd0")).lerp(accent, 0.08)
	for material in accent_materials:
		if material != null:
			material.emission = accent.lightened(0.28)

func _material(
	color: Color,
	metallic_value: float = 0.0,
	roughness_value: float = 0.38,
	clearcoat_value: float = 0.35
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = clampf(roughness_value, 0.06, 0.82)
	if color.a < 0.995:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.clearcoat_enabled = true
	material.clearcoat = clampf(clearcoat_value, 0.0, 1.0)
	material.clearcoat_roughness = 0.10
	return material

func _add_box(parent: Node3D, dimensions: Vector3, position_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _add_sphere(
	parent: Node3D,
	radius: float,
	position_value: Vector3,
	material: Material,
	scale_value: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.scale = scale_value
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _add_cylinder(
	parent: Node3D,
	top_radius: float,
	bottom_radius: float,
	height: float,
	position_value: Vector3,
	material: Material
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_value
	instance.material_override = material
	parent.add_child(instance)
	return instance
