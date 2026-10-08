extends "res://scripts/systems/cloud_save_manager.gd"

# Test-only HTTP stand-in, loaded after Godot initializes the project autoloads.
var fixture: Dictionary = {}

func _request_json(_payload: Dictionary, callback: Callable) -> void:
	callback.call(bool(fixture.get("ok", true)), int(fixture.get("status", 200)), fixture)
