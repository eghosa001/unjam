extends SceneTree

func _initialize() -> void:
    var failures: Array[String] = []
    var project := FileAccess.get_file_as_string("res://project.godot")
    var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
    var main := load("res://assets/icon_user_512.png") as Texture2D
    var adaptive := load("res://assets/icon_user_adaptive_432.png") as Texture2D

    if main == null or main.get_width() != 512 or main.get_height() != 512:
        failures.append("Main launcher icon must be a crisp 512x512 PNG")
    if adaptive == null or adaptive.get_width() != 432 or adaptive.get_height() != 432:
        failures.append("Adaptive launcher foreground must be 432x432")
    if 'config/icon="res://assets/icon_user_512.png"' not in project:
        failures.append("project.godot is not wired to the supplied glossy U icon")
    for token in [
        'launcher_icons/main_192x192="res://assets/icon_user_512.png"',
        'launcher_icons/adaptive_foreground_432x432="res://assets/icon_user_adaptive_432.png"',
        'launcher_icons/adaptive_background_432x432="res://assets/icon_adaptive_background.svg"',
    ]:
        if token not in preset:
            failures.append("Android launcher preset missing: %s" % token)

    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    print("Launcher icon PNG wiring validated.")
    quit(0)
