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
var _canvas: FigmaReferenceCanvas

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
	var dim := ColorRect.new()
	dim.name = "ResultDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.12, 0.22, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_canvas = FigmaReferenceCanvas.new()
	_canvas.name = "FigmaResult390x844"
	add_child(_canvas)

	var card := PanelContainer.new()
	card.name = "ResultCard3D"
	card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(
		Color(0.996, 0.998, 1.0),
		Color(0.93, 0.97, 0.99),
		24,
		accent.lightened(0.30),
		2
	))
	FigmaReferenceCanvas.set_rect(card, 28, 86, 334, 590)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(card)

	var title := FigmaReferenceCanvas.label(title_text, 26, Unjam3DTheme.NAVY, true)
	title.name = "ResultTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(title, 48, 128, 294, 56)
	_canvas.add_child(title)

	var subtitle := FigmaReferenceCanvas.label(subtitle_text, 14, Color("45617b"), false)
	subtitle.name = "ResultSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(subtitle, 48, 188, 294, 40)
	_canvas.add_child(subtitle)

	_add_identity(_result_game_id())

	for i in range(3):
		var x := 61.0 + float(i) * 92.0
		var star_card := PanelContainer.new()
		star_card.name = "StarCard"
		var earned := i < stars
		star_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(
			Color("fff6c9") if earned else Color("e3edf3"),
			Color("f6df79") if earned else Color("cbd8e0"),
			18,
			Unjam3DTheme.GOLD if earned else Color("a9bac5"),
			1
		))
		FigmaReferenceCanvas.set_rect(star_card, x, 307, 78, 78)
		star_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(star_card)
		var star := FigmaReferenceCanvas.label("★" if earned else "☆", 38, Unjam3DTheme.GOLD if earned else Color("8faabc"), true)
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FigmaReferenceCanvas.set_rect(star, x + 22, 270, 40, 46)
		_canvas.add_child(star)

	var stats_panel := PanelContainer.new()
	stats_panel.name = "Stats"
	stats_panel.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(
		Color("f4fbff"), Color("e7f4fb"), 16, Color("afdfff"), 1
	))
	FigmaReferenceCanvas.set_rect(stats_panel, 48, 364, 294, 92)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(stats_panel)
	var stats := FigmaReferenceCanvas.label(stats_text, 15, Unjam3DTheme.NAVY, true)
	stats.name = "ResultStatsText"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(stats, 68, 378, 254, 66)
	_canvas.add_child(stats)

	var primary := FigmaReferenceCanvas.button(button_text, 14, Color.WHITE, accent, 17, accent.lightened(0.26), 1)
	primary.name = "PrimaryAction"
	FigmaReferenceCanvas.set_rect(primary, 48, 500, 294, 58)
	primary.pressed.connect(func(): continue_requested.emit())
	_canvas.add_child(primary)

	_secondary_button = FigmaReferenceCanvas.button(secondary_text, 12, Color.WHITE, Color("176eb4"), 16, Color("70b9ef"), 1)
	_secondary_button.name = "SecondaryAction"
	FigmaReferenceCanvas.set_rect(_secondary_button, 48, 570, 294, 48)
	_secondary_button.visible = not secondary_text.is_empty()
	_secondary_button.disabled = not secondary_enabled
	_secondary_button.pressed.connect(func(): secondary_requested.emit())
	_canvas.add_child(_secondary_button)

	card.modulate.a = 0.0
	card.scale = Vector2(0.94, 0.94)
	card.pivot_offset = Vector2(167, 295)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.10)
	tween.parallel().tween_property(card, "scale", Vector2(1.015, 1.015), 0.18)
	tween.tween_property(card, "scale", Vector2.ONE, 0.08)

func _result_game_id() -> String:
	var upper := title_text.to_upper()
	if "WATER" in upper:
		return "water_sort"
	if "BLOCK" in upper or "EXTREME" in upper:
		return "block_puzzle"
	return "rescue_rush"

func _add_identity(game_id: String) -> void:
	match game_id:
		"water_sort":
			for i in range(3):
				var x := 145.0 + float(i) * 36.0
				var glass := PanelContainer.new()
				glass.name = "ResultIdentity/Water/Glass/%d" % i
				glass.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.92,0.99,1.0,0.26), 9, Color("a6e7ff"), 1))
				FigmaReferenceCanvas.set_rect(glass, x, 204, 28, 48)
				_canvas.add_child(glass)
				var colors := [Color("ff4f9c"), Color("19a9e8"), Color("f4cf25")]
				var liquid := ColorRect.new()
				liquid.color = colors[i]
				FigmaReferenceCanvas.set_rect(liquid, x + 4, 218, 20, 28)
				_canvas.add_child(liquid)
				var meniscus := PanelContainer.new()
				meniscus.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(colors[i].lightened(0.08), 4))
				FigmaReferenceCanvas.set_rect(meniscus, x + 4, 214, 20, 8)
				_canvas.add_child(meniscus)
		"block_puzzle":
			for i in range(4):
				var x := 139.0 + float(i) * 30.0
				var cell := PanelContainer.new()
				cell.name = "ResultIdentity/Block/%d/Front" % i
				cell.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(
					Color("ff8bcf") if i % 2 == 0 else Color("40d8ff"),
					Color("d94ab4") if i % 2 == 0 else Color("258ccf"),
					5
				))
				FigmaReferenceCanvas.set_rect(cell, x, 221, 24, 24)
				_canvas.add_child(cell)
				var top := Polygon2D.new()
				top.name = "ResultIdentity/Block/%d/Top" % i
				top.polygon = PackedVector2Array([Vector2(x,221),Vector2(x+3,216),Vector2(x+27,216),Vector2(x+24,221)])
				top.color = Color("ffd2ee") if i % 2 == 0 else Color("b9efff")
				_canvas.add_child(top)
		_:
			var shadow := PanelContainer.new()
			shadow.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.04,0.18,0.12,0.20), 8))
			FigmaReferenceCanvas.set_rect(shadow,169,237,52,10)
			_canvas.add_child(shadow)
			var chick := PanelContainer.new()
			chick.name = "ResultIdentity/Rescue/Chick"
			chick.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color("ffd34f"), 14, Color("fff0a3"), 1))
			FigmaReferenceCanvas.set_rect(chick,181,207,28,28)
			_canvas.add_child(chick)
			for x in [188.0,198.0]:
				var eye := ColorRect.new()
				eye.color = Color("1d3650")
				FigmaReferenceCanvas.set_rect(eye,x,216,3,4)
				_canvas.add_child(eye)
			var exit := PanelContainer.new()
			exit.name = "ResultIdentity/Rescue/Exit"
			exit.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.16,0.78,0.42,0.22), 10, Color("3dcc78"), 2))
			FigmaReferenceCanvas.set_rect(exit,221,201,20,42)
			_canvas.add_child(exit)

func _celebrate() -> void:
	if not is_inside_tree():
		return
	var visuals := get_tree().root.get_node_or_null("PremiumVisuals")
	if visuals == null:
		return
	var center := get_viewport_rect().size * 0.5
	if visuals.has_method("burst"):
		visuals.call("burst", center + Vector2(0, -110), accent, 18)
