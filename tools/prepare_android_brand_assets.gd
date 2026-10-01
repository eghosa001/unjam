extends SceneTree

# Final user-approved UNJAM branding. These assets are committed as exact
# binaries; builds validate them but never recompress, crop, or regenerate them.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const FOREGROUND_SOURCE := "res://store_assets/unjam_adaptive_foreground_432.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"

func _initialize() -> void:
	var failures: Array[String] = []
	_check_size(SOURCE, Vector2i(512, 512), "Approved UNJAM full logo", failures)
	_check_size(LEGACY_OUT, Vector2i(512, 512), "Packaged launcher icon", failures)
	_check_size(FOREGROUND_SOURCE, Vector2i(432, 432), "Approved adaptive foreground", failures)
	_check_size(ADAPTIVE_OUT, Vector2i(432, 432), "Packaged adaptive foreground", failures)
	_check_transparent_corners(FOREGROUND_SOURCE, failures)
	_check_transparent_corners(ADAPTIVE_OUT, failures)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY approved-full-logo exact-binaries transparent-adaptive")
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
	for point in [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		if image.get_pixelv(point).a > 0.05:
			failures.append("%s must keep transparent corners so no square boundary is visible" % path)
			return
