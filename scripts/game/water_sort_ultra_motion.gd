extends "res://scripts/game/water_sort_reference_motion.gd"

# GAME_FIRST_WATER

func _ready() -> void:
	super._ready()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_queue_tube_layout):
		viewport.size_changed.connect(_queue_tube_layout)

func _queue_tube_layout() -> void:
	call_deferred("_apply_tube_layout")

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
	_apply_tube_layout()

func _available_tube_height(row_count: int) -> float:
	var viewport_height := get_viewport_rect().size.y
	# Reserve header/info/objective/feedback/actions and margins, then let the
	# bottle rows consume the rest on tall phones instead of leaving a dead stage.
	var remaining := viewport_height - 438.0
	return clampf(remaining, 340.0, viewport_height * 0.60)

func _apply_tube_layout() -> void:
	if board == null or not is_instance_valid(board):
		return
	var count := tubes.size()
	if count <= 0:
		return
	var columns := _balanced_columns(count)
	var row_count := int(ceil(float(count) / float(columns)))
	board.columns = columns
	var gap := 22 if count <= 8 else 14
	var row_gap := 26.0
	var viewport_width := get_viewport_rect().size.x
	var usable_width := maxf(360.0, viewport_width - 108.0)
	var max_width_from_screen: float = floorf((usable_width - float(gap * maxi(columns - 1, 0))) / float(columns))
	var ratio := 1.78 if count <= 6 else (1.84 if count <= 8 else 1.94)
	var available_height := _available_tube_height(row_count)
	var per_row_height := floorf((available_height - row_gap * float(maxi(row_count - 1, 0)) - 36.0) / float(maxi(row_count, 1)))
	var max_width_from_height := per_row_height / ratio
	var preferred := _tube_size_for_count(count)
	var tube_width := minf(preferred.x, minf(max_width_from_screen, max_width_from_height))
	var tube_size := Vector2(tube_width, tube_width * ratio)
	board.add_theme_constant_override("h_separation", gap)
	board.add_theme_constant_override("v_separation", int(row_gap))
	for child in board.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = tube_size
	var stage := find_child("GameplayStage", true, false) as PanelContainer
	if stage != null:
		var content_height := tube_size.y * float(row_count) + row_gap * float(maxi(row_count - 1, 0)) + 42.0
		var tall_screen_floor := 1080.0 if get_viewport_rect().size.y >= 1800.0 else 0.0
		stage.custom_minimum_size.y = minf(available_height, maxf(content_height, tall_screen_floor))

func _tube_size_for_count(tube_count: int) -> Vector2:
	if tube_count <= 6:
		return Vector2(260, 463)
	if tube_count <= 8:
		return Vector2(184, 348)
	if tube_count <= 10:
		return Vector2(164, 324)
	return Vector2(138, 296)

func _control_point(control: Control, local_point: Vector2) -> Vector2:
	# The active 3D tube now projects its own rim through Camera3D. Preserve that
	# exact local point instead of rewriting it with the old 2D bottle estimate.
	return super._control_point(control, local_point)
