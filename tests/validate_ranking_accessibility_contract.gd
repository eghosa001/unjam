extends SceneTree

func _initialize() -> void:
	var ui := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var mandatory := [
		"friend_name_label.tooltip_text = friend_full_name",
		"friend_name_label.accessibility_name =",
		"player_label.tooltip_text = full_player_name",
		"player_label.accessibility_name =",
		"progress.accessibility_name =",
		"own.accessibility_name =",
		"row.get(\"rank\",i+1)",
	]
	for text in mandatory:
		if not ui.contains(text):
			push_error("Compact ranking loses full player name, place or accessible score: %s" % text)
			quit(1)
			return
	if not ui.contains("Rank %d, %s, %d levels, %d stars"):
		push_error("Full player name and earned progression not spoken")
		quit(1)
		return
	print("RANKING_ACCESSIBILITY_OK: full names and actual tied ranks remain readable by screen reader")
	quit(0)
