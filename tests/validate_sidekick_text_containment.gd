extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		return _fail("Main scene failed to load")
	var main := scene.instantiate()
	root.add_child(main)
	await _frames(3)
	main.call("show_playmate_sidekick", "water_sort")
	await _frames(3)

	var card := main.find_child("SidekickTipCard", true, false) as Control
	var tip := main.find_child("SidekickTip", true, false) as Label
	if card == null or tip == null:
		return _fail("Sidekick tip UI missing")
	if tip.position.x < card.position.x or tip.position.x + tip.size.x > card.position.x + card.size.x:
		return _fail("Sidekick tip control exceeds card width")
	if tip.position.y < card.position.y or tip.position.y + tip.size.y > card.position.y + card.size.y:
		return _fail("Sidekick tip control exceeds card height")

	var font := tip.get_theme_font("font")
	var font_size := tip.get_theme_font_size("font_size")
	if font == null:
		return _fail("Sidekick tip font missing")
	for line in tip.text.split("\n", false):
		var width := font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if width > tip.size.x + 0.5:
			return _fail("Sidekick tip rendered line exceeds its text box: %s" % String(line))

	if "Finish one colour before opening too many new tubes." == tip.text:
		return _fail("Sidekick test phrase was not wrapped")

	print("SIDEKICK_TEXT_CONTAINMENT_OK")
	main.queue_free()
	await process_frame
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
