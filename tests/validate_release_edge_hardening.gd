extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_single_navigation_feedback()
	_check_network_response_decoding()
	_check_compact_quick_switch_label()
	await _check_day_rollover_refresh()
	if failures.is_empty():
		print("RELEASE_EDGE_HARDENING_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_single_navigation_feedback() -> void:
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var main := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var home_block := _function_block(home, "_open_game_selector")
	var destination_block := _function_block(main, "_open_games_surface")
	_check(not home_block.contains("FeedbackManager.tap()"), "Home Choose Game still pre-plays duplicate feedback")
	_check(destination_block.count("FeedbackManager.tap()") == 1, "Games destination must own exactly one navigation tap")

func _check_network_response_decoding() -> void:
	_check_quiet_decoder(root.get_node_or_null("PurchaseVerifier"), "PurchaseVerifier")
	_check_quiet_decoder(root.get_node_or_null("CloudSaveManager"), "CloudSaveManager")

func _check_quiet_decoder(node: Node, label: String) -> void:
	_check(node != null, "%s autoload missing" % label)
	if node == null:
		return
	var empty: Dictionary = node.call("_decode_response_json", PackedByteArray())
	var malformed: Dictionary = node.call("_decode_response_json", "{".to_utf8_buffer())
	var valid: Dictionary = node.call("_decode_response_json", "{\"ok\":true,\"reason\":\"verified\"}".to_utf8_buffer())
	_check(empty.is_empty() and malformed.is_empty(), "%s decoder must fail quietly on empty/malformed bodies" % label)
	_check(bool(valid.get("ok", false)) and String(valid.get("reason", "")) == "verified", "%s decoder rejected valid JSON" % label)

func _check_compact_quick_switch_label() -> void:
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	_check('switch_font := 11 if id == "block_puzzle" else 12' in home, "Block Puzzle Quick Switch label is not compact-phone tuned")
	_check('Rect2(x + 2, 504, 104, 19)' in home and '"HomeQuickSwitchName_%s"' in home, "Quick Switch label containment contract is missing")

func _check_day_rollover_refresh() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	_check(packed != null, "Main scene missing")
	if packed == null:
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	current_scene = main
	await _frames(5)
	main.set("_last_calendar_day", "2099-01-01")
	main.call("build_home")
	await _frames(3)
	var before = main.get("content")
	var before_id := (before as Object).get_instance_id()
	main.call("_refresh_day_sensitive_surface", "2099-01-02")
	await _frames(5)
	var after = main.get("content")
	_check(String(main.get("_last_calendar_day")) == "2099-01-02", "Calendar-day marker did not advance")
	_check((after as Object).get_instance_id() != before_id, "Home did not refresh after a calendar-day rollover")
	var stable_id := (after as Object).get_instance_id()
	main.call("_refresh_day_sensitive_surface", "2099-01-02")
	await _frames(3)
	_check((main.get("content") as Object).get_instance_id() == stable_id, "Same-day resume rebuilt Home unnecessarily")
	main.queue_free()
	await process_frame

func _function_block(source: String, name: String) -> String:
	var start := source.find("func %s(" % name)
	if start < 0:
		return ""
	var finish := source.find("\nfunc ", start + 1)
	return source.substr(start) if finish < 0 else source.substr(start, finish - start)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
