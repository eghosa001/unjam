extends Node

var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_apply")

func _process(delta: float) -> void:
	timer += delta
	if timer < 0.20:
		return
	timer = 0.0
	_apply()

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
