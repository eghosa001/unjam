extends RefCounted
## UNJAM V3 -- static, game-safe visual materials for secondary screens.
## No input, navigation, economy, preference or ranking state is changed.
const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

static func _accent(surface: String) -> Color:
	match surface:
		"settings": return Color("#63DCC4")
		"daily": return Color("#66D5B3")
		"compete": return Color("#C5A2FF")
		"selector": return Color("#6DDCCB")
		_: return Color("#67CAE9")

static func _material(fill: Color, edge: Color, radius: int = 18, depth: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.01, 0.05, 0.12, 0.22)
	s.shadow_size = depth
	s.shadow_offset = Vector2(0, float(depth))
	s.anti_aliasing = true
	return s

static func _button(button: Button, fill: Color, dark: bool, radius: int = 14) -> void:
	var edge := fill.lightened(0.23) if dark else fill.darkened(0.15)
	var ink := RefCanvas.accessible_text_color(
		Color("#F6FFFF") if dark else Color("#123B4A"), fill, 4.5)
	button.flat = false
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.add_theme_stylebox_override("normal", _material(fill, edge, radius, 3))
	button.add_theme_stylebox_override("hover", _material(fill.lightened(0.08), edge, radius, 3))
	button.add_theme_stylebox_override("pressed", _material(fill.darkened(0.13), edge, radius, 1))
	button.add_theme_stylebox_override("focus", _material(fill, Color("#FFF2B2"), radius, 3))
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	if button.disabled:
		var disabled_fill := Color("#244E43") if dark else Color("#D9ECE4")
		var disabled_ink := Color("#E5FFF2") if dark else Color("#1A5441")
		button.add_theme_stylebox_override("disabled", _material(disabled_fill,
			Color("#6AA18C") if dark else Color("#A5CDB9"), radius, 1))
		button.add_theme_color_override("font_disabled_color", disabled_ink)
	# Keep authored accessibility and control geometry. Do not resize buttons.
	button.set_meta("unjam_preserve_surface_style", true)
	button.set_meta("unjam_preserve_control_geometry", true)

static func _card_surface(name_value: String, surface: String, dark: bool) -> Color:
	var ink := Color("#172B40") if dark else Color("#FFFFFF")
	match surface:
		"settings":
			if name_value.contains("Sound"): return Color("#16394A") if dark else Color("#F0F9F8")
			if name_value.contains("Comfort"): return Color("#25314A") if dark else Color("#F1F4FB")
			if name_value.contains("Appearance"): return Color("#1D3B3C") if dark else Color("#E9F7EF")
			return Color("#1A3043") if dark else Color("#F8FBFC")
		"daily":
			if name_value.contains("rescue_rush"): return Color("#103A38") if dark else Color("#E5F7EF")
			if name_value.contains("water_sort"): return Color("#133B52") if dark else Color("#E5F5FC")
			if name_value.contains("block_puzzle"): return Color("#312A4B") if dark else Color("#F1EAFE")
			if name_value.contains("CheckIn"): return Color("#2C3548") if dark else Color("#FFF4DF")
			return Color("#173B3F") if dark else Color("#F7FCF9")
		"compete":
			if name_value.contains("Leaderboard"): return Color("#252C46") if dark else Color("#F5F0FD")
			return Color("#1C3445") if dark else Color("#F8F7FD")
	return ink

static func apply(canvas: Control, surface: String, dark: bool) -> void:
	if canvas == null or not is_instance_valid(canvas):
		return
	var accent := _accent(surface)
	var bg := canvas.get_node_or_null("FigmaSurfaceBackground") as PanelContainer
	if bg != null:
		bg.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#0E273B") if dark else Color("#F8FCF9"),
			Color("#0B1B2E") if dark else Color("#EBF5F3"),
			Color("#091522") if dark else Color("#E3EFEF"),
			28, Color(accent, 0.10), 1, 0.10))
	for node in canvas.find_children("*", "PanelContainer", true, false):
		var panel := node as PanelContainer
		if panel == null or panel == bg:
			continue
		var name_value := String(panel.name)
		var is_card := name_value.begins_with("SettingsCard/") or name_value in [
			"HelpPrivacy", "DailyProgress", "DailyCheckIn", "CompetitionPlayerProgress",
			"CompetitionPrizeTimingCard"] or name_value.begins_with("DailyCard/") \
			or name_value.begins_with("Leaderboard/")
		if not is_card:
			continue
		var fill := _card_surface(name_value, surface, dark)
		var edge := Color(accent.r, accent.g, accent.b, 0.32 if dark else 0.21)
		if name_value.contains("water_sort"): edge = Color("#64CFFA", 0.55)
		if name_value.contains("block_puzzle"): edge = Color("#C2A0F8", 0.55)
		if name_value.contains("rescue_rush"): edge = Color("#58D9A8", 0.55)
		panel.add_theme_stylebox_override("panel", _material(fill, edge, 19, 4))
	for node in canvas.find_children("*", "Button", true, false):
		var b := node as Button
		if b == null or b.flat and b.text.is_empty():
			continue
		var id := String(b.name)
		var fill := Color("#27485A") if dark else Color("#E5F0EF")
		if id.begins_with("SettingToggle/"):
			fill = Color("#35B58F") if b.text == "ON" else (Color("#34475A") if dark else Color("#D6E2E5"))
		elif id == "SettingsThemeToggle": fill = Color("#3BC3A9") if dark else Color("#168D80")
		elif id.begins_with("Settings"): fill = Color("#2B5262") if dark else Color("#DDECEB")
		elif id.begins_with("DailyPlay_"):
			if id.ends_with("rescue_rush"): fill = Color("#32BC8F") if dark else Color("#159B73")
			if id.ends_with("water_sort"): fill = Color("#2495C8") if dark else Color("#0E7EA7")
			if id.ends_with("block_puzzle"): fill = Color("#9970D3") if dark else Color("#7854B6")
		elif id == "DailyLeaderboardOpen": fill = Color("#7059B5")
		elif id == "DailyCheckInAction": fill = Color("#D99646") if dark else Color("#AD6E23")
		elif id.begins_with("RankingGame_"):
			fill = accent if b.mouse_filter == Control.MOUSE_FILTER_IGNORE else (Color("#354054") if dark else Color("#E6E0F0"))
		elif id.begins_with("Competition"):
			fill = Color("#755AAE") if dark else Color("#6F51A4")
		elif id == "FigmaBack": fill = Color("#27485A") if dark else Color("#DCEAE8")
		elif id == "FigmaHeaderPill": fill = accent.darkened(0.40) if dark else accent.darkened(0.22)
		_button(b, fill, dark, 13)
	for node in canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null: continue
		var n := String(label.name)
		if n == "FigmaHeaderTitle":
			label.add_theme_color_override("font_color", Color("#F7FBFF") if dark else Color("#193849"))
		elif n == "FigmaHeaderSubtitle":
			label.add_theme_color_override("font_color", Color("#BFD6E0") if dark else Color("#476B77"))
		elif n.begins_with("DailyTitle_"):
			label.add_theme_color_override("font_color", Color("#F7FCFF") if dark else Color("#1C3B4C"))
	# Preserve all existing labels, localized text, real counters, save values,
	# enabled/disabled states, callback connections, and nav geometry.
