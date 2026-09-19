extends "res://scripts/ui/premium_live_hub.gd"

# Premium game selector. Visual hierarchy only: game launch/navigation contracts,
# progression data and all gameplay motion systems remain unchanged.

func _button(text_value: String, minimum: Vector2, accent: Color, strong := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 25)
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
	var viewport_size := get_viewport_rect().size
	var narrow := viewport_size.x < 600.0
	var phone_width := viewport_size.x <= 1120.0
	var compact := viewport_size.x <= 1120.0
	var short := viewport_size.y < 1100.0
	var medium_height := viewport_size.y < 1500.0
	var nav_height := 86.0 if short else (94.0 if medium_height else 102.0)
	var nav_bottom := 10.0 if short else 16.0
	var nav_side := 12.0 if narrow else (20.0 if phone_width else 28.0)
	var nav_reserve := nav_height + nav_bottom + (12.0 if short else 20.0)

	var bg := Unjam3DBackdrop.new()
	bg.name = "GameSelectorBackdrop"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Unjam3DTheme.WATER, dark_mode)
	add_child(bg)

	var outer := MarginContainer.new()
	outer.name = "GameSelectorOuter"
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 12 if narrow else (20 if phone_width else 34))
	outer.add_theme_constant_override("margin_right", 12 if narrow else (20 if phone_width else 34))
	outer.add_theme_constant_override("margin_top", 10 if short else (18 if medium_height else 28))
	outer.add_theme_constant_override("margin_bottom", int(nav_reserve))
	add_child(outer)

	var root := VBoxContainer.new()
	root.name = "GameSelectorRoot"
	root.add_theme_constant_override("separation", 6 if short else (9 if medium_height else 14))
	outer.add_child(root)

	_make_selector_header(root, narrow, phone_width, short, medium_height)
	_make_selector_wallet(root, narrow, short)

	var scroll := ScrollContainer.new()
	scroll.name = "GameSelectorScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(scroll)

	var stack := VBoxContainer.new()
	stack.name = "GameSelectorStack"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10 if short else (14 if medium_height else 18))
	scroll.add_child(stack)

	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		_add_game_card(stack, game_id)

	if not short:
		var quote := PanelContainer.new()
		quote.name = "GameSelectorQuote"
		quote.custom_minimum_size = Vector2(0, 72 if medium_height else 86)
		quote.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("26334a") if dark_mode else Color(0.94, 0.98, 1.0, 0.94), 28, Color("d8f3ff"), 3, 8))
		stack.add_child(quote)
		var quote_label := Label.new()
		quote_label.text = "PLAY YOUR WAY  •  MASTER ALL THREE WORLDS  ♥"
		quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quote_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quote_label.add_theme_font_size_override("font_size", 22 if narrow else 24)
		Unjam3DTheme.label_3d(quote_label, Color("eef7ff") if dark_mode else Color("244279"), Color("071426") if dark_mode else Color.WHITE, 2)
		quote.add_child(quote_label)

	_add_bottom_nav(nav_height, nav_bottom, nav_side)

func _make_selector_header(parent: VBoxContainer, narrow: bool, phone_width: bool, short: bool, medium_height: bool) -> void:
	var header := HBoxContainer.new()
	header.name = "GameSelectorHeader"
	header.custom_minimum_size = Vector2(0, 84 if short else (94 if medium_height else 106))
	header.add_theme_constant_override("separation", 6 if narrow else (8 if phone_width else 12))
	parent.add_child(header)

	var side_button_size := Vector2(72, 82) if short else (Vector2(78, 90) if phone_width else Vector2(92, 96))
	var back := _button("←", side_button_size, Unjam3DTheme.WATER_DARK, true)
	back.name = "GameSelectorBack"
	back.add_theme_font_size_override("font_size", 30)
	back.pressed.connect(_go_home)
	header.add_child(back)

	var titles := VBoxContainer.new()
	titles.name = "GameSelectorTitles"
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.clip_contents = true
	titles.add_theme_constant_override("separation", 0 if short else 2)
	header.add_child(titles)

	var title := Label.new()
	title.name = "GameSelectorTitle"
	title.text = "PICK YOUR PUZZLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 29 if narrow else (35 if phone_width else 42))
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.NAVY, 4 if phone_width else 5)
	titles.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "GameSelectorSubtitle"
	subtitle.text = "YOUR PROGRESS IS SAVED IN EVERY WORLD"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.clip_text = true
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle.add_theme_font_size_override("font_size", 18 if narrow else (21 if phone_width else 24))
	Unjam3DTheme.label_3d(subtitle, Color("e9fbff"), Unjam3DTheme.NAVY, 2)
	titles.add_child(subtitle)

	var settings := _button("⚙", side_button_size, Unjam3DTheme.WATER_DARK, true)
	settings.name = "GameSelectorSettings"
	settings.add_theme_font_size_override("font_size", 28)
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	header.add_child(settings)

func _make_selector_wallet(parent: VBoxContainer, narrow: bool, short: bool) -> void:
	var wallet := HBoxContainer.new()
	wallet.name = "GameSelectorWallet"
	wallet.custom_minimum_size.y = 44.0 if short else 54.0
	wallet.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet.add_theme_constant_override("separation", 10 if narrow else 16)
	parent.add_child(wallet)

	var coins := Label.new()
	coins.text = "●  %d COINS" % int(SaveManager.data.get("coins", 0))
	coins.add_theme_font_size_override("font_size", 20 if narrow else 24)
	Unjam3DTheme.label_3d(coins, Unjam3DTheme.GOLD, Unjam3DTheme.NAVY, 2)
	wallet.add_child(coins)

	var divider := Label.new()
	divider.text = "•"
	divider.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.label_3d(divider, Color("d9f5ff"), Unjam3DTheme.NAVY, 2)
	wallet.add_child(divider)

	var stars := Label.new()
	stars.text = "★  %d STARS" % _total_stars()
	stars.add_theme_font_size_override("font_size", 20 if narrow else 24)
	Unjam3DTheme.label_3d(stars, Color.WHITE, Unjam3DTheme.NAVY, 2)
	wallet.add_child(stars)

func _add_game_card(parent: VBoxContainer, game_id: String) -> void:
	var accent := Unjam3DTheme.game_accent(game_id)
	var dark := Unjam3DTheme.game_dark(game_id)
	var progress := MultiGameManager.progress_for(game_id)
	var highest := clampi(int(progress.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var level_in_world := ((highest - 1) % 100) + 1
	var world := MultiGameManager.world_for_game_level(game_id, highest)

	var viewport_size := get_viewport_rect().size
	var narrow := viewport_size.x < 600.0
	var compact := viewport_size.x <= 1120.0
	var short := viewport_size.y < 1100.0
	var medium_height := viewport_size.y < 1500.0
	var card_height := 352.0 if short else (420.0 if medium_height else 470.0)
	if not compact:
		card_height = clampf(viewport_size.y * 0.215, 340.0, 490.0)

	var panel := PanelContainer.new()
	panel.name = "GameCard3D_%s" % game_id
	panel.custom_minimum_size = Vector2(0, card_height)
	var fill := accent.darkened(0.44) if _theme_mode() == "dark" else accent.lightened(0.04)
	panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(fill, 30 if compact else 38, accent.lightened(0.42), 4, 18))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	var side_margin := 10 if narrow else (14 if compact else 20)
	margin.add_theme_constant_override("margin_left", side_margin)
	margin.add_theme_constant_override("margin_right", side_margin)
	margin.add_theme_constant_override("margin_top", 10 if short else 14)
	margin.add_theme_constant_override("margin_bottom", 10 if short else 14)
	panel.add_child(margin)

	var composition: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
	composition.add_theme_constant_override("separation", 8 if short else (12 if compact else 18))
	margin.add_child(composition)

	var art_shell := _make_game_art_shell(game_id, compact, short, medium_height, card_height)
	var info := _make_game_info(game_id, highest, world, level_in_world, compact, narrow, short, accent, dark)

	# On phones the artwork leads the card, like a premium casual-game poster.
	# Wide layouts use text left / artwork right for faster scanning.
	if compact:
		composition.add_child(art_shell)
		composition.add_child(info)
	else:
		composition.add_child(info)
		composition.add_child(art_shell)

func _make_game_art_shell(game_id: String, compact: bool, short: bool, medium_height: bool, card_height: float) -> PanelContainer:
	var art_shell := PanelContainer.new()
	art_shell.name = "GameArtShell_%s" % game_id
	var art_height := 118.0 if short else (154.0 if medium_height else 182.0)
	art_shell.custom_minimum_size = Vector2(0 if compact else 360, art_height if compact else minf(card_height - 30.0, 310.0))
	art_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_shell.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(1, 1, 1, 0.18), 24 if compact else 30, Color(1, 1, 1, 0.54), 3, 10))

	var art_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		art_margin.add_theme_constant_override("margin_%s" % side, 6)
	art_shell.add_child(art_margin)

	var art := Unjam3DGameArt.new()
	art.custom_minimum_size = Vector2(0 if compact else 340, maxf(96.0, art_shell.custom_minimum_size.y - 12.0))
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.configure(game_id)
	art_margin.add_child(art)
	return art_shell

func _make_game_info(game_id: String, highest: int, world: int, level_in_world: int, compact: bool, narrow: bool, short: bool, accent: Color, dark: Color) -> VBoxContainer:
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(0 if compact else 410, 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3 if short else 6)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	info.add_child(heading)

	var name := Label.new()
	name.text = MultiGameManager.display_name(game_id).to_upper()
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 29 if narrow else (34 if compact else 44))
	Unjam3DTheme.label_3d(name, Color.WHITE, dark.darkened(0.34), 4 if compact else 5)
	heading.add_child(name)

	var world_label := Label.new()
	world_label.text = "WORLD %d" % world
	world_label.add_theme_font_size_override("font_size", 18 if narrow else 21)
	Unjam3DTheme.label_3d(world_label, Color("fff2a0"), dark.darkened(0.34), 2)
	heading.add_child(world_label)

	var desc := Label.new()
	desc.text = _reference_card_copy(game_id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 22 if narrow else (24 if compact else 26))
	Unjam3DTheme.label_3d(desc, Color.WHITE, dark.darkened(0.34), 2)
	info.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(spacer)

	var footer: Container = GridContainer.new() if compact else HBoxContainer.new()
	if footer is GridContainer:
		(footer as GridContainer).columns = 2
	footer.custom_minimum_size = Vector2(0, 92 if short else (104 if compact else 72))
	footer.add_theme_constant_override("h_separation", 7)
	footer.add_theme_constant_override("v_separation", 7)
	info.add_child(footer)

	var footer_height := 54.0 if short else (62.0 if compact else 70.0)
	var level_chip := PanelContainer.new()
	level_chip.custom_minimum_size = Vector2(0 if compact else 118, footer_height)
	level_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_chip.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(dark, 18 if compact else 22, accent.lightened(0.35), 2, 4))
	footer.add_child(level_chip)

	var level_label := Label.new()
	level_label.text = "LEVEL %d" % highest
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 20 if narrow else 23)
	Unjam3DTheme.label_3d(level_label, Color.WHITE, dark.darkened(0.35), 2)
	level_chip.add_child(level_label)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "WorldProgress"
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size = Vector2(0 if compact else 160, 24 if short else 30)
	progress_bar.max_value = 100.0
	progress_bar.value = float(level_in_world)
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", Unjam3DTheme.panel_3d(dark.darkened(0.16), 12, Color(dark.lightened(0.18), 0.7), 1, 2))
	progress_bar.add_theme_stylebox_override("fill", Unjam3DTheme.panel_3d(Color("42e58a") if game_id == "rescue_rush" else accent.lightened(0.22), 12, Color.WHITE, 1, 3))
	footer.add_child(progress_bar)

	var star_label := Label.new()
	star_label.text = "★ %d" % MultiGameManager.total_stars(game_id)
	star_label.custom_minimum_size = Vector2(0 if compact else 88, footer_height)
	star_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 20 if narrow else 23)
	Unjam3DTheme.label_3d(star_label, Color("fff2a0"), dark.darkened(0.38), 2)
	footer.add_child(star_label)

	var play := _button("PLAY  ›", Vector2(0 if compact else 128, footer_height), dark, true)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.add_theme_font_size_override("font_size", 22 if narrow else 26)
	play.pressed.connect(_play.bind(game_id))
	footer.add_child(play)
	return info

func _reference_card_copy(game_id: String) -> String:
	match game_id:
		"water_sort": return "Sort the colors. Find the perfect flow."
		"block_puzzle": return "Drag. Place. Clear. Build satisfying combos."
		_: return "Clear the lane. Rescue the chick. Make the escape."

func _add_bottom_nav(nav_height: float = 92.0, nav_bottom: float = 16.0, nav_side: float = 28.0) -> void:
	var nav := PanelContainer.new()
	nav.name = "GameSelectorBottomNav"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = nav_side
	nav.offset_right = -nav_side
	nav.offset_top = -(nav_height + nav_bottom)
	nav.offset_bottom = -nav_bottom
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("071a35") if _theme_mode() == "dark" else Color("0756a8"), 24 if nav_height < 90.0 else 30, Color("56c8ff"), 3, 10))
	add_child(nav)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4 if get_viewport_rect().size.x < 600.0 else 8)
	nav.add_child(row)

	var entries: Array = [
		["⌂\nHOME", Callable(self, "_go_home")],
		["●\nGAMES", Callable()],
		["☀\nDAILY", func(): get_parent().call("build_daily_games")],
		["★\nCOLLECT", func(): get_parent().call("build_collection")],
		["⚙\nSETTINGS", func(): get_parent().call("build_settings")]
	]
	var narrow := get_viewport_rect().size.x < 600.0
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := _button(String(entry[0]), Vector2(0, maxf(54.0, nav_height - 10.0)), Unjam3DTheme.WATER if i == 1 else Color("0d6dc2"), i == 1)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16 if narrow else (19 if nav_height < 100.0 else 21))
		var callback: Callable = entry[1]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)
