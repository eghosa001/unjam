extends "res://scripts/ui/ui_touch_enhancer.gd"

func _apply_button_size(button: Button) -> void:
	if _is_block_cell_button(button) or _is_water_tube_widget(button):
		return
	var label := button.text.strip_edges().to_upper()
	var wanted := Vector2(maxf(button.custom_minimum_size.x, 116.0), maxf(button.custom_minimum_size.y, 76.0))
	var is_back := label == "←" or label == "‹" or label == "BACK" or label.begins_with("← ") or label.contains("BACK HOME")
	if is_back:
		wanted = Vector2(maxf(button.custom_minimum_size.x, 104.0), maxf(button.custom_minimum_size.y, 72.0))
		button.add_theme_font_size_override("font_size", maxi(20, button.get_theme_font_size("font_size")))
	match host.name:
		"Game":
			if is_back or label.contains("RETRY"): wanted = Vector2(104, 72)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(220, 72)
			elif label.contains("NEXT RESCUE") or label.contains("BACK HOME"): wanted = Vector2(360, 82)
		"WaterSort":
			if is_back or label.contains("RETRY"): wanted = Vector2(104, 72)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(220, 72)
		"BlockPuzzle":
			if _is_block_piece_button(button): wanted = Vector2(260, 142)
			elif is_back or label.contains("RETRY"): wanted = Vector2(150, 76)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(220, 72)
		"Main":
			if label.begins_with("PLAY"): wanted = Vector2(maxf(button.custom_minimum_size.x, 270), 92)
			elif label == "CONTINUE": wanted = Vector2(270, 76)
			elif is_back: wanted = Vector2(104, 82)
			elif label.contains("PREV") or label == "CURRENT" or label.contains("NEXT"): wanted = Vector2(220, 82)
	if wanted.x > button.custom_minimum_size.x or wanted.y > button.custom_minimum_size.y:
		button.custom_minimum_size = Vector2(maxf(wanted.x, button.custom_minimum_size.x), maxf(wanted.y, button.custom_minimum_size.y))
