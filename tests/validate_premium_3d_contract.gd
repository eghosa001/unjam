extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_material_api(): return
	if not _validate_depth_scaling(): return
	if not _validate_active_surface_adoption(): return
	print("Premium 3D contract validated: shared bevel/extrusion materials, quality-scaled depth, and active shell/game surfaces use the same depth language.")
	quit(0)

func _validate_material_api() -> bool:
	var script := load("res://scripts/ui/procedural_materials.gd") as Script
	if script == null or not script.can_instantiate():
		return _fail("Procedural material helpers are missing")
	var helper = script.new()
	for method_name in ["bevel_light", "bevel_dark", "depth_tone", "extrusion_offset", "depth_layers_for"]:
		if not helper.has_method(method_name):
			return _fail("Premium pseudo-3D material API is incomplete: " + method_name)
	var base := Color("4f8cff")
	var light: Color = helper.call("bevel_light", base)
	var dark: Color = helper.call("bevel_dark", base)
	var depth: Color = helper.call("depth_tone", base)
	if light.get_luminance() <= base.get_luminance():
		return _fail("Bevel light must be visibly brighter than the base surface")
	if dark.get_luminance() >= base.get_luminance() or depth.get_luminance() >= dark.get_luminance():
		return _fail("Bevel/depth tones do not create a convincing top-light/bottom-depth stack")
	helper = null
	return true

func _validate_depth_scaling() -> bool:
	var helper = load("res://scripts/ui/procedural_materials.gd").new()
	var high_offset: Vector2 = helper.call("extrusion_offset", 1.0, false)
	var low_offset: Vector2 = helper.call("extrusion_offset", 0.45, false)
	var reduced_offset: Vector2 = helper.call("extrusion_offset", 1.0, true)
	var high_layers := int(helper.call("depth_layers_for", 1.0, false))
	var low_layers := int(helper.call("depth_layers_for", 0.45, false))
	var reduced_layers := int(helper.call("depth_layers_for", 1.0, true))
	helper = null
	if high_offset.length() < 4.0:
		return _fail("High-quality surfaces need enough extrusion offset to read as 3D")
	if low_offset.length() > high_offset.length() or reduced_offset.length() > high_offset.length():
		return _fail("Low-quality/reduced-motion depth must not cost more than high quality")
	if high_layers < 3 or low_layers > high_layers or reduced_layers > high_layers:
		return _fail("Depth layer budget does not scale with visual quality/accessibility")
	return true

func _validate_active_surface_adoption() -> bool:
	var required := [
		"res://scripts/ui/game_select_tile.gd",
		"res://scripts/ui/game_showcase_art.gd",
		"res://scripts/ui/block_cell_button.gd",
		"res://scripts/ui/block_piece_button.gd",
		"res://scripts/ui/water_tube_reference_motion.gd"
	]
	for path in required:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return _fail("Active premium surface is missing: " + path)
		var source := file.get_as_text()
		if not source.contains("procedural_materials.gd"):
			return _fail("Active premium surface is not using shared pseudo-3D materials: " + path)
		if not (source.contains("bevel_light") or source.contains("depth_tone") or source.contains("extrusion_offset")):
			return _fail("Active premium surface does not render shared depth cues: " + path)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
