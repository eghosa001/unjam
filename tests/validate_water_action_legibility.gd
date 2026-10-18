extends SceneTree

# Screenshot/player feedback: Water Sort bottom actions were 12px at 390x844,
# despite having 60px-high touch targets. Legible controls are a benchmark gate.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene unavailable")
	for level in [1, 10000]:
		var game := packed.instantiate() as Control
		game.set("level_number",level)
		root.add_child(game)
		await _frames(7)
		var actions := ["WaterUndoAction","WaterHintAction","AddTubeAction"]
		for name in actions:
			var button := game.find_child(name,true,false) as Button
			if button == null:
				return _fail("%s is missing on level %d" % [name,level])
			if button.get_theme_font_size("font_size") < 15:
				return _fail("%s still uses tiny text: %d" % [name,button.get_theme_font_size("font_size")])
			if button.size.y < 58 or button.size.x < 100:
				return _fail("%s touch target is too small" % name)
			if button.tooltip_text.is_empty() and button.accessibility_name.is_empty():
				return _fail("%s has no accessible affordance" % name)
		var purchase := game.find_child("AddTubeAction",true,false) as Button
		if not purchase.text.contains("\n") or not purchase.text.contains("75"):
			return _fail("The extra tube must show its real price on a readable second line")
		game.set("extra_tube_used",true)
		game.call("_refresh_extra_tube_button")
		if not purchase.disabled or not purchase.text.contains("USED"):
			return _fail("A purchased extra tube must be clearly disabled and named")
		game.queue_free()
		await _frames(3)
	print("WATER_ACTION_LEGIBILITY_OK")
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
