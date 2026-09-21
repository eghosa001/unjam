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
	call_deferred("_show_level_intro")

func _show_level_intro() -> void:
	if daily_mode or premium_feedback == null or not is_instance_valid(premium_feedback):
		return
	var milestone := String(level_data.get("milestone", "normal"))
	var role := String(level_data.get("level_role", "standard"))
	if milestone == "normal" and role not in ["world_boss", "boss"]:
		return
	var label := ("WORLD BOSS" if role == "world_boss" else milestone.replace("_", " ").to_upper())
	var center := _level_intro_banner_center()
	premium_feedback.show_banner(label, Color("#ffd166"), center, 176.0)

func _level_intro_banner_center() -> Vector2:
	var view := get_viewport_rect().size
	if board_panel == null or not is_instance_valid(board_panel):
		return Vector2(view.x * 0.5, view.y * 0.66)
	var inverse := get_global_transform_with_canvas().affine_inverse()
	var board_bottom_local: Vector2 = inverse * board_panel.get_global_rect().end
	# Rescue has a deliberate breathing zone below the board and above the
	# action buttons. Put milestone feedback there so it never masks an arrow.
	var y := minf(view.y - 150.0, board_bottom_local.y + 54.0)
	return Vector2(view.x * 0.5, y)

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
		var inverse := get_global_transform_with_canvas().affine_inverse()
		var global_rect := board_panel.get_global_rect()
		var local_top_left: Vector2 = inverse * global_rect.position
		var local_bottom_right: Vector2 = inverse * global_rect.end
		var local_center := (local_top_left + local_bottom_right) * 0.5
		var local_size := Vector2(absf(local_bottom_right.x - local_top_left.x), absf(local_bottom_right.y - local_top_left.y))
		premium_feedback.show_ring(local_center, minf(local_size.x, local_size.y) * 0.92, Color("#ff8d78"))
