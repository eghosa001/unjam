extends SceneTree

func _initialize() -> void:
	var text := FileAccess.get_file_as_string("res://tools/sample_authored_variety.py")
	for fragment in ["CHAPTERS = (1, 10, 20)", "CONTENT_SAMPLE_OK", "authored_seed", "distinct_boards"]:
		if not text.contains(fragment):
			push_error("Sampled content audit missing: %s" % fragment)
			quit(1)
			return
	print("AUTHORED_SAMPLE_CONTRACT_OK")
	quit(0)
