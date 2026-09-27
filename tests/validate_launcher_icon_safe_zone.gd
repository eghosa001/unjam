extends SceneTree

const SPLASH_BG := "Color(0.701961, 0.67451, 0.635294, 1)"

func _initialize() -> void:
	var failures: Array[String] = []
	var export_cfg := _read("res://export_presets.cfg")
	var project_cfg := _read("res://project.godot")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon_user_512.png\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_user_adaptive_432.png\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
		"splash_screen/icon=\"res://assets/boot_mark.png\"",
		"splash_screen/background_color=%s" % SPLASH_BG,
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher/splash export contract missing: %s" % token)

	for token in [
		"config/icon=\"res://assets/icon_user_512.png\"",
		"boot_splash/image=\"res://assets/boot_mark.png\"",
		"boot_splash/bg_color=%s" % SPLASH_BG,
	]:
		if not project_cfg.contains(token):
			failures.append("Godot launcher/splash contract missing: %s" % token)

	_check_size("res://assets/icon_user_512.png", Vector2i(512, 512), "Launcher icon", failures)
	_check_adaptive_foreground(failures)
	_check_boot_mark(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_AND_SPLASH_SAFE_ZONE_OK")
	quit(0)

func _check_size(path: String, expected: Vector2i, label: String, failures: Array[String]) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		failures.append("%s failed to load" % label)
		return
	var image := texture.get_image()
	if Vector2i(image.get_width(), image.get_height()) != expected:
		failures.append("%s must be %dx%d" % [label, expected.x, expected.y])

func _check_adaptive_foreground(failures: Array[String]) -> void:
	var texture := load("res://assets/icon_user_adaptive_432.png") as Texture2D
	if texture == null:
		failures.append("Adaptive launcher foreground failed to load")
		return
	var image := texture.get_image()
	if image.get_width() != 432 or image.get_height() != 432:
		failures.append("Adaptive launcher foreground must be 432x432")
		return
	var bounds := _alpha_bounds(image)
	if int(bounds.get("count", 0)) == 0:
		failures.append("Adaptive launcher foreground raster is empty")
		return
	var center: Vector2 = bounds.get("center", Vector2.ZERO)
	var target := Vector2(215.5, 215.5)
	# Adaptive foreground layers may extend to the source edge because Android
	# applies the device mask/inset. Protect the meaningful requirement here:
	# the supplied foreground stays optically centered and correctly sized.
	if center.distance_to(target) > 24.0:
		failures.append("Adaptive launcher foreground is not optically centered: %s" % center)

func _check_boot_mark(failures: Array[String]) -> void:
	var texture := load("res://assets/boot_mark.png") as Texture2D
	if texture == null:
		failures.append("Transparent boot mark failed to load")
		return
	var image := texture.get_image()
	if image.get_width() != 432 or image.get_height() != 432:
		failures.append("Boot mark must be 432x432")
		return
	for point in [Vector2i(0, 0), Vector2i(431, 0), Vector2i(0, 431), Vector2i(431, 431)]:
		if image.get_pixelv(point).a > 0.01:
			failures.append("Boot mark has an opaque corner and will look like a pasted square")
			break
	var bounds := _alpha_bounds(image)
	if int(bounds.get("count", 0)) == 0:
		failures.append("Boot mark raster is empty")
		return
	var min_pos: Vector2i = bounds.get("min", Vector2i.ZERO)
	var max_pos: Vector2i = bounds.get("max", Vector2i.ZERO)
	var clear_margin := 56
	if min_pos.x < clear_margin or min_pos.y < clear_margin or max_pos.x > 431 - clear_margin or max_pos.y > 431 - clear_margin:
		failures.append("Boot mark needs clearer margins to blend into the splash background")

func _alpha_bounds(image: Image) -> Dictionary:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	var alpha_sum := 0.0
	var weighted_x := 0.0
	var weighted_y := 0.0
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			if alpha <= 0.04:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
			alpha_sum += alpha
			weighted_x += float(x) * alpha
			weighted_y += float(y) * alpha
			count += 1
	return {
		"count": count,
		"min": Vector2i(min_x, min_y),
		"max": Vector2i(max_x, max_y),
		"center": Vector2(weighted_x / alpha_sum, weighted_y / alpha_sum) if alpha_sum > 0.0 else Vector2.ZERO,
	}

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
