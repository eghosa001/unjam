extends Control
class_name GardenUpgradePreview

var item_id := ""
var owned := false
var upgrade_level := 0

func configure(value: String, level: int) -> void:
	item_id = value
	upgrade_level = clampi(level, 0, 5)
	owned = upgrade_level > 0
	# Paint real progression tiers without introducing six animated viewports or
	# frame callbacks in the scrollable Garden shop.
	tooltip_text = "%s: upgrade level %d of 5" % [value.replace("_", " ").capitalize(), upgrade_level]
	accessibility_name = tooltip_text
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var accent := Color("#22b86b") if owned else Color("#7a57e0")
	var ink := Color("#234259")
	var soft := Color("#dff5e9") if owned else Color("#eee8ff")
	draw_circle(size * 0.5, minf(size.x, size.y) * 0.46, Color(soft, 0.96))
	match item_id:
		"tree":
			_draw_tree(accent, ink)
		"bench":
			_draw_bench(accent, ink)
		"fountain":
			_draw_fountain(accent, ink)
		"lanterns":
			_draw_lanterns(accent, ink)
		"cottage":
			_draw_cottage(accent, ink)
		"rainbow_bridge":
			_draw_bridge(accent, ink)
		_:
			draw_circle(size * 0.5, 10.0, accent)
	# Up to five tiny golden tier marks provide a consistent upgrade cue.
	# They live inside the existing 38×50 preview geometry.
	if upgrade_level > 0:
		var spacing := 5.0
		var first_x := (size.x - float(upgrade_level - 1) * spacing) * 0.5
		for i in range(upgrade_level):
			draw_circle(Vector2(first_x + float(i) * spacing, size.y - 3.0), 1.65, Color("#e7b845"))
	if upgrade_level >= 5:
		draw_arc(size * 0.5, minf(size.x, size.y) * 0.445, 0.0, TAU, 20, Color("#f9ce61", 0.95), 1.6, true)

func _draw_tree(accent: Color, ink: Color) -> void:
	var c := size * 0.5
	draw_rect(Rect2(c + Vector2(-3, 6), Vector2(6, 15)), Color("#855b37"))
	draw_circle(c + Vector2(-9, 1), 11, accent.darkened(0.08))
	draw_circle(c + Vector2(7, -2), 12, accent)
	draw_circle(c + Vector2(0, -11), 11, accent.lightened(0.12))
	if upgrade_level >= 2:
		draw_circle(c + Vector2(-7, -10), 3, Color("#b0f7ad"))
	if upgrade_level >= 3:
		draw_circle(c + Vector2(8, -12), 3, Color("#fce39a"))
	if upgrade_level >= 4:
		draw_circle(c + Vector2(-3, 0), 3, Color("#f79b88"))
	draw_line(c + Vector2(-12, 21), c + Vector2(13, 21), Color(ink, 0.35), 2.0, true)

func _draw_bench(accent: Color, ink: Color) -> void:
	var c := size * 0.5
	draw_rect(Rect2(c + Vector2(-17, -7), Vector2(34, 7)), accent)
	draw_rect(Rect2(c + Vector2(-17, 3), Vector2(34, 6)), accent.darkened(0.10))
	draw_line(c + Vector2(-13, 9), c + Vector2(-13, 20), ink, 3.0, true)
	draw_line(c + Vector2(13, 9), c + Vector2(13, 20), ink, 3.0, true)
	draw_line(c + Vector2(-17, 0), c + Vector2(-17, -13), ink, 2.0, true)
	draw_line(c + Vector2(17, 0), c + Vector2(17, -13), ink, 2.0, true)
	if upgrade_level >= 2:
		draw_rect(Rect2(c + Vector2(-10, 3), Vector2(20, 3)), Color("#efd481"))
	if upgrade_level >= 4:
		draw_circle(c + Vector2(0, -12), 3.0, Color("#f8d86b"))

func _draw_fountain(accent: Color, ink: Color) -> void:
	var c := size * 0.5
	draw_arc(c + Vector2(0, 10), 17, 0.0, PI, 28, ink, 3.0, true)
	draw_rect(Rect2(c + Vector2(-3, -2), Vector2(6, 18)), accent.darkened(0.12))
	draw_circle(c + Vector2(0, -4), 6, accent)
	draw_arc(c + Vector2(0, -4), 15, PI * 0.20, PI * 0.80, 24, Color("#36bff5"), 2.5, true)
	draw_line(c + Vector2(0, -10), c + Vector2(0, -22), Color("#36bff5"), 2.5, true)
	if upgrade_level >= 2:
		draw_arc(c + Vector2(0, -4), 13, PI * 0.12, PI * 0.88, 18, Color("#83efff"), 1.5, true)
	if upgrade_level >= 4:
		draw_circle(c + Vector2(0, -21), 3, Color("#f9da76"))

func _draw_lanterns(accent: Color, ink: Color) -> void:
	var c := size * 0.5
	draw_line(c + Vector2(-17, 20), c + Vector2(17, -15), Color(ink, 0.35), 4.0, true)
	var lantern_points: Array[Vector2] = [Vector2(-13, 10), Vector2(0, -2), Vector2(13, -14)]
	for i in range(lantern_points.size()):
		# Lanterns visibly multiply as they are upgraded.
		if upgrade_level > 0 and i >= mini(3, upgrade_level):
			continue
		var point: Vector2 = lantern_points[i]
		var base: Vector2 = c + point
		draw_line(base, base + Vector2(0, -10), ink, 2.2, true)
		draw_rect(Rect2(base + Vector2(-4, -16), Vector2(8, 7)), Color("#ffd34f"))
		draw_rect(Rect2(base + Vector2(-5, -17), Vector2(10, 2)), accent)

func _draw_cottage(accent: Color, ink: Color) -> void:
	var c := size * 0.5
	draw_rect(Rect2(c + Vector2(-16, -1), Vector2(32, 22)), Color("#f0d3a0"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 0), c + Vector2(0, -18), c + Vector2(20, 0)]), accent)
	draw_rect(Rect2(c + Vector2(-5, 8), Vector2(10, 13)), ink)
	draw_rect(Rect2(c + Vector2(7, 5), Vector2(6, 6)), Color("#8bd7ff"))
	if upgrade_level >= 2:
		draw_rect(Rect2(c + Vector2(-12, -20), Vector2(5, 10)), Color("#b96b45"))
	if upgrade_level >= 3:
		draw_rect(Rect2(c + Vector2(-14, 6), Vector2(6, 7)), Color("#ffe18b"))
	if upgrade_level >= 4:
		draw_circle(c + Vector2(13, -6), 2.2, Color("#f4cd61"))

func _draw_bridge(accent: Color, ink: Color) -> void:
	var c := size * 0.5
	var colors := [Color("#ff6b6b"), Color("#ffd93d"), Color("#5ad66f"), Color("#4da3ff")]
	for i in range(mini(colors.size(), maxi(2, upgrade_level + 1))):
		draw_arc(c + Vector2(0, 11), 21.0 - float(i) * 3.5, PI, TAU, 32, colors[i], 2.6, true)
	draw_arc(c + Vector2(0, 16), 20, PI, TAU, 28, ink, 4.0, true)
	draw_line(c + Vector2(-20, 16), c + Vector2(20, 16), accent.darkened(0.15), 3.0, true)
	if upgrade_level >= 3:
		draw_line(c + Vector2(-18, 13), c + Vector2(18, 13), Color("#fce294"), 1.4, true)
