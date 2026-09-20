extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var specs := [
		["res://scenes/Game.tscn", "RescuePremiumFeedback"],
		["res://scenes/WaterSort.tscn", "WaterPremiumFeedback"],
		["res://scenes/BlockPuzzle.tscn", "BlockPremiumFeedback"],
	]
	for spec in specs:
		var packed := load(String(spec[0])) as PackedScene
		if packed == null:
			return _fail("Premium benchmark scene failed to load: %s" % String(spec[0]))
		var game := packed.instantiate() as Control
		root.add_child(game)
		await _frames(8)
		var feedback := game.find_child(String(spec[1]), true, false) as Control
		if feedback == null:
			return _fail("Missing premium gameplay feedback layer: %s" % String(spec[1]))
		if feedback.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return _fail("%s may intercept gameplay touches" % String(spec[1]))
		feedback.call("show_banner", "PREMIUM FLOW", Color("#ffd166"), Vector2(270, 260), 190.0)
		feedback.call("show_ring", Vector2(270, 430), 92.0, Color("#67e8ff"))
		feedback.call("show_sweep", Rect2(90, 360, 360, 120), Color("#ff7a66"))
		await _frames(2)
		if feedback.find_child("PremiumGameplayBanner", true, false) == null:
			return _fail("%s failed to render its premium banner" % String(spec[1]))
		if feedback.find_child("PremiumGameplayRing", true, false) == null:
			return _fail("%s failed to render its local success ring" % String(spec[1]))
		if feedback.find_child("PremiumGameplaySweep", true, false) == null:
			return _fail("%s failed to render its local clear sweep" % String(spec[1]))
		game.queue_free()
		await _frames(2)

	var water_source := _read("res://scripts/game/water_sort_10000.gd")
	if not water_source.contains("PERFECT TUBE") or not water_source.contains("_pour_flow_streak"):
		return _fail("Water Sort premium flow/solved-tube feature is missing")
	var rescue_source := _read("res://scripts/game/rescue_rush_assisted.gd")
	if not rescue_source.contains("FLOW ×%d") or not rescue_source.contains("show_ring"):
		return _fail("Rescue Rush premium flow feedback is missing")
	var block_source := _read("res://scripts/game/block_puzzle_10000.gd")
	if not block_source.contains("LINE BLAST") or not block_source.contains("show_sweep"):
		return _fail("Block Puzzle premium combo/sweep feedback is missing")

	print("PREMIUM_BENCHMARK_FEATURES_OK")
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
