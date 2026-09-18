extends "res://scripts/ui/main.gd"

signal surface_changed(surface: String)

var _current_surface := "home"
var _surface_emit_pending := false
var current_surface: String:
	get:
		return _current_surface
	set(value):
		_current_surface = value
		if has_method("_sync_persistent_surfaces_now"):
			call("_sync_persistent_surfaces_now", value)
		_queue_surface_changed()
var active_game: Control
var selected_game_id := "rescue_rush"
var selected_multi_world := 1
var selected_multi_page := 1
const MULTI_LEVEL_PAGE_SIZE := 100

func _ready() -> void:
	MultiGameManager.ensure_state()
	super._ready()
	_queue_surface_changed()

func _multi_page_count(game_id: String, world: int) -> int:
	var first := MultiGameManager.first_level_in_game_world(game_id, world)
	var last := MultiGameManager.last_level_in_game_world(game_id, world)
	return maxi(1, ceili(float(last - first + 1) / float(MULTI_LEVEL_PAGE_SIZE)))

func _multi_page_for_level(game_id: String, level: int) -> int:
	var world := MultiGameManager.world_for_game_level(game_id, level)
	var first := MultiGameManager.first_level_in_game_world(game_id, world)
	return clampi(int((level - first) / MULTI_LEVEL_PAGE_SIZE) + 1, 1, _multi_page_count(game_id, world))

func _multi_page_bounds(game_id: String, world: int, page: int) -> Vector2i:
	var world_first := MultiGameManager.first_level_in_game_world(game_id, world)
	var world_last := MultiGameManager.last_level_in_game_world(game_id, world)
	var first := world_first + (clampi(page, 1, _multi_page_count(game_id, world)) - 1) * MULTI_LEVEL_PAGE_SIZE
	return Vector2i(first, mini(first + MULTI_LEVEL_PAGE_SIZE - 1, world_last))

func _queue_surface_changed() -> void:
	if _surface_emit_pending:
		return
	_surface_emit_pending = true
	call_deferred("_emit_surface_changed")

func _emit_surface_changed() -> void:
	_surface_emit_pending = false
	if not is_inside_tree():
		return
	surface_changed.emit(_current_surface)

func build_home() -> void:
	current_surface = "home"
	_remove_active_game()
	clear_content()
	# PremiumHome is the only interactive home surface. Keep the legacy content
	# container inert so it can never intercept touches behind the launcher.
	if has_node("PremiumHome"):
		content.visible = false
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	add_background()

func _add_journey_card(parent: VBoxContainer) -> void:
	var completed_total := 0
	var perfect_total := 0
	for game_id in MultiGameManager.GAME_IDS:
		var progress := MultiGameManager.progress_for(game_id)
		completed_total += int(progress.get("levels_completed", 0))
		perfect_total += int(progress.get("perfect_clears", 0))
	var journey := add_glass_card(parent, Vector2(0, 142))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	journey.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = "UNJAM JOURNEY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("67e8cf"))
	box.add_child(title)
	var summary := Label.new()
	summary.text = "%d / 30,000 LEVELS CLEARED   •   %d PERFECT CLEARS" % [completed_total, perfect_total]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 16)
	summary.add_theme_color_override("font_color", Color("c2cde0"))
	box.add_child(summary)
	var progress_bar := ProgressBar.new()
	progress_bar.max_value = 30000.0
	progress_bar.value = float(completed_total)
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 18)
	progress_bar.add_theme_stylebox_override("background", style_box(Color("13243d"), 9))
	progress_bar.add_theme_stylebox_override("fill", style_box(Color("21c7a8"), 9))
	box.add_child(progress_bar)

func _add_game_card(parent: VBoxContainer, game_id: String, accent: Color, subtitle_text: String) -> void:
	var progress := MultiGameManager.progress_for(game_id)
	var panel := add_glass_card(parent, Vector2(0, 224))
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
	stats.text = "LEVEL %d / 10,000   •   %d ★   •   %d PERFECT\nWORLD %d / %d   •   %d BADGES" % [highest, MultiGameManager.total_stars(game_id), int(progress.get("perfect_clears", 0)), MultiGameManager.highest_unlocked_game_world(game_id), MultiGameManager.world_count_for(game_id), (progress.get("world_badges", []) as Array).size()]
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
	var highest := MultiGameManager.highest_level(game_id)
	selected_multi_world = MultiGameManager.highest_unlocked_game_world(game_id)
	selected_multi_page = _multi_page_for_level(game_id, highest)
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
	selected_multi_world = clampi(selected_multi_world, 1, MultiGameManager.world_count_for(selected_game_id))
	selected_multi_page = clampi(selected_multi_page, 1, _multi_page_count(selected_game_id, selected_multi_world))
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var back := make_button("←", Vector2(126, 86))
	back.add_theme_font_size_override("font_size", 30)
	back.pressed.connect(build_home)
	header.add_child(back)
	var title := Label.new()
	title.text = "%s  •  WORLD %d / %d" % [MultiGameManager.display_name(selected_game_id), selected_multi_world, MultiGameManager.world_count_for(selected_game_id)]
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
	var page_bounds := _multi_page_bounds(selected_game_id, selected_multi_world, selected_multi_page)
	var page_count := _multi_page_count(selected_game_id, selected_multi_world)
	hero_label.text = "%s\nLEVELS %d–%d   •   SET %d/%d" % [MultiGameManager.world_name(selected_game_id, selected_multi_world).to_upper(), page_bounds.x, page_bounds.y, selected_multi_page, page_count]
	hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_label.add_theme_font_size_override("font_size", 21)
	hero.add_child(hero_label)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 12)
	root.add_child(nav)
	var prev := make_button("◀ PREV", Vector2(220, 60))
	prev.disabled = selected_multi_world <= 1 and selected_multi_page <= 1
	prev.pressed.connect(_change_multi_page.bind(-1))
	nav.add_child(prev)
	var current := make_button("CURRENT", Vector2(220, 60), true)
	current.pressed.connect(_jump_multi_current)
	nav.add_child(current)
	var next := make_button("NEXT ▶", Vector2(220, 60))
	next.disabled = selected_multi_world >= MultiGameManager.world_count_for(selected_game_id) and selected_multi_page >= _multi_page_count(selected_game_id, selected_multi_world)
	next.pressed.connect(_change_multi_page.bind(1))
	nav.add_child(next)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 11)
	grid.add_theme_constant_override("v_separation", 11)
	scroll.add_child(grid)
	var visible_bounds := _multi_page_bounds(selected_game_id, selected_multi_world, selected_multi_page)
	for level_number in range(visible_bounds.x, visible_bounds.y + 1):
		var unlocked := MultiGameManager.is_level_unlocked(selected_game_id, level_number)
		var level_stars := MultiGameManager.get_stars(selected_game_id, level_number)
		var difficulty := MultiGameManager.difficulty_for_game(selected_game_id, level_number)
		var button := make_button("%d\n%s   %s" % [level_number, "★".repeat(level_stars), difficulty_short(difficulty)], Vector2(170, 102), level_number == MultiGameManager.highest_level(selected_game_id))
		button.disabled = not unlocked
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", difficulty_color(difficulty) if unlocked else Color("697387"))
		button.pressed.connect(start_multi_level.bind(selected_game_id, level_number, false))
		grid.add_child(button)

func _change_multi_page(delta: int) -> void:
	if delta < 0:
		if selected_multi_page > 1:
			selected_multi_page -= 1
		elif selected_multi_world > 1:
			selected_multi_world -= 1
			selected_multi_page = _multi_page_count(selected_game_id, selected_multi_world)
	elif delta > 0:
		var pages := _multi_page_count(selected_game_id, selected_multi_world)
		if selected_multi_page < pages:
			selected_multi_page += 1
		elif selected_multi_world < MultiGameManager.world_count_for(selected_game_id):
			selected_multi_world += 1
			selected_multi_page = 1
	build_multi_level_select()

func _change_multi_world(delta: int) -> void:
	# Compatibility entry point for older callers: move to the adjacent world.
	selected_multi_world = clampi(selected_multi_world + delta, 1, MultiGameManager.world_count_for(selected_game_id))
	selected_multi_page = 1
	build_multi_level_select()

func _jump_multi_current() -> void:
	var highest := MultiGameManager.highest_level(selected_game_id)
	selected_multi_world = MultiGameManager.highest_unlocked_game_world(selected_game_id)
	selected_multi_page = _multi_page_for_level(selected_game_id, highest)
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
	start_multi_level_mode(game_id, level_number, daily, "campaign")

func start_multi_level_mode(game_id: String, level_number: int, daily: bool = false, mode: String = "campaign") -> void:
	selected_game_id = game_id
	current_surface = "game"
	_remove_active_game()
	if content and is_instance_valid(content):
		content.hide()
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
	if game_id == "block_puzzle":
		game_scene.set("play_mode", mode)
	game_scene.finished.connect(_on_multi_finished.bind(game_id))
	game_scene.quit_requested.connect(_on_multi_quit.bind(game_id))
	add_child(game_scene)
	game_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_scene.z_index = 100
	active_game = game_scene
	AnalyticsManager.track("game_scene_opened", {"game": game_id, "level": level_number, "daily": daily, "mode": mode})

func start_block_mode(mode: String) -> void:
	var safe_mode := mode if mode in ["endless", "zen", "extreme"] else "campaign"
	var level := clampi(MultiGameManager.highest_level("block_puzzle"), 1, MultiGameManager.CAMPAIGN_LEVELS)
	start_multi_level_mode("block_puzzle", level, false, safe_mode)

func _spawn_rescue(level_number: int, daily: bool, custom_data: Dictionary) -> void:
	current_surface = "game"
	_remove_active_game()
	if content and is_instance_valid(content):
		content.hide()
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		build_home()
		return
	var game_scene := packed.instantiate() as Control
	game_scene.name = "ActiveGame"
	game_scene.level_number = level_number
	game_scene.daily_mode = daily
	if not custom_data.is_empty():
		game_scene.custom_level_data = custom_data.duplicate(true)
	game_scene.finished.connect(_on_rescue_finished)
	game_scene.quit_requested.connect(_on_rescue_quit)
	add_child(game_scene)
	game_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_scene.z_index = 100
	active_game = game_scene

func _remove_active_game() -> void:
	if active_game and is_instance_valid(active_game):
		if active_game.get_parent() == self:
			remove_child(active_game)
		active_game.queue_free()
	active_game = null
	var stale := get_node_or_null("ActiveGame")
	if stale and is_instance_valid(stale):
		if stale.get_parent() == self:
			remove_child(stale)
		stale.queue_free()

func force_back_from_game() -> void:
	# Android back must never depend on the active game's animation/busy state.
	var game_id := selected_game_id
	_remove_active_game()
	if game_id == "rescue_rush":
		build_level_select()
	else:
		selected_game_id = game_id
		selected_multi_world = MultiGameManager.world_for_game_level(game_id, MultiGameManager.highest_level(game_id))
		selected_multi_page = _multi_page_for_level(game_id, MultiGameManager.highest_level(game_id))
		build_multi_level_select()

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
	selected_multi_world = MultiGameManager.world_for_game_level(game_id, MultiGameManager.highest_level(game_id))
	selected_multi_page = _multi_page_for_level(game_id, MultiGameManager.highest_level(game_id))
	build_multi_level_select()

func _checkpoint_for(game_id: String) -> Dictionary:
	if game_id == "rescue_rush":
		return SaveManager.data.get("active_run", {})
	return MultiGameManager.checkpoint(game_id)

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
		var mode := "campaign"
		if game_id == "block_puzzle":
			mode = String(checkpoint.get("play_mode", "campaign"))
		start_multi_level_mode(game_id, int(checkpoint.get("level", 1)), bool(checkpoint.get("daily", false)), mode)
