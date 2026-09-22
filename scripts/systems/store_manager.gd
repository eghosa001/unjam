extends Node

signal catalog_changed
signal purchase_started(product_id: String)
signal purchase_pending(product_id: String, reason: String)
signal purchase_succeeded(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restore_completed(count: int)
signal entitlement_revoked(product_id: String, reason: String)

const PRODUCT_REMOVE_ADS := "unjam_remove_ads"
const PRODUCT_STARTER_PACK := "unjam_starter_pack"
const PRODUCT_COINS_SMALL := "unjam_coins_500"
const PRODUCT_COINS_MEDIUM := "unjam_coins_1500"
const PRODUCT_COINS_LARGE := "unjam_coins_4000"
const PURCHASE_STATE_PURCHASED := 1
const PURCHASE_STATE_PENDING := 2
# Public semantic alias used by release/readiness code. Keep the numeric bridge
# constant separate so StoreManager does not depend on a plugin implementation.
const PURCHASE_PENDING := PURCHASE_STATE_PENDING
const PURCHASE_TIMEOUT_SECONDS := 60.0
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
var _purchase_serial := 0
var _restore_batch_active := false
var _restore_pending: Dictionary = {}
var _restore_success_count := 0

func register_provider(value: Node) -> void:
	provider = value
	if provider != null and provider.has_method("query_products"):
		provider.call("query_products", PRODUCTS.keys(), Callable(self, "set_localized_prices"))
	# Query owned purchases at startup and after every billing reconnect. This
	# recovers PURCHASED/PENDING transactions whose callback arrived while the
	# app or Play Billing service was unavailable.
	reconcile_purchases()
	reconcile_revocations()
	catalog_changed.emit()

func provider_ready() -> bool:
	return provider != null and is_instance_valid(provider)

func verifier_ready() -> bool:
	var supabase_url := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges()
	var publishable_key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	return supabase_url.begins_with("https://") and not publishable_key.is_empty()

func release_configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	var supabase_url := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges()
	var publishable_key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if not supabase_url.begins_with("https://"):
		issues.append("Supabase monetization URL is not configured")
	if publishable_key.is_empty():
		issues.append("Supabase publishable key is not configured")
	var privacy_url := String(ProjectSettings.get_setting("monetization/privacy_policy_url", ""))
	if not privacy_url.begins_with("https://"):
		issues.append("Privacy policy URL is not configured with HTTPS")
	return issues

func _token_fingerprint(token: String) -> String:
	return token.sha256_text() if not token.is_empty() else ""

func _claim_id_for_token(token: String) -> String:
	if token == "desktop-test":
		return "desktop-test-claim"
	var fingerprint := _token_fingerprint(token)
	if fingerprint.is_empty():
		return ""
	var claims_value = SaveManager.data.get("purchase_claim_ids", {})
	var claims: Dictionary = claims_value if claims_value is Dictionary else {}
	if claims.has(fingerprint):
		var existing := String(claims[fingerprint])
		if existing.length() >= 8 and existing.length() <= 128:
			return existing
	var claim_id := Crypto.new().generate_random_bytes(16).hex_encode()
	if claim_id.is_empty():
		claim_id = "%s-%s" % [str(Time.get_ticks_usec()), str(randi())]
	claims[fingerprint] = claim_id
	SaveManager.data.purchase_claim_ids = claims
	SaveManager.save()
	return claim_id

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
	if is_purchase_pending(product_id):
		purchase_pending.emit(product_id, "This purchase is still pending in Google Play")
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
		confirm_purchase(product_id, "desktop-test")
		return true
	_clear_purchase_busy(product_id)
	purchase_failed.emit(product_id, "Google Play Billing provider unavailable")
	return false

func confirm_purchase(product_id: String, purchase_token: String = "") -> void:
	if not PRODUCTS.has(product_id):
		_clear_purchase_busy(product_id)
		pending_products.erase(product_id)
		_settle_restore(product_id, purchase_token, false)
		return
	pending_products.erase(product_id)
	var claim_id := _claim_id_for_token(purchase_token)
	PurchaseVerifier.verify(product_id, purchase_token, claim_id, func(result: Dictionary): _on_verified(product_id, purchase_token, claim_id, result))

func _on_verified(product_id: String, token: String, claim_id: String, result: Dictionary) -> void:
	pending_products.erase(product_id)
	var valid := bool(result.get("valid", false))
	var reason := String(result.get("reason", "Verification failed"))
	if not valid:
		_clear_purchase_busy(product_id)
		purchase_failed.emit(product_id, reason)
		AnalyticsManager.track("purchase_verification_failed", {"product": product_id})
		_settle_restore(product_id, token, false)
		return

	var info: Dictionary = PRODUCTS[product_id]
	var coins := int(info.get("coins", 0))
	var non_consumable := bool(info.get("non_consumable", false))
	var grant := bool(result.get("grant", false))
	var entitlement := non_consumable and bool(result.get("entitlement", false))
	var claim_state := String(result.get("claim_state", ""))
	var processed: Array = SaveManager.data.get("processed_purchase_tokens", [])
	var fingerprint := _token_fingerprint(token)
	var locally_processed := (not fingerprint.is_empty() and fingerprint in processed) or token in processed

	# Migrate any pre-v10 raw local token without retaining the reusable credential.
	if token in processed:
		processed.erase(token)
		if not fingerprint.is_empty() and fingerprint not in processed:
			processed.append(fingerprint)

	var purchased: Array = SaveManager.data.get("purchased_products", [])
	var already_entitled := non_consumable and product_id in purchased
	if entitlement:
		if product_id == PRODUCT_REMOVE_ADS:
			AdManager.set_remove_ads_purchased(true)
		elif product_id == PRODUCT_STARTER_PACK:
			AdManager.set_remove_ads_purchased(true)
			SaveManager.data.starter_pack_purchased = true
		if product_id not in purchased:
			purchased.append(product_id)

	var granted_coins := 0
	if grant and not locally_processed and not already_entitled:
		if product_id == PRODUCT_STARTER_PACK and coins > 0:
			EconomyManager.grant(coins, "purchase", {"product": product_id})
			granted_coins = coins
		elif not non_consumable and coins > 0:
			EconomyManager.grant(coins, "purchase", {"product": product_id})
			SaveManager.data.lifetime_purchased_coins = int(SaveManager.data.get("lifetime_purchased_coins", 0)) + coins
			granted_coins = coins

	if grant and not token.is_empty() and token != "desktop-test" and not fingerprint.is_empty() and fingerprint not in processed:
		processed.append(fingerprint)
	SaveManager.data.purchased_products = purchased
	SaveManager.data.processed_purchase_tokens = processed
	SaveManager.save()

	# A new/same server claim is committed only after the local reward/entitlement
	# has been persisted. Play consume/acknowledge happens after this commit.
	if grant:
		PurchaseVerifier.commit(product_id, token, claim_id, func(committed: bool, commit_reason: String): _on_claim_committed(product_id, token, non_consumable, granted_coins, committed, commit_reason))
		return

	# Server-side duplicates never regrant currency. A committed claim can safely
	# be finalized again; an issued claim owned by another install is left alone.
	if claim_state == "committed":
		# The ledger may have been committed by an older build before server-side
		# acknowledgement/consumption was introduced. Re-run the idempotent backend
		# commit so Google Play finalization is guaranteed before reporting success.
		PurchaseVerifier.commit(product_id, token, claim_id, func(committed: bool, commit_reason: String):
			if committed:
				_clear_purchase_busy(product_id)
				purchase_succeeded.emit(product_id)
				AnalyticsManager.track("purchase_restored_without_regrant", {"product": product_id})
				_settle_restore(product_id, token, true)
			else:
				_clear_purchase_busy(product_id)
				purchase_pending.emit(product_id, "Purchase finalization will retry")
				AnalyticsManager.track("purchase_commit_pending", {"product": product_id, "reason": commit_reason})
				_settle_restore(product_id, token, false)
		)
		return

	_clear_purchase_busy(product_id)
	if non_consumable and entitlement:
		purchase_succeeded.emit(product_id)
		_settle_restore(product_id, token, true)
	else:
		purchase_pending.emit(product_id, "This purchase reward is already claimed or awaiting finalization")
		_settle_restore(product_id, token, false)

func _on_claim_committed(product_id: String, token: String, non_consumable: bool, granted_coins: int, committed: bool, reason: String) -> void:
	if committed:
		_clear_purchase_busy(product_id)
		purchase_succeeded.emit(product_id)
		AnalyticsManager.track("purchase_succeeded", {"product": product_id, "coins": granted_coins})
		_settle_restore(product_id, token, true)
		return

	# The reward is already safely persisted locally. Do not roll it back and do
	# not consume/acknowledge the Play purchase until the server commit succeeds.
	_clear_purchase_busy(product_id)
	purchase_pending.emit(product_id, "Reward saved; purchase finalization will retry")
	AnalyticsManager.track("purchase_commit_pending", {"product": product_id, "reason": reason})
	_settle_restore(product_id, token, true)
	call_deferred("reconcile_purchases")

func restore_purchases() -> bool:
	if _restore_batch_active:
		return false
	if not provider_ready() or not provider.has_method("restore_purchases"):
		return false
	_restore_batch_active = true
	_restore_pending.clear()
	_restore_success_count = 0
	var accepted = provider.call("restore_purchases", Callable(self, "_on_restore_result"))
	if accepted == false:
		_restore_batch_active = false
	return accepted != false

func _purchase_product_ids(purchase: Dictionary) -> Array:
	var product_ids = purchase.get("product_ids", [])
	if product_ids is Array and not product_ids.is_empty():
		return product_ids
	# Compatibility with any older provider adapter that exposed `products`.
	var legacy_products = purchase.get("products", [])
	return legacy_products if legacy_products is Array else []

func _on_restore_result(purchases: Array) -> void:
	_restore_batch_active = true
	_restore_pending.clear()
	_restore_success_count = 0
	var candidates: Array[Dictionary] = []
	for purchase_value in purchases:
		if not purchase_value is Dictionary:
			continue
		var purchase: Dictionary = purchase_value
		if int(purchase.get("purchase_state", PURCHASE_STATE_PURCHASED)) != PURCHASE_STATE_PURCHASED:
			continue
		var token := String(purchase.get("purchase_token", ""))
		for product_value in _purchase_product_ids(purchase):
			var product_id := String(product_value)
			if not PRODUCTS.has(product_id) or not bool(PRODUCTS[product_id].get("non_consumable", false)):
				continue
			var key := _restore_key(product_id, token)
			if _restore_pending.has(key):
				continue
			_restore_pending[key] = true
			candidates.append({"product_id": product_id, "token": token})
	if candidates.is_empty():
		_finish_restore_batch()
		return
	for candidate in candidates:
		confirm_purchase(String(candidate.get("product_id", "")), String(candidate.get("token", "")))

func _restore_key(product_id: String, token: String) -> String:
	return "%s:%s" % [product_id, _token_fingerprint(token)]

func _settle_restore(product_id: String, token: String, succeeded: bool) -> void:
	if not _restore_batch_active:
		return
	var key := _restore_key(product_id, token)
	if not _restore_pending.has(key):
		return
	_restore_pending.erase(key)
	if succeeded:
		_restore_success_count += 1
	if _restore_pending.is_empty():
		_finish_restore_batch()

func _finish_restore_batch() -> void:
	var restored := _restore_success_count
	_restore_pending.clear()
	_restore_success_count = 0
	_restore_batch_active = false
	restore_completed.emit(restored)

func reconcile_purchases() -> void:
	_reconcile_owned_purchases()

func reconcile_revocations() -> void:
	PurchaseVerifier.sync_revocations(Callable(self, "_on_revocations_synced"))

func _reconcile_owned_purchases() -> void:
	if not provider_ready():
		return
	if provider.has_method("query_owned_purchases"):
		provider.call("query_owned_purchases", Callable(self, "_on_owned_purchase_snapshot"))
		return
	if provider.has_method("restore_purchases"):
		provider.call("restore_purchases", Callable(self, "_on_reconcile_result"))

func _on_owned_purchase_snapshot(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	var purchases_value = result.get("purchases", [])
	if not purchases_value is Array:
		return
	var purchases: Array = purchases_value
	var owned_non_consumables: Array[String] = []
	for purchase_value in purchases:
		if not purchase_value is Dictionary:
			continue
		var purchase: Dictionary = purchase_value
		if int(purchase.get("purchase_state", PURCHASE_STATE_PURCHASED)) != PURCHASE_STATE_PURCHASED:
			continue
		for product_value in _purchase_product_ids(purchase):
			var product_id := String(product_value)
			if PRODUCTS.has(product_id) and bool(PRODUCTS[product_id].get("non_consumable", false)) and product_id not in owned_non_consumables:
				owned_non_consumables.append(product_id)
	_on_reconcile_result(purchases)
	_revoke_missing_non_consumables(owned_non_consumables)

func _on_reconcile_result(purchases: Array) -> void:
	for purchase_value in purchases:
		if not purchase_value is Dictionary:
			continue
		var purchase: Dictionary = purchase_value
		var state := int(purchase.get("purchase_state", PURCHASE_STATE_PURCHASED))
		var token := String(purchase.get("purchase_token", ""))
		for product_value in _purchase_product_ids(purchase):
			var product_id := String(product_value)
			if not PRODUCTS.has(product_id):
				continue
			if state == PURCHASE_PENDING:
				pending_products[product_id] = true
				purchase_pending.emit(product_id, "Purchase is pending in Google Play")
			elif state == PURCHASE_STATE_PURCHASED:
				pending_products.erase(product_id)
				confirm_purchase(product_id, token)

func _revoke_missing_non_consumables(owned: Array[String]) -> void:
	var purchased_value = SaveManager.data.get("purchased_products", [])
	var purchased: Array = purchased_value if purchased_value is Array else []
	var changed := false
	for product_id in [PRODUCT_REMOVE_ADS, PRODUCT_STARTER_PACK]:
		if product_id in purchased and product_id not in owned:
			purchased.erase(product_id)
			changed = true
			if product_id == PRODUCT_STARTER_PACK:
				SaveManager.data.starter_pack_purchased = false
			entitlement_revoked.emit(product_id, "Google Play no longer reports this purchase as owned")
			AnalyticsManager.track("purchase_entitlement_revoked", {"product": product_id, "source": "ownership_snapshot"})
	if not changed:
		return
	SaveManager.data.purchased_products = purchased
	var keep_remove_ads := PRODUCT_REMOVE_ADS in owned or PRODUCT_STARTER_PACK in owned
	AdManager.set_remove_ads_purchased(keep_remove_ads)
	SaveManager.save()
	catalog_changed.emit()

func _on_revocations_synced(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	var revocations_value = result.get("revocations", [])
	if not revocations_value is Array:
		return
	for value in revocations_value:
		if value is Dictionary:
			_apply_verified_revocation(value)

func _apply_verified_revocation(revocation: Dictionary) -> void:
	var token_hash := String(revocation.get("token_hash", ""))
	var product_id := String(revocation.get("product_id", ""))
	if token_hash.length() != 64 or not PRODUCTS.has(product_id):
		return
	var processed_value = SaveManager.data.get("processed_purchase_revocations", [])
	var processed: Array = processed_value if processed_value is Array else []
	if token_hash in processed:
		return
	var info: Dictionary = PRODUCTS[product_id]
	var purchased_value = SaveManager.data.get("purchased_products", [])
	var purchased: Array = purchased_value if purchased_value is Array else []
	if bool(info.get("non_consumable", false)):
		purchased.erase(product_id)
		SaveManager.data.purchased_products = purchased
		if product_id == PRODUCT_STARTER_PACK:
			SaveManager.data.starter_pack_purchased = false
		var keep_remove_ads := PRODUCT_REMOVE_ADS in purchased or PRODUCT_STARTER_PACK in purchased
		AdManager.set_remove_ads_purchased(keep_remove_ads)
	var coin_amount := int(info.get("coins", 0)) * maxi(1, int(revocation.get("voided_quantity", 1)))
	if coin_amount > 0 and EconomyManager.has_method("revoke_purchase_credit"):
		EconomyManager.call("revoke_purchase_credit", coin_amount, {
			"product": product_id,
			"token_hash": token_hash,
			"voided_reason": int(revocation.get("voided_reason", -1))
		})
	processed.append(token_hash)
	SaveManager.data.processed_purchase_revocations = processed
	SaveManager.save()
	entitlement_revoked.emit(product_id, "Google Play reported the purchase as refunded or voided")
	AnalyticsManager.track("purchase_revoked", {
		"product": product_id,
		"voided_reason": int(revocation.get("voided_reason", -1)),
		"voided_source": int(revocation.get("voided_source", -1))
	})
	catalog_changed.emit()

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
	_purchase_serial += 1
	active_purchase_product = product_id
	purchase_in_progress = true
	_watch_purchase_timeout(product_id, _purchase_serial)

func _watch_purchase_timeout(product_id: String, serial: int) -> void:
	await get_tree().create_timer(PURCHASE_TIMEOUT_SECONDS).timeout
	if serial != _purchase_serial or active_purchase_product != product_id or not purchase_in_progress:
		return
	# The Play UI/service did not settle the launch. Release only the launch lock,
	# mark it pending, and immediately reconcile so a late PURCHASED result can
	# still be verified and granted exactly once.
	_provider_purchase_pending(product_id, "Google Play is still processing this purchase")
	reconcile_purchases()

func _clear_purchase_busy(product_id: String) -> void:
	# A pending purchase can become PURCHASED while another product is being
	# launched. Never let that background completion unlock the newer launch.
	if active_purchase_product == product_id:
		active_purchase_product = ""
		purchase_in_progress = false
