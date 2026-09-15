extends "res://scripts/game/block_puzzle_premium_layout.gd"

const SmoothPieceButton = preload("res://scripts/ui/smooth_block_piece_button.gd")

func _ready() -> void:
	super._ready()
	if hint_label != null:
		hint_label.text = "Release when the placement preview locks into place"

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := SmoothPieceButton.new()
		button.custom_minimum_size = Vector2(260, 142)
		button.configure(pieces[i], i == selected_piece, piece_colors[i], i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)
