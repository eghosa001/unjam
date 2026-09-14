extends Button
class_name BlockCellButton

var occupied := false
var preview := false
var accent := Color("8b7cf6")
var footprint_active := false
var footprint_valid := false

func configure(value: bool, preview_value: bool = false, color: Color = Color("8b7cf6"), _index: int = 0) -> void:
	occupied = value
	preview = preview_value
	accent = color
	text = ""
	flat = true
	queue_redraw()

func set_drag_footprint(active: bool, valid: bool = false) -> void:
	footprint_active = active
	footprint_valid = valid
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(5,5), size - Vector2(10,10)), Color("101a32"), true)
	if occupied:
		draw_rect(Rect2(Vector2(12,12), size - Vector2(24,24)), accent, true)
	elif preview or footprint_active:
		draw_rect(Rect2(Vector2(12,12), size - Vector2(24,24)), Color(accent, 0.35), true)
