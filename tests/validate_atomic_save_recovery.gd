extends SceneTree

const IO = preload("res://scripts/core/atomic_save_io.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prefix := "user://unjam-atomic-save-contract-%d" % Time.get_ticks_usec()
	var main_path := prefix + ".json"
	var pending_path := prefix + ".tmp"
	var backup_path := prefix + ".bak"
	var first := {"highest_level":11, "coins":100, "language_code":"fr"}
	var second := {"highest_level":20, "coins":135, "language_code":"yo"}
	if not _assert(IO.commit(main_path,pending_path,backup_path,JSON.stringify(first)),"Initial atomic commit failed"):return
	if not _assert(IO.recover(main_path,pending_path,backup_path)==first,"Freshly committed save could not be loaded"):return
	if not _assert(IO.commit(main_path,pending_path,backup_path,JSON.stringify(second)),"Overwrite of existing save failed"):return
	if not _assert(IO.read_dictionary(main_path)==second,"New commit not written to primary"):return
	if not _assert(IO.read_dictionary(backup_path)==first,"Previous valid save not retained as rollback"):return
	# A stale pending temp must never replace a valid committed main.
	_write(pending_path,JSON.stringify(first))
	if not _assert(IO.recover(main_path,pending_path,backup_path)==second,"Stale pending save displaced valid committed save"):return
	# Incomplete primary + fully flushed pending: recover the newer pending.
	_write(main_path,"{ broken")
	_write(pending_path,JSON.stringify(second))
	if not _assert(IO.recover(main_path,pending_path,backup_path)==second,"Interrupted replacement cannot recover pending state"):return
	# Incomplete primary and pending: fall back to the last valid backup.
	_write(pending_path,"{ also broken")
	if not _assert(IO.recover(main_path,pending_path,backup_path)==first,"Corrupt primary and pending lost last good backup"):return
	# Missing primary with valid pending must also recover after power loss.
	_remove(main_path)
	_write(pending_path,JSON.stringify(second))
	if not _assert(IO.recover(main_path,pending_path,backup_path)==second,"Absent primary could not recover pending save"):return
	if not _assert(not IO.commit(main_path,pending_path,backup_path,"not json"),"Invalid commit payload was accepted"):return
	for path in [main_path,pending_path,backup_path,backup_path+".tmp"]:
		_remove(path)
	# Simulate a filesystem error when refreshing the rollback destination.
	# The *existing primary* must survive and the new pending data remain.
	var blocked := prefix + "-blocked"
	var blocked_main := blocked+".json"
	var blocked_temp := blocked+".tmp"
	var blocked_backup := blocked+".bak"
	if not _assert(IO.commit(blocked_main,blocked_temp,blocked_backup,JSON.stringify(first)),"Blocked fixture setup failed"):return
	if not _assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_backup))==OK,"Could not simulate backup rename obstruction"):return
	if not _assert(not IO.commit(blocked_main,blocked_temp,blocked_backup,JSON.stringify(second)),"Commit was incorrectly successful with protected backup"):return
	if not _assert(IO.read_dictionary(blocked_main)==first,"Failed commit destroyed last valid primary"):return
	if not _assert(IO.read_dictionary(blocked_temp)==second,"Failed commit destroyed pending recoverable data"):return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_backup))
	for path in [blocked_main,blocked_temp,blocked_backup+".tmp"]:
		_remove(path)
	print("ATOMIC_SAVE_RECOVERY_OK: primary, temp, backup, corruption, interrupted writes and failed rename preserve progress.")
	quit(0)

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(value)
		file.flush()

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
