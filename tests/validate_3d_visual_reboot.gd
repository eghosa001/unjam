extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check("res://scripts/ui/premium_home_direct_levels.gd", ["FigmaHome390x844", "GAME_ART_SCRIPT", "HomeHeroFlatGameLogo", "HomeLevelsNavButton"], failures)
	_check("res://scripts/ui/unjam_2d_game_art.gd", ["class_name Unjam2DGameArt", "_draw_rescue", "_draw_water", "_draw_block"], failures)
	_check("res://scripts/ui/unjam_meta_art.gd", ["class_name UnjamMetaArt", "_draw_compete", "_draw_collection"], failures)
	_check("res://scripts/ui/premium_main_casual.gd", ["FigmaSurface390x844", "META_ART_SCRIPT", "_figma_surface_accent"], failures)
	_check("res://scripts/game/rescue_rush_casual.gd", ["FigmaRescue390x844", "RescueBoardPanel", "RescueHintAction"], failures)
	_check("res://scripts/ui/rescue_token.gd", ["class_name RescueToken", "extends Control", "func celebrate"], failures)
	_check("res://scripts/game/water_sort_casual.gd", ["FigmaWater390x844", "GameplayStage", "WaterHintAction"], failures)
	_check("res://scripts/ui/water_tube_3d_motion.gd", ["extends \"res://scripts/ui/water_tube_reference_motion.gd\"", "func set_pour_progress"], failures)
	_check("res://scripts/game/block_puzzle_3d.gd", ["FigmaBlock390x844", "BlockBoardShell", "BlockPieceRow"], failures)
	_check("res://scripts/ui/block_cell_button.gd", ["Empty cells intentionally recede", "Saturated two-tone 2D material"], failures)
	for path in ["res://scripts/ui/rescue_token.gd", "res://scripts/ui/water_tube_3d_motion.gd"]:
		var source := _read(path)
		for forbidden in ["SubViewport", "Camera3D", "MeshInstance3D"]:
			if source.contains(forbidden):
				failures.append("Retired gameplay 3D token '%s' returned in %s" % [forbidden, path])

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("VISUAL_MASTER_RUNTIME_CONTRACT_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _check(path: String, needles: Array[String], failures: Array[String]) -> void:
	var source := _read(path)
	if source.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if not source.contains(needle):
			failures.append("Missing visual contract '%s' in %s" % [needle, path])
