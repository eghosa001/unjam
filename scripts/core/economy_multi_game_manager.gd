extends "res://scripts/core/multi_game_manager.gd"

# Preserve MultiGameManager's progression calculations while surfacing the
# direct coin mutations it performs for Water Sort / Block Puzzle.

func _economy() -> Node:
	return get_node_or_null("/root/EconomyManager")

func claim_daily_task(id: String, task_id: String) -> bool:
	var previous := int(SaveManager.data.get("coins", 0))
	var claimed := super.claim_daily_task(id, task_id)
	if claimed:
		var economy := _economy()
		if economy != null:
			economy.call("notify_external_change", previous, "daily_task_reward", {"game": id, "task": task_id})
	return claimed

func complete_daily(id: String, reward := 100) -> bool:
	var safe_reward := maxi(0, int(reward))
	var previous := int(SaveManager.data.get("coins", 0))
	var completed := super.complete_daily(id, safe_reward)
	# Rescue Rush delegates to SaveManager.complete_daily(), whose economy-aware
	# wrapper already emits the semantic transaction.
	if completed and id != "rescue_rush":
		var economy := _economy()
		if economy != null:
			economy.call("notify_external_change", previous, "daily_reward", {"game": id, "reward": safe_reward})
	return completed

func complete_level(id: String, n: int, stars: int, coin_reward := 25) -> Dictionary:
	var safe_reward := maxi(0, int(coin_reward))
	var rewards := super.complete_level(id, n, stars, safe_reward)
	# Rescue Rush delegates to SaveManager.complete_level() and is already synced.
	if id == "rescue_rush":
		return rewards
	var direct_delta := 0
	if bool(rewards.get("first_clear", false)):
		direct_delta += safe_reward
	if bool(rewards.get("milestone", false)):
		direct_delta += 100
	if bool(rewards.get("world_badge", false)):
		direct_delta += 250
	if direct_delta != 0:
		var economy := _economy()
		if economy != null and economy.has_method("record_external_delta"):
			economy.call("record_external_delta", direct_delta, "level_reward", {
				"game": id,
				"level": n,
				"stars": stars,
				"first_clear": bool(rewards.get("first_clear", false))
			})
	return rewards
