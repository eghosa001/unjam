extends "res://scripts/core/robust_save_manager.gd"

# Economy-aware persistence boundary. RobustSaveManager remains the authority
# for save integrity/progression; this wrapper only makes legacy coin mutations
# visible to the shared EconomyManager signal/transaction stream.

func _notify_economy(previous_balance: int, reason: String, metadata: Dictionary = {}) -> void:
	var economy := get_node_or_null("/root/EconomyManager")
	if economy != null and economy.has_method("notify_external_change"):
		economy.call("notify_external_change", previous_balance, reason, metadata)

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	var previous := int(data.get("coins", 0))
	super.add_coins(amount)
	_notify_economy(previous, "external_reward", {"source": "save_manager"})

func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return false
	var previous := int(data.get("coins", 0))
	var spent := super.spend_coins(amount)
	if spent:
		_notify_economy(previous, "external_spend", {"source": "save_manager"})
	return spent

# EconomyManager owns semantic reasons for its own transactions, so these two
# methods persist without generating a second generic external transaction.
func economy_add_coins(amount: int) -> void:
	if amount <= 0:
		return
	super.add_coins(amount)

func economy_spend_coins(amount: int) -> bool:
	if amount <= 0:
		return false
	return super.spend_coins(amount)

func complete_daily(date_key: String, reward: int = 100) -> bool:
	var safe_reward := maxi(0, reward)
	var previous := int(data.get("coins", 0))
	var completed := super.complete_daily(date_key, safe_reward)
	if completed:
		_notify_economy(previous, "daily_reward", {"date": date_key, "reward": safe_reward})
	return completed

func complete_level(level_number: int, stars: int, rescue_id: String, coin_reward: int = 25) -> Dictionary:
	var safe_reward := maxi(0, coin_reward)
	var previous := int(data.get("coins", 0))
	var rewards := super.complete_level(level_number, stars, rescue_id, safe_reward)
	_notify_economy(previous, "level_reward", {
		"level": level_number,
		"stars": stars,
		"base_reward": int(rewards.get("base_coins", 0)),
		"bonus_reward": int(rewards.get("bonus_coins", 0))
	})
	return rewards
