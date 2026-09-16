extends "res://scripts/ui/premium_live_hub.gd"

func _button(text_value: String, minimum: Vector2, accent: Color, strong := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 21)
	Unjam3DTheme.gloss_button(button, accent, strong, 26)
	return button

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	built = true
	last_theme = _theme_mode()

	var bg := Unjam3DBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Unjam3DTheme.WATER)
	add_child(bg)

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

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 92)
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var back := _button("←", Vector2(92, 82), Unjam3DTheme.WATER_DARK, true)
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(_go_home)
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var title := Label.new()
	title.text = "CHOOSE A GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.NAVY, 6)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "THREE PUZZLES  •  ONE JOURNEY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	Unjam3DTheme.label_3d(subtitle, Color("e9fbff"), Unjam3DTheme.NAVY, 3)
	titles.add_child(subtitle)
	var settings := _button("⚙", Vector2(92, 82), Unjam3DTheme.WATER_DARK, true)
	settings.add_theme_font_size_override("font_size", 30)
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	header.add_child(settings)

	var wallet := HBoxContainer.new()
	wallet.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet.add_theme_constant_override("separation", 18)
	root.add_child(wallet)
	var coins := Label.new()
	coins.text = "●  %d" % int(SaveManager.data.get("coins", 0))
	coins.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(coins, Unjam3DTheme.GOLD, Unjam3DTheme.NAVY, 3)
	wallet.add_child(coins)
	var stars := Label.new()
	stars.text = "★  %d" % _total_stars()
	stars.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(stars, Color.WHITE, Unjam3DTheme.NAVY, 3)
	wallet.add_child(stars)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 17)
	scroll.add_child(stack)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		_add_game_card(stack, game_id)

	var quote := PanelContainer.new()
	quote.custom_minimum_size = Vector2(0, 92)
	quote.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("d0c8a8"), 30, Color("f2e9bf"), 3, 8))
	stack.add_child(quote)
	var quote_label := Label.new()
	quote_label.text = "Different puzzles.\nA brighter you.  ♥"
	quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quote_label.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.label_3d(quote_label, Color("244279"), Color.WHITE, 2)
	quote.add_child(quote_label)
	_add_bottom_nav()

func _add_game_card(parent: VBoxContainer, game_id: String) -> void:
	var accent := Unjam3DTheme.game_accent(game_id)
	var dark := Unjam3DTheme.game_dark(game_id)
	var progress := MultiGameManager.progress_for(game_id)
	var highest := clampi(int(progress.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var level_in_world := ((highest - 1) % 100) + 1

	var panel := PanelContainer.new()
	panel.name = "GameCard3D_%s" % game_id
	panel.custom_minimum_size = Vector2(0, 350)
	panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(accent, 38, accent.lightened(0.36), 4, 14))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(430, 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 7)
	row.add_child(info)
	var name := Label.new()
	name.text = MultiGameManager.display_name(game_id).to_upper()
	name.add_theme_font_size_override("font_size", 41)
	Unjam3DTheme.label_3d(name, Color.WHITE, dark.darkened(0.34), 6)
	info.add_child(name)
	var desc := Label.new()
	desc.text = _reference_card_copy(game_id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 19)
	Unjam3DTheme.label_3d(desc, Color.WHITE, dark.darkened(0.34), 3)
	info.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(spacer)

	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 76)
	footer.add_theme_constant_override("separation", 10)
	info.add_child(footer)
	var level_chip := PanelContainer.new()
	level_chip.custom_minimum_size = Vector2(120, 62)
	level_chip.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(dark, 22, accent.lightened(0.35), 2, 5))
	footer.add_child(level_chip)
	var level_label := Label.new()
	level_label.text = "LEVEL %d" % highest
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 16)
	Unjam3DTheme.label_3d(level_label, Color.WHITE, dark.darkened(0.35), 2)
	level_chip.add_child(level_label)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "WorldProgress"
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size = Vector2(160, 34)
	progress_bar.max_value = 100.0
	progress_bar.value = float(level_in_world)
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", Unjam3DTheme.panel_3d(dark.darkened(0.16), 16, Color(dark.lightened(0.18), 0.7), 1, 2))
	progress_bar.add_theme_stylebox_override("fill", Unjam3DTheme.panel_3d(Color("42e58a") if game_id == "rescue_rush" else accent.lightened(0.22), 16, Color.WHITE, 1, 3))
	footer.add_child(progress_bar)

	var star_label := Label.new()
	star_label.text = "★ %d" % MultiGameManager.total_stars(game_id)
	star_label.custom_minimum_size = Vector2(92, 62)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(star_label, Color("fff2a0"), dark.darkened(0.38), 3)
	footer.add_child(star_label)
	var play := _button("›", Vector2(68, 68), dark, true)
	play.add_theme_font_size_override("font_size", 38)
	play.pressed.connect(_play.bind(game_id))
	footer.add_child(play)

	var art := Unjam3DGameArt.new()
	art.custom_minimum_size = Vector2(360, 310)
	art.configure(game_id)
	row.add_child(art)

func _reference_card_copy(game_id: String) -> String:
	match game_id:
		"water_sort": return "Sort the colors.\nTrain your mind.\nFind the perfect flow!"
		"block_puzzle": return "Drag. Place. Clear.\nKeep the board tidy!"
		_: return "Clear the lane.\nRescue the chick.\nMake the escape!"

func _add_bottom_nav() -> void:
	var nav := PanelContainer.new()
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
		["⌂\nHOME", Callable(self, "_go_home")],
		["●\nGAMES", Callable()],
		["★\nCOLLECTION", func(): get_parent().call("build_collection")],
		["⚙\nSETTINGS", func(): get_parent().call("build_settings")]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := _button(String(entry[0]), Vector2(0, 78), Unjam3DTheme.WATER if i == 1 else Color("0d6dc2"), i == 1)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		var callback: Callable = entry[1]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)
