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

func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if width > 0:
		s.border_width_left = width
		s.border_width_right = width
		s.border_width_top = width
		s.border_width_bottom = width
		s.border_color = border
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.50)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 10)
	return s

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.05, 0.93)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.position = Vector2(-360, -430)
	glow.size = Vector2(720, 860)
	glow.color = Color(accent, 0.055)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var card := PanelContainer.new()
	card.name = "ResultCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-350, -470)
	card.custom_minimum_size = Vector2(700, 940)
	card.add_theme_stylebox_override("panel", _box(Color("0b1628"), 42, Color(accent, 0.72), 2, 24))
	add_child(card)
	var margin := MarginContainer.new()
	margin.name = "ResultMargin"
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 44)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 38)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "ResultBox"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)

	var badge := Label.new()
	badge.text = badge_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", Color(accent, 0.92))
	box.add_child(badge)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("f7f9ff"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("9fb0c7"))
	box.add_child(subtitle)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 16)
	box.add_child(star_row)
	for i in range(3):
		var star := Label.new()
		star.text = "★" if i < stars else "☆"
		star.custom_minimum_size = Vector2(100, 100)
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_font_size_override("font_size", 72)
		star.add_theme_color_override("font_color", Color("ffd166") if i < stars else Color("435168"))
		star.scale = Vector2.ONE if MotionSystem.reduced() else Vector2(0.10, 0.10)
		star.modulate.a = 1.0 if MotionSystem.reduced() else 0.0
		star.pivot_offset = star.custom_minimum_size * 0.5
		star_row.add_child(star)
		if not MotionSystem.reduced():
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(MotionSystem.duration(&"press") + float(i) * MotionSystem.duration(&"settle"))
			tw.tween_property(star, "modulate:a", 1.0, MotionSystem.duration(&"micro"))
			tw.parallel().tween_property(star, "scale", Vector2(1.18, 1.18), MotionSystem.duration(&"settle"))
			tw.tween_property(star, "scale", Vector2.ONE, MotionSystem.duration(&"press"))

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(accent, 0.22)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)

	var stats := Label.new()
	stats.text = stats_text
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("font_size", 22)
	stats.add_theme_color_override("font_color", Color("d8e4f2"))
	stats.custom_minimum_size = Vector2(0, 110)
	box.add_child(stats)

	_secondary_button = Button.new()
	_secondary_button.name = "SecondaryAction"
	_secondary_button.text = secondary_text
	_secondary_button.visible = not secondary_text.is_empty()
	_secondary_button.disabled = not secondary_enabled
	_secondary_button.custom_minimum_size = Vector2(0, 78)
	_secondary_button.add_theme_font_size_override("font_size", 21)
	_secondary_button.add_theme_stylebox_override("normal", _box(Color("13233a"), 23, Color(accent, 0.72), 2, 5))
	_secondary_button.add_theme_stylebox_override("hover", _box(Color("18304e"), 23, Color(accent, 0.96), 2, 7))
	_secondary_button.add_theme_stylebox_override("pressed", _box(Color("0e1b2e"), 23, accent, 2, 2))
	_secondary_button.add_theme_color_override("font_color", Color("e8f2ff"))
	_secondary_button.pressed.connect(func() -> void: secondary_requested.emit())
	box.add_child(_secondary_button)

	var continue_button := Button.new()
	continue_button.name = "PrimaryAction"
	continue_button.text = button_text
	continue_button.custom_minimum_size = Vector2(0, 92)
	continue_button.add_theme_font_size_override("font_size", 24)
	continue_button.add_theme_stylebox_override("normal", _box(accent, 26, accent.lightened(0.20), 2, 10))
	continue_button.add_theme_stylebox_override("hover", _box(accent.lightened(0.08), 26, Color.WHITE, 2, 12))
	continue_button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.12), 26, Color.WHITE, 2, 3))
	continue_button.add_theme_color_override("font_color", Color("061019") if accent.get_luminance() > 0.56 else Color.WHITE)
	continue_button.pressed.connect(func(): continue_requested.emit())
	box.add_child(continue_button)

	var hint := Label.new()
	hint.text = "KEEP THE FLOW GOING"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("6f8098"))
	box.add_child(hint)

	card.modulate.a = 1.0 if MotionSystem.reduced() else 0.0
	card.scale = Vector2.ONE if MotionSystem.reduced() else Vector2(0.90, 0.90)
	card.pivot_offset = Vector2(350, 470)
	if not MotionSystem.reduced():
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, MotionSystem.duration(&"settle"))
		tween.parallel().tween_property(card, "scale", Vector2(1.02, 1.02), MotionSystem.duration(&"celebrate"))
		tween.tween_property(card, "scale", Vector2.ONE, MotionSystem.duration(&"press"))
