class_name GameSelectTile
extends Button

signal chosen(game_id: String)
var game_id := "rescue_rush"

func configure(id: String, display_title: String, current_level: int, color: Color, is_selected: bool, _dark: bool) -> void:
	game_id = id
	text = "%s\nLEVEL %d" % [display_title, current_level]
	custom_minimum_size = Vector2(300, 150)
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", color if is_selected else Color("f7f9ff"))

func _ready() -> void:
	pressed.connect(func(): chosen.emit(game_id))
