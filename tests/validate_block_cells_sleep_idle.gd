extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/block_cell_button.gd", FileAccess.READ)
	if file == null:
		push_error("Block cell source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["func _wake_animation", "set_process(false)", "_wake_animation()"]:
		if not source.contains(needle):
			push_error("Block cells do not sleep while idle: " + needle)
			quit(1)
			return
	var ready_start := source.find("func _ready()")
	var ready_end := source.find("\nfunc ", ready_start + 1)
	var ready_block := source.substr(ready_start, ready_end - ready_start)
	if ready_block.contains("set_process(true)"):
		push_error("All Block Puzzle cells still wake every frame at startup")
		quit(1)
		return
	print("Block Puzzle cells sleep while idle.")
	quit(0)
