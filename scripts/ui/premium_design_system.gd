class_name PremiumDesignSystem
extends RefCounted

const GAME_ACCENTS := {
	"rescue_rush": Color("39d8c2"),
	"water_sort": Color("62b6ff"),
	"block_puzzle": Color("9a86ff")
}

const GOLD := Color("ffd166")
const DANGER := Color("ff6b7a")
const SUCCESS := Color("55d68b")

static func accent_for_game(game_id: String) -> Color:
	return GAME_ACCENTS.get(game_id, GAME_ACCENTS["rescue_rush"])

static func ink(dark: bool) -> Color:
	return Color("f4f7fb") if dark else Color("213044")

static func muted(dark: bool) -> Color:
	return Color("b6c3d4") if dark else Color("6f7f92")

static func canvas(dark: bool) -> Color:
	return Color("1b1c1e") if dark else Color("e6e2da")

static func surface(dark: bool) -> Color:
	return Color("24262a") if dark else Color("f1eee7")

static func surface_2(dark: bool) -> Color:
	return Color("2c2f34") if dark else Color("e3dfd6")

static func surface_3(dark: bool) -> Color:
	return Color("34383e") if dark else Color("d6d1c7")

static func border(dark: bool) -> Color:
	return Color("5b6068") if dark else Color("aaa397")

static func disabled(dark: bool) -> Color:
	return Color("303338") if dark else Color("cbc6bd")

static func game_canvas(game_id: String, dark: bool) -> Color:
	if not dark:
		match game_id:
			"water_sort": return Color("e7ecef")
			"block_puzzle": return Color("ebe8ee")
			_: return Color("e7ece9")
	match game_id:
		"water_sort": return Color("182127")
		"block_puzzle": return Color("1e1b24")
		_: return Color("17221e")

static func box(color: Color, radius: int = 24, edge: Color = Color.TRANSPARENT, edge_width: int = 0, shadow: int = 0, dark: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if edge_width > 0:
		style.border_width_left = edge_width
		style.border_width_right = edge_width
		style.border_width_top = edge_width
		style.border_width_bottom = edge_width
		style.border_color = edge
	if shadow > 0:
		style.shadow_color = Color(0, 0, 0, 0.34 if dark else 0.12)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0, maxf(1.0, shadow * 0.42))
	return style

static func _gloss_style(fill: Color, radius: int, dark: bool) -> StyleBoxTexture:
	var top_strength := 0.22 if dark else 0.16
	var bottom_strength := 0.16 if dark else 0.11
	var top := fill.lightened(top_strength)
	var middle := fill.lightened(0.025)
	var bottom := fill.darkened(bottom_strength)
	return FigmaReferenceCanvas.rounded_gradient3(top, middle, bottom, radius, Color.TRANSPARENT, 0.0, 0.40)

static func _install_gloss(control: Control, style: StyleBoxTexture) -> void:
	var backdrop := control.get_node_or_null("PremiumGlossBackdrop") as FigmaButtonBackdrop
	if backdrop == null:
		backdrop = FigmaButtonBackdrop.new()
		backdrop.name = "PremiumGlossBackdrop"
		control.add_child(backdrop)
	backdrop.configure(style)

static func role_for_button(button: Button) -> String:
	var text := button.text.strip_edges().to_upper()
	if button.disabled:
		return "disabled"
	if "DELETE" in text or "REMOVE" in text or "RESET" in text:
		return "danger"
	if "PLAY" in text or "CONTINUE" in text or "CURRENT" in text or "GOT IT" in text:
		return "primary"
	if "HINT" in text or "DAILY" in text or "REWARD" in text:
		return "reward"
	if "OWNED" in text or text.ends_with(": ON"):
		return "success"
	if text.ends_with(": OFF"):
		return "toggle_off"
	if text in ["←", "‹", "BACK", "←  BACK", "◀ PREV", "NEXT ▶"]:
		return "utility"
	return "secondary"

static func apply_button(button: Button, dark: bool, accent: Color, role: String = "auto", radius: int = 22) -> void:
	if role == "auto":
		role = role_for_button(button)
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not button.has_meta("unjam_figma_exact_geometry"):
		button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, 78.0))
	var current_font := button.get_theme_font_size("font_size")
	button.add_theme_font_size_override("font_size", maxi(20, current_font))
	var normal := surface_2(dark)
	var edge := border(dark)
	var text_color := ink(dark)
	var shadow := 3
	match role:
		"primary":
			normal = accent
			edge = accent.lightened(0.16)
			text_color = Color("061019") if accent.get_luminance() > 0.55 else Color.WHITE
			shadow = 8
		"reward":
			normal = Color(GOLD, 0.96) if dark else Color("fff0bd")
			edge = GOLD
			text_color = Color("241a05")
			shadow = 6
		"success":
			normal = Color(SUCCESS, 0.19) if dark else Color("e4f8ed")
			edge = Color(SUCCESS, 0.78)
			text_color = SUCCESS.lightened(0.18) if dark else Color("1d7043")
		"danger":
			normal = Color(DANGER, 0.16) if dark else Color("fff0f2")
			edge = Color(DANGER, 0.72)
			text_color = DANGER.lightened(0.14) if dark else Color("a83243")
		"toggle_off":
			normal = surface_3(dark)
			edge = border(dark)
			text_color = muted(dark)
		"utility":
			normal = Color(surface_2(dark), 0.96)
			edge = Color(accent, 0.38)
		"disabled":
			normal = disabled(dark)
			edge = Color(border(dark), 0.55)
			text_color = muted(dark)
			shadow = 0
		_:
			normal = Color(surface_2(dark), 0.98)
			edge = border(dark)
	_install_gloss(button, _gloss_style(normal, radius, dark))
	# The parent keeps only edge/shadow/state overlays. The glossy fill is drawn by
	# a cached nine-slice child behind the button, preserving text sharpness.
	button.add_theme_stylebox_override("normal", box(Color(0, 0, 0, 0.001), radius, edge, 2, shadow, dark))
	button.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.075), radius, accent, 2, max(3, shadow), dark))
	button.add_theme_stylebox_override("pressed", box(Color(0, 0, 0, 0.105), radius, accent.lightened(0.14), 2, 1, dark))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, radius, accent, 3, 0, dark))
	button.add_theme_stylebox_override("disabled", box(Color(0.10, 0.13, 0.16, 0.18), radius, Color(border(dark), 0.5), 1, 0, dark))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", muted(dark))

static func apply_panel(panel: PanelContainer, dark: bool, accent: Color, emphasis: bool = false, radius: int = 28) -> void:
	var fill := Color(surface(dark), 0.97)
	var edge := Color(accent, 0.44) if emphasis else border(dark)
	_install_gloss(panel, _gloss_style(fill, radius, dark))
	panel.add_theme_stylebox_override("panel", box(Color(0, 0, 0, 0.001), radius, edge, 2 if emphasis else 1, 10 if emphasis else 4, dark))

static func apply_label(label: Label, dark: bool, kind: String = "body", accent: Color = Color.WHITE) -> void:
	match kind:
		"title":
			label.add_theme_color_override("font_color", ink(dark))
			label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.18 if dark else 0.05))
			label.add_theme_constant_override("shadow_offset_y", 2)
		"accent":
			label.add_theme_color_override("font_color", accent)
		"muted":
			label.add_theme_color_override("font_color", muted(dark))
		_:
			label.add_theme_color_override("font_color", ink(dark))

static func surface_title(text: String) -> String:
	return text.strip_edges().to_upper()
