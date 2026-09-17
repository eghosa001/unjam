extends "res://scripts/game/rescue_rush_casual.gd"

# Hints are actions, not vague advice. PuzzleSolver returns the first move on a
# verified solution path, so activating Hint removes the correct arrow/key/etc.
func show_hint() -> void:
	if board_locked or rescued:
		return
	var index: int = PuzzleSolver.first_solution_move(level_data, pieces, 20000)
	if index < 0 or index >= pieces.size():
		hint_label.text = "No verified route from this position — Undo or Retry."
		FeedbackManager.blocked()
		return
	var piece: Dictionary = pieces[index]
	hints_used_this_level += 1
	SaveManager.record_hint()
	FeedbackManager.tap()
	AnalyticsManager.hint_used(level_number)
	var piece_type := String(piece.get("type", "normal"))
	var action_name := "arrow"
	match piece_type:
		"key": action_name = "key"
		"bomb": action_name = "bomb"
		"rotate": action_name = "rotate tile"
		"linked": action_name = "linked arrow"
		hint_label.text = "Best move: %s at row %d, column %d." % [action_name, int(piece.get("y", 0)) + 1, int(piece.get("x", 0)) + 1]
	_save_checkpoint()
	await try_move(index)
