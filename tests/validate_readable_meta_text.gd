extends SceneTree

func _initialize() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	if source.count("var readable_floor := mini(start_size, maxi(12, min_size))") != 2:
		push_error("Small-screen font fit may shrink primary labels below readable size")
		quit(1)
		return
	if source.count("while size > readable_floor") != 2:
		push_error("Text fitting does not honor the readable floor")
		quit(1)
		return
	for item in ["fitted_label.accessibility_name = text_value", "label.accessibility_name = raw_text", "label.tooltip_text = raw_text"]:
		if not source.contains(item):
			push_error("Clipped meta text has no full accessibility fallback: %s" % item)
			quit(1)
			return
	print("READABLE_META_TEXT_OK: text floor and full accessible fallback")
	quit(0)
