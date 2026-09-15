extends Node

# GAME_FIRST_HOME
# GAME_FIRST_SETTINGS

var last_surface := ""
var last_home_root := 0
var last_settings_root := 0

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
		last_settings_root = 0
	if surface == "home":
		_patch_home(main)
	elif surface == "settings":
		_patch_settings(main)

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
	if content.get_instance_id() == last_settings_root:
		return
	last_settings_root = content.get_instance_id()
	for node in _descendants(content):
		if node is Button:
			var button := node as Button
			var text := button.text.to_upper()
			if text.contains("SOUND") or text.contains("HAPTICS") or text.contains("MUSIC") or text.contains("APPEARANCE"):
				button.custom_minimum_size = Vector2(560, 92)
		elif node is Label:
			var label := node as Label
			if label.text.contains("Hints") or label.text.contains("Prestige"):
				label.text = "YOUR PROGRESS LIVES ON THE HOME AND COLLECTION SCREENS"
				label.add_theme_font_size_override("font_size", 16)

func _home_root(home: Control) -> VBoxContainer:
	for child in home.get_children():
		if child is MarginContainer and child.get_child_count() > 0:
			var candidate := child.get_child(0)
			if candidate is VBoxContainer:
				return candidate as VBoxContainer
	return null

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result
