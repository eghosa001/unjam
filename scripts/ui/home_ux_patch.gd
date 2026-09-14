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
	# The premium backdrop must never fade out during game selection changes.
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
	# Premium screens are assembled at runtime. Refresh them whenever the user
	# re-enters the surface so coins, stars, checkpoints and progress never show
	# stale values after finishing or quitting a level.
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
	panel.custom_minimum_size = Vector2(0, 154)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(card_color, 28, Color(accent, 0.42), 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 6)
	row.add_child(copy)
	var title := Label.new()
	title.text = "YOUR %s JOURNEY" % MultiGameManager.display_name(game_id).to_upper()
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", accent)
	copy.add_child(title)
	var level := clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var meta := Label.new()
	meta.text = "WORLD %d / 100   •   LEVEL %d / 10,000   •   %d ★" % [MultiGameManager.highest_unlocked_world(game_id), level, MultiGameManager.total_stars(game_id)]
	meta.add_theme_font_size_override("font_size", 18)
	meta.add_theme_color_override("font_color", meta_color)
	copy.add_child(meta)
	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = MultiGameManager.CAMPAIGN_LEVELS
	progress.value = level
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 14)
	progress.add_theme_stylebox_override("background", _box(track_color, 7))
	progress.add_theme_stylebox_override("fill", _box(accent, 7))
	copy.add_child(progress)
	var stats := Label.new()
	stats.custom_minimum_size = Vector2(260, 72)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.text = "DAILY STREAK  %d\nPERFECT CLEARS  %d" % [int(SaveManager.data.get("daily_streak", 0)), int(MultiGameManager.progress_for(game_id).get("perfect_clears", 0))]
	stats.add_theme_font_size_override("font_size", 17)
	stats.add_theme_color_override("font_color", muted_color)
	row.add_child(stats)
	# Root order is header, hero, section, games, quick. Put journey immediately before quick.
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
