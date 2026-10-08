extends SceneTree

# Focused UI copy and font contract; runtime fit/overlap is independently
# verified by validate_viewport_fit and rendered visual-audit screenshots.
func _initialize() -> void:
	var checks := {
		"res://scripts/game/rescue_rush_casual.gd": [
			'RefCanvas.label("LEVEL %d • WORLD %d" % [level_number,world],14,',
			'RefCanvas.label(_compact_objective_instruction(),16,'
		],
		"res://scripts/game/water_sort_casual.gd": [
			'_make_label("WIN • ONE COLOUR PER FULL TUBE", 17,'
		],
		"res://scripts/game/block_puzzle_3d.gd": [
			'goal_label = FigmaReferenceCanvas.label("", 17,',
			'status_label = FigmaReferenceCanvas.label("", 16,',
			'hint_label = FigmaReferenceCanvas.label("", 16,'
		]
	}
	for path in checks:
		var source := FileAccess.get_file_as_string(String(path))
		for token in checks[path]:
			if not source.contains(String(token)):
				push_error("Gameplay HUD readability regressed: " + String(path))
				quit(1)
				return
	print("GAMEPLAY_HUD_READABILITY_OK")
	quit(0)
