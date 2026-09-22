extends Node

const LEVEL_DIR := "res://data/levels/"
const CAMPAIGN_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100
var current_level := 1
var _cached_level_number := -1
var _cached_level: Dictionary = {}

func _cache_level(level_number: int, level: Dictionary) -> Dictionary:
	_cached_level_number = level_number
	_cached_level = level.duplicate(true)
	return _cached_level.duplicate(true)

func load_level(level_number: int) -> Dictionary:
	current_level = level_number
	if level_number == _cached_level_number and not _cached_level.is_empty():
		return _cached_level.duplicate(true)
	# The original hand-authored starter files are intentionally simple. Use the
	# richer campaign generator for the opening ten levels as well.
	if level_number >= 1 and level_number <= 10:
		return _cache_level(level_number, CampaignGenerator.generate(level_number))
	var path := LEVEL_DIR + "level_%02d.json" % level_number
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				return _cache_level(level_number, parsed)
	if level_number >= 1 and level_number <= CAMPAIGN_LEVELS:
		return _cache_level(level_number, CampaignGenerator.generate(level_number))
	return {}

func has_level(level_number: int) -> bool:
	return level_number >= 1 and level_number <= CAMPAIGN_LEVELS

func get_level_count() -> int:
	return CAMPAIGN_LEVELS

func world_for_level(level_number: int) -> int:
	return int((level_number - 1) / LEVELS_PER_WORLD) + 1

func first_level_in_world(world: int) -> int:
	return (clamp(world, 1, WORLD_COUNT) - 1) * LEVELS_PER_WORLD + 1

func last_level_in_world(world: int) -> int:
	return min(first_level_in_world(world) + LEVELS_PER_WORLD - 1, CAMPAIGN_LEVELS)

func highest_unlocked_world() -> int:
	return clamp(world_for_level(int(SaveManager.data.get("highest_level", 1))), 1, WORLD_COUNT)

func world_name(world: int) -> String:
	var themes := ["Garden Escape", "Locks & Keys", "Chain Reaction", "Blast Lab", "Linked Zone", "Chaos Rescue", "Portal Works", "Crystal Circuit", "Neon Factory", "Rescue Nexus"]
	var theme := String(themes[(world - 1) % themes.size()])
	var chapter := int((world - 1) / themes.size()) + 1
	return "%s %d" % [theme, chapter] if chapter > 1 else theme
