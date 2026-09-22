extends SceneTree

const ReferenceTube = preload("res://scripts/ui/water_tube_reference_button.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var palette: Array = ReferenceTube.PALETTE
	if palette.size() != 12:
		failures.append("Water Sort late-game palette must expose exactly 12 distinct colours")

	var minimum_distance := 999.0
	for i in range(palette.size()):
		var a: Color = palette[i]
		for j in range(i + 1, palette.size()):
			var b: Color = palette[j]
			var dr := a.r - b.r
			var dg := a.g - b.g
			var db := a.b - b.b
			var distance := sqrt(dr * dr + dg * dg + db * db)
			minimum_distance = minf(minimum_distance, distance)
			if distance < 0.34:
				failures.append("Water colours %d and %d are too similar for dense late-level play (RGB distance %.3f; minimum 0.34)" % [i, j, distance])

	var motion_source := _read("res://scripts/ui/water_tube_3d_motion.gd")
	for token in [
		"func _draw_liquid_identity_markers()",
		"var shape := color_index % 4",
		"var count := int(color_index / 4) + 1",
		"func _draw_identity_marker",
	]:
		if not motion_source.contains(token):
			failures.append("Water liquid secondary identity cue is missing: %s" % token)

	var reference_source := _read("res://scripts/ui/water_tube_reference_button.gd")
	var legacy_source := _read("res://scripts/ui/water_tube_button.gd")
	var gameplay_source := _read("res://scripts/game/water_sort.gd")
	for token in [
		"Color(\"c62828\")", "Color(\"1e5eff\")", "Color(\"ffd400\")",
		"Color(\"00a86b\")", "Color(\"a100f2\")", "Color(\"ff7a00\")",
		"Color(\"00b8d9\")", "Color(\"e0008a\")", "Color(\"263238\")",
		"Color(\"8bc34a\")", "Color(\"795548\")", "Color(\"b2f0e8\")",
	]:
		if not reference_source.contains(token) or not legacy_source.contains(token) or not gameplay_source.contains(token):
			failures.append("Water bottle/stream renderers disagree on accessible palette token: %s" % token)
	for token in [
		"func _liquid_material_3d(color: Color)",
		"material.roughness = 0.22",
		"material.clearcoat = 0.24",
		"material.emission_energy_multiplier = 0.075",
	]:
		if not motion_source.contains(token):
			failures.append("Water liquid anti-wash material contract is missing: %s" % token)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("WATER_PALETTE_ACCESSIBILITY_OK minimum_rgb_distance=%.3f" % minimum_distance)
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
