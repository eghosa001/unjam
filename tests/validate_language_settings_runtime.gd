extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var previous_code := String(SaveManager.data.get("language_code", ""))
	LocalizationManager.set_language("en", false)
	var label := Label.new()
	label.text = "LEVEL 25"
	label.add_theme_font_size_override("font_size", 16)
	root.add_child(label)
	var button := Button.new()
	button.text = "NEXT TIP"
	button.accessibility_name = "NEXT TIP"
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size = Vector2(180, 48)
	root.add_child(button)
	LocalizationManager.set_language("es", false)
	if not _assert(label.text == "NIVEL 25" and button.text == "OTRO CONSEJO", "Spanish switch failed"):
		return
	if not _assert(button.accessibility_name == "OTRO CONSEJO", "Accessibility name still speaks English"):
		return
	LocalizationManager.set_language("fr", false)
	if not _assert(label.text == "NIVEAU 25" and button.text == "AUTRE CONSEIL", "Second language switch kept the first language"):
		return
	LocalizationManager.set_language("en", false)
	if not _assert(label.text == "LEVEL 25" and button.text == "NEXT TIP", "Switching back to English did not restore originals"):
		return
	if not _assert(button.accessibility_name == "NEXT TIP" and label.get_theme_font_size("font_size") == 16, "Language switch left stale accessibility or font size"):
		return
	# Check that dynamically updated authored text becomes the new translation
	# source rather than reverting to an old label after the next switch.
	label.text = "NEXT TIP"
	LocalizationManager.set_language("es", false)
	if not _assert(label.text == "OTRO CONSEJO", "Dynamic text cannot be translated"):
		return
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	for _i in range(5):
		await process_frame
	LocalizationManager.set_language("en", false)
	main.call("build_settings")
	for _i in range(3):
		await process_frame
	var language_button := main.find_child("SettingsLanguageToggle", true, false) as Button
	if not _assert(language_button != null, "Settings lacks a language selector"):
		return
	if not _assert(language_button.size.x >= 140.0 and language_button.size.y >= 44.0, "Language button is too small"):
		return
	main.call("_cycle_settings_language")
	for _i in range(3):
		await process_frame
	var translated_button := main.find_child("SettingsLanguageToggle", true, false) as Button
	if not _assert(LocalizationManager.language_code == "es", "Language control did not switch to Spanish"):
		return
	if not _assert(SaveManager.data.get("language_code", "") == "es", "Language preference was not saved"):
		return
	if not _assert(translated_button != null and translated_button.text.contains("ES"), "Settings label did not show chosen locale"):
		return
	main.queue_free()
	label.queue_free()
	button.queue_free()
	await process_frame
	LocalizationManager.set_language("en", false)
	if previous_code.is_empty():
		SaveManager.data.erase("language_code")
	else:
		SaveManager.data["language_code"] = previous_code
	SaveManager.save()
	print("LANGUAGE_SETTINGS_RUNTIME_OK: reversible localization, screen reader label, persisted settings selection")
	quit(0)

func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
