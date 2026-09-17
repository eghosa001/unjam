extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	var save_manager = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	expect_true(save_manager != null, "SaveManager autoload missing")
	expect_true(economy != null, "EconomyManager autoload missing")
	if save_manager == null or economy == null:
		_finish()
		return

	var original_coins := int(save_manager.data.get("coins", 0))
	var events: Array = []
	var callback := func(new_balance: int, delta: int, reason: String) -> void:
		events.append({"balance": new_balance, "delta": delta, "reason": reason})
	economy.balance_changed.connect(callback)

	save_manager.data.coins = 100
	save_manager.save()
	expect_true(int(economy.balance()) == 100, "Economy balance did not read canonical SaveManager wallet")
	expect_true(bool(economy.can_afford(100)), "Economy can_afford rejected exact balance")
	expect_true(bool(economy.spend(25, "hint_rescue_rush")), "Valid 25-coin spend failed")
	expect_true(int(economy.balance()) == 75, "Spend did not leave expected balance")
	expect_true(not bool(economy.spend(100, "qa_overdraft")), "Economy allowed overdraft")
	expect_true(int(economy.balance()) == 75, "Failed spend changed balance")
	expect_true(int(economy.grant(50, "rewarded_ad")) == 125, "50-coin grant returned wrong balance")
	expect_true(int(economy.balance()) == 125, "Grant did not persist wallet")
	expect_true(not bool(economy.spend(0, "qa_zero")), "Zero-value spend should be rejected")
	expect_true(int(economy.grant(0, "qa_zero")) == 125, "Zero-value grant should be a no-op")
	expect_true(events.size() == 2, "Wallet emitted an unexpected number of successful transaction events")
	if events.size() >= 2:
		expect_true(String(events[0].reason) == "hint_rescue_rush" and int(events[0].delta) == -25, "Spend reason/delta event incorrect")
		expect_true(String(events[1].reason) == "rewarded_ad" and int(events[1].delta) == 50, "Grant reason/delta event incorrect")

	if economy.balance_changed.is_connected(callback):
		economy.balance_changed.disconnect(callback)
	save_manager.data.coins = original_coins
	save_manager.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("COIN_ECONOMY_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
