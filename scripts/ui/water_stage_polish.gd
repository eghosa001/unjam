extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_queue_apply)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply")

func _queue_apply() -> void:
	call_deferred("_apply")

func _on_node_added(node: Node) -> void:
	var game := get_parent()
	if game != null and is_instance_valid(game) and (node == game or game.is_ancestor_of(node)):
		call_deferred("_apply")

func _apply() -> void:
	var game := get_parent()
	if game == null:
		return
	var board: GridContainer = game.get("board") as GridContainer
	var tubes = game.get("tubes")
	if board == null or not (tubes is Array):
		return
	if tubes.size() == 6:
		board.columns = 3
		board.add_theme_constant_override("h_separation", 34)
		board.add_theme_constant_override("v_separation", 30)
		for child in board.get_children():
			if child is Control:
				(child as Control).custom_minimum_size = Vector2(184, 372)
