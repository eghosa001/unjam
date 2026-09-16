extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var art := Unjam3DGameArt.new()
	art.configure("water_sort")
	root.add_child(art)
	if art.viewport_3d == null:
		push_error("Game preview did not create its SubViewport synchronously")
		quit(1)
		return
	if art.viewport_3d.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		push_error("Game preview must prime with UPDATE_ALWAYS until its first visible frames are rendered")
		quit(1)
		return
	await process_frame
	await process_frame
	await process_frame
	if art.viewport_3d.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
		push_error("Game preview stayed in UPDATE_ALWAYS instead of returning to one-shot/idle rendering")
		quit(1)
		return
	art.queue_free()
	print("3D game preview initial render priming validated.")
	quit(0)
