extends Node

var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_fit_board_to_viewport")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.18:
		return
	timer = 0.0
	_fit_board_to_viewport()

func _fit_board_to_viewport() -> void:
	var game := get_parent() as Control
	if game == null:
		return
	var grid: GridContainer = game.get("board_grid") as GridContainer
	if grid == null or grid.get_child_count() == 0:
		return
	var board_width := int(game.get("width")) if game.get("width") != null else maxi(1, grid.columns)
	var board_height := int(game.get("height")) if game.get("height") != null else maxi(1, int(ceil(float(grid.get_child_count()) / float(maxi(board_width, 1)))))
	var viewport_size := game.get_viewport_rect().size
	var viewport_width := viewport_size.x
	var viewport_height := viewport_size.y
	var gap := 9.0 if board_width <= 5 else 7.0
	var max_board_width := minf(viewport_width - 76.0, 900.0)
	var reserved_vertical := clampf(viewport_height * 0.28, 420.0, 570.0)
	var max_board_height := maxf(420.0, viewport_height - reserved_vertical)
	var width_cell: float = floor((max_board_width - gap * float(maxi(board_width - 1, 0))) / float(maxi(board_width, 1)))
	var height_cell: float = floor((max_board_height - gap * float(maxi(board_height - 1, 0))) / float(maxi(board_height, 1)))
	var cell_size := int(clampf(minf(width_cell, height_cell), 66.0, 150.0))
	grid.add_theme_constant_override("h_separation", int(gap))
	grid.add_theme_constant_override("v_separation", int(gap))
	for child in grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
