extends "res://scripts/systems/robust_retention_manager.gd"

# RobustRetentionManager has one internal weekly-settlement path that writes the
# shared coin field directly. Capture only the delta produced while ensure_state
# runs so the live wallet stays synchronized without changing settlement math.

func ensure_state() -> void:
	var previous := int(SaveManager.data.get("coins", 0))
	super.ensure_state()
	var current := int(SaveManager.data.get("coins", 0))
	if current != previous:
		var economy := get_node_or_null("/root/EconomyManager")
		if economy != null and economy.has_method("notify_external_change"):
			economy.call("notify_external_change", previous, "retention_reward", {"source": "weekly_settlement"})
