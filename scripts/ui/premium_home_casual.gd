extends "res://scripts/ui/premium_home_overhaul.gd"

# Reference-composed Home: fantasy waterfall world, oversized colorful branding,
# explorer sign stack, a real-time 3D mascot, one dominant PLAY action, stone
# motto and a chunky five-item bottom navigation bar.

var home_coin_button: Button

func build_home_launcher() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not EconomyManager.balance_changed.is_connected(_on_economy_balance_changed):
		EconomyManager.balance_changed.connect(_on_economy_balance_changed)

	var dark_mode := _theme_mode() == "dark"
	var viewport_size := get_viewport_rect().size
	var short_phone := viewport_size.y < 1100.0
	var narrow_phone := viewport_size.x < 600.0
	clip_contents = true
	var backdrop := Unjam3DBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Unjam3DTheme.GREEN, dark_mode)
	add_child(backdrop)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 18 if narrow_phone else 34)
	outer.add_theme_constant_override("margin_right", 18 if narrow_phone else 34)
	outer.add_theme_constant_override("margin_top", 18 if short_phone else 28)
	outer.add_theme_constant_override("margin_bottom", 112 if short_phone else 132)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6 if short_phone else 9)
	outer.add_child(root)

	_make_status_bar(root)
	_make_brand_logo(root)
	_make_hero(root)

	var aspect_ratio := viewport_size.y / maxf(1.0, viewport_size.x)
	var upper_balance_height := maxf(0.0, aspect_ratio - 1.9) * 760.0
	if upper_balance_height > 0.0:
		var upper_balance_spacer := Control.new()
		upper_balance_spacer.name = "HomeUpperBalanceSpacer"
		upper_balance_spacer.custom_minimum_size = Vector2(0, upper_balance_height)
		root.add_child(upper_balance_spacer)

	var action_cluster := VBoxContainer.new()
	action_cluster.name = "HomeActionCluster"
	action_cluster.size_flags_vertical = Control.SIZE_FILL
	action_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
	action_cluster.add_theme_constant_override("separation", 7 if short_phone else 11)
	root.add_child(action_cluster)

	primary_button = Button.new()
	primary_button.name = "HomePrimaryAction"
	primary_button.text = "▶   PLAY"
	var tall_screen := viewport_size.y >= 1400.0
	primary_button.custom_minimum_size = Vector2(0, 126 if tall_screen else (104 if short_phone else 116))
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button.add_theme_font_size_override("font_size", 38 if short_phone else 44)
	Unjam3DTheme.gloss_button(primary_button, Unjam3DTheme.GREEN, true, 44, dark_mode)
	primary_button.pressed.connect(_open_game_selector)
	action_cluster.add_child(primary_button)

	var play_hint := Label.new()
	play_hint.text = "PICK YOUR PUZZLE   •   START PLAYING"
	play_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_hint.add_theme_font_size_override("font_size", 19 if short_phone else 22)
	Unjam3DTheme.label_3d(play_hint, Color.WHITE, Unjam3DTheme.NAVY, 3)
	action_cluster.add_child(play_hint)

	_make_game_strip(action_cluster)
	_make_daily_games_action(action_cluster)
	var lower_balance_spacer := Control.new()
	lower_balance_spacer.name = "HomeLowerBalanceSpacer"
	lower_balance_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(lower_balance_spacer)
	_make_motto(root)
	_make_bottom_nav()
	_animate_entry(root)

func _make_status_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	var viewport_size := get_viewport_rect().size
	var short_phone := viewport_size.y < 1100.0
	bar.custom_minimum_size = Vector2(0, 66 if short_phone else 84)
	bar.add_theme_constant_override("separation", 10)
	parent.add_child(bar)
	var cleared := 0
	for game_id in MultiGameManager.GAME_IDS:
		cleared += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	var player_level := maxi(1, 1 + int(cleared / 10))
	bar.add_child(_make_badge("☺  LV %d" % player_level, Unjam3DTheme.WATER))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	home_coin_button = _make_shop_badge()
	bar.add_child(home_coin_button)
	bar.add_child(_make_badge("★  %s  +" % _compact_number(_total_stars()), Unjam3DTheme.GOLD))

func _make_badge(text_value: String, fill: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	var viewport_size := get_viewport_rect().size
	var badge_width := 150.0 if viewport_size.x < 600.0 else (188.0 if viewport_size.x < 800.0 else 204.0)
	var badge_height := 62.0 if viewport_size.y < 1100.0 else 76.0
	badge.custom_minimum_size = Vector2(badge_width, badge_height)
	badge.add_theme_stylebox_override("panel", Unjam3DTheme.badge(fill, 27))
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19 if viewport_size.x < 600.0 else 24)
	Unjam3DTheme.label_3d(label, Color.WHITE, fill.darkened(0.46), 3)
	badge.add_child(label)
	return badge

func _make_shop_badge() -> Button:
	var viewport_size := get_viewport_rect().size
	var button := Button.new()
	button.name = "HomeCoinShopButton"
	button.text = "●  %s  +" % _compact_number(EconomyManager.balance())
	button.tooltip_text = "Coins • Open Shop"
	button.custom_minimum_size = Vector2(150.0 if viewport_size.x < 600.0 else (188.0 if viewport_size.x < 800.0 else 204.0), 62.0 if viewport_size.y < 1100.0 else 76.0)
	button.add_theme_font_size_override("font_size", 19 if viewport_size.x < 600.0 else 24)
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.ORANGE, true, 27, _theme_mode() == "dark")
	button.pressed.connect(_open_shop)
	return button

func _on_economy_balance_changed(new_balance: int, _delta: int, _reason: String) -> void:
	if home_coin_button != null and is_instance_valid(home_coin_button):
		home_coin_button.text = "●  %s  +" % _compact_number(new_balance)

func _make_brand_logo(parent: VBoxContainer) -> void:
	var viewport_size := get_viewport_rect().size
	var short_phone := viewport_size.y < 1100.0
	var logo_box := VBoxContainer.new()
	logo_box.custom_minimum_size = Vector2(0, 132 if short_phone else (180 if viewport_size.y < 1400.0 else 205))
	logo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_box.add_theme_constant_override("separation", -2)
	parent.add_child(logo_box)
	var letters := HBoxContainer.new()
	letters.alignment = BoxContainer.ALIGNMENT_CENTER
	letters.add_theme_constant_override("separation", -13)
	logo_box.add_child(letters)
	var palette := [Color("ffd52b"), Color("ff8c21"), Color("ff4b83"), Color("ce48ff"), Color("25b7ff")]
	var text := "UNJAM"
	var available_logo_width := maxf(360.0, viewport_size.x - (48.0 if viewport_size.x < 600.0 else 96.0))
	var letter_width := clampf((available_logo_width + 52.0) / 5.0, 82.0, 148.0)
	for i in range(text.length()):
		var label := Label.new()
		label.text = text.substr(i, 1)
		label.add_theme_font_size_override("font_size", int(letter_width * 0.81))
		label.custom_minimum_size = Vector2(letter_width, letter_width * 0.96)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.rotation = deg_to_rad(float(i - 2) * 1.7)
		label.position.y = absf(float(i - 2)) * 4.0
		Unjam3DTheme.label_3d(label, palette[i], Color("06488d"), 11)
		letters.add_child(label)
	var subtitle := Label.new()
	subtitle.text = "THREE PUZZLES  •  ONE JOURNEY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18 if short_phone else 22)
	Unjam3DTheme.label_3d(subtitle, Color.WHITE, Unjam3DTheme.NAVY, 4)
	logo_box.add_child(subtitle)

func _make_hero(parent: VBoxContainer) -> void:
	var viewport_size := get_viewport_rect().size
	var hero_height := 210.0 if viewport_size.y < 1100.0 else (300.0 if viewport_size.y < 1400.0 else 360.0)
	var hero := PanelContainer.new()
	hero.name = "HomeHero3D"
	hero.custom_minimum_size = Vector2(0, hero_height)
	hero.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.06, 0.13, 0.24, 0.52) if _theme_mode() == "dark" else Color(0.82, 0.97, 1.0, 0.09), 42, Color(1, 1, 1, 0.38), 2, 8))
	parent.add_child(hero)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	hero.add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	var mascot := Unjam3DMascot.new()
	mascot.name = "HomeMascot3D"
	mascot.custom_minimum_size = Vector2(minf(700.0, maxf(420.0, viewport_size.x - 80.0)), maxf(190.0, hero_height - 40.0))
	mascot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mascot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(mascot)

func _make_game_strip(parent: VBoxContainer) -> void:
	var strip := HBoxContainer.new()
	strip.name = "HomeGameStrip"
	var viewport_height := get_viewport_rect().size.y
	strip.custom_minimum_size = Vector2(0, 70 if viewport_height < 1100.0 else (104 if viewport_height >= 1400.0 else 92))
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 12)
	parent.add_child(strip)
	var games := [
		["RESCUE", "RUSH", Unjam3DTheme.GREEN],
		["WATER", "SORT", Unjam3DTheme.WATER],
		["BLOCK", "PUZZLE", Unjam3DTheme.PURPLE]
	]
	for game in games:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 62 if viewport_height < 1100.0 else 86)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var accent: Color = game[2]
		card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(accent, 24, accent.lightened(0.34), 2, 8))
		strip.add_child(card)
		var label := Label.new()
		label.text = "%s\n%s" % [game[0], game[1]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15 if viewport_height < 1100.0 else 18)
		Unjam3DTheme.label_3d(label, Color.WHITE, accent.darkened(0.48), 3)
		card.add_child(label)

func _make_daily_games_action(parent: VBoxContainer) -> void:
	var completed := 0
	for game_id in MultiGameManager.GAME_IDS:
		if get_parent().has_method("_daily_done") and bool(get_parent().call("_daily_done", game_id)):
			completed += 1
	var bonus := EconomyManager.collection_daily_bonus()
	var daily := Button.new()
	daily.name = "HomeDailyGamesButton"
	daily.text = "☀  DAILY GAMES   •   %d/3 COMPLETE" % completed
	if bonus > 0:
		daily.text += "   •   +%d COLLECTION BONUS" % bonus
	daily.tooltip_text = "Play today's Rescue Rush, Water Sort and Block Puzzle challenges"
	daily.custom_minimum_size = Vector2(0, 84 if get_viewport_rect().size.y < 1100.0 else 94)
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily.add_theme_font_size_override("font_size", 19 if get_viewport_rect().size.x < 600.0 else 23)
	Unjam3DTheme.gloss_button(daily, Unjam3DTheme.GOLD, true, 24, _theme_mode() == "dark")
	daily.pressed.connect(func() -> void:
		FeedbackManager.tap()
		var main := get_parent()
		if main != null and main.has_method("build_daily_games"):
			main.call("build_daily_games")
	)
	parent.add_child(daily)

func _make_motto(parent: VBoxContainer) -> void:
	var viewport_size := get_viewport_rect().size
	var center := CenterContainer.new()
	parent.add_child(center)
	var stone := PanelContainer.new()
	stone.name = "HomeMottoStone"
	stone.custom_minimum_size = Vector2(minf(760.0, maxf(390.0, viewport_size.x - 48.0)), 72 if viewport_size.y < 1100.0 else (100 if viewport_size.y >= 1400.0 else 86))
	stone.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("24314a") if _theme_mode() == "dark" else Color("c8c4a7"), 30, Color("eef0cf"), 3, 8))
	center.add_child(stone)
	var label := Label.new()
	label.text = "SMALL PUZZLES  •  BRIGHTER DAYS  ♥"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19 if viewport_size.y < 1100.0 else 24)
	Unjam3DTheme.label_3d(label, Color("f3f7ff") if _theme_mode() == "dark" else Color("244279"), Color(1,1,1,0.82), 2)
	stone.add_child(label)

func _make_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.name = "HomeBottomNav3D"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 28
	nav.offset_right = -28
	nav.offset_top = -120
	nav.offset_bottom = -16
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("071a35") if _theme_mode() == "dark" else Color("0756a8"), 30, Color("56c8ff"), 3, 10))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	nav.add_child(row)
	# Keep the same global destinations everywhere. Shop stays available from the
	# coin badge above, while gameplay level selection remains inside Games.
	var entries: Array = [
		["⌂\nHOME", Callable(), "HomeNavButton", Color("33b9ff"), "Home"],
		["▦\nGAMES", Callable(self, "_open_game_selector"), "HomeGamesNavButton", Color("7b6cff"), "Games"],
		["✦\nDAILY", func(): get_parent().call("build_daily_games"), "HomeDailyNavButton", Color("f5c93a"), "Daily Games"],
		["◆\nCOLLECT", func(): get_parent().call("build_collection"), "HomeCollectionNavButton", Color("24c96b"), "Collection"],
		["⚙\nSETTINGS", func(): get_parent().call("build_settings"), "HomeSettingsNavButton", Color("35c6ff"), "Settings"]
	]
	var narrow := get_viewport_rect().size.x < 600.0
	var dark_mode := _theme_mode() == "dark"
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := Button.new()
		button.name = String(entry[2])
		button.text = String(entry[0])
		button.tooltip_text = String(entry[4])
		button.custom_minimum_size = Vector2(0, 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18 if narrow else 20)
		var selected := i == 0
		var accent: Color = entry[3]
		var idle_fill := Color("0a315d") if dark_mode else Color("0d6dc2")
		Unjam3DTheme.gloss_button(button, accent if selected else idle_fill, selected, 22, dark_mode)
		if not selected:
			button.modulate = Color(1,1,1,0.96)
		var callback: Callable = entry[1]
		if callback.is_valid():
			button.pressed.connect(callback)
		else:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(button)

func _open_shop() -> void:
	var main := get_parent()
	if main == null:
		return
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		FeedbackManager.tap()
		hub.call("open_shop")

func _open_game_selector() -> void:
	var main := get_parent()
	if main == null:
		return
	FeedbackManager.tap()
	main.set("current_surface", "live")
	var content = main.get("content")
	if content is Control and is_instance_valid(content):
		(content as Control).hide()

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