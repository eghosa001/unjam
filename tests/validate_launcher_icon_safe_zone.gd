extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var icon := _read("res://assets/icon.svg")
	var adaptive := _read("res://assets/icon_adaptive_foreground.svg")
	var export_cfg := _read("res://export_presets.cfg")

	if icon.is_empty():
		failures.append("Legacy launcher icon source is missing")
	else:
		if not icon.contains("LauncherSafeForeground"):
			failures.append("Legacy launcher foreground safe-zone wrapper is missing")
		if not icon.contains("stroke-width=\"94\""):
			failures.append("Legacy launcher foreground is not using the approved large readable U stroke")
		if not icon.contains("scale(0.86)"):
			failures.append("Legacy launcher foreground must use the approved uniform safe-zone scale")
		if icon.contains(">UNJAM<"):
			failures.append("Launcher icon must remain symbol-only without app-name text")

	if adaptive.is_empty():
		failures.append("Adaptive launcher foreground source is missing")
	else:
		if not adaptive.contains("AdaptiveSafeZone"):
			failures.append("Adaptive launcher safe-zone group is missing")
		if not adaptive.contains("stroke-width=\"74\""):
			failures.append("Adaptive launcher foreground is not using the approved large readable U stroke")
		if not adaptive.contains("scale(0.70)"):
			failures.append("Adaptive launcher foreground must use the approved Samsung-safe uniform scale")
		if adaptive.contains(">UNJAM<"):
			failures.append("Adaptive launcher foreground must remain symbol-only")

	for token in [
		"launcher_icons/main_192x192=\"res://assets/icon.svg\"",
		"launcher_icons/adaptive_foreground_432x432=\"res://assets/icon_adaptive_foreground.svg\"",
		"launcher_icons/adaptive_background_432x432=\"res://assets/icon_adaptive_background.svg\"",
	]:
		if not export_cfg.contains(token):
			failures.append("Android launcher export contract missing: %s" % token)

	var texture := load("res://assets/icon_adaptive_foreground.svg") as Texture2D
	if texture == null:
		failures.append("Adaptive launcher foreground failed to rasterize")
	else:
		var image := texture.get_image()
		var min_x := image.get_width()
		var min_y := image.get_height()
		var max_x := -1
		var max_y := -1
		var weighted_x := 0.0
		var weighted_y := 0.0
		var alpha_sum := 0.0
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
			var tolerance := float(mini(image.get_width(), image.get_height())) * 0.065
			if center.distance_to(target) > tolerance:
				failures.append("Adaptive launcher foreground is not optically centered: %s vs %s" % [center, target])
			var safe_margin := int(round(float(mini(image.get_width(), image.get_height())) * 0.075))
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
