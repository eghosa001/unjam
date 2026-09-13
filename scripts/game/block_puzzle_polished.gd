extends "res://scripts/game/block_puzzle.gd"

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := PolishedBlockPieceButton.new()
		button.custom_minimum_size = Vector2(285, 130)
		button.configure(pieces[i], i == selected_piece, Color("7d86e8"), i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)
