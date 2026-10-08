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
			'_make_label("WIN • ONE COLOUR PER FULL TUBE", 17,',
			'drop.position = Vector2(39,144)'
		],
		"res://scripts/game/block_puzzle_3d.gd": [
			'goal_label = FigmaReferenceCanvas.label("", 17,',
			'status_label = FigmaReferenceCanvas.label("", 16,',
			'hint_label = FigmaReferenceCanvas.label("", 16,'
		],
		"res://scripts/ui/block_cell_button.gd": [
			'var idle_fill := Color(0.49, 0.34, 0.68, 0.49',
			'_draw_box(inset, idle_fill, 7, Color(0.88, 0.76, 1.0, 0.24'
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
