extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/systems/premium_visuals.gd", FileAccess.READ)
	if file == null:
		push_error("Premium visuals source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	if not source.contains("set_process(not _reduced_motion())"):
		push_error("Premium visuals still schedules frame processing in Reduced Motion")
		quit(1)
		return
	var ready_start := source.find("func _ready()")
	var ready_end := source.find("\nfunc ", ready_start + 1)
	var ready_block := source.substr(ready_start, ready_end - ready_start)
	if ready_block.contains("set_process(true)"):
		push_error("Premium visuals unconditionally enables frame processing at startup")
		quit(1)
		return
	print("Premium visuals frame processing follows motion preference.")
	quit(0)
