extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var project := FileAccess.get_file_as_string("res://project.godot")
	var selector := FileAccess.get_file_as_string("res://scripts/ui/premium_live_hub_3d.gd")
	var rescue := FileAccess.get_file_as_string("res://scripts/game/game.gd")
	var block := FileAccess.get_file_as_string("res://scripts/game/block_puzzle.gd")
	var multi := FileAccess.get_file_as_string("res://scripts/core/multi_game_manager.gd")
	var save := FileAccess.get_file_as_string("res://scripts/core/save_manager.gd")

	for token in ["RetentionManager", "LiveHubLauncher"]:
		if project.contains(token):
			failures.append("Retired Rewards & Events autoload still exists: %s" % token)
	for token in ["REWARDS & EVENTS", "SelectorRewardsPanel", "SelectorRewardsOpenButton", "LiveHubLauncher"]:
		if selector.contains(token):
			failures.append("Choose Game still exposes retired Rewards & Events UI: %s" % token)
	for path in [
		"res://scenes/RetentionHub.tscn",
		"res://scripts/systems/live_hub_launcher.gd",
		"res://scripts/systems/retention_manager.gd",
		"res://scripts/systems/robust_retention_manager.gd",
		"res://scripts/systems/economy_retention_manager.gd",
		"res://scripts/ui/retention_hub.gd",
		"res://scripts/ui/retention_hub_3d.gd"
	]:
		if FileAccess.file_exists(path):
			failures.append("Retired Rewards & Events file still ships: %s" % path)
	for token in ["event_shop_owned", "event_currency", "gold_rescue_frame", "aurora_trail", "crystal_garden"]:
		if rescue.contains(token) or block.contains(token):
			failures.append("Gameplay still depends on retired event reward state: %s" % token)
	for token in ["TASK_REWARD", "daily_tasks(", "claim_daily_task(", "_advance_tasks("]:
		if multi.contains(token):
			failures.append("Retired hub task-reward machinery still exists: %s" % token)
	for token in ["event_currency", "event_shop_owned", "daily_tasks"]:
		if not save.contains(token):
			failures.append("Save migration no longer purges retired state: %s" % token)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Rewards & Events removal validated: UI, managers, gameplay hooks and stale state are gone.")
	quit(0)
