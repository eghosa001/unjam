class_name RescueToken
extends Control

# Fast illustrated 2D rescue character. The public API intentionally matches the
# former rendered token so gameplay/reward logic stays untouched.
var rescue_id := "chick"
var accent := Color("#ffd166")
var rarity := ""
var phase := 0.0
var celebrating := false
var _redraw_accumulator := 0.0

const DECORATIVE_RENDER_FPS := 20.0
const DECORATIVE_RENDER_INTERVAL := 1.0 / DECORATIVE_RENDER_FPS

func configure(id: String, color: Color = Color("#ffd166"), variant_rarity: String = "") -> void:
	rescue_id = id
	accent = color
	rarity = variant_rarity.to_lower()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	visibility_changed.connect(_sync_motion)
	add_to_group("reduced_motion_aware")
	_sync_motion()

func apply_motion_preference() -> void:
	_sync_motion()
	queue_redraw()

func _sync_motion() -> void:
	var reduced := false
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced"):
		reduced = bool(motion.call("reduced"))
	_redraw_accumulator = 0.0
	set_process(is_visible_in_tree() and not reduced)

func _process(delta: float) -> void:
	phase += delta
	_redraw_accumulator += delta
	if _redraw_accumulator >= DECORATIVE_RENDER_INTERVAL:
		_redraw_accumulator = fmod(_redraw_accumulator, DECORATIVE_RENDER_INTERVAL)
		queue_redraw()

func celebrate() -> void:
	FeedbackManager.complete()
	if celebrating:
		return
	celebrating = true
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced") and bool(motion.call("reduced")):
		scale = Vector2.ONE
		celebrating = false
		queue_redraw()
		return
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.16, 0.86), 0.08)
	tween.tween_property(self, "scale", Vector2(0.94, 1.13), 0.09)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_callback(func() -> void:
		celebrating = false
		queue_redraw()
	)

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var s := minf(size.x, size.y)
	var reduced := false
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced"):
		reduced = bool(motion.call("reduced"))
	var bob := 0.0 if reduced else sin(phase * 2.8) * s * 0.025
	var center := Vector2(size.x * 0.5, size.y * 0.51 + bob)
	var r := s * 0.36
	var colors := _variant_colors()
	var body: Color = colors[0]
	var detail: Color = colors[1]
	var ink: Color = colors[2]

	# Contact shadow visually anchors the mascot to the board cell.
	_draw_ellipse(center + Vector2(0, r * 0.94), Vector2(r * 0.72, r * 0.17), Color(0.01,0.08,0.10,0.25))
	_draw_body(center, r, body, detail, ink)
	_draw_variant(center, r, body, detail, ink)

	# Local lacquer highlights make the 2D sprite read as authored game art.
	draw_circle(center + Vector2(-r * 0.28, -r * 0.60), r * 0.10, Color(1,1,1,0.28))
	draw_arc(center + Vector2(-r * 0.18, -r * 0.30), r * 0.52, -2.70, -1.55, 16, Color(1,1,1,0.16), maxf(1.2, r * 0.055), true)
	if rarity in ["silver","gold","royal"]:
		var ring := Color("#dce8f4") if rarity == "silver" else (Color("#ffd75c") if rarity == "gold" else Color("#b790ff"))
		draw_arc(center, r * 1.12, 0, TAU, 36, Color(ring, 0.46), maxf(1.5, r * 0.07), true)

func _draw_body(center: Vector2, r: float, body: Color, detail: Color, ink: Color) -> void:
	# Feet, body, head and small arms form one large silhouette at phone scale.
	for side in [-1.0, 1.0]:
		_draw_ellipse(center + Vector2(side * r * 0.34, r * 0.70), Vector2(r * 0.30, r * 0.15), detail.darkened(0.06))
		_draw_ellipse(center + Vector2(side * r * 0.62, r * 0.12), Vector2(r * 0.15, r * 0.36), body.darkened(0.06))
	_draw_ellipse(center + Vector2(0, r * 0.18), Vector2(r * 0.67, r * 0.76), body.darkened(0.035))
	draw_circle(center + Vector2(0, -r * 0.35), r * 0.72, body)

	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * r * 0.25, -r * 0.42)
		_draw_ellipse(eye, Vector2(r * 0.09, r * 0.12), ink)
		draw_circle(eye + Vector2(-side * r * 0.025, -r * 0.025), r * 0.025, Color.WHITE)
		draw_circle(center + Vector2(side * r * 0.40, -r * 0.20), r * 0.10, Color("#ff8b78"))

	# Smile.
	draw_arc(center + Vector2(0, -r * 0.13), r * 0.19, 0.18, PI - 0.18, 14, ink, maxf(1.3, r * 0.055), true)

func _draw_variant(center: Vector2, r: float, body: Color, detail: Color, ink: Color) -> void:
	match rescue_id:
		"puppy":
			for side in [-1.0, 1.0]:
				_draw_ellipse(center + Vector2(side * r * 0.57, -r * 0.64), Vector2(r * 0.22, r * 0.38), detail)
			_draw_ellipse(center + Vector2(0, -r * 0.17), Vector2(r * 0.13, r * 0.09), ink)
		"kitten":
			_draw_ear(center + Vector2(-r * 0.44, -r * 0.88), r * 0.34, body.darkened(0.05), -1.0)
			_draw_ear(center + Vector2(r * 0.44, -r * 0.88), r * 0.34, body.darkened(0.05), 1.0)
			for side in [-1.0, 1.0]:
				for dy in [-0.09, 0.03]:
					draw_line(center + Vector2(side * r * 0.31, dy * r), center + Vector2(side * r * 0.72, (dy - 0.04) * r), Color(1,1,1,0.72), maxf(1.0,r*0.035), true)
		"robot":
			_round(Rect2(center + Vector2(-r * 0.49, -r * 0.65), Vector2(r * 0.98, r * 0.48)), Color("#d9edf5"), r * 0.12, Color("#6aa7c8"), maxf(1.0,r*0.04))
			draw_line(center + Vector2(0,-r*1.00), center + Vector2(0,-r*1.20), Color("#a8c8d8"), maxf(1.0,r*0.05), true)
			draw_circle(center + Vector2(0,-r*1.25), r*0.09, Color("#ff5260"))
		"slime":
			_draw_ellipse(center + Vector2(-r * 0.34, r * 0.62), Vector2(r * 0.40, r * 0.22), body)
			_draw_ellipse(center + Vector2(r * 0.34, r * 0.62), Vector2(r * 0.40, r * 0.22), body)
		"panda":
			draw_circle(center + Vector2(-r * 0.48, -r * 0.82), r * 0.24, Color("#222936"))
			draw_circle(center + Vector2(r * 0.48, -r * 0.82), r * 0.24, Color("#222936"))
			for side in [-1.0, 1.0]:
				_draw_ellipse(center + Vector2(side * r * 0.25, -r * 0.40), Vector2(r * 0.17,r*0.20), Color("#222936"))
		"fox":
			_draw_ear(center + Vector2(-r * 0.45,-r * 0.88), r * 0.36, Color("#f47d37"), -1.0)
			_draw_ear(center + Vector2(r * 0.45,-r * 0.88), r * 0.36, Color("#f47d37"), 1.0)
			_draw_ellipse(center + Vector2(0,-r*0.16), Vector2(r*0.26,r*0.16), Color("#fff1dc"))
		"alien":
			for side in [-1.0,1.0]:
				draw_line(center + Vector2(side*r*0.24,-r*0.94), center + Vector2(side*r*0.35,-r*1.18), detail, maxf(1.0,r*0.045), true)
				draw_circle(center + Vector2(side*r*0.36,-r*1.22), r*0.08, Color("#ffda42") if side < 0 else Color("#ff55ae"))
		_:
			# Chick beak and tuft.
			var beak := PackedVector2Array([
				center + Vector2(-r*0.13,-r*0.18),
				center + Vector2(r*0.15,-r*0.18),
				center + Vector2(0,r*0.02),
			])
			draw_colored_polygon(beak, Color("#ff941f"))
			draw_circle(center + Vector2(-r*0.10,-r*1.02), r*0.10, body.lightened(0.08))
			draw_circle(center + Vector2(r*0.07,-r*1.05), r*0.085, body.lightened(0.14))

func _variant_colors() -> Array[Color]:
	var base: Array[Color]
	match rescue_id:
		"puppy": base = [Color("#d8945f"), Color("#8b5a3c"), Color("#273342")]
		"kitten": base = [Color("#ffb0c9"), Color("#fff0e6"), Color("#3e3150")]
		"robot": base = [Color("#91dff5"), Color("#3d8ec6"), Color("#17304a")]
		"slime": base = [Color("#6be56e"), Color("#2faf50"), Color("#173b32")]
		"panda": base = [Color("#f5f6f0"), Color("#282e39"), Color("#1f2631")]
		"fox": base = [Color("#f58c42"), Color("#fff0da"), Color("#3b2c2e")]
		"alien": base = [Color("#7ef0bd"), Color("#36bc91"), Color("#23334e")]
		_: base = [accent, Color("#ff9b2f"), Color("#23334e")]
	match rarity:
		"silver": return [base[0].lerp(Color("#dbe4ee"),0.58), base[1].lerp(Color("#9eacba"),0.62), Color("#334353")]
		"gold": return [base[0].lerp(Color("#ffd45c"),0.64), base[1].lerp(Color("#d99a18"),0.68), Color("#5f4310")]
		"royal": return [base[0].lerp(Color("#9b6cff"),0.58), Color("#ffd45c"), Color("#2a164f")]
		_: return base

func _draw_ear(center: Vector2, span: float, color: Color, direction: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-span*0.50, span*0.36),
		center + Vector2(direction*span*0.10, -span*0.62),
		center + Vector2(span*0.50, span*0.36),
	])
	draw_colored_polygon(points, color)

func _round(rect: Rect2, fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: float = 0.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	var rr := maxi(0,int(round(radius)))
	style.corner_radius_top_left = rr
	style.corner_radius_top_right = rr
	style.corner_radius_bottom_left = rr
	style.corner_radius_bottom_right = rr
	if border_width > 0.0:
		var bw := maxi(1,int(round(border_width)))
		style.border_width_left = bw
		style.border_width_top = bw
		style.border_width_right = bw
		style.border_width_bottom = bw
		style.border_color = border
	draw_style_box(style, rect)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
