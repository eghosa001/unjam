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
	if not EconomyManager.balance_changed.is_connected(_on_economy_balance_changed):
		EconomyManager.balance_changed.connect(_on_economy_balance_changed)
	var initial_surface := String(main.get("current_surface")) if main != null and main.get("current_surface") != null else "home"
	call_deferred("_on_surface_changed", initial_surface)

func _on_surface_changed(surface: String) -> void:
	visible = surface == "live"
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		return
	_refresh_progress_on_entry()

func _refresh_progress_on_entry() -> void:
	# Progress can change while this persistent selector is hidden behind gameplay.
	# Rebuilding only on entry keeps it event-driven and guarantees fresh cards.
	_build()
	_ensure_wallet_shop_action()

func _theme_mode() -> String:
	var shell := get_parent().get_node_or_null("UXShell")
	if shell != null and shell.get("theme_mode") != null:
		return String(shell.get("theme_mode"))
	return "dark"

# Implemented by premium_live_hub_3d.gd.
func _build() -> void:
	pass

func _ensure_wallet_shop_action() -> void:
	var existing := find_child("LiveCoinShopButton", true, false) as Button
	if existing != null:
		_set_wallet_balance(EconomyManager.balance())
		return
	var coin_label := _find_coin_label(self)
	if coin_label == null or coin_label.get_parent() == null:
		return
	var parent := coin_label.get_parent()
	var index := coin_label.get_index()
	parent.remove_child(coin_label)
	coin_label.queue_free()
	var button := Button.new()
	button.name = "LiveCoinShopButton"
	button.text = "●  %d  +" % EconomyManager.balance()
	button.tooltip_text = "Coins • Open Shop"
	button.custom_minimum_size = Vector2(180, 58)
	button.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.ORANGE, true, 24, _theme_mode() == "dark")
	button.pressed.connect(_open_shop)
	parent.add_child(button)
	parent.move_child(button, index)

func _find_coin_label(node: Node) -> Label:
	for child in node.get_children():
		if child is Label and String((child as Label).text).begins_with("●"):
			return child as Label
		var nested := _find_coin_label(child)
		if nested != null:
			return nested
	return null

func _set_wallet_balance(new_balance: int) -> void:
	var button := find_child("LiveCoinShopButton", true, false) as Button
	if button != null:
		button.text = "●  %d  +" % new_balance

func _on_economy_balance_changed(new_balance: int, _delta: int, _reason: String) -> void:
	if visible:
		_set_wallet_balance(new_balance)

func _open_shop() -> void:
	var hub := get_parent().get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		hub.call("open_shop")

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
