extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/systems/live_hub_launcher.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	var source := "" if file == null else file.get_as_text()
	var selector_file := FileAccess.open("res://scripts/ui/premium_live_hub_3d.gd", FileAccess.READ)
	var selector := "" if selector_file == null else selector_file.get_as_text()
	var failures: Array[String] = []
	if source.contains("func _process("):
		failures.append("LiveHubLauncher still owns an always-running frame callback")
	if not source.contains("launcher.visible = false"):
		failures.append("LiveHubLauncher must keep its retired floating launcher hidden")
	if not source.contains("set_process(false)"):
		failures.append("LiveHubLauncher must explicitly sleep after setup")
	if not selector.contains("SelectorRewardsOpenButton") or not selector.contains("LiveHubLauncher.open_hub()"):
		failures.append("Retention rewards exist in code but are not exposed from the visible game selector")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LiveHubLauncher stays hidden without an idle frame loop.")
	quit(0)
