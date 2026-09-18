extends SceneTree

const TALL_VIEWPORT := Vector2i(1080, 1920)
const SELECTOR_VIEWPORTS := [
	Vector2i(540, 960),
	Vector2i(720, 1280),
	Vector2i(1080, 1920),
	Vector2i(1440, 3200)
]
const MAX_TRAILING_ACTION_GAP := 180.0
const MIN_SELECTOR_TRAILING_GAP := 32.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = TALL_VIEWPORT
	var failures: Array[String] = []
	await _check_scene("res://scenes/WaterSort.tscn", "GameplayStageHolder", failures)
	await _check_scene("res://scenes/Game.tscn", "GameplayBoardHolder", failures)
	for viewport_size in SELECTOR_VIEWPORTS:
		await _check_selector(viewport_size, failures)
	if failures.is_empty():
		print("PASS compact gameplay stack")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_scene(path: String, holder_name: String, failures: Array[String]) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Could not load %s" % path)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _frames(2)
	var holder := scene.find_child(holder_name, true, false) as Control
	if holder == null:
		failures.append("%s missing %s" % [path, holder_name])
		scene.queue_free()
		await process_frame
		return
	if holder.size_flags_vertical != Control.SIZE_EXPAND_FILL:
		failures.append("%s gameplay holder does not absorb tall-screen surplus height" % path)
	if holder.get_child_count() == 0 or not (holder.get_child(0) is Control):
		failures.append("%s holder has no visual gameplay child" % path)
	else:
		var visual := holder.get_child(0) as Control
		if visual.get_global_rect().end.y > holder.get_global_rect().end.y + 1.0:
			failures.append("%s gameplay visual spills below its holder" % path)
		if path.ends_with("WaterSort.tscn") and visual.size_flags_vertical != Control.SIZE_EXPAND_FILL:
			failures.append("Water Sort stage leaves avoidable vertical dead space inside its holder")
	var actions := scene.find_child("CompactGameActions", true, false) as Control
	if actions == null:
		failures.append("%s missing CompactGameActions" % path)
	else:
		var trailing_gap := root.get_visible_rect().size.y - actions.get_global_rect().end.y
		if trailing_gap > MAX_TRAILING_ACTION_GAP:
			failures.append("%s leaves %.1fpx unused below gameplay actions on a tall phone" % [path, trailing_gap])
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
	await _frames(4)
	main.set("current_surface", "live")
	if main.has_signal("surface_changed"):
		main.emit_signal("surface_changed", "live")
	await _frames(4)
	var live := main.get_node_or_null("PremiumLive") as Control
	var header := main.find_child("GameSelectorHeader", true, false) as Control
	var scroll := main.find_child("GameSelectorScroll", true, false) as ScrollContainer
	var nav := main.find_child("GameSelectorBottomNav", true, false) as Control
	var title := main.find_child("GameSelectorTitle", true, false) as Label
	if live == null or header == null or scroll == null or nav == null or title == null:
		failures.append("Game selector responsive structure is incomplete at %s" % str(viewport_size))
	else:
		var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
		for control in [live, header, scroll, nav]:
			var rect: Rect2 = (control as Control).get_global_rect()
			if not _inside(rect, screen):
				failures.append("Game selector control %s spills outside %s: %s" % [control.name, str(viewport_size), str(rect)])
		var header_rect := header.get_global_rect()
		var scroll_rect := scroll.get_global_rect()
		var nav_rect := nav.get_global_rect()
		if header_rect.intersects(nav_rect) or scroll_rect.intersects(nav_rect):
			failures.append("Game selector content overlaps bottom navigation at %s" % str(viewport_size))
		if scroll_rect.size.y < 180.0:
			failures.append("Game selector scroll viewport is too short at %s: %.1fpx" % [str(viewport_size), scroll_rect.size.y])
		if title.get_theme_font_size("font_size") < 26:
			failures.append("Game selector title became unreadably small at %s" % str(viewport_size))
		for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
			var card := main.find_child("GameCard3D_%s" % game_id, true, false) as Control
			var art := main.find_child("GameArtShell_%s" % game_id, true, false) as Control
			if card == null or art == null:
				failures.append("Game selector %s card/art missing at %s" % [game_id, str(viewport_size)])
				continue
			if not card.get_global_rect().encloses(art.get_global_rect()):
				failures.append("Game selector %s artwork escapes its card at %s" % [game_id, str(viewport_size)])
		print("SELECTOR_COMPOSITION %s header=%s scroll=%s nav=%s" % [str(viewport_size), str(header_rect), str(scroll_rect), str(nav_rect)])
	main.queue_free()
	await process_frame

func _inside(rect: Rect2, viewport_rect: Rect2) -> bool:
	var epsilon := 2.0
	return rect.position.x >= viewport_rect.position.x - epsilon \
		and rect.position.y >= viewport_rect.position.y - epsilon \
		and rect.end.x <= viewport_rect.end.x + epsilon \
		and rect.end.y <= viewport_rect.end.y + epsilon

func _find_label(node: Node, fragment: String) -> Label:
	if node is Label and fragment in (node as Label).text:
		return node as Label
	for child in node.get_children():
		var found := _find_label(child, fragment)
		if found != null:
			return found
	return null

func _find_button(node: Node, fragment: String) -> Button:
	if node is Button and fragment in (node as Button).text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, fragment)
		if found != null:
			return found
	return null

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
