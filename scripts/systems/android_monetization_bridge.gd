extends Node

var billing_client: Node

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	if OS.get_name() == "Android" and ResourceLoader.exists("res://addons/GodotGooglePlayBilling/BillingClient.gd"):
		var billing_script = load("res://addons/GodotGooglePlayBilling/BillingClient.gd")
		billing_client = billing_script.new() if billing_script != null else null
		if billing_client != null:
			add_child(billing_client)
			StoreManager.register_provider(self)
	PrivacyManager.refresh_consent()

func query_products(_product_ids: Array, callback: Callable) -> void:
	if callback.is_valid():
		callback.call({})

func purchase(product_id: String, success: Callable, failed: Callable) -> bool:
	if billing_client == null:
		failed.call(product_id, "Google Play Billing plugin unavailable")
		return false
	if billing_client.has_signal("on_purchase_updated"):
		var handler := func(response: Dictionary):
			var code := int(response.get("response_code", -1))
			if code != 0:
				failed.call(product_id, String(response.get("debug_message", "Purchase failed")))
				return
			for purchase in response.get("purchases", []):
				var products: Array = purchase.get("products", [])
				if product_id in products and int(purchase.get("purchase_state", 0)) == 1:
					success.call(product_id, String(purchase.get("purchase_token", "")))
		billing_client.on_purchase_updated.connect(handler, CONNECT_ONE_SHOT)
	var result: Dictionary = billing_client.purchase(product_id)
	if int(result.get("response_code", 0)) != 0:
		failed.call(product_id, String(result.get("debug_message", "Could not start purchase")))
		return false
	return true

func restore_purchases(callback: Callable) -> bool:
	if billing_client == null:
		return false
	var handler := func(response: Dictionary):
		callback.call(response.get("purchases", []))
	billing_client.query_purchases_response.connect(handler, CONNECT_ONE_SHOT)
	billing_client.query_purchases(0)
	return true

func finalize_purchase(token: String, consumable: bool) -> void:
	if billing_client == null or token.is_empty():
		return
	if consumable:
		billing_client.consume_purchase(token)
	else:
		billing_client.acknowledge_purchase(token)
