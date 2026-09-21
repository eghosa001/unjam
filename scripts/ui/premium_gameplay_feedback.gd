extends Control
class_name PremiumGameplayFeedback

var _active_banner: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 780

func _visual_scale() -> float:
	# Effects are authored against the 540-wide QA viewport while gameplay uses
	# a fixed higher logical resolution. Scale the effect, not the gameplay.
	return clampf(size.x / 540.0, 1.0, 2.5)

func show_banner(text_value: String, accent: Color, center: Vector2, width: float = 214.0) -> void:
	if text_value.is_empty():
		return
	# Level-intro milestone banners use the compact 176px treatment. Keep those
	# out of live puzzle cells: Block already carries milestone identity in its
	# persistent footer, while Rescue has a clear non-interactive gap below board.
	var viewport_size := get_viewport_rect().size
	var is_intro_banner := is_equal_approx(width, 176.0) and center.y <= viewport_size.y * 0.30
	if is_intro_banner and name == "BlockPremiumFeedback":
		return
	if is_intro_banner and name == "RescuePremiumFeedback":
		center.y = viewport_size.y * 0.68
	var visual_scale := _visual_scale()
	var banner_width := width * visual_scale
	var banner_height := 46.0 * visual_scale
	if _active_banner != null and is_instance_valid(_active_banner):
		_active_banner.queue_free()
	var panel := PanelContainer.new()
	panel.name = "PremiumGameplayBanner"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.darkened(0.52), 0.94)
	style.border_color = Color(accent.lightened(0.30), 0.92)
	style.border_width_left = maxi(2, int(round(2.0 * visual_scale)))
	style.border_width_right = maxi(2, int(round(2.0 * visual_scale)))
	style.border_width_top = maxi(2, int(round(2.0 * visual_scale)))
	style.border_width_bottom = maxi(2, int(round(2.0 * visual_scale)))
	style.corner_radius_top_left = int(round(18.0 * visual_scale))
	style.corner_radius_top_right = int(round(18.0 * visual_scale))
	style.corner_radius_bottom_left = int(round(18.0 * visual_scale))
	style.corner_radius_bottom_right = int(round(18.0 * visual_scale))
	style.shadow_color = Color(0.01, 0.04, 0.10, 0.30)
	style.shadow_size = int(round(8.0 * visual_scale))
	style.shadow_offset = Vector2(0, 5.0 * visual_scale)
	panel.add_theme_stylebox_override("panel", style)
	panel.size = Vector2(banner_width, banner_height)
	panel.position = center - Vector2(banner_width * 0.5, banner_height * 0.5)
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.78, 0.78)
	panel.modulate.a = 0.0
	add_child(panel)
	_active_banner = panel

	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", maxi(17, int(round(17.0 * visual_scale))))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.52))
	label.add_theme_constant_override("shadow_offset_y", maxi(2, int(round(2.0 * visual_scale))))
	panel.add_child(label)

	if _reduced_motion():
		panel.scale = Vector2.ONE
		panel.modulate.a = 1.0
		var timer := get_tree().create_timer(0.42)
		timer.timeout.connect(panel.queue_free)
		return

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(panel, "scale", Vector2(1.08, 1.08), 0.10)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.34)
	tween.tween_property(panel, "position:y", panel.position.y - 18.0, 0.18).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.18)
	tween.finished.connect(panel.queue_free)

func show_ring(center: Vector2, diameter: float, accent: Color) -> void:
	var visual_scale := _visual_scale()
	var scaled_diameter := diameter * visual_scale
	var ring := Panel.new()
	ring.name = "PremiumGameplayRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2(scaled_diameter, scaled_diameter)
	ring.position = center - ring.size * 0.5
	ring.pivot_offset = ring.size * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(accent.lightened(0.28), 0.82)
	style.border_width_left = maxi(4, int(round(4.0 * visual_scale)))
	style.border_width_right = maxi(4, int(round(4.0 * visual_scale)))
	style.border_width_top = maxi(4, int(round(4.0 * visual_scale)))
	style.border_width_bottom = maxi(4, int(round(4.0 * visual_scale)))
	var radius := int(scaled_diameter * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	ring.add_theme_stylebox_override("panel", style)
	add_child(ring)
	if _reduced_motion():
		ring.modulate.a = 0.65
		get_tree().create_timer(0.16).timeout.connect(ring.queue_free)
		return
	ring.scale = Vector2(0.78, 0.78)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.30, 1.30), 0.28)
	tween.tween_property(ring, "modulate:a", 0.0, 0.28)
	tween.finished.connect(ring.queue_free)

func show_sweep(rect: Rect2, accent: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var sweep := ColorRect.new()
	sweep.name = "PremiumGameplaySweep"
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweep.color = Color(accent.lightened(0.34), 0.24)
	sweep.position = Vector2(rect.position.x - 20.0, rect.position.y)
	sweep.size = Vector2(maxf(20.0, rect.size.x * 0.16), rect.size.y)
	add_child(sweep)
	if _reduced_motion():
		sweep.position.x = rect.position.x + rect.size.x * 0.42
		get_tree().create_timer(0.10).timeout.connect(sweep.queue_free)
		return
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sweep, "position:x", rect.end.x + 16.0, 0.24)
	tween.tween_property(sweep, "modulate:a", 0.0, 0.24)
	tween.finished.connect(sweep.queue_free)

func _reduced_motion() -> bool:
	var motion := get_node_or_null("/root/MotionSystem")
	return motion != null and bool(motion.call("reduced"))
