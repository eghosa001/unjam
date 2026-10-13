extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var profile := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var privacy := FileAccess.get_file_as_string("res://scripts/ui/privacy_analytics_sheet.gd")
	for fragment in [
		"fit_single_line_text(label, label_width - 2.0, 13, 12)",
		"font_size, mini(font_size, 12)",
	]:
		if not home.contains(fragment):
			failures.append("Home nav/action text can shrink to tiny glyphs: " + fragment)
	for fragment in [
		"_fit_single_line_control_text(stat_label,68.0,12,12)",
		"_fit_single_line_control_text(achievement_progress,146.0,12,12)"
	]:
		if not profile.contains(fragment):
			failures.append("Profile caption/progress must remain readable: " + fragment)
	for fragment in [
		'_label(stack, _copy("heading"), 24, Color.WHITE, true)',
		'_label(stack, _copy("subheading"), 16, Color("#f0d580"), true)',
		"label.accessibility_name = value",
		"label.tooltip_text = value",
	]:
		if not privacy.contains(fragment):
			failures.append("Localized privacy text can clip or lose accessibility copy: " + fragment)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("MOBILE_TEXT_READABILITY_OK: 12px navigation/profile floor, wrapping privacy headings, full accessibility text")
	quit(0)
