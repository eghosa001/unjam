extends "res://scripts/ui/main.gd"

var continue_button: Button
var current_surface := "home"
var active_game: Control

func _ready() -> void:
	super._ready()
	_create_continue_button()
	set_process(true)

func build_home() -> void:
	current_surface = "home"
	_remove_active_game()
	super.build_home()

func build_level_select() -> void:
	current_surface = "levels"
	_remove_active_game()
	super.build_level_select()

func build_collection() -> void:
	current_surface = "collection"
	_remove_active_game()
	super.build_collection()

func build_settings() -> void:
	current_surface = "settings"
	_remove_active_game()
	super.build_settings()

func start_level(level_number: int) -> void:
	current_surface = "game"
	_spawn_game(level_number, false, {})

func start_daily() -> void:
	if DailyChallenge.is_completed_today():
		current_surface = "home"
		super.start_daily()
		return
	current_surface = "game"
	_spawn_game(1, true, DailyChallenge.build_today())

func _spawn_game(level_number: int, daily: bool, custom_data: Dictionary) -> void:
	_remove_active_game()
	if content and is_instance_valid(content):
		content.hide()
	if continue_button and is_instance_valid(continue_button):
		continue_button.hide()
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		push_error("Game scene could not be loaded.")
		current_surface = "levels"
		if content and is_instance_valid(content):
			content.show()
		return
	var game_scene := packed.instantiate() as Control
	if game_scene == null:
		push_error("Game scene could not be instantiated.")
		current_surface = "levels"
		if content and is_instance_valid(content):
			content.show()
		return
	game_scene.name = "ActiveGame"
	game_scene.level_number = level_number
	game_scene.daily_mode = daily
	if not custom_data.is_empty():
		game_scene.custom_level_data = custom_data.duplicate(true)
	game_scene.finished.connect(_on_game_finished)
	game_scene.quit_requested.connect(_on_game_quit)
	add_child(game_scene)
	game_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_scene.offset_left = 0.0
	game_scene.offset_top = 0.0
	game_scene.offset_right = 0.0
	game_scene.offset_bottom = 0.0
	game_scene.z_index = 100
	game_scene.show()
	move_child(game_scene, get_child_count() - 1)
	active_game = game_scene
	AnalyticsManager.track("game_scene_opened", {"level": level_number, "daily": daily})

func _remove_active_game() -> void:
	if active_game and is_instance_valid(active_game):
		active_game.queue_free()
	active_game = null
	var stale := get_node_or_null("ActiveGame")
	if stale and is_instance_valid(stale):
		stale.queue_free()

func _on_game_finished(completed_level: int) -> void:
	active_game = null
	if completed_level < 0:
		current_surface = "home"
		build_home()
		return
	if LevelManager.has_level(completed_level + 1):
		current_surface = "game"
		call_deferred("start_level", completed_level + 1)
	else:
		current_surface = "home"
		build_home()

func _on_game_quit() -> void:
	active_game = null
	current_surface = "levels"
	build_level_select()

func _create_continue_button() -> void:
	continue_button = make_button("CONTINUE RESCUE", Vector2(480, 88), true)
	continue_button.position = Vector2(300, 1685)
	continue_button.z_index = 50
	continue_button.pressed.connect(_resume_checkpoint)
	add_child(continue_button)
	PremiumVisuals.premium_button(continue_button)

func _process(_delta: float) -> void:
	if continue_button == null:
		return
	var checkpoint := _valid_checkpoint()
	continue_button.visible = current_surface == "home" and not checkpoint.is_empty()
	if continue_button.visible:
		var label := "DAILY RESCUE" if bool(checkpoint.get("daily", false)) else "LEVEL %d" % int(checkpoint.get("level", 1))
		continue_button.text = "CONTINUE RESCUE\n%s  •  %d MOVES" % [label, int(checkpoint.get("moves", 0))]

func _valid_checkpoint() -> Dictionary:
	var raw = SaveManager.data.get("active_run", {})
	if not raw is Dictionary or raw.is_empty():
		return {}
	var checkpoint: Dictionary = raw
	var level_number := int(checkpoint.get("level", 0))
	if level_number < 1 or level_number > LevelManager.CAMPAIGN_LEVELS:
		_clear_bad_checkpoint()
		return {}
	if bool(checkpoint.get("daily", false)):
		if String(checkpoint.get("daily_key", "")) != DailyChallenge.date_key():
			_clear_bad_checkpoint()
			return {}
		var custom = checkpoint.get("level_data", {})
		if not custom is Dictionary or custom.is_empty():
			_clear_bad_checkpoint()
			return {}
	return checkpoint

func _clear_bad_checkpoint() -> void:
	SaveManager.data["active_run"] = {}
	SaveManager.save()

func _resume_checkpoint() -> void:
	var checkpoint := _valid_checkpoint()
	if checkpoint.is_empty():
		return
	current_surface = "game"
	var custom_data: Dictionary = {}
	if bool(checkpoint.get("daily", false)):
		var custom = checkpoint.get("level_data", {})
		if custom is Dictionary:
			custom_data = custom.duplicate(true)
	_spawn_game(int(checkpoint.get("level", 1)), bool(checkpoint.get("daily", false)), custom_data)
	AnalyticsManager.track("resume_selected", {"level": int(checkpoint.get("level", 1)), "daily": bool(checkpoint.get("daily", false))})