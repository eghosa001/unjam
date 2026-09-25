extends RefCounted
class_name RescueRushAuthoredCatalog

const TOTAL_LEVELS := 10000
const CHAPTER_SIZE := 500
const CHAPTER_COUNT := 20
const CATALOG_VERSION := 1
const ROOT := "res://data/rescue_rush/authored"

static var _chapter_cache: Dictionary = {}

static func recipe(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, TOTAL_LEVELS)
	var chapter := int((n - 1) / CHAPTER_SIZE) + 1
	var rows := _chapter(chapter)
	var index := posmod(n - 1, CHAPTER_SIZE)
	if index < 0 or index >= rows.size():
		return {}
	var raw = rows[index]
	if not raw is Dictionary:
		return {}
	var result: Dictionary = (raw as Dictionary).duplicate(true)
	if int(result.get("level", 0)) != n:
		return {}
	return result

static func chapter(level_or_chapter: int, treat_as_level: bool = true) -> Array:
	var chapter_number := int((clampi(level_or_chapter, 1, TOTAL_LEVELS) - 1) / CHAPTER_SIZE) + 1 if treat_as_level else clampi(level_or_chapter, 1, CHAPTER_COUNT)
	return _chapter(chapter_number).duplicate(true)

static func clear_cache() -> void:
	_chapter_cache.clear()

static func _chapter(chapter_number: int) -> Array:
	var chapter := clampi(chapter_number, 1, CHAPTER_COUNT)
	if _chapter_cache.has(chapter):
		return _chapter_cache[chapter]
	var path := "%s/chapter_%02d.json" % [ROOT, chapter]
	if not FileAccess.file_exists(path):
		return []
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return []
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return []
	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) != CATALOG_VERSION or int(payload.get("chapter", 0)) != chapter:
		return []
	var levels = payload.get("levels", [])
	if not levels is Array or levels.size() != CHAPTER_SIZE:
		return []
	_chapter_cache[chapter] = levels
	return levels
