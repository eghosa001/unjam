class_name RescueToken
extends Control

const RESCUE_TEXTURES := {
	"chick": preload("res://assets/art/gameplay/rescue/chick.svg"),
	"puppy": preload("res://assets/art/gameplay/rescue/puppy.svg"),
	"kitten": preload("res://assets/art/gameplay/rescue/kitten.svg"),
	"robot": preload("res://assets/art/gameplay/rescue/robot.svg"),
	"slime": preload("res://assets/art/gameplay/rescue/slime.svg"),
	"panda": preload("res://assets/art/gameplay/rescue/panda.svg"),
	"fox": preload("res://assets/art/gameplay/rescue/fox.svg"),
	"alien": preload("res://assets/art/gameplay/rescue/alien.svg"),
}

var rescue_id := "chick"
var accent := Color("#ffd166")
var rarity := ""
var phase := 0.0
var celebrating := false
var _redraw_accumulator := 0.0

const DECORATIVE_RENDER_FPS := 20.0
const DECORATIVE_RENDER_INTERVAL := 1.0 / DECORATIVE_RENDER_FPS

func configure(id: String, color: Color = Color("#ffd166"), variant_rarity: String = "") -> void:
	rescue_id = id if RESCUE_TEXTURES.has(id) else "chick"
	accent = color
	rarity = variant_rarity.to_lower()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	visibility_changed.connect(_sync_motion)
	add_to_group("reduced_motion_aware")
	_sync_motion()

func apply_motion_preference() -> void:
	_sync_motion()
	queue_redraw()

func _sync_motion() -> void:
	var reduced := false
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced"):
		reduced = bool(motion.call("reduced"))
	_redraw_accumulator = 0.0
	set_process(is_visible_in_tree() and not reduced)

func _process(delta: float) -> void:
	phase += delta
	_redraw_accumulator += delta
	if _redraw_accumulator >= DECORATIVE_RENDER_INTERVAL:
		_redraw_accumulator = fmod(_redraw_accumulator, DECORATIVE_RENDER_INTERVAL)
		queue_redraw()

func celebrate() -> void:
	FeedbackManager.complete()
	if celebrating:
		return
	celebrating = true
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced") and bool(motion.call("reduced")):
		scale = Vector2.ONE
		celebrating = false
		queue_redraw()
		return
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.16, 0.86), 0.08)
	tween.tween_property(self, "scale", Vector2(0.94, 1.13), 0.09)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_callback(func() -> void:
		celebrating = false
		queue_redraw()
	)

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var s := minf(size.x, size.y)
	var reduced := false
	var motion := get_node_or_null("/root/MotionSystem")
	if motion != null and motion.has_method("reduced"):
		reduced = bool(motion.call("reduced"))
	var bob := 0.0 if reduced else sin(phase * 2.8) * s * 0.025
	var art_size := Vector2(s * 1.30, s * 1.30)
	var art_rect := Rect2(Vector2(size.x * 0.5, size.y * 0.50 + bob) - art_size * 0.5, art_size)
	var texture := RESCUE_TEXTURES.get(rescue_id) as Texture2D
	if texture == null:
		texture = RESCUE_TEXTURES["chick"] as Texture2D
	draw_texture_rect(texture, art_rect, false, Color.WHITE)
	if rarity in ["silver","gold","royal"]:
		var ring := Color("#dce8f4") if rarity == "silver" else (Color("#ffd75c") if rarity == "gold" else Color("#b790ff"))
		draw_arc(art_rect.get_center(), s * 0.60, 0, TAU, 42, Color(ring, 0.54), maxf(1.5, s * 0.028), true)
