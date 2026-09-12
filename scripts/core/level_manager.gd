extends Node

const LEVEL_DIR := "res://data/levels/"
const CAMPAIGN_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100
var current_level := 1

func load_level(level_number: int) -> Dictionary:
	current_level = level_number
	var path := LEVEL_DIR + "level_%02d.json" % level_number
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				return parsed
	if level_number >= 1 and level_number <= CAMPAIGN_LEVELS:
		return CampaignGenerator.generate(level_number)
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
