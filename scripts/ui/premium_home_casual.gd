extends "res://scripts/ui/premium_home_overhaul.gd"

# UNJAM 3D visual reboot.
# This home screen intentionally does not use the retired PremiumBackdrop,
# GameShowcaseArt or UnjamLogo renderers. It is rebuilt from the reference
# direction: bright fantasy scenery, chunky depth, glossy controls and a
# friendly central mascot.

func build_home_launcher() -> void:
	for child in get_children():
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var accent := Unjam3DTheme.game_accent(selected_game)

	var backdrop := Unjam3DBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(accent)
	add_child(backdrop)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_bottom", 118)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	outer.add_child(root)

	_make_status_bar(root)
	_make_brand_logo(root)
	_make_tagline(root)
	_make_hero(root, accent)

	primary_button = Button.new()
	primary_button.name = "HomePrimaryAction"
	primary_button.text = "▶   PLAY"
	primary_button.custom_minimum_size = Vector2(0, 118)
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button.add_theme_font_size_override("font_size", 43)
	Unjam3DTheme.gloss_button(primary_button, Unjam3DTheme.GREEN, true, 42)
	primary_button.pressed.connect(_play_selected)
	root.add_child(primary_button)

	var play_hint := Label.new()
	play_hint.text = "START THE JOURNEY   •   %s" % _hero_progress_text(selected_game)
	play_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_hint.add_theme_font_size_override("font_size", 17)
	Unjam3DTheme.label_3d(play_hint, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(play_hint)

	var choose_row := HBoxContainer.new()
	root.add_child(choose_row)
	var choose := Label.new()
	choose.text = "CHOOSE A GAME"
	choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose.add_theme_font_size_override("font_size", 25)
	Unjam3DTheme.label_3d(choose, Color.WHITE, Unjam3DTheme.NAVY, 4)
	choose_row.add_child(choose)
	footer_label = Label.new()
	footer_label.text = _shared_progress_text()
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer_label.add_theme_font_size_override("font_size", 16)
	Unjam3DTheme.label_3d(footer_label, Color.WHITE, Unjam3DTheme.NAVY, 3)
	choose_row.add_child(footer_label)

	var games := GridContainer.new()
	games.columns = 3
	games.add_theme_constant_override("h_separation", 12)
	root.add_child(games)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var card := _make_game_card(game_id)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		games.add_child(card)

	_make_bottom_nav()
	_animate_entry(root)

func _make_status_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 74)
	bar.add_theme_constant_override("separation", 10)
	parent.add_child(bar)
	var cleared := 0
	for game_id in MultiGameManager.GAME_IDS:
		cleared += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	var player_level := maxi(1, 1 + cleared / 10)
	bar.add_child(_make_badge("☺  LV %d" % player_level, Unjam3DTheme.WATER))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	bar.add_child(_make_badge("●  %s" % _compact_number(int(SaveManager.data.get("coins", 0))), Unjam3DTheme.ORANGE))
	bar.add_child(_make_badge("★  %s" % _compact_number(_total_stars()), Unjam3DTheme.GOLD))

func _make_badge(text_value: String, fill: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(188, 66)
	badge.add_theme_stylebox_override("panel", Unjam3DTheme.badge(fill, 26))
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	Unjam3DTheme.label_3d(label, Color.WHITE, fill.darkened(0.45), 3)
	badge.add_child(label)
	return badge

func _make_brand_logo(parent: VBoxContainer) -> void:
	var logo_box := VBoxContainer.new()
	logo_box.custom_minimum_size = Vector2(0, 192)
	logo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_box.add_theme_constant_override("separation", 0)
	parent.add_child(logo_box)
	var letters := HBoxContainer.new()
	letters.alignment = BoxContainer.ALIGNMENT_CENTER
	letters.add_theme_constant_override("separation", -9)
	logo_box.add_child(letters)
	var palette := [Color("ffd52b"), Color("ff8c21"), Color("ff4b83"), Color("ce48ff"), Color("25b7ff")]
	var text := "UNJAM"
	for i in range(text.length()):
		var label := Label.new()
		label.text = text.substr(i, 1)
		label.add_theme_font_size_override("font_size", 110)
		label.custom_minimum_size = Vector2(145, 132)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		Unjam3DTheme.label_3d(label, palette[i], Color("084b94"), 9)
		letters.add_child(label)
	var subtitle := Label.new()
	subtitle.text = "THREE PUZZLES  •  ONE JOURNEY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	Unjam3DTheme.label_3d(subtitle, Color.WHITE, Unjam3DTheme.NAVY, 4)
	logo_box.add_child(subtitle)

func _make_tagline(parent: VBoxContainer) -> void:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(0, 62)
	pill.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("c76a25"), 26, Color("ffcf77"), 2, 7))
	parent.add_child(pill)
	var label := Label.new()
	label.text = "PUZZLE  •  RELAX  •  BRIGHTER DAYS ♥"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(label, Color.WHITE, Color("73310f"), 3)
	pill.add_child(label)

func _make_hero(parent: VBoxContainer, accent: Color) -> void:
	var hero := PanelContainer.new()
	hero.name = "HomeHero3D"
	hero.custom_minimum_size = Vector2(0, 520)
	hero.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.84, 0.97, 1.0, 0.23), 42, Color(1, 1, 1, 0.70), 3, 12))
	parent.add_child(hero)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 20)
	hero.add_child(hero_row)

	var message := VBoxContainer.new()
	message.custom_minimum_size = Vector2(330, 0)
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.alignment = BoxContainer.ALIGNMENT_CENTER
	message.add_theme_constant_override("separation", 9)
	hero_row.add_child(message)
	var small := Label.new()
	small.text = "SMALL PUZZLES"
	small.add_theme_font_size_override("font_size", 22)
	Unjam3DTheme.label_3d(small, Color.WHITE, Unjam3DTheme.NAVY, 4)
	message.add_child(small)
	var bright := Label.new()
	bright.text = "BRIGHTER\nDAYS ♥"
	bright.add_theme_font_size_override("font_size", 38)
	bright.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Unjam3DTheme.label_3d(bright, Color("fff7d6"), Color("713170"), 5)
	message.add_child(bright)

	var mascot := Unjam3DMascot.new()
	mascot.custom_minimum_size = Vector2(430, 470)
	mascot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mascot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_row.add_child(mascot)

	var selection := VBoxContainer.new()
	selection.custom_minimum_size = Vector2(260, 0)
	selection.alignment = BoxContainer.ALIGNMENT_CENTER
	selection.add_theme_constant_override("separation", 8)
	hero_row.add_child(selection)
	var selected_label := Label.new()
	selected_label.text = MultiGameManager.display_name(selected_game).to_upper()
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_label.add_theme_font_size_override("font_size", 27)
	Unjam3DTheme.label_3d(selected_label, Color.WHITE, Unjam3DTheme.game_dark(selected_game), 4)
	selection.add_child(selected_label)
	var mini := Unjam3DGameArt.new()
	mini.custom_minimum_size = Vector2(250, 250)
	mini.configure(selected_game)
	selection.add_child(mini)
	var level := Label.new()
	level.text = "LEVEL %d" % _current_level(selected_game)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.add_theme_font_size_override("font_size", 19)
	Unjam3DTheme.label_3d(level, accent.lightened(0.28), Unjam3DTheme.game_dark(selected_game), 3)
	selection.add_child(level)

func _make_game_card(game_id: String) -> Button:
	var accent := Unjam3DTheme.game_accent(game_id)
	var button := Button.new()
	button.name = "GameCard_%s" % game_id
	button.custom_minimum_size = Vector2(0, 292)
	button.clip_contents = true
	button.text = ""
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.game_dark(game_id), true, 32)
	button.pressed.connect(_choose_game.bind(game_id))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10)
	button.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var art := Unjam3DGameArt.new()
	art.custom_minimum_size = Vector2(0, 190)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.configure(game_id)
	box.add_child(art)
	var title := Label.new()
	title.text = MultiGameManager.display_name(game_id).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.game_dark(game_id).darkened(0.35), 3)
	box.add_child(title)
	var detail := Label.new()
	detail.text = "LV %d   ★ %d" % [_current_level(game_id), MultiGameManager.total_stars(game_id)]
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 15)
	Unjam3DTheme.label_3d(detail, accent.lightened(0.34), Unjam3DTheme.game_dark(game_id).darkened(0.42), 2)
	box.add_child(detail)
	return button

func _choose_game(game_id: String) -> void:
	selected_game = game_id
	var main := get_parent()
	if main != null:
		main.set("selected_game_id", game_id)
	FeedbackManager.tap()
	build_home_launcher()

func _make_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.name = "HomeBottomNav3D"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 28
	nav.offset_right = -28
	nav.offset_top = -108
	nav.offset_bottom = -16
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("0756a8"), 30, Color("56c8ff"), 3, 10))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	nav.add_child(row)
	var entries: Array = [
		["⌂\nHOME", Callable()],
		["★\nLEVELS", Callable(self, "_open_journey")],
		["♥\nCOLLECTION", func(): get_parent().call("build_collection")],
		["⚙\nSETTINGS", func(): get_parent().call("build_settings")]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := Button.new()
		button.text = String(entry[0])
		button.custom_minimum_size = Vector2(0, 78)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		Unjam3DTheme.gloss_button(button, Unjam3DTheme.WATER if i == 0 else Color("0d6dc2"), i == 0, 22)
		var callback: Callable = entry[1]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)

func _animate_entry(root: Control) -> void:
	if MotionSystem.reduced():
		root.modulate = Color.WHITE
		return
	root.modulate.a = 0.72
	root.position.y = 18.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 1.0, 0.20)
	tween.parallel().tween_property(root, "position:y", 0.0, 0.28)

func _compact_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)
