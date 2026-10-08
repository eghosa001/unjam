extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node_or_null("SaveManager")
	if not _assert(save != null,"SaveManager autoload is missing"):return
	var original: Dictionary = save.data.duplicate(true)
	var test_state: Dictionary = original.duplicate(true)
	test_state["language_code"] = "yo"
	test_state["highest_level"] = 40
	test_state["coins"] = 421
	test_state["purchased_products"] = ["fixture-permanent-upgrade"]
	test_state["privacy_consent_status"] = "required"
	save.data = test_state
	save.reset_progress()
	var preserved: bool = String(save.data.get("language_code","")) == "yo" and int(save.data.get("coins",0)) == 421
	preserved = preserved and save.data.get("purchased_products",[]) == ["fixture-permanent-upgrade"]
	preserved = preserved and save.data.get("privacy_consent_status","") == "required"
	var reset := int(save.data.get("highest_level",0)) == 1
	save.data = original
	save.save()
	if not _assert(preserved and reset,"Reset lost chosen language, wallet, privacy state, purchased products, or failed to reset progression"):return
	var cloud := root.get_node_or_null("CloudSaveManager")
	if not _assert(cloud != null and cloud.CLOUD_KEYS.has("language_code"),"Cloud backup omits user-selected locale"):return
	print("RESET_LANGUAGE_PREFERENCE_OK: saved language and purchases survive reset and locale is included in backups.")
	quit(0)

func _assert(condition: bool, message: String) -> bool:
	if condition:return true
	push_error(message)
	quit(1)
	return false
