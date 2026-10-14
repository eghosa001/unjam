extends SceneTree

const Copy = preload("res://scripts/systems/tutorial_text.gd")
const GAMES := ["rescue_rush","water_sort","block_puzzle"]
const LANGUAGES := ["en","es","fr","pt","de","it","ha","yo","ig"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var l10n := root.get_node("LocalizationManager")
	var before := String(l10n.language_code)
	var keys: Array = Copy.KEYS
	var en: Array = Copy.COPY["en"]
	for language in LANGUAGES:
		var values: Array = Copy.COPY.get(language,[])
		if values.size() != keys.size():
			return _fail("Incomplete onboarding language: " + language)
		l10n.set_language(language,false)
		for i in range(keys.size()):
			var translated := Copy.translated(String(keys[i]))
			if translated.is_empty() or translated == String(keys[i]):
				return _fail("Missing localized tutorial copy: %s/%s" % [language,keys[i]])
			if language != "en" and i in [0,4,8,12,13,14,15] and translated == String(en[i]):
				return _fail("English-only core instruction: %s/%s" % [language,keys[i]])
	# Actual tutorial controllers must display local language on entry,
	# including new gesture feedback, not merely contain unused dictionaries.
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var shell := main.get_node_or_null("UXShell")
	for language in LANGUAGES:
		l10n.set_language(language,false)
		for game in GAMES:
			shell.call("show_tutorial",game)
			await process_frame
			var intro := shell.get("tutorial_body") as Label
			var expected := Copy.translated("%s_intro" % ("rescue" if game == "rescue_rush" else ("water" if game == "water_sort" else "block")))
			if intro == null or intro.text != expected:
				return _fail("Tutorial does not render language %s for %s" % [language,game])
			var gesture := shell.find_child("TutorialGesturePractice",true,false) as Control
			if gesture == null:
				return _fail("Localized tutorial has no practice control for %s" % game)
			if not gesture.accessibility_name.contains(Copy.translated("practice_%s" % ("rescue" if game == "rescue_rush" else ("water" if game == "water_sort" else "block")))):
				return _fail("Localized practice accessibility caption is missing")
			shell.call("hide_tutorial")
	l10n.set_language(before,false)
	main.queue_free()
	await process_frame
	print("NINE_LANGUAGE_ONBOARDING_OK: 23 localized copy slots in 9 languages, live tutorials")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
