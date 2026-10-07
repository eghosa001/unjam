class_name Unjam2DGameArt
extends Control

# Lightweight illustrated game identity used on Home and meta surfaces.
# It intentionally stays in the lightweight CanvasItem renderer with no per-frame allocation.
var game_id := "rescue_rush"
var compact := false
var dark_mode := false
var phase := 0.0
var _redraw_accumulator := 0.0

const ACTIVE_FPS := 20.0
const ACTIVE_INTERVAL := 1.0 / ACTIVE_FPS

func configure(id: String, compact_mode: bool = false, dark: bool = false) -> void:
	game_id = id
	compact = compact_mode
	dark_mode = dark
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	if is_inside_tree():
		_sync_motion()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_sync_motion)
	_sync_motion()

func _sync_motion() -> void:
	var reduced := false
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced"):
		reduced = bool(motion.call("reduced"))
	set_process(is_visible_in_tree() and not reduced)

func _process(delta: float) -> void:
	phase += delta
	_redraw_accumulator += delta
	if _redraw_accumulator >= ACTIVE_INTERVAL:
		_redraw_accumulator = fmod(_redraw_accumulator, ACTIVE_INTERVAL)
		queue_redraw()

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	match game_id:
		"water_sort":
			_draw_water()
		"block_puzzle":
			_draw_block()
		_:
			_draw_rescue()

func _draw_rescue() -> void:
	var w := size.x
	var h := size.y
	var accent := Color("#35df7a")
	var sky := Color("#123e37") if dark_mode else Color("#ccebd2")
	var ground := Color("#1d5a46") if dark_mode else Color("#78b77f")
	_round(Rect2(Vector2.ZERO, size), sky, minf(28.0, h * 0.12))
	# Layered illustrated environment, deliberately border-free.
	draw_circle(Vector2(w * 0.16, h * 0.24), w * 0.22, Color(ground, 0.36))
	draw_circle(Vector2(w * 0.86, h * 0.20), w * 0.28, Color(ground.darkened(0.10), 0.34))
	var path := PackedVector2Array([
		Vector2(w * 0.05, h * 0.88),
		Vector2(w * 0.34, h * 0.62),
		Vector2(w * 0.58, h * 0.54),
		Vector2(w * 0.94, h * 0.31),
	])
	draw_polyline(path, Color(accent, 0.26), maxf(8.0, w * 0.06), true)
	draw_polyline(path, Color(accent.lightened(0.35), 0.36), maxf(2.0, w * 0.012), true)

	var tile := minf(w, h) * (0.25 if compact else 0.22)
	var bob := sin(phase * 2.4) * (1.8 if not compact else 0.8)
	var centers := [
		Vector2(w * 0.24, h * 0.63),
		Vector2(w * 0.53, h * 0.49),
		Vector2(w * 0.76, h * 0.31),
	]
	var dirs := [Vector2.RIGHT, Vector2.UP, Vector2.RIGHT]
	var colors := [Color("#2ed46f"), Color("#22a8f4"), Color("#ff795f")]
	for i in range(centers.size()):
		_draw_rescue_tile(centers[i] + Vector2(0, bob * (0.4 + i * 0.18)), tile, dirs[i], colors[i])

	var hero_center := Vector2(w * 0.72, h * 0.72 + bob)
	var hero_r := minf(w, h) * (0.18 if compact else 0.20)
	_draw_character(hero_center, hero_r, Color("#ffd84d"))
	# Exit target is the brightest non-character object.
	var exit_center := Vector2(w * 0.91, h * 0.24)
	draw_circle(exit_center, hero_r * 0.42, Color(accent, 0.13))
	draw_arc(exit_center, hero_r * 0.40, 0.0, TAU, 28, Color(accent.lightened(0.36), 0.88), maxf(2.0, hero_r * 0.08), true)

func _draw_rescue_tile(center: Vector2, side: float, direction: Vector2, color: Color) -> void:
	var rect := Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	_round(Rect2(rect.position + Vector2(0, side * 0.08), rect.size), Color(0.02, 0.08, 0.10, 0.20), side * 0.22)
	_round(rect, color, side * 0.22)
	var sheen := Rect2(rect.position + Vector2(side * 0.13, side * 0.10), Vector2(side * 0.52, side * 0.12))
	_round(sheen, Color(1, 1, 1, 0.25), side * 0.06)
	var n := Vector2(-direction.y, direction.x)
	var tip := center + direction * side * 0.30
	var neck := center + direction * side * 0.05
	var tail := center - direction * side * 0.27
	var half := side * 0.09
	var wing := side * 0.20
	var arrow := PackedVector2Array([
		tail + n * half, neck + n * half, neck + n * wing,
		tip, neck - n * wing, neck - n * half, tail - n * half,
	])
	draw_colored_polygon(arrow, Color("#f9fff5") if color.get_luminance() < 0.52 else Color("#12304a"))

func _draw_character(center: Vector2, r: float, body: Color) -> void:
	# Soft contact shadow, then a large readable mascot silhouette.
	draw_ellipse(center + Vector2(0, r * 0.88), Vector2(r * 0.82, r * 0.22), Color(0.02, 0.08, 0.10, 0.22))
	draw_circle(center + Vector2(0, r * 0.12), r * 0.78, body.darkened(0.04))
	draw_circle(center - Vector2(0, r * 0.36), r * 0.73, body)
	draw_circle(center - Vector2(r * 0.25, r * 0.52), r * 0.10, Color(1, 1, 1, 0.26))
	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * r * 0.25, -r * 0.42)
		draw_circle(eye, r * 0.075, Color("#173047"))
		draw_circle(eye - Vector2(r * 0.022, r * 0.022), r * 0.022, Color.WHITE)
		draw_circle(center + Vector2(side * r * 0.40, -r * 0.20), r * 0.10, Color("#ff8b78"))
	var beak := PackedVector2Array([
		center + Vector2(-r * 0.12, -r * 0.20),
		center + Vector2(r * 0.16, -r * 0.20),
		center + Vector2(0, r * 0.01),
	])
	draw_colored_polygon(beak, Color("#ff941f"))

func _draw_water() -> void:
	var w := size.x
	var h := size.y
	var bg := Color("#102f51") if dark_mode else Color("#ccecff")
	_round(Rect2(Vector2.ZERO, size), bg, minf(28.0, h * 0.12))
	draw_circle(Vector2(w * 0.82, h * 0.18), w * 0.28, Color("#4fc5ff", 0.12))
	draw_circle(Vector2(w * 0.18, h * 0.72), w * 0.35, Color("#00d4c8", 0.09))
	var bottle_w := w * (0.22 if compact else 0.20)
	var bottle_h := h * (0.62 if compact else 0.68)
	var centers := [w * 0.23, w * 0.50, w * 0.77]
	var palette := [
		[Color("#ff4f66"), Color("#ffb11f"), Color("#8d5cff")],
		[Color("#19c98b"), Color("#20a9ff"), Color("#ff4f66")],
		[Color("#ffb11f"), Color("#8d5cff"), Color("#19c98b")],
	]
	for i in range(3):
		var rise := sin(phase * 2.2 + i * 0.7) * (1.4 if not compact else 0.6)
		_draw_art_bottle(Vector2(centers[i], h * 0.55 + rise), bottle_w, bottle_h, palette[i])
	# One clear pour arc gives the composition motion even as a still screenshot.
	var start := Vector2(w * 0.35, h * 0.28)
	var end := Vector2(w * 0.51, h * 0.34)
	var cp := Vector2(w * 0.43, h * 0.15)
	var points := PackedVector2Array()
	for i in range(13):
		var t := float(i) / 12.0
		var p := (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * cp + t * t * end
		points.append(p)
	draw_polyline(points, Color("#24b5ff", 0.72), maxf(3.0, w * 0.018), true)
	for i in range(4):
		var p := end + Vector2((i - 1.5) * w * 0.025, (i % 2) * h * 0.018)
		draw_circle(p, maxf(1.6, w * 0.011), Color("#b9f4ff", 0.72))

func _draw_art_bottle(center: Vector2, bw: float, bh: float, colors: Array) -> void:
	var body := Rect2(center - Vector2(bw * 0.5, bh * 0.42), Vector2(bw, bh * 0.82))
	var radius := bw * 0.27
	_round(Rect2(body.position + Vector2(0, bh * 0.035), body.size), Color(0.02, 0.12, 0.22, 0.18), radius)
	var inner := body.grow(-bw * 0.13)
	var slot_h := inner.size.y / 3.0
	for i in range(3):
		var c: Color = colors[i]
		var r := Rect2(Vector2(inner.position.x, inner.end.y - slot_h * float(i + 1)), Vector2(inner.size.x, slot_h + 1))
		if i == 0:
			_round(r, c.darkened(0.06), radius * 0.44)
		else:
			draw_rect(r, c.darkened(0.05), true)
		draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, r.size.y * 0.38)), Color(c.lightened(0.26), 0.46), true)
		draw_line(Vector2(r.position.x + 2, r.position.y + 2), Vector2(r.end.x - 2, r.position.y + 2), c.lightened(0.42), maxf(1.2, bw * 0.035), true)
	# Crystal silhouette after liquid.
	_round(body, Color(0.78, 0.96, 1.0, 0.08), radius, Color(0.92, 1.0, 1.0, 0.92), maxf(1.4, bw * 0.055))
	var neck_w := bw * 0.46
	var mouth_y := body.position.y - bh * 0.035
	draw_line(Vector2(center.x - neck_w * 0.5, mouth_y), Vector2(center.x + neck_w * 0.5, mouth_y), Color(0.96, 1.0, 1.0, 0.96), maxf(2.0, bw * 0.08), true)
	draw_arc(center + Vector2(-bw * 0.13, -bh * 0.17), bw * 0.14, -2.6, -1.0, 12, Color(1,1,1,0.48), maxf(1.2, bw * 0.035), true)

func _draw_block() -> void:
	var w := size.x
	var h := size.y
	var bg := Color("#23163e") if dark_mode else Color("#ece0ff")
	_round(Rect2(Vector2.ZERO, size), bg, minf(28.0, h * 0.12))
	# Grid only whispers behind the pieces.
	var grid_rect := Rect2(Vector2(w * 0.08, h * 0.12), Vector2(w * 0.84, h * 0.76))
	var cell := minf(grid_rect.size.x, grid_rect.size.y) / 6.0
	for y in range(6):
		for x in range(6):
			var r := Rect2(grid_rect.position + Vector2(x, y) * cell + Vector2.ONE * cell * 0.08, Vector2.ONE * cell * 0.84)
			_round(r, Color("#5a3c82", 0.08 if not dark_mode else 0.12), cell * 0.16)
	var blocks := [
		[Vector2i(0,4), Color("#ff5b72")], [Vector2i(1,4), Color("#ff5b72")], [Vector2i(1,3), Color("#ff5b72")],
		[Vector2i(3,1), Color("#34b5ff")], [Vector2i(4,1), Color("#34b5ff")], [Vector2i(5,1), Color("#34b5ff")],
		[Vector2i(3,4), Color("#ffbd2f")], [Vector2i(4,4), Color("#ffbd2f")], [Vector2i(4,5), Color("#ffbd2f")],
		[Vector2i(1,1), Color("#35d890")], [Vector2i(1,2), Color("#35d890")],
	]
	var bounce := sin(phase * 2.6) * (1.4 if not compact else 0.5)
	for item in blocks:
		var p: Vector2i = item[0]
		var c: Color = item[1]
		var r := Rect2(grid_rect.position + Vector2(p) * cell + Vector2.ONE * cell * 0.055 + Vector2(0, bounce * (0.25 + p.x * 0.05)), Vector2.ONE * cell * 0.89)
		_draw_gloss_block(r, c)

func _draw_gloss_block(rect: Rect2, color: Color) -> void:
	var radius := rect.size.x * 0.18
	_round(Rect2(rect.position + Vector2(0, rect.size.y * 0.09), rect.size), Color(0.03, 0.03, 0.08, 0.24), radius)
	_round(rect, color, radius)
	var top := Rect2(rect.position + Vector2(rect.size.x * 0.10, rect.size.y * 0.09), Vector2(rect.size.x * 0.62, rect.size.y * 0.16))
	_round(top, Color(1, 1, 1, 0.30), radius * 0.55)
	draw_line(Vector2(rect.position.x + radius, rect.end.y - rect.size.y * 0.10), Vector2(rect.end.x - radius, rect.end.y - rect.size.y * 0.10), Color(color.darkened(0.30), 0.30), maxf(1.0, rect.size.y * 0.035), true)

func _round(rect: Rect2, fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: float = 0.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	var r := maxi(0, int(round(radius)))
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	if border_width > 0.0:
		var bw := maxi(1, int(round(border_width)))
		style.border_width_left = bw
		style.border_width_top = bw
		style.border_width_right = bw
		style.border_width_bottom = bw
		style.border_color = border
	draw_style_box(style, rect)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
