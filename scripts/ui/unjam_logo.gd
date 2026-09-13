class_name UnjamLogo
extends Control

var phase := 0.0
var ink := Color("f7f9ff")
var muted := Color("aebbd0")
var accents := [Color("2dd4b6"), Color("5da9ff"), Color("8b7cf6")]

func configure(dark_mode: bool) -> void:
	ink = Color("f7f9ff") if dark_mode else Color("14213a")
	muted = Color("aebbd0") if dark_mode else Color("52637a")
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
	var glow := 0.04 + sin(phase * 1.8) * 0.015
	for i in range(3):
		var x := center.x - 170.0 + i * 170.0
		var bob := sin(phase * 1.6 + float(i) * 0.8) * 4.0
		var shadow_rect := Rect2(Vector2(x - 62, center.y - 59 + bob), Vector2(124, 124))
		draw_rect(shadow_rect.grow(10), Color(accents[i], glow), true)
		draw_rect(shadow_rect, Color(accents[i], 0.15), true)
		draw_rect(Rect2(shadow_rect.position + Vector2(5, 5), shadow_rect.size - Vector2(10, 10)), Color(accents[i], 0.07), true)
	var letters := "UNJAM"
	var width := font.get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, 92).x
	var text_pos := Vector2(center.x - width * 0.5, center.y + 35)
	draw_string(font, text_pos + Vector2(0, 8), letters, HORIZONTAL_ALIGNMENT_LEFT, -1, 92, Color(0,0,0,0.20))
	draw_string(font, text_pos, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, 92, ink)
	var sub := "THREE PUZZLES. ONE JOURNEY."
	var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(font, Vector2(center.x - sw * 0.5, center.y + 88), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, muted)
