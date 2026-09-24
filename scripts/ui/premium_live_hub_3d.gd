extends "res://scripts/ui/premium_live_hub.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")
const FLAT_GAME_LOGO_SCRIPT = preload("res://scripts/ui/unjam_flat_game_logo.gd")

const BG_TOP := Color("#e9e5dd")
const BG_MID := Color("#b9b2a7")
const BG_BOTTOM := Color("#8f887f")
const NAVY := Color("#252a30")
const INK := Color("#26323d")
const MUTED := Color("#62676e")
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const CYAN := Color(0.14, 0.68, 1.0)
const DARK_TOP := Color("#363636")
const DARK_MID := Color("#272727")
const DARK_BOTTOM := Color("#1f1f1f")
const DARK_INK := Color("#f5f7fa")
const DARK_MUTED := Color("#a7b1bc")
const SCENE_TOP := Color("#e4dfd5")
const SCENE_MID := Color("#b3aca2")
const SCENE_BOTTOM := Color("#80786e")
const DARK_SCENE_TOP := Color("#363636")
const DARK_SCENE_MID := Color("#272727")
const DARK_SCENE_BOTTOM := Color("#1f1f1f")

var figma_canvas: FigmaReferenceCanvas

func _selector_dark() -> bool:
	return _theme_mode() == "dark"

func _selector_text_color(color: Color) -> Color:
	if not _selector_dark():
		return color
	if color.is_equal_approx(NAVY) or color.is_equal_approx(INK):
		return DARK_INK
	if color.is_equal_approx(MUTED):
		return DARK_MUTED
	if color.get_luminance() < 0.34:
		return color.lightened(0.48)
	return color.lightened(0.06)

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	built = true
	last_theme = _theme_mode()
	clip_contents = true

	var viewport_bg := ColorRect.new()
	viewport_bg.name = "FigmaSelectorViewportBackground"
	viewport_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_bg.color = DARK_BOTTOM if _selector_dark() else BG_BOTTOM
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaSelector390x844"
	add_child(figma_canvas)
	_build_reference_selector(figma_canvas)

func _build_reference_selector(canvas: Control) -> void:
	var background := PanelContainer.new()
	var bg_top := DARK_SCENE_TOP if _selector_dark() else SCENE_TOP
	var bg_mid := DARK_SCENE_MID if _selector_dark() else SCENE_MID
	var bg_bottom := DARK_SCENE_BOTTOM if _selector_dark() else SCENE_BOTTOM
	var bg_border := Color("#5b5347") if _selector_dark() else Color("#d2b06a")
	background.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(bg_top, bg_mid, bg_bottom, 34, bg_border, 1, 0.48))
	RefCanvas.set_rect(background, 0, 0, 390, 844)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	RefCanvas.add_world_depth(canvas, Color("#59636f") if _selector_dark() else Color("#9aa4ae"), _selector_dark(), 0.0, "SelectorWorldDepth")
	RefCanvas.add_scene_backdrop_layers(canvas, Color("#5b5347") if _selector_dark() else Color("#b7aa91"), _selector_dark(), "Selector")
	var selector_key_light := canvas.get_node_or_null("SelectorKeyLight")
	if selector_key_light != null:
		selector_key_light.set_meta("unjam_figma_scene_light", true)

	RefCanvas.add_shadow(canvas, Rect2(17, 19, 52, 52), 18, Color(0.02,0.15,0.30,0.24), 4, Vector2(0,3))
	var back := RefCanvas.premium_button("‹", 27, OFF_WHITE, Color("#101a31") if _selector_dark() else Color("#152b52"), 18)
	back.name = "SelectorBackButton"
	back.tooltip_text = "Back home"
	RefCanvas.set_rect(back, 17, 19, 52, 52)
	back.pressed.connect(_go_home)
	canvas.add_child(back)

	var selector_title := _add_text(canvas, "CHOOSE A GAME", Rect2(78, 26, 196, 34), 22, OFF_WHITE, true)
	selector_title.name = "SelectorTitle3D"
	selector_title.clip_text = true
	RefCanvas.style_display_title(selector_title, Color("#ffca45"), Color("#071d55"), 2)
	RefCanvas.add_shadow(canvas, Rect2(285, 21, 84, 46), 23, Color(0.02,0.15,0.30,0.16), 3, Vector2(0,2))
	var settings := RefCanvas.premium_button("⚙", 18, NAVY if not _selector_dark() else OFF_WHITE, Color("#cbc4b8") if not _selector_dark() else Color("#2c2c2c"), 23, Color("#b3aca2"), 1.1)
	settings.name = "SelectorSettingsButton"
	settings.tooltip_text = "Settings"
	RefCanvas.set_rect(settings, 285, 21, 84, 46)
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	canvas.add_child(settings)

	_add_game_card(canvas, "rescue_rush", Rect2(17, 111, 354, 160), Color("#21c763"), Color("#49d17f"), "RESCUE RUSH", "Tap arrows. Clear paths.")
	_add_game_card(canvas, "water_sort", Rect2(17, 285, 354, 160), Color("#1aa8ff"), Color("#43b8ff"), "WATER SORT", "Sort colours by tube.")
	_add_game_card(canvas, "block_puzzle", Rect2(17, 459, 354, 160), Color("#c73dff"), Color("#d160ff"), "BLOCK PUZZLE", "Place blocks. Clear lines.")
	_add_retention_access(canvas)
	_add_bottom_nav(canvas)

func _add_retention_access(canvas: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "SelectorRewardsPanel"
	var fill := Color("#2a2a2a") if _selector_dark() else Color("#d8d4cc")
	panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(fill.lightened(0.10), fill, fill.darkened(0.10), 18, Color("#e1b94f"), 1.2, 0.36))
	RefCanvas.set_rect(panel, 17, 638, 354, 82)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	var title := _add_text(canvas, "REWARDS & EVENTS", Rect2(31, 650, 184, 20), 16, OFF_WHITE if _selector_dark() else INK, true)
	title.name = "SelectorRewardsTitle"
	var detail := _add_text(canvas, "MISSIONS • LEAGUE • SEASON", Rect2(31, 676, 226, 19), 12, DARK_MUTED if _selector_dark() else MUTED, true)
	detail.clip_text = true
	var open := RefCanvas.premium_button("OPEN", 13, OFF_WHITE, Color("#9a6f18"), 15, Color("#f2cf65"), 1.1)
	open.name = "SelectorRewardsOpenButton"
	open.tooltip_text = "Open Rescue rewards, missions, league, season, achievements and event shop"
	RefCanvas.set_rect(open, 271, 655, 82, 42)
	open.pressed.connect(func() -> void: LiveHubLauncher.open_hub())
	canvas.add_child(open)

func _add_game_card(canvas: Control, game_id: String, rect: Rect2, accent: Color, highlight: Color, title: String, subtitle: String) -> void:
	var card_shadow := RefCanvas.add_shadow(canvas, rect, 20, Color(0.03,0.10,0.20,0.22), 8, Vector2(0,6))
	card_shadow.name = "SelectorCardShadow_%s" % game_id
	var card := PanelContainer.new()
	card.name = "GameCard3D_%s" % game_id
	var neutral_top := Color("#2c2c2c") if _selector_dark() else Color("#dedad2")
	var neutral_mid := Color("#252525") if _selector_dark() else Color("#d8d4cc")
	var neutral_bottom := Color("#1f1f1f") if _selector_dark() else Color("#cec8be")
	card.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(neutral_top, neutral_mid, neutral_bottom, 20, Color(accent,0.58), 1.2, 0.26))
	RefCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)

	var game_title := _add_text(canvas, title, Rect2(34, rect.position.y + 11.6, 184, 27), 22, DARK_INK if _selector_dark() else INK, true)
	game_title.name = "SelectorGameTitle_%s" % game_id
	game_title.add_theme_color_override("font_color", DARK_INK if _selector_dark() else INK)
	game_title.add_theme_constant_override("outline_size", 2)
	game_title.add_theme_color_override("font_outline_color", Color("#11151a") if _selector_dark() else Color(1, 1, 1, 0.72))
	# Keep body copy in a hard clipping region. Label intrinsic minimum size can
	# exceed its authored width for longer localized strings, so the wrapper is
	# the authoritative boundary before the 3D emblem.
	var subtitle_clip := Control.new()
	subtitle_clip.name = "SelectorGameSubtitleClip_%s" % game_id
	subtitle_clip.clip_contents = true
	subtitle_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(subtitle_clip, 34, rect.position.y + 39.6, 184, 38)
	canvas.add_child(subtitle_clip)
	var game_subtitle := _make_label(subtitle, 14, DARK_MUTED if _selector_dark() else MUTED, false)
	game_subtitle.name = "SelectorGameSubtitle_%s" % game_id
	game_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_subtitle.clip_text = true
	game_subtitle.custom_minimum_size = Vector2.ZERO
	game_subtitle.position = Vector2.ZERO
	game_subtitle.size = Vector2(184, 38)
	subtitle_clip.add_child(game_subtitle)
	var level := maxi(1, MultiGameManager.highest_level(game_id))
	RefCanvas.add_shadow(canvas, Rect2(33, rect.position.y + 100.7, 112, 36), 13, Color(0.02,0.10,0.20,0.16), 3, Vector2(0,2))
	var level_pill := PanelContainer.new()
	var pill_mid := Color("#2c2c2c") if _selector_dark() else Color("#cec8be")
	level_pill.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(pill_mid.lightened(0.04), pill_mid, pill_mid.darkened(0.04), 13, Color(accent,0.42), 1, 0.24))
	RefCanvas.set_rect(level_pill, 33, rect.position.y + 100.7, 112, 36)
	level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(level_pill)
	var level_label := _add_text(canvas, "LEVEL %d" % level, Rect2(45, rect.position.y + 109, 88, 19), 14, DARK_INK if _selector_dark() else INK, true)
	level_label.name = "SelectorLevelLabel_%s" % game_id
	_add_card_preview(canvas, game_id, rect.position.y)

	var tap := Button.new()
	tap.name = "SelectorCardHit_%s" % game_id
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.modulate.a = 0.001
	RefCanvas.set_rect(tap, rect.position.x - 2, rect.position.y - 5, rect.size.x + 4, rect.size.y + 10)
	tap.pressed.connect(_play.bind(game_id))
	canvas.add_child(tap)

	var play := RefCanvas.premium_button("PLAY", 14, OFF_WHITE, accent.darkened(0.22), 14, accent.lightened(0.18), 1.1)
	play.name = "SelectorPlay_%s" % game_id
	play.tooltip_text = "Play %s" % title.capitalize()
	RefCanvas.set_rect(play, 153, rect.position.y + 96, 74, 44)
	play.pressed.connect(_play.bind(game_id))
	canvas.add_child(play)

func _add_card_preview(canvas: Control, game_id: String, card_y: float) -> void:
	var origin_y := card_y + 22.5
	var stage := PanelContainer.new()
	stage.name = "SelectorGamePreviewFrame_%s" % game_id
	var stage_mid := Color("#252525") if _selector_dark() else Color("#d6d1c7")
	stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(stage_mid.lightened(0.05), stage_mid, stage_mid.darkened(0.05), 16, Color(1,1,1,0.16), 1, 0.24))
	RefCanvas.set_rect(stage, 243, origin_y, 104, 112)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(stage)
	var mark := FLAT_GAME_LOGO_SCRIPT.new()
	mark.name = "SelectorFlatGameLogo_%s" % game_id
	mark.configure(game_id)
	RefCanvas.set_rect(mark, 252, origin_y + 9, 86, 94)
	canvas.add_child(mark)

func _add_bottom_nav(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "SelectorBottomNav"
	RefCanvas.add_shadow(canvas, Rect2(13, 757, 362, 70), 18, Color(0.02,0.10,0.18,0.16), 5, Vector2(0,4))
	var nav_fill := Color("#232323") if _selector_dark() else Color("#bcb5a9")
	var nav_border := Color("#5b5347") if _selector_dark() else Color("#d2b06a")
	shell.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(nav_fill.lightened(0.12), nav_fill, nav_fill.darkened(0.10), 18, nav_border, 1, 0.40))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)

	var top_gloss := PanelContainer.new()
	top_gloss.name = "SelectorNavTopGloss"
	top_gloss.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(1.0,0.94,0.78,0.18 if _selector_dark() else 0.30), 1))
	RefCanvas.set_rect(top_gloss, 28, 760, 332, 2)
	top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_gloss)

	var items := [
		["HOME", "⌂", 22.0, 14.0, Callable(self, "_go_home"), false, Color("#ffd54f")],
		["GAMES", "▦", 94.0, 86.0, Callable(), true, Color("#ffd54f")],
		["DAILY", "✦", 166.0, 158.0, func(): get_parent().call("build_daily_games"), false, Color("#ffd54f")],
		["COLLECT", "◆", 238.0, 230.0, func(): get_parent().call("build_collection"), false, Color("#ffd54f")],
		["SETTINGS", "⚙", 310.0, 302.0, func(): get_parent().call("build_settings"), false, Color("#ffd54f")],
	]
	for item in items:
		var selected: bool = bool(item[5])
		var accent: Color = item[6]
		var idle_text := DARK_MUTED if _selector_dark() else Color(0.31, 0.43, 0.54)
		var label_color := Color.WHITE if selected and _selector_dark() else (INK if selected else idle_text)
		var glyph_color := accent.lightened(0.18) if selected else idle_text.lightened(0.06)
		if selected:
			var plate := PanelContainer.new()
			plate.name = "SelectorNavActivePlate_%s" % String(item[0])
			var plate_fill := accent.darkened(0.50) if _selector_dark() else accent.lightened(0.34)
			var plate_border := accent.lightened(0.16) if _selector_dark() else accent.darkened(0.08)
			plate.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(plate_fill.lightened(0.14), plate_fill, plate_fill.darkened(0.12), 15, plate_border, 1.0, 0.38))
			RefCanvas.set_rect(plate, float(item[3]) + 6.0, 762, 60, 57)
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(plate)
			var shine := PanelContainer.new()
			shine.name = "SelectorNavActiveShine_%s" % String(item[0])
			shine.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(1,1,1,0.32 if _selector_dark() else 0.55),1))
			RefCanvas.set_rect(shine, float(item[3]) + 16.0, 765, 40, 2)
			shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(shine)
		var glyph := _add_text(canvas, String(item[1]), Rect2(float(item[2]) - 1.0, 763, 58, 24), 21, glyph_color, true)
		glyph.name = "SelectorNavGlyph_%s" % String(item[0])
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var display_name := String(item[0])
		var label_width := 66.0 if String(item[0]) in ["COLLECT", "SETTINGS"] else 58.0
		var label_x := float(item[3]) + (72.0 - label_width) * 0.5
		var label := _add_text(canvas, display_name, Rect2(label_x, 789, label_width, 24), 14, label_color, selected)
		label.name = "SelectorNavLabel_%s" % String(item[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.custom_minimum_size = Vector2.ZERO
		label.position = Vector2(label_x, 789)
		label.size = Vector2(label_width, 24)
		var hit := Button.new()
		hit.name = "SelectorNavHit_%s" % String(item[0])
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		RefCanvas.set_rect(hit, float(item[3]), 753, 72, 78)
		var callback: Callable = item[4]
		if callback.is_valid():
			hit.pressed.connect(callback)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)

func _add_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color, bold: bool) -> Label:
	var label := _make_label(text_value, font_size, color, bold)
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return label

func _make_label(text_value: String, font_size: int, color: Color, bold: bool) -> Label:
	return RefCanvas.label(text_value, font_size, _selector_text_color(color), bold)
