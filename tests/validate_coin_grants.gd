extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	ProjectSettings.set_setting("monetization/test_mode", true)
	var save_manager = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	var ads = root.get_node_or_null("AdManager")
	var store = root.get_node_or_null("StoreManager")
	expect_true(save_manager != null and economy != null and ads != null and store != null, "Monetization autoloads missing")
	if save_manager == null or economy == null or ads == null or store == null:
		_finish()
		return

	var original := save_manager.data.duplicate(true)
	var reasons: Array[String] = []
	var callback := func(transaction: Dictionary) -> void:
		reasons.append(String(transaction.get("reason", "")))
	economy.transaction_recorded.connect(callback)

	# Rewarded Shop coins use the shared wallet once.
	save_manager.data.coins = 0
	var reward_callbacks := {"count": 0}
	var reward_ok := bool(ads.reward_coins("shop_coins", 50, func() -> void: reward_callbacks.count += 1))
	expect_true(reward_ok, "Desktop rewarded coin request was rejected")
	expect_true(int(save_manager.data.get("coins", -1)) == 50, "Rewarded Shop ad did not grant exactly 50 coins")
	expect_true(int(reward_callbacks.count) == 1, "Rewarded coin completion callback did not run exactly once")
	expect_true("rewarded_ad" in reasons, "Rewarded coins bypassed EconomyManager reason tracking")

	# Verified consumable purchase grants through shared wallet exactly once per token.
	save_manager.data.coins = 0
	save_manager.data.processed_purchase_tokens = []
	store.call("_on_verified", store.PRODUCT_COINS_SMALL, "qa-token-small", true, "qa")
	expect_true(int(save_manager.data.get("coins", -1)) == 500, "500-coin pack grant incorrect")
	store.call("_on_verified", store.PRODUCT_COINS_SMALL, "qa-token-small", true, "qa-repeat")
	expect_true(int(save_manager.data.get("coins", -1)) == 500, "Processed purchase token granted coins twice")

	# Starter pack remains one-time Remove Ads + 1,000 coins.
	save_manager.data.coins = 0
	save_manager.data.remove_ads = false
	save_manager.data.starter_pack_purchased = false
	save_manager.data.purchased_products = []
	save_manager.data.processed_purchase_tokens = []
	ads.ads_enabled = true
	store.call("_on_verified", store.PRODUCT_STARTER_PACK, "qa-token-starter", true, "qa")
	expect_true(int(save_manager.data.get("coins", -1)) == 1000, "Starter Pack did not grant 1,000 coins")
	expect_true(bool(save_manager.data.get("remove_ads", false)), "Starter Pack did not unlock Remove Ads")
	expect_true(not ads.ads_enabled, "Starter Pack did not disable interstitial ads")
	store.call("_on_verified", store.PRODUCT_STARTER_PACK, "qa-token-starter", true, "qa-repeat")
	expect_true(int(save_manager.data.get("coins", -1)) == 1000, "Starter Pack granted twice for same token")
	expect_true("purchase" in reasons, "Verified coin purchase bypassed EconomyManager reason tracking")

	if economy.transaction_recorded.is_connected(callback):
		economy.transaction_recorded.disconnect(callback)
	save_manager.data = original
	save_manager.save()
	ads.ads_enabled = not bool(save_manager.data.get("remove_ads", false))
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("COIN_GRANTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
