extends SceneTree

# Android packaged launcher/splash raster regression verified.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"
const LEGACY_CANVAS := 512
const LEGACY_CONTENT := 384
const ADAPTIVE_CANVAS := 432
const ADAPTIVE_CONTENT := 288

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Could not load UNJAM source launcher artwork")
		quit(1)
		return
	if source.get_width() != 512 or source.get_height() != 512:
		push_error("UNJAM source launcher artwork must remain 512x512")
		quit(1)
		return
	if not _write_padded(source, LEGACY_OUT, LEGACY_CANVAS, LEGACY_CONTENT):
		quit(1)
		return
	if not _write_padded(source, ADAPTIVE_OUT, ADAPTIVE_CANVAS, ADAPTIVE_CONTENT):
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY legacy=384/512 adaptive=288/432")
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
		push_error("Could not save Android brand asset %s: %s" % [output_path, error])
		return false
	return true
