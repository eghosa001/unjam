extends Node

signal verification_completed(product_id: String, token: String, result: Dictionary)
signal commit_completed(product_id: String, token: String, committed: bool, reason: String)
signal revocations_synced(result: Dictionary)

const VERIFICATION_TIMEOUT_SECONDS := 20.0
const PACKAGE_NAME := "com.eghosa.unjamgam"
const FUNCTION_NAME := "unjam-purchase"

func install_id() -> String:
	var existing := String(SaveManager.data.get("purchase_install_id", "")).strip_edges()
	if existing.length() >= 16 and existing.length() <= 128:
		return existing
	var generated := Crypto.new().generate_random_bytes(16).hex_encode()
	if generated.is_empty():
		generated = "%s%s" % [str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
	SaveManager.data.purchase_install_id = generated
	SaveManager.save()
	return generated

func verify(product_id: String, token: String, claim_id: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		var desktop_result := {
			"valid": true, "grant": true, "entitlement": true, "claim_state": "issued",
			"product_id": product_id, "claim_id": claim_id, "reason": "desktop-test"
		}
		if callback.is_valid():
			callback.call(desktop_result)
		verification_completed.emit(product_id, token, desktop_result)
		return
	if token.is_empty():
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Missing purchase token"))
		return
	if claim_id.length() < 8 or claim_id.length() > 128:
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Purchase claim is invalid"))
		return
	var payload := {
		"action": "verify",
		"package_name": PACKAGE_NAME,
		"product_id": product_id,
		"purchase_token": token,
		"claim_id": claim_id,
		"install_id": install_id()
	}
	_request_json(payload, func(ok: bool, parsed: Dictionary, reason: String) -> void:
		var verification := _failure(product_id, claim_id, reason if not reason.is_empty() else "Verification failed")
		if ok:
			var verified_product_id := String(parsed.get("product_id", ""))
			var verified_claim_id := String(parsed.get("claim_id", ""))
			var valid := bool(parsed.get("valid", false)) and verified_product_id == product_id and verified_claim_id == claim_id
			verification = {
				"valid": valid,
				"grant": valid and bool(parsed.get("grant", false)),
				"entitlement": valid and bool(parsed.get("entitlement", false)),
				"claim_state": String(parsed.get("claim_state", "")) if valid else "",
				"product_id": product_id,
				"claim_id": claim_id,
				"reason": String(parsed.get("reason", "verified" if valid else "Verification rejected"))
			}
		_emit_verification(product_id, token, callback, verification)
	)

func commit(product_id: String, token: String, claim_id: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		if callback.is_valid():
			callback.call(true, "desktop-test")
		commit_completed.emit(product_id, token, true, "desktop-test")
		return
	if token.is_empty() or claim_id.length() < 8 or claim_id.length() > 128:
		if callback.is_valid():
			callback.call(false, "Purchase claim is invalid")
		commit_completed.emit(product_id, token, false, "Purchase claim is invalid")
		return
	var payload := {
		"action": "commit",
		"package_name": PACKAGE_NAME,
		"product_id": product_id,
		"purchase_token": token,
		"claim_id": claim_id,
		"install_id": install_id()
	}
	_request_json(payload, func(ok: bool, parsed: Dictionary, reason: String) -> void:
		var committed := ok and bool(parsed.get("committed", false)) and String(parsed.get("product_id", "")) == product_id
		var final_reason := String(parsed.get("reason", "committed" if committed else reason))
		if final_reason.is_empty():
			final_reason = "Purchase commit failed"
		if callback.is_valid():
			callback.call(committed, final_reason)
		commit_completed.emit(product_id, token, committed, final_reason)
	)

func sync_revocations(callback: Callable = Callable()) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		var desktop := {"ok": true, "revocations": [], "reason": "desktop-test"}
		if callback.is_valid():
			callback.call(desktop)
		revocations_synced.emit(desktop)
		return
	var payload := {
		"action": "sync_revocations",
		"package_name": PACKAGE_NAME,
		"install_id": install_id()
	}
	_request_json(payload, func(ok: bool, parsed: Dictionary, reason: String) -> void:
		var result := {
			"ok": ok and bool(parsed.get("ok", false)),
			"revocations": parsed.get("revocations", []) if parsed.get("revocations", []) is Array else [],
			"reason": String(parsed.get("reason", reason))
		}
		if callback.is_valid():
			callback.call(result)
		revocations_synced.emit(result)
	)

func _request_json(payload: Dictionary, callback: Callable) -> void:
	var endpoint := _function_endpoint()
	var headers := _request_headers()
	if endpoint.is_empty() or headers.is_empty():
		if callback.is_valid():
			callback.call(false, {}, "Supabase purchase verification is not configured")
		return
	var request := _new_request()
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var parsed: Dictionary = {}
		var reason := "Request failed"
		if result == HTTPRequest.RESULT_TIMEOUT:
			reason = "Purchase service timed out"
		else:
			var decoded = JSON.parse_string(body.get_string_from_utf8())
			if decoded is Dictionary:
				parsed = decoded
				reason = String(parsed.get("reason", parsed.get("error", reason)))
		var ok := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and parsed is Dictionary
		if callback.is_valid():
			callback.call(ok, parsed, reason)
		request.queue_free()
	)
	var err := request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		request.queue_free()
		if callback.is_valid():
			callback.call(false, {}, "Could not start purchase service request")

func _new_request() -> HTTPRequest:
	var request := HTTPRequest.new()
	request.timeout = VERIFICATION_TIMEOUT_SECONDS
	request.max_redirects = 0
	add_child(request)
	return request

func _function_endpoint() -> String:
	var base := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges().trim_suffix("/")
	if not base.begins_with("https://"):
		return ""
	return "%s/functions/v1/%s" % [base, FUNCTION_NAME]

func _request_headers() -> PackedStringArray:
	var key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if key.is_empty():
		return PackedStringArray()
	return PackedStringArray(["Content-Type: application/json", "apikey: %s" % key])

func _failure(product_id: String, claim_id: String, reason: String) -> Dictionary:
	return {
		"valid": false,
		"grant": false,
		"entitlement": false,
		"claim_state": "",
		"product_id": product_id,
		"claim_id": claim_id,
		"reason": reason
	}

func _emit_verification(product_id: String, token: String, callback: Callable, result: Dictionary) -> void:
	if callback.is_valid():
		callback.call(result)
	verification_completed.emit(product_id, token, result)
