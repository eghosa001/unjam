class_name GameSelectTile
extends Control

signal chosen(game_id: String)

var game_id := "rescue_rush"
var title := "RESCUE RUSH"
var level := 1
var accent := Color("2dd4b6")
var selected := false
var dark_mode := true
var hovering := false
var pressed_amount := 0.0
var phase := 0.0

func configure(id: String, display_title: String, current_level: int, color: Color, is_selected: bool, dark: bool) -> void:
	game_id = id
	title = display_title
	level = current_level
	accent = color
	selected = is_selected
	dark_mode = dark
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): hovering = true; _animate_hover(true))
	mouse_exited.connect(func(): hovering = false; _animate_hover(false))
	resized.connect(func(): pivot_offset = size * 0.5)
	pivot_offset = size * 0.5
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	pressed_amount = maxf(0.0, pressed_amount - delta * 6.0)
	queue_redraw()

func _animate_hover(value: bool) -> void:
	var target := Vector2(1.025, 1.025) if value else Vector2.ONE
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target, 0.12)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed_amount = 1.0
			var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(0.975, 0.975), 0.055)
		else:
			chosen.emit(game_id)
			_animate_hover(hovering)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			pressed_amount = 1.0
		else:
			chosen.emit(game_id)
		accept_event()

func _box(rect: Rect2, color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if width > 0:
		s.border_width_left = width
		s.border_width_right = width
		s.border_width_top = width
		s.border_width_bottom = width
		s.border_color = border
	draw_style_box(s, rect)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bg := Color("0d1727") if dark_mode else Color("ffffff")
	var ink := Color("f7f9ff") if dark_mode else Color("132033")
	var muted := Color("95a5ba") if dark_mode else Color("607087")
	var border := Color(accent, 0.92) if selected else (Color("26384e") if dark_mode else Color("c5d0dd"))
	var rect := Rect2(Vector2(3, 4), size - Vector2(6, 8))
	var shadow := rect.translated(Vector2(0, 7))
	_box(shadow, Color(0, 0, 0, 0.25), 24)
	var glow := 0.10 if selected else (0.055 if hovering else 0.0)
	if glow > 0.0:
		_box(rect.grow(5), Color(accent, glow), 28)
	_box(rect, bg, 24, border, 2 if selected else 1)

	# accent notch instead of a loud top stripe
	_box(Rect2(rect.position + Vector2(14, 14), Vector2(48, 5)), Color(accent, 0.95 if selected else 0.46), 3)
	var icon_center := Vector2(rect.position.x + 58, rect.position.y + 79)
	_draw_icon(icon_center)

	var title_size := 19 if size.x < 330 else 22
	draw_string(font, Vector2(rect.position.x + 104, rect.position.y + 68), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, accent if selected else ink)
	draw_string(font, Vector2(rect.position.x + 104, rect.position.y + 101), "LEVEL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, muted)
	if selected:
		draw_circle(Vector2(rect.end.x - 28, rect.position.y + 28), 7, accent)
		draw_circle(Vector2(rect.end.x - 28, rect.position.y + 28), 3, Color("061019"))
	var progress := fposmod(phase * 0.24, 1.0)
	var rail := Rect2(Vector2(rect.position.x + 16, rect.end.y - 17), Vector2(rect.size.x - 32, 3))
	_box(rail, Color(1, 1, 1, 0.055), 2)
	var travel := maxf(18.0, rail.size.x * 0.18)
	_box(Rect2(Vector2(rail.position.x + (rail.size.x - travel) * progress, rail.position.y), Vector2(travel, 3)), Color(accent, 0.46), 2)

func _draw_icon(center: Vector2) -> void:
	match game_id:
		"water_sort":
			for i in range(3):
				var x := center.x - 22 + i * 22
				draw_line(Vector2(x - 6, center.y - 21), Vector2(x - 6, center.y + 20), Color(0.82, 0.94, 1, 0.62), 2.0, true)
				draw_line(Vector2(x + 6, center.y - 21), Vector2(x + 6, center.y + 20), Color(0.82, 0.94, 1, 0.62), 2.0, true)
				draw_arc(Vector2(x, center.y + 20), 6, 0, PI, 16, Color(0.82, 0.94, 1, 0.62), 2.0, true)
				draw_rect(Rect2(Vector2(x - 5, center.y + 1 + float(i) * 4), Vector2(10, 18 - float(i) * 4)), Color(accent.lightened(float(i) * 0.08), 0.94), true)
		"block_puzzle":
			for raw in [Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(0,0), Vector2(0,1), Vector2(1,1)]:
				var p := center + raw * 15.0
				_box(Rect2(p - Vector2(6,6), Vector2(12,12)), Color(accent, 0.92), 3)
		_:
			draw_circle(center, 22, Color("ffd166"))
			draw_circle(center + Vector2(-7,-4), 3, Color("111827"))
			draw_circle(center + Vector2(7,-4), 3, Color("111827"))
			draw_arc(center + Vector2(0,5), 8, 0.15, PI - 0.15, 16, Color("111827"), 2.5, true)
			var tip := center + Vector2(35, 0)
			draw_polygon(PackedVector2Array([tip + Vector2(9,0), tip + Vector2(-8,-7), tip + Vector2(-8,7)]), PackedColorArray([accent]))
