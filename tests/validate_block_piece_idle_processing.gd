extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var button = load("res://scripts/ui/smooth_block_piece_button.gd").new()
	root.add_child(button)
	button.configure([Vector2i(0, 0), Vector2i(1, 0)], false, Color("19b9ff"), 0)
	# Headless runs can synthesize a pointer hover at the origin; force the
	# unhovered state so this assertion measures true idle behavior.
	button.call("_set_hover", false)
	await process_frame
	var failures: Array[String] = []
	if button.is_processing():
		failures.append("Idle unselected Block Puzzle tray pieces must not process every frame")
	button.call("_set_hover", true)
	if not button.is_processing():
		failures.append("Hovered Block Puzzle tray pieces must wake processing")
	button.call("_set_hover", false)
	if button.is_processing():
		failures.append("Block Puzzle tray pieces must sleep again after hover ends")
	button.configure([Vector2i(0, 0)], true, Color("ffd83d"), 0)
	if not button.is_processing():
		failures.append("Selected Block Puzzle tray pieces must process for the selection pulse")
	button.configure([Vector2i(0, 0)], false, Color("ffd83d"), 0)
	if button.is_processing():
		failures.append("Deselected Block Puzzle tray pieces must return to idle sleep")
	button.call("_begin_drag_feedback")
	if not button.is_processing():
		failures.append("Dragging Block Puzzle tray pieces must wake processing")
	button.call("_end_drag_feedback", false)
	if button.is_processing():
		failures.append("Block Puzzle tray pieces must sleep after drag feedback ends")
	button.queue_free()
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Block Puzzle tray pieces process only while interactive motion needs it.")
	quit(0)
