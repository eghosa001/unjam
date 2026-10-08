extends RefCounted

# Filesystem-only save transactions, deliberately free of gameplay and wallet
# policy so crash/recovery scenarios can be tested on isolated user:// paths.
# Godot's DirAccess.rename_absolute replaces an existing destination file.
# Never delete or truncate the live save before that replacement succeeds.
static func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null:
		return {}
	var parsed = JSON.parse_string(source.get_as_text())
	return parsed if parsed is Dictionary and not parsed.is_empty() else {}

static func recover(primary: String, pending: String, backup: String) -> Dictionary:
	# A committed valid primary wins; an interrupted temp write must not silently
	# override it. If the primary is missing/corrupt, a fully written temp is the
	# most recent recoverable state. Otherwise use the last committed backup.
	for path in [primary, pending, backup]:
		var restored := read_dictionary(path)
		if not restored.is_empty():
			return restored
	return {}

static func _write_text(path: String, value: String) -> bool:
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		return false
	output.store_string(value)
	output.flush()
	output = null
	return true

static func commit(primary: String, pending: String, backup: String, payload: String) -> bool:
	if not JSON.parse_string(payload) is Dictionary:
		return false
	# Stage the new save first, without touching a committed primary or backup.
	if not _write_text(pending, payload):
		return false
	var old_data := read_dictionary(primary)
	if not old_data.is_empty():
		var existing := FileAccess.open(primary, FileAccess.READ)
		if existing == null:
			return false
		var old_payload := existing.get_as_text()
		existing = null
		# Refresh the rollback copy by replacing a fully written backup temp.
		# If this step fails, leave the old primary intact and the new temp
		# available for recovery instead of risking a destructive fallback.
		var backup_pending := backup + ".tmp"
		if not _write_text(backup_pending, old_payload):
			return false
		if DirAccess.rename_absolute(
			ProjectSettings.globalize_path(backup_pending),
			ProjectSettings.globalize_path(backup)
		) != OK:
			return false
	# One filesystem rename commits the new state. Never remove the destination
	# ahead of time, and never fall back to direct FileAccess.WRITE on failure.
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(pending),
		ProjectSettings.globalize_path(primary)
	) == OK
