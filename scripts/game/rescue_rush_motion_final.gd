extends "res://scripts/game/rescue_rush_premium.gd"

# Completion must never cover an escape that is still visibly travelling.
# The polished escape sequence lasts ~0.47 s; keep a small safety margin so
# the final arrow is fully off-screen before the rescue/result celebration.
var _escape_visual_deadline_msec := 0

func render_board() -> void:
	super.render_board()
	_fit_board_to_viewport()

func _fit_board_to_viewport() -> void:
	if board_grid == null or board_panel == null or width <= 0 or height <= 0:
		return
	var viewport_size := get_viewport_rect().size
	var gap_x := float(board_grid.get_theme_constant("h_separation"))
	var gap_y := float(board_grid.get_theme_constant("v_separation"))
	var max_board_width := minf(maxf(320.0, viewport_size.x - 112.0), 860.0)
	# Reserve the header/status/action/footer stack and constrain late-level tall
	# boards by height as well as width. Width-only sizing was the overflow root cause.
	var max_board_height := minf(maxf(360.0, viewport_size.y * 0.52), 1040.0)
	var calculated_width := floor((max_board_width - 40.0 - gap_x * float(maxi(0, width - 1))) / float(width))
	var calculated_height := floor((max_board_height - 40.0 - gap_y * float(maxi(0, height - 1))) / float(height))
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
		_escape_visual_deadline_msec = maxi(_escape_visual_deadline_msec, Time.get_ticks_msec() + 520)

func resolve_rescue() -> void:
	if not rescue_has_exit():
		return
	# Re-render once after all cascade state has settled. This removes the
	# source buttons for escaped/inactive arrows while their flying ghosts finish.
	render_board()
	while Time.get_ticks_msec() < _escape_visual_deadline_msec:
		await get_tree().process_frame
	# A tiny breathing beat makes the final escape read before the rescue leaves.
	await get_tree().create_timer(0.035).timeout
	await super.resolve_rescue()
