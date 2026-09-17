extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	var save = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	expect_true(save != null and economy != null, "Save/Economy autoloads missing")
	if save == null or economy == null:
		_finish()
		return

	var original_data: Dictionary = save.data.duplicate(true)
	var transactions: Array[Dictionary] = []
	var callback := func(transaction: Dictionary) -> void:
		transactions.append(transaction.duplicate(true))
	economy.transaction_recorded.connect(callback)

	save.data.coins = 100
	save.save()
	save.add_coins(40)
	expect_true(int(save.data.coins) == 140, "Direct SaveManager coin grant failed")
	expect_true(not transactions.is_empty() and String(transactions.back().get("reason", "")) == "external_reward", "Direct SaveManager grant did not notify EconomyManager")

	var spent := bool(save.spend_coins(15))
	expect_true(spent and int(save.data.coins) == 125, "Direct SaveManager spend failed")
	expect_true(String(transactions.back().get("reason", "")) == "external_spend", "Direct SaveManager spend did not notify EconomyManager")

	# Daily completion mutates the persistent reward state internally; it must
	# still surface exactly one semantic wallet transaction to live UI listeners.
	save.data.daily_completed = []
	var before_daily := int(save.data.coins)
	var daily_ok := bool(save.complete_daily("2099-12-31", 100))
	expect_true(daily_ok and int(save.data.coins) == before_daily + 100, "Daily reward amount changed unexpectedly")
	expect_true(String(transactions.back().get("reason", "")) == "daily_reward", "Daily reward did not emit semantic EconomyManager transaction")

	# Use a level far from milestone boundaries so only its configured base reward
	# is under test. Restore the full save snapshot when the contract finishes.
	var level_number := 9877
	save.data.stars.erase(str(level_number))
	var before_level := int(save.data.coins)
	save.complete_level(level_number, 2, "", 25)
	expect_true(int(save.data.coins) == before_level + 25, "Base level coin reward changed unexpectedly")
	expect_true(String(transactions.back().get("reason", "")) == "level_reward", "Level reward did not emit semantic EconomyManager transaction")

	if economy.transaction_recorded.is_connected(callback):
		economy.transaction_recorded.disconnect(callback)
	save.data = original_data
	save.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("EXTERNAL_COIN_SYNC_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
