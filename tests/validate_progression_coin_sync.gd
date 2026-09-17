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
	var multi = root.get_node_or_null("MultiGameManager")
	var retention = root.get_node_or_null("RetentionManager")
	expect_true(save != null and economy != null and multi != null and retention != null, "Progression/economy autoloads missing")
	if save == null or economy == null or multi == null or retention == null:
		_finish()
		return

	var original_data: Dictionary = save.data.duplicate(true)
	var transactions: Array[Dictionary] = []
	var callback := func(transaction: Dictionary) -> void:
		transactions.append(transaction.duplicate(true))
	economy.transaction_recorded.connect(callback)

	# Start from deterministic multi-game state.
	save.data.coins = 0
	save.data.game_progress = {}
	save.data.daily_tasks = {}
	multi.ensure_state()
	save.save()

	var before_daily := int(save.data.coins)
	var daily_ok := bool(multi.complete_daily("water_sort", 100))
	expect_true(daily_ok and int(save.data.coins) == before_daily + 100, "Water Sort daily reward changed unexpectedly")
	expect_true(not transactions.is_empty() and String(transactions.back().get("reason", "")) == "daily_reward", "Multi-game daily reward did not notify shared economy")

	var level_number := 9877
	var before_level := int(save.data.coins)
	multi.complete_level("water_sort", level_number, 2, 25)
	expect_true(int(save.data.coins) == before_level + 25, "Water Sort first-clear base reward changed unexpectedly")
	expect_true(String(transactions.back().get("reason", "")) == "level_reward", "Multi-game level reward did not notify shared economy")

	# Force one daily task claim without depending on which seeded task appears.
	var tasks: Array = multi.daily_tasks("block_puzzle")
	expect_true(not tasks.is_empty(), "Daily task fixture missing")
	if not tasks.is_empty():
		var first: Dictionary = tasks[0]
		first["progress"] = int(first.get("target", 1))
		first["claimed"] = false
		tasks[0] = first
		var task_key := multi.date_key() + ":block_puzzle"
		var store: Dictionary = save.data.get("daily_tasks", {})
		store[task_key] = tasks
		save.data.daily_tasks = store
		save.save()
		var before_task := int(save.data.coins)
		var claimed := bool(multi.claim_daily_task("block_puzzle", String(first.get("id", ""))))
		expect_true(claimed and int(save.data.coins) == before_task + int(multi.TASK_REWARD), "Daily task coin reward changed unexpectedly")
		expect_true(String(transactions.back().get("reason", "")) == "daily_task_reward", "Daily task reward did not notify shared economy")

	# Robust retention settles an old week by writing its reward internally. The
	# economy wrapper must surface that direct mutation exactly once.
	retention.ensure_state()
	var current_week := String(retention.week_key())
	save.data.weekly_key = current_week + "_OLD"
	save.data.weekly_settlement_key = ""
	save.data.weekly_points = 0
	save.save()
	var before_weekly := int(save.data.coins)
	retention.ensure_state()
	expect_true(int(save.data.coins) > before_weekly, "Weekly settlement did not grant its existing coin reward")
	expect_true(String(transactions.back().get("reason", "")) == "retention_reward", "Weekly settlement did not notify shared economy")

	if economy.transaction_recorded.is_connected(callback):
		economy.transaction_recorded.disconnect(callback)
	save.data = original_data
	save.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("PROGRESSION_COIN_SYNC_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
