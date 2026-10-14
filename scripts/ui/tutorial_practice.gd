extends Control

# Zero-stakes first-play gesture lesson; never writes to game progression.
signal practice_completed(game_id: String)
const RESCUE_FREE := Rect2(148,127,57,47)
const WATER_LEFT := Rect2(52,18,54,132)
const WATER_MIDDLE := Rect2(126,18,54,132)
const WATER_RIGHT := Rect2(200,18,54,132)
const BLOCK_SOURCE := Rect2(226,101,59,42)
const BLOCK_GOAL := Rect2(94,92,84,45)
var game_id := "rescue_rush"
var completed := false
var _water_selected := false
var _dragging := false
var _drag_position := Vector2.ZERO
var _hint: Label

func configure(id: String) -> void:
	game_id = id if id in ["rescue_rush","water_sort","block_puzzle"] else "rescue_rush"
	completed = false
	_water_selected = false
	_dragging = false
	size = Vector2(302,184)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	tooltip_text = _instruction()
	accessibility_name = "Practice %s: %s" % [game_id.replace("_"," "),_instruction()]
	_hint = Label.new()
	_hint.name = "TutorialPracticeMessage"
	_hint.text = _instruction()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size",13)
	_hint.add_theme_color_override("font_color",Color("#f5faff"))
	_hint.position = Vector2(10,149)
	_hint.size = Vector2(282,31)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	queue_redraw()

func _instruction() -> String:
	match game_id:
		"water_sort": return "Try it: tap PINK, then matching PINK."
		"block_puzzle": return "Try it: drag the blue shape to the outline."
		_: return "Try it: tap the free right-facing arrow."

func _gui_input(event: InputEvent) -> void:
	if completed: return
	if event is InputEventScreenTouch:
		if event.pressed: _press(event.position)
		else: _release(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_move(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press(event.position)
		else: _release(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_move(event.position)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		# Non-drag alternative for TalkBack, keyboard or gamepad.
		_complete()
		accept_event()
