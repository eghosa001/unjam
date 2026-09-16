extends SceneTree

func _initialize() -> void:
	var main_file := FileAccess.open("res://scripts/ui/premium_main_casual.gd", FileAccess.READ)
	var manager_file := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ)
	if main_file == null or manager_file == null:
		push_error("Secondary surface source is missing")
		quit(1)
		return
	var main_source := main_file.get_as_text()
	var manager_source := manager_file.get_as_text()
	var diorama_start := main_source.find("func _add_surface_diorama")
	var diorama_end := main_source.find("\nfunc ", diorama_start + 1)
	var diorama_block := main_source.substr(diorama_start, diorama_end - diorama_start)
	if not diorama_block.contains("content.remove_child(old)"):
		push_error("Surface diorama replacement can overlap old/new nodes for one frame")
		quit(1)
		return
	var chrome_start := manager_source.find("func _add_surface_chrome")
	var chrome_end := manager_source.find("\nfunc ", chrome_start + 1)
	var chrome_block := manager_source.substr(chrome_start, chrome_end - chrome_start)
	if not chrome_block.contains("content.remove_child(existing)"):
		push_error("Surface chrome replacement can overlap old/new nodes for one frame")
		quit(1)
		return
	print("Secondary surface replacements detach outgoing nodes before rebuilding.")
	quit(0)
