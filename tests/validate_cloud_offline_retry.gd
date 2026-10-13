extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var original: Dictionary = save.data.duplicate(true)
	var fake = load("res://tests/fake_cloud_save_manager.gd").new()
	fake.fixture = {"ok": false, "status": 503}
	root.add_child(fake)
	await process_frame
	await process_frame
	var timer := fake.get("_sync_timer") as Timer
	if not _check(timer != null and not timer.is_stopped(),
		"Offline startup must schedule a retry without waiting for a new level save"):return
	if not _check(bool(fake.get("_initial_reconciled")),
		"Offline startup blocked local play while checking cloud"):return
	if not _check(String(fake.call("backup_status")).contains("offline"),
		"Backup screen falsely reports successful sync while offline"):return
	if not _check(timer.time_left > 10.0 and timer.time_left <= 20.0,
		"Offline network would retry too aggressively"):return

	# Reconnection should clear the status, reset backoff and stop the
	# old timer, rather than repeatedly uploading the same save.
	fake.fixture = {"ok":true,"status":200,"revision":4}
	fake.call("_push_now")
	if not _check(String(fake.call("backup_status")).contains("synced"),
		"Successful reconnect did not refresh player-facing status"):return
	if not _check(timer.is_stopped() and float(fake.get("_sync_retry_delay")) == 20.0,
		"Successful upload left a stale retry or exponential penalty"):return

	# Repeated offline requests back off instead of retrying every 5 seconds.
	fake.fixture = {"ok":false,"status":503}
	fake.call("_push_now")
	if not _check(not timer.is_stopped() and float(fake.get("_sync_retry_delay")) == 40.0,
		"First failed upload did not back off"):return
	fake.call("_push_now")
	if not _check(float(fake.get("_sync_retry_delay")) == 80.0,
		"Repeated failures do not use bounded exponential backoff"):return

	# A 409 means another device saved a newer revision. If all this
	# phone's levels are already included, there is nothing to upload.
	var matching_remote: Dictionary = fake.call("_merge_progress_on_conflict", fake.call("_snapshot"))
	fake.fixture = {"ok":false,"status":409,"revision":5,"save":matching_remote}
	fake.call("_push_now")
	if not _check(String(fake.call("backup_status")).contains("synced"),
		"Resolved 409 is incorrectly presented as an endless sync conflict"):return
	if not _check(timer.is_stopped()
		and float(fake.get("_sync_retry_delay")) == 20.0,
		"Resolved 409 still has a needless retry scheduled"):return

	fake.queue_free()
	await process_frame
	save.data = original
	save.save()
	print("CLOUD_OFFLINE_RETRY_OK: startup retry, accurate player status and bounded exponential backoff")
	quit(0)

func _check(ok: bool, reason: String) -> bool:
	if ok:return true
	push_error(reason)
	quit(1)
	return false
