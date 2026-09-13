extends "res://scripts/game/water_sort.gd"

func pour(from_idx: int, to_idx: int) -> void:
	_spawn_pour_animation(from_idx, to_idx)
	super.pour(from_idx, to_idx)

func _spawn_pour_animation(from_idx: int, to_idx: int) -> void:
	if board == null or from_idx < 0 or to_idx < 0 or from_idx >= board.get_child_count() or to_idx >= board.get_child_count():
		return
	if tubes[from_idx].is_empty():
		return
	var source: Control = board.get_child(from_idx) as Control
	var target: Control = board.get_child(to_idx) as Control
	if source == null or target == null:
		return
	var color_index: int = clampi(int(tubes[from_idx].back()), 0, WaterTubeButton.PALETTE.size() - 1)
	var liquid: Color = WaterTubeButton.PALETTE[color_index]
	var start: Vector2 = source.get_global_rect().get_center() - global_position + Vector2(0, -source.size.y * 0.26)
	var finish: Vector2 = target.get_global_rect().get_center() - global_position + Vector2(0, -target.size.y * 0.24)
	var arc_height: float = maxf(120.0, absf(finish.x - start.x) * 0.20)
	var stream := Line2D.new()
	stream.width = 16.0
	stream.default_color = Color(liquid, 0.88)
	stream.z_index = 280
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(stream)
	var droplet := Panel.new()
	droplet.size = Vector2(28, 28)
	droplet.pivot_offset = droplet.size * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = liquid
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	droplet.add_theme_stylebox_override("panel", style)
	droplet.position = start - droplet.size * 0.5
	droplet.z_index = 290
	add_child(droplet)
	var tween := create_tween()
	for step in range(1, 13):
		var t: float = float(step) / 12.0
		var p: Vector2 = start.lerp(finish, t)
		p.y -= sin(t * PI) * arc_height
		tween.tween_property(droplet, "position", p - droplet.size * 0.5, 0.018)
		tween.tween_callback(func():
			if is_instance_valid(stream) and is_instance_valid(droplet):
				stream.clear_points()
				stream.add_point(start)
				stream.add_point(droplet.position + droplet.size * 0.5)
		)
	tween.tween_property(droplet, "scale", Vector2(1.45, 0.65), 0.05)
	tween.tween_property(droplet, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		if is_instance_valid(stream): stream.queue_free()
		if is_instance_valid(droplet): droplet.queue_free()
		PremiumVisuals.burst(finish, liquid, 7)
	)
