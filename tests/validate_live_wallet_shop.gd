extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	var save = root.get_node_or_null("SaveManager")
	expect_true(save != null, "SaveManager autoload missing")
	if save == null:
		_finish()
		return

	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(5)
	if main.has_method("_open_games_surface"):
		main.call("_open_games_surface")
	else:
		main.set("current_surface", "live")
	await _frames(5)

	var live := main.get_node_or_null("PremiumLive")
	expect_true(live != null and live.visible, "Choose Game Figma surface did not open")
	if live != null:
		var settings := live.find_child("SelectorSettingsButton", true, false) as Button
		var legacy_wallet := live.find_child("LiveCoinShopButton", true, false) as Button
		expect_true(settings != null and settings.visible, "Choose Game Figma Settings action is missing")
		expect_true(legacy_wallet == null, "Legacy coin wallet was injected into the audited Figma selector")

	main.queue_free()
	await _frames(2)
	_finish()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("LIVE_FIGMA_SELECTOR_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
