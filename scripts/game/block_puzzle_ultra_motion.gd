extends "res://scripts/game/block_puzzle_premium_layout.gd"

# Active Block Puzzle motion/interaction layer. Keep screen roots fixed and
# concentrate impact on the board/pieces so fast play never feels like a flash
# or whole-screen vibration.
const SmoothPieceButton = preload("res://scripts/ui/smooth_block_piece_button.gd")
const PLACEMENT_HELP := "Release when the placement preview locks into place"

func build_ui() -> void:
	super.build_ui()
	_patch_game_first_layout()

func load_level() -> void:
	super.load_level()
	if hint_label != null:
		hint_label.text = PLACEMENT_HELP

func select_piece(index: int) -> void:
	super.select_piece(index)
	if not completed and index >= 0 and index < pieces.size() and not pieces[index].is_empty():
		FeedbackManager.lift()
		hint_label.text = PLACEMENT_HELP

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := SmoothPieceButton.new()
		button.custom_minimum_size = Vector2(270, 150)
		button.configure(pieces[i], i == selected_piece, piece_colors[i], i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func _play_place_feedback(indices: Array[int], color: Color, points: int) -> void:
	FeedbackManager.drop()
	var stagger := MotionSystem.duration(&"micro") * 0.25
	for i in range(indices.size()):
		var idx := indices[i]
		if idx >= 0 and idx < cell_buttons.size():
			cell_buttons[idx].play_land(stagger * float(i))
	_spawn_score_popup("+%d" % points, color.lightened(0.15), 0.0)
	if board_shell != null:
		MotionSystem.local_punch(board_shell, 1.0)

func _invalid_bump() -> void:
	FeedbackManager.invalid()
	if board_shell == null or MotionSystem.reduced():
		return
	var base_x := board_shell.position.x
	var beat := MotionSystem.duration(&"micro")
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(board_shell, "position:x", base_x - 10.0, beat * 0.55)
	tween.tween_property(board_shell, "position:x", base_x + 8.0, beat * 0.65)
	tween.tween_property(board_shell, "position:x", base_x - 4.0, beat * 0.50)
	tween.tween_property(board_shell, "position:x", base_x, beat * 0.50)

func _spawn_clear_feedback(indices: Array[int], line_count: int) -> void:
	# Preserve the proven clear/debris rendering while standardizing its semantic
	# audio/haptic beat and local board impact through the shared motion system.
	FeedbackManager.line_clear(line_count)
	if line_count >= 2:
		FeedbackManager.combo(line_count)
	super._spawn_clear_feedback(indices, line_count)
	if board_shell != null:
		MotionSystem.local_punch(board_shell, clampf(float(line_count), 1.0, 2.4))

func complete_level() -> void:
	if completed:
		return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if placements <= par_placements else (2 if placements <= par_placements + 6 else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 30)
	status_label.text = "BOARD MASTERED"
	_spawn_score_popup("SPECTACULAR!", Color("ff665e"), 0.0, true)
	FeedbackManager.complete()
	AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	var completion_hold := MotionSystem.duration(&"celebrate") + MotionSystem.duration(&"settle")
	await get_tree().create_timer(completion_hold).timeout
	var result := PremiumResultOverlay.new()
	result.configure(
		"BLOCK PUZZLE COMPLETE",
		"Strong placements. Clean lines. Space controlled.",
		"SCORE %d   •   %d LINES\n%d PLACEMENTS   •   PERFECT ≤ %d" % [score, lines_cleared, placements, par_placements],
		stars,
		Color("8b7cf6"),
		"BACK HOME" if daily_mode else "NEXT PUZZLE"
	)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)

func _patch_game_first_layout() -> void:
	for node in _descendants(self):
		if node is PanelContainer:
			var panel := node as PanelContainer
			if _contains_label(panel, "SCORE") or _contains_label(panel, "TARGET"):
				panel.custom_minimum_size.y = minf(panel.custom_minimum_size.y, 92.0)
			elif _contains_label(panel, "DRAG A BLOCK"):
				panel.custom_minimum_size.y = 196.0
			elif _contains_label(panel, "RUN PROGRESS"):
				panel.visible = false
				panel.custom_minimum_size = Vector2.ZERO
		elif node is CenterContainer:
			var center := node as CenterContainer
			if _contains_grid(center):
				center.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _contains_label(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.to_upper().contains(needle):
		return true
	for child in root.get_children():
		if _contains_label(child, needle):
			return true
	return false

func _contains_grid(root: Node) -> bool:
	if root is GridContainer:
		return true
	for child in root.get_children():
		if _contains_grid(child):
			return true
	return false

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result
