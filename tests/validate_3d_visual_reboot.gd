extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check("res://scripts/ui/unjam_3d_theme.gd", ["class_name Unjam3DTheme", "gloss_button", "panel_3d", "SKY_TOP"], failures)
	_check("res://scripts/ui/premium_home_casual.gd", ["UNJAM", "build_home_launcher", "_make_game_card", "_make_bottom_nav"], failures)
	var home := _read("res://scripts/ui/premium_home_casual.gd")
	for legacy in ["PremiumBackdrop.new()", "GameShowcaseArt.new()", "UnjamLogo.new()"]:
		if home.contains(legacy):
			failures.append("Legacy home visual still active: " + legacy)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("3D visual reboot contract validated.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _check(path: String, needles: Array[String], failures: Array[String]) -> void:
	var text := _read(path)
	if text.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if not text.contains(needle):
			failures.append("Missing 3D visual contract '%s' in %s" % [needle, path])
