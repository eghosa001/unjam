extends Control

var content: Control
var selected_world := 1

const WORLD_BASE := ["081426", "0b1830", "141533", "25142b", "0d241f", "1b1230"]
const WORLD_ACCENT := ["2dd4b6", "5da9ff", "8b7cf6", "ff6b7a", "55d68b", "c074ff"]

func _ready() -> void:
	selected_world = LevelManager.highest_unlocked_world()
	build_home()

func clear_content() -> void:
	if content and is_instance_valid(content):
		if content.get_parent() == self:
			remove_child(content)
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
	b.add_theme_stylebox_override("normal", style_box(Color(color, 0.92), 24, Color(1,1,1,0.08), 1))
	b.add_theme_stylebox_override("hover", style_box(color.lightened(0.08), 24, Color(1,1,1,0.18), 2))
	b.add_theme_stylebox_override("pressed", style_box(color.darkened(0.10), 24, Color.WHITE, 2))
	b.add_theme_stylebox_override("disabled", style_box(Color("252d3e"), 24))
	b.add_theme_color_override("font_disabled_color", Color("697387"))
	return b

func world_palette(world: int) -> Array[Color]:
	var idx := posmod(world - 1, WORLD_BASE.size())
	return [Color(WORLD_BASE[idx]), Color(WORLD_ACCENT[idx])]

func add_background() -> void:
	var palette := world_palette(max(1, selected_world))
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(palette[0], palette[1], selected_world - 1)
	content.add_child(backdrop)
	PremiumVisuals.set_accent(palette[1])
	PremiumVisuals.ambient_sparkles(12)

func add_glass_card(parent: Node, minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", style_box(Color(0.035,0.06,0.11,0.88), 30, Color(1,1,1,0.10), 2))
	parent.add_child(panel)
	return panel

func build_home() -> void:
	clear_content()
	add_background()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-330, -650)
	box.custom_minimum_size = Vector2(660, 1300)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
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
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", Color("f3fbff"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "RESCUE RUSH"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.modulate = Color("a8b8cf")
	box.add_child(subtitle)

	var stats_panel := add_glass_card(box, Vector2(620, 132))
	var stats := Label.new()
	stats.text = "%d / %d LEVELS\n%d ★   •   %d COINS   •   %d PRESTIGE" % [min(int(SaveManager.data.highest_level) - 1, LevelManager.get_level_count()), LevelManager.get_level_count(), SaveManager.total_stars(), int(SaveManager.data.coins), int(SaveManager.data.prestige_points)]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats_panel.add_child(stats)

	var progress_strip := HBoxContainer.new()
	progress_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_strip.add_theme_constant_override("separation", 12)
	box.add_child(progress_strip)
	for text_value in ["PERFECT %d" % int(SaveManager.data.perfect_clears), "STREAK %d" % int(SaveManager.data.perfect_streak), "ACH %d" % int(SaveManager.data.achievement_points)]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(190, 58)
		chip.add_theme_stylebox_override("panel", style_box(Color(0.08,0.13,0.22,0.86), 20, Color("2dd4b6"), 1))
		var chip_label := Label.new()
		chip_label.text = text_value
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_label.add_theme_font_size_override("font_size", 16)
		chip.add_child(chip_label)
		progress_strip.add_child(chip)

	var play := make_button("PLAY CAMPAIGN", Vector2(560, 100), true)
	play.pressed.connect(func(): selected_world = LevelManager.highest_unlocked_world(); build_level_select())
	box.add_child(play)

	var daily_text := "DAILY RESCUE  •  " + DailyChallenge.reward_text()
	var daily := make_button(daily_text, Vector2(560, 88))
	daily.pressed.connect(start_daily)
	box.add_child(daily)

	var secondary := HBoxContainer.new()
	secondary.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary.add_theme_constant_override("separation", 16)
	box.add_child(secondary)
	var collection := make_button("RESCUE GARDEN", Vector2(272, 82))
	collection.pressed.connect(build_collection)
	collection.add_theme_font_size_override("font_size", 21)
	secondary.add_child(collection)
	var settings := make_button("SETTINGS", Vector2(272, 82))
	settings.pressed.connect(build_settings)
	settings.add_theme_font_size_override("font_size", 21)
	secondary.add_child(settings)

	var streak := Label.new()
	streak.text = "Daily streak: %d   •   Best: %d" % [int(SaveManager.data.daily_streak), int(SaveManager.data.daily_best_streak)]
	streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak.add_theme_font_size_override("font_size", 19)
	streak.modulate = Color("95a4bb")
	box.add_child(streak)
	PremiumVisuals.entrance(box, 0.04)

func difficulty_short(label: String) -> String:
	match label:
		"tutorial": return "LEARN"
		"easy": return "EASY"
		"medium": return "MED"
		"normal-hard": return "N-HARD"
		"hard": return "HARD"
		"very hard": return "V-HARD"
		"expert": return "EXPERT"
		"extreme": return "EXTREME"
		"milestone": return "MILE"
		"boss": return "BOSS"
		_: return label.to_upper()

func difficulty_color(label: String) -> Color:
	match label:
		"tutorial": return Color("57d69a")
		"easy": return Color("57d69a")
		"medium": return Color("66a8ff")
		"normal-hard": return Color("66a8ff")
		"hard": return Color("ffb454")
		"very hard": return Color("ff8a55")
		"expert": return Color("d983ff")
		"extreme": return Color("ff667a")
		"milestone": return Color("ffd166")
		"boss": return Color("ff5d7a")
		_: return Color("95a4bb")

func build_level_select() -> void:
	selected_world = clamp(selected_world, 1, LevelManager.WORLD_COUNT)
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 15)
	margin.add_child(root)

	var header := HBoxContainer.new()
	var back := make_button("←", Vector2(90, 66))
	back.pressed.connect(build_home)
	header.add_child(back)
	var label := Label.new()
	label.text = "WORLD %d / %d" % [selected_world, LevelManager.WORLD_COUNT]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 31)
	header.add_child(label)
	var prestige := Label.new()
	prestige.text = "%d P" % int(SaveManager.data.prestige_points)
	prestige.custom_minimum_size = Vector2(120, 66)
	prestige.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prestige.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(prestige)
	root.add_child(header)

	var hero := add_glass_card(root, Vector2(0, 110))
	var hero_box := VBoxContainer.new()
	hero_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_child(hero_box)
	var world_title := Label.new()
	world_title.text = LevelManager.world_name(selected_world).to_upper()
	world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_title.add_theme_font_size_override("font_size", 26)
	world_title.add_theme_color_override("font_color", world_palette(selected_world)[1])
	hero_box.add_child(world_title)
	var range_label := Label.new()
	range_label.text = "LEVELS %d–%d   •   %d ★" % [LevelManager.first_level_in_world(selected_world), LevelManager.last_level_in_world(selected_world), SaveManager.total_stars()]
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 17)
	range_label.modulate = Color("95a4bb")
	hero_box.add_child(range_label)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	var previous := make_button("◀ PREV", Vector2(220, 62))
	previous.disabled = selected_world <= 1
	previous.pressed.connect(_change_world.bind(-1))
	nav.add_child(previous)
	var jump := make_button("CURRENT", Vector2(200, 62), true)
	jump.pressed.connect(_jump_to_current_world)
	nav.add_child(jump)
	var next := make_button("NEXT ▶", Vector2(220, 62))
	next.disabled = selected_world >= LevelManager.WORLD_COUNT or selected_world >= LevelManager.highest_unlocked_world() + 1
	next.pressed.connect(_change_world.bind(1))
	nav.add_child(next)
	root.add_child(nav)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	var first := LevelManager.first_level_in_world(selected_world)
	var last := LevelManager.last_level_in_world(selected_world)
	for level_number in range(first, last + 1):
		var unlocked := SaveManager.is_level_unlocked(level_number)
		var level_stars := SaveManager.get_stars(level_number)
		var level_data := LevelManager.load_level(level_number)
		var d_label := String(level_data.get("difficulty_label", "medium"))
		var text := "%d\n%s   %s" % [level_number, "★".repeat(level_stars), difficulty_short(d_label)]
		var button := make_button(text, Vector2(170, 108), level_number == int(SaveManager.data.highest_level))
		button.disabled = not unlocked
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", difficulty_color(d_label) if unlocked else Color("697387"))
		button.pressed.connect(start_level.bind(level_number))
		grid.add_child(button)

func _change_world(delta: int) -> void:
	selected_world = clamp(selected_world + delta, 1, LevelManager.WORLD_COUNT)
	build_level_select()

func _jump_to_current_world() -> void:
	selected_world = LevelManager.highest_unlocked_world()
	build_level_select()

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
	selected_world = LevelManager.highest_unlocked_world()
	build_level_select()
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

	var garden := add_glass_card(root, Vector2(0, 520))
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

	var prestige := Label.new()
	prestige.text = "PRESTIGE %d   •   ACHIEVEMENT POINTS %d   •   WORLD BADGES %d" % [int(SaveManager.data.prestige_points), int(SaveManager.data.achievement_points), SaveManager.data.world_badges.size()]
	prestige.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prestige.add_theme_font_size_override("font_size", 18)
	root.add_child(prestige)

	var shop_title := Label.new()
	shop_title.text = "GARDEN DECORATIONS"
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_font_size_override("font_size", 24)
	root.add_child(shop_title)
	var shop := HBoxContainer.new()
	shop.alignment = BoxContainer.ALIGNMENT_CENTER
	shop.add_theme_constant_override("separation", 14)
	root.add_child(shop)
	for item in [["tree", "TREE", 100], ["bench", "BENCH", 150], ["fountain", "FOUNTAIN", 250]]:
		var id := String(item[0])
		var owned: bool = id in SaveManager.data.decorations
		var button := make_button((String(item[1]) + ("  OWNED" if owned else "\n%d COINS" % int(item[2]))), Vector2(280, 105), owned)
		button.disabled = owned
		button.pressed.connect(_buy_decoration.bind(id, int(item[2])))
		shop.add_child(button)

func rescue_garden_text() -> String:
	if SaveManager.data.rescued.is_empty():
		return "Your first friend is waiting to be rescued."
	var names := []
	for id in SaveManager.data.rescued:
		names.append(String(id).capitalize())
	return "RESCUED FRIENDS\n" + "  •  ".join(names)

func decoration_text() -> String:
	if SaveManager.data.decorations.is_empty():
		return "Build a home worthy of your rescued crew."
	var names := []
	for id in SaveManager.data.decorations:
		names.append(String(id).capitalize())
	return "GARDEN: " + "  •  ".join(names)

func _buy_decoration(id: String, cost: int) -> void:
	if SaveManager.unlock_decoration(id, cost):
		FeedbackManager.effect()
		PremiumVisuals.burst(Vector2(540, 1100), Color("2dd4b6"), 20)
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
	var shell := get_node_or_null("UXShell")
	if shell != null:
		var current_theme := String(shell.get("theme_mode")) if shell.get("theme_mode") != null else "dark"
		var appearance := make_button("APPEARANCE: %s" % current_theme.to_upper(), Vector2(500, 86))
		appearance.pressed.connect(func() -> void:
			if shell.has_method("_toggle_theme"):
				shell.call("_toggle_theme")
			call_deferred("build_settings")
		)
		box.add_child(appearance)
	var info := Label.new()
	info.text = "Progress saves automatically.\nHints %d   •   Undos %d   •   Perfect clears %d\nPrestige %d   •   Achievement points %d" % [int(SaveManager.data.hints_used), int(SaveManager.data.undos_used), int(SaveManager.data.perfect_clears), int(SaveManager.data.prestige_points), int(SaveManager.data.achievement_points)]
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