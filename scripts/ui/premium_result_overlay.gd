class_name PremiumResultOverlay
extends Control

signal continue_requested
signal secondary_requested

const VIBRANT_REFERENCE_TARGET := "approved-colorful-reference"

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

func _motion_service() -> Node:
	return get_node_or_null("/root/MotionSystem")

func _reduced_motion() -> bool:
	var motion := _motion_service()
	return bool(motion.call("reduced")) if motion != null and motion.has_method("reduced") else false

func _motion_duration(kind: StringName) -> float:
	var motion := _motion_service()
	if motion != null and motion.has_method("duration"):
		return float(motion.call("duration", kind))
	match kind:
		&"micro": return 0.07
		&"press": return 0.10
		&"settle": return 0.14
		&"celebrate": return 0.34
		_: return 0.16

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
		s.shadow_color = Color(0, 0, 0, 0.28)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 10)
	return s

func _build() -> void:
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Color("7bdcff"), accent.lightened(0.16), 0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.09, 0.22, 0.38, 0.20)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var card := PanelContainer.new()
	card.name = "ResultCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-370, -490)
	card.custom_minimum_size = Vector2(740, 980)
	card.add_theme_stylebox_override("panel", _box(Color("fffaf0"), 46, Color(accent.lightened(0.18), 0.95), 4, 22))
	add_child(card)
	var margin := MarginContainer.new()
	margin.name = "ResultMargin"
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 48)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 38)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "ResultBox"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)

	var badge_panel := PanelContainer.new()
	badge_panel.add_theme_stylebox_override("panel", _box(Color(accent, 0.16), 18, Color(accent, 0.42), 2))
	box.add_child(badge_panel)
	var badge := Label.new()
	badge.text = badge_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 17)
	badge.add_theme_color_override("font_color", accent.darkened(0.42))
	badge_panel.add_child(badge)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("24345f"))
	title.add_theme_color_override("font_shadow_color", Color(1,1,1,0.55))
	title.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color("4c6480"))
	box.add_child(subtitle)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 18)
	box.add_child(star_row)
	for i in range(3):
		var star := Label.new()
		star.text = "★" if i < stars else "☆"
		star.custom_minimum_size = Vector2(108, 108)
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_font_size_override("font_size", 78)
		star.add_theme_color_override("font_color", Color("ffca28") if i < stars else Color("c8d4e5"))
		star.add_theme_color_override("font_shadow_color", Color("d77d00", 0.25))
		star.add_theme_constant_override("shadow_offset_y", 3)
		star.scale = Vector2.ONE if _reduced_motion() else Vector2(0.10, 0.10)
		star.modulate.a = 1.0 if _reduced_motion() else 0.0
		star.pivot_offset = star.custom_minimum_size * 0.5
		star_row.add_child(star)
		if not _reduced_motion():
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(_motion_duration(&"press") + float(i) * _motion_duration(&"settle"))
			tw.tween_property(star, "modulate:a", 1.0, _motion_duration(&"micro"))
			tw.parallel().tween_property(star, "scale", Vector2(1.18, 1.18), _motion_duration(&"settle"))
			tw.tween_property(star, "scale", Vector2.ONE, _motion_duration(&"press"))

	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", _box(Color("eef8ff"), 24, Color("b9e4ff"), 2))
	box.add_child(stats_panel)
	var stats := Label.new()
	stats.text = stats_text
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("font_size", 23)
	stats.add_theme_color_override("font_color", Color("31506e"))
	stats.custom_minimum_size = Vector2(0, 118)
	stats_panel.add_child(stats)

	_secondary_button = Button.new()
	_secondary_button.name = "SecondaryAction"
	_secondary_button.text = secondary_text
	_secondary_button.visible = not secondary_text.is_empty()
	_secondary_button.disabled = not secondary_enabled
	_secondary_button.custom_minimum_size = Vector2(0, 82)
	_secondary_button.add_theme_font_size_override("font_size", 22)
	PremiumDesignSystem.apply_button(_secondary_button, true, Color("7657d8"), "secondary", 24)
	_secondary_button.pressed.connect(func() -> void: secondary_requested.emit())
	box.add_child(_secondary_button)

	var continue_button := Button.new()
	continue_button.name = "PrimaryAction"
	continue_button.text = button_text
	continue_button.custom_minimum_size = Vector2(0, 98)
	continue_button.add_theme_font_size_override("font_size", 26)
	PremiumDesignSystem.apply_button(continue_button, true, accent, "primary", 26)
	continue_button.pressed.connect(func(): continue_requested.emit())
	box.add_child(continue_button)

	var hint := Label.new()
	hint.text = "KEEP THE FLOW GOING"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("6e7891"))
	box.add_child(hint)

	card.modulate.a = 1.0 if _reduced_motion() else 0.0
	card.scale = Vector2.ONE if _reduced_motion() else Vector2(0.90, 0.90)
	card.pivot_offset = Vector2(370, 490)
	if not _reduced_motion():
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, _motion_duration(&"settle"))
		tween.parallel().tween_property(card, "scale", Vector2(1.02, 1.02), _motion_duration(&"celebrate"))
		tween.tween_property(card, "scale", Vector2.ONE, _motion_duration(&"press"))
