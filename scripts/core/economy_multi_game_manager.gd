extends "res://scripts/core/multi_game_manager.gd"

# Preserve MultiGameManager's progression calculations while surfacing the
# direct coin mutations it performs for Water Sort / Block Puzzle.

func _economy() -> Node:
	return get_node_or_null("/root/EconomyManager")

func complete_daily(id: String, reward := 100) -> bool:
	var safe_reward := maxi(0, int(reward))
	var economy := _economy()
	var bonus := int(economy.call("collection_daily_bonus")) if economy != null and economy.has_method("collection_daily_bonus") else 0
	# Rescue Rush delegates to EconomySaveManager.complete_daily(), which adds
	# the collection bonus there. Add it here only for Water Sort / Block Puzzle.
	var effective_reward := safe_reward if id == "rescue_rush" else safe_reward + bonus
	var previous := int(SaveManager.data.get("coins", 0))
	var completed := super.complete_daily(id, effective_reward)
	if completed and id != "rescue_rush" and economy != null:
		economy.call("notify_external_change", previous, "daily_reward", {
			"game": id,
			"reward": effective_reward,
			"base_reward": safe_reward,
			"collection_bonus": bonus
		})
	return completed

func complete_level(id: String, n: int, stars: int, coin_reward := 25, context: Dictionary = {}) -> Dictionary:
	var safe_reward := maxi(0, int(coin_reward))
	var rewards := super.complete_level(id, n, stars, safe_reward, context)
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
