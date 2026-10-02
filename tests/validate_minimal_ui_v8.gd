extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var surfaces := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var selector := FileAccess.get_file_as_string("res://scripts/ui/premium_live_hub_3d.gd")
	var canvas := FileAccess.get_file_as_string("res://scripts/ui/figma_reference_canvas.gd")
	var theme := FileAccess.get_file_as_string("res://scripts/ui/unjam_3d_theme.gd")

	_check('Rect2(261, 15, 108, 44)' in home, "Sidekick must stay a compact Home chip", failures)
	_check('Rect2(257, 365, 110, 52)' not in home, "Sidekick must not occupy a third Home action column", failures)
	_check("HomeWorldDepth" not in home and "HomeBackdropHaloTop" not in home, "Home decorative depth still enabled", failures)
	_check("SurfaceWorldDepth" not in surfaces and "SurfaceBackdropHaloTop" not in surfaces, "secondary surface decoration still enabled", failures)
	_check("SelectorWorldDepth" not in selector and "SelectorGamePreviewFrame" not in selector, "game selector is not minimal", failures)
	_check("minf(shadow_color.a, 0.065)" in canvas, "shared shadows are not reduced", failures)
	_check("static func flat_box" in theme and "motion.call(\"press\", result, 0.92)" in canvas, "shared controls are not using minimalist treatment", failures)
	_check("func show_playmate_sidekick" in surfaces and "LocalizationManager" in home, "Version 8 features were removed", failures)

	if failures.is_empty():
		print("MINIMAL_UI_V8_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
