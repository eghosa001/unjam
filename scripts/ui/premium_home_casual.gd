extends "res://scripts/ui/premium_home_overhaul.gd"

func _ink() -> Color:
	return PremiumDesignSystem.ink(_dark())

func _muted() -> Color:
	return PremiumDesignSystem.muted(_dark())

func _surface() -> Color:
	return PremiumDesignSystem.canvas(_dark())

func _card() -> Color:
	return PremiumDesignSystem.surface(_dark())

func _border() -> Color:
	return PremiumDesignSystem.border(_dark())

func _casual_accent(game_id: String) -> Color:
	return PremiumDesignSystem.accent_for_game(game_id)

func _status_chip(text_value: String, tint: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 64)
	panel.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(tint, _dark()))
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", PremiumDesignSystem.ink(_dark()))
	panel.add_child(label)
	return panel

func build_home_launcher() -> void:
	for child in get_children():
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var accent: Color = _casual_accent(selected_game)

	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(PremiumDesignSystem.game_canvas(selected_game, _dark()), accent, ["rescue_rush", "water_sort", "block_puzzle"].find(selected_game))
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 30)
	outer.add_theme_constant_override("margin_right", 30)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 106)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	outer.add_child(root)

	# Progression row: compact tactile chips instead of a dashboard card.
	var status_row := HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 10)
	root.add_child(status_row)
	var level_chip := _status_chip("LV %d" % _current_level(selected_game), accent)
	level_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(level_chip)
	var coins_chip := _status_chip("◈  %d" % int(SaveManager.data.get("coins", 0)), PremiumDesignSystem.GOLD)
	coins_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(coins_chip)
	var stars_chip := _status_chip("★  %d" % _total_stars(), PremiumDesignSystem.GOLD)
	stars_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(stars_chip)

	logo = UnjamLogo.new()
	logo.name = "PremiumUnjamLogo"
	logo.custom_minimum_size = Vector2(0, 126)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo.configure(_dark())
	root.add_child(logo)

	var strap := Label.new()
	strap.text = "THREE PUZZLES  •  ONE JOURNEY"
	strap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strap.add_theme_font_size_override("font_size", 18)
	strap.add_theme_color_override("font_color", Color(accent, 0.95))
	strap.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
	strap.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(strap)

	# Hero is deliberately world-first: art dominates, UI sits over/around it.
	var hero := PanelContainer.new()
	hero.name = "HomeHero"
	hero.custom_minimum_size = Vector2(0, 610)
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color(_card(), 0.76), 40, Color(accent, 0.46), _dark(), 12))
	root.add_child(hero)
	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 18)
	hero_margin.add_theme_constant_override("margin_right", 18)
	hero_margin.add_theme_constant_override("margin_top", 14)
	hero_margin.add_theme_constant_override("margin_bottom", 18)
	hero.add_child(hero_margin)
	var hero_stack := VBoxContainer.new()
	hero_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_stack.add_theme_constant_override("separation", 5)
	hero_margin.add_child(hero_stack)

	hero_art = GameShowcaseArt.new()
	hero_art.name = "HomeShowcaseArt"
	hero_art.custom_minimum_size = Vector2(0, 370)
	hero_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_art.configure(selected_game, accent, _dark())
	hero_stack.add_child(hero_art)

	hero_title = Label.new()
	hero_title.text = MultiGameManager.display_name(selected_game).to_upper()
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_size_override("font_size", 40)
	hero_title.add_theme_color_override("font_color", PremiumDesignSystem.ink(_dark()))
	hero_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
	hero_title.add_theme_constant_override("shadow_offset_y", 3)
	hero_stack.add_child(hero_title)

	hero_subtitle = Label.new()
	hero_subtitle.text = SUBTITLES[selected_game]
	hero_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_subtitle.add_theme_font_size_override("font_size", 20)
	hero_subtitle.add_theme_color_override("font_color", _muted())
	hero_stack.add_child(hero_subtitle)

	hero_progress = Label.new()
	hero_progress.text = _hero_progress_text(selected_game)
	hero_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_progress.add_theme_font_size_override("font_size", 18)
	hero_progress.add_theme_color_override("font_color", Color(accent, 0.95))
	hero_stack.add_child(hero_progress)

	primary_button = Button.new()
	primary_button.name = "HomePrimaryAction"
	primary_button.text = "▶   %s" % _primary_text(selected_game)
	primary_button.custom_minimum_size = Vector2(0, 104)
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button.add_theme_font_size_override("font_size", 30)
	PremiumDesignSystem.apply_button(primary_button, _dark(), accent, "primary", 30)
	primary_button.pressed.connect(_play_selected)
	hero_stack.add_child(primary_button)

	var section := HBoxContainer.new()
	root.add_child(section)
	var choose := Label.new()
	choose.text = "CHOOSE A GAME"
	choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose.add_theme_font_size_override("font_size", 22)
	choose.add_theme_color_override("font_color", _ink())
	section.add_child(choose)
	footer_label = Label.new()
	footer_label.text = _shared_progress_text()
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer_label.add_theme_font_size_override("font_size", 16)
	footer_label.add_theme_color_override("font_color", _muted())
	section.add_child(footer_label)

	var games := HBoxContainer.new()
	games.alignment = BoxContainer.ALIGNMENT_CENTER
	games.add_theme_constant_override("separation", 10)
	root.add_child(games)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var tile := GameSelectTile.new()
		tile.custom_minimum_size = Vector2(0, 188)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.configure(game_id, MultiGameManager.display_name(game_id).to_upper(), _current_level(game_id), _casual_accent(game_id), game_id == selected_game, _dark())
		tile.chosen.connect(_select_game)
		games.add_child(tile)

	var secondary := GridContainer.new()
	secondary.name = "HomeSecondaryActions"
	secondary.columns = 4
	secondary.add_theme_constant_override("h_separation", 10)
	root.add_child(secondary)
	var actions: Array = [
		["DAILY", Color("ffb84d"), Callable(self, "_open_daily")],
		["LEVELS", accent, Callable(self, "_open_journey")],
		["COLLECTION", PremiumDesignSystem.accent_for_game("block_puzzle"), func(): get_parent().call("build_collection")],
		["LIVE", PremiumDesignSystem.accent_for_game("water_sort"), Callable(self, "_open_live")]
	]
	for action in actions:
		var button := Button.new()
		button.text = String(action[0])
		button.custom_minimum_size = Vector2(0, 74)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)
		PremiumDesignSystem.apply_button(button, _dark(), Color(action[1]), "secondary", 22)
		button.pressed.connect(action[2])
		secondary.add_child(button)

	_add_bottom_nav()

	if MotionSystem.reduced():
		hero.modulate.a = 1.0
		games.modulate.a = 1.0
		return
	hero.modulate.a = 0.86
	games.modulate.a = 0.86
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(hero, "modulate:a", 1.0, 0.20)
	tween.parallel().tween_property(games, "modulate:a", 1.0, 0.24)

func _open_shop() -> void:
	var hub := get_parent().get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		hub.call("open_shop")

func _nav_button(text_value: String, tint: Color, active: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 72)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	PremiumDesignSystem.apply_button(button, _dark(), tint, "primary" if active else "utility", 22)
	return button

func _add_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 30
	nav.offset_right = -30
	nav.offset_bottom = -16
	nav.offset_top = -94
	nav.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color(_card(), 0.98), 28, _border(), _dark(), 8))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	nav.add_child(row)
	var home := _nav_button("⌂  HOME", PremiumDesignSystem.accent_for_game("water_sort"), true)
	row.add_child(home)
	var levels := _nav_button("★  LEVELS", _casual_accent(selected_game))
	levels.pressed.connect(_open_journey)
	row.add_child(levels)
	var collection := _nav_button("✦  COLLECTION", PremiumDesignSystem.accent_for_game("block_puzzle"))
	collection.pressed.connect(func(): get_parent().call("build_collection"))
	row.add_child(collection)
	var settings := _nav_button("⚙  SETTINGS", PremiumDesignSystem.accent_for_game("rescue_rush"))
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	row.add_child(settings)
