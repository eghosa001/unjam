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
var _secondary_shadow: Control
var _canvas: FigmaReferenceCanvas

func _dark_theme() -> bool:
	var main := get_tree().current_scene
	var shell := main.get_node_or_null("UXShell") if main != null else null
	return shell != null and shell.get("theme_mode") != null and String(shell.get("theme_mode")) == "dark"

func configure(title_value: String, subtitle_value: String, stats_value: String, star_count: int, color: Color, action_text: String = "CONTINUE", badge_value: String = "PUZZLE CLEARED") -> void:
	title_text = title_value
	subtitle_text = subtitle_value
	stats_text = stats_value
	stars = clampi(star_count, 0, 3)
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
		if _secondary_shadow != null and is_instance_valid(_secondary_shadow):
			_secondary_shadow.visible = _secondary_button.visible

func set_secondary_state(text_value: String, enabled: bool, tooltip: String = "") -> void:
	secondary_text = text_value
	secondary_enabled = enabled
	if _secondary_button != null and is_instance_valid(_secondary_button):
		_secondary_button.text = text_value
		_secondary_button.disabled = not enabled
		_secondary_button.tooltip_text = tooltip
		_secondary_button.visible = not text_value.is_empty()
		if _secondary_shadow != null and is_instance_valid(_secondary_shadow):
			_secondary_shadow.visible = _secondary_button.visible

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000
	_build()
	call_deferred("_celebrate")

func _build() -> void:
	var dark := _dark_theme()
	var dim := ColorRect.new()
	dim.name = "ResultDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(Color("#0a4f94"), 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_canvas = FigmaReferenceCanvas.new()
	_canvas.name = "FigmaResult390x844"
	add_child(_canvas)

	var has_secondary := not secondary_text.is_empty()
	var card_rect := Rect2(27,76,334,570 if has_secondary else 500)
	FigmaReferenceCanvas.add_shadow(_canvas, card_rect, 28, Color(0.03,0.11,0.20,0.16), 5, Vector2(0,5))
	var card := PanelContainer.new()
	card.name = "ResultCard3D"
	card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		Color("#172238") if dark else Color("#fffef8"),
		Color("#131e31") if dark else Color("#fbfaf4"),
		Color("#0f1828") if dark else Color("#f6f5ef"),
		28,
		Color(accent, 0.62 if dark else 0.32),
		1.2,
		0.50
	))
	FigmaReferenceCanvas.set_rect(card, card_rect.position.x, card_rect.position.y, card_rect.size.x, card_rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(card)

	var title := FigmaReferenceCanvas.label(title_text, 26, Color("#eef7ff") if dark else Unjam3DTheme.NAVY, true)
	title.name = "ResultTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(title, 47, 100, 294, 44)
	_canvas.add_child(title)

	var subtitle := FigmaReferenceCanvas.label(subtitle_text, 13, Color("#b6c7d6") if dark else Color("45617b"), false)
	subtitle.name = "ResultSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(subtitle, 47, 150, 294, 68)
	_canvas.add_child(subtitle)

	_add_identity(_result_game_id())

	for i in range(3):
		var x := 60.0 + float(i) * 92.0
		var star_card := PanelContainer.new()
		star_card.name = "StarCard"
		var earned := i < stars
		FigmaReferenceCanvas.add_shadow(_canvas, Rect2(x,306,78,72), 30, Color(0.02,0.14,0.26,0.20), 4, Vector2(0,3))
		var star_mid := Color("#fff2b2") if earned else Color("#e3edf3")
		star_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
			star_mid.lightened(0.13),
			star_mid,
			star_mid.darkened(0.13),
			30,
			Color("#ffd63d") if earned else Color("#a9bac5"),
			1.5,
			0.40
		))
		FigmaReferenceCanvas.set_rect(star_card, x, 306, 78, 72)
		star_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(star_card)
		var star := FigmaReferenceCanvas.label("★" if earned else "☆", 38, Unjam3DTheme.GOLD if earned else Color("8faabc"), true)
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FigmaReferenceCanvas.set_rect(star, x, 306, 78, 72)
		_canvas.add_child(star)

	var stats_panel := PanelContainer.new()
	stats_panel.name = "Stats"
	FigmaReferenceCanvas.add_shadow(_canvas, Rect2(47,392,294,86), 18, Color(0.02,0.14,0.26,0.20), 3, Vector2(0,2))
	var stats_mid := Color("#1a384d") if dark else Color("#ebfaff")
	stats_panel.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		stats_mid.lightened(0.14 if dark else 0.07),
		stats_mid,
		stats_mid.darkened(0.16 if dark else 0.08),
		18,
		Color("#1aa8ff"),
		1.5,
		0.40
	))
	FigmaReferenceCanvas.set_rect(stats_panel, 47, 392, 294, 86)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(stats_panel)
	var stats := FigmaReferenceCanvas.label(stats_text, 14, Color("#dceaf5") if dark else Unjam3DTheme.NAVY, true)
	stats.name = "ResultStatsText"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(stats, 67, 401, 254, 68)
	_canvas.add_child(stats)

	FigmaReferenceCanvas.add_shadow(_canvas, Rect2(47,498,294,58), 17, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	var primary := FigmaReferenceCanvas.premium_button(button_text, 14, Color.WHITE, accent, 17, accent.lightened(0.26), 1.3)
	primary.name = "PrimaryAction"
	FigmaReferenceCanvas.set_rect(primary, 47, 498, 294, 58)
	primary.pressed.connect(func(): continue_requested.emit())
	_canvas.add_child(primary)

	_secondary_shadow = FigmaReferenceCanvas.add_shadow(_canvas, Rect2(47,568,294,48), 16, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	_secondary_shadow.name = "SecondaryActionShadow"
	_secondary_shadow.visible = has_secondary
	_secondary_button = FigmaReferenceCanvas.premium_button(secondary_text, 12, Color.WHITE, Color("#086ec7"), 16, Color("#70b9ef"), 1.3)
	_secondary_button.name = "SecondaryAction"
	FigmaReferenceCanvas.set_rect(_secondary_button, 47, 568, 294, 48)
	_secondary_button.visible = has_secondary
	_secondary_button.disabled = not secondary_enabled
	_secondary_button.pressed.connect(func(): secondary_requested.emit())
	_canvas.add_child(_secondary_button)

	card.modulate.a = 0.0
	card.scale = Vector2(0.94, 0.94)
	card.pivot_offset = card_rect.size * 0.5
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
			var colors: Array[Color] = [Color("#ff4da3"), Color("#1fabff"), Color("#38d16b")]
			for i in range(3):
				var x := 144.0 + float(i) * 36.0
				var glass := PanelContainer.new()
				glass.name = "ResultIdentity/Water/Glass/%d" % i
				glass.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.92,0.99,1.0,0.10), 10, Color(0.78,0.96,1.0,0.90), 1.2))
				FigmaReferenceCanvas.set_rect(glass, x, 246, 28, 44)
				_canvas.add_child(glass)
				var liquid := ColorRect.new()
				liquid.color = colors[i]
				FigmaReferenceCanvas.set_rect(liquid, x + 4, 260, 20, 24)
				_canvas.add_child(liquid)
				var meniscus := PanelContainer.new()
				meniscus.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(colors[i].lightened(0.08), 4))
				FigmaReferenceCanvas.set_rect(meniscus, x + 4, 256, 20, 8)
				_canvas.add_child(meniscus)
		"block_puzzle":
			var fills: Array[Color] = [Color("#38df63"), Color("#466df2"), Color("#ff8b3e"), Color("#9d5add")]
			var edges: Array[Color] = [Color("#61ff8c"), Color("#6f96ff"), Color("#ffb467"), Color("#c683ff")]
			for i in range(4):
				var x := 138.0 + float(i) * 30.0
				var cell := PanelContainer.new()
				cell.name = "ResultIdentity/Block/%d/Front" % i
				cell.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(fills[i], 4, Color(edges[i],0.90), 1))
				FigmaReferenceCanvas.set_rect(cell, x, 261, 24, 22)
				_canvas.add_child(cell)
				var top := Polygon2D.new()
				top.name = "ResultIdentity/Block/%d/Top" % i
				top.polygon = PackedVector2Array([Vector2(x,261),Vector2(x+3,257),Vector2(x+27,257),Vector2(x+24,261)])
				top.color = fills[i].lightened(0.28)
				_canvas.add_child(top)
		_:
			var shadow := PanelContainer.new()
			shadow.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.04,0.18,0.12,0.20), 8))
			FigmaReferenceCanvas.set_rect(shadow,168,278,52,8)
			_canvas.add_child(shadow)
			var chick := PanelContainer.new()
			chick.name = "ResultIdentity/Rescue/Chick"
			chick.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color("#ffd63d"), 14, Color("#fff1a0"), 1))
			FigmaReferenceCanvas.set_rect(chick,180,251,28,26)
			_canvas.add_child(chick)
			for x in [187.0,197.0]:
				var eye := ColorRect.new()
				eye.color = Color("#183b42")
				FigmaReferenceCanvas.set_rect(eye,x,260,3,4)
				_canvas.add_child(eye)
			var exit := PanelContainer.new()
			exit.name = "ResultIdentity/Rescue/Exit"
			exit.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(Color("#80efb0"), Color("#35b96b"), Color("#148b4c"), 10))
			FigmaReferenceCanvas.set_rect(exit,220,246,20,38)
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
