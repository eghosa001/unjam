extends Control

var selected_game := "rescue_rush"
var built := false
var last_theme := ""
var hero_art: GameShowcaseArt
var hero_title: Label
var hero_subtitle: Label
var hero_progress: Label
var footer_label: Label
var primary_button: Button
var logo: UnjamLogo

const ACCENTS := {
	"rescue_rush": Color("2dd4b6"),
	"water_sort": Color("5da9ff"),
	"block_puzzle": Color("8b7cf6")
}
const SUBTITLES := {
	"rescue_rush": "Clear the lane. Release the chain. Make the rescue.",
	"water_sort": "Read the stack. Pour clean. Finish with perfect colour.",
	"block_puzzle": "Place with intent. Build space. Detonate clean lines."
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
	return Color("f7f9ff") if _dark() else Color("132033")

func _muted() -> Color:
	return Color("9aa9bf") if _dark() else Color("607087")

func _surface() -> Color:
	return Color("050a12") if _dark() else Color("edf3f8")

func _card() -> Color:
	return Color("0c1524") if _dark() else Color("ffffff")

func _border() -> Color:
	return Color("24344a") if _dark() else Color("c4cfdd")

func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0, shadow: int = 0) -> StyleBoxFlat:
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
	if shadow > 0:
		style.shadow_color = Color(0, 0, 0, 0.38 if _dark() else 0.12)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0, shadow * 0.45)
	return style

func build_home_launcher() -> void:
	for child in get_children():
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var accent: Color = ACCENTS[selected_game]

	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(_surface(), accent, ["rescue_rush", "water_sort", "block_puzzle"].find(selected_game))
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 44)
	outer.add_theme_constant_override("margin_right", 44)
	outer.add_theme_constant_override("margin_top", 36)
	outer.add_theme_constant_override("margin_bottom", 118)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	outer.add_child(root)

	# Compact brand header: premium games keep branding strong without spending a quarter of the screen on it.
	logo = UnjamLogo.new()
	logo.custom_minimum_size = Vector2(0, 120)
	logo.configure(_dark())
	root.add_child(logo)

	var hero := PanelContainer.new()
	hero.name = "HomeHero"
	hero.custom_minimum_size = Vector2(0, 700)
	hero.add_theme_stylebox_override("panel", _box(Color(_card(), 0.96), 42, Color(accent, 0.42), 2, 18))
	root.add_child(hero)
	var hero_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		hero_margin.add_theme_constant_override(side, 26)
	hero_margin.add_theme_constant_override("margin_top", 20)
	hero_margin.add_theme_constant_override("margin_bottom", 24)
	hero.add_child(hero_margin)
	var hero_stack := VBoxContainer.new()
	hero_stack.add_theme_constant_override("separation", 8)
	hero_margin.add_child(hero_stack)

	var eyebrow := Label.new()
	eyebrow.text = "FEATURED PUZZLE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", Color(accent, 0.86))
	hero_stack.add_child(eyebrow)

	hero_art = GameShowcaseArt.new()
	hero_art.custom_minimum_size = Vector2(0, 340)
	hero_art.configure(selected_game, accent, _dark())
	hero_stack.add_child(hero_art)

	hero_title = Label.new()
	hero_title.text = MultiGameManager.display_name(selected_game).to_upper()
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_size_override("font_size", 46)
	hero_title.add_theme_color_override("font_color", _ink())
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
	hero_progress.add_theme_color_override("font_color", Color("d9e5f4") if _dark() else Color("314158"))
	hero_stack.add_child(hero_progress)

	primary_button = _button(_primary_text(selected_game), Vector2(0, 90), accent, true)
	primary_button.name = "HomePrimaryAction"
	primary_button.add_theme_font_size_override("font_size", 24)
	primary_button.pressed.connect(_play_selected)
	hero_stack.add_child(primary_button)

	var choose := Label.new()
	choose.text = "CHOOSE A GAME"
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choose.add_theme_font_size_override("font_size", 14)
	choose.add_theme_color_override("font_color", _muted())
	root.add_child(choose)

	var games := HBoxContainer.new()
	games.alignment = BoxContainer.ALIGNMENT_CENTER
	games.add_theme_constant_override("separation", 12)
	root.add_child(games)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var tile := GameSelectTile.new()
		tile.custom_minimum_size = Vector2(316, 170)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.configure(game_id, MultiGameManager.display_name(game_id).to_upper(), _current_level(game_id), ACCENTS[game_id], game_id == selected_game, _dark())
		tile.chosen.connect(_select_game)
		games.add_child(tile)

	var quick := GridContainer.new()
	quick.columns = 2
	quick.add_theme_constant_override("h_separation", 12)
	quick.add_theme_constant_override("v_separation", 12)
	root.add_child(quick)
	var daily := _button("DAILY", Vector2(0, 76), accent)
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily.pressed.connect(_open_daily)
	quick.add_child(daily)
	var journey := _button("LEVELS", Vector2(0, 76), accent)
	journey.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey.pressed.connect(_open_journey)
	quick.add_child(journey)
	var collection := _button("COLLECTION", Vector2(0, 76), accent)
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.pressed.connect(func(): get_parent().call("build_collection"))
	quick.add_child(collection)
	var settings := _button("SETTINGS", Vector2(0, 76), accent)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	quick.add_child(settings)

	footer_label = Label.new()
	footer_label.text = _shared_progress_text()
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 14)
	footer_label.add_theme_color_override("font_color", _muted())
	root.add_child(footer_label)

	modulate.a = 0.0
	position.y += 18.0
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.28)
	tween.parallel().tween_property(self, "position:y", position.y - 18.0, 0.34)

func _button(text_value: String, minimum: Vector2, accent: Color, strong: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = minimum
	b.add_theme_font_size_override("font_size", 16)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := accent if strong else Color(_card(), 0.96)
	var normal_border := accent.lightened(0.14) if strong else _border()
	b.add_theme_stylebox_override("normal", _box(normal, 24, normal_border, 2, 8 if strong else 4))
	b.add_theme_stylebox_override("hover", _box(normal.lightened(0.06), 24, accent, 2, 8))
	b.add_theme_stylebox_override("pressed", _box(normal.darkened(0.10), 24, accent.lightened(0.22), 2, 2))
	b.add_theme_color_override("font_color", Color("061019") if strong and accent.get_luminance() > 0.55 else _ink())
	return b

func _current_level(game_id: String) -> int:
	return clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)

func _hero_progress_text(game_id: String) -> String:
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
	return "%d / 30,000 CLEARED   •   %d COINS   •   %d PRESTIGE" % [completed, int(SaveManager.data.get("coins", 0)), int(SaveManager.data.get("prestige_points", 0))]

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
	if main != null:
		main.call("open_game_campaign", selected_game)
