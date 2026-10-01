extends SceneTree

const SPLASH_BG := "Color(0.062745, 0.152941, 0.415686, 1)"

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
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_launcher_adaptive_432.png\"",
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
		"_prime_game_scene(RESCUE_GAME_SCENE_PATH)",
		'_prime_game_scene(WATER_GAME_SCENE_PATH if selected_game_id == "water_sort" else BLOCK_GAME_SCENE_PATH)',
	]:
		if not robust_main.contains(token):
			failures.append("Deferred game-scene priming contract missing: %s" % token)

	for token in [
		"const STARTUP_BRAND_HOLD_SECONDS := 1.20",
		"const STARTUP_BRAND_FADE_SECONDS := 0.30",
		'const STARTUP_BRAND_BG := Color("#10276a")',
		'const STARTUP_BRAND_TEXTURE := "res://assets/icon_user_adaptive_432.png"',
		"func _show_startup_brand_hold() -> void:",
		"func _fade_startup_brand_hold(overlay: Control) -> void:",
		'overlay.name = "StartupBrandHold"',
	]:
		if not robust_main.contains(token):
			failures.append("Non-blocking startup brand hold missing: %s" % token)

	for forbidden in [
		"BrandedLaunch",
		"CanvasLayer.new()",
		"_warm_game_scene_resources",
		'preload("res://scenes/Game.tscn")',
		'preload("res://scenes/WaterSort.tscn")',
		'preload("res://scenes/BlockPuzzle.tscn")',
	]:
		if robust_main.contains(forbidden):
			failures.append("Startup must not retain blocking launch UI/eager game preload: %s" % forbidden)

	for token in [
		'const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"',
		'const LEGACY_OUT := "res://assets/icon_user_512.png"',
		'const ADAPTIVE_OUT := "res://assets/icon_launcher_adaptive_432.png"',
		"const LEGACY_CONTENT := 384",
		"const ADAPTIVE_CONTENT := 288",
		"Image.INTERPOLATE_LANCZOS",
	]:
		if not prep.contains(token):
			failures.append("Former Android launcher pipeline missing: %s" % token)

	for workflow in [debug_workflow, release_workflow]:
		if not workflow.contains("prepare_android_brand_assets.gd"):
			failures.append("Android build workflow does not prepare approved branding")
		if not workflow.contains('test "$FOREGROUND_BYTES" -gt 1000') and not workflow.contains('test "$AAB_FOREGROUND_BYTES" -gt 1000'):
			failures.append("Android build workflow does not reject a blank adaptive foreground")

	_check_size("res://store_assets/unjam_google_play_icon_512.png", Vector2i(512, 512), "Original launcher artwork", failures)
	_check_size("res://assets/icon_launcher_adaptive_432.png", Vector2i(432, 432), "Former adaptive launcher foreground", failures)
	_check_size("res://assets/icon_user_adaptive_432.png", Vector2i(432, 432), "Approved splash foreground", failures)

	var adaptive_bg := _read("res://assets/icon_adaptive_background.svg")
	if not adaptive_bg.contains("#173BFF") or not adaptive_bg.contains("#0B66DB") or not adaptive_bg.contains("#24106F"):
		failures.append("Adaptive launcher background no longer matches the former UNJAM gradient")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_AND_STARTUP_HANDOFF_OK")
	quit(0)

func _check_size(path: String, expected: Vector2i, label: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("%s failed to load" % label)
		return
	if image.get_size() != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
