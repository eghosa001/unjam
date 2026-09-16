extends SceneTree

func _init() -> void:
	if not _validate_design_palette(): return
	if not _validate_home_density_contract(): return
	if not _validate_game_tile_adoption(): return
	if not _validate_backdrop_adoption(): return
	print("Vibrant visual contract validated: bright canvas, saturated game identity, dense full-height launcher, and colorful backdrop are active.")
	quit(0)

func _validate_design_palette() -> bool:
	var script := load("res://scripts/ui/premium_design_system.gd") as Script
	if script == null or not script.can_instantiate():
		return _fail("Premium design system is missing")
	for method_name in ["vibrant_canvas", "vibrant_surface", "game_gradient"]:
		if not script.has_method(method_name):
			return _fail("Missing vibrant design helper: " + method_name)
	var canvas: Color = script.call("vibrant_canvas", "rescue_rush")
	if canvas.get_luminance() < 0.56:
		return _fail("Vibrant canvas is still too dark")
	var rescue: Array = script.call("game_gradient", "rescue_rush")
	var water: Array = script.call("game_gradient", "water_sort")
	var block: Array = script.call("game_gradient", "block_puzzle")
	if rescue.size() < 2 or water.size() < 2 or block.size() < 2:
		return _fail("Game gradients need at least two stops")
	if rescue[0].is_equal_approx(water[0]) or water[0].is_equal_approx(block[0]):
		return _fail("Each game needs a distinct saturated identity")
	return true

func _validate_home_density_contract() -> bool:
	var file := FileAccess.open("res://scripts/ui/premium_home_casual.gd", FileAccess.READ)
	if file == null:
		return _fail("Premium home launcher source is missing")
	var source := file.get_as_text()
	for marker in ["VIBRANT_REFERENCE_TARGET", "HomeFeatureStrip", "HomeGameShelf", "vibrant_canvas", "game_gradient"]:
		if not source.contains(marker):
			return _fail("Home launcher has not adopted vibrant dense layout marker: " + marker)
	if source.contains("margin_left\", 34") or source.contains("margin_right\", 34"):
		return _fail("Home launcher still keeps the old wide side gutters")
	return true

func _validate_game_tile_adoption() -> bool:
	var file := FileAccess.open("res://scripts/ui/game_select_tile.gd", FileAccess.READ)
	if file == null:
		return _fail("Game tile source is missing")
	var source := file.get_as_text()
	for marker in ["game_gradient", "vibrant_surface", "card_glow"]:
		if not source.contains(marker):
			return _fail("Game tiles are not using the vibrant card language: " + marker)
	return true

func _validate_backdrop_adoption() -> bool:
	var file := FileAccess.open("res://scripts/ui/premium_backdrop.gd", FileAccess.READ)
	if file == null:
		return _fail("Premium backdrop source is missing")
	var source := file.get_as_text()
	for marker in ["sky_top", "sky_bottom", "decorative_orbs", "horizon_glow"]:
		if not source.contains(marker):
			return _fail("Backdrop is missing colorful environmental layer: " + marker)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
