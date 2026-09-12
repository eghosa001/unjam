extends Node

const LEVEL_DIR := "res://data/levels/"
var current_level := 1

func load_level(level_number: int) -> Dictionary:
	current_level = level_number
	var path := LEVEL_DIR + "level_%02d.json" % level_number
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func has_level(level_number: int) -> bool:
	return FileAccess.file_exists(LEVEL_DIR + "level_%02d.json" % level_number)

func get_level_count() -> int:
	var count := 0
	var dir := DirAccess.open(LEVEL_DIR)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.begins_with("level_") and name.ends_with(".json"):
			count += 1
		name = dir.get_next()
	dir.list_dir_end()
	return count
