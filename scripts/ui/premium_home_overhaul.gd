extends Control

var selected_game := "rescue_rush"
var built := false
var last_theme := ""
var hero_art: GameShowcaseArt
var hero_title: Label
var hero_subtitle: Label
var hero_progress: Label
var primary_button: Button
var tile_row: VBoxContainer
var logo: UnjamLogo

const ACCENTS := {
	"rescue_rush": Color("2dd4b6"),
	"water_sort": Color("5da9ff"),
	"block_puzzle": Color("8b7cf6")
}
const SUBTITLES := {
	"rescue_rush": "CLEAR THE PATH. TRIGGER THE CHAIN. SAVE THEM.",
	"water_sort": "POUR. SORT. RELAX. MASTER EVERY COLOR.",
	"block_puzzle": "PLACE SMART. CLEAR LINES. BUILD COMBOS."
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_sync")

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	visible = surface == "home"
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		return
	var mode := _theme_mode()
	if not built or mode != last_theme:
		_sync()

func _sync() -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface != "home":
		visible = false
		return
	var current = main.get("selected_game_id")
	if current != null and String(current) in ACCENTS:
		selected_game = String(current)
	build_home_launcher()

func _theme_mode() -> String:
	var shell := get_parent().get_node_or_null("UXShell")
	if shell != null and shell.get("theme_mode") != null:
		return String(shell.get("theme_mode"))
	return "dark"

func _dark() -> bool:
	return _theme_mode() == "dark"

func _ink() -> Color:
	return Color("f7f9ff") if _dark() else Color("14213a")

func _muted() -> Color:
	return Color("aebbd0") if _dark() else Color("52637a")

func _surface() -> Color:
	return Color("0a1220") if _dark() else Color("f5f8fc")

func _card() -> Color:
	return Color("111d31") if _dark() else Color("ffffff")

func _border() -> Color:
	return Color("33445e") if _dark() else Color("b7c4d6")

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
	style.shadow_color = Color(0,0,0,0.30) if _dark() else Color(0.08,0.12,0.2,0.12)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0,6)
	return style

func build_home_launcher() -> void:
	for child in get_children():
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = _surface()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var accent: Color = ACCENTS[selected_game]
	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(accent, 0.045 if _dark() else 0.055)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 150)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	logo = UnjamLogo.new()
	logo.custom_minimum_size = Vector2(0, 220)
	logo.configure(_dark())
	root.add_child(logo)

	var hero := PanelContainer.new()
	hero.name = "HomeHero"
	hero.custom_minimum_size = Vector2(0, 700)
	hero.add_theme_stylebox_override("panel", _box(_card(), 42, Color(accent, 0.52), 2))
	root.add_child(hero)
	var hero_stack := VBoxContainer.new()
	hero_stack.add_theme_constant_override("separation", 4)
	hero.add_child(hero_stack)

	hero_art = GameShowcaseArt.new()
	hero_art.custom_minimum_size = Vector2(0, 430)
	hero_art.configure(selected_game, accent, _dark())
	hero_stack.add_child(hero_art)

	hero_title = Label.new()
	hero_title.text = MultiGameManager.display_name(selected_game).to_upper()
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_size_override("font_size", 42)
	hero_title.add_theme_color_override("font_color", accent)
	hero_stack.add_child(hero_title)

	hero_subtitle = Label.new()
	hero_subtitle.text = SUBTITLES[selected_game]
	hero_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_subtitle.add_theme_font_size_override("font_size", 17)
	hero_subtitle.add_theme_color_override("font_color", _muted())
	hero_stack.add_child(hero_subtitle)

	hero_progress = Label.new()
	hero_progress.text = _hero_progress_text(selected_game)
	hero_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_progress.add_theme_font_size_override("font_size", 18)
	hero_progress.add_theme_color_override("font_color", _ink())
	hero_stack.add_child(hero_progress)

	primary_button = Button.new()
	primary_button.name = "HomePrimaryAction"
	primary_button.text = _primary_text(selected_game)
	primary_button.custom_minimum_size = Vector2(0, 94)
	primary_button.add_theme_font_size_override("font_size", 25)
	primary_button.pressed.connect(_play_selected)
	hero_stack.add_child(primary_button)

	var choose := Label.new()
	choose.text = "CHOOSE YOUR PUZZLE"
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choose.add_theme_font_size_override("font_size", 15)
	choose.add_theme_color_override("font_color", _muted())
	root.add_child(choose)

	tile_row = VBoxContainer.new()
	tile_row.add_theme_constant_override("separation", 10)
	root.add_child(tile_row)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var tile := GameSelectTile.new()
		tile.custom_minimum_size = Vector2(0, 136)
		tile.configure(game_id, MultiGameManager.display_name(game_id).to_upper(), _current_level(game_id), ACCENTS[game_id], game_id == selected_game, _dark())
		tile.chosen.connect(_select_game)
		tile_row.add_child(tile)

	var secondary := HBoxContainer.new()
	secondary.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary.add_theme_constant_override("separation", 12)
	root.add_child(secondary)
	var daily := _small_button("DAILY", Vector2(212, 72))
	daily.pressed.connect(_open_daily)
	secondary.add_child(daily)
	var journey := _small_button("JOURNEY", Vector2(212, 72))
	journey.pressed.connect(_open_journey)
	secondary.add_child(journey)
	var collection := _small_button("COLLECTION", Vector2(212, 72))
	collection.pressed.connect(func(): get_parent().call("build_collection"))
	secondary.add_child(collection)
	var settings := _small_button("SETTINGS", Vector2(212, 72))
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	secondary.add_child(settings)

	var footer := Label.new()
	footer.text = _shared_progress_text()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 15)
	footer.add_theme_color_override("font_color", _muted())
	root.add_child(footer)
	call_deferred("_restyle_buttons")

func _small_button(text_value: String, minimum: Vector2) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = minimum
	b.add_theme_font_size_override("font_size", 16)
	return b

func _restyle_buttons() -> void:
	if not is_instance_valid(primary_button):
		return
	var accent: Color = ACCENTS[selected_game]
	primary_button.add_theme_stylebox_override("normal", _box(accent, 26, accent.lightened(0.16), 2))
	primary_button.add_theme_stylebox_override("hover", _box(accent.lightened(0.08), 26, Color.WHITE, 2))
	primary_button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.10), 26, Color.WHITE, 2))
	primary_button.add_theme_color_override("font_color", Color("071421") if accent.get_luminance() > 0.58 else Color.WHITE)

func _current_level(game_id: String) -> int:
	return clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)

func _hero_progress_text(game_id: String) -> String:
	var progress := MultiGameManager.progress_for(game_id)
	var level := _current_level(game_id)
	var world := MultiGameManager.highest_unlocked_world(game_id)
	var stars := MultiGameManager.total_stars(game_id)
	return "LEVEL %d   •   WORLD %d   •   %d ★" % [level, world, stars]

func _primary_text(game_id: String) -> String:
	var main := get_parent()
	if main != null and main.has_method("_checkpoint_for"):
		var checkpoint = main.call("_checkpoint_for", game_id)
		if checkpoint is Dictionary and not checkpoint.is_empty():
			return "CONTINUE  •  LEVEL %d" % int(checkpoint.get("level", _current_level(game_id)))
	return "PLAY  •  LEVEL %d" % _current_level(game_id)

func _shared_progress_text() -> String:
	var completed := 0
	for game_id in MultiGameManager.GAME_IDS:
		completed += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	return "%d / 30,000 CLEARED   •   %d COINS   •   %d PRESTIGE" % [completed, int(SaveManager.data.get("coins",0)), int(SaveManager.data.get("prestige_points",0))]

func _select_game(game_id: String) -> void:
	if game_id == selected_game:
		return
	selected_game = game_id
	var main := get_parent()
	if main != null:
		main.set("selected_game_id", game_id)
	build_home_launcher()

func _play_selected() -> void:
	var main := get_parent()
	if main == null:
		return
	if main.has_method("_checkpoint_for"):
		var checkpoint = main.call("_checkpoint_for", selected_game)
		if checkpoint is Dictionary and not checkpoint.is_empty():
			main.call("resume_game", selected_game)
			return
	main.call("open_game_campaign", selected_game)

func _open_daily() -> void:
	var main := get_parent()
	if main != null:
		main.call("start_game_daily", selected_game)

func _open_journey() -> void:
	var main := get_parent()
	if main == null:
		return
	main.call("open_game_campaign", selected_game)
