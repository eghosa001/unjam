extends Control

# Shared Home state/navigation only. The retired flat renderer that used
# PremiumBackdrop, GameSelectTile, GameShowcaseArt and UnjamLogo has been
# removed; premium_home_casual.gd owns the active 3D presentation.
var selected_game := "rescue_rush"
var built := false
var last_theme := ""
var footer_label: Label
var primary_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_sync")

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	visible = surface == "home"
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		return
	var mode := _theme_mode()
	if not built or mode != last_theme:
		_sync()

func _sync() -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface != "home":
		visible = false
		return
	var current = main.get("selected_game_id")
	if current != null and String(current) in MultiGameManager.GAME_IDS:
		selected_game = String(current)
	build_home_launcher()

func _theme_mode() -> String:
	var shell := get_parent().get_node_or_null("UXShell")
	if shell != null and shell.get("theme_mode") != null:
		return String(shell.get("theme_mode"))
	return "dark"

# Implemented by the active 3D home subclass.
func build_home_launcher() -> void:
	pass

func _current_level(game_id: String) -> int:
	return clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)

func _hero_progress_text(game_id: String) -> String:
	var level := _current_level(game_id)
	var world := MultiGameManager.highest_unlocked_world(game_id)
	var stars := MultiGameManager.total_stars(game_id)
	return "LEVEL %d   •   WORLD %d   •   %d ★" % [level, world, stars]

func _shared_progress_text() -> String:
	var completed := 0
	for game_id in MultiGameManager.GAME_IDS:
		completed += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	return "%d / 30,000 CLEARED" % completed

func _total_stars() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.total_stars(game_id)
	return total

func _play_selected() -> void:
	var main := get_parent()
	if main == null:
		return
	if main.has_method("_checkpoint_for"):
		var checkpoint = main.call("_checkpoint_for", selected_game)
		if checkpoint is Dictionary and not checkpoint.is_empty():
			main.call("resume_game", selected_game)
			return
	main.call("open_game_campaign", selected_game)

func _open_journey() -> void:
	var main := get_parent()
	if main != null:
		main.call("open_game_campaign", selected_game)
