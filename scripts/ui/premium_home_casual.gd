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
	bg.configure(_surface(), accent, ["rescue_rush", "water_sort", "block_puzzle"].find(selected_game))
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 22)
	outer.add_theme_constant_override("margin_bottom", 102)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 82)
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)
	logo = UnjamLogo.new()
	logo.custom_minimum_size = Vector2(420, 82)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo.configure(_dark())
	header.add_child(logo)
	var profile := PanelContainer.new()
	profile.custom_minimum_size = Vector2(238, 70)
	profile.add_theme_stylebox_override("panel", _box(Color(_card(), 0.92), 22, _border(), 1))
	header.add_child(profile)
	var profile_label := Label.new()
	profile_label.text = "%d  ◈    %d ★" % [int(SaveManager.data.get("coins", 0)), _total_stars()]
	profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	profile_label.add_theme_font_size_override("font_size", 18)
	profile_label.add_theme_color_override("font_color", Color("ffd166"))
	profile.add_child(profile_label)

	var hero := PanelContainer.new()
	hero.name = "HomeHero"
	hero.custom_minimum_size = Vector2(0, 438)
	hero.add_theme_stylebox_override("panel", _box(Color(_card(), 0.965), 38, Color(accent, 0.42), 2, 14))
	root.add_child(hero)
	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 24)
	hero_margin.add_theme_constant_override("margin_right", 24)
	hero_margin.add_theme_constant_override("margin_top", 16)
	hero_margin.add_theme_constant_override("margin_bottom", 16)
	hero.add_child(hero_margin)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 24)
	hero_margin.add_child(hero_row)

	hero_art = GameShowcaseArt.new()
	hero_art.custom_minimum_size = Vector2(330, 390)
	hero_art.configure(selected_game, accent, _dark())
	hero_row.add_child(hero_art)

	var hero_copy := VBoxContainer.new()
	hero_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_copy.add_theme_constant_override("separation", 8)
	hero_row.add_child(hero_copy)
	var eyebrow := Label.new()
	eyebrow.text = "YOUR NEXT RUN"
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color(accent, 0.92))
	hero_copy.add_child(eyebrow)
	hero_title = Label.new()
	hero_title.text = MultiGameManager.display_name(selected_game).to_upper()
	hero_title.add_theme_font_size_override("font_size", 42)
	hero_title.add_theme_color_override("font_color", _ink())
	hero_copy.add_child(hero_title)
	hero_subtitle = Label.new()
	hero_subtitle.text = SUBTITLES[selected_game]
	hero_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_subtitle.add_theme_font_size_override("font_size", 19)
	hero_subtitle.add_theme_color_override("font_color", _muted())
	hero_copy.add_child(hero_subtitle)
	hero_progress = Label.new()
	hero_progress.text = _hero_progress_text(selected_game)
	hero_progress.add_theme_font_size_override("font_size", 18)
	hero_progress.add_theme_color_override("font_color", Color("d9e5f4") if _dark() else Color("314158"))
	hero_copy.add_child(hero_progress)
	primary_button = _button(_primary_text(selected_game), Vector2(0, 82), accent, true)
	primary_button.name = "HomePrimaryAction"
	primary_button.add_theme_font_size_override("font_size", 24)
	primary_button.pressed.connect(_play_selected)
	hero_copy.add_child(primary_button)

	var section := HBoxContainer.new()
	root.add_child(section)
	var choose := Label.new()
	choose.text = "CHOOSE A GAME"
	choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose.add_theme_font_size_override("font_size", 19)
	choose.add_theme_color_override("font_color", _ink())
	section.add_child(choose)
	footer_label = Label.new()
	footer_label.text = _shared_progress_text()
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer_label.add_theme_font_size_override("font_size", 15)
	footer_label.add_theme_color_override("font_color", _muted())
	section.add_child(footer_label)

	var games := HBoxContainer.new()
	games.alignment = BoxContainer.ALIGNMENT_CENTER
	games.add_theme_constant_override("separation", 10)
	root.add_child(games)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var tile := GameSelectTile.new()
		tile.custom_minimum_size = Vector2(0, 176)
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
		var button := _button(String(action[0]), Vector2(0, 68), Color(action[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(action[2])
		secondary.add_child(button)

	_add_bottom_nav()

	if not is_instance_valid(hero):
		return
	hero.modulate.a = 0.82
	games.modulate.a = 0.84
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(hero, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(games, "modulate:a", 1.0, 0.22)

func _add_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 34
	nav.offset_right = -34
	nav.offset_bottom = -18
	nav.offset_top = -92
	nav.add_theme_stylebox_override("panel", _box(Color(_card(), 0.98), 26, _border(), 1, 8))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	nav.add_child(row)
	var entries: Array = [
		["⌂  HOME", PremiumDesignSystem.accent_for_game("water_sort"), Callable()],
		["●  LIVE", PremiumDesignSystem.accent_for_game("water_sort"), Callable(self, "_open_live")],
		["★  COLLECTION", PremiumDesignSystem.accent_for_game("block_puzzle"), func(): get_parent().call("build_collection")],
		["⚙  SETTINGS", PremiumDesignSystem.accent_for_game("rescue_rush"), func(): get_parent().call("build_settings")]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := _button(String(entry[0]), Vector2(0, 64), Color(entry[1]), i == 0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		var callback: Callable = entry[2]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)
