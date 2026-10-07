extends SceneTree

# Restored former UNJAM launcher pipeline.
# The launcher uses the original store icon artwork and the original Android
# safe-zone padding. The splash artwork is intentionally separate and is not
# rewritten here.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const SPLASH_SOURCE := "res://store_assets/unjam_approved_logo_transparent.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_launcher_adaptive_432.png"
const SPLASH_OUT := "res://assets/icon_user_adaptive_432.png"
const SYSTEM_SPLASH_OUT := "res://assets/splash_emblem_safe_432.png"
const LEGACY_CANVAS := 512
const LEGACY_CONTENT := 512
const ADAPTIVE_CANVAS := 432
# Keep the foreground inside aggressive Android/Samsung adaptive masks.
# 280/432 leaves a 76px transparent margin on every side before masking.
const ADAPTIVE_CONTENT := 280
const SYSTEM_SPLASH_CONTENT := 280
const SPLASH_SIZE := 432

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Could not load original UNJAM launcher artwork")
		quit(1)
		return
	if source.get_width() != 512 or source.get_height() != 512:
		push_error("Original UNJAM launcher artwork must remain 512x512")
		quit(1)
		return
	if not _write_padded(source, LEGACY_OUT, LEGACY_CANVAS, LEGACY_CONTENT):
		quit(1)
		return
	if not _write_padded(source, ADAPTIVE_OUT, ADAPTIVE_CANVAS, ADAPTIVE_CONTENT):
		quit(1)
		return
	if not _write_padded(source, SYSTEM_SPLASH_OUT, ADAPTIVE_CANVAS, SYSTEM_SPLASH_CONTENT):
		quit(1)
		return
	var splash_source: Image = Image.load_from_file(SPLASH_SOURCE)
	if splash_source == null or splash_source.is_empty():
		push_error("Could not load approved UNJAM splash artwork")
		quit(1)
		return
	splash_source.convert(Image.FORMAT_RGBA8)
	if not _corners_are_transparent(splash_source):
		push_error("Approved UNJAM splash artwork must keep transparent corners")
		quit(1)
		return
	if not _write_resized(splash_source, SPLASH_OUT, SPLASH_SIZE):
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY samsung-launcher safe-system-splash full-inapp-logo")
	quit(0)

func _write_padded(source: Image, output_path: String, canvas_size: int, content_size: int) -> bool:
	var scaled := source.duplicate()
	scaled.convert(Image.FORMAT_RGBA8)
	scaled.resize(content_size, content_size, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(canvas_size, canvas_size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var offset := Vector2i((canvas_size - content_size) / 2, (canvas_size - content_size) / 2)
	canvas.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), offset)
	var error := canvas.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save Android launcher asset %s: %s" % [output_path, error])
		return false
	return true


func _write_resized(source: Image, output_path: String, target_size: int) -> bool:
	var image: Image = source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
	var error: Error = image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save Android splash asset %s: %s" % [output_path, error])
		return false
	return true

func _corners_are_transparent(image: Image) -> bool:
	var last: Vector2i = image.get_size() - Vector2i.ONE
	for point in [Vector2i.ZERO, Vector2i(last.x, 0), Vector2i(0, last.y), last]:
		if image.get_pixelv(point).a > 0.08:
			return false
	return true
