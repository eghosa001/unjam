extends Node

signal catalog_changed
signal purchase_started(product_id: String)
signal purchase_succeeded(product_id: String)
signal purchase_failed(product_id: String, reason: String)

const PRODUCT_REMOVE_ADS := "unjam_remove_ads"
const PRODUCT_STARTER_PACK := "unjam_starter_pack"
const PRODUCT_COINS_SMALL := "unjam_coins_500"
const PRODUCT_COINS_MEDIUM := "unjam_coins_1500"
const PRODUCT_COINS_LARGE := "unjam_coins_4000"

const PRODUCTS := {
	PRODUCT_REMOVE_ADS: {"title": "REMOVE ADS", "subtitle": "No interstitial ads", "coins": 0, "non_consumable": true},
	PRODUCT_STARTER_PACK: {"title": "STARTER PACK", "subtitle": "1,000 coins + Remove Ads", "coins": 1000, "non_consumable": true},
	PRODUCT_COINS_SMALL: {"title": "500 COINS", "subtitle": "Small coin pack", "coins": 500, "non_consumable": false},
	PRODUCT_COINS_MEDIUM: {"title": "1,500 COINS", "subtitle": "Best for regular play", "coins": 1500, "non_consumable": false},
	PRODUCT_COINS_LARGE: {"title": "4,000 COINS", "subtitle": "Largest coin pack", "coins": 4000, "non_consumable": false}
}

var provider: Node
var localized_prices: Dictionary = {}

func register_provider(value: Node) -> void:
	provider = value
	if provider != null and provider.has_method("query_products"):
		provider.call("query_products", PRODUCTS.keys(), Callable(self, "set_localized_prices"))
	catalog_changed.emit()

func provider_ready() -> bool:
	return provider != null and is_instance_valid(provider)

func set_localized_prices(prices: Dictionary) -> void:
	localized_prices = prices.duplicate(true)
	catalog_changed.emit()

func price_text(product_id: String) -> String:
	if localized_prices.has(product_id):
		return String(localized_prices[product_id])
	return "PLAY STORE" if OS.get_name() == "Android" else "TEST PURCHASE"

func purchase(product_id: String) -> bool:
	if not PRODUCTS.has(product_id):
		purchase_failed.emit(product_id, "Unknown product")
		return false
	purchase_started.emit(product_id)
	AnalyticsManager.track("purchase_started", {"product": product_id})
	if provider_ready() and provider.has_method("purchase"):
		var accepted = provider.call("purchase", product_id, Callable(self, "confirm_purchase"), Callable(self, "_provider_purchase_failed"))
		return accepted != false
	if bool(ProjectSettings.get_setting("monetization/test_mode", true)) and OS.get_name() != "Android":
		confirm_purchase(product_id, "desktop-test")
		return true
	purchase_failed.emit(product_id, "Google Play Billing provider unavailable")
	return false

func _provider_purchase_failed(product_id: String, reason: String = "Purchase failed") -> void:
	purchase_failed.emit(product_id, reason)
	AnalyticsManager.track("purchase_failed", {"product": product_id, "reason": reason})

func confirm_purchase(product_id: String, purchase_token: String = "") -> void:
	# This is the only grant path. Android providers must call it after Play Billing reports success.
	if not PRODUCTS.has(product_id):
		return
	var purchased: Array = SaveManager.data.get("purchased_products", [])
	var non_consumable := bool(PRODUCTS[product_id].get("non_consumable", false))
	if non_consumable and product_id in purchased:
		purchase_succeeded.emit(product_id)
		return
	var coins := int(PRODUCTS[product_id].get("coins", 0))
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
	SaveManager.data.purchased_products = purchased
	SaveManager.save()
	purchase_succeeded.emit(product_id)
	AnalyticsManager.track("purchase_succeeded", {"product": product_id, "coins": coins, "token_present": not purchase_token.is_empty()})
