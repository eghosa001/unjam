extends "res://scripts/game/water_sort_reference_motion.gd"

# Return the point on the visible bottle lip, not the nominal centre point.
# When a source bottle tilts, the stream must leave from the downhill rim.
func _visual_mouth_local(control: Control) -> Vector2:
	var outer_x := control.size.x * 0.18
	var outer_y := 13.0
	var outer_w := control.size.x * 0.64
	var outer_h := control.size.y - 42.0
	var neck_h := outer_h * 0.10
	var lip_y := outer_y + neck_h * 0.28 + 1.0
	if control.rotation > 0.08:
		return Vector2(outer_x + outer_w * 0.92, lip_y)
	if control.rotation < -0.08:
		return Vector2(outer_x + outer_w * 0.08, lip_y)
	return Vector2(outer_x + outer_w * 0.5, lip_y)

func _control_point(control: Control, local_point: Vector2) -> Vector2:
	var adjusted := local_point
	# The parent animation asks for a point around y=30 for both source and
	# receiver. Replace only that mouth probe; other control-point requests stay intact.
	if local_point.y <= 42.0 and absf(local_point.x - control.size.x * 0.5) <= control.size.x * 0.18:
		adjusted = _visual_mouth_local(control)
	return super._control_point(control, adjusted)
