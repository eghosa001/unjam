extends SceneTree

const LocalizationScript = preload("res://scripts/systems/localization_manager.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := LocalizationScript.new()
	manager.language_code = "es"
	var cases := {
		"INCOMPLETE": "INCOMPLETE",
		"LEVELSHIFT": "LEVELSHIFT",
		"RECOMPLETE": "RECOMPLETE",
		"LEVEL 25": "NIVEL 25",
		"LEVELS 25": "NIVELES 25",
		"LEVEL, LEVEL": "NIVEL, NIVEL",
		"NEXT TIP": "OTRO CONSEJO",
		"LEVEL! NEXT": "NIVEL! SIGUIENTE"
	}
	for original in cases.keys():
		var actual: String = manager.localize(String(original))
		if actual != String(cases[original]):
			manager.free()
			push_error("Broken Spanish localization for %s: %s" % [original, actual])
			quit(1)
			return
	for language in LocalizationScript.SUPPORTED_LANGUAGES:
		manager.language_code = String(language)
		if manager.localize("INCOMPLETE") != "INCOMPLETE" or manager.localize("LEVELSHIFT") != "LEVELSHIFT":
			manager.free()
			push_error("A token was replaced inside another word in language: " + String(language))
			quit(1)
			return
	manager.free()
	print("LOCALIZATION_INTEGRITY_OK: all locales protect whole words and Spanish dynamic labels translate correctly.")
	quit(0)
