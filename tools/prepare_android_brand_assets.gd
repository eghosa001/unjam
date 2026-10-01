extends SceneTree

# Validate the exact approved UNJAM launcher sources before Android packaging.
# The legacy layer keeps the full blue artwork + UNJAM wordmark. The adaptive
# foreground keeps the same logo cut out over transparency so Android can place
# it on the matching blue-purple background without a visible square boundary.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.jpg"
const FOREGROUND_SOURCE := "res://store_assets/unjam_adaptive_foreground_432.png"
const LEGACY_OUT := "res://assets/icon_user_512.jpg"
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
	if not FileAccess.file_exists(LEGACY_OUT) or not FileAccess.file_exists(ADAPTIVE_OUT):
		push_error("Packaged UNJAM launcher assets are missing")
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY full-wordmark legacy=512 adaptive=432 transparent")
	quit(0)
