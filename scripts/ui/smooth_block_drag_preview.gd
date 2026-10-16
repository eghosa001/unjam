extends "res://scripts/ui/block_drag_preview.gd"

func _process(delta: float) -> void:
	phase += delta
	if has_target:
		var delta_to_target := target_position - position
		# High-response exponential tracking: smooth without the rubber-band lag
		# that the previous 30x lerp produced on 60/90/120 Hz phones.
		# Small adjacent-cell moves ease into alignment in 1-3 frames, while
		# long distances bypass easing to avoid a rubber-band effect.
		# A small, fast ease makes the magnetic pull visible. Large pointer
		# jumps remain immediate so the ghost never trails the player's finger.
		var follow := 1.0 - exp(-delta * (80.0 if board_valid else 98.0))
		if delta_to_target.length() > maxf(60.0, board_cell_size * 1.65):
			follow = 1.0
		position = position.lerp(target_position, follow)
		if board_valid and delta_to_target.length() < 0.35:
			position = target_position
		var desired_rotation := 0.0 if board_valid else clampf(delta_to_target.x * 0.00018, -0.014, 0.014)
		rotation = lerpf(rotation, desired_rotation, 1.0 - exp(-delta * 24.0))
	else:
		rotation = lerpf(rotation, 0.0, 1.0 - exp(-delta * 24.0))
	scale = scale.lerp(target_scale, 1.0 - exp(-delta * 34.0))
	queue_redraw()
