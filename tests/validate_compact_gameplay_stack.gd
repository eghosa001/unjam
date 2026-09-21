extends SceneTree

const TALL_VIEWPORT := Vector2i(1080,1920)
const SELECTOR_VIEWPORTS := [
	Vector2i(540,960),
	Vector2i(720,1280),
	Vector2i(1080,1920),
	Vector2i(1440,3200)
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	root.size = TALL_VIEWPORT
	await _check_game_scene("res://scenes/WaterSort.tscn","FigmaWater390x844","GameplayStage",Rect2(17,169,354,420),"CompactGameActions",Rect2(21,650,346,60),failures)
	await _check_water_header(failures)
	await _check_water_footer(failures)
	await _check_game_scene("res://scenes/Game.tscn","FigmaRescue390x844","RescueBoardPanel",Rect2(21,180,348,348),"CompactGameActions",Rect2(21,566,346,62),failures)
	for viewport_size in SELECTOR_VIEWPORTS:
		await _check_selector(viewport_size,failures)
	if failures.is_empty():
		print("PASS Figma compact gameplay stack")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_game_scene(path: String, canvas_name: String, stage_name: String, stage_expected: Rect2, actions_name: String, actions_expected: Rect2, failures: Array[String]) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Could not load %s" % path)
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	var canvas := scene.find_child(canvas_name,true,false) as Control
	var stage := scene.find_child(stage_name,true,false) as Control
	var actions := scene.find_child(actions_name,true,false) as Control
	if canvas == null or stage == null or actions == null:
		failures.append("%s Figma hierarchy is incomplete" % path)
	else:
		if not _rect_eq(Rect2(stage.position,stage.size),stage_expected):
			failures.append("%s stage drifted from Figma reference: %s" % [path,str(Rect2(stage.position,stage.size))])
		if not _rect_eq(Rect2(actions.position,actions.size),actions_expected):
			failures.append("%s action row drifted from Figma reference: %s" % [path,str(Rect2(actions.position,actions.size))])
		var screen := Rect2(Vector2.ZERO,root.get_visible_rect().size)
		for control in [stage,actions]:
			if not _inside((control as Control).get_global_rect(),screen):
				failures.append("%s control %s spills outside tall viewport" % [path,control.name])
	scene.queue_free()
	await process_frame

func _check_water_header(failures: Array[String]) -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		failures.append("Could not load WaterSort.tscn for header audit")
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	var meta := scene.get("meta_label") as Label
	var moves := scene.get("move_label") as Label
	if meta == null or moves == null:
		failures.append("Water header labels are missing")
	else:
		if meta.get_global_rect().intersects(moves.get_global_rect()):
			failures.append("Water metadata and move labels overlap")
		if not meta.clip_text or not moves.clip_text:
			failures.append("Water header labels must clip instead of bleeding into each other")
		if meta.get_theme_font_size("font_size") < 13 or moves.get_theme_font_size("font_size") < 13:
			failures.append("Water header text fell below 13px reference size")
	scene.queue_free()
	await process_frame

func _check_water_footer(failures: Array[String]) -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		failures.append("Could not load WaterSort.tscn for footer audit")
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	var status := scene.find_child("WaterStatusText",true,false) as Label
	var guidance := scene.find_child("WaterGuidanceText",true,false) as Label
	var actions := scene.find_child("CompactGameActions",true,false) as Control
	if status == null or guidance == null or actions == null:
		failures.append("Water footer hierarchy is incomplete")
	else:
		var status_rect := status.get_global_rect()
		var guidance_rect := guidance.get_global_rect()
		var action_rect := actions.get_global_rect()
		if status_rect.intersects(guidance_rect):
			failures.append("Water status and guidance rows overlap")
		if guidance_rect.intersects(action_rect):
			failures.append("Water guidance overlaps action row")
		if status.get_theme_font_size("font_size") < 14 or guidance.get_theme_font_size("font_size") < 14:
			failures.append("Water footer text fell below 14px reference size")
	scene.queue_free()
	await process_frame

func _check_selector(viewport_size: Vector2i, failures: Array[String]) -> void:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		failures.append("Could not load Main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(6)
	main.call("build_home")
	await _frames(3)
	var home := main.get_node_or_null("PremiumHome") as Control
	var games := home.find_child("HomeLevelsNavButton",true,false) as Button if home != null else null
	if games == null:
		failures.append("Home Games action missing at %s" % str(viewport_size))
		main.queue_free()
		await process_frame
		return
	games.pressed.emit()
	await _frames(6)

	var live := main.get_node_or_null("PremiumLive") as Control
	var canvas := live.find_child("FigmaSelector390x844",true,false) as Control if live != null else null
	var nav := live.find_child("SelectorBottomNav",true,false) as Control if live != null else null
	if live == null or canvas == null or nav == null:
		failures.append("Figma selector structure is incomplete at %s" % str(viewport_size))
	else:
		var screen := Rect2(Vector2.ZERO,root.get_visible_rect().size)
		if not _inside(nav.get_global_rect(),screen):
			failures.append("Selector bottom nav spills outside %s" % str(viewport_size))
		if not _rect_eq(Rect2(nav.position,nav.size),Rect2(13,757,362,70)):
			failures.append("Selector bottom nav drifted from Figma geometry")
		var specs := {
			"rescue_rush": Rect2(17,111,354,160),
			"water_sort": Rect2(17,285,354,160),
			"block_puzzle": Rect2(17,459,354,160)
		}
		for game_id in specs.keys():
			var card := live.find_child("GameCard3D_%s" % game_id,true,false) as Control
			var hit := live.find_child("SelectorCardHit_%s" % game_id,true,false) as Button
			if card == null or hit == null:
				failures.append("Selector %s card/hit target missing at %s" % [game_id,str(viewport_size)])
				continue
			if not _rect_eq(Rect2(card.position,card.size),specs[game_id]):
				failures.append("Selector %s card drifted from Figma reference" % game_id)
			if not _inside(card.get_global_rect(),screen):
				failures.append("Selector %s card spills outside %s" % [game_id,str(viewport_size)])
	main.queue_free()
	await process_frame

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _inside(rect: Rect2, viewport_rect: Rect2) -> bool:
	var epsilon := 2.0
	return rect.position.x >= viewport_rect.position.x - epsilon and rect.position.y >= viewport_rect.position.y - epsilon and rect.end.x <= viewport_rect.end.x + epsilon and rect.end.y <= viewport_rect.end.y + epsilon

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
