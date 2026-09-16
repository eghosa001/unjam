extends Node

signal verification_completed(product_id: String, token: String, valid: bool, reason: String)

const VERIFICATION_TIMEOUT_SECONDS := 20.0

func verify(product_id: String, token: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		callback.call(true, "desktop-test")
		verification_completed.emit(product_id, token, true, "desktop-test")
		return
	if token.is_empty():
		callback.call(false, "Missing purchase token")
		verification_completed.emit(product_id, token, false, "Missing purchase token")
		return
	var endpoint := String(ProjectSettings.get_setting("monetization/purchase_verification_url", ""))
	if endpoint.is_empty() or not endpoint.begins_with("https://"):
		callback.call(false, "Secure purchase verification is not configured")
		verification_completed.emit(product_id, token, false, "Secure purchase verification is not configured")
		return
	var request := HTTPRequest.new()
	request.timeout = VERIFICATION_TIMEOUT_SECONDS
	# Purchase tokens are bearer-like credentials. Never follow redirects to a
	# different endpoint; the configured HTTPS verifier must answer directly.
	request.max_redirects = 0
	add_child(request)
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var ok := false
		var reason := "Verification failed"
		if result == HTTPRequest.RESULT_TIMEOUT:
			reason = "Purchase verification timed out"
		elif response_code >= 200 and response_code < 300:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary:
				var verified_product_id := String(parsed.get("product_id", ""))
				ok = bool(parsed.get("valid", false)) and not verified_product_id.is_empty() and verified_product_id == product_id
				reason = String(parsed.get("reason", "verified" if ok else "Verification rejected"))
		callback.call(ok, reason)
		verification_completed.emit(product_id, token, ok, reason)
		request.queue_free()
	)
	var payload := JSON.stringify({"package_name": "com.eghosa.unjam", "product_id": product_id, "purchase_token": token})
	var err := request.request(endpoint, ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
	if err != OK:
		request.queue_free()
		callback.call(false, "Could not start purchase verification")
		verification_completed.emit(product_id, token, false, "Could not start purchase verification")
