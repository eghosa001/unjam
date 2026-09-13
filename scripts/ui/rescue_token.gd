extends Control
class_name RescueToken

var rescue_id := "chick"
var accent := Color("ffd166")
var t := 0.0
var blink_timer := 1.6
var blinking := false
var mood_boost := 0.0

func configure(id: String, color: Color = Color("ffd166")) -> void:
	rescue_id = id
	accent = color
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	pivot_offset = size * 0.5

func celebrate() -> void:
	mood_boost = 1.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.22, 0.88), 0.10)
	tween.tween_property(self, "scale", Vector2(0.92, 1.16), 0.10)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	var rotate := create_tween().set_trans(Tween.TRANS_SINE)
	rotate.tween_property(self, "rotation", deg_to_rad(-8.0), 0.10)
	rotate.tween_property(self, "rotation", deg_to_rad(8.0), 0.12)
	rotate.tween_property(self, "rotation", 0.0, 0.12)

func _process(delta: float) -> void:
	t += delta
	mood_boost = maxf(0.0, mood_boost - delta * 0.65)
	blink_timer -= delta
	if blink_timer <= 0.0:
		blinking = true
		blink_timer = 2.0 + fmod(t * 0.73, 2.2)
		get_tree().create_timer(0.11).timeout.connect(func(): blinking = false)
	queue_redraw()

func _draw() -> void:
	var bob := sin(t * 2.8) * 3.0
	var breathe := 1.0 + sin(t * 2.1) * 0.025
	var center: Vector2 = size * 0.5 + Vector2(0, bob)
	var r: float = minf(size.x, size.y) * 0.28 * breathe
	var aura := 0.18 + 0.05 * sin(t * 3.0) + mood_boost * 0.18
	draw_circle(center + Vector2(0, 10), r * 1.35, Color(accent, aura))
	draw_circle(center, r, accent)
	var eye_h := r * (0.025 if blinking else 0.09)
	for side in [-1.0, 1.0]:
		var eye_center := center + Vector2(side * r * 0.32, -r * 0.08)
		if blinking:
			draw_line(eye_center - Vector2(r * 0.08, 0), eye_center + Vector2(r * 0.08, 0), Color("152039"), 3.0, true)
		else:
			draw_circle(eye_center, eye_h, Color("152039"))
			draw_circle(eye_center + Vector2(-side * r * 0.025, -r * 0.04), r * 0.026, Color.WHITE)
	match rescue_id:
		"puppy": _draw_ears(center, r, Color("b8794c"))
		"kitten": _draw_cat_ears(center, r)
		"robot": _draw_robot(center, r)
		"slime": _draw_slime(center, r)
		"panda": _draw_panda(center, r)
		"fox": _draw_fox(center, r)
		"alien": _draw_alien(center, r)
		_: _draw_chick(center, r)
	_draw_smile(center, r)
	# Small anticipation marks make the rescue target feel alive rather than static.
	var sparkle_alpha := 0.25 + 0.18 * sin(t * 4.0)
	for i in range(3):
		var a := t * 0.8 + float(i) * TAU / 3.0
		var p := center + Vector2(cos(a), sin(a)) * r * 1.45
		draw_circle(p, 2.5 + mood_boost * 2.0, Color(1, 1, 1, sparkle_alpha + mood_boost * 0.35))

func _draw_smile(center: Vector2, r: float) -> void:
	var smile_width := r * (0.26 + mood_boost * 0.08)
	draw_arc(center + Vector2(0, r * 0.14), smile_width, 0.25, PI - 0.25, 16, Color("152039"), 3.2, true)

func _draw_ears(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center + Vector2(-r * 0.82, -r * 0.42), r * 0.35, color)
	draw_circle(center + Vector2(r * 0.82, -r * 0.42), r * 0.35, color)

func _draw_cat_ears(center: Vector2, r: float) -> void:
	for side in [-1.0, 1.0]:
		var p := PackedVector2Array([center + Vector2(side * r * 0.76, -r * 0.62), center + Vector2(side * r * 0.34, -r * 1.12), center + Vector2(side * r * 0.08, -r * 0.56)])
		draw_colored_polygon(p, accent.darkened(0.08))

func _draw_robot(center: Vector2, r: float) -> void:
	draw_line(center + Vector2(0, -r), center + Vector2(0, -r * 1.3), Color.WHITE, 4.0, true)
	draw_circle(center + Vector2(0, -r * 1.36), r * 0.09, Color("ff6b7a"))
	draw_rect(Rect2(center - Vector2(r * 0.6, r * 0.42), Vector2(r * 1.2, r * 0.84)), Color(accent, 0.18), false, 3.0)

func _draw_slime(center: Vector2, r: float) -> void:
	draw_circle(center + Vector2(-r * 0.6, r * 0.52), r * 0.28, accent)
	draw_circle(center + Vector2(r * 0.6, r * 0.52), r * 0.28, accent)

func _draw_panda(center: Vector2, r: float) -> void:
	draw_circle(center + Vector2(-r * 0.72, -r * 0.58), r * 0.28, Color("172033"))
	draw_circle(center + Vector2(r * 0.72, -r * 0.58), r * 0.28, Color("172033"))

func _draw_fox(center: Vector2, r: float) -> void:
	for side in [-1.0, 1.0]:
		var p := PackedVector2Array([center + Vector2(side * r * 0.72, -r * 0.52), center + Vector2(side * r * 0.48, -r * 1.15), center + Vector2(side * r * 0.10, -r * 0.62)])
		draw_colored_polygon(p, Color("f28c4b"))

func _draw_alien(center: Vector2, r: float) -> void:
	draw_arc(center, r * 0.86, 0, TAU, 28, Color("8af0c8"), 4.0, true)
	draw_line(center + Vector2(-r * 0.22, -r * 0.94), center + Vector2(-r * 0.38, -r * 1.22), Color("8af0c8"), 3.0, true)
	draw_line(center + Vector2(r * 0.22, -r * 0.94), center + Vector2(r * 0.38, -r * 1.22), Color("8af0c8"), 3.0, true)

func _draw_chick(center: Vector2, r: float) -> void:
	var beak := PackedVector2Array([center + Vector2(-r * 0.16, r * 0.10), center + Vector2(r * 0.16, r * 0.10), center + Vector2(0, r * 0.34)])
	draw_colored_polygon(beak, Color("ff9f43"))
