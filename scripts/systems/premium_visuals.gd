extends Node

var layer: CanvasLayer
var overlay: Control
var ambient_time := 0.0
var accent := Color("2dd4b6")

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	get_tree().node_added.connect(_on_node_added)
	if SaveManager.has_signal("premium_reward"):
		SaveManager.premium_reward.connect(_on_premium_reward)
	apply_motion_preference()

func _reduced_motion() -> bool:
	return MotionSystem.reduced()

func apply_motion_preference() -> void:
	set_process(not _reduced_motion())
	if is_instance_valid(overlay):
		if _reduced_motion():
			clear_ambient()
		else:
			ambient_sparkles(12)
	if get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("reduced_motion_aware"):
		if node != self and is_instance_valid(node) and node.has_method("apply_motion_preference"):
			node.call("apply_motion_preference")

func _process(delta: float) -> void:
	if _reduced_motion():
		return
	ambient_time += delta
	for i in range(overlay.get_child_count()):
		var node := overlay.get_child(i)
		if node.has_meta("ambient"):
			var speed := float(node.get_meta("speed", 6.0))
			node.position.y -= speed * delta
			node.position.x += sin(ambient_time * 0.45 + float(i)) * 2.2 * delta
			if node.position.y < -40.0:
				node.position.y = 1960.0

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		call_deferred("premium_button", node)

func set_accent(color: Color) -> void:
	accent = color
	ambient_sparkles(14)

func _diamond(radius: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(0, -radius), Vector2(radius * 0.72, 0), Vector2(0, radius), Vector2(-radius * 0.72, 0)])
	p.color = color
	return p

func ambient_sparkles(count: int = 12) -> void:
	clear_ambient()
	if _reduced_motion() or not is_instance_valid(overlay):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 44321
	for _i in range(count):
		var radius := rng.randf_range(1.8, 4.5)
		var dot := _diamond(radius, Color(accent.lightened(0.20), rng.randf_range(0.05, 0.16)))
		dot.position = Vector2(rng.randf_range(20.0, 1060.0), rng.randf_range(40.0, 1880.0))
		dot.rotation = rng.randf_range(0.0, TAU)
		dot.set_meta("ambient", true)
		dot.set_meta("speed", rng.randf_range(3.0, 10.0))
		overlay.add_child(dot)

func clear_ambient() -> void:
	if not is_instance_valid(overlay):
		return
	for child in overlay.get_children():
		if child.has_meta("ambient"):
			child.queue_free()

func burst(global_pos: Vector2, color: Color = Color("2dd4b6"), count: int = 18) -> void:
	if _reduced_motion() or not is_instance_valid(overlay):
		return
	var rng := RandomNumberGenerator.new()
	for _i in range(count):
		var radius := rng.randf_range(3.0, 8.0)
		var particle := _diamond(radius, Color(color.lightened(rng.randf_range(0.0, 0.28)), 0.92))
		particle.position = global_pos
		particle.rotation = rng.randf_range(0.0, TAU)
		overlay.add_child(particle)
		var angle := rng.randf_range(-PI * 0.95, -0.05)
		if _i % 3 == 0:
			angle = rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(80.0, 245.0)
		var target := global_pos + Vector2(cos(angle), sin(angle)) * distance + Vector2(0, rng.randf_range(20.0, 90.0))
		var duration := rng.randf_range(0.42, 0.72)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(particle, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "rotation", particle.rotation + rng.randf_range(-3.5, 3.5), duration)
		tween.tween_property(particle, "scale", Vector2(0.25, 0.25), duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration).set_delay(duration * 0.34)
		tween.chain().tween_callback(particle.queue_free)

func screen_flash(color: Color = Color("2dd4b6"), strength: float = 0.18) -> void:
	if _reduced_motion() or not is_instance_valid(overlay):
		return
	# Keep celebration energy away from the display edges. A centered radial
	# pulse reads as impact without producing the harsh full-screen flash that
	# was visible during navigation/results on bright mobile displays.
	var viewport_rect := get_viewport().get_visible_rect()
	var radius := minf(viewport_rect.size.x, viewport_rect.size.y) * 0.22
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	var pulse := Polygon2D.new()
	pulse.polygon = points
	pulse.color = Color(color.lightened(0.18), minf(strength, 0.09))
	pulse.position = viewport_rect.position + viewport_rect.size * 0.5
	pulse.scale = Vector2(0.72, 0.72)
	overlay.add_child(pulse)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "scale", Vector2(1.18, 1.18), 0.18)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(pulse.queue_free)

func entrance(node: Control, delay: float = 0.0) -> void:
	if not is_instance_valid(node):
		return
	if _reduced_motion():
		return
	var final_alpha := node.modulate.a
	node.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", final_alpha, 0.14).set_delay(delay)

func premium_button(button: Variant) -> void:
	if not is_instance_valid(button) or not button is BaseButton:
		return
	var target := button as BaseButton
	if target.has_meta("premium_motion"):
		return
	target.set_meta("premium_motion", true)
	target.focus_mode = Control.FOCUS_NONE
	target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	target.scale = Vector2.ONE
	target.mouse_entered.connect(func():
		if is_instance_valid(target) and not target.disabled:
			target.self_modulate = Color(0.985, 0.985, 0.985, 1.0)
	)
	target.mouse_exited.connect(func():
		if is_instance_valid(target):
			target.self_modulate = Color.WHITE
	)
	target.button_down.connect(func():
		if is_instance_valid(target) and not target.disabled:
			target.self_modulate = Color(0.94, 0.94, 0.94, 1.0)
	)
	target.button_up.connect(func():
		if is_instance_valid(target):
			target.self_modulate = Color.WHITE
	)

func show_combo(text_value: String, global_pos: Vector2, color: Color = Color("ffd166")) -> void:
	if _reduced_motion() or not is_instance_valid(overlay):
		return
	var label := Label.new()
	label.text = text_value
	label.position = global_pos - Vector2(170, 40)
	label.size = Vector2(340, 80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_y", 5)
	label.scale = Vector2(0.68, 0.68)
	label.pivot_offset = label.size * 0.5
	overlay.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.10, 1.10), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.10)
	tween.tween_interval(0.28)
	tween.parallel().tween_property(label, "position:y", label.position.y - 46.0, 0.28)
	tween.tween_property(label, "modulate:a", 0.0, 0.20)
	tween.tween_callback(label.queue_free)

func _on_premium_reward(reward: Dictionary) -> void:
	var achievements: Array = reward.get("achievements", [])
	if not achievements.is_empty():
		var first: Dictionary = achievements[0]
		show_reward_banner("ACHIEVEMENT UNLOCKED", "%s  •  +%d AP" % [String(first.get("title", "ACHIEVEMENT")), int(first.get("points", 0))], Color("f472b6"))
		burst(Vector2(540, 760), Color("f472b6"), 30)
		screen_flash(Color("f472b6"), 0.14)
		return
	if bool(reward.get("world_badge", false)):
		show_reward_banner("WORLD MASTERED", "Badge unlocked  •  +250 coins  •  +5 prestige", Color("ffd166"))
		burst(Vector2(540, 760), Color("ffd166"), 34)
		screen_flash(Color("ffd166"), 0.16)
	elif bool(reward.get("milestone", false)):
		show_reward_banner("MILESTONE CHEST", "+100 bonus coins", Color("7dd3fc"))
		burst(Vector2(540, 760), Color("7dd3fc"), 24)
	elif int(reward.get("perfect_streak", 0)) >= 5 and int(reward.get("perfect_streak", 0)) % 5 == 0:
		show_reward_banner("PERFECT STREAK ×%d" % int(reward.get("perfect_streak", 0)), "+50 coins  •  +1 prestige", Color("c084fc"))
		burst(Vector2(540, 760), Color("c084fc"), 22)
	elif bool(reward.get("perfect", false)):
		show_reward_banner("PERFECT CLEAR", "Three-star clear", Color("2dd4b6"))

func show_reward_banner(title: String, subtitle: String, color: Color) -> void:
	if not is_instance_valid(overlay):
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(160, 180)
	panel.size = Vector2(760, 142)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0a1423e8")
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(color, 0.82)
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 29)
	heading.add_theme_color_override("font_color", color)
	box.add_child(heading)
	var sub := Label.new()
	sub.text = subtitle
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color("d8e2ef"))
	box.add_child(sub)
	if _reduced_motion():
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
		get_tree().create_timer(1.65).timeout.connect(func():
			if is_instance_valid(panel):
				panel.queue_free()
		)
		return
	panel.modulate.a = 0.0
	panel.position.y -= 28.0
	panel.scale = Vector2(0.96, 0.96)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "position:y", 180.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(1.65)
	tween.tween_property(panel, "modulate:a", 0.0, 0.22)
	tween.tween_callback(panel.queue_free)

func tactile_success(node: Control, color: Color = Color("2dd4b6")) -> void:
	if node == null or not is_instance_valid(node) or _reduced_motion():
		return
	node.pivot_offset = node.size * 0.5
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.025, 0.985), 0.055)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12)
	burst(node.global_position + node.size * 0.5, color, 5)

func tactile_invalid(node: Control) -> void:
	if node == null or not is_instance_valid(node) or _reduced_motion():
		return
	var base := node.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	for dx in [5.0, -5.0, 3.0, -3.0, 0.0]:
		tw.tween_property(node, "position", base + Vector2(dx, 0), 0.028)

func transition_cover(color: Color, duration: float = 0.16) -> void:
	if _reduced_motion() or not is_instance_valid(overlay):
		return
	var veil := ColorRect.new()
	veil.color = Color(color.darkened(0.55), 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(veil)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(veil, "color:a", 0.16, duration * 0.45)
	tw.tween_property(veil, "color:a", 0.0, duration * 0.55)
	tw.tween_callback(veil.queue_free)
