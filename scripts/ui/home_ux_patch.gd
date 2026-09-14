extends Node

var patched_outer_id := 0
var last_surface := ""

func _ready() -> void:
	var main := get_parent()
	if main != null and main.get("current_surface") != null:
		last_surface = String(main.get("current_surface"))

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface != last_surface:
		last_surface = surface
		_refresh_surface(surface)

	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null or not home.visible:
		return
	home.modulate = Color.WHITE
	home.position = Vector2.ZERO
	var outer := _find_outer(home)
	if outer == null:
		return
	outer.modulate = Color.WHITE
	if outer.get_instance_id() == patched_outer_id:
		return
	patched_outer_id = outer.get_instance_id()
	_patch_layout(outer)

func _refresh_surface(surface: String) -> void:
	var main := get_parent()
	if surface == "home":
		patched_outer_id = 0
		var home := main.get_node_or_null("PremiumHome")
		if home != null and home.has_method("_sync"):
			home.call_deferred("_sync")
	elif surface == "live":
		var live := main.get_node_or_null("PremiumLive")
		if live != null and live.has_method("_build"):
			live.call_deferred("_build")

func _find_outer(home: Control) -> MarginContainer:
	for child in home.get_children():
		if child is MarginContainer:
			return child as MarginContainer
	return null

func _patch_layout(outer: MarginContainer) -> void:
	if outer.get_child_count() == 0:
		return
	var root := outer.get_child(0) as VBoxContainer
	if root == null:
		return
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var existing := root.get_node_or_null("JourneyFill")
	if existing != null:
		return
	var main := get_parent()
	var game_id := String(main.get("selected_game_id")) if main.get("selected_game_id") != null else "rescue_rush"
	if game_id not in MultiGameManager.GAME_IDS:
		game_id = "rescue_rush"
	var accent := _accent(game_id)
	var dark := _is_dark_theme()
	var card_color := Color("0b1626") if dark else Color("ffffff")
	var meta_color := Color("d8e4f4") if dark else Color("34445a")
	var muted_color := Color("9aa9bf") if dark else Color("607087")
	var track_color := Color("101b2d") if dark else Color("dbe5ef")

	var panel := PanelContainer.new()
	panel.name = "JourneyFill"
	panel.custom_minimum_size = Vector2(0, 270)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(card_color, 28, Color(accent, 0.42), 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "YOUR %s JOURNEY" % MultiGameManager.display_name(game_id).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", accent)
	stack.add_child(title)
	var level := clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var world := MultiGameManager.highest_unlocked_world(game_id)
	var meta := Label.new()
	meta.text = "LEVEL %d / 10,000   •   WORLD %d / 100   •   %d ★" % [level, world, MultiGameManager.total_stars(game_id)]
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.add_theme_font_size_override("font_size", 24)
	meta.add_theme_color_override("font_color", meta_color)
	stack.add_child(meta)
	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = MultiGameManager.CAMPAIGN_LEVELS
	progress.value = level
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 24)
	progress.add_theme_stylebox_override("background", _box(track_color, 9))
	progress.add_theme_stylebox_override("fill", _box(accent, 9))
	stack.add_child(progress)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 16)
	stack.add_child(stats)
	for item in [
		["CURRENT LEVEL", str(level)],
		["CURRENT WORLD", "%d / 100" % world],
		["DAILY STREAK", str(int(SaveManager.data.get("daily_streak", 0)))],
		["PERFECT CLEARS", str(int(MultiGameManager.progress_for(game_id).get("perfect_clears", 0)))]
	]:
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(205, 132)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel", _box(track_color, 20, Color(accent, 0.20), 1))
		var tile_margin := MarginContainer.new()
		tile_margin.add_theme_constant_override("margin_top", 14)
		tile_margin.add_theme_constant_override("margin_bottom", 14)
		tile_margin.add_theme_constant_override("margin_left", 10)
		tile_margin.add_theme_constant_override("margin_right", 10)
		tile.add_child(tile_margin)
		var stat := VBoxContainer.new()
		stat.alignment = BoxContainer.ALIGNMENT_CENTER
		tile_margin.add_child(stat)
		var value := Label.new()
		value.text = String(item[1])
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_size_override("font_size", 42)
		value.add_theme_color_override("font_color", meta_color)
		stat.add_child(value)
		var caption := Label.new()
		caption.text = String(item[0])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 18)
		caption.add_theme_color_override("font_color", muted_color)
		stat.add_child(caption)
		stats.add_child(tile)
	var footer := Label.new()
	footer.text = "NEXT WORLD AT LEVEL %d   •   KEEP YOUR DAILY STREAK ALIVE" % mini(MultiGameManager.CAMPAIGN_LEVELS, world * 100)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 19)
	footer.add_theme_color_override("font_color", muted_color)
	stack.add_child(footer)
	var insert_at := maxi(0, root.get_child_count() - 1)
	root.add_child(panel)
	root.move_child(panel, insert_at)

func _is_dark_theme() -> bool:
	var shell := get_parent().get_node_or_null("UXShell")
	if shell != null and shell.get("theme_mode") != null:
		return String(shell.get("theme_mode")) == "dark"
	return true

func _accent(game_id: String) -> Color:
	match game_id:
		"water_sort": return Color("5da9ff")
		"block_puzzle": return Color("8b7cf6")
		_: return Color("2dd4b6")

func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if width > 0:
		style.border_width_left = width
		style.border_width_right = width
		style.border_width_top = width
		style.border_width_bottom = width
		style.border_color = border
	return style
