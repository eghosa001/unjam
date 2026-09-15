extends Node

const ADMOB_PROVIDER_PATH := "res://addons/unjam_admob_provider.gd"
const BILLING_CLIENT_PATH := "res://addons/GodotGooglePlayBilling/BillingClient.gd"
const BILLING_OK := 0
const PRODUCT_TYPE_INAPP := 0
const PURCHASE_STATE_PURCHASED := 1

var billing_client: Node
var admob_provider: Node
var _billing_connected := false
var _billing_registered := false

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	_initialize_billing()
	_initialize_admob()

func _initialize_billing() -> void:
	if OS.get_name() != "Android" or not ResourceLoader.exists(BILLING_CLIENT_PATH):
		return
	var billing_script = load(BILLING_CLIENT_PATH)
	billing_client = billing_script.new() if billing_script != null else null
	if billing_client == null:
		return
	add_child(billing_client)
	if billing_client.has_signal("connected"):
		billing_client.connected.connect(_on_billing_connected)
	if billing_client.has_signal("disconnected"):
		billing_client.disconnected.connect(_on_billing_disconnected)
	if billing_client.has_signal("connect_error"):
		billing_client.connect_error.connect(_on_billing_connect_error)
	if billing_client.has_method("start_connection"):
		billing_client.start_connection()

func _initialize_admob() -> void:
	if OS.get_name() == "Android" and ResourceLoader.exists(ADMOB_PROVIDER_PATH):
		var admob_script = load(ADMOB_PROVIDER_PATH)
		admob_provider = admob_script.new() if admob_script != null else null
		if admob_provider != null and admob_provider.has_method("plugin_available") and bool(admob_provider.call("plugin_available")):
			add_child(admob_provider)
			AdManager.register_provider(admob_provider)
			PrivacyManager.register_provider(admob_provider)
			return
	PrivacyManager.refresh_consent()

func _on_billing_connected() -> void:
	_billing_connected = true
	if not _billing_registered:
		_billing_registered = true
		StoreManager.register_provider(self)

func _on_billing_disconnected() -> void:
	_billing_connected = false

func _on_billing_connect_error(_response_code: int, _debug_message: String) -> void:
	_billing_connected = false

func billing_ready() -> bool:
	if billing_client == null or not _billing_connected:
		return false
	if billing_client.has_method("is_ready"):
		return bool(billing_client.is_ready())
	return true

func query_products(product_ids: Array, callback: Callable) -> void:
	if not billing_ready():
		if callback.is_valid():
			callback.call({})
		return
	var handler := func(response: Dictionary) -> void:
		var prices: Dictionary = {}
		if int(response.get("response_code", -1)) == BILLING_OK:
			for entry_value in response.get("product_details", []):
				var entry: Dictionary = entry_value
				var product_id := String(entry.get("product_id", ""))
				var offers = entry.get("one_time_purchase_offer_details_list", [])
				if offers == null:
					continue
				for offer_value in offers:
					var offer: Dictionary = offer_value
					var price := String(offer.get("formatted_price", ""))
					if not product_id.is_empty() and not price.is_empty():
						prices[product_id] = price
						break
		if callback.is_valid():
			callback.call(prices)
	if billing_client.has_signal("query_product_details_response"):
		billing_client.query_product_details_response.connect(handler, CONNECT_ONE_SHOT)
	billing_client.query_product_details(PackedStringArray(product_ids), PRODUCT_TYPE_INAPP)

func purchase(product_id: String, success: Callable, failed: Callable) -> bool:
	if not billing_ready():
		if failed.is_valid():
			failed.call(product_id, "Google Play Billing is not connected")
		return false
	if billing_client.has_signal("on_purchase_updated"):
		var handler := func(response: Dictionary):
			var code := int(response.get("response_code", -1))
			if code != BILLING_OK:
				if failed.is_valid():
					failed.call(product_id, String(response.get("debug_message", "Purchase failed")))
				return
			for purchase_value in response.get("purchases", []):
				var purchase_data: Dictionary = purchase_value
				var products: Array = Array(purchase_data.get("product_ids", []))
				if product_id in products and int(purchase_data.get("purchase_state", 0)) == PURCHASE_STATE_PURCHASED:
					if success.is_valid():
						success.call(product_id, String(purchase_data.get("purchase_token", "")))
		billing_client.on_purchase_updated.connect(handler, CONNECT_ONE_SHOT)
	var result: Dictionary = billing_client.purchase(product_id)
	if int(result.get("response_code", BILLING_OK)) != BILLING_OK:
		if failed.is_valid():
			failed.call(product_id, String(result.get("debug_message", "Could not start purchase")))
		return false
	return true

func restore_purchases(callback: Callable) -> bool:
	if not billing_ready():
		return false
	var handler := func(response: Dictionary):
		if callback.is_valid():
			callback.call(response.get("purchases", []) if int(response.get("response_code", -1)) == BILLING_OK else [])
	billing_client.query_purchases_response.connect(handler, CONNECT_ONE_SHOT)
	billing_client.query_purchases(PRODUCT_TYPE_INAPP)
	return true

func finalize_purchase(token: String, consumable: bool) -> void:
	if not billing_ready() or token.is_empty():
		return
	if consumable:
		billing_client.consume_purchase(token)
	else:
		billing_client.acknowledge_purchase(token)
