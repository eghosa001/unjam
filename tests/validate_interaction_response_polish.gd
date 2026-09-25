extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var shop := FileAccess.get_file_as_string("res://scripts/ui/monetization_hub_3d.gd")
	var rescue := FileAccess.get_file_as_string("res://scripts/game/rescue_rush_polished.gd")
	var hints := FileAccess.get_file_as_string("res://scripts/systems/hint_manager.gd")
	var settings := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var touch := FileAccess.get_file_as_string("res://scripts/ui/ui_touch_enhancer_casual.gd")
	var main := FileAccess.get_file_as_string("res://scripts/ui/robust_main.gd")

	for old_color in ["#1b63c5", "#173f98", "#0a1d58", "#101932", "#0b1631", "#060d22"]:
		if shop.contains(old_color):
			failures.append("Shop still contains retired blue background color %s" % old_color)
	for neutral in ["#e4dfd5", "#b3aca2", "#80786e", "#363636", "#272727", "#1c1c1c"]:
		if not shop.contains(neutral):
			failures.append("Shop is missing current neutral background color %s" % neutral)

	if rescue.count('tween_property(ghost, "position"') != 1:
		failures.append("Rescue arrow position is still split across multiple tween segments")
	if not rescue.contains('tween_property(ghost, "position", final_target, travel_time)'):
		failures.append("Rescue arrow does not use one continuous offscreen position tween")

	if not hints.contains("const HINT_COST := 25"):
		failures.append("Hint coin price changed or disappeared")
	for token in ["EconomyManager", "HintCoinCost", "ACTION_MODE_BUTTON_PRESS", "request_hint_for_game"]:
		if not hints.contains(token):
			failures.append("Paid Hint contract missing %s" % token)

	for token in ["SETTINGS_HELP_GAMES", "_settings_help_game_label", "_cycle_settings_help_game", "show_tutorial\", _settings_help_game"]:
		if not settings.contains(token):
			failures.append("Settings single-game How to Play contract missing %s" % token)
	if settings.contains('show_tutorial\", selected_game_id'):
		failures.append("Settings How to Play still depends on the last globally selected game")

	if not touch.contains("func _apply_fast_action_mode"):
		failures.append("Safe touch-down response helper is missing")
	if not touch.contains("button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS"):
		failures.append("Safe controls are not configured for touch-down response")
	for protected in ['node_name.begins_with("Buy_")', '"REWARDED" in node_name.to_upper()', '"RESTORE" in node_name.to_upper()']:
		if not touch.contains(protected):
			failures.append("Sensitive action release guard missing %s" % protected)

	for scene_constant in ["RESCUE_GAME_SCENE", "WATER_GAME_SCENE", "BLOCK_GAME_SCENE"]:
		if not main.contains(scene_constant):
			failures.append("Gameplay scene preload missing %s" % scene_constant)
	if main.contains('load("res://scenes/Game.tscn")'):
		failures.append("Rescue launch still performs a synchronous scene resource load")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("INTERACTION_RESPONSE_POLISH_OK")
	quit(0)
