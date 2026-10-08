extends "res://scripts/ui/premium_main.gd"

const FIGMA_LEVEL_PAGE_SIZE := 20
const GardenUpgradePreviewScene = preload("res://scripts/ui/garden_upgrade_preview.gd")
const META_ART_SCRIPT = preload("res://scripts/ui/unjam_meta_art.gd")
const GAME_ART_SCRIPT = preload("res://scripts/ui/unjam_2d_game_art.gd")
const UNJAM_WORDMARK: Texture2D = preload("res://assets/art/brand/unjam_wordmark.svg")
const WIDE_META_ART := {
	"collection": preload("res://assets/art/meta_wide/collection.svg"),
	"daily": preload("res://assets/art/meta_wide/daily.svg"),
	"compete": preload("res://assets/art/meta_wide/compete.svg"),
	"goals": preload("res://assets/art/meta_wide/goals.svg"),
	"profile": preload("res://assets/art/meta_wide/profile.svg"),
	"friends": preload("res://assets/art/meta_wide/friends.svg"),
	"settings": preload("res://assets/art/meta_wide/settings.svg"),
}
const FIGMA_BG_TOP := Color("#e9e5dd")
const FIGMA_BG_BOTTOM := Color("#8f887f")
const FIGMA_NAVY := Color("#252a30")
const FIGMA_INK := Color("#26323d")
const FIGMA_MUTED := Color("#62676e")
const FIGMA_OFF_WHITE := Color(1.0, 0.995, 0.97)
const FIGMA_BLUE := Color(0.03, 0.43, 0.78)
const FIGMA_GREEN := Color(0.13, 0.78, 0.39)
const FIGMA_CYAN := Color(0.14, 0.68, 1.0)
const FIGMA_ORANGE := Color(1.0, 0.55, 0.12)
const FIGMA_GOLD := Color(1.0, 0.84, 0.24)

const FIGMA_DARK_TOP := Color("#343434")
const FIGMA_DARK_BOTTOM := Color("#1c1c1c")
const FIGMA_DARK_CARD := Color("#252525")
const FIGMA_DARK_INK := Color("#f5f7fa")
const FIGMA_DARK_MUTED := Color("#bbc5cf")
const FIGMA_SCENE_TOP := Color("#e4dfd5")
const FIGMA_SCENE_MID := Color("#b3aca2")
const FIGMA_SCENE_BOTTOM := Color("#80786e")
const FIGMA_SCENE_DARK_TOP := Color("#363636")
const FIGMA_SCENE_DARK_MID := Color("#272727")
const FIGMA_SCENE_DARK_BOTTOM := Color("#1c1c1c")

var _collection_scroll_tracking := false
var _collection_scroll_origin_y := 0.0
var _settings_help_game := "rescue_rush"
var _settings_theme_toggle_pending := false
var _profile_game := "rescue_rush"
var _ranking_game := "rescue_rush"
var _friends_period := "all_time"
var _friends_status := ""
const SETTINGS_HELP_GAMES := ["rescue_rush", "water_sort", "block_puzzle"]

var _sidekick_game := "rescue_rush"
var _sidekick_tip_index := -1
const SIDEKICK_TIPS := {
	"rescue_rush": [
		"Tap blockers first when one arrow frees several paths.",
		"Trace the exit lane before moving the first arrow.",
		"Save hints for boards where two routes look equally safe."
	],
	"water_sort": [
		"Finish one colour before opening too many new tubes.",
		"Keep one empty tube available as a working space.",
		"Look for the longest same-colour stack before you pour."
	],
	"block_puzzle": [
		"Protect the centre so every new piece has room.",
		"Clear lines early instead of waiting for a perfect combo.",
		"Before placing a piece, check all three tray pieces."
	]
}


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
	# Structural fallback only: keeps letterbox/background pixels theme-correct.
	var viewport_bg := ColorRect.new()
	viewport_bg.name = "FigmaSurfaceViewportBackground"
	viewport_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_bg.color = Color("#1f1f1f") if _dark() else Color("#e6e3dc")
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(viewport_bg)
	var wide_stage := Control.new()
	wide_stage.name = "FigmaWideSurfaceStage"
	wide_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wide_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(wide_stage)

	var canvas := FigmaReferenceCanvas.new()
	canvas.name = "FigmaSurface390x844"
	content.add_child(canvas)
	var available := content.size
	if available.x <= 2.0 or available.y <= 2.0:
		available = get_viewport_rect().size
	var wide := available.x >= 1180.0 and available.x / maxf(1.0, available.y) >= 1.22
	wide_stage.visible = wide
	if wide:
		canvas.set_fit_bias(0.10, 0.5)
		_build_figma_wide_surface_stage(wide_stage, active, available)

	# Secondary systems now live in restrained game-world colour fields instead of
	# a beige application shell. Information cards remain simple and readable.
	var bg := PanelContainer.new()
	bg.name = "FigmaSurfaceBackground"
	var accent := _figma_surface_accent(active)
	var light_top := top_tint.lerp(accent.lightened(0.62), 0.18)
	var light_mid := Color("#eef1ee").lerp(accent.lightened(0.68), 0.24)
	var light_bottom := bottom_tint.lerp(accent.lightened(0.56), 0.20)
	var dark_top := Color("#1c2027").lerp(accent.darkened(0.64), 0.26)
	var dark_mid := Color("#171b22").lerp(accent.darkened(0.70), 0.22)
	var dark_bottom := Color("#11151c").lerp(accent.darkened(0.76), 0.20)
	bg.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		dark_top if _dark() else light_top,
		dark_mid if _dark() else light_mid,
		dark_bottom if _dark() else light_bottom,
		34,
		Color(accent, 0.14),
		1,
		0.15
	))
	FigmaReferenceCanvas.set_rect(bg, 0, 0, 390, 844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	if active in ["compete", "friends", "goals", "profile", "collection", "daily"]:
		var art := META_ART_SCRIPT.new()
		art.name = "MetaArt/%s" % active.capitalize()
		art.configure(active, _dark())
		FigmaReferenceCanvas.set_rect(art, 0, 0, 390, 844)
		canvas.add_child(art)
	return canvas

func _build_figma_wide_surface_stage(stage: Control, active: String, available: Vector2) -> void:
	var accent := _figma_surface_accent(active)
	var dark := _dark()

	# A pair of soft halos establishes depth without turning the wide region into
	# a second dark card. The authored illustration below remains the visual hero.
	for halo_data in [
		[Vector2(available.x * 0.61, available.y * 0.16), minf(available.y * 0.44, available.x * 0.22), 0.10],
		[Vector2(available.x * 0.78, available.y * 0.56), minf(available.y * 0.34, available.x * 0.18), 0.055],
	]:
		var halo := PanelContainer.new()
		halo.name = "FigmaWideSurfaceHalo"
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var halo_size: float = float(halo_data[1])
		halo.position = Vector2(halo_data[0])
		halo.size = Vector2(halo_size, halo_size)
		halo.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(accent.r, accent.g, accent.b, float(halo_data[2])), halo_size * 0.50))
		stage.add_child(halo)

	var mark := TextureRect.new()
	mark.name = "FigmaWideSurfaceWordmark"
	mark.texture = UNJAM_WORDMARK
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark_w := minf(available.x * 0.24, 560.0)
	mark.position = Vector2(available.x * 0.58, available.y * 0.055)
	mark.size = Vector2(mark_w, mark_w * 0.265)
	stage.add_child(mark)

	var title_text := active.to_upper()
	if active == "games":
		title_text = _wide_selected_game_name()
	elif active == "compete":
		title_text = "RANKINGS"
	var title := FigmaReferenceCanvas.label(title_text, int(clampf(available.y * 0.036, 38.0, 62.0)), Color.WHITE, true)
	title.name = "FigmaWideSurfaceTitle"
	FigmaReferenceCanvas.style_display_title(title, accent.lightened(0.18), Color("#09141f"), 3)
	title.position = Vector2(available.x * 0.56, available.y * 0.15)
	title.size = Vector2(available.x * 0.37, available.y * 0.07)
	stage.add_child(title)

	var subtitle := FigmaReferenceCanvas.label(_wide_surface_subtitle(active), int(clampf(available.y * 0.014, 18.0, 26.0)), Color("#d7e1ea") if dark else Color("#354450"), true)
	subtitle.name = "FigmaWideSurfaceSubtitle"
	subtitle.position = Vector2(available.x * 0.56, available.y * 0.215)
	subtitle.size = Vector2(available.x * 0.36, available.y * 0.045)
	stage.add_child(subtitle)

	if WIDE_META_ART.has(active):
		var art := TextureRect.new()
		art.name = "FigmaWideMetaArtwork"
		art.texture = WIDE_META_ART[active] as Texture2D
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.position = Vector2(available.x * 0.50, available.y * 0.255)
		art.size = Vector2(available.x * 0.47, available.y * 0.70)
		stage.add_child(art)
	else:
		var game_art := GAME_ART_SCRIPT.new()
		game_art.name = "FigmaWideGameArt"
		game_art.configure(_wide_selected_game_id(), false, dark)
		var art_side := minf(available.y * 0.60, available.x * 0.34)
		game_art.position = Vector2(available.x * 0.62, available.y * 0.30)
		game_art.size = Vector2(art_side, art_side)
		game_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(game_art)

func _wide_selected_game_id() -> String:
	var id := String(selected_game_id)
	return id if id in ["rescue_rush", "water_sort", "block_puzzle"] else "rescue_rush"

func _wide_selected_game_name() -> String:
	match _wide_selected_game_id():
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _wide_surface_subtitle(active: String) -> String:
	match active:
		"compete": return "CAMPAIGN PROGRESS • LEAGUES • WEEKLY RANK"
		"friends": return "PLAYMATES • PRIVATE CODES • FRIEND RANKINGS"
		"goals": return "DAILY MISSIONS • WEEKLY MISSIONS • SEASON JOURNEY"
		"profile": return "PLAYER STATS • ACHIEVEMENTS • GAME MASTERY"
		"collection": return "RESCUE GARDEN • UPGRADES • PERMANENT BONUSES"
		"daily": return "CHECK-IN • DAILY PUZZLES • REWARDS"
		"settings": return "SOUND • COMFORT • APPEARANCE • SUPPORT"
		"games": return "CHOOSE A WORLD • KEEP YOUR CAMPAIGN MOVING"
		_: return "UNJAM • THREE PUZZLES • ONE JOURNEY"

func _figma_surface_accent(active: String) -> Color:
	match active:
		"compete":
			return FIGMA_GOLD
		"friends":
			return Color("#7a57e0")
		"goals":
			return FIGMA_ORANGE
		"profile":
			return Color("#8066e8")
		"collection":
			return FIGMA_GREEN
		"daily":
			return Color("#f0a33b")
		"games":
			return _accent()
		_:
			return Color("#6b8498")

func _figma_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color = FIGMA_INK, center := false) -> Label:
	# Small secondary labels use the readable weight; the heavyweight display
	# face muddies glyphs after 390x844 reference scaling on compact Android.
	var label := FigmaReferenceCanvas.label(text_value, font_size, _figma_theme_text(color), font_size >= 15)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	label.clip_text = true
	label.set_meta("unjam_authored_rect", rect)
	FigmaReferenceCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	# Figma rectangles are authoritative. Label font minimums must never silently
	# enlarge a text control into a neighboring card/button or beyond the screen.
	label.custom_minimum_size = Vector2.ZERO
	label.position = rect.position
	label.size = rect.size
	canvas.add_child(label)
	return label

func _fit_single_line_control_text(control: Control, max_width: float, start_size: int, min_size: int = 10) -> void:
	if control == null or max_width <= 0.0:
		return
	var font := control.get_theme_font("font")
	if font == null:
		return
	var authored_position := control.position
	var authored_size := control.size
	if control.has_meta("unjam_authored_rect"):
		var authored_rect: Rect2 = control.get_meta("unjam_authored_rect")
		authored_position = authored_rect.position
		authored_size = authored_rect.size
	var text_value := ""
	if control is Label:
		text_value = (control as Label).text
	elif control is Button:
		text_value = (control as Button).text
	else:
		return
	var size := start_size
	while size > min_size and font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		size -= 1
	control.add_theme_font_size_override("font_size", size)
	control.custom_minimum_size = Vector2.ZERO
	control.position = authored_position
	control.size = authored_size
	if control is Label:
		var fitted_label := control as Label
		fitted_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		fitted_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		fitted_label.clip_text = true
		fitted_label.custom_minimum_size = Vector2.ZERO
		fitted_label.position = authored_position
		fitted_label.size = authored_size
func _fit_wrapped_text(label: Label, max_width: float, start_size: int, min_size: int = 10) -> void:
	if label == null or max_width <= 0.0:
		return
	var font := label.get_theme_font("font")
	if font == null:
		return
	var authored_position := label.position
	var authored_size := label.size
	if label.has_meta("unjam_authored_rect"):
		var authored_rect: Rect2 = label.get_meta("unjam_authored_rect")
		authored_position = authored_rect.position
		authored_size = authored_rect.size
	var raw_text := label.text.strip_edges()
	var words := raw_text.split(" ", false)
	var size := start_size
	# First guarantee that even the longest token can fit inside the card.
	while size > min_size:
		var token_too_wide := false
		for word in words:
			if font.get_string_size(String(word), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
				token_too_wide = true
				break
		if not token_too_wide:
			break
		size -= 1
	label.add_theme_font_size_override("font_size", size)

	# Build explicit measured lines. This removes any dependence on Label minimum
	# size/autowrap quirks and keeps every Sidekick tip inside the visible card.
	if words.is_empty():
		return
	var wrapped: Array[String] = []
	var current := ""
	for word in words:
		var word_text := String(word)
		var candidate := word_text if current.is_empty() else "%s %s" % [current, word_text]
		if current.is_empty() or font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			current = candidate
		else:
			wrapped.append(current)
			current = word_text
	if not current.is_empty():
		wrapped.append(current)
	label.text = "\n".join(wrapped)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.custom_minimum_size = Vector2.ZERO
	label.position = authored_position
	label.size = authored_size


func _figma_button(canvas: Control, name_value: String, text_value: String, rect: Rect2, fill: Color, callback: Callable, text_color: Color = FIGMA_OFF_WHITE, radius: float = 14.0, font_size: int = 12) -> Button:
	var resolved_fill := fill
	var resolved_text := text_color
	if _dark() and fill.get_luminance() > 0.82:
		resolved_fill = Color("#2a2b2e")
		resolved_text = FIGMA_DARK_INK
	var button := FigmaReferenceCanvas.premium_button(text_value, font_size, resolved_text, resolved_fill, radius, Color(resolved_fill.r, resolved_fill.g, resolved_fill.b, 0.38), 1)
	button.name = name_value
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.set_meta("unjam_authored_rect", rect)
	FigmaReferenceCanvas.set_rect(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	_fit_single_line_control_text(button, maxf(24.0, rect.size.x - 18.0), font_size, 10)
	if callback.is_valid():
		button.pressed.connect(callback)
	canvas.add_child(button)
	return button

func _figma_card(canvas: Control, name_value: String, rect: Rect2, tint: Color = Color(1.0, 0.995, 0.97), accent: Color = Color(0.70, 0.88, 0.96, 0.45), radius: float = 16.0) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = name_value
	var base_tint := Color("#282a2e") if _dark() else Color("#fffaf2")
	var resolved_tint := base_tint.lerp(Color(accent.r,accent.g,accent.b,1.0),0.035)
	var resolved_accent := Color(accent.r, accent.g, accent.b, 0.34 if _dark() else 0.30)
	card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.flat_gloss(resolved_tint, radius, resolved_accent, 1, 0.17))
	FigmaReferenceCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)
	return card

func _figma_solid_card(canvas: Control, name_value: String, rect: Rect2, tint: Color, border: Color, radius: float = 16.0, with_shadow: bool = true) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = name_value
	var resolved_tint := tint
	var resolved_border := Color(border.r, border.g, border.b, minf(border.a, 0.34))
	if not _dark() and tint.get_luminance() > 0.72:
		resolved_tint = Color("#f5f2ec")
	elif _dark() and tint.get_luminance() > 0.72:
		resolved_tint = Color("#27282b")
	card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.flat_gloss(resolved_tint, radius, resolved_border, 1, 0.10))
	FigmaReferenceCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)
	return card

func _figma_header(canvas: Control, title_text: String, subtitle_text: String, pill_text: String, pill_fill: Color, back_callback: Callable = Callable(self, "build_home"), pill_callback: Callable = Callable(), dark_mode: bool = false) -> void:
	var use_dark := dark_mode or _dark()
	var heading_color := FIGMA_OFF_WHITE if not use_dark else FIGMA_DARK_INK
	var muted_color := FIGMA_MUTED if not use_dark else FIGMA_DARK_MUTED
	var back_color := FIGMA_DARK_INK if use_dark else FIGMA_NAVY
	var back_fill := Color("#cbc4b8") if not use_dark else Color("#2c2c2c")
	var back_button := _figma_button(canvas, "FigmaBack", "←", Rect2(17,19,52,52), back_fill, back_callback, back_color, 18, 27)
	back_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	back_button.tooltip_text = "Back"
	var header_title := _figma_text(canvas, title_text, Rect2(83,21,186,27), 23, heading_color)
	header_title.name = "FigmaHeaderTitle"
	header_title.clip_text = true
	# Apply the display font before fitting so its actual metrics cannot expand
	# back into the subtitle band after compact-screen layout.
	FigmaReferenceCanvas.style_display_title(header_title, pill_fill.lightened(0.20), Color("#071d55"), 1)
	_fit_single_line_control_text(header_title, 182.0, 23, 14)
	if not subtitle_text.strip_edges().is_empty():
		var subtitle := _figma_text(canvas, subtitle_text, Rect2(83,55,186,18), 13, muted_color)
		subtitle.name = "FigmaHeaderSubtitle"
		subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
		subtitle.clip_text = true
		subtitle.custom_minimum_size = Vector2.ZERO
		_fit_single_line_control_text(subtitle, 182.0, 13, 8)
		# Font fitting can leave an older Label minimum cached. Reassert the
		# authored one-line lane so the subtitle never grows into the header pill.
		subtitle.custom_minimum_size = Vector2.ZERO
		subtitle.position = Vector2(83,55)
		subtitle.size = Vector2(186,18)
	if pill_text.strip_edges().is_empty():
		return
	if pill_callback.is_valid():
		var pill_button := _figma_button(canvas, "FigmaHeaderPill", pill_text, Rect2(285,21,84,46), pill_fill, pill_callback, FIGMA_OFF_WHITE, 23, 12)
		if pill_text.begins_with("◈"):
			# Preserve the Figma/runtime text contract ("◈ +") for automation and
			# accessibility while the faceted 3D gem sits directly over the glyph.
			FigmaReferenceCanvas.add_collectible_gem(canvas, Vector2(301,44), 8.0, "HeaderCurrencyGem3D")
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
		var pill_text_color := FigmaReferenceCanvas.accessible_text_color(FIGMA_OFF_WHITE, pill_fill)
		var pill_label := _figma_text(canvas, pill_text, Rect2(297,29,60,30), 12, pill_text_color, true)
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
	var bar_fill := Color("#252629") if use_dark else Color("#f0ede6")
	var bar_border := Color("#3a3d42") if use_dark else Color("#cbc6bc")
	_figma_solid_card(canvas, "StdNav/Bar", Rect2(13,757,362,70), bar_fill, bar_border, 18, false)
	# Keep the legacy node name for regression compatibility, but use it as a
	# quiet divider instead of a glossy highlight.
	_figma_solid_card(
		canvas,
		"StdNavTopGloss",
		Rect2(30,760,328,1),
		Color(1,1,1,0.08 if use_dark else 0.34),
		Color.TRANSPARENT,
		1,
		false
	)
	var xs := {"home":22.0, "games":94.0, "daily":166.0, "collection":238.0, "settings":310.0}
	var hit_x := {"home":14.0, "games":86.0, "daily":158.0, "collection":230.0, "settings":302.0}
	var names := {"home":"HOME", "games":"GAMES", "daily":"DAILY", "collection":"COLLECT", "settings":"SETTINGS"}
	var glyphs := {"home":"⌂", "games":"▦", "daily":"★", "collection":"◆", "settings":"⚙"}
	var callbacks := {
		"home": Callable(self,"build_home"),
		"games": Callable(self,"_open_games_surface"),
		"daily": Callable(self,"build_daily_games"),
		"collection": Callable(self,"build_collection"),
		"settings": Callable(self,"build_settings"),
	}
	for key in ["home","games","daily","collection","settings"]:
		var selected: bool = String(key) == active
		var accent := FIGMA_GOLD
		var selected_text := FIGMA_DARK_INK if use_dark else FIGMA_INK
		var idle_text := Color("#98a2ad") if use_dark else Color("#66707a")
		var icon_color := accent if selected else idle_text
		if selected:
			var plate_fill := Color(accent.r, accent.g, accent.b, 0.12 if use_dark else 0.15)
			var plate_border := Color(accent.r, accent.g, accent.b, 0.38 if use_dark else 0.44)
			_figma_solid_card(
				canvas,
				"StdNavActivePlate_%s" % String(key),
				Rect2(float(hit_x[key])+7.0,761,58,58),
				plate_fill,
				plate_border,
				14,
				false
			)
			# Keep this node as a tiny accent marker instead of a lacquer shine.
			_figma_solid_card(
				canvas,
				"StdNavActiveShine_%s" % String(key),
				Rect2(float(hit_x[key])+24.0,763,24,2),
				Color(accent.r,accent.g,accent.b,0.82),
				Color.TRANSPARENT,
				1,
				false
			)
		var glyph := _figma_text(canvas, String(glyphs[key]), Rect2(float(xs[key])-1.0,761,58,24), 18, icon_color, true)
		glyph.name = "StdNavGlyph_%s" % String(key)
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var label_width := 66.0 if String(key) in ["collection", "settings"] else 58.0
		var label_x := float(hit_x[key]) + (72.0 - label_width) * 0.5
		var nav_label := _figma_text(canvas, String(names[key]), Rect2(label_x,803,label_width,18), 13, selected_text if selected else idle_text, selected)
		nav_label.name = "StdNavLabel_%s" % String(key)
		nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nav_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nav_label.clip_text = true
		nav_label.custom_minimum_size = Vector2.ZERO
		nav_label.position = Vector2(label_x, 803)
		nav_label.size = Vector2(label_width, 18)
		_fit_single_line_control_text(nav_label, label_width - 2.0, 13, 10)
		var hit := Button.new()
		hit.name = "StdNavHit_%s" % String(key).to_upper()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		hit.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		FigmaReferenceCanvas.set_rect(hit, float(hit_x[key]),753,72,78)
		if not selected:
			var cb: Callable = callbacks[key]
			hit.pressed.connect(cb)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)

func _toggle_settings_theme() -> void:
	if _settings_theme_toggle_pending:
		return
	var shell := get_node_or_null("UXShell")
	if shell == null or not shell.has_method("_toggle_theme"):
		return
	_settings_theme_toggle_pending = true
	shell.call("_toggle_theme")
	call_deferred("_finish_settings_theme_toggle")


func _finish_settings_theme_toggle() -> void:
	_settings_theme_toggle_pending = false
	if current_surface == "settings":
		build_settings()


func build_goals() -> void:
	current_surface = "goals"
	_remove_active_game()
	var canvas := _figma_surface("goals", Color("#e8e0c8"))
	var ready := MetaProgressionManager.ready_claim_count()
	var goals_card_fill := Color("#27282b") if _dark() else Color("#fffef8")
	_figma_header(canvas, "GOALS", "Live rewards • %d ready" % ready, "◈ +", FIGMA_ORANGE, Callable(self,"build_home"), Callable(self,"_figma_open_shop"))

	var login := MetaProgressionManager.daily_login_info()
	_figma_card(canvas, "GoalsLogin", Rect2(17,91,354,72), goals_card_fill, Color(FIGMA_ORANGE,0.36), 17)
	_figma_text(canvas, "DAILY CHECK-IN • DAY %d/7" % int(login.get("day",1)), Rect2(31,103,208,22), 15, FIGMA_INK)
	_figma_text(canvas, "+%d COINS" % int(login.get("reward",0)), Rect2(31,129,150,20), 13, FIGMA_GOLD)
	var login_claimed := bool(login.get("claimed",false))
	var login_button := _figma_button(canvas,"GoalsLoginClaim","CLAIMED" if login_claimed else "CLAIM",Rect2(260,104,92,44),Color("#7d8a94") if login_claimed else FIGMA_ORANGE,Callable(),Color.WHITE,13,12)
	login_button.disabled = login_claimed
	if not login_claimed:
		login_button.pressed.connect(_claim_daily_login)

	_figma_text(canvas, "DAILY MISSIONS", Rect2(19,178,180,20), 15, FIGMA_GOLD)
	var daily_rows := MetaProgressionManager.daily_goals()
	for i in range(daily_rows.size()):
		_figma_goal_row(canvas, daily_rows[i] as Dictionary, "daily", 202.0 + float(i) * 50.0)

	_figma_text(canvas, "WEEKLY MISSIONS", Rect2(19,356,190,20), 15, FIGMA_GOLD)
	var weekly_rows := MetaProgressionManager.weekly_goals()
	for i in range(weekly_rows.size()):
		_figma_goal_row(canvas, weekly_rows[i] as Dictionary, "weekly", 380.0 + float(i) * 50.0)

	var season := MetaProgressionManager.season_info()
	_figma_card(canvas, "GoalsSeason", Rect2(17,548,354,134), goals_card_fill, Color("#7a57e0"), 18)
	_figma_text(canvas, "SEASON JOURNEY", Rect2(31,560,190,22), 16, Color("#7a57e0"))
	_figma_text(canvas, "%d PTS • %d/%d TIERS" % [int(season.get("points",0)),int(season.get("completed",0)),int(season.get("tiers",0))], Rect2(31,587,210,20), 13, FIGMA_MUTED)
	var next_target := int(season.get("next_target",0))
	var journey_detail := "ALL TIERS COMPLETE" if next_target <= 0 else "NEXT REWARD AT %d PTS" % next_target
	var journey_label := _figma_text(canvas, journey_detail, Rect2(31,613,202,18), 11, FIGMA_MUTED)
	journey_label.name = "GoalsSeasonNextReward"
	_fit_single_line_control_text(journey_label,198.0,11,9)
	var season_ready := int(season.get("ready",0))
	var season_button := _figma_button(canvas,"GoalsSeasonClaim","CLAIM %d" % season_ready if season_ready > 0 else "IN PROGRESS",Rect2(246,575,106,46),FIGMA_GREEN if season_ready > 0 else Color("#7d8a94"),Callable(),Color.WHITE,13,11)
	season_button.disabled = season_ready <= 0
	if season_ready > 0:
		season_button.pressed.connect(_claim_next_season_reward)
	_figma_text(canvas, "First clears +10 • Daily Cup +25 • Replays +3", Rect2(31,646,310,18), 11, FIGMA_MUTED)
	_figma_bottom_nav(canvas,"home")

func _figma_goal_row(canvas: Control, row: Dictionary, period: String, y: float) -> void:
	var claimable := bool(row.get("claimable",false))
	var claimed := bool(row.get("claimed",false))
	var fill := Color("#f5f2ec") if not _dark() else Color("#27282b")
	var border := Color(FIGMA_GREEN,0.34) if claimable else Color(FIGMA_GOLD,0.20)
	_figma_card(canvas,"Goal/%s/%s" % [period,String(row.get("id",""))],Rect2(17,y,354,44),fill,border,13)
	var goal_title := _figma_text(canvas,String(row.get("title","GOAL")),Rect2(30,y+4,172,18),13,FIGMA_INK)
	goal_title.name = "GoalTitle/%s/%s" % [period,String(row.get("id",""))]
	_fit_single_line_control_text(goal_title,168.0,13,11)
	var crowns := int(row.get("crowns",0))
	var reward_text := "+%d" % int(row.get("coins",0))
	if crowns > 0:
		reward_text += " • ♛%d" % crowns
	var goal_progress := _figma_text(canvas,"%d/%d • %s" % [int(row.get("progress",0)),int(row.get("target",1)),reward_text],Rect2(30,y+24,190,16),11,FIGMA_MUTED)
	goal_progress.name = "GoalProgress/%s/%s" % [period,String(row.get("id",""))]
	_fit_single_line_control_text(goal_progress,186.0,11,10)
	var action_text := "DONE" if claimed else ("CLAIM" if claimable else "GO")
	var action_fill := Color("#7d8a94") if claimed else (FIGMA_GREEN if claimable else Color("#7a57e0"))
	var action := _figma_button(canvas,"GoalAction/%s/%s" % [period,String(row.get("id",""))],action_text,Rect2(274,y,78,44),action_fill,Callable(),Color.WHITE,11,10)
	action.disabled = claimed
	if claimable:
		action.pressed.connect(_claim_goal.bind(period,String(row.get("id",""))))
	elif not claimed:
		action.pressed.connect(build_home)

func _claim_daily_login() -> void:
	if MetaProgressionManager.claim_daily_login() > 0:
		FeedbackManager.effect()
	build_goals()

func _claim_goal(period: String, id: String) -> void:
	if MetaProgressionManager.claim_goal(period,id):
		FeedbackManager.effect()
	build_goals()

func _claim_next_season_reward() -> void:
	if MetaProgressionManager.claim_next_ready_season_tier():
		FeedbackManager.effect()
	build_goals()

func build_profile() -> void:
	current_surface = "profile"
	_remove_active_game()
	var canvas := _figma_surface("profile", Color("#d8e9f5"))
	var profile_card_fill := Color("#27282b") if _dark() else Color("#fffef8")
	_figma_header(canvas, "PROFILE", "LV %d • PLAYER STATS" % MetaProgressionManager.player_level(), "◈ +", FIGMA_CYAN, Callable(self,"build_home"), Callable(self,"_figma_open_shop"))

	_figma_card(canvas,"ProfileIdentity",Rect2(17,91,354,70),profile_card_fill,Color(FIGMA_CYAN,0.34),17)
	var name_edit := LineEdit.new()
	name_edit.name = "ProfileNameEdit"
	name_edit.text = CompetitionManager.display_name()
	name_edit.placeholder_text = "PLAYER NAME"
	name_edit.max_length = 20
	name_edit.add_theme_font_size_override("font_size",15)
	name_edit.add_theme_color_override("font_color",_figma_theme_text(FIGMA_INK))
	name_edit.add_theme_color_override("font_placeholder_color",Color("#8f99a5") if _dark() else Color("#68717b"))
	name_edit.add_theme_stylebox_override("normal",FigmaReferenceCanvas.flat_gloss(Color("#f5f2ec") if not _dark() else Color("#27282b"),12,Color(FIGMA_CYAN,0.34),1,0.08,10.0))
	FigmaReferenceCanvas.set_rect(name_edit,31,104,218,44)
	canvas.add_child(name_edit)
	var save_name := _figma_button(canvas,"ProfileSaveName","SAVE",Rect2(263,104,88,44),FIGMA_CYAN,Callable(),Color.WHITE,13,11)
	save_name.pressed.connect(_save_profile_name.bind(name_edit))

	_figma_card(canvas,"ProfileStats",Rect2(17,176,354,110),profile_card_fill,Color(FIGMA_CYAN,0.24),17)
	var stats := [
		[_compact_stat(MetaProgressionManager.total_levels_completed()),"LEVELS",30.0],
		[_compact_stat(MetaProgressionManager.total_stars()),"STARS",116.0],
		[str(MetaProgressionManager.current_daily_streak()),"STREAK",202.0],
		[str(int(SaveManager.data.get("crown_tokens",0))),"CROWNS",288.0]
	]
	for stat in stats:
		var stat_value := _figma_text(canvas,String(stat[0]),Rect2(float(stat[2]),193,64,21),16,FIGMA_INK)
		_fit_single_line_control_text(stat_value,60.0,16,12)
		var stat_label := _figma_text(canvas,String(stat[1]),Rect2(float(stat[2])-4,218,72,14),10,FIGMA_MUTED)
		_fit_single_line_control_text(stat_label,68.0,10,8)
	var profile_rank := CompetitionManager.game_all_time_rank(_profile_game)
	var rank_text := "UNRANKED" if profile_rank <= 0 else "RANK #%d" % profile_rank
	_figma_text(canvas,"%s • %d/%d ACHIEVEMENTS" % [rank_text,MetaProgressionManager.total_achievements(),MetaProgressionManager.total_achievement_slots()],Rect2(31,244,220,18),11,FIGMA_GOLD)
	var friends_button := _figma_button(canvas,"ProfileFriendsButton","FRIENDS",Rect2(272,240,79,44),Color("#7a57e0"),Callable(self,"build_friends"),Color.WHITE,10,9)
	friends_button.tooltip_text = "Friend codes and campaign progress rankings"

	_figma_text(canvas,"ACHIEVEMENTS",Rect2(19,294,170,20),15,FIGMA_GOLD)
	_figma_profile_game_tabs(canvas)
	var defs := MultiGameManager.achievement_definitions(_profile_game)
	for i in range(defs.size()):
		_figma_achievement_row(canvas,defs[i] as Dictionary,370.0+float(i)*60.0)
	_figma_bottom_nav(canvas,"home")

func _figma_profile_game_tabs(canvas: Control) -> void:
	var ids: Array[String] = ["rescue_rush","water_sort","block_puzzle"]
	var labels: Array[String] = ["RESCUE","WATER","BLOCK"]
	for i in range(ids.size()):
		var selected: bool = _profile_game == ids[i]
		var fill := Unjam3DTheme.game_accent(ids[i]) if selected else Color("#7d8a94")
		var button := _figma_button(canvas,"ProfileGame/%s" % ids[i],labels[i],Rect2(19.0+float(i)*118.0,318,108,44),fill,Callable(),Color.WHITE,11,10)
		if not selected:
			button.pressed.connect(_set_profile_game.bind(ids[i]))
		else:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _figma_achievement_row(canvas: Control, achievement: Dictionary, y: float) -> void:
	var id := String(achievement.get("id",""))
	var need := maxi(1,int(achievement.get("need",1)))
	var progress := MultiGameManager.achievement_progress(_profile_game,id)
	var done := progress >= need
	var accent := FIGMA_GREEN if done else Unjam3DTheme.game_accent(_profile_game)
	_figma_card(canvas,"ProfileAchievement/%s/%s" % [_profile_game,id],Rect2(17,y,354,52),Color("#27282b") if _dark() else Color("#fffef8"),Color(accent,0.28),14)
	var achievement_title := _figma_text(canvas,String(achievement.get("title","Achievement")),Rect2(31,y+6,210,15),12,FIGMA_INK)
	achievement_title.name = "ProfileAchievementTitle/%s" % id
	_fit_single_line_control_text(achievement_title,206.0,12,9)
	var achievement_progress := _figma_text(canvas,"%d / %d" % [mini(progress,need),need],Rect2(31,y+29,150,13),10,FIGMA_MUTED)
	achievement_progress.name = "ProfileAchievementProgress/%s" % id
	_fit_single_line_control_text(achievement_progress,146.0,10,8)
	var status := _figma_text(canvas,"✓" if done else "•",Rect2(315,y+13,28,28),18,accent,true)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _set_profile_game(game_id: String) -> void:
	if game_id in MultiGameManager.GAME_IDS:
		_profile_game = game_id
		build_profile()

func _save_profile_name(name_edit: LineEdit) -> void:
	if name_edit == null or not is_instance_valid(name_edit):
		return
	CompetitionManager.set_display_name(name_edit.text)
	FeedbackManager.effect()
	build_profile()

func build_friends(refresh_remote: bool = true) -> void:
	current_surface = "friends"
	_remove_active_game()
	if refresh_remote:
		var refresh_callback := Callable(self, "_on_friends_social_updated")
		if not CompetitionManager.social_updated.is_connected(refresh_callback):
			CompetitionManager.social_updated.connect(refresh_callback, CONNECT_ONE_SHOT)
		CompetitionManager.refresh_social(_ranking_game)
	var canvas := _figma_surface("friends", Color("#d9e4f5"))
	var friends_card_fill := Color("#282a2e") if _dark() else Color("#fffaf2")
	_figma_header(
		canvas,
		"FRIENDS",
		"Progress • private codes",
		"↻",
		Color("#7a57e0"),
		Callable(self,"build_profile"),
		Callable(self,"_refresh_friends")
	)

	var friend_code := CompetitionManager.friend_code()
	_figma_card(canvas,"FriendsCode",Rect2(17,91,354,76),friends_card_fill,Color(FIGMA_CYAN,0.38),17)
	_figma_text(canvas,"YOUR FRIEND CODE",Rect2(31,103,180,18),13,FIGMA_MUTED)
	var code_text := friend_code if not friend_code.is_empty() else "SYNCING…"
	_figma_text(canvas,code_text,Rect2(31,126,174,27),20,FIGMA_INK,true)
	var copy := _figma_button(canvas,"FriendsCopyCode","COPY",Rect2(218,108,63,44),FIGMA_CYAN,Callable(self,"_copy_friend_code"),Color.WHITE,10,10)
	copy.disabled = friend_code.is_empty()
	var rotate := _figma_button(canvas,"FriendsRotateCode","NEW",Rect2(288,108,63,44),Color("#7a57e0"),Callable(self,"_rotate_friend_code"),Color.WHITE,10,10)
	rotate.disabled = friend_code.is_empty()
	rotate.tooltip_text = "Create a new code. Existing friends stay connected."

	_figma_card(canvas,"FriendsAdd",Rect2(17,180,354,82),friends_card_fill,Color("#7a57e0"),17)
	_figma_text(canvas,"ADD A FRIEND",Rect2(31,191,140,18),13,FIGMA_MUTED)
	var code_input := LineEdit.new()
	code_input.name = "FriendsCodeInput"
	code_input.placeholder_text = "8-CHARACTER CODE"
	code_input.max_length = 10
	code_input.add_theme_font_size_override("font_size",14)
	code_input.add_theme_color_override("font_color",_figma_theme_text(FIGMA_INK))
	code_input.add_theme_color_override("font_placeholder_color",Color("#8f99a5") if _dark() else Color("#68717b"))
	code_input.add_theme_color_override("caret_color",_figma_theme_text(FIGMA_INK))
	code_input.add_theme_stylebox_override("normal",FigmaReferenceCanvas.flat_gloss(Color("#24262a") if _dark() else Color("#fffaf2"),11,Color("#7a57e0"),1,0.16,10.0))
	code_input.custom_minimum_size = Vector2.ZERO
	FigmaReferenceCanvas.set_rect(code_input,31,212,211,44)
	canvas.add_child(code_input)
	var add_button := _figma_button(canvas,"FriendsAddButton","ADD",Rect2(258,212,93,44),Color("#7a57e0"),Callable(),Color.WHITE,12,11)
	add_button.pressed.connect(_add_friend_from_input.bind(code_input))

	var count := CompetitionManager.friend_count()
	_figma_text(canvas,"FRIENDS • %d/%d" % [count,CompetitionManager.max_friends()],Rect2(19,277,190,20),15,FIGMA_INK)
	var global_button := _figma_button(canvas,"FriendsGlobalRanks","GLOBAL",Rect2(286,270,65,44),FIGMA_GOLD,Callable(self,"build_compete_leaderboard"),FIGMA_NAVY,10,11)
	global_button.tooltip_text = "Open global campaign rankings"

	_figma_friend_period_tabs(canvas)
	_figma_compete_game_tabs(canvas, 357.0, true)

	_figma_card(canvas,"FriendsLeaderboard",Rect2(17,411,354,241),friends_card_fill,Color(FIGMA_CYAN,0.34),18)
	var period_title := "ALL-TIME" if _friends_period == "all_time" else "THIS WEEK"
	var game_title := MultiGameManager.display_name(_ranking_game).to_upper()
	_figma_text(canvas,"%s • %s" % [game_title,period_title],Rect2(31,423,250,20),14,Unjam3DTheme.game_accent(_ranking_game))
	var rows := CompetitionManager.friends_all_time() if _friends_period == "all_time" else CompetitionManager.friends_weekly()
	if rows.size() <= 1 and count <= 0:
		var empty_title := _figma_text(canvas,"Share your code to connect.",Rect2(38,474,310,28),14,FIGMA_INK,true)
		empty_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var empty_detail := _figma_text(canvas,"Friends appear here by levels cleared.",Rect2(38,512,310,42),12,FIGMA_MUTED,true)
		_fit_wrapped_text(empty_detail,300.0,12,11)
	else:
		var shown := mini(4,rows.size())
		for i in range(shown):
			_figma_friend_rank_row(canvas,rows[i] as Dictionary,i,448.0+float(i)*46.0)

	var status_text := _friends_status
	if status_text.is_empty():
		status_text = "Only your name and level rank are public."
	var privacy_note := _figma_text(canvas,status_text,Rect2(31,663,328,36),11,FIGMA_MUTED,true)
	privacy_note.name = "FriendsPrivacyNote"
	privacy_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fit_wrapped_text(privacy_note,316.0,11,9)
	privacy_note.custom_minimum_size = Vector2.ZERO
	privacy_note.position = Vector2(31,663)
	privacy_note.size = Vector2(328,36)
	_figma_bottom_nav(canvas,"home")

func _figma_friend_period_tabs(canvas: Control) -> void:
	var specs := [
		["all_time","ALL-TIME",19.0],
		["weekly","WEEKLY",128.0],
	]
	for spec in specs:
		var period := String(spec[0])
		var selected := _friends_period == period
		var fill := Color("#7a57e0") if selected else (Color("#36383d") if _dark() else Color("#d8d2c8"))
		var text_color := Color.WHITE if selected else FIGMA_INK
		var button := _figma_button(canvas,"FriendsPeriod/%s" % period,String(spec[1]),Rect2(float(spec[2]),307,101,44),fill,Callable(),text_color,9,11)
		if not selected:
			button.pressed.connect(_set_friends_period.bind(period))
		else:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_friends_period(period: String) -> void:
	if period in ["all_time","weekly"]:
		_friends_period = period
		build_friends(false)

func _figma_friend_rank_row(canvas: Control, row: Dictionary, index: int, y: float) -> void:
	var is_you := bool(row.get("you",false))
	var accent := FIGMA_CYAN if is_you else Unjam3DTheme.game_accent(_ranking_game)
	var rank := int(row.get("rank",index+1))
	_figma_text(canvas,"YOU" if is_you else str(rank),Rect2(30,y+6,38,24),13,accent,true)
	_figma_text(canvas,String(row.get("name","PLAYER")).left(15),Rect2(75,y+6,130,24),13,FIGMA_INK)
	var levels := maxi(0,int(row.get("levels_completed",0)))
	var stars := maxi(0,int(row.get("stars",0)))
	var progress := _figma_text(canvas,"L%d • ★%d" % [levels,stars],Rect2(205,y+6,96,24),12,FIGMA_MUTED,true)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not is_you:
		var code := String(row.get("friend_code",""))
		var remove := _figma_button(canvas,"FriendRemove/%d" % index,"×",Rect2(304,y,44,44),Color("#7d8a94"),Callable(),Color.WHITE,12,15)
		remove.tooltip_text = "Remove friend"
		if not code.is_empty():
			remove.pressed.connect(_remove_friend.bind(code))
		else:
			remove.disabled = true

func _refresh_friends() -> void:
	_friends_status = "Refreshing…"
	var callback := Callable(self,"_on_friends_social_updated")
	if not CompetitionManager.social_updated.is_connected(callback):
		CompetitionManager.social_updated.connect(callback, CONNECT_ONE_SHOT)
	CompetitionManager.refresh_social(_ranking_game)

func _on_friends_social_updated(_snapshot: Dictionary) -> void:
	if current_surface == "friends":
		_friends_status = ""
		build_friends(false)

func _copy_friend_code() -> void:
	var code := CompetitionManager.friend_code()
	if code.is_empty():
		return
	DisplayServer.clipboard_set(code)
	_friends_status = "Friend code copied."
	FeedbackManager.effect()
	build_friends(false)

func _rotate_friend_code() -> void:
	var callback := Callable(self,"_on_friend_action_finished")
	if not CompetitionManager.social_action_finished.is_connected(callback):
		CompetitionManager.social_action_finished.connect(callback, CONNECT_ONE_SHOT)
	_friends_status = "Creating a new code…"
	CompetitionManager.rotate_friend_code()

func _add_friend_from_input(code_input: LineEdit) -> void:
	if code_input == null or not is_instance_valid(code_input):
		return
	var callback := Callable(self,"_on_friend_action_finished")
	if not CompetitionManager.social_action_finished.is_connected(callback):
		CompetitionManager.social_action_finished.connect(callback, CONNECT_ONE_SHOT)
	_friends_status = "Adding friend…"
	CompetitionManager.add_friend(code_input.text)

func _remove_friend(code: String) -> void:
	var callback := Callable(self,"_on_friend_action_finished")
	if not CompetitionManager.social_action_finished.is_connected(callback):
		CompetitionManager.social_action_finished.connect(callback, CONNECT_ONE_SHOT)
	_friends_status = "Removing friend…"
	CompetitionManager.remove_friend(code)

func _on_friend_action_finished(ok: bool, message: String) -> void:
	_friends_status = message
	if ok:
		FeedbackManager.effect()
	else:
		FeedbackManager.blocked()
	if current_surface == "friends":
		build_friends(false)

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
	_figma_header(canvas, "SETTINGS", "", "", FIGMA_GOLD, Callable(self,"build_home"), Callable(), dark_mode)
	if not dark_mode:
		var settings_title := canvas.get_node_or_null("FigmaHeaderTitle") as Label
		if settings_title != null:
			settings_title.add_theme_color_override("font_color",FIGMA_INK)

	var card_fill := Color("#27282b") if dark_mode else Color("#f5f2ec")
	var card_border := Color("#3a3d42") if dark_mode else Color("#cbc6bc")
	var heading_color := FIGMA_GOLD.lightened(0.08) if dark_mode else Color("#7c5c16")
	var muted_color := Color("#b8c2cc") if dark_mode else FIGMA_MUTED

	_figma_settings_card(canvas,"SettingsCard/Sound",Rect2(17,91,354,170),card_fill,card_border,dark_mode)
	_figma_text(canvas,"SOUND",Rect2(33,107,160,18),15,heading_color)
	_figma_setting_row(canvas,"sound","SOUND EFFECTS",130,142,true,false,dark_mode)
	_figma_setting_row(canvas,"music","MUSIC",178,190,true,false,dark_mode)
	_figma_setting_row(canvas,"vibration","HAPTICS",226,238,true,false,dark_mode)

	_figma_settings_card(canvas,"SettingsCard/Comfort",Rect2(17,275,354,120),card_fill,card_border,dark_mode)
	_figma_text(canvas,"COMFORT",Rect2(33,291,130,18),15,heading_color)
	_figma_setting_row(canvas,"reduce_motion","REDUCED MOTION",314,326,false,true,dark_mode)
	_figma_setting_row(canvas,"fast_animation","FAST ANIMATION",358,370,false,false,dark_mode)

	_figma_settings_card(canvas,"SettingsCard/Appearance",Rect2(17,409,354,76),card_fill,card_border,dark_mode)
	_figma_text(canvas,"APPEARANCE",Rect2(33,425,150,18),15,heading_color)
	_figma_text(canvas,"THEME",Rect2(33,448,210,28),14,muted_color)
	var theme_fill := FIGMA_GOLD
	var theme_text := FIGMA_NAVY
	var theme_button := _figma_button(canvas,"SettingsThemeToggle",theme_name,Rect2(279,439,72,44),theme_fill,Callable(),theme_text,19,15)
	theme_button.pressed.connect(_toggle_settings_theme)

	var help_card: PanelContainer
	if dark_mode:
		help_card = _figma_solid_card(canvas,"HelpPrivacy",Rect2(17,499,354,94),card_fill,card_border,18)
	else:
		help_card = _figma_solid_card(canvas,"HelpPrivacy",Rect2(17,499,354,94),Color("#f5f2ec"),Color("#cbc6bc"),18)
	_figma_text(canvas,"SUPPORT",Rect2(33,515,170,18),15,heading_color)
	var utility_fill := Color("#2d2e31") if dark_mode else Color("#ebe7df")
	var utility_border := Color("#44474c") if dark_mode else Color("#cbc6bc")
	var utility_text := FIGMA_DARK_INK if dark_mode else FIGMA_NAVY
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(33,541,126,46), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var how_to := FigmaReferenceCanvas.premium_button("HOW TO PLAY",15,utility_text,utility_fill,16,utility_border,1.2)
	how_to.name = "SettingsHowToPlay"
	FigmaReferenceCanvas.set_rect(how_to,33,541,126,46)
	how_to.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	how_to.pressed.connect(_show_current_tutorial)
	canvas.add_child(how_to)
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(167,541,90,46), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var help_game := FigmaReferenceCanvas.premium_button(_settings_help_game_label(),12,utility_text,utility_fill,16,utility_border,1.2)
	help_game.name = "SettingsHowToPlayGame"
	FigmaReferenceCanvas.set_rect(help_game,167,541,90,46)
	help_game.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	help_game.pressed.connect(_cycle_settings_help_game.bind(help_game))
	canvas.add_child(help_game)
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(265,541,86,46), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var privacy := FigmaReferenceCanvas.premium_button("PRIVACY",15,utility_text,utility_fill,16,utility_border,1.2)
	privacy.name = "SettingsPrivacy"
	FigmaReferenceCanvas.set_rect(privacy,265,541,86,46)
	privacy.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	canvas.add_child(privacy)

	_figma_settings_card(canvas,"SettingsCard/Purchases",Rect2(17,607,354,98),card_fill,card_border,dark_mode)
	_figma_text(canvas,"PURCHASES",Rect2(33,621,170,18),15,heading_color)
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(33,645,318,46), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var purchases := FigmaReferenceCanvas.premium_button("SHOP & RESTORE",15,utility_text,utility_fill,16,utility_border,1.2)
	purchases.name = "SettingsPurchases"
	purchases.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	FigmaReferenceCanvas.set_rect(purchases,33,645,318,46)
	purchases.tooltip_text = "Buy upgrades or restore previous Google Play purchases"
	purchases.pressed.connect(_figma_open_shop)
	canvas.add_child(purchases)

	_figma_bottom_nav(canvas,"settings",dark_mode)

func _figma_settings_card(canvas: Control, name_value: String, rect: Rect2, fill: Color, border: Color, dark_mode: bool) -> PanelContainer:
	var card: PanelContainer
	if dark_mode:
		card = _figma_solid_card(canvas,name_value,rect,fill,border,18)
	else:
		card = _figma_card(canvas,name_value,rect,fill,border,18)
	return card

func _figma_setting_row(canvas: Control, key: String, label_text: String, toggle_y: float, label_y: float, default_value: bool = true, reduced_motion: bool = false, dark_mode: bool = false) -> void:
	var text_color := Color(0.76,0.84,0.90) if dark_mode else FIGMA_INK
	_figma_text(canvas,label_text,Rect2(34,label_y-7,210,30),15,text_color)
	var enabled := bool(SaveManager.data.get(key,default_value))
	var fill := FIGMA_GOLD if enabled else Color("#b2bfcc")
	var button_text_color := FIGMA_OFF_WHITE if enabled else FIGMA_NAVY
	var state := "ON" if enabled else "OFF"
	var button := _figma_button(canvas,"SettingToggle/%s" % key.capitalize(),state,Rect2(279,toggle_y-3.0,72,44),fill,Callable(),button_text_color,19,15)
	if reduced_motion:
		button.pressed.connect(_toggle_reduced_motion)
	else:
		button.pressed.connect(_toggle_setting.bind(key))

func _toggle_reduced_motion() -> void:
	var enabled := not bool(SaveManager.data.get("reduce_motion", false))
	SaveManager.data["reduce_motion"] = enabled
	SaveManager.save()
	MotionSystem.refresh_preferences()
	PremiumVisuals.apply_motion_preference()
	FeedbackManager.tap()
	build_settings()

func _settings_help_game_label() -> String:
	match _settings_help_game:
		"water_sort": return "WATER ›"
		"block_puzzle": return "BLOCK ›"
		_: return "RESCUE ›"

func _cycle_settings_help_game(button: Button) -> void:
	var index := SETTINGS_HELP_GAMES.find(_settings_help_game)
	_settings_help_game = SETTINGS_HELP_GAMES[(index + 1) % SETTINGS_HELP_GAMES.size()]
	if button != null and is_instance_valid(button):
		button.text = _settings_help_game_label()
	FeedbackManager.tap()

func _show_current_tutorial() -> void:
	var shell := get_node_or_null("UXShell")
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", _settings_help_game)

func build_daily_games() -> void:
	current_surface = "daily"
	_remove_active_game()
	var canvas := _figma_surface("daily", Color("#ead9b8"))
	var bonus := EconomyManager.collection_daily_bonus()
	var done_count := 0
	for game_id in MultiGameManager.GAME_IDS:
		if _daily_done(game_id):
			done_count += 1
	_figma_header(canvas, "DAILY", "Check-in • play • rewards", "%d/3" % done_count, FIGMA_GOLD)

	_figma_daily_card(canvas, "rescue_rush", 115, bonus)
	_figma_daily_card(canvas, "water_sort", 239, bonus)
	_figma_daily_card(canvas, "block_puzzle", 363, bonus)
	_figma_daily_progress(canvas)
	_figma_daily_tip(canvas, bonus)
	# Daily is a primary destination; campaign rankings remain a separate Compete flow.
	_figma_bottom_nav(canvas, "daily")

func _figma_daily_progress(canvas: Control) -> void:
	var done_count := 0
	for game_id in MultiGameManager.GAME_IDS:
		if _daily_done(game_id):
			done_count += 1

	_figma_card(canvas, "DailyProgress", Rect2(17,487,354,106), Color("#fffef8"), Color(FIGMA_GOLD,0.42), 18)
	_figma_text(canvas, "TODAY", Rect2(33,500,80,20), 15, FIGMA_INK)
	var count := _figma_text(canvas, "%d / 3 COMPLETE" % done_count, Rect2(210,500,141,20), 13, FIGMA_MUTED, true)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var progress := ProgressBar.new()
	progress.name = "DailyProgressBar"
	progress.show_percentage = false
	progress.min_value = 0
	progress.max_value = 3
	progress.value = done_count
	progress.add_theme_stylebox_override("background", FigmaReferenceCanvas.solid_box(Color("#d8cdb7"), 6))
	progress.add_theme_stylebox_override("fill", FigmaReferenceCanvas.flat_gloss(FIGMA_GOLD, 6, Color("#fff4b3"), 1, 0.22))
	FigmaReferenceCanvas.set_rect(progress, 33, 530, 318, 9)
	canvas.add_child(progress)

	var status_specs := [
		["rescue_rush", "RESCUE", 33.0],
		["water_sort", "WATER", 139.0],
		["block_puzzle", "BLOCK", 245.0],
	]
	for spec in status_specs:
		var game_id := String(spec[0])
		var accent := Unjam3DTheme.game_accent(game_id)
		var done := _daily_done(game_id)
		var fill := accent.darkened(0.68) if _dark() else accent.lightened(0.82)
		var border := accent.lightened(0.14 if _dark() else 0.02)
		_figma_solid_card(canvas, "DailyProgress/%s" % game_id, Rect2(float(spec[2]),550,96,32), fill, border, 12, false)
		var label := _figma_text(
			canvas,
			"%s %s" % [String(spec[1]), "✓" if done else "GO"],
			Rect2(float(spec[2])+4,555,88,20),
			12,
			accent.lightened(0.25) if _dark() else accent.darkened(0.24),
			true
		)
		label.name = "DailyProgressLabel_%s" % game_id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		# Keep READY/complete status inside its 90px authored lane. Font minimum
		# metrics must not push neighboring game labels into each other.
		label.custom_minimum_size = Vector2.ZERO
		_fit_single_line_control_text(label, 84.0, 12, 10)
		label.position = Vector2(float(spec[2])+3,554)
		label.size = Vector2(90,22)

func _figma_daily_tip(canvas: Control, collection_bonus: int) -> void:
	var login := MetaProgressionManager.daily_login_info()
	var claimed := bool(login.get("claimed",false))
	var reward := maxi(0,int(login.get("reward",0)))
	var tip_fill := Color("#282a2e") if _dark() else Color("#fffaf2")
	var tip_border := Color(FIGMA_ORANGE,0.34)
	_figma_card(canvas, "DailyCheckIn", Rect2(17,598,354,80), tip_fill, tip_border, 16)
	var title := _figma_text(canvas,"DAILY CHECK-IN • DAY %d/7" % int(login.get("day",1)),Rect2(33,609,205,20),15,FIGMA_ORANGE)
	title.name = "DailyTipTitle"
	var bonus_text := " • +%d COLLECTION" % collection_bonus if collection_bonus > 0 else ""
	var detail := _figma_text(canvas,"+%d COINS%s" % [reward,bonus_text],Rect2(33,636,205,20),12,FIGMA_MUTED)
	detail.name = "DailyTipDetail"
	var action_text := "GOALS" if claimed else "CLAIM"
	var action_cb := Callable(self,"build_goals") if claimed else Callable(self,"_claim_daily_login_from_daily")
	var action_fill := Color("#7a57e0") if claimed else FIGMA_ORANGE
	var action := _figma_button(canvas,"DailyCheckInAction",action_text,Rect2(244,617,107,44),action_fill,action_cb,Color.WHITE,14,12)
	action.tooltip_text = "Daily check-in, missions and Season Journey"

func _claim_daily_login_from_daily() -> void:
	if MetaProgressionManager.claim_daily_login() > 0:
		FeedbackManager.effect()
	build_daily_games()

func build_compete_leaderboard(refresh_remote: bool = true) -> void:
	current_surface = "compete"
	_remove_active_game()
	if refresh_remote:
		var refresh_callback := Callable(self, "_on_competition_snapshot_for_rankings")
		if not CompetitionManager.snapshot_updated.is_connected(refresh_callback):
			CompetitionManager.snapshot_updated.connect(refresh_callback, CONNECT_ONE_SHOT)
		CompetitionManager.refresh_snapshot()
	var canvas := _figma_surface("compete", Color("#ead9b8"))
	var accent := Unjam3DTheme.game_accent(_ranking_game)
	_figma_header(canvas, "RANKINGS", "CAMPAIGN RANKINGS", "↻", accent, Callable(self,"build_home"), Callable(self,"_refresh_competition_rankings"))
	_figma_compete_game_tabs(canvas, 91.0, false)

	_figma_card(canvas,"CompetitionPlayerProgress",Rect2(17,145,354,60),Color("#282a2e") if _dark() else Color("#fffaf2"),Color(accent,0.38),16)
	var ranking_game_title := _figma_text(canvas,MultiGameManager.display_name(_ranking_game).to_upper(),Rect2(31,154,160,15),12,accent)
	_fit_single_line_control_text(ranking_game_title,156.0,12,10)
	var ranking_progress := _figma_text(canvas,"%d LEVELS • ★%d" % [CompetitionManager.game_all_time_levels(_ranking_game),CompetitionManager.game_all_time_stars(_ranking_game)],Rect2(31,178,190,14),10,FIGMA_INK)
	_fit_single_line_control_text(ranking_progress,186.0,10,9)
	var week := _figma_text(canvas,"WEEK +%d" % CompetitionManager.game_weekly_levels(_ranking_game),Rect2(242,164,105,22),12,FIGMA_MUTED,true)
	week.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_figma_progress_leaderboard_panel(canvas,"ALL-TIME",CompetitionManager.game_all_time_top(_ranking_game),215.0,CompetitionManager.game_all_time_rank(_ranking_game),CompetitionManager.game_all_time_levels(_ranking_game),CompetitionManager.game_all_time_stars(_ranking_game),accent)
	_figma_progress_leaderboard_panel(canvas,"THIS WEEK",CompetitionManager.game_weekly_top(_ranking_game),405.0,CompetitionManager.game_weekly_rank(_ranking_game),CompetitionManager.game_weekly_levels(_ranking_game),CompetitionManager.game_weekly_stars(_ranking_game),accent)

	var daily := _figma_button(canvas,"CompetitionDailyButton","DAILY",Rect2(31,598,94,44),FIGMA_ORANGE,Callable(self,"build_daily_games"),Color.WHITE,12,11)
	daily.tooltip_text = "Daily challenges, check-in and rewards"
	var friends_rank := _figma_button(canvas,"CompetitionFriendsButton","FRIENDS",Rect2(140,598,103,44),Color("#7a57e0"),Callable(self,"build_friends"),Color.WHITE,12,11)
	friends_rank.tooltip_text = "Compare campaign progress with friends"
	var refresh := _figma_button(canvas,"CompetitionRefreshButton","REFRESH",Rect2(258,598,93,44),accent,Callable(self,"_refresh_competition_rankings"),Color.WHITE,12,10)
	refresh.tooltip_text = "Refresh campaign rankings"

	var reward := CompetitionManager.previous_week_reward(_ranking_game)
	if bool(reward.get("eligible", false)) and not bool(reward.get("claimed", false)):
		var claim := _figma_button(canvas,"CompetitionClaimWeekly","CLAIM LAST WEEK",Rect2(112,659,166,44),FIGMA_GREEN,Callable(self,"_claim_weekly_competition_reward"),Color.WHITE,14,12)
		claim.tooltip_text = "Claim last week's %s placement reward" % MultiGameManager.display_name(_ranking_game)
	else:
		var note := _figma_text(canvas,"Weekly rewards settle after each reset.",Rect2(44,663,302,40),12,FIGMA_MUTED,true)
		_fit_wrapped_text(note,292.0,12,10)
	# Rankings are intentionally separate from the Daily destination.
	_figma_bottom_nav(canvas,"")

func _figma_compete_game_tabs(canvas: Control, y: float, compact: bool = false) -> void:
	var ids: Array[String] = ["rescue_rush","water_sort","block_puzzle"]
	var labels: Array[String] = ["RESCUE","WATER","BLOCK"]
	var width := 108.0 if not compact else 106.0
	var gap := 8.0 if not compact else 10.0
	var start_x := 19.0
	for i in range(ids.size()):
		var selected := _ranking_game == ids[i]
		var accent := Unjam3DTheme.game_accent(ids[i])
		var fill := accent if selected else (Color("#36383d") if _dark() else Color("#d8d2c8"))
		var text_color := Color.WHITE if selected else FIGMA_INK
		var button := _figma_button(canvas,"RankingGame_%s" % ids[i],labels[i],Rect2(start_x+float(i)*(width+gap),y,width,44),fill,Callable(),text_color,10,10)
		if not selected:
			button.pressed.connect(_set_ranking_game.bind(ids[i]))
		else:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_ranking_game(game_id: String) -> void:
	if game_id not in MultiGameManager.GAME_IDS:
		return
	_ranking_game = game_id
	if current_surface == "friends":
		CompetitionManager.refresh_social(_ranking_game)
		build_friends(false)
	else:
		build_compete_leaderboard(false)

func _refresh_competition_rankings() -> void:
	var refresh_callback := Callable(self, "_on_competition_snapshot_for_rankings")
	if not CompetitionManager.snapshot_updated.is_connected(refresh_callback):
		CompetitionManager.snapshot_updated.connect(refresh_callback, CONNECT_ONE_SHOT)
	CompetitionManager.refresh_snapshot()

func _on_competition_snapshot_for_rankings(_snapshot: Dictionary) -> void:
	if current_surface == "compete":
		build_compete_leaderboard(false)

func _claim_weekly_competition_reward() -> void:
	var reward_callback := Callable(self, "_on_weekly_competition_reward")
	if not CompetitionManager.weekly_reward_claimed.is_connected(reward_callback):
		CompetitionManager.weekly_reward_claimed.connect(reward_callback, CONNECT_ONE_SHOT)
	CompetitionManager.claim_weekly_reward(_ranking_game)

func _on_weekly_competition_reward(_coins: int, _crowns: int) -> void:
	FeedbackManager.effect()
	build_compete_leaderboard(false)

func _figma_progress_leaderboard_panel(canvas: Control, title_text: String, entries: Array, y: float, own_rank: int, own_levels: int, own_stars: int, accent: Color) -> void:
	_figma_card(canvas,"Leaderboard/%s" % title_text,Rect2(17,y,354,180),Color("#fffaf2"),Color(accent,0.36),18)
	_figma_text(canvas,title_text,Rect2(33,y+12,120,20),15,accent)
	var own_text := "YOU —" if own_rank <= 0 else "YOU #%d • L%d" % [own_rank,own_levels]
	var own := _figma_text(canvas,own_text,Rect2(185,y+12,166,20),13,FIGMA_INK,true)
	own.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var shown := mini(4,entries.size())
	if shown <= 0:
		var empty := _figma_text(canvas,"Finish campaign levels to enter this ranking.",Rect2(38,y+72,310,42),12,FIGMA_MUTED,true)
		_fit_wrapped_text(empty,300.0,12,10)
		return
	for i in range(shown):
		var row = entries[i]
		if not row is Dictionary:
			continue
		var row_y := y+42.0+float(i)*33.0
		var place := i+1
		_figma_text(canvas,"★" if place == 1 else str(place),Rect2(34,row_y,28,24),13,accent,true)
		_figma_text(canvas,String(row.get("name","PLAYER")).left(15),Rect2(70,row_y,135,24),13,FIGMA_INK)
		var levels := maxi(0,int(row.get("levels_completed",0)))
		var stars := maxi(0,int(row.get("stars",0)))
		var progress := _figma_text(canvas,"L%d • ★%d" % [levels,stars],Rect2(210,row_y,130,24),12,FIGMA_MUTED,true)
		progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _figma_today_label() -> String:
	var d := Time.get_date_dict_from_system()
	var months := ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
	var month := int(d.get("month",1))
	return "%s %d" % [months[clampi(month - 1,0,11)], int(d.get("day",1))]

func _daily_ui_state(game_id: String, accent: Color) -> Dictionary:
	# Each Daily card is independent. Completing, abandoning or failing one game
	# must never disable either of the other two.
	if _daily_done(game_id):
		return {"text":"COMPLETED", "fill":Color("#4a4c50") if _dark() else Color("#d8d4cc"), "disabled":true, "done":true}
	return {"text":"PLAY", "fill":accent, "disabled":false, "done":false}

func _figma_daily_card(canvas: Control, game_id: String, y: float, collection_bonus: int) -> void:
	var accent := Unjam3DTheme.game_accent(game_id)
	var card_fill := Color("#27282b") if _dark() else Color("#f5f2ec")
	var card_border := Color(accent, 0.32 if _dark() else 0.28)
	_figma_solid_card(canvas, "DailyCard/%s" % game_id, Rect2(17,y,354,106), card_fill, card_border, 18)
	var accent_rail := PanelContainer.new()
	accent_rail.name = "DailyAccent/%s" % game_id
	accent_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_rail.add_theme_stylebox_override("panel", FigmaReferenceCanvas.flat_gloss(accent, 3, Color.TRANSPARENT, 0, 0.18))
	FigmaReferenceCanvas.set_rect(accent_rail, 20, y + 14, 5, 78)
	canvas.add_child(accent_rail)
	var daily_title := _figma_text(canvas, MultiGameManager.display_name(game_id).to_upper(), Rect2(33,y+16,178,25), 19, FIGMA_DARK_INK if _dark() else FIGMA_INK)
	daily_title.name = "DailyTitle_%s" % game_id
	var title_fill := accent.lightened(0.22) if _dark() else accent.darkened(0.30)
	var title_outline := Color("#151619") if _dark() else Color("#ffffff")
	FigmaReferenceCanvas.style_display_title(daily_title, title_fill, title_outline, 1)
	var detail := "CLEAR THE ROUTE" if game_id == "rescue_rush" else ("SORT THE COLOURS" if game_id == "water_sort" else "CLEAR THE BOARD")
	_figma_text(canvas, detail, Rect2(33,y+47,182,18), 13, FIGMA_MUTED)
	var reward := "+%d COINS" % (100 + collection_bonus) if game_id == "rescue_rush" else "+%d–%d COINS" % [125 + collection_bonus,175 + collection_bonus]
	_figma_text(canvas, reward, Rect2(33,y+70,150,19), 14, FIGMA_GOLD if _dark() else Color("#8a642e"))
	var daily_state := _daily_ui_state(game_id, accent)
	var fill: Color = daily_state.get("fill", accent)
	var button_text := String(daily_state.get("text", "PLAY"))
	var button := _figma_button(
		canvas,
		"DailyPlay_%s" % game_id,
		button_text,
		Rect2(236,y+42,116,48),
		fill,
		Callable(),
		FIGMA_OFF_WHITE,
		15,
		15
	)
	button.disabled = bool(daily_state.get("disabled", false))
	if not button.disabled:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.pressed.connect(start_game_daily.bind(game_id))

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
		"Progress & rewards",
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
		total_completed += MultiGameManager.levels_completed(game_id)
		total_stars += MultiGameManager.total_stars(game_id)
		total_perfect += MultiGameManager.perfect_clears(game_id)
		total_badges += MultiGameManager.world_badge_count(game_id)

	_figma_card(canvas,"Journey",Rect2(17,89,354,96),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"PROGRESS",Rect2(33,106,210,21),17,FIGMA_GOLD)
	var metrics := [
		[total_completed,"LEVELS",35.0],
		[total_stars,"STARS",119.0],
		[total_perfect,"PERFECT",203.0],
		[total_badges,"BADGES",287.0]
	]
	for metric in metrics:
		var metric_key := String(metric[1])
		# Keep value and caption in distinct compact bands. Font ascent/descent
		# can otherwise make their intrinsic rectangles overlap on narrow phones.
		var metric_value := _figma_text(canvas,_compact_stat(int(metric[0])),Rect2(float(metric[2]),135,62,22),17,FIGMA_INK)
		metric_value.name = "CollectionMetricValue_%s" % metric_key
		_fit_single_line_control_text(metric_value, 60.0, 17, 12)
		var metric_label := _figma_text(canvas,metric_key,Rect2(float(metric[2])-3,162,70,18),12,FIGMA_MUTED)
		metric_label.name = "CollectionMetricLabel_%s" % metric_key
		_fit_single_line_control_text(metric_label, 68.0, 12, 10)

	_figma_text(canvas,"GAMES",Rect2(17,202,190,21),16,FIGMA_INK)
	_figma_collection_progress(canvas,"rescue_rush",17)
	_figma_collection_progress(canvas,"water_sort",135)
	_figma_collection_progress(canvas,"block_puzzle",253)

	_figma_card(canvas,"Achievements",Rect2(17,339,354,76),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"ACHIEVEMENTS",Rect2(33,353,220,21),16,FIGMA_GOLD)
	var achievement_parts: Array[String] = []
	for game_id in MultiGameManager.GAME_IDS:
		var unlocked := MultiGameManager.unlocked_achievements(game_id).size()
		var total := MultiGameManager.achievement_definitions(game_id).size()
		achievement_parts.append("%s %d/%d" % [_figma_short_game(game_id),unlocked,total])
	var achievement_summary := _figma_text(canvas," • ".join(achievement_parts),Rect2(33,394,310,18),13,FIGMA_MUTED)
	achievement_summary.name = "CollectionAchievementSummary"
	achievement_summary.clip_text = true
	achievement_summary.custom_minimum_size = Vector2.ZERO
	_fit_single_line_control_text(achievement_summary,306.0,13,10)
	achievement_summary.position = Vector2(33,394)
	achievement_summary.size = Vector2(310,18)
	var achievements_view := _figma_button(canvas,"CollectionAchievementsView","VIEW",Rect2(286,347,65,44),Color("#7a57e0"),Callable(self,"build_profile"),Color.WHITE,11,10)
	achievements_view.tooltip_text = "Open detailed Profile & Achievements"

	var rescued: Array = SaveManager.data.get("rescued",[])
	_figma_card(canvas,"Garden",Rect2(17,429,354,96),Color("#fffef8"),Color(0.55,0.86,0.71,0.32),18)
	_figma_text(canvas,"RESCUE GARDEN",Rect2(33,443,230,22),17,FIGMA_GOLD)
	_figma_text(canvas,"%d friends • %d/%d upgrades" % [rescued.size(),EconomyManager.collection_total_levels(),EconomyManager.collection_max_total_levels()],Rect2(33,474,300,22),14,FIGMA_MUTED)
	_figma_text(canvas,"+%d DAILY • +%d GIFT • ♛ %d" % [EconomyManager.collection_daily_bonus(),EconomyManager.garden_gift_amount(),int(SaveManager.data.get("crown_tokens",0))],Rect2(33,499,310,22),13,FIGMA_MUTED)

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
		gift_text = "GIFT CLAIMED" if EconomyManager.garden_gift_claimed_today() else "UNLOCK WITH UPGRADE"
	var gift_fill := FIGMA_GREEN if can_claim else Color(0.54,0.64,0.72)
	var gift := _figma_button(canvas,"CollectionGardenGift",gift_text,Rect2(33,548,200,44),gift_fill,Callable(),FIGMA_OFF_WHITE,16,13)
	gift.disabled = not can_claim
	if can_claim:
		gift.pressed.connect(_claim_collection_gift)

	var upgrades_button := _figma_button(
		canvas,
		"CollectionOpenUpgrades",
		"UPGRADES",
		Rect2(243,548,114,44),
		Color("#7a57e0"),
		Callable(self,"build_collection_upgrades"),
		Color.WHITE,
		14,
		13
	)
	upgrades_button.tooltip_text = "Buy permanent Rescue Garden upgrades with coins"

	# Fill the dead zone below the gift/upgrades row with a decorative tip card
	_figma_collection_tip(canvas)
	_figma_bottom_nav(canvas,"collection")

func _figma_collection_tip(canvas: Control) -> void:
	# Explain the Collection's permanent reward value instead of repeating the
	# wallet balance already exposed in the header.
	var daily_bonus := EconomyManager.collection_daily_bonus()
	var gift_amount := EconomyManager.garden_gift_amount()
	var tip_fill := Color("#27282b") if _dark() else Color("#f5f2ec")
	var tip_border := Color(FIGMA_GREEN, 0.22 if _dark() else 0.18)
	_figma_card(canvas, "CollectionTip", Rect2(17, 606, 354, 82), tip_fill, tip_border, 16)
	var icon := _figma_text(canvas, "◆", Rect2(33, 622, 24, 24), 17, FIGMA_GREEN, true)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var title := _figma_text(canvas, EconomyManager.competition_prestige_title(), Rect2(63, 615, 288, 22), 15, FIGMA_INK)
	title.name = "CollectionTipTitle"
	var current_value := _figma_text(canvas, "+%d DAILY  •  +%d GIFT" % [daily_bonus, gift_amount], Rect2(63, 639, 288, 20), 13, FIGMA_GOLD)
	current_value.name = "CollectionTipValue"
	var detail := _figma_text(canvas, "PERMANENT BOOSTS • 5 LEVELS EACH", Rect2(63, 663, 288, 21), 12, FIGMA_MUTED)
	detail.name = "CollectionTipDetail"
	detail.clip_text = true
	# Label minimum metrics are computed before font fitting. Reset the minimum
	# and restore the authored card box afterwards so compact viewports cannot
	# expand this line beyond the Collection card.
	detail.custom_minimum_size = Vector2.ZERO
	_fit_single_line_control_text(detail, 284.0, 12, 11)
	detail.position = Vector2(63,664)
	detail.size = Vector2(288,20)

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
		"Progress & rewards",
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

	_figma_text(canvas,"GARDEN UPGRADES",Rect2(23,99,342,28),22,Color("#1c8552"))
	_figma_text(canvas,"Permanent progression • %d / %d levels" % [EconomyManager.collection_total_levels(),EconomyManager.collection_max_total_levels()],Rect2(23,131,342,18),14,Color("#597a8f"))
	_figma_solid_card(canvas,"CollectionScroll/Boost",Rect2(23,163,342,60),Color("#f0fff5"),Color(0.30,0.78,0.48,0.42),16,false)
	var boost_text := _figma_text(
		canvas,
		"DAILY +%d  •  GIFT +%d  •  CAMPAIGN +%d%%" % [EconomyManager.collection_daily_bonus(),EconomyManager.garden_gift_amount(),EconomyManager.collection_campaign_reward_bonus_pct()],
		Rect2(33,184,322,18),
		13,
		Color("#1f8a52"),
		true
	)
	boost_text.name = "CollectionUpgradeBoostSummary"
	boost_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boost_text.custom_minimum_size = Vector2.ZERO
	_fit_single_line_control_text(boost_text, 318.0, 13, 9)

	var upgrades := [
		["tree","CANOPY TREE","SHADE",100],
		["bench","GARDEN BENCH","REST",150],
		["fountain","CRYSTAL FOUNTAIN","SPARKLE",250],
		["lanterns","LANTERN PATH","GLOW",350],
		["cottage","RESCUE COTTAGE","HOME",500],
		["rainbow_bridge","RAINBOW BRIDGE","WONDER",750],
	]
	for i in range(upgrades.size()):
		var spec: Array = upgrades[i]
		var id := String(spec[0])
		var display_name := String(spec[1])
		var base_cost := int(spec[3])
		var level := EconomyManager.collection_item_level(id)
		var maxed := level >= EconomyManager.COLLECTION_MAX_LEVEL
		var cost := EconomyManager.collection_level_cost(id,base_cost)
		var y := 235.0 + float(i)*78.0
		var card_fill := Color("#f0fff5") if level > 0 else Color("#fcfaff")
		var card_border := Color(0.32,0.78,0.49,0.46) if level > 0 else Color(0.72,0.58,0.90,0.46)
		var title_color := Color("#1f854f") if level > 0 else Color("#4d3373")
		_figma_solid_card(canvas, "CollectionScroll/Upgrade/%d" % i, Rect2(23,y,342,70), card_fill, card_border, 16, false)
		var upgrade_title := _figma_text(canvas,"%s  •  L%d/%d" % [display_name,level,EconomyManager.COLLECTION_MAX_LEVEL],Rect2(37,y+8,154,20),14,title_color)
		upgrade_title.name = "CollectionUpgradeTitle/%s" % id
		upgrade_title.custom_minimum_size = Vector2.ZERO
		_fit_single_line_control_text(upgrade_title, 150.0, 14, 9)
		var effect_text := _figma_text(canvas,EconomyManager.collection_effect_text(id,level),Rect2(37,y+34,154,24),11,Color("#6b8091"))
		effect_text.name = "CollectionUpgradeEffect/%s" % id
		effect_text.custom_minimum_size = Vector2.ZERO
		_fit_single_line_control_text(effect_text, 150.0, 11, 8)
		var preview := GardenUpgradePreviewScene.new() as GardenUpgradePreview
		preview.name = "CollectionUpgradePreview/%s" % id
		preview.configure(id,level > 0)
		FigmaReferenceCanvas.set_rect(preview,197,y+9,38,50)
		canvas.add_child(preview)
		var state_text := "MAX" if maxed else "%d COINS" % cost
		var pill_fill := Color("#e0f2e5") if maxed else Color("#7a57e0")
		var state_text_color := Color("#4d7a59") if maxed else Color.WHITE
		var state := _figma_button(canvas, "CollectionUpgrade/%s" % id, state_text, Rect2(251,y+13,96,44), pill_fill, Callable(), state_text_color, 12, 13)
		state.disabled = maxed
		if maxed:
			var owned_style := FigmaReferenceCanvas.solid_box(Color("#e0f2e5"),12,Color.TRANSPARENT,0)
			state.add_theme_stylebox_override("disabled",owned_style)
			state.add_theme_color_override("font_disabled_color",Color("#4d7a59"))
			state.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			state.pressed.connect(_buy_collection_upgrade.bind(id,base_cost))

	var return_hint := _figma_text(canvas,"SWIPE DOWN • COLLECTION SUMMARY",Rect2(37,710,314,18),12,Color("#6e8596"),true)
	return_hint.name = "CollectionUpgradeReturnHint"
	return_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_hint.clip_text = true
	return_hint.custom_minimum_size = Vector2.ZERO
	_fit_single_line_control_text(return_hint,310.0,12,10)
	return_hint.position = Vector2(37,710)
	return_hint.size = Vector2(314,18)
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

func _buy_collection_upgrade(id: String, base_cost: int) -> bool:
	if EconomyManager.collection_item_level(id) >= EconomyManager.COLLECTION_MAX_LEVEL:
		return true
	var cost := EconomyManager.collection_level_cost(id,base_cost)
	if EconomyManager.upgrade_collection_item(id,base_cost):
		FeedbackManager.effect()
		PremiumVisuals.burst(Vector2(get_viewport_rect().size.x*0.5,get_viewport_rect().size.y*0.45),FIGMA_GOLD,18)
		build_collection_upgrades()
		return true
	var prompt := get_node_or_null("InsufficientCoinsPrompt")
	if prompt != null and prompt.has_method("show_for"):
		prompt.call("show_for", "%s UPGRADE" % display_name_for_upgrade(id), cost, Callable(self,"_retry_collection_upgrade").bind(id,base_cost))
	else:
		FeedbackManager.blocked()
	return false

func _retry_collection_upgrade(id: String, base_cost: int) -> bool:
	if EconomyManager.upgrade_collection_item(id,base_cost):
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
		"%s %d / %d" % [MultiGameManager.progression_scope_label(game_id),selected_multi_world,world_count],
		"◈ +",
		accent,
		Callable(self,"_open_games_surface"),
		Callable(self,"_figma_open_shop")
	)
	_style_figma_level_header(canvas,accent)
	_figma_level_tabs(canvas,game_id)

	var bounds := _multi_page_bounds(game_id,selected_multi_world,selected_multi_page)
	var world_name := MultiGameManager.world_name(game_id,selected_multi_world).to_upper()
	_figma_card(canvas,"JourneyHero",Rect2(17,149,354,74),Color("#fffaf0"),Color(accent,0.30),15)
	_figma_text(canvas,world_name,Rect2(35,144,250,25),20,accent)
	_figma_text(canvas,"LEVELS %d–%d" % [bounds.x,bounds.y],Rect2(35,173,210,19),14,FIGMA_MUTED)

	var page_y := 247.0 if game_id == "block_puzzle" else 222.0
	var grid_y := 308.0 if game_id == "block_puzzle" else 269.0
	if game_id == "block_puzzle":
		_add_figma_block_modes(canvas)

	var prev_fill := Color("#33281c") if _dark() else Color("#fffaf0")
	var prev_text := FIGMA_DARK_INK if _dark() else FIGMA_MUTED
	var prev := _figma_button(canvas,"LevelPrev","◀ PREV",Rect2(17,page_y - 3.0,100,44),prev_fill,Callable(),prev_text,14,14)
	prev.disabled = selected_multi_world <= 1 and selected_multi_page <= 1
	_style_figma_page_button(prev,prev_fill,accent,prev.disabled,true)
	if not prev.disabled:
		prev.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		prev.pressed.connect(_change_multi_page.bind(-1))
	var current := _figma_button(canvas,"LevelCurrent","CURRENT",Rect2(125,page_y - 3.0,118,44),accent,Callable(self,"_jump_multi_current"),FIGMA_OFF_WHITE,14,14)
	current.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_style_figma_page_button(current,accent,accent,false)
	var next_disabled := selected_multi_world >= world_count and selected_multi_page >= _multi_page_count(game_id,selected_multi_world)
	var next := _figma_button(canvas,"LevelNext","NEXT ▶",Rect2(251,page_y - 3.0,120,44),Color("#fcfeff"),Callable(),FIGMA_MUTED,14,14)
	next.disabled = next_disabled
	_style_figma_page_button(next,Color("#fcfeff"),accent,next_disabled,true)
	if not next.disabled:
		next.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
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
		var fill := Color("#33281c") if _dark() else Color("#fffaf0")
		var border := Color(accent,0.62 if _dark() else 0.40)
		var text_color := FIGMA_DARK_INK if _dark() else FIGMA_INK
		if not unlocked:
			fill = Color("#2a2118") if _dark() else Color("#e5ddce")
			border = Color("#80613b",0.58) if _dark() else Color("#c7bda9",0.55)
			text_color = Color("#9e9485") if _dark() else Color("#958b7c")
		elif is_current:
			fill = accent
			border = Color(accent.lightened(0.24),0.75)
			text_color = FIGMA_OFF_WHITE
		elif milestone:
			border = Color(FIGMA_GOLD,0.85)
		# The tile button owns background + hit target only. Number and status use
		# separate authored bands so LOCK/stars never paint over the level number.
		var card := _figma_button(canvas,"Level/%d" % level_number,"",Rect2(x,y,82,70),fill,Callable(),text_color,16,16)
		card.tooltip_text = "Level %d" % level_number
		card.disabled = not unlocked
		_style_figma_level_card(card,accent,border,unlocked,is_current)
		if unlocked:
			card.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			if game_id == "rescue_rush":
				card.pressed.connect(start_level.bind(level_number))
			else:
				card.pressed.connect(start_multi_level.bind(game_id,level_number,false))
		var number_color := FIGMA_OFF_WHITE if is_current else text_color
		var number_label := _figma_text(canvas,str(level_number),Rect2(x+8,y+7,66,23),16,number_color,true)
		number_label.name = "LevelNumber_%d" % level_number
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fit_single_line_control_text(number_label,62.0,16,12)
		var star_text := "LOCK" if not unlocked else ("★".repeat(stars) if stars > 0 else "···")
		var star_color := (Color("#9e9485") if _dark() else Color("#958b7c")) if not unlocked else (FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)
		var status_label := _figma_text(canvas,star_text,Rect2(x+8,y+43,66,18),11,star_color,true)
		status_label.name = "LevelStatus_%d" % level_number
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fit_single_line_control_text(status_label,62.0,11,9)
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
		var fill := active_accent if active else (Color("#33281c") if _dark() else Color("#fffaf0"))
		var text_color := FIGMA_OFF_WHITE if active else (FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)
		var button := _figma_button(canvas,"LevelGameTab/%s" % game_id,String(spec[1]),Rect2(float(spec[2]),81,108,44),fill,Callable(),text_color,14,13)
		_style_figma_level_tab(button,active_accent,active)
		if active:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			button.pressed.connect(_figma_switch_level_game.bind(game_id))

func _style_figma_level_header(canvas: Control, accent: Color) -> void:
	var back := canvas.get_node_or_null("FigmaBack") as Button
	if back != null:
		var back_top := Color("#3a2d20") if _dark() else Color("#fffaf0")
		var back_mid := Color("#33281c") if _dark() else Color("#fffaf0")
		var back_bottom := Color("#2a2118") if _dark() else Color("#eadfc8")
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
		var tab_top := Color("#3a2d20") if _dark() else Color("#fffaf0")
		var tab_mid := Color("#33281c") if _dark() else Color("#fffaf0")
		var tab_bottom := Color("#2a2118") if _dark() else Color("#eadfc8")
		var normal := FigmaReferenceCanvas.rounded_gradient3(tab_top,tab_mid,tab_bottom,14,Color(accent,0.70 if _dark() else 0.55),1.2,0.50)
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(tab_top.lightened(0.08),tab_mid.lightened(0.06),tab_bottom.lightened(0.04),14,Color(accent,0.82),1.2,0.50))
		button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(tab_mid,tab_bottom,tab_bottom.darkened(0.08),14,Color(accent,0.70),1.2,0.50))
		button.add_theme_color_override("font_color", FIGMA_DARK_MUTED if _dark() else FIGMA_MUTED)

func _style_figma_page_button(button: Button, fill: Color, accent: Color, disabled: bool, light_surface: bool = false) -> void:
	if light_surface or disabled:
		var page_top := Color("#3a2d20") if _dark() else Color("#fffaf0")
		var page_mid := Color("#33281c") if _dark() else Color("#fffaf0")
		var page_bottom := Color("#2a2118") if _dark() else Color("#eadfc8")
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
		var button := _figma_button(canvas,"BlockMode/%s" % mode,String(spec[1]),Rect2(float(spec[2]),197,82,44),fill,Callable(),FIGMA_OFF_WHITE,13,13)
		_style_figma_page_button(button,fill,fill,false)
		if mode == "campaign":
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			button.pressed.connect(start_block_mode.bind(mode))

func _figma_switch_level_game(game_id: String) -> void:
	selected_game_id = game_id
	selected_multi_world = MultiGameManager.highest_unlocked_game_world(game_id)
	selected_multi_page = _multi_page_for_level(game_id,_highest_level_for_game(game_id))
	build_multi_level_select()



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


func _highest_level_for_game(game_id: String) -> int:
	if game_id == "rescue_rush":
		return int(SaveManager.data.get("highest_level", 1))
	return MultiGameManager.highest_level(game_id)


func show_playmate_sidekick(game_id: String = "") -> void:
	current_surface = "sidekick"
	_remove_active_game()
	var requested_game := _sidekick_game
	if game_id in MultiGameManager.GAME_IDS:
		requested_game = game_id
	elif selected_game_id in MultiGameManager.GAME_IDS:
		requested_game = selected_game_id
	if requested_game != _sidekick_game:
		_sidekick_tip_index = -1
	_sidekick_game = requested_game
	var accent := Unjam3DTheme.game_accent(_sidekick_game)
	var canvas := _figma_surface("games", Color("#d9e8f4"))
	_figma_header(
		canvas,
		"PLAYMATE SIDEKICK",
		"BETA • OFFLINE COACH",
		LocalizationManager.locale_badge(),
		accent,
		Callable(self, "build_home")
	)

	_figma_card(canvas, "SidekickPlaymateCard", Rect2(17, 102, 354, 138), Color("#d8d4cc"), Color(accent, 0.56), 20)
	_figma_text(canvas, "YOUR PLAYMATE", Rect2(35, 118, 160, 20), 14, FIGMA_GOLD)
	var friend_name := _sidekick_playmate_name()
	var friend := _figma_text(canvas, friend_name, Rect2(35, 145, 200, 34), 25, _figma_theme_text(FIGMA_INK))
	friend.name = "SidekickPlaymateName"
	friend.clip_text = true
	_fit_single_line_control_text(friend, 196.0, 25, 14)
	var game_label := _figma_text(canvas, MultiGameManager.display_name(_sidekick_game).to_upper(), Rect2(35, 188, 220, 24), 15, _figma_theme_text(FIGMA_MUTED))
	game_label.name = "SidekickGameName"
	game_label.clip_text = true
	_fit_single_line_control_text(game_label, 216.0, 15, 11)
	var level := MultiGameManager.highest_level(_sidekick_game)
	var level_badge := _figma_text(canvas, "LEVEL %d" % level, Rect2(263, 151, 86, 30), 13, _figma_theme_text(FIGMA_INK), true)
	level_badge.name = "SidekickLevel"
	level_badge.clip_text = true
	_fit_single_line_control_text(level_badge, 82.0, 13, 10)

	_figma_card(canvas, "SidekickTipCard", Rect2(17, 257, 354, 234), Color("#d8d4cc"), Color(accent, 0.42), 20)
	_figma_text(canvas, "LEVEL %d • %s" % [MultiGameManager.highest_level(_sidekick_game), LocalizationManager.localize("TIP")], Rect2(35, 278, 290, 20), 14, FIGMA_GOLD)
	var tip := _figma_text(canvas, _sidekick_tip(), Rect2(35, 312, 300, 130), 15, _figma_theme_text(FIGMA_INK))
	tip.name = "SidekickTip"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tip.clip_text = true
	tip.custom_minimum_size = Vector2.ZERO
	tip.position = Vector2(35, 312)
	tip.size = Vector2(300, 130)
	_fit_wrapped_text(tip, 296.0, 15, 12)
	var identity := _figma_text(canvas, "BETA • OFFLINE COACH", Rect2(35, 449, 318, 24), 12, _figma_theme_text(FIGMA_MUTED), true)
	identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity.clip_text = true
	_fit_single_line_control_text(identity, 314.0, 12, 10)

	var next_tip := _figma_button(canvas, "SidekickNextTip", "NEXT TIP", Rect2(17, 515, 170, 52), Color("#cbc4b8"), Callable(self, "_sidekick_next_tip"), FIGMA_NAVY, 16, 13)
	next_tip.tooltip_text = LocalizationManager.localize("NEXT TIP")
	var change_game := _figma_button(canvas, "SidekickChangeGame", "CHANGE GAME", Rect2(201, 515, 170, 52), Color("#cbc4b8"), Callable(self, "_sidekick_change_game"), FIGMA_NAVY, 16, 13)
	change_game.tooltip_text = LocalizationManager.localize("CHANGE GAME")
	var play := _figma_button(canvas, "SidekickPlayGame", "PLAY THIS GAME", Rect2(17, 588, 354, 58), accent.darkened(0.16), Callable(self, "_sidekick_play_game"), FIGMA_OFF_WHITE, 17, 15)
	play.tooltip_text = LocalizationManager.localize("PLAY THIS GAME")
	var locale_note := _figma_text(canvas, "Auto • %s" % LocalizationManager.locale_badge(), Rect2(17, 674, 354, 24), 12, _figma_theme_text(FIGMA_MUTED), true)
	locale_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_figma_bottom_nav(canvas, "home")

func _sidekick_playmate_name() -> String:
	var rescued = SaveManager.data.get("rescued", [])
	if rescued is Array and not (rescued as Array).is_empty():
		return String((rescued as Array)[0]).capitalize()
	return "UNJAM BUDDY"

func _sidekick_recommended_tip_index() -> int:
	# The first tip is chosen using the active campaign state, rather than
	# always displaying the first generic instruction for every player.
	var level := maxi(1, MultiGameManager.highest_level(_sidekick_game))
	match _sidekick_game:
		"rescue_rush":
			if level <= 12:
				return 1 # Learn the exit route before touching arrows.
			if level % 100 >= 75:
				return 2 # Conserve hints on difficult milestone boards.
			return 0 # Unlock paths by freeing blockers.
		"water_sort":
			if level <= 20:
				return 1 # Keep working space for initial lessons.
			if level >= 100:
				return 2 # Look for larger matching stacks.
			return 0
		"block_puzzle":
			if level <= 20:
				return 2 # Inspect the whole tray before placement.
			if level >= 100:
				return 0 # Protect board space on tougher levels.
			return 1
	return 0

func _sidekick_tip() -> String:
	var tips: Array = SIDEKICK_TIPS.get(_sidekick_game, SIDEKICK_TIPS["rescue_rush"])
	var tip_index := _sidekick_recommended_tip_index() if _sidekick_tip_index < 0 else _sidekick_tip_index
	return LocalizationManager.localize(String(tips[tip_index % tips.size()]))

func _sidekick_next_tip() -> void:
	var tips: Array = SIDEKICK_TIPS.get(_sidekick_game, SIDEKICK_TIPS["rescue_rush"])
	var previous := _sidekick_recommended_tip_index() if _sidekick_tip_index < 0 else _sidekick_tip_index
	_sidekick_tip_index = (previous + 1) % tips.size()
	FeedbackManager.tap()
	show_playmate_sidekick(_sidekick_game)

func _sidekick_change_game() -> void:
	var index := MultiGameManager.GAME_IDS.find(_sidekick_game)
	_sidekick_game = MultiGameManager.GAME_IDS[(index + 1) % MultiGameManager.GAME_IDS.size()]
	_sidekick_tip_index = -1
	FeedbackManager.tap()
	show_playmate_sidekick(_sidekick_game)

func _sidekick_play_game() -> void:
	FeedbackManager.tap()
	open_game_campaign(_sidekick_game)
