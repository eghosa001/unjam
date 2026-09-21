class_name UnjamFlatGameLogo
extends Control

# Shared flat game identity mark used by Home, Choose Game and World Journey.
# These are intentionally 2D vector emblems: no SubViewport, no lighting, no
# perspective and no per-frame rendering. They stay crisp at small mobile sizes
# and give each game a consistent visual identity everywhere it is referenced.

var game_id := "rescue_rush"
var accent := Unjam3DTheme.GREEN

func configure(id: String) -> void:
	game_id = id
	accent = Unjam3DTheme.game_accent(id)
	set_meta("unjam_flat_game_logo", true)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("unjam_flat_game_logo", true)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var radius := minf(size.x, size.y) * 0.43
	draw_circle(Vector2(size.x * 0.5, size.y * 0.5), radius, Color(accent, 0.13))
	match game_id:
		"water_sort":
			_draw_water()
		"block_puzzle":
			_draw_block()
		_:
			_draw_rescue()

func _draw_rescue() -> void:
	var unit := minf(size.x, size.y)
	var tile := unit * 0.31
	var centers := [
		Vector2(size.x * 0.36, size.y * 0.36),
		Vector2(size.x * 0.64, size.y * 0.52),
		Vector2(size.x * 0.39, size.y * 0.68),
	]
	var colors := [accent, Color("#ffd83d"), Color("#19b9ff")]
	var angles := [0.0, PI * 0.5, -PI * 0.5]
	for i in range(centers.size()):
		var center: Vector2 = centers[i]
		draw_rect(Rect2(center - Vector2.ONE * tile * 0.5, Vector2.ONE * tile), colors[i], true)
		_draw_arrow(center, tile * 0.70, angles[i], Color.WHITE)

func _draw_arrow(center: Vector2, length: float, angle: float, color: Color) -> void:
	var stem_w := length * 0.18
	var stem_h := length * 0.48
	var head := length * 0.34
	draw_set_transform(center, angle, Vector2.ONE)
	draw_rect(Rect2(-stem_w * 0.5, -stem_h * 0.48, stem_w, stem_h), color, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-head, -stem_h * 0.08),
		Vector2(head, -stem_h * 0.08),
		Vector2(0.0, -length * 0.52),
	]), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_water() -> void:
	var unit := minf(size.x, size.y)
	var tube_w := unit * 0.18
	var tube_h := unit * 0.54
	var xs := [0.30, 0.50, 0.70]
	var liquid := [Color("#19b9ff"), Color("#ff4d8d"), Color("#ffd83d")]
	for i in range(xs.size()):
		var x := size.x * float(xs[i])
		var top := size.y * (0.25 + float(i % 2) * 0.05)
		var bottom := top + tube_h
		var outline := Color("#eefaff")
		draw_line(Vector2(x - tube_w * 0.5, top), Vector2(x - tube_w * 0.5, bottom - tube_w * 0.45), outline, maxf(2.0, unit * 0.035), true)
		draw_line(Vector2(x + tube_w * 0.5, top), Vector2(x + tube_w * 0.5, bottom - tube_w * 0.45), outline, maxf(2.0, unit * 0.035), true)
		draw_arc(Vector2(x, bottom - tube_w * 0.45), tube_w * 0.5, 0.0, PI, 18, outline, maxf(2.0, unit * 0.035), true)
		var fill_top := top + tube_h * (0.45 + float(i) * 0.07)
		draw_rect(Rect2(x - tube_w * 0.39, fill_top, tube_w * 0.78, bottom - tube_w * 0.45 - fill_top), liquid[i], true)
		draw_circle(Vector2(x, bottom - tube_w * 0.45), tube_w * 0.39, liquid[i])
		draw_line(Vector2(x - tube_w * 0.55, top), Vector2(x + tube_w * 0.55, top), outline, maxf(2.0, unit * 0.035), true)

func _draw_block() -> void:
	var unit := minf(size.x, size.y)
	var cell := unit * 0.18
	var gap := cell * 0.14
	var start := Vector2(size.x * 0.27, size.y * 0.27)
	var cells := [
		[0, 0, Color("#c63cff")],
		[1, 0, Color("#c63cff")],
		[0, 1, Color("#c63cff")],
		[2, 1, Color("#19b9ff")],
		[1, 2, Color("#ffd83d")],
		[2, 2, Color("#ffd83d")],
	]
	for entry in cells:
		var col := int(entry[0])
		var row := int(entry[1])
		var color: Color = entry[2]
		var pos := start + Vector2(float(col) * (cell + gap), float(row) * (cell + gap))
		draw_rect(Rect2(pos, Vector2.ONE * cell), color, true)
