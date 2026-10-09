extends "res://scripts/ui/premium_live_hub.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")
const GAME_ART_SCRIPT = preload("res://scripts/ui/unjam_2d_game_art.gd")
const UNJAM_WORDMARK: Texture2D = preload("res://assets/art/brand/unjam_wordmark.svg")

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
var wide_stage: Control

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

	wide_stage = Control.new()
	wide_stage.name = "SelectorWideStage"
	wide_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wide_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wide_stage.visible = false
	add_child(wide_stage)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaSelector390x844"
	add_child(figma_canvas)
	_build_reference_selector(figma_canvas)
	if not resized.is_connected(_sync_wide_selector_stage):
		resized.connect(_sync_wide_selector_stage)
	call_deferred("_sync_wide_selector_stage")

func _sync_wide_selector_stage() -> void:
	if figma_canvas == null or not is_instance_valid(figma_canvas):
		return
	var available := size
	if available.x <= 2.0 or available.y <= 2.0:
		available = get_viewport_rect().size
	var wide := available.x >= 1180.0 and available.x / maxf(1.0, available.y) >= 1.22
	figma_canvas.set_fit_bias(0.10 if wide else 0.5, 0.5)
	if wide_stage == null or not is_instance_valid(wide_stage):
		return
	wide_stage.visible = wide
	for child in wide_stage.get_children():
		wide_stage.remove_child(child)
		child.queue_free()
	if not wide:
		return
	_build_wide_selector_stage(wide_stage, available)

func _build_wide_selector_stage(stage: Control, available: Vector2) -> void:
	var dark := _selector_dark()
	var mark_w := minf(available.x * 0.22, 520.0)
	var mark := TextureRect.new()
	mark.name = "SelectorWideWordmark"
	mark.texture = UNJAM_WORDMARK
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2(available.x * 0.60, available.y * 0.045)
	mark.size = Vector2(mark_w, mark_w * 0.265)
	stage.add_child(mark)

	var title := RefCanvas.label("CHOOSE YOUR PUZZLE", int(clampf(available.y * 0.034, 38.0, 60.0)), Color.WHITE, true)
	title.name = "SelectorWideTitle"
	RefCanvas.style_display_title(title, Color("#f7fbff"), Color("#09141f"), 3)
	title.position = Vector2(available.x * 0.55, available.y * 0.15)
	title.size = Vector2(available.x * 0.40, available.y * 0.07)
	stage.add_child(title)

	var subtitle := RefCanvas.label("RESCUE • SORT • BUILD • KEEP YOUR CAMPAIGN MOVING", int(clampf(available.y * 0.014, 18.0, 25.0)), Color("#d6e0ea") if dark else Color("#354450"), true)
	subtitle.name = "SelectorWideSubtitle"
	subtitle.position = Vector2(available.x * 0.55, available.y * 0.215)
	subtitle.size = Vector2(available.x * 0.40, available.y * 0.04)
	stage.add_child(subtitle)

	var big := minf(available.y * 0.42, available.x * 0.30)
	_add_selector_wide_art(stage, "rescue_rush", Vector2(available.x * 0.63, available.y * 0.27), Vector2(big, big))
	var small := minf(available.y * 0.29, available.x * 0.21)
	_add_selector_wide_art(stage, "water_sort", Vector2(available.x * 0.55, available.y * 0.66), Vector2(small, small))
	_add_selector_wide_art(stage, "block_puzzle", Vector2(available.x * 0.76, available.y * 0.66), Vector2(small, small))

func _add_selector_wide_art(stage: Control, game_id: String, position_value: Vector2, size_value: Vector2) -> void:
	var art := GAME_ART_SCRIPT.new()
	art.name = "SelectorWideArt_%s" % game_id
	art.configure(game_id, false, _selector_dark())
	art.position = position_value
	art.size = size_value
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(art)

func _build_reference_selector(canvas: Control) -> void:
	var background := PanelContainer.new()
	var bg_fill := Color("#202124") if _selector_dark() else Color("#e6e3dc")
	var bg_border := Color("#3d4045") if _selector_dark() else Color("#c8c3ba")
	background.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(bg_fill, 34, bg_border, 1, 0.11))
	RefCanvas.set_rect(background, 0, 0, 390, 844)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)

	var back := RefCanvas.premium_button("‹", 27, OFF_WHITE, Color("#292a2d") if _selector_dark() else Color("#d6d1c7"), 16, bg_border, 1)
	back.name = "SelectorBackButton"
	back.tooltip_text = "Back home"
	RefCanvas.set_rect(back, 17, 19, 52, 52)
	back.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	back.pressed.connect(_go_home)
	canvas.add_child(back)

	var selector_title := _add_text(canvas, "CHOOSE A GAME", Rect2(78, 26, 196, 34), 22, DARK_INK if _selector_dark() else INK, true)
	selector_title.name = "SelectorTitle3D"
	selector_title.clip_text = true
	RefCanvas.fit_single_line_text(selector_title, 192.0, 22, 14)
	var settings := RefCanvas.premium_button("⚙", 18, DARK_INK if _selector_dark() else NAVY, Color("#292a2d") if _selector_dark() else Color("#d6d1c7"), 16, bg_border, 1)
	settings.name = "SelectorSettingsButton"
	settings.tooltip_text = "Settings"
	RefCanvas.set_rect(settings, 317, 21, 52, 46)
	settings.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	canvas.add_child(settings)

	var guide := _add_text(canvas, "TAP CARD FOR LEVELS  •  PLAY TO RESUME", Rect2(25, 78, 340, 22), 12, DARK_MUTED if _selector_dark() else MUTED, false)
	guide.name = "SelectorActionGuide"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_add_game_card(canvas, "rescue_rush", Rect2(17, 111, 354, 160), Color("#21c763"), Color("#49d17f"), "RESCUE RUSH", "Tap arrows. Clear paths.")
	_add_game_card(canvas, "water_sort", Rect2(17, 285, 354, 160), Color("#1aa8ff"), Color("#43b8ff"), "WATER SORT", "Sort colours by tube.")
	_add_game_card(canvas, "block_puzzle", Rect2(17, 459, 354, 160), Color("#c73dff"), Color("#d160ff"), "BLOCK PUZZLE", "Place blocks. Clear lines.")
	_add_bottom_nav(canvas)

func _add_game_card(canvas: Control, game_id: String, rect: Rect2, accent: Color, highlight: Color, title: String, subtitle: String) -> void:
	var card_shadow := RefCanvas.add_shadow(canvas, rect, 18, Color(0.02,0.10,0.18,0.045), 1, Vector2(0,1))
	card_shadow.name = "SelectorCardShadow_%s" % game_id
	card_shadow.set_meta("unjam_figma_exact_geometry", true)
	var card := PanelContainer.new()
	card.name = "GameCard3D_%s" % game_id
	card.set_meta("unjam_figma_exact_geometry", true)
	var neutral := Color("#27282b") if _selector_dark() else Color("#f5f2ec")
	card.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(neutral, 18, Color(accent.r, accent.g, accent.b, 0.24), 1, 0.11))
	RefCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)

	var accent_rail := PanelContainer.new()
	accent_rail.name = "SelectorAccentRail_%s" % game_id
	accent_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_rail.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(accent, 2.5, Color.TRANSPARENT, 0, 0.18))
	RefCanvas.set_rect(accent_rail, rect.position.x + 4.0, rect.position.y + 18.0, 4.0, rect.size.y - 36.0)
	canvas.add_child(accent_rail)

	var game_title := _add_text(canvas, title, Rect2(34, rect.position.y + 16, 184, 27), 22, DARK_INK if _selector_dark() else INK, true)
	game_title.name = "SelectorGameTitle_%s" % game_id
	game_title.add_theme_constant_override("outline_size", 2)
	game_title.add_theme_color_override("font_outline_color", Color("#151619") if _selector_dark() else Color(1,1,1,0.84))
	RefCanvas.fit_single_line_text(game_title, 180.0, 22, 13)
	var subtitle_clip := Control.new()
	subtitle_clip.name = "SelectorGameSubtitleClip_%s" % game_id
	subtitle_clip.clip_contents = true
	subtitle_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(subtitle_clip, 34, rect.position.y + 47, 184, 34)
	canvas.add_child(subtitle_clip)
	var game_subtitle := _make_label(subtitle, 14, DARK_MUTED if _selector_dark() else MUTED, false)
	game_subtitle.name = "SelectorGameSubtitle_%s" % game_id
	game_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_subtitle.clip_text = true
	game_subtitle.position = Vector2.ZERO
	game_subtitle.size = Vector2(184, 34)
	subtitle_clip.add_child(game_subtitle)

	var level := maxi(1, MultiGameManager.highest_level(game_id))
	var level_label := _add_text(canvas, "LEVEL %d" % level, Rect2(34, rect.position.y + 108, 104, 24), 13, DARK_MUTED if _selector_dark() else MUTED, true)
	level_label.name = "SelectorLevelLabel_%s" % game_id
	_add_card_preview(canvas, game_id, rect.position.y)

	var tap := Button.new()
	tap.name = "SelectorCardHit_%s" % game_id
	tap.flat = true
	tap.focus_mode = Control.FOCUS_ALL
	tap.add_theme_stylebox_override("normal", RefCanvas.solid_box(Color.TRANSPARENT, 18))
	tap.add_theme_stylebox_override("hover", RefCanvas.solid_box(Color(accent, 0.08), 18))
	tap.add_theme_stylebox_override("pressed", RefCanvas.solid_box(Color(accent, 0.14), 18))
	tap.add_theme_stylebox_override("focus", RefCanvas.solid_box(Color.TRANSPARENT, 18, accent, 2))
	tap.accessibility_name = "Browse %s levels" % title.capitalize()
	tap.tooltip_text = "Browse %s levels" % title.capitalize()
	RefCanvas.set_rect(tap, rect.position.x - 2, rect.position.y - 3, rect.size.x + 4, rect.size.y + 6)
	tap.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	tap.pressed.connect(_browse_levels.bind(game_id))
	canvas.add_child(tap)
	# Native surface setup may clear focus/action modes while controls mount.
	# Restore them after the tree has finished configuring the selector.
	tap.set_deferred("focus_mode", Control.FOCUS_ALL)
	tap.set_deferred("action_mode", BaseButton.ACTION_MODE_BUTTON_RELEASE)
	tap.set_meta("unjam_authored_focus_mode", int(Control.FOCUS_ALL))

	var play := RefCanvas.premium_button("PLAY", 14, OFF_WHITE, accent.darkened(0.18), 13, Color(accent.r, accent.g, accent.b, 0.54), 1)
	play.name = "SelectorPlay_%s" % game_id
	play.tooltip_text = "Play %s" % title.capitalize()
	RefCanvas.set_rect(play, 151, rect.position.y + 99, 76, 44)
	RefCanvas.fit_single_line_text(play, 64.0, 14, 10)
	play.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	play.accessibility_name = "Play or resume %s" % title.capitalize()
	play.pressed.connect(_play.bind(game_id))
	canvas.add_child(play)

func _add_card_preview(canvas: Control, game_id: String, card_y: float) -> void:
	# Keep a quiet frame as a containment boundary; no depth, gloss or viewport.
	var frame := PanelContainer.new()
	frame.name = "SelectorGamePreviewFrame_%s" % game_id
	var accent := Unjam3DTheme.game_accent(game_id)
	var frame_fill := Color("#222326") if _selector_dark() else Color("#ebe7df")
	frame_fill = frame_fill.lerp(accent.darkened(0.42) if _selector_dark() else accent.lightened(0.78), 0.08)
	frame.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(frame_fill, 14, Color(accent.r,accent.g,accent.b,0.20), 1, 0.11))
	RefCanvas.set_rect(frame, 243, card_y + 23, 104, 112)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(frame)
	var art := GAME_ART_SCRIPT.new()
	art.name = "SelectorAuthoredGameArt_%s" % game_id
	art.configure(game_id, true, _selector_dark())
	RefCanvas.set_rect(art, 249, card_y + 27, 92, 104)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(art)

func _add_bottom_nav(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "SelectorBottomNav"
	var nav_fill := Color("#252629") if _selector_dark() else Color("#f0ede6")
	var nav_border := Color("#3a3d42") if _selector_dark() else Color("#cbc6bc")
	shell.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(nav_fill, 18, nav_border, 1, 0.10))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)

	var top_gloss := PanelContainer.new()
	top_gloss.name = "SelectorNavTopGloss"
	top_gloss.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(1,1,1,0.08 if _selector_dark() else 0.34), 1))
	RefCanvas.set_rect(top_gloss, 30, 760, 328, 1)
	top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_gloss)

	var items := [
		["HOME", "⌂", 22.0, 14.0, Callable(self, "_go_home"), false, Color("#ffd54f")],
		["GAMES", "▦", 94.0, 86.0, Callable(), true, Color("#ffd54f")],
		["DAILY", "★", 166.0, 158.0, func(): get_parent().call("build_daily_games"), false, Color("#ffd54f")],
		["COLLECT", "◆", 238.0, 230.0, func(): get_parent().call("build_collection"), false, Color("#ffd54f")],
		["SETTINGS", "⚙", 310.0, 302.0, func(): get_parent().call("build_settings"), false, Color("#ffd54f")],
	]
	for item in items:
		var selected: bool = bool(item[5])
		var accent: Color = item[6]
		var idle_text := Color("#98a2ad") if _selector_dark() else Color("#66707a")
		var label_color := DARK_INK if selected and _selector_dark() else (INK if selected else idle_text)
		var glyph_color := accent if selected else idle_text
		if selected:
			var plate := PanelContainer.new()
			plate.name = "SelectorNavActivePlate_%s" % String(item[0])
			plate.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(Color(accent.r,accent.g,accent.b,0.12 if _selector_dark() else 0.15), 14, Color(accent.r,accent.g,accent.b,0.40), 1, 0.16))
			RefCanvas.set_rect(plate, float(item[3]) + 7.0, 761, 58, 58)
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(plate)
			var shine := PanelContainer.new()
			shine.name = "SelectorNavActiveShine_%s" % String(item[0])
			shine.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(accent.r,accent.g,accent.b,0.82),1))
			RefCanvas.set_rect(shine, float(item[3]) + 24.0, 763, 24, 2)
			shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(shine)
		var glyph := _add_text(canvas, String(item[1]), Rect2(float(item[2]) - 1.0, 761, 58, 24), 18, glyph_color, true)
		glyph.name = "SelectorNavGlyph_%s" % String(item[0])
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var display_name := String(item[0])
		var label_width := 66.0 if String(item[0]) in ["COLLECT", "SETTINGS"] else 58.0
		var label_x := float(item[3]) + (72.0 - label_width) * 0.5
		var label := _add_text(canvas, display_name, Rect2(label_x, 803, label_width, 18), 13, label_color, selected)
		label.name = "SelectorNavLabel_%s" % String(item[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.custom_minimum_size = Vector2.ZERO
		label.position = Vector2(label_x, 803)
		label.size = Vector2(label_width, 18)
		RefCanvas.fit_single_line_text(label, label_width - 2.0, 13, 11)
		var hit := Button.new()
		hit.name = "SelectorNavHit_%s" % String(item[0])
		hit.flat = true
		hit.accessibility_name = "%s, current tab" % String(item[0]).capitalize() if selected else "Open %s tab" % String(item[0]).capitalize()
		hit.tooltip_text = "Current: %s" % String(item[0]).capitalize() if selected else "Open %s" % String(item[0]).capitalize()
		hit.focus_mode = Control.FOCUS_NONE if selected else Control.FOCUS_ALL
		# Keep overlay transparent without nearly-zero alpha: an invisible
		# hit control needs a visible high-contrast keyboard focus ring.
		hit.add_theme_stylebox_override("normal", RefCanvas.solid_box(Color.TRANSPARENT,12))
		hit.add_theme_stylebox_override("focus", RefCanvas.solid_box(Color.TRANSPARENT,12,Color(accent,0.94),2))
		hit.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		RefCanvas.set_rect(hit, float(item[3]), 753, 72, 78)
		var callback: Callable = item[4]
		if callback.is_valid():
			hit.pressed.connect(callback)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)
		if not selected:
			# Parent/theme init can reset focus on invisible navigation controls.
			hit.set_deferred("focus_mode",Control.FOCUS_ALL)

func _add_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color, bold: bool) -> Label:
	var label := _make_label(text_value, font_size, color, bold)
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return label

func _make_label(text_value: String, font_size: int, color: Color, bold: bool) -> Label:
	return RefCanvas.label(text_value, font_size, _selector_text_color(color), bold)
