extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/ui_touch_enhancer.gd", FileAccess.READ)
	if file == null:
		push_error("Touch enhancer source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func _enlarge_buttons")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start)
	if not block.contains("node != host") or not block.contains("get_node_or_null(\"UiTouchEnhancer\")"):
		push_error("Parent touch enhancer still descends into surfaces with their own enhancer")
		quit(1)
		return
	print("Touch enhancer ownership stops at nested enhanced surfaces.")
	quit(0)
