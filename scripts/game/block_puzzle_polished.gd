extends "res://scripts/game/block_puzzle.gd"

const PIECE_COLORS := [
	Color("8b7cf6"), Color("5da9ff"), Color("2dd4b6"),
	Color("ffb454"), Color("ff6b8a"), Color("67e8cf")
]

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := PolishedBlockPieceButton.new()
		button.custom_minimum_size = Vector2(285, 130)
		var color: Color = PIECE_COLORS[posmod(piece_batch * 3 + i, PIECE_COLORS.size())]
		button.configure(pieces[i], i == selected_piece, color, i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func complete_level() -> void:
	if completed:
		return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if placements <= par_placements else (2 if placements <= par_placements + 6 else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 30)
	status_label.text = "BOARD MASTERED"
	PremiumVisuals.burst(Vector2(540, 850), Color("8b7cf6"), 32)
	PremiumVisuals.screen_flash(Color("8b7cf6"), 0.11)
	PremiumVisuals.show_combo("BOARD CLEAR", Vector2(540, 720), Color("67e8cf"))
	AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.30).timeout
	var result := PremiumResultOverlay.new()
	result.configure(
		"BLOCK PUZZLE COMPLETE",
		"Strong placements. Clean lines. Space controlled.",
		"SCORE %d   •   %d LINES\n%d PLACEMENTS   •   PERFECT ≤ %d" % [score, lines_cleared, placements, par_placements],
		stars,
		Color("8b7cf6"),
		"BACK HOME" if daily_mode else "NEXT PUZZLE"
	)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)
