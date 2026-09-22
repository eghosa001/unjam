extends "res://scripts/ui/premium_live_hub.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")
const FLAT_GAME_LOGO_SCRIPT = preload("res://scripts/ui/unjam_flat_game_logo.gd")

const BG_TOP := Color("#4f76b8")
const BG_MID := Color("#8ea8d1")
const BG_BOTTOM := Color("#315596")
const NAVY := Color("#1f2933")
const INK := Color("#26323d")
const MUTED := Color("#52606d")
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const CYAN := Color(0.14, 0.68, 1.0)
const DARK_TOP := Color("#1b2742")
const DARK_MID := Color("#131d33")
const DARK_BOTTOM := Color("#0c1324")
const DARK_INK := Color("#f5f7fa")
const DARK_MUTED := Color("#a7b1bc")
const SCENE_TOP := Color("#4f76b8")
const SCENE_MID := Color("#3f67aa")
const SCENE_BOTTOM := Color("#315596")
const DARK_SCENE_TOP := Color("#1b2742")
const DARK_SCENE_MID := Color("#1b2742")
const DARK_SCENE_BOTTOM := Color("#0c1324")

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
	var bg_border := Color("#334c78") if _selector_dark() else Color("#5ba6e8")
	background.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(bg_top, bg_mid, bg_bottom, 34, bg_border, 1, 0.48))
	RefCanvas.set_rect(background, 0, 0, 390, 844)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	RefCanvas.add_world_depth(canvas, Color("#59636f") if _selector_dark() else Color("#9aa4ae"), _selector_dark(), 0.0, "SelectorWorldDepth")
	RefCanvas.add_scene_backdrop_layers(canvas, Color("#314467") if _selector_dark() else Color("#6f8fbd"), _selector_dark(), "Selector")
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

	var selector_title := _add_text(canvas, "CHOOSE A GAME", Rect2(83, 21, 186, 28), 21, OFF_WHITE, true)
	selector_title.name = "SelectorTitle3D"
	selector_title.clip_text = true
	RefCanvas.style_display_title(selector_title, Color("#ffca45"), Color("#071d55"), 2)
	var selector_subtitle := _add_text(canvas, "3 PUZZLES • 1 JOURNEY", Rect2(83, 51, 186, 30), 12, Color("#c6d9ec") if _selector_dark() else Color("#e4edf8"), false)
	selector_subtitle.name = "SelectorSubtitle"
	selector_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selector_subtitle.clip_text = true
	RefCanvas.set_rect(selector_subtitle, 83, 51, 186, 30)

	RefCanvas.add_shadow(canvas, Rect2(285, 21, 84, 46), 23, Color(0.02,0.15,0.30,0.16), 3, Vector2(0,2))
	var settings := RefCanvas.premium_button("⚙", 18, OFF_WHITE, Color(0.03, 0.43, 0.78), 23)
	settings.name = "SelectorSettingsButton"
	settings.tooltip_text = "Settings"
	RefCanvas.set_rect(settings, 285, 21, 84, 46)
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	canvas.add_child(settings)

	_add_game_card(canvas, "rescue_rush", Rect2(17, 111, 354, 160), Color("#21c763"), Color("#49d17f"), "RESCUE RUSH", "Tap arrows. Clear paths.")
	_add_game_card(canvas, "water_sort", Rect2(17, 285, 354, 160), Color("#1aa8ff"), Color("#43b8ff"), "WATER SORT", "Sort colours by tube.")
	_add_game_card(canvas, "block_puzzle", Rect2(17, 459, 354, 160), Color("#c73dff"), Color("#d160ff"), "BLOCK PUZZLE", "Place blocks. Clear lines.")
	_add_bottom_nav(canvas)

func _add_game_card(canvas: Control, game_id: String, rect: Rect2, accent: Color, highlight: Color, title: String, subtitle: String) -> void:
	RefCanvas.add_shadow(canvas, rect, 20, Color(0.03,0.10,0.20,0.22), 8, Vector2(0,6))
	var card := PanelContainer.new()
	card.name = "GameCard3D_%s" % game_id
	card.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(highlight, accent, accent.darkened(0.18), 20, highlight.lightened(0.35), 1.6, 0.55))
	RefCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)

	var game_title := _add_text(canvas, title, Rect2(34, rect.position.y + 12.6, 184, 24), 20, OFF_WHITE, true)
	game_title.name = "SelectorGameTitle_%s" % game_id
	RefCanvas.style_display_title(game_title, Color("#fff7df"), accent.darkened(0.62), 2)
	# Keep body copy in a hard clipping region. Label intrinsic minimum size can
	# exceed its authored width for longer localized strings, so the wrapper is
	# the authoritative boundary before the 3D emblem.
	var subtitle_clip := Control.new()
	subtitle_clip.name = "SelectorGameSubtitleClip_%s" % game_id
	subtitle_clip.clip_contents = true
	subtitle_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(subtitle_clip, 34, rect.position.y + 39.6, 184, 38)
	canvas.add_child(subtitle_clip)
	var game_subtitle := _make_label(subtitle, 13, OFF_WHITE, false)
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
	var pill_mid := Color(0.04, 0.30, 0.55)
	level_pill.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(pill_mid.lightened(0.20), pill_mid, pill_mid.darkened(0.16), 13, pill_mid.lightened(0.28), 1, 0.40))
	RefCanvas.set_rect(level_pill, 33, rect.position.y + 100.7, 112, 36)
	level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(level_pill)
	var level_label := _add_text(canvas, "LEVEL %d" % level, Rect2(45, rect.position.y + 111, 88, 16), 13, OFF_WHITE, true)
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

func _add_card_preview(canvas: Control, game_id: String, card_y: float) -> void:
	var origin_y := card_y + 22.5
	var stage := PanelContainer.new()
	stage.name = "SelectorGamePreviewFrame_%s" % game_id
	var stage_mid := Color(0.92, 1.0, 0.86, 0.50) if game_id == "rescue_rush" else (Color(0.91, 0.99, 1.0, 0.54) if game_id == "water_sort" else Color(0.94, 0.91, 1.0, 0.46))
	stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(stage_mid.lightened(0.12), stage_mid, stage_mid.darkened(0.10), 16, Color(1,1,1,0.24), 1, 0.40))
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
	var nav_fill := Color("#18243b") if _selector_dark() else Color("#9fb5d5")
	var nav_border := Color("#314467") if _selector_dark() else Color("#6f8fbd")
	shell.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(nav_fill.lightened(0.12), nav_fill, nav_fill.darkened(0.10), 18, nav_border, 1, 0.40))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)

	var top_gloss := PanelContainer.new()
	top_gloss.name = "SelectorNavTopGloss"
	top_gloss.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.64,0.88,1.0,0.22 if _selector_dark() else 0.34), 1))
	RefCanvas.set_rect(top_gloss, 28, 760, 332, 2)
	top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_gloss)

	var items := [
		["HOME", "⌂", 22.0, Callable(self, "_go_home"), false, Color("#33b9ff")],
		["GAMES", "▦", 91.0, Callable(), true, Color("#7b6cff")],
		["DAILY", "✦", 150.0, func(): get_parent().call("build_daily_games"), false, Color("#ffd54f")],
		["COLLECT", "◆", 225.0, func(): get_parent().call("build_collection"), false, Color("#21c763")],
		["SETTINGS", "⚙", 310.0, func(): get_parent().call("build_settings"), false, CYAN],
	]
	for item in items:
		var selected: bool = bool(item[4])
		var accent: Color = item[5]
		var idle_text := DARK_MUTED if _selector_dark() else Color(0.31, 0.43, 0.54)
		var label_color := Color.WHITE if selected and _selector_dark() else (INK if selected else idle_text)
		var glyph_color := accent.lightened(0.18) if selected else idle_text.lightened(0.06)
		if selected:
			var plate := PanelContainer.new()
			plate.name = "SelectorNavActivePlate_%s" % String(item[0])
			var plate_fill := accent.darkened(0.50) if _selector_dark() else accent.lightened(0.34)
			var plate_border := accent.lightened(0.16) if _selector_dark() else accent.darkened(0.08)
			plate.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(plate_fill.lightened(0.14), plate_fill, plate_fill.darkened(0.12), 15, plate_border, 1.0, 0.38))
			RefCanvas.set_rect(plate, float(item[2]) - 2.0, 762, 60, 57)
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(plate)
			var shine := PanelContainer.new()
			shine.name = "SelectorNavActiveShine_%s" % String(item[0])
			shine.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(1,1,1,0.32 if _selector_dark() else 0.55),1))
			RefCanvas.set_rect(shine, float(item[2]) + 8.0, 765, 40, 2)
			shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(shine)
		var glyph := _add_text(canvas, String(item[1]), Rect2(float(item[2]) - 1.0, 764, 58, 23), 20, glyph_color, true)
		glyph.name = "SelectorNavGlyph_%s" % String(item[0])
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var display_name := "COLLECTION" if String(item[0]) == "COLLECT" else String(item[0])
		var label_width := 82.0 if String(item[0]) == "COLLECT" else (66.0 if String(item[0]) == "SETTINGS" else 58.0)
		var label_x := float(item[2]) - 12.0 if String(item[0]) == "COLLECT" else (float(item[2]) - 5.0 if String(item[0]) == "SETTINGS" else float(item[2]) - 1.0)
		var label := _add_text(canvas, display_name, Rect2(label_x, 790, label_width, 22), 13, label_color, selected)
		label.name = "SelectorNavLabel_%s" % String(item[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.custom_minimum_size = Vector2.ZERO
		label.position = Vector2(label_x, 790)
		label.size = Vector2(label_width, 22)
		var hit := Button.new()
		hit.name = "SelectorNavHit_%s" % String(item[0])
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		RefCanvas.set_rect(hit, float(item[2]) - 9.0, 753, 74 if String(item[0]) != "SETTINGS" else 80, 78)
		var callback: Callable = item[3]
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
