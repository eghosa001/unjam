extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_material_helpers(): return
	if not _validate_backdrop_budget(): return
	if not _validate_reduced_motion_source(): return
	if not _validate_vibrant_palette(): return
	if not _validate_vibrant_home_source(): return
	if not _validate_vibrant_tiles_source(): return
	if not _validate_full_app_vibrant_adoption(): return
	print("Visual quality contract validated: procedural depth, adaptive particle budgets, reduced-motion behavior, vibrant palette, dense launcher, and full-app vibrant surface adoption.")
	quit(0)

func _validate_material_helpers() -> bool:
	var script := load("res://scripts/ui/procedural_materials.gd") as Script
	if script == null:
		return _fail("Procedural material helpers are missing")
	if not script.can_instantiate():
		return _fail("Procedural material helpers cannot instantiate")
	var helper = script.new()
	if not helper.has_method("vertical_shade") or not helper.has_method("particle_budget"):
		return _fail("Procedural material helper API is incomplete")
	var base := Color("4f8cff")
	var top: Color = helper.call("vertical_shade", base, 0.0)
	var bottom: Color = helper.call("vertical_shade", base, 1.0)
	if top.get_luminance() <= bottom.get_luminance():
		return _fail("Procedural vertical shading does not create a top-light/bottom-depth material")
	var high := int(helper.call("particle_budget", 20, 1.0, false))
	var low := int(helper.call("particle_budget", 20, 0.5, false))
	var reduced := int(helper.call("particle_budget", 20, 1.0, true))
	helper = null
	if not (high > low and low >= reduced and reduced >= 0):
		return _fail("Particle budget does not scale down with quality/reduced motion")
	return true

func _validate_backdrop_budget() -> bool:
	var script := load("res://scripts/ui/premium_backdrop.gd") as Script
	if script == null:
		return _fail("Premium backdrop is missing")
	var backdrop: Control = script.new()
	if not backdrop.has_method("decorative_particle_count_for"):
		backdrop.free()
		return _fail("Backdrop does not expose an adaptive decorative particle budget")
	var high := int(backdrop.call("decorative_particle_count_for", 1.0, false))
	var low := int(backdrop.call("decorative_particle_count_for", 0.5, false))
	var reduced := int(backdrop.call("decorative_particle_count_for", 1.0, true))
	backdrop.free()
	if high < 16 or low >= high or reduced >= high:
		return _fail("Backdrop decorative work is not materially reduced for low quality/accessibility")
	return true

func _validate_reduced_motion_source() -> bool:
	var file := FileAccess.open("res://scripts/ui/premium_backdrop.gd", FileAccess.READ)
	if file == null:
		return _fail("Premium backdrop source is missing")
	var source := file.get_as_text()
	for marker in ["/root/MotionSystem", "has_method(\"reduced\")", "_reduced_motion()", "set_process(not reduced)"]:
		if not source.contains(marker):
			return _fail("Backdrop reduced-motion lookup is not isolated-test safe: " + marker)
	if source.contains("MotionSystem.reduced()"):
		return _fail("Backdrop still depends on a compile-time MotionSystem global")
	return true

func _validate_vibrant_palette() -> bool:
	var script := load("res://scripts/ui/premium_design_system.gd") as Script
	if script == null:
		return _fail("Premium design system is missing")
	for method_name in ["vibrant_canvas", "vibrant_surface", "game_gradient"]:
		if not script.has_method(method_name):
			return _fail("Missing vibrant design helper: " + method_name)
	var canvas: Color = script.call("vibrant_canvas", "rescue_rush")
	if canvas.get_luminance() < 0.56:
		return _fail("Vibrant canvas is still too dark")
	var rescue: Array = script.call("game_gradient", "rescue_rush")
	var water: Array = script.call("game_gradient", "water_sort")
	var block: Array = script.call("game_gradient", "block_puzzle")
	if rescue.size() < 2 or water.size() < 2 or block.size() < 2:
		return _fail("Game gradients need at least two stops")
	if rescue[0].is_equal_approx(water[0]) or water[0].is_equal_approx(block[0]):
		return _fail("Each game needs a distinct saturated identity")
	return true

func _validate_vibrant_home_source() -> bool:
	var file := FileAccess.open("res://scripts/ui/premium_home_casual.gd", FileAccess.READ)
	if file == null:
		return _fail("Premium home launcher source is missing")
	var source := file.get_as_text()
	for marker in ["VIBRANT_REFERENCE_TARGET", "HomeFeatureStrip", "HomeGameShelf", "vibrant_canvas", "game_gradient"]:
		if not source.contains(marker):
			return _fail("Home launcher has not adopted vibrant dense layout marker: " + marker)
	if source.contains("margin_left\", 34") or source.contains("margin_right\", 34"):
		return _fail("Home launcher still keeps the old wide side gutters")
	return true

func _validate_vibrant_tiles_source() -> bool:
	var file := FileAccess.open("res://scripts/ui/game_select_tile.gd", FileAccess.READ)
	if file == null:
		return _fail("Game tile source is missing")
	var source := file.get_as_text()
	for marker in ["game_gradient", "vibrant_surface", "card_glow"]:
		if not source.contains(marker):
			return _fail("Game tiles are not using the vibrant card language: " + marker)
	return true

func _validate_full_app_vibrant_adoption() -> bool:
	var required := {
		"res://scripts/game/rescue_rush_casual.gd": ["VIBRANT_REFERENCE_TARGET", "vibrant_canvas", "game_gradient"],
		"res://scripts/game/water_sort_casual.gd": ["VIBRANT_REFERENCE_TARGET", "vibrant_canvas", "game_gradient"],
		"res://scripts/game/block_puzzle_premium_layout.gd": ["VIBRANT_REFERENCE_TARGET", "vibrant_canvas", "game_gradient"],
		"res://scripts/ui/premium_surface_manager.gd": ["VIBRANT_REFERENCE_TARGET", "vibrant_surface", "_densify_layout"],
		"res://scripts/ui/monetization_hub.gd": ["VIBRANT_REFERENCE_TARGET", "PremiumDesignSystem", "vibrant_canvas"],
		"res://scripts/ui/premium_result_overlay.gd": ["VIBRANT_REFERENCE_TARGET", "PremiumBackdrop", "PremiumDesignSystem"],
		"res://tests/capture_visual_audit.gd": ["tutorial-water", "tutorial-block", "result-overlay", "settings-light", "levels-block"]
	}
	for path in required.keys():
		var file := FileAccess.open(String(path), FileAccess.READ)
		if file == null:
			return _fail("Required vibrant surface source is missing: " + String(path))
		var source := file.get_as_text()
		for marker in required[path]:
			if not source.contains(String(marker)):
				return _fail("Full-app vibrant rollout missing marker %s in %s" % [String(marker), String(path)])
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
