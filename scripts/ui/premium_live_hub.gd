extends Control

# Shared Live/Game-select state and navigation only. Retired presentation code
# is gone; premium_live_hub_3d.gd owns the active visual implementation.
const DESCRIPTIONS := {
	"rescue_rush": "Clear the lane, trigger chain reactions and rescue the trapped character.",
	"water_sort": "Sort every colour into clean tubes with the fewest possible pours.",
	"block_puzzle": "Place pieces, preserve space and clear satisfying lines."
}

var built := false
var last_theme := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var main := get_parent()
	if main != null and main.has_signal("surface_changed"):
		main.surface_changed.connect(_on_surface_changed)
	var initial_surface := String(main.get("current_surface")) if main != null and main.get("current_surface") != null else "home"
	call_deferred("_on_surface_changed", initial_surface)

func _on_surface_changed(surface: String) -> void:
	visible = surface == "live"
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		return
	var mode := _theme_mode()
	if not built or mode != last_theme:
		_build()

func _theme_mode() -> String:
	var shell := get_parent().get_node_or_null("UXShell")
	if shell != null and shell.get("theme_mode") != null:
		return String(shell.get("theme_mode"))
	return "dark"

# Implemented by premium_live_hub_3d.gd.
func _build() -> void:
	pass

func _total_stars() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.total_stars(game_id)
	return total

func _go_home() -> void:
	get_parent().call("build_home")

func _play(game_id: String) -> void:
	var main := get_parent()
	var checkpoint = main.call("_checkpoint_for", game_id) if main.has_method("_checkpoint_for") else {}
	if checkpoint is Dictionary and not checkpoint.is_empty():
		main.call("resume_game", game_id)
	else:
		main.call("open_game_campaign", game_id)
