extends "res://scripts/ui/main.gd"

var current_surface := "home"
var active_game: Control
var selected_game_id := "rescue_rush"
var selected_multi_world := 1

func _ready() -> void:
	MultiGameManager.ensure_state()
	super._ready()

func build_home() -> void:
	current_surface = "home"
	_remove_active_game()
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var brand := Label.new()
	brand.text = "UNJAM"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 72)
	brand.add_theme_color_override("font_color", Color("f3fbff"))
	root.add_child(brand)
	var tagline := Label.new()
	tagline.text = "THREE GAMES  •  30,000 LEVELS  •  ONE PROGRESSION"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.add_theme_color_override("font_color", Color("67e8cf"))
	root.add_child(tagline)

	var shared := add_glass_card(root, Vector2(0, 92))
	var shared_label := Label.new()
	shared_label.text = "%d COINS   •   %d PRESTIGE   •   %d ACHIEVEMENT POINTS" % [int(SaveManager.data.get("coins", 0)), int(SaveManager.data.get("prestige_points", 0)), int(SaveManager.data.get("achievement_points", 0))]
	shared_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shared_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shared_label.add_theme_font_size_override("font_size", 19)
	shared.add_child(shared_label)

	var games := VBoxContainer.new()
	games.add_theme_constant_override("separation", 12)
	root.add_child(games)
	_add_game_card(games, "rescue_rush", Color("2dd4b6"), "CHAIN-REACTION RESCUE")
	_add_game_card(games, "water_sort", Color("5da9ff"), "SORT EVERY COLOR")
	_add_game_card(games, "block_puzzle", Color("8b7cf6"), "BUILD, CLEAR, COMBO")

	var daily_title := Label.new()
	daily_title.text = "DAILY CHALLENGES"
	daily_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_title.add_theme_font_size_override("font_size", 18)
	daily_title.add_theme_color_override("font_color", Color("ffd166"))
	root.add_child(daily_title)
	var daily_row := HBoxContainer.new()
	daily_row.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_row.add_theme_constant_override("separation", 10)
	root.add_child(daily_row)
	for game_id in MultiGameManager.GAME_IDS:
		var done := _daily_done(game_id)
		var label := "%s\n%s" % [MultiGameManager.display_name(game_id), "DONE" if done else "+ DAILY REWARD"]
		var daily := make_button(label, Vector2(302, 84), not done)
		daily.add_theme_font_size_override("font_size", 16)
		daily.disabled = done
		daily.pressed.connect(start_game_daily.bind(game_id))
		daily_row.add_child(daily)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 14)
	root.add_child(bottom)
	var collection := make_button("COLLECTION", Vector2(300, 70))
	collection.pressed.connect(build_collection)
	bottom.add_child(collection)
	var settings := make_button("SETTINGS", Vector2(300, 70))
	settings.pressed.connect(build_settings)
	bottom.add_child(settings)
	PremiumVisuals.entrance(root, 0.03)

func _add_game_card(parent: VBoxContainer, game_id: String, accent: Color, subtitle_text: String) -> void:
	var progress := MultiGameManager.progress_for(game_id)
	var panel := add_glass_card(parent, Vector2(0, 196))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name := Label.new()
	name.text = MultiGameManager.display_name(game_id)
	name.add_theme_font_size_override("font_size", 29)
	name.add_theme_color_override("font_color", accent)
	info.add_child(name)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.modulate = Color("95a4bb")
	info.add_child(subtitle)
	var highest := mini(MultiGameManager.CAMPAIGN_LEVELS, int(progress.get("highest_level", 1)))
	var stats := Label.new()
	stats.text = "LEVEL %d / 10,000   •   %d ★   •   %d PERFECT\nWORLD %d / 100   •   %d BADGES" % [highest, MultiGameManager.total_stars(game_id), int(progress.get("perfect_clears", 0)), MultiGameManager.highest_unlocked_world(game_id), (progress.get("world_badges", []) as Array).size()]
	stats.add_theme_font_size_override("font_size", 16)
	stats.modulate = Color("c2cde0")
	info.add_child(stats)
	var controls := VBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)
	row.add_child(controls)
	var play := make_button("PLAY\nLEVEL %d" % highest, Vector2(230, 82), true)
	play.add_theme_font_size_override("font_size", 18)
	play.pressed.connect(open_game_campaign.bind(game_id))
	controls.add_child(play)
	var checkpoint := _checkpoint_for(game_id)
	if not checkpoint.is_empty():
		var resume := make_button("CONTINUE", Vector2(230, 58))
		resume.add_theme_font_size_override("font_size", 16)
		resume.pressed.connect(resume_game.bind(game_id))
		controls.add_child(resume)

func _daily_done(game_id: String) -> bool:
	if game_id == "rescue_rush":
		return DailyChallenge.is_completed_today()
	return MultiGameManager.is_daily_completed(game_id)

func open_game_campaign(game_id: String) -> void:
	selected_game_id = game_id
	selected_multi_world = MultiGameManager.highest_unlocked_world(game_id)
	if game_id == "rescue_rush":
		build_level_select()
	else:
		build_multi_level_select()

func build_level_select() -> void:
	selected_game_id = "rescue_rush"
	current_surface = "levels"
	_remove_active_game()
	super.build_level_select()

func build_multi_level_select() -> void:
	current_surface = "levels"
	_remove_active_game()
	selected_multi_world = clampi(selected_multi_world, 1, MultiGameManager.WORLD_COUNT)
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var back := make_button("←", Vector2(90, 64))
	back.pressed.connect(build_home)
	header.add_child(back)
	var title := Label.new()
	title.text = "%s  •  WORLD %d / 100" % [MultiGameManager.display_name(selected_game_id), selected_multi_world]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	var stars := Label.new()
	stars.text = "%d ★" % MultiGameManager.total_stars(selected_game_id)
	stars.custom_minimum_size = Vector2(120, 64)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(stars)
	var hero := add_glass_card(root, Vector2(0, 96))
	var hero_label := Label.new()
	hero_label.text = "%s\nLEVELS %d–%d" % [MultiGameManager.world_name(selected_game_id, selected_multi_world).to_upper(), MultiGameManager.first_level_in_world(selected_multi_world), MultiGameManager.last_level_in_world(selected_multi_world)]
	hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_label.add_theme_font_size_override("font_size", 21)
	hero.add_child(hero_label)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 12)
	root.add_child(nav)
	var prev := make_button("◀ PREV", Vector2(220, 60))
	prev.disabled = selected_multi_world <= 1
	prev.pressed.connect(_change_multi_world.bind(-1))
	nav.add_child(prev)
	var current := make_button("CURRENT", Vector2(220, 60), true)
	current.pressed.connect(_jump_multi_current)
	nav.add_child(current)
	var next := make_button("NEXT ▶", Vector2(220, 60))
	next.disabled = selected_multi_world >= MultiGameManager.WORLD_COUNT or selected_multi_world > MultiGameManager.highest_unlocked_world(selected_game_id)
	next.pressed.connect(_change_multi_world.bind(1))
	nav.add_child(next)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 11)
	grid.add_theme_constant_override("v_separation", 11)
	scroll.add_child(grid)
	for level_number in range(MultiGameManager.first_level_in_world(selected_multi_world), MultiGameManager.last_level_in_world(selected_multi_world) + 1):
		var unlocked := MultiGameManager.is_level_unlocked(selected_game_id, level_number)
		var level_stars := MultiGameManager.get_stars(selected_game_id, level_number)
		var difficulty := MultiGameManager.difficulty_for_level(level_number)
		var button := make_button("%d\n%s   %s" % [level_number, "★".repeat(level_stars), difficulty_short(difficulty)], Vector2(170, 102), level_number == MultiGameManager.highest_level(selected_game_id))
		button.disabled = not unlocked
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", difficulty_color(difficulty) if unlocked else Color("697387"))
		button.pressed.connect(start_multi_level.bind(selected_game_id, level_number, false))
		grid.add_child(button)

func _change_multi_world(delta: int) -> void:
	selected_multi_world = clampi(selected_multi_world + delta, 1, MultiGameManager.WORLD_COUNT)
	build_multi_level_select()

func _jump_multi_current() -> void:
	selected_multi_world = MultiGameManager.highest_unlocked_world(selected_game_id)
	build_multi_level_select()

func build_collection() -> void:
	current_surface = "collection"
	_remove_active_game()
	super.build_collection()

func build_settings() -> void:
	current_surface = "settings"
	_remove_active_game()
	super.build_settings()

func start_level(level_number: int) -> void:
	selected_game_id = "rescue_rush"
	current_surface = "game"
	_spawn_rescue(level_number, false, {})

func start_daily() -> void:
	start_game_daily("rescue_rush")

func start_game_daily(game_id: String) -> void:
	if _daily_done(game_id):
		build_home()
		return
	selected_game_id = game_id
	if game_id == "rescue_rush":
		_spawn_rescue(1, true, DailyChallenge.build_today())
	else:
		start_multi_level(game_id, MultiGameManager.daily_level(game_id), true)

func start_multi_level(game_id: String, level_number: int, daily: bool = false) -> void:
	selected_game_id = game_id
	current_surface = "game"
	_remove_active_game()
	if content and is_instance_valid(content): content.hide()
	var scene_path := "res://scenes/WaterSort.tscn" if game_id == "water_sort" else "res://scenes/BlockPuzzle.tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Game scene could not be loaded: %s" % scene_path)
		build_home()
		return
	var game_scene := packed.instantiate() as Control
	game_scene.name = "ActiveGame"
	game_scene.level_number = level_number
	game_scene.daily_mode = daily
	game_scene.finished.connect(_on_multi_finished.bind(game_id))
	game_scene.quit_requested.connect(_on_multi_quit.bind(game_id))
	add_child(game_scene)
	game_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_scene.z_index = 100
	active_game = game_scene
	AnalyticsManager.track("game_scene_opened", {"game": game_id, "level": level_number, "daily": daily})

func _spawn_rescue(level_number: int, daily: bool, custom_data: Dictionary) -> void:
	current_surface = "game"
	_remove_active_game()
	if content and is_instance_valid(content): content.hide()
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		build_home()
		return
	var game_scene := packed.instantiate() as Control
	game_scene.name = "ActiveGame"
	game_scene.level_number = level_number
	game_scene.daily_mode = daily
	if not custom_data.is_empty(): game_scene.custom_level_data = custom_data.duplicate(true)
	game_scene.finished.connect(_on_rescue_finished)
	game_scene.quit_requested.connect(_on_rescue_quit)
	add_child(game_scene)
	game_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_scene.z_index = 100
	active_game = game_scene
	AnalyticsManager.track("game_scene_opened", {"game": "rescue_rush", "level": level_number, "daily": daily})

func _remove_active_game() -> void:
	if active_game and is_instance_valid(active_game): active_game.queue_free()
	active_game = null
	var stale := get_node_or_null("ActiveGame")
	if stale and is_instance_valid(stale): stale.queue_free()

func _on_rescue_finished(completed_level: int) -> void:
	active_game = null
	if completed_level < 0:
		build_home()
	elif LevelManager.has_level(completed_level + 1):
		call_deferred("start_level", completed_level + 1)
	else:
		build_home()

func _on_rescue_quit() -> void:
	active_game = null
	build_level_select()

func _on_multi_finished(completed_level: int, game_id: String) -> void:
	active_game = null
	if completed_level < 0:
		build_home()
	elif completed_level < MultiGameManager.CAMPAIGN_LEVELS:
		call_deferred("start_multi_level", game_id, completed_level + 1, false)
	else:
		build_home()

func _on_multi_quit(game_id: String) -> void:
	active_game = null
	selected_game_id = game_id
	selected_multi_world = MultiGameManager.world_for_level(MultiGameManager.highest_level(game_id))
	build_multi_level_select()

func _checkpoint_for(game_id: String) -> Dictionary:
	if game_id == "rescue_rush":
		return SaveManager.data.get("active_run", {})
	return MultiGameManager.load_checkpoint(game_id)

func resume_game(game_id: String) -> void:
	var checkpoint := _checkpoint_for(game_id)
	if checkpoint.is_empty():
		open_game_campaign(game_id)
		return
	if game_id == "rescue_rush":
		var custom: Dictionary = {}
		if bool(checkpoint.get("daily", false)) and checkpoint.get("level_data", {}) is Dictionary:
			custom = (checkpoint.get("level_data", {}) as Dictionary).duplicate(true)
		_spawn_rescue(int(checkpoint.get("level", 1)), bool(checkpoint.get("daily", false)), custom)
	else:
		start_multi_level(game_id, int(checkpoint.get("level", 1)), bool(checkpoint.get("daily", false)))
	AnalyticsManager.track("resume_selected", {"game": game_id, "level": int(checkpoint.get("level", 1))})