extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node_or_null("SaveManager")
	if save == null:
		_fail("SaveManager not available")
		return
	var old_data: Dictionary = save.data.duplicate(true)
	# Runtime load avoids parsing the inheritance tree before project autoloads.
	var fake_script := load("res://tests/fake_cloud_save_manager.gd")
	if fake_script == null:
		_fail("Cloud recovery test fixture unavailable")
		return
	var recovery = fake_script.new()
	recovery.set("_initial_reconciled", true)
	var starting_id := recovery.recovery_code()
	if starting_id.length() != 64:
		_revert(recovery, save, old_data)
		_fail("Current recovery identity is missing")
		return
	var callbacks := []
	var invalid_id := "not-a-cloud-save-id"
	recovery.restore_from_recovery_code(invalid_id, func(ok: bool, _message: String) -> void:
		callbacks.append(ok)
	)
	if callbacks != [false] or recovery.recovery_code() != starting_id:
		_revert(recovery, save, old_data)
		_fail("Invalid recovery code changed the active save")
		return

	var remote_id := "c".repeat(64) if starting_id != "c".repeat(64) else "d".repeat(64)
	recovery.fixture = {"ok":true, "status":200, "exists":false}
	callbacks.clear()
	recovery.restore_from_recovery_code(remote_id, func(ok: bool, _message: String) -> void:
		callbacks.append(ok)
	)
	if callbacks != [false] or recovery.recovery_code() != starting_id:
		_revert(recovery, save, old_data)
		_fail("Missing remote backup replaced healthy local progress")
		return

	var purchased: Array = (save.data.get("purchased_products", []) as Array).duplicate()
	var level_before := int(save.data.get("highest_level", 1))
	var remote_level := level_before + 3
	recovery.fixture = {"ok":true, "status":200, "exists":true, "revision":9, "save":{"highest_level":remote_level}}
	callbacks.clear()
	recovery.restore_from_recovery_code(remote_id, func(ok: bool, _message: String) -> void:
		callbacks.append(ok)
	)
	var restored := callbacks == [true] and recovery.recovery_code() == remote_id and int(save.data.get("highest_level", 0)) == remote_level
	var kept_purchases := (save.data.get("purchased_products", []) as Array) == purchased
	_revert(recovery, save, old_data)
	if not restored or not kept_purchases:
		_fail("Verified restore did not apply cloud progress or preserved paid entitlements")
		return
	print("CLOUD_RECOVERY_CONTRACT_OK: invalid, missing and valid restores, no paid-entitlement changes.")
	quit(0)

func _revert(recovery: Node, save: Node, old_data: Dictionary) -> void:
	recovery.free()
	save.data = old_data
	save.save()

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
