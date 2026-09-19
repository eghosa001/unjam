extends "res://scripts/ui/premium_home_casual.gd"

# UNJAM premium Home redesign.
#
# This leaf intentionally changes presentation only. Navigation, game launch,
# persistence and motion ownership stay in the existing controllers. In
# particular, MotionDirector remains the sole screen-transition owner and the
# live 3D mascot/backdrop keep their own animation behavior.

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

	var viewport_size := get_viewport_rect().size
	var dark_mode := _theme_mode() == "dark"
	var short_phone := viewport_size.y < 1100.0
	var compact_height := viewport_size.y < 1250.0
	var compact_width := viewport_size.x < 700.0
	clip_contents = true

	var backdrop := Unjam3DBackdrop.new()
	backdrop.name = "HomePremiumBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Unjam3DTheme.game_accent(selected_game), dark_mode)
	add_child(backdrop)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 16 if viewport_size.x < 600.0 else (22 if compact_width else 34))
	outer.add_theme_constant_override("margin_right", 16 if viewport_size.x < 600.0 else (22 if compact_width else 34))
	outer.add_theme_constant_override("margin_top", 14 if short_phone else (18 if compact_height else 28))
	outer.add_theme_constant_override("margin_bottom", 110 if short_phone else (116 if compact_height else 132))
	add_child(outer)

	var root := VBoxContainer.new()
	root.name = "HomePremiumRoot"
	root.add_theme_constant_override("separation", 6 if short_phone else (8 if compact_height else 11))
	outer.add_child(root)

	_make_status_bar(root)
	_make_brand_logo(root)

	# Keep the hero/action composition centred on very tall phones without
	# stretching the 3D scene itself.
	var tall_top_push := maxf(0.0, viewport_size.y - 1920.0) * 0.57
	if tall_top_push > 0.0:
		var tall_top_spacer := Control.new()
		tall_top_spacer.name = "HomeTallTopSpacer"
		tall_top_spacer.custom_minimum_size = Vector2(0, tall_top_push)
		root.add_child(tall_top_spacer)

	_make_hero(root)

	var aspect_ratio := viewport_size.y / maxf(1.0, viewport_size.x)
	var balance_height := maxf(0.0, aspect_ratio - 1.82) * 360.0
	if balance_height > 0.0:
		var spacer := Control.new()
		spacer.name = "HomeUpperBalanceSpacer"
		spacer.custom_minimum_size = Vector2(0, minf(balance_height, 180.0))
		root.add_child(spacer)

	var action_cluster := VBoxContainer.new()
	action_cluster.name = "HomeActionCluster"
	action_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
	action_cluster.add_theme_constant_override("separation", 7 if short_phone else (9 if compact_height else 12))
	root.add_child(action_cluster)

	var current_level := _home_current_level(selected_game)
	primary_button = Button.new()
	primary_button.name = "HomePrimaryAction"
	primary_button.text = "▶  CONTINUE\n%s  •  LEVEL %d" % [_short_game_name(selected_game), current_level]
	primary_button.tooltip_text = "Continue your current %s campaign" % MultiGameManager.display_name(selected_game)
	primary_button.custom_minimum_size = Vector2(0, 106 if short_phone else (118 if compact_height else 132))
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_button.add_theme_font_size_override("font_size", 27 if viewport_size.x < 600.0 else (30 if compact_width else 35))
	Unjam3DTheme.gloss_button(primary_button, Unjam3DTheme.game_accent(selected_game), true, 34, dark_mode)
	primary_button.pressed.connect(_continue_selected_game)
	action_cluster.add_child(primary_button)

	var quick_row := HBoxContainer.new()
	quick_row.name = "HomeQuickActions"
	quick_row.add_theme_constant_override("separation", 8 if compact_width else 10)
	action_cluster.add_child(quick_row)

	var choose := Button.new()
	choose.name = "HomeChooseGameButton"
	choose.text = "◈  ALL GAMES"
	choose.custom_minimum_size = Vector2(0, 78 if short_phone else (84 if compact_height else 92))
	choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose.add_theme_font_size_override("font_size", 18 if compact_width else 22)
	Unjam3DTheme.gloss_button(choose, Unjam3DTheme.WATER_DARK, false, 24, dark_mode)
	choose.pressed.connect(_open_game_selector)
	quick_row.add_child(choose)

	var daily := Button.new()
	daily.name = "HomeDailyGamesButton"
	var daily_done := 0
	for game_id in MultiGameManager.GAME_IDS:
		var main := get_parent()
		if main != null and main.has_method("_daily_done") and bool(main.call("_daily_done", game_id)):
			daily_done += 1
	daily.text = "☀  DAILY  %d/3" % daily_done
	daily.tooltip_text = "Play today's three daily challenges"
	daily.custom_minimum_size = Vector2(0, 78 if short_phone else (84 if compact_height else 92))
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily.add_theme_font_size_override("font_size", 18 if compact_width else 22)
	Unjam3DTheme.gloss_button(daily, Unjam3DTheme.GOLD, true, 24, dark_mode)
	daily.pressed.connect(_open_daily_games)
	quick_row.add_child(daily)

	_make_game_strip(action_cluster)

	var lower_spacer := Control.new()
	lower_spacer.name = "HomeLowerBalanceSpacer"
	lower_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(lower_spacer)
	_make_bottom_nav()
	_animate_entry(root)

func _make_status_bar(parent: VBoxContainer) -> void:
	var viewport_size := get_viewport_rect().size
	var narrow := viewport_size.x < 600.0
	var compact := viewport_size.x < 700.0
	var bar := HBoxContainer.new()
	bar.name = "HomeStatusBar"
	bar.custom_minimum_size = Vector2(0, 64 if viewport_size.y < 1100.0 else (70 if viewport_size.y < 1250.0 else 80))
	bar.add_theme_constant_override("separation", 6 if narrow else 8)
	parent.add_child(bar)

	var cleared := 0
	for game_id in MultiGameManager.GAME_IDS:
		cleared += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	var player_level := maxi(1, 1 + int(cleared / 10))
	var profile := _make_badge("☺  LV %d" % player_level, Unjam3DTheme.WATER_DARK)
	profile.custom_minimum_size.x = 126 if narrow else (142 if compact else 176)
	bar.add_child(profile)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	home_coin_button = _make_shop_badge()
	home_coin_button.custom_minimum_size.x = 136 if narrow else (150 if compact else 184)
	bar.add_child(home_coin_button)

	var stars := _make_badge("★  %s" % _compact_number(_total_stars()), Unjam3DTheme.GOLD)
	stars.custom_minimum_size.x = 126 if narrow else (142 if compact else 176)
	bar.add_child(stars)

func _make_brand_logo(parent: VBoxContainer) -> void:
	var viewport_size := get_viewport_rect().size
	var short_phone := viewport_size.y < 1100.0
	var compact := viewport_size.y < 1250.0
	var box := VBoxContainer.new()
	box.name = "HomeBrandLockup"
	box.custom_minimum_size = Vector2(0, 92 if short_phone else (112 if compact else 140))
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -4)
	parent.add_child(box)

	# Individual letters create a stronger game identity than a flat wordmark,
	# while staying fully procedural and resolution-independent.
	var letters := HBoxContainer.new()
	letters.name = "HomeLogoLetters"
	letters.alignment = BoxContainer.ALIGNMENT_CENTER
	letters.add_theme_constant_override("separation", -10 if viewport_size.x < 600.0 else -14)
	box.add_child(letters)

	var palette := [Color("ffd52b"), Color("ff8c21"), Color("ff4b83"), Color("c94dff"), Color("27baff")]
	var text := "UNJAM"
	var available_width := maxf(320.0, viewport_size.x - (36.0 if viewport_size.x < 600.0 else 86.0))
	var letter_width := clampf((available_width + 44.0) / 5.0, 62.0, 128.0)
	for i in range(text.length()):
		var letter := Label.new()
		letter.text = text.substr(i, 1)
		letter.custom_minimum_size = Vector2(letter_width, letter_width * 0.82)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.add_theme_font_size_override("font_size", int(letter_width * 0.76))
		letter.rotation = deg_to_rad(float(i - 2) * 1.25)
		letter.position.y = absf(float(i - 2)) * 2.5
		Unjam3DTheme.label_3d(letter, palette[i], Color("06488d"), 8)
		letters.add_child(letter)

	var strap := Label.new()
	strap.text = "THREE PUZZLE WORLDS  •  ONE JOURNEY"
	strap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strap.add_theme_font_size_override("font_size", 17 if short_phone else (20 if compact else 23))
	Unjam3DTheme.label_3d(strap, Color.WHITE, Unjam3DTheme.NAVY, 3)
	box.add_child(strap)

func _make_hero(parent: VBoxContainer) -> void:
	var viewport_size := get_viewport_rect().size
	var hero_height := 228.0 if viewport_size.y < 1100.0 else (320.0 if viewport_size.y < 1250.0 else clampf(viewport_size.y * 0.23, 390.0, 460.0))
	var hero := PanelContainer.new()
	hero.name = "HomeHero3D"
	hero.custom_minimum_size = Vector2(0, hero_height)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_theme_stylebox_override(
		"panel",
		Unjam3DTheme.panel_3d(
			Color("102846") if _theme_mode() == "dark" else Color(0.70, 0.94, 1.0, 0.58),
			42,
			Color(1, 1, 1, 0.52),
			3,
			18
		)
	)
	parent.add_child(hero)

	var mascot := Unjam3DMascot.new()
	mascot.name = "HomeMascot3D"
	var mascot_width := maxf(640.0, viewport_size.x - 96.0) if viewport_size.x >= 700.0 else maxf(360.0, viewport_size.x - 38.0)
	mascot.custom_minimum_size = Vector2(mascot_width, maxf(190.0, hero_height - 24.0))
	mascot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero.add_child(mascot)

	var overlay_margin := MarginContainer.new()
	overlay_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_margin.add_theme_constant_override("margin_left", 18 if viewport_size.x < 600.0 else 26)
	overlay_margin.add_theme_constant_override("margin_right", 18 if viewport_size.x < 600.0 else 26)
	overlay_margin.add_theme_constant_override("margin_top", 16 if viewport_size.y < 1100.0 else 22)
	overlay_margin.add_theme_constant_override("margin_bottom", 14 if viewport_size.y < 1100.0 else 20)
	hero.add_child(overlay_margin)

	var overlay := VBoxContainer.new()
	overlay.name = "HomeHeroOverlay"
	overlay.add_theme_constant_override("separation", 4)
	overlay_margin.add_child(overlay)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	overlay.add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "CURRENT JOURNEY"
	eyebrow.add_theme_font_size_override("font_size", 18 if viewport_size.x < 600.0 else 22)
	Unjam3DTheme.label_3d(eyebrow, Unjam3DTheme.GOLD, Unjam3DTheme.NAVY, 3)
	header.add_child(eyebrow)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	var world_badge := Label.new()
	world_badge.text = "WORLD %d" % world
	world_badge.add_theme_font_size_override("font_size", 17 if viewport_size.x < 600.0 else 20)
	Unjam3DTheme.label_3d(world_badge, Color.WHITE, Unjam3DTheme.NAVY, 3)
	header.add_child(world_badge)

	var current := Label.new()
	current.text = "%s\nLEVEL %d" % [MultiGameManager.display_name(selected_game).to_upper(), level]
	current.add_theme_font_size_override("font_size", 28 if viewport_size.x < 600.0 else (33 if viewport_size.x < 700.0 else 40))
	Unjam3DTheme.label_3d(current, Color.WHITE, Unjam3DTheme.NAVY, 4)
	overlay.add_child(current)

	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.add_child(push)

	var caption := Label.new()
	caption.text = "RELAX • SOLVE • KEEP YOUR STREAK"
	caption.add_theme_font_size_override("font_size", 17 if viewport_size.x < 600.0 else 22)
	Unjam3DTheme.label_3d(caption, Color("e8f8ff"), Unjam3DTheme.NAVY, 2)
	overlay.add_child(caption)

func _make_game_strip(parent: VBoxContainer) -> void:
	var strip := HBoxContainer.new()
	strip.name = "HomeGameStrip"
	var viewport_size := get_viewport_rect().size
	var short_phone := viewport_size.y < 1100.0
	var compact := viewport_size.x < 700.0
	strip.custom_minimum_size = Vector2(0, 92 if short_phone else (112 if viewport_size.y < 1250.0 else 132))
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 7 if compact else 10)
	parent.add_child(strip)

	var games := [
		["rescue_rush", "RESCUE RUSH", "↗"],
		["water_sort", "WATER SORT", "◉"],
		["block_puzzle", "BLOCK PUZZLE", "◆"]
	]
	for entry in games:
		var game_id := String(entry[0])
		var level := _home_current_level(game_id)
		var stars := MultiGameManager.total_stars(game_id)
		var button := Button.new()
		button.name = "HomeDirect_%s" % game_id
		button.text = "%s  %s\nLV %d  •  ★ %s" % [String(entry[2]), String(entry[1]), level, _compact_number(stars)]
		button.custom_minimum_size = Vector2(0, 90 if short_phone else (104 if compact else 120))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15 if viewport_size.x < 600.0 else (17 if compact else 20))
		button.tooltip_text = "Open %s journey" % MultiGameManager.display_name(game_id)
		var accent := Unjam3DTheme.game_accent(game_id)
		Unjam3DTheme.gloss_button(button, accent, game_id == selected_game, 24, _theme_mode() == "dark")
		button.pressed.connect(_select_and_open_game.bind(game_id))
		strip.add_child(button)

func _make_motto(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)
	var plaque := PanelContainer.new()
	plaque.name = "HomeMottoStone"
	plaque.custom_minimum_size = Vector2(minf(790.0, get_viewport_rect().size.x - 56.0), 74)
	plaque.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("122741") if _theme_mode() == "dark" else Color(0.94, 0.98, 1.0, 0.92), 28, Color(1, 1, 1, 0.34), 2, 7))
	center.add_child(plaque)
	var label := Label.new()
	label.text = "THREE WORLDS  •  ONE RELAXING JOURNEY"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	Unjam3DTheme.label_3d(label, Color("f2f8ff") if _theme_mode() == "dark" else Unjam3DTheme.NAVY, Color("071a35") if _theme_mode() == "dark" else Color.WHITE, 2)
	plaque.add_child(label)

func _make_bottom_nav() -> void:
	var viewport_size := get_viewport_rect().size
	var nav := PanelContainer.new()
	nav.name = "HomeBottomNav3D"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 14 if viewport_size.x < 600.0 else 22
	nav.offset_right = -14 if viewport_size.x < 600.0 else -22
	nav.offset_top = -110 if viewport_size.y < 1100.0 else -118
	nav.offset_bottom = -10 if viewport_size.y < 1100.0 else -14
	nav.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("071a35") if _theme_mode() == "dark" else Color("0756a8"), 30, Color("67d3ff"), 3, 12))
	add_child(nav)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3 if viewport_size.x < 600.0 else 5)
	nav.add_child(row)

	var entries: Array = [
		["⌂\nHOME", Callable(), "HomeNavButton"],
		["◈\nGAMES", Callable(self, "_open_game_selector"), "HomeLevelsNavButton"],
		["☀\nDAILY", Callable(self, "_open_daily_games"), "HomeDailyNavButton"],
		["★\nCOLLECT", func(): get_parent().call("build_collection"), "HomeCollectionNavButton"],
		["⚙\nSETTINGS", func(): get_parent().call("build_settings"), "HomeSettingsNavButton"]
	]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button := Button.new()
		button.name = String(entry[2])
		button.text = String(entry[0])
		button.custom_minimum_size = Vector2(0, 82 if viewport_size.y < 1100.0 else 88)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14 if viewport_size.x < 600.0 else (16 if viewport_size.x < 700.0 else 18))
		var selected := i == 0
		var accent := Unjam3DTheme.WATER if selected else Color("0d6dc2")
		Unjam3DTheme.gloss_button(button, accent, selected, 22, _theme_mode() == "dark")
		var callback: Callable = entry[1]
		if callback.is_valid():
			button.pressed.connect(callback)
		row.add_child(button)

func _home_current_level(game_id: String) -> int:
	if game_id == "rescue_rush":
		return clampi(int(SaveManager.data.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	return clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)

func _short_game_name(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _continue_selected_game() -> void:
	var main := get_parent()
	if main == null:
		return
	FeedbackManager.tap()
	var level := _home_current_level(selected_game)
	if selected_game == "rescue_rush":
		main.call("start_level", level)
	else:
		main.call("start_multi_level", selected_game, level, false)

func _open_daily_games() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_daily_games"):
		FeedbackManager.tap()
		main.call("build_daily_games")

func _select_and_open_game(game_id: String) -> void:
	selected_game = game_id
	var main := get_parent()
	if main == null or not main.has_method("open_game_campaign"):
		return
	main.set("selected_game_id", game_id)
	FeedbackManager.tap()
	main.call("open_game_campaign", game_id)

func _open_game_levels(game_id: String) -> void:
	_select_and_open_game(game_id)
