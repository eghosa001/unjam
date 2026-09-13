extends "res://scripts/game/game.gd"

func escape_piece(index: int, trigger_effect: bool) -> void:
	if index < 0 or index >= pieces.size() or not bool(pieces[index].get("active", true)):
		return
	if trigger_effect:
		_spawn_escape_visual(index)
	super.escape_piece(index, trigger_effect)

func _spawn_escape_visual(index: int) -> void:
	if board_grid == null or index < 0 or index >= pieces.size():
		return
	var piece: Dictionary = pieces[index]
	var pos := piece_position(piece)
	var grid_index := pos.y * width + pos.x
	if grid_index < 0 or grid_index >= board_grid.get_child_count():
		return
	var cell := board_grid.get_child(grid_index) as Control
	if cell == null:
		return
	var ghost := PremiumPieceButton.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.disabled = true
	ghost.size = cell.size
	ghost.custom_minimum_size = cell.size
	ghost.configure(String(piece.get("type", "normal")), String(piece.get("direction", "right")), piece_color(String(piece.get("type", "normal"))))
	ghost.global_position = cell.global_position
	ghost.z_index = 250
	add_child(ghost)
	ghost.global_position = cell.global_position
	ghost.pivot_offset = ghost.size * 0.5
	var dir: Vector2i = DIRECTIONS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var distance := maxf(get_viewport_rect().size.x, get_viewport_rect().size.y) + 360.0
	var target := ghost.position + Vector2(dir) * distance
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ghost, "position", target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost, "scale", Vector2(1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.16).set_delay(0.20)
	_spawn_speed_lines(cell.global_rect.get_center(), Vector2(dir), world_accent())
	tween.finished.connect(ghost.queue_free)

func _spawn_speed_lines(origin_global: Vector2, direction: Vector2, color: Color) -> void:
	var origin := origin_global - global_position
	for i in range(4):
		var line := Line2D.new()
		line.width = 5.0 - float(i) * 0.6
		line.default_color = Color(color, 0.55 - float(i) * 0.08)
		line.z_index = 220
		var perpendicular := Vector2(-direction.y, direction.x)
		var offset := perpendicular * (float(i) - 1.5) * 14.0
		line.add_point(origin + offset - direction * 12.0)
		line.add_point(origin + offset - direction * (90.0 + float(i) * 18.0))
		add_child(line)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(line, "modulate:a", 0.0, 0.22)
		tw.tween_property(line, "position", direction * 52.0, 0.22)
		tw.finished.connect(line.queue_free)
