extends Node

signal balance_changed(new_balance: int, delta: int, reason: String)
signal transaction_recorded(transaction: Dictionary)

func balance() -> int:
	return maxi(0, int(SaveManager.data.get("coins", 0)))

func can_afford(amount: int) -> bool:
	return amount > 0 and balance() >= amount

func spend(amount: int, reason: String, metadata: Dictionary = {}) -> bool:
	if amount <= 0 or reason.strip_edges().is_empty():
		return false
	if not SaveManager.spend_coins(amount):
		return false
	_emit_transaction(-amount, reason, metadata)
	return true

func grant(amount: int, reason: String, metadata: Dictionary = {}) -> int:
	if amount <= 0 or reason.strip_edges().is_empty():
		return balance()
	SaveManager.add_coins(amount)
	_emit_transaction(amount, reason, metadata)
	return balance()

func notify_external_change(previous_balance: int, reason: String, metadata: Dictionary = {}) -> int:
	var current := balance()
	var delta := current - previous_balance
	if delta != 0 and not reason.strip_edges().is_empty():
		_emit_transaction(delta, reason, metadata)
	return current

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
