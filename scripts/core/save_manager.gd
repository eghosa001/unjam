extends Node

const SAVE_PATH := "user://unjam_save.json"

var data: Dictionary = {
	"highest_level": 1,
	"stars": {},
	"rescued": [],
	"coins": 0,
	"sound": true,
	"vibration": true
}

func _ready() -> void:
	load_save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed:
			data[key] = parsed[key]

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func complete_level(level_number: int, stars: int, rescue_id: String, coin_reward: int = 25) -> void:
	var key := str(level_number)
	data.stars[key] = max(int(data.stars.get(key, 0)), stars)
	data.highest_level = max(int(data.highest_level), level_number + 1)
	data.coins = int(data.coins) + coin_reward
	if not rescue_id.is_empty() and not rescue_id in data.rescued:
		data.rescued.append(rescue_id)
	save()

func get_stars(level_number: int) -> int:
	return int(data.stars.get(str(level_number), 0))

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= int(data.highest_level)

func reset_progress() -> void:
	data = {"highest_level": 1, "stars": {}, "rescued": [], "coins": 0, "sound": true, "vibration": true}
	save()
