extends "res://scripts/game/rescue_rush_casual.gd"

func can_show_hint() -> bool:
	if board_locked or rescued:
		return false
	var solution: Array[int] = PuzzleSolver.find_solution(level_data, pieces, 20000)
	return not solution.is_empty()

func show_hint() -> void:
	if not can_show_hint():
		if hint_label != null:
			hint_label.text = "No removable arrow is available — Undo or Retry."
		FeedbackManager.blocked()
		return
	# A Rescue hint is a direct assist, not tutorial copy: remove one verified
	# useful arrow while preserving the player's move count.
	await super.show_hint()
