extends SceneTree

const TALL_VIEWPORT := Vector2i(1080, 1920)
const SELECTOR_VIEWPORTS := [
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
	var quote_label := _find_label(main, "Different puzzles.")
	var home_button := _find_button(main, "HOME")
	if quote_label == null or home_button == null:
		failures.append("Game selector final content or bottom navigation is missing at %s" % str(viewport_size))
	else:
		var quote := quote_label.get_parent() as Control
		var nav := home_button.get_parent().get_parent() as Control
		var gap := nav.get_global_rect().position.y - quote.get_global_rect().end.y
		var max_gap := maxf(140.0, float(viewport_size.y) * 0.075)
		print("SELECTOR_COMPOSITION %s gap=%.1f max=%.1f" % [str(viewport_size), gap, max_gap])
		if gap < MIN_SELECTOR_TRAILING_GAP:
			failures.append("Game selector content crowds/overlaps bottom navigation at %s: %.1fpx gap" % [str(viewport_size), gap])
		elif gap > max_gap:
			failures.append("Game selector leaves %.1fpx unused before bottom navigation at %s (max %.1fpx)" % [gap, str(viewport_size), max_gap])
	main.queue_free()
	await process_frame

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
