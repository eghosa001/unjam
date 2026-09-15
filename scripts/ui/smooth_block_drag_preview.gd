extends "res://scripts/ui/block_drag_preview.gd"

func _process(delta: float) -> void:
	phase += delta
	if has_target:
		var delta_to_target := target_position - position
		# High-response exponential tracking: smooth without the rubber-band lag
		# that the previous 30x lerp produced on 60/90/120 Hz phones.
		var follow := 1.0 - exp(-delta * 86.0)
		position = position.lerp(target_position, follow)
		var desired_rotation := clampf(delta_to_target.x * 0.00018, -0.014, 0.014)
		rotation = lerpf(rotation, desired_rotation, 1.0 - exp(-delta * 24.0))
	else:
		rotation = lerpf(rotation, 0.0, 1.0 - exp(-delta * 24.0))
	scale = scale.lerp(target_scale, 1.0 - exp(-delta * 34.0))
	queue_redraw()
