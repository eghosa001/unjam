extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var project := FileAccess.get_file_as_string("res://project.godot")
	var theme := FileAccess.get_file_as_string("res://scripts/ui/unjam_3d_theme.gd")
	var figma := FileAccess.get_file_as_string("res://scripts/ui/figma_reference_canvas.gd")
	var premium := FileAccess.get_file_as_string("res://scripts/ui/premium_design_system.gd")

	if not project.contains("theme/default_font_multichannel_signed_distance_field=false"):
		failures.append("Global fallback-font MSDF is still enabled")

	if theme.contains("variation_embolden = 0.62") or theme.contains("variation_embolden = 0.85"):
		failures.append("Strong font synthetic embolden is still heavy enough to overfill glyph joins")
	if not theme.contains("variation_embolden = 0.08"):
		failures.append("Readable font is not using the reduced embolden value")
	if not theme.contains("variation_embolden = 0.38"):
		failures.append("Strong font is not using the reduced embolden value")

	if not figma.contains('label_node.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)'):
		failures.append("Figma display titles still add a dark font shadow")
	if not figma.contains('label_node.add_theme_constant_override("shadow_offset_y", 0)'):
		failures.append("Figma display titles still offset a secondary glyph shadow")

	if premium.contains('font_shadow_color", Color(0, 0, 0'):
		failures.append("Premium title labels still add dark text shadows")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("CRISP_TEXT_RENDERING_OK")
	quit(0)
