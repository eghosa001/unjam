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
		"launcher_icons/main_192x192=\"res://assets/icon_user_512.jpg\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_user_adaptive_432.png\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
		"splash_screen/icon=\"res://assets/icon_user_adaptive_432.png\"",
		"splash_screen/background_color=%s" % SPLASH_BG,
		"splash_screen/disable_godot_boot_splash=true",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher/startup contract missing: %s" % token)

	for token in [
		"config/icon=\"res://assets/icon_user_512.jpg\"",
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
		'const SOURCE := "res://store_assets/unjam_google_play_icon_512.jpg"',
		'const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"',
		"const CONTENT_SIZE := 392",
		"const EDGE_FADE_PX := 24.0",
		"adaptive.save_png(ADAPTIVE_OUT)"
		"transparent corners",
	]:
		if not prep.contains(token):
			failures.append("Android raster preparation contract missing: %s" % token)

	for workflow in [debug_workflow, release_workflow]:
		if not workflow.contains("prepare_android_brand_assets.gd"):
			failures.append("Android build workflow does not generate padded raster branding")
		if not workflow.contains('test "$FOREGROUND_BYTES" -gt 1000') and not workflow.contains('test "$AAB_FOREGROUND_BYTES" -gt 1000'):
			failures.append("Android build workflow does not reject a blank adaptive foreground")

	_check_size("res://store_assets/unjam_google_play_icon_512.jpg", Vector2i(512, 512), "Canonical launcher artwork", failures)
	if not _read("res://assets/icon_adaptive_background.svg").contains("#0F62C8") or not _read("res://assets/icon_adaptive_background.svg").contains("#210C69"):
		failures.append("Adaptive background no longer matches the approved UNJAM blue gradient")

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
	if Vector2i(image.get_width(), image.get_height()) != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _check_transparent_corners(path: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return
	for point in [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		if image.get_pixelv(point).a > 0.02:
			failures.append("Adaptive foreground must not carry a visible square background")
			return

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
