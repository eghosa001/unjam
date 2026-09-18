extends Node

signal balance_changed(new_balance: int, delta: int, reason: String)
signal transaction_recorded(transaction: Dictionary)


const COLLECTION_ITEM_IDS := ["tree", "bench", "fountain", "lanterns", "cottage", "rainbow_bridge"]
const COLLECTION_DAILY_BONUS_PER_ITEM := 5
const COLLECTION_GIFT_PER_ITEM := 10
const COLLECTION_FULL_SET_GIFT_BONUS := 20

func collection_owned_count() -> int:
	var decorations = SaveManager.data.get("decorations", [])
	if not decorations is Array:
		return 0
	var owned := 0
	for id in COLLECTION_ITEM_IDS:
		if id in decorations:
			owned += 1
	return owned

func collection_daily_bonus() -> int:
	# Every permanent garden upgrade makes each of the three Daily Games more
	# valuable. At full collection this is +30 coins per Daily Game.
	return collection_owned_count() * COLLECTION_DAILY_BONUS_PER_ITEM

func collection_daily_reward(base_reward: int) -> int:
	return maxi(0, base_reward) + collection_daily_bonus()

func garden_gift_amount() -> int:
	var owned := collection_owned_count()
	if owned <= 0:
		return 0
	var amount := owned * COLLECTION_GIFT_PER_ITEM
	if owned >= COLLECTION_ITEM_IDS.size():
		amount += COLLECTION_FULL_SET_GIFT_BONUS
	return amount

func garden_gift_claimed_today() -> bool:
	return String(SaveManager.data.get("garden_last_gift_date", "")) == _date_key()

func can_claim_garden_gift() -> bool:
	return garden_gift_amount() > 0 and not garden_gift_claimed_today()

func claim_garden_gift() -> int:
	if not can_claim_garden_gift():
		return 0
	var amount := garden_gift_amount()
	SaveManager.data["garden_last_gift_date"] = _date_key()
	SaveManager.data["garden_gifts_claimed"] = int(SaveManager.data.get("garden_gifts_claimed", 0)) + 1
	SaveManager.save()
	grant(amount, "collection_daily_gift", {
		"owned": collection_owned_count(),
		"full_set": collection_owned_count() >= COLLECTION_ITEM_IDS.size()
	})
	return amount

func unlock_collection_item(id: String, cost: int) -> bool:
	if id not in COLLECTION_ITEM_IDS or cost <= 0:
		return false
	var decorations = SaveManager.data.get("decorations", [])
	if not decorations is Array:
		decorations = []
	if id in decorations:
		return true
	if not spend(cost, "collection_purchase", {"item": id}):
		return false
	decorations.append(id)
	SaveManager.data["decorations"] = decorations
	SaveManager.save()
	AnalyticsManager.track("collection_item_unlocked", {
		"item": id,
		"cost": cost,
		"owned": collection_owned_count(),
		"daily_bonus": collection_daily_bonus(),
		"gift": garden_gift_amount()
	})
	return true

func _date_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func balance() -> int:
	return maxi(0, int(SaveManager.data.get("coins", 0)))

func can_afford(amount: int) -> bool:
	return amount > 0 and balance() >= amount

func spend(amount: int, reason: String, metadata: Dictionary = {}) -> bool:
	if amount <= 0 or reason.strip_edges().is_empty():
		return false
	var spent := false
	if SaveManager.has_method("economy_spend_coins"):
		spent = bool(SaveManager.call("economy_spend_coins", amount))
	else:
		spent = bool(SaveManager.spend_coins(amount))
	if not spent:
		return false
	_emit_transaction(-amount, reason, metadata)
	return true

func grant(amount: int, reason: String, metadata: Dictionary = {}) -> int:
	if amount <= 0 or reason.strip_edges().is_empty():
		return balance()
	if SaveManager.has_method("economy_add_coins"):
		SaveManager.call("economy_add_coins", amount)
	else:
		SaveManager.add_coins(amount)
	_emit_transaction(amount, reason, metadata)
	return balance()

func notify_external_change(previous_balance: int, reason: String, metadata: Dictionary = {}) -> int:
	var current := balance()
	var delta := current - previous_balance
	if delta != 0 and not reason.strip_edges().is_empty():
		_emit_transaction(delta, reason, metadata)
	return current

func record_external_delta(delta: int, reason: String, metadata: Dictionary = {}) -> int:
	if delta != 0 and not reason.strip_edges().is_empty():
		_emit_transaction(delta, reason, metadata)
	return balance()

func _emit_transaction(delta: int, reason: String, metadata: Dictionary) -> void:
	var current := balance()
	var transaction := {
		"balance": current,
		"delta": delta,
		"reason": reason,
		"metadata": metadata.duplicate(true),
		"unix": int(Time.get_unix_time_from_system())
	}
	balance_changed.emit(current, delta, reason)
	transaction_recorded.emit(transaction)
	if get_node_or_null("/root/AnalyticsManager") != null:
		AnalyticsManager.track("coin_transaction", {
			"delta": delta,
			"balance": current,
			"reason": reason
		})
