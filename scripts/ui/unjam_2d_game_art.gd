class_name Unjam2DGameArt
extends Control

# Authored vector illustration owns the identity layer. Runtime code only selects,
# scales and gently animates the art; it no longer invents the scene from primitives.
const RESCUE_ART: Texture2D = preload("res://assets/art/home/rescue_rush_hero.svg")
const WATER_ART: Texture2D = preload("res://assets/art/home/water_sort_hero.svg")
const BLOCK_ART: Texture2D = preload("res://assets/art/home/block_puzzle_hero.svg")

var game_id := "rescue_rush"
var compact := false
var dark_mode := false
var phase := 0.0
var _redraw_accumulator := 0.0

const ACTIVE_FPS := 20.0
const ACTIVE_INTERVAL := 1.0 / ACTIVE_FPS

func configure(id: String, compact_mode: bool = false, dark: bool = false) -> void:
	game_id = id
	compact = compact_mode
	dark_mode = dark
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	if is_inside_tree():
		_sync_motion()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_sync_motion)
	_sync_motion()

func _sync_motion() -> void:
	var reduced := false
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced"):
		reduced = bool(motion.call("reduced"))
	set_process(is_visible_in_tree() and not reduced and not compact)

func _process(delta: float) -> void:
	phase += delta
	_redraw_accumulator += delta
	if _redraw_accumulator >= ACTIVE_INTERVAL:
		_redraw_accumulator = fmod(_redraw_accumulator, ACTIVE_INTERVAL)
		queue_redraw()

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	match game_id:
		"water_sort": _draw_water()
		"block_puzzle": _draw_block()
		_: _draw_rescue()

func _draw_rescue() -> void:
	_draw_authored(RESCUE_ART, 1.0)

func _draw_water() -> void:
	_draw_authored(WATER_ART, 1.0)

func _draw_block() -> void:
	_draw_authored(BLOCK_ART, 1.0)

func _draw_authored(texture: Texture2D, opacity: float) -> void:
	var bob := 0.0
	if not compact:
		bob = sin(phase * 1.65) * minf(size.x, size.y) * 0.006
	var rect := Rect2(Vector2(0, bob), size)
	draw_texture_rect(texture, rect, false, Color(1, 1, 1, opacity))
	# Tiny live glint: motion supports the illustration instead of replacing it.
	if not compact:
		var t := 0.5 + 0.5 * sin(phase * 2.1)
		var p := Vector2(size.x * (0.78 + 0.06 * t), size.y * (0.16 + 0.025 * t))
		draw_circle(p, maxf(1.5, size.x * 0.012), Color(1, 1, 1, 0.12 + 0.12 * t))
