extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var icon_source := _read("res://assets/icon.svg")
	var adaptive_source := _read("res://assets/icon_adaptive_foreground.svg")
	var export_cfg := _read("res://export_presets.cfg")

	if icon_source.is_empty():
		failures.append("Launcher icon source is missing")
	else:
		if not icon_source.contains("data:image/png;base64,"):
			failures.append("Launcher icon must embed the approved user-supplied artwork")
		if icon_source.contains("feGaussianBlur"):
			failures.append("Launcher icon must not reintroduce blur filters")

	if adaptive_source.is_empty():
		failures.append("Adaptive launcher foreground source is missing")
	else:
		if not adaptive_source.contains("data:image/png;base64,"):
			failures.append("Adaptive launcher must embed the approved user-supplied artwork")
		if not adaptive_source.contains("x=\"32\"") or not adaptive_source.contains("y=\"32\"") or not adaptive_source.contains("width=\"368\"") or not adaptive_source.contains("height=\"368\""):
			failures.append("Adaptive launcher artwork must stay inside the Samsung/Android safe zone")
		if adaptive_source.contains("feGaussianBlur"):
			failures.append("Adaptive launcher icon must not reintroduce blur filters")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon.svg\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_adaptive_foreground.svg\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher export contract missing: %s" % token)

	var icon_texture := load("res://assets/icon.svg") as Texture2D
	if icon_texture == null:
		failures.append("Launcher icon failed to rasterize")
	else:
		var image := icon_texture.get_image()
		if image.get_width() != 512 or image.get_height() != 512:
			failures.append("Launcher icon must rasterize to 512x512")

	var adaptive_texture := load("res://assets/icon_adaptive_foreground.svg") as Texture2D
	if adaptive_texture == null:
		failures.append("Adaptive launcher foreground failed to rasterize")
	else:
		var image := adaptive_texture.get_image()
		if image.get_width() != 432 or image.get_height() != 432:
			failures.append("Adaptive launcher foreground must rasterize to 432x432")
		else:
			var min_x := image.get_width()
			var min_y := image.get_height()
			var max_x := -1
			var max_y := -1
			var alpha_sum := 0.0
			var weighted_x := 0.0
			var weighted_y := 0.0
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					var alpha := image.get_pixel(x, y).a
					if alpha <= 0.04:
						continue
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x)
					max_y = maxi(max_y, y)
					weighted_x += float(x) * alpha
					weighted_y += float(y) * alpha
					alpha_sum += alpha
			if alpha_sum <= 0.0:
				failures.append("Adaptive launcher foreground raster is empty")
			else:
				var center := Vector2(weighted_x / alpha_sum, weighted_y / alpha_sum)
				var target := Vector2(image.get_width() - 1, image.get_height() - 1) * 0.5
				var tolerance := float(mini(image.get_width(), image.get_height())) * 0.04
				if center.distance_to(target) > tolerance:
					failures.append("Adaptive launcher foreground is not optically centered: %s vs %s" % [center, target])
				var safe_margin := 30
				if min_x < safe_margin or min_y < safe_margin or max_x > image.get_width() - 1 - safe_margin or max_y > image.get_height() - 1 - safe_margin:
					failures.append("Adaptive launcher foreground exceeds the approved visual safe margin")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("LAUNCHER_ICON_SAFE_ZONE_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
