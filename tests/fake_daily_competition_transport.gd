extends "res://scripts/systems/competition_manager.gd"

# Deterministic transport: validates the queue without live-network calls.
var pending_requests: Array = []

func _request_json(payload: Dictionary, callback: Callable) -> void:
	pending_requests.append({"payload":payload.duplicate(true),"callback":callback})
