extends SceneTree

# Exact user-approved UNJAM branding pipeline.
# Full artwork (three game motifs + UNJAM wordmark) is the launcher source.
# Its transparent cutout is the adaptive/splash foreground, so Android's
# matching blue background shows through with no square/card demarcation.

const FULL_SOURCE := "res://store_assets/unjam_approved_logo_source.png"
const TRANSPARENT_SOURCE := "res://store_assets/unjam_approved_logo_transparent.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"
const FULL_SOURCE_SIZE := Vector2i(320, 320)
const LEGACY_SIZE := Vector2i(512, 512)
const ADAPTIVE_SIZE := Vector2i(432, 432)

func _initialize() -> void:
	var full_logo: Image = Image.load_from_file(FULL_SOURCE)
	var transparent_logo: Image = Image.load_from_file(TRANSPARENT_SOURCE)
	if full_logo == null or full_logo.is_empty():
		push_error("Could not load the approved full UNJAM logo")
		quit(1)
		return
	if transparent_logo == null or transparent_logo.is_empty():
		push_error("Could not load the approved transparent UNJAM logo")
		quit(1)
		return
	if full_logo.get_size() != FULL_SOURCE_SIZE:
		push_error("Approved full UNJAM logo source must remain 320x320")
		quit(1)
		return
	if transparent_logo.get_size() != FULL_SOURCE_SIZE:
		push_error("Approved transparent UNJAM logo source must remain 320x320")
		quit(1)
		return
	if not _corners_are_transparent(transparent_logo):
		push_error("Approved transparent UNJAM logo must keep transparent corners")
		quit(1)
		return
	if not _write_resized(full_logo, LEGACY_OUT, LEGACY_SIZE):
		quit(1)
		return
	if not _write_resized(transparent_logo, ADAPTIVE_OUT, ADAPTIVE_SIZE):
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY exact-approved-logo legacy=512 adaptive-splash=432 no-demarcation")
	quit(0)

func _write_resized(source: Image, output_path: String, target_size: Vector2i) -> bool:
	var image: Image = source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var error: int = image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save Android brand asset %s: %s" % [output_path, error])
		return false
	return true

func _corners_are_transparent(image: Image) -> bool:
	var last: Vector2i = image.get_size() - Vector2i.ONE
	for point in [Vector2i.ZERO, Vector2i(last.x, 0), Vector2i(0, last.y), last]:
		if image.get_pixelv(point).a > 0.08:
			return false
	return true
