extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/systems/premium_visuals.gd", FileAccess.READ)
	if file == null:
		push_error("Premium visuals source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func screen_flash")
	var finish := source.find("func entrance", start)
	if start < 0 or finish <= start:
		push_error("screen_flash implementation is missing")
		quit(1)
		return
	var block := source.substr(start, finish - start)
	if block.contains("PRESET_FULL_RECT") or block.contains("ColorRect.new()"):
		push_error("screen_flash still uses a full-screen rectangle and can flash screen edges")
		quit(1)
		return
	if not block.contains("Polygon2D.new()") or not block.contains("get_visible_rect"):
		push_error("screen_flash is not using the centered edge-safe pulse")
		quit(1)
		return
	print("Edge-safe premium effects validated.")
	quit(0)
