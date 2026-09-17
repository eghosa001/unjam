extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	var store = root.get_node_or_null("StoreManager")
	var save = root.get_node_or_null("SaveManager")
	expect_true(store != null and save != null, "StoreManager/SaveManager autoload missing")
	if store == null or save == null:
		_finish()
		return

	var old_test_mode := bool(ProjectSettings.get_setting("monetization/test_mode", false))
	var old_verify_url := String(ProjectSettings.get_setting("monetization/purchase_verification_url", ""))
	var original_purchased: Array = (save.data.get("purchased_products", []) as Array).duplicate(true)
	var original_tokens: Array = (save.data.get("processed_purchase_tokens", []) as Array).duplicate(true)
	var original_remove := bool(save.data.get("remove_ads", false))

	# Use a deliberately unreachable local HTTPS endpoint so verification is
	# asynchronous and then fails. The critical contract is that Restore must not
	# announce success before that verification settles.
	ProjectSettings.set_setting("monetization/test_mode", false)
	ProjectSettings.set_setting("monetization/purchase_verification_url", "https://127.0.0.1:1/verify")
	save.data.purchased_products = []
	save.data.processed_purchase_tokens = []
	save.data.remove_ads = false
	save.save()

	var restore_events: Array[int] = []
	var restore_callback := func(count: int) -> void:
		restore_events.append(count)
	store.restore_completed.connect(restore_callback)
	store.call("_on_restore_result", [{
		"purchase_state": store.PURCHASE_STATE_PURCHASED,
		"purchase_token": "qa-restore-unverified-token",
		"product_ids": [store.PRODUCT_REMOVE_ADS]
	}])

	expect_true(restore_events.is_empty(), "Restore completed before asynchronous purchase verification settled")

	# Connection refusal on localhost should settle quickly. Give the HTTPRequest
	# enough frames to report its failure without waiting for the 20-second timeout.
	for _i in range(180):
		if not restore_events.is_empty():
			break
		await process_frame
	expect_true(restore_events.size() == 1, "Restore batch did not emit exactly once after verification settled")
	if restore_events.size() == 1:
		expect_true(int(restore_events[0]) == 0, "Failed verification was incorrectly counted as a restored entitlement")
	expect_true(not bool(save.data.get("remove_ads", false)), "Failed restore verification granted Remove Ads")

	# Main's Shop must listen for the settled restore result so the UI cannot stay
	# permanently on 'Checking Google Play purchases…'.
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	for _i in range(4):
		await process_frame
	var hub := main.get_node_or_null("MonetizationHub")
	expect_true(hub != null, "MonetizationHub missing from Main")
	if hub != null:
		var connections: Array = store.restore_completed.get_connections()
		var connected := false
		for entry in connections:
			var callback: Callable = entry.get("callable", Callable())
			if callback.is_valid() and callback.get_object() == hub:
				connected = true
				break
		expect_true(connected, "Shop is not connected to StoreManager.restore_completed")
	main.queue_free()
	await process_frame

	if store.restore_completed.is_connected(restore_callback):
		store.restore_completed.disconnect(restore_callback)
	ProjectSettings.set_setting("monetization/test_mode", old_test_mode)
	ProjectSettings.set_setting("monetization/purchase_verification_url", old_verify_url)
	save.data.purchased_products = original_purchased
	save.data.processed_purchase_tokens = original_tokens
	save.data.remove_ads = original_remove
	save.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("RESTORE_PURCHASE_FLOW_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
