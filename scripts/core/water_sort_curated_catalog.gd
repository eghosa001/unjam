extends RefCounted
class_name WaterSortCuratedCatalog

const MAX_LEVEL := 10000
const CHAPTER_SIZE := 500
const CATALOG_VERSION := 1
const BASE_PATH := "res://data/water_sort_curated"

static var _chapter_cache: Dictionary = {}

static func level(raw_level: int) -> Dictionary:
	var level_id := clampi(raw_level, 1, MAX_LEVEL)
	var chapter := int((level_id - 1) / CHAPTER_SIZE) + 1
	var entries: Array = _chapter(chapter)
	if entries.is_empty():
		return {}
	var index := posmod(level_id - 1, CHAPTER_SIZE)
	if index < 0 or index >= entries.size():
		return {}
	var raw = entries[index]
	if not raw is Dictionary:
		return {}
	var entry := raw as Dictionary
	if int(entry.get("l", -1)) != level_id:
		return {}
	var raw_tubes = entry.get("t", [])
	var raw_solution = entry.get("s", [])
	if not raw_tubes is Array or not raw_solution is Array:
		return {}
	var tubes: Array = (raw_tubes as Array).duplicate(true)
	var solution: Array[Vector2i] = []
	for raw_move in raw_solution as Array:
		if not raw_move is Array or (raw_move as Array).size() != 2:
			return {}
		var pair := raw_move as Array
		solution.append(Vector2i(int(pair[0]), int(pair[1])))
	if tubes.is_empty() or solution.is_empty():
		return {}
	return {
		"tubes": tubes,
		"solution": solution,
		"catalog_version": CATALOG_VERSION,
		"chapter": chapter,
		"authored_level": level_id,
	}

static func has_level(raw_level: int) -> bool:
	return not level(raw_level).is_empty()

static func clear_cache() -> void:
	_chapter_cache.clear()

static func _chapter(chapter: int) -> Array:
	if _chapter_cache.has(chapter):
		return _chapter_cache[chapter] as Array
	var path := "%s/chapter_%02d.json" % [BASE_PATH, chapter]
	if not FileAccess.file_exists(path):
		push_warning("Water curated chapter missing: %s" % path)
		_chapter_cache[chapter] = []
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_chapter_cache[chapter] = []
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Water curated chapter invalid JSON: %s" % path)
		_chapter_cache[chapter] = []
		return []
	var payload := parsed as Dictionary
	if int(payload.get("v", -1)) != CATALOG_VERSION:
		push_warning("Water curated chapter version mismatch: %s" % path)
		_chapter_cache[chapter] = []
		return []
	var entries = payload.get("levels", [])
	if not entries is Array or (entries as Array).size() != CHAPTER_SIZE:
		push_warning("Water curated chapter must contain %d levels: %s" % [CHAPTER_SIZE, path])
		_chapter_cache[chapter] = []
		return []
	var out := entries as Array
	_chapter_cache[chapter] = out
	return out
