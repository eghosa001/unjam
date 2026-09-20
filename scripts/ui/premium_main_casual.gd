extends "res://scripts/ui/premium_main.gd"

const FIGMA_LEVEL_PAGE_SIZE := 20
const FIGMA_BG_TOP := Color("#dcebe8")
const FIGMA_BG_MID := Color("#d4e3e8")
const FIGMA_BG_BOTTOM := Color("#c3d2df")
const FIGMA_NAVY := Color(0.03, 0.23, 0.47)
const FIGMA_INK := Color(0.07, 0.20, 0.35)
const FIGMA_MUTED := Color(0.31, 0.42, 0.52)
const FIGMA_OFF_WHITE := Color(1.0, 0.995, 0.97)
const FIGMA_BLUE := Color(0.03, 0.43, 0.78)
const FIGMA_GREEN := Color(0.13, 0.78, 0.39)
const FIGMA_CYAN := Color(0.14, 0.68, 1.0)
const FIGMA_ORANGE := Color(1.0, 0.55, 0.12)
const FIGMA_GOLD := Color(1.0, 0.84, 0.24)
const FIGMA_PURPLE := Color(0.78, 0.24, 1.0)

const FIGMA_DARK_TOP := Color("#182a3b")
const FIGMA_DARK_MID := Color("#20384b")
const FIGMA_DARK_BOTTOM := Color("#29465b")
const FIGMA_DARK_CARD := Color("#223b50")
const FIGMA_DARK_INK := Color("#eef7ff")
const FIGMA_DARK_MUTED := Color("#b6c7d6")

var _collection_scroll_tracking := false
var _collection_scroll_origin_y := 0.0


func _figma_theme_text(color: Color) -> Color:
	if not _dark():
		return color
	if color.is_equal_approx(FIGMA_INK) or color.is_equal_approx(FIGMA_NAVY):
		return FIGMA_DARK_INK
	if color.is_equal_approx(FIGMA_MUTED):
		return FIGMA_DARK_MUTED
	if color.get_luminance() < 0.34:
		return color.lightened(0.48)
	return color.lightened(0.06)


func _figma_theme_card(accent: Color, fallback: Color = FIGMA_DARK_CARD) -> Color:
	var opaque_accent := Color(accent.r, accent.g, accent.b, 1.0)
	return fallback.lerp(opaque_accent.darkened(0.38), 0.12)


func _sync_persistent_surfaces_now(surface: String) -> void:
	var home := get_node_or_null("PremiumHome")
	if home != null and home.has_method("_on_surface_changed"):
		home.call("_on_surface_changed", surface)
	var live := get_node_or_null("PremiumLive")
	if live != null and live.has_method("_on_surface_changed"):
		live.call("_on_surface_changed", surface)

func build_home() -> void:
	# Base navigation replaces/removes the outgoing surface immediately. Bring the
	# persistent premium surfaces into their final visibility state before this
	# call returns so Settings/Collection/Game -> Home cannot expose a blank frame
	# while robust_main's surface_changed signal is waiting for its deferred emit.
	super.build_home()
	var live := get_node_or_null("PremiumLive")
	if live != null and live.has_method("_on_surface_changed"):
		live.call("_on_surface_changed", "home")
	var home := get_node_or_null("PremiumHome")
	if home != null and home.has_method("_on_surface_changed"):
		home.call("_on_surface_changed", "home")

func add_background() -> void:
	# Base level builders call add_background() directly. Override it so every
	# secondary surface uses the final bright backdrop without allocating the
	# retired PremiumBackdrop first.
	if content == null or not is_instance_valid(content):
		return
	content.clip_contents = true
	var existing := content.get_node_or_null("Unjam3DSurfaceBackdrop") as Unjam3DBackdrop
	if existing == null:
		existing = Unjam3DBackdrop.new()
		existing.name = "Unjam3DSurfaceBackdrop"
		existing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		existing.z_index = -100
		content.add_child(existing)
		content.move_child(existing, 0)
	existing.configure(_accent(), _dark())

func _page_root() -> VBoxContainer:
	clear_content()
	add_background()
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport_rect().size
	var side_margin := 46 if viewport_size.x >= 760.0 else 28
	outer.add_theme_constant_override("margin_left", side_margin)
	outer.add_theme_constant_override("margin_right", side_margin)
	outer.add_theme_constant_override("margin_top", 34 if viewport_size.y >= 1400.0 else 24)
	var bottom_margin := 34 if viewport_size.y >= 1400.0 else 24
	if current_surface in ["daily", "collection", "settings"]:
		bottom_margin = 136 if viewport_size.y >= 1400.0 else 114
	outer.add_theme_constant_override("margin_bottom", bottom_margin)
	content.add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)
	return root

func _figma_surface(active: String, bottom_tint: Color = FIGMA_BG_BOTTOM, top_tint: Color = FIGMA_BG_TOP) -> FigmaReferenceCanvas:
	clear_content()
	content.visible = true
	content.mouse_filter = Control.MOUSE_FILTER_STOP
	# Every menu starts from a premium neutral palette, then receives only a faint
	# hint of the requested surface tint. This avoids flat white/black pages while
	# keeping game-specific greens/blues/purples visually dominant.
	var opaque_bottom := Color(bottom_tint.r, bottom_tint.g, bottom_tint.b, 1.0)
	var opaque_top := Color(top_tint.r, top_tint.g, top_tint.b, 1.0)
	var resolved_bottom := FIGMA_DARK_BOTTOM.lerp(opaque_bottom, 0.07) if _dark() else FIGMA_BG_BOTTOM.lerp(opaque_bottom, 0.16)
	var resolved_top := FIGMA_DARK_TOP.lerp(opaque_top, 0.06) if _dark() else FIGMA_BG_TOP.lerp(opaque_top, 0.12)
	var viewport_bg := ColorRect.new()
	viewport_bg.name = "FigmaSurfaceViewportBackground"
	viewport_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_bg.color = resolved_bottom
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(viewport_bg)
	var canvas := FigmaReferenceCanvas.new()
	canvas.name = "FigmaSurface390x844"
	content.add_child(canvas)
	var bg := PanelContainer.new()
	bg.name = "FigmaSurfaceBackground"
	var mid_tint := FIGMA_BG_MID if not _dark() else resolved_top.lerp(resolved_bottom, 0.48)
	bg.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(resolved_top, mid_tint, resolved_bottom, 34, Color("#bad1e3") if not _dark() else Color(0.22,0.36,0.48,0.82), 1, 0.48))
	FigmaReferenceCanvas.set_rect(bg, 0, 0, 390, 844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	var halo_top := PanelContainer.new()
	halo_top.name = "SurfaceBackdropHaloTop"
	halo_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo_top.modulate.a = 0.20 if not _dark() else 0.16
	halo_top.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color("#8fb9bd") if not _dark() else Color("#52758a"), 110))
	FigmaReferenceCanvas.set_rect(halo_top, 268, -68, 205, 205)
	canvas.add_child(halo_top)
	canvas.move_child(halo_top, 1)

	var halo_bottom := PanelContainer.new()
	halo_bottom.name = "SurfaceBackdropHaloBottom"
	halo_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo_bottom.modulate.a = 0.16 if not _dark() else 0.13
	halo_bottom.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color("#9bafc4") if not _dark() else Color("#456579"), 100))
	FigmaReferenceCanvas.set_rect(halo_bottom, -76, 632, 188, 188)
	canvas.add_child(halo_bottom)
	canvas.move_child(halo_bottom, 1)

	var ribbon := Polygon2D.new()
	ribbon.name = "SurfaceBackdropRibbon"
	ribbon.polygon = PackedVector2Array([Vector2(-32,330),Vector2(420,235),Vector2(420,296),Vector2(-32,390)])
	ribbon.color = Color("#7198a4", 0.065 if not _dark() else 0.085)
	canvas.add_child(ribbon)
	canvas.move_child(ribbon, 1)

	# Large-scale specular sweep: premium casual games use a readable light roll
	# across whole screens in addition to glossy cards. Keep it static and subtle
	# so it adds lacquer/depth without costing frames on low-end phones.
	var gloss_sweep := Polygon2D.new()
	gloss_sweep.name = "SurfaceGlossSweep"
	gloss_sweep.polygon = PackedVector2Array([Vector2(-45,118),Vector2(435,22),Vector2(435,118),Vector2(-45,226)])
	gloss_sweep.color = Color(1,1,1,0.050 if _dark() else 0.085)
	canvas.add_child(gloss_sweep)
	canvas.move_child(gloss_sweep, 2)

	var lower_depth := Polygon2D.new()
	lower_depth.name = "SurfaceLowerDepth"
	lower_depth.polygon = PackedVector2Array([Vector2(-30,692),Vector2(430,604),Vector2(430,844),Vector2(-30,844)])
	lower_depth.color = Color(0.01,0.06,0.10,0.055 if _dark() else 0.035)
	canvas.add_child(lower_depth)
	canvas.move_child(lower_depth, 2)
	return canvas

func _figma_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color = FIGMA_INK, center := false) -> Label:
	var label := FigmaReferenceCanvas.label(text_value, font_size, _figma_theme_text(color), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	FigmaReferenceCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return label

func _figma_button(canvas: Control, name_value: String, text_value: String, rect: Rect2, fill: Color, callback: Callable, text_color: Color = FIGMA_OFF_WHITE, radius: float = 14.0, font_size: int = 12) -> Button:
	FigmaReferenceCanvas.add_shadow(canvas, rect, radius, Color(0.02,0.10,0.18,0.20 if _dark() else 0.16), 4, Vector2(0,3))
	var resolved_fill := fill
	var resolved_text := text_color
	if _dark() and fill.get_luminance() > 0.82:
		resolved_fill = _figma_theme_card(fill, Color("#152337"))
		resolved_text = FIGMA_DARK_INK
	var button := FigmaReferenceCanvas.premium_button(text_value, font_size, resolved_text, resolved_fill, radius, resolved_fill.lightened(0.20), 1.2)
	button.name = name_value
	FigmaReferenceCanvas.set_rect(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	if callback.is_valid():
		button.pressed.connect(callback)
	canvas.add_child(button)
	return button

func _figma_card(canvas: Control, name_value: String, rect: Rect2, tint: Color = Color(1.0, 0.995, 0.97), accent: Color = Color(0.70, 0.88, 0.96, 0.45), radius: float = 16.0) -> PanelContainer:
	FigmaReferenceCanvas.add_shadow(canvas, rect, radius, Color(0.01,0.04,0.08,0.30 if _dark() else 0.16), 5, Vector2(0,4))
	var card := PanelContainer.new()
	card.name = name_value
	var resolved_tint := _figma_theme_card(accent) if _dark() else tint
	var resolved_accent := Color(accent.r, accent.g, accent.b, 0.78) if _dark() else accent
	card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(resolved_tint.lightened(0.025), resolved_tint, resolved_tint.darkened(0.07), radius, resolved_accent, 1.2, 0.48))
	FigmaReferenceCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)
	return card

func _figma_solid_card(canvas: Control, name_value: String, rect: Rect2, tint: Color, border: Color, radius: float = 16.0, with_shadow: bool = true) -> PanelContainer:
	if with_shadow:
		FigmaReferenceCanvas.add_shadow(canvas, rect, radius, Color(0.01,0.04,0.08,0.28 if _dark() else 0.14), 4, Vector2(0,3))
	var card := PanelContainer.new()
	card.name = name_value
	var resolved_tint := tint
	var resolved_border := border
	if _dark() and tint.get_luminance() > 0.72:
		resolved_tint = _figma_theme_card(border, Color("#132033"))
		resolved_border = Color(border.r, border.g, border.b, 0.78)
	var gloss_top := resolved_tint.lightened(0.16 if _dark() else 0.11)
	var gloss_mid := resolved_tint.lightened(0.025)
	var gloss_bottom := resolved_tint.darkened(0.13 if _dark() else 0.08)
	card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(gloss_top, gloss_mid, gloss_bottom, radius, resolved_border, 1, 0.40))
	FigmaReferenceCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)
	return card

func _figma_header(canvas: Control, title_text: String, subtitle_text: String, pill_text: String, pill_fill: Color, back_callback: Callable = Callable(self, "build_home"), pill_callback: Callable = Callable(), dark_mode: bool = false) -> void:
	var use_dark := dark_mode or _dark()
	var heading_color := FIGMA_DARK_INK if use_dark else FIGMA_INK
	var muted_color := FIGMA_DARK_MUTED if use_dark else FIGMA_MUTED
	var back_color := muted_color if use_dark else FIGMA_NAVY
	var back_fill := Color("#152337") if use_dark else Color(1.0,0.995,0.97)
	_figma_button(canvas, "FigmaBack", "‹", Rect2(17,19,52,52), back_fill, back_callback, back_color, 18, 27)
	var header_title := _figma_text(canvas, title_text, Rect2(83,21,205,28), 23, heading_color)
	header_title.name = "FigmaHeaderTitle"
	var subtitle := _figma_text(canvas, subtitle_text, Rect2(83,51,210,30), 12, muted_color)
	subtitle.name = "FigmaHeaderSubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pill_callback.is_valid():
		var pill_button := _figma_button(canvas, "FigmaHeaderPill", pill_text, Rect2(285,21,84,46), pill_fill, pill_callback, FIGMA_DARK_INK if use_dark else FIGMA_OFF_WHITE, 23, 12)
		if pill_text.begins_with("◈"):
			pill_button.set_meta("unjam_figma_wallet_pill", true)
			pill_button.tooltip_text = "Coins: %d • Open Shop" % EconomyManager.balance()
			if not EconomyManager.balance_changed.is_connected(_on_figma_wallet_balance_changed):
				EconomyManager.balance_changed.connect(_on_figma_wallet_balance_changed)
	else:
		var pill: PanelContainer
		if use_dark:
			pill = _figma_solid_card(canvas, "FigmaHeaderPill", Rect2(285,21,84,46), pill_fill, pill_fill, 23)
		else:
			pill = _figma_solid_card(canvas, "FigmaHeaderPill", Rect2(285,21,84,46), pill_fill, pill_fill.lightened(0.24), 23)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pill_label := _figma_text(canvas, pill_text, Rect2(297,29,60,30), 12, FIGMA_DARK_INK if use_dark else FIGMA_OFF_WHITE, true)
		pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _on_figma_wallet_balance_changed(new_balance: int, _delta: int, _reason: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	for node in content.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and bool(button.get_meta("unjam_figma_wallet_pill", false)):
			button.tooltip_text = "Coins: %d • Open Shop" % new_balance

func _figma_open_shop() -> void:
	var hub := get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		FeedbackManager.tap()
		hub.call("open_shop")

func _figma_bottom_nav(canvas: Control, active: String, dark_mode: bool = false) -> void:
	var use_dark := dark_mode or _dark()
	var bar_fill := Color(0.07,0.10,0.17,0.98) if use_dark else Color(0.985,0.995,1.0)
	var bar_border := Color(0.23,0.34,0.45,0.90) if use_dark else Color(0.78,0.88,0.95,0.75)
	if use_dark:
		_figma_solid_card(canvas, "StdNav/Bar", Rect2(13,757,362,70), bar_fill, bar_border, 18)
	else:
		_figma_card(canvas, "StdNav/Bar", Rect2(13,757,362,70), bar_fill, bar_border, 18)
	var xs := {"home":22.0, "games":91.0, "daily":160.0, "collection":229.0, "settings":298.0}
	var names := {"home":"HOME", "games":"GAMES", "daily":"DAILY", "collection":"COLLECT", "settings":"SETTINGS"}
	var callbacks := {
		"home": Callable(self,"build_home"),
		"games": Callable(self,"_open_games_surface"),
		"daily": Callable(self,"build_daily_games"),
		"collection": Callable(self,"build_collection"),
		"settings": Callable(self,"build_settings"),
	}
	var hit_x := {"home":14.0, "games":84.0, "daily":153.0, "collection":222.0, "settings":291.0}
	for key in ["home","games","daily","collection","settings"]:
		var selected: bool = String(key) == active
		var selected_text := Color(0.42,0.78,1.0) if use_dark else Color(0.05,0.49,0.86)
		var idle_text := Color(0.62,0.72,0.80) if use_dark else FIGMA_MUTED
		if selected:
			var marker_color := Color(0.32,0.75,1.0) if use_dark else FIGMA_CYAN
			_figma_solid_card(canvas, "StdNavSelectedDot_%s" % String(key), Rect2(float(xs[key])+25.0,776,8,8), marker_color, marker_color, 4, false)
			_figma_solid_card(canvas, "StdNavSelectedLine_%s" % String(key), Rect2(float(xs[key])+11.0,815,36,4), marker_color, marker_color, 2, false)
		var nav_label := _figma_text(canvas, String(names[key]), Rect2(float(xs[key])-1.0,787,58,28), 13, selected_text if selected else idle_text, true)
		nav_label.name = "StdNavLabel_%s" % String(key)
		var hit := Button.new()
		hit.name = "StdNav/Proto/%s" % String(names[key])
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		FigmaReferenceCanvas.set_rect(hit, float(hit_x[key])-1.0,753,74 if key != "settings" else 80,78)
		if not selected:
			var cb: Callable = callbacks[key]
			hit.pressed.connect(cb)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)

func build_settings() -> void:
	current_surface = "settings"
	_remove_active_game()
	var shell := get_node_or_null("UXShell")
	var theme_name := "LIGHT"
	if shell != null and shell.get("theme_mode") != null:
		theme_name = String(shell.get("theme_mode")).to_upper()
	var dark_mode := theme_name == "DARK"

	var canvas := _figma_surface(
		"settings",
		FIGMA_DARK_BOTTOM if dark_mode else FIGMA_BG_BOTTOM,
		FIGMA_DARK_TOP if dark_mode else FIGMA_BG_TOP
	)
	_figma_header(canvas, "SETTINGS", "Make UNJAM feel right for you", "AUTO-SAVE", Color("#1aa8ff"), Callable(self,"build_home"), Callable(), dark_mode)
	if not dark_mode:
		var settings_title := canvas.get_node_or_null("FigmaHeaderTitle") as Label
		if settings_title != null:
			settings_title.add_theme_color_override("font_color",Color("#0d7ddb"))

	var card_fill := Color(0.09,0.13,0.21,0.96) if dark_mode else Color("#fffef8")
	var card_border := Color(0.22,0.36,0.48,0.72) if dark_mode else Color(0.51,0.77,0.95,0.32)
	var heading_color := Color(0.91,0.97,1.0) if dark_mode else FIGMA_INK
	var muted_color := Color(0.76,0.84,0.90) if dark_mode else FIGMA_INK

	_figma_settings_card(canvas,"SettingsCard/Sound",Rect2(17,91,354,170),card_fill,card_border,dark_mode)
	_figma_text(canvas,"♫  SOUND & FEEL",Rect2(33,107,160,18),15,Color("#086ec7") if not dark_mode else heading_color)
	_figma_setting_row(canvas,"sound","SOUND EFFECTS",130,142,true,false,dark_mode)
	_figma_setting_row(canvas,"music","MUSIC",178,190,true,false,dark_mode)
	_figma_setting_row(canvas,"vibration","HAPTICS",226,238,true,false,dark_mode)

	_figma_settings_card(canvas,"SettingsCard/Comfort",Rect2(17,275,354,120),card_fill,card_border,dark_mode)
	_figma_text(canvas,"✦  COMFORT",Rect2(33,291,130,18),15,Color("#088c3d") if not dark_mode else heading_color)
	_figma_setting_row(canvas,"reduce_motion","REDUCED MOTION",314,326,false,true,dark_mode)
	_figma_setting_row(canvas,"fast_animation","FAST ANIMATION",358,370,false,false,dark_mode)

	_figma_settings_card(canvas,"SettingsCard/Appearance",Rect2(17,409,354,76),card_fill,card_border,dark_mode)
	_figma_text(canvas,"☀  APPEARANCE",Rect2(33,425,150,18),15,Color("#ff8c1f") if not dark_mode else heading_color)
	_figma_text(canvas,"THEME",Rect2(33,448,210,28),13,muted_color)
	var theme_fill := FIGMA_ORANGE
	var theme_text := Color(0.76,0.84,0.90) if dark_mode else FIGMA_OFF_WHITE
	var theme_button := _figma_button(canvas,"SettingToggle/Theme",theme_name,Rect2(279,442,72,38),theme_fill,Callable(),theme_text,19,12)
	theme_button.pressed.connect(func() -> void:
		if shell != null and shell.has_method("_toggle_theme"):
			shell.call("_toggle_theme")
		call_deferred("build_settings")
	)

	var help_card: PanelContainer
	if dark_mode:
		help_card = _figma_solid_card(canvas,"HelpPrivacy",Rect2(17,499,354,94),card_fill,card_border,18)
	else:
		help_card = _figma_solid_card(canvas,"HelpPrivacy",Rect2(17,499,354,94),Color("#fffef7"),Color("#1aa8ff"),18)
		help_card.modulate.a = 0.70
	_figma_text(canvas,"?  HELP & PRIVACY",Rect2(33,515,170,18),15,Color("#086ec7") if not dark_mode else heading_color)
	var utility_fill := Color(0.12,0.18,0.28,0.96) if dark_mode else FIGMA_BLUE
	var utility_border := Color(0.26,0.43,0.57,0.72) if dark_mode else utility_fill.lightened(0.24)
	var utility_text := Color(0.76,0.84,0.90) if dark_mode else FIGMA_OFF_WHITE
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(33,543,144,42), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var how_to := FigmaReferenceCanvas.premium_button("HOW TO PLAY",12,utility_text,Color("#086ec7") if not dark_mode else utility_fill,16,utility_border,1.2)
	how_to.name = "SettingsHowToPlay"
	FigmaReferenceCanvas.set_rect(how_to,33,543,144,42)
	how_to.pressed.connect(_show_current_tutorial)
	canvas.add_child(how_to)
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(193,543,158,42), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var privacy := FigmaReferenceCanvas.premium_button("PRIVACY OPTIONS",12,utility_text,Color("#086ec7") if not dark_mode else utility_fill,16,utility_border,1.2)
	privacy.name = "SettingsPrivacy"
	FigmaReferenceCanvas.set_rect(privacy,193,543,158,42)
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	canvas.add_child(privacy)

	_figma_bottom_nav(canvas,"settings",dark_mode)

func _figma_settings_card(canvas: Control, name_value: String, rect: Rect2, fill: Color, border: Color, dark_mode: bool) -> PanelContainer:
	var card: PanelContainer
	if dark_mode:
		card = _figma_solid_card(canvas,name_value,rect,fill,border,18)
	else:
		card = _figma_card(canvas,name_value,rect,fill,border,18)
		card.modulate.a = 0.70
	return card

func _figma_setting_row(canvas: Control, key: String, label_text: String, toggle_y: float, label_y: float, default_value: bool = true, reduced_motion: bool = false, dark_mode: bool = false) -> void:
	var text_color := Color(0.76,0.84,0.90) if dark_mode else FIGMA_INK
	_figma_text(canvas,label_text,Rect2(34,label_y-7,210,30),13,text_color)
	var enabled := bool(SaveManager.data.get(key,default_value))
	var fill := FIGMA_BLUE if enabled else Color("#b2bfcc")
	var button_text_color := Color(0.76,0.84,0.90) if dark_mode else FIGMA_OFF_WHITE
	var state := "ON" if enabled else "OFF"
	var button := _figma_button(canvas,"SettingToggle/%s" % key.capitalize(),state,Rect2(279,toggle_y,72,38),fill,Callable(),button_text_color,19,12)
	if reduced_motion:
		button.pressed.connect(_toggle_reduced_motion)
	else:
		button.pressed.connect(_toggle_setting.bind(key))

func _setting_button(title_text: String, detail_text: String, enabled: bool, accent: Color) -> Button:
	var state := "ON" if enabled else "OFF"
	var role := "success" if enabled else "toggle_off"
	var button := _button("%s   •   %s\n%s" % [title_text, state, detail_text], Vector2(0, 94), role)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	button.tooltip_text = "%s: %s" % [title_text, state]
	return button

func _toggle_reduced_motion() -> void:
	var enabled := not bool(SaveManager.data.get("reduce_motion", false))
	SaveManager.data["reduce_motion"] = enabled
	SaveManager.save()
	PremiumVisuals.apply_motion_preference()
	FeedbackManager.tap()
	build_settings()

func _show_current_tutorial() -> void:
	var shell := get_node_or_null("UXShell")
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", selected_game_id)

func build_daily_games() -> void:
	current_surface = "daily"
	_remove_active_game()
	var canvas := _figma_surface("daily", Color("#fff6e6"))
	var bonus := EconomyManager.collection_daily_bonus()
	_figma_header(canvas, "DAILY GAMES", "Choose one challenge for today", "+%d" % bonus, FIGMA_GOLD)
	_figma_card(canvas, "DailyIntro", Rect2(17,89,354,64), Color("#fffef8"), Color(1.0,0.847,0.55,0.32), 16)
	_figma_text(canvas, "TODAY • %s" % _figma_today_label(), Rect2(35,106,220,17), 14, FIGMA_INK)

	_figma_daily_card(canvas, "rescue_rush", 171, bonus)
	_figma_daily_card(canvas, "water_sort", 293, bonus)
	_figma_daily_card(canvas, "block_puzzle", 415, bonus)

	_figma_card(canvas, "Perks", Rect2(17,539,354,52), Color("#fffef8"), Color(1.0,0.847,0.55,0.32), 16)
	_figma_text(
		canvas,
		"COLLECTION BONUS  +%d DAILY   •   GARDEN GIFT +%d" % [bonus, EconomyManager.garden_gift_amount()],
		Rect2(33,556,322,18),
		12,
		FIGMA_MUTED
	)
	_figma_bottom_nav(canvas, "daily")

func _figma_today_label() -> String:
	var d := Time.get_date_dict_from_system()
	var months := ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
	var month := int(d.get("month",1))
	return "%s %d" % [months[clampi(month - 1,0,11)], int(d.get("day",1))]

func _daily_ui_state(game_id: String, accent: Color) -> Dictionary:
	var chosen := MultiGameManager.daily_selected_game()
	var own_done := _daily_done(game_id)
	var chosen_done := not chosen.is_empty() and _daily_done(chosen)
	if chosen_done:
		return {"text":"DONE TODAY", "fill":FIGMA_GREEN, "disabled":true, "done":true}
	if own_done:
		return {"text":"DONE TODAY", "fill":FIGMA_GREEN, "disabled":true, "done":true}
	if not chosen.is_empty() and chosen != game_id:
		return {"text":"TODAY: %s" % _figma_short_game(chosen), "fill":Color("#718696"), "disabled":true, "done":false}
	return {"text":"PLAY TODAY", "fill":accent, "disabled":false, "done":false}

func _figma_daily_card(canvas: Control, game_id: String, y: float, collection_bonus: int) -> void:
	var accent := Unjam3DTheme.game_accent(game_id)
	_figma_card(canvas, "DailyCard/%s" % game_id, Rect2(17,y,354,106), Color("#fffef8"), Color(1.0,0.847,0.55,0.32), 18)
	_figma_text(canvas, MultiGameManager.display_name(game_id).to_upper(), Rect2(33,y+18,150,21), 17, accent)
	var detail := "TODAY’S RESCUE" if game_id == "rescue_rush" else ("TODAY’S SORT" if game_id == "water_sort" else "TODAY’S BLOCK RUN")
	_figma_text(canvas, detail, Rect2(33,y+48,175,15), 12, FIGMA_MUTED)
	var reward := "+%d COINS" % (100 + collection_bonus) if game_id == "rescue_rush" else "+%d–%d COINS" % [125 + collection_bonus,175 + collection_bonus]
	_figma_text(canvas, reward, Rect2(33,y+72,130,16), 13, FIGMA_ORANGE)
	var daily_state := _daily_ui_state(game_id, accent)
	var fill: Color = daily_state.get("fill", accent)
	var button_text := String(daily_state.get("text", "PLAY TODAY"))
	var button := _figma_button(
		canvas,
		"DailyPlay/%s" % game_id,
		button_text,
		Rect2(236,y+42,116,48),
		fill,
		Callable(),
		FIGMA_OFF_WHITE,
		14,
		11
	)
	button.disabled = bool(daily_state.get("disabled", false))
	if not button.disabled:
		button.pressed.connect(start_game_daily.bind(game_id))

func _daily_game_card(game_id: String, collection_bonus: int) -> PanelContainer:
	var accent := Unjam3DTheme.game_accent(game_id)
	var done := _daily_done(game_id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 250)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PremiumDesignSystem.apply_panel(card, _dark(), accent, true, 28)
	var margin := _pad(card, 18)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := _label(MultiGameManager.display_name(game_id).to_upper(), 24, "title", accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var challenge_text := "TODAY’S RESCUE" if game_id == "rescue_rush" else ("TODAY’S SORT" if game_id == "water_sort" else "TODAY’S BLOCK RUN")
	var challenge := _label(challenge_text, 16, "body", accent)
	challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(challenge)

	var reward_text := "+%d COINS" % (100 + collection_bonus)
	if game_id != "rescue_rush":
		reward_text = "+%d–%d COINS" % [125 + collection_bonus, 175 + collection_bonus]
	var reward := _label(reward_text, 18, "accent", PremiumDesignSystem.GOLD)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(reward)

	var perk := _label(
		"Includes +%d permanent Collection bonus" % collection_bonus if collection_bonus > 0 else "Collection upgrades can boost this reward",
		14,
		"muted",
		accent
	)
	perk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(perk)

	var daily_state := _daily_ui_state(game_id, accent)
	var play_text := String(daily_state.get("text", "PLAY TODAY"))
	var play := _button(play_text, Vector2(0, 68), "success" if bool(daily_state.get("done", false)) else "primary", game_id)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.disabled = bool(daily_state.get("disabled", false))
	if not play.disabled:
		play.pressed.connect(start_game_daily.bind(game_id))
	box.add_child(play)
	return card

func _claim_collection_gift() -> void:
	var amount := EconomyManager.claim_garden_gift()
	if amount <= 0:
		return
	FeedbackManager.effect()
	PremiumVisuals.burst(Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.45), PremiumDesignSystem.GOLD, 22)
	build_collection()

func build_collection() -> void:
	current_surface = "collection"
	_remove_active_game()
	var canvas := _figma_surface("collection", Color("#e6f7ef"))
	_figma_header(
		canvas,
		"COLLECTION",
		"Progress, friends and permanent rewards",
		"◈ +",
		FIGMA_GREEN,
		Callable(self,"build_home"),
		Callable(self,"_figma_open_shop")
	)

	var total_completed := 0
	var total_stars := 0
	var total_perfect := 0
	var total_badges := 0
	for game_id in MultiGameManager.GAME_IDS:
		var p := MultiGameManager.progress_for(game_id)
		total_completed += int(p.get("levels_completed",0))
		total_stars += MultiGameManager.total_stars(game_id)
		total_perfect += int(p.get("perfect_clears",0))
		var badges = p.get("world_badges",[])
		if badges is Array:
			total_badges += (badges as Array).size()

	_figma_card(canvas,"Journey",Rect2(17,89,354,96),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"YOUR UNJAM JOURNEY",Rect2(33,107,210,19),16,Color("#088c3d"))
	var metrics := [
		[total_completed,"LEVELS",35.0],
		[total_stars,"STARS",119.0],
		[total_perfect,"PERFECT",203.0],
		[total_badges,"BADGES",287.0]
	]
	for metric in metrics:
		_figma_text(canvas,_compact_stat(int(metric[0])),Rect2(float(metric[2]),136,62,26),18,FIGMA_INK)
		_figma_text(canvas,String(metric[1]),Rect2(float(metric[2])-3,161,70,20),12,FIGMA_MUTED)

	_figma_text(canvas,"THREE PUZZLE WORLDS",Rect2(17,204,190,18),15,FIGMA_INK)
	_figma_collection_progress(canvas,"rescue_rush",17)
	_figma_collection_progress(canvas,"water_sort",135)
	_figma_collection_progress(canvas,"block_puzzle",253)

	_figma_card(canvas,"Achievements",Rect2(17,339,354,76),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"★  ACHIEVEMENT CABINET",Rect2(33,355,220,18),15,FIGMA_ORANGE)
	var achievement_parts: Array[String] = []
	for game_id in MultiGameManager.GAME_IDS:
		var unlocked := MultiGameManager.unlocked_achievements(game_id).size()
		var total := MultiGameManager.achievement_definitions(game_id).size()
		achievement_parts.append("%s %d/%d" % [_figma_short_game(game_id),unlocked,total])
	_figma_text(canvas," • ".join(achievement_parts),Rect2(33,384,310,22),12,FIGMA_MUTED)

	var decorations: Array = SaveManager.data.get("decorations",[])
	var rescued: Array = SaveManager.data.get("rescued",[])
	var owned := decorations.size()
	_figma_card(canvas,"Garden",Rect2(17,429,354,96),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"♥  RESCUE GARDEN",Rect2(33,445,180,19),16,Color("#088c3d"))
	_figma_text(canvas,"%d friends home • %d / 6 upgrades" % [rescued.size(),owned],Rect2(33,476,240,20),13,FIGMA_MUTED)
	_figma_text(canvas,"%d / 6 upgrades  •  +%d Daily  •  +%d Gift" % [owned,EconomyManager.collection_daily_bonus(),EconomyManager.garden_gift_amount()],Rect2(33,501,310,20),12,FIGMA_MUTED)

	_figma_card(canvas,"Boost",Rect2(17,539,354,92),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"PERMANENT BOOST",Rect2(33,555,180,18),15,FIGMA_ORANGE)
	_figma_text(canvas,"+5 per Daily Game • +10 Garden Gift per upgrade",Rect2(33,583,310,20),12,FIGMA_MUTED)

	# Figma state transition: swipe upward through the Garden/Boost region to
	# reveal the dedicated six-upgrade Collection state.
	var scroll_to_upgrades := Control.new()
	scroll_to_upgrades.name = "Proto/ScrollToUpgrades"
	scroll_to_upgrades.mouse_filter = Control.MOUSE_FILTER_PASS
	FigmaReferenceCanvas.set_rect(scroll_to_upgrades,12,420,366,320)
	scroll_to_upgrades.gui_input.connect(_collection_summary_scroll_input.bind(scroll_to_upgrades))
	canvas.add_child(scroll_to_upgrades)

	var can_claim := EconomyManager.can_claim_garden_gift()
	var gift_text := "CLAIM GARDEN GIFT • +%d" % EconomyManager.garden_gift_amount()
	if not can_claim:
		gift_text = "GARDEN GIFT CLAIMED" if EconomyManager.garden_gift_claimed_today() else "BUY AN UPGRADE IN SHOP"
	var gift_fill := FIGMA_GREEN if can_claim else Color(0.54,0.64,0.72)
	var gift := _figma_button(canvas,"CollectionGardenGift",gift_text,Rect2(33,605,250,40),gift_fill,Callable(),FIGMA_OFF_WHITE,16,12)
	if can_claim:
		gift.pressed.connect(_claim_collection_gift)
	else:
		gift.pressed.connect(_figma_open_shop)

	_figma_bottom_nav(canvas,"collection")

func _figma_collection_progress(canvas: Control, game_id: String, x: float) -> void:
	var accent := Unjam3DTheme.game_accent(game_id)
	_figma_card(canvas,"ProgressCard/%s" % game_id,Rect2(x,231,110,86),Color("#fffef7"),Color(accent,0.70),16)
	_figma_text(canvas,_figma_short_game(game_id),Rect2(x+12,245,86,15),12,accent)
	var level := _highest_level_for_game(game_id)
	var stars := MultiGameManager.total_stars(game_id)
	_figma_text(canvas,"L%d • ★ %s" % [level,_compact_stat(stars)],Rect2(x+12,273,92,20),12,FIGMA_MUTED)

func _figma_short_game(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER"
		"block_puzzle": return "BLOCK"
		_: return "RESCUE"

func build_collection_upgrades() -> void:
	current_surface = "collection"
	_remove_active_game()
	var canvas := _figma_surface("collection",Color("#e6f7ef"))
	_figma_header(
		canvas,
		"COLLECTION",
		"Progress, friends and permanent rewards",
		"◈ +",
		FIGMA_GREEN,
		Callable(self,"build_home"),
		Callable(self,"_figma_open_shop")
	)

	# Add the swipe-return region first so live purchase pills painted afterward
	# remain the top-most touch owners.
	var scroll_to_summary := Control.new()
	scroll_to_summary.name = "Proto/ScrollToSummary"
	scroll_to_summary.mouse_filter = Control.MOUSE_FILTER_PASS
	FigmaReferenceCanvas.set_rect(scroll_to_summary,11,87,366,650)
	scroll_to_summary.gui_input.connect(_collection_upgrades_scroll_input.bind(scroll_to_summary))
	canvas.add_child(scroll_to_summary)

	var owned_count := EconomyManager.collection_owned_count()
	_figma_text(canvas,"GARDEN UPGRADES",Rect2(23,99,342,28),22,Color("#1c8552"))
	_figma_text(canvas,"Permanent value • %d / 6 owned" % owned_count,Rect2(23,131,342,18),13,Color("#597a8f"))
	_figma_solid_card(canvas,"CollectionScroll/Boost",Rect2(23,163,342,60),Color("#f0fff5"),Color(0.30,0.78,0.48,0.42),16,false)
	var boost_text := _figma_text(
		canvas,
		"+%d EVERY DAILY GAME   •   +%d GARDEN GIFT" % [EconomyManager.collection_daily_bonus(),EconomyManager.garden_gift_amount()],
		Rect2(33,184,322,18),
		12,
		Color("#1f8a52"),
		true
	)
	boost_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var upgrades := [
		["tree","CANOPY TREE","SHADE",100],
		["bench","GARDEN BENCH","REST",150],
		["fountain","CRYSTAL FOUNTAIN","SPARKLE",250],
		["lanterns","LANTERN PATH","GLOW",350],
		["cottage","RESCUE COTTAGE","HOME",500],
		["rainbow_bridge","RAINBOW BRIDGE","WONDER",750],
	]
	var owned_decorations: Array = SaveManager.data.get("decorations",[])
	for i in range(upgrades.size()):
		var spec: Array = upgrades[i]
		var id := String(spec[0])
		var display_name := String(spec[1])
		var flavor := String(spec[2])
		var cost := int(spec[3])
		var y := 239.0 + float(i)*76.0
		var owned := id in owned_decorations
		var card_fill := Color("#f0fff5") if owned else Color("#fcfaff")
		var card_border := Color(0.32,0.78,0.49,0.46) if owned else Color(0.72,0.58,0.90,0.46)
		var title_color := Color("#1f854f") if owned else Color("#4d3373")
		_figma_solid_card(
			canvas,
			"CollectionScroll/Upgrade/%d" % i,
			Rect2(23,y,342,66),
			card_fill,
			card_border,
			16,
			false
		)
		_figma_text(canvas,display_name,Rect2(37,y+11,184,18),13,title_color)
		_figma_text(canvas,"%s  •  +5 DAILY  •  +10 GIFT" % flavor,Rect2(37,y+36,206,16),12,Color("#6b8091"))
		var state_text := "OWNED" if owned else "%d COINS" % cost
		var pill_fill := Color("#e0f2e5") if owned else Color("#7a57e0")
		var state_text_color := Color("#4d7a59") if owned else Color.WHITE
		var state := _figma_button(
			canvas,
			"CollectionUpgrade/%s" % id,
			state_text,
			Rect2(249,y+14,98,38),
			pill_fill,
			Callable(),
			state_text_color,
			12,
			12
		)
		state.disabled = owned
		if owned:
			var owned_style := FigmaReferenceCanvas.solid_box(Color("#e0f2e5"),12,Color.TRANSPARENT,0)
			state.add_theme_stylebox_override("disabled",owned_style)
			state.add_theme_color_override("font_disabled_color",Color("#4d7a59"))
			state.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			state.pressed.connect(_buy_collection_upgrade.bind(id,cost))

	var return_hint := _figma_text(canvas,"Swipe up to return to your Collection summary",Rect2(37,710,314,18),12,Color("#6e8596"),true)
	return_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_figma_bottom_nav(canvas,"collection")

func _collection_summary_scroll_input(event: InputEvent, owner: Control) -> void:
	_collection_scroll_input(event,owner,true)

func _collection_upgrades_scroll_input(event: InputEvent, owner: Control) -> void:
	_collection_scroll_input(event,owner,false)

func _collection_scroll_input(event: InputEvent, owner: Control, toward_upgrades: bool) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_collection_scroll_tracking = true
			_collection_scroll_origin_y = touch.position.y
		else:
			_collection_scroll_tracking = false
		return
	if event is InputEventScreenDrag and _collection_scroll_tracking:
		var drag := event as InputEventScreenDrag
		var delta_y := drag.position.y - _collection_scroll_origin_y
		if (toward_upgrades and delta_y <= -42.0) or ((not toward_upgrades) and delta_y >= 42.0):
			_collection_scroll_tracking = false
			owner.accept_event()
			FeedbackManager.tap()
			if toward_upgrades:
				build_collection_upgrades()
			else:
				build_collection()
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and toward_upgrades and mouse.pressed:
			owner.accept_event()
			build_collection_upgrades()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and not toward_upgrades and mouse.pressed:
			owner.accept_event()
			build_collection()

func _buy_collection_upgrade(id: String, cost: int) -> bool:
	if id in SaveManager.data.get("decorations",[]):
		return true
	if EconomyManager.unlock_collection_item(id,cost):
		FeedbackManager.effect()
		PremiumVisuals.burst(Vector2(get_viewport_rect().size.x*0.5,get_viewport_rect().size.y*0.45),FIGMA_GOLD,18)
		build_collection_upgrades()
		return true
	var prompt := get_node_or_null("InsufficientCoinsPrompt")
	if prompt != null and prompt.has_method("show_for"):
		prompt.call(
			"show_for",
			display_name_for_upgrade(id),
			cost,
			Callable(self,"_retry_collection_upgrade").bind(id,cost)
		)
	else:
		FeedbackManager.blocked()
	return false

func _retry_collection_upgrade(id: String, cost: int) -> bool:
	if EconomyManager.unlock_collection_item(id,cost):
		FeedbackManager.effect()
		build_collection_upgrades()
		return true
	return false

func display_name_for_upgrade(id: String) -> String:
	match id:
		"tree": return "CANOPY TREE"
		"bench": return "GARDEN BENCH"
		"fountain": return "CRYSTAL FOUNTAIN"
		"lanterns": return "LANTERN PATH"
		"cottage": return "RESCUE COTTAGE"
		"rainbow_bridge": return "RAINBOW BRIDGE"
		_: return id.replace("_"," ").to_upper()

func _open_games_surface() -> void:
	_remove_active_game()
	if content != null and is_instance_valid(content):
		content.hide()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FeedbackManager.tap()
	current_surface = "live"

func _add_secondary_nav(active: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var old := content.get_node_or_null("SecondaryBottomNav")
	if old != null:
		content.remove_child(old)
		old.queue_free()
	var viewport_size := get_viewport_rect().size
	var nav := PanelContainer.new()
	nav.name = "SecondaryBottomNav"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 12 if viewport_size.x < 600.0 else 22
	nav.offset_right = -12 if viewport_size.x < 600.0 else -22
	nav.offset_top = -102 if viewport_size.y < 1100.0 else -114
	nav.offset_bottom = -8 if viewport_size.y < 1100.0 else -14
	nav.z_index = 180
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("071a35") if _dark() else Color("0756a8"), 28, Color("67d3ff"), 3, 10))
	content.add_child(nav)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3 if viewport_size.x < 600.0 else 5)
	nav.add_child(row)
	var entries: Array = [
		["home", "⌂\nHOME", Callable(self, "build_home"), "SecondaryNavHome"],
		["games", "◈\nGAMES", Callable(self, "_open_games_surface"), "SecondaryNavGames"],
		["daily", "☀\nDAILY", Callable(self, "build_daily_games"), "SecondaryNavDaily"],
		["collection", "★\nCOLLECT", Callable(self, "build_collection"), "SecondaryNavCollection"],
		["settings", "⚙\nSETTINGS", Callable(self, "build_settings"), "SecondaryNavSettings"],
	]
	for entry in entries:
		var key := String(entry[0])
		var button := Button.new()
		button.name = String(entry[3])
		button.text = String(entry[1])
		button.set_meta("unjam_preserve_surface_style", true)
		button.custom_minimum_size = Vector2(0, 78 if viewport_size.y < 1100.0 else 88)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14 if viewport_size.x < 600.0 else 17)
		var selected := key == active
		Unjam3DTheme.gloss_button(button, Unjam3DTheme.WATER if selected else Color("0d6dc2"), selected, 22, _dark())
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if selected else Control.MOUSE_FILTER_STOP
		if not selected:
			var callback: Callable = entry[2]
			button.pressed.connect(callback)
		row.add_child(button)
	_restyle_secondary_nav(active)

func _restyle_secondary_nav(active: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var nav := content.get_node_or_null("SecondaryBottomNav")
	if nav == null:
		return
	var mapping := {
		"home": "SecondaryNavHome",
		"games": "SecondaryNavGames",
		"daily": "SecondaryNavDaily",
		"collection": "SecondaryNavCollection",
		"settings": "SecondaryNavSettings",
	}
	for key in mapping.keys():
		var button := nav.find_child(String(mapping[key]), true, false) as Button
		if button == null:
			continue
		var selected: bool = String(key) == active
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if selected else Control.MOUSE_FILTER_STOP
		button.set_meta("unjam_selected_nav", selected)
		Unjam3DTheme.gloss_button(button, Unjam3DTheme.WATER if selected else Color("0d6dc2"), selected, 22, _dark())

func _journey_metric(title_text: String, value: int, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 82)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(_dark()), 20, Color(accent, 0.30), 1, 2, _dark()))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(box)
	var number := _label(str(value), 27, "title", accent)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(number)
	var title := _label(title_text, 13, "muted", accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	return chip

func _collection_game_card(game_id: String) -> PanelContainer:
	var accent := Unjam3DTheme.game_accent(game_id)
	var progress_data := MultiGameManager.progress_for(game_id)
	var highest := clampi(int(progress_data.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var world := MultiGameManager.world_for_game_level(game_id, highest)
	var local_level := posmod(highest - 1, 100) + 1
	var icon := "↗"
	if game_id == "water_sort":
		icon = "◉"
	elif game_id == "block_puzzle":
		icon = "◆"

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 248)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Unjam3DTheme.surface_fill(_dark(), true), 28, Color(accent, 0.82), 3, 11))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := _label("%s  %s" % [icon, MultiGameManager.display_name(game_id).to_upper()], 24, "title", accent)
	box.add_child(title)
	var journey := _label("WORLD %d  •  LEVEL %d" % [world, highest], 18, "body", accent)
	box.add_child(journey)

	var progress := ProgressBar.new()
	progress.max_value = 100.0
	progress.value = float(local_level)
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 18)
	progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(_dark()), 9, Color.TRANSPARENT, 0, 0, _dark()))
	progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 9, accent.lightened(0.14), 1, 0, _dark()))
	box.add_child(progress)

	var stats := _label("★ %s   •   PERFECT %d   •   BADGES %d" % [
		_compact_stat(MultiGameManager.total_stars(game_id)),
		int(progress_data.get("perfect_clears", 0)),
		(progress_data.get("world_badges", []) as Array).size()
	], 16, "muted", accent)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(stats)

	var open := _button("OPEN JOURNEY", Vector2(0, 72), "primary", game_id)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.pressed.connect(open_game_campaign.bind(game_id))
	box.add_child(open)
	return card

func _compact_stat(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)

func _multi_page_count(game_id: String, world: int) -> int:
	var first := MultiGameManager.first_level_in_game_world(game_id,world)
	var last := MultiGameManager.last_level_in_game_world(game_id,world)
	return maxi(1,ceili(float(last-first+1)/float(FIGMA_LEVEL_PAGE_SIZE)))

func _multi_page_for_level(game_id: String, level: int) -> int:
	var world := MultiGameManager.world_for_game_level(game_id,level)
	var first := MultiGameManager.first_level_in_game_world(game_id,world)
	return clampi(int((level-first)/FIGMA_LEVEL_PAGE_SIZE)+1,1,_multi_page_count(game_id,world))

func _multi_page_bounds(game_id: String, world: int, page: int) -> Vector2i:
	var world_first := MultiGameManager.first_level_in_game_world(game_id,world)
	var world_last := MultiGameManager.last_level_in_game_world(game_id,world)
	var safe_page := clampi(page,1,_multi_page_count(game_id,world))
	var first := world_first + (safe_page-1)*FIGMA_LEVEL_PAGE_SIZE
	return Vector2i(first,mini(first+FIGMA_LEVEL_PAGE_SIZE-1,world_last))

func build_level_select() -> void:
	selected_game_id = "rescue_rush"
	selected_multi_world = clampi(selected_multi_world,1,MultiGameManager.world_count_for(selected_game_id))
	if selected_multi_world <= 0:
		selected_multi_world = MultiGameManager.highest_unlocked_game_world(selected_game_id)
	selected_multi_page = clampi(selected_multi_page,1,_multi_page_count(selected_game_id,selected_multi_world))
	_build_figma_level_browser(selected_game_id)

func build_multi_level_select() -> void:
	selected_multi_world = clampi(selected_multi_world,1,MultiGameManager.world_count_for(selected_game_id))
	selected_multi_page = clampi(selected_multi_page,1,_multi_page_count(selected_game_id,selected_multi_world))
	_build_figma_level_browser(selected_game_id)

func _build_figma_level_browser(game_id: String) -> void:
	current_surface = "levels"
	_remove_active_game()
	var bottom_tint := Color("#e4f8ec") if game_id == "rescue_rush" else (Color("#e3f2fc") if game_id == "water_sort" else Color("#f5eafd"))
	var canvas := _figma_surface("games",bottom_tint)
	var accent := Unjam3DTheme.game_accent(game_id)
	var title := MultiGameManager.display_name(game_id).to_upper()
	var world_count := MultiGameManager.world_count_for(game_id)
	_figma_header(
		canvas,
		title,
		"WORLD %d / %d" % [selected_multi_world,world_count],
		"◈ +",
		accent,
		Callable(self,"_open_games_surface"),
		Callable(self,"_figma_open_shop")
	)
	_style_figma_level_header(canvas,accent)
	_figma_level_tabs(canvas,game_id)

	var bounds := _multi_page_bounds(game_id,selected_multi_world,selected_multi_page)
	var world_name := MultiGameManager.world_name(game_id,selected_multi_world).to_upper()
	_figma_card(canvas,"JourneyHero",Rect2(17,149,354,94),Color("#fffef8"),Color(accent,0.42),15)
	_figma_text(canvas,world_name,Rect2(35,145,250,23),19,accent)
	_figma_text(canvas,"LEVELS %d–%d • SET %d/%d" % [bounds.x,bounds.y,selected_multi_page,_multi_page_count(game_id,selected_multi_world)],Rect2(35,175,210,16),13,FIGMA_MUTED)

	var accent_rail := ColorRect.new()
	accent_rail.name = "ScreenPolish/AccentRail"
	accent_rail.color = Color(accent,0.88)
	accent_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FigmaReferenceCanvas.set_rect(accent_rail,17,161,5,70)
	canvas.add_child(accent_rail)

	var page_y := 243.0 if game_id == "block_puzzle" else 222.0
	var grid_y := 304.0 if game_id == "block_puzzle" else 269.0
	if game_id == "block_puzzle":
		_add_figma_block_modes(canvas)

	var prev := _figma_button(canvas,"LevelPrev","◀ PREV",Rect2(17,page_y,100,38),FIGMA_BLUE,Callable(),FIGMA_OFF_WHITE,13,13)
	prev.disabled = selected_multi_world <= 1 and selected_multi_page <= 1
	_style_figma_page_button(prev,FIGMA_BLUE,accent,prev.disabled)
	if not prev.disabled:
		prev.pressed.connect(_change_multi_page.bind(-1))
	var current := _figma_button(canvas,"LevelCurrent","CURRENT",Rect2(125,page_y,118,38),accent,Callable(self,"_jump_multi_current"),FIGMA_OFF_WHITE,13,13)
	_style_figma_page_button(current,accent,accent,false)
	var next_disabled := selected_multi_world >= world_count and selected_multi_page >= _multi_page_count(game_id,selected_multi_world)
	var next := _figma_button(canvas,"LevelNext","NEXT ▶",Rect2(251,page_y,120,38),Color("#fcfeff"),Callable(),FIGMA_MUTED,13,13)
	next.disabled = next_disabled
	_style_figma_page_button(next,Color("#fcfeff"),accent,next_disabled,true)
	if not next.disabled:
		next.pressed.connect(_change_multi_page.bind(1))

	var current_level := _highest_level_for_game(game_id)
	var index := 0
	for level_number in range(bounds.x,bounds.y+1):
		var col := index % 4
		var row := int(index/4)
		var x := 17.0 + float(col)*89.0
		var y := grid_y + float(row)*80.0
		var unlocked := MultiGameManager.is_level_unlocked(game_id,level_number)
		var stars := MultiGameManager.get_stars(game_id,level_number)
		var is_current := unlocked and level_number == current_level
		var milestone := level_number % 25 == 0
		var fill := Color("#20384b") if _dark() else Color("#fefefa")
		var border := Color(accent,0.62 if _dark() else 0.40)
		var text_color := FIGMA_DARK_INK if _dark() else FIGMA_INK
		if not unlocked:
			fill = Color("#1a2938") if _dark() else Color("#dee5eb")
			border = Color("#52687a",0.72) if _dark() else Color("#b8c4cf",0.45)
			text_color = Color("#8296a8") if _dark() else Color("#8c9ca8")
		elif is_current:
			fill = accent
			border = Color(accent.lightened(0.24),0.75)
			text_color = FIGMA_OFF_WHITE
		elif milestone:
			border = Color(FIGMA_GOLD,0.85)
		var card := _figma_button(canvas,"Level/%d" % level_number,str(level_number),Rect2(x,y,80,68),fill,Callable(),text_color,15,15)
		card.disabled = not unlocked
		_style_figma_level_card(card,accent,border,unlocked,is_current)
		if unlocked:
			if game_id == "rescue_rush":
				card.pressed.connect(start_level.bind(level_number))
			else:
				card.pressed.connect(start_multi_level.bind(game_id,level_number,false))
		var star_text := "LOCK" if not unlocked else ("★".repeat(stars) if stars > 0 else "···")
		var star_color := (Color("#8296a8") if _dark() else Color("#8c9ca8")) if not unlocked else (FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)
		_figma_text(canvas,star_text,Rect2(x+9,y+38,64,18),12,star_color,true)
		index += 1

func _figma_level_tabs(canvas: Control, active_game_id: String) -> void:
	var active_accent := Unjam3DTheme.game_accent(active_game_id)
	var specs := [
		["rescue_rush","RESCUE",17.0],
		["water_sort","WATER",133.0],
		["block_puzzle","BLOCK",249.0],
	]
	for spec in specs:
		var game_id := String(spec[0])
		var active := game_id == active_game_id
		var fill := active_accent if active else (Color("#20384b") if _dark() else Color("#fcfeff"))
		var text_color := FIGMA_OFF_WHITE if active else (FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)
		var button := _figma_button(canvas,"LevelGameTab/%s" % game_id,String(spec[1]),Rect2(float(spec[2]),83,108,40),fill,Callable(),text_color,14,12)
		_style_figma_level_tab(button,active_accent,active)
		if active:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			button.pressed.connect(_figma_switch_level_game.bind(game_id))

func _style_figma_level_header(canvas: Control, accent: Color) -> void:
	var back := canvas.get_node_or_null("FigmaBack") as Button
	if back != null:
		var back_top := Color("#2b455b") if _dark() else Color("#fcfeff")
		var back_mid := Color("#20384b") if _dark() else Color("#fcfeff")
		var back_bottom := Color("#15293b") if _dark() else Color("#e2e4e5")
		back.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(back_top,back_mid,back_bottom,16,Color(accent,0.70 if _dark() else 0.55),1.2,0.50))
		back.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(back_top.lightened(0.08),back_mid.lightened(0.06),back_bottom.lightened(0.04),16,Color(accent,0.82),1.2,0.50))
		back.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(back_mid,back_bottom,back_bottom.darkened(0.08),16,Color(accent,0.70),1.2,0.50))
		back.add_theme_color_override("font_color", FIGMA_DARK_INK if _dark() else FIGMA_NAVY)
	var pill := canvas.get_node_or_null("FigmaHeaderPill") as Button
	if pill != null:
		pill.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(accent.lightened(0.15),accent,accent.darkened(0.10),16,Color(accent.lightened(0.28),0.55),1.2))
		pill.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(accent.lightened(0.20),accent.lightened(0.04),accent.darkened(0.06),16,Color(accent.lightened(0.34),0.62),1.2))
		pill.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(accent,accent.darkened(0.06),accent.darkened(0.18),16,Color(accent.lightened(0.20),0.55),1.2))

func _style_figma_level_tab(button: Button, accent: Color, active: bool) -> void:
	if active:
		button.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(accent.lightened(0.15),accent,accent.darkened(0.10),14,Color(accent.lightened(0.28),0.55),1.2))
		button.add_theme_stylebox_override("hover",button.get_theme_stylebox("normal"))
		button.add_theme_stylebox_override("pressed",button.get_theme_stylebox("normal"))
	else:
		var tab_top := Color("#2b455b") if _dark() else Color("#fcfeff")
		var tab_mid := Color("#20384b") if _dark() else Color("#fcfeff")
		var tab_bottom := Color("#15293b") if _dark() else Color("#e2e4e5")
		var normal := FigmaReferenceCanvas.rounded_gradient3(tab_top,tab_mid,tab_bottom,14,Color(accent,0.70 if _dark() else 0.55),1.2,0.50)
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(tab_top.lightened(0.08),tab_mid.lightened(0.06),tab_bottom.lightened(0.04),14,Color(accent,0.82),1.2,0.50))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(tab_mid,tab_bottom,tab_bottom.darkened(0.08),14,Color(accent,0.70),1.2,0.50))
		button.add_theme_color_override("font_color", FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)

func _style_figma_page_button(button: Button, fill: Color, accent: Color, disabled: bool, light_surface: bool = false) -> void:
	if light_surface or disabled:
		var page_top := Color("#2b455b") if _dark() else Color("#fcfeff")
		var page_mid := Color("#20384b") if _dark() else Color("#fcfeff")
		var page_bottom := Color("#15293b") if _dark() else Color("#e2e4e5")
		var normal := FigmaReferenceCanvas.rounded_gradient3(page_top,page_mid,page_bottom,13,Color(accent,0.70 if _dark() else 0.55),1.2,0.50)
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(page_top.lightened(0.08),page_mid.lightened(0.06),page_bottom.lightened(0.04),13,Color(accent,0.82),1.2,0.50))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(page_mid,page_bottom,page_bottom.darkened(0.08),13,Color(accent,0.70),1.2,0.50))
		button.add_theme_stylebox_override("disabled",normal)
		button.add_theme_color_override("font_disabled_color",FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)
		button.add_theme_color_override("font_color",FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)
	else:
		button.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(fill.lightened(0.15),fill,fill.darkened(0.10),13,Color(fill.lightened(0.28),0.55),1.2))
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(fill.lightened(0.20),fill.lightened(0.04),fill.darkened(0.06),13,Color(fill.lightened(0.34),0.62),1.2))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(fill,fill.darkened(0.06),fill.darkened(0.18),13,Color(fill.lightened(0.20),0.55),1.2))

func _style_figma_level_card(button: Button, accent: Color, border: Color, unlocked: bool, current: bool) -> void:
	if not unlocked:
		var locked := FigmaReferenceCanvas.rounded_gradient3(
			Color("#253746") if _dark() else Color("#dfe7eb"),
			Color("#1d2d3b") if _dark() else Color("#dee5eb"),
			Color("#142330") if _dark() else Color("#d3dadf"),
			15, Color("#52687a",0.72) if _dark() else Color("#b8c4cf",0.45), 1.4, 0.48
		)
		button.add_theme_stylebox_override("normal",locked)
		button.add_theme_stylebox_override("hover",locked)
		button.add_theme_stylebox_override("pressed",locked)
		button.add_theme_stylebox_override("disabled",locked)
		button.add_theme_color_override("font_disabled_color",Color("#8296a8") if _dark() else Color("#8c9ca8"))
		return
	if current:
		button.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(accent.lightened(0.20),accent,accent.darkened(0.16),15,border,1.6,0.40))
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(accent.lightened(0.28),accent.lightened(0.05),accent.darkened(0.10),15,border.lightened(0.10),1.6,0.40))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(accent,accent.darkened(0.08),accent.darkened(0.22),15,border,1.6,0.40))
		button.add_theme_color_override("font_color", FIGMA_OFF_WHITE)
		return
	if _dark():
		button.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(Color("#2a4559"),Color("#20384b"),Color("#162a3b"),15,border,1.4,0.42))
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(Color("#35566e"),Color("#29485f"),Color("#1b3347"),15,border.lightened(0.10),1.4,0.42))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(Color("#20384b"),Color("#192f41"),Color("#112536"),15,border,1.4,0.42))
		button.add_theme_color_override("font_color",FIGMA_DARK_INK)
		button.add_theme_color_override("font_hover_color",Color.WHITE)
		button.add_theme_color_override("font_pressed_color",FIGMA_DARK_INK)
	else:
		button.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(Color("#fefefa"),Color("#fefefa"),Color("#e9e9e6"),15,border,1.4,0.52))
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(Color.WHITE,Color("#fffefb"),Color("#efefec"),15,border.lightened(0.08),1.4,0.52))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(Color("#f7f7f4"),Color("#f4f4f1"),Color("#e2e2df"),15,border,1.4,0.52))

func _add_figma_block_modes(canvas: Control) -> void:
	var specs := [
		["campaign","CAMPAIGN",17.0,Color("#c73dff")],
		["endless","ENDLESS",105.0,FIGMA_BLUE],
		["zen","ZEN",193.0,FIGMA_GREEN],
		["extreme","EXTREME",281.0,FIGMA_ORANGE],
	]
	for spec in specs:
		var mode := String(spec[0])
		var fill: Color = spec[3] as Color
		var button := _figma_button(canvas,"BlockMode/%s" % mode,String(spec[1]),Rect2(float(spec[2]),201,82,36),fill,Callable(),FIGMA_OFF_WHITE,13,12)
		_style_figma_page_button(button,fill,fill,false)
		if mode == "campaign":
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			button.pressed.connect(start_block_mode.bind(mode))

func _figma_switch_level_game(game_id: String) -> void:
	selected_game_id = game_id
	selected_multi_world = MultiGameManager.highest_unlocked_game_world(game_id)
	selected_multi_page = _multi_page_for_level(game_id,_highest_level_for_game(game_id))
	build_multi_level_select()

func _inject_game_tabs(active_game_id: String) -> void:
	var root := _find_page_root()
	if root == null:
		return
	var old := root.get_node_or_null("LevelGameTabs")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	var tabs := HBoxContainer.new()
	tabs.name = "LevelGameTabs"
	tabs.custom_minimum_size = Vector2(0, 92)
	tabs.add_theme_constant_override("separation", 10)
	root.add_child(tabs)
	root.move_child(tabs, mini(1, root.get_child_count() - 1))
	for game_id in MultiGameManager.GAME_IDS:
		var current: bool = game_id == active_game_id
		var button := _button(MultiGameManager.display_name(game_id), Vector2(0, 84), "primary" if current else "secondary", game_id)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18 if get_viewport_rect().size.x >= 700.0 else 15)
		button.disabled = current
		button.pressed.connect(open_game_campaign.bind(game_id))
		tabs.add_child(button)

func _inject_block_modes() -> void:
	var root := _find_page_root()
	if root == null:
		return
	var old := root.get_node_or_null("BlockPuzzleModes")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	var stats = SaveManager.data.get("block_mode_stats", {})
	if not stats is Dictionary:
		stats = {}
	var bar := HBoxContainer.new()
	bar.name = "BlockPuzzleModes"
	bar.custom_minimum_size = Vector2(0, 86)
	bar.add_theme_constant_override("separation", 6)
	var specs := [
		["endless", "ENDLESS", "SURVIVAL"],
		["zen", "ZEN", "NO GAME OVER"],
		["extreme", "EXTREME", "MASTER RULES"],
	]
	for spec in specs:
		var mode := String(spec[0])
		var mode_stats = (stats as Dictionary).get(mode, {})
		var best := int((mode_stats as Dictionary).get("best_score", 0)) if mode_stats is Dictionary else 0
		var subtitle := String(spec[2])
		if best > 0:
			subtitle += "  •  BEST %d" % best
		var button := _button("%s\n%s" % [String(spec[1]), subtitle], Vector2(0, 82), "secondary", "block_puzzle")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(start_block_mode.bind(mode))
		bar.add_child(button)
	root.add_child(bar)
	root.move_child(bar, mini(2, root.get_child_count() - 1))

func _find_page_root() -> VBoxContainer:
	if content == null:
		return null
	for child in content.get_children():
		if child is MarginContainer:
			for inner in child.get_children():
				if inner is VBoxContainer:
					return inner as VBoxContainer
	return null

func _inject_journey_summary(game_id: String) -> void:
	var root := _find_page_root()
	if root == null:
		return
	var old := root.get_node_or_null("JourneySummary")
	if old != null:
		root.remove_child(old)
		old.queue_free()

	var accent := Unjam3DTheme.game_accent(game_id)
	var level := _highest_level_for_game(game_id)
	var world := MultiGameManager.world_for_game_level(game_id, level)
	var world_count := MultiGameManager.world_count_for(game_id)
	var local_level := posmod(level - 1, 100) + 1
	var next_milestone := 25
	for milestone in [25, 50, 75, 100]:
		if local_level <= milestone:
			next_milestone = milestone
			break

	var card := PanelContainer.new()
	card.name = "JourneySummary"
	card.custom_minimum_size = Vector2(0, 190)
	card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Unjam3DTheme.surface_fill(_dark(), true), 30, Color(accent, 0.82), 3, 12))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 20)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	box.add_child(top)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(copy)
	var title := _label("%s JOURNEY" % MultiGameManager.display_name(game_id).to_upper(), 25, "title", accent)
	copy.add_child(title)
	var detail := _label("WORLD %d / %d  •  LEVEL %d  •  NEXT MILESTONE %d" % [world, world_count, level, next_milestone], 17, "body", accent)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail)
	var play := _button("▶  CONTINUE", Vector2(220, 72), "primary", game_id)
	play.pressed.connect(_continue_campaign.bind(game_id))
	top.add_child(play)

	var progress := ProgressBar.new()
	progress.max_value = 100.0
	progress.value = float(local_level)
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 22)
	progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(_dark()), 10, Color.TRANSPARENT, 0, 0, _dark()))
	progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 10, accent.lightened(0.14), 1, 0, _dark()))
	box.add_child(progress)
	var hint := _label("Challenge nodes at 25 • 50 • 75 • 100 are highlighted below.", 15, "muted", accent)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	root.add_child(card)
	root.move_child(card, mini(2, root.get_child_count() - 1))

func _continue_campaign(game_id: String) -> void:
	var level := _highest_level_for_game(game_id)
	FeedbackManager.tap()
	if game_id == "rescue_rush":
		start_level(level)
	else:
		start_multi_level(game_id, level, false)

func _level_column_count(usable_width: float) -> int:
	if usable_width >= 900.0:
		return 3
	return 2

func _upgrade_level_browser(game_id: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var accent := Unjam3DTheme.game_accent(game_id)
	var dark_accent := Unjam3DTheme.game_dark(game_id)
	var current_level := _highest_level_for_game(game_id)
	var usable_width := maxf(320.0, get_viewport_rect().size.x - (92.0 if get_viewport_rect().size.x >= 760.0 else 56.0))
	var columns := _level_column_count(usable_width)
	var gap := 14.0
	var button_width := floorf((usable_width - gap * float(columns - 1)) / float(columns)) - 4.0
	for grid in _collect_grids(content):
		if grid.get_child_count() < 20:
			continue
		grid.columns = columns
		grid.add_theme_constant_override("h_separation", int(gap))
		grid.add_theme_constant_override("v_separation", 14)
		for child in grid.get_children():
			if not child is Button:
				continue
			var button := child as Button
			button.custom_minimum_size = Vector2(maxf(156.0, button_width), 148.0)
			button.add_theme_font_size_override("font_size", 22 if columns >= 3 else 20)
			var first_line := button.text.get_slice("\n", 0).strip_edges()
			var is_current := "CURRENT" in button.text.to_upper() or (first_line.is_valid_int() and int(first_line) == current_level and not button.disabled)
			if button.disabled:
				Unjam3DTheme.gloss_button(button, Color("75879b") if _dark() else Color("9db6c8"), false, 22, _dark())
				button.add_theme_color_override("font_color", Color("a8b5c6") if _dark() else Color("6d8597"))
			elif is_current:
				Unjam3DTheme.gloss_button(button, accent, true, 22, _dark())
			elif first_line.is_valid_int() and (int(first_line) % 10 == 0 or "BOSS" in button.text.to_upper() or "MILE" in button.text.to_upper()):
				Unjam3DTheme.gloss_button(button, Unjam3DTheme.GOLD, true, 22, _dark())
				button.add_theme_color_override("font_color", Unjam3DTheme.NAVY)
				button.add_theme_color_override("font_hover_color", Unjam3DTheme.NAVY)
				button.add_theme_color_override("font_pressed_color", Unjam3DTheme.NAVY)
			else:
				Unjam3DTheme.gloss_button(button, dark_accent, false, 22, _dark())

func _add_surface_diorama(game_id: String, node_name: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var old := content.get_node_or_null(node_name)
	if old != null:
		content.remove_child(old)
		old.queue_free()
	var art := Unjam3DGameArt.new()
	art.name = node_name
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.anchor_left = 1.0
	art.anchor_top = 1.0
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	var viewport_size := get_viewport_rect().size
	var art_width := minf(400.0, viewport_size.x * 0.42)
	var art_height := minf(300.0, viewport_size.y * 0.22)
	art.offset_left = -art_width - 24.0
	art.offset_top = -art_height - 24.0
	art.offset_right = -24.0
	art.offset_bottom = -24.0
	art.z_index = -20
	art.modulate = Color(1, 1, 1, 0.42 if _dark() else 0.58)
	art.configure(game_id)
	content.add_child(art)

func _highest_level_for_game(game_id: String) -> int:
	if game_id == "rescue_rush":
		return int(SaveManager.data.get("highest_level", 1))
	return MultiGameManager.highest_level(game_id)
