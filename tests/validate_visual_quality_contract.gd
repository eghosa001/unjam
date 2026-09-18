extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_material_helpers(): return
	if not _validate_backdrop_budget(): return
	if not _validate_reduced_motion_source(): return
	if not _validate_readable_typography(): return
	print("Visual quality contract validated: procedural depth, adaptive particle budgets, reduced-motion behavior, and crisp readable typography.")
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
	if not source.contains("MotionSystem.reduced()"):
		return _fail("Backdrop does not respect the shared reduced-motion preference")
	if not source.contains("if MotionSystem.reduced():"):
		return _fail("Backdrop keeps advancing decorative motion under reduced motion")
	return true

func _validate_readable_typography() -> bool:
	var font := Unjam3DTheme.readable_font()
	if font == null or font.variation_embolden < 0.6:
		return _fail("Shared premium font is not strongly emboldened")
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(label, Color.WHITE, Color("071426"), 4)
	if label.get_theme_font("font") != font:
		label.free()
		return _fail("Premium labels do not use the shared readable font")
	if label.get_theme_constant("outline_size") > 2 or label.get_theme_constant("shadow_offset_y") > 2:
		label.free()
		return _fail("Small premium text still uses blur-heavy outline/shadow settings")
	label.free()
	var button := Button.new()
	button.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.WATER_DARK, true, 24)
	if button.get_theme_font_size("font_size") < 28 or button.custom_minimum_size.y < 88.0:
		button.free()
		return _fail("Premium buttons do not meet the readability/touch contract")
	button.free()
	var manager_script := load("res://scripts/ui/premium_surface_manager_static.gd") as Script
	var manager = manager_script.new()
	var root := Control.new()
	var tiny := Label.new()
	tiny.text = "SECONDARY COPY"
	tiny.add_theme_font_size_override("font_size", 13)
	root.add_child(tiny)
	manager.call("_polish_tree", root, "collection", true, Unjam3DTheme.GREEN)
	if tiny.get_theme_font_size("font_size") < 22:
		root.free()
		manager.free()
		return _fail("Secondary surfaces can still render unreadably small labels")
	root.free()
	manager.free()
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
