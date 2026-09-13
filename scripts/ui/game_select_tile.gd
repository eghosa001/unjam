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
	mouse_entered.connect(func(): hovering = true; queue_redraw())
	mouse_exited.connect(func(): hovering = false; queue_redraw())
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		chosen.emit(game_id)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		chosen.emit(game_id)
		accept_event()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bg := Color("152238") if dark_mode else Color("ffffff")
	var ink := Color("f7f9ff") if dark_mode else Color("14213a")
	var muted := Color("aebbd0") if dark_mode else Color("52637a")
	var border := accent if selected else (Color("40516d") if dark_mode else Color("bcc8d8"))
	var rect := Rect2(Vector2.ZERO, size)
	var glow_alpha := 0.16 if selected else (0.08 if hovering else 0.0)
	draw_rect(rect.grow(7), Color(accent, glow_alpha), true)
	draw_rect(rect, bg, true)
	draw_rect(Rect2(Vector2(0,0), Vector2(size.x, 7)), accent if selected else Color(accent, 0.55), true)
	# compact game icon
	var icon_center := Vector2(62, 68)
	match game_id:
		"water_sort":
			for i in range(3):
				var x := icon_center.x - 32 + i * 32
				draw_rect(Rect2(Vector2(x - 9, icon_center.y - 24), Vector2(18, 48)), Color(1,1,1,0.08), true)
				draw_rect(Rect2(Vector2(x - 6, icon_center.y + 2), Vector2(12, 18)), accent.lightened(float(i) * 0.08), true)
		"block_puzzle":
			for y in range(3):
				for x in range(3):
					if not (x == 0 and y == 2):
						draw_rect(Rect2(icon_center + Vector2(x-1, y-1) * 20 - Vector2(8,8), Vector2(16,16)), Color(accent, 0.88), true)
		_:
			draw_circle(icon_center, 24, Color("ffd166"))
			draw_circle(icon_center + Vector2(-8,-4), 3.5, Color("14213a"))
			draw_circle(icon_center + Vector2(8,-4), 3.5, Color("14213a"))
			draw_colored_polygon(PackedVector2Array([icon_center+Vector2(33,0),icon_center+Vector2(15,-12),icon_center+Vector2(15,12)]), accent)
	var title_pos := Vector2(112, 58)
	draw_string(font, title_pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, accent if selected else ink)
	draw_string(font, Vector2(112, 92), "LEVEL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, muted)
	if selected:
		draw_string(font, Vector2(size.x - 92, 78), "SELECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, accent)
	# subtle animated indicator
	var p := fposmod(phase * 90.0, maxf(1.0, size.x - 30.0))
	draw_rect(Rect2(Vector2(15 + p, size.y - 5), Vector2(26, 3)), Color(accent, 0.24), true)
