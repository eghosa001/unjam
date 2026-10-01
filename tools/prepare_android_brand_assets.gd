extends SceneTree

# The approved full UNJAM logo is the single source of truth.
# Android adaptive foreground is regenerated on every build with a soft edge so
# the artwork blends into the matching blue-purple adaptive background.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.jpg"
const LEGACY_OUT := "res://assets/icon_user_512.jpg"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"
const ADAPTIVE_SIZE := 432
const CONTENT_SIZE := 392
const EDGE_FADE_PX := 24.0

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Could not load approved UNJAM launcher artwork")
		quit(1)
		return
	if source.get_size() != Vector2i(512, 512):
		push_error("UNJAM launcher artwork must remain 512x512")
		quit(1)
		return

	# Preserve the exact approved full logo for legacy launchers/store surfaces.
	var legacy := source.duplicate()
	var legacy_err := legacy.save_jpg(LEGACY_OUT, 0.94)
	if legacy_err != OK:
		push_error("Could not write packaged UNJAM legacy launcher")
		quit(1)
		return

	# Generate a safe adaptive layer from the same artwork. Fade only the outer
	# perimeter so Android's blue-purple background flows into the logo without
	# a visible square/card boundary.
	var content := source.duplicate()
	content.resize(CONTENT_SIZE, CONTENT_SIZE, Image.INTERPOLATE_LANCZOS)
	content.convert(Image.FORMAT_RGBA8)
	for y in range(CONTENT_SIZE):
		for x in range(CONTENT_SIZE):
			var edge := float(min(min(x, CONTENT_SIZE - 1 - x), min(y, CONTENT_SIZE - 1 - y)))
			var alpha := smoothstep(0.0, EDGE_FADE_PX, edge)
			var c := content.get_pixel(x, y)
			c.a *= alpha
			content.set_pixel(x, y, c)

	var adaptive := Image.create(ADAPTIVE_SIZE, ADAPTIVE_SIZE, false, Image.FORMAT_RGBA8)
	adaptive.fill(Color(0, 0, 0, 0))
	var offset := Vector2i((ADAPTIVE_SIZE - CONTENT_SIZE) / 2, (ADAPTIVE_SIZE - CONTENT_SIZE) / 2)
	adaptive.blit_rect(content, Rect2i(Vector2i.ZERO, content.get_size()), offset)
	var adaptive_err := adaptive.save_png(ADAPTIVE_OUT)
	if adaptive_err != OK:
		push_error("Could not write UNJAM adaptive foreground")
		quit(1)
		return

	print("ANDROID_BRAND_ASSETS_READY approved-full-logo legacy=512 adaptive=432 feathered")
	quit(0)
