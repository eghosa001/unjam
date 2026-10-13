extends SceneTree

const ExtraCopy = preload("res://scripts/systems/localization_screen_copy.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var l10n := root.get_node("LocalizationManager")
	var original := String(l10n.language_code)
	var keys := ExtraCopy.SCREEN_COPY["es"].keys()
	if not _check(keys.size() >= 16, "Navigation translation catalog is incomplete"):return
	for code in ["es","fr","pt","de","it","ha","yo","ig"]:
		if not _check(l10n.call("set_language", code, false), "Missing locale: %s" % code):return
		var extra: Dictionary = ExtraCopy.SCREEN_COPY[code]
		if not _check(extra.size() == keys.size(), "Locale coverage mismatch: %s" % code):return
		for key in keys:
			var translation := String(l10n.call("localize",key))
			if not _check(not translation.is_empty() and translation != key, "Untranslated primary screen label '%s' in %s" % [key,code]):return
			if not _check(translation.length() < 65, "Long primary nav copy needs shortened text in %s" % code):return
	l10n.call("set_language", original, false)
	print("PRIMARY_SCREEN_L10N_OK: 8 languages × %d launch navigation headings and restore" % keys.size())
	quit(0)

func _check(ok: bool, why: String) -> bool:
	if ok:return true
	push_error(why)
	quit(1)
	return false
