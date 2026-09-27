extends SceneTree

const SPLASH_BG := "Color(0.070588, 0.109804, 0.227451, 1)"

func _initialize() -> void:
	var failures: Array[String] = []
	var export_cfg := _read("res://export_presets.cfg")
	var project_cfg := _read("res://project.godot")
	var robust_main := _read("res://scripts/ui/robust_main.gd")
	var adaptive_svg := _read("res://assets/icon_adaptive_foreground.svg")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon_user_512.png\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_adaptive_foreground.svg\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
		"splash_screen/icon=\"res://assets/icon_adaptive_foreground.svg\"",
		"splash_screen/background_color=%s" % SPLASH_BG,
		"splash_screen/disable_godot_boot_splash=true",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher/startup contract missing: %s" % token)

	for token in [
		"config/icon=\"res://assets/icon_user_512.png\"",
		"boot_splash/show_image=false",
		"boot_splash/bg_color=%s" % SPLASH_BG,
	]:
		if not project_cfg.contains(token):
			failures.append("Godot startup contract missing: %s" % token)

	for token in [
		'layer.name = "BrandedLaunch"',
		'logo.texture = load("res://assets/icon.svg")',
		'title.text = "UNJAM"',
		'subtitle.text = "PUZZLE COLLECTION"',
	]:
		if not robust_main.contains(token):
			failures.append("Branded launch overlay missing: %s" % token)

	expect_svg_safe_zone(adaptive_svg, failures)
	_check_size("res://assets/icon_user_512.png", Vector2i(512, 512), "Legacy launcher icon", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_AND_BRANDED_STARTUP_OK")
	quit(0)

func expect_svg_safe_zone(source: String, failures: Array[String]) -> void:
	if not source.contains('viewBox="0 0 432 432"'):
		failures.append("Adaptive foreground must stay 432x432")
	if not source.contains('x="72" y="72" width="288" height="288"'):
		failures.append("Adaptive foreground does not preserve the reduced Samsung-safe footprint")

func _check_size(path: String, expected: Vector2i, label: String, failures: Array[String]) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		failures.append("%s failed to load" % label)
		return
	var image := texture.get_image()
	if Vector2i(image.get_width(), image.get_height()) != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
