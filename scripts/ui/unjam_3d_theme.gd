class_name Unjam3DTheme
extends RefCounted

const SKY_TOP := Color("41b9ff")
const SKY_BOTTOM := Color("dff8ff")
const DEEP_BLUE := Color("075bb8")
const NAVY := Color("073b78")
const INK := Color("12345a")
const WHITE := Color("fffef8")
const GOLD := Color("ffd83d")
const ORANGE := Color("ff8d1f")
const GREEN := Color("20d86b")
const GREEN_DARK := Color("079341")
const WATER := Color("19b9ff")
const WATER_DARK := Color("087dcc")
const PURPLE := Color("c63cff")
const PURPLE_DARK := Color("7d20d7")
const PINK := Color("ff4ca5")
const RED := Color("ff4d55")

static func game_accent(game_id: String) -> Color:
	match game_id:
		"water_sort": return WATER
		"block_puzzle": return PURPLE
		_: return GREEN

static func game_dark(game_id: String) -> Color:
	match game_id:
		"water_sort": return WATER_DARK
		"block_puzzle": return PURPLE_DARK
		_: return GREEN_DARK

static func panel_3d(fill: Color, radius: int = 28, edge: Color = Color.WHITE, edge_width: int = 2, depth: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = edge_width
	style.border_width_right = edge_width
	style.border_width_top = edge_width
	style.border_width_bottom = edge_width
	style.border_color = edge
	style.shadow_color = Color(0.02, 0.18, 0.34, 0.32)
	style.shadow_size = depth
	style.shadow_offset = Vector2(0, maxf(2.0, depth * 0.48))
	return style

static func gloss_button(button: Button, accent: Color, primary: bool = true, radius: int = 28) -> void:
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 72.0)
	button.add_theme_font_size_override("font_size", maxi(22, button.get_theme_font_size("font_size")))
	var base := accent if primary else Color("edf9ff")
	var edge := accent.lightened(0.28) if primary else Color("9de2ff")
	var pressed := base.darkened(0.14)
	button.add_theme_stylebox_override("normal", panel_3d(base, radius, edge, 3, 12 if primary else 7))
	button.add_theme_stylebox_override("hover", panel_3d(base.lightened(0.08), radius, Color.WHITE, 3, 14 if primary else 8))
	button.add_theme_stylebox_override("pressed", panel_3d(pressed, radius, edge, 3, 3))
	button.add_theme_stylebox_override("focus", panel_3d(Color.TRANSPARENT, radius, Color.WHITE, 3, 0))
	button.add_theme_color_override("font_color", Color.WHITE if primary else NAVY)
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else NAVY)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if primary else NAVY)
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.18, 0.34, 0.55))
	button.add_theme_constant_override("outline_size", 3)

static func label_3d(label: Label, color: Color = Color.WHITE, outline: Color = Color("07518e"), outline_size: int = 4) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.12, 0.25, 0.34))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 4)

static func badge(fill: Color, radius: int = 22) -> StyleBoxFlat:
	return panel_3d(fill, radius, fill.lightened(0.34), 2, 7)
