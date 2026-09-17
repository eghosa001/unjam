extends "res://scripts/ui/premium_live_hub.gd"

func _button(text_value: String, minimum: Vector2, accent: Color, strong := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 21)
	Unjam3DTheme.gloss_button(button, accent, strong, 26, _theme_mode() == "dark")
	return button

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	built = true
	last_theme = _theme_mode()

	clip_contents = true
	var dark_mode := _theme_mode() == "dark"
	var bg := Unjam3DBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Unjam3DTheme.WATER, dark_mode)
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport_rect().size
	var narrow := viewport_size.x < 900.0
	outer.add_theme_constant_override("margin_left", 20 if viewport_size.x < 600.0 else 34)
	outer.add_theme_constant_override("margin_right", 20 if viewport_size.x < 600.0 else 34)
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
	quote.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("26334a") if dark_mode else Color("d0c8a8"), 30, Color("f2e9bf"), 3, 8))
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

	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 900.0
	var card_height := (570.0 if viewport_size.y >= 1200.0 else 500.0) if compact else clampf(viewport_size.y * 0.217, 340.0, 520.0)
	var panel := PanelContainer.new()
	panel.name = "GameCard3D_%s" % game_id
	panel.custom_minimum_size = Vector2(0, card_height)
	panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(accent.darkened(0.42) if _theme_mode() == "dark" else accent.lightened(0.025), 38, accent.lightened(0.42), 4, 18))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
	row.add_theme_constant_override("separation", 12 if compact else 16)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(0 if compact else 430, 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 7)
	row.add_child(info)
	var name := Label.new()
	name.text = MultiGameManager.display_name(game_id).to_upper()
	name.add_theme_font_size_override("font_size", 34 if compact else 44)
	Unjam3DTheme.label_3d(name, Color.WHITE, dark.darkened(0.34), 6)
	info.add_child(name)
	var desc := Label.new()
	desc.text = _reference_card_copy(game_id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 18 if compact else 23)
	Unjam3DTheme.label_3d(desc, Color.WHITE, dark.darkened(0.34), 3)
	info.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(spacer)

	var footer: Container
	if compact:
		var grid_footer := GridContainer.new()
		grid_footer.columns = 2
		grid_footer.custom_minimum_size = Vector2(0, 126)
		grid_footer.add_theme_constant_override("h_separation", 8)
		grid_footer.add_theme_constant_override("v_separation", 8)
		footer = grid_footer
	else:
		var row_footer := HBoxContainer.new()
		row_footer.custom_minimum_size = Vector2(0, 76)
		row_footer.add_theme_constant_override("separation", 10)
		footer = row_footer
	info.add_child(footer)
	var level_chip := PanelContainer.new()
	level_chip.custom_minimum_size = Vector2(0 if compact else 120, 56 if compact else 62)
	level_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	progress_bar.custom_minimum_size = Vector2(0 if compact else 160, 34)
	progress_bar.max_value = 100.0
	progress_bar.value = float(level_in_world)
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", Unjam3DTheme.panel_3d(dark.darkened(0.16), 16, Color(dark.lightened(0.18), 0.7), 1, 2))
	progress_bar.add_theme_stylebox_override("fill", Unjam3DTheme.panel_3d(Color("42e58a") if game_id == "rescue_rush" else accent.lightened(0.22), 16, Color.WHITE, 1, 3))
	footer.add_child(progress_bar)

	var star_label := Label.new()
	star_label.text = "★ %d" % MultiGameManager.total_stars(game_id)
	star_label.custom_minimum_size = Vector2(0 if compact else 92, 56 if compact else 62)
	star_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(star_label, Color("fff2a0"), dark.darkened(0.38), 3)
	footer.add_child(star_label)
	var play := _button("PLAY  ›", Vector2(0 if compact else 124, 60 if compact else 68), dark, true)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.add_theme_font_size_override("font_size", 22)
	play.pressed.connect(_play.bind(game_id))
	footer.add_child(play)

	var art_shell := PanelContainer.new()
	art_shell.name = "GameArtShell_%s" % game_id
	art_shell.custom_minimum_size = Vector2(0 if compact else 370, 205 if compact else 312)
	art_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_shell.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(1, 1, 1, 0.16), 30, Color(1, 1, 1, 0.48), 2, 10))
	row.add_child(art_shell)
	var art_margin := MarginContainer.new()
	art_margin.add_theme_constant_override("margin_left", 8)
	art_margin.add_theme_constant_override("margin_right", 8)
	art_margin.add_theme_constant_override("margin_top", 6)
	art_margin.add_theme_constant_override("margin_bottom", 6)
	art_shell.add_child(art_margin)
	var art := Unjam3DGameArt.new()
	art.custom_minimum_size = Vector2(0 if compact else 340, 190 if compact else 294)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.configure(game_id)
	art_margin.add_child(art)

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
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("071a35") if _theme_mode() == "dark" else Color("0756a8"), 30, Color("56c8ff"), 3, 10))
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
