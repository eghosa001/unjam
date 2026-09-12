extends Node

const LEVEL_DIR := "res://data/levels/"
const CAMPAIGN_LEVELS := 60
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
	return int((level_number - 1) / 10) + 1

func world_name(world: int) -> String:
	match world:
		1: return "Garden Escape"
		2: return "Locks & Keys"
		3: return "Chain Reaction"
		4: return "Blast Lab"
		5: return "Linked Zone"
		_: return "Chaos Rescue"
