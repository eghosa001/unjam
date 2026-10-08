extends Node

var pending_callback: Callable

func request_consent(callback: Callable) -> void:
	pending_callback = callback

func resolve(status: String) -> void:
	if pending_callback.is_valid():
		var callback := pending_callback
		pending_callback = Callable()
		callback.call(status)
