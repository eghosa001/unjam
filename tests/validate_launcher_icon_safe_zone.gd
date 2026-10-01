extends SceneTree

const SPLASH_BG := "Color(0.062745, 0.152941, 0.415686, 1)"

func _initialize() -> void:
	var failures: Array[String] = []
	var export_cfg := _read("res://export_presets.cfg")
	var project_cfg := _read("res://project.godot")
	var robust_main := _read("res://scripts/ui/robust_main.gd")
	var boot_script := _read("res://scripts/ui/boot_splash.gd")
	var boot_scene := _read("res://scenes/Boot.tscn")
	var prep := _read("res://tools/prepare_android_brand_assets.gd")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon_user_512.png\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_launcher_adaptive_432.png\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
		"splash_screen/icon=\"res://assets/splash_emblem_safe_432.png\"",
		"splash_screen/background_color=%s" % SPLASH_BG,
		"splash_screen/disable_godot_boot_splash=true",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher/startup contract missing: %s" % token)

	for token in [
		"run/main_scene=\"res://scenes/Boot.tscn\"",
		"config/icon=\"res://assets/icon_user_512.png\"",
		"boot_splash/show_image=false",
		"boot_splash/image=\"res://assets/splash_emblem_safe_432.png\"",
		"boot_splash/bg_color=%s" % SPLASH_BG,
	]:
		if not project_cfg.contains(token):
			failures.append("Project boot contract missing: %s" % token)

	for token in [
		'const HOLD_SECONDS := 1.55',
		'const FADE_SECONDS := 0.25',
		'const MAIN_SCENE := "res://scenes/Main.tscn"',
		'ResourceLoader.load_threaded_request(MAIN_SCENE)',
		'func _open_main() -> void:',
		'get_tree().change_scene_to_file(MAIN_SCENE)',
	]:
		if not boot_script.contains(token):
			failures.append("Standalone Boot behavior missing: %s" % token)

	for token in [
		'path="res://assets/unjam_startup_logo.png"',
		'custom_minimum_size = Vector2(560, 560)',
		'color = Color(0.062745, 0.152941, 0.415686, 1)',
	]:
		if not boot_scene.contains(token):
			failures.append("Standalone Boot visual missing: %s" % token)

	for forbidden in [
		"StartupBrandHold",
		"_show_startup_brand_hold",
		"_fade_startup_brand_hold",
		"STARTUP_BRAND_TEXTURE",
	]:
		if robust_main.contains(forbidden):
			failures.append("Interactive Main must not own startup overlay: %s" % forbidden)

	for token in [
		'const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"',
		'const ADAPTIVE_OUT := "res://assets/icon_launcher_adaptive_432.png"',
		'const SYSTEM_SPLASH_OUT := "res://assets/splash_emblem_safe_432.png"',
		"const LEGACY_CONTENT := 512",
		"const ADAPTIVE_CONTENT := 344",
		"const SYSTEM_SPLASH_CONTENT := 280",
		"Image.INTERPOLATE_LANCZOS",
	]:
		if not prep.contains(token):
			failures.append("Android branding pipeline missing: %s" % token)

	_check_size("res://store_assets/unjam_google_play_icon_512.png", Vector2i(512, 512), "Canonical launcher artwork", failures)
	_check_size("res://assets/unjam_startup_logo.png", Vector2i(320, 320), "Exported full startup logo", failures)
	_check_loadable("res://assets/splash_emblem_safe_432.png", "Safe system splash emblem", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("STANDALONE_BOOT_AND_SAMSUNG_SPLASH_OK")
	quit(0)

func _check_size(path: String, expected: Vector2i, label: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("%s failed to load" % label)
		return
	if image.get_size() != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _check_loadable(path: String, label: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("%s failed to load" % label)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
