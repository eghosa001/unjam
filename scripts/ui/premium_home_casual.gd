extends "res://scripts/ui/premium_home_overhaul.gd"

# VIBRANT_REFERENCE_TARGET
# Bright world backdrop, oversized hero, full-width play CTA, colorful game
# shelf and compact navigation. Avoid large inactive gutters or dark empty panels.

func _ink() -> Color:
	return PremiumDesignSystem.ink(_dark())

func _muted() -> Color:
	return PremiumDesignSystem.muted(_dark())

func _surface() -> Color:
	return PremiumDesignSystem.surface(_dark())

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
	var game_gradient: Array[Color] = PremiumDesignSystem.game_gradient(selected_game)

	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(PremiumDesignSystem.vibrant_canvas(selected_game), accent, ["rescue_rush", "water_sort", "block_puzzle"].find(selected_game))
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 14)
	outer.add_theme_constant_override("margin_right", 14)
	outer.add_theme_constant_override("margin_top", 12)
	outer.add_theme_constant_override("margin_bottom", 100)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 80)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	logo = UnjamLogo.new()
	logo.custom_minimum_size = Vector2(430, 80)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo.configure(false)
	header.add_child(logo)
	var profile := PanelContainer.new()
	profile.custom_minimum_size = Vector2(250, 70)
	profile.add_theme_stylebox_override("panel", _box(Color("ffffff", 0.90), 24, Color(accent, 0.62), 2, 8))
	header.add_child(profile)
	var profile_label := Label.new()
	profile_label.text = "◈ %d     ★ %d" % [int(SaveManager.data.get("coins", 0)), _total_stars()]
	profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	profile_label.add_theme_font_size_override("font_size", 19)
	profile_label.add_theme_color_override("font_color", Color("244365"))
	profile.add_child(profile_label)

	var feature_strip := HBoxContainer.new()
	feature_strip.name = "HomeFeatureStrip"
	feature_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	feature_strip.add_theme_constant_override("separation", 8)
	root.add_child(feature_strip)
	var feature_data: Array = [
		["🔥 STREAK %d" % int(SaveManager.data.get("daily_streak", 0)), Color("ff7b55")],
		["🏆 %d CLEARED" % _completed_levels(), Color("ffcf3f")],
		["✨ PUZZLE EXPLORER", Color("7d63ff")]
	]
	for item in feature_data:
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size = Vector2(0, 50)
		chip.add_theme_stylebox_override("panel", _box(Color("ffffff", 0.86), 18, Color(item[1], 0.72), 2, 4))
		var chip_label := Label.new()
		chip_label.text = String(item[0])
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_label.add_theme_font_size_override("font_size", 15)
		chip_label.add_theme_color_override("font_color", Color("244365"))
		chip.add_child(chip_label)
		feature_strip.add_child(chip)

	var hero := PanelContainer.new()
	hero.name = "HomeHero"
	hero.custom_minimum_size = Vector2(0, 760)
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.add_theme_stylebox_override("panel", _box(Color(game_gradient[0], 0.88), 40, Color("ffffff", 0.72), 3, 16))
	root.add_child(hero)
	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 18)
	hero_margin.add_theme_constant_override("margin_right", 18)
	hero_margin.add_theme_constant_override("margin_top", 14)
	hero_margin.add_theme_constant_override("margin_bottom", 14)
	hero.add_child(hero_margin)
	var hero_row := VBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 8)
	hero_margin.add_child(hero_row)

	var banner := Label.new()
	banner.text = "THREE PUZZLES • ONE JOURNEY"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 18)
	banner.add_theme_color_override("font_color", Color("ffffff"))
	banner.add_theme_color_override("font_shadow_color", Color(0.04, 0.12, 0.24, 0.35))
	banner.add_theme_constant_override("shadow_offset_y", 2)
	hero_row.add_child(banner)

	hero_art = GameShowcaseArt.new()
	hero_art.name = "HomeShowcaseArt"
	hero_art.custom_minimum_size = Vector2(0, 500)
	hero_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_art.configure(selected_game, accent, false)
	hero_row.add_child(hero_art)

	var hero_copy := VBoxContainer.new()
	hero_copy.custom_minimum_size = Vector2(0, 190)
	hero_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_copy.add_theme_constant_override("separation", 4)
	hero_row.add_child(hero_copy)
	hero_title = Label.new()
	hero_title.text = MultiGameManager.display_name(selected_game).to_upper()
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_size_override("font_size", 42)
	hero_title.add_theme_color_override("font_color", Color.WHITE)
	hero_title.add_theme_color_override("font_shadow_color", Color(0.04, 0.10, 0.20, 0.40))
	hero_title.add_theme_constant_override("shadow_offset_y", 3)
	hero_copy.add_child(hero_title)
	hero_subtitle = Label.new()
	hero_subtitle.text = SUBTITLES[selected_game]
	hero_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_subtitle.add_theme_font_size_override("font_size", 19)
	hero_subtitle.add_theme_color_override("font_color", Color("f6fdff"))
	hero_copy.add_child(hero_subtitle)
	hero_progress = Label.new()
	hero_progress.text = _hero_progress_text(selected_game)
	hero_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_progress.add_theme_font_size_override("font_size", 17)
	hero_progress.add_theme_color_override("font_color", Color("fff4a8"))
	hero_copy.add_child(hero_progress)
	primary_button = _button(_primary_text(selected_game), Vector2(0, 96), Color("31e575"), true)
	primary_button.name = "HomePrimaryAction"
	primary_button.add_theme_font_size_override("font_size", 27)
	primary_button.pressed.connect(_play_selected)
	hero_copy.add_child(primary_button)

	var section := HBoxContainer.new()
	root.add_child(section)
	var choose := Label.new()
	choose.text = "OUR GAMES"
	choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose.add_theme_font_size_override("font_size", 21)
	choose.add_theme_color_override("font_color", Color("153b5b"))
	section.add_child(choose)
	footer_label = Label.new()
	footer_label.text = _shared_progress_text()
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer_label.add_theme_font_size_override("font_size", 15)
	footer_label.add_theme_color_override("font_color", Color("355d79"))
	section.add_child(footer_label)

	var games := HBoxContainer.new()
	games.name = "HomeGameShelf"
	games.alignment = BoxContainer.ALIGNMENT_CENTER
	games.add_theme_constant_override("separation", 8)
	root.add_child(games)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var tile := GameSelectTile.new()
		tile.custom_minimum_size = Vector2(0, 224)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.configure(game_id, MultiGameManager.display_name(game_id).to_upper(), _current_level(game_id), _casual_accent(game_id), game_id == selected_game, false)
		tile.chosen.connect(_select_game)
		games.add_child(tile)

	var secondary := GridContainer.new()
	secondary.name = "HomeSecondaryActions"
	secondary.columns = 4
	secondary.add_theme_constant_override("h_separation", 8)
	root.add_child(secondary)
	var actions: Array = [
		["DAILY", Color("ffad36"), Callable(self, "_open_daily")],
		["LEVELS", Color("18b7ff"), Callable(self, "_open_journey")],
		["COLLECTION", Color("bd4cff"), func(): get_parent().call("build_collection")],
		["LIVE", Color("12d3aa"), Callable(self, "_open_live")]
	]
	for action in actions:
		var button := _button(String(action[0]), Vector2(0, 68), Color(action[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(action[2])
		secondary.add_child(button)

	_add_bottom_nav()
	if MotionSystem.reduced():
		hero.modulate.a = 1.0
		games.modulate.a = 1.0
		return
	hero.modulate.a = 0.82
	games.modulate.a = 0.84
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(hero, "modulate:a", 1.0, MotionSystem.duration(&"screen"))
	tween.parallel().tween_property(games, "modulate:a", 1.0, MotionSystem.duration(&"travel"))

func _completed_levels() -> int:
	var completed := 0
	for game_id in MultiGameManager.GAME_IDS:
		completed += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	return completed

func _open_shop() -> void:
	var hub := get_parent().get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		hub.call("open_shop")

func _add_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 14
	nav.offset_right = -14
	nav.offset_bottom = -10
	nav.offset_top = -88
	nav.add_theme_stylebox_override("panel", _box(Color("ffffff", 0.94), 26, Color("38aaf5", 0.55), 2, 10))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	nav.add_child(row)
	var entries: Array = [
		["⌂  HOME", Color("16a9ff"), Callable()],
		["●  LIVE", Color("10cfa8"), Callable(self, "_open_live")],
		["SHOP", Color("8f55ff"), Callable(self, "_open_shop")],
		["★  COLLECTION", Color("ec4ac8"), func(): get_parent().call("build_collection")],
		["⚙  SETTINGS", Color("ff9f32"), func(): get_parent().call("build_settings")]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := _button(String(entry[0]), Vector2(0, 58), Color(entry[1]), i == 0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		var callback: Callable = entry[2]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)
