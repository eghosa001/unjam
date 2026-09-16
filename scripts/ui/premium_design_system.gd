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
const MIN_TOUCH_HEIGHT := 78.0
const TITLE_MIN := 40
const GAME_TITLE_MIN := 30
const CTA_MIN := 24
const HUD_MIN := 20
const BODY_MIN := 17
const NAV_MIN := 15

static func accent_for_game(game_id: String) -> Color:
	return GAME_ACCENTS.get(game_id, GAME_ACCENTS["rescue_rush"])

static func ink(dark: bool) -> Color:
	return Color("f4f7fb") if dark else Color("213044")

static func muted(dark: bool) -> Color:
	return Color("b6c3d4") if dark else Color("6f7f92")

static func canvas(dark: bool) -> Color:
	return Color("0b1220") if dark else Color("eef2f5")

static func surface(dark: bool) -> Color:
	return Color("121a29") if dark else Color("f8fafc")

static func surface_2(dark: bool) -> Color:
	return Color("182538") if dark else Color("e9eef3")

static func surface_3(dark: bool) -> Color:
	return Color("22304a") if dark else Color("dfe6ed")

static func border(dark: bool) -> Color:
	return Color("334a67") if dark else Color("c7d1dc")

static func disabled(dark: bool) -> Color:
	return Color("202c3f") if dark else Color("e5eaf0")

static func game_canvas(game_id: String, dark: bool) -> Color:
	if not dark:
		match game_id:
			"water_sort": return Color("eaf6ff")
			"block_puzzle": return Color("f5efff")
			_: return Color("e8fbf2")
	match game_id:
		"water_sort": return Color("06101e")
		"block_puzzle": return Color("0c0a1b")
		_: return Color("061411")

static func material_color(material: String, dark: bool, accent: Color) -> Color:
	match material:
		"stone":
			return Color("26364a") if dark else Color("d9e3ec")
		"glass":
			return Color("163455") if dark else Color("dff4ff")
		"toy":
			return Color(accent, 0.94)
		"metal":
			return Color("68788d") if dark else Color("b9c4cf")
		_:
			return surface_2(dark)

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
		style.shadow_color = Color(0, 0, 0, 0.40 if dark else 0.18)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0, maxf(2.0, shadow * 0.52))
	return style

static func raised_box(color: Color, radius: int = 24, edge: Color = Color.TRANSPARENT, dark: bool = true, depth: int = 8) -> StyleBoxFlat:
	var rim := edge if edge != Color.TRANSPARENT else color.lightened(0.22)
	var style := box(color, radius, rim, 2, depth, dark)
	style.content_margin_top = 4.0
	style.content_margin_bottom = 6.0
	return style

static func recessed_box(color: Color, radius: int = 24, edge: Color = Color.TRANSPARENT, dark: bool = true) -> StyleBoxFlat:
	var body := color.darkened(0.18) if dark else color.darkened(0.05)
	var rim := edge if edge != Color.TRANSPARENT else color.lightened(0.10)
	var style := box(body, radius, rim, 3, 2, dark)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

static func gloss_button(color: Color, radius: int = 24, dark: bool = true, depth: int = 9) -> StyleBoxFlat:
	var style := raised_box(color, radius, color.lightened(0.24), dark, depth)
	style.border_width_top = 3
	style.border_color = color.lightened(0.26)
	return style

static func hud_box(accent: Color, dark: bool) -> StyleBoxFlat:
	var body := Color(surface_2(dark), 0.96)
	return raised_box(body, 22, Color(accent, 0.48), dark, 6)

static func status_chip(accent: Color, dark: bool) -> StyleBoxFlat:
	var body := Color(accent, 0.17 if dark else 0.11)
	return raised_box(body, 18, Color(accent, 0.56), dark, 4)

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
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, MIN_TOUCH_HEIGHT))
	var current_font := button.get_theme_font_size("font_size")
	button.add_theme_font_size_override("font_size", maxi(20, current_font))
	var normal := surface_2(dark)
	var edge := border(dark)
	var text_color := ink(dark)
	var shadow := 5
	match role:
		"primary":
			normal = accent
			edge = accent.lightened(0.18)
			text_color = Color("061019") if accent.get_luminance() > 0.55 else Color.WHITE
			shadow = 10
		"reward":
			normal = Color(GOLD, 0.98) if dark else Color("fff0bd")
			edge = GOLD.lightened(0.12)
			text_color = Color("241a05")
			shadow = 8
		"success":
			normal = Color(SUCCESS, 0.25) if dark else Color("e4f8ed")
			edge = Color(SUCCESS, 0.86)
			text_color = SUCCESS.lightened(0.20) if dark else Color("1d7043")
			shadow = 5
		"danger":
			normal = Color(DANGER, 0.22) if dark else Color("fff0f2")
			edge = Color(DANGER, 0.78)
			text_color = DANGER.lightened(0.14) if dark else Color("a83243")
		"toggle_off":
			normal = surface_3(dark)
			edge = border(dark)
			text_color = muted(dark)
		"utility":
			normal = Color(surface_2(dark), 0.98)
			edge = Color(accent, 0.48)
			shadow = 5
		"disabled":
			normal = disabled(dark)
			edge = Color(border(dark), 0.55)
			text_color = muted(dark)
			shadow = 0
		_:
			normal = Color(surface_2(dark), 0.99)
			edge = Color(border(dark), 0.96)
	button.add_theme_stylebox_override("normal", gloss_button(normal, radius, dark, shadow) if role in ["primary", "reward"] else raised_box(normal, radius, edge, dark, shadow))
	button.add_theme_stylebox_override("hover", gloss_button(normal.lightened(0.055), radius, dark, max(5, shadow)) if role in ["primary", "reward"] else raised_box(normal.lightened(0.055), radius, accent, dark, max(5, shadow)))
	button.add_theme_stylebox_override("pressed", box(normal.darkened(0.11), radius, accent.lightened(0.14), 2, 1, dark))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, radius, accent, 3, 0, dark))
	button.add_theme_stylebox_override("disabled", box(disabled(dark), radius, Color(border(dark), 0.5), 1, 0, dark))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", muted(dark))
	button.add_theme_constant_override("outline_size", 1 if role in ["primary", "reward"] else 0)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.24))

static func apply_panel(panel: PanelContainer, dark: bool, accent: Color, emphasis: bool = false, radius: int = 28) -> void:
	var fill := Color(surface(dark), 0.985)
	var edge := Color(accent, 0.54) if emphasis else border(dark)
	panel.add_theme_stylebox_override("panel", raised_box(fill, radius, edge, dark, 11 if emphasis else 6))

static func apply_recessed_panel(panel: PanelContainer, dark: bool, accent: Color, radius: int = 28) -> void:
	panel.add_theme_stylebox_override("panel", recessed_box(surface_2(dark), radius, Color(accent, 0.34), dark))

static func apply_label(label: Label, dark: bool, kind: String = "body", accent: Color = Color.WHITE) -> void:
	var current := label.get_theme_font_size("font_size")
	match kind:
		"title":
			label.add_theme_font_size_override("font_size", maxi(TITLE_MIN, current))
			label.add_theme_color_override("font_color", ink(dark))
			label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.28 if dark else 0.10))
			label.add_theme_constant_override("shadow_offset_y", 3)
			label.add_theme_constant_override("shadow_outline_size", 2)
		"accent":
			label.add_theme_color_override("font_color", accent)
			label.add_theme_font_size_override("font_size", maxi(BODY_MIN, current))
		"muted":
			label.add_theme_color_override("font_color", muted(dark))
			label.add_theme_font_size_override("font_size", maxi(NAV_MIN, current))
		_:
			label.add_theme_color_override("font_color", ink(dark))
			label.add_theme_font_size_override("font_size", maxi(BODY_MIN, current))

static func surface_title(text: String) -> String:
	return text.strip_edges().to_upper()
