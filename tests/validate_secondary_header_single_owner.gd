extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ)
	if file == null:
		push_error("Premium surface manager source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func _add_surface_chrome")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start)
	if block.contains("PanelContainer.new()") or block.contains("content.add_child(chrome)"):
		push_error("Secondary surface manager still adds a duplicate top badge over screen-owned headers")
		quit(1)
		return
	if not block.contains("content.remove_child(existing)"):
		push_error("Retired surface chrome must still be detached atomically if present")
		quit(1)
		return
	print("Secondary headers have one owner; legacy premium chrome is removed without replacement.")
	quit(0)
