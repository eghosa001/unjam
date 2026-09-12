extends "res://scripts/ui/main.gd"

var continue_button: Button
var current_surface := "home"

func _ready() -> void:
	super._ready()
	_create_continue_button()
	set_process(true)

func build_home() -> void:
	current_surface = "home"
	super.build_home()

func build_level_select() -> void:
	current_surface = "levels"
	super.build_level_select()

func build_collection() -> void:
	current_surface = "collection"
	super.build_collection()

func build_settings() -> void:
	current_surface = "settings"
	super.build_settings()

func start_level(level_number: int) -> void:
	current_surface = "game"
	super.start_level(level_number)

func start_daily() -> void:
	current_surface = "game"
	super.start_daily()

func _on_game_finished(completed_level: int) -> void:
	super._on_game_finished(completed_level)
	if completed_level < 0:
		current_surface = "home"
	else:
		current_surface = "game"

func _on_game_quit() -> void:
	current_surface = "levels"
	super._on_game_quit()

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
	if content:
		content.visible = false
	var game_scene = load("res://scenes/Game.tscn").instantiate()
	game_scene.level_number = int(checkpoint.get("level", 1))
	game_scene.daily_mode = bool(checkpoint.get("daily", false))
	if game_scene.daily_mode:
		game_scene.custom_level_data = Dictionary(checkpoint.get("level_data", {})).duplicate(true)
	game_scene.finished.connect(_on_game_finished)
	game_scene.quit_requested.connect(_on_game_quit)
	add_child(game_scene)
	AnalyticsManager.track("resume_selected", {"level": game_scene.level_number, "daily": game_scene.daily_mode})
