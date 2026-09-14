class_name UnjamLogo
extends Control

var phase := 0.0
var ink := Color("f7f9ff")
var muted := Color("93a4ba")
var accents := [Color("2dd4b6"), Color("5da9ff"), Color("8b7cf6")]

func configure(dark_mode: bool) -> void:
	ink = Color("f7f9ff") if dark_mode else Color("132033")
	muted = Color("93a4ba") if dark_mode else Color("607087")
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var center := size * 0.5
	var title_size := clampi(int(size.y * 0.46), 48, 72)
	var sub_size := clampi(int(size.y * 0.12), 14, 18)
	var letters := "UNJAM"
	var text_width := font.get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var baseline := center.y + float(title_size) * 0.30

	# restrained three-game accent rail; brand remains readable at every phone width.
	var rail_width := minf(size.x * 0.52, 430.0)
	var rail_x := center.x - rail_width * 0.5
	var rail_y := baseline - float(title_size) - 18.0
	for i in range(3):
		var seg_w := rail_width / 3.0
		var pulse := 0.45 + 0.08 * sin(phase * 1.4 + float(i))
		draw_rect(Rect2(Vector2(rail_x + seg_w * i + 4, rail_y), Vector2(seg_w - 8, 4)), Color(accents[i], pulse), true)

	var title_pos := Vector2(center.x - text_width * 0.5, baseline)
	draw_string(font, title_pos + Vector2(0, 4), letters, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0, 0, 0, 0.30))
	draw_string(font, title_pos, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, ink)

	var sub := "THREE PUZZLES  •  ONE JOURNEY"
	var sub_width := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x
	draw_string(font, Vector2(center.x - sub_width * 0.5, baseline + 32), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, muted)
