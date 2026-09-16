class_name PremiumDesignSystem
extends RefCounted

const GAME_ACCENTS := {
	"rescue_rush": Color("19dba9"),
	"water_sort": Color("279cff"),
	"block_puzzle": Color("bd4cff")
}

const GOLD := Color("ffd23f")
const DANGER := Color("ff5f78")
const SUCCESS := Color("35d979")

static func accent_for_game(game_id: String) -> Color:
	return GAME_ACCENTS.get(game_id, GAME_ACCENTS["rescue_rush"])

static func vibrant_canvas(game_id: String) -> Color:
	match game_id:
		"water_sort": return Color("78d7ff")
		"block_puzzle": return Color("efa6ff")
		_: return Color("76efd9")

static func vibrant_surface(game_id: String) -> Color:
	match game_id:
		"water_sort": return Color("e6f8ff")
		"block_puzzle": return Color("fae9ff")
		_: return Color("e7fff7")

static func game_gradient(game_id: String) -> Array[Color]:
	match game_id:
		"water_sort": return [Color("14a8ff"), Color("4368ff"), Color("69e6ff")]
		"block_puzzle": return [Color("9d36ff"), Color("f14fd4"), Color("ff8b6e")]
		_: return [Color("08cf93"), Color("10b8e7"), Color("7cf05d")]

static func ink(dark: bool) -> Color:
	return Color("f8fbff") if dark else Color("12304b")

static func muted(dark: bool) -> Color:
	return Color("c4d2e4") if dark else Color("516d88")

static func canvas(dark: bool) -> Color:
	return Color("0b1730") if dark else Color("eef8ff")

static func surface(dark: bool) -> Color:
	return Color("11223f") if dark else Color("fbfdff")

static func surface_2(dark: bool) -> Color:
	return Color("183052") if dark else Color("eef7ff")

static func surface_3(dark: bool) -> Color:
	return Color("234267") if dark else Color("dceeff")

static func border(dark: bool) -> Color:
	return Color("3e6b94") if dark else Color("9bc5e6")

static func disabled(dark: bool) -> Color:
	return Color("24354c") if dark else Color("e5edf5")

static func game_canvas(game_id: String, dark: bool) -> Color:
	if not dark:
		return vibrant_canvas(game_id).lerp(Color.WHITE, 0.32)
	match game_id:
		"water_sort": return Color("0b3f74")
		"block_puzzle": return Color("43105f")
		_: return Color("075f59")

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
		style.shadow_color = Color(0.015, 0.08, 0.16, 0.32 if dark else 0.16)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0, maxf(1.0, shadow * 0.42))
	return style

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
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, 78.0))
	var current_font := button.get_theme_font_size("font_size")
	button.add_theme_font_size_override("font_size", maxi(20, current_font))
	var normal := surface_2(dark)
	var edge := border(dark)
	var text_color := ink(dark)
	var shadow := 5
	match role:
		"primary":
			normal = accent.lightened(0.06)
			edge = accent.lightened(0.28)
			text_color = Color("05243a") if accent.get_luminance() > 0.58 else Color.WHITE
			shadow = 10
		"reward":
			normal = Color("ffe16c")
			edge = GOLD
			text_color = Color("372600")
			shadow = 8
		"success":
			normal = Color(SUCCESS, 0.30) if dark else Color("d8ffe8")
			edge = Color(SUCCESS, 0.92)
			text_color = SUCCESS.lightened(0.22) if dark else Color("12683a")
		"danger":
			normal = Color(DANGER, 0.24) if dark else Color("ffe7ec")
			edge = Color(DANGER, 0.88)
			text_color = DANGER.lightened(0.18) if dark else Color("9e2638")
		"toggle_off":
			normal = surface_3(dark)
			edge = border(dark)
			text_color = muted(dark)
		"utility":
			normal = Color(surface_2(dark), 0.98)
			edge = Color(accent, 0.62)
		"disabled":
			normal = disabled(dark)
			edge = Color(border(dark), 0.55)
			text_color = muted(dark)
			shadow = 0
		_:
			normal = Color(surface_2(dark), 0.98)
			edge = Color(accent, 0.42)
	button.add_theme_stylebox_override("normal", box(normal, radius, edge, 2, shadow, dark))
	button.add_theme_stylebox_override("hover", box(normal.lightened(0.075), radius, accent.lightened(0.12), 3, max(4, shadow), dark))
	button.add_theme_stylebox_override("pressed", box(normal.darkened(0.09), radius, accent.lightened(0.20), 2, 2, dark))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, radius, accent, 3, 0, dark))
	button.add_theme_stylebox_override("disabled", box(disabled(dark), radius, Color(border(dark), 0.5), 1, 0, dark))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", muted(dark))

static func apply_panel(panel: PanelContainer, dark: bool, accent: Color, emphasis: bool = false, radius: int = 28) -> void:
	var fill := Color(surface(dark), 0.95)
	var edge := Color(accent, 0.64) if emphasis else border(dark)
	panel.add_theme_stylebox_override("panel", box(fill, radius, edge, 3 if emphasis else 1, 12 if emphasis else 5, dark))

static func apply_label(label: Label, dark: bool, kind: String = "body", accent: Color = Color.WHITE) -> void:
	match kind:
		"title":
			label.add_theme_color_override("font_color", ink(dark))
			label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.22 if dark else 0.08))
			label.add_theme_constant_override("shadow_offset_y", 2)
		"accent":
			label.add_theme_color_override("font_color", accent)
		"muted":
			label.add_theme_color_override("font_color", muted(dark))
		_:
			label.add_theme_color_override("font_color", ink(dark))

static func surface_title(text: String) -> String:
	return text.strip_edges().to_upper()
