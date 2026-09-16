extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/RetentionHub.tscn") as PackedScene
	var hub := packed.instantiate() as Control
	root.add_child(hub)
	await process_frame
	await process_frame
	var baseline := hub.get_child_count()
	hub.refresh()
	var after_first := hub.get_child_count()
	hub.refresh()
	var after_second := hub.get_child_count()
	if after_first > baseline + 1 or after_second > after_first + 1:
		push_error("Retention refresh leaves old UI trees parented during rebuild: %d -> %d -> %d" % [baseline, after_first, after_second])
		hub.queue_free()
		quit(1)
		return
	hub.queue_free()
	print("Retention hub refresh replaces its UI tree atomically.")
	quit(0)
