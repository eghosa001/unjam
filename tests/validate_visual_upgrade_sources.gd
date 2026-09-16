extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_source("res://scripts/ui/premium_design_system.gd", ["TITLE_MIN", "CTA_MIN", "NAV_MIN", "material_color"], failures)
	_check_source("res://scripts/ui/premium_home_casual.gd", ["HomeHero", "GameSelectTile", "_add_bottom_nav", "PremiumDesignSystem.apply_button"], failures)
	_check_source("res://scripts/game/rescue_rush_casual.gd", ["CompactStatusStrip", "RescueStoneFrame", "RESTART"], failures)
	_check_source("res://scripts/game/water_sort_casual.gd", ["CompactGameInfo", "WaterGlassFrame", "RESTART"], failures)
	_check_source("res://scripts/game/block_puzzle_ultra_motion.gd", ["_apply_premium_block_surface", "PremiumDesignSystem.apply_button"], failures)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Premium visual upgrade source contract validated.")
	quit(0)

func _check_source(path: String, needles: Array[String], failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Missing source: " + path)
		return
	var source := file.get_as_text()
	for needle in needles:
		if not source.contains(needle):
			failures.append("Missing premium source contract '%s' in %s" % [needle, path])
