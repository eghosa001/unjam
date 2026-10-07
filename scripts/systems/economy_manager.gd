extends Node

signal balance_changed(new_balance: int, delta: int, reason: String)
signal transaction_recorded(transaction: Dictionary)

const COLLECTION_ITEM_IDS := ["tree", "bench", "fountain", "lanterns", "cottage", "rainbow_bridge"]
const COLLECTION_MAX_LEVEL := 5
const COLLECTION_LEVEL_COST_MULTIPLIERS := [1.0, 1.6, 2.4, 3.4, 4.6]
const COLLECTION_FULL_SET_GIFT_BONUS := 25

func collection_item_level(id: String) -> int:
	if id not in COLLECTION_ITEM_IDS:
		return 0
	var levels = SaveManager.data.get("collection_levels", {})
	if levels is Dictionary and levels.has(id):
		return clampi(int(levels[id]), 0, COLLECTION_MAX_LEVEL)
	var decorations = SaveManager.data.get("decorations", [])
	return 1 if decorations is Array and id in decorations else 0

func collection_owned_count() -> int:
	var owned := 0
	for id in COLLECTION_ITEM_IDS:
		if collection_item_level(id) > 0:
			owned += 1
	return owned

func collection_total_levels() -> int:
	var total := 0
	for id in COLLECTION_ITEM_IDS:
		total += collection_item_level(id)
	return total

func collection_max_total_levels() -> int:
	return COLLECTION_ITEM_IDS.size() * COLLECTION_MAX_LEVEL

func collection_daily_bonus() -> int:
	return collection_total_levels() + collection_item_level("tree") * 4

func collection_campaign_reward_bonus_pct() -> int:
	return collection_item_level("fountain") * 3 + collection_item_level("rainbow_bridge")

func collection_campaign_reward(amount: int) -> int:
	if amount <= 0:
		return 0
	return maxi(amount, int(round(float(amount) * (1.0 + float(collection_campaign_reward_bonus_pct()) / 100.0))))

func hint_cost(base_cost: int) -> int:
	var discount := collection_item_level("bench") * 6
	return maxi(5, int(round(float(base_cost) * (1.0 - float(discount) / 100.0))))

func competition_prestige_title() -> String:
	var crowns := maxi(0, int(SaveManager.data.get("crown_tokens", 0)))
	if crowns >= 300: return "UNJAM LEGEND"
	if crowns >= 150: return "DIAMOND CHAMPION"
	if crowns >= 75: return "GOLD CONTENDER"
	if crowns >= 30: return "SILVER CONTENDER"
	if crowns >= 10: return "BRONZE CONTENDER"
	return "ROOKIE"

func competition_crown_reward(base_crowns: int) -> int:
	if base_crowns <= 0:
		return 0
	var bonus_pct := collection_item_level("rainbow_bridge") * 5
	return base_crowns + int(floor(float(base_crowns) * float(bonus_pct) / 100.0))

func garden_gift_amount() -> int:
	var total := collection_total_levels()
	if total <= 0:
		return 0
	var amount := total * 5
	amount += collection_item_level("cottage") * 10
	amount += collection_item_level("rainbow_bridge") * 5
	if collection_owned_count() >= COLLECTION_ITEM_IDS.size():
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
		"levels": collection_total_levels(),
		"full_set": collection_owned_count() >= COLLECTION_ITEM_IDS.size()
	})
	return amount

func collection_level_cost(id: String, base_cost: int) -> int:
	if id not in COLLECTION_ITEM_IDS or base_cost <= 0:
		return 0
	var level := collection_item_level(id)
	if level >= COLLECTION_MAX_LEVEL:
		return 0
	return maxi(1, int(round(float(base_cost) * float(COLLECTION_LEVEL_COST_MULTIPLIERS[level]))))

func collection_effect_text(id: String, level: int = -1) -> String:
	var safe_level := collection_item_level(id) if level < 0 else clampi(level, 0, COLLECTION_MAX_LEVEL)
	match id:
		"tree": return "Daily reward +%d" % (safe_level * 4)
		"bench": return "Hint cost -%d%%" % (safe_level * 6)
		"fountain": return "Campaign coins +%d%%" % (safe_level * 3)
		"lanterns":
			var shields := 1 if safe_level <= 2 else (2 if safe_level <= 4 else 3)
			return "Streak shields %d/month" % shields if safe_level > 0 else "Protect Daily streaks"
		"cottage": return "Garden gift +%d" % (safe_level * 10)
		"rainbow_bridge": return "Crown rewards +%d%%" % (safe_level * 5)
		_: return "Permanent upgrade"

func upgrade_collection_item(id: String, base_cost: int) -> bool:
	if id not in COLLECTION_ITEM_IDS:
		return false
	var current := collection_item_level(id)
	if current >= COLLECTION_MAX_LEVEL:
		return true
	var cost := collection_level_cost(id, base_cost)
	if cost <= 0 or not spend(cost, "collection_upgrade", {"item": id, "from_level": current, "to_level": current + 1}):
		return false
	var levels = SaveManager.data.get("collection_levels", {})
	if not levels is Dictionary:
		levels = {}
	levels[id] = current + 1
	SaveManager.data["collection_levels"] = levels
	var decorations = SaveManager.data.get("decorations", [])
	if not decorations is Array:
		decorations = []
	if id not in decorations:
		decorations.append(id)
	SaveManager.data["decorations"] = decorations
	SaveManager.save()
	AnalyticsManager.track("collection_item_upgraded", {
		"item": id, "level": current + 1, "cost": cost,
		"total_levels": collection_total_levels(),
		"daily_bonus": collection_daily_bonus(), "gift": garden_gift_amount()
	})
	return true

func unlock_collection_item(id: String, cost: int) -> bool:
	if collection_item_level(id) > 0:
		return true
	return upgrade_collection_item(id, cost)

func maybe_restore_daily_streak(previous_date: String, new_date: String, previous_streak: int) -> bool:
	var level := collection_item_level("lanterns")
	if level <= 0 or previous_date.is_empty() or new_date.is_empty():
		return false
	var previous_unix := _date_unix(previous_date)
	var new_unix := _date_unix(new_date)
	if previous_unix <= 0 or new_unix <= 0 or int(new_unix - previous_unix) != 172800:
		return false
	var month_key := new_date.left(7)
	var used := int(SaveManager.data.get("lantern_shield_uses", 0))
	if String(SaveManager.data.get("lantern_shield_month", "")) != month_key:
		used = 0
	var max_uses := 1 if level <= 2 else (2 if level <= 4 else 3)
	if used >= max_uses:
		return false
	SaveManager.data["daily_streak"] = previous_streak + 1
	SaveManager.data["daily_best_streak"] = maxi(int(SaveManager.data.get("daily_best_streak", 0)), previous_streak + 1)
	SaveManager.data["lantern_shield_month"] = month_key
	SaveManager.data["lantern_shield_uses"] = used + 1
	SaveManager.save()
	AnalyticsManager.track("collection_streak_shield_used", {"level": level, "month": month_key, "uses": used + 1})
	return true

func _date_unix(date_key: String) -> int:
	var parts := date_key.split("-")
	if parts.size() != 3:
		return 0
	return int(Time.get_unix_time_from_datetime_dict({
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 0, "minute": 0, "second": 0
	}))

func reward_double_claimed(claim_id: String) -> bool:
	var claims = SaveManager.data.get("reward_double_claims", [])
	return claims is Array and claim_id in claims

func claim_reward_double(claim_id: String, amount: int) -> bool:
	if claim_id.is_empty() or amount <= 0 or reward_double_claimed(claim_id):
		return false
	var claims = SaveManager.data.get("reward_double_claims", [])
	if not claims is Array:
		claims = []
	claims.append(claim_id)
	if claims.size() > 512:
		claims = claims.slice(claims.size() - 512)
	SaveManager.data["reward_double_claims"] = claims
	SaveManager.save()
	grant(amount, "reward_double", {"claim_id": claim_id})
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
	var remaining := amount
	var debt := maxi(0, int(SaveManager.data.get("purchase_coin_debt", 0)))
	if debt > 0:
		var settled := mini(remaining, debt)
		remaining -= settled
		debt -= settled
		SaveManager.data.purchase_coin_debt = debt
		SaveManager.save()
		AnalyticsManager.track("purchase_refund_debt_settled", {
			"settled": settled,
			"remaining_debt": debt,
			"source_reason": reason
		})
	if remaining <= 0:
		return balance()
	if SaveManager.has_method("economy_add_coins"):
		SaveManager.call("economy_add_coins", remaining)
	else:
		SaveManager.add_coins(remaining)
	_emit_transaction(remaining, reason, metadata)
	return balance()

func revoke_purchase_credit(amount: int, metadata: Dictionary = {}) -> int:
	if amount <= 0:
		return balance()
	var current := balance()
	var removed := mini(current, amount)
	if removed > 0:
		var spent := false
		if SaveManager.has_method("economy_spend_coins"):
			spent = bool(SaveManager.call("economy_spend_coins", removed))
		else:
			spent = bool(SaveManager.spend_coins(removed))
		if spent:
			_emit_transaction(-removed, "purchase_refund", metadata)
		else:
			removed = 0
	var debt_add := amount - removed
	if debt_add > 0:
		SaveManager.data.purchase_coin_debt = maxi(0, int(SaveManager.data.get("purchase_coin_debt", 0))) + debt_add
		SaveManager.save()
	AnalyticsManager.track("purchase_refund_clawback", {
		"requested": amount,
		"removed": removed,
		"debt_added": debt_add,
		"remaining_debt": int(SaveManager.data.get("purchase_coin_debt", 0))
	})
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
