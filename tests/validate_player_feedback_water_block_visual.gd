extends SceneTree

# Focused user-feedback contract: category-leading games keep the playfield
# primary, reward actual progress and avoid decorative GPU cost.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var tube_script := load("res://scripts/ui/water_tube_3d_motion.gd") as Script
	if tube_script == null:
		return _fail("Water tube component could not load")
	var tube = tube_script.new()
	tube.size = Vector2(110, 230)
	root.add_child(tube)
	tube.configure([3, 3, 3, 3], false, 0)
	await _frames(2)
	if not bool(tube.call("_tube_visually_complete")):
		return _fail("Complete Water bottle failed to show a solved material")
	tube.configure([3, 3, 3, 2], false, 0)
	if bool(tube.call("_tube_visually_complete")):
		return _fail("Mixed Water bottle was incorrectly rewarded")
	tube.configure([3, 3], false, 0)
	if bool(tube.call("_tube_visually_complete")):
		return _fail("Half-filled Water bottle was incorrectly rewarded")
	tube.configure([3, 3, 3, 3], false, 0)
	tube.begin_pour_out(1)
	if bool(tube.call("_tube_visually_complete")):
		return _fail("Animated pour falsely counts as a sorted tube")
	tube.queue_free()
	await _frames(2)

	var water_packed := load("res://scenes/WaterSort.tscn") as PackedScene
	var block_packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if water_packed == null or block_packed == null:
		return _fail("Gameplay scene resource missing")

	var water := water_packed.instantiate() as Control
	water.set("level_number", 5)
	root.add_child(water)
	await _frames(8)
	var water_stage := water.find_child("GameplayStage", true, false) as PanelContainer
	var water_art := water.find_child("WaterStageWorldArt", true, false) as Control
	var water_overlay := water.find_child("WaterAuthoredScreenWorld", true, false) as Control
	var water_ground := water.find_child("WaterScenicGround", true, false) as Control
	if water_stage == null or water_art == null or water_overlay == null or water_ground == null:
		return _fail("Water visual hierarchy missing")
	if water_art.modulate.a > 0.15 or water_overlay.modulate.a > 0.22 or water_ground.modulate.a > 0.23:
		return _fail("Water decorative world obscures active bottles")
	water.queue_free()
	await _frames(3)

	var block := block_packed.instantiate() as Control
	block.set("level_number", 5)
	root.add_child(block)
	await _frames(8)
	var block_board := block.get("board_grid") as GridContainer
	var block_art := block.find_child("BlockBoardWorldArt", true, false) as Control
	var tray_art := block.find_child("BlockTrayWorldArt", true, false) as Control
	var block_overlay := block.find_child("BlockAuthoredScreenWorld", true, false) as Control
	var block_ground := block.find_child("BlockScenicGround", true, false) as Control
	if block_board == null or block_board.get_child_count() != 64 or block_art == null or tray_art == null or block_overlay == null or block_ground == null:
		return _fail("Block visual hierarchy missing")
	if block_art.modulate.a > 0.15 or tray_art.modulate.a > 0.15 or block_overlay.modulate.a > 0.22 or block_ground.modulate.a > 0.23:
		return _fail("Block decorative world obscures the piece/tray state")

	var cell_source := FileAccess.get_file_as_string("res://scripts/ui/block_cell_button.gd")
	if not cell_source.contains("draw_colored_polygon(upper") or not cell_source.contains("draw_colored_polygon(lower") or not cell_source.contains("draw_colored_polygon(side"):
		return _fail("Block material lost low-cost face facets")
	block.queue_free()
	await _frames(2)
	print("PLAYER_FEEDBACK_WATER_BLOCK_VISUAL_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
