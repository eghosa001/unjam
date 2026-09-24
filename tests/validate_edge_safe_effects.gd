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
	var banner_start := source.find("func show_reward_banner")
	var banner_end := source.find("func tactile_success", banner_start)
	var banner_block := source.substr(banner_start, banner_end - banner_start)
	if banner_start < 0 or not banner_block.contains("get_visible_rect") or not banner_block.contains("banner_width") or banner_block.contains("panel.position = Vector2(160, 180)"):
		push_error("Reward banner is not viewport-relative")
		quit(1)
		return
	if not source.contains("func _celebration_origin()") or source.contains("burst(Vector2(540, 760)"):
		push_error("Reward celebration origin is still hard-coded")
		quit(1)
		return
	if not source.contains("rng.randf_range(min_x, max_x)") or not source.contains("rng.randf_range(min_y, max_y)"):
		push_error("Ambient sparkles are not bounded to the live viewport")
		quit(1)
		return
	print("Edge-safe premium effects validated.")
	quit(0)
