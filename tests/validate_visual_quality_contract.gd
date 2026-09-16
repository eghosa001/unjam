extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_material_helpers(): return
	if not _validate_backdrop_budget(): return
	if not _validate_reduced_motion_source(): return
	print("Visual quality contract validated: procedural depth, adaptive particle budgets, and reduced-motion backdrop behavior.")
	quit(0)

func _validate_material_helpers() -> bool:
	var script := load("res://scripts/ui/procedural_materials.gd") as Script
	if script == null:
		return _fail("Procedural material helpers are missing")
	if not script.can_instantiate():
		return _fail("Procedural material helpers cannot instantiate")
	var helper = script.new()
	if not helper.has_method("vertical_shade") or not helper.has_method("particle_budget"):
		helper.free()
		return _fail("Procedural material helper API is incomplete")
	var base := Color("4f8cff")
	var top: Color = helper.call("vertical_shade", base, 0.0)
	var bottom: Color = helper.call("vertical_shade", base, 1.0)
	if top.get_luminance() <= bottom.get_luminance():
		helper.free()
		return _fail("Procedural vertical shading does not create a top-light/bottom-depth material")
	var high := int(helper.call("particle_budget", 20, 1.0, false))
	var low := int(helper.call("particle_budget", 20, 0.5, false))
	var reduced := int(helper.call("particle_budget", 20, 1.0, true))
	helper.free()
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
	if not source.contains("MotionSystem.reduced()"):
		return _fail("Backdrop does not respect the shared reduced-motion preference")
	if not source.contains("if MotionSystem.reduced():"):
		return _fail("Backdrop keeps advancing decorative motion under reduced motion")
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
