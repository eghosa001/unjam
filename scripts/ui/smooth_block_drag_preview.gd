extends "res://scripts/ui/block_drag_preview.gd"

func set_drag_target(value: Vector2, valid := true) -> void:
	super.set_drag_target(value, valid)
	if valid:
		# The rendered green ghost and the legal highlighted cells must land
		# together on the very same input sample, not after an easing delay.
		position = value
		rotation = 0.0
		scale = Vector2.ONE
		target_scale = Vector2.ONE

func _process(delta: float) -> void:
	phase += delta
	if has_target:
		if board_valid:
			position = target_position
			rotation = 0.0
		else:
			# Only the free-floating invalid ghost may ease towards the touch.
			var delta_to_target := target_position - position
			var follow := 1.0 - exp(-delta * 98.0)
			if delta_to_target.length() > maxf(60.0, board_cell_size * 1.65):
				follow = 1.0
			position = position.lerp(target_position, follow)
			var desired_rotation := clampf(delta_to_target.x * 0.00018, -0.014, 0.014)
			rotation = lerpf(rotation, desired_rotation, 1.0 - exp(-delta * 24.0))
	else:
		rotation = lerpf(rotation, 0.0, 1.0 - exp(-delta * 24.0))
	scale = Vector2.ONE if board_valid else scale.lerp(target_scale, 1.0 - exp(-delta * 34.0))
	queue_redraw()
