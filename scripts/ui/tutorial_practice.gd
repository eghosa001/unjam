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

func _press(at: Vector2) -> void:
	if completed: return
	match game_id:
		"rescue_rush":
			if RESCUE_FREE.has_point(at):
				_complete()
			else:
				_message("Blocked! Find an arrow with a clear edge.")
		"water_sort":
			if WATER_LEFT.has_point(at):
				_water_selected = true
				_message("Pink selected. Now tap the matching pink tube.")
			elif WATER_RIGHT.has_point(at) and _water_selected:
				_complete()
			elif WATER_MIDDLE.has_point(at) and _water_selected:
				_message("Different colours cannot stack. Try pink.")
			else:
				_message("Start by tapping the left pink tube.")
		"block_puzzle":
			if BLOCK_SOURCE.has_point(at):
				_dragging = true
				_drag_position = at
				_message("Keep holding. Slide onto the glowing outline.")
			else:
				_message("Hold the blue shape first, then drag.")
	queue_redraw()

func _move(at: Vector2) -> void:
	if _dragging and game_id == "block_puzzle" and not completed:
		_drag_position = at
		queue_redraw()

func _release(at: Vector2) -> void:
	if game_id != "block_puzzle" or not _dragging or completed: return
	_dragging = false
	if BLOCK_GOAL.grow(9.0).has_point(at):
		_complete()
	else:
		_message("Almost! Release inside the glowing outline.")
	queue_redraw()

func _complete() -> void:
	if completed: return
	completed = true
	_dragging = false
	_message("NICE MOVE! Ready to play the real puzzle.")
	practice_completed.emit(game_id)
	queue_redraw()

func _message(message: String) -> void:
	if _hint != null: _hint.text = message
	accessibility_name = message

func _draw() -> void:
	var mint := Color("#79f2be")
	var water := Color("#63dafe")
	var block := Color("#b4a0ff")
	match game_id:
		"rescue_rush":
			draw_rect(RESCUE_FREE.grow(2), mint if completed else Color("#ffe78c"), false, 3.0, true)
			if completed:
				draw_circle(Vector2(177,149),10,mint)
			else:
				draw_line(Vector2(206,148),Vector2(242,148),mint,3.0,true)
		"water_sort":
			draw_rect(WATER_LEFT.grow(3),water,false,3.0,true)
			draw_rect(WATER_RIGHT.grow(3),mint if _water_selected or completed else Color("#a0b7c8"),false,2.5,true)
			if _water_selected or completed:
				draw_line(Vector2(105,37),Vector2(201,37),mint,3.0,true)
		"block_puzzle":
			draw_rect(BLOCK_GOAL,Color(block,0.18),true)
			draw_rect(BLOCK_GOAL,block,false,3.0,true)
			var centre := BLOCK_GOAL.get_center() if completed else (_drag_position if _dragging else BLOCK_SOURCE.get_center())
			for offset in [-12.0,12.0]:
				draw_rect(Rect2(centre+Vector2(offset-10,-10),Vector2(20,20)),Color("#567afa"),true)
			if completed: draw_rect(BLOCK_GOAL,mint,false,3.5,true)
	# Opaque strip ensures legibility over the tutorial art in both themes.
	draw_rect(Rect2(5,148,292,34),Color("#152437",0.97),true)
