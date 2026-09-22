extends Node

signal verification_completed(product_id: String, token: String, result: Dictionary)
signal commit_completed(product_id: String, token: String, committed: bool, reason: String)

const VERIFICATION_TIMEOUT_SECONDS := 20.0
const PACKAGE_NAME := "com.eghosa.unjamgam"
const FUNCTION_NAME := "unjam-purchase"

func verify(product_id: String, token: String, claim_id: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		var desktop_result := {
			"valid": true, "grant": true, "entitlement": true, "claim_state": "issued",
			"product_id": product_id, "claim_id": claim_id, "reason": "desktop-test"
		}
		callback.call(desktop_result)
		verification_completed.emit(product_id, token, desktop_result)
		return
	if token.is_empty():
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Missing purchase token"))
		return
	if claim_id.length() < 8 or claim_id.length() > 128:
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Purchase claim is invalid"))
		return
	var endpoint := _function_endpoint()
	var headers := _request_headers()
	if endpoint.is_empty() or headers.is_empty():
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Supabase purchase verification is not configured"))
		return
	var request := _new_request()
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var verification := _failure(product_id, claim_id, "Verification failed")
		if result == HTTPRequest.RESULT_TIMEOUT:
			verification.reason = "Purchase verification timed out"
		elif response_code >= 200 and response_code < 300:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary:
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
		request.queue_free()
	)
	var payload := JSON.stringify({
		"action": "verify", "package_name": PACKAGE_NAME, "product_id": product_id,
		"purchase_token": token, "claim_id": claim_id
	})
	var err := request.request(endpoint, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		request.queue_free()
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Could not start purchase verification"))

func commit(product_id: String, token: String, claim_id: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		callback.call(true, "desktop-test")
		commit_completed.emit(product_id, token, true, "desktop-test")
		return
	if token.is_empty() or claim_id.length() < 8 or claim_id.length() > 128:
		callback.call(false, "Purchase claim is invalid")
		commit_completed.emit(product_id, token, false, "Purchase claim is invalid")
		return
	var endpoint := _function_endpoint()
	var headers := _request_headers()
	if endpoint.is_empty() or headers.is_empty():
		callback.call(false, "Supabase purchase verification is not configured")
		commit_completed.emit(product_id, token, false, "Supabase purchase verification is not configured")
		return
	var request := _new_request()
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var committed := false
		var reason := "Purchase commit failed"
		if result == HTTPRequest.RESULT_TIMEOUT:
			reason = "Purchase commit timed out"
		elif response_code >= 200 and response_code < 300:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and String(parsed.get("product_id", "")) == product_id:
				committed = bool(parsed.get("committed", false))
				reason = String(parsed.get("reason", "committed" if committed else "Purchase commit rejected"))
		callback.call(committed, reason)
		commit_completed.emit(product_id, token, committed, reason)
		request.queue_free()
	)
	var payload := JSON.stringify({
		"action": "commit", "package_name": PACKAGE_NAME, "product_id": product_id,
		"purchase_token": token, "claim_id": claim_id
	})
	var err := request.request(endpoint, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		request.queue_free()
		callback.call(false, "Could not start purchase commit")
		commit_completed.emit(product_id, token, false, "Could not start purchase commit")

func _new_request() -> HTTPRequest:
	var request := HTTPRequest.new()
	request.timeout = VERIFICATION_TIMEOUT_SECONDS
	request.max_redirects = 0
	add_child(request)
	return request

func _function_endpoint() -> String:
	var base := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges().trim_suffix("/")
	if not base.begins_with("https://") or not ".supabase.co" in base:
		return ""
	return "%s/functions/v1/%s" % [base, FUNCTION_NAME]

func _request_headers() -> PackedStringArray:
	var key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if key.is_empty():
		return PackedStringArray()
	return PackedStringArray(["Content-Type: application/json", "apikey: %s" % key])

func _failure(product_id: String, claim_id: String, reason: String) -> Dictionary:
	return {"valid": false, "grant": false, "entitlement": false, "claim_state": "", "product_id": product_id, "claim_id": claim_id, "reason": reason}

func _emit_verification(product_id: String, token: String, callback: Callable, result: Dictionary) -> void:
	callback.call(result)
	verification_completed.emit(product_id, token, result)
