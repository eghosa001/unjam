extends "res://scripts/game/rescue_rush_casual.gd"

const PremiumGameplayFeedbackLayer = preload("res://scripts/ui/premium_gameplay_feedback.gd")
var premium_feedback: PremiumGameplayFeedback

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

func build_ui() -> void:
	super.build_ui()
	premium_feedback = PremiumGameplayFeedbackLayer.new()
	premium_feedback.name = "RescuePremiumFeedback"
	add_child(premium_feedback)

func _spawn_chain_popup(center: Vector2, combo: int) -> void:
	super._spawn_chain_popup(center, combo)
	if premium_feedback == null or not is_instance_valid(premium_feedback):
		return
	premium_feedback.show_ring(center, 72.0 + minf(28.0, float(combo) * 5.0), world_accent())
	if combo >= 2:
		premium_feedback.show_banner("FLOW ×%d" % combo, world_accent(), Vector2(center.x, maxf(188.0, center.y - 72.0)), 184.0)

func try_move(index: int) -> void:
	var legal := index >= 0 and index < pieces.size() and is_path_clear(index)
	await super.try_move(index)
	if not legal and premium_feedback != null and is_instance_valid(premium_feedback) and board_panel != null:
		var local_center: Vector2 = get_global_transform_with_canvas().affine_inverse() * board_panel.get_global_rect().get_center()
		premium_feedback.show_ring(local_center, minf(board_panel.size.x, board_panel.size.y) * 0.92, Color("#ff8d78"))
