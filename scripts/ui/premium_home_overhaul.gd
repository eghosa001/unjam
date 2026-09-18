extends Control

# Shared Home state/navigation only. Retired presentation code has been removed;
# premium_home_casual.gd owns the active 3D presentation.
var selected_game := "rescue_rush"
var built := false
var last_theme := ""
var primary_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	var main := get_parent()
	if main != null and main.has_signal("surface_changed"):
		main.surface_changed.connect(_on_surface_changed)
	var initial_surface := String(main.get("current_surface")) if main != null and main.get("current_surface") != null else "home"
	call_deferred("_on_surface_changed", initial_surface)

func _on_surface_changed(surface: String) -> void:
	visible = surface == "home"
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		return
	var main := get_parent()
	if main == null:
		return
	var previous_game := selected_game
	var current = main.get("selected_game_id")
	if current != null and String(current) in MultiGameManager.GAME_IDS:
		selected_game = String(current)
	var mode := _theme_mode()
	if not built or mode != last_theme or selected_game != previous_game:
		_sync()

func _sync() -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface != "home":
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _total_stars() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.total_stars(game_id)
	return total

func _open_journey() -> void:
	var main := get_parent()
	if main != null:
		main.call("open_game_campaign", selected_game)
