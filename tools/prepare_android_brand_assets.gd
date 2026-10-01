extends SceneTree

# Keep the approved UNJAM artwork exact in Android packages. The square source
# contains the full wordmark; the adaptive source is already cut out so Android
# can place it over a matching background without a visible square edge.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const FOREGROUND_SOURCE := "res://store_assets/unjam_adaptive_foreground_432.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"

func _initialize() -> void:
	var legacy := Image.load_from_file(SOURCE)
	var foreground := Image.load_from_file(FOREGROUND_SOURCE)
	if legacy == null or legacy.is_empty():
		push_error("Could not load approved UNJAM launcher artwork")
		quit(1)
		return
	if foreground == null or foreground.is_empty():
		push_error("Could not load approved UNJAM adaptive foreground")
		quit(1)
		return
	if legacy.get_size() != Vector2i(512, 512):
		push_error("UNJAM launcher artwork must remain 512x512")
		quit(1)
		return
	if foreground.get_size() != Vector2i(432, 432):
		push_error("UNJAM adaptive foreground must remain 432x432")
		quit(1)
		return
	if foreground.get_pixel(0, 0).a > 0.02 or foreground.get_pixel(431, 431).a > 0.02:
		push_error("UNJAM adaptive foreground must keep transparent corners")
		quit(1)
		return
	if not _write_exact(legacy, LEGACY_OUT):
		quit(1)
		return
	if not _write_exact(foreground, ADAPTIVE_OUT):
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY approved-logo exact legacy=512 adaptive=432 transparent")
	quit(0)

func _write_exact(source: Image, output_path: String) -> bool:
	var image := source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save Android brand asset %s: %s" % [output_path, error])
		return false
	return true
