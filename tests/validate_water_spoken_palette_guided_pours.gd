extends SceneTree

# Focused Water Sort accessibility contract. Uses the real active scene and
# a bounded 14-tube fixture (rather than generating all 10,000 levels).
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null:
		return _fail("Water Sort scene is unavailable")
	var game := scene.instantiate() as Control
	root.add_child(game)
	await _frames(5)
	var board := game.get("board") as GridContainer
	if not _check(board != null and board.get_child_count() >= 3,"Water Sort opening tubes unavailable"): return
	for i in range(board.get_child_count()):
		var tube := board.get_child(i) as Button
		if not _check(tube != null and tube.focus_mode == Control.FOCUS_ALL,"Water bottle %d is missing keyboard/TalkBack focus" % (i + 1)):return
		if not _check(tube.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE,"Water bottle activates on touch-down rather than touch release"):return

	var dense: Array = []
	for i in range(12):
		dense.append([i])
	dense.append([])
	dense.append([])
	game.set("tubes",dense)
	game.set("selected",-1)
	game.call("render_board")
	await _frames(3)
	board = game.get("board") as GridContainer
	if not _check(board.get_child_count() == 14,"Dense Water board did not expose all bottles"):return
	var names := [
		"deep red", "royal blue", "golden yellow", "emerald green",
		"violet", "orange", "cyan blue", "magenta pink",
		"charcoal grey", "lime green", "brown", "pale mint"
	]
	for i in range(12):
		var bottle := board.get_child(i) as Button
		var label := bottle.accessibility_name
		if not _check(label.contains(String(names[i])) and label.contains("bottom to top"),"Palette colour %d is not spoken by its colour name" % i):return
		if not _check(label.contains("Tap to select as source"),"Unselected source lacks a discoverable action"):return
	var empty := board.get_child(12) as Button
	if not _check(empty.accessibility_name.contains("empty") and empty.accessibility_name.contains("Choose a filled source"),"Empty destination guidance missing"):return
	if not _check(empty.focus_mode == Control.FOCUS_ALL,"Empty destination tube is not keyboard focusable"):return

	game.call("select_tube",0)
	await _frames(2)
	if not _check((board.get_child(0) as Button).accessibility_name.contains("Selected source"),"Selected bottle does not announce its state"):return
	if not _check((board.get_child(12) as Button).accessibility_name.contains("Valid destination"),"Legal empty target is not announced"):return
	if not _check((board.get_child(1) as Button).accessibility_name.contains("Blocked destination"),"Different top-colour target is not flagged as blocked"):return
	if not _check((board.get_child(0) as Button).tooltip_text == (board.get_child(0) as Button).accessibility_name,"Hover and screen-reader state diverged"):return

	game.call("select_tube",0)
	await _frames(2)
	if not _check(int(game.get("selected")) == -1,"Re-tap did not clear source selection"):return
	if not _check((board.get_child(12) as Button).accessibility_name.contains("Choose a filled source"),"Empty target did not revert to safe instruction"):return

	dense[2] = [2,2,2,2]
	game.set("tubes",dense)
	game.call("render_board")
	if not _check((board.get_child(2) as Button).accessibility_name.contains("complete"),"Completed single-colour bottle not described"):return
	game.queue_free()
	await process_frame
	print("WATER_SPOKEN_PALETTE_GUIDED_POURS_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(ok: bool, reason: String) -> bool:
	if ok:
		return true
	return _fail(reason)

func _fail(reason: String) -> bool:
	push_error(reason)
	quit(1)
	return false
