extends Button
class_name BlockCellButton

var occupied := false
var preview := false
var accent := Color("8b7cf6")
var footprint_active := false
var footprint_valid := false
var cell_index := 0
var phase := 0.0
var hover_amount := 0.0
var impact := 0.0
var clear_echo := 0.0

func configure(value: bool, preview_value: bool = false, color: Color = Color("8b7cf6"), index: int = 0) -> void:
	var old := occupied
	occupied = value
	preview = preview_value
	accent = color
	cell_index = index
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if is_inside_tree():
		if not old and occupied:
			_play_land()
		elif old and not occupied:
			_play_clear()
	queue_redraw()

func _ready() -> void:
	set_process(true)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_update_pivot)
	_update_pivot()

func _update_pivot() -> void:
	pivot_offset = size * 0.5

func _hover(value: bool) -> void:
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.11)

func _press() -> void:
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(0.94, 0.94), 0.05)

func _release() -> void:
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.07, 1.07), 0.075)
	tw.tween_property(self, "scale", Vector2.ONE, 0.14)

func _play_land() -> void:
	impact = 1.0
	scale = Vector2(0.70, 0.70)
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.11)
	tw.tween_property(self, "scale", Vector2.ONE, 0.13)

func _play_clear() -> void:
	clear_echo = 1.0
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(1.16, 1.16), 0.07)
	tw.tween_property(self, "scale", Vector2(0.40, 0.40), 0.10)
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)

func set_drag_footprint(active: bool, valid: bool = false) -> void:
	footprint_active = active
	footprint_valid = valid
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	impact = maxf(0.0, impact - delta * 4.0)
	clear_echo = maxf(0.0, clear_echo - delta * 3.8)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	var shadow_rect := Rect2(rect.position + Vector2(0, 5), rect.size)
	_draw_box(shadow_rect, Color(0.01, 0.02, 0.07, 0.44), 16, Color.TRANSPARENT, 0)
	var base := Color("11192d")
	if hover_amount > 0.01 and not occupied:
		base = base.lightened(0.055 * hover_amount)
	_draw_box(rect, base, 16, Color("35415f"), 1)

	var pulse := 0.5 + 0.5 * sin(phase * 5.0 + float(cell_index) * 0.13)
	if occupied or preview or footprint_active or clear_echo > 0.001:
		var inset := rect.grow(-7)
		var fill := accent
		if clear_echo > 0.001 and not occupied:
			fill = Color(accent.lightened(0.25), clear_echo)
		elif preview:
			fill = Color(accent, 0.42)
		elif footprint_active and not occupied:
			fill = Color("34d399", 0.34 + pulse * 0.08) if footprint_valid else Color("ef476f", 0.23 + pulse * 0.06)
		_draw_box(inset, fill, 12, fill.lightened(0.22), 1)
		var top_y := inset.position.y + 6
		draw_line(Vector2(inset.position.x + 7, top_y), Vector2(inset.end.x - 7, top_y), Color(1, 1, 1, 0.28), 3.0, true)
		var bottom_y := inset.end.y - 5
		draw_line(Vector2(inset.position.x + 8, bottom_y), Vector2(inset.end.x - 8, bottom_y), Color(accent.darkened(0.35), 0.38), 3.0, true)
		if footprint_active and not footprint_valid:
			draw_line(inset.position + Vector2(13, 13), inset.end - Vector2(13, 13), Color("ffffff", 0.88), 4.0, true)
			draw_line(Vector2(inset.end.x - 13, inset.position.y + 13), Vector2(inset.position.x + 13, inset.end.y - 13), Color("ffffff", 0.88), 4.0, true)

	if impact > 0.001:
		_draw_box(rect.grow(3 + impact * 3), Color.TRANSPARENT, 19, Color(accent.lightened(0.38), impact * 0.70), 3)

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
