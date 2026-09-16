class_name GameSelectTile
extends Button

signal chosen(game_id: String)

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

var game_id := "rescue_rush"
var title := "RESCUE RUSH"
var level := 1
var accent := Color("2dd4b6")
var selected := false
var dark_mode := true
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
	var rect := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var surface := Color("101a2c") if dark_mode else Color("ffffff")
	var ink := Color("f8fbff") if dark_mode else Color("122036")
	var muted := Color("95a6be") if dark_mode else Color("607087")
	var border := accent if selected else Color("34455d") if dark_mode else Color("c7d1df")
	var lift := hover_amount * 3.0
	var card_rect := Rect2(rect.position - Vector2(0, lift), rect.size)
	var reduced := MotionSystem.reduced()
	var depth_offset := _materials.extrusion_offset(1.0, reduced)
	var layers := _materials.depth_layers_for(1.0, reduced)
	var depth_color: Color = _materials.depth_tone(surface)
	for layer in range(layers, 0, -1):
		var factor := float(layer) / float(layers)
		var layer_offset := depth_offset * factor
		_draw_box(Rect2(card_rect.position + layer_offset, card_rect.size), Color(depth_color, 0.82 - factor * 0.12), 28, Color.TRANSPARENT, 0)
	var shadow_rect := Rect2(card_rect.position + depth_offset + Vector2(0, 5), card_rect.size)
	_draw_box(shadow_rect, Color(0, 0, 0, 0.25 if dark_mode else 0.13), 28, Color.TRANSPARENT, 0)
	_draw_box(card_rect, surface, 28, Color(border, 0.90 if selected else 0.58), 2 if selected else 1)
	var bevel: Color = _materials.bevel_light(surface, 0.82)
	draw_line(card_rect.position + Vector2(24, 5), Vector2(card_rect.end.x - 24, card_rect.position.y + 5), Color(bevel, 0.45 if dark_mode else 0.68), 2.0, true)
	var lower_bevel: Color = _materials.bevel_dark(surface, 0.85)
	draw_line(Vector2(card_rect.position.x + 24, card_rect.end.y - 4), card_rect.end - Vector2(24, 4), Color(lower_bevel, 0.72), 2.0, true)

	var glow_alpha := 0.12 if selected else hover_amount * 0.07
	if glow_alpha > 0.001:
		_draw_box(card_rect.grow(4), Color(accent, glow_alpha), 31, Color.TRANSPARENT, 0)

	var icon_center := Vector2(58, size.y * 0.5 - lift)
	_draw_game_icon(icon_center)

	var font := ThemeDB.fallback_font
	var title_color := accent.lightened(0.12) if selected else ink
	draw_string(font, Vector2(108, 68 - lift), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, title_color)
	draw_string(font, Vector2(108, 104 - lift), "LEVEL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, muted)
	var mode_text := _mode_label()
	draw_string(font, Vector2(108, 139 - lift), mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(accent, 0.82))

	var chevron_x := size.x - 31.0
	var chevron_y := size.y * 0.5 - lift
	draw_line(Vector2(chevron_x - 8, chevron_y - 10), Vector2(chevron_x + 2, chevron_y), Color(ink, 0.62), 3.0, true)
	draw_line(Vector2(chevron_x + 2, chevron_y), Vector2(chevron_x - 8, chevron_y + 10), Color(ink, 0.62), 3.0, true)

	if selected and not reduced:
		var sweep := fposmod(phase * 110.0, maxf(1.0, size.x - 80.0))
		draw_rect(Rect2(Vector2(38 + sweep, size.y - 8 - lift), Vector2(42, 3)), Color(accent, 0.40), true)

func _mode_label() -> String:
	match game_id:
		"water_sort": return "SORT • POUR • RELAX"
		"block_puzzle": return "DRAG • PLACE • CLEAR"
		_: return "TAP • ESCAPE • RESCUE"

func _draw_game_icon(center: Vector2) -> void:
	var pulse := 0.5 if MotionSystem.reduced() else 0.5 + 0.5 * sin(phase * 3.0)
	var icon_rect := Rect2(center - Vector2(36, 36), Vector2(72, 72))
	var icon_depth := _materials.extrusion_offset(0.78, MotionSystem.reduced())
	_draw_box(Rect2(icon_rect.position + icon_depth, icon_rect.size), _materials.depth_tone(Color(accent, 0.42)), 22, Color.TRANSPARENT, 0)
	_draw_box(icon_rect, Color(accent, 0.12 + pulse * 0.035), 22, Color(_materials.bevel_light(accent), 0.36), 1)
	match game_id:
		"water_sort":
			for i in range(3):
				var x := center.x - 20 + i * 20
				draw_line(Vector2(x - 6, center.y - 19), Vector2(x - 6, center.y + 18), Color("d9f2ff", 0.75), 3.0, true)
				draw_line(Vector2(x + 6, center.y - 19), Vector2(x + 6, center.y + 18), Color("d9f2ff", 0.75), 3.0, true)
				draw_arc(Vector2(x, center.y + 17), 6.0, 0, PI, 18, Color("d9f2ff", 0.75), 3.0, true)
				draw_rect(Rect2(Vector2(x - 4, center.y + 1 + float(i) * 3), Vector2(8, 14 - float(i) * 3)), Color(accent.lightened(float(i) * 0.10), 0.95), true)
		"block_puzzle":
			var cells := [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)]
			for p in cells:
				var r := Rect2(center + Vector2(float(p.x - 1) * 16 - 6, float(p.y - 1) * 16 - 6), Vector2(13, 13))
				var d := _materials.extrusion_offset(0.55, MotionSystem.reduced())
				_draw_box(Rect2(r.position + d, r.size), _materials.depth_tone(accent), 4, Color.TRANSPARENT, 0)
				_draw_box(r, accent, 4, _materials.bevel_light(accent), 1)
		_:
			var dir := Vector2.RIGHT
			var tip := center + dir * 21
			var n := Vector2(0, 1)
			var points := PackedVector2Array([
				center - dir * 18 + n * 7,
				center + dir * 5 + n * 7,
				center + dir * 5 + n * 15,
				tip,
				center + dir * 5 - n * 15,
				center + dir * 5 - n * 7,
				center - dir * 18 - n * 7
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
