class_name GameSelectTile
extends Button

signal chosen(game_id: String)

var game_id := "rescue_rush"
var title := "RESCUE RUSH"
var level := 1
var accent := Color("2dd4b6")
var selected := false
var dark_mode := true
var phase := 0.0
var hover_amount := 0.0
var press_amount := 0.0

func configure(id: String, display_title: String, current_level: int, color: Color, is_selected: bool, dark: bool) -> void:
	game_id = id
	title = display_title
	level = current_level
	accent = color
	selected = is_selected
	dark_mode = dark
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size.y = maxf(custom_minimum_size.y, 188.0)
	queue_redraw()

func _ready() -> void:
	set_process(true)
	pressed.connect(func(): chosen.emit(game_id))
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_update_pivot)
	_update_pivot()

func _update_pivot() -> void:
	pivot_offset = size * 0.5

func _set_hover(value: bool) -> void:
	if MotionSystem.reduced():
		hover_amount = 1.0 if value else 0.0
		queue_redraw()
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.14)

func _press() -> void:
	press_amount = 1.0
	if MotionSystem.reduced():
		scale = Vector2(0.985, 0.985)
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.972, 0.972), 0.055)

func _release() -> void:
	if MotionSystem.reduced():
		scale = Vector2.ONE
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.018, 1.018), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _process(delta: float) -> void:
	if not MotionSystem.reduced():
		phase += delta
	press_amount = maxf(0.0, press_amount - delta * 5.0)
	queue_redraw()

func _draw() -> void:
	if size.x < 80.0 or size.y < 80.0:
		return
	var rect := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	var surface := Color("102039") if dark_mode else Color("f9fcff")
	var surface_deep := Color("071321") if dark_mode else Color("e8eef5")
	var ink := Color("f8fbff") if dark_mode else Color("122036")
	var muted := Color("a8b8cc") if dark_mode else Color("607087")
	var border := accent if selected else Color("3a516d") if dark_mode else Color("bdcad8")
	var lift := hover_amount * 3.0
	var card_rect := Rect2(rect.position - Vector2(0, lift), rect.size)

	# Layered 2.5D card: deep contact shadow, lower rim/body, glossy face.
	_draw_box(Rect2(card_rect.position + Vector2(0, 12), card_rect.size), Color(0, 0, 0, 0.32 if dark_mode else 0.15), 30, Color.TRANSPARENT, 0)
	_draw_box(Rect2(card_rect.position + Vector2(0, 5), card_rect.size), surface_deep, 30, Color(border, 0.34), 2)
	_draw_box(card_rect, surface, 30, Color(border, 0.90 if selected else 0.62), 3 if selected else 2)
	_draw_box(Rect2(card_rect.position + Vector2(7, 6), Vector2(card_rect.size.x - 14, 8)), Color(1, 1, 1, 0.075 if dark_mode else 0.28), 5, Color.TRANSPARENT, 0)

	if selected or hover_amount > 0.02:
		var glow_alpha := 0.14 if selected else hover_amount * 0.08
		_draw_box(card_rect.grow(3), Color(accent, glow_alpha), 33, Color(accent, glow_alpha * 2.1), 1)

	var art_width := clampf(size.x * 0.34, 104.0, 160.0)
	var art_rect := Rect2(Vector2(16, 18 - lift), Vector2(art_width, size.y - 36))
	_draw_box(Rect2(art_rect.position + Vector2(0, 6), art_rect.size), Color(0, 0, 0, 0.20), 23, Color.TRANSPARENT, 0)
	_draw_box(art_rect, Color(accent, 0.12 if dark_mode else 0.09), 23, Color(accent, 0.46), 2)
	_draw_game_scene(art_rect)

	var text_x := art_rect.end.x + 16.0
	var action_w := 58.0
	var available := maxf(120.0, size.x - text_x - action_w - 18.0)
	var font := ThemeDB.fallback_font
	var title_color := accent.lightened(0.16) if selected else ink
	draw_string(font, Vector2(text_x, 48 - lift), title, HORIZONTAL_ALIGNMENT_LEFT, available, 28, title_color)
	draw_string(font, Vector2(text_x, 80 - lift), _description(), HORIZONTAL_ALIGNMENT_LEFT, available, 16, muted)
	draw_string(font, Vector2(text_x, 109 - lift), _mode_label(), HORIZONTAL_ALIGNMENT_LEFT, available, 15, Color(accent, 0.90))

	# Progress strip.
	var progress_y := size.y - 42.0 - lift
	var progress_w := maxf(74.0, available - 82.0)
	_draw_box(Rect2(Vector2(text_x, progress_y), Vector2(progress_w, 12)), Color(surface_deep, 0.92), 6, Color(border, 0.22), 1)
	var progress_ratio := clampf(float(level % 10) / 10.0, 0.08, 1.0)
	_draw_box(Rect2(Vector2(text_x + 2, progress_y + 2), Vector2((progress_w - 4) * progress_ratio, 8)), accent, 4, accent.lightened(0.18), 1)
	draw_string(font, Vector2(text_x, progress_y - 7), "LEVEL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, progress_w, 16, ink)

	var star_rect := Rect2(Vector2(text_x + progress_w + 10, progress_y - 18), Vector2(70, 32))
	_draw_box(star_rect, Color(PremiumDesignSystem.GOLD, 0.16), 15, Color(PremiumDesignSystem.GOLD, 0.50), 1)
	draw_string(font, star_rect.position + Vector2(8, 22), "★ %d" % ((maxi(0, level - 1) * 3) % 90), HORIZONTAL_ALIGNMENT_LEFT, 58, 15, PremiumDesignSystem.GOLD)

	# Tactile circular action button.
	var action_center := Vector2(size.x - 34.0, size.y * 0.5 - lift)
	draw_circle(action_center + Vector2(0, 5), 23.0, Color(0, 0, 0, 0.25))
	draw_circle(action_center, 23.0, accent.darkened(0.12))
	draw_circle(action_center - Vector2(0, 2), 20.0, accent)
	draw_arc(action_center, 20.0, PI + 0.25, TAU - 0.25, 20, accent.lightened(0.28), 3.0, true)
	draw_line(action_center + Vector2(-5, -7), action_center + Vector2(4, 0), Color.WHITE, 3.0, true)
	draw_line(action_center + Vector2(4, 0), action_center + Vector2(-5, 7), Color.WHITE, 3.0, true)

func _description() -> String:
	match game_id:
		"water_sort": return "Sort colours into perfect tubes"
		"block_puzzle": return "Place pieces and clear the board"
		_: return "Clear the lane and make the rescue"

func _mode_label() -> String:
	match game_id:
		"water_sort": return "POUR • SORT • RELAX"
		"block_puzzle": return "DRAG • PLACE • CLEAR"
		_: return "SLIDE • CLEAR • RESCUE"

func _draw_game_scene(rect: Rect2) -> void:
	var center := rect.get_center()
	match game_id:
		"water_sort":
			_draw_water_scene(rect, center)
		"block_puzzle":
			_draw_block_scene(rect, center)
		_:
			_draw_rescue_scene(rect, center)

func _draw_water_scene(rect: Rect2, center: Vector2) -> void:
	# Three dimensional glass tubes with liquid and highlights.
	for i in range(3):
		var x := center.x - 34.0 + float(i) * 34.0
		var top := rect.position.y + 40.0 + float(i % 2) * 8.0
		var bottom := rect.end.y - 25.0
		draw_line(Vector2(x - 10, top), Vector2(x - 10, bottom - 8), Color("dff7ff", 0.82), 3.0, true)
		draw_line(Vector2(x + 10, top), Vector2(x + 10, bottom - 8), Color("dff7ff", 0.82), 3.0, true)
		draw_arc(Vector2(x, bottom - 8), 10.0, 0, PI, 18, Color("dff7ff", 0.82), 3.0, true)
		draw_line(Vector2(x - 12, top), Vector2(x + 12, top), Color.WHITE, 4.0, true)
		var liquid_top := bottom - 35.0 - float(i) * 7.0
		draw_rect(Rect2(Vector2(x - 7, liquid_top), Vector2(14, bottom - 10 - liquid_top)), accent.lightened(float(i) * 0.10), true)
		draw_line(Vector2(x - 5, liquid_top + 2), Vector2(x - 5, bottom - 13), Color.WHITE, 2.0, true)
	# Small stream cue from the first mouth.
	if not MotionSystem.reduced():
		var shimmer := sin(phase * 3.2) * 2.0
		draw_line(Vector2(center.x - 44, rect.position.y + 41), Vector2(center.x, rect.position.y + 28 + shimmer), Color(accent.lightened(0.25), 0.78), 4.0, true)

func _draw_block_scene(rect: Rect2, center: Vector2) -> void:
	var colors := [Color("ffcf3f"), Color("65dc7b"), Color("54b9ff"), Color("d36dff"), Color("ff6f9f")]
	var cells := [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)]
	for i in range(cells.size()):
		var p := cells[i]
		var r := Rect2(center + Vector2(float(p.x) * 28.0 - 11, float(p.y) * 28.0 - 11), Vector2(24, 24))
		draw_rect(Rect2(r.position + Vector2(0, 4), r.size), colors[i].darkened(0.38), true)
		_draw_box(r, colors[i], 6, colors[i].lightened(0.28), 2)
		draw_rect(Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, 4)), Color.WHITE, false, 2.0)

func _draw_rescue_scene(rect: Rect2, center: Vector2) -> void:
	# Recessed mini board with tactile arrow pieces and mascot.
	var board := Rect2(rect.position + Vector2(18, 28), rect.size - Vector2(36, 54))
	_draw_box(board, Color("101b2b"), 16, Color("52657c"), 2)
	var block_size := 30.0
	var positions := [Vector2(center.x, center.y - 32), Vector2(center.x - 34, center.y), Vector2(center.x + 34, center.y)]
	var dirs := [Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	var colors := [Color("52b8ff"), Color("56db79"), Color("ff6a6a")]
	for i in range(positions.size()):
		var r := Rect2(positions[i] - Vector2(block_size, block_size) * 0.5, Vector2(block_size, block_size))
		draw_rect(Rect2(r.position + Vector2(0, 4), r.size), colors[i].darkened(0.40), true)
		_draw_box(r, colors[i], 7, colors[i].lightened(0.24), 2)
		_draw_arrow(positions[i], dirs[i])
	var face := center + Vector2(0, 36)
	draw_circle(face + Vector2(0, 3), 15, Color("b8860b"))
	draw_circle(face, 15, Color("ffd84d"))
	draw_circle(face + Vector2(-5, -2), 2.0, Color("202530"))
	draw_circle(face + Vector2(5, -2), 2.0, Color("202530"))
	draw_arc(face + Vector2(0, 2), 6.0, 0.20, PI - 0.20, 12, Color("202530"), 2.0, true)

func _draw_arrow(center: Vector2, dir: Vector2) -> void:
	var n := Vector2(-dir.y, dir.x)
	var tip := center + dir * 9.0
	var points := PackedVector2Array([
		center - dir * 8 + n * 3,
		center + dir * 1 + n * 3,
		center + dir * 1 + n * 7,
		tip,
		center + dir * 1 - n * 7,
		center + dir * 1 - n * 3,
		center - dir * 8 - n * 3
	])
	draw_polygon(points, PackedColorArray([Color.WHITE]))

func _draw_box(rect: Rect2, color: Color, radius: int, border: Color, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border
	draw_style_box(style, rect)
