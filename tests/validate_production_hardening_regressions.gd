extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_canonical_motion_key(): return
	if not await _validate_active_game_monetization_identity(): return
	if not _validate_water_concurrent_action_safety(): return
	if not _validate_multi_game_retention_parity(): return
	if not _validate_rewarded_result_state(): return
	if not await _validate_shared_completion_overlay(): return
	if not await _validate_help_does_not_overlap_game_footer(): return
	if not await _validate_primary_visual_occupancy(): return
	if not _validate_visual_workflow_installs_plugins(): return
	if not _validate_main_ci_runs_new_hardening_gates(): return
	if not _validate_release_workflow_exists(): return
	if not _validate_retired_dead_code_removed(): return
	if not await _validate_audio_teardown_contract(): return
	print("Production hardening regressions validated")
	quit(0)

func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _validate_canonical_motion_key() -> bool:
	for path in [
		"res://scripts/ui/motion_director.gd",
		"res://scripts/ui/game_showcase_art.gd",
		"res://scripts/ui/premium_surface_manager_static.gd",
		"res://scripts/ui/premium_home_casual.gd",
		"res://scripts/systems/premium_visuals.gd"
	]:
		var source := _source(path)
		if not source.contains("MotionSystem.reduced()"):
			return _fail("%s does not use MotionSystem.reduced()" % path)
		if source.contains('SaveManager.data.get("reduced_motion"'):
			return _fail("%s still reads legacy reduced_motion directly" % path)
	var settings := _source("res://scripts/ui/premium_main_casual.gd")
	if settings.contains('SaveManager.data["reduced_motion"]'):
		return _fail("Settings still writes duplicate reduced_motion key")
	return true

func _validate_active_game_monetization_identity() -> bool:
	var cases := [
		["res://scenes/WaterSort.tscn", "water_sort"],
		["res://scenes/BlockPuzzle.tscn", "block_puzzle"]
	]
	for case_value in cases:
		var scene := load(String(case_value[0])) as PackedScene
		var game := scene.instantiate()
		root.add_child(game)
		await process_frame
		if not game.has_method("monetization_game_id"):
			game.queue_free(); await process_frame
			return _fail("Active scene %s has no monetization_game_id method" % case_value[0])
		if String(game.call("monetization_game_id")) != String(case_value[1]):
			game.queue_free(); await process_frame
			return _fail("Active scene %s reports wrong monetization game id" % case_value[0])
		game.queue_free()
		await process_frame
	var hub := _source("res://scripts/ui/monetization_hub.gd")
	if not hub.contains('node.has_method("monetization_game_id")'):
		return _fail("MonetizationHub still identifies active games by script filename")
	return true

func _validate_water_concurrent_action_safety() -> bool:
	var source := _source("res://scripts/game/water_sort_reference_motion.gd")
	for needle in ["func _has_active_pours", "func undo_move", "func restart_level", "func _quit", "_queued_action", "_run_queued_action_if_ready"]:
		if not source.contains(needle):
			return _fail("Water concurrent action safety missing: %s" % needle)
	return true


func _validate_multi_game_retention_parity() -> bool:
	var save := root.get_node_or_null("SaveManager")
	var multi := root.get_node_or_null("MultiGameManager")
	var retention := root.get_node_or_null("RetentionManager")
	if save == null or multi == null or retention == null:
		return _fail("Shared managers missing during retention parity test")
	var backup: Dictionary = (save.get("data") as Dictionary).duplicate(true)
	save.call("reset_progress")
	multi.call("ensure_state")
	retention.call("ensure_state")
	var data: Dictionary = save.get("data") as Dictionary
	var before_weekly := int(data.get("weekly_points", 0))
	multi.call("complete_level", "water_sort", 1, 3, 0)
	data = save.get("data") as Dictionary
	var water_weekly := int(data.get("weekly_points", 0))
	multi.call("complete_level", "block_puzzle", 1, 3, 0)
	data = save.get("data") as Dictionary
	var block_weekly := int(data.get("weekly_points", 0))
	save.set("data", backup)
	save.call("save")
	if water_weekly <= before_weekly:
		return _fail("Water Sort completion does not advance shared retention")
	if block_weekly <= water_weekly:
		return _fail("Block Puzzle level with same number is incorrectly deduplicated against Water Sort")
	return true

func _validate_rewarded_result_state() -> bool:
	var source := _source("res://scripts/game/game.gd")
	if not source.contains('"WATCHING AD…"'):
		return _fail("Rescue rewarded result button has no loading state")
	if not source.contains('"BASE REWARD DOUBLED"') or not source.contains("on_failed"):
		return _fail("Rescue rewarded result does not update from explicit success/failure callbacks")
	var ads := _source("res://scripts/systems/ad_manager.gd")
	if not ads.contains("on_failed: Callable"):
		return _fail("AdManager rewarded API has no failure callback")
	return true

func _validate_shared_completion_overlay() -> bool:
	var block_source := _source("res://scripts/game/block_puzzle_ultra_motion.gd")
	var rescue_source := _source("res://scripts/game/game.gd")
	var overlay_source := _source("res://scripts/ui/premium_result_overlay.gd")
	if not block_source.contains("PremiumResultOverlay.new()"):
		return _fail("Active Block Puzzle completion bypasses shared premium result overlay")
	if not rescue_source.contains("PremiumResultOverlay.new()"):
		return _fail("Rescue Rush completion bypasses shared premium result overlay")
	if not overlay_source.contains("signal secondary_requested") or not overlay_source.contains("func configure_secondary"):
		return _fail("Shared premium result overlay cannot host rewarded secondary actions")
	var overlay := PremiumResultOverlay.new()
	overlay.configure("TEST COMPLETE", "Shared presentation", "3 MOVES", 3, Color.WHITE, "CONTINUE")
	overlay.configure_secondary("DOUBLE REWARD", true)
	root.add_child(overlay)
	await process_frame
	var secondary := overlay.get_node_or_null("ResultCard/ResultMargin/ResultBox/SecondaryAction") as Button
	var ok := secondary != null and secondary.visible and secondary.text == "DOUBLE REWARD"
	overlay.queue_free()
	await process_frame
	if not ok:
		return _fail("Shared result overlay does not render its configured secondary action")
	return true

func _validate_help_does_not_overlap_game_footer() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	for game_id in ["water_sort", "block_puzzle"]:
		main.call("start_multi_level", game_id, 1, false)
		await _frames(10)
		var shell := main.get_node_or_null("UXShell")
		var help = shell.get("help_button") if shell != null else null
		var game := main.get_node_or_null("ActiveGame")
		if help == null or game == null:
			main.queue_free(); await process_frame
			return _fail("Missing gameplay help or active game")
		var footer := _first_named_control(game, ["CompactGameActions", "CompactProgressStrip"])
		if footer != null and help.get_global_rect().intersects(footer.get_global_rect()):
			main.queue_free(); await process_frame
			return _fail("Help button overlaps %s footer" % game_id)
		main.call("build_home")
		await _frames(5)
	main.queue_free()
	await process_frame
	return true

func _first_named_control(node: Node, names: Array[String]) -> Control:
	if node is Control and String(node.name) in names:
		return node as Control
	for child in node.get_children():
		var found := _first_named_control(child, names)
		if found != null:
			return found
	return null

func _validate_primary_visual_occupancy() -> bool:
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)
	main.call("build_home")
	await _frames(6)
	var showcase := main.find_child("HomeShowcaseArt", true, false) as Control
	if showcase == null or showcase.size.x < 800.0 or showcase.size.y < 500.0:
		main.queue_free(); await process_frame
		return _fail("Home showcase does not occupy enough of the cinematic hero on 1080x1920")
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(10)
	var game := main.get_node_or_null("ActiveGame")
	var board = game.get("board") if game != null else null
	if board == null or board.get_child_count() < 1:
		main.queue_free(); await process_frame
		return _fail("Water Sort board missing during visual occupancy check")
	var tube := board.get_child(0) as Control
	if tube == null or tube.size.x < 205.0 or tube.size.y < 400.0:
		main.queue_free(); await process_frame
		return _fail("Water Sort bottles remain undersized on 1080x1920")
	main.queue_free()
	await process_frame
	return true

func _validate_visual_workflow_installs_plugins() -> bool:
	var source := _source("res://.github/workflows/visual-audit.yml")
	if not source.contains("tools/install_monetization_plugins.sh"):
		return _fail("Visual audit workflow imports the project without monetization plugins")
	return true


func _validate_main_ci_runs_new_hardening_gates() -> bool:
	var source := _source("res://.github/workflows/godot-ci.yml")
	for needle in ["validate_production_hardening_regressions", "validate_water_constructive_solvability", "ObjectDB instances were leaked"]:
		if not source.contains(needle):
			return _fail("Main CI is missing production hardening gate: %s" % needle)
	return true

func _validate_release_workflow_exists() -> bool:
	var source := _source("res://.github/workflows/android-release.yml")
	if source.is_empty() or not source.contains("--export-release") or not source.contains("workflow_dispatch"):
		return _fail("Protected Android release workflow is missing")
	if not source.contains("version_code:") or not source.contains("VERSION_CODE"):
		return _fail("Release workflow does not require an explicit monotonic Play version code")
	if not source.contains('VERSION_CODE: ${{ inputs.version_code }}'):
		return _fail("Release workflow does not pass the requested Play version code into its configuration step")
	if source.contains("GITHUB_RUN_NUMBER"):
		return _fail("Release workflow still derives Play version code from workflow run number")
	if source.contains("STORE_PASSWORD") or source.contains("GODOT_ANDROID_KEYSTORE_RELEASE_STORE_PASSWORD"):
		return _fail("Release workflow uses an unsupported separate Android keystore store-password path")
	if not source.contains("validate_water_constructive_solvability"):
		return _fail("Release workflow skips the full Water Sort solvability gate")
	if not source.contains("keytool -list"):
		return _fail("Release workflow does not validate the keystore alias/password before export")
	return true

func _validate_retired_dead_code_removed() -> bool:
	if FileAccess.file_exists("res://scripts/ui/water_sort_reference_backdrop.gd"):
		return _fail("Retired Water Sort reference backdrop is still shipped")
	return true

func _validate_audio_teardown_contract() -> bool:
	var feedback := root.get_node_or_null("FeedbackManager")
	if feedback == null or not feedback.has_method("shutdown_audio"):
		return _fail("FeedbackManager has no explicit audio teardown for deterministic visual/test shutdown")
	feedback.call("shutdown_audio")
	await process_frame
	var player = feedback.get("player")
	var music_player = feedback.get("music_player")
	if player != null and player.get("stream") != null:
		return _fail("FeedbackManager sound player retains a stream after shutdown")
	if music_player != null and music_player.get("stream") != null:
		return _fail("FeedbackManager music player retains a stream after shutdown")
	var capture := _source("res://tests/capture_visual_audit.gd")
	if not capture.contains('feedback.call("shutdown_audio")'):
		return _fail("Visual audit does not explicitly release generated audio before quitting")
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
