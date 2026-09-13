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
	var ad_manager = root.get_node_or_null("AdManager")
	var store_manager = root.get_node_or_null("StoreManager")
	expect_true(save_manager != null, "SaveManager autoload missing")
	expect_true(ad_manager != null, "AdManager autoload missing")
	expect_true(store_manager != null, "StoreManager autoload missing")
	if save_manager == null or ad_manager == null or store_manager == null:
		quit(1)
		return
	expect_true(store_manager.PRODUCTS.has(store_manager.PRODUCT_REMOVE_ADS), "remove ads product missing")
	expect_true(store_manager.PRODUCTS.has(store_manager.PRODUCT_STARTER_PACK), "starter pack missing")
	expect_true(store_manager.PRODUCTS.size() >= 5, "coin catalog incomplete")
	var before := int(save_manager.data.get("coins", 0))
	var old_remove := bool(save_manager.data.get("remove_ads", false))
	store_manager.confirm_purchase(store_manager.PRODUCT_COINS_SMALL, "desktop-test")
	await process_frame
	expect_true(int(save_manager.data.get("coins", 0)) == before + 500, "coin purchase grant incorrect")
	store_manager.confirm_purchase(store_manager.PRODUCT_REMOVE_ADS, "desktop-test")
	await process_frame
	expect_true(bool(save_manager.data.get("remove_ads", false)), "remove ads not persisted")
	expect_true(not ad_manager.ads_enabled, "ads should be disabled after remove ads")
	save_manager.data.coins = before
	save_manager.data.remove_ads = old_remove
	save_manager.data.purchased_products = []
	save_manager.data.processed_purchase_tokens = []
	ad_manager.ads_enabled = not old_remove
	save_manager.save()
	if failures.is_empty():
		print("MONETIZATION VALIDATION PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
