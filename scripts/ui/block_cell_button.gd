extends Button
class_name BlockCellButton

var occupied := false
var preview := false
var accent := Color("4f7cff")
var footprint_active := false
var footprint_valid := false
var cell_index := 0
var hover_amount := 0.0
var impact := 0.0
var clear_echo := 0.0
var clear_phase := 0.0

func configure(value: bool, preview_value: bool = false, color: Color = Color("4f7cff"), index: int = 0) -> void:
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
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.08)
	if not value and footprint_active:
		footprint_active = false
		footprint_valid = false
		queue_redraw()

func _press() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(0.965, 0.965), 0.045)

func _release() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.045, 1.045), 0.055)
	tw.tween_property(self, "scale", Vector2.ONE, 0.11)

func _play_land() -> void:
	impact = 1.0
	scale = Vector2(0.72, 0.72)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.10, 1.10), 0.09)
	tw.tween_property(self, "scale", Vector2.ONE, 0.11)

func _play_clear() -> void:
	clear_echo = 1.0
	clear_phase = 1.0
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(1.10, 1.10), 0.055)
	tw.tween_property(self, "scale", Vector2(0.12, 0.12), 0.115)
	tw.tween_property(self, "scale", Vector2.ONE, 0.055)

func set_drag_footprint(active: bool, valid: bool = false) -> void:
	footprint_active = active
	footprint_valid = valid
	queue_redraw()

func _game() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("place_piece_from_drag") and node.has_method("can_place"):
			return node
		node = node.get_parent()
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or String(data.get("kind", "")) != "block_piece":
		set_drag_footprint(false, false)
		return false
	var game := _game()
	if game == null:
		set_drag_footprint(false, false)
		return false
	var origin := Vector2i(cell_index % 8, int(cell_index / 8))
	var valid: bool = bool(game.can_place(data.get("shape", []), origin))
	set_drag_footprint(true, valid)
	return valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var game := _game()
	set_drag_footprint(false, false)
	if game == null or not (data is Dictionary):
		return
	var origin := Vector2i(cell_index % 8, int(cell_index / 8))
	game.place_piece_from_drag(int(data.get("piece_index", -1)), origin)

func _process(delta: float) -> void:
	impact = maxf(0.0, impact - delta * 5.5)
	clear_echo = maxf(0.0, clear_echo - delta * 3.8)
	clear_phase = maxf(0.0, clear_phase - delta * 4.8)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(1.5, 1.5), size - Vector2(3, 3))
	var board_fill := Color("20294b")
	if hover_amount > 0.01 and not occupied:
		board_fill = board_fill.lightened(0.035 * hover_amount)
	_draw_box(rect, board_fill, 3, Color("111833"), 1)

	if occupied or preview or footprint_active:
		var inset := rect.grow(-2.0)
		var fill := accent
		if preview:
			fill = Color(accent, 0.48)
		elif footprint_active and not occupied:
			fill = Color("48e27a", 0.40) if footprint_valid else Color("ff4f73", 0.32)
		_draw_block(inset, fill)

	if impact > 0.001:
		_draw_box(rect.grow(1.0 + impact * 2.0), Color.TRANSPARENT, 4, Color(accent.lightened(0.38), impact * 0.78), 2)

	if clear_echo > 0.001:
		var neon := Color("ff416c", clear_echo)
		_draw_box(rect.grow(1.0 + clear_echo * 3.0), Color(neon, 0.08), 3, neon, 3)
		var c := rect.get_center()
		var r := rect.size.x * (0.14 + (1.0 - clear_echo) * 0.42)
		draw_arc(c, r, 0.0, TAU, 20, Color("ff7a96", clear_echo), 2.0, true)

func _draw_block(rect: Rect2, fill: Color) -> void:
	var darker := fill.darkened(0.26)
	_draw_box(Rect2(rect.position + Vector2(0, 3), rect.size), darker, 3, Color.TRANSPARENT, 0)
	_draw_box(rect, fill, 3, fill.lightened(0.22), 1)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.end.x - 3, rect.position.y + 3), Color(fill.lightened(0.48), 0.95), 2.0, true)
	draw_line(rect.position + Vector2(3, 3), Vector2(rect.position.x + 3, rect.end.y - 3), Color(fill.lightened(0.30), 0.75), 1.5, true)
	draw_line(Vector2(rect.position.x + 3, rect.end.y - 3), rect.end - Vector2(3, 3), Color(darker, 0.92), 2.0, true)
	draw_line(Vector2(rect.end.x - 3, rect.position.y + 3), rect.end - Vector2(3, 3), Color(darker, 0.78), 1.5, true)

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
