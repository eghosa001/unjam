extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene could not be loaded for tutorial validation")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	var shell := main.get_node_or_null("UXShell")
	if shell == null or not shell.has_method("show_tutorial"):
		return _fail("UXShell tutorial controller is missing")

	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		shell.call("show_tutorial",game_id)
		await _frames(3)
		var canvas := shell.find_child("FigmaTutorial390x844",true,false) as Control
		var panel := shell.get("tutorial_panel") as PanelContainer
		var body := shell.get("tutorial_body") as Label
		var step := shell.get("tutorial_step_label") as Label
		var progress := shell.get("tutorial_progress_label") as Label
		var next := shell.get("tutorial_next_button") as Button
		var back := shell.get("tutorial_prev_button") as Button
		var demo := shell.find_child("TutorialDemoArt",true,false) as Control
		var close := shell.find_child("TutorialClose",true,false) as Button
		var demo_panel := shell.find_child("TutorialDemoPanel",true,false) as Control
		var step_card := shell.find_child("TutorialStepCard",true,false) as Control
		if canvas == null or not canvas.visible:
			return _fail("Figma tutorial canvas did not open for %s" % game_id)
		if panel == null or not _rect_eq(Rect2(panel.position,panel.size),Rect2(17,45,354,682)):
			return _fail("%s tutorial panel drifted from Figma 354x682 geometry" % game_id)
		if body == null or body.text.length() > 180:
			return _fail("%s tutorial reverted to a wall of text" % game_id)
		if demo == null or demo.get_child_count() == 0 or step == null or step.text.is_empty():
			return _fail("%s gameplay demo art is missing" % game_id)
		if game_id == "rescue_rush":
			var exit_label := shell.find_child("TutorialDemoExitLabel",true,false) as Label
			if exit_label == null or exit_label.get_theme_font_size("font_size") < 12:
				return _fail("Rescue tutorial EXIT label fell below the 12px readability floor")
			if exit_label.position.distance_to(Vector2(160,34)) > 1.0:
				return _fail("Rescue tutorial EXIT label drifted from its intended position")
			if exit_label.position.x + exit_label.size.x > demo.size.x or exit_label.position.y + exit_label.size.y > demo.size.y:
				return _fail("Rescue tutorial EXIT label escaped the demo bounds")
		if demo_panel == null or step_card == null or demo_panel.get_rect().intersects(step_card.get_rect()):
			return _fail("%s tutorial demo and instruction card overlap" % game_id)
		if step.get_rect().intersects(progress.get_rect()):
			return _fail("%s tutorial instruction overlaps progress text" % game_id)
		if progress == null or "STEP 1 OF 3" not in progress.text:
			return _fail("%s tutorial progress indicator is missing" % game_id)
		if next == null or back == null:
			return _fail("%s tutorial navigation is missing" % game_id)
		if not _rect_eq(Rect2(back.position,back.size),Rect2(43,526,142,48)):
			return _fail("%s BACK control drifted from Figma geometry" % game_id)
		if not _rect_eq(Rect2(next.position,next.size),Rect2(203,526,142,48)):
			return _fail("%s NEXT control drifted from Figma geometry" % game_id)
		if close == null or not _rect_eq(Rect2(close.position,close.size),Rect2(43,598,302,58)):
			return _fail("%s PLAY NOW control drifted from Figma geometry" % game_id)
		var first_text := step.text
		next.pressed.emit()
		await _frames(2)
		if step.text == first_text or "STEP 2 OF 3" not in progress.text:
			return _fail("%s tutorial NEXT does not advance" % game_id)
		back.pressed.emit()
		await _frames(2)
		if step.text != first_text or "STEP 1 OF 3" not in progress.text:
			return _fail("%s tutorial BACK does not restore the previous step" % game_id)
		shell.call("hide_tutorial")
		await _frames(2)

	main.queue_free()
	await process_frame
	print("Figma tutorial flow validated.")
	quit(0)

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
