class_name PremiumResultOverlay
extends Control

signal continue_requested
signal secondary_requested

var accent := Color("5da9ff")
var title_text := "LEVEL COMPLETE"
var subtitle_text := ""
var stats_text := ""
var stars := 3
var button_text := "CONTINUE"
var badge_text := "PUZZLE CLEARED"
var secondary_text := ""
var secondary_enabled := false
var _secondary_button: Button

func configure(title_value: String, subtitle_value: String, stats_value: String, star_count: int, color: Color, action_text: String = "CONTINUE", badge_value: String = "PUZZLE CLEARED") -> void:
	title_text = title_value
	subtitle_text = subtitle_value
	stats_text = stats_value
	stars = clampi(star_count, 1, 3)
	accent = color
	button_text = action_text
	badge_text = badge_value

func configure_secondary(text_value: String, enabled: bool = true) -> void:
	secondary_text = text_value
	secondary_enabled = enabled
	if _secondary_button != null and is_instance_valid(_secondary_button):
		_secondary_button.text = secondary_text
		_secondary_button.disabled = not secondary_enabled
		_secondary_button.visible = not secondary_text.is_empty()

func set_secondary_state(text_value: String, enabled: bool, tooltip: String = "") -> void:
	secondary_text = text_value
	secondary_enabled = enabled
	if _secondary_button != null and is_instance_valid(_secondary_button):
		_secondary_button.text = text_value
		_secondary_button.disabled = not enabled
		_secondary_button.tooltip_text = tooltip
		_secondary_button.visible = not text_value.is_empty()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000
	_build()
	call_deferred("_celebrate")

func _build() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 700.0 or viewport_size.y < 1100.0
	var card_size := Vector2(
		clampf(viewport_size.x - 48.0, 460.0, 760.0),
		clampf(viewport_size.y * (0.69 if compact else 0.43), 650.0, 820.0)
	)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.16, 0.30, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var card := PanelContainer.new()
	card.name = "ResultCard3D"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = -card_size * 0.5
	card.custom_minimum_size = card_size
	card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("f9fdff"), 46, accent.lightened(0.28), 5, 24))
	add_child(card)

	var margin := MarginContainer.new()
	var side_margin := 28 if compact else 46
	var vertical_margin := 26 if compact else 36
	margin.add_theme_constant_override("margin_left", side_margin)
	margin.add_theme_constant_override("margin_right", side_margin)
	margin.add_theme_constant_override("margin_top", vertical_margin)
	margin.add_theme_constant_override("margin_bottom", vertical_margin)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12 if compact else 18)
	margin.add_child(box)

	var badge_panel := PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(0, 54 if compact else 62)
	badge_panel.add_theme_stylebox_override("panel", Unjam3DTheme.badge(accent, 24))
	box.add_child(badge_panel)
	var badge := Label.new()
	badge.text = badge_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18 if compact else 19)
	Unjam3DTheme.label_3d(badge, Color.WHITE, accent.darkened(0.45), 3)
	badge_panel.add_child(badge)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 35 if compact else 46)
	Unjam3DTheme.label_3d(title, Unjam3DTheme.NAVY, Color.WHITE, 3)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18 if compact else 21)
	Unjam3DTheme.label_3d(subtitle, Color("3d6286"), Color.WHITE, 2)
	box.add_child(subtitle)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 10 if compact else 14)
	box.add_child(star_row)
	for i in range(3):
		var star_panel := PanelContainer.new()
		var star_size := 88.0 if compact else 116.0
		star_panel.custom_minimum_size = Vector2(star_size, star_size)
		star_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("fff2b5") if i < stars else Color("d9e8f2"), 40, Unjam3DTheme.GOLD if i < stars else Color("a4c0d2"), 3, 8))
		star_row.add_child(star_panel)
		var star := Label.new()
		star.text = "★" if i < stars else "☆"
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_font_size_override("font_size", 52 if compact else 67)
		Unjam3DTheme.label_3d(star, Unjam3DTheme.GOLD if i < stars else Color("8faabc"), Color.WHITE, 3)
		star_panel.add_child(star)
		star_panel.scale = Vector2(0.15, 0.15)
		star_panel.modulate.a = 0.0
		star_panel.pivot_offset = star_panel.custom_minimum_size * 0.5
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.07 + float(i) * 0.10)
		tw.tween_property(star_panel, "modulate:a", 1.0, 0.05)
		tw.parallel().tween_property(star_panel, "scale", Vector2(1.10, 1.10), 0.14)
		tw.tween_property(star_panel, "scale", Vector2.ONE, 0.09)

	var performance := Label.new()
	performance.text = "✦  PERFORMANCE"
	performance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	performance.add_theme_font_size_override("font_size", 16 if compact else 18)
	Unjam3DTheme.label_3d(performance, accent, Color.WHITE, 2)
	box.add_child(performance)

	var stats_panel := PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(0, 118 if compact else 144)
	stats_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("edf9ff"), 28, Color("a9e2ff"), 2, 6))
	box.add_child(stats_panel)
	var stats := Label.new()
	stats.text = stats_text
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("font_size", 20 if compact else 24)
	Unjam3DTheme.label_3d(stats, Unjam3DTheme.NAVY, Color.WHITE, 2)
	stats_panel.add_child(stats)

	_secondary_button = Button.new()
	_secondary_button.name = "SecondaryAction"
	_secondary_button.text = secondary_text
	_secondary_button.visible = not secondary_text.is_empty()
	_secondary_button.disabled = not secondary_enabled
	_secondary_button.custom_minimum_size = Vector2(0, 70 if compact else 82)
	_secondary_button.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.gloss_button(_secondary_button, Unjam3DTheme.WATER_DARK, false, 27)
	_secondary_button.pressed.connect(func() -> void: secondary_requested.emit())
	box.add_child(_secondary_button)

	var continue_button := Button.new()
	continue_button.name = "PrimaryAction"
	continue_button.text = button_text
	continue_button.custom_minimum_size = Vector2(0, 86 if compact else 104)
	continue_button.add_theme_font_size_override("font_size", 24 if compact else 28)
	Unjam3DTheme.gloss_button(continue_button, accent, true, 32)
	continue_button.pressed.connect(func(): continue_requested.emit())
	box.add_child(continue_button)

	var hint := Label.new()
	hint.text = "NEXT PUZZLE READY  •  KEEP THE MOMENTUM ♥"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16 if compact else 18)
	Unjam3DTheme.label_3d(hint, Color("557a98"), Color.WHITE, 2)
	box.add_child(hint)

	card.modulate.a = 0.0
	card.scale = Vector2(0.88, 0.88)
	card.pivot_offset = card_size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.10)
	tween.parallel().tween_property(card, "scale", Vector2(1.025, 1.025), 0.23)
	tween.tween_property(card, "scale", Vector2.ONE, 0.09)


func _celebrate() -> void:
	if not is_inside_tree():
		return
	var visuals := get_tree().root.get_node_or_null("PremiumVisuals")
	if visuals == null:
		return
	var center := get_viewport_rect().size * 0.5
	if visuals.has_method("screen_flash"):
		visuals.call("screen_flash", accent, 0.10)
	if visuals.has_method("burst"):
		visuals.call("burst", center + Vector2(0, -120), accent, 34)
		visuals.call("burst", center + Vector2(0, 20), Unjam3DTheme.GOLD, 22)
