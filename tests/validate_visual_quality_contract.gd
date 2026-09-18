extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_material_helpers(): return
	if not _validate_backdrop_budget(): return
	if not _validate_reduced_motion_source(): return
	if not _validate_crisp_bold_typography(): return
	print("Visual quality contract validated: procedural depth, adaptive particle budgets, reduced motion, and crisp bold typography.")
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

func _validate_crisp_bold_typography() -> bool:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	Unjam3DTheme.label_3d(label, Color.WHITE, Color("06203a"), 9)
	if label.get_theme_constant("outline_size") > 1:
		label.free()
		return _fail("3D labels still use blurry multi-pixel outlines")
	if abs(label.get_theme_constant("shadow_offset_y")) > 1:
		label.free()
		return _fail("3D labels still use blurry displaced shadows")
	var label_font := label.get_theme_font("font")
	if not label_font is FontVariation or (label_font as FontVariation).variation_embolden < 0.45:
		label.free()
		return _fail("3D labels are not using a real emboldened font variation")
	label.free()

	var button := Button.new()
	button.custom_minimum_size = Vector2(200, 64)
	button.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.WATER, true, 20, true)
	if button.get_theme_constant("outline_size") > 1:
		button.free()
		return _fail("Premium buttons still use blurry multi-pixel text outlines")
	var button_font := button.get_theme_font("font")
	if not button_font is FontVariation or (button_font as FontVariation).variation_embolden < 0.45:
		button.free()
		return _fail("Premium buttons are not emboldened")
	button.free()
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
