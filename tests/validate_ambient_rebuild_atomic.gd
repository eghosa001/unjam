extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/systems/premium_visuals.gd", FileAccess.READ)
	if file == null:
		push_error("Premium visuals source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func clear_ambient")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start)
	if not block.contains("overlay.remove_child(child)"):
		push_error("Ambient accent refresh can overlap outgoing and incoming sparkles for one frame")
		quit(1)
		return
	print("Ambient sparkle replacement is atomic.")
	quit(0)
