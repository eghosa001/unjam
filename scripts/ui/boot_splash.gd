extends Control

const HOLD_SECONDS := 1.55
const FADE_SECONDS := 0.25
const MAIN_SCENE := "res://scenes/Main.tscn"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# A single deterministic scene transition is more reliable than parsing the
	# same scene early on a background loader while startup classes initialize.
	get_tree().change_scene_to_file(MAIN_SCENE)
