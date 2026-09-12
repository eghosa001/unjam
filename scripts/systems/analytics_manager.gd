extends Node

var enabled := true

func track(event_name: String, properties: Dictionary = {}) -> void:
	if not enabled:
		return
	# Development fallback. Replace with Firebase/GameAnalytics adapter later.
	print("[analytics] %s %s" % [event_name, JSON.stringify(properties)])

func level_started(level_number: int) -> void:
	track("level_start", {"level": level_number})

func level_completed(level_number: int, moves: int, stars: int) -> void:
	track("level_complete", {"level": level_number, "moves": moves, "stars": stars})

func level_restarted(level_number: int) -> void:
	track("level_restart", {"level": level_number})

func hint_used(level_number: int) -> void:
	track("hint_used", {"level": level_number})

func undo_used(level_number: int) -> void:
	track("undo_used", {"level": level_number})
