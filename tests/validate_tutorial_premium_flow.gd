extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene could not be loaded for tutorial validation")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(6)
	var shell := main.get_node_or_null("UXShell")
	if shell == null or not shell.has_method("show_tutorial"):
		push_error("UXShell tutorial controller is missing")
		quit(1)
		return

	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		shell.call("show_tutorial", game_id)
		await _frames(3)
		var panel = shell.get("tutorial_panel") as PanelContainer
		var body = shell.get("tutorial_body") as Label
		var demo = shell.get("tutorial_demo") as Label
		var step = shell.get("tutorial_step_label") as Label
		var progress = shell.get("tutorial_progress_label") as Label
		var next = shell.get("tutorial_next_button") as Button
		var back = shell.get("tutorial_prev_button") as Button
		if panel == null or not panel.visible:
			return _fail("Tutorial panel did not open for %s" % game_id)
		if panel.custom_minimum_size.y > 780.0:
			return _fail("%s tutorial panel reverted to an oversized empty shell" % game_id)
		if panel.custom_minimum_size.x > root.get_visible_rect().size.x - 20.0:
			return _fail("%s tutorial panel is too wide for the viewport" % game_id)
		if body == null or body.text.length() > 180:
			return _fail("%s tutorial reverted to a wall of text" % game_id)
		if demo == null or demo.text.is_empty() or step == null or step.text.is_empty():
			return _fail("%s visual tutorial step is missing" % game_id)
		if progress == null or "STEP 1 OF 3" not in progress.text:
			return _fail("%s tutorial progress indicator is missing" % game_id)
		if next == null or back == null or next.custom_minimum_size.y < 64.0 or back.custom_minimum_size.y < 64.0:
			return _fail("%s tutorial navigation touch targets are too small" % game_id)
		var first_text: String = step.text
		next.emit_signal("pressed")
		await _frames(2)
		if step.text == first_text or "STEP 2 OF 3" not in progress.text:
			return _fail("%s tutorial NEXT does not advance the visual step" % game_id)
		back.emit_signal("pressed")
		await _frames(2)
		if step.text != first_text or "STEP 1 OF 3" not in progress.text:
			return _fail("%s tutorial BACK does not restore the previous step" % game_id)
		shell.call("hide_tutorial")
		await _frames(2)

	main.queue_free()
	await process_frame
	print("Premium step-based tutorial flow validated.")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
