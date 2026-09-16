extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/game/rescue_rush_motion_final.gd", FileAccess.READ)
	if file == null:
		push_error("Rescue Rush final motion source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func render_board()")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start if finish > start else source.length() - start)
	var detach := block.find("board_grid.remove_child(child)")
	var rebuild := block.find("super.render_board()")
	if detach < 0 or rebuild < 0 or detach > rebuild:
		push_error("Rescue board can overlap stale and rebuilt controls")
		quit(1)
		return
	print("Rescue Rush board rebuild is atomic.")
	quit(0)
