extends SceneTree

var failures: Array[String] = []

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var bridge_path := "res://scripts/systems/android_monetization_bridge.gd"
	expect_true(ResourceLoader.exists(bridge_path), "Android monetization bridge missing")
	var source := FileAccess.get_file_as_string(bridge_path)
	expect_true("start_connection" in source, "Billing client is never connected")
	expect_true("query_product_details" in source, "Play product catalog query is missing")
	expect_true("formatted_price" in source, "Localized Play Store price parsing is missing")
	expect_true("product_ids" in source, "Billing v3.3 purchase payload key is not handled")
	expect_true("purchase_state" in source and "PURCHASE_STATE_PURCHASED" in source, "Purchase completion state is not validated")
	expect_true("query_purchases" in source, "Restore-purchases path is missing")
	expect_true("query_owned_purchases" in source, "Authoritative owned-purchase snapshot path is missing")
	expect_true("consume_purchase" not in source and "acknowledge_purchase" not in source, "Client billing bridge must not finalize verified purchases")

	# Google Play can return a pending purchase and later emit PURCHASED. The
	# purchase-update signal must therefore stay connected for the BillingClient
	# lifetime rather than being consumed by the first callback.
	expect_true("PURCHASE_STATE_PENDING := 2" in source, "Pending purchase state is not defined")
	expect_true("BILLING_USER_CANCELED := 1" in source, "User-cancelled billing response is not defined")
	expect_true("on_purchase_updated.connect(_on_purchase_updated)" in source, "Purchase updates are not handled by a persistent listener")
	expect_true("on_purchase_updated.connect(handler, CONNECT_ONE_SHOT)" not in source, "Purchase updates must not use a one-shot listener")
	expect_true("pending: Callable" in source, "Billing provider does not expose a pending-purchase callback")
	expect_true("Another purchase is already in progress" in source, "Billing bridge can launch a second purchase while another Play flow is active")

	# Billing service disconnects are expected on Android. The bridge must retry
	# with bounded backoff instead of leaving the store unavailable for the rest
	# of the session.
	expect_true("BILLING_RECONNECT_BASE_SECONDS" in source and "BILLING_RECONNECT_MAX_SECONDS" in source, "Billing reconnect backoff constants are missing")
	expect_true("_schedule_billing_reconnect" in source, "Billing disconnects do not schedule reconnection")

	var store_path := "res://scripts/systems/store_manager.gd"
	expect_true(ResourceLoader.exists(store_path), "StoreManager missing")
	if ResourceLoader.exists(store_path):
		var store_source := FileAccess.get_file_as_string(store_path)
		expect_true('purchase.get("product_ids"' in store_source, "Restore must read Google Play purchase product_ids")
		expect_true("signal purchase_pending" in store_source, "StoreManager does not expose pending purchase state")
		expect_true("_provider_purchase_pending" in store_source, "StoreManager does not release its purchase lock on pending state")
		expect_true("PURCHASE_TIMEOUT_SECONDS" in store_source and "_watch_purchase_timeout" in store_source, "Store purchase launch has no timeout recovery")
		expect_true("_on_reconcile_result" in store_source, "Store does not reconcile Play-owned purchases after reconnect/startup")
		expect_true("_revoke_missing_non_consumables" in store_source, "Store does not revoke stale non-consumable ownership")
		expect_true("reconcile_revocations" in store_source and "_apply_verified_revocation" in store_source, "Store does not apply backend-verified refunds/voids")
		expect_true('provider.call("finalize_purchase"' not in store_source, "Play finalization must not be performed by the client StoreManager")

	var verifier_path := "res://scripts/systems/purchase_verifier.gd"
	expect_true(ResourceLoader.exists(verifier_path), "PurchaseVerifier missing")
	if ResourceLoader.exists(verifier_path):
		var verifier_source := FileAccess.get_file_as_string(verifier_path)
		expect_true("VERIFICATION_TIMEOUT_SECONDS" in verifier_source, "Purchase verification timeout constant is missing")
		expect_true("request.timeout" in verifier_source, "Purchase verification HTTP request has no timeout")
		expect_true("request.max_redirects = 0" in verifier_source, "Purchase verification may forward purchase tokens through redirects")
		expect_true('parsed.get("product_id", "")' in verifier_source, "Purchase verification does not require an explicit matching product id")
		expect_true('"apikey: %s"' in verifier_source, "Supabase publishable key header is not sent")
		expect_true('"action": "verify"' in verifier_source and '"action": "commit"' in verifier_source, "Supabase purchase action routing is incomplete")
		expect_true('"action": "sync_revocations"' in verifier_source, "Purchase verifier does not synchronize refunded/voided purchases")
		expect_true('"install_id"' in verifier_source and "func install_id()" in verifier_source, "Purchase verifier does not bind claims to an installation")

	var backend_path := "res://supabase/functions/unjam-purchase/index.ts"
	expect_true(FileAccess.file_exists(backend_path), "Supabase purchase backend source missing")
	if FileAccess.file_exists(backend_path):
		var backend_source := FileAccess.get_file_as_string(backend_path)
		expect_true("purchases/voidedpurchases" in backend_source, "Voided Purchases API integration is missing")
		expect_true('suffix = product.nonConsumable ? "acknowledge" : "consume"' in backend_source, "Server-side Play acknowledge/consume finalization is missing")
		expect_true("consume_play_request_slot" in backend_source, "Purchase endpoint database rate limiting is missing")
		expect_true("install_bound_revocations" in backend_source, "Install-bound refund readiness capability is missing")
		expect_true("oneTimeProducts?pageSize=1000" in backend_source and "product_catalog_validation" in backend_source, "Google Play product-catalog readiness validation is missing")

	expect_true(FileAccess.file_exists("res://tools/install_monetization_plugins.sh"), "Monetization plugin installer missing")
	if FileAccess.file_exists("res://tools/install_monetization_plugins.sh"):
		var installer := FileAccess.get_file_as_string("res://tools/install_monetization_plugins.sh")
		expect_true("godot-google-play-billing" in installer and "3.3.0" in installer, "Google Play Billing 3.3.0 installer missing")
		expect_true("addons/GodotGooglePlayBilling/bin/debug/GodotGooglePlayBilling-debug.aar" in installer, "Billing installer does not require debug native AAR")
		expect_true("addons/GodotGooglePlayBilling/bin/release/GodotGooglePlayBilling-release.aar" in installer, "Billing installer does not require release native AAR")
	# The selective CI job intentionally clears editor_plugins before importing the
	# project because release-only Android addons are not installed there. The
	# production plugin declaration is enforced earlier by validate_release_contract.py.
	if failures.is_empty():
		print("BILLING PRODUCTION INTEGRATION VALIDATION PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
