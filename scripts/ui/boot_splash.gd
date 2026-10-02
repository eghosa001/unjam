extends Control

const HOLD_SECONDS := 1.55
const FADE_SECONDS := 0.25
const MAIN_SCENE := "res://scenes/Main.tscn"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Let autoloads/global classes settle before parsing the main scene on a
	# background thread. The splash hold already gives this preload ample time.
	call_deferred("_prime_main_scene")
	var timer := get_tree().create_timer(HOLD_SECONDS, true, false, true)
	await timer.timeout
	if not is_inside_tree():
		return
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	await fade.finished
	if is_inside_tree():
		_open_main()

func _open_main() -> void:
	var status := ResourceLoader.load_threaded_get_status(MAIN_SCENE)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
		if packed != null:
			get_tree().change_scene_to_packed(packed)
			return
	get_tree().change_scene_to_file(MAIN_SCENE)


func _prime_main_scene() -> void:
	for _i in range(2):
		await get_tree().process_frame
	if is_inside_tree():
		ResourceLoader.load_threaded_request(MAIN_SCENE)
