extends Node

signal catalog_changed
signal purchase_started(product_id: String)
signal purchase_pending(product_id: String, reason: String)
signal purchase_succeeded(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restore_completed(count: int)

const PRODUCT_REMOVE_ADS := "unjam_remove_ads"
const PRODUCT_STARTER_PACK := "unjam_starter_pack"
const PRODUCT_COINS_SMALL := "unjam_coins_500"
const PRODUCT_COINS_MEDIUM := "unjam_coins_1500"
const PRODUCT_COINS_LARGE := "unjam_coins_4000"
const PRODUCTS := {
	PRODUCT_REMOVE_ADS: {"title":"REMOVE ADS","subtitle":"No interstitial ads","coins":0,"non_consumable":true},
	PRODUCT_STARTER_PACK: {"title":"STARTER PACK","subtitle":"1,000 coins + Remove Ads","coins":1000,"non_consumable":true},
	PRODUCT_COINS_SMALL: {"title":"500 COINS","subtitle":"Small coin pack","coins":500,"non_consumable":false},
	PRODUCT_COINS_MEDIUM: {"title":"1,500 COINS","subtitle":"Best for regular play","coins":1500,"non_consumable":false},
	PRODUCT_COINS_LARGE: {"title":"4,000 COINS","subtitle":"Largest coin pack","coins":4000,"non_consumable":false}
}

var provider: Node
var localized_prices: Dictionary = {}
var purchase_in_progress := false
var active_purchase_product := ""
var pending_products: Dictionary = {}

func register_provider(value: Node) -> void:
	provider = value
	if provider != null and provider.has_method("query_products"):
		provider.call("query_products", PRODUCTS.keys(), Callable(self, "set_localized_prices"))
	catalog_changed.emit()

func provider_ready() -> bool:
	return provider != null and is_instance_valid(provider)

func verifier_ready() -> bool:
	var endpoint := String(ProjectSettings.get_setting("monetization/purchase_verification_url", ""))
	return endpoint.begins_with("https://")

func _token_fingerprint(token: String) -> String:
	return token.sha256_text() if not token.is_empty() else ""

func set_localized_prices(prices: Dictionary) -> void:
	localized_prices = prices.duplicate(true)
	catalog_changed.emit()

func price_text(product_id: String) -> String:
	if localized_prices.has(product_id):
		return String(localized_prices[product_id])
	if provider_ready() and verifier_ready():
		return "PLAY STORE"
	if bool(ProjectSettings.get_setting("monetization/test_mode", false)) and OS.get_name() != "Android":
		return "TEST PURCHASE"
	return "UNAVAILABLE"

func is_purchase_pending(product_id: String) -> bool:
	return bool(pending_products.get(product_id, false))

func purchase(product_id: String) -> bool:
	if purchase_in_progress:
		purchase_failed.emit(product_id, "Another purchase is already in progress")
		return false
	if not PRODUCTS.has(product_id):
		purchase_failed.emit(product_id, "Unknown product")
		return false
	if OS.get_name() == "Android" and not verifier_ready():
		purchase_failed.emit(product_id, "Secure purchase verification is not configured")
		return false

	_set_purchase_busy(product_id)
	purchase_started.emit(product_id)
	AnalyticsManager.track("purchase_started", {"product": product_id})
	if provider_ready() and provider.has_method("purchase"):
		var accepted = provider.call(
			"purchase",
			product_id,
			Callable(self, "confirm_purchase"),
			Callable(self, "_provider_purchase_failed"),
			Callable(self, "_provider_purchase_pending")
		)
		if accepted == false:
			_clear_purchase_busy(product_id)
		return accepted != false
	if bool(ProjectSettings.get_setting("monetization/test_mode", false)) and OS.get_name() != "Android":
		PurchaseVerifier.verify(product_id, "desktop-test", func(valid: bool, reason: String): _on_verified(product_id, "desktop-test", valid, reason))
		return true
	_clear_purchase_busy(product_id)
	purchase_failed.emit(product_id, "Google Play Billing provider unavailable")
	return false

func confirm_purchase(product_id: String, purchase_token: String = "") -> void:
	if not PRODUCTS.has(product_id):
		_clear_purchase_busy(product_id)
		pending_products.erase(product_id)
		return
	pending_products.erase(product_id)
	PurchaseVerifier.verify(product_id, purchase_token, func(valid: bool, reason: String): _on_verified(product_id, purchase_token, valid, reason))

func _on_verified(product_id: String, token: String, valid: bool, reason: String) -> void:
	pending_products.erase(product_id)
	if not valid:
		_clear_purchase_busy(product_id)
		purchase_failed.emit(product_id, reason)
		AnalyticsManager.track("purchase_verification_failed", {"product": product_id})
		return

	var processed: Array = SaveManager.data.get("processed_purchase_tokens", [])
	var fingerprint := _token_fingerprint(token)
	if not token.is_empty() and token != "desktop-test" and (fingerprint in processed or token in processed):
		_clear_purchase_busy(product_id)
		purchase_succeeded.emit(product_id)
		return

	var info: Dictionary = PRODUCTS[product_id]
	var coins := int(info.get("coins", 0))
	var non_consumable := bool(info.get("non_consumable", false))
	var purchased: Array = SaveManager.data.get("purchased_products", [])
	if non_consumable and product_id in purchased:
		_clear_purchase_busy(product_id)
		purchase_succeeded.emit(product_id)
		return

	if product_id == PRODUCT_REMOVE_ADS:
		AdManager.set_remove_ads_purchased(true)
	elif product_id == PRODUCT_STARTER_PACK:
		AdManager.set_remove_ads_purchased(true)
		SaveManager.data.starter_pack_purchased = true
		SaveManager.add_coins(coins)
	elif coins > 0:
		SaveManager.add_coins(coins)
		SaveManager.data.lifetime_purchased_coins = int(SaveManager.data.get("lifetime_purchased_coins", 0)) + coins

	if non_consumable and product_id not in purchased:
		purchased.append(product_id)
	if not token.is_empty() and token != "desktop-test" and fingerprint not in processed:
		processed.append(fingerprint)
	if token in processed:
		processed.erase(token)
	SaveManager.data.purchased_products = purchased
	SaveManager.data.processed_purchase_tokens = processed
	SaveManager.save()
	if provider_ready() and provider.has_method("finalize_purchase"):
		provider.call("finalize_purchase", token, not non_consumable)
	_clear_purchase_busy(product_id)
	purchase_succeeded.emit(product_id)
	AnalyticsManager.track("purchase_succeeded", {"product": product_id, "coins": coins})

func restore_purchases() -> bool:
	if not provider_ready() or not provider.has_method("restore_purchases"):
		return false
	return provider.call("restore_purchases", Callable(self, "_on_restore_result")) != false

func _purchase_product_ids(purchase: Dictionary) -> Array:
	var product_ids = purchase.get("product_ids", [])
	if product_ids is Array and not product_ids.is_empty():
		return product_ids
	# Compatibility with any older provider adapter that exposed `products`.
	var legacy_products = purchase.get("products", [])
	return legacy_products if legacy_products is Array else []

func _on_restore_result(purchases: Array) -> void:
	var restored := 0
	for purchase_value in purchases:
		if not purchase_value is Dictionary:
			continue
		var purchase: Dictionary = purchase_value
		var token := String(purchase.get("purchase_token", ""))
		for product_id in _purchase_product_ids(purchase):
			if PRODUCTS.has(product_id) and bool(PRODUCTS[product_id].get("non_consumable", false)):
				confirm_purchase(String(product_id), token)
				restored += 1
	restore_completed.emit(restored)

func _provider_purchase_pending(product_id: String, reason: String = "Purchase is pending in Google Play") -> void:
	pending_products[product_id] = true
	_clear_purchase_busy(product_id)
	purchase_pending.emit(product_id, reason)
	AnalyticsManager.track("purchase_pending", {"product": product_id})

func _provider_purchase_failed(product_id: String, reason: String = "Purchase failed") -> void:
	pending_products.erase(product_id)
	_clear_purchase_busy(product_id)
	purchase_failed.emit(product_id, reason)
	AnalyticsManager.track("purchase_failed", {"product": product_id, "reason": reason})

func _set_purchase_busy(product_id: String) -> void:
	active_purchase_product = product_id
	purchase_in_progress = true

func _clear_purchase_busy(product_id: String) -> void:
	# A pending purchase can become PURCHASED while another product is being
	# launched. Never let that background completion unlock the newer launch.
	if active_purchase_product == product_id:
		active_purchase_product = ""
		purchase_in_progress = false
