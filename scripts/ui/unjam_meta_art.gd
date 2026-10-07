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

const PHONE_SAFE_ART_SOURCE := Rect2(0.0, 610.0, 390.0, 142.0)

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
	# Phone meta screens already contain dense authored cards. Keep illustration
	# in the dedicated lower decorative band so large hero shapes never sit under
	# player names, progress cards, rankings, missions or upgrade controls.
	var y_scale := size.y / 844.0
	var destination := Rect2(
		Vector2(0.0, PHONE_SAFE_ART_SOURCE.position.y * y_scale),
		Vector2(size.x, PHONE_SAFE_ART_SOURCE.size.y * y_scale)
	)
	draw_texture_rect_region(
		texture,
		destination,
		PHONE_SAFE_ART_SOURCE,
		Color(1,1,1,0.76 if dark_mode else 0.72)
	)
