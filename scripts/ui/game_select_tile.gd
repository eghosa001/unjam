class_name GameSelectTile
extends Button

signal chosen(game_id: String)

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

var game_id := "rescue_rush"
var title := "RESCUE RUSH"
var level := 1
var accent := Color("19dba9")
var selected := false
var dark_mode := false
var phase := 0.0
var hover_amount := 0.0
var press_amount := 0.0
var _materials = MATERIALS_SCRIPT.new()

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
	queue_redraw()

func _ready() -> void:
	set_process(not MotionSystem.reduced())
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
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, MotionSystem.duration(&"settle"))

func _press() -> void:
	press_amount = 1.0
	if MotionSystem.reduced():
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.975, 0.975), MotionSystem.duration(&"micro"))

func _release() -> void:
	if MotionSystem.reduced():
		scale = Vector2.ONE
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.025, 1.025), MotionSystem.duration(&"micro"))
	tween.tween_property(self, "scale", Vector2.ONE, MotionSystem.duration(&"settle"))

func _process(delta: float) -> void:
	phase += delta
	press_amount = maxf(0.0, press_amount - delta * 5.0)
	if selected or hover_amount > 0.001 or press_amount > 0.001:
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	var game_gradient: Array[Color] = PremiumDesignSystem.game_gradient(game_id)
	var vibrant_surface: Color = PremiumDesignSystem.vibrant_surface(game_id)
	var top_color: Color = game_gradient[0]
	var bottom_color: Color = game_gradient[1]
	var card_glow := 0.20 + hover_amount * 0.12 + (0.08 if selected else 0.0)
	var lift := hover_amount * 4.0
	var card_rect := Rect2(rect.position - Vector2(0, lift), rect.size)
	var reduced := MotionSystem.reduced()
	var depth_offset := _materials.extrusion_offset(1.0, reduced)
	var layers := _materials.depth_layers_for(1.0, reduced)
	for layer in range(layers, 0, -1):
		var factor := float(layer) / float(layers)
		var layer_color := _materials.depth_tone(bottom_color, 0.92)
		_draw_box(Rect2(card_rect.position + depth_offset * factor, card_rect.size), Color(layer_color, 0.90), 28, Color.TRANSPARENT, 0)
	_draw_box(Rect2(card_rect.position + depth_offset + Vector2(0, 5), card_rect.size), Color(0.02, 0.11, 0.25, 0.22), 28, Color.TRANSPARENT, 0)
	_draw_box(card_rect, bottom_color, 28, Color("ffffff", 0.78), 2)
	var top_rect := Rect2(card_rect.position, Vector2(card_rect.size.x, card_rect.size.y * 0.55))
	_draw_box(top_rect, Color(top_color, 0.94), 28, Color.TRANSPARENT, 0)
	draw_rect(Rect2(card_rect.position + Vector2(0, card_rect.size.y * 0.42), Vector2(card_rect.size.x, card_rect.size.y * 0.32)), Color(vibrant_surface, 0.08), true)
	draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.82, card_rect.size.y * 0.18), 70.0, Color("ffffff", card_glow * 0.30))
	draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.12, card_rect.size.y * 0.85), 54.0, Color(game_gradient[2], card_glow * 0.26))
	draw_line(card_rect.position + Vector2(22, 7), Vector2(card_rect.end.x - 22, card_rect.position.y + 7), Color("ffffff", 0.58), 3.0, true)

	var icon_center := Vector2(size.x * 0.5, 72 - lift)
	_draw_game_icon(icon_center)

	var font := ThemeDB.fallback_font
	var title_width := card_rect.size.x - 20.0
	draw_string(font, Vector2(10, 148 - lift), title, HORIZONTAL_ALIGNMENT_CENTER, title_width, 24, Color.WHITE)
	draw_string(font, Vector2(10, 178 - lift), "LEVEL %d" % level, HORIZONTAL_ALIGNMENT_CENTER, title_width, 17, Color("fff5a8"))
	draw_string(font, Vector2(10, 205 - lift), _mode_label(), HORIZONTAL_ALIGNMENT_CENTER, title_width, 13, Color("f4fbff"))
	if selected:
		_draw_box(card_rect.grow(3), Color.TRANSPARENT, 31, Color("fff26e", 0.88), 3)

func _mode_label() -> String:
	match game_id:
		"water_sort": return "POUR • SORT • RELAX"
		"block_puzzle": return "DRAG • PLACE • CLEAR"
		_: return "SLIDE • CLEAR • RESCUE"

func _draw_game_icon(center: Vector2) -> void:
	var pulse := 0.5 if MotionSystem.reduced() else 0.5 + 0.5 * sin(phase * 3.0)
	var icon_rect := Rect2(center - Vector2(42, 42), Vector2(84, 84))
	var icon_depth := _materials.extrusion_offset(0.82, MotionSystem.reduced())
	_draw_box(Rect2(icon_rect.position + icon_depth, icon_rect.size), _materials.depth_tone(Color(accent, 0.76)), 24, Color.TRANSPARENT, 0)
	_draw_box(icon_rect, Color("ffffff", 0.18 + pulse * 0.04), 24, Color("ffffff", 0.54), 2)
	match game_id:
		"water_sort":
			var liquids: Array[Color] = [Color("ffd43b"), Color("ff58b5"), Color("63f0ff")]
			for i in range(3):
				var x := center.x - 22 + i * 22
				draw_line(Vector2(x - 6, center.y - 23), Vector2(x - 6, center.y + 22), Color("e8fbff"), 3.0, true)
				draw_line(Vector2(x + 6, center.y - 23), Vector2(x + 6, center.y + 22), Color("e8fbff"), 3.0, true)
				draw_arc(Vector2(x, center.y + 21), 6.0, 0, PI, 18, Color("e8fbff"), 3.0, true)
				draw_rect(Rect2(Vector2(x - 4, center.y + 1 + float(i) * 3), Vector2(8, 18 - float(i) * 3)), liquids[i], true)
		"block_puzzle":
			var colors: Array[Color] = [Color("ffd33d"), Color("ff6c8e"), Color("a75cff")]
			var cells := [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)]
			for i in range(cells.size()):
				var p: Vector2i = cells[i]
				var r := Rect2(center + Vector2(float(p.x - 1) * 18 - 7, float(p.y - 1) * 18 - 7), Vector2(15, 15))
				var col: Color = colors[i % colors.size()]
				_draw_box(Rect2(r.position + Vector2(2, 5), r.size), _materials.depth_tone(col), 4, Color.TRANSPARENT, 0)
				_draw_box(r, col, 4, Color("ffffff", 0.48), 1)
		_:
			draw_circle(center, 24, Color("ffd84f"))
			draw_circle(center + Vector2(-8, -5), 3.2, Color("253550"))
			draw_circle(center + Vector2(8, -5), 3.2, Color("253550"))
			draw_arc(center + Vector2(0, 4), 9, 0.2, PI - 0.2, 16, Color("253550"), 2.5, true)
			var tip := center + Vector2(36, 0)
			var points := PackedVector2Array([center + Vector2(18,-9), center + Vector2(18,9), tip])
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
