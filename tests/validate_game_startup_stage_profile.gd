extends SceneTree
# Headless CPU stage profiling for real gameplay scenes. Not a mobile GPU
# benchmark. Startup and resource/node ownership are measured separately.
const GAME_PATHS := [
	"res://scenes/Game.tscn",
	"res://scenes/WaterSort.tscn",
	"res://scenes/BlockPuzzle.tscn",
]
const REF = preload("res://scripts/ui/figma_reference_canvas.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	root.size = Vector2i(540,960)
	var base_memory_mib := _mem_mib()
	for path in GAME_PATHS:
		var t0 := Time.get_ticks_usec()
		var packed := load(path) as PackedScene
		var load_us := Time.get_ticks_usec() - t0
		if not _check(packed != null,"Missing gameplay scene: "+path):return
		# Isolate expensive first-time style creation from subsequent hot scene
		# instantiation, and sample memory AFTER detached scenes have freed.
		for iteration in range(2):
			var i_start := Time.get_ticks_usec()
			var game := packed.instantiate() as Control
			var instantiate_us := Time.get_ticks_usec() - i_start
			if not _check(game != null,"Could not instantiate "+path):return
			var add_start := Time.get_ticks_usec()
			root.add_child(game)
			var ready_us := Time.get_ticks_usec() - add_start
			var enter_mib := _mem_mib()
			print("STARTUP_STAGE scene=%s pass=%d load_us=%d instantiate_us=%d ready_us=%d static_mib=%.2f gradients=%d" % [
				path, iteration, load_us if iteration == 0 else 0,
				instantiate_us, ready_us, enter_mib,
				REF._rounded_gradient3_cache.size()])
			await _frames(3)
			root.remove_child(game)
			game.queue_free()
			await _frames(5)
	print("STARTUP_STAGE_SUMMARY baseline_static_mib=%.2f end_static_mib=%.2f gradient3_count=%d flat_gloss_count=%d" % [
		base_memory_mib,_mem_mib(),REF._rounded_gradient3_cache.size(),
		REF._flat_gloss_cache.size()])
	print("GAME_STARTUP_STAGE_PROFILE_OK")
	quit(0)

func _mem_mib() -> float:
	return float(Performance.get_monitor(Performance.MEMORY_STATIC)) / (1024.0*1024.0)

func _frames(count: int) -> void:
	for i in range(count): await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
