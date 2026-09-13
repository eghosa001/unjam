extends SceneTree

const Solver = preload("res://scripts/core/puzzle_solver.gd")
const Generator = preload("res://scripts/core/campaign_generator.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ProjectSettings.set_setting("monetization/test_mode", true)
	var errors: Array[String] = []
	var save_manager := get_root().get_node_or_null("SaveManager")
	var daily := get_root().get_node_or_null("DailyChallenge")
	var ads := get_root().get_node_or_null("AdManager")
	var retention := get_root().get_node_or_null("RetentionManager")
	if save_manager == null or daily == null or ads == null or retention == null:
		errors.append("Required production autoload missing")
		_finish(errors)
		return
	for level_number in [11, 25, 100, 101, 999, 2500, 5000, 7500, 9999, 10000]:
		var level: Dictionary = Generator.generate(level_number)
		if not Solver.has_solution(level, 6000):
			errors.append("Representative level %d is not solvable" % level_number)
	var daily_level: Dictionary = daily.build_today()
	if daily_level.is_empty() or not Solver.has_solution(daily_level, 6000):
		errors.append("Daily challenge is not solvable")
	save_manager.reset_progress()
	var first: Dictionary = save_manager.complete_level(1, 3, "chick", 75)
	var second: Dictionary = save_manager.complete_level(1, 3, "chick", 75)
	if int(save_manager.data.total_levels_completed) != 1: errors.append("Replay incorrectly increments unique completion count")
	if int(save_manager.data.perfect_clears) != 1: errors.append("Replay incorrectly increments unique perfect count")
	if int(first.get("base_coins", -1)) != 75: errors.append("First-clear reward accounting is incorrect")
	if int(second.get("base_coins", -1)) != 0: errors.append("Replay reward duplication protection failed")
	if int(save_manager.data.get("save_version", 0)) < 3: errors.append("Robust save version is missing")
	ads.completed_since_interstitial = 0
	ads.set_ads_enabled(true)
	for i in range(ads.interstitial_interval): ads.note_level_completed()
	if not ads.should_show_interstitial(): errors.append("Interstitial pacing does not reach ready state")
	var missions: Array = retention.daily_missions()
	if missions.size() != 3: errors.append("Daily mission count changed unexpectedly")
	save_manager.reset_progress()
	_finish(errors)

func _finish(errors: Array[String]) -> void:
	if not errors.is_empty():
		for error in errors: printerr(error)
		printerr("Production robustness validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Production robustness validated: solvability, daily challenge, save accounting, ad pacing and retention invariants.")
	quit(0)
