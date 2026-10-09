class_name PremiumResultOverlay
extends Control

const GAME_ART_SCRIPT = preload("res://scripts/ui/unjam_2d_game_art.gd")

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
var _primary_button: Button
var _primary_committed := false
var _secondary_pending := false
var _canvas: FigmaReferenceCanvas

func _motion_reduced() -> bool:
	# Use runtime lookup rather than a global symbol so standalone component
	# checks can preload this class before project autoloads are compiled.
	var motion := get_node_or_null("/root/MotionSystem")
	return motion != null and motion.has_method("reduced") and bool(motion.call("reduced"))

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
	if enabled:
		_secondary_pending = false
	if _secondary_button != null and is_instance_valid(_secondary_button):
		_secondary_button.text = secondary_text
		_secondary_button.disabled = not secondary_enabled
		_secondary_button.visible = not secondary_text.is_empty()
		if _secondary_shadow != null and is_instance_valid(_secondary_shadow):
			_secondary_shadow.visible = _secondary_button.visible

func set_secondary_state(text_value: String, enabled: bool, tooltip: String = "") -> void:
	secondary_text = text_value
	secondary_enabled = enabled
	if enabled:
		# Explicit failure / retry is the only way to re-arm an ad action.
		_secondary_pending = false
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
	FigmaReferenceCanvas.add_scene_backdrop_layers(_canvas, accent, dark, "Result")
	var result_key_light := _canvas.get_node_or_null("ResultKeyLight")
	if result_key_light != null:
		result_key_light.set_meta("unjam_figma_scene_light", true)

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

	_add_victory_aura(dark)

	var title := FigmaReferenceCanvas.label(_result_display_title(), 27, Color("#eef7ff") if dark else Unjam3DTheme.NAVY, true)
	title.name = "ResultTitle"
	FigmaReferenceCanvas.style_display_title(title, accent.lightened(0.22), Color("#071d55"), 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The status badge already communicates completion. Keep the large heading to
	# one game-name line so Android font metrics can never wrap "COMPLETE" into
	# the descriptive subtitle below it.
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	FigmaReferenceCanvas.set_rect(title, 47, 118, 294, 40)
	_canvas.add_child(title)

	var badge_fill := Color(accent, 0.18 if dark else 0.12)
	var badge := PanelContainer.new()
	badge.name = "ResultBadge"
	badge.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(badge_fill, 12, Color(accent, 0.58), 1))
	FigmaReferenceCanvas.set_rect(badge, 109, 86, 170, 28)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(badge)
	var badge_label := FigmaReferenceCanvas.label(badge_text, 13, accent.lightened(0.28) if dark else accent.darkened(0.28), true)
	badge_label.name = "ResultBadgeText"
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.clip_text = true
	FigmaReferenceCanvas.set_rect(badge_label, 115, 88, 158, 24)
	_canvas.add_child(badge_label)

	var subtitle := FigmaReferenceCanvas.label(subtitle_text, 14, Color("#b6c7d6") if dark else Color("45617b"), false)
	subtitle.name = "ResultSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(subtitle, 47, 162, 294, 66)
	_canvas.add_child(subtitle)

	_add_identity(_result_game_id())

	for i in range(3):
		var x := 62.0 + float(i) * 90.0
		var star_card := PanelContainer.new()
		star_card.name = "StarCard"
		star_card.set_meta("result_star_index", i)
		var earned := i < stars
		var star_rect := Rect2(x, 306, 74, 70)
		FigmaReferenceCanvas.add_shadow(_canvas, star_rect, 30, Color(0.02,0.08,0.16,0.18), 4, Vector2(0,3))
		var earned_mid := Color("#3b3211") if dark else Color("#fff5c9")
		var idle_mid := Color("#26313b") if dark else Color("#e9eef1")
		var star_mid := earned_mid if earned else idle_mid
		var star_edge := Color("#ffd84f", 0.74) if earned else Color("#a8bac7", 0.38)
		star_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
			star_mid.lightened(0.08),
			star_mid,
			star_mid.darkened(0.08),
			30,
			star_edge,
			1.2,
			0.22
		))
		FigmaReferenceCanvas.set_rect(star_card, star_rect.position.x, star_rect.position.y, star_rect.size.x, star_rect.size.y)
		star_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(star_card)
		if earned:
			var star_glow := PanelContainer.new()
			star_glow.name = "ResultStarGlow_%d" % i
			star_glow.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color("#ffd84f", 0.09), 32))
			FigmaReferenceCanvas.set_rect(star_glow, x - 7, 300, 88, 82)
			star_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_canvas.add_child(star_glow)
		FigmaReferenceCanvas.add_collectible_star(
			_canvas,
			Vector2(x + 37.0, 341.0),
			24.0,
			earned,
			"ResultStar3D_%d" % i
		)

	var stats_panel := PanelContainer.new()
	stats_panel.name = "Stats"
	FigmaReferenceCanvas.add_shadow(_canvas, Rect2(47,392,294,86), 18, Color(0.02,0.14,0.26,0.20), 3, Vector2(0,2))
	var stats_mid := (Color("#162a2b").lerp(accent.darkened(0.55), 0.26) if dark
		else Color("#f3f7f4").lerp(accent.lightened(0.72), 0.26))
	stats_panel.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		stats_mid.lightened(0.10 if dark else 0.05),
		stats_mid,
		stats_mid.darkened(0.10 if dark else 0.06),
		18,
		Color(accent, 0.70 if dark else 0.44),
		1.4,
		0.28
	))
	FigmaReferenceCanvas.set_rect(stats_panel, 47, 392, 294, 86)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(stats_panel)
	var stats := FigmaReferenceCanvas.label(stats_text, 15, Color("#dceaf5") if dark else Unjam3DTheme.NAVY, true)
	stats.name = "ResultStatsText"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(stats, 67, 401, 254, 68)
	_canvas.add_child(stats)

	FigmaReferenceCanvas.add_shadow(_canvas, Rect2(47,498,294,58), 17, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	var primary := FigmaReferenceCanvas.premium_button(button_text, 16, Color.WHITE, accent, 17, accent.lightened(0.26), 1.3)
	primary.name = "PrimaryAction"
	FigmaReferenceCanvas.set_rect(primary, 47, 498, 294, 58)
	_primary_button = primary
	primary.pressed.connect(_on_continue_pressed)
	_canvas.add_child(primary)

	_secondary_shadow = FigmaReferenceCanvas.add_shadow(_canvas, Rect2(47,568,294,48), 16, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	_secondary_shadow.name = "SecondaryActionShadow"
	_secondary_shadow.visible = has_secondary
	var secondary_fill := accent.darkened(0.32) if dark else accent.darkened(0.12)
	_secondary_button = FigmaReferenceCanvas.premium_button(secondary_text, 15, Color.WHITE, secondary_fill, 16, accent.lightened(0.24), 1.3)
	_secondary_button.name = "SecondaryAction"
	FigmaReferenceCanvas.set_rect(_secondary_button, 47, 568, 294, 48)
	_secondary_button.visible = has_secondary
	_secondary_button.disabled = not secondary_enabled
	_secondary_button.pressed.connect(_on_secondary_pressed)
	_canvas.add_child(_secondary_button)

	card.pivot_offset = card_rect.size * 0.5
	if _motion_reduced():
		# Don't hide a newly won result behind a transition or animate a large
		# central panel for players who opted out of motion.
		card.modulate.a = 1.0
		card.scale = Vector2.ONE
	else:
		card.modulate.a = 0.0
		card.scale = Vector2(0.94, 0.94)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, 0.10)
		tween.parallel().tween_property(card, "scale", Vector2(1.015, 1.015), 0.18)
		tween.tween_property(card, "scale", Vector2.ONE, 0.08)

func _on_continue_pressed() -> void:
	# Do not emit two level-advance signals if a button is tapped twice while
	# the result overlay is still queued for removal.
	if _primary_committed:
		return
	_primary_committed = true
	if _primary_button != null and is_instance_valid(_primary_button):
		_primary_button.disabled = true
	if _secondary_button != null and is_instance_valid(_secondary_button):
		_secondary_button.disabled = true
	continue_requested.emit()

func _on_secondary_pressed() -> void:
	if _primary_committed or _secondary_pending or not secondary_enabled:
		return
	_secondary_pending = true
	if _secondary_button != null and is_instance_valid(_secondary_button):
		_secondary_button.disabled = true
	secondary_requested.emit()

func _result_display_title() -> String:
	match _result_game_id():
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _result_game_id() -> String:
	var upper := title_text.to_upper()
	if "WATER" in upper:
		return "water_sort"
	if "BLOCK" in upper or "EXTREME" in upper:
		return "block_puzzle"
	return "rescue_rush"

func _add_victory_aura(dark: bool) -> void:
	var halo := PanelContainer.new()
	halo.name = "ResultVictoryHalo"
	halo.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(accent, 0.08 if dark else 0.065), 100))
	FigmaReferenceCanvas.set_rect(halo, 77, 196, 236, 190)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(halo)

	var center := Vector2(195, 278)
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		var ray := ColorRect.new()
		ray.name = "ResultVictoryRay_%02d" % i
		ray.color = Color((Color("#ffd95e") if i % 2 == 0 else accent).lightened(0.10), 0.075 if dark else 0.060)
		ray.size = Vector2(4, 42)
		ray.pivot_offset = Vector2(2, 21)
		var radius := 76.0
		ray.position = center + Vector2(cos(angle), sin(angle)) * radius - ray.pivot_offset
		ray.rotation = angle + PI * 0.5
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(ray)

	for spec in [
		[84.0, 270.0, 5.0, -0.32],
		[298.0, 264.0, 6.0, 0.38],
		[98.0, 360.0, 4.0, 0.28],
		[287.0, 354.0, 5.0, -0.24],
	]:
		var confetti := ColorRect.new()
		confetti.name = "ResultVictoryConfetti"
		confetti.color = Color("#ffd95e", 0.62)
		FigmaReferenceCanvas.set_rect(confetti, float(spec[0]), float(spec[1]), float(spec[2]), float(spec[2]) * 2.1)
		confetti.rotation = float(spec[3])
		confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(confetti)

func _add_identity(game_id: String) -> void:
	# Results reuse the same authored 2D identity as Home/Choose Game. Keep it
	# compact and static: the win moment is carried by the illustration, stars
	# and burst feedback rather than a hidden 3D viewport.
	var halo := PanelContainer.new()
	halo.name = "ResultIdentityHalo"
	halo.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(accent, 0.10), 42))
	FigmaReferenceCanvas.set_rect(halo, 116, 229, 156, 70)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(halo)

	var art := GAME_ART_SCRIPT.new()
	art.name = "ResultGameArt2D"
	art.configure(game_id, true, _dark_theme())
	FigmaReferenceCanvas.set_rect(art, 128, 231, 132, 67)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(art)

	for spec in [
		[112.0, 250.0, 4.0],
		[274.0, 240.0, 5.0],
		[287.0, 286.0, 3.0],
	]:
		var spark := PanelContainer.new()
		spark.name = "ResultIdentitySpark"
		spark.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(1, 0.96, 0.62, 0.82), float(spec[2])))
		FigmaReferenceCanvas.set_rect(spark, float(spec[0]), float(spec[1]), float(spec[2]) * 2.0, float(spec[2]) * 2.0)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(spark)

func _celebrate() -> void:
	if not is_inside_tree() or _motion_reduced():
		# The earned stars and readable result remain visible; skip all bursts,
		# flashes and sequential entrance animations in Reduced Motion mode.
		return
	var visuals := get_tree().root.get_node_or_null("PremiumVisuals")
	if visuals == null:
		return
	var center := get_viewport_rect().size * 0.5
	if visuals.has_method("screen_flash"):
		visuals.call("screen_flash", accent, 0.10)
	if visuals.has_method("burst"):
		visuals.call("burst", center + Vector2(0, -118), accent, 22)
		visuals.call("burst", center + Vector2(0, -72), Color("#ffd85a"), 12)
	if visuals.has_method("entrance"):
		var star_cards := _canvas.find_children("StarCard", "PanelContainer", true, false)
		for i in range(star_cards.size()):
			var card := star_cards[i] as Control
			if card != null:
				visuals.call("entrance", card, 0.07 * float(i))
		if _secondary_button != null and _secondary_button.visible:
			visuals.call("entrance", _secondary_button, 0.24)
