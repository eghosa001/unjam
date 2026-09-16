extends "res://scripts/game/water_sort_reference_motion.gd"

# GAME_FIRST_WATER

func _balanced_columns(tube_count: int) -> int:
	if tube_count <= 6:
		return 3
	if tube_count <= 8:
		return 4
	if tube_count <= 10:
		return 5
	return 6

func render_board() -> void:
	super.render_board()
	if board == null:
		return
	var count := tubes.size()
	board.columns = _balanced_columns(count)
	var tube_size := _tube_size_for_count(count)
	var gap := 22 if count <= 8 else 14
	board.add_theme_constant_override("h_separation", gap)
	board.add_theme_constant_override("v_separation", 26)
	for child in board.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = tube_size

func _tube_size_for_count(tube_count: int) -> Vector2:
	if tube_count <= 6:
		return Vector2(208, 370)
	if tube_count <= 8:
		return Vector2(184, 348)
	if tube_count <= 10:
		return Vector2(164, 324)
	return Vector2(138, 296)

func _visual_mouth_local(control: Control) -> Vector2:
	var outer_x := control.size.x * 0.18
	var outer_y := 13.0
	var outer_w := control.size.x * 0.64
	var outer_h := control.size.y - 42.0
	var neck_h := outer_h * 0.10
	var lip_y := outer_y + neck_h * 0.28 + 1.0
	if control.rotation > 0.08:
		return Vector2(outer_x + outer_w * 0.92, lip_y)
	if control.rotation < -0.08:
		return Vector2(outer_x + outer_w * 0.08, lip_y)
	return Vector2(outer_x + outer_w * 0.5, lip_y)

func _control_point(control: Control, local_point: Vector2) -> Vector2:
	var adjusted := local_point
	if local_point.y <= 42.0 and absf(local_point.x - control.size.x * 0.5) <= control.size.x * 0.18:
		adjusted = _visual_mouth_local(control)
	return super._control_point(control, adjusted)
