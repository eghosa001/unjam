extends SceneTree

const SPLASH_BG := "Color(0.031373, 0.078431, 0.14902, 1)"

func _initialize() -> void:
	var failures: Array[String] = []
	var export_cfg := _read("res://export_presets.cfg")
	var project_cfg := _read("res://project.godot")
	var robust_main := _read("res://scripts/ui/robust_main.gd")
	var main_ui := _read("res://scripts/ui/main.gd")
	var prep := _read("res://tools/prepare_android_brand_assets.gd")
	var debug_workflow := _read("res://.github/workflows/android-test-apk.yml")
	var release_workflow := _read("res://.github/workflows/android-release.yml")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon_user_512.png\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_user_adaptive_432.png\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
		"splash_screen/icon=\"res://assets/icon_user_adaptive_432.png\"",
		"splash_screen/background_color=%s" % SPLASH_BG,
		"splash_screen/disable_godot_boot_splash=true",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher/startup contract missing: %s" % token)

	for token in [
		"config/icon=\"res://assets/icon_user_512.png\"",
		"boot_splash/show_image=false",
		"boot_splash/image=\"res://assets/icon_user_adaptive_432.png\"",
		"boot_splash/bg_color=%s" % SPLASH_BG,
		"environment/defaults/default_clear_color=%s" % SPLASH_BG,
	]:
		if not project_cfg.contains(token):
			failures.append("Godot startup contract missing: %s" % token)

	if not main_ui.contains('const WORLD_BASE := ["081426"'):
		failures.append("Startup background must match the first Home world background")

	for token in [
		"func _prime_game_scene(path: String) -> void:",
		"ResourceLoader.load_threaded_request(path)",
		"func _game_scene_resource(path: String) -> PackedScene:",
	]:
		if not robust_main.contains(token):
			failures.append("Deferred game-scene loading contract missing: %s" % token)

	for forbidden in [
		"BrandedLaunch",
		"CanvasLayer.new()",
		"_warm_game_scene_resources",
	]:
		if robust_main.contains(forbidden):
			failures.append("Startup must not retain blocking launch UI: %s" % forbidden)

	for token in [
		'const LEGACY_SOURCE := "res://store_assets/unjam_google_play_icon_512.png"',
		'const ADAPTIVE_SOURCE := "res://store_assets/unjam_adaptive_foreground_432.png"',
		'const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"',
		"Image.INTERPOLATE_LANCZOS",
		"full-unjam-logo transparent-blend",
	]:
		if not prep.contains(token):
			failures.append("Approved branding pipeline missing: %s" % token)

	_check_size("res://assets/icon_user_512.png", Vector2i(192, 192), "Launcher artwork", failures)
	_check_size("res://store_assets/unjam_adaptive_foreground_432.png", Vector2i(256, 256), "Adaptive source", failures)
	_check_size("res://assets/icon_user_adaptive_432.png", Vector2i(432, 432), "Adaptive/splash artwork", failures)
	_check_transparent_corners("res://store_assets/unjam_adaptive_foreground_432.png", failures)
	_check_transparent_corners("res://assets/icon_user_adaptive_432.png", failures)

	var bg := _read("res://assets/icon_adaptive_background.svg")
	if not bg.contains("#0F62C8") or not bg.contains("#210C69"):
		failures.append("Adaptive background no longer matches the approved UNJAM blue gradient")

	for wf in [debug_workflow, release_workflow]:
		if not wf.contains("prepare_android_brand_assets.gd"):
			failures.append("Android workflow does not materialize approved branding")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_AND_STARTUP_HANDOFF_OK full-logo-no-demarcation")
	quit(0)

func _check_size(path: String, expected: Vector2i, label: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("%s failed to load" % label)
		return
	if image.get_size() != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _check_transparent_corners(path: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return
	for point in [
		Vector2i(0, 0),
		Vector2i(image.get_width() - 1, 0),
		Vector2i(0, image.get_height() - 1),
		Vector2i(image.get_width() - 1, image.get_height() - 1),
	]:
		if image.get_pixelv(point).a > 0.05:
			failures.append("%s has a visible square edge" % path)
			return

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
