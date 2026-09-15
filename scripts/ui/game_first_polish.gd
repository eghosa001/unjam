extends Node

# GAME_FIRST_HOME
# GAME_FIRST_SETTINGS

var last_surface := ""
var last_home_root := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	if surface != last_surface:
		last_surface = surface
		last_home_root = 0
	_patch_global_help(main, surface)
	if surface == "home":
		_patch_home(main)
	elif surface == "settings":
		_patch_settings(main)
	elif surface == "game":
		_patch_game_surface(main)

func _patch_home(main: Node) -> void:
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null or not home.visible:
		return
	# Screen itself remains geometrically fixed; child feedback provides motion.
	home.position = Vector2.ZERO
	var root := _home_root(home)
	if root == null:
		return
	if root.get_instance_id() == last_home_root:
		return
	last_home_root = root.get_instance_id()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 10)
	var journey := root.get_node_or_null("JourneyFill")
	if journey != null:
		journey.queue_free()
	for node in _descendants(root):
		if node.name == "HomeHero" and node is Control:
			(node as Control).custom_minimum_size = Vector2(0, 500)
		elif node is GameSelectTile:
			(node as Control).custom_minimum_size = Vector2(300, 192)
		elif node is GridContainer:
			_patch_quick_grid(node as GridContainer)

func _patch_quick_grid(grid: GridContainer) -> void:
	var has_daily := false
	for child in grid.get_children():
		if child is Button and (child as Button).text.to_upper().contains("DAILY"):
			has_daily = true
	if not has_daily:
		return
	grid.columns = 2
	for child in grid.get_children():
		if child is Button:
			var button := child as Button
			var text := button.text.to_upper()
			button.visible = not text.contains("COLLECTION") and not text.contains("LIVE")
			if button.visible:
				button.custom_minimum_size = Vector2(0, 78)

func _patch_settings(main: Node) -> void:
	var content_value = main.get("content")
	if content_value == null or not is_instance_valid(content_value):
		return
	var content := content_value as Control
	if content == null or not content.visible:
		return
	# Settings rebuilds its children after toggles, so this intentionally reapplies.
	var middle_fill := content.get_node_or_null("PremiumMiddleFill") as Control
	if middle_fill != null:
		middle_fill.visible = false
		middle_fill.custom_minimum_size = Vector2.ZERO
	for node in _descendants(content):
		if node is Button:
			var button := node as Button
			var text := button.text.to_upper()
			if text.contains("SOUND") or text.contains("HAPTICS") or text.contains("MUSIC") or text.contains("APPEARANCE"):
				button.custom_minimum_size = Vector2(560, 92)
		elif node is PanelContainer and _contains_label(node, "PLAY HISTORY"):
			var panel := node as PanelContainer
			panel.visible = false
			panel.custom_minimum_size = Vector2.ZERO

func _patch_global_help(main: Node, surface: String) -> void:
	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return
	var value = shell.get("help_button")
	if value == null or not is_instance_valid(value):
		return
	var help := value as Button
	if help == null:
		return
	if surface == "game":
		help.text = "?"
		help.custom_minimum_size = Vector2(64, 64)
		help.position = Vector2(24, -84)

func _patch_game_surface(main: Node) -> void:
	var game_value = main.get("active_game")
	if game_value == null or not is_instance_valid(game_value):
		return
	var game := game_value as Control
	if game == null:
		return
	var selected := String(main.get("selected_game_id")) if main.get("selected_game_id") != null else ""
	if selected != "rescue_rush":
		return
	for node in _descendants(game):
		if node is Label:
			var label := node as Label
			var text := label.text.to_upper()
			if text.begins_with("TIP:") or text.contains("EVERY RESCUE COUNTS"):
				label.visible = false
				label.custom_minimum_size = Vector2.ZERO

func _home_root(home: Control) -> VBoxContainer:
	for child in home.get_children():
		if child is MarginContainer and child.get_child_count() > 0:
			var candidate := child.get_child(0)
			if candidate is VBoxContainer:
				return candidate as VBoxContainer
	return null

func _contains_label(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.to_upper().contains(needle):
		return true
	for child in root.get_children():
		if _contains_label(child, needle):
			return true
	return false

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result
