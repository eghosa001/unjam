extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	for script_path in [
		"res://scripts/game/game.gd",
		"res://scripts/game/rescue_rush_polished.gd",
		"res://scripts/game/rescue_rush_premium.gd",
		"res://scripts/game/rescue_rush_motion_final.gd",
		"res://scripts/game/rescue_rush_casual.gd",
		"res://scripts/game/rescue_rush_assisted.gd",
	]:
		var script_resource := load(script_path)
		if script_resource == null:
			return _fail("Rescue hierarchy script failed to load: %s" % script_path)
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue Rush scene could not be loaded")
	var game := packed.instantiate() as Control
	game.set("level_number",1)
	root.add_child(game)
	await _frames(10)

	var board_panel := game.get("board_panel") as PanelContainer
	var board_grid := game.get("board_grid") as GridContainer
	var objective := game.find_child("RescueObjectiveLabel",true,false) as Label
	if board_panel == null or board_grid == null or objective == null:
		return _fail("Rescue Rush gameplay hierarchy is incomplete")
	if game.find_child("RescueScenicGround", true, false) != null:
		return _fail("Rescue scenic background regained the opaque ground layer that creates horizontal seams")
	var hint_button := game.find_child("RescueHintAction", true, false) as Button
	if hint_button == null or not bool(hint_button.get_meta("unjam_hint_badge_top_right", false)):
		return _fail("Rescue compact Hint control no longer owns its in-face cost-badge placement")
	if board_panel.size.distance_to(Vector2(348,348)) > 1.0:
		return _fail("Rescue board is not using the restored 348x348 play area")
	var width := int(game.get("width"))
	var height := int(game.get("height"))
	if width != 7 or height != 7:
		return _fail("Opening Rescue campaign level should preserve its 7x7 progression board")
	if board_grid.columns != width or board_grid.get_child_count() != width * height:
		return _fail("Rescue board does not render its complete progression grid")
	if board_grid.get_theme_constant("h_separation") != 5 or board_grid.get_theme_constant("v_separation") != 5:
		return _fail("Rescue grid gaps are still too large")
	var minimum_cell := 40.0
	for child in board_grid.get_children():
		if child is Control and (child as Control).custom_minimum_size.x < minimum_cell:
			return _fail("Rescue grid cells are still undersized")
	var expected_objective := String(game.call("_compact_objective_instruction"))
	if objective.text != expected_objective:
		return _fail("Rescue objective copy drifted from active objective: %s != %s" % [objective.text, expected_objective])

	var arrow_source := _read("res://scripts/ui/rescue_piece_3d_button.gd")
	for token in [
		"func _draw_motion_trail(_center: Vector2, _pulse: float) -> void:",
		"var bright_tile := accent.get_luminance() >= 0.46",
		"draw_colored_polygon(points, fill)",
		"draw_polyline(closed, keyline",
	]:
		if not arrow_source.contains(token):
			return _fail("Rescue flat-arrow clarity contract is missing: %s" % token)
	for forbidden in ["cast.append(", "side.append(", "draw_polygon(side", "Directional spine reinforces orientation"]:
		if arrow_source.contains(forbidden):
			return _fail("Rescue arrow regained 3D/extruded decoration: %s" % forbidden)

	var rescue_source := _read("res://scripts/game/rescue_rush_polished.gd")
	if rescue_source.contains("PremiumVisuals.burst(Vector2(540, 860)") or not rescue_source.contains("board_panel.get_global_rect().get_center()"):
		return _fail("Rescue completion celebration is not anchored to the live board")

	game.queue_free()
	await process_frame

	var late_game := packed.instantiate() as Control
	late_game.set("level_number", 10000)
	root.add_child(late_game)
	await _frames(10)
	var late_grid := late_game.get("board_grid") as GridContainer
	if late_grid == null or int(late_game.get("width")) < 8 or int(late_game.get("height")) < 8:
		return _fail("Late Rescue finale did not load its dense board for rendering validation")
	if late_grid.get_theme_constant("h_separation") != 3 or late_grid.get_theme_constant("v_separation") != 3:
		return _fail("Dense Rescue finale spacing did not gain the compact 3px rendering gap")
	late_game.queue_free()
	await process_frame

	var hint_source := _read("res://scripts/systems/hint_manager.gd")
	if not hint_source.contains("unjam_hint_badge_top_right") or not hint_source.contains("VERTICAL_ALIGNMENT_TOP if top_right"):
		return _fail("Rescue Hint coin cost can drift back onto the lower button bevel")

	print("Rescue Rush normal and dense rendering hierarchy validated.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
