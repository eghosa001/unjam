extends SceneTree

# Derive Android launcher/splash rasters from the exact approved full UNJAM icon.
# The adaptive foreground removes only blue/purple pixels connected to the outer
# border, so the central game artwork + UNJAM wordmark remain intact while the
# matching adaptive background shows through with no square demarcation.

const SOURCE := "res://store_assets/unjam_google_play_icon_512.png"
const LEGACY_OUT := "res://assets/icon_user_512.png"
const ADAPTIVE_OUT := "res://assets/icon_user_adaptive_432.png"
const LEGACY_SIZE := Vector2i(512, 512)
const ADAPTIVE_SIZE := Vector2i(432, 432)
const SAFE_FILL := 0.88
const BG_DISTANCE_LIMIT := 88.0

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Could not load approved UNJAM launcher artwork")
		quit(1)
		return
	if source.get_size() != LEGACY_SIZE:
		push_error("UNJAM launcher artwork must remain 512x512")
		quit(1)
		return

	var legacy := source.duplicate()
	if legacy.save_png(LEGACY_OUT) != OK:
		push_error("Could not write UNJAM legacy launcher raster")
		quit(1)
		return

	var foreground := _cut_out_connected_background(source)
	if foreground == null or foreground.is_empty():
		push_error("Could not derive transparent UNJAM adaptive foreground")
		quit(1)
		return
	foreground = _fit_transparent(foreground, ADAPTIVE_SIZE, SAFE_FILL)
	if foreground.save_png(ADAPTIVE_OUT) != OK:
		push_error("Could not write UNJAM adaptive foreground raster")
		quit(1)
		return

	for point in [Vector2i(0, 0), Vector2i(ADAPTIVE_SIZE.x - 1, 0), Vector2i(0, ADAPTIVE_SIZE.y - 1), Vector2i(ADAPTIVE_SIZE.x - 1, ADAPTIVE_SIZE.y - 1)]:
		if foreground.get_pixelv(point).a > 0.02:
			push_error("UNJAM adaptive foreground must keep transparent corners")
			quit(1)
			return
	print("ANDROID_BRAND_ASSETS_READY approved-logo legacy=512 adaptive=432 transparent no-demarcation")
	quit(0)

func _cut_out_connected_background(source: Image) -> Image:
	var image := source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in range(width):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	for y in range(1, height - 1):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))

	var cursor := 0
	while cursor < queue.size():
		var point := queue[cursor]
		cursor += 1
		var index := point.y * width + point.x
		if visited[index] != 0:
			continue
		visited[index] = 1
		var color := image.get_pixelv(point)
		if not _looks_like_outer_blue(color):
			continue
		color.a = 0.0
		image.set_pixelv(point, color)
		if point.x > 0:
			queue.append(Vector2i(point.x - 1, point.y))
		if point.x + 1 < width:
			queue.append(Vector2i(point.x + 1, point.y))
		if point.y > 0:
			queue.append(Vector2i(point.x, point.y - 1))
		if point.y + 1 < height:
			queue.append(Vector2i(point.x, point.y + 1))
	return image

func _looks_like_outer_blue(color: Color) -> bool:
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	# The approved art's outer field ranges from bright royal blue to deep violet.
	# Restrict removal to clearly blue/purple pixels reached from the border.
	return b >= 78.0 and b >= r * 1.18 and b >= g * 0.88 and (b - r) >= 22.0

func _fit_transparent(source: Image, target_size: Vector2i, fill: float) -> Image:
	var rect := source.get_used_rect()
	if rect.size.x <= 0 or rect.size.y <= 0:
		return Image.new()
	var cropped := source.get_region(rect)
	var max_width := float(target_size.x) * fill
	var max_height := float(target_size.y) * fill
	var scale := minf(max_width / float(cropped.get_width()), max_height / float(cropped.get_height()))
	var new_size := Vector2i(maxi(1, int(round(float(cropped.get_width()) * scale))), maxi(1, int(round(float(cropped.get_height()) * scale))))
	cropped.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var offset := Vector2i((target_size.x - new_size.x) / 2, (target_size.y - new_size.y) / 2)
	canvas.blend_rect(cropped, Rect2i(Vector2i.ZERO, new_size), offset)
	return canvas
