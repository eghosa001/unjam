extends Node

signal verification_completed(product_id: String, token: String, result: Dictionary)
signal commit_completed(product_id: String, token: String, committed: bool, reason: String)

const VERIFICATION_TIMEOUT_SECONDS := 20.0
const PACKAGE_NAME := "com.eghosa.unjam"

func verify(product_id: String, token: String, claim_id: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		var desktop_result := {
			"valid": true,
			"grant": true,
			"entitlement": true,
			"claim_state": "issued",
			"product_id": product_id,
			"claim_id": claim_id,
			"reason": "desktop-test"
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
	var endpoint := _verification_endpoint()
	if endpoint.is_empty():
		_emit_verification(product_id, token, callback, _failure(product_id, claim_id, "Secure purchase verification is not configured"))
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
	var payload := JSON.stringify({"package_name": PACKAGE_NAME, "product_id": product_id, "purchase_token": token, "claim_id": claim_id})
	var err := request.request(endpoint, ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
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
	var endpoint := _commit_endpoint()
	if endpoint.is_empty():
		callback.call(false, "Secure purchase verification is not configured")
		commit_completed.emit(product_id, token, false, "Secure purchase verification is not configured")
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
	var payload := JSON.stringify({"package_name": PACKAGE_NAME, "product_id": product_id, "purchase_token": token, "claim_id": claim_id})
	var err := request.request(endpoint, ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
	if err != OK:
		request.queue_free()
		callback.call(false, "Could not start purchase commit")
		commit_completed.emit(product_id, token, false, "Could not start purchase commit")

func _new_request() -> HTTPRequest:
	var request := HTTPRequest.new()
	request.timeout = VERIFICATION_TIMEOUT_SECONDS
	# Purchase tokens are bearer-like credentials. Never follow redirects to a
	# different endpoint; the configured HTTPS verifier must answer directly.
	request.max_redirects = 0
	add_child(request)
	return request

func _verification_endpoint() -> String:
	var endpoint := String(ProjectSettings.get_setting("monetization/purchase_verification_url", "")).strip_edges()
	return endpoint if endpoint.begins_with("https://") else ""

func _commit_endpoint() -> String:
	var endpoint := _verification_endpoint()
	if endpoint.is_empty():
		return ""
	if endpoint.ends_with("/verify"):
		return endpoint.left(endpoint.length() - 7) + "/commit"
	return endpoint.trim_suffix("/") + "/commit"

func _failure(product_id: String, claim_id: String, reason: String) -> Dictionary:
	return {"valid": false, "grant": false, "entitlement": false, "claim_state": "", "product_id": product_id, "claim_id": claim_id, "reason": reason}

func _emit_verification(product_id: String, token: String, callback: Callable, result: Dictionary) -> void:
	callback.call(result)
	verification_completed.emit(product_id, token, result)
