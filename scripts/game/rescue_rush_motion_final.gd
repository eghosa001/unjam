extends "res://scripts/game/rescue_rush_premium.gd"

# Final active Rescue Rush layout layer. Escape timing lives in the polished
# gameplay renderer; this script is the single owner of responsive board sizing.
const BOARD_HEIGHT_RATIO := 0.60
const MAX_CELL_SIZE := 168.0

var _board_has_rendered := false
var _last_fit_viewport := Vector2(-1.0, -1.0)
var _last_fit_gap := Vector2(-1.0, -1.0)
var _last_fit_first_child_id := 0
var _last_fit_board_size := Vector2i(-1, -1)

func _ready() -> void:
	super._ready()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_queue_board_fit):
		viewport.size_changed.connect(_queue_board_fit)

func _queue_board_fit() -> void:
	call_deferred("_fit_board_to_viewport")

func render_board() -> void:
	# The premium layer now owns state-aware rebuilding. Do not pre-clear here or
	# an unchanged refresh would defeat control reuse before the parent can skip it.
	super.render_board()
	_board_has_rendered = true
	_fit_board_to_viewport()

func _animate_cell(cell: Control, x: int, y: int) -> void:
	# Subsequent state refreshes should never replay a whole-board pulse. Reduced
	# Motion also skips the initial grid entrance entirely instead of animating 25+
	# controls at a shortened duration.
	if _board_has_rendered or _reduced_motion_enabled():
		cell.modulate.a = 1.0
		cell.scale = Vector2.ONE
		cell.pivot_offset = cell.custom_minimum_size * 0.5
		return
	super._animate_cell(cell, x, y)

func _reduced_motion_enabled() -> bool:
	# Resolve the autoload through the scene tree here. The final Rescue leaf is
	# dynamically loaded by viewport tests and some navigation paths; avoiding a
	# direct compile-time singleton symbol keeps that inheritance chain resolvable
	# while still using MotionSystem as the single source of truth.
	var motion := get_node_or_null("/root/MotionSystem")
	return motion != null and bool(motion.call("reduced"))

func _fit_board_to_viewport() -> void:
	if board_grid == null or board_panel == null or width <= 0 or height <= 0:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var gap_x := float(board_grid.get_theme_constant("h_separation"))
	var gap_y := float(board_grid.get_theme_constant("v_separation"))
	var first_child_id := 0
	if board_grid.get_child_count() > 0:
		first_child_id = int(board_grid.get_child(0).get_instance_id())
	var board_size := Vector2i(width, height)
	var gap := Vector2(gap_x, gap_y)
	if _last_fit_viewport.is_equal_approx(viewport_size) and _last_fit_gap.is_equal_approx(gap) and _last_fit_first_child_id == first_child_id and _last_fit_board_size == board_size:
		return
	_last_fit_viewport = viewport_size
	_last_fit_gap = gap
	_last_fit_first_child_id = first_child_id
	_last_fit_board_size = board_size
	var max_board_width := minf(maxf(320.0, viewport_size.x - 80.0), 920.0)
	var max_board_height := minf(maxf(360.0, viewport_size.y * BOARD_HEIGHT_RATIO), 1120.0)
	var calculated_width: float = floorf((max_board_width - 40.0 - gap_x * float(maxi(0, width - 1))) / float(width))
	var calculated_height: float = floorf((max_board_height - 40.0 - gap_y * float(maxi(0, height - 1))) / float(height))
	var cell_size := int(clampf(minf(calculated_width, calculated_height), 54.0, MAX_CELL_SIZE))
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
			if child.get_child_count() > 0 and child.get_child(0) is Control:
				(child.get_child(0) as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	var board_width := float(width * cell_size) + gap_x * float(maxi(0, width - 1)) + 40.0
	var board_height := float(height * cell_size) + gap_y * float(maxi(0, height - 1)) + 40.0
	board_panel.custom_minimum_size = Vector2(board_width, board_height)
