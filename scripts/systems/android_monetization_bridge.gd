extends Node

# Android billing payload + already-owned recovery regression verified.

const ADMOB_PROVIDER_PATH := "res://addons/unjam_admob_provider.gd"
const BILLING_CLIENT_PATH := "res://addons/GodotGooglePlayBilling/BillingClient.gd"
const BILLING_OK := 0
const BILLING_USER_CANCELED := 1
const BILLING_ITEM_ALREADY_OWNED := 7
const BILLING_ITEM_NOT_OWNED := 8
const PRODUCT_TYPE_INAPP := 0
const PURCHASE_STATE_PURCHASED := 1
const PURCHASE_STATE_PENDING := 2
const BILLING_RECONNECT_BASE_SECONDS := 2.0
const BILLING_RECONNECT_MAX_SECONDS := 30.0

var billing_client: Node
var admob_provider: Node
var _billing_connected := false
var _billing_reconnect_attempt := 0
var _billing_reconnect_scheduled := false
var _purchase_requests: Dictionary = {}
var _launch_product_id := ""
var _finalization_queue: Array[Dictionary] = []
var _finalization_active := false

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
	# Purchase updates can arrive more than once for the same transaction. In
	# particular, Google Play can emit PENDING and later PURCHASED, so this must
	# live for the lifetime of the BillingClient rather than CONNECT_ONE_SHOT.
	if billing_client.has_signal("on_purchase_updated"):
		billing_client.on_purchase_updated.connect(_on_purchase_updated)
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
	_billing_reconnect_attempt = 0
	_billing_reconnect_scheduled = false
	# Re-registering is intentional. StoreManager refreshes localized prices and
	# reconciles Play-owned purchases on both initial startup and every reconnect.
	StoreManager.register_provider(self)

func _on_billing_disconnected() -> void:
	_billing_connected = false
	_schedule_billing_reconnect()

func _on_billing_connect_error(_response_code: int, _debug_message: String) -> void:
	_billing_connected = false
	_schedule_billing_reconnect()

func _schedule_billing_reconnect() -> void:
	if OS.get_name() != "Android" or billing_client == null or not is_instance_valid(billing_client):
		return
	if _billing_connected or _billing_reconnect_scheduled:
		return
	_billing_reconnect_scheduled = true
	_billing_reconnect_attempt += 1
	var exponent: int = maxi(0, _billing_reconnect_attempt - 1)
	var delay: float = minf(BILLING_RECONNECT_MAX_SECONDS, BILLING_RECONNECT_BASE_SECONDS * pow(2.0, float(exponent)))
	get_tree().create_timer(delay).timeout.connect(_retry_billing_connection, CONNECT_ONE_SHOT)

func _retry_billing_connection() -> void:
	_billing_reconnect_scheduled = false
	if _billing_connected or billing_client == null or not is_instance_valid(billing_client):
		return
	if billing_client.has_method("start_connection"):
		billing_client.start_connection()

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
				if not entry_value is Dictionary:
					continue
				var entry: Dictionary = entry_value
				var product_id := String(entry.get("product_id", ""))
				var offers = entry.get("one_time_purchase_offer_details_list", [])
				if offers == null:
					continue
				for offer_value in offers:
					if not offer_value is Dictionary:
						continue
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

func purchase(product_id: String, success: Callable, failed: Callable, pending: Callable = Callable()) -> bool:
	if not billing_ready():
		if failed.is_valid():
			failed.call(product_id, "Google Play Billing is not connected")
		return false
	if not _launch_product_id.is_empty():
		if failed.is_valid():
			failed.call(product_id, "Another purchase is already in progress")
		return false
	if _purchase_requests.has(product_id):
		if failed.is_valid():
			failed.call(product_id, "This purchase is already pending in Google Play")
		return false
	_purchase_requests[product_id] = {
		"success": success,
		"failed": failed,
		"pending": pending,
		"pending_notified": false
	}
	_launch_product_id = product_id
	var result: Dictionary = billing_client.purchase(product_id)
	var response_code := int(result.get("response_code", BILLING_OK))
	if response_code == BILLING_ITEM_ALREADY_OWNED:
		# Do not strand a consumable as "already owned". Recover the Play-owned
		# token and send it through the normal verify/grant/finalize pipeline.
		_recover_owned_purchase_request(product_id)
		return true
	if response_code != BILLING_OK:
		_fail_purchase_request(product_id, String(result.get("debug_message", "Could not start purchase")))
		return false
	return true

func _product_ids_from_purchase(purchase: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw = purchase.get("product_ids", PackedStringArray())
	if raw is PackedStringArray:
		for value in raw:
			result.append(String(value))
	elif raw is Array:
		for value in raw:
			result.append(String(value))
	else:
		var legacy = purchase.get("products", [])
		if legacy is PackedStringArray or legacy is Array:
			for value in legacy:
				result.append(String(value))
	return result

func _on_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code != BILLING_OK:
		var failed_product := _launch_product_id
		if not failed_product.is_empty():
			if code == BILLING_ITEM_ALREADY_OWNED:
				_recover_owned_purchase_request(failed_product)
				return
			var reason := "Purchase cancelled" if code == BILLING_USER_CANCELED else String(response.get("debug_message", "Purchase failed"))
			_fail_purchase_request(failed_product, reason)
		return

	var matched_launch := false
	for purchase_value in response.get("purchases", []):
		if not purchase_value is Dictionary:
			continue
		var purchase_data: Dictionary = purchase_value
		var products: Array[String] = _product_ids_from_purchase(purchase_data)
		if products.is_empty():
			continue
		var state := int(purchase_data.get("purchase_state", 0))
		for product_value in products:
			var product_id := String(product_value)
			if product_id == _launch_product_id:
				matched_launch = true
			if not _purchase_requests.has(product_id):
				continue
			match state:
				PURCHASE_STATE_PURCHASED:
					_complete_purchase_request(product_id, String(purchase_data.get("purchase_token", "")))
				PURCHASE_STATE_PENDING:
					_notify_purchase_pending(product_id)
				_:
					_fail_purchase_request(product_id, "Google Play returned an unknown purchase state")

	# A successful update for the currently launched product should contain that
	# product. If it does not, terminate that launch instead of leaving the app
	# permanently blocked waiting for a callback that already arrived.
	if not _launch_product_id.is_empty() and not matched_launch:
		_fail_purchase_request(_launch_product_id, "Google Play did not return the requested product")

func _complete_purchase_request(product_id: String, token: String) -> void:
	if not _purchase_requests.has(product_id):
		return
	var request: Dictionary = _purchase_requests[product_id]
	_purchase_requests.erase(product_id)
	if _launch_product_id == product_id:
		_launch_product_id = ""
	var success: Callable = request.get("success", Callable())
	if success.is_valid():
		success.call(product_id, token)

func _notify_purchase_pending(product_id: String) -> void:
	if not _purchase_requests.has(product_id):
		return
	var request: Dictionary = _purchase_requests[product_id]
	if bool(request.get("pending_notified", false)):
		return
	request["pending_notified"] = true
	_purchase_requests[product_id] = request
	if _launch_product_id == product_id:
		_launch_product_id = ""
	var pending: Callable = request.get("pending", Callable())
	if pending.is_valid():
		pending.call(product_id, "Purchase is pending in Google Play")

func _fail_purchase_request(product_id: String, reason: String) -> void:
	if not _purchase_requests.has(product_id):
		if _launch_product_id == product_id:
			_launch_product_id = ""
		return
	var request: Dictionary = _purchase_requests[product_id]
	_purchase_requests.erase(product_id)
	if _launch_product_id == product_id:
		_launch_product_id = ""
	var failed: Callable = request.get("failed", Callable())
	if failed.is_valid():
		failed.call(product_id, reason)

func _recover_owned_purchase_request(product_id: String) -> void:
	if not _purchase_requests.has(product_id):
		return
	query_owned_purchases(func(result: Dictionary) -> void:
		if not bool(result.get("ok", false)):
			_fail_purchase_request(product_id, String(result.get("reason", "Could not recover the existing Google Play purchase")))
			return
		var purchases_value = result.get("purchases", [])
		if not purchases_value is Array:
			_fail_purchase_request(product_id, "Google Play did not return the existing purchase")
			return
		for purchase_value in purchases_value:
			if not purchase_value is Dictionary:
				continue
			var purchase: Dictionary = purchase_value
			var products: Array[String] = _product_ids_from_purchase(purchase)
			if product_id not in products:
				continue
			var state := int(purchase.get("purchase_state", 0))
			if state == PURCHASE_STATE_PURCHASED:
				_complete_purchase_request(product_id, String(purchase.get("purchase_token", "")))
				return
			if state == PURCHASE_STATE_PENDING:
				_notify_purchase_pending(product_id)
				return
		_fail_purchase_request(product_id, "Google Play reports this item as owned, but no active purchase could be recovered")
	)

func restore_purchases(callback: Callable) -> bool:
	if not billing_ready():
		return false
	var handler := func(response: Dictionary):
		if callback.is_valid():
			callback.call(response.get("purchases", []) if int(response.get("response_code", -1)) == BILLING_OK else [])
	billing_client.query_purchases_response.connect(handler, CONNECT_ONE_SHOT)
	billing_client.query_purchases(PRODUCT_TYPE_INAPP)
	return true

func query_owned_purchases(callback: Callable) -> bool:
	if not billing_ready():
		if callback.is_valid():
			callback.call({"ok": false, "purchases": [], "reason": "Google Play Billing is not connected"})
		return false
	var handler := func(response: Dictionary):
		var ok := int(response.get("response_code", -1)) == BILLING_OK
		var purchases = response.get("purchases", []) if ok else []
		if not purchases is Array:
			purchases = []
		if callback.is_valid():
			callback.call({
				"ok": ok,
				"purchases": purchases,
				"reason": "" if ok else String(response.get("debug_message", "Could not query owned purchases"))
			})
	billing_client.query_purchases_response.connect(handler, CONNECT_ONE_SHOT)
	billing_client.query_purchases(PRODUCT_TYPE_INAPP)
	return true

# Server-side finalization remains the primary path. StoreManager invokes this
# fallback only after the purchase ledger has already committed the verified
# claim, so a client-side consume/acknowledge can never bypass deduplication.
func finalize_purchase(purchase_token: String, non_consumable: bool, callback: Callable) -> bool:
	if purchase_token.is_empty() or not billing_ready():
		return false
	var signal_name := StringName("acknowledge_purchase_response" if non_consumable else "consume_purchase_response")
	var method_name := StringName("acknowledge_purchase" if non_consumable else "consume_purchase")
	if not billing_client.has_signal(signal_name) or not billing_client.has_method(method_name):
		return false
	_finalization_queue.append({
		"token": purchase_token,
		"non_consumable": non_consumable,
		"callback": callback
	})
	_pump_finalization_queue()
	return true

func _pump_finalization_queue() -> void:
	if _finalization_active or _finalization_queue.is_empty():
		return
	if not billing_ready():
		_fail_queued_finalization("Google Play Billing is not connected")
		return
	var request: Dictionary = _finalization_queue.front()
	var non_consumable := bool(request.get("non_consumable", false))
	var purchase_token := String(request.get("token", ""))
	var callback: Callable = request.get("callback", Callable())
	var signal_name := StringName("acknowledge_purchase_response" if non_consumable else "consume_purchase_response")
	var method_name := StringName("acknowledge_purchase" if non_consumable else "consume_purchase")
	if not billing_client.has_signal(signal_name) or not billing_client.has_method(method_name):
		_fail_queued_finalization("Google Play Billing finalization is unavailable")
		return
	_finalization_active = true
	var handler := func(response: Dictionary) -> void:
		var code := int(response.get("response_code", -1))
		# ITEM_NOT_OWNED is idempotent success here: this fallback is only reached
		# after the backend has committed the verified claim, so absence from Play
		# ownership means the transaction was already finalized elsewhere.
		var finalized := code == BILLING_OK or (not non_consumable and code == BILLING_ITEM_NOT_OWNED)
		var reason := "" if finalized else String(response.get("debug_message", "Google Play finalization failed"))
		_finalization_active = false
		if not _finalization_queue.is_empty():
			_finalization_queue.pop_front()
		if callback.is_valid():
			callback.call(finalized, reason)
		call_deferred("_pump_finalization_queue")
	var connect_error := billing_client.connect(signal_name, handler, CONNECT_ONE_SHOT)
	if connect_error != OK:
		_finalization_active = false
		_fail_queued_finalization("Could not observe Google Play finalization")
		return
	billing_client.call(method_name, purchase_token)

func _fail_queued_finalization(reason: String) -> void:
	if _finalization_queue.is_empty():
		_finalization_active = false
		return
	var request: Dictionary = _finalization_queue.pop_front()
	_finalization_active = false
	var callback: Callable = request.get("callback", Callable())
	if callback.is_valid():
		callback.call(false, reason)
	call_deferred("_pump_finalization_queue")

