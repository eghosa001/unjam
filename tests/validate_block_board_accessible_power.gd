extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	game.level_number = 8
	root.add_child(game)
	for _i in range(7):
		await process_frame
	var cells: Array = game.get("cell_buttons")
	if not _check(cells.size() == 64, "Block must display the entire eight-by-eight board"):return
	for i in range(cells.size()):
		var button := cells[i] as BlockCellButton
		if not _check(button != null and button.focus_mode == Control.FOCUS_ALL, "Board square cannot receive keyboard/TalkBack focus: %d" % i):return
		if not _check(button.accessibility_name.contains("Row %d, column %d" % [int(i / 8) + 1, i % 8 + 1]), "Board square has no location label: %d" % i):return
		if not _check(button.accessibility_name.contains("occupied") or button.accessibility_name.contains("empty"), "Board square lacks state semantics: %d" % i):return
		if not _check(button.get_theme_stylebox("focus") != null, "No visible keyboard focus ring on Block square"):return
	var first_empty := -1
	for i in range(cells.size()):
		if not bool(game.cells[int(i / 8)][i % 8]):
			first_empty = i
			break
	if not _check(first_empty >= 0, "Starting board cannot be completely full"):return
	var tile := cells[first_empty] as BlockCellButton
	tile.set_drag_footprint(true, true, Color("#83fda3"))
	if not _check(not tile.is_processing(), "A static drag footprint must not run an infinite 60fps animation"):return
	tile.set_drag_footprint(false)
	var source := FileAccess.get_file_as_string("res://scripts/game/block_puzzle.gd")
	if not _check(source.contains('range(8 if bool(SaveManager.data.get("gentle_effects", true)) and not MotionSystem.reduced() else 0)'), "Reduce Motion still creates ambient infinite tweens"):return
	game.queue_free()
	await process_frame
	print("BLOCK_BOARD_ACCESSIBLE_POWER_OK: 64 keyboard targets, focus, board semantics, static drag, ambient motion guard")
	quit(0)

func _check(ok: bool, why: String) -> bool:
	if ok: return true
	push_error(why)
	quit(1)
	return false
