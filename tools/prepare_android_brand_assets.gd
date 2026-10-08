extends SceneTree

# A single deterministic Android identity: a clean gold U on a blue gradient,
# rather than shrinking the full store illustration to an unreadable tiny icon.
# The artist-approved transparent brand logo remains the in-app opening mark,
# aspect-fitted instead of being squashed to a square.
const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const MARK_SOURCE := "res://assets/boot_mark.svg"
const SPLASH_SOURCE := "res://store_assets/unjam_approved_logo_transparent.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_launcher_adaptive_432.png"
const SPLASH_OUT := "res://assets/icon_user_adaptive_432.png"
const SYSTEM_SPLASH_OUT := "res://assets/splash_emblem_safe_432.png"
const LEGACY_CANVAS := 512
const ADAPTIVE_CANVAS := 432
const ADAPTIVE_CONTENT := 270
const SYSTEM_SPLASH_CONTENT := 260
const SPLASH_SIZE := 432

func _initialize() -> void:
	var original := Image.load_from_file(SOURCE)
	if original == null or original.get_size() != Vector2i(512,512):
		push_error("Approved 512px store icon not found")
		quit(1)
		return
	var mark := Image.new()
	var result := mark.load_svg_from_buffer(FileAccess.get_file_as_bytes(MARK_SOURCE),1.0)
	if result != OK or mark.is_empty():
		push_error("Could not rasterize UNJAM vector U mark")
		quit(1)
		return
	mark.convert(Image.FORMAT_RGBA8)
	if not _write_legacy_icon(mark):
		quit(1)
		return
	if not _write_contained(mark,ADAPTIVE_OUT,ADAPTIVE_CANVAS,ADAPTIVE_CONTENT):
		quit(1)
		return
	if not _write_contained(mark,SYSTEM_SPLASH_OUT,ADAPTIVE_CANVAS,SYSTEM_SPLASH_CONTENT):
		quit(1)
		return
	var full_logo := Image.load_from_file(SPLASH_SOURCE)
	if full_logo == null or full_logo.is_empty():
		push_error("Approved transparent UNJAM startup artwork missing")
		quit(1)
		return
	full_logo.convert(Image.FORMAT_RGBA8)
	if not _corners_are_transparent(full_logo):
		push_error("UNJAM startup logo must retain transparency")
		quit(1)
		return
	# _write_contained crops only transparent exterior padding. Never force
	# artwork with a non-square aspect ratio into 432x432 source coordinates.
	if not _write_contained(full_logo,SPLASH_OUT,SPLASH_SIZE,354):
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY consistent-U-logo safe-adaptive-zone aspect-preserved-splash")
	quit(0)

func _write_legacy_icon(mark: Image) -> bool:
	var background := Image.create(LEGACY_CANVAS,LEGACY_CANVAS,false,Image.FORMAT_RGBA8)
	# Native legacy launchers do not support a separately masked background.
	# Draw one full-bleed brand background rather than a black/transparent halo.
	for y in range(LEGACY_CANVAS):
		var t := float(y)/float(LEGACY_CANVAS-1)
		var top := Color("#1847d4")
		var bottom := Color("#18124c")
		var tint := top.lerp(bottom,t)
		for x in range(LEGACY_CANVAS):
			background.set_pixel(x,y,tint)
	var image := mark.duplicate()
	image.resize(434,434,Image.INTERPOLATE_LANCZOS)
	background.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(39,39))
	return _save(background,LEGACY_OUT)

func _write_contained(source: Image, output_path: String, canvas_size: int, max_content: int) -> bool:
	var bounds := source.get_used_rect()
	if bounds.size.x < 1 or bounds.size.y < 1:
		push_error("UNJAM brand mark has no visible pixels")
		return false
	var cropped := source.get_region(bounds)
	var ratio := minf(float(max_content)/float(cropped.get_width()),float(max_content)/float(cropped.get_height()))
	var width := maxi(1,roundi(cropped.get_width()*ratio))
	var height := maxi(1,roundi(cropped.get_height()*ratio))
	cropped.resize(width,height,Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(canvas_size,canvas_size,false,Image.FORMAT_RGBA8)
	canvas.fill(Color(0,0,0,0))
	canvas.blend_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),Vector2i((canvas_size-width)/2,(canvas_size-height)/2))
	return _save(canvas,output_path)

func _save(image: Image, output_path: String) -> bool:
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save %s: %s" % [output_path,error])
		return false
	return true

func _corners_are_transparent(image: Image) -> bool:
	var last := image.get_size()-Vector2i.ONE
	for point in [Vector2i.ZERO,Vector2i(last.x,0),Vector2i(0,last.y),last]:
		if image.get_pixelv(point).a > 0.08:
			return false
	return true
