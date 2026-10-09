extends SceneTree

# Use the EXACT approved colourful UNJAM launch-screen logo for all Android
# branding. The old vector-only U was an unintended generic replacement.
# Artwork is never redrawn, skewed or replaced; only aspect-preserved resizing
# and safe-centred padding adapt the same source to Android icon masks.
const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const APPROVED_LOGO := "res://store_assets/unjam_approved_logo_transparent.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_launcher_adaptive_432.png"
const SPLASH_OUT := "res://assets/icon_user_adaptive_432.png"
const SYSTEM_SPLASH_OUT := "res://assets/splash_emblem_safe_432.png"

const LEGACY_CANVAS := 512
const LEGACY_CONTENT := 415
const ADAPTIVE_CANVAS := 432
# The adaptive 432x432 mask guarantees a 72px central safety margin. Full
# "UNJAM" lettering and the three-game emblem are kept together.
# Samsung One UI uses smaller rounded/squircle masks and sometimes applies
# additional launcher scaling. Keep the complete U + UNJAM wordmark comfortably
# inside the actual adaptive foreground, with >= 88px margin on each edge.
# Previously 280px left only 76px margin and made the symbol feel zoomed.
const ADAPTIVE_CONTENT := 256
const SYSTEM_SPLASH_CONTENT := 260
const SPLASH_SIZE := 432
const IN_APP_CONTENT := 354

func _initialize() -> void:
	# Store artwork is retained as the canonical Google Play graphic, but
	# launcher/startup branding deliberately uses the approved LAUNCH logo.
	var store_icon := Image.load_from_file(SOURCE)
	if store_icon == null or store_icon.get_size() != Vector2i(512,512):
		push_error("Approved Google Play 512px icon missing")
		quit(1)
		return
	var logo := Image.load_from_file(APPROVED_LOGO)
	if logo == null or logo.is_empty():
		push_error("Approved full-colour UNJAM launch artwork missing")
		quit(1)
		return
	logo.convert(Image.FORMAT_RGBA8)
	if not _corners_are_transparent(logo):
		push_error("Approved UNJAM logo must retain transparent exterior padding")
		quit(1)
		return
	if not _write_legacy_icon(logo):
		quit(1)
		return
	if not _write_contained(logo, ADAPTIVE_OUT, ADAPTIVE_CANVAS, ADAPTIVE_CONTENT):
		quit(1)
		return
	if not _write_contained(logo, SYSTEM_SPLASH_OUT, ADAPTIVE_CANVAS, SYSTEM_SPLASH_CONTENT):
		quit(1)
		return
	if not _write_contained(logo, SPLASH_OUT, SPLASH_SIZE, IN_APP_CONTENT):
		quit(1)
		return
	print("ANDROID_BRAND_ASSETS_READY full-colour-approved-launch-logo on legacy adaptive splash and in-app")
	quit(0)

func _write_legacy_icon(logo: Image) -> bool:
	var canvas := Image.create(LEGACY_CANVAS,LEGACY_CANVAS,false,Image.FORMAT_RGBA8)
	# Match the official adaptive blue background; unlike the masked adaptive
	# foreground, legacy launcher icons need an opaque edge-to-edge background.
	for y in range(LEGACY_CANVAS):
		var t := float(y)/float(LEGACY_CANVAS-1)
		var top := Color("#173BFF")
		var bottom := Color("#24106F")
		var tint := top.lerp(bottom,t)
		for x in range(LEGACY_CANVAS):
			canvas.set_pixel(x,y,tint)
	var fitted := _contained_logo(logo, LEGACY_CANVAS, LEGACY_CONTENT)
	canvas.blend_rect(fitted,Rect2i(Vector2i.ZERO,fitted.get_size()),Vector2i.ZERO)
	return _save(canvas,LEGACY_OUT)

func _write_contained(source: Image, output_path: String, canvas_size: int, max_content: int) -> bool:
	return _save(_contained_logo(source, canvas_size, max_content),output_path)

func _contained_logo(source: Image, canvas_size: int, max_content: int) -> Image:
	# Crop only fully transparent padding. Do not crop off lower UNJAM letters,
	# replace colours or stretch the original non-square logo into a square.
	var bounds := source.get_used_rect()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		push_error("Approved UNJAM logo has no visible pixels")
		return Image.new()
	var cropped := source.get_region(bounds)
	var ratio := minf(float(max_content)/float(cropped.get_width()),float(max_content)/float(cropped.get_height()))
	var width := maxi(1,roundi(cropped.get_width()*ratio))
	var height := maxi(1,roundi(cropped.get_height()*ratio))
	cropped.resize(width,height,Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(canvas_size,canvas_size,false,Image.FORMAT_RGBA8)
	canvas.fill(Color(0,0,0,0))
	canvas.blend_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),Vector2i((canvas_size-width)/2,(canvas_size-height)/2))
	return canvas

func _save(image: Image, output_path: String) -> bool:
	if image.is_empty():
		return false
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
