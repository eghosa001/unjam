extends SceneTree

const OUT_DIR := "res://build/level100-qa"
const CHECKPOINTS := [1, 10, 25, 50, 75, 100]
const VIEWPORT := Vector2i(540, 960)

var failures: Array[String] = []
var launch_ms := {
	"rescue_rush": [],
	"water_sort": [],
	"block_puzzle": [],
}
var save_manager: Node\nvar multi_game_manager: Node\n\nvar assist_steps := {
	"rescue_rush": 0,
	"water_sort": 0,
	"block_puzzle": 0,
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))\n\tsave_manager = root.get_node_or_null("/root/SaveManager")\n\tmulti_game_manager = root.get_node_or_null("/root/MultiGameManager")\n\tif save_manager == null or multi_game_manager == null:\n\t\treturn _fatal("Required SaveManager/MultiGameManager autoloads are unavailable")
	root.size = VIEWPORT
	Engine.max_fps = 120
	Engine.time_scale = 4.0

	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fatal("Main.tscn could not be loaded")
	var main := packed.instantiate() as Control
	if main == null:
		return _fatal("Main.tscn could not be instantiated")
	root.add_child(main)
	current_scene = main
	await _frames(10)

	await _sweep_rescue(main)
	await _sweep_multi(main, "water_sort")
	await _sweep_multi(main, "block_puzzle")

	var report := {
		"viewport": {"width": VIEWPORT.x, "height": VIEWPORT.y},
		"levels_tested_per_game": 100,
		"automated_play": "assist-driven through normal game interaction paths",
		"launch_ms": {
			"rescue_rush": _stats(launch_ms["rescue_rush"]),
			"water_sort": _stats(launch_ms["water_sort"]),
			"block_puzzle": _stats(launch_ms["block_puzzle"]),
		},
		"assist_steps": assist_steps,
		"failures": failures,
	}
	var f := FileAccess.open(OUT_DIR + "/report.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "\t"))

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("LEVEL_1_100_SWEEP_OK: 300 levels launched, rendered and completed through normal assist-driven gameplay paths.")
		print(JSON.stringify(report))
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _sweep_rescue(main: Control) -> void:
	for level in range(1, 101):
		var save_data: Dictionary = save_manager.get("data")\n\t\tsave_data["active_run"] = {}\n\t\tsave_manager.set("data", save_data)
		var started := Time.get_ticks_usec()
		main.call("start_level", level)
		await _frames(5)
		var game = main.get("active_game")
		launch_ms["rescue_rush"].append(float(Time.get_ticks_usec() - started) / 1000.0)
		if not _validate_common(game, "Rescue Rush", level):
			_cleanup(main)
			await _frames(2)
			continue
		_validate_rescue(game, level)
		if level in CHECKPOINTS:
			await _capture("rescue-%03d-initial" % level)
		var steps := 0
		while is_instance_valid(game) and not bool(game.get("rescued")) and steps < 160:
			if bool(game.get("board_locked")):
				if not await _wait_rescue_ready(game, 360):
					_fail("Rescue Rush L%d stayed locked" % level)
					break
			if bool(game.get("rescued")):
				break
			if game.has_method("can_show_hint") and not bool(game.call("can_show_hint")):
				_fail("Rescue Rush L%d had no verified assist before completion" % level)
				break
			game.call("show_hint")
			steps += 1
			assist_steps["rescue_rush"] = int(assist_steps["rescue_rush"]) + 1
			if not await _wait_rescue_progress(game, 360):
				_fail("Rescue Rush L%d assist produced no progress" % level)
				break
			if level in CHECKPOINTS and steps == 1:
				await _capture("rescue-%03d-active" % level)
		if is_instance_valid(game) and not bool(game.get("rescued")):
			_fail("Rescue Rush L%d did not complete within %d assists" % [level, steps])
		_cleanup(main)
		await _frames(2)

func _sweep_multi(main: Control, game_id: String) -> void:
	var display := "Water Sort" if game_id == "water_sort" else "Block Puzzle"
	for level in range(1, 101):
		multi_game_manager.call("clear_checkpoint", game_id)
		var started := Time.get_ticks_usec()
		main.call("start_multi_level", game_id, level, false)
		await _frames(5)
		var game = main.get("active_game")
		launch_ms[game_id].append(float(Time.get_ticks_usec() - started) / 1000.0)
		if not _validate_common(game, display, level):
			_cleanup(main)
			await _frames(2)
			continue
		if game_id == "water_sort":
			_validate_water(game, level)
		else:
			_validate_block(game, level)
		if level in CHECKPOINTS:
			await _capture("%s-%03d-initial" % [game_id, level])
		var steps := 0
		var max_steps := 360 if game_id == "water_sort" else 220
		while is_instance_valid(game) and not bool(game.get("completed")) and steps < max_steps:
			if game_id == "water_sort":
				if not await _water_step(game, level):
					break
			else:
				if not await _block_step(game, level):
					break
			steps += 1
			assist_steps[game_id] = int(assist_steps[game_id]) + 1
			if level in CHECKPOINTS and steps == 1:
				await _capture("%s-%03d-active" % [game_id, level])
		if is_instance_valid(game) and not bool(game.get("completed")):
			_fail("%s L%d did not complete within %d assists" % [display, level, steps])
		_cleanup(main)
		await _frames(2)

func _water_step(game: Node, level: int) -> bool:
	if game.has_method("_has_active_pours") and bool(game.call("_has_active_pours")):
		if not await _wait_water_idle(game, 480):
			_fail("Water Sort L%d pour did not settle" % level)
			return false
	if bool(game.get("completed")):
		return true
	if game.has_method("can_show_hint") and not bool(game.call("can_show_hint")):
		_fail("Water Sort L%d had no verified assist before completion" % level)
		return false
	var before := int(game.get("moves"))
	game.call("show_hint")
	for _i in range(480):
		if not is_instance_valid(game):
			return true
		if bool(game.get("completed")):
			return true
		var active := bool(game.call("_has_active_pours")) if game.has_method("_has_active_pours") else bool(game.get("animating"))
		if int(game.get("moves")) > before and not active:
			return true
		await process_frame
	_fail("Water Sort L%d assist produced no settled move" % level)
	return false

func _block_step(game: Node, level: int) -> bool:
	if bool(game.get("_clear_transition_active")):
		for _i in range(360):
			if not is_instance_valid(game) or bool(game.get("completed")) or not bool(game.get("_clear_transition_active")):
				break
			await process_frame
	if not is_instance_valid(game) or bool(game.get("completed")):
		return true
	var before := int(game.get("placements"))
	game.call("show_hint")
	for _i in range(360):
		if not is_instance_valid(game):
			return true
		if bool(game.get("completed")):
			return true
		var clearing := bool(game.get("_clear_transition_active"))
		if int(game.get("placements")) > before and not clearing:
			return true
		await process_frame
	_fail("Block Puzzle L%d assist produced no settled placement" % level)
	return false

func _validate_common(game: Variant, name: String, level: int) -> bool:
	if game == null or not is_instance_valid(game) or not game is Control:
		_fail("%s L%d did not create a valid ActiveGame" % [name, level])
		return false
	var control := game as Control
	if not control.visible or not control.is_visible_in_tree():
		_fail("%s L%d is not visible" % [name, level])
		return false
	if control.size.x < 500.0 or control.size.y < 900.0:
		_fail("%s L%d has undersized root %s" % [name, level, str(control.size)])
		return false
	_validate_visible_buttons(control, name, level)
	return true

func _validate_visible_buttons(root_control: Control, name: String, level: int) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(VIEWPORT))
	var stack: Array[Node] = [root_control]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is Button:
			var button := node as Button
			if not button.visible or not button.is_visible_in_tree():
				continue
			var rect := button.get_global_rect()
			if rect.size.x < 34.0 or rect.size.y < 28.0:
				_fail("%s L%d has too-small visible button %s size=%s" % [name, level, button.name, str(rect.size)])
			var overlap := rect.intersection(viewport_rect)
			if overlap.size.x < rect.size.x - 2.0 or overlap.size.y < rect.size.y - 2.0:
				_fail("%s L%d has clipped visible button %s rect=%s" % [name, level, button.name, str(rect)])

func _validate_rescue(game: Node, level: int) -> void:
	var board = game.get("board_grid")
	var pieces = game.get("pieces")
	if board == null or not board is GridContainer or board.get_child_count() <= 0:
		_fail("Rescue Rush L%d board missing" % level)
	if not pieces is Array or pieces.is_empty():
		_fail("Rescue Rush L%d pieces missing" % level)

func _validate_water(game: Node, level: int) -> void:
	var board = game.get("board")
	var tubes = game.get("tubes")
	if board == null or not board is GridContainer:
		_fail("Water Sort L%d board missing" % level)
	if not tubes is Array or tubes.size() < 5:
		_fail("Water Sort L%d tube data invalid" % level)
	elif board.get_child_count() != tubes.size():
		_fail("Water Sort L%d rendered %d tubes for %d data tubes" % [level, board.get_child_count(), tubes.size()])

func _validate_block(game: Node, level: int) -> void:
	var cells = game.get("cell_buttons")
	var pieces = game.get("pieces")
	if not cells is Array or cells.size() != 64:
		_fail("Block Puzzle L%d did not render 64 cells" % level)
	if not pieces is Array or pieces.size() != 3:
		_fail("Block Puzzle L%d did not render three tray pieces" % level)

func _wait_rescue_ready(game: Node, max_frames: int) -> bool:
	for _i in range(max_frames):
		if not is_instance_valid(game) or bool(game.get("rescued")) or not bool(game.get("board_locked")):
			return true
		await process_frame
	return false

func _wait_rescue_progress(game: Node, max_frames: int) -> bool:
	var active_before := _active_rescue_pieces(game)
	for _i in range(max_frames):
		if not is_instance_valid(game) or bool(game.get("rescued")):
			return true
		if not bool(game.get("board_locked")) and _active_rescue_pieces(game) < active_before:
			return true
		await process_frame
	return false

func _active_rescue_pieces(game: Node) -> int:
	var count := 0
	for raw in (game.get("pieces") as Array):
		if raw is Dictionary and bool((raw as Dictionary).get("active", true)):
			count += 1
	return count

func _wait_water_idle(game: Node, max_frames: int) -> bool:
	for _i in range(max_frames):
		if not is_instance_valid(game) or bool(game.get("completed")):
			return true
		var active := bool(game.call("_has_active_pours")) if game.has_method("_has_active_pours") else bool(game.get("animating"))
		if not active:
			return true
		await process_frame
	return false

func _capture(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Screenshot capture failed: %s" % stem)
		return
	var err := image.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + stem + ".png"))
	if err != OK:
		_fail("Screenshot write failed: %s (%s)" % [stem, err])

func _cleanup(main: Control) -> void:
	if main.has_method("_remove_active_game"):
		main.call("_remove_active_game")

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _stats(values: Array) -> Dictionary:
	if values.is_empty():
		return {}
	var copy := values.duplicate()
	copy.sort()
	var sum := 0.0
	for value in copy:
		sum += float(value)
	var p95_index := clampi(int(ceil(float(copy.size()) * 0.95)) - 1, 0, copy.size() - 1)
	return {
		"count": copy.size(),
		"mean": sum / float(copy.size()),
		"p95": float(copy[p95_index]),
		"max": float(copy[-1]),
	}

func _fail(message: String) -> void:
	if not failures.has(message):
		failures.append(message)

func _fatal(message: String) -> void:
	push_error(message)
	quit(1)
