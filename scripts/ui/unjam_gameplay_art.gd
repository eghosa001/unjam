class_name UnjamGameplayArt
extends Control

# Authored world plates live behind interactive gameplay. They carry atmosphere,
# depth and game identity while the gameplay controls remain lightweight/dynamic.
const RESCUE_WORLD: Texture2D = preload("res://assets/art/gameplay/rescue_board_bg.svg")
const WATER_WORLD: Texture2D = preload("res://assets/art/gameplay/water_stage_bg.svg")
const BLOCK_WORLD: Texture2D = preload("res://assets/art/gameplay/block_board_bg.svg")

var kind := ""
var accent := Color.WHITE
var dark_mode := true
var seed_value := 0

func configure(value: String, color: Color, dark: bool = true, seed: int = 0) -> void:
	kind = value
	accent = color
	dark_mode = dark
	seed_value = seed
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	match kind:
		"rescue_board": _draw_rescue_board()
		"water_stage": _draw_water_stage()
		"block_tray": _draw_block_tray()
		_: _draw_block_board()

func _draw_rescue_board() -> void:
	_draw_world(RESCUE_WORLD, 1.0)

func _draw_water_stage() -> void:
	_draw_world(WATER_WORLD, 1.0)

func _draw_block_board() -> void:
	_draw_world(BLOCK_WORLD, 1.0)

func _draw_block_tray() -> void:
	_draw_world(BLOCK_WORLD, 0.62)

func _draw_world(texture: Texture2D, opacity: float) -> void:
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(1,1,1,opacity))
