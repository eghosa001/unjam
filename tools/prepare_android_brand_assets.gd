extends SceneTree

# Approved UNJAM full-logo pipeline.
# The repository keeps compact, valid source artwork to avoid connector binary
# truncation. Android builds upscale only the transparent adaptive/splash layer;
# the visible artwork and wordmark are preserved.

const LEGACY_SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_SOURCE := "res://store_assets/unjam_adaptive_foreground_432.png"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"
const ADAPTIVE_SIZE := 432

func _initialize() -> void:
	var failures: Array[String] = []
	_check_size(LEGACY_SOURCE, Vector2i(192, 192), "Approved UNJAM launcher source", failures)
	_check_size(LEGACY_OUT, Vector2i(192, 192), "Packaged UNJAM launcher", failures)
	_check_size(ADAPTIVE_SOURCE, Vector2i(256, 256), "Approved transparent UNJAM source", failures)
	_check_transparent_corners(ADAPTIVE_SOURCE, failures)
	if not failures.is_empty():
		_fail(failures)
		return

	var foreground := Image.load_from_file(ADAPTIVE_SOURCE)
	foreground.convert(Image.FORMAT_RGBA8)
	foreground.resize(ADAPTIVE_SIZE, ADAPTIVE_SIZE, Image.INTERPOLATE_LANCZOS)
	var err := foreground.save_png(ProjectSettings.globalize_path(ADAPTIVE_OUT))
	if err != OK:
		push_error("Could not materialize UNJAM adaptive/splash logo: %s" % err)
		quit(1)
		return

	failures.clear()
	_check_size(ADAPTIVE_OUT, Vector2i(432, 432), "Materialized adaptive/splash logo", failures)
	_check_transparent_corners(ADAPTIVE_OUT, failures)
	if not failures.is_empty():
		_fail(failures)
		return

	print("ANDROID_BRAND_ASSETS_READY full-unjam-logo transparent-blend")
	quit(0)

func _fail(failures: Array[String]) -> void:
	for failure in failures:
		push_error(failure)
	quit(1)

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
			failures.append("%s must retain transparent edges so no square boundary is visible" % path)
			return
