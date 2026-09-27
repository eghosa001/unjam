extends SceneTree

const SPLASH_BG := "Color(0.070588, 0.109804, 0.227451, 1)"

func _initialize() -> void:
	var failures: Array[String] = []
	var export_cfg := _read("res://export_presets.cfg")
	var project_cfg := _read("res://project.godot")
	var robust_main := _read("res://scripts/ui/robust_main.gd")
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

	for token in [
		'const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"',
		"const LEGACY_CONTENT := 384",
		"const ADAPTIVE_CONTENT := 288",
		'const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"',
		"Image.INTERPOLATE_LANCZOS",
	]:
		if not prep.contains(token):
			failures.append("Android raster preparation contract missing: %s" % token)

	for workflow in [debug_workflow, release_workflow]:
		if not workflow.contains("prepare_android_brand_assets.gd"):
			failures.append("Android build workflow does not generate padded raster branding")
		if not workflow.contains('test "$FOREGROUND_BYTES" -gt 1000') and not workflow.contains('test "$AAB_FOREGROUND_BYTES" -gt 1000'):
			failures.append("Android build workflow does not reject a blank adaptive foreground")

	_check_size("res://store_assets/unjam_google_play_icon_512.png", Vector2i(512, 512), "Canonical launcher artwork", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_AND_BRANDED_STARTUP_OK")
	quit(0)

func _check_size(path: String, expected: Vector2i, label: String, failures: Array[String]) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("%s failed to load" % label)
		return
	if Vector2i(image.get_width(), image.get_height()) != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
