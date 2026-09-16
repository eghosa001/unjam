extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script := load("res://scripts/game/water_sort_reference_motion.gd")
	var game = script.new()
	game.status_label = Label.new()
	game.status_label.text = "Pouring — keep going"
	game.active_source_tubes.clear()
	game.active_target_tubes.clear()
	game.pending_completion = false
	game._queued_action = ""

	if not game.has_method("_refresh_idle_status_after_pours"):
		push_error("Water Sort has no post-pour idle status refresh")
		quit(1)
		return
	game.call("_refresh_idle_status_after_pours")
	if game.status_label.text != "Ready to pour":
		push_error("Water Sort leaves stale pour feedback after all pours settle")
		quit(1)
		return
	game.status_label.free()
	game.free()
	print("Water Sort idle status refresh validated after all pours settle.")
	quit(0)
