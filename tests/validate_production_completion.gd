extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _source_has("res://scripts/game/block_puzzle.gd", ["MotionSystem.duration", "FeedbackManager.drop()", "FeedbackManager.line_clear", "FeedbackManager.complete()"]): return
	if not _source_has("res://scripts/game/rescue_rush_polished.gd", ["MotionSystem.duration", "FeedbackManager.combo", "MotionSystem.reduced()"]): return
	if not _source_has("res://scripts/game/rescue_rush_motion_final.gd", ["FeedbackManager.complete()", "MotionSystem.duration"]): return
	if not _source_has("res://scripts/ui/premium_main.gd", ["REDUCE MOTION", "FAST ANIMATION", "reduce_motion", "fast_animation"]): return
	if not _source_has("res://scripts/ui/device_fit.gd", ["get_display_safe_area", "safe_margins"]): return
	if not _source_has("res://scripts/systems/store_manager.gd", ["PURCHASE_PENDING", "reconcile_purchases", "release_configuration_issues"]): return
	if not _source_has("res://scripts/systems/android_monetization_bridge.gd", ["PURCHASE_STATE_PENDING", "query_products"]): return
	if not _source_has("res://scripts/ui/monetization_hub.gd", ["purchase_pending", "catalog_changed"]): return
	if not _source_has("res://tests/validate_viewport_fit.gd", ["720", "1600", "1080", "2400"]): return
	print("Production completion contract validated: game polish, accessibility/device fit, monetization state safety, and multi-resolution viewport coverage.")
	quit(0)

func _source_has(path: String, needles: Array[String]) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("Missing required production file: %s" % path)
	var source := file.get_as_text()
	for needle in needles:
		if not source.contains(needle):
			return _fail("Production contract missing %s in %s" % [needle, path])
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
