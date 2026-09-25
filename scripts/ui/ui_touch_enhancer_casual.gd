extends "res://scripts/ui/ui_touch_enhancer.gd"

func _apply_fast_action_mode(button: Button) -> void:
	# Gameplay board pieces own gesture semantics. Purchase/reward/restore actions
	# stay release-confirmed to avoid accidental paid/ad actions on touch-down.
	if _is_block_cell_button(button) or _is_water_tube_widget(button) or _is_rescue_piece_button(button):
		return
	var label := button.text.strip_edges().to_upper()
	var node_name := String(button.name)
	var confirmation_action := (
		node_name.begins_with("Buy_")
		or "REWARDED" in node_name.to_upper()
		or "RESTORE" in node_name.to_upper()
		or "WATCH" in label
		or "RESTORE PURCHASES" in label
	)
	if not confirmation_action:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

func _apply_button_size(button: Button) -> void:
	_apply_fast_action_mode(button)
	if button.has_meta("unjam_figma_exact_geometry"):
		return
	if _is_block_cell_button(button) or _is_water_tube_widget(button) or _is_rescue_piece_button(button):
		return
	var label := button.text.strip_edges().to_upper()
	button.add_theme_font_size_override("font_size", maxi(25, button.get_theme_font_size("font_size")))
	var wanted := Vector2(maxf(button.custom_minimum_size.x, 132.0), maxf(button.custom_minimum_size.y, 88.0))
	var is_back := label == "←" or label == "‹" or label == "BACK" or label.begins_with("← ") or label.contains("BACK HOME")
	if is_back:
		wanted = Vector2(maxf(button.custom_minimum_size.x, 128.0), maxf(button.custom_minimum_size.y, 92.0))
		button.add_theme_font_size_override("font_size", maxi(28, button.get_theme_font_size("font_size")))
	match host.name:
		"Game":
			if is_back or label.contains("RETRY"): wanted = Vector2(132, 92)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(240, 92)
			elif label.contains("NEXT RESCUE") or label.contains("BACK HOME"): wanted = Vector2(390, 98)
		"WaterSort":
			if is_back or label.contains("RETRY"): wanted = Vector2(132, 92)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(240, 92)
		"BlockPuzzle":
			if _is_block_piece_button(button): wanted = Vector2(280, 158)
			elif is_back or label.contains("RETRY"): wanted = Vector2(166, 94)
			elif label.contains("UNDO") or label.contains("HINT"): wanted = Vector2(240, 92)
		"Main":
			if label.begins_with("PLAY"): wanted = Vector2(maxf(button.custom_minimum_size.x, 300), 108)
			elif label == "CONTINUE": wanted = Vector2(300, 94)
			elif is_back: wanted = Vector2(132, 96)
			elif label.contains("PREV") or label == "CURRENT" or label.contains("NEXT"): wanted = Vector2(240, 96)
	if wanted.x > button.custom_minimum_size.x or wanted.y > button.custom_minimum_size.y:
		button.custom_minimum_size = Vector2(maxf(wanted.x, button.custom_minimum_size.x), maxf(wanted.y, button.custom_minimum_size.y))
