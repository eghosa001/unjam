extends "res://scripts/game/rescue_rush_casual.gd"

func can_show_hint() -> bool:
	if board_locked or rescued:
		return false
	var solution: Array[int] = PuzzleSolver.find_solution(level_data, pieces, 20000)
	return not solution.is_empty()

# Hints escalate instead of solving the puzzle immediately:
# 1) relevant region, 2) small candidate set, 3) exact solver move.
func show_hint() -> void:
	if board_locked or rescued:
		return
	var solution: Array[int] = PuzzleSolver.find_solution(level_data, pieces, 20000)
	if solution.is_empty():
		hint_label.text = "No verified route from this position — Undo or Retry."
		FeedbackManager.blocked()
		return
	hints_used_this_level += 1
	SaveManager.record_hint()
	FeedbackManager.tap()
	AnalyticsManager.hint_used(level_number)
	var index := int(solution[0])
	if index < 0 or index >= pieces.size():
		hint_label.text = "No verified move is available."
		return
	var stage := posmod(hints_used_this_level - 1, 3) + 1
	var piece: Dictionary = pieces[index]
	if stage == 1:
		hint_label.text = "Hint 1/3: inspect the %s area; the rescue-critical route starts there." % _hint_region(piece)
		_save_checkpoint()
		return
	if stage == 2:
		var candidates := _hint_candidates(index)
		hint_label.text = "Hint 2/3: compare %s. Trace each arrow all the way to the edge." % ", ".join(candidates)
		_save_checkpoint()
		return
	var piece_type := String(piece.get("type", "normal"))
	var action_name := "arrow"
	match piece_type:
		"key": action_name = "key"
		"bomb": action_name = "bomb"
		"rotate": action_name = "rotate tile"
		"linked": action_name = "linked arrow"
	hint_label.text = "Hint 3/3: %s at row %d, column %d." % [action_name.capitalize(), int(piece.get("y", 0)) + 1, int(piece.get("x", 0)) + 1]
	_save_checkpoint()
	await try_move(index)

func _hint_region(piece: Dictionary) -> String:
	var x := int(piece.get("x", 0))
	var y := int(piece.get("y", 0))
	var vertical := "upper" if y < int(height / 2) else "lower"
	var horizontal := "left" if x < int(width / 2) else "right"
	if absi(x - int(width / 2)) <= 1 and absi(y - int(height / 2)) <= 1:
		return "central"
	return "%s-%s" % [vertical, horizontal]

func _hint_candidates(solution_index: int) -> PackedStringArray:
	var result := PackedStringArray()
	result.append(_coordinate_label(solution_index))
	for i in range(pieces.size()):
		if result.size() >= 3:
			break
		if i == solution_index or not is_path_clear(i):
			continue
		result.append(_coordinate_label(i))
	return result

func _coordinate_label(index: int) -> String:
	if index < 0 or index >= pieces.size():
		return "?"
	var piece: Dictionary = pieces[index]
	return "R%d C%d" % [int(piece.get("y", 0)) + 1, int(piece.get("x", 0)) + 1]
