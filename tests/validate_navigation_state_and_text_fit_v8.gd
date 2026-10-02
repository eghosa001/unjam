extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var live := FileAccess.get_file_as_string("res://scripts/ui/premium_live_hub.gd")
	var main := FileAccess.get_file_as_string("res://scripts/ui/robust_main.gd")
	var sidekick := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var canvas := FileAccess.get_file_as_string("res://scripts/ui/figma_reference_canvas.gd")
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var selector := FileAccess.get_file_as_string("res://scripts/ui/premium_live_hub_3d.gd")

	var home_selector_block := _function_block(home, "func _open_game_selector() -> void:")
	_check('_open_games_surface' in home_selector_block, "Choose Game does not always open the Games selector", failures)
	_check('choose.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE' in home, "Home Choose Game still fires on touch-down and can pass through into a selector card", failures)

	var play_block := _function_block(live, "func _play(game_id: String) -> void:")
	_check('resume_game' in play_block, "Selecting a game no longer resumes its unfinished campaign run", failures)
	_check('open_game_campaign' not in play_block, "Games selector bypasses resume behavior", failures)

	_check('DAILY_CAMPAIGN_BACKUPS_KEY := "daily_campaign_checkpoint_backups"' in main, "Daily checkpoint isolation key missing", failures)
	_check('_stash_campaign_checkpoint_for_daily(game_id)' in main, "Daily does not park campaign checkpoint", failures)
	_check('_restore_campaign_checkpoint_after_daily(game_id)' in main, "Daily does not restore campaign checkpoint", failures)
	var daily_block := _function_block(main, "func start_game_daily(game_id: String) -> void:")
	_check('SaveManager.data["active_run"] = {}' not in daily_block, "Rescue Daily still destroys campaign checkpoint", failures)
	_check('MultiGameManager.clear_checkpoint(game_id)' not in daily_block, "Daily still directly destroys campaign checkpoint", failures)

	_check('static func fit_single_line_text' in canvas and 'font.get_string_size' in canvas, "Shared text-fit helper missing", failures)
	_check('_fit_single_line_control_text(header_title, 182.0, 23, 14)' in sidekick, "Sidekick header title is not fitted", failures)
	_check('_fit_single_line_control_text(friend, 196.0, 25, 14)' in sidekick, "Sidekick playmate name is not fitted", failures)
	_check('Rect2(35, 312, 300, 130), 15' in sidekick, "Sidekick tip is not constrained inside its card", failures)
	_check('func _fit_wrapped_text' in sidekick and '_fit_wrapped_text(tip, 296.0, 15, 12)' in sidekick, "Sidekick wrapped text fitting is missing", failures)
	_check('RefCanvas.fit_single_line_text(button' in home, "Home translated buttons are not fitted", failures)
	_check('RefCanvas.fit_single_line_text(label' in selector, "Choose Game translated nav text is not fitted", failures)

	if failures.is_empty():
		print("NAVIGATION_STATE_AND_TEXT_FIT_V8_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
