extends Node

var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_polish")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.20:
		return
	timer = 0.0
	_fit_board()

func _polish() -> void:
	var game := get_parent()
	if game == null:
		return
	var run_objective: Label = game.get("run_objective_label") as Label
	if run_objective != null:
		var deck := _nearest_panel(run_objective)
		if deck != null:
			deck.name = "CompactProgressStrip"
			deck.custom_minimum_size = Vector2(0, 74)
			deck.size_flags_vertical = Control.SIZE_SHRINK_END
		var box := run_objective.get_parent() as VBoxContainer
		if box != null:
			box.add_theme_constant_override("separation", 3)
		run_objective.visible = false
	var pace: Label = game.get("run_pace_label") as Label
	if pace != null:
		pace.add_theme_font_size_override("font_size", 13)
	var score_bar: ProgressBar = game.get("run_score_bar") as ProgressBar
	var line_bar: ProgressBar = game.get("run_line_bar") as ProgressBar
	for bar in [score_bar, line_bar]:
		if bar != null:
			bar.custom_minimum_size.y = 12
	_compact_buttons(game)
	_fit_board()

func _fit_board() -> void:
	var game := get_parent() as Control
	if game == null:
		return
	var grid: GridContainer = game.get("board_grid") as GridContainer
	if grid == null or grid.get_child_count() == 0:
		return
	var viewport := game.get_viewport_rect().size
	var available_width: float = maxf(560.0, viewport.x - 92.0)
	var available_height: float = maxf(560.0, viewport.y - 670.0)
	var width_cell: float = floor((available_width - 30.0) / 8.0)
	var height_cell: float = floor((available_height - 30.0) / 8.0)
	var cell_size: float = clampf(minf(width_cell, height_cell), 68.0, 102.0)
	for child in grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	var shell: Control = game.get("board_shell") as Control
	if shell != null:
		shell.custom_minimum_size = Vector2(cell_size * 8.0 + 20.0, cell_size * 8.0 + 20.0)
	var pieces: HBoxContainer = game.get("piece_row") as HBoxContainer
	if pieces != null:
		pieces.custom_minimum_size.y = 132
		var tray := _nearest_panel(pieces)
		if tray != null:
			tray.custom_minimum_size.y = 176

func _compact_buttons(root: Node) -> void:
	for node in _descendants(root):
		if node is Button:
			var button := node as Button
			if "BACK" in button.text or "RETRY" in button.text:
				button.custom_minimum_size = Vector2(150, 76)
				button.add_theme_font_size_override("font_size", 20)

func _nearest_panel(node: Node) -> PanelContainer:
	var current := node.get_parent()
	while current != null:
		if current is PanelContainer:
			return current as PanelContainer
		current = current.get_parent()
	return null

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result
