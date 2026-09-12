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
	ambient_sparkles(18)
	set_process(true)

func _process(delta: float) -> void:
	ambient_time += delta
	for i in range(overlay.get_child_count()):
		var node := overlay.get_child(i)
		if node.has_meta("ambient"):
			var speed := float(node.get_meta("speed", 6.0))
			node.position.y -= speed * delta
			node.position.x += sin(ambient_time * 0.7 + float(i)) * 2.0 * delta
			if node.position.y < -40.0:
				node.position.y = 1960.0

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		call_deferred("premium_button", node)

func set_accent(color: Color) -> void:
	accent = color
	ambient_sparkles(18)

func ambient_sparkles(count: int = 14) -> void:
	clear_ambient()
	var rng := RandomNumberGenerator.new()
	rng.seed = 44321
	for i in range(count):
		var dot := ColorRect.new()
		var size := rng.randf_range(3.0, 8.0)
		dot.size = Vector2(size, size)
		dot.position = Vector2(rng.randf_range(20.0, 1060.0), rng.randf_range(40.0, 1880.0))
		dot.color = Color(accent, rng.randf_range(0.08, 0.24))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("ambient", true)
		dot.set_meta("speed", rng.randf_range(4.0, 16.0))
		overlay.add_child(dot)

func clear_ambient() -> void:
	for child in overlay.get_children():
		if child.has_meta("ambient"):
			child.queue_free()

func burst(global_pos: Vector2, color: Color = Color("2dd4b6"), count: int = 18) -> void:
	var rng := RandomNumberGenerator.new()
	for i in range(count):
		var p := ColorRect.new()
		p.size = Vector2(rng.randf_range(6.0, 14.0), rng.randf_range(6.0, 14.0))
		p.position = global_pos
		p.color = Color(color, 0.95)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(p)
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(90.0, 260.0)
		var target := global_pos + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween().set_parallel(true)
		tween.tween_property(p, "position", target, rng.randf_range(0.35, 0.65)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.55)
		tween.chain().tween_callback(p.queue_free)

func screen_flash(color: Color = Color("2dd4b6"), strength: float = 0.18) -> void:
	var flash := ColorRect.new()
	flash.color = Color(color, strength)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.28)
	tween.tween_callback(flash.queue_free)

func entrance(node: Control, delay: float = 0.0) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.96, 0.96)
	node.pivot_offset = node.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, 0.28).set_delay(delay)
	tween.tween_property(node, "scale", Vector2.ONE, 0.34).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func premium_button(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.has_meta("premium_motion"):
		return
	button.set_meta("premium_motion", true)
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(func():
		if not is_instance_valid(button): return
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(1.025, 1.025), 0.10)
	)
	button.mouse_exited.connect(func():
		if not is_instance_valid(button): return
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.10)
	)
	button.button_down.connect(func():
		if not is_instance_valid(button): return
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(0.97, 0.97), 0.05)
	)
	button.button_up.connect(func():
		if not is_instance_valid(button): return
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	)

func _on_premium_reward(reward: Dictionary) -> void:
	var achievements: Array = reward.get("achievements", [])
	if not achievements.is_empty():
		var first: Dictionary = achievements[0]
		show_reward_banner("ACHIEVEMENT UNLOCKED", "%s  •  +%d AP" % [String(first.get("title", "ACHIEVEMENT")), int(first.get("points", 0))], Color("f472b6"))
		burst(Vector2(540, 760), Color("f472b6"), 30)
		screen_flash(Color("f472b6"), 0.16)
		return
	if bool(reward.get("world_badge", false)):
		show_reward_banner("WORLD MASTERED", "Badge unlocked  •  +250 coins  •  +5 prestige", Color("ffd166"))
		burst(Vector2(540, 760), Color("ffd166"), 34)
		screen_flash(Color("ffd166"), 0.20)
	elif bool(reward.get("milestone", false)):
		show_reward_banner("MILESTONE CHEST", "+100 bonus coins", Color("7dd3fc"))
		burst(Vector2(540, 760), Color("7dd3fc"), 24)
	elif int(reward.get("perfect_streak", 0)) >= 5 and int(reward.get("perfect_streak", 0)) % 5 == 0:
		show_reward_banner("PERFECT STREAK ×%d" % int(reward.get("perfect_streak", 0)), "+50 coins  •  +1 prestige", Color("c084fc"))
		burst(Vector2(540, 760), Color("c084fc"), 22)
	elif bool(reward.get("perfect", false)):
		show_reward_banner("PERFECT CLEAR", "Three-star rescue", Color("2dd4b6"))

func show_reward_banner(title: String, subtitle: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(150, 210)
	panel.size = Vector2(780, 150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.11, 0.96)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = color
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 31)
	heading.add_theme_color_override("font_color", color)
	box.add_child(heading)
	var sub := Label.new()
	sub.text = subtitle
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 19)
	sub.modulate = Color("d6dfef")
	box.add_child(sub)
	panel.modulate.a = 0.0
	panel.position.y -= 30.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(panel, "position:y", 210.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(panel.queue_free)
