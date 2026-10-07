class_name UnjamMetaArt
extends Control

const ART := {
	"compete": preload("res://assets/art/meta/compete.svg"),
	"friends": preload("res://assets/art/meta/friends.svg"),
	"goals": preload("res://assets/art/meta/goals.svg"),
	"profile": preload("res://assets/art/meta/profile.svg"),
	"collection": preload("res://assets/art/meta/collection.svg"),
	"daily": preload("res://assets/art/meta/daily.svg"),
}

var kind := "compete"
var dark_mode := false

func configure(value: String, dark: bool = false) -> void:
	kind = value
	dark_mode = dark
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	match kind:
		"friends": _draw_friends()
		"goals": _draw_goals()
		"profile": _draw_profile()
		"collection": _draw_collection()
		"daily": _draw_daily()
		_: _draw_compete()

func _draw_compete() -> void: _draw_asset("compete")
func _draw_friends() -> void: _draw_asset("friends")
func _draw_goals() -> void: _draw_asset("goals")
func _draw_profile() -> void: _draw_asset("profile")
func _draw_collection() -> void: _draw_asset("collection")
func _draw_daily() -> void: _draw_asset("daily")

func _draw_asset(id: String) -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var texture := ART.get(id) as Texture2D
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(1,1,1,0.94 if dark_mode else 1.0))
