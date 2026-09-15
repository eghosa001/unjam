extends "res://scripts/game/rescue_rush_motion_final.gd"

func render_board() -> void:
	super.render_board()
	if board_grid == null:
		return
	var viewport_size := get_viewport_rect().size
	var viewport_width := viewport_size.x
	var viewport_height := viewport_size.y
	var gap := 10.0 if width <= 5 else 7.0
	var max_board_width := minf(viewport_width - 112.0, 860.0)
	var reserved_vertical := clampf(viewport_height * 0.42, 640.0, 860.0)
	var max_board_height := maxf(360.0, viewport_height - reserved_vertical)
	var width_cell := floor((max_board_width - gap * float(maxi(width - 1, 0))) / float(maxi(width, 1)))
	var height_cell := floor((max_board_height - gap * float(maxi(height - 1, 0))) / float(maxi(height, 1)))
	var cell_size := int(clampf(minf(width_cell, height_cell), 62.0, 142.0))
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
