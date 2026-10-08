extends "res://scripts/ui/main.gd"

signal surface_changed(surface: String)

var _current_surface := "home"
var _surface_emit_pending := false
# Generation prevents a deferred win animation from reopening gameplay after
# the player presses Back, changes game, or navigates to another surface.
var _navigation_generation := 0
var _pending_game_launch: Dictionary = {}
# The active scenes have GDScript preloads of SVG art. Register their imported
# textures on the main thread once before dispatching a threaded scene load;
# otherwise cold worker compilation can fail to resolve those textures.
var _game_scene_art_ready := false
var _game_scene_art_cache: Array[Texture2D] = []
var _ready_game_scenes: Dictionary = {}
var _game_scene_script_cache: Dictionary = {}
const GAME_SCENE_SCRIPT_DEPENDENCIES := {
	"res://scenes/Game.tscn":"res://scripts/game/rescue_rush_assisted.gd",
	"res://scenes/WaterSort.tscn":"res://scripts/game/water_sort_10000.gd",
	"res://scenes/BlockPuzzle.tscn":"res://scripts/game/block_puzzle_10000.gd",
}
const GAME_SCENE_ART_DEPENDENCIES := [
	"res://assets/art/gameplay/water_screen_overlay.svg",
	"res://assets/art/gameplay/rescue_screen_overlay.svg",
	"res://assets/art/fx/spark.svg",
]
var current_surface: String:
	get:
		return _current_surface
	set(value):
		# Leaving a pending Daily before scene instantiation must restore its
		# parked campaign checkpoint, just like exiting a running Daily.
		if _current_surface == "game_loading" and value not in ["game_loading", "game"] and not _pending_game_launch.is_empty():
			var abandoned: Dictionary = _pending_game_launch.duplicate()
			_pending_game_launch.clear()
			if bool(abandoned.get("daily",false)):
				_restore_campaign_checkpoint_after_daily(String(abandoned.get("game_id","")))
		_navigation_generation += 1
		_current_surface = value
		if has_method("_sync_persistent_surfaces_now"):
			call("_sync_persistent_surfaces_now", value)
		_queue_surface_changed()
var active_game: Control
var selected_game_id := "rescue_rush"
var selected_multi_world := 1
var selected_multi_page := 1
var _last_calendar_day := ""
const MULTI_LEVEL_PAGE_SIZE := 100
const RESCUE_GAME_SCENE_PATH := "res://scenes/Game.tscn"
const WATER_GAME_SCENE_PATH := "res://scenes/WaterSort.tscn"
const BLOCK_GAME_SCENE_PATH := "res://scenes/BlockPuzzle.tscn"
const DAILY_CAMPAIGN_BACKUPS_KEY := "daily_campaign_checkpoint_backups"
func _ready() -> void:
	MultiGameManager.ensure_state()
	_last_calendar_day = DailyChallenge.date_key()
	super._ready()
	_queue_surface_changed()
	# Startup branding is owned by Boot.tscn. No full-screen startup control
	# is ever placed over the interactive Home scene.

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		_refresh_day_sensitive_surface(DailyChallenge.date_key())


func _refresh_day_sensitive_surface(today_key: String) -> void:
	if today_key.is_empty():
		return
	if _last_calendar_day.is_empty():
		_last_calendar_day = today_key
		return
	if today_key == _last_calendar_day:
		return
	_last_calendar_day = today_key
	# A phone can remain open across midnight. Refresh only date-sensitive
	# launcher surfaces so yesterday's Daily completion/reward state is never
	# shown after the app returns to the foreground.
	if current_surface == "home":
		call_deferred("build_home")
	elif current_surface == "daily" and has_method("build_daily_games"):
		call_deferred("build_daily_games")
	elif current_surface == "compete" and has_method("build_compete_leaderboard"):
		call_deferred("build_compete_leaderboard")


func _prime_game_scene(path: String) -> void:
	if not _game_scene_art_ready:
		for asset_path in GAME_SCENE_ART_DEPENDENCIES:
			var texture := load(asset_path) as Texture2D
			if texture != null:
				_game_scene_art_cache.append(texture)
		_game_scene_art_ready = true
	# Scene scripts and their inherited GDScript chain must be compiled on the
	# UI thread before a background .tscn parse. Worker-side GDScript reload
	# can orphan RefCounted resources when many loads are cancelled.
	if not _game_scene_script_cache.has(path):
		var script_path := String(GAME_SCENE_SCRIPT_DEPENDENCIES.get(path,""))
		var compiled := load(script_path) as Script if not script_path.is_empty() else null
		if compiled != null:
			_game_scene_script_cache[path] = compiled
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path)

func _game_scene_resource(path: String) -> PackedScene:
	# Important: load_threaded_get() BLOCKS the caller until completion when
	# called during THREAD_LOAD_IN_PROGRESS. Never invoke that on the UI thread.
	var ready := _ready_game_scenes.get(path,null) as PackedScene
	if ready != null:
		return ready
	var cached := ResourceLoader.get_cached_ref(path) as PackedScene
	if cached != null:
		return cached
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path) as PackedScene
	return null

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


func _daily_done(game_id: String) -> bool:
	if game_id == "rescue_rush":
		return DailyChallenge.is_completed_today()
	return MultiGameManager.is_daily_completed(game_id)

func open_game_campaign(game_id: String) -> void:
	# Recover any campaign checkpoint that was temporarily parked for a Daily
	# attempt. Choose Game still opens the campaign browser; it never resumes.
	_restore_campaign_checkpoint_after_daily(game_id)
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
	_prime_game_scene(RESCUE_GAME_SCENE_PATH)
	super.build_level_select()

func build_multi_level_select() -> void:
	current_surface = "levels"
	_remove_active_game()
	_prime_game_scene(WATER_GAME_SCENE_PATH if selected_game_id == "water_sort" else BLOCK_GAME_SCENE_PATH)
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
	title.text = "%s  •  %s %d / %d" % [MultiGameManager.display_name(selected_game_id), MultiGameManager.progression_scope_label(selected_game_id), selected_multi_world, MultiGameManager.world_count_for(selected_game_id)]
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
		if has_method("build_daily_games"):
			call("build_daily_games")
		else:
			build_home()
		return
	if not MultiGameManager.claim_daily_game(game_id):
		FeedbackManager.blocked()
		if has_method("build_daily_games"):
			call("build_daily_games")
		else:
			build_home()
		return
	selected_game_id = game_id
	# Daily challenges are one-shot daily surfaces, not resumable campaign runs.
	# Rescue Daily never reads/writes the campaign checkpoint, so preserve it.
	# Water/Block share a checkpoint slot with campaign; park that checkpoint
	# before Daily starts and restore it when the Daily attempt ends.
	if game_id == "rescue_rush":
		_spawn_rescue(1, true, DailyChallenge.build_today())
	else:
		_stash_campaign_checkpoint_for_daily(game_id)
		start_multi_level(game_id, MultiGameManager.daily_level(game_id), true)

func start_multi_level(game_id: String, level_number: int, daily: bool = false) -> void:
	start_multi_level_mode(game_id, level_number, daily, "campaign")

func start_multi_level_mode(game_id: String, level_number: int, daily: bool = false, mode: String = "campaign") -> void:
	selected_game_id = game_id
	var scene_path := WATER_GAME_SCENE_PATH if game_id == "water_sort" else BLOCK_GAME_SCENE_PATH
	_begin_game_scene_launch(scene_path, {"game_id":game_id,"level":level_number,"daily":daily,"mode":mode})

func start_block_mode(mode: String) -> void:
	var safe_mode := mode if mode in ["endless", "zen", "extreme"] else "campaign"
	var level := clampi(MultiGameManager.highest_level("block_puzzle"), 1, MultiGameManager.CAMPAIGN_LEVELS)
	start_multi_level_mode("block_puzzle", level, false, safe_mode)

func _spawn_rescue(level_number: int, daily: bool, custom_data: Dictionary) -> void:
	selected_game_id = "rescue_rush"
	_begin_game_scene_launch(RESCUE_GAME_SCENE_PATH, {"game_id":"rescue_rush","level":level_number,"daily":daily,"custom_data":custom_data.duplicate(true)})

func _begin_game_scene_launch(path: String, config: Dictionary) -> void:
	# Cached scenes still start synchronously. Cold loads use Godot's threaded
	# loader and poll between frames, never blocking navigation on an in-progress
	# background resource request.
	_remove_active_game()
	var packed := _game_scene_resource(path)
	if packed != null:
		_ready_game_scenes[path] = packed
		_pending_game_launch.clear()
		_instantiate_game_scene(packed,config)
		return
	current_surface = "game_loading"
	_pending_game_launch = config.duplicate(true)
	_show_game_loading(config)
	_prime_game_scene(path)
	var generation := _navigation_generation
	call_deferred("_await_game_scene",path,config.duplicate(true),generation)

func _show_game_loading(config: Dictionary) -> void:
	clear_content()
	content.visible = true
	content.mouse_filter = Control.MOUSE_FILTER_STOP
	var tint := ColorRect.new()
	tint.color = Color("#0c1729")
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(tint)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(center)
	var panel := VBoxContainer.new()
	panel.name = "GameLoadingCard"
	panel.add_theme_constant_override("separation",20)
	panel.custom_minimum_size = Vector2(280,180)
	center.add_child(panel)
	var label := Label.new()
	label.name = "GameLoadingMessage"
	label.text = "OPENING %s…" % MultiGameManager.display_name(String(config.get("game_id","rescue_rush"))).to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color",Color("#f1fbff"))
	label.accessibility_name = label.text
	panel.add_child(label)
	var progress := ProgressBar.new()
	progress.name = "GameLoadingProgress"
	progress.min_value = 0
	progress.max_value = 1
	progress.value = 0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0,12)
	panel.add_child(progress)
	var cancel := Button.new()
	cancel.name = "GameLoadingCancel"
	cancel.text = "BACK"
	cancel.custom_minimum_size = Vector2(0,56)
	cancel.focus_mode = Control.FOCUS_ALL
	cancel.accessibility_name = "Cancel loading and return"
	cancel.pressed.connect(_cancel_game_loading)
	panel.add_child(cancel)
	var retry := Button.new()
	retry.name = "GameLoadingRetry"
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(0,56)
	retry.visible = false
	retry.pressed.connect(_retry_game_loading)
	panel.add_child(retry)

func _cancel_game_loading() -> void:
	if current_surface != "game_loading":
		return
	var config := _pending_game_launch.duplicate(true)
	if bool(config.get("daily",false)):
		_return_from_daily(String(config.get("game_id","")))
	elif String(config.get("game_id","")) in MultiGameManager.GAME_IDS:
		open_game_campaign(String(config["game_id"]))
	else:
		build_home()

func _retry_game_loading() -> void:
	if current_surface != "game_loading":
		return
	var config := _pending_game_launch.duplicate(true)
	var path := RESCUE_GAME_SCENE_PATH if String(config.get("game_id","")) == "rescue_rush" else (WATER_GAME_SCENE_PATH if String(config.get("game_id","")) == "water_sort" else BLOCK_GAME_SCENE_PATH)
	_begin_game_scene_launch(path,config)

func _await_game_scene(path: String, config: Dictionary, generation: int) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while is_inside_tree():
		var stale := generation != _navigation_generation or current_surface != "game_loading"
		# Another request may have drained the same ResourceLoader token. Hold
		# that parsed PackedScene in app memory to satisfy the newest request.
		var retained := _ready_game_scenes.get(path,null) as PackedScene
		if retained != null:
			if not stale:
				_pending_game_launch.clear()
				_instantiate_game_scene(retained,config)
			return
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path,progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Even a cancelled launch must consume the completed background result.
			# Returning early would strand the ResourceLoader load token and leak
			# imported SVG/game resources after repeated Back/Home navigation.
			var packed := ResourceLoader.load_threaded_get(path) as PackedScene
			if packed != null:
				_ready_game_scenes[path] = packed
			if stale:
				return
			if packed != null:
				_pending_game_launch.clear()
				_instantiate_game_scene(packed,config)
			else:
				_show_game_loading_error("Could not open this game. Try again or go back.")
			return
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			if not stale:
				_show_game_loading_error("Game data could not be loaded. Retry or go back.")
			return
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			if stale:
				return
			var cached := ResourceLoader.get_cached_ref(path) as PackedScene
			if cached != null:
				_ready_game_scenes[path] = cached
				_pending_game_launch.clear()
				_instantiate_game_scene(cached,config)
				return
			if ResourceLoader.load_threaded_request(path) != OK:
				_show_game_loading_error("Game data is unavailable. Retry or go back.")
				return
		if not stale:
			var bar := content.find_child("GameLoadingProgress",true,false) as ProgressBar if content != null else null
			if bar != null and not progress.is_empty():
				bar.value = clampf(float(progress[0]),0.0,1.0)
			if Time.get_ticks_msec() > deadline:
				_show_game_loading_error("Loading is taking too long. Retry or go back.")
				# Keep draining in the background: a timed-out request is still owned
				# by ResourceLoader until it completes and the result is collected.
		await get_tree().process_frame

func _show_game_loading_error(message: String) -> void:
	var label := content.find_child("GameLoadingMessage",true,false) as Label if content != null else null
	if label != null:
		label.text = message
		label.accessibility_name = message
	var retry := content.find_child("GameLoadingRetry",true,false) as Button if content != null else null
	if retry != null:
		retry.visible = true

func _instantiate_game_scene(packed: PackedScene, config: Dictionary) -> void:
	var game_scene := packed.instantiate() as Control
	if game_scene == null:
		_show_game_loading_error("This game could not start. Try again.")
		return
	var game_id := String(config.get("game_id","rescue_rush"))
	var level_number := int(config.get("level",1))
	var daily := bool(config.get("daily",false))
	var mode := String(config.get("mode","campaign"))
	game_scene.name = "ActiveGame"
	game_scene.level_number = level_number
	game_scene.daily_mode = daily
	if game_id == "block_puzzle":
		game_scene.set("play_mode",mode)
	elif game_id == "rescue_rush":
		var custom: Dictionary = config.get("custom_data",{})
		if not custom.is_empty():
			game_scene.custom_level_data = custom.duplicate(true)
	game_scene.set_meta("unjam_game_id",game_id)
	game_scene.set_meta("unjam_level_number",level_number)
	game_scene.set_meta("unjam_daily_mode",daily)
	if game_id == "rescue_rush":
		game_scene.finished.connect(_on_rescue_finished.bind(daily))
		game_scene.quit_requested.connect(_on_rescue_quit.bind(game_scene,daily))
	else:
		game_scene.finished.connect(_on_multi_finished.bind(game_id,daily))
		game_scene.quit_requested.connect(_on_multi_quit.bind(game_scene,game_id,daily))
	current_surface = "game"
	if content != null and is_instance_valid(content):
		content.hide()
	add_child(game_scene)
	game_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_scene.z_index = 100
	active_game = game_scene
	AnalyticsManager.track("game_scene_opened",{"game":game_id,"level":level_number,"daily":daily,"mode":mode})

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

func _return_from_daily(game_id: String = "") -> void:
	if not game_id.is_empty():
		_restore_campaign_checkpoint_after_daily(game_id)
	if has_method("build_daily_games"):
		call("build_daily_games")
	else:
		build_home()

func _daily_checkpoint_backups() -> Dictionary:
	var raw = SaveManager.data.get(DAILY_CAMPAIGN_BACKUPS_KEY, {})
	return raw.duplicate(true) if raw is Dictionary else {}

func _stash_campaign_checkpoint_for_daily(game_id: String) -> void:
	if game_id == "rescue_rush":
		return
	var backups := _daily_checkpoint_backups()
	var checkpoint := MultiGameManager.checkpoint(game_id)
	# Never promote a stale Daily checkpoint into the campaign backup slot.
	if not checkpoint.is_empty() and not bool(checkpoint.get("daily", false)):
		backups[game_id] = checkpoint.duplicate(true)
	else:
		backups.erase(game_id)
	SaveManager.data[DAILY_CAMPAIGN_BACKUPS_KEY] = backups
	MultiGameManager.clear_checkpoint(game_id)
	SaveManager.save()

func _restore_campaign_checkpoint_after_daily(game_id: String) -> void:
	if game_id == "rescue_rush":
		return
	var backups := _daily_checkpoint_backups()
	if not backups.has(game_id):
		# Remove only a stale Daily checkpoint; keep a normal campaign checkpoint.
		var current := MultiGameManager.checkpoint(game_id)
		if bool(current.get("daily", false)):
			MultiGameManager.clear_checkpoint(game_id)
		return
	var backup = backups.get(game_id, {})
	MultiGameManager.clear_checkpoint(game_id)
	if backup is Dictionary and not (backup as Dictionary).is_empty():
		MultiGameManager.save_checkpoint(game_id, (backup as Dictionary).duplicate(true))
	backups.erase(game_id)
	SaveManager.data[DAILY_CAMPAIGN_BACKUPS_KEY] = backups
	SaveManager.save()

func _game_context(game: Control, fallback_game_id: String, fallback_daily: bool = false) -> Dictionary:
	var game_id := fallback_game_id
	var level_number := -1
	var was_daily := fallback_daily
	if game != null and is_instance_valid(game):
		if game.has_meta("unjam_game_id"):
			game_id = String(game.get_meta("unjam_game_id"))
		var level_value = game.get("level_number")
		if level_value != null:
			level_number = int(level_value)
		if game.has_meta("unjam_level_number"):
			level_number = int(game.get_meta("unjam_level_number"))
		var daily_value = game.get("daily_mode")
		if daily_value != null:
			was_daily = bool(daily_value)
		if game.has_meta("unjam_daily_mode"):
			was_daily = bool(game.get_meta("unjam_daily_mode"))
	return {
		"game_id": game_id,
		"level_number": level_number,
		"was_daily": was_daily,
	}


func _active_game_context() -> Dictionary:
	var game := active_game
	if game == null or not is_instance_valid(game):
		game = get_node_or_null("ActiveGame") as Control
	return _game_context(game, selected_game_id, false)


func _return_from_game(game_id: String, was_daily: bool, level_number: int = -1) -> void:
	_remove_active_game()
	if was_daily:
		_return_from_daily(game_id)
		return
	if game_id == "rescue_rush":
		selected_game_id = "rescue_rush"
		if level_number > 0:
			selected_world = LevelManager.world_for_level(level_number)
		build_level_select()
		return
	if game_id not in ["water_sort", "block_puzzle"]:
		build_home()
		return
	selected_game_id = game_id
	var target_level := level_number if level_number > 0 else MultiGameManager.highest_level(game_id)
	selected_multi_world = MultiGameManager.world_for_game_level(game_id, target_level)
	selected_multi_page = _multi_page_for_level(game_id, target_level)
	build_multi_level_select()


func force_back_from_game() -> void:
	if current_surface == "game_loading":
		_cancel_game_loading()
		return
	# System Back and every in-game Back control resolve from the game that is
	# actually open, never from a selector value that may have changed behind it.
	var context := _active_game_context()
	_return_from_game(
		String(context.get("game_id", selected_game_id)),
		bool(context.get("was_daily", false)),
		int(context.get("level_number", -1))
	)

func _submit_completed_daily_rank(game_id: String) -> void:
	# Only completed daily puzzles, never exits or failed daily attempts, enter
	# the competition. The server uses one entry per player/game/calendar day.
	if not _daily_done(game_id) or active_game == null or not is_instance_valid(active_game):
		return
	if active_game.has_meta("unjam_daily_rank_submitted"):
		return
	var game := active_game
	var metrics: Dictionary = {}
	if game_id == "rescue_rush":
		var moves := maxi(1, int(game.get("moves")))
		var par := maxi(1, int(game.get("par_moves")))
		var mistakes := maxi(0, int(game.get("mistakes_this_level")))
		var hints := maxi(0, int(game.get("hints_used_this_level")))
		var undos := maxi(0, int(game.get("undos_used_this_level")))
		var penalty := mistakes + hints + undos
		var stars := 1 if penalty > 1 or moves > par + 3 else (2 if penalty > 0 or moves > par else 3)
		metrics = {"stars": stars, "moves": moves, "par": par, "mistakes": mistakes, "hints": hints, "undos": undos}
	elif game_id == "water_sort":
		var moves := maxi(1, int(game.get("moves")))
		var par := maxi(1, int(game.get("par_moves")))
		var colours := maxi(1, int(game.get("color_count")))
		var stars := 3 if moves <= par else (2 if moves <= par + maxi(6, colours) else 1)
		metrics = {"stars": stars, "moves": moves, "par": par}
	elif game_id == "block_puzzle":
		var placements := maxi(1, int(game.get("placements")))
		var par := maxi(1, int(game.get("par_placements")))
		var stars := 3 if placements <= par else (2 if placements <= par + 6 else 1)
		metrics = {
			"stars": stars, "placements": placements, "par": par,
			"score": maxi(0, int(game.get("score"))),
			"lines": maxi(0, int(game.get("lines_cleared")))
		}
	else:
		return
	game.set_meta("unjam_daily_rank_submitted", true)
	CompetitionManager.submit_daily_result(game_id, metrics)


func _on_rescue_finished(completed_level: int, was_daily: bool = false) -> void:
	if was_daily:
		_submit_completed_daily_rank("rescue_rush")
	active_game = null
	if was_daily:
		_return_from_daily("rescue_rush")
	elif completed_level < 0:
		build_home()
	elif LevelManager.has_level(completed_level + 1):
		call_deferred("_advance_if_still_in_game", "rescue_rush", completed_level + 1, _navigation_generation)
	else:
		build_home()

func _on_rescue_quit(source_game: Control, was_daily: bool = false) -> void:
	if active_game != null and is_instance_valid(active_game) and source_game != active_game:
		return
	var context := _game_context(source_game, "rescue_rush", was_daily)
	_return_from_game(
		String(context.get("game_id", "rescue_rush")),
		bool(context.get("was_daily", was_daily)),
		int(context.get("level_number", -1))
	)

func _on_multi_finished(completed_level: int, game_id: String, was_daily: bool = false) -> void:
	if was_daily:
		_submit_completed_daily_rank(game_id)
	active_game = null
	if was_daily:
		_return_from_daily(game_id)
	elif completed_level < 0:
		build_home()
	elif completed_level < MultiGameManager.CAMPAIGN_LEVELS:
		call_deferred("_advance_if_still_in_game", game_id, completed_level + 1, _navigation_generation)
	else:
		build_home()

func _advance_if_still_in_game(game_id: String, next_level: int, generation: int) -> void:
	# Win callbacks may race with Back, a Home shortcut, or another game launch.
	# No old deferred callback may open an unwanted scene or overwrite a newer
	# daily/campaign checkpoint when navigation has already moved on.
	if not is_inside_tree() or generation != _navigation_generation or current_surface != "game":
		return
	if active_game != null and is_instance_valid(active_game):
		return
	if selected_game_id != game_id:
		return
	if next_level < 1 or next_level > MultiGameManager.CAMPAIGN_LEVELS:
		return
	if game_id == "rescue_rush":
		start_level(next_level)
	elif game_id in ["water_sort", "block_puzzle"]:
		start_multi_level(game_id, next_level, false)


func _on_multi_quit(source_game: Control, game_id: String, was_daily: bool = false) -> void:
	if active_game != null and is_instance_valid(active_game) and source_game != active_game:
		return
	var context := _game_context(source_game, game_id, was_daily)
	_return_from_game(
		String(context.get("game_id", game_id)),
		bool(context.get("was_daily", was_daily)),
		int(context.get("level_number", -1))
	)

func _checkpoint_for(game_id: String) -> Dictionary:
	var checkpoint: Dictionary = SaveManager.data.get("active_run", {}) if game_id == "rescue_rush" else MultiGameManager.checkpoint(game_id)
	if bool(checkpoint.get("daily", false)):
		return {}
	return checkpoint

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
