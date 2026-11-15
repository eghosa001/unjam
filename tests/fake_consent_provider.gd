extends Node

var pending_callback: Callable
var privacy_options_result := "options_not_required"

func request_consent(callback: Callable) -> void:
	pending_callback = callback

func resolve(status: String) -> void:
	if pending_callback.is_valid():
		var callback := pending_callback
		pending_callback = Callable()
		callback.call(status)

func show_privacy_options(callback: Callable) -> void:
	if callback.is_valid():
		callback.call(privacy_options_result)
