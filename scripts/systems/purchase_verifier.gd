extends Node

signal verification_completed(product_id: String, token: String, valid: bool, reason: String)

func verify(product_id: String, token: String, callback: Callable) -> void:
	if OS.get_name() != "Android" and bool(ProjectSettings.get_setting("monetization/test_mode", false)):
		callback.call(true, "desktop-test")
		return
	if token.is_empty():
		callback.call(false, "Missing purchase token")
		return
	var endpoint := String(ProjectSettings.get_setting("monetization/purchase_verification_url", ""))
	if endpoint.is_empty() or not endpoint.begins_with("https://"):
		callback.call(false, "Secure purchase verification is not configured")
		return
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var ok := false
		var reason := "Verification failed"
		if response_code >= 200 and response_code < 300:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary:
				ok = bool(parsed.get("valid", false)) and String(parsed.get("product_id", product_id)) == product_id
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
