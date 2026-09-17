extends "res://scripts/game/block_puzzle_3d.gd"

# Final competitive polish layer for the active Block Puzzle scene.
# Keep effects local to the board so the game feels stronger without adding
# full-screen flashes or permanent particle cost on Android.
const TENSION_THRESHOLD := 0.72
const TENSION_RELEASE_THRESHOLD := 0.60
const CLEAR_STREAK_WINDOW := 3.0

var _clear_streak := 0
var _clear_streak_generation := 0
var _tension_active := false

func load_level() -> void:
	_clear_streak = 0
	_clear_streak_generation += 1
	_tension_active = false
	super.load_level()
	_refresh_tension_feedback()

func render() -> void:
	super.render()
	_refresh_tension_feedback()

func _play_place_feedback(indices: Array[int], color: Color, points: int) -> void:
	super._play_place_feedback(indices, color, points)
	var impact_center := _cell_group_center(indices)
	if impact_center != Vector2.INF:
		# A compact burst makes the snap readable while remaining cheaper and safer
		# than a screen flash or a continuously-running effect layer.
		PremiumVisuals.burst(impact_center, color.lightened(0.08), mini(10, 4 + indices.size()))
	if score_label != null:
		MotionSystem.local_punch(score_label, 0.72)

func _spawn_clear_feedback(indices: Array[int], line_count: int) -> void:
	_clear_streak += 1
	_clear_streak_generation += 1
	var generation := _clear_streak_generation
	super._spawn_clear_feedback(indices, line_count)

	var clear_center := _cell_group_center(indices)
	if clear_center != Vector2.INF:
		PremiumVisuals.burst(clear_center, Color("ff7a66"), mini(28, 10 + line_count * 5))

	if _clear_streak >= 2:
		_spawn_score_popup("CLEAR STREAK ×%d" % _clear_streak, Color("ffd166"), 0.14, true)
		# Multi-line clears already emit their own combo beat in the parent layer;
		# avoid double-triggering it while still rewarding consecutive clear events.
		if line_count < 2:
			FeedbackManager.combo(_clear_streak)

	get_tree().create_timer(CLEAR_STREAK_WINDOW).timeout.connect(_expire_clear_streak.bind(generation))

func _expire_clear_streak(generation: int) -> void:
	if generation == _clear_streak_generation:
		_clear_streak = 0

func _refresh_tension_feedback() -> void:
	if completed or cells.is_empty():
		return
	var occupancy := _board_occupancy()
	if occupancy >= TENSION_THRESHOLD:
		if not _tension_active:
			_tension_active = true
			if board_shell != null:
				MotionSystem.local_punch(board_shell, 1.32)
			_spawn_tension_frame()
			_spawn_score_popup("TIGHT BOARD", Color("ffb347"), 0.0, true)
	elif occupancy <= TENSION_RELEASE_THRESHOLD:
		_tension_active = false

func _board_occupancy() -> float:
	var occupied := 0
	for row in cells:
		if not (row is Array):
			continue
		for value in row:
			if bool(value):
				occupied += 1
	return float(occupied) / float(GRID_SIZE * GRID_SIZE)

func _cell_group_center(indices: Array[int]) -> Vector2:
	var center := Vector2.ZERO
	var count := 0
	for idx in indices:
		if idx < 0 or idx >= cell_buttons.size():
			continue
		var cell := cell_buttons[idx] as Control
		if cell == null or not is_instance_valid(cell):
			continue
		center += cell.get_global_rect().get_center() - global_position
		count += 1
	if count <= 0:
		return Vector2.INF
	return center / float(count)

func _spawn_tension_frame() -> void:
	if effects_layer == null or board_shell == null:
		return
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = board_shell.global_position - global_position - Vector2(10, 10)
	frame.size = board_shell.size + Vector2(20, 20)
	frame.add_theme_stylebox_override("panel", style_box(Color("ff9f1c0a"), 30, Color("ffb347"), 4, 8))
	frame.modulate.a = 0.0
	effects_layer.add_child(frame)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate:a", 0.92, 0.08)
	tween.tween_property(frame, "modulate:a", 0.0, 0.34)
	tween.finished.connect(frame.queue_free)
