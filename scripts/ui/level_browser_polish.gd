extends Node

var last_content_id := 0
var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_refresh")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.20:
		return
	timer = 0.0
	_refresh()

func _refresh() -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface != "levels":
		last_content_id = 0
		return
	var content: Control = main.get("content") as Control
	if content == null or not is_instance_valid(content):
		return
	var current_id := content.get_instance_id()
	if current_id == last_content_id:
		return
	last_content_id = current_id
	var game_id := String(main.get("selected_game_id")) if main.get("selected_game_id") != null else "rescue_rush"
	var accent := PremiumDesignSystem.accent_for_game(game_id)
	var shell := main.get_node_or_null("UXShell")
	var dark := shell == null or String(shell.get("theme_mode")) != "light"
	for grid in _find_grids(content):
		if grid.columns != 5:
			continue
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		for child in grid.get_children():
			if child is Button:
				var button := child as Button
				button.custom_minimum_size = Vector2(218, 116)
				button.add_theme_font_size_override("font_size", 19)
				PremiumDesignSystem.apply_button(button, dark, accent, "disabled" if button.disabled else "secondary", 20)
				if not button.disabled and button.text.begins_with(str(_highest_level(main, game_id)) + "\n"):
					PremiumDesignSystem.apply_button(button, dark, accent, "primary", 20)

func _highest_level(main: Node, game_id: String) -> int:
	if game_id == "rescue_rush":
		return int(SaveManager.data.get("highest_level", 1))
	return MultiGameManager.highest_level(game_id)

func _find_grids(root: Node) -> Array[GridContainer]:
	var result: Array[GridContainer] = []
	for child in root.get_children():
		if child is GridContainer:
			result.append(child as GridContainer)
		result.append_array(_find_grids(child))
	return result
