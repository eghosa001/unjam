extends "res://scripts/game/game.gd"

const RescueEscapePiece3D = preload("res://scripts/ui/rescue_piece_3d_button.gd")

# Authoritative board state resolves first; visual ghosts are tracked separately.
# Completion waits for the actual final escape tween instead of guessing with a timer.
var _active_escape_visuals: Array[Node] = []
var _speed_line_pool: Array[Line2D] = []
var _effect_label_pool: Array[Label] = []
const MAX_SPEED_LINE_POOL := 12
const MAX_EFFECT_LABEL_POOL := 8

func escape_piece(index: int, trigger_effect: bool) -> void:
	if index < 0 or index >= pieces.size() or not bool(pieces[index].get("active", true)):
		return
	if trigger_effect:
		var route := _escape_route_cells(index)
		_spawn_escape_visual(index, route)
	super.escape_piece(index, trigger_effect)

func _escape_route_cells(index: int) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	if index < 0 or index >= pieces.size():
		return route
	var piece: Dictionary = pieces[index]
	if not bool(piece.get("active", true)):
		return route
	var direction: Vector2i = DIRECTIONS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var cursor := piece_position(piece)
	route.append(cursor)
	cursor += direction
	while is_inside(cursor):
		route.append(cursor)
		cursor += direction
	# Keep the first cell beyond the board in the command so the visual route has
	# an explicit exit, not a frame-by-frame collision guess.
	route.append(cursor)
	return route

func _route_from(start: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var route: Array[Vector2i] = [start]
	var cursor := start + direction
	while is_inside(cursor):
		route.append(cursor)
		cursor += direction
	route.append(cursor)
	return route

func _board_cell_local_position(pos: Vector2i, fallback: Vector2) -> Vector2:
	if board_grid == null or not is_inside(pos):
		return fallback
	var child_index := pos.y * width + pos.x
	if child_index < 0 or child_index >= board_grid.get_child_count():
		return fallback
	var cell := board_grid.get_child(child_index) as Control
	if cell == null:
		return fallback
	return cell.global_position - global_position

func _offscreen_target(start: Vector2, direction: Vector2, lane_offset: float = 0.0) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var distance := maxf(viewport_size.x, viewport_size.y) + 420.0
	var normal := Vector2(-direction.y, direction.x)
	return start + direction * distance + normal * lane_offset

func _track_escape_visual(node: Node) -> void:
	if node != null and is_instance_valid(node):
		_active_escape_visuals.append(node)

func _finish_escape_visual(node: Variant) -> void:
	_active_escape_visuals.erase(node)
	if node != null and is_instance_valid(node):
		node.queue_free()

func _wait_for_escape_visuals() -> void:
	while not _active_escape_visuals.is_empty():
		# Android Back may detach the active game immediately while completion is
		# waiting for an escape tween. Treat leaving the SceneTree as cancellation
		# instead of trying to await another frame through a null tree.
		if not is_inside_tree():
			return
		for node in _active_escape_visuals.duplicate():
			if node == null or not is_instance_valid(node):
				_active_escape_visuals.erase(node)
		if _active_escape_visuals.is_empty():
			return
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
		if not is_inside_tree():
			return

func _spawn_escape_visual(index: int, route: Array[Vector2i] = []) -> void:
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
	if route.is_empty():
		route = _escape_route_cells(index)
	var ghost := RescueEscapePiece3D.new()
	ghost.name = "RescueEscapeGhost"
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.disabled = true
	ghost.size = cell.size
	ghost.custom_minimum_size = cell.size
	ghost.configure(String(piece.get("type", "normal")), String(piece.get("direction", "right")), piece_color(String(piece.get("type", "normal"))))
	ghost.global_position = cell.global_position
	ghost.z_index = 520 + mini(chain_count, 20)
	add_child(ghost)
	ghost.global_position = cell.global_position
	ghost.pivot_offset = ghost.size * 0.5
	_track_escape_visual(ghost)

	var dir_i: Vector2i = DIRECTIONS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var direction := Vector2(dir_i)
	var start_pos := ghost.position
	var center: Vector2 = cell.get_global_rect().get_center() - global_position
	PremiumVisuals.burst(center, world_accent(), 7 + mini(chain_count, 8))
	_spawn_chain_popup(center, chain_count)
	_spawn_speed_lines(cell.get_global_rect().get_center(), direction, world_accent())

	var tween := create_tween()
	tween.tween_property(ghost, "position", start_pos - direction * 11.0, MotionSystem.duration(&"micro") * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.94, 0.94), MotionSystem.duration(&"micro") * 0.55)
	tween.tween_property(ghost, "position", start_pos + direction * 30.0, MotionSystem.duration(&"micro") * 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(1.10, 1.10), MotionSystem.duration(&"micro") * 0.72)

	var inside_steps := maxi(1, route.size() - 2)
	var step_time := maxf(0.035, MotionSystem.duration(&"travel") * 0.54 / float(inside_steps))
	for route_index in range(1, route.size() - 1):
		var route_cell: Vector2i = route[route_index]
		var target := _board_cell_local_position(route_cell, ghost.position)
		tween.tween_property(ghost, "position", target, step_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	var lane_offset := sin(float(pos.x + pos.y)) * 18.0
	var final_target := _offscreen_target(start_pos, direction, lane_offset)
	var exit_time := maxf(0.16, MotionSystem.duration(&"travel") * 0.72)
	tween.tween_property(ghost, "position", final_target, exit_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.78, 0.78), exit_time)
	tween.parallel().tween_property(ghost, "rotation", deg_to_rad(8.0 if direction.x + direction.y > 0.0 else -8.0), exit_time)
	tween.finished.connect(_finish_escape_visual.bind(ghost))

func _acquire_speed_line() -> Line2D:
	var line: Line2D
	if not _speed_line_pool.is_empty():
		line = _speed_line_pool.pop_back()
	else:
		line = Line2D.new()
		line.z_index = 220
		add_child(line)
	line.visible = true
	line.position = Vector2.ZERO
	line.modulate = Color.WHITE
	line.points = PackedVector2Array()
	return line

func _release_speed_line(value: Variant) -> void:
	if value == null or not is_instance_valid(value) or not value is Line2D:
		return
	var line := value as Line2D
	line.visible = false
	line.position = Vector2.ZERO
	line.modulate = Color.WHITE
	line.points = PackedVector2Array()
	if _speed_line_pool.size() < MAX_SPEED_LINE_POOL:
		_speed_line_pool.append(line)
	else:
		line.queue_free()

func _acquire_effect_label() -> Label:
	var label: Label
	if not _effect_label_pool.is_empty():
		label = _effect_label_pool.pop_back()
	else:
		label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	label.visible = true
	label.position = Vector2.ZERO
	label.scale = Vector2.ONE
	label.rotation = 0.0
	label.modulate = Color.WHITE
	return label

func _release_effect_label(value: Variant) -> void:
	if value == null or not is_instance_valid(value) or not value is Label:
		return
	var label := value as Label
	label.visible = false
	label.position = Vector2.ZERO
	label.scale = Vector2.ONE
	label.rotation = 0.0
	label.modulate = Color.WHITE
	if _effect_label_pool.size() < MAX_EFFECT_LABEL_POOL:
		_effect_label_pool.append(label)
	else:
		label.queue_free()

func _spawn_speed_lines(origin_global: Vector2, direction: Vector2, color: Color) -> void:
	var origin := origin_global - global_position
	var perpendicular := Vector2(-direction.y, direction.x)
	for i in range(4):
		var line := _acquire_speed_line()
		line.width = 5.0 - float(i) * 0.6
		line.default_color = Color(color, 0.55 - float(i) * 0.08)
		var offset := perpendicular * (float(i) - 1.5) * 14.0
		line.points = PackedVector2Array([
			origin + offset - direction * 12.0,
			origin + offset - direction * (90.0 + float(i) * 18.0)
		])
		var tw := create_tween().set_parallel(true)
		tw.tween_property(line, "modulate:a", 0.0, 0.22)
		tw.tween_property(line, "position", direction * 52.0, 0.22)
		tw.finished.connect(_release_speed_line.bind(line))

func _spawn_chain_popup(center: Vector2, combo: int) -> void:
	var label := _acquire_effect_label()
	label.text = "ESCAPE!" if combo <= 1 else "CHAIN ×%d" % combo
	label.position = center - Vector2(145, 54)
	label.size = Vector2(290, 76)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 610
	label.add_theme_font_size_override("font_size", 34 if combo <= 1 else 40)
	label.add_theme_color_override("font_color", Color("ffd166") if combo > 1 else world_accent().lightened(0.35))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.scale = Vector2(0.68, 0.68)
	label.modulate.a = 0.0
	label.pivot_offset = label.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(label, "scale", Vector2(1.16, 1.16), 0.11)
	tween.tween_property(label, "scale", Vector2.ONE, 0.09)
	tween.tween_property(label, "position:y", label.position.y - 82.0, 0.30).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.30)
	tween.finished.connect(_release_effect_label.bind(label))

func _spawn_vanish_visual(index: int, text_value: String) -> void:
	if index < 0 or index >= pieces.size() or board_grid == null:
		return
	var piece := pieces[index]
	var pos := piece_position(piece)
	var child_index := pos.y * width + pos.x
	if child_index < 0 or child_index >= board_grid.get_child_count():
		return
	var source := board_grid.get_child(child_index) as Control
	if source == null:
		return
	var center := source.global_position - global_position + source.size * 0.5
	PremiumVisuals.burst(center, piece_color(String(piece.get("type", "normal"))), 10)
	var label := _acquire_effect_label()
	label.text = text_value
	label.position = center - Vector2(105, 32)
	label.size = Vector2(210, 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color("ffffff"))
	label.z_index = 600
	label.pivot_offset = label.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.10)
	tween.tween_property(label, "position:y", label.position.y - 54.0, 0.24)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.24)
	tween.finished.connect(_release_effect_label.bind(label))

func open_gates(key_id: String) -> void:
	for i in range(pieces.size()):
		if bool(pieces[i].get("active", true)) and String(pieces[i].get("type", "")) == "gate" and String(pieces[i].get("key_id", "default")) == key_id:
			_spawn_vanish_visual(i, "UNLOCK!")
			pieces[i]["active"] = false
			chain_count += 1

func explode_at(center: Vector2i) -> void:
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 1, center.x + 2):
			var idx: int = get_piece_index_at(Vector2i(x, y))
			if idx >= 0 and String(pieces[idx].get("type", "")) not in ["gate", "blocker"]:
				_spawn_vanish_visual(idx, "BOOM!")
				pieces[idx]["active"] = false
				chain_count += 1

func activate_link(link_id: String, source_index: int) -> void:
	if link_id.is_empty():
		return
	for i in range(pieces.size()):
		if i == source_index or not bool(pieces[i].get("active", true)):
			continue
		if String(pieces[i].get("type", "")) == "linked" and String(pieces[i].get("link_id", "")) == link_id:
			if is_path_clear(i):
				_spawn_vanish_visual(i, "LINK!")
				pieces[i]["active"] = false
			else:
				pieces[i]["direction"] = rotate_direction(String(pieces[i].get("direction", "right")))
			chain_count += 1

func resolve_rescue() -> void:
	if not _objective_satisfied():
		return
	_spawn_rescue_escape()
	rescued = true
	chain_count += 1
	best_chain = maxi(best_chain, chain_count)
	FeedbackManager.rescue()
	PremiumVisuals.burst(Vector2(540, 860), world_accent(), 28)
	# Do not use a full-screen flash here. The local celebration keeps the finish
	# readable without producing bright edge flashes during the transition.
	render_board()
	await _wait_for_escape_visuals()
	complete_level()

func _rescue_exit_direction() -> Vector2i:
	for direction_i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var pos: Vector2i = rescue_pos + direction_i
		var blocked := false
		while is_inside(pos):
			if get_piece_index_at(pos) >= 0:
				blocked = true
				break
			pos += direction_i
		if not blocked:
			return direction_i
	return Vector2i.ZERO

func _spawn_rescue_escape() -> void:
	var rescue_visual := _current_rescue_visual()
	if rescue_visual == null:
		return
	var direction_i := _rescue_exit_direction()
	if direction_i == Vector2i.ZERO:
		return
	var direction := Vector2(direction_i)
	var ghost: Control = _clone_rescue_visual(rescue_visual)
	if ghost == null:
		return
	add_child(ghost)
	ghost.global_position = rescue_visual.global_position
	ghost.size = rescue_visual.size
	ghost.pivot_offset = ghost.size * 0.5
	ghost.z_index = 650
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track_escape_visual(ghost)
	rescue_visual.visible = false
	rescue_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var start := ghost.position
	var center := ghost.global_position - global_position + ghost.size * 0.5
	_spawn_speed_lines(ghost.global_position + ghost.size * 0.5, direction, Color("ffd166"))
	PremiumVisuals.burst(center, Color("ffd166"), 18)
	var tween := create_tween()
	tween.tween_property(ghost, "scale", Vector2(1.16, 0.88), MotionSystem.duration(&"micro")).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var final_target := _offscreen_target(start, direction)
	var travel_time := maxf(0.22, MotionSystem.duration(&"travel") * 0.88)
	tween.tween_property(ghost, "position", final_target, travel_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.78, 0.78), travel_time)
	tween.finished.connect(_finish_escape_visual.bind(ghost))

func _current_rescue_visual() -> Control:
	if board_grid == null or not is_inside(rescue_pos):
		return null
	var child_index := rescue_pos.y * width + rescue_pos.x
	if child_index < 0 or child_index >= board_grid.get_child_count():
		return null
	var slot := board_grid.get_child(child_index)
	if slot == null or slot.get_child_count() == 0:
		return null
	var visual := slot.get_child(0)
	if visual is Control:
		return visual as Control
	return null

func _clone_rescue_visual(source: Control) -> Control:
	if source == null or not is_instance_valid(source):
		return null
	var ghost := source.duplicate()
	if ghost is Control:
		return ghost as Control
	return null
