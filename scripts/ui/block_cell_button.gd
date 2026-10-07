extends Button
class_name BlockCellButton

const AUTHORED_TILE_OVERLAY: Texture2D = preload("res://assets/art/gameplay/block_tile_overlay.svg")
const AUTHORED_SPECIALS := {
	"crate": preload("res://assets/art/gameplay/special_crate.svg"),
	"ice": preload("res://assets/art/gameplay/special_ice.svg"),
	"lock": preload("res://assets/art/gameplay/special_lock.svg"),
	"steel": preload("res://assets/art/gameplay/special_steel.svg"),
	"target": preload("res://assets/art/gameplay/special_target.svg"),
}

var occupied := false
var preview := false
var accent := Color("4f7cff")
var footprint_active := false
var footprint_valid := false
var footprint_color := Color("8b7cf6")
var cell_index := 0
var hover_amount := 0.0
var impact := 0.0
var clear_echo := 0.0
var clear_phase := 0.0
var clear_color := Color("8b7cf6")
var footprint_phase := 0.0
var special_kind := ""
var special_layers := 0
var _game_cache: Node

func configure(value: bool, preview_value: bool = false, color: Color = Color("4f7cff"), index: int = 0) -> void:
	var old := occupied
	var old_accent := accent
	var changed := (
		occupied != value
		or preview != preview_value
		or not accent.is_equal_approx(color)
		or cell_index != index
	)
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
			clear_color = old_accent
			_play_clear()
	if changed:
		queue_redraw()

func set_special(kind: String = "", layers: int = 0) -> void:
	var safe_layers := maxi(0, layers)
	if special_kind == kind and special_layers == safe_layers:
		return
	special_kind = kind
	special_layers = safe_layers
	queue_redraw()

func _ready() -> void:
	set_process(false)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_update_pivot)
	_update_pivot()

func _update_pivot() -> void:
	pivot_offset = size * 0.5

func _wake_animation() -> void:
	if not is_processing():
		set_process(true)

func _hover(value: bool) -> void:
	_wake_animation()
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.08)

func _press() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(0.965, 0.965), 0.045)

func _release() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.045, 1.045), 0.055)
	tw.tween_property(self, "scale", Vector2.ONE, 0.11)

func _play_land() -> void:
	_wake_animation()
	impact = 1.0
	scale = Vector2(0.66, 0.66)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.14, 1.14), 0.09)
	tw.tween_property(self, "scale", Vector2(0.98, 0.98), 0.07)
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)

func play_land(delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_play_land()

func play_clear(delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_play_clear()

func _play_clear() -> void:
	_wake_animation()
	clear_echo = 1.0
	clear_phase = 1.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(1.18, 1.18), 0.065)
	tw.tween_property(self, "scale", Vector2(0.05, 0.05), 0.155).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_finish_clear_visual)
	tw.tween_property(self, "scale", Vector2.ONE, 0.075)

func _finish_clear_visual() -> void:
	clear_phase = 0.0
	queue_redraw()

func set_drag_footprint(active: bool, valid: bool = false, color: Color = Color("8b7cf6")) -> void:
	footprint_active = active
	footprint_valid = valid
	footprint_color = color
	if active:
		footprint_phase = 1.0
	_wake_animation()
	queue_redraw()

func _game() -> Node:
	if _game_cache != null and is_instance_valid(_game_cache):
		return _game_cache
	var node: Node = self
	while node != null:
		if node.has_method("place_piece_from_drag") and node.has_method("can_place"):
			_game_cache = node
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
	var drag_color: Color = Color(data.get("accent", Color("8b7cf6")))
	set_drag_footprint(true, valid, drag_color)
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
	clear_phase = maxf(0.0, clear_phase - delta * 3.2)
	if footprint_active:
		footprint_phase += delta * 6.0
	var animating := impact > 0.001 or clear_echo > 0.001 or clear_phase > 0.001 or footprint_active or hover_amount > 0.001
	if animating:
		queue_redraw()
	else:
		set_process(false)

func _draw() -> void:
	var rect := Rect2(Vector2(1.5, 1.5), size - Vector2(3, 3))
	var inset := rect.grow(-2.5)

	# Empty cells intentionally recede. The board should read as a play field,
	# not sixty-four individually outlined buttons.
	if not occupied and not preview:
		var idle_fill := Color(0.43, 0.27, 0.66, 0.145 + hover_amount * 0.070)
		var idle_edge := Color(0.86, 0.72, 1.0, 0.125 + hover_amount * 0.13)
		_draw_box(inset, idle_fill, 6, idle_edge, 1)
		# A restrained inset keeps the empty board tactile without restoring
		# sixty-four loud borders. It reads as a shallow premium well at phone size.
		var idle_inner := inset.grow(-3.0)
		_draw_box(idle_inner, Color(0.18, 0.09, 0.31, 0.145 + hover_amount * 0.040), 4, Color(1, 1, 1, 0.055 + hover_amount * 0.045), 1)

	if occupied or preview:
		var fill := Color(accent, 0.54) if preview else accent
		_draw_block(inset, fill)

	if footprint_active:
		var pulse := 0.72 + 0.28 * sin(footprint_phase)
		var edge := Color(footprint_color.lightened(0.42), 0.72 + pulse * 0.20) if footprint_valid else Color("#ff8ba3", 0.92)
		var wash := Color(footprint_color, 0.11 + pulse * 0.07) if footprint_valid else Color("#ff4f73", 0.12)
		_draw_box(inset.grow(1.0), wash, 7, edge, 3)

	if clear_phase > 0.001 and not occupied:
		var clear_fill := Color(clear_color, clampf(clear_phase, 0.0, 1.0))
		_draw_block(inset, clear_fill)
		_draw_box(inset.grow(-3.0), Color(1, 1, 1, clampf(clear_phase * 0.32, 0.0, 0.32)), 5, Color.TRANSPARENT, 0)

	if impact > 0.001:
		_draw_box(inset.grow(1.0 + impact * 3.0), Color.TRANSPARENT, 7, Color(accent.lightened(0.42), impact * 0.86), 3)
	_draw_special_overlay(rect)

	if clear_echo > 0.001:
		var neon := Color("#ff416c", clear_echo)
		_draw_box(inset.grow(1.0 + clear_echo * 4.0), Color(neon, 0.06), 7, neon, 3)
		var center := inset.get_center()
		var radius := inset.size.x * (0.14 + (1.0 - clear_echo) * 0.46)
		draw_arc(center, radius, 0.0, TAU, 24, Color("#ff7a96", clear_echo), 2.5, true)

func _draw_special_overlay(rect: Rect2) -> void:
	if special_kind.is_empty() or special_layers <= 0:
		return
	var inset := rect.grow(-5.0)
	if AUTHORED_SPECIALS.has(special_kind):
		var special_texture := AUTHORED_SPECIALS[special_kind] as Texture2D
		draw_texture_rect(special_texture, inset.grow(2.0), false, Color.WHITE)
		if special_layers > 1:
			var authored_badge := Rect2(Vector2(inset.end.x - 22, inset.position.y + 4), Vector2(18, 18))
			_draw_box(authored_badge, Color("241638", 0.92), 8, Color(1, 1, 1, 0.28), 1)
			draw_string(ThemeDB.fallback_font, authored_badge.position + Vector2(3, 14), str(special_layers), HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color.WHITE)
		return
	if special_kind == "crate":
		_draw_box(inset, Color("915a35", 0.88), 5, Color("e6b77e"), 2)
		draw_line(inset.position + Vector2(5, 5), inset.end - Vector2(5, 5), Color("f5d2a4"), 3.0, true)
		draw_line(Vector2(inset.end.x - 5, inset.position.y + 5), Vector2(inset.position.x + 5, inset.end.y - 5), Color("f5d2a4"), 3.0, true)
	elif special_kind == "ice":
		_draw_box(inset, Color("9de6ff", 0.24), 6, Color("d9f7ff", 0.92), 3)
		draw_line(inset.position + Vector2(7, inset.size.y * 0.28), inset.position + Vector2(inset.size.x * 0.72, 7), Color(1, 1, 1, 0.82), 2.0, true)
	elif special_kind == "lock":
		_draw_box(inset, Color("4b4f67", 0.62), 6, Color("f0cf63", 0.95), 3)
		var center := inset.get_center()
		draw_arc(center + Vector2(0, -4), inset.size.x * 0.18, PI, TAU, 16, Color("ffe894"), 3.0, true)
		_draw_box(Rect2(center + Vector2(-inset.size.x * 0.18, -2), Vector2(inset.size.x * 0.36, inset.size.y * 0.32)), Color("d5a52c", 0.94), 4, Color("fff0a6"), 2)
	elif special_kind == "steel":
		_draw_box(inset, Color("8693a8", 0.46), 5, Color("dce7f5", 0.96), 3)
		draw_line(inset.position + Vector2(6, inset.size.y * 0.33), Vector2(inset.end.x - 6, inset.position.y + inset.size.y * 0.33), Color("f7fbff", 0.72), 2.0, true)
		draw_line(inset.position + Vector2(6, inset.size.y * 0.66), Vector2(inset.end.x - 6, inset.position.y + inset.size.y * 0.66), Color("536073", 0.68), 2.0, true)
	elif special_kind == "target":
		var center := inset.get_center()
		draw_arc(center, inset.size.x * 0.27, 0.0, TAU, 28, Color("ffd85a", 0.96), 3.5, true)
		draw_circle(center, 3.0, Color("fff4b1"))
	elif special_kind in ["row_target", "col_target", "cross_target"]:
		var marker := Color("ffd85a", 0.92)
		if special_kind in ["row_target", "cross_target"]:
			var y := inset.get_center().y
			draw_line(Vector2(inset.position.x + 4, y), Vector2(inset.end.x - 4, y), marker, 3.0, true)
		if special_kind in ["col_target", "cross_target"]:
			var x := inset.get_center().x
			draw_line(Vector2(x, inset.position.y + 4), Vector2(x, inset.end.y - 4), marker, 3.0, true)
	elif special_kind == "preserve":
		_draw_box(inset, Color(0.24, 0.95, 0.74, 0.10), 6, Color("67f0c2", 0.94), 3)
		var center := inset.get_center()
		draw_arc(center, inset.size.x * 0.22, PI, TAU, 18, Color("b6ffe8", 0.92), 3.0, true)
	if special_layers > 1:
		var badge := Rect2(Vector2(inset.end.x - 22, inset.position.y + 4), Vector2(18, 18))
		_draw_box(badge, Color("241638", 0.92), 8, Color(1, 1, 1, 0.28), 1)
		draw_string(ThemeDB.fallback_font, badge.position + Vector2(3, 14), str(special_layers), HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color.WHITE)

func _draw_block(rect: Rect2, fill: Color) -> void:
	# Saturated two-tone 2D material: one face, one contact shadow, one highlight.
	# This keeps pieces rich without the noisy pseudo-3D top/right polygons.
	var radius := maxi(5, int(rect.size.x * 0.18))
	var shadow := Rect2(rect.position + Vector2(0, maxf(2.0, rect.size.y * 0.09)), rect.size)
	_draw_box(shadow, Color(0.02, 0.025, 0.08, 0.28), radius, Color.TRANSPARENT, 0)
	_draw_box(rect, fill, radius, Color(fill.lightened(0.30), 0.40), 1)
	draw_texture_rect(AUTHORED_TILE_OVERLAY, rect.grow(1.0), false, Color.WHITE)
	var shade := Rect2(Vector2(rect.position.x + rect.size.x * 0.08, rect.end.y - rect.size.y * 0.17), Vector2(rect.size.x * 0.84, rect.size.y * 0.10))
	_draw_box(shade, Color(fill.darkened(0.34), 0.24), maxi(2, radius / 2), Color.TRANSPARENT, 0)
	var gloss := Rect2(
		rect.position + Vector2(rect.size.x * 0.12, rect.size.y * 0.10),
		Vector2(rect.size.x * 0.58, maxf(3.0, rect.size.y * 0.14))
	)
	_draw_box(gloss, Color(1,1,1,0.28), maxi(2, radius / 2), Color.TRANSPARENT, 0)
	draw_circle(rect.position + Vector2(rect.size.x * 0.23, rect.size.y * 0.30), maxf(1.2, rect.size.x * 0.038), Color(1,1,1,0.46))

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
