extends "res://scripts/game/block_puzzle_premium_layout.gd"

# GAME_FIRST_BLOCK

const SmoothPieceButton = preload("res://scripts/ui/smooth_block_piece_button.gd")
const PLACEMENT_HELP := "Release when the placement preview locks into place"

func build_ui() -> void:
	super.build_ui()
	_patch_game_first_layout()

func load_level() -> void:
	super.load_level()
	hint_label.text = PLACEMENT_HELP

func select_piece(index: int) -> void:
	super.select_piece(index)
	if not completed and index >= 0 and index < pieces.size() and not pieces[index].is_empty():
		hint_label.text = PLACEMENT_HELP

func _patch_game_first_layout() -> void:
	for node in _descendants(self):
		if node is PanelContainer:
			var panel := node as PanelContainer
			if _contains_label(panel, "SCORE") or _contains_label(panel, "TARGET"):
				panel.custom_minimum_size.y = minf(panel.custom_minimum_size.y, 92.0)
			elif _contains_label(panel, "DRAG A BLOCK"):
				panel.custom_minimum_size.y = 196.0
			elif _contains_label(panel, "RUN PROGRESS"):
				panel.visible = false
				panel.custom_minimum_size = Vector2.ZERO
		elif node is CenterContainer:
			var center := node as CenterContainer
			if _contains_grid(center):
				center.size_flags_vertical = Control.SIZE_EXPAND_FILL

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := SmoothPieceButton.new()
		button.custom_minimum_size = Vector2(270, 150)
		button.configure(pieces[i], i == selected_piece, piece_colors[i], i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func _contains_label(root: Node, needle: String) -> bool:
	if root is Label and (root as Label).text.to_upper().contains(needle):
		return true
	for child in root.get_children():
		if _contains_label(child, needle):
			return true
	return false

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
