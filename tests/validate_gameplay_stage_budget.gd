extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/unjam_3d_gameplay_stage.gd", FileAccess.READ)
	if file == null:
		push_error("3D gameplay stage source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	if source.contains("SubViewport.UPDATE_ALWAYS"):
		push_error("Gameplay 3D environment still renders continuously")
		quit(1)
		return
	if not source.contains("SubViewport.UPDATE_ONCE"):
		push_error("Gameplay 3D environment is not one-shot rendered")
		quit(1)
		return
	if source.contains("func _process(delta") or source.contains("set_process(true)"):
		push_error("Gameplay 3D environment still owns an always-running animation loop")
		quit(1)
		return
	print("Gameplay 3D stage render budget validated.")
	quit(0)
