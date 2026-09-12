extends Control

var content: Control

func _ready() -> void:
	build_home()

func clear_content() -> void:
	if content and is_instance_valid(content):
		content.queue_free()
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)

func style_box(color: Color, radius := 28, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if width > 0:
		s.border_width_left = width
		s.border_width_right = width
		s.border_width_top = width
		s.border_width_bottom = width
		s.border_color = border
	return s

func make_button(text_value: String, size := Vector2(420, 92), accent := false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 28)
	var color := Color("243b63") if not accent else Color("21c7a8")
	b.add_theme_stylebox_override("normal", style_box(color, 24))
	b.add_theme_stylebox_override("hover", style_box(color.lightened(0.08), 24))
	b.add_theme_stylebox_override("pressed", style_box(color.darkened(0.10), 24))
	b.add_theme_stylebox_override("disabled", style_box(Color("252d3e"), 24))
	b.add_theme_color_override("font_disabled_color", Color("697387"))
	return b

func add_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color("081426")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(bg)
	var glow := ColorRect.new()
	glow.color = Color(0.08, 0.42, 0.48, 0.18)
	glow.position = Vector2(0, 180)
	glow.size = Vector2(1080, 620)
	content.add_child(glow)

func build_home() -> void:
	clear_content()
	add_background()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-300, -600)
	box.custom_minimum_size = Vector2(600, 1200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	content.add_child(box)

	var badge := Label.new()
	badge.text = "CHAIN-REACTION RESCUE PUZZLES"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_color_override("font_color", Color("67e8cf"))
	box.add_child(badge)

	var title := Label.new()
	title.text = "UNJAM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 82)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "RESCUE RUSH"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.modulate = Color("a8b8cf")
	box.add_child(subtitle)

	var stats_panel := PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(560, 118)
	stats_panel.add_theme_stylebox_override("panel", style_box(Color(0.06,0.10,0.18,0.92), 28, Color(1,1,1,0.08), 2))
	box.add_child(stats_panel)
	var stats := Label.new()
	stats.text = "%d / %d LEVELS   •   %d ★   •   %d COINS" % [min(int(SaveManager.data.highest_level) - 1, LevelManager.get_level_count()), LevelManager.get_level_count(), SaveManager.total_stars(), int(SaveManager.data.coins)]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 21)
	stats_panel.add_child(stats)

	var play := make_button("PLAY CAMPAIGN", Vector2(520, 96), true)
	play.pressed.connect(build_level_select)
	box.add_child(play)

	var daily_text := "DAILY RESCUE  •  " + DailyChallenge.reward_text()
	var daily := make_button(daily_text, Vector2(520, 86))
	daily.pressed.connect(start_daily)
	box.add_child(daily)

	var collection := make_button("RESCUE GARDEN", Vector2(520, 82))
	collection.pressed.connect(build_collection)
	box.add_child(collection)

	var settings := make_button("SETTINGS", Vector2(520, 76))
	settings.pressed.connect(build_settings)
	box.add_child(settings)

	var streak := Label.new()
	streak.text = "Daily streak: %d   •   Best: %d" % [int(SaveManager.data.daily_streak), int(SaveManager.data.daily_best_streak)]
	streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak.add_theme_font_size_override("font_size", 19)
	streak.modulate = Color("95a4bb")
	box.add_child(streak)

func build_level_select() -> void:
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 55)
	margin.add_theme_constant_override("margin_right", 55)
	margin.add_theme_constant_override("margin_top", 65)
	margin.add_theme_constant_override("margin_bottom", 65)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)
	var header := HBoxContainer.new()
	var back := make_button("←", Vector2(94, 68))
	back.pressed.connect(build_home)
	header.add_child(back)
	var label := Label.new()
	label.text = "RESCUE CAMPAIGN"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	header.add_child(label)
	var stars := Label.new()
	stars.text = "%d ★" % SaveManager.total_stars()
	stars.custom_minimum_size = Vector2(120, 68)
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(stars)
	root.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var worlds := VBoxContainer.new()
	worlds.add_theme_constant_override("separation", 30)
	scroll.add_child(worlds)

	for world in range(1, 7):
		var world_panel := PanelContainer.new()
		world_panel.add_theme_stylebox_override("panel", style_box(Color(0.04,0.075,0.14,0.92), 30, Color(1,1,1,0.07), 2))
		worlds.add_child(world_panel)
		var world_box := VBoxContainer.new()
		world_box.add_theme_constant_override("separation", 16)
		world_panel.add_child(world_box)
		var world_title := Label.new()
		world_title.text = "WORLD %d  •  %s" % [world, LevelManager.world_name(world).to_upper()]
		world_title.add_theme_font_size_override("font_size", 25)
		world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		world_box.add_child(world_title)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		world_box.add_child(grid)
		for n in range(10):
			var level_number := (world - 1) * 10 + n + 1
			var unlocked := SaveManager.is_level_unlocked(level_number)
			var level_stars := SaveManager.get_stars(level_number)
			var text := "%02d\n%s" % [level_number, "★".repeat(level_stars)]
			var button := make_button(text, Vector2(160, 112), level_number == int(SaveManager.data.highest_level))
			button.disabled = not unlocked
			button.add_theme_font_size_override("font_size", 22)
			button.pressed.connect(start_level.bind(level_number))
			grid.add_child(button)

func start_level(level_number: int) -> void:
	if content:
		content.visible = false
	var game_scene = load("res://scenes/Game.tscn").instantiate()
	game_scene.level_number = level_number
	game_scene.finished.connect(_on_game_finished)
	game_scene.quit_requested.connect(_on_game_quit)
	add_child(game_scene)

func start_daily() -> void:
	if DailyChallenge.is_completed_today():
		build_home()
		return
	if content:
		content.visible = false
	var game_scene = load("res://scenes/Game.tscn").instantiate()
	game_scene.level_number = 1
	game_scene.daily_mode = true
	game_scene.custom_level_data = DailyChallenge.build_today()
	game_scene.finished.connect(_on_game_finished)
	game_scene.quit_requested.connect(_on_game_quit)
	add_child(game_scene)

func _on_game_finished(completed_level: int) -> void:
	if completed_level < 0:
		build_home()
		content.visible = true
		return
	if LevelManager.has_level(completed_level + 1):
		start_level(completed_level + 1)
	else:
		build_home()
		content.visible = true

func _on_game_quit() -> void:
	build_home()
	content.visible = true

func build_collection() -> void:
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 65)
	margin.add_theme_constant_override("margin_bottom", 65)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	margin.add_child(root)
	var header := HBoxContainer.new()
	var back := make_button("←", Vector2(94, 68))
	back.pressed.connect(build_home)
	header.add_child(back)
	var title := Label.new()
	title.text = "RESCUE GARDEN"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	header.add_child(title)
	var coins := Label.new()
	coins.text = "%d ◈" % int(SaveManager.data.coins)
	coins.custom_minimum_size = Vector2(130, 68)
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(coins)
	root.add_child(header)

	var garden := PanelContainer.new()
	garden.custom_minimum_size = Vector2(0, 520)
	garden.add_theme_stylebox_override("panel", style_box(Color("163f38"), 34, Color("3ecf9a"), 2))
	root.add_child(garden)
	var garden_box := VBoxContainer.new()
	garden_box.alignment = BoxContainer.ALIGNMENT_CENTER
	garden.add_child(garden_box)
	var inhabitants := Label.new()
	inhabitants.text = rescue_garden_text()
	inhabitants.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inhabitants.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inhabitants.add_theme_font_size_override("font_size", 48)
	garden_box.add_child(inhabitants)
	var decor := Label.new()
	decor.text = decoration_text()
	decor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decor.add_theme_font_size_override("font_size", 34)
	garden_box.add_child(decor)

	var shop_title := Label.new()
	shop_title.text = "GARDEN DECORATIONS"
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_font_size_override("font_size", 24)
	root.add_child(shop_title)
	var shop := HBoxContainer.new()
	shop.alignment = BoxContainer.ALIGNMENT_CENTER
	shop.add_theme_constant_override("separation", 14)
	root.add_child(shop)
	for item in [["tree", "🌳 TREE", 100], ["bench", "🪑 BENCH", 150], ["fountain", "⛲ FOUNTAIN", 250]]:
		var id := String(item[0])
		var owned: bool = id in SaveManager.data.decorations
		var button := make_button((String(item[1]) + (" ✓" if owned else "\n%d" % int(item[2]))), Vector2(280, 105), owned)
		button.disabled = owned
		button.pressed.connect(_buy_decoration.bind(id, int(item[2])))
		shop.add_child(button)

func rescue_garden_text() -> String:
	if SaveManager.data.rescued.is_empty():
		return "🌱\nYour first friend is waiting to be rescued."
	var icons := []
	for id in SaveManager.data.rescued:
		match String(id):
			"puppy": icons.append("🐶")
			"kitten": icons.append("🐱")
			"robot": icons.append("🤖")
			"slime": icons.append("🟢")
			"panda": icons.append("🐼")
			"fox": icons.append("🦊")
			"alien": icons.append("👽")
			_: icons.append("🐥")
	return "  ".join(icons)

func decoration_text() -> String:
	var icons := []
	for id in SaveManager.data.decorations:
		match String(id):
			"tree": icons.append("🌳")
			"bench": icons.append("🪑")
			"fountain": icons.append("⛲")
	return "  ".join(icons) if not icons.is_empty() else ""

func _buy_decoration(id: String, cost: int) -> void:
	if SaveManager.unlock_decoration(id, cost):
		FeedbackManager.effect()
		build_collection()

func build_settings() -> void:
	clear_content()
	add_background()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-300, -500)
	box.custom_minimum_size = Vector2(600, 1000)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	content.add_child(box)
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)
	for setting in [["sound", "SOUND"], ["vibration", "HAPTICS"], ["music", "MUSIC"]]:
		var key := String(setting[0])
		var button := make_button("%s: %s" % [String(setting[1]), "ON" if bool(SaveManager.data.get(key, true)) else "OFF"], Vector2(500, 86))
		button.pressed.connect(_toggle_setting.bind(key))
		box.add_child(button)
	var info := Label.new()
	info.text = "Progress is saved automatically on this device.\nHints used: %d   •   Undos used: %d" % [int(SaveManager.data.hints_used), int(SaveManager.data.undos_used)]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 20)
	box.add_child(info)
	var back := make_button("BACK", Vector2(500, 82), true)
	back.pressed.connect(build_home)
	box.add_child(back)

func _toggle_setting(key: String) -> void:
	SaveManager.data[key] = not bool(SaveManager.data.get(key, true))
	SaveManager.save()
	FeedbackManager.tap()
	build_settings()
