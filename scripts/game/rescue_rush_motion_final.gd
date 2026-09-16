extends "res://scripts/game/rescue_rush_premium.gd"

# Final active Rescue Rush motion layer. Completion is held until every escape
# ghost has visually cleared, preventing the result card from covering the last arrow.
var _escape_visual_deadline_msec := 0

func render_board() -> void:
	super.render_board()
	_fit_board_to_viewport()

func _fit_board_to_viewport() -> void:
	if board_grid == null or board_panel == null or width <= 0 or height <= 0:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var gap_x := float(board_grid.get_theme_constant("h_separation"))
	var gap_y := float(board_grid.get_theme_constant("v_separation"))
	var max_board_width := minf(maxf(320.0, viewport_size.x - 112.0), 860.0)
	var max_board_height := minf(maxf(360.0, viewport_size.y * 0.52), 1040.0)
	var calculated_width: float = floorf((max_board_width - 40.0 - gap_x * float(maxi(0, width - 1))) / float(width))
	var calculated_height: float = floorf((max_board_height - 40.0 - gap_y * float(maxi(0, height - 1))) / float(height))
	var cell_size := int(clampf(minf(calculated_width, calculated_height), 54.0, 142.0))
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
			if child.get_child_count() > 0 and child.get_child(0) is Control:
				(child.get_child(0) as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	var board_width := float(width * cell_size) + gap_x * float(maxi(0, width - 1)) + 40.0
	var board_height := float(height * cell_size) + gap_y * float(maxi(0, height - 1)) + 40.0
	board_panel.custom_minimum_size = Vector2(board_width, board_height)

func escape_piece(index: int, trigger_effect: bool) -> void:
	var was_active := index >= 0 and index < pieces.size() and bool(pieces[index].get("active", true))
	super.escape_piece(index, trigger_effect)
	if was_active and trigger_effect:
		var escape_hold := MotionSystem.duration(&"travel") + MotionSystem.duration(&"settle") * 2.0
		if MotionSystem.reduced():
			escape_hold = MotionSystem.duration(&"settle")
		_escape_visual_deadline_msec = maxi(_escape_visual_deadline_msec, Time.get_ticks_msec() + int(escape_hold * 1000.0))

func resolve_rescue() -> void:
	if not rescue_has_exit():
		return
	# Re-render after cascade state settles so inactive source arrows disappear
	# while their moving ghosts complete their final travel.
	render_board()
	while Time.get_ticks_msec() < _escape_visual_deadline_msec:
		await get_tree().process_frame
	if not MotionSystem.reduced():
		await get_tree().create_timer(MotionSystem.duration(&"micro") * 0.5).timeout
	await super.resolve_rescue()
