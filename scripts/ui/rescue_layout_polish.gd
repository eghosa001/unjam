extends Node

func _ready() -> void:
	call_deferred("_polish_layout")

func _polish_layout() -> void:
	var game := get_parent() as Control
	if game == null:
		return
	var root_box: VBoxContainer = _find_primary_vbox(game)
	if root_box != null:
		root_box.alignment = BoxContainer.ALIGNMENT_CENTER
		root_box.add_theme_constant_override("separation", 15)
	var board_holder: CenterContainer = _find_board_holder(game)
	if board_holder != null:
		board_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		board_holder.custom_minimum_size = Vector2(0, 650)
	var board_panel: PanelContainer = _find_board_panel(game)
	if board_panel != null:
		board_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		board_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.box(Color(0.008, 0.024, 0.052, 0.98), 42, Color(PremiumDesignSystem.accent_for_game("rescue_rush"), 0.52), 3, 12, true))

func _find_primary_vbox(root: Node) -> VBoxContainer:
	for child in root.get_children():
		if child is MarginContainer:
			for grandchild in child.get_children():
				if grandchild is VBoxContainer:
					return grandchild as VBoxContainer
	return null

func _find_board_holder(root: Node) -> CenterContainer:
	for node in _descendants(root):
		if node is CenterContainer:
			for child in node.get_children():
				if child is PanelContainer and _contains_grid(child):
					return node as CenterContainer
	return null

func _find_board_panel(root: Node) -> PanelContainer:
	for node in _descendants(root):
		if node is PanelContainer and _contains_grid(node):
			return node as PanelContainer
	return null

func _contains_grid(root: Node) -> bool:
	if root is GridContainer:
		return true
	for child in root.get_children():
		if _contains_grid(child):
			return true
	return false

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result
