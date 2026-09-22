extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var icon := _read("res://assets/icon.svg")
	var adaptive := _read("res://assets/icon_adaptive_foreground.svg")
	var export_cfg := _read("res://export_presets.cfg")

	if icon.is_empty():
		failures.append("Legacy launcher icon source is missing")
	else:
		if not icon.contains("LauncherSafeForeground"):
			failures.append("Legacy launcher foreground safe-zone wrapper is missing")
		if not icon.contains("translate(245 269) scale(.76)"):
			failures.append("Legacy launcher foreground lost its approved optical-centering transform")
		if icon.contains(">UNJAM<"):
			failures.append("Launcher icon must remain symbol-only without app-name text")

	if adaptive.is_empty():
		failures.append("Adaptive launcher foreground source is missing")
	else:
		if not adaptive.contains("AdaptiveSafeZone"):
			failures.append("Adaptive launcher safe-zone group is missing")
		if not adaptive.contains("scale(.84)") or not adaptive.contains("translate(53 80) scale(.80)"):
			failures.append("Adaptive launcher foreground lost its optical-centering safe transform")
		if adaptive.contains(">UNJAM<"):
			failures.append("Adaptive launcher foreground must remain symbol-only")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon.svg\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_adaptive_foreground.svg\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher export contract missing: %s" % token)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_ICON_SAFE_ZONE_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
